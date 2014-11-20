CREATE OR REPLACE PACKAGE BODY XXCOI002A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI002A02C(body)
 * Description      : 倉替／返品情報の抽出
 * MD.050           : 倉替／返品情報の抽出 MD050_COI_002_A02
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理 (A-1)
 *  get_slip_num           伝票No取得処理 (A-2)
 *  get_kuragae_henpin     倉替／返品情報抽出処理 (A-4)
 *  chk_base_code          入力拠点存在チェック処理 (A-5)
 *  ins_if_table           倉替返品インターフェース情報テーブルデータ登録処理 (A-6)
 *  upd_flag               工場倉替返品連携フラグ更新処理 (A-7)
 *  submain                メイン処理プロシージャ
 *                         セーブポイント作成処理 (A-3)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/10/30    1.0   K.Nakamura       新規作成
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
  lock_expt                    EXCEPTION; -- ロック取得エラー
  no_base_code_expt            EXCEPTION; -- 入力拠点存在エラー
  no_data_expt                 EXCEPTION; -- 取得件数0件例外
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);  -- ロック取得例外
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                  CONSTANT VARCHAR2(15)  := 'XXCOI002A02C'; -- パッケージ名
  cv_appl_short_name           CONSTANT VARCHAR2(10)  := 'XXCCP';        -- アドオン：共通・IF領域
  cv_application_short_name    CONSTANT VARCHAR2(10)  := 'XXCOI';        -- アプリケーション短縮名
--
  -- メッセージ
  cv_no_para_msg               CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008'; -- コンカレント入力パラメータなしメッセージ
  cv_org_code_get_err_msg      CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00005'; -- 在庫組織コード取得エラーメッセージ
  cv_org_id_get_err_msg        CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00006'; -- 在庫組織ID取得エラーメッセージ
  cv_no_data_msg               CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00008'; -- 対象データ無しメッセージ
  cv_lookup_code_get_err_msg   CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00022'; -- 取引タイプ名取得エラーメッセージ
  cv_tran_type_get_err_msg     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10256'; -- 取引タイプID取得エラーメッセージ
  cv_no_base_code_err_msg      CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10050'; -- 入力拠点存在チェックエラーメッセージ
  cv_table_lock_err_msg        CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10054'; -- ロック取得エラーメッセージ（資材取引テーブル）
--
  -- トークン
  cv_tkn_pro                   CONSTANT VARCHAR2(20)  := 'PRO_TOK';              -- プロファイル名
  cv_tkn_org_code              CONSTANT VARCHAR2(20)  := 'ORG_CODE_TOK';         -- 在庫組織コード
  cv_tkn_lookup_type           CONSTANT VARCHAR2(20)  := 'LOOKUP_TYPE';          -- 参照タイプ
  cv_tkn_lookup_code           CONSTANT VARCHAR2(20)  := 'LOOKUP_CODE';          -- 参照コード
  cv_tkn_tran_type             CONSTANT VARCHAR2(20)  := 'TRANSACTION_TYPE_TOK'; -- 取引タイプ
  cv_tkn_base_code             CONSTANT VARCHAR2(20)  := 'BASE_CODE1';           -- 入力拠点コード
  cv_tkn_den_no                CONSTANT VARCHAR2(20)  := 'DEN_NO';               -- 伝票No
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 伝票No情報レコード格納用
  TYPE gt_slip_num_ttype IS TABLE OF mtl_material_transactions.transaction_set_id%TYPE INDEX BY BINARY_INTEGER;
