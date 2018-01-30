CREATE OR REPLACE PACKAGE BODY XXCOI010A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI010A01C(body)
 * Description      : 営業員在庫IF出力
 * MD.050           : 営業員在庫IF出力 MD050_COI_010_A01
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理 (A-1)
 *  get_sal_stf_inv        在庫情報抽出 (A-3)
 *  submain                メイン処理プロシージャ
 *                         UTLファイルオープン (A-2)
 *                         必須項目チェック処理 (A-4)
 *                         営業員在庫CSV作成 (A-5)
 *                         UTLファイルクローズ (A-6)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/18    1.0   T.Nakamura       新規作成
 *  2009/05/12    1.1   T.Nakamura       [障害T1_0813]容器群コードNULLチェックを削除
 *  2018/01/10    1.2   S.Yamashita      [E_本稼動_14486]次期HHTシステム リアルタイム在庫対応
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
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCOI010A01C';     -- パッケージ名
  cv_appl_short_name_xxccp    CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アプリケーション短縮名：XXCCP
  cv_appl_short_name_xxcoi    CONSTANT VARCHAR2(10)  := 'XXCOI';            -- アプリケーション短縮名：XXCOI
--
  -- メッセージ
  cv_para_target_date_msg     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10316'; -- パラメータ：処理対象日
  cv_file_name_msg            CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00028'; -- ファイル名出力メッセージ
  cv_no_data_msg              CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00008'; -- 対象データなしメッセージ
  cv_proc_date_get_err_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00011'; -- 業務日付取得エラーメッセージ
  cv_dire_name_get_err_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00003'; -- ディレクトリ名取得エラーメッセージ
  cv_dire_path_get_err_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00029'; -- ディレクトリフルパス取得エラーメッセージ
  cv_file_name_get_err_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00004'; -- ファイル名取得エラーメッセージ
  cv_org_code_get_err_msg     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00005'; -- 在庫組織コード取得エラーメッセージ
  cv_org_id_get_err_msg       CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00006'; -- 在庫組織ID取得エラーメッセージ
  cv_cat_set_n_get_err_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00014'; -- カテゴリセット名取得エラーメッセージ
  cv_file_remain_err_msg      CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00027'; -- ファイル存在チェックエラーメッセージ
  cv_ss_code_chk_err_msg      CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10022'; -- 営業員コードチェックエラーメッセージ
  cv_vg_code_chk_err_msg      CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10023'; -- 容器群コードチェックエラーメッセージ
  -- トークン
  cv_tkn_p_date               CONSTANT VARCHAR2(20)  := 'P_DATE';           -- 処理対象日
  cv_tkn_pro_tok              CONSTANT VARCHAR2(20)  := 'PRO_TOK';          -- プロファイル名
  cv_tkn_org_kode_tok         CONSTANT VARCHAR2(20)  := 'ORG_CODE_TOK';     -- 在庫組織コード
  cv_tkn_base_code_tok        CONSTANT VARCHAR2(20)  := 'BASE_CODE_TOK';    -- 拠点コード
  cv_tkn_inv_code_tok         CONSTANT VARCHAR2(20)  := 'INV_CODE_TOK';     -- 保管場所
  cv_tkn_item_code_tok        CONSTANT VARCHAR2(20)  := 'ITEM_CODE_TOK';    -- 品目コード
  cv_tkn_file_name            CONSTANT VARCHAR2(20)  := 'FILE_NAME';        -- ファイル名
  cv_tkn_dir_tok              CONSTANT VARCHAR2(20)  := 'DIR_TOK';          -- ディレクトリ名
--
-- Ver.1.2 S.Yamashita Add Start
  cv_subinv_type_warehouse    CONSTANT VARCHAR2(20)  := '1';                -- 保管場所区分：倉庫
