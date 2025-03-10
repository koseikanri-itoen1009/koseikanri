CREATE OR REPLACE PACKAGE BODY APPS.XXCSO014A08C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO014A08C(body)
 * Description      : 日別売上計画ファイルをHHTへ連携するためのCSVファイルを作成します。
 *                    
 * MD.050           : MD050_IPO_CSO_014_A08_HHT-EBSインターフェース：(OUT)日別売上計画
 *                    
 * Version          : 1.1
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  init                        初期処理 (A-1)
 *  set_parm_def                パラメータデフォルトセット (A-2)
 *  chk_parm_date               パラメータチェック (A-3)
 *  get_profile_info            プロファイル値を取得 (A-4)
 *  open_csv_file               CSVファイルオープン (A-5) 
 *  create_csv_rec              CSVファイル出力 (A-7)
 *  close_csv_file              CSVファイルクローズ (A-8)
 *  submain                     メイン処理プロシージャ
 *                                顧客別日別売上計画データ抽出 (A-6)
 *  main                        コンカレント実行ファイル登録プロシージャ
 *                                終了処理 (A-9)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-11-25    1.0   Syoei.Kin        新規作成
 *  2009-02-24    1.1   K.Sai            レビュー結果反映 
 *  2009-05-01    1.2   Tomoko.Mori      T1_0897対応
 *  2009-12-04    1.3   T.Maruyama       E_本稼動_00285対応
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg                VARCHAR2(2000);
  gn_target_cnt             NUMBER;                    -- 対象件数
  gn_normal_cnt             NUMBER;                    -- 正常件数
  gn_error_cnt              NUMBER;                    -- エラー件数
--
  gv_from_value             VARCHAR2(20);               -- 更新日FROM(YYYYMMDD)
  gv_to_value               VARCHAR2(20);               -- 更新日TO(YYYYMMDD)
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
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO014A08C';      -- パッケージ名
  cv_app_name            CONSTANT VARCHAR2(10)  := 'XXCSO';             -- アプリケーション短縮名
  cv_appl_short_name     CONSTANT VARCHAR2(10)  := 'XXCCP';             -- アドオン：共通・IF領域
--
  cv_monday_kbn_day      CONSTANT VARCHAR2(1)   := '2';                 -- 月日区分（日別：2）
--
  -- トークンコード
  cv_tkn_prof_name       CONSTANT VARCHAR2(20) := 'PROF_NAME';          -- プロファイル名
  cv_tkn_err_msg         CONSTANT VARCHAR2(20) := 'ERR_MSG';            -- SQLエラーメッセージ
  cv_tkn_value           CONSTANT VARCHAR2(20) := 'VALUE';              -- 入力されたパラメータ値
  cv_tkn_status          CONSTANT VARCHAR2(20) := 'STATUS';             -- リターンステータス(日付書式チェック結果)
  cv_tkn_message         CONSTANT VARCHAR2(20) := 'MESSAGE';            -- リターンメッセージ(日付書式チェック) 
  cv_tkn_from_value      CONSTANT VARCHAR2(20) := 'FROM_VALUE';         -- 更新日FROM
  cv_tkn_to_value        CONSTANT VARCHAR2(20) := 'TO_VALUE';           -- 更新日TO
  cv_tkn_csv_location    CONSTANT VARCHAR2(20) := 'CSV_LOCATION';       -- CSVファイル出力先
  cv_tkn_csv_file_name   CONSTANT VARCHAR2(20) := 'CSV_FILE_NAME';      -- CSVファイル名
  cv_tkn_year_month      CONSTANT VARCHAR2(20) := 'YEAR_MONTH';         -- 年月
  cv_tkn_location_cd     CONSTANT VARCHAR2(20) := 'LOCATION_CD';        -- 売上拠点コード
  cv_tkn_customer_cd     CONSTANT VARCHAR2(20) := 'CUSTOMER_CD';        -- 顧客コード
  cv_tkn_proc_name       CONSTANT VARCHAR2(20) := 'PROCESSING_NAME';    -- 抽出処理名
  cv_table               CONSTANT VARCHAR2(20) := 'TABLE';              -- テーブル名
--
  cb_true                CONSTANT BOOLEAN := TRUE;
  cb_false               CONSTANT BOOLEAN := FALSE;
