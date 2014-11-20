create or replace PACKAGE BODY      XXCFF017A04C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFF017A04C(body)
 * Description      : 自販機物件情報アップロード
 * MD.050           : MD050_CFF_017_A04_自販機物件情報アップロード
 * Version          : 1.0
 *
 * Program List
 * ---------------------------- ------------------------------------------------------------
 *  Name                         Description
 * ---------------------------- ------------------------------------------------------------
 *  init                         初期処理                              (A-1)
 *  get_for_validation           妥当性チェック用の値取得              (A-2)
 *  get_upload_data              ファイルアップロードIFデータ取得      (A-3)
 *  divide_item                  デリミタ文字項目分割(A-4)
 *  check_item_value             項目値チェック                        (A-5)
 *  ins_upload_wk                自販機物件アップロードワーク作成      (A-6)
 *  get_upload_wk                自販機物件アップロードワーク          (A-7)
 *  data_validation              データ妥当性チェック                  (A-8)
 *  ins_upd_vd_object            自販機物件情報更新                    (A-9)
 *
 *  submain                      メイン処理プロシージャ
 *  main                         コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014/07/14    1.0  SCSK 山下         新規作成
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
  -- ロックエラー
  lock_expt             EXCEPTION;
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFF017A04C'; -- パッケージ名
--
  cv_csv_delimiter   CONSTANT VARCHAR2(1) := ','; --カンマ
  cv_const_y         CONSTANT VARCHAR2(1) := 'Y'; --'Y'
  cv_const_n         CONSTANT VARCHAR2(1) := 'N'; --'N'
  cv_upload_type_col CONSTANT NUMBER := 1; -- ワークテーブル．変更区分の項目順
  cv_obj_code_col    CONSTANT NUMBER := 2; -- ワークテーブル．物件コードの項目順
--
  -- 変更区分
  cv_upload_type_1   CONSTANT VARCHAR2(1) := '1';  -- 1（移動）
  cv_upload_type_2   CONSTANT VARCHAR2(1) := '2';  -- 2（修正）
  cv_upload_type_3   CONSTANT VARCHAR2(1) := '3';  -- 3（除売却）
  -- 処理区分
  cv_process_type_103 CONSTANT VARCHAR2(3) := '103';  -- 101（移動）
  cv_process_type_104 CONSTANT VARCHAR2(3) := '104';  -- 104（修正）
  cv_process_type_105 CONSTANT VARCHAR2(3) := '105';  -- 105（除売却）
--
  -- 物件ステータス
  cv_ob_status_101    CONSTANT VARCHAR2(3) := '101';  -- 未確定
  cv_ob_status_102    CONSTANT VARCHAR2(3) := '102';  -- 確定
  cv_ob_status_103    CONSTANT VARCHAR2(3) := '103';  -- 移動
  cv_ob_status_104    CONSTANT VARCHAR2(3) := '104';  -- 修正
  cv_ob_status_105    CONSTANT VARCHAR2(3) := '105';  -- 除売却
  cv_ob_status_106    CONSTANT VARCHAR2(3) := '106';  -- 除売却未確定
--
  -- 書式マスク
  cv_date_format      CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';  -- 日付書式
  cv_format_yyyymm    CONSTANT VARCHAR2(7)   := 'YYYY-MM';     -- YYYYMM型
--
  -- 出力タイプ
  cv_file_type_out    CONSTANT VARCHAR2(10) := 'OUTPUT';      --出力(ユーザメッセージ用出力先)
  cv_file_type_log    CONSTANT VARCHAR2(10) := 'LOG';         --ログ(システム管理者用出力先)
--
  -- アプリケーション短縮名
  cv_msg_kbn_cff      CONSTANT VARCHAR2(5) := 'XXCFF'; --アドオン：会計・リース・FA領域
  cv_msg_kbn_ccp      CONSTANT VARCHAR2(5) := 'XXCCP'; --共通のメッセージ
--
  -- プロファイル
  cv_fixed_asset_register CONSTANT VARCHAR2(30) := 'XXCFF1_FIXED_ASSET_REGISTER'; -- 台帳種類_固定資産台帳
--
  -- メッセージ名
  cv_msg_name_00007   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00007';  -- ロックエラー
  cv_msg_name_00020   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00020';  -- プロファイル取得エラー
  cv_msg_name_00062   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00062';  -- 対象データなし
  cv_msg_name_00094   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00094';  -- 共通関数エラー
  cv_msg_name_00095   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00095';  -- 共通関数メッセージ
  cv_msg_name_00101   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00101';  -- 取得エラー
  cv_msg_name_00123   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00123';  -- 存在チェックエラー
  cv_msg_name_00124   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00124';  -- 項目値チェックエラー
  cv_msg_name_00159   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00159';  -- 物件エラー対象
  cv_msg_name_00167   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00167';  -- アップロード初期出力メッセージ
  cv_msg_name_00194   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00194';  -- リース月次締期間取得エラー
  cv_msg_name_00221   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00221';  -- 入力項目妥当性チェックエラー（自販機物件）
  cv_msg_name_00222   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00222';  -- 重複チェックエラー（自販機物件）
  cv_msg_name_00223   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00223';  -- 除売却処理エラー（自販機物件）
  cv_msg_name_00224   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00224';  -- 除売却ステータスエラー（自販機物件）
  cv_msg_name_00227   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00227';  -- 変更区分不正エラー（自販機物件）
  cv_msg_name_00231   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00231';  -- 除売却フラグ妥当性エラー（自販機物件）
  cv_msg_name_00232   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00232';  -- FAオープン期間外エラー（自販機物件）
  cv_msg_name_00234   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00234';  -- アップロードCSVファイル名取得エラー
  cv_msg_name_90000   CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90000';  -- 対象件数メッセージ
  cv_msg_name_90001   CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90001';  -- 成功件数メッセージ
  cv_msg_name_90002   CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90002';  -- エラー件数メッセージ
  cv_msg_name_90003   CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90003';  -- スキップ件数メッセージ
--
  -- メッセージ名(トークン)
  cv_tkn_val_50130    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50130'; --初期処理
  cv_tkn_val_50131    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50131'; --BLOBデータ変換用関数
  cv_tkn_val_50165    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50165'; --デリミタ文字分割関数
  cv_tkn_val_50166    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50166'; --項目チェック
  cv_tkn_val_50141    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50141'; --事業所マスタチェック
  cv_tkn_val_50175    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50175'; --ファイルアップロードI/F
  cv_tkn_val_50228    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50228'; -- XXCFF:台帳種類_固定資産台帳
  cv_tkn_val_50230    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50230'; -- 減価償却期間
  cv_tkn_val_50238    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50238'; -- カレンダ期間クローズ日
  cv_tkn_val_50259    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50259'; --自販機物件情報変更（移動・修正・除売却）
  cv_tkn_val_50260    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50260'; --自販機物件管理
  cv_tkn_val_50229    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50229'; --自販機物件履歴
--
  -- トークン名
  cv_tkn_name_00007    CONSTANT VARCHAR2(100) := 'TABLE_NAME';  -- テーブル
  cv_tkn_name_00094    CONSTANT VARCHAR2(100) := 'FUNC_NAME';   -- 共通関数名
  cv_tkn_name_00095    CONSTANT VARCHAR2(100) := 'ERR_MSG';     -- エラーメッセージ
  cv_tkn_name_00101    CONSTANT VARCHAR2(100) := 'INFO';        -- 固定資産情報
  cv_tkn_name_00123    CONSTANT VARCHAR2(100) := 'COLUMN_DATA'; -- 項目データ
  cv_tkn_name_00124_01 CONSTANT VARCHAR2(100) := 'COLUMN_NAME'; -- 項目名
  cv_tkn_name_00124_02 CONSTANT VARCHAR2(100) := 'COLUMN_INFO'; -- 項目情報
  cv_tkn_name_00159    CONSTANT VARCHAR2(100) := 'OBJECT_CODE'; -- 物件コード
  cv_tkn_name_00167_01 CONSTANT VARCHAR2(100) := 'FILE_NAME';   -- ファイル名トークン
  cv_tkn_name_00167_02 CONSTANT VARCHAR2(100) := 'CSV_NAME';    -- CSVファイル名トークン
  cv_tkn_name_00194    CONSTANT VARCHAR2(100) := 'BOOK_ID';     -- 会計帳簿ID
  cv_tkn_name_00020    CONSTANT VARCHAR2(100) := 'PROF_NAME';   -- プロファイル名
  cv_tkn_name_00232    CONSTANT VARCHAR2(100) := 'COL_CLOSE_DATE';   -- カレンダ期間クローズ日
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- 文字項目分割後データ格納配列
  TYPE g_load_data_ttype           IS TABLE OF VARCHAR2(600) INDEX BY PLS_INTEGER;
--
  -- 妥当性チェック用の値取得用定義
  TYPE g_column_desc_ttype         IS TABLE OF xxcff_vd_object_info_upload_v.column_desc%TYPE INDEX BY PLS_INTEGER;
  TYPE g_byte_count_ttype          IS TABLE OF xxcff_vd_object_info_upload_v.byte_count%TYPE INDEX BY PLS_INTEGER;
  TYPE g_byte_count_decimal_ttype  IS TABLE OF xxcff_vd_object_info_upload_v.byte_count_decimal%TYPE INDEX BY PLS_INTEGER;
  TYPE g_pay_match_flag_name_ttype IS TABLE OF xxcff_vd_object_info_upload_v.payment_match_flag_name%TYPE INDEX BY PLS_INTEGER;
  TYPE g_item_attribute_ttype      IS TABLE OF xxcff_vd_object_info_upload_v.item_attribute%TYPE INDEX BY PLS_INTEGER;
