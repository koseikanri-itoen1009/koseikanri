CREATE OR REPLACE PACKAGE BODY APPS.XXCFO016A04C AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 *
 * Package Name     : XXCFO016A04C(body)
 * Description      : 事業所マスタ連携データ抽出_EBSコンカレント
 * MD.050           : T_MD050_CFO_016_A04_事業所マスタ連携データ抽出_EBSコンカレント
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                    初期処理(A-1)
 *  output_office           連携データ抽出(A-2)
 *                          I/Fファイル出力(A-3)
 *  upd_oipm                管理テーブル登録更新(A-4)
 *  submain                 メイン処理プロシージャ
 *  main                    コンカレント実行ファイル登録プロシージャ
 *                          終了処理(A-5)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2022-11-28    1.0   N.Fujiwara       新規作成
 *  2022-12-07    1.1   N.Fujiwara       E106,E109～E111対応
 *  2022-12-14    1.2   N.Fujiwara       E112,E116対応
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  -- ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- 異常:2
  -- WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         -- CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    -- PROGRAM_UPDATE_DATE
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg         VARCHAR2(2000);
  gv_sep_msg         VARCHAR2(2000);
  gv_exec_user       VARCHAR2(100);
  gv_conc_name       VARCHAR2(30);
  gv_conc_status     VARCHAR2(30);
  gn_target_cnt      NUMBER;                    -- 対象件数
  gn_normal_cnt      NUMBER;                    -- 正常件数
  gn_error_cnt       NUMBER;                    -- エラー件数
  gn_warn_cnt        NUMBER;                    -- スキップ件数
--
--################################  固定部 END   ##################################
--
--##########################  固定共通例外宣言部 START  ###########################
--
  -- *** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  -- *** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  -- *** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name           CONSTANT VARCHAR2(100) := 'XXCFO016A04'; -- パッケージ名
  -- アプリケーション短縮名
  cv_msg_kbn_cfo        CONSTANT VARCHAR2(5)   := 'XXCFO';
  cv_msg_kbn_coi        CONSTANT VARCHAR2(5)   := 'XXCOI';
  -- プロファイル
  cv_data_filedir       CONSTANT VARCHAR2(50)  := 'XXCFO1_OIC_OUT_FILE_DIR';     -- OIC連携データファイル格納ディレクトリ名
  cv_filename           CONSTANT VARCHAR2(50)  := 'XXCFO1_OIC_LOC_MST_OUT_FILE'; -- 事業所マスタ連携データファイル名
  -- メッセージ
  cv_msg_coi_00029      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00029'; -- ディレクトリフルパス取得エラーメッセージ
  cv_msg_cfo_00001      CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00001'; -- プロファイル名取得エラーメッセージ
  cv_msg_cfo_00015      CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00015'; -- 業務日付取得エラーメッセージ
  cv_msg_cfo_00019      CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00019'; -- ロックエラーメッセージ
  cv_msg_cfo_00020      CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00020'; -- 更新エラーメッセージ
  cv_msg_cfo_00024      CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00024'; -- 登録エラーメッセージ
  cv_msg_cfo_00027      CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00027'; -- ファイル存在エラー
  cv_msg_cfo_00029      CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00029'; -- ファイルオープンエラーメッセージ
  cv_msg_cfo_00030      CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00030'; -- ファイル書き込みエラー
  cv_msg_cfo_60001      CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-60001'; -- パラメータ出力メッセージ
  cv_msg_cfo_60002      CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-60002'; -- ファイル名出力メッセージ
  cv_msg_cfo_60003      CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-60003'; -- 処理日時出力メッセージ
  cv_msg_cfo_60004      CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-60004'; -- 検索対象・件数メッセージ
  cv_msg_cfo_60005      CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-60005'; -- ファイル出力対象・件数メッセージ
  cv_msg_cfo_60006      CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-60006'; -- "業務日付（リカバリ用）"
  cv_msg_cfo_60007      CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-60007'; -- "事業所マスタ情報"
  cv_msg_cfo_60008      CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-60008'; -- "OIC連携処理管理テーブル"
  -- トークンコード
  cv_tkn_param_name     CONSTANT VARCHAR2(20)  := 'PARAM_NAME'; -- パラメータ名
  cv_tkn_param_val      CONSTANT VARCHAR2(20)  := 'PARAM_VAL';  -- パラメータ値
  cv_tkn_prof_name      CONSTANT VARCHAR2(20)  := 'PROF_NAME';  -- プロファイル名
  cv_tkn_dir_tok        CONSTANT VARCHAR2(20)  := 'DIR_TOK';    -- ディレクトリ名
  cv_tkn_file_name      CONSTANT VARCHAR2(20)  := 'FILE_NAME';  -- ディレクトリパス付きファイル名
  cv_tkn_table          CONSTANT VARCHAR2(20)  := 'TABLE';      -- テーブル
  cv_tkn_date1          CONSTANT VARCHAR2(20)  := 'DATE1';      -- 前回処理日時
  cv_tkn_date2          CONSTANT VARCHAR2(20)  := 'DATE2';      -- 今回処理日時
  cv_tkn_target         CONSTANT VARCHAR2(20)  := 'TARGET';     -- 検索対象
  cv_tkn_count          CONSTANT VARCHAR2(20)  := 'COUNT';      -- 検索件数
  cv_tkn_err_msg        CONSTANT VARCHAR2(20)  := 'ERRMSG';    -- エラー内容
  -- 日付フォーマット
  cv_dateformat_ymdhms  CONSTANT VARCHAR2(30)  := 'YYYY/MM/DD HH24:MI:SS'; -- 連携日付フォーマット
  -- 固定値
  cv_slash              CONSTANT VARCHAR2(1)   := '/'; -- スラッシュ
  cv_delimit            CONSTANT VARCHAR2(1)   := '|'; -- パイプ
  -- ファイル出力
  cv_file_type_out      CONSTANT VARCHAR2(30)  := 'OUTPUT'; -- メッセージ出力
  cv_file_type_log      CONSTANT VARCHAR2(30)  := 'LOG';    -- ログ出力
  cv_open_mode_w        CONSTANT VARCHAR2(30)  := 'W';      -- 書き込みモード
  cn_max_linesize       CONSTANT BINARY_INTEGER := 32767;   -- ファイルサイズ
