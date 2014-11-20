CREATE OR REPLACE PACKAGE BODY APPS.XXCSO016A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO016A06C(body)
 * Description      : 物件(自販機)の移動履歴情報を情報系システムに送信するためのCSVファイルを作成します。
 *                    
 * MD.050           : MD050_CSO_016_A06_情報系-EBSインターフェース：(OUT)什器移動明細
 *                    
 * Version          : 1.5
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  init                        初期処理 (A-1)
 *  set_parm_def                パラメータデフォルトセット (A-2)
 *  chk_parm_date               パラメータチェック (A-3)
 *  get_profile_info            プロファイル値取得 (A-4)
 *  open_csv_file               CSVファイルオープン (A-5)
 *  get_csv_data                CSVファイルに出力する関連情報取得 (A-7)
 *  create_csv_rec              CSVファイル出力 (A-8)
 *  close_csv_file              CSVファイルクローズ処理 (A-9)
 *  submain                     メイン処理プロシージャ
 *                                什器移動明細データ抽出 (A-6)
 *  main                        コンカレント実行ファイル登録プロシージャ
 *                                  終了処理 (A-10)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-01-21    1.0   Syoei.Kin        新規作成
 *  2009-02-24    1.1   K.Sai            レビュー後対応 
 *  2009-05-01    1.2   Tomoko.Mori      T1_0897対応
 *  2009-06-15    1.3   Kazuyo.Hosoi     T1_1240対応
 *  2009-10-01    1.4   Daisuke.Abe      0001452対応
 *  2009-11-25    1.5   Daisuke.Abe      E_本稼動_00045対応
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
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO016A06C';  -- パッケージ名
  cv_app_name            CONSTANT VARCHAR2(10)  := 'XXCSO';         -- アプリケーション短縮名
  cv_appl_short_name     CONSTANT VARCHAR2(10)  := 'XXCCP';         -- アドオン：共通・IF領域
--
  cv_active_status       CONSTANT VARCHAR2(1)   := 'A';             -- アクティブ
  cn_job_kbn_1           CONSTANT NUMBER        := 1;               -- 什器移動区分(1[新台設置])
  cn_job_kbn_2           CONSTANT NUMBER        := 2;               -- 什器移動区分(2[旧台設置])
  cn_job_kbn_3           CONSTANT NUMBER        := 3;               -- 什器移動区分(3[新台代替])
  cn_job_kbn_4           CONSTANT NUMBER        := 4;               -- 什器移動区分(4[旧台代替])
  cn_job_kbn_5           CONSTANT NUMBER        := 5;               -- 什器移動区分(5[引揚])
  cn_job_kbn_6           CONSTANT NUMBER        := 6;               -- 什器移動区分(6[店内移動])
  cn_job_kbn_8           CONSTANT NUMBER        := 8;               -- 什器移動区分(8[是正])
  cn_job_kbn_15          CONSTANT NUMBER        := 15;              -- 什器移動区分(15[転送])
  cn_job_kbn_16          CONSTANT NUMBER        := 16;              -- 什器移動区分(16[転売])
  /* 2009.06.09 K.Hosoi T1_1240 対応 START */
--  cn_job_kbn_17          CONSTANT NUMBER        := 17;              -- 什器移動区分(17[廃棄引取])
  cn_job_kbn_dspsl_lv    CONSTANT NUMBER        := 18;              -- 什器移動区分(18[廃棄引取])
  /* 2009.06.09 K.Hosoi T1_1240 対応 END */
--
  -- メッセージコード
  cv_tkn_number_01    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011';     -- 業務処理日付取得エラーメッセージ
  cv_tkn_number_02    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00012';     -- 日付書式エラーメッセージ
  cv_tkn_number_03    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00013';     -- パラメータ整合性エラーメッセージ
  cv_tkn_number_04    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00014';     -- プロファイル取得エラーメッセージ
  cv_tkn_number_05    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00123';     -- CSVファイル残存エラーメッセージ
  cv_tkn_number_06    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00015';     -- CSVファイルオープンエラーメッセージ
  cv_tkn_number_07    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00016';     -- データ抽出エラーメッセージ
  cv_tkn_number_08    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00296';     -- 拠点(部門)コードなし警告メッセージ
  cv_tkn_number_09    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00297';     -- CSVファイル出力エラーメッセージ
  cv_tkn_number_10    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00018';     -- CSVファイルクローズエラーメッセージ
  cv_tkn_number_11    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00152';     -- インターフェースファイル名
  cv_tkn_number_12    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00145';     -- パラメータ更新日FROM
  cv_tkn_number_13    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00146';     -- パラメータ更新日TO
  cv_tkn_number_14    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00150';     -- パラメータデフォルトセット
  -- トークンコード
  cv_tkn_err_msg         CONSTANT VARCHAR2(20) := 'ERR_MSG';            -- SQLエラーメッセージ
  cv_tkn_err_message     CONSTANT VARCHAR2(20) := 'ERR_MESSAGE';       -- SQLエラーメッセージ
  cv_tkn_value           CONSTANT VARCHAR2(20) := 'VALUE';              -- 入力されたパラメータの値
  cv_tkn_status          CONSTANT VARCHAR2(20) := 'STATUS';             -- リターンステータス
  cv_tkn_from_value      CONSTANT VARCHAR2(20) := 'FROM_VALUE';         -- 更新日FROMにセットされたパラメータ値
  cv_tkn_to_value        CONSTANT VARCHAR2(20) := 'TO_VALUE';           -- 更新日TOにセットされたパラメータ値
  cv_tkn_prof_name       CONSTANT VARCHAR2(20) := 'PROF_NAME';          -- プロファイル名
  cv_tkn_csv_location    CONSTANT VARCHAR2(20) := 'CSV_LOCATION';       -- CSVファイル出力先
  cv_tkn_csv_file_name   CONSTANT VARCHAR2(20) := 'CSV_FILE_NAME';      -- CSVファイル名
  cv_tkn_slip_no         CONSTANT VARCHAR2(20) := 'SLIP_NO';            -- 伝票番号
  cv_tkn_line_no         CONSTANT VARCHAR2(20) := 'LINE_NO';            -- 行番号
  cv_tkn_year_month_day  CONSTANT VARCHAR2(20) := 'YEAR_MONTH_DAY';     -- 年月日
  cv_tkn_object_cd       CONSTANT VARCHAR2(20) := 'OBJECT_CD';          -- 物件コード
  cv_tkn_object_cd1      CONSTANT VARCHAR2(20) := 'OBJECT_CD1';         -- 物件コード1
  cv_tkn_object_cd2      CONSTANT VARCHAR2(20) := 'OBJECT_CD2';         -- 物件コード2
  cv_tkn_work_kbn        CONSTANT VARCHAR2(20) := 'WORK_KBN';           -- 作業区分
  cv_tkn_proc_name       CONSTANT VARCHAR2(20) := 'PROCESSING_NAME';    -- 抽出処理名
  cv_tkn_message         CONSTANT VARCHAR2(20) := 'MESSAGE';            -- メッセージ
  cv_tkn_table           CONSTANT VARCHAR2(20) := 'TABLE';              -- テーブル名
