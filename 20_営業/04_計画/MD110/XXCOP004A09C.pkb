CREATE OR REPLACE PACKAGE BODY APPS.XXCOP004A09C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOP004A09C(body)
 * Description      : アップロードファイルからの登録（引取計画）
 * MD.050           : MD050_COP_004_A09_アップロードファイルからの登録（引取計画）
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_file_upload_data   ファイルアップロードデータ取得処理(A-2)
 *  chk_validate_item      妥当性チェック処理(A-3)
 *  exec_api_forecast_if   需要予測API実行(A-5)
 *  del_file_upload_data   ファイルアップロードデータ削除処理(A-6)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                         終了処理(A-7)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2013/10/30    1.0   S.Niki           新規作成
 *  2014/04/03    1.1   N.Nakamura       E_本稼動_11687対応
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
  global_lock_expt          EXCEPTION;  -- ロック例外
  global_chk_item_expt      EXCEPTION;  -- 妥当性チェック例外
-- ********** Ver.1.1 K.Nakamura ADD Start ************ --
  global_no_insert_expt     EXCEPTION;  -- 登録対象外例外
-- ********** Ver.1.1 K.Nakamura ADD End ************ --
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(20) := 'XXCOP004A09C';     -- パッケージ名
  -- アプリケーション短縮名
  cv_application              CONSTANT VARCHAR2(5)  := 'XXCOP';            -- アプリケーション:XXCOP
  cv_appl_xxcok               CONSTANT VARCHAR2(5)  := 'XXCOK';            -- アプリケーション:XXCOK
  -- プロファイル
  cv_master_org_id            CONSTANT VARCHAR2(30) := 'XXCMN_MASTER_ORG_ID';          -- マスタ組織ID
  cv_sales_org_code           CONSTANT VARCHAR2(30) := 'XXCOP1_SALES_ORG_CODE';        -- 営業組織コード
  cv_whse_code_leaf           CONSTANT VARCHAR2(30) := 'XXCOP1_WHSE_CODE_LEAF';        -- 出荷元倉庫_リーフ
  cv_whse_code_drink          CONSTANT VARCHAR2(30) := 'XXCOP1_WHSE_CODE_DRINK';       -- 出荷元倉庫_ドリンク
  cv_arti_div_code            CONSTANT VARCHAR2(30) := 'XXCMN_ARTI_DIV_CODE';          -- カテゴリセット名(本社商品区分)
  cv_product_div_code         CONSTANT VARCHAR2(30) := 'XXCMN_PRODUCT_DIV_CODE';       -- カテゴリセット名(商品製品区分)
  cv_item_class               CONSTANT VARCHAR2(30) := 'XXCMN_ITEM_CLASS';             -- カテゴリセット名(品目区分)
  cv_limit_forecast           CONSTANT VARCHAR2(30) := 'XXCOP1_LIMIT_FORECAST';        -- 引取計画入力制限日数
  -- クイックコード
  cv_file_upload_obj          CONSTANT VARCHAR2(30) := 'XXCCP1_FILE_UPLOAD_OBJ';       -- ファイルアップロード情報
  cv_forecast_item            CONSTANT VARCHAR2(30) := 'XXCOP1_FORECAST_ITEM';         -- 引取計画アップロード項目チェック
  cv_forecast_date            CONSTANT VARCHAR2(30) := 'XXCOP1_FORECAST_DATE';         -- ドリンク便日付
  -- メッセージ
  cv_msg_xxcop_00032          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00032';   -- アップロードIF情報取得エラーメッセージ
  cv_msg_xxcop_00036          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00036';   -- アップロードファイル出力メッセージ
  cv_msg_xxcop_00065          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00065';   -- 業務日付取得エラーメッセージ
  cv_msg_xxcop_00002          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00002';   -- プロファイル値取得失敗エラー
  cv_msg_xxcop_00013          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00013';   -- マスタチェックエラー
  cv_msg_xxcop_00006          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00006';   -- クイックコード取得エラーメッセージ
  cv_msg_xxcop_00007          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00007';   -- テーブルロックエラーメッセージ
  cv_msg_xxcop_00042          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00042';   -- 削除処理エラーメッセージ
  cv_msg_xxcok_00041          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00041';   -- BLOBデータ変換エラーメッセージ
  cv_msg_xxcop_00069          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00069';   -- フォーマットチェックエラー
  cv_msg_xxcop_00070          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00070';   -- 不正チェックエラー
  cv_msg_xxcop_00071          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00071';   -- DATE型チェックエラー
  cv_msg_xxcop_00072          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00072';   -- 担当拠点チェックエラー
  cv_msg_xxcop_00073          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00073';   -- マスタ未登録エラー
  cv_msg_xxcop_00074          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00074';   -- 不整合エラー
  cv_msg_xxcop_00076          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00076';   -- API起動エラー
  cv_msg_xxcop_00077          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00077';   -- 範囲外エラー
  cv_msg_xxcop_00079          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00079';   -- ファイルアップロードIF表ノート
  cv_msg_xxcop_00080          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00080';   -- 組織コードノート
  cv_msg_xxcop_00081          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00081';   -- 組織パラメータノート
  cv_msg_xxcop_00082          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00082';   -- フォーキャストノート
  cv_msg_xxcop_00084          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00084';   -- リーフ便表ノート
  cv_msg_xxcop_00085          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00085';   -- クイックコードノート
  cv_msg_xxcop_00086          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00086';   -- OPM保管場所マスタノート
  cv_msg_xxcop_00087          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00087';   -- 品目マスタノート
  cv_msg_xxcop_00088          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00088';   -- 出荷管理区分ノート
  cv_msg_xxcop_00089          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00089';   -- 商品区分ノート
  cv_msg_xxcop_00092          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00092';   -- 年月ノート
  cv_msg_xxcop_10058          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-10058';   -- 引取計画IF表ノート
  cv_msg_xxcop_10064          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-10064';   -- 引取計画データ範囲外エラー
  cv_msg_xxcop_10065          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-10065';   -- 出荷元倉庫取得エラー
  cv_msg_xxcop_10066          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-10066';   -- フォーキャスト存在チェックエラー
  cv_msg_xxcop_10068          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-10068';   -- 便稼働日チェックエラー
  cv_msg_xxcop_10069          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-10069';   -- 便重複チェックエラー
  cv_msg_xxcop_00027          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00027';   -- 登録処理エラーメッセージ
  -- トークンコード
  cv_tkn_fileid               CONSTANT VARCHAR2(20) := 'FILEID';             -- ファイルID
  cv_tkn_file_id              CONSTANT VARCHAR2(20) := 'FILE_ID';            -- ファイルID値
  cv_tkn_file_name            CONSTANT VARCHAR2(20) := 'FILE_NAME';          -- ファイル名
  cv_tkn_format               CONSTANT VARCHAR2(20) := 'FORMAT';             -- フォーマットパターン
  cv_tkn_format_ptn           CONSTANT VARCHAR2(20) := 'FORMAT_PTN';         -- フォーマットパターン値
  cv_tkn_upload_object        CONSTANT VARCHAR2(20) := 'UPLOAD_OBJECT';      -- ファイルアップロード名称
  cv_tkn_profile              CONSTANT VARCHAR2(20) := 'PROF_NAME';          -- プロファイル
  cv_tkn_row                  CONSTANT VARCHAR2(20) := 'ROW';                -- 行
  cv_tkn_file                 CONSTANT VARCHAR2(20) := 'FILE';               -- 項目
  cv_tkn_item                 CONSTANT VARCHAR2(20) := 'ITEM';               -- 項目
  cv_tkn_item1                CONSTANT VARCHAR2(20) := 'ITEM1';              -- 項目1
  cv_tkn_item2                CONSTANT VARCHAR2(20) := 'ITEM2';              -- 項目2
  cv_tkn_item3                CONSTANT VARCHAR2(20) := 'ITEM3';              -- 項目3
  cv_tkn_value                CONSTANT VARCHAR2(20) := 'VALUE';              -- 項目値
  cv_tkn_value1               CONSTANT VARCHAR2(20) := 'VALUE1';             -- 項目値1
  cv_tkn_value2               CONSTANT VARCHAR2(20) := 'VALUE2';             -- 項目値2
  cv_tkn_value3               CONSTANT VARCHAR2(20) := 'VALUE3';             -- 項目値3
  cv_tkn_value4               CONSTANT VARCHAR2(20) := 'VALUE4';             -- 項目値4
  cv_tkn_value5               CONSTANT VARCHAR2(20) := 'VALUE5';             -- 項目値5
  cv_tkn_table                CONSTANT VARCHAR2(20) := 'TABLE';              -- テーブル名
  cv_tkn_errmsg               CONSTANT VARCHAR2(20) := 'ERRMSG';             -- エラー内容詳細
  cv_tkn_prg_name             CONSTANT VARCHAR2(20) := 'PRG_NAME';           -- プログラム名
  --
  cv_flag_y                   CONSTANT VARCHAR2(1)  := 'Y';                  -- 有効
  ct_lang                     CONSTANT fnd_lookup_values.language%TYPE
                                                    := USERENV('LANG');
  -- 文字列
  cv_comma                    CONSTANT VARCHAR2(1)  := ',';                  -- 文字区切り
  cv_dobule_quote             CONSTANT VARCHAR2(1)  := '"';                  -- 文字括り
  -- 日付書式
  cv_format_yyyymm            CONSTANT VARCHAR2(6)  := 'YYYYMM';             -- YYYYMM
  cv_format_yyyymmdd          CONSTANT VARCHAR2(8)  := 'YYYYMMDD';           -- YYYYMMDD
  cv_format_std_yyyymmdd      CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';         -- YYYY/MM/DD
  --
  cv_forecast_type_01         CONSTANT VARCHAR2(2)  := '01';                 -- '01'：引取計画
  cv_prod_class_leaf          CONSTANT VARCHAR2(1)  := '1';                  -- '1'：リーフ
  cv_prod_class_drink         CONSTANT VARCHAR2(1)  := '2';                  -- '2'：ドリンク
  cv_prod_class_both          CONSTANT VARCHAR2(1)  := '3';                  -- '3'：両方
  cv_ins_0                    CONSTANT VARCHAR2(1)  := '0';
  cn_pad_2                    CONSTANT NUMBER       := 2;
  cn_case_count_min           CONSTANT NUMBER       := 0;                    -- 計画数量(min)
  cn_case_count_max           CONSTANT NUMBER       := 999999;               -- 計画数量(max)
  cn_num_of_case_1            CONSTANT NUMBER       := 1;                    -- ケース入数
  cn_api_ret_normal           CONSTANT NUMBER       := 5;                    -- 5：正常
  cn_process_status           CONSTANT NUMBER       := 2;                    -- process_status
  cn_confidence_percentage    CONSTANT NUMBER       := 100;                  -- confidence_percentage
  cn_bucket_type              CONSTANT NUMBER       := 1;                    -- バケットタイプ
  cv_api_name                 CONSTANT VARCHAR2(50) := 'mrp_forecast_interface_pk.mrp_forecast_interface';
                                                                             -- 需要API名
  cv_item_status_20           CONSTANT VARCHAR2(2)  := '20';                 -- '20'：仮登録
  cv_item_status_30           CONSTANT VARCHAR2(2)  := '30';                 -- '30'：本登録
  cv_item_status_40           CONSTANT VARCHAR2(2)  := '40';                 -- '40'：廃
  cv_item_prod_class_prod     CONSTANT VARCHAR2(1)  := '2';                  -- '2'：製品
  cv_item_class_prod          CONSTANT VARCHAR2(1)  := '5';                  -- '5'：製品
  cv_shipment_on              CONSTANT VARCHAR2(1)  := '1';                  -- '1'：出荷可
  cv_obsolete_class_off       CONSTANT VARCHAR2(1)  := '0';                  -- '0'：対象外
  cv_sales_target_on          CONSTANT VARCHAR2(1)  := '1';                  -- '1'：売上対象
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 項目チェック格納レコード
  TYPE g_chk_item_rtype IS RECORD(
      meaning                 fnd_lookup_values.meaning%TYPE     -- 項目名称
    , attribute1              fnd_lookup_values.attribute1%TYPE  -- 項目の長さ
    , attribute2              fnd_lookup_values.attribute2%TYPE  -- 項目の長さ（小数点以下）
    , attribute3              fnd_lookup_values.attribute3%TYPE  -- 必須フラグ
    , attribute4              fnd_lookup_values.attribute4%TYPE  -- 属性
  );
  -- テーブルタイプ
  TYPE g_chk_item_ttype       IS TABLE OF g_chk_item_rtype INDEX BY PLS_INTEGER;
  -- テーブル型
  gt_file_data                xxccp_common_pkg2.g_file_data_tbl; -- 変換後VARCHAR2データ
  gt_csv_tab                  xxcop_common_pkg.g_char_ttype;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_item_cnt                 NUMBER       DEFAULT 0;                        -- CSV項目数
  gn_line_cnt                 NUMBER       DEFAULT 0;                        -- CSV処理行カウンタ
  gn_record_no                NUMBER       DEFAULT 0;                        -- レコードNo
  gd_process_date             DATE         DEFAULT NULL;                     -- 業務日付
  gt_master_org_id            mtl_parameters.organization_id%TYPE;           -- マスタ組織ID
  gt_sales_org_code           mtl_parameters.organization_code%TYPE;         -- 営業組織コード
  gt_sales_org_id             mtl_parameters.organization_id%TYPE;           -- 営業組織ID
  gt_whse_code_leaf           mtl_item_locations.segment1%TYPE;              -- 出荷元倉庫_リーフ
  gt_whse_code_drink          mtl_item_locations.segment1%TYPE;              -- 出荷元倉庫_ドリンク
  gt_arti_div_code            mtl_category_sets_vl.category_set_name%TYPE;   -- カテゴリセット名(本社商品区分)
  gt_product_div_code         mtl_category_sets_vl.category_set_name%TYPE;   -- カテゴリセット名(商品製品区分)
  gt_item_class               mtl_category_sets_vl.category_set_name%TYPE;   -- カテゴリセット名(品目区分)
  gn_limit_forecast           NUMBER;                                        -- 引取計画入力制限日数
  gt_upload_name              fnd_lookup_values.meaning%TYPE;                -- ファイルアップロード名称
  --
  gv_tkn_1                    VARCHAR2(5000);        -- エラーメッセージ用トークン1
  gv_tkn_2                    VARCHAR2(5000);        -- エラーメッセージ用トークン2
  gv_tkn_3                    VARCHAR2(5000);        -- エラーメッセージ用トークン3
  gv_tkn_4                    VARCHAR2(5000);        -- エラーメッセージ用トークン4
  -- テーブル変数
  g_chk_item_tab              g_chk_item_ttype;      -- 項目チェック
