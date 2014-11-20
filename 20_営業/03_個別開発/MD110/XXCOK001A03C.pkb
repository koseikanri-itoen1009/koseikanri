CREATE OR REPLACE PACKAGE BODY XXCOK001A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK001A03C_pkg(body)
 * Description      : 営業システム構築プロジェクト
 * MD.050           : アドオン：顧客移行情報のI/Fファイル作成 販売物流 MD050_COK_001_A03
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  dlt_data_p             パージ処理(A-2)
 *  upd_unconfirmed_data_p 未確定データ取消(A-3)
 *  get_cust_shift_info_p  連携対象顧客移行情報取得(A-4)
 *  open_file_p            ファイルオープン(A-5)
 *  create_flat_file_p     フラットファイル作成(A-6)
 *  close_file_p           ファイルクローズ(A-7)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/10/31    1.0   K.Suenaga        新規作成
 *  2009/02/02    1.1   K.Suenaga        [障害COK_001]夜バッチ対応/営業単位ID追加
 *  2009/02/05    1.2   K.Suenaga        [障害COK_009]クイックコードビューに有効日・無効日の判定を追加
 *                                                    ディレクトリパスの出力方法を変更
 *  2011/02/17    1.3   M.Hirose         [E_本稼動_02085] ステータス：確定前の追加
 *
 *****************************************************************************************/
  -- ===============================
  -- グローバル定数
  -- ===============================
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1)    := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn            CONSTANT VARCHAR2(1)    := xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error           CONSTANT VARCHAR2(1)    := xxccp_common_pkg.set_status_error;  -- 異常:2
  --WHOカラム
  cn_created_by              CONSTANT NUMBER        := fnd_global.user_id;         --CREATED_BY
  cd_creation_date           CONSTANT DATE          := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by         CONSTANT NUMBER        := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date        CONSTANT DATE          := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login       CONSTANT NUMBER        := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id              CONSTANT NUMBER        := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id  CONSTANT NUMBER        := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id              CONSTANT NUMBER        := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date     CONSTANT DATE          := SYSDATE;                    --PROGRAM_UPDATE_DATE  
  --パッケージ名
  cv_pkg_name               CONSTANT VARCHAR2(100)  := 'XXCOK001A03C';             -- パッケージ名
  --プロファイル
  cv_org_id                 CONSTANT VARCHAR2(10)   := 'ORG_ID';                   -- 営業単位ID  
  cv_comp_code              CONSTANT VARCHAR2(50)   := 'XXCOK1_AFF1_COMPANY_CODE'; -- 会社コードのプロファイル
  cv_cust_keep_period       CONSTANT VARCHAR2(50)   := 'XXCOK1_CUST_KEEP_PERIOD';  -- 保持期間のプロファイル
  cv_cust_dire_path         CONSTANT VARCHAR2(50)   := 'XXCOK1_CUST_DIRE_PATH';    -- ディレクトリパスのプロファイル
  cv_cust_file_name         CONSTANT VARCHAR2(50)   := 'XXCOK1_CUST_FILE_NAME';    -- ファイルパスのプロファイル
  --トークン名
  cv_profile_token          CONSTANT VARCHAR2(15)   := 'PROFILE';                  -- プロファイルのトークン名
  cv_dire_name_token        CONSTANT VARCHAR2(15)   := 'DIRECTORY';                -- ディレクトリのトークン名
  cv_file_name_token        CONSTANT VARCHAR2(15)   := 'FILE_NAME';                -- ファイルのトークン名
  cv_count_token            CONSTANT VARCHAR2(50)   := 'COUNT';                    -- 処理件数のトークン名
  cv_process_flag_token     CONSTANT VARCHAR2(12)   := 'PROCESS_FLAG';             -- 入力項目の起動区分のトークン名
  --メッセージ
  cv_operation_date         CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00028';         -- 業務処理日付取得エラー
  cv_profile_err_msg        CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00003';         -- プロファイル取得エラー
  cv_dire_name_msg          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00067';         -- ディレクトリ名メッセージ出力
  cv_file_name_msg          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00006';         -- ファイル名メッセージ出力
  cv_lock_err_msg           CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00064';         -- 顧客移行情報ロック取得エラー
  cv_dlt_err_msg            CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10058';         -- 削除処理エラー
  cv_upd_err_msg            CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10059';         -- 未確定データ取消処理エラー
  cv_target_count_err_msg   CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10096';         -- 対象件数なしエラー 
  cv_file_err_msg           CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00009';         -- ファイル存在チェックエラー
  cv_target_count_msg       CONSTANT VARCHAR2(50)   := 'APP-XXCCP1-90000';         -- 対象件数メッセージ
  cv_normal_count_msg       CONSTANT VARCHAR2(50)   := 'APP-XXCCP1-90001';         -- 成功件数メッセージ
  cv_err_count_msg          CONSTANT VARCHAR2(50)   := 'APP-XXCCP1-90002';         -- エラー件数メッセージ
  cv_normal_msg             CONSTANT VARCHAR2(50)   := 'APP-XXCCP1-90004';         -- 正常終了メッセージ
  cv_commit_msg             CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10383';         -- エラーコミットメッセージ
  cv_err_msg                CONSTANT VARCHAR2(50)   := 'APP-XXCCP1-90006';         -- エラー終了全ロールバックメッセージ
  cv_00078_msg              CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00078';         -- システム稼働日取得エラーメッセージ
  cv_00076_msg              CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00076';         -- 起動区分出力用メッセージ
  --アプリケーション短縮名
  cv_appli_xxcok_name       CONSTANT VARCHAR2(15)   := 'XXCOK';                    -- アプリケーション短縮名
  cv_appli_xxccp_name       CONSTANT VARCHAR2(50)   := 'XXCCP';                    -- アプリケーション短縮名
  --ステータス
  cv_input_status           CONSTANT VARCHAR2(1)    := 'I';                        -- 入力中のステータス
  cv_cancel_status          CONSTANT VARCHAR2(1)    := 'C';                        -- 取消のステータス
