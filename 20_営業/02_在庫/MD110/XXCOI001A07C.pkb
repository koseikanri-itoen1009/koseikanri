CREATE OR REPLACE PACKAGE BODY XXCOI001A07C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI001A07C(body)
 * Description      : その他取引データOIF更新
 * MD.050           : その他取引データOIF更新 MD050_COI_001_A07
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理 (A-1)
 *  get_slip_num           対象伝票No取得処理 (A-2)
 *  get_inside_info        入庫情報取得処理 (A-4)
 *  chk_category           項目チェック処理 (A-5)
 *  ins_mtl_tran_if_tab    資材取引OIF挿入処理 (A-6)
 *  get_lock               ロック取得処理 (A-7)
 *  upd_storage_info_tab   入庫情報一時表更新処理 (A-8)
 *  submain                メイン処理プロシージャ
 *                         セーブポイント設定 (A-3)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                         終了処理 (A-9)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/19    1.0   K.Nakamura       新規作成
 *  2009/02/12    1.1   S.Moriyama       結合テスト障害No003対応
 *  2009/04/28    1.2   T.Nakamura       システムテスト障害T1_0640対応
 *  2009/05/18    1.3   T.Nakamura       システムテスト障害T1_0640対応
 *  2009/11/13    1.4   N.Abe            [E_T4_00189]品目1桁目が5,6を資材として処理
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
  no_data_expt                   EXCEPTION; -- 取得件数0件例外
  lock_expt                      EXCEPTION; -- ロック取得例外
--
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );  -- ロック取得例外
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                    CONSTANT VARCHAR2(100) := 'XXCOI001A07C'; -- パッケージ
  cv_appl_short_name             CONSTANT VARCHAR2(10)  := 'XXCCP';        -- アドオン：共通・IF領域
  cv_application_short_name      CONSTANT VARCHAR2(10)  := 'XXCOI';        -- アプリケーション短縮名
  cv_flag_on                     CONSTANT VARCHAR2(1)   := 'Y';            -- フラグON
  cv_flag_off                    CONSTANT VARCHAR2(1)   := 'N';            -- フラグOFF
  cv_slip_type_10                CONSTANT VARCHAR2(2)   := '10';           -- 伝票区分 10:工場入庫
  cv_slip_type_20                CONSTANT VARCHAR2(2)   := '20';           -- 伝票区分 20:拠点間入庫
  cv_segment1                    CONSTANT VARCHAR2(1)   := '2';            -- 品目区分  2:資材
  -- メッセージ
  cv_no_para_msg                 CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008'; -- コンカレント入力パラメータなしメッセージ
  cv_org_code_get_err_msg        CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00005'; -- 在庫組織コード取得エラーメッセージ
  cv_org_id_get_err_msg          CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00006'; -- 在庫組織ID取得エラーメッセージ
  cv_no_data_msg                 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00008'; -- 対象データ無しメッセージ
  cv_process_date_get_err_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00011'; -- 業務日付取得エラーメッセージ
  cv_tran_type_id_get_err_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00012'; -- 取引タイプID取得エラーメッセージ
  cv_tran_type_name_get_err_msg  CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00022'; -- 取引タイプ名取得エラーメッセージ
  cv_item_category_get_err_msg   CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10146'; -- 品目区分カテゴリセット名取得エラーメッセージ
  cv_acc_dept_code_get_err_msg   CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10080'; -- 経理用部門コード取得エラーメッセージ
  cv_item_found_chk_err_msg      CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10071'; -- 品目存在チェックエラーメッセージ
  cv_item_status_chk_err_msg     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10072'; -- 品目ステータス有効チェックエラーメッセージ
  cv_primary_found_chk_err_msg   CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10073'; -- 基準単位存在チェックエラーメッセージ
  cv_primary_valid_chk_err_msg   CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10074'; -- 基準単位有効チェックエラーメッセージ
  cv_subinv_found_chk_err_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10075'; -- 保管場所存在チェックエラーメッセージ
  cv_subinv_valid_chk_err_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10076'; -- 保管場所有効チェックエラーメッセージ
  cv_act_type_found_chk_err_msg  CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10077'; -- 勘定科目別名存在チェックエラーメッセージ
  cv_act_type_valid_chk_err_msg  CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10078'; -- 勘定科目別名有効チェックエラーメッセージ
  cv_inv_acc_period_chk_err_msg  CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10079'; -- 伝票日付在庫会計期間チェックエラーメッセージ
  cv_table_lock_err_msg          CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10029'; -- ロックエラーメッセージ（入庫情報一時表サマリ行）
  cv_table_lock_err_2_msg        CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10325'; -- ロックエラーメッセージ（入庫情報一時表）
  cv_no_data_inside_info_msg     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10350'; -- 入庫情報一時表データ取得エラーメッセージ
  -- トークン
  cv_tkn_item_code               CONSTANT VARCHAR2(20)  := 'ITEM_CODE';            -- 親品目コード
  cv_tkn_org_code                CONSTANT VARCHAR2(20)  := 'ORG_CODE_TOK';         -- 在庫組織コード
  cv_tkn_primary_uom             CONSTANT VARCHAR2(20)  := 'PRIMARY_UOM';          -- 基準数量
  cv_tkn_subinventory_code       CONSTANT VARCHAR2(20)  := 'SUBINVENTORY_CODE';    -- 保管場所コード
  cv_tkn_den_no                  CONSTANT VARCHAR2(20)  := 'DEN_NO';               -- 伝票No
  cv_tkn_entry_date              CONSTANT VARCHAR2(20)  := 'ENTRY_DATE';           -- 伝票日付
  cv_tkn_base_code               CONSTANT VARCHAR2(20)  := 'BASE_CODE';            -- 拠点コード
  cv_tkn_store_code              CONSTANT VARCHAR2(20)  := 'STORE_CODE';           -- 倉庫コード(確認倉庫・転送先倉庫)
  cv_tkn_act_type                CONSTANT VARCHAR2(20)  := 'ACT_TYPE';             -- 入出庫勘定区分
  cv_tkn_pro                     CONSTANT VARCHAR2(20)  := 'PRO_TOK';              -- プロファイル名
  cv_tkn_tran_type               CONSTANT VARCHAR2(20)  := 'TRANSACTION_TYPE_TOK'; -- 取引タイプ名
  cv_tkn_lookup_type             CONSTANT VARCHAR2(20)  := 'LOOKUP_TYPE';          -- 参照タイプ
  cv_tkn_lookup_code             CONSTANT VARCHAR2(20)  := 'LOOKUP_CODE';          -- 参照コード
  cv_tkn_item_status             CONSTANT VARCHAR2(20)  := 'ITEM_STATUS';          -- 品目ステータス
  cv_tkn_tran_id                 CONSTANT VARCHAR2(20)  := 'TRANSACTION_ID';       -- 取引ID
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 取引タイプID格納用
  TYPE gt_transaction_types_ttype IS TABLE OF mtl_transaction_types.transaction_type_id%TYPE INDEX BY BINARY_INTEGER;
--
  -- 伝票Noレコード格納用
  TYPE gt_slip_num_ttype IS TABLE OF xxcoi_storage_information.slip_num%TYPE INDEX BY BINARY_INTEGER;
--
  -- 入庫情報レコード格納用
  TYPE gr_inside_info_rec IS RECORD(
      transaction_id                      xxcoi_storage_information.transaction_id%TYPE                 -- 取引ID
    , slip_num                            xxcoi_storage_information.slip_num%TYPE                       -- 伝票番号
    , slip_date                           xxcoi_storage_information.slip_date%TYPE                      -- 伝票日付
    , base_code                           xxcoi_storage_information.base_code%TYPE                      -- 拠点コード
    , check_warehouse_code                xxcoi_storage_information.check_warehouse_code%TYPE           -- 確認倉庫コード
    , ship_warehouse_code                 xxcoi_storage_information.ship_warehouse_code%TYPE            -- 転送先倉庫コード
    , parent_item_code                    xxcoi_storage_information.parent_item_code%TYPE               -- 親品目コード
    , inventory_item_id                   mtl_system_items_b.inventory_item_id%TYPE                     -- 品目ID
    , item_code                           xxcoi_storage_information.item_code%TYPE                      -- 子品目コード
    , material_transaction_unset_qty      xxcoi_storage_information.material_transaction_unset_qty%TYPE -- 取引数量
    , slip_type                           xxcoi_storage_information.slip_type%TYPE                      -- 伝票区分
    , segment1                            mtl_categories_b.segment1%TYPE                                -- 品目区分
    , ship_base_code                      xxcoi_storage_information.ship_base_code%TYPE                 -- 出庫拠点コード
  );
--
  TYPE gt_inside_info_ttype IS TABLE OF gr_inside_info_rec INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gt_org_id                      mtl_parameters.organization_id%TYPE;                     -- 在庫組織ID
  gt_acc_dept_code               fnd_profile_option_values.profile_option_value%TYPE;     -- 経理部用部門コード
  gt_item_category_class         fnd_profile_option_values.profile_option_value%TYPE;     -- 品目区分カテゴリセット名
  gt_tran_type_factory_stock     mtl_transaction_types.transaction_type_id%TYPE;          -- 取引タイプID 工場入庫
  gt_tran_type_factory_stock_b   mtl_transaction_types.transaction_type_id%TYPE;          -- 取引タイプID 工場入庫振戻
  gt_tran_type_inout             mtl_transaction_types.transaction_type_id%TYPE;          -- 取引タイプID 入出庫
  gt_tran_type_pack_receive      mtl_transaction_types.transaction_type_id%TYPE;          -- 取引タイプID 梱包材料一時受入
  gt_tran_type_pack_receive_b    mtl_transaction_types.transaction_type_id%TYPE;          -- 取引タイプID 梱包材料一時受入振戻
  gt_tran_type_transfer_cost     mtl_transaction_types.transaction_type_id%TYPE;          -- 取引タイプID 梱包材料原価振替
  gt_tran_type_transfer_cost_b   mtl_transaction_types.transaction_type_id%TYPE;          -- 取引タイプID 梱包材料原価振替振戻
  gd_date                        DATE;                                                    -- 業務日付
  gt_primary_uom_code            mtl_system_items_b.primary_uom_code%TYPE;                -- 基準単位コード
  gt_sec_inv_nm                  mtl_secondary_inventories.secondary_inventory_name%TYPE; -- 保管場所コード
  gt_sec_inv_nm_2                mtl_secondary_inventories.secondary_inventory_name%TYPE; -- 保管場所コード(伝票区分が「20」)
  gn_disposition_id              mtl_generic_dispositions.disposition_id%TYPE;            -- 勘定科目別名ID
  gn_disposition_id_2            mtl_generic_dispositions.disposition_id%TYPE;            -- 勘定科目別名ID(梱包材料原価振替)
  -- カウンタ
  gn_slip_loop_cnt               NUMBER; -- 伝票単位ループカウンタ
  gn_inside_info_loop_cnt        NUMBER; -- 取引ID単位ループカウンタ
  gn_inside_info_cnt             NUMBER; -- 取引ID単位カウンタ
  gn_err_flag_cnt                NUMBER; -- エラー判別用カウンタ
  -- PL/SQL表
  gt_transaction_types_tab       gt_transaction_types_ttype;
  gt_slip_num_tab                gt_slip_num_ttype;
  gt_inside_info_tab             gt_inside_info_ttype;
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
    -- プロファイル
    cv_prf_org_code                CONSTANT VARCHAR2(30) := 'XXCOI1_ORGANIZATION_CODE';   -- 在庫組織コード
    cv_prf_acc_dept_code           CONSTANT VARCHAR2(30) := 'XXCOI1_ACCOUT_DEPT_CODE';    -- 経理部用部門コード
    cv_prf_item_category_class     CONSTANT VARCHAR2(30) := 'XXCOI1_ITEM_CATEGORY_CLASS'; -- 品目区分カテゴリセット名
    -- 参照タイプ ユーザー定義取引タイプ名称
    cv_tran_type                   CONSTANT VARCHAR2(30) := 'XXCOI1_TRANSACTION_TYPE_NAME';
    -- 参照コード
    cv_tran_type_factory_stock     CONSTANT VARCHAR2(3)  := '150'; -- 取引タイプ コード 工場入庫
    cv_tran_type_factory_stock_b   CONSTANT VARCHAR2(3)  := '160'; -- 取引タイプ コード 工場入庫振戻
    cv_tran_type_inout             CONSTANT VARCHAR2(3)  := '10';  -- 取引タイプ コード 入出庫
    cv_tran_type_pack_receive      CONSTANT VARCHAR2(3)  := '250'; -- 取引タイプ コード 梱包材料一時受入
    cv_tran_type_pack_receive_b    CONSTANT VARCHAR2(3)  := '260'; -- 取引タイプ コード 梱包材料一時受入振戻
    cv_tran_type_transfer_cost     CONSTANT VARCHAR2(3)  := '270'; -- 取引タイプ コード 梱包材料原価振替
    cv_tran_type_transfer_cost_b   CONSTANT VARCHAR2(3)  := '280'; -- 取引タイプ コード 梱包材料原価振替振戻
