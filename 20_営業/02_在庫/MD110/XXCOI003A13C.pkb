CREATE OR REPLACE PACKAGE BODY XXCOI003A13C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI003A13C(spec)
 * Description      : 保管場所転送取引データOIF更新（倉替情報）
 * MD.050           : 保管場所転送取引データOIF更新（倉替情報） MD050_COI_003_A13
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理 (A-1)
 *  get_kuragae_data       倉替データ抽出処理 (A-2)
 *  chk_kuragae_data       倉替データ妥当性チェック処理 (A-3)
 *  chk_ins_upd            追加／更新判定処理 (A-4)
 *  ins_storage_info_tab   入庫情報一時表追加処理 (A-5)
 *  upd_storage_info_tab   入庫情報一時表更新処理 (A-6)
 *  ins_kuragae_data       倉替データ追加処理 (A-7)
 *  upd_hht_inv_tab        HHT入出庫一時表更新処理 (A-8)
 *  del_hht_inv_tab        HHT入出庫一時表削除処理 (A-10)
 *  submain                メイン処理プロシージャ
 *                         エラーリスト表追加処理 (A-9)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                         終了処理 (A-11)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/11    1.0   K.Nakamura       新規作成
 *  2009/02/20    1.1   K.Nakamura       [障害COI_024] 百貨店HHTの入庫確認情報更新時、転送先倉庫コード設定対応
 *  2015/04/13    1.2   A.Uchida         [E_本稼動_13008]他拠点営業車の入出庫対応
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
  PRAGMA EXCEPTION_INIT(global_api_others_expt, -20000);
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  lock_expt                      EXCEPTION; -- ロック取得エラー
  no_data_expt                   EXCEPTION; -- 取得０件例外
  outside_base_code_expt         EXCEPTION; -- 倉替対象可否エラー（出庫側拠点コード）
  inside_base_code_expt          EXCEPTION; -- 倉替対象可否エラー（入庫側拠点コード）
  acct_period_close_expt         EXCEPTION; -- 在庫会計期間エラー
--
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );  -- ロック取得例外
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                    CONSTANT VARCHAR2(15)  := 'XXCOI003A13C'; -- パッケージ名
  cv_appl_short_name             CONSTANT VARCHAR2(10)  := 'XXCCP';        -- アドオン：共通・IF領域
  cv_application_short_name      CONSTANT VARCHAR2(10)  := 'XXCOI';        -- アプリケーション短縮名
  cv_flag_on                     CONSTANT VARCHAR2(1)   := 'Y';            -- フラグON
  cv_flag_off                    CONSTANT VARCHAR2(1)   := 'N';            -- フラグOFF
  cv_stock_uncheck_list_div_out  CONSTANT VARCHAR2(1)   := 'O';            -- 入庫未確認リスト対象区分 O：出庫側情報
  cv_stock_uncheck_list_div_in   CONSTANT VARCHAR2(1)   := 'I';            -- 入庫未確認リスト対象区分 I：入庫側情報
  cv_slip_type                   CONSTANT VARCHAR2(2)   := '20';           -- 伝票区分 20:拠点間倉替
  -- メッセージ
  cv_no_para_msg                 CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008'; -- コンカレント入力パラメータなしメッセージ
  cv_org_code_get_err_msg        CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00005'; -- 在庫組織コード取得エラーメッセージ
  cv_org_id_get_err_msg          CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00006'; -- 在庫組織ID取得エラーメッセージ
  cv_no_data_msg                 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00008'; -- 対象データ無しメッセージ
  cv_tran_type_name_get_err_msg  CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00022'; -- 取引タイプ名取得エラーメッセージ
  cv_tran_type_id_get_err_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00012'; -- 取引タイプID取得エラーメッセージ
  cv_data_name_get_err_msg       CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10027'; -- データ名称取得エラーメッセージ
  cv_hht_table_lock_err_msg      CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10055'; -- ロック取得エラーメッセージ（HHT入出庫一時表）
  cv_info_table_lock_err_msg     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10244'; -- ロック取得エラーメッセージ（入庫情報一時表）
  cv_dept_code_err_msg           CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10052'; -- 倉替対象可否エラーメッセージ
  cv_acct_period_close_err_msg   CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10231'; -- 在庫会計期間エラーメッセージ
  cv_key_info_msg                CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10342'; -- HHT入出庫データ用KEY情報
  -- 2015/04/27 Ver1.2 Add Start
  cv_lot_tran_temp_cre_error     CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10453'; -- ロット別取引TEMP登録エラーメッセージ
  -- 2015/04/27 Ver1.2 Add End
  -- トークン
  cv_tkn_pro                     CONSTANT VARCHAR2(20)  := 'PRO_TOK';              -- プロファイル名
  cv_tkn_org_code                CONSTANT VARCHAR2(20)  := 'ORG_CODE_TOK';         -- 在庫組織コード
  cv_tkn_tran_type               CONSTANT VARCHAR2(20)  := 'TRANSACTION_TYPE_TOK'; -- 取引タイプ名
  cv_tkn_lookup_type             CONSTANT VARCHAR2(20)  := 'LOOKUP_TYPE';          -- 参照タイプ
  cv_tkn_lookup_code             CONSTANT VARCHAR2(20)  := 'LOOKUP_CODE';          -- 参照コード
  cv_tkn_dept_code               CONSTANT VARCHAR2(20)  := 'DEPT_CODE';            -- 拠点コード（出庫側・入庫側）
  cv_tkn_invoice_date            CONSTANT VARCHAR2(20)  := 'INVOICE_DATE';         -- 伝票日付
  cv_tkn_base_code               CONSTANT VARCHAR2(20)  := 'BASE_CODE';            -- 拠点コード
  cv_tkn_record_type             CONSTANT VARCHAR2(20)  := 'RECORD_TYPE';          -- レコード種別
  cv_tkn_invoice_type            CONSTANT VARCHAR2(20)  := 'INVOICE_TYPE';         -- 伝票区分
  cv_tkn_dept_flag               CONSTANT VARCHAR2(20)  := 'DEPT_FLAG';            -- 百貨店フラグ
  cv_tkn_invoice_no              CONSTANT VARCHAR2(20)  := 'INVOICE_NO';           -- 伝票No
  cv_tkn_column_no               CONSTANT VARCHAR2(20)  := 'COLUMN_NO';            -- コラムNo
  cv_tkn_item_code               CONSTANT VARCHAR2(20)  := 'ITEM_CODE';            -- 品目コード
  -- 2015/04/27 Ver1.2 Add Start
  cv_tkn_name_err_msg           CONSTANT VARCHAR2(9)    := 'ERR_MSG';                   -- エラーメッセージ
  -- 2015/04/27 Ver1.2 Add End
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 倉替データレコード格納用
  TYPE gr_kuragae_data_rec IS RECORD(
      xhit_rowid                 rowid                                                  -- ROWID
    , invoice_no                 xxcoi_hht_inv_transactions.invoice_no%TYPE             -- 伝票No
    , transaction_id             xxcoi_hht_inv_transactions.transaction_id%TYPE         -- 入庫情報一時表ID
    , base_code                  xxcoi_hht_inv_transactions.base_code%TYPE              -- 拠点コード
    , record_type                xxcoi_hht_inv_transactions.record_type%TYPE            -- レコード種別
    , employee_num               xxcoi_hht_inv_transactions.employee_num%TYPE           -- 営業員コード
    , item_code                  xxcoi_hht_inv_transactions.item_code%TYPE              -- 品目コード
    , case_in_quantity           xxcoi_hht_inv_transactions.case_in_quantity%TYPE       -- 入数
    , case_quantity              xxcoi_hht_inv_transactions.case_quantity%TYPE          -- ケース数
    , quantity                   xxcoi_hht_inv_transactions.quantity%TYPE               -- 本数
    , total_quantity             xxcoi_hht_inv_transactions.total_quantity%TYPE         -- 総本数
    , inventory_item_id          xxcoi_hht_inv_transactions.inventory_item_id%TYPE      -- 品目ID
    , primary_uom_code           xxcoi_hht_inv_transactions.primary_uom_code%TYPE       -- 基準単位
    , invoice_date               xxcoi_hht_inv_transactions.invoice_date%TYPE           -- 伝票日付
    , invoice_type               xxcoi_hht_inv_transactions.invoice_type%TYPE           -- 伝票区分
    , department_flag            xxcoi_hht_inv_transactions.department_flag%TYPE        -- 百貨店フラグ
    , column_no                  xxcoi_hht_inv_transactions.column_no%TYPE              -- コラムNo
    , outside_subinv_code        xxcoi_hht_inv_transactions.outside_subinv_code%TYPE    -- 出庫側保管場所
    , inside_subinv_code         xxcoi_hht_inv_transactions.inside_subinv_code%TYPE     -- 入庫側保管場所
    , outside_code               xxcoi_hht_inv_transactions.outside_code%TYPE           -- 出庫側コード
    , inside_code                xxcoi_hht_inv_transactions.inside_code%TYPE            -- 入庫側コード
    , outside_base_code          xxcoi_hht_inv_transactions.outside_base_code%TYPE      -- 出庫側拠点コード
    , inside_base_code           xxcoi_hht_inv_transactions.inside_base_code%TYPE       -- 入庫側拠点コード
    , stock_uncheck_list_div     xxcoi_hht_inv_transactions.stock_uncheck_list_div%TYPE -- 入庫未確認リスト対象区分
    -- 2015/04/27 Ver1.2 Add Start
    , interface_date             xxcoi_hht_inv_transactions.interface_date%TYPE         -- 受信日時
    -- 2015/04/27 Ver1.2 Add End
  );
