CREATE OR REPLACE PACKAGE BODY XXCOI008A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI008A02C(body)
 * Description      : 情報系システムへの連携の為、EBSの資材取引（標準）をCSVファイルに出力
 * MD.050           : 入出庫情報系連携 <MD050_COI_008_A02>
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_transaction_id     データ連携制御ワークテーブルの取引ID取得(A-2)
 *  create_csv_p           入出庫トランCSVの作成(A-5)
 *  material_tran_cur_p    資材取引情報の抽出(A-4)
 *  upd_transaction_id     データ連携制御ワークテーブルの取引ID更新(A-6)
 *  submain                メイン処理プロシージャ
 *                           ・ファイルのオープン処理(A-3)
 *                           ・ファイルのクローズ処理(A-7)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/01/15    1.0   S.Kanda          新規作成
 *  2009/04/02    1.1   T.Nakamura       [障害T1_0226]IF項目の順序を修正
 *  2009/06/03    1.2   H.Sasaki         [T1_1202]保管場所マスタの結合条件に在庫組織IDを追加
 *  2011/01/18    1.3   H.Sekine         [E_本稼動_01762]管轄拠点コードの対応
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
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOI008A02C';
  cv_appl_short_name_ccp    CONSTANT VARCHAR2(10)  := 'XXCCP';         -- アドオン：共通・IF領域
  cv_appl_short_name        CONSTANT VARCHAR2(10)  := 'XXCOI';         -- アドオン：共通・IF領域
  cv_file_slash             CONSTANT VARCHAR2(2)   := '/';             -- ファイル区切り用
  cv_file_encloser          CONSTANT VARCHAR2(2)   := '"';             -- 文字データ括り用
  --
  -- メッセージ定数
  cv_msg_xxcoi_00003        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00003';  -- ディレクトリ名取得エラー
  cv_msg_xxcoi_00004        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00004';  -- ファイル名取得エラー
  cv_msg_xxcoi_00005        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00005';  -- 在庫組織コード取得エラー
  cv_msg_xxcoi_00006        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00006';  -- 在庫組織ID取得エラー
  cv_msg_xxcoi_00007        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00007';  -- 会社コード取得エラー
  cv_msg_xxcoi_00008        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00008';  -- 対象データ無しメッセージ
  cv_msg_xxcoi_00023        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00023';  -- コンカレント入力パラメータなしメッセージ
  cv_msg_xxcoi_00027        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00027';  -- ファイル存在チェックエラー
  cv_msg_xxcoi_00028        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00028';  -- ファイル名出力メッセージ
  cv_msg_xxcoi_00029        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00029';  -- ディレクトリフルパス取得エラー
  cv_msg_xxcoi_10001        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10001';  -- ロック取得エラー
  cv_msg_xxcoi_10002        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10002';  -- ワークテーブル取引ID取得エラー
  --
  --トークン
  cv_tkn_pro                CONSTANT VARCHAR2(10)  := 'PRO_TOK';       -- プロファイル名用
  cv_tkn_dir                CONSTANT VARCHAR2(10)  := 'DIR_TOK';       -- プロファイル名用
  cv_cnt_token              CONSTANT VARCHAR2(10)  := 'COUNT';         -- 件数メッセージ用
  cv_tkn_file_name          CONSTANT VARCHAR2(10)  := 'FILE_NAME';     -- ファイル名用
  cv_tkn_org_code           CONSTANT VARCHAR2(15)  := 'ORG_CODE_TOK';  -- 在庫組織コード用
  cv_tkn_program_id         CONSTANT VARCHAR2(20)  := 'PROGRAM_ID';    -- プログラムID
  --
  --ファイルオープンモード
  cv_file_mode              CONSTANT VARCHAR2(2)   := 'W';             -- オープンモード
  --
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_process_date         DATE;                                 -- 日付取得用
  gv_dire_pass            VARCHAR2(100);                        -- ディレクトリパス名用
  gv_file_stock_delivery  VARCHAR2(50);                         -- 入出庫ファイル名用
  gv_organization_code    VARCHAR2(50);                         -- 在庫組織コード取得用
  gn_organization_id      mtl_parameters.organization_id%TYPE;  -- 在庫組織ID取得用
  gv_company_code         VARCHAR2(50);                         -- 会社コード取得用
  gv_file_name            VARCHAR2(150);                        -- ファイルパス名取得用
  gv_activ_file_h         UTL_FILE.FILE_TYPE;                   -- ファイルハンドル取得用
  gn_transaction_id       NUMBER;                               -- 取引ID取得用
  gn_max_tran             NUMBER;                               -- 取引ID最大値取得用
