CREATE OR REPLACE PACKAGE BODY XXCOI002A01R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI002A01R(body)
 * Description      : 倉替伝票
 * MD.050           : 倉替伝票 MD050_COI_002_A01
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理 (A-1)
 *  get_base_code          出力拠点取得処理 (A-2)
 *  get_transaction_data   資材取引データ抽出処理 (A-3)
 *  ins_rep_table_data     倉替伝票帳票ワークテーブルデータ登録処理 (A-4)
 *  start_svf              SVF起動処理 (A-5)
 *  del_rep_table_data     倉替伝票帳票ワークテーブルデータ削除処理 (A-6)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/12    1.0   K.Nakamura       新規作成
 *  2009/05/13    1.1   H.Sasaki         [T1_0774]伝票番号の桁数を修正
 *  2009/07/30    1.2   N.Abe            [0000638]数量の取得項目修正
 *  2009/12/14    1.3   N.Abe            [E_本稼動_00385]倉替抽出方法修正
 *  2009/12/25    1.4   N.Abe            [E_本稼動_00610]パフォーマンス対応
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
-- == 2009/12/25 V1.4 Deleted START ===============================================================
--  lock_expt                      EXCEPTION; -- ロック取得エラー
-- == 2009/12/25 V1.4 Deleted END   ===============================================================
  no_data_expt                   EXCEPTION; -- 取得件数0件例外
--
-- == 2009/12/25 V1.4 Deleted START ===============================================================
--  PRAGMA EXCEPTION_INIT( lock_expt, -54 );  -- ロック取得例外
-- == 2009/12/25 V1.4 Deleted END   ===============================================================
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                    CONSTANT VARCHAR2(15)  := 'XXCOI002A01R'; -- パッケージ名
  cv_application_short_name      CONSTANT VARCHAR2(15)  := 'XXCOI';        -- アプリケーション短縮名
  -- 参照タイプ
  cv_voucher_inout_div           CONSTANT VARCHAR2(30)  := 'XXCOI1_VOUCHER_IN_OUT_DIV'; -- 倉替伝票入出庫区分
  -- メッセージ
  cv_para_inout_type_msg         CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10163';  -- パラメータ 入出庫区分値メッセージ
  cv_para_date_from_msg          CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10164';  -- パラメータ 日付（From）値メッセージ
  cv_para_date_to_msg            CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10165';  -- パラメータ 日付（To）値メッセージ
  cv_para_base_code_from_msg     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10166';  -- パラメータ 出庫元拠点値メッセージ
  cv_para_base_code_to_msg       CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10167';  -- パラメータ 入庫先拠点値メッセージ
  cv_org_code_get_err_msg        CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00005';  -- 在庫組織コード取得エラーメッセージ
  cv_org_id_get_err_msg          CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00006';  -- 在庫組織ID取得エラーメッセージ
  cv_inout_type_get_err_msg      CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10171';  -- 入出庫区分内容取得エラーメッセージ
  cv_dept_code_get_err           CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10254';  -- 所属拠点コード取得エラーメッセージ
  cv_date_over_err_msg           CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10047';  -- 日付入力エラー（未来日）メッセージ
  cv_date_reverse_err_msg        CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10048';  -- 日付入力エラー（日付逆転）エラーメッセージ
  cv_tran_type_name_get_err_msg  CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00022';  -- 取引タイプ名取得エラーメッセージ
  cv_tran_type_id_get_err_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10300';  -- 取引タイプID取得エラーメッセージ
  cv_api_err_msg                 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00010';  -- APIエラーメッセージ
  cv_table_lock_err_msg          CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10049';  -- ロック取得エラーメッセージ(倉替伝票帳票ワークテーブル)
-- == 2009/05/13 V1.1 Added START ===============================================================
  cv_msg_code_xxcoi_10381        CONSTANT VARCHAR2(30)  := 'APP-XXCOI1-10381';  -- 伝票№マスク取得エラーメッセージ
-- == 2009/05/13 V1.1 Added END   ===============================================================
  -- トークン
  cv_tkn_para_inout_type         CONSTANT VARCHAR2(20)  := 'P_INOUT_TYPE';         -- パラメータ 入出庫区分
  cv_tkn_para_date_from          CONSTANT VARCHAR2(20)  := 'P_DATE_FROM';          -- パラメータ 日付（From）
  cv_tkn_para_date_to            CONSTANT VARCHAR2(20)  := 'P_DATE_TO';            -- パラメータ 日付（To）
  cv_tkn_para_base_code_from     CONSTANT VARCHAR2(20)  := 'P_BASE_CODE_FROM';     -- パラメータ 出庫元拠点コード
  cv_tkn_para_base_code_to       CONSTANT VARCHAR2(20)  := 'P_BASE_CODE_TO';       -- パラメータ 入庫先拠点コード
  cv_tkn_pro                     CONSTANT VARCHAR2(20)  := 'PRO_TOK';              -- プロファイル名
  cv_tkn_org_code                CONSTANT VARCHAR2(20)  := 'ORG_CODE_TOK';         -- 在庫組織コード
  cv_tkn_lookup_type             CONSTANT VARCHAR2(20)  := 'LOOKUP_TYPE';          -- 参照タイプ
  cv_tkn_lookup_code             CONSTANT VARCHAR2(20)  := 'LOOKUP_CODE';          -- 参照コード
  cv_tkn_api_name                CONSTANT VARCHAR2(20)  := 'API_NAME';             -- API名
  cv_tkn_tran_type               CONSTANT VARCHAR2(20)  := 'TRANSACTION_TYPE_TOK'; -- 取引タイプ
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 出力拠点情報格納用レコード格納用
  TYPE gr_kyoten_rec IS RECORD(
      base_code                  hz_cust_accounts.account_number%TYPE
  );
--
  TYPE gt_kyoten_ttype IS TABLE OF gr_kyoten_rec INDEX BY BINARY_INTEGER;
--
  -- 資材取引情報格納用レコード格納用
  TYPE gr_mmt_info_rec IS RECORD(
      transaction_date           mtl_material_transactions.transaction_date%TYPE     -- 伝票日付
    , transaction_set_id         VARCHAR2(15)                                        -- 伝票No
-- == 2009/07/30 V1.2 Modified START ===============================================================
--    , transaction_quantity       mtl_material_transactions.transaction_quantity%TYPE -- 取引数量
    , transaction_quantity       mtl_material_transactions.primary_quantity%TYPE     -- 基準単位数量
-- == 2009/07/30 V1.2 Modified END   ===============================================================
    , kyoten_from_code           hz_cust_accounts.account_number%TYPE                -- 出庫元拠点コード
    , kyoten_to_code             VARCHAR2(240)                                       -- 入庫先拠点コード
    , kyoten_from_name           hz_cust_accounts.account_name%TYPE                  -- 出庫元拠点名称
    , kyoten_to_name             VARCHAR2(240)                                       -- 入庫先拠点名称
    , item_code                  mtl_system_items_b.segment1%TYPE                    -- 商品コード
    , item_name                  xxcmn_item_mst_b.item_short_name%TYPE               -- 商品名
    , title                      fnd_lookup_values.description%TYPE                  -- タイトル
  );
