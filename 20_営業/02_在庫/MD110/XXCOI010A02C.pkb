CREATE OR REPLACE PACKAGE BODY XXCOI010A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI010A02C(body)
 * Description      : 気づき情報IF出力
 * MD.050           : 気づき情報IF出力 MD050_COI_010_A02
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理 (A-1)
 *  chk_main_store_div     メイン倉庫区分チェック (A-3)
 *  get_awareness          気づき情報抽出 (A-4)
 *  chk_main_repeat        メイン倉庫重複チェック (A-5)
 *  submain                メイン処理プロシージャ
 *                         UTLファイルオープン (A-2)
 *                         気づき情報CSV作成 (A-6)
 *                         UTLファイルクローズ (A-7)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/26    1.0   T.Nakamura       新規作成
 *  2009/03/30    1.1   T.Nakamura       [障害T1_0083]IF項目の桁数を修正
 *                                       [障害T1_0084]IF項目の形式を修正
 *  2009/04/21    1.2   T.Nakamura       [障害T1_0580]メイン倉庫重複チェックを追加
 *  2010/02/16    1.3   N.Abe            [E_本稼動_01593]保管場所の無効日を参照
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
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCOI010A02C';     -- パッケージ名
  cv_appl_short_name_xxccp    CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アプリケーション短縮名：XXCCP
  cv_appl_short_name_xxcoi    CONSTANT VARCHAR2(10)  := 'XXCOI';            -- アプリケーション短縮名：XXCOI
--
  -- メッセージ
  cv_no_para_msg              CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008'; -- コンカレント入力パラメータなしメッセージ
  cv_file_name_msg            CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00028'; -- ファイル名出力メッセージ
  cv_no_data_msg              CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00008'; -- 対象データなしメッセージ
  cv_proc_date_get_err_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00011'; -- 業務日付取得エラーメッセージ
  cv_sold_out_mc_get_err_msg  CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10322'; -- 売切れ対策メッセージ色取得エラー
  cv_supl_rate_mc_get_err_msg CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10323'; -- 補充率対策メッセージ色取得エラー
  cv_hot_inv_mc_get_err_msg   CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10324'; -- ホット在庫対策メッセージ色取得エラー
  cv_dire_name_get_err_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00003'; -- ディレクトリ名取得エラーメッセージ
  cv_dire_path_get_err_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00029'; -- ディレクトリフルパス取得エラーメッセージ
  cv_file_name_get_err_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00004'; -- ファイル名取得エラーメッセージ
  cv_file_remain_err_msg      CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00027'; -- ファイル存在チェックエラーメッセージ
  cv_main_store_d_err_msg     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10009'; -- メイン倉庫区分チェックエラーメッセージ
  cv_sold_out_msg             CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10331'; -- 売切れ対策メッセージ
  cv_supl_rate_msg            CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10332'; -- 補充率対策メッセージ
  cv_hot_inv_msg              CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10333'; -- ホット在庫対策メッセージ
  cv_column_exist_msg         CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10334'; -- メッセージ.コラムあります
-- == 2009/04/21 V1.2 Added START ===============================================================
  cv_main_repeat_err_msg      CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10379'; -- メイン倉庫区分重複エラーメッセージ
-- == 2009/04/21 V1.2 Added END   ===============================================================
--
  -- トークン
  cv_tkn_pro_tok              CONSTANT VARCHAR2(20)  := 'PRO_TOK';          -- プロファイル名
  cv_tkn_base_code_tok        CONSTANT VARCHAR2(20)  := 'BASE_CODE_TOK';    -- 拠点コード
  cv_tkn_file_name            CONSTANT VARCHAR2(20)  := 'FILE_NAME';        -- ファイル名
  cv_tkn_dir_tok              CONSTANT VARCHAR2(20)  := 'DIR_TOK';          -- ディレクトリ名
  cv_tkn_time                 CONSTANT VARCHAR2(20)  := 'TIME';             -- 時間
  cv_tkn_rate                 CONSTANT VARCHAR2(20)  := 'RATE';             -- 率
  cv_tkn_day                  CONSTANT VARCHAR2(20)  := 'DAY';              -- 日数
