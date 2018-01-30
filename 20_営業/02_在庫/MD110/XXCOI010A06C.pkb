CREATE OR REPLACE PACKAGE BODY XXCOI010A06C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * Package Name     : XXCOI010A06C(body)
 * Description      : 工場入庫情報HHT連携
 * MD.050           : 工場入庫情報HHT連携 <MD050_COI_010_A06>
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  create_csv             対象データ抽出からCSV作成 (A-2,A-3,A-4)
 *  submain                メイン処理プロシージャ (A-5)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2018/01/12    1.0   SCSK佐々木       新規作成(E_本稼動_14486対応)
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
  procedure_common_expt     EXCEPTION;      --  ユーザ定義メッセージ出力用共通例外
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(100)  :=  'XXCOI010A06C';           --  パッケージ名
  cv_appl_short_name_xxcoi    CONSTANT VARCHAR2(10)   :=  'XXCOI';                  --  アプリケーション短縮名：XXCOI
  --  メッセージ・トークン
  cv_msg_xxcoi1_10316         CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-10316';       --  パラメータ.処理対象日
  cv_msg_xxcoi1_00011         CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-00011';       --  業務日付取得エラーメッセージ
  cv_msg_xxcoi1_00003         CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-00003';       --  ディレクトリ名取得エラーメッセージ
  cv_msg_xxcoi1_00029         CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-00029';       --  ディレクトリフルパス取得エラーメッセージ
  cv_msg_xxcoi1_00004         CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-00004';       --  ファイル名取得エラーメッセージ
  cv_msg_xxcoi1_00028         CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-00028';       --  ファイル名出力メッセージ
  cv_msg_xxcoi1_00027         CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-00027';       --  ファイル存在チェックエラー
  cv_msg_xxcoi1_00008         CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-00008';       --  対象データ無しメッセージ
  cv_msg_xxcoi1_10521         CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-10521';       --  保管場所情報取得エラーメッセージ
  cv_msg_xxcoi1_10380         CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-10380';       --  倉庫保管場所重複エラー
  cv_tkn_xxcoi1_10316_1       CONSTANT VARCHAR2(30)   :=  'P_DATE';                 --  APP-XXCOI1-10316用TOKEN
  cv_tkn_xxcoi1_00003_1       CONSTANT VARCHAR2(30)   :=  'PRO_TOK';                --  APP-XXCOI1-00003用TOKEN
  cv_tkn_xxcoi1_00029_1       CONSTANT VARCHAR2(30)   :=  'DIR_TOK';                --  APP-XXCOI1-00029用TOKEN
  cv_tkn_xxcoi1_00004_1       CONSTANT VARCHAR2(30)   :=  'PRO_TOK';                --  APP-XXCOI1-00004用TOKEN
  cv_tkn_xxcoi1_00028_1       CONSTANT VARCHAR2(30)   :=  'FILE_NAME';              --  APP-XXCOI1-00028用TOKEN
  cv_tkn_xxcoi1_00027_1       CONSTANT VARCHAR2(30)   :=  'FILE_NAME';              --  APP-XXCOI1-00027用TOKEN
  cv_tkn_xxcoi1_10521_1       CONSTANT VARCHAR2(30)   :=  'BASE_CODE';              --  APP-XXCOI1-10521用TOKEN
  cv_tkn_xxcoi1_10521_2       CONSTANT VARCHAR2(30)   :=  'SUBINV_CODE';            --  APP-XXCOI1-10521用TOKEN
  cv_tkn_xxcoi1_10380_1       CONSTANT VARCHAR2(30)   :=  'DEPT_CODE';              --  APP-XXCOI1-10380用TOKEN
  cv_tkn_xxcoi1_10380_2       CONSTANT VARCHAR2(30)   :=  'WHOUSE_CODE';            --  APP-XXCOI1-10380用TOKEN
  --  プロファイル
  cv_profile_dire_out_hht     CONSTANT VARCHAR2(30)   :=  'XXCOI1_DIRE_OUT_HHT';    --  XXCOI:HHT_OUTBOUND格納ディレクトリパス
  cv_profile_factory_hht      CONSTANT VARCHAR2(30)   :=  'XXCOI1_FILE_FACTORYHHT'; --  XXCOI:工場入庫情報HHT連携ファイル名
  --
  cv_param_none               CONSTANT VARCHAR2(10)   :=  'なし';                   --  パラメータ未設定
  cv_slip_type_10             CONSTANT VARCHAR2(2)    :=  '10';                     --  伝票区分 10:工場入庫
  cv_subinv_type_1            CONSTANT VARCHAR2(1)    :=  '1';                      --  保管場所区分 1:倉庫
  cv_subinv_type_3            CONSTANT VARCHAR2(1)    :=  '3';                      --  保管場所区分 3:預け先
  cv_subinv_type_4            CONSTANT VARCHAR2(1)    :=  '4';                      --  保管場所区分 4:専門店
  cv_slash                    CONSTANT VARCHAR2(1)    :=  '/';
  cv_comma                    CONSTANT VARCHAR2(1)    :=  ',';
  cv_dquot                    CONSTANT VARCHAR2(1)    :=  '"';
  cv_yes                      CONSTANT VARCHAR2(1)    :=  'Y';
  cv_no                       CONSTANT VARCHAR2(1)    :=  'N';
  cv_utlfile_open_w           CONSTANT VARCHAR2(1)    :=  'w';                      --  オープンモード w:書き込み
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_param_target_date        DATE;                                                 --  パラメータ.処理対象日
  gd_process_date             DATE;                                                 --  業務日付
  g_file_handle               UTL_FILE.FILE_TYPE;                                   --  ファイルハンドル

