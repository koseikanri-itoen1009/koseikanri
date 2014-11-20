create or replace PACKAGE BODY XXCFF012A18C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF012A18C(body)
 * Description      : リース債務残高レポート
 * MD.050           : リース債務残高レポート MD050_CFF_012_A18
 * Version          : 1.6
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   入力パラメータ値ログ出力処理(A-1)
 *  chk_period_name        会計期間チェック処理(A-2)
 *  get_first_period       会計期間期首取得処理(A-3)
 *  get_contract_info      リース契約情報取得処理(A-4)
 *  get_pay_planning       リース支払計画情報取得処理(A-5)
 *  edit_bal_in_obg_wk     リース債務残高ワークデータ編集処理 (A-6)
 *  ins_bal_in_obg_wk      リース債務残高ワークデータ作成処理 (A-7)
 *  submit_svf_request     SVF起動処理(A-8)
 *  del_bal_in_obg_wk      データ削除処理(A-9)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/19    1.0   SCS山岸          main新規作成
 *  2009/02/26    1.1   SCS山岸          [障害CFF_063] 初回、2回目同月支払の場合の不具合対応
 *  2009/02/27    1.2   SCS山岸          SVF出力関数に対応
 *  2009/07/17    1.3   SCS萱原          [統合テスト障害0000417] 支払計画の当期支払リース料取得処理修正
 *  2009/07/31    1.4   SCS渡辺          [統合テスト障害0000417(追加)]
 *                                         ・取得価額、減価償却累計額の取得条件を修正
 *                                         ・支払利息相当額、当期支払リース料（控除額）の取得条件修正
 *                                         ・リース契約情報取得カーソルをリース種類で分割
 *  2009/08/28    1.5   SCS 渡辺         [統合テスト障害0001063(PT対応)]
 *  2011/12/01    1.6   SCSK白川         [E_本稼動_08123] リース解約日設定許可に伴うリース債務残高集計条件の修正
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
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
--  <exception_name>          EXCEPTION;     -- <例外のコメント>
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name         CONSTANT VARCHAR2(100) := 'XXCFF012A18C'; -- パッケージ名
  cv_appl_short_name  CONSTANT VARCHAR2(100) := 'XXCFF';        -- アプリケーション短縮名
  cv_which            CONSTANT VARCHAR2(100) := 'LOG';          -- コンカレントログ出力先
  -- メッセージ
  cv_msg_close        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00038'; -- 会計期間仮クローズチェックエラー
  cv_msg_ins_err      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00102'; -- 登録エラー
  cv_msg_del_err      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00104'; -- 削除エラー
  cv_msg_no_lines     CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00010'; -- 明細0件用メッセージ
  cv_msg_lock_err     CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00007'; -- ロックエラー
  -- トークン名
  cv_tkn_book_type    CONSTANT VARCHAR2(50)  := 'BOOK_TYPE_CODE';   -- 資産台帳名
  cv_tkn_period_name  CONSTANT VARCHAR2(50)  := 'PERIOD_NAME';      -- 会計期間名
  cv_tkn_column_name  CONSTANT VARCHAR2(20)  := 'COLUMN_NAME';      -- カラム名
  cv_tkn_table_name   CONSTANT VARCHAR2(20)  := 'TABLE_NAME';       -- テーブル名
  cv_tkn_err_info     CONSTANT VARCHAR2(20)  := 'INFO';             -- エラー情報
  -- トークン値
  cv_tkv_wk_tab_name  CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50153'; -- リース債務残高レポート帳票ワークテーブル
  -- リース種類
  cv_lease_kind_fin   CONSTANT VARCHAR2(1)   := '0';  -- Finリース
  cv_lease_kind_op    CONSTANT VARCHAR2(1)   := '1';  -- Opリース
  cv_lease_kind_qfin  CONSTANT VARCHAR2(1)   := '2';  -- 旧Finリース
  -- リース区分
  cv_lease_type1      CONSTANT VARCHAR2(1)   := '1';  -- 原契約
  -- 契約ステータス
  cv_contr_st_201     CONSTANT VARCHAR2(3)   := '201'; -- 登録済み
-- 0000417 2009/07/31 ADD START --
  -- 除売却ステータス
  cv_processed        CONSTANT VARCHAR2(9)   := 'PROCESSED'; --処理済
  -- 会計IFフラグステータス
  cv_if_aft           CONSTANT VARCHAR2(1)   := '2'; --連携済
-- 0000417 2009/07/31 ADD END --
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  TYPE g_wk_ttype IS TABLE OF xxcff_rep_bal_in_obg_wk%ROWTYPE INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : del_bal_in_obg_wk
   * Description      : データ削除処理(A-9)
   ***********************************************************************************/
  PROCEDURE del_bal_in_obg_wk(
    ov_errbuf         OUT VARCHAR2,      --   エラー・メッセージ                  --# 固定 #
    ov_retcode        OUT VARCHAR2,      --   リターン・コード                    --# 固定 #
    ov_errmsg         OUT VARCHAR2)      --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_bal_in_obg_wk'; -- プログラム名
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
--
    -- *** ローカル・カーソル ***
    CURSOR bal_in_obg_wk_cur
    IS
      SELECT request_id
        FROM xxcff_rep_bal_in_obg_wk
       WHERE request_id = cn_request_id
      FOR UPDATE NOWAIT;
--
    -- *** ローカル・レコード ***
    TYPE l_request_id_ttype IS TABLE OF xxcff_rep_bal_in_obg_wk.request_id%TYPE INDEX BY BINARY_INTEGER;
    l_request_id_tab   l_request_id_ttype;
--
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
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    -- ロックの取得
    BEGIN
      OPEN bal_in_obg_wk_cur;
      FETCH bal_in_obg_wk_cur BULK COLLECT INTO l_request_id_tab;
      CLOSE bal_in_obg_wk_cur;
    EXCEPTION
      WHEN OTHERS THEN
        IF (bal_in_obg_wk_cur%ISOPEN) THEN
          CLOSE bal_in_obg_wk_cur;
        END IF;
        lv_errbuf := SQLERRM;
        lv_errmsg := xxccp_common_pkg.get_msg(
                        cv_appl_short_name, cv_msg_lock_err
                       ,cv_tkn_table_name, cv_tkv_wk_tab_name);
        RAISE global_process_expt;
    END;
    -- ワークデータ削除
    DELETE FROM xxcff_rep_bal_in_obg_wk
     WHERE request_id = cn_request_id;
    -- 変数のクリア
    l_request_id_tab.DELETE;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_process_expt THEN                           --*** <例外コメント> ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
      ov_errmsg  := xxccp_common_pkg.get_msg(
                       cv_appl_short_name, cv_msg_del_err
                      ,cv_tkn_table_name, cv_tkv_wk_tab_name
                      ,cv_tkn_err_info, ''
                      );
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END del_bal_in_obg_wk;
--
  /**********************************************************************************
   * Procedure Name   : submit_svf_request
   * Description      : SVF起動処理(A-8)
   ***********************************************************************************/
  PROCEDURE submit_svf_request(
    ov_errbuf         OUT VARCHAR2,      --   エラー・メッセージ                  --# 固定 #
    ov_retcode        OUT VARCHAR2,      --   リターン・コード                    --# 固定 #
    ov_errmsg         OUT VARCHAR2)      --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submit_svf_request'; -- プログラム名
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
    cv_rep_id    CONSTANT VARCHAR2(20) := 'XXCFF012A18';  -- 帳票ID
    cv_svf_fname CONSTANT VARCHAR2(20) := 'XXCFF012A18S'; -- SVFファイル名
--
    -- *** ローカル変数 ***
    lv_no_data_msg VARCHAR2(100);
    lv_file_name   VARCHAR2(100);
    lv_user_name   VARCHAR2(100);
    lv_resp_name   VARCHAR2(100);
