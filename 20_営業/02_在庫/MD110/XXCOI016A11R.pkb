CREATE OR REPLACE PACKAGE BODY XXCOI016A11R
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOI016A11R(body)
 * Description      : ロット別受払残高表（倉庫）
 * MD.050           : MD050_COI_016_A11_ロット別受払残高表（倉庫）.doc
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  proc_end               終了処理(A-6)
 *  execute_svf            SVF起動(A-5)
 *  ins_work_data          ワークテーブルデータ登録(A-4)
 *  get_monthly_data       ロット別受払（月次）データ取得(A-3)
 *  get_daily_data         ロット別受払（日次）データ取得(A-2)
 *  proc_init              初期処理(A-1)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014/11/06    1.0   Y.Nagasue        新規作成
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
  old_date_expt                EXCEPTION; -- 過去日エラー
  in_para_expt                 EXCEPTION; -- 入力パラメータエラー
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                  CONSTANT VARCHAR2(100) := 'XXCOI016A11R'; -- パッケージ名
  cv_xxcoi_short_name          CONSTANT VARCHAR2(5)   := 'XXCOI'; -- アプリケーション短縮名
--
  -- メッセージ
  cv_msg_xxcoi1_00005          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00005';
                                                  -- 在庫組織コード取得エラーメッセージ
  cv_msg_xxcoi1_00006          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00006'; 
                                                  -- 在庫組織ID取得エラーメッセージ
  cv_msg_xxcoi1_00011          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00011'; 
                                                  -- 業務日付取得エラーメッセージ
  cv_msg_xxcoi1_10460          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10460';
                                                  -- 対象日NULL値エラー
  cv_msg_xxcoi1_10461          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10461';
                                                  -- 対象日入力エラー
  cv_msg_xxcoi1_10462          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10462';
                                                  -- 対象日日付型エラー
  cv_msg_xxcoi1_10463          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10463';
                                                  -- 対象日未来日エラー
  cv_msg_xxcoi1_10464          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10464';
                                                  -- 対象月NULL値エラー
  cv_msg_xxcoi1_10465          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10465';
                                                  -- 対象月入力エラー
  cv_msg_xxcoi1_10466          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10466';
                                                  -- 対象月日付型エラー
  cv_msg_xxcoi1_10467          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10467';
                                                  -- 対象月未来日エラー
  cv_msg_xxcoi1_10116          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10116';
                                                  -- ログインユーザ拠点コード抽出エラーメッセージ
  cv_msg_xxcoi1_10468          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10468';
                                                  -- 拠点コードNULLチェックエラー
  cv_msg_xxcoi1_10459          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10459';
                                                  -- ロット別受払残高表（倉庫）コンカレント入力パラメータ
  cv_msg_xxcoi1_10469          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10469';
                                                  -- 本社商品区分取得エラー
  cv_msg_xxcoi1_00026          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00026';
                                                  -- 在庫会計期間ステータス取得エラーメッセージ
  cv_msg_xxcoi1_10451          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10451';
                                                  -- 在庫確定印字文字取得エラーメッセージ
  cv_msg_xxcoi1_00008          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00008';
                                                  -- 対象データ無しメッセージ
  cv_msg_xxcoi1_10119          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10119';
                                                  -- SVF起動エラーメッセージ
--
  -- トークン
  cv_tkn_pro_tok               CONSTANT VARCHAR2(20) := 'PRO_TOK';        -- プロファイル名
  cv_tkn_org_code_tok          CONSTANT VARCHAR2(20) := 'ORG_CODE_TOK';   -- 在庫組織コード
  cv_tkn_exe_type              CONSTANT VARCHAR2(20) := 'EXE_TYPE';       -- 実行区分
  cv_tkn_exe_type_name         CONSTANT VARCHAR2(20) := 'EXE_TYPE_NAME';  -- 実行区分名称
  cv_tkn_target_date           CONSTANT VARCHAR2(20) := 'TARGET_DATE';    -- 対象日
  cv_tkn_target_month          CONSTANT VARCHAR2(20) := 'TARGET_MONTH';   -- 対象月
  cv_tkn_base_code             CONSTANT VARCHAR2(20) := 'BASE_CODE';      -- 拠点コード
  cv_tkn_base_name             CONSTANT VARCHAR2(20) := 'BASE_NAME';      -- 拠点名
  cv_tkn_subinv_code           CONSTANT VARCHAR2(20) := 'SUBINV_CODE';    -- 保管場所コード
  cv_tkn_subinv_name           CONSTANT VARCHAR2(20) := 'SUBINV_NAME';    -- 保管場所名
  cv_tkn_business_date         CONSTANT VARCHAR2(20) := 'BUSINESS_DATE';  -- 業務日付
--
  -- プロファイル名
  cv_xxcoi1_organization_code  CONSTANT VARCHAR2(50) := 'XXCOI1_ORGANIZATION_CODE'; -- XXCOI:在庫組織コード
  cv_xxcoi1_inv_cl_character   CONSTANT VARCHAR2(50) := 'XXCOI1_INV_CL_CHARACTER';  -- XXCOI:在庫確定印字文字
  cv_xxcos1_item_div_h         CONSTANT VARCHAR2(50) := 'XXCOS1_ITEM_DIV_H';        -- XXCOS:本社商品区分
--
  -- 参照タイプ名
  ct_lot_rep_output_type       CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCOI1_LOT_REP_OUTPUT_TYPE';
                                                                          -- ロット別受払表実行区分
--
  -- SVF用
  cv_pdf                       CONSTANT VARCHAR2(4)  := '.pdf';             -- 拡張子：PDF
  cv_output_mode_1             CONSTANT VARCHAR2(1)  := '1';                -- 出力区分：PDF
  cv_frm_file                  CONSTANT VARCHAR2(20) := 'XXCOI016A11S.xml'; -- フォーム様式ファイル名
  cv_vrq_file                  CONSTANT VARCHAR2(20) := 'XXCOI016A11S.vrq'; -- クエリー様式ファイル名
--
  -- ステータス等
  -- 入力パラメータ.実行区分
  cv_exe_type_10               CONSTANT VARCHAR2(2) := '10'; -- 日次
  cv_exe_type_20               CONSTANT VARCHAR2(2) := '20'; -- 月次
  -- フラグ
  cv_flag_y                    CONSTANT VARCHAR2(1)  := 'Y'; -- フラグ：Y
  cv_flag_n                    CONSTANT VARCHAR2(1)  := 'N'; -- フラグ：N
  -- 顧客マスタ
  ct_cust_status_a             CONSTANT hz_cust_accounts.status%TYPE               := 'A'; -- ステータス：A
  ct_cust_class_code_1         CONSTANT hz_cust_accounts.customer_class_code%TYPE  := '1'; -- 顧客区分：1
  -- 保管場所マスタ
  ct_warehouse_flag_y          CONSTANT mtl_secondary_inventories.attribute14%TYPE := 'Y'; -- 倉庫管理対象区分：'Y'
  -- 管理元拠点判定
  cv_management_chk_1          CONSTANT VARCHAR2(1)  := '1'; -- 管理元拠点
  cv_management_chk_0          CONSTANT VARCHAR2(1)  := '0'; -- 非管理元拠点
  -- 言語
  ct_lang                      CONSTANT mtl_category_sets_tl.language%TYPE := USERENV('LANG'); -- 言語
--
  -- 日付形式
  cv_yyyymmddhh24miss          CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS'; -- 日付形式：YYYY/MM/DD HH24:MI:SS
  cv_yyyymmdd                  CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';            -- 日付形式：YYYY/MM/DD
  cv_yyyymmdd2                 CONSTANT VARCHAR2(8)  := 'YYYYMMDD';              -- 日付形式：YYYYMMDD
  cv_yyyymm                    CONSTANT VARCHAR2(6)  := 'YYYYMM';                -- 日付形式：YYYYMM
  cv_yy                        CONSTANT VARCHAR2(2)  := 'YY';                    -- 日付形式：YYYY
  cv_mm                        CONSTANT VARCHAR2(2)  := 'MM';                    -- 日付形式：MM
  cv_dd                        CONSTANT VARCHAR2(2)  := 'DD';                    -- 日付形式：DD
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 処理対象拠点情報格納用
  TYPE g_base_code_rtype IS RECORD(
    base_code hz_cust_accounts.account_number%TYPE -- 拠点コード
  );
  TYPE g_base_code_ttype IS TABLE OF g_base_code_rtype INDEX BY BINARY_INTEGER;
  g_base_code_tab g_base_code_ttype;
--
  -- 帳票ワークテーブル用
  TYPE g_lot_rec_work_ttype IS TABLE OF xxcoi_rep_lot_rec_ship_work%ROWTYPE INDEX BY BINARY_INTEGER;
  g_lot_rec_work_tab g_lot_rec_work_ttype;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 入力パラメータ格納用変数
  gt_exe_type                  fnd_lookup_values.lookup_code%TYPE;                      -- 実行区分
  gv_target_date               VARCHAR2(30);                                            -- 対象日
  gv_target_month              VARCHAR2(6);                                             -- 対象月
  gt_login_base_code           hz_cust_accounts.account_number%TYPE;                    -- 拠点
  gt_subinventory_code         mtl_secondary_inventories.secondary_inventory_name%TYPE; -- 保管場所