--
  cv_subinv_type_store        CONSTANT VARCHAR2(1)   := '1';                -- 保管場所区分：倉庫
  cv_main_store_div_y         CONSTANT VARCHAR2(1)   := 'Y';                -- メイン倉庫区分：'Y'
  cv_cust_class_code_base     CONSTANT VARCHAR2(1)   := '1';                -- 顧客区分：拠点
  cv_dept_hht_div_dummy       CONSTANT VARCHAR2(1)   := '9';                -- 百貨店HHT区分：ダミー
  cv_dept_hht_div_dept        CONSTANT VARCHAR2(1)   := '1';                -- 百貨店HHT区分：百貨店
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_process_date        DATE;                -- 業務日付
  gv_sold_out_msg_color  VARCHAR2(100);       -- 売切れ対策メッセージ色
  gv_supl_rate_msg_color VARCHAR2(100);       -- 補充率対策メッセージ色
  gv_hot_inv_msg_color   VARCHAR2(100);       -- ホット在庫対策メッセージ色
  gv_dire_name           VARCHAR2(50);        -- ディレクトリ名
  gv_file_name           VARCHAR2(50);        -- ファイル名
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
  -- 気づき情報抽出
  CURSOR get_awareness_cur
  IS
    SELECT   msi.attribute7             AS sale_base_code                   -- 売上拠点コード
           , msi.attribute8             AS sold_out_time                    -- 売切れ時間
           , msi.attribute9             AS supl_rate                        -- 補充率
           , msi.attribute10            AS hot_inv                          -- ホット在庫
    FROM     mtl_secondary_inventories  msi                                 -- 保管場所マスタ
           , hz_cust_accounts           hca                                 -- 顧客マスタ
           , xxcmm_cust_accounts        xca                                 -- 顧客追加情報
    WHERE    msi.attribute1             =  cv_subinv_type_store             -- 取得条件：保管場所区分が'1'(倉庫)
    AND      msi.attribute6             =  cv_main_store_div_y              -- 取得条件：メイン倉庫区分が'Y'
    AND      NVL( msi.disable_date, TO_DATE( '9999/12/31', 'YYYY/MM/DD' ) )
                                        >  gd_process_date                  -- 取得条件：失効日がNULLか業務日付より後
    AND      hca.account_number         =  msi.attribute7                   -- 結合条件：顧客マスタと保管場所マスタ
    AND      hca.customer_class_code    =  cv_cust_class_code_base          -- 取得条件：顧客区分が拠点
    AND      xca.customer_id            =  hca.cust_account_id              -- 結合条件：顧客追加情報と顧客マスタ
    AND      NVL( xca.dept_hht_div, cv_dept_hht_div_dummy )
                                        <> cv_dept_hht_div_dept             -- 取得条件：百貨店HHT区分が'1'(百貨店)以外
    ;
--
  -- ==============================
  -- ユーザー定義グローバルテーブル
  -- ==============================
  TYPE g_get_awareness_ttype IS TABLE OF get_awareness_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  g_get_awareness_tab        g_get_awareness_ttype;
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  file_exist_expt           EXCEPTION;     -- ファイル存在エラー
  no_data_expt              EXCEPTION;     -- 対象データ0件エラー
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
    , ov_retcode    OUT VARCHAR2      --   リターン・コード             --# 固定 #
    , ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- プロファイル XXCOI:HHT_OUTBOUND格納ディレクトリパス
    cv_prf_dire_out_hht        CONSTANT VARCHAR2(30) := 'XXCOI1_DIRE_OUT_HHT';
    -- プロファイル XXCOI:気づき情報IF出力ファイル名
    cv_prf_file_awareness      CONSTANT VARCHAR2(30) := 'XXCOI1_FILE_AWARENESS';
    -- プロファイル XXCOI:売切れ対策メッセージ色
    cv_prf_sold_out_msg_color  CONSTANT VARCHAR2(30) := 'XXCOI1_SOLD_OUT_MSG_COLOR';
    -- プロファイル XXCOI:補充率対策メッセージ色
    cv_prf_supl_rate_msg_color CONSTANT VARCHAR2(30) := 'XXCOI1_SUPL_RATE_MSG_COLOR';
    -- プロファイル XXCOI:ホット在庫対策メッセージ色
    cv_prf_hot_inv_msg_color   CONSTANT VARCHAR2(30) := 'XXCOI1_HOT_INV_MSG_COLOR';
--
    cv_slash                   CONSTANT VARCHAR2(1)  := '/';  -- スラッシュ
--
    -- *** ローカル変数 ***
    lv_dire_path               VARCHAR2(100);                 -- ディレクトリフルパス格納変数
    lv_file_name               VARCHAR2(100);                 -- ファイル名格納変数
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
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
    -- コンカレント入力パラメータなしメッセージ出力
    -- ==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application => cv_appl_short_name_xxccp
                    , iv_name        => cv_no_para_msg
                  );
    -- メッセージ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => gv_out_msg
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => ''
    );