--
  -- ==============================
  -- ユーザー定義カーソル
  -- ==============================
  -- 入出庫情報取得
  CURSOR material_tran_cur
  IS
    SELECT mmt.transaction_id              -- 取引ID
         , mmt.subinventory_code           -- 保管場所コード
         , mmt.transaction_type_id         -- 取引タイプID
         , mmt.transaction_source_type_id  -- ソースタイプID
         , mtt.attribute5                  -- 取引タイプコード(DFF5)
         , mmt.primary_quantity            -- 数量
         , mmt.transaction_uom             -- 取引単位
         , mmt.transaction_quantity        -- 取引数量
         , mmt.transaction_date            -- 取引日
         , mmt.transaction_set_id          -- 取引ヘッダ
         , mmt.transfer_subinventory       -- 移動先保管場所コード
/* 2011/01/18 Ver1.3 Add Start */
         , mmt.attribute6                  -- 管轄拠点コード(DFF6)
/* 2011/01/18 Ver1.3 Add End   */
         , msib.segment1                   -- 品目コード
         , msi.attribute7                  -- 拠点コード
    FROM   mtl_material_transactions   mmt    -- 資材取引テーブル
         , mtl_system_items_b          msib   -- 品目マスタ
         , mtl_secondary_inventories   msi    -- 保管場所マスタ
         , mtl_transaction_types       mtt    -- 取引タイプマスタ
    WHERE mmt.transaction_id            >  gn_transaction_id        -- A-2.で取得した取引ID
    AND   msib.inventory_item_id        =  mmt.inventory_item_id    -- 品目ID
    AND   msib.organization_id          =  gn_organization_id       -- A-1.で取得した在庫組織ID
    AND   msi.secondary_inventory_name  =  mmt.subinventory_code    -- 保管場所コード
-- == 2009/06/03 V1.2 Added START ===============================================================
    AND   msi.organization_id           =  mmt.organization_id
-- == 2009/06/03 V1.2 Added END   ===============================================================
    AND   mtt.transaction_type_id       =  mmt.transaction_type_id  -- 取引タイプID
    ORDER BY mmt.transaction_id;                                    -- 取引ID
    --
    -- material_tranレコード型
    material_tran_rec   material_tran_cur%ROWTYPE;
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    get_transaction_id_expt   EXCEPTION;      -- 最終連携日時取得エラー
    lock_expt                 EXCEPTION;      -- ロック取得エラー
    --
    PRAGMA EXCEPTION_INIT( lock_expt, -54 );  -- ロック取得例外
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
    --プロファイル取得用定数
    cv_pro_dire_out_info       CONSTANT VARCHAR2(30)  := 'XXCOI1_DIRE_OUT_INFO';        -- ディレクトリ名取得用
    cv_pro_file_stock_deli     CONSTANT VARCHAR2(30)  := 'XXCOI1_FILE_STOCK_DELIVERY';  -- ファイル名取得用
    cv_pro_org_code            CONSTANT VARCHAR2(30)  := 'XXCOI1_ORGANIZATION_CODE';    -- 在庫組織コード取得用
    cv_pro_company_code        CONSTANT VARCHAR2(30)  := 'XXCOI1_COMPANY_CODE';         -- 会社コード取得用
