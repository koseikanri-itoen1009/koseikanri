CREATE OR REPLACE PACKAGE BODY      XXCOK024A37C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A37C(body)
 * Description      : 控除データIF出力（情報系）
 * MD.050           : 控除データIF出力（情報系） MD050_COK_024_A37
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  proc_init            初期処理(A-1)
 *
 *  upd_control_p        販売控除管理情報更新(A-5)
 *  submain              メイン処理プロシージャ
 *                          ・proc_init
 *                       販売控除情報の取得(A-2)
 *                       売上区分、納品形態区分の取得(A-3)
 *                       販売控除情報（情報系）出力処理(A-4)
 *                       メイン処理プロシージャ
 *                          ・upd_control_p
 *                       終了処理(A-6)
 *  main                 コンカレント実行ファイル登録プロシージャ
 *                          ・submain
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2021/02/15    1.0   K.Yoshikawa      main新規作成
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal               CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal;  -- 正常:0
  cv_status_warn                 CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;    -- 警告:1
  cv_status_error                CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;   -- 異常:2
  --WHOカラム
  cn_created_by                  CONSTANT NUMBER      := fnd_global.user_id;            -- CREATED_BY
  cd_creation_date               CONSTANT DATE        := SYSDATE;                       -- CREATION_DATE
  cn_last_updated_by             CONSTANT NUMBER      := fnd_global.user_id;            -- LAST_UPDATED_BY
  cd_last_update_date            CONSTANT DATE        := SYSDATE;                       -- LAST_UPDATE_DATE
  cn_last_update_login           CONSTANT NUMBER      := fnd_global.login_id;           -- LAST_UPDATE_LOGIN
  cn_request_id                  CONSTANT NUMBER      := fnd_global.conc_request_id;    -- REQUEST_ID
  cn_program_application_id      CONSTANT NUMBER      := fnd_global.prog_appl_id;       -- PROGRAM_APPLICATION_ID
  cn_program_id                  CONSTANT NUMBER      := fnd_global.conc_program_id;    -- PROGRAM_ID
  cd_program_update_date         CONSTANT DATE        := SYSDATE;                       -- PROGRAM_UPDATE_DATE
  cv_msg_part                    CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont                    CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg                     VARCHAR2(2000);
  gv_sep_msg                     VARCHAR2(2000);
  gv_exec_user                   VARCHAR2(100);
  gv_conc_name                   VARCHAR2(30);
  gv_conc_status                 VARCHAR2(30);
  gn_target_cnt                  NUMBER;                    -- 対象件数
  gn_normal_cnt                  NUMBER;                    -- 正常件数
  gn_error_cnt                   NUMBER;                    -- エラー件数
  gn_warn_cnt                    NUMBER;                    -- スキップ件数
--
--################################  固定部 END   ##################################
--
--##########################  固定共通例外宣言部 START  ###########################
--
  --*** 処理部共通例外 ***
  global_process_expt            EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt                EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt         EXCEPTION;
  global_check_lock_expt         EXCEPTION;                 -- ロック取得エラー
  --
  --*** ログのみ出力例外 ***
  global_api_expt_log            EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_check_lock_expt, -54);
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000);
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                    CONSTANT VARCHAR2(30)  := 'XXCOK024A37C';       -- パッケージ名
--
  cv_appl_name_xxcok             CONSTANT VARCHAR2(5)   := 'XXCOK';              -- アプリケーション短縮名
  -- メッセージ
  cv_msg_xxcok_00001             CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00001';   -- 対象データなし
  cv_msg_xxcok_00003             CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00003';   -- プロファイル取得エラー
--
  cv_msg_xxcok_00006             CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00006';   -- CSVファイル名ノート
--
  cv_msg_xxcok_00009             CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00009';   -- CSVファイル存在エラー
  cv_msg_xxcok_10787             CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10787';   -- ファイルオープンエラー
  cv_msg_xxcok_10788             CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10788';   -- ファイル書き込みエラー
  cv_msg_xxcok_10789             CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10789';   -- ファイルクローズエラー
  cv_msg_xxcok_10592             CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10592';   -- 前回処理ID取得エラー
  cv_msg_proc_date_err           CONSTANT  VARCHAR2(100):= 'APP-XXCOK1-00028';   -- 業務日付取得エラーメッセージ
  -- トークン
  cv_tkn_profile                 CONSTANT VARCHAR2(10)  := 'PROFILE';            -- トークン：プロファイル名
  cv_tkn_sqlerrm                 CONSTANT VARCHAR2(10)  := 'SQLERRM';            -- トークン：SQLエラー
  cv_tkn_file_name               CONSTANT VARCHAR2(10)  := 'FILE_NAME';          -- トークン：SQLエラー
--                                                                               -- YYYYMMDD
  cv_date_fmt_ymd                CONSTANT VARCHAR2(10)  := 'RRRRMMDD';           -- YYYYMMDD
  cv_date_fmt_dt_ymdhms          CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_date_fmt_dt_ymdhms;
                                                                                 -- YYYYMMDDHH24MISS
--
  cv_csv_fl_name                 CONSTANT VARCHAR2(33)  := 'XXCOK1_DEDUCTION_DATA_FILE_NAME';
                                                                                 -- XXCOK:控除データファイル名
  cv_csv_fl_dir                  CONSTANT VARCHAR2(33)  := 'XXCOK1_DEDUCTION_DATA_DIRE_PATH';
                                                                                 -- XXCOK:控除データディレクトリパス
  cv_item_code_dummy_f           CONSTANT VARCHAR2(33)  := 'XXCOK1_ITEM_CODE_DUMMY_F';  -- XXCOK:品目コード_ダミー値（定額控除）
  cv_item_code_dummy_u           CONSTANT VARCHAR2(33)  := 'XXCOK1_ITEM_CODE_DUMMY_U';  -- XXCOK:品目コード_ダミー値（アップロード）
  cv_item_code_dummy_o           CONSTANT VARCHAR2(33)  := 'XXCOK1_ITEM_CODE_DUMMY_O';  -- XXCOK:品目コード_ダミー値（繰越調整）
  cv_dqu                         CONSTANT VARCHAR2(1)   := '"';
  cv_sep                         CONSTANT VARCHAR2(1)   := ',';