-- Ver.1.2 S.Yamashita Add End
  cv_subinv_type_sal_stf      CONSTANT VARCHAR2(20)  := '2';                -- 保管場所区分：営業員
  cv_dept_hht_div_dept        CONSTANT VARCHAR2(20)  := '1';                -- 百貨店HHT区分：百貨店
  cv_cust_class_code_base     CONSTANT VARCHAR2(20)  := '1';                -- 顧客区分：拠点
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_target_date     VARCHAR2(50);        -- 処理対象日：文字型
  gd_target_date     DATE;                -- 処理対象日：日付型
  gd_sysdate         DATE;                -- SYSDATE
  gd_process_date    DATE;                -- 業務日付
  gv_dire_name       VARCHAR2(50);        -- ディレクトリ名
  gv_file_name       VARCHAR2(50);        -- ファイル名
  gv_org_code        VARCHAR2(50);        -- 在庫組織コード
  gn_org_id          VARCHAR2(50);        -- 在庫組織ID
  gv_cat_set_name    VARCHAR2(50);        -- カテゴリセット名
  g_file_handle      UTL_FILE.FILE_TYPE;  -- ファイルハンドル
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
  -- 営業員在庫情報抽出
  CURSOR get_sal_stf_inv_cur
  IS
    SELECT   DECODE( xca.dept_hht_div                               -- 顧客追加情報の百貨店HHT区分が
                   , cv_dept_hht_div_dept                           -- '1'の場合
                   , xca.management_base_code                       -- 顧客追加情報の管理元拠点コード
                   , xird.base_code )     AS sale_base_code         -- それ以外の場合、月次在庫受払表(日次)の拠点コード
           , xird.book_inventory_quantity AS prev_inv_quantity      -- 前日在庫数
           , msi.attribute3               AS sale_staff_code        -- 営業員コード
           , xsib.vessel_group            AS vessel_group_code      -- 容器群コード
           , msib.segment1                AS item_code              -- 品目コード
           , mcb.segment1                 AS item_division          -- 商品区分
           , msi.secondary_inventory_name AS inv_code               -- 保管場所コード
-- Ver.1.2 S.Yamashita Add Start
           , xird.subinventory_type       AS subinventory_type      -- 保管場所区分
-- Ver.1.2 S.Yamashita Add ENd
    FROM     xxcoi_inv_reception_daily    xird                      -- 月次在庫受払表(日次)テーブル
           , mtl_secondary_inventories    msi                       -- 保管場所マスタ
           , mtl_system_items_b           msib                      -- 品目マスタ
           , mtl_categories_b             mcb                       -- 品目カテゴリマスタ
           , mtl_item_categories          mic                       -- 品目カテゴリ割当
           , mtl_category_sets_tl         mcst                      -- カテゴリセット
           , xxcmm_system_items_b         xsib                      -- Disc品目アドオン
           , hz_cust_accounts             hca                       -- 顧客マスタ
           , xxcmm_cust_accounts          xca                       -- 顧客追加情報
-- Ver.1.2 S.Yamashita Mod Start
--    WHERE    xird.subinventory_type       = cv_subinv_type_sal_stf  -- 抽出条件：保管場所区分が営業員
    WHERE    xird.subinventory_type       IN ( cv_subinv_type_warehouse, cv_subinv_type_sal_stf )  -- 抽出条件：保管場所区分が倉庫または営業員
-- Ver.1.2 S.Yamashita Mod End
    AND      xird.practice_date           = NVL( gd_target_date     -- 抽出条件：年月日が処理対象日と等しい
                                               , gd_process_date )  -- 処理対象日がNULLの場合、業務日付と等しい
    AND      msi.secondary_inventory_name = xird.subinventory_code  -- 結合条件：保管場所マスタと月次在庫受払表(日次)
    AND      msib.inventory_item_id       = xird.inventory_item_id  -- 結合条件：品目マスタと月次在庫受払表(日次)
    AND      msib.organization_id         = gn_org_id               -- 抽出条件：在庫組織IDが初期処理で取得した物
    AND      mcst.category_set_name       = gv_cat_set_name         -- 抽出条件；カテゴリセット名が初期処理で取得した物
    AND      mcst.language                = USERENV( 'LANG' )       -- 抽出条件；言語がユーザの環境と同一
    AND      mic.category_set_id          = mcst.category_set_id    -- 結合条件：品目カテゴリ割当とカテゴリセット
    AND      mic.inventory_item_id        = xird.inventory_item_id  -- 結合条件：品目カテゴリ割当と月次在庫受払表(日次)
    AND      mic.category_id              = mcb.category_id         -- 結合条件：品目カテゴリ割当と品目カテゴリマスタ
    AND      mic.organization_id          = msib.organization_id    -- 結合条件：品目カテゴリ割当と品目マスタ
    AND      xsib.item_code               = msib.segment1           -- 結合条件：Disc品目アドオンと品目マスタ
    AND      hca.account_number           = xird.base_code          -- 結合条件：顧客マスタと月次在庫受払表(日次)
    AND      hca.customer_class_code      = cv_cust_class_code_base -- 取得条件：顧客区分が拠点
    AND      xca.customer_id              = hca.cust_account_id     -- 結合条件：顧客追加情報と顧客マスタ
    ;
