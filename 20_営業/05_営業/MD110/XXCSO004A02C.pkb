CREATE OR REPLACE PACKAGE BODY APPS.XXCSO004A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO004A02C(body)
 * Description      : EBS(ファイルアップロードI/F)に取込まれた拠点別営業人員一覧
 *                    データを拠点別営業人員（アドオン）に取込みます。
 *                    
 * MD.050           : MD050_CSO_004_A02_拠点別営業人員一覧格納
 *                    
 * Version          : 1.2
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  init                        初期処理                                        (A-1)
 *  get_dept_sales_stff_data    拠点別営業人員一覧抽出                          (A-2)
 *  data_proper_check           データ妥当性チェック                            (A-4)
 *  chk_mst_is_exists           マスタ存在チェック                              (A-5)
 *  chk_dept_sales_stff         同一拠点別営業人員抽出                          (A-6)
 *  insert_dept_sales_stff      拠点別営業人員登録                              (A-8)
 *  update_dept_sales_stff      拠点別営業人員更新                              (A-7)
 *  delete_if_data              ファイルデータ削除処理                          (A-9)
 *  submain                     メイン処理プロシージャ(
 *                                セーブポイント設定                            (A-3)
 *                              )
 *  main                        コンカレント実行ファイル登録プロシージャ(
 *                                終了処理                                      (A-10)
 *                              )
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-02-17    1.0   kyo     新規作成
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897対応
 *  2011-02-07    1.2   N.Horigome       E_本稼動_02682対応
 *
 *****************************************************************************************/
-- 
-- #######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
  -- WHOカラム
  cn_created_by             CONSTANT NUMBER := fnd_global.user_id;         -- CREATED_BY
  cd_creation_date          CONSTANT DATE   := SYSDATE;                    -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER := fnd_global.user_id;         -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE   := SYSDATE;                    -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER := fnd_global.conc_program_id; -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE   := SYSDATE;                    -- PROGRAM_UPDATE_DATE
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
-- #######################  固定グローバル定数宣言部 END   #########################
--
-- #######################  固定グローバル変数宣言部 START #########################
--
  gv_out_msg             VARCHAR2(2000);
  gn_target_cnt          NUMBER;                    -- 対象件数
  gn_normal_cnt          NUMBER;                    -- 正常件数
  gn_error_cnt           NUMBER;                    -- エラー件数
--
-- #######################  固定グローバル変数宣言部 END   #########################
--
-- #######################  固定共通例外宣言部 START       #########################
--
  --*** 処理部共通例外 ***
  global_process_expt    EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt        EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
-- #######################  固定共通例外宣言部 END         #########################
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO004A02C';      -- パッケージ名
  cv_app_name            CONSTANT VARCHAR2(5)   := 'XXCSO';             -- アプリケーション短縮名
--
  cv_comma               CONSTANT VARCHAR2(1)   := ',';
--
  -- メッセージコード
  -- 初期処理エラー
  cv_tkn_number_01       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00256';  -- パラメータNULLエラー
  cv_tkn_number_02       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011';  -- 業務処理日付取得エラー
  cv_tkn_number_03       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00428';  -- 年度抽取得エラー
  -- データ処理エラー（ファイルアップロードI/Fテーブル）
  cv_tkn_number_04       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00035';  -- ロックエラー
  cv_tkn_number_05       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00259';  -- データ抽出エラー(ファイルアップロードI/Fテーブル)
  cv_tkn_number_06       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00270';  -- データ削除エラー
  -- データチェックエラー
  cv_tkn_number_07       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00262';  -- 拠点別営業人員一覧フォーマットチェックエラー
  cv_tkn_number_08       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00265';  -- 必須チェックエラー
  cv_tkn_number_09       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00266';  -- 半角英数チェックエラー
  cv_tkn_number_10       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00267';  -- サイズチェックエラー
  cv_tkn_number_11       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00263';  -- DATE型チェックエラー
  cv_tkn_number_12       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00429';  -- 年度不一致チェックエラー
  cv_tkn_number_13       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00264';  -- 年度内チェックエラー
  cv_tkn_number_14       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00268';  -- マイナス値エラー
  cv_tkn_number_15       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00261';  -- マスタチェックエラー
  -- データ処理エラー（拠点別営業人員）
  cv_tkn_number_16       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00258';  -- ロックエラー
  cv_tkn_number_17       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00260';  -- 拠点別営業人員データ抽出エラー
  cv_tkn_number_18       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00427';  -- データ登録エラー
  cv_tkn_number_19       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00269';  -- データ更新エラー
--
  -- コンカレントパラメータ関連
  cv_tkn_number_20       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00271';  -- パラメータファイルID
  cv_tkn_number_21       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00152';  -- パラメータ出力CSVファイル名
  cv_tkn_number_22       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00274';  -- ファイルアップロード名称抽出エラー
  cv_tkn_number_23       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00276';  -- ファイルアップロード名称
  cv_tkn_number_24       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00275';  -- パラメータフォーマットパターン
--
  cv_tkn_number_25       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00497';  -- AFF部門マスタビュー抽出エラー
--
  /* 2011.02.07 N.Horigome E_本稼動_02682 START */
  cv_tkn_number_26       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00609';  -- 会計期間クローズエラー
--
  /* 2011.02.07 N.Horigome E_本稼動_02682 END */
  -- トークンコード
  cv_tkn_tbl             CONSTANT VARCHAR2(20) := 'TABLE';
  cv_tkn_item            CONSTANT VARCHAR2(20) := 'ITEM';
  cv_tkn_file_id         CONSTANT VARCHAR2(20) := 'FILE_ID';
  cv_tkn_base_val        CONSTANT VARCHAR2(20) := 'BASE_VALUE';  
  cv_tkn_loc             CONSTANT VARCHAR2(20) := 'LOCATION';
  cv_tkn_year_month      CONSTANT VARCHAR2(20) := 'YEARMONTH';  
  cv_tkn_eigyo           CONSTANT VARCHAR2(20) := 'EIGYO';
  cv_tkn_err_msg         CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_csv_file_nm     CONSTANT VARCHAR2(20) := 'CSV_FILE_NAME';
  cv_tkn_file_upload_nm  CONSTANT VARCHAR2(20) := 'UPLOAD_FILE_NAME';
  cv_tkn_fmt_ptn         CONSTANT VARCHAR2(20) := 'FORMAT_PATTERN';
  cv_tkn_cur_year        CONSTANT VARCHAR2(20) := 'CURRENT_YEAR';
  cv_tkn_item_value      CONSTANT VARCHAR2(20) := 'ITEM_VALUE';
--
  -- DEBUG_LOG用メッセージ
  cv_debug_msg1          CONSTANT VARCHAR2(200) := '拠点別営業人員一覧を抽出しました。';
  cv_debug_msg2          CONSTANT VARCHAR2(200) := 'ln_business_year = ';
  cv_debug_msg3          CONSTANT VARCHAR2(200) := 'ファイルデータ削除しました。';
  cv_debug_msg4          CONSTANT VARCHAR2(200) := '<< 業務処理日付取得処理 >>';
  cv_debug_msg5          CONSTANT VARCHAR2(200) := 'ld_process_date = ';
  cv_debug_msg6          CONSTANT VARCHAR2(200) := 'ロールバックしました。';
  /* 2011.02.07 N.Horigome E_本稼動_02682 START */
  cv_debug_msg7          CONSTANT VARCHAR2(200) := 'ln_business_pre_year = ';
  /* 2011.02.07 N.Horigome E_本稼動_02682 END   */