-- 2011/02/07 Ver.1.3 [E_本稼動_02085] SCS M.Hirose INS START
  cv_wait_status            CONSTANT VARCHAR2(1)    := 'W';                        -- 確定前のステータス
-- 2011/02/07 Ver.1.3 [E_本稼動_02085] SCS M.Hirose INS END
  --移行区分
  cv_shift_type             CONSTANT VARCHAR2(1)    := '1';                        -- 移行区分の年次定数
  --起動区分
  cv_normal_type            CONSTANT VARCHAR2(1)    := '1';                        -- 起動区分の"1"(通常起動)
-- フラグ
  cv_commit_flag            CONSTANT VARCHAR2(1)    := '1';                        -- エラーフラグ
  --参照タイプ
  cv_cust_shift_status      CONSTANT VARCHAR2(50)   := 'XXCOK1_CUST_SHIFT_STATUS'; -- 顧客移行ステータスの定数
  cv_shift_divide           CONSTANT VARCHAR2(50)   := 'XXCOK1_SHIFT_DIVIDE';      -- 移行分割の定数
  --記号
  cv_slash                  CONSTANT VARCHAR2(1)    := '/';                        -- スラッシュ
  cv_msg_double             CONSTANT VARCHAR2(1)    := '"';                        -- ダブルコーテーション  
  cv_msg_comma              CONSTANT VARCHAR2(1)    := ',';                        -- カンマ
  cv_msg_part               CONSTANT VARCHAR2(3)    := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3)    := '.';
--
  cv_open_mode              CONSTANT VARCHAR2(1)    := 'w';
  cn_max_linesize           CONSTANT BINARY_INTEGER := 32767;
  --稼動日取得関数
  cn_cal_type_one           CONSTANT NUMBER         := 1;                         -- カレンダー区分=1(システムカレンダ)
  cn_aft                    CONSTANT NUMBER         := 2;                         -- 処理区分"2"(後)
  cn_plus_days              CONSTANT NUMBER         := 1;                         -- 日数
  -- ===============================
  -- グローバル変数
  -- ===============================
  gn_target_cnt     NUMBER             DEFAULT NULL;                  -- 対象件数
  gn_normal_cnt     NUMBER             DEFAULT NULL;                  -- 正常件数
  gn_error_cnt      NUMBER             DEFAULT NULL;                  -- エラー件数
  gd_system_date    DATE               DEFAULT NULL;                  -- システム日付のグローバル変数
  gd_operation_date DATE               DEFAULT NULL;                  -- 業務処理日付のグローバル変数
  gv_comp_code      VARCHAR2(50)       DEFAULT NULL;                  -- 会社コードのグローバル変数
  gn_keep_period    NUMBER             DEFAULT NULL;                  -- 保持期間のグローバル変数
  gv_cust_dire_path VARCHAR2(50)       DEFAULT NULL;                  -- ディレクトリパスのグローバル変数
  gv_cust_file_name VARCHAR2(50)       DEFAULT NULL;                  -- ファイルパスのグローバル変数
  g_open_file       UTL_FILE.FILE_TYPE DEFAULT NULL;                  -- オープンファイルハンドルの変数
  gv_commit_flag    VARCHAR2(50)       DEFAULT '0' ;                  -- エラーフラグの変数
  gn_org_id         NUMBER             DEFAULT NULL;                  -- 営業単位ID
  -- ===============================
  -- グローバルカーソル
  -- ===============================
  CURSOR g_cust_cur
  IS
    SELECT xcsi.cust_shift_id                AS cust_shift_id           -- 顧客移行情報ID
         , xcsi.cust_code                    AS cust_code               -- 顧客コード
         , xcsi.prev_base_code               AS prev_base_code          -- 旧担当拠点コード
         , xcsi.new_base_code                AS new_base_code           -- 新担当拠点コード
         , xcsi.cust_shift_date              AS cust_shift_date         -- 顧客移行日
         , xcsi.target_acctg_year            AS target_acctg_year       -- 対象会計年度
         , xcsi.emp_code                     AS emp_code                -- 入力者コード
         , xcsi.input_date                   AS input_date              -- 入力日
         , xlv1.attribute1                   AS base_divide_status_code -- 拠点分割移行情報ステータスコード
         , xlv2.attribute1                   AS shift_section_type      -- 年次移行区分
         , hl.address3                       AS section_code            -- 行政地区コード
    FROM   xxcok_cust_shift_info             xcsi                       -- 顧客移行情報テーブル
         , hz_cust_accounts                  hca                        -- 顧客マスタ
         , hz_cust_acct_sites_all            hcas                       -- 顧客所在地マスタ
         , hz_party_sites                    hps                        -- パーティサイトマスタ
         , hz_locations                      hl                         -- 顧客事業所マスタ
         , xxcok_lookups_v                   xlv1                       -- クイックコードビュー
         , xxcok_lookups_v                   xlv2                       -- クイックコードビュー2
    WHERE  xcsi.cust_code                  = hca.account_number
    AND    xcsi.shift_type                 = cv_shift_type
    AND    xcsi.status                    <> cv_cancel_status
    AND    xlv1.lookup_type                = cv_cust_shift_status
    AND    xlv2.lookup_type                = cv_shift_divide
    AND    xcsi.status                     = xlv1.lookup_code
    AND    xcsi.shift_type                 = xlv2.lookup_code
    AND    hcas.cust_account_id            = hca.cust_account_id
    AND    hcas.party_site_id              = hps.party_site_id
    AND    hl.location_id                  = hps.location_id
    AND    hcas.org_id                     = gn_org_id
    AND    TRUNC( gd_operation_date ) BETWEEN xlv1.start_date_active
                              AND NVL( xlv1.end_date_active, TRUNC( gd_operation_date ) )
    AND    TRUNC( gd_operation_date ) BETWEEN xlv2.start_date_active
                              AND NVL( xlv2.end_date_active, TRUNC( gd_operation_date ) )
    ;
