CREATE OR REPLACE PACKAGE BODY APPS.xxwsh420005c
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2011. All rights reserved.
 *
 * Package Name     : xxwsh420005c(body)
 * Description      : 請求OIF削除処理
 * MD.050           : 出荷実績 T_MD050_BPO_420
 * Version          : 1.0
 *
 * Program List
 * ------------------------- ----------------------------------------------------------
 *  Name                      Description
 * ------------------------- ----------------------------------------------------------
 *  init                      初期処理(D-1)
 *  get_oif_data              削除対象件数取得処理(D-2)
 *  del_oif_data              請求OIF削除処理(D-3)
 *  submain                   メイン処理プロシージャ
 *  main                      コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2011/04/19    1.0   SCS 楢原 香織    新規作成
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';    --正常
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';    --警告
  gv_status_error  CONSTANT VARCHAR2(1) := '2';    --失敗
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';    --ステータス(正常)
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';    --ステータス(警告)
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';    --ステータス(失敗)
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_dot       CONSTANT VARCHAR2(3) := '.';
  gv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);            -- 区切り文字
  gv_exec_user     VARCHAR2(100);             -- 実行ユーザ名
  gv_conc_name     VARCHAR2(30);              -- 実行コンカレント名
  gv_conc_status   VARCHAR2(30);              -- 実行結果
