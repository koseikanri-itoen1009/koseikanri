CREATE OR REPLACE PACKAGE BODY xxinv990001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXINV990001C(body)
 * Description      : 販売計画/引取計画のアップロード
 * MD.050           : ファイルアップロード            T_MD050_BPO_990
 * MD.070           : 販売計画/引取計画のアップロード T_MD070_BPO_99B
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  check_param            パラメータチェック(B-1)
 *  init_proc              関連データ取得(B-2)
 *  get_upload_data_proc   ファイルアップロードインタフェースデータ取得(B-3)
 *  check_proc             妥当性チェック (B-4)
 *  set_data_proc          登録データセット
 *  insert_mrp_forecast_if データ登録(B-5)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/02/20    1.0  Oracle 和田 大輝  初回作成
 *  2008/04/18    1.1  Oracle 山根 一浩  変更要求No63対応
 *  2008/04/24    1.2  Oracle 中村 純恵  部署コード取得時呼出共通関数変更
 *  2008/04/25    1.3  Oracle 山根 一浩  変更要求No70対応
 *  2008/04/25    1.3  Oracle 山根 一浩  変更要求No73対応
 *  2008/07/08    1.4  Oracle 山根 一浩  I_S_192対応
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
  global_process_expt    EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt        EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  lock_expt              EXCEPTION;     -- ロック取得エラー
  no_data_if_expt           EXCEPTION;     -- 対象データなし
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name            CONSTANT VARCHAR2(100) := 'xxinv990001c'; -- パッケージ名
--
  -- フォーマットパターン識別コード
  gv_format_code_01      CONSTANT VARCHAR2(2) := '01';
  gv_format_code_02      CONSTANT VARCHAR2(2) := '02';
  gv_format_code_03      CONSTANT VARCHAR2(2) := '03';
  gv_format_code_04      CONSTANT VARCHAR2(2) := '04';
  gv_format_code_05      CONSTANT VARCHAR2(2) := '05';
--
  gv_c_msg_kbn           CONSTANT VARCHAR2(5) := 'XXINV'; -- アプリケーション短縮名
--
  -- メッセージ番号
  gv_c_msg_99b_008 CONSTANT VARCHAR2(15) := 'APP-XXINV-10008'; -- データ取得エラーメッセージ
  gv_c_msg_99b_016 CONSTANT VARCHAR2(15) := 'APP-XXINV-10015'; -- パラメータエラーメッセージ
  gv_c_msg_99b_024 CONSTANT VARCHAR2(15) := 'APP-XXINV-10024'; -- フォーマットエラーメッセージ
  gv_c_msg_99b_025 CONSTANT VARCHAR2(15) := 'APP-XXINV-10025'; -- プロファイル取得エラーメッセージ
  gv_c_msg_99b_032 CONSTANT VARCHAR2(15) := 'APP-XXINV-10032'; -- ロックエラーメッセージ
--
  gv_c_msg_99b_101       CONSTANT VARCHAR2(15)  := 'APP-XXINV-00001'; -- ファイル名
  gv_c_msg_99b_103       CONSTANT VARCHAR2(15)  := 'APP-XXINV-00003'; -- アップロード日時
  gv_c_msg_99b_104       CONSTANT VARCHAR2(15)  := 'APP-XXINV-00004'; -- ファイルアップロード名称
  gv_c_msg_99b_106       CONSTANT VARCHAR2(15)  := 'APP-XXINV-00006'; -- フォーマットパターン
--
  -- トークン
  gv_c_tkn_param         CONSTANT VARCHAR2(15) := 'PARAMETER';
  gv_c_tkn_value         CONSTANT VARCHAR2(15) := 'VALUE';
  gv_c_tkn_name          CONSTANT VARCHAR2(15) := 'NAME';
  gv_c_tkn_item          CONSTANT VARCHAR2(15) := 'ITEM';
  gv_c_tkn_table         CONSTANT VARCHAR2(15) := 'TABLE';
--
  -- プロファイル
  gv_c_parge_term_001    CONSTANT VARCHAR2(20) := 'XXINV_PURGE_TERM_001';
  gv_c_parge_term_name   CONSTANT VARCHAR2(40) := 'パージ対象期間：販売計画引取計画';
--
  -- クイックコード タイプ
  gv_c_lookup_type       CONSTANT VARCHAR2(30) := 'XXINV_FILE_OBJECT';
  gv_c_format_type       CONSTANT VARCHAR2(20) := 'フォーマットパターン';
--
  gv_user_id_name        CONSTANT VARCHAR2(10) := 'ユーザーID';
  gv_file_id_name        CONSTANT VARCHAR2(24) := 'FILE_ID';
  gv_file_up_if_tbl      CONSTANT VARCHAR2(50) := 'ファイルアップロードインタフェーステーブル';
--
  gv_period              CONSTANT VARCHAR2(1) := '.';      -- ピリオド
  gv_comma               CONSTANT VARCHAR2(1) := ',';      -- カンマ
  gv_space               CONSTANT VARCHAR2(1) := ' ';      -- スペース
  gv_err_msg_space       CONSTANT VARCHAR2(6) := '      '; -- スペース（6byte）
--
  -- 販売計画/引取計画インタフェーステーブル：項目名
  gv_location_code_n     CONSTANT VARCHAR2(50) := '出荷倉庫';
  gv_base_code_n         CONSTANT VARCHAR2(50) := '拠点';
  gv_dept_code_n         CONSTANT VARCHAR2(50) := '取込部署';
  gv_item_code_n         CONSTANT VARCHAR2(50) := '品目';
  gv_forecast_date_n     CONSTANT VARCHAR2(50) := '開始日付';
  gv_forecast_end_date_n CONSTANT VARCHAR2(50) := '終了日付';
  gv_case_quantity_n     CONSTANT VARCHAR2(50) := 'ケース数量';
  gv_indivi_quantity_n   CONSTANT VARCHAR2(50) := 'バラ数量';
  gv_amount_n            CONSTANT VARCHAR2(50) := '金額';
