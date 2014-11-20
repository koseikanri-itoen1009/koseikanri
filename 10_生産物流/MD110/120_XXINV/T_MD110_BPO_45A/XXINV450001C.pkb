CREATE OR REPLACE PACKAGE BODY xxinv450001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxinv450001c(body)
 * Description      : 実績計上済フラグ更新処理
 * MD.050           : 実績計上済フラグ更新 T_MD050_BPO_450
 * MD.070           : 実績計上済フラグ更新処理(45A)
 * Version          : 1.1
 *
 * Program List
 * ------------------------- ----------------------------------------------------------
 *  Name                      Description
 * ------------------------- ----------------------------------------------------------
 *  initialize                初期処理              (A-1)
 *  chk_param                 入力パラメータチェック(A-2)
 *  get_prod_data             対象データ取得（生産）(A-3)
 *  get_po_data               対象データ取得（発注）(A-4)
 *  upd_actual_confirm_class  実績計上済フラグ更新  (A-5)
 *  submain                   メイン処理プロシージャ
 *  main                      コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2010/03/01    1.0   H.Itou           新規作成
 *  2010/03/17    1.1   M.Hokkanji       本番稼働障害#1612(発注分納時に実績計上済
 *                                       フラグが正しく更新されない問題を修正)
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
  lock_expt              EXCEPTION;        -- ロック取得例外
  PRAGMA EXCEPTION_INIT(lock_expt, -54);   -- ロック取得例外
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name                CONSTANT VARCHAR2(100) := 'xxinv450001c';    -- パッケージ名
  -- モジュール名略称
  gv_xxcmn                   CONSTANT VARCHAR2(100) := 'XXCMN';           -- モジュール名略称：XXCMN
  gv_xxinv                   CONSTANT VARCHAR2(100) := 'XXINV';           -- モジュール名略称：XXINV
--
  -- メッセージ
  gv_msg_xxcmn10002          CONSTANT VARCHAR2(100) := 'APP-XXCMN-10002'; -- プロファイル取得エラー
  gv_msg_xxcmn05002          CONSTANT VARCHAR2(100) := 'APP-XXCMN-05002'; -- 処理失敗
  gv_msg_xxcmn10019          CONSTANT VARCHAR2(100) := 'APP-XXCMN-10019'; -- ロックエラー
  gv_msg_xxinv10055          CONSTANT VARCHAR2(100) := 'APP-XXINV-10055'; -- 日付逆転エラーメッセージ
--
  -- トークン
  gv_tkn_table               CONSTANT VARCHAR2(100) := 'TABLE';
  gv_tkn_ship_date           CONSTANT VARCHAR2(100) := 'SHIP_DATE';
  gv_tkn_arrival_date        CONSTANT VARCHAR2(100) := 'ARRIVAL_DATE';
  gv_tkn_ng_profile          CONSTANT VARCHAR2(100) := 'NG_PROFILE';
  gv_tkn_process             CONSTANT VARCHAR2(100) := 'PROCESS';
--
  -- トークン値
  gv_table_name              CONSTANT VARCHAR2(100) := '移動ロット詳細';
  gv_date_from_name          CONSTANT VARCHAR2(100) := '更新日付(FROM)';
  gv_date_to_name            CONSTANT VARCHAR2(100) := '更新日付(TO)';
  gv_org_id_name             CONSTANT VARCHAR2(100) := '組織ID';
  gv_get_process_date        CONSTANT VARCHAR2(100) := '業務日付取得';
  gv_get_working_day         CONSTANT VARCHAR2(100) := '営業日日付取得';
--
  -- データフォーマット
  gv_datetime_fmt            CONSTANT VARCHAR2(100) := 'YYYY/MM/DD HH24:MI:SS';
  cv_date_fmt                CONSTANT VARCHAR2(100) := 'YYYY/MM/DD';
  gv_min_time                CONSTANT VARCHAR2(100) := ' 00:00:00';
  gv_max_time                CONSTANT VARCHAR2(100) := ' 23:59:59';
