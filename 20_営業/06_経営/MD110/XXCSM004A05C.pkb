CREATE OR REPLACE PACKAGE BODY XXCSM004A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM004A05C(body)
 * Description      : 資格ポイント・新規獲得ポイント情報系システムI/F
 * MD.050           : 資格ポイント・新規獲得ポイント情報系システムI/F MD050_CSM_004_A05
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                                  初期処理(A-1)
 *  open_csv_file                         ファイルオープン処理(A-2)
 *  create_csv_rec                        資格ポイント・新規獲得ポイントデータ書込処理(A-4)
 *  close_csv_file                        資格ポイント・新規獲得ポイントI/Fファイルクローズ処理(A-5)
 *  submain                               メイン処理プロシージャ
 *  main                                  コンカレント実行ファイル登録プロシージャ
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/05    1.0   S.Son            新規作成
 *  2009/07/01    1.1   T.Tsukino        ［SCS障害管理番号0000256］対応
 *  2009/12/22    1.2   T.Nakano         E_本番稼動_00589 対応
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
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;                 --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                            --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                 --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                            --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;         --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;            --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;         --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                            --PROGRAM_UPDATE_DATE
  --
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
  cv_msg_comma              CONSTANT VARCHAR2(1) := ',';
  cv_msg_wquot              CONSTANT VARCHAR2(1) := '"';
  --
  cv_xxcsm                  CONSTANT VARCHAR2(100) := 'XXCSM'; 
--//+ADD START 2009/07/01 0000256 T.Tsukino
  cv_xxccp                  CONSTANT VARCHAR2(5)   := 'XXCCP';           -- 共通関数アプリケーションID
--//+ADD START 2009/07/01 0000256 T.Tsukino
  --メッセージーコード
  cv_msg_00111              CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00111';       --想定外エラーメッセージ
  cv_msg_90008              CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008';       --入力パラメータ無しメッセージ
  cv_msg_00084              CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00084';       --インターフェースファイル名メッセージ
  cv_chk_err_00031          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00031';       --定期実行用プロファイル取得エラーメッセージ
  cv_chk_err_00001          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00001';       --ファイル存在チェックエラーメッセージ
  cv_chk_err_00002          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00002';       --ファイルオープンエラーメッセージ
  cv_chk_err_00003          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00003';       --ファイルクローズエラーメッセージ
  cv_chk_err_00019          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00019';       --情報系システム連携対象無しエラーメッセージ
  --トークン
  cv_tkn_prof               CONSTANT VARCHAR2(100) := 'PROF_NAME';               --カスタム・プロファイル・オプションの英名
  cv_tkn_file               CONSTANT VARCHAR2(100) := 'FILE_NAME';               --ファイル名
  cv_tkn_dir                CONSTANT VARCHAR2(100) := 'DIRECTORY';               --ディレクトリ
  cv_tkn_sql_cd             CONSTANT VARCHAR2(100) := 'SQL_CODE';                --オラクルエラーコード
  --
  cv_app_short_name         CONSTANT VARCHAR2(2)   := 'AR';                      --アプリケーション短縮名
  cv_mode_w                 CONSTANT VARCHAR2(1)   := 'W';                       --書込
  cn_max_size               CONSTANT NUMBER        := 2047;                      -- 2047バイト
  cv_status_open            CONSTANT VARCHAR2(1)   := 'O';                       --ステータス(オープン)
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
  gn_seq_no        NUMBER;                    -- 出力順
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
  -- ユーザー定義例外
  -- ===============================