--
  -- ===============================
  -- グローバルカーソル
  -- ===============================
  -- 引取計画IF表カーソル
  CURSOR forecast_if_cur(
    iv_file_id  IN VARCHAR2)
  IS
    SELECT xmfi.file_id               AS file_id               -- ファイルID
         , xmfi.record_no             AS record_no             -- レコードNo
         , xmfi.target_month          AS target_month          -- 年月
         , xmfi.base_code             AS base_code             -- 拠点コード
         , xmfi.whse_code             AS whse_code             -- 出荷元倉庫
         , xmfi.item_code             AS item_code             -- 商品コード
         , xmfi.service_no            AS service_no            -- 便数
         , xmfi.case_count            AS case_count            -- 計画数量
         , xmfi.inventory_item_id     AS inventory_item_id     -- 品目ID
         , xmfi.num_of_case           AS num_of_case           -- ケース入数
         , xmfi.forecast_date         AS forecast_date         -- 日付
         , xmfi.forecast_designator   AS forecast_designator   -- フォーキャスト名
    FROM   xxcop_mrp_forecast_interface  xmfi  -- 引取計画IF表
    WHERE  xmfi.file_id               = TO_NUMBER(iv_file_id)
    ORDER BY xmfi.record_no  -- レコードNo
    ;
  -- レコード定義
  forecast_if_rec             forecast_if_cur%ROWTYPE;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      iv_file_id IN  VARCHAR2 -- ファイルID
    , iv_format  IN  VARCHAR2 -- フォーマット
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
      SELECT flv.meaning              AS meaning     -- 項目名称
           , flv.attribute1           AS attribute1  -- 項目の長さ
           , flv.attribute2           AS attribute2  -- 項目の長さ（小数点以下）
           , flv.attribute3           AS attribute3  -- 必須フラグ
           , flv.attribute4           AS attribute4  -- 属性
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_type  = cv_forecast_item
      AND    gd_process_date BETWEEN NVL( flv.start_date_active, gd_process_date )
                             AND     NVL( flv.end_date_active  , gd_process_date )
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
                       iv_application => cv_application         -- アプリケーション短縮名
                     , iv_name        => cv_msg_xxcop_00065     -- メッセージコード
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
                        iv_application  => cv_application       -- アプリケーション短縮名
                      , iv_name         => cv_msg_xxcop_00002   -- メッセージコード
                      , iv_token_name1  => cv_tkn_profile       -- トークンコード1
                      , iv_token_value1 => cv_master_org_id     -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    --==============================================================
    -- 5．プロファイル：営業組織コード取得
    --==============================================================
      BEGIN
        gt_sales_org_code := fnd_profile.value(cv_sales_org_code);
      EXCEPTION
        WHEN OTHERS THEN
          gt_sales_org_code := NULL;
      END;
      -- プロファイル：営業組織コードが取得出来ない場合
      IF ( gt_sales_org_code IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application       -- アプリケーション短縮名
                      , iv_name         => cv_msg_xxcop_00002   -- メッセージコード
                      , iv_token_name1  => cv_tkn_profile       -- トークンコード1
                      , iv_token_value1 => cv_sales_org_code    -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    --==============================================================
    -- 6．営業組織ID取得
    --==============================================================
      BEGIN
        SELECT mp.organization_id  AS organization_id
        INTO   gt_sales_org_id
        FROM   mtl_parameters mp
        WHERE  mp.organization_code = gt_sales_org_code  -- 5.営業組織コード
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          gt_sales_org_id := NULL;
      END;
      -- 営業組織IDが取得出来ない場合
      IF ( gt_sales_org_id IS NULL ) THEN
        -- トークン値を設定
        gv_tkn_1  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_00080 );
        gv_tkn_3  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_00081 );
        --
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application        -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcop_00013    -- メッセージコード
                      ,iv_token_name1  => cv_tkn_item           -- トークンコード1
                      ,iv_token_value1 => gv_tkn_1              -- トークン値1
                      ,iv_token_name2  => cv_tkn_value          -- トークンコード2
                      ,iv_token_value2 => gt_sales_org_code     -- トークン値2
                      ,iv_token_name3  => cv_tkn_table          -- トークンコード3
                      ,iv_token_value3 => gv_tkn_3              -- トークン値3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    --==============================================================
    -- 7．プロファイル：出荷元倉庫_リーフ取得
    --==============================================================
      BEGIN
        gt_whse_code_leaf := fnd_profile.value(cv_whse_code_leaf);
      EXCEPTION
        WHEN OTHERS THEN
          gt_whse_code_leaf := NULL;
      END;
      -- プロファイル：出荷元倉庫_リーフが取得出来ない場合
      IF ( gt_whse_code_leaf IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application       -- アプリケーション短縮名
                      , iv_name         => cv_msg_xxcop_00002   -- メッセージコード
                      , iv_token_name1  => cv_tkn_profile       -- トークンコード1
                      , iv_token_value1 => cv_whse_code_leaf    -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    --==============================================================
    -- 8．プロファイル：出荷元倉庫_ドリンク取得
    --==============================================================
      BEGIN
        gt_whse_code_drink := fnd_profile.value(cv_whse_code_drink);
      EXCEPTION
        WHEN OTHERS THEN
          gt_whse_code_leaf := NULL;
      END;
      -- プロファイル：出荷元倉庫_ドリンクが取得出来ない場合
      IF ( gt_whse_code_drink IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application       -- アプリケーション短縮名
                      , iv_name         => cv_msg_xxcop_00002   -- メッセージコード
                      , iv_token_name1  => cv_tkn_profile       -- トークンコード1
                      , iv_token_value1 => cv_whse_code_drink   -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    --==============================================================
    -- 9．プロファイル：カテゴリセット名(本社商品区分)取得
    --==============================================================
      BEGIN
        gt_arti_div_code := fnd_profile.value(cv_arti_div_code);
      EXCEPTION
        WHEN OTHERS THEN
          gt_arti_div_code := NULL;
      END;
      -- プロファイル：カテゴリセット名(本社商品区分)が取得出来ない場合
      IF ( gt_arti_div_code IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application       -- アプリケーション短縮名
                      , iv_name         => cv_msg_xxcop_00002   -- メッセージコード
                      , iv_token_name1  => cv_tkn_profile       -- トークンコード1
                      , iv_token_value1 => cv_arti_div_code     -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    --==============================================================
    -- 10．プロファイル：カテゴリセット名(商品製品区分)取得
    --==============================================================
      BEGIN
        gt_product_div_code := fnd_profile.value(cv_product_div_code);
      EXCEPTION
        WHEN OTHERS THEN
          gt_product_div_code := NULL;
      END;
      -- プロファイル：カテゴリセット名(商品製品区分)が取得出来ない場合
      IF ( gt_product_div_code IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application       -- アプリケーション短縮名
                      , iv_name         => cv_msg_xxcop_00002   -- メッセージコード
                      , iv_token_name1  => cv_tkn_profile       -- トークンコード1
                      , iv_token_value1 => cv_product_div_code  -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    --==============================================================
    -- 11．プロファイル：カテゴリセット名(品目区分)取得
    --==============================================================
      BEGIN
        gt_item_class := fnd_profile.value(cv_item_class);
      EXCEPTION
        WHEN OTHERS THEN
          gt_item_class := NULL;
      END;
      -- プロファイル：カテゴリセット名(品目区分)が取得出来ない場合
      IF ( gt_item_class IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application       -- アプリケーション短縮名
                      , iv_name         => cv_msg_xxcop_00002   -- メッセージコード
                      , iv_token_name1  => cv_tkn_profile       -- トークンコード1
                      , iv_token_value1 => cv_item_class        -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    --==============================================================
    -- 12．プロファイル：引取計画入力制限日数取得
    --==============================================================
      BEGIN
        gn_limit_forecast := TO_NUMBER(fnd_profile.value(cv_limit_forecast));
      EXCEPTION
        WHEN OTHERS THEN
          gn_limit_forecast := NULL;
      END;
      -- プロファイル：引取計画入力制限日数が取得出来ない場合
      IF ( gn_limit_forecast IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application          -- アプリケーション短縮名
                      , iv_name         => cv_msg_xxcop_00002      -- メッセージコード
                      , iv_token_name1  => cv_tkn_profile          -- トークンコード1
                      , iv_token_value1 => cv_limit_forecast       -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    --==============================================================
    -- 13．クイックコード(項目チェック情報)取得
    --==============================================================
    -- カーソルオープン
    OPEN chk_item_cur;
    -- データの一括取得
    FETCH chk_item_cur BULK COLLECT INTO g_chk_item_tab;
    -- カーソルクローズ
    CLOSE chk_item_cur;
    -- クイックコードが取得できない場合
    IF ( g_chk_item_tab.COUNT = 0 ) THEN
      -- クイックコード取得エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application        -- アプリケーション短縮名
                     , iv_name         => cv_msg_xxcop_00006    -- メッセージコード
                     , iv_token_name1  => cv_tkn_value          -- トークンコード1
                     , iv_token_value1 => cv_forecast_item      -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 14．クイックコード(項目チェック情報)レコード件数取得
    --==============================================================
    gn_item_cnt := g_chk_item_tab.COUNT;
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
   * Procedure Name   : get_file_upload_data
   * Description      : ファイルアップロードデータ取得処理(A-2)
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
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
--
    -- *** ローカルカーソル ***
    -- アップロードファイルデータカーソル
    CURSOR xmfui_cur( in_file_id NUMBER )
    IS
      SELECT xmfui.file_name     AS file_name        -- ファイル名
            ,flv.meaning         AS upload_object    -- ファイルアップロード名称
      FROM   xxccp_mrp_file_ul_interface xmfui       -- ファイルアップロードIFテーブル
            ,fnd_lookup_values           flv         -- クイックコード
      WHERE  xmfui.file_id       = in_file_id
      AND    flv.lookup_type     = cv_file_upload_obj
      AND    flv.lookup_code     = xmfui.file_content_type
      AND    gd_process_date     BETWEEN NVL( flv.start_date_active, gd_process_date )
                                 AND     NVL( flv.end_date_active  , gd_process_date )
      AND    flv.enabled_flag    = cv_flag_y
      AND    flv.language        = ct_lang
      FOR UPDATE OF xmfui.file_id NOWAIT
    ;
    -- レコード定義
    xmfui_rec                 xmfui_cur%ROWTYPE;
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
    -- 1．ファイルアップロードIFテーブルロック取得
    --==============================================================
    BEGIN
      -- オープン
      OPEN xmfui_cur( TO_NUMBER(iv_file_id) );
      -- フェッチ
      FETCH xmfui_cur INTO xmfui_rec;
      -- クローズ
      CLOSE xmfui_cur;
      --
    EXCEPTION
      -- ロック取得例外ハンドラ
      WHEN global_lock_expt THEN
        -- トークン値を設定
        gv_tkn_1  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_00079 );
        --
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
    --==============================================================
    -- 2．BLOBデータ変換処理
    --==============================================================
    xxccp_common_pkg2.blob_to_varchar2(
        in_file_id   => TO_NUMBER(iv_file_id) -- ファイルID
      , ov_file_data => gt_file_data          -- 変換後VARCHAR2データ
      , ov_errbuf    => lv_errbuf             -- エラー・メッセージ
      , ov_retcode   => lv_retcode            -- リターン・コード
      , ov_errmsg    => lv_errmsg             -- ユーザー・エラー・メッセージ 
    );
    -- リターンコードがエラーの場合
    IF ( lv_retcode = cv_status_error ) THEN
      -- BLOBデータ変換エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_xxcok      -- アプリケーション短縮名
                     , iv_name         => cv_msg_xxcok_00041 -- メッセージコード
                     , iv_token_name1  => cv_tkn_file_id     -- トークンコード1
                     , iv_token_value1 => iv_file_id         -- トークン値1
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
      IF ( xmfui_cur%ISOPEN ) THEN
        CLOSE xmfui_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END get_file_upload_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_validate_item
   * Description      : 妥当性チェック処理(A-3)
   ***********************************************************************************/
  PROCEDURE chk_validate_item(
      iv_file_id IN  VARCHAR2 -- ファイルID
    , iv_format  IN  VARCHAR2 -- フォーマット
    , ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ           --# 固定 #
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
    ln_chk_cnt                NUMBER       DEFAULT 0;                                 -- チェック用件数
    lt_inventory_item_id      xxcop_mrp_forecast_interface.inventory_item_id%TYPE;    -- 品目ID
    lt_prod_class             mtl_categories_vl.segment1%TYPE;                        -- 商品区分
    lt_num_of_case            xxcop_mrp_forecast_interface.num_of_case%TYPE;          -- ケース入数
    lt_whse_code              xxcop_mrp_forecast_interface.whse_code%TYPE;            -- 出荷元倉庫
    lt_whse_type              hr_locations_all.attribute1%TYPE;                       -- 出荷管理元区分
    lt_target_month           xxcop_mrp_forecast_interface.target_month%TYPE;         -- 年月
    lt_forecast_date          xxcop_mrp_forecast_interface.forecast_date%TYPE;        -- フォーキャスト日付
    lt_chk_forecast_date      xxcop_mrp_forecast_interface.forecast_date%TYPE;        -- 稼働日チェック用日付
    lv_forecast_month         VARCHAR(6);                                             -- フォーキャスト年月
    lt_forecast_designator    xxcop_mrp_forecast_interface.forecast_designator%TYPE;  -- フォーキャスト名
    lt_csv_tab                xxcop_common_pkg.g_char_ttype;                          -- 分割結果
    lb_item_check_flag        BOOLEAN      DEFAULT FALSE;                             -- 項目チェックフラグ
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
    ln_chk_cnt              := 0;      -- チェック用件数
    lt_inventory_item_id    := NULL;   -- 品目ID
    lt_prod_class           := NULL;   -- 商品区分
    lt_num_of_case          := NULL;   -- ケース入数
    lt_whse_code            := NULL;   -- 出荷元倉庫
    lt_whse_type            := NULL;   -- 出荷管理元区分
    lt_target_month         := NULL;   -- 年月
    lt_forecast_date        := NULL;   -- フォーキャスト日付
    lt_chk_forecast_date    := NULL;   -- 稼働日チェック用日付
    lv_forecast_month       := NULL;   -- フォーキャスト年月
    lt_forecast_designator  := NULL;   -- フォーキャスト名
    lb_item_check_flag      := FALSE;  -- 項目チェックフラグ
    lt_csv_tab.DELETE;            -- 分割結果
    gt_csv_tab.DELETE;            -- 分割結果（文字括り除去後）
--
    --==============================================================
    -- 1．CSV文字列分割
    --==============================================================
    --CSV文字分割
    xxcop_common_pkg.char_delim_partition(
        ov_retcode => lv_retcode                    -- リターンコード
      , ov_errbuf  => lv_errbuf                     -- エラー・メッセージ
      , ov_errmsg  => lv_errmsg                     -- ユーザー・エラー・メッセージ
      , iv_char    => gt_file_data(gn_line_cnt)     -- 対象文字列
      , iv_delim   => cv_comma                      -- デリミタ
      , o_char_tab => lt_csv_tab                    -- 分割結果
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    --
    -- レコードNo
    gn_record_no  := gn_record_no  + 1;
    -- 対象件数（CSVの行数）保持
    gn_target_cnt := gn_target_cnt + 1;
    --
    -- 項目数が異なる場合
    IF ( gn_item_cnt <> lt_csv_tab.COUNT ) THEN
      -- フォーマットチェックエラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- アプリケーション短縮名
                     , iv_name         => cv_msg_xxcop_00069 -- メッセージコード
                     , iv_token_name1  => cv_tkn_row         -- トークンコード1
                     , iv_token_value1 => gn_record_no       -- トークン値1
                     , iv_token_name2  => cv_tkn_file        -- トークンコード2
                     , iv_token_value2 => gt_upload_name     -- トークン値2
                   );
      -- メッセージ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg);
      -- 妥当性チェックエラー例外
      RAISE global_chk_item_expt;
    END IF;
    --
    --==============================================================
    -- 2．必須／型／桁数チェック
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
          iv_item_name    => g_chk_item_tab(i).meaning     -- 項目名称
        , iv_item_value   => gt_csv_tab(i)                 -- 項目の値
        , in_item_len     => g_chk_item_tab(i).attribute1  -- 項目の長さ
        , in_item_decimal => g_chk_item_tab(i).attribute2  -- 項目の長さ(小数点以下)
        , iv_item_nullflg => g_chk_item_tab(i).attribute3  -- 必須フラグ
        , iv_item_attr    => g_chk_item_tab(i).attribute4  -- 項目属性
        , ov_errbuf       => lv_errbuf                     -- エラー・メッセージ           --# 固定 #
        , ov_retcode      => lv_retcode                    -- リターン・コード             --# 固定 #
        , ov_errmsg       => lv_errmsg                     -- ユーザー・エラー・メッセージ --# 固定 #
      );
      -- リターンコードが正常以外の場合
      IF ( lv_retcode <> cv_status_normal ) THEN
        -- 項目不備エラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application            -- アプリケーション短縮名
                       , iv_name         => cv_msg_xxcop_00070        -- メッセージコード
                       , iv_token_name1  => cv_tkn_row                -- トークンコード1
                       , iv_token_value1 => gn_record_no              -- トークン値1
                       , iv_token_name2  => cv_tkn_item               -- トークンコード2
                       , iv_token_value2 => g_chk_item_tab(i).meaning -- トークン値2
                       , iv_token_name3  => cv_tkn_value              -- トークンコード3
                       , iv_token_value3 => gt_csv_tab(i)             -- トークン値3
                       , iv_token_name4  => cv_tkn_errmsg             -- トークンコード4
                       , iv_token_value4 => lv_errmsg                 -- トークン値4
                     );
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg);
        -- 妥当性チェックエラー設定
        lb_item_check_flag := TRUE;
      END IF;
      --
    END LOOP item_check_loop;
    --
    -- 妥当性チェックエラーの場合
    IF ( lb_item_check_flag = TRUE ) THEN
      -- 妥当性チェックエラー例外
      RAISE global_chk_item_expt;
    END IF;
    --
    --==============================================================
    -- 3．年月チェック
    --==============================================================
    IF xxcop_common_pkg.chk_date_format( gt_csv_tab(1), cv_format_yyyymm ) = FALSE THEN
      -- DATE型チェックエラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application            -- アプリケーション短縮名
                     , iv_name         => cv_msg_xxcop_00071        -- メッセージコード
                     , iv_token_name1  => cv_tkn_row                -- トークンコード1
                     , iv_token_value1 => gn_record_no              -- トークン値1
                     , iv_token_name2  => cv_tkn_item               -- トークンコード2
                     , iv_token_value2 => g_chk_item_tab(1).meaning -- トークン値2
                     , iv_token_name3  => cv_tkn_value              -- トークンコード3
                     , iv_token_value3 => gt_csv_tab(1)             -- トークン値3
                   );
      -- メッセージ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg);
      -- 妥当性チェックエラー設定
      lb_item_check_flag := TRUE;
    ELSE
      -- チェックOKの場合、ローカル変数に設定
      lt_target_month := gt_csv_tab(1);
    END IF;
    --
    --==============================================================
    -- 4．担当拠点コードチェック
    --==============================================================
    SELECT COUNT(1)  AS cnt
    INTO   ln_chk_cnt
    FROM   xxcop_base_code_v xbcv         -- 計画_担当拠点ビュー
    WHERE  xbcv.base_code = gt_csv_tab(2) -- 拠点コード
    ;
    --
    -- 件数が0件の場合
    IF ( ln_chk_cnt = 0 ) THEN
      -- 担当拠点チェックエラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application            -- アプリケーション短縮名
                      , iv_name         => cv_msg_xxcop_00072        -- メッセージコード
                      , iv_token_name1  => cv_tkn_row                -- トークンコード1
                      , iv_token_value1 => gn_record_no              -- トークン値1
                      , iv_token_name2  => cv_tkn_item               -- トークンコード2
                      , iv_token_value2 => g_chk_item_tab(2).meaning -- トークン値2
                      , iv_token_name3  => cv_tkn_value              -- トークンコード3
                      , iv_token_value3 => gt_csv_tab(2)             -- トークン値3
                   );
      -- メッセージ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg);
      -- 妥当性チェックエラー設定
      lb_item_check_flag := TRUE;
    END IF;
    --
    --==============================================================
    -- 5．商品コードチェック
    --==============================================================
    BEGIN
      SELECT msib.inventory_item_id               AS inventory_item_id  -- 品目ID
            ,pc.prod_class                        AS prod_class         -- 商品区分
            ,TO_NUMBER( NVL( iimb.attribute11, cn_num_of_case_1 ) )
                                                  AS num_of_case        -- ケース入数
      INTO   lt_inventory_item_id
            ,lt_prod_class
            ,lt_num_of_case
      FROM   ic_item_mst_b          iimb     -- OPM品目
            ,xxcmn_item_mst_b       ximb     -- OPM品目アドオン
            ,xxcmm_system_items_b   xsib     -- Disc品目アドオン
            ,mtl_system_items_b     msib     -- Disc品目
            ,(SELECT gic_pc.item_id          AS item_id
                    ,mcv_pc.segment1         AS prod_class
              FROM   gmi_item_categories     gic_pc
                    ,mtl_category_sets_vl    mcsv_pc
                    ,mtl_categories_vl       mcv_pc
              WHERE  gic_pc.category_set_id    = mcsv_pc.category_set_id
              AND    mcsv_pc.category_set_name = gt_arti_div_code      -- カテゴリセット名(本社商品区分)
              AND    gic_pc.category_id        = mcv_pc.category_id
            ) pc  -- インラインビュー_本社商品区分
            ,(SELECT gic_ip.item_id          AS item_id
                    ,mcv_ip.segment1         AS item_prod_class
              FROM   gmi_item_categories     gic_ip
                    ,mtl_category_sets_vl    mcsv_ip
                    ,mtl_categories_vl       mcv_ip
              WHERE  gic_ip.category_set_id    = mcsv_ip.category_set_id
              AND    mcsv_ip.category_set_name = gt_product_div_code   -- カテゴリセット名(商品製品区分)
              AND    gic_ip.category_id        = mcv_ip.category_id
            ) ip  -- インラインビュー_商品製品区分
            ,(SELECT gic_ic.item_id          AS item_id
                    ,mcv_ic.segment1         AS item_class
              FROM   gmi_item_categories     gic_ic
                    ,mtl_category_sets_vl    mcsv_ic
                    ,mtl_categories_vl       mcv_ic
              WHERE  gic_ic.category_set_id    = mcsv_ic.category_set_id
              AND    mcsv_ic.category_set_name = gt_item_class         -- カテゴリセット名(品目区分)
              AND    gic_ic.category_id        = mcv_ic.category_id
            ) ic  -- インラインビュー_品目区分
      WHERE  iimb.item_id            = ximb.item_id
      AND    iimb.item_id            = pc.item_id
