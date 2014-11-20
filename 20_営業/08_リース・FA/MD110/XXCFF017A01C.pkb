CREATE OR REPLACE PACKAGE BODY XXCFF017A01C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFF017A01C(body)
 * Description      : 自販機情報連携
 * MD.050           : MD050_CFF_017_A01_自販機情報連携
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                    初期処理                   (A-1)
 *  select_vd_object_info   自販機物件管理情報抽出処理 (A-2)
 *  validate_record         データ妥当性チェック処理   (A-3)
 *  ins_upd_vd_object       自販機情報登録／更新       (A-4)
 *  ins_vd_obj_hist         自販機物件履歴登録         (A-5)
 *  delete_vd_object_if     自販機物件管理IF削除処理   (A-6)
 *  submain                 メイン処理プロシージャ
 *  main                    コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014-07-17    1.0   SCSK 山下 翔太   新規作成
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
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name         CONSTANT VARCHAR2(100) := 'XXCFF017A01C';  -- パッケージ名
  cv_app_kbn_cff      CONSTANT VARCHAR2(5)   := 'XXCFF';         -- アプリケーション短縮名
--
  -- メッセージ番号
  cv_msg_cff_00062    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00062';  -- 対象データなし
  cv_msg_cff_00092    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00092';  -- 業務処理日付取得エラー
  cv_msg_cff_00093    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00093';  -- キー情報付エラーメッセージ
  cv_msg_cff_00094    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00094';  -- 共通関数エラー
  cv_msg_cff_00095    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00095';  -- 共通関数メッセージ
  cv_msg_cff_00209    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00209';  -- （自販機物件情報）発生日エラーメッセージ
  cv_msg_cff_00210    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00210';  -- （自販機物件情報）物件の無効ステータス連携メッセージ
  cv_msg_cff_00211    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00211';  -- 除・売却日連携エラーメッセージ
  cv_msg_cff_00212    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00212';  -- 除売却ステータスエラーメッセージ
  cv_msg_cff_00213    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00213';  -- シーケンス取得エラーメッセージ
--
  -- トークン
  cv_tkn_cff_00093_01 CONSTANT VARCHAR2(15) := 'ERR_MSG';        -- エラーメッセージ
  cv_tkn_cff_00093_02 CONSTANT VARCHAR2(15) := 'KEY_INFO';       -- キー情報
  cv_tkn_cff_00094    CONSTANT VARCHAR2(15) := 'FUNC_NAME';      -- 共通関数名
  cv_tkn_cff_00095    CONSTANT VARCHAR2(15) := 'ERR_MSG';        -- エラーメッセージ
  cv_tkn_cff_00209    CONSTANT VARCHAR2(15) := 'TRX_DATE';       -- 取込済データの設置ベース情報連携日
  cv_tkn_cff_00213    CONSTANT VARCHAR2(15) := 'SEQUENCE';       -- シーケンス名
--
  -- トークン値
  cv_msg_cff_50137    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50137';  -- 物件コード：
  cv_msg_cff_50141    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50141';  -- 事業所マスタチェック
--
  -- フラグ
  gv_flag_on          CONSTANT VARCHAR2(1)   := 'Y';           -- 「Y」
  gv_flag_off         CONSTANT VARCHAR2(1)   := 'N';           -- 「N」
--
  -- 取込ステータス
  cv_import_status_0  CONSTANT VARCHAR2(1)   := '0';           -- 未取込
  cv_import_status_1  CONSTANT VARCHAR2(1)   := '1';           -- 取込済
  cv_import_status_9  CONSTANT VARCHAR2(1)   := '9';           -- 除売却ステータスエラー
--
  -- 物件ステータス
  cv_obj_status_101   CONSTANT VARCHAR2(3)   := '101';         -- 未確定
  cv_obj_status_102   CONSTANT VARCHAR2(3)   := '102';         -- 確定済
  cv_obj_status_103   CONSTANT VARCHAR2(3)   := '103';         -- 移動
  cv_obj_status_104   CONSTANT VARCHAR2(3)   := '104';         -- 修正
  cv_obj_status_105   CONSTANT VARCHAR2(3)   := '105';         -- 除売却未確定
  cv_obj_status_106   CONSTANT VARCHAR2(3)   := '106';         -- 除売却
--
  -- 書式マスク
  cv_date_format      CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';  -- 日付書式
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 自販機物件管理情報取込対象データレコード型
  TYPE g_vd_object_rtype IS RECORD(
    object_code                 xxcff_vd_object_mng_if.object_code%TYPE,            -- 物件コード
    generation_date             xxcff_vd_object_mng_if.generation_date%TYPE,        -- 発生日
    owner_company_type          xxcff_vd_object_mng_if.owner_company_type%TYPE,     -- 本社/工場区分
    department_code             xxcff_vd_object_mng_if.department_code%TYPE,        -- 管理部門
    machine_type                xxcff_vd_object_mng_if.machine_type%TYPE,           -- 機器区分
    lease_class                 xxcff_vd_object_mng_if.lease_class%TYPE,            -- リース種別
    vendor_code                 xxcff_vd_object_mng_if.vendor_code%TYPE,            -- 仕入先コード
    manufacturer_name           xxcff_vd_object_mng_if.manufacturer_name%TYPE,      -- メーカ名
    model                       xxcff_vd_object_mng_if.model%TYPE,                  -- 機種
    age_type                    xxcff_vd_object_mng_if.age_type%TYPE,               -- 年式
    customer_code               xxcff_vd_object_mng_if.customer_code%TYPE,          -- 顧客コード
    quantity                    xxcff_vd_object_mng_if.quantity%TYPE,               -- 数量
    date_placed_in_service      xxcff_vd_object_mng_if.date_placed_in_service%TYPE, -- 事業供用日
    assets_cost                 xxcff_vd_object_mng_if.assets_cost%TYPE,            -- 取得価格
    moved_date                  xxcff_vd_object_mng_if.moved_date%TYPE,             -- 移動日
    installation_place          xxcff_vd_object_mng_if.installation_place%TYPE,     -- 設置先
    installation_address        xxcff_vd_object_mng_if.installation_address%TYPE,   -- 設置場所
    dclr_place                  xxcff_vd_object_mng_if.dclr_place%TYPE,             -- 申告地
    location                    xxcff_vd_object_mng_if.location%TYPE,               -- 事業所
    date_retired                xxcff_vd_object_mng_if.date_retired%TYPE,           -- 除・売却日
    active_flag                 xxcff_vd_object_mng_if.active_flag%TYPE,            -- 物件有効フラグ
    import_status               xxcff_vd_object_mng_if.import_status%TYPE,          -- 取込ステータス
    xvoh_object_header_id       xxcff_vd_object_headers.object_header_id%TYPE,      -- 物件ID
    xvoh_object_status          xxcff_vd_object_headers.object_status%TYPE,         -- 物件ステータス
    xvoh_owner_company_type     xxcff_vd_object_headers.owner_company_type%TYPE,    -- 本社／工場区分
    xvoh_department_code        xxcff_vd_object_headers.department_code%TYPE,       -- 管理部門
    xvoh_manufacturer_name      xxcff_vd_object_headers.manufacturer_name%TYPE,     -- メーカ名
    xvoh_model                  xxcff_vd_object_headers.model%TYPE,                 -- 機種
    xvoh_age_type               xxcff_vd_object_headers.age_type%TYPE,              -- 年式
    xvoh_customer_code          xxcff_vd_object_headers.customer_code%TYPE,         -- 顧客コード
    xvoh_quantity               xxcff_vd_object_headers.quantity%TYPE,              -- 数量
    xvoh_date_placed_in_service xxcff_vd_object_headers.date_placed_in_service%TYPE,-- 事業供用日
    xvoh_assets_cost            xxcff_vd_object_headers.assets_cost%TYPE,           -- 取得価格
    xvoh_moved_date             xxcff_vd_object_headers.moved_date%TYPE,            -- 移動日
    xvoh_month_lease_charge     xxcff_vd_object_headers.month_lease_charge%TYPE,    -- 月額リース料
    xvoh_re_lease_charge        xxcff_vd_object_headers.re_lease_charge%TYPE,       -- 再リース料
    xvoh_assets_date            xxcff_vd_object_headers.assets_date%TYPE,           -- 取得日
    xvoh_installation_place     xxcff_vd_object_headers.installation_place%TYPE,    -- 設置先
    xvoh_installation_address   xxcff_vd_object_headers.installation_address%TYPE,  -- 設置場所
    xvoh_dclr_place             xxcff_vd_object_headers.dclr_place%TYPE,            -- 申告地
    xvoh_location               xxcff_vd_object_headers.location%TYPE,              -- 事業所
    xvoh_date_retired           xxcff_vd_object_headers.date_retired%TYPE,          -- 除・売却日
    xvoh_proceeds_of_sale       xxcff_vd_object_headers.proceeds_of_sale%TYPE,      -- 売却価格
    xvoh_cost_of_removal        xxcff_vd_object_headers.cost_of_removal%TYPE,       -- 撤去費用
    xvoh_ib_if_date             xxcff_vd_object_headers.ib_if_date%TYPE             -- 設置ベース情報連携日
  );
