CREATE OR REPLACE PACKAGE BODY XXCOI009A05R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI009A05R(body)
 * Description      : 消化ＶＤ商品別チェックリスト
 * MD.050           : 消化ＶＤ商品別チェックリスト <MD050_XXCOI_009_A05>
 * Version          : V1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  del_svf_data            ワークテーブルデータ削除    (A-7)
 *  call_output_svf         SVF起動                     (A-6)
 *  ins_svf_data            入出庫情報取得              (A-3)
 *                          消化計算情報取得            (A-4)
 *                          ワークテーブルデータ登録    (A-5)
 *  get_base_info           拠点情報取得                (A-2)
 *  init                    初期処理                    (A-1)
 *  submain                 メイン処理プロシージャ
 *  main                    コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2010/03/02    1.0   H.Sasaki         初版作成
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
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
  cv_pkg_name               CONSTANT VARCHAR2(100)  :=  'XXCOI009A05R';           --  パッケージ名
  -- SVF起動関数パラメータ用
  cv_conc_name              CONSTANT VARCHAR2(30)   :=  'XXCOI009A05R';           --  コンカレント名
  cv_file_id                CONSTANT VARCHAR2(30)   :=  'XXCOI009A05R';           --  帳票ID
  cv_type_pdf               CONSTANT VARCHAR2(4)    :=  '.pdf';                   --  拡張子（PDF）
  cv_output_mode            CONSTANT VARCHAR2(30)   :=  '1';                      --  出力区分
  cv_frm_file               CONSTANT VARCHAR2(30)   :=  'XXCOI009A05S.xml';       --  フォーム様式ファイル名
  cv_vrq_file               CONSTANT VARCHAR2(30)   :=  'XXCOI009A05S.vrq';       --  クエリー様式ファイル名
  -- メッセージ
  cv_short_name_xxcoi       CONSTANT VARCHAR2(5)    :=  'XXCOI';                  --  アプリケーション短縮名
  cv_msg_xxcoi1_00005       CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-00005';       --  在庫組織コード取得エラーメッセージ
  cv_msg_xxcoi1_00006       CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-00006';       --  在庫組織ID取得エラーメッセージ
  cv_msg_xxcoi1_00008       CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-00008';       --  対象データ無しメッセージ
  cv_msg_xxcoi1_00009       CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-00009';       --  拠点名取得エラーメッセージ
  cv_msg_xxcoi1_00011       CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-00011';       --  業務日付取得エラーメッセージ
  cv_msg_xxcoi1_00019       CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-00019';       --  顧客名取得エラーメッセージ
  cv_msg_xxcoi1_10119       CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-10119';       --  SVF起動APIエラーメッセージ
  cv_msg_xxcoi1_10337       CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-10337';       --  日付パラメータ整合性エラーメッセージ
  cv_msg_xxcoi1_10414       CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-10414';       --  拠点情報取得エラーメッセージ
  cv_msg_xxcoi1_10415       CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-10415';       --  消化VD商品別チェックリストパラメータ値メッセージ
  cv_msg_xxcoi1_10416       CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-10416';       --  日付パラメータ指定範囲エラーメッセージ
  -- メッセージ（トークン）
  cv_token_00005            CONSTANT VARCHAR2(30)   :=  'PRO_TOK';
  cv_token_00006            CONSTANT VARCHAR2(30)   :=  'ORG_CODE_TOK ';
  cv_token_00009            CONSTANT VARCHAR2(30)   :=  'DEPT_CODE_TOK';
  cv_token_00019            CONSTANT VARCHAR2(30)   :=  'CUSTOMER_CODE';
  cv_token_10414            CONSTANT VARCHAR2(30)   :=  'BASE_CODE';
  cv_token_10415_1          CONSTANT VARCHAR2(30)   :=  'BASE_CODE';
  cv_token_10415_2          CONSTANT VARCHAR2(30)   :=  'BASE_NAME';
  cv_token_10415_3          CONSTANT VARCHAR2(30)   :=  'DATE_FROM';
  cv_token_10415_4          CONSTANT VARCHAR2(30)   :=  'DATE_TO';
  cv_token_10415_5          CONSTANT VARCHAR2(30)   :=  'CONCLUSION_DAY';
  cv_token_10415_6          CONSTANT VARCHAR2(30)   :=  'CUST_CODE';
  cv_token_10415_7          CONSTANT VARCHAR2(30)   :=  'CUST_NAME';
  --
  cv_log                    CONSTANT VARCHAR2(3)    :=  'LOG';                -- コンカレントヘッダ出力先
  --
  -- プロファイル
  cv_prf_name_orgcd         CONSTANT VARCHAR2(30)   :=  'XXCOI1_ORGANIZATION_CODE';   -- プロファイル名（在庫組織コード）
  -- コード値
  cv_invoice_type_4         CONSTANT VARCHAR2(1)    :=  '4';                      --  伝票区分 4
  cv_invoice_type_5         CONSTANT VARCHAR2(1)    :=  '5';                      --  伝票区分 5
  cv_invoice_type_6         CONSTANT VARCHAR2(1)    :=  '6';                      --  伝票区分 6
  cv_invoice_type_7         CONSTANT VARCHAR2(1)    :=  '7';                      --  伝票区分 7
  cv_record_type_30         CONSTANT VARCHAR2(2)    :=  '30';                     --  レコードタイプ  30 入出庫
  cv_cust_class_1           CONSTANT VARCHAR2(1)    :=  '1';                      --  顧客区分 1  拠点
  cv_cust_class_10          CONSTANT VARCHAR2(2)    :=  '10';                     --  顧客区分 10 顧客
  -- その他
  cv_yes                    CONSTANT VARCHAR2(1)    :=  'Y';
  cv_no                     CONSTANT VARCHAR2(1)    :=  'N';
  cv_d                      CONSTANT VARCHAR2(1)    :=  'D';
  cv_space                  CONSTANT VARCHAR2(1)    :=  ' ';
  cv_comma                  CONSTANT VARCHAR2(1)    :=  ',';
  cv_slash                  CONSTANT VARCHAR2(1)    :=  '/';
  cv_date_type              CONSTANT VARCHAR2(8)    :=  'YYYYMMDD';
  cv_date_type_2            CONSTANT VARCHAR2(10)   :=  'YYYY/MM/DD';
  cv_date_type_3            CONSTANT VARCHAR2(21)   :=  'YYYY/MM/DD HH24:MI:SS';
  cv_date_type_4            CONSTANT VARCHAR2(7)    :=  'YYYY/MM';
  cv_default_time           CONSTANT VARCHAR2(8)    :=  '00:00:00';
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- 拠点情報
  TYPE  g_base_info_rtype   IS  RECORD(
      base_code     xxcoi_rep_vd_item_chklist.base_code%TYPE          --  拠点コード
    , base_name     xxcoi_rep_vd_item_chklist.base_name%TYPE          --  拠点名称
  );
  TYPE  g_base_info_ttype   IS  TABLE OF g_base_info_rtype INDEX BY BINARY_INTEGER;
  tab_base_info     g_base_info_ttype;
  --
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 起動パラメータ
  gt_base_code              xxcoi_rep_vd_item_chklist.base_code%TYPE;             --  拠点コード
  gd_date_from              DATE;                                                 --  出力期間(FROM)
  gd_date_to                DATE;                                                 --  出力期間(TO)
  gt_conclusion_day         xxcoi_rep_vd_item_chklist.conclusion_day_param%TYPE;  --  締め日
  gt_customer_code          xxcoi_rep_vd_item_chklist.customer_code%TYPE;         --  顧客コード
  --
  -- 共通データ
  gv_f_organization_code    VARCHAR2(30);                                     --  在庫組織コード
  gn_f_organization_id      NUMBER;                                           --  在庫組織ID
  gd_f_process_date         DATE;                                             --  業務処理日付
  gv_nodata_msg             VARCHAR2(5000);                                   --  対象データなしメッセージ
  --
  -- ===============================
  -- ユーザー定義カーソル
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : del_svf_data
   * Description      : ワークテーブルデータ削除(A-7)
   ***********************************************************************************/
  PROCEDURE del_svf_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_svf_data'; -- プログラム名
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
--
    -- *** ローカル変数 ***
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
    -- <カーソル名>レコード型
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
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
    -- 帳票ワークテーブルの削除（今回対象データのみ）
    DELETE  xxcoi_rep_vd_item_chklist
    WHERE   request_id    =   cn_request_id;
    --
  EXCEPTION
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
  END del_svf_data;