-- ********** Ver.1.1 K.Nakamura MOD Start ************ --
--      AND    iimb.item_id            = ic.item_id
      AND    iimb.item_id            = ic.item_id(+)
-- ********** Ver.1.1 K.Nakamura MOD End ************ --
      AND    iimb.item_id            = ip.item_id
      AND    iimb.item_no            = xsib.item_code
      AND    iimb.item_no            = msib.segment1
      AND    iimb.item_no            = gt_csv_tab(4)                              -- 商品コード
      AND    msib.organization_id    = gt_master_org_id                           -- マスタ組織ID
      AND    gd_process_date         BETWEEN ximb.start_date_active
                                     AND     ximb.end_date_active
      AND    ip.item_prod_class      = cv_item_prod_class_prod                    -- 製品
-- ********** Ver.1.1 K.Nakamura MOD Start ************ --
--      AND    ic.item_class           = cv_item_class_prod                         -- 製品
      AND    (  ( ic.item_class      = cv_item_class_prod )                       -- 製品
             OR ( ic.item_class      IS NULL ) )
-- ********** Ver.1.1 K.Nakamura MOD End ************ --
      AND    iimb.attribute18        = cv_shipment_on                             -- 出荷可
      AND    ximb.obsolete_class     = cv_obsolete_class_off                      -- 対象外
             -- 親品目かつ、品目ステータス「30：本登録」「40：廃」かつ、売上対象
      AND    (  (   iimb.item_id     = ximb.parent_item_id
                AND xsib.item_status IN ( cv_item_status_30 ,cv_item_status_40 )  -- 品目ステータス
                AND iimb.attribute26 = cv_sales_target_on )                       -- 売上対象
             -- 親品目かつ、品目ステータス「20：仮登録」
             OR (   iimb.item_id     = ximb.parent_item_id
                AND xsib.item_status = cv_item_status_20                          -- 品目ステータス
                )
             -- 子品目かつ、品目ステータス「20：仮登録」「30：本登録」「40：廃」
             OR (iimb.item_id        <> ximb.parent_item_id
                AND xsib.item_status IN ( cv_item_status_20 ,cv_item_status_30 ,cv_item_status_40 )
                )
             )
      AND    xsib.item_status_apply_date <= gd_process_date
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- トークン値を設定
        gv_tkn_4  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_00087 );
        -- マスタ未登録エラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application            -- アプリケーション短縮名
                        , iv_name         => cv_msg_xxcop_00073        -- メッセージコード
                        , iv_token_name1  => cv_tkn_row                -- トークンコード1
                        , iv_token_value1 => gn_record_no              -- トークン値1
                        , iv_token_name2  => cv_tkn_item               -- トークンコード2
                        , iv_token_value2 => g_chk_item_tab(4).meaning -- トークン値2
                        , iv_token_name3  => cv_tkn_value              -- トークンコード3
                        , iv_token_value3 => gt_csv_tab(4)             -- トークン値3
                        , iv_token_name4  => cv_tkn_table              -- トークンコード4
                        , iv_token_value4 => gv_tkn_4                  -- トークン値4
                     );
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg);
        -- 妥当性チェックエラー設定
        lb_item_check_flag := TRUE;
    END;
    --
    --==============================================================
    -- 6．出荷元倉庫設定
    --==============================================================
    -- 出荷元倉庫が未設定かつ、ローカル変数_商品区分が取得できた場合
    IF ( gt_csv_tab(3) IS NULL ) AND ( lt_prod_class IS NOT NULL ) THEN
      -- リーフの場合
      IF ( lt_prod_class = cv_prod_class_leaf ) THEN
        lt_whse_code  := gt_whse_code_leaf;   -- プロファイル：出荷元倉庫_リーフ
      -- ドリンクの場合
      ELSE
        lt_whse_code  := gt_whse_code_drink;  -- プロファイル：出荷元倉庫_ドリンク
      END IF;
    -- 出荷元倉庫に値が設定されている場合
    ELSIF ( gt_csv_tab(3) IS NOT NULL ) THEN
      lt_whse_code    := gt_csv_tab(3);
    -- 上記以外の場合
    ELSE
      lt_whse_code    := NULL;
      --
      -- 出荷元倉庫設定エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application      -- アプリケーション短縮名
                      , iv_name         => cv_msg_xxcop_10065  -- メッセージコード
                      , iv_token_name1  => cv_tkn_row          -- トークンコード1
                      , iv_token_value1 => gn_record_no        -- トークン値1
                   );
      -- メッセージ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg);
      -- 妥当性チェックエラー設定
      lb_item_check_flag := TRUE;
    END IF;
    --
    --==============================================================
    -- 7．出荷元倉庫チェック
    --==============================================================
    -- ローカル変数_出荷元倉庫が設定されている場合
    IF ( lt_whse_code IS NOT NULL ) THEN
      BEGIN
        SELECT hla.attribute1  AS whse_type     -- DFF1(出荷管理元区分)
        INTO   lt_whse_type
        FROM   ic_whse_mst                iwm   -- OPM倉庫マスタ
              ,mtl_item_locations         mil   -- OPM保管場所マスタ
              ,hr_all_organization_units  haou  -- 在庫組織マスタ
              ,hr_locations_all           hla   -- 事業所マスタ
        WHERE  iwm.mtl_organization_id = haou.organization_id
        AND    haou.organization_id    = mil.organization_id
        AND    mil.segment1            = lt_whse_code  -- ローカル変数_出荷元倉庫
        AND    iwm.whse_code           = hla.location_code
        AND    gd_process_date         BETWEEN haou.date_from
                                       AND     NVL( haou.date_to, gd_process_date )
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- トークン値を設定
          gv_tkn_4  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_00086 );
          -- マスタ未登録エラーメッセージ
          lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application            -- アプリケーション短縮名
                          , iv_name         => cv_msg_xxcop_00073        -- メッセージコード
                          , iv_token_name1  => cv_tkn_row                -- トークンコード1
                          , iv_token_value1 => gn_record_no              -- トークン値1
                          , iv_token_name2  => cv_tkn_item               -- トークンコード2
                          , iv_token_value2 => g_chk_item_tab(3).meaning -- トークン値2
                          , iv_token_name3  => cv_tkn_value              -- トークンコード3
                          , iv_token_value3 => lt_whse_code              -- トークン値3
                          , iv_token_name4  => cv_tkn_table              -- トークンコード4
                          , iv_token_value4 => gv_tkn_4                  -- トークン値4
                       );
          -- メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg);
          -- 妥当性チェックエラー設定
          lb_item_check_flag := TRUE;
      END;
    END IF;
    --
    --==============================================================
    -- 8．出荷元倉庫と商品コードの整合性チェック
    --==============================================================
    -- 出荷管理区分と商品区分が不一致の場合はエラー
    IF ( lt_whse_type IS NOT NULL ) AND ( lt_prod_class IS NOT NULL ) THEN
      IF ( lt_whse_type <> cv_prod_class_both ) AND ( lt_whse_type <> lt_prod_class ) THEN
        -- トークン値を設定
        gv_tkn_2  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_00088 );
        gv_tkn_4  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_00089 );
        -- 不整合エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application            -- アプリケーション短縮名
                        , iv_name         => cv_msg_xxcop_00074        -- メッセージコード
                        , iv_token_name1  => cv_tkn_row                -- トークンコード1
                        , iv_token_value1 => gn_record_no              -- トークン値1
                        , iv_token_name2  => cv_tkn_item1              -- トークンコード2
                        , iv_token_value2 => gv_tkn_2                  -- トークン値2
                        , iv_token_name3  => cv_tkn_value1             -- トークンコード3
                        , iv_token_value3 => lt_whse_type              -- トークン値3
                        , iv_token_name4  => cv_tkn_item2              -- トークンコード4
                        , iv_token_value4 => gv_tkn_4                  -- トークン値4
                        , iv_token_name5  => cv_tkn_value2             -- トークンコード5
                        , iv_token_value5 => lt_prod_class             -- トークン値5
                     );
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg);
        -- 妥当性チェックエラー設定
        lb_item_check_flag := TRUE;
      END IF;
    END IF;
    --
    -- 以下9、10のチェックは上記3がエラーではない場合に実行
    IF ( lt_target_month IS NOT NULL ) THEN
      --==============================================================
      -- 9．便数存在チェック
      --==============================================================
      -- リーフかつ、ローカル変数_出荷管理元区分が設定されている場合
      IF ( lt_prod_class = cv_prod_class_leaf ) AND ( lt_whse_type IS NOT NULL ) THEN
        BEGIN
          SELECT wl.forecast_date AS forecast_date  -- フォーキャスト日付
          INTO   lt_forecast_date
          FROM   (SELECT ROW_NUMBER() OVER ( ORDER BY xldos.target_month, xldos.day_of_service )    AS service_no
                        ,TO_DATE( xldos.target_month || LPAD( xldos.day_of_service, cn_pad_2, cv_ins_0 ), cv_format_yyyymmdd )
                                                                                                    AS forecast_date
                  FROM   xxcop_leaf_day_of_service xldos      -- リーフ便表
                  WHERE  xldos.whse_code    = lt_whse_code    -- 出荷元倉庫
                  AND    xldos.base_code    = gt_csv_tab(2)   -- 拠点コード
                  AND    xldos.target_month = lt_target_month -- 年月
                 ) wl
          WHERE wl.service_no               = gt_csv_tab(5)   -- 便数
          ;
          --
          -- 稼働日チェック用日付を設定
          lt_chk_forecast_date := mrp_calendar.next_work_day(
                                  gt_sales_org_id          -- 営業組織ID
                                 ,cn_bucket_type           -- バケットタイプ
                                 ,lt_forecast_date         -- ローカル変数_日付
                                  );
          --
          -- ローカル変数_日付と稼働日チェック用日付が一致しない場合はエラー
          IF ( lt_forecast_date <> lt_chk_forecast_date ) THEN
            -- トークン値を設定
            gv_tkn_3  := TO_CHAR( lt_forecast_date ,cv_format_std_yyyymmdd );
            -- 便稼働日チェックエラー
            lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application            -- アプリケーション短縮名
                            , iv_name         => cv_msg_xxcop_10068        -- メッセージコード
                            , iv_token_name1  => cv_tkn_row                -- トークンコード1
                            , iv_token_value1 => gn_record_no              -- トークン値1
                            , iv_token_name2  => cv_tkn_value1             -- トークンコード2
                            , iv_token_value2 => gt_csv_tab(5)             -- トークン値2
                            , iv_token_name3  => cv_tkn_value2             -- トークンコード3
                            , iv_token_value3 => gv_tkn_3                  -- トークン値3
                         );
            -- メッセージ出力
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg);
            -- 妥当性チェックエラー設定
            lb_item_check_flag := TRUE;
          END IF;
        --
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- トークン値を設定
            gv_tkn_4  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_00084 );
            -- マスタ未登録エラーメッセージ
            lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application            -- アプリケーション短縮名
                            , iv_name         => cv_msg_xxcop_00073        -- メッセージコード
                            , iv_token_name1  => cv_tkn_row                -- トークンコード1
                            , iv_token_value1 => gn_record_no              -- トークン値1
                            , iv_token_name2  => cv_tkn_item               -- トークンコード2
                            , iv_token_value2 => g_chk_item_tab(5).meaning -- トークン値2
                            , iv_token_name3  => cv_tkn_value              -- トークンコード3
                            , iv_token_value3 => gt_csv_tab(5)             -- トークン値3
                            , iv_token_name4  => cv_tkn_table              -- トークンコード4
                            , iv_token_value4 => gv_tkn_4                  -- トークン値4
                         );
            -- メッセージ出力
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg);
            -- 妥当性チェックエラー設定
            lb_item_check_flag := TRUE;
        END;
      --
      -- ドリンクの場合
      ELSIF ( lt_prod_class = cv_prod_class_drink ) THEN
        BEGIN
          SELECT wd.forecast_date AS forecast_date  -- フォーキャスト日付
          INTO   lt_forecast_date
          FROM (SELECT ROW_NUMBER() OVER ( ORDER BY tmp.forecast_date )  AS service_no
                      ,tmp.forecast_date                                 AS forecast_date
                FROM (SELECT mrp_calendar.next_work_day(
                             gt_sales_org_id          -- 営業組織ID
                            ,cn_bucket_type           -- バケットタイプ
                            ,TRUNC( ADD_MONTHS( TO_DATE( lt_target_month    -- 年月
                               || LPAD( TO_NUMBER( flv.description ), cn_pad_2, cv_ins_0 ), cv_format_yyyymmdd )
                              ,TO_NUMBER( flv.attribute1 ) ) )
                             )  AS forecast_date
                      FROM   fnd_lookup_values flv
                      WHERE  flv.lookup_type                                = cv_forecast_date
                      AND    flv.language                                   = ct_lang
                      AND    flv.enabled_flag                               = cv_flag_y
                      AND    NVL( flv.start_date_active, gd_process_date ) <= gd_process_date
                      AND    NVL( flv.end_date_active  , gd_process_date ) >= gd_process_date
                      ) tmp
               ) wd
          WHERE wd.service_no                                               = gt_csv_tab(5) -- 便数
          ;
          --
          -- 対象期間内チェック
          IF ( lt_forecast_date < gd_process_date - gn_limit_forecast ) THEN
            -- トークン値を設定
            gv_tkn_4  := TO_CHAR( lt_forecast_date ,cv_format_std_yyyymmdd );
            -- 引取計画対象期間外エラー
            lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application            -- アプリケーション短縮名
                            , iv_name         => cv_msg_xxcop_10064        -- メッセージコード
                            , iv_token_name1  => cv_tkn_row                -- トークンコード1
                            , iv_token_value1 => gn_record_no              -- トークン値1
                            , iv_token_name2  => cv_tkn_value1             -- トークンコード2
                            , iv_token_value2 => gn_limit_forecast         -- トークン値2
                            , iv_token_name3  => cv_tkn_value2             -- トークンコード3
                            , iv_token_value3 => gt_csv_tab(5)             -- トークン値3
                            , iv_token_name4  => cv_tkn_value3             -- トークンコード4
                            , iv_token_value4 => gv_tkn_4                  -- トークン値4
                         );
            -- メッセージ出力
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg);
            -- 妥当性チェックエラー設定
            lb_item_check_flag := TRUE;
          END IF;
        --
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- トークン値を設定
            gv_tkn_4  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_00085 )
                         ||'( '|| cv_forecast_date ||' )';
            -- マスタ未登録エラーメッセージ
            lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application            -- アプリケーション短縮名
                            , iv_name         => cv_msg_xxcop_00073        -- メッセージコード
                            , iv_token_name1  => cv_tkn_row                -- トークンコード1
                            , iv_token_value1 => gn_record_no              -- トークン値1
                            , iv_token_name2  => cv_tkn_item               -- トークンコード2
                            , iv_token_value2 => g_chk_item_tab(5).meaning -- トークン値2
                            , iv_token_name3  => cv_tkn_value              -- トークンコード3
                            , iv_token_value3 => gt_csv_tab(5)             -- トークン値3
                            , iv_token_name4  => cv_tkn_table              -- トークンコード4
                            , iv_token_value4 => gv_tkn_4                  -- トークン値4
                         );
            -- メッセージ出力
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg);
            -- 妥当性チェックエラー設定
            lb_item_check_flag := TRUE;
        END;
      END IF;
      --
      --==============================================================
      -- 10．年月と日付の整合性チェック
      --==============================================================
      IF ( lt_forecast_date IS NOT NULL ) THEN
        -- 日付の年月を取得
        lv_forecast_month := TO_CHAR( lt_forecast_date ,cv_format_yyyymm );
        -- フォーキャスト日付の年月とCSVファイルの年月が不一致の場合はエラー
        IF ( lv_forecast_month <> lt_target_month ) THEN
          -- トークン値を設定
          gv_tkn_2  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_00082 ) ||
                       xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_00092 );
          -- 不整合エラーメッセージ
          lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application             -- アプリケーション短縮名
                          , iv_name         => cv_msg_xxcop_00074         -- メッセージコード
                          , iv_token_name1  => cv_tkn_row                 -- トークンコード1
                          , iv_token_value1 => gn_record_no               -- トークン値1
                          , iv_token_name2  => cv_tkn_item1               -- トークンコード2
                          , iv_token_value2 => gv_tkn_2                   -- トークン値2
                          , iv_token_name3  => cv_tkn_value1              -- トークンコード3
                          , iv_token_value3 => lv_forecast_month          -- トークン値3
                          , iv_token_name4  => cv_tkn_item2               -- トークンコード4
                          , iv_token_value4 => g_chk_item_tab(1).meaning  -- トークン値4
                          , iv_token_name5  => cv_tkn_value2              -- トークンコード5
                          , iv_token_value5 => lt_target_month            -- トークン値5
                       );
          -- メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg);
          -- 妥当性チェックエラー設定
          lb_item_check_flag := TRUE;
        END IF;
      END IF;
    END IF;
    --
    --==============================================================
    -- 11．計画数量チェック
    --==============================================================
    -- 計画数量が範囲内であるかチェック
    IF ( gt_csv_tab(6) < cn_case_count_min ) OR ( gt_csv_tab(6) > cn_case_count_max ) THEN
      -- 範囲外エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application            -- アプリケーション短縮名
                      , iv_name         => cv_msg_xxcop_00077        -- メッセージコード
                      , iv_token_name1  => cv_tkn_row                -- トークンコード1
                      , iv_token_value1 => gn_record_no              -- トークン値1
                      , iv_token_name2  => cv_tkn_item               -- トークンコード2
                      , iv_token_value2 => g_chk_item_tab(6).meaning -- トークン値2
                      , iv_token_name3  => cv_tkn_value1             -- トークンコード3
                      , iv_token_value3 => gt_csv_tab(6)             -- トークン値3
                      , iv_token_name4  => cv_tkn_value2             -- トークンコード4
                      , iv_token_value4 => cn_case_count_min         -- トークン値4
                      , iv_token_name5  => cv_tkn_value3             -- トークンコード5
                      , iv_token_value5 => cn_case_count_max         -- トークン値5
                   );
      -- メッセージ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg);
      -- 妥当性チェックエラー設定
      lb_item_check_flag := TRUE;
    END IF;
    --
    --==============================================================
    -- 12．フォーキャスト名存在チェック
    --==============================================================
    -- ローカル変数_出荷管理元区分が設定されている場合
    IF ( lt_whse_type IS NOT NULL ) THEN
      --
      BEGIN
        SELECT mfds.forecast_designator  AS forecast_designator  -- フォーキャスト名
        INTO   lt_forecast_designator
        FROM   mrp_forecast_designators mfds                   -- フォーキャスト名
        WHERE  mfds.organization_id     = gt_master_org_id     -- マスタ組織ID
        AND    mfds.attribute1          = cv_forecast_type_01  -- FORECAST分類
        AND    mfds.attribute2          = lt_whse_code         -- 出荷元倉庫
        AND    mfds.attribute3          = gt_csv_tab(2)        -- 拠点コード
        AND  ( mfds.disable_date        IS NULL
          OR   mfds.disable_date        > gd_process_date )
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- マスタ未登録エラーメッセージ
          lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application            -- アプリケーション短縮名
                          , iv_name         => cv_msg_xxcop_10066        -- メッセージコード
                          , iv_token_name1  => cv_tkn_row                -- トークンコード1
                          , iv_token_value1 => gn_record_no              -- トークン値1
                          , iv_token_name2  => cv_tkn_value1             -- トークンコード2
                          , iv_token_value2 => cv_forecast_type_01       -- トークン値2
                          , iv_token_name3  => cv_tkn_value2             -- トークンコード3
                          , iv_token_value3 => lt_whse_code              -- トークン値3
                          , iv_token_name4  => cv_tkn_value3             -- トークンコード4
                          , iv_token_value4 => gt_csv_tab(2)             -- トークン値4
                       );
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg);
        -- 妥当性チェックエラー設定
        lb_item_check_flag := TRUE;
      END;
    END IF;
    --
    --==============================================================
    -- 13．引取計画IF表登録
    --==============================================================
    -- 妥当性チェックでエラーがない場合は引取計画IF表に登録
    IF ( lb_item_check_flag = FALSE ) THEN
      BEGIN
        INSERT INTO xxcop_mrp_forecast_interface(
            file_id                   -- ファイルID
          , record_no                 -- レコードNo
          , target_month              -- 年月
          , base_code                 -- 拠点コード
          , whse_code                 -- 出荷元倉庫
          , item_code                 -- 商品コード
          , service_no                -- 便数
          , case_count                -- 計画数量
          , inventory_item_id         -- 品目ID
          , num_of_case               -- ケース入数
          , forecast_date             -- 日付
          , forecast_designator       -- フォーキャスト名
        ) VALUES (
            TO_NUMBER(iv_file_id)     -- ファイルID
          , gn_record_no              -- レコードNo
          , lt_target_month           -- 年月
          , gt_csv_tab(2)             -- 拠点コード
          , lt_whse_code              -- 出荷元倉庫
          , gt_csv_tab(4)             -- 商品コード
          , gt_csv_tab(5)             -- 便数
          , gt_csv_tab(6)             -- 計画数量
          , lt_inventory_item_id      -- 品目ID
          , lt_num_of_case            -- ケース入数
          , lt_forecast_date          -- 日付
          , lt_forecast_designator    -- フォーキャスト名
        );
      EXCEPTION
        WHEN OTHERS THEN
          -- トークン値を設定
          gv_tkn_1  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_10058 );
          -- 登録処理エラーメッセージ
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application        -- アプリケーション短縮名
                         , iv_name         => cv_msg_xxcop_00027    -- メッセージコード
                         , iv_token_name1  => cv_tkn_table          -- トークンコード1
                         , iv_token_value1 => gv_tkn_1              -- トークン値1
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    END IF;
--
    --==============================================================
    -- 14．便重複チェック
    --==============================================================
    SELECT COUNT(1)  AS cnt      -- チェック用件数
    INTO   ln_chk_cnt
    FROM   xxcop_mrp_forecast_interface xmfi
    WHERE  xmfi.target_month  = lt_target_month  -- 年月
    AND    xmfi.base_code     = gt_csv_tab(2)    -- 拠点コード
    AND    xmfi.whse_code     = lt_whse_code     -- 出荷元倉庫
    AND    xmfi.item_code     = gt_csv_tab(4)    -- 商品コード
    AND    xmfi.service_no    = gt_csv_tab(5)    -- 便
    AND    xmfi.record_no    <> gn_record_no
    ;
    -- 件数が1件以上の場合
    IF ( ln_chk_cnt > 0 ) THEN
      -- 重複エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application            -- アプリケーション短縮名
                      , iv_name         => cv_msg_xxcop_10069        -- メッセージコード
                      , iv_token_name1  => cv_tkn_row                -- トークンコード1
                      , iv_token_value1 => gn_record_no              -- トークン値1
                      , iv_token_name2  => cv_tkn_value1             -- トークンコード2
                      , iv_token_value2 => lt_target_month           -- トークン値2
                      , iv_token_name3  => cv_tkn_value2             -- トークンコード3
                      , iv_token_value3 => gt_csv_tab(2)             -- トークン値3
                      , iv_token_name4  => cv_tkn_value3             -- トークンコード4
                      , iv_token_value4 => lt_whse_code              -- トークン値4
                      , iv_token_name5  => cv_tkn_value4             -- トークンコード5
                      , iv_token_value5 => gt_csv_tab(4)             -- トークン値5
                      , iv_token_name6  => cv_tkn_value5             -- トークンコード6
                      , iv_token_value6 => gt_csv_tab(5)             -- トークン値6
                   );
      -- メッセージ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg);
      -- 妥当性チェックエラー設定
      lb_item_check_flag := TRUE;
    END IF;