--
  cv_company_code                CONSTANT VARCHAR2(3)   := '001';                -- 会社コード
  cv_csv_mode                    CONSTANT VARCHAR2(1)   := 'w';                  -- csvファイルオープン時のモード
  cv_flag_1                      CONSTANT VARCHAR2(1)   := '1';                  -- 作成元区分 1 控除黒
  cv_flag_2                      CONSTANT VARCHAR2(1)   := '2';                  -- 作成元区分 2 控除赤（リカバリ赤、差額調整取消、繰越調整取消）
  cv_flag_3                      CONSTANT VARCHAR2(1)   := '3';                  -- 作成元区分 3 控除赤（速報戻し）
  cv_status_cancel               CONSTANT VARCHAR2(1)   := 'C';                  -- ステータス C キャンセル
  cv_status_new                  CONSTANT VARCHAR2(1)   := 'N';                  -- ステータス N 新規
  cv_source_category_v           CONSTANT VARCHAR2(1)   := 'V';                  -- 作成元区分 V 売上実績振替
  cv_source_category_s           CONSTANT VARCHAR2(1)   := 'S';                  -- 作成元区分 S 販売実績
  cv_source_category_t           CONSTANT VARCHAR2(1)   := 'T';                  -- 作成元区分 T 売上実績振替（EDI）
  cv_source_category_d           CONSTANT VARCHAR2(1)   := 'D';                  -- 作成元区分 D 差額調整
  cv_source_category_o           CONSTANT VARCHAR2(1)   := 'O';                  -- 作成元区分 O 繰越調整
  cv_source_category_u           CONSTANT VARCHAR2(1)   := 'U';                  -- 作成元区分 U アップロード
  cv_source_category_f           CONSTANT VARCHAR2(1)   := 'F';                  -- 作成元区分 F 定額控除
  cv_report_decision_flag_0      CONSTANT VARCHAR2(1)   := '0';                  -- 速報確定フラグ 0 
  cv_sales_class_1               CONSTANT VARCHAR2(1)   := '1';                  -- 売上区分 1通常
  cv_delivery_pattern_class_6    CONSTANT VARCHAR2(1)   := '6';                  -- 納品形態区分 6 実績振替
  cv_delivery_pattern_class_9    CONSTANT VARCHAR2(1)   := '9';                  -- 納品形態区分 9 その他
  cv_data_type_lookup            CONSTANT VARCHAR2(30)  := 'XXCOK1_DEDUCTION_DATA_TYPE'; -- データ種類 参照タイプ

  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_proc_date                   DATE;                                          -- 業務日付
  gv_trans_date                  VARCHAR2(14);                                  -- 連携日付
  gv_csv_file_dir                VARCHAR2(1000);                                -- 控除データ（情報系）連携用CSVファイル出力先の取得
  gv_file_name                   VARCHAR2(30);                                  -- 控除データ（情報系）連携用CSVファイル名
  gv_item_code_dummy_f           VARCHAR2(7);                                   -- ダミー品目コード（定額控除）
  gv_item_code_dummy_u           VARCHAR2(7);                                   -- ダミー品目コード（アップロード）
  gv_item_code_dummy_o           VARCHAR2(7);                                   -- ダミー品目コード（繰越調整）
  gn_target_header_id_st_1       NUMBER;                                        -- 販売控除ID (自)控除黒
  gn_target_header_id_ed_1       NUMBER;                                        -- 販売控除ID (至)控除黒
  gd_target_header_date_st_2     DATE;                                          -- 販売控除ID (自)控除赤（リカバリ赤、差額調整取消、繰越調整取消）
  gd_target_header_date_ed_2     DATE;                                          -- 販売控除ID (至)控除赤（リカバリ赤、差額調整取消、繰越調整取消）
  gn_target_header_id_st_3       NUMBER;                                        -- 販売控除ID (自)控除赤（速報戻し）
  gn_target_header_id_ed_3       NUMBER;                                        -- 販売控除ID (至)控除赤（速報戻し）
--
  /**********************************************************************************
   * Procedure Name   : proc_init
   * Description      : 初期処理プロシージャ(A-1)
   ***********************************************************************************/
  PROCEDURE proc_init(
    ov_errbuf      OUT    VARCHAR2         --   エラー・メッセージ           --# 固定 #
   ,ov_retcode     OUT    VARCHAR2         --   リターン・コード             --# 固定 #
   ,ov_errmsg      OUT    VARCHAR2         --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'proc_init';          -- プログラム名
--
    -- ===============================
    -- 固定ローカル変数
    -- ===============================
    lv_errbuf                 VARCHAR2(5000);                                 -- エラー・メッセージ
    lv_retcode                VARCHAR2(1);                                    -- リターン・コード
    lv_errmsg                 VARCHAR2(5000);                                 -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_step                   VARCHAR2(100);                                    -- ステップ
    lv_message_token          VARCHAR2(100);                                    -- 連携日付
    lb_fexists                BOOLEAN;                                          -- ファイル存在判断
    ln_file_length            NUMBER;                                           -- ファイルの文字列数
    lbi_block_size            BINARY_INTEGER;                                   -- ブロックサイズ
    lv_csv_file               VARCHAR2(1000);                                   -- csvファイル名
    --
    -- *** ユーザー定義例外 ***
    profile_expt              EXCEPTION;                                        -- プロファイル取得例外
    csv_file_exst_expt        EXCEPTION;                                        -- CSVファイル存在エラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 業務日付の取得
    lv_step := 'A-1.1';
    lv_message_token := '業務日付の取得';
    gd_proc_date := xxccp_common_pkg2.get_process_date;
    IF ( gd_proc_date IS NULL ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_appl_name_xxcok,
        iv_name               =>  cv_msg_proc_date_err
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt_log;
    END IF;
--
    -- 連携日時の取得
    lv_step := 'A-1.2';
    lv_message_token := '連携日時の取得';
    gv_trans_date    := TO_CHAR( SYSDATE, cv_date_fmt_dt_ymdhms );
--
    -- プロファイル取得
    lv_step := 'A-1.3a';
    lv_message_token := '連携用CSVファイル名の取得';
    -- 控除データ（情報系）連携用CSVファイル名の取得
    gv_file_name := FND_PROFILE.VALUE( cv_csv_fl_name );
    -- 取得エラー時
    IF ( gv_file_name IS NULL ) THEN
      lv_message_token := cv_csv_fl_name;
      RAISE profile_expt;
    END IF;
--
    lv_csv_file := xxccp_common_pkg.get_msg(                                    -- アップロード名称の出力
                    iv_application  => cv_appl_name_xxcok                       -- アプリケーション短縮名
                   ,iv_name         => cv_msg_xxcok_00006                       -- メッセージコード
                   ,iv_token_name1  => cv_tkn_file_name                         -- トークンコード1
                   ,iv_token_value1 => gv_file_name                             -- トークン値1
                  );
    -- ファイル名出力
    xxcmm_004common_pkg.put_message(
      iv_message_buff => lv_csv_file
     ,ov_errbuf       => lv_errbuf
     ,ov_retcode      => lv_retcode
     ,ov_errmsg       => lv_errmsg
    );
--
    lv_step := 'A-1.3b';
    lv_message_token := '連携用CSVファイル出力先の取得';
    -- 控除データ（情報系）連携用CSVファイル出力先の取得
    gv_csv_file_dir := FND_PROFILE.VALUE( cv_csv_fl_dir );
    -- 取得エラー時
    IF ( gv_csv_file_dir IS NULL ) THEN
      lv_message_token := cv_csv_fl_dir;
      RAISE profile_expt;
    END IF;
--
    lv_step := 'A-1.3c';
    lv_message_token := 'ダミー品目コード（定額控除）の取得';
    -- ダミー品目コードの取得
    gv_item_code_dummy_f := FND_PROFILE.VALUE( cv_item_code_dummy_f );
    -- 取得エラー時
    IF ( gv_item_code_dummy_f IS NULL ) THEN
      lv_message_token := cv_item_code_dummy_f;
      RAISE profile_expt;
    END IF;
--
    lv_step := 'A-1.3d';
    lv_message_token := 'ダミー品目コード（アップロード）の取得';
    -- ダミー品目コードの取得
    gv_item_code_dummy_u := FND_PROFILE.VALUE( cv_item_code_dummy_u );
    -- 取得エラー時
    IF ( gv_item_code_dummy_u IS NULL ) THEN
      lv_message_token := cv_item_code_dummy_u;
      RAISE profile_expt;
    END IF;
--
    lv_step := 'A-1.3e';
    lv_message_token := 'ダミー品目コード（繰越調整）の取得';
    -- ダミー品目コードの取得
    gv_item_code_dummy_o := FND_PROFILE.VALUE( cv_item_code_dummy_o );
    -- 取得エラー時
    IF ( gv_item_code_dummy_o IS NULL ) THEN
      lv_message_token := cv_item_code_dummy_o;
      RAISE profile_expt;
    END IF;
--
    lv_step := 'A-1.4';
    lv_message_token := 'CSVファイル存在チェック';
--
    -- CSVファイル存在チェック
    UTL_FILE.FGETATTR(
       location    => gv_csv_file_dir
      ,filename    => gv_file_name
      ,fexists     => lb_fexists
      ,file_length => ln_file_length
      ,block_size  => lbi_block_size
    );
    -- ファイル存在時
    IF ( lb_fexists = TRUE ) THEN
      RAISE csv_file_exst_expt;
    END IF;
--
    -- 処理対象となる販売控除ID取得
    lv_step := 'A-1.5';
    lv_message_token := '処理対象となる販売控除ID取得';
    -- ①控除黒
    BEGIN
--
      SELECT  xsdc.last_processing_id + 1
      INTO    gn_target_header_id_st_1
      FROM    xxcok_sales_deduction_control xsdc
      WHERE   xsdc.control_flag = cv_flag_1;
--
    EXCEPTION
      WHEN  OTHERS THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        cv_appl_name_xxcok
                      , cv_msg_xxcok_10592
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
--
    SELECT  MAX(xsd.sales_deduction_id)
    INTO    gn_target_header_id_ed_1
    FROM    xxcok_sales_deduction xsd
    WHERE   xsd.sales_deduction_id >= gn_target_header_id_st_1;
--
    -- ②控除赤データ(リカバリ赤、差額調整取消、繰越調整取消)
    BEGIN
--
      SELECT  xsdc.last_cooperation_date
      INTO    gd_target_header_date_st_2
      FROM    xxcok_sales_deduction_control xsdc
      WHERE   xsdc.control_flag = cv_flag_2;
--
    EXCEPTION
      WHEN  OTHERS THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        cv_appl_name_xxcok
                      , cv_msg_xxcok_10592
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
--
    gd_target_header_date_ed_2 := gd_proc_date ;
--
    -- ③控除赤データ(速報戻し)
    BEGIN
--
      SELECT  xsdc.last_processing_id + 1
      INTO    gn_target_header_id_st_3
      FROM    xxcok_sales_deduction_control xsdc
      WHERE   xsdc.control_flag = cv_flag_3;
--
    EXCEPTION
      WHEN  OTHERS THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        cv_appl_name_xxcok
                      , cv_msg_xxcok_10592
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
--
    SELECT  MAX(xdtr.sales_deduction_id)
    INTO    gn_target_header_id_ed_3
    FROM    xxcok_dedu_trn_rev xdtr
    WHERE   xdtr.sales_deduction_id >= gn_target_header_id_st_3;
--
  EXCEPTION
    -- *** 任意で例外処理を記述する ****
    -- カーソルのクローズをここに記述する
    --*** プロファイル取得エラー ***
    WHEN profile_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok            -- アプリケーション短縮名：XXCOK
                     ,iv_name         => cv_msg_xxcok_00003            -- メッセージ：APP-XXCOK1-00003 プロファイル取得エラー
                     ,iv_token_name1  => cv_tkn_profile                -- トークン：PROFILE
                     ,iv_token_value1 => lv_message_token              -- プロファイル名
                     );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg;
      ov_retcode := cv_status_error;
    --*** CSVファイル存在エラー ***
    WHEN csv_file_exst_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok            -- アプリケーション短縮名：XXCOK
                     ,iv_name         => cv_msg_xxcok_00009            -- メッセージ：APP-XXCOK1-00009 CSVファイル存在エラー
                     ,iv_token_name1  => cv_tkn_file_name              -- トークン：FILE_NAME
                     ,iv_token_value1 => gv_file_name                  -- プロファイル名
                     );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf    := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      ov_retcode   := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_init;