--
    -- *** ローカル変数 ***
    lv_directory_path       VARCHAR2(100);     -- ディレクトリパス取得用
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
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
    -- ===============================
    --  初期化処理
    -- ===============================
    gd_process_date        :=  NULL;          -- 業務日付
    gv_dire_pass           :=  NULL;          -- ディレクトリパス名
    gv_file_stock_delivery :=  NULL;          -- 入出庫ファイル名
    gv_organization_code   :=  NULL;          -- 在庫組織コード名
    gn_organization_id     :=  NULL;          -- 在庫組織ID名
    gv_company_code        :=  NULL;          -- 会社コード名
    gv_file_name           :=  NULL;          -- ファイルパス名
    lv_directory_path      :=  NULL;          -- ディレクトリフルパス
    --
    -- ===============================
    --  1.SYSDATE取得
    -- ===============================
    gd_process_date   :=  sysdate;
    --
    -- =======================================================
    --  2～6.固定グローバル定数宣言部で同項目(WHOカラム)取得
    -- =======================================================
    --
    -- ====================================================
    -- 7.情報系_OUTBOUND格納ディレクトリ名情報を取得
    -- ====================================================
    gv_dire_pass       := fnd_profile.value( cv_pro_dire_out_info );
--
    -- ディレクトリ名情報が取得できなかった場合
    IF ( gv_dire_pass IS NULL ) THEN
      -- ディレクトリ名取得エラーメッセージ
      -- 「プロファイル:ディレクトリパス( PRO_TOK )の取得に失敗しました。」
      lv_errmsg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name
                      , iv_name         => cv_msg_xxcoi_00003
                      , iv_token_name1  => cv_tkn_pro
                      , iv_token_value1 => cv_pro_dire_out_info
                     );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
--
    -- =======================================
    -- 8.入出庫ファイル名を取得
    -- =======================================
    gv_file_stock_delivery   := fnd_profile.value( cv_pro_file_stock_deli );
    --
    -- 入出庫ファイル名が取得できなかった場合
    IF ( gv_file_stock_delivery IS NULL ) THEN
      -- ファイル名取得エラーメッセージ
      -- 「プロファイル:ファイル名( PRO_TOK )の取得に失敗しました。」
      lv_errmsg    := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                       , iv_name         => cv_msg_xxcoi_00004
                       , iv_token_name1  => cv_tkn_pro
                       , iv_token_value1 => cv_pro_file_stock_deli
                      );
      lv_errbuf    := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================
    -- 9.在庫組織コードを取得
    -- =====================================
    gv_organization_code := fnd_profile.value( cv_pro_org_code );
    --
    -- 在庫組織コードが取得できなかった場合
    IF  ( gv_organization_code  IS NULL ) THEN
      -- 在庫組織コード取得エラーメッセージ
      -- 「プロファイル:在庫組織コード( PRO_TOK )の取得に失敗しました。」
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                       , iv_name         => cv_msg_xxcoi_00005
                       , iv_token_name1  => cv_tkn_pro
                       , iv_token_value1 => cv_pro_org_code
                     );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================
    -- 在庫組織ID取得
    -- =====================================
    gn_organization_id := xxcoi_common_pkg.get_organization_id( gv_organization_code );
    --
    -- 共通関数のリターンコードが取得できなかった場合
    IF ( gn_organization_id IS NULL ) THEN
      -- 在庫組織ID取得エラーメッセージ
      -- 「在庫組織コード( ORG_CODE_TOK )に対する在庫組織IDの取得に失敗しました。」
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                     , iv_name         => cv_msg_xxcoi_00006
                     , iv_token_name1  => cv_tkn_org_code
                     , iv_token_value1 => gv_organization_code
                   );
      lv_errbuf := lv_errmsg;
      --
      RAISE global_api_expt;
    END IF;
    --
    -- =====================================
    -- 10.会社コードを取得
    -- =====================================
    gv_company_code  := fnd_profile.value( cv_pro_company_code );
    --
    -- 会社コードが取得できなかった場合
    IF  ( gv_company_code  IS NULL ) THEN
      -- 会社コード取得エラーメッセージ
      -- 「プロファイル:会社コード( PRO_TOK )の取得に失敗しました。」
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                       , iv_name         => cv_msg_xxcoi_00007
                       , iv_token_name1  => cv_tkn_pro
                       , iv_token_value1 => cv_pro_company_code
                     );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================
    -- 11.メッセージの出力①
    -- =====================================
    -- コンカレント入力パラメータなしメッセージを出力
    gv_out_msg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                     , iv_name         => cv_msg_xxcoi_00023
                    );
    --
    -- メッセージ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => gv_out_msg
    );
    --
    -- =====================================
    -- 12.メッセージの出力②
    -- =====================================
    --
    -- 2.で取得したプロファイル値よりディレクトリパスを取得
    BEGIN
      SELECT directory_path
      INTO   lv_directory_path
      FROM   all_directories     -- ディレクトリ情報
      WHERE  directory_name = gv_dire_pass;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- ディレクトリフルパス取得エラーメッセージ
        -- 「このディレクトリ名ではディレクトリパスは取得できません。
        -- （ディレクトリ名 = DIR_TOK ）」
        lv_errmsg   := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_short_name
                        , iv_name         => cv_msg_xxcoi_00029
                        , iv_token_name1  => cv_tkn_dir
                        , iv_token_value1 => gv_dire_pass
                       );
        lv_errbuf   := lv_errmsg;
        --
        RAISE global_process_expt;
    END;
    --
    -- IFファイル名（IFファイルのフルパス情報）を出力
    -- 'ディレクトリパス'と'/'と‘ファイル名'を結合
    gv_file_name  := lv_directory_path || cv_file_slash || gv_file_stock_delivery;
    --「ファイル： FILE_NAME 」
    --ファイル名出力メッセージ
    gv_out_msg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                     , iv_name         => cv_msg_xxcoi_00028
                     , iv_token_name1  => cv_tkn_file_name
                     , iv_token_value1 => gv_file_name
                    );
    --
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
      );
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_process_expt THEN
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
   * Procedure Name   : get_transaction_id
   * Description      : データ連携制御ワークテーブルの前回取引ID取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_transaction_id(
      ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
    , ov_retcode    OUT VARCHAR2      --   リターン・コード             --# 固定 #
    , ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_transaction_id'; -- プログラム名
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
    -- 取引ID用変数の初期化処理
    gn_transaction_id   :=  NULL;
--
    -- =======================================================
    -- データ連携制御ワークテーブルから前回取引IDを取得
    -- =======================================================
    BEGIN
--
      SELECT xcc.transaction_id AS transaction_id      -- 前回取引ID
      INTO   gn_transaction_id
      FROM   xxcoi_cooperation_control xcc             -- データ連携制御ワークテーブル
      WHERE  xcc.program_id         = cn_program_id;   -- 取得条件プログラムID
--
    EXCEPTION
      -- 前回の取引IDが取得できない場合
      WHEN NO_DATA_FOUND THEN
        RAISE get_transaction_id_expt;
--
      WHEN OTHERS THEN
        RAISE;
    END;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN get_transaction_id_expt THEN
      -- データ連携制御ワークテーブル取引ID取得エラーメッセージ
      -- 「前回連携時の取引ID取得に失敗しました。」
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name
                      , iv_name         => cv_msg_xxcoi_10002
                    );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
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
  END get_transaction_id;