--
  -- ==============================
  -- ユーザー定義グローバルテーブル
  -- ==============================
  TYPE g_get_sal_stf_inv_ttype IS TABLE OF get_sal_stf_inv_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  g_get_sal_stf_inv_tab        g_get_sal_stf_inv_ttype;
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  remain_file_expt          EXCEPTION;     -- ファイル存在エラー
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
    , ov_retcode    OUT VARCHAR2      --   リターン・コード             --# 固定 #
    , ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- プロファイル XXCOI:HHT_OUTBOUND格納ディレクトリパス
    cv_prf_dire_out_hht        CONSTANT VARCHAR2(30) := 'XXCOI1_DIRE_OUT_HHT';
    -- プロファイル XXCOI:営業員在庫IF出力ファイル名
    cv_prf_file_sal_staff      CONSTANT VARCHAR2(30) := 'XXCOI1_FILE_SALE_STAFF';
    -- プロファイル XXCOI:在庫組織コード
    cv_prf_file_org_code       CONSTANT VARCHAR2(30) := 'XXCOI1_ORGANIZATION_CODE';
    -- プロファイル XXCOS:本社商品区分
    cv_prf_file_item_div_h     CONSTANT VARCHAR2(30) := 'XXCOS1_ITEM_DIV_H';
--
    cv_slash                   CONSTANT VARCHAR2(1)  := '/';  -- スラッシュ
--
    -- *** ローカル変数 ***
    lv_dire_path               VARCHAR2(100);                 -- ディレクトリフルパス格納変数
    lv_file_name               VARCHAR2(100);                 -- ファイル名格納変数
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
    -- コンカレント入力パラメータ出力
    -- ===============================
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_xxcoi
                    , iv_name         => cv_para_target_date_msg
                    , iv_token_name1  => cv_tkn_p_date
                    , iv_token_value1 => TO_CHAR( TRUNC( gd_target_date ), 'YYYY/MM/DD' )
                  );
    -- メッセージ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => gv_out_msg
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => ''
    );
--
    -- ===============================
    -- SYSDATE取得
    -- ===============================
    gd_sysdate := SYSDATE;
