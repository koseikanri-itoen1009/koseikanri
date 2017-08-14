CREATE OR REPLACE PACKAGE BODY APPS.XXCMM004A13C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * Package Name     : XXCMM004A13C(body)
 * Description      : 変更予約情報一括登録
 * MD.050           : 変更予約情報一括登録 MD050_CMM_004_A13
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  validate_data          妥当性チェック処理(A-4)
 *  ins_item_chg_data      変更予約情報登録処理(A-5)
 *  del_item_chg_data      変更予約情報削除処理(A-6)
 *  loop_main              一時表取得処理(A-3)、妥当性チェック処理(A-4)
 *  get_if_data            ファイルアップロードデータ取得処理(A-2)
 *  del_if_data            ファイルアップロードデータ削除処理(A-7)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                         終了処理(A-8)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2017/07/19    1.0   S.Niki           E_本稼動_14300対応 新規作成
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
  --*** ロックエラー例外 ***
  global_check_lock_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt, -20000);
  PRAGMA EXCEPTION_INIT(global_check_lock_expt, -54);
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
  cv_appl_name_xxcmm       CONSTANT VARCHAR2(5)   := 'XXCMM';               -- アプリケーション短縮名
  cv_pkg_name              CONSTANT VARCHAR2(100) := 'XXCMM004A13C';        -- パッケージ名
  cv_msg_comma             CONSTANT VARCHAR2(1)   := ',';                   -- カンマ
  cv_file_format           CONSTANT VARCHAR2(3)   := '540';                 -- 変更予約情報一括登録
--
  -- データ項目定義用
  cv_varchar               CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_varchar;        -- 文字列
  cv_number                CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_number;         -- 数値
  cv_date                  CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_date;           -- 日付
  cv_varchar_cd            CONSTANT VARCHAR2(1)   := xxcmm_004common_pkg.cv_varchar_cd;     -- 文字列項目
  cv_number_cd             CONSTANT VARCHAR2(1)   := xxcmm_004common_pkg.cv_number_cd;      -- 数値項目
  cv_date_cd               CONSTANT VARCHAR2(1)   := xxcmm_004common_pkg.cv_date_cd;        -- 日付項目
  cv_not_null              CONSTANT VARCHAR2(1)   := xxcmm_004common_pkg.cv_not_null;       -- 必須
  cv_null_ok               CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_null_ok;        -- 任意項目
  cv_null_ng               CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_null_ng;        -- 必須項目
--
  -- プロファイル名
  cv_prf_item_num          CONSTANT VARCHAR2(60)  := 'XXCMM1_004A13_ITEM_NUM';         -- XXCMM:変更予約情報一括登録データ項目数
  cv_prf_org_code          CONSTANT VARCHAR2(60)  := 'XXCOI1_ORGANIZATION_CODE';       -- XXCOI:在庫組織コード
--
  -- LOOKUP表
  cv_lookup_file_up_obj    CONSTANT VARCHAR2(30)  := 'XXCCP1_FILE_UPLOAD_OBJ';         -- ファイルアップロードオブジェクト
  cv_lookup_item_def       CONSTANT VARCHAR2(30)  := 'XXCMM1_004A13_ITEM_DEF';         -- 変更予約情報一括登録データ項目定義
  cv_lookup_item_status    CONSTANT VARCHAR2(30)  := 'XXCMM_ITM_STATUS';               -- 品目ステータス
--
  -- メッセージ
  cv_msg_xxcmm_00018       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00018';      -- 業務日付取得エラー
  cv_msg_xxcmm_00002       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00002';      -- プロファイル取得エラー
  cv_msg_xxcmm_10429       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10429';      -- 取得失敗エラー
  cv_msg_xxcmm_00402       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00402';      -- IFロック取得エラー
  cv_msg_xxcmm_00021       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00021';      -- 組織ID取得エラーメッセージ
  cv_msg_xxcmm_00015       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00015';      -- ファイルアップロード名称ノート
  cv_msg_xxcmm_00022       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00022';      -- CSVファイル名ノート
  cv_msg_xxcmm_00023       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00023';      -- FILE_IDノート
  cv_msg_xxcmm_00024       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00024';      -- フォーマットノート
  cv_msg_xxcmm_00028       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00028';      -- データ項目数エラー
  cv_msg_xxcmm_00403       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00403';      -- ファイル項目チェックエラー
  cv_msg_xxcmm_10328       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10328';      -- 値チェックエラー
  cv_msg_xxcmm_10330       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10330';      -- 参照コード存在チェックエラー
  cv_msg_xxcmm_10481       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10481';      -- IFデータ削除エラー
  cv_msg_xxcmm_10461       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10461';      -- 項目未入力エラー
  cv_msg_xxcmm_10462       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10462';      -- 親品目継承項目入力エラー
  cv_msg_xxcmm_10463       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10463';      -- 適用日過去日エラー
  cv_msg_xxcmm_10464       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10464';      -- 品目重複エラー
  cv_msg_xxcmm_10465       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10465';      -- 対象レコード存在チェックエラー
  cv_msg_xxcmm_10466       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10466';      -- 対象レコード非存在チェックエラー
  cv_msg_xxcmm_10467       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10467';      -- 品目ステータス廃止エラー
  cv_msg_xxcmm_10468       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10468';      -- 品目ステータス子品目エラー
  cv_msg_xxcmm_10469       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10469';      -- 品目ステータスフローエラー
  cv_msg_xxcmm_10470       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10470';      -- 品目ステータス適用日エラー
  cv_msg_xxcmm_10471       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10471';      -- 品目ステータス取引作成済エラー
  cv_msg_xxcmm_10472       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10472';      -- 品目ステータス拠点在庫存在エラー
  cv_msg_xxcmm_10473       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10473';      -- 品目ステータス戻しエラー
  cv_msg_xxcmm_10474       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10474';      -- 廃止品目入力エラー
  cv_msg_xxcmm_10475       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10475';      -- 品目ステータス仮採番登録エラー
  cv_msg_xxcmm_10476       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10476';      -- 標準原価未登録エラー
  cv_msg_xxcmm_10477       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10477';      -- 適用済みレコード削除エラー
  cv_msg_xxcmm_10478       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10478';      -- 初回変更予約レコード削除エラー
  cv_msg_xxcmm_00407       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00407';      -- データ登録エラー
  cv_msg_xxcmm_00008       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00008';      -- ロック取得エラー
  cv_msg_xxcmm_10479       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10479';      -- データ削除エラー
  cv_msg_xxcmm_10480       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10480';      -- 変更予約情報処理件数
--
  -- トークン値
  cv_msg_xxcmm_10452       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10452';      -- 項目チェック用定義情報
  cv_msg_xxcmm_10453       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10453';      -- ファイルアップロード名称
  cv_msg_xxcmm_10454       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10454';      -- 在庫会計期間
  cv_msg_xxcmm_10455       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10455';      -- 変更予約情報一括登録
  cv_msg_xxcmm_10456       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10456';      -- 品名コード
  cv_msg_xxcmm_10457       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10457';      -- 品目ステータス
  cv_msg_xxcmm_10458       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10458';      -- 登録ステータス
  cv_msg_xxcmm_10459       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10459';      -- 変更予約情報一時表
  cv_msg_xxcmm_10460       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10460';      -- Disc品目変更履歴アドオン
--
  -- トークン名
  cv_tkn_ng_profile        CONSTANT VARCHAR2(20)  := 'NG_PROFILE';            -- プロファイル名
  cv_tkn_value             CONSTANT VARCHAR2(20)  := 'VALUE';                 -- 値
  cv_tkn_ng_ou_name        CONSTANT VARCHAR2(20)  := 'NG_OU_NAME';            -- 組織名
  cv_tkn_up_name           CONSTANT VARCHAR2(20)  := 'UPLOAD_NAME';           -- ファイルアップロード名称
  cv_tkn_file_name         CONSTANT VARCHAR2(20)  := 'FILE_NAME';             -- CSVファイル名
  cv_tkn_file_id           CONSTANT VARCHAR2(20)  := 'FILE_ID';               -- FILE_ID
  cv_tkn_file_format       CONSTANT VARCHAR2(20)  := 'FORMAT';                -- フォーマットパターン
  cv_tkn_table             CONSTANT VARCHAR2(20)  := 'TABLE';                 -- テーブル名
  cv_tkn_ng_table          CONSTANT VARCHAR2(20)  := 'NG_TABLE';              -- NGテーブル名
  cv_tkn_input_line_no     CONSTANT VARCHAR2(20)  := 'INPUT_LINE_NO';         -- 行番号
  cv_tkn_err_msg           CONSTANT VARCHAR2(20)  := 'ERR_MSG';               -- エラーメッセージ
  cv_tkn_count             CONSTANT VARCHAR2(20)  := 'COUNT';                 -- 件数
  cv_tkn_input             CONSTANT VARCHAR2(20)  := 'INPUT';                 -- 項目名
  cv_tkn_item_code         CONSTANT VARCHAR2(20)  := 'ITEM_CODE';             -- 品名コード
  cv_tkn_input_item_code   CONSTANT VARCHAR2(20)  := 'INPUT_ITEM_CODE';       -- 品名コード
  cv_tkn_apply_date        CONSTANT VARCHAR2(20)  := 'APPLY_DATE';            -- 適用日
  cv_tkn_ins_count         CONSTANT VARCHAR2(20)  := 'INS_COUNT';             -- 登録件数
  cv_tkn_del_count         CONSTANT VARCHAR2(20)  := 'DEL_COUNT';             -- 削除件数
--
  -- 品目ステータス
  cn_itm_sts_num_tmp       CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_num_tmp;       -- 仮採番
  cn_itm_sts_pre_reg       CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_pre_reg;       -- 仮登録
  cn_itm_sts_regist        CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_regist;        -- 本登録
  cn_itm_sts_no_sch        CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_no_sch;        -- 廃
  cn_itm_sts_trn_only      CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_trn_only;      -- Ｄ’
  cn_itm_sts_no_use        CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_no_use;        -- Ｄ
--
  -- 品目カテゴリ
  cv_ctg_set_seisakugun    CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_seisakugun;     -- 政策群コード
--
  cv_yes                   CONSTANT VARCHAR2(1)   := 'Y';                     -- フラグ：有効
  cv_no                    CONSTANT VARCHAR2(1)   := 'N';                     -- フラグ：無効
  cv_ins                   CONSTANT VARCHAR2(1)   := 'I';                     -- 登録ステータス：登録
  cv_del                   CONSTANT VARCHAR2(1)   := 'D';                     -- 登録ステータス：削除
  cv_open                  CONSTANT VARCHAR2(1)   := 'Y';                     -- 期間オープンフラグ：オープン
  cv_flag_yes              CONSTANT VARCHAR2(1)   := 'Y';                     -- 適用フラグ：適用ずみ
  cv_flag_no               CONSTANT VARCHAR2(1)   := 'N';                     -- 適用フラグ：未適用
  cv_wildcard              CONSTANT VARCHAR2(3)   := '%*%';                   -- ワイルドカード
--
  -- 日付書式
  cv_date_fmt_std          CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';            -- 日付書式：YYYY/MM/DD
--
  cn_0                     CONSTANT NUMBER        := 0;                       -- 数字：0
  cn_1                     CONSTANT NUMBER        := 1;                       -- 数字：1
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 項目チェック用定義情報
  TYPE g_rec_item_def_data IS RECORD(
       item_name            VARCHAR2(100)                                     -- 項目名
     , item_attribute       VARCHAR2(100)                                     -- 項目属性
     , item_essential       VARCHAR2(100)                                     -- 必須フラグ
     , int_length           NUMBER                                            -- 項目の長さ(整数部分)
     , dec_length           NUMBER                                            -- 項目の長さ(小数点以下)
  );
  TYPE g_tab_item_def_data IS TABLE OF g_rec_item_def_data  INDEX BY PLS_INTEGER;