--
  -- 自販機物件管理情報取込対象データレコード配列
  TYPE g_vd_object_ttype IS TABLE OF g_vd_object_rtype
  INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_process_date  DATE;               -- 業務日付
  g_vd_object_tab  g_vd_object_ttype;  -- 自販機物件管理情報取込対象データ
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理 (A-1)
   ***********************************************************************************/
  PROCEDURE init(
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
    lv_which_out VARCHAR2(10) := 'OUTPUT';
    lv_which_log VARCHAR2(10) := 'LOG';
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
    -- コンカレントパラメータの値を表示するメッセージの出力
    xxcff_common1_pkg.put_log_param(
      iv_which   => lv_which_out,  -- 出力区分
      ov_retcode => lv_retcode,    -- リターンコード
      ov_errbuf  => lv_errbuf,     -- エラーメッセージ
      ov_errmsg  => lv_errmsg      -- ユーザー・エラーメッセージ
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- -- コンカレントパラメータの値を表示するメッセージのログ出力
    xxcff_common1_pkg.put_log_param(
      iv_which   => lv_which_log,  -- 出力区分
      ov_retcode => lv_retcode,    -- リターンコード
      ov_errbuf  => lv_errbuf,     -- エラーメッセージ
      ov_errmsg  => lv_errmsg      -- ユーザー・エラーメッセージ
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ***************************************************
    -- 業務処理日付取得処理
    -- ***************************************************
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    IF (gd_process_date IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                     cv_app_kbn_cff,      -- アプリケーション短縮名
                     cv_msg_cff_00092     -- メッセージ：業務処理日付取得エラー
                     ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : select_vd_object_info
   * Description      : 自販機物件管理情報抽出処理 (A-2)
   ***********************************************************************************/
  PROCEDURE select_vd_object_info(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'select_vd_object_info'; -- プログラム名
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
    -- 自販機物件管理情報取込対象データ取得
    CURSOR get_vd_object_info_cur
    IS
      SELECT xvomi.object_code                object_code,                 -- 物件コード
             xvomi.generation_date            generation_date,             -- 発生日
             xvomi.owner_company_type         owner_company_type,          -- 本社/工場区分
             xvomi.department_code            department_code,             -- 管理部門
             xvomi.machine_type               machine_type,                -- 機器区分
             xvomi.lease_class                lease_class,                 -- リース種別
             xvomi.vendor_code                vendor_code,                 -- 仕入先コード
             xvomi.manufacturer_name          manufacturer_name,           -- メーカ名
             xvomi.model                      model,                       -- 機種
             xvomi.age_type                   age_type,                    -- 年式
             xvomi.customer_code              customer_code,               -- 顧客コード
             xvomi.quantity                   quantity,                    -- 数量
             xvomi.date_placed_in_service     date_placed_in_service,      -- 事業供用日
             xvomi.assets_cost                assets_cost,                 -- 取得価格
             xvomi.moved_date                 moved_date,                  -- 移動日
             xvomi.installation_place         installation_place,          -- 設置先
             xvomi.installation_address       installation_address,        -- 設置場所
             xvomi.dclr_place                 dclr_place,                  -- 申告地
             xvomi.location                   location,                    -- 事業所
             xvomi.date_retired               date_retired,                -- 除・売却日
             xvomi.active_flag                active_flag,                 -- 物件有効フラグ
             xvomi.import_status              import_status,               -- 取込ステータス
             xvoh.object_header_id            xvoh_object_header_id,       -- 物件ID
             xvoh.object_status               xvoh_object_status,          -- 物件ステータス
             xvoh.owner_company_type          xvoh_owner_company_type,     -- 本社／工場区分
             xvoh.department_code             xvoh_department_code,        -- 管理部門
             xvoh.manufacturer_name           xvoh_manufacturer_name,      -- メーカ名
             xvoh.model                       xvoh_model,                  -- 機種
             xvoh.age_type                    xvoh_age_type,               -- 年式
             xvoh.customer_code               xvoh_customer_code,          -- 顧客コード
             xvoh.quantity                    xvoh_quantity,               -- 数量
             xvoh.date_placed_in_service      xvoh_date_placed_in_service, -- 事業供用日
             xvoh.assets_cost                 xvoh_assets_cost,            -- 取得価格
             xvoh.moved_date                  xvoh_moved_date,             -- 移動日
             xvoh.month_lease_charge          xvoh_month_lease_charge,     -- 月額リース料
             xvoh.re_lease_charge             xvoh_re_lease_charge,        -- 再リース料
             xvoh.assets_date                 xvoh_assets_date,            -- 取得日
             xvoh.installation_place          xvoh_installation_place,     -- 設置先
             xvoh.installation_address        xvoh_installation_address,   -- 設置場所
             xvoh.dclr_place                  xvoh_dclr_place,             -- 申告地
             xvoh.location                    xvoh_location,               -- 事業所
             xvoh.date_retired                xvoh_date_retired,           -- 除・売却日
             xvoh.proceeds_of_sale            xvoh_proceeds_of_sale,       -- 売却価格
             xvoh.cost_of_removal             xvoh_cost_of_removal,        -- 撤去費用
             xvoh.ib_if_date                  xvoh_ib_if_date              -- 設置ベース情報連携日
      FROM   xxcff_vd_object_mng_if xvomi,    -- 自販機物件管理IF
             xxcff_vd_object_headers xvoh     -- 自販機物件管理
      WHERE  xvomi.object_code = xvoh.object_code(+)
        AND  xvomi.import_status = cv_import_status_0
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
    -- 取込対象データの抽出
    OPEN  get_vd_object_info_cur;
    FETCH get_vd_object_info_cur BULK COLLECT INTO g_vd_object_tab;
    CLOSE get_vd_object_info_cur;
--
    -- 対象データが0件の場合、メッセージ出力(警告終了)
    IF (g_vd_object_tab.COUNT = 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_app_kbn_cff,   -- アプリケーション短縮名
                     iv_name        => cv_msg_cff_00062  -- メッセージコード
                   );
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      ov_retcode := cv_status_warn;
    END IF;
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
      IF (get_vd_object_info_cur%ISOPEN) THEN
        CLOSE get_vd_object_info_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END select_vd_object_info;
--
  /**********************************************************************************
   * Procedure Name   : validate_record
   * Description      : データ妥当性チェック処理 (A-3)
   ***********************************************************************************/
  PROCEDURE validate_record(
    in_rec_no     IN  NUMBER,       --   チェック対象レコード番号
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'validate_record'; -- プログラム名
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
    ln_lb_chk_err_flg BOOLEAN;        -- 整合性チェックエラーフラグ
    ln_location_id    NUMBER;         -- 事業所ID
    lv_token_value    VARCHAR2(100);  -- メッセージ出力時のトークン整形用
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
    -- フラグの初期化
    ln_lb_chk_err_flg := FALSE;
--
    -- 【マスタチェック】
    -- 共通関数(事業所マスタチェック)の呼び出し
    xxcff_common1_pkg.chk_fa_location(
      iv_segment1    => g_vd_object_tab(in_rec_no).dclr_place,         -- 申告地
      iv_segment2    => g_vd_object_tab(in_rec_no).department_code,    -- 管理部門
      iv_segment3    => g_vd_object_tab(in_rec_no).location,           -- 事業所
      iv_segment5    => g_vd_object_tab(in_rec_no).owner_company_type, -- 本社／工場区分
      on_location_id => ln_location_id,  -- 事業所ID
      ov_retcode     => lv_retcode,      -- リターンコード
      ov_errbuf      => lv_errbuf,       -- エラーメッセージ
      ov_errmsg      => lv_errmsg        -- ユーザー・エラーメッセージ
    );
    IF (lv_retcode = cv_status_error) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,    -- アプリケーション短縮名
                     iv_name         => cv_msg_cff_00094,  -- メッセージコード
                     iv_token_name1  => cv_tkn_cff_00094,  -- トークンコード1
                     iv_token_value1 => cv_msg_cff_50141   -- トークン値1
                   );
      lv_errbuf := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,    -- アプリケーション短縮名
                     iv_name         => cv_msg_cff_00095,  -- メッセージコード
                     iv_token_name1  => cv_tkn_cff_00095,  -- トークンコード1
                     iv_token_value1 => lv_errbuf          -- トークン値1
                   );
      lv_errmsg := lv_errmsg || lv_errbuf;
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT,
        buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG,
        buff   => lv_errmsg
      );
      ln_lb_chk_err_flg := TRUE;
    END IF;
--
    -- 【発生日チェック】
    -- 「取込済データの設置ベース情報連携日」＜「発生日」の関係でない場合、メッセージ出力
    IF (g_vd_object_tab(in_rec_no).xvoh_ib_if_date >= g_vd_object_tab(in_rec_no).generation_date) THEN
      -- 「取込済データの設置ベース情報連携日」を文字列型に変換し、トークン値に設定
      lv_token_value := TO_CHAR(g_vd_object_tab(in_rec_no).xvoh_ib_if_date, cv_date_format);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,       -- アプリケーション短縮名
                     iv_name         => cv_msg_cff_00209,     -- メッセージコード
                     iv_token_name1  => cv_tkn_cff_00209,     -- トークンコード1
                     iv_token_value1 => lv_token_value        -- トークン値1
                   );
      lv_token_value := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,       -- アプリケーション短縮名
                     iv_name         => cv_msg_cff_50137      -- メッセージコード
                   );
      -- 「物件コード」をトークン値に設定
      lv_token_value := lv_token_value || g_vd_object_tab(in_rec_no).object_code;
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,       -- アプリケーション短縮名
                     iv_name         => cv_msg_cff_00093,     -- メッセージコード
                     iv_token_name1  => cv_tkn_cff_00093_01,  -- トークンコード1
                     iv_token_value1 => lv_errmsg,            -- トークン値1
                     iv_token_name2  => cv_tkn_cff_00093_02,  -- トークンコード2
                     iv_token_value2 => lv_token_value        -- トークン値2
                   );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT,
        buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG,
        buff   => lv_errmsg
      );
      ln_lb_chk_err_flg := TRUE;
    END IF;