--
--################################  固定部 END   ##################################
--
--##########################  固定共通例外宣言部 START  ###########################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --*** 共通関数OTHERS例外 **
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  lock_error_expt             EXCEPTION;     -- ロックエラー
  PRAGMA EXCEPTION_INIT(lock_error_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_msg_kbn             CONSTANT VARCHAR2(5)   := 'XXCMN';
  gv_msg_kbn_wsh         CONSTANT VARCHAR2(5)   := 'XXWSH';
--
  gv_pkg_name            CONSTANT VARCHAR2(100) := 'xxwsh420005c';         -- パッケージ名
--
  --メッセージ番号(固定処理)
  gv_msg_42d_001         CONSTANT VARCHAR2(15)  := 'APP-XXCMN-00001';      -- ユーザー名
  gv_msg_42d_002         CONSTANT VARCHAR2(15)  := 'APP-XXCMN-00002';      -- コンカレント名
  gv_msg_42d_003         CONSTANT VARCHAR2(15)  := 'APP-XXCMN-00003';      -- セパレータ
  gv_msg_42d_004         CONSTANT VARCHAR2(15)  := 'APP-XXCMN-00012';      -- 処理ステータス
  gv_msg_42d_005         CONSTANT VARCHAR2(15)  := 'APP-XXCMN-10030';      -- コンカレント定型エラー
  gv_msg_42d_006         CONSTANT VARCHAR2(15)  := 'APP-XXCMN-10118';      -- 起動時間
--
  --メッセージ番号(現コンカレント専用)
  gv_msg_42d_007         CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11553';      -- プロファイル取得エラー
  gv_msg_42d_008         CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11772';      -- データ取得エラー
  gv_msg_42d_009         CONSTANT VARCHAR2(15)  := 'APP-XXWSH-13403';      -- テーブルロックエラー
  gv_msg_42d_010         CONSTANT VARCHAR2(15)  := 'APP-XXWSH-13173';      -- 対象データなしメッセージ
  gv_msg_42d_011         CONSTANT VARCHAR2(15)  := 'APP-XXWSH-13006';      -- テーブルデータ削除エラー
  gv_msg_42d_012         CONSTANT VARCHAR2(15)  := 'APP-XXCMN-00008';      -- 処理件数メッセージ
  gv_msg_42d_013         CONSTANT VARCHAR2(15)  := 'APP-XXCMN-00009';      -- 成功件数メッセージ
  gv_msg_42d_014         CONSTANT VARCHAR2(15)  := 'APP-XXCMN-00010';      -- エラー件数メッセージ
--
  --トークン(固定処理)
  gv_tkn_status          CONSTANT VARCHAR2(15)  := 'STATUS';
  gv_tkn_conc            CONSTANT VARCHAR2(15)  := 'CONC';
  gv_tkn_user            CONSTANT VARCHAR2(15)  := 'USER';
  gv_tkn_time            CONSTANT VARCHAR2(15)  := 'TIME';
--
  --トークン(現コンカレント専用)
  gv_tkn_prof_name       CONSTANT VARCHAR2(15)  := 'PROF_NAME';            -- プロファイル：XXCOS1_ITOE_OU_MFG
  gv_tkn_data            CONSTANT VARCHAR2(15)  := 'DATA';                 -- 取得データ：生産営業単位ID
  gv_tkn_table           CONSTANT VARCHAR2(15)  := 'TABLE';                -- テーブル名：請求OIF
  gv_tkn_table_name      CONSTANT VARCHAR2(15)  := 'TABLE_NAME';           -- テーブル名：請求OIF
  gv_tkn_cnt             CONSTANT VARCHAR2(15)  := 'CNT';                  -- 件数
--
  -- トークン表示用
  gv_tkn_name_org        CONSTANT VARCHAR2(30)  := '生産営業単位ID';
  gv_tkn_name_oif        CONSTANT VARCHAR2(30)  := '請求OIF';
--
  --プロファイル
  gv_prof_ou_mfg         CONSTANT VARCHAR2(20)  := 'XXCOS1_ITOE_OU_MFG';   -- XXCOS:生産営業単位取得名称
--
  -- クイックコード取得用(ルックアップタイプ)
  gv_cp_status_code      CONSTANT VARCHAR2(30)  := 'CP_STATUS_CODE';       -- ステータス
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 請求OIF情報を格納するレコード
  TYPE g_rec_oif_data IS RECORD(
    interface_line_id   ra_interface_lines_all.interface_line_id%TYPE      -- 請求OIF明細ID
  );
  -- 請求OIF情報を格納する配列
  TYPE g_tab_oif_data IS TABLE OF g_rec_oif_data INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_target_cnt          NUMBER;                                           -- 処理件数
  gn_del_cnt             NUMBER;                                           -- 成功件数
  gn_error_cnt           NUMBER;                                           -- エラー件数
  gv_ou_mfg_name         VARCHAR(200);                                     -- 生産営業単位取得名称
  gt_ou_mfg_id           hr_operating_units.organization_id%TYPE;          -- 生産営業単位ID
  gt_oif_data            g_tab_oif_data;                                   -- 請求OIF情報
--
  /***********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(D-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf       OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode      OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg       OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
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
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ========================================
    -- プロファイル値取得
    -- ========================================
    gv_ou_mfg_name  := FND_PROFILE.VALUE(gv_prof_ou_mfg);  -- XXCOS:生産営業単位取得名称
--
    -- XXCOS:生産営業単位取得名称の取得ができない場合、エラー終了
    IF ( gv_ou_mfg_name IS NULL ) THEN
      -- プロファイル取得エラー
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh,   gv_msg_42d_007,
                                            gv_tkn_prof_name, gv_prof_ou_mfg);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ========================================
    -- 生産営業単位ID取得
    -- ========================================
    BEGIN
      SELECT hou.organization_id  organization_id     -- 営業単位ID
      INTO   gt_ou_mfg_id
      FROM   hr_operating_units   hou                 -- 操作ユニット
      WHERE  hou.name             = gv_ou_mfg_name    -- XXCOS:生産営業単位取得名称
      ;
    EXCEPTION
      -- データが取得できない場合、エラー終了
      WHEN NO_DATA_FOUND THEN
        -- データ取得エラー
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh, gv_msg_42d_008,
                                              gv_tkn_data,    gv_tkn_name_org);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END init;
--
  /***********************************************************************************
   * Procedure Name   : get_oif_data
   * Description      : 削除対象件数取得処理(D-2)
   ***********************************************************************************/
  PROCEDURE get_oif_data(
    ov_errbuf     OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_oif_data'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
    -- ========================================
    -- 請求OIF情報取得
    -- ========================================
    CURSOR get_oif_data_cur
    IS
    SELECT interface_line_id  interface_line_id  -- 請求OIF明細ID
    FROM   ra_interface_lines_all
    WHERE  org_id  = gt_ou_mfg_id                -- 生産営業単位ID
    FOR UPDATE NOWAIT;
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ========================================
    -- 請求OIF情報取得
    -- ========================================
    BEGIN
      OPEN  get_oif_data_cur;
      -- バルクフェッチ
      FETCH get_oif_data_cur BULK COLLECT INTO gt_oif_data;
      -- 削除対象件数セット
      gn_target_cnt := get_oif_data_cur%ROWCOUNT;
      -- カーソルクローズ
      CLOSE get_oif_data_cur;
    EXCEPTION
      WHEN lock_error_expt THEN -- ロックエラー
        -- カーソルクローズ
        IF (get_oif_data_cur%ISOPEN) THEN
          CLOSE get_oif_data_cur;
        END IF;
        -- ロックエラー
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh, gv_msg_42d_009,
                                              gv_tkn_table,   gv_tkn_name_oif);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END get_oif_data;
--
  /***********************************************************************************
   * Procedure Name   : del_oif_data
   * Description      : 請求OIF削除処理(D-3)
   ***********************************************************************************/
  PROCEDURE del_oif_data(
    ov_errbuf            OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode           OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg            OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_oif_data'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ========================================
    -- 請求OIF削除
    -- ========================================
    BEGIN
     DELETE FROM ra_interface_lines_all
     WHERE       org_id  = gt_ou_mfg_id     -- 生産営業単位ID
     ;
     -- 削除件数セット
     gn_del_cnt  := SQL%ROWCOUNT;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- テーブルデータ削除エラー
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh,    gv_msg_42d_011,
                                              gv_tkn_table_name, gv_tkn_name_oif);
        RAISE global_api_others_expt;
    END;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END del_oif_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf       OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT NOCOPY VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_error_cnt  := 0;
    gn_del_cnt    := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- 初期処理(D-1)
    -- ===============================
    init(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF ( lv_retcode != gv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- 削除対象件数取得処理(D-2)
    -- ============================================
    get_oif_data(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF ( lv_retcode != gv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 削除対象件数が1件以上存在する場合のみ削除処理を実行
    IF ( gn_target_cnt >= 1 ) THEN
      -- ============================================
      -- 請求OIF削除処理(D-3)
      -- ============================================
      del_oif_data(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF ( lv_retcode != gv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
      -- カーソルが開いていればクローズ処理
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
    errbuf          OUT NOCOPY VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode         OUT NOCOPY VARCHAR2       --   リターン・コード    --# 固定 #
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
--
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
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn,  gv_msg_42d_001,
                                           gv_tkn_user, gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --実行コンカレント名出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn,  gv_msg_42d_002,
                                           gv_tkn_conc, gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --起動時間出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn,  gv_msg_42d_006,
                                           gv_tkn_time, TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --区切り文字取得
    gv_sep_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_42d_003);
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      lv_errbuf,       -- エラー・メッセージ           --# 固定 #
      lv_retcode,      -- リターン・コード             --# 固定 #
      lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- ======================
    -- エラー・メッセージ出力
    -- ======================
    -- リターンコードが正常の場合
    IF ( lv_retcode = gv_status_normal ) THEN
      -- 削除対象件数が0件の場合
      IF ( gn_target_cnt = 0 ) THEN
        -- 対象データなしメッセージを出力
        gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh, gv_msg_42d_010);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
      END IF;
--
    -- リターンコードが正常以外の場合
    ELSE
      IF (lv_errmsg IS NULL) THEN
        -- コンカレント定型エラーメッセージ
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_42d_005);
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG, lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_errmsg);
--
    END IF;
--
    --区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_sep_msg);
--
    -- ============================================
    -- 終了処理(D-4)
    -- ============================================
    -- 空行挿入
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '');
--
    -- 処理件数メッセージ
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_42d_012,
                                           gv_tkn_cnt, TO_CHAR(gn_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    -- 成功件数メッセージ
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_42d_013,
                                           gv_tkn_cnt, TO_CHAR(gn_del_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    -- エラー件数メッセージ
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_42d_014,
                                           gv_tkn_cnt, TO_CHAR(gn_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    -- 空行挿入
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '');
--
    -- ステータス取得
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = USERENV('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type, 
                                                                      flv.view_application_id)
    AND    flv.lookup_type         = gv_cp_status_code    -- CP_STATUS_CODE
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            gv_status_normal,gv_sts_cd_normal,
                                            gv_status_warn,gv_sts_cd_warn,
                                            gv_sts_cd_error)
    AND    ROWNUM                  = 1;
--
    -- 処理ステータスメッセージ
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn,    gv_msg_42d_004,
                                           gv_tkn_status, gv_conc_status);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    -- ステータスセット
    retcode := lv_retcode;
    -- 終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = gv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END xxwsh420005c;