CREATE OR REPLACE PACKAGE BODY APPS.XXCFO008A05C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 *
 * Package Name     : XXCFO008A05C (body)
 * Description      : ERP Cloudより勘定科目：仮払金(釣銭)のGL仕訳を連携し、EBSのアドオンテーブルを更新する。
 * MD.050           : T_MD050_CFO_008_A05_仮払金(釣銭)IF_仕訳取込_EBSコンカレント
 * Version          : 1.1
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  csv_data_load          CSVデータ取込処理(A-2)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2022-11-15    1.0   Y.Fuku           新規作成
 *  2023-02-10    1.1   F.Hasebe         改修内容反映
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
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- エラー件数
  gn_warn_cnt      NUMBER;                    -- スキップ件数
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
  PRAGMA EXCEPTION_INIT( global_api_others_expt , -20000 );
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  global_dir_get_expt       EXCEPTION;                                     -- ディレクトリフルパス取得エラー
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCFO008A05C';               -- パッケージ名 
--
  --アプリケーション短縮名
  cv_msg_kbn_cff            CONSTANT VARCHAR2(5)   := 'XXCFF';
  cv_msg_kbn_cfo            CONSTANT VARCHAR2(5)   := 'XXCFO';
  cv_msg_kbn_ccp            CONSTANT VARCHAR2(5)   := 'XXCCP';
  cv_msg_kbn_coi            CONSTANT VARCHAR2(5)   := 'XXCOI';
-- Ver 1.1 Add Start
  cv_date_fmt               CONSTANT VARCHAR2(10)  := 'YYYYMMDD';
-- Ver 1.1 Add End
  --
  cv_slash                  CONSTANT VARCHAR2(1)   := '/';
  --
  cn_max_linesize           CONSTANT BINARY_INTEGER := 32767;              -- ファイルサイズ
  cv_open_mode_r            CONSTANT VARCHAR2(1)    := 'R';                -- 読み込みモード
  cv_delim_comma            CONSTANT VARCHAR2(1)    := ',';                -- カンマ
  --プロファイル
  -- XXCFO:OIC連携データファイル取込ディレクトリ名
  cv_oic_in_file_dir        CONSTANT VARCHAR2(100) := 'XXCFO1_OIC_IN_FILE_DIR';
  -- XXCFO:ERP_仕訳明細_仮払金(釣銭)連携データファイル名（OIC連携）
  cv_data_filename          CONSTANT VARCHAR2(100) := 'XXCFO1_OIC_GL_JE_L_ERP_IN_FILE';
  --メッセージ
  cv_msg_cfo_00001          CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00001';   -- プロファイル名取得エラーメッセージ
  cv_msg_coi_00029          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00029';   -- ディレクトリフルパス取得エラーメッセージ
  cv_msg_cfo_00029          CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00029';   -- ファイルオープンエラーメッセージ
  cv_msg_cfo_00024          CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00024';   -- 登録エラーメッセージ
-- Ver 1.1 Add Start
  cv_msg_cfo_00020          CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00020';   -- 更新エラーメッセージ
  cv_msg_cfo_60030          CONSTANT VARCHAR2(20) := 'APP-XXCFO1-60030';   -- CSV更新件数メッセージ
  cv_msg_cfo_60031          CONSTANT VARCHAR2(20) := 'APP-XXCFO1-60031';   -- CSV登録件数メッセージ
-- Ver 1.1 Add End
  cv_msg_cfo_60002          CONSTANT VARCHAR2(20) := 'APP-XXCFO1-60002';   -- ファイル名出力メッセージ
  --トークンコード
  cv_tkn_prof_name          CONSTANT VARCHAR2(20)  := 'PROF_NAME';         -- プロファイル名
  cv_tkn_dir_tok            CONSTANT VARCHAR2(20)  := 'DIR_TOK';           -- ディレクトリ名
  cv_tkn_file_name          CONSTANT VARCHAR2(20)  := 'FILE_NAME';         -- ファイル名
  cv_tkn_table              CONSTANT VARCHAR2(20)  := 'TABLE';             -- テーブル名
  cv_tkn_errmsg             CONSTANT VARCHAR2(20)  := 'ERRMSG';            -- SQLエラーメッセージ
  cv_tkn_sqlerrm            CONSTANT VARCHAR2(30)  := 'SQLERRM';           -- トークン名(SQLERRM)