--
  -- 移動ロット詳細の固定値
  gt_document_type_prod      CONSTANT xxinv_mov_lot_details.document_type_code  %TYPE := '40'; -- 文書タイプ 生産
  gt_document_type_po        CONSTANT xxinv_mov_lot_details.document_type_code  %TYPE := '50'; -- 文書タイプ 発注
  gt_actual_confirm_class_n  CONSTANT xxinv_mov_lot_details.actual_confirm_class%TYPE := 'N' ; -- 実績計上済フラグ 未計上
  gt_actual_confirm_class_y  CONSTANT xxinv_mov_lot_details.actual_confirm_class%TYPE := 'Y' ; -- 実績計上済フラグ 計上済
--
  -- 保留在庫トランザクションの固定値
  gt_delete_y                CONSTANT ic_tran_pnd.delete_mark   %TYPE := 1;      -- 削除フラグ：削除
  gt_delete_n                CONSTANT ic_tran_pnd.delete_mark   %TYPE := 0;      -- 削除フラグ：削除されていない
  gt_complete_y              CONSTANT ic_tran_pnd.completed_ind %TYPE := 1;      -- EBSに実績反映済
  gt_complete_n              CONSTANT ic_tran_pnd.completed_ind %TYPE := 0;      -- EBSに実績未反映
  gt_doc_type_prod           CONSTANT ic_tran_pnd.doc_type      %TYPE := 'PROD'; -- 文書タイプ：生産
--
  -- 発注の固定値
-- Ver1.1 M.Hokkanji Start
  gt_status_ukeari           CONSTANT po_headers_all.attribute1 %TYPE := '25'; -- ステータス：受入有
-- Ver1.1 M.Hokkanji End
  gt_status_suukaku          CONSTANT po_headers_all.attribute1 %TYPE := '30'; -- ステータス:数量確定済
  gt_status_kinkaku          CONSTANT po_headers_all.attribute1 %TYPE := '35'; -- ステータス:金額確定済
  gt_aitesaki                CONSTANT po_headers_all.attribute11%TYPE := '3' ; -- 発注区分:相手先在庫
  gt_suukaku_y               CONSTANT po_lines_all.attribute13  %TYPE := 'Y' ; -- 数量確定済フラグ：確定
  gt_suukaku_n               CONSTANT po_lines_all.attribute13  %TYPE := 'N' ; -- 数量確定済フラグ：未確定
  gt_cancel_y                CONSTANT po_lines_all.cancel_flag  %TYPE := 'Y' ; -- 削除フラグ：削除
  gt_cancel_n                CONSTANT po_lines_all.cancel_flag  %TYPE := 'N' ; -- 削除フラグ：削除されていない

--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 移動ロット詳細ID テーブル型
  TYPE t_mov_lot_dtl_id IS TABLE OF xxinv_mov_lot_details.mov_lot_dtl_id%TYPE INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_prod_cnt            NUMBER;            -- 生産件数
  gn_po_cnt              NUMBER;            -- 発注件数
--
  gn_user_id             NUMBER;            -- ユーザID
  gn_login_id            NUMBER;            -- 最終更新ログイン
  gn_conc_request_id     NUMBER;            -- 要求ID
  gn_prog_appl_id        NUMBER;            -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑのｱﾌﾟﾘｹｰｼｮﾝID
  gn_conc_program_id     NUMBER;            -- コンカレント・プログラムID
--
  gd_date_from           DATE;              -- 入力パラメータ.更新日付(FROM)
  gd_date_to             DATE;              -- 入力パラメータ.更新日付(TO)
--
  gn_pro_org_id          NUMBER;            -- 組織ID
  gd_process_date        DATE;              -- 業務日付
  gd_prev_process_date   DATE;              -- 業務日付－１日の直近営業日
--
  /**********************************************************************************
   * Procedure Name   :  initialize
   * Description      :  関連データ取得(A-1)
   ***********************************************************************************/
  PROCEDURE initialize(
    iv_date_from       IN  VARCHAR2          -- IN    ：更新日付(FROM)
   ,iv_date_to         IN  VARCHAR2          -- IN    ：更新日付(TO)
   ,ov_errbuf          OUT VARCHAR2          --   エラー・メッセージ           --# 固定 #
   ,ov_retcode         OUT VARCHAR2          --   リターン・コード             --# 固定 #
   ,ov_errmsg          OUT VARCHAR2)         --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'initialize'; -- プログラム名
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
    -- プロファイルオプション
    cv_pro_sys_ctrl_cal CONSTANT VARCHAR2(26) := 'XXCMN_SYS_CAL_CODE'; -- システム稼働日カレンダコード
    cv_pro_org_id       CONSTANT VARCHAR2(26) := 'ORG_ID';             -- 組織ID
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- =================================
    -- ログイン情報取得
    -- =================================
    gn_user_id          := FND_GLOBAL.USER_ID;         -- ログインユーザID
    gn_login_id         := FND_GLOBAL.LOGIN_ID;        -- ログインID
    gn_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID; -- コンカレント要求ID
    gn_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;    -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑ・ｱﾌﾟﾘｹｰｼｮﾝID
    gn_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID; -- コンカレント・プログラムID
