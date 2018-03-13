CREATE OR REPLACE PACKAGE BODY APPS.XXCMM004A14C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * Package Name     : XXCMM004A14C(body)
 * Description      : 各諸マスタIF出力（HHT）
 * MD.050           : 各諸マスタIF出力（HHT） MD050_CMM_004_A14
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  file_open              ファイルオープン処理(A-2)
 *  put_csv_data           諸マスタ情報取得処理(A-3)
 *                         CSVファイル出力処理(A-4)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                         終了処理(A-5)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2017/07/25    1.0   S.Niki           E_本稼動_14486対応 新規作成
 *  2018/03/07    1.1   H.Sasaki         E_本稼動_14914対応
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
  PRAGMA EXCEPTION_INIT(global_api_others_expt, -20000);
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_appl_name_xxcmm       CONSTANT VARCHAR2(5)   := 'XXCMM';               -- アドオン：マスタ・マスタ領域
  cv_appl_name_xxccp       CONSTANT VARCHAR2(5)   := 'XXCCP';               -- アドオン：共通・IF領域
  cv_pkg_name              CONSTANT VARCHAR2(100) := 'XXCMM004A14C';        -- パッケージ名
--
  -- プロファイル名
  cv_prf_file_dir          CONSTANT VARCHAR2(60)  := 'XXCMM1_HHT_OUT_DIR';       -- XXCMM:HHT(OUTBOUND)連携用CSVファイル出力先
  cv_prf_file_name         CONSTANT VARCHAR2(60)  := 'XXCMM1_004A14_OUT_FILE';   -- XXCMM:各諸マスタHHT連携用CSVファイル名
--
  -- LOOKUP表
  cv_lookup_band_code      CONSTANT VARCHAR2(30)  := 'XXCOS1_BAND_CODE';    -- 政策群
  cv_lookup_itm_yokigun    CONSTANT VARCHAR2(30)  := 'XXCMM_ITM_YOKIGUN';   -- 容器群
--
  -- メッセージ
  cv_msg_xxcmm_00002       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00002';    -- プロファイル取得エラー
  cv_msg_xxcmm_00022       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00022';    -- CSVファイル名ノート
  cv_msg_xxcmm_10482       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10482';    -- CSVファイル存在エラー
  cv_msg_xxcmm_00487       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00487';    -- ファイルオープンエラー
  cv_msg_xxcmm_00488       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00488';    -- ファイル書き込みエラー
  cv_msg_xxcmm_00489       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00489';    -- ファイルクローズエラー
  cv_msg_xxccp_90008       CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90008';    -- コンカレント入力パラメータなし
--
  -- 除外文字列
  cv_msg_xxcmm_10483       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10483';    -- 合計
  cv_msg_xxcmm_10484       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10484';    -- 計
--
  -- トークン名
  cv_tkn_ng_profile        CONSTANT VARCHAR2(20)  := 'NG_PROFILE';    -- 取得に失敗したプロファイル名
  cv_tkn_file_name         CONSTANT VARCHAR2(20)  := 'FILE_NAME';     -- CSVファイル名
  cv_tkn_sqlerrm           CONSTANT VARCHAR2(20)  := 'SQLERRM';       -- SQLエラー
--
  cv_yes                   CONSTANT VARCHAR2(1)   := 'Y';             -- フラグ：有効
  cv_asterisk              CONSTANT VARCHAR2(1)   := '*';             -- アスタリスク
  cv_percent               CONSTANT VARCHAR2(1)   := '%';             -- パーセント
  cv_comma                 CONSTANT VARCHAR2(1)   := ',';             -- 区切り文字
  cv_dqu                   CONSTANT VARCHAR2(1)   := '"';             -- 括り文字
--
  -- 日付書式
  cv_date_fmt_full         CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS'; -- 日付書式：YYYY/MM/DD HH24:MI:SS
--
  -- 区分
  cv_kbn_seisakugun        CONSTANT VARCHAR2(2)   := '01';            -- 区分：政策群
  cv_kbn_youkigun          CONSTANT VARCHAR2(2)   := '02';            -- 区分：容器群
--
  -- レベル
  cv_lv_2                  CONSTANT VARCHAR2(1)   := '2';             -- レベル：2
  -- 文字長
  cn_first                 CONSTANT NUMBER        := 1;               -- 開始位置
  cn_cd_length             CONSTANT NUMBER        := 10;              -- コード
  cn_nm_length             CONSTANT NUMBER        := 20;              -- 名称