--
  -- 販売計画/引取計画インタフェーステーブル：項目桁数
  gv_location_code_l     CONSTANT NUMBER := 4;   -- 出荷倉庫
  gv_base_code_l         CONSTANT NUMBER := 4;   -- 拠点
  gv_dept_code_l         CONSTANT NUMBER := 4;   -- 取込部署
  gv_item_code_l         CONSTANT NUMBER := 7;   -- 品目
  gv_case_quantity_l     CONSTANT NUMBER := 38;  -- ケース数量(整数部)
  gv_indivi_quantity_l   CONSTANT NUMBER := 38;  -- バラ数量
  gv_amount_l            CONSTANT NUMBER := 38;  -- 金額
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- CSVを格納するレコード
  TYPE file_data_rec IS RECORD(
    location_code       VARCHAR2(32767), -- 出荷倉庫
    base_code           VARCHAR2(32767), -- 拠点
    dept_code           VARCHAR2(32767), -- 取込部署
    item_code           VARCHAR2(32767), -- 品目
    forecast_date       VARCHAR2(32767), -- 開始日付
    forecast_end_date   VARCHAR2(32767), -- 終了日付
    case_quantity       VARCHAR2(32767), -- ケース数量
    indivi_quantity     VARCHAR2(32767), -- バラ数量
    amount              VARCHAR2(32767), -- 金額
    line                VARCHAR2(32767), -- 行内容全て（内部制御用）
    err_message         VARCHAR2(32767)  -- エラーメッセージ（内部制御用）
  );
--
  -- CSVを格納する結合配列
  TYPE file_data_tbl IS TABLE OF file_data_rec INDEX BY BINARY_INTEGER;
  fdata_tbl   file_data_tbl;
--
  -- 登録用PL/SQL表型
  -- 1.取引ID
  TYPE forecast_if_id_type        IS TABLE OF xxinv_mrp_forecast_interface.forecast_if_id%TYPE
  INDEX BY BINARY_INTEGER;
  -- 2.Forecast分類
  TYPE forecast_designator_type   IS TABLE OF xxinv_mrp_forecast_interface.forecast_designator%TYPE
  INDEX BY BINARY_INTEGER; 
  -- 3.出荷倉庫
  TYPE location_code_type         IS TABLE OF xxinv_mrp_forecast_interface.location_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- 4.拠点
  TYPE base_code_type             IS TABLE OF xxinv_mrp_forecast_interface.base_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- 5.取込部署
  TYPE dept_code_type             IS TABLE OF xxinv_mrp_forecast_interface.dept_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- 6.品目
  TYPE item_code_type             IS TABLE OF xxinv_mrp_forecast_interface.item_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- 7.開始日付
  TYPE forecast_date_type         IS TABLE OF xxinv_mrp_forecast_interface.forecast_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- 8.終了日付
  TYPE forecast_end_date_type     IS TABLE OF xxinv_mrp_forecast_interface.forecast_end_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- 9.ケース数量
  TYPE case_quantity_type         IS TABLE OF xxinv_mrp_forecast_interface.case_quantity%TYPE
  INDEX BY BINARY_INTEGER;
  -- 10.バラ数量
  TYPE indivi_quantity_type       IS TABLE OF xxinv_mrp_forecast_interface.indivi_quantity%TYPE
  INDEX BY BINARY_INTEGER;
  -- 11.金額
  TYPE amount_type                IS TABLE OF xxinv_mrp_forecast_interface.amount%TYPE
  INDEX BY BINARY_INTEGER;
--
  gt_forecast_if_id        forecast_if_id_type;      -- 1.取引ID
  gt_forecast_designator   forecast_designator_type; -- 2.Forecast分類
  gt_location_code         location_code_type;       -- 3.出荷倉庫
  gt_base_code             base_code_type;           -- 4.拠点
  gt_dept_code             dept_code_type;           -- 5.取込部署
  gt_item_code             item_code_type;           -- 6.品目
  gt_forecast_date         forecast_date_type;       -- 7.開始日付
  gt_forecast_end_date     forecast_end_date_type;   -- 8.終了日付
  gt_case_quantity         case_quantity_type;       -- 9.ケース数量
  gt_indivi_quantity       indivi_quantity_type;     -- 10.バラ数量
  gt_amount                amount_type;              -- 11.金額
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  gd_sysdate               DATE;            -- システム日付
  gn_user_id               NUMBER;          -- ユーザID
  gn_login_id              NUMBER;          -- 最終更新ログイン
  gn_conc_request_id       NUMBER;          -- 要求ID
  gn_prog_appl_id          NUMBER;          -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑのｱﾌﾟﾘｹｰｼｮﾝID
  gn_conc_program_id       NUMBER;          -- コンカレント・プログラムID
--
  gn_xxinv_parge_term      NUMBER;          -- パージ対象期間
  gv_file_name             VARCHAR2(256);   -- ファイル名
  gv_file_up_name          VARCHAR2(256);   -- ファイルアップロード名称
  gv_file_content_type     VARCHAR2(256);   -- ファイル交換方式オブジェクトタイプコード
  gn_created_by            NUMBER(15);      -- 作成者
  gd_creation_date         DATE;            -- 作成日
  gv_check_proc_retcode    VARCHAR2(1);     -- 妥当性チェックステータス
  gv_location_code         VARCHAR2(60);    -- 事業所コード