--
    -- =================================
    -- プロファイルオプション取得
    -- =================================
    gn_pro_org_id       := TO_NUMBER(FND_PROFILE.VALUE(cv_pro_org_id)); -- 組織ID
--
    -- 組織IDが取得できない場合、プロファイル取得エラー
    IF ( gn_pro_org_id IS NULL ) THEN
      -- エラーメッセージ取得
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     gv_xxcmn
                    ,gv_msg_xxcmn10002
                    ,gv_tkn_ng_profile
                    ,gv_org_id_name
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- =================================
    -- 更新日付(FROM)の決定
    -- =================================
    -- NULLの場合、システム日付－１日
    IF (iv_date_from IS NULL) THEN
      gd_date_from  := TRUNC(SYSDATE) -1;
--
    -- NULLでない場合、指定した日付を使用
    ELSE
      gd_date_from  := TO_DATE(iv_date_from || gv_min_time, gv_datetime_fmt);
    END IF;
--
    -- =================================
    -- 更新日付(TO)の決定
    -- =================================
    -- NULLの場合、システム日付
    IF (iv_date_from IS NULL) THEN
      gd_date_to  := TO_DATE(TO_CHAR(TRUNC(SYSDATE) -1, cv_date_fmt) || gv_max_time, gv_datetime_fmt);
--
    -- NULLでない場合、指定した日付を使用
    ELSE
      gd_date_to  := TO_DATE(iv_date_to   || gv_max_time, gv_datetime_fmt);
    END IF;
--
  EXCEPTION
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
  END initialize;
--
  /**********************************************************************************
   * Procedure Name   :  chk_param
   * Description      :  パラメータチェック(A-2)
   ***********************************************************************************/
  PROCEDURE chk_param(
    ov_errbuf          OUT VARCHAR2          --   エラー・メッセージ           --# 固定 #
   ,ov_retcode         OUT VARCHAR2          --   リターン・コード             --# 固定 #
   ,ov_errmsg          OUT VARCHAR2)         --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_param'; -- プログラム名
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- =================================
    -- 更新日付がFROM＞TOの場合、日付逆転エラー
    -- =================================
    IF (gd_date_from > gd_date_to) THEN
      -- エラーメッセージ取得
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     gv_xxinv
                    ,gv_msg_xxinv10055   -- 日付逆転エラーメッセージ
                    ,gv_tkn_ship_date    -- トークンSHIP_DATE
                    ,gv_date_from_name   -- トークン値:更新日付(FROM)
                    ,gv_tkn_arrival_date -- トークンARRIVL_DATE
                    ,gv_date_to_name     -- トークン値:更新日付(TO)
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
--
  EXCEPTION
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
  END chk_param;
--
  /**********************************************************************************
   * Procedure Name   :  get_prod_data
   * Description      :  対象データ取得（生産）(A-3)
   ***********************************************************************************/
  PROCEDURE get_prod_data(
    ot_mov_lot_dtl_id  OUT t_mov_lot_dtl_id  --   移動ロット詳細ID 配列
   ,ov_errbuf          OUT VARCHAR2          --   エラー・メッセージ           --# 固定 #
   ,ov_retcode         OUT VARCHAR2          --   リターン・コード             --# 固定 #
   ,ov_errmsg          OUT VARCHAR2)         --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_prod_data'; -- プログラム名
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- =================================
    -- 実績計上済データ取得
    -- =================================
    BEGIN
      SELECT xmld.mov_lot_dtl_id         mov_lot_dtl_id                   -- 移動ロット詳細ID
      BULK COLLECT INTO ot_mov_lot_dtl_id
      FROM   xxinv_mov_lot_details       xmld                             -- 移動ロット詳細（アドオン）
      WHERE  EXISTS(
               SELECT 1
               FROM   ic_tran_pnd             itp                         -- 保留在庫トランザクション
               WHERE  itp.line_id           = xmld.mov_line_id            -- 
               AND    itp.delete_mark       = gt_delete_n                 -- 削除されていない
               AND    itp.completed_ind     = gt_complete_y               -- EBSに実績反映済
               AND    itp.doc_type          = gt_doc_type_prod            -- 生産
               AND    itp.last_update_date >= gd_date_from                -- 最終更新日がパラメータ.更新日付(FROM)から更新日付(TO)の間のデータ
               AND    itp.last_update_date <= gd_date_to                  -- 
             )
      AND    xmld.document_type_code        = gt_document_type_prod       -- 文書タイプ：生産
      AND    xmld.actual_confirm_class      = gt_actual_confirm_class_n   -- すでに移動ロット詳細の実績計上済フラグがYのものは更新不要のため取得しない。
      FOR UPDATE OF xmld.mov_lot_dtl_id NOWAIT
      ;