--
  -- 登録レコード格納変数
  TYPE g_rec_ins_data IS RECORD(
       item_id              xxcmm_system_items_b_hst.item_id%TYPE             -- 品目ID
     , item_code            xxcmm_system_items_b_hst.item_code%TYPE           -- 品目コード
     , apply_date           xxcmm_system_items_b_hst.apply_date%TYPE          -- 適用日
     , item_status          xxcmm_system_items_b_hst.item_status%TYPE         -- 品目ステータス
     , policy_group         xxcmm_system_items_b_hst.policy_group%TYPE        -- 政策群
     , discrete_cost        xxcmm_system_items_b_hst.discrete_cost%TYPE       -- 営業原価
     , line_no              NUMBER                                            -- 行番号
  );
  TYPE g_tab_ins_data  IS TABLE OF g_rec_ins_data  INDEX BY PLS_INTEGER;
--
  -- 削除レコード格納変数
  TYPE g_rec_del_data IS RECORD(
       item_hst_id          xxcmm_system_items_b_hst.item_hst_id%TYPE         -- 品目変更履歴ID
     , item_code            xxcmm_system_items_b_hst.item_code%TYPE           -- 品目コード
     , apply_date           xxcmm_system_items_b_hst.apply_date%TYPE          -- 適用日
     , line_no              NUMBER                                            -- 行番号
  );
  TYPE g_tab_del_data  IS TABLE OF g_rec_del_data  INDEX BY PLS_INTEGER;
--
  -- テーブル型
  gt_item_def_data          g_tab_item_def_data;    -- 項目チェック用定義情報
  gt_ins_data               g_tab_ins_data;         -- 登録レコード格納変数
  gt_del_data               g_tab_del_data;         -- 削除レコード格納変数
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_file_id                NUMBER;                 -- FILE_ID
  gv_format                 VARCHAR2(100);          -- フォーマットパターン
  gd_process_date           DATE;                   -- 業務日付
  gn_item_num               NUMBER;                 -- 変更予約情報一括登録データ項目数
  gn_org_id                 NUMBER;                 -- 在庫組織ID
  gd_period_s_date          DATE;                   -- 在庫会計期間開始日
--
  -- カウンタ制御用
  gn_ins_cnt                NUMBER;                 -- 登録用カウンタ
  gn_del_cnt                NUMBER;                 -- 削除用カウンタ
--
  -- エラー制御用
  gv_a2_check_sts           VARCHAR2(1);            -- A-2エラーチェック用
  gv_a4_check_sts           VARCHAR2(1);            -- A-4エラーチェック用
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
  -- 変更予約情報一時表取得
  CURSOR get_tmp_data_cur
  IS
    SELECT xticp.file_id                  AS file_id                -- ファイルID
          ,xticp.line_no                  AS line_no                -- 行番号
          ,xticp.item_code                AS item_code              -- 品目コード
          ,xticp.apply_date               AS apply_date             -- 適用日
          ,xticp.old_item_status          AS old_item_status        -- 旧品目ステータス
          ,xticp.new_item_status          AS new_item_status        -- 新品目ステータス
          ,xticp.discrete_cost            AS discrete_cost          -- 営業原価
          ,xticp.policy_group             AS policy_group           -- 政策群
          ,xticp.status                   AS status                 -- 登録ステータス
          ,xticp.item_id                  AS item_id                -- 品目ID
          ,xticp.parent_item_id           AS parent_item_id         -- 親品目ID
          ,xticp.inventory_item_id        AS inventory_item_id      -- Disc品目ID
          ,xticp.parent_item_flag         AS parent_item_flag       -- 親品目フラグ
    FROM   xxcmm_tmp_item_chg_upload   xticp     -- 変更予約情報一時表
    WHERE  xticp.file_id   =  gn_file_id
    ORDER BY
           xticp.line_no
    ;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_file_id            IN  VARCHAR2          -- ファイルID
   ,iv_format_pattern     IN  VARCHAR2          -- フォーマットパターン
   ,ov_errbuf     OUT VARCHAR2          -- エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2          -- リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2          -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_tkn_value              VARCHAR2(100);                                    -- トークン値
    lv_sqlerrm                VARCHAR2(5000);                                   -- SQLERRM
    ln_cnt                    NUMBER;                                           -- カウンタ
    lv_upload_obj             VARCHAR2(100);                                    -- ファイルアップロード名称
    -- ファイルアップロードIFテーブル項目
    lt_csv_file_name          xxccp_mrp_file_ul_interface.file_name%TYPE;       -- ファイル名格納用
    -- INパラメータ出力用
    lv_up_name                VARCHAR2(1000);                                   -- アップロード名称
    lv_file_name              VARCHAR2(1000);                                   -- ファイル名
    lv_file_id                VARCHAR2(1000);                                   -- ファイルID
    lv_file_format            VARCHAR2(1000);                                   -- フォーマット
    --
    lv_org_code               VARCHAR2(100);                                    -- 在庫組織コード
--
    -- *** ローカル・カーソル ***
    -- 項目チェック用定義情報取得カーソル
    CURSOR get_item_def_cur
    IS
      SELECT flv.meaning                         AS item_name                 -- 項目名
            ,DECODE(flv.attribute1
                  , cv_varchar ,cv_varchar_cd
                  , cv_number  ,cv_number_cd
                  , cv_date_cd
             )                                   AS item_attribute            -- 項目属性
            ,DECODE(flv.attribute2
                  , cv_not_null, cv_null_ng
                  , cv_null_ok
             )                                   AS item_essential            -- 必須フラグ
            ,TO_NUMBER(flv.attribute3)           AS int_length                -- 項目の長さ(整数部分)
            ,TO_NUMBER(flv.attribute4)           AS dec_length                -- 項目の長さ(小数点以下)
      FROM   fnd_lookup_values_vl  flv
      WHERE  flv.lookup_type  = cv_lookup_item_def
      AND    flv.enabled_flag = cv_yes
      AND    gd_process_date
               BETWEEN NVL(flv.start_date_active ,gd_process_date)
                   AND NVL(flv.end_date_active   ,gd_process_date)
      ORDER BY
             flv.lookup_code
      ;
--
    -- *** ローカル・レコード ***
--
    -- *** ローカルユーザー定義例外 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- パラメータをグローバル変数に格納
    gn_file_id := TO_NUMBER(iv_file_id);
    gv_format  := iv_format_pattern;
--
    -- ===============================
    -- 業務日付取得
    -- ===============================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF ( gd_process_date IS NULL ) THEN
      -- 業務日付取得エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_00018            -- メッセージ
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- プロファイル取得
    -- ===============================
    -- 変更予約情報一括登録データ項目数
    gn_item_num := TO_NUMBER(FND_PROFILE.VALUE(cv_prf_item_num));
    -- 取得値がNULLの場合
    IF ( gn_item_num IS NULL ) THEN
      -- プロファイル取得エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_00002            -- メッセージ
                    ,iv_token_name1  => cv_tkn_ng_profile             -- トークンコード1
                    ,iv_token_value1 => cv_prf_item_num               -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 在庫組織コード
    lv_org_code := FND_PROFILE.VALUE(cv_prf_org_code);
    -- 取得値がNULLの場合
    IF ( lv_org_code IS NULL ) THEN
      -- プロファイル取得エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_00002            -- メッセージ
                    ,iv_token_name1  => cv_tkn_ng_profile             -- トークンコード1
                    ,iv_token_value1 => cv_prf_org_code               -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 項目チェック用定義情報取得
    -- ===============================
    -- カウンター初期化
    ln_cnt := 0;
    -- 項目チェック用定義情報取得LOOP
    <<item_def_loop>>
    FOR get_item_def_rec IN get_item_def_cur LOOP
      ln_cnt := ln_cnt + 1;
      gt_item_def_data(ln_cnt).item_name      := get_item_def_rec.item_name;       -- 項目名
      gt_item_def_data(ln_cnt).item_attribute := get_item_def_rec.item_attribute;  -- 項目属性
      gt_item_def_data(ln_cnt).item_essential := get_item_def_rec.item_essential;  -- 必須フラグ
      gt_item_def_data(ln_cnt).int_length     := get_item_def_rec.int_length;      -- 項目の長さ(整数部分)
      gt_item_def_data(ln_cnt).dec_length     := get_item_def_rec.dec_length;      -- 項目の長さ(小数点以下)
    END LOOP item_def_loop
    ;
    -- 件数が0件の場合
    IF ( ln_cnt = 0 ) THEN
      -- 取得失敗エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_10429            -- メッセージ
                    ,iv_token_name1  => cv_tkn_value                  -- トークンコード1
                    ,iv_token_value1 => cv_msg_xxcmm_10452            -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ファイルアップロード名称取得
    -- ===============================
    BEGIN
      SELECT flv.meaning      AS upload_obj
      INTO   lv_upload_obj
      FROM   fnd_lookup_values_vl flv
      WHERE  flv.lookup_type  = cv_lookup_file_up_obj
      AND    flv.lookup_code  = gv_format
      AND    flv.enabled_flag = cv_yes
      AND    gd_process_date
               BETWEEN NVL(flv.start_date_active ,gd_process_date)
                   AND NVL(flv.end_date_active   ,gd_process_date)
      ;
    EXCEPTION
      -- 取得できない場合
      WHEN NO_DATA_FOUND THEN
        -- 取得失敗エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_10429            -- メッセージ
                      ,iv_token_name1  => cv_tkn_value                  -- トークンコード1
                      ,iv_token_value1 => cv_msg_xxcmm_10453            -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END;
--
    -- ===============================
    -- CSVファイル情報取得
    -- ===============================
    SELECT fui.file_name      AS csv_file_name
    INTO   lt_csv_file_name
    FROM   xxccp_mrp_file_ul_interface  fui      -- ファイルアップロードI/F表
    WHERE  fui.file_id           = gn_file_id    -- ファイルID
    AND    fui.file_content_type = gv_format     -- ファイルフォーマット
    FOR UPDATE NOWAIT
    ;