--
    -- 自販機物件情報アップロードワーク取得データレコード型
  TYPE g_vd_object_rtype IS RECORD(
    upload_type              xxcff_vd_object_info_upload_wk.upload_type%TYPE,            -- 変更区分
    object_code              xxcff_vd_object_info_upload_wk.object_code%TYPE,            -- 物件コード
    owner_company_type       xxcff_vd_object_info_upload_wk.owner_company_type%TYPE,     -- 本社／工場区分
    department_code          xxcff_vd_object_info_upload_wk.department_code%TYPE,        -- 管理部門
    moved_date               xxcff_vd_object_info_upload_wk.moved_date%TYPE,             -- 移動日
    installation_place       xxcff_vd_object_info_upload_wk.installation_place%TYPE,     -- 設置先
    installation_address     xxcff_vd_object_info_upload_wk.installation_address%TYPE,   -- 設置場所
    dclr_place               xxcff_vd_object_info_upload_wk.dclr_place%TYPE,             -- 申告地
    location                 xxcff_vd_object_info_upload_wk.location%TYPE,               -- 事業所
    manufacturer_name        xxcff_vd_object_info_upload_wk.manufacturer_name%TYPE,      -- メーカー名
    model                    xxcff_vd_object_info_upload_wk.model%TYPE,                  -- 機種
    age_type                 xxcff_vd_object_info_upload_wk.age_type%TYPE,               -- 年式
    quantity                 xxcff_vd_object_info_upload_wk.quantity%TYPE,               -- 数量
    date_placed_in_service   xxcff_vd_object_info_upload_wk.date_placed_in_service%TYPE, -- 事業供用日
    assets_date              xxcff_vd_object_info_upload_wk.assets_date%TYPE,            -- 取得日
    assets_cost              xxcff_vd_object_info_upload_wk.assets_cost%TYPE,            -- 取得価格
--    month_lease_charge       xxcff_vd_object_info_upload_wk.month_lease_charge%TYPE,     -- 月額リース料
--    re_lease_charge          xxcff_vd_object_info_upload_wk.re_lease_charge%TYPE,        -- 再リース料
    date_retired             xxcff_vd_object_info_upload_wk.date_retired%TYPE,           -- 除・売却日
    proceeds_of_sale         xxcff_vd_object_info_upload_wk.proceeds_of_sale%TYPE,       -- 売却価格
    cost_of_removal          xxcff_vd_object_info_upload_wk.cost_of_removal%TYPE,        -- 撤去費用
    retired_flag             xxcff_vd_object_info_upload_wk.retired_flag%TYPE,           -- 除売却確定フラグ
    xvoh_owner_company_type       xxcff_vd_object_headers.owner_company_type%TYPE,         -- 本社／工場区分
    xvoh_department_code          xxcff_vd_object_headers.department_code%TYPE,            -- 管理部門
    xvoh_moved_date               xxcff_vd_object_headers.moved_date%TYPE,                 -- 移動日
    xvoh_installation_place       xxcff_vd_object_headers.installation_place%TYPE,         -- 設置先
    xvoh_installation_address     xxcff_vd_object_headers.installation_address%TYPE,       -- 設置場所
    xvoh_dclr_place               xxcff_vd_object_headers.dclr_place%TYPE,                 -- 申告地
    xvoh_location                 xxcff_vd_object_headers.location%TYPE,                   -- 事業所 
    xvoh_manufacturer_name        xxcff_vd_object_headers.manufacturer_name%TYPE,          -- メーカー名
    xvoh_model                    xxcff_vd_object_headers.model%TYPE,                      -- 機種
    xvoh_age_type                 xxcff_vd_object_headers.age_type%TYPE,                   -- 年式
    xvoh_quantity                 xxcff_vd_object_headers.quantity%TYPE,                   -- 数量
    xvoh_date_placed_in_service   xxcff_vd_object_headers.date_placed_in_service%TYPE,     -- 事業供用日
    xvoh_assets_date              xxcff_vd_object_headers.assets_date%TYPE,                -- 取得日
    xvoh_assets_cost              xxcff_vd_object_headers.assets_cost%TYPE,                -- 取得価格
--    xvoh_month_lease_charge       xxcff_vd_object_headers.month_lease_charge%TYPE,         -- 月額リース料
--    xvoh_re_lease_charge          xxcff_vd_object_headers.re_lease_charge%TYPE,            -- 再リース料
    xvoh_date_retired             xxcff_vd_object_headers.date_retired%TYPE,               -- 除・売却日
    xvoh_proceeds_of_sale         xxcff_vd_object_headers.proceeds_of_sale%TYPE,           -- 売却価格
    xvoh_cost_of_removal          xxcff_vd_object_headers.cost_of_removal%TYPE,            -- 撤去費用
    xvoh_retired_flag             xxcff_vd_object_headers.retired_flag%TYPE,               -- 除売却確定フラグ
    xvoh_object_header_id         xxcff_vd_object_headers.object_header_id%TYPE,           -- 物件ID
    xvoh_object_status            xxcff_vd_object_headers.object_status%TYPE,              -- 物件ステータス
    xvoh_machine_type             xxcff_vd_object_headers.machine_type%TYPE,               -- 機器区分
    xvoh_customer_code            xxcff_vd_object_headers.customer_code%TYPE,              -- 顧客コード
    xvoh_ib_if_date               xxcff_vd_object_headers.ib_if_date%TYPE                  -- 設置ベース情報連携日
  );
--
  -- 自販機物件管理情報取込対象データレコード配列
  TYPE g_vd_object_ttype IS TABLE OF g_vd_object_rtype
  INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  -- 初期値情報
  g_init_rec                     xxcff_common1_pkg.init_rtype;
--
  --ファイルアップロードIFデータ
  g_file_upload_if_data_tab      xxccp_common_pkg2.g_file_data_tbl;
--
  --文字項目分割後データ格納配列
  g_load_data_tab                g_load_data_ttype;
--
  --CSVの物件コードを保持
  g_csv_object_code              VARCHAR2(100);
--
  -- 項目値チェック用の値取得用定義
  g_column_desc_tab              g_column_desc_ttype;
  g_byte_count_tab               g_byte_count_ttype;
  g_byte_count_decimal_tab       g_byte_count_decimal_ttype;
  g_pay_match_flag_name_tab      g_pay_match_flag_name_ttype;
  g_item_attribute_tab           g_item_attribute_ttype;
--
  -- 妥当性チェック用の変数
  gv_object_code_pre              VARCHAR2(100);
  gv_upload_type_pre              VARCHAR2(100);
--
  -- 自販機物件情報アップロードワーク取得対象データ
  g_vd_object_tab  g_vd_object_ttype;
--
  -- プロファイル値
  gv_fixed_asset_register  VARCHAR2(100); -- 台帳種類_固定資産台帳
--
  -- カレンダ期間クローズ日
  g_cal_per_close_date     DATE;
--
  -- エラーフラグ
  gb_err_flag                    BOOLEAN;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    in_file_id    IN  NUMBER,       --   1.ファイルID
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_file_name    xxccp_mrp_file_ul_interface.file_name%TYPE; -- 取得ファイル名
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
    BEGIN
      -- アップロードCSVファイル名取得
      SELECT  xfu.file_name
        INTO  lv_file_name
        FROM  xxccp_mrp_file_ul_interface  xfu
       WHERE  xfu.file_id = in_file_id;
    EXCEPTION
      -- アップロードCSVファイル名が取得できない場合
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff -- XXCFF
                                        ,cv_msg_name_00234)    -- アップロードCSVファイル名取得エラー
                                        ,1
                                        ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
    -- ファイル名を出力（ログ）
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
     ,buff   => xxccp_common_pkg.get_msg(cv_msg_kbn_cff, cv_msg_name_00167
                                        ,cv_tkn_name_00167_01,   cv_tkn_val_50259
                                        ,cv_tkn_name_00167_02,    lv_file_name)
    );
    -- ファイル名を出力（出力）
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => xxccp_common_pkg.get_msg(cv_msg_kbn_cff, cv_msg_name_00167
                                         ,cv_tkn_name_00167_01,   cv_tkn_val_50259
                                         ,cv_tkn_name_00167_02,    lv_file_name)
    );