--
  cb_true                CONSTANT BOOLEAN := TRUE;
  cb_false               CONSTANT BOOLEAN := FALSE;
--
  -- DEBUG_LOG用メッセージ
  
  cv_debug_msg1           CONSTANT VARCHAR2(200) := '<< システム日付取得処理 >>';
  cv_debug_msg2           CONSTANT VARCHAR2(200) := 'lv_sysdate          = ';
  cv_debug_msg3           CONSTANT VARCHAR2(200) := '<< 業務処理日付取得処理 >>';
  cv_debug_msg4           CONSTANT VARCHAR2(200) := 'ld_process_date = ';
  cv_debug_msg5           CONSTANT VARCHAR2(200) := '<< プロファイル値取得処理 >>';
  cv_debug_msg6           CONSTANT VARCHAR2(200) := 'lv_file_dir         = ';
  cv_debug_msg7           CONSTANT VARCHAR2(200) := 'lv_file_name        = ';
  cv_debug_msg8           CONSTANT VARCHAR2(200) := 'lv_company_cd       = ';
  cv_debug_msg10           CONSTANT VARCHAR2(200) := '<< CSVファイルをオープンしました >>' ;
  cv_debug_msg11          CONSTANT VARCHAR2(200) := '<< CSVファイルをクローズしました >>' ;
  cv_debug_msg12          CONSTANT VARCHAR2(200) := '<< ロールバックしました >>' ;
--
  cv_debug_msg_fnm        CONSTANT VARCHAR2(200) := 'filename = ';
  cv_debug_msg_fcls       CONSTANT VARCHAR2(200) := '<< 例外処理内でCSVファイルをクローズしました >>';
  cv_debug_msg_copn       CONSTANT VARCHAR2(200) := '<< カーソルをオープンしました >>';
  cv_debug_msg_ccls1      CONSTANT VARCHAR2(200) := '<< カーソルをクローズしました >>';
  cv_debug_msg_ccls2      CONSTANT VARCHAR2(200) := '<< 例外処理内でカーソルをクローズしました >>';
  cv_debug_msg_err1       CONSTANT VARCHAR2(200) := 'file_err_expt';
  cv_debug_msg_err2       CONSTANT VARCHAR2(200) := 'global_api_expt';
  cv_debug_msg_err3       CONSTANT VARCHAR2(200) := 'global_api_others_expt';
  cv_debug_msg_err4       CONSTANT VARCHAR2(200) := 'others例外';
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
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 什器移動明細情報データ
    TYPE g_value_rtype IS RECORD(
      company_cd                VARCHAR2(100),                                   -- 会社コード
      slip_no                   xxcso_in_work_data.slip_no%TYPE,                 -- 伝票番号
      line_number               xxcso_in_work_data.line_number%TYPE,             -- 行番号
      year_month_day            NUMBER,                                          -- 年月日
      install_code1             xxcso_in_work_data.install_code1%TYPE,           -- 物件コード1(設置用)
      install_code2             xxcso_in_work_data.install_code2%TYPE,           -- 物件コード2(引揚用)
      sale_base_code_s          xxcmm_cust_accounts.sale_base_code%TYPE,         -- 拠点(部門)コード(設置用)
      sale_base_code_w          xxcmm_cust_accounts.sale_base_code%TYPE,         -- 拠点(部門)コード(引揚用)
      job_kbn                   xxcso_in_work_data.job_kbn%TYPE,                 -- 什器移動区分
      delete_flag               xxcso_in_work_data.delete_flag%TYPE,             -- 削除フラグ
      sysdate_now               VARCHAR2(100)                                    -- 連携日時
    );
  --*** データ登録、更新例外 ***
  global_ins_upd_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_ins_upd_expt,-30000);
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理 (A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_sysdate          OUT NOCOPY VARCHAR2,  -- システム日付
    ov_errbuf           OUT NOCOPY VARCHAR2,  -- エラー・メッセージ            --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,  -- リターン・コード              --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'init';             -- プログラム名
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
    lv_sysdate           VARCHAR2(100);    -- システム日付
    lv_init_msg          VARCHAR2(5000);   -- エラーメッセージを格納
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- システム日付取得
    lv_sysdate := TO_CHAR(SYSDATE,'YYYYMMDDHH24MISS');
    -- 取得したシステム日付をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg1  || CHR(10) ||
                 cv_debug_msg2  || lv_sysdate || CHR(10) ||
                 ''
    );
