CREATE OR REPLACE PACKAGE BODY XXCFF003A31C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF003A31C(body)
 * Description      : リース契約登録一覧
 * MD.050           : リース契約登録一覧 MD050_CFF_003_A31
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   入力パラメータ値ログ出力処理(A-1)
 *  chk_input_param        入力パラメータチェック処理(A-2)
 *  get_lease_contr_list   リース契約登録一覧情報取得処理(A-3)
 *  ins_lease_contr_wk     リース契約登録一覧ワークデータ作成処理(A-4)
 *  submit_svf_request     SVF起動処理(A-5)
 *  del_lease_contr_wk     データ削除処理(A-6)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/05    1.0   SCS山岸          main新規作成
 *  2009/02/27    1.1   SCS山岸          SVF出力関数に対応
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
  cv_pkg_name         CONSTANT VARCHAR2(100) := 'XXCFF003A31C'; -- パッケージ名
  cv_appl_short_name  CONSTANT VARCHAR2(100) := 'XXCFF';        -- アプリケーション短縮名
  cv_which            CONSTANT VARCHAR2(100) := 'LOG';          -- コンカレントログ出力先
  -- メッセージ
  cv_msg_vld_fr_to    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00018'; -- パラメータ妥当性チェックエラー
  cv_msg_ins_err      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00102'; -- 登録エラー
  cv_msg_del_err      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00104'; -- 削除エラー
  cv_msg_no_lines     CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00010'; -- 明細0件用メッセージ
  cv_msg_lock_err     CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00007'; -- ロックエラー
  -- トークン名
  cv_tkn_column_name  CONSTANT VARCHAR2(20)  := 'COLUMN_NAME';      -- カラム名
  cv_tkn_table_name   CONSTANT VARCHAR2(20)  := 'TABLE_NAME';       -- テーブル名
  cv_tkn_err_info     CONSTANT VARCHAR2(20)  := 'INFO';             -- エラー情報
  -- トークン値
  cv_tkv_lease_st_dt  CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50046'; -- リース開始日
  cv_tkv_wk_tab_name  CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50152'; -- リース契約登録一覧帳票ワークテーブル
  -- 契約ステータス
  cv_st_contract      CONSTANT VARCHAR2(3) := '202';  -- 契約
  cv_st_re_lease      CONSTANT VARCHAR2(3) := '203';  -- 再リース
  -- 支払頻度
  cv_pmt_type_mon     CONSTANT VARCHAR2(1) := '0';    -- 月
  cv_pmt_type_year    CONSTANT VARCHAR2(1) := '1';    -- 年
  -- リース種類
  cv_lease_kind_op    CONSTANT VARCHAR2(1) := '1';    -- Op
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  TYPE g_wk_ttype IS TABLE OF xxcff_rep_contr_list_wk%ROWTYPE INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : del_lease_contr_wk
   * Description      : データ削除処理(A-6)
   ***********************************************************************************/
  PROCEDURE del_lease_contr_wk(
    ov_errbuf         OUT VARCHAR2,      --   エラー・メッセージ                  --# 固定 #
    ov_retcode        OUT VARCHAR2,      --   リターン・コード                    --# 固定 #
    ov_errmsg         OUT VARCHAR2)      --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_lease_contr_wk'; -- プログラム名
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
    CURSOR contr_list_wk_cur
    IS
      SELECT request_id
        FROM xxcff_rep_contr_list_wk
       WHERE request_id = cn_request_id
      FOR UPDATE NOWAIT;
--
    -- *** ローカル・レコード ***
    TYPE l_request_id_ttype IS TABLE OF xxcff_rep_contr_list_wk.request_id%TYPE INDEX BY BINARY_INTEGER;
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
      OPEN contr_list_wk_cur;
      FETCH contr_list_wk_cur BULK COLLECT INTO l_request_id_tab;
      CLOSE contr_list_wk_cur;
    EXCEPTION
      WHEN OTHERS THEN
        IF (contr_list_wk_cur%ISOPEN) THEN
          CLOSE contr_list_wk_cur;
        END IF;
        lv_errbuf := SQLERRM;
        lv_errmsg := xxccp_common_pkg.get_msg(
                        cv_appl_short_name, cv_msg_lock_err
                       ,cv_tkn_table_name, cv_tkv_wk_tab_name);
        RAISE global_process_expt;
    END;
    -- ワークデータ削除
    DELETE FROM xxcff_rep_contr_list_wk
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
  END del_lease_contr_wk;
