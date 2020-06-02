CREATE OR REPLACE PACKAGE BODY XXCOK008A05R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK008A05R(body)
 * Description      : 要求の発行画面から、売上振替割合チェックリストを帳票に出力します。
 * MD.050           : 売上振替割合チェックリスト MD050_COK_008_A05
 * Version          : 1.4
 *
 * Program List
 * --------------------------- ------------------------------------------------------------
 *  Name                         Description
 * --------------------------- ------------------------------------------------------------
 *  init                         初期処理(A-1)
 *  get_target_data              データ取得(A-2)
 *  ins_rep_selling_trns_chk     ワークテーブルデータ登録(A-3)
 *  start_svf                    SVF起動(A-4)
 *  del_rep_selling_trns_chk     ワークテーブルデータ削除(A-5)
 *  submain                      メイン処理プロシージャ
 *  main                         コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- --------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/10/23    1.0   T.Abe            新規作成
 *  2009/02/02    1.1   T.Abe            [障害COK_003] 取得条件に営業単位IDを追加
 *  2009/03/25    1.2   S.Kayahara       最終行にスラッシュ追加
 *  2009/08/26    1.3   M.Hiruta         [障害0001154] 従業員マスタの有効日をデータ抽出条件に追加
 *  2020/05/26    1.4   S.Kuwako         E_本稼動_16378対応
 *
 *****************************************************************************************/
--
  --==========================
  -- グローバル定数
  --==========================
  -- ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn            CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error           CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_error;  -- 異常:2
  -- WHOカラム
  cn_created_by             CONSTANT NUMBER        := fnd_global.user_id;                 -- CREATED_BY
  cn_last_updated_by        CONSTANT NUMBER        := fnd_global.user_id;                 -- LAST_UPDATED_BY
  cn_last_update_login      CONSTANT NUMBER        := fnd_global.login_id;                -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER        := fnd_global.conc_request_id;         -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER        := fnd_global.prog_appl_id;            -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER        := fnd_global.conc_program_id;         -- PROGRAM_ID
  -- セパレータ
  cv_msg_part               CONSTANT VARCHAR2(3)   := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3)   := '.';
  -- パッケージ名
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOK008A05R';
  -- アプリケーション短縮名
  cv_xxcok_appl             CONSTANT VARCHAR2(10)  := 'XXCOK';
  cv_xxccp_appl             CONSTANT VARCHAR2(10)  := 'XXCCP';
  -- プロファイル
-- Start 2009/08/26 Ver.1.3 0001154 M.Hiruta DELETE
--  cv_prof_org_code_sales    CONSTANT VARCHAR2(25)  := 'XXCOK1_ORG_CODE_SALES';    -- 在庫組織コード_営業組織
-- End   2009/08/26 Ver.1.3 0001154 M.Hiruta DELETE
  cv_prof_org_id            CONSTANT VARCHAR2(25)  := 'ORG_ID';                   -- 営業単位ID
  -- メッセージ
-- Start 2009/08/26 Ver.1.3 0001154 M.Hiruta DELETE
--  cv_msg_xxcok_00013        CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00013';         -- 在庫組織ID取得エラー
-- End   2009/08/26 Ver.1.3 0001154 M.Hiruta DELETE
  cv_msg_xxcok_00028        CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00028';         -- 業務処理日付取得エラー
  cv_msg_xxcok_00001        CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00001';         -- 対象データなしメッセージ
  cv_msg_xxcok_00040        CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00040';         -- SVF起動APIエラー'
  cv_msg_xxcok_00003        CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00003';         -- プロファイル取得エラー
  cv_msg_xxcok_10412        CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10412';         -- ロック取得エラー
  cv_msg_xxcok_10413        CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10413';         -- データ削除エラーメッセージ
  cv_msg_xxcok_00082        CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00082';         -- 売上振替元拠点コード
  cv_msg_xxcok_00083        CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00083';         -- 売上振替元顧客コード
  cv_msg_xxcok_00084        CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00084';         -- 売上振替先拠点コード
  cv_msg_xxccp_90000        CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90000';         -- 対象件数
  cv_msg_xxccp_90001        CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90001';         -- 成功件数
  cv_msg_xxccp_90002        CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90002';         -- エラー件数
  cv_msg_xxccp_90004        CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90004';         -- 正常終了
  cv_msg_xxccp_90006        CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90006';         -- エラー終了全ロールバック
  -- トークン
  cv_token_request_id       CONSTANT VARCHAR2(50)  := 'REQUEST_ID';               -- 要求ID
  cv_token_profile          CONSTANT VARCHAR2(50)  := 'PROFILE';                  -- プロファイル
