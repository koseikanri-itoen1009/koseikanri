CREATE OR REPLACE PACKAGE BODY XXCOK014A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK014A02C(body)
 * Description      : 販売手数料（自販機）の計算結果を情報系システムに
 *                    連携するインターフェースファイルを作成します
 * MD.050           : 情報系システムIFファイル作成-条件別販手販協  MD050_COK_014_A02
 * Version          : 1.8
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1),
 *                         ファイルオープン(A-2)
 *  get_cust_info          顧客情報取得処理(A-3)
 *  get_bm_support_info    条件別販手販協情報取得処理(A-4)
 *  storage_plsql_tab      PL/SQL表格納処理(A-5)
 *  output_csv_file        ファイル出力処理(A-6)
 *  upd_cond_bm_support    条件別販手販協テーブル更新処理(A-7)
 *  submain                メイン処理プロシージャ,
 *                         ファイルクローズ(A-8)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/19    1.0   T.Abe            新規作成
 *  2009/02/06    1.1   T.Abe            [障害COK_012] ディレクトリパスの出力を修正
 *  2009/02/16    1.2   T.Abe            [障害COK_035] 定数 フルサービスVDの変更
 *  2009/02/19    1.3   K.Yamaguchi      [障害COK_048] 最新の仕入先サイト情報を取得するよう変更
 *                                                     仕入先サイトの抽出条件に営業単位IDを追加
 *                                                     入力パラメータ「支払日」の書式を変更
 *  2009/02/25    1.4   T.Abe            [障害COK_056] 業務処理日付－２日営業日を取得する処理を追加
 *                                                     共通関数 締め日取得処理に業務処理日付－２営業日を渡すよう修正
 *                                                     業務処理日付＝取得した営業日の場合に条件別販手販協情報を
 *                                                     取得するよう修正
 *  2009/03/26    1.5   M.Hiruta         [障害T1_0162] ファイル出力処理において納品数量がNULLである場合
 *                                                     0へ置換するよう修正
 *  2009/04/17    1.6   K.Yamaguchi      [障害T1_0641] 契約管理テーブルの締め日、支払日がNULLの場合には、
 *                                                     プロファイル XXCOK1_FB_TERM_NAME の値を使用する。
 *  2009/06/29    1.7   K.Yamaguchi      [障害0000200] [障害0000290] パフォーマンス障害対応
 *  2009/10/08    1.8   S.Moriyama       [障害E_最終移行リハ_00460] 定額条件の場合は割戻額をNULLでファイル出力するよう変更
 *
 *****************************************************************************************/
--
  --==========================
  -- グローバル定数
  --==========================
  -- パッケージ名
  cv_pkg_name                CONSTANT VARCHAR2(100) := 'XXCOK014A02C';                     -- パッケージ名
  -- ステータス・コード
  cv_status_normal           CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn             CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error            CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_error;  --異常:2
  -- WHOカラム
  cn_created_by              CONSTANT NUMBER        := fnd_global.user_id;                 --CREATED_BY
  cn_last_updated_by         CONSTANT NUMBER        := fnd_global.user_id;                 --LAST_UPDATED_BY
  cn_last_update_login       CONSTANT NUMBER        := fnd_global.login_id;                --LAST_UPDATE_LOGIN
  cn_request_id              CONSTANT NUMBER        := fnd_global.conc_request_id;         --REQUEST_ID
  cn_program_application_id  CONSTANT NUMBER        := fnd_global.prog_appl_id;            --PROGRAM_APPLICATION_ID
  cn_program_id              CONSTANT NUMBER        := fnd_global.conc_program_id;         --PROGRAM_ID
  -- 記号
  cv_msg_part                CONSTANT VARCHAR2(3)   := ' : ';                              -- コロン
  cv_msg_cont                CONSTANT VARCHAR2(3)   := '.';                                -- ドット
  -- アプリケーション名
  cv_appli_xxcok             CONSTANT VARCHAR2(5)   := 'XXCOK';                            -- アプリケーション名：XXCOK
  cv_appli_xxccp             CONSTANT VARCHAR2(5)   := 'XXCCP';                            -- アプリケーション名：XXCCP
  -- メッセージ
  cv_msg_cok_00022           CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00022';                 -- コンカレント入力パラメータ
  cv_msg_cok_10342           CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10342';                 -- 業務日付の形式違いエラー
  cv_msg_cok_00028           CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00028';                 -- 業務日付取得エラー
  cv_msg_cok_00009           CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00009';                 -- ファイル存在チェックエラー
  cv_msg_cok_00051           CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00051';                 -- ロック取得エラー
  cv_msg_cok_00003           CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00003';                 -- プロファイル取得エラー
-- 2009/06/29 Ver.1.7 [障害0000200] [障害0000290] SCS K.Yamaguchi DEL START
--  cv_msg_cok_10203           CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10203';                 -- 営業日取得エラー
--  cv_msg_cok_10369           CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10369';                 -- 締め日取得エラー
-- 2009/06/29 Ver.1.7 [障害0000200] [障害0000290] SCS K.Yamaguchi DEL END
  cv_msg_cok_00067           CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00067';                 -- ディレクトリ
  cv_msg_cok_00006           CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00006';                 -- ファイル名
  cv_msg_ccp_90000           CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90000';                 -- 対象件数メッセージ
  cv_msg_ccp_90001           CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90001';                 -- 成功件数メッセージ
  cv_msg_ccp_90002           CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90002';                 -- エラー件数メッセージ
  cv_msg_ccp_90004           CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90004';                 -- 正常終了メッセージ
  cv_msg_ccp_90006           CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90006';                 -- エラー終了全ロールバックメッセージ
  -- プロファイル
  cv_prof_org_id             CONSTANT VARCHAR2(50)  := 'ORG_ID';                           -- 営業単位ID
  cv_prof_aff1_company_code  CONSTANT VARCHAR2(50)  := 'XXCOK1_AFF1_COMPANY_CODE';         -- 会社コード
  cv_prof_bs_period_to       CONSTANT VARCHAR2(50)  := 'XXCOK1_BM_SUPPORT_PERIOD_TO';      -- 販手販協計算処理期間（To）
  cv_prof_bs_dire_path       CONSTANT VARCHAR2(50)  := 'XXCOK1_BM_SUPPORT_DIRE_PATH';      -- 条件別販手販協ディレクトリオブジェクト
  cv_prof_bs_file_name       CONSTANT VARCHAR2(50)  := 'XXCOK1_BM_SUPPORT_FILE_NAME';      -- 条件別販手販協ファイル名
  cv_prof_uom_code_hon       CONSTANT VARCHAR2(50)  := 'XXCOK1_UOM_CODE_HON';              -- 単位コード(本)
-- 2009/04/17 Ver.1.6 [障害T1_0641] SCS K.Yamaguchi ADD START
  cv_prof_fb_term_name       CONSTANT VARCHAR2(50)  := 'XXCOK1_FB_TERM_NAME';              -- FB支払条件
-- 2009/04/17 Ver.1.6 [障害T1_0641] SCS K.Yamaguchi ADD END
  -- トークン
  cv_token_count             CONSTANT VARCHAR2(5)   := 'COUNT';                            -- 処理件数
  cv_token_business_date     CONSTANT VARCHAR2(30)  := 'BUSINESS_DATE';                    -- 業務日付
  cv_token_profile           CONSTANT VARCHAR2(7)   := 'PROFILE';                          -- プロファイル名
  cv_token_directory         CONSTANT VARCHAR2(9)   := 'DIRECTORY';                        -- ディレクトリ
  cv_token_file_name         CONSTANT VARCHAR2(9)   := 'FILE_NAME';                        -- ファイル名
-- 2009/06/29 Ver.1.7 [障害0000200] [障害0000290] SCS K.Yamaguchi DEL START
--  cv_token_close_date        CONSTANT VARCHAR2(10)  := 'CLOSE_DATE';                       -- 締め日
--  cv_token_term_code         CONSTANT VARCHAR2(10)  := 'TERM_CODE';                        -- 支払条件
-- 2009/06/29 Ver.1.7 [障害0000200] [障害0000290] SCS K.Yamaguchi DEL END
  -- フラグ
  cv_flag_no                 CONSTANT VARCHAR2(1)   := 'N';                                -- フラグ'N'
  -- 参照タイプ
  cv_bm_calc_type            CONSTANT VARCHAR2(50)  := 'XXCOK1_BM_CALC_TYPE';              -- 参照タイプ
  -- 数値
  cv_fullservice_vd          CONSTANT VARCHAR2(2)   := '25';                               -- フルサービスVD
  cv_customer                CONSTANT VARCHAR2(2)   := '10';                               -- 顧客
  cv_0                       CONSTANT VARCHAR2(1)   := '0';                                -- 文字'0'
  cv_1                       CONSTANT VARCHAR2(1)   := '1';                                -- 文字'1'
  cv_2                       CONSTANT VARCHAR2(1)   := '2';                                -- 文字'2'
  cn_1                       CONSTANT NUMBER        := 1;                                  -- 数値 1
  cn_2                       CONSTANT NUMBER        := 2;                                  -- 数値 2
  cn_minus_2                 CONSTANT NUMBER        := -2;                                 -- 数値 -2
-- 2009/10/08 Ver.1.8 [障害E_最終移行リハ_00460] SCS S.Moriyama ADD START
  cn_0                       CONSTANT NUMBER        := 0;                                  -- 数値 0
  cv_except_calc_type        CONSTANT VARCHAR2(10)  := '定額条件';                         -- 情報系IF割戻額未連携計算条件