-- Ver 1.1 Add Start
  cv_tkn_count              CONSTANT VARCHAR2(30)  := 'COUNT';             -- トークン名(COUNT)
-- Ver 1.1 Add End
  --メッセージ出力用文字列(トークン)
  cv_msgtkn_cfo_60024       CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-60024';  -- 'GL仕訳明細_ERP
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- XXCFO:OIC連携データファイル取込ディレクトリ名
  gv_dir_name      VARCHAR2(1000);
  -- XXCFO:ERP_仕訳明細_仮払金(釣銭)連携データファイル名（OIC連携）
  gv_if_file_name  VARCHAR2(1000);
  gt_directory_path all_directories.directory_path%TYPE;       -- ディレクトリパス
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2 ,    --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2 ,    --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- プログラム名
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
    lv_full_name      VARCHAR2(200)   DEFAULT NULL;                     -- ディレクトリパス＋ファイル名連結値
    lv_msg            VARCHAR2(300)   DEFAULT NULL;                     -- メッセージ出力用
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ==============================================================
    -- 1.プロファイルの取得
    -- ==============================================================
    -- OIC連携データファイル取込ディレクトリ名
    gv_dir_name := FND_PROFILE.VALUE( cv_oic_in_file_dir );
--
    IF ( gv_dir_name IS NULL ) THEN
      lv_errmsg :=  SUBSTRB( xxccp_common_pkg.get_msg
                              (
                                 cv_msg_kbn_cfo        -- XXCFO
                               , cv_msg_cfo_00001      -- プロファイル名取得エラーメッセージ
                               , cv_tkn_prof_name      -- トークン名：プロファイル名
                               , cv_oic_in_file_dir    -- トークン値：XXCFO1_OIC_IN_FILE_DIR
                              )
                            , 1
                            , 5000
                           );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ERP_仕訳明細_仮払金(釣銭)連携データファイル名
    gv_if_file_name := FND_PROFILE.VALUE( cv_data_filename );
--
    IF ( gv_if_file_name IS NULL ) THEN
      lv_errmsg :=  SUBSTRB( xxccp_common_pkg.get_msg
                              (
                                 cv_msg_kbn_cfo        -- XXCFO
                               , cv_msg_cfo_00001      -- プロファイル名取得エラーメッセージ
                               , cv_tkn_prof_name      -- トークン名：プロファイル名
                               , cv_data_filename      -- トークン値：XXCFO1_OIC_GL_JE_L_ERP_IN_FILE
                              )
                            , 1
                            , 5000
                           );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ==============================================================
    -- 2.プロファイル値「XXCFO:OIC連携データファイル取込ディレクトリ名」からディレクトリパスを取得する。
    -- ==============================================================
    BEGIN
      SELECT 
        RTRIM( ad.directory_path , cv_slash ) AS directory_path
      INTO 
        gt_directory_path
      FROM 
        all_directories ad
      WHERE 
        ad.directory_name = gv_dir_name
      ;
      -- レコードは存在するがディレクトリパスがnullの場合、エラー
      IF ( gt_directory_path IS NULL ) THEN
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg
                              (
                                 cv_msg_kbn_coi          -- XXCOI
                               , cv_msg_coi_00029        -- ディレクトリフルパス取得エラーメッセージ
                               , cv_tkn_dir_tok          -- トークン名：ディレクトリ名
                               , gv_dir_name             -- トークン値：gv_dir_name
                              )
                             , 1
                             , 5000
                            );
        lv_errbuf := lv_errmsg;
        RAISE global_dir_get_expt;
      END IF;
    -- レコードが取得できない場合、エラー
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg
                              (
                                 cv_msg_kbn_coi          -- XXCOI
                               , cv_msg_coi_00029        -- ディレクトリフルパス取得エラーメッセージ
                               , cv_tkn_dir_tok          -- トークン名：ディレクトリ名
                               , gv_dir_name             -- トークン値：gv_dir_name
                              )
                             , 1
                             , 5000
                            );
        lv_errbuf := lv_errmsg;
        RAISE global_dir_get_expt;
    END;