-- Ver1.2 Add Start
  --抽出条件
  cv_loc_code_1         CONSTANT VARCHAR2(30)  := 'ITOE_LOC'; -- 初期セットアップ登録済データ1
  cv_loc_code_2         CONSTANT VARCHAR2(30)  := 'X999';     -- 初期セットアップ登録済データ2
  --データ抽出・出力固定値
  cv_setcode            CONSTANT VARCHAR2(100) := 'ITO_SALES_DSET01'; -- 出荷先事業所セット・コード、セットコード
-- Ver1.2 Add End
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_process_date    DATE;                                                              -- 業務日付
  gd_coop_date       DATE;                                                              -- 連携日付
  gt_pre_prodate     xxccp_oic_if_process_mng.pre_process_date%TYPE DEFAULT NULL;       -- 前回処理日時
  gd_prodate         DATE DEFAULT NULL;                                                 -- 今回処理日時
  gf_file_hand       UTL_FILE.FILE_TYPE;                                                -- ファイル・ハンドルの宣言
  gt_ccrt_proname    fnd_concurrent_programs.concurrent_program_name%TYPE DEFAULT NULL; -- コンカレントプログラム名
  -- プロファイル用
  gv_dir_name        VARCHAR2(100) DEFAULT NULL; -- OIC連携データファイル格納ディレクトリ名
  gv_file_name       VARCHAR2(100) DEFAULT NULL; -- 事業所マスタ連携データファイル名
--
  --===============================================================
  -- グローバルカーソル
  --===============================================================
  -- 対象データ抽出用カーソル
  CURSOR  get_office_cur
  IS
    SELECT    hl.attribute3           AS hl_purchasing_flag     -- 購買担当フラグ
            , hl.attribute4           AS hl_shipping_flag       -- 出荷担当フラグ
            , hl.attribute5           AS hl_rsp_name1           -- 担当職責1
            , hl.attribute6           AS hl_rsp_name2           -- 担当職責2
            , hl.attribute7           AS hl_rsp_name3           -- 担当職責3
            , hl.attribute8           AS hl_rsp_name4           -- 担当職責4
            , hl.attribute9           AS hl_rsp_name5           -- 担当職責5
            , hl.attribute10          AS hl_rsp_name6           -- 担当職責6
            , hl.attribute11          AS hl_rsp_name7           -- 担当職責7
            , hl.attribute12          AS hl_rsp_name8           -- 担当職責8
            , hl.attribute13          AS hl_rsp_name9           -- 担当職責9
            , hl.attribute14          AS hl_rsp_name10          -- 担当職責10
            , hl.attribute17          AS hl_locations_name      -- 親事業所ID
            , hl.attribute18          AS hl_include_exclude     -- 他拠点出荷依頼作成可否区分
            , hl.attribute20          AS hl_area                -- 地区名
            , hl.ship_to_site_flag    AS hl_ship_to_site_flag   -- 出荷先フラグ
            , hl.receiving_site_flag  AS hl_receiving_site_flag -- 受入先フラグ
            , hl.bill_to_site_flag    AS hl_bill_to_site_flag   -- 請求先フラグ
            , hl.office_site_flag     AS hl_office_site_flag    -- 社内先フラグ
            , hl.location_code        AS hl_location_code       -- 事業所コード
            , hl.description          AS hl_description         -- 摘要
            , xla.location_name        AS xla_location_name      -- 正式名
            , xla.location_short_name  AS xla_location_shortname -- 略称
            , xla.location_name_alt    AS xla_location_name_alt  -- カナ名
            , xla.zip                  AS xla_zip                -- 郵便番号
            , xla.address_line1        AS xla_address            -- 住所
            , xla.phone                AS xla_phone              -- 電話番号
            , xla.fax                  AS xla_fax                -- FAX番号
            , xla.division_code        AS xla_division_code      -- 本部コード
            -- 有効ステータス
            , CASE
                WHEN  hl.inactive_date <= gd_coop_date THEN 'I'
                  ELSE 'A'
                END AS active_status
-- Ver1.1 Add Start
            -- NVL変換値
            , CASE
                WHEN gt_pre_prodate IS NULL THEN NULL
                WHEN hl.creation_date > gt_pre_prodate THEN NULL
                  ELSE '#NULL'
                END AS nvl_conversion
-- Ver1.1 Add End
-- Ver1.2 Add Start
            , hl.location_id          AS hl_location_id         -- ロケーションID
            --出荷先事業所コード
            , CASE
                WHEN hl.ship_to_site_flag = 'N' THEN 
                  ( SELECT hl2.location_code AS hl2_location_code
                    FROM   hr_locations hl2
                    WHERE  hl.ship_to_location_id = hl2.location_id
                   )
                  ELSE NULL
                END AS ship_to_loc_code
            --出荷先事業所セット・コード
            , CASE
                WHEN hl.ship_to_site_flag = 'N' THEN cv_setcode
                  ELSE NULL
                END AS ship_to_loc_setcode
-- Ver1.2 Add End
    FROM      hr_locations        hl  --事業所マスタ
            , xxcmn_locations_all xla --事業所アドオンマスタ
    WHERE
-- Ver1.2 Add Start
              hl.location_code NOT IN ( cv_loc_code_1,cv_loc_code_2 )
-- Ver1.2 Add End
      AND     hl.location_id = xla.location_id (+)
      AND     xla.start_date_active (+) <= gd_coop_date
      AND     NVL(xla.end_date_active (+) , gd_coop_date ) >= gd_coop_date
      AND     (
                (gt_pre_prodate IS NULL)
                OR
                (hl.last_update_date > gt_pre_prodate )
                OR
                (hl.inactive_date = gd_coop_date )
                OR
                (EXISTS (SELECT 1
                         FROM   xxcmn_locations_all xla2
                         WHERE  xla2.location_id = hl.location_id
                           AND  (
                                  (xla2.last_update_date > gt_pre_prodate )
                                  OR
                                  (xla2.start_date_active = gd_coop_date )
                                )
                        )
                )
              )
    ORDER BY  hl.location_code
    ;
--
  -- ===============================
  -- グローバルレコード型
  -- ===============================
  -- 事業所マスタ格納用
  g_office_rec    get_office_cur%ROWTYPE;
