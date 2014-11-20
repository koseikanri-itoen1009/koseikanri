CREATE OR REPLACE PACKAGE BODY XXCFF002A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF002A01C(body)
 * Description      : 自販機・SH物件情報連携
 * MD.050           : MD050_CFF_002_A01_自販機・SH物件情報連携
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理 (A-1)
 *  select_vd_ogject_if    自販機・SH物件情報IF抽出処理 (A-2)
 *  validate_record        データ妥当性チェック処理 (A-3)
 *  ins_upd_lease_object   リース物件情報登録／更新 (A-6)
 *  delete_vd_ogject_if    自販機・SH物件情報IF削除処理 (A-7)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-12-18    1.0   SCS 増子 秀幸    新規作成
 *  2009-02-09    1.1   SCS 増子 秀幸    [障害CFF_005] ログ出力先不具合対応
 *  2011-04-05    1.2   SCS 廣瀬 真佐人  E_本稼動_06767対応
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
  record_lock_expt    EXCEPTION;    -- レコードロックエラー
  PRAGMA EXCEPTION_INIT(record_lock_expt,-54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name         CONSTANT VARCHAR2(100) := 'XXCFF002A01C';  -- パッケージ名
  cv_app_kbn_cff      CONSTANT VARCHAR2(5)   := 'XXCFF';         -- アプリケーション短縮名
--
  -- メッセージ番号
  cv_msg_cff_00007    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00007';  -- ロックエラー
  cv_msg_cff_00062    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00062';  -- 対象データなし
  cv_msg_cff_00093    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00093';  -- キー情報付エラーメッセージ
  cv_msg_cff_00094    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00094';  -- 共通関数エラー
  cv_msg_cff_00095    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00095';  -- 共通関数メッセージ
  cv_msg_cff_00097    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00097';  -- 発生日チェックエラー
  cv_msg_cff_00098    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00098';  -- リース種別同一チェックエラー
  cv_msg_cff_00099    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00099';  -- 物件の無効ステータス連携
  cv_msg_cff_00100    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00100';  -- 取込対象データスキップ
--
  -- トークン
  cv_tkn_cff_00007    CONSTANT VARCHAR2(15) := 'TABLE_NAME';     -- テーブル名
  cv_tkn_cff_00093_01 CONSTANT VARCHAR2(15) := 'ERR_MSG';        -- エラーメッセージ
  cv_tkn_cff_00093_02 CONSTANT VARCHAR2(15) := 'KEY_INFO';       -- キー情報
  cv_tkn_cff_00094    CONSTANT VARCHAR2(15) := 'FUNC_NAME';      -- 共通関数名
  cv_tkn_cff_00095    CONSTANT VARCHAR2(15) := 'ERR_MSG';        -- エラーメッセージ
  cv_tkn_cff_00097    CONSTANT VARCHAR2(15) := 'TRX_DATE';       -- 取込済データの発生日
  cv_tkn_cff_00098    CONSTANT VARCHAR2(15) := 'LEASE_CLASS';    -- 取込済データのリース種別
  cv_tkn_cff_00100    CONSTANT VARCHAR2(15) := 'BKN_STATUS';     -- 物件ステータス
--
  -- トークン値
  cv_msg_cff_50130    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50130';  -- 初期処理
  cv_msg_cff_50135    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50135';  -- 自販機・SH物件情報インタフェーステーブル
  cv_msg_cff_50137    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50137';  -- 物件コード：
  cv_msg_cff_50138    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50138';  -- リース物件情報登録
  cv_msg_cff_50141    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50141';  -- 事業所マスタチェック
--
  -- フラグ
  gv_flag_on          CONSTANT VARCHAR2(1)   := 'Y';           -- 「Y」
  gv_flag_off         CONSTANT VARCHAR2(1)   := 'N';           -- 「N」
--
  -- 取込ステータス
  cv_import_status_0  CONSTANT VARCHAR2(1)   := '0';           -- 未取込
  cv_import_status_9  CONSTANT VARCHAR2(1)   := '9';           -- 取込エラー
--
  -- 物件ステータス
  cv_obj_status_101   CONSTANT VARCHAR2(3)   := '101';         -- 未契約
  cv_obj_status_107   CONSTANT VARCHAR2(3)   := '107';         -- 満了
  cv_obj_status_110   CONSTANT VARCHAR2(3)   := '110';         -- 中途解約（自己都合）
  cv_obj_status_111   CONSTANT VARCHAR2(3)   := '111';         -- 中途解約（保険対応）
  cv_obj_status_112   CONSTANT VARCHAR2(3)   := '112';         -- 中途解約（満了）
--
  -- 書式マスク
  cv_date_format      CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';  -- 日付書式
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 自販機SH物件IF取込対象データレコード型
  TYPE g_vd_ogject_rtype IS RECORD(
    object_code          xxcff_vd_object_if.object_code%TYPE,
    generation_date      xxcff_vd_object_if.generation_date%TYPE,
    lease_class          xxcff_vd_object_if.lease_class%TYPE,
    po_number            xxcff_vd_object_if.po_number%TYPE,
    manufacturer_name    xxcff_vd_object_if.manufacturer_name%TYPE,
    age_type             xxcff_vd_object_if.age_type%TYPE,
    model                xxcff_vd_object_if.model%TYPE,
    serial_number        xxcff_vd_object_if.serial_number%TYPE,
    quantity             xxcff_vd_object_if.quantity%TYPE,
    department_code      xxcff_vd_object_if.department_code%TYPE,
    owner_company        xxcff_vd_object_if.owner_company%TYPE,
    installation_place   xxcff_vd_object_if.installation_place%TYPE,
    installation_address xxcff_vd_object_if.installation_address%TYPE,
    customer_code        xxcff_vd_object_if.customer_code%TYPE,
    active_flag          xxcff_vd_object_if.active_flag%TYPE,
    import_status        xxcff_vd_object_if.import_status%TYPE,
    xoh_object_header_id xxcff_object_headers.object_header_id%TYPE,
    xoh_generation_date  xxcff_object_headers.generation_date%TYPE,
    xoh_object_status    xxcff_object_headers.object_status%TYPE,
    xoh_lease_class      xxcff_object_headers.lease_class%TYPE
  );
--
  -- 自販機SH物件IF取込対象データレコード配列
  TYPE g_vd_ogject_ttype IS TABLE OF g_vd_ogject_rtype
  INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  g_vd_ogject_tab  g_vd_ogject_ttype;  -- 自販機SH物件IF取込対象データ
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- コンカレントパラメータの値を表示するメッセージのログ出力
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
   * Procedure Name   : select_vd_ogject_if
   * Description      : 自販機・SH物件情報IF抽出処理 (A-2)
   ***********************************************************************************/
  PROCEDURE select_vd_ogject_if(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'select_vd_ogject_if'; -- プログラム名
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
    -- 自販機SH物件IFレコードロックカーソル
    CURSOR lock_row_cur
    IS
      SELECT xvoi.object_code object_code
      FROM   xxcff_vd_object_if xvoi
      WHERE  xvoi.import_status = cv_import_status_0
      FOR UPDATE NOWAIT;
    -- 自販機SH物件IF取込対象データ取得
    CURSOR get_vd_ogject_if_cur
    IS
      SELECT xvoi.object_code object_code,                    -- 物件コード
             xvoi.generation_date generation_date,            -- 発生日
             xvoi.lease_class lease_class,                    -- リース種別
             xvoi.po_number po_number,                        -- 発注番号
             xvoi.manufacturer_name manufacturer_name,        -- メーカー
             xvoi.age_type age_type,                          -- 年式
             xvoi.model model,                                -- 機種
             xvoi.serial_number serial_number,                -- 機番
             xvoi.quantity quantity,                          -- 数量
             xvoi.department_code department_code,            -- 管理部門コード
             xvoi.owner_company owner_company,                -- 本社工場区分
             xvoi.installation_place installation_place,      -- 現設置先
             xvoi.installation_address installation_address,  -- 現設置場所
             xvoi.customer_code customer_code,                -- 顧客コード
             xvoi.active_flag active_flag,                    -- 物件有効フラグ
             xvoi.import_status import_status,                -- 取込ステータス
             xoh.object_header_id xoh_object_header_id,       -- 物件内部ID
             xoh.generation_date xoh_generation_date,         -- 取込済データの発生日
             xoh.object_status xoh_object_status,             -- 物件ステータス
             xoh.lease_class xoh_lease_class                  -- 取込済データのリース種別
      FROM   xxcff_vd_object_if xvoi,  -- 自販機SH物件インタフェース
             xxcff_object_headers xoh  -- リース物件
      WHERE  xvoi.object_code = xoh.object_code(+)
        AND  xvoi.extract_flag = gv_flag_on
      FOR UPDATE NOWAIT;
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
    BEGIN
      -- 取込対象データのロック
      OPEN  lock_row_cur;
      CLOSE lock_row_cur;
--
      -- 取込対象データの更新
      UPDATE xxcff_vd_object_if
      SET    extract_flag = gv_flag_on
      WHERE  import_status = cv_import_status_0;
--
      -- 取込対象データの抽出(リース物件も含めた再ロック)
      OPEN  get_vd_ogject_if_cur;
      FETCH get_vd_ogject_if_cur BULK COLLECT INTO g_vd_ogject_tab;
      CLOSE get_vd_ogject_if_cur;
--
    EXCEPTION
      -- 対象データがロック中の場合、エラー
      WHEN record_lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application => cv_app_kbn_cff,     -- アプリケーション短縮名
                       iv_name        => cv_msg_cff_00007,   -- メッセージコード
                       iv_token_name1  => cv_tkn_cff_00007,  -- トークンコード1
                       iv_token_value1 => cv_msg_cff_50135   -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- 対象データが0件の場合、メッセージ出力(正常終了)
    IF (g_vd_ogject_tab.COUNT = 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_app_kbn_cff,   -- アプリケーション短縮名
                     iv_name        => cv_msg_cff_00062  -- メッセージコード
                   );
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
    END IF;
--
  EXCEPTION
    WHEN global_process_expt THEN
      IF (lock_row_cur%ISOPEN) THEN
        CLOSE lock_row_cur;
      END IF;
      IF (get_vd_ogject_if_cur%ISOPEN) THEN
        CLOSE get_vd_ogject_if_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
      IF (lock_row_cur%ISOPEN) THEN
        CLOSE lock_row_cur;
      END IF;
      IF (get_vd_ogject_if_cur%ISOPEN) THEN
        CLOSE get_vd_ogject_if_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END select_vd_ogject_if;
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
    ln_location_id NUMBER;         -- 事業所ID
    lv_token_value VARCHAR2(100);  -- メッセージ出力時のトークン整形用
    lb_chk_err_flg BOOLEAN;        -- 整合性チェックエラーフラグ
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
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
    -- フラグの初期化
    lb_chk_err_flg := FALSE;
--
    -- 【マスタチェック】
    -- 共通関数(事業所マスタチェック)の呼び出し
    xxcff_common1_pkg.chk_fa_location(
      iv_segment2    => g_vd_ogject_tab(in_rec_no).department_code,  -- 管理部門
      iv_segment5    => g_vd_ogject_tab(in_rec_no).owner_company,    -- 本社／工場区分
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
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 【データ整合性チェック】
    -- 「取込済データの発生日」＜「発生日」の関係でない場合、メッセージ出力
    IF (g_vd_ogject_tab(in_rec_no).xoh_generation_date >= g_vd_ogject_tab(in_rec_no).generation_date) THEN
      -- 「取込済データの発生日」を文字列型に変換し、トークン値に設定
      lv_token_value := TO_CHAR(g_vd_ogject_tab(in_rec_no).xoh_generation_date, cv_date_format);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,       -- アプリケーション短縮名
                     iv_name         => cv_msg_cff_00097,     -- メッセージコード
                     iv_token_name1  => cv_tkn_cff_00097,     -- トークンコード1
                     iv_token_value1 => lv_token_value        -- トークン値1
                   );
      lv_token_value := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,       -- アプリケーション短縮名
                     iv_name         => cv_msg_cff_50137      -- メッセージコード
                   );
      -- 「物件コード」をトークン値に設定
      lv_token_value := lv_token_value || g_vd_ogject_tab(in_rec_no).object_code;
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
      lb_chk_err_flg := TRUE;
    END IF;
--
    -- 「物件ステータス」が '101'(未契約)以外の場合で、
    -- 「取込済データのリース種別」と「リース種別」が異なる場合、メッセージ出力
    IF (  (g_vd_ogject_tab(in_rec_no).xoh_object_status != cv_obj_status_101)
      AND (g_vd_ogject_tab(in_rec_no).xoh_lease_class != g_vd_ogject_tab(in_rec_no).lease_class)  )
    THEN
      -- 「取込済データのリース種別」をトークン値に設定
      lv_token_value := g_vd_ogject_tab(in_rec_no).xoh_lease_class;
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,       -- アプリケーション短縮名
                     iv_name         => cv_msg_cff_00098,     -- メッセージコード
                     iv_token_name1  => cv_tkn_cff_00098,     -- トークンコード1
                     iv_token_value1 => lv_token_value        -- トークン値1
                   );
      lv_token_value := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,       -- アプリケーション短縮名
                     iv_name         => cv_msg_cff_50137      -- メッセージコード
                   );
      -- 「物件コード」をトークン値に設定
      lv_token_value := lv_token_value || g_vd_ogject_tab(in_rec_no).object_code;
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
      lb_chk_err_flg := TRUE;
    END IF;
