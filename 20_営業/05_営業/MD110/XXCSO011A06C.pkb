CREATE OR REPLACE PACKAGE BODY APPS.XXCSO011A06C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCSO011A06C(body)
 * Description      : 物件を廃棄の状態に更新します。
 * MD.050           : 廃棄申請CSVアップロード (MD050_CSO_011A06)
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_upload_if          ファイルアップロードIFデータ抽出(A-2)
 *  delete_upload_if       ファイルアップロードIFデータ削除(A-3)
 *  proc_kbn_check         処理区分チェック(A-4)
 *  data_validation        データ妥当性チェック(A-5)
 *  upd_install_info       物件情報更新(A-6)
 *  ins_bulk_disp_proc     一括廃棄連携対象テーブル登録(A-7)
 *  
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2015/08/20    1.0   S.Yamashita      新規作成
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
  cv_pkg_name                       CONSTANT VARCHAR2(100) := 'XXCSO011A06C';      -- パッケージ名
--
  cv_app_name                       CONSTANT VARCHAR2(5)   := 'XXCSO';             -- アプリケーション短縮名
--
  --メッセージ
  cv_msg_cso_00496                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00496';  -- パラメータ出力
  cv_msg_cso_00011                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00011';  -- 業務処理日付取得エラー
  cv_msg_cso_00276                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00276';  -- アップロードファイル名称
  cv_msg_cso_00274                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00274';  -- データ抽出エラー（アップロードファイル名称）
  cv_msg_cso_00152                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00152';  -- CSVファイル名
  cv_msg_cso_00278                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00278';  -- ロックエラー
  cv_msg_cso_00342                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00342';  -- 取引タイプIDなしエラーメッセージ
  cv_msg_cso_00103                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00103';  -- 追加属性ID抽出エラーメッセージ
  cv_msg_cso_00163                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00163';  -- ステータスIDなしエラーメッセージ
  cv_msg_cso_00025                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00025';  -- データ抽出エラーメッセージ
  cv_msg_cso_00399                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00399';  -- 対象件数0件メッセージ
  cv_msg_cso_00677                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00677';  -- 汎用CSV項目数エラー
  cv_msg_cso_00771                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00771';  -- CSV項目未設定エラー
  cv_msg_cso_00772                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00772';  -- 処理区分妥当性エラー
  cv_msg_cso_00351                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00351';  -- 物件マスタ存在チェックエラーメッセージ
  cv_msg_cso_00358                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00358';  -- 作業依頼中フラグ_廃棄用チェックエラーメッセージ
  cv_msg_cso_00359                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00359';  -- 機器状態１（稼動状態）_廃棄用チェックエラーメッセージ
  cv_msg_cso_00361                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00361';  -- 機器状態３（廃棄情報）_廃棄決済用チェックエラーメッセージ
  cv_msg_cso_00365                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00365';  -- リース物件ステータスチェック（廃棄用）エラーメッセージ
  cv_msg_cso_00784                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00784';  -- 廃棄決済申請チェックエラー
  cv_msg_cso_00014                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00014';  -- プロファイル取得エラーメッセージ
  cv_msg_cso_00545                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00545';  -- 参照タイプ内容取得エラーメッセージ
  cv_msg_cso_00380                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00380';  -- 廃棄用物件情報更新エラーメッセージ
  cv_msg_cso_00241                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00241';  -- ロックエラーメッセージ
  cv_msg_cso_00773                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00773';  -- データ登録エラー
  cv_msg_cso_00072                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00072';  -- データ削除エラーメッセージ
  cv_msg_cso_00783                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00783';  -- CSVファイル行番号
  cv_msg_cso_00785                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00785';  -- 物件重複チェックエラー
--
  cv_msg_cso_00673                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00673';  -- ファイルID(メッセージ文字列)
  cv_msg_cso_00674                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00674';  -- フォーマットパターン(メッセージ文字列)
  cv_msg_cso_00676                  CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00676';  -- ファイルアップロードIF(メッセージ文字列)
  cv_msg_cso_00696                  CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00696';  -- 物件コード(メッセージ文字列)
  cv_msg_cso_00711                  CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00711';  -- 取引タイプの取引タイプID(メッセージ文字列)
  cv_msg_cso_00712                  CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00712';  -- 設置機器拡張属性定義情報の追加属性ID(メッセージ文字列)
  cv_msg_cso_00714                  CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00714';  -- 物件マスタ(メッセージ文字列)
  cv_msg_cso_00774                  CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00774';  -- 機器状態３（廃棄情報）(メッセージ文字列)
  cv_msg_cso_00775                  CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00775';  -- 廃棄決裁日(メッセージ文字列)
  cv_msg_cso_00776                  CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00776';  -- 廃棄フラグ(メッセージ文字列)
  cv_msg_cso_00777                  CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00777';  -- 処理区分(メッセージ文字列)
  cv_msg_cso_00778                  CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00778';  -- 一括廃棄連携対象テーブル(メッセージ文字列)
  cv_msg_cso_00786                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00786';  -- 廃棄手続中(メッセージ文字列)
  cv_msg_cso_00787                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00787';  -- インスタンスステータスマスタのステータスID(メッセージ文字列)
--
  --トークン
  cv_tkn_param_name                 CONSTANT VARCHAR2(30)  := 'PARAM_NAME';
  cv_tkn_value                      CONSTANT VARCHAR2(30)  := 'VALUE';
  cv_tkn_upload_file_name           CONSTANT VARCHAR2(30)  := 'UPLOAD_FILE_NAME';
  cv_tkn_csv_file_name              CONSTANT VARCHAR2(30)  := 'CSV_FILE_NAME';
  cv_tkn_task_nm                    CONSTANT VARCHAR2(20)  := 'TASK_NAME';
  cv_tkn_src_tran_type              CONSTANT VARCHAR2(20)  := 'SRC_TRAN_TYPE';
  cv_tkn_status_name                CONSTANT VARCHAR2(20)  := 'STATUS_NAME';
  cv_tkn_err_msg                    CONSTANT VARCHAR2(20)  := 'ERR_MSG';
  cv_tkn_add_attr_nm                CONSTANT VARCHAR2(20)  := 'ADD_ATTRIBUTE_NAME';
  cv_tkn_add_attr_cd                CONSTANT VARCHAR2(20)  := 'ADD_ATTRIBUTE_CODE';
  cv_tkn_table                      CONSTANT VARCHAR2(20)  := 'TABLE';
  cv_tkn_file_id                    CONSTANT VARCHAR2(30)  := 'FILE_ID';
  cv_tkn_index                      CONSTANT VARCHAR2(30)  := 'INDEX';
  cv_tkn_bukken                     CONSTANT VARCHAR2(20)  := 'BUKKEN';
  cv_tkn_status1                    CONSTANT VARCHAR2(20)  := 'STATUS1';
  cv_tkn_status3                    CONSTANT VARCHAR2(20)  := 'STATUS3';
  cv_tkn_date                       CONSTANT VARCHAR2(20)  := 'DATE';
  cv_tkn_api_err_msg                CONSTANT VARCHAR2(20)  := 'API_ERR_MSG';
  cv_tkn_item                       CONSTANT VARCHAR2(30)  := 'ITEM';
  cv_tkn_base_value                 CONSTANT VARCHAR2(30)  := 'BASE_VALUE';
  cv_tkn_prof_name                  CONSTANT VARCHAR2(20)  := 'PROF_NAME';
  cv_tkn_lookup_type_name           CONSTANT VARCHAR2(20)  := 'LOOKUP_TYPE_NAME';
  cv_tkn_err_message                CONSTANT VARCHAR2(20)  := 'ERR_MESSAGE';
--
  -- 参照タイプ
  cv_lkup_file_ul_obj               CONSTANT VARCHAR2(50)  := 'XXCCP1_FILE_UPLOAD_OBJ';  -- ファイルアップロードOBJ
  cv_lkup_instance_status           CONSTANT VARCHAR2(30)  := 'XXCSO1_INSTANCE_STATUS';  -- インスタンスステータスID