--
  -- ===============================
  -- グローバル例外
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      iv_proc_date_for_recovery          IN  VARCHAR2  -- 1.業務日付(リカバリ用)
    , ov_errbuf                          OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
    , ov_retcode                         OUT VARCHAR2  -- リターン・コード             --# 固定 #
    , ov_errmsg                          OUT VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
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
--
    -- *** ローカル変数 ***
    lv_msg            VARCHAR2(300)   DEFAULT NULL;                     -- メッセージ出力用
    lv_msg_preprodate VARCHAR2(100)   DEFAULT NULL;                     -- メッセージ出力用前回処理日時
    lv_msg_prodate    VARCHAR2(100)   DEFAULT NULL;                     -- メッセージ出力用今回処理日時
    lv_full_name      VARCHAR2(200)   DEFAULT NULL;                     -- ディレクトリパス＋ファイル名連結値
    lt_dir_path       all_directories.directory_path%TYPE DEFAULT NULL; -- ディレクトリパス
    -- ファイル存在チェック用
    lb_exists         BOOLEAN         DEFAULT NULL;  -- ファイル存在判定用変数
    ln_file_length    NUMBER          DEFAULT NULL;  -- ファイルの長さ
    ln_block_size     BINARY_INTEGER  DEFAULT NULL;  -- ブロックサイズ
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --==============================================================
    -- パラメータ出力
    --==============================================================
    lv_msg := xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo            -- 'XXCFO'
                                       , cv_msg_cfo_60001          -- パラメータ出力メッセージ
                                       , cv_tkn_param_name         -- 'PARAM_NAME'
                                       , cv_msg_cfo_60006          -- '業務日付（リカバリ用）'
                                       , cv_tkn_param_val          -- 'PARAM_VAL'
                                       , iv_proc_date_for_recovery -- 業務日付（リカバリ用）
                                      );
    --メッセージ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msg
    );
    --ログ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => lv_msg
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
    --==================================
    -- プロファイルの取得
    --==================================
    -- OIC連携データファイル格納ディレクトリ名
    gv_dir_name := FND_PROFILE.VALUE( cv_data_filedir );
    IF ( gv_dir_name IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo   -- 'XXCFO'
                                                    , cv_msg_cfo_00001 -- プロファイル名取得エラー
                                                    , cv_tkn_prof_name -- 'PROF_NAME'
                                                    , cv_data_filedir  -- 'XXCFO1_OIC_OUT_FILE_DIR'
                                                   )
                           , 1
                           , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    -- 事業所マスタ連携データファイル名
    gv_file_name := FND_PROFILE.VALUE( cv_filename );
    IF ( gv_file_name IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo   -- 'XXCFO'
                                                    , cv_msg_cfo_00001 -- プロファイル名取得エラー
                                                    , cv_tkn_prof_name -- 'PROF_NAME'
                                                    , cv_filename      -- 'XXCFO1_OIC_LOC_MST_OUT_FILE'
                                                   )
                           , 1
                           , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --==================================
    -- ディレクトリパス取得
    --==================================
    BEGIN
      SELECT    RTRIM(ad.directory_path, cv_slash) AS directory_path
      INTO      lt_dir_path
      FROM      all_directories   ad
      WHERE     ad.directory_name = gv_dir_name;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_coi   -- 'XXCOI'
                                                      , cv_msg_coi_00029 -- ディレクトリフルパス取得エラー
                                                      , cv_tkn_dir_tok   -- 'DIR_TOK'
                                                      , gv_dir_name      -- OIC連携データファイル格納ディレクトリ名
                                                     )
                             , 1
                             , 5000);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --==================================
    -- 業務日付取得
    --==================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo   -- 'XXCFO'
                                                    , cv_msg_cfo_00015 -- 業務日付取得エラー
                                                   )
                           , 1
                           , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- 連携日付設定
    --==================================
    IF ( iv_proc_date_for_recovery IS NOT NULL ) THEN
      gd_coop_date := TO_DATE( iv_proc_date_for_recovery , cv_dateformat_ymdhms ) + 1;
    ELSE
      gd_coop_date := gd_process_date + 1;
    END IF; 
--
    --==================================
    -- ファイル名出力
    --==================================
    lv_full_name := lt_dir_path || cv_slash || gv_file_name;
    --
    lv_msg := xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo   -- 'XXCFO'
                                       , cv_msg_cfo_60002 -- ファイル名出力メッセージ
                                       , cv_tkn_file_name -- 'FILE_NAME'
                                       , lv_full_name     -- ディレクトリパスとファイル名の連結文字
                                      );
    -- メッセージ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msg
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
    --==================================
    -- 同一ファイル存在チェック
    --==================================
    -- ファイルの存在チェック
    UTL_FILE.FGETATTR( 
        location     =>  gv_dir_name
      , filename     =>  gv_file_name
      , fexists      =>  lb_exists
      , file_length  =>  ln_file_length
      , block_size   =>  ln_block_size
    );
    -- 同一ファイルが存在した場合はエラー
    IF ( lb_exists = TRUE ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo   -- 'XXCFO'
                                                    , cv_msg_cfo_00027 -- 同一ファイルあり
                                                   )
                           , 1
                           , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- 前回処理日時取得
    --==============================================================
    BEGIN
      SELECT   fcp.concurrent_program_name  AS fcp_ccrt_pronam  -- コンカレントプログラム名
             , oipm.pre_process_date        AS oipm_pre_prodate -- 前回処理日時
      INTO     gt_ccrt_proname                                  -- コンカレントプログラム名
             , gt_pre_prodate                                   -- 前回処理日時
      FROM     fnd_concurrent_programs     fcp                  -- コンカレントプログラム
             , xxccp_oic_if_process_mng    oipm                 -- OIC連携処理管理テーブル
      WHERE    fcp.concurrent_program_id = cn_program_id
        AND    fcp.concurrent_program_name = oipm.program_name (+)
      FOR UPDATE OF oipm.pre_process_date NOWAIT
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo   -- 'XXCFO'
                                                      , cv_msg_cfo_00019 -- ロックエラーメッセージ
                                                      , cv_tkn_table     -- 'TABLE'
                                                      , cv_msg_cfo_60008 -- 'OIC連携管理テーブル'
                                                     )
                             , 1
                             , 5000);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    -- 今回処理日時取得
    --==============================================================
    gd_prodate := SYSDATE;