--
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
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    -- 出力ファイル名
    lv_file_name := cv_rep_id || TO_CHAR(SYSDATE,'yyyymmdd') || TO_CHAR(cn_request_id) || '.pdf';
    -- 明細0件用メッセージ
    lv_no_data_msg := xxccp_common_pkg.get_msg(cv_appl_short_name, cv_msg_no_lines);
    -- ユーザー名
    SELECT user_name
      INTO lv_user_name
      FROM fnd_user
     WHERE user_id = cn_created_by;
    -- 職責名
    fnd_profile.get('RESP_NAME',lv_resp_name);
    -- SVF帳票起動API呼び出し
    xxccp_svfcommon_pkg.submit_svf_request(
       iv_conc_name    => cv_pkg_name        -- コンカレント名
      ,iv_file_name    => lv_file_name       -- 出力ファイル名
      ,iv_file_id      => cv_rep_id          -- 帳票ID
      ,iv_output_mode  => '1'                -- 出力区分
      ,iv_frm_file     => cv_svf_fname || '.xml' -- フォーム様式ファイル名
      ,iv_vrq_file     => cv_svf_fname || '.vrq' -- クエリー様式ファイル名
      ,iv_org_id       => fnd_profile.value('ORG_ID') -- ORG_ID
      ,iv_user_name    => lv_user_name       -- ユーザー名
      ,iv_resp_name    => lv_resp_name       -- 職責名
      ,iv_doc_name     => NULL               -- 文書名
      ,iv_printer_name => NULL               -- プリンタ名
      ,iv_request_id   => TO_CHAR(cn_request_id) -- 要求ID
      ,iv_nodata_msg   => lv_no_data_msg     -- 明細0件用メッセージ
      ,ov_errbuf       => lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode         -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode != cv_status_normal) THEN
      --(エラー処理)
      RAISE global_api_expt;
    END IF;
--
    -- 対象データが0件だった場合、コンカレントログにメッセージを出力
    IF (gn_target_cnt = 0) THEN
      lv_retcode := xxccp_svfcommon_pkg.no_data_msg;
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
  END submit_svf_request;
--
  /**********************************************************************************
   * Procedure Name   : ins_bal_in_obg_wk
   * Description      : リース債務残高ワークデータ作成処理(A-7)
   ***********************************************************************************/
  PROCEDURE ins_bal_in_obg_wk(
    i_wk_tab          IN  g_wk_ttype,    -- 1.リース債務残高レポートワークデータ
    ov_errbuf         OUT VARCHAR2,      --   エラー・メッセージ                  --# 固定 #
    ov_retcode        OUT VARCHAR2,      --   リターン・コード                    --# 固定 #
    ov_errmsg         OUT VARCHAR2)      --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_bal_in_obg_wk'; -- プログラム名
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
--
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
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    -- 対象件数インクリメント
    gn_target_cnt := gn_target_cnt + NVL(i_wk_tab.count,0);
--
    FORALL i IN 1..NVL(i_wk_tab.LAST,0) SAVE EXCEPTIONS
      INSERT INTO xxcff_rep_bal_in_obg_wk VALUES i_wk_tab(i);
    -- 成功件数インクリメント
    gn_normal_cnt := gn_normal_cnt + SQL%ROWCOUNT;
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
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- 成功件数インクリメント
      gn_normal_cnt := gn_normal_cnt + SQL%ROWCOUNT;
      -- エラー件数インクリメント
      gn_error_cnt := gn_error_cnt + SQL%BULK_EXCEPTIONS.COUNT;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM(-SQL%BULK_EXCEPTIONS(1).ERROR_CODE);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_bal_in_obg_wk;
--
  /**********************************************************************************
   * Procedure Name   : edit_bal_in_obg_wk
   * Description      : リース債務残高ワークデータ編集処理 (A-6)
   ***********************************************************************************/
  PROCEDURE edit_bal_in_obg_wk(
    iv_period_from    IN     VARCHAR2,     -- 1.出力期間（自）
    iv_period_to      IN     VARCHAR2,     -- 2.出力期間（至）
    io_wk_tab         IN OUT g_wk_ttype,   -- 3.リース債務残高レポートワークデータ
    ov_errbuf         OUT    VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT    VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg         OUT    VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'edit_bal_in_obg_wk'; -- プログラム名
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
--
    -- *** ローカル・カーソル ***
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
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    -- 出力期間の設定
    io_wk_tab(1).period_from           := REPLACE(iv_period_from,'-','/'); -- 出力期間（自）
    io_wk_tab(1).period_to             := REPLACE(iv_period_to,'-','/');   -- 出力期間（至）
    -- Opリースの固定出力項目
    io_wk_tab(1).o_deprn_amount        := 0;              -- 減価償却額相当額
    io_wk_tab(1).o_interest_amount     := 0;              -- 支払利息相当額
    -- WHOカラムの設定
    io_wk_tab(1).created_by            := cn_created_by;
    io_wk_tab(1).creation_date         := cd_creation_date;
    io_wk_tab(1).last_updated_by       := cn_last_updated_by;
    io_wk_tab(1).last_update_date      := cd_last_update_date;
    io_wk_tab(1).last_update_login     := cn_last_update_login;
    io_wk_tab(1).request_id            := cn_request_id;
    io_wk_tab(1).program_application_id:= cn_program_application_id;
    io_wk_tab(1).program_id            := cn_program_id;
    io_wk_tab(1).program_update_date   := cd_program_update_date;
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
  END edit_bal_in_obg_wk;
--
  /**********************************************************************************
   * Procedure Name   : get_pay_planning
   * Description      : リース支払計画情報取得処理(A-5)
   ***********************************************************************************/
  PROCEDURE get_pay_planning(
    id_start_date_1st IN     DATE,         -- 1.期首開始日
    id_start_date_now IN     DATE,         -- 2.当期開始日
-- 2011/12/01 Ver.1.6 A.Shirakawa ADD Start
    iv_period_name    IN     VARCHAR2,     -- 3.会計期間名
-- 2011/12/01 Ver.1.6 A.Shirakawa ADD End
    io_wk_tab         IN OUT g_wk_ttype,   -- 4.リース債務残高レポートワークデータ
    ov_errbuf         OUT    VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT    VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg         OUT    VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_payment_planning'; -- プログラム名
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
--
    -- *** ローカル・カーソル ***
    CURSOR planning_cur
    IS
      SELECT 
-- 0001063 2009/08/28 ADD START --
           /*+
             LEADING(XCH XCL)
             INDEX(XCH XXCFF_CONTRACT_HEADERS_N06)
             INDEX(XCL XXCFF_CONTRACT_LINES_U01)
           */
-- 0001063 2009/08/28 ADD END --
           xcl.lease_kind
-- 0000417 2009/07/17 ADD START --
          ,SUM(CASE WHEN xpp.accounting_if_flag = cv_if_aft THEN
-- 0000417 2009/07/17 ADD END --
-- 0000417 2009/07/17 MOD START --
--            ,SUM(CASE WHEN xpp.period_name >= TO_CHAR(id_start_date_1st,'YYYY-MM') THEN
                 (CASE WHEN xpp.period_name >= TO_CHAR(id_start_date_1st,'YYYY-MM') THEN
-- 0000417 2009/07/17 MOD END --
                    (CASE WHEN xpp.period_name <= TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                       xpp.lease_charge
                     ELSE 0 END)
-- 0000417 2009/07/17 ADD START --
                  ELSE 0 END)
-- 0000417 2009/07/17 ADD END --
               ELSE 0 END) AS lease_charge_this_month   -- 当期支払リース料
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                   xpp.lease_charge
                 ELSE 0 END) AS lease_charge_future       -- 未経過リース料
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                      xpp.lease_charge
                    ELSE 0 END)
                 ELSE 0 END) AS lease_charge_1year        -- 1年以内未経過リース料
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                   xpp.lease_charge
                 ELSE 0 END) AS lease_charge_over_1year   -- 1年越未経過リース料
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                   xpp.fin_debt
                 ELSE 0 END) AS lease_charge_debt         -- 未経過リース期末残高相当額
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                   xpp.fin_interest_due
                 ELSE 0 END) AS interest_future           -- 未経過リース支払利息額
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                   xpp.fin_tax_debt
                 ELSE 0 END) AS tax_future                -- 未経過リース消費税額
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                      xpp.fin_debt
                    ELSE 0 END)
                 ELSE 0 END) AS principal_1year           -- 1年以内元本
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                      xpp.fin_interest_due
                    ELSE 0 END)
                 ELSE 0 END) AS interest_1year            -- 1年以内支払利息
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                      xpp.fin_tax_debt
                    ELSE 0 END)
                 ELSE 0 END) AS tax_1year                 -- 1年以内消費税
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,24),'YYYY-MM') THEN
                      xpp.fin_debt
                    ELSE 0 END)
                 ELSE 0 END) AS principal_1to2year        -- 1年超2年以内元本
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,24),'YYYY-MM') THEN
                      xpp.fin_interest_due
                    ELSE 0 END)
                 ELSE 0 END) AS interest_1to2year         -- 1年超2年以内支払利息
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,24),'YYYY-MM') THEN
                      xpp.fin_tax_debt
                    ELSE 0 END)
                 ELSE 0 END) AS tax_1to2year              -- 1年超2年以内消費税
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,24),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,36),'YYYY-MM') THEN
                      xpp.fin_debt
                    ELSE 0 END)
                 ELSE 0 END) AS principal_2to3year        -- 2年超3年以内元本
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,24),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,36),'YYYY-MM') THEN
                      xpp.fin_interest_due
                    ELSE 0 END)
                 ELSE 0 END) AS interest_2to3year         -- 2年超3年以内支払利息
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,24),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,36),'YYYY-MM') THEN
                      xpp.fin_tax_debt
                    ELSE 0 END)
                 ELSE 0 END) AS tax_2to3year              -- 2年超3年以内消費税
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,36),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,48),'YYYY-MM') THEN
                      xpp.fin_debt
                    ELSE 0 END)
                 ELSE 0 END) AS principal_3to4year        -- 3年超4年以内元本
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,36),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,48),'YYYY-MM') THEN
                      xpp.fin_interest_due
                    ELSE 0 END)
                 ELSE 0 END) AS interest_3to4year         -- 3年超4年以内支払利息
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,36),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,48),'YYYY-MM') THEN
                      xpp.fin_tax_debt
                    ELSE 0 END)
                 ELSE 0 END) AS tax_3to4year              -- 3年超4年以内消費税
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,48),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,60),'YYYY-MM') THEN
                      xpp.fin_debt
                    ELSE 0 END)
                 ELSE 0 END) AS principal_4to5year        -- 4年超5年以内元本
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,48),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,60),'YYYY-MM') THEN
                      xpp.fin_interest_due
                    ELSE 0 END)
                 ELSE 0 END) AS interest_4to5year         -- 4年超5年以内支払利息
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,48),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,60),'YYYY-MM') THEN
                      xpp.fin_tax_debt
                    ELSE 0 END)
                 ELSE 0 END) AS tax_4to5year              -- 4年超5年以内消費税
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,60),'YYYY-MM') THEN
                   xpp.fin_debt
                 ELSE 0 END) AS principal_over_5year      -- 5年越元本
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,60),'YYYY-MM') THEN
                   xpp.fin_interest_due
                 ELSE 0 END) AS interest_over_5year       -- 5年越支払利息
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,60),'YYYY-MM') THEN
                   xpp.fin_tax_debt
                 ELSE 0 END) AS tax_over_5year            -- 5年越消費税
