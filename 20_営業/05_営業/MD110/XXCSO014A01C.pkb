CREATE OR REPLACE PACKAGE BODY APPS.XXCSO014A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO014A01C(body)
 * Description      : 月別売上計画データを顧客別売上計画テーブルへ登録または更新します。
 *                    
 * MD.050           : MD050_CSO_014_A01_HHT-EBSインターフェース：(IN）売上計画
 *                    
 * Version          : 1.1
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  init                        初期処理 (A-1)
 *  chk_mst_is_exists           マスタ存在チェック (A-3)
 *  chk_is_new_recode           最新レコードチェック (A-4)
 *  chk_sales_plan_day          日別計画連携チェック (A-5) 
 *  upd_sales_plan_month        顧客別売上計画データの登録または更新 (A-6)
 *  upd_sales_plan_day          日別売上計画データの登録または更新 (A-7) 
 *  submain                     メイン処理プロシージャ
 *                                売上計画情報抽出 (A-2)
 *                                セーブポイント設定 (A-8)
 *  main                        コンカレント実行ファイル登録プロシージャ
 *                                終了処理(A-9)
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-11-11    1.0   Kenji.Sai        新規作成
 *  2009-02-19    1.1   Kenji.Sai        レビュー後対応 
 *  2009-03-17    1.1   K.Boku           【結合障害067】upd_sales_plan_dayで、日(項目)に先頭０埋め対応
 *  2009-05-01    1.2   Tomoko.Mori      T1_0897対応
 *  2009-12-07    1.3   T.Maruyama       E_本稼動_00028
 *
 *****************************************************************************************/
-- 
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- 異常:2
--
  --WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         -- CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    -- PROGRAM_UPDATE_DATE
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- エラー件数
  gn_skip_cnt      NUMBER;                    -- スキップ件数
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
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO014A01C';      -- パッケージ名
  cv_app_name            CONSTANT VARCHAR2(5)   := 'XXCSO';             -- アプリケーション短縮名
--
  cv_active_status       CONSTANT VARCHAR2(1)   := 'A';                 -- アクティブ
  cv_dumm_day_month      CONSTANT VARCHAR2(2)   := '99';                -- 月別場合の日にち（99）
  cv_monday_kbn_month    CONSTANT VARCHAR2(1)   := '1';                 -- 月日区分（月別：1）
  cv_monday_kbn_day      CONSTANT VARCHAR2(1)   := '2';                 -- 月日区分（日別：2）
  cv_upd_kbn_sales_month CONSTANT VARCHAR2(1)   := '6';  -- HHT連携更新機能区分（売上計画：6）  
  cv_upd_kbn_sales_day   CONSTANT VARCHAR2(1)   := '7';  -- HHT連携更新機能区分（売上計画日別：7）    
  cv_houmon_kbn_taget    CONSTANT VARCHAR2(1)   := '1';  -- 訪問対象区分（訪問対象：1） 
--
  -- メッセージコード
  cv_tkn_number_01       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00066';  -- データ抽出エラー
  cv_tkn_number_02       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00067';  -- 顧客コードなし警告
  cv_tkn_number_03       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00068';  -- 売上拠点コードなし警告
  cv_tkn_number_04       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00069';  -- データ追加エラー
  cv_tkn_number_05       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00070';  -- データ更新エラー
  cv_tkn_number_06       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011';  -- 業務処理日付取得エラー 
  cv_tkn_number_07       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00149';  -- 年度取得エラー
--
  -- トークンコード
  cv_tkn_errmsg          CONSTANT VARCHAR2(20) := 'ERR_MESSAGE';
  cv_tkn_tbl             CONSTANT VARCHAR2(20) := 'TABLE';  
  cv_tkn_sequence        CONSTANT VARCHAR2(20) := 'SEQUENCE';
  cv_tkn_cstm_cd         CONSTANT VARCHAR2(20) := 'CUSTOMERCODE';
  cv_tkn_cstm_nm         CONSTANT VARCHAR2(20) := 'CUSTOMERNAME';
  cv_tkn_loc_cd          CONSTANT VARCHAR2(20) := 'LOCATIONCODE';
  cv_tkn_loc_nm          CONSTANT VARCHAR2(20) := 'LOCATIONNAME';
  cv_tkn_ym              CONSTANT VARCHAR2(20) := 'YEARMONTH';
  cv_tkn_mnt             CONSTANT VARCHAR2(20) := 'MOUNT';
--
  cb_true                CONSTANT BOOLEAN := TRUE;
  cb_false               CONSTANT BOOLEAN := FALSE;
--
  -- DEBUG_LOG用メッセージ
  cv_debug_msg1           CONSTANT VARCHAR2(200) := '<<業務処理日付取得処理>>';
  cv_debug_msg2           CONSTANT VARCHAR2(200) := 'gd_process_date = ';
  cv_debug_msg3           CONSTANT VARCHAR2(200) := '<<スキップ処理されたデータ>>';
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  gd_process_date        DATE;                                                 -- 業務処理日
  gt_business_year       xxcso_account_sales_plans.fiscal_year%TYPE;           -- 年度
  -- ファイル・ハンドルの宣言
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 取得情報格納レコード型定義
--
  -- 月別売上計画ワークテーブル＆関連情報抽出データ
  TYPE g_get_sales_plan_month_rtype IS RECORD(
    no_seq              xxcso_in_sales_plan_month.no_seq%TYPE,                -- シーケンス番号
    account_number      xxcso_in_sales_plan_month.account_number%TYPE,        -- 顧客コード
    sales_base_code     xxcso_in_sales_plan_month.sales_base_code%TYPE,       -- 売上拠点コード
    sales_plan_month    xxcso_in_sales_plan_month.sales_plan_month%TYPE,      -- 売上計画年月
    sales_plan_amt      xxcso_in_sales_plan_month.sales_plan_amt%TYPE,        -- 売上計画金額
    party_id            xxcso_cust_accounts_v.party_id%TYPE,                  -- パーティID
    vist_target_div     xxcso_cust_accounts_v.vist_target_div%TYPE,           -- 訪問対象区分
    account_name        xxcso_cust_accounts_v.account_name%TYPE,              -- 顧客名称
    sales_base_name     xxcso_aff_base_v2.base_name%TYPE                      -- 売上拠点名称
  );
  -- テーブル型定義
  TYPE sales_plan_day_on_month_ttype IS TABLE OF xxcso_in_sales_plan_month.sales_plan_amt%TYPE INDEX BY PLS_INTEGER;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理 (A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf           OUT NOCOPY VARCHAR2,  -- エラー・メッセージ            --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,  -- リターン・コード              --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'init';     -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_app_name2           CONSTANT VARCHAR2(10)     := 'XXCCP';             -- アドオン：共通・IF領域
    cv_no_para_msg         CONSTANT VARCHAR2(100)    := 'APP-XXCCP1-90008';  -- コンカレント入力パラメータなし
    -- *** ローカル変数 ***
    lv_noprm_msg    VARCHAR2(5000);  -- コンカレント入力パラメータなしメッセージ格納用
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- =======================================
    -- 入力パラメータなしメッセージ出力 
    -- =======================================
    lv_noprm_msg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name2,             -- アプリケーション短縮名
                        iv_name         => cv_no_para_msg            -- メッセージコード
                      );
    -- メッセージ出力
    fnd_file.put_line(
      which  => FND_FILE.OUTPUT,
      buff   => ''           || CHR(10) ||     -- 空行の挿入
                lv_noprm_msg || CHR(10) ||
                 ''                            -- 空行の挿入
    );
--
    -- =====================
    -- 業務処理日付取得処理 
    -- =====================
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    -- *** DEBUG_LOG ***
    -- 取得した業務処理日付をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg1 || CHR(10) ||
                 cv_debug_msg2 || TO_CHAR(gd_process_date,'yyyy/mm/dd hh24:mi:ss') || CHR(10) ||
                 ''
    );
