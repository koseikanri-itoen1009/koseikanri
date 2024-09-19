CREATE OR REPLACE PACKAGE BODY APPS.XXCMM002A15C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2024. All rights reserved.
 *
 * Package Name     : XXCMM002A15C(body)
 * Description      : 従業員の管理者、承認者範囲を更新します。
 * MD.050           : 管理者／承認者範囲アップロード (MD050_CMM_002_A15)
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_upload_if          ファイルアップロードIFデータ抽出(A-2)
 *  data_validation        データ妥当性チェック(A-3)
 *  upd_person_info        従業員情報更新(A-4)
 *  
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2024/09/11    1.0   M.Akachi         新規作成（E_本稼動_20141対応）
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
  gn_warn_cnt      NUMBER;                    -- 警告件数
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
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                       CONSTANT VARCHAR2(100) := 'XXCMM002A15C';      -- パッケージ名
--
  cv_app_name                       CONSTANT VARCHAR2(5)   := 'XXCMM';             -- アプリケーション短縮名
--
  --メッセージ
  cv_msg_cmm_00038                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00038';  -- パラメータ出力
  cv_msg_cmm_00018                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00018';  -- 業務処理日付取得エラー
  cv_msg_cmm_00021                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00021';  -- アップロードファイル名称
  cv_msg_cmm_00230                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00230';  -- データ抽出エラー（アップロードファイル名称）
  cv_msg_cmm_00022                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00022';  -- CSVファイル名
  cv_msg_cmm_00402                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00402';  -- ロックエラー
  cv_msg_cmm_00052                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00052';  -- データ抽出エラーメッセージ
  cv_msg_cmm_00418                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00418';  -- データ削除エラー
  cv_msg_cmm_00001                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00001';  -- 対象件数0件メッセージ
  cv_msg_cmm_00231                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00231';  -- データ項目数エラー
  cv_msg_cmm_00232                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00232';  -- ファイル項目必須チェックエラー
  cv_msg_cmm_00233                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00233';  -- ファイル項目存在チェックエラー
  cv_msg_cmm_00234                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00234';  -- 退職者チェックエラー
  cv_msg_cmm_00235                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00235';  -- 従業員重複チェック
  cv_msg_cmm_00236                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00236';  -- 従業員マスタロックエラーメッセージ
  cv_msg_cmm_10435                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-10435';  -- 更新エラー
  cv_msg_cmm_00244                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00244';  -- 退職者チェック（管理者）エラー
  --ノート
  cv_msg_cmm_00237                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00237';  -- ファイルID
  cv_msg_cmm_00238                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00238';  -- 従業員番号
  cv_msg_cmm_00239                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00239';  -- 管理者
  cv_msg_cmm_00240                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00240';  -- 承認者範囲
  cv_msg_cmm_00241                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00241';  -- 従業員マスタ
  cv_msg_cmm_00242                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00242';  -- アサイメントマスタ
  cv_msg_cmm_00243                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00243';  -- AFF部門マスタ
  cv_msg_cmm_30400                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-30400';  -- フォーマットパターン
  cv_msg_cmm_30404                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-30404';  -- ファイルアップロードIF
  --トークン
  cv_tkn_param                      CONSTANT VARCHAR2(30)  := 'PARAM';
  cv_tkn_value                      CONSTANT VARCHAR2(30)  := 'VALUE';
  cv_tkn_upload_name                CONSTANT VARCHAR2(30)  := 'UPLOAD_NAME';
  cv_tkn_file_name                  CONSTANT VARCHAR2(30)  := 'FILE_NAME';
  cv_tkn_err_msg                    CONSTANT VARCHAR2(20)  := 'ERR_MSG';
  cv_tkn_errmsg                     CONSTANT VARCHAR2(20)  := 'ERRMSG';
  cv_tkn_table                      CONSTANT VARCHAR2(20)  := 'TABLE';
  cv_tkn_count                      CONSTANT VARCHAR2(30)  := 'COUNT';
  cv_tkn_item                       CONSTANT VARCHAR2(30)  := 'ITEM';
  cv_tkn_item_val                   CONSTANT VARCHAR2(30)  := 'ITEM_VAL';
  cv_tkn_input_line_no              CONSTANT VARCHAR2(20)  := 'INPUT_LINE_NO';
  cv_tkn_key_data                   CONSTANT VARCHAR2(20)  := 'KEY_DATA';
--
  -- 参照タイプ
  cv_lkup_file_ul_obj               CONSTANT VARCHAR2(50)  := 'XXCCP1_FILE_UPLOAD_OBJ';  -- ファイルアップロードOBJ