--
    -- ===============================
    -- 業務日付取得
    -- ===============================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- 業務日付が取得できない場合
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_proc_date_get_err_msg
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ==============================================================
    -- プロファイル：売切れ対策メッセージ色取得
    -- ==============================================================
    gv_sold_out_msg_color := fnd_profile.value( cv_prf_sold_out_msg_color );
    -- 売切れ対策メッセージ色が取得できない場合
    IF ( gv_sold_out_msg_color IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_sold_out_mc_get_err_msg
                     , iv_token_name1  => cv_tkn_pro_tok
                     , iv_token_value1 => cv_prf_sold_out_msg_color
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ==============================================================
    -- プロファイル：補充率対策メッセージ色取得
    -- ==============================================================
    gv_supl_rate_msg_color := fnd_profile.value( cv_prf_supl_rate_msg_color );
    -- 補充率対策メッセージ色が取得できない場合
    IF ( gv_supl_rate_msg_color IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_supl_rate_mc_get_err_msg
                     , iv_token_name1  => cv_tkn_pro_tok
                     , iv_token_value1 => cv_prf_supl_rate_msg_color
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ==============================================================
    -- プロファイル：ホット在庫対策メッセージ色取得
    -- ==============================================================
    gv_hot_inv_msg_color := fnd_profile.value( cv_prf_hot_inv_msg_color );
    -- ホット在庫対策メッセージ色が取得できない場合
    IF ( gv_hot_inv_msg_color IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_hot_inv_mc_get_err_msg
                     , iv_token_name1  => cv_tkn_pro_tok
                     , iv_token_value1 => cv_prf_hot_inv_msg_color
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- プロファイル：ディレクトリ名取得
    -- ===============================
    -- ディレクトリ名取得
    gv_dire_name := fnd_profile.value( cv_prf_dire_out_hht );
    -- ディレクトリ名が取得できない場合
    IF ( gv_dire_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_dire_name_get_err_msg
                     , iv_token_name1  => cv_tkn_pro_tok
                     , iv_token_value1 => cv_prf_dire_out_hht
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ディレクトリパス取得
    BEGIN
      SELECT directory_path
      INTO   lv_dire_path
      FROM   all_directories
      WHERE  directory_name    = gv_dire_name;
    EXCEPTION
      -- ディレクトリパスが取得できない場合
      WHEN NO_DATA_FOUND THEN
        lv_errmsg   := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name_xxcoi
                         , iv_name         => cv_dire_path_get_err_msg
                         , iv_token_name1  => cv_tkn_dir_tok
                         , iv_token_value1 => gv_dire_name
                       );
        lv_errbuf   := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- ===============================
    -- プロファイル：ファイル名取得
    -- ===============================
    gv_file_name := fnd_profile.value( cv_prf_file_awareness );
    -- ファイル名が取得できない場合
    IF ( gv_file_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_file_name_get_err_msg
                     , iv_token_name1  => cv_tkn_pro_tok
                     , iv_token_value1 => cv_prf_file_awareness
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ==============================================================
    -- IFファイル名（IFファイルのフルパス情報）出力
    -- ==============================================================
    lv_file_name := lv_dire_path || cv_slash || gv_file_name;
    gv_out_msg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_xxcoi
                      , iv_name         => cv_file_name_msg
                      , iv_token_name1  => cv_tkn_file_name
                      , iv_token_value1 => lv_file_name
                    );
    -- メッセージ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN
    -- *** 共通関数例外ハンドラ ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
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
   * Procedure Name   : chk_main_store_div
   * Description      : メイン倉庫区分チェック (A-3)
   ***********************************************************************************/
  PROCEDURE chk_main_store_div(
-- == 2009/04/21 V1.2 Moded START ===============================================================
--      ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
--    , ov_retcode    OUT VARCHAR2      --   リターン・コード             --# 固定 #
--    , ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
      on_chk_cnt    OUT NUMBER        --   チェック件数カウント
    , ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
    , ov_retcode    OUT VARCHAR2      --   リターン・コード             --# 固定 #
    , ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
-- == 2009/04/21 V1.2 Moded END   ===============================================================
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_main_store_div'; -- プログラム名
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
-- == 2009/04/21 V1.2 Added START ===============================================================
    ln_chk_cnt  NUMBER;  -- チェック件数カウント
-- == 2009/04/21 V1.2 Added END   ===============================================================
--
    -- *** ローカル・カーソル ***
    -- メイン倉庫区分チェック
    CURSOR chk_main_store_div_cur
    IS
      SELECT    msi.attribute7             AS base_code             -- 拠点コード
      FROM      mtl_secondary_inventories  msi                      -- 保管場所マスタ
      WHERE     msi.attribute1             =  cv_subinv_type_store  -- 抽出条件：保管場所区分が'1'
-- == 2010/02/16 V1.3 Added START ===============================================================
      AND       NVL(msi.disable_date, TO_DATE('9999/12/31', 'YYYY/MM/DD'))
                                           >  gd_process_date       -- 取得条件：失効日がNULLか業務日付より後
-- == 2010/02/16 V1.3 Added END   ===============================================================
      GROUP BY  msi.attribute7                                      -- 集約条件：拠点コード
      MINUS                                                         -- マージ：マイナス
      SELECT    msi.attribute7             AS base_code             -- 拠点コード
      FROM      mtl_secondary_inventories  msi                      -- 保管場所マスタ
      WHERE     msi.attribute6             =  cv_main_store_div_y   -- 抽出条件：メイン倉庫区分が'Y'
      AND       msi.attribute1             =  cv_subinv_type_store  -- 抽出条件：保管場所区分が'1'
-- == 2010/02/16 V1.3 Added START ===============================================================
      AND       NVL(msi.disable_date, TO_DATE('9999/12/31', 'YYYY/MM/DD'))
                                           >  gd_process_date       -- 取得条件：失効日がNULLか業務日付より後
-- == 2010/02/16 V1.3 Added END   ===============================================================
      GROUP BY  msi.attribute7                                      -- 集約条件：拠点コード
      ;
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
-- == 2009/04/21 V1.2 Added START ===============================================================
    -- 変数の初期化
    ln_chk_cnt  :=  0;
-- == 2009/04/21 V1.2 Added END   ===============================================================
    <<chk_main_store_div_loop>>
    FOR l_chk_main_store_div_rec IN chk_main_store_div_cur LOOP
      gv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_xxcoi
                      , iv_name         => cv_main_store_d_err_msg
                      , iv_token_name1  => cv_tkn_base_code_tok
                      , iv_token_value1 => l_chk_main_store_div_rec.base_code
                    );
      -- メッセージ出力
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => gv_out_msg
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||gv_out_msg,1,5000 )
      );
-- == 2009/04/21 V1.2 Moded START ===============================================================
--      -- 警告件数カウント
--      gn_warn_cnt := gn_warn_cnt + 1;
      -- チェック件数カウント
      ln_chk_cnt := ln_chk_cnt + 1;
-- == 2009/04/21 V1.2 Moded END   ===============================================================
--
    END LOOP chk_main_store_div_loop;
-- == 2009/04/21 V1.2 Added START ===============================================================
    -- 出力パラメータのセット
    on_chk_cnt  :=  ln_chk_cnt;
-- == 2009/04/21 V1.2 Added END   ===============================================================
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルがOPENしている場合
      IF ( chk_main_store_div_cur%ISOPEN ) THEN
        CLOSE chk_main_store_div_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルがOPENしている場合
      IF ( chk_main_store_div_cur%ISOPEN ) THEN
        CLOSE chk_main_store_div_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルがOPENしている場合
      IF ( chk_main_store_div_cur%ISOPEN ) THEN
        CLOSE chk_main_store_div_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END chk_main_store_div;
--
  /**********************************************************************************
   * Procedure Name   : get_awareness
   * Description      : 気づき情報抽出 (A-4)
   ***********************************************************************************/
  PROCEDURE get_awareness(
      ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
    , ov_retcode    OUT VARCHAR2      --   リターン・コード             --# 固定 #
    , ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_awareness'; -- プログラム名
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
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- カーソルオープン
    OPEN  get_awareness_cur;
--
    -- カーソルデータ取得
    FETCH get_awareness_cur BULK COLLECT INTO g_get_awareness_tab;
--
    -- カーソルのクローズ
    CLOSE get_awareness_cur;
--
    -- ===============================
    -- 抽出0件チェック
    -- ===============================
    IF ( g_get_awareness_tab.COUNT = 0 ) THEN
      RAISE no_data_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- 対象データ0件エラー
    WHEN no_data_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_xxcoi
                      , iv_name         => cv_no_data_msg
                    );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルがOPENしている場合
      IF ( get_awareness_cur%ISOPEN ) THEN
        CLOSE get_awareness_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルがOPENしている場合
      IF ( get_awareness_cur%ISOPEN ) THEN
        CLOSE get_awareness_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルがOPENしている場合
      IF ( get_awareness_cur%ISOPEN ) THEN
        CLOSE get_awareness_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_awareness;
--
-- == 2009/04/21 V1.2 Added START ===============================================================
  /**********************************************************************************
   * Procedure Name   : chk_main_repeat
   * Description      : メイン倉庫重複チェック (A-5)
   ***********************************************************************************/
  PROCEDURE chk_main_repeat(
      iv_base_code  IN  VARCHAR2      --   拠点コード
    , ob_chk_status OUT BOOLEAN       --   重複チェックステータス
    , ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
    , ov_retcode    OUT VARCHAR2      --   リターン・コード             --# 固定 #
    , ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_main_repeat'; -- プログラム名
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
    lt_base_code       mtl_secondary_inventories.attribute7%TYPE; -- 拠点コード
    ln_main_store_cnt  NUMBER;                                    -- 拠点内メイン倉庫件数
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 変数の初期化
    lt_base_code       := NULL;
    ln_main_store_cnt  := NULL;
    ob_chk_status      := TRUE;
--
    -- メイン倉庫重複チェック
    SELECT    msi.attribute7             AS base_code             -- 拠点コード
            , COUNT(1)                   AS main_store_cnt        -- 拠点内メイン倉庫件数
    INTO      lt_base_code
            , ln_main_store_cnt
    FROM      mtl_secondary_inventories  msi                      -- 保管場所マスタ
    WHERE     msi.attribute6             =  cv_main_store_div_y   -- 抽出条件：メイン倉庫区分が'Y'
    AND       msi.attribute1             =  cv_subinv_type_store  -- 抽出条件：保管場所区分が'1'
    AND       NVL( msi.disable_date, TO_DATE( '9999/12/31', 'YYYY/MM/DD' ) )
                                         >  gd_process_date       -- 取得条件：失効日がNULLか業務日付より後
    AND       msi.attribute7             =  iv_base_code          -- 取得条件：拠点コード＝入力パラメータ
    GROUP BY  msi.attribute7                                      -- 集約条件：拠点コード
    ;
--
    -- 同一拠点内にメイン倉庫が複数存在する場合
    IF ( ln_main_store_cnt > 1 ) THEN
--
      -- 重複チェックステータスを更新
      ob_chk_status := FALSE;
--
      -- メイン倉庫重複エラーメッセージ
      gv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_xxcoi
                      , iv_name         => cv_main_repeat_err_msg
                      , iv_token_name1  => cv_tkn_base_code_tok
                      , iv_token_value1 => lt_base_code
                    );
      -- メッセージ出力
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => gv_out_msg
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||gv_out_msg,1,5000 )
      );