--
  /**********************************************************************************
   * Procedure Name   : check_param
   * Description      : パラメータチェック(B-1)
   ***********************************************************************************/
  PROCEDURE check_param(
    iv_file_format IN  VARCHAR2,     --   1.フォーマットパターン
    ov_errbuf      OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg      OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_param'; -- プログラム名
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
    ln_param_count   NUMBER;   -- パラメータ
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- フォーマットパターンチェック
    SELECT COUNT(xlvv.lookup_code) lookup_code -- コード
    INTO   ln_param_count
    FROM   xxcmn_lookup_values_v xlvv          -- クイックコードVIEW
    WHERE  xlvv.lookup_type = gv_c_lookup_type
    AND    xlvv.lookup_code = iv_file_format
    AND    ROWNUM           = 1;
--
    -- フォーマットパターンがクイックコードに登録されていない場合
    IF (ln_param_count < 1) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,   gv_c_msg_99b_016,
                                             gv_c_tkn_param, gv_c_format_type,
                                             gv_c_tkn_value, iv_file_format);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END check_param;
--
  /**********************************************************************************
   * Procedure Name   : init_proc
   * Description      : 関連データ取得(B-2)
   ***********************************************************************************/
  PROCEDURE init_proc(
    iv_file_format IN  VARCHAR2,     --   1.フォーマットパターン
    ov_errbuf      OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg      OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init_proc'; -- プログラム名
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
    lv_parge_term   VARCHAR2(100);   -- プロファイル格納場所
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- システム日付取得
    gd_sysdate := SYSDATE;
    -- WHOカラム情報取得
    gn_user_id          := FND_GLOBAL.USER_ID;         -- ユーザID
    gn_login_id         := FND_GLOBAL.LOGIN_ID;        -- 最終更新ログイン
    gn_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID; -- 要求ID
    gn_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;    -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑのｱﾌﾟﾘｹｰｼｮﾝID
    gn_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID; -- コンカレント・プログラムID
--
    -- プロファイル「パージ対象期間」取得
    lv_parge_term := FND_PROFILE.VALUE(gv_c_parge_term_001);
--
    -- プロファイルが取得できない場合はエラー
    IF (lv_parge_term IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,  gv_c_msg_99b_025,
                                            gv_c_tkn_name, gv_c_parge_term_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- プロファイル値チェック
    BEGIN
      -- TO_NUMBERできなければエラー
      gn_xxinv_parge_term := TO_NUMBER(lv_parge_term);
    EXCEPTION
      WHEN INVALID_NUMBER OR VALUE_ERROR THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,  gv_c_msg_99b_025,
                                            gv_c_tkn_name, gv_c_parge_term_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END;
--
    -- ファイルアップロード名称取得
    BEGIN
      SELECT  xlvv.meaning
      INTO    gv_file_up_name
      FROM    xxcmn_lookup_values_v xlvv                -- クイックコードVIEW
      WHERE   xlvv.lookup_type = gv_c_lookup_type       -- タイプ
      AND     xlvv.lookup_code = iv_file_format         -- コード
      AND     ROWNUM           = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN   --*** データ取得エラー ***
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,   gv_c_msg_99b_008,
                                              gv_c_tkn_item,  gv_c_format_type,
                                              gv_c_tkn_value, iv_file_format);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- 事業所コード取得
    -- 2008/4/24 modify start
    -- gv_location_code := xxcmn_common_pkg.get_user_dept(gn_user_id);
    gv_location_code := xxcmn_common_pkg.get_user_dept_code(gn_user_id);
    -- 2008/4/24 modify end
--
    -- 事業所コードが取得できない場合はエラー
    IF (gv_location_code IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,   gv_c_msg_99b_008,
                                            gv_c_tkn_item,  gv_user_id_name,
                                            gv_c_tkn_value, gn_user_id);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init_proc;
--
  /**********************************************************************************
   * Procedure Name   : get_upload_data_proc
   * Description      : ファイルアップロードインタフェースデータ取得(B-3)
   ***********************************************************************************/
  PROCEDURE get_upload_data_proc(
    in_file_id          IN  NUMBER,            -- FILE_ID
    iv_file_format      IN  VARCHAR2,          -- フォーマットパターン
    ov_errbuf           OUT NOCOPY VARCHAR2,   -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,   -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(25) := 'get_upload_data_proc';  -- プログラム名
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
    lv_line       VARCHAR2(32767);   -- 改行コード迄の情報
    ln_col        NUMBER;            -- カラム
    lb_col        BOOLEAN := TRUE;   -- カラム作成継続
    ln_length     NUMBER;            -- 長さ保管用
--
    lt_file_line_data   xxcmn_common3_pkg.g_file_data_tbl;   -- 行テーブル格納領域
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***     インタフェース情報取得      ***
    -- ***************************************
    -- ファイルアップロードインタフェースデータ取得
    -- 行ロック処理
    SELECT xmf.file_content_type,  -- ファイル交換方式オブジェクトタイプコード
           xmf.file_name,          -- ファイル名
           xmf.created_by,         -- 作成者
           xmf.creation_date       -- 作成日
    INTO   gv_file_content_type,
           gv_file_name,
           gn_created_by,
           gd_creation_date
    FROM   xxinv_mrp_file_ul_interface xmf
    WHERE  xmf.file_id = in_file_id
    FOR UPDATE OF xmf.file_id NOWAIT;
--
    -- ***************************************
    -- ***    インタフェースデータ取得     ***
    -- ***************************************
    xxcmn_common3_pkg.blob_to_varchar2(
      in_file_id,                                       -- ファイルID
      lt_file_line_data,                                -- 変換後VARCHAR2データ
      lv_errbuf,                                        -- エラー・メッセージ           --# 固定 #
      lv_retcode,                                       -- リターン・コード             --# 固定 #
      lv_errmsg);                                       -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- タイトル行のみ、又は、2行目が改行のみの場合
    IF (lt_file_line_data.LAST < 2) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,   gv_c_msg_99b_008,
                                            gv_c_tkn_item,  gv_file_id_name,
                                            gv_c_tkn_value, in_file_id);
      lv_errbuf := lv_errmsg;
      RAISE no_data_if_expt;
    END IF;
--
    -- *********************************************
    -- ***  取得データを行単位で処理(2行目以降)  ***
    -- *********************************************
    <<line_loop>>
    FOR ln_index IN 2 .. lt_file_line_data.LAST LOOP
--
      -- 対象件数カウント
      gn_target_cnt := gn_target_cnt + 1;
--
      -- 行毎に作業領域に格納
      lv_line := lt_file_line_data(ln_index);
--
      -- 1行の内容をlineに格納
      fdata_tbl(gn_target_cnt).line := lv_line;
--
      -- カラム番号初期化
      ln_col := 0;                                      -- カラム
      lb_col := TRUE;                                   -- カラム作成継続
--
      -- ***************************************
      -- ***       1行をカンマ毎に分解       ***
      -- ***************************************
      <<comma_loop>>
      LOOP
        -- lv_lineの長さが0なら終了
        EXIT WHEN ((lb_col = FALSE) OR (lv_line IS NULL));
--
        -- カラム番号をカウント
        ln_col := ln_col + 1;
--
        -- カンマの位置を取得
        ln_length := INSTR(lv_line, gv_comma);
        -- カンマがない
        IF (ln_length = 0) THEN
          ln_length := LENGTH(lv_line);
          lb_col    := FALSE;
        -- カンマがある
        ELSE
          ln_length := ln_length -1;
          lb_col    := TRUE;
        END IF;
--
        -- CSV形式を項目ごとにレコードに格納
        -- ***************************************
        -- ***             1項目目             ***
        -- ***************************************
        IF (ln_col = 1) THEN
          -- フォーマットパターンが「1」「2」「4」の場合
          IF ((iv_file_format = gv_format_code_01)
              OR (iv_file_format = gv_format_code_02)
              OR (iv_file_format = gv_format_code_04))
          THEN
            -- 出荷倉庫
            fdata_tbl(gn_target_cnt).location_code     := SUBSTR(lv_line, 1, ln_length);
          -- フォーマットパターンが「3」「5」の場合
          ELSIF ((iv_file_format = gv_format_code_03)
              OR (iv_file_format = gv_format_code_05))
          THEN
            -- 拠点
            fdata_tbl(gn_target_cnt).base_code         := SUBSTR(lv_line, 1, ln_length);
          END IF;
--
        -- ***************************************
        -- ***             2項目目             ***
        -- ***************************************
        ELSIF  (ln_col = 2) THEN
          -- フォーマットパターンが「1」「2」の場合
          IF ((iv_file_format = gv_format_code_01)
              OR (iv_file_format = gv_format_code_02))
          THEN
            -- 拠点
            fdata_tbl(gn_target_cnt).base_code         := SUBSTR(lv_line, 1, ln_length);
          -- フォーマットパターンが「3」「5」の場合
          ELSIF ((iv_file_format = gv_format_code_03)
                 OR (iv_file_format = gv_format_code_05))
          THEN
            -- 品目
            fdata_tbl(gn_target_cnt).item_code         := SUBSTR(lv_line, 1, ln_length);
          -- フォーマットパターンが「4」の場合
          ELSIF (iv_file_format = gv_format_code_04) THEN
            -- 取込部署
            fdata_tbl(gn_target_cnt).dept_code           := SUBSTR(lv_line, 1, ln_length);
          END IF;
--
        -- ***************************************
        -- ***             3項目目             ***
        -- ***************************************
        ELSIF  (ln_col = 3) THEN
          -- フォーマットパターンが「1」「2」「4」の場合
          IF ((iv_file_format = gv_format_code_01)
              OR (iv_file_format = gv_format_code_02)
              OR (iv_file_format = gv_format_code_04))
          THEN
            -- 品目
            fdata_tbl(gn_target_cnt).item_code         := SUBSTR(lv_line, 1, ln_length);
          -- フォーマットパターンが「3」の場合
          ELSIF (iv_file_format = gv_format_code_03) THEN
            -- 開始日付
            fdata_tbl(gn_target_cnt).forecast_date       := SUBSTR(lv_line, 1, ln_length);
          -- フォーマットパターンが「5」の場合
          ELSIF (iv_file_format = gv_format_code_05) THEN
            -- 日付(開始日付と終了日付の両方に設定)
            fdata_tbl(gn_target_cnt).forecast_date       := SUBSTR(lv_line, 1, ln_length);
            fdata_tbl(gn_target_cnt).forecast_end_date   := fdata_tbl(gn_target_cnt).forecast_date;
          END IF;
--
        -- ***************************************
        -- ***             4項目目             ***
        -- ***************************************
        ELSIF  (ln_col = 4) THEN
          -- フォーマットパターンが「1」の場合
          IF (iv_file_format = gv_format_code_01) THEN
            -- 日付(開始日付と終了日付の両方に設定)
            fdata_tbl(gn_target_cnt).forecast_date       := SUBSTR(lv_line, 1, ln_length);
            fdata_tbl(gn_target_cnt).forecast_end_date   := fdata_tbl(gn_target_cnt).forecast_date;
          -- フォーマットパターンが「2」「4」の場合
          ELSIF ((iv_file_format = gv_format_code_02)
                 OR (iv_file_format = gv_format_code_04))
          THEN
            -- 開始日付
            fdata_tbl(gn_target_cnt).forecast_date       := SUBSTR(lv_line, 1, ln_length);
          -- フォーマットパターンが「3」の場合
          ELSIF (iv_file_format = gv_format_code_03) THEN
            -- 終了日付
            fdata_tbl(gn_target_cnt).forecast_end_date   := SUBSTR(lv_line, 1, ln_length);
          -- フォーマットパターンが「5」の場合
          ELSIF (iv_file_format = gv_format_code_05) THEN
            -- ケース数量
            fdata_tbl(gn_target_cnt).case_quantity     := SUBSTR(lv_line, 1, ln_length);
          END IF;
--
        -- ***************************************
        -- ***             5項目目             ***
        -- ***************************************
        ELSIF  (ln_col = 5) THEN
          -- フォーマットパターンが「1」「3」の場合
          IF ((iv_file_format = gv_format_code_01)
              OR (iv_file_format = gv_format_code_03))
          THEN
            -- ケース数量
            fdata_tbl(gn_target_cnt).case_quantity     := SUBSTR(lv_line, 1, ln_length);
          -- フォーマットパターンが「2」「4」の場合
          ELSIF ((iv_file_format = gv_format_code_02)
                OR (iv_file_format = gv_format_code_04))
          THEN
            -- 終了日付
            fdata_tbl(gn_target_cnt).forecast_end_date   := SUBSTR(lv_line, 1, ln_length);
          -- フォーマットパターンが「5」の場合
          ELSIF (iv_file_format = gv_format_code_05) THEN
            -- バラ数量
            fdata_tbl(gn_target_cnt).indivi_quantity   := SUBSTR(lv_line, 1, ln_length);
          END IF;
--
        -- ***************************************
        -- ***             6項目目             ***
        -- ***************************************
        ELSIF  (ln_col = 6) THEN
          -- フォーマットパターンが「1」「3」の場合
          IF ((iv_file_format = gv_format_code_01)
              OR (iv_file_format = gv_format_code_03))
          THEN
            -- バラ数量
            fdata_tbl(gn_target_cnt).indivi_quantity   := SUBSTR(lv_line, 1, ln_length);
          -- フォーマットパターンが「2」「4」の場合
          ELSIF ((iv_file_format = gv_format_code_02)
                 OR (iv_file_format = gv_format_code_04))
          THEN
            -- ケース数量
            fdata_tbl(gn_target_cnt).case_quantity     := SUBSTR(lv_line, 1, ln_length);
          -- フォーマットパターンが「5」の場合
          ELSIF (iv_file_format = gv_format_code_05) THEN
            -- 金額
            fdata_tbl(gn_target_cnt).amount            := SUBSTR(lv_line, 1, ln_length);
          END IF;
--
        -- ***************************************
        -- ***             7項目目             ***
        -- ***************************************
        ELSIF  (ln_col = 7) THEN
          -- フォーマットパターンが「2」「4」の場合
          IF ((iv_file_format = gv_format_code_02)
              OR (iv_file_format = gv_format_code_04))
          THEN
            -- バラ数量
            fdata_tbl(gn_target_cnt).indivi_quantity   := SUBSTR(lv_line, 1, ln_length);
          END IF;
        END IF;
--
        -- strは今回取得した行を除く（カンマはのぞくため、ln_length + 2）
        IF (lb_col = TRUE) THEN
          lv_line := SUBSTR(lv_line, ln_length + 2);
        ELSE
          lv_line := SUBSTR(lv_line, ln_length);
        END IF;
--
      END LOOP comma_loop;
    END LOOP line_loop;
--
  EXCEPTION
    WHEN no_data_if_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_retcode := gv_status_warn;
--
    WHEN lock_expt THEN   --*** ロック取得エラー ***
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,   gv_c_msg_99b_032,
                                            gv_c_tkn_table, gv_file_up_if_tbl);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
    WHEN NO_DATA_FOUND THEN   --*** データ取得エラー ***
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,   gv_c_msg_99b_008,
                                            gv_c_tkn_item,  gv_file_id_name,
                                            gv_c_tkn_value, in_file_id);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