--
    -- コンカレントパラメータ値出力(ログ)
    xxcff_common1_pkg.put_log_param(
       iv_which         => cv_file_type_log    -- 出力区分
      ,ov_errbuf        => lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,ov_retcode       => lv_retcode          -- リターン・コード             --# 固定 #
      ,ov_errmsg        => lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    -- コンカレントパラメータ値出力(出力)
    xxcff_common1_pkg.put_log_param(
       iv_which         => cv_file_type_out    -- 出力区分
      ,ov_errbuf        => lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,ov_retcode       => lv_retcode          -- リターン・コード             --# 固定 #
      ,ov_errmsg        => lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    -- 初期値情報の取得
    xxcff_common1_pkg.init(
       or_init_rec => g_init_rec           -- 初期値情報
      ,ov_errbuf   => lv_errbuf            -- エラー・メッセージ           --# 固定 #
      ,ov_retcode  => lv_retcode           -- リターン・コード             --# 固定 #
      ,ov_errmsg   => lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 初期値情報が取得出来なかった場合
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff        -- XXCFF
                                                    ,cv_msg_name_00094     -- 共通関数エラー
                                                    ,cv_tkn_name_00094     -- トークン'FUNC_NAME'
                                                    ,cv_tkn_val_50130 )    -- 初期処理
                                                    || cv_msg_part
                                                    || lv_errmsg           -- ユーザー・エラー・メッセージ
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- プロファイル値の取得 XXCFF:台帳種類_固定資産台帳
    gv_fixed_asset_register := FND_PROFILE.VALUE(cv_fixed_asset_register);
    IF (gv_fixed_asset_register IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff      -- XXCFF
                                                    ,cv_msg_name_00020   -- プロファイル取得エラー
                                                    ,cv_tkn_name_00020   -- トークン'PROF_NAME'
                                                    ,cv_tkn_val_50228)  -- XXCFF:台帳種類_固定資産台帳
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    BEGIN
      -- 最新のカレンダ期間クローズ日を取得
      SELECT  MAX(calendar_period_close_date)                   -- カレンダ期間クローズ日
      INTO    g_cal_per_close_date
      FROM    fa_deprn_periods     fdp
      WHERE   fdp.book_type_code   = gv_fixed_asset_register    -- 台帳種類
      AND     fdp.period_close_date IS NOT NULL                 -- クローズなし
      ;
    EXCEPTION
      -- カレンダ期間クローズ日が取得できない場合
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff -- XXCFF
                                        ,cv_msg_name_00101    -- 取得エラー
                                        ,cv_tkn_name_00007    -- トークン'TABLE_NAME'
                                        ,cv_tkn_val_50230     -- 減価償却期間
                                        ,cv_tkn_name_00101    -- トークン'INFO'
                                        ,cv_tkn_val_50238)    -- カレンダ期間クローズ日
                                        ,1
                                        ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
  --==============================================================
  --メッセージ出力をする必要がある場合は処理を記述
  --==============================================================
--
--#################################  固定例外処理部 START   ####################################
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
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_for_validation
   * Description      : 妥当性チェック用の値取得処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_for_validation(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_for_validation'; -- プログラム名
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
    CURSOR get_validate_cur
    IS
      SELECT  xoa.column_desc               AS column_desc               -- 項目名称
              ,xoa.byte_count               AS byte_count                -- バイト数
              ,xoa.byte_count_decimal       AS byte_count_decimal        -- バイト数_小数点以下
              ,xoa.payment_match_flag_name  AS payment_match_flag_name   -- 必須フラグ
              ,xoa.item_attribute           AS item_attribute            -- 項目属性
        FROM  xxcff_vd_object_info_upload_v  xoa  -- 自販機物件情報変更ビュー
    ORDER BY  xoa.code ASC
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --カーソルのオープン
    OPEN get_validate_cur;
    FETCH get_validate_cur
    BULK COLLECT INTO g_column_desc_tab          --項目名称
                     ,g_byte_count_tab           --バイト数
                     ,g_byte_count_decimal_tab   --バイト数_小数点以下
                     ,g_pay_match_flag_name_tab  --必須フラグ
                     ,g_item_attribute_tab       --項目属性
    ;
--
    --カーソルのクローズ
    CLOSE get_validate_cur;
--
--#################################  固定例外処理部 START   ####################################
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
      IF ( get_validate_cur%ISOPEN ) THEN
        CLOSE get_validate_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_for_validation;
--
  /**********************************************************************************
   * Procedure Name   : get_upload_data
   * Description      : ファイルアップロードIFデータ取得処理(A-3)
   ***********************************************************************************/
  PROCEDURE get_upload_data(
    in_file_id    IN  NUMBER,       --   1.ファイルID
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_upload_data'; -- プログラム名
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
    -- ファイルアップロードIFデータを取得
    xxccp_common_pkg2.blob_to_varchar2(
      in_file_id   => in_file_id                 -- ファイルID
     ,ov_file_data => g_file_upload_if_data_tab  -- 変換後VARCHAR2データ
     ,ov_errbuf    => lv_errbuf                  -- エラー・メッセージ           --# 固定 #
     ,ov_retcode   => lv_retcode                 -- リターン・コード             --# 固定 #
     ,ov_errmsg    => lv_errmsg                  -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 共通関数エラーの場合
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_name_00094    -- 共通関数エラー
                                                    ,cv_tkn_name_00094    -- トークン'FUNC_NAME'
                                                    ,cv_tkn_val_50131 )   -- BLOBデータ変換用関数
                                                    || cv_msg_part
                                                    || lv_errmsg          --共通関数内ｴﾗｰﾒｯｾｰｼﾞ
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
--#################################  固定例外処理部 START   ####################################
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
--
--#####################################  固定部 END   ##########################################
--
  END get_upload_data;
--
  /**********************************************************************************
   * Procedure Name   : divide_item
   * Description      : デリミタ文字項目分割処理(A-4)
   ***********************************************************************************/
  PROCEDURE divide_item(
    in_loop_cnt_1 IN  NUMBER,       --   ループカウンタ1
    in_loop_cnt_2 IN  NUMBER,       --   ループカウンタ2
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'divide_item'; -- プログラム名
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
    --デリミタ文字分割の共通関数の呼出
    g_load_data_tab(in_loop_cnt_2) := xxccp_common_pkg.char_delim_partition(
                                        g_file_upload_if_data_tab(in_loop_cnt_1) --分割元文字列(取得データ)
                                       ,cv_csv_delimiter                         --デリミタ文字
                                       ,in_loop_cnt_2                            --返却対象INDEX
    );
    -- 処理中の物件コードを保持
    IF ( in_loop_cnt_2 = cv_obj_code_col ) THEN
      g_csv_object_code := g_load_data_tab(in_loop_cnt_2);
    END IF;
--
--#################################  固定例外処理部 START   ####################################
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN 
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      --エラーフラグをTRUEにする
      gb_err_flag := TRUE;
      --エラーメッセージを出力する
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff      -- XXCFF
                                                    ,cv_msg_name_00094   -- 共通関数エラー
                                                    ,cv_tkn_name_00094   -- トークン'FUNC_NAME'
                                                    ,cv_tkn_val_50165 )  -- デリミタ文字分割関数
                                                    ,1
                                                    ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  -- メッセージ出力
        ,buff   => lv_errmsg
      );
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END divide_item;
--
  /**********************************************************************************
   * Procedure Name   : check_item_value
   * Description      : 項目値チェック処理(A-5)
   ***********************************************************************************/
  PROCEDURE check_item_value(
    in_loop_cnt_2 IN  NUMBER,       -- ループカウンタ2
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_item_value'; -- プログラム名
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
    lv_warn_msg  VARCHAR2(5000); --警告メッセージ
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
    -- 項目チェックの共通関数の呼出
    xxccp_common_pkg2.upload_item_check(
       iv_item_name    => g_column_desc_tab(in_loop_cnt_2)          -- 項目名称
      ,iv_item_value   => g_load_data_tab(in_loop_cnt_2)            -- 項目の値
      ,in_item_len     => g_byte_count_tab(in_loop_cnt_2)           -- バイト数/項目の長さ
      ,in_item_decimal => g_byte_count_decimal_tab(in_loop_cnt_2)   -- バイト数_小数点以下/項目の長さ（小数点以下）
      ,iv_item_nullflg => g_pay_match_flag_name_tab(in_loop_cnt_2)  -- 必須フラグ
      ,iv_item_attr    => g_item_attribute_tab(in_loop_cnt_2)       -- 項目属性
      ,ov_errbuf       => lv_errbuf                                 -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode                                -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg                                 -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- リターンコードが警告の場合（対象データに不備があった場合）
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff           -- XXCFF
                                                      ,cv_msg_name_00094        -- 共通関数エラー
                                                      ,cv_tkn_name_00094        -- トークン'FUNC_NAME'
                                                      ,cv_tkn_val_50166  )      -- 共通関数名
                                                      ,1
                                                      ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_warn_msg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_warn_msg
      );
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff             -- XXCFF
                                                    ,cv_msg_name_00095          -- 共通関数メッセージ
                                                    ,cv_tkn_name_00095          -- トークン'ERR_MSG'
                                                    ,lv_errmsg                  -- ユーザー・エラー・メッセージ
                                                   )
                                                   || xxccp_common_pkg.get_msg(
                                                        cv_msg_kbn_cff          -- XXCFF
                                                       ,cv_msg_name_00159       -- 物件エラー対象
                                                       ,cv_tkn_name_00159       -- トークン'OBJECT_CODE'
                                                       ,g_csv_object_code       -- CSVの物件コード
                                                      )
                                                    ,1
                                                    ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
      -- エラーフラグを更新
      gb_err_flag := TRUE;
    -- リターンコードがエラーの場合（項目チェックでシステムエラーが発生した場合）
    ELSIF ( lv_retcode <> cv_status_normal ) THEN
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
--#################################  固定例外処理部 START   ####################################
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
--
--#####################################  固定部 END   ##########################################
--
  END check_item_value;
--
  /**********************************************************************************
   * Procedure Name   : ins_upload_wk
   * Description      : 自販機物件情報アップロードワーク作成処理(A-6)
   ***********************************************************************************/
  PROCEDURE ins_upload_wk(
    in_file_id    IN  NUMBER,       --   1.ファイルID
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_upload_wk'; -- プログラム名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 自販機物件情報アップロードワーク作成
    INSERT INTO xxcff_vd_object_info_upload_wk (
      file_id                   -- ファイルID
     ,upload_type               -- 変更区分
     ,object_code               -- 物件コード
     ,history_num               -- 履歴番号
     ,process_type              -- 処理区分
     ,process_date              -- 処理日
     ,object_status             -- 物件ステータス
     ,owner_company_type        -- 本社;工場区分
     ,department_code           -- 管理部門
     ,machine_type              -- 機器区分
     ,vendor_code               -- 仕入先コード
     ,manufacturer_name         -- メーカ名
     ,model                     -- 機種
     ,age_type                  -- 年式
     ,customer_code             -- 顧客コード
     ,quantity                  -- 数量
     ,date_placed_in_service    -- 事業供用日
     ,assets_cost               -- 取得価格
--     ,month_lease_charge        -- 月額リース料
--     ,re_lease_charge           -- 再リース料
     ,assets_date               -- 取得日
     ,moved_date                -- 移動日
     ,installation_place        -- 設置先
     ,installation_address      -- 設置場所
     ,dclr_place                -- 申告地
     ,location                  -- 事業所
     ,date_retired              -- 除･売却日
     ,proceeds_of_sale          -- 売却価額
     ,cost_of_removal           -- 撤去費用
     ,retired_flag              -- 除売却確定フラグ
     ,ib_if_date                -- 設置ベース情報連携日
     ,fa_if_date                -- FA情報連携日
     ,ob_last_updated_by        -- 物件管理_最終更新者
     ,created_by                -- 作成者
     ,creation_date             -- 作成日
     ,last_updated_by           -- 最終更新者
     ,last_update_date          -- 最終更新日
     ,last_update_login         -- 最終更新ログイン
     ,request_id                -- 要求ID
     ,program_application_id    -- コンカレント・プログラム・アプリケーションID
     ,program_id                -- コンカレント・プログラムID
     ,program_update_date       -- プログラム更新日
    )
    VALUES (
      in_file_id                -- ファイルID
     ,g_load_data_tab(1)        -- 変更区分
     ,g_load_data_tab(2)        -- 物件コード
     ,g_load_data_tab(3)        -- 履歴番号
     ,g_load_data_tab(4)        -- 処理区分
     ,g_load_data_tab(5)        -- 処理日
     ,g_load_data_tab(6)        -- 物件ステータス
     ,g_load_data_tab(7)        -- 本社;工場区分
     ,g_load_data_tab(8)        -- 管理部門
     ,g_load_data_tab(9)        -- 機器区分
     ,g_load_data_tab(10)       -- 仕入先コード
     ,g_load_data_tab(11)       -- メーカ名
     ,g_load_data_tab(12)       -- 機種
     ,g_load_data_tab(13)       -- 年式
     ,g_load_data_tab(14)       -- 顧客コード
     ,g_load_data_tab(15)       -- 数量
     ,g_load_data_tab(16)       -- 事業供用日
     ,g_load_data_tab(17)       -- 取得価格
--     ,g_load_data_tab(17)       -- 月額リース料
--     ,g_load_data_tab(18)       -- 再リース料
     ,g_load_data_tab(18)       -- 取得日
     ,g_load_data_tab(19)       -- 移動日
     ,g_load_data_tab(20)       -- 設置先
     ,g_load_data_tab(21)       -- 設置場所
     ,g_load_data_tab(22)       -- 申告地
     ,g_load_data_tab(23)       -- 事業所
     ,g_load_data_tab(24)       -- 除･売却日
     ,g_load_data_tab(25)       -- 売却価額
     ,g_load_data_tab(26)       -- 撤去費用
     ,g_load_data_tab(27)       -- 除売却確定フラグ
     ,g_load_data_tab(28)       -- 設置ベース情報連携日
     ,g_load_data_tab(29)       -- FA情報連携日
     ,g_load_data_tab(30)       -- 物件管理_最終更新者
     ,cn_created_by             -- 作成者
     ,cd_creation_date          -- 作成日
     ,cn_last_updated_by        -- 最終更新者
     ,cd_last_update_date       -- 最終更新日
     ,cn_last_update_login      -- 最終更新ログイン
     ,cn_request_id             -- 要求ID
     ,cn_program_application_id -- コンカレント・プログラム・アプリケーションI
     ,cn_program_id             -- コンカレント・プログラムID
     ,cd_program_update_date    -- プログラム更新日
    );
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
  EXCEPTION
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
      ov_errmsg  := SQLERRM;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_upload_wk;
--
  /**********************************************************************************
   * Procedure Name   : get_upload_wk
   * Description      : 自販機物件情報アップロードワーク取得処理(A-7)
   ***********************************************************************************/
  PROCEDURE get_upload_wk(
    in_file_id    IN  NUMBER,       --   1.ファイルID
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_upload_wk'; -- プログラム名
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
    CURSOR get_vd_object_upload_wk_cur
    IS
      SELECT
              xvoiu.upload_type             AS upload_type           -- 変更区分
             ,xvoiu.object_code             AS object_code           -- 物件コード
             ,xvoiu.owner_company_type      AS owner_company_type    -- 本社/工場区分
             ,xvoiu.department_code         AS department_code       -- 管理部門
             ,xvoiu.moved_date              AS moved_date            -- 移動日
             ,xvoiu.installation_place      AS installation_place    -- 設置先
             ,xvoiu.installation_address    AS installation_address  -- 設置場所
             ,xvoiu.dclr_place              AS dclr_place            -- 申告地
             ,xvoiu.location                AS location              -- 事業所
             ,xvoiu.manufacturer_name       AS manufacturer_name     -- メーカー名
             ,xvoiu.model                   AS model                 -- 機種
             ,xvoiu.age_type                AS age_type              -- 年式
             ,xvoiu.quantity                AS quantity              -- 数量
             ,xvoiu.date_placed_in_service  AS date_placed_in_service-- 事業供用日
             ,xvoiu.assets_date             AS assets_date           -- 取得日
             ,xvoiu.assets_cost             AS assets_cost           -- 取得価格
--             ,xvoiu.month_lease_charge      AS month_lease_charge    -- 月額リース料
--             ,xvoiu.re_lease_charge         AS re_lease_charge       -- 再リース料
             ,xvoiu.date_retired            AS date_retired          -- 除・売却日
             ,xvoiu.proceeds_of_sale        AS proceeds_of_sale      -- 売却価格
             ,xvoiu.cost_of_removal         AS cost_of_removal       -- 撤去費用
             ,xvoiu.retired_flag            AS retired_flag          -- 除売却確定フラグ
             ,xvoh.owner_company_type       AS xvoh_owner_company_type     -- 本社工場(物件管理)
             ,xvoh.department_code          AS xvoh_department_code        -- 管理部門(物件管理)
             ,xvoh.moved_date               AS xvoh_moved_date             -- 管理部門(物件管理)
             ,xvoh.installation_place       AS xvoh_installation_place     -- 設置先(物件管理)
             ,xvoh.installation_address     AS xvoh_installation_address   -- 設置場所(物件管理)
             ,xvoh.dclr_place               AS xvoh_dclr_place             -- 申告地(物件管理)
             ,xvoh.location                 AS xvoh_location               -- 事業所(物件管理)
             ,xvoh.manufacturer_name        AS xvoh_manufacturer_name      -- メーカー名(物件管理)
             ,xvoh.model                    AS xvoh_model                  -- 機種(物件管理)
             ,xvoh.age_type                 AS xvoh_age_type               -- 年式(物件管理)
             ,xvoh.quantity                 AS xvoh_quantity               -- 数量(物件管理)
             ,xvoh.date_placed_in_service   AS xvoh_date_placed_in_service -- 事業供用日(物件管理)
             ,xvoh.assets_date              AS xvoh_assets_date            -- 取得日(物件管理)
             ,xvoh.assets_cost              AS xvoh_assets_cost            -- 取得価格(物件管理)
--             ,xvoh.month_lease_charge       AS xvoh_month_lease_charge     -- 月額リース料(物件管理)
--             ,xvoh.re_lease_charge          AS xvoh_re_lease_charge        -- 再リース料(物件管理)
             ,xvoh.date_retired             AS xvoh_date_retired           -- 除・売却日(物件管理)
             ,xvoh.proceeds_of_sale         AS xvoh_proceeds_of_sale       -- 売却価格(物件管理)
             ,xvoh.cost_of_removal          AS xvoh_cost_of_removal        -- 撤去費用(物件管理)
             ,xvoh.retired_flag             AS xvoh_retired_flag           -- 除売却確定フラグ(物件管理)
             ,xvoh.object_header_id         AS xvoh_object_header_id       -- 物件ID(物件管理)
             ,xvoh.object_status            AS xvoh_object_status          -- 物件ステータス(物件管理)
             ,xvoh.machine_type             AS xvoh_machine_type           -- 機器区分(物件管理)
             ,xvoh.customer_code            AS xvoh_customer_code          -- 顧客コード(物件管理)
             ,xvoh.ib_if_date               AS xvoh_ib_if_date             -- 設置ベース情報連携日(物件管理)
        FROM
              xxcff_vd_object_info_upload_wk  xvoiu  -- 自販機物件情報アップロードワーク
             ,xxcff_vd_object_headers         xvoh   -- 自販機物件管理
       WHERE
              xvoiu.object_code = xvoh.object_code(+)      --物件コード
         AND  xvoiu.file_id     = in_file_id               --ファイルID
       ORDER BY
              xvoiu.object_code
             ,xvoiu.upload_type
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 自販機物件アップロードワーク取得
    OPEN  get_vd_object_upload_wk_cur;
    FETCH get_vd_object_upload_wk_cur BULK COLLECT INTO g_vd_object_tab;
    CLOSE get_vd_object_upload_wk_cur;
--
--#################################  固定例外処理部 START   ####################################
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
      IF ( get_vd_object_upload_wk_cur%ISOPEN ) THEN
        CLOSE get_vd_object_upload_wk_cur;
      END IF;
      ov_errmsg  := SQLERRM;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_upload_wk;
--
  /**********************************************************************************
   * Procedure Name   : data_validation
   * Description      : データ妥当性チェック処理(A-8)
   ***********************************************************************************/
  PROCEDURE data_validation(
    in_rec_no     IN  NUMBER,       --   対象レコード番号
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'data_validation'; -- プログラム名
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
    lv_warn_msg    VARCHAR2(5000);      -- 警告メッセージ
    ln_normal_cnt  PLS_INTEGER := 0;    -- 正常カウンター
    ln_error_cnt   PLS_INTEGER := 0;    -- エラーカウンター
    ln_location_id NUMBER;              -- 事業所ID
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
    -- エラーフラグの初期化
    gb_err_flag := FALSE;
--
    -- ①物件存在チェック
    IF ( g_vd_object_tab(in_rec_no).xvoh_object_status IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                       -- XXCFF
                                                      ,cv_msg_name_00123                    -- 存在チェックエラー
                                                      ,cv_tkn_name_00123                    -- トークン'COLUMN_DATA'
                                                      ,g_vd_object_tab(in_rec_no).object_code ) -- 物件コード
                                                      ,1
                                                      ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
      -- エラーフラグを更新
      gb_err_flag := TRUE;
    END IF;
--
    -- ②マスタチェック
    -- 共通関数(事業所マスタチェック)の呼び出し
    xxcff_common1_pkg.chk_fa_location(
      iv_segment1    => NVL( g_vd_object_tab(in_rec_no).dclr_place
                              ,g_vd_object_tab(in_rec_no).xvoh_dclr_place ),          -- 申告地
      iv_segment2    => NVL( g_vd_object_tab(in_rec_no).department_code
                              ,g_vd_object_tab(in_rec_no).xvoh_department_code ),     -- 管理部門
      iv_segment3    => NVL( g_vd_object_tab(in_rec_no).location
                              ,g_vd_object_tab(in_rec_no).xvoh_location ),            -- 事業所
      iv_segment5    => NVL( g_vd_object_tab(in_rec_no).owner_company_type
                              ,g_vd_object_tab(in_rec_no).xvoh_owner_company_type ),  -- 本社／工場区分
      on_location_id => ln_location_id,  -- 事業所ID
      ov_retcode     => lv_retcode,      -- リターンコード
      ov_errbuf      => lv_errbuf,       -- エラーメッセージ
      ov_errmsg      => lv_errmsg        -- ユーザー・エラーメッセージ
    );
    IF (lv_retcode = cv_status_error) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_name_00094    -- 共通関数エラー
                                                    ,cv_tkn_name_00094    -- トークン'FUNC_NAME'
                                                    ,cv_tkn_val_50141 )   -- 事業所マスタチェック
                                                    || cv_msg_part
                                                    || lv_errmsg          --共通関数内ｴﾗｰﾒｯｾｰｼﾞ
                                                    || xxccp_common_pkg.get_msg(
                                                        cv_msg_kbn_cff          -- XXCFF
                                                       ,cv_msg_name_00159       -- 物件エラー対象
                                                       ,cv_tkn_name_00159       -- トークン'OBJECT_CODE'
                                                       ,g_vd_object_tab(in_rec_no).object_code  -- 物件コード
                                                      )
                                                    ,1
                                                    ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
      -- エラーフラグを更新
      gb_err_flag := TRUE;
    END IF;
    --
    -- ③入力項目妥当性チェック
    -- 変更区分が「1（移動）の場合」
    IF ( g_vd_object_tab(in_rec_no).upload_type = cv_upload_type_1 ) THEN
      -- 下記項目が全てNULLの場合はエラー
      IF ( COALESCE(
              g_vd_object_tab(in_rec_no).owner_company_type                  -- 本社／工場区分
             ,g_vd_object_tab(in_rec_no).department_code                     -- 管理部門
             ,TO_CHAR(g_vd_object_tab(in_rec_no).moved_date,cv_date_format)  -- 移動日
             ,g_vd_object_tab(in_rec_no).installation_place                  -- 設置先
             ,g_vd_object_tab(in_rec_no).installation_address                -- 設置場所
             ,g_vd_object_tab(in_rec_no).dclr_place                          -- 申告地
             ,g_vd_object_tab(in_rec_no).location                            -- 事業所
           ) IS NULL
      )
      THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff           -- XXCFF
                                                    ,cv_msg_name_00221          -- 入力項目妥当性チェックエラー（自販機物件）
                                                   )
                                                   || xxccp_common_pkg.get_msg(
                                                        cv_msg_kbn_cff          -- XXCFF
                                                       ,cv_msg_name_00159       -- 物件エラー対象
                                                       ,cv_tkn_name_00159       -- トークン'OBJECT_CODE'
                                                       ,g_vd_object_tab(in_rec_no).object_code  -- 物件コード
                                                      )
                                                    ,1
                                                    ,5000);
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
         ,buff   => lv_errmsg
        );
        -- エラーフラグを更新
        gb_err_flag := TRUE;
      END IF;
