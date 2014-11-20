CREATE OR REPLACE PACKAGE BODY xxcso_007002j_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_007002j_pkg(body)
 * Description      : 商談決定情報入力画面で行われた承認依頼に対し、所属上長が承認／否認を
 *                    行います。所属上長の承認が得られた場合、商談決定情報の通知対象者へ商
 *                    談決定情報の通知を行います。所属上長が承認を行った場合は、承認依頼を
 *                    行ったユーザーへ承認結果を送付します。所属上長が否認を行った場合は、
 *                    承認依頼を行ったユーザーへ否認結果を送付します。
 * MD.050           : MD050_CSO_007_A02_商談決定情報通知
 *
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  chk_appr_rjct_comment   承認依頼通知(W-1)
 *  upd_line_notified_flag  商談決定情報履歴明細更新(W-2)
 *  get_notify_user         通知者取得(W-4)
 *  upd_user_notified_flag  商談決定情報通知者リスト更新(W-6)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-01-26    1.0   Kazuo.Satomura   新規作成
 *****************************************************************************************/
  --
  --#######################  固定グローバル定数宣言部 START   #######################
  --
  -- ステータス・コード
  cv_status_normal CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn   CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error  CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- 異常:2
  --
  -- WHOカラム
  cn_created_by             CONSTANT NUMBER := fnd_global.user_id;         -- CREATED_BY
  cd_creation_date          CONSTANT DATE   := SYSDATE;                    -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER := fnd_global.user_id;         -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE   := SYSDATE;                    -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER := fnd_global.conc_program_id; -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE   := SYSDATE;                    -- PROGRAM_UPDATE_DATE
  --
  cv_msg_part CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont CONSTANT VARCHAR2(3) := '.';
  --
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
  gn_target_cnt    NUMBER; -- 対象件数
  gn_normal_cnt    NUMBER; -- 正常件数
  gn_error_cnt     NUMBER; -- エラー件数
  gn_warn_cnt      NUMBER; -- スキップ件数
  --
  --################################  固定部 END   ##################################
  --
  --##########################  固定共通例外宣言部 START  ###########################
  --
  --*** 処理部共通例外 ***
  global_process_expt EXCEPTION;
  --
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
  --
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
  --
  --################################  固定部 END   ##################################
  --
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name              CONSTANT VARCHAR2(100) := 'xxcso_007002j_pkg'; -- パッケージ名
  cv_sales_appl_short_name CONSTANT VARCHAR2(5)   := 'XXCSO';             -- 営業用アプリケーション短縮名
  cv_com_appl_short_name   CONSTANT VARCHAR2(5)   := 'XXCCP';             -- 共通用アプリケーション短縮名
  cv_flag_yes              CONSTANT VARCHAR2(1)   := 'Y';
  cv_flag_no               CONSTANT VARCHAR2(1)   := 'N';
  --
  -- メッセージコード
  cv_tkn_number_01 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00161';  -- 否認コメント未設定エラー
  cv_tkn_number_02 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00074';  -- 桁数エラー1
  cv_tkn_number_03 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00337';  -- データ更新エラー
  cv_tkn_number_04 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00236';  -- 処理エラーメッセージ
  --
  -- トークンコード
  cv_tkn_table         CONSTANT VARCHAR2(20) := 'TABLE';
  cv_tkn_key           CONSTANT VARCHAR2(20) := 'KEY';
  cv_tkn_column        CONSTANT VARCHAR2(20) := 'COLUMN';
  cv_tkn_emsize        CONSTANT VARCHAR2(20) := 'EMSIZE';
  cv_tkn_onebyte       CONSTANT VARCHAR2(20) := 'ONEBYTE';
  cv_tkn_name          CONSTANT VARCHAR2(20) := 'NAME';
  cv_tkn_err_msg       CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_action        CONSTANT VARCHAR2(20) := 'ACTION';
  cv_tkn_error_message CONSTANT VARCHAR2(20) := 'ERROR_MESSAGE';
  cv_tkn_errmsg        CONSTANT VARCHAR2(20) := 'ERRMSG';
  --
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  --
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  --
  /**********************************************************************************
   * Procedure Name   : chk_appr_rjct_comment
   * Description      : 承認依頼通知(W-1)
   ***********************************************************************************/
  PROCEDURE chk_appr_rjct_comment(
     itemtype  IN         VARCHAR2
    ,itemkey   IN         VARCHAR2
    ,actid     IN         NUMBER
    ,funcmode  IN         VARCHAR2
    ,resultout OUT NOCOPY VARCHAR2
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'chk_appr_rjct_comment'; -- プロシージャ名
    --
    --#####################  固定ローカル変数宣言部 START   ########################
    --
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_aname_appr_rjct_comment  CONSTANT VARCHAR2(100) := 'XXCSO_APPR_RJCT_COMMENT';
    cv_aname_notify_header_id   CONSTANT VARCHAR2(100) := 'XXCSO_NOTIFY_HEADER_ID';
    cv_anama_result             CONSTANT VARCHAR2(100) := 'RESULT';
    cv_rjct_internal_name       CONSTANT VARCHAR2(100) := 'XXCSO007002L01C02'; -- 否認時のLOOKUP_CODE
    cn_appr_rjct_comment_length CONSTANT NUMBER        := 508; -- 承認／否認コメント最大入力バイト数 + 改行コード(2) * 4バイト
    --
    -- トークン用定数
    cv_tkn_value_table       CONSTANT VARCHAR2(100) := '承認／否認ステータス';
    cv_tkn_value_key         CONSTANT VARCHAR2(100) := 'ITEM_TYPE,ITEM_KEY,PROCESS_ACTIVITY';
    cv_tkn_value_comment     CONSTANT VARCHAR2(100) := '承認／否認コメント';
    cv_tkn_value_emsize      CONSTANT VARCHAR2(100) := '500';
    cv_tkn_value_onebyte     CONSTANT VARCHAR2(100) := '250';
    cv_tkn_value_chk_comment CONSTANT VARCHAR2(100) := '承認依頼通知';
    --
    -- *** ローカル変数 ***
    ln_nid                  NUMBER;         -- 通知ＩＤ
    lt_activity_result_code VARCHAR2(5000); -- 承認／否認ステータス
    lv_appr_rjct_comment    VARCHAR2(5000); -- 承認／否認コメント
    ln_notify_header_id     NUMBER;         -- 商談決定情報履歴ヘッダＩＤ
    --
  BEGIN
    --
    -- ======================
    -- 通知ＩＤ取得
    -- ======================
    ln_nid := wf_engine.context_nid;
    --
    -- ======================
    -- 承認／否認取得
    -- ======================
    lt_activity_result_code := wf_notification.getattrtext(
                                  nid   => ln_nid
                                 ,aname => cv_anama_result
                               );
    --
    -- ======================
    -- 承認／否認コメント取得
    -- ======================
    lv_appr_rjct_comment := wf_notification.getattrtext(
                               nid   => ln_nid
                              ,aname => cv_aname_appr_rjct_comment
                            );
    --
    IF (lv_appr_rjct_comment IS NULL) THEN
      -- 承認／否認コメントが未入力の場合
      IF (lt_activity_result_code = cv_rjct_internal_name) THEN
        -- 否認時はコメント必須
        fnd_message.set_name(cv_sales_appl_short_name, cv_tkn_number_01);
        app_exception.raise_exception;
        --
      END IF;
      --
    ELSE
      -- 承認／否認コメントが入力されている場合
      IF (LENGTHB(lv_appr_rjct_comment) > cn_appr_rjct_comment_length) THEN
        -- 508バイトを超える場合はエラー
        fnd_message.set_name(cv_sales_appl_short_name, cv_tkn_number_02);
        fnd_message.set_token(cv_tkn_column, cv_tkn_value_comment);
        fnd_message.set_token(cv_tkn_emsize, cv_tkn_value_onebyte);
        fnd_message.set_token(cv_tkn_onebyte, cv_tkn_value_emsize);
        app_exception.raise_exception;
        --
      END IF;
      --
    END IF;
    --
  EXCEPTION
    WHEN OTHERS THEN
      wf_core.context(
         pkg_name  => cv_pkg_name
        ,proc_name => cv_prg_name
        ,arg1      => itemtype
        ,arg2      => itemkey
        ,arg3      => TO_CHAR(actid)
        ,arg4      => funcmode
      );
      --
      RAISE;
      --
  END chk_appr_rjct_comment;
  --
  --
  /**********************************************************************************
   * Procedure Name   : upd_line_notified_flag
   * Description      : 商談決定情報履歴明細更新(W-2)
   ***********************************************************************************/
  PROCEDURE upd_line_notified_flag(
     itemtype  IN         VARCHAR2
    ,itemkey   IN         VARCHAR2
    ,actid     IN         NUMBER
    ,funcmode  IN         VARCHAR2
    ,resultout OUT NOCOPY VARCHAR2
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'upd_line_notified_flag'; -- プロシージャ名
    --
    --#####################  固定ローカル変数宣言部 START   ########################
    --
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_aname_notify_header_id CONSTANT VARCHAR2(100) := 'XXCSO_NOTIFY_HEADER_ID';
    --
    -- トークン用定数
    cv_tkn_value_sales_line    CONSTANT VARCHAR2(100) := '商談決定情報履歴明細テーブル';
    cv_tkn_value_upd_line_flag CONSTANT VARCHAR2(100) := '商談決定情報履歴明細更新';
    --
    -- *** ローカル変数 ***
    ln_notify_header_id NUMBER; -- 商談決定情報履歴ヘッダＩＤ
    --
  BEGIN
    --
    -- ==============================
    -- 商談決定情報履歴ヘッダＩＤ取得
    -- ==============================
    ln_notify_header_id := wf_engine.getitemattrnumber(
                              itemtype => itemtype
                             ,itemkey  => itemkey
                             ,aname    => cv_aname_notify_header_id
                           );
    --
    -- ========================
    -- 通知フラグ更新
    -- ========================
    BEGIN
      UPDATE xxcso_sales_lines_hist xlh -- 商談決定情報履歴明細テーブル
      SET    xlh.notified_flag     = cv_flag_yes          -- 通知フラグ
            ,xlh.last_updated_by   = cn_last_updated_by   -- 最終更新者
            ,xlh.last_update_date  = cd_last_update_date  -- 最終更新日
            ,xlh.last_update_login = cn_last_update_login -- 最終更新ログイン
      WHERE  xlh.header_history_id = ln_notify_header_id
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        fnd_message.set_name(cv_sales_appl_short_name, cv_tkn_number_03);
        fnd_message.set_token(cv_tkn_action, cv_tkn_value_sales_line);
        fnd_message.set_token(cv_tkn_error_message, SQLERRM);
        app_exception.raise_exception;
        --
    END;
    --
  EXCEPTION
    WHEN OTHERS THEN
      wf_core.context(
         pkg_name  => cv_pkg_name
        ,proc_name => cv_prg_name
        ,arg1      => itemtype
        ,arg2      => itemkey
        ,arg3      => TO_CHAR(actid)
        ,arg4      => funcmode
      );
      --
      RAISE;
      --
  END upd_line_notified_flag;
  --
  --
  /**********************************************************************************
   * Procedure Name   : create_process
   * Description      : 承認確認通知プロセス起動(W-4)
   ***********************************************************************************/
  -- 承認確認通知プロセス起動
  PROCEDURE create_process(
     itemtype  IN         VARCHAR2
    ,itemkey   IN         VARCHAR2
    ,actid     IN         NUMBER
    ,funcmode  IN         VARCHAR2
    ,resultout OUT NOCOPY VARCHAR2
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'create_process'; -- プロシージャ名
    --
    --#####################  固定ローカル変数宣言部 START   ########################
    --
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_aname_notify_header_id CONSTANT VARCHAR2(100) := 'XXCSO_NOTIFY_HEADER_ID';       -- 商談決定情報履歴ヘッダＩＤ
    cv_aname_req_appr_user_nm CONSTANT VARCHAR2(100) := 'XXCSO_REQUEST_APPR_USER_NAME'; -- 承認依頼者
    cv_anama_notify_user_nm   CONSTANT VARCHAR2(100) := 'XXCSO_NOTIFY_USER_NAME';       -- 通知者
    cv_aname_notify_subject   CONSTANT VARCHAR2(100) := 'XXCSO_NOTIFY_SUBJECT';         -- 件名
    cv_aname_notify_confirm   CONSTANT VARCHAR2(100) := 'XXCSO_NOTIFY_CONFIRM';         -- 通知確認画面ＵＲＬ
    cv_anama_notify_comment   CONSTANT VARCHAR2(100) := 'XXCSO_NOTIFY_COMMENT';         -- コメント
    cv_amane_user_name        CONSTANT VARCHAR2(100) := 'XXCSO_NEXT_NOTIFY_USER';
    cv_process_name           CONSTANT VARCHAR2(100) := 'XXCSO007002P02';
    --
    -- トークン用定数
    cv_tkn_value_sales_notifies CONSTANT VARCHAR2(100) := '商談決定情報通知者リストテーブル';
    cv_tkn_value_create_process CONSTANT VARCHAR2(100) := '承認確認通知プロセス起動';
    --
    -- *** ローカル変数 ***
    ln_notify_header_id NUMBER;         -- 商談決定情報ヘッダＩＤ
    lv_req_appr_user_nm VARCHAR2(100);  -- 承認依頼者
    lv_notify_subject   VARCHAR2(4000); -- 件名
    lv_notify_confirm   VARCHAR2(4000); -- 通知確認画面ＵＲＬ
    lv_notify_comment   VARCHAR2(4000); -- コメント
    lv_itemkey          VARCHAR2(100);  -- アイテムキー
    ln_loop_count       NUMBER := 0;    -- ループ件数
    --
    -- *** ローカル・カーソル ***
    -- 未通知者取得カーソル
    CURSOR get_user_name_cur
    IS
      SELECT xsn.user_name -- ユーザー名
      FROM   xxcso_sales_notifies xsn -- 商談決定情報通知者リストテーブル
      WHERE  xsn.header_history_id = ln_notify_header_id
      AND    xsn.notified_flag     = cv_flag_no
      ;
    --
  BEGIN
    --
    -- ==========================
    -- 商談決定情報ヘッダＩＤ取得
    -- ==========================
    ln_notify_header_id := wf_engine.getitemattrnumber(
                              itemtype => itemtype
                             ,itemkey  => itemkey
                             ,aname    => cv_aname_notify_header_id
                           );
    --
    -- ==========================
    -- 承認依頼者取得
    -- ==========================
    lv_req_appr_user_nm := wf_engine.getitemattrtext(
                              itemtype => itemtype
                             ,itemkey  => itemkey
                             ,aname    => cv_aname_req_appr_user_nm
                           );
    --
    -- ==========================
    -- 件名取得
    -- ==========================
    lv_notify_subject := wf_engine.getitemattrtext(
                             itemtype => itemtype
                            ,itemkey  => itemkey
                            ,aname    => cv_aname_notify_subject
                          );
    --
    -- ==========================
    -- 通知確認画面ＵＲＬ取得
    -- ==========================
    lv_notify_confirm := wf_engine.getitemattrtext(
                            itemtype => itemtype
                           ,itemkey  => itemkey
                           ,aname    => cv_aname_notify_confirm
                         );
    --
    -- ==========================
    -- コメント取得
    -- ==========================
    lv_notify_comment := wf_engine.getitemattrtext(
                            itemtype => itemtype
                           ,itemkey  => itemkey
                           ,aname    => cv_anama_notify_comment
                         );
    --
    -- ========================
    -- 未通知者取得
    -- ========================
    FOR lt_sales_notifies_rec IN get_user_name_cur LOOP
      ln_loop_count := ln_loop_count + 1;
      --
      IF (lt_sales_notifies_rec.user_name IS NOT NULL) THEN
        -- ==========================
        -- 承認確認通知プロセスを起動
        -- ==========================
        lv_itemkey  := 'XXCSO007' || TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS') || ln_loop_count;
        --
        wf_engine.createprocess(
           itemtype   => itemtype
          ,itemkey    => lv_itemkey
          ,process    => cv_process_name
          ,owner_role => fnd_global.user_name
        );
        --
        -- 商談決定情報履歴ヘッダＩＤ
        wf_engine.setitemattrnumber(
          itemtype   => itemtype
         ,itemkey    => lv_itemkey
         ,aname      => cv_aname_notify_header_id
         ,avalue     => ln_notify_header_id
        );
        --
        -- 承認依頼者
        wf_engine.setitemattrtext(
          itemtype   => itemtype
         ,itemkey    => lv_itemkey
         ,aname      => cv_aname_req_appr_user_nm
         ,avalue     => lv_req_appr_user_nm
        );
        --
        -- 通知者
        wf_engine.setitemattrtext(
          itemtype   => itemtype
         ,itemkey    => lv_itemkey
         ,aname      => cv_anama_notify_user_nm
         ,avalue     => lt_sales_notifies_rec.user_name
        );
        --
        -- 件名
        wf_engine.setitemattrtext(
          itemtype   => itemtype
         ,itemkey    => lv_itemkey
         ,aname      => cv_aname_notify_subject
         ,avalue     => lv_notify_subject
        );
        --
        -- 通知確認画面ＵＲＬ
        wf_engine.setitemattrtext(
          itemtype   => itemtype
         ,itemkey    => lv_itemkey
         ,aname      => cv_aname_notify_confirm
         ,avalue     => lv_notify_confirm
        );
        --
        -- コメント
        wf_engine.setitemattrtext(
          itemtype   => itemtype
         ,itemkey    => lv_itemkey
         ,aname      => cv_anama_notify_comment
         ,avalue     => lv_notify_comment
        );
        --
        wf_engine.startprocess(
          itemtype   => itemtype
         ,itemkey    => lv_itemkey
        );
      END IF;
      --
    END LOOP;
    --
  EXCEPTION
    WHEN OTHERS THEN
      wf_core.context(
         pkg_name  => cv_pkg_name
        ,proc_name => cv_prg_name
        ,arg1      => itemtype
        ,arg2      => itemkey
        ,arg3      => TO_CHAR(actid)
        ,arg4      => funcmode
      );
      --
      fnd_message.set_name(cv_sales_appl_short_name, cv_tkn_number_04);
      fnd_message.set_token(cv_tkn_action, cv_tkn_value_create_process);
      fnd_message.set_token(cv_tkn_errmsg, SQLERRM);
      app_exception.raise_exception;
      --
  END create_process;
  --
  --
  /**********************************************************************************
   * Procedure Name   : upd_user_notified_flag
   * Description      : 商談決定情報通知者リスト更新(W-6)
   ***********************************************************************************/
  PROCEDURE upd_user_notified_flag(
     itemtype  IN         VARCHAR2
    ,itemkey   IN         VARCHAR2
    ,actid     IN         NUMBER
    ,funcmode  IN         VARCHAR2
    ,resultout OUT NOCOPY VARCHAR2
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'upd_user_notified_flag'; -- プロシージャ名
    --
    --#####################  固定ローカル変数宣言部 START   ########################
    --
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_aname_notify_header_id CONSTANT VARCHAR2(100) := 'XXCSO_NOTIFY_HEADER_ID';
    cv_amane_user_name        CONSTANT VARCHAR2(100) := 'XXCSO_NOTIFY_USER_NAME';
    --
    -- トークン用定数
    cv_tkn_value_sales_notifies CONSTANT VARCHAR2(100) := '商談決定情報通知者リストテーブル';
    cv_tkn_value_upd_user_flag  CONSTANT VARCHAR2(100) := '商談決定情報通知者リスト更新';
    --
    -- *** ローカル変数 ***
    ln_notify_header_id NUMBER;        -- 商談決定情報履歴ヘッダＩＤ
    lt_user_name        VARCHAR2(100); -- ユーザー名
    --
  BEGIN
    --
    -- ==========================
    -- 商談決定情報ヘッダＩＤ取得
    -- ==========================
    ln_notify_header_id := wf_engine.getitemattrnumber(
                              itemtype => itemtype
                             ,itemkey  => itemkey
                             ,aname    => cv_aname_notify_header_id
                           );
    --
    -- ========================
    -- 通知者ユーザー名取得
    -- ========================
    lt_user_name := wf_engine.getitemattrtext(
                       itemtype => itemtype
                      ,itemkey  => itemkey
                      ,aname    => cv_amane_user_name
                    );
    --
    -- ========================
    -- 通知フラグ更新
    -- ========================
    BEGIN
      UPDATE xxcso_sales_notifies xsn -- 商談決定情報通知者リストテーブル
      SET    xsn.notified_flag     = cv_flag_yes          -- 通知フラグ
            ,xsn.last_updated_by   = cn_last_updated_by   -- 最終更新者
            ,xsn.last_update_date  = cd_last_update_date  -- 最終更新日
            ,xsn.last_update_login = cn_last_update_login -- 最終更新ログイン
      WHERE  xsn.header_history_id = ln_notify_header_id
      AND    xsn.user_name         = lt_user_name
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        fnd_message.set_name(cv_sales_appl_short_name, cv_tkn_number_03);
        fnd_message.set_token(cv_tkn_action, cv_tkn_value_sales_notifies);
        fnd_message.set_token(cv_tkn_error_message, SQLERRM);
        app_exception.raise_exception;
        --
    END;
    --
  EXCEPTION
    WHEN OTHERS THEN
      wf_core.context(
         pkg_name  => cv_pkg_name
        ,proc_name => cv_prg_name
        ,arg1      => itemtype
        ,arg2      => itemkey
        ,arg3      => TO_CHAR(actid)
        ,arg4      => funcmode
      );
      --
      RAISE;
      --
  END upd_user_notified_flag;
  --
  --
END xxcso_007002j_pkg;
/