--
  -- CSVファイル中の項目順番
  cn_fscl_year_num       CONSTANT NUMBER       := 1;                  -- 年度
  cn_year_mnth_num       CONSTANT NUMBER       := 2;                  -- 年月
  cn_base_code_num       CONSTANT NUMBER       := 3;                  -- 拠点コード
  cn_sales_sff_num       CONSTANT NUMBER       := 5;                  -- 営業人員
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- 拠点別営業人員情報抽出データ構造体
  TYPE g_dept_sales_stff_rtype IS RECORD(
     fiscal_year            xxcso_dept_sales_staffs.fiscal_year%TYPE   -- 年度
    ,year_month             xxcso_dept_sales_staffs.year_month%TYPE    -- 年月
    ,base_code              xxcso_dept_sales_staffs.base_code%TYPE     -- 拠点コード
    ,sales_staff            xxcso_dept_sales_staffs.sales_staff%TYPE   -- 営業人員
  );
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  -- 新規登録フラグ(TRUE：登録、FALSE：更新)
  gb_insert_process_flg    BOOLEAN;
  -- ロールバック判断
  gb_rollback_upd_flg      BOOLEAN;
  -- ファイルデータ
  g_file_data_tab          xxccp_common_pkg2.g_file_data_tbl;
  -- 拠点別営業人員情報抽出
  g_dept_sales_stff_rec    g_dept_sales_stff_rtype;
  -- ファイルID
  gt_file_id               xxccp_mrp_file_ul_interface.file_id%TYPE;
  -- フォーマットパターン 
  gv_fmt_ptn               VARCHAR2(20);
--  
  -- *** ユーザー定義グローバル例外 ***
  global_skip_error_expt   EXCEPTION;  -- スキップ例外
  global_lock_expt         EXCEPTION;  -- ロック例外
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理 (A-1)
   ***********************************************************************************/
--
  PROCEDURE init(
     od_process_date            OUT NOCOPY DATE       -- 業務処理日付
    ,on_process_year            OUT NOCOPY NUMBER     -- 現在年度
    /* 2011.02.07 N.Horigome E_本稼動_02682 START */
    ,on_pre_year                OUT NOCOPY NUMBER     -- 前月年度
    /* 2011.02.07 N.Horigome E_本稼動_02682 END   */
    ,ov_errbuf                  OUT NOCOPY VARCHAR2   -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode                 OUT NOCOPY VARCHAR2   -- リターン・コード              -- # 固定 #
    ,ov_errmsg                  OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                 CONSTANT VARCHAR2(100)   := 'init';     -- プログラム名
--
-- #####################  固定ローカル変数宣言部 START     #########################
--
    lv_errbuf                   VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode                  VARCHAR2(1);     -- リターン・コード
    lv_errmsg                   VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
-- #####################  固定ローカル変数宣言部 END       #########################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_file_upload_lookup_type  CONSTANT VARCHAR2(100) := 'XXCCP1_FILE_UPLOAD_OBJ';
    cv_dept_sales_lookup_code   CONSTANT VARCHAR2(30)  := '610';
    -- *** ローカル変数 ***
    lv_file_upload_nm           VARCHAR2(30);                   -- ファイルアップロード名称
    lv_current_yymm             VARCHAR2(10);                   -- 現在の年月
    ld_process_date             DATE;                           -- システム日付
    ln_business_year            gl_periods.period_year%TYPE;    -- 年度
    -- コンカレント入力パラメータなしメッセージ格納用
    lv_noprm_msg                VARCHAR2(5000);  
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 入力パラメータメッセージ出力
    -- ファイルIDメッセージ
    lv_noprm_msg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_app_name                -- アプリケーション短縮名
                ,iv_name         => cv_tkn_number_20           -- メッセージコード
                ,iv_token_name1  => cv_tkn_file_id             -- トークンコード1
                ,iv_token_value1 => TO_CHAR(gt_file_id)        -- トークン値1
              );
--
    -- ファイルIDメッセージ出力
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => lv_noprm_msg || CHR(10) || 
                 '' 
    );
    -- ファイルIDログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_noprm_msg || CHR(10) || 
                 '' 
    );
--
    -- フォーマットパターンメッセージ
    lv_noprm_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name             -- アプリケーション短縮名
                   ,iv_name         => cv_tkn_number_24        -- メッセージコード
                   ,iv_token_name1  => cv_tkn_fmt_ptn          -- トークンコード1
                   ,iv_token_value1 => gv_fmt_ptn              -- トークン値1
                 );
--
    -- フォーマットパターンメッセージ出力
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => lv_noprm_msg || CHR(10) || 
                 '' 
    );
    -- フォーマットパターンログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_noprm_msg || CHR(10) || 
                 '' 
    );
--
    -- 入力パラメータファイルIDのNULLチェック
    IF (gt_file_id IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name           -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_01      -- メッセージコード
                   );
      lv_errbuf := lv_errmsg;
--
      RAISE global_process_expt;
    END IF;
--
    -- 業務処理日付取得処理 
    ld_process_date := xxccp_common_pkg2.get_process_date; 
    -- *** DEBUG_LOG ***
    -- 取得した業務処理日付をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg4 || CHR(10) ||
                 cv_debug_msg5 || TO_CHAR(ld_process_date,'yyyy/mm/dd hh24:mi:ss') || CHR(10) ||
                 ''
    );
    -- 業務処理日付取得に失敗した場合
    IF (ld_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name                 -- アプリケーション短縮名
                   ,iv_name         => cv_tkn_number_02            -- メッセージコード
      );
      lv_errbuf  := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    od_process_date := ld_process_date;
--
    BEGIN
      -- ファイルアップロード名称抽出
      lv_file_upload_nm := xxcso_util_common_pkg.get_lookup_meaning(
                           cv_file_upload_lookup_type
                          ,cv_dept_sales_lookup_code
                          ,ld_process_date);
      IF (lv_file_upload_nm IS NULL) THEN
        RAISE global_process_expt;
      END IF;
     -- ファイルアップロード名称メッセージ
      lv_noprm_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name            -- アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_23       -- メッセージコード
                    ,iv_token_name1  => cv_tkn_file_upload_nm  -- トークンコード1
                    ,iv_token_value1 => lv_file_upload_nm      -- トークン値1
                   );
--
      -- ファイルアップロード名称メッセージ出力
      fnd_file.put_line(
         which  => fnd_file.output
        ,buff   => lv_noprm_msg || CHR(10) || 
                   '' 
      );
      -- ログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_noprm_msg || CHR(10) || 
                   '' 
      );
--
    EXCEPTION
      -- ファイルアップロード名称抽出に失敗した場合の後処理
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name         -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_22    -- メッセージコード
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE global_process_expt;
    END;
--
    BEGIN
      lv_current_yymm  := TO_CHAR(ld_process_date, 'YYYYMM');
      -- 現在年度を取得します。
      ln_business_year := xxcso_util_common_pkg.get_business_year(
                           lv_current_yymm
                         );
      IF (ln_business_year IS NULL) THEN
        RAISE global_process_expt;
      END IF;
      on_process_year  := ln_business_year;
      -- ログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg2 || TO_CHAR(ln_business_year) || CHR(10) ||
                   ''
      );
--
    EXCEPTION
      -- 現在年度抽出に失敗した場合の後処理
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name            -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_03       -- メッセージコード
                       ,iv_token_name1  => cv_tkn_year_month      -- トークンコード1
                       ,iv_token_value1 => lv_current_yymm        -- トークン値1
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE global_process_expt;
    END;
--
    /* 2011.02.07 N.Horigome E_本稼動_02682 START */