--
  /**********************************************************************************
   * Procedure Name   : upd_control_p
   * Description      : 販売控除管理情報更新(A-5)
   ***********************************************************************************/
  PROCEDURE upd_control_p(
    ov_errbuf  OUT VARCHAR2                                 -- エラー・メッセージ
  , ov_retcode OUT VARCHAR2                                 -- リターン・コード
  , ov_errmsg  OUT VARCHAR2                                 -- ユーザー・エラー・メッセージ
  )
  IS
--
    -- ==============================
    -- ローカル定数
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'upd_control_p'; -- プログラム名
    -- ==============================
    -- ローカル変数
    -- ==============================
    lv_errbuf        VARCHAR2(5000)      DEFAULT NULL;       -- エラー・メッセージ
    lv_retcode       VARCHAR2(1)         DEFAULT NULL;       -- リターン・コード
    lv_errmsg        VARCHAR2(5000)      DEFAULT NULL;       -- ユーザー・エラー・メッセージ
    lv_step          VARCHAR2(100);                          -- ステップ
    lv_message_token VARCHAR2(100);                          -- 連携日付
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- ============================================================
    -- 販売控除管理情報更新
    -- ============================================================
   lv_step := 'A-5.1';
   lv_message_token := ' 販売控除管理情報更新';
   UPDATE  xxcok_sales_deduction_control
    SET     last_processing_id      = NVL(gn_target_header_id_ed_1, last_processing_id) ,
            last_updated_by         = cn_last_updated_by                            ,
            last_update_date        = SYSDATE                                       ,
            last_update_login       = cn_last_update_login                          ,
            request_id              = cn_request_id                                 ,
            program_application_id  = cn_program_application_id                     ,
            program_id              = cn_program_id                                 ,
            program_update_date     = SYSDATE
    WHERE   control_flag  = cv_flag_1;
--
    UPDATE  xxcok_sales_deduction_control
    SET     last_cooperation_date   = NVL(gd_target_header_date_ed_2, last_cooperation_date) ,
            last_updated_by         = cn_last_updated_by                            ,
            last_update_date        = SYSDATE                                       ,
            last_update_login       = cn_last_update_login                          ,
            request_id              = cn_request_id                                 ,
            program_application_id  = cn_program_application_id                     ,
            program_id              = cn_program_id                                 ,
            program_update_date     = SYSDATE
    WHERE   control_flag  = cv_flag_2;
