create or replace
PACKAGE BODY XXCOI003A14C  
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI003A14C(body)
 * Description      : その他取引データOIF更新
 * MD.050           : その他取引データOIF更新（HHT入出庫データ） MD050_COI_003_A14 
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理                                 (A-1)
 *  chk_inout_kuragae_data 入出庫・倉替データ妥当性チェック         (A-3)
 *  ins_inout_kuragae_data 入出庫・倉替データの資材取引OIF追加      (A-4)
 *  update_xhit_data       HHT入出庫一時表の処理ステータス更新      (A-5)(A-12)(A-21)
 *  del_xhit_data          HHT入出庫一時表のエラーレコード削除      (A-7)(A-14)(A-23)
 *  get_inout_kuragae_data 入出庫・倉替データ取得                   (A-2)
 *  chk_svd_data           消化VD補充データ 妥当性チェック          (A-10)
 *  ins_temp_svd_data      消化VD補充データの一時表追加             (A-11)
 *  ins_oif_svd_data       消化VD補充データの資材取引OIF追加        (A-15)
 *  get_svd_data           消化VD補充データ取得                     (A-9)
 *  chk_item_conv_data     商品振替データ妥当性チェック             (A-18)
 *  ins_oif_item_conv_data 商品振替データの資材取引OIF追加          (A-20)
 *  get_item_conv_data     商品振替データ取得                       (A-17)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/19   1.0   H.Nakajima        新規作成
 *  2009/11/24   1.1   N.Abe             [E_本稼動_00025]画面入力時VDコラム品目チェックの解除
 *  2009/11/25   1.2   H.Sasaki          [E_本稼動_00025]画面入力時VDコラム品目チェックの削除
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
  lock_expt                      EXCEPTION; -- ロック取得エラー
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );  -- ロック取得例外
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                     CONSTANT VARCHAR2(15)  := 'XXCOI003A14C';       -- パッケージ名
  cv_appl_short_name              CONSTANT VARCHAR2(10)  := 'XXCCP';              -- アドオン：共通・IF領域
  cv_application_short_name       CONSTANT VARCHAR2(10)  := 'XXCOI';              -- アプリケーション短縮名
  -- メッセージ
  cv_no_para_msg                  CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90008';    -- コンカレント入力パラメータなしメッセージ
  cv_org_code_get_err             CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00005';    -- 在庫組織コード取得エラーメッセージ
  cv_org_id_get_err               CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00006';    -- 在庫組織ID取得エラーメッセージ
  cv_hht_name_get_err             CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10027';    -- HHTエラーリスト名取得エラーメッセージ
  cv_no_data_msg                  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00008';    -- 対象データ無しメッセージ
  cv_msg_process_date_get_err     CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00011';    -- 業務日付取得エラーメッセージ
  cv_tran_type_name_get_err_msg   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00022';    -- 取引タイプ名取得エラーメッセージ
  cv_tran_type_id_get_err_msg     CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00012';    -- 取引タイプID取得エラーメッセージ
  cv_hht_table_lock_err_msg       CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10055';    -- ロック取得エラーメッセージ（HHT入出庫一時表）
  cv_msg_org_acct_period_err      CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00026';    -- 在庫会計期間取得チェックエラー
  cv_invoice_date_invalid_err     CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10231';    -- 在庫会計期間チェックエラー
  cv_key_info                     CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10342';    -- HHT入出庫データ用KEY情報
  cv_dept_code_err_msg            CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10052';    -- 倉替対象可否エラーメッセージ
  cv_inout_kuragae_start_msg      CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10248';    -- 件数メッセージ（入出庫・倉替）
  cv_svd_start_msg                CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10249';    -- 件数メッセージ（消化VD補充）
  cv_item_conv_msg                CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10250';    -- 件数メッセージ（商品振替）
  cv_inout_kuragae_no_data_msg    CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10245';    -- 対象データ無しメッセージ（入出庫・倉換）
  cv_svd_no_data_msg              CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10246';    -- 対象データ無しメッセージ（消化VD補充）
  cv_item_conv_no_data_msg        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10247';    -- 対象データ無しメッセージ（商品振替）
  cv_column_no_is_null_err_msg    CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10025';    -- 必須項目エラー（コラム№）
  cv_up_is_null_err_mag           CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10026';    -- 必須項目エラー（単価）
  cv_vd_item_err_msg              CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10348';    -- VDコラム品目不一致エラー
  cv_vd_last_month_item_err_msg   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10349';    -- VDコラム前月末品目不一致エラー
  cv_get_disposition_id_err_msg   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10351';    -- 勘定科目別名ID取得エラー
  cv_oif_ins_cnt_msg              CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10335';    -- 取引作成件数メッセージ
  cv_end_msg                      CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10352';    -- その他取引OIF更新（HHT入出庫データ）処理件数メッセージ
  -- トークン 
  cv_tkn_pro                      CONSTANT VARCHAR2(20)  := 'PRO_TOK';              -- TKN：プロファイル名
  cv_tkn_org_code                 CONSTANT VARCHAR2(20)  := 'ORG_CODE_TOK';         -- TKN：在庫組織コード
  cv_tkn_tran_type                CONSTANT VARCHAR2(20)  := 'TRANSACTION_TYPE_TOK'; -- TKN：取引タイプ名
  cv_tkn_lookup_type              CONSTANT VARCHAR2(20)  := 'LOOKUP_TYPE';          -- TKN：参照タイプ
  cv_tkn_lookup_code              CONSTANT VARCHAR2(20)  := 'LOOKUP_CODE';          -- TKN：参照コード
  cv_tkn_proc_date                CONSTANT VARCHAR2(20)  := 'INVOICE_DATE';         -- TKN：伝票日付
  cv_tkn_target_date              CONSTANT VARCHAR2(20)  := 'TARGET_DATE';          -- TKN：対象日
  cv_tkn_record_type              CONSTANT VARCHAR2(20)  := 'RECORD_TYPE';          -- TKN：ﾚｺｰﾄﾞ種別
  cv_tkn_invoice_type             CONSTANT VARCHAR2(20)  := 'INVOICE_TYPE';         -- TKN：伝票区分
  cv_tkn_dept_flag                CONSTANT VARCHAR2(20)  := 'DEPT_FLAG';            -- TKN：百貨店ﾌﾗｸﾞ
  cv_tkn_base_code                CONSTANT VARCHAR2(20)  := 'BASE_CODE';            -- TKN：拠点ｺｰﾄﾞ
  cv_tkn_column_no                CONSTANT VARCHAR2(20)  := 'COLUMN_NO';            -- TKN：コラム№
  cv_tkn_invoice_no               CONSTANT VARCHAR2(20)  := 'INVOICE_NO';           -- TKN：伝票番号
  cv_tkn_item_code                CONSTANT VARCHAR2(20)  := 'ITEM_CODE';            -- TKN：品目ｺｰﾄﾞ
  cv_tkn_dept_code                CONSTANT VARCHAR2(20)  := 'DEPT_CODE';            -- TKN：拠点コード
  cv_tkn_acct_type                CONSTANT VARCHAR2(20)  := 'INV_ACCOUNT_TYPE';     -- TKN：入出庫勘定区分
  --
  cv_flag_y                       CONSTANT VARCHAR2(1)  := 'Y';                     -- フラグ：Y
  cv_flag_n                       CONSTANT VARCHAR2(1)  := 'N';                     -- フラグ：N
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 倉替データレコード格納用
  TYPE gr_inout_kuragae_data_rec IS RECORD(
      xhit_rowid                 rowid                                                  -- ROWID
    , invoice_no                 xxcoi_hht_inv_transactions.invoice_no%TYPE             -- 伝票No
    , transaction_id             xxcoi_hht_inv_transactions.transaction_id%TYPE         -- 入庫情報一時表ID
    , record_type                xxcoi_hht_inv_transactions.record_type%TYPE            -- レコード種別
    , invoice_type               xxcoi_hht_inv_transactions.invoice_type%TYPE           -- 伝票区分
    , department_flag            xxcoi_hht_inv_transactions.department_flag%TYPE        -- 百貨店フラグ
    , column_no                  xxcoi_hht_inv_transactions.column_no%TYPE              -- コラム№  
    , base_code                  xxcoi_hht_inv_transactions.base_code%TYPE              -- 拠点コード
    , employee_num               xxcoi_hht_inv_transactions.employee_num%TYPE           -- 営業員コード
    , item_code                  xxcoi_hht_inv_transactions.item_code%TYPE              -- 品目コード
    , case_in_quantity           xxcoi_hht_inv_transactions.case_in_quantity%TYPE       -- 入数
    , case_quantity              xxcoi_hht_inv_transactions.case_quantity%TYPE          -- ケース数
    , quantity                   xxcoi_hht_inv_transactions.quantity%TYPE               -- 本数
    , total_quantity             xxcoi_hht_inv_transactions.total_quantity%TYPE         -- 総数量
    , inventory_item_id          xxcoi_hht_inv_transactions.inventory_item_id%TYPE      -- 品目ID
    , primary_uom_code           xxcoi_hht_inv_transactions.primary_uom_code%TYPE       -- 基準単位
    , invoice_date               xxcoi_hht_inv_transactions.invoice_date%TYPE           -- 伝票日付
    , outside_subinv_code        xxcoi_hht_inv_transactions.outside_subinv_code%TYPE    -- 出庫側保管場所
    , inside_subinv_code         xxcoi_hht_inv_transactions.inside_subinv_code%TYPE     -- 入庫側保管場所
    , outside_code               xxcoi_hht_inv_transactions.outside_code%TYPE           -- 出庫側コード
    , inside_code                xxcoi_hht_inv_transactions.inside_code%TYPE            -- 入庫側コード
    , outside_base_code          xxcoi_hht_inv_transactions.outside_base_code%TYPE      -- 出庫側拠点コード
    , inside_base_code           xxcoi_hht_inv_transactions.inside_base_code%TYPE       -- 入庫側拠点コード
  );
  TYPE gt_inout_kuragae_data_ttype IS TABLE OF gr_inout_kuragae_data_rec INDEX BY BINARY_INTEGER;
  -- 消化VD補充データレコード格納用
  TYPE gr_svd_data_rec IS RECORD(
      xhit_rowid                 rowid                                                      -- ROWID
    , invoice_no                 xxcoi_hht_inv_transactions.invoice_no%TYPE                 -- 伝票No
    , transaction_id             xxcoi_hht_inv_transactions.transaction_id%TYPE             -- 入庫情報一時表ID
    , record_type                xxcoi_hht_inv_transactions.record_type%TYPE                -- レコード種別
    , invoice_type               xxcoi_hht_inv_transactions.invoice_type%TYPE               -- 伝票区分
    , department_flag            xxcoi_hht_inv_transactions.department_flag%TYPE            -- 百貨店フラグ
    , column_no                  xxcoi_hht_inv_transactions.column_no%TYPE                  -- コラム№  
    , unit_price                 xxcoi_hht_inv_transactions.unit_price%TYPE                 -- 単価
    , base_code                  xxcoi_hht_inv_transactions.base_code%TYPE                  -- 拠点コード
    , employee_num               xxcoi_hht_inv_transactions.employee_num%TYPE               -- 営業員コード
    , item_code                  xxcoi_hht_inv_transactions.item_code%TYPE                  -- 品目コード
    , case_in_quantity           xxcoi_hht_inv_transactions.case_in_quantity%TYPE           -- 入数
    , case_quantity              xxcoi_hht_inv_transactions.case_quantity%TYPE              -- ケース数
    , quantity                   xxcoi_hht_inv_transactions.quantity%TYPE                   -- 本数
    , total_quantity             xxcoi_hht_inv_transactions.total_quantity%TYPE             -- 総数量
    , inventory_item_id          xxcoi_hht_inv_transactions.inventory_item_id%TYPE          -- 品目ID
    , primary_uom_code           xxcoi_hht_inv_transactions.primary_uom_code%TYPE           -- 基準単位
    , invoice_date               xxcoi_hht_inv_transactions.invoice_date%TYPE               -- 伝票日付
    , outside_subinv_code        xxcoi_hht_inv_transactions.outside_subinv_code%TYPE        -- 出庫側保管場所
    , inside_subinv_code         xxcoi_hht_inv_transactions.inside_subinv_code%TYPE         -- 入庫側保管場所
    , outside_code               xxcoi_hht_inv_transactions.outside_code%TYPE               -- 出庫側コード
    , inside_code                xxcoi_hht_inv_transactions.inside_code%TYPE                -- 入庫側コード
    , outside_base_code          xxcoi_hht_inv_transactions.outside_base_code%TYPE          -- 出庫側拠点コード
    , inside_base_code           xxcoi_hht_inv_transactions.inside_base_code%TYPE           -- 入庫側拠点コード
    , outside_business_low_type  xxcoi_hht_inv_transactions.outside_business_low_type%TYPE  -- 出庫側業態小分類
    , inside_business_low_type   xxcoi_hht_inv_transactions.inside_business_low_type%TYPE   -- 入庫側業態小分類
  );
  TYPE gt_svd_data_ttype IS TABLE OF gr_svd_data_rec INDEX BY BINARY_INTEGER;
  -- 商品振替データレコード格納用
  TYPE gr_item_conv_data_rec IS RECORD(
      xhit_rowid                 rowid                                                  -- ROWID
    , invoice_no                 xxcoi_hht_inv_transactions.invoice_no%TYPE             -- 伝票No
    , transaction_id             xxcoi_hht_inv_transactions.transaction_id%TYPE         -- 入庫情報一時表ID
    , record_type                xxcoi_hht_inv_transactions.record_type%TYPE            -- レコード種別
    , invoice_type               xxcoi_hht_inv_transactions.invoice_type%TYPE           -- 伝票区分
    , department_flag            xxcoi_hht_inv_transactions.department_flag%TYPE        -- 百貨店フラグ
    , column_no                  xxcoi_hht_inv_transactions.column_no%TYPE              -- コラム№  
    , base_code                  xxcoi_hht_inv_transactions.base_code%TYPE              -- 拠点コード
    , employee_num               xxcoi_hht_inv_transactions.employee_num%TYPE           -- 営業員コード
    , item_code                  xxcoi_hht_inv_transactions.item_code%TYPE              -- 品目コード
    , case_in_quantity           xxcoi_hht_inv_transactions.case_in_quantity%TYPE       -- 入数
    , case_quantity              xxcoi_hht_inv_transactions.case_quantity%TYPE          -- ケース数
    , quantity                   xxcoi_hht_inv_transactions.quantity%TYPE               -- 本数
    , total_quantity             xxcoi_hht_inv_transactions.total_quantity%TYPE         -- 総数量
    , inventory_item_id          xxcoi_hht_inv_transactions.inventory_item_id%TYPE      -- 品目ID
    , primary_uom_code           xxcoi_hht_inv_transactions.primary_uom_code%TYPE       -- 基準単位
    , invoice_date               xxcoi_hht_inv_transactions.invoice_date%TYPE           -- 伝票日付
    , outside_subinv_code        xxcoi_hht_inv_transactions.outside_subinv_code%TYPE    -- 出庫側保管場所
    , inside_subinv_code         xxcoi_hht_inv_transactions.inside_subinv_code%TYPE     -- 入庫側保管場所
    , outside_code               xxcoi_hht_inv_transactions.outside_code%TYPE           -- 出庫側コード
    , inside_code                xxcoi_hht_inv_transactions.inside_code%TYPE            -- 入庫側コード
    , outside_base_code          xxcoi_hht_inv_transactions.outside_base_code%TYPE      -- 出庫側拠点コード
    , inside_base_code           xxcoi_hht_inv_transactions.inside_base_code%TYPE       -- 入庫側拠点コード
    , item_convert_div           xxcoi_hht_inv_transactions.item_convert_div%TYPE       -- 商品振替区分
  );
  TYPE gt_item_conv_data_ttype IS TABLE OF gr_item_conv_data_rec INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- PL/SQL表
  gt_inout_kuragae_data_tab       gt_inout_kuragae_data_ttype;
  gt_svd_data_tab                 gt_svd_data_ttype;
  gt_item_conv_data_tab           gt_item_conv_data_ttype;
  -- 初期処理取得変数
  gt_org_id                       mtl_parameters.organization_id%TYPE;                    -- 在庫組織ID
  gt_file_name                    fnd_profile_option_values.profile_option_value%TYPE;    -- HHTエラーリストファイル名
  gd_process_date                 DATE;                                                   -- 業務日付
  gt_tran_type_id_kuragae         mtl_transaction_types.transaction_type_id%TYPE;         -- 取引タイプID 倉替
  gt_tran_type_id_inout           mtl_transaction_types.transaction_type_id%TYPE;         -- 取引タイプID 入出庫
  gt_tran_type_id_item_conv_new   mtl_transaction_types.transaction_type_id%TYPE;         -- 取引タイプID 商品振替(新)
  gt_tran_type_id_item_conv_old   mtl_transaction_types.transaction_type_id%TYPE;         -- 取引タイプID 商品振替(旧)
  gt_tran_type_id_svd             mtl_transaction_types.transaction_type_id%TYPE;         -- 取引タイプID 消化VD補充
  gt_transaction_source_id        mtl_transactions_interface.transaction_source_id%TYPE;  -- 取引ソースID
  gv_kuragae_flag                 VARCHAR2(1);
  -- 入出庫・倉替 処理件数
  gn_target_inout_kuragae_cnt     NUMBER;
  gn_normal_inout_kuragae_cnt     NUMBER;
  gn_warn_inout_kuragae_cnt       NUMBER;
  gn_error_inout_kuragae_cnt      NUMBER;
  -- 消化VD補充 処理件数
  gn_target_svd_cnt               NUMBER;
  gn_normal_svd_cnt               NUMBER;
  gn_warn_svd_cnt                 NUMBER;
  gn_error_svd_cnt                NUMBER;
  gn_oif_ins_svd_cnt              NUMBER;
  -- 商品振替 処理件数
  gn_target_item_conv_cnt         NUMBER;
  gn_normal_item_conv_cnt         NUMBER;
  gn_warn_item_conv_cnt           NUMBER;
  gn_error_item_conv_cnt          NUMBER;
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
    cv_prf_org_code              CONSTANT VARCHAR2(30) := 'XXCOI1_ORGANIZATION_CODE';
    cv_prf_file_name             CONSTANT VARCHAR2(30) := 'XXCOI1_HHT_ERR_DATA_NAME';
    --
    -- 参照タイプ
    cv_tran_type                 CONSTANT VARCHAR2(30) := 'XXCOI1_TRANSACTION_TYPE_NAME'; -- ユーザー定義取引タイプ名称
    -- 参照コード
    cv_tran_type_inout           CONSTANT VARCHAR2(2)  := '10';                           -- 取引タイプ コード 入出庫
    cv_tran_type_kuragae         CONSTANT VARCHAR2(2)  := '20';                           -- 取引タイプ コード 倉替
    cv_tran_type_item_conv_new   CONSTANT VARCHAR2(2)  := '40';                           -- 取引タイプ コード 商品振替(新)
    cv_tran_type_item_conv_old   CONSTANT VARCHAR2(2)  := '30';                           -- 取引タイプ コード 商品振替(旧)
    cv_tran_type_svd             CONSTANT VARCHAR2(2)  := '70';                           -- 取引タイプ コード 消化VD補充