--
    BEGIN
      lv_current_yymm  := TO_CHAR(ADD_MONTHS(ld_process_date,-1), 'YYYYMM');
      -- 前月年度を取得します。
      ln_business_year := xxcso_util_common_pkg.get_business_year(
                           lv_current_yymm
                         );
      IF (ln_business_year IS NULL) THEN
        RAISE global_process_expt;
      END IF;
      on_pre_year  := ln_business_year;
      -- ログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg7 || TO_CHAR(ln_business_year) || CHR(10) ||
                   ''
      );
--
    EXCEPTION
      -- 前月年度抽出に失敗した場合の後処理
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name            -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_03       -- メッセージコード
                       ,iv_token_name1  => cv_tkn_year_month      -- トークンコード1
                       ,iv_token_value1 => lv_current_yymm        -- トークン値1
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE global_process_expt;
    END;
--    /* 2011.02.07 N.Horigome E_本稼動_02682 END   */
  EXCEPTION
    -- *** 処理例外ハンドラ ***
    WHEN global_process_expt THEN
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
  /**********************************************************************************
   * Procedure Name   : get_dept_sales_stff_data
   * Description      : 拠点別営業人員一覧抽出処理 (A-2)
   ***********************************************************************************/
--
  PROCEDURE get_dept_sales_stff_data(
     ov_errbuf           OUT NOCOPY VARCHAR2             -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2             -- リターン・コード              -- # 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2             -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'get_dept_sales_stff_data';     -- プログラム名
--
-- #####################  固定ローカル変数宣言部 START     #########################
--
    lv_errbuf            VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode           VARCHAR2(1);     -- リターン・コード
    lv_errmsg            VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
-- #####################  固定ローカル変数宣言部 END       #########################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_if_table_nm       CONSTANT VARCHAR2(100)  := 'ファイルアップロードI/Fテーブル';
    -- *** ローカル変数 ***
    lt_file_name         xxccp_mrp_file_ul_interface.file_name%TYPE;          -- ファイル名
    lt_file_content_type xxccp_mrp_file_ul_interface.file_content_type%TYPE;  -- ファイル区分
    lt_file_data         xxccp_mrp_file_ul_interface.file_data%TYPE;          -- ファイルデータ
    lt_file_format       xxccp_mrp_file_ul_interface.file_format%TYPE;        -- ファイルフォーマット
    -- パラメータ出力CSVファイル名メッセージ格納用
    lv_noprm_msg                VARCHAR2(5000);  
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    BEGIN
--
      -- ファイルデータ抽出
      SELECT xmfui.file_name          file_name          -- ファイル名
            ,xmfui.file_content_type  file_content_type  -- ファイル区分
            ,xmfui.file_data          file_date          -- ファイルデータ
            ,xmfui.file_format        file_format        -- ファイルフォーマット
      INTO   lt_file_name             -- ファイル名
            ,lt_file_content_type     -- ファイル区分
            ,lt_file_data             -- ファイルデータ
            ,lt_file_format           -- ファイルフォーマット
      FROM   xxccp_mrp_file_ul_interface  xmfui  -- ファイルアップロードI/Fテーブル
      WHERE  xmfui.file_id = gt_file_id
      FOR UPDATE NOWAIT;  -- テーブルロック
      
--
    EXCEPTION
      -- ロック失敗した場合の例外
      WHEN global_lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name          -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_04     -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl           -- トークンコード1
                       ,iv_token_value1 => cv_if_table_nm       -- トークン値1
                       ,iv_token_name2  => cv_tkn_file_id       -- トークンコード2
                       ,iv_token_value2 => TO_CHAR(gt_file_id)  -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      -- 抽出に失敗した場合の例外
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name          -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_05     -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl           -- トークンコード1
                       ,iv_token_value1 => cv_if_table_nm       -- トークン値1
                       ,iv_token_name2  => cv_tkn_file_id       -- トークンコード2
                       ,iv_token_value2 => TO_CHAR(gt_file_id)  -- トークン値2
                       ,iv_token_name3  => cv_tkn_err_msg       -- トークンコード3
                       ,iv_token_value3 => SQLERRM              -- トークン値3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- BLOBデータ変換関数により行単位データを抽出
    xxccp_common_pkg2.blob_to_varchar2(
       in_file_id   => gt_file_id         -- ファイルID
      ,ov_file_data => g_file_data_tab    -- ファイルデータ
      ,ov_errbuf    => lv_errbuf          -- エラー・メッセージ            -- # 固定 #
      ,ov_retcode   => lv_retcode         -- リターン・コード              -- # 固定 #
      ,ov_errmsg    => lv_errmsg          -- ユーザー・エラー・メッセージ  -- # 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name            -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_05       -- メッセージコード
                     ,iv_token_name1  => cv_tkn_tbl             -- トークンコード1
                     ,iv_token_value1 => cv_if_table_nm         -- トークン値1
                     ,iv_token_name2  => cv_tkn_file_id         -- トークンコード2
                     ,iv_token_value2 => TO_CHAR(gt_file_id)    -- トークン値2
                     ,iv_token_name3  => cv_tkn_err_msg         -- トークンコード2
                     ,iv_token_value3 => lv_errbuf              -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg1 || CHR(10) ||
                 ''
    );
--
    -- CSVファイル名メッセージ
    lv_noprm_msg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name               -- アプリケーション短縮名
                  ,iv_name         => cv_tkn_number_21          -- メッセージコード
                  ,iv_token_name1  => cv_tkn_csv_file_nm        -- トークンコード1
                  ,iv_token_value1 => lt_file_name              -- トークン値1
                 );
--
    -- CSVファイル名メッセージ出力
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => lv_noprm_msg || CHR(10) ||
                 ''
    );
    -- ログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_noprm_msg || CHR(10) ||
                 ''
    );
--
  EXCEPTION
    -- *** 処理例外ハンドラ ***
    WHEN global_process_expt THEN
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
  END get_dept_sales_stff_data;
--
  /**********************************************************************************
   * Procedure Name   : data_proper_check
   * Description      : データ妥当性チェック (A-4)
   ***********************************************************************************/