--
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_file_dir              VARCHAR2(1000);        -- CSVファイル出力先
  gv_file_name             VARCHAR2(30);          -- CSVファイル名
  gf_file_handler          UTL_FILE.FILE_TYPE;    -- ファイル・ハンドル
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2          -- エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2          -- リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2          -- ユーザー・エラー・メッセージ --# 固定 #
  )
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
    lb_fexists              BOOLEAN;                -- ファイル存在判断
    ln_file_length          NUMBER;                 -- ファイルの文字列数
    lbi_block_size          BINARY_INTEGER;         -- ブロックサイズ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカルユーザー定義例外 ***
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
    -- 入力パラメータなしメッセージ出力
    -- ===============================
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appl_name_xxccp          -- アプリケーション短縮名
                 ,iv_name         => cv_msg_xxccp_90008          -- メッセージ
                 );
    -- メッセージ出力
    xxcmm_004common_pkg.put_message(
      iv_message_buff => gv_out_msg
     ,ov_errbuf       => lv_errbuf
     ,ov_retcode      => lv_retcode
     ,ov_errmsg       => lv_errmsg
    );
    -- 空行挿入
    xxcmm_004common_pkg.put_message(
      iv_message_buff => ''
     ,ov_errbuf       => lv_errbuf
     ,ov_retcode      => lv_retcode
     ,ov_errmsg       => lv_errmsg
    );
--
    -- ===============================
    -- プロファイル取得
    -- ===============================
    -- CSVファイル出力先
    gv_file_dir := FND_PROFILE.VALUE(cv_prf_file_dir);
    -- 取得値がNULLの場合
    IF ( gv_file_dir IS NULL ) THEN
      -- プロファイル取得エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm       -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_00002       -- メッセージ
                    ,iv_token_name1  => cv_tkn_ng_profile        -- トークンコード1
                    ,iv_token_value1 => cv_prf_file_dir          -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- CSVファイル名
    gv_file_name := FND_PROFILE.VALUE(cv_prf_file_name);
    -- 取得値がNULLの場合
    IF ( gv_file_name IS NULL ) THEN
      -- プロファイル取得エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm       -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_00002       -- メッセージ
                    ,iv_token_name1  => cv_tkn_ng_profile        -- トークンコード1
                    ,iv_token_value1 => cv_prf_file_name         -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- CSVファイル名出力
    -- ===============================
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appl_name_xxcmm          -- アプリケーション短縮名
                 ,iv_name         => cv_msg_xxcmm_00022          -- メッセージ
                 ,iv_token_name1  => cv_tkn_file_name            -- トークンコード1
                 ,iv_token_value1 => gv_file_name                -- トークン値1
                 );
    -- メッセージ出力
    xxcmm_004common_pkg.put_message(
      iv_message_buff => gv_out_msg
     ,ov_errbuf       => lv_errbuf
     ,ov_retcode      => lv_retcode
     ,ov_errmsg       => lv_errmsg
    );
