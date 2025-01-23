CREATE OR REPLACE PACKAGE BODY XXCOS010A15C
AS
/*************************************************************************
 * Copyright(c)SCSK Corporation, 2024. All rights reserved.
 * 
 * Package Name    : XXCOS010A15C(body)
 * Description     : PaaS明細番号連携処理
 * MD.050          : T_MD050_COS_010_A15_PaaS明細番号連携処理
 * Version         : 1.0
 * 
 * Program List
 * -------------------- -----------------------------------------------------
 *  Name                Description
 * -------------------- -----------------------------------------------------
 *  init                初期処理(A-1)
 *  update_order_line   受注明細の更新処理(A-3)
 *  update_mng_tbl      管理テーブル更新処理(A-4)
 *  submain             メイン処理プロシージャ
 *  main                コンカレント実行ファイル登録プロシージャ
 * 
 * Change Record
 * ------------- ----- ------------- -------------------------------------
 *  Date          Ver.  Editor        Description
 * ------------- ----- ------------- -------------------------------------
 *  2024-10-08    1.0   Y.Ooyama      初回作成
 *
 ************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- 異常:2
  --WHOカラム
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                 -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                            -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;         -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;            -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;         -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                            -- PROGRAM_UPDATE_DATE
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
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  -- ロックエラー
  lock_expt EXCEPTION;
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(15) := 'XXCOS010A15C';        -- パッケージ名
  -- アプリケーション短縮名
  cv_appl_xxcos      CONSTANT VARCHAR2(5)  := 'XXCOS';               -- アドオン：販売領域
  -- 連携処理管理テーブル向け
  cv_func_id         CONSTANT VARCHAR2(15) := 'XXCOS010A15C';        -- 機能ID
  -- メッセージ
  cv_msg_cos1_00001  CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00001';    -- ロックエラーメッセージ
  cv_msg_cos1_16001  CONSTANT VARCHAR2(20) := 'APP-XXCOS1-16001';    -- 前回処理日時取得エラーメッセージ
  cv_msg_cos1_16002  CONSTANT VARCHAR2(20) := 'APP-XXCOS1-16002';    -- 処理日時出力メッセージ
  cv_msg_cos1_00011  CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00011';    -- 更新エラーメッセージ
  -- トークンメッセージ
  cv_msg_cos1_11524  CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11524';    -- 受注明細
  cv_msg_cos1_16010  CONSTANT VARCHAR2(20) := 'APP-XXCOS1-16010';    -- 連携処理管理テーブル
  cv_msg_cos1_10258  CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10258';    -- 受注明細ID
  -- トークン
  cv_tkn_date1       CONSTANT VARCHAR2(20) := 'DATE1';               -- 日時1
  cv_tkn_date2       CONSTANT VARCHAR2(20) := 'DATE2';               -- 日時2
  cv_tkn_count       CONSTANT VARCHAR2(20) := 'COUNT';               -- 件数
  cv_tkn_table       CONSTANT VARCHAR2(20) := 'TABLE';               -- テーブル名
  cv_tkn_table_nm    CONSTANT VARCHAR2(20) := 'TABLE_NAME';          -- テーブル名
  cv_tkn_key_data    CONSTANT VARCHAR2(20) := 'KEY_DATA';            -- キーデータ
  -- 処理日書式
  cv_datetime_fmt    CONSTANT VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS';
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_cur_proc_date            DATE;               -- 今回処理日時
  gd_pre_proc_date            DATE;               -- 前回処理日時
--
  -- ==============================
  -- ユーザー定義グローバルカーソル
  -- ==============================
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      ov_errbuf               OUT VARCHAR2     -- エラー・メッセージ            # 固定 #
    , ov_retcode              OUT VARCHAR2     -- リターン・コード              # 固定 #
    , ov_errmsg               OUT VARCHAR2)    -- ユーザー・エラー・メッセージ  # 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf    VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode   VARCHAR2(1);     -- リターン・コード
    lv_errmsg    VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- *** ローカル変数 ***
    -- *** ローカル・カーソル ***
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
    ----------------------------------------------
    -- 今回処理日時を取得
    ----------------------------------------------
    gd_cur_proc_date := SYSDATE;
    --
    ----------------------------------------------
    -- 前回処理日時を取得
    ----------------------------------------------
    BEGIN
      SELECT
          xipm.pre_process_date          -- 前回処理日時
      INTO
          gd_pre_proc_date
      FROM
          xxccp_if_process_mng  xipm     -- 連携処理管理テーブル
      WHERE
          xipm.function_id = cv_func_id  -- 機能ID
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- データが取得できない場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_xxcos             -- アプリケーション短縮名：XXCOS
                       , iv_name         => cv_msg_cos1_16001         -- メッセージ名：前回処理日時取得エラーメッセージ
                     );
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
      WHEN lock_expt THEN
        -- ロックに失敗した場合
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_xxcos             -- アプリケーション短縮名：XXCOS
                       , iv_name         => cv_msg_cos1_00001         -- メッセージ名：ロックエラーメッセージ
                       , iv_token_name1  => cv_tkn_table              -- トークン名1：TABLE
                       , iv_token_value1 => cv_msg_cos1_16010         -- トークン値1：連携処理管理テーブル
                      );
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
    END;
    --
    ----------------------------------------------
    -- 処理日時出力メッセージを出力
    ----------------------------------------------
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_xxcos                -- アプリケーション短縮名：XXCOS
                    , iv_name         => cv_msg_cos1_16002            -- メッセージ名：処理日時出力メッセージ
                    , iv_token_name1  => cv_tkn_date1                 -- トークン名1：DATE1
                    , iv_token_value1 => TO_CHAR(
                                             gd_pre_proc_date
                                           , cv_datetime_fmt
                                         )                            -- トークン値1：前回処理日時
                    , iv_token_name2  => cv_tkn_date2                 -- トークン名2：DATE2
                    , iv_token_value2 => TO_CHAR(
                                             gd_cur_proc_date
                                           , cv_datetime_fmt
                                         )                            -- トークン値2：今回処理日時
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
  END init;
--
--
  /**********************************************************************************
   * Procedure Name   : update_order_line
   * Description      : 受注明細の更新処理(A-3)
   ***********************************************************************************/
  PROCEDURE update_order_line(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_order_line';       -- プログラム名
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
    lt_lock_line_id           oe_order_lines_all.line_id%TYPE;   -- ロック明細ID
    lv_key_info               VARCHAR2(50);                      -- キー情報 (受注明細ID = XXXXX)
    --
    -- *** ローカル・カーソル ***
    ----------------------------------------------
    -- 受注明細番号連携データ抽出カーソル
    ----------------------------------------------
    -- ※受注明細番号連携マテビューには、下記に相当する条件が含まれています。
    --   受注明細番号連携マテビュー．CREATION_DATE（作成日） >= 「前回処理日時」（PaaS明細番号連携処理） - 9/24
    CURSOR get_line_cur
    IS
      SELECT
          oola.line_id                   AS line_id             -- 明細ID
        , xolnim.line_number_paas        AS line_number_paas    -- PAAS受注明細番号
      FROM
          xxcos_order_line_number_if_mv  xolnim                 -- 受注明細番号連携マテビュー
        , oe_order_headers_all           ooha                   -- 受注ヘッダ
        , oe_order_lines_all             oola                   -- 受注明細
      WHERE
          xolnim.order_number_ebs  = ooha.order_number
      AND ooha.header_id           = oola.header_id
      AND xolnim.line_number_ebs   = oola.line_number
      AND xolnim.creation_date     < gd_cur_proc_date - 9/24    -- 作成日 < 今回処理日時(JST->UTC)
      ORDER BY
          xolnim.order_number_ebs  ASC                          -- EBS受注番号(昇順)
        , xolnim.line_number_ebs   ASC                          -- EBS受注明細番号(昇順)
    ;
    --
    -- *** ローカル・レコード ***
    -- 受注明細番号連携データ抽出カーソル・レコード
    l_get_line_rec        get_line_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    ----------------------------------------------
    -- 受注明細番号連携データ抽出(A-2)
    ----------------------------------------------
    -- カーソルオープン
    OPEN get_line_cur;
    <<get_line_loop>>
    LOOP
      --
      FETCH get_line_cur INTO l_get_line_rec;
      EXIT WHEN get_line_cur%NOTFOUND;
      --
      -- 受注明細番号連携データの抽出件数をカウントアップ
      gn_target_cnt := gn_target_cnt + 1;
      --
      ----------------------------------------------
      -- 受注明細の更新処理
      ----------------------------------------------
      BEGIN
        -- ロック
        SELECT
            oola.line_id        AS line_id   -- 明細ID
        INTO
            lt_lock_line_id
        FROM
            oe_order_lines_all  oola         -- 受注明細
        WHERE
            oola.line_id        = l_get_line_rec.line_id
        FOR UPDATE NOWAIT
        ;
        --
        -- 更新
        UPDATE
            oe_order_lines_all  oola  -- 受注明細
        SET
            oola.global_attribute8       = l_get_line_rec.line_number_paas     -- PAAS受注明細番号
          , oola.last_updated_by         = cn_last_updated_by                  -- 最終更新者
          , oola.last_update_date        = cd_last_update_date                 -- 最終更新日
          , oola.last_update_login       = cn_last_update_login                -- 最終更新ログイン
          , oola.request_id              = cn_request_id                       -- 要求ID
          , oola.program_application_id  = cn_program_application_id           -- コンカレント・プログラム・アプリケーションID
          , oola.program_id              = cn_program_id                       -- コンカレント・プログラムID
          , oola.program_update_date     = cd_program_update_date              -- プログラム更新日
        WHERE
            oola.line_id                 = l_get_line_rec.line_id              -- 明細ID
        ;
        --
        -- 受注明細の更新件数をカウントアップ
        gn_normal_cnt := gn_normal_cnt + 1;
      --
      EXCEPTION
        WHEN lock_expt THEN
          -- ロックに失敗した場合
          lv_errmsg  := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_xxcos           -- アプリケーション短縮名：XXCOS
                         , iv_name         => cv_msg_cos1_00001       -- メッセージ名：ロックエラーメッセージ
                         , iv_token_name1  => cv_tkn_table            -- トークン名1：TABLE
                         , iv_token_value1 => cv_msg_cos1_11524       -- トークン値1：受注明細
                        );
          lv_errbuf  := lv_errmsg;
          RAISE global_process_expt;
        WHEN OTHERS THEN
          -- 更新に失敗した場合
          -- キー情報生成
          lv_key_info := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_xxcos         -- アプリケーション短縮名：XXCOS
                           , iv_name         => cv_msg_cos1_10258     -- メッセージ名：受注明細ID
                         );
          lv_key_info := lv_key_info || ' = ' || TO_CHAR(l_get_line_rec.line_id);
          --
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_xxcos           -- アプリケーション短縮名：XXCOS
                         , iv_name         => cv_msg_cos1_00011       -- メッセージ名：更新エラーメッセージ
                         , iv_token_name1  => cv_tkn_table_nm         -- トークン名1：TABLE_NAME
                         , iv_token_value1 => cv_msg_cos1_11524       -- トークン値1：受注明細
                         , iv_token_name2  => cv_tkn_key_data         -- トークン名2：KEY_DATA
                         , iv_token_value2 => lv_key_info             -- トークン値2：キー情報
                       );
          lv_errbuf  := lv_errmsg;
          RAISE global_process_expt;
      END;
    --
    END LOOP get_line_loop;
    --
    -- 抽出カーソルクローズ
    CLOSE get_line_cur;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- 抽出カーソルクローズ
      IF ( get_line_cur%ISOPEN ) THEN
        CLOSE get_line_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- 抽出カーソルクローズ
      IF ( get_line_cur%ISOPEN ) THEN
        CLOSE get_line_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- 抽出カーソルクローズ
      IF ( get_line_cur%ISOPEN ) THEN
        CLOSE get_line_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- 抽出カーソルクローズ
      IF ( get_line_cur%ISOPEN ) THEN
        CLOSE get_line_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END update_order_line;