--
  PROCEDURE data_proper_check(
     iv_base_value         IN  VARCHAR2                 -- 当該行データ
    ,in_process_year       IN  NUMBER                   -- 現在年度
  /* 2011.02.07 N.Horigome E_本稼動_02682 START */
    ,in_pre_year           IN  NUMBER                   -- 前月年度
  /* 2011.02.07 N.Horigome E_本稼動_02682 END   */
    ,ov_errbuf             OUT NOCOPY VARCHAR2          -- エラー・メッセージ           -- # 固定 #
    ,ov_retcode            OUT NOCOPY VARCHAR2          -- リターン・コード             -- # 固定 #
    ,ov_errmsg             OUT NOCOPY VARCHAR2          -- ユーザー・エラー・メッセージ -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(20)   := 'data_proper_check';       -- プログラム名
--
-- #####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf   VARCHAR2(5000);   -- エラー・メッセージ
    lv_retcode  VARCHAR2(1);      -- リターン・コード
    lv_errmsg   VARCHAR2(5000);   -- ユーザー・エラー・メッセージ
--
-- ###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cn_format_col_cnt      CONSTANT NUMBER        := 5;           -- 項目数
    cn_byte_fscl_year      CONSTANT NUMBER        := 4;           -- 年度バイト数
    cn_byte_year_mnth      CONSTANT NUMBER        := 6;           -- 年月バイト数
    cn_byte_base_code      CONSTANT NUMBER        := 4;           -- 拠点コードバイト数
    cn_byte_sales_sff      CONSTANT NUMBER        := 3;           -- 営業人員
    cv_date_fmt            CONSTANT VARCHAR2(100) := 'YYYY/MM';   -- DATE型
    cv_fiscal_year         CONSTANT VARCHAR2(100) := '年度';      -- 年度
    cv_year_month          CONSTANT VARCHAR2(100) := '年月';      -- 年月
    cv_base_code           CONSTANT VARCHAR2(100) := '拠点コード'; -- 拠点コード
    cv_sales_staff         CONSTANT VARCHAR2(100) := '営業人員';   -- 営業人員
    /* 2011.02.07 N.Horigome E_本稼動_02682 START */
    cv_false               CONSTANT VARCHAR2(50)  := 'FALSE';      --FALSE
    /* 2011.02.07 N.Horigome E_本稼動_02682 END */
--
    -- *** ローカル変数 ***
    lv_fiscal_year         VARCHAR2(100);                              -- 年度
    lv_year_month          VARCHAR2(100);                              -- 年月
    lv_base_code           VARCHAR2(100);                              -- 拠点コード
    ln_sales_staff         NUMBER;                                     -- 営業人員
    lv_sales_staff         VARCHAR2(100);                              -- 営業人員
    lv_item_nm             VARCHAR2(100);                              -- 該当項目名
    ln_year                NUMBER;                                     -- (CSV)年月の年
    lb_return              BOOLEAN;                                    -- リターンステータス
    /* 2011.02.07 N.Horigome E_本稼動_02682 START */
    lv_result              VARCHAR2(10);                               -- 会計期間クローズチェック戻り値格納
    /* 2011.02.07 N.Horigome E_本稼動_02682 END   */
--
    lv_tmp                 VARCHAR2(2000);
    ln_pos                 NUMBER;
    ln_cnt                 NUMBER := 1;
    lb_format_flag         BOOLEAN := TRUE;
--
  BEGIN
--
-- ##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
-- ###########################  固定部 END   ############################
--
    -- 項目数を取得
    IF (iv_base_value IS NULL) THEN
      lb_format_flag := FALSE;
    END IF;
--
    IF lb_format_flag THEN
      lv_tmp := iv_base_value;
      LOOP
        ln_pos := INSTR(lv_tmp, cv_comma);
        IF ((ln_pos IS NULL) OR (ln_pos = 0)) THEN
          EXIT;
        ELSE
          ln_cnt := ln_cnt + 1;
          lv_tmp := SUBSTR(lv_tmp, ln_pos + 1);
          ln_pos := 0;
        END IF;
      END LOOP;
    END IF;
--
    -- 1.項目数チェック
    IF ((lb_format_flag = FALSE) OR (ln_cnt <> cn_format_col_cnt)) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name        -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_07   -- メッセージコード
                       ,iv_token_name1  => cv_tkn_base_val    -- トークンコード1
                       ,iv_token_value1 => iv_base_value      -- トークン値1
                     );
        lv_errbuf  := lv_errmsg;
        RAISE global_skip_error_expt;
    END IF;
--
    -- 2.必須項目のNULLチェック
    lv_fiscal_year := REPLACE(xxccp_common_pkg.char_delim_partition(
                                iv_base_value, cv_comma, cn_fscl_year_num), '"');
    lv_year_month  := REPLACE(xxccp_common_pkg.char_delim_partition(
                                iv_base_value, cv_comma, cn_year_mnth_num), '"');
    lv_base_code   := REPLACE(xxccp_common_pkg.char_delim_partition(
                                iv_base_value, cv_comma, cn_base_code_num), '"');
    lv_sales_staff := REPLACE(xxccp_common_pkg.char_delim_partition(
                                iv_base_value, cv_comma, cn_sales_sff_num), '"');
--
    lb_return  := TRUE;
    lv_item_nm := '';
--
    IF lv_fiscal_year IS NULL THEN
      -- 年度
      lb_return  := FALSE;
      lv_item_nm := cv_fiscal_year;
    ELSIF lv_year_month IS NULL THEN
      -- 年月
      lb_return  := FALSE;
      lv_item_nm := cv_year_month;
    ELSIF lv_base_code IS NULL THEN
      -- 拠点コード
      lb_return  := FALSE;
      lv_item_nm := cv_base_code;
    ELSIF lv_sales_staff IS NULL THEN
      -- 営業人員
      lb_return  := FALSE;
      lv_item_nm := cv_sales_staff;
    END IF;
--
    IF (lb_return = FALSE) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name        -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_08   -- メッセージコード
                     ,iv_token_name1  => cv_tkn_item        -- トークンコード1
                     ,iv_token_value1 => lv_item_nm         -- トークン値1
                     ,iv_token_name2  => cv_tkn_base_val    -- トークンコード2
                     ,iv_token_value2 => iv_base_value      -- トークン値2
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_skip_error_expt;
    END IF;
--
    -- 3. サイズチェック
    IF (LENGTHB(lv_fiscal_year) <> cn_byte_fscl_year) THEN
      -- 年度
      lb_return  := FALSE;
      lv_item_nm := cv_fiscal_year;
    ELSIF (LENGTHB(lv_year_month) <> cn_byte_year_mnth) THEN
      -- 年月
      lb_return  := FALSE;
      lv_item_nm := cv_year_month;
    ELSIF (LENGTHB(lv_base_code) <> cn_byte_base_code) THEN
      -- 拠点コード
      lb_return  := FALSE;
      lv_item_nm := cv_base_code;
    ELSIF (LENGTHB(lv_sales_staff) > cn_byte_sales_sff) THEN
      -- 営業人員
      lb_return  := FALSE;
      lv_item_nm := cv_sales_staff;
    END IF;
--
    IF (lb_return = FALSE) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name        -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_10   -- メッセージコード
                     ,iv_token_name1  => cv_tkn_item        -- トークンコード1
                     ,iv_token_value1 => lv_item_nm         -- トークン値1
                     ,iv_token_name2  => cv_tkn_base_val    -- トークンコード2
                     ,iv_token_value2 => iv_base_value      -- トークン値2
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_skip_error_expt;
    END IF;
--    
    -- 4. 半角数値型チェック
    IF (xxccp_common_pkg.chk_number(lv_fiscal_year) = FALSE) THEN
      -- 年度
      lb_return  := FALSE;
      lv_item_nm := cv_fiscal_year;
    ELSIF (xxccp_common_pkg.chk_number(lv_year_month) = FALSE) THEN
      -- 年月
      lb_return  := FALSE;
      lv_item_nm := cv_year_month;
    ELSIF (xxccp_common_pkg.chk_number(lv_base_code) = FALSE) THEN
      -- 拠点コード
      lb_return  := FALSE;
      lv_item_nm := cv_base_code;
    ELSIF (xxccp_common_pkg.chk_number(lv_sales_staff) = FALSE) THEN
      -- 営業人員
      lb_return  := FALSE;
      lv_item_nm := cv_sales_staff;
    END IF;
--
    IF (lb_return = FALSE) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name        -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_09   -- メッセージコード
                     ,iv_token_name1  => cv_tkn_item        -- トークンコード1
                     ,iv_token_value1 => lv_item_nm         -- トークン値1
                     ,iv_token_name2  => cv_tkn_base_val    -- トークンコード2
                     ,iv_token_value2 => iv_base_value      -- トークン値2
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_skip_error_expt;
    END IF;
--
    -- 5. 日付書式チェック
    -- 年月
    IF (xxcso_util_common_pkg.check_date(lv_year_month, cv_date_fmt) = FALSE) THEN
     lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name        -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_11   -- メッセージコード
                     ,iv_token_name1  => cv_tkn_year_month  -- トークンコード1
                     ,iv_token_value1 => cv_year_month      -- トークン値1
                     ,iv_token_name2  => cv_tkn_base_val    -- トークンコード2
                     ,iv_token_value2 => iv_base_value      -- トークン値2
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_skip_error_expt;
    END IF;