--
    -- *** ローカル変数 ***
    lt_org_code                    mtl_parameters.organization_code%TYPE;            -- 在庫組織コード
    lt_tran_type_factory_stock     mtl_transaction_types.transaction_type_name%TYPE; -- 取引タイプ名 工場入庫
    lt_tran_type_factory_stock_b   mtl_transaction_types.transaction_type_name%TYPE; -- 取引タイプ名 工場入庫振戻
    lt_tran_type_inout             mtl_transaction_types.transaction_type_name%TYPE; -- 取引タイプ名 入出庫
    lt_tran_type_pack_receive      mtl_transaction_types.transaction_type_name%TYPE; -- 取引タイプ名 梱包材料一時受入
    lt_tran_type_pack_receive_b    mtl_transaction_types.transaction_type_name%TYPE; -- 取引タイプ名 梱包材料一時受入振戻
    lt_tran_type_transfer_cost     mtl_transaction_types.transaction_type_name%TYPE; -- 取引タイプ名 梱包材料原価振替
    lt_tran_type_transfer_cost_b   mtl_transaction_types.transaction_type_name%TYPE; -- 取引タイプ名 梱包材料原価振替振戻
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
    -- コンカレント入力パラメータなしメッセージログ出力
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
    -- 取引タイプ名取得（工場入庫）
    -- ===============================
    lt_tran_type_factory_stock := xxcoi_common_pkg.get_meaning( cv_tran_type, cv_tran_type_factory_stock );
    -- 共通関数の戻り値がNULLの場合
    IF ( lt_tran_type_factory_stock IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_name_get_err_msg
                     , iv_token_name1  => cv_tkn_lookup_type
                     , iv_token_value1 => cv_tran_type
                     , iv_token_name2  => cv_tkn_lookup_code
                     , iv_token_value2 => cv_tran_type_factory_stock
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 取引タイプID取得（工場入庫）
    -- ===============================
    gt_tran_type_factory_stock := xxcoi_common_pkg.get_transaction_type_id( lt_tran_type_factory_stock );
    -- 共通関数の戻り値がNULLの場合
    IF ( gt_tran_type_factory_stock IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_id_get_err_msg
                     , iv_token_name1  => cv_tkn_tran_type
                     , iv_token_value1 => lt_tran_type_factory_stock
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 取引タイプ名取得（工場入庫振戻）
    -- ===============================
    lt_tran_type_factory_stock_b := xxcoi_common_pkg.get_meaning( cv_tran_type, cv_tran_type_factory_stock_b );
    -- 共通関数の戻り値がNULLの場合
    IF ( lt_tran_type_factory_stock_b IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_name_get_err_msg
                     , iv_token_name1  => cv_tkn_lookup_type
                     , iv_token_value1 => cv_tran_type
                     , iv_token_name2  => cv_tkn_lookup_code
                     , iv_token_value2 => cv_tran_type_factory_stock_b
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 取引タイプID取得（工場入庫振戻）
    -- ===============================
    gt_tran_type_factory_stock_b := xxcoi_common_pkg.get_transaction_type_id( lt_tran_type_factory_stock_b );
    -- 共通関数の戻り値がNULLの場合
    IF ( gt_tran_type_factory_stock_b IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_id_get_err_msg
                     , iv_token_name1  => cv_tkn_tran_type
                     , iv_token_value1 => lt_tran_type_factory_stock_b
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
    -- ===============================
    -- 取引タイプ名取得（梱包材料一時受入）
    -- ===============================
    lt_tran_type_pack_receive := xxcoi_common_pkg.get_meaning( cv_tran_type, cv_tran_type_pack_receive );
    -- 共通関数の戻り値がNULLの場合
    IF ( lt_tran_type_pack_receive IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_name_get_err_msg
                     , iv_token_name1  => cv_tkn_lookup_type
                     , iv_token_value1 => cv_tran_type
                     , iv_token_name2  => cv_tkn_lookup_code
                     , iv_token_value2 => cv_tran_type_pack_receive
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 取引タイプID取得（梱包材料一時受入）
    -- ===============================
    gt_tran_type_pack_receive := xxcoi_common_pkg.get_transaction_type_id( lt_tran_type_pack_receive );
    -- 共通関数の戻り値がNULLの場合
    IF ( gt_tran_type_pack_receive IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_id_get_err_msg
                     , iv_token_name1  => cv_tkn_tran_type
                     , iv_token_value1 => lt_tran_type_pack_receive
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 取引タイプ名取得（梱包材料一時受入振戻）
    -- ===============================
    lt_tran_type_pack_receive_b := xxcoi_common_pkg.get_meaning( cv_tran_type, cv_tran_type_pack_receive_b );
    -- 共通関数の戻り値がNULLの場合
    IF ( lt_tran_type_pack_receive_b IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_name_get_err_msg
                     , iv_token_name1  => cv_tkn_lookup_type
                     , iv_token_value1 => cv_tran_type
                     , iv_token_name2  => cv_tkn_lookup_code
                     , iv_token_value2 => cv_tran_type_pack_receive_b
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 取引タイプID取得（梱包材料一時受入振戻）
    -- ===============================
    gt_tran_type_pack_receive_b := xxcoi_common_pkg.get_transaction_type_id( lt_tran_type_pack_receive_b );
    -- 共通関数の戻り値がNULLの場合
    IF ( gt_tran_type_pack_receive_b IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_id_get_err_msg
                     , iv_token_name1  => cv_tkn_tran_type
                     , iv_token_value1 => lt_tran_type_pack_receive_b
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 取引タイプ名取得（梱包材料原価振替）
    -- ===============================
    lt_tran_type_transfer_cost := xxcoi_common_pkg.get_meaning( cv_tran_type, cv_tran_type_transfer_cost );
    -- 共通関数の戻り値がNULLの場合
    IF ( lt_tran_type_transfer_cost IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_name_get_err_msg
                     , iv_token_name1  => cv_tkn_lookup_type
                     , iv_token_value1 => cv_tran_type
                     , iv_token_name2  => cv_tkn_lookup_code
                     , iv_token_value2 => cv_tran_type_transfer_cost
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 取引タイプID取得（梱包材料原価振替）
    -- ===============================
    gt_tran_type_transfer_cost := xxcoi_common_pkg.get_transaction_type_id( lt_tran_type_transfer_cost );
    -- 共通関数の戻り値がNULLの場合
    IF ( gt_tran_type_transfer_cost IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_id_get_err_msg
                     , iv_token_name1  => cv_tkn_tran_type
                     , iv_token_value1 => lt_tran_type_transfer_cost
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 取引タイプ名取得（梱包材料原価振替振戻）
    -- ===============================
    lt_tran_type_transfer_cost_b := xxcoi_common_pkg.get_meaning( cv_tran_type, cv_tran_type_transfer_cost_b );
    -- 共通関数の戻り値がNULLの場合
    IF ( lt_tran_type_transfer_cost_b IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_name_get_err_msg
                     , iv_token_name1  => cv_tkn_lookup_type
                     , iv_token_value1 => cv_tran_type
                     , iv_token_name2  => cv_tkn_lookup_code
                     , iv_token_value2 => cv_tran_type_transfer_cost_b
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 取引タイプID取得（梱包材料原価振替振戻）
    -- ===============================
    gt_tran_type_transfer_cost_b := xxcoi_common_pkg.get_transaction_type_id( lt_tran_type_transfer_cost_b );
    -- 共通関数の戻り値がNULLの場合
    IF ( gt_tran_type_transfer_cost_b IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_id_get_err_msg
                     , iv_token_name1  => cv_tkn_tran_type
                     , iv_token_value1 => lt_tran_type_transfer_cost_b
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 業務日付取得
    -- ===============================
    gd_date := xxccp_common_pkg2.get_process_date;
    -- 共通関数の戻り値がNULLの場合
    IF ( gd_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_process_date_get_err_msg
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- プロファイル取得：経理部用部門コード
    -- ===============================
    gt_acc_dept_code := fnd_profile.value( cv_prf_acc_dept_code );
    -- プロファイルが取得できない場合
    IF ( gt_acc_dept_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_acc_dept_code_get_err_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_acc_dept_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- プロファイル取得：品目区分カテゴリセット名
    -- ===============================
    gt_item_category_class := fnd_profile.value( cv_prf_item_category_class );
    -- プロファイルが取得できない場合
    IF ( gt_item_category_class IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_item_category_get_err_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_item_category_class
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
    WHEN global_api_expt THEN
    -- *** 共通関数例外ハンドラ ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;                                            --# 任意 #
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
   * Procedure Name   : get_slip_num
   * Description      : 対象伝票No取得処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_slip_num(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_slip_num'; -- プログラム名
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
    -- 伝票単位取得
    CURSOR slip_num_cur
    IS
      SELECT  DISTINCT xsi.slip_num             AS slip_num                      -- 伝票No
      FROM    xxcoi_storage_information         xsi                              -- 入庫情報一時表
      WHERE   xsi.store_check_flag              = cv_flag_on                     -- 入庫確認フラグ
      AND     xsi.material_transaction_set_flag = cv_flag_off                    -- 資材取引連携済フラグ
      AND ( ( xsi.slip_type                     = cv_slip_type_10 )              -- 伝票区分が「10」
      OR  ( ( xsi.slip_type                     = cv_slip_type_20 )              -- 伝票区分が「20」
      AND   ( xsi.check_warehouse_code          <> xsi.ship_warehouse_code ) ) ) -- 確認倉庫コード <> 転送先倉庫コード
      ORDER BY xsi.slip_num                                                      -- 伝票No
    ;
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
    -- カーソルオープン
    OPEN slip_num_cur;
--
    -- レコード読み込み
    FETCH slip_num_cur BULK COLLECT INTO gt_slip_num_tab;
--
    -- 対象件数セット
    gn_target_cnt := gt_slip_num_tab.COUNT;
--
    -- カーソルクローズ
    CLOSE slip_num_cur;
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
      -- カーソルがOPENしている場合
      IF ( slip_num_cur%ISOPEN ) THEN
        CLOSE slip_num_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルがOPENしている場合
      IF ( slip_num_cur%ISOPEN ) THEN
        CLOSE slip_num_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルがOPENしている場合
      IF ( slip_num_cur%ISOPEN ) THEN
        CLOSE slip_num_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_slip_num;
--
  /**********************************************************************************
   * Procedure Name   : get_inside_info
   * Description      : 入庫情報取得処理 (A-4)
   ***********************************************************************************/
  PROCEDURE get_inside_info(
    gn_slip_loop_cnt IN  NUMBER,       --   伝票単位ループカウンタ
    ov_errbuf        OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode       OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg        OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inside_info'; -- プログラム名
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
    -- 取引ID単位取得
    CURSOR inside_info_cur
    IS
      SELECT
              xsi.transaction_id                 AS transaction_id                               -- 取引ID
            , xsi.slip_num                       AS slip_num                                     -- 伝票No
            , xsi.slip_date                      AS slip_date                                    -- 伝票日付
            , xsi.base_code                      AS base_code                                    -- 拠点コード
            , xsi.check_warehouse_code           AS check_warehouse_code                         -- 確認倉庫コード
            , xsi.ship_warehouse_code            AS ship_warehouse_code                          -- 転送先倉庫コード
            , xsi.parent_item_code               AS parent_item_code                             -- 親品目コード
            , msib.inventory_item_id             AS inventory_item_id                            -- 品目ID
            , xsi.item_code                      AS item_code                                    -- 子品目コード
            , xsi.material_transaction_unset_qty AS material_transaction_unset_qty               -- 資材取引未連携数量 
            , xsi.slip_type                      AS slip_type                                    -- 伝票区分
-- == 2009/11/13 V1.4 Modified START =============================================================
--            , mcb.segment1                       AS segment1                                     -- 品目区分
            , DECODE(SUBSTRB(xsi.parent_item_code, 1, 1), '5', '2'
                                                        , '6', '2'
                                                        , mcb.segment1) AS segment1              -- 品目区分
-- == 2009/11/13 V1.4 Modified END   =============================================================
            , xsi.ship_base_code                 AS ship_base_code                               -- 出庫拠点コード
      FROM
              xxcoi_storage_information          xsi                                             -- 入庫情報一時表
            , mtl_system_items_b                 msib                                            -- Disc品目マスタ
            , mtl_category_sets_tl               mcst                                            -- 品目カテゴリセット
            , mtl_item_categories                mic                                             -- 品目カテゴリ割当
            , mtl_categories_b                   mcb                                             -- 品目カテゴリ
      WHERE
              xsi.slip_num                       = gt_slip_num_tab( gn_slip_loop_cnt )           -- 伝票No
      AND     xsi.store_check_flag               = cv_flag_on                                    -- 入庫確認フラグが「Y」
      AND     xsi.material_transaction_set_flag  = cv_flag_off                                   -- 資材取引連携済フラグ
      AND ( ( xsi.slip_type                      = cv_slip_type_10 )                             -- 伝票区分が「10」
      OR  ( ( xsi.slip_type                      = cv_slip_type_20 )                             -- 伝票区分が「20」
      AND   ( xsi.check_warehouse_code           <> xsi.ship_warehouse_code ) ) )                -- 確認倉庫コード <> 転送先倉庫コード
      AND     msib.segment1                      = xsi.parent_item_code                          -- 親品目コード
      AND     msib.organization_id               = gt_org_id                                     -- 在庫組織ID
      AND     mcst.category_set_name             = gt_item_category_class                        -- カテゴリセット名
      AND     mcst.language                      = USERENV('LANG')                               -- 言語
      AND     mic.category_set_id                = mcst.category_set_id                          -- カテゴリセットID
      AND     mic.inventory_item_id              = msib.inventory_item_id                        -- 品目ID
      AND     mic.organization_id                = msib.organization_id                          -- 在庫組織ID
      AND     mcb.category_id                    = mic.category_id                               -- カテゴリID
      AND     mcb.enabled_flag                   = cv_flag_on                                    -- 使用可能フラグ
      AND     gd_date                            < NVL( TRUNC( mcb.disable_date ), gd_date + 1 ) -- 無効日
-- == 2009/11/13 V1.4 Added START =============================================================
      UNION
      SELECT
              xsi.transaction_id                 AS transaction_id                               -- 取引ID
            , xsi.slip_num                       AS slip_num                                     -- 伝票No
            , xsi.slip_date                      AS slip_date                                    -- 伝票日付
            , xsi.base_code                      AS base_code                                    -- 拠点コード
            , xsi.check_warehouse_code           AS check_warehouse_code                         -- 確認倉庫コード
            , xsi.ship_warehouse_code            AS ship_warehouse_code                          -- 転送先倉庫コード
            , xsi.parent_item_code               AS parent_item_code                             -- 親品目コード
            , msib.inventory_item_id             AS inventory_item_id                            -- 品目ID
            , xsi.item_code                      AS item_code                                    -- 子品目コード
            , xsi.material_transaction_unset_qty AS material_transaction_unset_qty               -- 資材取引未連携数量 
            , xsi.slip_type                      AS slip_type                                    -- 伝票区分
            , '2'                                AS segment1                                     -- 品目区分
            , xsi.ship_base_code                 AS ship_base_code                               -- 出庫拠点コード
      FROM
              xxcoi_storage_information          xsi                                             -- 入庫情報一時表
            , mtl_system_items_b                 msib                                            -- Disc品目マスタ
      WHERE
              xsi.slip_num                       = gt_slip_num_tab( gn_slip_loop_cnt )           -- 伝票No
      AND     xsi.store_check_flag               = cv_flag_on                                    -- 入庫確認フラグが「Y」
      AND     xsi.material_transaction_set_flag  = cv_flag_off                                   -- 資材取引連携済フラグ
      AND ( ( xsi.slip_type                      = cv_slip_type_10 )                             -- 伝票区分が「10」
      OR  ( ( xsi.slip_type                      = cv_slip_type_20 )                             -- 伝票区分が「20」
      AND   ( xsi.check_warehouse_code           <> xsi.ship_warehouse_code ) ) )                -- 確認倉庫コード <> 転送先倉庫コード
      AND     msib.segment1                      = xsi.parent_item_code                          -- 親品目コード
      AND     msib.organization_id               = gt_org_id                                     -- 在庫組織ID
      AND   ( msib.segment1                      LIKE '5%'
      OR      msib.segment1                      LIKE '6%' )
-- == 2009/11/13 V1.4 Added END   =============================================================
-- == 2009/04/28 V1.2 Added START ===============================================================
-- == 2009/05/18 V1.3 Deleted START =============================================================
--      AND     xsi.material_transaction_unset_qty <> 0                                            -- 資材取引未連携数量 <> 0
-- == 2009/05/18 V1.3 Deleted END   =============================================================
-- == 2009/04/28 V1.2 Added END   ===============================================================
    ;
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
    -- 取引ID単位件数初期化
    gn_inside_info_cnt := 0;
--
    -- カーソルオープン
    OPEN inside_info_cur;
--
    -- レコード読み込み
    FETCH inside_info_cur BULK COLLECT INTO gt_inside_info_tab;
--
    -- 取引ID単位件数セット
    gn_inside_info_cnt := gt_inside_info_tab.COUNT;
--
    -- カーソルクローズ
    CLOSE inside_info_cur;
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
      -- カーソルがOPENしている場合
      IF ( inside_info_cur%ISOPEN ) THEN
        CLOSE inside_info_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルがOPENしている場合
      IF ( inside_info_cur%ISOPEN ) THEN
        CLOSE inside_info_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルがOPENしている場合
      IF ( inside_info_cur%ISOPEN ) THEN
        CLOSE inside_info_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_inside_info;
--
  /**********************************************************************************
   * Procedure Name   : chk_category
   * Description      : 項目チェック処理 (A-5)
   ***********************************************************************************/
  PROCEDURE chk_category(
    gn_inside_info_loop_cnt  IN   NUMBER,    -- 取引ID単位ループカウンタ
    ov_errbuf                OUT  VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT  VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg                OUT  VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_category'; -- プログラム名
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
    cv_inactive                  CONSTANT VARCHAR2(10) := 'Inactive'; -- 品目ステータス Inactive
    cv_sales_class_1             CONSTANT VARCHAR2(1)  := '1';        -- 品目ステータス 1:対象
    cv_inv_account_kbn_01        CONSTANT VARCHAR2(2)  := '01';       -- 入出庫勘定区分 01
    cv_inv_account_kbn_02        CONSTANT VARCHAR2(2)  := '02';       -- 入出庫勘定区分 02
    cv_inv_account_kbn_21        CONSTANT VARCHAR2(2)  := '21';       -- 入出庫勘定区分 21
--
    -- *** ローカル変数 ***
    -- 品目チェック
    lt_item_status               mtl_system_items_b.inventory_item_status_code%TYPE;    -- 品目ステータス
    lt_cust_order_flg            mtl_system_items_b.customer_order_enabled_flag%TYPE;   -- 顧客受注可能フラグ
    lt_transaction_enable        mtl_system_items_b.mtl_transactions_enabled_flag%TYPE; -- 取引可能
    lt_stock_enabled_flg         mtl_system_items_b.stock_enabled_flag%TYPE;            -- 在庫保有可能フラグ
    lt_return_enable             mtl_system_items_b.returnable_flag%TYPE;               -- 返品可能
    lt_sales_class               ic_item_mst_b.attribute26%TYPE;                        -- 売上対象区分
    lt_primary_unit              mtl_system_items_b.primary_unit_of_measure%TYPE;       -- 基準単位
    lt_inventory_item_id         mtl_system_items_b.inventory_item_id%TYPE;             -- 品目ID
    -- 基準単位チェック
    lt_disable_date              mtl_units_of_measure_tl.disable_date%TYPE;             -- 無効日
    -- 保管場所コードチェック
    lt_sec_inv_disable_date      mtl_secondary_inventories.disable_date%TYPE;           -- 無効日
    -- 在庫会計期間チェック
    lb_chk_result                BOOLEAN;                                               -- ステータス
    --
    lv_disposition_id_chk_flag   VARCHAR2(1); -- 勘定科目別名IDチェックエラー判別用フラグ
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
    -- 変数の初期化
    -- 品目チェック
    lt_item_status             := NULL; -- 品目ステータス
    lt_cust_order_flg          := NULL; -- 顧客受注可能フラグ
    lt_transaction_enable      := NULL; -- 取引可能
    lt_stock_enabled_flg       := NULL; -- 在庫保有可能フラグ
    lt_return_enable           := NULL; -- 返品可能
    lt_sales_class             := NULL; -- 売上対象区分
    lt_primary_unit            := NULL; -- 基準単位
    lt_inventory_item_id       := NULL; -- 品目ID
    -- 基準単位チェック
    gt_primary_uom_code        := NULL; -- 基準単位コード
    lt_disable_date            := NULL; -- 無効日
    -- 保管場所コードチェック
    gt_sec_inv_nm              := NULL; -- 保管場所コード
    gt_sec_inv_nm_2            := NULL; -- 保管場所コード(伝票区分が「20」)
    lt_sec_inv_disable_date    := NULL; -- 無効日
    -- 勘定科目別名チェック
    gn_disposition_id          := NULL; -- 勘定科目別名ID
    gn_disposition_id_2        := NULL; -- 勘定科目別名ID(梱包材料原価振替)
    -- 在庫会計期間チェック
    lb_chk_result              := TRUE; -- ステータス
    --
    lv_disposition_id_chk_flag := cv_flag_off; -- 勘定科目別名IDチェックエラー判別用フラグ
--
    -- ===============================
    -- 品目チェック
    -- ===============================
    xxcoi_common_pkg.get_item_info2(
        iv_item_code          => gt_inside_info_tab( gn_inside_info_loop_cnt ).parent_item_code -- 品目コード
      , in_org_id             => gt_org_id                                                      -- 在庫組織ID
      , ov_item_status        => lt_item_status                                                 -- 品目ステータス
      , ov_cust_order_flg     => lt_cust_order_flg                                              -- 顧客受注可能フラグ
      , ov_transaction_enable => lt_transaction_enable                                          -- 取引可能
      , ov_stock_enabled_flg  => lt_stock_enabled_flg                                           -- 在庫保有可能フラグ
      , ov_return_enable      => lt_return_enable                                               -- 返品可能
      , ov_sales_class        => lt_sales_class                                                 -- 売上対象区分(使用しない)
      , ov_primary_unit       => lt_primary_unit                                                -- 基準単位(使用しない)
      , on_inventory_item_id  => lt_inventory_item_id                                           -- 品目ID(使用しない)
      , ov_primary_uom_code   => gt_primary_uom_code                                            -- 基準単位コード
      , ov_errbuf             => lv_errbuf                                                      -- エラーメッセージ
      , ov_retcode            => lv_retcode                                                     -- リターン・コード
      , ov_errmsg             => lv_errmsg                                                      -- ユーザー・エラーメッセージ
   );
--
    -- 戻り値の品目ステータスがNULLの場合
    IF ( lt_item_status IS NULL ) THEN
      -- 品目存在チェックエラー
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application_short_name
                      , iv_name         => cv_item_found_chk_err_msg
                      , iv_token_name1  => cv_tkn_item_code
                      , iv_token_value1 => gt_inside_info_tab( gn_inside_info_loop_cnt ).parent_item_code
                      , iv_token_name2  => cv_tkn_den_no
                      , iv_token_value2 => gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_num
                    );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_warn;
      -- メッセージ出力
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => ov_errmsg --エラーメッセージ
      );
    END IF;
--
    -- 戻り値の品目ステータスが「Inactive」且つ顧客受注可能フラグが「Y」且つ取引可能が「Y」且つ
    -- 在庫保有可能フラグが「Y」且つ返品可能が「Y」以外の場合
    IF ( ( lt_item_status         =  cv_inactive )
      AND ( lt_cust_order_flg     =  cv_flag_on )
      AND ( lt_transaction_enable =  cv_flag_on )
      AND ( lt_stock_enabled_flg  =  cv_flag_on )
      AND ( lt_return_enable      <> cv_flag_on ) ) THEN
      -- 品目ステータス有効チェックエラー
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application_short_name
                      , iv_name         => cv_item_status_chk_err_msg
                      , iv_token_name1  => cv_tkn_item_code
                      , iv_token_value1 => gt_inside_info_tab( gn_inside_info_loop_cnt ).parent_item_code
                      , iv_token_name2  => cv_tkn_item_status
                      , iv_token_value2 => lt_item_status
                      , iv_token_name3  => cv_tkn_den_no
                      , iv_token_value3 => gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_num
                    );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_warn;
      -- メッセージ出力
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => ov_errmsg --エラーメッセージ
      );
    END IF;
--
    -- 品目ステータスがNULLの場合はスキップ
    IF ( lt_item_status IS NOT NULL ) THEN
      -- ===============================
      -- 基準単位チェック
      -- ===============================
      xxcoi_common_pkg.get_uom_disable_info(
          iv_unit_code    => gt_primary_uom_code -- 単位コード
        , od_disable_date => lt_disable_date     -- 無効日
        , ov_errbuf       => lv_errbuf           -- エラーメッセージ
        , ov_retcode      => lv_retcode          -- リターン・コード
        , ov_errmsg       => lv_errmsg           -- ユーザー・エラーメッセージ
      );
  --
      -- 戻り値のリターン・コードが「0」（正常）以外の場合
      IF ( lv_retcode <> cv_status_normal ) THEN
        -- 基準単位存在チェックエラー
        lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application_short_name
                        , iv_name         => cv_primary_found_chk_err_msg
                        , iv_token_name1  => cv_tkn_primary_uom
                        , iv_token_value1 => gt_primary_uom_code
                        , iv_token_name2  => cv_tkn_den_no
                        , iv_token_value2 => gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_num
                      );
        lv_errbuf  := lv_errmsg;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
        ov_retcode := cv_status_warn;
        -- メッセージ出力
        FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
          , buff   => ov_errmsg --エラーメッセージ
        );
      -- 戻り値の無効日がTRUNC(NVL(無効日, システム日付+1)) <= TRUNC(システム日付)の場合
      ELSIF ( TRUNC( NVL( lt_disable_date, cd_creation_date + 1 ) ) <= TRUNC( cd_creation_date ) ) THEN
        -- 基準単位有効チェックエラー
        lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application_short_name
                        , iv_name         => cv_primary_valid_chk_err_msg
                        , iv_token_name1  => cv_tkn_primary_uom
                        , iv_token_value1 => gt_primary_uom_code
                        , iv_token_name2  => cv_tkn_den_no
                        , iv_token_value2 => gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_num
                      );
        lv_errbuf  := lv_errmsg;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
        ov_retcode := cv_status_warn;
        -- メッセージ出力
        FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
          , buff   => ov_errmsg --エラーメッセージ
        );
      END IF;
--
    END IF;
--
    -- ===============================
    -- 保管場所コードチェック
    -- ===============================
    -- 伝票区分が「10」（工場入庫）の場合
    IF ( gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_type = cv_slip_type_10 ) THEN
--
      -- 転送先倉庫コードがNULLの場合
      IF ( gt_inside_info_tab( gn_inside_info_loop_cnt ).ship_warehouse_code IS NULL ) THEN
--
        -- 保管場所コードのチェック
        xxcoi_common_pkg.get_subinventory_info1(
            iv_base_code    => gt_inside_info_tab( gn_inside_info_loop_cnt ).base_code            -- 拠点コード
          , iv_whse_code    => gt_inside_info_tab( gn_inside_info_loop_cnt ).check_warehouse_code -- 確認倉庫コード
          , ov_sec_inv_nm   => gt_sec_inv_nm                                                      -- 保管場所コード
          , od_disable_date => lt_sec_inv_disable_date                                            -- 無効日
          , ov_errbuf       => lv_errbuf                                                          -- エラーメッセージ
          , ov_retcode      => lv_retcode                                                         -- リターン・コード
          , ov_errmsg       => lv_errmsg                                                          -- ユーザー・エラーメッセージ
        );
--
        -- 戻り値の保管場所コードがNULLの場合
        IF ( gt_sec_inv_nm IS NULL ) THEN
          -- 保管場所存在チェックエラー
          lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application_short_name
                          , iv_name         => cv_subinv_found_chk_err_msg
                          , iv_token_name1  => cv_tkn_base_code
                          , iv_token_value1 => gt_inside_info_tab( gn_inside_info_loop_cnt ).base_code
                          , iv_token_name2  => cv_tkn_store_code
                          , iv_token_value2 => gt_inside_info_tab( gn_inside_info_loop_cnt ).check_warehouse_code
                          , iv_token_name3  => cv_tkn_den_no
                          , iv_token_value3 => gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_num
                        );
          lv_errbuf  := lv_errmsg;
          ov_errmsg  := lv_errmsg;
          ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
          ov_retcode := cv_status_warn;
          -- メッセージ出力
          FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
            , buff   => ov_errmsg --エラーメッセージ
          );
        -- 戻り値の無効日がTRUNC(NVL(無効日, システム日付+1)) <= TRUNC(システム日付)の場合
        ELSIF ( TRUNC( NVL( lt_sec_inv_disable_date, cd_creation_date + 1 ) ) <= TRUNC( cd_creation_date ) ) THEN
          -- 保管場所有効チェックエラー
          lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application_short_name
                          , iv_name         => cv_subinv_valid_chk_err_msg
                          , iv_token_name1  => cv_tkn_subinventory_code
                          , iv_token_value1 => gt_sec_inv_nm
                          , iv_token_name2  => cv_tkn_den_no
                          , iv_token_value2 => gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_num
                        );
          lv_errbuf  := lv_errmsg;
          ov_errmsg  := lv_errmsg;
          ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
          ov_retcode := cv_status_warn;
          -- メッセージ出力
          FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
            , buff   => ov_errmsg --エラーメッセージ
          );
        END IF;
--
      -- 転送先倉庫コードがNULLでない場合
      ELSIF ( gt_inside_info_tab( gn_inside_info_loop_cnt ).ship_warehouse_code IS NOT NULL ) THEN
--
        -- 保管場所コードのチェック
        xxcoi_common_pkg.get_subinventory_info2(
            iv_base_code    => gt_inside_info_tab( gn_inside_info_loop_cnt ).base_code           -- 拠点コード
          , iv_shop_code    => gt_inside_info_tab( gn_inside_info_loop_cnt ).ship_warehouse_code -- 転送先倉庫コード
          , ov_sec_inv_nm   => gt_sec_inv_nm                                                     -- 保管場所コード
          , od_disable_date => lt_sec_inv_disable_date                                           -- 無効日
          , ov_errbuf       => lv_errbuf                                                         -- エラーメッセージ
          , ov_retcode      => lv_retcode                                                        -- リターン・コード
          , ov_errmsg       => lv_errmsg                                                         -- ユーザー・エラーメッセージ
        );
--
        -- 戻り値の保管場所コードがNULLの場合
        IF ( gt_sec_inv_nm IS NULL ) THEN
          -- 保管場所存在チェックエラー
          lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application_short_name
                          , iv_name         => cv_subinv_found_chk_err_msg
                          , iv_token_name1  => cv_tkn_base_code
                          , iv_token_value1 => gt_inside_info_tab( gn_inside_info_loop_cnt ).base_code
                          , iv_token_name2  => cv_tkn_store_code
                          , iv_token_value2 => gt_inside_info_tab( gn_inside_info_loop_cnt ).ship_warehouse_code
                          , iv_token_name3  => cv_tkn_den_no
                          , iv_token_value3 => gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_num
                        );
          lv_errbuf  := lv_errmsg;
          ov_errmsg  := lv_errmsg;
          ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
          ov_retcode := cv_status_warn;
          -- メッセージ出力
          FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
            , buff   => ov_errmsg --エラーメッセージ
          );
        -- 戻り値の無効日がTRUNC(NVL(無効日, システム日付+1)) <= TRUNC(システム日付)の場合
        ELSIF ( TRUNC( NVL( lt_sec_inv_disable_date, cd_creation_date + 1 ) ) <= TRUNC( cd_creation_date ) ) THEN
          -- 保管場所有効チェックエラー
          lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application_short_name
                          , iv_name         => cv_subinv_valid_chk_err_msg
                          , iv_token_name1  => cv_tkn_subinventory_code
                          , iv_token_value1 => gt_sec_inv_nm
                          , iv_token_name2  => cv_tkn_den_no
                          , iv_token_value2 => gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_num
                        );
          lv_errbuf  := lv_errmsg;
          ov_errmsg  := lv_errmsg;
          ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
          ov_retcode := cv_status_warn;
          -- メッセージ出力
          FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
            , buff   => ov_errmsg --エラーメッセージ
          );
        END IF;
--
      END IF;
--
    -- 伝票区分が「20」（拠点間入庫）の場合
    ELSIF ( gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_type = cv_slip_type_20 ) THEN
--
      -- 確認倉庫コードに紐づく保管場所コードのチェック
      xxcoi_common_pkg.get_subinventory_info1(
          iv_base_code    => gt_inside_info_tab( gn_inside_info_loop_cnt ).base_code            -- 拠点コード
        , iv_whse_code    => gt_inside_info_tab( gn_inside_info_loop_cnt ).check_warehouse_code -- 確認倉庫コード
        , ov_sec_inv_nm   => gt_sec_inv_nm_2                                                    -- 保管場所コード
        , od_disable_date => lt_sec_inv_disable_date                                            -- 無効日
        , ov_errbuf       => lv_errbuf                                                          -- エラーメッセージ
        , ov_retcode      => lv_retcode                                                         -- リターン・コード
        , ov_errmsg       => lv_errmsg                                                          -- ユーザー・エラーメッセージ
      );
--
      -- 戻り値の保管場所コードがNULLの場合
      IF ( gt_sec_inv_nm_2 IS NULL ) THEN
        -- 保管場所存在チェックエラー
        lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application_short_name
                        , iv_name         => cv_subinv_found_chk_err_msg
                        , iv_token_name1  => cv_tkn_base_code
                        , iv_token_value1 => gt_inside_info_tab( gn_inside_info_loop_cnt ).base_code
                        , iv_token_name2  => cv_tkn_store_code
                        , iv_token_value2 => gt_inside_info_tab( gn_inside_info_loop_cnt ).check_warehouse_code
                        , iv_token_name3  => cv_tkn_den_no
                        , iv_token_value3 => gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_num
                      );
        lv_errbuf  := lv_errmsg;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
        ov_retcode := cv_status_warn;
        -- メッセージ出力
        FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
          , buff   => ov_errmsg --エラーメッセージ
        );
      -- 戻り値の無効日がTRUNC(NVL(無効日, システム日付+1)) <= TRUNC(システム日付)の場合
      ELSIF ( TRUNC( NVL( lt_sec_inv_disable_date, cd_creation_date + 1 ) ) <= TRUNC( cd_creation_date ) ) THEN
        -- 保管場所有効チェックエラー
        lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application_short_name
                        , iv_name         => cv_subinv_valid_chk_err_msg
                        , iv_token_name1  => cv_tkn_subinventory_code
                        , iv_token_value1 => gt_sec_inv_nm_2
                        , iv_token_name2  => cv_tkn_den_no
                        , iv_token_value2 => gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_num
                      );
        lv_errbuf  := lv_errmsg;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
        ov_retcode := cv_status_warn;
        -- メッセージ出力
        FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
          , buff   => ov_errmsg --エラーメッセージ
        );
      END IF;