--
    -- 取得したシステム日付をOUTパラメータに設定
    ov_sysdate := lv_sysdate;
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : set_parm_def                                  
   * Description      : パラメータデフォルトセット (A-2)
   ***********************************************************************************/
  PROCEDURE set_parm_def(
    ov_errbuf               OUT NOCOPY VARCHAR2,        -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,        -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ   --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'set_parm_def';      -- プログラム名
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
    lb_check               BOOLEAN;         -- パラメータデフォルトセットチェック
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
    lv_param_set := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_tkn_number_12
                    ,iv_token_name1  => cv_tkn_from_value
                    ,iv_token_value1 => gv_from_value
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''             || CHR(10) ||   -- 空行の挿入
                   lv_param_set 
    );
    --更新日TOメッセージ出力
    lv_param_set := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_tkn_number_13
                    ,iv_token_name1  => cv_tkn_to_value
                    ,iv_token_value1 => gv_to_value
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_param_set || CHR(10) ||
                    ''
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
             ,iv_name         => cv_tkn_number_01            -- メッセージコード
      );
      lv_errbuf  := lv_errmsg||SQLERRM;
      RAISE global_api_expt;
    END IF;
    -- 更新日FROMと更新日TOの存在チェック 
    IF (gv_from_value IS NULL) THEN
      gv_from_value := TO_CHAR(ld_process_date,'YYYYMMDD');
      lb_check := TRUE;
    END IF;
    IF (gv_to_value IS NULL) THEN
      gv_to_value := TO_CHAR(ld_process_date,'YYYYMMDD');
      lb_check := TRUE;
    END IF;
    --パラメータデフォルトセット
    IF (lb_check = TRUE) THEN
      lv_param_set := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_tkn_number_14
                     );
      lv_errbuf  := lv_errmsg||SQLERRM;
      fnd_file.put_line(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_param_set  || CHR(10) ||
                    ''
      );
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
    ov_errmsg               OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- *** ローカル変数 ***
    lv_format                 VARCHAR2(20);  -- 日付のフォーマット
    lb_check_date_from_value  BOOLEAN;       -- 更新日FROMの書式が指定された日付の書式（YYYYMMDD）であるかを確認
    lb_check_date_to_value    BOOLEAN;       -- 更新日TOの書式が指定された日付の書式（YYYYMMDD）であるかを確認
    lv_value                  VARCHAR2(20);  -- 更新日FROMと更新日TOの値
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
        lv_value   := gv_from_value;
      END IF;
      IF (lb_check_date_to_value = cb_false) THEN
        lv_value   := gv_to_value;
      END IF;
      IF ((lb_check_date_from_value = cb_false) OR (lb_check_date_to_value = cb_false)) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name               -- アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_02          -- メッセージコード
                        ,iv_token_name1  => cv_tkn_value              -- トークンコード1
                        ,iv_token_value1 => lv_value                  -- トークン値1パラメータ
                        ,iv_token_name2  => cv_tkn_status             -- トークンコード2
                        ,iv_token_value2 => cv_false                  -- トークン値2リターンステータス
                        ,iv_token_name3  => cv_tkn_message            -- トークンコード3
                        ,iv_token_value3 => NULL                      -- トークン値3リターンメッセージ
        );
        lv_errbuf  := lv_errmsg||SQLERRM;
        RAISE global_api_expt;
      END IF;
    -- ===========================
    -- 日付大小関係チェック
    -- ===========================
      --入力されたパラメータの値の大小関係が正しいか確認
      IF (gv_from_value > gv_to_value) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name              -- アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_03         -- メッセージコード
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
    ov_file_dir             OUT NOCOPY VARCHAR2,        -- CSVファイル出力先
    ov_file_name            OUT NOCOPY VARCHAR2,        -- CSVファイル名
    ov_company_cd           OUT NOCOPY VARCHAR2,        -- 会社コード(固定値001)
    ov_errbuf               OUT NOCOPY VARCHAR2,        -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,        -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)  := 'get_profile_info';            -- プログラム名
