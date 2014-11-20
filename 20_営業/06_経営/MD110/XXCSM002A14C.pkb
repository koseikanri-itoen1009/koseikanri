CREATE OR REPLACE PACKAGE BODY XXCSM002A14C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM002A14C(body)
 * Description      : 商品計画ヘッダテーブル、及び商品計画明細テーブルより
 *                    対象予算年度の商品計画データを抽出し、情報系システムに
 *                    連携するためのI/Fファイルを作成します。
 * MD.050           : MD050_CSM_002_A14_年間商品計画情報系システムIF
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理 (A-1)
 *  open_csv_file          ファイルオープン処理 (A-2)
 *  create_csv_rec         年間商品計画データファイル作成処理 (A-4)
 *  close_csv_file         ファイルクローズ処理処理 (A-5)
 *  submain                メイン処理プロシージャ
 *                         年間商品計画データ抽出処理 (A-3)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                         終了処理 (A-6)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-01-21    1.0   T.Shimoji       新規作成
 *  2009-07-27    1.1   K.Kubo          ［SCS障害管理番号0000784］対象0件時のハンドリング変更
 *  2011-12-20    1.2   Y.Horikawa       [E_本稼動_08372] 対応 売上値引、入金値引のデータを連携対象に追加
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
  cv_pkg_name             CONSTANT VARCHAR2(100) := 'XXCSM002A14C';                                 -- パッケージ名
  cv_app_name             CONSTANT VARCHAR2(5)   := 'XXCSM';                                        -- アプリケーション短縮名
  -- メッセージコード
  cv_xxccp_msg_008        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008';                             -- コンカレント入力パラメータなし
  cv_xxcsm_msg_001        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00001';                             -- ファイル存在チェックエラーメッセージ
  cv_xxcsm_msg_002        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00002';                             -- ファイルオープンエラーメッセージ
  cv_xxcsm_msg_003        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00003';                             -- ファイルクローズエラーメッセージ
--//+DEL START  2009-07-27 0000784 K.Kubo
--  cv_xxcsm_msg_019        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00019';                             -- 情報系システム連携対象無しエラーメッセージ
--//+DEL END    2009-07-27 0000784 K.Kubo
  cv_xxcsm_msg_021        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00021';                             -- 年度取得エラーメッセージ
  cv_xxcsm_msg_031        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00031';                             -- 定期実行用プロファイル取得エラーメッセージ
  cv_xxcsm_msg_084        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00084';                             -- インターフェースファイル名
  --プロファイル名
  cv_file_dir             CONSTANT VARCHAR2(100) := 'XXCSM1_INFOSYS_FILE_DIR';                      -- 情報系データファイル作成ディレクトリ
  cv_file_name            CONSTANT VARCHAR2(100) := 'XXCSM1_ITEM_PLAN_FILE_NAME';                   -- 年間商品計画データファイル名
  -- トークンコード
  cv_tkn_directory        CONSTANT VARCHAR2(20) := 'DIRECTORY';
  cv_tkn_file_name        CONSTANT VARCHAR2(20) := 'FILE_NAME';
  cv_tkn_prf_name         CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_sql_code         CONSTANT VARCHAR2(20) := 'SQL_CODE';
  cv_tkn_count            CONSTANT VARCHAR2(20) := 'COUNT';
  cv_tkn_yyyymm           CONSTANT VARCHAR2(20) := 'YYYYMM';
  -- 商品計画明細データ取得条件値
  cv_bdgt_kbn_m           CONSTANT VARCHAR2(1)  := '0';                                             -- 年間群予算区分(0:各月単位)
  cv_item_kbn_g           CONSTANT VARCHAR2(1)  := '0';                                             -- 商品区分(0:商品群)
--
  cb_true                 CONSTANT BOOLEAN := TRUE;
-- 2011/12/20 Add Start Ver.1.2
  cv_sales_discount_item_cd    CONSTANT VARCHAR2(100) := 'XXCOS1_DISCOUNT_ITEM_CODE';               -- XXCOS:売上値引品目
  cv_receipt_discount_item_cd  CONSTANT VARCHAR2(100) := 'XXCSM1_RECEIPT_DISCOUNT_ITEM_CODE';       -- XXCSM:入金値引品目