--
    EXCEPTION
      -- 生産対象データ0件でも処理続行
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
  EXCEPTION
    WHEN lock_expt THEN                           --*** ロック取得エラー ***
      -- エラーメッセージ取得
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     gv_xxcmn
                    ,gv_msg_xxcmn10019   -- ロックエラー
                    ,gv_tkn_table        -- トークンTABLE
                    ,gv_table_name       -- トークン値:移動ロット詳細
                     );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,5000);
      ov_retcode := gv_status_error;
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
  END get_prod_data;
--
  /**********************************************************************************
   * Procedure Name   :  get_po_data
   * Description      :  対象データ取得（発注）(A-4)
   ***********************************************************************************/
  PROCEDURE get_po_data(
    ot_mov_lot_dtl_id  OUT t_mov_lot_dtl_id  --   移動ロット詳細ID 配列
   ,ov_errbuf          OUT VARCHAR2          --   エラー・メッセージ           --# 固定 #
   ,ov_retcode         OUT VARCHAR2          --   リターン・コード             --# 固定 #
   ,ov_errmsg          OUT VARCHAR2)         --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_po_data'; -- プログラム名
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- =================================
    -- 実績計上済データ取得
    -- =================================
    BEGIN
      SELECT xmld.mov_lot_dtl_id         mov_lot_dtl_id                             -- 移動ロット詳細ID
      BULK COLLECT INTO ot_mov_lot_dtl_id
      FROM   xxinv_mov_lot_details       xmld                                       -- 移動ロット詳細（アドオン）
            ,po_lines_all                pla                                        -- 発注明細
            ,po_headers_all              pha                                        -- 発注ヘッダ
      WHERE  pla.po_line_id               = xmld.mov_line_id
      AND    pla.po_header_id             = pha.po_header_id
      AND    xmld.document_type_code      = gt_document_type_po                     -- 発注
      AND    xmld.actual_confirm_class    = gt_actual_confirm_class_n               -- すでに移動ロット詳細の実績計上済フラグがYのものは更新不要のため取得しない。
      AND    pla.attribute13              = gt_suukaku_y                            -- 数量確定済
      AND    pla.cancel_flag              = gt_cancel_n                             -- 削除されていない
      AND    pla.attribute12             IS NOT NULL                                -- 相手先在庫入庫先
      AND    pha.org_id                   = gn_pro_org_id                           -- 組織ID
-- Ver1.1 M.Hokkanji Start
--      AND    pha.attribute1              IN (gt_status_suukaku,gt_status_kinkaku)   -- 数量確定済,金額確定済
      AND    pha.attribute1              IN (gt_status_ukeari,gt_status_suukaku,gt_status_kinkaku)   -- 受入有,数量確定済,金額確定済
-- Ver1.1 M.Hokkanji End
      AND    pha.attribute11              = gt_aitesaki                             -- 発注区分：相手先在庫
      AND    pla.last_update_date        >= gd_date_from                            -- 最終更新日がパラメータ.更新日付(FROM)から更新日付(TO)の間のデータ
      AND    pla.last_update_date        <= gd_date_to                              -- 
      FOR UPDATE OF xmld.mov_lot_dtl_id NOWAIT
      ;