--
    -- 変更区分が「2（修正）の場合」
    ELSIF ( g_vd_object_tab(in_rec_no).upload_type = cv_upload_type_2 ) THEN
      -- 下記項目が全てNULLの場合はエラー
      IF ( COALESCE(
              g_vd_object_tab(in_rec_no).manufacturer_name                              -- メーカー名
             ,g_vd_object_tab(in_rec_no).model                                          -- 機種
             ,g_vd_object_tab(in_rec_no).age_type                                       -- 年式
             ,TO_CHAR(g_vd_object_tab(in_rec_no).quantity)                              -- 数量
             ,TO_CHAR(g_vd_object_tab(in_rec_no).date_placed_in_service,cv_date_format) -- 事業供用日
             ,TO_CHAR(g_vd_object_tab(in_rec_no).assets_date,cv_date_format)            -- 取得日
             ,TO_CHAR(g_vd_object_tab(in_rec_no).assets_cost)                           -- 取得価格
--             ,TO_CHAR(g_vd_object_tab(in_rec_no).month_lease_charge)                    -- 月額リース料
--             ,TO_CHAR(g_vd_object_tab(in_rec_no).re_lease_charge)                       -- 再リース料
           ) IS NULL 
      )
      THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff           -- XXCFF
                                                    ,cv_msg_name_00221          -- 入力項目妥当性チェックエラー（自販機物件）
                                                   )
                                                   || xxccp_common_pkg.get_msg(
                                                        cv_msg_kbn_cff          -- XXCFF
                                                       ,cv_msg_name_00159       -- 物件エラー対象
                                                       ,cv_tkn_name_00159       -- トークン'OBJECT_CODE'
                                                       ,g_vd_object_tab(in_rec_no).object_code  -- 物件コード
                                                      )
                                                    ,1
                                                    ,5000);
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
         ,buff   => lv_errmsg
        );
        -- エラーフラグを更新
        gb_err_flag := TRUE;
      END IF;
--
    -- 変更区分が「3（除売却）の場合」
    ELSIF ( g_vd_object_tab(in_rec_no).upload_type = cv_upload_type_3 ) THEN
      -- 下記項目が全てNULLの場合、または除売却確定フラグが設定されていない場合はエラー
      IF ( (COALESCE(
               TO_CHAR(g_vd_object_tab(in_rec_no).date_retired,cv_date_format)  -- 除・売却日
              ,TO_CHAR(g_vd_object_tab(in_rec_no).proceeds_of_sale)             -- 売却価格
              ,TO_CHAR(g_vd_object_tab(in_rec_no).cost_of_removal)              -- 撤去費用
            ) IS NULL
      )
      OR ( g_vd_object_tab(in_rec_no).retired_flag IS NULL )                -- 除売却確定フラグ
      )   
      THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff           -- XXCFF
                                                    ,cv_msg_name_00221          -- 入力項目妥当性チェックエラー（自販機物件）
                                                   )
                                                   || xxccp_common_pkg.get_msg(
                                                        cv_msg_kbn_cff          -- XXCFF
                                                       ,cv_msg_name_00159       -- 物件エラー対象
                                                       ,cv_tkn_name_00159       -- トークン'OBJECT_CODE'
                                                       ,g_vd_object_tab(in_rec_no).object_code  -- 物件コード
                                                      )
                                                    ,1
                                                    ,5000);
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
         ,buff   => lv_errmsg
        );
        -- エラーフラグを更新
        gb_err_flag := TRUE;
      END IF;
    -- 変更区分が上記以外の場合
    ELSE
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff     -- XXCFF
                                            ,cv_msg_name_00227          -- 変更区分不正エラー（自販機物件）
                                           )
                                           || xxccp_common_pkg.get_msg(
                                                cv_msg_kbn_cff          -- XXCFF
                                               ,cv_msg_name_00159       -- 物件エラー対象
                                               ,cv_tkn_name_00159       -- トークン'OBJECT_CODE'
                                               ,g_vd_object_tab(in_rec_no).object_code  -- 物件コード
                                              )
                                            ,1
                                            ,5000);
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
      -- エラーフラグを更新
      gb_err_flag := TRUE;
    END IF;
--
    -- ④重複チェック
    -- 1つの物件コードに対して同一の変更区分が設定されている場合はエラー
    IF ( ( g_vd_object_tab(in_rec_no).object_code = gv_object_code_pre )
    AND (  g_vd_object_tab(in_rec_no).upload_type = gv_upload_type_pre )
    )
    THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff     -- XXCFF
                                           ,cv_msg_name_00222          -- 重複チェックエラー（自販機物件）
                                          )
                                          || xxccp_common_pkg.get_msg(
                                               cv_msg_kbn_cff          -- XXCFF
                                              ,cv_msg_name_00159       -- 物件エラー対象
                                              ,cv_tkn_name_00159       -- トークン'OBJECT_CODE'
                                              ,g_vd_object_tab(in_rec_no).object_code  -- 物件コード
                                             )
                                           ,1
                                           ,5000);
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
      -- エラーフラグを更新
      gb_err_flag := TRUE;
    END IF;