--
  TYPE gt_kuragae_data_ttype IS TABLE OF gr_kuragae_data_rec INDEX BY BINARY_INTEGER;
--
  -- 入庫情報一時表データレコード格納用
  TYPE gr_storage_info_rec IS RECORD(
      xsi_rowid                  rowid                                            -- ROWID
    , ship_case_qty              xxcoi_storage_information.ship_case_qty%TYPE     -- 出庫数量ケース数
    , ship_singly_qty            xxcoi_storage_information.ship_singly_qty%TYPE   -- 出庫数量バラ数
    , ship_summary_qty           xxcoi_storage_information.ship_summary_qty%TYPE  -- 出庫数量総バラ数
    , check_case_qty             xxcoi_storage_information.check_case_qty%TYPE    -- 確認数量ケース数
    , check_singly_qty           xxcoi_storage_information.check_singly_qty%TYPE  -- 確認数量バラ数
    , check_summary_qty          xxcoi_storage_information.check_summary_qty%TYPE -- 確認数量総バラ数
  );
--
  TYPE gt_storage_info_ttype IS TABLE OF gr_storage_info_rec INDEX BY BINARY_INTEGER;
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gt_org_id                      mtl_parameters.organization_id%TYPE;                 -- 在庫組織ID
  gt_data_name                   fnd_profile_option_values.profile_option_value%TYPE; -- HHTエラーリスト入出庫データ名称
  gt_tran_type_kuragae           mtl_transaction_types.transaction_type_id%TYPE;      -- 取引タイプID 倉替
  gt_tran_type_inout             mtl_transaction_types.transaction_type_id%TYPE;      -- 取引タイプID 入出庫
  gv_skip_flag                   VARCHAR2(1);                                         -- スキップ用フラグ
  gv_auto_flag                   VARCHAR2(1);                                         -- 自動入庫確認フラグ
  -- カウンタ
  gn_kuragae_data_loop_cnt       NUMBER; -- 倉替データループカウンタ
  gn_storage_info_loop_cnt       NUMBER; -- 入庫情報一時表データループカウンタ
  gn_storage_info_cnt            NUMBER; -- 入庫情報一時表件数カウンタ
  -- PL/SQL表
  gt_kuragae_data_tab            gt_kuragae_data_ttype;
  gt_storage_info_tab            gt_storage_info_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理 (A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT  VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT  VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg     OUT  VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- プロファイル
    cv_prf_org_code              CONSTANT VARCHAR2(30) := 'XXCOI1_ORGANIZATION_CODE'; -- 在庫組織コード
    cv_prf_data_name             CONSTANT VARCHAR2(30) := 'XXCOI1_HHT_ERR_DATA_NAME'; -- HHTエラーリスト用入出庫データ名
    -- 参照タイプ
    cv_tran_type                 CONSTANT VARCHAR2(30) := 'XXCOI1_TRANSACTION_TYPE_NAME'; -- ユーザー定義取引タイプ名称
    -- 参照コード
    cv_tran_type_kuragae         CONSTANT VARCHAR2(2)  := '20'; -- 取引タイプ コード 倉替
    cv_tran_type_inout           CONSTANT VARCHAR2(2)  := '10'; -- 取引タイプ コード 入出庫
--
    -- *** ローカル変数 ***
    lt_org_code                  mtl_parameters.organization_code%TYPE;            -- 在庫組織コード
    lt_tran_type_kuragae         mtl_transaction_types.transaction_type_name%TYPE; -- 取引タイプ名 倉替
    lt_tran_type_inout           mtl_transaction_types.transaction_type_name%TYPE; -- 取引タイプ名 入出庫
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
    --==============================================================
    -- コンカレント入力パラメータなしログ出力
    --==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application => cv_appl_short_name
                    , iv_name        => cv_no_para_msg
                  );
    -- メッセージ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
    -- ===============================
    -- プロファイル取得：在庫組織コード
    -- ===============================
    lt_org_code := fnd_profile.value( cv_prf_org_code );
    -- プロファイルが取得できない場合
    IF ( lt_org_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_org_code_get_err_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_org_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 在庫組織ID取得
    -- ===============================
    gt_org_id := xxcoi_common_pkg.get_organization_id( lt_org_code );
    -- 共通関数の戻り値がNULLの場合
    IF ( gt_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_org_id_get_err_msg
                     , iv_token_name1  => cv_tkn_org_code
                     , iv_token_value1 => lt_org_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- プロファイル取得：HHTエラーリスト入出庫データ名称
    -- ===============================
    gt_data_name := fnd_profile.value( cv_prf_data_name );
    -- プロファイルが取得できない場合
    IF ( gt_data_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_data_name_get_err_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_data_name
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 取引タイプ名取得（倉替）
    -- ===============================
    lt_tran_type_kuragae := xxcoi_common_pkg.get_meaning( cv_tran_type, cv_tran_type_kuragae );
    -- 共通関数の戻り値がNULLの場合
    IF ( lt_tran_type_kuragae IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_name_get_err_msg
                     , iv_token_name1  => cv_tkn_lookup_type
                     , iv_token_value1 => cv_tran_type
                     , iv_token_name2  => cv_tkn_lookup_code
                     , iv_token_value2 => cv_tran_type_kuragae
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 取引タイプID取得（倉替）
    -- ===============================
    gt_tran_type_kuragae := xxcoi_common_pkg.get_transaction_type_id( lt_tran_type_kuragae );
    -- 共通関数の戻り値がNULLの場合
    IF ( gt_tran_type_kuragae IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_id_get_err_msg
                     , iv_token_name1  => cv_tkn_tran_type
                     , iv_token_value1 => lt_tran_type_kuragae
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 取引タイプ名取得（入出庫）
    -- ===============================
    lt_tran_type_inout := xxcoi_common_pkg.get_meaning( cv_tran_type, cv_tran_type_inout );
    -- 共通関数の戻り値がNULLの場合
    IF ( lt_tran_type_inout IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_name_get_err_msg
                     , iv_token_name1  => cv_tkn_lookup_type
                     , iv_token_value1 => cv_tran_type
                     , iv_token_name2  => cv_tkn_lookup_code
                     , iv_token_value2 => cv_tran_type_inout
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 取引タイプID取得（入出庫）
    -- ===============================
    gt_tran_type_inout := xxcoi_common_pkg.get_transaction_type_id( lt_tran_type_inout );
    -- 共通関数の戻り値がNULLの場合
    IF ( gt_tran_type_inout IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_id_get_err_msg
                     , iv_token_name1  => cv_tkn_tran_type
                     , iv_token_value1 => lt_tran_type_inout
                   );
      lv_errbuf := lv_errmsg;
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
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
   * Procedure Name   : get_kuragae_data
   * Description      : 倉替データ抽出処理 (A-2)
   ***********************************************************************************/
  PROCEDURE get_kuragae_data(
    ov_errbuf     OUT  VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT  VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg     OUT  VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_kuragae_data'; -- プログラム名
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
    cv_hht_program_div_2         CONSTANT VARCHAR2(1) := '2'; -- 入出庫ジャーナル処理区分 2:拠点間倉替
    cv_status_pre                CONSTANT NUMBER      := 0;   -- 処理ステータス 0:未処理
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
    -- 倉替データ抽出
    CURSOR get_data_cur
    IS
      SELECT
             xhit.rowid                  AS xhit_rowid             -- ROWID
           , xhit.invoice_no             AS invoice_no             -- 伝票No
           , xhit.transaction_id         AS transaction_id         -- 入庫情報一時表ID
           , xhit.base_code              AS base_code              -- 拠点コード
           , xhit.record_type            AS record_type            -- レコード種別
           , xhit.employee_num           AS employee_num           -- 営業員コード
           , xhit.item_code              AS item_code              -- 品目コード
           , xhit.case_in_quantity       AS case_in_quantity       -- 入数
           , xhit.case_quantity          AS case_quantity          -- ケース数
           , xhit.quantity               AS quantity               -- 本数
           , xhit.total_quantity         AS total_quantity         -- 総本数
           , xhit.inventory_item_id      AS inventory_item_id      -- 品目ID
           , xhit.primary_uom_code       AS primary_uom_code       -- 基準単位
           , xhit.invoice_date           AS invoice_date           -- 伝票日付
           , xhit.invoice_type           AS invoice_type           -- 伝票区分
           , xhit.department_flag        AS department_flag        -- 百貨店フラグ
           , xhit.column_no              AS column_no              -- コラムNo
           , xhit.outside_subinv_code    AS outside_subinv_code    -- 出庫側保管場所
           , xhit.inside_subinv_code     AS inside_subinv_code     -- 入庫側保管場所
           , xhit.outside_code           AS outside_code           -- 出庫側コード
           , xhit.inside_code            AS inside_code            -- 入庫側コード
           , xhit.outside_base_code      AS outside_base_code      -- 出庫側拠点コード
           , xhit.inside_base_code       AS inside_base_code       -- 入庫側拠点コード
           , xhit.stock_uncheck_list_div AS stock_uncheck_list_div -- 入庫未確認リスト対象区分
           -- 2015/04/27 Ver1.2 Add Start
           , xhit.interface_date         AS interface_date         -- 受信日時
           -- 2015/04/27 Ver1.2 Add End
      FROM   xxcoi_hht_inv_transactions  xhit                      -- HHT入出庫一時表
      WHERE  xhit.status          = cv_status_pre                  -- 処理ステータス
      AND    xhit.hht_program_div = cv_hht_program_div_2           -- 入出庫ジャーナル処理区分
      ORDER BY 
             xhit.inside_code                                      -- 顧客コード
           , xhit.invoice_no                                       -- 伝票No
      FOR UPDATE OF xhit.status NOWAIT
    ;
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
    -- カーソルオープン
    OPEN get_data_cur;
--
    -- レコード読み込み
    FETCH get_data_cur BULK COLLECT INTO gt_kuragae_data_tab;
--
    -- 対象件数取得
    gn_target_cnt := gt_kuragae_data_tab.COUNT;
--
    -- カーソルクローズ
    CLOSE get_data_cur;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- ロック取得エラー
    WHEN lock_expt THEN
      -- カーソルがOPENしている場合
      IF ( get_data_cur%ISOPEN ) THEN
        CLOSE get_data_cur;
      END IF;
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_hht_table_lock_err_msg
                     );
      lv_errbuf   := lv_errmsg;
      ov_errmsg   := lv_errmsg;
      ov_errbuf   := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルがOPENしている場合
      IF ( get_data_cur%ISOPEN ) THEN
        CLOSE get_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルがOPENしている場合
      IF ( get_data_cur%ISOPEN ) THEN
        CLOSE get_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルがOPENしている場合
      IF ( get_data_cur%ISOPEN ) THEN
        CLOSE get_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_kuragae_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_kuragae_data
   * Description      : 倉替データ妥当性チェック処理 (A-3)
   ***********************************************************************************/
  PROCEDURE chk_kuragae_data(
    gn_kuragae_data_loop_cnt IN   NUMBER,    -- 倉替データループカウンタ
    ov_errbuf                OUT  VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT  VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg                OUT  VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_kuragae_data'; -- プログラム名
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
    cv_customer_class_code       CONSTANT VARCHAR2(1) := '1'; -- 顧客区分 1:拠点
    cv_kuragae_div               CONSTANT VARCHAR2(1) := '0'; -- 倉替対象可否区分   0:倉替対象否拠点
    cv_auto_flag_off             CONSTANT VARCHAR2(1) := 'N'; -- 自動入庫確認フラグ N:自動入庫確認対象外
--
    -- *** ローカル変数 ***
    lt_outside_attribute6        hz_cust_accounts.attribute6%TYPE; -- 倉替対象可否区分（出庫側拠点コード）
    lt_inside_attribute6         hz_cust_accounts.attribute6%TYPE; -- 倉替対象可否区分（入庫側拠点コード）
    lb_chk_result                BOOLEAN;                          -- 在庫会計期間オープン判定
    lv_key_info                  VARCHAR2(5000);                   -- 保管場所転送取引データOIF更新（倉替情報）用KEY情報
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
    -- 変数初期化
    lt_outside_attribute6 := NULL;
    lt_inside_attribute6  := NULL;
    gv_auto_flag          := NULL;
    lb_chk_result         := TRUE;
--
    -- 出庫側拠点コードと入庫側拠点コードが不一致の場合、倉替と判断し妥当性チェック
    IF ( gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).outside_base_code
      <> gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).inside_base_code ) THEN
--
      SELECT hca.attribute6 AS attribute6                                                                -- 倉替対象可否区分
      INTO   lt_outside_attribute6
      FROM   hz_cust_accounts hca                                                                        -- 顧客アカウント
      WHERE  hca.account_number      = gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).outside_base_code -- 顧客コード = 出庫側拠点コード
      AND    hca.customer_class_code = cv_customer_class_code                                            -- 顧客区分
      ;
--
      -- （出庫側拠点コードが）倉替対象否拠点に設定されている場合
      IF ( lt_outside_attribute6 = cv_kuragae_div ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_dept_code_err_msg
                       , iv_token_name1  => cv_tkn_dept_code
                       , iv_token_value1 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).outside_base_code
                     );
        lv_errbuf := lv_errmsg;
        RAISE outside_base_code_expt;
      END IF;
--
      SELECT hca.attribute6 AS attribute6                                                                -- 倉替対象可否区分
      INTO   lt_inside_attribute6
      FROM   hz_cust_accounts hca                                                                        -- 顧客アカウント
      WHERE  hca.account_number      = gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).inside_base_code  -- 顧客コード = 入庫側拠点コード
      AND    hca.customer_class_code = cv_customer_class_code                                            -- 顧客区分
      ;
--
      -- （入庫側拠点コードが）倉替対象否拠点に設定されている場合
      IF ( lt_inside_attribute6 = cv_kuragae_div ) THEN
        lv_errmsg:= xxccp_common_pkg.get_msg(
                        iv_application  => cv_application_short_name
                      , iv_name         => cv_dept_code_err_msg
                      , iv_token_name1  => cv_tkn_dept_code
                      , iv_token_value1 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).inside_base_code
                    );
        lv_errbuf := lv_errmsg;
        RAISE inside_base_code_expt;
      END IF;
--
    END IF;
--
    -- 自動入庫確認フラグの確認
    SELECT NVL( msi.attribute11, cv_auto_flag_off ) AS attribute11                                           -- 自動入庫確認フラグ
    INTO   gv_auto_flag
    FROM   mtl_secondary_inventories msi                                                                     -- 保管場所マスタ
    WHERE  msi.secondary_inventory_name = gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).inside_subinv_code -- 保管場所コード = 入庫側保管場所
    AND    msi.organization_id          = gt_org_id                                                          -- 在庫組織ID
    ;