--
  -- CSV関連
  cn_col_employee_number            CONSTANT NUMBER        := 1;   -- 従業員番号
  cn_col_supervisor_num             CONSTANT NUMBER        := 2;   -- 管理者番号
  cn_col_location_code              CONSTANT NUMBER        := 3;   -- 承認者範囲
  cn_csv_file_col_num               CONSTANT NUMBER        := 3;   -- CSVファイル項目数
  cv_col_separator                  CONSTANT VARCHAR2(1)   := ','; -- 項目区切文字
  cv_dqu                            CONSTANT VARCHAR2(1)   := '"'; -- 文字列括り
--
  -- その他
  cv_yes                            CONSTANT VARCHAR2(1)   := 'Y'; -- 汎用Y
  cv_no                             CONSTANT VARCHAR2(1)   := 'N'; -- 汎用N
  cv_dept_status_2                  CONSTANT VARCHAR2(1)   := '2'; -- 部門階層一時ワークの処理区分 '2'（部門）
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- アップロードデータ分割取得用
  TYPE gt_col_data_rec    IS TABLE OF VARCHAR(2000)   INDEX BY BINARY_INTEGER; -- 1次元配列
  TYPE gt_rec_data_ttype  IS TABLE OF gt_col_data_rec INDEX BY BINARY_INTEGER; -- 2次元配列
  g_sep_data_tab          gt_rec_data_ttype; -- 分割データ格納用配列
  -- 従業員番号重複チェック用
  TYPE g_employee_number_ttype   IS TABLE OF per_all_people_f.employee_number%TYPE INDEX BY VARCHAR2(30); -- 1次元配列
  g_chk_employee_number_tab      g_employee_number_ttype;  -- 従業員番号格納用配列
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_process_date         DATE;    -- 業務処理日付
  gt_person_type_id       per_person_types.person_type_id%TYPE; -- パーソンタイプID
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     in_file_id    IN  NUMBER       -- ファイルID
    ,iv_fmt_ptn    IN  VARCHAR2     -- フォーマットパターン
    ,ov_errbuf     OUT VARCHAR2     -- エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT VARCHAR2     -- リターン・コード             --# 固定 #
    ,ov_errmsg     OUT VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
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
    lv_user_person_type_ex       CONSTANT VARCHAR2(10) := '退職者';
--
    -- *** ローカル変数 ***
    lv_msg           VARCHAR2(5000);                             -- メッセージ出力用
    lt_file_ul_name  fnd_lookup_values_vl.meaning%TYPE;          -- ファイルアップロード名称
    lt_file_name     xxccp_mrp_file_ul_interface.file_name%TYPE; -- ファイル名
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
    -- ローカル変数初期化
    lv_msg          := NULL;
    lt_file_ul_name := NULL;
    lt_file_name    := NULL;
--
    --=========================================
    -- 入力パラメータ出力
    --=========================================
    -- ファイルID
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_app_name
               ,iv_name         => cv_msg_cmm_00038  -- パラメータ出力
               ,iv_token_name1  => cv_tkn_param
               ,iv_token_value1 => cv_msg_cmm_00237  -- ファイルID
               ,iv_token_name2  => cv_tkn_value
               ,iv_token_value2 => TO_CHAR(in_file_id)
              );
    -- ファイルIDメッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg
    );
    -- フォーマットパターン
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_app_name
               ,iv_name         => cv_msg_cmm_00038  -- パラメータ出力
               ,iv_token_name1  => cv_tkn_param
               ,iv_token_value1 => cv_msg_cmm_30400  -- フォーマットパターン
               ,iv_token_name2  => cv_tkn_value
               ,iv_token_value2 => iv_fmt_ptn
              );
    -- フォーマットパターンメッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --=========================================
    -- 業務処理日付取得
    --=========================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- 取得できなかった場合
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_msg_cmm_00018 --業務処理日付取得エラー
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --=========================================
    -- アップロードファイル名称取得
    --=========================================
    BEGIN
      SELECT flv.meaning  AS meaning                -- アップロードファイル名称
      INTO   lt_file_ul_name
      FROM   fnd_lookup_values_vl flv               -- クイックコード
      WHERE  flv.lookup_type  = cv_lkup_file_ul_obj -- タイプ
      AND    flv.lookup_code  = iv_fmt_ptn          -- コード
      AND    flv.enabled_flag = cv_yes              -- 有効フラグ
      AND    gd_process_date  BETWEEN TRUNC(flv.start_date_active)
                              AND     NVL(flv.end_date_active, gd_process_date) -- 有効日付
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- データ抽出エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_msg_cmm_00230
                      ,iv_token_name1  => cv_tkn_key_data
                      ,iv_token_value1 => iv_fmt_ptn
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ファイルアップロード名称ノート
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_app_name
               ,iv_name         => cv_msg_cmm_00021
               ,iv_token_name1  => cv_tkn_upload_name
               ,iv_token_value1 => lt_file_ul_name
              );
    -- ファイルアップロード名称メッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg
    );
