CREATE OR REPLACE PACKAGE BODY XXCOS003A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS003A05C(body)
 * Description      : 単価マスタIF出力（ファイル作成）
 * MD.050           : 単価マスタIF出力（ファイル作成） MD050_COS_003_A05
 * Version          : 1.4
 *
 * Program List     
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  proc_break_process     受注ヘッダ情報IDブレイク後の処理（ファイル出力、ステータス更新）
 *  proc_main_loop         ループ部 A-2データ抽出
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/05   1.0    K.Okaguchi       新規作成
 *  2009/01/17   1.1    K.Okaguchi       [障害COS_124] ファイル出力編集のバグを修正
 *  2009/02/24   1.2    T.Nakamura       [障害COS_130] メッセージ出力、ログ出力への出力内容の追加・修正
 *  2009/04/15   1.3    N.Maeda          [ST障害No.T1_0067対応] ファイル出力時のCHAR型VARCHAR型以外への｢"｣付加の削除
 *  2009/04/22   1.4    N.Maeda          [ST障害No.T1_0754対応]ファイル出力時の｢"｣付加修正
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
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER DEFAULT 0;                    -- 対象件数
  gn_normal_cnt    NUMBER DEFAULT 0;                    -- 正常件数
  gn_error_cnt     NUMBER DEFAULT 0;                    -- エラー件数
  gn_warn_cnt      NUMBER DEFAULT 0;                    -- スキップ件数
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
  global_data_check_expt    EXCEPTION;     -- データチェック時のエラー
  file_open_expt            EXCEPTION;     -- ファイルオープンエラー
  update_expt               EXCEPTION;     -- 更新エラー
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name             CONSTANT VARCHAR2(100):= 'XXCOS003A05C'; -- パッケージ名
  cv_application          CONSTANT VARCHAR2(5)  := 'XXCOS';        -- アプリケーション名
  cv_appl_short_name      CONSTANT VARCHAR2(10) := 'XXCCP';        -- アドオン：共通・IF領域
  cv_delimit              CONSTANT VARCHAR2(1)  := ',';            -- 区切り文字
  cv_quot                 CONSTANT VARCHAR2(1)  := '"';            -- コーテーション
  cv_tkn_table_name       CONSTANT VARCHAR2(20) := 'TABLE_NAME';
  cv_tkn_key_data         CONSTANT VARCHAR2(20) := 'KEY_DATA';
  cv_brank                CONSTANT VARCHAR2(1)  := ' ';
  cv_minus                CONSTANT VARCHAR2(1)  := '-';
  cv_flag_off             CONSTANT VARCHAR2(1)  := 'N';
  cv_tkn_lock             CONSTANT VARCHAR2(20) := 'TABLE';               -- ロックエラー
  cv_flag_on              CONSTANT VARCHAR2(1)  := 'Y';
  cv_tkn_filename         CONSTANT VARCHAR2(20) := 'FILE_NAME';
  cn_lock_error_code      CONSTANT NUMBER       := -54;
  cv_msg_lock             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00001';    --ロック取得エラー
  cv_msg_pro              CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00004';    --プロファイル取得エラー
  cv_msg_file_open        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00009';    --ファイルオープンエラーメッセージ
  cv_msg_update_err       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00011';    --データ更新エラーメッセージ
  cv_msg_filename         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00044';    --ファイル名（タイトル）
  cv_tkn_dir_path         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10662';    -- HHTアウトバウンド用ディレクトリパス
  cv_tkn_tm_filename      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10851';    -- 単価マスタファイル名
  cv_tkn_tm_w_tbl         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10852';    -- 単価マスタワークテーブル  
  cv_tkn_cust_code        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10853';    -- 顧客コード
  cv_tkn_item_code        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10854';    -- 品名コード
  cv_no_parameter         CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90008';    -- パラメータなし
  cv_prf_dir_path         CONSTANT VARCHAR2(50) := 'XXCOS1_OUTBOUND_HHT_DIR';      -- HHTアウトバウンド用ディレクトリパス
  cv_prf_tm_filename      CONSTANT VARCHAR2(50) := 'XXCOS1_UNIT_PRICE_M_FILE_NAME';-- 単価マスタファイル名
  cv_tkn_profile          CONSTANT VARCHAR2(20) := 'PROFILE';                -- プロファイル名
  cv_tkn_file_name        CONSTANT VARCHAR2(20) := 'FILE_NAME';              -- ファイル名
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_key_info                 fnd_new_messages.message_text%TYPE   ;--メッセージ出力用キー情報
  gv_msg_tkn_dir_path         fnd_new_messages.message_text%TYPE   ;--'HHTアウトバウンド用ディレクトリパス'
  gv_msg_tkn_tm_filename      fnd_new_messages.message_text%TYPE   ;--'単価マスタファイル名'☆
  gv_msg_tkn_tm_w_tbl         fnd_new_messages.message_text%TYPE   ;--'単価マスタワークテーブル'☆
  gv_msg_tkn_cust_code        fnd_new_messages.message_text%TYPE   ;--'顧客コード'☆
  gv_msg_tkn_item_code        fnd_new_messages.message_text%TYPE   ;--'品名コード'☆
  gv_tm_file_data             VARCHAR2(2000);
  gd_process_date             DATE;
