CREATE OR REPLACE PACKAGE BODY XXWIPQTTEST
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2007. All rights reserved.
 *
 * Package Name     : XXWIPQTTEST(body)
 * Description      : xxwip_common_pkg.make_qt_inspectionテスト用コンカレント
 * MD.050           : -
 * MD.070           : -
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 * 2007/12/03     1.0   H.Itou            新規作成
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
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'XXWIPQTTEST'; -- パッケージ名
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_division          IN  VARCHAR2, -- IN  1.区分         必須（1:生産 2:発注 3:ロット情報 4:外注出来高 5:荒茶製造）
    iv_disposal_div      IN  VARCHAR2, -- IN  2.処理区分     必須（1:追加 2:更新 3:削除）
    iv_lot_id            IN  VARCHAR2, -- IN  3.ロットID     必須
    iv_item_id           IN  VARCHAR2, -- IN  4.品目ID       必須
    iv_qt_object         IN  VARCHAR2, -- IN  5.対象先       区分:5のみ必須（1:荒茶品目 2:副産物１ 3:副産物２ 4:副産物３）
    iv_batch_id          IN  VARCHAR2, -- IN  6.生産バッチID 区分:1のみ必須
    iv_batch_po_id       IN  VARCHAR2, -- IN  7.明細番号     区分:2のみ必須
    iv_qty               IN  VARCHAR2, -- IN  8.数量         区分:2のみ必須
    iv_prod_dely_date    IN  VARCHAR2, -- IN  9.納入日       区分:2のみ必須
    iv_vendor_line       IN  VARCHAR2, -- IN 10.仕入先コード 区分:2のみ必須
    iv_qt_inspect_req_no IN  VARCHAR2  -- IN 11.検査依頼No   処理区分:2、3のみ必須
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
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lt_qt_inspect_req_no xxwip_qt_inspection.qt_inspect_req_no%TYPE;  -- 検査依頼No
--
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- ======================
    -- 固定出力用変数セット
    -- ======================
    --実行ユーザ名取得
    gv_exec_user := fnd_global.user_name;
    --実行コンカレント名取得
    SELECT fcp.concurrent_program_name
    INTO   gv_conc_name
    FROM   fnd_concurrent_programs fcp
    WHERE  fcp.application_id        = fnd_global.prog_appl_id
    AND    fcp.concurrent_program_id = fnd_global.conc_program_id
    AND    ROWNUM                    = 1;
--
    -- ======================
    -- 固定出力
    -- ======================
    --実行ユーザ名出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00001','USER',gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);

    --実行コンカレント名出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00002','CONC',gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);

    --起動時間出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118',
                                           'TIME', TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);

    --区切り文字出力
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_sep_msg);
--
--###########################  固定部 END   #############################
--
    -- ==================================
    -- 品質検査依頼情報作成実行
    -- ==================================
    xxwip_common_pkg.make_qt_inspection(
      it_division          => iv_division
     ,iv_disposal_div      => iv_disposal_div
     ,it_lot_id            => TO_NUMBER(iv_lot_id)
     ,it_item_id           => TO_NUMBER(iv_item_id)
     ,iv_qt_object         => iv_qt_object
     ,it_batch_id          => TO_NUMBER(iv_batch_id)
     ,it_batch_po_id       => TO_NUMBER(iv_batch_po_id)
     ,it_qty               => TO_NUMBER(iv_qty)
     ,it_prod_dely_date    => TO_DATE(iv_prod_dely_date,'YYYYMMDD')
     ,it_vendor_line       => iv_vendor_line
     ,it_qt_inspect_req_no => TO_NUMBER(iv_qt_inspect_req_no)
     ,ot_qt_inspect_req_no => lt_qt_inspect_req_no
     ,ov_errbuf            => lv_errbuf
     ,ov_retcode           => lv_retcode
     ,ov_errmsg            => lv_errmsg
      );
--
    -- ===================================
    -- OUTパラメータ出力
    -- ===================================
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'検査依頼No :' || lt_qt_inspect_req_no);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'ov_errbuf  :' || lv_errbuf);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'ov_retcode :' || lv_retcode);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'ov_errmsg  :' || lv_errmsg);
--
--###########################  固定部 START   #####################################################
--
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
END XXWIPQTTEST;
/
