CREATE OR REPLACE PACKAGE BODY XXCSM001A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM001A03C(body)
 * Description      : 販売計画テーブルに登録された処理対象予算年度のデータを抽出し、
 *                  : CSV形式のファイルを作成します。
 *                  : 作成したCSVファイルを所定のフォルダに格納します。
 * MD.050           : MD050_CSM_001_A03_年間計画情報系システムIF
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理 (A-1)
 *  open_csv_file          ファイルオープン処理 (A-2)
 *  create_csv_rec         販売計画データ書込処理 (A-4)
 *  close_csv_file         年間計画IFファイルクローズ処理処理 (A-5)
 *  submain                メイン処理プロシージャ
 *                           販売計画データ抽出処理 (A-3)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                           終了処理 (A-6)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-12-01    1.0   M.Ohtsuki       新規作成
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal;             -- 正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;               -- 警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;              -- 異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;                             -- CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                                        -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                             -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                                        -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                            -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;                     -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;                        -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;                     -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                                        -- PROGRAM_UPDATE_DATE
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
  cv_msg_00111              CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00111';                           -- 想定外エラーメッセージ
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg                VARCHAR2(2000);
  gv_sep_msg                VARCHAR2(2000);
  gv_exec_user              VARCHAR2(100);
  gv_conc_name              VARCHAR2(30);
  gv_conc_status            VARCHAR2(30);
  gn_target_cnt             NUMBER;                                                                 -- 対象件数
  gn_normal_cnt             NUMBER;                                                                 -- 正常件数
  gn_error_cnt              NUMBER;                                                                 -- エラー件数
  gn_warn_cnt               NUMBER;                                                                 -- スキップ件数
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
  cv_pkg_name             CONSTANT VARCHAR2(100) := 'XXCSM001A03C';                                 -- パッケージ名
  cv_app_name             CONSTANT VARCHAR2(5)   := 'XXCSM';                                        -- アプリケーション短縮名
  -- メッセージコード
  cv_xxccp_msg_008        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008';                             -- コンカレント入力パラメータなし
  cv_xxcsm_msg_001        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00001';                             -- ファイル存在チェックエラーメッセージ
  cv_xxcsm_msg_002        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00002';                             -- ファイルオープンエラーメッセージ
  cv_xxcsm_msg_003        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00003';                             -- ファイルクローズエラーメッセージ
  cv_xxcsm_msg_019        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00019';                             -- 情報系システム連携対象無しエラーメッセージ
  cv_xxcsm_msg_021        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00021';                             -- 年度取得エラーメッセージ
  cv_xxcsm_msg_031        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00031';                             -- 定期実行用プロファイル取得エラーメッセージ
  cv_xxcsm_msg_084        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00084';                             -- インターフェースファイル名
  --プロファイル名
  cv_file_dir             CONSTANT VARCHAR2(100) := 'XXCSM1_INFOSYS_FILE_DIR';                      -- 情報系データファイル作成ディレクトリ
  cv_file_name            CONSTANT VARCHAR2(100) := 'XXCSM1_YEARPLAN_FILE_NAME';                    -- 年間計画データファイル名
  -- トークンコード
  cv_tkn_prf_name         CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_directory        CONSTANT VARCHAR2(20) := 'DIRECTORY';
  cv_tkn_file_name        CONSTANT VARCHAR2(20) := 'FILE_NAME';
  cv_tkn_sql_code         CONSTANT VARCHAR2(20) := 'SQL_CODE';
  cv_tkn_yyyymm           CONSTANT VARCHAR2(20) := 'YYYYMM';
  cv_tkn_count            CONSTANT VARCHAR2(20) := 'COUNT';