--
  file_err_expt          EXCEPTION;              --ファイルオープンエラー
  no_data_expt           EXCEPTION;              --情報系システム連携対象無しエラー
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                         CONSTANT VARCHAR2(100) := 'XXCSM004A05C';                 -- パッケージ名
  cv_file_dir_profile                 CONSTANT VARCHAR2(100) := 'XXCSM1_INFOSYS_FILE_DIR';      --情報系データファイル作成ディレクトリ
  cv_file_name_profile                CONSTANT VARCHAR2(100) := 'XXCSM1_POINT_FILE_NAME';       --資格ポイント・新規獲得ポイントデータファイル名
  cv_bks_id_profile                   CONSTANT VARCHAR2(100) := 'GL_SET_OF_BKS_ID';             --会計帳簿ID
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  gv_file_dir          VARCHAR2(100);            --情報系データファイル作成ディレクトリ
  gv_file_name         VARCHAR2(100);            --資格ポイント、新規獲得ポイントデータファイル名
  gv_bks_id            VARCHAR2(100);            --会計帳簿ID
  gv_app_id            VARCHAR2(100);            --アプリケーションID
  gf_file_hand         UTL_FILE.FILE_TYPE;
  gd_sysdate           DATE;                     --システム日付

--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf        OUT NOCOPY VARCHAR2,       -- エラー・メッセージ
    ov_retcode       OUT NOCOPY VARCHAR2,       -- リターン・コード
    ov_errmsg        OUT NOCOPY VARCHAR2)       -- ユーザー・エラー・メッセージ 
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'init';            -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf         VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode        VARCHAR2(1);     -- リターン・コード
    lv_errmsg         VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_tkn_value      VARCHAR2(4000);  --トークン値
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_no_pram_msg       VARCHAR2(100);         --入力パラメータ無しメッセージ
    file_chk             BOOLEAN;               --ファイル存在チェック結果
    file_size            NUMBER;                --ファイルサイズ
    block_size           NUMBER;                --ブロックサイズ
--
    -- *** ローカル・カーソル ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- *** ローカル変数初期化 ***

    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--①入力パラメータ無しをメッセージ出力
    --対象年度
    lv_no_pram_msg := xxccp_common_pkg.get_msg(
--//+UPD START 2009/07/01 0000256 T.Tsukino
--                                             iv_application  => cv_xxcsm
                                               iv_application  => cv_xxccp
--//+UPD START 2009/07/01 0000256 T.Tsukino
                                            ,iv_name         => cv_msg_90008
                                            );
    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_no_pram_msg);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_no_pram_msg);
    
--
--② プロファイル値取得
    --情報系データファイル作成ディレクトリ
    gv_file_dir := FND_PROFILE.VALUE(cv_file_dir_profile);
    
    IF gv_file_dir IS NULL THEN
        lv_tkn_value := cv_file_dir_profile;
        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_xxcsm
                                             ,iv_name         => cv_chk_err_00031
                                             ,iv_token_name1  => cv_tkn_prof
                                             ,iv_token_value1 => lv_tkn_value
                                             );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END IF;
--
    --資格ポイント、新規獲得ポイントデータファイル名
    gv_file_name := FND_PROFILE.VALUE(cv_file_name_profile);
    IF gv_file_name IS NULL THEN
        lv_tkn_value := cv_file_name_profile;
        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_xxcsm
                                             ,iv_name         => cv_chk_err_00031
                                             ,iv_token_name1  => cv_tkn_prof
                                             ,iv_token_value1 => lv_tkn_value
                                             );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    ELSE
      lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_xxcsm
                                             ,iv_name         => cv_msg_00084
                                             ,iv_token_name1  => cv_tkn_file
                                             ,iv_token_value1 => gv_file_name
                                             );
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
--
    --会計帳簿ID
    gv_bks_id := FND_PROFILE.VALUE(cv_bks_id_profile);
    IF gv_bks_id IS NULL THEN
        lv_tkn_value := cv_bks_id_profile;
        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_xxcsm
                                             ,iv_name         => cv_chk_err_00031
                                             ,iv_token_name1  => cv_tkn_prof
                                             ,iv_token_value1 => lv_tkn_value
                                             );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END IF;
--
--③ ファイル作成領域に同名のファイルが存在チャック
    UTL_FILE.FGETATTR(gv_file_dir, gv_file_name, file_chk, file_size, block_size);
    IF file_chk THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_xxcsm
                                             ,iv_name         => cv_chk_err_00001
                                             ,iv_token_name1  => cv_tkn_dir
                                             ,iv_token_value1 => gv_file_dir
                                             ,iv_token_name2  => cv_tkn_file
                                             ,iv_token_value2 => gv_file_name
                                             );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END IF;