--
    -- 在庫会計期間チェック
    xxcoi_common_pkg.org_acct_period_chk(
        in_organization_id => gt_org_id                                                    -- 在庫組織ID
      , id_target_date     => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_date -- 対象日
      , ob_chk_result      => lb_chk_result                                                -- チェック結果
      , ov_errbuf          => lv_errbuf                                                    -- エラーメッセージ
      , ov_retcode         => lv_retcode                                                   -- リターン・コード
      , ov_errmsg          => lv_errmsg                                                    -- ユーザー・エラーメッセージ
    );
--
    -- 戻り値のステータスがFALSEの場合
    IF ( lb_chk_result = FALSE ) THEN
      lv_errmsg:= xxccp_common_pkg.get_msg(
                      iv_application  => cv_application_short_name
                    , iv_name         => cv_acct_period_close_err_msg
                    , iv_token_name1  => cv_tkn_invoice_date
                    , iv_token_value1 => TO_CHAR( gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_date, 'YYYYMMDD' )
                  );
      lv_errbuf := lv_errmsg;
      RAISE acct_period_close_expt;
    END IF;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
    -- 倉替対象可否エラー（出庫側拠点コード）
    WHEN outside_base_code_expt THEN
      -- KEY情報出力
      lv_key_info := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_key_info_msg
                       , iv_token_name1  => cv_tkn_base_code
                       , iv_token_value1 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).base_code
                       , iv_token_name2  => cv_tkn_record_type
                       , iv_token_value2 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).record_type
                       , iv_token_name3  => cv_tkn_invoice_type
                       , iv_token_value3 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_type
                       , iv_token_name4  => cv_tkn_dept_flag
                       , iv_token_value4 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).department_flag
                       , iv_token_name5  => cv_tkn_invoice_no
                       , iv_token_value5 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_no
                       , iv_token_name6  => cv_tkn_column_no
                       , iv_token_value6 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).column_no
                       , iv_token_name7  => cv_tkn_item_code
                       , iv_token_value7 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).item_code
                     );
      -- メッセージ出力
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_key_info || lv_errmsg
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_key_info || lv_errbuf
      );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_warn;
    -- 倉替対象可否エラー（入庫側拠点コード）
    WHEN inside_base_code_expt THEN
      -- KEY情報出力
      lv_key_info := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_key_info_msg
                       , iv_token_name1  => cv_tkn_base_code
                       , iv_token_value1 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).base_code
                       , iv_token_name2  => cv_tkn_record_type
                       , iv_token_value2 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).record_type
                       , iv_token_name3  => cv_tkn_invoice_type
                       , iv_token_value3 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_type
                       , iv_token_name4  => cv_tkn_dept_flag
                       , iv_token_value4 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).department_flag
                       , iv_token_name5  => cv_tkn_invoice_no
                       , iv_token_value5 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_no
                       , iv_token_name6  => cv_tkn_column_no
                       , iv_token_value6 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).column_no
                       , iv_token_name7  => cv_tkn_item_code
                       , iv_token_value7 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).item_code
                     );
      -- メッセージ出力
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_key_info || lv_errmsg
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_key_info || lv_errbuf
      );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_warn;
    -- 在庫会計期間エラー
    WHEN acct_period_close_expt THEN
      -- KEY情報出力
      lv_key_info := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_key_info_msg
                       , iv_token_name1  => cv_tkn_base_code
                       , iv_token_value1 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).base_code
                       , iv_token_name2  => cv_tkn_record_type
                       , iv_token_value2 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).record_type
                       , iv_token_name3  => cv_tkn_invoice_type
                       , iv_token_value3 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_type
                       , iv_token_name4  => cv_tkn_dept_flag
                       , iv_token_value4 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).department_flag
                       , iv_token_name5  => cv_tkn_invoice_no
                       , iv_token_value5 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_no
                       , iv_token_name6  => cv_tkn_column_no
                       , iv_token_value6 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).column_no
                       , iv_token_name7  => cv_tkn_item_code
                       , iv_token_value7 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).item_code
                     );
      -- メッセージ出力
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_key_info || lv_errmsg
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_key_info || lv_errbuf
      );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_warn;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END chk_kuragae_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_ins_upd
   * Description      : 追加／更新判定処理 (A-4)
   ***********************************************************************************/
  PROCEDURE chk_ins_upd(
    gn_kuragae_data_loop_cnt IN   NUMBER,    -- 倉替データループカウンタ
    ov_errbuf                OUT  VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT  VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg                OUT  VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_ins_upd'; -- プログラム名
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
    cv_department_flag_5         CONSTANT VARCHAR2(2) := '5'; -- 百貨店フラグ 5
--
    -- *** ローカル変数 ***
    lv_key_info                  VARCHAR2(5000);              -- 保管場所転送取引データOIF更新（倉替情報）用KEY情報
--
    -- *** ローカル・カーソル ***
    -- 入庫情報一時表データ抽出
    CURSOR chk_ins_upd_cur
    IS
      SELECT
             xsi.rowid                 AS xsi_rowid                                                  -- ROWID
           , xsi.ship_case_qty         AS ship_case_qty                                              -- 出庫数量ケース数
           , xsi.ship_singly_qty       AS ship_singly_qty                                            -- 出庫数量バラ数
           , xsi.ship_summary_qty      AS ship_summary_qty                                           -- 出庫数量総バラ数
           , xsi.check_case_qty        AS check_case_qty                                             -- 確認数量ケース数
           , xsi.check_singly_qty      AS check_singly_qty                                           -- 確認数量バラ数
           , xsi.check_summary_qty     AS check_summary_qty                                          -- 確認数量総バラ数
      FROM   xxcoi_storage_information xsi                                                           -- 入庫情報一時表
      WHERE
             xsi.slip_num         = gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_no       -- 伝票No
      AND    xsi.slip_date        = gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_date     -- 伝票日付
      AND    xsi.ship_base_code   = CASE WHEN ( gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).department_flag = cv_department_flag_5 )
                                         THEN gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).outside_code
                                         ELSE gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).outside_base_code
                                         END                                                         -- 出庫側拠点コード
      AND    xsi.base_code        = gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).inside_base_code -- 拠点コード
      AND    xsi.parent_item_code = gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).item_code        -- 親品目コード
      AND    xsi.slip_type        = cv_slip_type                                                     -- 伝票区分
      FOR UPDATE OF xsi.slip_num NOWAIT
    ;
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
    -- 入庫情報一時表件数カウンタ初期化
    gn_storage_info_cnt := 0;