--
  cb_true                 CONSTANT BOOLEAN := TRUE;
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- ファイル・ハンドルの宣言
  gf_file_hand            UTL_FILE.FILE_TYPE;
  gv_file_dir             VARCHAR2(100);
  gv_file_name            VARCHAR2(100);
  gv_obj_year             VARCHAR2(100);
  gd_sysdate              DATE;
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- CSV出力データ格納用レコード型定義
  TYPE g_get_data_rtype IS RECORD(
    company_cd                   VARCHAR2(3)                                                        -- 会社コード
   ,plan_year                    xxcsm_sales_plan.plan_year%TYPE                                    -- 年度
   ,plan_ym                      xxcsm_sales_plan.plan_ym%TYPE                                      -- 年月
   ,location_cd                  xxcsm_sales_plan.location_cd%TYPE                                  -- 拠点（部門）コード
   ,act_work_date                xxcsm_sales_plan.act_work_date%TYPE                                -- 実働日
   ,plan_staff                   xxcsm_sales_plan.plan_staff%TYPE                                   -- 計画人員
   ,sale_plan_depart             xxcsm_sales_plan.sale_plan_depart%TYPE                             -- 量販店
   ,sale_plan_cvs                xxcsm_sales_plan.sale_plan_cvs%TYPE                                -- ＣＶＳ
   ,sale_plan_dealer             xxcsm_sales_plan.sale_plan_dealer%TYPE                             -- 問屋
   ,sale_plan_others             xxcsm_sales_plan.sale_plan_others%TYPE                             -- その他
   ,sale_plan_vendor             xxcsm_sales_plan.sale_plan_vendor%TYPE                             -- ベンダー
   ,sale_plan_total              xxcsm_sales_plan.sale_plan_total%TYPE                              -- 売上合計
   ,sale_plan_spare_1            xxcsm_sales_plan.sale_plan_spare_1%TYPE                            -- 業態別売上計画（予備１）
   ,sale_plan_spare_2            xxcsm_sales_plan.sale_plan_spare_2%TYPE                            -- 業態別売上計画（予備２）
   ,sale_plan_spare_3            xxcsm_sales_plan.sale_plan_spare_3%TYPE                            -- 業態別売上計画（予備３）
   ,ly_revision_depart           xxcsm_sales_plan.ly_revision_depart%TYPE                           -- 前年実績修正（量販店）
   ,ly_revision_cvs              xxcsm_sales_plan.ly_revision_cvs%TYPE                              -- 前年実績修正（ＣＶＳ）
   ,ly_revision_dealer           xxcsm_sales_plan.ly_revision_dealer%TYPE                           -- 前年実績修正（問屋）
   ,ly_revision_others           xxcsm_sales_plan.ly_revision_others%TYPE                           -- 前年実績修正（その他）
   ,ly_revision_vendor           xxcsm_sales_plan.ly_revision_vendor%TYPE                           -- 前年実績修正（ベンダー）
   ,ly_revision_spare_1          xxcsm_sales_plan.ly_revision_spare_1%TYPE                          -- 前年実績修正（予備１）
   ,ly_revision_spare_2          xxcsm_sales_plan.ly_revision_spare_2%TYPE                          -- 前年実績修正（予備２）
   ,ly_revision_spare_3          xxcsm_sales_plan.ly_revision_spare_3%TYPE                          -- 前年実績修正（予備３）
   ,ly_exist_total               xxcsm_sales_plan.ly_exist_total%TYPE                               -- 昨年既存客（全体）
   ,ly_newly_total               xxcsm_sales_plan.ly_newly_total%TYPE                               -- 昨年新規客（全体）
   ,ty_first_total               xxcsm_sales_plan.ty_first_total%TYPE                               -- 本年新規初回（全体）
   ,ty_turn_total                xxcsm_sales_plan.ty_turn_total%TYPE                                -- 本年新規回転（全体）
   ,discount_total               xxcsm_sales_plan.discount_total%TYPE                               -- 入金値引（全体）
   ,ly_exist_vd_charge           xxcsm_sales_plan.ly_exist_vd_charge%TYPE                           -- 昨年既存客（ＶＤ）担当
   ,ly_newly_vd_charge           xxcsm_sales_plan.ly_newly_vd_charge%TYPE                           -- 昨年新規客（ＶＤ）担当
   ,ty_first_vd_charge           xxcsm_sales_plan.ty_first_vd_charge%TYPE                           -- 本年新規初回（ＶＤ）担当
   ,ty_turn_vd_charge            xxcsm_sales_plan.ty_turn_vd_charge%TYPE                            -- 本年新規回転（ＶＤ）担当
   ,ty_first_vd_get              xxcsm_sales_plan.ty_first_vd_get%TYPE                              -- 本年新規初回（ＶＤ）獲得
   ,ty_turn_vd_get               xxcsm_sales_plan.ty_turn_vd_get%TYPE                               -- 本年新規回転（ＶＤ）獲得
   ,st_mon_get_total             xxcsm_sales_plan.st_mon_get_total%TYPE                             -- 月首顧客数（全体）獲得
   ,newly_get_total              xxcsm_sales_plan.newly_get_total%TYPE                              -- 新規軒数（全体）獲得
   ,cancel_get_total             xxcsm_sales_plan.cancel_get_total%TYPE                             -- 中止軒数（全体）獲得
   ,newly_charge_total           xxcsm_sales_plan.newly_charge_total%TYPE                           -- 新規軒数（全体）担当
   ,st_mon_get_vd                xxcsm_sales_plan.st_mon_get_vd%TYPE                                -- 月首顧客数（ＶＤ）獲得
   ,newly_get_vd                 xxcsm_sales_plan.newly_get_vd%TYPE                                 -- 新規軒数（ＶＤ）獲得
   ,cancel_get_vd                xxcsm_sales_plan.cancel_get_vd%TYPE                                -- 中止軒数（ＶＤ）獲得
   ,newly_charge_vd_own          xxcsm_sales_plan.newly_charge_vd_own%TYPE                          -- 自力新規軒数（ＶＤ）担当
   ,newly_charge_vd_help         xxcsm_sales_plan.newly_charge_vd_help%TYPE                         -- 他力新規軒数（ＶＤ）担当
   ,cancel_charge_vd             xxcsm_sales_plan.cancel_charge_vd%TYPE                             -- 中止軒数（ＶＤ）担当
   ,patrol_visit_cnt             xxcsm_sales_plan.patrol_visit_cnt%TYPE                             -- 巡回訪問顧客数
   ,patrol_def_visit_cnt         xxcsm_sales_plan.patrol_def_visit_cnt%TYPE                         -- 巡回延訪問軒数
   ,vendor_visit_cnt             xxcsm_sales_plan.vendor_visit_cnt%TYPE                             -- ベンダー訪問顧客数
   ,vendor_def_visit_cnt         xxcsm_sales_plan.vendor_def_visit_cnt%TYPE                         -- ベンダー延訪問軒数
   ,public_visit_cnt             xxcsm_sales_plan.public_visit_cnt%TYPE                             -- 一般訪問顧客数
   ,public_def_visit_cnt         xxcsm_sales_plan.public_def_visit_cnt%TYPE                         -- 一般延訪問軒数
   ,def_cnt_total                xxcsm_sales_plan.def_cnt_total%TYPE                                -- 延訪問軒数合計
   ,vend_machine_sales_plan      xxcsm_sales_plan.vend_machine_sales_plan%TYPE                      -- 自販機売上
   ,vend_machine_margin          xxcsm_sales_plan.vend_machine_margin%TYPE                          -- 粗利益
   ,vend_machine_bm              xxcsm_sales_plan.vend_machine_bm%TYPE                              -- 自販機手数料（ＢＭ）
   ,vend_machine_elect           xxcsm_sales_plan.vend_machine_elect%TYPE                           -- 自販機手数料（電気代）
   ,vend_machine_lease           xxcsm_sales_plan.vend_machine_lease%TYPE                           -- 自販機リース料
   ,vend_machine_manage          xxcsm_sales_plan.vend_machine_manage%TYPE                          -- 自販機維持管理料
   ,vend_machine_sup_money       xxcsm_sales_plan.vend_machine_sup_money%TYPE                       -- 協賛金
   ,vend_machine_total           xxcsm_sales_plan.vend_machine_total%TYPE                           -- 費用合計
   ,vend_machine_profit          xxcsm_sales_plan.vend_machine_profit%TYPE                          -- 拠点自販機利益
   ,deficit_num                  xxcsm_sales_plan.deficit_num%TYPE                                  -- 赤字台数
   ,par_machine                  xxcsm_sales_plan.par_machine%TYPE                                  -- パーマシン
   ,possession_num               xxcsm_sales_plan.possession_num%TYPE                               -- 保有台数
   ,stock_num                    xxcsm_sales_plan.stock_num%TYPE                                    -- 在庫台数
   ,operation_num                xxcsm_sales_plan.operation_num%TYPE                                -- 稼働台数
   ,increase                     xxcsm_sales_plan.increase%TYPE                                     -- 純増
   ,new_setting_own              xxcsm_sales_plan.new_setting_own%TYPE                              -- 新規設置（自力）
   ,new_setting_help             xxcsm_sales_plan.new_setting_help%TYPE                             -- 新規設置（他力）
   ,new_setting_total            xxcsm_sales_plan.new_setting_total%TYPE                            -- 新規設置合計
   ,withdraw_num                 xxcsm_sales_plan.withdraw_num%TYPE                                 -- 単独引揚
   ,new_num_newly                xxcsm_sales_plan.new_num_newly%TYPE                                -- 新台（新規）
   ,new_num_replace              xxcsm_sales_plan.new_num_replace%TYPE                              -- 新台（台替）
   ,new_num_total                xxcsm_sales_plan.new_num_total%TYPE                                -- 新台合計
   ,old_num_newly                xxcsm_sales_plan.old_num_newly%TYPE                                -- 旧台（新規）
   ,old_num_replace              xxcsm_sales_plan.old_num_replace%TYPE                              -- 旧台（台替・移設）
   ,disposal_num                 xxcsm_sales_plan.disposal_num%TYPE                                 -- 廃棄
   ,enter_num                    xxcsm_sales_plan.enter_num%TYPE                                    -- 拠点間（移入）
   ,appear_num                   xxcsm_sales_plan.appear_num%TYPE                                   -- 拠点間（移出）
   ,vend_machine_plan_spare_1    xxcsm_sales_plan.vend_machine_plan_spare_1%TYPE                    -- 自動販売機計画（予備１）
   ,vend_machine_plan_spare_2    xxcsm_sales_plan.vend_machine_plan_spare_2%TYPE                    -- 自動販売機計画（予備２）
   ,vend_machine_plan_spare_3    xxcsm_sales_plan.vend_machine_plan_spare_3%TYPE                    -- 自動販売機計画（予備３）
   ,spare_1                      xxcsm_sales_plan.spare_1%TYPE                                      -- 予備１
   ,spare_2                      xxcsm_sales_plan.spare_2%TYPE                                      -- 予備２
   ,spare_3                      xxcsm_sales_plan.spare_3%TYPE                                      -- 予備３
   ,spare_4                      xxcsm_sales_plan.spare_4%TYPE                                      -- 予備４
   ,spare_5                      xxcsm_sales_plan.spare_5%TYPE                                      -- 予備５
   ,spare_6                      xxcsm_sales_plan.spare_6%TYPE                                      -- 予備６
   ,spare_7                      xxcsm_sales_plan.spare_7%TYPE                                      -- 予備７
   ,spare_8                      xxcsm_sales_plan.spare_8%TYPE                                      -- 予備８
   ,spare_9                      xxcsm_sales_plan.spare_9%TYPE                                      -- 予備９
   ,spare_10                     xxcsm_sales_plan.spare_10%TYPE                                     -- 予備１０
   ,cprtn_date                   DATE                                                               -- 連携日時
   );
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理 (A-1)
   ***********************************************************************************/
  PROCEDURE init(
     ov_errbuf           OUT NOCOPY VARCHAR2                                                        -- エラー・メッセージ
    ,ov_retcode          OUT NOCOPY VARCHAR2                                                        -- リターン・コード
    ,ov_errmsg           OUT NOCOPY VARCHAR2                                                        -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)   := 'init';                                         -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf           VARCHAR2(4000);                                                             -- エラー・メッセージ
    lv_retcode          VARCHAR2(1);                                                                -- リターン・コード
    lv_errmsg           VARCHAR2(4000);                                                             -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_appl_short_name  CONSTANT VARCHAR2(10)  := 'XXCCP';                                          -- アプリケーション短縮名
    -- *** ローカル変数 ***
    lv_noprm_msg        VARCHAR2(4000);                                                             -- コンカレント入力パラメータなしメッセージ格納用
    lv_month            VARCHAR2(100);
    lv_msg              VARCHAR2(100);
    lv_tkn_value        VARCHAR2(100);
    -- ファイル存在チェック戻り値用
    lb_retcd            BOOLEAN;
    ln_file_size        NUMBER;
    ln_block_size       NUMBER;
    ld_process_date     DATE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- =================================
    -- 入力パラメータなしメッセージ出力 
    -- =================================
    lv_noprm_msg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name                                       --アプリケーション短縮名
                       ,iv_name         => cv_xxccp_msg_008                                         --メッセージコード
                      );
    --メッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_noprm_msg || CHR(10) ||
                 ''                                                                                 -- 空行の挿入
    );
    -- =======================
    -- プロファイル値取得処理 
    -- =======================
    gv_file_dir   := FND_PROFILE.VALUE(cv_file_dir);
    gv_file_name  := FND_PROFILE.VALUE(cv_file_name);
    -- 年間計画データファイル名をメッセージ出力する
    lv_msg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_app_name                                                     --アプリケーション短縮名
                ,iv_name         => cv_xxcsm_msg_084                                                --メッセージコード
                ,iv_token_name1  => cv_tkn_file_name                                                --トークンコード1
                ,iv_token_value1 => gv_file_name                                                    --トークン値1
              );
    --メッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg || CHR(10) ||
                 ''                                                                                 -- 空行の挿入
    );