--
  /**********************************************************************************
   * Procedure Name   : create_csv_p
   * Description      : 入出庫トランCSVの作成(A-5)
   ***********************************************************************************/
  PROCEDURE create_csv_p(
     ir_material_tran_cur  IN  material_tran_cur%ROWTYPE -- 入出庫データ
   , ov_errbuf             OUT VARCHAR2                  -- エラー・メッセージ           --# 固定 #
   , ov_retcode            OUT VARCHAR2                  -- リターン・コード             --# 固定 #
   , ov_errmsg             OUT VARCHAR2)                 -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_csv_p'; -- プログラム名
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
    cv_csv_com       CONSTANT VARCHAR2(1)   := ',';
--
    -- *** ローカル変数 ***
    lv_material_tran    VARCHAR2(3000);  -- CSV出力用変数
    lv_process_date     VARCHAR2(14);    -- システム日付 格納用変数
    lv_transaction_date VARCHAR2(14);    -- 最終更新日 格納用変数
/* 2011/01/18 Ver1.3 Add Start */
    lv_base_code        xxwsh_order_headers_all.head_sales_branch%TYPE;   -- 拠点コード
/* 2011/01/18 Ver1.3 Add End   */
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
    -- 変数の初期化
    lv_material_tran    := NULL;
    lv_process_date     := NULL;
    lv_transaction_date := NULL;
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    lv_process_date     := TO_CHAR( gd_process_date , 'YYYYMMDDHH24MISS' );                -- 連携日時
    lv_transaction_date := TO_CHAR( ir_material_tran_cur.transaction_date , 'YYYYMMDD' );  -- 取引日
    --
    -- 取引IDの最大値を取得するため変数に格納
    gn_max_tran         :=  ir_material_tran_cur.transaction_id;