--
  -- DEBUG_LOG用メッセージ
  cv_debug_msg1           CONSTANT VARCHAR2(200) := '<< システム日付取得処理 >>';
  cv_debug_msg2           CONSTANT VARCHAR2(200) := 'od_sysdate = ';
  cv_debug_msg3           CONSTANT VARCHAR2(200) := '<< 業務処理日付取得処理 >>';
  cv_debug_msg4           CONSTANT VARCHAR2(200) := 'ld_process_date = ';
  cv_debug_msg5           CONSTANT VARCHAR2(200) := '<< 年度取得処理 >>';
  cv_debug_msg6           CONSTANT VARCHAR2(200) := 'ln_business_year = ';
  cv_debug_msg7           CONSTANT VARCHAR2(200) := '<< プロファイル値取得処理 >>';
  cv_debug_msg8           CONSTANT VARCHAR2(200) := 'lv_company_cd = ';
  cv_debug_msg9           CONSTANT VARCHAR2(200) := 'lv_csv_dir    = ';
  cv_debug_msg10          CONSTANT VARCHAR2(200) := 'lv_csv_nm     = ';
  cv_debug_msg11          CONSTANT VARCHAR2(200) := 'lv_cntrbt_sls = ';
  cv_debug_msg12          CONSTANT VARCHAR2(200) := '<< CSVファイルをオープンしました >>' ;
  cv_debug_msg13          CONSTANT VARCHAR2(200) := '<< CSVファイルをクローズしました >>' ;
  cv_debug_msg14          CONSTANT VARCHAR2(200) := '<< ロールバックしました >>' ;
  cv_debug_msg_fnm        CONSTANT VARCHAR2(200) := 'filename = ';
  cv_debug_msg_fcls       CONSTANT VARCHAR2(200) := '<< 例外処理内でCSVファイルをクローズしました >>';
  cv_debug_msg_copn       CONSTANT VARCHAR2(200) := '<< カーソルをオープンしました >>';
  cv_debug_msg_ccls1      CONSTANT VARCHAR2(200) := '<< カーソルをクローズしました >>';
  cv_debug_msg_ccls2      CONSTANT VARCHAR2(200) := '<< 例外処理内でカーソルをクローズしました >>';
  cv_debug_msg_err1       CONSTANT VARCHAR2(200) := 'file_err_expt';
  cv_debug_msg_err2       CONSTANT VARCHAR2(200) := 'global_api_expt';
  cv_debug_msg_err3       CONSTANT VARCHAR2(200) := 'global_api_others_expt';
  cv_debug_msg_err4       CONSTANT VARCHAR2(200) := 'others例外';
  cv_debug_msg_err5       CONSTANT VARCHAR2(200) := 'no_data_expt';
  cv_debug_msg_err6       CONSTANT VARCHAR2(200) := 'global_process_expt';
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- ファイル・ハンドルの宣言
  gf_file_hand    UTL_FILE.FILE_TYPE;
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  --*** グローバルTABLE ***
    TYPE g_csv_get_sales_plan_day_ttype IS TABLE OF VARCHAR2(20) INDEX BY BINARY_INTEGER;
    g_csv_get_sales_plan_day_list g_csv_get_sales_plan_day_ttype;
  --*** データ登録、更新例外 ***
  global_ins_upd_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_ins_upd_expt,-30000);
--

--

  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理 (A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_sysdate          OUT NOCOPY VARCHAR2,  -- システム日付
    ov_errbuf           OUT NOCOPY VARCHAR2,  -- エラー・メッセージ            --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,  -- リターン・コード              --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ    --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'init';           -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    lv_sysdate      VARCHAR2(100);    --システム日付
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===========================
    -- システム日付取得処理 
    -- ===========================
    --
    --プログラム開始時点のシステム日付
    lv_sysdate := TO_CHAR(SYSDATE, 'YYYY/MM/DD HH24:MI:SS');
    -- *** DEBUG_LOG ***
    -- 取得したシステム日付をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg1  || CHR(10) ||
                 cv_debug_msg2  || lv_sysdate || CHR(10) ||
                 ''
    );
    -- 取得したシステム日付をOUTパラメータに設定
    ov_sysdate  := lv_sysdate;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
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
   * Procedure Name   : set_parm_def                                  
   * Description      : パラメータデフォルトセット (A-2)
   ***********************************************************************************/
  PROCEDURE set_parm_def(
    od_process_date         OUT NOCOPY DATE,            -- 業務処理日
    ov_errbuf               OUT NOCOPY VARCHAR2,        -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,        -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ   --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'set_parm_def';      -- プログラム名
--
    cv_param_def_set_tkn    CONSTANT VARCHAR2(100)  := 'APP-XXCSO1-00150';  -- パラメータデフォルトセット
    cv_process_date_tkn     CONSTANT VARCHAR2(100)  := 'APP-XXCSO1-00011';  -- 業務処理日付取得エラー
    cv_from_value_tkn       CONSTANT VARCHAR2(100)  := 'APP-XXCSO1-00145';  -- パラメータ更新日FROM
    cv_to_value_tkn         CONSTANT VARCHAR2(100)  := 'APP-XXCSO1-00146';  -- パラメータ更新日TO
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
    ld_process_date        DATE;            -- 業務処理日
    lv_param_set           VARCHAR2(1000);  -- パラメータデフォルトセットメッセージを格納
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
    -- パラメータ更新日FROMと更新日TO出力 
    -- =======================================
--
    --更新日FROMメッセージ出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_from_value_tkn
                    ,iv_token_name1  => cv_tkn_from_value
                    ,iv_token_value1 => gv_from_value
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''           || CHR(10) ||   -- 空行の挿入
                   gv_out_msg ||
                 ''                   -- 空行の挿入
    );
    --更新日TOメッセージ出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_to_value_tkn
                    ,iv_token_name1  => cv_tkn_to_value
                    ,iv_token_value1 => gv_to_value
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''           || CHR(10) ||   -- 空行の挿入
                   gv_out_msg ||
                 ''                   -- 空行の挿入
    );
--
    -- =======================================================================
    -- 起動パラメータ「更新日FROM」「更新日TO」が「NULL」であるかどうかを確認 
    -- =======================================================================
--
    -- 業務処理日付取得処理 
    ld_process_date := xxccp_common_pkg2.get_process_date;  
    -- *** DEBUG_LOG ***
    -- 取得した業務処理日付をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg3 || CHR(10) ||
                 cv_debug_msg4 || TO_CHAR(ld_process_date,'yyyy/mm/dd hh24:mi:ss') || CHR(10) ||
                 ''
    );
    -- 業務処理日付取得に失敗した場合
    IF (ld_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
              iv_application  => cv_app_name                 -- アプリケーション短縮名
             ,iv_name         => cv_process_date_tkn         -- メッセージコード
      );
      lv_errbuf  := lv_errmsg||SQLERRM;
      RAISE global_api_expt;
    END IF;
    -- 更新日FROMと更新日TOの存在チェック 
    IF (gv_from_value IS NULL) THEN
      gv_from_value := TO_CHAR(ld_process_date,'YYYYMMDD');
      --パラメータデフォルトセット
      lv_param_set := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_param_def_set_tkn
                     );
      lv_errbuf  := lv_errmsg||SQLERRM;
      fnd_file.put_line(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_param_set
      );
    END IF;
    IF (gv_to_value IS NULL) THEN
      /* 2009/12/04 T.Maruyama E_本稼動_00285対応 START */
      --夜間JOB更新データも対称として連携する
      --gv_to_value := TO_CHAR(ld_process_date,'YYYYMMDD');
      gv_to_value := TO_CHAR(ld_process_date + 1,'YYYYMMDD');
      /* 2009/12/04 T.Maruyama E_本稼動_00285対応 END */
      --パラメータデフォルトセット
      lv_param_set := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_param_def_set_tkn
                     );
      lv_errbuf  := lv_errmsg||SQLERRM;
      fnd_file.put_line(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_param_set
      );
    END IF;
    -- 取得した業務処理日をOUTパラメータに設定
    od_process_date  := ld_process_date;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END set_parm_def;