--
      -- 保管場所コードがNULLの場合はスキップ
      IF ( gt_sec_inv_nm_2 IS NOT NULL ) THEN
--
        -- ローカル変数の初期化(無効日)
        lt_sec_inv_disable_date := NULL;
--
        -- 転送先倉庫コードが2桁の場合
        IF ( LENGTHB( gt_inside_info_tab( gn_inside_info_loop_cnt ).ship_warehouse_code ) = 2 ) THEN
--
          -- 転送先コードに紐づく保管場所コードのチェック
          xxcoi_common_pkg.get_subinventory_info1(
              iv_base_code    => gt_inside_info_tab( gn_inside_info_loop_cnt ).base_code           -- 拠点コード
            , iv_whse_code    => gt_inside_info_tab( gn_inside_info_loop_cnt ).ship_warehouse_code -- 転送先倉庫コード
            , ov_sec_inv_nm   => gt_sec_inv_nm                                                     -- 保管場所コード
            , od_disable_date => lt_sec_inv_disable_date                                           -- 無効日
            , ov_errbuf       => lv_errbuf                                                         -- エラーメッセージ
            , ov_retcode      => lv_retcode                                                        -- リターン・コード
            , ov_errmsg       => lv_errmsg                                                         -- ユーザー・エラーメッセージ
          );