--
--カーソル
  CURSOR main_cur
  IS
    SELECT 
           xupw.customer_number          customer_number            --顧客コード
         , xupw.item_code                item_code                  --品名コード
         , xupw.nml_prev_unit_price      nml_prev_unit_price        --通常　前回　単価　
         , xupw.nml_prev_dlv_date        nml_prev_dlv_date          --通常　前回　納品年月日　
         , xupw.nml_prev_qty             nml_prev_qty               --通常　前回　数量　
         , xupw.nml_bef_prev_dlv_date    nml_bef_prev_dlv_date      --通常　前々回　納品年月日　
         , xupw.nml_bef_prev_qty         nml_bef_prev_qty           --通常　前々回　数量　
         , xupw.sls_prev_unit_price      sls_prev_unit_price        --特売　前回　単価　
         , xupw.sls_prev_dlv_date        sls_prev_dlv_date          --特売　前回　納品年月日　
         , xupw.sls_prev_qty             sls_prev_qty               --特売　前回　数量　
         , xupw.sls_bef_prev_dlv_date    sls_bef_prev_dlv_date      --特売　前々回　納品年月日　
         , xupw.sls_bef_prev_qty         sls_bef_prev_qty           --特売　前々回　数量　
    FROM   xxcos_unit_price_mst_work     xupw                       --単価マスタワークテーブル
    WHERE 
          xupw.file_output_flag           =  cv_flag_off            --未出力
    ORDER BY 
          xupw.customer_number 
        , xupw.item_code
    FOR UPDATE NOWAIT
    ;
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  g_tm_handle       UTL_FILE.FILE_TYPE;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
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

    -- *** ローカル変数 ***
--
    lv_dir_path                 VARCHAR2(100);                -- HHTアウトバウンド用ディレクトリパス
    lv_tm_filename              VARCHAR2(100);                -- 単価マスタファイル名

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

-- 2009/02/24 T.Nakamura Ver.1.2 add start
    --空行
    FND_FILE.PUT_LINE(which  => FND_FILE.OUTPUT
                     ,buff   => ''
                     );
-- 2009/02/24 T.Nakamura Ver.1.2 add end
    --==============================================================
    -- 「コンカレント入力パラメータなし」メッセージを出力
    --==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(iv_application  => cv_appl_short_name
                                          ,iv_name         => cv_no_parameter
                                          );
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT
                     ,buff   => gv_out_msg
                     );
-- 2009/02/24 T.Nakamura Ver.1.2 add start
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.LOG
                     ,buff   => gv_out_msg
                     );