--
    -- カーソルオープン
    OPEN chk_ins_upd_cur;
--
    -- レコード読み込み
    FETCH chk_ins_upd_cur BULK COLLECT INTO gt_storage_info_tab;
--
    -- 入庫情報一時表件数カウントセット
    gn_storage_info_cnt := gt_storage_info_tab.COUNT;
--
    -- カーソルクローズ
    CLOSE chk_ins_upd_cur;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
    -- ロック取得エラー
    WHEN lock_expt THEN
      -- カーソルがOPENしている場合
      IF ( chk_ins_upd_cur%ISOPEN ) THEN
        CLOSE chk_ins_upd_cur;
      END IF;
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_info_table_lock_err_msg
                     );
      -- KEY情報出力
      lv_errbuf   := lv_errmsg;
      lv_key_info := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_key_info_msg
                       , iv_token_name1  => cv_tkn_base_code
                       , iv_token_value1 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).base_code
                       , iv_token_name2  => cv_tkn_record_type
                       , iv_token_value2 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).record_type
                       , iv_token_name3  => cv_tkn_invoice_type
                       , iv_token_value3 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_type
                       , iv_token_name4  => cv_tkn_dept_flag
                       , iv_token_value4 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).department_flag
                       , iv_token_name5  => cv_tkn_invoice_no
                       , iv_token_value5 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_no
                       , iv_token_name6  => cv_tkn_column_no
                       , iv_token_value6 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).column_no
                       , iv_token_name7  => cv_tkn_item_code
                       , iv_token_value7 => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).item_code
                     );
      -- メッセージ出力
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_key_info || CHR(10) || lv_errmsg
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_key_info || CHR(10) || lv_errbuf
      );
      ov_errmsg   := lv_errmsg;
      ov_errbuf   := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  := cv_status_warn;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルがOPENしている場合
      IF ( chk_ins_upd_cur%ISOPEN ) THEN
        CLOSE chk_ins_upd_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルがOPENしている場合
      IF ( chk_ins_upd_cur%ISOPEN ) THEN
        CLOSE chk_ins_upd_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルがOPENしている場合
      IF ( chk_ins_upd_cur%ISOPEN ) THEN
        CLOSE chk_ins_upd_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END chk_ins_upd;
--
  /**********************************************************************************
   * Procedure Name   : ins_storage_info_tab
   * Description      : 入庫情報一時表追加処理 (A-5)
   ***********************************************************************************/
  PROCEDURE ins_storage_info_tab(
    gn_kuragae_data_loop_cnt IN   NUMBER,    -- 倉替データループカウンタ
    ov_errbuf                OUT  VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT  VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg                OUT  VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_storage_info_tab'; -- プログラム名
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
    cv_zero                      CONSTANT VARCHAR2(1) := '0';  -- 固定値
--
    -- *** ローカル変数 ***
    -- 2015/04/27 Ver1.2 Add Start
    ln_cnt                NUMBER;
    lt_wh_flg             mtl_secondary_inventories.attribute14%TYPE;          -- 倉庫管理対象区分
    ln_lot_tran_temp_id   xxcoi_lot_transactions_temp.transaction_id%TYPE;     -- ロット別取引TEMPID
    ln_storage_info_id    xxcoi_storage_information.transaction_id%TYPE;       -- 入庫情報一時表ID
    -- 2015/04/27 Ver1.2 Add End
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
    -- 出庫側情報の場合の入庫情報一時表登録
    IF ( gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).stock_uncheck_list_div = cv_stock_uncheck_list_div_out ) THEN
      -- 2015/04/27 Ver1.2 Add Start
      -- 同時に登録されている、「倉庫→営業車」、「営業車→倉庫」を検索
      ln_cnt := 0;
      --
      SELECT COUNT(1)
      INTO   ln_cnt
      FROM   xxcoi_hht_inv_transactions   xhit
      WHERE  ((xhit.invoice_type   =  '1'
        AND    xhit.outside_subinv_code = gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).inside_subinv_code)
        OR    (xhit.invoice_type   =  '2'
        AND    xhit.inside_subinv_code  = gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).outside_subinv_code))
      AND    xhit.item_code      =  gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).item_code
      AND    xhit.case_quantity  =  gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).case_quantity
      AND    xhit.quantity       =  gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).quantity
      AND    xhit.invoice_date   =  gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_date
      AND    xhit.interface_date =  gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).interface_date
      ;
      -- 2015/04/27 Ver1.2 Add End