--
  /**********************************************************************************
   * Procedure Name   : submit_svf_request
   * Description      : SVF起動処理(A-5)
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
    cv_rep_id    CONSTANT VARCHAR2(20) := 'XXCFF003A31';  -- 帳票ID
    cv_svf_fname CONSTANT VARCHAR2(20) := 'XXCFF003A31S'; -- SVFファイル名
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
   * Procedure Name   : ins_lease_contr_wk
   * Description      : リース契約登録一覧ワークデータ作成処理(A-4)
   ***********************************************************************************/
  PROCEDURE ins_lease_contr_wk(
    i_wk_tab          IN  g_wk_ttype,    -- 1.リース契約登録一覧ワークデータ
    ov_errbuf         OUT VARCHAR2,      --   エラー・メッセージ                  --# 固定 #
    ov_retcode        OUT VARCHAR2,      --   リターン・コード                    --# 固定 #
    ov_errmsg         OUT VARCHAR2)      --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_lease_contr_wk'; -- プログラム名
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
    FORALL i IN 1..NVL(i_wk_tab.LAST,0) SAVE EXCEPTIONS
      INSERT INTO xxcff_rep_contr_list_wk VALUES i_wk_tab(i);
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
      ov_errmsg  := xxccp_common_pkg.get_msg(
                       cv_appl_short_name, cv_msg_ins_err
                      ,cv_tkn_table_name, cv_tkv_wk_tab_name
                      ,cv_tkn_err_info, ''
                      );
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM(-SQL%BULK_EXCEPTIONS(1).ERROR_CODE);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_lease_contr_wk;
--
  /**********************************************************************************
   * Procedure Name   : get_lease_contr_list
   * Description      : リース契約登録一覧情報取得処理(A-3)
   ***********************************************************************************/
  PROCEDURE get_lease_contr_list(
    id_lease_st_date_fr  IN  DATE,          -- 1.リース開始日FROM
    id_lease_st_date_to  IN  DATE,          -- 2.リース開始日TO
    iv_lease_company     IN  VARCHAR2,      -- 3.リース会社コード
    iv_lease_class_fr    IN  VARCHAR2,      -- 4.リース種別FROM
    iv_lease_class_to    IN  VARCHAR2,      -- 5.リース種別TO
    iv_lease_type        IN  VARCHAR2,      -- 6.リース区分
    ov_errbuf            OUT VARCHAR2,      --   エラー・メッセージ                  --# 固定 #
    ov_retcode           OUT VARCHAR2,      --   リターン・コード                    --# 固定 #
    ov_errmsg            OUT VARCHAR2)      --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lease_contr_list'; -- プログラム名
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
    cn_bulk_size  CONSTANT PLS_INTEGER  := 200;