--④ システム日付取得
    gd_sysdate := SYSDATE;
--
--⑤ アプリケーションIDを取得
    gv_app_id := xxccp_common_pkg.get_application(cv_app_short_name);
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
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
  /****************************************************************************
  * Procedure Name   : open_csv_file
  * Description      : ファイルオープン処理(A-2)
  ****************************************************************************/
  PROCEDURE open_csv_file (
       ov_errbuf     OUT NOCOPY VARCHAR2              -- 共通・エラー・メッセージ
      ,ov_retcode    OUT NOCOPY VARCHAR2              -- リターン・コード
      ,ov_errmsg     OUT NOCOPY VARCHAR2)             -- ユーザー・エラー・メッセージ
  IS

--#####################  固定ローカル変数宣言部 START   ###########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   #####################################
--
--  ===============================
--  固定ローカル定数
--  ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)   := 'open_csv_file'; -- プログラム名
--  ===============================
--  固定ローカル変数
--  ===============================
--
    lb_fopn_retcd     BOOLEAN;            --ファイルオープン確認戻り値格納
--  ===============================
--  ローカル・カーソル
--  ===============================
--
--##################  固定ステータス初期化部 START   ###################
  BEGIN
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
    BEGIN
      gf_file_hand := UTL_FILE.FOPEN(
                                   location     => gv_file_dir 
                                  ,filename     => gv_file_name 
                                  ,open_mode    => cv_mode_w 
                                  ,max_linesize => cn_max_size
                                  );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_xxcsm
                                             ,iv_name         => cv_chk_err_00002
                                             ,iv_token_name1  => cv_tkn_dir
                                             ,iv_token_value1 => gv_file_dir
                                             ,iv_token_name2  => cv_tkn_file
                                             ,iv_token_value2 => gv_file_name
                                             ,iv_token_name3  => cv_tkn_sql_cd
                                             ,iv_token_value3 => SQLERRM
                                             );
          lv_errbuf := lv_errmsg;
          RAISE file_err_expt;
    END;
--
  EXCEPTION
    -- *** ファイルオープンエラー ***
    WHEN file_err_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF lb_fopn_retcd  THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file => gf_file_hand
        );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--#################################  固定例外処理部  #############################

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
--#####################################  固定部 END   ###########################
--
  END open_csv_file;
--
  /****************************************************************************
  * Procedure Name   : create_csv_rec
  * Description      : 資格ポイント・新規獲得ポイントデータ抽出処理(A-3)
  *                    資格ポイント・新規獲得ポイントデータ書込処理(A-4)
  ****************************************************************************/
  PROCEDURE create_csv_rec (
       ov_errbuf       OUT NOCOPY VARCHAR2              -- 共通・エラー・メッセージ
      ,ov_retcode      OUT NOCOPY VARCHAR2              -- リターン・コード
      ,ov_errmsg       OUT NOCOPY VARCHAR2)             -- ユーザー・エラー・メッセージ
  IS
--#####################  固定ローカル変数宣言部 START   ###########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   #####################################
--
--  ===============================
--  固定ローカル定数
--  ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'create_csv_rec';   -- プログラム名
    cv_company_cd        CONSTANT VARCHAR2(3)     := '001';              -- 会社コード
--  ===============================
--  固定ローカル変数
--  ===============================
--
    ln_subject_year           NUMBER;                      --対象年度
    ln_year_month             NUMBER;                      --年月
    lv_location_cd            VARCHAR2(4);                 --拠点コード
    lv_employee_number        VARCHAR2(5);                 --従業員コード
    lv_data_kbn               VARCHAR2(1);                 --ポイント区分
    lv_get_intro_kbn          VARCHAR2(1);                 --獲得・紹介区
    lv_get_custom_date        VARCHAR2(8);                 --獲得年月日
    lv_account_number         VARCHAR2(9);                 --顧客コード
    lv_business_low_type      VARCHAR2(2);                 --業態
    lv_evaluration_kbn        VARCHAR2(1);                 --新規評価対象
    ln_point                  NUMBER;                      --ポイント
    lb_fopn_retcd             BOOLEAN;                     --ファイルオープン確認戻り値格納
    lv_data                   VARCHAR2(4000);