-- 2009/10/08 Ver.1.8 [障害E_最終移行リハ_00460] SCS S.Moriyama ADD END
--
  --==========================
  -- グローバル変数
  --==========================
  gv_out_msg                VARCHAR2(2000) DEFAULT NULL;
  gv_sep_msg                VARCHAR2(2000) DEFAULT NULL;
  gv_exec_user              VARCHAR2(100)  DEFAULT NULL;
  gv_conc_name              VARCHAR2(30)   DEFAULT NULL;
  gv_conc_status            VARCHAR2(30)   DEFAULT NULL;
  gn_target_cnt             NUMBER         DEFAULT NULL;                            -- 対象件数
  gn_normal_cnt             NUMBER         DEFAULT NULL;                            -- 正常件数
  gn_error_cnt              NUMBER         DEFAULT NULL;                            -- エラー件数
  gn_warn_cnt               NUMBER         DEFAULT NULL;                            -- スキップ件数
  -- プロファイル
  gt_prof_aff1_company_code fnd_profile_option_values.profile_option_value%TYPE;    -- 会社コード
-- 2009/06/29 Ver.1.7 [障害0000200] [障害0000290] SCS K.Yamaguchi DEL START
--  gt_prof_bs_period_to      fnd_profile_option_values.profile_option_value%TYPE;    -- 販手販協計算処理期間（To）
-- 2009/06/29 Ver.1.7 [障害0000200] [障害0000290] SCS K.Yamaguchi DEL END
  gt_prof_bs_dire_path      fnd_profile_option_values.profile_option_value%TYPE;    -- 条件別販手販協ディレクトリオブジェクト
  gt_prof_bs_file_name      fnd_profile_option_values.profile_option_value%TYPE;    -- 条件別販手販協ファイル名
  gt_prof_uom_code_hon      fnd_profile_option_values.profile_option_value%TYPE;    -- 単位コード(本)
-- 2009/06/29 Ver.1.7 [障害0000200] [障害0000290] SCS K.Yamaguchi DEL START
---- 2009/04/17 Ver.1.6 [障害T1_0641] SCS K.Yamaguchi ADD START
--  gt_prof_fb_term_name      fnd_profile_option_values.profile_option_value%TYPE;    -- FB支払条件
---- 2009/04/17 Ver.1.6 [障害T1_0641] SCS K.Yamaguchi ADD END
-- 2009/06/29 Ver.1.7 [障害0000200] [障害0000290] SCS K.Yamaguchi DEL END
  -- 変数
  gv_bs_dire_path           VARCHAR2(1000) DEFAULT NULL;                            -- 条件別販手販協ディレクトリパス
  gd_sysdate                DATE           DEFAULT NULL;                            -- システム日付
  gd_business_date          DATE           DEFAULT NULL;                            -- 業務日付
  gu_open_file_handle       UTL_FILE.FILE_TYPE;                                     -- オープンファイルハンドル
  gn_org_id                 NUMBER         DEFAULT NULL;
  --==========================
  -- グローバル・レコード
  --==========================
-- 2009/06/29 Ver.1.7 [障害0000200] [障害0000290] SCS K.Yamaguchi DEL START
--  TYPE bm_support_csv_rtype IS RECORD(
--    sequence_number          NUMBER             -- シーケンス番号
--   ,company_code             VARCHAR2(3)        -- 会社コード
--   ,base_code                VARCHAR2(4)        -- 拠点(部門) コード
--   ,emp_code                 VARCHAR2(5)        -- 担当者コード
--   ,cust_code                VARCHAR2(9)        -- 顧客コード
--   ,acctg_year               VARCHAR2(4)        -- 会計年度
--   ,chain_store_code         VARCHAR2(9)        -- チェーン店コード
--   ,supplier_code            VARCHAR2(9)        -- 仕入先コード
--   ,supplier_site_code       VARCHAR2(10)       -- 支払先サイトコード
--   ,delivery_date            NUMBER             -- 納品日年月
--   ,delivery_qty             NUMBER             -- 納品数量
--   ,delivery_unit_type       VARCHAR2(2)        -- 納品単位(本/ケース)
--   ,selling_amt_tax          NUMBER             -- 売上金額(税込)
--   ,account_type             VARCHAR2(20)       -- 取引条件
--   ,rebate_rate              NUMBER             -- 割戻率
--   ,rebate_amt               NUMBER             -- 割戻額
--   ,container_type_code      VARCHAR2(4)        -- 容器区分コード
--   ,selling_price            NUMBER             -- 売価金額
--   ,cond_bm_amt_tax          NUMBER             -- 条件別手数料額(税込)
--   ,cond_bm_amt_no_tax       NUMBER             -- 条件別手数料額(税抜)
--   ,cond_tax_amt             NUMBER             -- 条件別消費税額
--   ,electric_amt             NUMBER             -- 電気料
--   ,closing_date             DATE               -- 締日
--   ,expect_payment_date      DATE               -- 支払日
--   ,calc_target_period_from  DATE               -- 計算対象期間(From)
--   ,calc_target_period_to    DATE               -- 計算対象期間(To)
--   ,ref_base_code            VARCHAR2(4)        -- 問合わせ担当拠点コード
--   ,interface_date           DATE               -- 連携日時
--  );
-- 2009/06/29 Ver.1.7 [障害0000200] [障害0000290] SCS K.Yamaguchi DEL END
  --===========================
  -- グローバル・カーソル
  --===========================
-- 2009/06/29 Ver.1.7 [障害0000200] [障害0000290] SCS K.Yamaguchi DEL START
--  -- A-3.顧客情報取得
--  CURSOR cust_info_cur
--  IS
--  SELECT xcm.install_account_number  AS  install_account_number                      -- 設置先顧客コード
--        ,xcm.close_day_code          AS  close_day_code                              -- 締め日
--        ,xcm.transfer_day_code       AS  transfer_day_code                           -- 支払日
--  FROM   xxcso_contract_managements  xcm                                             -- 契約管理
--        ,(
--            SELECT MAX( TO_NUMBER( xcm.contract_number ) )  AS  contract_number      -- 契約書番号
--                  ,xcm.install_account_id                   AS  install_account_id   -- 設置先顧客ID
--            FROM   xxcso_contract_managements  xcm                                   -- 契約管理
--                  ,hz_cust_accounts            hca                                   -- 顧客マスタ
--                  ,xxcmm_cust_accounts         xca                                   -- 顧客追加アドオン
--            WHERE  hca.cust_account_id     = xcm.install_account_id
--            AND    hca.cust_account_id     = xca.customer_id
--            AND    xca.business_low_type   = cv_fullservice_vd
--            AND    hca.customer_class_code = cv_customer
--            AND    xcm.status              = cv_1
--            GROUP BY xcm.install_account_id
--         )                           xcm_v                                           -- インラインビュー
--  WHERE  xcm.contract_number    = xcm_v.contract_number
--  AND    xcm.install_account_id = xcm_v.install_account_id
--  AND    xcm.status             = cv_1;
--  cust_info_rec    cust_info_cur%ROWTYPE;
--  --==================================
--  -- グローバルTABLE型
--  --==================================
--  -- 顧客情報
--  TYPE cust_info_ttpye IS TABLE OF cust_info_cur%ROWTYPE
--  INDEX BY BINARY_INTEGER;
--  gt_cust_info_tab    cust_info_ttpye;
-- 2009/06/29 Ver.1.7 [障害0000200] [障害0000290] SCS K.Yamaguchi DEL END
  --==================================
  -- グローバル・カーソル
  --==================================
  --条件別販手販協情報
-- 2009/06/29 Ver.1.7 [障害0000200] [障害0000290] SCS K.Yamaguchi REPAIR START
--  CURSOR bm_support_cur(
--           in_ci_cnt IN NUMBER
--  )
  CURSOR bm_support_cur
-- 2009/06/29 Ver.1.7 [障害0000200] [障害0000290] SCS K.Yamaguchi REPAIR END
  IS
-- 2009/10/08 Ver.1.8 [障害E_最終移行リハ_00460] SCS S.Moriyama UPD START
--  SELECT  xcbs.cond_bm_support_id       AS cond_bm_support_id         -- 条件別販手販協ID
  SELECT  /*+
              LEADING( xcbs , xbb )
              INDEX( xbb xxcok_backmargin_balance_n03 )
              INDEX( xcbs xxcok_cond_bm_support_n03 )
          */
          xcbs.cond_bm_support_id       AS cond_bm_support_id         -- 条件別販手販協ID