--
    /* 2011.02.07 N.Horigome E_本稼動_02682 START */
    -- 6．現在年度・前月年度比較チェック
    IF (in_process_year = in_pre_year) THEN
    /* 2011.02.07 N.Horigome E_本稼動_02682 END   */
      -- 6-1. 年度不一致チェック
      IF (TO_CHAR(in_process_year) <> lv_fiscal_year) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name        -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_12   -- メッセージコード
                       ,iv_token_name1  => cv_tkn_cur_year    -- トークンコード1
                       ,iv_token_value1 => TO_CHAR(in_process_year)     -- トークン値1
                       ,iv_token_name2  => cv_tkn_base_val    -- トークンコード2
                       ,iv_token_value2 => iv_base_value      -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
      END IF;
--
    /* 2011.02.07 N.Horigome E_本稼動_02682 START */
    ELSE
      -- 6-2.AR会計期間クローズチェック
      lv_result := xxcso_util_common_pkg.check_ar_gl_period_status(TO_DATE(lv_year_month,'YYYYMM'));
--
      -- 会計期間がクローズされている場合
      IF (lv_result = cv_false) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name        -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_26   -- メッセージコード
                       ,iv_token_name1  => cv_tkn_year_month  -- トークンコード1
                       ,iv_token_value1 => lv_year_month      -- トークン値1
                       ,iv_token_name2  => cv_tkn_base_val    -- トークンコード2
                       ,iv_token_value2 => iv_base_value      -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
      END IF;
    END IF;
--
    /* 2011.02.07 N.Horigome E_本稼動_02682 END */
    -- 7. 年度・年月整合性チェック
    BEGIN
      ln_year := xxcso_util_common_pkg.get_business_year(
                   lv_year_month
                 ); 
      IF (ln_year IS NULL) THEN
        RAISE global_skip_error_expt;
      END IF;
--      
    EXCEPTION
      -- 年月から年度抽出に失敗した場合の後処理
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name            -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_03       -- メッセージコード
                       ,iv_token_name1  => cv_tkn_year_month      -- トークンコード1
                       ,iv_token_value1 => lv_year_month          -- トークン値1
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE global_skip_error_expt;
    END;
--    
    -- 年度と年月からの年度が一致しない場合
    IF (TO_CHAR(ln_year) <> lv_fiscal_year) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name        -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_13   -- メッセージコード
                     ,iv_token_name1  => cv_tkn_base_val    -- トークンコード1
                     ,iv_token_value1 => iv_base_value      -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_skip_error_expt;
    END IF;
--
    ln_sales_staff := TO_CHAR(lv_sales_staff);
    -- 行単位データをレコードにセット
    g_dept_sales_stff_rec.fiscal_year      := lv_fiscal_year;   -- 年度
    g_dept_sales_stff_rec.year_month       := lv_year_month;    -- 年月
    g_dept_sales_stff_rec.base_code        := lv_base_code;     -- 拠点コード
    g_dept_sales_stff_rec.sales_staff      := ln_sales_staff;   -- 営業人員
--    
  EXCEPTION
    -- *** スキップ例外ハンドラ ***
    WHEN global_skip_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END data_proper_check;
--
  /**********************************************************************************
   * Procedure Name   : chk_mst_is_exists
   * Description      : マスタ存在チェック (A-5)
   ***********************************************************************************/
--
  PROCEDURE chk_mst_is_exists(
     id_process_date       IN  DATE             -- 業務処理日付 
    ,ov_errbuf             OUT NOCOPY VARCHAR2  -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode            OUT NOCOPY VARCHAR2  -- リターン・コード              -- # 固定 #
    ,ov_errmsg             OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100) := 'chk_mst_is_exists';  -- プログラム名
--
-- #######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf              VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode             VARCHAR2(1);     -- リターン・コード
    lv_errmsg              VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
-- ###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_item_nm             CONSTANT VARCHAR2(100) := '拠点コード';
    cv_aff_mst_v_nm        CONSTANT VARCHAR2(100) := 'AFF部門マスタビュー';
    -- *** ローカル変数 ***
    ld_process_date        DATE;
    lv_base_code_value     VARCHAR2(4);           -- 拠点コード
    ln_count               NUMBER;                -- 拠点コードカウント用変数(AFFマスタビューチェック)
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    ld_process_date    := TRUNC(id_process_date);
    lv_base_code_value := g_dept_sales_stff_rec.base_code;
--
    -- マスタ存在チェック--
    BEGIN
      SELECT COUNT(xabv.base_code)  base_code_num          -- 拠点コード数カウント
      INTO   ln_count                                      -- 拠点コードカウント用変数
      FROM   xxcso_aff_base_v xabv                         -- AFF部門マスタビュー
      WHERE  xabv.base_code = lv_base_code_value
        AND NVL(xabv.start_date_active,ld_process_date) <= ld_process_date
              AND NVL(xabv.end_date_active,ld_process_date) >= ld_process_date
        ;
--
    EXCEPTION
      -- 抽出に失敗した場合
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                       -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_25                  -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl                        -- トークンコード1
                       ,iv_token_value1 => cv_aff_mst_v_nm                   -- トークン値1
                       ,iv_token_name2  => cv_tkn_item                       -- トークンコード2
                       ,iv_token_value2 => lv_base_code_value                -- トークン値2
                       ,iv_token_name3  => cv_tkn_err_msg                    -- トークンコード3
                       ,iv_token_value3 => SQLERRM                           -- トークン値3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
    END;
--
    IF (ln_count = 0) THEN
    -- 抽出件数が0件の場合
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                         -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_15                    -- メッセージコード
                     ,iv_token_name1  => cv_tkn_item                         -- トークンコード1
                     ,iv_token_value1 => cv_item_nm                          -- トークン値1
                     ,iv_token_name2  => cv_tkn_tbl                          -- トークンコード2
                     ,iv_token_value2 => cv_aff_mst_v_nm                     -- トークン値2
                     ,iv_token_name3  => cv_tkn_item_value                   -- トークンコード3
                     ,iv_token_value3 => lv_base_code_value                  -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_skip_error_expt;
    END IF;
--
  EXCEPTION
    -- *** スキップ例外ハンドラ ***
    WHEN global_skip_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
     -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END chk_mst_is_exists;
--
  /**********************************************************************************
   * Procedure Name   : chk_dept_sales_stff
   * Description      : 同一拠点別営業人員抽出処理 (A-6)
   ***********************************************************************************/
--
  PROCEDURE chk_dept_sales_stff(
     on_count              OUT NOCOPY NUMBER    -- 同一拠点別営業人員抽出件数
    ,ov_errbuf             OUT NOCOPY VARCHAR2  -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode            OUT NOCOPY VARCHAR2  -- リターン・コード              -- # 固定 #
    ,ov_errmsg             OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100) := 'chk_dept_sales_stff';  -- プログラム名
--
-- #######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf              VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode             VARCHAR2(1);     -- リターン・コード
    lv_errmsg              VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
-- ###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_base_code_nm        CONSTANT VARCHAR2(100) := '拠点コード';
    cv_fscl_year_nm        CONSTANT VARCHAR2(100) := '年月';
    cv_dept_sales_stff_nm  CONSTANT VARCHAR2(100) := '拠点別営業人員テーブル';
    -- *** ローカル変数 ***
    lv_year_mnth_value     VARCHAR2(6);           -- 年月
    lv_base_code_value     VARCHAR2(4);           -- 拠点コード
    ln_count               NUMBER;                -- 拠点コードカウント用変数(拠点別営業人員テーブルチェック)
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    lv_year_mnth_value := g_dept_sales_stff_rec.year_month;
    lv_base_code_value := g_dept_sales_stff_rec.base_code;
--    
    -- 拠点別営業人員データ抽出
    BEGIN