--
    --=========================================
    -- ファイル名取得
    --=========================================
    BEGIN
      SELECT xmfui.file_name AS file_name          -- ファイル名
      INTO   lt_file_name
      FROM   xxccp_mrp_file_ul_interface xmfui     -- ファイルアップロードIF
      WHERE  xmfui.file_id = in_file_id            -- ファイルID
      FOR UPDATE NOWAIT ;
      -- CSVファイル名メッセージ
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name
                 ,iv_name         => cv_msg_cmm_00022 -- CSVファイル名
                 ,iv_token_name1  => cv_tkn_file_name
                 ,iv_token_value1 => lt_file_name
                );
      -- CSVファイル名メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_msg
      );
      -- 空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
    EXCEPTION
      WHEN global_lock_expt THEN
        -- ロックエラー時
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_msg_cmm_00402  -- ロックエラー
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --=========================================
    -- パーソンタイプ取得
    --=========================================
    BEGIN
      SELECT ppt.person_type_id AS person_type_id
      INTO   gt_person_type_id
      FROM   per_person_types ppt     -- パーソンタイプマスタ
      WHERE  ppt.user_person_type = lv_user_person_type_ex -- 退職者
      AND    ROWNUM = 1;
    EXCEPTION
      -- データなしの場合も継続
      WHEN NO_DATA_FOUND THEN
        gt_person_type_id    := NULL;
      --
      WHEN OTHERS THEN
        RAISE global_process_expt;
    END;