--
  TYPE gt_mmt_info_ttype IS TABLE OF gr_mmt_info_rec INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 起動パラメータ
  gv_para_org_code               VARCHAR2(100); -- 在庫組織
  gv_para_inout_div              VARCHAR2(100); -- 入出庫区分
  gv_para_date_from              VARCHAR2(100); -- 日付（From）
  gv_para_date_to                VARCHAR2(100); -- 日付（To）
  gv_para_kyoten_from            VARCHAR2(100); -- 出庫元拠点
  gv_para_kyoten_to              VARCHAR2(100); -- 入庫先拠点
  --
  gv_date                        VARCHAR2(100); -- SYSDATE(文字列)
  -- 書式変換後
  gd_para_date_from2             DATE; -- 日付（From）
  gd_para_date_to2               DATE; -- 日付（To）
  --
  gt_org_id                      mtl_parameters.organization_id%TYPE;            -- 在庫組織ID
  gt_tran_type_factory_change    mtl_transaction_types.transaction_type_id%TYPE; -- 取引タイプID 工場倉替
  gt_tran_type_factory_change_b  mtl_transaction_types.transaction_type_id%TYPE; -- 取引タイプID 工場倉替振戻
  gt_tran_type_factory_return    mtl_transaction_types.transaction_type_id%TYPE; -- 取引タイプID 工場返品
  gt_tran_type_factory_return_b  mtl_transaction_types.transaction_type_id%TYPE; -- 取引タイプID 工場返品振戻
  gt_tran_type_kuragae           mtl_transaction_types.transaction_type_id%TYPE; -- 取引タイプID 倉替
  gv_login_kyoten                VARCHAR2(100);                                  -- ログインユーザーの拠点コード
  -- カウンタ
  gn_kyoten_loop_cnt             NUMBER; -- 拠点コードループカウンタ
  gn_mmt_info_loop_cnt           NUMBER; -- 資材取引情報ループカウンタ
  gn_kyoten_cnt                  NUMBER; -- 拠点コード件数
  gn_mmt_info_cnt                NUMBER; -- 資材取引情報件数
  -- PL/SQL表
  gt_kyoten_tab                  gt_kyoten_ttype;
  gt_mmt_info_tab                gt_mmt_info_ttype;
-- == 2009/05/13 V1.1 Added START ===============================================================
  gn_slip_number_mask            NUMBER;        -- 伝票№マスク(990000000000)
-- == 2009/05/13 V1.1 Added END   ===============================================================
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf       OUT VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- プロファイル 在庫組織コード
    cv_prf_org_code                CONSTANT VARCHAR2(30) := 'XXCOI1_ORGANIZATION_CODE';
-- == 2009/05/13 V1.1 Added START ===============================================================
    cv_prf_slip_number_mask        CONSTANT VARCHAR2(30) := 'XXCOI1_SLIP_NUMBER_MASK';
-- == 2009/05/13 V1.1 Added END   ===============================================================
    -- 参照タイプ ユーザー定義取引タイプ名称
    cv_tran_type                   CONSTANT VARCHAR2(30) := 'XXCOI1_TRANSACTION_TYPE_NAME';
    -- 参照コード
    cv_tran_type_factory_change    CONSTANT VARCHAR2(3)  := '110'; -- 取引タイプ コード 工場倉替
    cv_tran_type_factory_change_b  CONSTANT VARCHAR2(3)  := '120'; -- 取引タイプ コード 工場倉替振戻
    cv_tran_type_factory_return    CONSTANT VARCHAR2(3)  := '90';  -- 取引タイプ コード 工場返品
    cv_tran_type_factory_return_b  CONSTANT VARCHAR2(3)  := '100'; -- 取引タイプ コード 工場返品振戻
    cv_tran_type_kuragae           CONSTANT VARCHAR2(3)  := '20';  -- 取引タイプ コード 倉替