--
  /**********************************************************************************
   * Procedure Name   : chk_parm_date
   * Description      : パラメータチェック (A-3)
   ***********************************************************************************/
  PROCEDURE chk_parm_date(
    ov_errbuf               OUT NOCOPY VARCHAR2,        -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,        -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ   --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'chk_parm_date';     -- プログラム名
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
    cv_false               CONSTANT VARCHAR2(10)  := 'false';
    cv_date_formart_tkn    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00012';  -- 日付書式エラー
    cv_parameter_tkn       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00176';  -- パラメータ整合性エラー
    -- *** ローカル変数 ***
    lv_format                 VARCHAR2(20);  -- 日付のフォーマット
    lb_check_date_from_value  BOOLEAN;       -- 更新日FROMの書式が指定された日付の書式（YYYYMMDD）であるかを確認
    lb_check_date_to_value    BOOLEAN;       -- 更新日TOの書式が指定された日付の書式（YYYYMMDD）であるかを確認
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    lv_format            := 'YYYYMMDD';     -- 日付のフォーマット
--
    -- ===========================
    -- 日付書式チェック 
    -- ===========================
    BEGIN
--
      --取得したパラメータの書式が指定された日付の書式（YYYYMMDD）であるかを確認
      lb_check_date_from_value := xxcso_util_common_pkg.check_date(
                                    iv_date         => gv_from_value
                                   ,iv_date_format  => lv_format
      );
      lb_check_date_to_value   := xxcso_util_common_pkg.check_date(
                                    iv_date         => gv_to_value
                                   ,iv_date_format  => lv_format
      );     
      --リターンステータスが「FALSE」の場合,例外処理を行う
      IF (lb_check_date_from_value = cb_false) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name               -- アプリケーション短縮名
                        ,iv_name         => cv_date_formart_tkn       -- メッセージコード
                        ,iv_token_name1  => cv_tkn_value              -- トークンコード1
                        ,iv_token_value1 => gv_from_value             -- トークン値1パラメータ
                        ,iv_token_name2  => cv_tkn_status             -- トークンコード2
                        ,iv_token_value2 => cv_false                  -- トークン値2リターンステータス
                        ,iv_token_name3  => cv_tkn_message            -- トークンコード3
                        ,iv_token_value3 => NULL                      -- トークン値3リターンメッセージ
        );
        lv_errbuf  := lv_errmsg||SQLERRM;
        RAISE global_api_expt;
      END IF;
      IF (lb_check_date_to_value = cb_false) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name               -- アプリケーション短縮名
                        ,iv_name         => cv_date_formart_tkn       -- メッセージコード
                        ,iv_token_name1  => cv_tkn_value              -- トークンコード1
                        ,iv_token_value1 => gv_to_value               -- トークン値1パラメータ
                        ,iv_token_name2  => cv_tkn_status             -- トークンコード2
                        ,iv_token_value2 => cv_false                  -- トークン値2リターンステータス
                        ,iv_token_name3  => cv_tkn_message            -- トークンコード3
                        ,iv_token_value3 => NULL                      -- トークン値3リターンメッセージ
        );
        lv_errbuf  := lv_errmsg||SQLERRM;
        RAISE global_api_expt;
      END IF;
    END;
--
    -- ===========================
    -- 日付大小関係チェック
    -- ===========================
    BEGIN
--
      --入力されたパラメータの値の大小関係が正しいか確認
      IF (gv_from_value > gv_to_value) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name              -- アプリケーション短縮名
                        ,iv_name         => cv_parameter_tkn         -- メッセージコード
                        ,iv_token_name1  => cv_tkn_from_value        -- トークンコード1
                        ,iv_token_value1 => gv_from_value            -- トークン値1更新日FROM
                        ,iv_token_name2  => cv_tkn_to_value          -- トークンコード2
                        ,iv_token_value2 => gv_to_value              -- トークン値2更新日TO
        );
        lv_errbuf  := lv_errmsg||SQLERRM;
        RAISE global_api_expt;
      END IF;
    END;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END chk_parm_date;
--
  /**********************************************************************************
   * Procedure Name   : get_profile_info
   * Description      : プロファイル値を取得 (A-4)
   ***********************************************************************************/
  PROCEDURE get_profile_info(
    ov_file_dir             OUT NOCOPY VARCHAR2,        --XXCSO:HTT連携用CSVファイル出力先
    ov_file_name            OUT NOCOPY VARCHAR2,        --XXCSO:HTT連携用CSVファイル名
    ov_errbuf               OUT NOCOPY VARCHAR2,        -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,        -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ   --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)  := 'get_profile_info';          -- プログラム名
