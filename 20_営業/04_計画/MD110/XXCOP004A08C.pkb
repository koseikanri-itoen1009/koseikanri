CREATE OR REPLACE PACKAGE BODY APPS.XXCOP004A08C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOP004A08C(body)
 * Description      : アップロードファイルからの登録（品目コード集約マスタ）
 * MD.050           : MD050_COP_004_A08_アップロードファイルからの登録（品目コード集約マスタ）
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  del_mst_sum_item_code  品目コード集約マスタ削除処理(A-2)
 *  get_file_upload_data   ファイルアップロードデータ取得処理(A-3)
 *  chk_validate_item      妥当性チェック処理(A-4)
 *  ins_mst_sum_item_code  品目コード集約マスタ登録処理(A-5)
 *  del_file_upload_data   ファイルアップロードデータ削除処理(A-6)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                           終了処理(A-7)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2013/10/31    1.0   K.Nakamura       新規作成
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
  global_lock_expt          EXCEPTION; -- ロック例外
  global_chk_item_expt      EXCEPTION; -- 妥当性チェック例外
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(20) := 'XXCOP004A08C';     -- パッケージ名
  -- アプリケーション短縮名
  cv_application              CONSTANT VARCHAR2(5)  := 'XXCOP';            -- アプリケーション
  -- プロファイル
  cv_master_org_id            CONSTANT VARCHAR2(30) := 'XXCMN_MASTER_ORG_ID';     -- マスタ組織ID
  cv_policy_group_code        CONSTANT VARCHAR2(30) := 'XXCMN_POLICY_GROUP_CODE'; -- カテゴリセット名(政策群コード)
  -- クイックコード
  cv_mst_group_item           CONSTANT VARCHAR2(30) := 'XXCOP1_MST_GROUP_ITEM';  -- 品目コード集約マスタ項目チェック
  cv_use_kbn                  CONSTANT VARCHAR2(30) := 'XXCOP1_USE_KBN';         -- 使用区分
  cv_file_upload_obj          CONSTANT VARCHAR2(30) := 'XXCCP1_FILE_UPLOAD_OBJ'; -- ファイルアップロード情報
  -- メッセージ
  cv_msg_xxcop_00002          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00002'; -- プロファイル値取得失敗エラー
  cv_msg_xxcop_00006          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00006'; -- クイックコード取得エラーメッセージ
  cv_msg_xxcop_00007          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00007'; -- テーブルロックエラーメッセージ
  cv_msg_xxcop_00014          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00014'; -- 担当拠点なし
  cv_msg_xxcop_00027          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00027'; -- 登録処理エラーメッセージ
  cv_msg_xxcop_00032          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00032'; -- アップロードIF取得エラーメッセージ
  cv_msg_xxcop_00036          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00036'; -- アップロードファイル出力メッセージ
  cv_msg_xxcop_00042          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00042'; -- 削除処理エラーメッセージ
  cv_msg_xxcop_00065          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00065'; -- 業務日付取得エラーメッセージ
  cv_msg_xxcop_00069          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00069'; -- フォーマットチェックエラー
  cv_msg_xxcop_00070          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00070'; -- 不正チェックエラー
  cv_msg_xxcop_00072          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00072'; -- 担当拠点チェックエラー
  cv_msg_xxcop_00078          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00078'; -- 空行メッセージ
  cv_msg_xxcop_10059          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-10059'; -- 集約コード存在チェックエラー
  cv_msg_xxcop_10060          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-10060'; -- 品目コード存在チェックエラー
  cv_msg_xxcop_10061          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-10061'; -- CSV内重複チェックエラー1
  cv_msg_xxcop_10062          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-10062'; -- CSV内重複チェックエラー2
  cv_msg_xxcop_10063          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-10063'; -- 品目コード集約マスタ存在チェックエラー
  cv_msg_xxcop_10067          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-10067'; -- 使用区分存在エラー
  cv_msg_xxcop_10070          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-10070'; -- 使用区分チェックエラー
  cv_msg_xxcop_10071          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-10071'; -- 政策群コード整合性チェックエラー
  -- トークン値
  cv_msg_xxcop_00079          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00079'; -- ファイルアップロードIF表
  cv_msg_xxcop_00083          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00083'; -- 品目コード集約マスタ
  -- トークンコード
  cv_tkn_errmsg               CONSTANT VARCHAR2(20) := 'ERRMSG';           -- エラーメッセージ
  cv_tkn_fileid               CONSTANT VARCHAR2(20) := 'FILEID';           -- ファイルID
  cv_tkn_file_id              CONSTANT VARCHAR2(20) := 'FILE_ID';          -- ファイルID
  cv_tkn_file                 CONSTANT VARCHAR2(20) := 'FILE';             -- ファイル名称
  cv_tkn_file_name            CONSTANT VARCHAR2(20) := 'FILE_NAME';        -- ファイル名称
  cv_tkn_format               CONSTANT VARCHAR2(20) := 'FORMAT';           -- フォーマットパターン
  cv_tkn_format_ptn           CONSTANT VARCHAR2(20) := 'FORMAT_PTN';       -- フォーマットパターン
  cv_tkn_item                 CONSTANT VARCHAR2(20) := 'ITEM';             -- 項目
  cv_tkn_profile              CONSTANT VARCHAR2(20) := 'PROF_NAME';        -- プロファイル
  cv_tkn_row                  CONSTANT VARCHAR2(20) := 'ROW';              -- 行数
  cv_tkn_table                CONSTANT VARCHAR2(20) := 'TABLE';            -- テーブル名
  cv_tkn_upload_object        CONSTANT VARCHAR2(20) := 'UPLOAD_OBJECT';    -- ファイルアップロード名称
  cv_tkn_user                 CONSTANT VARCHAR2(20) := 'USER';             -- ユーザID
  cv_tkn_value                CONSTANT VARCHAR2(20) := 'VALUE';            -- 項目値
  cv_tkn_value1               CONSTANT VARCHAR2(20) := 'VALUE1';           -- 項目値
  cv_tkn_value2               CONSTANT VARCHAR2(20) := 'VALUE2';           -- 項目値
  cv_tkn_value3               CONSTANT VARCHAR2(20) := 'VALUE3';           -- 項目値
  cv_tkn_value4               CONSTANT VARCHAR2(20) := 'VALUE4';           -- 項目値
  --
  cv_flag_y                   CONSTANT VARCHAR2(1)  := 'Y';                -- 'Y'
  ct_lang                     CONSTANT fnd_lookup_values.language%TYPE
                                                    := USERENV('LANG');    -- 言語
  -- 文字列
  cv_comma                    CONSTANT VARCHAR2(1)  := ',';                -- 文字区切り
  cv_dobule_quote             CONSTANT VARCHAR2(1)  := '"';                -- 文字括り
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 項目チェック格納レコード
  TYPE g_chk_item_rtype IS RECORD(
      meaning                 fnd_lookup_values.meaning%TYPE    -- 項目名称
    , attribute1              fnd_lookup_values.attribute1%TYPE -- 項目の長さ
    , attribute2              fnd_lookup_values.attribute2%TYPE -- 項目の長さ（小数点以下）
    , attribute3              fnd_lookup_values.attribute3%TYPE -- 必須フラグ
    , attribute4              fnd_lookup_values.attribute4%TYPE -- 属性
  );
  -- テーブルタイプ
  TYPE g_chk_item_ttype       IS TABLE OF g_chk_item_rtype INDEX BY PLS_INTEGER;
  -- テーブル型
  gt_file_data_all            xxccp_common_pkg2.g_file_data_tbl; -- 変換後VARCHAR2データ
  gt_csv_tab                  xxcop_common_pkg.g_char_ttype;     -- 分割結果（文字括り除去後）
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_base_code                VARCHAR2(4)                                 DEFAULT NULL;  -- 担当拠点コード
  gv_tkn_1                    VARCHAR2(5000)                              DEFAULT NULL;  -- エラーメッセージ用トークン1
  gn_delete_cnt               NUMBER                                      DEFAULT 0;     -- 削除件数
  gn_insert_cnt               NUMBER                                      DEFAULT 0;     -- 登録件数
  gn_item_cnt                 NUMBER                                      DEFAULT 0;     -- CSV項目数
  gn_record_cnt               NUMBER                                      DEFAULT 0;     -- CSVレコードカウンタ
  gd_process_date             DATE                                        DEFAULT NULL;  -- 業務日付
  gb_crowd_class_code_flag    BOOLEAN                                     DEFAULT FALSE; -- 政策群コード整合性チェックフラグ
  gt_master_org_id            mtl_parameters.organization_id%TYPE         DEFAULT NULL;  -- マスタ組織ID
  gt_policy_group_code        mtl_category_sets_vl.category_set_name%TYPE DEFAULT NULL;  -- カテゴリセット名(政策群コード)
  gt_upload_name              fnd_lookup_values.meaning%TYPE              DEFAULT NULL;  -- ファイルアップロード名称
  gt_use_kbn                  fnd_lookup_values.lookup_code%TYPE          DEFAULT NULL;  -- 使用区分
  -- テーブル変数
  g_chk_item_tab              g_chk_item_ttype;                                 -- 項目チェック
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      iv_file_id IN  VARCHAR2 -- ファイルID
    , iv_format  IN  VARCHAR2 -- フォーマットパターン
    , ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ           --# 固定 #
    , ov_retcode OUT VARCHAR2 -- リターン・コード             --# 固定 #
    , ov_errmsg  OUT VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #
  )
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
    -- *** ローカル変数 ***
    lt_file_name              xxccp_mrp_file_ul_interface.file_name%TYPE;     -- ファイル名
    lt_upload_date            xxccp_mrp_file_ul_interface.creation_date%TYPE; -- アップロード日時