--
  -- 妥当性チェックエラーの場合
  IF ( lb_item_check_flag = TRUE ) THEN
    -- 妥当性チェック例外
    RAISE global_chk_item_expt;
  END IF;
--
  EXCEPTION
--
    -- 妥当性チェック例外ハンドラ
    WHEN global_chk_item_expt THEN
      ov_retcode := cv_status_error;
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
   * Procedure Name   : exec_api_forecast_if
   * Description      : 需要API実行(A-5)
   ***********************************************************************************/
  PROCEDURE exec_api_forecast_if(
      ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ           --# 固定 #
    , ov_retcode OUT VARCHAR2 -- リターン・コード             --# 固定 #
    , ov_errmsg  OUT VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'exec_api_forecast_if'; -- プログラム名
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
    lt_transaction_id     mrp_forecast_dates.transaction_id%TYPE;  -- トランザクションID
    lt_attribute5         mrp_forecast_dates.attribute5%TYPE;      -- DFF5(拠点)
    lt_attribute6         mrp_forecast_dates.attribute6%TYPE;      -- DFF6(計画数量)
    lt_creation_date      mrp_forecast_dates.creation_date%TYPE;   -- 作成日
    lt_created_by         mrp_forecast_dates.created_by%TYPE;      -- 作成者
    ln_forecast_quantity  NUMBER;                                  -- フォーキャスト数量
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    t_forecast_interface_tab    mrp_forecast_interface_pk.t_forecast_interface;  -- 需要API：フォーキャスト日付
    lb_api                      BOOLEAN;                                         -- 需要API：返却値
--
    -- *** ローカルユーザー定義例外 ***
    exec_api_forecast_expt    EXCEPTION;  -- 需要API失敗例外
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
    -- 1．フォーキャスト日付情報取得
    --==============================================================
    BEGIN
      SELECT mfdt.transaction_id  AS transaction_id  -- トランザクションID
            ,mfdt.creation_date   AS creation_date   -- 作成日
            ,mfdt.created_by      AS created_by      -- 作成者
      INTO   lt_transaction_id
            ,lt_creation_date
            ,lt_created_by
      FROM   mrp_forecast_dates mfdt  -- フォーキャスト日付
      WHERE  mfdt.organization_id     = gt_master_org_id                     -- マスタ組織ID
      AND    mfdt.forecast_designator = forecast_if_rec.forecast_designator  -- フォーキャスト名
      AND    mfdt.inventory_item_id   = forecast_if_rec.inventory_item_id    -- 品目ID
      AND    mfdt.forecast_date       = forecast_if_rec.forecast_date        -- フォーキャスト日付
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      --
      WHEN NO_DATA_FOUND THEN
        -- 取得できない場合は、新規レコードとして変数にNULLを設定
        lt_transaction_id := NULL;
-- ********** Ver.1.1 K.Nakamura ADD Start ************ --
        -- 新規レコードかつ計画数量が0の場合、登録しない
        IF ( forecast_if_rec.case_count = 0 ) THEN
          RAISE global_no_insert_expt;
        END IF;
-- ********** Ver.1.1 K.Nakamura ADD End ************ --
      -- ロック取得例外ハンドラ
      WHEN global_lock_expt THEN
        -- トークン値を設定
        gv_tkn_1  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_00082 );
        --
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
    --==============================================================
    -- 2．需要API実行
    --==============================================================
    -- フォーキャスト数量の算出（計画数量 * ケース入数）
    ln_forecast_quantity := forecast_if_rec.case_count * forecast_if_rec.num_of_case;