--
    -- 整合性チェックでエラーの場合、ステータスに'1'(警告)を設定
    IF (lb_chk_err_flg) THEN
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
   * Procedure Name   : ins_upd_lease_object
   * Description      : リース物件情報登録／更新 (A-6)
   ***********************************************************************************/
  PROCEDURE ins_upd_lease_object(
    in_rec_no     IN  NUMBER,       --   チェック対象レコード番号
    ob_skip_flg   OUT BOOLEAN,      --   登録／更新スキップフラグ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_upd_lease_object'; -- プログラム名
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
    lr_object_data_rec  xxcff_common3_pkg.object_data_rtype;  -- 物件情報
    lv_token_value      VARCHAR2(100);                        -- メッセージ出力時のトークン整形用
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
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
    -- フラグの初期化
    ob_skip_flg := FALSE;
--
    -- 取込対象データの解約／満了判定 (A-5)
    -- 「物件ステータス」が解約／満了に該当するコードの場合、メッセージ出力
    -- (リース物件情報登録／更新処理はスキップ)
    IF (g_vd_ogject_tab(in_rec_no).xoh_object_status
      IN(cv_obj_status_107, cv_obj_status_110, cv_obj_status_111, cv_obj_status_112))
    THEN
      -- 「取込済データの物件ステータス」をトークン値に設定
      lv_token_value := g_vd_ogject_tab(in_rec_no).xoh_object_status;
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,       -- アプリケーション短縮名
                     iv_name         => cv_msg_cff_00100,     -- メッセージコード
                     iv_token_name1  => cv_tkn_cff_00100,     -- トークンコード1
                     iv_token_value1 => lv_token_value        -- トークン値1
                   );
      lv_token_value := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,       -- アプリケーション短縮名
                     iv_name         => cv_msg_cff_50137      -- メッセージコード
                   );
      -- 「物件コード」をトークン値に設定
      lv_token_value := lv_token_value || g_vd_ogject_tab(in_rec_no).object_code;
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
      ob_skip_flg := TRUE;
    ELSE
      -- 共通関数パラメータ「リース物件情報」への値の設定
      lr_object_data_rec.object_header_id       := g_vd_ogject_tab(in_rec_no).xoh_object_header_id;  -- 物件内部ID
      lr_object_data_rec.object_code            := g_vd_ogject_tab(in_rec_no).object_code;           -- 物件コード
      lr_object_data_rec.generation_date        := g_vd_ogject_tab(in_rec_no).generation_date;       -- 発生日
      lr_object_data_rec.lease_class            := g_vd_ogject_tab(in_rec_no).lease_class;           -- リース種別
      lr_object_data_rec.po_number              := g_vd_ogject_tab(in_rec_no).po_number;             -- 発注番号
      lr_object_data_rec.manufacturer_name      := g_vd_ogject_tab(in_rec_no).manufacturer_name;     -- メーカー
      lr_object_data_rec.age_type               := g_vd_ogject_tab(in_rec_no).age_type;              -- 年式
      lr_object_data_rec.model                  := g_vd_ogject_tab(in_rec_no).model;                 -- 機種
      lr_object_data_rec.serial_number          := g_vd_ogject_tab(in_rec_no).serial_number;         -- 機番
      lr_object_data_rec.quantity               := g_vd_ogject_tab(in_rec_no).quantity;              -- 数量
      lr_object_data_rec.department_code        := g_vd_ogject_tab(in_rec_no).department_code;       -- 管理部門コード
      lr_object_data_rec.owner_company          := g_vd_ogject_tab(in_rec_no).owner_company;         -- 本社／工場区分
      lr_object_data_rec.installation_place     := g_vd_ogject_tab(in_rec_no).installation_place;    -- 現設置先
      lr_object_data_rec.installation_address   := g_vd_ogject_tab(in_rec_no).installation_address;  -- 現設置場所
      lr_object_data_rec.customer_code          := g_vd_ogject_tab(in_rec_no).customer_code;         -- 顧客コード
      lr_object_data_rec.active_flag            := g_vd_ogject_tab(in_rec_no).active_flag;           -- 物件有効フラグ
      lr_object_data_rec.created_by             := cn_created_by;                -- 作成者
      lr_object_data_rec.creation_date          := cd_creation_date;             -- 作成日
      lr_object_data_rec.last_updated_by        := cn_last_updated_by;           -- 最終更新者
      lr_object_data_rec.last_update_date       := cd_last_update_date;          -- 最終更新日
      lr_object_data_rec.last_update_login      := cn_last_update_login;         -- 最終更新ﾛｸﾞｲﾝ
      lr_object_data_rec.request_id             := cn_request_id;                -- 要求ID
      lr_object_data_rec.program_application_id := cn_program_application_id;    -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
      lr_object_data_rec.program_id             := cn_program_id;                -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
      lr_object_data_rec.program_update_date    := cd_program_update_date;       -- ﾌﾟﾛｸﾞﾗﾑ更新日