--
    -- ===============================
    -- 業務日付取得
    -- ===============================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- 業務日付が取得できない場合
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_proc_date_get_err_msg
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- プロファイル：ディレクトリパス取得
    -- ===============================
    -- ディレクトリパス取得
    gv_dire_name := fnd_profile.value( cv_prf_dire_out_hht );
    -- ディレクトリパスが取得できない場合
    IF ( gv_dire_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_dire_name_get_err_msg
                     , iv_token_name1  => cv_tkn_pro_tok
                     , iv_token_value1 => cv_prf_dire_out_hht
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ディレクトリフルパス取得
    BEGIN
      SELECT directory_path
      INTO   lv_dire_path
      FROM   all_directories
      WHERE  directory_name    = gv_dire_name;
    EXCEPTION
      -- ディレクトリフルパスが取得できない場合
      WHEN NO_DATA_FOUND THEN
        lv_errmsg   := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name_xxcoi
                         , iv_name         => cv_dire_path_get_err_msg
                         , iv_token_name1  => cv_tkn_dir_tok
                         , iv_token_value1 => gv_dire_name
                       );
        lv_errbuf   := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- ===============================
    -- プロファイル：ファイル名取得
    -- ===============================
    gv_file_name := fnd_profile.value( cv_prf_file_sal_staff );
    -- ファイル名が取得できない場合
    IF ( gv_file_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_file_name_get_err_msg
                     , iv_token_name1  => cv_tkn_pro_tok
                     , iv_token_value1 => cv_prf_file_sal_staff
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- プロファイル：在庫組織コード取得
    -- ===============================
    gv_org_code := fnd_profile.value( cv_prf_file_org_code );
    -- 在庫組織コードが取得できない場合
    IF ( gv_org_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_org_code_get_err_msg
                     , iv_token_name1  => cv_tkn_pro_tok
                     , iv_token_value1 => cv_prf_file_org_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 在庫組織ID取得
    -- ===============================
    gn_org_id := xxcoi_common_pkg.get_organization_id( iv_organization_code => gv_org_code );
    -- 在庫組織IDが取得できない場合
    IF ( gn_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_org_id_get_err_msg
                     , iv_token_name1  => cv_tkn_org_kode_tok
                     , iv_token_value1 => gv_org_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- プロファイル：カテゴリセット名取得
    -- ===============================
    gv_cat_set_name := fnd_profile.value( cv_prf_file_item_div_h );
    -- カテゴリセットが取得できない場合
    IF ( gv_cat_set_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_cat_set_n_get_err_msg
                     , iv_token_name1  => cv_tkn_pro_tok
                     , iv_token_value1 => cv_prf_file_item_div_h
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ==============================================================
    -- IFファイル名（IFファイルのフルパス情報）出力
    -- ==============================================================
    lv_file_name := lv_dire_path || cv_slash || gv_file_name;
    gv_out_msg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_xxcoi
                      , iv_name         => cv_file_name_msg
                      , iv_token_name1  => cv_tkn_file_name
                      , iv_token_value1 => lv_file_name
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
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN
    -- *** 共通関数例外ハンドラ ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
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
   * Procedure Name   : get_sal_stf_inv
   * Description      : 在庫情報抽出(A-3)
   ***********************************************************************************/
  PROCEDURE get_sal_stf_inv(
      ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
    , ov_retcode    OUT VARCHAR2      --   リターン・コード             --# 固定 #
    , ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_sal_stf_inv'; -- プログラム名
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
    -- カーソルオープン
    OPEN  get_sal_stf_inv_cur;
--
    -- カーソルデータ取得
    FETCH get_sal_stf_inv_cur BULK COLLECT INTO g_get_sal_stf_inv_tab;
--
    -- カーソルのクローズ
    CLOSE get_sal_stf_inv_cur;
--
    -- ===============================
    -- 対象件数カウント
    -- ===============================
    gn_target_cnt := g_get_sal_stf_inv_tab.COUNT;
--
    -- ===============================
    -- 抽出0件チェック
    -- ===============================
    IF ( gn_target_cnt = 0 ) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_xxcoi
                      , iv_name         => cv_no_data_msg
                    );
      -- メッセージ出力
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => gv_out_msg
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
      -- カーソルがOPENしている場合
      IF ( get_sal_stf_inv_cur%ISOPEN ) THEN
        CLOSE get_sal_stf_inv_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルがOPENしている場合
      IF ( get_sal_stf_inv_cur%ISOPEN ) THEN
        CLOSE get_sal_stf_inv_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルがOPENしている場合
      IF ( get_sal_stf_inv_cur%ISOPEN ) THEN
        CLOSE get_sal_stf_inv_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_sal_stf_inv;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
      ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
    , ov_retcode    OUT VARCHAR2      --   リターン・コード             --# 固定 #
    , ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    cv_open_mode             CONSTANT VARCHAR2(1) := 'w';  -- オープンモード：書き込み
    cv_delimiter             CONSTANT VARCHAR2(1) := ',';  -- 区切り文字
    cv_encloser              CONSTANT VARCHAR2(1) := '"';  -- 括り文字
    cv_const_zero            CONSTANT VARCHAR2(1) := '0';  -- '0'固定
--
    -- *** ローカル変数 ***
    ln_file_length           NUMBER;                       -- ファイルの長さの変数
    ln_block_size            NUMBER;                       -- ブロックサイズの変数
    lb_fexists               BOOLEAN;                      -- ファイル存在チェック結果
    lv_csv_file              VARCHAR2(1500);               -- CSVファイル
    lv_prev_inv_quantity     VARCHAR2(100);                -- 前日在庫数
    lv_sysdate               VARCHAR2(100);                -- SYSDATE
--
    lv_chk_status            BOOLEAN;                      -- 必須チェックステータス
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
    gn_warn_cnt   := 0;
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
        ov_errbuf  => lv_errbuf         -- エラー・メッセージ           --# 固定 #
      , ov_retcode => lv_retcode        -- リターン・コード             --# 固定 #
      , ov_errmsg  => lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- UTLファイルオープン (A-2)
    -- ===============================
    -- ファイルの存在チェック
    UTL_FILE.FGETATTR(
        location    => gv_dire_name
      , filename    => gv_file_name
      , fexists     => lb_fexists
      , file_length => ln_file_length
      , block_size  => ln_block_size
    );
    IF( lb_fexists = TRUE ) THEN
      RAISE remain_file_expt;
    END IF;
--
    -- ファイルのオープン
    g_file_handle := UTL_FILE.FOPEN(
                         location  => gv_dire_name
                       , filename  => gv_file_name
                       , open_mode => cv_open_mode
                     );
--
    -- ===============================
    -- 在庫情報抽出 (A-3)
    -- ===============================
    get_sal_stf_inv(
        ov_errbuf  => lv_errbuf         -- エラー・メッセージ           --# 固定 #
      , ov_retcode => lv_retcode        -- リターン・コード             --# 固定 #
      , ov_errmsg  => lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ループ開始
    -- ===============================
    <<create_file_loop>>
    FOR i IN 1 .. g_get_sal_stf_inv_tab.COUNT LOOP
--
      -- 必須チェックステータスの初期化
      lv_chk_status := TRUE;
--
-- Ver.1.2 S.Yamashita Add Start
      -- 営業員の場合
      IF ( g_get_sal_stf_inv_tab(i).subinventory_type = cv_subinv_type_sal_stf ) THEN
-- Ver.1.2 S.Yamashita Add End
        -- ===============================
        -- 必須項目チェック処理 (A-4)
        -- ===============================
        -- 営業員コードNULLチェック
        IF ( g_get_sal_stf_inv_tab(i).sale_staff_code IS NULL ) THEN
          gv_out_msg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_appl_short_name_xxcoi
                          , iv_name         => cv_ss_code_chk_err_msg
                          , iv_token_name1  => cv_tkn_base_code_tok
                          , iv_token_value1 => g_get_sal_stf_inv_tab(i).sale_base_code
                          , iv_token_name2  => cv_tkn_inv_code_tok
                          , iv_token_value2 => g_get_sal_stf_inv_tab(i).inv_code
                          , iv_token_name3  => cv_tkn_item_code_tok
                          , iv_token_value3 => g_get_sal_stf_inv_tab(i).item_code
                        );
          -- メッセージ出力
          FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
            , buff   => gv_out_msg
          );
          FND_FILE.PUT_LINE(
              which  => FND_FILE.LOG
            , buff   => SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||gv_out_msg,1,5000 )
          );
          lv_chk_status := FALSE;
          ov_retcode    := cv_status_warn;
        END IF;
-- Ver.1.2 S.Yamashita Add Start
      END IF;
-- Ver.1.2 S.Yamashita Add End
--
-- == 2009/05/12 V1.1 Deleted START ================================================================
--      -- 容器群コードNULLチェック
--      IF ( g_get_sal_stf_inv_tab(i).vessel_group_code IS NULL ) THEN
--        gv_out_msg := xxccp_common_pkg.get_msg(
--                          iv_application  => cv_appl_short_name_xxcoi
--                        , iv_name         => cv_vg_code_chk_err_msg
--                        , iv_token_name1  => cv_tkn_base_code_tok
--                        , iv_token_value1 => g_get_sal_stf_inv_tab(i).sale_base_code
--                        , iv_token_name2  => cv_tkn_inv_code_tok
--                        , iv_token_value2 => g_get_sal_stf_inv_tab(i).inv_code
--                        , iv_token_name3  => cv_tkn_item_code_tok
--                        , iv_token_value3 => g_get_sal_stf_inv_tab(i).item_code
--                      );
--        -- メッセージ出力
--        FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--          , buff   => gv_out_msg
--        );
--        FND_FILE.PUT_LINE(
--            which  => FND_FILE.LOG
--          , buff   => SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||gv_out_msg,1,5000 )
--        );
--        lv_chk_status := FALSE;
--        ov_retcode    := cv_status_warn;
--      END IF;
-- == 2009/05/12 V1.1 Deleted END   ================================================================
--
      -- 必須チェックステータスがFALSEの場合
      IF ( lv_chk_status = FALSE ) THEN
        gn_warn_cnt := gn_warn_cnt + 1;
      -- ステータスが正常の場合
      ELSE
        -- ===============================
        -- 営業員在庫CSV作成 (A-5)
        -- ===============================