--  ===============================
--  ローカル・カーソル
--  ===============================
    CURSOR point_date_cur
    IS
      SELECT  xncph.employee_number                                                        --従業員コード
             ,xncph.subject_year                                                           --対象年度
             ,xncph.year_month                                                             --年月
             ,xncph.location_cd                                                            --拠点コード
             ,DECODE(xncph.data_kbn,1,xncph.account_number,'0') account_number           --顧客コード
             ,xncph.data_kbn                                                               --データ区分
             ,xncph.get_intro_kbn                                                          --獲得・紹介区分
             ,xncph.get_custom_date                                                        --顧客獲得日
             ,xncph.business_low_type                                                      --業態（小分類）
--//+UPD START 2009/12/22 E_本番稼動_00589 対応 T.Nakano
--              ,DECODE(xncph.data_kbn,1,xncph.evaluration_kbn,NULL) evaluration_kbn        --新規評価対象区分
             ,DECODE(xncph.data_kbn,1,xncph.evaluration_kbn,2,xncph.evaluration_kbn,NULL) evaluration_kbn        --新規評価対象区分
--//+UPD END 2009/12/22 E_本番稼動_00589 対応 T.Nakano
             ,xncph.point                                                                  --ポイント
      FROM    xxcsm_new_cust_point_hst   xncph                                             --新規獲得ポイント顧客別履歴テーブル
             ,(
               SELECT  DISTINCT gps.period_year  period_year            --会計年度
               FROM    gl_period_statuses  gps                          --会計期間ステータステーブル
               WHERE   gps.set_of_books_id = gv_bks_id                  --会計帳簿ID
               AND     gps.application_id = gv_app_id                   --アプリケーションID
               AND     gps.closing_status = cv_status_open              --ステータス
              ) status_view                                             --会計期間ステータスビュー
      WHERE   xncph.subject_year = status_view.period_year
      ORDER BY  xncph.data_kbn                                          --データ区分
               ,xncph.employee_number                                   --従業員コード
               ,xncph.year_month                                        --年月
      ;
    point_date_cur_rec point_date_cur%ROWTYPE;
--
--##################  固定ステータス初期化部 START   ###################
  BEGIN