--
  -- 初期処理取得値
  gt_org_code                  mtl_parameters.organization_code%TYPE;               -- 在庫組織コード
  gt_org_id                    mtl_parameters.organization_id%TYPE;                 -- 在庫組織ID
  gd_proc_date                 DATE;                                                -- 業務日付
  gv_proc_date_char            VARCHAR2(11);                                        -- 業務日付文字列
  gt_exe_type_meaning          fnd_lookup_values.meaning%TYPE;                      -- 入力パラメータ.実行区分名称
  gd_target_date               DATE;                                                -- 入力パラメータDATE型
  gt_base_code                 hz_cust_accounts.account_number%TYPE;                -- ログインユーザ所属拠点コード
  gt_base_name                 hz_parties.party_name%TYPE;                          -- 入力パラメータ.拠点名
  gt_subinv_name               mtl_secondary_inventories.description%TYPE;          -- 保管場所名
  gt_item_div_h                fnd_profile_option_values.profile_option_value%TYPE; -- プロファイル値：本社商品区分
  gt_inv_cl_char               fnd_profile_option_values.profile_option_value%TYPE; -- プロファイル値：在庫確定文字
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
  -- 管理元拠点情報取得カーソル
  CURSOR get_manage_base_cur(
    iv_base_code VARCHAR2                                  -- 処理対象拠点
  ) IS
    SELECT hca.account_number base_code                    -- 拠点コード
    FROM   hz_cust_accounts    hca                         -- 顧客マスタ
          ,xxcmm_cust_accounts xca                         -- 顧客追加情報
    WHERE  hca.cust_account_id      = xca.customer_id
    AND    hca.customer_class_code  = ct_cust_class_code_1 -- 顧客区分：拠点
    AND    hca.status               = ct_cust_status_a     -- ステータス：有効
    AND    xca.management_base_code = iv_base_code         -- 処理対象拠点
  ;
  g_get_manage_base_rec get_manage_base_cur%ROWTYPE;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_end
   * Description      : 終了処理(A-6)
   ***********************************************************************************/
  PROCEDURE proc_end(
    ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ           
   ,ov_retcode OUT VARCHAR2 -- リターン・コード             
   ,ov_errmsg  OUT VARCHAR2 -- ユーザー・エラー・メッセージ 
  )IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_end'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==============================================================
    -- ワークテーブルデータ削除
    --==============================================================
    DELETE
    FROM   xxcoi_rep_lot_rec_ship_work xrlrsw
    WHERE  xrlrsw.request_id = cn_request_id
    ;
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
  END proc_end;
--
  /**********************************************************************************
   * Procedure Name   : execute_svf
   * Description      : SVF起動(A-5)
   ***********************************************************************************/
  PROCEDURE execute_svf(
    ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ           
   ,ov_retcode OUT VARCHAR2 -- リターン・コード             
   ,ov_errmsg  OUT VARCHAR2 -- ユーザー・エラー・メッセージ 
  )IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'execute_svf'; -- プログラム名
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
    -- *** ローカル変数 ***
    lv_file_name VARCHAR2(200); -- 出力ファイル名
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==============================================================
    -- SVF起動前に、COMMIT発行
    --==============================================================
    COMMIT;
--
    --==============================================================
    -- SVF起動
    --==============================================================
    -- ファイル名設定
    lv_file_name := cv_pkg_name || TO_CHAR( SYSDATE, cv_yyyymmdd2 ) || TO_CHAR( cn_request_id ) || cv_pdf;
--
    -- 共通関数実行
    xxccp_svfcommon_pkg.submit_svf_request(
      ov_retcode      => lv_retcode               -- リターンコード
     ,ov_errbuf       => lv_errbuf                -- エラーメッセージ
     ,ov_errmsg       => lv_errmsg                -- ユーザー・エラーメッセージ
     ,iv_conc_name    => cv_pkg_name              -- コンカレント名
     ,iv_file_name    => lv_file_name             -- 出力ファイル名
     ,iv_file_id      => cv_pkg_name              -- 帳票ID
     ,iv_output_mode  => cv_output_mode_1         -- 出力区分
     ,iv_frm_file     => cv_frm_file              -- フォーム様式ファイル名
     ,iv_vrq_file     => cv_vrq_file              -- クエリー様式ファイル名
     ,iv_org_id       => fnd_global.org_id        -- ORG_ID
     ,iv_user_name    => fnd_global.user_name     -- ログイン・ユーザ名
     ,iv_resp_name    => fnd_global.resp_name     -- ログイン・ユーザの職責名
     ,iv_doc_name     => NULL                     -- 文書名
     ,iv_printer_name => NULL                     -- プリンタ名
     ,iv_request_id   => TO_CHAR( cn_request_id ) -- 要求ID
     ,iv_nodata_msg   => NULL                     -- データなしメッセージ
    );
    -- エラー処理
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcoi_short_name
                    ,iv_name         => cv_msg_xxcoi1_10119
                   );
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
  END execute_svf;
--
  /**********************************************************************************
   * Procedure Name   : ins_work_data
   * Description      : ワークテーブルデータ登録(A-4)
   ***********************************************************************************/
  PROCEDURE ins_work_data(
    ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ           
   ,ov_retcode OUT VARCHAR2 -- リターン・コード             
   ,ov_errmsg  OUT VARCHAR2 -- ユーザー・エラー・メッセージ 
  )IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_work_data'; -- プログラム名
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
    lv_no_data_msg    VARCHAR2(1000);                                    -- 対象0件メッセージ
    lt_practice_year  xxcoi_rep_lot_rec_ship_work.practice_year%TYPE;  -- 対象年
    lt_practice_month xxcoi_rep_lot_rec_ship_work.practice_month%TYPE; -- 対象月
    lt_practice_day   xxcoi_rep_lot_rec_ship_work.practice_day%TYPE;   -- 対象日
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==============================================================
    -- 対象0件時処理
    --==============================================================
    -- 帳票ワークテーブル用テーブル型変数の件数が0件の場合
    IF ( g_lot_rec_work_tab.COUNT = 0 ) THEN
      -- ----------------------------------
      -- 対象0件メッセージをセット
      -- ----------------------------------
      lv_no_data_msg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcoi_short_name
                         ,iv_name         => cv_msg_xxcoi1_00008
                        );
--
      -- ----------------------------------
      -- 拠点、保管場所をセット
      -- ----------------------------------
      g_lot_rec_work_tab(1).base_code         := NVL( gt_login_base_code, gt_base_code ); -- 拠点コード
      g_lot_rec_work_tab(1).base_name         := gt_base_name;                            -- 拠点名
      g_lot_rec_work_tab(1).subinventory_code := gt_subinventory_code;                    -- 保管場所コード
      g_lot_rec_work_tab(1).subinventory_name := gt_subinv_name;                          -- 保管場所名
--
    -- 0件以外の場合は、対象0件メッセージにNULLをセット
    ELSE
      lv_no_data_msg := NULL;
    END IF;
--
    --==============================================================
    -- ロット別棚卸・受払確認表(倉庫)帳票ワークテーブル作成
    --==============================================================
    -- ----------------------------------
    -- 対象年・対象月・対象日設定
    -- ----------------------------------
    lt_practice_year  := TO_CHAR( gd_target_date, cv_yy ); -- 対象年
    lt_practice_month := TO_CHAR( gd_target_date, cv_mm ); -- 対象月
    -- 日次の場合
    IF ( gt_exe_type = cv_exe_type_10 ) THEN
      lt_practice_day := TO_CHAR( gd_target_date, cv_dd ); -- 対象日
    -- 月次の場合
    ELSE
      lt_practice_day := NULL;                             -- 対象日
    END IF;