--
  -- CSV関連
  cn_col_proc_kbn                   CONSTANT NUMBER        := 1;   -- 処理区分
  cn_col_install_code               CONSTANT NUMBER        := 2;   -- 物件コード
  cn_csv_file_col_num               CONSTANT NUMBER        := 2;   -- CSVファイル項目数
  cv_col_separator                  CONSTANT VARCHAR2(1)   := ','; -- 項目区切文字
  cv_dqu                            CONSTANT VARCHAR2(1)   := '"'; -- 文字列括り
--
  -- その他
  cv_yes                            CONSTANT VARCHAR2(1)   := 'Y';             -- 汎用Y
  cv_no                             CONSTANT VARCHAR2(1)   := 'N';             -- 汎用N
  cv_zero                           CONSTANT VARCHAR2(1)   := '0';             -- 汎用0
  cv_kbn_1                          CONSTANT VARCHAR2(1)   := '1';             -- 区分'1'（チェック）
  cv_kbn_2                          CONSTANT VARCHAR2(1)   := '2';             -- 区分'2'（更新）
  cv_instance_status_4              CONSTANT VARCHAR2(1)   := '4';             -- ステータスIDのコード'4'（廃棄手続中）
  cv_fmt_ptn_check                  CONSTANT VARCHAR2(3)   := '690';           -- フォーマットパターン:690（チェック）
  cv_ib_ui                          CONSTANT VARCHAR2(5)   := 'IB_UI';         -- 取引タイプ:'IB_UI'
  cv_attr_cd_jotai_kbn3             CONSTANT VARCHAR2(30)  := 'JOTAI_KBN3';    -- 属性コード:'JOTAI_KBN3'
  cv_attr_cd_haikikessai_dt         CONSTANT VARCHAR2(30)  := 'HAIKIKESSAI_DT';-- 属性コード:'HAIKIKESSAI_DT'
  cv_attr_cd_ven_haiki_flg          CONSTANT VARCHAR2(30)  := 'VEN_HAIKI_FLG'; -- 属性コード:'VEN_HAIKI_FLG'
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- アップロードデータ分割取得用
  TYPE gt_col_data_rec    IS TABLE OF VARCHAR(2000)   INDEX BY BINARY_INTEGER; -- 1次元配列
  TYPE gt_rec_data_ttype  IS TABLE OF gt_col_data_rec INDEX BY BINARY_INTEGER; -- 2次元配列
  g_sep_data_tab          gt_rec_data_ttype; -- 分割データ格納用配列
  -- 物件重複チェック用
  TYPE g_instance_ttype   IS TABLE OF csi_item_instances.external_reference%TYPE INDEX BY VARCHAR2(30); -- 1次元配列
  g_chk_instance_tab      g_instance_ttype;  -- 物件コード格納用配列
--
  -- IB追加属性ID
  TYPE g_ib_ext_attr_id_rtype IS RECORD(
      jotai_kbn3                 NUMBER  -- 機器状態3
     ,abolishment_flag           NUMBER  -- 廃棄フラグ
     ,abolishment_decision_date  NUMBER  -- 廃棄決裁日
  );
  -- IB追加属性値ID
  TYPE g_ib_ext_attr_val_id_rtype IS RECORD(
      jotai_kbn3                 NUMBER  -- 機器状態3
     ,abolishment_flag           NUMBER  -- 廃棄フラグ
     ,abolishment_decision_date  NUMBER  -- 廃棄決裁日
  );
  -- IB追加属性ID情報
  g_ib_ext_attr_id_rec        g_ib_ext_attr_id_rtype;
  -- IB追加属性ID情報
  g_ib_ext_attr_val_id_rec    g_ib_ext_attr_val_id_rtype;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_process_date         DATE;    -- 業務処理日付
  gv_kbn                  VARCHAR2(1); -- 区分
  gt_transaction_type_id  csi_txn_types.transaction_type_id%TYPE; -- 取引タイプID
  gt_instance_id          xxcso_install_base_v.instance_id%TYPE;  -- インスタンスID
  gt_instance_status_id   csi_instance_statuses.instance_status_id%TYPE; -- インスタンスステータスID
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     iv_file_id    IN  VARCHAR2     --   1.ファイルID
    ,iv_fmt_ptn    IN  VARCHAR2     --   2.フォーマットパターン
    ,ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
    ,ov_errmsg     OUT VARCHAR2)    --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_msg           VARCHAR2(5000);                             -- メッセージ出力用
    lt_file_ul_name  fnd_lookup_values_vl.meaning%TYPE;          -- ファイルアップロード名称
    lt_file_name     xxccp_mrp_file_ul_interface.file_name%TYPE; -- ファイル名
    lt_status_name   csi_instance_statuses.name%TYPE;            -- ステータス名
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
    lv_msg           := NULL;
    lt_file_ul_name  := NULL;
    lt_file_name     := NULL;
    lt_status_name   := NULL;
--
    --=========================================
    -- 入力パラメータ出力
    --=========================================
    -- ファイルID
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_app_name
               ,iv_name         => cv_msg_cso_00496  -- パラメータ出力
               ,iv_token_name1  => cv_tkn_param_name
               ,iv_token_value1 => cv_msg_cso_00673  -- ファイルID
               ,iv_token_name2  => cv_tkn_value
               ,iv_token_value2 => iv_file_id
              );
    -- ファイルIDメッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg
    );
    -- フォーマットパターン
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_app_name
               ,iv_name         => cv_msg_cso_00496  -- パラメータ出力
               ,iv_token_name1  => cv_tkn_param_name
               ,iv_token_value1 => cv_msg_cso_00674  -- フォーマットパターン
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
                    ,iv_name         => cv_msg_cso_00011 --業務処理日付取得エラー
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --=========================================
    -- アップロードファイル名称取得
    --=========================================
    BEGIN
      SELECT flv.meaning  AS meaning -- アップロードファイル名称
      INTO   lt_file_ul_name
      FROM   fnd_lookup_values_vl flv -- クイックコード
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
                      ,iv_name         => cv_msg_cso_00274 -- データ抽出エラー（アップロードファイル名称）
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ファイルアップロード名称
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_app_name
               ,iv_name         => cv_msg_cso_00276 -- ファイルアップロード名称
               ,iv_token_name1  => cv_tkn_upload_file_name
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
      SELECT xmfui.file_name AS file_name -- ファイル名
      INTO   lt_file_name
      FROM   xxccp_mrp_file_ul_interface xmfui -- ファイルアップロードIF
      WHERE  xmfui.file_id = TO_NUMBER(iv_file_id) -- ファイルID
      FOR UPDATE NOWAIT
      ;
      -- CSVファイル名メッセージ
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name
                 ,iv_name         => cv_msg_cso_00152 -- CSVファイル名
                 ,iv_token_name1  => cv_tkn_csv_file_name
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
                      ,iv_name         => cv_msg_cso_00278  -- ロックエラー
                      ,iv_token_name1  => cv_tkn_table
                      ,iv_token_value1 => cv_msg_cso_00676  -- ファイルアップロードIF
                      ,iv_token_name2  => cv_tkn_err_msg
                      ,iv_token_value2 => SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --=========================================
    -- 取引タイプID抽出
    --=========================================
    BEGIN
      SELECT ctt.transaction_type_id AS transaction_type_id -- 取引タイプID
      INTO   gt_transaction_type_id
      FROM   csi_txn_types ctt -- 取引タイプ
      WHERE  ctt.source_transaction_type = cv_ib_ui -- ソーストランザクションタイプ
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- 取得できなかった場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_msg_cso_00342 -- 取引タイプIDなしエラーメッセージ
                      ,iv_token_name1  => cv_tkn_task_nm
                      ,iv_token_value1 => cv_msg_cso_00711 -- 取引タイプの取引タイプID
                      ,iv_token_name2  => cv_tkn_src_tran_type
                      ,iv_token_value2 => cv_ib_ui         -- 取引タイプ:'IB_UI'
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END;
--
    --=========================================
    -- 設置機器拡張属性の追加属性ID抽出
    --=========================================
    -- 機器状態３（廃棄情報）
    g_ib_ext_attr_id_rec.jotai_kbn3 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                         iv_attribute_code => cv_attr_cd_jotai_kbn3
                                        ,id_standard_date  => gd_process_date
                                       );
    -- 取得できなかった場合
    IF ( g_ib_ext_attr_id_rec.jotai_kbn3 IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_msg_cso_00103 -- 追加属性ID抽出エラーメッセージ
                    ,iv_token_name1  => cv_tkn_task_nm
                    ,iv_token_value1 => cv_msg_cso_00712 -- 設置機器拡張属性定義情報の追加属性ID
                    ,iv_token_name2  => cv_tkn_add_attr_nm
                    ,iv_token_value2 => cv_msg_cso_00774 -- 機器状態３（廃棄情報）
                    ,iv_token_name3  => cv_tkn_add_attr_cd
                    ,iv_token_value3 => cv_attr_cd_jotai_kbn3 -- 属性コード:'JOTAI_KBN3'
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 廃棄フラグ
    g_ib_ext_attr_id_rec.abolishment_flag := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                               iv_attribute_code => cv_attr_cd_ven_haiki_flg
                                              ,id_standard_date  => gd_process_date
                                             );