--
    -- *** ローカルカーソル ***
    -- 項目チェックカーソル
    CURSOR chk_item_cur
    IS
      SELECT flv.meaning       AS meaning     -- 項目名称
           , flv.attribute1    AS attribute1  -- 項目の長さ
           , flv.attribute2    AS attribute2  -- 項目の長さ（小数点以下）
           , flv.attribute3    AS attribute3  -- 必須フラグ
           , flv.attribute4    AS attribute4  -- 属性
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_type  = cv_mst_group_item
      AND    gd_process_date BETWEEN NVL( flv.start_date_active, gd_process_date )
                             AND     NVL( flv.end_date_active, gd_process_date )
      AND    flv.enabled_flag = cv_flag_y
      AND    flv.language     = ct_lang
      ORDER BY flv.lookup_code
    ;
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
    -- 1．ファイルアップロードテーブル情報取得
    --==============================================================
    xxcop_common_pkg.get_upload_table_info(
        in_file_id     => TO_NUMBER(iv_file_id) -- ファイルID
      , iv_format      => iv_format             -- フォーマットパターン
      , ov_upload_name => gt_upload_name        -- ファイルアップロード名称
      , ov_file_name   => lt_file_name          -- ファイル名
      , od_upload_date => lt_upload_date        -- アップロード日時
      , ov_retcode     => lv_retcode            -- リターンコード
      , ov_errbuf      => lv_errbuf             -- エラー・メッセージ
      , ov_errmsg      => lv_errmsg             -- ユーザー・エラー・メッセージ
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      -- アップロードIF情報取得エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- アプリケーション短縮名
                     , iv_name         => cv_msg_xxcop_00032 -- メッセージコード
                     , iv_token_name1  => cv_tkn_fileid      -- トークンコード1
                     , iv_token_value1 => iv_file_id         -- トークン値1
                     , iv_token_name2  => cv_tkn_format      -- トークンコード2
                     , iv_token_value2 => iv_format          -- トークン値2
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 2．コンカレント入力パラメータメッセージ出力
    --==============================================================
    lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application       -- アプリケーション短縮名
                   , iv_name         => cv_msg_xxcop_00036   -- メッセージコード
                   , iv_token_name1  => cv_tkn_file_id       -- トークンコード1
                   , iv_token_value1 => iv_file_id           -- トークン値1
                   , iv_token_name2  => cv_tkn_format_ptn    -- トークンコード2
                   , iv_token_value2 => iv_format            -- トークン値2
                   , iv_token_name3  => cv_tkn_upload_object -- トークンコード3
                   , iv_token_value3 => gt_upload_name       -- トークン値3
                   , iv_token_name4  => cv_tkn_file_name     -- トークンコード4
                   , iv_token_value4 => lt_file_name         -- トークン値4
                 );
    -- メッセージ出力
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
      , buff  => lv_errmsg
    );
    FND_FILE.PUT_LINE(
        which => FND_FILE.LOG
      , buff  => lv_errmsg
    );
    -- 空行出力
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
      , buff  => ''
    );
    FND_FILE.PUT_LINE(
        which => FND_FILE.LOG
      , buff  => ''
    );