--
    -- *** ローカル変数 ***
    lt_org_code                    mtl_parameters.organization_code%TYPE;            -- 在庫組織コード
    lt_tran_type_factory_change    mtl_transaction_types.transaction_type_name%TYPE; -- 取引タイプ名 工場倉替
    lt_tran_type_factory_change_b  mtl_transaction_types.transaction_type_name%TYPE; -- 取引タイプ名 工場倉替振戻
    lt_tran_type_factory_return    mtl_transaction_types.transaction_type_name%TYPE; -- 取引タイプ名 工場返品
    lt_tran_type_factory_return_b  mtl_transaction_types.transaction_type_name%TYPE; -- 取引タイプ名 工場返品振戻
    lt_tran_type_kuragae           mtl_transaction_types.transaction_type_name%TYPE; -- 取引タイプ名 倉替
    lv_voucher_inout_div           VARCHAR(10); -- 入出庫区分内容 全部 工場倉替 工場返品 拠点間倉替
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
    -- ===============================
    -- プロファイル取得：在庫組織コード
    -- ===============================
    lt_org_code := fnd_profile.value( cv_prf_org_code );
    -- 共通関数の戻り値がNULLの場合、またはパラメータ.在庫組織コードと相違する場合
    IF ( lt_org_code IS NULL ) OR ( lt_org_code <> gv_para_org_code )THEN
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
    -- 取引タイプ名取得（工場倉替）
    -- ===============================
    lt_tran_type_factory_change := xxcoi_common_pkg.get_meaning( cv_tran_type, cv_tran_type_factory_change );
    -- 共通関数の戻り値がNULLの場合
    IF ( lt_tran_type_factory_change IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_name_get_err_msg
                     , iv_token_name1  => cv_tkn_lookup_type
                     , iv_token_value1 => cv_tran_type
                     , iv_token_name2  => cv_tkn_lookup_code
                     , iv_token_value2 => cv_tran_type_factory_change
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 取引タイプID取得（工場倉替）
    -- ===============================
    gt_tran_type_factory_change := xxcoi_common_pkg.get_transaction_type_id( lt_tran_type_factory_change );
    -- 共通関数の戻り値がNULLの場合
    IF ( gt_tran_type_factory_change IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_id_get_err_msg
                     , iv_token_name1  => cv_tkn_tran_type
                     , iv_token_value1 => lt_tran_type_factory_change
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 取引タイプ名取得（工場倉替振戻）
    -- ===============================
    lt_tran_type_factory_change_b := xxcoi_common_pkg.get_meaning( cv_tran_type, cv_tran_type_factory_change_b );
    -- 共通関数の戻り値がNULLの場合
    IF ( lt_tran_type_factory_change_b IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_name_get_err_msg
                     , iv_token_name1  => cv_tkn_lookup_type
                     , iv_token_value1 => cv_tran_type
                     , iv_token_name2  => cv_tkn_lookup_code
                     , iv_token_value2 => cv_tran_type_factory_change_b
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 取引タイプID取得（工場倉替振戻）
    -- ===============================
    gt_tran_type_factory_change_b := xxcoi_common_pkg.get_transaction_type_id( lt_tran_type_factory_change_b );
    -- 共通関数の戻り値がNULLの場合
    IF ( gt_tran_type_factory_change_b IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_id_get_err_msg
                     , iv_token_name1  => cv_tkn_tran_type
                     , iv_token_value1 => lt_tran_type_factory_change_b
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 取引タイプ名取得（工場返品）
    -- ===============================
    lt_tran_type_factory_return := xxcoi_common_pkg.get_meaning( cv_tran_type, cv_tran_type_factory_return );
    -- 共通関数の戻り値がNULLの場合
    IF ( lt_tran_type_factory_return IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_name_get_err_msg
                     , iv_token_name1  => cv_tkn_lookup_type
                     , iv_token_value1 => cv_tran_type
                     , iv_token_name2  => cv_tkn_lookup_code
                     , iv_token_value2 => cv_tran_type_factory_return
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 取引タイプID取得（工場返品）
    -- ===============================
    gt_tran_type_factory_return := xxcoi_common_pkg.get_transaction_type_id( lt_tran_type_factory_return );
    -- 共通関数の戻り値がNULLの場合
    IF ( gt_tran_type_factory_return IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_id_get_err_msg
                     , iv_token_name1  => cv_tkn_tran_type
                     , iv_token_value1 => lt_tran_type_factory_return
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 取引タイプ名取得（工場倉返品振戻）
    -- ===============================
    lt_tran_type_factory_return_b := xxcoi_common_pkg.get_meaning( cv_tran_type, cv_tran_type_factory_return_b );
    -- 共通関数の戻り値がNULLの場合
    IF ( lt_tran_type_factory_return_b IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_name_get_err_msg
                     , iv_token_name1  => cv_tkn_lookup_type
                     , iv_token_value1 => cv_tran_type
                     , iv_token_name2  => cv_tkn_lookup_code
                     , iv_token_value2 => cv_tran_type_factory_return_b
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 取引タイプID取得（工場倉返品振戻）
    -- ===============================
    gt_tran_type_factory_return_b := xxcoi_common_pkg.get_transaction_type_id( lt_tran_type_factory_return_b );
    -- 共通関数の戻り値がNULLの場合
    IF ( gt_tran_type_factory_return_b IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_tran_type_id_get_err_msg
                     , iv_token_name1  => cv_tkn_tran_type
                     , iv_token_value1 => lt_tran_type_factory_return_b
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
    -- パラメータ.入出庫区分内容取得
    -- ===============================
    lv_voucher_inout_div := xxcoi_common_pkg.get_meaning( cv_voucher_inout_div, gv_para_inout_div );
    -- 共通関数の戻り値がNULLの場合
    IF ( lv_voucher_inout_div IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_inout_type_get_err_msg
                     , iv_token_name1  => cv_tkn_lookup_type
                     , iv_token_value1 => cv_voucher_inout_div
                     , iv_token_name2  => cv_tkn_lookup_code
                     , iv_token_value2 => gv_para_inout_div
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- パラメータ.出庫元拠点がNULLの場合
    IF ( gv_para_kyoten_from IS NULL ) THEN
      -- ===============================
      -- ログインユーザの所属拠点を取得
      -- ===============================
      xxcoi_common_pkg.get_belonging_base(
          in_user_id     => cn_created_by    -- ユーザーID
        , id_target_date => cd_creation_date -- 対象日
        , ov_base_code   => gv_login_kyoten  -- 拠点コード
        , ov_errbuf      => lv_errbuf        -- エラー・メッセージ
        , ov_retcode     => lv_retcode       -- リターン・コード
        , ov_errmsg      => lv_errmsg        -- ユーザー・エラー・メッセージ
      );
      -- リターン・コードが正常以外の場合
      IF ( lv_retcode <> cv_status_normal ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_dept_code_get_err
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- ===============================
    -- SYSDATE取得(文字列)
    -- ===============================
    gv_date := TO_CHAR( cd_creation_date, 'YYYY/MM/DD' );
--
    -- パラメータ.日付（To）がNULLの場合
    IF ( gv_para_date_to IS NULL ) THEN
      -- ===============================
      -- パラメータ内容取得：日付（To）
      -- ===============================
      gv_para_date_to := gv_date;
    END IF;
--
    -- ===============================
    -- パラメータ内容チェック：未来日
    -- ===============================
    -- パラメータ.日付（From）／（To）がシステム日付より大きい場合
    IF ( gv_para_date_from > gv_date ) OR ( gv_para_date_to > gv_date ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_date_over_err_msg
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- パラメータ内容チェック：日付逆転
    -- ===============================
    -- パラメータ.日付（From）／（To）が逆転している場合
    IF ( gv_para_date_from > gv_para_date_to ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_date_reverse_err_msg
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 日付書式(YYYYMMDD)変換
    -- ===============================
    gd_para_date_from2 := TO_DATE( TO_CHAR( TO_DATE( gv_para_date_from , 'YYYY/MM/DD' ), 'YYYYMMDD'), 'YYYYMMDD' );
    gd_para_date_to2   := TO_DATE( TO_CHAR( TO_DATE( gv_para_date_to , 'YYYY/MM/DD' ), 'YYYYMMDD'), 'YYYYMMDD' );
--
    --==============================================================
    --コンカレントパラメータログ出力
    --==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application_short_name
                    , iv_name         => cv_para_inout_type_msg
                    , iv_token_name1  => cv_tkn_para_inout_type
                    , iv_token_value1 => gv_para_inout_div
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => gv_out_msg
    );
--
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application_short_name
                    , iv_name         => cv_para_date_from_msg
                    , iv_token_name1  => cv_tkn_para_date_from
                    , iv_token_value1 => gv_para_date_from
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => gv_out_msg
    );
--
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application_short_name
                    , iv_name         => cv_para_date_to_msg
                    , iv_token_name1  => cv_tkn_para_date_to
                    , iv_token_value1 => gv_para_date_to
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => gv_out_msg
    );
--
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application_short_name
                    , iv_name         => cv_para_base_code_from_msg
                    , iv_token_name1  => cv_tkn_para_base_code_from
                    , iv_token_value1 => gv_para_kyoten_from
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => gv_out_msg
    );
--
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application_short_name
                    , iv_name         => cv_para_base_code_to_msg
                    , iv_token_name1  => cv_tkn_para_base_code_to
                    , iv_token_value1 => gv_para_kyoten_to
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => gv_out_msg
    );
    -- 空行出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => ''
    );
--
-- == 2009/05/13 V1.1 Added START ===============================================================
    -- ===============================
    -- 伝票№マスク取得
    -- ===============================
    gn_slip_number_mask  :=  TO_NUMBER(fnd_profile.value( cv_prf_slip_number_mask ));
    -- 共通関数の戻り値がNULLの場合、またはパラメータ.在庫組織コードと相違する場合
    IF (gn_slip_number_mask IS NULL) THEN
      -- 伝票№マスク取得エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_msg_code_xxcoi_10381
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_slip_number_mask
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
-- == 2009/05/13 V1.1 Added END   ===============================================================
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
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
   * Procedure Name   : get_base_code
   * Description      : 出力拠点取得処理 (A-2)
   ***********************************************************************************/
  PROCEDURE get_base_code(
    ov_errbuf       OUT VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_base_code'; -- プログラム名
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
    -- 出力拠点情報取得
    CURSOR info_kyoten_cur
    IS
      SELECT xbiv.base_code       AS base_code      -- 拠点コード
      FROM   xxcoi_base_info_v    xbiv              -- 拠点情報ビュー
      WHERE  xbiv.focus_base_code = gv_login_kyoten -- 絞込拠点コード = ログインユーザーの所属拠点コード
      ORDER BY xbiv.base_code
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
    OPEN info_kyoten_cur;
--
    -- レコード読込
    FETCH info_kyoten_cur BULK COLLECT INTO gt_kyoten_tab;
--
    -- 出力拠点情報カウントセット
    gn_kyoten_cnt := gt_kyoten_tab.COUNT;
--
    -- カーソルクローズ
    CLOSE info_kyoten_cur;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルがOPENしている場合
      IF ( info_kyoten_cur%ISOPEN ) THEN
        CLOSE info_kyoten_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルがOPENしている場合
      IF ( info_kyoten_cur%ISOPEN ) THEN
        CLOSE info_kyoten_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルがOPENしている場合
      IF ( info_kyoten_cur%ISOPEN ) THEN
        CLOSE info_kyoten_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_base_code;
--
  /**********************************************************************************
   * Procedure Name   : get_transaction_data
   * Description      : 資材取引データ抽出処理 (A-3)
   ***********************************************************************************/
  PROCEDURE get_transaction_data(
    gn_kyoten_loop_cnt IN NUMBER,     -- 拠点コードループカウンタ
    ov_errbuf          OUT VARCHAR2,  -- エラー・メッセージ                  --# 固定 #
    ov_retcode         OUT VARCHAR2,  -- リターン・コード                    --# 固定 #
    ov_errmsg          OUT VARCHAR2)  -- ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_transaction_data'; -- プログラム名
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
    cv_inout_div_all              CONSTANT VARCHAR2(1)  := '0';                   -- 入出庫区分 全部
    cv_inout_div_factory_change   CONSTANT VARCHAR2(1)  := '1';                   -- 入出庫区分 工場倉替
    cv_inout_div_factory_return   CONSTANT VARCHAR2(1)  := '2';                   -- 入出庫区分 工場返品
    cv_inout_div_kuragae          CONSTANT VARCHAR2(1)  := '3';                   -- 入出庫区分 拠点間倉替
    cv_customer_div               CONSTANT VARCHAR2(1)  := '1';                   -- 顧客区分 拠点
    cv_flag                       CONSTANT VARCHAR2(1)  := 'Y';                   -- 使用可能フラグ 'Y'
    cv_mfg_fctory_cd              CONSTANT VARCHAR2(30) := 'XXCOI_MFG_FCTORY_CD'; -- 工場返品倉替先コード
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
    -- 資材取引情報抽出
    CURSOR info_transaction_cur
    IS
      SELECT
             mmt.transaction_date                       AS transaction_date                 -- 伝票日付
           , mmt.attribute1                             AS transaction_set_id               -- 伝票No(拠点間倉替)
-- == 2009/07/30 V1.2 Modified START ===============================================================
--           , ( SUM( mmt.transaction_quantity ) * (-1) ) AS transaction_quantity             -- 取引数量
           , ( SUM( mmt.primary_quantity ) * (-1) )     AS transaction_quantity             -- 基準単位数量
-- == 2009/07/30 V1.2 Modified END   ===============================================================
           , hca1.account_number                        AS kyoten_from_code                 -- 出庫元拠点コード
           , hca2.account_number                        AS kyoten_to_code                   -- 入庫先拠点コード(拠点間倉替)
           , SUBSTRB( hca1.account_name, 1, 8 )         AS kyoten_from_name                 -- 出庫元拠点名称(略称)
           , SUBSTRB( hca2.account_name, 1, 8 )         AS kyoten_to_name                   -- 入庫先拠点名称(略称)
           , msib.segment1                              AS item_code                        -- 商品コード
           , xim.item_short_name                        AS item_name                        -- 商品名(略称)
           , flv.description                            AS title                            -- タイトル
      FROM 
             mtl_material_transactions mmt                                                  -- 資材取引
           , fnd_lookup_values         flv                                                  -- クイックコードマスタ
           , mtl_secondary_inventories msi1                                                 -- 保管場所マスタ1
           , mtl_secondary_inventories msi2                                                 -- 保管場所マスタ2
           , hz_cust_accounts          hca1                                                 -- 顧客マスタ1
           , hz_cust_accounts          hca2                                                 -- 顧客マスタ2
           , mtl_system_items_b        msib                                                 -- Disc品目マスタ
           , ic_item_mst_b             iim                                                  -- OPM品目マスタ
           , xxcmn_item_mst_b          xim                                                  -- OPM品目アドオン
      WHERE 
           ( gv_para_inout_div              IN ( cv_inout_div_all                           -- パラメータ.入出庫区分が'全部'
                                               , cv_inout_div_kuragae )                                      -- または'拠点間倉替'
      AND    mmt.transaction_type_id        = gt_tran_type_kuragae                          -- 取引タイプIDが'倉替'
      AND    flv.lookup_code                = cv_inout_div_kuragae                          -- 参照コードが'拠点間倉替'
      AND    flv.lookup_type                = cv_voucher_inout_div                          -- 参照タイプ
      AND    flv.enabled_flag               = cv_flag                                       -- 使用可能フラグ
      AND    TRUNC( cd_creation_date ) BETWEEN TRUNC( flv.start_date_active )               -- 適用開始日
      AND    TRUNC( NVL( flv.end_date_active, cd_creation_date ) )                          -- 終了日
      AND    flv.language                   = USERENV( 'LANG' ) )                           -- 言語
      AND    TRUNC( mmt.transaction_date ) >= gd_para_date_from2                            -- パラメータ.取引日(From)
      AND    TRUNC( mmt.transaction_date ) <= gd_para_date_to2                              -- パラメータ.取引日(To)
      AND    hca1.account_number            = gt_kyoten_tab( gn_kyoten_loop_cnt ).base_code -- パラメータ.出庫元拠点
      AND    hca1.account_number            = msi1.attribute7                               -- 顧客コード
      AND    hca1.customer_class_code       = cv_customer_div                               -- 顧客区分
      AND    mmt.subinventory_code          = msi1.secondary_inventory_name                 -- 保管場所コード
      AND    hca2.account_number            = NVL( gv_para_kyoten_to, hca2.account_number ) -- パラメータ.入庫先拠点
      AND    hca2.account_number            = msi2.attribute7                               -- 顧客コード
      AND    hca2.customer_class_code       = cv_customer_div                               -- 顧客区分
      AND    mmt.transfer_subinventory      = msi2.secondary_inventory_name                 -- 転送先保管場所コード
      AND    msib.organization_id           = gt_org_id                                     -- 在庫組織ID
      AND    msib.inventory_item_id         = mmt.inventory_item_id                         -- 品目ID
      AND    iim.item_no                    = msib.segment1                                 -- 品名コード
      AND    xim.item_id                    = iim.item_id                                   -- 品目ID
      AND    TRUNC( mmt.transaction_date ) BETWEEN TRUNC( xim.start_date_active )           -- 適用開始日
      AND    TRUNC( NVL( xim.end_date_active, mmt.transaction_date ) )                      -- 終了日
      AND    xim.active_flag                = cv_flag                                       -- 使用可能フラグ
-- == 2009/12/14 V1.3 Added START ===============================================================
      AND    mmt.primary_quantity           < 0                                             -- 数量マイナス(出庫)
-- == 2009/12/14 V1.3 Added END   ===============================================================
      GROUP BY
             mmt.transaction_date                                                           -- 伝票日付
           , mmt.attribute1                                                                 -- 伝票No(拠点間倉替)
           , hca1.account_number                                                            -- 出庫元拠点コード
           , hca2.account_number                                                            -- 入庫先拠点コード(拠点間倉替)
           , hca1.account_name                                                              -- 出庫元拠点名称(略称)
           , hca2.account_name                                                              -- 入庫先拠点名称(略称)
           , msib.segment1                                                                  -- 商品コード
           , xim.item_short_name                                                            -- 商品名(略称)
           , flv.description                                                                -- タイトル
      UNION
      SELECT 
             mmt.transaction_date                       AS transaction_date                 -- 伝票日付
-- == 2009/05/13 V1.1 Modified START ===============================================================
--           , TO_CHAR( mmt.transaction_set_id )          AS transaction_set_id               -- 伝票No(工場倉替・工場返品)
           , TO_CHAR(gn_slip_number_mask + mmt.transaction_set_id)
                                                        AS transaction_set_id               -- 伝票No(工場倉替・工場返品)
-- == 2009/05/13 V1.1 Modified END   ===============================================================
-- == 2009/07/30 V1.2 Modified START ===============================================================
--           , ( SUM( mmt.transaction_quantity ) * (-1) ) AS transaction_quantity             -- 取引数量
           , ( SUM( mmt.primary_quantity ) * (-1) )     AS transaction_quantity             -- 基準単位数量
-- == 2009/07/30 V1.2 Modified END   ===============================================================
           , hca.account_number                         AS kyoten_from_code                 -- 出庫元拠点コード
           , mmt.attribute2                             AS kyoten_to_code                   -- 入庫先拠点コード(工場倉替・工場返品)
           , SUBSTRB( hca.account_name, 1, 8 )          AS kyoten_from_name                 -- 出庫元拠点名称(略称)
           , SUBSTRB( flv2.description, 1, 8 )          AS kyoten_to_name                   -- 入庫先拠点名称(略称)
           , msib.segment1                              AS item_code                        -- 商品コード
           , xim.item_short_name                        AS item_name                        -- 商品名(略称)
           , flv.description                            AS title                            -- タイトル
      FROM 
             mtl_material_transactions  mmt                                                 -- 資材取引
           , fnd_lookup_values          flv                                                 -- クイックコードマスタ
           , fnd_lookup_values          flv2                                                -- クイックコードマスタ
           , mtl_secondary_inventories  msi                                                 -- 保管場所マスタ
           , hz_cust_accounts           hca                                                 -- 顧客マスタ
           , mtl_system_items_b         msib                                                -- Disc品目マスタ
           , ic_item_mst_b              iim                                                 -- OPM品目マスタ
           , xxcmn_item_mst_b           xim                                                 -- OPM品目アドオン
      WHERE 
         (
           ( gv_para_inout_div              IN ( cv_inout_div_all                           -- パラメータ.入出庫区分が'全部'
                                               , cv_inout_div_factory_change )                               -- または'工場倉替'
      AND    mmt.transaction_type_id        IN ( gt_tran_type_factory_change                -- 取引タイプIDが'工場倉替'
                                               , gt_tran_type_factory_change_b )                    -- または'工場倉替振戻'
      AND    flv.lookup_code                = cv_inout_div_factory_change                   -- 参照コードが'工場倉替'
      AND    flv.lookup_type                = cv_voucher_inout_div                          -- 参照タイプ
      AND    flv.enabled_flag               = cv_flag                                       -- 使用可能フラグ
      AND    TRUNC( cd_creation_date ) BETWEEN TRUNC( flv.start_date_active )               -- 適用開始日
      AND    TRUNC( NVL( flv.end_date_active, cd_creation_date ) )                          -- 終了日
      AND    flv.language                   = USERENV( 'LANG' )                             -- 言語
           )
      OR   ( gv_para_inout_div              IN ( cv_inout_div_all                           -- パラメータ.入出庫区分が'全部'
                                               , cv_inout_div_factory_return )                               -- または'工場返品'
      AND    mmt.transaction_type_id        IN ( gt_tran_type_factory_return                -- 取引タイプIDが'工場返品'
                                               , gt_tran_type_factory_return_b )            -- 取引タイプIDが'工場返品振戻'
      AND    flv.lookup_code                = cv_inout_div_factory_return                   -- 参照コード
      AND    flv.lookup_type                = cv_voucher_inout_div                          -- 参照タイプ
      AND    flv.enabled_flag               = cv_flag                                       -- 使用可能フラグ
      AND    TRUNC( cd_creation_date ) BETWEEN TRUNC( flv.start_date_active )               -- 適用開始日
      AND    TRUNC( NVL( flv.end_date_active, cd_creation_date ) )                          -- 終了日
      AND    flv.language                   = USERENV( 'LANG' )                             -- 言語
           )
         )
      AND    TRUNC( mmt.transaction_date ) >= gd_para_date_from2                            -- パラメータ.取引日
      AND    TRUNC( mmt.transaction_date ) <= gd_para_date_to2                              -- パラメータ.取引日
      AND    hca.account_number             = gt_kyoten_tab( gn_kyoten_loop_cnt ).base_code -- パラメータ.出庫元拠点
      AND    hca.account_number             = msi.attribute7                                -- 顧客コード
      AND    hca.customer_class_code        = cv_customer_div                               -- 顧客区分
      AND    mmt.subinventory_code          = msi.secondary_inventory_name                  -- 保管場所コード
      AND    msib.organization_id           = gt_org_id                                     -- 在庫組織ID
      AND    msib.inventory_item_id         = mmt.inventory_item_id                         -- 品目ID
      AND    iim.item_no                    = msib.segment1                                 -- 品名コード
      AND    xim.item_id                    = iim.item_id                                   -- 品目ID
      AND    TRUNC( mmt.transaction_date ) BETWEEN TRUNC( xim.start_date_active )           -- 適用開始日
      AND    TRUNC( NVL( xim.end_date_active, mmt.transaction_date ) )                      -- 終了日
      AND    xim.active_flag                = cv_flag                                       -- 使用可能フラグ
      AND    flv2.lookup_type               = cv_mfg_fctory_cd                              -- 参照タイプ
      AND    flv2.lookup_code               = mmt.attribute2                                -- 参照コード
      AND    flv2.enabled_flag              = cv_flag                                       -- 使用可能フラグ
      AND    TRUNC( cd_creation_date ) BETWEEN TRUNC( flv2.start_date_active )              -- 適用開始日
      AND    TRUNC( NVL( flv2.end_date_active, cd_creation_date ) )                         -- 終了日
      AND    flv2.language                  = USERENV( 'LANG' )                             -- 言語
      GROUP BY
             mmt.transaction_date                                                           -- 伝票日付
           , mmt.transaction_set_id                                                         -- 伝票No(工場倉替・工場返品)
           , hca.account_number                                                             -- 出庫元拠点コード
           , mmt.attribute2                                                                 -- 入庫先拠点コード(工場倉替・工場返品)
           , hca.account_name                                                               -- 出庫元拠点名称(略称)
           , flv2.description                                                               -- 入庫先拠点名称(略称)
           , msib.segment1                                                                  -- 商品コード
           , xim.item_short_name                                                            -- 商品名(略称)
           , flv.description                                                                -- タイトル
      ORDER BY 
             title                                                                          -- タイトル
           , transaction_set_id                                                             -- 伝票No
           , transaction_date                                                               -- 取引日
           , kyoten_from_code                                                               -- 出庫元拠点コード
           , kyoten_to_code                                                                 -- 入庫先拠点コード
           , item_code                                                                      -- 商品コード
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
    -- カウンタ初期化
    gn_mmt_info_cnt := 0;
--
    -- カーソルオープン
    OPEN info_transaction_cur;
--
    -- レコード読込
    FETCH info_transaction_cur BULK COLLECT INTO gt_mmt_info_tab;
--
    -- 資材取引情報カウントセット
    gn_mmt_info_cnt := gt_mmt_info_tab.COUNT;
--
    -- カーソルクローズ
    CLOSE info_transaction_cur;
--
    -- 対象処理件数
    gn_target_cnt := gn_target_cnt + gn_mmt_info_cnt;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルがOPENしている場合
      IF ( info_transaction_cur%ISOPEN ) THEN
        CLOSE info_transaction_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルがOPENしている場合
      IF ( info_transaction_cur%ISOPEN ) THEN
        CLOSE info_transaction_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルがOPENしている場合
      IF ( info_transaction_cur%ISOPEN ) THEN
        CLOSE info_transaction_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_transaction_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_rep_table_data
   * Description      : 倉替伝票帳票ワークテーブルデータ登録処理 (A-4)
   ***********************************************************************************/
  PROCEDURE ins_rep_table_data(
    gn_mmt_info_loop_cnt IN NUMBER,     -- 資材取引情報ループカウンタ
    ov_errbuf            OUT VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode           OUT VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg            OUT VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_rep_table_data'; -- プログラム名
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
    -- 倉替伝票帳票ワークテーブルデータ登録処理
    INSERT INTO xxcoi_rep_kuragae_slip(
        kuragae_slip_id                                                         -- 倉替伝票ID
      , report_id                                                               -- 帳票ID
      , title                                                                   -- タイトル
      , transaction_date                                                        -- 取引日
      , slip_num                                                                -- 伝票No
      , item_code                                                               -- 商品コード
      , item_name                                                               -- 商品名
      , subinventory_code_from                                                  -- 出庫元保管場所コード
      , subinventory_name_from                                                  -- 出庫元保管場所名称
      , subinventory_code_to                                                    -- 入庫先保管場所コード
      , subinventory_name_to                                                    -- 入庫先保管場所名称
      , trn_qty                                                                 -- 数量
      , created_by                                                              -- 作成者
      , creation_date                                                           -- 作成日
      , last_updated_by                                                         -- 最終更新者
      , last_update_date                                                        -- 最終更新日
      , last_update_login                                                       -- 最終更新ユーザ
      , request_id                                                              -- 要求ID
      , program_application_id                                                  -- プログラムアプリケーションID
      , program_id                                                              -- プログラムID
      , program_update_date                                                     -- プログラム更新日
    )
    VALUES(
        xxcoi_rep_kuragae_slip_s01.NEXTVAL                                      -- 倉替伝票ID(シーケンス)
      , cv_pkg_name                                                             -- 帳票ID
      , gt_mmt_info_tab( gn_mmt_info_loop_cnt ).title                           -- タイトル
      , gt_mmt_info_tab( gn_mmt_info_loop_cnt ).transaction_date                -- 伝票日付
      , gt_mmt_info_tab( gn_mmt_info_loop_cnt ).transaction_set_id              -- 伝票No
      , gt_mmt_info_tab( gn_mmt_info_loop_cnt ).item_code                       -- 商品コード
      , gt_mmt_info_tab( gn_mmt_info_loop_cnt ).item_name                       -- 商品名
      , gt_mmt_info_tab( gn_mmt_info_loop_cnt ).kyoten_from_code                -- 出庫元拠点コード
      , gt_mmt_info_tab( gn_mmt_info_loop_cnt ).kyoten_from_name                -- 出庫元拠点名称
      , gt_mmt_info_tab( gn_mmt_info_loop_cnt ).kyoten_to_code                  -- 入庫先拠点コード
      , gt_mmt_info_tab( gn_mmt_info_loop_cnt ).kyoten_to_name                  -- 入庫先拠点名称
      , gt_mmt_info_tab( gn_mmt_info_loop_cnt ).transaction_quantity            -- 取引数量
      , cn_created_by                                                           -- 作成者
      , cd_creation_date                                                        -- 作成日
      , cn_last_updated_by                                                      -- 最終更新者
      , cd_last_update_date                                                     -- 最終更新日
      , cn_last_update_login                                                    -- 最終更新ユーザ
      , cn_request_id                                                           -- 要求ID
      , cn_program_application_id                                               -- プログラムアプリケーションID
      , cn_program_id                                                           -- プログラムID
      , cd_program_update_date                                                  -- プログラム更新日
     );
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
  END ins_rep_table_data;
--
  /**********************************************************************************
   * Procedure Name   : start_svf
   * Description      : SVF起動処理 (A-5)
   ***********************************************************************************/
  PROCEDURE start_svf(
    ov_errbuf     OUT VARCHAR2,  -- エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,  -- リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)  -- ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'start_svf'; -- プログラム名
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
    cv_frm_name   CONSTANT VARCHAR2(20) := 'XXCOI002A01S.xml';  -- フォーム様式ファイル名
    cv_vrq_name   CONSTANT VARCHAR2(20) := 'XXCOI002A01S.vrq';  -- クエリー様式ファイル名
    cv_out_div    CONSTANT VARCHAR2(20) := '1';   -- 出力区分
    cv_svf        CONSTANT VARCHAR2(20) := 'SVF'; -- メッセージ出力用
--
    -- *** ローカル変数 ***
    ld_date       VARCHAR2(8);   -- 日付
    lv_file_name  VARCHAR2(100); -- 出力ファイル名
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
    -- 日付書式変換
    ld_date := TO_CHAR( cd_creation_date, 'YYYYMMDD' );
--
    -- 出力ファイル名
    lv_file_name := cv_pkg_name || ld_date || cn_request_id;
--
    -- SVF共通関数起動
    xxccp_svfcommon_pkg.submit_svf_request(
        ov_retcode      => lv_retcode           -- リターンコード
      , ov_errbuf       => lv_errbuf            -- エラーメッセージ
      , ov_errmsg       => lv_errmsg            -- ユーザー・エラーメッセージ
      , iv_conc_name    => cv_pkg_name          -- コンカレント名
      , iv_file_name    => lv_file_name         -- 出力ファイル名
      , iv_file_id      => cv_pkg_name          -- 帳票ID
      , iv_output_mode  => cv_out_div           -- 出力区分
      , iv_frm_file     => cv_frm_name          -- フォーム様式ファイル名
      , iv_vrq_file     => cv_vrq_name          -- クエリー様式ファイル名
      , iv_org_id       => fnd_global.org_id    -- ORG_ID
      , iv_user_name    => fnd_global.user_name -- ログイン・ユーザ名
      , iv_resp_name    => fnd_global.resp_name -- ログイン・ユーザの職責名
      , iv_doc_name     => NULL                 -- 文書名
      , iv_printer_name => NULL                 -- プリンタ名
      , iv_request_id   => cn_request_id        -- 要求ID
      , iv_nodata_msg   => NULL                 -- データなしメッセージ
    );
    -- 共通関数のリターンコードが正常以外の場合
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_api_err_msg
                     , iv_token_name1  => cv_tkn_api_name
                     , iv_token_value1 => cv_svf
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
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
  END start_svf;
--
  /**********************************************************************************
   * Procedure Name   : del_rep_table_data
   * Description      : 倉替伝票帳票ワークテーブルデータ削除処理 (A-6)
   ***********************************************************************************/
  PROCEDURE del_rep_table_data(
    ov_errbuf     OUT  VARCHAR2,  -- エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT  VARCHAR2,  -- リターン・コード                    --# 固定 #
    ov_errmsg     OUT  VARCHAR2)  -- ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_rep_table_data'; -- プログラム名
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
-- == 2009/12/25 V1.4 Deleted START ===============================================================
--    -- 資材取引ロック
--    CURSOR del_xrs_tbl_cur
--    IS
--      SELECT 'X'                    AS request_id  -- 要求ID
--      FROM   xxcoi_rep_kuragae_slip xrk            -- 倉替伝票帳票ワークテーブル
--      WHERE  xrk.request_id = cn_request_id        -- 要求ID
--      FOR UPDATE OF xrk.request_id NOWAIT
--    ;
----
--    -- *** ローカル・レコード ***
--    del_xrs_tbl_rec  del_xrs_tbl_cur%ROWTYPE;
-- == 2009/12/25 V1.4 Deleted END   ===============================================================
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
-- == 2009/12/25 V1.4 Deleted START ===============================================================
--    -- カーソルオープン
--    OPEN del_xrs_tbl_cur;
----
--    <<del_xrs_tbl_cur_loop>>
--    LOOP
--      -- レコード読込
--      FETCH del_xrs_tbl_cur INTO del_xrs_tbl_rec;
--      EXIT WHEN del_xrs_tbl_cur%NOTFOUND;
-- == 2009/12/25 V1.4 Deleted END   ===============================================================
--
      -- 倉替伝票帳票ワークテーブルの削除
      DELETE
      FROM   xxcoi_rep_kuragae_slip xrk     -- 倉替伝票帳票ワークテーブル
      WHERE  xrk.request_id = cn_request_id -- 要求ID
      ;
--
-- == 2009/12/25 V1.4 Deleted START ===============================================================
--    END LOOP del_xrs_tbl_cur_loop;
----
--    -- カーソルクローズ
--    CLOSE del_xrs_tbl_cur;
-- == 2009/12/25 V1.4 Deleted END   ===============================================================
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
-- == 2009/12/25 V1.4 Deleted START ===============================================================
--    -- ロック取得エラー
--    WHEN lock_expt THEN
--      -- カーソルがOPENしている場合
--      IF ( del_xrs_tbl_cur%ISOPEN ) THEN
--        CLOSE del_xrs_tbl_cur;
--      END IF;
--      lv_errmsg  := xxccp_common_pkg.get_msg(
--                        iv_application  => cv_application_short_name
--                      , iv_name         => cv_table_lock_err_msg
--                    );
--      lv_errbuf  := lv_errmsg;
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
--      ov_retcode := cv_status_error;
-- == 2009/12/25 V1.4 Deleted END   ===============================================================
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
-- == 2009/12/25 V1.4 Deleted START ===============================================================
--      -- カーソルがOPENしている場合
--      IF ( del_xrs_tbl_cur%ISOPEN ) THEN
--        CLOSE del_xrs_tbl_cur;
--      END IF;
-- == 2009/12/25 V1.4 Deleted END   ===============================================================
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
-- == 2009/12/25 V1.4 Deleted START ===============================================================
--      -- カーソルがOPENしている場合
--      IF ( del_xrs_tbl_cur%ISOPEN ) THEN
--        CLOSE del_xrs_tbl_cur;
--      END IF;
-- == 2009/12/25 V1.4 Deleted END   ===============================================================
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
-- == 2009/12/25 V1.4 Deleted START ===============================================================
--      -- カーソルがOPENしている場合
--      IF ( del_xrs_tbl_cur%ISOPEN ) THEN
--        CLOSE del_xrs_tbl_cur;
--      END IF;
-- == 2009/12/25 V1.4 Deleted END   ===============================================================
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END del_rep_table_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_org_code     IN  VARCHAR2,  --  1.在庫組織
    iv_inout_div    IN  VARCHAR2,  --  2.入出庫区分
    iv_date_from    IN  VARCHAR2,  --  3.日付（From）
    iv_date_to      IN  VARCHAR2,  --  4.日付（To）
    iv_kyoten_from  IN  VARCHAR2,  --  5.出庫元拠点
    iv_kyoten_to    IN  VARCHAR2,  --  6.入庫先拠点
    ov_errbuf       OUT VARCHAR2,  --  エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,  --  リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2)  --  ユーザー・エラー・メッセージ --# 固定 #
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
    gn_target_cnt       := 0;    -- 対象件数
    gn_normal_cnt       := 0;    -- 成功件数
    gn_error_cnt        := 0;    -- エラー件数
    gn_warn_cnt         := 0;    -- スキップ件数
    gv_para_org_code    := NULL; -- 入力パラメータ.在庫組織
    gv_para_inout_div   := NULL; -- 入力パラメータ.入出庫区分
    gv_para_date_from   := NULL; -- 入力パラメータ.日付（From）
    gv_para_date_to     := NULL; -- 入力パラメータ.日付（To）
    gv_para_kyoten_from := NULL; -- 入力パラメータ.出庫元拠点
    gv_para_kyoten_to   := NULL; -- 入力パラメータ.入庫先拠点
    gn_kyoten_cnt       := 0;    -- 拠点コードカウンタ
    gn_mmt_info_cnt     := 0;    -- 資材取引情報カウンタ
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- 入力パラメータをグローバル変数へセット
    gv_para_org_code    := iv_org_code;                   -- 在庫組織
    gv_para_inout_div   := iv_inout_div;                  -- 入出庫区分
    gv_para_date_from   := SUBSTRB( iv_date_from, 1, 10); -- 日付（From）
    gv_para_date_to     := SUBSTRB( iv_date_to, 1, 10);   -- 日付（To）
    gv_para_kyoten_from := iv_kyoten_from;                -- 出庫元拠点
    gv_para_kyoten_to   := iv_kyoten_to;                  -- 入庫先拠点
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
    -- パラメータ.出庫元拠点がNULLの場合
    IF ( gv_para_kyoten_from IS NULL ) THEN
      -- ===============================
      -- 出力拠点取得処理 (A-2)
      -- ===============================
      get_base_code(
          ov_errbuf  => lv_errbuf  -- エラー・メッセージ           --# 固定 #
        , ov_retcode => lv_retcode -- リターン・コード             --# 固定 #
        , ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
    ELSE
      -- 出力拠点情報セット
      gn_kyoten_cnt := 1;
    END IF;
--
    -- 出力拠点が1件以上ある場合
    IF ( gn_kyoten_cnt > 0 ) THEN
--
      -- 出力拠点単位ループ開始
      <<gn_kyoten_cnt_loop>>
      FOR gn_kyoten_loop_cnt IN 1 .. gn_kyoten_cnt LOOP
--
        -- 出力拠点情報セット
        IF ( gv_para_kyoten_from IS NOT NULL ) THEN
          gt_kyoten_tab( gn_kyoten_loop_cnt ).base_code := gv_para_kyoten_from;
        END IF;
--
        -- ===============================
        -- 資材取引データ抽出処理 (A-3)
        -- ===============================
        get_transaction_data(
            gn_kyoten_loop_cnt => gn_kyoten_loop_cnt -- 拠点コードループカウンタ
          , ov_errbuf          => lv_errbuf          -- エラー・メッセージ           --# 固定 #
          , ov_retcode         => lv_retcode         -- リターン・コード             --# 固定 #
          , ov_errmsg          => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
        );
--
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        -- 資材取引データが1件以上取得できた場合
        IF ( gn_mmt_info_cnt > 0 ) THEN
--
          -- 資材取引情報単位ループ開始
          <<gn_mmt_info_cnt_loop>>
          FOR gn_mmt_info_loop_cnt IN 1 .. gn_mmt_info_cnt LOOP
            -- ===============================
            -- 倉替伝票帳票ワークテーブルデータ登録処理 (A-4)
            -- ===============================
            ins_rep_table_data(
                gn_mmt_info_loop_cnt => gn_mmt_info_loop_cnt -- 資材取引情報ループカウンタ
              , ov_errbuf            => lv_errbuf            -- エラー・メッセージ           --# 固定 #
              , ov_retcode           => lv_retcode           -- リターン・コード             --# 固定 #
              , ov_errmsg            => lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
            );
--
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            END IF;
--
          END LOOP gn_mmt_info_cnt_loop;
--
        END IF;
--
      END LOOP gn_kyoten_cnt_loop;
--
    END IF;
--
    -- コミット
    COMMIT;
--
    -- ==============================================
    -- SVF起動処理 (A-5)
    -- ==============================================
    start_svf(
        ov_errbuf  => lv_errbuf  -- エラー・メッセージ           --# 固定 #
      , ov_retcode => lv_retcode -- リターン・コード             --# 固定 #
      , ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==============================================
    -- 倉替伝票帳票ワークテーブルデータ削除処理 (A-6)
    -- ==============================================
    del_rep_table_data(
        ov_errbuf  => lv_errbuf  -- エラー・メッセージ           --# 固定 #
      , ov_retcode => lv_retcode -- リターン・コード             --# 固定 #
      , ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
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
    errbuf          OUT VARCHAR2,      -- エラー・メッセージ  --# 固定 #
    retcode         OUT VARCHAR2,      -- リターン・コード    --# 固定 #
    iv_org_code     IN  VARCHAR2,      -- 1.在庫組織
    iv_inout_div    IN  VARCHAR2,      -- 2.入出庫区分
    iv_date_from    IN  VARCHAR2,      -- 3.日付（From）
    iv_date_to      IN  VARCHAR2,      -- 4.日付（To）
    iv_kyoten_from  IN  VARCHAR2,      -- 5.出庫元拠点
    iv_dummy        IN  VARCHAR2,      -- 入力制御用ダミー値
    iv_kyoten_to    IN  VARCHAR2       -- 6.入庫先拠点
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
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    --
    cv_log             CONSTANT VARCHAR2(10)  := 'LOG';              -- コンカレントヘッダメッセージログ出力
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
       iv_which   => cv_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
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
        iv_org_code    => iv_org_code     -- 1.在庫組織(非表示)
      , iv_inout_div   => iv_inout_div    -- 2.入出庫区分
      , iv_date_from   => iv_date_from    -- 3.日付（From）
      , iv_date_to     => iv_date_to      -- 4.日付（To）
      , iv_kyoten_from => iv_kyoten_from  -- 5.出庫元拠点
      , iv_kyoten_to   => iv_kyoten_to    -- 6.入庫先拠点
      , ov_errbuf      => lv_errbuf       -- エラー・メッセージ           --# 固定 #
      , ov_retcode     => lv_retcode      -- リターン・コード             --# 固定 #
      , ov_errmsg      => lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    -- 空行出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => ''
    );
--
    -- 終了ステータス「エラー」の場合、対象件数・正常件数・スキップ件数の初期化とエラー件数のセット
    IF ( lv_retcode = cv_status_error ) THEN
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_warn_cnt   := 0;
      gn_error_cnt  := 1;
    -- 終了ステータス「正常」の場合、対象件数を成功件数にセット
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      gn_normal_cnt := gn_target_cnt;
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
        which  => FND_FILE.LOG
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
        which  => FND_FILE.LOG
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
        which  => FND_FILE.LOG
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
        which  => FND_FILE.LOG
      , buff   => gv_out_msg
    );
--
    -- 空行出力
    FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
      ,  buff   => ''
    );
--
    -- 終了メッセージ
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
        which  => FND_FILE.LOG
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
END XXCOI002A01R;
/
