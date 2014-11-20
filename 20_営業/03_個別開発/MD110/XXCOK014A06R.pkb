CREATE OR REPLACE PACKAGE BODY XXCOK014A06R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK014A06R(body)
 * Description      : 条件別販手販協計算処理実行時に販手条件マスタ未登録の販売実績をエラーリストに出力
 * MD.050           : 自販機販手条件エラーリスト MD050_COK_014_A06
 * Version          : 1.5
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  delete_err_data        ワークテーブルデータ削除(A-6)
 *  start_svf              SVF起動処理(A-5)
 *  insert_err_data        ワークテーブル登録処理(A-4)
 *  get_mst_info           売上拠点・顧客情報抽出処理(A-3)
 *  get_err_data           販手条件エラー情報抽出処理(A-2)
 *  init                   初期処理(A-1)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/24    1.0   S.Tozawa         新規作成
 *  2009/03/02    1.1   M.Hiruta         [障害COK_066] 容器区分取得方法変更
 *  2009/03/25    1.2   S.Kayahara       最終行にスラッシュ追加
 *  2009/03/02    1.3   K.Yamaguchi      [障害T1_0510] 売上拠点情報取得SQL文の不足対応
 *  2009/09/01    1.4   S.Moriyama       [障害0001230] OPM品目マスタ取得条件追加
 *  2011/02/02    1.5   S.Ochiai         [障害E_本稼動_05408] 年次切替対応
 *
 *****************************************************************************************/
  -- ===============================================
  -- グローバル定数
  -- ===============================================
  -- パッケージ名
  cv_pkg_name                CONSTANT VARCHAR2(20)  := 'XXCOK014A06R';
  -- アプリケーション短縮名
  cv_xxcok_appl_short_name   CONSTANT VARCHAR2(10)  := 'XXCOK';
  cv_xxccp_appl_short_name   CONSTANT VARCHAR2(10)  := 'XXCCP';
  -- ステータス・コード
  cv_status_normal           CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_normal;  -- 正常:0
  cv_status_warn             CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_warn;    -- 警告:1
  cv_status_error            CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_error;   -- 異常:2
  -- WHOカラム
  cn_created_by              CONSTANT NUMBER        := fnd_global.user_id;          -- CREATED_BY
  cn_last_updated_by         CONSTANT NUMBER        := fnd_global.user_id;          -- LAST_UPDATED_BY
  cn_last_update_login       CONSTANT NUMBER        := fnd_global.login_id;         -- LAST_UPDATE_LOGIN
  cn_request_id              CONSTANT NUMBER        := fnd_global.conc_request_id;  -- REQUEST_ID
  cn_program_application_id  CONSTANT NUMBER        := fnd_global.prog_appl_id;     -- PROGRAM_APPLICATION_ID
  cn_program_id              CONSTANT NUMBER        := fnd_global.conc_program_id;  -- PROGRAM_ID
  -- メッセージコード
  cv_msg_code_00001          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00001';          -- 対象データなしメッセージ
  cv_msg_code_00074          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00074';          -- パラメータログ出力用メッセージ
  cv_msg_code_00003          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00003';          -- プロファイル取得エラー
  cv_msg_code_00013          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00013';          -- 在庫組織ID取得エラー
  cv_msg_code_00048          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00048';          -- 売上計上拠点情報0件エラー
  cv_msg_code_00047          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00047';          -- 売上計上拠点情報複数件エラー
  cv_msg_code_00035          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00035';          -- 顧客情報0件エラー
  cv_msg_code_00046          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00046';          -- 顧客情報複数件取得エラー
  cv_msg_code_00056          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00056';          -- 品目情報取得エラー
  cv_msg_code_00015          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00015';          -- 容器情報取得エラー
-- 2009/09/01 Ver.1.4 [障害0001230] SCS S.Moriyama ADD START
  cv_msg_code_00028          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00028';          -- 業務処理日付取得エラー
-- 2009/09/01 Ver.1.4 [障害0001230] SCS S.Moriyama ADD END
  cv_msg_code_00040          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00040';          -- SVF起動APIエラー
  cv_msg_code_10321          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10321';          -- ロック取得エラー
  cv_msg_code_10397          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10397';          -- データ削除エラー
  cv_msg_code_90000          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90000';          -- 対象件数
  cv_msg_code_90001          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90001';          -- 成功件数
  cv_msg_code_90002          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90002';          -- エラー件数
  cv_msg_code_90004          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90004';          -- 正常終了
  cv_msg_code_90005          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90005';          -- 警告終了
  cv_msg_code_90006          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90006';          -- エラー終了全ロールバック
  -- トークン
  cv_token_base_code         CONSTANT VARCHAR2(20)  := 'SELLING_BASE_CODE';
  cv_token_profile           CONSTANT VARCHAR2(20)  := 'PROFILE';
  cv_token_sales_log         CONSTANT VARCHAR2(20)  := 'SALES_LOC';
  cv_token_org_code          CONSTANT VARCHAR2(20)  := 'ORG_CODE';
  cv_token_cust_code         CONSTANT VARCHAR2(20)  := 'CUST_CODE';
  cv_token_item_code         CONSTANT VARCHAR2(20)  := 'ITEM_CODE';
  cv_token_lookup_value_set  CONSTANT VARCHAR2(20)  := 'LOOKUP_VALUE_SET';
  cv_token_count             CONSTANT VARCHAR2(20)  := 'COUNT';
  cv_token_request_id        CONSTANT VARCHAR2(20)  := 'REQUEST_ID';
  -- 参照タイプ
-- Start 2009/03/03 M.Hiruta
--  cv_token_yoki_kubun        CONSTANT VARCHAR2(20)  := 'XXCMM_YOKI_KUBUN';          -- 容器区分
  cv_token_yoki_kubun        CONSTANT VARCHAR2(25)  := 'XXCSO1_SP_RULE_BOTTLE';     -- 容器区分
-- End   2009/03/03 M.Hiruta
  -- プロファイル
-- 2009/04/14 Ver.1.3 [障害T1_0510] SCS K.Yamaguchi ADD START
  cv_prof_org_id             CONSTANT VARCHAR2(25)  := 'ORG_ID';    -- MO：営業単位ID