--
    -- 業務処理日付取得に失敗した場合
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  -- アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_06             -- メッセージコード
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
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
   * Procedure Name   : chk_mst_is_exists                                  
   * Description      : マスタ存在チェック (A-3)
   ***********************************************************************************/
  PROCEDURE chk_mst_is_exists(
    io_sales_plan_month_rec IN OUT NOCOPY g_get_sales_plan_month_rtype,  
-- 月別売上計画ワークテーブル＆関連情報抽出データ
    ov_errbuf               OUT NOCOPY VARCHAR2,        -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,        -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'chk_mst_is_exists';     -- プログラム名
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
    cv_table_name_xcav   CONSTANT VARCHAR2(100) := 'xxcso_cust_accounts_v';    -- 顧客マスタビュー名
    cv_table_name_xabv   CONSTANT VARCHAR2(100) := 'xxcso_aff_base_v';         -- AFF部門マスタビュー
    -- *** ローカル変数 ***
    lt_account_number      xxcso_cust_accounts_v.account_number%TYPE;          -- 顧客コード
    lt_party_id            xxcso_cust_accounts_v.party_id%TYPE;                -- パーティID
    lt_vist_target_div     xxcso_cust_accounts_v.vist_target_div%TYPE;         -- 訪問対象区分
    lt_account_name        xxcso_cust_accounts_v.account_name%TYPE;            -- 顧客名称
    lt_sales_base_name     xxcso_aff_base_v2.base_name%TYPE;                   -- 売上拠点名称   
--
    -- *** ローカル・レコード ***
    l_sales_plan_month_rec  g_get_sales_plan_month_rtype; 
-- INパラメータ.月別売上計画ワークテーブルデータ格納
    --*** ローカル・例外 ***
    warning_expt       EXCEPTION;
-- 
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
    -- INパラメータをレコード変数に代入
    l_sales_plan_month_rec := io_sales_plan_month_rec;
--
    -- ===========================
    -- 顧客マスタ存在チェック 
    -- ===========================
    BEGIN
--
      -- 顧客マスタビューから顧客コード、パーティID、訪問対象区分、顧客名称を抽出する
      SELECT xcav.account_number account_number,       -- 顧客コード
             xcav.party_id party_id,                   -- パーティID
             xcav.vist_target_div vist_target_div,     -- 訪問対象区分
             xcav.account_name account_name            -- 顧客名称
      INTO   lt_account_number,                        -- 顧客コード
             lt_party_id,                              -- パーティID
             lt_vist_target_div,                       -- 訪問対象区分
             lt_account_name                           -- 顧客名称
      FROM   xxcso_cust_accounts_v xcav                -- 顧客マスタビュー
      WHERE  xcav.account_number = io_sales_plan_month_rec.account_number  -- 顧客コード
        AND  xcav.account_status = cv_active_status                        -- 顧客ステータス（A)
        AND  xcav.party_status   = cv_active_status;                       -- パーティステータス（A)
--
      -- 取得した顧客マスタデータをOUTパラメータに設定
      io_sales_plan_month_rec.party_id          := lt_party_id;                -- パーティID
      io_sales_plan_month_rec.vist_target_div   := lt_vist_target_div;         -- 訪問対象区分
      io_sales_plan_month_rec.account_name      := lt_account_name;            -- 顧客名称
--
    EXCEPTION
      -- *** 該当データが存在しない例外ハンドラ ***
      WHEN NO_DATA_FOUND THEN
      -- エラーメッセージ作成
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                              -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_02                         -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl                               -- トークンコード1
                       ,iv_token_value1 => cv_table_name_xcav                       -- エラー発生のテーブル名
                       ,iv_token_name2  => cv_tkn_sequence                          -- トークンコード2
                       ,iv_token_value2 => io_sales_plan_month_rec.no_seq           -- シーケンス番号
                       ,iv_token_name3  => cv_tkn_cstm_cd                           -- トークンコード3
                       ,iv_token_value3 => io_sales_plan_month_rec.account_number   -- 顧客コード
                       ,iv_token_name4  => cv_tkn_cstm_nm                           -- トークンコード4
                       ,iv_token_value4 => io_sales_plan_month_rec.account_name     -- 顧客名称
                       ,iv_token_name5  => cv_tkn_loc_cd                            -- トークンコード5
                       ,iv_token_value5 => io_sales_plan_month_rec.sales_base_code  -- 売上拠点コード
                       ,iv_token_name6  => cv_tkn_loc_nm                            -- トークンコード6
                       ,iv_token_value6 => io_sales_plan_month_rec.sales_base_name  -- 売上拠点名称
                       ,iv_token_name7  => cv_tkn_ym                                -- トークンコード7
                       ,iv_token_value7 => io_sales_plan_month_rec.sales_plan_month -- 売上計画年月
                       ,iv_token_name8  => cv_tkn_mnt                               -- トークンコード8
                       ,iv_token_value8 => io_sales_plan_month_rec.sales_plan_amt   -- 売上計画金額
                      );
        lv_errbuf  := lv_errmsg||SQLERRM;
        RAISE warning_expt;
      -- *** OTHERS例外ハンドラ ***
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                              -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_01                         -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl                               -- トークンコード1
                       ,iv_token_value1 => cv_table_name_xcav                       -- エラー発生のテーブル名
                       ,iv_token_name2  => cv_tkn_sequence                          -- トークンコード2
                       ,iv_token_value2 => io_sales_plan_month_rec.no_seq           -- シーケンス番号
                       ,iv_token_name3  => cv_tkn_cstm_cd                           -- トークンコード3
                       ,iv_token_value3 => io_sales_plan_month_rec.account_number   -- 顧客コード
                       ,iv_token_name4  => cv_tkn_cstm_nm                           -- トークンコード4
                       ,iv_token_value4 => io_sales_plan_month_rec.account_name     -- 顧客名称
                       ,iv_token_name5  => cv_tkn_loc_cd                            -- トークンコード5
                       ,iv_token_value5 => io_sales_plan_month_rec.sales_base_code  -- 売上拠点コード
                       ,iv_token_name6  => cv_tkn_loc_nm                            -- トークンコード6
                       ,iv_token_value6 => io_sales_plan_month_rec.sales_base_name  -- 売上拠点名称
                       ,iv_token_name7  => cv_tkn_ym                                -- トークンコード7
                       ,iv_token_value7 => io_sales_plan_month_rec.sales_plan_month -- 売上計画年月
                       ,iv_token_name8  => cv_tkn_mnt                               -- トークンコード8
                       ,iv_token_value8 => io_sales_plan_month_rec.sales_plan_amt   -- 売上計画金額
                      );
        lv_errbuf  := lv_errmsg||SQLERRM;
        RAISE warning_expt;
    END;
--
    -- ===========================
    -- AFF部門マスタ存在チェック
    -- ===========================  
    BEGIN    
      -- AFF部門マスタビューから売上拠点名称を抽出する
      SELECT xabv.base_name base_name       -- 売上拠点名称
      INTO   lt_sales_base_name             -- 売上拠点名称
      FROM   xxcso_aff_base_v xabv          -- AFF部門マスタビュー
      WHERE  xabv.base_code = io_sales_plan_month_rec.sales_base_code                     -- 売上拠点コード
        AND  gd_process_date BETWEEN TRUNC(NVL(xabv.start_date_active, gd_process_date))  -- 有効期間範囲
               AND TRUNC(NVL(xabv.end_date_active, gd_process_date));                     
--
      -- 取得した売上拠点名称をOUTパラメータに設定
      io_sales_plan_month_rec.sales_base_name := lt_sales_base_name;           -- 売上拠点名称
--
    EXCEPTION
      -- *** 該当データが存在しない例外ハンドラ ***
      WHEN NO_DATA_FOUND THEN
        -- エラーメッセージ作成
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                              -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_03                         -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl                               -- トークンコード1
                       ,iv_token_value1 => cv_table_name_xabv                       -- エラー発生のテーブル名
                       ,iv_token_name2  => cv_tkn_sequence                          -- トークンコード2
                       ,iv_token_value2 => io_sales_plan_month_rec.no_seq           -- シーケンス番号
                       ,iv_token_name3  => cv_tkn_cstm_cd                           -- トークンコード3
                       ,iv_token_value3 => io_sales_plan_month_rec.account_number   -- 顧客コード
                       ,iv_token_name4  => cv_tkn_cstm_nm                           -- トークンコード4
                       ,iv_token_value4 => io_sales_plan_month_rec.account_name     -- 顧客名称
                       ,iv_token_name5  => cv_tkn_loc_cd                            -- トークンコード5
                       ,iv_token_value5 => io_sales_plan_month_rec.sales_base_code  -- 売上拠点コード
                       ,iv_token_name6  => cv_tkn_loc_nm                            -- トークンコード6
                       ,iv_token_value6 => io_sales_plan_month_rec.sales_base_name  -- 売上拠点名称
                       ,iv_token_name7  => cv_tkn_ym                                -- トークンコード7
                       ,iv_token_value7 => io_sales_plan_month_rec.sales_plan_month -- 売上計画年月
                       ,iv_token_name8  => cv_tkn_mnt                               -- トークンコード8
                       ,iv_token_value8 => io_sales_plan_month_rec.sales_plan_amt   -- 売上計画金額
                      );
        lv_errbuf  := lv_errmsg||SQLERRM;
        RAISE warning_expt;
      -- *** OTHERS例外ハンドラ ***
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                              -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_01                         -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl                               -- トークンコード1
                       ,iv_token_value1 => cv_table_name_xabv                       -- エラー発生のテーブル名
                       ,iv_token_name2  => cv_tkn_sequence                          -- トークンコード2
                       ,iv_token_value2 => io_sales_plan_month_rec.no_seq           -- シーケンス番号
                       ,iv_token_name3  => cv_tkn_cstm_cd                           -- トークンコード3
                       ,iv_token_value3 => io_sales_plan_month_rec.account_number   -- 顧客コード
                       ,iv_token_name4  => cv_tkn_cstm_nm                           -- トークンコード4
                       ,iv_token_value4 => io_sales_plan_month_rec.account_name     -- 顧客名称
                       ,iv_token_name5  => cv_tkn_loc_cd                            -- トークンコード5
                       ,iv_token_value5 => io_sales_plan_month_rec.sales_base_code  -- 売上拠点コード
                       ,iv_token_name6  => cv_tkn_loc_nm                            -- トークンコード6
                       ,iv_token_value6 => io_sales_plan_month_rec.sales_base_name  -- 売上拠点名称
                       ,iv_token_name7  => cv_tkn_ym                                -- トークンコード7
                       ,iv_token_value7 => io_sales_plan_month_rec.sales_plan_month -- 売上計画年月
                       ,iv_token_name8  => cv_tkn_mnt                               -- トークンコード8
                       ,iv_token_value8 => io_sales_plan_month_rec.sales_plan_amt   -- 売上計画金額
                      );
        lv_errbuf  := lv_errmsg||SQLERRM;
        RAISE warning_expt;
    END;    