--
    cv_intf_file_name   CONSTANT VARCHAR2(100)  := 'APP-XXCSO1-00152';          -- インターフェースファイル名
    cv_profile_get_tkn  CONSTANT VARCHAR2(100)  := 'APP-XXCSO1-00014';          -- プロファイル取得エラー
    cv_tkn_csv_name     CONSTANT VARCHAR2(100)  := 'CSV_FILE_NAME';
      -- インターフェースファイル名トークン名

    cv_file_dir         CONSTANT VARCHAR2(100)  := 'XXCSO1_HHT_OUT_CSV_DIR';
      --XXCSO:HTT連携用CSVファイル出力先      
    cv_file_name        CONSTANT VARCHAR2(100)  := 'XXCSO1_HHT_OUT_CSV_DAY_PLAN';
      --XXCSO:HTT連携用CSVファイル名
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
    lv_file_dir       VARCHAR2(1000);      --XXCSO:HTT連携用CSVファイル出力先
    lv_file_name      VARCHAR2(1000);      --XXCSO:HTT連携用CSVファイル名
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================
    -- プロファイル値を取得
    -- ===============================
--
    fnd_profile.get(
                  cv_file_dir
                 ,lv_file_dir
    );  --CSVファイル出力先の値取得
    fnd_profile.get(
                  cv_file_name
                 ,lv_file_name
    );  --CSVファイル名の値取得
    -- *** DEBUG_LOG ***
    -- 取得したプロファイル値をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg7  || CHR(10) ||
                 cv_debug_msg9  || lv_file_dir    || CHR(10) ||
                 cv_debug_msg10 || lv_file_name     || CHR(10) ||
                 ''
    );
    --戻り値が「NULL」であった場合,例外処理を行う
    --XXCSO:HTT連携用CSVファイル出力先
    IF (lv_file_dir IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name              -- アプリケーション短縮名
                        ,iv_name         => cv_profile_get_tkn       -- メッセージコード
                        ,iv_token_name1  => cv_tkn_prof_name         -- トークンコード1
                        ,iv_token_value1 => cv_file_dir              -- トークン値1CSVファイル出力先
      );
      lv_errbuf  := lv_errmsg||SQLERRM;
      RAISE global_api_expt;
    END IF;
    --XXCSO:HTT連携用CSVファイル名
    IF (lv_file_name IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name              -- アプリケーション短縮名
                        ,iv_name         => cv_profile_get_tkn       -- メッセージコード
                        ,iv_token_name1  => cv_tkn_prof_name         -- トークンコード1
                        ,iv_token_value1 => cv_file_name             -- トークン値1CSVファイル名
      );
      lv_errbuf  := lv_errmsg||SQLERRM;
      RAISE global_api_expt;
    END IF;
    --インターフェースファイル名メッセージ出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_intf_file_name
                    ,iv_token_name1  => cv_tkn_csv_name
                    ,iv_token_value1 => lv_file_name
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''           || CHR(10) ||   -- 空行の挿入
                   gv_out_msg || CHR(10) ||
                 ''                   -- 空行の挿入
    );
    -- 取得したCSVファイル出力先とファイル名をOUTパラメータに設定
    ov_file_dir   := lv_file_dir;       --XXCSO:HTT連携用CSVファイル出力先
    ov_file_name  := lv_file_name;      --XXCSO:HTT連携用CSVファイル名
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_profile_info;
--
  /**********************************************************************************
   * Procedure Name   : open_csv_file
   * Description      : CSVファイルオープン (A-5)
   ***********************************************************************************/
  PROCEDURE open_csv_file(
    iv_file_dir             IN  VARCHAR2,               -- XXCSO:HTT連携用CSVファイル出力先
    iv_file_name            IN  VARCHAR2,               -- XXCSO:HTT連携用CSVファイル名
    ov_errbuf               OUT NOCOPY VARCHAR2,        -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,        -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'open_csv_file';     -- プログラム名
--
    cv_open_writer          CONSTANT VARCHAR2(100)  := 'W';                 -- 入出力モード
    cv_csv_in_tkn           CONSTANT VARCHAR2(100)  := 'APP-XXCSO1-00123';  -- CSVファイル残存エラー
    cv_csv_open_tkn         CONSTANT VARCHAR2(100)  := 'APP-XXCSO1-00015';  -- CSVファイルオープンエラー

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
    lv_file_dir       VARCHAR2(1000);      --XXCSO:HTT連携用CSVファイル出力先
    lv_file_name      VARCHAR2(1000);      --XXCSO:HTT連携用CSVファイル名
    lv_exists         BOOLEAN;             --存在チェック結果
    lv_file_length    VARCHAR2(1000);      --ファイルサイズ
    lv_blocksize      VARCHAR2(1000);      --ブロックサイズ
    -- ファイルオープン確認戻り値格納
    lb_fopn_retcd   BOOLEAN;
    -- *** ローカル例外 ***
    file_err_expt   EXCEPTION;  -- ファイル処理例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- INパラメータをローカル変数に代入
    lv_file_dir   := iv_file_dir;       --XXCSO:HTT連携用CSVファイル出力先
    lv_file_name  := iv_file_name;      --XXCSO:HTT連携用CSVファイル名
    -- ========================
    -- CSVファイル存在チェック 
    -- ========================
    UTL_FILE.FGETATTR(
                  location    => lv_file_dir
                 ,filename    => lv_file_name
                 ,fexists     => lv_exists
                 ,file_length => lv_file_length
                 ,block_size  => lv_blocksize
    );
    --CSVファイルが存在した場合
    IF (lv_exists = cb_true) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name              -- アプリケーション短縮名
                        ,iv_name         => cv_csv_in_tkn            -- メッセージコード
                        ,iv_token_name1  => cv_tkn_csv_location      -- トークンコード1
                        ,iv_token_value1 => lv_file_dir              -- トークン値1CSVファイル出力先
                        ,iv_token_name2  => cv_tkn_csv_file_name     -- トークンコード1
                        ,iv_token_value2 => lv_file_name             -- トークン値1CSVファイル名
      );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE file_err_expt;
    END IF;
    BEGIN
      -- ========================
      -- CSVファイルオープン 
      -- ========================
        gf_file_hand := UTL_FILE.FOPEN(
                           location   => lv_file_dir
                          ,filename   => lv_file_name
                          ,open_mode  => cv_open_writer
        );
      -- *** DEBUG_LOG ***
      -- ファイルオープンしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg12   || CHR(10)   ||
                   cv_debug_msg_fnm || lv_file_name || CHR(10) ||
                   ''
      );
      EXCEPTION
        WHEN UTL_FILE.INVALID_PATH       OR       -- ファイルパス不正エラー
             UTL_FILE.INVALID_MODE       OR       -- open_modeパラメータ不正エラー
             UTL_FILE.INVALID_OPERATION  OR       -- オープン不可能エラー
             UTL_FILE.INVALID_MAXLINESIZE  THEN   -- MAX_LINESIZE値無効エラー
          -- エラーメッセージ取得
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name              -- アプリケーション短縮名
                        ,iv_name         => cv_csv_open_tkn          -- メッセージコード
                        ,iv_token_name1  => cv_tkn_csv_location      -- トークンコード1
                        ,iv_token_value1 => lv_file_dir              -- トークン値1CSVファイル出力先
                        ,iv_token_name2  => cv_tkn_csv_file_name     -- トークンコード1
                        ,iv_token_value2 => lv_file_name             -- トークン値1CSVファイル名
          );
          lv_errbuf := lv_errmsg || SQLERRM;
          RAISE file_err_expt;
    END;