-- 2011/12/20 Add End Ver.1.2
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- ファイル・ハンドルの宣言
  gf_file_hand            UTL_FILE.FILE_TYPE;
  gv_file_dir             VARCHAR2(100);
  gv_file_name            VARCHAR2(100);
  gd_sysdate              DATE;
  gv_budget_year          VARCHAR2(4);
  gv_budget_month         VARCHAR2(2);
-- 2011/12/20 Add Start Ver.1.2
  gv_prf_sales_discnt_item_cd    VARCHAR2(100);
  gv_prf_receipt_discnt_item_cd  VARCHAR2(100);
-- 2011/12/20 Add End Ver.1.2
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- CSV出力データ格納用レコード型定義
  TYPE g_get_data_rtype IS RECORD(
     plan_year            xxcsm_item_plan_headers.plan_year%TYPE                                    -- 予算年度
    ,year_month           xxcsm_item_plan_lines.year_month%TYPE                                     -- 年月
    ,location_cd          xxcsm_item_plan_headers.location_cd%TYPE                                  -- 拠点コード
    ,item_no              xxcsm_item_plan_lines.item_no%TYPE                                        -- 商品コード
    ,amount               xxcsm_item_plan_lines.amount%TYPE                                         -- 数量
    ,sales_budget         xxcsm_item_plan_lines.sales_budget%TYPE                                   -- 売上金額
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
    cv_appl_short_name   CONSTANT VARCHAR2(10)  := 'XXCCP';                                         -- アプリケーション短縮名
    cn_next_day          CONSTANT NUMBER := 1;                                                      -- 翌営業日
    -- *** ローカル変数 ***
    lv_noprm_msg         VARCHAR2(4000);                                                            -- コンカレント入力パラメータなしメッセージ格納用
    lv_month             VARCHAR2(100);
    lv_msg               VARCHAR2(100);
    lv_tkn_value         VARCHAR2(100);
    -- ファイル存在チェック戻り値用
    lb_retcd             BOOLEAN;
    ln_file_size         NUMBER;
    ln_block_size        NUMBER;
    ld_process_date      DATE;
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
       which  => FND_FILE.LOG
      ,buff   => lv_noprm_msg || CHR(10) ||
                 ''                                                                                 -- 空行の挿入
    );
    --
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_noprm_msg || CHR(10) ||
                 ''                                                                                 -- 空行の挿入
    );
    -- =======================
    -- プロファイル値取得処理
    -- =======================
-- 2011/12/20 Add Start Ver.1.2
    -- 売上値引品目取得
    gv_prf_sales_discnt_item_cd := FND_PROFILE.VALUE(cv_sales_discount_item_cd);
    -- プロファイル値取得に失敗した場合
    IF (gv_prf_sales_discnt_item_cd IS NULL) THEN
      -- エラーメッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name                                                   --アプリケーション短縮名
                  ,iv_name         => cv_xxcsm_msg_031                                              --メッセージコード
                  ,iv_token_name1  => cv_tkn_prf_name                                               --トークンコード1
                  ,iv_token_value1 => cv_sales_discount_item_cd                                     --トークン値1
                 );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
    -- 入金値引品目取得
    gv_prf_receipt_discnt_item_cd := FND_PROFILE.VALUE(cv_receipt_discount_item_cd);
    -- プロファイル値取得に失敗した場合
    IF (gv_prf_receipt_discnt_item_cd IS NULL) THEN
      -- エラーメッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name                                                   --アプリケーション短縮名
                  ,iv_name         => cv_xxcsm_msg_031                                              --メッセージコード
                  ,iv_token_name1  => cv_tkn_prf_name                                               --トークンコード1
                  ,iv_token_value1 => cv_receipt_discount_item_cd                                   --トークン値1
                 );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