--
    --=========================================
    -- 部門階層一時ワーク登録
    --=========================================
    INSERT INTO xxcmm_wk_hiera_dept(
      cur_dpt_cd
     ,dpt1_cd
     ,dpt2_cd
     ,dpt3_cd
     ,dpt4_cd
     ,dpt5_cd
     ,dpt6_cd
     ,process_kbn
    )
      SELECT  xhd.cur_dpt_cd,        -- 最下層部門コード
              NULL,                  -- １階層目部門コード
              NULL,                  -- ２階層目部門コード
              NULL,                  -- ３階層目部門コード
              NULL,                  -- ４階層目部門コード
              NULL,                  -- ５階層目部門コード
              NULL,                  -- ６階層目部門コード
              cv_dept_status_2       -- 処理区分(1：全部門、2：部門)
      FROM    xxcmm_hierarchy_dept_v xhd
    ;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理エラー例外 ***
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
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_upload_if
   * Description      : ファイルアップロードIFデータ抽出(A-2)
   ***********************************************************************************/
  PROCEDURE get_upload_if(
     in_file_id      IN  NUMBER            -- ファイルID
    ,ov_errbuf       OUT VARCHAR2          -- エラー・メッセージ           --# 固定 #
    ,ov_retcode      OUT VARCHAR2          -- リターン・コード             --# 固定 #
    ,ov_errmsg       OUT VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_upload_if'; -- プログラム名
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
    ln_line_cnt          NUMBER;
    ln_col_num           NUMBER;
    ln_column_cnt        NUMBER;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル・テーブル ***
    l_file_data_tab     xxccp_common_pkg2.g_file_data_tbl;  -- 行単位データ格納用配列
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --=========================================
    -- BLOBデータ変換関数により行単位データを抽出
    --=========================================
    xxccp_common_pkg2.blob_to_varchar2(
       in_file_id   => in_file_id       -- ファイルID
      ,ov_file_data => l_file_data_tab  -- ファイルデータ
      ,ov_errbuf    => lv_errbuf        -- エラー・メッセージ            -- # 固定 #
      ,ov_retcode   => lv_retcode       -- リターン・コード              -- # 固定 #
      ,ov_errmsg    => lv_errmsg        -- ユーザー・エラー・メッセージ  -- # 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      -- リターンコードがエラーの場合
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_msg_cmm_00052 -- データ抽出エラーメッセージ
                    ,iv_token_name1  => cv_tkn_table
                    ,iv_token_value1 => cv_msg_cmm_30404 -- ファイルアップロードIF
                    ,iv_token_name2  => cv_tkn_err_msg
                    ,iv_token_value2 => lv_errbuf
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --=========================================
    -- ファイルアップロードIF削除
    --=========================================
    BEGIN
      DELETE FROM xxccp_mrp_file_ul_interface xmfui -- ファイルアップロードIF
      WHERE xmfui.file_id = in_file_id              -- ファイルID
      ;
      COMMIT;
    EXCEPTION
      WHEN OTHERS THEN
        -- エラーが発生した場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_msg_cmm_00418 -- データ削除エラーメッセージ
                      ,iv_token_name1  => cv_tkn_table
                      ,iv_token_value1 => cv_msg_cmm_30404 -- ファイルアップロードIF
                      ,iv_token_name2  => cv_tkn_err_msg
                      ,iv_token_value2 => SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --=========================================
    -- 取得したデータが1件（ヘッダのみ）の場合
    --=========================================
    IF (l_file_data_tab.COUNT - 1 <= 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_msg_cmm_00001 -- 対象件数0件メッセージ
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --対象件数の取得
    gn_target_cnt := l_file_data_tab.COUNT - 1;
--
    --=========================================
    -- 項目数のチェック
    --=========================================
    <<line_data_loop>>
    FOR ln_line_cnt IN 2 .. l_file_data_tab.COUNT LOOP
      --項目数取得(区切り文字の数で判定)
      ln_col_num := NVL(LENGTH(l_file_data_tab(ln_line_cnt)), 0)
                      - NVL(LENGTH(REPLACE(l_file_data_tab(ln_line_cnt), cv_col_separator, NULL)), 0) + 1;
      --項目数チェック
      IF (ln_col_num <> cn_csv_file_col_num) THEN
        -- 項目数が異なる場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_msg_cmm_00231 -- データ項目数エラー
                      ,iv_token_name1  => cv_tkn_input_line_no
                      ,iv_token_value1 => TO_CHAR(ln_line_cnt - 1)
                      ,iv_token_name2  => cv_tkn_count
                      ,iv_token_value2 => TO_CHAR(ln_col_num)
                     );
        --メッセージ出力
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode  := cv_status_warn;
        gn_warn_cnt := gn_warn_cnt + 1;
      ELSE
        -- 項目分割（ヘッダ行は除く）
        <<col_sep_loop>>
        FOR ln_column_cnt IN 1 .. cn_csv_file_col_num LOOP
          g_sep_data_tab(ln_line_cnt - 1)(ln_column_cnt) := REPLACE(xxccp_common_pkg.char_delim_partition(
                                                          iv_char     => l_file_data_tab(ln_line_cnt)
                                                         ,iv_delim    => cv_col_separator
                                                         ,in_part_num => ln_column_cnt
                                                        ), cv_dqu, NULL);
        END LOOP col_sep_loop;
      END IF;
    END LOOP line_data_loop;
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
  END get_upload_if;
--
  /**********************************************************************************
   * Procedure Name   : data_validation
   * Description      : データ妥当性チェック(A-3)
   ***********************************************************************************/
  PROCEDURE data_validation(
     iv_employee_number IN  VARCHAR2       -- 従業員番号
    ,iv_supervisor_num  IN  VARCHAR2       -- 管理者番号
    ,iv_location_code   IN  VARCHAR2       -- 承認者範囲
    ,in_loop_cnt        IN  NUMBER         -- ループカウンタ
    ,ov_errbuf          OUT VARCHAR2       -- エラー・メッセージ           --# 固定 #
    ,ov_retcode         OUT VARCHAR2       -- リターン・コード             --# 固定 #
    ,ov_errmsg          OUT VARCHAR2)      -- ユーザー・エラー・メッセージ --# 固定 #
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
    ln_cnt                    NUMBER;                                 -- カウント用
    lt_person_type_id         per_all_people_f.person_type_id%TYPE;   -- パーソンタイプ（従業員）
    lt_person_type_id_sup     per_all_people_f.person_type_id%TYPE;   -- パーソンタイプ（管理者）

--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル・テーブル ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ローカル変数初期化
    ln_cnt                    := 0;
    lt_person_type_id         := NULL; -- パーソンタイプ（従業員）
    lt_person_type_id_sup     := NULL; -- パーソンタイプ（管理者）
--
    --=========================================
    -- 従業員番号必須チェック
    --=========================================
    IF ( iv_employee_number IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_msg_cmm_00232     -- ファイル項目必須チェックエラー
                    ,iv_token_name1  => cv_tkn_item
                    ,iv_token_value1 => cv_msg_cmm_00238     -- 従業員番号
                    ,iv_token_name2  => cv_tkn_input_line_no
                    ,iv_token_value2 => TO_CHAR(in_loop_cnt) -- 行番号
                   );
      -- 警告メッセージ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      -- ステータスを警告に設定
      ov_retcode := cv_status_warn;
    END IF;
--
    -- 上記でエラーが発生していない場合
    IF ( ov_retcode <> cv_status_warn ) THEN
      --=========================================
      -- 従業員存在チェック
      --=========================================
      SELECT COUNT(1)
      INTO   ln_cnt
      FROM   per_all_people_f papf  -- 従業員マスタ
      WHERE  papf.employee_number = iv_employee_number -- 従業員番号
      AND    papf.current_emp_or_apl_flag = cv_yes     --  履歴フラグ
      AND    ROWNUM = 1;
--
      IF ( ln_cnt = 0 ) THEN
        -- 取得できなかった場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_msg_cmm_00233     -- ファイル項目存在チェックエラー
                      ,iv_token_name1  => cv_tkn_item
                      ,iv_token_value1 => cv_msg_cmm_00238     -- 従業員番号
                      ,iv_token_name2  => cv_tkn_item_val
                      ,iv_token_value2 => iv_employee_number   -- 従業員番号
                      ,iv_token_name3  => cv_tkn_table
                      ,iv_token_value3 => cv_msg_cmm_00241     -- 従業員マスタ
                      ,iv_token_name4  => cv_tkn_input_line_no
                      ,iv_token_value4 => TO_CHAR(in_loop_cnt) -- 行番号
                     );
        -- 警告メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        -- ステータスを警告に設定
        ov_retcode := cv_status_warn;
      END IF;
    END IF;
--
    -- エラーが発生していない場合
    IF ( ov_retcode <> cv_status_warn ) THEN
      --=========================================
      -- 退職者チェック
      --=========================================
      BEGIN
        SELECT papf.person_type_id AS person_type_id
        INTO   lt_person_type_id
        FROM   per_all_people_f papf  -- 従業員マスタ
              ,( SELECT  papf2.person_id                 AS person_id
                        ,MAX(papf2.effective_start_date) AS effective_start_date
                 FROM    per_all_people_f  papf2
                 WHERE   papf2.employee_number = iv_employee_number
                 GROUP BY papf2.person_id
               ) sub
        WHERE  sub.person_id            = papf.person_id
        AND    sub.effective_start_date = papf.effective_start_date
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- 取得できなかった場合
          lt_person_type_id := NULL;
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
      -- 退職者の場合エラー
      IF ( lt_person_type_id = gt_person_type_id ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name
                        ,iv_name         => cv_msg_cmm_00234     -- 退職者チェックエラー
                        ,iv_token_name1  => cv_tkn_input_line_no
                        ,iv_token_value1 => TO_CHAR(in_loop_cnt) -- 行番号
                        ,iv_token_name2  => cv_tkn_item_val
                        ,iv_token_value2 => iv_employee_number   -- 従業員番号
                       );
          -- 警告メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          -- ステータスを警告に設定
          ov_retcode := cv_status_warn;
      END IF;
    END IF;
--
    -- 管理者が設定されている場合
    IF ( iv_supervisor_num IS NOT NULL ) THEN
    --=========================================
    -- 管理者存在チェック
    --=========================================
      SELECT COUNT(1)
      INTO   ln_cnt
      FROM   per_all_people_f papf  -- 従業員マスタ
      WHERE  papf.employee_number = iv_supervisor_num  -- 管理者番号
      AND    papf.current_emp_or_apl_flag = cv_yes     -- 履歴フラグ
      AND    ROWNUM = 1;
--
      IF ( ln_cnt = 0 ) THEN
        -- 取得できなかった場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_msg_cmm_00233     -- ファイル項目存在チェックエラー
                      ,iv_token_name1  => cv_tkn_item
                      ,iv_token_value1 => cv_msg_cmm_00239     -- 管理者番号
                      ,iv_token_name2  => cv_tkn_item_val
                      ,iv_token_value2 => iv_supervisor_num    -- 管理者番号
                      ,iv_token_name3  => cv_tkn_table
                      ,iv_token_value3 => cv_msg_cmm_00241     -- 従業員マスタ
                      ,iv_token_name4  => cv_tkn_input_line_no
                      ,iv_token_value4 => TO_CHAR(in_loop_cnt) -- 行番号
                     );
        -- 警告メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        -- ステータスを警告に設定
        ov_retcode := cv_status_warn;
      ELSE
        --=========================================
        -- 退職者チェック（管理者）
        --=========================================
        BEGIN
          SELECT papf.person_type_id AS person_type_id
          INTO   lt_person_type_id_sup
          FROM   per_all_people_f papf  -- 従業員マスタ
                ,( SELECT  papf2.person_id                 AS person_id
                          ,MAX(papf2.effective_start_date) AS effective_start_date
                   FROM    per_all_people_f  papf2
                   WHERE   papf2.employee_number = iv_supervisor_num
                   GROUP BY papf2.person_id
                 ) sub
          WHERE  sub.person_id            = papf.person_id
          AND    sub.effective_start_date = papf.effective_start_date
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- 取得できなかった場合
            lt_person_type_id_sup := NULL;
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
        -- 退職者の場合エラー
        IF ( lt_person_type_id_sup = gt_person_type_id ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name
                          ,iv_name         => cv_msg_cmm_00244     -- 退職者チェック（管理者）エラー
                          ,iv_token_name1  => cv_tkn_input_line_no
                          ,iv_token_value1 => TO_CHAR(in_loop_cnt) -- 行番号
                          ,iv_token_name2  => cv_tkn_item_val
                          ,iv_token_value2 => iv_supervisor_num    -- 管理者番号
                         );
            -- 警告メッセージ出力
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
            -- ステータスを警告に設定
            ov_retcode := cv_status_warn;
        END IF;
      END IF;
    END IF;