/* 2011/01/18 Ver1.3 Add Start */
    --
    -- 管轄拠点コードのセット
    IF ( ir_material_tran_cur.attribute6 IS NOT NULL ) THEN
      lv_base_code := ir_material_tran_cur.attribute6;
    ELSE
      lv_base_code := ir_material_tran_cur.attribute7;
    END IF;
/* 2011/01/18 Ver1.3 Add End   */
--
    -- =================================
    -- CSVファイル作成
    -- =================================
    --
    -- カーソルで取得した値をCSVファイルに格納
    lv_material_tran := 
      cv_file_encloser || gv_company_code                            || cv_file_encloser || cv_csv_com || -- 会社コード
                          ir_material_tran_cur.transaction_id                            || cv_csv_com || -- 取引ID
      cv_file_encloser || ir_material_tran_cur.subinventory_code     || cv_file_encloser || cv_csv_com || -- 保管場所コード
                          ir_material_tran_cur.transaction_type_id                       || cv_csv_com || -- 取引タイプID
                          ir_material_tran_cur.transaction_source_type_id                || cv_csv_com || -- ソースタイプID
      cv_file_encloser || ir_material_tran_cur.attribute5            || cv_file_encloser || cv_csv_com || -- 取引タイプコード(DFF5)
                          ir_material_tran_cur.primary_quantity                          || cv_csv_com || -- 数量
      cv_file_encloser || ir_material_tran_cur.transaction_uom       || cv_file_encloser || cv_csv_com || -- 取引単位
                          ir_material_tran_cur.transaction_quantity                      || cv_csv_com || -- 取引数量
                          lv_transaction_date                                            || cv_csv_com || -- 取引日
                          ir_material_tran_cur.transaction_set_id                        || cv_csv_com || -- 取引ヘッダ
      cv_file_encloser || ir_material_tran_cur.transfer_subinventory || cv_file_encloser || cv_csv_com || -- 移動先保管場所コード
-- == 2009/04/02 V1.1 Moded START ===============================================================
--      cv_file_encloser || ir_material_tran_cur.segment1              || cv_file_encloser || cv_csv_com || -- 品目コード
/* 2011/01/18 Ver1.3 Mod Start */
--      cv_file_encloser || ir_material_tran_cur.attribute7            || cv_file_encloser || cv_csv_com || -- 拠点コード
      cv_file_encloser || lv_base_code                               || cv_file_encloser || cv_csv_com || -- 拠点コード
/* 2011/01/18 Ver1.3 Mod End   */
      cv_file_encloser || ir_material_tran_cur.segment1              || cv_file_encloser || cv_csv_com || -- 品目コード
-- == 2009/04/02 V1.1 Moded END   ===============================================================
                          lv_process_date;                                                                -- 連携日時
--
--
    UTL_FILE.PUT_LINE(
        gv_activ_file_h     -- A-3.で取得したファイルハンドル
      , lv_material_tran        -- デリミタ＋上記CSV出力項目
      );
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
  END create_csv_p;
--
  /**********************************************************************************
   * Procedure Name   : material_tran_cur_p
   * Description      : 資材取引情報の抽出(A-4)
   ***********************************************************************************/
  PROCEDURE material_tran_cur_p(
     ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ                  --# 固定 #
   , ov_retcode    OUT VARCHAR2     --   リターン・コード                    --# 固定 #
   , ov_errmsg     OUT VARCHAR2)    --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'material_tran_cur_p'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf  VARCHAR2(5000);   -- エラー・メッセージ
    lv_retcode VARCHAR2(1);      -- リターン・コード
    lv_errmsg  VARCHAR2(5000);   -- ユーザー・エラー・メッセージ
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
    --入出庫データ取得カーソルオープン
    OPEN material_tran_cur;
      --
      <<material_tran_loop>>
      LOOP
        FETCH material_tran_cur INTO material_tran_rec;
        --次データがなくなったら終了
        EXIT WHEN material_tran_cur%NOTFOUND;
        --対象件数加算
        gn_target_cnt := gn_target_cnt + 1;