--
    -- 帳票ワークテーブル用テーブル型変数の件数だけデータ行作成
    <<ins_work_data_loop>>
    FOR i IN 1..g_lot_rec_work_tab.COUNT LOOP
      INSERT INTO xxcoi_rep_lot_rec_ship_work(
        execute_type                                  -- 実行区分
       ,practice_year                                 -- 対象年
       ,practice_month                                -- 対象月
       ,practice_day                                  -- 対象日
       ,base_code                                     -- 拠点コード
       ,base_name                                     -- 拠点名
       ,subinventory_code                             -- 保管場所コード
       ,subinventory_name                             -- 保管場所名
       ,inv_cl_char                                   -- 在庫確定印字文字
       ,item_type                                     -- 商品区分
       ,gun_code                                      -- 群コード
       ,child_item_code                               -- 子商品コード
       ,child_item_name                               -- 子商品名
       ,taste_term                                    -- 賞味期限
       ,difference_summary_code                       -- 固有記号
       ,location_code                                 -- ロケーションコード
       ,location_name                                 -- ロケーション名
       ,month_begin_quantity                          -- 月首棚卸高
       ,factory_stock                                 -- 工場入庫
       ,change_stock                                  -- 倉替入庫
       ,truck_stock                                   -- 営業車より入庫
       ,truck_ship                                    -- 営業車へ出庫
       ,sales_shipped                                 -- 売上出庫
       ,support                                       -- 協賛見本
       ,removed_goods                                 -- 廃却出庫
       ,change_ship                                   -- 倉替出庫
       ,factory_return                                -- 工場返品
       ,location_move                                 -- ロケーション移動
       ,inv_adjust                                    -- 在庫調整
       ,book_inventory_quantity                       -- 帳簿在庫
       ,message                                       -- メッセージ
       ,created_by                                    -- 作成者
       ,creation_date                                 -- 作成日
       ,last_updated_by                               -- 最終更新者
       ,last_update_date                              -- 最終更新日
       ,last_update_login                             -- 最終更新ログイン
       ,request_id                                    -- 要求ID
       ,program_application_id                        -- アプリケーションID
       ,program_id                                    -- プログラムID
       ,program_update_date                           -- プログラム更新日
      )VALUES(
        gt_exe_type_meaning                           -- 実行区分
       ,lt_practice_year                              -- 対象年
       ,lt_practice_month                             -- 対象月
       ,lt_practice_day                               -- 対象日
       ,g_lot_rec_work_tab(i).base_code               -- 拠点コード
       ,g_lot_rec_work_tab(i).base_name               -- 拠点名
       ,g_lot_rec_work_tab(i).subinventory_code       -- 保管場所コード
       ,g_lot_rec_work_tab(i).subinventory_name       -- 保管場所名
       ,gt_inv_cl_char                                -- 在庫確定印字文字
       ,g_lot_rec_work_tab(i).item_type               -- 商品区分
       ,g_lot_rec_work_tab(i).gun_code                -- 群コード
       ,g_lot_rec_work_tab(i).child_item_code         -- 子商品コード
       ,g_lot_rec_work_tab(i).child_item_name         -- 子商品名
       ,g_lot_rec_work_tab(i).taste_term              -- 賞味期限
       ,g_lot_rec_work_tab(i).difference_summary_code -- 固有記号
       ,g_lot_rec_work_tab(i).location_code           -- ロケーションコード
       ,g_lot_rec_work_tab(i).location_name           -- ロケーション名
       ,g_lot_rec_work_tab(i).month_begin_quantity    -- 月首棚卸高
       ,g_lot_rec_work_tab(i).factory_stock           -- 工場入庫
       ,g_lot_rec_work_tab(i).change_stock            -- 倉替入庫
       ,g_lot_rec_work_tab(i).truck_stock             -- 営業車より入庫
       ,g_lot_rec_work_tab(i).truck_ship              -- 営業車へ出庫
       ,g_lot_rec_work_tab(i).sales_shipped           -- 売上出庫
       ,g_lot_rec_work_tab(i).support                 -- 協賛見本
       ,g_lot_rec_work_tab(i).removed_goods           -- 廃却出庫
       ,g_lot_rec_work_tab(i).change_ship             -- 倉替出庫
       ,g_lot_rec_work_tab(i).factory_return          -- 工場返品
       ,g_lot_rec_work_tab(i).location_move           -- ロケーション移動
       ,g_lot_rec_work_tab(i).inv_adjust              -- 在庫調整
       ,g_lot_rec_work_tab(i).book_inventory_quantity -- 帳簿在庫
       ,lv_no_data_msg                                -- メッセージ
       ,cn_created_by                                 -- 作成者
       ,cd_creation_date                              -- 作成日
       ,cn_last_updated_by                            -- 最終更新者
       ,cd_last_update_date                           -- 最終更新日
       ,cn_last_update_login                          -- 最終更新ログイン
       ,cn_request_id                                 -- 要求ID
       ,cn_program_application_id                     -- アプリケーションID
       ,cn_program_id                                 -- プログラムID
       ,cd_program_update_date                        -- プログラム更新日
      );
--
      -- 正常件数カウント
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP ins_work_data_loop;
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
  END ins_work_data;
--
  /**********************************************************************************
   * Procedure Name   : get_monthly_data
   * Description      : ロット別受払（月次）データ取得(A-3)
   ***********************************************************************************/
  PROCEDURE get_monthly_data(
    ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ           
   ,ov_retcode OUT VARCHAR2 -- リターン・コード             
   ,ov_errmsg  OUT VARCHAR2 -- ユーザー・エラー・メッセージ 
  )IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_monthly_data'; -- プログラム名
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
    ln_dummy NUMBER; -- ロット別受払(月次)存在チェック
--
    -- *** ローカル・カーソル ***
    -- ロット別受払(月次)情報カーソル
    CURSOR get_monthly_data_cur(
      iv_base_code VARCHAR2 -- 対象拠点
    )IS
      SELECT xlrm.base_code                    base_code               -- 拠点コード
            ,hp.party_name                     party_name              -- パーティ名
            ,xlrm.subinventory_code            subinventory_code       -- 保管場所コード
            ,msi.description                   subinventory_name       -- 保管場所名
            ,mcb.segment1                      item_type               -- 商品区分
            ,SUBSTRB(
               (CASE WHEN (TO_DATE( iimb.attribute3, cv_yyyymmdd ) ) > gd_proc_date -- 摘要開始日>業務日付
                 THEN iimb.attribute1 -- 群コード(旧)
                 ELSE iimb.attribute2 -- 群コード(新)
               END) ,1 ,3 )                    gun_code                -- 群コード
            ,msib.segment1                     item_code               -- 子品目コード
            ,ximb.item_short_name              item_name               -- 子品目名
            ,xlrm.lot                          lot                     -- ロット
            ,xlrm.difference_summary_code      diff_sum_code           -- 固有記号
            ,xlrm.location_code                location_code           -- ロケーションコード
            ,xwlmv.location_name               location_name           -- ロケーション名
            ,SUM(xlrm.month_begin_quantity)    month_begin_quantity    -- 月初棚卸高
            ,SUM(xlrm.factory_stock)           factory_stock           -- 工場入庫
            ,SUM(xlrm.factory_stock_b)         factory_stock_b         -- 工場入庫振戻
            ,SUM(xlrm.change_stock)            change_stock            -- 倉替入庫
            ,SUM(xlrm.others_stock)            others_stock            -- 入出庫＿その他入庫
            ,SUM(xlrm.truck_stock)             truck_stock             -- 営業車より入庫
            ,SUM(xlrm.truck_ship)              truck_ship              -- 営業車へ出庫
            ,SUM(xlrm.sales_shipped)           sales_shipped           -- 売上出庫
            ,SUM(xlrm.sales_shipped_b)         sales_shipped_b         -- 売上出庫振戻
            ,SUM(xlrm.return_goods)            return_goods            -- 返品
            ,SUM(xlrm.return_goods_b)          return_goods_b          -- 返品振戻
            ,SUM(xlrm.customer_sample_ship)    customer_sample_ship    -- 顧客見本出庫
            ,SUM(xlrm.customer_sample_ship_b)  customer_sample_ship_b  -- 顧客見本出庫振戻
            ,SUM(xlrm.customer_support_ss)     customer_support_ss     -- 顧客協賛見本出庫
            ,SUM(xlrm.customer_support_ss_b)   customer_support_ss_b   -- 顧客協賛見本出庫振戻
            ,SUM(xlrm.ccm_sample_ship)         ccm_sample_ship         -- 顧客広告宣伝費A自社商品
            ,SUM(xlrm.ccm_sample_ship_b)       ccm_sample_ship_b       -- 顧客広告宣伝費A自社商品振戻
            ,SUM(xlrm.vd_supplement_stock)     vd_supplement_stock     -- 消化VD補充入庫
            ,SUM(xlrm.vd_supplement_ship)      vd_supplement_ship      -- 消化VD補充出庫
            ,SUM(xlrm.removed_goods)           removed_goods           -- 廃却
            ,SUM(xlrm.removed_goods_b)         removed_goods_b         -- 廃却振戻
            ,SUM(xlrm.change_ship)             change_ship             -- 倉替出庫
            ,SUM(xlrm.others_ship)             others_ship             -- 入出庫＿その他出庫
            ,SUM(xlrm.factory_change)          factory_change          -- 工場倉替
            ,SUM(xlrm.factory_change_b)        factory_change_b        -- 工場倉替振戻
            ,SUM(xlrm.factory_return)          factory_return          -- 工場返品
            ,SUM(xlrm.factory_return_b)        factory_return_b        -- 工場返品振戻
            ,SUM(xlrm.location_decrease)       location_decrease       -- ロケーション移動増
            ,SUM(xlrm.location_increase)       location_increase       -- ロケーション移動減
            ,SUM(xlrm.adjust_decrease)         adjust_decrease         -- 在庫調整増
            ,SUM(xlrm.adjust_increase)         adjust_increase         -- 在庫調整減
            ,SUM(xlrm.book_inventory_quantity) book_inventory_quantity -- 帳簿在庫数
      FROM   xxcoi_lot_reception_monthly       xlrm                    -- ロット別受払(月次)
            ,hz_cust_accounts                  hca                     -- 顧客マスタ
            ,hz_parties                        hp                      -- パーティマスタ
            ,mtl_secondary_inventories         msi                     -- 保管場所マスタ
            ,mtl_system_items_b                msib                    -- Disc品目マスタ
            ,ic_item_mst_b                     iimb                    -- OPM品目マスタ
            ,xxcmn_item_mst_b                  ximb                    -- OPM品目マスタアドオン
            ,mtl_categories_b                  mcb                     -- 品目カテゴリマスタ
            ,mtl_item_categories               mic                     -- 品目カテゴリマスタ割当
            ,mtl_category_sets_b               mcsb                    -- 品目カテゴリセット
            ,mtl_category_sets_tl              mcst                    -- 品目カテゴリセット日本語
            ,xxcoi_warehouse_location_mst_v    xwlmv                   -- 倉庫ロケーションマスタ
      WHERE  xlrm.practice_month     = gv_target_month                 -- 入力パラメータ.年月
      AND    xlrm.base_code          = iv_base_code                    -- 拠点コード
      AND    xlrm.subinventory_code  = NVL( gt_subinventory_code, xlrm.subinventory_code )
                                                                       -- 入力パラメータ.保管場所
      AND    xlrm.organization_id    = gt_org_id                       -- 在庫組織ID
      AND    xlrm.base_code          = hca.account_number
      AND    hca.customer_class_code = ct_cust_class_code_1            -- 顧客区分：拠点
      AND    hca.status              = ct_cust_status_a                -- ステータス：有効
      AND    hca.party_id            = hp.party_id 
      AND    xlrm.subinventory_code  = msi.secondary_inventory_name
      AND    xlrm.organization_id    = msi.organization_id
      AND    msi.attribute14         = ct_warehouse_flag_y             -- 倉庫管理対象
      AND    xlrm.child_item_id      = msib.inventory_item_id
      AND    xlrm.organization_id    = msib.organization_id
      AND    msib.segment1           = iimb.item_no
      AND    iimb.item_id            = ximb.item_id
      AND    gd_proc_date BETWEEN ximb.start_date_active 
                              AND ximb.end_date_active                 -- 有効日
      AND    msib.inventory_item_id  = mic.inventory_item_id
      AND    msib.organization_id    = mic.organization_id
      AND    mic.category_id         = mcb.category_id
      AND    mic.category_set_id     = mcsb.category_set_id
      AND    mcsb.category_set_id    = mcst.category_set_id
      AND    mcst.language           = ct_lang                         -- 言語
      AND    mcst.category_set_name  = gt_item_div_h                   -- プロファイル値：本社商品区分
      AND    xlrm.organization_id    = xwlmv.organization_id(+)
      AND    xlrm.base_code          = xwlmv.base_code(+)
      AND    xlrm.subinventory_code  = xwlmv.subinventory_code(+)
      AND    xlrm.location_code      = xwlmv.location_code(+)
      GROUP BY
         xlrm.base_code                                                -- 拠点コード
        ,hp.party_name                                                 -- パーティ名
        ,xlrm.subinventory_code                                        -- 保管場所コード
        ,msi.description                                               -- 保管場所名
        ,mcb.segment1                                                  -- 商品区分
        ,SUBSTRB(
           (CASE WHEN (TO_DATE( iimb.attribute3, cv_yyyymmdd ) ) > gd_proc_date
             THEN iimb.attribute1
             ELSE iimb.attribute2
           END) ,1 ,3 )                                                -- 群コード
        ,msib.segment1                                                 -- 子品目コード
        ,ximb.item_short_name                                          -- 子品目名
        ,xlrm.lot                                                      -- ロット
        ,xlrm.difference_summary_code                                  -- 固有記号
        ,xlrm.location_code                                            -- ロケーションコード
        ,xwlmv.location_name                                           -- ロケーション名
    ;