--
    -- 承認者範囲が設定されている場合
    IF ( iv_location_code IS NOT NULL ) THEN
    --=========================================
    -- 承認者範囲存在チェック
    --=========================================
      SELECT COUNT(1)
      INTO   ln_cnt
      FROM   xxcmm_wk_hiera_dept xwhd
      WHERE  xwhd.cur_dpt_cd  = iv_location_code  -- 最下層部門コード
      AND    xwhd.process_kbn = cv_dept_status_2  -- 処理区分(2：部門)
      AND    ROWNUM = 1;
--
      IF ( ln_cnt = 0 ) THEN
        -- 取得できなかった場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_msg_cmm_00233     -- ファイル項目存在チェックエラー
                      ,iv_token_name1  => cv_tkn_item
                      ,iv_token_value1 => cv_msg_cmm_00240     -- 承認者範囲
                      ,iv_token_name2  => cv_tkn_item_val
                      ,iv_token_value2 => iv_location_code     -- 承認者範囲
                      ,iv_token_name3  => cv_tkn_table
                      ,iv_token_value3 => cv_msg_cmm_00243     -- AFF部門マスタ
                      ,iv_token_name4  => cv_tkn_input_line_no
                      ,iv_token_value4 => TO_CHAR(in_loop_cnt) -- 行番号
                     );
        -- 警告メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        -- ステータスを警告に設定
        ov_retcode := cv_status_warn;
      END IF;
    END IF;