--
    -- 取得できなかった場合
    IF ( g_ib_ext_attr_id_rec.abolishment_flag IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_msg_cso_00103 -- 追加属性ID抽出エラーメッセージ
                    ,iv_token_name1  => cv_tkn_task_nm
                    ,iv_token_value1 => cv_msg_cso_00712 -- 設置機器拡張属性定義情報の追加属性ID
                    ,iv_token_name2  => cv_tkn_add_attr_nm
                    ,iv_token_value2 => cv_msg_cso_00776 -- 廃棄フラグ
                    ,iv_token_name3  => cv_tkn_add_attr_cd
                    ,iv_token_value3 => cv_attr_cd_ven_haiki_flg -- 属性コード:'VEN_HAIKI_FLG'
                 );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 廃棄決裁日
    g_ib_ext_attr_id_rec.abolishment_decision_date := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                                         iv_attribute_code => cv_attr_cd_haikikessai_dt
                                                        ,id_standard_date  => gd_process_date
                                                      );
--
    -- 取得できなかった場合
    IF ( g_ib_ext_attr_id_rec.abolishment_decision_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_msg_cso_00103 -- 追加属性ID抽出エラーメッセージ
                    ,iv_token_name1  => cv_tkn_task_nm
                    ,iv_token_value1 => cv_msg_cso_00712 -- 設置機器拡張属性定義情報の追加属性ID
                    ,iv_token_name2  => cv_tkn_add_attr_nm
                    ,iv_token_value2 => cv_msg_cso_00775 -- 廃棄決裁日
                    ,iv_token_name3  => cv_tkn_add_attr_cd
                    ,iv_token_value3 => cv_attr_cd_haikikessai_dt -- 属性コード:'HAIKIKESSAI_DT'
                 );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --=========================================
    -- インスタンスステータスIDの抽出
    --=========================================
    BEGIN
      -- ステータス名の取得
      lt_status_name := xxcso_util_common_pkg.get_lookup_meaning(
                            cv_lkup_instance_status
                          , cv_instance_status_4
                          , gd_process_date
                        );
--
      -- インスタンスステータスIDの取得
      SELECT cis.instance_status_id AS instance_status_id -- インスタンスステータスID
      INTO   gt_instance_status_id
      FROM   csi_instance_statuses cis -- インスタンスステータスマスタ
      WHERE  cis.name = lt_status_name  -- ステータス名
      AND    gd_process_date
               BETWEEN TRUNC( NVL( cis.start_date_active, gd_process_date ) ) -- 有効開始日
               AND     TRUNC( NVL( cis.end_date_active, gd_process_date ) )   -- 有効終了日
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- データが存在しない場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name        -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cso_00163   -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_nm     -- トークンコード1
                       ,iv_token_value1 => cv_msg_cso_00787   -- トークン値1
                       ,iv_token_name2  => cv_tkn_status_name -- トークンコード2
                       ,iv_token_value2 => cv_msg_cso_00786   -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
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
     in_file_id      IN  NUMBER            -- 1.ファイルID
    ,ov_errbuf       OUT VARCHAR2          --   エラー・メッセージ           --# 固定 #
    ,ov_retcode      OUT VARCHAR2          --   リターン・コード             --# 固定 #
    ,ov_errmsg       OUT VARCHAR2)         --   ユーザー・エラー・メッセージ --# 固定 #
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
                    ,iv_name         => cv_msg_cso_00025 -- データ抽出エラーメッセージ
                    ,iv_token_name1  => cv_tkn_table
                    ,iv_token_value1 => cv_msg_cso_00676 -- ファイルアップロードIF
                    ,iv_token_name2  => cv_tkn_file_id
                    ,iv_token_value2 => TO_CHAR(in_file_id) -- ファイルID
                    ,iv_token_name3  => cv_tkn_err_msg
                    ,iv_token_value3 => lv_errbuf
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --=========================================
    -- 取得したデータが1件（ヘッダのみ）の場合
    --=========================================
    IF (l_file_data_tab.COUNT - 1 <= 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_msg_cso_00399 -- 対象件数0件メッセージ
                   );
      -- 対象件数0件メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      ov_retcode  := cv_status_warn;
      -- 以降の処理は行わない
      RETURN;
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
                      ,iv_name         => cv_msg_cso_00677 -- 汎用CSV項目数エラー
                      ,iv_token_name1  => cv_tkn_index
                      ,iv_token_value1 => TO_CHAR(ln_line_cnt - 1)
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
   * Procedure Name   : delete_upload_if
   * Description      : ファイルアップロードIFデータ削除(A-3)
   ***********************************************************************************/
  PROCEDURE delete_upload_if(
    in_file_id    IN  NUMBER,       -- ファイルID
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_upload_if'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_msg_tkn VARCHAR2(5000);  -- メッセージトークン取得用
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
    --=========================================
    -- ファイルアップロードIF削除
    --=========================================
    BEGIN
      DELETE FROM xxccp_mrp_file_ul_interface xmfui -- ファイルアップロードIF
      WHERE xmfui.file_id = in_file_id -- ファイルID
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- エラーが発生した場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_msg_cso_00072 -- データ削除エラーメッセージ
                      ,iv_token_name1  => cv_tkn_table
                      ,iv_token_value1 => cv_msg_cso_00676 -- ファイルアップロードIF
                      ,iv_token_name2  => cv_tkn_err_message
                      ,iv_token_value2 => SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
    WHEN global_process_expt THEN                           --*** 処理エラー例外 ***
      -- *** 任意で例外処理を記述する ****
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
  END delete_upload_if;
--
  /**********************************************************************************
   * Procedure Name   : proc_kbn_check
   * Description      : 処理区分チェック(A-4)
   ***********************************************************************************/
  PROCEDURE proc_kbn_check(
     iv_proc_kbn     IN  VARCHAR2   -- 処理区分
    ,in_loop_cnt     IN  NUMBER     -- ループカウンタ
    ,ov_errbuf       OUT VARCHAR2          --   エラー・メッセージ           --# 固定 #
    ,ov_retcode      OUT VARCHAR2          --   リターン・コード             --# 固定 #
    ,ov_errmsg       OUT VARCHAR2)         --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_kbn_check'; -- プログラム名
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
    --=========================================
    -- 処理区分必須チェック
    --=========================================
    IF ( iv_proc_kbn IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_msg_cso_00771 -- CSV項目未設定エラー
                    ,iv_token_name1  => cv_tkn_item
                    ,iv_token_value1 => cv_msg_cso_00777 -- 処理区分
                   );
      --メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      ov_retcode  := cv_status_warn;
    END IF;
--
    --=========================================
    -- 処理区分妥当性チェック
    --=========================================
    IF ( iv_proc_kbn <> gv_kbn ) THEN 
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_msg_cso_00772 -- 処理区分妥当性エラー
                   );
      --メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      ov_retcode  := cv_status_warn;
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
      ov_retcode := cv_status_warn;
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
  END proc_kbn_check;