--  
      SELECT COUNT(xdss.base_code)  base_code_num          -- 拠点コード数カウント
      INTO   ln_count
      FROM   xxcso_dept_sales_staffs xdss                  -- 拠点別営業人員テーブル
      WHERE  xdss.base_code  = lv_base_code_value
        AND  xdss.year_month = lv_year_mnth_value
        ;
--
    EXCEPTION
      -- 抽出に失敗した場合
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name          -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_17     -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl           -- トークンコード1
                       ,iv_token_value1 => cv_dept_sales_stff_nm-- トークン値1
                       ,iv_token_name2  => cv_tkn_loc           -- トークンコード2
                       ,iv_token_value2 => lv_base_code_value   -- トークン値2
                       ,iv_token_name3  => cv_tkn_year_month    -- トークンコード3
                       ,iv_token_value3 => lv_year_mnth_value   -- トークン値3
                       ,iv_token_name4  => cv_tkn_err_msg       -- トークンコード4
                       ,iv_token_value4 => SQLERRM              -- トークン値4
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
    END;
--
    on_count := ln_count;
--
  EXCEPTION
    -- *** スキップ例外ハンドラ ***
    WHEN global_skip_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
     -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END chk_dept_sales_stff;
--
  /**********************************************************************************
   * Procedure Name   : insert_dept_sales_stff
   * Description      : 拠点別営業人員登録 (A-8)
   ***********************************************************************************/
--
  PROCEDURE insert_dept_sales_stff(
     ov_errbuf             OUT NOCOPY VARCHAR2             -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode            OUT NOCOPY VARCHAR2             -- リターン・コード              -- # 固定 #
    ,ov_errmsg             OUT NOCOPY VARCHAR2             -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100)   := 'insert_dept_sales_stff';     -- プログラム名
--
-- #####################  固定ローカル変数宣言部 START     #########################
--
    lv_errbuf              VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode             VARCHAR2(1);     -- リターン・コード
    lv_errmsg              VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
-- #####################  固定ローカル変数宣言部 END       #########################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_dept_sales_stff_nm  CONSTANT VARCHAR2(100) := '拠点別営業人員テーブル';
    -- *** ローカル変数 ***
    lv_year_mnth_value     VARCHAR2(6);           -- 年月
    lv_base_code_value     VARCHAR2(4);           -- 拠点コード
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    lv_year_mnth_value := g_dept_sales_stff_rec.year_month;
    lv_base_code_value := g_dept_sales_stff_rec.base_code;
--
    -- =======================
    -- 拠点別営業人員データ登録 
    -- =======================
    BEGIN
      INSERT INTO xxcso_dept_sales_staffs  -- 拠点別営業人員テーブル
        ( year_month              -- 年月
         ,base_code               -- 拠点コード
         ,fiscal_year             -- 年度
         ,sales_staff             -- 営業人員
         ,created_by              -- 作成者
         ,creation_date           -- 作成日
         ,last_updated_by         -- 最終更新者
         ,last_update_date        -- 最終更新日
         ,last_update_login       -- 最終更新ログイン
         ,request_id              -- 要求ID
         ,program_application_id  -- コンカレント・プログラム・アプリケーションID
         ,program_id              -- コンカレント・プログラムID
         ,program_update_date     -- プログラム更新日
         )
      VALUES
        ( g_dept_sales_stff_rec.year_month
         ,g_dept_sales_stff_rec.base_code        
         ,g_dept_sales_stff_rec.fiscal_year
         ,g_dept_sales_stff_rec.sales_staff
         ,cn_created_by            
         ,cd_creation_date         
         ,cn_last_updated_by       
         ,cd_last_update_date      
         ,cn_last_update_login     
         ,cn_request_id            
         ,cn_program_application_id
         ,cn_program_id            
         ,cd_program_update_date   
        );
--
    EXCEPTION
         -- 登録に失敗した場合
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name          -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_18     -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl           -- トークンコード1
                       ,iv_token_value1 => cv_dept_sales_stff_nm-- トークン値1
                       ,iv_token_name2  => cv_tkn_loc           -- トークンコード2
                       ,iv_token_value2 => lv_base_code_value   -- トークン値2
                       ,iv_token_name3  => cv_tkn_year_month    -- トークンコード3
                       ,iv_token_value3 => lv_year_mnth_value   -- トークン値3
                       ,iv_token_name4  => cv_tkn_err_msg       -- トークンコード4
                       ,iv_token_value4 => SQLERRM              -- トークン値4
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
    END;
--
  EXCEPTION
    -- *** スキップ例外ハンドラ ***
    WHEN global_skip_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END insert_dept_sales_stff;
--
  /**********************************************************************************
   * Procedure Name   : update_dept_sales_stff
   * Description      : 拠点別営業人員テーブルデータ更新 (A-7)
   ***********************************************************************************/
--
  PROCEDURE update_dept_sales_stff(
     ov_errbuf             OUT NOCOPY VARCHAR2             -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode            OUT NOCOPY VARCHAR2             -- リターン・コード              -- # 固定 #
    ,ov_errmsg             OUT NOCOPY VARCHAR2             -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100)   := 'update_dept_sales_stff';     -- プログラム名
--
-- #####################  固定ローカル変数宣言部 START     #########################
--
    lv_errbuf              VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode             VARCHAR2(1);     -- リターン・コード
    lv_errmsg              VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
-- #####################  固定ローカル変数宣言部 END       #########################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    cv_dept_sales_stff_nm  CONSTANT VARCHAR2(100) := '拠点別営業人員テーブル';
    -- *** ローカル変数 ***
    lv_year_mnth_value     VARCHAR2(6);           -- 年月
    lv_base_code_value     VARCHAR2(4);           -- 拠点コード
    lv_base_code_loc       VARCHAR2(4);           -- 拠点コード
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--    
    lv_year_mnth_value := g_dept_sales_stff_rec.year_month;
    lv_base_code_value := g_dept_sales_stff_rec.base_code;
--
    -- 拠点別営業人員データロック 
    BEGIN
--  
      SELECT xdss.base_code base_code                      -- 拠点コード
      INTO   lv_base_code_loc
      FROM   xxcso_dept_sales_staffs xdss                  -- 拠点別営業人員テーブル
      WHERE  xdss.base_code  = lv_base_code_value
        AND  xdss.year_month = lv_year_mnth_value
      FOR UPDATE NOWAIT;  -- テーブルロック
--
    EXCEPTION
      -- ロック失敗した場合の例外
      WHEN global_lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name          -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_16     -- メッセージコード
                       ,iv_token_name1  => cv_tkn_loc           -- トークンコード1
                       ,iv_token_value1 => lv_base_code_value   -- トークン値1
                       ,iv_token_name2  => cv_tkn_year_month    -- トークンコード2
                       ,iv_token_value2 => lv_year_mnth_value   -- トークン値2
                       ,iv_token_name3  => cv_tkn_err_msg       -- トークンコード3
                       ,iv_token_value3 => SQLERRM              -- トークン値3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
--
      -- 抽出に失敗した場合
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name          -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_17     -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl           -- トークンコード1
                       ,iv_token_value1 => cv_dept_sales_stff_nm-- トークン値1
                       ,iv_token_name2  => cv_tkn_loc           -- トークンコード2
                       ,iv_token_value2 => lv_base_code_value   -- トークン値2
                       ,iv_token_name3  => cv_tkn_year_month    -- トークンコード3
                       ,iv_token_value3 => lv_year_mnth_value   -- トークン値3
                       ,iv_token_name4  => cv_tkn_err_msg       -- トークンコード4
                       ,iv_token_value4 => SQLERRM              -- トークン値4
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
    END;
    -- ================================
    -- 拠点別営業人員テーブルデータ更新 
    -- ================================