--
          -- 戻り値の保管場所コードがNULLの場合
          IF ( gt_sec_inv_nm IS NULL ) THEN
            -- 保管場所存在チェックエラー
            lv_errmsg  := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application_short_name
                            , iv_name         => cv_subinv_found_chk_err_msg
                            , iv_token_name1  => cv_tkn_base_code
                            , iv_token_value1 => gt_inside_info_tab( gn_inside_info_loop_cnt ).base_code
                            , iv_token_name2  => cv_tkn_store_code
                            , iv_token_value2 => gt_inside_info_tab( gn_inside_info_loop_cnt ).ship_warehouse_code
                            , iv_token_name3  => cv_tkn_den_no
                            , iv_token_value3 => gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_num
                          );
            lv_errbuf  := lv_errmsg;
            ov_errmsg  := lv_errmsg;
            ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
            ov_retcode := cv_status_warn;
            -- メッセージ出力
            FND_FILE.PUT_LINE(
                which  => FND_FILE.OUTPUT
              , buff   => ov_errmsg --エラーメッセージ
            );
          -- 戻り値の無効日がTRUNC(NVL(無効日, システム日付+1)) <= TRUNC(システム日付)の場合
          ELSIF ( TRUNC( NVL( lt_sec_inv_disable_date, cd_creation_date + 1 ) ) <= TRUNC( cd_creation_date ) ) THEN
            -- 保管場所有効チェックエラー
            lv_errmsg  := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application_short_name
                            , iv_name         => cv_subinv_valid_chk_err_msg
                            , iv_token_name1  => cv_tkn_subinventory_code
                            , iv_token_value1 => gt_sec_inv_nm
                            , iv_token_name2  => cv_tkn_den_no
                            , iv_token_value2 => gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_num
                          );
            lv_errbuf  := lv_errmsg;
            ov_errmsg  := lv_errmsg;
            ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
            ov_retcode := cv_status_warn;
            -- メッセージ出力
            FND_FILE.PUT_LINE(
                which  => FND_FILE.OUTPUT
              , buff   => ov_errmsg --エラーメッセージ
            );
          END IF;