--
      INSERT INTO xxcoi_storage_information(
          transaction_id                                                                       -- 取引ID
        , base_code                                                                            -- 入庫拠点コード
        , warehouse_code                                                                       -- 倉庫コード
        , slip_date                                                                            -- 伝票日付
        , slip_num                                                                             -- 伝票No
        , req_status                                                                           -- 出庫依頼ステータス
        , parent_item_code                                                                     -- 親品目コード
        , item_code                                                                            -- 子品目コード
        , case_in_qty                                                                          -- 入数
        , ship_case_qty                                                                        -- 出庫数量ケース数
        , ship_singly_qty                                                                      -- 出庫数量バラ数
        , ship_summary_qty                                                                     -- 出庫数量総バラ数
        , ship_warehouse_code                                                                  -- 転送先倉庫コード
        , check_warehouse_code                                                                 -- 確認倉庫コード
        , check_case_qty                                                                       -- 確認数量ケース数
        , check_singly_qty                                                                     -- 確認数量バラ数
        , check_summary_qty                                                                    -- 確認数量総バラ数
        , material_transaction_unset_qty                                                       -- 資材取引未連携数量
        , slip_type                                                                            -- 伝票区分
        , ship_base_code                                                                       -- 出庫拠点コード
        , taste_term                                                                           -- 賞味期限
        , difference_summary_code                                                              -- 工場固有記号
        , summary_data_flag                                                                    -- サマリーデータフラグ
        , store_check_flag                                                                     -- 入庫確認フラグ
        , material_transaction_set_flag                                                        -- 資材取引連携済フラグ
        , auto_store_check_flag                                                                -- 自動入庫確認フラグ
        , created_by                                                                           -- 作成者
        , creation_date                                                                        -- 作成日
        , last_updated_by                                                                      -- 最終更新者
        , last_update_date                                                                     -- 最終更新日
        , last_update_login                                                                    -- 最終更新ログイン
        , request_id                                                                           -- 要求ID
        , program_application_id                                                               -- プログラムアプリケーションID
        , program_id                                                                           -- プログラムID
        , program_update_date                                                                  -- プログラム更新日
      )
      VALUES(
          xxcoi_storage_information_s01.NEXTVAL                                                -- 取引ID(シーケンス)
        , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).inside_base_code                     -- 入庫拠点コード
        , SUBSTRB( gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).inside_subinv_code, 6, 2 )  -- 倉庫コード
        , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_date                         -- 伝票日付
        , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_no                           -- 伝票No
        , NULL                                                                                 -- 出庫依頼ステータス
        , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).item_code                            -- 親品目コード
        , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).item_code                            -- 子品目コード
        , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).case_in_quantity                     -- 入数
        , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).case_quantity                        -- 出庫数量ケース数
        , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).quantity                             -- 出庫数量バラ数
        , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).total_quantity                       -- 出庫数量総バラ数
        , NULL                                                                                 -- 転送先倉庫コード
        , SUBSTRB( gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).inside_subinv_code, 6, 2 )  -- 確認倉庫コード
        , cv_zero                                                                              -- 確認数量ケース数
        , cv_zero                                                                              -- 確認数量バラ数
        , cv_zero                                                                              -- 確認数量総バラ数
        , cv_zero                                                                              -- 資材取引未連携数量
        , cv_slip_type                                                                         -- 伝票区分
        , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).outside_base_code                    -- 出庫拠点コード
        , NULL                                                                                 -- 賞味期限
        , NULL                                                                                 -- 工場固有記号
        , cv_flag_on                                                                           -- サマリーデータフラグ
        -- 2015/04/27 Ver1.2 Mod Start
--        , cv_flag_off                                                                          -- 入庫確認フラグ
        , DECODE(ln_cnt
                ,0
                ,cv_flag_off
                ,cv_flag_on  )                                                                 -- 入庫確認フラグ
        -- 2015/04/27 Ver1.2 Mod End
        , cv_flag_off                                                                          -- 資材取引連携済フラグ
        , gv_auto_flag                                                                         -- 自動入庫確認フラグ
        , cn_created_by                                                                        -- 作成者
        , cd_creation_date                                                                     -- 作成日
        , cn_last_updated_by                                                                   -- 最終更新者
        , cd_last_update_date                                                                  -- 最終更新日
        , cn_last_update_login                                                                 -- 最終更新ログイン
        , cn_request_id                                                                        -- 要求ID
        , cn_program_application_id                                                            -- プログラムアプリケーションID
        , cn_program_id                                                                        -- プログラムID
        , cd_program_update_date                                                               -- プログラム更新日
      -- 2015/04/27 Ver1.2 Mod Start
--      );
      )
      RETURNING transaction_id
      INTO      ln_storage_info_id;
      -- 2015/04/27 Ver1.2 Mod End
--
      -- 2015/04/27 Ver1.2 Add Start
      IF ln_cnt > 0 THEN
        BEGIN
          -- 入庫側倉庫の倉庫管理区分を取得
          SELECT msi.attribute14 AS wh_flg
          INTO   lt_wh_flg
          FROM   mtl_secondary_inventories   msi
          WHERE  msi.attribute1               IN ('1','4')
          AND    msi.attribute7               = gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).inside_base_code
          AND    msi.secondary_inventory_name = gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).inside_subinv_code
          AND    msi.organization_id          = gt_org_id
          AND    NVL(msi.disable_date,gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_date+1)
                                              > gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_date
          ;
        EXCEPTION
          WHEN OTHERS THEN
            lt_wh_flg := NULL;
        END;
--
        IF lt_wh_flg = cv_flag_on THEN
          -- 共通関数：ロット別取引TEMP作成 実行
          xxcoi_common_pkg.cre_lot_trx_temp(
             in_trx_set_id       => NULL
            ,iv_parent_item_code => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).item_code
            ,iv_child_item_code  => NULL
            ,iv_lot              => NULL
            ,iv_diff_sum_code    => NULL
            ,iv_trx_type_code    => '20'
            ,id_trx_date         => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_date
            ,iv_slip_num         => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_no
            ,in_case_in_qty      => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).case_in_quantity
            ,in_case_qty         => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).case_quantity
            ,in_singly_qty       => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).quantity
            ,in_summary_qty      => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).total_quantity
            ,iv_base_code        => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).inside_base_code
            ,iv_subinv_code      => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).inside_subinv_code
            ,iv_tran_subinv_code => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).outside_subinv_code
            ,iv_tran_loc_code    => NULL
            ,iv_inout_code       => '21'
            ,iv_source_code      => cv_pkg_name
            ,iv_relation_key     => ln_storage_info_id
            ,on_trx_id           => ln_lot_tran_temp_id
            ,ov_errbuf           => lv_errbuf
            ,ov_retcode          => lv_retcode
            ,ov_errmsg           => lv_errmsg
            );
--
          -- 共通関数異常終了時
          IF ( lv_retcode <> cv_status_normal ) THEN
            -- エラーメッセージの取得
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application_short_name
                          ,iv_name         => cv_lot_tran_temp_cre_error
                          ,iv_token_name1  => cv_tkn_name_err_msg
                          ,iv_token_value1 => lv_errbuf
                          );
            RAISE global_api_expt;
          END IF;
        END IF;
      END IF;
      -- 2015/04/27 Ver1.2 Add End
    -- 百貨店HHT入庫側情報の場合の入庫情報一時表登録
    ELSIF ( gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).stock_uncheck_list_div = cv_stock_uncheck_list_div_in ) THEN