-- 2011/12/20 Add End Ver.1.2
    -- 情報系データファイル作成ディレクトリ名取得
    gv_file_dir   := FND_PROFILE.VALUE(cv_file_dir);
    -- プロファイル値取得に失敗した場合
    IF (gv_file_dir IS NULL) THEN                                                                   -- CSVファイル出力先取得失敗時
      -- エラーメッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name                                                   --アプリケーション短縮名
                  ,iv_name         => cv_xxcsm_msg_031                                              --メッセージコード
                  ,iv_token_name1  => cv_tkn_prf_name                                               --トークンコード1
                  ,iv_token_value1 => cv_file_dir                                                   --トークン値1
                 );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
    -- 年間商品計画データファイル名取得
    gv_file_name  := FND_PROFILE.VALUE(cv_file_name);
    -- プロファイル値取得に失敗した場合
    IF (gv_file_name IS NULL) THEN                                                                  -- CSVファイル出力先取得失敗時
      -- エラーメッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name                                                   --アプリケーション短縮名
                  ,iv_name         => cv_xxcsm_msg_031                                              --メッセージコード
                  ,iv_token_name1  => cv_tkn_prf_name                                               --トークンコード1
                  ,iv_token_value1 => cv_file_name                                                  --トークン値1
                 );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
    -- 年間商品計画データファイル名をメッセージ出力する
    lv_msg := xxccp_common_pkg.get_msg(
             iv_application  => cv_app_name                                                         --アプリケーション短縮名
            ,iv_name         => cv_xxcsm_msg_084                                                    --メッセージコード
            ,iv_token_name1  => cv_tkn_file_name                                                    --トークンコード1
            ,iv_token_value1 => gv_file_name                                                        --トークン値1
          );
    --メッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg || CHR(10) ||
                 ''                                                                                 -- 空行の挿入
    );
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
    -- すでにファイルが存在する場合
    IF (lb_retcd = cb_true) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name                                                   --アプリケーション短縮名
                  ,iv_name         => cv_xxcsm_msg_001                                              --メッセージコード
                  ,iv_token_name1  => cv_tkn_directory                                              --トークンコード1
                  ,iv_token_value1 => gv_file_dir                                                   --トークン値1
                  ,iv_token_name2  => cv_tkn_file_name                                              --トークンコード2
                  ,iv_token_value2 => gv_file_name                                                  --トークン値2
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
    -- 年度・月の算出
    -- =====================
    xxcsm_common_pkg.get_year_month(
         iv_process_years   => TO_CHAR(ld_process_date,'YYYYMM')                                    -- 年月
        ,ov_year            => gv_budget_year                                                       -- 取得予算年度
        ,ov_month           => gv_budget_month                                                      -- 取得予算月
        ,ov_retcode         => lv_retcode                                                           -- リターンコード
        ,ov_errbuf          => lv_errbuf                                                            -- エラーメッセージ
        ,ov_errmsg          => lv_errmsg                                                            -- ユーザー・エラーメッセージ
    );
    -- 予算年度取得エラー場合
    IF (lv_retcode <> cv_status_normal) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name                                                   --アプリケーション短縮名
                  ,iv_name         => cv_xxcsm_msg_021                                              --メッセージコード
                  ,iv_token_name1  => cv_tkn_yyyymm                                                 --トークンコード1
                  ,iv_token_value1 => TO_CHAR(ld_process_date,'YYYYMM')                             --トークン値1
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
  /**********************************************************************************
   * Procedure Name   : open_csv_file
   * Description      : ファイルオープン処理 (A-2)
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
    cv_prg_name       CONSTANT VARCHAR2(100) := 'open_csv_file';                                    -- プログラム名
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
    -- ========================
    -- CSVファイルオープン
    -- ========================
    BEGIN
      -- ファイルオープン
      gf_file_hand := UTL_FILE.FOPEN(
                         location     => gv_file_dir                                                -- 情報系データファイルディレクトリ
                        ,filename     => gv_file_name                                               -- 年間商品計画データファイル名
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
   * Description      : 年間商品計画データファイル作成処理 (A-4)
   ***********************************************************************************/
  PROCEDURE create_csv_rec(
     ir_plan_item        IN  g_get_data_rtype                                                       -- 年間商品計画データ
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
    cv_sep_com           CONSTANT VARCHAR2(1)  := ',';                                              -- 区切り文字
    cv_sep_wquot         CONSTANT VARCHAR2(1)  := '"';                                              -- 囲み文字
    cv_company_cd        CONSTANT VARCHAR2(3)  := '001';                                            -- 会社コード
    -- *** ローカル変数 ***
    lv_data              VARCHAR2(4000);                                                            -- 編集データ格納
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ======================
    -- CSV出力処理
    -- ======================
    -- データ作成
    lv_data :=
      cv_sep_wquot  || cv_company_cd         || cv_sep_wquot                         -- 会社コード
      || cv_sep_com || TO_CHAR(ir_plan_item.plan_year)                               -- 予算年度
      || cv_sep_com || TO_CHAR(ir_plan_item.year_month)                              -- 年月
      || cv_sep_com ||
      cv_sep_wquot  || ir_plan_item.location_cd || cv_sep_wquot                      -- 拠点コード
      || cv_sep_com ||
      cv_sep_wquot  || ir_plan_item.item_no     || cv_sep_wquot                      -- 商品コード
      || cv_sep_com || TO_CHAR(ir_plan_item.amount)                                  -- 数量
      || cv_sep_com || TO_CHAR(ir_plan_item.sales_budget)                            -- 売上金額
      || cv_sep_com || TO_CHAR(gd_sysdate, 'yyyymmddhh24miss');                      -- 連携日時                                                                                            -- 連携日時
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
   * Description      : ファイルクローズ処理処理 (A-5)
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
-- 2011/12/20 Add Start Ver.1.2
    -- *** ローカル定数 ***
    cn_qty_of_discount_item  CONSTANT NUMBER := 0;  -- 値引品目に対する数量
    cn_no_discount           CONSTANT NUMBER := 0;  -- 値引無し
-- 2011/12/20 Add End Ver.1.2
    -- *** ローカル変数 ***
    -- ファイルオープン確認戻り値格納
    lb_fopn_retcd        BOOLEAN;
    -- メッセージ出力用
    lv_msg               VARCHAR2(2000);
    -- *** ローカル・カーソル ***
    CURSOR get_item_plan_cur                                                              -- 年間商品計画データ取得
    IS
      SELECT    xiph.plan_year             AS  plan_year                                  -- 予算年度
               ,xipl.year_month            AS  year_month                                 -- 年月
               ,xiph.location_cd           AS  location_cd                                -- 拠点コード
               ,xipl.item_no               AS  item_no                                    -- 商品コード
               ,xipl.amount                AS  amount                                     -- 数量
               ,xipl.sales_budget          AS  sales_budget                               -- 売上金額
      FROM      xxcsm_item_plan_headers  xiph                                             --『商品計画ヘッダテーブル』
               ,xxcsm_item_plan_lines    xipl                                             --『商品計画明細テーブル』
      WHERE     xiph.item_plan_header_id = xipl.item_plan_header_id                       -- 商品計画ヘッダID
        AND     xiph.plan_year           = TO_NUMBER(gv_budget_year)                      -- 予算年度
        AND     xipl.year_bdgt_kbn       = cv_bdgt_kbn_m                                  -- 年間群予算区分(0:各月単位)
        AND     xipl.item_kbn           <> cv_item_kbn_g                                  -- 商品区分(0:商品群)以外
-- 2011/12/20 Add Start Ver.1.2
      UNION ALL
      SELECT    xiph.plan_year                AS plan_year                                -- 予算年度
               ,xiplb.year_month              AS year_month                               -- 年月
               ,xiph.location_cd              AS location_cd                              -- 拠点コード
               ,gv_prf_sales_discnt_item_cd   AS item_no                                  -- 商品コード
               ,cn_qty_of_discount_item       AS amount                                   -- 数量
               ,xiplb.sales_discount          AS sales_budget                             -- 売上金額（売上値引額）
      FROM      xxcsm_item_plan_headers  xiph                                             -- 商品計画ヘッダテーブル
               ,xxcsm_item_plan_loc_bdgt xiplb                                            -- 商品計画拠点別予算テーブル
      WHERE     xiplb.item_plan_header_id = xiph.item_plan_header_id                      -- ヘッダIDで関連付け
      AND       xiph.plan_year            = TO_NUMBER(gv_budget_year)                     -- 商品計画ヘッダテーブル．予算年度 ＝ A-1で取得した年度
      AND       xiplb.sales_discount     <> cn_no_discount                                -- 商品計画拠点別予算テーブル．売上値引 <> 0
      UNION ALL
      SELECT    xiph.plan_year                AS plan_year                                -- 予算年度
               ,xiplb.year_month              AS year_month                               -- 年月
               ,xiph.location_cd              AS location_cd                              -- 拠点コード
               ,gv_prf_receipt_discnt_item_cd AS item_no                                  -- 商品コード
               ,cn_qty_of_discount_item       AS amount                                   -- 数量
               ,xiplb.receipt_discount        AS sales_budget                             -- 売上金額（入金値引額）
      FROM      xxcsm_item_plan_headers  xiph                                             -- 商品計画ヘッダテーブル
               ,xxcsm_item_plan_loc_bdgt xiplb                                            -- 商品計画拠点別予算テーブル
      WHERE     xiplb.item_plan_header_id = xiph.item_plan_header_id                      -- ヘッダIDで関連付け
      AND       xiph.plan_year            = TO_NUMBER(gv_budget_year)                     -- 商品計画ヘッダテーブル．予算年度 ＝ A-1で取得した年度
      AND       xiplb.receipt_discount   <> cn_no_discount                                -- 商品計画拠点別予算テーブル．入金値引 <> 0
-- 2011/12/20 Add End Ver.1.2
-- 2011/12/20 Mod Start Ver.1.2
--      ORDER BY  xipl.year_month                                                           -- ソート条件:年月
--               ,xiph.location_cd                                                          --   拠点コード
--               ,xipl.item_no                                                              --   商品コード
      ORDER BY  year_month                                                                -- ソート条件:年月
               ,location_cd                                                               --   拠点コード
               ,item_no                                                                   --   商品コード
-- 2011/12/20 Mod End Ver.1.2
      ;
    -- *** ローカル・レコード ***
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
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
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
    -- ========================================
    -- A-3.年間商品計画データ取得処理
    -- ========================================
    -- カーソルオープン
    OPEN get_item_plan_cur;
    -- 年間商品計画データ取得LOOP
    <<get_data_loop>>
    LOOP
      FETCH get_item_plan_cur INTO l_get_data_rec;
      EXIT WHEN get_item_plan_cur%NOTFOUND;
      -- 処理対象件数格納
      gn_target_cnt := get_item_plan_cur%ROWCOUNT;
      --
      -- ========================================
      -- A-4.年間商品計画データファイル作成処理
      -- ========================================
      create_csv_rec(
        ir_plan_item   =>  l_get_data_rec                                                           -- 年間商品計画データ
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
    END LOOP get_data_loop;
    -- カーソルクローズ
    CLOSE get_item_plan_cur;
--//+DEL START  2009-07-27 0000784 K.Kubo
--    -- 処理対象件数が0件の場合
--    IF (gn_target_cnt = 0) THEN
--      -- エラーメッセージ取得
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_app_name                                                 --アプリケーション短縮名
--                    ,iv_name         => cv_xxcsm_msg_019                                            --メッセージコード
--                   );
--      lv_errbuf := lv_errmsg;
--      RAISE no_data_expt;
--    END IF;
--//+DEL END    2009-07-27 0000784 K.Kubo
    -- ========================================
    -- A-5.ファイルクローズ処理
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
--//+DEL START  2009-07-27 0000784 K.Kubo
--    -- *** 処理対象データ0件例外ハンドラ ***
--    WHEN no_data_expt THEN
--      -- エラー件数カウント
--      gn_error_cnt := gn_error_cnt + 1;
--      --
--      lb_fopn_retcd := UTL_FILE.IS_OPEN (
--                         file =>gf_file_hand
--                       );
--      -- ファイルがクローズされていない場合
--      IF (lb_fopn_retcd = cb_true) THEN
--        -- ファイルクローズ
--        UTL_FILE.FCLOSE(
--          file =>gf_file_hand
--        );
--      END IF;
--      -- カーソルがクローズされていない場合
--      IF (get_item_plan_cur%ISOPEN) THEN
--        -- カーソルクローズ
--        CLOSE get_item_plan_cur;
--      END IF;
--      --
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
--      ov_retcode := cv_status_error;
--//+DEL END    2009-07-27 0000784 K.Kubo
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
      IF (get_item_plan_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_item_plan_cur;
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
      IF (get_item_plan_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_item_plan_cur;
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
      IF (get_item_plan_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_item_plan_cur;
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
      IF (get_item_plan_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_item_plan_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END submain;
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
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';                                -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005';                                -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';                                -- エラー終了全ロールバック
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';                                           -- 件数メッセージ用トークン名
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
    --空行の出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
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
END XXCSM002A14C;
/