-- Start 2009/08/26 Ver.1.3 0001154 M.Hiruta DELETE
--  cv_token_org_code         CONSTANT VARCHAR2(50)  := 'ORG_CODE';                 -- ORG_CODE
-- End   2009/08/26 Ver.1.3 0001154 M.Hiruta DELETE
  cv_token_count            CONSTANT VARCHAR2(50)  := 'COUNT';                    -- 件数
  cv_token_from_location    CONSTANT VARCHAR2(50)  := 'FROM_LOCATION';            -- 売上振替元拠点コード
  cv_token_from_customer    CONSTANT VARCHAR2(50)  := 'FROM_CUSTOMER';            -- 売上振替元顧客コード
  cv_token_to_location      CONSTANT VARCHAR2(50)  := 'TO_LOCATION';              -- 売上振替先拠点コード
  -- スペース
  cv_space                  CONSTANT VARCHAR2(1)   := ' ';                        -- スペース
  -- 出力区分
  cv_which                  CONSTANT VARCHAR2(3)   := 'LOG';                      -- ログ
  -- SVF起動パラメータ
  cv_file_id                CONSTANT VARCHAR2(20)  := 'XXCOK008A05R';             -- 帳票ID
  cv_output_mode            CONSTANT VARCHAR2(1)   := '1';                        -- 出力区分(PDF出力)
  cv_extension              CONSTANT VARCHAR2(10)  := '.pdf';                     -- 出力ファイル名拡張子(PDF出力)
  cv_frm_file               CONSTANT VARCHAR2(20)  := 'XXCOK008A05S.xml';         -- フォーム様式ファイル名
  cv_vrq_file               CONSTANT VARCHAR2(20)  := 'XXCOK008A05S.vrq';         -- クエリー様式ファイル名
  -- 数値
  cn_0                      CONSTANT NUMBER        := 0;                          -- 数値：0
  cn_1                      CONSTANT NUMBER        := 1;                          -- 数値：1
  -- 文字
  cv_0                      CONSTANT VARCHAR2(1)   := '0';                        -- 文字：'0'
  --==========================
  -- グローバル変数
  --==========================
  -- 件数カウンタ
  gn_target_cnt             NUMBER        DEFAULT 0;            -- 対象件数
  gn_normal_cnt             NUMBER        DEFAULT 0;            -- 正常件数
  gn_error_cnt              NUMBER        DEFAULT 0;            -- エラー件数
  gn_warn_cnt               NUMBER        DEFAULT 0;            -- スキップ件数
  -- 変数
-- Start 2009/08/26 Ver.1.3 0001154 M.Hiruta DELETE
--  gv_org_code               VARCHAR2(50)  DEFAULT NULL;         -- プロファイル値(在庫組織コード_営業組織)
--  gn_org_id                 NUMBER        DEFAULT NULL;         -- 在庫組織ID
-- End   2009/08/26 Ver.1.3 0001154 M.Hiruta DELETE
  gn_org_id_sales           NUMBER        DEFAULT NULL;         -- 営業単位ID
  gd_process_date           DATE          DEFAULT NULL;         -- 業務処理日付
  gv_no_data_msg            VARCHAR2(30)  DEFAULT NULL;         -- 対象データなしメッセージ
  --===============================
  -- グローバルカーソル
  --===============================
  CURSOR g_target_cur(
    iv_selling_from_base_code IN VARCHAR2    -- 売上振替元拠点コード
   ,iv_selling_from_cust_code IN VARCHAR2    -- 売上振替元顧客コード
   ,iv_selling_to_base_code   IN VARCHAR2    -- 売上振替先拠点コード
  )
  IS
    SELECT  xsri.selling_from_base_code                                    AS selling_from_base_code  -- 売上振替元拠点コード
           ,mkhp.party_name                                                AS selling_from_base_name  -- 売上振替元拠点名
           ,xsri.selling_from_cust_code                                    AS selling_from_cust_code  -- 売上振替元顧客コード
           ,mhp.party_name                                                 AS selling_from_cust_name  -- 売上振替元顧客名
           ,mjrre.source_number                                            AS selling_from_emp_code   -- 売上振替元担当営業コード
           ,mpapf.per_information18 || cv_space || mpapf.per_information19 AS selling_from_emp_name   -- 売上振替元担当営業名(姓 名)
           ,xsri.selling_to_cust_code                                      AS selling_to_cust_code    -- 売上振替先顧客コード
           ,shp.party_name                                                 AS selling_to_cust_name    -- 売上振替先顧客名
           ,xca.sale_base_code                                             AS selling_to_base_code    -- 売上振替先拠点コード
           ,skhp.party_name                                                AS selling_to_base_name    -- 売上振替先拠点名
           ,sjrre.source_number                                            AS selling_to_emp_code     -- 売上振替先担当営業コード
           ,spapf.per_information18 || cv_space || spapf.per_information19 AS selling_to_emp_name     -- 売上振替先担当営業名(姓 名)
           ,xsri.selling_trns_rate                                         AS selling_trns_rate       -- 売上振替割合
           ,hl.address3                                                    AS section_code            -- 地区コード
    FROM    xxcok_selling_rate_info    xsri     -- 売上振替割合情報テーブル
           ,hz_cust_accounts           mhca     -- 顧客マスタ(振替元)
           ,hz_cust_accounts           shca     -- 顧客マスタ(振替先)
           ,hz_cust_accounts           mkhca    -- 顧客マスタ(振替元拠点)
           ,hz_cust_accounts           skhca    -- 顧客マスタ(振替先拠点)
           ,hz_parties                 mkhp     -- パーティマスタ(振替元拠点)
           ,hz_parties                 skhp     -- パーティマスタ(振替先拠点)
           ,hz_parties                 mhp      -- パーティマスタ(振替元顧客)
           ,hz_parties                 shp      -- パーティマスタ(振替先顧客)
           ,hz_cust_acct_sites_all     hcas     -- 顧客所在地マスタ
           ,hz_party_sites             hps      -- パーティサイトマスタ
           ,hz_locations               hl       -- 顧客事業所
           ,hz_organization_profiles   mhop     -- 組織プロファイル(振替元)
           ,hz_organization_profiles   shop     -- 組織プロファイル(振替先)
           ,ego_resource_agv           mera     -- 組織プロファイル拡張View(振替元)
           ,ego_resource_agv           sera     -- 組織プロファイル拡張View(振替先)
           ,jtf_rs_resource_extns      mjrre    -- リソース(振替元)
           ,jtf_rs_resource_extns      sjrre    -- リソース(振替先)
           ,xxcmm_cust_accounts        xca      -- 顧客追加情報
           ,per_all_people_f           mpapf    -- 従業員マスタ(振替元)
           ,per_all_people_f           spapf    -- 従業員マスタ(振替先)
    WHERE xsri.selling_from_base_code                = NVL( iv_selling_from_base_code, xsri.selling_from_base_code )
    AND   xsri.selling_from_cust_code                = NVL( iv_selling_from_cust_code, xsri.selling_from_cust_code )
    AND   xsri.selling_from_cust_code                               = mhca.account_number
    AND   mhca.party_id                                             = mhp.party_id
    AND   mhca.party_id                                             = mhop.party_id