--    
  EXCEPTION
--
    -- *** 該当データが存在しないかデータ抽出エラー発生時の例外ハンドラ ***
    WHEN warning_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      -- ステータスは警告
      ov_retcode := cv_status_warn;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END chk_mst_is_exists;
--
  /**********************************************************************************
   * Procedure Name   : chk_is_new_recode                                             
   * Description      : 最新レコードチェック (A-4)
   ***********************************************************************************/
  PROCEDURE chk_is_new_recode(
    io_sales_plan_month_rec IN OUT NOCOPY g_get_sales_plan_month_rtype, -- 月別売上計画ワークテーブルデータ
    ob_not_exists_new_data  OUT BOOLEAN,                                -- 最新レコードチェックフラグ
    ov_errbuf               OUT NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2          -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'chk_is_new_recode';     -- プログラム名
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
    -- *** ローカル・定数 ***
    cv_table_name       CONSTANT VARCHAR2(100)  := 'xxcso_in_sales_plan_month';   -- 月別売上計画ワークテーブル
    -- *** ローカル・変数 ***
    lt_max_no_seq          xxcso_in_sales_plan_month.no_seq%TYPE;  -- 最大シーケンス番号
    lv_table_name          VARCHAR2(200);                          -- テーブル名
    lb_not_exists_new_data BOOLEAN;                                -- 最新レコード存在チェックフラグ
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル・例外 ***
    select_error_expt EXCEPTION;
--    
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
    --当該レコードより最新レコードが存在するかを判断するチェックフラグの初期化
    lb_not_exists_new_data := cb_true;                             -- 最新レコードが存在しない
--
    -- ================================================================
    -- 月別売上計画ワークテーブルから該当最大シーケンス番号を取得 
    -- ================================================================
    BEGIN
      SELECT  MAX(xispm.no_seq) max_no_seq         -- 最大シーケンス番号
      INTO    lt_max_no_seq                        -- 最大シーケンス番号
      FROM    xxcso_in_sales_plan_month  xispm     -- 月別売上計画ワークテーブル
      WHERE   xispm.account_number   = io_sales_plan_month_rec.account_number     -- 顧客コード
        AND   xispm.sales_base_code  = io_sales_plan_month_rec.sales_base_code    -- 売上拠点コード
        AND   xispm.sales_plan_month = io_sales_plan_month_rec.sales_plan_month;  -- 売上計画年月
      -- 当該レコードのシーケンス番号が最大シーケンス番号より、大きい場合、スキップする
      -- 当該レコードのシーケンス番号が最大シーケンス番号と同じ場合、正常
      IF (lt_max_no_seq > io_sales_plan_month_rec.no_seq) THEN
        lb_not_exists_new_data := cb_false;                        -- 最新レコードが存在する
      END IF;
      -- 取得した最新レコードチェック結果をOUTパラメータに設定
      ob_not_exists_new_data := lb_not_exists_new_data;
--
    EXCEPTION
      -- *** OTHERS例外ハンドラ ***
      WHEN OTHERS THEN
        -- エラーメッセージ作成
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name              -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_01         -- メッセージコード データ抽出エラー
                       ,iv_token_name1  => cv_tkn_tbl                                -- トークンコード1
                       ,iv_token_value1 => cv_table_name                             -- エラー発生のテーブル名
                       ,iv_token_name2  => cv_tkn_errmsg                             -- トークンコード2
                       ,iv_token_value2 => SQLERRM                                   -- ORACLEエラー
                       ,iv_token_name3  => cv_tkn_sequence                           -- トークンコード3
                       ,iv_token_value3 => io_sales_plan_month_rec.no_seq            -- シーケンス番号
                       ,iv_token_name4  => cv_tkn_cstm_cd                            -- トークンコード4
                       ,iv_token_value4 => io_sales_plan_month_rec.account_number    -- 顧客コード
                       ,iv_token_name5  => cv_tkn_cstm_nm                            -- トークンコード5
                       ,iv_token_value5 => io_sales_plan_month_rec.account_name      -- 顧客名称
                       ,iv_token_name6  => cv_tkn_loc_cd                             -- トークンコード6
                       ,iv_token_value6 => io_sales_plan_month_rec.sales_base_code   -- 売上拠点コード
                       ,iv_token_name7  => cv_tkn_loc_nm                             -- トークンコード7
                       ,iv_token_value7 => io_sales_plan_month_rec.sales_base_name   -- 売上拠点名称
                       ,iv_token_name8  => cv_tkn_ym                                 -- トークンコード8
                       ,iv_token_value8 => io_sales_plan_month_rec.sales_plan_month  -- 売上計画年月
                       ,iv_token_name9  => cv_tkn_mnt                                -- トークンコード9
                       ,iv_token_value9 => io_sales_plan_month_rec.sales_plan_amt    -- 売上計画金額
                      );
          lv_errbuf  := lv_errmsg||SQLERRM;
          RAISE select_error_expt;
    END;
--
  EXCEPTION
    -- *** データ抽出時の例外ハンドラ ***
    WHEN select_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END chk_is_new_recode;
--
  /**********************************************************************************
   * Procedure Name   : chk_sales_plan_day                                                       
   * Description      : 日別計画連携チェック (A-5)
   ***********************************************************************************/
  PROCEDURE chk_sales_plan_day(
    io_sales_plan_month_rec IN OUT NOCOPY g_get_sales_plan_month_rtype,  -- 月別売上計画ワークテーブルデータ
    on_sales_plan_cnt       OUT NUMBER,                 -- 日別売上計画連携チェック用のデータ件数
    ov_errbuf               OUT NOCOPY VARCHAR2,        -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,        -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'chk_sales_plan_day';     -- プログラム名
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
    cv_table_name       CONSTANT VARCHAR2(100) := 'xxcso_in_sales_plan_day';   -- 日別売上計画ワークテーブル
    -- *** ローカル変数 ***
    ln_sales_plan_cnt      NUMBER;                              -- 日別売上計画連携チェック用のデータ件数    
--
    -- *** ローカル・レコード ***
--    
    -- *** ローカル・例外 ***
    select_error_expt EXCEPTION;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ========================================================
    -- 日別売上計画ワークテーブルから該当データ件数を取得 
    -- ========================================================
    BEGIN
      SELECT  COUNT(xispd.no_seq) sales_plan_cnt    -- 日別売上計画該当データ件数
      INTO    ln_sales_plan_cnt                     -- 日別売上計画該当データ件数
      FROM    xxcso_in_sales_plan_day  xispd        -- 日別売上計画ワークテーブル
      WHERE   xispd.account_number = io_sales_plan_month_rec.account_number           -- 顧客コード
        AND   xispd.sales_base_code = io_sales_plan_month_rec.sales_base_code         -- 売上拠点コード
        AND   xispd.sales_plan_day LIKE io_sales_plan_month_rec.sales_plan_month||'%' -- 売上計画年月日
        AND   ROWNUM = 1;                                                             -- 最初の1件
      -- 取得した日別売上計画ワークテーブルの該当データ件数をOUTパラメータに設定
      on_sales_plan_cnt      := ln_sales_plan_cnt;                    
--
    EXCEPTION
      WHEN OTHERS THEN
        -- エラーメッセージ作成
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name              -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_01         -- メッセージコード データ抽出エラー
                       ,iv_token_name1  => cv_tkn_tbl                                -- トークンコード1
                       ,iv_token_value1 => cv_table_name                             -- エラー発生のテーブル名
                       ,iv_token_name2  => cv_tkn_errmsg                             -- トークンコード2
                       ,iv_token_value2 => SQLERRM                                   -- ORACLEエラー
                       ,iv_token_name3  => cv_tkn_sequence                           -- トークンコード3
                       ,iv_token_value3 => io_sales_plan_month_rec.no_seq            -- シーケンス番号
                       ,iv_token_name4  => cv_tkn_cstm_cd                            -- トークンコード4
                       ,iv_token_value4 => io_sales_plan_month_rec.account_number    -- 顧客コード
                       ,iv_token_name5  => cv_tkn_cstm_nm                            -- トークンコード5
                       ,iv_token_value5 => io_sales_plan_month_rec.account_name      -- 顧客名称
                       ,iv_token_name6  => cv_tkn_loc_cd                             -- トークンコード6
                       ,iv_token_value6 => io_sales_plan_month_rec.sales_base_code   -- 売上拠点コード
                       ,iv_token_name7  => cv_tkn_loc_nm                             -- トークンコード7
                       ,iv_token_value7 => io_sales_plan_month_rec.sales_base_name   -- 売上拠点名称
                       ,iv_token_name8  => cv_tkn_ym                                 -- トークンコード8
                       ,iv_token_value8 => io_sales_plan_month_rec.sales_plan_month  -- 売上計画年月
                       ,iv_token_name9  => cv_tkn_mnt                                -- トークンコード9
                       ,iv_token_value9 => io_sales_plan_month_rec.sales_plan_amt    -- 売上計画金額
                      );
        lv_errbuf  := lv_errmsg||SQLERRM;
        RAISE select_error_expt;
    END;