--
    -- ===============================
    -- 在庫組織ID取得
    -- ===============================
    BEGIN
      SELECT mp.organization_id   AS org_id
      INTO   gn_org_id
      FROM   mtl_parameters       mp
      WHERE  mp.organization_code = lv_org_code  -- 在庫組織コード
      ;
    EXCEPTION
      -- 取得できない場合
      WHEN NO_DATA_FOUND THEN
        -- 組織ID取得エラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_00015            -- メッセージ
                      ,iv_token_name1  => cv_tkn_ng_ou_name             -- トークンコード1
                      ,iv_token_value1 => lv_org_code                   -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- ===============================
    -- 在庫会計期間開始日取得
    -- ===============================
    SELECT MIN( oap.period_start_date )   AS period_s_date
    INTO   gd_period_s_date
    FROM   org_acct_periods   oap
    WHERE  oap.organization_id = gn_org_id  -- 在庫組織ID
    AND    oap.open_flag       = cv_open    -- オープン
    ;
    -- 取得できない場合
    IF ( gd_period_s_date IS NULL ) THEN
      -- 取得失敗エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_10429            -- メッセージ
                    ,iv_token_name1  => cv_tkn_value                  -- トークンコード1
                    ,iv_token_value1 => cv_msg_xxcmm_10454            -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- パラメータ出力
    -- ===============================
    -- ファイルアップロード名称
    lv_up_name     := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                       ,iv_name         => cv_msg_xxcmm_00021            -- メッセージコード
                       ,iv_token_name1  => cv_tkn_up_name                -- トークンコード1
                       ,iv_token_value1 => lv_upload_obj                 -- トークン値1
                      );
    -- CSVファイル名
    lv_file_name   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                       ,iv_name         => cv_msg_xxcmm_00022            -- メッセージコード
                       ,iv_token_name1  => cv_tkn_file_name              -- トークンコード1
                       ,iv_token_value1 => lt_csv_file_name              -- トークン値1
                      );
    -- ファイルID
    lv_file_id     := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                       ,iv_name         => cv_msg_xxcmm_00023            -- メッセージコード
                       ,iv_token_name1  => cv_tkn_file_id                -- トークンコード1
                       ,iv_token_value1 => TO_CHAR(gn_file_id)           -- トークン値1
                      );
    -- フォーマットパターン
    lv_file_format := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm             -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_00024             -- メッセージコード
                      ,iv_token_name1  => cv_tkn_file_format             -- トークンコード1
                      ,iv_token_value1 => gv_format                      -- トークン値1
                      );
    -- 出力に表示
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT
                     ,buff   => ''             || CHR(10) ||
                                lv_up_name     || CHR(10) ||
                                lv_file_name   || CHR(10) ||
                                lv_file_id     || CHR(10) ||
                                lv_file_format || CHR(10)
    );
    -- ログに表示
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.LOG
                     ,buff   => ''             || CHR(10) ||
                                lv_up_name     || CHR(10) ||
                                lv_file_name   || CHR(10) ||
                                lv_file_id     || CHR(10) ||
                                lv_file_format || CHR(10)
    );
--
  EXCEPTION
--
    -- *** ロックエラー例外ハンドラ ***
    WHEN global_check_lock_expt THEN
      -- IFロック取得エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_00402            -- メッセージ
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : validate_data
   * Description      : 妥当性チェック処理(A-4)
   ***********************************************************************************/
  PROCEDURE validate_data(
    i_tmp_date_rec     IN  get_tmp_data_cur%ROWTYPE       -- 変更予約情報一時表情報
   ,ov_errbuf          OUT VARCHAR2     --   エラー・メッセージ                  -- # 固定 #
   ,ov_retcode         OUT VARCHAR2     --   リターン・コード                    -- # 固定 #
   ,ov_errmsg          OUT VARCHAR2     --   ユーザー・エラー・メッセージ        -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'validate_data'; -- プログラム名
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
    lv_check_status           VARCHAR2(1);            -- ステータス
    --
    lt_item_hst_id            xxcmm_system_items_b_hst.item_hst_id%TYPE;        -- 品目変更履歴ID
    lt_apply_flag             xxcmm_system_items_b_hst.apply_flag%TYPE;         -- 適用有無
    lt_first_apply_flag       xxcmm_system_items_b_hst.first_apply_flag%TYPE;   -- 初回適用フラグ
    ln_standard_cost          NUMBER;                                           -- 標準原価
    ln_chk_cnt                NUMBER;                                           -- チェック用件数
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
    -- ローカル変数の初期化
    lv_check_status := cv_status_normal;
--
    -- ===============================
    -- 必須項目チェック
    -- ===============================
    -- 「登録」かつ、必須項目のいずれか設定されているかチェック
    IF ( i_tmp_date_rec.status = cv_ins )
      AND ( i_tmp_date_rec.new_item_status IS NULL )
      AND ( i_tmp_date_rec.discrete_cost IS NULL )
      AND ( i_tmp_date_rec.policy_group IS NULL ) THEN
      -- 項目未入力エラー
      gv_out_msg := xxccp_common_pkg.get_msg(
                   iv_application   =>  cv_appl_name_xxcmm                                     -- アプリケーション短縮名
                  ,iv_name          =>  cv_msg_xxcmm_10461                                     -- メッセージ
                  ,iv_token_name1   =>  cv_tkn_item_code                                       -- トークンコード1
                  ,iv_token_value1  =>  i_tmp_date_rec.item_code                               -- トークン値1
                  ,iv_token_name2   =>  cv_tkn_apply_date                                      -- トークンコード2
                  ,iv_token_value2  =>  TO_CHAR( i_tmp_date_rec.apply_date ,cv_date_fmt_std )  -- トークン値2
                  ,iv_token_name3   =>  cv_tkn_input_line_no                                   -- トークンコード3
                  ,iv_token_value3  =>  TO_CHAR( i_tmp_date_rec.line_no )                      -- トークン値3
                   );
      -- メッセージ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      -- エラーセット
      gv_a4_check_sts := cv_status_error;
      lv_check_status := cv_status_error;
    END IF;
--
    -- ===============================
    -- 親品目継承項目入力チェック
    -- ===============================
    -- 「登録」かつ、「子品目」の場合、
    -- 親品目継承項目が入力されていないかチェック
    IF ( i_tmp_date_rec.status = cv_ins )
      AND ( i_tmp_date_rec.parent_item_flag = cv_no )
      AND ( ( i_tmp_date_rec.discrete_cost IS NOT NULL )
         OR ( i_tmp_date_rec.policy_group IS NOT NULL ) ) THEN
      -- 親品目継承項目入力エラー
      gv_out_msg := xxccp_common_pkg.get_msg(
                   iv_application   =>  cv_appl_name_xxcmm                                     -- アプリケーション短縮名
                  ,iv_name          =>  cv_msg_xxcmm_10462                                     -- メッセージ
                  ,iv_token_name1   =>  cv_tkn_item_code                                       -- トークンコード1
                  ,iv_token_value1  =>  i_tmp_date_rec.item_code                               -- トークン値1
                  ,iv_token_name2   =>  cv_tkn_input_line_no                                   -- トークンコード2
                  ,iv_token_value2  =>  TO_CHAR( i_tmp_date_rec.line_no )                      -- トークン値2
                   );
      -- メッセージ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      -- エラーセット
      gv_a4_check_sts := cv_status_error;
      lv_check_status := cv_status_error;
    END IF;
--
    -- ===============================
    -- 廃止品目チェック
    -- ===============================
    -- 「登録」かつ、旧品目ステータスが「Ｄ」、新品目ステータスが未設定
    -- または新品目ステータスが「Ｄ」の場合、営業原価が入力されていないかチェック
    IF ( i_tmp_date_rec.status = cv_ins )
      AND ( ( ( i_tmp_date_rec.old_item_status = cn_itm_sts_no_use )  --「Ｄ」
          AND ( i_tmp_date_rec.new_item_status IS NULL ) )
       OR   ( i_tmp_date_rec.new_item_status = cn_itm_sts_no_use ) )  --「Ｄ」
      AND ( i_tmp_date_rec.discrete_cost IS NOT NULL ) THEN
      -- 廃止品目入力エラー
      gv_out_msg := xxccp_common_pkg.get_msg(
                   iv_application   =>  cv_appl_name_xxcmm                                     -- アプリケーション短縮名
                  ,iv_name          =>  cv_msg_xxcmm_10474                                     -- メッセージ
                  ,iv_token_name1   =>  cv_tkn_item_code                                       -- トークンコード1
                  ,iv_token_value1  =>  i_tmp_date_rec.item_code                               -- トークン値1
                  ,iv_token_name2   =>  cv_tkn_input_line_no                                   -- トークンコード2
                  ,iv_token_value2  =>  TO_CHAR( i_tmp_date_rec.line_no )                      -- トークン値2
                   );
      -- メッセージ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      -- エラーセット
      gv_a4_check_sts := cv_status_error;
      lv_check_status := cv_status_error;
    END IF;
--
    -- ===============================
    -- 過去日チェック
    -- ===============================
    -- 「登録」の場合、適用日＜業務日付でないかチェック
    IF ( i_tmp_date_rec.status = cv_ins )
      AND ( i_tmp_date_rec.apply_date < gd_process_date ) THEN
      -- 適用日過去日エラー
      gv_out_msg := xxccp_common_pkg.get_msg(
                   iv_application   =>  cv_appl_name_xxcmm                                     -- アプリケーション短縮名
                  ,iv_name          =>  cv_msg_xxcmm_10463                                     -- メッセージ
                  ,iv_token_name1   =>  cv_tkn_item_code                                       -- トークンコード1
                  ,iv_token_value1  =>  i_tmp_date_rec.item_code                               -- トークン値1
                  ,iv_token_name2   =>  cv_tkn_apply_date                                      -- トークンコード2
                  ,iv_token_value2  =>  TO_CHAR( i_tmp_date_rec.apply_date ,cv_date_fmt_std )  -- トークン値2
                  ,iv_token_name3   =>  cv_tkn_input_line_no                                   -- トークンコード3
                  ,iv_token_value3  =>  TO_CHAR( i_tmp_date_rec.line_no )                      -- トークン値3
                   );
      -- メッセージ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      -- エラーセット
      gv_a4_check_sts := cv_status_error;
      lv_check_status := cv_status_error;
    END IF;
--
    -- ===============================
    -- 重複レコードチェック(一時表)
    -- ===============================
    -- 一時表内に同一品目、適用日でレコードが重複していないかチェック
    SELECT COUNT(0)      AS chk_cnt
    INTO   ln_chk_cnt
    FROM   xxcmm_tmp_item_chg_upload  xticu
    WHERE  xticu.item_code   = i_tmp_date_rec.item_code
    AND    xticu.apply_date  = i_tmp_date_rec.apply_date
    AND    xticu.line_no    != i_tmp_date_rec.line_no
    AND    ROWNUM            = cn_1
    ;
    -- 件数が1件以上の場合
    IF ( ln_chk_cnt > 0 ) THEN
      -- 品目重複エラー
      gv_out_msg := xxccp_common_pkg.get_msg(
                   iv_application   =>  cv_appl_name_xxcmm                                     -- アプリケーション短縮名
                  ,iv_name          =>  cv_msg_xxcmm_10464                                     -- メッセージ
                  ,iv_token_name1   =>  cv_tkn_item_code                                       -- トークンコード1
                  ,iv_token_value1  =>  i_tmp_date_rec.item_code                               -- トークン値1
                  ,iv_token_name2   =>  cv_tkn_apply_date                                      -- トークンコード2
                  ,iv_token_value2  =>  TO_CHAR( i_tmp_date_rec.apply_date ,cv_date_fmt_std )  -- トークン値2
                  ,iv_token_name3   =>  cv_tkn_input_line_no                                   -- トークンコード3
                  ,iv_token_value3  =>  TO_CHAR( i_tmp_date_rec.line_no )                      -- トークン値3
                   );
      -- メッセージ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      -- エラーセット
      gv_a4_check_sts := cv_status_error;
      lv_check_status := cv_status_error;
    END IF;
--
    -- ===============================================
    -- 対象レコード有無チェック
    -- ===============================================
    -- 「登録」の場合、既存レコードが存在しないことをチェック
    -- 「削除」の場合、既存レコードが存在することをチェック
    BEGIN
      SELECT xsibhv.item_hst_id         AS item_hst_id         -- 品目変更履歴ID
            ,xsibhv.apply_flag          AS apply_flag          -- 適用有無
            ,xsibhv.first_apply_flag    AS first_apply_flag    -- 初回適用フラグ
      INTO   lt_item_hst_id
            ,lt_apply_flag
            ,lt_first_apply_flag
      FROM  (SELECT xsibh.item_hst_id         AS item_hst_id
                   ,xsibh.apply_flag          AS apply_flag
                   ,xsibh.first_apply_flag    AS first_apply_flag
                   ,ROW_NUMBER() OVER ( ORDER BY xsibh.item_hst_id DESC )
                                              AS num
             FROM   xxcmm_system_items_b_hst xsibh
             WHERE  xsibh.item_code   = i_tmp_date_rec.item_code
             AND    xsibh.apply_date  = i_tmp_date_rec.apply_date
            ) xsibhv
      WHERE  xsibhv.num               = cn_1
      ;
      -- レコードが取得できて「登録」の場合エラー
      IF ( i_tmp_date_rec.status = cv_ins ) THEN
        -- 対象レコード存在チェックエラー
        gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application   =>  cv_appl_name_xxcmm                                     -- アプリケーション短縮名
                    ,iv_name          =>  cv_msg_xxcmm_10465                                     -- メッセージ
                    ,iv_token_name1   =>  cv_tkn_item_code                                       -- トークンコード1
                    ,iv_token_value1  =>  i_tmp_date_rec.item_code                               -- トークン値1
                    ,iv_token_name2   =>  cv_tkn_apply_date                                      -- トークンコード2
                    ,iv_token_value2  =>  TO_CHAR( i_tmp_date_rec.apply_date ,cv_date_fmt_std )  -- トークン値2
                    ,iv_token_name3   =>  cv_tkn_input_line_no                                   -- トークンコード3
                    ,iv_token_value3  =>  TO_CHAR( i_tmp_date_rec.line_no )                      -- トークン値3
                     );
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
        -- エラーセット
        gv_a4_check_sts := cv_status_error;
        lv_check_status := cv_status_error;
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- レコードが取得できず「削除」の場合エラー
        IF ( i_tmp_date_rec.status = cv_del ) THEN
          -- 対象レコード非存在チェックエラー
          gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application   =>  cv_appl_name_xxcmm                                     -- アプリケーション短縮名
                      ,iv_name          =>  cv_msg_xxcmm_10466                                     -- メッセージ
                      ,iv_token_name1   =>  cv_tkn_item_code                                       -- トークンコード1
                      ,iv_token_value1  =>  i_tmp_date_rec.item_code                               -- トークン値1
                      ,iv_token_name2   =>  cv_tkn_apply_date                                      -- トークンコード2
                      ,iv_token_value2  =>  TO_CHAR( i_tmp_date_rec.apply_date ,cv_date_fmt_std )  -- トークン値2
                      ,iv_token_name3   =>  cv_tkn_input_line_no                                   -- トークンコード3
                      ,iv_token_value3  =>  TO_CHAR( i_tmp_date_rec.line_no )                      -- トークン値3
                       );
          -- メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg
          );
          -- エラーセット
          gv_a4_check_sts := cv_status_error;
          lv_check_status := cv_status_error;
        END IF;
    END;
