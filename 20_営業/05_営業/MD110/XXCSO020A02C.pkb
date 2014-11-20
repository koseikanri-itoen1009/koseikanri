CREATE OR REPLACE PACKAGE BODY APPS.XXCSO020A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO020A02C(body)
 * Description      : フルベンダー用ＳＰ専決・登録画面から渡される情報をもとに指定された
 *                    回送先にワークフロー通知を送付します。
 * MD.050           : MD050_CSO_020_A02_通知・承認ワークフロー機能
 *
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                    初期処理(A-1)
 *  get_notify_info         通知情報抽出(A-2)
 *  start_sp_dec_wf_proc    ＳＰ専決ワークフロー起動(A-7)
 *  submain                 メイン処理プロシージャ
 *                            承認／確認通知送付(A-3)
 *                            否決／返却通知先情報抽出(A-4)
 *                            否決／返却通知送付(A-5)
 *                            申請者向け否決／返却通知送付(A-6)
 *  main                    実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-12-22    1.0   Noriyuki.Yabuki  新規作成
 *  2009-02-05          Kazuo.Satomura   従業員番号からユーザー名を取得
 *  2009-02-27          Noriyuki.Yabuki  ワークフロー用APIの名称を小文字から大文字に修正
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897対応
 *  2009-06-29    1.2   Kazuo.Satomura   統合テスト障害対応(0000209)
 *  2009-10-21    1.3   Daisuke.Abe      E_T4_00050対応
 *****************************************************************************************/
  --
  --#######################  固定グローバル定数宣言部 START   #######################
  --
  -- ステータス・コード
  cv_status_normal CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal;  -- 正常:0
  cv_status_warn   CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;    -- 警告:1
  cv_status_error  CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;   -- 異常:2
  --
  -- WHOカラム
  cn_created_by             CONSTANT NUMBER := fnd_global.user_id;          -- CREATED_BY
  cd_creation_date          CONSTANT DATE   := SYSDATE;                     -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER := fnd_global.user_id;          -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE   := SYSDATE;                     -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER := fnd_global.login_id;         -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER := fnd_global.conc_request_id;  -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER := fnd_global.prog_appl_id;     -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER := fnd_global.conc_program_id;  -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE   := SYSDATE;                     -- PROGRAM_UPDATE_DATE
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
  global_process_expt       EXCEPTION;
  --
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
  --
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
  --
  --################################  固定部 END   ##################################
  --
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name              CONSTANT VARCHAR2(100) := 'XXCSO020A02C';  -- パッケージ名
  cv_sales_appl_short_name CONSTANT VARCHAR2(5)   := 'XXCSO';         -- 営業用アプリケーション短縮名
  cv_com_appl_short_name   CONSTANT VARCHAR2(5)   := 'XXCCP';         -- 共通用アプリケーション短縮名
  --
  -- メッセージコード
  cv_tkn_number_01 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011';  -- 業務処理日付取得エラー
  cv_tkn_number_02 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00382';  -- 入力パラメータ必須エラー
  cv_tkn_number_03 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00323';  -- データ取得エラー
  cv_tkn_number_04 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00324';  -- データ抽出時例外エラー
  cv_tkn_number_05 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00340';  -- ワークフローAPIエラー
  --
  -- トークンコード
  cv_tkn_item     CONSTANT VARCHAR2(20) := 'ITEM';
  cv_tkn_table    CONSTANT VARCHAR2(20) := 'TABLE';
  cv_tkn_key      CONSTANT VARCHAR2(20) := 'KEY';
  cv_tkn_err_msg  CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_func_nm  CONSTANT VARCHAR2(20) := 'FUNC_NAME';
  --
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  --
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  --
  --
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      iv_notify_type           IN         VARCHAR2    -- 通知区分
    , it_sp_decision_header_id IN         xxcso_sp_decision_headers.sp_decision_header_id%TYPE  -- ＳＰ専決ヘッダＩＤ
    , iv_send_employee_number  IN         VARCHAR2    -- 回送元従業員番号
    , iv_dest_employee_number  IN         VARCHAR2    -- 回送先従業員番号
    , od_process_date          OUT NOCOPY DATE        -- 業務処理日付
    , ov_errbuf                OUT NOCOPY VARCHAR2    -- エラー・メッセージ --# 固定 #
    , ov_retcode               OUT NOCOPY VARCHAR2    -- リターン・コード   --# 固定 #
  ) IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'init'; -- プロシージャ名

    /* 2009.10.21 D.Abe E_T4_00050対応 START */
    ct_item_type    CONSTANT VARCHAR2(30) := 'XXCSO020'; -- アイテムタイプ
    ct_item_name    CONSTANT VARCHAR2(30) := 'XXCSO_SP_DECISION_HEADER_ID'; -- アイテム項目名
    ct_wf_status_o  CONSTANT VARCHAR2(30) := 'OPEN';   -- 通知ステータス
    ct_wf_status_c  CONSTANT VARCHAR2(30) := 'CLOSED'; -- 通知ステータス
    /* 2009.10.21 D.Abe E_T4_00050対応 END */

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
    cv_nm_notify_type           CONSTANT VARCHAR2(30) := '通知区分';
    cv_nm_sp_decision_header_id CONSTANT VARCHAR2(30) := 'ＳＰ専決ヘッダＩＤ';
    cv_nm_send_employee_number  CONSTANT VARCHAR2(30) := '回送元従業員番号';
    cv_nm_dest_employee_number  CONSTANT VARCHAR2(30) := '回送先従業員番号';
    /* 2009.10.21 D.Abe E_T4_00050対応 START */
    cv_nm_wf_notifications      CONSTANT VARCHAR2(30) := '通知クローズ処理';
    /* 2009.10.21 D.Abe E_T4_00050対応 END */
    --
    -- *** ローカル変数 ***
    /* 2009.10.21 D.Abe E_T4_00050対応 START */
    lt_login_user_name fnd_user.user_name%TYPE;    -- ログインユーザー名
    /* 2009.10.21 D.Abe E_T4_00050対応 END */
    --
    -- *** ローカル例外 ***
    input_parameter_expt  EXCEPTION;
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    -- ======================
    -- 入力パラメータチェック
    -- ======================
    -- 通知区分が未入力の場合エラー
    IF ( iv_notify_type IS NULL ) THEN
      lv_errbuf := xxccp_common_pkg.get_msg(
                       iv_application  => cv_sales_appl_short_name     -- アプリケーション短縮名
                     , iv_name         => cv_tkn_number_02             -- メッセージコード
                     , iv_token_name1  => cv_tkn_item                  -- トークコード1
                     , iv_token_value1 => cv_nm_notify_type            -- トークン値1
                   );
      --
      RAISE input_parameter_expt;
      --
    END IF;
    --
    -- ＳＰ専決ヘッダＩＤが未入力の場合エラー
    IF ( it_sp_decision_header_id IS NULL ) THEN
      lv_errbuf := xxccp_common_pkg.get_msg(
                       iv_application  => cv_sales_appl_short_name     -- アプリケーション短縮名
                     , iv_name         => cv_tkn_number_02             -- メッセージコード
                     , iv_token_name1  => cv_tkn_item                  -- トークコード1
                     , iv_token_value1 => cv_nm_sp_decision_header_id  -- トークン値1
                   );
      --
      RAISE input_parameter_expt;
      --
    END IF;
    --
    -- 回送元従業員番号が未入力の場合エラー
    IF ( iv_send_employee_number IS NULL ) THEN
      lv_errbuf := xxccp_common_pkg.get_msg(
                       iv_application  => cv_sales_appl_short_name    -- アプリケーション短縮名
                     , iv_name         => cv_tkn_number_02            -- メッセージコード
                     , iv_token_name1  => cv_tkn_item                 -- トークコード1
                     , iv_token_value1 => cv_nm_send_employee_number  -- トークン値1
                   );
      --
      RAISE input_parameter_expt;
      --
    END IF;
    --
    -- 回送先従業員番号が未入力の場合エラー
    IF ( iv_dest_employee_number IS NULL ) THEN
      lv_errbuf := xxccp_common_pkg.get_msg(
                       iv_application  => cv_sales_appl_short_name    -- アプリケーション短縮名
                     , iv_name         => cv_tkn_number_02            -- メッセージコード
                     , iv_token_name1  => cv_tkn_item                 -- トークコード1
                     , iv_token_value1 => cv_nm_dest_employee_number  -- トークン値1
                   );
      --
      RAISE input_parameter_expt;
      --
    END IF;
    --
    -- ======================
    -- 業務処理日付取得
    -- ======================
    od_process_date := xxccp_common_pkg2.get_process_date;
    --
    IF ( od_process_date IS NULL ) THEN
      lv_errbuf := xxccp_common_pkg.get_msg(
                       iv_application  => cv_sales_appl_short_name    -- アプリケーション短縮名
                     , iv_name         => cv_tkn_number_01            -- メッセージコード
                   );
      --
      RAISE global_api_expt;
    END IF;
    /* 2009.10.21 D.Abe E_T4_00050対応 START */
    --
    -- ============================
    -- ログインユーザ名取得処理
    -- ============================
    BEGIN
      lt_login_user_name := NULL;
      SELECT USER_NAME
      INTO   lt_login_user_name
      FROM   FND_USER
      WHERE  USER_ID = fnd_global.user_id
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    -- ============================
    -- 既存ワークフロー通知クローズ処理
    -- ============================
    BEGIN
      UPDATE wf_notifications wn
      SET    status   = ct_wf_status_c,
             end_date = SYSDATE,
             responder = lt_login_user_name
      WHERE  EXISTS(SELECT 1
                    FROM   wf_item_attribute_values  wiav
                          ,wf_item_activity_statuses wias
                    WHERE  wiav.item_type     = wias.item_type
                    AND    wiav.item_key      = wias.item_key
                    AND    wiav.item_type     = ct_item_type
                    AND    wiav.name          = ct_item_name
                    AND    wiav.number_value  = it_sp_decision_header_id
                    AND    wn.notification_id = wias.notification_id)
      AND    wn.status = ct_wf_status_o
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        -- その他の例外の場合
        lv_errbuf := xxccp_common_pkg.get_msg(
                       iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                     , iv_name         => cv_tkn_number_05          -- メッセージコード
                     , iv_token_name1  => cv_tkn_func_nm            -- トークンコード1
                     , iv_token_value1 => cv_nm_wf_notifications    -- トークン値1
                     , iv_token_name2  => cv_tkn_err_msg            -- トークンコード2
                     , iv_token_value2 => SQLERRM                   -- トークン値2
                    );
        --
        RAISE global_api_expt;
        --
    END;
    /* 2009.10.21 D.Abe E_T4_00050対応 END */
    --
  EXCEPTION
    --
    WHEN input_parameter_expt THEN
      -- *** 入力パラメータチェックエラー時 ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** 共通関数例外ハンドラ ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END init;
  --
  --
  /**********************************************************************************
   * Procedure Name   : get_notify_info
   * Description      : 通知情報抽出(A-2)
   ***********************************************************************************/
  PROCEDURE get_notify_info(
      iv_notify_type           IN         VARCHAR2                                 -- 通知区分
    , id_process_date          IN         DATE                                     -- 業務処理日付
    , it_sp_decision_header_id IN         xxcso_sp_decision_headers.sp_decision_header_id%TYPE  -- ＳＰ専決ヘッダＩＤ
    , iv_send_employee_number  IN         VARCHAR2                                 -- 回送元従業員番号
    , iv_dest_employee_number  IN         VARCHAR2                                 -- 回送先従業員番号
    , ot_notify_subject        OUT NOCOPY fnd_lookup_values_vl.attribute1%TYPE     -- 件名
    , ot_notify_body           OUT NOCOPY fnd_lookup_values_vl.attribute2%TYPE     -- 本文
    , ot_party_name            OUT NOCOPY hz_parties.party_name%TYPE               -- 顧客名
    , ot_send_user_name        OUT NOCOPY VARCHAR2                                 -- 回送元ユーザー名
    , ot_dest_user_name        OUT NOCOPY VARCHAR2                                 -- 回送先ユーザー名
    , ov_errbuf                OUT NOCOPY VARCHAR2                                 -- エラー・メッセージ  --# 固定 #
    , ov_retcode               OUT NOCOPY VARCHAR2                                 -- リターン・コード    --# 固定 #
  ) IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'get_notify_info';  -- プロシージャ名
    --
    --#######################  固定ローカル変数宣言部 START   ######################
    --
    lv_errbuf     VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);     -- リターン・コード
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    ct_lookup_type_sp_wf_notify    CONSTANT fnd_lookup_values_vl.lookup_type%TYPE := 'XXCSO1_SP_WF_NOTICE_TEXT';
                                                                                        -- ＳＰワークフロー通知
    ct_sp_dec_cust_class_install   CONSTANT xxcso_sp_decision_custs.sp_decision_customer_class%TYPE := '1';
                                                                                        -- ＳＰ専決顧客区分=設置先
    --
    -- トークン用定数
    cv_tkn_val_notify_type        CONSTANT VARCHAR2(100) := '通知区分：';
    cv_tkn_val_lookup_vals_vl     CONSTANT VARCHAR2(100) := 'クイックコードビュー';
    cv_tkn_val_sp_dec_head_id     CONSTANT VARCHAR2(100) := 'ＳＰ専決ヘッダＩＤ：';
    cv_tkn_val_sp_cst_and_cst_mst CONSTANT VARCHAR2(100) := 'ＳＰ専決顧客テーブル／顧客マスタ';
    cv_tkn_val_send_emp_number    CONSTANT VARCHAR2(100) := '回送元従業員番号：';
    cv_tkn_val_dest_emp_number    CONSTANT VARCHAR2(100) := '回送先従業員番号：';
    cv_tkn_val_employee_v         CONSTANT VARCHAR2(100) := '従業員マスタ（最新）ビュー';
    --
    -- *** ローカル変数 ***
    lt_notify_subject fnd_lookup_values_vl.attribute1%TYPE; -- 件名
    lt_notify_body    fnd_lookup_values_vl.attribute2%TYPE; -- 本文
    lt_party_name     hz_parties.party_name%TYPE;           -- 顧客名
    lt_send_user_name xxcso_employees_v2.user_name%TYPE;    -- 回送元ユーザー名
    lt_dest_user_name xxcso_employees_v2.user_name%TYPE;    -- 回送先ユーザー名
    --
    -- *** ローカル例外 ***
    sql_expt  EXCEPTION;
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    -- ==============
    -- 変数初期化処理
    -- ==============
    lt_notify_subject := NULL;
    lt_notify_body    := NULL;
    lt_party_name     := NULL;
    --
    -- ============================
    -- 件名、本文取得処理
    -- ============================
    BEGIN
      SELECT flvv.attribute1  notify_subject    -- 件名
           , flvv.attribute2  notify_body       -- 本文
      INTO   lt_notify_subject
           , lt_notify_body
      FROM   fnd_lookup_values_vl  flvv    -- クイックコードビュー
      WHERE  flvv.lookup_type  = ct_lookup_type_sp_wf_notify
      AND    flvv.lookup_code  = iv_notify_type
      AND    flvv.enabled_flag = 'Y'
      AND    TRUNC( NVL( flvv.start_date_active, id_process_date ) ) <= TRUNC( id_process_date )
      AND    TRUNC( NVL( flvv.end_date_active, id_process_date ) )   >= TRUNC( id_process_date )
      ;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- データが存在しない場合
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name   -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_03           -- メッセージコード
                       , iv_token_name1  => cv_tkn_item                -- トークンコード1
                       , iv_token_value1 => cv_tkn_val_notify_type ||
                                            cv_msg_part            ||
                                            iv_notify_type             -- トークン値1
                       , iv_token_name2  => cv_tkn_table               -- トークンコード2
                       , iv_token_value2 => cv_tkn_val_lookup_vals_vl  -- トークン値2
                    );
        --
        RAISE sql_expt;
        --
      WHEN OTHERS THEN
        -- その他の例外の場合
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name   -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_04           -- メッセージコード
                       , iv_token_name1  => cv_tkn_table               -- トークンコード1
                       , iv_token_value1 => cv_tkn_val_lookup_vals_vl  -- トークン値1
                       , iv_token_name2  => cv_tkn_key                 -- トークンコード2
                       , iv_token_value2 => iv_notify_type             -- トークン値2
                       , iv_token_name3  => cv_tkn_err_msg             -- トークンコード3
                       , iv_token_value3 => SQLERRM                    -- トークン値3
                    );
        --
        RAISE sql_expt;
        --
    END;
    --
    -- ==========================
    -- ＳＰ専決顧客取得処理
    -- ==========================
    BEGIN
      SELECT DECODE(  xsdc.new_customer_flag
                    , 'Y'
                    , xsdc.party_name
                    , xcav.party_name )  party_name    -- 顧客名
      INTO   lt_party_name
      FROM   xxcso_sp_decision_custs  xsdc    -- ＳＰ専決顧客テーブル
           , xxcso_cust_accounts_v    xcav    -- 顧客マスタビュー
      WHERE  xsdc.sp_decision_header_id      = it_sp_decision_header_id
      AND    xsdc.sp_decision_customer_class = ct_sp_dec_cust_class_install
      AND    xsdc.customer_id                = xcav.cust_account_id(+)
      ;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- データが存在しない場合
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name       -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_03               -- メッセージコード
                       , iv_token_name1  => cv_tkn_item                    -- トークンコード1
                       , iv_token_value1 => cv_tkn_val_sp_dec_head_id ||
                                            cv_msg_part               ||
                                            it_sp_decision_header_id       -- トークン値1
                       , iv_token_name2  => cv_tkn_table                   -- トークンコード2
                       , iv_token_value2 => cv_tkn_val_sp_cst_and_cst_mst  -- トークン値2
                    );
        --
        RAISE sql_expt;
        --
      WHEN OTHERS THEN
        -- その他の例外の場合
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name       -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_04               -- メッセージコード
                       , iv_token_name1  => cv_tkn_table                   -- トークンコード1
                       , iv_token_value1 => cv_tkn_val_sp_cst_and_cst_mst  -- トークン値1
                       , iv_token_name2  => cv_tkn_key                     -- トークンコード2
                       , iv_token_value2 => it_sp_decision_header_id       -- トークン値2
                       , iv_token_name3  => cv_tkn_err_msg                 -- トークンコード3
                       , iv_token_value3 => SQLERRM                        -- トークン値3
                    );
        --
        RAISE sql_expt;
        --
    END;
    --
    -- ==========================
    -- 回送元ユーザー名取得処理
    -- ==========================
    BEGIN
      SELECT xev.user_name user_name -- ユーザー名
      INTO   lt_send_user_name
      FROM   xxcso_employees_v2 xev -- 従業員マスタ（最新）ビュー
      WHERE  xev.employee_number = iv_send_employee_number
      ;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- データが存在しない場合
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_03         -- メッセージコード
                       , iv_token_name1  => cv_tkn_item              -- トークンコード1
                       , iv_token_value1 => cv_tkn_val_send_emp_number ||
                                            iv_send_employee_number  -- トークン値1
                       , iv_token_name2  => cv_tkn_table             -- トークンコード2
                       , iv_token_value2 => cv_tkn_val_employee_v    -- トークン値2
                    );
        --
        RAISE sql_expt;
        --
      WHEN OTHERS THEN
        -- その他の例外の場合
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_04         -- メッセージコード
                       , iv_token_name1  => cv_tkn_table             -- トークンコード1
                       , iv_token_value1 => cv_tkn_val_employee_v    -- トークン値1
                       , iv_token_name2  => cv_tkn_key               -- トークンコード2
                       , iv_token_value2 => iv_send_employee_number  -- トークン値2
                       , iv_token_name3  => cv_tkn_err_msg           -- トークンコード3
                       , iv_token_value3 => SQLERRM                  -- トークン値3
                    );
        --
        RAISE sql_expt;
        --
    END;
    --
    -- ==========================
    -- 回送先ユーザー名取得処理
    -- ==========================
    BEGIN
      SELECT xev.user_name user_name -- ユーザー名
      INTO   lt_dest_user_name
      FROM   xxcso_employees_v2 xev -- 従業員マスタ（最新）ビュー
      WHERE  xev.employee_number = iv_dest_employee_number
      ;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- データが存在しない場合
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_03         -- メッセージコード
                       , iv_token_name1  => cv_tkn_item              -- トークンコード1
                       , iv_token_value1 => cv_tkn_val_dest_emp_number ||
                                            iv_dest_employee_number  -- トークン値1
                       , iv_token_name2  => cv_tkn_table             -- トークンコード2
                       , iv_token_value2 => cv_tkn_val_employee_v    -- トークン値2
                    );
        --
        RAISE sql_expt;
        --
      WHEN OTHERS THEN
        -- その他の例外の場合
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_04         -- メッセージコード
                       , iv_token_name1  => cv_tkn_table             -- トークンコード1
                       , iv_token_value1 => cv_tkn_val_employee_v    -- トークン値1
                       , iv_token_name2  => cv_tkn_key               -- トークンコード2
                       , iv_token_value2 => iv_dest_employee_number  -- トークン値2
                       , iv_token_name3  => cv_tkn_err_msg           -- トークンコード3
                       , iv_token_value3 => SQLERRM                  -- トークン値3
                    );
        --
        RAISE sql_expt;
        --
    END;
    --
    ot_notify_subject := lt_notify_subject;
    ot_notify_body    := lt_notify_body;
    ot_party_name     := lt_party_name;
    ot_send_user_name := lt_send_user_name;
    ot_dest_user_name := lt_dest_user_name;
    --
  EXCEPTION
    --
    WHEN sql_expt THEN
      -- *** データ取得SQL例外ハンドラ ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END get_notify_info;
  --
  --
  /**********************************************************************************
   * Procedure Name   : start_sp_dec_wf_proc
   * Description      : ＳＰ専決ワークフロー起動(A-7)
   ***********************************************************************************/
  PROCEDURE start_sp_dec_wf_proc(
      it_sp_decision_header_id IN         xxcso_sp_decision_headers.sp_decision_header_id%TYPE  -- ＳＰ専決ヘッダＩＤ
    , iv_dest_user_name        IN         VARCHAR2    -- 回送先ユーザー名
    , iv_send_user_name        IN         VARCHAR2    -- 回送元ユーザー名
    , it_notify_subject        IN         VARCHAR2    -- 件名
    , it_notify_body           IN         VARCHAR2    -- 本文
    , in_seq_num               IN         NUMBER      -- 連番
    , ov_errbuf                OUT NOCOPY VARCHAR2    -- エラー・メッセージ  --# 固定 #
    , ov_retcode               OUT NOCOPY VARCHAR2    -- リターン・コード    --# 固定 #
  ) IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'start_sp_dec_wf_proc';  -- プロシージャ名
    --
    --#######################  固定ローカル変数宣言部 START   ######################
    --
    lv_errbuf  VARCHAR2(5000); -- エラー・メッセージ
    lv_retcode VARCHAR2(1);    -- リターン・コード
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_wf_itemtype              CONSTANT VARCHAR2(30) := 'XXCSO020';
    cv_wf_process               CONSTANT VARCHAR2(30) := 'XXCSO020002P01';
    cv_wf_pkg_name              CONSTANT VARCHAR2(30) := 'wf_engine';
    cv_wf_createprocess         CONSTANT VARCHAR2(30) := 'createprocess';
    cv_wf_setitemattrnumber     CONSTANT VARCHAR2(30) := 'setitemattrnumber';
    cv_wf_setitemattrtext       CONSTANT VARCHAR2(30) := 'setitemattrtext';
    cv_wf_startprocess          CONSTANT VARCHAR2(30) := 'startprocess';
    --
    -- ワークフロー属性名
    cv_wf_aname_sp_dec_head_id  CONSTANT VARCHAR2(30) := 'XXCSO_SP_DECISION_HEADER_ID';
    cv_wf_aname_dest_user_nm    CONSTANT VARCHAR2(30) := 'XXCSO_DESTINATION_USER_NAME';
    cv_wf_aname_send_user_nm    CONSTANT VARCHAR2(30) := 'XXCSO_SENDER_USER_NAME';
    cv_wf_aname_notify_subject  CONSTANT VARCHAR2(30) := 'XXCSO_NOTIFY_SUBJECT';
    cv_wf_aname_notify_body     CONSTANT VARCHAR2(30) := 'XXCSO_NOTIFY_BODY';
    --
    -- トークン用定数
    --
    -- *** ローカル変数 ***
    -- ワークフローAPI例外
    lv_itemkey                  VARCHAR2(100);
    lv_token_value              VARCHAR2(60);
    --
    -- *** ローカル例外 ***
    wf_api_others_expt          EXCEPTION;
    --
    PRAGMA EXCEPTION_INIT( wf_api_others_expt, -20002 );
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    lv_itemkey := cv_sales_appl_short_name
                    || TO_CHAR( SYSDATE, 'YYYYMMDDHH24MISS' )
                    /* 2009.06.29 K.Satomura 統合テスト障害対応(0000209) START */
                    --|| LPAD( TO_CHAR( in_seq_num ), 2, '0' );
                    || LPAD( TO_CHAR( in_seq_num ), 2, '0' )
                    || TO_CHAR(it_sp_decision_header_id)
                    ;
                    /* 2009.06.29 K.Satomura 統合テスト障害対応(0000209) END */
    --
    -- ==========================
    -- ワークフロープロセス生成
    -- ==========================
    lv_token_value := cv_wf_pkg_name || cv_wf_createprocess;
    --
    WF_ENGINE.CREATEPROCESS(
        itemtype => cv_wf_itemtype
      , itemkey  => lv_itemkey
      , process  => cv_wf_process
    );
    --
    -- ==========================
    -- ワークフロー属性設定
    -- ==========================
    lv_token_value := cv_wf_pkg_name || cv_wf_setitemattrnumber;
    --
    -- ＳＰ専決ヘッダＩＤ
    WF_ENGINE.SETITEMATTRNUMBER(
        itemtype => cv_wf_itemtype
      , itemkey  => lv_itemkey
      , aname    => cv_wf_aname_sp_dec_head_id
      , avalue   => it_sp_decision_header_id
    );
    --
    lv_token_value := cv_wf_pkg_name || cv_wf_setitemattrtext;
    --
    -- 通知回送先
    WF_ENGINE.SETITEMATTRTEXT(
        itemtype => cv_wf_itemtype
      , itemkey  => lv_itemkey
      , aname    => cv_wf_aname_dest_user_nm
      , avalue   => iv_dest_user_name
    );
    --
    -- 通知回送元
    WF_ENGINE.SETITEMATTRTEXT(
        itemtype => cv_wf_itemtype
      , itemkey  => lv_itemkey
      , aname    => cv_wf_aname_send_user_nm
      , avalue   => iv_send_user_name
    );
    --
    -- 通知件名
    WF_ENGINE.SETITEMATTRTEXT(
        itemtype => cv_wf_itemtype
      , itemkey  => lv_itemkey
      , aname    => cv_wf_aname_notify_subject
      , avalue   => it_notify_subject
    );
    --
    -- 通知本文
    WF_ENGINE.SETITEMATTRTEXT(
        itemtype => cv_wf_itemtype
      , itemkey  => lv_itemkey
      , aname    => cv_wf_aname_notify_body
      , avalue   => it_notify_body
    );
    --
    -- ==========================
    -- ワークフロープロセス起動
    -- ==========================
    lv_token_value := cv_wf_pkg_name || cv_wf_startprocess;
    --
    WF_ENGINE.STARTPROCESS(
        itemtype => cv_wf_itemtype
      , itemkey  => lv_itemkey
    );
    --
  EXCEPTION
    --
    WHEN wf_api_others_expt THEN
      -- *** ワークフローAPI例外ハンドラ ***
      lv_errbuf := xxccp_common_pkg.get_msg(
                       iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                     , iv_name         => cv_tkn_number_05          -- メッセージコード
                     , iv_token_name1  => cv_tkn_func_nm            -- トークンコード1
                     , iv_token_value1 => lv_token_value            -- トークン値1
                     , iv_token_name2  => cv_tkn_err_msg            -- トークンコード2
                     , iv_token_value2 => SQLERRM                   -- トークン値2
                  );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
     -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END start_sp_dec_wf_proc;
  --
  --
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   ***********************************************************************************/
  PROCEDURE submain(
      iv_notify_type           IN         VARCHAR2    -- 通知区分
    , it_sp_decision_header_id IN         xxcso_sp_decision_headers.sp_decision_header_id%TYPE  -- ＳＰ専決ヘッダＩＤ
    , iv_send_employee_number  IN         VARCHAR2    -- 回送元従業員番号
    , iv_dest_employee_number  IN         VARCHAR2    -- 回送先従業員番号
    , ov_errbuf                OUT NOCOPY VARCHAR2    -- エラー・メッセージ  --# 固定 #
    , ov_retcode               OUT NOCOPY VARCHAR2    -- リターン・コード    --# 固定 #
  ) IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'submain'; -- プロシージャ名
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
    ct_approval_state_type_in_prc  CONSTANT xxcso_sp_decision_sends.approval_state_type%TYPE := '1';
                                                                                        -- 決裁状態区分=処理中
    ct_approval_state_type_prcssd  CONSTANT xxcso_sp_decision_sends.approval_state_type%TYPE := '2';
                                                                                        -- 決裁状態区分=処理済
    cv_notify_type_aprv_req        CONSTANT VARCHAR2(1) := '1';    -- 承認依頼通知
    cv_notify_type_cnfrm_req       CONSTANT VARCHAR2(1) := '2';    -- 確認依頼通知
    cv_notify_type_rjct            CONSTANT VARCHAR2(1) := '3';    -- 否決通知
    cv_notify_type_rtrn            CONSTANT VARCHAR2(1) := '4';    -- 返却通知
    cv_notify_type_aprv_cmplt      CONSTANT VARCHAR2(1) := '5';    -- 承認完了通知
    cv_seq_num                     CONSTANT NUMBER(1)   := 1;      -- 連番
    --
    -- *** ローカル変数 ***
    ld_process_date   DATE;                                 -- 業務処理日付
    lt_notify_subject fnd_lookup_values_vl.attribute1%TYPE; -- 件名
    lt_notify_body    fnd_lookup_values_vl.attribute2%TYPE; -- 本文
    lt_party_name     hz_parties.party_name%TYPE;           -- 顧客名
    lt_send_user_name xxcso_employees_v2.user_name%TYPE;    -- 回送元ユーザー名
    lt_dest_user_name xxcso_employees_v2.user_name%TYPE;    -- 回送先ユーザー名
    ln_seq_num        NUMBER;                               -- 連番
    --
    -- *** ローカル・カーソル ***
    CURSOR xsds_data_cur
    IS
      SELECT   xev.user_name dest_user_name -- 回送先ユーザー名
      FROM     xxcso_sp_decision_sends xsds -- ＳＰ専決回送先テーブル
              ,xxcso_employees_v2      xev  -- 従業員マスタ（最新）ビュー
      WHERE    xsds.sp_decision_header_id = it_sp_decision_header_id
      AND      xsds.approval_state_type   IN ( ct_approval_state_type_in_prc, ct_approval_state_type_prcssd )
      AND      xsds.approve_code          <> '*'
      AND      xsds.approve_code          = xev.employee_number
      ORDER BY xsds.approval_authority_number DESC
      ;
    --
    -- *** ローカル・レコード ***
    l_xsds_data_rec xsds_data_cur%ROWTYPE;
    --
    -- *** ローカル例外 ***
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    ln_seq_num    := 0;
    --
    -- ========================================
    -- A-1.初期処理
    -- ========================================
    init(
        iv_notify_type           => iv_notify_type            -- 通知区分
      , it_sp_decision_header_id => it_sp_decision_header_id  -- ＳＰ専決ヘッダＩＤ
      , iv_send_employee_number  => iv_send_employee_number   -- 回送元従業員番号
      , iv_dest_employee_number  => iv_dest_employee_number   -- 回送先従業員番号
      , od_process_date          => ld_process_date           -- 業務処理日付
      , ov_errbuf                => lv_errbuf                 -- エラー・メッセージ --# 固定 #
      , ov_retcode               => lv_retcode                -- リターン・コード   --# 固定 #
    );
    --
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- ========================================
    -- A-2. 通知情報抽出
    -- ========================================
    get_notify_info(
        iv_notify_type           => iv_notify_type            -- 通知区分
      , id_process_date          => ld_process_date           -- 業務処理日付
      , it_sp_decision_header_id => it_sp_decision_header_id  -- ＳＰ専決ヘッダＩＤ
      , iv_send_employee_number  => iv_send_employee_number   -- 回送元従業員番号
      , iv_dest_employee_number  => iv_dest_employee_number   -- 回送先従業員番号
      , ot_notify_subject        => lt_notify_subject         -- 件名
      , ot_notify_body           => lt_notify_body            -- 本文
      , ot_party_name            => lt_party_name             -- 顧客名
      , ot_send_user_name        => lt_send_user_name         -- 回送元ユーザー名
      , ot_dest_user_name        => lt_dest_user_name         -- 回送先ユーザー名
      , ov_errbuf                => lv_errbuf                 -- エラー・メッセージ  --# 固定 #
      , ov_retcode               => lv_retcode                -- リターン・コード    --# 固定 #
    );
    --
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    ------------------------------------------------------------
    -- 通知区分が「承認依頼」「確認依頼」「承認完了」の場合
    ------------------------------------------------------------
    IF ( iv_notify_type in ( cv_notify_type_aprv_req, cv_notify_type_cnfrm_req, cv_notify_type_aprv_cmplt ) ) THEN
      -- ========================================
      -- A-3.承認／確認通知送付
      -- (A-7.ＳＰ専決通知ワークフロー起動を実行)
      -- ========================================
      start_sp_dec_wf_proc(
          it_sp_decision_header_id => it_sp_decision_header_id            -- ＳＰ専決ヘッダＩＤ
        , iv_dest_user_name        => lt_dest_user_name                   -- 通知回送先
        , iv_send_user_name        => lt_send_user_name                   -- 通知回送元
        , it_notify_subject        => lt_notify_subject || lt_party_name  -- 通知件名（A-2で取得した件名＋顧客名）
        , it_notify_body           => lt_notify_body                      -- 通知本文（A-2で取得した本文）
        , in_seq_num               => cv_seq_num                          -- 連番
        , ov_errbuf                => lv_errbuf                           -- エラー・メッセージ  --# 固定 #
        , ov_retcode               => lv_retcode                          -- リターン・コード    --# 固定 #
      );
      --
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
        --
      END IF;
      --
    ------------------------------------------------------------
    -- 通知区分が「否決通知」「返却通知」の場合
    ------------------------------------------------------------
    ELSE
      -- ========================================
      -- A-4. 否決／返却通知先情報抽出
      -- ========================================
      -- カーソルオープン
      OPEN xsds_data_cur;