--
  EXCEPTION
    -- *** データ抽出時の例外ハンドラ ***
    WHEN select_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END chk_sales_plan_day;
--
  /**********************************************************************************
   * Procedure Name   : upd_sales_plan_month                                                               
   * Description      : 顧客別売上計画データの登録または更新 (A-6)
   ***********************************************************************************/
  PROCEDURE upd_sales_plan_month(
    io_sales_plan_month_rec  IN OUT NOCOPY g_get_sales_plan_month_rtype,   -- 月別売上計画ワークテーブルデータ
    ov_errbuf                OUT NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2          -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'upd_sales_plan_month';     -- プログラム名
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
    -- 顧客別売上計画テーブル名をローカル変数に代入
    cv_table_name          CONSTANT VARCHAR2(100) := 'xxcso_account_sales_plans';  -- 顧客別売上計画テーブル
    -- *** ローカル変数 ***
    ln_data_cnt            NUMBER;              -- 顧客別売上計画テーブルの月別売上計画データ件数    
    lv_msg_code            VARCHAR2(100);                                          -- メッセージコード
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル・例外 ***
    select_error_expt EXCEPTION;
    ins_upd_expt      EXCEPTION;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ======================================================
    -- 顧客別売上計画テーブルから該当データ件数を取得
    -- ======================================================
    BEGIN
      SELECT COUNT(xasp.account_sales_plan_id) data_cnt   -- 顧客売上計画の該当データ件数
      INTO   ln_data_cnt                                  -- 顧客売上計画の該当データ件数
      FROM   xxcso_account_sales_plans xasp               -- 顧客別売上計画テーブル
      WHERE  xasp.account_number = io_sales_plan_month_rec.account_number    -- 顧客コード
        AND  xasp.base_code      = io_sales_plan_month_rec.sales_base_code   -- 売上拠点コード
        AND  xasp.year_month     = io_sales_plan_month_rec.sales_plan_month  -- 年月
        AND  xasp.plan_day       = cv_dumm_day_month                         -- 日(99)
        AND  xasp.month_date_div = cv_monday_kbn_month;                      -- 月日区分(1)
--
    EXCEPTION
      -- *** OTHERS例外ハンドラ ***
      WHEN OTHERS THEN
        -- エラーメッセージ作成
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name              -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_01         -- メッセージコード データ抽出エラー
                       ,iv_token_name1  => cv_tkn_tbl                                -- トークンコード1
                       ,iv_token_value1 => cv_table_name                             -- エラー発生のテーブル名
                       ,iv_token_name2  => cv_tkn_errmsg                             -- トークンコード2
                       ,iv_token_value2 => SQLERRM                                   -- ORACLEエラー
                       ,iv_token_name3  => cv_tkn_sequence                           -- トークンコード3
                       ,iv_token_value3 => io_sales_plan_month_rec.no_seq            -- シーケンス番号
                       ,iv_token_name4  => cv_tkn_cstm_cd                            -- トークンコード4
                       ,iv_token_value4 => io_sales_plan_month_rec.account_number    -- 顧客コード
                       ,iv_token_name5  => cv_tkn_cstm_nm                            -- トークンコード5
                       ,iv_token_value5 => io_sales_plan_month_rec.account_name      -- 顧客名称
                       ,iv_token_name6  => cv_tkn_loc_cd                             -- トークンコード6
                       ,iv_token_value6 => io_sales_plan_month_rec.sales_base_code   -- 売上拠点コード
                       ,iv_token_name7  => cv_tkn_loc_nm                             -- トークンコード7
                       ,iv_token_value7 => io_sales_plan_month_rec.sales_base_name   -- 売上拠点名称
                       ,iv_token_name8  => cv_tkn_ym                                 -- トークンコード8
                       ,iv_token_value8 => io_sales_plan_month_rec.sales_plan_month  -- 売上計画年月
                       ,iv_token_name9  => cv_tkn_mnt                                -- トークンコード9
                       ,iv_token_value9 => io_sales_plan_month_rec.sales_plan_amt    -- 売上計画金額
                      );
        lv_errbuf  := lv_errmsg||SQLERRM;
        RAISE select_error_expt;
    END;
--    
    -- 該当データ件数が１件以上の場合、顧客別売上計画テーブルのデータ更新を行う
    -- 該当データ件数が０件の場合、顧客別売上計画テーブルのデータ登録を行う
    BEGIN
      IF (ln_data_cnt >= 1) THEN
        -- ========================================================
        -- 顧客別売上計画テーブルの該当月別売上計画データ更新 
        -- ========================================================
        lv_msg_code := cv_tkn_number_05;  -- データ更新エラーコードセット
        UPDATE xxcso_account_sales_plans       -- 顧客別売上計画テーブル
        SET    last_updated_by        = cn_last_updated_by,                     -- 最終更新者
               last_update_date       = cd_last_update_date,                    -- 最終更新日
               last_update_login      = cn_last_update_login,                   -- 最終更新ログイン
               request_id             = cn_request_id,                          -- 要求ID
               program_application_id = cn_program_application_id,              -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑのｱﾌﾟﾘｹｰｼｮﾝID
               program_id             = cn_program_id,                          -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
               program_update_date    = cd_program_update_date,                 -- ﾌﾟﾛｸﾞﾗﾑによる更新日
               sales_plan_month_amt   = io_sales_plan_month_rec.sales_plan_amt, -- 月別売上計画
               update_func_div        = cv_upd_kbn_sales_month                  -- 更新機能区分(6)
        WHERE  account_number = io_sales_plan_month_rec.account_number          -- 顧客コード
          AND  base_code      = io_sales_plan_month_rec.sales_base_code         -- 売上拠点コード
          AND  year_month     = io_sales_plan_month_rec.sales_plan_month        -- 売上計画年月
          AND  plan_day       = cv_dumm_day_month                               -- 日(99)
          AND  month_date_div = cv_monday_kbn_month;                            -- 月日区分(1)
      ELSE
        -- ========================================================
        -- 顧客別売上計画テーブルの該当月別売上計画データ登録 
        -- ========================================================
        lv_msg_code := cv_tkn_number_04;  -- データ追加エラーコードセット
        INSERT INTO xxcso_account_sales_plans(
          account_sales_plan_id,                                   -- 顧客別売上計画ＩＤ
          base_code,                                               -- 売上拠点コード
          account_number,                                          -- 顧客コード
          year_month,                                              -- 売上計画年月
          plan_day,                                                -- 日:99
          fiscal_year,                                             -- 年度
          month_date_div,                                          -- 月日区分:月別計画：1
          sales_plan_month_amt,                                    -- 月別売上計画
          sales_plan_day_amt,                                      -- 日別売上計画
          plan_date,                                               -- 年月日
          party_id,                                                -- パーティID
          update_func_div,                                         -- 更新機能区分
          created_by,                                              -- 作成者
          creation_date,                                           -- 作成日
          last_updated_by,                                         -- 最終更新者
          last_update_date,                                        -- 最終更新日
          last_update_login,                                       -- 最終更新ログイン
          request_id,                                              -- 要求ID
          program_application_id,                                  -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑのｱﾌﾟﾘｹｰｼｮﾝID
          program_id,                                              -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
          program_update_date                                      -- ﾌﾟﾛｸﾞﾗﾑによる更新日
        )VALUES(
          xxcso_account_sales_plans_s01.NEXTVAL,                   -- 顧客別売上計画ＩＤ
          io_sales_plan_month_rec.sales_base_code,                 -- 売上拠点コード
          io_sales_plan_month_rec.account_number,                  -- 顧客コード
          io_sales_plan_month_rec.sales_plan_month,                -- 売上計画年月
          cv_dumm_day_month,                                       -- 日:99
          gt_business_year,                                        -- 年度
          cv_monday_kbn_month,                                     -- 月日区分:月別計画：1
          io_sales_plan_month_rec.sales_plan_amt,                  -- 月別売上計画
          NULL,                                                    -- 日別売上計画
          io_sales_plan_month_rec.sales_plan_month||'99',          -- 年月日
          io_sales_plan_month_rec.party_id,                        -- パーティID
          cv_upd_kbn_sales_month,                                  -- 更新機能区分
          cn_created_by,                                           -- 作成者
          SYSDATE,                                                 -- 作成日
          cn_last_updated_by,                                      -- 最終更新者
          SYSDATE,                                                 -- 最終更新日
          cn_last_update_login,                                    -- 最終更新ログイン
          cn_request_id,                                           -- 要求ID
          cn_program_application_id,                               -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑのｱﾌﾟﾘｹｰｼｮﾝID
          cn_program_id,                                           -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
          SYSDATE                                                  -- ﾌﾟﾛｸﾞﾗﾑによる更新日
        );
      END IF;
    EXCEPTION
      -- *** OTHERS例外ハンドラ ***
      WHEN OTHERS THEN
        -- エラーメッセージ作成
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                               -- アプリケーション短縮名
                       ,iv_name         => lv_msg_code                               -- メッセージコード 
                       ,iv_token_name1  => cv_tkn_tbl                                -- トークンコード1
                       ,iv_token_value1 => cv_table_name                             -- エラー発生のテーブル名
                       ,iv_token_name2  => cv_tkn_errmsg                             -- トークンコード2
                       ,iv_token_value2 => SQLERRM                                   -- ORACLEエラー
                       ,iv_token_name3  => cv_tkn_sequence                           -- トークンコード3
                       ,iv_token_value3 => io_sales_plan_month_rec.no_seq            -- シーケンス番号
                       ,iv_token_name4  => cv_tkn_cstm_cd                            -- トークンコード4
                       ,iv_token_value4 => io_sales_plan_month_rec.account_number    -- 顧客コード
                       ,iv_token_name5  => cv_tkn_cstm_nm                            -- トークンコード5
                       ,iv_token_value5 => io_sales_plan_month_rec.account_name      -- 顧客名称
                       ,iv_token_name6  => cv_tkn_loc_cd                             -- トークンコード6
                       ,iv_token_value6 => io_sales_plan_month_rec.sales_base_code   -- 売上拠点コード
                       ,iv_token_name7  => cv_tkn_loc_nm                             -- トークンコード7
                       ,iv_token_value7 => io_sales_plan_month_rec.sales_base_name   -- 売上拠点名称
                       ,iv_token_name8  => cv_tkn_ym                                 -- トークンコード8
                       ,iv_token_value8 => io_sales_plan_month_rec.sales_plan_month  -- 売上計画年月
                       ,iv_token_name9  => cv_tkn_mnt                                -- トークンコード9
                       ,iv_token_value9 => io_sales_plan_month_rec.sales_plan_amt    -- 売上計画金額
                      );
        lv_errbuf  := lv_errmsg||SQLERRM;  
        RAISE ins_upd_expt;
    END;