--
    -- ===============================
    -- 品目ステータス廃止チェック
    -- ===============================
    -- 「登録」かつ、「親品目」かつ、新品目ステータスが「Ｄ」の場合、
    -- 紐付く子品目の品目ステータスが全て「Ｄ」であるかチェック
    IF ( i_tmp_date_rec.status = cv_ins )
      AND ( i_tmp_date_rec.parent_item_flag = cv_yes )
      AND ( i_tmp_date_rec.new_item_status = cn_itm_sts_no_use ) THEN
      --
      SELECT COUNT(0)      AS chk_cnt
      INTO   ln_chk_cnt
      FROM   xxcmm_opmmtl_items_v  xoiv
      WHERE  xoiv.parent_item_id      = i_tmp_date_rec.parent_item_id
      AND    xoiv.item_id            != i_tmp_date_rec.parent_item_id
      AND    xoiv.item_status        != cn_itm_sts_no_use   -- 品目ステータス「Ｄ」
      AND    xoiv.start_date_active  <= gd_process_date
      AND    xoiv.end_date_active    >= gd_process_date
      AND    ROWNUM                   = cn_1
      ;
      -- 件数が1件以上の場合
      IF ( ln_chk_cnt > 0 ) THEN
        -- 品目ステータス廃止エラー
        gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application   =>  cv_appl_name_xxcmm                                     -- アプリケーション短縮名
                    ,iv_name          =>  cv_msg_xxcmm_10467                                     -- メッセージ
                    ,iv_token_name1   =>  cv_tkn_item_code                                       -- トークンコード1
                    ,iv_token_value1  =>  i_tmp_date_rec.item_code                               -- トークン値1
                    ,iv_token_name2   =>  cv_tkn_input_line_no                                   -- トークンコード2
                    ,iv_token_value2  =>  TO_CHAR( i_tmp_date_rec.line_no )                      -- トークン値2
                     );
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
        -- エラーセット
        gv_a4_check_sts := cv_status_error;
        lv_check_status := cv_status_error;
      END IF;
    END IF;
--
    -- ===============================
    -- 品目ステータス子品目チェック
    -- ===============================
    -- 「登録」かつ、「子品目」かつ、旧品目ステータスが「Ｄ」かつ、
    -- 新品目ステータスが「本登録」「廃」「Ｄ’」の場合、
    -- 親品目の品目ステータスが「Ｄ」でないことをチェック
    IF ( i_tmp_date_rec.status = cv_ins )
      AND ( i_tmp_date_rec.parent_item_flag = cv_no )
      AND ( i_tmp_date_rec.old_item_status = cn_itm_sts_no_use )       -- 「Ｄ」
      AND ( i_tmp_date_rec.new_item_status IN ( cn_itm_sts_regist      -- 「本登録」
                                              , cn_itm_sts_no_sch      -- 「廃」
                                              , cn_itm_sts_trn_only    -- 「Ｄ’」
                                              ) ) THEN
      --
      SELECT COUNT(0)      AS chk_cnt
      INTO   ln_chk_cnt
      FROM   xxcmm_opmmtl_items_v  xoiv
      WHERE  xoiv.parent_item_id      = i_tmp_date_rec.parent_item_id
      AND    xoiv.item_id             = xoiv.parent_item_id
      AND    xoiv.item_status         = cn_itm_sts_no_use   -- 「Ｄ」
      AND    xoiv.start_date_active  <= gd_process_date
      AND    xoiv.end_date_active    >= gd_process_date
      AND    ROWNUM                   = cn_1
      ;
      -- 件数が1件以上の場合
      IF ( ln_chk_cnt > 0 ) THEN
        -- 品目ステータス子品目エラー
        gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application   =>  cv_appl_name_xxcmm                                     -- アプリケーション短縮名
                    ,iv_name          =>  cv_msg_xxcmm_10468                                     -- メッセージ
                    ,iv_token_name1   =>  cv_tkn_item_code                                       -- トークンコード1
                    ,iv_token_value1  =>  i_tmp_date_rec.item_code                               -- トークン値1
                    ,iv_token_name2   =>  cv_tkn_input_line_no                                   -- トークンコード2
                    ,iv_token_value2  =>  TO_CHAR( i_tmp_date_rec.line_no )                      -- トークン値2
                     );
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
        -- エラーセット
        gv_a4_check_sts := cv_status_error;
        lv_check_status := cv_status_error;
      END IF;
    END IF;
--
    -- ===============================
    -- 品目ステータスフローチェック１
    -- ===============================
    -- 「登録」かつ、新品目ステータスが「本登録」「廃」「Ｄ’」「Ｄ」の場合、
    -- 未来日に「仮採番」「仮登録」のレコードがないことをチェック
    IF ( i_tmp_date_rec.status = cv_ins )
      AND ( i_tmp_date_rec.new_item_status IN ( cn_itm_sts_regist      -- 「本登録」
                                              , cn_itm_sts_no_sch      -- 「廃」
                                              , cn_itm_sts_trn_only    -- 「Ｄ’」
                                              , cn_itm_sts_no_use      -- 「Ｄ」
                                              ) ) THEN
      --
      SELECT COUNT(0)      AS chk_cnt
      INTO   ln_chk_cnt
      FROM   xxcmm_item_chg_info_v  xiciv
      WHERE  xiciv.item_code     = i_tmp_date_rec.item_code
      AND    xiciv.apply_date    > i_tmp_date_rec.apply_date
      AND    xiciv.item_status   IN ( cn_itm_sts_pre_reg         -- 「仮採番」
                                    , cn_itm_sts_num_tmp         -- 「仮登録」
                                    )
      AND    ROWNUM              = cn_1
      ;
      -- 件数が1件以上の場合
      IF ( ln_chk_cnt > 0 ) THEN
        -- 品目ステータスフローエラー
        gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application   =>  cv_appl_name_xxcmm                                     -- アプリケーション短縮名
                    ,iv_name          =>  cv_msg_xxcmm_10469                                     -- メッセージ
                    ,iv_token_name1   =>  cv_tkn_item_code                                       -- トークンコード1
                    ,iv_token_value1  =>  i_tmp_date_rec.item_code                               -- トークン値1
                    ,iv_token_name2   =>  cv_tkn_input_line_no                                   -- トークンコード2
                    ,iv_token_value2  =>  TO_CHAR( i_tmp_date_rec.line_no )                      -- トークン値2
                     );
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
        -- エラーセット
        gv_a4_check_sts := cv_status_error;
        lv_check_status := cv_status_error;
      END IF;
    END IF;
--
    -- ===============================
    -- 品目ステータスフローチェック２
    -- ===============================
    -- 「登録」かつ、新品目ステータスが「仮登録」の場合、
    -- 過去日に「本登録」「廃」「Ｄ’」「Ｄ」のレコードがないことをチェック
    IF ( i_tmp_date_rec.status = cv_ins )
      AND ( i_tmp_date_rec.new_item_status = cn_itm_sts_pre_reg )    -- 「仮登録」
    THEN
      --
      SELECT COUNT(0)      AS chk_cnt
      INTO   ln_chk_cnt
      FROM   xxcmm_item_chg_info_v  xiciv
      WHERE  xiciv.item_code     = i_tmp_date_rec.item_code
      AND    xiciv.apply_date    < i_tmp_date_rec.apply_date
      AND    xiciv.item_status   IN ( cn_itm_sts_regist      -- 「本登録」
                                    , cn_itm_sts_no_sch      -- 「廃」
                                    , cn_itm_sts_trn_only    -- 「Ｄ’」
                                    , cn_itm_sts_no_use      -- 「Ｄ」
                                    )
      AND    ROWNUM              = cn_1
      ;
      -- 件数が1件以上の場合
      IF ( ln_chk_cnt > 0 ) THEN
        -- 品目ステータスフローエラー
        gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application   =>  cv_appl_name_xxcmm                                     -- アプリケーション短縮名
                    ,iv_name          =>  cv_msg_xxcmm_10469                                     -- メッセージ
                    ,iv_token_name1   =>  cv_tkn_item_code                                       -- トークンコード1
                    ,iv_token_value1  =>  i_tmp_date_rec.item_code                               -- トークン値1
                    ,iv_token_name2   =>  cv_tkn_input_line_no                                   -- トークンコード2
                    ,iv_token_value2  =>  TO_CHAR( i_tmp_date_rec.line_no )                      -- トークン値2
                     );
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
        -- エラーセット
        gv_a4_check_sts := cv_status_error;
        lv_check_status := cv_status_error;
      END IF;
    END IF;