--
    -- 【除売却ステータスエラーチェック】
    -- 取込済データの「物件ステータス」が '106'（除売却）の場合
    IF ( g_vd_object_tab(in_rec_no).xvoh_object_status = cv_obj_status_106) THEN
      -- 自販機物件管理IFの取込ステータスを'9'（除売却ステータスエラー）に更新
      UPDATE xxcff_vd_object_mng_if  xvomi    -- 自販機物件管理IF
      SET    xvomi.import_status           =  cv_import_status_9,         -- 取込ステータス
             xvomi.last_updated_by         =  cn_last_updated_by,         -- 最終更新者
             xvomi.last_update_date        =  cd_last_update_date,        -- 最終更新日
             xvomi.last_update_login       =  cn_last_update_login,       -- 最終更新ログイン
             xvomi.request_id              =  cn_request_id,              -- 要求ID
             xvomi.program_application_id  =  cn_program_application_id,  -- コンカレント･プログラム･アプリケーション
             xvomi.program_id              =  cn_program_id,              -- コンカレント･プログラムID
             xvomi.program_update_date     =  cd_program_update_date      -- プログラム更新日
      WHERE  g_vd_object_tab(in_rec_no).object_code = xvomi.object_code   -- 物件コード
      ;
--
      -- 「除売却ステータスエラーメッセージ」を表示
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,       -- アプリケーション短縮名
                     iv_name         => cv_msg_cff_00212      -- メッセージコード
                   );
      lv_token_value := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,       -- アプリケーション短縮名
                     iv_name         => cv_msg_cff_50137      -- メッセージコード
                   );
      -- 「物件コード」をトークン値に設定
      lv_token_value := lv_token_value || g_vd_object_tab(in_rec_no).object_code;
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,       -- アプリケーション短縮名
                     iv_name         => cv_msg_cff_00093,     -- メッセージコード
                     iv_token_name1  => cv_tkn_cff_00093_01,  -- トークンコード1
                     iv_token_value1 => lv_errmsg,            -- トークン値1
                     iv_token_name2  => cv_tkn_cff_00093_02,  -- トークンコード2
                     iv_token_value2 => lv_token_value        -- トークン値2
                   );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT,
        buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG,
        buff   => lv_errmsg
      );
      ln_lb_chk_err_flg := TRUE;
    END IF;