--
      -- 警告件数カウント
      gn_warn_cnt := gn_warn_cnt + 1;
--
   END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
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
  END chk_main_repeat;
--
-- == 2009/04/21 V1.2 Added END   ===============================================================
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
      ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
    , ov_retcode    OUT VARCHAR2      --   リターン・コード             --# 固定 #
    , ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    cv_open_mode             CONSTANT VARCHAR2(1)   := 'w';              -- オープンモード：書き込み
    cv_delimiter             CONSTANT VARCHAR2(1)   := ',';              -- 区切り文字
    cv_encloser              CONSTANT VARCHAR2(1)   := '"';              -- 括り文字
--
    -- *** ローカル変数 ***
    ln_file_length           NUMBER;                       -- ファイルの長さの変数
    ln_block_size            NUMBER;                       -- ブロックサイズの変数
    lb_fexists               BOOLEAN;                      -- ファイル存在チェック結果
    lv_sold_out_msg          VARCHAR2(50);                 -- 売切れ対策メッセージ
    lv_supl_rate_msg         VARCHAR2(50);                 -- 補充率対策メッセージ
    lv_hot_inv_msg           VARCHAR2(50);                 -- ホット在庫対策メッセージ
    lv_column_exist_msg      VARCHAR2(50);                 -- コラムありますメッセージ
    lv_csv_file              VARCHAR2(1500);               -- CSVファイル
    l_file_handle            UTL_FILE.FILE_TYPE;           -- ファイルハンドル