--
        -- ===============================
        -- A-5．入出庫CSVの作成
        -- ===============================
        create_csv_p(
            ir_material_tran_cur  => material_tran_rec       -- 入出庫データレコード
          , ov_errbuf             => lv_errbuf               -- エラー・メッセージ           --# 固定 #
          , ov_retcode            => lv_retcode              -- リターン・コード             --# 固定 #
          , ov_errmsg             => lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
        );  
--
        IF (lv_retcode = cv_status_error) THEN
          -- エラー処理
          RAISE global_process_expt;
        END IF;
--
        -- 正常件数に加算
        gn_normal_cnt := gn_normal_cnt + 1;
      --
      --ループの終了
      END LOOP material_tran_loop;
      --
    --カーソルのクローズ
    CLOSE material_tran_cur;
    --
    -- データが０件で終了した場合
    IF ( gn_target_cnt = 0 ) THEN
      -- 対象データ無しメッセージ
      -- 「対象データはありません。」
      gv_out_msg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name
                      , iv_name         => cv_msg_xxcoi_00008
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
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      IF material_tran_cur%ISOPEN THEN
        CLOSE material_tran_cur;
      END IF;
      --
      -- エラーメッセージ
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルがオープンしている場合はクローズする
      IF material_tran_cur%ISOPEN THEN
        CLOSE material_tran_cur;
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルがオープンしている場合はクローズする
      IF material_tran_cur%ISOPEN THEN
        CLOSE material_tran_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルがオープンしている場合はクローズする
      IF material_tran_cur%ISOPEN THEN
        CLOSE material_tran_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END material_tran_cur_p;