--
    cv_tkn_csv_name     CONSTANT VARCHAR2(100)  := 'CSV_FILE_NAME';
      -- インターフェースファイル名トークン名
    cv_file_dir         CONSTANT VARCHAR2(100)  := 'XXCSO1_INFO_OUT_CSV_DIR';         -- CSVファイル出力先
    cv_file_name        CONSTANT VARCHAR2(100)  := 'XXCSO1_INFO_OUT_CSV_IB_WRK_LNS';  -- CSVファイル名
    cv_company_cd       CONSTANT VARCHAR2(100)  := 'XXCSO1_INFO_OUT_COMPANY_CD';      -- 会社コード(固定値001)

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
    lv_file_dir       VARCHAR2(2000);             -- CSVファイル出力先
    lv_file_name      VARCHAR2(2000);             -- CSVファイル名
    lv_company_cd     VARCHAR2(2000);             -- 会社コード(固定値001)
    lv_msg_set        VARCHAR2(1000);             -- メッセージ格納
    lv_value          VARCHAR2(1000);             -- プロファイルオプション値
    lv_check_flg      VARCHAR2(1000);             -- プロファイル値取得失敗の場合('1')
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
    -- CSVファイル出力先の値取得
    fnd_profile.get(
                  cv_file_dir
                 ,lv_file_dir
    );
    -- CSVファイル名の値取得
    fnd_profile.get(
                  cv_file_name
                 ,lv_file_name
    );
    -- 会社コードの値取得
    fnd_profile.get(
                  cv_company_cd
                 ,lv_company_cd
    );
    -- *** DEBUG_LOG ***
    -- 取得したプロファイル値をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg5 || CHR(10) ||
                 cv_debug_msg6 || lv_file_dir    || CHR(10) ||
                 cv_debug_msg7 || lv_file_name   || CHR(10) ||
                 cv_debug_msg8 || lv_company_cd  || CHR(10) ||
                 ''
    );
    --インターフェースファイル名メッセージ出力
    lv_msg_set := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_tkn_number_11
                    ,iv_token_name1  => cv_tkn_csv_name
                    ,iv_token_value1 => lv_file_name
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg_set ||CHR(10) ||
                 ''                           -- 空行の挿入
    );
    -- 戻り値が「NULL」であった場合,例外処理を行う
    -- CSVファイル出力先
    IF (lv_file_dir IS NULL) THEN
      lv_check_flg := '1';
      lv_value     := cv_file_dir;
    END IF;
    -- CSVファイル名
    IF (lv_file_name IS NULL) THEN
      lv_check_flg := '1';
      lv_value     := cv_file_name;
    END IF;
    -- 会社コード(固定値001)
    IF (lv_company_cd IS NULL) THEN
      lv_check_flg := '1';
      lv_value := cv_company_cd;
    END IF;
    IF (lv_check_flg = '1') THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name              -- アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_04         -- メッセージコード
                        ,iv_token_name1  => cv_tkn_prof_name         -- トークンコード1
                        ,iv_token_value1 => lv_value                 -- トークン値1引揚拠点コード
      );
      lv_errbuf  := lv_errmsg||SQLERRM;
      RAISE global_api_expt;    
    END IF;
    -- 取得した値をOUTパラメータに設定
    ov_file_dir   := lv_file_dir;       -- CSVファイル出力先
    ov_file_name  := lv_file_name;      -- CSVファイル名
    ov_company_cd := lv_company_cd;     -- 会社コード(固定値001)
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
    iv_file_dir             IN  VARCHAR2,               -- CSVファイル出力先
    iv_file_name            IN  VARCHAR2,               -- CSVファイル名
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
    lv_file_dir       VARCHAR2(1000);      -- CSVファイル出力先
    lv_file_name      VARCHAR2(1000);      -- CSVファイル名
    lv_exists         BOOLEAN;             -- 存在チェック結果
    lv_file_length    VARCHAR2(1000);      -- ファイルサイズ
    lv_blocksize      VARCHAR2(1000);      -- ブロックサイズ
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
    lv_file_dir   := iv_file_dir;       -- CSVファイル出力先
    lv_file_name  := iv_file_name;      -- CSVファイル名
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
      -- CSVファイル残存エラーメッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name              -- アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_05         -- メッセージコード
                        ,iv_token_name1  => cv_tkn_csv_location      -- トークンコード1
                        ,iv_token_value1 => lv_file_dir              -- トークン値1CSVファイル出力先
                        ,iv_token_name2  => cv_tkn_csv_file_name     -- トークンコード1
                        ,iv_token_value2 => lv_file_name             -- トークン値1CSVファイル名
      );
      lv_errbuf := lv_errmsg||SQLERRM;
      RAISE file_err_expt;
    ELSIF (lv_exists = cb_false) THEN
      -- ========================
      -- CSVファイルオープン 
      -- ========================
      BEGIN
  --
        -- ファイルIDを取得
        gf_file_hand := UTL_FILE.FOPEN(
                             location   => lv_file_dir
                            ,filename   => lv_file_name
                            ,open_mode  => cv_open_writer
          );
        -- *** DEBUG_LOG ***
        -- ファイルオープンしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg10    || CHR(10)   ||
                     cv_debug_msg_fnm  || lv_file_name || CHR(10) ||
                     ''
        );
        EXCEPTION
          WHEN UTL_FILE.INVALID_PATH       OR       -- ファイルパス不正エラー
               UTL_FILE.INVALID_MODE       OR       -- open_modeパラメータ不正エラー
               UTL_FILE.INVALID_OPERATION  OR       -- オープン不可能エラー
               UTL_FILE.INVALID_MAXLINESIZE  THEN   -- MAX_LINESIZE値無効エラー
            -- CSVファイルオープンエラーメッセージ取得
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name              -- アプリケーション短縮名
                          ,iv_name         => cv_tkn_number_06         -- メッセージコード
                          ,iv_token_name1  => cv_tkn_csv_location      -- トークンコード1
                          ,iv_token_value1 => lv_file_dir              -- トークン値1CSVファイル出力先
                          ,iv_token_name2  => cv_tkn_csv_file_name     -- トークンコード1
                          ,iv_token_value2 => lv_file_name             -- トークン値1CSVファイル名
            );
            lv_errbuf := lv_errmsg||SQLERRM;
            RAISE file_err_expt;
      END;
    END IF;
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
      -- 取得した値をOUTパラメータに設定
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
--
  /**********************************************************************************
   * Procedure Name   : get_csv_data
   * Description      : CSVファイルに出力する関連情報取得 (A-7)
   ***********************************************************************************/
  PROCEDURE get_csv_data(
    io_get_rec      IN OUT NOCOPY g_value_rtype,       -- 情報データ
    ov_errbuf       OUT NOCOPY VARCHAR2,               -- エラー・メッセージ           --# 固定 #
    ov_retcode      OUT NOCOPY VARCHAR2,               -- リターン・コード             --# 固定 #
    ov_errmsg       OUT NOCOPY VARCHAR2                -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100)  := 'get_csv_data';       -- プログラム名
    cv_sep_com                 CONSTANT VARCHAR2(3)    := ',';
    cv_sep_wquot               CONSTANT VARCHAR2(3)    := '"';
    --
    cv_account_master          CONSTANT VARCHAR2(100)  := '顧客マスタ';
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
    lv_sale_base_code_s          VARCHAR2(100);         -- 拠点(部門)コード(設置用)
    lv_sale_base_code_w          VARCHAR2(100);         -- 拠点(部門)コード(引揚用)
    ln_debug  number;
    -- *** ローカル・レコード ***
    l_get_rec       g_value_rtype;            -- 什器移動明細データ
    -- *** ローカル例外 ***
    select_error_expt     EXCEPTION;          -- データ出力処理例外(エラー)
    select_warning_expt   EXCEPTION;          -- データ出力処理例外(警告)
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
    l_get_rec := io_get_rec;
    -- 物件コード1がNULLでない場合、
    /* 2009.11.25 D.Abe E_本稼動_00045 対応 START */
    ---- 什器移動区分=(1[新台設置], 2[旧台設置], 3[新台代替], 4[旧台代替], 6[店内移動], 8[是正])の場合
    -- 什器移動区分=(1[新台設置], 2[旧台設置], 3[新台代替], 4[旧台代替], 6[店内移動], 8[是正], 
    --               15[転送], 16[転売], 18[廃棄引取])の場合
    /* 2009.11.25 D.Abe E_本稼動_00045 対応 END */
    IF ((l_get_rec.install_code1 IS NOT NULL)
          AND (l_get_rec.job_kbn IN (cn_job_kbn_1,cn_job_kbn_2,cn_job_kbn_3,cn_job_kbn_4,
                                     /* 2009.11.25 D.Abe E_本稼動_00045 対応 START */
                                     cn_job_kbn_6,cn_job_kbn_8,
                                     cn_job_kbn_15,cn_job_kbn_16,cn_job_kbn_dspsl_lv)) ) THEN
                                     --cn_job_kbn_6,cn_job_kbn_8)) ) THEN
                                     /* 2009.11.25 D.Abe E_本稼動_00045 対応 END */
      BEGIN
        SELECT  xca.sale_base_code         -- 拠点(部門)コード(設置用)
        INTO    lv_sale_base_code_s
        FROM    csi_item_instances cii     -- インストールベースマスタ
               ,xxcmm_cust_accounts xca    -- 顧客アドオンマスタ
        WHERE cii.external_reference = l_get_rec.install_code1
        AND cii.owner_party_account_id = xca.customer_id;
        
      EXCEPTION
        -- コードが存在しない場合
        WHEN NO_DATA_FOUND THEN
          -- データ抽出エラーメッセージ
          lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_app_name               -- アプリケーション短縮名
                              ,iv_name         => cv_tkn_number_08          -- メッセージコード
                              ,iv_token_name1  => cv_tkn_table              -- トークンコード1
                              ,iv_token_value1 => cv_account_master         -- トークン値1
                              ,iv_token_name2  => cv_tkn_slip_no            -- トークンコード2
                              ,iv_token_value2 => l_get_rec.slip_no         -- トークン値2伝票番号
                              ,iv_token_name3  => cv_tkn_line_no            -- トークンコード3
                              ,iv_token_value3 => l_get_rec.line_number     -- トークン値3行番号
                              ,iv_token_name4  => cv_tkn_year_month_day     -- トークンコード4
                              ,iv_token_value4 => l_get_rec.year_month_day  -- トークン値4年月日
                              ,iv_token_name5  => cv_tkn_object_cd          -- トークンコード5
                              ,iv_token_value5 => l_get_rec.install_code1   -- トークン値5物件コード
                              ,iv_token_name6  => cv_tkn_work_kbn           -- トークンコード6
                              ,iv_token_value6 => l_get_rec.job_kbn         -- トークン値6作業区分
              );
          lv_errbuf  := lv_errmsg;
          RAISE select_warning_expt;
        -- 抽出に失敗した場合
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_app_name               -- アプリケーション短縮名
                              ,iv_name         => cv_tkn_number_07          -- メッセージコード
                              ,iv_token_name1  => cv_tkn_proc_name          -- トークンコード1
                              ,iv_token_value1 => cv_account_master         -- トークン値1
                              ,iv_token_name2  => cv_tkn_err_message        -- トークンコード2
                              ,iv_token_value2 => SQLERRM                   -- トークン値2
              );
          lv_errbuf  := lv_errmsg;
        RAISE select_error_expt;
      END;
    END IF;
    /* 2009.06.09 K.Hosoi T1_1240 対応 START */
    -- 物件コード2がNULLでない場合