--
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
--
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
                   ''
      );
      END IF;
--
      -- 取得したパラメータをOUTパラメータに設定
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
--
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
                   ''
      );
      END IF;
--
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
--
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
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
--
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END open_csv_file;
--
  /**********************************************************************************
   * Procedure Name   : create_csv_rec
   * Description      : CSVファイル出力 (A-7)
   ***********************************************************************************/
  PROCEDURE create_csv_rec(
    it_sales_plan_day_table_list  IN  g_csv_get_sales_plan_day_ttype,  -- 日別売上計画を格納する配列
    iv_sysdate                    IN  VARCHAR2,                        -- システム日付
    ov_errbuf                     OUT NOCOPY VARCHAR2,                 -- エラー・メッセージ           --# 固定 #
    ov_retcode                    OUT NOCOPY VARCHAR2,                 -- リターン・コード             --# 固定 #
    ov_errmsg                     OUT NOCOPY VARCHAR2                  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'create_csv_rec';       -- プログラム名
    cv_sep_com              CONSTANT VARCHAR2(3)    := ',';
    cv_sep_wquot            CONSTANT VARCHAR2(3)    := '"';
--
    cv_csv_create_tkn       CONSTANT VARCHAR2(100)  := 'APP-XXCSO1-00065';     -- CSVファイル出力エラー
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--_
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    lv_data                        VARCHAR2(5000);                  -- 編集データ
    lv_sysdate                     VARCHAR2(100);                   -- システム日付
    lt_sales_plan_day_table_list   g_csv_get_sales_plan_day_ttype;  -- 日別売上計画を格納する配列
    -- *** ローカル例外 ***
    file_put_line_expt             EXCEPTION;                       -- データ出力処理例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- INパラメータをローカル変数に代入
    lv_sysdate                    := iv_sysdate;                         -- システム日付
    lt_sales_plan_day_table_list  := it_sales_plan_day_table_list;       -- 日別売上計画を格納する配列
    BEGIN
    -- 対象件数カウントアップ
    gn_target_cnt := gn_target_cnt + 1;
--
      --データ作成
      lv_data := cv_sep_wquot || lt_sales_plan_day_table_list(1) || cv_sep_wquot                -- 売上拠点コード
         || cv_sep_com || cv_sep_wquot || lt_sales_plan_day_table_list(2) || cv_sep_wquot        -- 顧客コード
        || cv_sep_com || lt_sales_plan_day_table_list(3);                                        -- 年月
      FOR i IN 1..31 LOOP
        lv_data := lv_data ||  cv_sep_com || lt_sales_plan_day_table_list(i+3);
      END LOOP;
      lv_data := lv_data ||  cv_sep_com || cv_sep_wquot || lv_sysdate || cv_sep_wquot;
      -- データ出力
      UTL_FILE.PUT_LINE(
         file   => gf_file_hand
        ,buffer => lv_data
      );
      -- データ初期化
      FOR j IN 1..35 LOOP
        lt_sales_plan_day_table_list(j) := NULL;
      END LOOP;
    EXCEPTION
      WHEN UTL_FILE.INVALID_FILEHANDLE OR     -- ファイル・ハンドル無効エラー
           UTL_FILE.INVALID_OPERATION  OR     -- オープン不可能エラー
           UTL_FILE.WRITE_ERROR  THEN         -- 書込み操作中オペレーティングエラー
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                       --アプリケーション短縮名
                     ,iv_name         => cv_csv_create_tkn                 --メッセージコード
                     ,iv_token_name1  => cv_tkn_customer_cd                --トークンコード1
                     ,iv_token_value1 => lt_sales_plan_day_table_list(2)   --トークン値1顧客コード
                     ,iv_token_name2  => cv_tkn_location_cd                --トークンコード2
                     ,iv_token_value2 => lt_sales_plan_day_table_list(1)   --トークン値2売上拠点コード
                     ,iv_token_name3  => cv_tkn_year_month                 --トークンコード3
                     ,iv_token_value3 => lt_sales_plan_day_table_list(3)   --トークン値3年月
                     ,iv_token_name4  => cv_tkn_err_msg                    --トークンコード4
                     ,iv_token_value4 => SQLERRM                           --トークン値4
                    );
        lv_errbuf := lv_errmsg || SQLERRM;
      RAISE file_put_line_expt;
    END;
    -- 正常件数カウントアップ
    gn_normal_cnt := gn_normal_cnt + 1;