--
    --==============================================================
    -- 3．業務日付取得
    --==============================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- 業務日付が取得できない場合
    IF ( gd_process_date IS NULL ) THEN
      -- 業務日付取得エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application => cv_application     -- アプリケーション短縮名
                     , iv_name        => cv_msg_xxcop_00065 -- メッセージコード
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 4．プロファイル：マスタ組織ID取得
    --==============================================================
      BEGIN
        gt_master_org_id := fnd_profile.value(cv_master_org_id);
      EXCEPTION
        WHEN OTHERS THEN
          gt_master_org_id := NULL;
      END;
      -- プロファイル：マスタ組織IDが取得出来ない場合
      IF ( gt_master_org_id IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application     -- アプリケーション短縮名
                      , iv_name         => cv_msg_xxcop_00002 -- メッセージコード
                      , iv_token_name1  => cv_tkn_profile     -- トークンコード1
                      , iv_token_value1 => cv_master_org_id   -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    --==============================================================
    -- 5．プロファイル：カテゴリセット名(政策群コード)取得
    --==============================================================
      BEGIN
        gt_policy_group_code := fnd_profile.value(cv_policy_group_code);
      EXCEPTION
        WHEN OTHERS THEN
          gt_policy_group_code := NULL;
      END;
      -- プロファイル：カテゴリセット名(政策群コード)が取得出来ない場合
      IF ( gt_policy_group_code IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application       -- アプリケーション短縮名
                      , iv_name         => cv_msg_xxcop_00002   -- メッセージコード
                      , iv_token_name1  => cv_tkn_profile       -- トークンコード1
                      , iv_token_value1 => cv_policy_group_code -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    --==============================================================
    -- 6．クイックコード(項目チェック用定義情報)取得
    --==============================================================
    -- カーソルオープン
    OPEN chk_item_cur;
    -- データの一括取得
    FETCH chk_item_cur BULK COLLECT INTO g_chk_item_tab;
    -- カーソルクローズ
    CLOSE chk_item_cur;
    -- クイックコード(項目チェック用定義情報)が取得できない場合
    IF ( g_chk_item_tab.COUNT = 0 ) THEN
      -- クイックコード取得エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- アプリケーション短縮名
                     , iv_name         => cv_msg_xxcop_00006 -- メッセージコード
                     , iv_token_name1  => cv_tkn_value       -- トークンコード1
                     , iv_token_value1 => cv_mst_group_item  -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 7．クイックコード(項目チェック用定義情報)レコード件数取得
    --==============================================================
    gn_item_cnt := g_chk_item_tab.COUNT;
--
    --==============================================================
    -- 8．クイックコード(使用区分)が設定されているかチェック
    --==============================================================
    BEGIN
      SELECT flv.lookup_code   AS use_kbn
      INTO   gt_use_kbn
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_type  = cv_use_kbn
      AND    gd_process_date BETWEEN NVL( flv.start_date_active, gd_process_date )
                             AND     NVL( flv.end_date_active, gd_process_date )
      AND    flv.enabled_flag = cv_flag_y
      AND    flv.language     = ct_lang
      AND    ROWNUM           = 1
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- クイックコード取得エラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     -- アプリケーション短縮名
                       , iv_name         => cv_msg_xxcop_00006 -- メッセージコード
                       , iv_token_name1  => cv_tkn_value       -- トークンコード1
                       , iv_token_value1 => cv_use_kbn         -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==============================================================
    -- 9．担当拠点取得
    --==============================================================
    gv_base_code := xxcop_common_pkg.get_charge_base_code(
                        in_user_id     => cn_last_updated_by -- ユーザーID
                      , id_target_date => gd_process_date    -- 対象日
                    );
    -- 拠点コードが取得できない場合
    IF ( gv_base_code IS NULL ) THEN
      -- 担当拠点なしエラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- アプリケーション短縮名
                     , iv_name         => cv_msg_xxcop_00014 -- メッセージコード
                     , iv_token_name1  => cv_tkn_user        -- トークンコード1
                     , iv_token_value1 => cn_last_updated_by -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 10．担当拠点の使用区分取得
    --==============================================================
    BEGIN
      SELECT flv.lookup_code   AS use_kbn -- 使用区分
      INTO   gt_use_kbn
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_type  = cv_use_kbn
      AND    flv.meaning      = gv_base_code -- 担当拠点コード
      AND    gd_process_date BETWEEN NVL( flv.start_date_active, gd_process_date )
                             AND     NVL( flv.end_date_active, gd_process_date )
      AND    flv.enabled_flag = cv_flag_y
      AND    flv.language     = ct_lang
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- 使用区分存在エラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     -- アプリケーション短縮名
                       , iv_name         => cv_msg_xxcop_10067 -- メッセージコード
                       , iv_token_name1  => cv_tkn_value1      -- トークンコード1
                       , iv_token_value1 => cv_use_kbn         -- トークン値1
                       , iv_token_name2  => cv_tkn_value2      -- トークンコード2
                       , iv_token_value2 => gv_base_code       -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
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
      IF ( chk_item_cur%ISOPEN ) THEN
        CLOSE chk_item_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : del_mst_sum_item_code
   * Description      : 品目コード集約マスタ削除処理(A-2)
   ***********************************************************************************/
  PROCEDURE del_mst_sum_item_code(
      ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ           --# 固定 #
    , ov_retcode OUT VARCHAR2 -- リターン・コード             --# 固定 #
    , ov_errmsg  OUT VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_mst_sum_item_code'; -- プログラム名
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
    -- *** ローカルカーソル ***
    -- ロックカーソル
    CURSOR lock_cur
    IS
      SELECT 1                         AS dummy -- ダミー値
      FROM   xxcop_mst_group_item_code xmsic    -- 品目コード集約マスタ
      WHERE  xmsic.use_kbn = gt_use_kbn         -- 使用区分
      FOR UPDATE NOWAIT
    ;
    --
    TYPE l_lock_type IS TABLE OF lock_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    l_lock_tab                l_lock_type;
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
    -- 1．ロック取得
    --==============================================================
    BEGIN
      -- オープン
      OPEN lock_cur;
      -- フェッチ
      FETCH lock_cur BULK COLLECT INTO l_lock_tab;
      -- クローズ
      CLOSE lock_cur;
      --
    EXCEPTION
      -- ロック取得ができない場合
      WHEN global_lock_expt THEN
        -- トークン値取得
        gv_tkn_1  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_00083 );
        -- テーブルロックエラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     -- アプリケーション短縮名
                       , iv_name         => cv_msg_xxcop_00007 -- メッセージコード
                       , iv_token_name1  => cv_tkn_table       -- トークンコード1
                       , iv_token_value1 => gv_tkn_1           -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- データが存在する場合
    IF ( l_lock_tab.COUNT > 0 ) THEN
      --==============================================================
      -- 2．品目コード集約マスタ削除
      --==============================================================
      BEGIN
        DELETE FROM xxcop_mst_group_item_code xmsic -- 品目コード集約マスタ
        WHERE       xmsic.use_kbn = gt_use_kbn      -- 使用区分
        ;
        -- 削除件数
        gn_delete_cnt := SQL%ROWCOUNT;
        --
      EXCEPTION
        -- 削除に失敗した場合
        WHEN OTHERS THEN
          -- トークン値取得
          gv_tkn_1  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_00083 );
          -- 削除処理エラーメッセージ
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application     -- アプリケーション短縮名
                         , iv_name         => cv_msg_xxcop_00042 -- メッセージコード
                         , iv_token_name1  => cv_tkn_table       -- トークンコード1
                         , iv_token_value1 => gv_tkn_1           -- トークン値1
                       );
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END del_mst_sum_item_code;
--
  /**********************************************************************************
   * Procedure Name   : get_file_upload_data
   * Description      : ファイルアップロードデータ取得処理(A-3)
   ***********************************************************************************/
  PROCEDURE get_file_upload_data(
      iv_file_id IN  VARCHAR2 -- ファイルID
    , ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ           --# 固定 #
    , ov_retcode OUT VARCHAR2 -- リターン・コード             --# 固定 #
    , ov_errmsg  OUT VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_file_upload_data'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
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
    -- 1．BLOBデータ変換処理
    --==============================================================
    xxccp_common_pkg2.blob_to_varchar2(
        in_file_id   => TO_NUMBER(iv_file_id) -- ファイルID
      , ov_file_data => gt_file_data_all      -- 変換後VARCHAR2データ
      , ov_errbuf    => lv_errbuf             -- エラー・メッセージ
      , ov_retcode   => lv_retcode            -- リターン・コード
      , ov_errmsg    => lv_errmsg             -- ユーザー・エラー・メッセージ 
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_file_upload_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_validate_item
   * Description      : 妥当性チェック処理(A-4)
   ***********************************************************************************/
  PROCEDURE chk_validate_item(
      ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ           --# 固定 #
    , ov_retcode OUT VARCHAR2 -- リターン・コード             --# 固定 #
    , ov_errmsg  OUT VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_validate_item'; -- プログラム名
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
    -- *** ローカル変数 ***
    lv_crowd_class_code_sum   VARCHAR2(4);                    -- 政策群コード（集約コード用）
    lv_crowd_class_code_item  VARCHAR2(4);                    -- 政策群コード（品目コード用）
    ln_chk_cnt                NUMBER;                         -- チェック用件数
    lb_item_check_flag        BOOLEAN;                        -- 項目チェックフラグ
    lt_meaning                fnd_lookup_values.meaning%TYPE; -- 内容
    lt_csv_tab                xxcop_common_pkg.g_char_ttype;  -- 分割結果
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 初期化
    lv_crowd_class_code_sum  := NULL;  -- 政策群コード（集約コード用）
    lv_crowd_class_code_item := NULL;  -- 政策群コード（品目コード用）
    ln_chk_cnt               := 0;     -- チェック用件数
    lb_item_check_flag       := FALSE; -- 項目チェックフラグ
    lt_meaning               := NULL;  -- 内容
    lt_csv_tab.DELETE;                 -- 分割結果
    gt_csv_tab.DELETE;                 -- 分割結果（文字括り除去後）
--
    --==============================================================
    -- 1．CSV文字列分割
    --==============================================================
    -- CSV文字分割
    xxcop_common_pkg.char_delim_partition(
        iv_char    => gt_file_data_all(gn_record_cnt) -- 対象文字列
      , iv_delim   => cv_comma                        -- デリミタ
      , o_char_tab => lt_csv_tab                      -- 分割結果
      , ov_retcode => lv_retcode                      -- リターンコード
      , ov_errbuf  => lv_errbuf                       -- エラー・メッセージ
      , ov_errmsg  => lv_errmsg                       -- ユーザー・エラー・メッセージ
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    --
    -- 対象件数保持（CSVの行Noとしても使用）
    gn_target_cnt := gn_target_cnt + 1;
    --
    -- 全ての項目が未設定の場合
    IF ( TRIM( REPLACE( REPLACE( gt_file_data_all(gn_record_cnt), cv_comma, NULL ), cv_dobule_quote, NULL ) ) IS NULL ) THEN
      -- 空行メッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- アプリケーション短縮名
                     , iv_name         => cv_msg_xxcop_00078 -- メッセージコード
                     , iv_token_name1  => cv_tkn_row         -- トークンコード1
                     , iv_token_value1 => gn_target_cnt      -- トークン値1
                   );
      -- 妥当性チェック例外
      RAISE global_chk_item_expt;
    END IF;
    --
    -- 項目数が異なる場合
    IF ( gn_item_cnt <> lt_csv_tab.COUNT ) THEN
      -- フォーマットチェックエラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- アプリケーション短縮名
                     , iv_name         => cv_msg_xxcop_00069 -- メッセージコード
                     , iv_token_name1  => cv_tkn_row         -- トークンコード1
                     , iv_token_value1 => gn_target_cnt      -- トークン値1
                     , iv_token_name2  => cv_tkn_file        -- トークンコード2
                     , iv_token_value2 => gt_upload_name     -- トークン値2
                   );
      -- 妥当性チェック例外
      RAISE global_chk_item_expt;
    END IF;
    --
    --==============================================================
    -- 2．項目チェック
    --==============================================================
    -- 項目チェックループ
    << item_check_loop >>
    FOR i IN g_chk_item_tab.FIRST .. g_chk_item_tab.COUNT LOOP
      --
      -- 文字括りが存在する場合は削除
      gt_csv_tab(i) := TRIM( REPLACE( lt_csv_tab(i), cv_dobule_quote, NULL ) );
      --
      -- 項目チェック共通関数
      xxccp_common_pkg2.upload_item_check(
          iv_item_name    => g_chk_item_tab(i).meaning    -- 項目名称
        , iv_item_value   => gt_csv_tab(i)                -- 項目の値
        , in_item_len     => g_chk_item_tab(i).attribute1 -- 項目の長さ
        , in_item_decimal => g_chk_item_tab(i).attribute2 -- 項目の長さ(小数点以下)
        , iv_item_nullflg => g_chk_item_tab(i).attribute3 -- 必須フラグ
        , iv_item_attr    => g_chk_item_tab(i).attribute4 -- 項目属性
        , ov_errbuf       => lv_errbuf                    -- エラー・メッセージ           --# 固定 #
        , ov_retcode      => lv_retcode                   -- リターン・コード             --# 固定 #
        , ov_errmsg       => lv_errmsg                    -- ユーザー・エラー・メッセージ --# 固定 #
      );
      -- リターンコードが正常以外の場合
      IF ( lv_retcode <> cv_status_normal ) THEN
        -- 不正チェックエラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application            -- アプリケーション短縮名
                       , iv_name         => cv_msg_xxcop_00070        -- メッセージコード
                       , iv_token_name1  => cv_tkn_row                -- トークンコード1
                       , iv_token_value1 => gn_target_cnt             -- トークン値1
                       , iv_token_name2  => cv_tkn_item               -- トークンコード2
                       , iv_token_value2 => g_chk_item_tab(i).meaning -- トークン値2
                       , iv_token_name3  => cv_tkn_value              -- トークンコード3
                       , iv_token_value3 => gt_csv_tab(i)             -- トークン値3
                       , iv_token_name4  => cv_tkn_errmsg             -- トークンコード3
                       , iv_token_value4 => lv_errmsg                 -- トークン値3
                     );
        -- メッセージ出力
        FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT
          , buff  => lv_errmsg
        );
        -- 項目チェックエラー判定のフラグ変更
        lb_item_check_flag := TRUE;
      END IF;
      --
    END LOOP item_check_loop;
    --
    -- 項目チェックでエラーの場合
    IF ( lb_item_check_flag = TRUE ) THEN
      -- 妥当性チェック例外
      RAISE global_chk_item_expt;
    END IF;
    --