--
      -- 共通関数(リース物件情報作成（バッチ）)の呼び出し
      xxcff_common3_pkg.create_ob_bat(
        io_object_data_rec => lr_object_data_rec,  -- 初期取得情報
        ov_retcode         => lv_retcode,          -- リターンコード
        ov_errbuf          => lv_errbuf,           -- エラーメッセージ
        ov_errmsg          => lv_errmsg            -- ユーザー・エラーメッセージ
      );
      IF (lv_retcode != cv_status_normal) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_kbn_cff,       -- アプリケーション短縮名
                       iv_name         => cv_msg_cff_00094,     -- メッセージコード
                       iv_token_name1  => cv_tkn_cff_00094,     -- トークンコード1
                       iv_token_value1 => cv_msg_cff_50138      -- トークン値1
                     );
        lv_errbuf := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_kbn_cff,       -- アプリケーション短縮名
                       iv_name         => cv_msg_cff_00095,     -- メッセージコード
                       iv_token_name1  => cv_tkn_cff_00095,     -- トークンコード1
                       iv_token_value1 => lv_errbuf             -- トークン値1
                     );
        lv_errmsg := lv_errmsg || lv_errbuf;
        lv_token_value := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_kbn_cff,       -- アプリケーション短縮名
                       iv_name         => cv_msg_cff_50137      -- メッセージコード
                     );
        -- 「物件コード」をトークン値に設定
        lv_token_value := lv_token_value || g_vd_ogject_tab(in_rec_no).object_code;
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_kbn_cff,       -- アプリケーション短縮名
                       iv_name         => cv_msg_cff_00093,     -- メッセージコード
                       iv_token_name1  => cv_tkn_cff_00093_01,  -- トークンコード1
                       iv_token_value1 => lv_errmsg,            -- トークン値1
                       iv_token_name2  => cv_tkn_cff_00093_02,  -- トークンコード2
                       iv_token_value2 => lv_token_value        -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      -- 「物件有効フラグ」が'N'(無効)の場合、メッセージ出力し、ステータスに'1'(警告)を設定
      IF (g_vd_ogject_tab(in_rec_no).active_flag = gv_flag_off) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_kbn_cff,   -- アプリケーション短縮名
                       iv_name         => cv_msg_cff_00099  -- メッセージコード
                     );
        lv_token_value := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_kbn_cff,       -- アプリケーション短縮名
                       iv_name         => cv_msg_cff_50137      -- メッセージコード
                     );
        -- 「物件コード」をトークン値に設定
        lv_token_value := lv_token_value || g_vd_ogject_tab(in_rec_no).object_code;
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
        ov_retcode := cv_status_warn;
      END IF;
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
  END ins_upd_lease_object;