--
  EXCEPTION
    -- *** ファイル処理例外ハンドラ ***
    WHEN file_put_line_expt THEN
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END create_csv_rec;
--
  /**********************************************************************************
   * Procedure Name   : close_csv_file
   * Description      : CSVファイルクローズ処理 (A-8)
   ***********************************************************************************/
  PROCEDURE close_csv_file(
     iv_file_dir       IN  VARCHAR2         -- CSVファイル出力先
    ,iv_file_name      IN  VARCHAR2         -- CSVファイル名
    ,ov_errbuf         OUT NOCOPY VARCHAR2  -- エラー・メッセージ              --# 固定 #
    ,ov_retcode        OUT NOCOPY VARCHAR2  -- リターン・コード                --# 固定 #
    ,ov_errmsg         OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ    --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'close_csv_file';    -- プログラム名
--
    cv_csv_close_tkn    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00018';  -- CSVファイルクローズエラー
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    -- ファイルオープン確認戻り値格納
    lb_fopn_retcd   BOOLEAN;
    -- *** ローカル例外 ***
    file_err_expt   EXCEPTION;  -- ファイル処理例外
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
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg13   || CHR(10)   ||
                   cv_debug_msg_fnm || iv_file_name || CHR(10) ||
                   ''
      );
      EXCEPTION
        WHEN UTL_FILE.WRITE_ERROR          OR     -- オペレーティングシステムエラー
             UTL_FILE.INVALID_FILEHANDLE   THEN   -- ファイル・ハンドル無効エラー
          -- エラーメッセージ取得
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name                  --アプリケーション短縮名
                        ,iv_name         => cv_csv_close_tkn             --メッセージコード
                        ,iv_token_name1  => cv_tkn_csv_location          --トークンコード1
                        ,iv_token_value1 => iv_file_dir                  --トークン値1
                        ,iv_token_name2  => cv_tkn_csv_file_name         --トークンコード1
                        ,iv_token_value2 => iv_file_name                 --トークン値1
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
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
                   ''
      );
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
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
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
--
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
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
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END close_csv_file;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   ***********************************************************************************/
  PROCEDURE submain(
     ov_errbuf           OUT NOCOPY VARCHAR2   -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ    --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100) := 'submain';           -- プログラム名
--
    cv_app_day_plan_tkn    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00024';  -- 顧客別日別売上計画データ抽出エラー
    cv_csv_0_tkn           CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00224';  -- CSVファイル出力0件エラー
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
---- *** ローカル定数 ***
    cv_sep_com              CONSTANT VARCHAR2(3)     := ',';
    cv_sep_wquot            CONSTANT VARCHAR2(3)     := '"';
    cv_app_day_plans        CONSTANT VARCHAR2(100)   := '顧客別日別売上計画テーブル';
    -- *** ローカル変数 ***
    --
    lt_sales_base_code     xxcso_account_sales_plans.base_code%TYPE;           -- 売上拠点コード
    lt_account_number      xxcso_account_sales_plans.account_number%TYPE;      -- 顧客コード
    lt_year_month          xxcso_account_sales_plans.year_month%TYPE;          -- 年月
    lt_plan_day            xxcso_account_sales_plans.plan_day%TYPE;            -- 日
    lt_sales_plan_day_amt  xxcso_account_sales_plans.sales_plan_day_amt%TYPE;  -- 日別売上計画
    --
    lv_sysdate             VARCHAR2(100);                                      -- システム日付
    ld_process_date        DATE;                                               -- 業務処理日
    lv_target_cnt          NUMBER;                                             -- 処理対象件数格納
    ln_table_no            NUMBER;                                             -- レコードに対する配列表の日
    lb_csv_putl_rec        VARCHAR2(2000);                                     -- CSVファイル出力判断
    lv_file_dir            VARCHAR2(2000);                                     -- CSVファイル出力先
    lv_file_name           VARCHAR2(2000);                                     -- CSVファイル名
    lv_table_no            NUMBER;                                             -- 表のNUMBER
    lv_data                VARCHAR2(5000);                                     -- 編集データ
    lv_process_date        VARCHAR2(100);                                      -- 業務処理日
    lv_process_date_add    VARCHAR2(100);                                      -- 業務処理日(翌月)
    lv_taget_cnt           NUMBER;                                             -- ループ件数
    -- ファイルオープン確認戻り値格納
    lb_fopn_retcd   BOOLEAN;
    -- メッセージ出力用
    lv_msg          VARCHAR2(2000);
    -- *** ローカル・カーソル ***
    CURSOR xsasp_data_cur
    IS
      SELECT     xsasp.base_code base_code                     -- 売上拠点コード
                ,xsasp.account_number account_number           -- 顧客コード
                ,xsasp.year_month year_month                   -- 年月
                ,xsasp.plan_day plan_day                       -- 日
                ,xsasp.sales_plan_day_amt sales_plan_day_amt   -- 日別売上計画
      FROM       xxcso_account_sales_plans xsasp               -- 顧客別売上計画テーブル
      WHERE      xsasp.year_month BETWEEN lv_process_date AND lv_process_date_add
        AND      TO_CHAR(xsasp.last_update_date,'YYYYMMDD') BETWEEN gv_from_value AND gv_to_value
        AND      xsasp.month_date_div = cv_monday_kbn_day
      ORDER BY   xsasp.base_code        ASC                     -- 売上拠点コード
                ,xsasp.account_number   ASC                     -- 顧客コード
                ,xsasp.year_month       ASC                     -- 年月
                ,xsasp.plan_day         ASC;                    -- 日
    -- *** ローカル・レコード ***
    l_xsasp_data_rec   xsasp_data_cur%ROWTYPE;
    --*** ローカルPL/SQL表 ***
    l_sales_plan_day_table_list g_csv_get_sales_plan_day_ttype;
    -- *** ローカル例外 ***
    no_data_expt       EXCEPTION;
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
    -- データ初期化
    FOR j IN 1..35 LOOP
      l_sales_plan_day_table_list(j) := NULL;
    END LOOP;