-- 2009/10/08 Ver.1.8 [障害E_最終移行リハ_00460] SCS S.Moriyama UPD END
         ,xcbs.base_code                AS base_code                  -- 拠点コード
         ,xcbs.emp_code                 AS emp_code                   -- 担当者コード
         ,xcbs.delivery_cust_code       AS delivery_cust_code         -- 顧客【納品先】
         ,xcbs.acctg_year               AS acctg_year                 -- 会計年度
         ,xcbs.chain_store_code         AS chain_store_code           -- チェーン店コード
         ,xcbs.supplier_code            AS supplier_code              -- 仕入先コード
         ,pvsa.vendor_site_code         AS supplier_site_code         -- 仕入先サイトコード
         ,xcbs.delivery_date            AS delivery_date              -- 納品日年月
         ,xcbs.delivery_qty             AS delivery_qty               -- 納品数量
         ,xcbs.delivery_unit_type       AS delivery_unit_type         -- 納品単位
         ,xcbs.selling_amt_tax          AS selling_amt_tax            -- 売上金額（税込）
         ,xlv_v.meaning                 AS calc_type                  -- 計算条件
         ,xcbs.rebate_rate              AS rebate_rate                -- 割戻率
         ,xcbs.rebate_amt               AS rebate_amt                 -- 割戻額
         ,xcbs.container_type_code      AS container_type_code        -- 容器区分コード
         ,xcbs.selling_price            AS selling_price              -- 売価金額
         ,xcbs.cond_bm_amt_tax          AS cond_bm_amt_tax            -- 条件別手数料額（税込）
         ,xcbs.cond_bm_amt_no_tax       AS cond_bm_amt_no_tax         -- 条件別手数料額（税抜）
         ,xcbs.cond_tax_amt             AS cond_tax_amt               -- 条件別消費税額
         ,xcbs.electric_amt_tax         AS electric_amt_tax           -- 電気料（税込）
         ,xcbs.closing_date             AS closing_date               -- 締め日
         ,xcbs.expect_payment_date      AS expect_payment_date        -- 支払予定日
         ,xcbs.calc_target_period_from  AS calc_target_period_from    -- 計算対象期間（From）
         ,xcbs.calc_target_period_to    AS calc_target_period_to      -- 計算対象期間（To）
         ,pvsa.attribute5               AS ref_base_code              -- 問合せ担当拠点コード
  FROM    xxcok_cond_bm_support         xcbs                          -- 条件別販手販協テーブル
         ,xxcok_backmargin_balance      xbb                           -- 販手残高テーブル
         ,po_vendors                    pv                            -- 仕入先マスタ
         ,po_vendor_sites_all           pvsa                          -- 仕入先サイトマスタ
-- 2009/10/08 Ver.1.8 [障害E_最終移行リハ_00460] SCS S.Moriyama UPD START
--         ,xxcmn_lookup_values_v         xlv_v                         -- クイックコード
         ,xxcok_lookups_v               xlv_v                         -- クイックコード
-- 2009/10/08 Ver.1.8 [障害E_最終移行リハ_00460] SCS S.Moriyama UPD END
  WHERE xcbs.base_code                  = xbb.base_code
  AND   xcbs.supplier_code              = xbb.supplier_code
  AND   xcbs.closing_date               = xbb.closing_date
  AND   xcbs.expect_payment_date        = xbb.expect_payment_date
  AND   xcbs.supplier_code              = pv.segment1
  AND   xcbs.cond_bm_interface_status   = cv_0
  AND   pv.vendor_id                    = pvsa.vendor_id
  AND   ( pvsa.inactive_date            > gd_business_date OR pvsa.inactive_date IS NULL )
  AND   pvsa.org_id                     = gn_org_id
  AND   xbb.resv_flag                   IS NULL
  AND   pvsa.hold_all_payments_flag     = cv_flag_no
  AND   xbb.cust_code                   = xcbs.delivery_cust_code
-- 2009/06/29 Ver.1.7 [障害0000200] [障害0000290] SCS K.Yamaguchi REPAIR START
--  AND   xbb.cust_code                   = gt_cust_info_tab( in_ci_cnt ).install_account_number
-- 2009/06/29 Ver.1.7 [障害0000200] [障害0000290] SCS K.Yamaguchi REPAIR END
  AND   xlv_v.lookup_code               = xcbs.calc_type
  AND   xlv_v.lookup_type               = cv_bm_calc_type
-- 2009/10/08 Ver.1.8 [障害E_最終移行リハ_00460] SCS S.Moriyama ADD START
  AND   gd_business_date                BETWEEN xlv_v.start_date_active
                                            AND NVL(xlv_v.end_date_active,gd_business_date)
  AND   xbb.payment_amt_tax             = cn_0
-- 2009/10/08 Ver.1.8 [障害E_最終移行リハ_00460] SCS S.Moriyama ADD END
  AND   pvsa.attribute4                 IN (cv_1, cv_2);
  bm_support_rec    bm_support_cur%ROWTYPE;
  -- 条件別販手販協テーブルロック情報
  CURSOR lock_cond_bm_support_cur(
           in_cond_bm_support_id IN xxcok_cond_bm_support.cond_bm_support_id%TYPE      -- 条件別販手販協ID
  )
  IS
  SELECT xcbs.cond_bm_support_id  AS  cond_bm_support_id                               -- 条件別販手販協ID
  FROM   xxcok_cond_bm_support  xcbs                                                   -- 条件別販手販協テーブル
  WHERE  xcbs.cond_bm_support_id = in_cond_bm_support_id
  FOR UPDATE NOWAIT;
-- 2009/06/29 Ver.1.7 [障害0000200] [障害0000290] SCS K.Yamaguchi DEL START
--  --=================================
--  -- グローバル・TABLE型
--  --=================================
--  -- 条件別販手販協情報
--  TYPE bm_support_ttpye IS TABLE OF bm_support_cur%ROWTYPE
--  INDEX BY BINARY_INTEGER;
--  gt_bm_support_tab    bm_support_ttpye;
--  --=================================
--  -- グローバル・PL/SQL表
--  --=================================
--  TYPE bm_support_csv_ttpye IS TABLE OF bm_support_csv_rtype
--  INDEX BY BINARY_INTEGER;
--  gt_bms_csv_tab  bm_support_csv_ttpye;
-- 2009/06/29 Ver.1.7 [障害0000200] [障害0000290] SCS K.Yamaguchi DEL END
  --=================================
  -- 共通例外
  --=================================
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
  --*** 共通ロック取得例外 ***
  global_lock_err_expt      EXCEPTION;
  --=================================
  -- プラグマ
  --=================================
  PRAGMA EXCEPTION_INIT( global_api_others_expt,-20000 );
  PRAGMA EXCEPTION_INIT( global_lock_err_expt, -54 );
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   *                  : ファイルオープン処理(A-2)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf        OUT VARCHAR2           -- エラー・メッセージ
   ,ov_retcode       OUT VARCHAR2           -- リターン・コード
   ,ov_errmsg        OUT VARCHAR2           -- ユーザー・エラー・メッセージ
   ,iv_business_date IN  VARCHAR2           -- 入力パラメータ・業務日付
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name      CONSTANT VARCHAR2(100) := 'init';      -- プログラム名
    cv_open_mode     CONSTANT VARCHAR2(1)   := 'w';         -- OPEN_MODE
    cn_max_linesize  CONSTANT NUMBER        := 32767;       -- MAX_LINESIZE
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf        VARCHAR2(5000) DEFAULT NULL;           -- エラー・メッセージ
    lv_retcode       VARCHAR2(1)    DEFAULT NULL;           -- リターン・コード
    lv_errmsg        VARCHAR2(5000) DEFAULT NULL;           -- ユーザー・エラー・メッセージ
    lb_retcode       BOOLEAN        DEFAULT NULL;           -- リターンコード
    lv_out_msg       VARCHAR2(5000) DEFAULT NULL;           -- アウトメッセージ
    ld_business_date DATE           DEFAULT NULL;           -- 入力パラメータ変換チェック用
    lv_err_profile   VARCHAR2(50)   DEFAULT NULL;           -- 取得に失敗したプロファイル
    lb_exists        BOOLEAN        DEFAULT NULL;           -- ファイル存在チェック
    ln_file_length   NUMBER         DEFAULT NULL;           -- ファイルの長さ
    ln_block_size    NUMBER         DEFAULT NULL;           -- ブロックサイズ
    --===============================
    -- ローカル例外
    --===============================
    --*** 型変換例外 ***
    date_prm_expt          EXCEPTION;
    --*** プロファイル取得例外 ***
    no_prifile_expt        EXCEPTION;
    --*** 業務日付取得例外 ***
    no_process_date_expt   EXCEPTION;
    --*** ファイル存在例外 ***
    file_exists_expt       EXCEPTION;
--
  BEGIN
    -- ステータス初期化
    ov_retcode := cv_status_normal;
    -- コンカレントプログラム入力項目をメッセージ出力する
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appli_xxcok
                    ,iv_name         => cv_msg_cok_00022
                    ,iv_token_name1  => cv_token_business_date
                    ,iv_token_value1 => iv_business_date
                   );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT      -- 出力区分
                   ,iv_message  => lv_out_msg           -- メッセージ
                   ,in_new_line => 1                    -- 改行
                  );
    BEGIN
      -- 入力パラメータDATE型変換チェック
      IF( iv_business_date IS NOT NULL ) THEN
        gd_business_date := TO_DATE( iv_business_date, 'FXRRRR/MM/DD' );
      ELSE
        -- 業務日付取得
        gd_business_date := xxccp_common_pkg2.get_process_date;
        -- 業務日付取得エラー
        IF( gd_business_date IS NULL ) THEN
          lv_out_msg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appli_xxcok
                         ,iv_name         => cv_msg_cok_00028
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.OUTPUT    -- 出力区分
                         ,iv_message  => lv_out_msg         -- メッセージ
                         ,in_new_line => 0                  -- 改行
                        );
          RAISE no_process_date_expt;
        END IF;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appli_xxcok
                       ,iv_name         => cv_msg_cok_10342
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT     -- 出力区分
                       ,iv_message  => lv_out_msg          -- メッセージ
                       ,in_new_line => 0                   -- 改行
                      );
      RAISE date_prm_expt;
    END;
    -- システム日付を取得する
    gd_sysdate := SYSDATE;
    -- 営業単位IDを取得する
    gn_org_id  := FND_PROFILE.VALUE( cv_prof_org_id );
    IF( gn_org_id IS NULL ) THEN
      lv_err_profile := cv_prof_org_id;
      RAISE no_prifile_expt;
    END IF;
    -- 会社コード プロファイルを取得する
    gt_prof_aff1_company_code := FND_PROFILE.VALUE( cv_prof_aff1_company_code );
    IF( gt_prof_aff1_company_code IS NULL ) THEN
      lv_err_profile := cv_prof_aff1_company_code;
      RAISE no_prifile_expt;
    END IF;
