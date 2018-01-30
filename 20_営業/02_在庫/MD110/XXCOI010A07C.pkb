CREATE OR REPLACE PACKAGE BODY XXCOI010A07C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * Package Name     : XXCOI010A07C(body)
 * Description      : 出荷ペースHHT連携
 * MD.050           : 出荷ペースHHT連携 <MD050_COI_010_A07>
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
 *  2018/01/15    1.0   SCSK佐々木       新規作成(E_本稼動_14486)
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
  cv_pkg_name                 CONSTANT VARCHAR2(100)  :=  'XXCOI010A07C';             --  パッケージ名
  cv_appl_short_name_xxcoi    CONSTANT VARCHAR2(10)   :=  'XXCOI';                    --  アプリケーション：XXCOI
  --  メッセージ・トークン
  cv_msg_xxcoi1_00023         CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-00023';         --  コンカレント入力パラメータなしメッセージ
  cv_msg_xxcoi1_00011         CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-00011';         --  業務日付取得エラーメッセージ
  cv_msg_xxcoi1_00003         CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-00003';         --  ディレクトリ名取得エラーメッセージ
  cv_msg_xxcoi1_00029         CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-00029';         --  ディレクトリフルパス取得エラーメッセージ
  cv_msg_xxcoi1_00004         CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-00004';         --  ファイル名取得エラーメッセージ
  cv_msg_xxcoi1_00028         CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-00028';         --  ファイル名出力メッセージ
  cv_msg_xxcoi1_00027         CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-00027';         --  ファイル存在チェックエラー
  cv_msg_xxcoi1_00008         CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-00008';         --  対象データ無しメッセージ
  cv_msg_xxcoi1_00005         CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-00005';         --  在庫組織コード取得エラー
  cv_msg_xxcoi1_00006         CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-00006';         --  在庫組織ID取得エラー
  cv_msg_xxcoi1_00032         CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-00032';         --  プロファイル値取得エラー
  cv_msg_xxcoi1_10736         CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-10736';         --  出荷ペース対象抽出期間（日数）設定値不正
  cv_tkn_xxcoi1_10316_1       CONSTANT VARCHAR2(30)   :=  'P_DATE';                   --  APP-XXCOI1-10316用TOKEN
  cv_tkn_xxcoi1_00003_1       CONSTANT VARCHAR2(30)   :=  'PRO_TOK';                  --  APP-XXCOI1-00003用TOKEN
  cv_tkn_xxcoi1_00029_1       CONSTANT VARCHAR2(30)   :=  'DIR_TOK';                  --  APP-XXCOI1-00029用TOKEN
  cv_tkn_xxcoi1_00004_1       CONSTANT VARCHAR2(30)   :=  'PRO_TOK';                  --  APP-XXCOI1-00004用TOKEN
  cv_tkn_xxcoi1_00028_1       CONSTANT VARCHAR2(30)   :=  'FILE_NAME';                --  APP-XXCOI1-00028用TOKEN
  cv_tkn_xxcoi1_00027_1       CONSTANT VARCHAR2(30)   :=  'FILE_NAME';                --  APP-XXCOI1-00027用TOKEN
  cv_tkn_xxcoi1_00005_1       CONSTANT VARCHAR2(30)   :=  'PRO_TOK';                  --  APP-XXCOI1-00005用TOKEN
  cv_tkn_xxcoi1_00006_1       CONSTANT VARCHAR2(30)   :=  'ORG_CODE_TOK';             --  APP-XXCOI1-00006用TOKEN
  cv_tkn_xxcoi1_00032_1       CONSTANT VARCHAR2(30)   :=  'PRO_TOK';                  --  APP-XXCOI1-00032用TOKEN
  --  プロファイル
  cv_profile_dire_out_hht     CONSTANT VARCHAR2(30)   :=  'XXCOI1_DIRE_OUT_HHT';      --  XXCOI:HHT_OUTBOUND格納ディレクトリパス
  cv_profile_shippace_hht     CONSTANT VARCHAR2(30)   :=  'XXCOI1_FILE_SHIPPACEHHT';  --  XXCOI:工場入庫情報HHT連携ファイル名
  cv_profile_org_code         CONSTANT VARCHAR2(30)   :=  'XXCOI1_ORGANIZATION_CODE'; --  XXCOI:在庫組織コード
  cv_profile_pace_term        CONSTANT VARCHAR2(30)   :=  'XXCOI1_SHIP_PACE_TERM';    --  XXCOI:出荷ペース対象期間 
  --
  cv_subinv_type_1            CONSTANT VARCHAR2(1)    :=  '1';                        --  保管場所区分 1:倉庫
  cv_subinv_type_2            CONSTANT VARCHAR2(1)    :=  '2';                        --  保管場所区分 2:営業車
  cv_slash                    CONSTANT VARCHAR2(1)    :=  '/';
  cv_comma                    CONSTANT VARCHAR2(1)    :=  ',';
  cv_dquot                    CONSTANT VARCHAR2(1)    :=  '"';
  cv_utlfile_open_w           CONSTANT VARCHAR2(1)    :=  'w';                        --  オープンモード w:書き込み
  cv_calendar_desc            CONSTANT bom_calendars.description%TYPE :=  '伊藤園営業稼働カレンダ';
                                                                                      --  カレンダ適用
  cn_roundup_rank             CONSTANT NUMBER         :=  3;                          --  小数切り上げの位
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_process_date             DATE;                                                 --  業務日付
  g_file_handle               UTL_FILE.FILE_TYPE;                                   --  ファイルハンドル
  gt_organization_code        mtl_parameters.organization_code%TYPE;                --  組織コード
  gt_organization_id          mtl_parameters.organization_id%TYPE;                  --  組織ID
  gn_ship_pace_term           NUMBER;                                               --  出荷ペース対象期間
  gn_work_day_count           NUMBER;                                               --  稼働日日数
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      ov_errbuf         OUT VARCHAR2      --  エラー・メッセージ           --# 固定 #
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
    lv_dire_name        VARCHAR2(50);                             --  ディレクトリ名
    lt_dire_path        all_directories.directory_path%TYPE;      --  ディレクトリパス
    lv_file_name        VARCHAR2(50);                             --  ファイル名
    lb_fexists          BOOLEAN;                                  --  ファイル存在チェック結果
    ln_file_length      NUMBER;                                   --  ファイルの長さの変数
    ln_block_size       NUMBER;                                   --  ブロックサイズの変数
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
    lv_dire_name        :=  NULL;           --  ディレクトリ名
    lt_dire_path        :=  NULL;           --  ディレクトリパス
    lv_file_name        :=  NULL;           --  ファイル名
    lb_fexists          :=  FALSE;          --  ファイル存在チェック結果
    ln_file_length      :=  NULL;           --  ファイルの長さの変数
    ln_block_size       :=  NULL;           --  ブロックサイズの変数
    --
    -- ===================================
    --  コンカレント入力パラメータ出力
    -- ===================================
    gv_out_msg  :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_appl_short_name_xxcoi
                      , iv_name           =>  cv_msg_xxcoi1_00023
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
    --  組織コード/組織ID取得
    -- ===================================
    gt_organization_code  :=  fnd_profile.value( cv_profile_org_code );
    IF ( gt_organization_code IS NULL ) THEN
      --  組織コードが取得できない場合
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_appl_short_name_xxcoi
                      , iv_name           =>  cv_msg_xxcoi1_00005
                      , iv_token_name1    =>  cv_tkn_xxcoi1_00005_1
                      , iv_token_value1   =>  cv_profile_org_code
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE procedure_common_expt;
    END IF;
    --
    gt_organization_id  :=  xxcoi_common_pkg.get_organization_id( gt_organization_code );
    IF ( gt_organization_id IS NULL ) THEN
      --  組織IDが取得できない場合
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_appl_short_name_xxcoi
                      , iv_name           =>  cv_msg_xxcoi1_00006
                      , iv_token_name1    =>  cv_tkn_xxcoi1_00006_1
                      , iv_token_value1   =>  gt_organization_code
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
    lv_file_name  :=  fnd_profile.value( cv_profile_shippace_hht );
    IF ( lv_file_name IS NULL ) THEN
      --  ファイル名が取得できない場合
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_appl_short_name_xxcoi
                      , iv_name           =>  cv_msg_xxcoi1_00004
                      , iv_token_name1    =>  cv_tkn_xxcoi1_00004_1
                      , iv_token_value1   =>  cv_profile_shippace_hht
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
    -- ===================================
    --  出荷ペース対象抽出期間（日数）取得
    -- ===================================
    gn_ship_pace_term :=  TO_NUMBER( fnd_profile.value( cv_profile_pace_term ) );
    IF ( gn_ship_pace_term IS NULL ) THEN
      --  出荷ペース対象抽出期間（日数）が取得できない場合
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_appl_short_name_xxcoi
                      , iv_name           =>  cv_msg_xxcoi1_00032
                      , iv_token_name1    =>  cv_tkn_xxcoi1_00032_1
                      , iv_token_value1   =>  cv_profile_pace_term
                    );
      lv_errbuf := lv_errmsg;
      RAISE procedure_common_expt;
    END IF;
    --
    IF ( gn_ship_pace_term < 0 ) THEN
      --  出荷ペース対象抽出期間（日数）が 0 より小さい場合
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_appl_short_name_xxcoi
                      , iv_name           =>  cv_msg_xxcoi1_10736
                    );
      lv_errbuf := lv_errmsg;
      RAISE procedure_common_expt;
    END IF;
    --
    -- ===================================
    --  稼働日日数取得
    -- ===================================
    SELECT  COUNT(1)
    INTO    gn_work_day_count
    FROM    bom_calendars         bc
          , bom_calendar_dates    bcd
    WHERE   bc.description        =   cv_calendar_desc
    AND     bc.calendar_code      =   bcd.calendar_code
    AND     bcd.seq_num IS NOT NULL
    AND     bcd.calendar_date     >   gd_process_date - gn_ship_pace_term
    AND     bcd.calendar_date     <=  gd_process_date
    ;
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
    lv_csv_line                     VARCHAR2(1500);               --  CSVデータ
    lv_transfer_date                VARCHAR2(21);                 --  送信日時
    ln_ship_pace                    NUMBER;                       --  出荷ペース
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- ===============================
    --  月次在庫受払表（日次）抽出 (A-2)
    -- ===============================
    CURSOR  ship_pace_cur
    IS
      SELECT  subq.subinventory_code          AS  "SUBINVENTORY_CODE"                       --  保管場所コード
            , msib.segment1                   AS  "ITEM_NUMBER"                             --  品目コード
            , subq.ship_quantity_total        AS  "SHIP_QUANTITY_TOTAL"                     --  出荷総数
      FROM    (
                SELECT  xird.subinventory_code        AS  "SUBINVENTORY_CODE"               --  保管場所コード
                      , xird.inventory_item_id        AS  "INVENTORY_ITEM_ID"               --  品目ID
                      , xird.organization_id          AS  "ORGANIZATION_ID"                 --  組織ID
                      , SUM(  xird.sales_shipped                --  売上出庫
                            + xird.truck_ship                   --  営業車へ出庫
                            + xird.others_ship                  --  入出庫＿その他出庫
                            + xird.goods_transfer_old           --  商品振替（旧商品）
                            + xird.customer_sample_ship         --  顧客見本出庫
                            + xird.customer_support_ss          --  顧客協賛見本出庫
                            + xird.vd_supplement_ship           --  消化VD補充出庫
                        )                             AS  "SHIP_QUANTITY_TOTAL"             --  出荷総数
                FROM    xxcoi_inv_reception_daily   xird                                    --  月次在庫受払表（日次）
                WHERE   xird.subinventory_type IN( cv_subinv_type_1, cv_subinv_type_2 )     --  倉庫or営業員
                AND     xird.organization_id    =   gt_organization_id
                AND     xird.practice_date      >   gd_process_date - gn_ship_pace_term
                GROUP BY  xird.subinventory_code
                        , xird.inventory_item_id
                        , xird.organization_id
              )                     subq
            , mtl_system_items_b    msib
      WHERE   subq.inventory_item_id    =   msib.inventory_item_id
      AND     subq.organization_id      =   msib.organization_id
      ORDER BY  subq.subinventory_code
              , msib.segment1
    ;
    -- <月次在庫受払表（日次）抽出>レコード型
    ship_pace_rec     ship_pace_cur%ROWTYPE;
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    lv_transfer_date  :=  TO_CHAR( SYSDATE, 'YYYY/MM/DD HH24:MI:SS' );            --  送信日時
    --
    <<csv_loop>>
    FOR ship_pace_rec IN ship_pace_cur LOOP
      --  対象件数カウント
      gn_target_cnt :=  gn_target_cnt + 1;
      lv_errmsg     :=  NULL;
      lv_csv_line   :=  NULL;
      ln_ship_pace  :=  NULL;
      -- ===============================
      --  出荷ペース算出 (A-3)
      -- ===============================
      --  期間内の総数量 / 稼働日日数 （稼働日１日あたりの平均出荷数）
      ln_ship_pace  :=  ship_pace_rec.ship_quantity_total / gn_work_day_count;
      --
      --  切上げ処理(小数 第cn_roundup_rank位 で切上げ)
      IF ( TRUNC( ln_ship_pace, cn_roundup_rank ) = TRUNC( ln_ship_pace, cn_roundup_rank-1 ) ) THEN
        --  整数、または、切上げ対象の位が0の場合
        ln_ship_pace  :=  TRUNC( ln_ship_pace, cn_roundup_rank-1 );
      ELSE
        --  切上げ対象の位が0以外の場合
        ln_ship_pace  :=  TRUNC( ln_ship_pace, cn_roundup_rank-1 ) + POWER( 0.1, cn_roundup_rank-1 );
      END IF;
      --
      -- ===============================
      --  CSV作成 (A-4)
      -- ===============================
      lv_csv_line :=
                          cv_dquot || ship_pace_rec.subinventory_code || cv_dquot     --  保管場所
        ||  cv_comma  ||  cv_dquot || ship_pace_rec.item_number       || cv_dquot     --  商品コード
        ||  cv_comma  ||  TO_CHAR( ln_ship_pace )                                     --  出荷ペース
        ||  cv_comma  ||  cv_dquot || lv_transfer_date                || cv_dquot     --  送信日時
      ;
      UTL_FILE.PUT_LINE(
          file    =>  g_file_handle
        , buffer  =>  lv_csv_line
      );
      --
      gn_normal_cnt :=  gn_normal_cnt + 1;
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
      IF ( ship_pace_cur%ISOPEN ) THEN
        CLOSE ship_pace_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF ( ship_pace_cur%ISOPEN ) THEN
        CLOSE ship_pace_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( ship_pace_cur%ISOPEN ) THEN
        CLOSE ship_pace_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( ship_pace_cur%ISOPEN ) THEN
        CLOSE ship_pace_cur;
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
      ov_errbuf       OUT VARCHAR2      --  エラー・メッセージ           --# 固定 #
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
    gd_process_date   :=  NULL;
    g_file_handle     :=  NULL;
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
        ov_errbuf       =>  lv_errbuf
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
    END IF;
    --
    -- ===============================
    -- ファイルCLOSE (A-5)
    -- ===============================
    UTL_FILE.FCLOSE( file => g_file_handle );
    --
  EXCEPTION
    WHEN procedure_common_expt THEN
      --  メッセージ、ステータスをmainへ引き渡し
      ov_errmsg     :=  lv_errmsg;
      ov_errbuf     :=  lv_errbuf;
      ov_retcode    :=  lv_retcode;
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
      errbuf          OUT VARCHAR2        --  エラー・メッセージ  --# 固定 #
    , retcode         OUT VARCHAR2        --  リターン・コード    --# 固定 #
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
        ov_errbuf         =>  lv_errbuf       --  エラー・メッセージ           --# 固定 #
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
END XXCOI010A07C;
/