--
    UPDATE  xxcok_sales_deduction_control
    SET     last_processing_id      = NVL(gn_target_header_id_ed_3, last_processing_id) ,
            last_updated_by         = cn_last_updated_by                            ,
            last_update_date        = SYSDATE                                       ,
            last_update_login       = cn_last_update_login                          ,
            request_id              = cn_request_id                                 ,
            program_application_id  = cn_program_application_id                     ,
            program_id              = cn_program_id                                 ,
            program_update_date     = SYSDATE
    WHERE   control_flag  = cv_flag_3;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数例外ハンドラ ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END upd_control_p;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf      OUT    VARCHAR2         --   エラー・メッセージ           --# 固定 #
   ,ov_retcode     OUT    VARCHAR2         --   リターン・コード             --# 固定 #
   ,ov_errmsg      OUT    VARCHAR2         --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'submain';            -- プログラム名
    -- ===============================
    -- 固定ローカル変数
    -- ===============================
    lv_errbuf                 VARCHAR2(5000);                                 -- エラー・メッセージ
    lv_retcode                VARCHAR2(1);                                    -- リターン・コード
    lv_errmsg                 VARCHAR2(5000);                                 -- ユーザー・エラー・メッセージ
    lv_step                   VARCHAR2(100);                                  -- ステップ
    lv_sales_class            VARCHAR2(1);                                    -- 売上区分
    lv_delivery_pattern_class VARCHAR2(1);                                    -- 納品形態区分
    lv_attribute11            VARCHAR2(150);                                  -- 控除データ種類DFF11 変動対価区分
    lv_attribute12            VARCHAR2(150);                                  -- 控除データ種類DFF12 変動対価区分(差額調整分)
    lv_fluctuation_value_class   VARCHAR2(150);                               -- 変動対価区分
    lv_data_type_name         VARCHAR2(80);                                   -- 控除データ種類名称
    --###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザーローカル変数
    -- ===============================
    lv_sqlerrm                VARCHAR2(5000);                                 -- SQLERRM退避
    lf_file_hand              UTL_FILE.FILE_TYPE;                             -- ファイル・ハンドルの宣言
    lv_message_token          VARCHAR2(100);                                  -- 連携日付
    lv_out_csv_line           VARCHAR2(1000);                                 -- 出力行
    lv_item_code              VARCHAR2(7);                                    -- 品目コード
