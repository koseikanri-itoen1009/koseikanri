CREATE OR REPLACE PACKAGE BODY APPS.XXCOI010A05C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOI010A05C(body)
 * Description      : 他拠点営業車入出庫セキュリティマスタHHT連携
 * MD.050           : 他拠点営業車入出庫セキュリティマスタHHT連携 MD050_COI_010_A05
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理                                     (A-1)
 *                         データ抽出                                   (A-2)
 *  create_csv_file        他拠点営業車入出庫セキュリティマスタCSV出力  (A-3)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2015/04/21    1.0   S.Yamashita      新規作成
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
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
  gn_skip_cnt      NUMBER;                    -- スキップ件数
  gn_error_cnt     NUMBER;                    -- エラー件数
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
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCOI010A05C';     -- パッケージ名
  cv_appl_short_name_xxccp    CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アプリケーション短縮名：XXCCP
  cv_appl_short_name_xxcoi    CONSTANT VARCHAR2(10)  := 'XXCOI';            -- アプリケーション短縮名：XXCOI
--
  -- メッセージ
  cv_msg_coi_00003            CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00003'; -- ディレクトリ名取得エラーメッセージ
  cv_msg_coi_00004            CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00004'; -- ファイル名取得エラーメッセージ
  cv_msg_coi_00008            CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00008'; -- 対象データなしメッセージ
  cv_msg_coi_00011            CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00011'; -- 業務日付取得エラーメッセージ
  cv_msg_coi_00023            CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00023'; -- コンカレント入力パラメータなしメッセージ
  cv_msg_coi_00027            CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00027'; -- ファイル存在チェックエラーメッセージ
  cv_msg_coi_00028            CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00028'; -- ファイル名出力メッセージ
  cv_msg_coi_00029            CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00029'; -- ディレクトリフルパス取得エラーメッセージ
  cv_msg_coi_10700            CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10700'; -- 拠点コード不正メッセージ
--
  -- トークン
  cv_tkn_pro_tok              CONSTANT VARCHAR2(20)  := 'PRO_TOK';          -- プロファイル名
  cv_tkn_file_name            CONSTANT VARCHAR2(20)  := 'FILE_NAME';        -- ファイル名
  cv_tkn_dir_tok              CONSTANT VARCHAR2(20)  := 'DIR_TOK';          -- ディレクトリ名
  cv_tkn_base_code            CONSTANT VARCHAR2(20)  := 'BASE_CODE';        -- 拠点コード
  cv_tkn_out_base_code        CONSTANT VARCHAR2(20)  := 'OUT_BASE_CODE';    -- 相手先拠点コード
--
  cv_flag_y                   CONSTANT VARCHAR2(1)   := 'Y';
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_dir_name          VARCHAR2(50);          -- ディレクトリ名
  gv_file_name         VARCHAR2(50);          -- ファイル名
  g_file_handle        UTL_FILE.FILE_TYPE;    -- ファイルハンドル
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  remain_file_expt          EXCEPTION;     -- ファイル存在エラー
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
    -- プロファイル
    cv_prf_dire_out_hht        CONSTANT VARCHAR2(30) := 'XXCOI1_DIRE_OUT_HHT';    -- XXCOI:HHT_OUTBOUND格納ディレクトリパス
    cv_prf_file_other_base     CONSTANT VARCHAR2(30) := 'XXCOI1_FILE_OTHER_BASE'; -- XXCOI:他拠点営業車入出庫セキュリティIF出力ファイル名
--
    cv_slash                   CONSTANT VARCHAR2(1) :=  '/';  -- スラッシュ
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
    -- ===============================
    -- コンカレント入力パラメータなしメッセージ出力
    -- ===============================
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_xxcoi
                    , iv_name         => cv_msg_coi_00023
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
    -- ===============================
    -- プロファイル：ディレクトリ名取得
    -- ===============================
    -- ディレクトリ名取得
    gv_dir_name := fnd_profile.value( cv_prf_dire_out_hht );
--
    -- ディレクトリ名が取得できない場合
    IF ( gv_dir_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_msg_coi_00003  -- ディレクトリ名取得エラーメッセージ
                     , iv_token_name1  => cv_tkn_pro_tok
                     , iv_token_value1 => cv_prf_dire_out_hht
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ディレクトリパス取得
    BEGIN
      SELECT ad.directory_path AS directory_path -- ディレクトリパス
      INTO   lv_dire_path -- ディレクトリパス
      FROM   all_directories ad -- ディレクトリマスタ
      WHERE  ad.directory_name  = gv_dir_name; -- ディレクトリ名
    EXCEPTION
      -- ディレクトリパスが取得できない場合
      WHEN NO_DATA_FOUND THEN
        lv_errmsg   := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name_xxcoi
                         , iv_name         => cv_msg_coi_00029 -- ディレクトリフルパス取得エラーメッセージ
                         , iv_token_name1  => cv_tkn_dir_tok
                         , iv_token_value1 => gv_dir_name
                       );
        lv_errbuf   := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- ===============================
    -- プロファイル：ファイル名取得
    -- ===============================
    gv_file_name := fnd_profile.value( cv_prf_file_other_base );