--
    --=========================================
    -- 従業員重複チェック
    --=========================================
    IF ( iv_employee_number IS NOT NULL ) THEN
      IF ( g_chk_employee_number_tab.EXISTS(iv_employee_number) = FALSE ) THEN
        g_chk_employee_number_tab(iv_employee_number) := iv_employee_number;
      ELSE
        -- 従業員重複チェックエラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_msg_cmm_00235   -- 従業員重複チェックエラー
                      ,iv_token_name1  => cv_tkn_item_val
                      ,iv_token_value1 => iv_employee_number -- 従業員番号
                     );
        -- 警告メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        -- ステータスを警告に設定
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
  END data_validation;
--
  /**********************************************************************************
   * Procedure Name   : upd_person_info
   * Description      : 従業員情報更新(A-4)
   ***********************************************************************************/
  PROCEDURE upd_person_info(
     iv_employee_number IN  VARCHAR2       -- 従業員番号
    ,iv_supervisor_num  IN  VARCHAR2       -- 管理者番号
    ,iv_location_code   IN  VARCHAR2       -- 承認者範囲
    ,ov_errbuf          OUT VARCHAR2       -- エラー・メッセージ           --# 固定 #
    ,ov_retcode         OUT VARCHAR2       -- リターン・コード             --# 固定 #
    ,ov_errmsg          OUT VARCHAR2)      -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_person_info'; -- プログラム名
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
    lv_date_time_format      CONSTANT VARCHAR2(30)   := 'YYYY/MM/DD HH24:MI:SS'; 
    -- *** ローカル変数 ***
    lt_person_id             per_all_people_f.person_id%TYPE;             -- 従業員ID
    lt_effective_start_date  per_all_people_f.effective_start_date%TYPE;  -- 登録年月日
    lt_effective_end_date    per_all_people_f.effective_end_date%TYPE;    -- 登録期限年月日
    lt_assignment_id         per_all_assignments_f.assignment_id%TYPE;    -- アサインメントID
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --=========================================
    -- 従業員ロック取得
    --=========================================
    BEGIN
      SELECT papf.person_id              AS  person_id             -- パーソンID
            ,papf.effective_start_date   AS  effective_start_date  -- 登録年月日
            ,papf.effective_end_date     AS  effective_end_date    -- 登録期限年月日
            ,paaf.assignment_id          AS  assignment_id         -- アサインメントID
      INTO   lt_person_id
            ,lt_effective_start_date
            ,lt_effective_end_date
            ,lt_assignment_id
      FROM   per_all_people_f       papf                           -- 従業員マスタ
            ,per_all_assignments_f  paaf                           -- アサインメントマスタ
            ,( SELECT papf2.person_id                 AS person_id
                     ,MAX(papf2.effective_start_date) AS effective_start_date
               FROM   per_all_people_f  papf2
               WHERE  papf2.current_emp_or_apl_flag = cv_yes
               AND    papf2.employee_number = iv_employee_number
               GROUP BY papf2.person_id
             ) sub
      WHERE  sub.person_id = papf.person_id
      AND    sub.effective_start_date  = papf.effective_start_date
      AND    papf.person_id            = paaf.person_id
      AND    papf.effective_start_date = paaf.effective_start_date
      FOR UPDATE OF papf.person_id
                   ,paaf.assignment_id NOWAIT
      ;
    EXCEPTION
      WHEN global_lock_expt THEN
        -- ロックエラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_msg_cmm_00236    -- 従業員マスタロックエラー
                      ,iv_token_name1  => cv_tkn_item_val
                      ,iv_token_value1 => iv_employee_number  -- 従業員番号
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --=========================================
    -- 管理者更新
    --=========================================
    IF ( iv_supervisor_num IS NOT NULL ) THEN
      BEGIN
        UPDATE per_all_assignments_f
        SET    supervisor_id        = ( SELECT papf.person_id
                                        FROM   per_all_people_f  papf
                                        WHERE  papf.employee_number = iv_supervisor_num
                                        AND    ROWNUM = 1 )
              ,ass_attribute19      = TO_CHAR(cd_last_update_date, lv_date_time_format)
        WHERE  assignment_id        = lt_assignment_id         -- アサインメントID
        AND    effective_start_date = lt_effective_start_date  -- 登録年月日
        AND    effective_end_date   = lt_effective_end_date    -- 登録期限年月日
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name
                        ,iv_name         => cv_msg_cmm_10435  -- 更新エラー
                        ,iv_token_name1  => cv_tkn_table
                        ,iv_token_value1 => cv_msg_cmm_00242  -- アサインメントマスタ
                        ,iv_token_name2  => cv_tkn_errmsg
                        ,iv_token_value2 => SQLERRM
                       );
          lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END;
    END IF;