-- 2009/02/24 T.Nakamura Ver.1.2 add end
    --空行
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT
                     ,buff   => ''
                     );
-- 2009/02/24 T.Nakamura Ver.1.2 add start
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.LOG
                     ,buff   => ''
                     );
-- 2009/02/24 T.Nakamura Ver.1.2 add end
                     

    --==============================================================
    -- マルチバイトの固定値をメッセージより取得
    --==============================================================
    gv_msg_tkn_dir_path         := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_dir_path
                                                           );
    gv_msg_tkn_tm_filename      := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_tm_filename
                                                           );
    gv_msg_tkn_tm_w_tbl         := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_tm_w_tbl
                                                           );
    gv_msg_tkn_cust_code        := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_cust_code
                                                           );
    gv_msg_tkn_item_code        := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_item_code
                                                           );
--
    --==============================================================
    -- プロファイルの取得(XXCOS:HHTアウトバウンド用ディレクトリパス)
    --==============================================================
    lv_dir_path := FND_PROFILE.VALUE(cv_prf_dir_path);
    
--
    -- プロファイル取得エラーの場合
    IF (lv_dir_path IS NULL) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                          , cv_msg_pro
                                          , cv_tkn_profile
                                          , gv_msg_tkn_dir_path
                                           );

      RAISE global_api_others_expt;
    END IF;
--
    --==============================================================
    -- プロファイルの取得(XXCOS:単価マスタファイル名)
    --==============================================================
    lv_tm_filename := FND_PROFILE.VALUE(cv_prf_tm_filename);
--
    -- プロファイル取得エラーの場合
    IF (lv_tm_filename IS NULL) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                          , cv_msg_pro
                                          , cv_tkn_profile
                                          , gv_msg_tkn_tm_filename
                                           );

      RAISE global_api_others_expt;
    END IF;
--
    --==============================================================
    -- ファイル名のログ出力
    --==============================================================
    --単価マスタファイル名
    gv_out_msg := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                          ,iv_name         => cv_msg_filename
                                          ,iv_token_name1  => cv_tkn_filename
                                          ,iv_token_value1 => lv_tm_filename
                                          );
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT
                     ,buff   => gv_out_msg
                     );
                     
    --空行
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT
                     ,buff   => ''
                     );

    --==============================================================
    -- 単価マスタファイル　ファイルオープン
    --==============================================================
    BEGIN
      g_tm_handle := UTL_FILE.FOPEN(lv_dir_path
                                  , lv_tm_filename
                                  , 'w');
    EXCEPTION
      WHEN OTHERS THEN
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                            , cv_msg_file_open
                                            , cv_tkn_file_name
                                            , lv_tm_filename);
        RAISE file_open_expt;
    END;
    
    --==============================================================
    -- 業務日付取得より一年前を取得
    --==============================================================
    gd_process_date := ADD_MONTHS(xxccp_common_pkg2.get_process_date,-12);