--
  /**********************************************************************************
   * Procedure Name   : data_validation
   * Description      : データ妥当性チェック(A-5)
   ***********************************************************************************/
  PROCEDURE data_validation(
     iv_install_code IN  VARCHAR2          --   物件コード
    ,in_loop_cnt     IN  NUMBER            --   ループカウンタ
    ,ov_errbuf       OUT VARCHAR2          --   エラー・メッセージ           --# 固定 #
    ,ov_retcode      OUT VARCHAR2          --   リターン・コード             --# 固定 #
    ,ov_errmsg       OUT VARCHAR2)         --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- リース区分
    cv_lease_kbn_1          CONSTANT VARCHAR2(1)  := '1'; -- 自社リース
    cv_lease_kbn_4          CONSTANT VARCHAR2(1)  := '4'; -- 固定資産
    -- リース区分（リース物件）
    cv_lease_type_1         CONSTANT VARCHAR2(1)  := '1'; -- 原契約
    cv_lease_type_2         CONSTANT VARCHAR2(1)  := '2'; -- 再リース契約
    -- 物件ステータス
    cv_obj_sts_110          CONSTANT VARCHAR2(3)  := '110';  -- 中途解約（自己都合）
    cv_obj_sts_111          CONSTANT VARCHAR2(3)  := '111';  -- 中途解約（保険対応）
    cv_obj_sts_112          CONSTANT VARCHAR2(3)  := '112';  -- 中途解約（満了）
    cv_obj_sts_107          CONSTANT VARCHAR2(3)  := '107';  -- 満了
    -- 証書受領フラグ
    cv_bnd_accpt_flg_accptd CONSTANT VARCHAR2(1)  := '1'; -- 受領済
    -- 状態区分
    cv_jotai_kbn_0          CONSTANT VARCHAR2(1)  := '0'; -- 状態区分:'0'(予定無)
    cv_jotai_kbn_1          CONSTANT VARCHAR2(1)  := '1'; -- 状態区分:'1'(滞留)
    cv_jotai_kbn_2          CONSTANT VARCHAR2(1)  := '2'; -- 状態区分:'2'(廃棄予定)
    -- プロファイル
    cv_prof_fa_books        CONSTANT VARCHAR2(30) := 'XXCFF1_FIXED_ASSETS_BOOKS';  -- XXCFF:台帳名
    cv_lookup_csi_type_code CONSTANT VARCHAR2(30) := 'CSI_INST_TYPE_CODE';         -- インスタンス・タイプ・コード
    -- 参照タイプ
    cv_lookup_deprn_year    CONSTANT VARCHAR2(30) := 'XXCSO1_DEPRN_YEAR';  -- 参照タイプ「償却年数」
--
    -- *** ローカル変数 ***
    lv_msg_row_num            VARCHAR2(5000); -- 行番号
    lt_op_request_flag        xxcso_install_base_v.op_request_flag%TYPE;         -- 作業依頼中フラグ
    lt_jotai_kbn1             xxcso_install_base_v.jotai_kbn1%TYPE;              -- 機器状態１（稼動状態）
    lt_jotai_kbn3             xxcso_install_base_v.jotai_kbn3%TYPE;              -- 機器状態３（廃棄情報）
    lt_lease_kbn              xxcso_install_base_v.lease_kbn%TYPE;               -- リース区分
    lt_instance_type_code     xxcso_install_base_v.lease_kbn%TYPE;               -- インスタンス・タイプ・コード
    lt_object_code            xxcff_object_headers.object_code%TYPE;             -- 物件コード
    lt_object_status          xxcff_object_headers.object_status%TYPE;           -- 物件ステータス
    lt_lease_type             xxcff_object_headers.lease_type%TYPE;              -- リース区分（リース物件）
    lt_bond_acceptance_flag   xxcff_object_headers.bond_acceptance_flag%TYPE;    -- 証書受領フラグ
    lt_lease_start_date       xxcff_contract_headers.lease_start_date%TYPE;      -- リース開始日
    lt_lease_class            xxcff_contract_headers.lease_class%TYPE;           -- リース種別
    ld_deprn_date             DATE;                                              -- 償却日
    lt_fa_book_type_code      fa_books.book_type_code%TYPE;                      -- 台帳名
    lt_date_placed_in_service fa_books.date_placed_in_service%TYPE;              -- 事業供用日
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
    lv_msg_row_num            := NULL; -- 行番号
    lt_op_request_flag        := NULL; -- 作業依頼中フラグ
    lt_jotai_kbn1             := NULL; -- 機器状態１（稼動状態）
    lt_jotai_kbn3             := NULL; -- 機器状態３（廃棄情報）
    lt_lease_kbn              := NULL; -- リース区分
    lt_instance_type_code     := NULL; -- インスタンス・タイプ・コード
    lt_object_code            := NULL; -- 物件コード
    lt_object_status          := NULL; -- 物件ステータス
    lt_lease_type             := NULL; -- リース区分（リース物件）
    lt_bond_acceptance_flag   := NULL; -- 証書受領フラグ
    lt_lease_start_date       := NULL; -- リース開始日
    lt_lease_class            := NULL; -- リース種別
    ld_deprn_date             := NULL; -- 償却日
    lt_fa_book_type_code      := NULL; -- 台帳名
    lt_date_placed_in_service := NULL; -- 事業供用日
--
    -- 行番号メッセージ取得
    lv_msg_row_num := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_msg_cso_00783     -- CSVファイル行番号
                    ,iv_token_name1  => cv_tkn_index
                    ,iv_token_value1 => TO_CHAR(in_loop_cnt) -- レコード行
                   );
--
    --=========================================
    -- 物件コード必須チェック
    --=========================================
    IF ( iv_install_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_msg_cso_00771 -- CSV項目未設定エラー
                    ,iv_token_name1  => cv_tkn_item
                    ,iv_token_value1 => cv_msg_cso_00696 -- 物件コード
                   ) || lv_msg_row_num;
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
      -- 物件存在チェック
      --=========================================
      BEGIN
        SELECT xibv.op_request_flag              AS op_request_flag         -- 作業依頼中フラグ
              ,xibv.jotai_kbn1                   AS jotai_kbn1              -- 機器状態１（稼動状態）
              ,xibv.jotai_kbn3                   AS jotai_kbn3              -- 機器状態３（廃棄情報）
              ,xibv.lease_kbn                    AS lease_kbn               -- リース区分
              ,xibv.instance_type_code           AS instance_type_code      -- インスタンス・タイプ・コード
        INTO  lt_op_request_flag
             ,lt_jotai_kbn1
             ,lt_jotai_kbn3
             ,lt_lease_kbn
             ,lt_instance_type_code
        FROM  xxcso_install_base_v xibv -- 物件マスタビュー
        WHERE xibv.install_code = iv_install_code -- 物件コード
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- 取得できなかった場合
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name
                        ,iv_name         => cv_msg_cso_00351 -- 物件マスタ存在チェックエラーメッセージ
                        ,iv_token_name1  => cv_tkn_bukken
                        ,iv_token_value1 => iv_install_code  -- 物件コード
                       ) || lv_msg_row_num;
          -- 警告メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          -- ステータスを警告に設定
          ov_retcode := cv_status_warn;
      END;
    END IF;