--
    -- *** ローカル・レコード ***
    -- ロット別受払(月次)情報レコード
    l_get_monthly_data_rec get_monthly_data_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 変数初期化
    g_base_code_tab.DELETE; -- 処理対象拠点情報格納用テーブル型
--
    --==============================================================
    -- 管理元拠点情報取得
    --==============================================================
    -- 管理元拠点情報取得カーソルオープン
    OPEN get_manage_base_cur(
      iv_base_code => NVL( gt_login_base_code, gt_base_code ) -- 入力パラメータorログインユーザ所属拠点
    );
--
    <<manage_base_loop>>
    LOOP
      -- 管理元拠点情報フェッチ
      FETCH get_manage_base_cur INTO g_get_manage_base_rec;
      EXIT WHEN get_manage_base_cur%NOTFOUND;
--
      -- ロット別受払(月次)存在チェック初期化
      ln_dummy := 0;
--
      -- --------------------------------
      -- ロット別受払(月次)存在チェック
      -- --------------------------------
      SELECT COUNT(1)
      INTO   ln_dummy
      FROM   mtl_secondary_inventories msi
            ,xxcoi_lot_reception_monthly xlrm
      WHERE  msi.attribute14              = ct_warehouse_flag_y             -- 倉庫管理対象
      AND    msi.organization_id          = gt_org_id                       -- 在庫組織ID
      AND    msi.secondary_inventory_name = xlrm.subinventory_code
      AND    msi.organization_id          = xlrm.organization_id
      AND    xlrm.base_code               = g_get_manage_base_rec.base_code -- 拠点コード
      AND    xlrm.practice_date           = gd_target_date                  -- 入力パラメータ.年月日
      AND    ROWNUM                       = 1
      ;
      -- ---------------------------------------
      -- 存在する場合は、処理対象拠点として保持
      -- ---------------------------------------
      IF ( ln_dummy > 0 ) THEN
        g_base_code_tab(g_base_code_tab.COUNT + 1).base_code := g_get_manage_base_rec.base_code;
      END IF;
--
    END LOOP manage_base_loop;
    -- 管理元拠点情報取得カーソルクローズ
    CLOSE get_manage_base_cur;
--
    -- 管理元拠点情報取得が取得できていない場合、入力パラメータ.拠点を処理対象とする
    IF ( g_base_code_tab.COUNT = 0 ) THEN
      g_base_code_tab(1).base_code := gt_login_base_code;
    END IF;
--
    --==============================================================
    -- ロット別受払(月次)情報取得
    --==============================================================
    -- ---------------------------------------
    -- 処理対象拠点の件数だけ実行
    -- ---------------------------------------
    <<get_monthly_data_loop>>
    FOR i IN 1..g_base_code_tab.COUNT LOOP
      -- 処理対象拠点をセットしカーソルオープン
      OPEN get_monthly_data_cur(
        iv_base_code => g_base_code_tab(i).base_code -- 処理対象拠点
      );
--
      -- 取得した情報を使用し、帳票ワークテーブルデータを格納する
      <<set_work_tbl_data_loop>>
      LOOP
--
        -- データフェッチ
        FETCH get_monthly_data_cur INTO l_get_monthly_data_rec;
        EXIT WHEN get_monthly_data_cur%NOTFOUND;
--
        -- 件数カウント
        gn_target_cnt := gn_target_cnt + 1; -- 処理件数
--
        --==============================================================
        -- 取得した値を帳票ワークテーブル用テーブル型変数にデータをセット
        --==============================================================
        -- 拠点コード
        g_lot_rec_work_tab(gn_target_cnt).base_code
          := l_get_monthly_data_rec.base_code;
--
        -- 拠点名
        g_lot_rec_work_tab(gn_target_cnt).base_name
          := l_get_monthly_data_rec.party_name;
--
        -- 保管場所コード
        g_lot_rec_work_tab(gn_target_cnt).subinventory_code
          := l_get_monthly_data_rec.subinventory_code;
--
        -- 保管場所名
        g_lot_rec_work_tab(gn_target_cnt).subinventory_name
          := l_get_monthly_data_rec.subinventory_name;
--
        -- 商品区分
        g_lot_rec_work_tab(gn_target_cnt).item_type
          := l_get_monthly_data_rec.item_type;
--
        -- 群コード
        g_lot_rec_work_tab(gn_target_cnt).gun_code
          := l_get_monthly_data_rec.gun_code;
--
        -- 子品目コード
        g_lot_rec_work_tab(gn_target_cnt).child_item_code
          := l_get_monthly_data_rec.item_code;
--
        -- 子品目名
        g_lot_rec_work_tab(gn_target_cnt).child_item_name
          := l_get_monthly_data_rec.item_name;
--
        -- ロット(賞味期限)
        g_lot_rec_work_tab(gn_target_cnt).taste_term
          := l_get_monthly_data_rec.lot;
--
        -- 固有記号
        g_lot_rec_work_tab(gn_target_cnt).difference_summary_code
          := l_get_monthly_data_rec.diff_sum_code;
--
        -- ロケーションコード
        g_lot_rec_work_tab(gn_target_cnt).location_code
          := l_get_monthly_data_rec.location_code;
--
        -- ロケーション名
        g_lot_rec_work_tab(gn_target_cnt).location_name
          := l_get_monthly_data_rec.location_name;
--
        -- 月首棚卸高
        g_lot_rec_work_tab(gn_target_cnt).month_begin_quantity
          := l_get_monthly_data_rec.month_begin_quantity;
--
        -- 工場入庫
        g_lot_rec_work_tab(gn_target_cnt).factory_stock
          := l_get_monthly_data_rec.factory_stock            -- 工場入庫
           - l_get_monthly_data_rec.factory_stock_b          -- 工場入庫振戻
        ;
--
        -- 倉替入庫
        g_lot_rec_work_tab(gn_target_cnt).change_stock
          := l_get_monthly_data_rec.change_stock             -- 倉替入庫
           + l_get_monthly_data_rec.others_stock             -- 入出庫_その他入庫
           + l_get_monthly_data_rec.vd_supplement_stock      -- 消化VD補充入庫
        ;
--
        -- 営業車より入庫
        g_lot_rec_work_tab(gn_target_cnt).truck_stock
          := l_get_monthly_data_rec.truck_stock              -- 営業車より入庫
        ;
--
        -- 営業車へ出庫
        g_lot_rec_work_tab(gn_target_cnt).truck_ship
          := l_get_monthly_data_rec.truck_ship               -- 営業車へ出庫
        ;
--
        -- 売上出庫
        g_lot_rec_work_tab(gn_target_cnt).sales_shipped
          := l_get_monthly_data_rec.sales_shipped            -- 売上出庫
           - l_get_monthly_data_rec.sales_shipped_b          -- 売上出庫振戻
           - l_get_monthly_data_rec.return_goods             -- 返品
           + l_get_monthly_data_rec.return_goods_b           -- 返品振戻
        ;