--
    -- *** ローカル変数 ***
    l_wk_tab    g_wk_ttype;
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- リース契約登録一覧情報
    CURSOR lease_contr_cur
    IS
      SELECT (SELECT xlcv.lease_company_code ||' '|| xlcv.lease_company_name
                FROM xxcff_lease_company_v xlcv
               WHERE xlcv.lease_company_code = xch.lease_company
              ) AS lease_company                -- リース会社
            ,xch.contract_number                -- 契約No
            ,xch.comments                       -- 件名
            ,(SELECT xlsv.lease_class_name
                FROM xxcff_lease_class_v xlsv
               WHERE xlsv.lease_class_code = xch.lease_class
              ) AS lease_class                  -- リース種別
            ,(SELECT xltv.lease_type_name
                FROM xxcff_lease_type_v xltv
               WHERE xltv.lease_type_code = xch.lease_type
              ) AS lease_type                   -- リース区分
            ,TO_CHAR(xch.contract_date,'yyyy/mm/dd') AS contract_date -- リース契約日
            ,TO_CHAR(xch.lease_start_date,'yyyy/mm/dd') AS lease_start_date -- リース開始日
            ,TO_CHAR(xch.lease_end_date,'yyyy/mm/dd') AS lease_end_date -- リース終了日
            ,xch.payment_frequency              -- 支払回数
            ,(SELECT xptv.payment_type_name
                FROM xxcff_payment_type_v xptv
               WHERE xptv.payment_type_code = xch.payment_type
              ) AS payment_type                 -- 頻度
            ,(CASE xch.payment_type
              WHEN cv_pmt_type_mon THEN xch.payment_frequency
              WHEN cv_pmt_type_year THEN xch.payment_frequency * 12
              END) AS term                      -- 期間
            ,TO_CHAR(xch.first_payment_date,'yyyy/mm/dd') AS first_payment_date -- 初回支払日
            ,TO_CHAR(xch.second_payment_date,'yyyy/mm/dd') AS second_payment_date -- 2回目支払日
            ,LTRIM(TO_CHAR(xch.third_payment_date,'00')) AS third_payment_date -- 3回目以降支払日
            ,SUM(CASE xcl.lease_kind
                 WHEN cv_lease_kind_op THEN 0
                 ELSE 1 END
             ) AS fin_cnt                       -- 明細数（Fin数）
            ,SUM(CASE xcl.lease_kind
                 WHEN cv_lease_kind_op THEN 1
                 ELSE 0 END
             ) AS op_cnt                        -- 明細数（Op数）
            ,SUM(NVL(xhis.estimated_cash_price,xcl.estimated_cash_price)
             ) AS estimated_cash_price          -- 見積現金購入価額
            ,SUM(NVL(xhis.gross_charge,xcl.gross_charge)
             ) AS gross_charge                  -- リース料総額（リース料）
            ,SUM(NVL(xhis.gross_tax_charge,xcl.gross_tax_charge)
             ) AS gross_tax_charge              -- リース料総額（消費税）
            ,SUM(NVL(xhis.gross_total_charge,xcl.gross_total_charge)
             ) AS gross_total_charge            -- リース料総額（計）
            ,SUM(NVL(xhis.gross_deduction,xcl.gross_deduction)
             ) AS gross_deduction               -- 控除額総額（リース料）
            ,SUM(NVL(xhis.gross_tax_deduction,xcl.gross_tax_deduction)
             ) AS gross_tax_deduction           -- 控除額総額（消費税）
            ,SUM(NVL(xhis.gross_total_deduction,xcl.gross_total_deduction)
             ) AS gross_total_deduction         -- 控除額総額（計）
            ,SUM(NVL(xhis.first_charge,xcl.first_charge)
             ) AS first_charge                  -- 初回リース料（リース料）
            ,SUM(NVL(xhis.first_tax_charge,xcl.first_tax_charge)
             ) AS first_tax_charge              -- 初回リース料（消費税）
            ,SUM(NVL(xhis.first_total_charge,xcl.first_total_charge)
             ) AS first_total_charge            -- 初回リース料（計）
            ,SUM(NVL(xhis.second_charge,xcl.second_charge)
             ) AS second_charge                 -- 月額リース料（リース料）
            ,SUM(NVL(xhis.second_tax_charge,xcl.second_tax_charge)
             ) AS second_tax_charge             -- 月額リース料（消費税）
            ,SUM(NVL(xhis.second_total_charge,xcl.second_total_charge)
             ) AS second_total_charge           -- 月額リース料（計）
            -- WHOカラム
            ,cn_created_by             AS created_by
            ,cd_creation_date          AS creation_date
            ,cn_last_updated_by        AS last_updated_by
            ,cd_last_update_date       AS last_update_date
            ,cn_last_update_login      AS last_update_login
            ,cn_request_id             AS request_id
            ,cn_program_application_id AS program_application_id
            ,cn_program_id             AS program_id
            ,cd_program_update_date    AS program_update_date
      FROM xxcff_contract_headers xch
      INNER JOIN xxcff_contract_lines xcl
         ON xch.contract_header_id = xcl.contract_header_id
       LEFT JOIN xxcff_contract_histories xhis
         ON xcl.contract_line_id = xhis.contract_line_id
        AND xch.contract_header_id = xhis.contract_header_id
      WHERE (xhis.contract_status = cv_st_contract
          OR xhis.contract_status = cv_st_re_lease
          OR xhis.contract_status IS NULL)
        AND xcl.expiration_date IS NULL
        AND EXISTS (
            SELECT 'x'
              FROM xxcff_contract_lines xcl2
             WHERE xcl2.contract_header_id = xch.contract_header_id
               AND xcl2.cancellation_date IS NULL)
        AND xch.lease_start_date >= id_lease_st_date_fr
        AND xch.lease_start_date <= NVL(id_lease_st_date_to,xch.lease_start_date)
        AND xch.lease_company = NVL(iv_lease_company,xch.lease_company)
        AND xch.lease_class >= NVL(iv_lease_class_fr,xch.lease_class)
        AND xch.lease_class <= NVL(iv_lease_class_to,xch.lease_class)
        AND xch.lease_type = NVL(iv_lease_type,xch.lease_type)
      GROUP BY
             xch.lease_company                  -- リース会社
            ,xch.contract_number                -- 契約No
            ,xch.lease_start_date               -- リース開始日
            ,xch.lease_end_date                 -- リース終了日
            ,xch.contract_date                  -- リース契約日
            ,xch.comments                       -- 件名
            ,xch.lease_class                    -- リース種別
            ,xch.lease_type                     -- リース区分
            ,xch.payment_frequency              -- 支払回数
            ,xch.payment_type                   -- 頻度
            ,xch.first_payment_date             -- 初回支払日
            ,xch.second_payment_date            -- 2回目支払日
            ,xch.third_payment_date             -- 3回目以降支払日
            ,xch.contract_header_id
      ;
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
    OPEN lease_contr_cur;
    <<main_loop>>
    LOOP
      FETCH lease_contr_cur BULK COLLECT INTO l_wk_tab LIMIT cn_bulk_size;
      EXIT WHEN l_wk_tab.COUNT = 0;
      -- 対象件数インクリメント
      gn_target_cnt := gn_target_cnt + NVL(l_wk_tab.COUNT,0);
      -- ============================================
      -- A-5．リース契約登録一覧ワークデータ作成処理
      -- ============================================
      ins_lease_contr_wk(
         l_wk_tab           -- 1.リース契約登録一覧ワークデータ
        ,lv_errbuf          --   エラー・メッセージ           --# 固定 #
        ,lv_retcode         --   リターン・コード             --# 固定 #
        ,lv_errmsg          --   ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode != cv_status_normal) THEN
        --(エラー処理)
        RAISE global_process_expt;
      END IF;
      -- コレクション初期化
      l_wk_tab.DELETE;
    END LOOP main_loop;
    CLOSE lease_contr_cur;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- カーソルクローズ
      IF (lease_contr_cur%ISOPEN) THEN
        CLOSE lease_contr_cur;
      END IF;
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
  END get_lease_contr_list;