--
    -- エラーが発生していない場合
    IF ( ov_retcode <> cv_status_warn ) THEN
      --=========================================
      -- 物件ステータスチェック
      --=========================================
      -- 作業依頼中フラグが'Y'の場合
      IF ( lt_op_request_flag = cv_yes ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_msg_cso_00358 -- 作業依頼中フラグ_廃棄用チェックエラーメッセージ
                      ,iv_token_name1  => cv_tkn_bukken
                      ,iv_token_value1 => iv_install_code  -- 物件コード
                     ) || lv_msg_row_num;
        -- 警告メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        -- ステータスを警告に設定
        ov_retcode := cv_status_warn;
      END IF;
--
      -- 機器状態１（稼動状態）が'2'（滞留）以外の場合
      IF ( lt_jotai_kbn1 <> cv_jotai_kbn_2 ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_msg_cso_00359 -- 機器状態１（稼動状態）_廃棄用チェックエラーメッセージ
                      ,iv_token_name1  => cv_tkn_bukken
                      ,iv_token_value1 => iv_install_code  -- 物件コード
                      ,iv_token_name2  => cv_tkn_status1
                      ,iv_token_value2 => lt_jotai_kbn1    -- 機器状態１（稼動状態）
                     ) || lv_msg_row_num;
        -- 警告メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        -- ステータスを警告に設定
        ov_retcode := cv_status_warn;
      END IF;
--
      -- 「機器状態３（廃棄情報）が'0'(予定無)、もしくは'1'(廃棄予定)」以外の場合
      IF ( ( lt_jotai_kbn3 <> cv_jotai_kbn_0 ) AND ( lt_jotai_kbn3 <> cv_jotai_kbn_1 ) ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_msg_cso_00361 -- 機器状態３（廃棄情報）_廃棄決済用チェックエラーメッセージ
                      ,iv_token_name1  => cv_tkn_bukken
                      ,iv_token_value1 => iv_install_code  -- 物件コード
                      ,iv_token_name2  => cv_tkn_status3
                      ,iv_token_value2 => lt_jotai_kbn3    -- 機器状態３（廃棄情報）
                     ) || lv_msg_row_num;
        -- 警告メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        -- ステータスを警告に設定
        ov_retcode := cv_status_warn;
      END IF;
--
      --=========================================
      -- リース状態チェック
      --=========================================
      -- リース区分が「1:自社リース」の場合
      IF ( lt_lease_kbn = cv_lease_kbn_1 ) THEN
        BEGIN
          SELECT xoh.object_code           AS object_code          -- 物件コード
                ,xoh.object_status         AS object_status        -- 物件ステータス
                ,xoh.lease_type            AS lease_type           -- リース区分（リース物件）
                ,xoh.bond_acceptance_flag  AS bond_acceptance_flag -- 証書受領フラグ
          INTO   lt_object_code
                ,lt_object_status
                ,lt_lease_type
                ,lt_bond_acceptance_flag
          FROM   xxcff_object_headers  xoh -- リース物件テーブル
          WHERE  xoh.object_code = iv_install_code -- 物件コード
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
        END;
--
        -- データが取得できた場合
        IF ( lt_object_code IS NOT NULL ) THEN
          -- ステータスチェック
          IF ( NOT(
                -- 物件ステータスが「満了」または「中途解約（満了）」
                -- リース区分（リース物件）が「原契約」かつ物件ステータスが「中途解約(自己都合)」かつ証書受領フラグが「受領済」
                -- リース区分（リース物件）が「原契約」かつ物件ステータスが「中途解約(保険対応)」かつ証書受領フラグが「受領済」
                -- リース区分（リース物件）が「再リース契約」
                ( (lt_object_status = cv_obj_sts_107) OR (lt_object_status = cv_obj_sts_112) )
                OR ( (lt_lease_type = cv_lease_type_1) AND (lt_object_status = cv_obj_sts_110) AND (lt_bond_acceptance_flag = cv_bnd_accpt_flg_accptd) )
                OR ( (lt_lease_type = cv_lease_type_1) AND (lt_object_status = cv_obj_sts_111) AND (lt_bond_acceptance_flag = cv_bnd_accpt_flg_accptd) )
                OR ( lt_lease_type = cv_lease_type_2)
               ))
          THEN
            -- ステータスチェックエラー
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name
                          ,iv_name         => cv_msg_cso_00365 -- リース物件ステータスチェック（廃棄用）エラーメッセージ
                          ,iv_token_name1  => cv_tkn_bukken
                          ,iv_token_value1 => iv_install_code  -- 物件コード
                         ) || lv_msg_row_num;
            -- 警告メッセージ出力
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
            -- ステータスを警告に設定
            ov_retcode := cv_status_warn;
          END IF;
--
          -- ステータスが「中途解約(自己都合)」または「中途解約(保険対応)」かつ、証書受領フラグが「受領済」の場合
          IF ( (lt_object_status = cv_obj_sts_110 OR lt_object_status = cv_obj_sts_111)
                   AND (lt_bond_acceptance_flag = cv_bnd_accpt_flg_accptd) )
          THEN
            -- リース情報取得
            BEGIN
              SELECT /*+ USE_NL(xxoh xxcl xxch) INDEX(xxoh XXCFF_OBJECT_HEADERS_U01) */
                     xxch.lease_start_date AS lease_start_date -- リース開始日
                    ,xxch.lease_class      AS lease_class      -- リース種別
              INTO   lt_lease_start_date
                    ,lt_lease_class
              FROM   xxcff_object_headers    xxoh  --リース物件
                    ,xxcff_contract_lines    xxcl  --リース契約明細
                    ,xxcff_contract_headers  xxch  --リース契約ヘッダ
              WHERE  xxoh.object_code      = iv_install_code            -- 物件コード
              AND    xxoh.object_header_id = xxcl.object_header_id      -- 物件内部ID
              AND    xxcl.lease_kind       = cv_zero                    -- リース種類(Fin)
              AND    xxch.contract_header_id = xxcl.contract_header_id  -- 契約内部ID
              ;
            EXCEPTION
              -- 該当データが存在しない場合
              WHEN NO_DATA_FOUND THEN
                NULL;
            END;
--
            -- 上記でデータが取得できた場合
            IF ( lt_lease_start_date IS NOT NULL ) THEN
              -- 償却日を取得
              BEGIN
                SELECT ADD_MONTHS( lt_lease_start_date , flvv.attribute1 * 12 ) AS deprn_date  -- 償却日
                INTO   ld_deprn_date
                FROM   fnd_lookup_values_vl flvv -- クイックコード
                WHERE  flvv.lookup_type  = cv_lookup_deprn_year -- タイプ
                AND    flvv.enabled_flag = cv_yes          -- 有効フラグ
                AND    flvv.attribute2   = lt_lease_class       -- リース種別
                AND    flvv.start_date_active <= lt_lease_start_date  -- 有効開始日
                AND    flvv.end_date_active   >= lt_lease_start_date  -- 有効終了日
                ;
              EXCEPTION
                -- 該当データが存在しない場合
                WHEN NO_DATA_FOUND THEN
                  NULL;
              END;
--
              -- 償却日を取得できた場合
              IF ( ld_deprn_date IS NOT NULL ) THEN
                -- 償却期間中チェック
                IF ( (lt_lease_start_date <= gd_process_date)
                  AND ( gd_process_date < ld_deprn_date ) )
                THEN
                  -- 廃棄決済申請チェックエラー
                  lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_app_name
                                ,iv_name         => cv_msg_cso_00784 -- 廃棄決済申請チェックエラー
                                ,iv_token_name1  => cv_tkn_bukken
                                ,iv_token_value1 => iv_install_code  -- 物件コード
                                ,iv_token_name2  => cv_tkn_date
                                ,iv_token_value2 => TO_CHAR(ld_deprn_date-1,'YYYY/MM/DD') -- 償却期間終了日
                               ) || lv_msg_row_num;
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
          END IF;
        END IF;
      END IF;