--    -- 什器移動区分=(3[新台代替], 4[旧台代替],5[引揚], 15[転送], 16[転売], 17[廃棄引取])の場合
    /* 2009.11.25 D.Abe E_本稼動_00045 対応 START */
    ---- 什器移動区分=(3[新台代替], 4[旧台代替],5[引揚], 15[転送], 16[転売], 18[廃棄引取])の場合
    -- 什器移動区分=(3[新台代替], 4[旧台代替],5[引揚])の場合
    /* 2009.11.25 D.Abe E_本稼動_00045 対応 END */
    IF ((l_get_rec.install_code2 IS NOT NULL)
/* 2009.11.25 D.Abe E_本稼動_00045 対応 START */
          AND (l_get_rec.job_kbn IN (cn_job_kbn_3,cn_job_kbn_4,cn_job_kbn_5)) ) THEN
--          AND (l_get_rec.job_kbn IN (cn_job_kbn_3,cn_job_kbn_4,cn_job_kbn_5,
----                                     cn_job_kbn_15,cn_job_kbn_16,cn_job_kbn_17)) ) THEN
--                                     cn_job_kbn_15,cn_job_kbn_16,cn_job_kbn_dspsl_lv)) ) THEN
/* 2009.11.25 D.Abe E_本稼動_00045 対応 END */
    /* 2009.06.09 K.Hosoi T1_1240 対応 END */
      BEGIN
        SELECT xca.sale_base_code         -- 拠点(部門)コード(引揚用)
        INTO   lv_sale_base_code_w
        FROM   xxcso_install_base_v xibv  -- 物件マスタビュー
              ,hz_cust_accounts hca       -- 顧客マスタ
              ,xxcmm_cust_accounts xca    -- 顧客アドオンマスタ
        WHERE  xibv.install_code = l_get_rec.install_code2
          AND  xibv.ven_kyaku_last = hca.account_number
          AND  hca.cust_account_id = xca.customer_id
          /* 2009.10.01 D.Abe 0001452 対応 START */
          --AND  hca.status = cv_active_status
          /* 2009.10.01 D.Abe 0001452 対応 END */
          ;
      EXCEPTION
        -- コードが存在しない場合
        WHEN NO_DATA_FOUND THEN
          -- データ抽出エラーメッセージ
          lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_app_name               -- アプリケーション短縮名
                              ,iv_name         => cv_tkn_number_08          -- メッセージコード
                              ,iv_token_name1  => cv_tkn_table              -- トークンコード1
                              ,iv_token_value1 => cv_account_master         -- トークン値1
                              ,iv_token_name2  => cv_tkn_slip_no            -- トークンコード2
                              ,iv_token_value2 => l_get_rec.slip_no         -- トークン値2伝票番号
                              ,iv_token_name3  => cv_tkn_line_no            -- トークンコード3
                              ,iv_token_value3 => l_get_rec.line_number     -- トークン値3行番号
                              ,iv_token_name4  => cv_tkn_year_month_day     -- トークンコード4
                              ,iv_token_value4 => l_get_rec.year_month_day  -- トークン値4年月日
                              ,iv_token_name5  => cv_tkn_object_cd          -- トークンコード5
                              ,iv_token_value5 => l_get_rec.install_code2   -- トークン値5物件コード
                              ,iv_token_name6  => cv_tkn_work_kbn           -- トークンコード6
                              ,iv_token_value6 => l_get_rec.job_kbn         -- トークン値6作業区分
              );
          lv_errbuf  := lv_errmsg;
          RAISE select_warning_expt;
        -- 抽出に失敗した場合
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_app_name               -- アプリケーション短縮名
                              ,iv_name         => cv_tkn_number_07          -- メッセージコード
                              ,iv_token_name1  => cv_tkn_proc_name          -- トークンコード1
                              ,iv_token_value1 => cv_account_master         -- トークン値1
                              ,iv_token_name2  => cv_tkn_err_message        -- トークンコード2
                              ,iv_token_value2 => SQLERRM                   -- トークン値2
              );
          lv_errbuf  := lv_errmsg;
        RAISE select_error_expt;
      END;
    END IF;
      -- 取得した値をOUTパラメータに設定
    l_get_rec.sale_base_code_s  := lv_sale_base_code_s;      -- 拠点(部門)コード(設置用)
    l_get_rec.sale_base_code_w  := lv_sale_base_code_w;      -- 拠点(部門)コード(引揚用)