--
    BEGIN
--   
      UPDATE xxcso_dept_sales_staffs xdss                        -- 拠点別営業人員テーブル
      SET    fiscal_year             =  g_dept_sales_stff_rec.fiscal_year  -- 年度
            ,sales_staff             =  g_dept_sales_stff_rec.sales_staff  -- 営業人員
            ,last_updated_by         =  cn_last_updated_by           -- 最終更新者
            ,last_update_date        =  cd_last_update_date          -- 最終更新日
            ,last_update_login       =  cn_last_update_login         -- 最終更新ログイン
            ,request_id              =  cn_request_id                -- 要求ID
            ,program_application_id  =  cn_program_application_id    -- コンカレント・プログラム・アプリケーションID
            ,program_id              =  cn_program_id                -- コンカレント・プログラムID
            ,program_update_date     =  cd_program_update_date       -- プログラム更新日
      WHERE  xdss.base_code  = lv_base_code_value
      AND    xdss.year_month = lv_year_mnth_value;
    
--
    EXCEPTION
      -- 更新に失敗した場合の例外
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name          -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_19     -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl           -- トークンコード1
                       ,iv_token_value1 => cv_dept_sales_stff_nm-- トークン値1
                       ,iv_token_name2  => cv_tkn_loc           -- トークンコード2
                       ,iv_token_value2 => lv_base_code_value   -- トークン値2
                       ,iv_token_name3  => cv_tkn_year_month    -- トークンコード3
                       ,iv_token_value3 => lv_year_mnth_value   -- トークン値3
                       ,iv_token_name4  => cv_tkn_err_msg       -- トークンコード4
                       ,iv_token_value4 => SQLERRM              -- トークン値4
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
    END;
--
  EXCEPTION
    -- *** スキップ例外ハンドラ ***
    WHEN global_skip_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END update_dept_sales_stff;
--
  /**********************************************************************************
   * Procedure Name   : delete_if_data
   * Description      : ファイルデータ削除処理 (A-11)
   ***********************************************************************************/
--
  PROCEDURE delete_if_data(
     ov_errbuf      OUT NOCOPY VARCHAR2             -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode     OUT NOCOPY VARCHAR2             -- リターン・コード              -- # 固定 #
    ,ov_errmsg      OUT NOCOPY VARCHAR2             -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100)   := 'delete_if_data';     -- プログラム名
--
-- #####################  固定ローカル変数宣言部 START     #########################
--
    lv_errbuf       VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode      VARCHAR2(1);     -- リターン・コード
    lv_errmsg       VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
-- #####################  固定ローカル変数宣言部 END       #########################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_if_table_nm  CONSTANT VARCHAR2(100)  := 'ファイルアップロードI/Fテーブル';
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    BEGIN
--
      -- ファイルデータ削除
      DELETE FROM   xxccp_mrp_file_ul_interface xmfui
      WHERE  xmfui.file_id = gt_file_id;
--
      -- ログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg3 || CHR(10) ||
                   '' 
      );
--
    EXCEPTION
      -- 削除に失敗した場合
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name          -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_06     -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl           -- トークンコード1
                       ,iv_token_value1 => cv_if_table_nm       -- トークン値1
                       ,iv_token_name2  => cv_tkn_file_id       -- トークンコード2
                       ,iv_token_value2 => TO_CHAR(gt_file_id)  -- トークン値2
                       ,iv_token_name3  => cv_tkn_err_msg       -- トークンコード2
                       ,iv_token_value3 => SQLERRM              -- トークン値3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;                              -- # 任意 #
    END;
--
  EXCEPTION
    -- *** 処理例外ハンドラ ***
    WHEN global_process_expt THEN
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
  END delete_if_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   ***********************************************************************************/
--
  PROCEDURE submain(
     ov_errbuf      OUT NOCOPY VARCHAR2   -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode     OUT NOCOPY VARCHAR2   -- リターン・コード              -- # 固定 #
    ,ov_errmsg      OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100)   := 'submain';     -- プログラム名
--
-- #####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf       VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode      VARCHAR2(1);     -- リターン・コード
    lv_sub_retcode  VARCHAR2(1);     -- サーブリターン・コード
    lv_errmsg       VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
-- ###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cn_no_data        CONSTANT NUMBER := 0;   -- データなし 
    -- *** ローカル変数 ***
    lv_base_value     VARCHAR2(5000);         -- 当該行データ
    ln_count_process  NUMBER;                 -- 抽出件数
    ln_process_year   NUMBER;                 -- 現在年度
    /* 2011.02.07 N.Horigome E_本稼動_02682 START */
    ln_pre_year       NUMBER;                 -- 前月年度
    /* 2011.02.07 N.Horigome E_本稼動_02682 END   */
    ld_process_date   DATE;                   -- 業務処理日付
--
  BEGIN