-- 2009/04/14 Ver.1.3 [障害T1_0510] SCS K.Yamaguchi ADD END
  cv_prof_org_code_sales     CONSTANT VARCHAR2(25)  := 'XXCOK1_ORG_CODE_SALES';     -- 在庫組織コード_営業組織
  -- 顧客タイプ
  cv_cust_base_type          CONSTANT VARCHAR2(30)  := '1';                  -- 顧客区分「拠点」：'1'
  cv_cust_customer_type      CONSTANT VARCHAR2(30)  := '10';                 -- 顧客区分「顧客」：'10'
  -- セパレータ
  cv_msg_part                CONSTANT VARCHAR2(3)   := ' : ';
  cv_msg_cont                CONSTANT VARCHAR2(3)   := '.';
  -- 出力区分
  cv_which                   CONSTANT VARCHAR2(3)   := 'LOG';                -- 出力区分：'LOG'
  -- 数値(改行の指定、件数チェック時に使用)
  cn_number_0                CONSTANT NUMBER        := 0;
  cn_number_1                CONSTANT NUMBER        := 1;
  -- SVF起動パラメータ
  cv_file_id                 CONSTANT VARCHAR2(20)  := 'XXCOK014A06R';       -- 帳票ID
  cv_output_mode             CONSTANT VARCHAR2(1)   := '1';                  -- 出力区分(PDF出力)
  cv_frm_file                CONSTANT VARCHAR2(20)  := 'XXCOK014A06S.xml';   -- フォーム様式ファイル名
  cv_vrq_file                CONSTANT VARCHAR2(20)  := 'XXCOK014A06S.vrq';   -- クエリー様式ファイル名
  -- SVF出力ファイル名作成用
  cv_format_yyyymmdd         CONSTANT VARCHAR2(20)  := 'YYYYMMDD';           -- 文字列変換用日付書式フォーマット
  cv_extension               CONSTANT VARCHAR2(5)   := '.pdf';               -- 出力ファイル用拡張子(PDF形式)
  -- ===============================================
  -- グローバル変数
  -- ===============================================
  -- カウンタ
  gn_target_cnt             NUMBER         DEFAULT 0;     -- 対象件数
  gn_normal_cnt             NUMBER         DEFAULT 0;     -- 正常件数
  gn_error_cnt              NUMBER         DEFAULT 0;     -- エラー件数
  -- メッセージ
  gv_no_data_msg_table      VARCHAR2(30)                         DEFAULT NULL;  -- 0件メッセージ(テーブル格納用)
  gv_no_data_msg_output     VARCHAR2(5000)                       DEFAULT NULL;  -- 0件メッセージ(SVF出力用)
  -- 取得データ格納
-- 2009/04/14 Ver.1.3 [障害T1_0510] SCS K.Yamaguchi ADD START
  gn_operating_unit         NUMBER                               DEFAULT NULL;  -- プロファイル(MO：営業単位ID)
-- 2009/04/14 Ver.1.3 [障害T1_0510] SCS K.Yamaguchi ADD END
  gv_org_code               VARCHAR2(50)                         DEFAULT NULL;  -- プロファイル値(在庫組織コード)
  gn_org_id                 NUMBER                               DEFAULT NULL;  -- 在庫組織ID
  gt_selling_base_code      hz_cust_accounts.account_number%TYPE DEFAULT NULL;  -- 売上計上拠点コード(入力パラメータ)
  gt_selling_base_name      hz_cust_accounts.account_name%TYPE   DEFAULT NULL;  -- 売上計上拠点名
  gt_section_code           hz_locations.address3%TYPE           DEFAULT NULL;  -- 地区コード（売上計上拠点）
  gt_customer_code          hz_cust_accounts.account_number%TYPE DEFAULT NULL;  -- 顧客コード
  gt_customer_name          hz_cust_accounts.account_name%TYPE   DEFAULT NULL;  -- 顧客名
  -- 退避データ格納
  gt_base_code              xxcok_bm_contract_err.base_code%TYPE DEFAULT NULL;  -- 拠点コード(入力パラメータ)
  gt_selling_base_code_bkup hz_cust_accounts.account_number%TYPE DEFAULT NULL;  -- 売上計上拠点コード
  gt_cust_code_bkup         hz_locations.address3%TYPE           DEFAULT NULL;  -- 地区コード
-- 2009/09/01 Ver.1.4 [障害0001230] SCS S.Moriyama ADD START
  gd_process_date           DATE                                 DEFAULT NULL;  -- 業務処理日付
-- 2009/09/01 Ver.1.4 [障害0001230] SCS S.Moriyama ADD END
  -- ファイル名称
  gv_file_name              VARCHAR2(100)                        DEFAULT NULL;  -- SVF出力ファイル名
  -- ===============================================
  -- グローバルカーソル
  -- ===============================================
  -- エラーデータ取得カーソル
  CURSOR g_get_err_cur(
    iv_bace_code IN  VARCHAR2 DEFAULT NULL                        -- 拠点コード(入力パラメータ)
  )
  IS
-- 2011/02/02 Ver.1.5 [障害E_本稼動_05408] SCS S.Ochiai UPD START
--    SELECT xbce.base_code            AS base_code                 -- 拠点コード
    SELECT /*+
               PUSH_PRED(ITEM)
               LEADING  (XBCE XCA)
               USE_NL   (XBCE XCA)
               INDEX    (XBCE XXCOK_BM_CONTRACT_ERR_N02)
               INDEX    (XCA  XXCMM_CUST_ACCOUNTS_N06)
           */
           xbce.base_code            AS base_code                 -- 拠点コード
-- 2011/02/02 Ver.1.5 [障害E_本稼動_05408] SCS S.Ochiai UPD END
         , xbce.cust_code            AS cust_code                 -- 顧客コード
         , xbce.item_code            AS item_code                 -- 品目コード
         , xbce.container_type_code  AS container_type_code       -- 容器コード
         , xbce.selling_price        AS selling_price             -- 売価
         , xbce.selling_amt_tax      AS selling_amt_tax           -- 売上金額(税込)
         , xbce.closing_date         AS closing_date              -- 締め日
         , item.item_short_name      AS item_short_name           -- 品目・略名
         , cont.container_name       AS container_name            -- 容器名
    FROM   xxcok_bm_contract_err     xbce                         -- 販手条件エラーテーブル
-- 2011/02/02 Ver.1.5 [障害E_本稼動_05408] SCS S.Ochiai ADD START
         , xxcmm_cust_accounts       xca                          -- 顧客追加情報