--
  /**********************************************************************************
   * Procedure Name   : call_output_svf
   * Description      : SVF起動(A-6)
   ***********************************************************************************/
  PROCEDURE call_output_svf(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'call_output_svf'; -- プログラム名
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
--
    -- *** ローカル変数 ***
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
    -- <カーソル名>レコード型
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
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
    -- ===============================
    --  1.SVF起動
    -- ===============================
    xxccp_svfcommon_pkg.submit_svf_request(
       iv_conc_name         =>    cv_conc_name                        -- コンカレント名
      ,iv_file_name         =>    cv_file_id 
                              ||  TO_CHAR(SYSDATE, cv_date_type)
                              ||  TO_CHAR(cn_request_id)
                              ||  cv_type_pdf                         -- 出力ファイル名
      ,iv_file_id           =>    cv_file_id                          -- 帳票ID
      ,iv_output_mode       =>    cv_output_mode                      -- 出力区分
      ,iv_frm_file          =>    cv_frm_file                         -- フォーム様式ファイル名
      ,iv_vrq_file          =>    cv_vrq_file                         -- クエリー様式ファイル名
      ,iv_org_id            =>    fnd_global.org_id                   -- ORG_ID
      ,iv_user_name         =>    fnd_global.user_name                -- ログイン・ユーザ名
      ,iv_resp_name         =>    fnd_global.resp_name                -- ログイン・ユーザの職責名
      ,iv_doc_name          =>    NULL                                -- 文書名
      ,iv_printer_name      =>    NULL                                -- プリンタ名
      ,iv_request_id        =>    cn_request_id                       -- 要求ID
      ,iv_nodata_msg        =>    NULL                                -- データなしメッセージ
      ,ov_retcode           =>    lv_retcode                          -- リターンコード
      ,ov_errbuf            =>    lv_errbuf                           -- エラーメッセージ
      ,ov_errmsg            =>    lv_errmsg                           -- ユーザー・エラーメッセージ
    );
    -- 終了パラメータ判定
    IF (lv_retcode  <>  cv_status_normal) THEN
      -- SVF起動APIエラーメッセージ
      lv_errmsg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_short_name_xxcoi
                      ,iv_name         => cv_msg_xxcoi1_10119
                     );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF; 
   --
  EXCEPTION
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
  END call_output_svf;