--
  EXCEPTION
    -- *** データ抽出時の例外ハンドラ ***
    WHEN select_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** データ登録更新例外ハンドラ ***
    WHEN ins_upd_expt THEN  
      ov_errmsg  := lv_errmsg;      
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END upd_sales_plan_month;
--
  /**********************************************************************************
   * Procedure Name   : upd_sales_plan_day                                                                         
   * Description      : 日別売上計画データの登録または更新 (A-7)
   ***********************************************************************************/
  PROCEDURE upd_sales_plan_day(
    io_sales_plan_month_rec IN OUT NOCOPY g_get_sales_plan_month_rtype, -- 月別売上計画ワークテーブルデータ
    ov_errbuf               OUT NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2          -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'upd_sales_plan_day';     -- プログラム名
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
    cv_table_name       CONSTANT VARCHAR2(100) := 'xxcso_account_sales_plans';   -- 顧客別売上計画テーブル
    -- *** ローカル変数 ***
    ln_data_cnt            NUMBER;              -- 顧客別売上計画テーブルの月別売上計画データ件数    
    lt_route_no            xxcso_in_route_no.route_no%TYPE;                      -- ルートNo
    lv_msg_code            VARCHAR2(200);                                        -- メッセージコード
--
    l_sales_plan_day_on_month_tbl sales_plan_day_on_month_ttype;  --実際の月の日にち分の日別売上計画データ 
    ln_day_on_month        NUMBER;              -- 当該月の日数
    ln_visit_daytimes      NUMBER;              -- 当該月の訪問日数
    ln_loop_cnt            NUMBER;              -- ループ用変数
    lv_table_name          VARCHAR2(200);       -- テーブル名
    -- *** ローカル・例外 ***
    select_error_expt      EXCEPTION;
    ins_upd_expt           EXCEPTION;
    normal_expt            EXCEPTION;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ルートNo変数初期化
    lt_route_no := NULL;
    -- =========================================================
    -- ルートNoビューにより、当該顧客のルートNoを取得 
    -- =========================================================
    BEGIN
      SELECT xcrv.route_number route_number        -- ルートNo
      INTO   lt_route_no                           -- ルートNo
      FROM   xxcso_cust_routes_v xcrv              -- 顧客ルートNoビュー
      WHERE  xcrv.account_number = io_sales_plan_month_rec.account_number  -- 顧客コード
        AND  gd_process_date BETWEEN TRUNC(xcrv.start_date_active)         -- 有効期間
               AND TRUNC(NVL(xcrv.end_date_active, gd_process_date));   
--
    EXCEPTION
      -- *** 該当データが存在しないか複数存在する場合例外ハンドラ ***
      WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
        RAISE normal_expt;
      -- *** OTHERS例外ハンドラ ***
      WHEN OTHERS THEN
        -- エラーメッセージ作成
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name              -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_01         -- メッセージコード データ抽出エラー
                       ,iv_token_name1  => cv_tkn_tbl                                -- トークンコード1
                       ,iv_token_value1 => cv_table_name                             -- エラー発生のテーブル名
                       ,iv_token_name2  => cv_tkn_errmsg                             -- トークンコード2
                       ,iv_token_value2 => SQLERRM                                   -- ORACLEエラー
                       ,iv_token_name3  => cv_tkn_sequence                           -- トークンコード3
                       ,iv_token_value3 => io_sales_plan_month_rec.no_seq            -- シーケンス番号
                       ,iv_token_name4  => cv_tkn_cstm_cd                            -- トークンコード4
                       ,iv_token_value4 => io_sales_plan_month_rec.account_number    -- 顧客コード
                       ,iv_token_name5  => cv_tkn_cstm_nm                            -- トークンコード5
                       ,iv_token_value5 => io_sales_plan_month_rec.account_name      -- 顧客名称
                       ,iv_token_name6  => cv_tkn_loc_cd                             -- トークンコード6
                       ,iv_token_value6 => io_sales_plan_month_rec.sales_base_code   -- 売上拠点コード
                       ,iv_token_name7  => cv_tkn_loc_nm                             -- トークンコード7
                       ,iv_token_value7 => io_sales_plan_month_rec.sales_base_name   -- 売上拠点名称
                       ,iv_token_name8  => cv_tkn_ym                                 -- トークンコード8
                       ,iv_token_value8 => io_sales_plan_month_rec.sales_plan_month  -- 売上計画年月
                       ,iv_token_name9  => cv_tkn_mnt                                -- トークンコード9
                       ,iv_token_value9 => io_sales_plan_month_rec.sales_plan_amt    -- 売上計画金額
                      );
        lv_errbuf  := lv_errmsg||SQLERRM;
        RAISE select_error_expt;
    END;  