--
      INSERT INTO xxcoi_storage_information(
          transaction_id                                                                       -- 取引ID
        , base_code                                                                            -- 入庫拠点コード
        , warehouse_code                                                                       -- 倉庫コード
        , slip_date                                                                            -- 伝票日付
        , slip_num                                                                             -- 伝票No
        , req_status                                                                           -- 出庫依頼ステータス
        , parent_item_code                                                                     -- 親品目コード
        , item_code                                                                            -- 子品目コード
        , case_in_qty                                                                          -- 入数
        , ship_case_qty                                                                        -- 出庫数量ケース数
        , ship_singly_qty                                                                      -- 出庫数量バラ数
        , ship_summary_qty                                                                     -- 出庫数量総バラ数
        , ship_warehouse_code                                                                  -- 転送先倉庫コード
        , check_warehouse_code                                                                 -- 確認倉庫コード
        , check_case_qty                                                                       -- 確認数量ケース数
        , check_singly_qty                                                                     -- 確認数量バラ数
        , check_summary_qty                                                                    -- 確認数量総バラ数
        , material_transaction_unset_qty                                                       -- 資材取引未連携数量
        , slip_type                                                                            -- 伝票区分
        , ship_base_code                                                                       -- 出庫拠点コード
        , taste_term                                                                           -- 賞味期限
        , difference_summary_code                                                              -- 工場固有記号
        , summary_data_flag                                                                    -- サマリーデータフラグ
        , store_check_flag                                                                     -- 入庫確認フラグ
        , material_transaction_set_flag                                                        -- 資材取引連携済フラグ
        , auto_store_check_flag                                                                -- 自動入庫確認フラグ
        , created_by                                                                           -- 作成者
        , creation_date                                                                        -- 作成日
        , last_updated_by                                                                      -- 最終更新者
        , last_update_date                                                                     -- 最終更新日
        , last_update_login                                                                    -- 最終更新ログイン
        , request_id                                                                           -- 要求ID
        , program_application_id                                                               -- プログラムアプリケーションID
        , program_id                                                                           -- プログラムID
        , program_update_date                                                                  -- プログラム更新日
      )
      VALUES(
          xxcoi_storage_information_s01.NEXTVAL                                                -- 取引ID(シーケンス)
        , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).inside_base_code                     -- 入庫拠点コード
        , SUBSTRB( gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).outside_subinv_code, 6, 2 ) -- 倉庫コード
        , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_date                         -- 伝票日付
        , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_no                           -- 伝票No
        , NULL                                                                                 -- 出庫依頼ステータス
        , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).item_code                            -- 親品目コード
        , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).item_code                            -- 子品目コード
        , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).case_in_quantity                     -- 入数
        , cv_zero                                                                              -- 出庫数量ケース数
        , cv_zero                                                                              -- 出庫数量バラ数
        , cv_zero                                                                              -- 出庫数量総バラ数
        , SUBSTRB( gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).inside_subinv_code, 6, 5 )  -- 転送先倉庫コード
        , SUBSTRB( gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).outside_subinv_code, 6, 2 ) -- 確認倉庫コード
        , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).case_quantity                        -- 確認数量ケース数
        , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).quantity                             -- 確認数量バラ数
        , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).total_quantity                       -- 確認数量総バラ数
        , cv_zero                                                                              -- 資材取引未連携数量
        , cv_slip_type                                                                         -- 伝票区分
        , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).outside_code                         -- 出庫拠点コード
        , NULL                                                                                 -- 賞味期限
        , NULL                                                                                 -- 工場固有記号
        , cv_flag_on                                                                           -- サマリーデータフラグ
        , cv_flag_on                                                                           -- 入庫確認フラグ
        , cv_flag_off                                                                          -- 資材取引連携済フラグ
        , gv_auto_flag                                                                         -- 自動入庫確認フラグ
        , cn_created_by                                                                        -- 作成者
        , cd_creation_date                                                                     -- 作成日
        , cn_last_updated_by                                                                   -- 最終更新者
        , cd_last_update_date                                                                  -- 最終更新日
        , cn_last_update_login                                                                 -- 最終更新ログイン
        , cn_request_id                                                                        -- 要求ID
        , cn_program_application_id                                                            -- プログラムアプリケーションID
        , cn_program_id                                                                        -- プログラムID
        , cd_program_update_date                                                               -- プログラム更新日
      );
--
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
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END ins_storage_info_tab;
--
  /**********************************************************************************
   * Procedure Name   : upd_storage_info_tab
   * Description      : 入庫情報一時表更新処理 (A-6)
   ***********************************************************************************/
  PROCEDURE upd_storage_info_tab(
    gn_storage_info_loop_cnt IN   NUMBER,    -- 入庫情報一時表データループカウンタ
    gn_kuragae_data_loop_cnt IN   NUMBER,    -- 倉替データループカウンタ
    ov_errbuf                OUT  VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT  VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg                OUT  VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_storage_info_tab'; -- プログラム名
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 出庫側情報の場合の入庫情報一時表更新
    IF ( gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).stock_uncheck_list_div = cv_stock_uncheck_list_div_out ) THEN
--
      UPDATE xxcoi_storage_information  xsi                                                                   -- 入庫情報一時表
      SET    xsi.ship_case_qty          = ( gt_storage_info_tab( gn_storage_info_loop_cnt ).ship_case_qty     -- 出庫数量ケース数 = 
                                          + gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).case_quantity )   -- 出庫数量ケース数 + ケース数
           , xsi.ship_singly_qty        = ( gt_storage_info_tab( gn_storage_info_loop_cnt ).ship_singly_qty   -- 出庫数量バラ数
                                          + gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).quantity )        -- 出庫数量バラ数   + 本数
           , xsi.ship_summary_qty       = ( gt_storage_info_tab( gn_storage_info_loop_cnt ).ship_summary_qty  -- 出庫数量総バラ数
                                          + gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).total_quantity )  -- 出庫数量総バラ数 + 総数
           , xsi.last_updated_by        = cn_last_updated_by                                                  -- 最終更新者
           , xsi.last_update_date       = cd_last_update_date                                                 -- 最終更新日
           , xsi.last_update_login      = cn_last_update_login                                                -- 最終更新ログイン
           , xsi.request_id             = cn_request_id                                                       -- 要求ID
           , xsi.program_application_id = cn_program_application_id                                           -- プログラムアプリケーションID
           , xsi.program_id             = cn_program_id                                                       -- プログラムID
           , xsi.program_update_date    = cd_program_update_date                                              -- プログラム更新日
      WHERE  xsi.rowid                  = gt_storage_info_tab( gn_storage_info_loop_cnt ).xsi_rowid           -- ROWID
      ;
--
    -- 百貨店HHT入庫側情報の場合の入庫情報一時表更新
    ELSIF ( gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).stock_uncheck_list_div = cv_stock_uncheck_list_div_in ) THEN
--
      UPDATE xxcoi_storage_information  xsi                                                                   -- 入庫情報一時表
      SET    xsi.check_case_qty         = ( gt_storage_info_tab( gn_storage_info_loop_cnt ).check_case_qty    -- 確認数量ケース数 = 
                                          + gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).case_quantity )   -- 確認数量ケース数 + ケース数
           , xsi.check_singly_qty       = ( gt_storage_info_tab( gn_storage_info_loop_cnt ).check_singly_qty  -- 確認数量バラ数
                                          + gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).quantity )        -- 確認数量バラ数   + 本数
           , xsi.check_summary_qty      = ( gt_storage_info_tab( gn_storage_info_loop_cnt ).check_summary_qty -- 確認数量総バラ数
                                          + gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).total_quantity )  -- 確認数量総バラ数 + 総数
           , xsi.ship_warehouse_code    = SUBSTRB( gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).inside_subinv_code, 6, 5 )  -- 転送先倉庫コード
           , xsi.store_check_flag       = cv_flag_on                                                          -- 入庫確認フラグ
           , xsi.last_updated_by        = cn_last_updated_by                                                  -- 最終更新者
           , xsi.last_update_date       = cd_last_update_date                                                 -- 最終更新日
           , xsi.last_update_login      = cn_last_update_login                                                -- 最終更新ログイン
           , xsi.request_id             = cn_request_id                                                       -- 要求ID
           , xsi.program_application_id = cn_program_application_id                                           -- プログラムアプリケーションID
           , xsi.program_id             = cn_program_id                                                       -- プログラムID
           , xsi.program_update_date    = cd_program_update_date                                              -- プログラム更新日
      WHERE  xsi.rowid                  = gt_storage_info_tab( gn_storage_info_loop_cnt ).xsi_rowid           -- ROWID
      ;