--
    -- 登録の場合
    IF ( lt_transaction_id IS NULL ) THEN
      lt_attribute5       := forecast_if_rec.base_code;   -- DFF5(拠点コード)
      lt_attribute6       := forecast_if_rec.case_count;  -- DFF6(計画数量)
      lt_creation_date    := cd_creation_date;            -- 作成日
      lt_created_by       := cn_created_by;               -- 作成者
    ELSE
      -- 更新の場合
      IF ( ln_forecast_quantity <> 0 ) THEN
        lt_attribute5     := forecast_if_rec.base_code;   -- DFF5(拠点コード)
        lt_attribute6     := forecast_if_rec.case_count;  -- DFF6(計画数量)
      ELSE
        -- 削除の場合
        lt_attribute5     := NULL;                        -- DFF5(拠点コード)
        lt_attribute6     := NULL;                        -- DFF6(計画数量)
      END IF;
    END IF;
    --
    -- 需要APIパラメータの初期化
    t_forecast_interface_tab.DELETE;
    --
    -- パラメータセット（フォーキャスト日付）
    t_forecast_interface_tab(1).inventory_item_id       := forecast_if_rec.inventory_item_id;     -- 品目ID
    t_forecast_interface_tab(1).forecast_designator     := forecast_if_rec.forecast_designator;   -- フォーキャスト名
    t_forecast_interface_tab(1).organization_id         := gt_master_org_id;                      -- マスタ組織ID
    t_forecast_interface_tab(1).forecast_date           := forecast_if_rec.forecast_date;         -- フォーキャスト日付
    t_forecast_interface_tab(1).last_update_date        := cd_last_update_date;                   -- 最終更新日
    t_forecast_interface_tab(1).last_updated_by         := cn_last_updated_by;                    -- 最終更新者
    t_forecast_interface_tab(1).creation_date           := lt_creation_date;                      -- 作成日
    t_forecast_interface_tab(1).created_by              := lt_created_by;                         -- 作成者
    t_forecast_interface_tab(1).last_update_login       := cn_last_update_login;                  -- 最終更新ログイン
    t_forecast_interface_tab(1).quantity                := ln_forecast_quantity;                  -- フォーキャスト数量
    t_forecast_interface_tab(1).process_status          := cn_process_status;                     -- process_status
    t_forecast_interface_tab(1).confidence_percentage   := cn_confidence_percentage;              -- confidence_percentage
    t_forecast_interface_tab(1).bucket_type             := cn_bucket_type;                        -- バケット・タイプ
    t_forecast_interface_tab(1).transaction_id          := lt_transaction_id;                     -- トランザクションID
    t_forecast_interface_tab(1).attribute5              := lt_attribute5;                         -- DFF5(拠点)
    t_forecast_interface_tab(1).attribute6              := lt_attribute6;                         -- DFF6(計画数量)