--
    --==============================================================
    -- 前回・今回処理日時出力
    --==============================================================
    --日付書式変換
    lv_msg_preprodate := TO_CHAR(gt_pre_prodate ,cv_dateformat_ymdhms);
    lv_msg_prodate    := TO_CHAR(gd_prodate     ,cv_dateformat_ymdhms);
    --
    lv_msg := xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo    -- 'XXCFO'
                                       , cv_msg_cfo_60003  -- 処理日時出力メッセージ
                                       , cv_tkn_date1      -- 'DATE1'
                                       , lv_msg_preprodate -- 前回処理日時
                                       , cv_tkn_date2      -- 'DATE2'
                                       , lv_msg_prodate    -- 今回処理日時
                                      );
     -- メッセージに出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --==============================================================
    -- ファイルオープン
    --==============================================================
    BEGIN
      gf_file_hand := UTL_FILE.FOPEN(  location     => gv_dir_name
                                     , filename     => gv_file_name
                                     , open_mode    => cv_open_mode_w
                                     , max_linesize => cn_max_linesize
                                    );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo   -- 'XXCFO'
                                                      , cv_msg_cfo_00029 -- ファイルオープンエラー
                                                     )
                             , 1
                             , 5000);
        lv_errbuf  := lv_errmsg || SQLERRM;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;                                                  -- # 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            -- # 任意 #
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
   * Procedure Name   : output_office
   * Description      : 連携データ抽出(A-2)
   *                    I/Fファイル出力(A-3)
   ***********************************************************************************/
  PROCEDURE output_office(
      ov_errbuf      OUT VARCHAR2  -- エラー・メッセージ                  -- # 固定 #
    , ov_retcode     OUT VARCHAR2  -- リターン・コード                    -- # 固定 #
    , ov_errmsg      OUT VARCHAR2) -- ユーザー・エラー・メッセージ        -- # 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_office'; -- プログラム名
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
    -- ヘッダ用
    cv_h_metadata             CONSTANT VARCHAR2(100) := 'METADATA';                                             -- METADATA
    cv_h_location             CONSTANT VARCHAR2(100) := 'Location';                                             -- Location
    cv_h_flex_pld             CONSTANT VARCHAR2(100) := 'FLEX:PER_LOCATIONS_DF';                                -- FLEX:PER_LOCATIONS_DF
    cv_h_purchasingflag       CONSTANT VARCHAR2(100) := 'purchasingFlag(PER_LOCATIONS_DF=SALES-BU_DEPT)';       -- 購買担当フラグ
    cv_h_shippingflag         CONSTANT VARCHAR2(100) := 'shippingFlag(PER_LOCATIONS_DF=SALES-BU_DEPT)';         -- 出荷担当フラグ
    cv_h_rsp_name1            CONSTANT VARCHAR2(100) := 'responsibilityName1(PER_LOCATIONS_DF=SALES-BU_DEPT)';  -- 担当職責1
    cv_h_rsp_name2            CONSTANT VARCHAR2(100) := 'responsibilityName2(PER_LOCATIONS_DF=SALES-BU_DEPT)';  -- 担当職責2
    cv_h_rsp_name3            CONSTANT VARCHAR2(100) := 'responsibilityName3(PER_LOCATIONS_DF=SALES-BU_DEPT)';  -- 担当職責3
    cv_h_rsp_name4            CONSTANT VARCHAR2(100) := 'responsibilityName4(PER_LOCATIONS_DF=SALES-BU_DEPT)';  -- 担当職責4
    cv_h_rsp_name5            CONSTANT VARCHAR2(100) := 'responsibilityName5(PER_LOCATIONS_DF=SALES-BU_DEPT)';  -- 担当職責5
    cv_h_rsp_name6            CONSTANT VARCHAR2(100) := 'responsibilityName6(PER_LOCATIONS_DF=SALES-BU_DEPT)';  -- 担当職責6
    cv_h_rsp_name7            CONSTANT VARCHAR2(100) := 'responsibilityName7(PER_LOCATIONS_DF=SALES-BU_DEPT)';  -- 担当職責7
    cv_h_rsp_name8            CONSTANT VARCHAR2(100) := 'responsibilityName8(PER_LOCATIONS_DF=SALES-BU_DEPT)';  -- 担当職責8
    cv_h_rsp_name9            CONSTANT VARCHAR2(100) := 'responsibilityName9(PER_LOCATIONS_DF=SALES-BU_DEPT)';  -- 担当職責9
    cv_h_rsp_name10           CONSTANT VARCHAR2(100) := 'responsibilityName10(PER_LOCATIONS_DF=SALES-BU_DEPT)'; -- 担当職責10
    cv_h_locations_name       CONSTANT VARCHAR2(100) := 'locationsName(PER_LOCATIONS_DF=SALES-BU_DEPT)';        -- 親事業所ID
    cv_h_incld_excld          CONSTANT VARCHAR2(100) := 'includeExclude(PER_LOCATIONS_DF=SALES-BU_DEPT)';       -- 他拠点出荷依頼作成可否区分
    cv_h_area                 CONSTANT VARCHAR2(100) := 'area(PER_LOCATIONS_DF=SALES-BU_DEPT)';                 -- 地区名
    cv_h_location_name        CONSTANT VARCHAR2(100) := 'locationName(PER_LOCATIONS_DF=SALES-BU_DEPT)';         -- 正式名
    cv_h_location_shortname   CONSTANT VARCHAR2(100) := 'locationShortName(PER_LOCATIONS_DF=SALES-BU_DEPT)';    -- 略称
    cv_h_location_name_alt    CONSTANT VARCHAR2(100) := 'locationNameAlt(PER_LOCATIONS_DF=SALES-BU_DEPT)';      -- カナ名
    cv_h_zip                  CONSTANT VARCHAR2(100) := 'zip(PER_LOCATIONS_DF=SALES-BU_DEPT)';                  -- 郵便番号
    cv_h_address              CONSTANT VARCHAR2(100) := 'addressLine1(PER_LOCATIONS_DF=SALES-BU_DEPT)';         -- 住所
    cv_h_phone                CONSTANT VARCHAR2(100) := 'phone(PER_LOCATIONS_DF=SALES-BU_DEPT)';                -- 電話番号
    cv_h_fax                  CONSTANT VARCHAR2(100) := 'fax(PER_LOCATIONS_DF=SALES-BU_DEPT)';                  -- FAX番号
    cv_h_division_code        CONSTANT VARCHAR2(100) := 'divisionCode(PER_LOCATIONS_DF=SALES-BU_DEPT)';         -- 本部コード
    cv_h_location_id          CONSTANT VARCHAR2(100) := 'LocationId';                                           -- ロケーション内部ID
    cv_h_setcode              CONSTANT VARCHAR2(100) := 'SetCode';                                              -- セットコード
    cv_h_active_status        CONSTANT VARCHAR2(100) := 'ActiveStatus';                                         -- 有効ステータス
    cv_h_ship_to_site_flag    CONSTANT VARCHAR2(100) := 'ShipToSiteFlag';                                       -- 出荷先フラグ
    cv_h_receiving_site_flag  CONSTANT VARCHAR2(100) := 'ReceivingSiteFlag';                                    -- 受入先フラグ
    cv_h_bill_to_site_flag    CONSTANT VARCHAR2(100) := 'BillToSiteFlag';                                       -- 請求先フラグ
    cv_h_office_site_flag     CONSTANT VARCHAR2(100) := 'OfficeSiteFlag';                                       -- 社内先フラグ
    cv_h_location_code        CONSTANT VARCHAR2(100) := 'LocationCode';                                         -- 事業所コード
    cv_h_location_name_d      CONSTANT VARCHAR2(100) := 'LocationName';                                         -- 摘要
    cv_h_description          CONSTANT VARCHAR2(100) := 'Description';                                          -- 摘要
    cv_h_address_l            CONSTANT VARCHAR2(100) := 'AddressLine1';                                         -- 住所
    cv_h_country              CONSTANT VARCHAR2(100) := 'Country';                                              -- 国
    cv_h_postalcode           CONSTANT VARCHAR2(100) := 'PostalCode';                                           -- 郵便番号
    cv_h_eff_startdate        CONSTANT VARCHAR2(100) := 'EffectiveStartDate';                                   -- 有効開始日
    cv_h_eff_enddate          CONSTANT VARCHAR2(100) := 'EffectiveEndDate';                                     -- 有効終了日