--
    --==============================================================
    -- 3．集約コードマスタ存在チェック
    --==============================================================
    BEGIN
      SELECT mcsv_ccc.crowd_class_code AS crowd_class_code -- 政策群コード
      INTO   lv_crowd_class_code_sum
      FROM   ic_item_mst_b             iimb -- OPM品目
           , mtl_system_items_b        msib -- Disc品目
           , ( SELECT gic.item_id            AS item_id
                    , mcv.segment1           AS crowd_class_code
               FROM   gmi_item_categories    gic
                    , mtl_category_sets_vl   mcsv
                    , mtl_categories_vl      mcv
               WHERE  gic.category_set_id    = mcsv.category_set_id
               AND    mcsv.category_set_name = gt_policy_group_code
               AND    gic.category_id        = mcv.category_id
             ) mcsv_ccc  -- インラインビュー_政策群コード
      WHERE  iimb.item_id         = mcsv_ccc.item_id(+)
      AND    iimb.item_no         = msib.segment1
      AND    iimb.item_no         = gt_csv_tab(1)
      AND    msib.organization_id = gt_master_org_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- 集約コードマスタ存在チェックエラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     -- アプリケーション短縮名
                       , iv_name         => cv_msg_xxcop_10059 -- メッセージコード
                       , iv_token_name1  => cv_tkn_row         -- トークンコード1
                       , iv_token_value1 => gn_target_cnt      -- トークン値1
                       , iv_token_name2  => cv_tkn_value       -- トークンコード2
                       , iv_token_value2 => gt_csv_tab(1)      -- トークン値2
                     );
        -- 妥当性チェック例外
        RAISE global_chk_item_expt;
    END;