--
    -- ================================
    -- A-1.初期処理 
    -- ================================
    init(
      ov_sysdate          => lv_sysdate,  -- システム日付
      ov_errbuf           => lv_errbuf,   -- エラー・メッセージ            --# 固定 #
      ov_retcode          => lv_retcode,  -- リターン・コード              --# 固定 #
      ov_errmsg           => lv_errmsg    -- ユーザー・エラー・メッセージ  --# 固定 #
    ); 
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ================================
    -- A-2.パラメータデフォルトセット 
    -- ================================
    set_parm_def(
      od_process_date     => ld_process_date,     -- 業務処理日
      ov_errbuf           => lv_errbuf,           -- エラー・メッセージ            --# 固定 #
      ov_retcode          => lv_retcode,          -- リターン・コード              --# 固定 #
      ov_errmsg           => lv_errmsg            -- ユーザー・エラー・メッセージ    --# 固定 #
    );
    lv_process_date      := TO_CHAR(ld_process_date, 'YYYYMM');
    lv_process_date_add  := TO_CHAR(ADD_MONTHS(ld_process_date, 1), 'YYYYMM');
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ================================
    -- A-3.パラメータチェック 
    -- ================================
    chk_parm_date(
      ov_errbuf           => lv_errbuf,         -- エラー・メッセージ            --# 固定 #
      ov_retcode          => lv_retcode,        -- リターン・コード              --# 固定 #
      ov_errmsg           => lv_errmsg          -- ユーザー・エラー・メッセージ    --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =================================================
    -- A-4.プロファイル値を取得 
    -- =================================================
    get_profile_info(
       ov_file_dir   => lv_file_dir   -- CSVファイル出力先
      ,ov_file_name  => lv_file_name  -- CSVファイル名
      ,ov_errbuf     => lv_errbuf     -- エラー・メッセージ            --# 固定 #
      ,ov_retcode    => lv_retcode    -- リターン・コード              --# 固定 #
      ,ov_errmsg     => lv_errmsg     -- ユーザー・エラー・メッセージ    --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =================================================
    -- A-5.CSVファイルオープン 
    -- =================================================
    open_csv_file(
       iv_file_dir  => lv_file_dir   -- CSVファイル出力先
      ,iv_file_name => lv_file_name  -- CSVファイル名
      ,ov_errbuf    => lv_errbuf     -- エラー・メッセージ            --# 固定 #
      ,ov_retcode   => lv_retcode    -- リターン・コード              --# 固定 #
      ,ov_errmsg    => lv_errmsg     -- ユーザー・エラー・メッセージ    --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    -- カーソルオープン
    OPEN xsasp_data_cur;
    -- *** DEBUG_LOG ***
    -- カーソルオープンしたことをログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_copn || CHR(10) ||
                 ''
    );
--
    <<get_data_loop>>
    LOOP
--
      BEGIN
        FETCH xsasp_data_cur INTO l_xsasp_data_rec;
--      
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_app_name               -- アプリケーション短縮名
                              ,iv_name         => cv_app_day_plan_tkn       -- メッセージコード
                              ,iv_token_name1  => cv_table                  -- トークンコード1
                              ,iv_token_value1 => cv_app_day_plans          -- トークン値1パラメータ
                              ,iv_token_name2  => cv_tkn_err_msg            -- トークンコード2
                              ,iv_token_value2 => SQLERRM                   -- トークン値2リターンステータス
              );
          lv_errbuf  := lv_errmsg||SQLERRM;
        RAISE global_process_expt;
      END;
      -- 処理対象件数格納
      lv_taget_cnt := xsasp_data_cur%ROWCOUNT;
      -- 対象件数がO件の場合
      EXIT WHEN xsasp_data_cur%NOTFOUND
      OR  xsasp_data_cur%ROWCOUNT = 0;
      -- 取得データを格納
      lt_sales_base_code      := l_xsasp_data_rec.base_code;           -- 売上拠点コード
      lt_account_number       := l_xsasp_data_rec.account_number;      -- 顧客コード
      lt_year_month           := l_xsasp_data_rec.year_month;          -- 年月
      lt_plan_day             := l_xsasp_data_rec.plan_day;            -- 日
      lt_sales_plan_day_amt   := l_xsasp_data_rec.sales_plan_day_amt;  --日別売上計画
      --配列にデータをセット
      lv_table_no    := TO_NUMBER(lt_plan_day) + 3;
      --日別売上計画をセット
      IF (lv_taget_cnt = 1) THEN  --最初値の場合
        l_sales_plan_day_table_list(1)           := TO_CHAR(lt_sales_base_code);
        l_sales_plan_day_table_list(2)           := lt_account_number;
        l_sales_plan_day_table_list(3)           := lt_year_month;
        l_sales_plan_day_table_list(lv_table_no) := TO_CHAR(lt_sales_plan_day_amt);
      ELSIF ((l_sales_plan_day_table_list(1)       = TO_CHAR(lt_sales_base_code))
          AND (l_sales_plan_day_table_list(2)      = lt_account_number)
          AND (l_sales_plan_day_table_list(3)      = lt_year_month)) THEN  
        l_sales_plan_day_table_list(lv_table_no) := TO_CHAR(lt_sales_plan_day_amt);
      ELSIF ((l_sales_plan_day_table_list(1) IS NOT NULL)
          AND (l_sales_plan_day_table_list(2) IS NOT NULL)
          AND (l_sales_plan_day_table_list(3) IS NOT NULL))THEN
--
        -- ========================================
        -- A-7.CSVファイル出力 
        -- ========================================
        create_csv_rec(
          it_sales_plan_day_table_list  =>  l_sales_plan_day_table_list  -- 日別売上計画を格納する配列
         ,iv_sysdate                    =>  lv_sysdate                   -- システム日付
         ,ov_errbuf                     =>  lv_errbuf                    -- エラー・メッセージ
         ,ov_retcode                    =>  lv_retcode                   -- リターン・コード
         ,ov_errmsg                     =>  lv_errmsg                    -- ユーザー・エラー・メッセージ
        );
        --
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lv_retcode = cv_status_warn) THEN
          -- ステータスは警告、その次にデータ初期化を行う
          ov_retcode := cv_status_warn;
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
        -- データ初期化
        FOR j IN 1..35 LOOP
          l_sales_plan_day_table_list(j) := NULL;
        END LOOP;
        l_sales_plan_day_table_list(1)           := TO_CHAR(lt_sales_base_code);
        l_sales_plan_day_table_list(2)           := lt_account_number;
        l_sales_plan_day_table_list(3)           := lt_year_month;
        l_sales_plan_day_table_list(lv_table_no) := TO_CHAR(lt_sales_plan_day_amt);
      END IF;
    END LOOP get_data_loop;