--
    END IF;
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
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END upd_storage_info_tab;
--
  /**********************************************************************************
   * Procedure Name   : ins_kuragae_data
   * Description      : 倉替データ追加処理 (A-7)
   ***********************************************************************************/
  PROCEDURE ins_kuragae_data(
    gn_kuragae_data_loop_cnt IN   NUMBER,    -- 倉替データループカウンタ
    ov_errbuf                OUT  VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT  VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg                OUT  VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_kuragae_data'; -- プログラム名
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
    cv_process_flag              CONSTANT VARCHAR2(1) := '1';  -- プロセスフラグ 1：処理対象
    cv_transaction_mode          CONSTANT VARCHAR2(1) := '3';  -- 取引モード     3：バックグラウンド
    cv_source_line_id            CONSTANT VARCHAR2(1) := '1';  -- ソースラインID 1：固定
--
    -- *** ローカル変数 ***
    lt_subinventory_code         mtl_transactions_interface.subinventory_code%TYPE;     -- 保管場所
    lt_transfer_subinventory     mtl_transactions_interface.transfer_subinventory%TYPE; -- 相手先保管場所
    lt_transaction_type_id       mtl_transactions_interface.transaction_type_id%TYPE;   -- 取引タイプID
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
    -- ローカル変数の初期化
    lt_subinventory_code     := NULL;
    lt_transfer_subinventory := NULL;
    lt_transaction_type_id   := NULL;
--
    -- 総数量の符号がによる保管場所、相手先保管場所の判定
    IF ( SIGN( gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).total_quantity ) = 1 ) THEN
      lt_subinventory_code     := gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).outside_subinv_code;
      lt_transfer_subinventory := gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).inside_subinv_code;
    ELSIF ( SIGN( gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).total_quantity ) = ( -1 ) ) THEN
      lt_subinventory_code     := gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).inside_subinv_code;
      lt_transfer_subinventory := gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).outside_subinv_code;
    END IF;
--
    -- 取引タイプIDの判定（拠点が同じ場合は入出庫、異なる場合は倉替）
    IF ( gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).outside_base_code
      = gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).inside_base_code ) THEN
       lt_transaction_type_id := gt_tran_type_inout;
    ELSE
       lt_transaction_type_id := gt_tran_type_kuragae;
    END IF;
--
    -- 資材取引OIFへ登録
    INSERT INTO mtl_transactions_interface(
        process_flag                                                             -- プロセスフラグ
      , transaction_mode                                                         -- 取引モード
      , source_code                                                              -- ソースコード
      , source_header_id                                                         -- ソースヘッダーID
      , source_line_id                                                           -- ソースラインID
      , inventory_item_id                                                        -- 品目ID
      , organization_id                                                          -- 在庫組織ID
      , transaction_quantity                                                     -- 取引数量
      , primary_quantity                                                         -- 基準単位数量
      , transaction_uom                                                          -- 取引単位
      , transaction_date                                                         -- 取引日
      , subinventory_code                                                        -- 保管場所コード
      , transaction_type_id                                                      -- 取引タイプID
      , transfer_subinventory                                                    -- 相手先保管場所コード
      , transfer_organization                                                    -- 相手先在庫組織ID
      , attribute1                                                               -- 伝票No
      , created_by                                                               -- 作成者
      , creation_date                                                            -- 作成日
      , last_updated_by                                                          -- 最終更新者
      , last_update_date                                                         -- 最終更新日
      , last_update_login                                                        -- 最終更新ログイン
      , request_id                                                               -- 要求ID
      , program_application_id                                                   -- プログラムアプリケーションID
      , program_id                                                               -- プログラムID
      , program_update_date                                                      -- プログラム更新日
    )
    VALUES(
        cv_process_flag                                                          -- プロセスフラグ
      , cv_transaction_mode                                                      -- 取引モード
      , cv_pkg_name                                                              -- ソースコード
      , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).transaction_id           -- ソースヘッダーID
      , cv_source_line_id                                                        -- ソースラインID
      , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).inventory_item_id        -- 品目ID
      , gt_org_id                                                                -- 在庫組織ID
      , ( SIGN( gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).total_quantity )
          * ( gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).total_quantity ) ) -- 取引数量
      , ( SIGN( gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).total_quantity )
          * ( gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).total_quantity ) ) -- 基準単位数量
      , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).primary_uom_code         -- 取引単位
      , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_date             -- 取引日
      , lt_subinventory_code                                                     -- 保管場所コード
      , lt_transaction_type_id                                                   -- 取引タイプID
      , lt_transfer_subinventory                                                 -- 相手先保管場所コード
      , gt_org_id                                                                -- 相手先在庫組織ID
      , gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_no               -- 伝票No
      , cn_created_by                                                            -- 作成者
      , cd_creation_date                                                         -- 作成日
      , cn_last_updated_by                                                       -- 最終更新者
      , cd_last_update_date                                                      -- 最終更新日
      , cn_last_update_login                                                     -- 最終更新ログイン
      , cn_request_id                                                            -- 要求ID
      , cn_program_application_id                                                -- プログラムアプリケーションID
      , cn_program_id                                                            -- プログラムID
      , cd_program_update_date                                                   -- プログラム更新日
    );
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
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END ins_kuragae_data;
--
  /**********************************************************************************
   * Procedure Name   : upd_hht_inv_tab
   * Description      : HHT入出庫一時表更新処理 (A-8)
   ***********************************************************************************/
  PROCEDURE upd_hht_inv_tab(
    gn_kuragae_data_loop_cnt IN   NUMBER,    -- 倉替データループカウンタ
    ov_errbuf                OUT  VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT  VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg                OUT  VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_hht_inv_tab'; -- プログラム名
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
    cv_status_post               CONSTANT VARCHAR2(1) := '1';  -- 処理ステータス 1：処理済
--
    -- *** ローカル変数 ***
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
    -- HHT入出庫一時表更新
    UPDATE xxcoi_hht_inv_transactions xhit                                                          -- HHT入出庫一時表
    SET    xhit.status                 = cv_status_post                                             -- 処理ステータス
         , xhit.last_updated_by        = cn_last_updated_by                                         -- 最終更新者
         , xhit.last_update_date       = cd_last_update_date                                        -- 最終更新日
         , xhit.last_update_login      = cn_last_update_login                                       -- 最終更新ログイン
         , xhit.request_id             = cn_request_id                                              -- 要求ID
         , xhit.program_application_id = cn_program_application_id                                  -- プログラムアプリケーションID
         , xhit.program_id             = cn_program_id                                              -- プログラムID
         , xhit.program_update_date    = cd_program_update_date                                     -- プログラム更新日
    WHERE  xhit.rowid                  = gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).xhit_rowid -- ROWID
    ;
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
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END upd_hht_inv_tab;
--
  /**********************************************************************************
   * Procedure Name   : del_hht_inv_tab
   * Description      : HHT入出庫一時表削除処理 (A-10)
   ***********************************************************************************/
  PROCEDURE del_hht_inv_tab(
    gn_kuragae_data_loop_cnt IN   NUMBER,    -- 倉替データループカウンタ
    ov_errbuf                OUT  VARCHAR2,  -- エラー・メッセージ                  --# 固定 #
    ov_retcode               OUT  VARCHAR2,  -- リターン・コード                    --# 固定 #
    ov_errmsg                OUT  VARCHAR2)  -- ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_hht_inv_tab'; -- プログラム名
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- HHT入出庫一時表の削除
    DELETE
    FROM   xxcoi_hht_inv_transactions xhit                                         -- HHT入出庫一時表
    WHERE  xhit.rowid = gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).xhit_rowid -- ROWID
    ;
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
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END del_hht_inv_tab;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT  VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT  VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg     OUT  VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
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
--
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
    -- グローバル変数の初期化
    gn_target_cnt := 0; -- 対象件数
    gn_normal_cnt := 0; -- 成功件数
    gn_error_cnt  := 0; -- エラー件数
    gn_warn_cnt   := 0; -- スキップ件数
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- 初期処理 (A-1)
    -- ===============================
    init(
        ov_errbuf  => lv_errbuf  -- エラー・メッセージ           --# 固定 #
      , ov_retcode => lv_retcode -- リターン・コード             --# 固定 #
      , ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 倉替データ抽出処理 (A-2)
    -- ===============================
    get_kuragae_data(
        ov_errbuf  => lv_errbuf  -- エラー・メッセージ           --# 固定 #
      , ov_retcode => lv_retcode -- リターン・コード             --# 固定 #
      , ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 倉替データ取得件数が0件の場合
    IF ( gn_target_cnt = 0 ) THEN
      RAISE no_data_expt;
    END IF;
--
      -- 倉替データループ開始
      <<gt_kuragae_data_tab_loop>>
      FOR gn_kuragae_data_loop_cnt IN 1 .. gn_target_cnt LOOP
--
        -- スキップ用フラグの初期化
        gv_skip_flag := cv_flag_off;
--
        -- ===============================
        -- 倉替データ妥当性チェック処理 (A-3)
        -- ===============================
        chk_kuragae_data(
            gn_kuragae_data_loop_cnt => gn_kuragae_data_loop_cnt -- 倉替データループカウンタ
          , ov_errbuf                => lv_errbuf                -- エラー・メッセージ           --# 固定 #
          , ov_retcode               => lv_retcode               -- リターン・コード             --# 固定 #
          , ov_errmsg                => lv_errmsg                -- ユーザー・エラー・メッセージ --# 固定 #
        );
--
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          -- ===============================
          -- エラーリスト表追加処理 (A-9)
          -- ===============================
          xxcoi_common_pkg.add_hht_err_list_data(
              iv_base_code           => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).base_code    -- 拠点コード
            , iv_origin_shipment     => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).outside_code -- 出庫側コード
            , iv_data_name           => gt_data_name                                                 -- データ名称
            , id_transaction_date    => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_date -- 取引日
            , iv_entry_number        => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).invoice_no   -- 伝票No
            , iv_party_num           => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).inside_code  -- 入庫側コード
            , iv_performance_by_code => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).employee_num -- 営業員コード
            , iv_item_code           => gt_kuragae_data_tab( gn_kuragae_data_loop_cnt ).item_code    -- 品目コード
            , iv_error_message       => lv_errmsg                                                    -- エラー内容
            , ov_errbuf              => lv_errbuf                                                    -- エラー・メッセージ
            , ov_retcode             => lv_retcode                                                   -- リターン・コード
            , ov_errmsg              => lv_errmsg                                                    -- ユーザー・エラー・メッセージ
          );