-- Start 2009/08/26 Ver.1.3 0001154 M.Hiruta REPAIR
--    AND   TRUNC( mhop.effective_start_date )                       <= gd_process_date
    AND   TRUNC( NVL( mhop.effective_start_date, SYSDATE ) )       <= TRUNC( SYSDATE )
-- End   2009/08/26 Ver.1.3 0001154 M.Hiruta REPAIR
    AND   mhop.organization_profile_id                              = mera.organization_profile_id
-- Start 2009/08/26 Ver.1.3 0001154 M.Hiruta REPAIR
--    AND   TRUNC( NVL( mhop.effective_end_date, gd_process_date ) ) >= gd_process_date
    AND   TRUNC( NVL( mhop.effective_end_date, SYSDATE ) )         >= TRUNC( SYSDATE )
-- End   2009/08/26 Ver.1.3 0001154 M.Hiruta REPAIR
    AND   TRUNC( NVL( mera.resource_s_date, gd_process_date ) )    <= gd_process_date
    AND   TRUNC( NVL( mera.resource_e_date, gd_process_date ) )    >= gd_process_date
-- Start 2009/08/26 Ver.1.3 0001154 M.Hiruta ADD
    AND   TRUNC( NVL( mpapf.effective_start_date, gd_process_date ) ) <= gd_process_date
    AND   TRUNC( NVL( mpapf.effective_end_date,   gd_process_date ) ) >= gd_process_date
-- End   2009/08/26 Ver.1.3 0001154 M.Hiruta ADD
    AND   mjrre.source_number                                       = mera.resource_no
    AND   mhca.cust_account_id                                      = hcas.cust_account_id
    AND   hcas.party_site_id                                        = hps.party_site_id
    AND   hcas.org_id                                               = gn_org_id_sales
    AND   hps.location_id                                           = hl.location_id
    AND   xsri.selling_to_cust_code                                 = shca.account_number
    AND   shca.party_id                                             = shp.party_id
    AND   shca.party_id                                             = shop.party_id
-- Start 2009/08/26 Ver.1.3 0001154 M.Hiruta REPAIR
--    AND   TRUNC( shop.effective_start_date )                       <= gd_process_date
    AND   TRUNC( shop.effective_start_date )                       <= TRUNC( SYSDATE )
-- End   2009/08/26 Ver.1.3 0001154 M.Hiruta REPAIR
    AND   shop.organization_profile_id                              = sera.organization_profile_id
-- Start 2009/08/26 Ver.1.3 0001154 M.Hiruta REPAIR
--    AND   TRUNC( NVL( shop.effective_end_date, gd_process_date ) ) >= gd_process_date
    AND   TRUNC( NVL( shop.effective_end_date, SYSDATE ) )         >= TRUNC( SYSDATE )
-- End   2009/08/26 Ver.1.3 0001154 M.Hiruta REPAIR
    AND   TRUNC( NVL( sera.resource_s_date, gd_process_date ) )    <= gd_process_date
    AND   TRUNC( NVL( sera.resource_e_date, gd_process_date ) )    >= gd_process_date
-- Start 2009/08/26 Ver.1.3 0001154 M.Hiruta ADD
    AND   TRUNC( NVL( spapf.effective_start_date, gd_process_date ) ) <= gd_process_date
    AND   TRUNC( NVL( spapf.effective_end_date,   gd_process_date ) ) >= gd_process_date
-- End   2009/08/26 Ver.1.3 0001154 M.Hiruta ADD
    AND   sjrre.source_number                                       = sera.resource_no
    AND   xsri.selling_from_base_code                               = mkhca.account_number
    AND   mkhca.party_id                                            = mkhp.party_id
    AND   xsri.invalid_flag                                         = cv_0
    AND   shca.cust_account_id                                      = xca.customer_id
    AND   xca.sale_base_code                                        = NVL( iv_selling_to_base_code, xca.sale_base_code )
    AND   xca.sale_base_code                                        = skhca.account_number
    AND   skhca.party_id                                            = skhp.party_id
    AND   mpapf.employee_number                                     = mjrre.source_number
    AND   spapf.employee_number                                     = sjrre.source_number;
  TYPE g_target_ttype IS TABLE OF g_target_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  g_target_tab g_target_ttype;
  --=================================
  -- 共通例外
  --=================================
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
  --*** ロック取得エラー ***
  global_lock_err_expt      EXCEPTION;
  --=================================
  -- プラグマ
  --=================================
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
  PRAGMA EXCEPTION_INIT( global_lock_err_expt, -54 );