--
  EXCEPTION
    WHEN file_open_expt THEN
      ov_errbuf := ov_errbuf || ov_errmsg;
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg;
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
   * Procedure Name   : proc_main_loop（ループ部）
   * Description      : A-2データ抽出
   ***********************************************************************************/
  PROCEDURE proc_main_loop(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_main_loop'; -- メインループ処理
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_message_code          VARCHAR2(20);
    lv_nml_prev_unit_price   VARCHAR2(7);--通常前回単価
    lv_nml_prev_qty_sign     VARCHAR2(1);--通常前回数量サイン
    lv_nml_prev_qty          VARCHAR2(5);--通常前回数量
    lv_nml_prev_dlv_date     VARCHAR2(8);--通常前回納品年月日
    lv_nml_bef_prev_qty_sign VARCHAR2(1);--通常前々回数量サイン
    lv_nml_bef_prev_qty      VARCHAR2(5);--通常前々回数量
    lv_nml_bef_prev_dlv_date VARCHAR2(8);--通常前々回納品年月日
    lv_sls_prev_unit_price   VARCHAR2(7);--特売前回単価
    lv_sls_prev_qty_sign     VARCHAR2(1);--特売前回数量サイン
    lv_sls_prev_qty          VARCHAR2(5);--特売前回数量
    lv_sls_prev_dlv_date     VARCHAR2(8);--特売前回納品年月日
    lv_sls_bef_prev_qty_sign VARCHAR2(1);--特売前々回数量サイン
    lv_sls_bef_prev_qty      VARCHAR2(5);--特売前々回数量
    lv_sls_bef_prev_dlv_date VARCHAR2(8);--特売前々回納品年月日
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
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
    <<main_loop>>
    FOR main_rec in main_cur LOOP
      -- ===============================
      -- A-3 単価マスタファイル出力
      -- ===============================
  --データ編集
     --通常　前回　数量サイン
      IF (main_rec.nml_prev_qty < 0) THEN
        lv_nml_prev_qty_sign := cv_minus;
        lv_nml_prev_qty      := TO_CHAR(main_rec.nml_prev_qty * -1);
      ELSE
        lv_nml_prev_qty_sign := cv_brank;
        lv_nml_prev_qty      := TO_CHAR(main_rec.nml_prev_qty);
      END IF;
     --通常　前々回　数量サイン
      IF (main_rec.nml_bef_prev_qty < 0) THEN
        lv_nml_bef_prev_qty_sign := cv_minus;
        lv_nml_bef_prev_qty      := TO_CHAR(main_rec.nml_bef_prev_qty * -1);
      ELSE
        lv_nml_bef_prev_qty_sign := cv_brank;
        lv_nml_bef_prev_qty      := TO_CHAR(main_rec.nml_bef_prev_qty);
      END IF;
     --特売　前回　数量サイン
      IF (main_rec.sls_prev_qty < 0) THEN
        lv_sls_prev_qty_sign := cv_minus;
        lv_sls_prev_qty      := TO_CHAR(main_rec.sls_prev_qty * -1);
      ELSE
        lv_sls_prev_qty_sign := cv_brank;        
        lv_sls_prev_qty      := TO_CHAR(main_rec.sls_prev_qty);
      END IF;
     --特売　前々回　数量サイン
      IF (main_rec.sls_bef_prev_qty < 0) THEN
        lv_sls_bef_prev_qty_sign := cv_minus;
        lv_sls_bef_prev_qty      := TO_CHAR(main_rec.sls_bef_prev_qty * -1);
      ELSE
        lv_sls_bef_prev_qty_sign := cv_brank;        
        lv_sls_bef_prev_qty      := TO_CHAR(main_rec.sls_bef_prev_qty);
      END IF;
     --通常　前回　納品年月日が処理日（バッチ日付）より一年を過ぎている場合は設定を行いません。
      IF gd_process_date > main_rec.nml_prev_dlv_date THEN
        lv_nml_prev_unit_price := NULL;--通常前回単価
        lv_nml_prev_qty_sign   := NULL;--通常前回数量サイン
        lv_nml_prev_qty        := NULL;--通常前回数量
        lv_nml_prev_dlv_date   := NULL;--通常前回納品年月日
      ELSE
        lv_nml_prev_unit_price := TO_CHAR(main_rec.nml_prev_unit_price); --通常前回単価
        lv_nml_prev_dlv_date   := TO_CHAR(main_rec.nml_prev_dlv_date ,'YYYYMMDD');   --通常前回納品年月日
    
      END IF;
     --通常　前々回　納品年月日が処理日（バッチ日付）より一年を過ぎている場合は設定を行いません。
      IF (gd_process_date > main_rec.nml_bef_prev_dlv_date) THEN
        lv_nml_bef_prev_qty_sign := NULL;--通常前々回数量サイン
        lv_nml_bef_prev_qty      := NULL;--通常前々回数量
        lv_nml_bef_prev_dlv_date := NULL;--通常前々回納品年月日
      ELSE
        lv_nml_bef_prev_dlv_date := TO_CHAR(main_rec.nml_bef_prev_dlv_date ,'YYYYMMDD') ;--通常前々回納品年月日
      END IF;

     --特売　前回　納品年月日が処理日（バッチ日付）より一年を過ぎている場合は設定を行いません。
      IF (gd_process_date > main_rec.sls_prev_dlv_date) THEN
        lv_sls_prev_unit_price := NULL;--特売前回単価
        lv_sls_prev_qty_sign   := NULL;--特売前回数量サイン
        lv_sls_prev_qty        := NULL;--特売前回数量
        lv_sls_prev_dlv_date   := NULL;--特売前回納品年月日
      ELSE
      
        lv_sls_prev_unit_price := TO_CHAR(main_rec.sls_prev_unit_price);--特売前回単価
        lv_sls_prev_dlv_date   := TO_CHAR(main_rec.sls_prev_dlv_date ,'YYYYMMDD');--特売前回納品年月日
      END IF;
     --特売　前々回　納品年月日が処理日（バッチ日付）より一年を過ぎている場合は設定を行いません。
      IF (gd_process_date > main_rec.sls_bef_prev_dlv_date) THEN
        lv_sls_bef_prev_qty_sign := NULL;--特売前々回数量サイン
        lv_sls_bef_prev_qty      := NULL;--特売前々回数量
        lv_sls_bef_prev_dlv_date := NULL;--特売前々回納品年月日
      ELSE
        lv_sls_bef_prev_dlv_date := TO_CHAR(main_rec.sls_bef_prev_dlv_date ,'YYYYMMDD');--特売前々回納品年月日
      END IF;

      IF lv_nml_prev_dlv_date     IS NULL AND
         lv_nml_bef_prev_dlv_date IS NULL AND
         lv_sls_prev_dlv_date     IS NULL AND
         lv_sls_bef_prev_dlv_date IS NULL 
      THEN
        NULL;
      ELSE
        gn_target_cnt := gn_target_cnt + 1;
        SELECT             cv_quot || main_rec.customer_number || cv_quot -- 顧客コード
          || cv_delimit || cv_quot || main_rec.item_code       || cv_quot -- 品名コード
          || cv_delimit || lv_nml_prev_unit_price                         -- 通常前回単価
          || cv_delimit || lv_nml_prev_dlv_date                           -- 通常前回納品年月日
          || cv_delimit || cv_quot || lv_nml_prev_qty_sign     || cv_quot -- 通常前回数量サイン
          || cv_delimit || lv_nml_prev_qty                                -- 通常前回数量
          || cv_delimit || lv_nml_bef_prev_dlv_date                       -- 通常前々回納品年月日
          || cv_delimit || cv_quot || lv_nml_bef_prev_qty_sign || cv_quot -- 通常前々回数量サイン
          || cv_delimit || lv_nml_bef_prev_qty                            -- 通常前々回数量
          || cv_delimit || lv_sls_prev_unit_price                         -- 特売前回単価
          || cv_delimit || lv_sls_prev_dlv_date                           -- 特売前回納品年月日
          || cv_delimit || cv_quot || lv_sls_prev_qty_sign     || cv_quot -- 特売前回数量サイン
          || cv_delimit || lv_sls_prev_qty                                -- 特売前回数量
          || cv_delimit || lv_sls_bef_prev_dlv_date                       -- 特売前々回納品年月日
          || cv_delimit || cv_quot || lv_sls_bef_prev_qty_sign || cv_quot -- 特売前々回数量サイン
          || cv_delimit || lv_sls_bef_prev_qty                            -- 特売前々回数量
          || cv_delimit                                                   -- 値引単価　前回
          || cv_delimit || cv_quot || TO_CHAR(SYSDATE , 'YYYY/MM/DD HH24:MI:SS') || cv_quot     -- 処理日時
        INTO gv_tm_file_data
        FROM DUAL
        ;
        UTL_FILE.PUT_LINE(g_tm_handle
                         ,gv_tm_file_data
                         );
        gn_normal_cnt := gn_normal_cnt + 1;
        
      -- ===============================
      -- A-4 単価マスタワークテーブルステータス更新
      -- ===============================
        BEGIN
          UPDATE xxcos_unit_price_mst_work
          SET    file_output_flag           = cv_flag_on
                ,last_updated_by            = cn_last_updated_by       
                ,last_update_date           = cd_last_update_date      
                ,last_update_login          = cn_last_update_login     
                ,request_id                 = cn_request_id            
                ,program_application_id     = cn_program_application_id
                ,program_id                 = cn_program_id            
                ,program_update_date        = cd_program_update_date   
          WHERE  CURRENT OF main_cur
          ;
        EXCEPTION
          WHEN OTHERS THEN
            ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
            xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                -- エラー・メッセージ
                                            ,ov_retcode     => lv_retcode               -- リターン・コード
                                            ,ov_errmsg      => lv_errmsg                --ユーザー・エラー・メッセージ
                                            ,ov_key_info    => gv_key_info              --キー情報
                                            ,iv_item_name1  => gv_msg_tkn_cust_code     --項目名称1
                                            ,iv_data_value1 => main_rec.customer_number --データの値1
                                            ,iv_item_name2  => gv_msg_tkn_item_code     --項目名称2
                                            ,iv_data_value2 => main_rec.item_code       --データの値2                                            
                                            );
            ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                                , cv_msg_update_err
                                                , cv_tkn_table_name
                                                , gv_msg_tkn_tm_w_tbl
                                                , cv_tkn_key_data
                                                , gv_key_info
                                                );
            ov_errbuf := ov_errbuf || CHR(10) || ov_errmsg;  
            RAISE update_expt;
        END;
      END IF;
    END LOOP main_loop;
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN update_expt THEN
      ov_retcode := cv_status_error;
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
      IF (SQLCODE = cn_lock_error_code) THEN
        ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                            , cv_msg_lock
                                            , cv_tkn_lock
                                            , gv_msg_tkn_tm_w_tbl
                                             );
      END IF;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_main_loop;