--
  /**********************************************************************************
   * Procedure Name   : delete_vd_ogject_if
   * Description      : 自販機・SH物件情報IF削除処理 (A-7)
   ***********************************************************************************/
  PROCEDURE delete_vd_ogject_if(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_vd_ogject_if'; -- プログラム名
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
    -- 取込対象データの削除
    DELETE FROM xxcff_vd_object_if
    WHERE extract_flag = gv_flag_on;
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
  END delete_vd_ogject_if;
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
-- ************ 2011-04-05 1.2 M.Hirose DEL START ************ --
--    ln_skip_cnt  NUMBER;   -- リース物件情報登録／更新スキップ件数カウント用
-- ************ 2011-04-05 1.2 M.Hirose DEL END   ************ --
    lb_skip_flg  BOOLEAN;  -- リース物件情報登録／更新スキップフラグ
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
-- ************ 2011-04-05 1.2 M.Hirose DEL START ************ --
--    gn_warn_cnt   := 0;
-- ************ 2011-04-05 1.2 M.Hirose DEL END   ************ --
--
    -- ローカル変数の初期化
    ln_err_cnt    := 0;
-- ************ 2011-04-05 1.2 M.Hirose DEL START ************ --
--    ln_skip_cnt   := 0;
-- ************ 2011-04-05 1.2 M.Hirose DEL END   ************ --
    lb_skip_flg   := FALSE;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
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
    --  自販機・SH物件情報IF抽出処理 (A-2)
    -- =====================================================
    select_vd_ogject_if(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 処理対象件数の設定
    gn_target_cnt := g_vd_ogject_tab.COUNT;
    -- エラー処理件数の初期設定
    gn_error_cnt := gn_target_cnt;
--
    -- =====================================================
    --  データ妥当性チェック処理 (A-3)
    -- =====================================================
    -- 取込対象データのレコード単位のチェック
    <<validate_rec_loop>>
    FOR i IN 1..g_vd_ogject_tab.COUNT LOOP
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
-- ************ 2011-04-05 1.2 M.Hirose MOD START ************ --
--      END IF;
--    END LOOP validate_rec_loop;
      ELSE
-- ************ 2011-04-05 1.2 M.Hirose MOD END   ************ --
--
    -- =====================================================
    --  リース物件情報登録／更新 (A-6)
    -- =====================================================
-- ************ 2011-04-05 1.2 M.Hirose DEL START ************ --
--    -- エラー件数判定 (A-4)
--    -- 妥当性チェックでエラーデータが存在した場合は、以下の処理を行わない
--    IF (ln_err_cnt = 0) THEN
--      <<ins_upd_lease_obj_loop>>
--      FOR i IN 1..g_vd_ogject_tab.COUNT LOOP
-- ************ 2011-04-05 1.2 M.Hirose DEL END   ************ --
        ins_upd_lease_object(
          i,                 -- チェック対象レコード番号
          lb_skip_flg,       -- 登録／更新スキップフラグ
          lv_errbuf,         -- エラー・メッセージ           --# 固定 #
          lv_retcode,        -- リターン・コード             --# 固定 #
          lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lv_retcode = cv_status_warn) THEN
          ov_retcode  := cv_status_warn;
        END IF;
        IF (lb_skip_flg) THEN
-- ************ 2011-04-05 1.2 M.Hirose MOD START ************ --
--          ln_skip_cnt := ln_skip_cnt + 1;
          ln_err_cnt := ln_err_cnt + 1;
-- ************ 2011-04-05 1.2 M.Hirose MOD END   ************ --
        END IF;
-- ************ 2011-04-05 1.2 M.Hirose MOD START ************ --
--      END LOOP validate_rec_loop;
--    END IF;
      END IF;
    END LOOP validate_rec_loop;
-- ************ 2011-04-05 1.2 M.Hirose MOD END   ************ --
--
    -- =====================================================
    --  自販機・SH物件情報IF削除処理 (A-7)
    -- =====================================================
    delete_vd_ogject_if(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
-- ************ 2011-04-05 1.2 M.Hirose MOD START ************ --
--    -- 正常終了の場合のグローバル変数の設定
--    IF (ln_err_cnt = 0) THEN
--      gn_error_cnt  := 0;
--      gn_warn_cnt   := ln_skip_cnt;
--      gn_normal_cnt := gn_target_cnt - gn_warn_cnt;
--    END IF;
    gn_error_cnt  := ln_err_cnt;                    -- エラー件数
    gn_normal_cnt := gn_target_cnt - gn_error_cnt;  -- 成功件数：対象件数 - エラー件数
-- ************ 2011-04-05 1.2 M.Hirose MOD END   ************ --
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
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
-- ************ 2011-04-05 1.2 M.Hirose DEL START ************ --
--    --
--    --スキップ件数出力
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_appl_short_name
--                    ,iv_name         => cv_skip_rec_msg
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
--                   );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => gv_out_msg
--    );
-- ************ 2011-04-05 1.2 M.Hirose DEL END   ************ --
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
END XXCFF002A01C;
/