--
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ===============================
          -- HHT入出庫一時表削除処理 (A-10)
          -- ===============================
          del_hht_inv_tab(
              gn_kuragae_data_loop_cnt => gn_kuragae_data_loop_cnt -- 倉替データループカウンタ
            , ov_errbuf                => lv_errbuf                -- エラー・メッセージ           --# 固定 #
            , ov_retcode               => lv_retcode               -- リターン・コード             --# 固定 #
            , ov_errmsg                => lv_errmsg                -- ユーザー・エラー・メッセージ --# 固定 #
          );
--
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
          -- スキップ用フラグ
          gv_skip_flag := cv_flag_on;
          -- エラー件数
          gn_error_cnt := gn_error_cnt + 1;
--
        END IF;
--
        -- スキップ用フラグがOFFの場合
        IF ( gv_skip_flag = cv_flag_off ) THEN
--
          -- ===============================
          -- 追加／更新判定処理 (A-4)
          -- ===============================
          chk_ins_upd(
              gn_kuragae_data_loop_cnt => gn_kuragae_data_loop_cnt -- 倉替データループカウンタ
            , ov_errbuf                => lv_errbuf                -- エラー・メッセージ           --# 固定 #
            , ov_retcode               => lv_retcode               -- リターン・コード             --# 固定 #
            , ov_errmsg                => lv_errmsg                -- ユーザー・エラー・メッセージ --# 固定 #
          );
--
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          ELSIF ( lv_retcode = cv_status_warn ) THEN
            -- スキップ用フラグ
            gv_skip_flag := cv_flag_on;
            -- スキップ件数
            gn_warn_cnt := gn_warn_cnt + 1;
          END IF;
--
        END IF;
--
        -- スキップ用フラグがOFFの場合
        IF ( gv_skip_flag = cv_flag_off ) THEN
--
          -- 入庫情報一時表データが取得できなかった場合
          IF ( gn_storage_info_cnt = 0 ) THEN
            -- ====================================
            -- 入庫情報一時表追加処理 (A-5)
            -- ====================================
            ins_storage_info_tab(
                gn_kuragae_data_loop_cnt => gn_kuragae_data_loop_cnt -- 倉替データループカウンタ
              , ov_errbuf                => lv_errbuf                -- エラー・メッセージ           --# 固定 #
              , ov_retcode               => lv_retcode               -- リターン・コード             --# 固定 #
              , ov_errmsg                => lv_errmsg                -- ユーザー・エラー・メッセージ --# 固定 #
            );
--
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            END IF;
--
          -- 入庫情報一時表データが取得できた場合
          ELSE
--
            -- 入庫情報一時表データループ開始
            <<gt_storage_info_tab_loop>>
            FOR gn_storage_info_loop_cnt IN 1 .. gn_storage_info_cnt LOOP
--
              -- ====================================
              -- 入庫情報一時表更新処理 (A-6)
              -- ====================================
              upd_storage_info_tab(
                  gn_storage_info_loop_cnt => gn_storage_info_loop_cnt -- 入庫情報一時表データループカウンタ
                , gn_kuragae_data_loop_cnt => gn_kuragae_data_loop_cnt -- 倉替データループカウンタ
                , ov_errbuf                => lv_errbuf                -- エラー・メッセージ           --# 固定 #
                , ov_retcode               => lv_retcode               -- リターン・コード             --# 固定 #
                , ov_errmsg                => lv_errmsg                -- ユーザー・エラー・メッセージ --# 固定 #
              );
--
              IF ( lv_retcode = cv_status_error ) THEN
                RAISE global_process_expt;
              END IF;
--
            END LOOP gt_storage_info_tab_loop;
--
          END IF;
--
          -- ========================================================
          -- 倉替データ追加処理 (A-7)
          -- ========================================================
          ins_kuragae_data(
              gn_kuragae_data_loop_cnt => gn_kuragae_data_loop_cnt -- 倉替データループカウンタ
            , ov_errbuf                => lv_errbuf                -- エラー・メッセージ           --# 固定 #
            , ov_retcode               => lv_retcode               -- リターン・コード             --# 固定 #
            , ov_errmsg                => lv_errmsg                -- ユーザー・エラー・メッセージ --# 固定 #
          );
--
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ====================================
          -- HHT入出庫一時表更新処理 (A-8)
          -- ====================================
          upd_hht_inv_tab(
              gn_kuragae_data_loop_cnt => gn_kuragae_data_loop_cnt -- 倉替データループカウンタ
            , ov_errbuf                => lv_errbuf                -- エラー・メッセージ           --# 固定 #
            , ov_retcode               => lv_retcode               -- リターン・コード             --# 固定 #
            , ov_errmsg                => lv_errmsg                -- ユーザー・エラー・メッセージ --# 固定 #
          );
--
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
          -- 成功件数
          gn_normal_cnt := gn_normal_cnt + 1;
--
        END IF;
--
      END LOOP gt_kuragae_data_tab_loop;
--
  EXCEPTION
    -- 取得件数0件
    WHEN no_data_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                      ,iv_name         => cv_no_data_msg
                    );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_normal;
      -- メッセージ出力
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => ov_errmsg --エラーメッセージ
      );
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
    errbuf        OUT  VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT  VARCHAR2       --   リターン・コード    --# 固定 #
  )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
--
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
      , ov_errbuf  => lv_errbuf
      , ov_errmsg  => lv_errmsg
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
        lv_errbuf   -- エラー・メッセージ           --# 固定 #
      , lv_retcode  -- リターン・コード             --# 固定 #
      , lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      -- エラーメッセージ出力
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_errmsg --エラーメッセージ
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
--
    -- 空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
    -- 終了ステータス「エラー」の場合、対象件数・正常件数・スキップ件数の初期化とエラー件数のセット
    IF ( lv_retcode = cv_status_error ) THEN
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_warn_cnt   := 0;
      gn_error_cnt  := 1;
    END IF;
--
    -- 対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
--
    -- 成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
--
    -- エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
--
    -- スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_skip_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
--
    -- 空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
    -- 終了ステータスが「エラー」以外且つ、スキップ件数またはエラー件数が1件以上ある場合、終了ステータス「警告」にする
    IF ( ( lv_retcode <> cv_status_error ) AND ( ( gn_warn_cnt > 0 ) OR ( gn_error_cnt > 0 ) ) ) THEN
      lv_retcode := cv_status_warn;
    END IF;
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
                    , iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- ステータスセット
    retcode := lv_retcode;
    -- 終了ステータスがエラーの場合はROLLBACKする
    IF ( retcode = cv_status_error ) THEN
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
END XXCOI003A13C;
/