--
  TYPE g_cust_ttype IS TABLE OF g_cust_cur%ROWTYPE;
  g_cust_tab g_cust_ttype;
  -- ===============================
  -- グローバル例外
  -- ===============================
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
  --*** ロックエラー ***
  lock_expt EXCEPTION;
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf  OUT VARCHAR2                         -- エラー・メッセージ
  , ov_retcode OUT VARCHAR2                         -- リターン・コード
  , ov_errmsg  OUT VARCHAR2                         -- ユーザー・エラー・メッセージ 
  , iv_process_flag IN VARCHAR2                     -- 入力項目の起動区分パラメータ
  )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf         VARCHAR2(5000) DEFAULT NULL;  -- エラー・メッセージ
    lv_retcode        VARCHAR2(1)    DEFAULT NULL;  -- リターン・コード
    lv_errmsg         VARCHAR2(5000) DEFAULT NULL;  -- ユーザー・エラー・メッセージ
    lb_retcode        BOOLEAN        DEFAULT NULL;  -- メッセージ出力関数の戻り値
    lv_out_msg        VARCHAR2(100)  DEFAULT NULL;  -- メッセージ出力変数
    lv_token_value    VARCHAR2(100)  DEFAULT NULL;  -- トークンバリューの変数
    -- ===============================
    -- ローカル例外
    -- ===============================
    operation_date_expt EXCEPTION;                  -- 業務処理日付取得エラー
    get_profile_expt    EXCEPTION;                  -- プロファイル取得エラー
    system_operation_date_expt EXCEPTION;           -- システム稼働日取得エラー
--
  BEGIN
    ov_retcode := cv_status_normal;
    --==============================================================
    --入力パラメータの起動区分の項目をメッセージ出力
    --==============================================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_xxcok_name
                  , cv_00076_msg
                  , cv_process_flag_token
                  , iv_process_flag
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
    --システム日付を取得
    --==============================================================
    gd_system_date := SYSDATE;
    --==============================================================
    --業務処理日付を取得
    --==============================================================
    gd_operation_date := xxccp_common_pkg2.get_process_date;
--
    IF ( gd_operation_date IS NULL ) THEN
      RAISE operation_date_expt;
    END IF;
    --==============================================================
    --起動区分が通常起動の場合、システム稼動日取得を業務処理日付とする
    --==============================================================
    IF( iv_process_flag = cv_normal_type ) THEN
      gd_operation_date := xxcok_common_pkg.get_operating_day_f(
                             gd_operation_date    -- 上記で取得した業務処理日付
                           , cn_plus_days         -- 日数(1)
                           , cn_aft               -- 処理区分(2)
                           , cn_cal_type_one      -- カレンダー区分=1(システムカレンダ)
                           );
    END IF;
--
    IF ( gd_operation_date IS NULL ) THEN
      RAISE system_operation_date_expt;
    END IF;
    --==============================================================
    --カスタムプロファイルよりプロファイルを取得
    --==============================================================
    gn_org_id         := TO_NUMBER(FND_PROFILE.VALUE( cv_org_id           ));    -- 営業単位ID
    gv_comp_code      := FND_PROFILE.VALUE( cv_comp_code                   );    -- 会社コード
    gn_keep_period    := TO_NUMBER(FND_PROFILE.VALUE( cv_cust_keep_period ));    -- 保持期間
    gv_cust_dire_path := FND_PROFILE.VALUE( cv_cust_dire_path              );    -- ディレクトリパス
    gv_cust_file_name := FND_PROFILE.VALUE( cv_cust_file_name              );    -- ファイル名