--
    -- ===============================
    -- 品目ステータス適用日チェック
    -- ===============================
    -- 「登録」かつ、旧品目ステータスが「Ｄ」以外かつ、新品目ステータスが「Ｄ’」、
    -- または、新品目ステータスが「Ｄ’」の場合、
    -- 適用日＝業務日付でないことをチェック
    IF ( ( ( i_tmp_date_rec.status = cv_ins )
      AND ( i_tmp_date_rec.old_item_status != cn_itm_sts_no_use )
      AND ( i_tmp_date_rec.new_item_status  = cn_itm_sts_trn_only ) )
      OR  ( i_tmp_date_rec.new_item_status  = cn_itm_sts_no_use ) ) THEN
      -- 適用日＝業務日付の場合
      IF  ( i_tmp_date_rec.apply_date = gd_process_date ) THEN
        -- 品目ステータス適用日エラー
        gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application   =>  cv_appl_name_xxcmm                                     -- アプリケーション短縮名
                    ,iv_name          =>  cv_msg_xxcmm_10470                                     -- メッセージ
                    ,iv_token_name1   =>  cv_tkn_item_code                                       -- トークンコード1
                    ,iv_token_value1  =>  i_tmp_date_rec.item_code                               -- トークン値1
                    ,iv_token_name2   =>  cv_tkn_input_line_no                                   -- トークンコード2
                    ,iv_token_value2  =>  TO_CHAR( i_tmp_date_rec.line_no )                      -- トークン値2
                     );
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
        -- エラーセット
        gv_a4_check_sts := cv_status_error;
        lv_check_status := cv_status_error;
      END IF;
    END IF;
--
    -- ===============================
    -- 取引存在チェック
    -- ===============================
    -- 「登録」かつ、新品目ステータスが「Ｄ」の場合、
    -- OPEN在庫会計期間内に取引が作成されていないことをチェック
    IF  ( ( i_tmp_date_rec.status = cv_ins )
      AND ( i_tmp_date_rec.new_item_status  = cn_itm_sts_no_use ) ) THEN
      --
      SELECT COUNT(0)      AS chk_cnt
      INTO   ln_chk_cnt
      FROM   mtl_material_transactions mmt  -- 資材取引
      WHERE  mmt.inventory_item_id  = i_tmp_date_rec.inventory_item_id
      AND    mmt.organization_id    = gn_org_id
      AND    mmt.transaction_date  >= gd_period_s_date
      AND    mmt.transaction_date  <  i_tmp_date_rec.apply_date + 1
      AND    ROWNUM                 = cn_1
      ;
      -- 件数が1件以上の場合
      IF ( ln_chk_cnt > 0 ) THEN
        -- 品目ステータス取引作成済エラー
        gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application   =>  cv_appl_name_xxcmm                                     -- アプリケーション短縮名
                    ,iv_name          =>  cv_msg_xxcmm_10471                                     -- メッセージ
                    ,iv_token_name1   =>  cv_tkn_item_code                                       -- トークンコード1
                    ,iv_token_value1  =>  i_tmp_date_rec.item_code                               -- トークン値1
                    ,iv_token_name2   =>  cv_tkn_input_line_no                                   -- トークンコード2
                    ,iv_token_value2  =>  TO_CHAR( i_tmp_date_rec.line_no )                      -- トークン値2
                     );
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
        -- エラーセット
        gv_a4_check_sts := cv_status_error;
        lv_check_status := cv_status_error;
      END IF;
    END IF;
--
    -- ===============================
    -- 拠点在庫存在チェック
    -- ===============================
    -- 「登録」かつ、新品目ステータスが「Ｄ」の場合、
    -- 拠点に在庫が存在しないことをチェック
    IF  ( ( i_tmp_date_rec.status = cv_ins )
      AND ( i_tmp_date_rec.new_item_status  = cn_itm_sts_no_use ) ) THEN
      --
      SELECT COUNT(0)      AS chk_cnt
      INTO   ln_chk_cnt
      FROM   mtl_onhand_quantities moq  -- 手持在庫
      WHERE  moq.inventory_item_id     = i_tmp_date_rec.inventory_item_id
      AND    moq.organization_id       = gn_org_id
      AND    moq.transaction_quantity != cn_0
      AND    ROWNUM                    = cn_1
      ;
      -- 件数が1件以上の場合
      IF ( ln_chk_cnt > 0 ) THEN
        -- 品目ステータス拠点在庫存在エラー
        gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application   =>  cv_appl_name_xxcmm                                     -- アプリケーション短縮名
                    ,iv_name          =>  cv_msg_xxcmm_10472                                     -- メッセージ
                    ,iv_token_name1   =>  cv_tkn_item_code                                       -- トークンコード1
                    ,iv_token_value1  =>  i_tmp_date_rec.item_code                               -- トークン値1
                    ,iv_token_name2   =>  cv_tkn_input_line_no                                   -- トークンコード2
                    ,iv_token_value2  =>  TO_CHAR( i_tmp_date_rec.line_no )                      -- トークン値2
                     );
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
        -- エラーセット
        gv_a4_check_sts := cv_status_error;
        lv_check_status := cv_status_error;
      END IF;
    END IF;
--
    -- ===============================
    -- 品目ステータス戻しチェック
    -- ===============================
    -- 「登録」かつ、旧品目ステータスが「本登録」「廃」「Ｄ’」「Ｄ」の場合、
    -- 新品目ステータスが「仮登録」でないことをチェック
    IF ( i_tmp_date_rec.status = cv_ins )
      AND ( i_tmp_date_rec.old_item_status IN ( cn_itm_sts_regist      -- 「本登録」
                                              , cn_itm_sts_no_sch      -- 「廃」
                                              , cn_itm_sts_trn_only    -- 「Ｄ’」
                                              , cn_itm_sts_no_use      -- 「Ｄ」
                                              ) )
      AND ( i_tmp_date_rec.new_item_status = cn_itm_sts_pre_reg )      -- 「仮登録」
    THEN
      -- 品目ステータス戻しエラー
      gv_out_msg := xxccp_common_pkg.get_msg(
                   iv_application   =>  cv_appl_name_xxcmm                                     -- アプリケーション短縮名
                  ,iv_name          =>  cv_msg_xxcmm_10473                                     -- メッセージ
                  ,iv_token_name1   =>  cv_tkn_item_code                                       -- トークンコード1
                  ,iv_token_value1  =>  i_tmp_date_rec.item_code                               -- トークン値1
                  ,iv_token_name2   =>  cv_tkn_input_line_no                                   -- トークンコード2
                  ,iv_token_value2  =>  TO_CHAR( i_tmp_date_rec.line_no )                      -- トークン値2
                   );
      -- メッセージ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      -- エラーセット
      gv_a4_check_sts := cv_status_error;
      lv_check_status := cv_status_error;
    END IF;
--
    -- ===============================
    -- 品目ステータス仮採番登録チェック
    -- ===============================
    -- 「登録」の場合、新品目ステータスが「仮採番」でないことをチェック
    IF ( i_tmp_date_rec.status = cv_ins )
      AND ( i_tmp_date_rec.new_item_status = cn_itm_sts_num_tmp )    -- 「仮採番」
    THEN
      -- 品目ステータス仮採番登録エラー
      gv_out_msg := xxccp_common_pkg.get_msg(
                   iv_application   =>  cv_appl_name_xxcmm                                     -- アプリケーション短縮名
                  ,iv_name          =>  cv_msg_xxcmm_10475                                     -- メッセージ
                  ,iv_token_name1   =>  cv_tkn_item_code                                       -- トークンコード1
                  ,iv_token_value1  =>  i_tmp_date_rec.item_code                               -- トークン値1
                  ,iv_token_name2   =>  cv_tkn_input_line_no                                   -- トークンコード2
                  ,iv_token_value2  =>  TO_CHAR( i_tmp_date_rec.line_no )                      -- トークン値2
                   );
      -- メッセージ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      -- エラーセット
      gv_a4_check_sts := cv_status_error;
      lv_check_status := cv_status_error;
    END IF;
--
    -- ===============================
    -- 標準原価チェック
    -- ===============================
    -- 「登録」かつ、営業原価が設定されている場合、
    -- 適用日時点の標準原価が登録されていることをチェック
    IF ( i_tmp_date_rec.status = cv_ins )
      AND ( i_tmp_date_rec.discrete_cost IS NOT NULL ) THEN
      BEGIN
        SELECT SUM(ccd.cmpnt_cost)  AS standard_cost
        INTO   ln_standard_cost
        FROM   cm_cmpt_dtl  ccd    -- OPM原価
              ,cm_cldr_dtl  ccc    -- OPM原価カレンダ
        WHERE  ccd.calendar_code  = ccc.calendar_code
        AND    ccd.period_code    = ccc.period_code
        AND    ccc.start_date    <= i_tmp_date_rec.apply_date
        AND    ccc.end_date      >= i_tmp_date_rec.apply_date
        AND    ccd.item_id        = i_tmp_date_rec.item_id
        GROUP BY
               ccd.item_id
              ,ccd.calendar_code
              ,ccd.period_code
        ;
      EXCEPTION
        -- 取得できない場合
        WHEN NO_DATA_FOUND THEN
          -- 標準原価未登録エラー
          gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application   =>  cv_appl_name_xxcmm                                     -- アプリケーション短縮名
                      ,iv_name          =>  cv_msg_xxcmm_10476                                     -- メッセージ
                      ,iv_token_name1   =>  cv_tkn_item_code                                       -- トークンコード1
                      ,iv_token_value1  =>  i_tmp_date_rec.item_code                               -- トークン値1
                      ,iv_token_name2   =>  cv_tkn_apply_date                                      -- トークンコード2
                      ,iv_token_value2  =>  TO_CHAR( i_tmp_date_rec.apply_date ,cv_date_fmt_std )  -- トークン値2
                      ,iv_token_name3   =>  cv_tkn_input_line_no                                   -- トークンコード3
                      ,iv_token_value3  =>  TO_CHAR( i_tmp_date_rec.line_no )                      -- トークン値3
                       );
          -- メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg
          );
          -- エラーセット
          gv_a4_check_sts := cv_status_error;
          lv_check_status := cv_status_error;
      END;
    END IF;
--
    -- ===============================
    -- 適用済みレコード削除チェック
    -- ===============================
    -- 「削除」の場合、適用有無が「適用済み」でないことをチェック
    IF ( i_tmp_date_rec.status = cv_del )
      AND ( lt_apply_flag = cv_flag_yes )    -- 「適用済み」
    THEN
      -- 適用済みレコード削除エラー
      gv_out_msg := xxccp_common_pkg.get_msg(
                   iv_application   =>  cv_appl_name_xxcmm                                     -- アプリケーション短縮名
                  ,iv_name          =>  cv_msg_xxcmm_10477                                     -- メッセージ
                  ,iv_token_name1   =>  cv_tkn_item_code                                       -- トークンコード1
                  ,iv_token_value1  =>  i_tmp_date_rec.item_code                               -- トークン値1
                  ,iv_token_name2   =>  cv_tkn_apply_date                                      -- トークンコード2
                  ,iv_token_value2  =>  TO_CHAR( i_tmp_date_rec.apply_date ,cv_date_fmt_std )  -- トークン値2
                  ,iv_token_name3   =>  cv_tkn_input_line_no                                   -- トークンコード3
                  ,iv_token_value3  =>  TO_CHAR( i_tmp_date_rec.line_no )                      -- トークン値3
                   );
      -- メッセージ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      -- エラーセット
      gv_a4_check_sts := cv_status_error;
      lv_check_status := cv_status_error;
    END IF;