--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      iv_target_date    IN  VARCHAR2      --  パラメータ：処理対象日
    , ov_errbuf         OUT VARCHAR2      --  エラー・メッセージ           --# 固定 #
    , ov_retcode        OUT VARCHAR2      --  リターン・コード             --# 固定 #
    , ov_errmsg         OUT VARCHAR2      --  ユーザー・エラー・メッセージ --# 固定 #
  ) IS
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
    lv_dire_name      VARCHAR2(50);                             --  ディレクトリ名
    lt_dire_path      all_directories.directory_path%TYPE;      --  ディレクトリパス
    lv_file_name      VARCHAR2(50);                             --  ファイル名
    lb_fexists        BOOLEAN;                                  --  ファイル存在チェック結果
    ln_file_length    NUMBER;                                   --  ファイルの長さの変数
    ln_block_size     NUMBER;                                   --  ブロックサイズの変数
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
    --  初期化
    lv_dire_name      :=  NULL;           --  ディレクトリ名
    lt_dire_path      :=  NULL;           --  ディレクトリパス
    lv_file_name      :=  NULL;           --  ファイル名
    lb_fexists        :=  FALSE;          --  ファイル存在チェック結果
    ln_file_length    :=  NULL;           --  ファイルの長さの変数
    ln_block_size     :=  NULL;           --  ブロックサイズの変数
    gd_process_date   :=  NULL;
    g_file_handle     :=  NULL;
    --
    -- ===================================
    --  コンカレント入力パラメータ出力
    -- ===================================
    gv_out_msg  :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_appl_short_name_xxcoi
                      , iv_name           =>  cv_msg_xxcoi1_10316
                      , iv_token_name1    =>  cv_tkn_xxcoi1_10316_1
                      , iv_token_value1   =>  CASE  WHEN  iv_target_date IS NOT NULL
                                                      THEN  iv_target_date
                                                      ELSE  cv_param_none
                                              END
                    );
    -- メッセージ出力
    FND_FILE.PUT_LINE(
        which   =>  FND_FILE.OUTPUT
      , buff    =>  gv_out_msg
    );
    FND_FILE.PUT_LINE(
        which   =>  FND_FILE.LOG
      , buff    =>  gv_out_msg
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
        which   =>  FND_FILE.OUTPUT
      , buff    =>  ''
    );
    FND_FILE.PUT_LINE(
        which   =>  FND_FILE.LOG
      , buff    =>  ''
    );
    --
    -- ===================================
    --  パラメータ保持
    -- ===================================
    gd_param_target_date  :=  TO_DATE( iv_target_date, 'YYYY/MM/DD HH24:MI:SS' );
    --
    -- ===================================
    --  業務日付取得
    -- ===================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF ( gd_process_date IS NULL ) THEN
      --  業務日付が取得できない場合
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_appl_short_name_xxcoi
                      , iv_name           =>  cv_msg_xxcoi1_00011
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE procedure_common_expt;
    END IF;
    --
    -- ===================================
    --  ディレクトリ名取得
    -- ===================================
    lv_dire_name  :=  fnd_profile.value( cv_profile_dire_out_hht );
    IF ( lv_dire_name IS NULL ) THEN
      --  ディレクトリ名が取得できない場合
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_appl_short_name_xxcoi
                      , iv_name           =>  cv_msg_xxcoi1_00003
                      , iv_token_name1    =>  cv_tkn_xxcoi1_00003_1
                      , iv_token_value1   =>  cv_profile_dire_out_hht
                    );
      lv_errbuf := lv_errmsg;
      RAISE procedure_common_expt;
    END IF;
    --
    -- ===================================
    --  ディレクトリパス取得
    -- ===================================
    BEGIN
      SELECT  ad.directory_path
      INTO    lt_dire_path
      FROM    all_directories     ad
      WHERE   ad.directory_name   =   lv_dire_name
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --  ディレクトリパスが取得できない場合
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_appl_short_name_xxcoi
                        , iv_name           =>  cv_msg_xxcoi1_00029
                        , iv_token_name1    =>  cv_tkn_xxcoi1_00029_1
                        , iv_token_value1   =>  lv_dire_name
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE procedure_common_expt;
    END;
    --
    -- ===================================
    --  ファイル名取得
    -- ===================================
    lv_file_name  :=  fnd_profile.value( cv_profile_factory_hht );
    IF ( lv_file_name IS NULL ) THEN
      --  ディレクトリ名が取得できない場合
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_appl_short_name_xxcoi
                      , iv_name           =>  cv_msg_xxcoi1_00004
                      , iv_token_name1    =>  cv_tkn_xxcoi1_00004_1
                      , iv_token_value1   =>  cv_profile_factory_hht
                    );
      lv_errbuf := lv_errmsg;
      RAISE procedure_common_expt;
    END IF;
    --
    -- ===================================
    --  ファイル名出力
    -- ===================================
    -- メッセージ生成
    gv_out_msg  :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_appl_short_name_xxcoi
                      , iv_name           =>  cv_msg_xxcoi1_00028
                      , iv_token_name1    =>  cv_tkn_xxcoi1_00028_1
                      , iv_token_value1   =>  lt_dire_path || cv_slash || lv_file_name
                    );
    -- メッセージ出力
    FND_FILE.PUT_LINE(
        which   =>  FND_FILE.OUTPUT
      , buff    =>  gv_out_msg
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
        which   =>  FND_FILE.OUTPUT
      , buff    =>  ''
    );
    --
    -- ===================================
    --  ファイル存在チェック
    -- ===================================
    UTL_FILE.FGETATTR(
        location      =>  lv_dire_name
      , filename      =>  lv_file_name
      , fexists       =>  lb_fexists
      , file_length   =>  ln_file_length
      , block_size    =>  ln_block_size
    );
    IF ( lb_fexists ) THEN
      --  同名ファイルが存在する場合
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_appl_short_name_xxcoi
                      , iv_name           =>  cv_msg_xxcoi1_00027
                      , iv_token_name1    =>  cv_tkn_xxcoi1_00027_1
                      , iv_token_value1   =>  lv_file_name
                    );
      lv_errbuf := lv_errmsg;
      RAISE procedure_common_expt;
    END IF;
    --
    -- ===================================
    --  ファイルOPEN
    -- ===================================
    g_file_handle :=  UTL_FILE.FOPEN(
                          location    =>  lv_dire_name
                        , filename    =>  lv_file_name
                        , open_mode   =>  cv_utlfile_open_w
                      );
    --
  EXCEPTION
    WHEN procedure_common_expt THEN
      -- *** ユーザ定義メッセージ出力<共通例外> ****
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
   * Procedure Name   : create_csv
   * Description      : 対象データ抽出からCSV作成 (A-2, A-3, A-4)
   ***********************************************************************************/
  PROCEDURE create_csv(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_csv'; -- プログラム名
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
    ld_disposal_day                 DATE;                       --  処理日
    lv_transfer_date                VARCHAR2(21);               --  送信日時
    lt_secondary_inventory_name     mtl_secondary_inventories.secondary_inventory_name%TYPE;
    lv_csv_line                     VARCHAR2(1500);
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- ===============================
    --  入庫情報一時表抽出 (A-2)
    -- ===============================
    CURSOR  storage_cur
    IS
      SELECT  xsi.base_code                           AS  "BASE_CODE"               --  拠点コード
            , xsi.warehouse_code                      AS  "WAREHOUSE_CODE"          --  倉庫コード
            , xsi.ship_warehouse_code                 AS  "SHIP_WAREHOUSE_CODE"     --  転送先倉庫コード
            , xsi.slip_date                           AS  "SLIP_DATE"               --  伝票日付
            , xsi.parent_item_code                    AS  "PARENT_ITEM_CODE"        --  親品目コード
            , SUM( NVL( xsi.ship_summary_qty, 0 ) )   AS  "SHIP_SUMMARY_QTY"        --  入庫数（出庫数量.総計）
      FROM    xxcoi_storage_information   xsi                                       --  入庫情報一時表
      WHERE   xsi.slip_type                       =   cv_slip_type_10               --  伝票区分：工場入庫
      AND     xsi.slip_date                       >=  ld_disposal_day               --  入庫予定日
      AND     NVL( xsi.store_check_flag, cv_no )  =   cv_no                         --  入庫確認済フラグ：未確認
      AND     xsi.summary_data_flag               =   cv_yes
      GROUP BY
              xsi.base_code
            , xsi.warehouse_code
            , xsi.ship_warehouse_code
            , xsi.slip_date
            , xsi.parent_item_code
      ;
    -- <入庫情報一時表抽出>レコード型
    storage_rec   storage_cur%ROWTYPE;
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    ld_disposal_day   :=  NVL( gd_param_target_date, gd_process_date + 1 );           --  処理日
    lv_transfer_date  :=  TO_CHAR( SYSDATE, 'YYYY/MM/DD HH24:MI:SS' );                --  送信日時
    --
    <<csv_loop>>
    FOR storage_rec IN storage_cur LOOP
      --  対象件数カウント
      gn_target_cnt                 :=  gn_target_cnt + 1;
      lv_errmsg                     :=  NULL;
      lv_csv_line                   :=  NULL;
      lt_secondary_inventory_name   :=  NULL;
      -- ===============================
      --  保管場所導出 (A-3)
      -- ===============================
      BEGIN
        IF ( storage_rec.ship_warehouse_code IS NOT NULL ) THEN
          --  転送先倉庫が設定されている場合
          SELECT  msi.secondary_inventory_name    AS  "SECONDARY_INVENTORY_NAME"    --  保管場所コード
          INTO    lt_secondary_inventory_name                                       --  保管場所マスタ
          FROM    mtl_secondary_inventories     msi
          WHERE   msi.attribute7      =   storage_rec.base_code
          AND     msi.attribute1      =   cv_subinv_type_3        --  預け先
          AND     SUBSTRB( msi.secondary_inventory_name, 6, 5 )   =   storage_rec.ship_warehouse_code
          AND     NVL( msi.disable_date, ld_disposal_day + 1 )    >   ld_disposal_day
          ;
        ELSE
          --  設定されていない場合
          SELECT  msi.secondary_inventory_name    AS  "SECONDARY_INVENTORY_NAME"    --  保管場所コード
          INTO    lt_secondary_inventory_name                                       --  保管場所マスタ
          FROM    mtl_secondary_inventories     msi
          WHERE   msi.attribute7      =   storage_rec.base_code
          AND     msi.attribute1 IN( cv_subinv_type_1, cv_subinv_type_4 )     --  倉庫or専門店
          AND     SUBSTRB( msi.secondary_inventory_name, 6, 2 )   =   storage_rec.warehouse_code
          AND     NVL( msi.disable_date, ld_disposal_day + 1 )    >   ld_disposal_day
          ;
        END IF;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg :=  xxccp_common_pkg.get_msg(
                            iv_application    =>  cv_appl_short_name_xxcoi
                          , iv_name           =>  cv_msg_xxcoi1_10521
                          , iv_token_name1    =>  cv_tkn_xxcoi1_10521_1
                          , iv_token_value1   =>  storage_rec.base_code
                          , iv_token_name2    =>  cv_tkn_xxcoi1_10521_2
                          , iv_token_value2   =>  NVL( storage_rec.ship_warehouse_code, storage_rec.warehouse_code )
                        );
        WHEN TOO_MANY_ROWS THEN
          lv_errmsg :=  xxccp_common_pkg.get_msg(
                            iv_application    =>  cv_appl_short_name_xxcoi
                          , iv_name           =>  cv_msg_xxcoi1_10380
                          , iv_token_name1    =>  cv_tkn_xxcoi1_10380_1
                          , iv_token_value1   =>  storage_rec.base_code
                          , iv_token_name2    =>  cv_tkn_xxcoi1_10380_2
                          , iv_token_value2   =>  NVL( storage_rec.ship_warehouse_code, storage_rec.warehouse_code )
                        );
      END;
      --
      IF ( lv_errmsg IS NOT NULL ) THEN
        --  保管場所取得に失敗した場合、警告メッセージ出力、スキップ件数count
        FND_FILE.PUT_LINE(
            which   =>  FND_FILE.OUTPUT
          , buff    =>  lv_errmsg
        );
        gn_warn_cnt :=  gn_warn_cnt + 1;
        ov_retcode  :=  cv_status_warn;
      ELSE
        --  保管場所が取得された場合、CSVを出力、正常件数count
        -- ===============================
        --  CSV作成 (A-4)
        -- ===============================
        lv_csv_line :=
                            cv_dquot || lt_secondary_inventory_name || cv_dquot     --  保管場所
          ||  cv_comma  ||  TO_CHAR( storage_rec.slip_date, 'YYYYMMDD' )            --  入庫予定日
          ||  cv_comma  ||  cv_dquot || storage_rec.parent_item_code || cv_dquot    --  商品コード
          ||  cv_comma  ||  TO_CHAR( storage_rec.ship_summary_qty )                 --  入庫数
          ||  cv_comma  ||  cv_dquot || lv_transfer_date || cv_dquot                --  連携日
        ;
        -- ===============================
        --  CSV出力 (A-4)
        -- ===============================
        UTL_FILE.PUT_LINE(
            file    =>  g_file_handle
          , buffer  =>  lv_csv_line
        );
        --
        gn_normal_cnt :=  gn_normal_cnt + 1;
      END IF;
    END LOOP  csv_loop;
    --
    --  対象データが存在しない場合、ログを出力
    IF ( gn_target_cnt = 0 ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_appl_short_name_xxcoi
                      , iv_name           =>  cv_msg_xxcoi1_00008
                    );
      FND_FILE.PUT_LINE(
          which   =>  FND_FILE.OUTPUT
        , buff    =>  lv_errmsg
      );
      -- 空行挿入
      FND_FILE.PUT_LINE(
          which   =>  FND_FILE.OUTPUT
        , buff    =>  ''
      );
    ELSIF ( gn_warn_cnt <> 0 ) THEN
      -- 空行挿入
      FND_FILE.PUT_LINE(
          which   =>  FND_FILE.OUTPUT
        , buff    =>  ''
      );
    END IF;
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      --  CURSORがOPENしている場合、CLOSE
      IF ( storage_cur%ISOPEN ) THEN
        CLOSE storage_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF ( storage_cur%ISOPEN ) THEN
        CLOSE storage_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( storage_cur%ISOPEN ) THEN
        CLOSE storage_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( storage_cur%ISOPEN ) THEN
        CLOSE storage_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END create_csv;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
      iv_target_date  IN  VARCHAR2      --  パラメータ：処理対象日
    , ov_errbuf       OUT VARCHAR2      --  エラー・メッセージ           --# 固定 #
    , ov_retcode      OUT VARCHAR2      --  リターン・コード             --# 固定 #
    , ov_errmsg       OUT VARCHAR2      --  ユーザー・エラー・メッセージ --# 固定 #
  ) IS
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
    gn_target_cnt     :=  0;
    gn_normal_cnt     :=  0;
    gn_error_cnt      :=  0;
    gn_warn_cnt       :=  0;
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
        iv_target_date  =>  iv_target_date
      , ov_errbuf       =>  lv_errbuf
      , ov_retcode      =>  lv_retcode
      , ov_errmsg       =>  lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE procedure_common_expt;
    END IF;
    --
    -- ===============================
    -- 対象データ抽出からCSV作成 (A-2, A-3, A-4)
    -- ===============================
    create_csv(
        ov_errbuf       =>  lv_errbuf
      , ov_retcode      =>  lv_retcode
      , ov_errmsg       =>  lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE procedure_common_expt;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      ov_retcode := lv_retcode;
    END IF;
    --
    -- ===============================
    -- ファイルCLOSE (A-5)
    -- ===============================
    UTL_FILE.FCLOSE( file => g_file_handle );
    --
  EXCEPTION
    WHEN procedure_common_expt THEN
      --  ファイルがOPENしている場合、CLOSE
      IF ( UTL_FILE.IS_OPEN( file => g_file_handle ) ) THEN
        UTL_FILE.FCLOSE( file => g_file_handle );
      END IF;
      --  メッセージ、ステータスをmainへ引き渡し
      ov_errmsg     :=  lv_errmsg;
      ov_errbuf     :=  lv_errbuf;
      ov_retcode    :=  lv_retcode;
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      --  ファイルがOPENしている場合、CLOSE
      IF ( UTL_FILE.IS_OPEN( file => g_file_handle ) ) THEN
        UTL_FILE.FCLOSE( file => g_file_handle );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      --  ファイルがOPENしている場合、CLOSE
      IF ( UTL_FILE.IS_OPEN( file => g_file_handle ) ) THEN
        UTL_FILE.FCLOSE( file => g_file_handle );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      --  ファイルがOPENしている場合、CLOSE
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
      errbuf          OUT VARCHAR2        --  エラー・メッセージ  --# 固定 #
    , retcode         OUT VARCHAR2        --  リターン・コード    --# 固定 #
    , iv_target_date  VARCHAR2            --  処理対象日
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
        iv_target_date    =>  iv_target_date  --  パラメータ：処理対象日
      , ov_errbuf         =>  lv_errbuf       --  エラー・メッセージ           --# 固定 #
      , ov_retcode        =>  lv_retcode      --  リターン・コード             --# 固定 #
      , ov_errmsg         =>  lv_errmsg       --  ユーザー・エラー・メッセージ --# 固定 #
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
      gn_error_cnt  :=  gn_error_cnt + 1;
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
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
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
END XXCOI010A06C;
/