--
  /**********************************************************************************
   * Procedure Name   : chk_input_param
   * Description      : 入力パラメータチェック処理(A-2)
   ***********************************************************************************/
  PROCEDURE chk_input_param(
    id_lease_st_date_fr  IN  DATE,         -- 1.リース開始日FROM
    id_lease_st_date_to  IN  DATE,         -- 2.リース開始日TO
    ov_errbuf            OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode           OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg            OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_input_param'; -- プログラム名
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
    -- リース開始日TOの入力がある場合にFROM <= TO の関係チェック
    IF (id_lease_st_date_to IS NOT NULL) THEN
      IF (id_lease_st_date_fr > id_lease_st_date_to) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                      cv_appl_short_name,cv_msg_vld_fr_to
                     ,cv_tkn_column_name,cv_tkv_lease_st_dt
                   );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_process_expt THEN
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
  END chk_input_param;
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
    id_lease_st_date_fr  IN  DATE,          -- 1.リース開始日FROM
    id_lease_st_date_to  IN  DATE,          -- 2.リース開始日TO
    iv_lease_company     IN  VARCHAR2,      -- 3.リース会社コード
    iv_lease_class_fr    IN  VARCHAR2,      -- 4.リース種別FROM
    iv_lease_class_to    IN  VARCHAR2,      -- 5.リース種別TO
    iv_lease_type        IN  VARCHAR2,      -- 6.リース区分
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
    -- A-2．入力パラメータチェック処理
    -- ============================================
    chk_input_param(
       id_lease_st_date_fr   -- 1.リース開始日FROM
      ,id_lease_st_date_to   -- 2.リース開始日TO
      ,lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode != cv_status_normal) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-3．リース契約登録一覧情報取得処理
    -- ============================================
    get_lease_contr_list(
       id_lease_st_date_fr   -- 1.リース開始日FROM
      ,id_lease_st_date_to   -- 2.リース開始日TO
      ,iv_lease_company      -- 3.リース会社コード
      ,iv_lease_class_fr     -- 4.リース種別FROM
      ,iv_lease_class_to     -- 5.リース種別TO
      ,iv_lease_type         -- 6.リース区分
      ,lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
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
--
    -- ============================================
    -- A-5．SVF起動処理
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
    -- A-6．データ削除処理
    -- ============================================
    del_lease_contr_wk(
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
    iv_lease_st_date_fr  IN  VARCHAR2,      -- 1.リース開始日FROM
    iv_lease_st_date_to  IN  VARCHAR2,      -- 2.リース開始日TO
    iv_lease_company     IN  VARCHAR2,      -- 3.リース会社コード
    iv_lease_class_fr    IN  VARCHAR2,      -- 4.リース種別FROM
    iv_lease_class_to    IN  VARCHAR2,      -- 5.リース種別TO
    iv_lease_type        IN  VARCHAR2       -- 6.リース区分
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
       iv_which   => cv_which
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
       TO_DATE(iv_lease_st_date_fr,'yyyy/mm/dd hh24:mi:ss')  -- 1.リース開始日FROM
      ,TO_DATE(iv_lease_st_date_to,'yyyy/mm/dd hh24:mi:ss')  -- 2.リース開始日TO
      ,iv_lease_company     -- 3.リース会社コード
      ,iv_lease_class_fr    -- 4.リース種別FROM
      ,iv_lease_class_to    -- 5.リース種別TO
      ,iv_lease_type        -- 6.リース区分
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- ============================================
    -- A-7．終了処理
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
--       which  => FND_FILE.LOG
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
END XXCFF003A31C;
/