--
    -- 需要APIの実行
    lb_api := mrp_forecast_interface_pk.mrp_forecast_interface(
                t_forecast_interface_tab
              );
    -- 戻り値が正常以外
    IF ( t_forecast_interface_tab(1).process_status <> cn_api_ret_normal ) THEN
      -- API起動エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application             -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcop_00076         -- メッセージコード
                     ,iv_token_name1  => cv_tkn_row                 -- トークンコード1
                     ,iv_token_value1 => forecast_if_rec.record_no  -- トークン値1
                     ,iv_token_name2  => cv_tkn_prg_name            -- トークンコード2
                     ,iv_token_value2 => cv_api_name                -- トークン値2
                     ,iv_token_name3  => cv_tkn_errmsg              -- トークンコード3
                     ,iv_token_value3 => SQLERRM                    -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 成功件数
    gn_normal_cnt := gn_normal_cnt + 1;
--
  EXCEPTION
-- ********** Ver.1.1 K.Nakamura ADD Start ************ --
    -- *** 登録対象外例外ハンドラ ***
    WHEN global_no_insert_expt THEN
      -- 成功件数への出力やメッセージ出力も行なわない
      ov_retcode := cv_status_normal;
-- ********** Ver.1.1 K.Nakamura ADD End ************ --
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
  END exec_api_forecast_if;
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
    -- ファイルアップロード削除
    --==============================================================
    --ファイルアップロードテーブルデータ削除処理
    xxcop_common_pkg.delete_upload_table(
        ov_retcode => lv_retcode                -- リターン・コード
      , ov_errbuf  => lv_errbuf                 -- エラー・メッセージ
      , ov_errmsg  => lv_errmsg                 -- ユーザー・エラー・メッセージ
      , in_file_id => TO_NUMBER(iv_file_id)     -- ファイルID
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- トークン値を設定
      gv_tkn_1  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_00079 );
      --
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
    , iv_format  IN  VARCHAR2 -- フォーマット
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
    lv_errbuf            VARCHAR2(5000)   DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode           VARCHAR2(1)      DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg            VARCHAR2(5000)   DEFAULT NULL;              -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_validate_retcode  VARCHAR2(1)      DEFAULT cv_status_normal;  -- 妥当性チェックリターン・コード
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
    gn_normal_cnt  := 0;
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
      , iv_format  => iv_format  -- フォーマット
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
    -- ファイルアップロードデータ取得処理(A-2)
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
    -- 引取計画IF表登録ループ
    << ins_if_loop >>
    FOR i IN gt_file_data.FIRST .. gt_file_data.COUNT LOOP
      -- カウントアップ
      gn_line_cnt := gn_line_cnt + 1;
      -- ===============================================
      -- 妥当性チェック処理(A-3)
      -- ===============================================
      chk_validate_item(
          iv_file_id => iv_file_id -- ファイルID
        , iv_format  => iv_format  -- フォーマット
        , ov_errbuf  => lv_errbuf  -- エラー・メッセージ
        , ov_retcode => lv_retcode -- リターン・コード
        , ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ
      );
      -- 妥当性チェックエラー
      IF ( lv_retcode = cv_status_error ) THEN
        lv_validate_retcode := cv_status_error;
      END IF;
      --
    END LOOP ins_if_loop;