-- 2011/02/02 Ver.1.5 [障害E_本稼動_05408] SCS S.Ochiai ADD END
         , ( SELECT msib.segment1         AS item_code            -- 品目コード
                  , ximb.item_short_name  AS item_short_name      -- 品目・略名
             FROM   mtl_system_items_b    msib                    -- 品目マスタ
                  , ic_item_mst_b         iimb                    -- OPM品目マスタ
                  , xxcmn_item_mst_b      ximb                    -- OPM品目アドオンマスタ
             WHERE  msib.organization_id  = gn_org_id
             AND    msib.segment1         = iimb.item_no
             AND    iimb.item_id          = ximb.item_id
-- 2009/09/01 Ver.1.4 [障害0001230] SCS S.Moriyama ADD START
             AND    gd_process_date BETWEEN ximb.start_date_active
                                    AND NVL ( ximb.end_date_active , gd_process_date )
-- 2009/09/01 Ver.1.4 [障害0001230] SCS S.Moriyama ADD END
           ) item
-- Start 2009/03/03 M.Hiruta
--         , ( SELECT xlvv.lookup_code      AS container_type_code  -- 容器コード
         , ( SELECT xlvv.attribute1       AS container_type_code  -- 容器コード
-- End   2009/03/03 M.Hiruta
                  , xlvv.meaning          AS container_name       -- 容器名
             FROM   xxcmn_lookup_values_v xlvv                    -- クイックコード
             WHERE  xlvv.lookup_type      = cv_token_yoki_kubun
           ) cont
-- 2011/02/02 Ver.1.5 [障害E_本稼動_05408] SCS S.Ochiai UPD START
--    WHERE  xbce.base_code            = NVL( iv_bace_code , xbce.base_code )
    WHERE  xbce.cust_code            = xca.customer_code
    AND    xca.past_sale_base_code   = NVL( iv_bace_code ,xca.past_sale_base_code)
-- 2011/02/02 Ver.1.5 [障害E_本稼動_05408] SCS S.Ochiai UPD END
    AND    xbce.item_code            = item.item_code(+)
    AND    xbce.container_type_code  = cont.container_type_code(+)
    ORDER BY
      xbce.base_code
    , xbce.cust_code
    , xbce.item_code
    , xbce.container_type_code;
  -- ===============================================
  -- グローバルテーブルタイプ
  -- ===============================================
  TYPE g_err_ttype IS TABLE OF g_get_err_cur%ROWTYPE
  INDEX BY BINARY_INTEGER;
  -- ===============================================
  -- グローバルテーブル型変数
  -- ===============================================
  g_err_tab                 g_err_ttype;
  -- ===============================================
  -- グローバル例外
  -- ===============================================
  global_api_expt           EXCEPTION;  -- 共通関数例外
  global_api_others_expt    EXCEPTION;  -- 共通関数OTHERS例外
  global_lock_fail_expt     EXCEPTION;  -- ロック取得エラー
--
  PRAGMA EXCEPTION_INIT( global_api_others_expt , -20000 );
  PRAGMA EXCEPTION_INIT(global_lock_fail_expt, -54);
--
  /************************************************************************
   * Procedure Name  : delete_err_data
   * Description     : ワークテーブルデータ削除(A-6)
   ************************************************************************/
  PROCEDURE delete_err_data(
    ov_errbuf        OUT VARCHAR2  -- エラー・メッセージ
  , ov_retcode       OUT VARCHAR2  -- リターン・コード
  , ov_errmsg        OUT VARCHAR2  -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name  CONSTANT VARCHAR2(30)  := 'delete_err_data';       -- プロシージャ名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf              VARCHAR2(5000) DEFAULT NULL;             -- エラー・メッセージ
    lv_retcode             VARCHAR2(1)    DEFAULT cv_status_normal; -- リターン・コード
    lv_errmsg              VARCHAR2(5000) DEFAULT NULL;             -- ユーザ・エラー･メッセージ
    lv_message             VARCHAR2(5000) DEFAULT NULL;             -- 作成メッセージ格納
    lb_retcode             BOOLEAN        DEFAULT NULL;             -- メッセージ出力時リターンコード
    -- ===============================================
    -- ローカルカーソル
    -- ===============================================
    CURSOR lock_chk_cur
    IS
      SELECT 'X'
      FROM   xxcok_rep_bm_contract_err  xrbce       -- 販手条件エラーリスト帳票ワークテーブル
      WHERE  xrbce.request_id = cn_request_id
      FOR UPDATE OF xrbce.request_id NOWAIT;
--
  BEGIN
    lv_retcode := cv_status_normal;
    -- ===============================================
    -- 販手条件エラーリスト帳票ワークテーブルロック取得
    -- ===============================================
    OPEN  lock_chk_cur;
    CLOSE lock_chk_cur;
    -- ===============================================
    -- ワークテーブルデータ削除
    -- ===============================================
    BEGIN
      DELETE FROM xxcok_rep_bm_contract_err         -- 販手条件エラーリスト帳票ワークテーブル
      WHERE       request_id = cn_request_id;
    EXCEPTION
      WHEN OTHERS THEN
      lv_message  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcok_appl_short_name
                     , iv_name         => cv_msg_code_10397
                     , iv_token_name1  => cv_token_request_id
                     , iv_token_value1 => cn_request_id
                     );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG      -- 出力区分
                    , iv_message  => lv_errmsg         -- メッセージ
                    , in_new_line => cn_number_0       -- 改行
                    );
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
      ov_errmsg  := NULL;
    END;
    -- ===============================================
    -- 成功件数取得
    -- ===============================================
    gn_normal_cnt := SQL%ROWCOUNT;
    -- エラーリストテーブルの取得データが0件の場合は、成功件数にも0を代入。
    IF ( gn_target_cnt = cn_number_0 ) THEN
      gn_normal_cnt := cn_number_0;
    END IF;
--
  EXCEPTION
    -- *** ロック取得エラー ***
    WHEN global_lock_fail_expt THEN
      lv_message  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcok_appl_short_name
                     , iv_name         => cv_msg_code_10321
                     , iv_token_name1  => cv_token_request_id
                     , iv_token_value1 => cn_request_id
                     );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG      -- 出力区分
                    , iv_message  => lv_errmsg         -- メッセージ
                    , in_new_line => cn_number_0       -- 改行
                    );
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_message , 1 , 5000 );
      ov_errmsg  := NULL;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
      ov_errmsg  := NULL;
  END delete_err_data;