--
    ov_retcode := cv_status_normal;
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
--###########################  固定部 END   ############################
    OPEN point_date_cur;
      <<point_date_loop>>
      LOOP
        FETCH point_date_cur INTO point_date_cur_rec;
      -- 処理対象件数格納
        gn_target_cnt := point_date_cur%ROWCOUNT;
        EXIT WHEN point_date_cur%NOTFOUND
             OR point_date_cur%ROWCOUNT = 0;
        -- 取得データを格納
        ln_subject_year       :=  point_date_cur_rec.subject_year;                           --対象年度
        ln_year_month         :=  point_date_cur_rec.year_month;                             --年月
        lv_location_cd        :=  point_date_cur_rec.location_cd;                            --拠点コード
        lv_employee_number    :=  point_date_cur_rec.employee_number;                        --従業員コード
        lv_data_kbn           :=  TO_CHAR(point_date_cur_rec.data_kbn);                      --ポイント区分
        lv_get_intro_kbn      :=  point_date_cur_rec.get_intro_kbn;                          --獲得・紹介区分
        lv_get_custom_date    :=  TO_CHAR(point_date_cur_rec.get_custom_date,'YYYYMMDD');    --獲得年月日
        lv_account_number     :=  point_date_cur_rec.account_number;                         --顧客コード
        lv_business_low_type  :=  point_date_cur_rec.business_low_type;                      --業態
        lv_evaluration_kbn    :=  point_date_cur_rec.evaluration_kbn;                        --新規評価対象区
        ln_point              :=  point_date_cur_rec.point;                                  --ポイント
        -- ========================================
        -- 資格ポイント・新規獲得ポイントデータ書込み処理(A-4)
        -- ========================================
        lv_data := cv_msg_wquot||cv_company_cd||cv_msg_wquot||cv_msg_comma||                --会社コード
                   ln_subject_year||cv_msg_comma||                                          --対象年度
                   ln_year_month||cv_msg_comma||                                            --年月
                   cv_msg_wquot||lv_location_cd||cv_msg_wquot||cv_msg_comma||               --拠点(部門)コード
                   cv_msg_wquot||lv_employee_number||cv_msg_wquot||cv_msg_comma||           --従業員コード
                   cv_msg_wquot||lv_data_kbn||cv_msg_wquot||cv_msg_comma||                  --ポイント区分
                   cv_msg_wquot||lv_get_intro_kbn||cv_msg_wquot||cv_msg_comma||             --獲得・紹介区分
                   lv_get_custom_date||cv_msg_comma||                                       --獲得年月日
                   cv_msg_wquot||lv_account_number||cv_msg_wquot||cv_msg_comma||            --顧客コード
                   cv_msg_wquot||lv_business_low_type||cv_msg_wquot||cv_msg_comma||         --業態
                   cv_msg_wquot||lv_evaluration_kbn||cv_msg_wquot||cv_msg_comma||           --新規評価対象区分
                   ln_point||cv_msg_comma||                                                 --ポイント
                   TO_CHAR(gd_sysdate,'YYYYMMDDHH24MISS');                                  --連携日時
        -- データ出力
        UTL_FILE.PUT_LINE(
                          file   => gf_file_hand
                         ,buffer => lv_data
                         );
        
        -- 正常件数カウントアップ
        gn_normal_cnt := gn_normal_cnt + 1;
      END LOOP point_date_loop;
    CLOSE point_date_cur;
    -- 処理対象件数が0件の場合
    IF (gn_target_cnt = 0) THEN
      -- エラーメッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcsm                                --アプリケーション短縮名
                    ,iv_name         => cv_chk_err_00019                        --メッセージコード
                   );
      lv_errbuf := lv_errmsg;
      RAISE no_data_expt;
    END IF;
--
  EXCEPTION
      -- *** 処理対象データ0件例外ハンドラ ***
    WHEN no_data_expt THEN
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF lb_fopn_retcd  THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      -- カーソルがクローズされていない場合
      IF (point_date_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE point_date_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--#################################  固定例外処理部  #############################

    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF lb_fopn_retcd  THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      -- カーソルがクローズされていない場合
      IF (point_date_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE point_date_cur;
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
      IF lb_fopn_retcd  THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      -- カーソルがクローズされていない場合
      IF (point_date_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE point_date_cur;
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
      IF lb_fopn_retcd  THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      -- カーソルがクローズされていない場合
      IF (point_date_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE point_date_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ###########################
--
  END create_csv_rec;
--
  /****************************************************************************
  * Procedure Name   : close_csv_file
  * Description      : ファイルクローズ処理(A-5)
  ****************************************************************************/
  PROCEDURE close_csv_file (
       ov_errbuf     OUT NOCOPY VARCHAR2              -- 共通・エラー・メッセージ
      ,ov_retcode    OUT NOCOPY VARCHAR2              -- リターン・コード
      ,ov_errmsg     OUT NOCOPY VARCHAR2)             -- ユーザー・エラー・メッセージ
  IS

--#####################  固定ローカル変数宣言部 START   ###########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   #####################################
--
--  ===============================
--  固定ローカル定数
--  ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)   := 'close_csv_file'; -- プログラム名
--  ===============================
--  固定ローカル変数
--  ===============================
--
    lb_fopn_retcd     BOOLEAN;            --ファイルオープン確認戻り値格納
--  ===============================
--  ローカル・カーソル
--  ===============================
--
--##################  固定ステータス初期化部 START   ###################
  BEGIN
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
    BEGIN
      UTL_FILE.FCLOSE(
        file => gf_file_hand
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_chk_err_00003
                                           ,iv_token_name1  => cv_tkn_dir
                                           ,iv_token_value1 => gv_file_dir
                                           ,iv_token_name2  => cv_tkn_file
                                           ,iv_token_value2 => gv_file_name
                                           ,iv_token_name3  => cv_tkn_sql_cd
                                           ,iv_token_value3 => SQLERRM
                                           );
        lv_errbuf := lv_errmsg;
        RAISE file_err_expt;
    END;
--
  EXCEPTION
    -- *** ファイルオープンエラー ***
    WHEN file_err_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF lb_fopn_retcd  THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file => gf_file_hand
        );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--#################################  固定例外処理部  #############################

    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF lb_fopn_retcd  THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file => gf_file_hand
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
      IF lb_fopn_retcd  THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file => gf_file_hand
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
      IF lb_fopn_retcd  THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file => gf_file_hand
        );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ###########################
--
  END close_csv_file;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf        OUT NOCOPY VARCHAR2,     --  エラー・メッセージ
    ov_retcode       OUT NOCOPY VARCHAR2,     --  リターン・コード
    ov_errmsg        OUT NOCOPY VARCHAR2)     --  ユーザー・エラー・メッセージ 
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'submain';          -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf                 VARCHAR2(5000);                   --エラー・メッセージ
    lv_retcode                VARCHAR2(1);                      --リターン・コード
    lv_errmsg                 VARCHAR2(5000);                   --ユーザー・エラー・メッセージ