--
        -- 協賛見本
        g_lot_rec_work_tab(gn_target_cnt).support
          := l_get_monthly_data_rec.customer_sample_ship     -- 顧客見本出庫
           - l_get_monthly_data_rec.customer_sample_ship_b   -- 顧客見本出庫振戻
           + l_get_monthly_data_rec.customer_support_ss      -- 顧客協賛見本出庫
           - l_get_monthly_data_rec.customer_support_ss_b    -- 顧客協賛見本出庫振戻
           + l_get_monthly_data_rec.ccm_sample_ship          -- 顧客広告宣伝費A自社商品
           - l_get_monthly_data_rec.ccm_sample_ship_b        -- 顧客広告宣伝費A自社商品振戻
        ;
--
        -- 廃却出庫
        g_lot_rec_work_tab(gn_target_cnt).removed_goods
          := l_get_monthly_data_rec.removed_goods            -- 廃却
           - l_get_monthly_data_rec.removed_goods_b          -- 廃却振戻
        ;
--
        -- 倉替出庫
        g_lot_rec_work_tab(gn_target_cnt).change_ship
          := l_get_monthly_data_rec.change_ship              -- 倉替出庫
           + l_get_monthly_data_rec.others_ship              -- 入出庫＿その他出庫
           + l_get_monthly_data_rec.factory_change           -- 工場倉替
           - l_get_monthly_data_rec.factory_change_b         -- 工場倉替振戻
           + l_get_monthly_data_rec.vd_supplement_ship       -- 消化VD補充出庫
        ;
--
        -- 工場返品
        g_lot_rec_work_tab(gn_target_cnt).factory_return
          := l_get_monthly_data_rec.factory_return           -- 工場返品
           - l_get_monthly_data_rec.factory_return_b         -- 工場返品振戻
        ;
--
        -- ロケーション移動
        g_lot_rec_work_tab(gn_target_cnt).location_move
          := l_get_monthly_data_rec.location_decrease        -- ロケーション移動増
           - l_get_monthly_data_rec.location_increase        -- ロケーション移動減
        ;
--
        -- 在庫調整
        g_lot_rec_work_tab(gn_target_cnt).inv_adjust
          := l_get_monthly_data_rec.adjust_decrease          -- 在庫調整増
           - l_get_monthly_data_rec.adjust_increase          -- 在庫調整減
        ;
--
        -- 帳簿在庫
        g_lot_rec_work_tab(gn_target_cnt).book_inventory_quantity
          := l_get_monthly_data_rec.book_inventory_quantity; -- 帳簿在庫数
--
      END LOOP set_work_tbl_data_loop;
--
      -- カーソルクローズ
      CLOSE get_monthly_data_cur;
--
    END LOOP get_monthly_data_loop;
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
      -- カーソルクローズ
      IF ( get_manage_base_cur%ISOPEN ) THEN
        CLOSE get_manage_base_cur;
      END IF;
--
      IF ( get_monthly_data_cur%ISOPEN ) THEN
        CLOSE get_manage_base_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END get_monthly_data;