--
  /************************************************************************
   * Procedure Name  : start_svf
   * Description     : SVF起動処理(A-5)
   ************************************************************************/
  PROCEDURE start_svf(
    ov_errbuf        OUT VARCHAR2  -- エラー・メッセージ
  , ov_retcode       OUT VARCHAR2  -- リターン・コード
  , ov_errmsg        OUT VARCHAR2  -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name   CONSTANT VARCHAR2(30)  := 'start_svf';            -- プロシージャ名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf              VARCHAR2(5000) DEFAULT NULL;             -- エラー・メッセージ
    lv_retcode             VARCHAR2(1)    DEFAULT cv_status_normal; -- リターン・コード
    lv_errmsg              VARCHAR2(5000) DEFAULT NULL;             -- ユーザ・エラー･メッセージ
    lv_message             VARCHAR2(5000) DEFAULT NULL;             -- 作成メッセージ格納
    lb_retcode             BOOLEAN        DEFAULT NULL;             -- メッセージ出力時リターンコード
    lv_sysdate             VARCHAR2(10)   DEFAULT NULL;             -- システム日付の文字型格納
    -- ===============================================
    -- ローカル例外
    -- ===============================================
    call_svf_err_expt      EXCEPTION;                  -- SVF実行エラー
-- 
  BEGIN
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- 出力ファイル名に使用する日付を文字列に変換
    -- ===============================================
    lv_sysdate := TO_CHAR( SYSDATE, cv_format_yyyymmdd );
    -- ===============================================
    -- 出力ファイル名(帳票ID + YYYYMMDD + 要求ID)
    -- ===============================================
    gv_file_name := cv_file_id || lv_sysdate || TO_CHAR( cn_request_id ) || cv_extension;
    -- ===============================================
    -- SVFコンカレント起動
    -- ===============================================
    xxccp_svfcommon_pkg.submit_svf_request(
        ov_errbuf        => lv_errbuf                 -- エラーバッファ
      , ov_retcode       => lv_retcode                -- リターンコード
      , ov_errmsg        => lv_errmsg                 -- エラーメッセージ
      , iv_conc_name     => cv_pkg_name               -- コンカレント名
      , iv_file_name     => gv_file_name              -- 出力ファイル名
      , iv_file_id       => cv_file_id                -- 帳票ID
      , iv_output_mode   => cv_output_mode            -- 出力区分
      , iv_frm_file      => cv_frm_file               -- フォーム様式ファイル名
      , iv_vrq_file      => cv_vrq_file               -- クエリー様式ファイル名
      , iv_org_id        => TO_CHAR( gn_org_id )      -- ORG_ID
      , iv_user_name     => fnd_global.user_name      -- ログイン・ユーザ名
      , iv_resp_name     => fnd_global.resp_name      -- ログイン・ユーザ職責名
      , iv_doc_name      => NULL                      -- 文書名
      , iv_printer_name  => NULL                      -- プリンタ名
      , iv_request_id    => TO_CHAR( cn_request_id )  -- 要求ID
      , iv_nodata_msg    => gv_no_data_msg_output     -- データなしメッセージ
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      lv_message := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00040
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG     --出力区分
                    , iv_message  => lv_message       --メッセージ
                    , in_new_line => cn_number_0      --改行
              );
      RAISE call_svf_err_expt;
    END IF;
--
  EXCEPTION
    -- *** SVF実行エラー ***
    WHEN call_svf_err_expt THEN
      ov_retcode := lv_retcode;
      ov_errbuf  := lv_errbuf;
      ov_errmsg  := lv_errmsg;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
      ov_errmsg  := NULL;
  END start_svf;
--
  /************************************************************************
   * Procedure Name  : insert_err_data
   * Description     : ワークテーブル登録処理(A-4)
   ************************************************************************/
  PROCEDURE insert_err_data(
    ov_errbuf    OUT VARCHAR2               -- エラー・メッセージ
  , ov_retcode   OUT VARCHAR2               -- リターン・コード
  , ov_errmsg    OUT VARCHAR2               -- ユーザ・エラー・メッセージ
  , in_cnt       IN  NUMBER                 -- LOOPカウンタ
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name   CONSTANT VARCHAR2(30)   := 'insert_err_data';     -- プロシージャ名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf              VARCHAR2(5000) DEFAULT NULL;             -- エラー・メッセージ
    lv_retcode             VARCHAR2(1)    DEFAULT cv_status_normal; -- リターン・コード
    lv_errmsg              VARCHAR2(5000) DEFAULT NULL;             -- ユーザ・エラー･メッセージ
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- エラーデータの挿入
    -- ===============================================
    -- 0件以外の場合
    IF ( gn_target_cnt != cn_number_0 ) THEN
      INSERT INTO xxcok_rep_bm_contract_err(   -- 販手条件エラーリスト帳票ワークテーブル
        p_selling_base_code                    -- 売上計上拠点コード(入力パラメータ)
      , selling_base_code                      -- 売上計上拠点コード
      , selling_base_name                      -- 売上計上拠点名
      , cost_code                              -- 顧客コード
      , cost_name                              -- 顧客名
      , item_code                              -- 品目コード
      , item_name                              -- 品目名
      , container_type                         -- 容器区分
      , selling_price                          -- 売価
      , selling_amt_tax                        -- 売上金額(税込)
      , closing_date                           -- 締め日
      , selling_base_section_code              -- 地区コード（売上計上拠点）
      , no_data_message                        -- 0件メッセージ
      , created_by                             -- 作成者
      , creation_date                          -- 作成日
      , last_updated_by                        -- 最終更新者
      , last_update_date                       -- 最終更新日
      , last_update_login                      -- 最終更新ログイン
      , request_id                             -- 要求ID
      , program_application_id                 -- コンカレント・プログラム・アプリケーションID
      , program_id                             -- コンカレント・プログラムID
      , program_update_date                    -- プログラム更新日
      )
      VALUES(
        gt_base_code                           -- 売上計上拠点コード(入力パラメータ)
      , gt_selling_base_code                   -- 売上計上拠点コード
      , gt_selling_base_name                   -- 売上計上拠点名
      , gt_customer_code                       -- 顧客コード
      , gt_customer_name                       -- 顧客名
      , g_err_tab( in_cnt ).item_code          -- 品目コード
      , g_err_tab( in_cnt ).item_short_name    -- 品目名
      , g_err_tab( in_cnt ).container_name     -- 容器区分
      , g_err_tab( in_cnt ).selling_price      -- 売価
      , g_err_tab( in_cnt ).selling_amt_tax    -- 売上金額(税込)
      , g_err_tab( in_cnt ).closing_date       -- 締め日
      , gt_section_code                        -- 地区コード（売上計上拠点）
      , gv_no_data_msg_table                   -- 0件メッセージ
      , cn_created_by                          -- 作成者
      , SYSDATE                                -- 作成日
      , cn_last_updated_by                     -- 最終更新者
      , SYSDATE                                -- 最終更新日
      , cn_last_update_login                   -- 最終ログイン
      , cn_request_id                          -- 要求ID
      , cn_program_application_id              -- コンカレント・プログラム・アプリケーションID
      , cn_program_id                          -- コンカレント・プログラムID
      , SYSDATE                                -- プログラム更新日
      );
      -- ===============================================
      -- 取得データの退避
      -- ===============================================
      gt_selling_base_code_bkup := gt_selling_base_code;  -- 売上計上拠点情報
      gt_cust_code_bkup         := gt_customer_code;      -- 顧客情報
    -- 0件の場合
    ELSE
      INSERT INTO xxcok_rep_bm_contract_err(   -- 販手条件エラーリスト帳票ワークテーブル
        p_selling_base_code                    -- 売上計上拠点コード(入力パラメータ)
      , selling_base_code                      -- 売上計上拠点コード
      , selling_base_name                      -- 売上計上拠点名
      , cost_code                              -- 顧客コード
      , cost_name                              -- 顧客名
      , item_code                              -- 品目コード
      , item_name                              -- 品目名
      , container_type                         -- 容器区分
      , selling_price                          -- 売価
      , selling_amt_tax                        -- 売上金額(税込)
      , closing_date                           -- 締め日
      , selling_base_section_code              -- 地区コード（売上計上拠点）
      , no_data_message                        -- 0件メッセージ
      , created_by                             -- 作成者
      , creation_date                          -- 作成日
      , last_updated_by                        -- 最終更新者
      , last_update_date                       -- 最終更新日
      , last_update_login                      -- 最終更新ログイン
      , request_id                             -- 要求ID
      , program_application_id                 -- コンカレント・プログラム・アプリケーションID
      , program_id                             -- コンカレント・プログラムID
      , program_update_date                    -- プログラム更新日
      )
      VALUES(
        gt_base_code                           -- 売上計上拠点コード(入力パラメータ)
      , NULL                                   -- 売上計上拠点コード
      , NULL                                   -- 売上計上拠点名
      , NULL                                   -- 顧客コード
      , NULL                                   -- 顧客名
      , NULL                                   -- 品目コード
      , NULL                                   -- 品目名
      , NULL                                   -- 容器区分
      , NULL                                   -- 売価
      , NULL                                   -- 売上金額(税込)
      , NULL                                   -- 締め日
      , NULL                                   -- 地区コード（売上計上拠点）
      , gv_no_data_msg_table                   -- 0件メッセージ
      , cn_created_by                          -- 作成者
      , SYSDATE                                -- 作成日
      , cn_last_updated_by                     -- 最終更新者
      , SYSDATE                                -- 最終更新日
      , cn_last_update_login                   -- 最終ログイン
      , cn_request_id                          -- 要求ID
      , cn_program_application_id              -- コンカレント・プログラム・アプリケーションID
      , cn_program_id                          -- コンカレント・プログラムID
      , SYSDATE                                -- プログラム更新日
      );
    END IF;
  EXCEPTION
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
  END insert_err_data;
--
  /************************************************************************
   * Procedure Name  : get_mst_info
   * Description     : 売上拠点・顧客情報抽出処理(A-3)
   ************************************************************************/
  PROCEDURE get_mst_info(
    ov_errbuf     OUT VARCHAR2               -- エラー・メッセージ
  , ov_retcode    OUT VARCHAR2               -- リターン・コード
  , ov_errmsg     OUT VARCHAR2               -- ユーザ・エラー・メッセージ
  , iv_base_code  IN  VARCHAR2               -- 拠点コード(SQL条件)
  , iv_cust_code  IN  VARCHAR2               -- 顧客コード(SQL条件)
  , in_cnt        IN  NUMBER                 -- LOOPカウンタ
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name   CONSTANT VARCHAR2(30)  := 'get_mst_info';         -- プロシージャ名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf              VARCHAR2(5000) DEFAULT NULL;             -- エラー・メッセージ
    lv_retcode             VARCHAR2(1)    DEFAULT cv_status_normal; -- リターン・コード
    lv_errmsg              VARCHAR2(5000) DEFAULT NULL;             -- ユーザ・エラー･メッセージ
    lv_message             VARCHAR2(5000) DEFAULT NULL;             -- 作成メッセージ格納
    lb_retcode             BOOLEAN        DEFAULT NULL;             -- メッセージ出力時リターンコード
    -- ===============================================
    -- ローカル例外
    -- ===============================================
    get_data_err_expt      EXCEPTION;         -- データ取得エラー
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- 売上拠点情報取得
    -- ===============================================
    -- 初回、もしくは直前の拠点コードと値が異なる場合に取得する。
--    IF ( in_cnt = cn_number_0 )
    IF ( in_cnt = cn_number_1 )
      OR ( gt_selling_base_code_bkup != iv_base_code )
    THEN
--
      BEGIN
        SELECT hca.account_number   AS selling_base_code  -- 売上計上拠点コード(顧客コード)
             , hca.account_name     AS selling_base_name  -- 売上拠点名(アカウント名)
             , hl.address3          AS section_code       -- 地区コード(住所3)
        INTO   gt_selling_base_code
             , gt_selling_base_name
             , gt_section_code
        FROM   hz_cust_accounts        hca                -- 顧客マスタ
             , hz_locations            hl                 -- 顧客事業所マスタ
             , hz_parties              hp                 -- パーティマスタ
             , hz_party_sites          hps                -- パーティサイトマスタ
             , hz_cust_acct_sites_all  hcasa              -- 顧客所在地マスタ
        WHERE  hca.party_id            = hp.party_id
        AND    hca.cust_account_id     = hcasa.cust_account_id
        AND    hp.party_id             = hps.party_id
        AND    hps.location_id         = hl.location_id
-- 2009/04/14 Ver.1.3 [障害T1_0510] SCS K.Yamaguchi ADD START
        AND    hcasa.party_site_id     = hps.party_site_id
        AND    hcasa.org_id            = gn_operating_unit
-- 2009/04/14 Ver.1.3 [障害T1_0510] SCS K.Yamaguchi ADD END
        AND    hca.account_number      = iv_base_code
        AND    hca.customer_class_code = cv_cust_base_type;
--
      EXCEPTION
        -- *** 対象データ0件の場合 ***
        WHEN NO_DATA_FOUND THEN
          lv_message := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_00048
                        , iv_token_name1  => cv_token_sales_log
                        , iv_token_value1 => iv_base_code
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.LOG     --出力区分
                        , iv_message  => lv_message       --メッセージ
                        , in_new_line => cn_number_0      --改行
                        );
          RAISE get_data_err_expt;
        -- *** 複数行のデータが返された場合 ***
        WHEN TOO_MANY_ROWS THEN
          lv_message := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_00047
                        , iv_token_name1  => cv_token_sales_log
                        , iv_token_value1 => iv_base_code
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.LOG     --出力区分
                        , iv_message  => lv_message       --メッセージ
                        , in_new_line => cn_number_0      --改行
                        );
          RAISE get_data_err_expt;
      END;
    END IF;
    -- ===============================================
    -- 顧客情報の取得
    -- ===============================================
    -- 初回、もしくは直前の顧客コードと値が異なる場合に取得する。
--    IF ( in_cnt = cn_number_0 )
    IF ( in_cnt = cn_number_1 )
      OR ( gt_cust_code_bkup != iv_cust_code )
    THEN
--
      BEGIN
        SELECT hca.account_number      AS customer_code  -- 顧客コード
             , hp.party_name           AS customer_name  -- 顧客名
        INTO   gt_customer_code
             , gt_customer_name
        FROM   hz_cust_accounts        hca               -- 顧客マスタ
             , hz_parties              hp                -- パーティマスタ
        WHERE  hca.party_id            = hp.party_id
        AND    hca.account_number      = iv_cust_code
        AND    hca.customer_class_code = cv_cust_customer_type;
--
      EXCEPTION
        -- *** 対象データ0件の場合 ***
        WHEN NO_DATA_FOUND THEN
          lv_message := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_00035
                        , iv_token_name1  => cv_token_cust_code
                        , iv_token_value1 => iv_cust_code
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.LOG     --出力区分
                        , iv_message  => lv_message       --メッセージ
                        , in_new_line => cn_number_0      --改行
                        );
          RAISE get_data_err_expt;
        -- *** 複数行のデータが返された場合 ***
        WHEN TOO_MANY_ROWS THEN
          lv_message := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_00046
                        , iv_token_name1  => cv_token_cust_code
                        , iv_token_value1 => iv_cust_code
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.LOG     --出力区分
                        , iv_message  => lv_message       --メッセージ
                        , in_new_line => cn_number_0      --改行
                        );
          RAISE get_data_err_expt;
      END;
    END IF;