-- 0000417 2009/07/31 ADD START --
            ,SUM(CASE WHEN xpp.accounting_if_flag = cv_if_aft THEN
-- 0000417 2009/07/31 ADD END --
-- 0000417 2009/07/31 MOD START --
--            ,SUM(CASE WHEN xpp.period_name >= TO_CHAR(id_start_date_1st,'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name >= TO_CHAR(id_start_date_1st,'YYYY-MM') THEN
-- 0000417 2009/07/31 MOD END --
                      (CASE WHEN xpp.period_name <= TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                         xpp.fin_interest_due
                       ELSE 0 END)
-- 0000417 2009/07/31 ADD START --
                    ELSE 0 END)
-- 0000417 2009/07/31 ADD END --
                 ELSE 0 END) AS interest_amount           -- 支払利息相当額
-- 0000417 2009/07/31 ADD START --
            ,SUM(CASE WHEN xpp.accounting_if_flag = cv_if_aft THEN
-- 0000417 2009/07/31 ADD END --
-- 0000417 2009/07/31 MOD START --
--            ,SUM(CASE WHEN xpp.period_name >= TO_CHAR(id_start_date_1st,'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name >= TO_CHAR(id_start_date_1st,'YYYY-MM') THEN
-- 0000417 2009/07/31 MOD END --
                      (CASE WHEN xpp.period_name <= TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                         xpp.lease_deduction
                       ELSE 0 END)
-- 0000417 2009/07/31 ADD START --
                    ELSE 0 END)
-- 0000417 2009/07/31 ADD END --
                 ELSE 0 END) AS deduction_this_month      -- 当期支払リース料（控除額）
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                   xpp.lease_deduction
                 ELSE 0 END) AS deduction_future          -- 未経過リース料（控除額）
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                      xpp.lease_deduction
                    ELSE 0 END)
                 ELSE 0 END) AS deduction_1year           -- 1年以内未経過リース料（控除額）
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                   xpp.lease_deduction
                 ELSE 0 END) AS deduction_over_1year      -- 1年越未経過リース料（控除額）
        FROM xxcff_contract_headers xch
            ,xxcff_contract_lines xcl
            ,xxcff_pay_planning xpp
       WHERE xch.contract_header_id = xcl.contract_header_id
         AND xpp.contract_line_id = xcl.contract_line_id
         AND xch.lease_type = cv_lease_type1
         AND EXISTS (
               SELECT 'x' FROM xxcff_pay_planning xpp2
                WHERE xpp2.contract_line_id = xcl.contract_line_id
                  AND xpp2.period_name >= TO_CHAR(id_start_date_1st,'YYYY-MM'))