--
    -- ==============================================================
    -- 3.ファイル名をディレクトリパス付きで出力する。
    -- ==============================================================
    lv_full_name := gt_directory_path || cv_slash || gv_if_file_name;
    --
    lv_msg := xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo   -- 'XXCFO'
                                       , cv_msg_cfo_60002 -- ファイル名出力メッセージ
                                       , cv_tkn_file_name -- 'FILE_NAME'
                                       , lv_full_name     -- ディレクトリパスとファイル名の連結文字
                                      );
    -- メッセージ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msg
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
  EXCEPTION
    WHEN global_dir_get_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf , 1 , 5000 );
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf , 1 , 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf , 1 , 5000 );
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
   * Procedure Name   : csv_data_load
   * Description      : OICから連携されたCSVファイルの取り込み処理として処理を行う。(A-2)
   ***********************************************************************************/
  PROCEDURE csv_data_load(
    ov_errbuf     OUT VARCHAR2 ,    --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2 ,    --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'csv_data_load'; -- プログラム名
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
    lv_csv_buf       VARCHAR2(32767);       -- CSVファイルバッファ
-- Ver 1.1 Add Start
    ln_get_count     NUMBER;                -- 抽出件数
-- Ver 1.1 Add End
    ln_cnt_insert    NUMBER;                -- insert件数
-- Ver 1.1 Add Start
    ln_cnt_update    NUMBER;                -- update件数
-- Ver 1.1 Add End
    lf_file_handle   UTL_FILE.FILE_TYPE;    -- CSVファイルバッファ
    TYPE lt_tbl_type_textlist IS TABLE OF VARCHAR2(100) NOT NULL;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 変数の初期化
    ln_cnt_insert  := 0;
-- Ver 1.1 Add Start
    ln_cnt_update  := 0;
    ln_get_count   := 0;
-- Ver 1.1 Add End
    ----------------
    -- ファイル取込
    ----------------
    -- 1．ファイルのオープンを行う。
    BEGIN
      lf_file_handle := UTL_FILE.FOPEN( gt_directory_path , gv_if_file_name , cv_open_mode_r , cn_max_linesize );
    EXCEPTION
      -- ファイルオープンエラー 
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                                                         cv_msg_kbn_cfo      -- XXCFO
                                                       , cv_msg_cfo_00029    -- ファイルオープンエラーメッセージ
                                                      )
                              , 1
                              , 5000
                             );
        lv_errbuf := lv_errmsg;
        --例外表示は、上位モジュールで行う。
        RAISE global_process_expt;
    END;
    -- ファイルのレコード分ループ
    <<file_recode_loop>>
    LOOP
      BEGIN
        UTL_FILE.GET_LINE( lf_file_handle , lv_csv_buf );
        --行数カウントアップ
        gn_target_cnt := gn_target_cnt + 1;
-- Ver 1.1 Add Start
        --
        -- GL仕訳明細_ERPテーブルに既にデータが登録済みか確認
        SELECT COUNT(1)
        INTO   ln_get_count
        FROM   XXCFO_GL_JE_LINES_ERP xgjle
        WHERE  xgjle.je_header_id  =  NVL( TO_NUMBER( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 1 ) ) , NULL )
        AND    xgjle.je_line_num   =  NVL( TO_NUMBER( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 2 ) ) , NULL );
        --
        IF (ln_get_count = 0) THEN
        -- 登録
-- Ver 1.1 Add END
        -- 2．「GL仕訳明細_ERP」テーブルの登録処理を行う。
          BEGIN
            INSERT INTO XXCFO_GL_JE_LINES_ERP(
                je_header_id
              , je_line_num
              , set_of_books_name
              , period_name
              , je_source
              , je_category
              , effective_date
              , entered_dr
              , entered_cr
              , accounted_dr
              , accounted_cr
              , segment1
              , segment2
              , segment3
              , segment4
              , segment5
              , segment6
              , segment7
              , segment8
              , payment_status_flag
              , check_date
              , cancelled_date
              --WHOカラム
              , created_by
              , creation_date
              , last_updated_by
              , last_update_date
              , last_update_login
              , request_id
              , program_application_id
              , program_id
              , program_update_date
            ) VALUES (
                NVL( TO_NUMBER( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 1 ) ) , NULL )
              , NVL( TO_NUMBER( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 2 ) ) , NULL )
              , NVL( TO_CHAR( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 3 ) ) , NULL )
              , NVL( TO_CHAR( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 4 ) ) , NULL )
              , NVL( TO_CHAR( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 5 ) ) , NULL )
              , NVL( TO_CHAR( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 6 ) ) , NULL )
              , NVL( TO_DATE( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 7 ) , 
-- Ver 1.1 Mod Start
--                'YYYY-MM-DD' ) , NULL )
                cv_date_fmt ) , NULL )