--
    IF(gn_org_id IS NULL ) THEN
      lv_token_value  := cv_org_id;
      RAISE get_profile_expt;
    ELSIF( gv_comp_code IS NULL ) THEN
      lv_token_value  := cv_comp_code;
      RAISE get_profile_expt;
    ELSIF( gn_keep_period IS NULL ) THEN
      lv_token_value  := cv_cust_keep_period;
      RAISE get_profile_expt;
    ELSIF( gv_cust_dire_path IS NULL ) THEN
      lv_token_value  := cv_cust_dire_path;
      RAISE get_profile_expt;
    ELSIF( gv_cust_file_name IS NULL ) THEN
      lv_token_value  := cv_cust_file_name;
      RAISE get_profile_expt;
    END IF;
    --===============================================================
    --ディレクトリ名・ファイル名をメッセージ出力
    --===============================================================
    lv_out_msg   := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_dire_name_msg
                    , cv_dire_name_token
                    , xxcok_common_pkg.get_directory_path_f( gv_cust_dire_path )
                    );
    lb_retcode   := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- 出力区分
                    , lv_out_msg         -- メッセージ
                    , 0                  -- 改行
                    );
    lv_out_msg   := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_file_name_msg
                    , cv_file_name_token
                    , gv_cust_file_name
                    );
    lb_retcode   := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- 出力区分
                    , lv_out_msg         -- メッセージ
                    , 1                  -- 改行
                    );
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
    WHEN system_operation_date_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_00078_msg
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
    WHEN get_profile_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_profile_err_msg
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
   * Procedure Name   : dlt_data_p
   * Description      : パージ処理(A-2)
   ***********************************************************************************/
  PROCEDURE dlt_data_p(
    ov_errbuf  OUT VARCHAR2                               -- エラー・メッセージ
  , ov_retcode OUT VARCHAR2                               -- リターン・コード
  , ov_errmsg  OUT VARCHAR2                               -- ユーザー・エラー・メッセージ 
  )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'dlt_data_p'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;               -- エラー・メッセージ
    lv_retcode VARCHAR2(1)    DEFAULT NULL;               -- リターン・コード
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;               -- ユーザー・エラー・メッセージ
    lv_out_msg VARCHAR2(100)  DEFAULT NULL;               -- メッセージ出力変数
    lb_retcode BOOLEAN        DEFAULT NULL;               -- メッセージ出力関数の戻り値
    ld_months  DATE           DEFAULT NULL;               -- 格納ローカル変数
    --==============================================================
    --ロック取得用カーソル
    --==============================================================
    CURSOR l_dlt_cur(
      id_months IN DATE
    )
    IS
      SELECT 'X'
      FROM   xxcok_cust_shift_info xcsi
      WHERE  xcsi.cust_shift_date <= id_months
      FOR UPDATE OF xcsi.cust_shift_id NOWAIT;
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    ld_months := ADD_MONTHS(
                   gd_operation_date
                 , - gn_keep_period
                 );
--
    OPEN  l_dlt_cur(
            ld_months
          );
    CLOSE l_dlt_cur;
    --=============================================================
    --顧客移行情報テーブルの削除処理
    --=============================================================
    BEGIN
--
      DELETE
      FROM   xxcok_cust_shift_info   xcsi
      WHERE  xcsi.cust_shift_date <= ld_months;
--
    EXCEPTION
      -- *** 削除処理エラー ***
      WHEN OTHERS THEN
        lv_out_msg := xxccp_common_pkg.get_msg(
                        cv_appli_xxcok_name
                      , cv_dlt_err_msg
                      );
        lb_retcode := xxcok_common_pkg.put_message_f( 
                        FND_FILE.OUTPUT    -- 出力区分
                      , lv_out_msg         -- メッセージ
                      , 0                  -- 改行
                      );
        ov_errmsg  := NULL;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
        ov_retcode := cv_status_error;
    END;
--
  EXCEPTION
    -- *** 顧客移行情報ロック取得エラー ***
    WHEN lock_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_lock_err_msg
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
      ov_errbuf    := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode   := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf    := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode   := cv_status_error;
  END dlt_data_p;