--
    EXCEPTION
      -- 発注対象データ0件でも処理続行
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
  EXCEPTION
    WHEN lock_expt THEN                           --*** ロック取得エラー ***
      -- エラーメッセージ取得
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     gv_xxcmn
                    ,gv_msg_xxcmn10019   -- ロックエラー
                    ,gv_tkn_table        -- トークンTABLE
                    ,gv_table_name       -- トークン値:移動ロット詳細
                     );
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
  END get_po_data;
--
  /**********************************************************************************
   * Procedure Name   :  upd_actual_confirm_class
   * Description      :  実績計上済フラグ更新  (A-5)
   ***********************************************************************************/
  PROCEDURE upd_actual_confirm_class(
    it_mov_lot_dtl_id  IN  t_mov_lot_dtl_id  --   移動ロット詳細ID 配列
   ,ov_errbuf          OUT VARCHAR2          --   エラー・メッセージ           --# 固定 #
   ,ov_retcode         OUT VARCHAR2          --   リターン・コード             --# 固定 #
   ,ov_errmsg          OUT VARCHAR2)         --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_actual_confirm_class'; -- プログラム名
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- =================================
    -- 移動ロット詳細の実績計上済フラグ更新
    -- =================================
    FORALL ln_cnt IN it_mov_lot_dtl_id.FIRST .. it_mov_lot_dtl_id.LAST
      UPDATE xxinv_mov_lot_details       xmld                            -- 移動ロット詳細
      SET    xmld.actual_confirm_class      = gt_actual_confirm_class_y  -- 実績計上済フラグ＝「Y:実績計上済」
            ,xmld.last_updated_by           = gn_user_id                 -- 最終更新者
            ,xmld.last_update_date          = SYSDATE                    -- 最終更新日
            ,xmld.last_update_login         = gn_login_id                -- 最終更新ログイン
            ,xmld.request_id                = gn_conc_request_id         -- 要求ID
            ,xmld.program_application_id    = gn_prog_appl_id            -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑ・ｱﾌﾟﾘｹｰｼｮﾝID
            ,xmld.program_id                = gn_conc_program_id         -- コンカレント・プログラムID
            ,xmld.program_update_date       = SYSDATE                    -- プログラム更新日
      WHERE  xmld.mov_lot_dtl_id            = it_mov_lot_dtl_id(ln_cnt)
      ;
--
  EXCEPTION
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
  END upd_actual_confirm_class;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_date_from  IN  VARCHAR2     --   更新日付(FROM)
   ,iv_date_to    IN  VARCHAR2     --   更新日付(TO)
   ,ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2)    --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lt_prod_id  t_mov_lot_dtl_id;  --   生産 移動ロット詳細ID 配列
    lt_po_id    t_mov_lot_dtl_id;  --   発注 移動ロット詳細ID 配列
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    gn_prod_cnt   := 0;
    gn_po_cnt     := 0;
--
    -- ===============================
    -- A-1.初期処理
    -- ===============================
    initialize(
      iv_date_from          => iv_date_from                         -- IN    ：更新日付(FROM)
     ,iv_date_to            => iv_date_to                           -- IN    ：更新日付(TO)
     ,ov_errbuf             => lv_errbuf                            -- OUT   ：エラー・メッセージ
     ,ov_retcode            => lv_retcode                           -- OUT   ：リターン・コード
     ,ov_errmsg             => lv_errmsg                            -- OUT   ：ユーザー・エラー・メッセージ
    );
--
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2.パラメータチェック
    -- ===============================
    chk_param(
      ov_errbuf             => lv_errbuf                            -- OUT   ：エラー・メッセージ
     ,ov_retcode            => lv_retcode                           -- OUT   ：リターン・コード
     ,ov_errmsg             => lv_errmsg                            -- OUT   ：ユーザー・エラー・メッセージ
    );
--
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-3.対象データ取得（生産）
    -- ===============================
    get_prod_data(
      ot_mov_lot_dtl_id     => lt_prod_id                           -- OUT   ：移動ロット詳細ID 配列
     ,ov_errbuf             => lv_errbuf                            -- OUT   ：エラー・メッセージ
     ,ov_retcode            => lv_retcode                           -- OUT   ：リターン・コード
     ,ov_errmsg             => lv_errmsg                            -- OUT   ：ユーザー・エラー・メッセージ
    );