--
    --ルートNoが存在する場合、日別売上計画データ登録または更新を行う
    --ルートNoが存在しない場合、継続処理を行う
    IF (lt_route_no IS NOT NULL) THEN
      --売上計画日別配分処理共通関数により、実際の月の日にち分の配分データを取得する
      xxcso_route_common_pkg.distribute_sales_plan(
        iv_year_month                 => io_sales_plan_month_rec.sales_plan_month,
        it_sales_plan_amt             => io_sales_plan_month_rec.sales_plan_amt,
        it_route_number               => lt_route_no,
        on_day_on_month               => ln_day_on_month,                     -- 当該月の日数を取得
        on_visit_daytimes             => ln_visit_daytimes,                   -- 当該月の訪問日数
        ot_sales_plan_day_amt_1       => l_sales_plan_day_on_month_tbl(1),    -- 1日目日別売上計画金額
        ot_sales_plan_day_amt_2       => l_sales_plan_day_on_month_tbl(2),    -- 2日目日別売上計画金額
        ot_sales_plan_day_amt_3       => l_sales_plan_day_on_month_tbl(3),    -- 3日目日別売上計画金額
        ot_sales_plan_day_amt_4       => l_sales_plan_day_on_month_tbl(4),    -- 4日目日別売上計画金額
        ot_sales_plan_day_amt_5       => l_sales_plan_day_on_month_tbl(5),    -- 5日目日別売上計画金額
        ot_sales_plan_day_amt_6       => l_sales_plan_day_on_month_tbl(6),    -- 6日目日別売上計画金額
        ot_sales_plan_day_amt_7       => l_sales_plan_day_on_month_tbl(7),    -- 7日目日別売上計画金額
        ot_sales_plan_day_amt_8       => l_sales_plan_day_on_month_tbl(8),    -- 8日目日別売上計画金額
        ot_sales_plan_day_amt_9       => l_sales_plan_day_on_month_tbl(9),    -- 9日目日別売上計画金額
        ot_sales_plan_day_amt_10      => l_sales_plan_day_on_month_tbl(10),   -- 10日目日別売上計画金額
        ot_sales_plan_day_amt_11      => l_sales_plan_day_on_month_tbl(11),   -- 11日目日別売上計画金額
        ot_sales_plan_day_amt_12      => l_sales_plan_day_on_month_tbl(12),   -- 12日目日別売上計画金額
        ot_sales_plan_day_amt_13      => l_sales_plan_day_on_month_tbl(13),   -- 13日目日別売上計画金額
        ot_sales_plan_day_amt_14      => l_sales_plan_day_on_month_tbl(14),   -- 14日目日別売上計画金額
        ot_sales_plan_day_amt_15      => l_sales_plan_day_on_month_tbl(15),   -- 15日目日別売上計画金額
        ot_sales_plan_day_amt_16      => l_sales_plan_day_on_month_tbl(16),   -- 16日目日別売上計画金額
        ot_sales_plan_day_amt_17      => l_sales_plan_day_on_month_tbl(17),   -- 17日目日別売上計画金額
        ot_sales_plan_day_amt_18      => l_sales_plan_day_on_month_tbl(18),   -- 18日目日別売上計画金額
        ot_sales_plan_day_amt_19      => l_sales_plan_day_on_month_tbl(19),   -- 19日目日別売上計画金額
        ot_sales_plan_day_amt_20      => l_sales_plan_day_on_month_tbl(20),   -- 20日目日別売上計画金額
        ot_sales_plan_day_amt_21      => l_sales_plan_day_on_month_tbl(21),   -- 21日目日別売上計画金額
        ot_sales_plan_day_amt_22      => l_sales_plan_day_on_month_tbl(22),   -- 22日目日別売上計画金額
        ot_sales_plan_day_amt_23      => l_sales_plan_day_on_month_tbl(23),   -- 23日目日別売上計画金額
        ot_sales_plan_day_amt_24      => l_sales_plan_day_on_month_tbl(24),   -- 24日目日別売上計画金額
        ot_sales_plan_day_amt_25      => l_sales_plan_day_on_month_tbl(25),   -- 25日目日別売上計画金額
        ot_sales_plan_day_amt_26      => l_sales_plan_day_on_month_tbl(26),   -- 26日目日別売上計画金額
        ot_sales_plan_day_amt_27      => l_sales_plan_day_on_month_tbl(27),   -- 27日目日別売上計画金額
        ot_sales_plan_day_amt_28      => l_sales_plan_day_on_month_tbl(28),   -- 28日目日別売上計画金額
        ot_sales_plan_day_amt_29      => l_sales_plan_day_on_month_tbl(29),   -- 29日目日別売上計画金額
        ot_sales_plan_day_amt_30      => l_sales_plan_day_on_month_tbl(30),   -- 30日目日別売上計画金額
        ot_sales_plan_day_amt_31      => l_sales_plan_day_on_month_tbl(31),   -- 31日目日別売上計画金額
        ov_errbuf                     => lv_errbuf,
        ov_retcode                    => lv_retcode,
        ov_errmsg                     => lv_errmsg);
--
      /* 2009/12/07 T.Maruyama E_本稼動_00028対応 START */
      --日別按分ができない＝ルートNoが不正な場合は、日別按分を実施せず終了
      IF (lv_retcode = cv_status_error) THEN
        raise normal_expt;
      END IF;
      /* 2009/12/07 T.Maruyama E_本稼動_00028対応 END */
--
      -- ==============================================================
      -- 顧客別売上計画テーブルから該当日別売上データ件数を取得 
      -- ==============================================================
      BEGIN
        SELECT COUNT(xasp.account_sales_plan_id) datacnt   -- 該当日別売上データ件数
        INTO   ln_data_cnt                                 -- 該当日別売上データ件数
        FROM   xxcso_account_sales_plans xasp              -- 顧客別売上計画テーブル
        WHERE  xasp.account_number = io_sales_plan_month_rec.account_number      -- 顧客コード
          AND  xasp.base_code      = io_sales_plan_month_rec.sales_base_code     -- 売上拠点コード
          AND  xasp.year_month     = io_sales_plan_month_rec.sales_plan_month    -- 売上計画年月
          AND  xasp.plan_date LIKE io_sales_plan_month_rec.sales_plan_month||'%' -- 売上計画年月日
          AND  xasp.month_date_div = cv_monday_kbn_day;                          -- 月日区分(2)
--
      EXCEPTION
        -- *** OTHERS例外ハンドラ ***
        WHEN OTHERS THEN
          -- エラーメッセージ作成
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name              -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_01         -- メッセージコード データ抽出エラー
                         ,iv_token_name1  => cv_tkn_tbl                                -- トークンコード1
                         ,iv_token_value1 => cv_table_name                             -- エラー発生のテーブル名
                         ,iv_token_name2  => cv_tkn_errmsg                             -- トークンコード2
                         ,iv_token_value2 => SQLERRM                                   -- ORACLEエラー
                         ,iv_token_name3  => cv_tkn_sequence                           -- トークンコード3
                         ,iv_token_value3 => io_sales_plan_month_rec.no_seq            -- シーケンス番号
                         ,iv_token_name4  => cv_tkn_cstm_cd                            -- トークンコード4
                         ,iv_token_value4 => io_sales_plan_month_rec.account_number    -- 顧客コード
                         ,iv_token_name5  => cv_tkn_cstm_nm                            -- トークンコード5
                         ,iv_token_value5 => io_sales_plan_month_rec.account_name      -- 顧客名称
                         ,iv_token_name6  => cv_tkn_loc_cd                             -- トークンコード6
                         ,iv_token_value6 => io_sales_plan_month_rec.sales_base_code   -- 売上拠点コード
                         ,iv_token_name7  => cv_tkn_loc_nm                             -- トークンコード7
                         ,iv_token_value7 => io_sales_plan_month_rec.sales_base_name   -- 売上拠点名称
                         ,iv_token_name8  => cv_tkn_ym                                 -- トークンコード8
                         ,iv_token_value8 => io_sales_plan_month_rec.sales_plan_month  -- 売上計画年月
                         ,iv_token_name9  => cv_tkn_mnt                                -- トークンコード9
                         ,iv_token_value9 => io_sales_plan_month_rec.sales_plan_amt    -- 売上計画金額
                        );
          lv_errbuf  := lv_errmsg||SQLERRM;
          RAISE select_error_expt;
      END;