--
    -- *** ローカル変数 ***
    lt_org_code                  mtl_parameters.organization_code%TYPE;                   -- 在庫組織コード
    lt_tran_type_kuragae         mtl_transaction_types.transaction_type_name%TYPE;        -- 取引タイプ名 倉替
    lt_tran_type_inout           mtl_transaction_types.transaction_type_name%TYPE;        -- 取引タイプ名 入出庫
    lt_tran_type_item_conv_new   mtl_transaction_types.transaction_type_name%TYPE;        -- 取引タイプ名 商品振替(新)
    lt_tran_type_item_conv_old   mtl_transaction_types.transaction_type_name%TYPE;        -- 取引タイプ名 商品振替(旧)
    lt_tran_type_svd             mtl_transaction_types.transaction_type_name%TYPE;        -- 取引タイプ名 消化VD補充
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
                     , iv_name         => cv_org_code_get_err
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
    -- 共通関数のリターンコードがNULLの場合
    IF ( gt_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_org_id_get_err
                     , iv_token_name1  => cv_tkn_org_code
                     , iv_token_value1 => lt_org_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- プロファイル取得：HHTエラーリスト名
    -- ===============================
    gt_file_name := fnd_profile.value( cv_prf_file_name );
    -- プロファイルが取得できない場合
    IF ( gt_file_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_hht_name_get_err
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_file_name
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ==============================================================
    -- 業務日付取得
    -- ==============================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- 業務日付が取得できない場合
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_msg_process_date_get_err
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
    gt_tran_type_id_inout := xxcoi_common_pkg.get_transaction_type_id( lt_tran_type_inout );
    -- 共通関数の戻り値がNULLの場合
    IF ( gt_tran_type_id_inout IS NULL ) THEN
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
    gt_tran_type_id_kuragae := xxcoi_common_pkg.get_transaction_type_id( lt_tran_type_kuragae );
    -- 共通関数の戻り値がNULLの場合
    IF ( gt_tran_type_id_kuragae IS NULL ) THEN
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
    -- 取引タイプ名取得（商品振替：新）
    -- ===============================
    lt_tran_type_item_conv_new := xxcoi_common_pkg.get_meaning( cv_tran_type, cv_tran_type_item_conv_new );
    -- 共通関数の戻り値がNULLの場合
    IF ( lt_tran_type_item_conv_new IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_name_get_err_msg
                     , iv_token_name1  => cv_tkn_lookup_type
                     , iv_token_value1 => cv_tran_type
                     , iv_token_name2  => cv_tkn_lookup_code
                     , iv_token_value2 => cv_tran_type_item_conv_new
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 取引タイプID取得（商品振替：新）
    -- ===============================
    gt_tran_type_id_item_conv_new := xxcoi_common_pkg.get_transaction_type_id( lt_tran_type_item_conv_new );
    -- 共通関数の戻り値がNULLの場合
    IF ( gt_tran_type_id_item_conv_new IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_id_get_err_msg
                     , iv_token_name1  => cv_tkn_tran_type
                     , iv_token_value1 => lt_tran_type_item_conv_new
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 取引タイプ名取得（商品振替：旧）
    -- ===============================
    lt_tran_type_item_conv_old := xxcoi_common_pkg.get_meaning( cv_tran_type, cv_tran_type_item_conv_old );
    -- 共通関数の戻り値がNULLの場合
    IF ( lt_tran_type_item_conv_old IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_name_get_err_msg
                     , iv_token_name1  => cv_tkn_lookup_type
                     , iv_token_value1 => cv_tran_type
                     , iv_token_name2  => cv_tkn_lookup_code
                     , iv_token_value2 => cv_tran_type_item_conv_old
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 取引タイプID取得（商品振替：旧）
    -- ===============================
    gt_tran_type_id_item_conv_old := xxcoi_common_pkg.get_transaction_type_id( lt_tran_type_item_conv_old );
    -- 共通関数の戻り値がNULLの場合
    IF ( gt_tran_type_id_item_conv_old IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_id_get_err_msg
                     , iv_token_name1  => cv_tkn_tran_type
                     , iv_token_value1 => lt_tran_type_item_conv_old
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 取引タイプ名取得（消化VD補充）
    -- ===============================
    lt_tran_type_svd := xxcoi_common_pkg.get_meaning( cv_tran_type, cv_tran_type_svd );
    -- 共通関数の戻り値がNULLの場合
    IF ( lt_tran_type_svd IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_name_get_err_msg
                     , iv_token_name1  => cv_tkn_lookup_type
                     , iv_token_value1 => cv_tran_type
                     , iv_token_name2  => cv_tkn_lookup_code
                     , iv_token_value2 => cv_tran_type_svd
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 取引タイプID取得（消化VD補充）
    -- ===============================
    gt_tran_type_id_svd := xxcoi_common_pkg.get_transaction_type_id( lt_tran_type_svd );
    -- 共通関数の戻り値がNULLの場合
    IF ( gt_tran_type_id_svd IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_id_get_err_msg
                     , iv_token_name1  => cv_tkn_tran_type
                     , iv_token_value1 => lt_tran_type_svd
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
   * Procedure Name   : chk_inout_kuragae_data
   * Description      : 入出庫・倉替データ妥当性チェック (A-3)
   ***********************************************************************************/
  PROCEDURE chk_inout_kuragae_data(
    in_index      IN  NUMBER,       -- 1.INDEX
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_inout_kuragae_data'; -- プログラム名
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
    cv_kuragae_kahi_div_0       CONSTANT VARCHAR2(1) := '0';        -- 倉替対象可否区分   0:倉替対象否拠点
    cv_cust_class_code_base     CONSTANT VARCHAR2(1) := '1';        -- 顧客区分           1:拠点
--
    -- *** ローカル変数 ***
    lv_key_info                     VARCHAR2(500);                      -- KEY情報
    lb_org_acct_period_flg          BOOLEAN;                            -- 当月在庫会計期間オープンフラグ
    lt_kuragae_kahi_count           hz_cust_accounts.attribute6%TYPE;   -- 倉替対象可否区分（出庫側拠点コード）
    -- *** ローカル・例外 ***
    invalid_value_expt              EXCEPTION;                                  -- チェック例外
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
--  変数の初期化
    gv_kuragae_flag := NULL;
    --
    -- =========================
    --  1.在庫会計期間チェック
    -- =========================
    xxcoi_common_pkg.org_acct_period_chk(
        in_organization_id => gt_org_id                                                 -- 在庫組織ID
      , id_target_date     => gt_inout_kuragae_data_tab( in_index ).invoice_date    -- 伝票日付
      , ob_chk_result      => lb_org_acct_period_flg                                    -- チェック結果
      , ov_errbuf          => lv_errbuf
      , ov_retcode         => lv_retcode
      , ov_errmsg          => lv_errmsg
    );
    -- 在庫会計期間ステータスの取得に失敗した場合
    IF ( lv_retcode != cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_msg_org_acct_period_err
                     , iv_token_name1  => cv_tkn_target_date
                     , iv_token_value1 => TO_CHAR( gt_inout_kuragae_data_tab( in_index ).invoice_date ,'yyyymmdd' )
                   );
      RAISE global_api_expt;
    END IF;
    -- 当月在庫会計期間がクローズの場合
    IF ( NOT lb_org_acct_period_flg ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_invoice_date_invalid_err
                     , iv_token_name1  => cv_tkn_proc_date
                     , iv_token_value1 => TO_CHAR( gt_inout_kuragae_data_tab( in_index ).invoice_date ,'yyyymmdd' )
                   );
      lv_errbuf := lv_errmsg;
      RAISE invalid_value_expt;
    END IF;
    -- =========================
    --  2.入出庫・倉替判定
    -- =========================
    IF ( gt_inout_kuragae_data_tab(in_index).outside_base_code 
         = gt_inout_kuragae_data_tab(in_index).inside_base_code ) THEN
    -- 入出庫
      gv_kuragae_flag := cv_flag_n;
    --
    ELSE
    -- 倉替
      gv_kuragae_flag := cv_flag_y;
      -- ------------------------
      -- (1) 出庫側：倉替可否判定
      -- ------------------------
      SELECT COUNT(1)                  -- 倉替対象不可件数
      INTO   lt_kuragae_kahi_count
      FROM   hz_cust_accounts hca 
      WHERE  hca.account_number      = gt_inout_kuragae_data_tab(in_index).outside_base_code
      AND    hca.customer_class_code = cv_cust_class_code_base
      AND    hca.attribute6          = cv_kuragae_kahi_div_0
      AND    ROWNUM                 <= 1;
      -- 倉替不可の場合
      IF lt_kuragae_kahi_count = 1 THEN
      --
        lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application_short_name
                          , iv_name         => cv_dept_code_err_msg
                          , iv_token_name1  => cv_tkn_dept_code
                          , iv_token_value1 => gt_inout_kuragae_data_tab(in_index).outside_base_code
                        );
        --
        lv_errbuf := lv_errmsg;
        --
        RAISE invalid_value_expt;
        --
      END IF;
      -- ------------------------
      -- (2) 入庫側：倉替可否判定
      -- ------------------------
      SELECT COUNT(1)                  -- 倉替対象不可件数
      INTO   lt_kuragae_kahi_count
      FROM   hz_cust_accounts hca 
      WHERE  hca.account_number      = gt_inout_kuragae_data_tab(in_index).inside_base_code
      AND    hca.customer_class_code = cv_cust_class_code_base
      AND    hca.attribute6          = cv_kuragae_kahi_div_0
      AND    ROWNUM                 <= 1;
      -- 倉替不可の場合
      IF lt_kuragae_kahi_count = 1 THEN
      --
        lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application_short_name
                          , iv_name         => cv_dept_code_err_msg
                          , iv_token_name1  => cv_tkn_dept_code
                          , iv_token_value1 => gt_inout_kuragae_data_tab(in_index).inside_base_code
                        );
        --
        lv_errbuf := lv_errmsg;
        --
        RAISE invalid_value_expt;
        --
      END IF;
    --
    END IF;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** 不正値例外ハンドラ ***
    WHEN invalid_value_expt THEN
      -- KEY情報取得
      lv_key_info := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_key_info
                     , iv_token_name1  => cv_tkn_base_code
                     , iv_token_value1 => gt_inout_kuragae_data_tab( in_index ).base_code
                     , iv_token_name2  => cv_tkn_record_type
                     , iv_token_value2 => gt_inout_kuragae_data_tab( in_index ).record_type
                     , iv_token_name3  => cv_tkn_invoice_type
                     , iv_token_value3 => gt_inout_kuragae_data_tab( in_index ).invoice_type
                     , iv_token_name4  => cv_tkn_dept_flag
                     , iv_token_value4 => gt_inout_kuragae_data_tab( in_index ).department_flag
                     , iv_token_name5  => cv_tkn_invoice_no
                     , iv_token_value5 => gt_inout_kuragae_data_tab( in_index ).invoice_no
                     , iv_token_name6  => cv_tkn_column_no
                     , iv_token_value6 => gt_inout_kuragae_data_tab( in_index ).column_no
                     , iv_token_name7  => cv_tkn_item_code
                     , iv_token_value7 => gt_inout_kuragae_data_tab( in_index ).item_code );
      --
      FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
         , buff   => lv_key_info || lv_errmsg );
      --
      FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
         , buff   => lv_key_info || lv_errbuf );
      --
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;                                             --# 任意 #
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
  END chk_inout_kuragae_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_inout_kuragae_data
   * Description      : 入出庫・倉替データの資材取引OIF追加 (A-4)
   ***********************************************************************************/
  PROCEDURE ins_inout_kuragae_data(
    in_index      IN  NUMBER,       -- 1.INDEX
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_inout_kuragae_data'; -- プログラム名
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
    lt_tran_type_id              mtl_transaction_types.transaction_type_id%TYPE;         -- 取引タイプID
    lt_subinventory_code         mtl_transactions_interface.subinventory_code%TYPE;      -- 保管場所
    lt_transfer_subinventory     mtl_transactions_interface.transfer_subinventory%TYPE;  -- 相手先保管場所
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
--  変数の初期化
    lt_tran_type_id := NULL;
    lt_subinventory_code := NULL;
    lt_transfer_subinventory := NULL;
    -- =======================
    -- 取引タイプ判定
    -- =======================
    IF gv_kuragae_flag = cv_flag_y THEN
      -- 倉替
      lt_tran_type_id := gt_tran_type_id_kuragae;
      --
    ELSE
      -- 入出庫
      lt_tran_type_id := gt_tran_type_id_inout;
      --
    END IF;
    -- =======================
    -- 数量による保管場所判定
    -- =======================
    IF ( SIGN( gt_inout_kuragae_data_tab( in_index ).total_quantity ) = 1 ) THEN
      -- 正転
      lt_subinventory_code     := gt_inout_kuragae_data_tab( in_index ).outside_subinv_code;
      lt_transfer_subinventory := gt_inout_kuragae_data_tab( in_index ).inside_subinv_code;
      --
    ELSIF ( SIGN( gt_inout_kuragae_data_tab( in_index ).total_quantity ) = ( -1 ) ) THEN
      -- 反転
      lt_subinventory_code     := gt_inout_kuragae_data_tab( in_index ).inside_subinv_code;
      lt_transfer_subinventory := gt_inout_kuragae_data_tab( in_index ).outside_subinv_code;
      --
    END IF;
    -- =======================
    -- 資材取引OIFへ登録
    -- =======================
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
      , gt_inout_kuragae_data_tab( in_index ).transaction_id                     -- ソースヘッダーID
      , cv_source_line_id                                                        -- ソースラインID
      , gt_inout_kuragae_data_tab( in_index ).inventory_item_id                  -- 品目ID
      , gt_org_id                                                                -- 在庫組織ID
      , ( SIGN( gt_inout_kuragae_data_tab( in_index ).total_quantity )
          * ( gt_inout_kuragae_data_tab( in_index ).total_quantity ) )           -- 取引数量
      , ( SIGN( gt_inout_kuragae_data_tab( in_index ).total_quantity )
          * ( gt_inout_kuragae_data_tab( in_index ).total_quantity ) )           -- 基準単位数量
      , gt_inout_kuragae_data_tab( in_index ).primary_uom_code                   -- 取引単位
      , gt_inout_kuragae_data_tab( in_index ).invoice_date                       -- 取引日
      , lt_subinventory_code                                                     -- 保管場所コード
      , lt_tran_type_id                                                          -- 取引タイプID
      , lt_transfer_subinventory                                                 -- 相手先保管場所コード
      , gt_org_id                                                                -- 相手先在庫組織ID
      , gt_inout_kuragae_data_tab( in_index ).invoice_no                         -- 伝票No
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
  END ins_inout_kuragae_data;
--
  /**********************************************************************************
   * Procedure Name   : update_xhit_data
   * Description      : HHT入出庫一時表の処理ステータス更新 (A-5)(A-12)(A-21)
   ***********************************************************************************/
  PROCEDURE update_xhit_data(
    ir_rowid      IN  ROWID,        -- 1.ROWID
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_xhit_data'; -- プログラム名
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
    cn_status_post               CONSTANT NUMBER := 1;  -- 処理ステータス 1：処理済
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
    -- HHT入出庫一時表更新
    UPDATE xxcoi_hht_inv_transactions xhit                              -- HHT入出庫一時表
    SET    xhit.status                 = cn_status_post                 -- 処理ステータス
         , xhit.last_updated_by        = cn_last_updated_by             -- 最終更新者
         , xhit.last_update_date       = cd_last_update_date            -- 最終更新日
         , xhit.last_update_login      = cn_last_update_login           -- 最終更新ログイン
         , xhit.request_id             = cn_request_id                  -- 要求ID
         , xhit.program_application_id = cn_program_application_id      -- プログラムアプリケーションID
         , xhit.program_id             = cn_program_id                  -- プログラムID
         , xhit.program_update_date    = cd_program_update_date         -- プログラム更新日
    WHERE  xhit.rowid                  = ir_rowid                       -- ROWID
    ;
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
  END update_xhit_data;
--
  /**********************************************************************************
   * Procedure Name   : del_xhit_data
   * Description      : HHT入出庫一時表のエラーレコード削除 (A-7)(A-14)(A-23)
   ***********************************************************************************/
  PROCEDURE del_xhit_data(
    ir_rowid      IN  ROWID,       -- 1.ROWID
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_xhit_data'; -- プログラム名
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
    -- HHT入出庫一時表の削除
    DELETE
    FROM   xxcoi_hht_inv_transactions xhit                               -- HHT入出庫一時表
    WHERE  xhit.rowid = ir_rowid                                         -- ROWID
    ;
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
  END del_xhit_data;
--
  /**********************************************************************************
   * Procedure Name   : get_inout_kuragae_data
   * Description      : 入出庫・倉替データ取得 (A-2)
   ***********************************************************************************/
  PROCEDURE get_inout_kuragae_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inout_kuragae_data'; -- プログラム名
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
    cv_hht_program_div_5          CONSTANT VARCHAR2(1) := '5';        -- 入出庫ｼﾞｬｰﾅﾙ処理区分：その他入出庫
    cn_status_pre                 CONSTANT NUMBER      := 0;          -- 処理ステータス：未処理
    cv_business_low_type_27       CONSTANT VARCHAR2(2) := '27';       -- 業態小分類：消化VD
    cv_business_low_type_dummy    CONSTANT VARCHAR2(2) := 'XX';       -- 業態小分類：ダミー
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
    CURSOR inout_kuragae_data_cur
    IS
      SELECT             
              xhit.rowid                  AS xhit_rowid             -- ROWID
            , xhit.invoice_no             AS invoice_no             -- 伝票No
            , xhit.transaction_id         AS transaction_id         -- 入庫情報一時表ID
            , xhit.record_type            AS record_type          -- レコード種別
            , xhit.invoice_type           AS invoice_type         -- 伝票区分
            , xhit.department_flag        AS department_flag      -- 百貨店フラグ
            , xhit.column_no              AS column_no            -- コラム№  
            , xhit.base_code              AS base_code              -- 拠点コード
            , xhit.employee_num           AS employee_num           -- 営業員コード
            , xhit.item_code              AS item_code              -- 品目コード
            , xhit.case_in_quantity       AS case_in_quantity       -- 入数
            , xhit.case_quantity          AS case_quantity          -- ケース数
            , xhit.quantity               AS quantity               -- 本数
            , xhit.total_quantity         AS total_quantity         -- 総数量
            , xhit.inventory_item_id      AS inventory_item_id      -- 品目ID
            , xhit.primary_uom_code       AS primary_uom_code       -- 基準単位
            , xhit.invoice_date           AS invoice_date           -- 伝票日付
            , xhit.outside_subinv_code    AS outside_subinv_code    -- 出庫側保管場所
            , xhit.inside_subinv_code     AS inside_subinv_code     -- 入庫側保管場所
            , xhit.outside_code           AS outside_code           -- 出庫側コード
            , xhit.inside_code            AS inside_code            -- 入庫側コード
            , xhit.outside_base_code      AS outside_base_code      -- 出庫側拠点コード
            , xhit.inside_base_code       AS inside_base_code       -- 入庫側拠点コード
      FROM    
              xxcoi_hht_inv_transactions  xhit                      -- HHT入出庫一時表
      WHERE   
              xhit.hht_program_div = cv_hht_program_div_5           -- 入出庫ジャーナル処理区分(5)
      AND     xhit.status          = cn_status_pre                  -- 処理ステータス
      AND     NVL( xhit.outside_business_low_type,cv_business_low_type_dummy ) <> cv_business_low_type_27
      AND     NVL( xhit.inside_business_low_type,cv_business_low_type_dummy  ) <> cv_business_low_type_27
      ORDER BY
                xhit.base_code
              , xhit.record_type    
              , xhit.invoice_type   
              , xhit.department_flag
              , xhit.invoice_no
              , xhit.column_no
              , xhit.item_code
      FOR UPDATE NOWAIT;
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
    -- =======================
    -- 入出庫・倉替データ取得
    -- =======================
    -- カーソルオープン
    OPEN inout_kuragae_data_cur;
    -- レコード読み込み
    FETCH inout_kuragae_data_cur BULK COLLECT INTO gt_inout_kuragae_data_tab;
    -- 対象件数取得
    gn_target_inout_kuragae_cnt := gt_inout_kuragae_data_tab.COUNT;
    -- カーソルクローズ
    CLOSE inout_kuragae_data_cur;
    -- =======================
    -- 0件判定
    -- =======================
    IF gn_target_inout_kuragae_cnt = 0 THEN
    --
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application_short_name
                      , iv_name         => cv_inout_kuragae_no_data_msg
                    );
      -- 0件メッセージ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --エラーメッセージ
      );
      --
      ov_retcode := cv_status_normal;
      RETURN;
    --
    END IF;
    -- =======================
    -- LOOP処理
    -- =======================
    <<inout_kuragae_data_loop>>
    FOR ln_index IN 1..gn_target_inout_kuragae_cnt LOOP
        -- ===============================================================
        -- 入出庫・倉替データ妥当性チェック処理 (A-3)
        -- ===============================================================
        --
        chk_inout_kuragae_data(
            in_index     => ln_index                 -- ループカウンタ
          , ov_errbuf    => lv_errbuf                -- エラー・メッセージ           --# 固定 #
          , ov_retcode   => lv_retcode               -- リターン・コード             --# 固定 #
          , ov_errmsg    => lv_errmsg                -- ユーザー・エラー・メッセージ --# 固定 #
        );
        -- 正常の場合
        IF (lv_retcode = cv_status_normal) THEN
        --
        -- ===============================================================
        -- 入出庫・倉替データの資材取引OIF追加 (A-4)
        -- ===============================================================
          ins_inout_kuragae_data(
              in_index     => ln_index                 -- ループカウンタ
            , ov_errbuf    => lv_errbuf                -- エラー・メッセージ           --# 固定 #
            , ov_retcode   => lv_retcode               -- リターン・コード             --# 固定 #
            , ov_errmsg    => lv_errmsg                -- ユーザー・エラー・メッセージ --# 固定 #
          );
          -- 
          IF (lv_retcode <> cv_status_normal) THEN
            --(エラー処理)
            RAISE global_api_expt;
            --
          END IF;
        -- ===============================================================
        -- 入出庫・倉替データの HHT入出庫一時表の処理ステータス更新 (A-5)
        -- ===============================================================
          update_xhit_data(
              ir_rowid     => gt_inout_kuragae_data_tab(ln_index).xhit_rowid  -- ROWID
            , ov_errbuf    => lv_errbuf                                       -- エラー・メッセージ           --# 固定 #
            , ov_retcode   => lv_retcode                                      -- リターン・コード             --# 固定 #
            , ov_errmsg    => lv_errmsg                                       -- ユーザー・エラー・メッセージ --# 固定 #
          );
          -- 
          IF (lv_retcode <> cv_status_normal) THEN
            --(エラー処理)
            RAISE global_api_expt;
            --
          END IF;
        --
          -- ----------------
          -- 正常件数カウント
          -- ----------------
          gn_normal_inout_kuragae_cnt := gn_normal_inout_kuragae_cnt + 1;
        -- 警告の場合
        ELSIF (lv_retcode = cv_status_warn) THEN
        -- ===============================================================
        -- 入出庫・倉替データのHHTエラーリスト表追加 (A-6)
        -- ===============================================================
          xxcoi_common_pkg.add_hht_err_list_data(
              iv_base_code           => gt_inout_kuragae_data_tab( ln_index ).base_code    -- 拠点コード
            , iv_origin_shipment     => gt_inout_kuragae_data_tab( ln_index ).outside_code -- 出庫側コード
            , iv_data_name           => gt_file_name                                       -- データ名称
            , id_transaction_date    => gt_inout_kuragae_data_tab( ln_index ).invoice_date -- 取引日
            , iv_entry_number        => gt_inout_kuragae_data_tab( ln_index ).invoice_no   -- 伝票No
            , iv_party_num           => gt_inout_kuragae_data_tab( ln_index ).inside_code  -- 入庫側コード
            , iv_performance_by_code => gt_inout_kuragae_data_tab( ln_index ).employee_num -- 営業員コード
            , iv_item_code           => gt_inout_kuragae_data_tab( ln_index ).item_code    -- 品目コード
            , iv_error_message       => lv_errmsg                                          -- エラー内容
            , ov_errbuf              => lv_errbuf                                          -- エラー・メッセージ
            , ov_retcode             => lv_retcode                                         -- リターン・コード
            , ov_errmsg              => lv_errmsg                                          -- ユーザー・エラー・メッセージ
          );
          -- 
          IF (lv_retcode <> cv_status_normal) THEN
            --(エラー処理)
            RAISE global_api_expt;
            --
          END IF;
        -- ===============================================================
        -- HHT入出庫一時表のエラーレコード削除 (A-7)
        -- ===============================================================
          del_xhit_data(
              ir_rowid     => gt_inout_kuragae_data_tab( ln_index ).xhit_rowid  -- ROWID
            , ov_errbuf    => lv_errbuf                                         -- エラー・メッセージ           --# 固定 #
            , ov_retcode   => lv_retcode                                        -- リターン・コード             --# 固定 #
            , ov_errmsg    => lv_errmsg                                         -- ユーザー・エラー・メッセージ --# 固定 #
          );
          -- 
          IF (lv_retcode <> cv_status_normal) THEN
            --(エラー処理)
            RAISE global_api_expt;
            --
          END IF;
          -- ----------------
          -- 警告件数カウント
          -- ----------------
          gn_warn_inout_kuragae_cnt := gn_warn_inout_kuragae_cnt + 1;
          --
        ELSE
          --(エラー処理)
          RAISE global_api_expt;
          --
        END IF;
    --
    END LOOP inout_kuragae_data_loop;
    --
    
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- ロック取得エラー
    WHEN lock_expt THEN
      -- カーソルがOPENしている場合
      IF ( inout_kuragae_data_cur%ISOPEN ) THEN
        CLOSE inout_kuragae_data_cur;
      END IF;
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application_short_name
                      , iv_name         => cv_hht_table_lock_err_msg
                    );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END get_inout_kuragae_data;
--
--
  /**********************************************************************************
   * Procedure Name   : chk_svd_data
   * Description      : 消化VD補充データ 妥当性チェック (A-10)
   ***********************************************************************************/
  PROCEDURE chk_svd_data(
    in_index      IN  NUMBER,       -- 1.INDEX
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_svd_data'; -- プログラム名
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
    cv_business_low_type_27       CONSTANT VARCHAR2(2) := '27';       -- 業態小分類：消化VD
    cv_business_low_type_dummy    CONSTANT VARCHAR2(2) := 'XX';       -- 業態小分類：ダミー
    -- *** ローカル変数 ***
    lv_key_info             VARCHAR2(500);                            -- KEY情報
    lb_org_acct_period_flg  BOOLEAN;                                  -- 当月在庫会計期間オープンフラグ
    lt_cust_code            hz_cust_accounts.account_number%TYPE;     -- 顧客コード
    ln_count                NUMBER;                                   -- 品目一致件数
    -- *** ローカル・例外 ***
    invalid_value_expt      EXCEPTION;                                -- チェック例外
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
--  変数の初期化
    ln_count := 0;
    --
    -- =========================
    --  1.在庫会計期間チェック
    -- =========================
    xxcoi_common_pkg.org_acct_period_chk(
        in_organization_id => gt_org_id                                    -- 在庫組織ID
      , id_target_date     => gt_svd_data_tab( in_index ).invoice_date     -- 伝票日付
      , ob_chk_result      => lb_org_acct_period_flg                       -- チェック結果
      , ov_errbuf          => lv_errbuf
      , ov_retcode         => lv_retcode
      , ov_errmsg          => lv_errmsg
    );
    -- 在庫会計期間ステータスの取得に失敗した場合
    IF ( lv_retcode != cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_msg_org_acct_period_err
                     , iv_token_name1  => cv_tkn_target_date
                     , iv_token_value1 => TO_CHAR( gt_svd_data_tab( in_index ).invoice_date ,'YYYYMMDD' )
                   );
      RAISE global_api_expt;
    END IF;
    -- 当月在庫会計期間がクローズの場合
    IF ( NOT lb_org_acct_period_flg ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_invoice_date_invalid_err
                     , iv_token_name1  => cv_tkn_proc_date
                     , iv_token_value1 => TO_CHAR( gt_svd_data_tab( in_index ).invoice_date ,'YYYYMMDD' )
                   );
      lv_errbuf := lv_errmsg;
      RAISE invalid_value_expt;
    END IF;
    -- =========================
    --  2.消化VD補充データの必須チェック
    -- =========================
    -- コラム№
    IF ( gt_svd_data_tab( in_index ).column_no IS NULL ) THEN
    --
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_column_no_is_null_err_msg );
      lv_errbuf := lv_errmsg;
      RAISE invalid_value_expt;
    --
    END IF;
    -- 単価
    IF ( gt_svd_data_tab( in_index ).unit_price IS NULL ) THEN
    --
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_up_is_null_err_mag );
      lv_errbuf := lv_errmsg;
      RAISE invalid_value_expt;
    --
    END IF;
    -- =========================
    --  3.消化VD補充データの品目一致チェック
    -- =========================
    -- 顧客コードの設定
    IF ( NVL( gt_svd_data_tab( in_index ).outside_business_low_type , cv_business_low_type_dummy )
            = cv_business_low_type_27 ) 
    THEN
      lt_cust_code := gt_svd_data_tab( in_index ).outside_code;
    ELSE
      lt_cust_code := gt_svd_data_tab( in_index ).inside_code;
    END IF;
-- == 2009/11/25 V1.2 Deleted START ===============================================================
---- == 2009/11/24 V1.1 Added START ===============================================================
--    --画面入力されたデータはVDコラムマスタとのチェックを行わない
--    IF (SUBSTRB(gt_svd_data_tab(in_index).invoice_no, 1, 1) <> 'E') THEN
---- == 2009/11/24 V1.1 Added END   ===============================================================
--      -- -------------
--      -- (1)当月の場合
--      -- -------------
--      IF ( TRUNC(gt_svd_data_tab( in_index ).invoice_date,'MM') = TRUNC(gd_process_date,'MM') ) THEN
--      --
--        SELECT  COUNT(1)
--        INTO    ln_count
--        FROM    hz_cust_accounts hca,
--                xxcoi_mst_vd_column xmvc
--        WHERE   hca.cust_account_id = xmvc.customer_id 
--        AND     hca.account_number  = lt_cust_code
--        AND     xmvc.column_no      = gt_svd_data_tab( in_index ).column_no
--        AND     xmvc.item_id        = gt_svd_data_tab( in_index ).inventory_item_id
--        AND     ROWNUM <= 1;
--        -- 一致件数が0の場合
--        IF ln_count = 0 THEN
--          lv_errmsg := xxccp_common_pkg.get_msg(
--                           iv_application  => cv_application_short_name
--                         , iv_name         => cv_vd_item_err_msg );
--          lv_errbuf := lv_errmsg;
--          RAISE invalid_value_expt;
--        END IF;
--      -- -------------
--      -- (2)前月の場合
--      -- -------------
--      ELSE
--      --
--        SELECT  COUNT(1)
--        INTO    ln_count
--        FROM    hz_cust_accounts hca,
--                xxcoi_mst_vd_column xmvc
--        WHERE   hca.cust_account_id     = xmvc.customer_id 
--        AND     hca.account_number      = lt_cust_code
--        AND     xmvc.column_no          = gt_svd_data_tab( in_index ).column_no
--        AND     xmvc.last_month_item_id = gt_svd_data_tab( in_index ).inventory_item_id
--        AND     ROWNUM <= 1;
--        -- 一致件数が0の場合
--        IF ln_count = 0 THEN
--          lv_errmsg := xxccp_common_pkg.get_msg(
--                           iv_application  => cv_application_short_name
--                         , iv_name         => cv_vd_last_month_item_err_msg );
--          lv_errbuf := lv_errmsg;
--          RAISE invalid_value_expt;
--        END IF;
--      --
--      END IF;
---- == 2009/11/24 V1.1 Added START ===============================================================
--    END IF;
---- == 2009/11/24 V1.1 Added END   ===============================================================
-- == 2009/11/25 V1.2 Deleted END   ===============================================================
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** 不正値例外ハンドラ ***
    WHEN invalid_value_expt THEN
      -- KEY情報取得
      lv_key_info := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_key_info
                     , iv_token_name1  => cv_tkn_base_code
                     , iv_token_value1 => gt_svd_data_tab( in_index ).base_code
                     , iv_token_name2  => cv_tkn_record_type
                     , iv_token_value2 => gt_svd_data_tab( in_index ).record_type
                     , iv_token_name3  => cv_tkn_invoice_type
                     , iv_token_value3 => gt_svd_data_tab( in_index ).invoice_type
                     , iv_token_name4  => cv_tkn_dept_flag
                     , iv_token_value4 => gt_svd_data_tab( in_index ).department_flag
                     , iv_token_name5  => cv_tkn_invoice_no
                     , iv_token_value5 => gt_svd_data_tab( in_index ).invoice_no
                     , iv_token_name6  => cv_tkn_column_no
                     , iv_token_value6 => gt_svd_data_tab( in_index ).column_no
                     , iv_token_name7  => cv_tkn_item_code
                     , iv_token_value7 => gt_svd_data_tab( in_index ).item_code );
      --
      FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
         , buff   => lv_key_info || lv_errmsg );
      --
      FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
         , buff   => lv_key_info || lv_errbuf );
      --
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;                                             --# 任意 #
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
  END chk_svd_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_temp_svd_data
   * Description      : 消化VD補充データの一時表追加 (A-11)
   ***********************************************************************************/
  PROCEDURE ins_temp_svd_data(
    in_index      IN  NUMBER,       -- 1.INDEX
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_temp_svd_data'; -- プログラム名
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
    -- *** ローカル変数 ***
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
    -- 消化VD補充ワークテーブルへ登録
    INSERT INTO xxcoi_tmp_svd_transactions(
       item_id                                                                -- 品目ID
      ,primary_uom_code                                                       -- 基準単位コード
      ,invoice_date                                                           -- 伝票日付
      ,outside_subinv_code                                                    -- 出庫側保管場所コード
      ,inside_subinv_code                                                     -- 入庫側保管場所コード
      ,total_quantity                                                         -- 総数量
    )
    VALUES(
       gt_svd_data_tab( in_index ).inventory_item_id                          -- 品目ID
      ,gt_svd_data_tab( in_index ).primary_uom_code                           -- 基準単位コード
      ,gt_svd_data_tab( in_index ).invoice_date                               -- 伝票日付
      ,gt_svd_data_tab( in_index ).outside_subinv_code                        -- 出庫側保管場所コード
      ,gt_svd_data_tab( in_index ).inside_subinv_code                         -- 入庫側保管場所コード
      ,gt_svd_data_tab( in_index ).total_quantity                             -- 総数量
    );
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
  END ins_temp_svd_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_oif_svd_data
   * Description      : 消化VD補充データの資材取引OIF追加 (A-15)
   ***********************************************************************************/
  PROCEDURE ins_oif_svd_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_oif_svd_data'; -- プログラム名
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
    cv_process_flag              CONSTANT VARCHAR2(1) := '1';  -- プロセスフラグ   1：処理対象
    cv_transaction_mode          CONSTANT VARCHAR2(1) := '3';  -- 取引モード       3：バックグラウンド
    cv_source_head_id            CONSTANT VARCHAR2(1) := '1';  -- ソースヘッダーID 1：固定
    cv_source_line_id            CONSTANT VARCHAR2(1) := '1';  -- ソースラインID   1：固定
    -- *** ローカル変数 ***
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
    -- =======================
    -- 資材取引OIFへ登録
    -- =======================
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
    SELECT
        cv_process_flag                                                          -- プロセスフラグ
      , cv_transaction_mode                                                      -- 取引モード
      , cv_pkg_name                                                              -- ソースコード
      , cv_source_head_id                                                        -- ソースヘッダーID
      , cv_source_line_id                                                        -- ソースラインID
      , xtst.item_id                                                             -- 品目ID
      , gt_org_id                                                                -- 在庫組織ID
      , ( SIGN( SUM(xtst.total_quantity) ) * SUM(xtst.total_quantity) )          -- 取引数量
      , ( SIGN( SUM(xtst.total_quantity) ) * SUM(xtst.total_quantity) )          -- 基準単位数量
      , xtst.primary_uom_code                                                    -- 取引単位
      , xtst.invoice_date                                                        -- 取引日
      , DECODE( SIGN( SUM(xtst.total_quantity) )
                    , 1 , xtst.outside_subinv_code
                        , xtst.inside_subinv_code  )                             -- 保管場所コード
      , gt_tran_type_id_svd                                                      -- 取引タイプID
      , DECODE( SIGN( SUM(xtst.total_quantity) )
                    , 1 , xtst.inside_subinv_code
                        , xtst.outside_subinv_code )                             -- 相手先保管場所コード
      , gt_org_id                                                                -- 相手先在庫組織ID
      , cn_created_by                                                            -- 作成者
      , cd_creation_date                                                         -- 作成日
      , cn_last_updated_by                                                       -- 最終更新者
      , cd_last_update_date                                                      -- 最終更新日
      , cn_last_update_login                                                     -- 最終更新ログイン
      , cn_request_id                                                            -- 要求ID
      , cn_program_application_id                                                -- プログラムアプリケーションID
      , cn_program_id                                                            -- プログラムID
      , cd_program_update_date                                                   -- プログラム更新日
    FROM
          xxcoi_tmp_svd_transactions xtst
    HAVING    SUM(xtst.total_quantity) <> 0
    GROUP BY  xtst.item_id
            , xtst.primary_uom_code
            , xtst.invoice_date
            , xtst.outside_subinv_code
            , xtst.inside_subinv_code
    ;
    -- 登録件数を取得
    gn_oif_ins_svd_cnt := SQL%ROWCOUNT;
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
  END ins_oif_svd_data;
--
  /**********************************************************************************
   * Procedure Name   : get_svd_data
   * Description      : 消化VD補充データ取得 (A-9)
   ***********************************************************************************/
  PROCEDURE get_svd_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_svd_data'; -- プログラム名
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
    cv_hht_program_div_5          CONSTANT VARCHAR2(1) := '5';        -- 入出庫ｼﾞｬｰﾅﾙ処理区分：その他入出庫
    cn_status_pre                 CONSTANT NUMBER      := 0;          -- 処理ステータス：未処理
    cv_business_low_type_27       CONSTANT VARCHAR2(2) := '27';       -- 業態小分類：消化VD
    cv_business_low_type_dummy    CONSTANT VARCHAR2(2) := 'XX';       -- 業態小分類：ダミー
--
    -- *** ローカル変数 ***
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
    CURSOR svd_cur
    IS
      SELECT             
              xhit.rowid                      AS xhit_rowid                 -- ROWID
            , xhit.invoice_no                 AS invoice_no                 -- 伝票No
            , xhit.transaction_id             AS transaction_id             -- 入庫情報一時表ID
            , xhit.record_type                AS record_type                -- レコード種別
            , xhit.invoice_type               AS invoice_type               -- 伝票区分
            , xhit.department_flag            AS department_flag            -- 百貨店フラグ
            , xhit.column_no                  AS column_no                  -- コラム№  
            , xhit.unit_price                 AS unit_price                 -- 単価
            , xhit.base_code                  AS base_code                  -- 拠点コード
            , xhit.employee_num               AS employee_num               -- 営業員コード
            , xhit.item_code                  AS item_code                  -- 品目コード
            , xhit.case_in_quantity           AS case_in_quantity           -- 入数
            , xhit.case_quantity              AS case_quantity              -- ケース数
            , xhit.quantity                   AS quantity                   -- 本数
            , xhit.total_quantity             AS total_quantity             -- 総数量
            , xhit.inventory_item_id          AS inventory_item_id          -- 品目ID
            , xhit.primary_uom_code           AS primary_uom_code           -- 基準単位
            , xhit.invoice_date               AS invoice_date               -- 伝票日付
            , xhit.outside_subinv_code        AS outside_subinv_code        -- 出庫側保管場所
            , xhit.inside_subinv_code         AS inside_subinv_code         -- 入庫側保管場所
            , xhit.outside_code               AS outside_code               -- 出庫側コード
            , xhit.inside_code                AS inside_code                -- 入庫側コード
            , xhit.outside_base_code          AS outside_base_code          -- 出庫側拠点コード
            , xhit.inside_base_code           AS inside_base_code           -- 入庫側拠点コード
            , xhit.outside_business_low_type  AS outside_business_low_type  -- 出庫側業態小分類
            , xhit.inside_business_low_type   AS inside_business_low_type   -- 入庫側業態小分類
      FROM    
              xxcoi_hht_inv_transactions  xhit                              -- HHT入出庫一時表
      WHERE   
              xhit.hht_program_div = cv_hht_program_div_5                   -- 入出庫ジャーナル処理区分(5)
      AND     xhit.status          = cn_status_pre                          -- 処理ステータス(0)
      AND     xhit.consume_vd_flag = cv_flag_y                              -- 消化VD補充対象フラグ(Y)
      AND     ( NVL( xhit.outside_business_low_type,cv_business_low_type_dummy ) = cv_business_low_type_27
                OR NVL( xhit.inside_business_low_type,cv_business_low_type_dummy  ) = cv_business_low_type_27 )
      ORDER BY
                xhit.base_code
              , xhit.record_type    
              , xhit.invoice_type   
              , xhit.department_flag
              , xhit.invoice_no
              , xhit.column_no
              , xhit.item_code
      FOR UPDATE NOWAIT;
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
--  変数の初期化
    -- =======================
    -- 入出庫・倉替データ取得
    -- =======================
    -- カーソルオープン
    OPEN svd_cur;
    -- レコード読み込み
    FETCH svd_cur BULK COLLECT INTO gt_svd_data_tab;
    -- 対象件数取得
    gn_target_svd_cnt := gt_svd_data_tab.COUNT;
    -- カーソルクローズ
    CLOSE svd_cur;
    -- =======================
    -- 0件判定
    -- =======================
    IF gn_target_svd_cnt = 0 THEN
    --
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application_short_name
                      , iv_name         => cv_svd_no_data_msg
                    );
      -- 0件メッセージ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --エラーメッセージ
      );
      --
      ov_retcode := cv_status_normal;
      RETURN;
    --
    END IF;
    -- =======================
    -- LOOP処理
    -- =======================
    <<svd_data_loop>>
    FOR ln_index IN 1..gn_target_svd_cnt LOOP

        -- ===============================================================
        -- 消化VD補充データ 妥当性チェック (A-10)
        -- ===============================================================
        --
        chk_svd_data(
            in_index     => ln_index                 -- ループカウンタ
          , ov_errbuf    => lv_errbuf                -- エラー・メッセージ           --# 固定 #
          , ov_retcode   => lv_retcode               -- リターン・コード             --# 固定 #
          , ov_errmsg    => lv_errmsg                -- ユーザー・エラー・メッセージ --# 固定 #
        );
        -- 正常の場合
        IF (lv_retcode = cv_status_normal) THEN
        -- ===============================================================
        -- 消化VD補充データの一時表追加 (A-11)
        -- ===============================================================
          ins_temp_svd_data(
              in_index     => ln_index                 -- ループカウンタ
            , ov_errbuf    => lv_errbuf                -- エラー・メッセージ           --# 固定 #
            , ov_retcode   => lv_retcode               -- リターン・コード             --# 固定 #
            , ov_errmsg    => lv_errmsg                -- ユーザー・エラー・メッセージ --# 固定 #
          );
          -- 
          IF (lv_retcode <> cv_status_normal) THEN
            --(エラー処理)
            RAISE global_api_expt;
            --
          END IF;
        -- ===============================================================
        -- 消化VD補充の HHT入出庫一時表の処理ステータス更新 (A-12)
        -- ===============================================================
          update_xhit_data(
              ir_rowid     => gt_svd_data_tab( ln_index ).xhit_rowid   -- ROWID
            , ov_errbuf    => lv_errbuf                                -- エラー・メッセージ           --# 固定 #
            , ov_retcode   => lv_retcode                               -- リターン・コード             --# 固定 #
            , ov_errmsg    => lv_errmsg                                -- ユーザー・エラー・メッセージ --# 固定 #
          );
          -- 
          IF (lv_retcode <> cv_status_normal) THEN
            --(エラー処理)
            RAISE global_api_expt;
            --
          END IF;
          -- ----------------
          -- 正常件数カウント
          -- ----------------
          gn_normal_svd_cnt := gn_normal_svd_cnt + 1;
        --
        -- 警告の場合
        ELSIF (lv_retcode = cv_status_warn) THEN
        -- ===============================================================
        -- 消化VD補充のHHTエラーリスト表追加 (A-13)
        -- ===============================================================
          xxcoi_common_pkg.add_hht_err_list_data(
              iv_base_code           => gt_svd_data_tab( ln_index ).base_code    -- 拠点コード
            , iv_origin_shipment     => gt_svd_data_tab( ln_index ).outside_code -- 出庫側コード
            , iv_data_name           => gt_file_name                             -- データ名称
            , id_transaction_date    => gt_svd_data_tab( ln_index ).invoice_date -- 取引日
            , iv_entry_number        => gt_svd_data_tab( ln_index ).invoice_no   -- 伝票No
            , iv_party_num           => gt_svd_data_tab( ln_index ).inside_code  -- 入庫側コード
            , iv_performance_by_code => gt_svd_data_tab( ln_index ).employee_num -- 営業員コード
            , iv_item_code           => gt_svd_data_tab( ln_index ).item_code    -- 品目コード
            , iv_error_message       => lv_errmsg                                -- エラー内容
            , ov_errbuf              => lv_errbuf                                -- エラー・メッセージ
            , ov_retcode             => lv_retcode                               -- リターン・コード
            , ov_errmsg              => lv_errmsg                                -- ユーザー・エラー・メッセージ
          );
          -- 
          IF (lv_retcode <> cv_status_normal) THEN
            --(エラー処理)
            RAISE global_api_expt;
            --
          END IF;
        -- ===============================================================
        -- HHT入出庫一時表のエラーレコード削除 (A-14)
        -- ===============================================================
          del_xhit_data(
              ir_rowid     => gt_svd_data_tab( ln_index ).xhit_rowid    -- ROWID
            , ov_errbuf    => lv_errbuf                                 -- エラー・メッセージ           --# 固定 #
            , ov_retcode   => lv_retcode                                -- リターン・コード             --# 固定 #
            , ov_errmsg    => lv_errmsg                                 -- ユーザー・エラー・メッセージ --# 固定 #
          );
          -- 
          IF (lv_retcode <> cv_status_normal) THEN
            --(エラー処理)
            RAISE global_api_expt;
            --
          END IF;
          -- ----------------
          -- 警告件数カウント
          -- ----------------
          gn_warn_svd_cnt := gn_warn_svd_cnt + 1;
        -- 異常の場合
        ELSE
          --
          RAISE global_api_expt;
          --
        END IF;
    --
    END LOOP svd_data_loop;
    -- ===============================================================
    -- 消化VD補充データの資材取引OIF追加 (A-15)
    -- ===============================================================
    ins_oif_svd_data(
        ov_errbuf    => lv_errbuf                -- エラー・メッセージ           --# 固定 #
      , ov_retcode   => lv_retcode               -- リターン・コード             --# 固定 #
      , ov_errmsg    => lv_errmsg                -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 
    IF (lv_retcode <> cv_status_normal) THEN
      --(エラー処理)
      RAISE global_api_expt;
      --
    END IF;    
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- ロック取得エラー
    WHEN lock_expt THEN
      -- カーソルがOPENしている場合
      IF ( svd_cur%ISOPEN ) THEN
        CLOSE svd_cur;
      END IF;
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application_short_name
                      , iv_name         => cv_hht_table_lock_err_msg
                    );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END get_svd_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_item_conv_data
   * Description      : 商品振替データ妥当性チェック (A-18)
   ***********************************************************************************/
  PROCEDURE chk_item_conv_data(
    in_index      IN  NUMBER,       -- 1.INDEX
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_item_conv_data'; -- プログラム名
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
    cv_inv_acct_type_item_conv    CONSTANT VARCHAR2(2) := '14';      -- 入出庫勘定区分：商品振替(14)
    -- *** ローカル変数 ***
    lv_key_info                            VARCHAR2(500);            -- KEY情報
    lb_org_acct_period_flg                 BOOLEAN;                  -- 当月在庫会計期間オープンフラグ
    -- *** ローカル・例外 ***
    invalid_value_expt                     EXCEPTION;                -- チェック例外
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
    -- =========================
    --  1.在庫会計期間チェック
    -- =========================
    xxcoi_common_pkg.org_acct_period_chk(
        in_organization_id => gt_org_id                                      -- 在庫組織ID
      , id_target_date     => gt_item_conv_data_tab( in_index ).invoice_date  -- 伝票日付
      , ob_chk_result      => lb_org_acct_period_flg                         -- チェック結果
      , ov_errbuf          => lv_errbuf
      , ov_retcode         => lv_retcode
      , ov_errmsg          => lv_errmsg
    );
    -- 在庫会計期間ステータスの取得に失敗した場合
    IF ( lv_retcode != cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_msg_org_acct_period_err
                     , iv_token_name1  => cv_tkn_target_date
                     , iv_token_value1 => TO_CHAR( gt_item_conv_data_tab( in_index ).invoice_date ,'YYYYMMDD' )
                   );
      RAISE global_api_expt;
    END IF;
    -- 当月在庫会計期間がクローズの場合
    IF ( NOT lb_org_acct_period_flg ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_invoice_date_invalid_err
                     , iv_token_name1  => cv_tkn_proc_date
                     , iv_token_value1 => TO_CHAR( gt_item_conv_data_tab( in_index ).invoice_date ,'YYYYMMDD' )
                   );
      lv_errbuf := lv_errmsg;
      RAISE invalid_value_expt;
    END IF;
    -- =========================
    --  2.勘定科目別名の取得 (A-19)
    --  変換後の拠点コードより取得
    -- =========================
    gt_transaction_source_id := xxcoi_common_pkg.get_disposition_id(
                                     iv_inv_account_kbn    => cv_inv_acct_type_item_conv                            -- 入出庫勘定区分 14:商品振替
                                   , iv_dept_code          => gt_item_conv_data_tab( in_index ).outside_base_code   -- 出庫側拠点コード
                                   , in_organization_id    => gt_org_id                                             -- 在庫組織ID
                                 );
    --
    IF gt_transaction_source_id IS NULL THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_get_disposition_id_err_msg
                     , iv_token_name1  => cv_tkn_base_code
                     , iv_token_value1 => gt_item_conv_data_tab( in_index ).outside_base_code
                     , iv_token_name2  => cv_tkn_acct_type
                     , iv_token_value2 => cv_inv_acct_type_item_conv
                   );
      lv_errbuf := lv_errmsg;
      RAISE invalid_value_expt;
    END IF;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** 不正値例外ハンドラ ***
    WHEN invalid_value_expt THEN
      -- KEY情報取得
      lv_key_info := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_key_info
                     , iv_token_name1  => cv_tkn_base_code
                     , iv_token_value1 => gt_item_conv_data_tab( in_index ).base_code
                     , iv_token_name2  => cv_tkn_record_type
                     , iv_token_value2 => gt_item_conv_data_tab( in_index ).record_type
                     , iv_token_name3  => cv_tkn_invoice_type
                     , iv_token_value3 => gt_item_conv_data_tab( in_index ).invoice_type
                     , iv_token_name4  => cv_tkn_dept_flag
                     , iv_token_value4 => gt_item_conv_data_tab( in_index ).department_flag
                     , iv_token_name5  => cv_tkn_invoice_no
                     , iv_token_value5 => gt_item_conv_data_tab( in_index ).invoice_no
                     , iv_token_name6  => cv_tkn_column_no
                     , iv_token_value6 => gt_item_conv_data_tab( in_index ).column_no
                     , iv_token_name7  => cv_tkn_item_code
                     , iv_token_value7 => gt_item_conv_data_tab( in_index ).item_code );
      --
      FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
         , buff   => lv_key_info || lv_errmsg );
      --
      FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
         , buff   => lv_key_info || lv_errbuf );
      --
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;                                             --# 任意 #
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
  END chk_item_conv_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_oif_item_conv_data
   * Description      : 商品振替データの資材取引OIF追加 (A-20)
   ***********************************************************************************/
  PROCEDURE ins_oif_item_conv_data(
    in_index      IN  NUMBER,       -- 1.INDEX
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_oif_item_conv_data'; -- プログラム名
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
    cv_new_item                  CONSTANT VARCHAR2(1) := '1';  -- 商品振替区分   1：新商品
    cv_old_item                  CONSTANT VARCHAR2(1) := '2';  -- 商品振替区分   2：旧商品
--
    -- *** ローカル変数 ***
    ln_tran_qty                  mtl_transactions_interface.transaction_quantity%TYPE;   -- 取引数量
    lt_tran_type_id              mtl_transaction_types.transaction_type_id%TYPE;         -- 取引タイプID
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
--  変数の初期化
    ln_tran_qty := 0;
    lt_tran_type_id := NULL;
    -- =======================
    -- 取引タイプ/数量符号判定
    -- =======================
    -- 「商品振替(新)」かつ正数
    IF gt_item_conv_data_tab( in_index ).item_convert_div = cv_new_item
          AND SIGN( gt_item_conv_data_tab( in_index ).total_quantity ) = 1
    THEN
      -- 商品振替(新)
      lt_tran_type_id := gt_tran_type_id_item_conv_new;
      -- 取引数(正)
      ln_tran_qty     := gt_item_conv_data_tab( in_index ).total_quantity;
      --
    -- 「商品振替(新)」かつ負数
    ELSIF gt_item_conv_data_tab( in_index ).item_convert_div = cv_new_item
          AND SIGN( gt_item_conv_data_tab( in_index ).total_quantity ) = -1
    THEN
      -- 商品振替(旧)
      lt_tran_type_id := gt_tran_type_id_item_conv_old;
      -- 取引数(負)
      ln_tran_qty     := gt_item_conv_data_tab( in_index ).total_quantity;
      --
    -- 「商品振替(旧)」かつ正数
    ELSIF gt_item_conv_data_tab( in_index ).item_convert_div = cv_old_item
          AND SIGN( gt_item_conv_data_tab( in_index ).total_quantity ) = 1
    THEN
      -- 商品振替(旧)
      lt_tran_type_id := gt_tran_type_id_item_conv_old;
      -- 取引数(負)
      ln_tran_qty     := gt_item_conv_data_tab( in_index ).total_quantity * (-1);
      --
    -- 「商品振替(旧)」かつ負数
    ELSE
      -- 商品振替(新)
      lt_tran_type_id := gt_tran_type_id_item_conv_new;
      -- 取引数(正)
      ln_tran_qty     := gt_item_conv_data_tab( in_index ).total_quantity * (-1);
      --
    END IF;
    -- =======================
    -- 資材取引OIFへ登録
    -- =======================
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
      , transaction_source_id                                                    -- 取引ソースID
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
      , gt_item_conv_data_tab( in_index ).transaction_id                         -- ソースヘッダーID
      , cv_source_line_id                                                        -- ソースラインID
      , gt_item_conv_data_tab( in_index ).inventory_item_id                      -- 品目ID
      , gt_org_id                                                                -- 在庫組織ID
      , ln_tran_qty                                                              -- 取引数量
      , ln_tran_qty                                                              -- 基準単位数量
      , gt_item_conv_data_tab( in_index ).primary_uom_code                       -- 取引単位
      , gt_item_conv_data_tab( in_index ).invoice_date                           -- 取引日
      , gt_item_conv_data_tab( in_index ).outside_subinv_code                    -- 保管場所コード
      , lt_tran_type_id                                                          -- 取引タイプID
      , NULL                                                                     -- 相手先保管場所コード
      , NULL                                                                     -- 相手先在庫組織ID
      , gt_transaction_source_id                                                 -- 取引ソースID
      , gt_item_conv_data_tab( in_index ).invoice_no                             -- 伝票No
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
  END ins_oif_item_conv_data;
--
  /**********************************************************************************
   * Procedure Name   : get_item_conv_data
   * Description      : 商品振替データ取得 (A-17)
   ***********************************************************************************/
  PROCEDURE get_item_conv_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_item_conv_data'; -- プログラム名
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
    cv_hht_program_div_3          CONSTANT VARCHAR2(1) := '3';        -- 入出庫ｼﾞｬｰﾅﾙ処理区分：商品振替(3)
    cn_status_pre                 CONSTANT NUMBER := 0;               -- 処理ステータス：未処理(0)
--
    -- *** ローカル変数 ***
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
    CURSOR item_conv_cur
    IS
      SELECT             
              xhit.rowid                      AS xhit_rowid                 -- ROWID
            , xhit.invoice_no                 AS invoice_no                 -- 伝票No
            , xhit.transaction_id             AS transaction_id             -- 入庫情報一時表ID
            , xhit.record_type                AS record_type                -- レコード種別
            , xhit.invoice_type               AS invoice_type               -- 伝票区分
            , xhit.department_flag            AS department_flag            -- 百貨店フラグ
            , xhit.column_no                  AS column_no                  -- コラム№  
            , xhit.base_code                  AS base_code                  -- 拠点コード
            , xhit.employee_num               AS employee_num               -- 営業員コード
            , xhit.item_code                  AS item_code                  -- 品目コード
            , xhit.case_in_quantity           AS case_in_quantity           -- 入数
            , xhit.case_quantity              AS case_quantity              -- ケース数
            , xhit.quantity                   AS quantity                   -- 本数
            , xhit.total_quantity             AS total_quantity             -- 総数量
            , xhit.inventory_item_id          AS inventory_item_id          -- 品目ID
            , xhit.primary_uom_code           AS primary_uom_code           -- 基準単位
            , xhit.invoice_date               AS invoice_date               -- 伝票日付
            , xhit.outside_subinv_code        AS outside_subinv_code        -- 出庫側保管場所
            , xhit.inside_subinv_code         AS inside_subinv_code         -- 入庫側保管場所
            , xhit.outside_code               AS outside_code               -- 出庫側コード
            , xhit.inside_code                AS inside_code                -- 入庫側コード
            , xhit.outside_base_code          AS outside_base_code          -- 出庫側拠点コード
            , xhit.inside_base_code           AS inside_base_code           -- 入庫側拠点コード
            , xhit.item_convert_div           AS item_convert_div           -- 商品振替区分
      FROM    
              xxcoi_hht_inv_transactions  xhit                      -- HHT入出庫一時表
      WHERE   
              xhit.hht_program_div = cv_hht_program_div_3           -- 入出庫ジャーナル処理区分(3)
      AND     xhit.status          = cn_status_pre                  -- 処理ステータス
      ORDER BY 
                xhit.base_code
              , xhit.record_type    
              , xhit.invoice_type   
              , xhit.department_flag
              , xhit.invoice_no
              , xhit.column_no
              , xhit.item_code
      FOR UPDATE NOWAIT;
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
    -- =======================
    -- 商品振替データ取得
    -- =======================
    -- カーソルオープン
    OPEN item_conv_cur;
    -- レコード読み込み
    FETCH item_conv_cur BULK COLLECT INTO gt_item_conv_data_tab;
    -- 対象件数取得
    gn_target_item_conv_cnt := gt_item_conv_data_tab.COUNT;
    -- カーソルクローズ
    CLOSE item_conv_cur;
    -- =======================
    -- 0件判定
    -- =======================
    IF gn_target_item_conv_cnt = 0 THEN
    --
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application_short_name
                      , iv_name         => cv_item_conv_no_data_msg
                    );
      -- 0件メッセージ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --エラーメッセージ
      );
      --
      ov_retcode := cv_status_normal;
      RETURN;
    --
    END IF;
    -- =======================
    -- LOOP処理
    -- =======================
    <<item_conv_data_loop>>
    FOR ln_index IN 1..gn_target_item_conv_cnt LOOP
        -- ===============================================================
        -- 商品振替データ 妥当性チェック (A-18)
        -- 勘定科目別名の取得(A-19)
        -- ===============================================================
        --
        chk_item_conv_data(
            in_index     => ln_index                 -- ループカウンタ
          , ov_errbuf    => lv_errbuf                -- エラー・メッセージ           --# 固定 #
          , ov_retcode   => lv_retcode               -- リターン・コード             --# 固定 #
          , ov_errmsg    => lv_errmsg                -- ユーザー・エラー・メッセージ --# 固定 #
        );
        -- 正常の場合
        IF (lv_retcode = cv_status_normal) THEN
        -- ===============================================================
        -- 商品振替データの一時表追加 (A-20)
        -- ===============================================================
          ins_oif_item_conv_data(
              in_index     => ln_index                 -- ループカウンタ
            , ov_errbuf    => lv_errbuf                -- エラー・メッセージ           --# 固定 #
            , ov_retcode   => lv_retcode               -- リターン・コード             --# 固定 #
            , ov_errmsg    => lv_errmsg                -- ユーザー・エラー・メッセージ --# 固定 #
          );
          -- 
          IF (lv_retcode <> cv_status_normal) THEN
            --(エラー処理)
            RAISE global_api_expt;
            --
          END IF;
        -- ===============================================================
        -- 商品振替の HHT入出庫一時表の処理ステータス更新 (A-21)
        -- ===============================================================
          update_xhit_data(
              ir_rowid     => gt_item_conv_data_tab( ln_index ).xhit_rowid   -- ROWID
            , ov_errbuf    => lv_errbuf                                -- エラー・メッセージ           --# 固定 #
            , ov_retcode   => lv_retcode                               -- リターン・コード             --# 固定 #
            , ov_errmsg    => lv_errmsg                                -- ユーザー・エラー・メッセージ --# 固定 #
          );
          -- 
          IF (lv_retcode <> cv_status_normal) THEN
            --(エラー処理)
            RAISE global_api_expt;
            --
          END IF;
          -- ----------------
          -- 正常件数カウント
          -- ----------------
          gn_normal_item_conv_cnt := gn_normal_item_conv_cnt +1;
        -- 警告の場合
        ELSIF (lv_retcode = cv_status_warn) THEN
        -- ===============================================================
        -- 商品振替のHHTエラーリスト表追加 (A-22)
        -- ===============================================================
          xxcoi_common_pkg.add_hht_err_list_data(
              iv_base_code           => gt_item_conv_data_tab( ln_index ).base_code    -- 拠点コード
            , iv_origin_shipment     => gt_item_conv_data_tab( ln_index ).outside_code -- 出庫側コード
            , iv_data_name           => gt_file_name                             -- データ名称
            , id_transaction_date    => gt_item_conv_data_tab( ln_index ).invoice_date -- 取引日
            , iv_entry_number        => gt_item_conv_data_tab( ln_index ).invoice_no   -- 伝票No
            , iv_party_num           => gt_item_conv_data_tab( ln_index ).inside_code  -- 入庫側コード
            , iv_performance_by_code => gt_item_conv_data_tab( ln_index ).employee_num -- 営業員コード
            , iv_item_code           => gt_item_conv_data_tab( ln_index ).item_code    -- 品目コード
            , iv_error_message       => lv_errmsg                                -- エラー内容
            , ov_errbuf              => lv_errbuf                                -- エラー・メッセージ
            , ov_retcode             => lv_retcode                               -- リターン・コード
            , ov_errmsg              => lv_errmsg                                -- ユーザー・エラー・メッセージ
          );
          -- 
          IF (lv_retcode <> cv_status_normal) THEN
            --(エラー処理)
            RAISE global_api_expt;
            --
          END IF;
        -- ===============================================================
        -- HHT入出庫一時表のエラーレコード削除 (A-23)
        -- ===============================================================
          del_xhit_data(
              ir_rowid     => gt_item_conv_data_tab( ln_index ).xhit_rowid    -- ROWID
            , ov_errbuf    => lv_errbuf                                 -- エラー・メッセージ           --# 固定 #
            , ov_retcode   => lv_retcode                                -- リターン・コード             --# 固定 #
            , ov_errmsg    => lv_errmsg                                 -- ユーザー・エラー・メッセージ --# 固定 #
          );
          -- 
          IF (lv_retcode <> cv_status_normal) THEN
            --(エラー処理)
            RAISE global_api_expt;
            --
          END IF;
          -- ----------------
          -- 警告件数カウント
          -- ----------------
          gn_warn_item_conv_cnt := gn_warn_item_conv_cnt + 1;
        ELSE
          --(エラー処理)
          RAISE global_api_expt;
          --
        END IF;
    --
    END LOOP item_conv_data_loop;
    --
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- ロック取得エラー
    WHEN lock_expt THEN
      -- カーソルがOPENしている場合
      IF ( item_conv_cur%ISOPEN ) THEN
        CLOSE item_conv_cur;
      END IF;
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application_short_name
                      , iv_name         => cv_hht_table_lock_err_msg
                    );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END get_item_conv_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