--
        -- 転送先倉庫コードが5桁の場合
        ELSIF ( LENGTHB( gt_inside_info_tab( gn_inside_info_loop_cnt ).ship_warehouse_code ) = 5 ) THEN
--
          -- 転送先コードに紐づく保管場所コードのチェック
          xxcoi_common_pkg.get_subinventory_info2(
              iv_base_code    => gt_inside_info_tab( gn_inside_info_loop_cnt ).base_code           -- 拠点コード
            , iv_shop_code    => gt_inside_info_tab( gn_inside_info_loop_cnt ).ship_warehouse_code -- 転送先倉庫コード
            , ov_sec_inv_nm   => gt_sec_inv_nm                                                     -- 保管場所コード
            , od_disable_date => lt_sec_inv_disable_date                                           -- 無効日
            , ov_errbuf       => lv_errbuf                                                         -- エラーメッセージ
            , ov_retcode      => lv_retcode                                                        -- リターン・コード
            , ov_errmsg       => lv_errmsg                                                         -- ユーザー・エラーメッセージ
          );
--
          -- 戻り値の保管場所コードがNULLの場合
          IF ( gt_sec_inv_nm IS NULL ) THEN
            -- 保管場所存在チェックエラー
            lv_errmsg  := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application_short_name
                            , iv_name         => cv_subinv_found_chk_err_msg
                            , iv_token_name1  => cv_tkn_base_code
                            , iv_token_value1 => gt_inside_info_tab( gn_inside_info_loop_cnt ).base_code
                            , iv_token_name2  => cv_tkn_store_code
                            , iv_token_value2 => gt_inside_info_tab( gn_inside_info_loop_cnt ).ship_warehouse_code
                            , iv_token_name3  => cv_tkn_den_no
                            , iv_token_value3 => gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_num
                          );
            lv_errbuf  := lv_errmsg;
            ov_errmsg  := lv_errmsg;
            ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
            ov_retcode := cv_status_warn;
            -- メッセージ出力
            FND_FILE.PUT_LINE(
                which  => FND_FILE.OUTPUT
              , buff   => ov_errmsg --エラーメッセージ
            );
          -- 戻り値の無効日がTRUNC(NVL(無効日, システム日付+1)) <= TRUNC(システム日付)の場合
          ELSIF ( TRUNC( NVL( lt_sec_inv_disable_date, cd_creation_date + 1 ) ) <= TRUNC( cd_creation_date ) ) THEN
            -- 保管場所有効チェックエラー
            lv_errmsg  := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application_short_name
                            , iv_name         => cv_subinv_valid_chk_err_msg
                            , iv_token_name1  => cv_tkn_subinventory_code
                            , iv_token_value1 => gt_sec_inv_nm
                            , iv_token_name2  => cv_tkn_den_no
                            , iv_token_value2 => gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_num
                          );
            lv_errbuf  := lv_errmsg;
            ov_errmsg  := lv_errmsg;
            ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
            ov_retcode := cv_status_warn;
            -- メッセージ出力
            FND_FILE.PUT_LINE(
                which  => FND_FILE.OUTPUT
              , buff   => ov_errmsg --エラーメッセージ
            );
          END IF;
--
        END IF;
--
      END IF;
--
    END IF;
--
    -- ===============================
    -- 勘定科目別名存在チェック
    -- ===============================
    -- 伝票区分が「10」（工場入庫）且つ品目区分が「2」（資材）以外の場合
    IF ( ( gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_type = cv_slip_type_10 )
      AND ( gt_inside_info_tab( gn_inside_info_loop_cnt ).segment1 <> cv_segment1 ) ) THEN
--
      -- 勘定科目別名IDの取得
      gn_disposition_id := xxcoi_common_pkg.get_disposition_id_2(
                               iv_inv_account_kbn => cv_inv_account_kbn_01 -- 入出庫勘定区分
                             , iv_dept_code       => gt_acc_dept_code      -- 部門コード
                             , in_organization_id => gt_org_id             -- 在庫組織ID
                           );
--
      -- 戻り値の勘定科目別名IDがNULLの場合
      IF ( gn_disposition_id IS NULL ) THEN
        -- 勘定科目別名存在チェックエラー
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_act_type_found_chk_err_msg
                       , iv_token_name1  => cv_tkn_base_code
                       , iv_token_value1 => gt_acc_dept_code
                       , iv_token_name2  => cv_tkn_act_type
                       , iv_token_value2 => cv_inv_account_kbn_01
                       , iv_token_name3  => cv_tkn_den_no
                       , iv_token_value3 => gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_num
                     );
        lv_errbuf  := lv_errmsg;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
        ov_retcode := cv_status_warn;
        -- 勘定科目別名IDチェックエラー判別用フラグON
        lv_disposition_id_chk_flag := cv_flag_on;
        -- メッセージ出力
        FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
          , buff   => ov_errmsg --エラーメッセージ
        );
      END IF;
--
    -- 伝票区分が「10」（工場入庫）且つ品目区分が「2」（資材）の場合
    ELSIF ( ( gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_type = cv_slip_type_10 )
      AND ( gt_inside_info_tab( gn_inside_info_loop_cnt ).segment1 = cv_segment1 ) ) THEN
--
      -- 梱包材料一時受入の勘定科目別名IDの取得
      gn_disposition_id := xxcoi_common_pkg.get_disposition_id_2(
                               iv_inv_account_kbn => cv_inv_account_kbn_02 -- 入出庫勘定区分
                             , iv_dept_code       => gt_acc_dept_code      -- 部門コード
                             , in_organization_id => gt_org_id             -- 在庫組織ID
                           );
--
      -- 戻り値の勘定科目別名IDがNULLの場合
      IF ( gn_disposition_id IS NULL ) THEN
        -- 勘定科目別名存在チェックエラー
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_act_type_found_chk_err_msg
                       , iv_token_name1  => cv_tkn_base_code
                       , iv_token_value1 => gt_acc_dept_code
                       , iv_token_name2  => cv_tkn_act_type
                       , iv_token_value2 => cv_inv_account_kbn_02
                       , iv_token_name3  => cv_tkn_den_no
                       , iv_token_value3 => gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_num
                     );
        lv_errbuf  := lv_errmsg;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
        ov_retcode := cv_status_warn;
        -- 勘定科目別名IDチェックエラー判別用フラグON
        lv_disposition_id_chk_flag := cv_flag_on;
        -- メッセージ出力
        FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
          , buff   => ov_errmsg --エラーメッセージ
        );
      END IF;
--
      -- 梱包材料原価振替の勘定科目別名IDの取得
      gn_disposition_id_2 := xxcoi_common_pkg.get_disposition_id_2(
                                 iv_inv_account_kbn => cv_inv_account_kbn_21                                   -- 入出庫勘定区分
                               , iv_dept_code       => gt_inside_info_tab( gn_inside_info_loop_cnt ).base_code -- 部門コード
                               , in_organization_id => gt_org_id                                               -- 在庫組織ID
                             );
--
      -- 戻り値の勘定科目別名IDがNULLの場合
      IF ( gn_disposition_id_2 IS NULL ) THEN
        -- 勘定科目別名存在チェックエラー
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_act_type_found_chk_err_msg
                       , iv_token_name1  => cv_tkn_base_code
                       , iv_token_value1 => gt_inside_info_tab( gn_inside_info_loop_cnt ).base_code
                       , iv_token_name2  => cv_tkn_act_type
                       , iv_token_value2 => cv_inv_account_kbn_21
                       , iv_token_name3  => cv_tkn_den_no
                       , iv_token_value3 => gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_num
                     );
        lv_errbuf  := lv_errmsg;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
        ov_retcode := cv_status_warn;
        -- 勘定科目別名IDチェックエラー判別用フラグON
        lv_disposition_id_chk_flag := cv_flag_on;
        -- メッセージ出力
        FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
          , buff   => ov_errmsg --エラーメッセージ
        );
      END IF;
--
    END IF;
--
    -- ===============================
    -- 勘定科目別名有効チェック
    -- ===============================
    -- 勘定科目別名IDがNULLの場合はスキップ
    IF ( lv_disposition_id_chk_flag = cv_flag_off ) THEN
--
      -- ローカル変数の初期化(勘定科目別名ID)
      gn_disposition_id   := NULL; -- 勘定科目別名ID
      gn_disposition_id_2 := NULL; -- 勘定科目別名ID(梱包材料原価振替)
--
      -- 伝票区分が「10」（工場入庫）且つ品目区分が「2」（資材）以外場合
      IF ( gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_type = cv_slip_type_10
        AND gt_inside_info_tab( gn_inside_info_loop_cnt ).segment1 <> cv_segment1 ) THEN
--
        -- 勘定科目別名IDの取得
        gn_disposition_id := xxcoi_common_pkg.get_disposition_id(
                                 iv_inv_account_kbn => cv_inv_account_kbn_01 -- 入出庫勘定区分
                               , iv_dept_code       => gt_acc_dept_code      -- 部門コード
                               , in_organization_id => gt_org_id             -- 在庫組織ID
                             );
--
        -- 戻り値の勘定科目別名IDがNULLの場合
        IF ( gn_disposition_id IS NULL ) THEN
          -- 勘定科目別名有効チェックエラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application_short_name
                         , iv_name         => cv_act_type_valid_chk_err_msg
                         , iv_token_name1  => cv_tkn_base_code
                         , iv_token_value1 => gt_acc_dept_code
                         , iv_token_name2  => cv_tkn_act_type
                         , iv_token_value2 => cv_inv_account_kbn_01
                         , iv_token_name3  => cv_tkn_den_no
                         , iv_token_value3 => gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_num
                       );
          lv_errbuf  := lv_errmsg;
          ov_errmsg  := lv_errmsg;
          ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
          ov_retcode := cv_status_warn;
          -- メッセージ出力
          FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
            , buff   => ov_errmsg --エラーメッセージ
          );
        END IF;
--
      -- 伝票区分が「10」（工場入庫）且つ品目区分が「2」（資材）の場合
      ELSIF ( ( gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_type = cv_slip_type_10 )
        AND ( gt_inside_info_tab( gn_inside_info_loop_cnt ).segment1 = cv_segment1 ) ) THEN
--
        -- 梱包材料一時受入の勘定科目別名IDの取得
        gn_disposition_id := xxcoi_common_pkg.get_disposition_id(
                                 iv_inv_account_kbn => cv_inv_account_kbn_02 -- 入出庫勘定区分
                               , iv_dept_code       => gt_acc_dept_code      -- 部門コード
                               , in_organization_id => gt_org_id             -- 在庫組織ID
                             );
--
        -- 戻り値の勘定科目別名IDがNULLの場合
        IF ( gn_disposition_id IS NULL ) THEN
          -- 勘定科目別名有効チェックエラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application_short_name
                         , iv_name         => cv_act_type_valid_chk_err_msg
                         , iv_token_name1  => cv_tkn_base_code
                         , iv_token_value1 => gt_acc_dept_code
                         , iv_token_name2  => cv_tkn_act_type
                         , iv_token_value2 => cv_inv_account_kbn_02
                         , iv_token_name3  => cv_tkn_den_no
                         , iv_token_value3 => gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_num
                       );
          lv_errbuf  := lv_errmsg;
          ov_errmsg  := lv_errmsg;
          ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
          ov_retcode := cv_status_warn;
          -- メッセージ出力
          FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
            , buff   => ov_errmsg --エラーメッセージ
          );
        END IF;