--
  /**********************************************************************************
   * Procedure Name   : upd_transaction_id
   * Description      : データ連携制御ワークテーブルの取引ID更新(A-6)
   ***********************************************************************************/
  PROCEDURE upd_transaction_id(
      ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
    , ov_retcode    OUT VARCHAR2      --   リターン・コード             --# 固定 #
    , ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_transaction_id'; -- プログラム名
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
    CURSOR get_coop_wk_cur
    IS
      SELECT 'X'
      FROM   xxcoi_cooperation_control xcc         -- データ連携制御ワークテーブル
      WHERE  xcc.program_id     = cn_program_id    -- 取得条件プログラムID
      FOR UPDATE NOWAIT;                           -- ロック取得
--
    -- *** ローカル・レコード ***
    get_coop_wk_rec  get_coop_wk_cur%ROWTYPE;
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
    --==============================================================
    -- データ連携制御ワークテーブルロック取得
    --==============================================================
    -- カーソルオープン
    OPEN get_coop_wk_cur;
    FETCH get_coop_wk_cur INTO get_coop_wk_rec;
--
    -- ==============================================================
    -- データ連携制御ワークテーブル更新処理
    -- ==============================================================
    UPDATE   xxcoi_cooperation_control    xcc
    SET      xcc.last_cooperation_date  = gd_process_date            -- 最終連携日時
           , xcc.transaction_id         = gn_max_tran                -- A-5.で取得した取引IDの最大値
           , xcc.last_update_date       = cd_last_update_date        -- 最終更新日
           , xcc.last_updated_by        = cn_last_updated_by         -- 最終更新者
           , xcc.last_update_login      = cn_last_update_login       -- 最終更新者ログイン
           , xcc.request_id             = cn_request_id              -- 要求ID
           , xcc.program_application_id = cn_program_application_id  -- アプリケーションID
           , xcc.program_id             = cn_program_id              -- プログラムID
           , xcc.program_update_date    = cd_program_update_date     -- プログラム更新日時
    WHERE    xcc.program_id             = cn_program_id;             -- プログラムID
--
    -- カーソルクローズ
    CLOSE get_coop_wk_cur;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
    -- ロック取得エラー
    WHEN lock_expt THEN
      -- カーソルがオープンしている場合はクローズ
      IF get_coop_wk_cur%ISOPEN THEN
        CLOSE get_coop_wk_cur;
      END IF;
      --
      -- 対象件数を０にセット
      gn_target_cnt := 0;
      --
      -- ロックエラーメッセージ(データ連携制御ワークテーブル)
      -- 「データ連携制御ワークテーブルのロックに失敗しました。
      --   時間をおいてから、再度当処理を実施して下さい。
      --   （プログラムID＝ PROGRAM_ID ）」
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name
                      , iv_name         => cv_msg_xxcoi_10001
                      , iv_token_name1  => cv_tkn_program_id
                      , iv_token_value1 => cn_program_id
                    );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルがオープンしている場合はクローズ
      IF get_coop_wk_cur%ISOPEN THEN
        CLOSE get_coop_wk_cur;
      END IF;
      --
      -- 対象件数を０にセット
      gn_target_cnt := 0;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルがオープンしている場合はクローズ
      IF get_coop_wk_cur%ISOPEN THEN
        CLOSE get_coop_wk_cur;
      END IF;
      --
      -- 対象件数を０にセット
      gn_target_cnt := 0;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルがオープンしている場合はクローズ
      IF get_coop_wk_cur%ISOPEN THEN
        CLOSE get_coop_wk_cur;
      END IF;
      --
      -- 対象件数を０にセット
      gn_target_cnt := 0;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END upd_transaction_id;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
     ov_errbuf     OUT VARCHAR2    --   エラー・メッセージ           --# 固定 #
   , ov_retcode    OUT VARCHAR2    --   リターン・コード             --# 固定 #
   , ov_errmsg     OUT VARCHAR2)   --   ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100)  := 'submain'; -- プログラム名
    cn_max_linesize   CONSTANT BINARY_INTEGER := 32767;
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf       VARCHAR2(5000);                -- エラー・メッセージ
    lv_retcode      VARCHAR2(1);                   -- リターン・コード
    lv_errmsg       VARCHAR2(5000);                -- ユーザー・エラー・メッセージ
    --
    -- ファイルの存在チェック用変数
    lb_exists       BOOLEAN         DEFAULT NULL;  -- ファイル存在判定用変数
    ln_file_length  NUMBER          DEFAULT NULL;  -- ファイルの長さ
    ln_block_size   BINARY_INTEGER  DEFAULT NULL;  -- ブロックサイズ
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
    -- *** ローカル例外 ***
    remain_file_expt           EXCEPTION;
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
    -- 初期化処理
    -- ===============================
    -- グローバル変数の初期化
    gn_target_cnt    := 0;
    gn_normal_cnt    := 0;
    gn_error_cnt     := 0;
    gv_activ_file_h  := NULL;            -- ファイルハンドル
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ========================================
    --  A-1. 初期処理
    -- ========================================
    init(
        ov_errbuf    => lv_errbuf         -- エラー・メッセージ           --# 固定 #
      , ov_retcode   => lv_retcode        -- リターン・コード             --# 固定 #
      , ov_errmsg    => lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    -- 終了パラメータ判定
    IF (lv_retcode = cv_status_error) THEN
      -- エラー処理
      RAISE global_process_expt;
    END IF;
--
    -- ====================================================
    -- A-2．データ連携制御ワークテーブルの前回取引ID取得
    -- ====================================================
    get_transaction_id(
        ov_errbuf    => lv_errbuf      -- エラー・メッセージ           --# 固定 #
      , ov_retcode   => lv_retcode     -- リターン・コード             --# 固定 #
      , ov_errmsg    => lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- 終了パラメータ判定
    IF ( lv_retcode = cv_status_error ) THEN
      -- エラー処理
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-3．ファイルオープン処理
    -- ========================================
    -- ファイルの存在チェック
    UTL_FILE.FGETATTR( 
        location     =>  gv_dire_pass
      , filename     =>  gv_file_stock_delivery
      , fexists      =>  lb_exists
      , file_length  =>  ln_file_length
      , block_size   =>  ln_block_size
    );
--
    -- 同一ファイルが存在した場合はエラー
    IF( lb_exists = TRUE ) THEN
      RAISE remain_file_expt;
--
    ELSE
      -- ファイルオープン処理実行
      gv_activ_file_h := UTL_FILE.FOPEN(
                            location     => gv_dire_pass           -- ディレクトリパス
                          , filename     => gv_file_stock_delivery -- ファイル名
                          , open_mode    => cv_file_mode           -- オープンモード
                          , max_linesize => cn_max_linesize        -- ファイルサイズ
                         );
    END IF;
    --
    -- ========================================
    -- A-4．入出庫情報の抽出
    -- ========================================
    -- A-4の処理内部でA-5を処理
    material_tran_cur_p(
        ov_errbuf    => lv_errbuf         -- エラー・メッセージ           --# 固定 #
      , ov_retcode   => lv_retcode        -- リターン・コード             --# 固定 #
      , ov_errmsg    => lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    -- 終了パラメータ判定
    IF (lv_retcode = cv_status_error) THEN
      -- エラー処理
      RAISE global_process_expt;
    END IF;
--
    -- 対象件数が1件以上の場合
    IF ( gn_target_cnt > 0 ) THEN
--
      -- ==============================================================
      -- A-6.データ連携制御ワークテーブルの取引ID更新
      -- ==============================================================
      upd_transaction_id(
          ov_errbuf  => lv_errbuf         -- エラー・メッセージ           --# 固定 #
        , ov_retcode => lv_retcode        -- リターン・コード             --# 固定 #
        , ov_errmsg  => lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    -- ===============================
    -- A-7．ファイルのクローズ処理
    -- ===============================
    UTL_FILE.FCLOSE(
      file => gv_activ_file_h
      );
--
  EXCEPTION
    -- カーソルのクローズをここに記述する
    -- *** ファイル存在チェックエラー ***
    -- 「ファイル「 FILE_NAME 」はすでに存在します。」
    WHEN remain_file_expt THEN
      lv_errmsg    := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_short_name
                        , iv_name         => cv_msg_xxcoi_00027
                        , iv_token_name1  => cv_tkn_file_name
                        , iv_token_value1 => gv_file_stock_delivery
                      );
      lv_errbuf    := lv_errmsg;
      --
      ov_errmsg    := lv_errmsg;
      ov_errbuf    := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode   := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- CSVファイルがオープンしていればクローズする
      IF( UTL_FILE.IS_OPEN( gv_activ_file_h ) ) THEN
        UTL_FILE.FCLOSE(
          file => gv_activ_file_h
          );
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- CSVファイルがオープンしていればクローズする
      IF( UTL_FILE.IS_OPEN( gv_activ_file_h ) ) THEN
        UTL_FILE.FCLOSE(
          file => gv_activ_file_h
          );
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    --
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- CSVファイルがオープンしていればクローズする
      IF( UTL_FILE.IS_OPEN( gv_activ_file_h ) ) THEN
        UTL_FILE.FCLOSE(
          file => gv_activ_file_h
          );
      END IF;
      --
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
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
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
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- ===============================
    -- 変数の初期化
    -- ===============================
    lv_errbuf    := NULL;   -- エラー・メッセージ
    lv_retcode   := NULL;   -- リターン・コード
    lv_errmsg    := NULL;   -- ユーザー・エラー・メッセージ
    --
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
        ov_retcode => lv_retcode  -- エラー・メッセージ           --# 固定 #
      , ov_errbuf  => lv_errbuf   -- リターン・コード             --# 固定 #
      , ov_errmsg  => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --
    --
    --==============================================================
    -- A-6．件数表示処理
    --==============================================================
    -- エラー時は成功件数出力を０にセット
    --           エラー件数出力を１にセット
    IF( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
    --
    --
    --空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    --
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_ccp
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_ccp
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_ccp
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --
    --空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    --
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      -- 正常終了メッセージ
      -- 「処理が正常終了しました。」
      lv_message_code := cv_normal_msg;
    --
    ELSIF(lv_retcode = cv_status_error) THEN
      -- エラー終了全ロールバックメッセージ
      -- 「処理がエラー終了しました。データは全件処理前の状態に戻しました。」
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_ccp
                    , iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      --
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
END XXCOI008A02C;
/