--
    -- *** ローカル変数 ***
    lv_message_code    VARCHAR2(100);   -- 終了メッセージコード
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
    -- 入出庫・倉替の初期化
    gn_target_inout_kuragae_cnt := 0;
    gn_normal_inout_kuragae_cnt := 0;
    gn_warn_inout_kuragae_cnt   := 0;
    gn_error_inout_kuragae_cnt  := 0;
    -- 消化VDの初期化
    gn_target_svd_cnt  := 0;
    gn_normal_svd_cnt  := 0;
    gn_warn_svd_cnt    := 0;
    gn_error_svd_cnt   := 0;
    gn_oif_ins_svd_cnt := 0;
    -- 商品振替の初期化
    gn_target_item_conv_cnt := 0;
    gn_normal_item_conv_cnt := 0;
    gn_warn_item_conv_cnt   := 0;
    gn_error_item_conv_cnt  := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===========================================
    -- 初期処理 (A-1)
    -- ===========================================
    init(
        lv_errbuf            -- エラー・メッセージ           --# 固定 #
      , lv_retcode           -- リターン・コード             --# 固定 #
      , lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
        -- エラー件数のカウントアップ
        gn_error_cnt := gn_error_cnt + 1;
        -- Initのエラーは処理中断
        RAISE global_process_expt;
    END IF;
    --
    --*********************************************
    --***             入出庫・倉替              ***
    --*********************************************
    --
    -- =======================
    -- 入出庫・倉替の開始処理
    -- =======================
    --SAVE POINT1
    SAVEPOINT inout_kuragae_point;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application_short_name
                    , iv_name         => cv_inout_kuragae_start_msg
                  );
    --
    FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
       , buff   => gv_out_msg );
    --
    FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
       , buff   => gv_out_msg );
    -- ===========================================
    -- 入出庫・倉替データ取得 (A-2)
    -- ===========================================
    get_inout_kuragae_data(
        lv_errbuf            -- エラー・メッセージ           --# 固定 #
      , lv_retcode           -- リターン・コード             --# 固定 #
      , lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    -- ===========================================
    -- 入出庫・倉替の終了処理 (A-8)
    -- ===========================================
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
        -- 入出庫・倉替処理をROLLBACK;
        ROLLBACK TO SAVEPOINT inout_kuragae_point;
        -- 異常処理件数セット
        gn_error_inout_kuragae_cnt  := 1;
        gn_warn_inout_kuragae_cnt   := 1;
        gn_normal_inout_kuragae_cnt := 0;
        -- エラーメッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg --ユーザー・エラーメッセージ
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errbuf --エラーメッセージ
        );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_inout_kuragae_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_inout_kuragae_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_inout_kuragae_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --終了メッセージ
    IF ( gn_error_inout_kuragae_cnt > 0 ) THEN
      lv_message_code := cv_error_msg;
    ELSIF ( gn_warn_inout_kuragae_cnt > 0 ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( gn_target_inout_kuragae_cnt = gn_normal_inout_kuragae_cnt ) THEN
      lv_message_code := cv_normal_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --*********************************************
    --***             消化VD補充                ***
    --*********************************************
    --
    -- =======================
    -- 消化VD補充の開始処理
    -- =======================
    --SAVE POINT2
    SAVEPOINT svd_point;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application_short_name
                    , iv_name         => cv_svd_start_msg
                  );
    --
    FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
       , buff   => gv_out_msg );
    --
    FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
       , buff   => gv_out_msg );
    -- ===========================================
    -- 消化VD補充データ取得 (A-9)
    -- ===========================================
    get_svd_data(
        lv_errbuf            -- エラー・メッセージ           --# 固定 #
      , lv_retcode           -- リターン・コード             --# 固定 #
      , lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    -- ===========================================
    -- 消化VD補充の終了処理 (A-16)
    -- ===========================================
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
        -- 消化VD補充処理をROLLBACK;
        ROLLBACK TO SAVEPOINT svd_point;
        -- 処理件数セット
        gn_error_svd_cnt  := 1;
        gn_warn_svd_cnt   := 1;
        gn_normal_svd_cnt := 0;
        -- エラーメッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg --ユーザー・エラーメッセージ
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errbuf --エラーメッセージ
        );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_svd_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_svd_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_svd_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --取引作成件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application_short_name
                    ,iv_name         => cv_oif_ins_cnt_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_oif_ins_svd_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --終了メッセージ
    IF ( gn_error_svd_cnt > 0 ) THEN
      lv_message_code := cv_error_msg;
    ELSIF ( gn_warn_svd_cnt > 0 ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( gn_target_svd_cnt = gn_normal_svd_cnt ) THEN
      lv_message_code := cv_normal_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --*********************************************
    --***              商品振替                 ***
    --*********************************************
    --
    -- =======================
    -- 商品振替の開始処理
    -- =======================
    --SAVE POINT3
    SAVEPOINT svd_item_conv;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application_short_name
                    , iv_name         => cv_item_conv_msg
                  );
    --
    FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
       , buff   => gv_out_msg );
    --
    FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
       , buff   => gv_out_msg );
    -- ===========================================
    --  商品振替データ取得 (A-17)
    -- ===========================================
    get_item_conv_data(
        lv_errbuf            -- エラー・メッセージ           --# 固定 #
      , lv_retcode           -- リターン・コード             --# 固定 #
      , lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    -- ===========================================
    -- 商品振替の終了処理 (A-24)
    -- ===========================================
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
        -- 商品振替処理をROLLBACK;
        ROLLBACK TO SAVEPOINT svd_item_conv;
        -- 処理件数セット
        gn_error_item_conv_cnt  := 1;
        gn_warn_item_conv_cnt   := 1;
        gn_normal_item_conv_cnt := 0;
        -- エラーメッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg --ユーザー・エラーメッセージ
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errbuf --エラーメッセージ
        );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_item_conv_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_item_conv_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_item_conv_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --終了メッセージ
    IF ( gn_error_item_conv_cnt > 0 ) THEN
      lv_message_code := cv_error_msg;
    ELSIF ( gn_warn_item_conv_cnt > 0 ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( gn_target_item_conv_cnt = gn_normal_item_conv_cnt ) THEN
      lv_message_code := cv_normal_msg;
    END IF;
    --
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --*********************************************
    --***              終了判定                 ***
    --*********************************************
    --
    gn_target_cnt := gn_target_inout_kuragae_cnt + gn_target_svd_cnt + gn_target_item_conv_cnt;
    gn_normal_cnt := gn_normal_inout_kuragae_cnt + gn_normal_svd_cnt + gn_normal_item_conv_cnt;
    gn_error_cnt  := gn_error_inout_kuragae_cnt + gn_error_svd_cnt + gn_error_item_conv_cnt;
    gn_warn_cnt   := gn_warn_inout_kuragae_cnt + gn_warn_svd_cnt + gn_warn_item_conv_cnt;
    --
    -- 異常判定(入出庫・倉替、消化VD補充、商品振替機能が全て異常)
    -- 全件ROLLBACKとする
    IF gn_error_cnt = 3 THEN
    --
      ov_retcode := cv_status_error;
    --
    ELSE
    --
        -- 警告判定
        IF gn_warn_cnt > 0 THEN
          ov_retcode   := cv_status_warn;
          gn_error_cnt := gn_warn_cnt;
        -- 正常
        ELSE
          ov_retcode := cv_status_normal;
        END IF;
    --
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    -- 計
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application_short_name
                    , iv_name         => cv_end_msg
                  );
    --
    FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
       , buff   => gv_out_msg );
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
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2       --   リターン・コード    --# 固定 #
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
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
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
    FND_FILE.PUT_LINE(
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
    FND_FILE.PUT_LINE(
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
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
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
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;

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
END XXCOI003A14C;
/