--
    IF (lv_taget_cnt = 0) THEN  --出力件数が０件の場合、メッセージを出力する
      gv_out_msg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --アプリケーション短縮名
                    ,iv_name         => cv_csv_0_tkn                 --メッセージコード
                   );
      lv_errbuf  := gv_out_msg||SQLERRM;
      fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''           || CHR(10) ||   -- 空行の挿入
                   gv_out_msg ||
                 ''                   -- 空行の挿入
      );
    ELSE  --ループが終わった場合、CSVファイルを出力 
      -- ========================================
      -- A-7.CSVファイル出力 
      -- ========================================
      create_csv_rec(
            it_sales_plan_day_table_list  =>  l_sales_plan_day_table_list  -- 日別売上計画を格納する配列
           ,iv_sysdate                    =>  lv_sysdate                   -- システム日付
           ,ov_errbuf                     =>  lv_errbuf                    -- エラー・メッセージ
           ,ov_retcode                    =>  lv_retcode                   -- リターン・コード
           ,ov_errmsg                     =>  lv_errmsg                    -- ユーザー・エラー・メッセージ
          );
      --
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_warn) THEN
        -- ステータスは警告、その次にデータ初期化を行う
        ov_retcode := cv_status_warn;
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
      -- データ初期化
      FOR j IN 1..35 LOOP
        l_sales_plan_day_table_list(j) := NULL;
      END LOOP;
    END IF;
--
    -- カーソルクローズ
    CLOSE xsasp_data_cur;
    -- *** DEBUG_LOG ***
    -- カーソルクローズしたことをログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_ccls1 || CHR(10) ||
                 ''
    );
--
    -- ========================================
    -- A-8.CSVファイルクローズ  
    -- ========================================
--
    close_csv_file(
       iv_file_dir   => lv_file_dir   -- CSVファイル出力先
      ,iv_file_name  => lv_file_name  -- CSVファイル名
      ,ov_errbuf     => lv_errbuf     -- エラー・メッセージ            --# 固定 #
      ,ov_retcode    => lv_retcode    -- リターン・コード              --# 固定 #
      ,ov_errmsg     => lv_errmsg     -- ユーザー・エラー・メッセージ    --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;  
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
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
        -- *** DEBUG_LOG ***
        -- ファイルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_fcls || CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err6 || cv_msg_part ||
                     cv_debug_msg_fnm  || lv_file_name   || CHR(10) ||
                     ''
        );
      END IF;
      -- カーソルがクローズされていない場合
      IF (xsasp_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE xsasp_data_cur;
        -- *** DEBUG_LOG ***
        -- カーソルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_ccls2|| CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err6 || CHR(10) ||
                     ''
        );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
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
        -- *** DEBUG_LOG ***
        -- ファイルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_fcls || CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err3 || cv_msg_part ||
                     cv_debug_msg_fnm  || lv_file_name   || CHR(10) ||
                     ''
        );
      END IF;
      -- カーソルがクローズされていない場合
      IF (xsasp_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE xsasp_data_cur;
        -- *** DEBUG_LOG ***
        -- カーソルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_ccls2|| CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err3 || CHR(10) ||
                    ''
       );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
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
        -- *** DEBUG_LOG ***
        -- ファイルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_fcls || CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err4 || cv_msg_part ||
                     cv_debug_msg_fnm  || lv_file_name   || CHR(10) ||
                     ''
        );
      END IF;
      -- カーソルがクローズされていない場合
      IF (xsasp_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE xsasp_data_cur;
        -- *** DEBUG_LOG ***
        -- カーソルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_ccls2|| CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err4 || CHR(10) ||
''
       );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
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
     errbuf              OUT NOCOPY VARCHAR2     -- エラー・メッセージ  --# 固定 #
    ,retcode             OUT NOCOPY VARCHAR2     -- リターン・コード    --# 固定 #
    ,iv_from_value       IN VARCHAR2             -- 更新日FROM(YYYYMMDD)
    ,iv_to_value         IN VARCHAR2             -- 更新日TO(YYYYMMDD)
    )
--
--###########################  固定部 START   ###########################
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
    -- INパラメータをローカル変数に代入
    gv_from_value        := iv_from_value;     -- 更新日FROM(YYYYMMDD)
    gv_to_value          := iv_to_value;       -- 更新日TO(YYYYMMDD)
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       ov_errbuf      => lv_errbuf          -- エラー・メッセージ            --# 固定 #
      ,ov_retcode     => lv_retcode         -- リターン・コード              --# 固定 #
      ,ov_errmsg      => lv_errmsg          -- ユーザー・エラー・メッセージ  --# 固定 #
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
    -- =======================
    -- A-9.終了処理 
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
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF (lv_retcode = cv_status_warn) THEN
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
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --ステータスセット
    retcode := lv_retcode;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      retcode := cv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCSO014A08C;
/