--
--  ===============================
--  ローカル・カーソル
--  ===============================
--
--###########################  固定部 END   ####################################
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
    gn_target_cnt  := 0;
    gn_normal_cnt  := 0;
    gn_error_cnt   := 0;
    gn_warn_cnt    := 0;
    -- ローカル変数初期化
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    init(
          lv_errbuf         -- エラー・メッセージ
         ,lv_retcode        -- リターン・コード
         ,lv_errmsg );
    -- 例外処理
    IF (lv_retcode <> cv_status_normal) THEN
      --(エラー処理)
      gn_error_cnt := gn_error_cnt +1;
      RAISE global_process_expt;
    END IF;
    -- ===============================
    -- ファイルオープン処理(A-2)
    -- ===============================
    open_csv_file(
       ov_errbuf    => lv_errbuf                                                                    -- エラー・メッセージ
      ,ov_retcode   => lv_retcode                                                                   -- リターン・コード
      ,ov_errmsg    => lv_errmsg                                                                    -- ユーザー・エラー・メッセージ
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    -- =======================================================
    -- 資格ポイント・新規獲得ポイントデータ抽出処理(A-3)
    -- 資格ポイント・新規獲得ポイントデータ書込処理(A-4)
    -- =======================================================
    create_csv_rec(
       ov_errbuf    => lv_errbuf                                                                    -- エラー・メッセージ
      ,ov_retcode   => lv_retcode                                                                   -- リターン・コード
      ,ov_errmsg    => lv_errmsg                                                                    -- ユーザー・エラー・メッセージ
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==========================================================
    -- 資格ポイント・新規獲得ポイントI/Fファイルクローズ処理(A-5)
    -- ==========================================================
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
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN--
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
    errbuf                  OUT  NOCOPY VARCHAR2,     --   エラー・メッセージ
    retcode                 OUT  NOCOPY VARCHAR2      --   リターン・コード
  )
--
--###########################  固定部 START   ###########################
--
  IS
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

    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       lv_errbuf        -- エラー・メッセージ 
      ,lv_retcode       -- リターン・コード  
      ,lv_errmsg        -- ユーザー・エラー・メッセージ 
    );
--
    IF lv_retcode = cv_status_error THEN
      IF lv_errmsg IS NULL THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                                                 iv_application  => cv_xxcsm
                                                ,iv_name         => cv_msg_00111
                                               );
      END IF;
      
    --エラー出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff => lv_errbuf --エラーメッセージ
      );
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt := 1;
      gn_warn_cnt := 0;
    END IF;
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
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --終了メッセージ
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
END XXCSM004A05C;
/