--
    --==============================================================
    -- 4．品目コードマスタ存在チェック
    --==============================================================
    BEGIN
      SELECT mcsv_ccc.crowd_class_code AS crowd_class_code -- 政策群コード
      INTO   lv_crowd_class_code_item
      FROM   ic_item_mst_b             iimb -- OPM品目
           , mtl_system_items_b        msib -- Disc品目
           , ( SELECT gic.item_id            AS item_id
                    , mcv.segment1           AS crowd_class_code
               FROM   gmi_item_categories    gic
                    , mtl_category_sets_vl   mcsv
                    , mtl_categories_vl      mcv
               WHERE  gic.category_id        = mcv.category_id
               AND    gic.category_set_id    = mcsv.category_set_id
               AND    mcsv.category_set_name = gt_policy_group_code
             ) mcsv_ccc  -- インラインビュー_政策群コード
      WHERE  iimb.item_id         = mcsv_ccc.item_id(+)
      AND    iimb.item_no         = msib.segment1
      AND    iimb.item_no         = gt_csv_tab(3)
      AND    msib.organization_id = gt_master_org_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- 品目コードマスタ存在チェックエラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     -- アプリケーション短縮名
                       , iv_name         => cv_msg_xxcop_10060 -- メッセージコード
                       , iv_token_name1  => cv_tkn_row         -- トークンコード1
                       , iv_token_value1 => gn_target_cnt      -- トークン値1
                       , iv_token_name2  => cv_tkn_value       -- トークンコード2
                       , iv_token_value2 => gt_csv_tab(3)      -- トークン値2
                     );
        -- 妥当性チェック例外
        RAISE global_chk_item_expt;
    END;