-- 2009/06/29 Ver.1.7 [障害0000200] [障害0000290] SCS K.Yamaguchi DEL START
--    -- 販手販協計算処理期間（To）プロファイルを取得する
--    gt_prof_bs_period_to := FND_PROFILE.VALUE( cv_prof_bs_period_to );
--    IF( gt_prof_bs_period_to IS NULL ) THEN
--      lv_err_profile := cv_prof_bs_period_to;
--      RAISE no_prifile_expt;
--    END IF;
-- 2009/06/29 Ver.1.7 [障害0000200] [障害0000290] SCS K.Yamaguchi DEL END
    -- 条件別販手販協ディレクトリオブジェクト プロファイルを取得する
    gt_prof_bs_dire_path := FND_PROFILE.VALUE( cv_prof_bs_dire_path );
    IF( gt_prof_bs_dire_path IS NULL ) THEN
      lv_err_profile := cv_prof_bs_dire_path;
      RAISE no_prifile_expt;
    END IF;
    -- 条件別販手販協ファイル名 プロファイルを取得する
    gt_prof_bs_file_name := FND_PROFILE.VALUE( cv_prof_bs_file_name );
    IF( gt_prof_bs_file_name IS NULL ) THEN
      lv_err_profile := cv_prof_bs_file_name;
      RAISE no_prifile_expt;
    END IF;
    -- 単位コード(本) プロファイルを取得する
    gt_prof_uom_code_hon := FND_PROFILE.VALUE( cv_prof_uom_code_hon );
    IF( gt_prof_uom_code_hon IS NULL ) THEN
      lv_err_profile := cv_prof_uom_code_hon;
      RAISE no_prifile_expt;
    END IF;
-- 2009/06/29 Ver.1.7 [障害0000200] [障害0000290] SCS K.Yamaguchi DEL START
---- 2009/04/17 Ver.1.6 [障害T1_0641] SCS K.Yamaguchi ADD START
--    -- FB支払条件 プロファイルを取得する
--    gt_prof_fb_term_name := FND_PROFILE.VALUE( cv_prof_fb_term_name );
--    IF( gt_prof_fb_term_name IS NULL ) THEN
--      lv_err_profile := cv_prof_fb_term_name;
--      RAISE no_prifile_expt;
--    END IF;
---- 2009/04/17 Ver.1.6 [障害T1_0641] SCS K.Yamaguchi ADD END
-- 2009/06/29 Ver.1.7 [障害0000200] [障害0000290] SCS K.Yamaguchi DEL END
    -- ディレクトリオブジェクトよりパスを取得する
    gv_bs_dire_path := xxcok_common_pkg.get_directory_path_f(
                         iv_directory_name => gt_prof_bs_dire_path
                       );
    -- ディレクトリパスをメッセージ出力する
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appli_xxcok
                    ,iv_name         => cv_msg_cok_00067
                    ,iv_token_name1  => cv_token_directory
                    ,iv_token_value1 => gv_bs_dire_path
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT    -- 出力区分
                   ,iv_message  => lv_out_msg         -- メッセージ
                   ,in_new_line => 0                  -- 改行
                  );
    -- ファイル名をメッセージ出力する
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appli_xxcok
                    ,iv_name         => cv_msg_cok_00006
                    ,iv_token_name1  => cv_token_file_name
                    ,iv_token_value1 => gt_prof_bs_file_name
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT    -- 出力区分
                   ,iv_message  => lv_out_msg         -- メッセージ
                   ,in_new_line => 1                  -- 改行
                  );
    --========================================
    -- A-2.ファイル存在チェック
    --========================================
    UTL_FILE.FGETATTR(
      location    => gt_prof_bs_dire_path              -- ファイルパス
     ,filename    => gt_prof_bs_file_name              -- ファイル名
     ,fexists     => lb_exists                         -- ファイル存在チェック
     ,file_length => ln_file_length                    -- ファイルの長さ
     ,block_size  => ln_block_size                     -- ブロックサイズ
    );
    -- ファイルが存在している場合
    IF( lb_exists = TRUE ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_xxcok
                      ,iv_name         => cv_msg_cok_00009
                      ,iv_token_name1  => cv_token_file_name
                      ,iv_token_value1 => gt_prof_bs_file_name
                     );
      lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which    => FND_FILE.OUTPUT    -- 出力区分
                    ,iv_message  => lv_out_msg         -- メッセージ
                    ,in_new_line => 0                  -- 改行
                   );
      RAISE file_exists_expt;
    END IF;
    --=======================================
    -- ファイルオープン
    --=======================================
    gu_open_file_handle := UTL_FILE.FOPEN(
                             location     => gt_prof_bs_dire_path
                            ,filename     => gt_prof_bs_file_name
                            ,open_mode    => cv_open_mode
                            ,max_linesize => cn_max_linesize
                           );
--
  EXCEPTION
    -- *** 入力パラメータDATE型変換例外ハンドラ ****
    WHEN date_prm_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
    -- *** プロファイル取得例外ハンドラ ****
    WHEN no_prifile_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_xxcok
                      ,iv_name         => cv_msg_cok_00003
                      ,iv_token_name1  => cv_token_profile
                      ,iv_token_value1 => lv_err_profile
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT    -- 出力区分
                     ,iv_message  => lv_out_msg         -- メッセージ
                     ,in_new_line => 0                  -- 改行
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
    -- *** 業務日付取得例外ハンドラ ****
    WHEN no_process_date_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
    -- *** ファイル存在チェック例外ハンドラ ****
    WHEN file_exists_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
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
  END init;