--
-- ##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
-- ###########################  固定部 END   ############################
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
    -- ================================
    -- A-1.初期処理 
    -- ================================
    init(
       od_process_date  => ld_process_date     -- 業務処理日付
      ,on_process_year  => ln_process_year     -- 現在年度
    /* 2011.02.07 N.Horigome E_本稼動_02682 START */
      ,on_pre_year      => ln_pre_year         -- 前月年度
    /* 2011.02.07 N.Horigome E_本稼動_02682 END   */
      ,ov_errbuf        => lv_errbuf           -- エラー・メッセージ            -- # 固定 #
      ,ov_retcode       => lv_retcode          -- リターン・コード              -- # 固定 #
      ,ov_errmsg        => lv_errmsg           -- ユーザー・エラー・メッセージ  -- # 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--

    -- ========================================
    -- A-2.拠点別営業人員一覧抽出処理 
    -- ========================================
    get_dept_sales_stff_data(
       ov_errbuf        => lv_errbuf        -- エラー・メッセージ            -- # 固定 #
      ,ov_retcode       => lv_retcode       -- リターン・コード              -- # 固定 #
      ,ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ  -- # 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ファイルデータループ
    <<dept_sales_stff_data>>
    FOR i IN 1..g_file_data_tab.COUNT LOOP
--
      BEGIN
--
        -- レコードクリア
        g_dept_sales_stff_rec := NULL;

        -- 対象件数カウント
        gn_target_cnt := gn_target_cnt + 1;

        lv_base_value := g_file_data_tab(i);
--
        -- =======================
        -- A-3.セーブポイント設定
        -- =======================
        SAVEPOINT dept_sales_stff;
--
        -- =================================================
        -- A-4.データ妥当性チェック (レコードにデータセット)
        -- =================================================
        data_proper_check(
           iv_base_value    => lv_base_value    -- 当該行データ
          ,in_process_year  => ln_process_year  -- 現在年度
        /* 2011.02.07 N.Horigome E_本稼動_02682 START */
          ,in_pre_year      => ln_pre_year      -- 前月年度
        /* 2011.02.07 N.Horigome E_本稼動_02682 END   */
          ,ov_errbuf        => lv_errbuf        -- エラー・メッセージ            -- # 固定 #
          ,ov_retcode       => lv_sub_retcode   -- リターン・コード              -- # 固定 #
          ,ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ  -- # 固定 #
        );
        IF (lv_sub_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lv_sub_retcode = cv_status_warn) THEN
          RAISE global_skip_error_expt;
        END IF;
--
        -- =============================
        -- A-5.マスタ存在チェック 
        -- =============================
        chk_mst_is_exists(
           id_process_date  => ld_process_date  -- 業務処理日付
          ,ov_errbuf        => lv_errbuf        -- エラー・メッセージ            -- # 固定 #
          ,ov_retcode       => lv_sub_retcode   -- リターン・コード              -- # 固定 #
          ,ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ  -- # 固定 #
        );
        IF (lv_sub_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lv_sub_retcode = cv_status_warn) THEN
          RAISE global_skip_error_expt;
        END IF;
--
        -- ===============================
        -- A-6.同一拠点別営業人員抽出処理 
        -- ===============================
--
        -- 同一拠点別営業人員抽出件数初期化
        ln_count_process := 0;
--        
        chk_dept_sales_stff(
           on_count         => ln_count_process -- 同一拠点別営業人員抽出件数
          ,ov_errbuf        => lv_errbuf        -- エラー・メッセージ            -- # 固定 #
          ,ov_retcode       => lv_sub_retcode   -- リターン・コード              -- # 固定 #
          ,ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ  -- # 固定 #
        );
        IF (lv_sub_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lv_sub_retcode = cv_status_warn) THEN
          RAISE global_skip_error_expt;
        END IF;
--
        -- 新規登録フラグがTRUEの場合
        IF (ln_count_process = cn_no_data) THEN
--
          -- ===============================
          -- A-8.拠点別営業人員登録処理 
          -- ===============================
          insert_dept_sales_stff(
             ov_errbuf        => lv_errbuf        -- エラー・メッセージ            -- # 固定 #
            ,ov_retcode       => lv_sub_retcode   -- リターン・コード              -- # 固定 #
            ,ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ  -- # 固定 #
          );
--
          IF (lv_sub_retcode = cv_status_error) THEN
            gb_rollback_upd_flg := TRUE;
            RAISE global_process_expt;
          ELSIF (lv_sub_retcode = cv_status_warn) THEN
            gb_rollback_upd_flg := TRUE;
            RAISE global_skip_error_expt;
          END IF;
        -- 新規登録フラグがFALSEの場合
        ELSE
          -- ===============================
          -- A-7.拠点別営業人員更新処理 
          -- ===============================
          update_dept_sales_stff(
             ov_errbuf        => lv_errbuf        -- エラー・メッセージ            -- # 固定 #
            ,ov_retcode       => lv_sub_retcode   -- リターン・コード              -- # 固定 #
            ,ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ  -- # 固定 #
          );
--
          IF (lv_sub_retcode = cv_status_error) THEN
            gb_rollback_upd_flg := TRUE;
            RAISE global_process_expt;
          ELSIF (lv_sub_retcode = cv_status_warn) THEN
            gb_rollback_upd_flg := TRUE;
            RAISE global_skip_error_expt;
          END IF;
--
        END IF;
--
        -- 成功件数カウント
        gn_normal_cnt := gn_normal_cnt + 1;
--
      EXCEPTION
        -- *** スキップ例外ハンドラ ***
        WHEN global_skip_error_expt THEN
          gn_error_cnt := gn_error_cnt + 1;       -- エラー件数カウント
          lv_retcode   := cv_status_warn;
--
          -- メッセージ出力
          fnd_file.put_line(
             which  => fnd_file.output
            ,buff   => lv_errmsg                  -- ユーザー・エラーメッセージ
          );
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff   => cv_pkg_name||cv_msg_cont||
                       cv_prg_name||cv_msg_part||
                       lv_errbuf                  -- エラーメッセージ
          );
--
          -- ロールバック
          IF gb_rollback_upd_flg = TRUE THEN
            ROLLBACK TO SAVEPOINT dept_sales_stff;    -- ROLLBACK
            gb_rollback_upd_flg := FALSE;
            -- ログ出力
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => cv_debug_msg6|| CHR(10) ||
                         ''
            );
          END IF;
--
        --*** 処理部共通例外ハンドラ ***
        WHEN global_process_expt THEN
          gn_error_cnt := gn_error_cnt + 1;       -- エラー件数カウント
          lv_retcode   := cv_status_warn;
--
          -- メッセージ出力
          fnd_file.put_line(
             which  => fnd_file.output
            ,buff   => lv_errmsg                  -- ユーザー・エラーメッセージ
          );
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff   => cv_pkg_name||cv_msg_cont||
                       cv_prg_name||cv_msg_part||
                       lv_errbuf                  -- エラーメッセージ
          );
--
          -- ロールバック
          IF gb_rollback_upd_flg = TRUE THEN
            ROLLBACK TO SAVEPOINT dept_sales_stff;    -- ROLLBACK
            gb_rollback_upd_flg := FALSE;
            -- ログ出力
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => cv_debug_msg6|| CHR(10) ||
                         ''
            );
          END IF;
--        
        -- *** スキップ例外OTHERSハンドラ ***
        WHEN OTHERS THEN
          gn_error_cnt := gn_error_cnt + 1;       -- エラー件数カウント
          lv_retcode   := cv_status_warn;
--
          -- ログ出力
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff   => cv_pkg_name||cv_msg_cont||
                       cv_prg_name||cv_msg_part||
                       lv_errbuf                  -- エラーメッセージ
          );
--
          -- ロールバック
          IF gb_rollback_upd_flg = TRUE THEN
            ROLLBACK TO SAVEPOINT dept_sales_stff;    -- ROLLBACK
            gb_rollback_upd_flg := FALSE;
            -- ログ出力
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => cv_debug_msg6|| CHR(10) ||
                         ''
            );
          END IF;
--
      END;
--
    END LOOP dept_sales_stff_data;
--
    ov_retcode := lv_retcode;                -- リターン・コード
--
    -- =============================
    -- A-9.ファイルデータ削除処理 
    -- =============================
    delete_if_data(
       ov_errbuf        => lv_errbuf        -- エラー・メッセージ            -- # 固定 #
      ,ov_retcode       => lv_retcode       -- リターン・コード              -- # 固定 #
      ,ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ  -- # 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;

--
  EXCEPTION
--
-- #################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
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
     errbuf        OUT NOCOPY VARCHAR2          -- エラー・メッセージ  -- # 固定 #
    ,retcode       OUT NOCOPY VARCHAR2          -- リターン・コード    -- # 固定 #
    ,in_file_id    IN         NUMBER            -- ファイルID
    ,iv_fmt_ptn    IN         VARCHAR2          -- フォーマットパターン
  )    
--
-- ###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- プログラム名
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);   -- 終了メッセージコード
--
  BEGIN
--
-- ###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
--
-- ###########################  固定部 END   #############################
--
    -- *** 入力パラメータをセット
    gt_file_id := in_file_id;
    gv_fmt_ptn := iv_fmt_ptn;
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       ov_errbuf   => lv_errbuf          -- エラー・メッセージ            -- # 固定 #
      ,ov_retcode  => lv_retcode         -- リターン・コード              -- # 固定 #
      ,ov_errmsg   => lv_errmsg          -- ユーザー・エラー・メッセージ  -- # 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
       --エラー出力
       fnd_file.put_line(
          which  => fnd_file.output
         ,buff   => lv_errmsg                  -- ユーザー・エラーメッセージ
       );
       fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => cv_pkg_name||cv_msg_cont||
                    cv_prg_name||cv_msg_part||
                    lv_errbuf                  --エラーメッセージ
       );
--
    END IF;
--
    -- =======================
    -- A-10.終了処理 
    -- =======================
    -- 空行の出力
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => ''               -- 空行
    );
    -- 対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                  );
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => gv_out_msg
    );
--
    -- 成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                  );
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => gv_out_msg
    );
--
    -- エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                  );
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => gv_out_msg
    );
--
    -- 終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
--
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                  );
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => gv_out_msg
    );
--
    -- ステータスセット
    retcode := lv_retcode;
    -- 終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ロールバックしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg6 || CHR(10) ||
                   ''
      );
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
END XXCSO004A02C;
/