--
        -- 梱包材料原価振替の勘定科目別名IDの取得
        gn_disposition_id_2 := xxcoi_common_pkg.get_disposition_id(
                                   iv_inv_account_kbn => cv_inv_account_kbn_21                                   -- 入出庫勘定区分
                                 , iv_dept_code       => gt_inside_info_tab( gn_inside_info_loop_cnt ).base_code -- 部門コード
                                 , in_organization_id => gt_org_id                                               -- 在庫組織ID
                               );
--
        -- 戻り値の勘定科目別名IDがNULLの場合
        IF ( gn_disposition_id_2 IS NULL ) THEN
          -- 勘定科目別名有効チェックエラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application_short_name
                         , iv_name         => cv_act_type_valid_chk_err_msg
                         , iv_token_name1  => cv_tkn_base_code
                         , iv_token_value1 => gt_inside_info_tab( gn_inside_info_loop_cnt ).base_code
                         , iv_token_name2  => cv_tkn_act_type
                         , iv_token_value2 => cv_inv_account_kbn_21
                         , iv_token_name3  => cv_tkn_den_no
                         , iv_token_value3 => gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_num
                       );
          lv_errbuf  := lv_errmsg;
          ov_errmsg  := lv_errmsg;
          ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
          ov_retcode := cv_status_warn;
          -- メッセージ出力
          FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
            , buff   => ov_errmsg --エラーメッセージ
          );
        END IF;
--
      END IF;
--
    END IF;
--
    -- ===============================
    -- 在庫会計期間チェック
    -- ===============================
    xxcoi_common_pkg.org_acct_period_chk(
        in_organization_id => gt_org_id                                               -- 在庫組織ID
      , id_target_date     => gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_date -- 対象日
      , ob_chk_result      => lb_chk_result                                           -- チェック結果
      , ov_errbuf          => lv_errbuf                                               -- エラーメッセージ
      , ov_retcode         => lv_retcode                                              -- リターン・コード
      , ov_errmsg          => lv_errmsg                                               -- ユーザー・エラーメッセージ
    );
--
   -- 戻り値のステータスがFALSEの場合
   IF ( lb_chk_result = FALSE ) THEN
     -- 伝票日付在庫会計期間チェックエラー
     lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application_short_name
                    , iv_name         => cv_inv_acc_period_chk_err_msg
                    , iv_token_name1  => cv_tkn_den_no
                    , iv_token_value1 => gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_num
                    , iv_token_name2  => cv_tkn_entry_date
                    , iv_token_value2 => TO_CHAR( gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_date, 'YYYY/MM/DD' )
                  );
     lv_errbuf  := lv_errmsg;
     ov_errmsg  := lv_errmsg;
     ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
     ov_retcode := cv_status_warn;
     -- メッセージ出力
     FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
       , buff   => ov_errmsg --エラーメッセージ
     );
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
  END chk_category;