--
      --=========================================
      -- 償却期間チェック（固定資産）
      --=========================================
      -- リース区分が「4:固定資産」の場合
      IF ( lt_lease_kbn = cv_lease_kbn_4 ) THEN
        -- プロファイルオプション値の取得
        FND_PROFILE.GET( cv_prof_fa_books ,lt_fa_book_type_code );
        -- 取得できなかった場合
        IF ( lt_fa_book_type_code IS NULL ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name           -- アプリケーション短縮名
                         ,iv_name         => cv_msg_cso_00014      -- プロファイル取得エラーメッセージ
                         ,iv_token_name1  => cv_tkn_prof_name      -- トークンコード1
                         ,iv_token_value1 => cv_prof_fa_books      -- トークン値1
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- リース種別取得
        lt_lease_class := xxcso_util_common_pkg.get_lookup_attribute(
                            cv_lookup_csi_type_code  -- タイプ
                           ,lt_instance_type_code    -- コード
                           ,1                        -- DFF番号
                           ,gd_process_date          -- 基準日
                          );
        -- 取得できなかった場合
        IF ( lt_lease_class IS NULL ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name              -- アプリケーション短縮名
                        ,iv_name         => cv_msg_cso_00545         -- 参照タイプ内容取得エラーメッセージ
                        ,iv_token_name1  => cv_tkn_task_nm
                        ,iv_token_value1 => lt_instance_type_code    -- インスタンス・タイプ・コード
                        ,iv_token_name2  => cv_tkn_lookup_type_name
                        ,iv_token_value2 => cv_lookup_csi_type_code  -- 参照タイプ:'CSI_INST_TYPE_CODE'
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- 事業供用日取得
        BEGIN
          SELECT fb.date_placed_in_service AS date_placed_in_service -- 事業供用日
          INTO   lt_date_placed_in_service
          FROM   fa_additions_b            fab -- 資産詳細情報
                ,fa_books                  fb  -- 資産台帳情報
          WHERE  fab.asset_id      = fb.asset_id          -- 資産ID
          AND    fb.date_ineffective IS NULL              -- 無効日
          AND    fb.book_type_code = lt_fa_book_type_code -- 資産台帳名
          AND    fab.tag_number    = iv_install_code      -- 物件コード
          ;
        EXCEPTION
          -- 該当データが存在しない場合
          WHEN NO_DATA_FOUND THEN
            NULL;
        END;
--
        -- 事業供用日が取得できた場合
        IF ( lt_date_placed_in_service IS NOT NULL ) THEN
          -- 償却日を取得
          BEGIN
            SELECT ADD_MONTHS( lt_date_placed_in_service , flvv.attribute1 * 12 ) AS deprn_date -- 償却日
            INTO   ld_deprn_date
            FROM   fnd_lookup_values_vl flvv
            WHERE  flvv.lookup_type        = cv_lookup_deprn_year -- タイプ
            AND    flvv.enabled_flag       = cv_yes               -- 有効フラグ
            AND    flvv.attribute2         = lt_lease_class       -- リース種別
            AND    flvv.start_date_active <= lt_date_placed_in_service  -- 有効開始日
            AND    flvv.end_date_active   >= lt_date_placed_in_service  -- 有効終了日
            ;
          EXCEPTION
            -- 該当データが存在しない場合
            WHEN NO_DATA_FOUND THEN
              NULL;
          END;
--
          -- 償却日を取得できた場合
          IF ( ld_deprn_date IS NOT NULL ) THEN
            -- 償却期間中チェック
            IF ( lt_date_placed_in_service <= gd_process_date )
              AND ( gd_process_date < ld_deprn_date )
            THEN
              -- 廃棄決済申請チェックエラー
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name
                            ,iv_name         => cv_msg_cso_00784 -- 廃棄決済申請チェックエラー
                            ,iv_token_name1  => cv_tkn_bukken
                            ,iv_token_value1 => iv_install_code  -- 物件コード
                            ,iv_token_name2  => cv_tkn_date
                            ,iv_token_value2 => TO_CHAR(ld_deprn_date-1,'YYYY/MM/DD') -- 償却期間終了日
                           ) || lv_msg_row_num;
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
      END IF;
--
      --=========================================
      -- 物件重複チェック
      --=========================================
      IF ( g_chk_instance_tab.EXISTS(iv_install_code) = FALSE ) THEN
        g_chk_instance_tab(iv_install_code) := iv_install_code;
      ELSE
        -- 物件重複チェックエラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_msg_cso_00785 -- 物件重複チェックエラー
                      ,iv_token_name1  => cv_tkn_bukken
                      ,iv_token_value1 => iv_install_code -- 物件コード
                     )
                     || lv_msg_row_num;
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
   * Procedure Name   : upd_install_info
   * Description      : 物件情報更新(A-6)
   ***********************************************************************************/
  PROCEDURE upd_install_info(
     iv_install_code IN  VARCHAR2          --   物件コード
    ,ov_errbuf       OUT VARCHAR2          --   エラー・メッセージ           --# 固定 #
    ,ov_retcode      OUT VARCHAR2          --   リターン・コード             --# 固定 #
    ,ov_errmsg       OUT VARCHAR2)         --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_install_info'; -- プログラム名
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
    -- 物件更新API引数
    cn_api_version           CONSTANT NUMBER         := 1.0;
    cv_commit_false          CONSTANT VARCHAR2(1)    := 'F';
    cv_init_msg_list_true    CONSTANT VARCHAR2(2000) := 'T';
    cv_encoded_false         CONSTANT VARCHAR2(1)    := 'F';
    -- 属性値
    cv_jotai_kbn3_ablsh_desc CONSTANT VARCHAR2(1)    := '3';  -- 機器状態３（廃棄情報）「廃棄決裁済」
    cv_ablsh_flg_ablsh_desc  CONSTANT VARCHAR2(1)    := '9';  -- 廃棄フラグ「廃棄決裁済」
--
    -- *** ローカル変数 ***
    lt_object_version_number xxcso_install_base_v.object_version_number%TYPE;   -- オブジェクトバージョン番号
    -- API入力値格納用
    ln_validation_level      NUMBER;
    -- API入出力レコード値格納用
    l_instance_rec           csi_datastructures_pub.instance_rec;
    l_ext_attrib_values_tab  csi_datastructures_pub.extend_attrib_values_tbl;
    l_party_tab              csi_datastructures_pub.party_tbl;
    l_account_tab            csi_datastructures_pub.party_account_tbl;
    l_pricing_attrib_tab     csi_datastructures_pub.pricing_attribs_tbl;
    l_org_assignments_tab    csi_datastructures_pub.organization_units_tbl;
    l_asset_assignment_tab   csi_datastructures_pub.instance_asset_tbl;
    l_txn_rec                csi_datastructures_pub.transaction_rec;
    l_instance_id_tab        csi_datastructures_pub.id_tbl;
    -- 戻り値格納用
    lv_return_status         VARCHAR2(1);
    ln_msg_count             NUMBER;
    lv_msg_data              VARCHAR2(2000);
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    l_iea_val_rec            csi_iea_values%ROWTYPE;
--
    -- *** ローカル・テーブル ***
    TYPE l_iea_val_ttype     IS TABLE OF csi_iea_values%ROWTYPE INDEX BY BINARY_INTEGER;
    l_iea_val_tab            l_iea_val_ttype;
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
    -- 物件ロック取得
    --=========================================
    BEGIN
      SELECT cii.instance_id              AS  instance_id            -- インスタンスID
           , cii.object_version_number    AS  object_version_number  -- オブジェクトバージョン番号
      INTO   gt_instance_id
           , lt_object_version_number
      FROM   csi_item_instances  cii -- 物件マスタ
      WHERE  cii.external_reference = iv_install_code -- 物件コード
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      WHEN global_lock_expt THEN
        -- ロックエラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_msg_cso_00241  -- ロックエラー
                      ,iv_token_name1  => cv_tkn_table
                      ,iv_token_value1 => cv_msg_cso_00714  -- '物件マスタ'
                      ,iv_token_name2  => cv_tkn_item
                      ,iv_token_value2 => cv_msg_cso_00696  -- '物件コード'
                      ,iv_token_name3  => cv_tkn_base_value
                      ,iv_token_value3 => iv_install_code   -- 物件コード
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --=========================================
    -- 追加属性値情報取得
    --=========================================
    -- 機器状態３（廃棄情報）
    l_iea_val_tab(1) := xxcso_ib_common_pkg.get_ib_ext_attrib_info2(
                          in_instance_id    => gt_instance_id            -- インスタンスID
                         ,iv_attribute_code => cv_attr_cd_jotai_kbn3     -- 属性定義
                        );