--
    -- 物件コードと変更区分を保存
    gv_object_code_pre  := g_vd_object_tab(in_rec_no).object_code;
    gv_upload_type_pre := g_vd_object_tab(in_rec_no).upload_type;
--
    -- ⑤物件ステータス妥当性チェック
    -- 更新対象の物件ステータスが「101（未確定）」または「102（確定済）」で、変更区分が「3（除売却）」で連携された場合
    IF ( ((g_vd_object_tab(in_rec_no).xvoh_object_status = cv_ob_status_101)
      OR ( g_vd_object_tab(in_rec_no).xvoh_object_status = cv_ob_status_102 ))
    AND ( g_vd_object_tab(in_rec_no).upload_type = cv_upload_type_3 )
    )
    THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff     -- XXCFF
                                            ,cv_msg_name_00223          -- 除売却処理エラー（自販機物件）
                                           )
                                           || xxccp_common_pkg.get_msg(
                                                cv_msg_kbn_cff          -- XXCFF
                                               ,cv_msg_name_00159       -- 物件エラー対象
                                               ,cv_tkn_name_00159       -- トークン'OBJECT_CODE'
                                               ,g_vd_object_tab(in_rec_no).object_code  -- 物件コード
                                              )
                                            ,1
                                            ,5000);
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
      -- エラーフラグを更新
      gb_err_flag := TRUE;
    END IF;
--
    -- 更新対象の物件ステータスが「106（除売却）」の場合
    IF ( g_vd_object_tab(in_rec_no).xvoh_object_status = cv_ob_status_106 ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff     -- XXCFF
                                            ,cv_msg_name_00224          -- 除売却ステータスエラー（自販機物件）
                                           )
                                           || xxccp_common_pkg.get_msg(
                                                cv_msg_kbn_cff          -- XXCFF
                                               ,cv_msg_name_00159       -- 物件エラー対象
                                               ,cv_tkn_name_00159       -- トークン'OBJECT_CODE'
                                               ,g_vd_object_tab(in_rec_no).object_code  -- 物件コード
                                              )
                                            ,1
                                            ,5000);
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
      -- エラーフラグを更新
      gb_err_flag := TRUE;
    END IF;
--
    -- ⑥FAオープン期間チェック
    -- 移動日がカレンダ期間クローズ日以前の場合
    IF(g_vd_object_tab(in_rec_no).upload_type = cv_upload_type_1) THEN
      IF ( (g_vd_object_tab(in_rec_no).moved_date IS NOT NULL)
        AND ( g_vd_object_tab(in_rec_no).moved_date <= g_cal_per_close_date)
      )
      THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff     -- XXCFF
                                              ,cv_msg_name_00232          -- FAオープン期間外エラー（自販機物件）
                                              ,cv_tkn_name_00232
                                              ,TO_CHAR(g_cal_per_close_date,'YYYY/MM/DD')
                                             )
                                             || xxccp_common_pkg.get_msg(
                                                  cv_msg_kbn_cff          -- XXCFF
                                                 ,cv_msg_name_00159       -- 物件エラー対象
                                                 ,cv_tkn_name_00159       -- トークン'OBJECT_CODE'
                                                 ,g_vd_object_tab(in_rec_no).object_code  -- 物件コード
                                                )
                                              ,1
                                              ,5000);
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
         ,buff   => lv_errmsg
        );
      -- エラーフラグを更新
      gb_err_flag := TRUE;
      END IF;
    END IF;
--
    -- 除・売却日がカレンダ期間クローズ日以前の場合
    IF(g_vd_object_tab(in_rec_no).upload_type = cv_upload_type_3) THEN
      IF ((g_vd_object_tab(in_rec_no).date_retired IS NOT NULL)
        AND (g_vd_object_tab(in_rec_no).date_retired <= g_cal_per_close_date)
      )
      THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff     -- XXCFF
                                              ,cv_msg_name_00232          -- FAオープン期間外エラー（自販機物件）
                                              ,cv_tkn_name_00232
                                              ,TO_CHAR(g_cal_per_close_date,'YYYY/MM/DD')
                                             )
                                             || xxccp_common_pkg.get_msg(
                                                  cv_msg_kbn_cff          -- XXCFF
                                                 ,cv_msg_name_00159       -- 物件エラー対象
                                                 ,cv_tkn_name_00159       -- トークン'OBJECT_CODE'
                                                 ,g_vd_object_tab(in_rec_no).object_code  -- 物件コード
                                                )
                                              ,1
                                              ,5000);
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
         ,buff   => lv_errmsg
        );
      -- エラーフラグを更新
      gb_err_flag := TRUE;
      END IF;
    END IF;
--
    -- ⑦除売却フラグ妥当性チェック
    -- 除売却確定フラグに「Y」、「N」以外の値が入力されている場合
    IF ( g_vd_object_tab(in_rec_no).retired_flag NOT IN (cv_const_y,cv_const_n) ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff     -- XXCFF
                                            ,cv_msg_name_00231          -- 除売却フラグ妥当性エラー（自販機物件）
                                           )
                                           || xxccp_common_pkg.get_msg(
                                                cv_msg_kbn_cff          -- XXCFF
                                               ,cv_msg_name_00159       -- 物件エラー対象
                                               ,cv_tkn_name_00159       -- トークン'OBJECT_CODE'
                                               ,g_vd_object_tab(in_rec_no).object_code  -- 物件コード
                                              )
                                            ,1
                                            ,5000);
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
      -- エラーフラグを更新
      gb_err_flag := TRUE;
    END IF;
--
--#################################  固定例外処理部 START   ####################################
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
--
--#####################################  固定部 END   ##########################################
--
  END data_validation;
--
  /**********************************************************************************
   * Procedure Name   : ins_upd_vd_object
   * Description      : 自販機物件情報更新処理(A-9)
   ***********************************************************************************/
  PROCEDURE ins_upd_vd_object(
    in_rec_no     IN  NUMBER,       --   対象レコード番号
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_upd_vd_object'; -- プログラム名
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
    cv_history_num_1   CONSTANT NUMBER := 1;
--
    -- *** ローカル変数 ***
    lv_warn_msg VARCHAR2(5000);      -- 警告メッセージ出力用変数
    lv_process_type    VARCHAR2(3);  -- 処理区分
    ln_history_num_max NUMBER;       -- 履歴番号（最大値）
--
    lv_nvl_owner_company_type      xxcff_vd_object_info_upload_wk.owner_company_type%TYPE;     -- 本社／工場区分
    lv_nvl_department_code         xxcff_vd_object_info_upload_wk.department_code%TYPE;        -- 管理部門
    lv_nvl_moved_date              xxcff_vd_object_info_upload_wk.moved_date%TYPE;             -- 移動日
    lv_nvl_installation_place      xxcff_vd_object_info_upload_wk.installation_place%TYPE;     -- 設置先
    lv_nvl_installation_address    xxcff_vd_object_info_upload_wk.installation_address%TYPE;   -- 設置場所
    lv_nvl_dclr_place              xxcff_vd_object_info_upload_wk.dclr_place%TYPE;             -- 申告地
    lv_nvl_location                xxcff_vd_object_info_upload_wk.location%TYPE;               -- 事業所
    lv_nvl_manufacturer_name       xxcff_vd_object_info_upload_wk.manufacturer_name%TYPE;      -- メーカー名
    lv_nvl_model                   xxcff_vd_object_info_upload_wk.model%TYPE;                  -- 機種
    lv_nvl_age_type                xxcff_vd_object_info_upload_wk.age_type%TYPE;               -- 年式
    lv_nvl_quantity                xxcff_vd_object_info_upload_wk.quantity%TYPE;               -- 数量
    lv_nvl_date_placed_in_service  xxcff_vd_object_info_upload_wk.date_placed_in_service%TYPE; -- 事業供用日
    lv_nvl_assets_date             xxcff_vd_object_info_upload_wk.assets_date%TYPE;            -- 取得日
    lv_nvl_assets_cost             xxcff_vd_object_info_upload_wk.assets_cost%TYPE;            -- 取得価格
    lv_nvl_date_retired            xxcff_vd_object_info_upload_wk.date_retired%TYPE;           -- 除・売却日
    lv_nvl_proceeds_of_sale        xxcff_vd_object_info_upload_wk.proceeds_of_sale%TYPE;       -- 売却価格
    lv_nvl_cost_of_removal         xxcff_vd_object_info_upload_wk.cost_of_removal%TYPE;        -- 撤去費用
    lv_nvl_retired_flag            xxcff_vd_object_info_upload_wk.retired_flag%TYPE;           -- 撤去費用
--
    -- *** ローカル・カーソル ***
    -- 自販機物件管理
    CURSOR lock_ob_cur
    IS
      SELECT  xvoh.object_header_id
        FROM  xxcff_vd_object_headers  xvoh  --自販機物件管理
       WHERE  xvoh.object_header_id = g_vd_object_tab(in_rec_no).xvoh_object_header_id
      FOR UPDATE NOWAIT
    ;
    -- 自販機物件履歴 
    CURSOR lock_hist_cur
    IS
      SELECT  xvohi.object_header_id
        FROM  xxcff_vd_object_histories  xvohi  --自販機物件履歴
       WHERE  xvohi.object_header_id = g_vd_object_tab(in_rec_no).xvoh_object_header_id
      FOR UPDATE NOWAIT
    ;
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
    -- ローカル変数の初期化
    ln_history_num_max := 0;
--
    BEGIN
      -- 自販機物件管理テーブルロック
      OPEN  lock_ob_cur;
      CLOSE lock_ob_cur;
      EXCEPTION
        WHEN lock_expt THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff         -- XXCFF
                                                      ,cv_msg_name_00007    -- ロックエラー
                                                      ,cv_tkn_name_00007    -- トークン'TABLE_NAME'
                                                      ,cv_tkn_val_50260 )   -- 自販機物件管理
                                                      ,1
                                                      ,5000);
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
    END;