-- Ver 1.1 Mod End
              , NVL( TO_NUMBER( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 8 ) ) , NULL )
              , NVL( TO_NUMBER( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 9 ) ) , NULL )
              , NVL( TO_NUMBER( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 10 ) ) , NULL )
              , NVL( TO_NUMBER( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 11 ) ) , NULL )
              , NVL( TO_CHAR( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 12 ) ) , NULL )
              , NVL( TO_CHAR( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 13 ) ) , NULL )
              , NVL( TO_CHAR( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 14 ) ) , NULL )
              , NVL( TO_CHAR( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 15 ) ) , NULL )
              , NVL( TO_CHAR( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 16 ) ) , NULL )
              , NVL( TO_CHAR( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 17 ) ) , NULL )
              , NVL( TO_CHAR( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 18 ) ) , NULL )
              , NVL( TO_CHAR( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 19 ) ) , NULL )
              , NVL( TO_CHAR( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 20 ) ) , NULL )
              , NVL( TO_DATE( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 21 ) , 
-- Ver 1.1 Mod Start
--                'YYYY-MM-DD' ) , NULL )
                cv_date_fmt ) , NULL )
-- Ver 1.1 Mod End
              , NVL( TO_DATE( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 22 ) , 
-- Ver 1.1 Mod Start
--                'YYYY-MM-DD' ) , NULL )
                cv_date_fmt ) , NULL )
-- Ver 1.1 Mod End
              , cn_created_by
              , cd_creation_date
              , cn_last_updated_by
              , cd_last_update_date
              , cn_last_update_login
              , cn_request_id
              , cn_program_application_id
              , cn_program_id
              , cd_program_update_date
            );
          EXCEPTION
            WHEN OTHERS THEN
              --ファイルが開いていたら閉じる
              IF ( UTL_FILE.IS_OPEN( lf_file_handle ) ) THEN
                  UTL_FILE.FCLOSE( lf_file_handle );
              END IF;
              lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                                                               cv_msg_kbn_cfo       -- XXCFO
                                                             , cv_msg_cfo_00024     -- 登録エラーメッセージ
                                                             , cv_tkn_table         -- トークン名1：TABLE
                                                             , cv_msgtkn_cfo_60024  -- トークン値1：GL仕訳明細_ERP
                                                             , cv_tkn_errmsg        -- トークン名2：ERRMSG
                                                             , SQLERRM              -- トークン値2：SQLERRM
                                                            )
                                   , 1
                                   , 5000
                                  );
              lv_errbuf := lv_errmsg;
              --例外表示は、上位モジュールで行う。
              RAISE global_process_expt;
          END;
          ln_cnt_insert := ln_cnt_insert + 1;
-- Ver 1.1 Add Start
        ELSE
          -- 更新
          BEGIN
            UPDATE
              XXCFO_GL_JE_LINES_ERP xgjle
            SET
                xgjle.payment_status_flag    = NVL( TO_CHAR( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 20 ) ) , NULL )
              , xgjle.check_date             = NVL( TO_DATE( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 21 ) , 
-- Ver 1.1 Mod Start
--                                               'YYYY-MM-DD' ) , NULL )
                                               cv_date_fmt ) , NULL )
