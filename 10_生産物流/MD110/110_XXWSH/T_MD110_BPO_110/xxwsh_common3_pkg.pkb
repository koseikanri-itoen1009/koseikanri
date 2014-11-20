CREATE OR REPLACE PACKAGE BODY xxwsh_common3_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2007. All rights reserved.
 *
 * Package Name           : xxwsh_common3_pkg(BODY)
 * Description            : 共通関数(BODY)
 * MD.070(CMD.050)        : なし
 * Version                : 1.0
 *
 * Program List
 *  --------------------   ---- ----- --------------------------------------------------
 *   Name                  Type  Ret   Description
 *  --------------------   ---- ----- --------------------------------------------------
 *  wf_whs_start            P          最大配送区分算出関数
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/06/10   1.0   Oracle 野村      新規作成
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
  no_data                   EXCEPTION;
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gn_status_normal CONSTANT NUMBER := 0;
  gn_status_error  CONSTANT NUMBER := 1;
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'xxwsh_common3_pkg'; -- パッケージ名
--
  gv_cnst_com_kbn     CONSTANT VARCHAR2(5)   := 'XXCMN';
--
  -- メッセージID
  gv_cnst_msg_nodata  CONSTANT VARCHAR2(15)  := 'APP-XXCMN-10001'; -- 対象データなし
--
  -- トークン
  gv_tkn_table        CONSTANT VARCHAR2(10)  := 'TABLE';
  gv_tkn_key          CONSTANT VARCHAR2(10)  := 'KEY';
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : get_outbound_info
   * Description      : アウトバウンド処理情報取得関数
   ***********************************************************************************/
  PROCEDURE get_wsh_wf_info(
    iv_wf_ope_div       IN  VARCHAR2,                 -- 処理区分
    iv_wf_class         IN  VARCHAR2,                 -- 対象
    iv_wf_notification  IN  VARCHAR2,                 -- 宛先
    or_wf_whs_rec       OUT NOCOPY wf_whs_rec,        -- ファイル情報
    ov_errbuf           OUT NOCOPY VARCHAR2,          -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,          -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)          -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_wsh_wf_info'; -- プログラム名
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
    cv_wf_noti        CONSTANT VARCHAR2(100) := 'XXCMN_WF_NOTIFICATION';  -- Workflow通知先
    cv_wf_info        CONSTANT VARCHAR2(100) := 'XXCMN_WF_INFO';          -- Workflow情報
    cv_prof_min_date  CONSTANT VARCHAR2(100) := 'XXCMN_MIN_DATE';
--
    -- *** ローカル変数 ***
    lr_wf_whs_rec   wf_whs_rec;   -- wf_whs_rec関連データ
    lv_table_name   VARCHAR2(100);
    lv_value        VARCHAR2(100);
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    BEGIN
      -- 通知先ユーザーを取得
      SELECT  xlv.attribute1,     -- 対象（パラメータと同じ）
              xlv.attribute2,     -- 宛先（パラメータと同じ）
              xlv.attribute3,     -- 宛先１
              xlv.attribute4,     -- 宛先２
              xlv.attribute5,     -- 宛先３
              xlv.attribute6,     -- 宛先４
              xlv.attribute7,     -- 宛先５
              xlv.attribute8,     -- 宛先６
              xlv.attribute9,     -- 宛先７
              xlv.attribute10,    -- 宛先８
              xlv.attribute11,    -- 宛先９
              xlv.attribute12     -- 宛先１０
      INTO    lr_wf_whs_rec.wf_class,
              lr_wf_whs_rec.wf_notification,
              lr_wf_whs_rec.user_cd01,
              lr_wf_whs_rec.user_cd02,
              lr_wf_whs_rec.user_cd03,
              lr_wf_whs_rec.user_cd04,
              lr_wf_whs_rec.user_cd05,
              lr_wf_whs_rec.user_cd06,
              lr_wf_whs_rec.user_cd07,
              lr_wf_whs_rec.user_cd08,
              lr_wf_whs_rec.user_cd09,
              lr_wf_whs_rec.user_cd10
      FROM    xxcmn_lookup_values_v xlv
      WHERE  xlv.lookup_type  = cv_wf_noti          -- Workflow通知先
      AND    xlv.attribute1   = iv_wf_class         -- 対象
      AND    xlv.attribute2   = iv_wf_notification  -- 宛先
      AND    ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- 取得できない場合は、エラー
        lv_table_name := 'xxcmn_lookup_values_v';
        lv_value      :=  cv_wf_noti ||
                          ','         ||
                          iv_wf_class ||
                          ','         ||
                          iv_wf_notification;
--
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_com_kbn,
                                              gv_cnst_msg_nodata,
                                              gv_tkn_table,
                                              lv_table_name,
                                              gv_tkn_key,
                                              lv_value);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END;