--
    --==============================================================
    -- 5．使用区分整合性チェック
    --==============================================================
    -- 使用区分がログインユーザーの使用区分と相違する場合
    IF ( gt_csv_tab(5) <> gt_use_kbn ) THEN
      -- メッセージ用の使用区分名取得
      BEGIN
        SELECT flv.meaning       AS meaning -- 使用部署コード
        INTO   lt_meaning
        FROM   fnd_lookup_values flv
        WHERE  flv.lookup_type  = cv_use_kbn
        AND    flv.lookup_code  = gt_csv_tab(5)
        AND    gd_process_date BETWEEN NVL( flv.start_date_active, gd_process_date )
                               AND     NVL( flv.end_date_active, gd_process_date )
        AND    flv.enabled_flag = cv_flag_y
        AND    flv.language     = ct_lang
        ;
      EXCEPTION
        -- 取得できない場合
        WHEN NO_DATA_FOUND THEN
          -- メッセージ表示のための取得であるため、エラーにしない
          NULL;
      END;
      -- 使用区分チェックエラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- アプリケーション短縮名
                     , iv_name         => cv_msg_xxcop_10070 -- メッセージコード
                     , iv_token_name1  => cv_tkn_row         -- トークンコード1
                     , iv_token_value1 => gn_target_cnt      -- トークン値1
                     , iv_token_name2  => cv_tkn_value1      -- トークンコード2
                     , iv_token_value2 => gt_csv_tab(5)      -- トークン値2
                     , iv_token_name3  => cv_tkn_value2      -- トークンコード3
                     , iv_token_value3 => lt_meaning         -- トークン値3
                     , iv_token_name4  => cv_tkn_value3      -- トークンコード4
                     , iv_token_value4 => gv_base_code       -- トークン値4
                   );
      -- 妥当性チェック例外
      RAISE global_chk_item_expt;
    END IF;
--
    --==============================================================
    -- 6．CSVファイル内レコード重複チェック（集約コード・品目コード）
    --==============================================================
    SELECT COUNT(1)                  AS cnt      -- チェック用件数
    INTO   ln_chk_cnt
    FROM   xxcop_mst_group_item_code xmsic       -- 品目コード集約マスタ
    WHERE  xmsic.group_item_code = gt_csv_tab(1) -- 集約コード
    AND    xmsic.item_code       = gt_csv_tab(3) -- 品目コード
    AND    xmsic.use_kbn         = gt_use_kbn    -- 使用区分
    ;
    -- 件数が取得された場合
    IF ( ln_chk_cnt > 0 ) THEN
      -- データ重複エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- アプリケーション短縮名
                     , iv_name         => cv_msg_xxcop_10061 -- メッセージコード
                     , iv_token_name1  => cv_tkn_row         -- トークンコード1
                     , iv_token_value1 => gn_target_cnt      -- トークン値1
                     , iv_token_name2  => cv_tkn_value1      -- トークンコード2
                     , iv_token_value2 => gt_csv_tab(1)      -- トークン値2
                     , iv_token_name3  => cv_tkn_value2      -- トークンコード3
                     , iv_token_value3 => gt_csv_tab(3)      -- トークン値3
                   );
      -- 妥当性チェック例外
      RAISE global_chk_item_expt;
    END IF;
--
    --==============================================================
    -- 7．CSVファイル内レコード重複チェック（品目コード）
    --==============================================================
    SELECT COUNT(1)                  AS cnt -- チェック用件数
    INTO   ln_chk_cnt
    FROM   xxcop_mst_group_item_code xmsic  -- 品目コード集約マスタ
    WHERE  xmsic.item_code = gt_csv_tab(3)  -- 品目コード
    AND    xmsic.use_kbn   = gt_use_kbn     -- 使用区分
    ;
    -- 件数が取得された場合
    IF ( ln_chk_cnt > 0 ) THEN
      -- データ重複エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- アプリケーション短縮名
                     , iv_name         => cv_msg_xxcop_10062 -- メッセージコード
                     , iv_token_name1  => cv_tkn_row         -- トークンコード1
                     , iv_token_value1 => gn_target_cnt      -- トークン値1
                     , iv_token_name2  => cv_tkn_value1      -- トークンコード2
                     , iv_token_value2 => gt_csv_tab(3)      -- トークン値2
                   );
      -- 妥当性チェック例外
      RAISE global_chk_item_expt;
    END IF;
--
    --==============================================================
    -- 8．品目コード集約マスタ存在チェック（品目コード）
    --==============================================================
    SELECT COUNT(1)                  AS cnt -- チェック用件数
    INTO   ln_chk_cnt
    FROM   xxcop_mst_group_item_code xmsic  -- 品目コード集約マスタ
    WHERE  xmsic.item_code = gt_csv_tab(3)  -- 品目コード
    ;
    -- 件数が取得された場合
    IF ( ln_chk_cnt > 0 ) THEN
      -- データ重複エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- アプリケーション短縮名
                     , iv_name         => cv_msg_xxcop_10063 -- メッセージコード
                     , iv_token_name1  => cv_tkn_row         -- トークンコード1
                     , iv_token_value1 => gn_target_cnt      -- トークン値1
                     , iv_token_name2  => cv_tkn_value1      -- トークンコード2
                     , iv_token_value2 => gt_csv_tab(1)      -- トークン値2
                     , iv_token_name3  => cv_tkn_value2      -- トークンコード3
                     , iv_token_value3 => gt_csv_tab(3)      -- トークン値3
                     , iv_token_name4  => cv_tkn_value3      -- トークンコード3
                     , iv_token_value4 => gt_csv_tab(5)      -- トークン値3
                   );
      -- 妥当性チェック例外
      RAISE global_chk_item_expt;
    END IF;