--
      -- 該当データ件数が１件以上の場合、顧客別売上計画テーブルの日別売上計画データ更新を行う
      -- 該当データ件数が０件の場合、顧客別売上計画テーブルの日別売上計画データ登録を行う
      BEGIN
        IF (ln_data_cnt >= 1) THEN
          lv_msg_code := cv_tkn_number_05;  -- データ更新エラーコードセット
          <<sales_plan_day_data_loop1>>
          FOR ln_loop_cnt IN 1..ln_day_on_month LOOP
            -- ==============================================================
            -- 顧客別売上計画テーブルの該当月の日別売上計画データ更新 
            -- ==============================================================
            UPDATE xxcso_account_sales_plans       -- 顧客別売上計画テーブル
            SET    last_updated_by        = cn_last_updated_by,        -- 最終更新者
                   last_update_date       = cd_last_update_date,       -- 最終更新日
                   last_update_login      = cn_last_update_login,      -- 最終更新ログイン
                   request_id             = cn_request_id,             -- 要求ID
                   program_application_id = cn_program_application_id, -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑのｱﾌﾟﾘｹｰｼｮﾝID
                   program_id             = cn_program_id,             -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
                   program_update_date    = cd_program_update_date,    -- ﾌﾟﾛｸﾞﾗﾑによる更新日
                   sales_plan_day_amt     = l_sales_plan_day_on_month_tbl(ln_loop_cnt), -- 日別売上計画
                   update_func_div        = cv_upd_kbn_sales_month     -- 更新機能区分(6)
            WHERE  account_number = io_sales_plan_month_rec.account_number  -- 顧客コード
              AND  base_code      = io_sales_plan_month_rec.sales_base_code -- 売上拠点コード
              AND  plan_date      = io_sales_plan_month_rec.sales_plan_month||LPAD(TO_CHAR(ln_loop_cnt),2,'0') -- 売上計画年月日
              AND  month_date_div = cv_monday_kbn_day;                      -- 月日区分(2)
          END LOOP sales_plan_day_data_loop1;
        ELSE
          lv_msg_code := cv_tkn_number_04;  -- データ登録エラーコードセット
          <<sales_plan_day_data_loop2>>
          FOR ln_loop_cnt IN 1..ln_day_on_month LOOP
            -- ==============================================================
            -- 顧客別売上計画テーブルの該当月の日別売上計画データ登録 
            -- ==============================================================
            INSERT INTO xxcso_account_sales_plans(
              account_sales_plan_id,                                         -- 顧客別売上計画ＩＤ
              base_code,                                                     -- 売上拠点コード
              account_number,                                                -- 顧客コード
              year_month,                                                    -- 売上計画年月
              plan_day,                                                      -- 日
              fiscal_year,                                                   -- 年度
              month_date_div,                                                -- 月日区分
              sales_plan_month_amt,                                          -- 月別売上計画
              sales_plan_day_amt,                                            -- 日別売上計画
              plan_date,                                                     -- 年月日
              party_id,                                                      -- パーティID
              update_func_div,                                               -- 更新機能区分
              created_by,                                                    -- 作成者
              creation_date,                                                 -- 作成日
              last_updated_by,                                               -- 最終更新者
              last_update_date,                                              -- 最終更新日
              last_update_login,                                             -- 最終更新ログイン
              request_id,                                                    -- 要求ID
              program_application_id,                                        -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑのｱﾌﾟﾘｹｰｼｮﾝID
              program_id,                                                    -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
              program_update_date                                            -- ﾌﾟﾛｸﾞﾗﾑによる更新日
            )VALUES(
              xxcso_account_sales_plans_s01.NEXTVAL,                         -- 顧客別売上計画ＩＤ
              io_sales_plan_month_rec.sales_base_code,                       -- 売上拠点コード
              io_sales_plan_month_rec.account_number,                        -- 顧客コード
              io_sales_plan_month_rec.sales_plan_month,                      -- 売上計画年月
-- 障害番号067対応
--              ln_loop_cnt,                                                   -- 日
              LPAD(TO_CHAR(ln_loop_cnt),2,'0'),                              -- 日
--
              gt_business_year,                                              -- 年度
              cv_monday_kbn_day,                                             -- 月日区分:日別計画：2
              NULL,                                                          -- 月別売上計画
              l_sales_plan_day_on_month_tbl(ln_loop_cnt),                    -- 日別売上計画
              io_sales_plan_month_rec.sales_plan_month||LPAD(TO_CHAR(ln_loop_cnt),2,'0'),  -- 年月日
              io_sales_plan_month_rec.party_id,                              -- パーティID
              cv_upd_kbn_sales_month,                                        -- 更新機能区分
              cn_created_by,                                                 -- 作成者
              SYSDATE,                                                       -- 作成日
              cn_last_updated_by,                                            -- 最終更新者
              SYSDATE,                                                       -- 最終更新日
              cn_last_update_login,                                          -- 最終更新ログイン
              cn_request_id,                                                 -- 要求ID
              cn_program_application_id,                                     -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑのｱﾌﾟﾘｹｰｼｮﾝID
              cn_program_id,                                                 -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
              SYSDATE                                                        -- ﾌﾟﾛｸﾞﾗﾑによる更新日
            );
          END LOOP sales_plan_day_data_loop2;
        END IF;
      EXCEPTION
        -- *** OTHERS例外ハンドラ ***
        WHEN OTHERS THEN
          -- エラーメッセージ作成
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                               -- アプリケーション短縮名
                         ,iv_name         => lv_msg_code                               -- メッセージコード 
                         ,iv_token_name1  => cv_tkn_tbl                                -- トークンコード1
                         ,iv_token_value1 => cv_table_name                             -- エラー発生のテーブル名
                         ,iv_token_name2  => cv_tkn_errmsg                             -- トークンコード2
                         ,iv_token_value2 => SQLERRM                                   -- ORACLEエラー
                         ,iv_token_name3  => cv_tkn_sequence                           -- トークンコード3
                         ,iv_token_value3 => io_sales_plan_month_rec.no_seq            -- シーケンス番号
                         ,iv_token_name4  => cv_tkn_cstm_cd                            -- トークンコード4
                         ,iv_token_value4 => io_sales_plan_month_rec.account_number    -- 顧客コード
                         ,iv_token_name5  => cv_tkn_cstm_nm                            -- トークンコード5
                         ,iv_token_value5 => io_sales_plan_month_rec.account_name      -- 顧客名称
                         ,iv_token_name6  => cv_tkn_loc_cd                             -- トークンコード6
                         ,iv_token_value6 => io_sales_plan_month_rec.sales_base_code   -- 売上拠点コード
                         ,iv_token_name7  => cv_tkn_loc_nm                             -- トークンコード7
                         ,iv_token_value7 => io_sales_plan_month_rec.sales_base_name   -- 売上拠点名称
                         ,iv_token_name8  => cv_tkn_ym                                 -- トークンコード8
                         ,iv_token_value8 => io_sales_plan_month_rec.sales_plan_month  -- 売上計画年月
                         ,iv_token_name9  => cv_tkn_mnt                                -- トークンコード9
                         ,iv_token_value9 => io_sales_plan_month_rec.sales_plan_amt    -- 売上計画金額
                        );
          lv_errbuf  := lv_errmsg||SQLERRM;  
          RAISE ins_upd_expt;
      END;
    END IF;
--
  EXCEPTION
    -- *** ルートNoが存在しない場合データ更新処理を抜ける ***
    WHEN normal_expt THEN
      ov_retcode := cv_status_normal;  
    -- *** データ抽出時の例外ハンドラ ***
    WHEN select_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** データ登録更新例外ハンドラ ***
    WHEN ins_upd_expt THEN  
      ov_errmsg  := lv_errmsg;      
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END upd_sales_plan_day;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   ***********************************************************************************/
  PROCEDURE submain(
    ov_errbuf           OUT NOCOPY VARCHAR2,   -- エラー・メッセージ             --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,   -- リターン・コード               --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2    -- ユーザー・エラー・メッセージ   --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'submain';     -- プログラム名
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
    ln_sales_plan_cnt      NUMBER;                     -- 日別売上計画連携チェック用のデータ件数
    lb_not_exists_new_data BOOLEAN;                    -- 最新レコード存在チェックフラグ
    lv_msg_code            VARCHAR2(100);              -- メッセージコード
    lv_err_rec_info        VARCHAR2(5000);             -- エラーデータ格納用
    lt_visit_target_div    xxcso_cust_accounts_v.vist_target_div%TYPE;    -- 訪問対象区分
--
    -- *** ローカル・カーソル ***
    CURSOR xispm_data_cur
    IS
      SELECT  xispm.no_seq  no_seq,                           -- シーケンス番号
              xispm.account_number account_number,            -- 顧客コード
              xispm.sales_base_code sales_base_code,          -- 売上拠点コード
              xispm.sales_plan_month sales_plan_month,        -- 売上計画年月
              xispm.sales_plan_amt sales_plan_amt             -- 売上計画金額
      FROM   xxcso_in_sales_plan_month  xispm                 -- 月別売上計画ワークテーブル
      ORDER BY xispm.no_seq;
--
    -- *** ローカル・レコード ***
    l_xispm_data_rec      xispm_data_cur%ROWTYPE;
    l_get_data_rec        g_get_sales_plan_month_rtype;
--
    -- *** ローカル例外 ***
    skip_data_expt             EXCEPTION;  -- 正常処理でスキップ処理される例外（最新レコードチェックなど）
    error_skip_data_expt       EXCEPTION;  -- マスタ存在チェックエラーなどで発生した例外
    
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
    gn_skip_cnt   := 0;
    gn_error_cnt  := 0;
--
    -- ================================
    -- A-1.初期処理 
    -- ================================
    init(
      ov_errbuf  => lv_errbuf,          -- エラー・メッセージ            --# 固定 #
      ov_retcode => lv_retcode,         -- リターン・コード              --# 固定 #
      ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ====================================
    -- A-2.売上計画情報抽出 
    -- ====================================
    -- カーソルオープン
    OPEN xispm_data_cur;
--
    <<get_data_loop>>
    LOOP
--
      BEGIN
        FETCH xispm_data_cur INTO l_xispm_data_rec;
        -- 処理対象件数格納
        gn_target_cnt := xispm_data_cur%ROWCOUNT;
--
        EXIT WHEN xispm_data_cur%NOTFOUND
        OR  xispm_data_cur%ROWCOUNT = 0;
--
        -- レコード変数初期化
        l_get_data_rec := NULL;
--
        l_get_data_rec.no_seq                  := l_xispm_data_rec.no_seq;               -- シーケンス番号
        l_get_data_rec.account_number          := l_xispm_data_rec.account_number;       -- 顧客コード
        l_get_data_rec.sales_base_code         := l_xispm_data_rec.sales_base_code;      -- 売上拠点コード
        l_get_data_rec.sales_plan_month        := l_xispm_data_rec.sales_plan_month;     -- 売上計画年月
        l_get_data_rec.sales_plan_amt          := l_xispm_data_rec.sales_plan_amt;       -- 売上計画金額
--      
        -- INPUTデータの項目をカンマ区切りで文字連結してログに出力する用
        lv_err_rec_info := l_get_data_rec.no_seq||','
                        || l_get_data_rec.account_number ||','
                        || l_get_data_rec.sales_base_code ||','
                        || l_get_data_rec.sales_plan_month ||','
                        || l_get_data_rec.sales_plan_amt || ' ';
--
        -- 年度取得
        gt_business_year := TO_CHAR(xxcso_util_common_pkg.get_business_year(
                              iv_year_month => l_get_data_rec.sales_plan_month));
--
        -- 年度取得に失敗した場合
        IF (gt_business_year IS NULL) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name                  -- アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_07             -- メッセージコード
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- ========================================
        -- A-3.マスタ存在チェック 
        -- ========================================
        chk_mst_is_exists(
          io_sales_plan_month_rec  => l_get_data_rec,                  -- 月別売上計画ワークテーブルデータ
          ov_errbuf                => lv_errbuf,      -- エラー・メッセージ            --# 固定 #
          ov_retcode               => lv_retcode,     -- リターン・コード              --# 固定 #
          ov_errmsg                => lv_errmsg       -- ユーザー・エラー・メッセージ  --# 固定 #
        );
        -- マスタ存在チェックでエラーが発生する場合、中断処理またはスキップ処理
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lv_retcode = cv_status_warn) THEN
          RAISE error_skip_data_expt;
        END IF;
--
        -- ========================================
        -- A-4.最新レコードチェック
        -- ========================================
        chk_is_new_recode(
          io_sales_plan_month_rec   => l_get_data_rec,              -- 月別売上計画ワークテーブルデータ
          ob_not_exists_new_data    => lb_not_exists_new_data,      -- 最新レコード存在チェックフラグ
          ov_errbuf                 => lv_errbuf,      -- エラー・メッセージ             --# 固定 #
          ov_retcode                => lv_retcode,     -- リターン・コード               --# 固定 #
          ov_errmsg                 => lv_errmsg       -- ユーザー・エラー・メッセージ   --# 固定 #
        );
        -- エラーが発生する場合は中断、最新レコードが存在する場合は正常スキップ
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lb_not_exists_new_data = cb_false) THEN
          RAISE skip_data_expt;
        END IF;