--
    io_get_rec := l_get_rec;
--
  EXCEPTION
    -- *** ファイル処理例外ハンドラ ***
    WHEN select_warning_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_csv_data;
--
--
  /**********************************************************************************
   * Procedure Name   : create_csv_rec
   * Description      : CSVファイル出力 (A-8)
   ***********************************************************************************/
  PROCEDURE create_csv_rec(
    i_get_rec   IN g_value_rtype,                  -- 什器移動明細データ
    ov_errbuf   OUT NOCOPY VARCHAR2,               -- エラー・メッセージ           --# 固定 #
    ov_retcode  OUT NOCOPY VARCHAR2,               -- リターン・コード             --# 固定 #
    ov_errmsg   OUT NOCOPY VARCHAR2                -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'create_csv_rec';       -- プログラム名
    cv_sep_com              CONSTANT VARCHAR2(3)    := ',';
    cv_sep_wquot            CONSTANT VARCHAR2(3)    := '"';
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
    lv_data          VARCHAR2(5000);                -- 編集データ
    -- *** ローカル・レコード ***
    l_get_rec       g_value_rtype;                  -- 什器移動明細データ
    -- *** ローカル例外 ***
    file_put_line_expt             EXCEPTION;       -- データ出力処理例外
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
    l_get_rec  := i_get_rec;               -- 什器移動明細データを格納するレコード
--
    BEGIN
--
      --データ作成
      lv_data := cv_sep_wquot || l_get_rec.company_cd || cv_sep_wquot                    -- 会社コード
        || cv_sep_com || cv_sep_wquot || TO_CHAR(l_get_rec.slip_no) || cv_sep_wquot      -- 伝票番号
        || cv_sep_com || TO_CHAR(l_get_rec.line_number)                                  -- 行番号
        || cv_sep_com || TO_CHAR(l_get_rec.year_month_day)                               -- 年月日
        || cv_sep_com || cv_sep_wquot || l_get_rec.install_code1 || cv_sep_wquot         -- 物件コード1
        || cv_sep_com || cv_sep_wquot || l_get_rec.install_code2 || cv_sep_wquot         -- 物件コード2
        || cv_sep_com || cv_sep_wquot || l_get_rec.sale_base_code_s || cv_sep_wquot      -- 外部参照
        || cv_sep_com || cv_sep_wquot || l_get_rec.sale_base_code_w || cv_sep_wquot      -- 外部参照
        || cv_sep_com || TO_CHAR(l_get_rec.job_kbn)                                      -- 什器移動区分
        || cv_sep_com || cv_sep_wquot ||TO_CHAR(l_get_rec.delete_flag) || cv_sep_wquot   -- 削除フラグ
        || cv_sep_com || l_get_rec.sysdate_now;                                          -- 連携時間
      -- データ出力
      UTL_FILE.PUT_LINE(
         file   => gf_file_hand
        ,buffer => lv_data
      );
    EXCEPTION
      WHEN UTL_FILE.INVALID_FILEHANDLE OR     -- ファイル・ハンドル無効エラー
           UTL_FILE.INVALID_OPERATION  OR     -- オープン不可能エラー
           UTL_FILE.WRITE_ERROR  THEN         -- 書込み操作中オペレーティングエラー
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name               -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_09          -- メッセージコード
                     ,iv_token_name1  => cv_tkn_slip_no            -- トークンコード1
                     ,iv_token_value1 => l_get_rec.slip_no         -- トークン値1伝票番号
                     ,iv_token_name2  => cv_tkn_line_no            -- トークンコード2
                     ,iv_token_value2 => l_get_rec.line_number     -- トークン値2行番号
                     ,iv_token_name3  => cv_tkn_year_month_day     -- トークンコード3
                     ,iv_token_value3 => l_get_rec.year_month_day  -- トークン値3年月日
                     ,iv_token_name4  => cv_tkn_object_cd1         -- トークンコード4
                     ,iv_token_value4 => l_get_rec.install_code1   -- トークン値4物件コード1
                     ,iv_token_name5  => cv_tkn_object_cd2         -- トークンコード5
                     ,iv_token_value5 => l_get_rec.install_code2   -- トークン値5物件コード2
                     ,iv_token_name6  => cv_tkn_err_msg            -- トークンコード6
                     ,iv_token_value6 => SQLERRM                   -- トークン値6
                    );
        lv_errbuf := lv_errmsg||SQLERRM;
      RAISE file_put_line_expt;
    END;