--
  EXCEPTION
    -- *** データ取得エラー ***
    WHEN get_data_err_expt THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_message , 1 , 5000 );
      ov_errmsg  := NULL;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
      ov_errmsg  := NULL;
  END get_mst_info;
--
  /************************************************************************
   * Procedure Name  : get_err_data
   * Description     : 販手条件エラー情報抽出処理(A-2)
   ************************************************************************/
  PROCEDURE get_err_data(
    ov_errbuf     OUT VARCHAR2       -- エラー・メッセージ
  , ov_retcode    OUT VARCHAR2       -- リターン・コード
  , ov_errmsg     OUT VARCHAR2       -- ユーザ・エラー・メッセージ
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name   CONSTANT VARCHAR2(30)  := 'get_err_date';                    -- プロシージャ名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf              VARCHAR2(5000) DEFAULT NULL;                        -- エラー・メッセージ
    lv_retcode             VARCHAR2(1)    DEFAULT cv_status_normal;            -- リターン・コード
    lv_errmsg              VARCHAR2(5000) DEFAULT NULL;                        -- ユーザ・エラー･メッセージ
    lv_message             VARCHAR2(5000) DEFAULT NULL;                        -- 作成メッセージ格納
    lb_retcode             BOOLEAN        DEFAULT NULL;                        -- メッセージ出力時リターンコード
    -- ===============================================
    -- ローカル例外
    -- ===============================================
    get_data_null_expt     EXCEPTION;                                          -- 品目・略名、容器名取得エラー
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- 販手条件エラー情報の取得
    -- ===============================================
    -- カーソルオープン
    OPEN g_get_err_cur(
           iv_bace_code => gt_base_code
         );
    FETCH g_get_err_cur BULK COLLECT INTO g_err_tab;
    -- カーソルクローズ
    CLOSE g_get_err_cur;
    -- 取得件数を退避
    gn_target_cnt := g_err_tab.COUNT;
    -- ===============================================
    -- データが取得された場合
    -- ===============================================
    IF ( gn_target_cnt != 0 ) THEN
      -- ループ開始
      <<main_loop>>
      FOR i IN g_err_tab.FIRST .. g_err_tab.LAST LOOP
        -- ===============================================
        -- 品目・略名が取得できなかった場合
        -- ===============================================
        IF ( g_err_tab( i ).item_short_name IS NULL ) THEN
          lv_message := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_00056
--                        , iv_token_name1  => cv_token_profile
--                        , iv_token_value1 => cv_prof_org_code_sales
                        , iv_token_name1  => cv_token_item_code
                        , iv_token_value1 => g_err_tab( i ).item_code
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.LOG     --出力区分
                        , iv_message  => lv_message       --メッセージ
                        , in_new_line => cn_number_0      --改行
                        );
          RAISE get_data_null_expt;
        END IF;
        -- ===============================================
        -- 容器が取得できなかった場合
        -- ===============================================
        IF ( g_err_tab( i ).container_name IS NULL ) THEN
          lv_message := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_00015