--
    -- 控除データ（情報系）情報カーソル
    --lv_step := 'A-2';
    CURSOR csv_deduction_cur
    IS
      --①控除黒
      SELECT sales_deduction_id ,
             --base_code_from,
             base_code_to,
             --customer_code_from,
             customer_code_to,
             deduction_chain_code,
             corp_code,
             record_date,
             source_category,
             source_line_id,
             condition_id,
             condition_no,
             condition_line_id,
             data_type,
             status ,
             item_code,
             sales_uom_code,
             sales_unit_price,
             sales_quantity,
             sale_pure_amount,
             sale_tax_amount,
             deduction_uom_code,
             deduction_unit_price,
             deduction_quantity,
             deduction_amount,
             compensation,
             margin,
             sales_promotion_expenses,
             margin_reduction,
             tax_code,
             tax_rate,
             recon_tax_code,
             recon_tax_rate,
             deduction_tax_amount,
             --remarks,
             application_no,
             --gl_if_flag,
             --gl_base_code,
             --gl_date,
             --recovery_date,
             --recovery_add_request_id,
             report_decision_flag,
             recovery_del_date ,
             --recovery_del_request_id,
             --cancel_flag,
             --cancel_base_code,
             --cancel_gl_date,
             --cancel_user,
             --recon_base_code,
             --recon_slip_num,
             --carry_payment_slip_num,
             --gl_interface_id,
             --cancel_gl_interface_id,
             created_by,
             last_updated_by,
             --last_update_login,
             --request_id,
             --program_application_id,
             --program_id,
             --program_update_date,
             create_user_name,
             creation_date,
             last_updated_user_name,
             last_update_date 
      FROM
         (SELECT xsd.sales_deduction_id ,                                         --販売控除ID
                 --xsd.base_code_from ,
                 xsd.base_code_to ,                                               --振替先拠点
                 --xsd.customer_code_from ,
                 xsd.customer_code_to ,                                           --振替先顧客コード
                 xsd.deduction_chain_code ,                                       --控除用チェーンコード
                 xsd.corp_code ,                                                  --企業コード
                 TO_CHAR( xsd.record_date , cv_date_fmt_ymd )
                                                      record_date,                --計上日
                 xsd.source_category ,                                            --作成元区分
                 xsd.source_line_id ,                                             --作成元明細ID
                 xsd.condition_id ,                                               --控除条件ID
                 xsd.condition_no ,                                               --控除番号
                 xsd.condition_line_id ,                                          --控除詳細ID
                 xsd.data_type ,                                                  --データ種類
                 cv_status_new                        status ,                    --ステータス
                 xsd.item_code ,                                                  --品目コード
                 xsd.sales_uom_code ,                                             --販売単位
                 xsd.sales_unit_price ,                                           --販売単価
                 xsd.sales_quantity ,                                             --販売数量
                 xsd.sale_pure_amount ,                                           --売上本体金額
                 xsd.sale_tax_amount ,                                            --売上消費税額
                 xsd.deduction_uom_code ,                                         --控除単位
                 xsd.deduction_unit_price ,                                       --控除単価
                 xsd.deduction_quantity ,                                         --控除数量
                 xsd.deduction_amount ,                                           --控除額
                 xsd.compensation ,                                               --補填
                 xsd.margin ,                                                     --問屋マージン
                 xsd.sales_promotion_expenses ,                                   --拡売
                 xsd.margin_reduction ,                                           --問屋マージン減額
                 xsd.tax_code ,                                                   --税コード
                 xsd.tax_rate ,                                                   --税率
                 xsd.recon_tax_code ,                                             --消込時税コード
                 xsd.recon_tax_rate ,                                             --消込時税率
                 xsd.deduction_tax_amount ,                                       --控除税額
                 --xsd.remarks ,
                 xsd.application_no ,                                             --申請書No.
                 --xsd.gl_if_flag ,
                 --xsd.gl_base_code ,
                 --xsd.gl_date ,
                 --xsd.recovery_date ,
                 --xsd.recovery_add_request_id ,
                 xsd.report_decision_flag ,                                       --速報確定フラグ
                 NULL                                 recovery_del_date ,         --リカバリデータ削除時日付
                 --xsd.recovery_del_request_id ,
                 --xsd.cancel_flag ,
                 --xsd.cancel_base_code ,
                 --xsd.cancel_gl_date ,
                 --xsd.cancel_user ,
                 --xsd.recon_base_code ,
                 --xsd.recon_slip_num ,
                 --xsd.carry_payment_slip_num ,
                 --xsd.gl_interface_id ,
                 --xsd.cancel_gl_interface_id ,
                 xsd.created_by ,                                                 --作成者
                 xsd.last_updated_by ,                                            --最終更新者
                 --xsd.last_update_login ,
                 --xsd.request_id ,
                 --xsd.program_application_id ,
                 --xsd.program_id ,
                 --xsd.program_update_date ,
                 fu1.user_name                        create_user_name,           -- 作成者
                 TO_CHAR( xsd.creation_date, cv_date_fmt_ymd )
                                                      creation_date,              -- 作成日
                 fu2.user_name                        last_updated_user_name,     -- 最終更新者
                 TO_CHAR( xsd.last_update_date, cv_date_fmt_ymd )
                                                      last_update_date            -- 最終更新日
          FROM   xxcok_sales_deduction xsd,  -- 販売控除情報
                 fnd_user fu1,               -- ユーザ
                 fnd_user fu2                -- ユーザ
          WHERE  1=1
          AND    xsd.sales_deduction_id BETWEEN gn_target_header_id_st_1  AND gn_target_header_id_ed_1
          AND    xsd.created_by      = fu1.user_id(+)
          AND    xsd.last_updated_by = fu2.user_id(+)
          ORDER BY xsd.sales_deduction_id
         ) 
          UNION ALL
      --②控除赤データ(リカバリ赤、差額調整取消、繰越調整取消)
      SELECT sales_deduction_id,
             --base_code_from,
             base_code_to,
             --customer_code_from,
             customer_code_to,
             deduction_chain_code,
             corp_code,
             record_date,
             source_category,
             source_line_id,
             condition_id,
             condition_no,
             condition_line_id,
             data_type,
             status,
             item_code,
             sales_uom_code,
             sales_unit_price,
             sales_quantity,
             sale_pure_amount,
             sale_tax_amount,
             deduction_uom_code,
             deduction_unit_price,
             deduction_quantity,
             deduction_amount,
             compensation,
             margin,
             sales_promotion_expenses,
             margin_reduction,
             tax_code,
             tax_rate,
             recon_tax_code,
             recon_tax_rate,
             deduction_tax_amount,
             --remarks,
             application_no,
             --gl_if_flag,
             --gl_base_code,
             --gl_date,
             --recovery_date,
             --recovery_add_request_id,
             report_decision_flag,
             recovery_del_date,
             --recovery_del_request_id,
             --cancel_flag,
             --cancel_base_code,
             --cancel_gl_date,
             --cancel_user,
             --recon_base_code,
             --recon_slip_num,
             --carry_payment_slip_num,
             --gl_interface_id,
             --cancel_gl_interface_id,
             created_by,
             last_updated_by,
             --last_update_login,
             --request_id,
             --program_application_id,
             --program_id,
             --program_update_date,
             create_user_name,
             creation_date,
             last_updated_user_name,
             last_update_date 
      FROM
         (SELECT xsd.sales_deduction_id ,                                         --販売控除ID
                 --xsd.base_code_from ,
                 xsd.base_code_to ,                                               --振替先拠点
                 --xsd.customer_code_from ,
                 xsd.customer_code_to ,                                           --振替先顧客コード
                 xsd.deduction_chain_code ,                                       --控除用チェーンコード
                 xsd.corp_code ,                                                  --企業コード
                 TO_CHAR( xsd.record_date , cv_date_fmt_ymd )
                                                      record_date,                --計上日
                 xsd.source_category ,                                            --作成元区分
                 xsd.source_line_id ,                                             --作成元明細ID
                 xsd.condition_id ,                                               --控除条件ID
                 xsd.condition_no ,                                               --控除番号
                 xsd.condition_line_id ,                                          --控除詳細ID
                 xsd.data_type ,                                                  --データ種類
                 xsd.status ,                                                     --ステータス
                 xsd.item_code ,                                                  --品目コード
                 xsd.sales_uom_code ,                                             --販売単位
                 xsd.sales_unit_price ,                                           --販売単価
                 xsd.sales_quantity * -1              sales_quantity,             --販売数量
                 xsd.sale_pure_amount * -1            sale_pure_amount,           --売上本体金額
                 xsd.sale_tax_amount * -1             sale_tax_amount,            --売上消費税額
                 xsd.deduction_uom_code ,                                         --控除単位
                 xsd.deduction_unit_price ,                                       --控除単価
                 xsd.deduction_quantity * -1          deduction_quantity,         --控除数量
                 xsd.deduction_amount * -1            deduction_amount,           --控除額
                 xsd.compensation * -1                compensation,               --補填
                 xsd.margin * -1                      margin,                     --問屋マージン
                 xsd.sales_promotion_expenses * -1    sales_promotion_expenses,   --拡売
                 xsd.margin_reduction * -1            margin_reduction,           --問屋マージン減額
                 xsd.tax_code ,                                                   --税コード
                 xsd.tax_rate ,                                                   --税率
                 xsd.recon_tax_code ,                                             --消込時税コード
                 xsd.recon_tax_rate ,                                             --消込時税率
                 xsd.deduction_tax_amount * -1        deduction_tax_amount,       --控除税額
                 --xsd.remarks ,
                 xsd.application_no ,                                             --申請書No.
                 --xsd.gl_if_flag ,
                 --xsd.gl_base_code ,
                 --xsd.gl_date ,
                 --xsd.recovery_date ,
                 --xsd.recovery_add_request_id ,
                 xsd.report_decision_flag ,                                       --速報確定フラグ
                 TO_CHAR( xsd.recovery_del_date, cv_date_fmt_ymd )
                                                      recovery_del_date,          --リカバリデータ削除時日付
                 --xsd.recovery_del_request_id ,
                 --xsd.cancel_flag ,
                 --xsd.cancel_base_code ,
                 --xsd.cancel_gl_date ,
                 --xsd.cancel_user ,
                 --xsd.recon_base_code ,
                 --xsd.recon_slip_num ,
                 --xsd.carry_payment_slip_num ,
                 --xsd.gl_interface_id ,
                 --xsd.cancel_gl_interface_id ,
                 xsd.created_by ,                                                 --作成者
                 xsd.last_updated_by ,                                            --最終更新者
                 --xsd.last_update_login ,
                 --xsd.request_id ,
                 --xsd.program_application_id ,
                 --xsd.program_id ,
                 --xsd.program_update_date ,
                 fu1.user_name                        create_user_name,           -- 作成者
                 TO_CHAR( xsd.creation_date, cv_date_fmt_ymd )
                                                      creation_date,              -- 作成日
                 fu2.user_name                        last_updated_user_name,     -- 最終更新者
                 TO_CHAR( xsd.last_update_date, cv_date_fmt_ymd )
                                                      last_update_date            -- 最終更新日
          FROM   xxcok_sales_deduction xsd,  -- 販売控除情報
                 fnd_user fu1,               -- ユーザ
                 fnd_user fu2                -- ユーザ
          WHERE  1=1
          AND    xsd.recovery_del_date >  gd_target_header_date_st_2  
          AND    xsd.recovery_del_date <= gd_target_header_date_ed_2
          AND    xsd.status            =  cv_status_cancel
          AND    xsd.created_by        =  fu1.user_id(+)
          AND    xsd.last_updated_by   =  fu2.user_id(+)
          ORDER BY xsd.sales_deduction_id
         )
          UNION ALL
      --③控除赤データ(速報戻し)
      SELECT sales_deduction_id,
             --base_code_from,
             base_code_to,
             --customer_code_from,
             customer_code_to,
             deduction_chain_code,
             corp_code,
             record_date,
             source_category,
             source_line_id,
             condition_id,
             condition_no,
             condition_line_id,
             data_type,
             status,
             item_code,
             sales_uom_code,
             sales_unit_price,
             sales_quantity,
             sale_pure_amount,
             sale_tax_amount,
             deduction_uom_code,
             deduction_unit_price,
             deduction_quantity,
             deduction_amount,
             compensation,
             margin,
             sales_promotion_expenses,
             margin_reduction,
             tax_code,
             tax_rate,
             recon_tax_code,
             recon_tax_rate,
             deduction_tax_amount,
             --remarks,
             application_no,
             --gl_if_flag,
             --gl_base_code,
             --gl_date,
             --recovery_date,
             --recovery_add_request_id,
             report_decision_flag,
             recovery_del_date,
             --recovery_del_request_id,
             --cancel_flag,
             --cancel_base_code,
             --cancel_gl_date,
             --cancel_user,
             --recon_base_code,
             --recon_slip_num,
             --carry_payment_slip_num,
             --gl_interface_id,
             --cancel_gl_interface_id,
             created_by,
             last_updated_by,
             --last_update_login,
             --request_id,
             --program_application_id,
             --program_id,
             --program_update_date,
             create_user_name,
             creation_date,
             last_updated_user_name,
             last_update_date 
      FROM
         (SELECT xdtr.sales_deduction_id ,                                         --販売控除ID
                 --xdtr.base_code_from ,
                 xdtr.base_code_to ,                                               --振替先拠点
                 --xdtr.customer_code_from ,
                 xdtr.customer_code_to ,                                           --振替先顧客コード
                 NULL                                  deduction_chain_code,       --控除用チェーンコード
                 NULL                                  corp_code,                  --企業コード
                 TO_CHAR( xdtr.record_date , cv_date_fmt_ymd )
                                                       record_date,                --計上日
                 cv_source_category_v                  source_category,            --作成元区分
                 xdtr.source_line_id ,                                             --作成元明細ID
                 xdtr.condition_id ,                                               --控除条件ID
                 xdtr.condition_no ,                                               --控除番号
                 xdtr.condition_line_id ,                                          --控除詳細ID
                 xdtr.data_type ,                                                  --データ種類
                 cv_status_cancel                      status,                     --ステータス
                 xdtr.item_code ,                                                  --品目コード
                 xdtr.sales_uom_code ,                                             --販売単位
                 xdtr.sales_unit_price ,                                           --販売単価
                 xdtr.sales_quantity                   sales_quantity,             --販売数量
                 xdtr.sale_pure_amount                 sale_pure_amount,           --売上本体金額
                 xdtr.sale_tax_amount                  sale_tax_amount,            --売上消費税額
                 xdtr.deduction_uom_code ,                                         --控除単位
                 xdtr.deduction_unit_price ,                                       --控除単価
                 xdtr.deduction_quantity               deduction_quantity,         --控除数量
                 xdtr.deduction_amount                 deduction_amount,           --控除額
                 xdtr.compensation                     compensation,               --補填
                 xdtr.margin                           margin,                     --問屋マージン
                 xdtr.sales_promotion_expenses         sales_promotion_expenses,   --拡売
                 xdtr.margin_reduction                 margin_reduction,           --問屋マージン減額
                 xdtr.tax_code ,                                                   --税コード
                 xdtr.tax_rate ,                                                   --税率
                 NULL                                  recon_tax_code,             --消込時税コード
                 NULL                                  recon_tax_rate,             --消込時税率
                 xdtr.deduction_tax_amount             deduction_tax_amount,       --控除税額
                 --xdtr.remarks ,
                 NULL                                  application_no,             --申請書No.
                 --xdtr.gl_if_flag ,
                 --xdtr.gl_base_code ,
                 --xdtr.gl_date ,
                 --xdtr.recovery_date ,
                 --xdtr.recovery_add_request_id ,
                 cv_report_decision_flag_0             report_decision_flag,       --速報確定フラグ
                 NULL                                  recovery_del_date,          --リカバリデータ削除時日付
                 --xdtr.recovery_del_request_id ,
                 --xdtr.cancel_flag ,
                 --xdtr.cancel_base_code ,
                 --xdtr.cancel_gl_date ,
                 --xdtr.cancel_user ,
                 --xdtr.recon_base_code ,
                 --xdtr.recon_slip_num ,
                 --xdtr.carry_payment_slip_num ,
                 --xdtr.gl_interface_id ,
                 --xdtr.cancel_gl_interface_id ,
                 xdtr.created_by ,                                                 --作成者
                 xdtr.last_updated_by ,                                            --最終更新者
                 --xdtr.last_update_login ,
                 --xdtr.request_id ,
                 --xdtr.program_application_id ,
                 --xdtr.program_id ,
                 --xdtr.program_update_date ,
                 fu1.user_name                         create_user_name,           -- 作成者
                 TO_CHAR( xdtr.creation_date, cv_date_fmt_ymd )
                                                       creation_date,              -- 作成日
                 fu2.user_name                         last_updated_user_name,     -- 最終更新者
                 TO_CHAR( xdtr.last_update_date, cv_date_fmt_ymd )
                                                       last_update_date            -- 最終更新日
          FROM   xxcok_dedu_trn_rev xdtr,    -- 販売控除情報
                 fnd_user fu1,               -- ユーザ
                 fnd_user fu2                -- ユーザ
          WHERE  1=1
          AND    xdtr.sales_deduction_id BETWEEN gn_target_header_id_st_3  AND gn_target_header_id_ed_3
          AND    xdtr.created_by      = fu1.user_id(+)
          AND    xdtr.last_updated_by = fu2.user_id(+)
          ORDER BY xdtr.sales_deduction_id
         ) ;