--
    -- ファイル名が取得できない場合
    IF ( gv_file_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_msg_coi_00004  -- ファイル名取得エラーメッセージ
                     , iv_token_name1  => cv_tkn_pro_tok
                     , iv_token_value1 => cv_prf_file_other_base
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
                      , iv_name         => cv_msg_coi_00028  -- ファイル名出力メッセージ
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
   * Procedure Name   : create_csv_file
   * Description      : 他拠点営業車入出庫セキュリティマスタCSV作成(A-3)
   ***********************************************************************************/
  PROCEDURE create_csv_file(
      ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
    , ov_retcode    OUT VARCHAR2      --   リターン・コード             --# 固定 #
    , ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100) := 'create_csv_file'; -- プログラム名
    cv_lookup_other_base CONSTANT VARCHAR2(100) := 'XXCOI1_OTHER_BASE_INOUT_SECURE'; -- 参照タイプ
    cv_cust_class_1      CONSTANT VARCHAR2(1)   := '1';               -- 顧客区分:1（拠点）
    cv_language          CONSTANT VARCHAR2(100) := USERENV('LANG');   -- 言語
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
    cv_delimiter     CONSTANT VARCHAR2(1) := ',';  -- 区切り文字
    cv_encloser      CONSTANT VARCHAR2(1) := '"';  -- 括り文字
--
    -- *** ローカル変数 ***
    lv_csv_file      VARCHAR2(1500);
--
    -- *** ローカル・カーソル ***
    -- データ抽出(A-2)
    CURSOR get_other_base_sec_cur
    IS
      SELECT SUBSTRB(flv.lookup_code,1,4) AS base_code            -- 親拠点コード
            ,SUBSTRB(flv.meaning,1,4)     AS other_base_code      -- 相手先拠点コード
            ,flv.description              AS other_warehouse_code -- 相手先倉庫
            ,hca1.account_number          AS base_code1           -- 拠点コード1
            ,hca2.account_number          AS base_code2           -- 拠点コード2
      FROM   fnd_lookup_values flv -- クイックコード
            ,hz_cust_accounts hca1 -- 顧客マスタ1
            ,hz_cust_accounts hca2 -- 顧客マスタ2
      WHERE  flv.lookup_type             = cv_lookup_other_base  -- タイプ
      AND    flv.enabled_flag            = cv_flag_y             -- 有効フラグ
      AND    flv.language                = cv_language           -- 言語
      AND    hca1.account_number(+)      = SUBSTRB(flv.lookup_code,1,4) -- 顧客コード1
      AND    hca1.customer_class_code(+) = cv_cust_class_1              -- 顧客区分
      AND    hca2.account_number(+)      = SUBSTRB(flv.meaning,1,4)     -- 顧客コード2
      AND    hca2.customer_class_code(+) = cv_cust_class_1              -- 顧客区分
      ORDER BY 
             base_code             -- 親拠点コード
            ,other_base_code       -- 相手先拠点コード
            ,other_warehouse_code  -- 相手先倉庫
    ;
--
    -- *** ローカル・レコード ***
    get_other_base_sec_rec  get_other_base_sec_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ローカル変数初期化
    lv_csv_file := NULL;
--
    -- ===============================
    -- ループ開始
    -- ===============================
    OPEN get_other_base_sec_cur;
--
    <<output_loop>>
    LOOP
      FETCH get_other_base_sec_cur INTO get_other_base_sec_rec;
      EXIT WHEN get_other_base_sec_cur%NOTFOUND;
--
      -- 対象件数カウント
      gn_target_cnt := gn_target_cnt + 1;
--
      -- 拠点コード1または拠点コード2がNULLの場合（拠点が不正な場合）
      IF ( (get_other_base_sec_rec.base_code1 IS NULL)
        OR (get_other_base_sec_rec.base_code2 IS NULL) )
      THEN
        gv_out_msg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_short_name_xxcoi
                        , iv_name         => cv_msg_coi_10700  -- 拠点コード不正メッセージ
                        , iv_token_name1  => cv_tkn_base_code
                        , iv_token_value1 => get_other_base_sec_rec.base_code       -- 親拠点コード
                        , iv_token_name2  => cv_tkn_out_base_code
                        , iv_token_value2 => get_other_base_sec_rec.other_base_code -- 相手先拠点コード
                      );
        -- メッセージ出力
        FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
          , buff   => gv_out_msg
        );