--#################################  固定例外処理部 START   ####################################
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_upload_data_proc;
--
  /**********************************************************************************
   * Procedure Name   : check_proc
   * Description      : 妥当性チェック(B-4)
   ***********************************************************************************/
  PROCEDURE check_proc(
    iv_file_format IN  VARCHAR2,     --   フォーマットパターン
    ov_errbuf      OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode     OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg      OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_proc'; -- プログラム名
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
    lv_line_feed        VARCHAR2(1);                  -- 改行コード
--
    -- *** ローカル変数 ***
    ln_c_col   NUMBER; -- 総項目数
--
    lv_log_data                                      VARCHAR2(32767);  -- LOGデータ部退避用
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
    -- 初期化
    gv_check_proc_retcode := gv_status_normal; -- 妥当性チェックステータス
    lv_line_feed := CHR(10);                   -- 改行コード
--
    -- 総項目数の設定
    -- フォーマットパターンが「1」「3」「5」の場合
    IF ((iv_file_format = gv_format_code_01)
        OR (iv_file_format = gv_format_code_03)
        OR (iv_file_format = gv_format_code_05))
    THEN
      ln_c_col := 6;
    -- フォーマットパターンが「2」「4」の場合
    ELSIF ((iv_file_format = gv_format_code_02)
           OR (iv_file_format = gv_format_code_04))
    THEN
      ln_c_col := 7;
    END IF;
--
    -- **************************************************
    -- *** 取得したレコード毎に項目チェックを行う。
    -- **************************************************
    <<check_loop>>
    FOR ln_index IN 1 .. fdata_tbl.LAST LOOP
--
      -- **************************************************
      -- *** 項目数チェック
      -- **************************************************
      -- (行全体の長さ - 行からカンマを抜いた長さ = カンマの数)
      --   <> (正式な項目数 - 1 = 正式なカンマの数)
      IF ((NVL(LENGTH(fdata_tbl(ln_index).line) ,0)
        - NVL(LENGTH(REPLACE(fdata_tbl(ln_index).line,gv_comma, NULL)),0))
          <> (ln_c_col - 1))
      THEN
--
        fdata_tbl(ln_index).err_message := gv_err_msg_space || gv_err_msg_space
                                      || xxcmn_common_pkg.get_msg(gv_c_msg_kbn, gv_c_msg_99b_024)
                                      || lv_line_feed;
      -- 項目数が同じ場合
      ELSE
        -- 項目チェック
        -- フォーマットパターンが「1」「2」「4」の場合
        IF ((iv_file_format = gv_format_code_01)
            OR (iv_file_format = gv_format_code_02)
            OR (iv_file_format = gv_format_code_04))
        THEN
          -- **************************************************
          -- *** 出荷倉庫
          -- **************************************************
          xxcmn_common3_pkg.upload_item_check(gv_location_code_n,
                                              fdata_tbl(ln_index).location_code,
                                              gv_location_code_l,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                 || lv_errmsg
                                                 || lv_line_feed;
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
        END IF;
--
        -- フォーマットパターンが「1」「2」「3」「5」の場合
        IF ((iv_file_format = gv_format_code_01)
            OR (iv_file_format = gv_format_code_02)
            OR (iv_file_format = gv_format_code_03)
            OR (iv_file_format = gv_format_code_05))
        THEN
          -- **************************************************
          -- *** 拠点
          -- **************************************************
          xxcmn_common3_pkg.upload_item_check(gv_base_code_n,
                                              fdata_tbl(ln_index).base_code,
                                              gv_base_code_l,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                 || lv_errmsg
                                                 || lv_line_feed;
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
        END IF;
--
        -- **************************************************
        -- *** 品目
        -- **************************************************
        xxcmn_common3_pkg.upload_item_check(gv_item_code_n,
                                            fdata_tbl(ln_index).item_code,
                                            gv_item_code_l,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ng,
                                            xxcmn_common3_pkg.gv_attr_vc2,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- 項目チェックエラー
        IF (lv_retcode = gv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                               || lv_errmsg
                                               || lv_line_feed;
        -- プロシージャー異常終了
        ELSIF (lv_retcode = gv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- **************************************************
        -- *** ケース数量
        -- **************************************************
        xxcmn_common3_pkg.upload_item_check(gv_case_quantity_n,
                                            fdata_tbl(ln_index).case_quantity,
                                            gv_case_quantity_l,
                                            0,
                                            xxcmn_common3_pkg.gv_null_ng,
                                            xxcmn_common3_pkg.gv_attr_num,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- 項目チェックエラー
        IF (lv_retcode = gv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                               || lv_errmsg
                                               || lv_line_feed;
        -- プロシージャー異常終了
        ELSIF (lv_retcode = gv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- **************************************************
        -- *** バラ数量
        -- **************************************************
        xxcmn_common3_pkg.upload_item_check(gv_indivi_quantity_n,
                                            fdata_tbl(ln_index).indivi_quantity,
                                            gv_indivi_quantity_l,
                                            0,
                                            xxcmn_common3_pkg.gv_null_ng,
                                            xxcmn_common3_pkg.gv_attr_num,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- 項目チェックエラー
        IF (lv_retcode = gv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                               || lv_errmsg
                                               || lv_line_feed;
        -- プロシージャー異常終了
        ELSIF (lv_retcode = gv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- **************************************************
        -- *** 開始日付
        -- **************************************************
        xxcmn_common3_pkg.upload_item_check(gv_forecast_date_n,
                                            fdata_tbl(ln_index).forecast_date,
                                            NULL,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ng,
                                            xxcmn_common3_pkg.gv_attr_dat,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- 項目チェックエラー
        IF (lv_retcode = gv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                               || lv_errmsg
                                               || lv_line_feed;
        -- プロシージャー異常終了
        ELSIF (lv_retcode = gv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- **************************************************
        -- *** 終了日付
        -- **************************************************
        xxcmn_common3_pkg.upload_item_check(gv_forecast_end_date_n,
                                            fdata_tbl(ln_index).forecast_end_date,
                                            NULL,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ng,
                                            xxcmn_common3_pkg.gv_attr_dat,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- 項目チェックエラー
        IF (lv_retcode = gv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                               || lv_errmsg
                                               || lv_line_feed;
        -- プロシージャー異常終了
        ELSIF (lv_retcode = gv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- フォーマットパターンが「4」の場合
        IF (iv_file_format = gv_format_code_04) THEN
          -- **************************************************
          -- *** 取込部署
          -- **************************************************
          xxcmn_common3_pkg.upload_item_check(gv_dept_code_n,
                                              fdata_tbl(ln_index).dept_code,
                                              gv_dept_code_l,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                 || lv_errmsg
                                                 || lv_line_feed;
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
        END IF;
--
        -- フォーマットパターンが「5」の場合
        IF (iv_file_format = gv_format_code_05) THEN
          -- **************************************************
          -- *** 金額
          -- **************************************************
          xxcmn_common3_pkg.upload_item_check(gv_amount_n,
                                              fdata_tbl(ln_index).amount,
                                              gv_amount_l,
                                              0,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_num,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                 || lv_errmsg
                                                 || lv_line_feed;
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
        END IF;
--
      END IF;
--
      -- **************************************************
      -- *** エラー制御
      -- **************************************************
      -- チェックエラーありの場合
      IF (fdata_tbl(ln_index).err_message IS NOT NULL) THEN
--
        -- **************************************************
        -- *** データ部出力準備（行数 + SPACE + 行全体のデータ）
        -- **************************************************
        lv_log_data := NULL;
        lv_log_data := TO_CHAR(ln_index,'99999') || gv_space || fdata_tbl(ln_index).line;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_log_data);
--
        -- エラーメッセージ部出力
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RTRIM(fdata_tbl(ln_index).err_message, lv_line_feed));
        -- 妥当性チェックステータス
        gv_check_proc_retcode := gv_status_error;
        -- エラー件数カウント
        gn_error_cnt := gn_error_cnt + 1;
--
      -- チェックエラーなしの場合
      ELSE
        -- 成功件数カウント
        gn_normal_cnt := gn_normal_cnt + 1;
      END IF;
--
    END LOOP check_loop;
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END check_proc;
--
  /**********************************************************************************
   * Procedure Name   : set_data_proc
   * Description      : 登録データ設定
   ***********************************************************************************/
  PROCEDURE set_data_proc(
    iv_file_format IN  VARCHAR2,     --   フォーマットパターン
    ov_errbuf      OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg      OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_data_proc'; -- プログラム名
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
    ln_forecast_if_id   NUMBER;   -- 取引ID
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- ローカル変数初期化
    ln_forecast_if_id := NULL;
--
    -- **************************************************
    -- *** 登録用PL/SQL表編集（2行目から）
    -- **************************************************
    <<fdata_loop>>
    FOR ln_index IN 1 .. fdata_tbl.LAST LOOP
--
      -- 取引ID採番
      SELECT xxinv_mrp_frcst_if_s1.NEXTVAL
      INTO   ln_forecast_if_id
      FROM   dual;
--
      -- 対象項目の格納
      -- 1.取引ID
      gt_forecast_if_id(ln_index)       := ln_forecast_if_id;
      -- 2.Forecast分類
      gt_forecast_designator(ln_index)  := gv_file_content_type;
      -- 3.出荷倉庫
      gt_location_code(ln_index)        := fdata_tbl(ln_index).location_code;
      -- 4.拠点
      gt_base_code(ln_index)            := fdata_tbl(ln_index).base_code;
--
      IF (iv_file_format = gv_format_code_04) THEN
        -- 5.取込部署
        gt_dept_code(ln_index)            := fdata_tbl(ln_index).dept_code;
      ELSE
        gt_dept_code(ln_index)            := gv_location_code;
      END IF;
--
      -- 6.品目
      gt_item_code(ln_index)            := fdata_tbl(ln_index).item_code;
      -- 7.開始日付
      gt_forecast_date(ln_index)
        := FND_DATE.STRING_TO_DATE(fdata_tbl(ln_index).forecast_date, 'RR/MM/DD');
      -- 8.終了日付
      gt_forecast_end_date(ln_index)
        := FND_DATE.STRING_TO_DATE(fdata_tbl(ln_index).forecast_end_date, 'RR/MM/DD');
      -- 9.ケース数量
      gt_case_quantity(ln_index)
        := TO_NUMBER(fdata_tbl(ln_index).case_quantity);
      -- 10.バラ数量
      gt_indivi_quantity(ln_index)      := TO_NUMBER(fdata_tbl(ln_index).indivi_quantity);
      -- 11.金額
      gt_amount(ln_index)               := TO_NUMBER(fdata_tbl(ln_index).amount);
--
    END LOOP fdata_loop;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END set_data_proc;
--
  /**********************************************************************************
   * Procedure Name   : insert_mrp_forecast_if
   * Description      : データ登録 (B-4)
   ***********************************************************************************/
  PROCEDURE insert_mrp_forecast_if(
    ov_errbuf    OUT NOCOPY VARCHAR2,   --   エラー・メッセージ           --# 固定 #
    ov_retcode   OUT NOCOPY VARCHAR2,   --   リターン・コード             --# 固定 #
    ov_errmsg    OUT NOCOPY VARCHAR2)   --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(30) := 'insert_mrp_forecast_if'; -- プログラム名
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- **************************************************
    -- *** 販売計画/引取計画インタフェーステーブル登録
    -- **************************************************
    FORALL item_cnt IN 1 .. gt_forecast_if_id.COUNT
      INSERT INTO xxinv_mrp_forecast_interface
      ( forecast_if_id                                  -- 取引ID
       ,forecast_designator                             -- Forecast分類
       ,location_code                                   -- 出荷倉庫
       ,base_code                                       -- 拠点
       ,dept_code                                       -- 取込部署
       ,item_code                                       -- 品目
       ,forecast_date                                   -- 開始日付
       ,forecast_end_date                               -- 終了日付
       ,case_quantity                                   -- ケース数量
       ,indivi_quantity                                 -- バラ数量
       ,amount                                          -- 金額
       ,created_by                                      -- 作成者
       ,creation_date                                   -- 作成日
       ,last_updated_by                                 -- 最終更新者
       ,last_update_date                                -- 最終更新日
       ,last_update_login                               -- 最終更新ログイン
       ,request_id                                      -- 要求ID
       ,program_application_id                          -- プログラムアプリケーションID
       ,program_id                                      -- プログラムID
       ,program_update_date                             -- プログラム更新日
      ) VALUES
      ( gt_forecast_if_id(item_cnt)                     -- 取引ID
       ,gt_forecast_designator(item_cnt)                -- Forecast分類
       ,gt_location_code(item_cnt)                      -- 出荷倉庫
       ,gt_base_code(item_cnt)                          -- 拠点
       ,gt_dept_code(item_cnt)                          -- 取込部署
       ,gt_item_code(item_cnt)                          -- 品目
       ,gt_forecast_date(item_cnt)                      -- 開始日付
       ,gt_forecast_end_date(item_cnt)                  -- 終了日付
       ,gt_case_quantity(item_cnt)                      -- ケース数量
       ,gt_indivi_quantity(item_cnt)                    -- バラ数量
       ,gt_amount(item_cnt)                             -- 金額
       ,gn_user_id                                      -- 作成者
       ,gd_sysdate                                      -- 作成日
       ,gn_user_id                                      -- 最終更新者
       ,gd_sysdate                                      -- 最終更新日
       ,gn_login_id                                     -- 最終更新ログイン
       ,gn_conc_request_id                              -- 要求ID
       ,gn_prog_appl_id                                 -- プログラムアプリケーションID
       ,gn_conc_program_id                              -- プログラムID
       ,gd_sysdate                                      -- プログラム更新日
      );
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END insert_mrp_forecast_if;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    in_file_id     IN  NUMBER,       --   FILE_ID
    iv_file_format IN  VARCHAR2,     --   フォーマットパターン
    ov_errbuf      OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg      OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_out_rep VARCHAR2(1000);  -- レポート出力
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- 妥当性チェックステータスの初期化
    gv_check_proc_retcode := gv_status_normal;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- パラメータチェック(B-1)
    -- ===============================
    check_param(
      iv_file_format,    -- フォーマットパターン
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 関連データ取得(B-2)
    -- ===============================
    init_proc(
      iv_file_format,    -- フォーマットパターン
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ファイルアップロードインタフェースデータ取得(B-3)
    -- ===============================
    get_upload_data_proc(
      in_file_id,        -- FILE_ID
      iv_file_format,    -- フォーマットパターン
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
--##############################  アップロード固定メッセージ START  ##############################
    --処理結果レポート出力（上部）
    -- ファイル名
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_c_msg_kbn, gv_c_msg_99b_101,
                                              gv_c_tkn_value, gv_file_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    -- アップロード日時
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_c_msg_kbn, gv_c_msg_99b_103,
                                              gv_c_tkn_value,
                                              TO_CHAR(gd_creation_date,'YYYY/MM/DD HH24:MI'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    -- ファイルアップロード名称
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_c_msg_kbn, gv_c_msg_99b_104,
                                              gv_c_tkn_value, gv_file_up_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    -- フォーマットパターン
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_c_msg_kbn, gv_c_msg_99b_106,
                                              gv_c_tkn_value, iv_file_format);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
--
--##############################  アップロード固定メッセージ END   ##############################
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
--
    -- 2008/07/08 Add ↓
    ELSIF (lv_retcode = gv_status_warn) THEN
      ov_retcode := lv_retcode;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      RETURN;
    -- 2008/07/08 Add ↑
    END IF;
--
    -- ===============================
    -- 妥当性チェック(B-4)
    -- ===============================
    check_proc(
      iv_file_format,    -- フォーマットパターン
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
--
    -- 妥当性チェックでエラーがなかった場合
    ELSIF (gv_check_proc_retcode = gv_status_normal) THEN
      -- ===============================
      -- 登録データセット
      -- ===============================
      set_data_proc(
        iv_file_format,    -- フォーマットパターン
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
      -- ===============================
      -- データ登録(B-5)
      -- ===============================
      insert_mrp_forecast_if(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ==================================================
    -- ファイルアップロードインタフェースデータ削除(B-6)
    -- ==================================================
    xxcmn_common3_pkg.delete_fileup_proc(
      iv_file_format,                 -- フォーマットパターン
      gd_sysdate,                     -- 対象日付
      gn_xxinv_parge_term,            -- パージ対象期間
      lv_errbuf,                      -- エラー・メッセージ           --# 固定 #
      lv_retcode,                     -- リターン・コード             --# 固定 #
      lv_errmsg);                     -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      -- 削除処理エラー時にRollBackをする為、妥当性チェックステータスを初期化
      gv_check_proc_retcode := gv_status_normal;
      RAISE global_process_expt;
    END IF;
--
    -- チェック処理エラー
    IF (gv_check_proc_retcode = gv_status_error) THEN
      -- 固定のエラーメッセージの出力をしないようにする
      lv_errmsg := gv_space;
      RAISE global_process_expt;
    END IF;
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
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
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
    errbuf         OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode        OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    in_file_id     IN  VARCHAR2,      --   1.FILE_ID 2008/04/18 変更
    iv_file_format IN  VARCHAR2       --   2.フォーマットパターン
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- ======================
    -- 固定出力用変数セット
    -- ======================
    --実行ユーザ名取得
    gv_exec_user := fnd_global.user_name;
    --実行コンカレント名取得
    SELECT fcp.concurrent_program_name
    INTO   gv_conc_name
    FROM   fnd_concurrent_programs fcp
    WHERE  fcp.application_id        = fnd_global.prog_appl_id
    AND    fcp.concurrent_program_id = fnd_global.conc_program_id
    AND    ROWNUM                    = 1;
--
    -- ======================
    -- 固定出力
    -- ======================
    --実行ユーザ名出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00001','USER',gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --実行コンカレント名出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00002','CONC',gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --起動時間出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118',
                                           'TIME', TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --区切り文字出力
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      TO_NUMBER(in_file_id),     -- FILE_ID 2008/04/18 変更
      iv_file_format, -- フォーマットパターン
      lv_errbuf,      -- エラー・メッセージ           --# 固定 #
      lv_retcode,     -- リターン・コード             --# 固定 #
      lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
--###########################  固定部 START   #####################################################
--
    -- ======================
    -- エラー・メッセージ出力
    -- ======================
    IF (lv_retcode = gv_status_error) THEN
      IF (lv_errmsg IS NULL) THEN
        --定型メッセージ・セット
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10030');
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
    -- ==================================
    -- リターン・コードのセット、終了処理
    -- ==================================
    --区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --処理件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00008','CNT',TO_CHAR(gn_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --成功件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --エラー件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00010','CNT',TO_CHAR(gn_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --スキップ件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00011','CNT',TO_CHAR(gn_warn_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --ステータス出力
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = userenv('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type, 
                                                                      flv.view_application_id)
    AND    flv.lookup_type         = 'CP_STATUS_CODE'
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            gv_status_normal,gv_sts_cd_normal,
                                            gv_status_warn,gv_sts_cd_warn,
                                            gv_sts_cd_error)
    AND    ROWNUM                  = 1;
--
    --処理ステータス出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00012','STATUS',gv_conc_status);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = gv_status_error) AND (gv_check_proc_retcode = gv_status_normal) THEN
      ROLLBACK;
    ELSE
      COMMIT;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END xxinv990001c;
/