--
    -- プロファイル値取得に失敗した場合
    IF (gv_file_dir IS NULL) THEN                                                                   -- CSVファイル出力先取得失敗時
      lv_tkn_value := cv_file_dir;
    ELSIF (gv_file_name IS NULL) THEN                                                               -- CSVファイル名取得失敗時
      lv_tkn_value := cv_file_name;
    END IF;
    -- エラーメッセージ取得
    IF (lv_tkn_value IS NOT NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                                                 --アプリケーション短縮名
                    ,iv_name         => cv_xxcsm_msg_031                                            --メッセージコード
                    ,iv_token_name1  => cv_tkn_prf_name                                             --トークンコード1
                    ,iv_token_value1 => lv_tkn_value                                                --トークン値1
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
    -- ========================
    -- CSVファイル存在チェック 
    -- ========================
    UTL_FILE.FGETATTR(
       location    => gv_file_dir
      ,filename    => gv_file_name
      ,fexists     => lb_retcd
      ,file_length => ln_file_size
      ,block_size  => ln_block_size
    );
--
    -- すでにファイルが存在した場合
    IF (lb_retcd = cb_true) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                                                 --アプリケーション短縮名
                    ,iv_name         => cv_xxcsm_msg_001                                            --メッセージコード
                    ,iv_token_name1  => cv_tkn_directory                                            --トークンコード1
                    ,iv_token_value1 => gv_file_dir                                                 --トークン値1
                    ,iv_token_name2  => cv_tkn_file_name                                            --トークンコード2
                    ,iv_token_value2 => gv_file_name                                                --トークン値2
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
    -- ===========================
    -- システム日付取得処理 
    -- ===========================
    gd_sysdate := SYSDATE;
    -- =====================
    -- 業務処理日付取得処理 
    -- =====================
    ld_process_date := xxccp_common_pkg2.get_process_date;
    -- =====================
    -- 対象予算年度算出処理 
    -- =====================
    xxcsm_common_pkg.get_year_month(iv_process_years => TO_CHAR(ld_process_date,'YYYYMM')
                                   ,ov_year          => gv_obj_year
                                   ,ov_month         => lv_month
                                   ,ov_retcode       => lv_retcode
                                   ,ov_errbuf        => lv_errbuf 
                                   ,ov_errmsg        => lv_errmsg 
                                   );
--
    IF (lv_retcode <> cv_status_normal) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                                                 --アプリケーション短縮名
                    ,iv_name         => cv_xxcsm_msg_021                                            --メッセージコード
                    ,iv_token_name1  => cv_tkn_yyyymm                                               --トークンコード1
                    ,iv_token_value1 => TO_CHAR(ld_process_date,'YYYYMM')                           --トークン値1
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
--
  /**********************************************************************************
   * Procedure Name   : open_csv_file
   * Description      : ファイルオープン処理 (A-4)
   ***********************************************************************************/
  PROCEDURE open_csv_file(
     ov_errbuf         OUT NOCOPY VARCHAR2                                                          -- エラー・メッセージ
    ,ov_retcode        OUT NOCOPY VARCHAR2                                                          -- リターン・コード
    ,ov_errmsg         OUT NOCOPY VARCHAR2                                                          -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'open_csv_file';                                        -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf         VARCHAR2(4000);                                                               -- エラー・メッセージ
    lv_retcode        VARCHAR2(1);                                                                  -- リターン・コード
    lv_errmsg         VARCHAR2(4000);                                                               -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_w              CONSTANT VARCHAR2(1) := 'w';                                                  -- 書込 = w
    cn_max_size       CONSTANT NUMBER := 2047;                                                      -- 2047バイト
--
    -- *** ローカル変数 ***
    -- ファイルオープン確認戻り値格納
    lb_fopn_retcd     BOOLEAN;
    -- *** ローカル例外 ***
    file_err_expt     EXCEPTION;                                                                    -- ファイル処理例外
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
    -- ========================
    -- CSVファイルオープン 
    -- ========================
    BEGIN
      -- ファイルオープン
      gf_file_hand := UTL_FILE.FOPEN(
                         location     => gv_file_dir                                                -- 年間計画ファイルディレクトリ
                        ,filename     => gv_file_name                                               -- 年間計画ファイル名
                        ,open_mode    => cv_w                                                       -- 書込
                        ,max_linesize => cn_max_size                                                -- 2047バイト
                      );
    EXCEPTION
      WHEN OTHERS THEN
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                                               --アプリケーション短縮名
                      ,iv_name         => cv_xxcsm_msg_002                                          --メッセージコード
                      ,iv_token_name1  => cv_tkn_directory                                          --トークンコード1
                      ,iv_token_value1 => gv_file_dir                                               --トークン値1
                      ,iv_token_name2  => cv_tkn_file_name                                          --トークンコード2
                      ,iv_token_value2 => gv_file_name                                              --トークン値2
                      ,iv_token_name3  => cv_tkn_sql_code                                           --トークンコード3
                      ,iv_token_value3 => SQLERRM                                                   --トークン値3
                     );
        lv_errbuf := lv_errmsg;
        RAISE file_err_expt;
    END;
  EXCEPTION
    -- *** ファイル処理例外ハンドラ ***
    WHEN file_err_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file => gf_file_hand
        );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END open_csv_file;