--
  -- 倉替返品情報レコード格納用
  TYPE gr_kuragae_henpin_rec IS RECORD(
      mmt_transaction_set_id            mtl_material_transactions.transaction_set_id%TYPE   -- 伝票No
    , mmt_transaction_date              mtl_material_transactions.transaction_date%TYPE     -- 取引日
    , mmt_attribute2                    mtl_material_transactions.attribute2%TYPE           -- 出荷倉庫コード
    , mmt_attribute3                    mtl_material_transactions.attribute3%TYPE           -- 子コード
    , mmt_transaction_quantity          mtl_material_transactions.transaction_quantity%TYPE -- 取引数量
    , mtt_attribute1                    mtl_transaction_types.attribute1%TYPE               -- 工場倉替返品種別
    , mtt_attribute2                    mtl_transaction_types.attribute2%TYPE               -- 生産物流伝票種類
    , msi_attribute7                    mtl_secondary_inventories.attribute7%TYPE           -- 入力拠点コード
    , msib_segment1                     mtl_system_items_b.segment1%TYPE                    -- 品目コード
    , iim_attribute                     VARCHAR2(240)                                       -- 群コード
    , mmt_rowid                         rowid                                               -- ROWID
  );
  TYPE gt_kuragae_henpin_ttype IS TABLE OF gr_kuragae_henpin_rec INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gt_org_id                             mtl_parameters.organization_id%TYPE;            -- 在庫組織ID
  gt_tran_type_factory_change           mtl_transaction_types.transaction_type_id%TYPE; -- 取引タイプID 工場倉替
  gt_tran_type_factory_change_b         mtl_transaction_types.transaction_type_id%TYPE; -- 取引タイプID 工場倉替振戻
  gt_tran_type_factory_return           mtl_transaction_types.transaction_type_id%TYPE; -- 取引タイプID 工場返品
  gt_tran_type_factory_return_b         mtl_transaction_types.transaction_type_id%TYPE; -- 取引タイプID 工場返品振戻
  -- カウンタ
  gn_slip_loop_cnt                      NUMBER; -- 伝票Noループカウンタ
  gn_kuragae_henpin_loop_cnt            NUMBER; -- 倉替返品情報ループカウンタ
  gn_kuragae_henpin_cnt                 NUMBER; -- 倉替返品情報件数
  gn_kuragae_henpin_all_cnt             NUMBER; -- 倉替返品情報総件数
  -- PL/SQL表
  gt_slip_num_tab                       gt_slip_num_ttype;
  gt_kuragae_henpin_tab                 gt_kuragae_henpin_ttype;
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
    -- プロファイル 在庫組織コード
    cv_prf_org_code                     CONSTANT VARCHAR2(30) := 'XXCOI1_ORGANIZATION_CODE';
    -- 参照タイプ ユーザー定義取引タイプ名称
    cv_tran_type                        CONSTANT VARCHAR2(30) := 'XXCOI1_TRANSACTION_TYPE_NAME';
    -- 参照コード
    cv_tran_type_factory_change         CONSTANT VARCHAR2(3)  := '110'; -- 取引タイプ コード 工場倉替
    cv_tran_type_factory_change_b       CONSTANT VARCHAR2(3)  := '120'; -- 取引タイプ コード 工場倉替振戻
    cv_tran_type_factory_return         CONSTANT VARCHAR2(3)  := '90';  -- 取引タイプ コード 工場返品
    cv_tran_type_factory_return_b       CONSTANT VARCHAR2(3)  := '100'; -- 取引タイプ コード 工場返品振戻
