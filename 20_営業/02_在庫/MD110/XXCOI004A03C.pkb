CREATE OR REPLACE PACKAGE BODY XXCOI004A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcoi004a03c(body)
 * Description      : 月次スライド
 * MD.050           : 月次スライド MD050_COI_004_A03
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理          (A-1)
 *  upd_vd_column_mst      VDコラムマスタ更新(A-4)
 *  submain                メイン処理プロシージャ(A-2,A-3)
 *  main                   コンカレント実行ファイル登録プロシージャ(A-5)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/09    1.0   SCS H.Wada       新規作成
 *  2009/12/14    1.1   T.Murakami       [E_本稼動_00271]ロック取得の対象を変更
 *  2010/03/02    1.2   T.Murakami       [E_本稼動_01773]月次スライドに中止顧客を追加する
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  gv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  gv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
  --WHOカラム
  gn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  gd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  gn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  gd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  gn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  gn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  gn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  gn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  gd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
  lock_expt          EXCEPTION;     -- ロック取得エラー
--
  -- プラグマ
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCOI004A03C'; -- パッケージ名
--
  -- ===============================
  -- メッセージ
  -- ===============================
  -- アプリケーション短縮名
  gv_msg_kbn_coi   CONSTANT VARCHAR2(5)  := 'XXCOI';
  gv_msg_kbn_ccp   CONSTANT VARCHAR2(5)  := 'XXCCP';
--
  -- メッセージ番号
  gv_msg_ccp_00    CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90000';   -- 対象件数メッセージ
  gv_msg_ccp_01    CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90001';   -- 成功件数メッセージ
  gv_msg_ccp_02    CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90002';   -- エラー件数メッセージ
  gv_msg_ccp_04    CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90004';   -- 正常終了メッセージ
  gv_msg_ccp_06    CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90006';   -- エラー終了全ロールバックメッセージ
  gv_msg_ccp_08    CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90008';   -- コンカレント入力パラメータなしメッセージ
--
  gv_msg_coi_08    CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00008';   -- 対象データ無しメッセージ
  gv_msg_coi_24    CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10024';   -- ロックエラーメッセージ
--
  -- トークン
  gv_tkn_count     CONSTANT VARCHAR2(5)  := 'COUNT';
--
--
  /**********************************************************************************
   * Procedure Name   : upd_vd_column_mst
   * Description      : VDコラムマスタ更新(A-4)
   ***********************************************************************************/
  PROCEDURE upd_vd_column_mst(
    it_rowid     IN   ROWID       -- 1.ROWID
   ,ov_errbuf    OUT  VARCHAR2    -- 2.エラー・メッセージ           --# 固定 #
   ,ov_retcode   OUT  VARCHAR2    -- 3.リターン・コード             --# 固定 #
   ,ov_errmsg    OUT  VARCHAR2)   -- 4.ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_vd_column_mst'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 更新処理
    UPDATE xxcoi_mst_vd_column                  xvcm
    SET    xvcm.last_month_item_id            = xvcm.item_id              -- 1.前月末品目ID
          ,xvcm.last_month_inventory_quantity = xvcm.inventory_quantity   -- 2.前月末基準在庫数
          ,xvcm.last_month_price              = xvcm.price                -- 3.前月末単価
          ,xvcm.last_month_hot_cold           = xvcm.hot_cold             -- 4.前月末H/C
          ,xvcm.last_update_date              = gd_last_update_date       -- 5.最終更新日
          ,xvcm.last_updated_by               = gn_last_updated_by        -- 6.最終更新者
          ,xvcm.last_update_login             = gn_last_update_login      -- 7.最終更新ユーザ
          ,xvcm.request_id                    = gn_request_id             -- 8.要求ID
          ,xvcm.program_application_id        = gn_program_application_id -- 9.プログラムアプリケーションID
          ,xvcm.program_id                    = gn_program_id             -- 10.プログラムID
          ,xvcm.program_update_date           = gd_program_update_date    -- 11.プログラム更新日
    WHERE  xvcm.rowid                         = it_rowid;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END upd_vd_column_mst;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf    OUT  VARCHAR2    -- 1.エラー・メッセージ           --# 固定 #
   ,ov_retcode   OUT  VARCHAR2    -- 2.リターン・コード             --# 固定 #
   ,ov_errmsg    OUT  VARCHAR2)   -- 3.ユーザー・エラー・メッセージ --# 固定 #
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
    -- *** ローカル変数 ***
    lv_message VARCHAR2(5000);  -- 出力メッセージ
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 入力パラメータ無しメッセージ
    lv_message := xxccp_common_pkg.get_msg(
                    iv_application  => gv_msg_kbn_ccp
                   ,iv_name         => gv_msg_ccp_08
                  );
    -- ファイルに出力
    FND_FILE.PUT_LINE(
      which => FND_FILE.OUTPUT
     ,buff  => lv_message
    );
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf    OUT  VARCHAR2    -- 1.エラー・メッセージ           --# 固定 #
   ,ov_retcode   OUT  VARCHAR2    -- 2.リターン・コード             --# 固定 #
   ,ov_errmsg    OUT  VARCHAR2)   -- 3.ユーザー・エラー・メッセージ --# 固定 #
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
    -- ローカル・カーソル
    -- ===============================
    -- VDコラム情報カーソル
    CURSOR vd_column_info_cur
    IS
      SELECT xvcm.rowid         AS xvcm_rowid
      FROM   xxcoi_mst_vd_column   xvcm   -- 1.VDコラムマスタ
            ,hz_cust_accounts      hca    -- 2.顧客アカウント
            ,hz_parties            hp     -- 3.パーティマスタ
      WHERE  xvcm.customer_id    = hca.cust_account_id
      AND    hca.party_id        = hp.party_id