--
  /**********************************************************************************
   * Procedure Name   : edit_conclusion_day
   * Description      : 締め日編集処理
   ***********************************************************************************/
  PROCEDURE edit_conclusion_day(
    iv_material1  IN  VARCHAR2,     --  締め日１
    iv_material2  IN  VARCHAR2,     --  締め日２
    iv_material3  IN  VARCHAR2,     --  締め日３
    ov_conc_day   OUT VARCHAR2,     --  締め日
    ov_errbuf     OUT VARCHAR2,     --  エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --  リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --  ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'edit_conclusion_day'; -- プログラム名
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
--
    -- *** ローカル変数 ***
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
    -- <カーソル名>レコード型
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
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
    -- 設定されている締め日を、日付順にカンマ区切りで１データに編集
    IF (iv_material1 IS NOT NULL AND iv_material2 IS NOT NULL AND iv_material3 IS NOT NULL) THEN
      IF (TO_NUMBER(iv_material1) <= TO_NUMBER(iv_material2)) THEN
        IF (TO_NUMBER(iv_material2) <= TO_NUMBER(iv_material3)) THEN
          ov_conc_day :=  iv_material1 || cv_comma || iv_material2 || cv_comma || iv_material3;
        ELSIF (TO_NUMBER(iv_material1) <= TO_NUMBER(iv_material3)) THEN
          ov_conc_day :=  iv_material1 || cv_comma || iv_material3 || cv_comma || iv_material2;
        ELSE
          ov_conc_day :=  iv_material3 || cv_comma || iv_material1 || cv_comma || iv_material2;
        END IF;
      ELSE
        IF (TO_NUMBER(iv_material1) <= TO_NUMBER(iv_material3)) THEN
          ov_conc_day :=  iv_material2 || cv_comma || iv_material1 || cv_comma || iv_material3;
        ELSIF (TO_NUMBER(iv_material2) <= TO_NUMBER(iv_material3)) THEN
          ov_conc_day :=  iv_material2 || cv_comma || iv_material3 || cv_comma || iv_material1;
        ELSE
          ov_conc_day :=  iv_material3 || cv_comma || iv_material2 || cv_comma || iv_material1;
        END IF;
      END IF;
    ELSIF (iv_material1 IS NOT NULL AND iv_material2 IS NOT NULL AND iv_material3 IS NULL) THEN
      IF (TO_NUMBER(iv_material1) <= TO_NUMBER(iv_material2)) THEN
        ov_conc_day :=  iv_material1 || cv_comma || iv_material2;
      ELSE
        ov_conc_day :=  iv_material2 || cv_comma || iv_material1;
      END IF;
    ELSIF (iv_material1 IS NOT NULL AND iv_material2 IS NULL AND iv_material3 IS NOT NULL) THEN
      IF (TO_NUMBER(iv_material1) <= TO_NUMBER(iv_material3)) THEN
        ov_conc_day :=  iv_material1 || cv_comma || iv_material3;
      ELSE
        ov_conc_day :=  iv_material3 || cv_comma || iv_material1;
      END IF;
    ELSIF (iv_material1 IS NULL AND iv_material2 IS NOT NULL AND iv_material3 IS NOT NULL) THEN
      IF (TO_NUMBER(iv_material2) <= TO_NUMBER(iv_material3)) THEN
        ov_conc_day :=  iv_material2 || cv_comma || iv_material3;
      ELSE
        ov_conc_day :=  iv_material3 || cv_comma || iv_material2;
      END IF;
    ELSIF (iv_material1 IS NOT NULL AND iv_material2 IS NULL AND iv_material3 IS NULL) THEN
      ov_conc_day :=  iv_material1;
    ELSIF (iv_material1 IS NULL AND iv_material2 IS NOT NULL AND iv_material3 IS NULL) THEN
      ov_conc_day :=  iv_material2;
    ELSIF (iv_material1 IS NULL AND iv_material2 IS NULL AND iv_material3 IS NOT NULL) THEN
      ov_conc_day :=  iv_material3;
    ELSE
      ov_conc_day :=  NULL;
    END IF;
    --
  EXCEPTION
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
  END edit_conclusion_day;
--
  /**********************************************************************************
   * Procedure Name   : ins_svf_data
   * Description      : 入出庫情報取得            (A-3)
   *                  : 消化計算情報取得          (A-4)
   *                  : ワークテーブルデータ登録  (A-5)
   ***********************************************************************************/
  PROCEDURE ins_svf_data(
    iv_base_code  IN  VARCHAR2,     --  拠点
    iv_base_name  IN  VARCHAR2,     --  拠点名称
    ov_errbuf     OUT VARCHAR2,     --  エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --  リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --  ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_svf_data'; -- プログラム名
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
--
    -- *** ローカル変数 ***
    lv_conc_day                 VARCHAR2(8);                  --  編集締め日
    ln_target_cnt               NUMBER  :=  0;                --  拠点別対象件数
    ln_dummy                    NUMBER;                       --  ダミー
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
    CURSOR  cur_tran_data
    IS
      SELECT  sub.base_code                   base_code         --  拠点
            , hca2.account_name               base_name         --  拠点名称
            , sub.account_number              customer_code     --  顧客
            , hp.party_name                   customer_name     --  顧客名称
            , sub.item_code                   item_code         --  品目コード
            , ximb.item_short_name            item_name         --  品目名称
            , xca.conclusion_day1             conclusion_day1   --  消化計算締め日１
            , xca.conclusion_day2             conclusion_day2   --  消化計算締め日２
            , xca.conclusion_day3             conclusion_day3   --  消化計算締め日３
            , SUM(
                    CASE  WHEN  sub.data_type = 1 THEN  sub.quantity
                          ELSE  0
                    END
              )     stock_quantity            --  入庫数量
            , SUM(
                    CASE  WHEN  sub.data_type = 2 THEN  sub.quantity
                          ELSE  0
                    END
              )     ship_quantity             --  出庫数量
      FROM    hz_cust_accounts                    hca1                          --  顧客マスタ（顧客）
            , hz_cust_accounts                    hca2                          --  顧客マスタ（拠点）
            , xxcmm_cust_accounts                 xca                           --  顧客アドオン
            , hz_parties                          hp                            --  パーティー
            , mtl_system_items_b                  msib                          --  品目マスタ
            , ic_item_mst_b                       iimb                          --  OPM品目
            , xxcmn_item_mst_b                    ximb                          --  OPM品目アドオン
            , ( SELECT
                        xhit.base_code                base_code                 --  拠点
                      , xhit.inside_code              account_number            --  顧客（入庫側）
                      , xhit.item_code                item_code                 --  品目
                      , NVL(xhit.total_quantity, 0)   quantity                  --  数量
                      , 1                             data_type                 --  データタイプ（1:入庫側）
                FROM    xxcoi_hht_inv_transactions    xhit                      --  HHT入出庫一時表
                      , hz_cust_accounts              hca                       --  顧客マスタ
                WHERE   xhit.invoice_date             >=  gd_date_from
                AND     xhit.invoice_date             <   gd_date_to + 1
                AND     xhit.invoice_type             IN(cv_invoice_type_4, cv_invoice_type_5, cv_invoice_type_6, cv_invoice_type_7)
                AND     xhit.record_type              =   cv_record_type_30
                AND     xhit.consume_vd_flag          =   cv_yes
                AND     xhit.inside_code              =   hca.account_number
                AND     xhit.base_code                =   iv_base_code
                AND     xhit.inside_code              =   NVL(gt_customer_code, xhit.inside_code)
                AND     hca.customer_class_code       =   cv_cust_class_10
                UNION ALL
                SELECT
                        xhit.base_code                base_code                 --  拠点
                      , xhit.outside_code             account_number            --  顧客（出庫側）
                      , xhit.item_code                item_code                 --  品目
                      , NVL(xhit.total_quantity, 0)   quantity                  --  数量
                      , 2                             data_type                 --  データタイプ（2:出庫側）
                FROM    xxcoi_hht_inv_transactions    xhit                      --  HHT入出庫一時表
                      , hz_cust_accounts              hca                       --  顧客マスタ
                WHERE   xhit.invoice_date             >=  gd_date_from
                AND     xhit.invoice_date             <   gd_date_to + 1
                AND     xhit.invoice_type             IN(cv_invoice_type_4, cv_invoice_type_5, cv_invoice_type_6, cv_invoice_type_7)
                AND     xhit.record_type              =   cv_record_type_30
                AND     xhit.consume_vd_flag          =   cv_yes
                AND     xhit.outside_code             =   hca.account_number
                AND     xhit.base_code                =   iv_base_code
                AND     xhit.outside_code             =   NVL(gt_customer_code, xhit.outside_code)
                AND     hca.customer_class_code       =   cv_cust_class_10
              )     sub
      WHERE   sub.account_number        =   hca1.account_number
      AND     sub.item_code             =   msib.segment1
      AND     sub.base_code             =   hca2.account_number
      AND     hca1.cust_account_id      =   xca.customer_id
      AND     hca1.party_id             =   hp.party_id
      AND     msib.segment1             =   iimb.item_no
      AND     iimb.item_id              =   ximb.item_id
      AND     hca1.customer_class_code  =   cv_cust_class_10
      AND     hca2.customer_class_code  =   cv_cust_class_1
      AND     msib.organization_id      =   gn_f_organization_id
      AND     (   xca.conclusion_day1   =   gt_conclusion_day
               OR xca.conclusion_day2   =   gt_conclusion_day
               OR xca.conclusion_day3   =   gt_conclusion_day
              )
      AND     gd_f_process_date   BETWEEN   ximb.start_date_active
                                  AND       NVL(ximb.end_date_active, gd_f_process_date)
      GROUP BY
              sub.base_code
            , hca2.account_name
            , sub.account_number
            , hp.party_name
            , sub.item_code
            , ximb.item_short_name
            , xca.conclusion_day1
            , xca.conclusion_day2
            , xca.conclusion_day3;
    --
    CURSOR  cur_digestion_due
    IS
      SELECT  xvdh.sales_base_code        base_code         --  拠点
            , hca2.account_name           base_name         --  拠点名称
            , xvdh.customer_number        customer_code     --  顧客
            , hp.party_name               customer_name     --  顧客名称
            , xvdl.item_code              item_code         --  品目コード
            , ximb.item_short_name        item_name         --  品目名称
            , xca.conclusion_day1         conclusion_day1   --  消化計算締め日１
            , xca.conclusion_day2         conclusion_day2   --  消化計算締め日２
            , xca.conclusion_day3         conclusion_day3   --  消化計算締め日３
            , SUM(CASE  WHEN  xvdh.sales_result_creation_flag IN(cv_yes, cv_d) THEN xvdl.sales_quantity
                        ELSE 0
                  END
              )                           sales_quantity    --  売上計上済
            , SUM(CASE  WHEN  (xvdh.sales_result_creation_flag = cv_no OR xvdh.sales_result_creation_flag IS NULL) THEN xvdl.sales_quantity
                        ELSE 0
                  END
              )                           digestion_due_qty --  今回消化計算対象
      FROM    xxcos_vd_digestion_lns      xvdl              --  消化VD用消化計算明細テーブル
            , xxcos_vd_digestion_hdrs     xvdh              --  消化VD用消化計算ヘッダテーブル
            , hz_cust_accounts            hca1              --  顧客マスタ（顧客）
            , hz_cust_accounts            hca2              --  顧客マスタ（拠点）
            , xxcmm_cust_accounts         xca               --  顧客アドオン
            , hz_parties                  hp                --  パーティー
            , mtl_system_items_b          msib              --  品目マスタ
            , ic_item_mst_b               iimb              --  OPM品目マスタ
            , xxcmn_item_mst_b            ximb              --  OPM品目アドオン
      WHERE   xvdh.vd_digestion_hdr_id  =   xvdl.vd_digestion_hdr_id
      AND     xvdh.sales_base_code      =   hca2.account_number
      AND     xvdh.customer_number      =   hca1.account_number
      AND     hca1.cust_account_id      =   xca.customer_id
      AND     hca1.party_id             =   hp.party_id
      AND     xvdl.item_code            =   msib.segment1
      AND     msib.segment1             =   iimb.item_no
      AND     iimb.item_id              =   ximb.item_id
      AND     xvdh.sales_base_code      =   iv_base_code
      AND     xvdh.customer_number      =   NVL(gt_customer_code, xvdh.customer_number)
      AND     xvdh.digestion_due_date   >=  gd_date_from
      AND     xvdh.digestion_due_date   <   gd_date_to + 1
      AND     xvdh.uncalculate_class    IN('0', '2', '4')
      AND     hca1.customer_class_code  =   cv_cust_class_10
      AND     hca2.customer_class_code  =   cv_cust_class_1
      AND     msib.organization_id      =   gn_f_organization_id
      AND     (   xca.conclusion_day1   =   gt_conclusion_day
               OR xca.conclusion_day2   =   gt_conclusion_day
               OR xca.conclusion_day3   =   gt_conclusion_day
              )
      AND     gd_f_process_date   BETWEEN   ximb.start_date_active
                                  AND       NVL(ximb.end_date_active, gd_f_process_date)
      GROUP BY
              xvdh.sales_base_code
            , hca2.account_name
            , xvdh.customer_number
            , hp.party_name
            , xvdl.item_code
            , ximb.item_short_name
            , xca.conclusion_day1
            , xca.conclusion_day2
            , xca.conclusion_day3;
    --
    -- <カーソル名>レコード型
    rec_tran_data       cur_tran_data%ROWTYPE;
    rec_digestion_due   cur_digestion_due%ROWTYPE;
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
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
    -- ===========================================
    --  入出庫情報設定
    -- ===========================================
    OPEN  cur_tran_data;
    --
    LOOP
      FETCH cur_tran_data INTO  rec_tran_data;
      EXIT WHEN cur_tran_data%NOTFOUND;
      ln_target_cnt :=  ln_target_cnt + 1;
      --
      -- ------------------------
      --  締め日編集
      -- ------------------------
      edit_conclusion_day(
          iv_material1  =>  rec_tran_data.conclusion_day1
        , iv_material2  =>  rec_tran_data.conclusion_day2
        , iv_material3  =>  rec_tran_data.conclusion_day3
        , ov_conc_day   =>  lv_conc_day
        , ov_errbuf     =>  lv_errbuf           --  エラー・メッセージ           --# 固定 #
        , ov_retcode    =>  lv_retcode          --  リターン・コード             --# 固定 #
        , ov_errmsg     =>  lv_errmsg           --  ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      INSERT INTO xxcoi_rep_vd_item_chklist(
          base_code                             --  01.拠点コード
        , base_name                             --  02.拠点名
        , customer_code                         --  03.顧客コード
        , customer_name                         --  04.顧客名称
        , item_code                             --  05.品目コード
        , item_name                             --  06.品目名称
        , date_from                             --  07.出力期間（From)
        , date_to                               --  08.出力期間（To)
        , conclusion_day_param                  --  09.締め日（指定）
        , conclusion_day                        --  10.締め日
        , stock_qty                             --  11.入庫数量
        , ship_qty                              --  12.出庫数量
        , sales_qty                             --  13.売上計上済数量
        , digestion_due_qty                     --  14.今回消化計算対象数量
        , customer_specify_flag                 --  15.顧客指定
        , message                               --  16.メッセージ
        , created_by                            --  17.作成者
        , creation_date                         --  18.作成日
        , last_updated_by                       --  19.最終更新者
        , last_update_date                      --  20.最終更新日
        , last_update_login                     --  21.最終更新ログイン
        , request_id                            --  22.要求ID
        , program_application_id                --  23.コンカレント・プログラム・アプリケーションID
        , program_id                            --  24.コンカレント・プログラムID
        , program_update_date                   --  25.プログラム更新日
      )VALUES(
          rec_tran_data.base_code                       --  01
        , SUBSTRB(rec_tran_data.base_name, 1, 20)       --  02
        , rec_tran_data.customer_code                   --  03
        , SUBSTRB(rec_tran_data.customer_name, 1, 80)   --  04
        , rec_tran_data.item_code                       --  05
        , SUBSTRB(rec_tran_data.item_name, 1, 20)       --  06
        , TO_CHAR(gd_date_from, cv_date_type_2)         --  07
        , TO_CHAR(gd_date_to, cv_date_type_2)           --  08
        , gt_conclusion_day                             --  09
        , lv_conc_day                                   --  10
        , rec_tran_data.stock_quantity                  --  11
        , rec_tran_data.ship_quantity                   --  12
        , 0                                             --  13
        , 0                                             --  14
        , CASE  WHEN  gt_customer_code IS NULL THEN  '0'
                ELSE  '1'
          END                                           --  15
        , NULL                                          --  16
        , cn_created_by                                 --  17
        , SYSDATE                                       --  18
        , cn_last_updated_by                            --  19
        , SYSDATE                                       --  20
        , cn_last_update_login                          --  21
        , cn_request_id                                 --  22
        , cn_program_application_id                     --  23
        , cn_program_id                                 --  24
        , SYSDATE                                       --  25
      );
    END LOOP;
    --
    CLOSE cur_tran_data;
    --
    -- ===========================================
    --  消化計算情報設定
    -- ===========================================
    OPEN cur_digestion_due;
    --
    <<digestion_due_loop>>
    LOOP
      FETCH cur_digestion_due INTO  rec_digestion_due;
      EXIT WHEN cur_digestion_due%NOTFOUND;
      --
      BEGIN
        SELECT  1
        INTO    ln_dummy
        FROM    xxcoi_rep_vd_item_chklist   xrvic
        WHERE   xrvic.base_code       =   rec_digestion_due.base_code
        AND     xrvic.customer_code   =   rec_digestion_due.customer_code
        AND     xrvic.item_code       =   rec_digestion_due.item_code
        AND     xrvic.request_id      =   cn_request_id;
        --
        UPDATE  xxcoi_rep_vd_item_chklist
        SET     sales_qty             =   rec_digestion_due.sales_quantity      --  14.売上計上済数量
              , digestion_due_qty     =   rec_digestion_due.digestion_due_qty   --  15.今回消化計算対象数量
        WHERE   base_code             =   rec_digestion_due.base_code
        AND     customer_code         =   rec_digestion_due.customer_code
        AND     item_code             =   rec_digestion_due.item_code
        AND     request_id            =   cn_request_id;
        --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          ln_target_cnt :=  ln_target_cnt + 1;
          --
          -- ------------------------
          --  締め日編集
          -- ------------------------
          edit_conclusion_day(
              iv_material1  =>  rec_digestion_due.conclusion_day1
            , iv_material2  =>  rec_digestion_due.conclusion_day2
            , iv_material3  =>  rec_digestion_due.conclusion_day3
            , ov_conc_day   =>  lv_conc_day
            , ov_errbuf     =>  lv_errbuf           --  エラー・メッセージ           --# 固定 #
            , ov_retcode    =>  lv_retcode          --  リターン・コード             --# 固定 #
            , ov_errmsg     =>  lv_errmsg           --  ユーザー・エラー・メッセージ --# 固定 #
          );
          --
          INSERT INTO xxcoi_rep_vd_item_chklist(
              base_code                             --  01.拠点コード
            , base_name                             --  02.拠点名
            , customer_code                         --  03.顧客コード
            , customer_name                         --  04.顧客名称
            , item_code                             --  05.品目コード
            , item_name                             --  06.品目名称
            , date_from                             --  07.出力期間（From)
            , date_to                               --  08.出力期間（To)
            , conclusion_day_param                  --  09.締め日（指定）
            , conclusion_day                        --  10.締め日
            , stock_qty                             --  11.入庫数量
            , ship_qty                              --  12.出庫数量
            , sales_qty                             --  13.売上計上済数量
            , digestion_due_qty                     --  14.今回消化計算対象数量
            , customer_specify_flag                 --  15.顧客指定
            , message                               --  16.メッセージ
            , created_by                            --  17.作成者
            , creation_date                         --  18.作成日
            , last_updated_by                       --  19.最終更新者
            , last_update_date                      --  20.最終更新日
            , last_update_login                     --  21.最終更新ログイン
            , request_id                            --  22.要求ID
            , program_application_id                --  23.コンカレント・プログラム・アプリケーションID
            , program_id                            --  24.コンカレント・プログラムID
            , program_update_date                   --  25.プログラム更新日
          )VALUES(
              rec_digestion_due.base_code                       --  01
            , SUBSTRB(rec_digestion_due.base_name, 1, 20)       --  02
            , rec_digestion_due.customer_code                   --  03
            , SUBSTRB(rec_digestion_due.customer_name, 1, 80)   --  04
            , rec_digestion_due.item_code                       --  05
            , SUBSTRB(rec_digestion_due.item_name, 1, 20)       --  06
            , TO_CHAR(gd_date_from, cv_date_type_2)             --  07
            , TO_CHAR(gd_date_to, cv_date_type_2)               --  08
            , gt_conclusion_day                                 --  09
            , lv_conc_day                                       --  10
            , 0                                                 --  11
            , 0                                                 --  12
            , rec_digestion_due.sales_quantity                  --  13
            , rec_digestion_due.digestion_due_qty               --  14
            , CASE  WHEN  gt_customer_code IS NULL THEN  '0'
                    ELSE  '1'
              END                                               --  15
            , NULL                                              --  16
            , cn_created_by                                     --  17
            , SYSDATE                                           --  18
            , cn_last_updated_by                                --  19
            , SYSDATE                                           --  20
            , cn_last_update_login                              --  21
            , cn_request_id                                     --  22
            , cn_program_application_id                         --  23
            , cn_program_id                                     --  24
            , SYSDATE                                           --  25
          );
      END;
      --
    END LOOP;
    --
    CLOSE cur_digestion_due;
    --
    --
    -- ===========================================
    --  対象件数０件時設定
    -- ===========================================
    IF (ln_target_cnt = 0) THEN
      --
      INSERT INTO xxcoi_rep_vd_item_chklist(
          base_code                             --  01.拠点コード
        , base_name                             --  02.拠点名
        , customer_code                         --  03.顧客コード
        , customer_name                         --  04.顧客名称
        , item_code                             --  05.品目コード
        , item_name                             --  06.品目名称
        , date_from                             --  07.出力期間（From)
        , date_to                               --  08.出力期間（To)
        , conclusion_day_param                  --  09.締め日（指定）
        , conclusion_day                        --  10.締め日
        , stock_qty                             --  11.入庫数量
        , ship_qty                              --  12.出庫数量
        , sales_qty                             --  13.売上計上済数量
        , digestion_due_qty                     --  14.今回消化計算対象数量
        , customer_specify_flag                 --  15.顧客指定
        , message                               --  16.メッセージ
        , created_by                            --  17.作成者
        , creation_date                         --  18.作成日
        , last_updated_by                       --  19.最終更新者
        , last_update_date                      --  20.最終更新日
        , last_update_login                     --  21.最終更新ログイン
        , request_id                            --  22.要求ID
        , program_application_id                --  23.コンカレント・プログラム・アプリケーションID
        , program_id                            --  24.コンカレント・プログラムID
        , program_update_date                   --  25.プログラム更新日
      )VALUES(
          iv_base_code                          --  01
        , SUBSTRB(iv_base_name, 1, 20)          --  02
        , NULL                                  --  03
        , NULL                                  --  04
        , NULL                                  --  05
        , NULL                                  --  06
        , TO_CHAR(gd_date_from, cv_date_type_2) --  07
        , TO_CHAR(gd_date_to, cv_date_type_2)   --  08
        , gt_conclusion_day                     --  09
        , NULL                                  --  10
        , NULL                                  --  11
        , NULL                                  --  12
        , NULL                                  --  13
        , NULL                                  --  14
        , '0'                                   --  15
        , gv_nodata_msg                         --  16
        , cn_created_by                         --  17
        , SYSDATE                               --  18
        , cn_last_updated_by                    --  19
        , SYSDATE                               --  20
        , cn_last_update_login                  --  21
        , cn_request_id                         --  22
        , cn_program_application_id             --  23
        , cn_program_id                         --  24
        , SYSDATE                               --  25
      );
    END IF;
    --
    gn_target_cnt :=  gn_target_cnt + ln_target_cnt;
    gn_normal_cnt :=  gn_normal_cnt + ln_target_cnt;
    --
  EXCEPTION
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
  END ins_svf_data;