--
  /**********************************************************************************
   * Procedure Name   : get_daily_data
   * Description      : ロット別受払(日次)データ取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_daily_data(
    ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ           
   ,ov_retcode OUT VARCHAR2 -- リターン・コード             
   ,ov_errmsg  OUT VARCHAR2 -- ユーザー・エラー・メッセージ 
  )IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_daily_data'; -- プログラム名
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
    ln_dummy NUMBER; -- ロット別受払(日次)存在チェック
--
    -- *** ローカル・カーソル ***
    -- ロット別受払(日次)情報カーソル
    CURSOR get_daily_data_cur(
      iv_base_code VARCHAR2 -- 対象拠点
    )IS
      SELECT xlrd.base_code                   base_code                   -- 拠点コード
            ,hp.party_name                    party_name                  -- パーティ名
            ,xlrd.subinventory_code           subinventory_code           -- 保管場所コード
            ,msi.description                  subinventory_name           -- 保管場所名
            ,mcb.segment1                     item_type                   -- 商品区分
            ,SUBSTRB(
               (CASE WHEN (TO_DATE( iimb.attribute3, cv_yyyymmdd ) ) > gd_proc_date -- 摘要開始日>業務日付
                 THEN iimb.attribute1 -- 群コード(旧)
                 ELSE iimb.attribute2 -- 群コード(新)
               END) ,1 ,3 )                   gun_code                    -- 群コード
            ,msib.segment1                    item_code                   -- 子品目コード
            ,ximb.item_short_name             item_name                   -- 子品目名
            ,xlrd.lot                         lot                         -- ロット
            ,xlrd.difference_summary_code     diff_sum_code               -- 固有記号
            ,xlrd.location_code               location_code               -- ロケーションコード
            ,xwlmv.location_name              location_name               -- ロケーション名
            ,xlrd.previous_inventory_quantity previous_inventory_quantity -- 前日在庫数
            ,xlrd.factory_stock               factory_stock               -- 工場入庫
            ,xlrd.factory_stock_b             factory_stock_b             -- 工場入庫振戻
            ,xlrd.change_stock                change_stock                -- 倉替入庫
            ,xlrd.others_stock                others_stock                -- 入出庫＿その他入庫
            ,xlrd.truck_stock                 truck_stock                 -- 営業車より入庫
            ,xlrd.truck_ship                  truck_ship                  -- 営業車へ出庫
            ,xlrd.sales_shipped               sales_shipped               -- 売上出庫
            ,xlrd.sales_shipped_b             sales_shipped_b             -- 売上出庫振戻
            ,xlrd.return_goods                return_goods                -- 返品
            ,xlrd.return_goods_b              return_goods_b              -- 返品振戻
            ,xlrd.customer_sample_ship        customer_sample_ship        -- 顧客見本出庫
            ,xlrd.customer_sample_ship_b      customer_sample_ship_b      -- 顧客見本出庫振戻
            ,xlrd.customer_support_ss         customer_support_ss         -- 顧客協賛見本出庫
            ,xlrd.customer_support_ss_b       customer_support_ss_b       -- 顧客協賛見本出庫振戻
            ,xlrd.ccm_sample_ship             ccm_sample_ship             -- 顧客広告宣伝費A自社商品
            ,xlrd.ccm_sample_ship_b           ccm_sample_ship_b           -- 顧客広告宣伝費A自社商品振戻
            ,xlrd.vd_supplement_stock         vd_supplement_stock         -- 消化VD補充入庫
            ,xlrd.vd_supplement_ship          vd_supplement_ship          -- 消化VD補充出庫
            ,xlrd.removed_goods               removed_goods               -- 廃却
            ,xlrd.removed_goods_b             removed_goods_b             -- 廃却振戻
            ,xlrd.change_ship                 change_ship                 -- 倉替出庫
            ,xlrd.others_ship                 others_ship                 -- 入出庫＿その他出庫
            ,xlrd.factory_change              factory_change              -- 工場倉替
            ,xlrd.factory_change_b            factory_change_b            -- 工場倉替振戻
            ,xlrd.factory_return              factory_return              -- 工場返品
            ,xlrd.factory_return_b            factory_return_b            -- 工場返品振戻
            ,xlrd.location_decrease           location_decrease           -- ロケーション移動増
            ,xlrd.location_increase           location_increase           -- ロケーション移動減
            ,xlrd.adjust_decrease             adjust_decrease             -- 在庫調整増
            ,xlrd.adjust_increase             adjust_increase             -- 在庫調整減
            ,xlrd.book_inventory_quantity     book_inventory_quantity     -- 帳簿在庫数
      FROM   xxcoi_lot_reception_daily        xlrd                        -- ロット別受払(日次)
            ,hz_cust_accounts                 hca                         -- 顧客マスタ
            ,hz_parties                       hp                          -- パーティマスタ
            ,mtl_secondary_inventories        msi                         -- 保管場所マスタ
            ,mtl_system_items_b               msib                        -- Disc品目マスタ
            ,ic_item_mst_b                    iimb                        -- OPM品目マスタ
            ,xxcmn_item_mst_b                 ximb                        -- OPM品目マスタアドオン
            ,mtl_categories_b                 mcb                         -- 品目カテゴリマスタ
            ,mtl_item_categories              mic                         -- 品目カテゴリマスタ割当
            ,mtl_category_sets_b              mcsb                        -- 品目カテゴリセット
            ,mtl_category_sets_tl             mcst                        -- 品目カテゴリセット日本語
            ,xxcoi_warehouse_location_mst_v   xwlmv                       -- 倉庫ロケーションマスタ
      WHERE  xlrd.practice_date      = gd_target_date                     -- 入力パラメータ.年月日
      AND    xlrd.base_code          = iv_base_code                       -- 拠点コード
      AND    xlrd.subinventory_code  = NVL( gt_subinventory_code, xlrd.subinventory_code )
                                                                          -- 入力パラメータ.保管場所
      AND    xlrd.organization_id    = gt_org_id                          -- 在庫組織ID
      AND    xlrd.base_code          = hca.account_number
      AND    hca.customer_class_code = ct_cust_class_code_1               -- 顧客区分：拠点
      AND    hca.status              = ct_cust_status_a                   -- ステータス：有効
      AND    hca.party_id            = hp.party_id 
      AND    xlrd.subinventory_code  = msi.secondary_inventory_name
      AND    xlrd.organization_id    = msi.organization_id
      AND    msi.attribute14         = ct_warehouse_flag_y                -- 倉庫管理対象
      AND    xlrd.child_item_id      = msib.inventory_item_id
      AND    xlrd.organization_id    = msib.organization_id
      AND    msib.segment1           = iimb.item_no
      AND    iimb.item_id            = ximb.item_id
      AND    gd_proc_date BETWEEN ximb.start_date_active 
                              AND ximb.end_date_active                    -- 有効日
      AND    msib.inventory_item_id  = mic.inventory_item_id
      AND    msib.organization_id    = mic.organization_id
      AND    mic.category_id         = mcb.category_id
      AND    mic.category_set_id     = mcsb.category_set_id
      AND    mcsb.category_set_id    = mcst.category_set_id
      AND    mcst.language           = ct_lang                            -- 言語
      AND    mcst.category_set_name  = gt_item_div_h                      -- プロファイル値：本社商品区分
      AND    xlrd.organization_id    = xwlmv.organization_id(+)
      AND    xlrd.base_code          = xwlmv.base_code(+)
      AND    xlrd.subinventory_code  = xwlmv.subinventory_code(+)
      AND    xlrd.location_code      = xwlmv.location_code(+)
    ;
--
    -- *** ローカル・レコード ***
    -- ロット別受払(日次)情報レコード
    l_get_daily_data_rec get_daily_data_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 変数初期化
    g_base_code_tab.DELETE; -- 処理対象拠点情報格納用テーブル型
--
    --==============================================================
    -- 管理元拠点情報取得
    --==============================================================
    -- 管理元拠点情報取得カーソルオープン
    OPEN get_manage_base_cur(
      iv_base_code => NVL( gt_login_base_code, gt_base_code ) -- 入力パラメータorログインユーザ所属拠点
    );
--
    <<manage_base_loop>>
    LOOP
      -- 管理元拠点情報フェッチ
      FETCH get_manage_base_cur INTO g_get_manage_base_rec;
      EXIT WHEN get_manage_base_cur%NOTFOUND;
--
      -- ロット別受払(日次)存在チェック初期化
      ln_dummy := 0;
--
      -- --------------------------------
      -- ロット別受払(日次)存在チェック
      -- --------------------------------
      SELECT COUNT(1)
      INTO   ln_dummy
      FROM   mtl_secondary_inventories msi
            ,xxcoi_lot_reception_daily xlrd
      WHERE  msi.attribute14              = ct_warehouse_flag_y             -- 倉庫管理対象
      AND    msi.organization_id          = gt_org_id                       -- 在庫組織ID
      AND    msi.secondary_inventory_name = xlrd.subinventory_code
      AND    msi.organization_id          = xlrd.organization_id
      AND    xlrd.base_code               = g_get_manage_base_rec.base_code -- 拠点コード
      AND    xlrd.practice_date           = gd_target_date                  -- 入力パラメータ.年月日
      AND    ROWNUM                       = 1
      ;
      -- ---------------------------------------
      -- 存在する場合は、処理対象拠点として保持
      -- ---------------------------------------
      IF ( ln_dummy > 0 ) THEN
        g_base_code_tab(g_base_code_tab.COUNT + 1).base_code := g_get_manage_base_rec.base_code;
      END IF;
--
    END LOOP manage_base_loop;
    -- 管理元拠点情報取得カーソルクローズ
    CLOSE get_manage_base_cur;
--
    -- 管理元拠点情報取得が取得できていない場合、入力パラメータ.拠点を処理対象とする
    IF ( g_base_code_tab.COUNT = 0 ) THEN
      g_base_code_tab(1).base_code := gt_login_base_code;
    END IF;
--
    --==============================================================
    -- ロット別受払(日次)情報取得
    --==============================================================
    -- ---------------------------------------
    -- 処理対象拠点の件数だけ実行
    -- ---------------------------------------
    <<get_daily_data_loop>>
    FOR i IN 1..g_base_code_tab.COUNT LOOP
      -- 処理対象拠点をセットしカーソルオープン
      OPEN get_daily_data_cur(
        iv_base_code => g_base_code_tab(i).base_code -- 処理対象拠点
      );
--
      -- 取得した情報を使用し、帳票ワークテーブルデータを格納する
      <<set_work_tbl_data_loop>>
      LOOP
--
        -- データフェッチ
        FETCH get_daily_data_cur INTO l_get_daily_data_rec;
        EXIT WHEN get_daily_data_cur%NOTFOUND;
--
        -- 件数カウント
        gn_target_cnt := gn_target_cnt + 1; -- 処理件数
--
        --==============================================================
        -- 取得した値を帳票ワークテーブル用テーブル型変数にデータをセット
        --==============================================================
        -- 拠点コード
        g_lot_rec_work_tab(gn_target_cnt).base_code
          := l_get_daily_data_rec.base_code;
--
        -- 拠点名
        g_lot_rec_work_tab(gn_target_cnt).base_name
          := l_get_daily_data_rec.party_name;
--
        -- 保管場所コード
        g_lot_rec_work_tab(gn_target_cnt).subinventory_code
          := l_get_daily_data_rec.subinventory_code;
--
        -- 保管場所名
        g_lot_rec_work_tab(gn_target_cnt).subinventory_name
          := l_get_daily_data_rec.subinventory_name;
--
        -- 商品区分
        g_lot_rec_work_tab(gn_target_cnt).item_type
          := l_get_daily_data_rec.item_type;
--
        -- 群コード
        g_lot_rec_work_tab(gn_target_cnt).gun_code
          := l_get_daily_data_rec.gun_code;
--
        -- 子品目コード
        g_lot_rec_work_tab(gn_target_cnt).child_item_code
          := l_get_daily_data_rec.item_code;
--
        -- 子品目名
        g_lot_rec_work_tab(gn_target_cnt).child_item_name
          := l_get_daily_data_rec.item_name;
--
        -- ロット(賞味期限)
        g_lot_rec_work_tab(gn_target_cnt).taste_term
          := l_get_daily_data_rec.lot;
--
        -- 固有記号
        g_lot_rec_work_tab(gn_target_cnt).difference_summary_code
          := l_get_daily_data_rec.diff_sum_code;
--
        -- ロケーションコード
        g_lot_rec_work_tab(gn_target_cnt).location_code
          := l_get_daily_data_rec.location_code;
--
        -- ロケーション名
        g_lot_rec_work_tab(gn_target_cnt).location_name
          := l_get_daily_data_rec.location_name;
--
        -- 月首棚卸高
        g_lot_rec_work_tab(gn_target_cnt).month_begin_quantity
          := l_get_daily_data_rec.previous_inventory_quantity;
--
        -- 工場入庫
        g_lot_rec_work_tab(gn_target_cnt).factory_stock
          := l_get_daily_data_rec.factory_stock            -- 工場入庫
           - l_get_daily_data_rec.factory_stock_b          -- 工場入庫振戻
        ;
--
        -- 倉替入庫
        g_lot_rec_work_tab(gn_target_cnt).change_stock
          := l_get_daily_data_rec.change_stock             -- 倉替入庫
           + l_get_daily_data_rec.others_stock             -- 入出庫_その他入庫
           + l_get_daily_data_rec.vd_supplement_stock      -- 消化VD補充入庫
        ;
--
        -- 営業車より入庫
        g_lot_rec_work_tab(gn_target_cnt).truck_stock
          := l_get_daily_data_rec.truck_stock              -- 営業車より入庫
        ;
--
        -- 営業車へ出庫
        g_lot_rec_work_tab(gn_target_cnt).truck_ship
          := l_get_daily_data_rec.truck_ship               -- 営業車へ出庫
        ;
--
        -- 売上出庫
        g_lot_rec_work_tab(gn_target_cnt).sales_shipped
          := l_get_daily_data_rec.sales_shipped            -- 売上出庫
           - l_get_daily_data_rec.sales_shipped_b          -- 売上出庫振戻
           - l_get_daily_data_rec.return_goods             -- 返品
           + l_get_daily_data_rec.return_goods_b           -- 返品振戻
        ;
--
        -- 協賛見本
        g_lot_rec_work_tab(gn_target_cnt).support
          := l_get_daily_data_rec.customer_sample_ship     -- 顧客見本出庫
           - l_get_daily_data_rec.customer_sample_ship_b   -- 顧客見本出庫振戻
           + l_get_daily_data_rec.customer_support_ss      -- 顧客協賛見本出庫
           - l_get_daily_data_rec.customer_support_ss_b    -- 顧客協賛見本出庫振戻
           + l_get_daily_data_rec.ccm_sample_ship          -- 顧客広告宣伝費A自社商品
           - l_get_daily_data_rec.ccm_sample_ship_b        -- 顧客広告宣伝費A自社商品振戻
        ;
--
        -- 廃却出庫
        g_lot_rec_work_tab(gn_target_cnt).removed_goods
          := l_get_daily_data_rec.removed_goods            -- 廃却
           - l_get_daily_data_rec.removed_goods_b          -- 廃却振戻
        ;
--
        -- 倉替出庫
        g_lot_rec_work_tab(gn_target_cnt).change_ship
          := l_get_daily_data_rec.change_ship              -- 倉替出庫
           + l_get_daily_data_rec.others_ship              -- 入出庫＿その他出庫
           + l_get_daily_data_rec.factory_change           -- 工場倉替
           - l_get_daily_data_rec.factory_change_b         -- 工場倉替振戻
           + l_get_daily_data_rec.vd_supplement_ship       -- 消化VD補充出庫
        ;
--
        -- 工場返品
        g_lot_rec_work_tab(gn_target_cnt).factory_return
          := l_get_daily_data_rec.factory_return           -- 工場返品
           - l_get_daily_data_rec.factory_return_b         -- 工場返品振戻
        ;
--
        -- ロケーション移動
        g_lot_rec_work_tab(gn_target_cnt).location_move
          := l_get_daily_data_rec.location_decrease        -- ロケーション移動増
           - l_get_daily_data_rec.location_increase        -- ロケーション移動減
        ;
--
        -- 在庫調整
        g_lot_rec_work_tab(gn_target_cnt).inv_adjust
          := l_get_daily_data_rec.adjust_decrease          -- 在庫調整増
           - l_get_daily_data_rec.adjust_increase          -- 在庫調整減
        ;
--
        -- 帳簿在庫
        g_lot_rec_work_tab(gn_target_cnt).book_inventory_quantity
          := l_get_daily_data_rec.book_inventory_quantity; -- 帳簿在庫数
--
      END LOOP set_work_tbl_data_loop;
--
      -- カーソルクローズ
      CLOSE get_daily_data_cur;
--
    END LOOP get_daily_data_loop;
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
      -- カーソルクローズ
      IF ( get_manage_base_cur%ISOPEN ) THEN
        CLOSE get_manage_base_cur;
      END IF;
--
      IF ( get_daily_data_cur%ISOPEN ) THEN
        CLOSE get_manage_base_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END get_daily_data;
--
  /**********************************************************************************
   * Procedure Name   : proc_init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE proc_init(
    ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ           
   ,ov_retcode OUT VARCHAR2 -- リターン・コード             
   ,ov_errmsg  OUT VARCHAR2 -- ユーザー・エラー・メッセージ 
  )IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_init'; -- プログラム名
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
    -- *** ローカル変数 ***
    lv_manage_base_flag VARCHAR2(1);                                -- 管理元拠点フラグ
    lb_status           boolean;                                    -- 在庫会計期間ステータス
    lv_in_para_err      VARCHAR2(5000);                             -- 入力パラメータチェックエラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 変数初期化
    -- グローバル変数
    gt_org_code         := NULL; -- 在庫組織コード
    gt_org_id           := NULL; -- 在庫組織ID
    gd_proc_date        := NULL; -- 業務日付
    gv_proc_date_char   := NULL; -- 業務日付文字列
    gt_exe_type_meaning := NULL; -- 入力パラメータ.実行区分名称
    gd_target_date      := NULL; -- 入力パラメータ.年月日DATE型
    gt_base_code        := NULL; -- ログインユーザ所属拠点コード
    gt_base_name        := NULL; -- 入力パラメータ.拠点名
    gt_subinv_name      := NULL; -- 入力パラメータ.保管場所名
    gt_item_div_h       := NULL; -- プロファイル値：本社商品区分
    gt_inv_cl_char      := NULL; -- プロファイル値：在庫確定文字
    -- ローカル変数
    lv_manage_base_flag := NULL; -- 管理元拠点フラグ
    lb_status           := NULL; -- 在庫会計期間ステータス
    lv_in_para_err      := NULL; -- 入力パラメータチェックエラー
--
    --==============================================================
    -- 在庫組織コード取得
    --==============================================================
    gt_org_code := FND_PROFILE.VALUE( cv_xxcoi1_organization_code );
    IF ( gt_org_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcoi_short_name
                    ,iv_name         => cv_msg_xxcoi1_00005
                    ,iv_token_name1  => cv_tkn_pro_tok              -- プロファイル名
                    ,iv_token_value1 => cv_xxcoi1_organization_code
                   );
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- 在庫組織ID取得
    --==============================================================
    gt_org_id := xxcoi_common_pkg.get_organization_id(
                   iv_organization_code => gt_org_code
                 );
    IF ( gt_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcoi_short_name
                    ,iv_name         => cv_msg_xxcoi1_00006
                    ,iv_token_name1  => cv_tkn_org_code_tok -- 在庫組織コード
                    ,iv_token_value1 => gt_org_code
                   );
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- 業務日付取得
    --==============================================================
    gd_proc_date := xxccp_common_pkg2.get_process_date;
    IF ( gd_proc_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcoi_short_name
                    ,iv_name         => cv_msg_xxcoi1_00011
                   );
      RAISE global_process_expt;
    END IF;
    -- 文字列変換
    gv_proc_date_char := TO_CHAR( gd_proc_date, cv_yyyymmdd );
--
    --==============================================================
    -- 入力パラメータチェック
    --==============================================================
    BEGIN
      -- ---------------------------
      -- 実行区分チェック
      -- ---------------------------
      gt_exe_type_meaning := xxcoi_common_pkg.get_meaning(
                               iv_lookup_type => ct_lot_rep_output_type -- 参照タイプ名
                              ,iv_lookup_code => gt_exe_type            -- 参照タイプコード
                             );
--
      -- ---------------------------
      -- 対象日チェック
      -- ---------------------------
      -- NULL値チェック
      IF ( gt_exe_type = cv_exe_type_10 AND gv_target_date IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcoi_short_name
                      ,iv_name         => cv_msg_xxcoi1_10460
                     );
        RAISE in_para_expt;
      END IF;
--
      -- 月次で入力されている場合
      IF ( gt_exe_type = cv_exe_type_20 AND gv_target_date IS NOT NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcoi_short_name
                      ,iv_name         => cv_msg_xxcoi1_10461
                     );
        RAISE in_para_expt;
      END IF;
--
      IF ( gt_exe_type = cv_exe_type_10 ) THEN
        BEGIN
--
          -- 日付形式チェック
          gd_target_date := TO_DATE( gv_target_date, cv_yyyymmddhh24miss );
--
          -- 過去日チェック
          IF ( gd_proc_date < gd_target_date ) THEN
            RAISE old_date_expt;
          END IF;
--
        EXCEPTION
          -- 過去日チェックエラー
          WHEN old_date_expt THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcoi_short_name
                          ,iv_name         => cv_msg_xxcoi1_10463
                          ,iv_token_name1  => cv_tkn_target_date   -- 対象日
                          ,iv_token_value1 => gv_target_date
                          ,iv_token_name2  => cv_tkn_business_date -- 業務日付
                          ,iv_token_value2 => gv_proc_date_char
                         );
            RAISE in_para_expt;
          -- 型チェックエラー
          WHEN OTHERS THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcoi_short_name
                          ,iv_name         => cv_msg_xxcoi1_10462
                          ,iv_token_name1  => cv_tkn_target_date   -- 対象日
                          ,iv_token_value1 => gv_target_date
                         );
            RAISE in_para_expt;
        END;
      END IF;
--
      -- ---------------------------
      -- 対象月チェック
      -- ---------------------------
      -- NULL値チェック
      IF ( gt_exe_type = cv_exe_type_20 AND gv_target_month IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcoi_short_name
                      ,iv_name         => cv_msg_xxcoi1_10464
                     );
        RAISE in_para_expt;
      END IF;
--
      -- 日次で入力されている場合
      IF ( gt_exe_type = cv_exe_type_10 AND gv_target_month IS NOT NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcoi_short_name
                      ,iv_name         => cv_msg_xxcoi1_10465
                     );
        RAISE in_para_expt;
      END IF;
--
      IF ( gt_exe_type = cv_exe_type_20 ) THEN
        BEGIN
--
          -- 日付型チェック
          gd_target_date := TO_DATE( gv_target_month, cv_yyyymm );
--
          -- 過去日チェック
          IF ( gd_proc_date < gd_target_date ) THEN
            RAISE old_date_expt;
          END IF;
--
        EXCEPTION
          -- 過去日チェックエラー
          WHEN old_date_expt THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcoi_short_name
                          ,iv_name         => cv_msg_xxcoi1_10467
                          ,iv_token_name1  => cv_tkn_target_month  -- 対象日
                          ,iv_token_value1 => gv_target_month
                          ,iv_token_name2  => cv_tkn_business_date -- 業務日付
                          ,iv_token_value2 => gv_proc_date_char
                         );
            RAISE in_para_expt;
          -- 型チェックエラー
          WHEN OTHERS THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcoi_short_name
                          ,iv_name         => cv_msg_xxcoi1_10466
                          ,iv_token_name1  => cv_tkn_target_month -- 対象月
                          ,iv_token_value1 => gv_target_month
                         );
            RAISE in_para_expt;
        END;
      END IF;
--
      -- ---------------------------
      -- 拠点チェック
      -- ---------------------------
      -- 入力パラメータ.拠点がNULLの場合
      IF ( gt_login_base_code IS NULL ) THEN
--
        -- ログインユーザ所属拠点取得
        gt_base_code := xxcoi_common_pkg.get_base_code(
                          in_user_id     => cn_created_by -- ユーザID
                         ,id_target_date => gd_proc_date  -- 業務日付
                        );
        IF ( gt_base_code IS NULL ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcoi_short_name
                        ,iv_name         => cv_msg_xxcoi1_10116
                       );
          RAISE in_para_expt;
        END IF;
--
        -- 管理元拠点チェック
        SELECT CASE WHEN xca.customer_code = xca.management_base_code
                 THEN cv_management_chk_1
                 ELSE cv_management_chk_0
               END manage_base_flag                           -- 管理元拠点フラグ
        INTO   lv_manage_base_flag
        FROM   hz_cust_accounts    hca                        -- 顧客マスタ
              ,xxcmm_cust_accounts xca                        -- 顧客追加情報
        WHERE  xca.customer_code       = gt_base_code         -- ログインユーザ所属拠点
        AND    hca.customer_class_code = ct_cust_class_code_1 -- 顧客区分：拠点
        AND    hca.status              = ct_cust_status_a     -- ステータス：有効
        AND    hca.cust_account_id     = xca.customer_id
        ;
        -- フラグが0の場合エラー
        IF ( lv_manage_base_flag = cv_management_chk_0 ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcoi_short_name
                        ,iv_name         => cv_msg_xxcoi1_10468
                       );
          RAISE in_para_expt;
        END IF;
--
      END IF;
--
      -- 拠点名取得
      SELECT xlbiv.base_name base_name
      INTO   gt_base_name
      FROM   xxcos_login_base_info_v xlbiv
      WHERE  xlbiv.base_code = NVL( gt_login_base_code, gt_base_code ) -- 入力パラメータorログインユーザ所属拠点
      ;
--
      -- ---------------------------
      -- 保管場所名取得
      -- ---------------------------
      IF ( gt_subinventory_code IS NOT NULL ) THEN
        SELECT msi.description subinv_name
        INTO   gt_subinv_name
        FROM   mtl_secondary_inventories msi
             , xxcoi_base_info2_v        xbiv
        WHERE  msi.attribute7                          = xbiv.base_code
        AND    msi.attribute14                         = ct_warehouse_flag_y  -- 倉庫管理対象フラグ：Y
        AND    msi.organization_id                     = gt_org_id            -- 在庫組織ID
        AND    NVL(msi.disable_date, gd_proc_date + 1) > gd_proc_date         -- 有効日チェック
        AND    xbiv.focus_base_code                    = gt_login_base_code   -- 絞込み拠点
        AND    msi.secondary_inventory_name            = gt_subinventory_code -- 保管場所
        ;
      END IF;
--
    EXCEPTION
      WHEN in_para_expt THEN
        lv_in_para_err := lv_errmsg;
    END;
--
    --==============================================================
    -- 入力パラメータログ出力
    --==============================================================
    -- メッセージ取得
    lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application        => cv_xxcoi_short_name
                  ,iv_name               => cv_msg_xxcoi1_10459
                  ,iv_token_name1        => cv_tkn_exe_type                         -- 実行区分
                  ,iv_token_value1       => gt_exe_type
                  ,iv_token_name2        => cv_tkn_exe_type_name                    -- 実行区分名称
                  ,iv_token_value2       => gt_exe_type_meaning
                  ,iv_token_name3        => cv_tkn_target_date                      -- 対象日
                  ,iv_token_value3       => gv_target_date
                  ,iv_token_name4        => cv_tkn_target_month                     -- 対象月
                  ,iv_token_value4       => gv_target_month
                  ,iv_token_name5        => cv_tkn_base_code                        -- 拠点コード
                  ,iv_token_value5       => NVL( gt_login_base_code, gt_base_code )
                  ,iv_token_name6        => cv_tkn_base_name                        -- 拠点名
                  ,iv_token_value6       => gt_base_name 
                  ,iv_token_name7        => cv_tkn_subinv_code                      -- 保管場所コード
                  ,iv_token_value7       => gt_subinventory_code
                  ,iv_token_name8        => cv_tkn_subinv_name                      -- 保管場所名
                  ,iv_token_value8       => gt_subinv_name
                 );
--
    -- メッセージ出力(ログ)
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_errmsg
    );
--
    -- 空行出力(ログ)
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => ''
    );
--
    -- 入力パラメータチェックでエラーが発生した場合は、例外処理を実施
    IF ( lv_in_para_err IS NOT NULL ) THEN
      lv_errmsg := lv_in_para_err;
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- プロファイル値：本社商品区分取得
    --==============================================================
    gt_item_div_h := FND_PROFILE.VALUE( cv_xxcos1_item_div_h );
    IF ( gt_item_div_h IS NULL )THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcoi_short_name
                    ,iv_name         => cv_msg_xxcoi1_10469
                    ,iv_token_name1  => cv_tkn_pro_tok       -- プロファイル名
                    ,iv_token_value1 => cv_xxcos1_item_div_h
                   );
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- 在庫会計期間オープンチェック
    --==============================================================
    -- 月次の場合は、末日でチェックする
    IF ( gt_exe_type = cv_exe_type_20 ) THEN
      gd_target_date := LAST_DAY( gd_target_date );
    END IF;
--
    -- ---------------------------------
    -- 共通関数：在庫会計期間チェック
    -- ---------------------------------
    xxcoi_common_pkg.org_acct_period_chk(
      in_organization_id => gt_org_id      -- 在庫組織ID
     ,id_target_date     => gd_target_date -- 対象日
     ,ob_chk_result      => lb_status      -- ステータス
     ,ov_errbuf          => lv_errbuf      -- エラーメッセージ
     ,ov_retcode         => lv_retcode     -- リターン・コード(0:正常、2:エラー)
     ,ov_errmsg          => lv_errmsg      -- ユーザー・エラーメッセージ
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcoi_short_name
                    ,iv_name         => cv_msg_xxcoi1_00026
                    ,iv_token_name1  => cv_tkn_target_date                     -- 対象日
                    ,iv_token_value1 => TO_CHAR( gd_target_date, cv_yyyymmdd )
                   );
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- プロファイル値：在庫確定印字文字
    --==============================================================
    -- 会計期間がクローズの場合のみ取得
    IF ( lb_status = FALSE ) THEN
      gt_inv_cl_char := FND_PROFILE.VALUE( cv_xxcoi1_inv_cl_character );
      IF ( gt_inv_cl_char IS NULL )THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcoi_short_name
                      ,iv_name         => cv_msg_xxcoi1_10451
                      ,iv_token_name1  => cv_tkn_pro_tok             -- プロファイル名
                      ,iv_token_value1 => cv_xxcoi1_inv_cl_character
                     );
        RAISE global_process_expt;
      END IF;
    END IF;
--
  EXCEPTION
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
  END proc_init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ           
   ,ov_retcode OUT VARCHAR2 -- リターン・コード             
   ,ov_errmsg  OUT VARCHAR2 -- ユーザー・エラー・メッセージ 
  )IS
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
--
    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    proc_init(
      ov_errbuf  => lv_errbuf  -- エラー・メッセージ           
     ,ov_retcode => lv_retcode -- リターン・コード             
     ,ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ 
    );
    -- エラー処理
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- --------------------
    -- 日次の場合
    -- --------------------
    IF ( gt_exe_type = cv_exe_type_10 ) THEN
      -- ===============================
      -- ロット別受払（日次）データ取得(A-2)
      -- ===============================
      get_daily_data(
        ov_errbuf  => lv_errbuf  -- エラー・メッセージ           
       ,ov_retcode => lv_retcode -- リターン・コード             
       ,ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ 
      );
      -- エラー処理
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    -- --------------------
    -- 月次の場合
    -- --------------------
    ELSE
      -- ===============================
      -- ロット別受払（月次）データ取得(A-3)
      -- ===============================
      get_monthly_data(
        ov_errbuf  => lv_errbuf  -- エラー・メッセージ           
       ,ov_retcode => lv_retcode -- リターン・コード             
       ,ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ 
      );
      -- エラー処理
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    -- ===============================
    -- ワークテーブルデータ登録(A-4)
    -- ===============================
    ins_work_data(
      ov_errbuf  => lv_errbuf  -- エラー・メッセージ           
     ,ov_retcode => lv_retcode -- リターン・コード             
     ,ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ 
    );
    -- エラー処理
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- SVF起動(A-5)
    -- ===============================
    execute_svf(
      ov_errbuf  => lv_errbuf  -- エラー・メッセージ           
     ,ov_retcode => lv_retcode -- リターン・コード             
     ,ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ 
    );
    -- エラー処理
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 終了処理(A-6)
    -- ===============================
    proc_end(
      ov_errbuf  => lv_errbuf  -- エラー・メッセージ           
     ,ov_retcode => lv_retcode -- リターン・コード             
     ,ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ 
    );
--
    -- エラー処理
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
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
    errbuf               OUT VARCHAR2 -- エラーメッセージ 
   ,retcode              OUT VARCHAR2 -- エラーコード     
   ,iv_exe_type          IN  VARCHAR2 -- 実行区分
   ,iv_target_date       IN  VARCHAR2 -- 対象日
   ,iv_target_month      IN  VARCHAR2 -- 対象月
   ,iv_login_base_code   IN  VARCHAR2 -- 拠点
   ,iv_subinventory_code IN  VARCHAR2 -- 保管場所
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
       ov_retcode => lv_retcode
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
    -- 入力パラメータ退避
    gt_exe_type          := iv_exe_type;
    gv_target_date       := iv_target_date;
    gv_target_month      := iv_target_month;
    gt_login_base_code   := iv_login_base_code;
    gt_subinventory_code := iv_subinventory_code;
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      ov_errbuf  => lv_errbuf   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode => lv_retcode  -- リターン・コード             --# 固定 #
     ,ov_errmsg  => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
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
      -- エラー時件数セット
      gn_error_cnt  := 1;
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
    END IF;
--
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    -- 対象件数が0件の場合は、成功件数も0件にする
    IF ( gn_target_cnt = 0 ) THEN
      gn_normal_cnt := 0;
    END IF;
--
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
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSE
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
END XXCOI016A11R;
/