--
        -- スキップ件数カウント
        gn_skip_cnt := gn_skip_cnt + 1;
--
      ELSE
        -- 出力文字列を作成
        lv_csv_file := (
          cv_encloser || get_other_base_sec_rec.base_code            || cv_encloser  || cv_delimiter ||  -- 親拠点コード
          cv_encloser || get_other_base_sec_rec.other_base_code      || cv_encloser  || cv_delimiter ||  -- 相手先拠点コード
          cv_encloser || get_other_base_sec_rec.other_warehouse_code || cv_encloser                      -- 相手先倉庫
        );
--
        -- ===============================
        -- CSV出力
        -- ===============================
        UTL_FILE.PUT_LINE(
            file   => g_file_handle
          , buffer => lv_csv_file
        );
--
        -- ===============================
        -- 成功件数カウント
        -- ===============================
        gn_normal_cnt := gn_normal_cnt + 1;
--
      END IF;
--
    END LOOP output_loop;
--
    CLOSE get_other_base_sec_cur;
--
    -- ===============================
    -- 抽出0件チェック
    -- ===============================
    IF ( gn_target_cnt = 0 ) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_xxcoi
                      , iv_name         => cv_msg_coi_00008
                    );
      -- メッセージ出力
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => gv_out_msg
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
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルが開いている場合はクローズ
      IF (get_other_base_sec_cur%ISOPEN) THEN
        CLOSE get_other_base_sec_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END create_csv_file;
--
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
    cv_open_mode    CONSTANT VARCHAR2(1) := 'w';  -- オープンモード：書き込み
--
    -- *** ローカル変数 ***
    ln_file_length  NUMBER;        -- ファイルの長さの変数
    ln_block_size   NUMBER;        -- ブロックサイズの変数
    lb_fexists      BOOLEAN;       -- ファイル存在チェック結果
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
    gn_target_cnt   := 0;
    gn_normal_cnt   := 0;
    gn_skip_cnt     := 0;
    gn_error_cnt    := 0;
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
    -- UTLファイルオープン
    -- ===============================
    -- ファイルの存在チェック
    UTL_FILE.FGETATTR(
        location    => gv_dir_name
      , filename    => gv_file_name
      , fexists     => lb_fexists
      , file_length => ln_file_length
      , block_size  => ln_block_size
    );
    -- 同一ファイルが存在する場合
    IF( lb_fexists = TRUE ) THEN
      -- 同一ファイル存在チェックエラー
      RAISE remain_file_expt;
    END IF;
--
    -- ファイルのオープン
    g_file_handle := UTL_FILE.FOPEN(
                         location  => gv_dir_name
                       , filename  => gv_file_name
                       , open_mode => cv_open_mode
                     );
--
    -- ===============================
    -- データ抽出/他拠点営業車入出庫セキュリティマスタCSV出力 (A-2,A-3)
    -- ===============================
    create_csv_file(
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
    -- UTLファイルクローズ
    -- ===============================
    UTL_FILE.FCLOSE( file => g_file_handle );
--
  EXCEPTION
--
    -- *** ファイル存在チェックエラー ***
    WHEN remain_file_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_xxcoi
                      , iv_name         => cv_msg_coi_00027
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
      IF ( UTL_FILE.IS_OPEN( file => g_file_handle ) ) THEN
        UTL_FILE.FCLOSE( file => g_file_handle );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- ファイルがOPENしている場合
      IF ( UTL_FILE.IS_OPEN( file => g_file_handle ) ) THEN
        UTL_FILE.FCLOSE( file => g_file_handle );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- ファイルがOPENしている場合
      IF ( UTL_FILE.IS_OPEN( file => g_file_handle ) ) THEN
        UTL_FILE.FCLOSE( file => g_file_handle );
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
      errbuf              OUT VARCHAR2       --   エラー・メッセージ  --# 固定 #
    , retcode             OUT VARCHAR2       --   リターン・コード    --# 固定 #
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
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    cv_warn_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
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
      -- エラーの場合、エラー件数のみ1件に設定
      gn_target_cnt := 0; -- 対象件数
      gn_normal_cnt := 0; -- 成功件数
      gn_skip_cnt   := 0; -- スキップ件数
      gn_error_cnt  := 1; -- エラー件数
      --エラー出力
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
    --対象件数出力
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
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_xxccp
                    , iv_name         => cv_warn_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_skip_cnt )
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
--
    --エラー件数出力
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
    -- 空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
    --終了メッセージ
    IF ( lv_retcode = cv_status_normal ) THEN
      IF ( gn_skip_cnt <> 0 ) THEN
        lv_message_code := cv_warn_msg;
        lv_retcode := cv_status_warn;
      ELSE
        lv_message_code := cv_normal_msg;
      END IF;
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
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
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
END XXCOI010A05C;
/