--
  /**********************************************************************************
   * Procedure Name   : upd_unconfirmed_data_p
   * Description      : 未確定データ取消(A-3)
   ***********************************************************************************/
  PROCEDURE upd_unconfirmed_data_p(
    ov_errbuf  OUT VARCHAR2                                           -- エラー・メッセージ
  , ov_retcode OUT VARCHAR2                                           -- リターン・コード
  , ov_errmsg  OUT VARCHAR2                                           -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_unconfirmed_data_p'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;                           -- エラー・メッセージ
    lv_retcode VARCHAR2(1)    DEFAULT NULL;                           -- リターン・コード
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;                           -- ユーザー・エラー・メッセージ
    lv_out_msg VARCHAR2(100)  DEFAULT NULL;                           -- メッセージ出力変数
    lb_retcode BOOLEAN        DEFAULT NULL;                           -- メッセージ出力関数の戻り値
    --==============================================================
    --ロック取得用カーソル
    --==============================================================
    CURSOR l_upd_cur
    IS
      SELECT 'X'
      FROM   xxcok_cust_shift_info xcsi
      WHERE  xcsi.cust_shift_date <= gd_operation_date
-- 2011/02/07 Ver.1.3 [E_本稼動_02085] SCS M.Hirose UPD START
--      AND    xcsi.status           = cv_input_status
      AND    xcsi.status           IN( cv_input_status  -- 入力中
                                     , cv_wait_status   -- 確定前
                                   )
-- 2011/02/07 Ver.1.3 [E_本稼動_02085] SCS M.Hirose UPD END
      FOR UPDATE OF xcsi.cust_shift_id NOWAIT;
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    OPEN  l_upd_cur;
    CLOSE l_upd_cur;
    --=============================================================
    --顧客移行情報テーブルの更新処理
    --=============================================================
    BEGIN
--
      UPDATE xxcok_cust_shift_info          xcsi
      SET    xcsi.status                  = cv_cancel_status          -- ステータス(取消)
           , xcsi.last_updated_by         = cn_last_updated_by        -- ログインユーザーID
           , xcsi.last_update_date        = SYSDATE                   -- システム日付
           , xcsi.last_update_login       = cn_last_update_login      -- ログインID
           , xcsi.request_id              = cn_request_id             -- コンカレント要求ID
           , xcsi.program_application_id  = cn_program_application_id -- コンカレント・プログラム・アプリケーションID
           , xcsi.program_id              = cn_program_id             -- コンカレント・プログラムID
           , xcsi.program_update_date     = SYSDATE                   -- システム日付
      WHERE  xcsi.cust_shift_date        <= gd_operation_date
-- 2011/02/07 Ver.1.3 [E_本稼動_02085] SCS M.Hirose UPD START
--      AND    xcsi.status                  = cv_input_status;
      AND    xcsi.status                 IN( cv_input_status  -- 入力済
                                           , cv_wait_status   -- 確定前
                                         )
      ;
-- 2011/02/07 Ver.1.3 [E_本稼動_02085] SCS M.Hirose UPD END
--
    EXCEPTION
      -- *** 未確定データ取消処理エラー ***
      WHEN OTHERS THEN
        lv_out_msg   := xxccp_common_pkg.get_msg(
                          cv_appli_xxcok_name
                        , cv_upd_err_msg
                        );
        lb_retcode   := xxcok_common_pkg.put_message_f( 
                          FND_FILE.OUTPUT    -- 出力区分
                        , lv_out_msg         -- メッセージ
                        , 0                  -- 改行
                        );
        ov_errmsg    := NULL;
        ov_errbuf    := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
        ov_retcode   := cv_status_error;
    END;
--
  EXCEPTION
    -- *** 顧客移行情報ロック取得エラー ***
    WHEN lock_expt THEN
      lv_out_msg   := xxccp_common_pkg.get_msg(
                        cv_appli_xxcok_name
                      , cv_lock_err_msg
                      );
      lb_retcode   := xxcok_common_pkg.put_message_f( 
                        FND_FILE.OUTPUT    -- 出力区分
                      , lv_out_msg         -- メッセージ
                      , 0                  -- 改行
                      );
      ov_errmsg    := NULL;
      ov_errbuf    := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
      ov_retcode   := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf    := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode   := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf    := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode   := cv_status_error;
  END upd_unconfirmed_data_p;
--
  /**********************************************************************************
   * Procedure Name   : get_cust_shift_info_p
   * Description      : 連携対象顧客移行情報取得(A-4)
   ***********************************************************************************/
  PROCEDURE get_cust_shift_info_p(
    ov_errbuf  OUT VARCHAR2                                          -- エラー・メッセージ
  , ov_retcode OUT VARCHAR2                                          -- リターン・コード
  , ov_errmsg  OUT VARCHAR2                                          -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cust_shift_info_p'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;                          -- エラー・メッセージ
    lv_retcode VARCHAR2(1)    DEFAULT NULL;                          -- リターン・コード
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;                          -- ユーザー・エラー・メッセージ
    lv_out_msg VARCHAR2(100)  DEFAULT NULL;                          -- メッセージ出力変数
    lb_retcode BOOLEAN        DEFAULT NULL;                          -- メッセージ出力関数の戻り値
    -- ===============================
    -- ローカル例外
    -- ===============================
    target_data_expt EXCEPTION;                                      -- 対象件数無しエラー
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    OPEN  g_cust_cur;
    FETCH g_cust_cur BULK COLLECT INTO g_cust_tab;
    CLOSE g_cust_cur;
--
    --==============================================================
    --対象件数なしチェック
    --==============================================================
    IF( g_cust_tab.COUNT = 0 ) THEN
      RAISE target_data_expt;
    END IF;
--
  EXCEPTION
    -- *** 対象件数なしエラー ***
    WHEN target_data_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_target_count_err_msg
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
  END get_cust_shift_info_p;
--
  /**********************************************************************************
   * Procedure Name   : open_file_p
   * Description      : ファイルオープン(A-5)
   ***********************************************************************************/
  PROCEDURE open_file_p(
    ov_errbuf  OUT VARCHAR2                                -- エラー・メッセージ
  , ov_retcode OUT VARCHAR2                                -- リターン・コード
  , ov_errmsg  OUT VARCHAR2                                -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'open_file_p'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf      VARCHAR2(5000) DEFAULT NULL;            -- エラー・メッセージ
    lv_retcode     VARCHAR2(1)    DEFAULT NULL;            -- リターン・コード
    lv_errmsg      VARCHAR2(5000) DEFAULT NULL;            -- ユーザー・エラー・メッセージ
    lb_retcode     BOOLEAN        DEFAULT NULL;            -- メッセージ出力関数の戻り値
    lv_out_msg     VARCHAR2(100)  DEFAULT NULL;            -- メッセージ出力変数
    ln_file_length NUMBER         DEFAULT NULL;            -- ファイルの長さの変数
    ln_block_size  NUMBER         DEFAULT NULL;            -- ブロックサイズの変数
    lb_fexists     BOOLEAN        DEFAULT NULL;            -- BOOLEAN型
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    --=============================================================
    --ファイルの存在チェック
    --=============================================================
    UTL_FILE.FGETATTR(
      location    =>  gv_cust_dire_path
    , filename    =>  gv_cust_file_name
    , fexists     =>  lb_fexists
    , file_length =>  ln_file_length
    , block_size  =>  ln_block_size
    );
--
    IF( lb_fexists = TRUE ) THEN
      -- *** ファイル存在チェックエラー ***
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_file_err_msg
                    , cv_file_name_token
                    , gv_cust_file_name
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- 出力区分
                    , lv_out_msg         -- メッセージ
                    , 0                  -- 改行
                    );
      RAISE global_api_expt;
    END IF;
    --=============================================================
    --ファイルのオープン
    --=============================================================
    g_open_file := UTL_FILE.FOPEN(
                     gv_cust_dire_path
                   , gv_cust_file_name
                   , cv_open_mode
                   , cn_max_linesize
                   );
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg    := lv_errmsg;
      ov_errbuf    := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode   := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf    := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode   := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf    := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode   := cv_status_error;
  END open_file_p;
--
  /**********************************************************************************
   * Procedure Name   : create_flat_file_p
   * Description      : フラットファイル作成(A-6)
   ***********************************************************************************/
  PROCEDURE create_flat_file_p(
    ov_errbuf  OUT VARCHAR2                                       -- エラー・メッセージ
  , ov_retcode OUT VARCHAR2                                       -- リターン・コード
  , ov_errmsg  OUT VARCHAR2                                       -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_flat_file_p'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf            VARCHAR2(5000) DEFAULT NULL;             -- エラー・メッセージ
    lv_retcode           VARCHAR2(1)    DEFAULT NULL;             -- リターン・コード
    lv_errmsg            VARCHAR2(5000) DEFAULT NULL;             -- ユーザー・エラー・メッセージ
    lv_out_msg           VARCHAR2(100)  DEFAULT NULL;             -- メッセージ出力変数
    lb_retcode           BOOLEAN        DEFAULT NULL;             -- メッセージ出力関数の戻り値
    lv_flat              VARCHAR2(1500) DEFAULT NULL;             -- フラットファイル格納変数
    lv_cust_shift_id     VARCHAR2(100)  DEFAULT NULL;             -- 顧客移行情報IDの変数
    lv_cust_shift_date   VARCHAR2(100)  DEFAULT NULL;             -- 顧客移行日の変数
    lv_input_date        VARCHAR2(100)  DEFAULT NULL;             -- 入力日の変数
    lv_system_date       VARCHAR2(100)  DEFAULT NULL;             -- システム日付の変数
    lv_target_acctg_year VARCHAR2(100)  DEFAULT NULL;             -- 対象会計年度
--
  BEGIN
    ov_retcode := cv_status_normal;
--
    --==============================================================
    --対象件数カウント
    --==============================================================
    gn_target_cnt := g_cust_tab.COUNT;
    --===============================================================
    --ループ開始
    --===============================================================
    <<out_file_loop>>
    FOR i IN 1 .. g_cust_tab.COUNT LOOP
      lv_cust_shift_id     := TO_CHAR( g_cust_tab(i).cust_shift_id               );
      lv_cust_shift_date   := TO_CHAR( g_cust_tab(i).cust_shift_date, 'YYYYMMDD' );
      lv_input_date        := TO_CHAR( g_cust_tab(i).input_date, 'YYYYMMDD'      );
      lv_system_date       := TO_CHAR( gd_system_date, 'YYYYMMDDHH24MISS'        );
      lv_target_acctg_year := TO_CHAR( g_cust_tab(i).target_acctg_year           );
--
      lv_flat := (
        cv_msg_double || gv_comp_code                          || cv_msg_double || cv_msg_comma ||
        cv_msg_double || lv_cust_shift_id                      || cv_msg_double || cv_msg_comma ||
        cv_msg_double || g_cust_tab(i).cust_code               || cv_msg_double || cv_msg_comma ||
        cv_msg_double || g_cust_tab(i).prev_base_code          || cv_msg_double || cv_msg_comma ||
        cv_msg_double || g_cust_tab(i).new_base_code           || cv_msg_double || cv_msg_comma ||
        cv_msg_double || g_cust_tab(i).section_code            || cv_msg_double || cv_msg_comma ||
                         lv_cust_shift_date                    || cv_msg_comma  ||
                         lv_input_date                         || cv_msg_comma  ||
        cv_msg_double || g_cust_tab(i).emp_code                || cv_msg_double || cv_msg_comma ||
        cv_msg_double || lv_target_acctg_year                  || cv_msg_double || cv_msg_comma ||
        cv_msg_double || g_cust_tab(i).shift_section_type      || cv_msg_double || cv_msg_comma ||
        cv_msg_double || g_cust_tab(i).base_divide_status_code || cv_msg_double || cv_msg_comma ||
                         lv_system_date
      );
      --==============================================================
      --フラットファイルを作成
      --==============================================================
      UTL_FILE.PUT_LINE(
        file   => g_open_file
      , buffer => lv_flat
      );
--
      --==============================================================
      --成功件数カウント
      --==============================================================
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP out_file_loop;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf    := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode   := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf    := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode   := cv_status_error;
  END create_flat_file_p;
--
  /**********************************************************************************
   * Procedure Name   : close_file_p
   * Description      : ファイルクローズ(A-7)
   ***********************************************************************************/
  PROCEDURE close_file_p(
    ov_errbuf  OUT VARCHAR2                                 -- エラー・メッセージ
  , ov_retcode OUT VARCHAR2                                 -- リターン・コード
  , ov_errmsg  OUT VARCHAR2                                 -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'close_file_p'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode VARCHAR2(1)    DEFAULT NULL;                 -- リターン・コード
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_out_msg VARCHAR2(100)  DEFAULT NULL;                 -- メッセージ出力変数
    lb_retcode BOOLEAN        DEFAULT NULL;                 -- メッセージ出力関数の戻り値
--
  BEGIN
    ov_retcode := cv_status_normal;
    --==============================================================
    --オープン・ファイルをファイル・ハンドルが識別しているかテスト
    --==============================================================
    IF( UTL_FILE.IS_OPEN( g_open_file ) ) THEN
      --==============================================================
      --ファイルのクローズ
      --==============================================================
      UTL_FILE.FCLOSE(
        file => g_open_file
      );
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf    := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode   := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf    := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode   := cv_status_error;
  END close_file_p;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf  OUT VARCHAR2                            -- エラー・メッセージ
  , ov_retcode OUT VARCHAR2                            -- リターン・コード
  , ov_errmsg  OUT VARCHAR2                            -- ユーザー・エラー・メッセージ
  , iv_process_flag IN VARCHAR2                        -- 入力項目の起動区分パラメータ
  )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;            -- エラー・メッセージ
    lv_retcode VARCHAR2(1)    DEFAULT NULL;            -- リターン・コード
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;            -- ユーザー・エラー・メッセージ
    lv_out_msg VARCHAR2(100)  DEFAULT NULL;            -- メッセージ出力変数
    lb_retcode BOOLEAN        DEFAULT NULL;            -- メッセージ出力関数の戻り値
    -- ===============================
    -- ローカル例外
    -- ===============================
    file_close_expt EXCEPTION;
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    --==============================================================
    --グローバル変数の初期化
    --==============================================================
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    --===============================================================
    --initの呼び出し
    --===============================================================
    init(
      ov_errbuf  => lv_errbuf                          -- エラー・メッセージ
    , ov_retcode => lv_retcode                         -- リターン・コード
    , ov_errmsg  => lv_errmsg                          -- ユーザー・エラー・メッセージ
    , iv_process_flag => iv_process_flag               -- 入力項目の起動区分パラメータ
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==============================================================
    --パージ処理呼び出し
    --==============================================================
    dlt_data_p(
      ov_errbuf  => lv_errbuf                          -- エラー・メッセージ
    , ov_retcode => lv_retcode                         -- リターン・コード
    , ov_errmsg  => lv_errmsg                          -- ユーザー・エラー・メッセージ
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==============================================================
    --未確定データ取消呼び出し
    --==============================================================
    upd_unconfirmed_data_p(
      ov_errbuf  => lv_errbuf                          -- エラー・メッセージ
    , ov_retcode => lv_retcode                         -- リターン・コード
    , ov_errmsg  => lv_errmsg                          -- ユーザー・エラー・メッセージ
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --=============================================================
    --コミット
    --=============================================================
    COMMIT;
--
    gv_commit_flag := cv_commit_flag;
    --==============================================================
    --連携対象顧客移行情報取得の呼び出し
    --==============================================================
    get_cust_shift_info_p(
      ov_errbuf  => lv_errbuf                          -- エラー・メッセージ
    , ov_retcode => lv_retcode                         -- リターン・コード
    , ov_errmsg  => lv_errmsg                          -- ユーザー・エラー・メッセージ
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==============================================================
    --ファイルオープン呼び出し
    --==============================================================
    open_file_p(
      ov_errbuf  => lv_errbuf                          -- エラー・メッセージ
    , ov_retcode => lv_retcode                         -- リターン・コード
    , ov_errmsg  => lv_errmsg                          -- ユーザー・エラー・メッセージ
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==============================================================
    --フラットファイル作成の呼び出し
    --==============================================================
    create_flat_file_p(
      ov_errbuf  => lv_errbuf                          -- エラー・メッセージ
    , ov_retcode => lv_retcode                         -- リターン・コード
    , ov_errmsg  => lv_errmsg                          -- ユーザー・エラー・メッセージ
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==============================================================
    --ファイルクローズ呼び出し
    --==============================================================
    close_file_p(
      ov_errbuf  => lv_errbuf                          -- エラー・メッセージ
    , ov_retcode => lv_retcode                         -- リターン・コード
    , ov_errmsg  => lv_errmsg                          -- ユーザー・エラー・メッセージ
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE file_close_expt;
    END IF;
--
  EXCEPTION
    WHEN file_close_expt THEN
      ov_errmsg    := lv_errmsg;
      ov_errbuf    := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode   := cv_status_error;
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg    := lv_errmsg;
      ov_errbuf    := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode   := cv_status_error;
      close_file_p(
        ov_errbuf   => lv_errbuf                       -- エラー・メッセージ
      , ov_retcode  => lv_retcode                      -- リターン・コード
      , ov_errmsg   => lv_errmsg                       -- ユーザー・エラー・メッセージ
      );
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf    := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode   := cv_status_error;
      close_file_p(
        ov_errbuf   => lv_errbuf                       -- エラー・メッセージ
      , ov_retcode  => lv_retcode                      -- リターン・コード
      , ov_errmsg   => lv_errmsg                       -- ユーザー・エラー・メッセージ
      );
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf    := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode   := cv_status_error;
      close_file_p(
        ov_errbuf   => lv_errbuf                       -- エラー・メッセージ
      , ov_retcode  => lv_retcode                      -- リターン・コード
      , ov_errmsg   => lv_errmsg                       -- ユーザー・エラー・メッセージ
      );
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
  PROCEDURE main(
    errbuf  OUT VARCHAR2                                              -- エラー・メッセージ
  , retcode OUT VARCHAR2                                              -- リターン・コード
  , iv_process_flag IN VARCHAR2                                       -- 入力項目の起動区分パラメータ
  )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'main';             -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;                      -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)    DEFAULT NULL;                      -- リターン・コード
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;                      -- ユーザー・エラー・メッセージ
    lb_retcode      BOOLEAN        DEFAULT NULL;                      -- メッセージ出力関数の戻り値
    lv_out_msg      VARCHAR2(100)  DEFAULT NULL;                      -- メッセージ変数
    lv_message_code VARCHAR2(100)  DEFAULT NULL;                      -- メッセージコード
    lv_commit_code  VARCHAR2(100)  DEFAULT NULL;                      -- コミットメッセージコード
  BEGIN
    --==============================================================
    --コンカレントヘッダメッセージ出力関数の呼び出し
    --==============================================================
    xxccp_common_pkg.put_log_header(
      ov_retcode => lv_retcode
    , ov_errbuf  => lv_errbuf
    , ov_errmsg  => lv_errmsg
    );
--
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- 出力区分
                  , NULL               -- メッセージ
                  , 1                  -- 改行
                  );
--
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    --==============================================================
    --submainの呼び出し（実際の処理はsubmainで行う）
    --==============================================================
    submain(
      ov_errbuf  => lv_errbuf                               -- エラー・メッセージ
    , ov_retcode => lv_retcode                              -- リターン・コード
    , ov_errmsg  => lv_errmsg                               -- ユーザー・エラー・メッセージ
    , iv_process_flag => iv_process_flag                    -- 入力項目の起動区分パラメータ
    );
    --==============================================================
    --エラー出力
    --==============================================================
    IF ( lv_retcode = cv_status_error ) THEN
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
    --==============================================================
    --対象件数出力
    --==============================================================
    IF( lv_retcode = cv_status_error ) THEN
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
--
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_xxccp_name
                  , cv_target_count_msg
                  , cv_count_token
                  , TO_CHAR( gn_target_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- 出力区分
                  , lv_out_msg         -- メッセージ
                  , 0                  -- 改行
                  );
    --==============================================================
    --成功件数出力
    --==============================================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_xxccp_name
                  , cv_normal_count_msg
                  , cv_count_token
                  , TO_CHAR( gn_normal_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- 出力区分
                  , lv_out_msg         -- メッセージ
                  , 0                  -- 改行
                  );
    --==============================================================
    --エラー件数出力
    --==============================================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_xxccp_name
                  , cv_err_count_msg
                  , cv_count_token
                  , TO_CHAR( gn_error_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- 出力区分
                  , lv_out_msg         -- メッセージ
                  , 0                  -- 改行
                  );
    --==============================================================
    --終了メッセージ
    --==============================================================
    IF( lv_retcode     = cv_status_normal ) THEN
      lv_message_code  := cv_normal_msg;
      retcode          := cv_status_normal;
      lv_out_msg       := xxccp_common_pkg.get_msg(
                            cv_appli_xxccp_name
                          , lv_message_code
                          );
    ELSIF( ( lv_retcode  = cv_status_error )
      AND ( gv_commit_flag = cv_commit_flag ) ) THEN
        lv_commit_code   := cv_commit_msg;
        retcode          := cv_status_error;
        lv_out_msg       := xxccp_common_pkg.get_msg(
                              cv_appli_xxcok_name
                            , lv_commit_code
                            );
    ELSIF( lv_retcode  = cv_status_error ) THEN
      lv_message_code  := cv_err_msg;
      retcode          := cv_status_error;
      lv_out_msg       := xxccp_common_pkg.get_msg(
                            cv_appli_xxccp_name
                          , lv_message_code
                          );
    END IF;
--
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
END XXCOK001A03C;
/