--
    -- ===============================
    -- 初回変更予約レコード削除チェック
    -- ===============================
    -- 「削除」の場合、初回適用フラグが「初回適用」でないことをチェック
    IF ( i_tmp_date_rec.status = cv_del )
      AND ( lt_first_apply_flag = cv_flag_yes )    -- 「初回適用」
    THEN
      -- 初回変更予約レコード削除エラー
      gv_out_msg := xxccp_common_pkg.get_msg(
                   iv_application   =>  cv_appl_name_xxcmm                                     -- アプリケーション短縮名
                  ,iv_name          =>  cv_msg_xxcmm_10478                                     -- メッセージ
                  ,iv_token_name1   =>  cv_tkn_item_code                                       -- トークンコード1
                  ,iv_token_value1  =>  i_tmp_date_rec.item_code                               -- トークン値1
                  ,iv_token_name2   =>  cv_tkn_apply_date                                      -- トークンコード2
                  ,iv_token_value2  =>  TO_CHAR( i_tmp_date_rec.apply_date ,cv_date_fmt_std )  -- トークン値2
                  ,iv_token_name3   =>  cv_tkn_input_line_no                                   -- トークンコード3
                  ,iv_token_value3  =>  TO_CHAR( i_tmp_date_rec.line_no )                      -- トークン値3
                   );
      -- メッセージ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      -- エラーセット
      gv_a4_check_sts := cv_status_error;
      lv_check_status := cv_status_error;
    END IF;
--
    -- ===============================
    -- レコード格納
    -- ===============================
    -- 妥当性チェックOKの場合
    IF ( lv_check_status = cv_status_normal ) THEN
      -- 「登録」の場合
      IF ( i_tmp_date_rec.status = cv_ins ) THEN
        gn_ins_cnt                             := gn_ins_cnt + 1;
        gt_ins_data(gn_ins_cnt).item_id        := i_tmp_date_rec.item_id;            -- 品目ID
        gt_ins_data(gn_ins_cnt).item_code      := i_tmp_date_rec.item_code;          -- 品目コード
        gt_ins_data(gn_ins_cnt).apply_date     := i_tmp_date_rec.apply_date;         -- 適用日
        gt_ins_data(gn_ins_cnt).item_status    := i_tmp_date_rec.new_item_status;    -- 品目ステータス
        gt_ins_data(gn_ins_cnt).policy_group   := i_tmp_date_rec.policy_group;       -- 政策群
        gt_ins_data(gn_ins_cnt).discrete_cost  := i_tmp_date_rec.discrete_cost;      -- 営業原価
        gt_ins_data(gn_ins_cnt).line_no        := i_tmp_date_rec.line_no;            -- 行番号
--
      -- 「削除」の場合
      ELSE
        gn_del_cnt                             := gn_del_cnt + 1;
        gt_del_data(gn_del_cnt).item_hst_id    := lt_item_hst_id;                    -- 品目変更履歴ID
        gt_del_data(gn_del_cnt).item_code      := i_tmp_date_rec.item_code;          -- 品目コード
        gt_del_data(gn_del_cnt).apply_date     := i_tmp_date_rec.apply_date;         -- 適用日
        gt_del_data(gn_del_cnt).line_no        := i_tmp_date_rec.line_no;            -- 行番号
      END IF;
    END IF;