--
  EXCEPTION
    -- *** ファイル処理例外ハンドラ ***
    WHEN file_put_line_expt THEN
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
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END create_csv_rec;
--
  /**********************************************************************************
   * Procedure Name   : close_csv_file
   * Description      : CSVファイルクローズ処理 (A-9)
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
        ,buff   => cv_debug_msg11   || CHR(10)   ||
                   cv_debug_msg_fnm || iv_file_name || CHR(10) ||
                   ''
      );
      EXCEPTION
        WHEN UTL_FILE.WRITE_ERROR          OR     -- オペレーティングシステムエラー
             UTL_FILE.INVALID_FILEHANDLE   THEN   -- ファイル・ハンドル無効エラー
          -- エラーメッセージ取得
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name                  --アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_10             --メッセージコード
                        ,iv_token_name1  => cv_tkn_csv_location          --トークンコード1
                        ,iv_token_value1 => iv_file_dir                  --トークン値1
                        ,iv_token_name2  => cv_tkn_csv_file_name         --トークンコード1
                        ,iv_token_value2 => iv_file_name                 --トークン値1
                       );
          lv_errbuf := lv_errmsg||SQLERRM;
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
    cv_work_data_tkn        CONSTANT VARCHAR2(100)   := '作業データテーブル';
    -- *** ローカル変数 ***
    lv_sub_retcode         VARCHAR2(1);                -- サーブメイン用リターン・コード
    lv_sub_msg             VARCHAR2(5000);             -- 警告用メッセージ
    lv_sub_buf             VARCHAR2(5000);             -- 警告用エラー・メッセージ
    lv_sysdate             VARCHAR2(100);              -- システム日付
    lv_file_dir            VARCHAR2(2000);             -- CSVファイル出力先
    lv_file_name           VARCHAR2(2000);             -- CSVファイル名
    lv_company_cd          VARCHAR2(2000);             -- 会社コード(固定値001)
    lv_wd_base_cd          VARCHAR2(2000);             -- 引揚拠点コード
    ld_from_value          DATE;                       -- 更新日FROM(DATE)
    ld_to_value            DATE;                       -- 更新日TO(DATE)
    -- ファイルオープン確認戻り値格納
    lb_fopn_retcd   BOOLEAN;
    -- メッセージ出力用
    lv_msg          VARCHAR2(2000);
    -- *** ローカル・カーソル ***
    CURSOR xiwd_data_cur
    IS
      SELECT  xiwd.slip_no slip_no                          -- 伝票番号
             ,xiwd.line_number line_number                  -- 行番号
             ,(CASE                                         -- 年月日
                WHEN (xiwd.job_kbn IN(cn_job_kbn_1,cn_job_kbn_2,cn_job_kbn_3,cn_job_kbn_4,cn_job_kbn_5,
                                      cn_job_kbn_6,cn_job_kbn_8)) THEN
                xiwd.actual_work_date 
                WHEN (xiwd.job_kbn IN(cn_job_kbn_15,cn_job_kbn_16)) THEN
                xiwd.withdrawal_date 
    /* 2009.06.09 K.Hosoi T1_1240 対応 START */
--                WHEN (xiwd.job_kbn IN(cn_job_kbn_17)) THEN
                WHEN (xiwd.job_kbn IN(cn_job_kbn_dspsl_lv)) THEN
    /* 2009.06.09 K.Hosoi T1_1240 対応 END */
                xiwd.disposal_approval_date
              END) year_month_day
             ,xiwd.install_code1 install_code1              -- 物件コード1
             ,xiwd.install_code2 install_code2              -- 物件コード2
             ,xiwd.job_kbn job_kbn                          -- 什器移動区分
             ,xiwd.delete_flag delete_flag                  -- 削除フラグ
      FROM xxcso_in_work_data xiwd                          -- 作業データテーブル
      WHERE xiwd.job_kbn IN (cn_job_kbn_1,cn_job_kbn_2,cn_job_kbn_3,cn_job_kbn_4,cn_job_kbn_5,
    /* 2009.06.09 K.Hosoi T1_1240 対応 START */
--                             cn_job_kbn_6,cn_job_kbn_8,cn_job_kbn_15,cn_job_kbn_16,cn_job_kbn_17)
                             cn_job_kbn_6,cn_job_kbn_8,cn_job_kbn_15,cn_job_kbn_16,cn_job_kbn_dspsl_lv)
    /* 2009.06.09 K.Hosoi T1_1240 対応 END */
        AND TRUNC(xiwd.last_update_date) BETWEEN ld_from_value AND ld_to_value;
    -- *** ローカル・レコード ***
    l_xiwd_data_rec        xiwd_data_cur%ROWTYPE;
    l_get_rec              g_value_rtype;                    -- 什器移動明細データ
    -- *** ローカル・例外 ***
    select_error_expt EXCEPTION;
    lv_process_expt   EXCEPTION;
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
    /* 2009.10.01 D.Abe 0001452 対応 START */
    ---- ローカル変数の初期化
    --ld_from_value := TO_DATE(gv_from_value,'YYYYMMDD');
    --ld_to_value   := TO_DATE(gv_to_value,'YYYYMMDD');
    /* 2009.10.01 D.Abe 0001452 対応 END */
--
    -- ================================
    -- A-1.初期処理 
    -- ================================
    init(
      ov_sysdate          => lv_sysdate,       -- システム日付
      ov_errbuf           => lv_errbuf,        -- エラー・メッセージ            --# 固定 #
      ov_retcode          => lv_retcode,       -- リターン・コード              --# 固定 #
      ov_errmsg           => lv_errmsg         -- ユーザー・エラー・メッセージ  --# 固定 #
    ); 
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
--
    -- ================================
    -- A-2.パラメータデフォルトセット 
    -- ================================
    set_parm_def(
      ov_errbuf           => lv_errbuf,           -- エラー・メッセージ            --# 固定 #
      ov_retcode          => lv_retcode,          -- リターン・コード              --# 固定 #
      ov_errmsg           => lv_errmsg            -- ユーザー・エラー・メッセージ    --# 固定 #
    );
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
    /* 2009.10.01 D.Abe 0001452 対応 START */
    -- 抽出条件From-Toを設定
    ld_from_value := TO_DATE(gv_from_value,'YYYYMMDD');
    ld_to_value   := TO_DATE(gv_to_value,'YYYYMMDD');
    /* 2009.10.01 D.Abe 0001452 対応 END */