-- 0000417 2009/07/17 MOD START --
--         AND NOT (xpp.period_name >= TO_CHAR(xcl.cancellation_date,'YYYY-MM') AND
         AND NOT (xpp.period_name > TO_CHAR(xcl.cancellation_date,'YYYY-MM') AND
-- 0000417 2009/07/17 MOD END --
-- 2011/12/01 Ver.1.6 A.Shirakawa ADD Start
                  xcl.cancellation_date < LAST_DAY(TO_DATE(iv_period_name, 'YYYY-MM')) + 1 AND
-- 2011/12/01 Ver.1.6 A.Shirakawa ADD End
                  xcl.cancellation_date IS NOT NULL)
         AND xcl.contract_status > cv_contr_st_201
      GROUP BY xcl.lease_kind
      ;
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
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    <<planning_loop>>
    FOR l_rec IN planning_cur LOOP
      IF (l_rec.lease_kind = cv_lease_kind_fin) THEN
        io_wk_tab(1).f_lease_charge_this_month := l_rec.lease_charge_this_month; -- 当期支払リース料
        io_wk_tab(1).f_lease_charge_future     := l_rec.lease_charge_future;     -- 未経過リース料
        io_wk_tab(1).f_lease_charge_1year      := l_rec.lease_charge_1year;      -- 1年以内未経過リース料
        io_wk_tab(1).f_lease_charge_over_1year := l_rec.lease_charge_over_1year; -- 1年越未経過リース料
        io_wk_tab(1).f_lease_charge_debt       := l_rec.lease_charge_debt;       -- 未経過リース期末残高相当額
        io_wk_tab(1).f_interest_future         := l_rec.interest_future;         -- 未経過リース支払利息額
        io_wk_tab(1).f_tax_future              := l_rec.tax_future;              -- 未経過リース消費税額
        io_wk_tab(1).f_principal_1year         := l_rec.principal_1year;         -- 1年以内元本
        io_wk_tab(1).f_interest_1year          := l_rec.interest_1year;          -- 1年以内支払利息
        io_wk_tab(1).f_tax_1year               := l_rec.tax_1year;               -- 1年以内消費税
        io_wk_tab(1).f_principal_1to2year      := l_rec.principal_1to2year;      -- 1年越2年以内元本
        io_wk_tab(1).f_interest_1to2year       := l_rec.interest_1to2year;       -- 1年越2年以内支払利息
        io_wk_tab(1).f_tax_1to2year            := l_rec.tax_1to2year;            -- 1年越2年以内消費税
        io_wk_tab(1).f_principal_2to3year      := l_rec.principal_2to3year;      -- 2年超3年以内元本
        io_wk_tab(1).f_interest_2to3year       := l_rec.interest_2to3year;       -- 2年超3年以内支払利息
        io_wk_tab(1).f_tax_2to3year            := l_rec.tax_2to3year;            -- 2年超3年以内消費税
        io_wk_tab(1).f_principal_3to4year      := l_rec.principal_3to4year;      -- 3年越4年以内元本
        io_wk_tab(1).f_interest_3to4year       := l_rec.interest_3to4year;       -- 3年越4年以内支払利息
        io_wk_tab(1).f_tax_3to4year            := l_rec.tax_3to4year;            -- 3年越4年以内消費税
        io_wk_tab(1).f_principal_4to5year      := l_rec.principal_4to5year;      -- 4年越5年以内元本
        io_wk_tab(1).f_interest_4to5year       := l_rec.interest_4to5year;       -- 4年越5年以内支払利息
        io_wk_tab(1).f_tax_4to5year            := l_rec.tax_4to5year;            -- 4年越5年以内消費税
        io_wk_tab(1).f_principal_over_5year    := l_rec.principal_over_5year;    -- 5年越元本
        io_wk_tab(1).f_interest_over_5year     := l_rec.interest_over_5year;     -- 5年越支払利息
        io_wk_tab(1).f_tax_over_5year          := l_rec.tax_over_5year;          -- 5年越消費税
        io_wk_tab(1).f_interest_amount         := l_rec.interest_amount;         -- 支払利息相当額
        io_wk_tab(1).f_deduction_this_month    := l_rec.deduction_this_month;    -- 当期支払リース料（控除額）
        io_wk_tab(1).f_deduction_future        := l_rec.deduction_future;        -- 未経過リース料（控除額）
        io_wk_tab(1).f_deduction_1year         := l_rec.deduction_1year;         -- 1年以内未経過リース料（控除額）
        io_wk_tab(1).f_deduction_over_1year    := l_rec.deduction_over_1year;    -- 1年越未経過リース料（控除額）
--
      ELSIF (l_rec.lease_kind = cv_lease_kind_qfin) THEN
        io_wk_tab(1).q_lease_charge_this_month := l_rec.lease_charge_this_month; -- 当期支払リース料
        io_wk_tab(1).q_lease_charge_future     := l_rec.lease_charge_future;     -- 未経過リース料
        io_wk_tab(1).q_lease_charge_1year      := l_rec.lease_charge_1year;      -- 1年以内未経過リース料
        io_wk_tab(1).q_lease_charge_over_1year := l_rec.lease_charge_over_1year; -- 1年越未経過リース料
        io_wk_tab(1).q_lease_charge_debt       := l_rec.lease_charge_debt;       -- 未経過リース期末残高相当額
        io_wk_tab(1).q_interest_future         := l_rec.interest_future;         -- 未経過リース支払利息額
        io_wk_tab(1).q_tax_future              := l_rec.tax_future;              -- 未経過リース消費税額
        io_wk_tab(1).q_principal_1year         := l_rec.principal_1year;         -- 1年以内元本
        io_wk_tab(1).q_interest_1year          := l_rec.interest_1year;          -- 1年以内支払利息
        io_wk_tab(1).q_tax_1year               := l_rec.tax_1year;               -- 1年以内消費税
        io_wk_tab(1).q_principal_1to2year      := l_rec.principal_1to2year;      -- 1年越2年以内元本
        io_wk_tab(1).q_interest_1to2year       := l_rec.interest_1to2year;       -- 1年越2年以内支払利息
        io_wk_tab(1).q_tax_1to2year            := l_rec.tax_1to2year;            -- 1年越2年以内消費税
        io_wk_tab(1).q_principal_2to3year      := l_rec.principal_2to3year;      -- 2年超3年以内元本
        io_wk_tab(1).q_interest_2to3year       := l_rec.interest_2to3year;       -- 2年超3年以内支払利息
        io_wk_tab(1).q_tax_2to3year            := l_rec.tax_2to3year;            -- 2年超3年以内消費税
        io_wk_tab(1).q_principal_3to4year      := l_rec.principal_3to4year;      -- 3年越4年以内元本
        io_wk_tab(1).q_interest_3to4year       := l_rec.interest_3to4year;       -- 3年越4年以内支払利息
        io_wk_tab(1).q_tax_3to4year            := l_rec.tax_3to4year;            -- 3年越4年以内消費税
        io_wk_tab(1).q_principal_4to5year      := l_rec.principal_4to5year;      -- 4年越5年以内元本
        io_wk_tab(1).q_interest_4to5year       := l_rec.interest_4to5year;       -- 4年越5年以内支払利息
        io_wk_tab(1).q_tax_4to5year            := l_rec.tax_4to5year;            -- 4年越5年以内消費税
        io_wk_tab(1).q_principal_over_5year    := l_rec.principal_over_5year;    -- 5年越元本
        io_wk_tab(1).q_interest_over_5year     := l_rec.interest_over_5year;     -- 5年越支払利息
        io_wk_tab(1).q_tax_over_5year          := l_rec.tax_over_5year;          -- 5年越消費税
        io_wk_tab(1).q_interest_amount         := l_rec.interest_amount;         -- 支払利息相当額
        io_wk_tab(1).q_deduction_this_month    := l_rec.deduction_this_month;    -- 当期支払リース料（控除額）
        io_wk_tab(1).q_deduction_future        := l_rec.deduction_future;        -- 未経過リース料（控除額）
        io_wk_tab(1).q_deduction_1year         := l_rec.deduction_1year;         -- 1年以内未経過リース料（控除額）
        io_wk_tab(1).q_deduction_over_1year    := l_rec.deduction_over_1year;    -- 1年越未経過リース料（控除額）
--
      ELSIF (l_rec.lease_kind = cv_lease_kind_op) THEN
        io_wk_tab(1).o_lease_charge_this_month := l_rec.lease_charge_this_month; -- 当期支払リース料
        io_wk_tab(1).o_lease_charge_future     := l_rec.lease_charge_future;     -- 未経過リース料
        io_wk_tab(1).o_lease_charge_1year      := l_rec.lease_charge_1year;      -- 1年以内未経過リース料
        io_wk_tab(1).o_lease_charge_over_1year := l_rec.lease_charge_over_1year; -- 1年越未経過リース料
        io_wk_tab(1).o_deduction_this_month    := l_rec.deduction_this_month;    -- 当期支払リース料（控除額）
        io_wk_tab(1).o_deduction_future        := l_rec.deduction_future;        -- 未経過リース料（控除額）
        io_wk_tab(1).o_deduction_1year         := l_rec.deduction_1year;         -- 1年以内未経過リース料（控除額）
        io_wk_tab(1).o_deduction_over_1year    := l_rec.deduction_over_1year;    -- 1年越未経過リース料（控除額）
      END IF;
    END LOOP planning_loop;
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
  END get_pay_planning;
--
  /**********************************************************************************
   * Procedure Name   : get_contract_info
   * Description      : リース契約情報取得処理(A-4)
   ***********************************************************************************/
  PROCEDURE get_contract_info(
    id_start_date_1st  IN     DATE,       --  1.期首開始日
    id_start_date_now  IN     DATE,       --  2.当期開始日
    in_fiscal_year     IN     NUMBER,     --  3.会計年度
    in_period_num_1st  IN     NUMBER,     --  4.期首期間番号
    in_period_num_now  IN     NUMBER,     --  5.当期期間番号
    iv_period_from     IN     VARCHAR2,   --  6.出力期間（自）
    iv_period_to       IN     VARCHAR2,   --  7.出力期間（至）
    io_wk_tab          IN OUT g_wk_ttype, --  8.リース債務残高レポートワークデータ
    ov_errbuf          OUT    VARCHAR2,   --   エラー・メッセージ           --# 固定 #
    ov_retcode         OUT    VARCHAR2,   --   リターン・コード             --# 固定 #
    ov_errmsg          OUT    VARCHAR2)   --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_contract_info'; -- プログラム名
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
--
    -- *** ローカル・カーソル ***
-- 0000417 2009/08/06 DEL START --
/*
    CURSOR contract_cur
    IS
      SELECT xcl.lease_kind                     -- リース種類
            ,SUM(CASE WHEN fdp.period_name = iv_period_to THEN
                   xcl.second_charge
                 ELSE 0 END) AS monthly_charge  -- 月間リース料
            ,SUM(CASE WHEN fdp.period_name = iv_period_to THEN
                   xcl.gross_charge
                 ELSE 0 END) AS gross_charge    -- リース料総額
-- 0000417 2009/07/31 MOD START --
--            ,SUM(CASE WHEN xcl.cancellation_date IS NULL AND
--                           xcl.expiration_date IS NULL   THEN
            ,SUM(CASE WHEN fret.retirement_id IS NULL OR
                           fret.status <> cv_processed   THEN
-- 0000417 2009/07/31 MOD END --
                   (CASE WHEN fdp.period_name = iv_period_to THEN
                      xcl.original_cost
                    ELSE 0 END)
                 ELSE 0 END) AS original_cost   -- 取得価額総額
-- 0000417 2009/07/31 MOD START --
--            ,SUM(CASE WHEN xcl.cancellation_date IS NULL AND
--                           xcl.expiration_date IS NULL   THEN
            ,SUM(CASE WHEN fret.retirement_id IS NULL OR
                           fret.status <> cv_processed   THEN
-- 0000417 2009/07/31 MOD END --
                   (CASE WHEN fdp.period_name = iv_period_to THEN
-- 0000417 2009/07/31 MOD START --
--                      fds.deprn_reserve
                      NVL(fds.deprn_reserve,xcl.original_cost)
-- 0000417 2009/07/31 MOD END --
                    ELSE 0 END)
                 ELSE 0 END) AS deprn_reserve   -- 減価償却累計額相当額
            ,SUM(NVL(fds.deprn_amount,0)) AS deprn_amount -- 減価償却相当額
            ,SUM(CASE WHEN fdp.period_name = iv_period_to THEN
                   xcl.second_deduction
                 ELSE 0 END) AS monthly_deduction -- 月間リース料（控除額）
            ,SUM(CASE WHEN fdp.period_name = iv_period_to THEN
                   xcl.gross_deduction
                 ELSE 0 END) AS gross_deduction -- リース料総額（控除額）
        FROM xxcff_contract_headers xch       -- リース契約
       INNER JOIN xxcff_contract_lines xcl    -- リース契約明細
          ON xcl.contract_header_id = xch.contract_header_id
       INNER JOIN xxcff_lease_kind_v xlk      -- リース種類ビュー
          ON xcl.lease_kind = xlk.lease_kind_code
       LEFT JOIN fa_additions_b fab           -- 資産詳細情報
          ON fab.attribute10 = xcl.contract_line_id
-- 0000417 2009/07/31 ADD START --
       LEFT JOIN fa_retirements fret  -- 除売却
          ON fret.asset_id                  = fab.asset_id
         AND fret.book_type_code            = xlk.book_type_code
         AND fret.transaction_header_id_out IS NULL
-- 0000417 2009/07/31 ADD END --
       LEFT JOIN fa_deprn_periods fdp         -- 減価償却期間
          ON fdp.book_type_code = xlk.book_type_code
       LEFT JOIN fa_deprn_summary fds         -- 減価償却サマリ
          ON fds.asset_id = fab.asset_id
         AND fds.book_type_code = fdp.book_type_code
         AND fds.period_counter = fdp.period_counter
         AND fds.deprn_source_code = 'DEPRN'
       WHERE xch.lease_type = cv_lease_type1
         AND EXISTS (
             SELECT 'x' FROM xxcff_pay_planning xpp
              WHERE xpp.contract_line_id = xcl.contract_line_id
                AND xpp.period_name >= TO_CHAR(id_start_date_1st,'YYYY-MM')
             )
         AND xcl.contract_status > cv_contr_st_201
         AND fdp.fiscal_year = in_fiscal_year
         AND fdp.period_num >= in_period_num_1st
         AND fdp.period_num <= in_period_num_now
      GROUP BY xcl.lease_kind
      ;
*/
-- 0000417 2009/08/06 DEL END --
--
-- 0000417 2009/08/06 ADD START --
    --FIN、旧FINリース取得対象カーソル
    CURSOR contract_cur
    IS
      SELECT
-- 0001063 2009/08/28 ADD START --
            /*+
              LEADING(XCH XCL XLK FAB FRET FDP FDS)
              INDEX(XCH XXCFF_CONTRACT_HEADERS_N06)
              INDEX(XCL XXCFF_CONTRACT_LINES_U01)
              NO_USE_MERGE(XCH XLK)
              USE_NL(XCL FAB)
            */
-- 0001063 2009/08/28 ADD START --
             xcl.lease_kind                     -- リース種類

            ,SUM(CASE WHEN fret.retirement_id IS NULL OR
-- 2011/12/01 Ver.1.6 A.Shirakawa ADD Start
                           (xcl.cancellation_date IS NULL) OR
                           (xcl.cancellation_date >= LAST_DAY(TO_DATE(iv_period_to, 'YYYY-MM')) + 1) OR
-- 2011/12/01 Ver.1.6 A.Shirakawa ADD End
                           fret.status <> cv_processed   THEN
                   (CASE WHEN fdp.period_name = iv_period_to THEN
                      xcl.second_charge
                    ELSE 0 END)
                 ELSE 0 END) AS monthly_charge  -- 月間リース料
            ,SUM(CASE WHEN fret.retirement_id IS NULL OR
-- 2011/12/01 Ver.1.6 A.Shirakawa ADD Start
                           (xcl.cancellation_date IS NULL) OR
                           (xcl.cancellation_date >= LAST_DAY(TO_DATE(iv_period_to, 'YYYY-MM')) + 1) OR
-- 2011/12/01 Ver.1.6 A.Shirakawa ADD End
                           fret.status <> cv_processed   THEN
                   (CASE WHEN fdp.period_name = iv_period_to THEN
                      xcl.gross_charge
                    ELSE 0 END)
                 ELSE 0 END) AS gross_charge    -- リース料総額
            ,SUM(CASE WHEN fret.retirement_id IS NULL OR
-- 2011/12/01 Ver.1.6 A.Shirakawa ADD Start
                           (xcl.cancellation_date IS NULL) OR
                           (xcl.cancellation_date >= LAST_DAY(TO_DATE(iv_period_to, 'YYYY-MM')) + 1) OR
-- 2011/12/01 Ver.1.6 A.Shirakawa ADD End
                           fret.status <> cv_processed   THEN
                   (CASE WHEN fdp.period_name = iv_period_to THEN
                      xcl.original_cost
                    ELSE 0 END)
                 ELSE 0 END) AS original_cost   -- 取得価額総額
            ,SUM(CASE WHEN fret.retirement_id IS NULL OR
-- 2011/12/01 Ver.1.6 A.Shirakawa ADD Start
                           (xcl.cancellation_date IS NULL) OR
                           (xcl.cancellation_date >= LAST_DAY(TO_DATE(iv_period_to, 'YYYY-MM')) + 1) OR
-- 2011/12/01 Ver.1.6 A.Shirakawa ADD End
                           fret.status <> cv_processed   THEN
                   (CASE WHEN fdp.period_name = iv_period_to THEN
                      NVL(fds.deprn_reserve,original_cost)
                    ELSE 0 END)
                 ELSE 0 END) AS deprn_reserve   -- 減価償却累計額相当額
            ,SUM(NVL(fds.deprn_amount,0)) AS deprn_amount -- 減価償却相当額

            ,SUM(CASE WHEN fret.retirement_id IS NULL OR
-- 2011/12/01 Ver.1.6 A.Shirakawa ADD Start
                           (xcl.cancellation_date IS NULL) OR
                           (xcl.cancellation_date >= LAST_DAY(TO_DATE(iv_period_to, 'YYYY-MM')) + 1) OR
-- 2011/12/01 Ver.1.6 A.Shirakawa ADD End
                           fret.status <> cv_processed   THEN
                   (CASE WHEN fdp.period_name = iv_period_to THEN
                      xcl.second_deduction
                    ELSE 0 END)
                 ELSE 0 END) AS monthly_deduction -- 月間リース料（控除額）
            ,SUM(CASE WHEN fret.retirement_id IS NULL OR
-- 2011/12/01 Ver.1.6 A.Shirakawa ADD Start
                           (xcl.cancellation_date IS NULL) OR
                           (xcl.cancellation_date >= LAST_DAY(TO_DATE(iv_period_to, 'YYYY-MM')) + 1) OR
-- 2011/12/01 Ver.1.6 A.Shirakawa ADD End
                           fret.status <> cv_processed   THEN
                   (CASE WHEN fdp.period_name = iv_period_to THEN
                   xcl.gross_deduction
                    ELSE 0 END)
                 ELSE 0 END) AS gross_deduction -- リース料総額（控除額）
        FROM xxcff_contract_headers xch       -- リース契約
       INNER JOIN xxcff_contract_lines xcl    -- リース契約明細
          ON xcl.contract_header_id = xch.contract_header_id
         AND xcl.lease_kind IN (cv_lease_kind_fin,cv_lease_kind_qfin)
       INNER JOIN xxcff_lease_kind_v xlk      -- リース種類ビュー
          ON xcl.lease_kind = xlk.lease_kind_code
       INNER JOIN fa_additions_b fab           -- 資産詳細情報
-- 0001063 2009/08/28 MOD START --
--          ON fab.attribute10 = xcl.contract_line_id
          ON fab.attribute10 = to_char(xcl.contract_line_id)
-- 0001063 2009/08/28 MOD END --
       LEFT JOIN fa_retirements fret  -- 除売却
          ON fret.asset_id                  = fab.asset_id
         AND fret.book_type_code            = xlk.book_type_code
         AND fret.transaction_header_id_out IS NULL
       INNER JOIN fa_deprn_periods fdp         -- 減価償却期間
          ON fdp.book_type_code = xlk.book_type_code
-- 0001063 2009/08/28 ADD START --
         AND fdp.fiscal_year = in_fiscal_year
         AND fdp.period_num >= in_period_num_1st
         AND fdp.period_num <= in_period_num_now
-- 0001063 2009/08/28 ADD END --
       LEFT JOIN fa_deprn_summary fds         -- 減価償却サマリ
          ON fds.asset_id = fab.asset_id
         AND fds.book_type_code = fdp.book_type_code
         AND fds.period_counter = fdp.period_counter
         AND fds.deprn_source_code = 'DEPRN'
       WHERE xch.lease_type = cv_lease_type1
         AND xcl.contract_status > cv_contr_st_201
-- 0001063 2009/08/28 DEL START --
--         AND fdp.fiscal_year = in_fiscal_year
--         AND fdp.period_num >= in_period_num_1st
--         AND fdp.period_num <= in_period_num_now
-- 0001063 2009/08/28 DEL END --
      GROUP BY xcl.lease_kind
      ;
--
    --OPリース取得対象カーソル
    CURSOR contract_op_cur
    IS
      SELECT xcl.lease_kind                     -- リース種類
-- 2011/12/01 Ver.1.6 A.Shirakawa MOD Start
--            ,SUM(CASE WHEN xcl.cancellation_date IS NULL AND
            ,SUM(CASE WHEN ((xcl.cancellation_date IS NULL) OR
                            (xcl.cancellation_date >= LAST_DAY(TO_DATE(iv_period_to, 'YYYY-MM')) + 1)) AND
-- 2011/12/01 Ver.1.6 A.Shirakawa MOD End
                           xcl.expiration_date IS NULL   THEN
                   xcl.second_charge
                 ELSE 0 END) AS monthly_charge  -- 月間リース料
-- 2011/12/01 Ver.1.6 A.Shirakawa MOD Start
--            ,SUM(CASE WHEN xcl.cancellation_date IS NULL AND
            ,SUM(CASE WHEN ((xcl.cancellation_date IS NULL) OR
                            (xcl.cancellation_date >= LAST_DAY(TO_DATE(iv_period_to, 'YYYY-MM')) + 1)) AND
-- 2011/12/01 Ver.1.6 A.Shirakawa MOD End
                           xcl.expiration_date IS NULL   THEN
                   xcl.gross_charge
                 ELSE 0 END) AS gross_charge    -- リース料総額
            ,NULL AS original_cost   -- 取得価額総額
            ,NULL AS deprn_reserve   -- 減価償却累計額相当額
            ,NULL AS deprn_amount    -- 減価償却相当額
-- 2011/12/01 Ver.1.6 A.Shirakawa MOD Start
--            ,SUM(CASE WHEN xcl.cancellation_date IS NULL AND
            ,SUM(CASE WHEN ((xcl.cancellation_date IS NULL) OR
                            (xcl.cancellation_date >= LAST_DAY(TO_DATE(iv_period_to, 'YYYY-MM')) + 1)) AND
-- 2011/12/01 Ver.1.6 A.Shirakawa MOD End
                           xcl.expiration_date IS NULL   THEN
                   xcl.second_deduction
                 ELSE 0 END) AS monthly_deduction -- 月間リース料（控除額）
-- 2011/12/01 Ver.1.6 A.Shirakawa MOD Start
--            ,SUM(CASE WHEN xcl.cancellation_date IS NULL AND
            ,SUM(CASE WHEN ((xcl.cancellation_date IS NULL) OR
                            (xcl.cancellation_date >= LAST_DAY(TO_DATE(iv_period_to, 'YYYY-MM')) + 1)) AND
-- 2011/12/01 Ver.1.6 A.Shirakawa MOD End
                           xcl.expiration_date IS NULL   THEN
                   xcl.gross_deduction
                 ELSE 0 END) AS gross_deduction -- リース料総額（控除額）
        FROM xxcff_contract_headers xch       -- リース契約
       INNER JOIN xxcff_contract_lines xcl    -- リース契約明細
          ON xcl.contract_header_id = xch.contract_header_id
         AND xcl.lease_kind = cv_lease_kind_op
       INNER JOIN xxcff_lease_kind_v xlk      -- リース種類ビュー
          ON xcl.lease_kind = xlk.lease_kind_code
       WHERE xch.lease_type = cv_lease_type1
         AND EXISTS (
             SELECT 'x' FROM xxcff_pay_planning xpp
              WHERE xpp.contract_line_id = xcl.contract_line_id
                AND xpp.period_name >= TO_CHAR(id_start_date_1st,'YYYY-MM')
             )
         AND xcl.contract_status > cv_contr_st_201
      GROUP BY xcl.lease_kind
      ;
-- 0000417 2009/08/06 ADD END --
    contract_rec contract_cur%ROWTYPE;
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
--
    -- ***************************************
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
    -- FIN、旧FINリース対象
    <<contract_loop>>
    FOR l_rec in contract_cur LOOP
      -- 取得値を格納
      IF    (l_rec.lease_kind = cv_lease_kind_fin) THEN
        io_wk_tab(1).f_monthly_charge      := l_rec.monthly_charge;     -- 月間リース料
        io_wk_tab(1).f_gross_charge        := l_rec.gross_charge;       -- リース料総額
        io_wk_tab(1).f_original_cost       := l_rec.original_cost;      -- 取得価額総額
        io_wk_tab(1).f_deprn_reserve       := l_rec.deprn_reserve;      -- 減価償却累計額相当額
        io_wk_tab(1).f_deprn_amount        := l_rec.deprn_amount;       -- 減価償却相当額
        io_wk_tab(1).f_monthly_deduction   := l_rec.monthly_deduction;  -- 月間リース料（控除額）
        io_wk_tab(1).f_gross_deduction     := l_rec.gross_deduction;    -- リース料総額（控除額）
        io_wk_tab(1).f_bal_amount          := l_rec.original_cost - l_rec.deprn_reserve; -- 期末残高相当額
      ELSIF (l_rec.lease_kind = cv_lease_kind_qfin) THEN
        io_wk_tab(1).q_monthly_charge      := l_rec.monthly_charge;     -- 月間リース料
        io_wk_tab(1).q_gross_charge        := l_rec.gross_charge;       -- リース料総額
        io_wk_tab(1).q_original_cost       := l_rec.original_cost;      -- 取得価額総額
        io_wk_tab(1).q_deprn_reserve       := l_rec.deprn_reserve;      -- 減価償却累計額相当額
        io_wk_tab(1).q_deprn_amount        := l_rec.deprn_amount;       -- 減価償却相当額
        io_wk_tab(1).q_monthly_deduction   := l_rec.monthly_deduction;  -- 月間リース料（控除額）
        io_wk_tab(1).q_gross_deduction     := l_rec.gross_deduction;    -- リース料総額（控除額）
        io_wk_tab(1).q_bal_amount          := l_rec.original_cost - l_rec.deprn_reserve; -- 期末残高相当額
-- 0000417 2009/08/05 DEL START --
--      ELSIF (l_rec.lease_kind = cv_lease_kind_op) THEN
--        io_wk_tab(1).o_monthly_charge      := l_rec.monthly_charge;     -- 月間リース料
--        io_wk_tab(1).o_gross_charge        := l_rec.gross_charge;       -- リース料総額
--        io_wk_tab(1).o_monthly_deduction   := l_rec.monthly_deduction;  -- 月間リース料（控除額）
--        io_wk_tab(1).o_gross_deduction     := l_rec.gross_deduction;    -- リース料総額（控除額）
-- 0000417 2009/08/05 DEL END --
      END IF;
    END LOOP contract_loop;
--
-- 0000417 2009/08/06 START END --
    -- OPリース対象
    <<contract_loop2>>
    FOR l_rec in contract_op_cur LOOP
      -- 取得値を格納
      io_wk_tab(1).o_monthly_charge      := l_rec.monthly_charge;     -- 月間リース料
      io_wk_tab(1).o_gross_charge        := l_rec.gross_charge;       -- リース料総額
      io_wk_tab(1).o_monthly_deduction   := l_rec.monthly_deduction;  -- 月間リース料（控除額）
      io_wk_tab(1).o_gross_deduction     := l_rec.gross_deduction;    -- リース料総額（控除額）
    END LOOP contract_loop2;
-- 0000417 2009/08/06 END END --
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
  END get_contract_info;
--
  /**********************************************************************************
   * Procedure Name   : get_first_period
   * Description      : 会計期間期首取得処理(A-3)
   ***********************************************************************************/
  PROCEDURE get_first_period(
    in_fiscal_year    IN  NUMBER,       -- 1.会計年度
    ov_period_from    OUT VARCHAR2,     -- 2.出力期間（自）
    on_period_num_1st OUT NUMBER,       -- 3.期間番号
    od_start_date_1st OUT DATE,         -- 4.期首開始日
    ov_errbuf         OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_first_period'; -- プログラム名
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
    cn_period_num_1st CONSTANT NUMBER(1) := 1;  -- 期首期間番号
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
    CURSOR period_1st_cur
    IS
      SELECT fcp.period_name AS period_from    -- 出力期間（自）
            ,fcp.period_num  AS period_num     -- 期間番号
            ,fcp.start_date  AS start_date_1st -- 期首開始日
        FROM fa_calendar_periods fcp  -- 資産カレンダ
            ,fa_calendar_types fct    -- 資産カレンダタイプ
            ,fa_fiscal_year ffy       -- 資産会計年度
            ,fa_book_controls fbc     -- 資産台帳マスタ
            ,xxcff_lease_kind_v xlk   -- リース種類ビュー
       WHERE fbc.book_type_code = xlk.book_type_code
         AND xlk.lease_kind_code = cv_lease_kind_fin
         AND fbc.deprn_calendar = fcp.calendar_type
         AND ffy.fiscal_year = in_fiscal_year
         AND ffy.fiscal_year_name = fct.fiscal_year_name
         AND fct.calendar_type = fcp.calendar_type
         AND fcp.start_date >= ffy.start_date
         AND fcp.end_date <= ffy.end_date
         AND fcp.period_num = cn_period_num_1st;
    period_1st_rec period_1st_cur%ROWTYPE;
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
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    OPEN period_1st_cur;
    FETCH period_1st_cur INTO period_1st_rec;
    CLOSE period_1st_cur;
    -- 戻り値設定
    ov_period_from    := period_1st_rec.period_from;     -- 出力期間（自）
    on_period_num_1st := period_1st_rec.period_num;      -- 期間番号
    od_start_date_1st := period_1st_rec.start_date_1st;  -- 期首開始日
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
  END get_first_period;
--
  /**********************************************************************************
   * Procedure Name   : chk_period_name
   * Description      : 会計期間チェック処理(A-2)
   ***********************************************************************************/
  PROCEDURE chk_period_name(
    iv_period_name    IN  VARCHAR2,     -- 1.会計期間名
    on_fiscal_year    OUT NUMBER,       -- 2.会計年度
    ov_period_to      OUT VARCHAR2,     -- 3.出力期間（至）
    on_period_num_now OUT NUMBER,       -- 4.期間番号
    od_start_date_now OUT DATE,         -- 5.当期開始日
    ov_errbuf         OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_period_name'; -- プログラム名
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
--
    -- *** ローカル・カーソル ***
    CURSOR period_cur
    IS
      SELECT fdp.deprn_run   AS deprn_run      -- 減価償却実行フラグ
            ,fdp.fiscal_year AS fiscal_year    -- 会計期間
            ,fdp.period_name AS period_to      -- 出力期間（至）
            ,fdp.period_num  AS period_num     -- 期間番号
            ,fcp.start_date  AS start_date_now -- 当期開始日
            ,xlk.book_type_code AS book_type_code -- 資産台帳名
        FROM fa_deprn_periods fdp     -- 減価償却期間
            ,fa_calendar_periods fcp  -- 資産カレンダ
            ,fa_book_controls fbc     -- 資産台帳マスタ
            ,xxcff_lease_kind_v xlk   -- リース種類ビュー
       WHERE fbc.book_type_code = xlk.book_type_code
         AND fdp.period_name = iv_period_name
         AND fdp.book_type_code = fbc.book_type_code
         AND fbc.deprn_calendar = fcp.calendar_type
         AND fdp.period_name = fcp.period_name;
    period_rec period_cur%ROWTYPE;
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
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    -- 減価償却期間情報取得
    OPEN period_cur;
    <<period_loop>>
    LOOP
      FETCH period_cur INTO period_rec;
      EXIT WHEN period_cur%NOTFOUND;
      IF (NVL(period_rec.deprn_run,'N') != 'Y') THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        cv_appl_short_name,cv_msg_close
                       ,cv_tkn_book_type,period_rec.book_type_code
                       ,cv_tkn_period_name,iv_period_name
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
    END LOOP period_loop;
    CLOSE period_cur;
--
    -- 戻り値設定
    on_fiscal_year    := period_rec.fiscal_year;      -- 会計年度
    ov_period_to      := period_rec.period_to;        -- 出力期間（至）
    on_period_num_now := period_rec.period_num;       -- 期間番号
    od_start_date_now := period_rec.start_date_now;   -- 当期開始日
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_process_expt THEN                           --*** 共通処理例外 ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END chk_period_name;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 入力パラメータ値ログ出力処理(A-1)
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
--
    -- *** ローカル変数 ***
--
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
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    xxcff_common1_pkg.put_log_param(
       iv_which    => cv_which     -- 出力区分
      ,ov_retcode  => lv_retcode   --リターンコード
      ,ov_errbuf   => lv_errbuf    --エラーメッセージ
      ,ov_errmsg   => lv_errmsg    --ユーザー・エラーメッセージ
    );
    IF lv_retcode != cv_status_normal THEN
      RAISE global_api_expt;
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
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_period_name       IN  VARCHAR2,     -- 1.会計期間名
    ov_errbuf            OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode           OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg            OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    lt_fiscal_year    fa_deprn_periods.fiscal_year%TYPE;     -- 会計年度
    lt_period_from    fa_deprn_periods.period_name%TYPE;     -- 出力期間（自）
    lt_period_to      fa_deprn_periods.period_name%TYPE;     -- 出力期間（至）
    lt_period_num_1st fa_deprn_periods.period_num%TYPE;      -- 期首期間番号
    lt_period_num_now fa_deprn_periods.period_num%TYPE;      -- 当期期間番号
    ld_start_date_1st DATE;                                  -- 期首開始日
    ld_start_date_now DATE;                                  -- 当期開始日
    l_wk_tab          g_wk_ttype;
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
--    CURSOR <cursor_name>_cur
--    IS
--     SELECT
--      FROM
--      WHERE
    -- <カーソル名>レコード型
--    <cursor_name>_rec <cursor_name>_cur%ROWTYPE;
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
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ============================================
    -- A-1．入力パラメータ値ログ出力処理
    -- ============================================
    init(
       lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,lv_retcode         -- リターン・コード             --# 固定 #
      ,lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode != cv_status_normal) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-2．会計期間チェック処理
    -- ============================================
    chk_period_name(
       iv_period_name     -- 1.会計期間名
      ,lt_fiscal_year     -- 2.会計年度
      ,lt_period_to       -- 3.出力期間（至）
      ,lt_period_num_now  -- 4.期間番号
      ,ld_start_date_now  -- 5.当期開始日
      ,lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,lv_retcode         -- リターン・コード             --# 固定 #
      ,lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode != cv_status_normal) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-3．会計期間期首取得処理
    -- ============================================
    get_first_period(
       lt_fiscal_year     -- 1.会計年度
      ,lt_period_from     -- 2.出力期間（至）
      ,lt_period_num_1st  -- 3.期間番号
      ,ld_start_date_1st  -- 4.当期開始日
      ,lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,lv_retcode         -- リターン・コード             --# 固定 #
      ,lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode != cv_status_normal) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-4．リース契約情報取得処理
    -- ============================================
    get_contract_info(
       ld_start_date_1st  --  1.期首開始日
      ,ld_start_date_now  --  2.当期開始日
      ,lt_fiscal_year     --  3.会計年度
      ,lt_period_num_1st  --  4.期首期間番号
      ,lt_period_num_now  --  5.当期期間番号
      ,lt_period_from     --  6.出力期間（自）
      ,lt_period_to       --  7.出力期間（至）
      ,l_wk_tab           --  8.リース債務残高レポートワークデータ
      ,lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,lv_retcode         -- リターン・コード             --# 固定 #
      ,lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode != cv_status_normal) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    IF (NVL(l_wk_tab.COUNT,0) > 0) THEN
      -- ============================================
      -- A-5．リース支払計画情報取得処理
      -- ============================================
      get_pay_planning(
         ld_start_date_1st  --  1.期首開始日
        ,ld_start_date_now  --  2.当期開始日
-- 2011/12/01 Ver.1.6 A.Shirakawa ADD Start
        ,lt_period_to       --  3.会計期間名
-- 2011/12/01 Ver.1.6 A.Shirakawa ADD Start
        ,l_wk_tab           --  4.リース債務残高レポートワークデータ
        ,lv_errbuf          -- エラー・メッセージ           --# 固定 #
        ,lv_retcode         -- リターン・コード             --# 固定 #
        ,lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode != cv_status_normal) THEN
        --(エラー処理)
        RAISE global_process_expt;
      END IF;
  --
      -- ============================================
      -- A-6．リース債務残高レポートワークデータ編集処理
      -- ============================================
      edit_bal_in_obg_wk(
         lt_period_from     -- 1.出力期間（自）
        ,lt_period_to       -- 2.出力期間（至）
        ,l_wk_tab           -- 3.リース債務残高レポートワークデータ
        ,lv_errbuf          -- エラー・メッセージ           --# 固定 #
        ,lv_retcode         -- リターン・コード             --# 固定 #
        ,lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode != cv_status_normal) THEN
        --(エラー処理)
        RAISE global_process_expt;
      END IF;
  --
      -- ============================================
      -- A-7．リース債務残高レポートワークデータ作成処理
      -- ============================================
      ins_bal_in_obg_wk(
         l_wk_tab           -- 1.リース債務残高レポートワークデータ
        ,lv_errbuf          --   エラー・メッセージ           --# 固定 #
        ,lv_retcode         --   リターン・コード             --# 固定 #
        ,lv_errmsg          --   ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_normal) THEN
        -- 成功件数が0件以上ならコミット発行
        IF (gn_normal_cnt > 0) THEN
          COMMIT;
        END IF;
      ELSE
        --(エラー処理)
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ============================================
    -- A-8．SVF起動処理
    -- ============================================
    submit_svf_request(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode != cv_status_normal) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-9．データ削除処理
    -- ============================================
    del_bal_in_obg_wk(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode != cv_status_normal) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
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
    errbuf               OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode              OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_period_name       IN  VARCHAR2       -- 1.会計期間名
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
       iv_which    => cv_which     -- 出力区分
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
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_period_name  -- 1.会計期間名
      ,lv_errbuf       --   エラー・メッセージ           --# 固定 #
      ,lv_retcode      --   リターン・コード             --# 固定 #
      ,lv_errmsg       --   ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- ============================================
    -- A-10．終了処理
    -- ============================================
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --スキップ件数出力
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_appl_short_name
--                    ,iv_name         => cv_skip_rec_msg
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
--                   );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => gv_out_msg
--    );
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
       which  => FND_FILE.LOG
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
END XXCFF012A18C;
/