--
    --==============================================================
    -- 9．政策群コード整合性チェック
    --==============================================================
    -- 政策群コードの頭3桁が相違する場合
    -- または政策群コード（集約コード）がNULLの場合
    -- または政策群コード（品目コード）がNULLの場合
    IF ( ( SUBSTRB(lv_crowd_class_code_sum, 1, 3) <> SUBSTRB(lv_crowd_class_code_item, 1, 3) )
      OR ( lv_crowd_class_code_sum IS NULL )
      OR ( lv_crowd_class_code_item IS NULL ) )
    THEN
      -- 政策群コード整合性チェックエラーメッセージ
      -- ※このチェックエラーは登録対象であり、警告終了する
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application           -- アプリケーション短縮名
                     , iv_name         => cv_msg_xxcop_10071       -- メッセージコード
                     , iv_token_name1  => cv_tkn_row               -- トークンコード1
                     , iv_token_value1 => gn_target_cnt            -- トークン値1
                     , iv_token_name2  => cv_tkn_value1            -- トークンコード2
                     , iv_token_value2 => gt_csv_tab(1)            -- トークン値2
                     , iv_token_name3  => cv_tkn_value2            -- トークンコード3
                     , iv_token_value3 => lv_crowd_class_code_sum  -- トークン値3
                     , iv_token_name4  => cv_tkn_value3            -- トークンコード4
                     , iv_token_value4 => gt_csv_tab(3)            -- トークン値4
                     , iv_token_name5  => cv_tkn_value4            -- トークンコード5
                     , iv_token_value5 => lv_crowd_class_code_item -- トークン値5
                   );
      -- メッセージ出力
      FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT
        , buff  => lv_errmsg
      );
      -- 政策群コードチェックフラグON
      gb_crowd_class_code_flag := TRUE;
    END IF;
--
  EXCEPTION
--
    -- 妥当性チェック例外ハンドラ
    WHEN global_chk_item_expt THEN
      -- 2.項目チェックエラーはメッセージ出力済のため、それ以外の場合にメッセージ出力
      IF ( lb_item_check_flag = FALSE ) THEN
        -- メッセージ出力
        FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT
          , buff  => lv_errmsg
        );
      END IF;
      --
      -- 警告件数設定
      gn_warn_cnt := gn_warn_cnt + 1;
      -- リターン・コードを警告設定
      ov_retcode := cv_status_warn;
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END chk_validate_item;
--
  /**********************************************************************************
   * Procedure Name   : ins_mst_sum_item_code
   * Description      : 品目コード集約マスタ登録処理(A-5)
   ***********************************************************************************/
  PROCEDURE ins_mst_sum_item_code(
      ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ           --# 固定 #
    , ov_retcode OUT VARCHAR2 -- リターン・コード             --# 固定 #
    , ov_errmsg  OUT VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_mst_sum_item_code'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
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
    -- 1. 登録処理
    --==============================================================
    BEGIN
      INSERT INTO xxcop_mst_group_item_code(
          group_item_code           -- 集約コード
        , group_item_name           -- 集約コード品目名
        , item_code                 -- 品目コード
        , item_name                 -- 品目名
        , use_kbn                   -- 使用区分
        , created_by                -- 作成者
        , creation_date             -- 作成日
        , last_updated_by           -- 最終更新者
        , last_update_date          -- 最終更新日
        , last_update_login         -- 最終更新ログイン
        , request_id                -- 要求ID
        , program_application_id    -- プログラムアプリケーションID
        , program_id                -- プログラムID
        , program_update_date       -- プログラム更新日
      ) VALUES (
          gt_csv_tab(1)             -- 集約コード
        , gt_csv_tab(2)             -- 集約コード品目名
        , gt_csv_tab(3)             -- 品目コード
        , gt_csv_tab(4)             -- 品目名
        , gt_csv_tab(5)             -- 使用区分
        , cn_created_by             -- 作成者
        , cd_creation_date          -- 作成日
        , cn_last_updated_by        -- 最終更新者
        , cd_last_update_date       -- 最終更新日
        , cn_last_update_login      -- 最終更新ログイン
        , cn_request_id             -- 要求ID
        , cn_program_application_id -- プログラムアプリケーションID
        , cn_program_id             -- プログラムID
        , cd_program_update_date    -- プログラム更新日
      );
      -- 登録件数
      gn_insert_cnt := gn_insert_cnt + 1;
      --
    EXCEPTION
      WHEN OTHERS THEN
        -- トークン値取得
        gv_tkn_1  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_00083 );
        -- 登録処理エラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     -- アプリケーション短縮名
                       , iv_name         => cv_msg_xxcop_00027 -- メッセージコード
                       , iv_token_name1  => cv_tkn_table       -- トークンコード1
                       , iv_token_value1 => gv_tkn_1           -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_mst_sum_item_code;