-- Ver.1.2 S.Yamashita Add Start
        -- 倉庫の場合
        IF ( g_get_sal_stf_inv_tab(i).subinventory_type = cv_subinv_type_warehouse ) THEN
          lv_prev_inv_quantity := NULL; -- 前日在庫数
        ELSE
-- Ver.1.2 S.Yamashita Add End
          lv_prev_inv_quantity := TO_CHAR( g_get_sal_stf_inv_tab(i).prev_inv_quantity ); -- 前日在庫数
-- Ver.1.2 S.Yamashita Add Start
        END IF;
-- Ver.1.2 S.Yamashita Add End
        lv_sysdate           := TO_CHAR( gd_sysdate, 'YYYY/MM/DD HH24:MI:SS' );        -- SYSDATE
--
        -- CSVデータを作成
        lv_csv_file := (
          cv_encloser || g_get_sal_stf_inv_tab(i).sale_base_code    || cv_encloser || cv_delimiter || -- 売上拠点コード
          cv_encloser || g_get_sal_stf_inv_tab(i).sale_staff_code   || cv_encloser || cv_delimiter || -- 営業員コード
          cv_encloser || g_get_sal_stf_inv_tab(i).vessel_group_code || cv_encloser || cv_delimiter || -- 容器群コード
          cv_encloser || g_get_sal_stf_inv_tab(i).item_code         || cv_encloser || cv_delimiter || -- 品目コード
                         lv_prev_inv_quantity                                      || cv_delimiter || -- 前日在庫数
                         cv_const_zero                                             || cv_delimiter || -- 倉庫より入庫
                         cv_const_zero                                             || cv_delimiter || -- 売上出庫
          cv_encloser || lv_sysdate                                 || cv_encloser || cv_delimiter || -- SYSDATE
          cv_encloser || g_get_sal_stf_inv_tab(i).item_division     || cv_encloser                    -- 商品区分
-- Ver.1.2 S.Yamashita Add Start
          || cv_delimiter || cv_encloser || g_get_sal_stf_inv_tab(i).inv_code                     || cv_encloser  -- 保管場所コード
          || cv_delimiter ||                TO_CHAR( g_get_sal_stf_inv_tab(i).prev_inv_quantity )                 -- 前日在庫数（営業車・倉庫）
-- Ver.1.2 S.Yamashita Add End
        );