--
-- 2009/06/29 Ver.1.7 [障害0000200] [障害0000290] SCS K.Yamaguchi DEL START
--  /**********************************************************************************
--   * Procedure Name   : get_cust_info
--   * Description      : 顧客情報取得処理(A-3)
--   ***********************************************************************************/
--  PROCEDURE get_cust_info(
--    ov_errbuf     OUT VARCHAR2             -- エラー・メッセージ
--   ,ov_retcode    OUT VARCHAR2             -- リターン・コード
--   ,ov_errmsg     OUT VARCHAR2             -- ユーザー・エラー・メッセージ
--  )
--  IS
--    --===============================
--    -- ローカル定数
--    --===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cust_info'; -- プログラム名
--    --===============================
--    -- ローカル変数
--    --===============================
--    lv_errbuf     VARCHAR2(5000) DEFAULT NULL;               -- エラー・メッセージ
--    lv_retcode    VARCHAR2(1)    DEFAULT NULL;               -- リターン・コード
--    lv_errmsg     VARCHAR2(5000) DEFAULT NULL;               -- ユーザー・エラー・メッセージ
----
--  BEGIN
--    -- ステータス初期化
--    ov_retcode := cv_status_normal;
--    -- 顧客情報を取得する
--    OPEN cust_info_cur;
--      FETCH cust_info_cur BULK COLLECT INTO gt_cust_info_tab;
--    CLOSE cust_info_cur;
----
--  EXCEPTION
--    -- *** 共通関数例外ハンドラ ***
--    WHEN global_api_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
--  END get_cust_info;
----
--  /**********************************************************************************
--   * Procedure Name   : get_bm_support_info
--   * Description      : 条件別販手販協情報取得処理(A-4)
--   ***********************************************************************************/
--  PROCEDURE get_bm_support_info(
--    ov_errbuf     OUT VARCHAR2            -- エラー・メッセージ
--   ,ov_retcode    OUT VARCHAR2            -- リターン・コード
--   ,ov_errmsg     OUT VARCHAR2            -- ユーザー・エラー・メッセージ
--   ,in_ci_cnt     IN  NUMBER              -- 索引カウンタ
--  )
--  IS
--    --===============================
--    -- ローカル定数
--    --===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_bm_support_info';   -- プログラム名
--    cv_00         CONSTANT VARCHAR2(2)   := '00';                    -- 支払条件
--    --===============================
--    -- ローカル変数
--    --===============================
--    lv_errbuf        VARCHAR2(5000) DEFAULT NULL;                       -- エラー・メッセージ
--    lv_retcode       VARCHAR2(1)    DEFAULT NULL;                       -- リターン・コード
--    lv_errmsg        VARCHAR2(5000) DEFAULT NULL;                       -- ユーザー・エラー・メッセージ
--    lb_retcode       BOOLEAN        DEFAULT NULL;                       -- リターン・コード
--    lv_out_msg       VARCHAR2(5000) DEFAULT NULL;                       -- メッセージ
--    lv_pay_cond      VARCHAR2(8)    DEFAULT NULL;                       -- 支払条件
--    ld_close_date    DATE           DEFAULT NULL;                       -- 締め日
--    ld_pay_date      DATE           DEFAULT NULL;                       -- 支払日
--    ld_op_day        DATE           DEFAULT NULL;                       -- 営業日
--    ld_business_date DATE           DEFAULT NULL;                       -- 業務処理日付-2日
--    --===============================
--    -- ローカル例外
--    --===============================
--    --*** 締め日取得例外 ***
--    close_date_expt    EXCEPTION;
--    --*** 営業日取得例外 ***
--    operating_day_expt EXCEPTION;
----
--  BEGIN
--    -- ステータス初期化
--    ov_retcode := cv_status_normal;
---- 2009/04/17 Ver.1.6 [障害T1_0641] SCS K.Yamaguchi REPAIR START
----    -- 取得したデータを結合し支払条件を設定する
----    lv_pay_cond := gt_cust_info_tab( in_ci_cnt ).close_day_code    || '_' ||
----                   gt_cust_info_tab( in_ci_cnt ).transfer_day_code || '_' || cv_00;
--    IF(    ( gt_cust_info_tab( in_ci_cnt ).close_day_code    IS NULL )
--        OR ( gt_cust_info_tab( in_ci_cnt ).transfer_day_code IS NULL )
--    ) THEN
--      lv_pay_cond := gt_prof_fb_term_name;
--    ELSE
--      -- 取得したデータを結合し支払条件を設定する
--      lv_pay_cond := gt_cust_info_tab( in_ci_cnt ).close_day_code    || '_' ||
--                     gt_cust_info_tab( in_ci_cnt ).transfer_day_code || '_' || cv_00;
--    END IF;
---- 2009/04/17 Ver.1.6 [障害T1_0641] SCS K.Yamaguchi REPAIR END
--    -- 業務処理日付－２営業日を取得する
--    ld_business_date := xxcok_common_pkg.get_operating_day_f(
--                          id_proc_date => gd_business_date     -- 処理日
--                         ,in_days      => cn_minus_2           -- 日数
--                         ,in_proc_type => cn_1                 -- 処理区分
--                        );
--    -- 締め日を取得する
--    xxcok_common_pkg.get_close_date_p(
--      ov_errbuf     => lv_errbuf
--     ,ov_retcode    => lv_retcode
--     ,ov_errmsg     => lv_errmsg
--     ,id_proc_date  => ld_business_date
--     ,iv_pay_cond   => lv_pay_cond
--     ,od_close_date => ld_close_date
--     ,od_pay_date   => ld_pay_date
--    );
--    -- 締め日取得エラー
--    IF( lv_retcode = cv_status_error ) THEN
--      lv_out_msg := xxccp_common_pkg.get_msg(
--                      iv_application   => cv_appli_xxcok
--                     ,iv_name          => cv_msg_cok_10369
--                     ,iv_token_name1   => cv_token_close_date
--                     ,iv_token_value1  => gd_business_date
--                     ,iv_token_name2   => cv_token_term_code
--                     ,iv_token_value2  => lv_pay_cond
--                    );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT    -- 出力区分
--                     ,iv_message  => lv_out_msg         -- メッセージ
--                     ,in_new_line => 0                  -- 改行
--                    );
--      RAISE close_date_expt;
--    END IF;
--    -- 営業日を取得する
--    ld_op_day := xxcok_common_pkg.get_operating_day_f(
--                   id_proc_date => ld_close_date                -- 処理日
--                  ,in_days      => gt_prof_bs_period_to         -- 日数
--                  ,in_proc_type => cn_2                         -- 処理区分
--                 );
--    -- 営業日取得エラー
--    IF( ld_op_day IS NULL ) THEN
--      lv_out_msg := xxccp_common_pkg.get_msg(
--                      iv_application   => cv_appli_xxcok
--                     ,iv_name          => cv_msg_cok_10203
--                     ,iv_token_name1   => cv_token_close_date
--                     ,iv_token_value1  => ld_close_date
--                    );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT    -- 出力区分
--                     ,iv_message  => lv_out_msg         -- メッセージ
--                     ,in_new_line => 0                  -- 改行
--                    );
--      RAISE operating_day_expt;
--    END IF;
--    -- 業務処理日付＝取得した営業日の場合
--    IF( gd_business_date = ld_op_day ) THEN
--      -- 条件別販手販協情報を取得する
--      OPEN bm_support_cur(
--             in_ci_cnt => in_ci_cnt
--           );
--        FETCH bm_support_cur BULK COLLECT INTO gt_bm_support_tab;
--      CLOSE bm_support_cur;
--    END IF;
----
--  EXCEPTION
--    -- *** 締め日取得例外ハンドラ ***
--    WHEN close_date_expt THEN
--      ov_errmsg  := NULL;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** 営業日取得例外ハンドラ ***
--    WHEN operating_day_expt THEN
--      ov_errmsg  := NULL;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** 共通関数例外ハンドラ ***
--    WHEN global_api_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
--  END get_bm_support_info;
----
--  /**********************************************************************************
--   * Procedure Name   : storage_plsql_tab
--   * Description      : PL/SQL表格納処理(A-5)
--   ***********************************************************************************/
--  PROCEDURE storage_plsql_tab(
--    ov_errbuf     OUT VARCHAR2              -- エラー・メッセージ
--   ,ov_retcode    OUT VARCHAR2              -- リターン・コード
--   ,ov_errmsg     OUT VARCHAR2              -- ユーザー・エラー・メッセージ
--   ,in_bs_cnt     IN  NUMBER                -- 条件別販手販協情報の索引カウンタ
--   ,in_idx_cnt    IN  NUMBER                -- PL/SQL表格納索引カウンタ
--  )
--  IS
--    --===============================
--    -- ローカル定数
--    --===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'storage_plsql_tab'; -- プログラム名
--    --===============================
--    -- ローカル変数
--    --===============================
--    lv_errbuf     VARCHAR2(5000) DEFAULT NULL;                   -- エラー・メッセージ
--    lv_retcode    VARCHAR2(1)    DEFAULT NULL;                   -- リターン・コード
--    lv_errmsg     VARCHAR2(5000) DEFAULT NULL;                   -- ユーザー・エラー・メッセージ
----
--  BEGIN
--    -- ステータス初期化
--    ov_retcode := cv_status_normal;
--    -- 取得したデータをPL/SQL表に格納する
--    gt_bms_csv_tab( in_idx_cnt ).sequence_number         := gt_bm_support_tab( in_bs_cnt ).cond_bm_support_id;       -- シーケンス番号
--    gt_bms_csv_tab( in_idx_cnt ).company_code            := gt_prof_aff1_company_code;                               -- 会社コード
--    gt_bms_csv_tab( in_idx_cnt ).base_code               := gt_bm_support_tab( in_bs_cnt ).base_code;                -- 拠点(部門) コード
--    gt_bms_csv_tab( in_idx_cnt ).emp_code                := gt_bm_support_tab( in_bs_cnt ).emp_code;                 -- 担当者コード
--    gt_bms_csv_tab( in_idx_cnt ).cust_code               := gt_bm_support_tab( in_bs_cnt ).delivery_cust_code;       -- 顧客コード
--    gt_bms_csv_tab( in_idx_cnt ).acctg_year              := gt_bm_support_tab( in_bs_cnt ).acctg_year;               -- 会計年度
--    gt_bms_csv_tab( in_idx_cnt ).chain_store_code        := gt_bm_support_tab( in_bs_cnt ).chain_store_code;         -- チェーン店コード
--    gt_bms_csv_tab( in_idx_cnt ).supplier_code           := gt_bm_support_tab( in_bs_cnt ).supplier_code;            -- 仕入先コード
--    gt_bms_csv_tab( in_idx_cnt ).supplier_site_code      := gt_bm_support_tab( in_bs_cnt ).supplier_site_code;       -- 支払先サイトコード
--    gt_bms_csv_tab( in_idx_cnt ).delivery_date           := gt_bm_support_tab( in_bs_cnt ).delivery_date;            -- 納品日年月
--    gt_bms_csv_tab( in_idx_cnt ).delivery_qty            := gt_bm_support_tab( in_bs_cnt ).delivery_qty;             -- 納品数量
--    gt_bms_csv_tab( in_idx_cnt ).delivery_unit_type      := gt_prof_uom_code_hon;                                    -- 納品単位(本/ケース)
--    gt_bms_csv_tab( in_idx_cnt ).selling_amt_tax         := gt_bm_support_tab( in_bs_cnt ).selling_amt_tax;          -- 売上金額(税込)
--    gt_bms_csv_tab( in_idx_cnt ).account_type            := gt_bm_support_tab( in_bs_cnt ).calc_type;                -- 取引条件
--    gt_bms_csv_tab( in_idx_cnt ).rebate_rate             := gt_bm_support_tab( in_bs_cnt ).rebate_rate;              -- 割戻率
--    gt_bms_csv_tab( in_idx_cnt ).rebate_amt              := gt_bm_support_tab( in_bs_cnt ).rebate_amt;               -- 割戻額
--    gt_bms_csv_tab( in_idx_cnt ).container_type_code     := gt_bm_support_tab( in_bs_cnt ).container_type_code;      -- 容器区分コード
--    gt_bms_csv_tab( in_idx_cnt ).selling_price           := gt_bm_support_tab( in_bs_cnt ).selling_price;            -- 売価金額
--    gt_bms_csv_tab( in_idx_cnt ).cond_bm_amt_tax         := gt_bm_support_tab( in_bs_cnt ).cond_bm_amt_tax;          -- 条件別手数料額(税込)
--    gt_bms_csv_tab( in_idx_cnt ).cond_bm_amt_no_tax      := gt_bm_support_tab( in_bs_cnt ).cond_bm_amt_no_tax;       -- 条件別手数料額(税抜)
--    gt_bms_csv_tab( in_idx_cnt ).cond_tax_amt            := gt_bm_support_tab( in_bs_cnt ).cond_tax_amt;             -- 条件別消費税額
--    gt_bms_csv_tab( in_idx_cnt ).electric_amt            := gt_bm_support_tab( in_bs_cnt ).electric_amt_tax;         -- 電気料
--    gt_bms_csv_tab( in_idx_cnt ).closing_date            := gt_bm_support_tab( in_bs_cnt ).closing_date;             -- 締日
--    gt_bms_csv_tab( in_idx_cnt ).expect_payment_date     := gt_bm_support_tab( in_bs_cnt ).expect_payment_date;      -- 支払日
--    gt_bms_csv_tab( in_idx_cnt ).calc_target_period_from := gt_bm_support_tab( in_bs_cnt ).calc_target_period_from;  -- 計算対象期間(From)
--    gt_bms_csv_tab( in_idx_cnt ).calc_target_period_to   := gt_bm_support_tab( in_bs_cnt ).calc_target_period_to;    -- 計算対象期間(To)
--    gt_bms_csv_tab( in_idx_cnt ).ref_base_code           := gt_bm_support_tab( in_bs_cnt ).ref_base_code;            -- 問合わせ担当拠点コード
--    gt_bms_csv_tab( in_idx_cnt ).interface_date          := gd_sysdate;                                              -- 連携日時
----
--  EXCEPTION
--    -- *** 共通関数例外ハンドラ ***
--    WHEN global_api_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
--  END storage_plsql_tab;
-- 2009/06/29 Ver.1.7 [障害0000200] [障害0000290] SCS K.Yamaguchi DEL END
--
  /**********************************************************************************
   * Procedure Name   : output_csv_file
   * Description      : ファイル出力処理(A-6)
   ***********************************************************************************/
  PROCEDURE output_csv_file(
    ov_errbuf     OUT VARCHAR2     -- エラー・メッセージ
   ,ov_retcode    OUT VARCHAR2     -- リターン・コード
   ,ov_errmsg     OUT VARCHAR2     -- ユーザー・エラー・メッセージ
-- 2009/06/29 Ver.1.7 [障害0000200] [障害0000290] SCS K.Yamaguchi REPAIR START
--   ,in_csv_cnt    IN  NUMBER       -- 索引カウンタ
   ,i_bm_support_rec IN  bm_support_cur%ROWTYPE   -- 条件別販手販協情報
-- 2009/06/29 Ver.1.7 [障害0000200] [障害0000290] SCS K.Yamaguchi REPAIR END
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_csv_file'; -- プログラム名
    cv_comma      CONSTANT VARCHAR2(1)   := ',';               -- コンマ
    cv_wq         CONSTANT VARCHAR2(1)   := '"';               -- ダブルコーテーション
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf     VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode    VARCHAR2(1)    DEFAULT NULL;                 -- リターン・コード
    lv_errmsg     VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_csv_file   VARCHAR2(5000) DEFAULT NULL;                 -- CSVファイル
-- 2009/10/08 Ver.1.8 [障害E_最終移行リハ_00460] SCS S.Moriyama ADD START
    lt_rebate_amt xxcok_cond_bm_support.rebate_amt%TYPE;       -- 割戻額
-- 2009/10/08 Ver.1.8 [障害E_最終移行リハ_00460] SCS S.Moriyama ADD END
    
--
  BEGIN
    -- ステータス初期化
    ov_retcode := cv_status_normal;
    --
-- 2009/10/08 Ver.1.8 [障害E_最終移行リハ_00460] SCS S.Moriyama ADD START
    IF ( i_bm_support_rec.calc_type = cv_except_calc_type ) THEN
      lt_rebate_amt := NULL;
    ELSE
      lt_rebate_amt := i_bm_support_rec.rebate_amt;
    END IF;
-- 2009/10/08 Ver.1.8 [障害E_最終移行リハ_00460] SCS S.Moriyama ADD END
-- 2009/06/29 Ver.1.7 [障害0000200] [障害0000290] SCS K.Yamaguchi REPAIR START
--    lv_csv_file := TO_CHAR( gt_bms_csv_tab( in_csv_cnt ).sequence_number )                     || cv_comma || -- シーケンス番号
--          cv_wq ||          gt_bms_csv_tab( in_csv_cnt ).company_code                 || cv_wq || cv_comma || -- 会社コード
--          cv_wq ||          gt_bms_csv_tab( in_csv_cnt ).base_code                    || cv_wq || cv_comma || -- 拠点(部門) コード
--          cv_wq ||          gt_bms_csv_tab( in_csv_cnt ).emp_code                     || cv_wq || cv_comma || -- 担当者コード
--          cv_wq ||          gt_bms_csv_tab( in_csv_cnt ).cust_code                    || cv_wq || cv_comma || -- 顧客コード
--                            gt_bms_csv_tab( in_csv_cnt ).acctg_year                            || cv_comma || -- 会計年度
--          cv_wq ||          gt_bms_csv_tab( in_csv_cnt ).chain_store_code             || cv_wq || cv_comma || -- チェーン店コード
--          cv_wq ||          gt_bms_csv_tab( in_csv_cnt ).supplier_code                || cv_wq || cv_comma || -- 仕入先コード
--          cv_wq ||          gt_bms_csv_tab( in_csv_cnt ).supplier_site_code           || cv_wq || cv_comma || -- 支払先サイトコード
--                   TO_CHAR( gt_bms_csv_tab( in_csv_cnt ).delivery_date )                       || cv_comma || -- 納品日年月
---- Start 2009/03/26 Ver_1.5 M.Hiruta
----                   TO_CHAR( gt_bms_csv_tab( in_csv_cnt ).delivery_qty )                        || cv_comma || -- 納品数量
--                   TO_CHAR( NVL( gt_bms_csv_tab( in_csv_cnt ).delivery_qty , cv_0 ) )          || cv_comma || -- 納品数量
---- End   2009/03/26 Ver_1.5 M.Hiruta
--          cv_wq ||          gt_bms_csv_tab( in_csv_cnt ).delivery_unit_type           || cv_wq || cv_comma || -- 納品単位(本/ケース)
--                   TO_CHAR( gt_bms_csv_tab( in_csv_cnt ).selling_amt_tax )                     || cv_comma || -- 売上金額(税込)
--          cv_wq ||          gt_bms_csv_tab( in_csv_cnt ).account_type                 || cv_wq || cv_comma || -- 取引条件
--                   TO_CHAR( gt_bms_csv_tab( in_csv_cnt ).rebate_rate )                         || cv_comma || -- 割戻率
--                   TO_CHAR( gt_bms_csv_tab( in_csv_cnt ).rebate_amt )                          || cv_comma || -- 割戻額
--          cv_wq ||          gt_bms_csv_tab( in_csv_cnt ).container_type_code          || cv_wq || cv_comma || -- 容器区分コード
--                   TO_CHAR( gt_bms_csv_tab( in_csv_cnt ).selling_price )                       || cv_comma || -- 売価金額
--                   TO_CHAR( gt_bms_csv_tab( in_csv_cnt ).cond_bm_amt_tax )                     || cv_comma || -- 条件別手数料額(税込)
--                   TO_CHAR( gt_bms_csv_tab( in_csv_cnt ).cond_bm_amt_no_tax )                  || cv_comma || -- 条件別手数料額(税抜)
--                   TO_CHAR( gt_bms_csv_tab( in_csv_cnt ).cond_tax_amt )                        || cv_comma || -- 条件別消費税額
--                   TO_CHAR( gt_bms_csv_tab( in_csv_cnt ).electric_amt )                        || cv_comma || -- 電気料
--                   TO_CHAR( gt_bms_csv_tab( in_csv_cnt ).closing_date, 'YYYYMMDD' )            || cv_comma || -- 締日
--                   TO_CHAR( gt_bms_csv_tab( in_csv_cnt ).expect_payment_date, 'YYYYMMDD' )     || cv_comma || -- 支払日
--                   TO_CHAR( gt_bms_csv_tab( in_csv_cnt ).calc_target_period_from, 'YYYYMMDD' ) || cv_comma || -- 計算対象期間(From)
--                   TO_CHAR( gt_bms_csv_tab( in_csv_cnt ).calc_target_period_to, 'YYYYMMDD' )   || cv_comma || -- 計算対象期間(To)
--          cv_wq ||          gt_bms_csv_tab( in_csv_cnt ).ref_base_code                || cv_wq || cv_comma || -- 問合わせ担当拠点コード
--                   TO_CHAR( gt_bms_csv_tab( in_csv_cnt ).interface_date, 'YYYYMMDDHHMISS' );                  -- 連携日時
    lv_csv_file := TO_CHAR( i_bm_support_rec.cond_bm_support_id )                            || cv_comma || -- シーケンス番号
          cv_wq ||          gt_prof_aff1_company_code                               || cv_wq || cv_comma || -- 会社コード
          cv_wq ||          i_bm_support_rec.base_code                              || cv_wq || cv_comma || -- 拠点(部門) コード
          cv_wq ||          i_bm_support_rec.emp_code                               || cv_wq || cv_comma || -- 担当者コード
          cv_wq ||          i_bm_support_rec.delivery_cust_code                     || cv_wq || cv_comma || -- 顧客コード
                            i_bm_support_rec.acctg_year                                      || cv_comma || -- 会計年度
          cv_wq ||          i_bm_support_rec.chain_store_code                       || cv_wq || cv_comma || -- チェーン店コード
          cv_wq ||          i_bm_support_rec.supplier_code                          || cv_wq || cv_comma || -- 仕入先コード
          cv_wq ||          i_bm_support_rec.supplier_site_code                     || cv_wq || cv_comma || -- 支払先サイトコード
                   TO_CHAR( i_bm_support_rec.delivery_date )                                 || cv_comma || -- 納品日年月
                   TO_CHAR( NVL( i_bm_support_rec.delivery_qty , cv_0 ) )                    || cv_comma || -- 納品数量
          cv_wq ||          gt_prof_uom_code_hon                                    || cv_wq || cv_comma || -- 納品単位(本/ケース)
                   TO_CHAR( i_bm_support_rec.selling_amt_tax )                               || cv_comma || -- 売上金額(税込)
          cv_wq ||          i_bm_support_rec.calc_type                              || cv_wq || cv_comma || -- 取引条件
                   TO_CHAR( i_bm_support_rec.rebate_rate )                                   || cv_comma || -- 割戻率
-- 2009/10/08 Ver.1.8 [障害E_最終移行リハ_00460] SCS S.Moriyama UPD START
--                   TO_CHAR( i_bm_support_rec.rebate_amt )                                    || cv_comma || -- 割戻額
                   TO_CHAR( lt_rebate_amt )                                                  || cv_comma || -- 割戻額
-- 2009/10/08 Ver.1.8 [障害E_最終移行リハ_00460] SCS S.Moriyama UPD END
          cv_wq ||          i_bm_support_rec.container_type_code                    || cv_wq || cv_comma || -- 容器区分コード
                   TO_CHAR( i_bm_support_rec.selling_price )                                 || cv_comma || -- 売価金額
                   TO_CHAR( i_bm_support_rec.cond_bm_amt_tax )                               || cv_comma || -- 条件別手数料額(税込)
                   TO_CHAR( i_bm_support_rec.cond_bm_amt_no_tax )                            || cv_comma || -- 条件別手数料額(税抜)
                   TO_CHAR( i_bm_support_rec.cond_tax_amt )                                  || cv_comma || -- 条件別消費税額
                   TO_CHAR( i_bm_support_rec.electric_amt_tax )                              || cv_comma || -- 電気料
                   TO_CHAR( i_bm_support_rec.closing_date           , 'YYYYMMDD' )           || cv_comma || -- 締日
                   TO_CHAR( i_bm_support_rec.expect_payment_date    , 'YYYYMMDD' )           || cv_comma || -- 支払日
                   TO_CHAR( i_bm_support_rec.calc_target_period_from, 'YYYYMMDD' )           || cv_comma || -- 計算対象期間(From)
                   TO_CHAR( i_bm_support_rec.calc_target_period_to  , 'YYYYMMDD' )           || cv_comma || -- 計算対象期間(To)
          cv_wq ||          i_bm_support_rec.ref_base_code                          || cv_wq || cv_comma || -- 問合わせ担当拠点コード
-- 2009/10/08 Ver.1.8 [障害E_最終移行リハ_00460] SCS S.Moriyama UPD START
--                   TO_CHAR( gd_sysdate, 'YYYYMMDDHHMISS' );                  -- 連携日時
                   TO_CHAR( gd_sysdate, 'YYYYMMDDHH24MISS' );                                               -- 連携日時
-- 2009/10/08 Ver.1.8 [障害E_最終移行リハ_00460] SCS S.Moriyama UPD END
-- 2009/06/29 Ver.1.7 [障害0000200] [障害0000290] SCS K.Yamaguchi REPAIR END
    -- CSVファイル出力
    UTL_FILE.PUT_LINE(
       file      => gu_open_file_handle
      ,buffer    => lv_csv_file
    );
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
  END output_csv_file;
--
  /**********************************************************************************
   * Procedure Name   : upd_cond_bm_support
   * Description      : 条件別販手販協テーブル更新処理(A-7)
   ***********************************************************************************/
  PROCEDURE upd_cond_bm_support(
    ov_errbuf     OUT VARCHAR2                                     -- エラー・メッセージ
   ,ov_retcode    OUT VARCHAR2                                     -- リターン・コード
   ,ov_errmsg     OUT VARCHAR2                                     -- ユーザー・エラー・メッセージ
-- 2009/06/29 Ver.1.7 [障害0000200] [障害0000290] SCS K.Yamaguchi REPAIR START
--   ,in_bs_cnt     IN  NUMBER                                       -- 索引カウンタ
   ,i_bm_support_rec IN  bm_support_cur%ROWTYPE   -- 条件別販手販協情報
-- 2009/06/29 Ver.1.7 [障害0000200] [障害0000290] SCS K.Yamaguchi REPAIR END
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_cond_bm_support'; -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf     VARCHAR2(5000) DEFAULT NULL;                     -- エラー・メッセージ
    lv_retcode    VARCHAR2(1)    DEFAULT NULL;                     -- リターン・コード
    lv_errmsg     VARCHAR2(5000) DEFAULT NULL;                     -- ユーザー・エラー・メッセージ
    lv_out_msg    VARCHAR2(5000) DEFAULT NULL;                     -- メッセージ
    lb_retcode    BOOLEAN        DEFAULT NULL;                     -- リターン・コード
--
  BEGIN
    -- ステータス初期化
    ov_retcode := cv_status_normal;
    -- 条件別販手販協テーブルのロックを取得する
    OPEN lock_cond_bm_support_cur(
-- 2009/06/29 Ver.1.7 [障害0000200] [障害0000290] SCS K.Yamaguchi REPAIR START
--           in_cond_bm_support_id => gt_bms_csv_tab( in_bs_cnt ).sequence_number
           in_cond_bm_support_id => i_bm_support_rec.cond_bm_support_id
-- 2009/06/29 Ver.1.7 [障害0000200] [障害0000290] SCS K.Yamaguchi REPAIR END
         );
    CLOSE lock_cond_bm_support_cur;
    -- 条件別販手販協テーブル更新処理を行なう
    UPDATE xxcok_cond_bm_support    xcbs                                                    -- 条件別販手販協テーブル
    SET    xcbs.cond_bm_interface_status = cv_1                                             -- 連携ステータス
          ,xcbs.cond_bm_interface_date   = gd_sysdate                                       -- 連携日
          ,xcbs.last_updated_by          = cn_last_updated_by                               -- 最終更新者
          ,xcbs.last_update_date         = SYSDATE                                          -- 最終更新日
          ,xcbs.last_update_login        = cn_last_update_login                             -- 最終更新ログイン
          ,xcbs.request_id               = cn_request_id                                    -- 要求ID
          ,xcbs.program_application_id   = cn_program_application_id                        -- コンカレント・プログラム・アプリケーションID
          ,xcbs.program_id               = cn_program_id                                    -- コンカレント・プログラムID
          ,xcbs.program_update_date      = SYSDATE                                          -- プログラム更新日
-- 2009/06/29 Ver.1.7 [障害0000200] [障害0000290] SCS K.Yamaguchi REPAIR START
--    WHERE  xcbs.cond_bm_support_id       = gt_bms_csv_tab( in_bs_cnt ).sequence_number;
    WHERE  xcbs.cond_bm_support_id       = i_bm_support_rec.cond_bm_support_id
    ;
-- 2009/06/29 Ver.1.7 [障害0000200] [障害0000290] SCS K.Yamaguchi REPAIR END
--
  EXCEPTION
    -- *** 共通ロック取得例外ハンドラ ***
    WHEN global_lock_err_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application => cv_appli_xxcok
                      ,iv_name        => cv_msg_cok_00051
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT    -- 出力区分
                     ,iv_message  => lv_out_msg         -- メッセージ
                     ,in_new_line => 0                  -- 改行
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
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
  END upd_cond_bm_support;
--
  /**********************************************************************************
   * Procedure Name   : create_csv_file
   * Description      : 条件別販手販協情報csvファイル作成
   ***********************************************************************************/
  PROCEDURE create_csv_file(
    ov_errbuf   OUT VARCHAR2            -- エラー・メッセージ
   ,ov_retcode  OUT VARCHAR2            -- リターン・コード
   ,ov_errmsg   OUT VARCHAR2            -- ユーザー・エラー・メッセージ
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'create_csv_file';    -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL;                    -- エラー・メッセージ
    lv_retcode  VARCHAR2(1)    DEFAULT NULL;                    -- リターン・コード
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL;                    -- ユーザー・エラー・メッセージ
    ln_ci_cnt   NUMBER         DEFAULT NULL;                    -- 顧客情報取得の索引カウンタ
    ln_bs_cnt   NUMBER         DEFAULT NULL;                    -- 条件別販手販協情報の索引カウンタ
    ln_csv_cnt  NUMBER         DEFAULT NULL;                    -- CSV出力の索引カウンタ
    ln_idx_cnt  NUMBER         DEFAULT NULL;                    -- PL/SQL表格納索引カウンタ
--
  BEGIN
    -- ステータス初期化
    ov_retcode := cv_status_normal;
-- 2009/06/29 Ver.1.7 [障害0000200] [障害0000290] SCS K.Yamaguchi REPAIR START
--    -- 索引カウンタ初期化
--    ln_ci_cnt  := 0;                                    -- 顧客情報取得の索引カウンタ
--    ln_bs_cnt  := 0;                                    -- 条件別販手販協情報の索引カウンタ
--    ln_csv_cnt := 0;                                    -- CSV出力の索引カウンタ
--    ln_idx_cnt := 0;                                    -- PL/SQL表格納索引カウンタ
--    --===================================
--    -- A-3.顧客情報取得処理
--    --===================================
--    get_cust_info(
--       ov_errbuf  => lv_errbuf                          -- エラー・メッセージ
--      ,ov_retcode => lv_retcode                         -- リターン・コード
--      ,ov_errmsg  => lv_errmsg                          -- ユーザー・エラー・メッセージ
--    );
--    IF( lv_retcode = cv_status_error ) THEN
--      RAISE global_process_expt;
--    END IF;
--    <<cust_info_loop>>                                  -- 顧客ループ START
--    FOR ln_ci_cnt IN 1 .. gt_cust_info_tab.COUNT LOOP
--      --===================================
--      -- A-4.条件別販手販協情報取得処理
--      --===================================
--      get_bm_support_info(
--         ov_errbuf            => lv_errbuf              -- エラー・メッセージ
--        ,ov_retcode           => lv_retcode             -- リターン・コード
--        ,ov_errmsg            => lv_errmsg              -- ユーザー・エラー・メッセージ
--        ,in_ci_cnt            => ln_ci_cnt              -- 顧客情報取得の索引カウンタ
--      );
--      IF( lv_retcode = cv_status_error ) THEN
--        RAISE global_process_expt;
--      END IF;
--      <<bm_support_tab_loop>>                           -- 条件別販手ループ START
--      FOR ln_bs_cnt IN 1 .. gt_bm_support_tab.COUNT LOOP
--        -- PL/SQL表格納索引カウント
--        ln_idx_cnt    := ln_idx_cnt + 1;
--        --===================================
--        -- A-5.PL/SQL表格納処理
--        --===================================
--        storage_plsql_tab(
--          ov_errbuf  => lv_errbuf                       -- エラー・メッセージ
--         ,ov_retcode => lv_retcode                      -- リターン・コード
--         ,ov_errmsg  => lv_errmsg                       -- ユーザー・エラー・メッセージ
--         ,in_bs_cnt  => ln_bs_cnt                       -- 条件別販手販協情報の索引カウンタ
--         ,in_idx_cnt => ln_idx_cnt                      -- PL/SQL表格納索引カウンタ
--        );
--        IF( lv_retcode = cv_status_error ) THEN
--          RAISE global_process_expt;
--        END IF;
--        -- 対象件数カウント
--        gn_target_cnt := gn_target_cnt + 1;
--      END LOOP bm_support_tab_loop;                     -- 条件別販手ループ END
--    END LOOP cust_info_loop;                            -- 顧客ループ END
--    <<bms_csv_tab_loop>>                                -- 出力ループ START
--      FOR ln_csv_cnt IN 1 .. gt_bms_csv_tab.COUNT LOOP
--      --===================================
--      -- A-6.ファイル出力処理
--      --===================================
--      output_csv_file(
--        ov_errbuf  => lv_errbuf                         -- エラー・メッセージ
--       ,ov_retcode => lv_retcode                        -- リターン・コード
--       ,ov_errmsg  => lv_errmsg                         -- ユーザー・エラー・メッセージ
--       ,in_csv_cnt => ln_csv_cnt                        -- CSV出力の索引カウンタ
--      );
--      IF( lv_retcode = cv_status_error ) THEN
--        RAISE global_process_expt;
--      END IF;
--      -- 成功件数カウント
--      gn_normal_cnt := gn_normal_cnt + 1;
--      --===================================
--      -- A-7.条件別販手販協テーブル更新処理
--      --===================================
--      upd_cond_bm_support(
--        ov_errbuf  => lv_errbuf                         -- エラー・メッセージ
--       ,ov_retcode => lv_retcode                        -- リターン・コード
--       ,ov_errmsg  => lv_errmsg                         -- ユーザー・エラー・メッセージ
--       ,in_bs_cnt  => ln_csv_cnt                        -- 索引カウンタ
--      );
--      IF( lv_retcode = cv_status_error ) THEN
--        RAISE global_process_expt;
--      END IF;
--    END LOOP bms_csv_tab_loop;                          -- 出力ループ END
    --===================================
    -- A-4.条件別販手販協情報取得処理
    --===================================
    << bm_support_loop >>
    FOR bm_support_rec IN bm_support_cur LOOP
      --===================================
      -- A-6.ファイル出力処理
      --===================================
      output_csv_file(
        ov_errbuf             => lv_errbuf             -- エラー・メッセージ
      , ov_retcode            => lv_retcode            -- リターン・コード
      , ov_errmsg             => lv_errmsg             -- ユーザー・エラー・メッセージ
      , i_bm_support_rec      => bm_support_rec        -- 条件別販手販協情報
      );
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      --===================================
      -- A-7.条件別販手販協テーブル更新処理
      --===================================
      upd_cond_bm_support(
        ov_errbuf             => lv_errbuf             -- エラー・メッセージ
      , ov_retcode            => lv_retcode            -- リターン・コード
      , ov_errmsg             => lv_errmsg             -- ユーザー・エラー・メッセージ
      , i_bm_support_rec      => bm_support_rec        -- 条件別販手販協情報
      );
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      gn_target_cnt := gn_target_cnt + 1;
      -- 成功件数カウント
      gn_normal_cnt := gn_normal_cnt + 1;
    END LOOP bm_support_loop;
-- 2009/06/29 Ver.1.7 [障害0000200] [障害0000290] SCS K.Yamaguchi REPAIR END
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END create_csv_file;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf        OUT VARCHAR2     -- エラー・メッセージ
   ,ov_retcode       OUT VARCHAR2     -- リターン・コード
   ,ov_errmsg        OUT VARCHAR2     -- ユーザー・エラー・メッセージ
   ,iv_business_date IN  VARCHAR2     -- 起動パラメータ
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'submain';   -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL;           -- エラー・メッセージ
    lv_retcode  VARCHAR2(1)    DEFAULT NULL;           -- リターン・コード
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL;           -- ユーザー・エラー・メッセージ
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    --===============================
    -- A-1.初期処理
    --===============================
    init(
      ov_errbuf        => lv_errbuf               -- エラー・メッセージ
     ,ov_retcode       => lv_retcode              -- リターン・コード
     ,ov_errmsg        => lv_errmsg               -- ユーザー・エラー・メッセージ
     ,iv_business_date => iv_business_date        -- 入力パラメータ・業務日付
    );
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    --===================================
    -- 条件別販手販協情報csvファイル作成
    --===================================
    create_csv_file(
      ov_errbuf  => lv_errbuf               -- エラー・メッセージ
     ,ov_retcode => lv_retcode              -- リターン・コード
     ,ov_errmsg  => lv_errmsg               -- ユーザー・エラー・メッセージ
    );
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
    --=================================
    -- A-8.ファイルクローズ
    --=================================
   IF( UTL_FILE.IS_OPEN( gu_open_file_handle ) ) THEN
      UTL_FILE.FCLOSE(
         file => gu_open_file_handle
      );
    END IF;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      --=================================
      -- A-8.ファイルクローズ
      --=================================
      IF( UTL_FILE.IS_OPEN( gu_open_file_handle ) ) THEN
        UTL_FILE.FCLOSE(
           file => gu_open_file_handle
        );
      END IF;
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
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf           OUT VARCHAR2      -- エラー・メッセージ
   ,retcode          OUT VARCHAR2      -- リターン・コード
   ,iv_business_date IN  VARCHAR2      -- 起動パラメータ
  )
  IS
--
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';   -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf          VARCHAR2(5000) DEFAULT NULL;        -- エラー・メッセージ
    lv_retcode         VARCHAR2(1)    DEFAULT NULL;        -- リターン・コード
    lv_errmsg          VARCHAR2(5000) DEFAULT NULL;        -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100)  DEFAULT NULL;        -- 終了メッセージコード
    lb_retcode         BOOLEAN        DEFAULT NULL;        -- リターン・コード
    lv_out_msg         VARCHAR2(5000) DEFAULT NULL;        -- メッセージ
--
  BEGIN
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode                            -- エラー・メッセージ
      ,ov_errbuf  => lv_errbuf                             -- リターン・コード
      ,ov_errmsg  => lv_errmsg                             -- ユーザー・エラー・メッセージ
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       ov_errbuf        => lv_errbuf                -- エラー・メッセージ
      ,ov_retcode       => lv_retcode               -- リターン・コード
      ,ov_errmsg        => lv_errmsg                -- ユーザー・エラー・メッセージ
      ,iv_business_date => iv_business_date         -- 起動パラメータ
    );
    IF( lv_retcode = cv_status_error ) THEN
      -- エラー件数カウント
      gn_error_cnt := 1;
      -- メッセージ出力
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT    -- 出力区分
                     ,iv_message  => lv_errmsg          -- メッセージ
                     ,in_new_line => 1                  -- 改行
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG       -- 出力区分
                     ,iv_message  => lv_errbuf          -- メッセージ
                     ,in_new_line => 1                  -- 改行
                    );
    END IF;
    --================================================
    -- A-9.終了処理
    --================================================
    -- 対象件数
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appli_xxccp
                    ,iv_name         => cv_msg_ccp_90000
                    ,iv_token_name1  => cv_token_count
                    ,iv_token_value1 => TO_CHAR( gn_target_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT    -- 出力区分
                   ,iv_message  => lv_out_msg         -- メッセージ
                   ,in_new_line => 0                  -- 改行
                  );
    --成功件数
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appli_xxccp
                    ,iv_name         => cv_msg_ccp_90001
                    ,iv_token_name1  => cv_token_count
                    ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
                   );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT    -- 出力区分
                   ,iv_message  => lv_out_msg         -- メッセージ
                   ,in_new_line => 0                  -- 改行
                  );
    --エラー件数
    lv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appli_xxccp
                   ,iv_name         => cv_msg_ccp_90002
                   ,iv_token_name1  => cv_token_count
                   ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT    -- 出力区分
                   ,iv_message  => lv_out_msg         -- メッセージ
                   ,in_new_line => 1                  -- 改行
                  );
    --ステータスセット
    retcode := lv_retcode;
    -- 終了ステータスが正常の場合は正常終了メッセージを出力する
    IF( retcode = cv_status_normal ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_xxccp
                     ,iv_name         => cv_msg_ccp_90004
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT    -- 出力区分
                     ,iv_message  => lv_out_msg         -- メッセージ
                     ,in_new_line => 0                  -- 改行
                    );
    -- 終了ステータスがエラーの場合はROLLBACKする
    ELSIF( retcode = cv_status_error ) THEN
      ROLLBACK;
      -- ロールバックメッセージ
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_xxccp
                      ,iv_name         => cv_msg_ccp_90006
                     );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT    -- 出力区分
                     ,iv_message  => lv_out_msg         -- メッセージ
                     ,in_new_line => 0                  -- 改行
                    );
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
END XXCOK014A02C;
/