--
  /**********************************************************************************
   * Procedure Name   : ins_mtl_tran_if_tab
   * Description      : 資材取引OIF挿入処理 (A-6)
   ***********************************************************************************/
  PROCEDURE ins_mtl_tran_if_tab(
    gn_inside_info_loop_cnt  IN   NUMBER,    -- 取引ID単位ループカウンタ
    ov_errbuf                OUT  VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT  VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg                OUT  VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_mtl_tran_if_tab'; -- プログラム名
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
    cv_1                         CONSTANT VARCHAR2(1) := '1';  -- 固定値 1
    cv_3                         CONSTANT VARCHAR2(1) := '3';  -- 固定値 3
--
    -- *** ローカル変数 ***
    lv_subinventory_code         VARCHAR2(100); -- 保管場所コード
    lv_source_code               VARCHAR2(100); -- 取引ソースID
    lv_transaction_type_id       VARCHAR2(100); -- 取引タイプID
    lv_transaction_quantity      VARCHAR2(100); -- 取引数量
    lv_transfer_subinventory     VARCHAR2(100); -- 相手先保管場所コード
    lv_transfer_organization     VARCHAR2(100); -- 相手先在庫組織ID
    lv_attribute5                VARCHAR2(100); -- ATTRIBUTE5（出庫拠点コード）
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
    -- ローカル変数の初期化
    lv_subinventory_code     := NULL; -- 保管場所コード
    lv_source_code           := NULL; -- 取引ソースID
    lv_transaction_type_id   := NULL; -- 取引タイプID
    lv_transaction_quantity  := NULL; -- 取引数量
    lv_transfer_subinventory := NULL; -- 相手先保管場所コード
    lv_transfer_organization := NULL; -- 相手先在庫組織ID
    lv_attribute5            := NULL; -- ATTRIBUTE5（出庫拠点コード）
--
    -- 値の設定
    -- 伝票区分が「10」（工場入庫）の場合
    IF ( gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_type = cv_slip_type_10 ) THEN
--
      lv_subinventory_code     := gt_sec_inv_nm; -- 保管場所コード
--
      -- 品目区分が「2」（資材）以外の場合
      -- 品目区分が「2」（資材）の場合（梱包材料一時受入）
      lv_source_code           := gn_disposition_id; -- 取引ソースID
--
      -- 品目区分が「2」（資材）以外且つ取引数量 > 0の場合
      IF ( ( gt_inside_info_tab( gn_inside_info_loop_cnt ).segment1 <> cv_segment1 )
        AND ( gt_inside_info_tab( gn_inside_info_loop_cnt ).material_transaction_unset_qty > 0 ) ) THEN
        lv_transaction_type_id := gt_tran_type_factory_stock;   -- 取引タイプID 工場入庫
      -- 品目区分が「2」（資材）以外且つ取引数量 < 0の場合
      ELSIF ( ( gt_inside_info_tab( gn_inside_info_loop_cnt ).segment1 <> cv_segment1 )
        AND ( gt_inside_info_tab( gn_inside_info_loop_cnt ).material_transaction_unset_qty < 0 ) ) THEN
        lv_transaction_type_id := gt_tran_type_factory_stock_b; -- 取引タイプID 工場入庫振戻
      -- 品目区分が「2」（資材）且つ取引数量 > 0の場合
      ELSIF ( ( gt_inside_info_tab( gn_inside_info_loop_cnt ).segment1 = cv_segment1 )
        AND ( gt_inside_info_tab( gn_inside_info_loop_cnt ).material_transaction_unset_qty > 0 ) ) THEN
        lv_transaction_type_id := gt_tran_type_pack_receive;    -- 取引タイプID 梱包材料一時受入
      -- 品目区分が「2」（資材）且つ取引数量 < 0の場合
      ELSIF ( ( gt_inside_info_tab( gn_inside_info_loop_cnt ).segment1 = cv_segment1 )
        AND ( gt_inside_info_tab( gn_inside_info_loop_cnt ).material_transaction_unset_qty < 0 ) ) THEN
        lv_transaction_type_id := gt_tran_type_pack_receive_b;  -- 取引タイプID 梱包材料一時受入振戻
      END IF;
--
      lv_transaction_quantity  := gt_inside_info_tab( gn_inside_info_loop_cnt ).material_transaction_unset_qty; -- 取引数量
      lv_transfer_subinventory := NULL; -- 相手先保管場所コード
      lv_transfer_organization := NULL; -- 相手先在庫組織ID
--
      -- 取引数量 > 0の場合
      IF ( gt_inside_info_tab( gn_inside_info_loop_cnt ).material_transaction_unset_qty > 0 ) THEN
        lv_attribute5          := gt_inside_info_tab( gn_inside_info_loop_cnt ).ship_base_code; -- ATTRIBUTE5（出庫拠点コード）
      -- 取引数量 < 0の場合
      ELSIF ( gt_inside_info_tab( gn_inside_info_loop_cnt ).material_transaction_unset_qty < 0 ) THEN
        lv_attribute5          := gt_inside_info_tab( gn_inside_info_loop_cnt ).base_code; -- ATTRIBUTE5（出庫拠点コード）
      END IF;
--
    -- 伝票区分が「20」（拠点間入庫）の場合
    ELSIF ( gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_type = cv_slip_type_20 ) THEN
--
      -- 取引数量 > 0の場合
      IF ( gt_inside_info_tab( gn_inside_info_loop_cnt ).material_transaction_unset_qty > 0 ) THEN
        lv_subinventory_code   := gt_sec_inv_nm_2; -- 保管場所コード
      -- 取引数量 < 0の場合
      ELSIF ( gt_inside_info_tab( gn_inside_info_loop_cnt ).material_transaction_unset_qty < 0 ) THEN
        lv_subinventory_code   := gt_sec_inv_nm; -- 保管場所コード
      END IF;
--
      lv_source_code           := NULL; -- 取引ソースID
      lv_transaction_type_id   := gt_tran_type_inout; -- 取引タイプID 入出庫
      lv_transaction_quantity  := ABS( gt_inside_info_tab( gn_inside_info_loop_cnt ).material_transaction_unset_qty ); -- 取引数量
--
      -- 取引数量 > 0の場合
      IF ( gt_inside_info_tab( gn_inside_info_loop_cnt ).material_transaction_unset_qty > 0 ) THEN
        lv_transfer_subinventory := gt_sec_inv_nm; -- 相手先保管場所コード
      -- 取引数量 < 0の場合
      ELSIF ( gt_inside_info_tab( gn_inside_info_loop_cnt ).material_transaction_unset_qty < 0 ) THEN
        lv_transfer_subinventory := gt_sec_inv_nm_2; -- 相手先保管場所コード
      END IF;
--
      lv_transfer_organization := gt_org_id; -- 相手先在庫組織ID
--
      -- 取引数量 > 0の場合
      IF ( gt_inside_info_tab( gn_inside_info_loop_cnt ).material_transaction_unset_qty > 0 ) THEN
        lv_attribute5          := gt_inside_info_tab( gn_inside_info_loop_cnt ).ship_base_code; -- ATTRIBUTE5（出庫拠点コード）
      -- 取引数量 < 0の場合
      ELSIF ( gt_inside_info_tab( gn_inside_info_loop_cnt ).material_transaction_unset_qty < 0 ) THEN
        lv_attribute5          := gt_inside_info_tab( gn_inside_info_loop_cnt ).base_code; -- ATTRIBUTE5（出庫拠点コード）
      END IF;
--
    END IF;
--
    -- 工場入庫、工場入庫振戻、梱包材料一時受入、梱包材料一時受入振戻、入出庫の資材取引データを資材取引OIFへ登録
    INSERT INTO mtl_transactions_interface(
        source_code                                                     -- ソースコード
      , source_line_id                                                  -- ソースラインID
      , source_header_id                                                -- ソースヘッダーID
      , process_flag                                                    -- プロセスフラグ
      , transaction_mode                                                -- 取引モード
      , inventory_item_id                                               -- 品目ID
      , organization_id                                                 -- 在庫組織ID
      , transaction_quantity                                            -- 取引数量
      , primary_quantity                                                -- 基準単位数量
      , transaction_uom                                                 -- 基準単位
      , transaction_date                                                -- 取引日
      , subinventory_code                                               -- 保管場所コード
      , transaction_source_id                                           -- 取引ソースID
      , transaction_type_id                                             -- 取引タイプID
      , transfer_subinventory                                           -- 相手先保管場所コード
      , transfer_organization                                           -- 相手先在庫組織ID
      , attribute1                                                      -- 伝票No
      , attribute3                                                      -- 子品目コード
      , attribute5                                                      -- 出庫拠点コード
      , created_by                                                      -- 作成者
      , creation_date                                                   -- 作成日
      , last_updated_by                                                 -- 最終更新者
      , last_update_date                                                -- 最終更新日
      , last_update_login                                               -- 最終更新ログイン
      , request_id                                                      -- 要求ID
      , program_application_id                                          -- プログラムアプリケーションID
      , program_id                                                      -- プログラムID
      , program_update_date                                             -- プログラム更新日
    )
    VALUES(
        cv_pkg_name                                                     -- ソースコード
      , cv_1                                                            -- ソースラインID
      , gt_inside_info_tab( gn_inside_info_loop_cnt ).transaction_id    -- ソースヘッダーID
      , cv_1                                                            -- プロセスフラグ
      , cv_3                                                            -- 取引モード
      , gt_inside_info_tab( gn_inside_info_loop_cnt ).inventory_item_id -- 品目ID
      , gt_org_id                                                       -- 在庫組織ID
      , lv_transaction_quantity                                         -- 取引数量
      , lv_transaction_quantity                                         -- 基準単位数量
      , gt_primary_uom_code                                             -- 基準単位
      , gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_date         -- 取引日
      , lv_subinventory_code                                            -- 保管場所コード
      , lv_source_code                                                  -- 取引ソースID
      , lv_transaction_type_id                                          -- 取引タイプID
      , lv_transfer_subinventory                                        -- 相手先保管場所コード
      , lv_transfer_organization                                        -- 相手先在庫組織ID
      , gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_num          -- 伝票No
      , gt_inside_info_tab( gn_inside_info_loop_cnt ).item_code         -- 子品目コード
      , lv_attribute5                                                   -- 出庫拠点コード
      , cn_created_by                                                   -- 作成者
      , cd_creation_date                                                -- 作成日
      , cn_last_updated_by                                              -- 最終更新者
      , cd_last_update_date                                             -- 最終更新日
      , cn_last_update_login                                            -- 最終更新ログイン
      , cn_request_id                                                   -- 要求ID
      , cn_program_application_id                                       -- プログラムアプリケーションID
      , cn_program_id                                                   -- プログラムID
      , cd_program_update_date                                          -- プログラム更新日
    );
--
    -- 値の設定
    -- 伝票区分が「10」（工場入庫）且つ品目区分が「2」（資材）の場合
    IF ( ( gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_type = cv_slip_type_10 )
      AND ( gt_inside_info_tab( gn_inside_info_loop_cnt ).segment1 = cv_segment1 ) ) THEN
--
      -- 取引数量 > 0の場合
      IF ( gt_inside_info_tab( gn_inside_info_loop_cnt ).material_transaction_unset_qty > 0 ) THEN
        lv_transaction_type_id := gt_tran_type_transfer_cost;   -- 取引タイプID
      -- 取引数量 < 0の場合
      ELSIF ( gt_inside_info_tab( gn_inside_info_loop_cnt ).material_transaction_unset_qty < 0 ) THEN
        lv_transaction_type_id := gt_tran_type_transfer_cost_b; -- 取引タイプID
      END IF;
--
      -- 取引数量 > 0の場合
      IF ( gt_inside_info_tab( gn_inside_info_loop_cnt ).material_transaction_unset_qty > 0 ) THEN
        lv_attribute5          := gt_inside_info_tab( gn_inside_info_loop_cnt ).ship_base_code; -- ATTRIBUTE5（出庫拠点コード）
      -- 取引数量 < 0の場合
      ELSIF ( gt_inside_info_tab( gn_inside_info_loop_cnt ).material_transaction_unset_qty < 0 ) THEN
        lv_attribute5          := gt_inside_info_tab( gn_inside_info_loop_cnt ).base_code; -- ATTRIBUTE5（出庫拠点コード）
      END IF;
--
      -- 梱包材料原価振替、梱包材料原価振替振戻の資材取引データを資材取引OIFへ登録
      INSERT INTO mtl_transactions_interface(
          source_code                                                                               -- ソースコード
        , source_line_id                                                                            -- ソースラインID
        , source_header_id                                                                          -- ソースヘッダーID
        , process_flag                                                                              -- プロセスフラグ
        , transaction_mode                                                                          -- 取引モード
        , inventory_item_id                                                                         -- 品目ID
        , organization_id                                                                           -- 在庫組織ID
        , transaction_quantity                                                                      -- 取引数量
        , primary_quantity                                                                          -- 基準単位数量
        , transaction_uom                                                                           -- 基準単位
        , transaction_date                                                                          -- 取引日
        , subinventory_code                                                                         -- 保管場所コード
        , transaction_source_id                                                                     -- 取引ソースID
        , transaction_type_id                                                                       -- 取引タイプID
        , transfer_subinventory                                                                     -- 相手先保管場所コード
        , transfer_organization                                                                     -- 相手先在庫組織ID
        , attribute1                                                                                -- 伝票No
        , attribute3                                                                                -- 子品目コード
        , attribute5                                                                                -- 出庫拠点コード
        , created_by                                                                                -- 作成者
        , creation_date                                                                             -- 作成日
        , last_updated_by                                                                           -- 最終更新者
        , last_update_date                                                                          -- 最終更新日
        , last_update_login                                                                         -- 最終更新ログイン
        , request_id                                                                                -- 要求ID
        , program_application_id                                                                    -- プログラムアプリケーションID
        , program_id                                                                                -- プログラムID
        , program_update_date                                                                       -- プログラム更新日
      )
      VALUES(
          cv_pkg_name                                                                               -- ソースコード
        , cv_1                                                                                      -- ソースラインID
        , gt_inside_info_tab( gn_inside_info_loop_cnt ).transaction_id                              -- ソースヘッダーID
        , cv_1                                                                                      -- プロセスフラグ
        , cv_3                                                                                      -- 取引モード
        , gt_inside_info_tab( gn_inside_info_loop_cnt ).inventory_item_id                           -- 品目ID
        , gt_org_id                                                                                 -- 在庫組織ID
        , ( gt_inside_info_tab( gn_inside_info_loop_cnt ).material_transaction_unset_qty * ( -1 ) ) -- 取引数量
        , ( gt_inside_info_tab( gn_inside_info_loop_cnt ).material_transaction_unset_qty * ( -1 ) ) -- 基準単位数量
        , gt_primary_uom_code                                                                       -- 基準単位
        , gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_date                                   -- 取引日
        , gt_sec_inv_nm                                                                             -- 保管場所コード
        , gn_disposition_id_2                                                                       -- 取引ソースID
        , lv_transaction_type_id                                                                    -- 取引タイプID
        , NULL                                                                                      -- 相手先保管場所コード
        , NULL                                                                                      -- 相手先在庫組織ID
        , gt_inside_info_tab( gn_inside_info_loop_cnt ).slip_num                                    -- 伝票No
        , gt_inside_info_tab( gn_inside_info_loop_cnt ).item_code                                   -- 子品目コード
        , lv_attribute5                                                                             -- 出庫拠点コード
        , cn_created_by                                                                             -- 作成者
        , cd_creation_date                                                                          -- 作成日
        , cn_last_updated_by                                                                        -- 最終更新者
        , cd_last_update_date                                                                       -- 最終更新日
        , cn_last_update_login                                                                      -- 最終更新ログイン
        , cn_request_id                                                                             -- 要求ID
        , cn_program_application_id                                                                 -- プログラムアプリケーションID
        , cn_program_id                                                                             -- プログラムID
        , cd_program_update_date                                                                    -- プログラム更新日
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
  END ins_mtl_tran_if_tab;
--
  /**********************************************************************************
   * Procedure Name   : get_lock
   * Description      : ロック取得処理 (A-7)
   ***********************************************************************************/
  PROCEDURE get_lock(
    gn_slip_loop_cnt        IN  NUMBER DEFAULT NULL,  -- 伝票単位ループカウンタ
    gn_inside_info_loop_cnt IN  NUMBER DEFAULT NULL,  -- 取引ID単位ループカウンタ
    ov_errbuf               OUT VARCHAR2,             -- エラー・メッセージ                  --# 固定 #
    ov_retcode              OUT VARCHAR2,             -- リターン・コード                    --# 固定 #
    ov_errmsg               OUT VARCHAR2)             -- ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lock'; -- プログラム名
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
    -- 入庫情報一時表ロック取得(資材取引OIFへのデータ作成が正常終了)
    CURSOR transaction_id_cur
    IS
      SELECT  xsi.slip_num              AS slip_num                                                    -- 伝票No
      FROM    xxcoi_storage_information xsi                                                            -- 入庫情報一時表
      WHERE   xsi.transaction_id        = gt_inside_info_tab( gn_inside_info_loop_cnt ).transaction_id -- 取引ID
      FOR UPDATE OF xsi.slip_num NOWAIT
    ;
--
    -- 入庫情報一時表ロック取得(項目チェックまたはロック取得処理でエラーの場合)
    CURSOR xsi_slip_num_cur
    IS
      SELECT  xsi.slip_num              AS slip_num                           -- 伝票No
      FROM    xxcoi_storage_information xsi                                   -- 入庫情報一時表
      WHERE   xsi.slip_num              = gt_slip_num_tab( gn_slip_loop_cnt ) -- 伝票No
      FOR UPDATE OF xsi.slip_num NOWAIT
    ;
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
    -- 資材取引OIFへのデータ作成が正常の場合
    IF ( gn_err_flag_cnt = 0 ) THEN
      -- カーソルオープン
      OPEN transaction_id_cur;
      -- カーソルクローズ
      CLOSE transaction_id_cur;
    -- 項目チェックまたはロック取得処理でエラーの場合
    ELSIF ( gn_err_flag_cnt > 0 ) THEN
      -- カーソルオープン
      OPEN xsi_slip_num_cur;
      -- カーソルクローズ
      CLOSE xsi_slip_num_cur;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- ロック取得エラー
    WHEN lock_expt THEN
      -- カーソルがOPENしている場合
      IF ( transaction_id_cur%ISOPEN ) THEN
        CLOSE transaction_id_cur;
      ELSIF ( xsi_slip_num_cur%ISOPEN ) THEN
        CLOSE xsi_slip_num_cur;
      END IF;
      -- 資材取引OIFへのデータ作成が正常の場合
      IF ( gn_err_flag_cnt = 0 ) THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application_short_name
                        , iv_name         => cv_table_lock_err_2_msg
                        , iv_token_name1  => cv_tkn_tran_id
                        , iv_token_value1 => TO_CHAR( gt_inside_info_tab( gn_inside_info_loop_cnt ).transaction_id )
                      );
        lv_errbuf  := lv_errmsg;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
        ov_retcode := cv_status_warn;
        -- メッセージ出力
        FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
          , buff   => ov_errmsg --エラーメッセージ
        );
      -- 項目チェックまたはロック取得処理でエラーの場合
      ELSIF ( gn_err_flag_cnt > 0 ) THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application_short_name
                        , iv_name         => cv_table_lock_err_msg
                        , iv_token_name1  => cv_tkn_den_no
                        , iv_token_value1 => gt_slip_num_tab( gn_slip_loop_cnt )
                      );
        lv_errbuf  := lv_errmsg;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
        ov_retcode := cv_status_warn;
        -- メッセージ出力
        FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
          , buff   => ov_errmsg --エラーメッセージ
        );
      END IF;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルがOPENしている場合
      IF ( transaction_id_cur%ISOPEN ) THEN
        CLOSE transaction_id_cur;
      ELSIF ( xsi_slip_num_cur%ISOPEN ) THEN
        CLOSE xsi_slip_num_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルがOPENしている場合
      IF ( transaction_id_cur%ISOPEN ) THEN
        CLOSE transaction_id_cur;
      ELSIF ( xsi_slip_num_cur%ISOPEN ) THEN
        CLOSE xsi_slip_num_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルがOPENしている場合
      IF ( transaction_id_cur%ISOPEN ) THEN
        CLOSE transaction_id_cur;
      ELSIF ( xsi_slip_num_cur%ISOPEN ) THEN
        CLOSE xsi_slip_num_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_lock;