-- == 2009/04/21 V1.2 Added START ===============================================================
    ln_main_chk_cnt          NUMBER;                       -- メイン倉庫区分チェック件数カウント
    lb_chk_status            BOOLEAN;                      -- メイン倉庫重複チェックステータス
-- == 2009/04/21 V1.2 Added END   ===============================================================
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
    gn_warn_cnt   := 0;
-- == 2009/04/21 V1.2 Added START ===============================================================
    -- ローカル変数の初期化
    ln_main_chk_cnt := 0;
    lb_chk_status   := NULL;
-- == 2009/04/21 V1.2 Added END   ===============================================================
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- 初期処理 (A-1)
    -- ===============================
    init(
        ov_errbuf  => lv_errbuf         -- エラー・メッセージ           --# 固定 #
      , ov_retcode => lv_retcode        -- リターン・コード             --# 固定 #
      , ov_errmsg  => lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- UTLファイルオープン (A-2)
    -- ===============================
    -- ファイルの存在チェック
    UTL_FILE.FGETATTR(
        location    => gv_dire_name
      , filename    => gv_file_name
      , fexists     => lb_fexists
      , file_length => ln_file_length
      , block_size  => ln_block_size
    );
    IF( lb_fexists = TRUE ) THEN
      RAISE file_exist_expt;
    END IF;
--
    -- ファイルのオープン
    l_file_handle := UTL_FILE.FOPEN(
                         location  => gv_dire_name
                       , filename  => gv_file_name
                       , open_mode => cv_open_mode
                     );
--
    -- ===============================
    -- メイン倉庫区分チェック(A-3)
    -- ===============================
    chk_main_store_div(
-- == 2009/04/21 V1.2 Added START ===============================================================
--        ov_errbuf  => lv_errbuf         -- エラー・メッセージ           --# 固定 #
--      , ov_retcode => lv_retcode        -- リターン・コード             --# 固定 #
--      , ov_errmsg  => lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
        on_chk_cnt => ln_main_chk_cnt   -- メイン倉庫区分チェック件数カウント
      , ov_errbuf  => lv_errbuf         -- エラー・メッセージ           --# 固定 #
      , ov_retcode => lv_retcode        -- リターン・コード             --# 固定 #
      , ov_errmsg  => lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
-- == 2009/04/21 V1.2 Added END   ===============================================================
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 気づき情報抽出(A-4)
    -- ===============================
    get_awareness(
        ov_errbuf  => lv_errbuf         -- エラー・メッセージ           --# 固定 #
      , ov_retcode => lv_retcode        -- リターン・コード             --# 固定 #
      , ov_errmsg  => lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ループ開始
    -- ===============================
    <<create_file_loop>>
    FOR i IN 1 .. g_get_awareness_tab.COUNT LOOP
--
-- == 2009/04/21 V1.2 Moded START ===============================================================
--      -- ===============================
--      -- 気づき情報CSV作成 (A-5)
--      -- ===============================
--      -- 売切れ対策メッセージ取得
--      lv_sold_out_msg     := xxccp_common_pkg.get_msg(
--                                 iv_application  => cv_appl_short_name_xxcoi
--                               , iv_name         => cv_sold_out_msg
--                               , iv_token_name1  => cv_tkn_time
--                               , iv_token_value1 => g_get_awareness_tab(i).sold_out_time
--                             );
--      -- 補充率対策メッセージ取得
--      lv_supl_rate_msg    := xxccp_common_pkg.get_msg(
--                                 iv_application  => cv_appl_short_name_xxcoi
--                               , iv_name         => cv_supl_rate_msg
--                               , iv_token_name1  => cv_tkn_rate
--                               , iv_token_value1 => g_get_awareness_tab(i).supl_rate
--                             );
--      -- ホット在庫対策メッセージ取得
--      lv_hot_inv_msg      := xxccp_common_pkg.get_msg(
--                                 iv_application  => cv_appl_short_name_xxcoi
--                               , iv_name         => cv_hot_inv_msg
--                               , iv_token_name1  => cv_tkn_day
--                               , iv_token_value1 => g_get_awareness_tab(i).hot_inv
--                             );
--      -- メッセージ.コラムあります取得
--      lv_column_exist_msg := xxccp_common_pkg.get_msg(
--                                 iv_application  => cv_appl_short_name_xxcoi
--                               , iv_name         => cv_column_exist_msg
--                             );
--      -- CSVデータを作成
--      lv_csv_file := (
--        cv_encloser || g_get_awareness_tab(i).sale_base_code || cv_encloser || cv_delimiter || --売上拠点コード
--                       g_get_awareness_tab(i).sold_out_time                 || cv_delimiter || --売切れ時間
--                       g_get_awareness_tab(i).supl_rate                     || cv_delimiter || --補充率
--                       g_get_awareness_tab(i).hot_inv                       || cv_delimiter || --ホット在庫
--        cv_encloser || gv_sold_out_msg_color                 || cv_encloser || cv_delimiter || --売切れ対策メッセージ色
---- == 2009/03/30 V1.1 Moded START ===============================================================
----        cv_encloser || lv_sold_out_msg                       || cv_encloser || cv_delimiter || --売切れ対策メッセージ1
--        cv_encloser || TO_MULTI_BYTE( REPLACE( lv_sold_out_msg, ' ' ) )
--                                                             || cv_encloser || cv_delimiter || --売切れ対策メッセージ1
---- == 2009/03/30 V1.1 Moded END   ===============================================================
--        cv_encloser || lv_column_exist_msg                   || cv_encloser || cv_delimiter || --売切れ対策メッセージ2
--        cv_encloser || gv_supl_rate_msg_color                || cv_encloser || cv_delimiter || --補充率対策メッセージ色
---- == 2009/03/30 V1.1 Moded START ===============================================================
----        cv_encloser || lv_supl_rate_msg                      || cv_encloser || cv_delimiter || --補充率対策メッセージ1
--        cv_encloser || TO_MULTI_BYTE( REPLACE( lv_supl_rate_msg, ' ' ) )    
--                                                             || cv_encloser || cv_delimiter || --補充率対策メッセージ1
---- == 2009/03/30 V1.1 Moded END   ===============================================================
--        cv_encloser || lv_column_exist_msg                   || cv_encloser || cv_delimiter || --補充率対策メッセージ2
--        cv_encloser || gv_hot_inv_msg_color                  || cv_encloser || cv_delimiter || --ホット在庫メッセージ色
---- == 2009/03/30 V1.1 Moded START ===============================================================
----        cv_encloser || lv_hot_inv_msg                        || cv_encloser || cv_delimiter || --ホット在庫メッセージ1
--        cv_encloser || TO_MULTI_BYTE( REPLACE( lv_hot_inv_msg, ' ' ) )
--                                                             || cv_encloser || cv_delimiter || --ホット在庫メッセージ1
---- == 2009/03/30 V1.1 Moded END   ===============================================================
--        cv_encloser || lv_column_exist_msg                   || cv_encloser                    --ホット在庫メッセージ2
--      );
----
--      -- ===============================
--      -- CSVデータを出力
--      -- ===============================
--      UTL_FILE.PUT_LINE(
--          file   => l_file_handle
--        , buffer => lv_csv_file
--      );
----
--      -- ===============================
--      -- 成功件数カウント
--      -- ===============================
--      gn_normal_cnt := gn_normal_cnt + 1;
--
      -- ===============================
      -- メイン倉庫重複チェック (A-5)
      -- ===============================
      chk_main_repeat(
          iv_base_code  => g_get_awareness_tab(i).sale_base_code  -- 拠点コード
        , ob_chk_status => lb_chk_status     -- 重複チェックステータス
        , ov_errbuf     => lv_errbuf         -- エラー・メッセージ           --# 固定 #
        , ov_retcode    => lv_retcode        -- リターン・コード             --# 固定 #
        , ov_errmsg     => lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- 同一拠点内にメイン倉庫が1つの場合
      IF ( lb_chk_status = TRUE ) THEN
--
        -- ===============================
        -- 気づき情報CSV作成 (A-6)
        -- ===============================
        -- 売切れ対策メッセージ取得
        lv_sold_out_msg     := xxccp_common_pkg.get_msg(
                                   iv_application  => cv_appl_short_name_xxcoi
                                 , iv_name         => cv_sold_out_msg
                                 , iv_token_name1  => cv_tkn_time
                                 , iv_token_value1 => g_get_awareness_tab(i).sold_out_time
                               );
        -- 補充率対策メッセージ取得
        lv_supl_rate_msg    := xxccp_common_pkg.get_msg(
                                   iv_application  => cv_appl_short_name_xxcoi
                                 , iv_name         => cv_supl_rate_msg
                                 , iv_token_name1  => cv_tkn_rate
                                 , iv_token_value1 => g_get_awareness_tab(i).supl_rate
                               );
        -- ホット在庫対策メッセージ取得
        lv_hot_inv_msg      := xxccp_common_pkg.get_msg(
                                   iv_application  => cv_appl_short_name_xxcoi
                                 , iv_name         => cv_hot_inv_msg
                                 , iv_token_name1  => cv_tkn_day
                                 , iv_token_value1 => g_get_awareness_tab(i).hot_inv
                               );
        -- メッセージ.コラムあります取得
        lv_column_exist_msg := xxccp_common_pkg.get_msg(
                                   iv_application  => cv_appl_short_name_xxcoi
                                 , iv_name         => cv_column_exist_msg
                               );
        -- CSVデータを作成
        lv_csv_file := (
          cv_encloser || g_get_awareness_tab(i).sale_base_code || cv_encloser || cv_delimiter || --売上拠点コード
                         g_get_awareness_tab(i).sold_out_time                 || cv_delimiter || --売切れ時間
                         g_get_awareness_tab(i).supl_rate                     || cv_delimiter || --補充率
                         g_get_awareness_tab(i).hot_inv                       || cv_delimiter || --ホット在庫
          cv_encloser || gv_sold_out_msg_color                 || cv_encloser || cv_delimiter || --売切れ対策メッセージ色
          cv_encloser || TO_MULTI_BYTE( REPLACE( lv_sold_out_msg, ' ' ) )
                                                               || cv_encloser || cv_delimiter || --売切れ対策メッセージ1
          cv_encloser || lv_column_exist_msg                   || cv_encloser || cv_delimiter || --売切れ対策メッセージ2
          cv_encloser || gv_supl_rate_msg_color                || cv_encloser || cv_delimiter || --補充率対策メッセージ色
          cv_encloser || TO_MULTI_BYTE( REPLACE( lv_supl_rate_msg, ' ' ) )    
                                                               || cv_encloser || cv_delimiter || --補充率対策メッセージ1
          cv_encloser || lv_column_exist_msg                   || cv_encloser || cv_delimiter || --補充率対策メッセージ2
          cv_encloser || gv_hot_inv_msg_color                  || cv_encloser || cv_delimiter || --ホット在庫メッセージ色
          cv_encloser || TO_MULTI_BYTE( REPLACE( lv_hot_inv_msg, ' ' ) )
                                                               || cv_encloser || cv_delimiter || --ホット在庫メッセージ1
          cv_encloser || lv_column_exist_msg                   || cv_encloser                    --ホット在庫メッセージ2
        );
--
        -- ===============================
        -- CSVデータを出力
        -- ===============================
        UTL_FILE.PUT_LINE(
            file   => l_file_handle
          , buffer => lv_csv_file
        );
--
        -- ===============================
        -- 成功件数カウント
        -- ===============================
        gn_normal_cnt := gn_normal_cnt + 1;
--
      END IF;
-- == 2009/04/21 V1.2 Moded END   ===============================================================
--
    END LOOP create_file_loop;
--
    -- ===============================
    -- UTLファイルクローズ (A-7)
    -- ===============================
    UTL_FILE.FCLOSE( file => l_file_handle );
--
-- == 2009/04/21 V1.2 Moded START ===============================================================
--    -- ===============================
--    -- 対象件数カウント
--    -- ===============================
--    gn_target_cnt := gn_normal_cnt + gn_warn_cnt;
    -- ===============================
    -- 対象件数カウント
    -- ===============================
    gn_target_cnt := g_get_awareness_tab.COUNT + ln_main_chk_cnt;
--
    -- ===============================
    -- 警告件数カウント
    -- ===============================
    gn_warn_cnt := gn_warn_cnt + ln_main_chk_cnt;
-- == 2009/04/21 V1.2 Moded END   ===============================================================
--
    -- 警告件数が0件より多い場合、ステータス：警告をセット
    IF ( gn_warn_cnt > 0 ) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
--
    -- *** ファイル存在チェックエラー ***
    WHEN file_exist_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_xxcoi
                      , iv_name         => cv_file_remain_err_msg
                      , iv_token_name1  => cv_tkn_file_name
                      , iv_token_value1 => gv_file_name
                    );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- ファイルがOPENしている場合
      IF ( UTL_FILE.IS_OPEN( file => l_file_handle ) ) THEN
        UTL_FILE.FCLOSE( file => l_file_handle );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- ファイルがOPENしている場合
      IF ( UTL_FILE.IS_OPEN( file => l_file_handle ) ) THEN
        UTL_FILE.FCLOSE( file => l_file_handle );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- ファイルがOPENしている場合
      IF ( UTL_FILE.IS_OPEN( file => l_file_handle ) ) THEN
        UTL_FILE.FCLOSE( file => l_file_handle );
      END IF;
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
      errbuf        OUT VARCHAR2       --   エラー・メッセージ  --# 固定 #
    , retcode       OUT VARCHAR2)      --   リターン・コード    --# 固定 #
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
        ov_errbuf  => lv_errbuf         -- エラー・メッセージ           --# 固定 #
      , ov_retcode => lv_retcode        -- リターン・コード             --# 固定 #
      , ov_errmsg  => lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      -- 成功件数、スキップ件数の初期化及びエラー件数のセット
      gn_normal_cnt := 0;
      gn_warn_cnt   := 0;
      gn_error_cnt  := 1;
      -- エラー出力
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_errmsg       -- ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_errbuf       -- エラーメッセージ
      );
    END IF;
    -- 空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
    -- 対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_xxccp
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
                      iv_application  => cv_appl_short_name_xxccp
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_normal_cnt )
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
--
    -- エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_xxccp
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_error_cnt )
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
--
    -- スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_xxccp
                    , iv_name         => cv_skip_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_warn_cnt )
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
    -- 終了メッセージ
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_xxccp
                    , iv_name         => lv_message_code
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- ステータスセット
    retcode := lv_retcode;
    -- 終了ステータスがエラーの場合はROLLBACKする
    IF ( retcode = cv_status_error ) THEN
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
END XXCOI010A02C;
/