--
    -- =================================================
    -- A-4.プロファイル値を取得 
    -- =================================================
    get_profile_info(
       ov_file_dir    => lv_file_dir    -- CSVファイル出力先
      ,ov_file_name   => lv_file_name   -- CSVファイル名
      ,ov_company_cd  => lv_company_cd  -- 会社コード(固定値001)
      ,ov_errbuf      => lv_errbuf      -- エラー・メッセージ            --# 固定 #
      ,ov_retcode     => lv_retcode     -- リターン・コード              --# 固定 #
      ,ov_errmsg      => lv_errmsg      -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =================================================
    -- A-5.CSVファイルオープン 
    -- =================================================
--
    open_csv_file(
       iv_file_dir  => lv_file_dir   -- CSVファイル出力先
      ,iv_file_name => lv_file_name  -- CSVファイル名
      ,ov_errbuf    => lv_errbuf     -- エラー・メッセージ            --# 固定 #
      ,ov_retcode   => lv_retcode    -- リターン・コード              --# 固定 #
      ,ov_errmsg    => lv_errmsg     -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =================================================
    -- A-6.什器移動明細データ抽出処理
    -- =================================================
--
    -- カーソルオープン
    OPEN xiwd_data_cur;
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
        FETCH xiwd_data_cur INTO l_xiwd_data_rec;
--
      EXCEPTION
        WHEN OTHERS THEN
          -- データ抽出エラーメッセージ
          lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_app_name               -- アプリケーション短縮名
                              ,iv_name         => cv_tkn_number_07          -- メッセージコード
                              ,iv_token_name1  => cv_tkn_proc_name          -- トークンコード1
                              ,iv_token_value1 => cv_work_data_tkn          -- トークン値1
                              ,iv_token_name2  => cv_tkn_err_message        -- トークンコード2
                              ,iv_token_value2 => SQLERRM                   -- トークン値2
              );
          lv_errbuf  := lv_errmsg||SQLERRM;
        RAISE global_process_expt;
      END;
--
      BEGIN
      -- データ初期化
      lv_sub_msg := NULL;
      lv_sub_buf := NULL;
      -- レコード変数初期化
      l_get_rec         := NULL;
      -- 処理対象件数格納
      gn_target_cnt := xiwd_data_cur%ROWCOUNT;
      -- 対象件数がO件の場合
      EXIT WHEN xiwd_data_cur%NOTFOUND
      OR  xiwd_data_cur%ROWCOUNT = 0;
      -- 取得データを格納
      l_get_rec.company_cd        := lv_company_cd;                     -- 会社コード
      l_get_rec.slip_no           := l_xiwd_data_rec.slip_no;           -- 伝票番号
      l_get_rec.line_number       := l_xiwd_data_rec.line_number;       -- 行番号
      l_get_rec.year_month_day    := l_xiwd_data_rec.year_month_day;    -- 年月日
      l_get_rec.install_code1     := l_xiwd_data_rec.install_code1;     -- 物件コード1
      l_get_rec.install_code2     := l_xiwd_data_rec.install_code2;     -- 物件コード2
      l_get_rec.job_kbn           := l_xiwd_data_rec.job_kbn;           -- 什器移動区分
      l_get_rec.delete_flag       := l_xiwd_data_rec.delete_flag;       -- 削除フラグ
      l_get_rec.sysdate_now       := lv_sysdate;                        -- 連携日時
--
      -- ================================================================
      -- A-7 CSVファイルに出力する関連情報取得
      -- ================================================================
--
      get_csv_data(
         io_get_rec       => l_get_rec        -- 什器移動明細データ
        ,ov_errbuf        => lv_sub_buf       -- エラー・メッセージ            --# 固定 #
        ,ov_retcode       => lv_sub_retcode   -- リターン・コード              --# 固定 #
        ,ov_errmsg        => lv_sub_msg       -- ユーザー・エラー・メッセージ  --# 固定 #
      );
      IF (lv_sub_retcode = cv_status_warn) THEN
        RAISE select_error_expt;
      ELSIF (lv_sub_retcode = cv_status_error) THEN
        lv_errmsg := lv_sub_msg;
        lv_errbuf := lv_sub_buf;
        RAISE lv_process_expt;
      END IF;
--
      -- ========================================
      -- A-8. 什器移動明細情報データCSVファイル出力 
      -- ========================================
      create_csv_rec(
        i_get_rec        =>  l_get_rec         -- 什器移動明細データ
       ,ov_errbuf        =>  lv_errbuf         -- エラー・メッセージ
       ,ov_retcode       =>  lv_retcode        -- リターン・コード
       ,ov_errmsg        =>  lv_errmsg         -- ユーザー・エラー・メッセージ
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE lv_process_expt;
      END IF;
      --成功件数カウント
      gn_normal_cnt := gn_normal_cnt + 1;
--
      EXCEPTION
        -- *** データ抽出時のエラー例外ハンドラ ***
        WHEN lv_process_expt THEN
          -- --エラー件数カウント
          gn_error_cnt  := gn_error_cnt + 1;
          --
          RAISE global_process_expt;
        -- *** データ抽出時の警告例外ハンドラ ***
        WHEN select_error_expt THEN
          --エラー件数カウント
          gn_error_cnt  := gn_error_cnt + 1;
          --
          lv_sub_retcode := cv_status_warn;
          ov_retcode     := lv_sub_retcode;
          --警告出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_sub_msg                  --ユーザー・エラーメッセージ
          );
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff   => cv_pkg_name||cv_msg_cont||
                       cv_prg_name||cv_msg_part||
                       lv_sub_buf 
          );
      END;
--
    END LOOP get_data_loop;
--
    -- カーソルクローズ
    CLOSE xiwd_data_cur;
    -- *** DEBUG_LOG ***
    -- カーソルクローズしたことをログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_ccls1 || CHR(10) ||
                 ''
    );
--
    -- ========================================
    -- A-9.CSVファイルクローズ  
    -- ========================================
--
    close_csv_file(
       iv_file_dir   => lv_file_dir   -- CSVファイル出力先
      ,iv_file_name  => lv_file_name  -- CSVファイル名
      ,ov_errbuf     => lv_errbuf     -- エラー・メッセージ            --# 固定 #
      ,ov_retcode    => lv_retcode    -- リターン・コード              --# 固定 #
      ,ov_errmsg     => lv_errmsg     -- ユーザー・エラー・メッセージ  --# 固定 #
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
      IF (xiwd_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE xiwd_data_cur;
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
      IF (xiwd_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE xiwd_data_cur;
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
      IF (xiwd_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE xiwd_data_cur;
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
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了
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
    -- INパラメータを代入
    gv_from_value    := iv_from_value;    -- 更新日FROM
    gv_to_value      := iv_to_value;      -- 更新日TO
    --
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       ov_errbuf   => lv_errbuf          -- エラー・メッセージ            --# 固定 #
      ,ov_retcode  => lv_retcode         -- リターン・コード              --# 固定 #
      ,ov_errmsg   => lv_errmsg          -- ユーザー・エラー・メッセージ  --# 固定 #
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
    -- A-10.終了処理 
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
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
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
      -- *** DEBUG_LOG ***
      -- ロールバックしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg12 || CHR(10) ||
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
      -- *** DEBUG_LOG ***
      -- ロールバックしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg12 || CHR(10) ||
                   ''
      );
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ロールバックしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg12 || CHR(10) ||
                   ''
      );
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCSO016A06C;
/