--
        -- ===============================
        -- CSVデータを出力
        -- ===============================
        UTL_FILE.PUT_LINE(
            file   => g_file_handle
          , buffer => lv_csv_file
        );
--
        -- ===============================
        -- 成功件数カウント
        -- ===============================
        gn_normal_cnt := gn_normal_cnt + 1;
      END IF;
--
    END LOOP create_file_loop;
--
    -- ===============================
    -- UTLファイルクローズ (A-6)
    -- ===============================
    UTL_FILE.FCLOSE( file => g_file_handle );
--
  EXCEPTION
--
    -- *** ファイル存在チェックエラー ***
    WHEN remain_file_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_xxcoi
                      , iv_name         => cv_file_remain_err_msg
                      , iv_token_name1  => cv_tkn_file_name
                      , iv_token_value1 => gv_file_name
                    );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- ファイルがOPENしている場合
      IF ( UTL_FILE.IS_OPEN( file => g_file_handle ) ) THEN
        UTL_FILE.FCLOSE( file => g_file_handle );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- ファイルがOPENしている場合
      IF ( UTL_FILE.IS_OPEN( file => g_file_handle ) ) THEN
        UTL_FILE.FCLOSE( file => g_file_handle );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- ファイルがOPENしている場合
      IF ( UTL_FILE.IS_OPEN( file => g_file_handle ) ) THEN
        UTL_FILE.FCLOSE( file => g_file_handle );
      END IF;
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
      errbuf          OUT VARCHAR2       --   エラー・メッセージ  --# 固定 #
    , retcode         OUT VARCHAR2       --   リターン・コード    --# 固定 #
    , iv_target_date  IN  VARCHAR2)      --   処理対象日
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
    -- パラメータの処理対象日をグローバル変数に格納
    gv_target_date := iv_target_date;
    gd_target_date := TO_DATE( gv_target_date, 'YYYY/MM/DD HH24:MI:SS' );
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
        ov_errbuf  => lv_errbuf         -- エラー・メッセージ           --# 固定 #
      , ov_retcode => lv_retcode        -- リターン・コード             --# 固定 #
      , ov_errmsg  => lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      -- 成功件数、スキップ件数の初期化及びエラー件数のセット
      gn_normal_cnt := 0;
      gn_warn_cnt   := 0;
      gn_error_cnt  := 1;
      --エラー出力
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_errmsg       -- ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_errbuf       -- エラーメッセージ
      );
    END IF;
--
    -- 空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    -- 対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_xxccp
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_target_cnt )
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
--
    -- 成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_xxccp
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_normal_cnt )
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
--
    -- エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_xxccp
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_error_cnt )
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
--
    -- スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_xxccp
                    , iv_name         => cv_skip_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_warn_cnt )
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- 空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    -- 終了メッセージ
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_xxccp
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
END XXCOI010A01C;
/