--
    BEGIN
      -- ワークフロー情報を取得
      SELECT  xlv.attribute4,     -- WFプロセス
              xlv.attribute5,     -- WFオーナー
              xlv.attribute6,     -- ディレクトリ
              xlv.attribute7,     -- ファイル名
              xlv.attribute8      -- 表示名
      INTO    lr_wf_whs_rec.wf_name,
              lr_wf_whs_rec.wf_owner,
              lr_wf_whs_rec.directory,
              lr_wf_whs_rec.file_name,
              lr_wf_whs_rec.file_display_name
      FROM    xxcmn_lookup_values_v xlv
      WHERE   xlv.lookup_type   = cv_wf_info          -- Workflow情報
      AND     xlv.attribute1    = iv_wf_ope_div       -- 処理区分
      AND     xlv.attribute2    = iv_wf_class         -- 対象
      AND     xlv.attribute3    = iv_wf_notification  -- 宛先
      AND     ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- 取得できない場合は、エラー
        lv_table_name := 'xxcmn_lookup_values_v';
        lv_value      :=  cv_wf_info          ||
                          ','                 ||
                          iv_wf_ope_div       ||
                          ','                 ||
                          iv_wf_class         ||
                          ','                 ||
                          iv_wf_notification;
--
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_com_kbn,
                                              gv_cnst_msg_nodata,
                                              gv_tkn_table,
                                              lv_table_name,
                                              gv_tkn_key,
                                              lv_value);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    or_wf_whs_rec := lr_wf_whs_rec;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
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
  END get_wsh_wf_info;
--
  /**********************************************************************************
   * Procedure Name   : wf_start
   * Description      : ワークフロー起動関数
   ***********************************************************************************/
  PROCEDURE wf_whs_start(
    ir_wf_whs_rec IN  wf_whs_rec,               -- ワークフロー関連情報
    iv_filename   IN  VARCHAR2,                 -- ファイル名
    ov_errbuf     OUT NOCOPY VARCHAR2,          -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,          -- リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)          -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'wf_start'; -- プログラム名
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
    lv_itemkey      VARCHAR2(30);
    lr_wf_whs_rec   wf_whs_rec; -- WF関連データ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    no_wf_info_expt                  EXCEPTION;     -- ワークフロー未設定エラー
    wf_exec_expt                     EXCEPTION;     -- ワークフロー実行エラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --WFタイプで一意となるWFキーを取得
    SELECT TO_CHAR(xxcmn_wf_key_s1.NEXTVAL)
    INTO   lv_itemkey
    FROM   DUAL;
--
    BEGIN
--
      --WFプロセスを作成
      WF_ENGINE.CREATEPROCESS(ir_wf_whs_rec.wf_name, lv_itemkey, ir_wf_whs_rec.wf_name);
      --WFオーナーを設定
      WF_ENGINE.SETITEMOWNER(ir_wf_whs_rec.wf_name, lv_itemkey, ir_wf_whs_rec.wf_owner);
      --WF属性を設定
      WF_ENGINE.SETITEMATTRTEXT(ir_wf_whs_rec.wf_name,
                                  lv_itemkey,
                                  'FILE_NAME',
                                  ir_wf_whs_rec.directory|| ',' || iv_filename );
      WF_ENGINE.SETITEMATTRTEXT(ir_wf_whs_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD01',
                                  ir_wf_whs_rec.user_cd01);
      WF_ENGINE.SETITEMATTRTEXT(ir_wf_whs_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD02',
                                  ir_wf_whs_rec.user_cd02);
      WF_ENGINE.SETITEMATTRTEXT(ir_wf_whs_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD03',
                                  ir_wf_whs_rec.user_cd03);
      WF_ENGINE.SETITEMATTRTEXT(ir_wf_whs_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD04',
                                  ir_wf_whs_rec.user_cd04);
      WF_ENGINE.SETITEMATTRTEXT(ir_wf_whs_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD05',
                                  ir_wf_whs_rec.user_cd05);
      WF_ENGINE.SETITEMATTRTEXT(ir_wf_whs_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD06',
                                  ir_wf_whs_rec.user_cd06);
      WF_ENGINE.SETITEMATTRTEXT(ir_wf_whs_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD07',
                                  ir_wf_whs_rec.user_cd07);
      WF_ENGINE.SETITEMATTRTEXT(ir_wf_whs_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD08',
                                  ir_wf_whs_rec.user_cd08);
      WF_ENGINE.SETITEMATTRTEXT(ir_wf_whs_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD09',
                                  ir_wf_whs_rec.user_cd09);
      WF_ENGINE.SETITEMATTRTEXT(ir_wf_whs_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD10',
                                  ir_wf_whs_rec.user_cd10);
      WF_ENGINE.SETITEMATTRTEXT(ir_wf_whs_rec.wf_name,
                                  lv_itemkey,
                                  'FILE_DISP_NAME',
                                  ir_wf_whs_rec.file_display_name);
      -- 1.1追加
      WF_ENGINE.SETITEMATTRTEXT(ir_wf_whs_rec.wf_name,
                                  lv_itemkey,
                                  'WF_OWNER',
                                  ir_wf_whs_rec.wf_owner);
--
      --WFプロセスを起動
      WF_ENGINE.STARTPROCESS(ir_wf_whs_rec.wf_name, lv_itemkey);
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10117');
        RAISE wf_exec_expt;
    END;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN no_wf_info_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,5000);
      ov_retcode := gv_status_error;
    WHEN wf_exec_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,5000);
      ov_retcode := gv_status_error;
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
  END wf_whs_start;
--
END xxwsh_common3_pkg;
/
