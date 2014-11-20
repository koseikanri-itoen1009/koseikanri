CREATE OR REPLACE PACKAGE BODY xxwsh420002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh420002c(body)
 * Description      : トリップ/ストップのインタフェース(標準)コールコンカレント
 * MD.050           : トリップ/ストップのインタフェース(標準)コール T_MD050_BPO_420
 * MD.070           : トリップ/ストップのインタフェース(標準)コール T_MD070_BPO_42B
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/09/09    1.0   Y.Suzuki         新規作成
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
  gv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
  gv_mst_normal    CONSTANT VARCHAR2(10) := '正常終了';
  gv_mst_warn      CONSTANT VARCHAR2(10) := '警告終了';
  gv_mst_error     CONSTANT VARCHAR2(10) := '異常終了';
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
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  -- メッセージ用定数
  gv_pkg_name       CONSTANT VARCHAR2(100) := 'xxwsh420002c';                           -- パッケージ名
  gv_app_name       CONSTANT VARCHAR2(5)   := 'XXCMN';                                  -- アプリケーション短縮名
--
  -- メッセージ
  gv_msg_xxcmn10135 CONSTANT VARCHAR2(100) := 'APP-XXCMN-10135';   -- 要求の発行失敗エラー
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf           OUT    VARCHAR2,                -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT    VARCHAR2,                -- リターン・コード             --# 固定 #
    ov_errmsg           OUT    VARCHAR2)                -- ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'submain';               -- プログラム名
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
--
    -- *** ローカル定数 ***
    cv_conc_p_c   CONSTANT VARCHAR2(100) := 'COMPLETE';
    cv_conc_s_w   CONSTANT VARCHAR2(100) := 'WARNING';
    cv_conc_s_e   CONSTANT VARCHAR2(100) := 'ERROR';
    cv_param_all  CONSTANT VARCHAR2(100) := 'ALL';
    cv_param_0    CONSTANT VARCHAR2(100) := '0';
    cv_param_1    CONSTANT VARCHAR2(100) := '1';
--
    -- *** ローカル変数 ***
    lv_phase      VARCHAR2(100);
    lv_status     VARCHAR2(100);
    lv_dev_phase  VARCHAR2(100);
    lv_dev_status VARCHAR2(100);
--
    i             INTEGER := 0;
    TYPE reqid_tab IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    reqid_rec reqid_tab;
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    CURSOR get_org_cur IS
      SELECT DISTINCT TO_CHAR(wnd.organization_id) org_id
      FROM   wsh_new_deliveries wnd
            ,wsh_delivery_legs  wdl
            ,wsh_trip_stops     wts
      WHERE  wnd.delivery_id     = wdl.delivery_id
      AND    wdl.pick_up_stop_id = wts.stop_id
      AND    wts.pending_interface_flag = 'Y';
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    FND_FILE.PUT_LINE (FND_FILE.LOG,'START');
--
    -- 「トリップ/ストップのインタフェース」発行
    <<call_conc>>
    FOR get_org_rec IN get_org_cur LOOP
      i := i + 1;
      reqid_rec(i) := FND_REQUEST.SUBMIT_REQUEST(
                        application       => 'WSH'                -- アプリケーション短縮名
                       ,program           => 'WSHINTERFACES'      -- プログラム名
                       ,argument1         => cv_param_all         -- インタフェース・モード
                       ,argument2         => NULL                 -- インタフェースされているトリップ/ストップ
                       ,argument3         => NULL                 -- インタフェースされた搬送
                       ,argument4         => cv_param_0           -- 要求のログ・レベル
                       ,argument5         => NULL                 -- バッチID
                       ,argument6         => NULL                 -- トリップ・タイプ
                       ,argument7         => get_org_rec.org_id   -- 組織
                       ,argument8         => cv_param_1           -- 要求数
                       ,argument9         => cv_param_1           -- バッチ当りのストップ
                        );
      -- エラーの場合
      IF (reqid_rec(i) = 0) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application   => gv_app_name
                      ,iv_name          => gv_msg_xxcmn10135);
        RAISE global_api_expt;
      ELSE
        COMMIT;
      END IF;
--
    END LOOP call_conc;
--
    FND_FILE.PUT_LINE (FND_FILE.LOG,'CONC EXEC END');
--
    -- コンカレントステータスのチェック
    <<chk_status>>
    FOR j IN 1 .. i LOOP
      IF (FND_CONCURRENT.WAIT_FOR_REQUEST(
            request_id => reqid_rec(j)
           ,interval   => 10
           ,max_wait   => 0
           ,phase      => lv_phase
           ,status     => lv_status
           ,dev_phase  => lv_dev_phase
           ,dev_status => lv_dev_status
           ,message    => lv_errbuf
           ))
      THEN
        -- ステータス反映
        -- フェーズ:完了
        IF (lv_dev_phase = cv_conc_p_c) THEN
          -- ステータス:異常
          IF (lv_dev_status = cv_conc_s_e) THEN
            ov_retcode := gv_status_error;
            FND_FILE.PUT_LINE (FND_FILE.OUTPUT,TO_CHAR(reqid_rec(j))||gv_msg_part||gv_mst_error);
          -- ステータス:警告
          ELSIF (lv_dev_status = cv_conc_s_w) THEN
            IF (ov_retcode < 1) THEN
              ov_retcode := gv_status_warn;
            END IF;
            FND_FILE.PUT_LINE (FND_FILE.OUTPUT,TO_CHAR(reqid_rec(j))||gv_msg_part||gv_mst_warn);
          -- ステータス:正常
          ELSE
            FND_FILE.PUT_LINE (FND_FILE.OUTPUT,TO_CHAR(reqid_rec(j))||gv_msg_part||gv_mst_normal);
          END IF;
        END IF;
      ELSE
        ov_retcode := gv_status_error;
        FND_FILE.PUT_LINE (FND_FILE.OUTPUT,TO_CHAR(reqid_rec(j))||gv_msg_part||gv_mst_error);
      END IF;
--
    END LOOP chk_status;
--
    FND_FILE.PUT_LINE (FND_FILE.LOG,'END');
--
  EXCEPTION
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
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
  PROCEDURE main(
    errbuf              OUT    VARCHAR2,                -- エラー・メッセージ           --# 固定 #
    retcode             OUT    VARCHAR2)                -- リターン・コード             --# 固定 #
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'main';                  -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
  BEGIN
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      lv_errbuf,              -- エラー・メッセージ           --# 固定 #
      lv_retcode,             -- リターン・コード             --# 固定 #
      lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
--
--###########################  固定部 START   #####################################################
--
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = gv_status_error) THEN
      errbuf  := lv_errbuf;
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
END xxwsh420002c;
/