--
    -- *** ローカル変数 ***
    lt_org_code                         mtl_parameters.organization_code%TYPE;            -- 在庫組織コード
    lt_tran_type_factory_change         mtl_transaction_types.transaction_type_name%TYPE; -- 取引タイプ名 工場倉替
    lt_tran_type_factory_change_b       mtl_transaction_types.transaction_type_name%TYPE; -- 取引タイプ名 工場倉替振戻
    lt_tran_type_factory_return         mtl_transaction_types.transaction_type_name%TYPE; -- 取引タイプ名 工場返品
    lt_tran_type_factory_return_b       mtl_transaction_types.transaction_type_name%TYPE; -- 取引タイプ名 工場返品振戻
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
    -- 共通関数の戻り値がNULLの場合
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
    -- 取引タイプ名取得（工場倉替）
    -- ===============================
    lt_tran_type_factory_change := xxcoi_common_pkg.get_meaning( cv_tran_type, cv_tran_type_factory_change );
    -- 共通関数の戻り値がNULLの場合
    IF ( lt_tran_type_factory_change IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_lookup_code_get_err_msg
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
                     , iv_name         => cv_tran_type_get_err_msg
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
                     , iv_name         => cv_lookup_code_get_err_msg
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
                     , iv_name         => cv_tran_type_get_err_msg
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
                     , iv_name         => cv_lookup_code_get_err_msg
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
                     , iv_name         => cv_tran_type_get_err_msg
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
                     , iv_name         => cv_lookup_code_get_err_msg
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
                     , iv_name         => cv_tran_type_get_err_msg
                     , iv_token_name1  => cv_tkn_tran_type
                     , iv_token_value1 => lt_tran_type_factory_return_b
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
   * Procedure Name   : get_slip_num
   * Description      : 伝票No取得処理 (A-2)
   ***********************************************************************************/
  PROCEDURE get_slip_num(
    ov_errbuf     OUT  VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT  VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg     OUT  VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_slip_num'; -- プログラム名
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
    -- 伝票No取得
    CURSOR info_slip_cur
    IS
      SELECT DISTINCT mmt.transaction_set_id AS transaction_set_id        -- 取引セットID(伝票No)
      FROM   mtl_material_transactions       mmt                          -- 資材取引テーブル
      WHERE  mmt.transaction_type_id IN ( gt_tran_type_factory_change     -- 取引タイプID 工場倉替
                                        , gt_tran_type_factory_change_b   -- 取引タイプID 工場倉替
                                        , gt_tran_type_factory_return     -- 取引タイプID 工場返品
                                        , gt_tran_type_factory_return_b ) -- 取引タイプID 工場返品振戻
      AND    mmt.attribute4          IS NULL                              -- 工場倉替返品連携フラグ
      ORDER BY mmt.transaction_set_id
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
    OPEN info_slip_cur;
--
    -- レコード読み込み
    FETCH info_slip_cur BULK COLLECT INTO gt_slip_num_tab;
--
    -- 伝票No(対象件数)セット
    gn_target_cnt := gt_slip_num_tab.COUNT;
--
    -- カーソルクローズ
    CLOSE info_slip_cur;
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
      IF ( info_slip_cur%ISOPEN ) THEN
        CLOSE info_slip_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルがOPENしている場合
      IF ( info_slip_cur%ISOPEN ) THEN
        CLOSE info_slip_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルがOPENしている場合
      IF ( info_slip_cur%ISOPEN ) THEN
        CLOSE info_slip_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_slip_num;
--
  /**********************************************************************************
   * Procedure Name   : get_kuragae_henpin
   * Description      : 倉替／返品情報抽出処理 (A-4)
   ***********************************************************************************/
  PROCEDURE get_kuragae_henpin(
    gn_slip_loop_cnt IN   NUMBER,    -- 伝票Noループカウンタ
    ov_errbuf        OUT  VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT  VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg        OUT  VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_kuragae_henpin'; -- プログラム名
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
    -- 倉替返品情報抽出
    CURSOR info_kuragae_henpin_cur
    IS
      SELECT 
             mmt.transaction_set_id    AS mmt_transaction_set_id                        -- 取引セットID
           , mmt.transaction_date      AS mmt_transaction_date                          -- 取引日
           , mmt.attribute2            AS mmt_attribute2                                -- 出荷倉庫コード
           , mmt.attribute3            AS mmt_attribute3                                -- 子コード
           , mmt.transaction_quantity  AS mmt_transaction_quantity                      -- 取引数量
           , mtt.attribute1            AS mtt_attribute1                                -- 工場倉替返品種別
           , mtt.attribute2            AS mtt_attribute2                                -- 生産物流伝票種類
           , msi.attribute7            AS msi_attribute7                                -- 入力拠点コード
           , msib.segment1             AS msib_segment1                                 -- 品目コード
           , CASE WHEN NVL( iim.attribute3, TO_CHAR( mmt.transaction_date, 'YYYY/MM/DD' ) )
               <= TO_CHAR( mmt.transaction_date, 'YYYY/MM/DD' )                         -- 群コード適用開始日 <= 取引日
               THEN iim.attribute2                                                      -- 群コード(新)
               ELSE iim.attribute1                                                      -- 旧群コード
               END                     AS iim_attribute                                 -- 群コード
           , mmt.rowid                 AS mmt_rowid                                     -- ROWID
      FROM 
             mtl_material_transactions mmt                                              -- 資材取引テーブル
           , mtl_transaction_types     mtt                                              -- 取引タイプマスタ
           , mtl_secondary_inventories msi                                              -- 保管場所マスタ
           , mtl_system_items_b        msib                                             -- Disc品目マスタ
           , ic_item_mst_b             iim                                              -- OPM品目マスタ
      WHERE 
             mmt.transaction_set_id  = gt_slip_num_tab( gn_slip_loop_cnt )              -- 伝票No
      AND    mmt.attribute4          IS NULL                                            -- 工場倉替返品連携フラグ
      AND    mmt.transaction_type_id = mtt.transaction_type_id                          -- 取引タイプID
      AND    mmt.subinventory_code   = msi.secondary_inventory_name                     -- 保管場所コード
      AND    mmt.inventory_item_id   = msib.inventory_item_id                           -- 品目ID
      AND    msib.organization_id    = gt_org_id                                        -- 在庫組織ID
      AND    iim.item_no             = msib.segment1                                    -- 品名コード
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
    -- 倉替返品情報件数の初期化
    gn_kuragae_henpin_cnt := 0;
--
    -- カーソルオープン
    OPEN info_kuragae_henpin_cur;
--
    -- レコード読込
    FETCH info_kuragae_henpin_cur BULK COLLECT INTO gt_kuragae_henpin_tab;
--
    -- 倉替返品情報件数セット
    gn_kuragae_henpin_cnt := gt_kuragae_henpin_tab.COUNT;
--
    -- 倉替返品情報総件数セット
    gn_kuragae_henpin_all_cnt := gn_kuragae_henpin_all_cnt + gn_kuragae_henpin_cnt;
--
    -- カーソルクローズ
    CLOSE info_kuragae_henpin_cur;
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
      IF ( info_kuragae_henpin_cur%ISOPEN ) THEN
        CLOSE info_kuragae_henpin_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルがOPENしている場合
      IF ( info_kuragae_henpin_cur%ISOPEN ) THEN
        CLOSE info_kuragae_henpin_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルがOPENしている場合
      IF ( info_kuragae_henpin_cur%ISOPEN ) THEN
        CLOSE info_kuragae_henpin_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_kuragae_henpin;
--
  /**********************************************************************************
   * Procedure Name   : chk_base_code
   * Description      : 入力拠点存在チェック処理 (A-5)
   ***********************************************************************************/
  PROCEDURE chk_base_code(
    gn_kuragae_henpin_loop_cnt IN   NUMBER,    -- 倉替返品情報ループカウンタ
    ov_errbuf                  OUT  VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode                 OUT  VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg                  OUT  VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_base_code'; -- プログラム名
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
    cv_customer_class_code   CONSTANT VARCHAR2(1) := '1'; -- 顧客区分 拠点
--
    -- *** ローカル変数 ***
    ln_cust_cnt              NUMBER; -- 顧客コード件数
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
    -- 件数カウンタ初期化
    ln_cust_cnt  := 0;
--
    -- 入力拠点コードの存在チェック
    SELECT count(1)                                                                                     -- 件数
    INTO   ln_cust_cnt
    FROM   hz_cust_accounts hca                                                                         -- 顧客マスタ
    WHERE  hca.account_number      = gt_kuragae_henpin_tab( gn_kuragae_henpin_loop_cnt ).msi_attribute7 -- 顧客コード
    AND    hca.customer_class_code = cv_customer_class_code                                             -- 顧客区分
    AND    ROWNUM                  = 1;
--
    -- カウントが0である場合
    IF ( ln_cust_cnt = 0 ) THEN
      RAISE no_base_code_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- 拠点コード存在エラー
    WHEN no_base_code_expt THEN
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_no_base_code_err_msg
                       , iv_token_name1  => cv_tkn_base_code
                       , iv_token_value1 => gt_kuragae_henpin_tab( gn_kuragae_henpin_loop_cnt ).msi_attribute7
                       , iv_token_name2  => cv_tkn_den_no
                       , iv_token_value2 => TO_CHAR( gt_kuragae_henpin_tab( gn_kuragae_henpin_loop_cnt ).mmt_transaction_set_id )
                     );
      lv_errbuf   := lv_errmsg;
      ov_errmsg   := lv_errmsg;
      ov_errbuf   := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  := cv_status_warn;
      -- エラーメッセージ出力
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => ov_errmsg --エラーメッセージ
      );
      -- セーブポイントまでロールバック
      ROLLBACK TO SAVEPOINT kuragae_point;
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
  END chk_base_code;
--
  /**********************************************************************************
   * Procedure Name   : ins_if_table
   * Description      : 倉替返品インターフェース情報テーブルデータ登録処理 (A-6)
   ***********************************************************************************/
  PROCEDURE ins_if_table(
    gn_kuragae_henpin_loop_cnt IN   NUMBER,    -- 倉替返品情報ループカウンタ
    ov_errbuf                  OUT  VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode                 OUT  VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg                  OUT  VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_if_table'; -- プログラム名
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
    cv_rno               CONSTANT VARCHAR2(1) := '0';  -- RNo
    cv_continue          CONSTANT VARCHAR2(2) := '00'; -- 継続
    cv_invoice_class_2   CONSTANT VARCHAR2(1) := '1';  -- 伝区2
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
    -- データ登録処理
    INSERT INTO xxwsh_reserve_interface(
        reserve_interface_id                         -- 倉替返品インターフェースID
      , data_class                                   -- データ種別
      , r_no                                         -- RNo.
      , continue                                     -- 継続
      , recorded_year                                -- 計上年月
      , input_base_code                              -- 入力拠点コード
      , receive_base_code                            -- 相手拠点コード
      , invoice_class_1                              -- 伝区１
      , invoice_class_2                              -- 伝区２
      , recorded_date                                -- 計上日付（着日）
      , ship_to_code                                 -- 配送先コード
      , customer_code                                -- 顧客コード
      , invoice_no                                   -- 伝票No
      , item_code                                    -- 品目コードエントリ
      , parent_item_code                             -- 品目コード親
      , crowd_code                                   -- 群コード
      , case_amount_of_content                       -- ケース数
      , quantity_in_case                             -- 入数
      , quantity                                     -- 本数（バラ）
      , created_by                                   -- 作成者
      , creation_date                                -- 作成日
      , last_updated_by                              -- 最終更新者
      , last_update_date                             -- 最終更新日
      , last_update_login                            -- 最終更新ユーザ
      , request_id                                   -- 要求ID
      , program_application_id                       -- プログラムアプリケーションID
      , program_id                                   -- プログラムID
      , program_update_date                          -- プログラム更新日
    )
    VALUES(
        xxcoi_xxwsh_reserve_if_s01.NEXTVAL                                                            -- 倉替返品インターフェースID
      , gt_kuragae_henpin_tab( gn_kuragae_henpin_loop_cnt ).mtt_attribute1                            -- データ種別
      , cv_rno                                                                                        -- RNo.
      , cv_continue                                                                                   -- 継続
      , TO_CHAR( gt_kuragae_henpin_tab( gn_kuragae_henpin_loop_cnt ).mmt_transaction_date, 'YYYYMM' ) -- 計上年月
      , gt_kuragae_henpin_tab( gn_kuragae_henpin_loop_cnt ).msi_attribute7                            -- 入力拠点コード
      , gt_kuragae_henpin_tab( gn_kuragae_henpin_loop_cnt ).mmt_attribute2                            -- 相手拠点コード
      , gt_kuragae_henpin_tab( gn_kuragae_henpin_loop_cnt ).mtt_attribute2                            -- 伝区１
      , cv_invoice_class_2                                                                            -- 伝区２
      , gt_kuragae_henpin_tab( gn_kuragae_henpin_loop_cnt ).mmt_transaction_date                      -- 計上日付（着日）
      , NULL                                                                                          -- 配送先コード
      , NULL                                                                                          -- 顧客コード
      , TO_CHAR( gt_kuragae_henpin_tab( gn_kuragae_henpin_loop_cnt ).mmt_transaction_set_id )         -- 伝票No
      , gt_kuragae_henpin_tab( gn_kuragae_henpin_loop_cnt ).mmt_attribute3                            -- 品目コードエントリ
      , gt_kuragae_henpin_tab( gn_kuragae_henpin_loop_cnt ).msib_segment1                             -- 品目コード親
      , gt_kuragae_henpin_tab( gn_kuragae_henpin_loop_cnt ).iim_attribute                             -- 群コード
      , NULL                                                                                          -- ケース数
      , NULL                                                                                          -- 入数
      , ( gt_kuragae_henpin_tab( gn_kuragae_henpin_loop_cnt ).mmt_transaction_quantity * ( -1 ) )     -- 本数（バラ）
      , cn_created_by                                                                                 -- 作成者
      , cd_creation_date                                                                              -- 作成日
      , cn_last_updated_by                                                                            -- 最終更新者
      , cd_last_update_date                                                                           -- 最終更新日
      , cn_last_update_login                                                                          -- 最終更新ユーザ
      , cn_request_id                                                                                 -- 要求ID
      , cn_program_application_id                                                                     -- プログラムアプリケーションID
      , cn_program_id                                                                                 -- プログラムID
      , cd_program_update_date                                                                        -- プログラム更新日
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
  END ins_if_table;
--
  /**********************************************************************************
   * Procedure Name   : upd_flag
   * Description      : 工場倉替返品連携フラグ更新処理 (A-7)
   ***********************************************************************************/
  PROCEDURE upd_flag(
    gn_kuragae_henpin_loop_cnt IN   NUMBER,    -- 倉替返品情報ループカウンタ
    ov_errbuf                  OUT  VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode                 OUT  VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg                  OUT  VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_flag'; -- プログラム名
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
    cv_kuragae_flg   CONSTANT VARCHAR2(1) := '1';  -- 工場倉替返品連携フラグ
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
    -- 資材取引テーブルロック
    CURSOR upd_mmt_tbl_cur
    IS
      SELECT 'X'                       AS attribute4                                   -- 工場倉替返品連携フラグ
      FROM   mtl_material_transactions mmt                                             -- 資材取引テーブル
      WHERE  mmt.rowid = gt_kuragae_henpin_tab( gn_kuragae_henpin_loop_cnt ).mmt_rowid -- ROWID
      FOR UPDATE OF mmt.attribute4 NOWAIT
    ;
--
    -- *** ローカル・レコード ***
    upd_mmt_tbl_rec  upd_mmt_tbl_cur%ROWTYPE;
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
    OPEN upd_mmt_tbl_cur;
--
    -- レコード読込
    FETCH upd_mmt_tbl_cur INTO upd_mmt_tbl_rec;
--
    -- 工場倉替返品連携フラグの更新
    UPDATE mtl_material_transactions  mmt                                                             -- 資材取引テーブル
    SET    mmt.attribute4             = cv_kuragae_flg                                                -- 工場倉替返品連携フラグ
         , mmt.last_updated_by        = cn_last_updated_by                                            -- 最終更新者
         , mmt.last_update_date       = cd_last_update_date                                           -- 最終更新日
         , mmt.last_update_login      = cn_last_update_login                                          -- 最終更新ユーザ
         , mmt.request_id             = cn_request_id                                                 -- 要求ID
         , mmt.program_application_id = cn_program_application_id                                     -- プログラムアプリケーションID
         , mmt.program_id             = cn_program_id                                                 -- プログラムID
         , mmt.program_update_date    = cd_program_update_date                                        -- プログラム更新日
    WHERE  mmt.rowid                  = gt_kuragae_henpin_tab( gn_kuragae_henpin_loop_cnt ).mmt_rowid -- ROWID
    ;
--
    -- カーソルクローズ
    CLOSE upd_mmt_tbl_cur;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- ロック取得エラー
    WHEN lock_expt THEN
      -- カーソルがOPENしている場合
      IF ( upd_mmt_tbl_cur%ISOPEN ) THEN
        CLOSE upd_mmt_tbl_cur;
      END IF;
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_table_lock_err_msg
                       , iv_token_name1  => cv_tkn_den_no
                       , iv_token_value1 => TO_CHAR( gt_kuragae_henpin_tab( gn_kuragae_henpin_loop_cnt ).mmt_transaction_set_id )
                     );
      lv_errbuf   := lv_errmsg;
      ov_errmsg   := lv_errmsg;
      ov_errbuf   := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  := cv_status_warn;
      -- エラーメッセージ出力
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => ov_errmsg --エラーメッセージ
      );
      -- セーブポイントまでロールバック
      ROLLBACK TO SAVEPOINT kuragae_point;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルがOPENしている場合
      IF ( upd_mmt_tbl_cur%ISOPEN ) THEN
        CLOSE upd_mmt_tbl_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルがOPENしている場合
      IF ( upd_mmt_tbl_cur%ISOPEN ) THEN
        CLOSE upd_mmt_tbl_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルがOPENしている場合
      IF ( upd_mmt_tbl_cur%ISOPEN ) THEN
        CLOSE upd_mmt_tbl_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END upd_flag;
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- グローバル変数の初期化
    gn_target_cnt             := 0; -- 対象件数
    gn_normal_cnt             := 0; -- 成功件数
    gn_error_cnt              := 0; -- エラー件数
    gn_warn_cnt               := 0; -- スキップ件数
    gn_kuragae_henpin_all_cnt := 0; -- 倉替返品情報総件数
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
        lv_errbuf            -- エラー・メッセージ           --# 固定 #
      , lv_retcode           -- リターン・コード             --# 固定 #
      , lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 伝票No取得処理 (A-2)
    -- ===============================
    get_slip_num(
        lv_errbuf            -- エラー・メッセージ           --# 固定 #
      , lv_retcode           -- リターン・コード             --# 固定 #
      , lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- 伝票No単位ループ開始
    <<gt_slip_num_tab_loop>>
    FOR gn_slip_loop_cnt IN 1 .. gn_target_cnt LOOP
--
      -- ===============================
      -- セーブポイント作成処理 (A-3)
      -- ===============================
      SAVEPOINT kuragae_point;
--
      -- ===============================
      -- 倉替／返品情報抽出処理 (A-4)
      -- ===============================
      get_kuragae_henpin(
          gn_slip_loop_cnt     -- 伝票Noループカウンタ
        , lv_errbuf            -- エラー・メッセージ           --# 固定 #
        , lv_retcode           -- リターン・コード             --# 固定 #
        , lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- 倉替返品情報が1件以上取得出来た場合
      IF ( gn_kuragae_henpin_cnt > 0 ) THEN
--
        -- 倉替返品情報ループ開始
        <<gt_kuragae_henpin_tab_loop>>
        FOR gn_kuragae_henpin_loop_cnt IN 1 .. gn_kuragae_henpin_cnt LOOP
--
          -- ====================================
          -- 入力拠点存在チェック処理 (A-5)
          -- ====================================
          chk_base_code(
              gn_kuragae_henpin_loop_cnt -- 倉替返品情報ループカウンタ
            , lv_errbuf                  -- エラー・メッセージ           --# 固定 #
            , lv_retcode                 -- リターン・コード             --# 固定 #
            , lv_errmsg                  -- ユーザー・エラー・メッセージ --# 固定 #
          );
--
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          ELSIF ( lv_retcode = cv_status_warn ) THEN
            -- スキップ件数
            gn_warn_cnt := gn_warn_cnt + 1;
            -- 倉替返品情報ループを抜ける
            EXIT gt_kuragae_henpin_tab_loop;
          END IF;
--
          -- ========================================================
          -- 倉替返品インターフェース情報テーブルデータ登録処理 (A-6)
          -- ========================================================
          ins_if_table(
              gn_kuragae_henpin_loop_cnt -- 倉替返品情報ループカウンタ
            , lv_errbuf                  -- エラー・メッセージ           --# 固定 #
            , lv_retcode                 -- リターン・コード             --# 固定 #
            , lv_errmsg                  -- ユーザー・エラー・メッセージ --# 固定 #
          );
--
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ====================================
          -- 工場倉替返品連携フラグ更新処理 (A-7)
          -- ====================================
          upd_flag(
              gn_kuragae_henpin_loop_cnt -- 倉替返品情報ループカウンタ
            , lv_errbuf                  -- エラー・メッセージ           --# 固定 #
            , lv_retcode                 -- リターン・コード             --# 固定 #
            , lv_errmsg                  -- ユーザー・エラー・メッセージ --# 固定 #
          );
--
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          ELSIF ( lv_retcode = cv_status_warn ) THEN
            -- スキップ件数
            gn_warn_cnt := gn_warn_cnt + 1;
            -- 倉替返品情報ループを抜ける
            EXIT gt_kuragae_henpin_tab_loop;
          END IF;
--
        END LOOP gt_kuragae_henpin_tab_loop;
--
        -- 倉替返品情報が正常終了の場合
        IF ( lv_retcode = cv_status_normal ) THEN
          -- 成功件数
          gn_normal_cnt := gn_normal_cnt + 1;
        END IF;
--
      END IF;
--
    END LOOP gt_slip_num_tab_loop;
--
    -- 倉替返品情報総件数が0件の場合
    IF ( gn_kuragae_henpin_all_cnt = 0 ) THEN
      RAISE no_data_expt;
    END IF;
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
    -- スキップ件数が1件以上ある場合、終了ステータス「警告」にする
    IF ( gn_warn_cnt > 0 ) THEN
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
END XXCOI002A02C;
/