--
    -- ===============================
    -- CSVファイル存在チェック
    -- ===============================
    UTL_FILE.FGETATTR(
      location     => gv_file_dir
     ,filename     => gv_file_name
     ,fexists      => lb_fexists
     ,file_length  => ln_file_length
     ,block_size   => lbi_block_size
    );
    -- ファイルが存在する場合
    IF ( lb_fexists = TRUE ) THEN
      -- CSVファイル存在エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm       -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_10482       -- メッセージ
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
   * Procedure Name   : file_open
   * Description      : ファイルオープン処理(A-2)
   ***********************************************************************************/
  PROCEDURE file_open(
    ov_errbuf       OUT VARCHAR2            --   エラー・メッセージ                  --# 固定 #
   ,ov_retcode      OUT VARCHAR2            --   リターン・コード                    --# 固定 #
   ,ov_errmsg       OUT VARCHAR2            --   ユーザー・エラー・メッセージ        --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'file_open'; -- プログラム名
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
    cv_file_mode     CONSTANT VARCHAR2(1) := 'W';    -- 書き込みモード
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカルユーザー定義例外 ***
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
      -- ファイルオープン
      gf_file_handler := UTL_FILE.FOPEN(
                           location  => gv_file_dir     -- ディレクトリ
                          ,filename  => gv_file_name    -- ファイル名
                          ,open_mode => cv_file_mode    -- モード
                         );
    EXCEPTION
      WHEN OTHERS THEN
        -- ファイルオープンエラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm      -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_00487      -- メッセージ
                      ,iv_token_name1  => cv_tkn_sqlerrm          -- トークンコード1
                      ,iv_token_value1 => SQLERRM                 -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
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
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END file_open;
--
  /**********************************************************************************
   * Procedure Name   : put_csv_data
   * Description      : 諸マスタ情報取得処理(A-3)・CSVファイル出力処理(A-4)
   ***********************************************************************************/
  PROCEDURE put_csv_data(
    ov_errbuf       OUT VARCHAR2            --   エラー・メッセージ                  --# 固定 #
   ,ov_retcode      OUT VARCHAR2            --   リターン・コード                    --# 固定 #
   ,ov_errmsg       OUT VARCHAR2            --   ユーザー・エラー・メッセージ        --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_csv_data'; -- プログラム名
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
    cv_goukei                CONSTANT VARCHAR2(4)   := xxccp_common_pkg.get_msg(cv_appl_name_xxcmm ,cv_msg_xxcmm_10483);
                                                           -- 合計
    cv_kei                   CONSTANT VARCHAR2(2)   := xxccp_common_pkg.get_msg(cv_appl_name_xxcmm ,cv_msg_xxcmm_10484);
                                                           -- 計
--
    -- *** ローカル変数 ***
    lv_coordinated_date      VARCHAR2(30)    := NULL;      -- 連携日付
    lv_csv_line              VARCHAR2(4095)  := NULL;      -- 出力文字列格納用変数
--
    lv_code                  VARCHAR2(10);      -- コード
    lv_name                  VARCHAR2(20);      -- 名称
--
    -- *** ローカル・カーソル ***
    -- 諸マスタ情報取得カーソル
    CURSOR var_data_cur
    IS
      SELECT var_data.kbn           AS kbn
            ,var_data.code          AS code
            ,var_data.name          AS name
      FROM (
             -- 政策群
             SELECT cv_kbn_seisakugun      AS kbn
                   ,flv.lookup_code        AS code
                   ,flv.description        AS name
             FROM   fnd_lookup_values_vl flv
             WHERE  flv.lookup_type  = cv_lookup_band_code     -- 政策群
             AND    flv.attribute2   = cv_lv_2                 -- レベル：2
             AND    flv.enabled_flag = cv_yes
             AND    TRUNC(SYSDATE)
                      BETWEEN NVL(flv.start_date_active ,TRUNC(SYSDATE))
                          AND NVL(flv.end_date_active   ,TRUNC(SYSDATE))
             UNION ALL
             -- 容器群
             SELECT cv_kbn_youkigun        AS kbn
                   ,flv.lookup_code        AS code
                   ,flv.meaning            AS name
             FROM   fnd_lookup_values_vl flv
             WHERE  flv.lookup_type  = cv_lookup_itm_yokigun   -- 容器群
             AND    flv.attribute1   IS NULL                   -- 容器区分：NULL
             AND    flv.enabled_flag = cv_yes
             AND    TRUNC(SYSDATE)
                      BETWEEN NVL(flv.start_date_active ,TRUNC(SYSDATE))
                          AND NVL(flv.end_date_active   ,TRUNC(SYSDATE))
           ) var_data
      ORDER BY
        var_data.kbn    ASC   -- 区分
       ,var_data.code   ASC   -- コード
      ;
    -- 諸マスタ情報取得カーソルレコード型
    var_data_rec var_data_cur%ROWTYPE;
--
    -- *** ローカル・レコード ***
--
    -- *** ローカルユーザー定義例外 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 連携日付
    lv_coordinated_date := TO_CHAR(SYSDATE, cv_date_fmt_full);
--
    -- 諸マスタ情報取得カーソルループ
    << var_data_loop >>
    FOR var_data_rec IN var_data_cur
    LOOP
--
      -- 対象件数カウント
      gn_target_cnt := gn_target_cnt + 1;
--
      -- ローカル変数の初期化
      lv_code     := NULL;    -- コード
      lv_name     := NULL;    -- 名称
      lv_csv_line := NULL;    -- 出力文字列格納用変数
--
      -- ===============================
      -- 出力文字列編集
      -- ===============================
      -- コード
      lv_code := SUBSTRB( RTRIM( REPLACE( var_data_rec.code, cv_asterisk ,'' ) ) ,cn_first ,cn_cd_length );
--
      -- 名称
--  2018/03/07 V1.1 Modified START
--      IF ( var_data_rec.name LIKE cv_percent || cv_goukei ) THEN
      IF  ( var_data_rec.name LIKE cv_percent || cv_goukei
            OR
            LENGTHB( lv_code ) = 2
          )
      THEN
--  2018/03/07 V1.1 Modified END
        lv_name := SUBSTRB( RTRIM( var_data_rec.name ) ,cn_first ,cn_nm_length );
      ELSE
        lv_name := SUBSTRB( RTRIM( REPLACE( var_data_rec.name, cv_kei ,'' ) ) ,cn_first ,cn_nm_length );
      END IF;
--
      -- 出力文字列結合
      lv_csv_line := cv_dqu || var_data_rec.kbn || cv_dqu;                                 -- 区分
      lv_csv_line := lv_csv_line || cv_comma || cv_dqu || lv_code || cv_dqu;               -- コード
      lv_csv_line := lv_csv_line || cv_comma || cv_dqu || lv_name || cv_dqu;               -- 名称
      lv_csv_line := lv_csv_line || cv_comma || cv_dqu || lv_coordinated_date || cv_dqu;   -- 連携日付
--
      -- ===============================
      -- CSVファイル出力
      -- ===============================
      BEGIN
        UTL_FILE.PUT_LINE(
          file   => gf_file_handler   -- ファイル
         ,buffer => lv_csv_line       -- 出力文字列格納用変数
        );
      EXCEPTION
        WHEN OTHERS THEN
          -- ファイル書き込みエラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm      -- アプリケーション短縮名
                        ,iv_name         => cv_msg_xxcmm_00488      -- メッセージ
                        ,iv_token_name1  => cv_tkn_sqlerrm          -- トークンコード1
                        ,iv_token_value1 => SQLERRM                 -- トークン値1
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
--
      -- 成功件数カウント
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP var_data_loop;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
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
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END put_csv_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2      -- エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2      -- リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
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
    -- *** ローカル変数 ***
--
    -- *** ローカルユーザー定義例外 ***
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
--
    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    init(
      ov_errbuf          => lv_errbuf           -- エラー・メッセージ
     ,ov_retcode         => lv_retcode          -- リターン・コード
     ,ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ファイルオープン処理(A-2)
    -- ===============================
    file_open(
      ov_errbuf          => lv_errbuf           -- エラー・メッセージ
     ,ov_retcode         => lv_retcode          -- リターン・コード
     ,ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 諸マスタ情報取得処理(A-3)・CSVファイル出力処理(A-4)
    -- ===============================
    put_csv_data(
      ov_errbuf          => lv_errbuf           -- エラー・メッセージ
     ,ov_retcode         => lv_retcode          -- リターン・コード
     ,ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 終了処理(A-5)
    -- ===============================
    BEGIN
      -- ファイルクローズ処理
      IF (UTL_FILE.IS_OPEN(gf_file_handler)) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(gf_file_handler);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        IF ( lv_retcode = cv_status_error ) THEN
          -- コンカレントメッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg --ユーザー・エラーメッセージ
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errbuf --エラーメッセージ
          );
        END IF;
        -- ファイルクローズエラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm      -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_00489      -- メッセージ
                      ,iv_token_name1  => cv_tkn_sqlerrm          -- トークンコード1
                      ,iv_token_value1 => SQLERRM                 -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
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
    errbuf                  OUT VARCHAR2      --   エラー・メッセージ  --# 固定 #
   ,retcode                 OUT VARCHAR2      --   リターン・コード    --# 固定 #
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
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      ov_errbuf             => lv_errbuf                -- エラー・メッセージ           --# 固定 #
     ,ov_retcode            => lv_retcode               -- リターン・コード             --# 固定 #
     ,ov_errmsg             => lv_errmsg                -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --===============================================
    -- 終了処理(A-5)
    --===============================================
    --エラー出力
    IF ( lv_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf
      );
      --空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      -- 件数カウント
      gn_target_cnt := 0;  -- 対象件数
      gn_normal_cnt := 0;  -- 成功件数
      gn_error_cnt  := 1;  -- エラー件数
    END IF;
--
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
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスが正常以外の場合はROLLBACK
    IF ( retcode <> cv_status_normal ) THEN
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
END XXCMM004A14C;
/