--
    -- 【除・売却日連携エラーチェック】
    -- 「物件ステータス」が自販機物件管理アドオンに存在しない、または'101'（未確定）と等しい場合
    --  かつ、自販機物件管理IFから「除・売却日」が連携された場合
    IF ( (g_vd_object_tab(in_rec_no).xvoh_object_status IS NULL
        OR g_vd_object_tab(in_rec_no).xvoh_object_status = cv_obj_status_101)
      AND g_vd_object_tab(in_rec_no).date_retired IS NOT NULL )
    THEN
      -- 「除・売却日連携エラーメッセージ」を表示
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,       -- アプリケーション短縮名
                     iv_name         => cv_msg_cff_00211      -- メッセージコード
                   );
      lv_token_value := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,       -- アプリケーション短縮名
                     iv_name         => cv_msg_cff_50137      -- メッセージコード
                   );
      -- 「物件コード」をトークン値に設定
      lv_token_value := lv_token_value || g_vd_object_tab(in_rec_no).object_code;
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,       -- アプリケーション短縮名
                     iv_name         => cv_msg_cff_00093,     -- メッセージコード
                     iv_token_name1  => cv_tkn_cff_00093_01,  -- トークンコード1
                     iv_token_value1 => lv_errmsg,            -- トークン値1
                     iv_token_name2  => cv_tkn_cff_00093_02,  -- トークンコード2
                     iv_token_value2 => lv_token_value        -- トークン値2
                   );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT,
        buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG,
        buff   => lv_errmsg
      );
      ln_lb_chk_err_flg := TRUE;
    END IF;
--
    -- 整合性チェックでエラーの場合、ステータスに'1'(警告)を設定
    IF (ln_lb_chk_err_flg) THEN
      ov_retcode := cv_status_warn;
    END IF;
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
  END validate_record;
--
  /**********************************************************************************
   * Procedure Name   : ins_vd_obj_hist
   * Description      : 自販機物件履歴登録 (A-5)
   ***********************************************************************************/
  PROCEDURE ins_vd_obj_hist(
    in_rec_no           IN NUMBER,     -- チェック対象レコード番号
    in_object_header_id IN NUMBER,     -- 物件ID
    iv_process_type     IN VARCHAR2,   -- 処理区分
    iv_object_status    IN VARCHAR2,   -- 物件ステータス
    ov_errbuf           OUT VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_vd_obj_hist'; -- プログラム名
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
    ln_history_num_max NUMBER; -- 履歴番号（最大値）
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
    -- 履歴番号（最大値）を設定
    -- 「未確定」の場合、履歴番号は'1'固定
    IF ( iv_object_status = cv_obj_status_101 ) THEN
      ln_history_num_max := 1;
    ELSE
      SELECT MAX(xvohi.history_num)
      INTO   ln_history_num_max
      FROM   xxcff_vd_object_histories xvohi  -- 自販機物件履歴
      WHERE  xvohi.object_header_id = in_object_header_id
      ;
      ln_history_num_max := ln_history_num_max + 1;
    END IF;
--
    -- ***************************************************
    -- 自販機物件履歴登録
    -- ***************************************************
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
         , month_lease_charge      -- 月額リース料
         , re_lease_charge         -- 再リース料
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
           in_object_header_id                                -- 物件ID
         , g_vd_object_tab(in_rec_no).object_code             -- 物件コード
         , ln_history_num_max                                 -- 履歴番号
         , iv_process_type                                    -- 処理区分
         , gd_process_date                                    -- 処理日
         , iv_object_status                                   -- 物件ステータス
         , g_vd_object_tab(in_rec_no).owner_company_type      -- 本社／工場区分
         , g_vd_object_tab(in_rec_no).department_code         -- 管理部門
         , g_vd_object_tab(in_rec_no).machine_type            -- 機器区分
         , g_vd_object_tab(in_rec_no).manufacturer_name       -- メーカー名
         , g_vd_object_tab(in_rec_no).model                   -- 機種
         , g_vd_object_tab(in_rec_no).age_type                -- 年式
         , g_vd_object_tab(in_rec_no).customer_code           -- 顧客コード
         , g_vd_object_tab(in_rec_no).quantity                -- 数量
         , g_vd_object_tab(in_rec_no).date_placed_in_service  -- 事業供用日
         , g_vd_object_tab(in_rec_no).assets_cost             -- 取得価格
         , g_vd_object_tab(in_rec_no).xvoh_month_lease_charge -- 月額リース料
         , g_vd_object_tab(in_rec_no).xvoh_re_lease_charge    -- 再リース料
         , g_vd_object_tab(in_rec_no).xvoh_assets_date        -- 取得日
         , g_vd_object_tab(in_rec_no).moved_date              -- 移動日
         , g_vd_object_tab(in_rec_no).installation_place      -- 設置先
         , g_vd_object_tab(in_rec_no).installation_address    -- 設置場所
         , g_vd_object_tab(in_rec_no).dclr_place              -- 申告地
         , g_vd_object_tab(in_rec_no).location                -- 事業所
         , g_vd_object_tab(in_rec_no).date_retired            -- 除・売却日
         , g_vd_object_tab(in_rec_no).xvoh_proceeds_of_sale   -- 売却価格
         , g_vd_object_tab(in_rec_no).xvoh_cost_of_removal    -- 撤去費用
         , gv_flag_off                                        -- 除売却確定フラグ
         , g_vd_object_tab(in_rec_no).generation_date         -- 設置ベース情報連携日
         , NULL                                               -- FA情報連携日
         , gv_flag_off                                        -- FA連携フラグ
         , cn_created_by                                      -- 作成者
         , cd_creation_date                                   -- 作成日
         , cn_last_updated_by                                 -- 最終更新者
         , cd_last_update_date                                -- 最終更新日
         , cn_last_update_login                               -- 最終更新ﾛｸﾞｲﾝ
         , cn_request_id                                      -- 要求ID
         , cn_program_application_id                          -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
         , cn_program_id                                      -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
         , cd_program_update_date                             -- ﾌﾟﾛｸﾞﾗﾑ更新日
        )
        ;
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
      ov_errmsg  := SQLERRM;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_vd_obj_hist;