--
    -- 廃棄フラグ
    l_iea_val_tab(2) := xxcso_ib_common_pkg.get_ib_ext_attrib_info2(
                          in_instance_id    => gt_instance_id            -- インスタンスID
                         ,iv_attribute_code => cv_attr_cd_ven_haiki_flg  -- 属性定義
                        );
--
    -- 廃棄決裁日
    l_iea_val_tab(3) := xxcso_ib_common_pkg.get_ib_ext_attrib_info2(
                          in_instance_id    => gt_instance_id            -- インスタンスID
                         ,iv_attribute_code => cv_attr_cd_haikikessai_dt -- 属性定義
                        );
--
    --=========================================
    -- 設置機器拡張属性値情報テーブル編集
    --=========================================
    -- 機器状態３（廃棄情報）
    l_ext_attrib_values_tab(1).attribute_value_id      := l_iea_val_tab(1).attribute_value_id;
    l_ext_attrib_values_tab(1).attribute_value         := cv_jotai_kbn3_ablsh_desc;
    l_ext_attrib_values_tab(1).object_version_number   := l_iea_val_tab(1).object_version_number;
--
    -- 廃棄フラグ
    IF ( l_iea_val_tab(2).attribute_value_id IS NOT NULL ) THEN
      l_ext_attrib_values_tab(2).attribute_value_id    := l_iea_val_tab(2).attribute_value_id;
      l_ext_attrib_values_tab(2).attribute_value       := cv_ablsh_flg_ablsh_desc;
      l_ext_attrib_values_tab(2).object_version_number := l_iea_val_tab(2).object_version_number;
    ELSE
      l_ext_attrib_values_tab(2).attribute_id          := g_ib_ext_attr_id_rec.abolishment_flag;
      l_ext_attrib_values_tab(2).instance_id           := gt_instance_id;
      l_ext_attrib_values_tab(2).attribute_value       := cv_ablsh_flg_ablsh_desc;
    END IF;
--
    -- 廃棄決裁日
    IF ( l_iea_val_tab(3).attribute_value_id IS NOT NULL ) THEN
      l_ext_attrib_values_tab(3).attribute_value_id    := l_iea_val_tab(3).attribute_value_id;
      l_ext_attrib_values_tab(3).attribute_value       := TO_CHAR(TRUNC( gd_process_date ),'YYYY/MM/DD');
      l_ext_attrib_values_tab(3).object_version_number := l_iea_val_tab(3).object_version_number;
    ELSE
      l_ext_attrib_values_tab(3).attribute_id          := g_ib_ext_attr_id_rec.abolishment_decision_date;
      l_ext_attrib_values_tab(3).instance_id           := gt_instance_id;
      l_ext_attrib_values_tab(3).attribute_value       := TO_CHAR(TRUNC( gd_process_date ),'YYYY/MM/DD');
    END IF;
--
    --=========================================
    -- インスタンスレコード編集
    --=========================================
    l_instance_rec.instance_id            := gt_instance_id;
    l_instance_rec.object_version_number  := lt_object_version_number;
    l_instance_rec.request_id             := fnd_global.conc_request_id;
    l_instance_rec.program_application_id := fnd_global.prog_appl_id;
    l_instance_rec.program_id             := fnd_global.conc_program_id;
    l_instance_rec.program_update_date    := SYSDATE;
    l_instance_rec.instance_status_id     := gt_instance_status_id;
--
    --=========================================
    -- 取引レコード編集
    --=========================================
    l_txn_rec.transaction_date        := SYSDATE;
    l_txn_rec.source_transaction_date := SYSDATE;
    l_txn_rec.transaction_type_id     := gt_transaction_type_id;
--
    --=========================================
    -- 物件情報更新
    --=========================================
    -- IB更新用標準API
    CSI_ITEM_INSTANCE_PUB.UPDATE_ITEM_INSTANCE(
      p_api_version           => cn_api_version
     ,p_commit                => cv_commit_false
     ,p_init_msg_list         => cv_init_msg_list_true
     ,p_validation_level      => ln_validation_level
     ,p_instance_rec          => l_instance_rec
     ,p_ext_attrib_values_tbl => l_ext_attrib_values_tab
     ,p_party_tbl             => l_party_tab
     ,p_account_tbl           => l_account_tab
     ,p_pricing_attrib_tbl    => l_pricing_attrib_tab
     ,p_org_assignments_tbl   => l_org_assignments_tab
     ,p_asset_assignment_tbl  => l_asset_assignment_tab
     ,p_txn_rec               => l_txn_rec
     ,x_instance_id_lst       => l_instance_id_tab
     ,x_return_status         => lv_return_status
     ,x_msg_count             => ln_msg_count
     ,x_msg_data              => lv_msg_data
    );
    -- APIが正常終了でない場合
    IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name           -- アプリケーション短縮名
                    ,iv_name         => cv_msg_cso_00380      -- プロファイル取得エラーメッセージ
                    ,iv_token_name1  => cv_tkn_bukken         -- トークンコード1
                    ,iv_token_value1 => iv_install_code       -- トークン値1
                    ,iv_token_name2  => cv_tkn_api_err_msg    -- トークンコード2
                    ,iv_token_value2 => lv_msg_data           -- トークン値2
                   );
      lv_errbuf := lv_errmsg;
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
  END upd_install_info;
--
  /**********************************************************************************
   * Procedure Name   : ins_bulk_disp_proc
   * Description      : 一括廃棄連携対象テーブル登録(A-7)
   ***********************************************************************************/
  PROCEDURE ins_bulk_disp_proc(
     iv_install_code IN  VARCHAR2          --   物件コード
    ,ov_errbuf       OUT VARCHAR2          --   エラー・メッセージ           --# 固定 #
    ,ov_retcode      OUT VARCHAR2          --   リターン・コード             --# 固定 #
    ,ov_errmsg       OUT VARCHAR2)         --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_bulk_disp_proc'; -- プログラム名
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
    --=========================================
    -- 一括廃棄連携対象テーブル登録
    --=========================================
    BEGIN
      INSERT INTO xxcso_wk_bulk_disposal_proc (
        instance_id            -- 物件ID
       ,interface_flag         -- 連携済フラグ
       ,interface_date         -- 連携日
       ,created_by             -- 作成者
       ,creation_date          -- 作成日
       ,last_updated_by        -- 最終更新者
       ,last_update_date       -- 最終更新日
       ,last_update_login      -- 最終更新ログイン
       ,request_id             -- 要求ID
       ,program_application_id -- コンカレント・プログラム・アプリケーションID
       ,program_id             -- コンカレント・プログラムID
       ,program_update_date    -- プログラム更新日
      ) VALUES (
        gt_instance_id            -- 物件ID
       ,cv_no                     -- 連携済フラグ
       ,NULL                      -- 連携日
       ,cn_created_by             -- 作成者
       ,cd_creation_date          -- 作成日
       ,cn_last_updated_by        -- 最終更新者
       ,cd_last_update_date       -- 最終更新日
       ,cn_last_update_login      -- 最終更新ログイン
       ,cn_request_id             -- 要求ID
       ,cn_program_application_id -- コンカレント・プログラム・アプリケーションID
       ,cn_program_id             -- コンカレント・プログラムID
       ,cd_program_update_date    -- プログラム更新日
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name           -- アプリケーション短縮名
                      ,iv_name         => cv_msg_cso_00773      -- プロファイル取得エラーメッセージ
                      ,iv_token_name1  => cv_tkn_table          -- トークンコード1
                      ,iv_token_value1 => cv_msg_cso_00778      -- トークン値1
                      ,iv_token_name2  => cv_tkn_item           -- トークンコード2
                      ,iv_token_value2 => cv_msg_cso_00696      -- トークン値2
                      ,iv_token_name3  => cv_tkn_value          -- トークンコード3
                      ,iv_token_value3 => iv_install_code       -- トークン値3
                      ,iv_token_name4  => cv_tkn_err_msg        -- トークンコード4
                      ,iv_token_value4 => SQLERRM               -- トークン値4
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
  END ins_bulk_disp_proc;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
     iv_file_id    IN  VARCHAR2     -- 1.ファイルID
    ,iv_fmt_ptn    IN  VARCHAR2     -- 2.フォーマットパターン
    ,ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
    ,ov_errmsg     OUT VARCHAR2)    --   ユーザー・エラー・メッセージ --# 固定 #
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
    gv_kbn                 := NULL; -- 区分
    gt_transaction_type_id := NULL; -- 取引タイプID
    gt_instance_id         := NULL; -- インスタンスID
    gt_instance_status_id  := NULL; -- インスタンスステータスID
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- 区分の判定
    IF ( iv_fmt_ptn = cv_fmt_ptn_check ) THEN
      -- チェック
      gv_kbn := cv_kbn_1;
    ELSE
      -- 更新
      gv_kbn := cv_kbn_2;
    END IF;