-- Ver1.2 Add Start
    cv_h_src_sys_owner        CONSTANT VARCHAR2(100) := 'SourceSystemOwner';                                    -- ソース・システム所有者
    cv_h_src_sys_id           CONSTANT VARCHAR2(100) := 'SourceSystemId';                                       -- ソース・システムID
    cv_h_ship_to_loc_code     CONSTANT VARCHAR2(100) := 'ShipToLocationCode';                                   -- 出荷先事業所コード
    cv_h_ship_to_loc_setcode  CONSTANT VARCHAR2(100) := 'ShipToLocationSetCode';                                -- 出荷先事業所セット・コード
-- Ver1.2 Add End
    -- I/Fファイル出力用固定値
-- Ver1.1 Mod Start
--  cv_null               CONSTANT VARCHAR2(100) := '#NULL';            -- NULL用
    cv_null               CONSTANT VARCHAR2(100)     DEFAULT NULL;      -- NULL用
    cv_metadata           CONSTANT VARCHAR2(100) := 'MERGE';            -- METADATA
    cv_location           CONSTANT VARCHAR2(100) := 'Location';         -- Location
    cv_flex_locations_df  CONSTANT VARCHAR2(100) := 'SALES-BU_DEPT';    -- FLEX:PER_LOCATIONS_DF
--  cv_location_id        CONSTANT VARCHAR2(100) := '#NULL';            -- ロケーション内部ID
-- Ver1.2 Del Start
--  cv_setcode            CONSTANT VARCHAR2(100) := 'ITO_SALES_DSET01'; -- セットコード
-- Ver1.2 Del End
    cv_country            CONSTANT VARCHAR2(100) := 'JP';               -- 国
    cv_eff_startdate      CONSTANT VARCHAR2(100) := '1900/01/01';       -- 有効開始日
--  cv_eff_enddate        CONSTANT VARCHAR2(100) := '#NULL';            -- 有効終了日
-- Ver1.1 Mod End
-- Ver1.2 Add Start
    cv_src_sys_owner      CONSTANT VARCHAR2(100) := 'EBS';               -- ソース・システム所有者
-- Ver1.2 Add End

--
    -- *** ローカル変数 ***
    lv_msg_prodate     VARCHAR2(3000)   DEFAULT NULL; -- 処理日時出力用メッセージ
    lv_head            VARCHAR2(30000)  DEFAULT NULL; -- ヘッダ書き込み用
    lv_file_data       VARCHAR2(30000)  DEFAULT NULL; -- ファイル書き込み用
-- Ver1.1 Add Start
    lv_nvl_conversion  VARCHAR2(100)    DEFAULT NULL; -- NVL変換値用