--
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-4.対象データ取得（発注）
    -- ===============================
    get_po_data(
      ot_mov_lot_dtl_id     => lt_po_id                             -- OUT   ：移動ロット詳細ID 配列
     ,ov_errbuf             => lv_errbuf                            -- OUT   ：エラー・メッセージ
     ,ov_retcode            => lv_retcode                           -- OUT   ：リターン・コード
     ,ov_errmsg             => lv_errmsg                            -- OUT   ：ユーザー・エラー・メッセージ
    );
--
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-5.実績計上済フラグ更新
    -- ===============================
    -- 生産に対象データがある場合
    IF (lt_prod_id.COUNT <> 0) THEN
      upd_actual_confirm_class(
       it_mov_lot_dtl_id     => lt_prod_id            -- IN    ：移動ロット詳細ID 配列
      ,ov_errbuf             => lv_errbuf             -- OUT   ：エラー・メッセージ
      ,ov_retcode            => lv_retcode            -- OUT   ：リターン・コード
      ,ov_errmsg             => lv_errmsg             -- OUT   ：ユーザー・エラー・メッセージ
      );
--
      -- エラーの場合
      IF (lv_retcode = gv_status_error) THEN
       --(エラー処理)
       RAISE global_process_expt;
      END IF;
    END IF;
--
    -- 発注に対象データがある場合
    IF (lt_po_id.COUNT <> 0) THEN
      upd_actual_confirm_class(
       it_mov_lot_dtl_id     => lt_po_id              -- IN    ：移動ロット詳細ID 配列
      ,ov_errbuf             => lv_errbuf             -- OUT   ：エラー・メッセージ
      ,ov_retcode            => lv_retcode            -- OUT   ：リターン・コード
      ,ov_errmsg             => lv_errmsg             -- OUT   ：ユーザー・エラー・メッセージ
      );
--
      -- エラーの場合
      IF (lv_retcode = gv_status_error) THEN
       --(エラー処理)
       RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ===============================
    -- 更新件数取得
    -- ===============================
    gn_normal_cnt := lt_prod_id.COUNT + lt_po_id.COUNT; -- 全件
    gn_prod_cnt   := lt_prod_id.COUNT;                  -- 生産件数
    gn_po_cnt     := lt_po_id.COUNT;                    -- 発注件数
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
--
  PROCEDURE main(
    errbuf               OUT VARCHAR2      --   エラー・メッセージ  --# 固定 #
   ,retcode              OUT VARCHAR2      --   リターン・コード    --# 固定 #
   ,iv_date_from         IN  VARCHAR2      --   更新日付(FROM)
   ,iv_date_to           IN  VARCHAR2      --   更新日付(TO)
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
--
    --実行コンカレント名出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00002','CONC',gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --区切り文字出力
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      iv_date_from --   更新日付(FROM)
     ,iv_date_to   --   更新日付(TO
     ,lv_errbuf    -- エラー・メッセージ           --# 固定 #
     ,lv_retcode   -- リターン・コード             --# 固定 #
     ,lv_errmsg);  -- ユーザー・エラー・メッセージ --# 固定 #
--
--###########################  固定部 START   #####################################################
--
    -- ======================
    -- エラー・メッセージ出力
    -- ======================
    IF (lv_retcode = gv_status_error) THEN
      IF (lv_errmsg IS NULL) THEN
        --定型メッセージ・セット
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10030');
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
    -- ==================================
    -- リターン・コードのセット、終了処理
    -- ==================================
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'入力パラメータ');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'　更新日付(FROM)：'|| TO_CHAR(gd_date_from, 'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'　更新日付(TO)  ：'|| TO_CHAR(gd_date_to,   'YYYY/MM/DD HH24:MI:SS'));
    --区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'移動ロット詳細更新件数(全件)：'|| TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'移動ロット詳細更新件数(生産)：'|| TO_CHAR(gn_prod_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'移動ロット詳細更新件数(発注)：'|| TO_CHAR(gn_po_cnt));
--
    --ステータス出力
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = userenv('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type, 
                                                                      flv.view_application_id)
    AND    flv.lookup_type         = 'CP_STATUS_CODE'
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            gv_status_normal,gv_sts_cd_normal,
                                            gv_status_warn,gv_sts_cd_warn,
                                            gv_sts_cd_error)
    AND    ROWNUM                  = 1;
--
    --処理ステータス出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00012','STATUS',gv_conc_status);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
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
END xxinv450001c;
/