--
  /**********************************************************************************
   * Procedure Name   : upd_storage_info_tab
   * Description      : 入庫情報一時表更新処理 (A-8)
   ***********************************************************************************/
  PROCEDURE upd_storage_info_tab(
    gn_slip_loop_cnt         IN   NUMBER DEFAULT NULL,  -- 伝票単位ループカウンタ
    gn_inside_info_loop_cnt  IN   NUMBER DEFAULT NULL,  -- 倉替データループカウンタ
    ov_errbuf                OUT  VARCHAR2,             -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT  VARCHAR2,             -- リターン・コード             --# 固定 #
    ov_errmsg                OUT  VARCHAR2)             -- ユーザー・エラー・メッセージ --# 固定 #
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
    cv_status_post               CONSTANT VARCHAR2(1) := '1';  -- 処理ステータス 1：処理済
    cv_zero                      CONSTANT VARCHAR2(1) := '0';  -- 固定値 0
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
    -- 資材取引OIFへのデータ作成が正常の場合
    IF ( gn_err_flag_cnt = 0 ) THEN
      -- 入庫情報一時表の更新
      UPDATE xxcoi_storage_information xsi                                                                       -- 入庫情報一時表
      SET    xsi.material_transaction_set_flag  = cv_flag_on                                                     -- 資材取引連携済フラグ
           , xsi.material_transaction_unset_qty = cv_zero                                                        -- 資材取引未連携数量
           , xsi.last_updated_by                = cn_last_updated_by                                             -- 最終更新者
           , xsi.last_update_date               = cd_last_update_date                                            -- 最終更新日
           , xsi.last_update_login              = cn_last_update_login                                           -- 最終更新ログイン
           , xsi.request_id                     = cn_request_id                                                  -- 要求ID
           , xsi.program_application_id         = cn_program_application_id                                      -- プログラムアプリケーションID
           , xsi.program_id                     = cn_program_id                                                  -- プログラムID
           , xsi.program_update_date            = cd_program_update_date                                         -- プログラム更新日
      WHERE  xsi.transaction_id                 = gt_inside_info_tab( gn_inside_info_loop_cnt ).transaction_id   -- 取引ID
      ;
    -- 項目チェックまたはロック取得処理でエラーの場合
    ELSIF ( gn_err_flag_cnt > 0 ) THEN
      -- 入庫情報一時表の更新
      UPDATE xxcoi_storage_information xsi                                                                       -- 入庫情報一時表
      SET    xsi.check_case_qty                 = DECODE( ( xsi.check_summary_qty - xsi.material_transaction_unset_qty ), 0, 0,
                                                    DECODE( xsi.case_in_qty, 0, 0,
                                                      TRUNC( ( xsi.check_summary_qty - xsi.material_transaction_unset_qty )
                                                           / xsi.case_in_qty ) ) )                               -- 確認数量ケース数
           , xsi.check_singly_qty               = DECODE( ( xsi.check_summary_qty - xsi.material_transaction_unset_qty ), 0, 0,
                                                    MOD( ( xsi.check_summary_qty - xsi.material_transaction_unset_qty ),
                                                           xsi.case_in_qty ) )                                   -- 確認数量バラ数
           , xsi.check_summary_qty              = ( xsi.check_summary_qty - xsi.material_transaction_unset_qty ) -- 確認数量総バラ数
           , xsi.material_transaction_unset_qty = 0                                                              -- 資材取引未連携数量
           , xsi.store_check_flag               = DECODE( ( xsi.check_summary_qty - xsi.material_transaction_unset_qty ), 0, cv_flag_off,
                                                            xsi.store_check_flag )                               -- 入庫確認フラグ
           , xsi.last_updated_by                = cn_last_updated_by                                             -- 最終更新者
           , xsi.last_update_date               = cd_last_update_date                                            -- 最終更新日
           , xsi.last_update_login              = cn_last_update_login                                           -- 最終更新ログイン
           , xsi.request_id                     = cn_request_id                                                  -- 要求ID
           , xsi.program_application_id         = cn_program_application_id                                      -- プログラムアプリケーションID
           , xsi.program_id                     = cn_program_id                                                  -- プログラムID
           , xsi.program_update_date            = cd_program_update_date                                         -- プログラム更新日
      WHERE  xsi.slip_num                       = gt_slip_num_tab( gn_slip_loop_cnt )                            -- 伝票No
      AND    xsi.material_transaction_set_flag  = cv_flag_off                                                    -- 資材取引連携済フラグ
      ;
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
--
    -- *** ローカル変数 ***
    lv_lock_err_flag             VARCHAR2(1); -- ロック取得エラー判別用フラグ
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
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
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--    gn_warn_cnt   := 0;
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
    -- 対象伝票No取得処理 (A-2)
    -- ===============================
    get_slip_num(
        ov_errbuf  => lv_errbuf  -- エラー・メッセージ           --# 固定 #
      , ov_retcode => lv_retcode -- リターン・コード             --# 固定 #
      , ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 伝票No取得件数が0件の場合
    IF ( gn_target_cnt = 0 ) THEN
      RAISE no_data_expt;
    END IF;
--
    -- 伝票単位ループ開始
    <<gt_slip_num_tab_loop>>
    FOR gn_slip_loop_cnt IN 1 .. gn_target_cnt LOOP
--
      -- エラー判別用カウンタ初期化
      gn_err_flag_cnt := 0;
--
      -- ===============================
      -- セーブポイント設定 (A-3)
      -- ===============================
      SAVEPOINT slip_point;
--
      -- ===============================
      -- 入庫情報取得処理 (A-4)
      -- ===============================
      get_inside_info(
          gn_slip_loop_cnt => gn_slip_loop_cnt -- 伝票単位ループカウンタ
        , ov_errbuf        => lv_errbuf        -- エラー・メッセージ           --# 固定 #
        , ov_retcode       => lv_retcode       -- リターン・コード             --# 固定 #
        , ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- 取引ID単位件数が0件の場合
      IF ( gn_inside_info_cnt = 0 ) THEN
        -- 入庫情報データ無しメッセージ
        lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application_short_name
                        , iv_name         => cv_no_data_inside_info_msg
                        , iv_token_name1  => cv_tkn_den_no
                        , iv_token_value1 => gt_slip_num_tab( gn_slip_loop_cnt )
                      );
        lv_errbuf  := lv_errmsg;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
        ov_retcode := cv_status_warn;
        -- メッセージ出力
        FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
          , buff   => ov_errmsg --エラーメッセージ
        );
        -- エラー件数
        gn_error_cnt := gn_error_cnt + 1;
      -- 取引ID単位件数が1件以上取得できた場合
      ELSIF ( gn_inside_info_cnt > 0 ) THEN
--
        -- 取引ID単位ループ開始
        <<gt_inside_info_tab_loop>>
        FOR gn_inside_info_loop_cnt IN 1 .. gn_inside_info_cnt LOOP
--
-- == 2009/05/18 V1.3 Added START ===============================================================
        -- 資材取引未連携数量 <> 0の場合
        IF ( gt_inside_info_tab( gn_inside_info_loop_cnt ).material_transaction_unset_qty <> 0 ) THEN
-- == 2009/05/18 V1.3 Added END   ===============================================================
          -- ===============================
          -- 項目チェック処理 (A-5)
          -- ===============================
          chk_category(
              gn_inside_info_loop_cnt => gn_inside_info_loop_cnt -- 取引ID単位ループカウンタ
            , ov_errbuf               => lv_errbuf               -- エラー・メッセージ           --# 固定 #
            , ov_retcode              => lv_retcode              -- リターン・コード             --# 固定 #
            , ov_errmsg               => lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
          );
--
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          ELSIF ( lv_retcode = cv_status_warn ) THEN
            -- エラー判別用カウンタ
            gn_err_flag_cnt := gn_err_flag_cnt + 1;
          END IF;
--
          -- 項目チェックにてエラーが発生していない場合
          IF ( gn_err_flag_cnt = 0 ) THEN
--
            -- ===============================
            -- 資材取引OIF挿入処理 (A-6)
            -- ===============================
            ins_mtl_tran_if_tab(
                gn_inside_info_loop_cnt => gn_inside_info_loop_cnt -- 取引ID単位ループカウンタ
              , ov_errbuf               => lv_errbuf               -- エラー・メッセージ           --# 固定 #
              , ov_retcode              => lv_retcode              -- リターン・コード             --# 固定 #
              , ov_errmsg               => lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
            );
--
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            END IF;
--
            -- ===============================
            -- ロック取得処理 (A-7)
            -- ===============================
            get_lock(
                gn_inside_info_loop_cnt => gn_inside_info_loop_cnt -- 取引ID単位ループカウンタ
              , ov_errbuf               => lv_errbuf               -- エラー・メッセージ           --# 固定 #
              , ov_retcode              => lv_retcode              -- リターン・コード             --# 固定 #
              , ov_errmsg               => lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
            );
--
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            ELSIF ( lv_retcode = cv_status_warn ) THEN
              -- エラー判別用カウンタ
              gn_err_flag_cnt := gn_err_flag_cnt + 1;
            END IF;
--
            -- ロック取得エラーが発生していない場合
            IF ( gn_err_flag_cnt = 0 ) THEN
--
              -- ===============================
              -- 入庫情報一時表更新処理 (A-8)
              -- ===============================
              upd_storage_info_tab(
                  gn_inside_info_loop_cnt => gn_inside_info_loop_cnt -- 取引ID単位ループカウンタ
                , ov_errbuf               => lv_errbuf               -- エラー・メッセージ           --# 固定 #
                , ov_retcode              => lv_retcode              -- リターン・コード             --# 固定 #
                , ov_errmsg               => lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
              );
--
              IF ( lv_retcode = cv_status_error ) THEN
                RAISE global_process_expt;
              END IF;
--
            END IF;
--
          END IF;
--
-- == 2009/05/18 V1.3 Added START ===============================================================
        -- 資材取引未連携数量 = 0の場合
        ELSE
          -- ===============================
          -- ロック取得処理 (A-7)
          -- ===============================
          get_lock(
              gn_inside_info_loop_cnt => gn_inside_info_loop_cnt -- 取引ID単位ループカウンタ
            , ov_errbuf               => lv_errbuf               -- エラー・メッセージ           --# 固定 #
            , ov_retcode              => lv_retcode              -- リターン・コード             --# 固定 #
            , ov_errmsg               => lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
          );
--
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          ELSIF ( lv_retcode = cv_status_warn ) THEN
            -- エラー判別用カウンタ
            gn_err_flag_cnt := gn_err_flag_cnt + 1;
          END IF;
--
          -- ロック取得エラーが発生していない場合
          IF ( gn_err_flag_cnt = 0 ) THEN
--
            -- ===============================
            -- 入庫情報一時表更新処理 (A-8)
            -- ===============================
            upd_storage_info_tab(
                gn_inside_info_loop_cnt => gn_inside_info_loop_cnt -- 取引ID単位ループカウンタ
              , ov_errbuf               => lv_errbuf               -- エラー・メッセージ           --# 固定 #
              , ov_retcode              => lv_retcode              -- リターン・コード             --# 固定 #
              , ov_errmsg               => lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
            );
--
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            END IF;
--
          END IF;
--
        END IF;
--
-- == 2009/05/18 V1.3 Added END   ===============================================================
        END LOOP gt_inside_info_tab_loop;
--
        -- 正常の場合
        IF ( gn_err_flag_cnt = 0 ) THEN
          -- 成功件数
          gn_normal_cnt := gn_normal_cnt + 1;
        -- エラーが発生している場合
        ELSIF ( gn_err_flag_cnt > 0 ) THEN
--
          -- セーブポイントまでロールバック
          ROLLBACK TO SAVEPOINT slip_point;
--
          -- ロック取得エラー判別用フラグ初期化
          lv_lock_err_flag := cv_flag_off;
--
          -- ===============================
          -- ロック取得処理 (A-7)
          -- ===============================
          get_lock(
              gn_slip_loop_cnt => gn_slip_loop_cnt -- 伝票単位ループカウンタ
            , ov_errbuf        => lv_errbuf        -- エラー・メッセージ           --# 固定 #
            , ov_retcode       => lv_retcode       -- リターン・コード             --# 固定 #
            , ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
          );
--
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          ELSIF ( lv_retcode = cv_status_warn ) THEN
            -- ロック取得エラー判別用フラグ
            lv_lock_err_flag := cv_flag_on;
          END IF;
--
          -- ロック取得エラーが発生していない場合
          IF ( lv_lock_err_flag = cv_flag_off ) THEN
            -- ===============================
            -- 入庫情報一時表更新処理 (A-8)
            -- ===============================
            upd_storage_info_tab(
                gn_slip_loop_cnt => gn_slip_loop_cnt -- 伝票単位ループカウンタ
              , ov_errbuf        => lv_errbuf        -- エラー・メッセージ           --# 固定 #
              , ov_retcode       => lv_retcode       -- リターン・コード             --# 固定 #
              , ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
            );
--
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            END IF;
--
          END IF;
--
          -- エラー件数
          gn_error_cnt := gn_error_cnt + 1;
--
        END IF;
--
      END IF;
--
    END LOOP gt_slip_num_tab_loop;
--
  EXCEPTION
    -- 取得件数0件
    WHEN no_data_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application_short_name
                      , iv_name         => cv_no_data_msg
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
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2       --   リターン・コード    --# 固定 #
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
    --エラー出力
    IF ( lv_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
    -- 終了ステータス「エラー」の場合、対象件数・正常件数の初期化とエラー件数のセット
    IF ( lv_retcode = cv_status_error ) THEN
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
--
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
--    --スキップ件数出力
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_appl_short_name
--                    , iv_name         => cv_skip_rec_msg
--                    , iv_token_name1  => cv_cnt_token
--                    , iv_token_value1 => TO_CHAR(gn_warn_cnt)
--                   );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => gv_out_msg
--    );
--
    -- 空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
    -- 終了ステータスが「エラー」以外且つ、エラー件数が1件以上ある場合、終了ステータス「警告」にする
    IF ( ( lv_retcode <> cv_status_error ) AND ( gn_error_cnt > 0 ) ) THEN
      lv_retcode := cv_status_warn;
    END IF;
--
    --終了メッセージ
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
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
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
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
END XXCOI001A07C;
/