-- Ver 1.1 Mod End
              , xgjle.last_updated_by        = cn_last_updated_by
              , xgjle.last_update_date       = cd_last_update_date
              , xgjle.last_update_login      = cn_last_update_login
              , xgjle.request_id             = cn_request_id
              , xgjle.program_application_id = cn_program_application_id
              , xgjle.program_id             = cn_program_id
              , xgjle.program_update_date    = cd_program_update_date
            WHERE
                  xgjle.je_header_id  =  NVL( TO_NUMBER( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 1 ) ) , NULL )
              AND xgjle.je_line_num   =  NVL( TO_NUMBER( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 2 ) ) , NULL );
          EXCEPTION
            WHEN  OTHERS  THEN
              --ファイルが開いていたら閉じる
              IF ( UTL_FILE.IS_OPEN( lf_file_handle ) ) THEN
                  UTL_FILE.FCLOSE( lf_file_handle );
              END IF;
              lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                                                               cv_msg_kbn_cfo       -- XXCFO
                                                             , cv_msg_cfo_00020     -- 更新エラーメッセージ
                                                             , cv_tkn_table         -- トークン名1：TABLE
                                                             , cv_msgtkn_cfo_60024  -- トークン値1：GL仕訳明細_ERP
                                                             , cv_tkn_errmsg        -- トークン名2：ERRMSG
                                                             , SQLERRM              -- トークン値2：SQLERRM
                                                            )
                                   , 1
                                   , 5000
                                  );
              lv_errbuf := lv_errmsg;
              --例外表示は、上位モジュールで行う。
              RAISE global_process_expt;
          END;
          ln_cnt_update := ln_cnt_update + 1;
        END IF;
-- Ver 1.1 Add End
      EXCEPTION
        -- 次のレコードがない場合、ループ終了
        WHEN NO_DATA_FOUND THEN
          -- 3．CSVファイルを閉じる
          IF ( UTL_FILE.IS_OPEN( lf_file_handle ) ) THEN
              UTL_FILE.FCLOSE( lf_file_handle );
          END IF;
-- Ver 1.1 Mod Start
--          gn_normal_cnt := ln_cnt_insert;
          gn_normal_cnt := ln_cnt_insert + ln_cnt_update;
-- Ver 1.1 Mod End
          EXIT;
      END;
    END LOOP file_recode_loop;
-- Ver 1.1 Add Start
    -- メッセージ出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     cv_msg_kbn_cfo       -- XXCFO
                   , cv_msg_cfo_60031     -- CSV登録件数メッセージ
                   , cv_tkn_table         -- トークン名1：TABLE
                   , cv_msgtkn_cfo_60024  -- トークン値1：GL仕訳明細_ERP
                   , cv_tkn_count         -- トークン名2：COUNT
                   , ln_cnt_insert        -- トークン値2：CSVによる登録件数
                 );
    FND_FILE.PUT_LINE (
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --空行挿入
    FND_FILE.PUT_LINE (
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    gv_out_msg := xxccp_common_pkg.get_msg(
                     cv_msg_kbn_cfo       -- XXCFO
                   , cv_msg_cfo_60030     -- CSV更新件数メッセージ
                   , cv_tkn_table         -- トークン名1：TABLE
                   , cv_msgtkn_cfo_60024  -- トークン値1：GL仕訳明細_ERP
                   , cv_tkn_count         -- トークン名2：COUNT
                   , ln_cnt_update        -- トークン値2：CSVによる更新件数
                 );
    FND_FILE.PUT_LINE (
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --空行挿入
    FND_FILE.PUT_LINE (
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
-- Ver 1.1 Add End
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf , 1 , 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf , 1 , 5000 );
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
  END csv_data_load;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2 ,    --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2 ,    --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2 )    --   ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
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
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
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
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- <A-1．初期処理>
    -- ===============================
    init(
      lv_errbuf ,         -- エラー・メッセージ           --# 固定 #
      lv_retcode ,        -- リターン・コード             --# 固定 #
      lv_errmsg );        -- ユーザー・エラー・メッセージ --# 固定 #
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- <A-2．CSVデータ取込処理>
    -- ===============================
    csv_data_load(
      lv_errbuf ,         -- エラー・メッセージ           --# 固定 #
      lv_retcode ,        -- リターン・コード             --# 固定 #
      lv_errmsg );        -- ユーザー・エラー・メッセージ --# 固定 #
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf , 1 , 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf , 1 , 5000 );
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
--####################################  固定部 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT VARCHAR2 ,     --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2       --   リターン・コード    --# 固定 #
  )
--
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
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
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
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
        ov_retcode => lv_retcode
      , ov_errbuf  => lv_errbuf
      , ov_errmsg  => lv_errmsg
    );
    --
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
        lv_errbuf   -- エラー・メッセージ           --# 固定 #
      , lv_retcode  -- リターン・コード             --# 固定 #
      , lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF ( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := 0;
      gn_error_cnt := 1;
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_target_cnt )
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_normal_cnt )
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
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
                      iv_application  => cv_appl_short_name
                    , iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
--###########################  固定部 START   #####################################################
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
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
END XXCFO008A05C;
/