--
  /**********************************************************************************
   * Procedure Name   : del_rep_selling_trns_chk
   * Description      : ワークテーブルデータ削除(A-5)
   ***********************************************************************************/
  PROCEDURE del_rep_selling_trns_chk(
    ov_errbuf   OUT VARCHAR2      -- エラー・メッセージ
   ,ov_retcode  OUT VARCHAR2      -- リターン・コード
   ,ov_errmsg   OUT VARCHAR2      -- ユーザー・エラー・メッセージ
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_rep_selling_trns_chk'; -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf     VARCHAR2(5000) DEFAULT NULL;                -- エラー・メッセージ
    lv_retcode    VARCHAR2(1)    DEFAULT cv_status_normal;    -- リターン・コード
    lv_errmsg     VARCHAR2(5000) DEFAULT NULL;                -- ユーザー・エラー・メッセージ
    lb_retcode    BOOLEAN        DEFAULT TRUE;                -- メッセージ出力関数戻り値
    --===============================
    -- ローカルカーソル
    --===============================
    CURSOR rep_selling_trns_chk_cur
    IS
    SELECT 'X'
    FROM   xxcok_rep_selling_trns_chk  xrstc
    WHERE  xrstc.request_id = cn_request_id
    FOR UPDATE OF xrstc.request_id NOWAIT;
  BEGIN
    -- ステータス初期化
    ov_retcode := cv_status_normal;
    --===========================================================
    -- 売上振替割合チェックリスト帳票ワークテーブルロック取得処理
    --===========================================================
    OPEN rep_selling_trns_chk_cur;
    CLOSE rep_selling_trns_chk_cur;
    --===========================================================
    -- 売上振替割合チェックリスト帳票ワークテーブルデータ削除処理
    --===========================================================
    BEGIN
      DELETE FROM xxcok_rep_selling_trns_chk  xrstc
      WHERE xrstc.request_id = cn_request_id;
      -- ===============================================
      -- 成功件数取得
      -- ===============================================
      gn_normal_cnt := SQL%ROWCOUNT;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_appl
                       ,iv_name         => cv_msg_xxcok_10413
                       ,iv_token_name1  => cv_token_request_id
                       ,iv_token_value1 => cn_request_id
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG   -- 出力区分
                       ,iv_message  => lv_errmsg      -- メッセージ
                       ,in_new_line => cn_0           -- 改行
                      );
    END;
  EXCEPTION
    -- *** ロック取得例外ハンドラ ***
    WHEN global_lock_err_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl
                     ,iv_name         => cv_msg_xxcok_10412
                     ,iv_token_name1  => cv_token_request_id
                     ,iv_token_value1 => cn_request_id
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG   -- 出力区分
                     ,iv_message  => lv_errmsg      -- メッセージ
                     ,in_new_line => cn_0           -- 改行
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END del_rep_selling_trns_chk;
--
  /**********************************************************************************
   * Procedure Name   : start_svf
   * Description      : SVF起動(A-4)
   ***********************************************************************************/
  PROCEDURE start_svf(
    ov_errbuf  OUT VARCHAR2     -- エラー・メッセージ
   ,ov_retcode OUT VARCHAR2     -- リターン・コード
   ,ov_errmsg  OUT VARCHAR2     -- ユーザー・エラー・メッセージ
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'start_svf';    -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf     VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode    VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg     VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lb_retcode    BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
    lv_outmsg     VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lv_date       VARCHAR2(8)    DEFAULT NULL;                 -- 出力ファイル名用日付
    lv_file_name  VARCHAR2(100)  DEFAULT NULL;                 -- 出力ファイル名
  BEGIN
    -- ステータス初期化
    ov_retcode := cv_status_normal;
    --====================
    -- システム日付型変換
    --====================
    lv_date := TO_CHAR( SYSDATE, 'YYYYMMDD' );
    --============================================
    -- 出力ファイル名(帳票ID + YYYYMMDD + 要求ID)
    --============================================
    lv_file_name := cv_file_id || lv_date || TO_CHAR( cn_request_id ) || cv_extension;
    --==============================
    -- SVF起動処理
    --==============================
    xxccp_svfcommon_pkg.submit_svf_request(
        ov_errbuf        => lv_errbuf                 -- エラーバッファ
      , ov_retcode       => lv_retcode                -- リターンコード
      , ov_errmsg        => lv_errmsg                 -- エラーメッセージ
      , iv_conc_name     => cv_pkg_name               -- コンカレント名
      , iv_file_name     => lv_file_name              -- 出力ファイル名
      , iv_file_id       => cv_file_id                -- 帳票ID
      , iv_output_mode   => cv_output_mode            -- 出力区分
      , iv_frm_file      => cv_frm_file               -- フォーム様式ファイル名
      , iv_vrq_file      => cv_vrq_file               -- クエリー様式ファイル名
-- Start 2009/08/26 Ver.1.3 0001154 M.Hiruta REPAIR
--      , iv_org_id        => TO_CHAR( gn_org_id )      -- ORG_ID
      , iv_org_id        => NULL                      -- ORG_ID
-- End   2009/08/26 Ver.1.3 0001154 M.Hiruta REPAIR
      , iv_user_name     => fnd_global.user_name      -- ログイン・ユーザ名
      , iv_resp_name     => fnd_global.resp_name      -- ログイン・ユーザ職責名
      , iv_doc_name      => NULL                      -- 文書名
      , iv_printer_name  => NULL                      -- プリンタ名
      , iv_request_id    => TO_CHAR( cn_request_id )  -- 要求ID
      , iv_nodata_msg    => NULL                      -- データなしメッセージ
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl
                     ,iv_name         => cv_msg_xxcok_00040
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG   -- 出力区分
                     ,iv_message  => lv_outmsg      -- メッセージ
                     ,in_new_line => cn_0           -- 改行
                    );
      RAISE global_api_expt;
    END IF;
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END start_svf;
--
  /**********************************************************************************
   * Procedure Name   : ins_rep_selling_trns_chk
   * Description      : ワークテーブルデータ登録(A-3)
   ***********************************************************************************/
  PROCEDURE ins_rep_selling_trns_chk(
    ov_errbuf                 OUT VARCHAR2     -- エラー・メッセージ
   ,ov_retcode                OUT VARCHAR2     -- リターン・コード
   ,ov_errmsg                 OUT VARCHAR2     -- ユーザー・エラー・メッセージ
   ,iv_selling_from_base_code IN  VARCHAR2     -- 売上振替元拠点コード
   ,iv_selling_from_cust_code IN  VARCHAR2     -- 売上振替元顧客コード
   ,iv_selling_to_base_code   IN  VARCHAR2     -- 売上振替先拠点コード
   ,in_i                      IN  NUMBER       -- インデックス
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'ins_rep_selling_trns_chk'; -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL;                -- エラー・メッセージ
    lv_retcode  VARCHAR2(1)    DEFAULT cv_status_normal;    -- リターン・コード
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL;                -- ユーザー・エラー・メッセージ
  BEGIN
    -- ステータス初期化
    ov_retcode := cv_status_normal;
    --==============================
    -- ワークテーブルデータ登録
    --==============================
    IF ( gn_target_cnt <> 0 ) THEN
      INSERT INTO xxcok_rep_selling_trns_chk(
         selling_from_base_code_in          -- 売上振替元拠点
        ,selling_from_cust_code_in          -- 売上振替元顧客
        ,selling_to_base_code_in            -- 売上振替先拠点
        ,selling_from_base_code             -- 売上振替元拠点コード
        ,selling_from_base_name             -- 売上振替元拠点名
        ,selling_from_cust_code             -- 売上振替元顧客コード
        ,selling_from_cust_name             -- 売上振替元顧客名
        ,selling_from_emp_code              -- 売上振替元担当営業コード
        ,selling_from_emp_name              -- 売上振替元担当営業名
        ,selling_to_cust_code               -- 売上振替先顧客コード
        ,selling_to_cust_name               -- 売上振替先顧客名
        ,selling_to_base_code               -- 売上振替先拠点コード
        ,selling_to_base_name               -- 売上振替先拠点名
        ,selling_to_emp_code                -- 売上振替先担当営業コード
        ,selling_to_emp_name                -- 売上振替先担当営業名
        ,selling_trns_rate                  -- 売上振替割合
        ,section_code                       -- 地区コード
        ,no_data_message                    -- 0件メッセージ
        ,created_by                         -- 作成者
        ,creation_date                      -- 作成日
        ,last_updated_by                    -- 最終更新者
        ,last_update_date                   -- 最終更新日
        ,last_update_login                  -- 最終更新ログイン
        ,request_id                         -- 要求ID
        ,program_application_id             -- コンカレント・プログラム・アプリケーションID
        ,program_id                         -- コンカレント・プログラムID
        ,program_update_date                -- プログラム更新日
      )
      VALUES(
         iv_selling_from_base_code                       -- selling_from_base_code_in
        ,iv_selling_from_cust_code                       -- selling_from_cust_code_in
        ,iv_selling_to_base_code                         -- selling_to_base_code_in
        ,g_target_tab( in_i ).selling_from_base_code     -- selling_from_base_code
        ,g_target_tab( in_i ).selling_from_base_name     -- selling_from_base_name
        ,g_target_tab( in_i ).selling_from_cust_code     -- selling_from_cust_code
-- Start 2020/05/26 Ver.1.4 S.Kuwako REPAIR
--        ,g_target_tab( in_i ).selling_from_cust_name     -- selling_from_cust_name
        ,SUBSTRB( g_target_tab( in_i ).selling_from_cust_name, 1, 100 )
                                                         -- selling_from_cust_name
-- End   2020/05/26 Ver.1.4 S.Kuwako REPAIR
        ,g_target_tab( in_i ).selling_from_emp_code      -- selling_from_emp_code
        ,g_target_tab( in_i ).selling_from_emp_name      -- selling_from_emp_name
        ,g_target_tab( in_i ).selling_to_cust_code       -- selling_to_cust_code
-- Start 2020/05/26 Ver.1.4 S.Kuwako REPAIR
--        ,g_target_tab( in_i ).selling_to_cust_name       -- selling_to_cust_name
        ,SUBSTRB( g_target_tab( in_i ).selling_to_cust_name, 1, 100 )
                                                         -- selling_to_cust_name
-- End   2020/05/26 Ver.1.4 S.Kuwako REPAIR
        ,g_target_tab( in_i ).selling_to_base_code       -- selling_to_base_code
        ,g_target_tab( in_i ).selling_to_base_name       -- selling_to_base_name
        ,g_target_tab( in_i ).selling_to_emp_code        -- selling_to_emp_code
        ,g_target_tab( in_i ).selling_to_emp_name        -- selling_to_emp_name
        ,g_target_tab( in_i ).selling_trns_rate          -- selling_trns_rate
        ,g_target_tab( in_i ).section_code               -- section_code
        ,NULL                                            -- no_data_message
        ,cn_created_by                                   -- created_by
        ,SYSDATE                                         -- creation_date
        ,cn_last_updated_by                              -- last_updated_by
        ,SYSDATE                                         -- last_update_date
        ,cn_last_update_login                            -- last_update_login
        ,cn_request_id                                   -- request_id
        ,cn_program_application_id                       -- program_application_id
        ,cn_program_id                                   -- program_id
        ,SYSDATE                                         -- program_update_date
      );
    ELSE
      -- ===============================================
      -- 対象件数0件時ワークテーブルデータ登録
      -- ===============================================
      INSERT INTO xxcok_rep_selling_trns_chk(
        selling_from_base_code_in           -- 売上振替元拠点
       ,selling_from_cust_code_in           -- 売上振替元顧客
       ,selling_to_base_code_in             -- 売上振替先拠点
       ,no_data_message                     -- 0件メッセージ
       ,created_by                          -- 作成者
       ,creation_date                       -- 作成日
       ,last_updated_by                     -- 最終更新者
       ,last_update_date                    -- 最終更新日
       ,last_update_login                   -- 最終更新ログイン
       ,request_id                          -- 要求ID
       ,program_application_id              -- コンカレント・プログラム・アプリケーションID
       ,program_id                          -- コンカレント・プログラムID
       ,program_update_date                 -- プログラム更新日
      )
      VALUES(
        iv_selling_from_base_code           -- selling_from_base_code_in
       ,iv_selling_from_cust_code           -- selling_from_cust_code_in
       ,iv_selling_to_base_code             -- selling_to_base_code_in
       ,gv_no_data_msg                      -- no_data_message
       ,cn_created_by                       -- created_by
       ,SYSDATE                             -- creation_date
       ,cn_last_updated_by                  -- last_updated_by
       ,SYSDATE                             -- last_update_date
       ,cn_last_update_login                -- last_update_login
       ,cn_request_id                       -- request_id
       ,cn_program_application_id           -- program_application_id
       ,cn_program_id                       -- program_id
       ,SYSDATE                             -- program_update_date
      );
    END IF;
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END ins_rep_selling_trns_chk;
--
  /**********************************************************************************
   * Procedure Name   : get_target_data
   * Description      : データ取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_target_data(
    ov_errbuf                 OUT VARCHAR2         -- エラー・メッセージ
   ,ov_retcode                OUT VARCHAR2         -- リターン・コード
   ,ov_errmsg                 OUT VARCHAR2         -- ユーザー・エラー・メッセージ
   ,iv_selling_from_base_code IN  VARCHAR2         -- 売上振替元拠点コード
   ,iv_selling_from_cust_code IN  VARCHAR2         -- 売上振替元顧客コード
   ,iv_selling_to_base_code   IN  VARCHAR2         -- 売上振替先拠点コード
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'get_target_data'; -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL;                -- エラー・メッセージ
    lv_retcode  VARCHAR2(1)    DEFAULT cv_status_normal;    -- リターン・コード
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL;                -- ユーザー・エラー・メッセージ
  BEGIN
    -- ステータス初期化
    ov_retcode := cv_status_normal;
    --===============================
    -- データ取得
    --===============================
    OPEN g_target_cur(
      iv_selling_from_base_code => iv_selling_from_base_code
     ,iv_selling_from_cust_code => iv_selling_from_cust_code
     ,iv_selling_to_base_code   => iv_selling_to_base_code
    );
    FETCH g_target_cur BULK COLLECT INTO g_target_tab;
    CLOSE g_target_cur;
    --=======================================
    -- 対象件数取得
    --=======================================
    gn_target_cnt := g_target_tab.COUNT;
    IF ( gn_target_cnt = 0 ) THEN
      --=====================================
      -- 対象データなしメッセージ取得
      --=====================================
      gv_no_data_msg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl
                         ,iv_name         => cv_msg_xxcok_00001
                        );
      --===============================================
      -- 対象件数0件時ワークテーブルデータ登録
      --===============================================
      ins_rep_selling_trns_chk(
         ov_errbuf                 => lv_errbuf                    -- エラー・メッセージ
        ,ov_retcode                => lv_retcode                   -- リターン・コード
        ,ov_errmsg                 => lv_errmsg                    -- ユーザー・エラー・メッセージ
        ,iv_selling_from_base_code => iv_selling_from_base_code    -- 売上振替元拠点コード
        ,iv_selling_from_cust_code => iv_selling_from_cust_code    -- 売上振替元顧客コード
        ,iv_selling_to_base_code   => iv_selling_to_base_code      -- 売上振替先拠点コード
        ,in_i                      => cn_0                         -- インデックス
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    ELSE
      <<get_data_loop>>
      FOR i IN 1 .. g_target_tab.COUNT LOOP
        --==============================
        -- ワークテーブルデータ登録
        --==============================
        ins_rep_selling_trns_chk(
           ov_errbuf                 => lv_errbuf                  -- エラー・メッセージ
          ,ov_retcode                => lv_retcode                 -- リターン・コード
          ,ov_errmsg                 => lv_errmsg                  -- ユーザー・エラー・メッセージ
          ,iv_selling_from_base_code => iv_selling_from_base_code  -- 売上振替元拠点コード
          ,iv_selling_from_cust_code => iv_selling_from_cust_code  -- 売上振替元顧客コード
          ,iv_selling_to_base_code   => iv_selling_to_base_code    -- 売上振替先拠点コード
          ,in_i                      => i                          -- インデックス
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      END LOOP get_data_loop;
    END IF;
  EXCEPTION
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END get_target_data;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf                 OUT VARCHAR2     -- エラー・メッセージ
   ,ov_retcode                OUT VARCHAR2     -- リターン・コード
   ,ov_errmsg                 OUT VARCHAR2     -- ユーザー・エラー・メッセージ
   ,iv_selling_from_base_code IN  VARCHAR2     -- 売上振替元拠点コード
   ,iv_selling_from_cust_code IN  VARCHAR2     -- 売上振替元顧客コード
   ,iv_selling_to_base_code   IN  VARCHAR2     -- 売上振替先拠点コード
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init';  -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf     VARCHAR2(5000)  DEFAULT NULL;                -- エラー・メッセージ
    lv_retcode    VARCHAR2(1)     DEFAULT cv_status_normal;    -- リターン・コード
    lv_errmsg     VARCHAR2(5000)  DEFAULT NULL;                -- ユーザー・エラー・メッセージ
    lv_outmsg     VARCHAR2(5000)  DEFAULT NULL;                -- 出力用メッセージ
    lb_retcode    BOOLEAN         DEFAULT TRUE;                -- メッセージ出力関数戻り値
    --===============================
    -- ローカル例外
    --===============================
    --*** 初期処理エラー ***
    init_fail_expt EXCEPTION;
  BEGIN
    -- ステータス初期化
    ov_retcode := cv_status_normal;
    --==============================
    -- プログラム入力項目を出力
    --==============================
    -- 売上振替元拠点コード
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl
                   ,iv_name         => cv_msg_xxcok_00082
                   ,iv_token_name1  => cv_token_from_location
                   ,iv_token_value1 => iv_selling_from_base_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG
                   ,iv_message  => lv_outmsg
                   ,in_new_line => cn_0
                  );
    -- 売上振替元顧客コード
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl
                   ,iv_name         => cv_msg_xxcok_00083
                   ,iv_token_name1  => cv_token_from_customer
                   ,iv_token_value1 => iv_selling_from_cust_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG
                   ,iv_message  => lv_outmsg
                   ,in_new_line => cn_0
                  );
    -- 売上振替先拠点コード
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl
                   ,iv_name         => cv_msg_xxcok_00084
                   ,iv_token_name1  => cv_token_to_location
                   ,iv_token_value1 => iv_selling_to_base_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG
                   ,iv_message  => lv_outmsg
                   ,in_new_line => cn_1
                  );
-- Start 2009/08/26 Ver.1.3 0001154 M.Hiruta DELETE
--    --==============================
--    -- プロファイル(在庫組織コード_営業組織)を取得する
--    --==============================
--    gv_org_code := FND_PROFILE.VALUE( cv_prof_org_code_sales );
--    IF( gv_org_code IS NULL ) THEN
--      lv_errmsg  := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_xxcok_appl
--                     ,iv_name         => cv_msg_xxcok_00003
--                     ,iv_token_name1  => cv_token_profile
--                     ,iv_token_value1 => cv_prof_org_code_sales
--                    );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.LOG   -- 出力区分
--                     ,iv_message  => lv_errmsg      -- メッセージ
--                     ,in_new_line => cn_0           -- 改行
--                    );
--      RAISE init_fail_expt;
--    END IF;
-- End   2009/08/26 Ver.1.3 0001154 M.Hiruta DELETE
    --==============================
    -- プロファイル(営業単位ID)を取得する
    --==============================
    gn_org_id_sales := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_org_id ) );
    IF( gn_org_id_sales IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl
                     ,iv_name         => cv_msg_xxcok_00003
                     ,iv_token_name1  => cv_token_profile
                     ,iv_token_value1 => cv_prof_org_id
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG   -- 出力区分
                     ,iv_message  => lv_errmsg      -- メッセージ
                     ,in_new_line => cn_0           -- 改行
                    );
      RAISE init_fail_expt;
    END IF;
-- Start 2009/08/26 Ver.1.3 0001154 M.Hiruta DELETE
--    --===============================================
--    -- 在庫組織IDを取得する
--    --===============================================
--    gn_org_id := xxcoi_common_pkg.get_organization_id( gv_org_code );
--    IF ( gn_org_id IS NULL ) THEN
--      lv_errmsg  := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_xxcok_appl
--                    , iv_name         => cv_msg_xxcok_00013
--                    , iv_token_name1  => cv_token_org_code
--                    , iv_token_value1 => gv_org_code
--                    );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.LOG   -- 出力区分
--                    , iv_message  => lv_errmsg      -- メッセージ
--                    , in_new_line => cn_0           -- 改行
--                    );
--      RAISE init_fail_expt;
--    END IF;
-- End   2009/08/26 Ver.1.3 0001154 M.Hiruta DELETE
    --==============================
    -- 業務処理日付を取得する
    --==============================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- 取得エラー
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl
                     ,iv_name         => cv_msg_xxcok_00028
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG   -- 出力区分
                     ,iv_message  => lv_errmsg      -- メッセージ
                     ,in_new_line => cn_0           -- 改行
                    );
      RAISE init_fail_expt;
    END IF;
  EXCEPTION
    -- *** 初期処理エラー ***
    WHEN init_fail_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
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
    ov_errbuf                 OUT VARCHAR2         -- エラー・メッセージ
   ,ov_retcode                OUT VARCHAR2         -- リターン・コード
   ,ov_errmsg                 OUT VARCHAR2         -- ユーザー・エラー・メッセージ
   ,iv_selling_from_base_code IN  VARCHAR2         -- 売上振替元拠点コード
   ,iv_selling_from_cust_code IN  VARCHAR2         -- 売上振替元顧客コード
   ,iv_selling_to_base_code   IN  VARCHAR2         -- 売上振替先拠点コード
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL;                -- エラー・メッセージ
    lv_retcode  VARCHAR2(1)    DEFAULT cv_status_normal;    -- リターン・コード
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL;                -- ユーザー・エラー・メッセージ
  BEGIN
    -- ステータス初期化
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
      ov_errbuf                 => lv_errbuf                    -- エラー・メッセージ
     ,ov_retcode                => lv_retcode                   -- リターン・コード
     ,ov_errmsg                 => lv_errmsg                    -- ユーザー・エラー・メッセージ
     ,iv_selling_from_base_code => iv_selling_from_base_code    -- 売上振替元拠点コード
     ,iv_selling_from_cust_code => iv_selling_from_cust_code    -- 売上振替元顧客コード
     ,iv_selling_to_base_code   => iv_selling_to_base_code      -- 売上振替先拠点コード
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==============================================
    -- A-2.データ取得, A-3.ワークテーブルデータ登録
    --==============================================
    get_target_data(
      ov_errbuf                 => lv_errbuf                    -- エラー・メッセージ
     ,ov_retcode                => lv_retcode                   -- リターン・コード
     ,ov_errmsg                 => lv_errmsg                    -- ユーザー・エラー・メッセージ
     ,iv_selling_from_base_code => iv_selling_from_base_code    -- 売上振替元拠点コード
     ,iv_selling_from_cust_code => iv_selling_from_cust_code    -- 売上振替元顧客コード
     ,iv_selling_to_base_code   => iv_selling_to_base_code      -- 売上振替先拠点コード
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --===========================
    -- ワークテーブルデータ確定
    --===========================
    COMMIT;
    --==========================
    -- A-4.SVF起動
    --==========================
    start_svf(
      ov_errbuf   => lv_errbuf            -- エラー・メッセージ
     ,ov_retcode  => lv_retcode           -- リターン・コード
     ,ov_errmsg   => lv_errmsg            -- ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --===============================
    -- A-5.ワークテーブルデータ削除
    --===============================
    del_rep_selling_trns_chk(
      ov_errbuf  => lv_errbuf             -- エラー・メッセージ
     ,ov_retcode => lv_retcode            -- リターン・コード
     ,ov_errmsg  => lv_errmsg             -- ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf                    OUT VARCHAR2         -- エラー・メッセージ
   ,retcode                   OUT VARCHAR2         -- リターン・コード
   ,iv_selling_from_base_code IN  VARCHAR2         -- 売上振替元拠点コード
   ,iv_selling_from_cust_code IN  VARCHAR2         -- 売上振替元顧客コード
   ,iv_selling_to_base_code   IN  VARCHAR2         -- 売上振替先拠点コード
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'main';   -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;                -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;    -- リターン・コード
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;                -- ユーザー・エラー・メッセージ
    lb_retcode      BOOLEAN        DEFAULT TRUE;                -- メッセージ出力関数戻り値
    lv_message_code VARCHAR2(100)  DEFAULT NULL;                -- 終了メッセージコード
    lv_outmsg       VARCHAR2(5000) DEFAULT NULL;                -- 出力用メッセージ
  BEGIN
    --===============================================
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    --===============================================
    xxccp_common_pkg.put_log_header(
      ov_retcode => lv_retcode
     ,ov_errbuf  => lv_errbuf
     ,ov_errmsg  => lv_errmsg
     ,iv_which   => cv_which
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    --===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    --===============================================
    submain(
       ov_errbuf                 => lv_errbuf                    -- エラー・メッセージ
      ,ov_retcode                => lv_retcode                   -- リターン・コード
      ,ov_errmsg                 => lv_errmsg                    -- ユーザー・エラー・メッセージ
      ,iv_selling_from_base_code => iv_selling_from_base_code    -- 売上振替元拠点コード
      ,iv_selling_from_cust_code => iv_selling_from_cust_code    -- 売上振替元顧客コード
      ,iv_selling_to_base_code   => iv_selling_to_base_code      -- 売上振替先拠点コード
    );
    --===============================================
    -- エラー出力
    --===============================================
    IF ( lv_retcode = cv_status_error ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG   -- 出力区分
                     ,iv_message  => lv_errmsg      -- メッセージ
                     ,in_new_line => cn_0           -- 改行
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG   -- 出力区分
                     ,iv_message  => lv_errbuf      -- メッセージ
                     ,in_new_line => cn_1           -- 改行
                    );
    END IF;
    --===============================================
    -- 対象件数出力
    --===============================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_appl
                   ,iv_name         => cv_msg_xxccp_90000
                   ,iv_token_name1  => cv_token_count
                   ,iv_token_value1 => TO_CHAR( gn_target_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG   -- 出力区分
                   ,iv_message  => lv_outmsg      -- メッセージ
                   ,in_new_line => cn_0           -- 改行
                  );
    --===============================================
    -- 成功件数出力(エラー発生の場合、成功件数:0件 エラー件数:1件  対象件数0件の場合、成功件数:0件)
    --===============================================
    IF ( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := cn_0;
      gn_error_cnt  := cn_1;
    ELSE
      IF ( gn_target_cnt = cn_0 ) THEN
        gn_normal_cnt := cn_0;
      END IF;
    END IF;
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_appl
                   ,iv_name         => cv_msg_xxccp_90001
                   ,iv_token_name1  => cv_token_count
                   ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG   -- 出力区分
                   ,iv_message  => lv_outmsg      -- メッセージ
                   ,in_new_line => cn_0           -- 改行
                  );
    --===============================================
    -- エラー件数出力
    --===============================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_appl
                   ,iv_name         => cv_msg_xxccp_90002
                   ,iv_token_name1  => cv_token_count
                   ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG   -- 出力区分
                   ,iv_message  => lv_outmsg      -- メッセージ
                   ,in_new_line => cn_1           -- 改行
                  );
    --===============================================
    -- 処理終了メッセージ出力
    --===============================================
    IF ( lv_retcode    = cv_status_normal ) THEN
      lv_message_code := cv_msg_xxccp_90004;
    ELSE
      lv_message_code := cv_msg_xxccp_90006;
    END IF;
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_appl
                   ,iv_name         => lv_message_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG   -- 出力区分
                   ,iv_message  => lv_outmsg      -- メッセージ
                   ,in_new_line => cn_0           -- 改行
                  );
    --===============================================
    -- ステータスセット
    --===============================================
    retcode := lv_retcode;
    --===============================================
    -- 終了ステータスエラー時、ロールバック
    --===============================================
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
  EXCEPTION
    -- *** 共通関数例外 ***
    WHEN global_api_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
  END main;
END XXCOK008A05R;
/