--
    BEGIN
      -- 自販機物件履歴テーブルロック
      OPEN  lock_hist_cur;
      CLOSE lock_hist_cur;
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff     -- XXCFF
                                                    ,cv_msg_name_00007    -- ロックエラー
                                                    ,cv_tkn_name_00007    -- トークン'TABLE_NAME'
                                                    ,cv_tkn_val_50229 )   -- 自販機物件履歴
                                                    ,1
                                                    ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- 自販機物件管理テーブルの更新
    -- 変更区分=「1（移動）」の場合
    IF ( g_vd_object_tab(in_rec_no).upload_type = cv_upload_type_1 ) THEN
      UPDATE xxcff_vd_object_headers  xvoh    -- 自販機物件管理
      SET    xvoh.owner_company_type     = NVL( g_vd_object_tab(in_rec_no).owner_company_type
                                             ,g_vd_object_tab(in_rec_no).xvoh_owner_company_type ),   -- 本社／工場区分
             xvoh.department_code        = NVL( g_vd_object_tab(in_rec_no).department_code
                                             ,g_vd_object_tab(in_rec_no).xvoh_department_code ),      -- 管理部門
             xvoh.moved_date             = NVL( g_vd_object_tab(in_rec_no).moved_date
                                             ,g_vd_object_tab(in_rec_no).xvoh_moved_date ),           -- 移動日
             xvoh.installation_place     = NVL( g_vd_object_tab(in_rec_no).installation_place
                                             ,g_vd_object_tab(in_rec_no).xvoh_installation_place ),   -- 設置先
             xvoh.installation_address   = NVL( g_vd_object_tab(in_rec_no).installation_address
                                             ,g_vd_object_tab(in_rec_no).xvoh_installation_address ), -- 設置場所
             xvoh.dclr_place             = NVL( g_vd_object_tab(in_rec_no).dclr_place
                                             ,g_vd_object_tab(in_rec_no).xvoh_dclr_place ),           -- 申告地
             xvoh.location               = NVL( g_vd_object_tab(in_rec_no).location
                                             ,g_vd_object_tab(in_rec_no).xvoh_location ),             -- 事業所
             xvoh.last_updated_by        = cn_last_updated_by,                              -- 最終更新者
             xvoh.last_update_date       = cd_last_update_date,                             -- 最終更新日
             xvoh.last_update_login      = cn_last_update_login,                            -- 最終更新ログイン
             xvoh.request_id             = cn_request_id,                                   -- 要求ID
             xvoh.program_application_id = cn_program_application_id,                       -- コンカレント･プログラム･アプリケーション
             xvoh.program_id             = cn_program_id,                                   -- コンカレント･プログラムID
             xvoh.program_update_date    = cd_program_update_date                           -- プログラム更新日
      WHERE  xvoh.object_header_id  = g_vd_object_tab(in_rec_no).xvoh_object_header_id   -- 物件ID
      ;
    -- 変更区分=「2（修正）」の場合
    ELSIF ( g_vd_object_tab(in_rec_no).upload_type = cv_upload_type_2 ) THEN
      UPDATE xxcff_vd_object_headers  xvoh    -- 自販機物件管理
      SET    xvoh.manufacturer_name      = NVL( g_vd_object_tab(in_rec_no).manufacturer_name
                                             ,g_vd_object_tab(in_rec_no).xvoh_manufacturer_name ),      -- メーカ名
             xvoh.model                  = NVL( g_vd_object_tab(in_rec_no).model
                                             ,g_vd_object_tab(in_rec_no).xvoh_model ),                  -- 機種
             xvoh.age_type               = NVL( g_vd_object_tab(in_rec_no).age_type
                                             ,g_vd_object_tab(in_rec_no).xvoh_age_type ),               -- 年式
             xvoh.quantity               = NVL( g_vd_object_tab(in_rec_no).quantity
                                             ,g_vd_object_tab(in_rec_no).xvoh_quantity ),               -- 数量
             xvoh.date_placed_in_service = NVL( g_vd_object_tab(in_rec_no).date_placed_in_service
                                             ,g_vd_object_tab(in_rec_no).xvoh_date_placed_in_service ), -- 事業供用日
             xvoh.assets_date            = NVL( g_vd_object_tab(in_rec_no).assets_date
                                             ,g_vd_object_tab(in_rec_no).xvoh_assets_date ),            -- 取得日
             xvoh.assets_cost            = NVL( g_vd_object_tab(in_rec_no).assets_cost
                                             ,g_vd_object_tab(in_rec_no).xvoh_assets_cost ),            -- 取得価格
--             xvoh.month_lease_charge     = NVL( g_vd_object_tab(in_rec_no).month_lease_charge
--                                             ,g_vd_object_tab(in_rec_no).xvoh_month_lease_charge ),     -- 月額リース料
--             xvoh.re_lease_charge        = NVL( g_vd_object_tab(in_rec_no).re_lease_charge
--                                             ,g_vd_object_tab(in_rec_no).xvoh_re_lease_charge ),        -- 再リース料
             xvoh.last_updated_by        = cn_last_updated_by,                              -- 最終更新者
             xvoh.last_update_date       = cd_last_update_date,                             -- 最終更新日
             xvoh.last_update_login      = cn_last_update_login,                            -- 最終更新ログイン
             xvoh.request_id             = cn_request_id,                                   -- 要求ID
             xvoh.program_application_id = cn_program_application_id,                       -- コンカレント･プログラム･アプリケーション
             xvoh.program_id             = cn_program_id,                                   -- コンカレント･プログラムID
             xvoh.program_update_date    = cd_program_update_date                           -- プログラム更新日
      WHERE  xvoh.object_header_id  = g_vd_object_tab(in_rec_no).xvoh_object_header_id   -- 物件ID
      ;
    -- 変更区分=「3（除売却）」かつ更新対象の物件ステータス=「105（除売却未確定）」 の場合
    ELSIF ( (g_vd_object_tab(in_rec_no).upload_type = cv_upload_type_3)
         AND ( g_vd_object_tab(in_rec_no).xvoh_object_status = cv_ob_status_105 ) 
    )
    THEN
      UPDATE xxcff_vd_object_headers  xvoh    -- 自販機物件管理
      SET    xvoh.date_retired           = NVL( g_vd_object_tab(in_rec_no).date_retired
                                             ,g_vd_object_tab(in_rec_no).xvoh_date_retired ),      -- 除・売却日
             xvoh.proceeds_of_sale       = NVL( g_vd_object_tab(in_rec_no).proceeds_of_sale
                                             ,g_vd_object_tab(in_rec_no).xvoh_proceeds_of_sale ),  -- 売却価格
             xvoh.cost_of_removal        = NVL( g_vd_object_tab(in_rec_no).cost_of_removal
                                             ,g_vd_object_tab(in_rec_no).xvoh_cost_of_removal ),   -- 撤去費用
             xvoh.retired_flag           = g_vd_object_tab(in_rec_no).retired_flag,                -- 除・売却確定フラグ
             xvoh.last_updated_by        = cn_last_updated_by,                              -- 最終更新者
             xvoh.last_update_date       = cd_last_update_date,                             -- 最終更新日
             xvoh.last_update_login      = cn_last_update_login,                            -- 最終更新ログイン
             xvoh.request_id             = cn_request_id,                                   -- 要求ID
             xvoh.program_application_id = cn_program_application_id,                       -- コンカレント･プログラム･アプリケーション
             xvoh.program_id             = cn_program_id,                                   -- コンカレント･プログラムID
             xvoh.program_update_date    = cd_program_update_date                           -- プログラム更新日
      WHERE  xvoh.object_header_id  = g_vd_object_tab(in_rec_no).xvoh_object_header_id   -- 物件ID
      ;
    END IF;
--
    -- 自販機物件履歴テーブルの更新
    -- 更新対象の物件ステータスが「未確定」の場合
    IF ( g_vd_object_tab(in_rec_no).xvoh_object_status = cv_ob_status_101 ) THEN
      -- 変更区分=「1（移動）」の場合
      IF ( g_vd_object_tab(in_rec_no).upload_type = cv_upload_type_1 ) THEN
        UPDATE xxcff_vd_object_histories  xvohi    -- 自販機物件履歴
        SET    xvohi.process_date           = g_init_rec.process_date,                                  -- 業務日付
               xvohi.owner_company_type     = NVL( g_vd_object_tab(in_rec_no).owner_company_type
                                               ,g_vd_object_tab(in_rec_no).xvoh_owner_company_type ),   -- 本社／工場区分
               xvohi.department_code        = NVL( g_vd_object_tab(in_rec_no).department_code
                                               ,g_vd_object_tab(in_rec_no).xvoh_department_code ),      -- 管理部門
               xvohi.moved_date             = NVL( g_vd_object_tab(in_rec_no).moved_date
                                               ,g_vd_object_tab(in_rec_no).xvoh_moved_date ),           -- 移動日
               xvohi.installation_place     = NVL( g_vd_object_tab(in_rec_no).installation_place
                                               ,g_vd_object_tab(in_rec_no).xvoh_installation_place ),   -- 設置先
               xvohi.installation_address   = NVL( g_vd_object_tab(in_rec_no).installation_address
                                               ,g_vd_object_tab(in_rec_no).xvoh_installation_address ), -- 設置場所
               xvohi.dclr_place             = NVL( g_vd_object_tab(in_rec_no).dclr_place
                                               ,g_vd_object_tab(in_rec_no).xvoh_dclr_place ),           -- 申告地
               xvohi.location               = NVL( g_vd_object_tab(in_rec_no).location
                                               ,g_vd_object_tab(in_rec_no).xvoh_location ),             -- 事業所
               xvohi.last_updated_by        = cn_last_updated_by,                              -- 最終更新者
               xvohi.last_update_date       = cd_last_update_date,                             -- 最終更新日
               xvohi.last_update_login      = cn_last_update_login,                            -- 最終更新ログイン
               xvohi.request_id             = cn_request_id,                                   -- 要求ID
               xvohi.program_application_id = cn_program_application_id,                       -- コンカレント･プログラム･アプリケーション
               xvohi.program_id             = cn_program_id,                                   -- コンカレント･プログラムID
               xvohi.program_update_date    = cd_program_update_date                           -- プログラム更新日
        WHERE  xvohi.object_header_id  = g_vd_object_tab(in_rec_no).xvoh_object_header_id   -- 物件ID
        AND    xvohi.history_num = cv_history_num_1  -- 履歴番号
        ;
      -- 変更区分=「2（修正）」の場合
      ELSIF ( g_vd_object_tab(in_rec_no).upload_type = cv_upload_type_2 ) THEN
        UPDATE xxcff_vd_object_histories  xvohi    -- 自販機物件履歴
        SET    xvohi.process_date           = g_init_rec.process_date,                                    -- 業務日付
               xvohi.manufacturer_name      = NVL( g_vd_object_tab(in_rec_no).manufacturer_name
                                               ,g_vd_object_tab(in_rec_no).xvoh_manufacturer_name ),      -- メーカ名
               xvohi.model                  = NVL( g_vd_object_tab(in_rec_no).model
                                               ,g_vd_object_tab(in_rec_no).xvoh_model ),                  -- 機種
               xvohi.age_type               = NVL( g_vd_object_tab(in_rec_no).age_type
                                               ,g_vd_object_tab(in_rec_no).xvoh_age_type ),               -- 年式
               xvohi.quantity               = NVL( g_vd_object_tab(in_rec_no).quantity
                                               ,g_vd_object_tab(in_rec_no).xvoh_quantity ),               -- 数量
               xvohi.date_placed_in_service = NVL( g_vd_object_tab(in_rec_no).date_placed_in_service
                                               ,g_vd_object_tab(in_rec_no).xvoh_date_placed_in_service ), -- 事業供用日
               xvohi.assets_date            = NVL( g_vd_object_tab(in_rec_no).assets_date
                                               ,g_vd_object_tab(in_rec_no).xvoh_assets_date ),            -- 取得日
               xvohi.assets_cost            = NVL( g_vd_object_tab(in_rec_no).assets_cost
                                               ,g_vd_object_tab(in_rec_no).xvoh_assets_cost ),            -- 取得価格