-- Ver1.1 Add End
--
    -- *** ローカル・カーソル ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ヘッダ用意
    lv_head := cv_h_metadata;                                     -- METADATA
    lv_head := lv_head || cv_delimit || cv_h_location;            -- Location
    lv_head := lv_head || cv_delimit || cv_h_flex_pld;            -- FLEX:PER_LOCATIONS_DF
    lv_head := lv_head || cv_delimit || cv_h_purchasingflag;      -- 購買担当フラグ
    lv_head := lv_head || cv_delimit || cv_h_shippingflag;        -- 出荷担当フラグ
    lv_head := lv_head || cv_delimit || cv_h_rsp_name1;           -- 担当職責1
    lv_head := lv_head || cv_delimit || cv_h_rsp_name2;           -- 担当職責2
    lv_head := lv_head || cv_delimit || cv_h_rsp_name3;           -- 担当職責3
    lv_head := lv_head || cv_delimit || cv_h_rsp_name4;           -- 担当職責4
    lv_head := lv_head || cv_delimit || cv_h_rsp_name5;           -- 担当職責5
    lv_head := lv_head || cv_delimit || cv_h_rsp_name6;           -- 担当職責6
    lv_head := lv_head || cv_delimit || cv_h_rsp_name7;           -- 担当職責7
    lv_head := lv_head || cv_delimit || cv_h_rsp_name8;           -- 担当職責8
    lv_head := lv_head || cv_delimit || cv_h_rsp_name9;           -- 担当職責9
    lv_head := lv_head || cv_delimit || cv_h_rsp_name10;          -- 担当職責10
    lv_head := lv_head || cv_delimit || cv_h_locations_name;      -- 親事業所ID
    lv_head := lv_head || cv_delimit || cv_h_incld_excld;         -- 他拠点出荷依頼作成可否区分
    lv_head := lv_head || cv_delimit || cv_h_area;                -- 地区名
    lv_head := lv_head || cv_delimit || cv_h_location_name;       -- 正式名
    lv_head := lv_head || cv_delimit || cv_h_location_shortname;  -- 略称
    lv_head := lv_head || cv_delimit || cv_h_location_name_alt;   -- カナ名
    lv_head := lv_head || cv_delimit || cv_h_zip;                 -- 郵便番号
    lv_head := lv_head || cv_delimit || cv_h_address;             -- 住所
    lv_head := lv_head || cv_delimit || cv_h_phone;               -- 電話番号
    lv_head := lv_head || cv_delimit || cv_h_fax;                 -- FAX番号
    lv_head := lv_head || cv_delimit || cv_h_division_code;       -- 本部コード
    lv_head := lv_head || cv_delimit || cv_h_location_id;         -- ロケーション内部ID
    lv_head := lv_head || cv_delimit || cv_h_setcode;             -- セットコード
    lv_head := lv_head || cv_delimit || cv_h_active_status;       -- 有効ステータス
    lv_head := lv_head || cv_delimit || cv_h_ship_to_site_flag;   -- 出荷先フラグ
    lv_head := lv_head || cv_delimit || cv_h_receiving_site_flag; -- 受入先フラグ
    lv_head := lv_head || cv_delimit || cv_h_bill_to_site_flag;   -- 請求先フラグ
    lv_head := lv_head || cv_delimit || cv_h_office_site_flag;    -- 社内先フラグ
    lv_head := lv_head || cv_delimit || cv_h_location_code;       -- 事業所コード
    lv_head := lv_head || cv_delimit || cv_h_location_name_d;     -- 摘要
    lv_head := lv_head || cv_delimit || cv_h_description;         -- 摘要
    lv_head := lv_head || cv_delimit || cv_h_address_l;           -- 住所
    lv_head := lv_head || cv_delimit || cv_h_country;             -- 国
    lv_head := lv_head || cv_delimit || cv_h_postalcode;          -- 郵便番号
    lv_head := lv_head || cv_delimit || cv_h_eff_startdate;       -- 有効開始日
    lv_head := lv_head || cv_delimit || cv_h_eff_enddate;         -- 有効終了日
-- Ver1.2 Add Start
    lv_head := lv_head || cv_delimit || cv_h_src_sys_owner;       -- ソース・システム所有者
    lv_head := lv_head || cv_delimit || cv_h_src_sys_id;          -- ソース・システムID
    lv_head := lv_head || cv_delimit || cv_h_ship_to_loc_code;    -- 出荷先事業所コード
    lv_head := lv_head || cv_delimit || cv_h_ship_to_loc_setcode; -- 出荷先事業所セット・コード
-- Ver1.2 Add End
--
    --===============================
    --  連携データ抽出(A-2)
    --===============================
    -- カーソルオープン
    OPEN get_office_cur;
    --
    --===============================
    --  I/Fファイル出力(A-3)
    --===============================
    -- データ書き込み
    <<main_loop>>
    LOOP
      -- レコードフェッチ
      FETCH get_office_cur INTO g_office_rec;
      EXIT WHEN get_office_cur%NOTFOUND;
      --
      -- ヘッダ出力
      BEGIN
        IF ( gn_target_cnt = 0 ) THEN
          UTL_FILE.PUT_LINE(  gf_file_hand
                            , lv_head
                             );
      END IF;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg :=  SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo      -- 'XXCFO'
                                                         , cv_msg_cfo_00030 )  -- ファイル書き込みエラー
                                , 1
                                , 5000);
          lv_errbuf := lv_errmsg || SQLERRM;
          -- ファイルをクローズ
          UTL_FILE.FCLOSE( gf_file_hand );
          RAISE global_process_expt;
      END;
      --
      -- 対象データ件数カウント
      gn_target_cnt := gn_target_cnt + 1;
      --