--
    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    init(
       iv_file_id => iv_file_id   -- ファイルID
      ,iv_fmt_ptn => iv_fmt_ptn   -- フォーマットパターン
      ,ov_errbuf  => lv_errbuf    -- エラー・メッセージ           --# 固定 #
      ,ov_retcode => lv_retcode   -- リターン・コード             --# 固定 #
      ,ov_errmsg  => lv_errmsg    -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ファイルアップロードIFデータ抽出(A-2)
    -- ===============================
    get_upload_if(
       in_file_id      => TO_NUMBER(iv_file_id) -- ファイルID
      ,ov_errbuf       => lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode         -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      -- 終了ステータス：警告
      ov_retcode := lv_retcode;
    END IF;
--
    -- ===============================
    -- ファイルアップロードIFデータ削除(A-3)
    -- ===============================
    delete_upload_if(
       in_file_id  =>  TO_NUMBER(iv_file_id) -- ファイルID
      ,ov_errbuf   =>  lv_errbuf       -- エラー・メッセージ           --# 固定 #
      ,ov_retcode  =>  lv_retcode      -- リターン・コード             --# 固定 #
      ,ov_errmsg   =>  lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSE
      -- 削除が成功した場合はコミット
      COMMIT;
    END IF;
--
    -- エラーが発生していない場合
    IF ( ov_retcode = cv_status_normal ) THEN
      -- 処理区分チェックループ
      <<proc_kbn_check_loop>>
      FOR ln_loop_cnt IN g_sep_data_tab.FIRST .. g_sep_data_tab.LAST LOOP
--
        -- ===============================
        -- 処理区分チェック(A-4)
        -- ===============================
        proc_kbn_check(
           iv_proc_kbn     => g_sep_data_tab(ln_loop_cnt)(cn_col_proc_kbn) -- 処理区分
          ,in_loop_cnt     => ln_loop_cnt  -- ループカウンタ
          ,ov_errbuf       => lv_errbuf    -- エラー・メッセージ           --# 固定 #
          ,ov_retcode      => lv_retcode   -- リターン・コード             --# 固定 #
          ,ov_errmsg       => lv_errmsg    -- ユーザー・エラー・メッセージ --# 固定 #
        );
--
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lv_retcode = cv_status_warn) THEN
          -- 件数設定
          gn_target_cnt := 0;
          gn_warn_cnt   := gn_warn_cnt + 1;
          -- 終了ステータス：警告
          ov_retcode := lv_retcode;
          -- ループ終了
          EXIT;
        END IF;
--
      END LOOP proc_kbn_check_loop;
--
      -- エラーが発生していない場合
      IF ( ov_retcode = cv_status_normal ) THEN
        -- 妥当性チェックループ
        <<validation_loop>>
        FOR ln_loop_cnt IN g_sep_data_tab.FIRST .. g_sep_data_tab.LAST LOOP
--
          -- ===============================
          -- データ妥当性チェック(A-5)
          -- ===============================
          data_validation(
             iv_install_code => g_sep_data_tab(ln_loop_cnt)(cn_col_install_code) -- 物件コード
            ,in_loop_cnt     => ln_loop_cnt    -- ループカウンタ
            ,ov_errbuf       => lv_errbuf      -- エラー・メッセージ           --# 固定 #
            ,ov_retcode      => lv_retcode     -- リターン・コード             --# 固定 #
            ,ov_errmsg       => lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
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
          -- 区分が'2'（更新）の場合は物件情報を更新
          IF ( gv_kbn = cv_kbn_2 ) THEN
            -- 物件更新ループ
            <<upd_install_info_loop>>
            FOR ln_loop_cnt IN g_sep_data_tab.FIRST .. g_sep_data_tab.LAST LOOP
--
              -- ===============================
              -- 物件情報更新(A-6)
              -- ===============================
              upd_install_info(
                 iv_install_code => g_sep_data_tab(ln_loop_cnt)(cn_col_install_code) -- 物件コード
                ,ov_errbuf       => lv_errbuf          -- エラー・メッセージ           --# 固定 #
                ,ov_retcode      => lv_retcode         -- リターン・コード             --# 固定 #
                ,ov_errmsg       => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
              );
              IF (lv_retcode = cv_status_error) THEN
                RAISE global_process_expt;
              END IF;
--
              -- ===============================
              -- 一括廃棄連携対象テーブル登録(A-7)
              -- ===============================
              ins_bulk_disp_proc(
                 iv_install_code => g_sep_data_tab(ln_loop_cnt)(cn_col_install_code) -- 物件コード
                ,ov_errbuf       => lv_errbuf          -- エラー・メッセージ           --# 固定 #
                ,ov_retcode      => lv_retcode         -- リターン・コード             --# 固定 #
                ,ov_errmsg       => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
              );
              IF (lv_retcode = cv_status_error) THEN
                RAISE global_process_expt;
              END IF;
--
              -- 成功件数設定（更新用）
              IF ( gv_kbn = cv_kbn_2 ) THEN
                gn_normal_cnt := gn_normal_cnt + 1;
              END IF;
--
            END LOOP upd_install_info_loop;
--
          END IF;
        END IF;
--
      -- 成功件数設定（チェック用）
      IF ( gv_kbn = cv_kbn_1 ) THEN
        gn_normal_cnt := gn_target_cnt - gn_warn_cnt;
      END IF;
--
      END IF;
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
     errbuf        OUT VARCHAR2      --   エラー・メッセージ  --# 固定 #
    ,retcode       OUT VARCHAR2      --   リターン・コード    --# 固定 #
    ,iv_file_id    IN  VARCHAR2      -- 1.ファイルID
    ,iv_fmt_ptn    IN  VARCHAR2)      -- 2.フォーマットパターン
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
       iv_file_id => iv_file_id   -- 1.ファイルID
      ,iv_fmt_ptn => iv_fmt_ptn   -- 2.フォーマットパターン
      ,ov_errbuf  => lv_errbuf    --   エラー・メッセージ           --# 固定 #
      ,ov_retcode => lv_retcode   --   リターン・コード             --# 固定 #
      ,ov_errmsg  => lv_errmsg    --   ユーザー・エラー・メッセージ --# 固定 #
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
END XXCSO011A06C;
/