--
  /**********************************************************************************
   * Procedure Name   : get_base_info
   * Description      : 拠点情報取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_base_info(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_base_info'; -- プログラム名
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
--
    -- *** ローカル変数 ***
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
    CURSOR  cur_base_info
    IS
      SELECT  hca.account_number                          --  拠点コード
            , SUBSTRB(hca.account_name, 1, 20)            --  拠点名称
      FROM    hz_cust_accounts          hca
            , xxcmm_cust_accounts       xca
      WHERE   hca.cust_account_id       =   xca.customer_id
      AND     xca.management_base_code  =   gt_base_code
      AND     hca.customer_class_code   =   cv_cust_class_1
      UNION
      SELECT  hca.account_number                          --  拠点コード
            , SUBSTRB(hca.account_name, 1, 20)            --  拠点名称
      FROM    hz_cust_accounts          hca
      WHERE   hca.account_number        =   gt_base_code
      AND     hca.customer_class_code   =   cv_cust_class_1;
    --
    -- <カーソル名>レコード型
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
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
    -- カーソルオープン
    OPEN  cur_base_info;
    FETCH cur_base_info BULK COLLECT INTO tab_base_info;
    --
    IF (tab_base_info.COUNT = 0) THEN
      -- 抽出データが0件の場合
      -- 拠点情報取得エラーメッセージ
      lv_errbuf   :=  xxccp_common_pkg.get_msg(
                          iv_application      =>  cv_short_name_xxcoi
                        , iv_name             =>  cv_msg_xxcoi1_10414
                          , iv_token_name1    =>  cv_token_10414
                          , iv_token_value1   =>  gt_base_code
                      );
      lv_errmsg   :=  lv_errbuf;
      RAISE global_process_expt;
    END IF;
    --
    CLOSE cur_base_info;
   --
  EXCEPTION
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
  END get_base_info;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
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
    lv_output_msg         VARCHAR2(5000);                               --  メッセージ設定
    lt_base_name          hz_cust_accounts.account_name%TYPE;           --  拠点名称
    lt_customer_name      hz_parties.party_name%TYPE;                   --  顧客名称
    ld_date_to            DATE;
--
    -- *** ローカル・カーソル ***
--
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
    -- ==================================
    --  1.出力期間編集
    -- ==================================
    IF (gt_conclusion_day = '30') THEN
      -- 月末締め日が指定されている場合、出力期間(TO)の月末日を設定
      gd_date_to  :=  LAST_DAY(gd_date_to);
    ELSE
      -- 
      BEGIN
        -- 上記以外の場合、出力期間(TO)の日付を月末締め日に置換え
        ld_date_to  :=  TO_DATE( TO_CHAR(gd_date_to, cv_date_type_4) || cv_slash || gt_conclusion_day || cv_default_time, cv_date_type_3);
        gd_date_to  :=  ld_date_to;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
    END IF;
    --
    -- ==================================
    --  2.起動パラメータログ出力
    -- ==================================
    --  拠点名称取得
    BEGIN
      SELECT  hca.account_name
      INTO    lt_base_name
      FROM    hz_cust_accounts      hca
      WHERE   hca.account_number        =   gt_base_code
      AND     hca.customer_class_code   =   cv_cust_class_1;
      --
    EXCEPTION
      WHEN  NO_DATA_FOUND THEN
        -- 拠点名取得エラーメッセージ
        lv_errbuf   :=  xxccp_common_pkg.get_msg(
                            iv_application    =>  cv_short_name_xxcoi
                          , iv_name           =>  cv_msg_xxcoi1_00009
                          , iv_token_name1    =>  cv_token_00009
                          , iv_token_value1   =>  gt_base_code
                        );
        lv_errmsg   :=  lv_errbuf;
        RAISE global_process_expt;
    END;
    --
    -- 顧客名称取得
    IF (gt_customer_code IS NOT NULL) THEN
      BEGIN
        SELECT  hp.party_name
        INTO    lt_customer_name
        FROM    hz_cust_accounts      hca
              , hz_parties            hp
        WHERE   hca.account_number        =   gt_customer_code
        AND     hca.party_id              =   hp.party_id
        AND     hca.customer_class_code   =   cv_cust_class_10;
        --
      EXCEPTION
        WHEN  NO_DATA_FOUND THEN
          -- 拠点名取得エラーメッセージ
          lv_errbuf   :=  xxccp_common_pkg.get_msg(
                              iv_application    =>  cv_short_name_xxcoi
                            , iv_name           =>  cv_msg_xxcoi1_00019
                            , iv_token_name1    =>  cv_token_00019
                            , iv_token_value1   =>  gt_base_code
                          );
          lv_errmsg   :=  lv_errbuf;
          RAISE global_process_expt;
      END;
    END IF;
    --
    -- メッセージ設定
    lv_output_msg   :=  xxccp_common_pkg.get_msg(
                            iv_application    =>  cv_short_name_xxcoi
                          , iv_name           =>  cv_msg_xxcoi1_10415
                          , iv_token_name1    =>  cv_token_10415_1
                          , iv_token_value1   =>  gt_base_code
                          , iv_token_name2    =>  cv_token_10415_2
                          , iv_token_value2   =>  lt_base_name
                          , iv_token_name3    =>  cv_token_10415_3
                          , iv_token_value3   =>  TO_CHAR(gd_date_from, cv_date_type_2)
                          , iv_token_name4    =>  cv_token_10415_4
                          , iv_token_value4   =>  TO_CHAR(gd_date_to, cv_date_type_2)
                          , iv_token_name5    =>  cv_token_10415_5
                          , iv_token_value5   =>  gt_conclusion_day
                          , iv_token_name6    =>  cv_token_10415_6
                          , iv_token_value6   =>  gt_customer_code
                          , iv_token_name7    =>  cv_token_10415_7
                          , iv_token_value7   =>  lt_customer_name
                        );
    -- メッセージ出力
    fnd_file.put_line(
        which   =>  FND_FILE.LOG
      , buff    =>  lv_output_msg
    );
    -- 空行を出力
    fnd_file.put_line(
        which   =>  FND_FILE.LOG
      , buff    =>  cv_space
    );
    --
    -- ==================================
    --  3.パラメータ妥当性チェック
    -- ==================================
    IF  (gd_date_from > gd_date_to) THEN
      -- 出力期間 FROM よりも TO が過去日付の場合
      -- 日付パラメータ整合性エラーメッセージ
      lv_errbuf   :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_short_name_xxcoi
                        , iv_name           =>  cv_msg_xxcoi1_10337
                      );
      lv_errmsg   :=  lv_errbuf;
      RAISE global_process_expt;
      --
    ELSIF (ADD_MONTHS(gd_date_from, 1) <= gd_date_to)  THEN
      -- 出力期間 FROM から TO が１ヶ月以上の場合
      -- 日付パラメータ指定範囲エラーメッセージ
      lv_errbuf   :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_short_name_xxcoi
                        , iv_name           =>  cv_msg_xxcoi1_10416
                      );
      lv_errmsg   :=  lv_errbuf;
      RAISE global_process_expt;
      --
    END IF;
    --
    -- ==================================
    --  4.初期値設定
    -- ==================================
    -- 在庫組織コード取得
    gv_f_organization_code  :=  fnd_profile.value(cv_prf_name_orgcd);
    --
    IF (gv_f_organization_code IS NULL) THEN
      -- 在庫組織コードが取得されなかった場合
      -- 在庫組織コード取得エラーメッセージ
      lv_errbuf   :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_short_name_xxcoi
                        , iv_name           =>  cv_msg_xxcoi1_00005
                        , iv_token_name1    =>  cv_token_00005
                        , iv_token_value1   =>  cv_prf_name_orgcd
                     );
      lv_errmsg   :=  lv_errbuf;
      RAISE global_process_expt;
    END IF;
    --
    -- 在庫組織ID取得
    gn_f_organization_id  :=  xxcoi_common_pkg.get_organization_id(gv_f_organization_code);
    --
    IF (gn_f_organization_id IS NULL) THEN
      -- 在庫組織IDが取得されなかった場合
      -- 在庫組織ID取得エラーメッセージ
      lv_errbuf   :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_short_name_xxcoi
                        , iv_name           =>  cv_msg_xxcoi1_00006
                        , iv_token_name1    =>  cv_token_00006
                        , iv_token_value1   =>  gv_f_organization_code
                      );
      lv_errmsg   :=  lv_errbuf;
      RAISE global_process_expt;
    END IF;
    --
    -- 業務処理日付取得
    gd_f_process_date   :=  xxccp_common_pkg2.get_process_date;
    --
    IF (gd_f_process_date IS NULL) THEN
      -- 業務処理日付が取得できなかった場合
      -- 業務日付の取得に失敗しました。
      lv_errbuf   :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_short_name_xxcoi
                       ,iv_name         => cv_msg_xxcoi1_00011
                      );
      lv_errmsg   :=  lv_errbuf;
      RAISE global_process_expt;
    END IF;
    --
    -- 対象データなしメッセージ
    gv_nodata_msg :=  xxccp_common_pkg.get_msg(
                          iv_application      =>  cv_short_name_xxcoi
                        , iv_name             =>  cv_msg_xxcoi1_00008
                      );
    --
  EXCEPTION
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
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_base_code      IN  VARCHAR2,     --  拠点コード
    iv_date_from      IN  VARCHAR2,     --  出力期間(FROM)
    iv_date_to        IN  VARCHAR2,     --  出力期間(TO)
    iv_conclusion_day IN  VARCHAR2,     --  締め日
    iv_customer_code  IN  VARCHAR2,     --  顧客コード
    ov_errbuf         OUT VARCHAR2,     --  エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,     --  リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)     --  ユーザー・エラー・メッセージ --# 固定 #
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
    -- <カーソル名>レコード型
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================================
    --  グローバル値設定
    -- ===============================================
    gn_target_cnt       :=  0;                                        --  対象件数
    gn_normal_cnt       :=  0;                                        --  正常件数
    gn_warn_cnt         :=  0;                                        --  警告件数
    gn_error_cnt        :=  0;                                        --  エラー件数
    --
    gt_base_code        :=  iv_base_code;                             --  拠点コード
    gd_date_from        :=  TO_DATE(iv_date_from, cv_date_type_3);    --  出力期間(FROM)
    gd_date_to          :=  TO_DATE(iv_date_to, cv_date_type_3);      --  出力期間(TO)
    gt_conclusion_day   :=  iv_conclusion_day;                        --  締め日
    gt_customer_code    :=  iv_customer_code;                         --  顧客コード
    --
    -- ===============================
    --  A-1.初期処理
    -- ===============================
    init(
        ov_errbuf     =>  lv_errbuf           --  エラー・メッセージ           --# 固定 #
      , ov_retcode    =>  lv_retcode          --  リターン・コード             --# 固定 #
      , ov_errmsg     =>  lv_errmsg           --  ユーザー・エラー・メッセージ --# 固定 #
    );
    --  終了判定
    IF  (lv_retcode <>  cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- ===============================
    --  A-2.拠点情報取得
    -- ===============================
    get_base_info(
        ov_errbuf     =>  lv_errbuf           --  エラー・メッセージ           --# 固定 #
      , ov_retcode    =>  lv_retcode          --  リターン・コード             --# 固定 #
      , ov_errmsg     =>  lv_errmsg           --  ユーザー・エラー・メッセージ --# 固定 #
    );
    --  終了判定
    IF  (lv_retcode <>  cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    --
    --
    <<base_info_loop>>
    FOR  ln_cnt  IN  1 .. tab_base_info.COUNT  LOOP
      --
      -- ===============================
      --  A-3.入出庫情報取得
      --  A-4.消化計算情報取得
      --  A-5.ワークテーブルデータ登録
      -- ===============================
      ins_svf_data(
          iv_base_code  =>  tab_base_info(ln_cnt).base_code       --  拠点コード
        , iv_base_name  =>  tab_base_info(ln_cnt).base_name       --  拠点名称
        , ov_errbuf     =>  lv_errbuf           --  エラー・メッセージ           --# 固定 #
        , ov_retcode    =>  lv_retcode          --  リターン・コード             --# 固定 #
        , ov_errmsg     =>  lv_errmsg           --  ユーザー・エラー・メッセージ --# 固定 #
      );
      --  終了判定
      IF  (lv_retcode <>  cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
      --
    END LOOP base_info_loop;
    --
    -- SVF用ワークテーブルの確定
    COMMIT;
    --
    -- ===============================
    --  A-6.SVF起動
    -- ===============================
    call_output_svf(
        ov_errbuf     =>  lv_errbuf           --  エラー・メッセージ           --# 固定 #
      , ov_retcode    =>  lv_retcode          --  リターン・コード             --# 固定 #
      , ov_errmsg     =>  lv_errmsg           --  ユーザー・エラー・メッセージ --# 固定 #
    );
    --  終了判定
    IF  (lv_retcode <>  cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- ===============================
    --  A-7.ワークテーブルデータ削除
    -- ===============================
    del_svf_data(
        ov_errbuf     =>  lv_errbuf           --  エラー・メッセージ           --# 固定 #
      , ov_retcode    =>  lv_retcode          --  リターン・コード             --# 固定 #
      , ov_errmsg     =>  lv_errmsg           --  ユーザー・エラー・メッセージ --# 固定 #
    );
    --  終了判定
    IF  (lv_retcode <>  cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    --
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
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
    errbuf            OUT VARCHAR2,       --  エラー・メッセージ  --# 固定 #
    retcode           OUT VARCHAR2,       --  リターン・コード    --# 固定 #
    iv_base_code      IN  VARCHAR2,       --  拠点コード
    iv_date_from      IN  VARCHAR2,       --  出力期間(FROM)
    iv_date_to        IN  VARCHAR2,       --  出力期間(TO)
    iv_conclusion_day IN  VARCHAR2,       --  締め日
    iv_customer_code  IN  VARCHAR2        --  顧客コード
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
       iv_which   =>  cv_log
      ,ov_retcode =>  lv_retcode
      ,ov_errbuf  =>  lv_errbuf
      ,ov_errmsg  =>  lv_errmsg
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
        iv_base_code        =>  iv_base_code        --  拠点コード
      , iv_date_from        =>  iv_date_from        --  出力期間(FROM)
      , iv_date_to          =>  iv_date_to          --  出力期間(TO)
      , iv_conclusion_day   =>  iv_conclusion_day   --  締め日
      , iv_customer_code    =>  iv_customer_code    --  顧客コード
      , ov_errbuf           =>  lv_errbuf           --  エラー・メッセージ           --# 固定 #
      , ov_retcode          =>  lv_retcode          --  リターン・コード             --# 固定 #
      , ov_errmsg           =>  lv_errmsg           --  ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode <> cv_status_normal) THEN
      gn_error_cnt  :=  1;
      gn_normal_cnt :=  0;
      --
      --エラー出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
      -- 空行出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_space
      );
    END IF;
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
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
    fnd_file.put_line(
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
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    -- 空行出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_space
    );
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
    fnd_file.put_line(
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
END XXCOI009A05R;
/