--
  /**********************************************************************************
   * Procedure Name   : del_file_upload_data
   * Description      : ファイルアップロードデータ削除処理(A-6)
   ***********************************************************************************/
  PROCEDURE del_file_upload_data(
      iv_file_id IN  VARCHAR2 -- ファイルID
    , ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ           --# 固定 #
    , ov_retcode OUT VARCHAR2 -- リターン・コード             --# 固定 #
    , ov_errmsg  OUT VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_file_upload_data'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
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
    -- 1. ファイルアップロード削除
    --==============================================================
    --ファイルアップロードテーブルデータ削除処理
    xxcop_common_pkg.delete_upload_table(
        in_file_id => TO_NUMBER(iv_file_id) -- ファイルID
      , ov_retcode => lv_retcode            -- リターン・コード
      , ov_errbuf  => lv_errbuf             -- エラー・メッセージ
      , ov_errmsg  => lv_errmsg             -- ユーザー・エラー・メッセージ
    );
    --
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- トークン値取得
      gv_tkn_1  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_00079 );
      -- 削除処理エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- アプリケーション短縮名
                     , iv_name         => cv_msg_xxcop_00042 -- メッセージコード
                     , iv_token_name1  => cv_tkn_table       -- トークンコード1
                     , iv_token_value1 => gv_tkn_1           -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END del_file_upload_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
      ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ           --# 固定 #
    , ov_retcode OUT VARCHAR2 -- リターン・コード             --# 固定 #
    , ov_errmsg  OUT VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #
    , iv_file_id IN  VARCHAR2 -- ファイルID
    , iv_format  IN  VARCHAR2 -- フォーマットパターン
  )
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- グローバル変数の初期化
    gn_target_cnt  := 0;
    gn_delete_cnt  := 0;
    gn_insert_cnt  := 0;
    gn_warn_cnt    := 0;
    gn_error_cnt   := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================================
    -- 初期処理(A-1)
    -- ===============================================
    init(
        iv_file_id => iv_file_id -- ファイルID
      , iv_format  => iv_format  -- フォーマットパターン
      , ov_errbuf  => lv_errbuf  -- エラー・メッセージ
      , ov_retcode => lv_retcode -- リターン・コード
      , ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- 品目コード集約マスタ削除処理(A-2)
    -- ===============================================
    del_mst_sum_item_code(
        ov_errbuf  => lv_errbuf  -- エラー・メッセージ
      , ov_retcode => lv_retcode -- リターン・コード
      , ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ 
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- ファイルアップロードデータ取得処理(A-3)
    -- ===============================================
    get_file_upload_data(
        iv_file_id => iv_file_id -- ファイルID
      , ov_errbuf  => lv_errbuf  -- エラー・メッセージ
      , ov_retcode => lv_retcode -- リターン・コード
      , ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ 
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 品目コード集約マスタ登録ループ
    << ins_loop >>
    FOR i IN gt_file_data_all.FIRST .. gt_file_data_all.COUNT LOOP
      -- カウンタ
      gn_record_cnt := gn_record_cnt + 1;
      --
      -- ===============================================
      -- 妥当性チェック処理(A-4)
      -- ===============================================
      chk_validate_item(
          ov_errbuf  => lv_errbuf  -- エラー・メッセージ
        , ov_retcode => lv_retcode -- リターン・コード
        , ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      --
      -- 妥当性チェックが正常のレコードは登録
      --                 警告のレコードはスキップ
      IF ( lv_retcode = cv_status_normal ) THEN
        -- ===============================================
        -- 品目コード集約マスタ登録処理(A-5)
        -- ===============================================
        ins_mst_sum_item_code(
            ov_errbuf  => lv_errbuf  -- エラー・メッセージ
          , ov_retcode => lv_retcode -- リターン・コード
          , ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ
        );
        --
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
    --
    END LOOP ins_loop;
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
      errbuf     OUT VARCHAR2 -- エラー・メッセージ #固定#
    , retcode    OUT VARCHAR2 -- リターン・コード   #固定#
    , iv_file_id IN  VARCHAR2 -- ファイルID
    , iv_format  IN  VARCHAR2 -- フォーマットパターン
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
    -- アプリケーション短縮名
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    -- メッセージ
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    cv_msg_xxcop_00090 CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00090'; -- 削除件数メッセージ
    cv_msg_xxcop_00091 CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00091'; -- 登録件数メッセージ
    cv_msg_xxcop_00093 CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00093'; -- 警告件数メッセージ
    -- トークン
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
--
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
        ov_errbuf  => lv_errbuf  -- エラー・メッセージ           --# 固定 #
      , ov_retcode => lv_retcode -- リターン・コード             --# 固定 #
      , ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ --# 固定 #
      , iv_file_id => iv_file_id -- ファイルID
      , iv_format  => iv_format  -- フォーマットパターン
    );
--
    --エラー出力
    IF ( lv_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf
      );
      -- エラー時のROLLBACK
      ROLLBACK;
      -- エラー件数設定
      gn_error_cnt := 1;
    END IF;
--
    -- ===============================================
    -- ファイルアップロードデータ削除処理(A-6)
    -- ===============================================
    del_file_upload_data(
        iv_file_id => iv_file_id -- ファイルID
      , ov_errbuf  => lv_errbuf  -- エラー・メッセージ
      , ov_retcode => lv_retcode -- リターン・コード
      , ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ 
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000)
      );
      -- エラー時のROLLBACK
      ROLLBACK;
      -- エラー件数設定
      gn_error_cnt := 1;
    END IF;
    -- ファイルアップロードデータ削除後のCOMMIT
    COMMIT;
--
    -- エラー件数が存在する場合
    IF ( gn_error_cnt > 0 ) THEN
      -- エラー時の件数設定
      gn_target_cnt  := 0;
      gn_delete_cnt  := 0;
      gn_insert_cnt  := 0;
      gn_warn_cnt    := 0;
      -- 終了ステータスをエラーにする
      lv_retcode := cv_status_error;
    -- エラー以外で、警告件数が存在する場合または政策群コード整合性チェックでエラーの場合
    ELSIF ( ( gn_warn_cnt > 0 ) OR ( gb_crowd_class_code_flag = TRUE ) ) THEN
      -- 終了ステータスを警告にする
      lv_retcode := cv_status_warn;
    -- エラー件数、警告件数が存在しない場合
    ELSE
      -- 終了ステータスを正常にする
      lv_retcode := cv_status_normal;
    END IF;
--
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --
    -- 対象件数出力
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
    -- 削除件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_xxcop_00090
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_delete_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    -- 登録件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_xxcop_00091
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_insert_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    -- 警告件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_xxcop_00093
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    -- エラー件数出力
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
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
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
END XXCOP004A08C;
/