--               xvohi.month_lease_charge     = NVL( g_vd_object_tab(in_rec_no).month_lease_charge
--                                               ,g_vd_object_tab(in_rec_no).xvoh_month_lease_charge ),     -- 月額リース料
--               xvohi.re_lease_charge        = NVL( g_vd_object_tab(in_rec_no).re_lease_charge
--                                               ,g_vd_object_tab(in_rec_no).xvoh_re_lease_charge ),        -- 再リース料
               xvohi.last_updated_by        = cn_last_updated_by,                              -- 最終更新者
               xvohi.last_update_date       = cd_last_update_date,                             -- 最終更新日
               xvohi.last_update_login      = cn_last_update_login,                            -- 最終更新ログイン
               xvohi.request_id             = cn_request_id,                                   -- 要求ID
               xvohi.program_application_id = cn_program_application_id,                       -- コンカレント･プログラム･アプリケーション
               xvohi.program_id             = cn_program_id,                                   -- コンカレント･プログラムID
               xvohi.program_update_date    = cd_program_update_date                           -- プログラム更新日
        WHERE  xvohi.object_header_id  = g_vd_object_tab(in_rec_no).xvoh_object_header_id   -- 物件ID
        AND    xvohi.history_num = cv_history_num_1  -- 履歴番号
        ;
      END IF;
    -- 更新対象の物件ステータスが「確定済」または「除売却未確定」の場合
    ELSIF ( (g_vd_object_tab(in_rec_no).xvoh_object_status = cv_ob_status_102)
      OR (g_vd_object_tab(in_rec_no).xvoh_object_status = cv_ob_status_105)
    )
    THEN
      -- 履歴番号（最大値）を取得
      SELECT MAX(xvohi.history_num)
      INTO   ln_history_num_max  -- 履歴番号（最大値）
      FROM   xxcff_vd_object_histories xvohi  -- 自販機物件履歴
      WHERE  xvohi.object_header_id = g_vd_object_tab(in_rec_no).xvoh_object_header_id
      ;
      ln_history_num_max := ln_history_num_max + 1;
      -- 移動の場合
      IF (  g_vd_object_tab(in_rec_no).upload_type = cv_upload_type_1 ) THEN
        -- 処理区分の設定
        lv_process_type := cv_process_type_103;
        -- 登録値の設定
        lv_nvl_owner_company_type     := NVL( g_vd_object_tab(in_rec_no).owner_company_type
                                                 ,g_vd_object_tab(in_rec_no).xvoh_owner_company_type ); -- 本社／工場区分
        lv_nvl_department_code        := NVL( g_vd_object_tab(in_rec_no).department_code
                                                 ,g_vd_object_tab(in_rec_no).xvoh_department_code );    -- 管理部門
        lv_nvl_moved_date             := NVL( g_vd_object_tab(in_rec_no).moved_date
                                                 ,g_vd_object_tab(in_rec_no).xvoh_moved_date );         -- 移動日
        lv_nvl_installation_place     := NVL( g_vd_object_tab(in_rec_no).installation_place
                                             ,g_vd_object_tab(in_rec_no).xvoh_installation_place );     -- 設置先
        lv_nvl_installation_address   := NVL( g_vd_object_tab(in_rec_no).installation_address
                                                 ,g_vd_object_tab(in_rec_no).xvoh_installation_address );   -- 設置場所
        lv_nvl_dclr_place             := NVL( g_vd_object_tab(in_rec_no).dclr_place
                                                 ,g_vd_object_tab(in_rec_no).xvoh_dclr_place );             -- 申告地
        lv_nvl_location               := NVL( g_vd_object_tab(in_rec_no).location
                                                 ,g_vd_object_tab(in_rec_no).xvoh_location );               -- 事業所
        lv_nvl_manufacturer_name      := g_vd_object_tab(in_rec_no).xvoh_manufacturer_name;             -- メーカー名
        lv_nvl_model                  := g_vd_object_tab(in_rec_no).xvoh_model;                         -- 機種
        lv_nvl_age_type               := g_vd_object_tab(in_rec_no).xvoh_age_type;                      -- 年式
        lv_nvl_quantity               := g_vd_object_tab(in_rec_no).xvoh_quantity;                      -- 数量
        lv_nvl_date_placed_in_service := g_vd_object_tab(in_rec_no).xvoh_date_placed_in_service;        -- 事業供用日
        lv_nvl_assets_date            := g_vd_object_tab(in_rec_no).xvoh_assets_date;                   -- 取得日
        lv_nvl_assets_cost            := g_vd_object_tab(in_rec_no).xvoh_assets_cost;                   -- 取得価格
        lv_nvl_date_retired           := g_vd_object_tab(in_rec_no).xvoh_date_retired;                  -- 除・売却日
        lv_nvl_proceeds_of_sale       := g_vd_object_tab(in_rec_no).xvoh_proceeds_of_sale;              -- 売却価格
        lv_nvl_cost_of_removal        := g_vd_object_tab(in_rec_no).xvoh_cost_of_removal;               -- 撤去費用
        lv_nvl_retired_flag           := g_vd_object_tab(in_rec_no).xvoh_retired_flag;             -- 除売却確定フラグ
      -- 修正の場合
      ELSIF (  g_vd_object_tab(in_rec_no).upload_type = cv_upload_type_2 ) THEN
        -- 処理区分の設定
        lv_process_type := cv_process_type_104;
        -- 登録値の設定
        lv_nvl_owner_company_type     := g_vd_object_tab(in_rec_no).xvoh_owner_company_type;     -- 本社／工場区分
        lv_nvl_department_code        := g_vd_object_tab(in_rec_no).xvoh_department_code;        -- 管理部門
        lv_nvl_moved_date             := g_vd_object_tab(in_rec_no).xvoh_moved_date;             -- 移動日
        lv_nvl_installation_place     := g_vd_object_tab(in_rec_no).xvoh_installation_place;     -- 設置先
        lv_nvl_installation_address   := g_vd_object_tab(in_rec_no).xvoh_installation_address;   -- 設置場所
        lv_nvl_dclr_place             := g_vd_object_tab(in_rec_no).xvoh_dclr_place;             -- 申告地
        lv_nvl_location               := g_vd_object_tab(in_rec_no).xvoh_location;               -- 事業所
        lv_nvl_manufacturer_name      := NVL( g_vd_object_tab(in_rec_no).manufacturer_name
                                                 ,g_vd_object_tab(in_rec_no).xvoh_manufacturer_name ); -- メーカー名
        lv_nvl_model                  := NVL( g_vd_object_tab(in_rec_no).model
                                                 ,g_vd_object_tab(in_rec_no).xvoh_model );    -- 機種
        lv_nvl_age_type               := NVL( g_vd_object_tab(in_rec_no).age_type
                                                 ,g_vd_object_tab(in_rec_no).xvoh_age_type ); -- 年式
        lv_nvl_quantity               := NVL( g_vd_object_tab(in_rec_no).quantity
                                                 ,g_vd_object_tab(in_rec_no).xvoh_quantity ); -- 数量
        lv_nvl_date_placed_in_service := NVL( g_vd_object_tab(in_rec_no).date_placed_in_service
                                                 ,g_vd_object_tab(in_rec_no).xvoh_date_placed_in_service ); -- 事業供用日
        lv_nvl_assets_date            := NVL( g_vd_object_tab(in_rec_no).assets_date
                                                 ,g_vd_object_tab(in_rec_no).xvoh_assets_date );  -- 取得日
        lv_nvl_assets_cost            := NVL( g_vd_object_tab(in_rec_no).assets_cost
                                                 ,g_vd_object_tab(in_rec_no).xvoh_assets_cost );  -- 取得価格
        lv_nvl_date_retired           := g_vd_object_tab(in_rec_no).xvoh_date_retired;             -- 除・売却日
        lv_nvl_proceeds_of_sale       := g_vd_object_tab(in_rec_no).xvoh_proceeds_of_sale;         -- 売却価格
        lv_nvl_cost_of_removal        := g_vd_object_tab(in_rec_no).xvoh_cost_of_removal;          -- 撤去費用
        lv_nvl_retired_flag           := g_vd_object_tab(in_rec_no).xvoh_retired_flag;             -- 除売却確定フラグ
      -- 除売却の場合
      ELSE
        -- 処理区分
        lv_process_type := cv_process_type_105;
        -- 登録値の設定
        lv_nvl_owner_company_type     := g_vd_object_tab(in_rec_no).xvoh_owner_company_type;     -- 本社／工場区分
        lv_nvl_department_code        := g_vd_object_tab(in_rec_no).xvoh_department_code;        -- 管理部門
        lv_nvl_moved_date             := g_vd_object_tab(in_rec_no).xvoh_moved_date;             -- 移動日
        lv_nvl_installation_place     := g_vd_object_tab(in_rec_no).xvoh_installation_place;     -- 設置先
        lv_nvl_installation_address   := g_vd_object_tab(in_rec_no).xvoh_installation_address;   -- 設置場所
        lv_nvl_dclr_place             := g_vd_object_tab(in_rec_no).xvoh_dclr_place;             -- 申告地
        lv_nvl_location               := g_vd_object_tab(in_rec_no).xvoh_location;               -- 事業所
        lv_nvl_manufacturer_name      := g_vd_object_tab(in_rec_no).xvoh_manufacturer_name;             -- メーカー名
        lv_nvl_model                  := g_vd_object_tab(in_rec_no).xvoh_model;                         -- 機種
        lv_nvl_age_type               := g_vd_object_tab(in_rec_no).xvoh_age_type;                      -- 年式
        lv_nvl_quantity               := g_vd_object_tab(in_rec_no).xvoh_quantity;                      -- 数量
        lv_nvl_date_placed_in_service := g_vd_object_tab(in_rec_no).xvoh_date_placed_in_service;        -- 事業供用日
        lv_nvl_assets_date            := g_vd_object_tab(in_rec_no).xvoh_assets_date;                   -- 取得日
        lv_nvl_assets_cost            := g_vd_object_tab(in_rec_no).xvoh_assets_cost;                   -- 取得価格
        lv_nvl_date_retired           := NVL( g_vd_object_tab(in_rec_no).date_retired
                                                 ,g_vd_object_tab(in_rec_no).xvoh_date_retired );  -- 除・売却日
        lv_nvl_proceeds_of_sale       := NVL( g_vd_object_tab(in_rec_no).proceeds_of_sale
                                                 ,g_vd_object_tab(in_rec_no).xvoh_proceeds_of_sale ); -- 売却価格
        lv_nvl_cost_of_removal        := NVL( g_vd_object_tab(in_rec_no).cost_of_removal
                                                 ,g_vd_object_tab(in_rec_no).xvoh_cost_of_removal );  -- 撤去費用
        lv_nvl_retired_flag           := NVL( g_vd_object_tab(in_rec_no).retired_flag
                                                 ,g_vd_object_tab(in_rec_no).xvoh_retired_flag );  -- 除売却確定フラグ
      END IF;
--
      -- 自販機物件履歴登録
      INSERT INTO xxcff_vd_object_histories(
             object_header_id        -- 物件ID
           , object_code             -- 物件コード
           , history_num             -- 履歴番号
           , process_type            -- 処理区分
           , process_date            -- 処理日
           , object_status           -- 物件ステータス
           , owner_company_type      -- 本社／工場区分
           , department_code         -- 管理部門
           , machine_type            -- 機器区分
           , manufacturer_name       -- メーカー名
           , model                   -- 機種
           , age_type                -- 年式
           , customer_code           -- 顧客コード
           , quantity                -- 数量
           , date_placed_in_service  -- 事業供用日
           , assets_cost             -- 取得価格
--           , month_lease_charge      -- 月額リース料
--           , re_lease_charge         -- 再リース料
           , assets_date             -- 取得日
           , moved_date              -- 移動日
           , installation_place      -- 設置先
           , installation_address    -- 設置場所
           , dclr_place              -- 申告地
           , location                -- 事業所
           , date_retired            -- 除・売却日
           , proceeds_of_sale        -- 売却価格
           , cost_of_removal         -- 撤去費用
           , retired_flag            -- 除売却確定フラグ
           , ib_if_date              -- 設置ベース情報連携日
           , fa_if_date              -- FA情報連携日
           , fa_if_flag              -- FA連携フラグ
           , created_by              -- 作成者
           , creation_date           -- 作成日
           , last_updated_by         -- 最終更新者
           , last_update_date        -- 最終更新日
           , last_update_login       -- 最終更新ﾛｸﾞｲﾝ
           , request_id              -- 要求ID
           , program_application_id  -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
           , program_id              -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
           , program_update_date     -- ﾌﾟﾛｸﾞﾗﾑ更新日
          )
          VALUES(
             g_vd_object_tab(in_rec_no).xvoh_object_header_id        -- 物件ID
           , g_vd_object_tab(in_rec_no).object_code                  -- 物件コード
           , ln_history_num_max                                      -- 履歴番号
           , lv_process_type                                         -- 処理区分
           , g_init_rec.process_date                                 -- 処理日
           , g_vd_object_tab(in_rec_no).xvoh_object_status           -- 物件ステータス
           , lv_nvl_owner_company_type                               -- 本社／工場区分
           , lv_nvl_department_code                                  -- 管理部門
           , g_vd_object_tab(in_rec_no).xvoh_machine_type            -- 機器区分
           , lv_nvl_manufacturer_name                                -- メーカー名
           , lv_nvl_model                                            -- 機種
           , lv_nvl_age_type                                         -- 年式
           , g_vd_object_tab(in_rec_no).xvoh_customer_code           -- 顧客コード
           , lv_nvl_quantity                                         -- 数量
           , lv_nvl_date_placed_in_service                           -- 事業供用日
           , lv_nvl_assets_cost                                      -- 取得価格
--           , NVL( g_vd_object_tab(in_rec_no).month_lease_charge
--               ,g_vd_object_tab(in_rec_no).xvoh_month_lease_charge ) -- 月額リース料
--           , NVL( g_vd_object_tab(in_rec_no).re_lease_charge
--               ,g_vd_object_tab(in_rec_no).xvoh_re_lease_charge )    -- 再リース料
           , lv_nvl_assets_date                                      -- 取得日
           , lv_nvl_moved_date                                       -- 移動日
           , lv_nvl_installation_place                               -- 設置先
           , lv_nvl_installation_address                             -- 設置場所
           , lv_nvl_dclr_place                                       -- 申告地
           , lv_nvl_location                                         -- 事業所
           , lv_nvl_date_retired                                     -- 除・売却日
           , lv_nvl_proceeds_of_sale                                 -- 売却価格
           , lv_nvl_cost_of_removal                                  -- 撤去費用
           , lv_nvl_retired_flag                                     -- 除売却確定フラグ
           , g_vd_object_tab(in_rec_no).xvoh_ib_if_date              -- 設置ベース情報連携日
           , NULL                                                    -- FA情報連携日
           , cv_const_n                                              -- FA連携フラグ
           , cn_created_by                                           -- 作成者
           , cd_creation_date                                        -- 作成日
           , cn_last_updated_by                                      -- 最終更新者
           , cd_last_update_date                                     -- 最終更新日
           , cn_last_update_login                                    -- 最終更新ﾛｸﾞｲﾝ
           , cn_request_id                                           -- 要求ID
           , cn_program_application_id                               -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
           , cn_program_id                                           -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
           , cd_program_update_date                                  -- ﾌﾟﾛｸﾞﾗﾑ更新日
          )
          ;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_process_expt THEN
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
      IF ( lock_ob_cur%ISOPEN ) THEN
        CLOSE lock_ob_cur;
      END IF;
      IF ( lock_hist_cur%ISOPEN ) THEN
        CLOSE lock_hist_cur;
      END IF;
      ov_errmsg  := SQLERRM;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_upd_vd_object;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    in_file_id      IN   NUMBER,       -- 1.ファイルID
    iv_file_format  IN   VARCHAR2,     -- 2.ファイルフォーマット
    ov_errbuf       OUT  VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT  VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT  VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_error_cnt   NUMBER;