-- == 2010/03/02 V1.2 Modified START ===============================================================
--      AND    hp.duns_number_c   IN (30, 40, 50, 80)
-- == 2010/03/02 V1.2 Modified END ===============================================================
-- == 2009/12/03 V1.1 Modified START ===============================================================
--      FOR UPDATE NOWAIT;
      FOR UPDATE OF xvcm.vd_column_mst_id NOWAIT;
-- == 2009/12/03 V1.1 Modified END   ===============================================================
--
    -- VDコラム情報レコード型
    vd_column_info_rec vd_column_info_cur%ROWTYPE;
--
    -- 例外
    no_date_expt       EXCEPTION;     -- 対象データ無しエラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    init(
      ov_errbuf  => lv_errbuf         -- 1.エラー・メッセージ           --# 固定 #
     ,ov_retcode => lv_retcode        -- 2.リターン・コード             --# 固定 #
     ,ov_errmsg  => lv_errmsg);       -- 3.ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = gv_status_normal) THEN
      null;
    ELSE
      RAISE global_api_expt;
    END IF;
--
    OPEN vd_column_info_cur;
--
    -- VDコラム情報取得ループ
    <<get_column_loop>>
    LOOP
      -- ===============================
      -- VDコラム情報取得(A-2)
      -- ロック取得(A-3)
      -- ===============================
      FETCH vd_column_info_cur INTO vd_column_info_rec;
      EXIT WHEN vd_column_info_cur%NOTFOUND;
--
      -- 対象件数のカウントアップ
      gn_target_cnt := gn_target_cnt + 1;
--
      -- ===============================
      -- VDコラムマスタ更新(A-4)
      -- ===============================
      upd_vd_column_mst(
        it_rowid   => vd_column_info_rec.xvcm_rowid   -- 1.ROWID
       ,ov_errbuf  => lv_errbuf                       -- 2.エラー・メッセージ           --# 固定 #
       ,ov_retcode => lv_retcode                      -- 3.リターン・コード             --# 固定 #
       ,ov_errmsg  => lv_errmsg);                     -- 4.ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = gv_status_error) THEN
        -- エラー件数のカウントアップ
        gn_error_cnt := gn_error_cnt + 1;
        -- 処理部共通例外ハンドラへ遷移
        RAISE global_process_expt;
      ELSIF (lv_retcode = gv_status_normal) THEN
        -- 成功件数のカウントアップ
        gn_normal_cnt := gn_normal_cnt + 1;
      END IF;
    END LOOP get_column_loop;
--
    CLOSE vd_column_info_cur;
    -- 取得件数が0件の場合
    IF (gn_target_cnt = 0) THEN
      -- 対象データ無しエラーへ遷移
      RAISE no_date_expt;
    END IF;
--
  EXCEPTION
    -- *** 対象データ無しエラー ***
    WHEN no_date_expt THEN
      -- 対象データ無しメッセージ
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_msg_kbn_coi
                    ,iv_name         => gv_msg_coi_08);
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
    --*** ロック取得エラー ***
    WHEN lock_expt THEN
      -- カーソルがオープンしている場合
      IF (vd_column_info_cur%ISOPEN) THEN
        CLOSE vd_column_info_cur;
      END IF;
      -- エラー件数のカウントアップ
      gn_error_cnt := gn_error_cnt + 1;
      -- ロックエラーメッセージ
      ov_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => gv_msg_kbn_coi
                   ,iv_name         => gv_msg_coi_24
                  );
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--####################################  固定部 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ(A-5)
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf  OUT  VARCHAR2   -- 1.エラーメッセージ #固定#
   ,retcode OUT  VARCHAR2   -- 2.エラーコード     #固定#
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
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf       VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode      VARCHAR2(1);     -- リターン・コード
    lv_errmsg       VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code VARCHAR2(16);    -- ユーザー・メッセージ・コード
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
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      ov_errbuf  => lv_errbuf   -- 1.エラー・メッセージ           --# 固定 #
     ,ov_retcode => lv_retcode  -- 2.リターン・コード             --# 固定 #
     ,ov_errmsg  => lv_errmsg   -- 3.ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => lv_errmsg --ユーザー・エラーメッセージ
    );
    -- ===============================
    -- 終了処理(A-5)
    -- ===============================
    -- 処理結果がエラーの場合
    IF (lv_retcode = gv_status_error) THEN
      -- 対象件数の初期化
      gn_target_cnt := 0;
      -- 成功件数の初期化
      gn_normal_cnt := 0;
    END IF;
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_msg_kbn_ccp
                    ,iv_name         => gv_msg_ccp_00
                    ,iv_token_name1  => gv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => gv_out_msg
    );
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_msg_kbn_ccp
                    ,iv_name         => gv_msg_ccp_01
                    ,iv_token_name1  => gv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => gv_out_msg
    );
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_msg_kbn_ccp
                    ,iv_name         => gv_msg_ccp_02
                    ,iv_token_name1  => gv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => gv_out_msg
    );
    --空行出力
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => ''
    );
    --終了メッセージ
    IF (lv_retcode = gv_status_normal) THEN
      lv_message_code := gv_msg_ccp_04;
    ELSIF(lv_retcode = gv_status_error) THEN
      lv_message_code := gv_msg_ccp_06;
    END IF;
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_msg_kbn_ccp
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = gv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCOI004A03C;
/