--                        , iv_token_name1  => cv_token_profile
--                        , iv_token_value1 => cv_prof_org_code_sales
                        , iv_token_name1  => cv_token_lookup_value_set
                        , iv_token_value1 => g_err_tab( i ).container_type_code
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.LOG     --出力区分
                        , iv_message  => lv_message       --メッセージ
                        , in_new_line => cn_number_0      --改行
                        );
          RAISE get_data_null_expt;
        END IF;
        -- ===============================================
        -- 売上拠点・顧客情報取得(A-3)
        -- ===============================================
        get_mst_info(
          ov_errbuf             => lv_errbuf                 -- エラー・メッセージ
        , ov_retcode            => lv_retcode                -- リターン・コード
        , ov_errmsg             => lv_errmsg                 -- ユーザ・エラー・メッセージ
        , iv_base_code          => g_err_tab( i ).base_code  -- 拠点コード(SQL条件)
        , iv_cust_code          => g_err_tab( i ).cust_code  -- 顧客コード(SQL条件)
        , in_cnt                => i                         -- LOOPカウンタ
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_api_expt;
        END IF;
        -- ===============================================
        -- ワークテーブルへの登録処理(A-4)
        -- ===============================================
        insert_err_data(
            ov_errbuf             => lv_errbuf              -- エラー・メッセージ
          , ov_retcode            => lv_retcode             -- リターン・コード
          , ov_errmsg             => lv_errmsg              -- ユーザ・エラー・メッセージ
          , in_cnt                => i                      -- LOOPカウンタ
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_api_expt;
        END IF;
      END LOOP main_loop;
    -- ===============================================
    -- データが0件の場合
    -- ===============================================
    ELSE
      -- ===============================================
      -- 対象データなしメッセージ取得
      -- ===============================================
      gv_no_data_msg_table := xxccp_common_pkg.get_msg(
                                iv_application  => cv_xxcok_appl_short_name
                              , iv_name         => cv_msg_code_00001
                        );
      -- ===============================================
      -- ワークテーブルへの登録処理(A-4)
      -- ===============================================
      insert_err_data(
        ov_errbuf             => lv_errbuf              -- エラー・メッセージ
      , ov_retcode            => lv_retcode             -- リターン・コード
      , ov_errmsg             => lv_errmsg              -- ユーザ・エラー・メッセージ
      , in_cnt                => cn_number_0            -- LOOPカウンタ(0固定)
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
  EXCEPTION
    -- *** 品目・略名、容器名取得エラー ***
    WHEN get_data_null_expt THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_message , 1 , 5000 );
    -- *** 共通関数例外 ***
    WHEN global_api_expt THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf , 1 , 5000 );
      ov_errmsg  := lv_errmsg;
    WHEN global_api_others_expt THEN
    -- *** 共通関数OTHERS例外 ***
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
--
  END get_err_data;
--
  /************************************************************************
   * Procedure Name  : init
   * Description     : 初期処理(A-1)
   ************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2     -- エラー・メッセージ
  , ov_retcode    OUT VARCHAR2     -- リターン・コード
  , ov_errmsg     OUT VARCHAR2     -- ユーザ・エラー・メッセージ
  , iv_base_code  IN  VARCHAR2     -- 拠点コード
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name   CONSTANT VARCHAR2(30)  := 'init';  -- プロシージャ名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf              VARCHAR2(5000) DEFAULT NULL;             -- エラー・メッセージ
    lv_retcode             VARCHAR2(1)    DEFAULT cv_status_normal; -- リターン・コード
    lv_errmsg              VARCHAR2(5000) DEFAULT NULL;             -- ユーザ・エラー･メッセージ
    lv_message             VARCHAR2(5000) DEFAULT NULL;             -- 作成メッセージ格納
    lb_retcode             BOOLEAN        DEFAULT NULL;             -- メッセージ出力時リターンコード
    -- ===============================================
    -- ローカル例外
    -- ===============================================
    get_data_err_expt      EXCEPTION;                -- データ取得エラー時例外
--
  BEGIN
    ov_retcode := cv_status_normal;
    --================================================
    -- 入力パラメータの退避
    --================================================
    gt_base_code := iv_base_code;
    --================================================
    -- 入力パラメータのログ出力
    --================================================
      lv_message  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00074
                    , iv_token_name1  => cv_token_base_code
                    , iv_token_value1 => gt_base_code
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG     --出力区分
                    , iv_message  => lv_message       --メッセージ
                    , in_new_line => cn_number_1      --改行
                    );
-- 2009/04/14 Ver.1.3 [障害T1_0510] SCS K.Yamaguchi ADD START
    --================================================
    -- プロファイル(営業単位ID)の取得
    --================================================
    gn_operating_unit := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_org_id ) );
    IF ( gn_operating_unit IS NULL ) THEN
      lv_message  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile
                    , iv_token_value1 => cv_prof_org_id
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG     --出力区分
                    , iv_message  => lv_message       --メッセージ
                    , in_new_line => cn_number_0      --改行
                    );
      RAISE get_data_err_expt;
    END IF;
-- 2009/04/14 Ver.1.3 [障害T1_0510] SCS K.Yamaguchi ADD END
    --================================================
    -- カスタム・プロファイル(在庫組織コード)の取得
    --================================================
    gv_org_code := FND_PROFILE.VALUE(
                     cv_prof_org_code_sales
                   );
    IF ( gv_org_code IS NULL ) THEN
      lv_message  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile
                    , iv_token_value1 => cv_prof_org_code_sales
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG     --出力区分
                    , iv_message  => lv_message       --メッセージ
                    , in_new_line => cn_number_0      --改行
                    );
      RAISE get_data_err_expt;
    END IF;
    --================================================
    -- 在庫組織IDの取得
    --================================================
    gn_org_id := xxcoi_common_pkg.get_organization_id(
                   iv_organization_code => gv_org_code
                 );
    -- 在庫組織IDの取得に失敗した場合
    IF ( gn_org_id IS NULL ) THEN
      lv_message := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00013
                    , iv_token_name1  => cv_token_org_code
                    , iv_token_value1 => gv_org_code
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG     --出力区分
                    , iv_message  => lv_message       --メッセージ
                    , in_new_line => cn_number_0      --改行
                    );
      RAISE get_data_err_expt;
    END IF;
-- 2009/09/01 Ver.1.4 [障害0001230] SCS S.Moriyama ADD START
    -- ===============================================
    -- 業務処理日付取得
    -- ===============================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00028
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
      RAISE get_data_err_expt;
    END IF;
-- 2009/09/01 Ver.1.4 [障害0001230] SCS S.Moriyama ADD END
--
  EXCEPTION
    -- *** データ取得エラー ***
    WHEN get_data_err_expt THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_message , 1 , 5000 );
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
  END init;
--
  /************************************************************************
   * Procedure Name  : submain
   * Description     : メイン処理プロシージャ
   ************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2     -- エラー・メッセージ
  , ov_retcode    OUT VARCHAR2     -- リターン・コード
  , ov_errmsg     OUT VARCHAR2     -- ユーザ・エラー・メッセージ
  , iv_base_code  IN  VARCHAR2     -- 拠点コード
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name   CONSTANT VARCHAR2(30)  := 'submain';  -- プロシージャ名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf              VARCHAR2(5000) DEFAULT NULL;             -- エラー・メッセージ
    lv_retcode             VARCHAR2(1)    DEFAULT cv_status_normal; -- リターン・コード
    lv_errmsg              VARCHAR2(5000) DEFAULT NULL;             -- ユーザ・エラー･メッセージ
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- 初期処理(A-1)
    -- ===============================================
    init(
      ov_errbuf     => lv_errbuf     -- エラー・メッセージ
    , ov_retcode    => lv_retcode    -- リターン・コード
    , ov_errmsg     => lv_errmsg     -- ユーザ・エラー・メッセージ
    , iv_base_code  => iv_base_code  -- 拠点コード
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    -- ===============================================
    -- 販手条件エラー情報抽出処理(A-2)・売上拠点・顧客情報抽出処理(A-3)・ワークテーブル登録処理(A-4)
    -- ===============================================
    get_err_data(
      ov_errbuf     => lv_errbuf     -- エラー・メッセージ
    , ov_retcode    => lv_retcode    -- リターン・コード
    , ov_errmsg     => lv_errmsg     -- ユーザ・エラー・メッセージ
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    -- ===============================================
    -- ワークテーブルデータ確定
    -- ===============================================
    COMMIT;
    -- ===============================================
    -- SVF起動処理(A-5)
    -- ===============================================
    start_svf(
      ov_errbuf     => lv_errbuf     -- エラー・メッセージ
    , ov_retcode    => lv_retcode    -- リターン・コード
    , ov_errmsg     => lv_errmsg     -- ユーザ・エラー・メッセージ
    );
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
    -- ===============================================
    -- ワークテーブルデータ削除(A-6)
    -- ===============================================
    delete_err_data(
      ov_errbuf     => lv_errbuf     -- エラー・メッセージ
    , ov_retcode    => lv_retcode    -- リターン・コード
    , ov_errmsg     => lv_errmsg     -- ユーザ・エラー・メッセージ
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
    -- *** 共通関数例外 ***
    WHEN global_api_expt THEN
      ov_retcode := lv_retcode;
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf , 1 , 5000 );
      ov_errmsg  := lv_errmsg;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
--
  END submain;
--
  /************************************************************************
   * Procedure Name  : main
   * Description     : コンカレント実行ファイル登録プロシージャ
   ************************************************************************/
  PROCEDURE main(
    errbuf        OUT VARCHAR2     -- エラー・メッセージ
  , retcode       OUT VARCHAR2     -- リターン・コード
  , iv_base_code  IN  VARCHAR2     -- 拠点コード
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name   CONSTANT VARCHAR2(30)  := 'main';  -- プロシージャ名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf              VARCHAR2(5000) DEFAULT NULL;             -- エラー・メッセージ
    lv_retcode             VARCHAR2(1)    DEFAULT cv_status_normal; -- リターン・コード
    lv_errmsg              VARCHAR2(5000) DEFAULT NULL;             -- ユーザ・エラー･メッセージ
    lv_message             VARCHAR2(5000) DEFAULT NULL;             -- 作成メッセージ格納
    lb_retcode             BOOLEAN        DEFAULT NULL;             -- メッセージ出力時リターンコード
    lv_message_code        VARCHAR2(50)   DEFAULT NULL;             -- 終了メッセージコード格納
--
  BEGIN
    -- ===============================================
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    -- ===============================================
    xxccp_common_pkg.put_log_header(
      ov_errbuf     => lv_errbuf     -- エラー・メッセージ
    , ov_retcode    => lv_retcode    -- リターン・コード
    , ov_errmsg     => lv_errmsg     -- ユーザ・エラー・メッセージ
    , iv_which      => cv_which      -- 出力区分
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    -- ===============================================
    -- submain(実処理)呼び出し
    -- ===============================================
    submain(
      ov_errbuf     => lv_errbuf     -- エラー・メッセージ
    , ov_retcode    => lv_retcode    -- リターン・コード
    , ov_errmsg     => lv_errmsg     -- ユーザ・エラー・メッセージ
    , iv_base_code  => iv_base_code  -- 拠点コード
    );
    -- ===============================================
    -- エラー終了時、lv_errmsgとlv_errbufをログに出力する
    -- ===============================================
    IF ( lv_retcode = cv_status_error ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG   -- 出力区分
                    , iv_message  => lv_errmsg      -- メッセージ
                    , in_new_line => cn_number_0    -- 改行
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG   -- 出力区分
                    , iv_message  => lv_errbuf      -- メッセージ
                    , in_new_line => cn_number_1    -- 改行
                    );
    END IF;
    -- ===============================================
    -- 対象件数出力
    -- ===============================================
    lv_message := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_appl_short_name  -- 'XXCCP'
                  , iv_name         => cv_msg_code_90000         -- 対象件数出力メッセージ
                  , iv_token_name1  => cv_token_count            -- トークン1('COUNT')
                  , iv_token_value1 => TO_CHAR( gn_target_cnt )  -- 対象総件数
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG                  --出力区分
                  , iv_message  => lv_message                    --メッセージ
                  , in_new_line => cn_number_0                   --改行
                  );
    -- ===============================================
    -- 成功件数出力(エラー発生時、成功件数:0件 エラー件数:1件)
    -- ===============================================
    IF ( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := cn_number_0;
      gn_error_cnt  := cn_number_1;
--    ELSE
--      gn_normal_cnt := gn_target_cnt;
    END IF;
    lv_message := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_appl_short_name  -- 'XXCCP'
                  , iv_name         => cv_msg_code_90001         -- 成功件数出力メッセージ
                  , iv_token_name1  => cv_token_count            -- トークン1('COUNT')
                  , iv_token_value1 => TO_CHAR( gn_normal_cnt )  -- 対象総件数
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG                  --出力区分
                  , iv_message  => lv_message                    --メッセージ
                  , in_new_line => cn_number_0                   --改行
                  );
    -- ===============================================
    -- エラー件数出力
    -- ===============================================
    lv_message := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_appl_short_name  -- 'XXCCP'
                  , iv_name         => cv_msg_code_90002         -- エラー件数出力メッセージ
                  , iv_token_name1  => cv_token_count            -- トークン1('COUNT')
                  , iv_token_value1 => TO_CHAR( gn_error_cnt )   -- 対象総件数
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG                  --出力区分
                  , iv_message  => lv_message                    --メッセージ
                  , in_new_line => cn_number_1                   --改行
                  );
    -- ===============================================
    -- 処理終了メッセージ出力
    -- ===============================================
    -- 正常終了
    IF ( lv_retcode    = cv_status_normal ) THEN
      lv_message_code := cv_msg_code_90004;
    -- 警告終了
    ELSIF ( lv_retcode = cv_status_warn )   THEN
      lv_message_code := cv_msg_code_90005;
    -- エラー終了
    ELSIF ( lv_retcode = cv_status_error )  THEN
      lv_message_code := cv_msg_code_90006;
    END IF;
    lv_message := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_appl_short_name  -- XXCCP'
                  , iv_name         => lv_message_code           -- 終了メッセージ
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG     --出力区分
                  , iv_message  => lv_message       --メッセージ
                  , in_new_line => cn_number_0      --改行
                  );
    -- ===============================================
    -- ステータスセット
    -- ===============================================
    retcode := lv_retcode;
    -- ===============================================
    -- 終了ステータスエラー時、ロールバック
    -- ===============================================
    IF ( retcode = cv_status_error ) THEN
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
      errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
END XXCOK014A06R;
/