--
    -- ループ時のカウント
    ln_loop_cnt_1  NUMBER;
    ln_loop_cnt_2  NUMBER;
    ln_loop_cnt_3  NUMBER;
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
    gn_target_cnt               := 0;
    gn_normal_cnt               := 0;
    gn_error_cnt                := 0;
    gn_warn_cnt                 := 0;
    gb_err_flag                 := FALSE;
    gv_object_code_pre          := 'DUMMY';
    gv_upload_type_pre          := 'DUMMY'; 
--
    -- ローカル変数の初期化
    ln_loop_cnt_1               := 0;
    ln_loop_cnt_2               := 0;
    ln_loop_cnt_3               := 0;
    ln_error_cnt                := 0;
--

--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
    -- ============================================
    -- A-1．初期処理
    -- ============================================
    init(
       in_file_id        -- 1.ファイルID
      ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-2．妥当性チェック用の値取得
    -- ============================================
    get_for_validation(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-3．ファイルアップロードIFデータ取得
    -- ============================================
    get_upload_data(
       in_file_id        -- 1.ファイルID
      ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    --メインループ①
    <<MAIN_LOOP_1>>
    FOR ln_loop_cnt_1 IN g_file_upload_if_data_tab.FIRST .. g_file_upload_if_data_tab.LAST LOOP
      --１行目の場合カラム行の処理となる為、スキップして２行目の処理に遷移する
      IF ( ln_loop_cnt_1 <> 1 ) THEN
        --メインループ②カウンタのリセット
        ln_loop_cnt_2 := 0;
--
        --メインループ②
        <<MAIN_LOOP_2>>
        FOR ln_loop_cnt_2 IN g_column_desc_tab.FIRST .. g_column_desc_tab.LAST LOOP
          -- ============================================
          -- A-4．デリミタ文字項目分割
          -- ============================================
          divide_item(
             ln_loop_cnt_1     -- ループカウンタ1
            ,ln_loop_cnt_2     -- ループカウンタ2
            ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
            ,lv_retcode        -- リターン・コード             --# 固定 #
            ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
          );
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
          IF ( gb_err_flag ) THEN
            EXIT MAIN_LOOP_2;
          END IF;
--
          -- 項目がNULLでない場合のみ、A-5のチェックを行う
          IF ( g_load_data_tab(ln_loop_cnt_2) IS NOT NULL ) THEN
            -- ============================================
            -- A-5．項目値チェック
            -- ============================================
            check_item_value(
               ln_loop_cnt_2     -- ループカウンタ2
              ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
              ,lv_retcode        -- リターン・コード             --# 固定 #
              ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
            );
            IF ( lv_retcode = cv_status_error ) THEN -- システムエラーの場合
              RAISE global_process_expt;
            END IF;
          END IF;
--
        END LOOP MAIN_LOOP_2;
--
        -- 項目値チェックでエラーが発生した場合、エラー件数をカウントし、A-6の処理をスキップ
        IF ( gb_err_flag ) THEN
          --  対象件数をカウント
          gn_target_cnt := gn_target_cnt + 1;
          --エラー件数をカウント
          ln_error_cnt := ln_error_cnt + 1;
          gn_error_cnt := gn_error_cnt + 1;
          --次処理継続の為、エラーフラグを戻す
          gb_err_flag := FALSE;
        ELSE
          
          -- 変更区分がNULLでないレコードのみ登録する
          IF ( g_load_data_tab(cv_upload_type_col) IS NOT NULL ) THEN
            --  対象件数をカウント
            gn_target_cnt := gn_target_cnt + 1;
--
            -- ============================================
            -- A-6．自販機物件情報アップロードワーク作成
            -- ============================================
              ins_upload_wk(
                 in_file_id        -- 1.ファイルID
                ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
                ,lv_retcode        -- リターン・コード             --# 固定 #
                ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
              );
            IF ( lv_retcode = cv_status_error ) THEN
              --エラー件数をカウント
              ln_error_cnt := ln_error_cnt + 1;
              gn_error_cnt := gn_error_cnt + 1;
              RAISE global_process_expt;
            END IF;
          END IF;
        END IF;
      END IF;
--
    END LOOP MAIN_LOOP_1;
--
    -- 1件でもエラーが存在する場合は処理を終了する
    IF ( ln_error_cnt <> 0 ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-7．自販機物件情報アップロードワーク取得
    -- ============================================
    get_upload_wk(
       in_file_id        -- 1.ファイルID
      ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- A-7で取得件数が1件以上の場合
    IF ( g_vd_object_tab.COUNT <> 0 ) THEN
--
      -- メインループ③
      <<MAIN_LOOP_3>>
      FOR ln_loop_cnt_3 IN g_vd_object_tab.FIRST .. g_vd_object_tab.LAST LOOP
--
        -- エラーフラグの初期化
        gb_err_flag := FALSE;
--
        -- ============================================
        -- A-8．データ妥当性チェック
        -- ============================================
        data_validation(
           ln_loop_cnt_3     -- ループカウンタ3（対象レコード番号）
          ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
          ,lv_retcode        -- リターン・コード             --# 固定 #
          ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
        );
        -- エラーが発生した場合、エラー件数をカウント
        IF ( gb_err_flag ) THEN
          ln_error_cnt := ln_error_cnt + 1;
          gn_error_cnt := gn_error_cnt + 1;
        -- チェックエラーが発生しなかったデータのみ処理を進める
        ELSE
          -- ============================================
          -- A-9．自販機物件情報更新
          -- ============================================
          ins_upd_vd_object(
             ln_loop_cnt_3     -- ループカウンタ3（対象レコード番号）
            ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
            ,lv_retcode        -- リターン・コード             --# 固定 #
            ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
          );
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
--
      END LOOP MAIN_LOOP_3;
--
      -- 1件でもエラーが存在する場合エラー終了
      IF ( ln_error_cnt <> 0 ) THEN
        ov_retcode := cv_status_error;
      END IF;
--
    ELSE
      -- 対象データが存在しない場合は、対象データなしメッセージを表示
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_msg_kbn_cff,   -- アプリケーション短縮名
                     iv_name        => cv_msg_name_00062  -- メッセージコード
                   );
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      ov_retcode := cv_status_warn;
    END IF;
--
--#################################  固定例外処理部 START   ###################################
--
  EXCEPTION
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
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf           OUT   VARCHAR2,        --   エラーメッセージ #固定#
    retcode          OUT   VARCHAR2,        --   エラーコード     #固定#
    in_file_id       IN    NUMBER,          --   1.ファイルID(必須)
    iv_file_format   IN    VARCHAR2         --   2.ファイルフォーマット(必須)
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
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
--
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
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
      ,iv_which   => cv_file_type_out
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
       in_file_id      -- 1.ファイルID
      ,iv_file_format  -- 2.ファイルフォーマット
      ,lv_errbuf       -- エラー・メッセージ           --# 固定 #
      ,lv_retcode      -- リターン・コード             --# 固定 #
      ,lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
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
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    IF (  lv_retcode <> cv_status_normal ) THEN
      -- ①正常以外の場合、ロールバックを発行
      ROLLBACK;
    ELSE
      -- 正常の場合
      -- 自販機物件アップロードワーク削除
      DELETE FROM
        xxcff_vd_object_info_upload_wk  --自販機物件アップロードワーク
      WHERE
        file_id = in_file_id
      ;
      -- 削除まで成功したレコード数を、成功件数に設定
      gn_normal_cnt := SQL%ROWCOUNT;
    END IF;
--
      -- ファイルアップロードI/F削除
      DELETE FROM
        xxccp_mrp_file_ul_interface  --ファイルアップロードI/F
      WHERE
        file_id = in_file_id
      ;
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      COMMIT;
    END IF;
--
    -- 共通のログメッセージの出力
    -- ===============================================
    -- エラー時の出力件数設定
    -- ===============================================
    IF (( lv_retcode <> cv_status_normal ) OR ( gn_error_cnt <> 0 )) THEN
      -- 成功件数にゼロ件をセットする
      gn_normal_cnt := 0;
--
      --強制終了した場合(エラーになった処理がエラーカウントにインクリメントされていない)
      IF ( gn_error_cnt = 0 ) THEN
        IF ( gn_target_cnt = 0 ) THEN  --対象件数が未取得の場合
          NULL;
        ELSE
          gn_error_cnt := 1;
          gn_warn_cnt  := ( gn_target_cnt - gn_error_cnt );
        END IF;
      ELSE
        --スキップ件数をセットする
        gn_warn_cnt   := ( gn_target_cnt - gn_error_cnt );
      END IF;
    END IF;
--
    -- ===============================================================
    -- 共通のログメッセージの出力
    -- ===============================================================
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --共通のメッセージ
                    ,iv_name         => cv_msg_name_90000
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
      ,buff   => gv_out_msg
    );
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --共通のメッセージ
                    ,iv_name         => cv_msg_name_90001
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
      ,buff   => gv_out_msg
    );
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --共通のメッセージ
                    ,iv_name         => cv_msg_name_90002
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
      ,buff   => gv_out_msg
    );
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --共通のメッセージ
                    ,iv_name         => cv_msg_name_90003
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
      ,buff   => gv_out_msg
    );
    --共通のログメッセージの出力終了
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --終了メッセージの設定、出力
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --共通のメッセージ
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG  --ログ(システム管理者用メッセージ)出力
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
      ,buff   => gv_out_msg
    );
--
    --ステータスセット
    retcode := lv_retcode;
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
END XXCFF017A04C;
/