--
  /**********************************************************************************
   * Procedure Name   : ins_upd_vd_object
   * Description      : 自販機情報登録／更新 (A-4)
   ***********************************************************************************/
  PROCEDURE ins_upd_vd_object(
    in_rec_no     IN  NUMBER,       --   チェック対象レコード番号
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
    cv_dummy             CONSTANT VARCHAR2(5)  := 'XXXXX';    -- NVL用ダミー値
    cv_tkn_val_00213     CONSTANT VARCHAR2(16) := '物件ID';   -- シーケンス取得エラートークン値
--
    -- *** ローカル変数 ***
    lv_token_value      VARCHAR2(100);         -- メッセージ出力時のトークン整形用
    lv_object_header_id NUMBER;                -- 物件ID
    lv_process_type     NUMBER;                -- 処理区分
    lv_object_status    NUMBER;                -- 物件ステータス
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
    -- １．A-2で取得した物件ステータスが自販機物件管理アドオンに存在しない場合
    IF ( g_vd_object_tab(in_rec_no).xvoh_object_status IS NULL ) THEN
--
      -- ***************************************************
      -- シーケンスの取得
      -- ***************************************************
      SELECT xxcff_vd_object_headers_s1.NEXTVAL
      INTO   lv_object_header_id
      FROM   dual
      ;
--
      IF ( lv_object_header_id IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,    -- アプリケーション短縮名
                     iv_name         => cv_msg_cff_00213,  -- メッセージコード
                     iv_token_name1  => cv_tkn_cff_00213,  -- トークンコード1
                     iv_token_value1 => cv_tkn_val_00213   -- トークン値1
                   );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      -- ***************************************************
      -- 自販機物件管理登録
      -- ***************************************************
      INSERT INTO xxcff_vd_object_headers(
         object_header_id        -- 物件ID
       , object_code             -- 物件コード
       , object_status           -- 物件ステータス
       , owner_company_type      -- 本社／工場区分
       , department_code         -- 管理部門
       , machine_type            -- 機器区分
       , lease_class             -- リース種別
       , vendor_code             -- 仕入先コード
       , manufacturer_name       -- メーカー名
       , model                   -- 機種
       , age_type                -- 年式
       , customer_code           -- 顧客コード
       , quantity                -- 数量
       , date_placed_in_service  -- 事業供用日
       , assets_cost             -- 取得価格
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
         lv_object_header_id                                -- 物件ID
       , g_vd_object_tab(in_rec_no).object_code             -- 物件コード
       , cv_obj_status_101                                  -- 物件ステータス
       , g_vd_object_tab(in_rec_no).owner_company_type      -- 本社／工場区分
       , g_vd_object_tab(in_rec_no).department_code         -- 管理部門
       , g_vd_object_tab(in_rec_no).machine_type            -- 機器区分
       , g_vd_object_tab(in_rec_no).lease_class             -- リース種別
       , g_vd_object_tab(in_rec_no).vendor_code             -- 仕入先コード
       , g_vd_object_tab(in_rec_no).manufacturer_name       -- メーカー名
       , g_vd_object_tab(in_rec_no).model                   -- 機種
       , g_vd_object_tab(in_rec_no).age_type                -- 年式
       , g_vd_object_tab(in_rec_no).customer_code           -- 顧客コード
       , g_vd_object_tab(in_rec_no).quantity                -- 数量
       , g_vd_object_tab(in_rec_no).date_placed_in_service  -- 事業供用日
       , g_vd_object_tab(in_rec_no).assets_cost             -- 取得価格
       , g_vd_object_tab(in_rec_no).xvoh_assets_date        -- 取得日
       , g_vd_object_tab(in_rec_no).moved_date              -- 移動日
       , g_vd_object_tab(in_rec_no).installation_place      -- 設置先
       , g_vd_object_tab(in_rec_no).installation_address    -- 設置場所
       , g_vd_object_tab(in_rec_no).dclr_place              -- 申告地
       , g_vd_object_tab(in_rec_no).location                -- 事業所
       , g_vd_object_tab(in_rec_no).date_retired            -- 除・売却日
       , g_vd_object_tab(in_rec_no).xvoh_proceeds_of_sale   -- 売却価格
       , g_vd_object_tab(in_rec_no).xvoh_cost_of_removal    -- 撤去費用
       , gv_flag_off                                        -- 除売却確定フラグ
       , g_vd_object_tab(in_rec_no).generation_date         -- 設置ベース情報連携日
       , cn_created_by                                      -- 作成者
       , cd_creation_date                                   -- 作成日
       , cn_last_updated_by                                 -- 最終更新者
       , cd_last_update_date                                -- 最終更新日
       , cn_last_update_login                               -- 最終更新ﾛｸﾞｲﾝ
       , cn_request_id                                      -- 要求ID
       , cn_program_application_id                          -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
       , cn_program_id                                      -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
       , cd_program_update_date                             -- ﾌﾟﾛｸﾞﾗﾑ更新日
      )
      ;
--
      -- =====================================================
      --  自販機物件履歴登録 (A-5)
      -- =====================================================
      ins_vd_obj_hist(
        in_rec_no,            -- チェック対象レコード番号
        lv_object_header_id,  -- 物件ID
        cv_obj_status_101,    -- 処理区分（'101' 未確定）
        cv_obj_status_101,    -- 物件ステータス（'101' 未確定） 
        lv_errbuf,            -- エラー・メッセージ           --# 固定 #
        lv_retcode,           -- リターン・コード             --# 固定 #
        lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- ２．自販機物件管理アドオンの物件ステータスが「未確定」の場合
    IF ( g_vd_object_tab(in_rec_no).xvoh_object_status = cv_obj_status_101 ) THEN
--
      -- ***************************************************
      -- 自販機物件管理更新
      -- ***************************************************
      UPDATE xxcff_vd_object_headers  xvoh    -- 自販機物件管理
      SET    xvoh.owner_company_type     = g_vd_object_tab(in_rec_no).owner_company_type,    -- 本社／工場区分
             xvoh.department_code        = g_vd_object_tab(in_rec_no).department_code,       -- 管理部門
             xvoh.machine_type           = g_vd_object_tab(in_rec_no).machine_type,          -- 機器区分
             xvoh.lease_class            = g_vd_object_tab(in_rec_no).lease_class,           -- リース種別
             xvoh.manufacturer_name      = g_vd_object_tab(in_rec_no).manufacturer_name,     -- メーカー名
             xvoh.model                  = g_vd_object_tab(in_rec_no).model,                 -- 機種
             xvoh.age_type               = g_vd_object_tab(in_rec_no).age_type,              -- 年式
             xvoh.customer_code          = g_vd_object_tab(in_rec_no).customer_code,         -- 顧客コード
             xvoh.quantity               = g_vd_object_tab(in_rec_no).quantity,              -- 数量
             xvoh.date_placed_in_service = g_vd_object_tab(in_rec_no).date_placed_in_service,-- 事業供用日
             xvoh.assets_cost            = g_vd_object_tab(in_rec_no).assets_cost,           -- 取得価格
             xvoh.assets_date            = g_vd_object_tab(in_rec_no).xvoh_assets_date,      -- 取得日
             xvoh.moved_date             = g_vd_object_tab(in_rec_no).moved_date,            -- 移動日
             xvoh.installation_place     = g_vd_object_tab(in_rec_no).installation_place,    -- 設置先
             xvoh.installation_address   = g_vd_object_tab(in_rec_no).installation_address,  -- 設置場所
             xvoh.dclr_place             = g_vd_object_tab(in_rec_no).dclr_place,            -- 申告地
             xvoh.location               = g_vd_object_tab(in_rec_no).location,              -- 事業所
             xvoh.date_retired           = g_vd_object_tab(in_rec_no).date_retired,          -- 除・売却日
             xvoh.proceeds_of_sale       = g_vd_object_tab(in_rec_no).xvoh_proceeds_of_sale, -- 売却価格
             xvoh.cost_of_removal        = g_vd_object_tab(in_rec_no).xvoh_cost_of_removal,  -- 撤去費用
             xvoh.ib_if_date             = g_vd_object_tab(in_rec_no).generation_date,       -- 設置ベース情報連携日
             xvoh.last_updated_by        = cn_last_updated_by,                               -- 最終更新者
             xvoh.last_update_date       = cd_last_update_date,                              -- 最終更新日
             xvoh.last_update_login      = cn_last_update_login,                             -- 最終更新ログイン
             xvoh.request_id             = cn_request_id,                                    -- 要求ID
             xvoh.program_application_id = cn_program_application_id,                        -- コンカレント･プログラム･アプリケーション
             xvoh.program_id             = cn_program_id,                                    -- コンカレント･プログラムID
             xvoh.program_update_date    = cd_program_update_date                            -- プログラム更新日
      WHERE  xvoh.object_header_id  = g_vd_object_tab(in_rec_no).xvoh_object_header_id   -- 物件ID
      ;
--
      -- ***************************************************
      -- 自販機物件履歴更新
      -- ***************************************************
      UPDATE xxcff_vd_object_histories  xvohi  -- 自販機物件管理
      SET    xvohi.process_date           = gd_process_date,                                  -- 処理日
             xvohi.owner_company_type     = g_vd_object_tab(in_rec_no).owner_company_type,    -- 本社／工場区分
             xvohi.department_code        = g_vd_object_tab(in_rec_no).department_code,       -- 管理部門
             xvohi.machine_type           = g_vd_object_tab(in_rec_no).machine_type,          -- 機器区分
             xvohi.manufacturer_name      = g_vd_object_tab(in_rec_no).manufacturer_name,     -- メーカー名
             xvohi.model                  = g_vd_object_tab(in_rec_no).model,                 -- 機種
             xvohi.age_type               = g_vd_object_tab(in_rec_no).age_type,              -- 年式
             xvohi.customer_code          = g_vd_object_tab(in_rec_no).customer_code,         -- 顧客コード
             xvohi.quantity               = g_vd_object_tab(in_rec_no).quantity,              -- 数量
             xvohi.date_placed_in_service = g_vd_object_tab(in_rec_no).date_placed_in_service,-- 事業供用日
             xvohi.assets_cost            = g_vd_object_tab(in_rec_no).assets_cost,           -- 取得価格
             xvohi.assets_date            = g_vd_object_tab(in_rec_no).xvoh_assets_date,      -- 取得日
             xvohi.moved_date             = g_vd_object_tab(in_rec_no).moved_date,            -- 移動日
             xvohi.installation_place     = g_vd_object_tab(in_rec_no).installation_place,    -- 設置先
             xvohi.installation_address   = g_vd_object_tab(in_rec_no).installation_address,  -- 設置場所
             xvohi.dclr_place             = g_vd_object_tab(in_rec_no).dclr_place,            -- 申告地
             xvohi.location               = g_vd_object_tab(in_rec_no).location,              -- 事業所
             xvohi.date_retired           = g_vd_object_tab(in_rec_no).date_retired,          -- 除・売却日
             xvohi.proceeds_of_sale       = g_vd_object_tab(in_rec_no).xvoh_proceeds_of_sale, -- 売却価格
             xvohi.cost_of_removal        = g_vd_object_tab(in_rec_no).xvoh_cost_of_removal,  -- 撤去費用
             xvohi.ib_if_date             = g_vd_object_tab(in_rec_no).generation_date,       -- 設置ベース情報連携日
             xvohi.last_updated_by        = cn_last_updated_by,                               -- 最終更新者
             xvohi.last_update_date       = cd_last_update_date,                              -- 最終更新日
             xvohi.last_update_login      = cn_last_update_login,                             -- 最終更新ログイン
             xvohi.request_id             = cn_request_id,                                    -- 要求ID
             xvohi.program_application_id = cn_program_application_id,                        -- コンカレント･プログラム･アプリケーション
             xvohi.program_id             = cn_program_id,                                    -- コンカレント･プログラムID
             xvohi.program_update_date    = cd_program_update_date                            -- プログラム更新日
      WHERE  xvohi.object_header_id  = g_vd_object_tab(in_rec_no).xvoh_object_header_id   -- 物件ID
        AND  xvohi.history_num = 1   -- 履歴番号
      ;
    END IF;
--
    -- ３．自販機物件管理アドオンの物件ステータスが「確定済」、または「除売却未確定」の場合
    IF ( g_vd_object_tab(in_rec_no).xvoh_object_status = cv_obj_status_102
      OR g_vd_object_tab(in_rec_no).xvoh_object_status = cv_obj_status_105)
    THEN
      -- 移動の場合
      IF ( g_vd_object_tab(in_rec_no).owner_company_type
             <> NVL(g_vd_object_tab(in_rec_no).xvoh_owner_company_type,cv_dummy)   -- 本社/工場区分
        OR g_vd_object_tab(in_rec_no).department_code
             <> NVL(g_vd_object_tab(in_rec_no).xvoh_department_code,cv_dummy)      -- 管理部門
        OR g_vd_object_tab(in_rec_no).installation_address
             <> NVL(g_vd_object_tab(in_rec_no).xvoh_installation_address,cv_dummy) -- 設置場所
        OR g_vd_object_tab(in_rec_no).dclr_place
             <> NVL(g_vd_object_tab(in_rec_no).xvoh_dclr_place,cv_dummy)           -- 申告地
        OR g_vd_object_tab(in_rec_no).location
             <> NVL(g_vd_object_tab(in_rec_no).xvoh_location,cv_dummy)             -- 事業所
        OR g_vd_object_tab(in_rec_no).customer_code
             <> NVL(g_vd_object_tab(in_rec_no).xvoh_customer_code,cv_dummy)        -- 顧客コード
        OR g_vd_object_tab(in_rec_no).installation_place
             <> NVL(g_vd_object_tab(in_rec_no).xvoh_installation_place,cv_dummy)   -- 設置先
      )
      THEN
        -- 移動日がNULLの場合は業務日付をセット
        IF ( g_vd_object_tab(in_rec_no).moved_date IS NULL) THEN
          g_vd_object_tab(in_rec_no).moved_date := gd_process_date;
        END IF;
--        
        -- ***************************************************
        -- 自販機物件管理更新
        -- ***************************************************
        UPDATE xxcff_vd_object_headers  xvoh    -- 自販機物件管理
        SET    xvoh.owner_company_type     = g_vd_object_tab(in_rec_no).owner_company_type,   -- 本社／工場区分
               xvoh.department_code        = g_vd_object_tab(in_rec_no).department_code,      -- 管理部門
               xvoh.customer_code          = g_vd_object_tab(in_rec_no).customer_code,        -- 顧客コード
               xvoh.installation_place     = g_vd_object_tab(in_rec_no).installation_place,   -- 設置先
               xvoh.installation_address   = g_vd_object_tab(in_rec_no).installation_address, -- 設置場所
               xvoh.dclr_place             = g_vd_object_tab(in_rec_no).dclr_place,           -- 申告地
               xvoh.location               = g_vd_object_tab(in_rec_no).location,             -- 事業所
               xvoh.moved_date             = g_vd_object_tab(in_rec_no).moved_date,           -- 移動日
               xvoh.ib_if_date             = g_vd_object_tab(in_rec_no).generation_date,      -- 設置ベース情報連携日
               xvoh.last_updated_by        = cn_last_updated_by,                              -- 最終更新者
               xvoh.last_update_date       = cd_last_update_date,                             -- 最終更新日
               xvoh.last_update_login      = cn_last_update_login,                            -- 最終更新ログイン
               xvoh.request_id             = cn_request_id,                                   -- 要求ID
               xvoh.program_application_id = cn_program_application_id,                       -- コンカレント･プログラム･アプリケーション
               xvoh.program_id             = cn_program_id,                                   -- コンカレント･プログラムID
               xvoh.program_update_date    = cd_program_update_date                           -- プログラム更新日
        WHERE  xvoh.object_header_id  = g_vd_object_tab(in_rec_no).xvoh_object_header_id   -- 物件ID
        ;
--
        -- =====================================================
        --  自販機物件履歴登録 (A-5)
        -- =====================================================
        ins_vd_obj_hist(
          in_rec_no,                                         -- チェック対象レコード番号
          g_vd_object_tab(in_rec_no).xvoh_object_header_id,  -- 物件ID
          cv_obj_status_103,                                 -- 処理区分（'103' 移動）
          g_vd_object_tab(in_rec_no).xvoh_object_status,     -- 物件ステータス（'102' 確定済 or '105' 除売却未確定） 
          lv_errbuf,            -- エラー・メッセージ           --# 固定 #
          lv_retcode,           -- リターン・コード             --# 固定 #
          lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        END IF;
      END IF;
--
      -- 修正の場合
      IF ( g_vd_object_tab(in_rec_no).manufacturer_name
             <> NVL(g_vd_object_tab(in_rec_no).xvoh_manufacturer_name,cv_dummy)     -- メーカ名
        OR g_vd_object_tab(in_rec_no).model
             <> NVL(g_vd_object_tab(in_rec_no).xvoh_model,cv_dummy)                 -- 機種
        OR g_vd_object_tab(in_rec_no).age_type
             <> NVL(g_vd_object_tab(in_rec_no).xvoh_age_type,cv_dummy)              -- 年式
        OR TO_CHAR( g_vd_object_tab(in_rec_no).quantity )
             <> NVL(TO_CHAR(g_vd_object_tab(in_rec_no).xvoh_quantity),cv_dummy)     -- 数量
        OR TO_CHAR( g_vd_object_tab(in_rec_no).date_placed_in_service, cv_date_format)
             <> NVL(TO_CHAR(g_vd_object_tab(in_rec_no).xvoh_date_placed_in_service, cv_date_format),cv_dummy) -- 事業供用日
        OR TO_CHAR( g_vd_object_tab(in_rec_no).assets_cost )
             <> NVL(TO_CHAR( g_vd_object_tab(in_rec_no).xvoh_assets_cost),cv_dummy) -- 取得価格
      )
      THEN
        -- 移動日は更新しない
        g_vd_object_tab(in_rec_no).moved_date := g_vd_object_tab(in_rec_no).xvoh_moved_date;
        -- ***************************************************
        -- 自販機物件管理更新
        -- ***************************************************
        UPDATE xxcff_vd_object_headers  xvoh    -- 自販機物件管理
        SET    xvoh.manufacturer_name      = g_vd_object_tab(in_rec_no).manufacturer_name,     -- メーカー名
               xvoh.model                  = g_vd_object_tab(in_rec_no).model,                 -- 機種
               xvoh.age_type               = g_vd_object_tab(in_rec_no).age_type,              -- 年式
               xvoh.quantity               = g_vd_object_tab(in_rec_no).quantity,              -- 数量
               xvoh.date_placed_in_service = g_vd_object_tab(in_rec_no).date_placed_in_service,-- 事業供用日
               xvoh.assets_cost            = g_vd_object_tab(in_rec_no).assets_cost,           -- 取得価格
               xvoh.ib_if_date             = g_vd_object_tab(in_rec_no).generation_date,       -- 設置ベース情報連携日
               xvoh.last_updated_by        = cn_last_updated_by,                               -- 最終更新者
               xvoh.last_update_date       = cd_last_update_date,                              -- 最終更新日
               xvoh.last_update_login      = cn_last_update_login,                             -- 最終更新ログイン
               xvoh.request_id             = cn_request_id,                                    -- 要求ID
               xvoh.program_application_id = cn_program_application_id,                        -- コンカレント･プログラム･アプリケーション
               xvoh.program_id             = cn_program_id,                                    -- コンカレント･プログラムID
               xvoh.program_update_date    = cd_program_update_date                            -- プログラム更新日
        WHERE  xvoh.object_header_id  = g_vd_object_tab(in_rec_no).xvoh_object_header_id   -- 物件ID
        ;
--
        -- =====================================================
        --  自販機物件履歴登録 (A-5)
        -- =====================================================
        ins_vd_obj_hist(
          in_rec_no,                                         -- チェック対象レコード番号
          g_vd_object_tab(in_rec_no).xvoh_object_header_id,  -- 物件ID
          cv_obj_status_104,                                 -- 処理区分（'104' 修正）
          g_vd_object_tab(in_rec_no).xvoh_object_status,     -- 物件ステータス（'102' 確定済 or '105' 除売却未確定） 
          lv_errbuf,            -- エラー・メッセージ           --# 固定 #
          lv_retcode,           -- リターン・コード             --# 固定 #
          lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        END IF;
      END IF;
--
      -- 除売却未確定の場合(「確定済」で除・売却日が連携 or 「除売却未確定」で除・売却日が変更）
      IF ( (g_vd_object_tab(in_rec_no).xvoh_object_status = cv_obj_status_102
          AND g_vd_object_tab(in_rec_no).date_retired IS NOT NULL)
        OR (g_vd_object_tab(in_rec_no).xvoh_object_status = cv_obj_status_105
          AND g_vd_object_tab(in_rec_no).date_retired <> g_vd_object_tab(in_rec_no).xvoh_date_retired)
      )
      THEN
        -- 移動日は更新しない
        g_vd_object_tab(in_rec_no).moved_date := g_vd_object_tab(in_rec_no).xvoh_moved_date;
        -- ***************************************************
        -- 自販機物件管理更新
        -- ***************************************************
        UPDATE xxcff_vd_object_headers  xvoh    -- 自販機物件管理
        SET    xvoh.object_status          = cv_obj_status_105,                          -- 物件ステータス（'105' 除売却未確定）
               xvoh.date_retired           = g_vd_object_tab(in_rec_no).date_retired,    -- 除・売却日
               xvoh.ib_if_date             = g_vd_object_tab(in_rec_no).generation_date, -- 設置ベース情報連携日
               xvoh.last_updated_by        = cn_last_updated_by,                         -- 最終更新者
               xvoh.last_update_date       = cd_last_update_date,                        -- 最終更新日
               xvoh.last_update_login      = cn_last_update_login,                       -- 最終更新ログイン
               xvoh.request_id             = cn_request_id,                              -- 要求ID
               xvoh.program_application_id = cn_program_application_id,                  -- コンカレント･プログラム･アプリケーション
               xvoh.program_id             = cn_program_id,                              -- コンカレント･プログラムID
               xvoh.program_update_date    = cd_program_update_date                      -- プログラム更新日
        WHERE  xvoh.object_header_id  = g_vd_object_tab(in_rec_no).xvoh_object_header_id -- 物件ID
        ;
--
        -- =====================================================
        --  自販機物件履歴登録 (A-5)
        -- =====================================================
        ins_vd_obj_hist(
          in_rec_no,                                         -- チェック対象レコード番号
          g_vd_object_tab(in_rec_no).xvoh_object_header_id,  -- 物件ID
          cv_obj_status_105,                                 -- 処理区分（'105' 除売却未確定）
          cv_obj_status_105,                                 -- 物件ステータス（'105' 除売却未確定）
          lv_errbuf,            -- エラー・メッセージ           --# 固定 #
          lv_retcode,           -- リターン・コード             --# 固定 #
          lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        END IF;
      END IF;
    END IF;
--
    -- 正常に取り込みが完了したデータに関して、取込ステータスを'1'（取込済）に更新
    UPDATE xxcff_vd_object_mng_if  xvomi    -- 自販機物件管理IF
    SET    xvomi.import_status           =  cv_import_status_1,         -- 取込ステータス
           xvomi.last_updated_by         =  cn_last_updated_by,         -- 最終更新者
           xvomi.last_update_date        =  cd_last_update_date,        -- 最終更新日
           xvomi.last_update_login       =  cn_last_update_login,       -- 最終更新ログイン
           xvomi.request_id              =  cn_request_id,              -- 要求ID
           xvomi.program_application_id  =  cn_program_application_id,  -- コンカレント･プログラム･アプリケーション
           xvomi.program_id              =  cn_program_id,              -- コンカレント･プログラムID
           xvomi.program_update_date     =  cd_program_update_date      -- プログラム更新日
    WHERE  xvomi.object_code = g_vd_object_tab(in_rec_no).object_code   -- 物件コード
    ;
--
    -- 「物件有効フラグ」が'N'(無効)の場合、メッセージを出力し、終了ステータスに'1'(警告)を設定
    IF (g_vd_object_tab(in_rec_no).active_flag = gv_flag_off) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,   -- アプリケーション短縮名
                     iv_name         => cv_msg_cff_00210  -- メッセージコード
                   );
      lv_token_value := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,       -- アプリケーション短縮名
                     iv_name         => cv_msg_cff_50137      -- メッセージコード
                   );
      -- 「物件コード」をトークン値に設定
      lv_token_value := lv_token_value || g_vd_object_tab(in_rec_no).object_code;
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,       -- アプリケーション短縮名
                     iv_name         => cv_msg_cff_00093,     -- メッセージコード
                     iv_token_name1  => cv_tkn_cff_00093_01,  -- トークンコード1
                     iv_token_value1 => lv_errmsg,            -- トークン値1
                     iv_token_name2  => cv_tkn_cff_00093_02,  -- トークンコード2
                     iv_token_value2 => lv_token_value        -- トークン値2
                   );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT,
        buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG,
        buff   => lv_errmsg
      );
      ov_retcode := cv_status_warn;
    END IF;
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
  END ins_upd_vd_object;
--
  /**********************************************************************************
   * Procedure Name   : delete_vd_object_if
   * Description      : 自販機物件管理IF削除処理 (A-7)
   ***********************************************************************************/
  PROCEDURE delete_vd_object_if(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_vd_object_if'; -- プログラム名
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
    -- 取込ステータスが'1'（取込済）、'9'（除売却ステータスエラー）のデータを削除
    DELETE FROM xxcff_vd_object_mng_if
    WHERE import_status IN (cv_import_status_1, cv_import_status_9)
    ;
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
  END delete_vd_object_if;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    ln_err_cnt   NUMBER;   -- 妥当性チェック時のエラー件数カウント用
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
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
    -- ローカル変数の初期化
    ln_err_cnt    := 0;
--
    -- =====================================================
    --  初期処理 (A-1)
    -- =====================================================
    init(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  自販機物件情報抽出処理 (A-2)
    -- =====================================================
    select_vd_object_info(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
    -- 処理対象件数の設定
    gn_target_cnt := g_vd_object_tab.COUNT;
    -- エラー処理件数の初期設定
    gn_error_cnt := gn_target_cnt;
--
    -- =====================================================
    --  データ妥当性チェック処理 (A-3)
    -- =====================================================
    -- 取込対象データのレコード単位のチェック
    <<validate_rec_loop>>
    FOR i IN 1..g_vd_object_tab.COUNT LOOP
      validate_record(
        i,                 -- チェック対象レコード番号
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_warn) THEN
        ln_err_cnt := ln_err_cnt + 1;
        ov_retcode := cv_status_warn;
      ELSE -- 整合性チェックエラーが発生しなかったデータのみ処理
        -- =====================================================
        --  自販機情報登録／更新 (A-4)
        -- =====================================================
        ins_upd_vd_object(
          i,                 -- チェック対象レコード番号
          lv_errbuf,         -- エラー・メッセージ           --# 固定 #
          lv_retcode,        -- リターン・コード             --# 固定 #
          lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lv_retcode = cv_status_warn) THEN
          ov_retcode  := cv_status_warn;
        END IF;
      END IF;
    END LOOP validate_rec_loop;
    -- =====================================================
    --  自販機物件管理IF削除処理 (A-6)
    -- =====================================================
    delete_vd_object_if(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    gn_error_cnt  := ln_err_cnt;                    -- エラー件数
    gn_normal_cnt := gn_target_cnt - gn_error_cnt;  -- 成功件数：対象件数 - エラー件数
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
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2       --   リターン・コード    --# 固定 #
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
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
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
END XXCFF017A01C;
/