--
    -- 妥当性チェック結果をセット
    ov_retcode := lv_check_status;
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
  END validate_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_item_chg_data
   * Description      : 変更予約情報登録処理(A-5)
   ***********************************************************************************/
  PROCEDURE ins_item_chg_data(
    ov_errbuf          OUT VARCHAR2     --   エラー・メッセージ                  -- # 固定 #
   ,ov_retcode         OUT VARCHAR2     --   リターン・コード                    -- # 固定 #
   ,ov_errmsg          OUT VARCHAR2     --   ユーザー・エラー・メッセージ        -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_item_chg_data'; -- プログラム名
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
    lv_check_status           VARCHAR2(1);            -- ステータス
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
    -- ローカル変数の初期化
    lv_check_status := cv_status_normal;
--
    <<ins_data_loop>>
    FOR ln_cnt IN 1..gt_ins_data.COUNT LOOP
      BEGIN
        -- ===============================
        -- 変更予約情報登録
        -- ===============================
        INSERT INTO xxcmm_system_items_b_hst(
          item_hst_id
         ,item_id
         ,item_code
         ,apply_date
         ,apply_flag
         ,item_status
         ,policy_group
         ,fixed_price
         ,discrete_cost
         ,first_apply_flag
         ,created_by
         ,creation_date
         ,last_updated_by
         ,last_update_date
         ,last_update_login
         ,request_id
         ,program_application_id
         ,program_id
         ,program_update_date
        ) VALUES (
          xxcmm_system_items_b_hst_s.NEXTVAL     -- 品目変更履歴ID
         ,gt_ins_data(ln_cnt).item_id            -- 品目ID
         ,gt_ins_data(ln_cnt).item_code          -- 品目コード
         ,gt_ins_data(ln_cnt).apply_date         -- 適用日(適用開始日)
         ,cv_flag_no                             -- 適用有無
         ,gt_ins_data(ln_cnt).item_status        -- 品目ステータス
         ,gt_ins_data(ln_cnt).policy_group       -- 群コード(政策群コード)
         ,NULL                                   -- 定価
         ,gt_ins_data(ln_cnt).discrete_cost      -- 営業原価
         ,cv_flag_no                             -- 初回適用フラグ
         ,cn_created_by                          -- 作成者
         ,cd_creation_date                       -- 作成日
         ,cn_last_updated_by                     -- 最終更新者
         ,cd_last_update_date                    -- 最終更新日
         ,cn_last_update_login                   -- 最終更新ログイン
         ,cn_request_id                          -- 要求ID
         ,cn_program_application_id              -- コンカレント・プログラムのアプリケーションID
         ,cn_program_id                          -- コンカレント・プログラムID
         ,cd_program_update_date                 -- プログラムによる更新日
        );
      EXCEPTION
        WHEN OTHERS THEN
          -- データ登録エラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_appl_name_xxcmm                        -- アプリケーション短縮名
                       ,iv_name          =>  cv_msg_xxcmm_00407                        -- メッセージ
                       ,iv_token_name1   =>  cv_tkn_table                              -- トークンコード1
                       ,iv_token_value1  =>  cv_msg_xxcmm_10460                        -- トークン値1
                       ,iv_token_name2   =>  cv_tkn_input_line_no                      -- トークンコード2
                       ,iv_token_value2  =>  TO_CHAR( ln_cnt )                         -- トークン値2
                       ,iv_token_name3   =>  cv_tkn_input_item_code                    -- トークンコード3
                       ,iv_token_value3  =>  gt_ins_data(ln_cnt).item_code             -- トークン値3
                       ,iv_token_name4   =>  cv_tkn_err_msg                            -- トークンコード4
                       ,iv_token_value4  =>  SQLERRM                                   -- トークン値4
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
    END LOOP ins_data_loop;
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
  END ins_item_chg_data;
--
  /**********************************************************************************
   * Procedure Name   : del_item_chg_data
   * Description      : 変更予約情報削除処理(A-6)
   ***********************************************************************************/
  PROCEDURE del_item_chg_data(
    ov_errbuf          OUT VARCHAR2     --   エラー・メッセージ                  -- # 固定 #
   ,ov_retcode         OUT VARCHAR2     --   リターン・コード                    -- # 固定 #
   ,ov_errmsg          OUT VARCHAR2     --   ユーザー・エラー・メッセージ        -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_item_chg_data'; -- プログラム名
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
    lv_check_status           VARCHAR2(1);                                    -- ステータス
    lt_item_hst_id            xxcmm_system_items_b_hst.item_hst_id%TYPE;      -- 品目変更履歴ID
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
    -- ローカル変数の初期化
    lv_check_status := cv_status_normal;
--
    <<del_data_loop>>
    FOR ln_cnt IN 1..gt_del_data.COUNT LOOP
      -- ===============================
      -- 対象レコードロック
      -- ===============================
      SELECT xsibh.item_hst_id      AS item_hst_id
      INTO   lt_item_hst_id
      FROM   xxcmm_system_items_b_hst  xsibh
      WHERE  xsibh.item_hst_id = gt_del_data(ln_cnt).item_hst_id   -- 品目変更履歴ID
      FOR UPDATE NOWAIT
      ;
--
      -- ===============================
      -- 変更予約情報削除
      -- ===============================
      BEGIN
        DELETE FROM  xxcmm_system_items_b_hst  xsibh
        WHERE  xsibh.item_hst_id = lt_item_hst_id   -- 品目変更履歴ID
        ;
      EXCEPTION
        WHEN OTHERS THEN
          -- データ削除エラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_appl_name_xxcmm                        -- アプリケーション短縮名
                       ,iv_name          =>  cv_msg_xxcmm_10479                        -- メッセージ
                       ,iv_token_name1   =>  cv_tkn_table                              -- トークンコード1
                       ,iv_token_value1  =>  cv_msg_xxcmm_10460                        -- トークン値1
                       ,iv_token_name2   =>  cv_tkn_input_line_no                      -- トークンコード2
                       ,iv_token_value2  =>  TO_CHAR( ln_cnt )                         -- トークン値2
                       ,iv_token_name3   =>  cv_tkn_input_item_code                    -- トークンコード3
                       ,iv_token_value3  =>  gt_del_data(ln_cnt).item_code             -- トークン値3
                       ,iv_token_name4   =>  cv_tkn_err_msg                            -- トークンコード4
                       ,iv_token_value4  =>  SQLERRM                                   -- トークン値4
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
    END LOOP del_data_loop;
--
  EXCEPTION
--
    -- *** ロックエラー例外ハンドラ ***
    WHEN global_check_lock_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application   =>  cv_appl_name_xxcmm                        -- アプリケーション短縮名
                   ,iv_name          =>  cv_msg_xxcmm_00008                        -- メッセージ
                   ,iv_token_name1   =>  cv_tkn_ng_table                           -- トークンコード1
                   ,iv_token_value1  =>  cv_msg_xxcmm_10460                        -- トークン値1
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
  END del_item_chg_data;
--
  /**********************************************************************************
   * Procedure Name   : loop_main
   * Description      : 一時表取得処理(A-3)、妥当性チェック処理(A-4)
   ***********************************************************************************/
  PROCEDURE loop_main(
    ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ                  --# 固定 #
   ,ov_retcode    OUT VARCHAR2     --   リターン・コード                    --# 固定 #
   ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ        --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'loop_main'; -- プログラム名
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
    lv_check_status           VARCHAR2(1);                          -- ステータス
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    lv_check_status := cv_status_normal;
--
    <<main_loop>>
    FOR get_tmp_data_rec IN get_tmp_data_cur LOOP
      -- ===============================
      -- 妥当性チェック処理(A-4)
      -- ===============================
      validate_data(
        i_tmp_date_rec     => get_tmp_data_rec         -- 変更予約情報一時表情報
       ,ov_errbuf          => lv_errbuf                -- エラー・メッセージ
       ,ov_retcode         => lv_retcode               -- リターン・コード
       ,ov_errmsg          => lv_errmsg                -- ユーザー・エラー・メッセージ
      );
      -- 処理結果チェック
      IF ( lv_retcode = cv_status_normal ) THEN
        -- 正常件数加算
        gn_normal_cnt := gn_normal_cnt + 1;
      ELSE
        -- データ妥当性チェックエラーの場合、エラーステータス退避
        lv_check_status := cv_status_error;
        -- エラー件数加算
        gn_error_cnt  := gn_error_cnt + 1;
      END IF;
      --
    END LOOP main_loop;
--
    -- 妥当性チェック結果をセット
    ov_retcode := gv_a4_check_sts;
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
  END loop_main;
--
  /**********************************************************************************
   * Procedure Name   : get_if_data
   * Description      : ファイルアップロードデータ取得処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_if_data(
    ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ                  --# 固定 #
   ,ov_retcode    OUT VARCHAR2     --   リターン・コード                    --# 固定 #
   ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ        --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_if_data'; -- プログラム名
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
    -- *** ローカル ユーザー定義型 ***
    TYPE l_check_data_ttype  IS TABLE OF VARCHAR2(4000)  INDEX BY BINARY_INTEGER;
--
    -- *** ローカル変数 ***
    lv_check_status           VARCHAR2(1);            -- ステータス
    ln_line_cnt               NUMBER;                 -- 行カウンタ
    ln_column_cnt             NUMBER;                 -- 項目数カウンタ
    ln_ins_cnt                NUMBER;                 -- 登録件数カウンタ
    ln_item_num               NUMBER;                 -- 項目数
    lv_tkn_value              VARCHAR2(100);          -- トークン値
    lv_tkn_err_msg            VARCHAR2(100);          -- トークン値
    --
    lt_item_status            xxcmm_opmmtl_items_v.item_status%TYPE;         -- 品目ステータス
    lt_item_id                xxcmm_opmmtl_items_v.item_id%TYPE;             -- 品目ID
    lt_parent_item_id         xxcmm_opmmtl_items_v.parent_item_id%TYPE;      -- 親品目ID
    lt_inventory_item_id      xxcmm_opmmtl_items_v.inventory_item_id%TYPE;   -- Disc品目ID
    lv_parent_item_flag       VARCHAR2(1);                                   -- 親品目フラグ
    ln_chk_cnt                NUMBER;                                        -- チェック用件数
    --
    l_if_data_tab             xxccp_common_pkg2.g_file_data_tbl;      -- IFテーブル取得用
    l_wk_item_tab             l_check_data_ttype;                     -- テーブル型変数を宣言(項目分割)
--
    -- *** ローカルユーザー定義例外 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --初期化
    ln_ins_cnt := 0;
--
    -- ===============================================
    -- ファイルアップロードI/F表データ取得
    -- ===============================================
    xxccp_common_pkg2.blob_to_varchar2(          -- BLOBデータ変換共通関数
      in_file_id   => gn_file_id                 -- ファイルID
     ,ov_file_data => l_if_data_tab              -- 変換後VARCHAR2データ
     ,ov_errbuf    => lv_errbuf                  -- エラー・メッセージ           --# 固定 #
     ,ov_retcode   => lv_retcode                 -- リターン・コード             --# 固定 #
     ,ov_errmsg    => lv_errmsg                  -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ===============================================
    -- LOOP START
    -- ※1行目はヘッダ情報のため、2行目以降を取得
    -- ===============================================
    <<ins_wk_loop>>
    FOR ln_line_cnt IN 2..l_if_data_tab.COUNT LOOP
--
      -- 行カウンタ
      ln_ins_cnt := ln_ins_cnt + 1;
--
      -- ローカル変数の初期化
      lt_item_status        := NULL;   -- 品目ステータス
      lt_item_id            := NULL;   -- 品目ID
      lt_parent_item_id     := NULL;   -- 親品目ID
      lt_inventory_item_id  := NULL;   -- Disc品目ID
      lv_parent_item_flag   := NULL;   -- 親品目フラグ
      --
      lv_check_status       := cv_status_normal;
--
      -- ===============================================
      -- 項目数チェック
      -- ===============================================
      -- データ項目数を格納
      ln_item_num := ( LENGTHB(l_if_data_tab( ln_line_cnt) )
                   - ( LENGTHB(REPLACE(l_if_data_tab(ln_line_cnt), cv_msg_comma, '') ) )
                   + 1 );
      -- 項目数が一致しない場合
      IF ( gn_item_num <> ln_item_num ) THEN
        -- データ項目数エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_00028            -- メッセージコード
                      ,iv_token_name1  => cv_tkn_table                  -- トークンコード1
                      ,iv_token_value1 => cv_msg_xxcmm_10455            -- トークン値1
                      ,iv_token_name2  => cv_tkn_count                  -- トークンコード2
                      ,iv_token_value2 => TO_CHAR(ln_item_num)          -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================================
      -- CSV文字列分割
      -- ===============================================
--
      <<get_column_loop>>
      FOR ln_column_cnt IN 1..gn_item_num LOOP
--
        -- 変数に項目の値を格納
        l_wk_item_tab(ln_column_cnt) := xxccp_common_pkg.char_delim_partition(        -- デリミタ文字変換共通関数
                                          iv_char     => l_if_data_tab(ln_line_cnt)   -- 分割元文字列
                                         ,iv_delim    => cv_msg_comma                 -- デリミタ
                                         ,in_part_num => ln_column_cnt                -- 取得対象の項目Index
                                        );
--
        -- ===============================================
        -- 項目チェック
        -- ===============================================
        xxccp_common_pkg2.upload_item_check(
          iv_item_name    => gt_item_def_data(ln_column_cnt).item_name         -- 項目名称
         ,iv_item_value   => l_wk_item_tab(ln_column_cnt)                      -- 項目の値
         ,in_item_len     => gt_item_def_data(ln_column_cnt).int_length        -- 項目の長さ(整数部分)
         ,in_item_decimal => gt_item_def_data(ln_column_cnt).dec_length        -- 項目の長さ(小数点以下)
         ,iv_item_nullflg => gt_item_def_data(ln_column_cnt).item_essential    -- 必須フラグ
         ,iv_item_attr    => gt_item_def_data(ln_column_cnt).item_attribute    -- 項目の属性
         ,ov_errbuf       => lv_errbuf
         ,ov_retcode      => lv_retcode
         ,ov_errmsg       => lv_errmsg
        );
--
        -- 項目チェック結果が正常以外の場合
        IF ( lv_retcode <> cv_status_normal ) THEN
          -- ファイル項目チェックエラー
          gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application   =>  cv_appl_name_xxcmm          -- アプリケーション短縮名
                      ,iv_name          =>  cv_msg_xxcmm_00403          -- メッセージ
                      ,iv_token_name1   =>  cv_tkn_input_line_no        -- トークンコード1
                      ,iv_token_value1  =>  TO_CHAR( ln_ins_cnt )       -- トークン値1
                      ,iv_token_name2   =>  cv_tkn_err_msg              -- トークンコード2
                      ,iv_token_value2  =>  LTRIM(lv_errmsg)            -- トークン値2
                       );
          -- メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg
          );
          -- エラーセット
          gv_a2_check_sts := cv_status_error;
          lv_check_status := cv_status_error;
--
        ELSE
--
          -- ===============================================
          -- 品名コード
          -- ===============================================
          IF ( ln_column_cnt = 1 ) THEN
            BEGIN
              SELECT xoiv.item_status          AS item_status          -- 品目ステータス
                    ,xoiv.item_id              AS item_id              -- 品目ID
                    ,xoiv.parent_item_id       AS parent_item_id       -- 親品目ID
                    ,xoiv.inventory_item_id    AS inventory_item_id    -- Disc品目ID
                    ,CASE WHEN xoiv.item_id = xoiv.parent_item_id THEN
                       cv_yes
                     ELSE
                       cv_no
                     END                       AS parent_item_flag     -- 親品目フラグ
              INTO   lt_item_status
                    ,lt_item_id
                    ,lt_parent_item_id
                    ,lt_inventory_item_id
                    ,lv_parent_item_flag
              FROM   xxcmm_opmmtl_items_v xoiv
              WHERE  xoiv.start_date_active <= gd_process_date
              AND    xoiv.end_date_active   >= gd_process_date
              AND    xoiv.item_no            = l_wk_item_tab(1)  -- 品名コード
              ;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                -- 値チェックエラー
                gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application   =>  cv_appl_name_xxcmm          -- アプリケーション短縮名
                            ,iv_name          =>  cv_msg_xxcmm_10328          -- メッセージ
                            ,iv_token_name1   =>  cv_tkn_input                -- トークンコード1
                            ,iv_token_value1  =>  cv_msg_xxcmm_10456          -- トークン値1
                            ,iv_token_name2   =>  cv_tkn_value                -- トークンコード2
                            ,iv_token_value2  =>  l_wk_item_tab(1)            -- トークン値2
                            ,iv_token_name3   =>  cv_tkn_input_line_no        -- トークンコード3
                            ,iv_token_value3  =>  TO_CHAR( ln_ins_cnt )       -- トークン値3
                             );
                -- メッセージ出力
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.OUTPUT
                  ,buff   => gv_out_msg
                );
                -- エラーセット
                gv_a2_check_sts := cv_status_error;
                lv_check_status := cv_status_error;
            END;
          END IF;
--
          -- ===============================================
          -- 品目ステータス
          -- ===============================================
          IF ( ln_column_cnt = 3 )
            AND ( l_wk_item_tab(3) IS NOT NULL ) THEN
            SELECT COUNT(0)   AS chk_cnt
            INTO   ln_chk_cnt
            FROM   fnd_lookup_values_vl flvv
            WHERE  flvv.lookup_type  = cv_lookup_item_status
            AND    flvv.lookup_code  = l_wk_item_tab(3)        -- 品目ステータス
            ;
            IF ( ln_chk_cnt = 0 ) THEN
              -- 参照コード存在チェックエラー
              gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application   =>  cv_appl_name_xxcmm          -- アプリケーション短縮名
                          ,iv_name          =>  cv_msg_xxcmm_10330          -- メッセージ
                          ,iv_token_name1   =>  cv_tkn_input                -- トークンコード1
                          ,iv_token_value1  =>  cv_msg_xxcmm_10457          -- トークン値1
                          ,iv_token_name2   =>  cv_tkn_value                -- トークンコード2
                          ,iv_token_value2  =>  l_wk_item_tab(3)            -- トークン値2
                          ,iv_token_name3   =>  cv_tkn_input_line_no        -- トークンコード3
                          ,iv_token_value3  =>  TO_CHAR( ln_ins_cnt )       -- トークン値3
                           );
              -- メッセージ出力
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.OUTPUT
                ,buff   => gv_out_msg
              );
              -- エラーセット
              gv_a2_check_sts := cv_status_error;
              lv_check_status := cv_status_error;
            END IF;
          END IF;
--
          -- ===============================================
          -- 政策群
          -- ===============================================
          IF ( ln_column_cnt = 5 )
            AND ( l_wk_item_tab(5) IS NOT NULL ) THEN
            SELECT COUNT(0)   AS chk_cnt
            INTO   ln_chk_cnt
            FROM   mtl_categories_vl      mcv
                  ,mtl_category_sets_vl   mcsv
            WHERE  mcv.structure_id        = mcsv.structure_id
            AND    mcsv.category_set_name  = cv_ctg_set_seisakugun  -- カテゴリセット名（政策群コード）
            AND    mcv.enabled_flag        = cv_yes
            AND    mcv.segment1            NOT LIKE cv_wildcard
            AND    mcv.segment1            = l_wk_item_tab(5)   -- 政策群
            ;
            IF ( ln_chk_cnt = 0 ) THEN
              -- 値チェックエラー
              gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application   =>  cv_appl_name_xxcmm          -- アプリケーション短縮名
                          ,iv_name          =>  cv_msg_xxcmm_10328          -- メッセージ
                          ,iv_token_name1   =>  cv_tkn_input                -- トークンコード1
                          ,iv_token_value1  =>  cv_ctg_set_seisakugun       -- トークン値1
                          ,iv_token_name2   =>  cv_tkn_value                -- トークンコード2
                          ,iv_token_value2  =>  l_wk_item_tab(5)            -- トークン値2
                          ,iv_token_name3   =>  cv_tkn_input_line_no        -- トークンコード3
                          ,iv_token_value3  =>  TO_CHAR( ln_ins_cnt )       -- トークン値3
                           );
              -- メッセージ出力
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.OUTPUT
                ,buff   => gv_out_msg
              );
              -- エラーセット
              gv_a2_check_sts := cv_status_error;
              lv_check_status := cv_status_error;
            END IF;
          END IF;
--
          -- ===============================================
          -- 登録ステータス
          -- ===============================================
          IF ( ln_column_cnt = 6 )
            AND ( l_wk_item_tab(6) NOT IN ( cv_ins , cv_del ) ) THEN
            -- 値チェックエラー
            gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application   =>  cv_appl_name_xxcmm          -- アプリケーション短縮名
                        ,iv_name          =>  cv_msg_xxcmm_10328          -- メッセージ
                        ,iv_token_name1   =>  cv_tkn_input                -- トークンコード1
                        ,iv_token_value1  =>  cv_msg_xxcmm_10458          -- トークン値1
                        ,iv_token_name2   =>  cv_tkn_value                -- トークンコード2
                        ,iv_token_value2  =>  l_wk_item_tab(6)            -- トークン値2
                        ,iv_token_name3   =>  cv_tkn_input_line_no        -- トークンコード3
                        ,iv_token_value3  =>  TO_CHAR( ln_ins_cnt )       -- トークン値3
                         );
            -- メッセージ出力
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => gv_out_msg
            );
            -- エラーセット
            gv_a2_check_sts := cv_status_error;
            lv_check_status := cv_status_error;
          END IF;
        END IF;
      END LOOP get_column_loop;
--
      -- ===============================================
      -- 変更予約情報一時表登録
      -- ===============================================
      IF ( lv_check_status = cv_status_normal ) THEN
        BEGIN
          INSERT INTO xxcmm_tmp_item_chg_upload(
             file_id                   -- ファイルID
            ,line_no                   -- 行番号
            ,item_code                 -- 品目コード
            ,apply_date                -- 適用日
            ,old_item_status           -- 旧品目ステータス
            ,new_item_status           -- 新品目ステータス
            ,discrete_cost             -- 営業原価
            ,policy_group              -- 政策群
            ,status                    -- 登録ステータス
            ,item_id                   -- 品目ID
            ,parent_item_id            -- 親品目ID
            ,inventory_item_id         -- Disc品目ID
            ,parent_item_flag          -- 親品目フラグ
          ) VALUES (
             gn_file_id                                    -- ファイルID
            ,ln_ins_cnt                                    -- ファイルSEQ
            ,l_wk_item_tab(1)                              -- 品目コード
            ,TO_DATE(l_wk_item_tab(2) ,cv_date_fmt_std)    -- 適用日
            ,lt_item_status                                -- 旧品目ステータス
            ,l_wk_item_tab(3)                              -- 新品目ステータス
            ,l_wk_item_tab(4)                              -- 営業原価
            ,l_wk_item_tab(5)                              -- 政策群
            ,l_wk_item_tab(6)                              -- 登録ステータス
            ,lt_item_id                                    -- 品目ID
            ,lt_parent_item_id                             -- 親品目ID
            ,lt_inventory_item_id                          -- Disc品目ID
            ,lv_parent_item_flag                           -- 親品目フラグ
          );
        EXCEPTION
          -- *** データ登録例外ハンドラ ***
          WHEN OTHERS THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_name_xxcmm                 -- アプリケーション短縮名
                          ,iv_name         => cv_msg_xxcmm_00407                 -- メッセージコード
                          ,iv_token_name1  => cv_tkn_table                       -- トークンコード1
                          ,iv_token_value1 => cv_msg_xxcmm_10459                 -- トークン値1
                          ,iv_token_name2  => cv_tkn_input_line_no               -- トークンコード2
                          ,iv_token_value2 => TO_CHAR( ln_ins_cnt )              -- トークン値2
                          ,iv_token_name3  => cv_tkn_input_item_code             -- トークンコード3
                          ,iv_token_value3 => l_wk_item_tab(1)                   -- トークン値3
                          ,iv_token_name4  => cv_tkn_err_msg                     -- トークンコード4
                          ,iv_token_value4 => SQLERRM                            -- トークン値4
                         );
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
        END;
      END IF;
    END LOOP ins_wk_loop;
--
    -- ===============================================
    -- LOOP END
    -- ===============================================
--
    -- 処理対象件数を格納(ヘッダ件数を除く)
    gn_target_cnt := l_if_data_tab.COUNT - 1 ;
--
    -- 戻り値更新
    ov_retcode := gv_a2_check_sts;
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
  END get_if_data;
--
  /**********************************************************************************
   * Procedure Name   : del_if_data
   * Description      : ファイルアップロードデータ削除処理(A-7)
   ***********************************************************************************/
  PROCEDURE del_if_data(
    ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ                  --# 固定 #
   ,ov_retcode    OUT VARCHAR2     --   リターン・コード                    --# 固定 #
   ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ        --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_if_data'; -- プログラム名
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================================
    -- ファイルアップロードI/F表データ削除
    -- ===============================================
    BEGIN
      DELETE FROM xxccp_mrp_file_ul_interface xmfi
      WHERE  xmfi.file_id = gn_file_id
      ;
      --
    EXCEPTION
      -- *** データ削除例外ハンドラ ***
      WHEN OTHERS THEN
        -- IFデータ削除エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm      -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_10481      -- メッセージコード
                      ,iv_token_name1  => cv_tkn_err_msg          -- トークンコード1
                      ,iv_token_value1 => SQLERRM                 -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
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
  END del_if_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_file_id            IN  VARCHAR2      -- 1.ファイルID
   ,iv_format_pattern     IN  VARCHAR2      -- 2.フォーマットパターン
   ,ov_errbuf     OUT VARCHAR2      -- エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2      -- リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
--
    -- *** ローカルユーザー定義例外 ***
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
    gn_ins_cnt    := 0;  -- 登録用カウンタ
    gn_del_cnt    := 0;  -- 削除用カウンタ
--
    gv_a2_check_sts  := cv_status_normal;  -- A-2エラーチェック用
    gv_a4_check_sts  := cv_status_normal;  -- A-4エラーチェック用
--
    --===============================================
    -- 初期処理(A-1)
    --===============================================
    init(
      iv_file_id         => iv_file_id          -- ファイルID
     ,iv_format_pattern  => iv_format_pattern   -- フォーマットパターン
     ,ov_errbuf          => lv_errbuf           -- エラー・メッセージ
     ,ov_retcode         => lv_retcode          -- リターン・コード
     ,ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- 件数カウント
      gn_target_cnt := 0;  -- 対象件数
      gn_error_cnt  := 1;  -- エラー件数
      RAISE global_process_expt;
    END IF;
--
    --===============================================
    -- ファイルアップロードIFデータ取得(A-2)
    --===============================================
    get_if_data(                        -- get_if_dataをコール
      ov_errbuf  => lv_errbuf           -- エラー・メッセージ
     ,ov_retcode => lv_retcode          -- リターン・コード
     ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- 件数カウント
      gn_target_cnt := 0;  -- 対象件数
      gn_error_cnt  := 1;  -- エラー件数
      RAISE global_process_expt;
    END IF;
--
    --===============================================
    -- 一時表取得処理(A-3)、妥当性チェック処理(A-4)
    --===============================================
    loop_main(
      ov_errbuf  => lv_errbuf           -- エラー・メッセージ
     ,ov_retcode => lv_retcode          -- リターン・コード
     ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    --===============================================
    -- 変更予約情報登録処理(A-5)
    --===============================================
    ins_item_chg_data(
      ov_errbuf  => lv_errbuf           -- エラー・メッセージ
     ,ov_retcode => lv_retcode          -- リターン・コード
     ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- 件数カウント
      gn_target_cnt := 0;  -- 対象件数
      gn_error_cnt  := 1;  -- エラー件数
      RAISE global_process_expt;
    END IF;
--
    --===============================================
    -- 変更予約情報削除処理(A-6)
    --===============================================
    del_item_chg_data(
      ov_errbuf  => lv_errbuf           -- エラー・メッセージ
     ,ov_retcode => lv_retcode          -- リターン・コード
     ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- 件数カウント
      gn_target_cnt := 0;  -- 対象件数
      gn_error_cnt  := 1;  -- エラー件数
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
    errbuf                  OUT VARCHAR2      --   エラー・メッセージ  --# 固定 #
   ,retcode                 OUT VARCHAR2      --   リターン・コード    --# 固定 #
   ,iv_file_id              IN  VARCHAR2      --   ファイルID
   ,iv_format_pattern       IN  VARCHAR2      --   フォーマットパターン
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
      iv_file_id            => iv_file_id               -- ファイルID
     ,iv_format_pattern     => iv_format_pattern        -- フォーマットパターン
     ,ov_errbuf             => lv_errbuf                -- エラー・メッセージ           --# 固定 #
     ,ov_retcode            => lv_retcode               -- リターン・コード             --# 固定 #
     ,ov_errmsg             => lv_errmsg                -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --===============================================
    -- 終了処理(A-8)
    --===============================================
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
      --空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      -- エラー時のROLLBACK
      ROLLBACK;
    END IF;
--
    --===============================================
    -- ファイルアップロードデータ削除処理(A-7)
    --===============================================
    del_if_data(
      ov_errbuf  => lv_errbuf           -- エラー・メッセージ
     ,ov_retcode => lv_retcode          -- リターン・コード
     ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    -- 処理結果チェック
    IF ( lv_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000)
      );
      --空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      -- 件数カウント
      gn_target_cnt := 0;  -- 対象件数
      gn_normal_cnt := 0;  -- 成功件数
      gn_error_cnt  := 1;  -- エラー件数
      -- エラー時のROLLBACK
      ROLLBACK;
    END IF;
--
    -- ファイルアップロードデータ削除後のCOMMIT
    COMMIT;
--
    -- エラーがあれば0件で返します
    IF ( gn_error_cnt > 0 ) THEN
--
      IF ( gv_a4_check_sts <> cv_status_error ) THEN
        -- 件数カウント
        gn_target_cnt := 0;  -- 対象件数
        gn_normal_cnt := 0;  -- 成功件数
        gn_error_cnt  := 1;  -- エラー件数
      END IF;
--
      gn_ins_cnt    := 0;  -- 変更予約情報登録件数
      gn_del_cnt    := 0;  -- 変更予約情報削除件数
      --ステータスセット
      lv_retcode := cv_status_error;
    END IF;
--
    -- ===============================
    -- 変更予約情報処理件数出力
    -- ===============================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm
                    ,iv_name         => cv_msg_xxcmm_10480
                    ,iv_token_name1  => cv_tkn_ins_count
                    ,iv_token_value1 => TO_CHAR(gn_ins_cnt)
                    ,iv_token_name2  => cv_tkn_del_count
                    ,iv_token_value2 => TO_CHAR(gn_del_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
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
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスが正常以外の場合はROLLBACK
    IF ( retcode <> cv_status_normal ) THEN
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
END XXCMM004A13C;
/