--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- <カーソル名>
--
    -- <カーソル名>レコード型
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
    -- ===============================
    -- Loop1 メイン　A-2データ抽出
    -- ===============================

    proc_main_loop(
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );

    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    ELSE
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ###################################
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
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
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
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- コンカレントヘッダメッセージ出力先：出力
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- コンカレントヘッダメッセージ出力先：ログ(帳票のみ)

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
       iv_which   => cv_log_header_out    
      ,ov_retcode => lv_retcode
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
    -- A-1．初期処理
    -- ===============================================
    init(
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_normal) THEN
      -- ===============================================
      -- submainの呼び出し（実際の処理はsubmainで行う）
      -- ===============================================
      submain(
         lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,lv_retcode  -- リターン・コード             --# 固定 #
        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_error) THEN
        gn_error_cnt := gn_error_cnt + 1;
      END IF;
       --ファイルのクローズ
      UTL_FILE.FCLOSE(g_tm_handle);
    END IF;

--
    -- ===============================================
    -- A-5．終了処理
    -- ===============================================
    --エラー出力
    IF (lv_retcode != cv_status_normal) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
-- 2009/02/24 T.Nakamura Ver.1.2 mod start
--    END IF;
--    --空行挿入
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => ''
--    );
      --空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
    END IF;
-- 2009/02/24 T.Nakamura Ver.1.2 mod end
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
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
    FND_FILE.PUT_LINE(
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
    FND_FILE.PUT_LINE(
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
    FND_FILE.PUT_LINE(
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
    FND_FILE.PUT_LINE(
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
END XXCOS003A05C;
/