-- Ver1.1 Mod Start
      -- 変数の初期化
      lv_file_data := NULL;
      lv_nvl_conversion := NULL;
      --
      --変数設定
      lv_nvl_conversion := g_office_rec.nvl_conversion;  --NVL変換値
      -- データ編集
      lv_file_data := cv_metadata;                                                                               -- METADATA
      lv_file_data := lv_file_data || cv_delimit || cv_location;                                                 -- Location
      lv_file_data := lv_file_data || cv_delimit || cv_flex_locations_df;                                        -- FLEX:PER_LOCATIONS_DF
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.hl_purchasing_flag     ,lv_nvl_conversion); -- 購買担当フラグ
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.hl_shipping_flag       ,lv_nvl_conversion); -- 出荷担当フラグ
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.hl_rsp_name1           ,lv_nvl_conversion); -- 担当職責1
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.hl_rsp_name2           ,lv_nvl_conversion); -- 担当職責2
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.hl_rsp_name3           ,lv_nvl_conversion); -- 担当職責3
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.hl_rsp_name4           ,lv_nvl_conversion); -- 担当職責4
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.hl_rsp_name5           ,lv_nvl_conversion); -- 担当職責5
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.hl_rsp_name6           ,lv_nvl_conversion); -- 担当職責6
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.hl_rsp_name7           ,lv_nvl_conversion); -- 担当職責7
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.hl_rsp_name8           ,lv_nvl_conversion); -- 担当職責8
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.hl_rsp_name9           ,lv_nvl_conversion); -- 担当職責9
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.hl_rsp_name10          ,lv_nvl_conversion); -- 担当職責10
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.hl_locations_name      ,lv_nvl_conversion); -- 親事業所ID
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.hl_include_exclude     ,lv_nvl_conversion); -- 他拠点出荷依頼作成可否区分
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.hl_area                ,lv_nvl_conversion); -- 地区名
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.xla_location_name      ,lv_nvl_conversion); -- 正式名
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.xla_location_shortname ,lv_nvl_conversion); -- 略称
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.xla_location_name_alt  ,lv_nvl_conversion); -- カナ名
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.xla_zip                ,lv_nvl_conversion); -- 郵便番号
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.xla_address            ,lv_nvl_conversion); -- 住所
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.xla_phone              ,lv_nvl_conversion); -- 電話番号
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.xla_fax                ,lv_nvl_conversion); -- FAX
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.xla_division_code      ,lv_nvl_conversion); -- 本部コード 
      lv_file_data := lv_file_data || cv_delimit || --lv_nvl_conversion;                                         -- ロケーション内部ID
                                                    cv_null;
      lv_file_data := lv_file_data || cv_delimit || cv_setcode;                                                  -- セットコード
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.active_status          ,lv_nvl_conversion); -- 有効ステータス
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.hl_ship_to_site_flag   ,lv_nvl_conversion); -- 出荷先フラグ
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.hl_receiving_site_flag ,lv_nvl_conversion); -- 受入先フラグ
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.hl_bill_to_site_flag   ,lv_nvl_conversion); -- 請求先フラグ
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.hl_office_site_flag    ,lv_nvl_conversion); -- 社内先フラグ
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.hl_location_code       ,lv_nvl_conversion); -- 事業所コード
      lv_file_data := lv_file_data || cv_delimit || --NVL(g_office_rec.hl_description       ,lv_nvl_conversion); -- 摘要
                                                    SUBSTR( NVL(g_office_rec.hl_description ,g_office_rec.hl_location_code) ,1,60);
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.hl_description         ,lv_nvl_conversion); -- 摘要
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.xla_address            ,lv_nvl_conversion); -- 住所
      lv_file_data := lv_file_data || cv_delimit || cv_country;                                                  -- 国
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.xla_zip                ,lv_nvl_conversion); -- 郵便番号
      lv_file_data := lv_file_data || cv_delimit || cv_eff_startdate;                                            -- 有効開始日
      lv_file_data := lv_file_data || cv_delimit || --lv_nvl_conversion;                                         -- 有効終了日
                                                    cv_null;
-- Ver1.1 Mod End
-- Ver1.2 Add Start
      lv_file_data := lv_file_data || cv_delimit || cv_src_sys_owner;                                            -- ソース・システム所有者
      lv_file_data := lv_file_data || cv_delimit || g_office_rec.hl_location_id;                                 -- ソース・システムID
      lv_file_data := lv_file_data || cv_delimit || g_office_rec.ship_to_loc_code;                               -- 出荷先事業所コード
      lv_file_data := lv_file_data || cv_delimit || g_office_rec.ship_to_loc_setcode;                            -- 出荷先事業所セット・コード
-- Ver1.2 Add End
      -- データ出力
      BEGIN
        UTL_FILE.PUT_LINE( gf_file_hand
                         , lv_file_data
                         );
        -- 出力件数カウント
        gn_normal_cnt := gn_normal_cnt + 1;
        --
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg :=  SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo      -- 'XXCFO'
                                                         , cv_msg_cfo_00030 )  -- ファイル書き込みエラー
                                , 1
                                , 5000);
          lv_errbuf := lv_errmsg || SQLERRM;
          -- ファイルをクローズ
          UTL_FILE.FCLOSE( gf_file_hand );
          RAISE global_process_expt;
      END;
      --
    END LOOP main_loop;
    --
    -- カーソルクローズ
    CLOSE get_office_cur;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- カーソルクローズ
      IF ( get_office_cur%ISOPEN ) THEN
        CLOSE get_office_cur;
      END IF;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;                                                  -- # 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            -- # 任意 #
      -- カーソルクローズ
      IF ( get_office_cur%ISOPEN ) THEN
        CLOSE get_office_cur;
      END IF;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      -- カーソルクローズ
      IF ( get_office_cur%ISOPEN ) THEN
        CLOSE get_office_cur;
      END IF;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      -- カーソルクローズ
      IF ( get_office_cur%ISOPEN ) THEN
        CLOSE get_office_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END output_office;
--
  /**********************************************************************************
   * Procedure Name   : upd_oipm
   * Description      : 管理テーブル登録・更新(A-4)
   ***********************************************************************************/
  PROCEDURE upd_oipm (
      ov_errbuf             OUT VARCHAR2   -- エラー・メッセージ                  -- # 固定 #
    , ov_retcode            OUT VARCHAR2   -- リターン・コード                    -- # 固定 #
    , ov_errmsg             OUT VARCHAR2)  -- ユーザー・エラー・メッセージ        -- # 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(10) := 'upd_oipm'; -- プログラム名
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
    -- OIC連携処理管理テーブルの登録・更新処理
    --==============================================================
    -- 初回(移行)処理時
    IF ( gt_pre_prodate IS NULL ) THEN
      BEGIN
        INSERT INTO xxccp_oic_if_process_mng (
                 program_name
               , pre_process_date
               -- WHOカラム
               , created_by
               , creation_date
               , last_updated_by
               , last_update_date
               , last_update_login
               , request_id
               , program_application_id
               , program_id
               , program_update_date 
        )VALUES(
                 gt_ccrt_proname
               , gd_prodate
               , cn_created_by
               , cd_creation_date
               , cn_last_updated_by
               , cd_last_update_date
               , cn_last_update_login
               , cn_request_id
               , cn_program_application_id
               , cn_program_id
               , cd_program_update_date
        );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo   -- 'XXCFO'
                                                        , cv_msg_cfo_00024 -- 登録エラーメッセージ
                                                        , cv_tkn_table     -- 'TABLE'
                                                        , cv_msg_cfo_60008 -- 'OIC連携管理テーブル'
                                                        , cv_tkn_err_msg   -- 'ERRMSG'
                                                        , SQLERRM          -- エラー内容
                                                       )
                               , 1
                               , 5000);
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    --
    ELSE
      -- 次回以降処理時
      BEGIN
        UPDATE xxccp_oic_if_process_mng     oipm
        SET     oipm.pre_process_date         = gd_prodate
              , oipm.last_updated_by          = cn_last_updated_by
              , oipm.last_update_date         = cd_last_update_date
              , oipm.last_update_login        = cn_last_update_login
              , oipm.request_id               = cn_request_id
              , oipm.program_application_id   = cn_program_application_id
              , oipm.program_id               = cn_program_id
              , oipm.program_update_date      = cd_program_update_date
        WHERE   oipm.program_name = gt_ccrt_proname
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo   -- 'XXCFO'
                                                        , cv_msg_cfo_00020 -- 更新エラーメッセージ
                                                        , cv_tkn_table     -- 'TABLE'
                                                        , cv_msg_cfo_60008 -- 'OIC連携管理テーブル'
                                                        , cv_tkn_err_msg   -- 'ERRMSG'
                                                        , SQLERRM          -- エラー内容
                                                       )
                               , 1
                               , 5000);
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END upd_oipm;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
      iv_proc_date_for_recovery       IN  VARCHAR2   -- 1.業務日付（リカバリ用）
    , ov_errbuf                       OUT VARCHAR2   -- エラー・メッセージ           -- # 固定 #
    , ov_retcode                      OUT VARCHAR2   -- リターン・コード             -- # 固定 #
    , ov_errmsg                       OUT VARCHAR2)  -- ユーザー・エラー・メッセージ -- # 固定 #
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
    gn_target_cnt      := 0;
    gn_normal_cnt      := 0;
    gn_error_cnt       := 0;
    gn_warn_cnt        := 0;