--
  /**********************************************************************************
   * Procedure Name   : create_csv_rec
   * Description      : 販売計画データ書込処理 (A-4)
   ***********************************************************************************/
  PROCEDURE create_csv_rec(
     ir_sales_plan       IN  g_get_data_rtype                                                       -- 販売計画抽出データ
    ,ov_errbuf           OUT NOCOPY VARCHAR2                                                        -- エラー・メッセージ
    ,ov_retcode          OUT NOCOPY VARCHAR2                                                        -- リターン・コード
    ,ov_errmsg           OUT NOCOPY VARCHAR2                                                        -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'create_csv_rec';                              -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf            VARCHAR2(4000);                                                            -- エラー・メッセージ
    lv_retcode           VARCHAR2(1);                                                               -- リターン・コード
    lv_errmsg            VARCHAR2(4000);                                                            -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_sep_com           CONSTANT VARCHAR2(1)  := ',';
    cv_sep_wquot         CONSTANT VARCHAR2(1)  := '"';
--
    -- *** ローカル変数 ***
    lv_data              VARCHAR2(4000);                                                            -- 編集データ格納
--
    -- *** ローカル・レコード ***
    l_sales_plan_rec     g_get_data_rtype;                                                          -- INパラメータ.年間計画データ格納
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- INパラメータをレコード変数に格納
    l_sales_plan_rec := ir_sales_plan; -- 年間計画データ
--
    -- ======================
    -- CSV出力処理 
    -- ======================
      -- データ作成
    lv_data := 
      cv_sep_wquot  || l_sales_plan_rec.company_cd || cv_sep_wquot                                  -- 会社コード
      || cv_sep_com || l_sales_plan_rec.plan_year                                                   -- 年度
      || cv_sep_com || l_sales_plan_rec.plan_ym                                                     -- 年月
      || cv_sep_com ||
      cv_sep_wquot  || l_sales_plan_rec.location_cd || cv_sep_wquot                                 -- 拠点コード
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.act_work_date)                                      -- 実働日
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.plan_staff)                                         -- 計画人員
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.sale_plan_depart)                                   -- 量販店
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.sale_plan_cvs)                                      -- ＣＶＳ
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.sale_plan_dealer)                                   -- 問屋
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.sale_plan_others)                                   -- その他
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.sale_plan_vendor)                                   -- ベンダー
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.sale_plan_total)                                    -- 売上合計
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.sale_plan_spare_1)                                  -- 業態別売上計画（予備１）
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.sale_plan_spare_2)                                  -- 業態別売上計画（予備２）
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.sale_plan_spare_3)                                  -- 業態別売上計画（予備３）
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.ly_revision_depart)                                 -- 前年実績修正（量販店）
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.ly_revision_cvs)                                    -- 前年実績修正（ＣＶＳ）
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.ly_revision_dealer)                                 -- 前年実績修正（問屋）
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.ly_revision_others)                                 -- 前年実績修正（その他）
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.ly_revision_vendor)                                 -- 前年実績修正（ベンダー）
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.ly_revision_spare_1)                                -- 前年実績修正（予備１）
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.ly_revision_spare_2)                                -- 前年実績修正（予備２）
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.ly_revision_spare_3)                                -- 前年実績修正（予備３）
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.ly_exist_total)                                     -- 昨年既存客（全体）
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.ly_newly_total)                                     -- 昨年新規客（全体）
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.ty_first_total)                                     -- 本年新規初回（全体）
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.ty_turn_total)                                      -- 本年新規回転（全体）
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.discount_total)                                     -- 入金値引（全体）
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.ly_exist_vd_charge)                                 -- 昨年既存客（ＶＤ）担当
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.ly_newly_vd_charge)                                 -- 昨年新規客（ＶＤ）担当
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.ty_first_vd_charge)                                 -- 本年新規初回（ＶＤ）担当
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.ty_turn_vd_charge)                                  -- 本年新規回転（ＶＤ）担当
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.ty_first_vd_get)                                    -- 本年新規初回（ＶＤ）獲得
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.ty_turn_vd_get)                                     -- 本年新規回転（ＶＤ）獲得
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.st_mon_get_total)                                   -- 月首顧客数（全体）獲得
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.newly_get_total)                                    -- 新規軒数（全体）獲得
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.cancel_get_total)                                   -- 中止軒数（全体）獲得
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.newly_charge_total)                                 -- 新規軒数（全体）担当
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.st_mon_get_vd)                                      -- 月首顧客数（ＶＤ）獲得
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.newly_get_vd)                                       -- 新規軒数（ＶＤ）獲得
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.cancel_get_vd)                                      -- 中止軒数（ＶＤ）獲得
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.newly_charge_vd_own)                                -- 自力新規軒数（ＶＤ）担当
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.newly_charge_vd_help)                               -- 他力新規軒数（ＶＤ）担当
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.cancel_charge_vd)                                   -- 中止軒数（ＶＤ）担当
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.patrol_visit_cnt)                                   -- 巡回訪問顧客数
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.patrol_def_visit_cnt)                               -- 巡回延訪問軒数
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.vendor_visit_cnt)                                   -- ベンダー訪問顧客数
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.vendor_def_visit_cnt)                               -- ベンダー延訪問軒数
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.public_visit_cnt)                                   -- 一般訪問顧客数
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.public_def_visit_cnt)                               -- 一般延訪問軒数
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.def_cnt_total)                                      -- 延訪問軒数合計
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.vend_machine_sales_plan)                            -- 自販機売上
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.vend_machine_margin)                                -- 粗利益
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.vend_machine_bm)                                    -- 自販機手数料（ＢＭ）
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.vend_machine_elect)                                 -- 自販機手数料（電気代）
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.vend_machine_lease)                                 -- 自販機リース料
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.vend_machine_manage)                                -- 自販機維持管理料
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.vend_machine_sup_money)                             -- 協賛金
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.vend_machine_total)                                 -- 費用合計
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.vend_machine_profit)                                -- 拠点自販機利益
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.deficit_num)                                        -- 赤字台数
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.par_machine)                                        -- パーマシン
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.possession_num)                                     -- 保有台数
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.stock_num)                                          -- 在庫台数
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.operation_num)                                      -- 稼働台数
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.increase)                                           -- 純増
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.new_setting_own)                                    -- 新規設置（自力）
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.new_setting_help)                                   -- 新規設置（他力）
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.new_setting_total)                                  -- 新規設置合計
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.withdraw_num)                                       -- 単独引揚
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.new_num_newly)                                      -- 新台（新規）
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.new_num_replace)                                    -- 新台（台替）
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.new_num_total)                                      -- 新台合計
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.old_num_newly)                                      -- 旧台（新規）
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.old_num_replace)                                    -- 旧台（台替・移設）
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.disposal_num)                                       -- 廃棄
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.enter_num)                                          -- 拠点間（移入）
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.appear_num)                                         -- 拠点間（移出）
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.vend_machine_plan_spare_1)                          -- 自動販売機計画（予備１）
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.vend_machine_plan_spare_2)                          -- 自動販売機計画（予備２）
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.vend_machine_plan_spare_3)                          -- 自動販売機計画（予備３）
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.spare_1)                                            -- 予備１
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.spare_2)                                            -- 予備２
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.spare_3)                                            -- 予備３
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.spare_4)                                            -- 予備４
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.spare_5)                                            -- 予備５
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.spare_6)                                            -- 予備６
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.spare_7)                                            -- 予備７
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.spare_8)                                            -- 予備８
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.spare_9)                                            -- 予備９
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.spare_10)                                           -- 予備１０
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.cprtn_date, 'yyyymmddhh24miss');                    -- 連携日時                                                                                            -- 連携日時
    -- データ出力
    UTL_FILE.PUT_LINE(
      file   => gf_file_hand
     ,buffer => lv_data
    );
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END create_csv_rec;
--
  /**********************************************************************************
   * Procedure Name   : close_csv_file
   * Description      : 年間計画IFファイルクローズ処理処理 (A-5)
   ***********************************************************************************/
  PROCEDURE close_csv_file(
     ov_errbuf         OUT NOCOPY VARCHAR2                                                          -- エラー・メッセージ
    ,ov_retcode        OUT NOCOPY VARCHAR2                                                          -- リターン・コード
    ,ov_errmsg         OUT NOCOPY VARCHAR2                                                          -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'close_csv_file';                                  -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf          VARCHAR2(4000);                                                              -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);                                                                 -- リターン・コード
    lv_errmsg          VARCHAR2(4000);                                                              -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    -- ファイルオープン確認戻り値格納
    lb_fopn_retcd     BOOLEAN;
    -- *** ローカル例外 ***
    file_err_expt     EXCEPTION;                                                                    -- ファイル処理例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ====================
    -- CSVファイルクローズ 
    -- ====================
    BEGIN
      UTL_FILE.FCLOSE(
        file => gf_file_hand
      );
    EXCEPTION
      WHEN OTHERS THEN
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                                               -- アプリケーション短縮名
                      ,iv_name         => cv_xxcsm_msg_003                                          -- メッセージコード
                      ,iv_token_name1  => cv_file_dir                                               -- トークンコード1
                      ,iv_token_value1 => gv_file_dir                                               -- トークン値1
                      ,iv_token_name2  => cv_file_name                                              -- トークンコード1
                      ,iv_token_value2 => gv_file_name                                              -- トークン値1
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE file_err_expt;
    END;
  EXCEPTION
    -- *** ファイル処理例外ハンドラ ***
    WHEN file_err_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END close_csv_file;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   ***********************************************************************************/
  PROCEDURE submain(
     ov_errbuf           OUT NOCOPY VARCHAR2                                                        -- エラー・メッセージ
    ,ov_retcode          OUT NOCOPY VARCHAR2                                                        -- リターン・コード
    ,ov_errmsg           OUT NOCOPY VARCHAR2                                                        -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'submain';                                     -- プログラム名
    cv_company_cd        CONSTANT VARCHAR2(3)     := '001';                                         -- 会社コード
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf            VARCHAR2(4000);                                                            -- エラー・メッセージ
    lv_retcode           VARCHAR2(1);                                                               -- リターン・コード
    lv_errmsg            VARCHAR2(4000);                                                            -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    -- ファイルオープン確認戻り値格納
    lb_fopn_retcd        BOOLEAN;
    -- メッセージ出力用
    lv_msg               VARCHAR2(2000);
--
    -- *** ローカル・カーソル ***
    CURSOR get_sales_plan_cur                                                                       -- 年間計画データ取得カーソル
    IS
      SELECT    xsp.plan_year                       plan_year                                       -- 予算年度
               ,xsp.plan_ym                         plan_ym                                         -- 年月
               ,xsp.location_cd                     location_cd                                     -- 拠点コード
               ,xsp.act_work_date                   act_work_date                                   -- 実働日
               ,xsp.plan_staff                      plan_staff                                      -- 計画人員
               ,xsp.sale_plan_depart                sale_plan_depart                                -- 量販店
               ,xsp.sale_plan_cvs                   sale_plan_cvs                                   -- ＣＶＳ
               ,xsp.sale_plan_dealer                sale_plan_dealer                                -- 問屋
               ,xsp.sale_plan_others                sale_plan_others                                -- その他
               ,xsp.sale_plan_vendor                sale_plan_vendor                                -- ベンダー
               ,xsp.sale_plan_total                 sale_plan_total                                 -- 売上合計
               ,xsp.sale_plan_spare_1               sale_plan_spare_1                               -- 業態別売上計画（予備１）
               ,xsp.sale_plan_spare_2               sale_plan_spare_2                               -- 業態別売上計画（予備２）
               ,xsp.sale_plan_spare_3               sale_plan_spare_3                               -- 業態別売上計画（予備３）
               ,xsp.ly_revision_depart              ly_revision_depart                              -- 前年実績修正（量販店）
               ,xsp.ly_revision_cvs                 ly_revision_cvs                                 -- 前年実績修正（ＣＶＳ）
               ,xsp.ly_revision_dealer              ly_revision_dealer                              -- 前年実績修正（問屋）
               ,xsp.ly_revision_others              ly_revision_others                              -- 前年実績修正（その他）
               ,xsp.ly_revision_vendor              ly_revision_vendor                              -- 前年実績修正（ベンダー）
               ,xsp.ly_revision_spare_1             ly_revision_spare_1                             -- 前年実績修正（予備１）
               ,xsp.ly_revision_spare_2             ly_revision_spare_2                             -- 前年実績修正（予備２）
               ,xsp.ly_revision_spare_3             ly_revision_spare_3                             -- 前年実績修正（予備３）
               ,xsp.ly_exist_total                  ly_exist_total                                  -- 昨年既存客（全体）
               ,xsp.ly_newly_total                  ly_newly_total                                  -- 昨年新規客（全体）
               ,xsp.ty_first_total                  ty_first_total                                  -- 本年新規初回（全体）
               ,xsp.ty_turn_total                   ty_turn_total                                   -- 本年新規回転（全体）
               ,xsp.discount_total                  discount_total                                  -- 入金値引（全体）
               ,xsp.ly_exist_vd_charge              ly_exist_vd_charge                              -- 昨年既存客（ＶＤ）担当
               ,xsp.ly_newly_vd_charge              ly_newly_vd_charge                              -- 昨年新規客（ＶＤ）担当
               ,xsp.ty_first_vd_charge              ty_first_vd_charge                              -- 本年新規初回（ＶＤ）担当
               ,xsp.ty_turn_vd_charge               ty_turn_vd_charge                               -- 本年新規回転（ＶＤ）担当
               ,xsp.ty_first_vd_get                 ty_first_vd_get                                 -- 本年新規初回（ＶＤ）獲得
               ,xsp.ty_turn_vd_get                  ty_turn_vd_get                                  -- 本年新規回転（ＶＤ）獲得
               ,xsp.st_mon_get_total                st_mon_get_total                                -- 月首顧客数（全体）獲得
               ,xsp.newly_get_total                 newly_get_total                                 -- 新規軒数（全体）獲得
               ,xsp.cancel_get_total                cancel_get_total                                -- 中止軒数（全体）獲得
               ,xsp.newly_charge_total              newly_charge_total                              -- 新規軒数（全体）担当
               ,xsp.st_mon_get_vd                   st_mon_get_vd                                   -- 月首顧客数（ＶＤ）獲得
               ,xsp.newly_get_vd                    newly_get_vd                                    -- 新規軒数（ＶＤ）獲得
               ,xsp.cancel_get_vd                   cancel_get_vd                                   -- 中止軒数（ＶＤ）獲得
               ,xsp.newly_charge_vd_own             newly_charge_vd_own                             -- 自力新規軒数（ＶＤ）担当
               ,xsp.newly_charge_vd_help            newly_charge_vd_help                            -- 他力新規軒数（ＶＤ）担当
               ,xsp.cancel_charge_vd                cancel_charge_vd                                -- 中止軒数（ＶＤ）担当
               ,xsp.patrol_visit_cnt                patrol_visit_cnt                                -- 巡回訪問顧客数
               ,xsp.patrol_def_visit_cnt            patrol_def_visit_cnt                            -- 巡回延訪問軒数
               ,xsp.vendor_visit_cnt                vendor_visit_cnt                                -- ベンダー訪問顧客数
               ,xsp.vendor_def_visit_cnt            vendor_def_visit_cnt                            -- ベンダー延訪問軒数
               ,xsp.public_visit_cnt                public_visit_cnt                                -- 一般訪問顧客数
               ,xsp.public_def_visit_cnt            public_def_visit_cnt                            -- 一般延訪問軒数
               ,xsp.def_cnt_total                   def_cnt_total                                   -- 延訪問軒数合計
               ,xsp.vend_machine_sales_plan         vend_machine_sales_plan                         -- 自販機売上
               ,xsp.vend_machine_margin             vend_machine_margin                             -- 粗利益
               ,xsp.vend_machine_bm                 vend_machine_bm                                 -- 自販機手数料（ＢＭ）
               ,xsp.vend_machine_elect              vend_machine_elect                              -- 自販機手数料（電気代）
               ,xsp.vend_machine_lease              vend_machine_lease                              -- 自販機リース料
               ,xsp.vend_machine_manage             vend_machine_manage                             -- 自販機維持管理料
               ,xsp.vend_machine_sup_money          vend_machine_sup_money                          -- 協賛金
               ,xsp.vend_machine_total              vend_machine_total                              -- 費用合計
               ,xsp.vend_machine_profit             vend_machine_profit                             -- 拠点自販機利益
               ,xsp.deficit_num                     deficit_num                                     -- 赤字台数
               ,xsp.par_machine                     par_machine                                     -- パーマシン
               ,xsp.possession_num                  possession_num                                  -- 保有台数
               ,xsp.stock_num                       stock_num                                       -- 在庫台数
               ,xsp.operation_num                   operation_num                                   -- 稼働台数
               ,xsp.increase                        increase                                        -- 純増
               ,xsp.new_setting_own                 new_setting_own                                 -- 新規設置（自力）
               ,xsp.new_setting_help                new_setting_help                                -- 新規設置（他力）
               ,xsp.new_setting_total               new_setting_total                               -- 新規設置合計
               ,xsp.withdraw_num                    withdraw_num                                    -- 単独引揚
               ,xsp.new_num_newly                   new_num_newly                                   -- 新台（新規）
               ,xsp.new_num_replace                 new_num_replace                                 -- 新台（台替）
               ,xsp.new_num_total                   new_num_total                                   -- 新台合計
               ,xsp.old_num_newly                   old_num_newly                                   -- 旧台（新規）
               ,xsp.old_num_replace                 old_num_replace                                 -- 旧台（台替・移設）
               ,xsp.disposal_num                    disposal_num                                    -- 廃棄
               ,xsp.enter_num                       enter_num                                       -- 拠点間（移入）
               ,xsp.appear_num                      appear_num                                      -- 拠点間（移出）
               ,xsp.vend_machine_plan_spare_1       vend_machine_plan_spare_1                       -- 自動販売機計画（予備１）
               ,xsp.vend_machine_plan_spare_2       vend_machine_plan_spare_2                       -- 自動販売機計画（予備２）
               ,xsp.vend_machine_plan_spare_3       vend_machine_plan_spare_3                       -- 自動販売機計画（予備３）
               ,xsp.spare_1                         spare_1                                         -- 予備１
               ,xsp.spare_2                         spare_2                                         -- 予備２
               ,xsp.spare_3                         spare_3                                         -- 予備３
               ,xsp.spare_4                         spare_4                                         -- 予備４
               ,xsp.spare_5                         spare_5                                         -- 予備５
               ,xsp.spare_6                         spare_6                                         -- 予備６
               ,xsp.spare_7                         spare_7                                         -- 予備７
               ,xsp.spare_8                         spare_8                                         -- 予備８
               ,xsp.spare_9                         spare_9                                         -- 予備９
               ,xsp.spare_10                        spare_10                                        -- 予備１０
      FROM      xxcsm_sales_plan                    xsp                                             -- 販売計画テーブル
      WHERE     xsp.plan_year = gv_obj_year
      ORDER BY  xsp.plan_ym                         ASC                                             -- 年月
               ,xsp.location_cd                     ASC;                                            -- 拠点コード
--
    -- *** ローカル・レコード ***
    get_sales_plan_rec   get_sales_plan_cur%ROWTYPE;
    l_get_data_rec       g_get_data_rtype;
    -- *** ローカル例外 ***
    no_data_expt         EXCEPTION;
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
--
    -- ========================================
    -- A-1.初期処理 
    -- ========================================
    init(
       ov_errbuf  => lv_errbuf                                                                      -- エラー・メッセージ
      ,ov_retcode => lv_retcode                                                                     -- リターン・コード
      ,ov_errmsg  => lv_errmsg                                                                      -- ユーザー・エラー・メッセージ
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- A-2.ファイルオープン処理 
    -- =========================================
    open_csv_file(
       ov_errbuf    => lv_errbuf                                                                    -- エラー・メッセージ
      ,ov_retcode   => lv_retcode                                                                   -- リターン・コード
      ,ov_errmsg    => lv_errmsg                                                                    -- ユーザー・エラー・メッセージ
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-3.販売計画データ抽出処理
    -- ========================================
    -- カーソルオープン
    OPEN get_sales_plan_cur;
--
    <<get_data_loop>>                                                                               -- 年間販売計画データ取得LOOP
    LOOP
      FETCH get_sales_plan_cur INTO get_sales_plan_rec;
      -- 処理対象件数格納
      gn_target_cnt := get_sales_plan_cur%ROWCOUNT;
--
      EXIT WHEN get_sales_plan_cur%NOTFOUND
             OR get_sales_plan_cur%ROWCOUNT = 0;
      -- レコード変数初期化
      l_get_data_rec := NULL;
      -- 取得データを格納
      l_get_data_rec.company_cd                := cv_company_cd;                                    -- 会社コード
      l_get_data_rec.plan_year                 := get_sales_plan_rec.plan_year;                     -- 予算年度
      l_get_data_rec.plan_ym                   := get_sales_plan_rec.plan_ym;                       -- 年月
      l_get_data_rec.location_cd               := get_sales_plan_rec.location_cd;                   -- 拠点コード
      l_get_data_rec.act_work_date             := get_sales_plan_rec.act_work_date;                 -- 実働日
      l_get_data_rec.plan_staff                := get_sales_plan_rec.plan_staff;                    -- 計画人員
      l_get_data_rec.sale_plan_depart          := get_sales_plan_rec.sale_plan_depart;              -- 量販店売上計画
      l_get_data_rec.sale_plan_cvs             := get_sales_plan_rec.sale_plan_cvs;                 -- CVS売上計画
      l_get_data_rec.sale_plan_dealer          := get_sales_plan_rec.sale_plan_dealer;              -- 問屋売上計画
      l_get_data_rec.sale_plan_others          := get_sales_plan_rec.sale_plan_others;              -- その他売上計画
      l_get_data_rec.sale_plan_vendor          := get_sales_plan_rec.sale_plan_vendor;              -- ベンダー売上計画
      l_get_data_rec.sale_plan_total           := get_sales_plan_rec.sale_plan_total;               -- 売上計画合計
      l_get_data_rec.sale_plan_spare_1         := get_sales_plan_rec.sale_plan_spare_1;             -- 業態別売上計画（予備１）
      l_get_data_rec.sale_plan_spare_2         := get_sales_plan_rec.sale_plan_spare_2;             -- 業態別売上計画（予備２）
      l_get_data_rec.sale_plan_spare_3         := get_sales_plan_rec.sale_plan_spare_3;             -- 業態別売上計画（予備３）
      l_get_data_rec.ly_revision_depart        := get_sales_plan_rec.ly_revision_depart;            -- 前年実績修正（量販店）
      l_get_data_rec.ly_revision_cvs           := get_sales_plan_rec.ly_revision_cvs;               -- 前年実績修正（CVS）
      l_get_data_rec.ly_revision_dealer        := get_sales_plan_rec.ly_revision_dealer;            -- 前年実績修正（問屋）
      l_get_data_rec.ly_revision_others        := get_sales_plan_rec.ly_revision_others;            -- 前年実績修正（その他）
      l_get_data_rec.ly_revision_vendor        := get_sales_plan_rec.ly_revision_vendor;            -- 前年実績修正（ベンダー）
      l_get_data_rec.ly_revision_spare_1       := get_sales_plan_rec.ly_revision_spare_1;           -- 前年実績修正（予備１）
      l_get_data_rec.ly_revision_spare_2       := get_sales_plan_rec.ly_revision_spare_2;           -- 前年実績修正（予備２）
      l_get_data_rec.ly_revision_spare_3       := get_sales_plan_rec.ly_revision_spare_3;           -- 前年実績修正（予備３）
      l_get_data_rec.ly_exist_total            := get_sales_plan_rec.ly_exist_total;                -- 昨年売上計画_既存客（全体）
      l_get_data_rec.ly_newly_total            := get_sales_plan_rec.ly_newly_total;                -- 昨年売上計画_新規客（全体）
      l_get_data_rec.ty_first_total            := get_sales_plan_rec.ty_first_total;                -- 本年売上計画_新規初回（全体）
      l_get_data_rec.ty_turn_total             := get_sales_plan_rec.ty_turn_total;                 -- 本年売上計画_新規回転（全体）
      l_get_data_rec.discount_total            := get_sales_plan_rec.discount_total;                -- 入金値引（全体）
      l_get_data_rec.ly_exist_vd_charge        := get_sales_plan_rec.ly_exist_vd_charge;            -- 昨年売上計画_既存客（VD）担当ベース
      l_get_data_rec.ly_newly_vd_charge        := get_sales_plan_rec.ly_newly_vd_charge;            -- 昨年売上計画_新規客（VD）担当ベース
      l_get_data_rec.ty_first_vd_charge        := get_sales_plan_rec.ty_first_vd_charge;            -- 本年売上計画_新規初回（VD）担当ベース
      l_get_data_rec.ty_turn_vd_charge         := get_sales_plan_rec.ty_turn_vd_charge;             -- 本年売上計画_新規回転（VD）担当ベース
      l_get_data_rec.ty_first_vd_get           := get_sales_plan_rec.ty_first_vd_get;               -- 本年売上計画_新規初回（VD）獲得ベース
      l_get_data_rec.ty_turn_vd_get            := get_sales_plan_rec.ty_turn_vd_get;                -- 本年売上計画_新規回転（VD）獲得ベース
      l_get_data_rec.st_mon_get_total          := get_sales_plan_rec.st_mon_get_total;              -- 月初顧客数（全体）獲得ベース
      l_get_data_rec.newly_get_total           := get_sales_plan_rec.newly_get_total;               -- 新規軒数（全体）獲得ベース
      l_get_data_rec.cancel_get_total          := get_sales_plan_rec.cancel_get_total;              -- 中止軒数（全体）獲得ベース
      l_get_data_rec.newly_charge_total        := get_sales_plan_rec.newly_charge_total;            -- 新規軒数（全体）担当ベース
      l_get_data_rec.st_mon_get_vd             := get_sales_plan_rec.st_mon_get_vd;                 -- 月初顧客数（VD）獲得ベース
      l_get_data_rec.newly_get_vd              := get_sales_plan_rec.newly_get_vd;                  -- 新規軒数（VD）獲得ベース
      l_get_data_rec.cancel_get_vd             := get_sales_plan_rec.cancel_get_vd;                 -- 中止軒数（VD）獲得ベース
      l_get_data_rec.newly_charge_vd_own       := get_sales_plan_rec.newly_charge_vd_own;           -- 自力新規軒数（VD）担当ベース
      l_get_data_rec.newly_charge_vd_help      := get_sales_plan_rec.newly_charge_vd_help;          -- 他力新規軒数（VD）担当ベース
      l_get_data_rec.cancel_charge_vd          := get_sales_plan_rec.cancel_charge_vd;              -- 中止軒数（VD）担当ベース
      l_get_data_rec.patrol_visit_cnt          := get_sales_plan_rec.patrol_visit_cnt;              -- 巡回訪問顧客数
      l_get_data_rec.patrol_def_visit_cnt      := get_sales_plan_rec.patrol_def_visit_cnt;          -- 巡回延訪問軒数
      l_get_data_rec.vendor_visit_cnt          := get_sales_plan_rec.vendor_visit_cnt;              -- ベンダー訪問顧客数
      l_get_data_rec.vendor_def_visit_cnt      := get_sales_plan_rec.vendor_def_visit_cnt;          -- ベンダー延訪問軒数
      l_get_data_rec.public_visit_cnt          := get_sales_plan_rec.public_visit_cnt;              -- 一般訪問顧客数
      l_get_data_rec.public_def_visit_cnt      := get_sales_plan_rec.public_def_visit_cnt;          -- 一般延訪問軒数
      l_get_data_rec.def_cnt_total             := get_sales_plan_rec.def_cnt_total;                 -- 延訪問軒数合計
      l_get_data_rec.vend_machine_sales_plan   := get_sales_plan_rec.vend_machine_sales_plan;       -- 自販機売上計画
      l_get_data_rec.vend_machine_margin       := get_sales_plan_rec.vend_machine_margin;           -- 自販機計画粗利益
      l_get_data_rec.vend_machine_bm           := get_sales_plan_rec.vend_machine_bm;               -- 自販機手数料（BM）
      l_get_data_rec.vend_machine_elect        := get_sales_plan_rec.vend_machine_elect;            -- 自販機手数料（電気代）
      l_get_data_rec.vend_machine_lease        := get_sales_plan_rec.vend_machine_lease;            -- 自販機リース料
      l_get_data_rec.vend_machine_manage       := get_sales_plan_rec.vend_machine_manage;           -- 自販機維持管理料
      l_get_data_rec.vend_machine_sup_money    := get_sales_plan_rec.vend_machine_sup_money;        -- 自販機計画協賛金
      l_get_data_rec.vend_machine_total        := get_sales_plan_rec.vend_machine_total;            -- 自販機計画費用合計
      l_get_data_rec.vend_machine_profit       := get_sales_plan_rec.vend_machine_profit;           -- 拠点自販機利益
      l_get_data_rec.deficit_num               := get_sales_plan_rec.deficit_num;                   -- 赤字台数
      l_get_data_rec.par_machine               := get_sales_plan_rec.par_machine;                   -- パーマシン
      l_get_data_rec.possession_num            := get_sales_plan_rec.possession_num;                -- 保有台数
      l_get_data_rec.stock_num                 := get_sales_plan_rec.stock_num;                     -- 在庫台数
      l_get_data_rec.operation_num             := get_sales_plan_rec.operation_num;                 -- 稼働台数
      l_get_data_rec.increase                  := get_sales_plan_rec.increase;                      -- 純増
      l_get_data_rec.new_setting_own           := get_sales_plan_rec.new_setting_own;               -- 新規設置台数（自力）
      l_get_data_rec.new_setting_help          := get_sales_plan_rec.new_setting_help;              -- 新規設置台数（他力）
      l_get_data_rec.new_setting_total         := get_sales_plan_rec.new_setting_total;             -- 新規設置台数合計
      l_get_data_rec.withdraw_num              := get_sales_plan_rec.withdraw_num;                  -- 単独引揚台数
      l_get_data_rec.new_num_newly             := get_sales_plan_rec.new_num_newly;                 -- 新台台数（新規）
      l_get_data_rec.new_num_replace           := get_sales_plan_rec.new_num_replace;               -- 新台台数（台替）
      l_get_data_rec.new_num_total             := get_sales_plan_rec.new_num_total;                 -- 新台台数合計
      l_get_data_rec.old_num_newly             := get_sales_plan_rec.old_num_newly;                 -- 旧台台数（新規）
      l_get_data_rec.old_num_replace           := get_sales_plan_rec.old_num_replace;               -- 旧台台数（台替・移設）
      l_get_data_rec.disposal_num              := get_sales_plan_rec.disposal_num;                  -- 廃棄台数
      l_get_data_rec.enter_num                 := get_sales_plan_rec.enter_num;                     -- 拠点間移入台数
      l_get_data_rec.appear_num                := get_sales_plan_rec.appear_num;                    -- 拠点間移出台数
      l_get_data_rec.vend_machine_plan_spare_1 := get_sales_plan_rec.vend_machine_plan_spare_1;     -- 自動販売機計画（予備１）
      l_get_data_rec.vend_machine_plan_spare_2 := get_sales_plan_rec.vend_machine_plan_spare_2;     -- 自動販売機計画（予備２）
      l_get_data_rec.vend_machine_plan_spare_3 := get_sales_plan_rec.vend_machine_plan_spare_3;     -- 自動販売機計画（予備３）
      l_get_data_rec.spare_1                   := get_sales_plan_rec.spare_1;                       -- 予備１
      l_get_data_rec.spare_2                   := get_sales_plan_rec.spare_2;                       -- 予備２
      l_get_data_rec.spare_3                   := get_sales_plan_rec.spare_3;                       -- 予備３
      l_get_data_rec.spare_4                   := get_sales_plan_rec.spare_4;                       -- 予備４
      l_get_data_rec.spare_5                   := get_sales_plan_rec.spare_5;                       -- 予備５
      l_get_data_rec.spare_6                   := get_sales_plan_rec.spare_6;                       -- 予備６
      l_get_data_rec.spare_7                   := get_sales_plan_rec.spare_7;                       -- 予備７
      l_get_data_rec.spare_8                   := get_sales_plan_rec.spare_8;                       -- 予備８
      l_get_data_rec.spare_9                   := get_sales_plan_rec.spare_9;                       -- 予備９
      l_get_data_rec.spare_10                  := get_sales_plan_rec.spare_10;                      -- 予備１０
      l_get_data_rec.cprtn_date                := gd_sysdate;                                       -- 連携日時
--
      -- ========================================
      -- A-4.販売計画データ書込処理
      -- ========================================
      create_csv_rec(
        ir_sales_plan  =>  l_get_data_rec                                                           -- 販売計画計画抽出データ
       ,ov_errbuf      =>  lv_errbuf                                                                -- エラー・メッセージ
       ,ov_retcode     =>  lv_retcode                                                               -- リターン・コード
       ,ov_errmsg      =>  lv_errmsg                                                                -- ユーザー・エラー・メッセージ
      );
      --
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
      -- 正常件数カウントアップ
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP get_data_loop;
--
    -- カーソルクローズ
    CLOSE get_sales_plan_cur;
--
    -- 処理対象件数が0件の場合
    IF (gn_target_cnt = 0) THEN
      -- エラーメッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                                                 --アプリケーション短縮名
                    ,iv_name         => cv_xxcsm_msg_019                                            --メッセージコード
                   );
      lv_errbuf := lv_errmsg;
      RAISE no_data_expt;
    END IF;
--
    -- ========================================
    -- A-5.年間計画I/Fファイルクローズ処理
    -- ========================================
    close_csv_file(
       ov_errbuf    => lv_errbuf                                                                    -- エラー・メッセージ
      ,ov_retcode   => lv_retcode                                                                   -- リターン・コード
      ,ov_errmsg    => lv_errmsg                                                                    -- ユーザー・エラー・メッセージ
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** 処理対象データ0件例外ハンドラ ***
    WHEN no_data_expt THEN
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
--
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
--
      -- カーソルがクローズされていない場合
      IF (get_sales_plan_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_sales_plan_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN--
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      -- カーソルがクローズされていない場合
      IF (get_sales_plan_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_sales_plan_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      -- カーソルがクローズされていない場合
      IF (get_sales_plan_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_sales_plan_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    WHEN global_process_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      -- カーソルがクローズされていない場合
      IF (get_sales_plan_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_sales_plan_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
--
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      -- カーソルがクローズされていない場合
      IF (get_sales_plan_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_sales_plan_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
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
     errbuf        OUT NOCOPY VARCHAR2                                                              -- エラー・メッセージ
    ,retcode       OUT NOCOPY VARCHAR2 )                                                            -- リターン・コード
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';                                            -- プログラム名
    cv_xxcsm           CONSTANT VARCHAR2(100) := 'XXCSM';                                           -- アプリケーション短縮名 
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';                                           -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';                                -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';                                -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';                                -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003';                                -- スキップ件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';                                           -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';                                -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005';                                -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';                                -- エラー終了全ロールバック
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(4000);                                                              -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);                                                                 -- リターン・コード
    lv_errmsg          VARCHAR2(4000);                                                              -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);                                                               -- 終了メッセージコード
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
       ov_errbuf   => lv_errbuf                                                                     -- エラー・メッセージ
      ,ov_retcode  => lv_retcode                                                                    -- リターン・コード
      ,ov_errmsg   => lv_errmsg                                                                     -- ユーザー・エラー・メッセージ
    );
--
    IF (lv_retcode = cv_status_error) THEN
      IF lv_errmsg IS NULL THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcsm
                      ,iv_name         => cv_msg_00111
                     );
      END IF;
      --エラー出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg                                                                        --ユーザー・エラーメッセージ
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf                                                                        --エラーメッセージ
      );
      --件数の振替(エラーの場合、エラー件数を1件のみ表示させる。）
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt := 1;
      gn_warn_cnt := 0;
    END IF;
--
    -- =======================
    -- A-6.終了処理 
    -- =======================
    --空行の出力
    fnd_file.put_line(
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
    fnd_file.put_line(
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
    fnd_file.put_line(
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
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --空行の出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
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
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
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
END XXCSM001A03C;
/