--
    TYPE csv_deduction_ttype IS TABLE OF csv_deduction_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    lt_csv_deduction_tab       csv_deduction_ttype;               -- 控販売控除情報IF出力データ
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    subproc_expt              EXCEPTION;       -- サブプログラムエラー
    file_open_expt            EXCEPTION;       -- ファイルオープンエラー
    file_output_expt          EXCEPTION;       -- ファイル書き込みエラー
    file_close_expt           EXCEPTION;       -- ファイルクローズエラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- ===============================================
    -- proc_initの呼び出し（初期処理はproc_initで行う）
    -- ===============================================
    proc_init(
       ov_errbuf      => lv_errbuf       -- エラー・メッセージ           --# 固定 #
      ,ov_retcode     => lv_retcode      -- リターン・コード             --# 固定 #
      ,ov_errmsg      => lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE subproc_expt;
    END IF;
--
    -----------------------------------
    -- A-2.販売控除情報の取得
    -----------------------------------
    lv_step := 'A-2';
--
    OPEN  csv_deduction_cur;
    FETCH csv_deduction_cur BULK COLLECT INTO lt_csv_deduction_tab;
    CLOSE csv_deduction_cur;
    -- 処理件数カウント
    gn_target_cnt := lt_csv_deduction_tab.COUNT;
--
    -----------------------------------------------
    -- A-3.販売区分、納品形態区分、変動対価区分の取得
    -----------------------------------------------
    lv_step := 'A-4.1a';
      -- CSVファイルオープン
      lv_step := 'A-1.5';
      BEGIN
        lf_file_hand := UTL_FILE.FOPEN(  location  => gv_csv_file_dir  -- 出力先
                                        ,filename  => gv_file_name     -- CSVファイル名
                                        ,open_mode => cv_csv_mode      -- モード
                                       );
      EXCEPTION
        WHEN OTHERS THEN
          lv_sqlerrm := SQLERRM;
          RAISE file_open_expt;
      END;
--
      <<out_csv_loop>>
      FOR i IN 1..lt_csv_deduction_tab.COUNT LOOP
--
      -- 販売区分、納品形態区分取得
      lv_step := 'A-3.1' || 'sales_deduction_id:' || lt_csv_deduction_tab( i ).sales_deduction_id;
        IF (lt_csv_deduction_tab( i ).source_category = cv_source_category_s ) THEN
          BEGIN
            SELECT sales_class,
                   delivery_pattern_class
            INTO   lv_sales_class,
                   lv_delivery_pattern_class
            FROM   xxcos_sales_exp_lines xsel
            WHERE  xsel.sales_exp_line_id = lt_csv_deduction_tab( i ).source_line_id;
      --
          EXCEPTION
              WHEN  NO_DATA_FOUND THEN
                lv_sales_class            := NULL;
                lv_delivery_pattern_class := NULL;
          END;
        ELSIF (lt_csv_deduction_tab( i ).source_category = cv_source_category_t ) THEN
            lv_sales_class            := cv_sales_class_1;
            lv_delivery_pattern_class := cv_delivery_pattern_class_6;
        ELSIF (lt_csv_deduction_tab( i ).source_category = cv_source_category_v ) THEN
            lv_sales_class            := cv_sales_class_1;
            lv_delivery_pattern_class := cv_delivery_pattern_class_6;
        ELSE
            lv_sales_class            := cv_sales_class_1;
            lv_delivery_pattern_class := cv_delivery_pattern_class_9;
        END IF;
      -- 変動対価区分取得
      lv_step := 'A-3.3' || 'sales_deduction_id:' || lt_csv_deduction_tab( i ).sales_deduction_id;
        BEGIN
          SELECT attribute11,
                 attribute12,
                 meaning
          INTO   lv_attribute11,
                 lv_attribute12,
                 lv_data_type_name
          FROM   fnd_lookup_values_vl flv
          WHERE  flv.lookup_code = lt_csv_deduction_tab( i ).data_type
          AND    flv.lookup_type = cv_data_type_lookup;
        EXCEPTION
            WHEN  NO_DATA_FOUND THEN
                 lv_attribute11    := null;
                 lv_attribute12    := null;
                 lv_data_type_name := null;
        END;
--
        IF lt_csv_deduction_tab( i ).source_category = cv_source_category_d THEN
          lv_fluctuation_value_class := lv_attribute12;
-- 2021/04/20 MOD Start
        ELSIF lt_csv_deduction_tab( i ).source_category = cv_source_category_o THEN
          lv_fluctuation_value_class := null;
-- 2021/04/20 MOD Start
        ELSE
          lv_fluctuation_value_class := lv_attribute11;
        END IF;
--
    -----------------------------------------------
    -- A-4.販売控除情報（情報系）出力処理
    -----------------------------------------------
      -- ファイル出力
      lv_step := 'A-4.1b';
        lv_out_csv_line := '';
        -- 会社コード
        lv_step := 'A-4.company_code';
        lv_out_csv_line := lv_out_csv_line  ||
                           cv_dqu ||
                           cv_company_code ||
                           cv_dqu;
        --販売控除ID
        lv_step := 'A-4.sales_deduction_id';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_deduction_tab( i ).sales_deduction_id ;
        --拠点コード
        lv_step := 'A-4.base_code_to';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_deduction_tab( i ).base_code_to ||
                           cv_dqu;
       --顧客コード
        lv_step := 'A-4.customer_code_to';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_deduction_tab( i ).customer_code_to ||
                           cv_dqu;
        --控除用チェーンコード
        lv_step := 'A-4.deduction_chain_code';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_deduction_tab( i ).deduction_chain_code ||
                           cv_dqu;
        --企業コード
        lv_step := 'A-4.corp_code';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_deduction_tab( i ).corp_code ||
                           cv_dqu;
        --計上日【YYYYMMDD】
        lv_step := 'A-4.record_date';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_deduction_tab( i ).record_date ;
        --作成元区分
        lv_step := 'A-4.source_category';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_deduction_tab( i ).source_category ||
                           cv_dqu;
        --作成元明細ID
        lv_step := 'A-4.source_line_id';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_deduction_tab( i ).source_line_id ;
        --控除条件ID
        lv_step := 'A-4.condition_id';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_deduction_tab( i ).condition_id ;
        --控除番号
        lv_step := 'A-4.condition_no';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_deduction_tab( i ).condition_no ||
                           cv_dqu;
        --控除詳細ID
        lv_step := 'A-4.condition_line_id';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_deduction_tab( i ).condition_line_id ;
        --データ種類
        lv_step := 'A-4.data_type';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lv_data_type_name ||
                           cv_dqu;
        --控除種類
        lv_step := 'A-4.status';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_deduction_tab( i ).data_type ||
                           cv_dqu;
        --売上区分
        lv_step := 'A-4.sales_class';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lv_sales_class ||
                           cv_dqu;
        --納品形態区分
        lv_step := 'A-4.delivery_pattern_class';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lv_delivery_pattern_class ||
                           cv_dqu;
        --変動対価区分
        lv_step := 'A-4.fluctuation_value_class';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lv_fluctuation_value_class ||
                           cv_dqu;
        --ステータス
        lv_step := 'A-4.status';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_deduction_tab( i ).status ||
                           cv_dqu;
        --品目コード
        lv_step := 'A-4.item_code';
        IF (lt_csv_deduction_tab( i ).item_code is NULL ) THEN
          IF (lt_csv_deduction_tab( i ).source_category = cv_source_category_f) THEN
            lv_item_code := gv_item_code_dummy_f;
          ELSIF (lt_csv_deduction_tab( i ).source_category = cv_source_category_u) THEN
            lv_item_code := gv_item_code_dummy_u;
          ELSIF (lt_csv_deduction_tab( i ).source_category = cv_source_category_o) THEN
            lv_item_code := gv_item_code_dummy_o;
          ELSE
            lv_item_code := lt_csv_deduction_tab( i ).item_code;
          END IF;
        ELSE
          lv_item_code := lt_csv_deduction_tab( i ).item_code;
        END IF;
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lv_item_code ||
                           cv_dqu;
        --販売単位
        lv_step := 'A-4.sales_uom_code';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_deduction_tab( i ).sales_uom_code ||
                           cv_dqu;
        --販売単価
        lv_step := 'A-4.sales_unit_price';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_deduction_tab( i ).sales_unit_price ;
        --販売数量
        lv_step := 'A-4.sales_quantity';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_deduction_tab( i ).sales_quantity ;
        --売上本体金額
        lv_step := 'A-4.sale_pure_amount';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_deduction_tab( i ).sale_pure_amount ;
        --売上消費税額
        lv_step := 'A-4.sale_tax_amount';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_deduction_tab( i ).sale_tax_amount ;
        --控除単位
        lv_step := 'A-4.deduction_uom_code';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_deduction_tab( i ).deduction_uom_code ||
                           cv_dqu;
        --控除単価
        lv_step := 'A-4.deduction_unit_price';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_deduction_tab( i ).deduction_unit_price ;
        --控除数量
        lv_step := 'A-4.deduction_quantity';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_deduction_tab( i ).deduction_quantity ;
        --控除額
        lv_step := 'A-4.deduction_amount';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_deduction_tab( i ).deduction_amount ;
        --補填
        lv_step := 'A-4.compensation';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_deduction_tab( i ).compensation ;
        --問屋マージン
        lv_step := 'A-4.margin';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_deduction_tab( i ).margin ;
        --拡売
        lv_step := 'A-4.sales_promotion_expenses';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_deduction_tab( i ).sales_promotion_expenses ;
        --問屋マージン減額
        lv_step := 'A-4.margin_reduction';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_deduction_tab( i ).margin_reduction ;
        --税コード
        lv_step := 'A-4.tax_code';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_deduction_tab( i ).tax_code ||
                           cv_dqu;
        --税率
        lv_step := 'A-4.tax_rate';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_deduction_tab( i ).tax_rate ;
        --消込時税コード
        lv_step := 'A-4.recon_tax_code';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_deduction_tab( i ).recon_tax_code ||
                           cv_dqu;
        --消込時税率
        lv_step := 'A-4.recon_tax_rate';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_deduction_tab( i ).recon_tax_rate ;
        --控除税額
        lv_step := 'A-4.deduction_tax_amount';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_deduction_tab( i ).deduction_tax_amount ;
        --申請書No.
        lv_step := 'A-4.application_no';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_deduction_tab( i ).application_no ||
                           cv_dqu;
        --速報確定フラグ
        lv_step := 'A-4.report_decision_flag';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_deduction_tab( i ).report_decision_flag ||
                           cv_dqu;
        --リカバリデータ削除時日付【YYYYMMDD】
        lv_step := 'A-4.recovery_del_date';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_deduction_tab( i ).recovery_del_date ;
        --作成者
        lv_step := 'A-4.create_user_name';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_deduction_tab( i ).create_user_name ||
                           cv_dqu;
        --作成日【YYYYMMDD】
        lv_step := 'A-4.creation_date';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_deduction_tab( i ).creation_date ;
        -- 最終更新者
        lv_step := 'A-4.last_updated_user_name';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_deduction_tab( i ).last_updated_user_name ||
                           cv_dqu;
        --最終更新日【YYYYMMDD】
        lv_step := 'A-4.last_update_date';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_deduction_tab( i ).last_update_date;
        -- 連携日時【YYYYMMDDHH24MISS】
        lv_step := 'A-4.gv_trans_date';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           gv_trans_date;
--
        --=================
        -- CSVファイル出力
        --=================
        lv_step := 'A-4.1c';
        BEGIN
          UTL_FILE.PUT_LINE( lf_file_hand, lv_out_csv_line );
        EXCEPTION
          WHEN OTHERS THEN
            lv_sqlerrm := SQLERRM;
            RAISE file_output_expt;
        END;
--
        -- 成功件数
        gn_normal_cnt := gn_normal_cnt + 1;
        --
      END LOOP out_csv_loop;
--
      -- ============================================================
      -- 販売控除管理情報更新の呼び出し
      -- ============================================================
      upd_control_p(
        ov_errbuf   =>  lv_errbuf                             -- エラー・メッセージ
      , ov_retcode  =>  lv_retcode                            -- リターン・コード
      , ov_errmsg   =>  lv_errmsg                             -- ユーザー・エラー・メッセージ
      );
      IF  lv_retcode  = cv_status_error THEN
        RAISE global_process_expt;
      END IF;
--
      COMMIT;
--
      -----------------------------------------------
      -- A-6.終了処理
      -----------------------------------------------
      -- ファイルクローズ
      lv_step := 'A-6.1';
--
      --ファイルクローズ失敗
      BEGIN
        UTL_FILE.FCLOSE( lf_file_hand );
      EXCEPTION
        WHEN OTHERS THEN
          lv_sqlerrm := SQLERRM;
          RAISE file_close_expt;
      END;
--
--
  EXCEPTION
    -- *** 任意で例外処理を記述する ****
    -- *** サブプログラム例外ハンドラ ****
    WHEN subproc_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
    --*** ファイルオープンエラー ***
    WHEN file_open_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok             -- アプリケーション短縮名：XXCMM マスタ
                     ,iv_name         => cv_msg_xxcok_10787             -- メッセージ：APP-XXCOK1-10787 ファイルオープンエラー
                     ,iv_token_name1  => cv_tkn_sqlerrm                 -- トークン：SQLERRM
                     ,iv_token_value1 => lv_sqlerrm                     -- 値：SQLERRM
                     );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg;
      ov_retcode := cv_status_error;
    --*** ファイル書き込みエラー ***
    WHEN file_output_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok             -- アプリケーション短縮名：XXCMM マスタ
                     ,iv_name         => cv_msg_xxcok_10788             -- メッセージ：APP-XXCOK1-10788 ファイルオープンエラー
                     ,iv_token_name1  => cv_tkn_sqlerrm                 -- トークン：SQLERRM
                     ,iv_token_value1 => lv_sqlerrm                     -- 値：SQLERRM
                     );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg;
      ov_retcode := cv_status_error;
    --*** ファイルクローズエラー ***
    WHEN file_close_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok             -- アプリケーション短縮名：XXCMM マスタ
                     ,iv_name         => cv_msg_xxcok_10789             -- メッセージ：APP-XXCOK1-10789 ファイルクローズエラー
                     ,iv_token_name1  => cv_tkn_sqlerrm                 -- トークン：SQLERRM
                     ,iv_token_value1 => lv_sqlerrm                     -- 値：SQLERRM
                     );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- エラー件数出力
      gn_error_cnt := gn_target_cnt;
      ov_errbuf    := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      ov_retcode   := cv_status_error;