--
    --=========================================
    -- 承認者範囲更新
    --=========================================
    IF ( iv_location_code IS NOT NULL ) THEN
      BEGIN
        UPDATE per_all_people_f
        SET    attribute30          = iv_location_code
              ,attribute23          = TO_CHAR(cd_last_update_date, lv_date_time_format)
        WHERE  person_id            = lt_person_id             --従業員ID
        AND    effective_start_date = lt_effective_start_date  --登録年月日
        AND    effective_end_date   = lt_effective_end_date    --登録期限年月日
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name
                        ,iv_name         => cv_msg_cmm_10435  -- 更新エラー
                        ,iv_token_name1  => cv_tkn_table
                        ,iv_token_value1 => cv_msg_cmm_00241  -- 従業員マスタ
                        ,iv_token_name2  => cv_tkn_errmsg
                        ,iv_token_value2 => SQLERRM
                       );
          lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END;
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
  END upd_person_info;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
     in_file_id    IN  NUMBER       -- ファイルID
    ,iv_fmt_ptn    IN  VARCHAR2     -- フォーマットパターン
    ,ov_errbuf     OUT VARCHAR2     -- エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT VARCHAR2     -- リターン・コード             --# 固定 #
    ,ov_errmsg     OUT VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- *** ローカル・テーブル ***
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
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    init(
       in_file_id => in_file_id     -- ファイルID
      ,iv_fmt_ptn => iv_fmt_ptn     -- フォーマットパターン
      ,ov_errbuf  => lv_errbuf      -- エラー・メッセージ           --# 固定 #
      ,ov_retcode => lv_retcode     -- リターン・コード             --# 固定 #
      ,ov_errmsg  => lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      --==================================
      -- ファイルアップロードIFデータ削除処理
      --==================================
      BEGIN
        DELETE FROM xxccp_mrp_file_ul_interface xmfui -- ファイルアップロードIF
        WHERE xmfui.file_id = in_file_id          -- ファイルID
        ;
        COMMIT;
      EXCEPTION
        WHEN OTHERS THEN
          -- エラーが発生した場合
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name
                        ,iv_name         => cv_msg_cmm_00418 -- データ削除エラーメッセージ
                        ,iv_token_name1  => cv_tkn_table
                        ,iv_token_value1 => cv_msg_cmm_30404 -- ファイルアップロードIF
                        ,iv_token_name2  => cv_tkn_err_msg
                        ,iv_token_value2 => SQLERRM
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
--
      RAISE global_process_expt;
    END IF;
--
    -- =====================================
    -- ファイルアップロードIFデータ抽出(A-2)
    -- =====================================
    get_upload_if(
       in_file_id      => in_file_id        -- ファイルID
      ,ov_errbuf       => lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode            -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      -- 終了ステータス：警告
      ov_retcode := lv_retcode;
    END IF;
--
    -- エラーが発生していない場合
    IF ( ov_retcode = cv_status_normal ) THEN
        -- 妥当性チェックループ
        <<validation_loop>>
        FOR ln_loop_cnt IN g_sep_data_tab.FIRST .. g_sep_data_tab.LAST LOOP
--
          -- ===============================
          -- データ妥当性チェック(A-3)
          -- ===============================
          data_validation(
             iv_employee_number => g_sep_data_tab(ln_loop_cnt)(cn_col_employee_number) -- 従業員番号
            ,iv_supervisor_num  => g_sep_data_tab(ln_loop_cnt)(cn_col_supervisor_num)  -- 管理者番号
            ,iv_location_code   => g_sep_data_tab(ln_loop_cnt)(cn_col_location_code)   -- 承認者範囲
            ,in_loop_cnt        => ln_loop_cnt    -- ループカウンタ
            ,ov_errbuf          => lv_errbuf      -- エラー・メッセージ           --# 固定 #
            ,ov_retcode         => lv_retcode     -- リターン・コード             --# 固定 #
            ,ov_errmsg          => lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
          );
--
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          ELSIF (lv_retcode = cv_status_warn) THEN
            -- 警告件数カウント
            gn_warn_cnt := gn_warn_cnt + 1;
            -- 終了ステータス：警告
            ov_retcode := lv_retcode;
          END IF;
--
        END LOOP validation_loop;
--
        -- エラーが発生していない場合
        IF ( ov_retcode = cv_status_normal ) THEN
          -- 従業員更新ループ
          <<upd_person_info_loop>>
          FOR ln_loop_cnt IN g_sep_data_tab.FIRST .. g_sep_data_tab.LAST LOOP
--
            -- ===============================
            -- 従業員情報更新(A-4)
            -- ===============================
            upd_person_info(
               iv_employee_number => g_sep_data_tab(ln_loop_cnt)(cn_col_employee_number) -- 従業員番号
              ,iv_supervisor_num  => g_sep_data_tab(ln_loop_cnt)(cn_col_supervisor_num)  -- 管理者番号
              ,iv_location_code   => g_sep_data_tab(ln_loop_cnt)(cn_col_location_code)   -- 承認者範囲
              ,ov_errbuf          => lv_errbuf          -- エラー・メッセージ           --# 固定 #
              ,ov_retcode         => lv_retcode         -- リターン・コード             --# 固定 #
              ,ov_errmsg          => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
            );
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--
            -- 成功件数設定
            gn_normal_cnt := gn_normal_cnt + 1;
--
          END LOOP upd_person_info_loop;
--
        END IF;
--
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
     errbuf            OUT VARCHAR2      -- エラー・メッセージ  --# 固定 #
    ,retcode           OUT VARCHAR2      -- リターン・コード    --# 固定 #
    ,in_get_file_id    IN  NUMBER        -- ファイルID
    ,iv_get_format_pat IN  VARCHAR2)     -- フォーマットパターン
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
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    cv_warn_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00001'; -- 警告件数メッセージ
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
       in_file_id => in_get_file_id    -- ファイルID
      ,iv_fmt_ptn => iv_get_format_pat -- フォーマットパターン
      ,ov_errbuf  => lv_errbuf    -- エラー・メッセージ           --# 固定 #
      ,ov_retcode => lv_retcode   -- リターン・コード             --# 固定 #
      ,ov_errmsg  => lv_errmsg    -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー終了の場合
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
      -- 件数初期化
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_warn_cnt   := 0;
      -- エラー件数の取得
      gn_error_cnt  := 1;
    END IF;
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
    --警告件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_warn_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
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
    --終了ステータスが正常の場合はCOMMIT、正常以外はROLLBACK
    IF (retcode = cv_status_normal) THEN
      COMMIT;
    ELSE
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
END XXCMM002A15C;
/