--
      <<get_data_loop>>
      LOOP
        FETCH xsds_data_cur INTO l_xsds_data_rec;
        -- 処理対象件数格納
        gn_target_cnt := xsds_data_cur%ROWCOUNT;
--
        EXIT WHEN xsds_data_cur%NOTFOUND
        OR  xsds_data_cur%ROWCOUNT = 0;
        --
        -- 連番をカウントアップ
        ln_seq_num := ln_seq_num + 1;
        --
        -- ========================================
        -- A-5.否決／返却通知送付
        -- (A-7.ＳＰ専決通知ワークフロー起動を実行)
        -- ========================================
        start_sp_dec_wf_proc(
            it_sp_decision_header_id => it_sp_decision_header_id           -- ＳＰ専決ヘッダＩＤ
          , iv_dest_user_name        => l_xsds_data_rec.dest_user_name     -- 通知回送先
          , iv_send_user_name        => lt_send_user_name                  -- 通知回送元
          , it_notify_subject        => lt_notify_subject || lt_party_name -- 通知件名（A-2で取得した件名＋顧客名）
          , it_notify_body           => lt_notify_body                     -- 通知本文（A-2で取得した本文）
          , in_seq_num               => ln_seq_num                         -- 連番
          , ov_errbuf                => lv_errbuf                          -- エラー・メッセージ  --# 固定 #
          , ov_retcode               => lv_retcode                         -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
--
      END LOOP get_data_loop;
--
      -- カーソルクローズ
      CLOSE xsds_data_cur;
      --
      -- 連番をカウントアップ
      ln_seq_num := ln_seq_num + 1;
      --
      -- ========================================
      -- A-6.申請者向け否決／返却通知送付
      -- (A-7.ＳＰ専決通知ワークフロー起動を実行)
      -- ========================================
      start_sp_dec_wf_proc(
          it_sp_decision_header_id => it_sp_decision_header_id           -- ＳＰ専決ヘッダＩＤ
        , iv_dest_user_name        => lt_dest_user_name                  -- 通知回送先
        , iv_send_user_name        => lt_send_user_name                  -- 通知回送元
        , it_notify_subject        => lt_notify_subject || lt_party_name -- 通知件名（A-2で取得した件名＋顧客名）
        , it_notify_body           => lt_notify_body                     -- 通知本文（A-2で取得した本文）
        , in_seq_num               => ln_seq_num                         -- 連番
        , ov_errbuf                => lv_errbuf                          -- エラー・メッセージ  --# 固定 #
        , ov_retcode               => lv_retcode                         -- リターン・コード    --# 固定 #
      );
      --
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
        --
      END IF;
      --
    END IF;
    --
  EXCEPTION
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_process_expt THEN
      -- *** 処理部共通例外ハンドラ ***
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
      --
      -- カーソルがクローズされていない場合
      IF (xsds_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE xsds_data_cur;
      END IF;
      --
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
      --
      -- カーソルがクローズされていない場合
      IF (xsds_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE xsds_data_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM || lv_errbuf;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
      --
      -- カーソルがクローズされていない場合
      IF (xsds_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE xsds_data_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    --
    --#####################################  固定部 END   ##########################################
    --
  END submain;
  --
  --
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : 実行ファイル登録プロシージャ
   **********************************************************************************/
  --
  PROCEDURE main(
      iv_notify_type           IN         VARCHAR2    -- 通知区分
    , it_sp_decision_header_id IN         xxcso_sp_decision_headers.sp_decision_header_id%TYPE  -- ＳＰ専決ヘッダＩＤ
    , iv_send_employee_number  IN         VARCHAR2    -- 回送元従業員番号
    , iv_dest_employee_number  IN         VARCHAR2    -- 回送先従業員番号
    , errbuf                   OUT NOCOPY VARCHAR2    -- エラー・メッセージ  --# 固定 #
    , retcode                  OUT NOCOPY VARCHAR2    -- リターン・コード    --# 固定 #
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
    --
/*
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
*/
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
--    lv_errmsg          VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--    lv_message_code    VARCHAR2(100);   -- 終了メッセージコード
    --
  BEGIN
    --
/*
    --###########################  固定部 START   #####################################################
    --
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
    --###########################  固定部 END   #############################
*/
    --
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
        iv_notify_type           => iv_notify_type            -- 通知区分
      , it_sp_decision_header_id => it_sp_decision_header_id  -- ＳＰ専決ヘッダＩＤ
      , iv_send_employee_number  => iv_send_employee_number   -- 回送元従業員番号
      , iv_dest_employee_number  => iv_dest_employee_number   -- 回送先従業員番号
      , ov_errbuf                => lv_errbuf                 -- エラー・メッセージ  --# 固定 #
      , ov_retcode               => lv_retcode                -- リターン・コード    --# 固定 #
    );
    --
    errbuf  := lv_errbuf;
/*
    IF ( lv_retcode = cv_status_error ) THEN
       --エラー出力
       fnd_file.put_line(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg                  --ユーザー・エラーメッセージ
       );
       fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => cv_pkg_name||cv_msg_cont||
                    cv_prg_name||cv_msg_part||
                    lv_errbuf                  --エラーメッセージ
       );
    END IF;
    --
    -- =======================
    -- A-x.終了処理 
    -- =======================
    --空行の出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
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
       which  => FND_FILE.OUTPUT
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
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --終了メッセージ
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
*/
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
/*
      -- *** DEBUG_LOG ***
      -- ロールバックしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg11 || CHR(10) ||
                   ''
      );
*/
    END IF;
--
  EXCEPTION
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM || lv_errbuf;
      retcode := cv_status_error;
      ROLLBACK;
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCSO020A02C;
/