--
--
  /**********************************************************************************
   * Procedure Name   : update_mng_tbl
   * Description      : 管理テーブル更新処理(A-4)
   ***********************************************************************************/
  PROCEDURE update_mng_tbl(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_mng_tbl';       -- プログラム名
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
    -- *** ローカル・カーソル ***
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
    ----------------------------------------------
    -- 連携処理管理テーブルの更新
    ----------------------------------------------
    BEGIN
      -- 更新
      UPDATE
          xxccp_if_process_mng  xipm    -- 連携処理管理テーブル
      SET
          xipm.pre_process_date       = gd_cur_proc_date              -- 前回処理日時 = A-1で取得した今回処理日時
        , xipm.last_updated_by        = cn_last_updated_by            -- 最終更新者
        , xipm.last_update_date       = cd_last_update_date           -- 最終更新日
        , xipm.last_update_login      = cn_last_update_login          -- 最終更新ログイン
        , xipm.request_id             = cn_request_id                 -- 要求ID
        , xipm.program_application_id = cn_program_application_id     -- プログラムアプリケーションID
        , xipm.program_id             = cn_program_id                 -- プログラムID
        , xipm.program_update_date    = cd_program_update_date        -- プログラム更新日
      WHERE
          xipm.function_id            = cv_func_id                    -- 機能ID
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- 更新に失敗した場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_xxcos             -- アプリケーション短縮名：XXCOS
                       , iv_name         => cv_msg_cos1_00011         -- メッセージ名：更新エラーメッセージ
                       , iv_token_name1  => cv_tkn_table_nm           -- トークン名1：TABLE_NAME
                       , iv_token_value1 => cv_msg_cos1_16010         -- トークン値1：連携処理管理テーブル
                       , iv_token_name2  => cv_tkn_key_data           -- トークン名2：KEY_DATA
                       , iv_token_value2 => NULL                      -- トークン値2：NULL
                     );
        lv_errbuf  := lv_errmsg;
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
  END update_mng_tbl;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
      ov_errbuf               OUT VARCHAR2     -- エラー・メッセージ            # 固定 #
    , ov_retcode              OUT VARCHAR2     -- リターン・コード              # 固定 #
    , ov_errmsg               OUT VARCHAR2)    -- ユーザー・エラー・メッセージ  # 固定 #
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
    -- *** ローカル変数 ***
    -- *** ローカル・カーソル ***
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
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    --
    -- ======================================================
    --  初期処理(A-1)
    -- ======================================================
    init(
        ov_errbuf        => lv_errbuf        -- エラー・メッセージ
      , ov_retcode       => lv_retcode       -- リターン・コード
      , ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- ======================================================
    --  受注明細の更新処理(A-3)
    --  ※受注明細番号連携データ抽出(A-2)含む
    -- ======================================================
    update_order_line(
        ov_errbuf        => lv_errbuf        -- エラー・メッセージ
      , ov_retcode       => lv_retcode       -- リターン・コード
      , ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- ======================================================
    --  管理テーブル更新処理(A-4)
    -- ======================================================
    update_mng_tbl(
        ov_errbuf        => lv_errbuf        -- エラー・メッセージ
      , ov_retcode       => lv_retcode       -- リターン・コード
      , ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ
    );
    --
    IF (lv_retcode = cv_status_error) THEN
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
--####################################  固定部 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
      errbuf                  OUT VARCHAR2      -- エラー・メッセージ   # 固定 #
    , retcode                 OUT VARCHAR2      -- リターン・コード     # 固定 #
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
--    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
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
        lv_errbuf                -- エラー・メッセージ            # 固定 #
      , lv_retcode               -- リターン・コード              # 固定 #
      , lv_errmsg                -- ユーザー・エラー・メッセージ  # 固定 #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      -- エラーあり
      gn_normal_cnt := 0;                 -- 成功件数
      gn_error_cnt  := 1;                 -- エラー件数
      --
      -- エラーメッセージ出力
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_errbuf --エラーメッセージ
      );
      -- 空行挿入
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => ''
      );
    END IF;
    --
    --------------------------
    -- 結果件数を出力
    --------------------------
    -- 対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_target_cnt)
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --
    -- 成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_normal_cnt)
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
                    , iv_token_value1 => TO_CHAR(gn_error_cnt)
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
--    --スキップ件数出力
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_appl_short_name
--                    , iv_name         => cv_skip_rec_msg
--                    , iv_token_name1  => cv_cnt_token
--                    , iv_token_value1 => TO_CHAR(gn_warn_cnt)
--                  );
--    FND_FILE.PUT_LINE(
--        which  => FND_FILE.OUTPUT
--      , buff   => gv_out_msg
--    );
    --
    --------------------------
    -- 終了メッセージ
    --------------------------
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
END XXCOS010A15C;
/