--
--####################################  固定部 END   ###################s#######################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
  --
  PROCEDURE main(
    errbuf         OUT    VARCHAR2         --   エラーメッセージ #固定#
   ,retcode        OUT    VARCHAR2         --   エラーコード     #固定#
  )
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'main';               -- プログラム名
    cv_log                    CONSTANT VARCHAR2(100) := 'LOG';                -- ログ
    cv_output                 CONSTANT VARCHAR2(100) := 'OUTPUT';             -- アウトプット
    cv_app_name_xxccp         CONSTANT VARCHAR2(100) := 'XXCCP';              -- アプリケーション短縮名
    cv_target_cnt_msg         CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';   -- 対象件数メッセージ
    cv_success_cnt_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';   -- 成功件数メッセージ
    cv_error_cnt_msg          CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';   -- エラー件数メッセージ
    cv_normal_msg             CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';   -- 正常終了メッセージ
    cv_warn_msg               CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005';   -- 警告終了メッセージ
    cv_error_msg              CONSTANT VARCHAR2(100) := 'APP-XXCCP1-10008';   -- エラー終了メッセージ
    cv_token_name1            CONSTANT VARCHAR2(100) := 'COUNT';              -- 処理件数
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf                 VARCHAR2(5000);                                 -- エラー・メッセージ
    lv_retcode                VARCHAR2(1);                                    -- リターン・コード
    lv_errmsg                 VARCHAR2(5000);                                 -- ユーザー・エラー・メッセージ
    lv_step                   VARCHAR2(10);                                   -- ステップ
    lv_message_code           VARCHAR2(100);                                  -- メッセージコード
--
--
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_output
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       ov_errbuf      => lv_errbuf       -- エラー・メッセージ           --# 固定 #
      ,ov_retcode     => lv_retcode      -- リターン・コード             --# 固定 #
      ,ov_errmsg      => lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      --エラー出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザーエラーメッセージ
      );
--
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_target_cnt_msg
                    ,iv_token_name1  => cv_token_name1
                    ,iv_token_value1 => TO_CHAR( gn_target_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_success_cnt_msg
                    ,iv_token_name1  => cv_token_name1
                    ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_error_cnt_msg
                    ,iv_token_name1  => cv_token_name1
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --終了メッセージ
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCOK024A37C;
/