--
        -- 最新レコードが存在しない（当該レコードよりシーケンス番号が大きいレコードがない）場合
        -- ========================================
        -- A-5.日別計画連携チェック 
        -- ========================================  
        chk_sales_plan_day(
          io_sales_plan_month_rec  => l_get_data_rec,         -- 月別売上計画ワークテーブルデータ
          on_sales_plan_cnt        => ln_sales_plan_cnt,      -- 日別売上計画連携チェック用のデータ件数
          ov_errbuf                => lv_errbuf,      -- エラー・メッセージ            --# 固定 #
          ov_retcode               => lv_retcode,     -- リターン・コード              --# 固定 #
          ov_errmsg                => lv_errmsg       -- ユーザー・エラー・メッセージ  --# 固定 #
        );
--
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ===============================================
        -- A-6.顧客別売上計画データの登録または更新 
        -- ===============================================
        upd_sales_plan_month(
            io_sales_plan_month_rec  => l_get_data_rec,         -- 月別売上計画ワークテーブルデータ
            ov_errbuf                => lv_errbuf,      -- エラー・メッセージ            --# 固定 #
            ov_retcode               => lv_retcode,     -- リターン・コード              --# 固定 #
            ov_errmsg                => lv_errmsg       -- ユーザー・エラー・メッセージ  --# 固定 #
        );
--
        -- 顧客別売上計画データの月別データ登録＆更新でエラーが発生する場合は中断
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lv_retcode = cv_status_warn) THEN
          RAISE error_skip_data_expt;
        END IF;
--
        -- 顧客別売上計画データの月別データ登録＆更新が正常の場合は次の処理に進む
        lt_visit_target_div := l_get_data_rec.vist_target_div;  -- 訪問対象区分
        -- ===============================================
        -- A-7.日別売上計画データの登録または更新 
        -- ===============================================
        -- 訪問対象区分が「1」（訪問対象）で、日別売上計画チェック結果がなしの場合、
        -- 且つ顧客別売上計画の月別データ登録または更新が正常の場合、日別データ登録＆更新
        IF (lt_visit_target_div = cv_houmon_kbn_taget) AND (ln_sales_plan_cnt = 0) 
          AND (lv_retcode = cv_status_normal) THEN
            upd_sales_plan_day(
              io_sales_plan_month_rec  => l_get_data_rec,  -- 月別売上計画ワークテーブルデータ
              ov_errbuf                => lv_errbuf,       -- エラー・メッセージ            --# 固定 #
              ov_retcode               => lv_retcode,      -- リターン・コード              --# 固定 #
              ov_errmsg                => lv_errmsg        -- ユーザー・エラー・メッセージ  --# 固定 #
            );
--
          -- 顧客別売上計画データの日別データ登録＆更新でエラーが発生する場合は中断
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          ELSIF (lv_retcode = cv_status_warn) THEN
            RAISE error_skip_data_expt;
          END IF;
        END IF;
--
        -- ========================
        -- A-8.セーブポイント設定
        -- ========================
        SAVEPOINT a;
--        
        -- 正常件数カウント
        gn_normal_cnt := gn_normal_cnt + 1;
--
      EXCEPTION
          -- データ処理対象外にてスキップ
          WHEN skip_data_expt THEN
            -- スキップ件数カウント
            gn_skip_cnt := gn_skip_cnt + 1;
            -- スキップデータログ出力
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => cv_debug_msg3 || lv_err_rec_info || CHR(10) ||
                         ''
            );
          -- データチェック、登録エラーにてスキップ
          WHEN error_skip_data_expt THEN
            -- エラー件数カウント
            gn_error_cnt := gn_error_cnt + 1;
            -- エラー出力
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg                  -- ユーザー・エラーメッセージ
            );
            -- エラーログ（データ情報＋エラーメッセージ）
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => lv_err_rec_info || lv_errbuf || CHR(10) ||
                         ''
            );
            -- ロールバック
            IF (gn_normal_cnt = 0) THEN
              ROLLBACK;
            ELSE
              ROLLBACK TO SAVEPOINT a;
            END IF;
            -- 全体の処理ステータスに警告セット
            ov_retcode := cv_status_warn;
      END;
    END LOOP get_data_loop;
    -- カーソルクローズ
    CLOSE xispm_data_cur;
--
  EXCEPTION
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      gn_error_cnt := gn_error_cnt + 1;                           -- エラー件数カウント
      -- カーソルがクローズされていない場合
      IF xispm_data_cur%ISOPEN THEN
        -- カーソルクローズ
        CLOSE xispm_data_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      gn_error_cnt := gn_error_cnt + 1;                           -- エラー件数カウント
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      gn_error_cnt := gn_error_cnt + 1;                           -- エラー件数カウント
      -- カーソルがクローズされていない場合
      IF xispm_data_cur%ISOPEN THEN
        -- カーソルクローズ
        CLOSE xispm_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      gn_error_cnt := gn_error_cnt + 1;                           -- エラー件数カウント
      -- カーソルがクローズされていない場合
      IF xispm_data_cur%ISOPEN THEN
        -- カーソルクローズ
        CLOSE xispm_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END submain;
--
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT NOCOPY VARCHAR2,    --   エラー・メッセージ  --# 固定 #
    retcode       OUT NOCOPY VARCHAR2     --   リターン・コード    --# 固定 #
  )
  IS
--
--###########################  固定部 START   ###########################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
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
    -- *** ローカル変数 ***
    lv_message_code  VARCHAR2(100);  -- 終了メッセージ名格納
--
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
      ov_retcode => lv_retcode,
      ov_errbuf  => lv_errbuf,
      ov_errmsg  => lv_errmsg
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
      ov_errbuf   => lv_errbuf,           -- エラー・メッセージ            --# 固定 #
      ov_retcode  => lv_retcode,          -- リターン・コード              --# 固定 #
      ov_errmsg   => lv_errmsg            -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
       --エラー出力
       fnd_file.put_line(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg                  --ユーザー・エラーメッセージ
       );
       fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => cv_pkg_name||cv_msg_cont||
                    cv_prg_name||cv_msg_part||
                    lv_errbuf                  --エラーメッセージ
       );
    END IF;
--
    -- ===============
    -- A-9.終了処理
    -- ===============
    -- 空行の出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name,
                    iv_name         => cv_target_rec_msg,
                    iv_token_name1  => cv_cnt_token,
                    iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name,
                    iv_name         => cv_success_rec_msg,
                    iv_token_name1  => cv_cnt_token,
                    iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name,
                    iv_name         => cv_skip_rec_msg,
                    iv_token_name1  => cv_cnt_token,
                    iv_token_value1 => TO_CHAR(gn_skip_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name,
                    iv_name         => cv_error_rec_msg,
                    iv_token_name1  => cv_cnt_token,
                    iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    fnd_file.put_line(
      which  => FND_FILE.OUTPUT,
      buff   => gv_out_msg
    );
--
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF (lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;      
    ELSIF (lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
--
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name,
                    iv_name         => lv_message_code
                   );
    fnd_file.put_line(
      which  => FND_FILE.OUTPUT,
      buff   => gv_out_msg
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
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
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
END XXCSO014A01C;
/