--
    --===============================
    -- 初期処理(A-1)
    --===============================
    init(
        iv_proc_date_for_recovery -- 1.業務日付（リカバリ用）
      , lv_errbuf                 -- エラー・メッセージ           -- # 固定 #
      , lv_retcode                -- リターン・コード             -- # 固定 #
      , lv_errmsg                 -- ユーザー・エラー・メッセージ -- # 固定 #
    );
    IF (lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --===============================
    -- 連携データ抽出(A-2)
    -- I/Fファイル出力(A-3)
    --===============================
    output_office(
        lv_errbuf  -- エラー・メッセージ           -- # 固定 #
      , lv_retcode -- リターン・コード             -- # 固定 #
      , lv_errmsg  -- ユーザー・エラー・メッセージ -- # 固定 #
    );
    IF (lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --===============================
    -- 管理テーブル登録更新処理(A-4)
    --===============================
     upd_oipm(
         lv_errbuf  -- エラー・メッセージ           -- # 固定 #
       , lv_retcode -- リターン・コード             -- # 固定 #
       , lv_errmsg  -- ユーザー・エラー・メッセージ -- # 固定 #
     );
     IF (lv_retcode = cv_status_error ) THEN
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
      errbuf                      OUT VARCHAR2  -- エラー・メッセージ  -- # 固定 #
    , retcode                     OUT VARCHAR2  -- リターン・コード    -- # 固定 #
    , iv_proc_date_for_recovery   IN  VARCHAR2) -- 1.業務日付（リカバリ用）
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
    lv_errbuf          VARCHAR2(5000);            -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);               -- リターン・コード
    lv_errmsg          VARCHAR2(5000);            -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);             -- 終了メッセージコード
    --
  BEGIN
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
    --===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    --===============================================
    submain(
       iv_proc_date_for_recovery                   -- 1.業務日付（リカバリ用）
     , lv_errbuf   -- エラー・メッセージ           -- # 固定 #
     , lv_retcode  -- リターン・コード             -- # 固定 #
     , lv_errmsg   -- ユーザー・エラー・メッセージ -- # 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      -- 会計チーム標準：異常終了時の件数設定
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
      --エラー出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg -- エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf -- ユーザー・エラーメッセージ
      );
    END IF;
--
    --====================================================
    -- 終了処理(A-5)
    --====================================================
    -- ファイルクローズ
    IF ( UTL_FILE.IS_OPEN ( gf_file_hand )) THEN
      UTL_FILE.FCLOSE( gf_file_hand );
    END IF;
--
    -- 抽出件数出力
    gv_out_msg :=xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo   -- 'XXCFO'
                                          , cv_msg_cfo_60004 -- 検索対象・件数メッセージ
                                          , cv_tkn_target    -- 'TARGET'
                                          , cv_msg_cfo_60007 -- '事業所マスタ情報'
                                          , cv_tkn_count     -- 'COUNT'
                                          , gn_target_cnt    -- 検索件数
                                          );
    -- メッセージに出力
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
    -- 出力件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo   -- 'XXCFO'
                                           , cv_msg_cfo_60005 -- ファイル出力対象・件数メッセージ
                                           , cv_tkn_target    -- 'TARGET'
                                           , gv_file_name     -- プロファイル値「事業所マスタ連携データファイル名」
                                           , cv_tkn_count     -- 'COUNT'
                                           , gn_normal_cnt    -- 出力成功件数
                                          );
    -- メッセージに出力
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
    -- 対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name     -- 'XXCCP'
                    , iv_name         => cv_target_rec_msg      -- 対象件数メッセージ
                    , iv_token_name1  => cv_cnt_token           -- 件数メッセージ用トークン名
                    , iv_token_value1 => TO_CHAR(gn_target_cnt) -- 対象件数
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    -- 成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name     -- 'XXCCP'
                    , iv_name         => cv_success_rec_msg     -- 成功件数メッセージ
                    , iv_token_name1  => cv_cnt_token           -- 件数メッセージ用トークン名
                    , iv_token_value1 => TO_CHAR(gn_normal_cnt) -- 成功件数
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name     -- 'XXCCP'
                    , iv_name         => cv_error_rec_msg       -- エラー件数メッセージ
                    , iv_token_name1  => cv_cnt_token           -- 件数メッセージ用トークン名
                    , iv_token_value1 => TO_CHAR(gn_error_cnt)  -- エラー件数
                   );
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
    -- 終了メッセージ
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(  iv_application  => cv_appl_short_name
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
--#################################  固定例外処理部 START   ###################################
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
--###########################  固定部 END   #######################################################
  END main;
--
END XXCFO016A04C;
/
 