--
    -- 全レコード妥当性チェック後にエラー判定
    IF ( lv_validate_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- 引取計画IF表データ取得処理(A-4)
    -- ===============================================
    -- カーソルオープン
    OPEN forecast_if_cur( iv_file_id );
    -- フォーキャスト日付登録ループ
    << ins_forecast_loop >>
    LOOP
      -- フェッチ
      FETCH forecast_if_cur INTO forecast_if_rec;
      EXIT WHEN forecast_if_cur%NOTFOUND;
      --
      -- ===============================================
      -- 需要API実行(A-5)
      -- ===============================================
      exec_api_forecast_if(
          ov_errbuf  => lv_errbuf  -- エラー・メッセージ
        , ov_retcode => lv_retcode -- リターン・コード
        , ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      --
    END LOOP ins_forecast_loop;
    -- カーソルクローズ
    CLOSE forecast_if_cur;
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
      IF ( forecast_if_cur%ISOPEN ) THEN
        CLOSE forecast_if_cur;
      END IF;
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
    , iv_format  IN  VARCHAR2 -- フォーマット
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
    cv_target_rec_msg  CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_normal_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
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
      , iv_format  => iv_format  -- フォーマット
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
    -- エラー出力
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
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      -- 終了ステータスをエラーにする
      lv_retcode := cv_status_error;
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
    -- 成功件数出力
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
END XXCOP004A09C;
/
