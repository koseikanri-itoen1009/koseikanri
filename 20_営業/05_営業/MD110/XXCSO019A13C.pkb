CREATE OR REPLACE PACKAGE BODY XXCSO019A13C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2018. All rights reserved.
 *
 * Package Name     : XXCSO019A13C(body)
 * Description      : ルートNo／営業員一括更新アップロード
 * MD.050           : 見積書アップロード MD050_CSO_017_A07
 * Version          : 1.1
 *
 * Program List
 * ------------------------- ----------------------------------------------------------
 *  Name                      Description
 * ------------------------- ----------------------------------------------------------
 *  init                      初期処理(A-1)
 *  get_upload_data           ファイルアップロードIFデータ抽出(A-2)
 *  get_check_spec            入力データチェック仕様取得(A-3)
 *  fnc_check_data            入力データチェック処理(A-4)
 *  check_input_data          入力データチェック(A-5)
 *  ins_route_emp_upload_work ルートNo／営業員アップロード中間テーブル登録(A-6)
 *  check_business_data       業務エラーチェック(A-7)
 *  reflect_route_emp         ルートNo／営業担当更新反映処理(A-8)
 *  delete_file_ul_if         ファイルアップロードIFデータ削除(A-9)
 *  submain                   メイン処理プロシージャ
 *  main                      コンカレント実行ファイル登録プロシージャ・終了処理(A-10)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2018/04/19    1.0   K.Kiriu          新規作成(E_本稼動_14722)
 *  2019/04/25    1.1   T.Kawaguchi      E_本稼動_15683【営業】ルート一括更新障害対応
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
  global_lock_expt                EXCEPTION;  -- ロック例外
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                         CONSTANT VARCHAR2(100) := 'XXCSO019A13C';      -- パッケージ名
--
  cv_app_name                         CONSTANT VARCHAR2(30)  := 'XXCSO';             -- アプリケーション短縮名
--
  -- メッセージ
  cv_msg_file_id                      CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00271';  -- ファイルID
  cv_msg_fmt_ptn                      CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00275';  -- フォーマットパターン
  cv_msg_param_required               CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00325';  -- パラメータ必須エラー
  cv_input_param_nm_file_id           CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00673';  -- 文言（ファイルID）
  cv_input_param_nm_fmt_ptn           CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00674';  -- 文言（フォーマットパターン）
  cv_msg_err_param_valuel             CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00252';  -- パラメータ妥当性チェックエラー
  cv_msg_err_get_data_ul              CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00274';  -- データ抽出エラー
  cv_msg_file_ul_name                 CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00276';  -- ファイルアップロード名称
  cv_msg_file_name                    CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00152';  -- CSVファイル名
  cv_msg_err_get_lock                 CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00278';  -- ロックエラー
  cv_msg_err_get_data                 CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00554';  -- データ抽出エラー
  cv_msg_err_get_proc_date            CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00011';  -- 業務処理日付取得エラー
  cv_msg_err_get_profile              CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00014';  -- プロファイル取得エラー
  cv_msg_err_no_data                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00399';  -- 対象件数0件メッセージ
  cv_msg_err_file_fmt                 CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00846';  -- ルートNo／営業員CSVフォーマットエラーメッセージ
  cv_msg_err_get_user_base            CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00847';  -- 所属拠点取得エラーメッセージ
  cv_msg_err_get_base                 CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00848';  -- 拠点取得エラーメッセージ
  cv_tbl_nm_file_ul_if                CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00676';  -- 文言（ファイルアップロードIF）
  cv_msg_err_required                 CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00403';  -- 必須項目エラー（複数行）
  cv_msg_err_no_ref_method            CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00849';  -- 反映方法チェックエラーメッセージ
  cv_msg_err_ins_data                 CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00471';  -- データ登録エラー
  cv_tbl_nm_work                      CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00850';  -- 文言（ルートNo／営業員アップロード中間テーブル）
  cv_msg_err_invalid                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00622';  -- 型・桁数チェックエラーメッセージ
  cv_msg_err_dup_cust                 CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00851';  -- 顧客重複エラーメッセージ
  cv_msg_err_no_cust                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00852';  -- 顧客取得エラーメッセージ
  cv_msg_err_class_status             CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00853';  -- 顧客区分・ステータス対象外エラーメッセージ
  cv_msg_err_cust_resouce             CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00854';  -- 顧客担当取得エラーメッセージ
  cv_msg_err_dup_resouce              CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00855';  -- 担当営業員重複エラーメッセージ
  cv_msg_err_no_update                CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00856';  -- 更新内容なしエラーメッセージ
  cv_msg_err_route_chack              CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00857';  -- ルートNo妥当性チェックエラー
  cv_msg_err_reflect_method           CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00858';  -- 反映方法指定エラー
  cv_msg_err_cust_inadequacy          CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00861';  -- 顧客設定不備エラー
  cv_route_date                       CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00859';  -- 文言（新ルートNo）
  cv_emp_date                         CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00860';  -- 文言（新担当）
  cv_msg_err_security                 CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00862';  -- 顧客セキュリティエラー
  cv_msg_immediate                    CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00863';  -- 文言（即時）
  cv_msg_reservation                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00864';  -- 文言（予約）
  cv_msg_err_emp_base                 CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00865';  -- 担当セキュリティエラー
  cv_msg_err_trgt_emp_base            CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00871';  -- 現担当取得エラー
  cv_msg_err_payment_cust_route       CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00866';  -- 売掛金管理先顧客ルートNo設定エラー
  cv_msg_err_payment_reflect          CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00867';  -- 売掛金管理先顧客反映方法エラー
  cv_msg_err_payment_emp              CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00869';  -- 売掛金管理先顧客新担当必須エラー
  cv_msg_err_payment_base             CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00868';  -- 売掛金管理先顧客入金必須エラー
  cv_msg_err_common_pkg               CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00870';  -- ルートNo／担当営業共通関数エラーメッセージ
  cv_msg_insert                       CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00702';  -- 文言（登録）
  cv_msg_err_del_data                 CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00872';  -- データ削除エラー
  cv_msg_err_lock_data                CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00874';  -- ロックエラー
  cv_msg_table_hopeb                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00875';  -- 文言(組織プロファイル拡張）
  cv_msg_trgt_route_date              CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00876';  -- 文言(現担当）
  cv_msg_trgt_emp_date                CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00877';  -- 文言(現ルートNo）
  cv_msg_delete                       CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00879';  -- 文言（削除）
  cv_msg_err_no_base                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00880';  -- 所属拠点設定なしエラーメッセージ
  cv_msg_err_rcv_security             CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00881';  -- 顧客セキュリティエラー（売掛金管理先）
  cv_msg_err_rcv_emp_base             CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00882';  -- 担当セキュリティエラー（売掛金管理先）
--
  --メッセージトークン
  cv_tkn_file_id                      CONSTANT VARCHAR2(7)   := 'FILE_ID';
  cv_tkn_fmt_ptn                      CONSTANT VARCHAR2(14)  := 'FORMAT_PATTERN';
  cv_tkn_param_name                   CONSTANT VARCHAR2(10)  := 'PARAM_NAME';
  cv_tkn_item                         CONSTANT VARCHAR2(4)   := 'ITEM';
  cv_tkn_file_ul_name                 CONSTANT VARCHAR2(16)  := 'UPLOAD_FILE_NAME';
  cv_tkn_file_name                    CONSTANT VARCHAR2(13)  := 'CSV_FILE_NAME';
  cv_tkn_table                        CONSTANT VARCHAR2(5)   := 'TABLE';
  cv_tkn_err_msg                      CONSTANT VARCHAR2(7)   := 'ERR_MSG';
  cv_tkn_profile_name                 CONSTANT VARCHAR2(9)   := 'PROF_NAME';
  cv_tkn_column                       CONSTANT VARCHAR2(6)   := 'COLUMN';
  cv_tkn_index                        CONSTANT VARCHAR2(5)   := 'INDEX';
  cv_tkn_data_div_val                 CONSTANT VARCHAR2(12)  := 'DATA_DIV_VAL';
  cv_tkn_error_message                CONSTANT VARCHAR2(13)  := 'ERROR_MESSAGE';
  cv_tkn_action                       CONSTANT VARCHAR2(6)   := 'ACTION';
  cv_tkn_account                      CONSTANT VARCHAR2(11)  := 'ACCOUNT_NUM';
  cv_tkn_class                        CONSTANT VARCHAR2(5)   := 'CLASS';
  cv_tkn_status                       CONSTANT VARCHAR2(6)   := 'STATUS';
  cv_tkn_route                        CONSTANT VARCHAR2(5)   := 'ROUTE';
  cv_tkn_data_div                     CONSTANT VARCHAR2(8)   := 'DATA_DIV';
  cv_tkn_base_code                    CONSTANT VARCHAR2(9)   := 'BASE_CODE';
  cv_tkn_emp_code                     CONSTANT VARCHAR2(9)   := 'EMP_CODE';
--
  -- 自拠点セキュリティ
  cv_no_security                      CONSTANT VARCHAR2(1)   := '1'; -- セキュリティなし
  -- 顧客区分
  cv_base                             CONSTANT VARCHAR2(1)   := '1'; -- 拠点
  -- 参照タイプ
  cv_lkup_file_ul_obj                 CONSTANT VARCHAR2(22)  := 'XXCCP1_FILE_UPLOAD_OBJ';      -- ファイルアップロードOBJ
  cv_lkup_route_mgr_cust_class        CONSTANT VARCHAR2(27)  := 'XXCSO1_ROUTE_MGR_CUST_CLASS'; -- ルートNo管理対象顧客
  -- プロファイル
  cv_security_019_a09                 CONSTANT VARCHAR2(23)  := 'XXCSO1_SECURITY_019_A09';     -- XXCSO:ルートNo／担当営業員一括更新セキュリティ
  -- CSVファイルヘッダ行
  cn_header_rec                       CONSTANT NUMBER        := 1;
  -- CSVファイルの項目位置
  cn_col_pos_cust_div                 CONSTANT NUMBER        := 1;   -- 顧客区分
  cn_col_pos_cust_code                CONSTANT NUMBER        := 2;   -- 顧客コード
  cn_col_pos_cust_name                CONSTANT NUMBER        := 3;   -- 顧客名
  cn_col_pos_now_emp                  CONSTANT NUMBER        := 4;   -- 現担当
  cn_col_pos_now_route                CONSTANT NUMBER        := 5;   -- 現ルートNo
  cn_col_pos_new_emp                  CONSTANT NUMBER        := 6;   -- 新担当
  cn_col_pos_new_route                CONSTANT NUMBER        := 7;   -- 新ルートNo
  cn_col_pos_reflect_method           CONSTANT NUMBER        := 8;   -- 反映方法
  -- CSVファイルの項目長
  cn_col_length_cust_code             CONSTANT NUMBER        := 9;   -- 顧客コード
  cn_col_length_new_emp               CONSTANT NUMBER        := 5;   -- 新担当
  cn_col_length_new_route             CONSTANT NUMBER        := 7;   -- 新ルートNo
  cn_col_length_reflect_method        CONSTANT NUMBER        := 1;   -- 反映方法
  -- 反映方法
  cv_immediate                        CONSTANT VARCHAR2(1)   := '1'; -- 即時
  cv_reservation                      CONSTANT VARCHAR2(1)   := '2'; -- 予約
  -- 削除
  cv_delete                           CONSTANT VARCHAR2(1)   := '-'; -- 削除
  -- 作成・更新、削除区分
  cv_ins_upd                          CONSTANT VARCHAR2(1)   := 'I'; -- 作成・更新
  cv_del                              CONSTANT VARCHAR2(1)   := 'D'; -- 削除
  -- 汎用
  cv_lang                             CONSTANT VARCHAR2(2)   := USERENV('LANG');  -- 言語
  cv_enabled                          CONSTANT VARCHAR2(1)   := 'Y';              -- 有効
  cv_month_format                     CONSTANT VARCHAR2(2)   := 'MM';             -- 日付フォーマット(月)
  cv_yes                              CONSTANT VARCHAR2(1)   := 'Y';              -- yes
  cv_no                               CONSTANT VARCHAR2(1)   := 'N';              -- no
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- ユーザーの自拠点コード
  TYPE gt_base_code_ttype IS TABLE OF hz_cust_accounts.account_number%TYPE INDEX BY BINARY_INTEGER;
  gt_base_code_tab  gt_base_code_ttype;
  -- アップロードデータ分割取得用
  TYPE gt_col_data_ttype  IS TABLE OF VARCHAR(1000)     INDEX BY BINARY_INTEGER;  --1次元配列（項目）
  TYPE gt_rec_data_ttype  IS TABLE OF gt_col_data_ttype INDEX BY BINARY_INTEGER;  --2次元配列（レコード）（項目）
  -- ルートNo/営業担当反映データ取得要
  TYPE gt_ref_route_emp_rtype IS RECORD(
     line_no                     xxcso_tmp_rtn_rsrc_work.line_no%TYPE              -- 行番号
    ,account_number              xxcso_tmp_rtn_rsrc_work.account_number%TYPE       -- 顧客コード
    ,new_employee_number         xxcso_tmp_rtn_rsrc_work.new_employee_number%TYPE  -- 新担当
    ,new_employee_date           DATE                                              -- 新担当適用開始日
    ,trgt_resource_id            hz_org_profiles_ext_b.extension_id%TYPE           -- 新担当拡張ID
    ,next_resource_id            hz_org_profiles_ext_b.extension_id%TYPE           -- 現担当拡張ID
    ,new_route_no                xxcso_tmp_rtn_rsrc_work.new_route_no%TYPE         -- 新ルートNo
    ,new_route_date              DATE                                              -- 新ルートNo適用開始日
    ,trgt_route_id               hz_org_profiles_ext_b.extension_id%TYPE           -- 新ルートNo拡張ID
    ,next_route_id               hz_org_profiles_ext_b.extension_id%TYPE           -- 現ルートNo拡張ID
    ,employee_change_flag        VARCHAR2(1)                                       -- 担当変更フラグ
    ,route_no_change_flag        VARCHAR2(1)                                       -- ルートNo変更フラグ
  );
  TYPE gt_ref_route_emp_ttype IS TABLE OF gt_ref_route_emp_rtype INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_process_date        DATE;                             -- 業務処理日付
  gd_first_day_date      DATE;                             -- 業務処理日付１日
  gd_next_month_date     DATE;                             -- 業務処理日付翌月1日
  gv_security_019_a09    VARCHAR2(1);                      -- ルートNo／担当営業員一括更新セキュリティ
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     iv_file_id    IN  VARCHAR2  -- 1.ファイルID
    ,iv_fmt_ptn    IN  VARCHAR2  -- 2.フォーマットパターン
    ,on_file_id    OUT NUMBER    -- 3.ファイルID（型変換後）
    ,ov_errbuf     OUT VARCHAR2  --   エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT VARCHAR2  --   リターン・コード             --# 固定 #
    ,ov_errmsg     OUT VARCHAR2  --   ユーザー・エラー・メッセージ --# 固定 #
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
--
    -- *** ローカル変数 ***
    lv_msg           VARCHAR2(5000);                              -- メッセージ
    lt_file_ul_name  fnd_lookup_values.meaning%TYPE;              -- ファイルアップロード名称
    lt_file_name     xxccp_mrp_file_ul_interface.file_name%TYPE;  -- CSVファイル名
    lt_base_code     hz_cust_accounts.account_number%TYPE;        -- ユーザー所属拠点
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==================================================
    -- 1.パラメータ出力
    --==================================================
    -- ファイルIDメッセージ
    lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name
                   ,iv_name         => cv_msg_file_id
                   ,iv_token_name1  => cv_tkn_file_id
                   ,iv_token_value1 => iv_file_id
                 );
    -- ファイルIDメッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg
    );
--
    -- フォーマットパターンメッセージ
    lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name
                   ,iv_name         => cv_msg_fmt_ptn
                   ,iv_token_name1  => cv_tkn_fmt_ptn
                   ,iv_token_value1 => iv_fmt_ptn
                 );
    -- フォーマットパターンメッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg
    );
--
    --==================================================
    -- 2.パラメータのチェック
    --==================================================
    -- パラメータ．ファイルIDの必須入力チェック
    IF (iv_file_id IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_param_required
                     ,iv_token_name1  => cv_tkn_param_name
                     ,iv_token_value1 => cv_input_param_nm_file_id
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- パラメータ．ファイルIDの型チェック(数値型に変換できない場合はエラー)
    IF (NOT xxcop_common_pkg.chk_number_format(iv_file_id)) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_err_param_valuel
                     ,iv_token_name1  => cv_tkn_item
                     ,iv_token_value1 => cv_input_param_nm_file_id
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ファイルIDの型変換
    on_file_id := TO_NUMBER(iv_file_id);
--
    -- パラメータ．フォーマットパターンの必須入力チェック
    IF (iv_fmt_ptn IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_param_required
                     ,iv_token_name1  => cv_tkn_param_name
                     ,iv_token_value1 => cv_input_param_nm_fmt_ptn
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --==================================================
    -- 3.業務日付の取得
    --==================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    --業務処理日付取得チェック
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_err_get_proc_date
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 業務日付の１日を取得
    gd_first_day_date   := TRUNC(gd_process_date, cv_month_format );
    -- 業務日付の翌月1日を取得
    gd_next_month_date  := TRUNC( ADD_MONTHS( gd_process_date, 1 ), cv_month_format );
--
    --==================================================
    -- 4.ファイルアップロード名・ファイル名の出力
    --==================================================
    BEGIN
      -- ファイルアップロード名称
      SELECT flv.meaning  meaning
      INTO   lt_file_ul_name
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_type  = cv_lkup_file_ul_obj
      AND    flv.lookup_code  = iv_fmt_ptn
      AND    flv.language     = cv_lang
      AND    flv.enabled_flag = cv_enabled
      AND    gd_process_date  BETWEEN flv.start_date_active
                              AND     NVL(flv.end_date_active, gd_process_date)
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_get_data_ul
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    -- ファイルアップロード名称メッセージ
    lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name
                   ,iv_name         => cv_msg_file_ul_name
                   ,iv_token_name1  => cv_tkn_file_ul_name
                   ,iv_token_value1 => TO_CHAR(lt_file_ul_name)
                 );
    -- ファイルアップロード名称メッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg
    );
--
    BEGIN
      --CSVファイル名
      SELECT xmfui.file_name file_name
      INTO   lt_file_name
      FROM   xxccp_mrp_file_ul_interface xmfui
      WHERE  xmfui.file_id = on_file_id
      FOR UPDATE NOWAIT
      ;
      -- CSVファイル名メッセージ
      lv_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_file_name
                     ,iv_token_name1  => cv_tkn_file_name
                     ,iv_token_value1 => lt_file_name
                   );
      -- CSVファイル名メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_msg
      );
      --空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
    EXCEPTION
      WHEN global_lock_expt THEN -- ロック取得失敗
        --ロックエラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_get_lock
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => cv_tbl_nm_file_ul_if
                       ,iv_token_name2  => cv_tkn_err_msg
                       ,iv_token_value2 => SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      WHEN OTHERS THEN
        --データ抽出エラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_get_data
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => cv_tbl_nm_file_ul_if
                       ,iv_token_name2  => cv_tkn_file_id
                       ,iv_token_value2 => on_file_id
                       ,iv_token_name3  => cv_tkn_err_msg
                       ,iv_token_value3 => SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --==================================================
    -- 5.プロファイルオプションの取得
    --==================================================
    -- XXCSO:ルートNo／担当営業員一括更新セキュリティ
    gv_security_019_a09 := FND_PROFILE.VALUE(cv_security_019_a09);
    IF ( gv_security_019_a09 IS NULL ) THEN
      -- プロファイル取得チェック
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_err_get_profile
                     ,iv_token_name1  => cv_tkn_profile_name
                     ,iv_token_value1 => cv_security_019_a09
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --==================================================
    -- 6.自拠点の取得(自拠点セキュリティ有りの場合)
    --==================================================
    IF ( gv_security_019_a09 <> cv_no_security ) THEN
      -- ユーザーの自拠点取得(リソースより取得)
      BEGIN
        SELECT xxcso_util_common_pkg.get_rs_base_code(
                  xrv.resource_id
                 ,gd_process_date
               ) base_code
        INTO   lt_base_code
        FROM   xxcso_resources_v2 xrv
        WHERE  xrv.user_id = cn_created_by
        ;
      EXCEPTION
        WHEN OTHERS THEN
          -- ユーザーの自拠点取得失敗
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_err_get_user_base
                         ,iv_token_name1  => cv_tkn_err_msg
                         ,iv_token_value1 => SQLERRM
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
--
      -- 取得した所属拠点がNULLでないかチェック
      IF ( lt_base_code IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_no_base
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
--
      -- 自拠点（管理元の場合、配下の拠点も含む）を取得
      BEGIN
        SELECT xcav.account_number base_code
        BULK COLLECT INTO
               gt_base_code_tab
        FROM   xxcso_cust_accounts_v xcav
        WHERE  xcav.customer_class_code = cv_base
        AND    xcav.account_number      = lt_base_code
        UNION
        SELECT xcav.account_number base_code
        FROM   xxcso_cust_accounts_v xcav
        WHERE  xcav.customer_class_code  = cv_base
        AND    xcav.management_base_code = lt_base_code
        ;
      EXCEPTION
        WHEN OTHERS THEN
          -- 拠点取得失敗
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_err_get_base
                         ,iv_token_name1  => cv_tkn_err_msg
                         ,iv_token_value1 => SQLERRM
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    END IF;
--
  EXCEPTION
    --*** 処理エラー例外 ***
    WHEN global_process_expt THEN
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_upload_data
   * Description      : ファイルアップロードIFデータ抽出(A-2)
   ***********************************************************************************/
  PROCEDURE get_upload_data(
     in_file_id            IN  NUMBER             -- 1.ファイルID
    ,ot_route_emp_data_tab OUT gt_rec_data_ttype  --   ルートNo/営業員データ配列
    ,ov_errbuf             OUT VARCHAR2           --   エラー・メッセージ           --# 固定 #
    ,ov_retcode            OUT VARCHAR2           --   リターン・コード             --# 固定 #
    ,ov_errmsg             OUT VARCHAR2           --   ユーザー・エラー・メッセージ --# 固定 #
  )
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
    cv_col_separator     CONSTANT VARCHAR2(10) := ',';  -- 項目区切文字
    cn_csv_file_col_num  CONSTANT NUMBER       := 8;    -- CSVファイル項目数
--
     -- *** ローカル変数 ***
    ln_col_num           NUMBER;
    ln_line_cnt          NUMBER;
    ln_column_cnt        NUMBER;
--
    -- *** ローカル・レコード ***
    l_file_data_tab      xxccp_common_pkg2.g_file_data_tbl;  -- 行単位データ格納用配列
    l_route_emp_data_tab gt_rec_data_ttype;                  -- ルートNo／営業員データ用配列
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- BLOBデータ変換関数により行単位データを抽出
    xxccp_common_pkg2.blob_to_varchar2(
       in_file_id   => in_file_id       -- ファイルID
      ,ov_file_data => l_file_data_tab  -- ファイルデータ
      ,ov_errbuf    => lv_errbuf        -- エラー・メッセージ            -- # 固定 #
      ,ov_retcode   => lv_retcode       -- リターン・コード              -- # 固定 #
      ,ov_errmsg    => lv_errmsg        -- ユーザー・エラー・メッセージ  -- # 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      -- データ抽出エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_err_get_data
                     ,iv_token_name1  => cv_tkn_table
                     ,iv_token_value1 => cv_tbl_nm_file_ul_if
                     ,iv_token_name2  => cv_tkn_file_id
                     ,iv_token_value2 => in_file_id
                     ,iv_token_name3  => cv_tkn_err_msg
                     ,iv_token_value3 => lv_errbuf
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    IF (l_file_data_tab.COUNT - cn_header_rec <= 0) THEN
      -- ヘッダ行を除いたデータが0行の場合、対象件数0件メッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_err_no_data
                   );
      -- 対象件数0件メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      gn_warn_cnt := 0;
      ov_retcode  := cv_status_warn;
      -- データ無しのため以下の処理は行わない。
      RETURN;
    END IF;
--
    gn_target_cnt := l_file_data_tab.COUNT - cn_header_rec;
--
    <<line_data_loop>>
    FOR ln_line_cnt IN 1 .. l_file_data_tab.COUNT LOOP
      -- 項目数取得
      ln_col_num := NVL(LENGTH(l_file_data_tab(ln_line_cnt)), 0)
                      - NVL(LENGTH(REPLACE(l_file_data_tab(ln_line_cnt), cv_col_separator, NULL)), 0) + 1;
      -- 項目数チェック
      IF (ln_col_num <> cn_csv_file_col_num) THEN
        -- ルートNo／営業員CSVフォーマットエラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_file_fmt
                       ,iv_token_name1  => cv_tkn_index
                       ,iv_token_value1 => ln_line_cnt - 1
                     );
        -- エラーメッセージ出力
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
--
        gn_warn_cnt := gn_warn_cnt + 1;
        ov_retcode  := cv_status_warn;
      ELSE
        <<column_loop>>
        FOR ln_column_cnt IN 1 .. cn_csv_file_col_num LOOP
          --項目分割
          l_route_emp_data_tab(ln_line_cnt)(ln_column_cnt) := xxccp_common_pkg.char_delim_partition(
                                                                 iv_char     => l_file_data_tab(ln_line_cnt)
                                                                ,iv_delim    => cv_col_separator
                                                                ,in_part_num => ln_column_cnt
                                                              );
        END LOOP column_loop;
      END IF;
    END LOOP line_loop;
--
    -- 分割データの返却
    ot_route_emp_data_tab := l_route_emp_data_tab;
--
  EXCEPTION
      --*** 処理エラー例外 ***
    WHEN global_process_expt THEN
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
  END get_upload_data;
--
  /**********************************************************************************
   * Procedure Name   : get_check_spec
   * Description      : 入力データチェック仕様取得(A-3)
   ***********************************************************************************/
  PROCEDURE get_check_spec(
     in_col_pos         IN  NUMBER    -- 1.項目位置
    ,ov_check           OUT VARCHAR2  --   チェック要否
    ,ov_allow_null      OUT VARCHAR2  --   NULL許可
    ,on_length          OUT NUMBER    --   項目長
    ,ov_errbuf          OUT VARCHAR2  --   エラー・メッセージ           --# 固定 #
    ,ov_retcode         OUT VARCHAR2  --   リターン・コード             --# 固定 #
    ,ov_errmsg          OUT VARCHAR2  --   ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_check_spec'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
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
    CASE in_col_pos
    WHEN cn_col_pos_cust_div THEN
      -- 顧客区分チェック仕様(チェック不要)
      ov_check          := cv_no;
    WHEN cn_col_pos_cust_code THEN
      -- 顧客コードチェック仕様
      ov_check          := cv_yes;
      ov_allow_null     := xxccp_common_pkg2.gv_null_ng;
      on_length         := cn_col_length_cust_code;
    WHEN cn_col_pos_cust_name THEN
      -- 顧客名チェック仕様（チェック不要）
      ov_check          := cv_no;
    WHEN cn_col_pos_now_emp THEN
       -- 現担当チェック仕様(チェック不要)
      ov_check          := cv_no;
    WHEN cn_col_pos_now_route THEN
       -- 現ルートNoチェック仕様(チェック不要)
      ov_check          := cv_no;
    WHEN cn_col_pos_new_emp THEN
       -- 新担当チェック仕様
      ov_check          := cv_yes;
      ov_allow_null     := xxccp_common_pkg2.gv_null_ok;
      on_length         := cn_col_length_new_emp;
    WHEN cn_col_pos_new_route THEN
       -- 新ルートNoチェック仕様
      ov_check          := cv_yes;
      ov_allow_null     := xxccp_common_pkg2.gv_null_ok;
      on_length         := cn_col_length_new_route;
    WHEN cn_col_pos_reflect_method THEN
       -- 反映方法チェック仕様
      ov_check          := cv_yes;
      ov_allow_null     := xxccp_common_pkg2.gv_null_ng;
      on_length         := cn_col_length_reflect_method;
    END CASE;
--
  EXCEPTION
    --*** 処理エラー例外 ***
    WHEN global_process_expt THEN
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
  END get_check_spec;
--
  /**********************************************************************************
   * Procedure Name   : fnc_check_data
   * Description      : 入力データチェック処理(A-4)
   ***********************************************************************************/
  PROCEDURE fnc_check_data(
     in_line_cnt        IN  NUMBER    -- 1.行番号
    ,iv_column          IN  VARCHAR2  -- 2.項目名
    ,iv_col_val         IN  VARCHAR2  -- 3.項目値
    ,iv_allow_null      IN  VARCHAR2  -- 4.必須チェック
    ,in_length          IN  NUMBER    -- 6.項目長
    ,ov_errbuf          OUT VARCHAR2  --   エラー・メッセージ           --# 固定 #
    ,ov_retcode         OUT VARCHAR2  --   リターン・コード             --# 固定 #
    ,ov_errmsg          OUT VARCHAR2  --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'fnc_check_data'; -- プログラム名
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
    lv_warn_flag  VARCHAR2(1);  -- 警告有りフラグ
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
    lv_warn_flag := cv_no;
--
    IF (iv_allow_null = xxccp_common_pkg2.gv_null_ng) THEN
      -- 必須入力チェック
      IF (iv_col_val IS NULL) THEN
        -- 必須項目エラー（複数行）
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_required
                       ,iv_token_name1  => cv_tkn_column
                       ,iv_token_value1 => iv_column
                       ,iv_token_name2  => cv_tkn_index
                       ,iv_token_value2 => in_line_cnt
                     );
        -- 必須項目エラー（複数行）エラーメッセージ出力
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        lv_warn_flag  := cv_yes;
      END IF;
    END IF;
--
    IF ( iv_col_val IS NOT NULL ) THEN
      -- 桁数チェック
      -- 共通関数「項目チェック」にてチェック
      xxccp_common_pkg2.upload_item_check(
         iv_item_name    => iv_column                     -- 1.項目名称(日本語名)
        ,iv_item_value   => iv_col_val                    -- 2.項目の値
        ,in_item_len     => in_length                     -- 3.項目の長さ
        ,in_item_decimal => NULL                          -- 4.項目の長さ(小数点以下)
        ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ok  -- 5.必須フラグ
        ,iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2 -- 6.項目属性
        ,ov_errbuf       => lv_errbuf                     --   エラー・メッセージ           --# 固定 #
        ,ov_retcode      => lv_retcode                    --   リターン・コード             --# 固定 #
        ,ov_errmsg       => lv_errmsg                     --   ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode <> cv_status_normal) THEN
        -- 型・桁数チェックエラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_invalid
                       ,iv_token_name1  => cv_tkn_column
                       ,iv_token_value1 => iv_column
                       ,iv_token_name2  => cv_tkn_index
                       ,iv_token_value2 => in_line_cnt
                     );
        -- 型・桁数チェックエラーメッセージ出力
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        lv_warn_flag  := cv_yes;
      END IF;
    END IF;
--
    -- ステータスの設定
    IF ( lv_warn_flag = cv_yes ) THEN
      ov_retcode   := cv_status_warn;
    END IF;
--
  EXCEPTION
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
  END fnc_check_data;
--
  /**********************************************************************************
   * Procedure Name   : check_input_data
   * Description      : 入力データチェック(A-5)
   ***********************************************************************************/
  PROCEDURE check_input_data(
     iv_fmt_ptn             IN  VARCHAR2           -- 1.フォーマットパターン
    ,it_route_emp_data_tab  IN  gt_rec_data_ttype  -- 2.ルートNo／営業員データ配列
    ,ov_errbuf              OUT VARCHAR2           --   エラー・メッセージ           --# 固定 #
    ,ov_retcode             OUT VARCHAR2           --   リターン・コード             --# 固定 #
    ,ov_errmsg              OUT VARCHAR2           --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_input_data'; -- プログラム名
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
--
    -- *** ローカル変数 ***
    ln_line_cnt    NUMBER;          -- レコード単位配列添え字
    ln_col_cnt     NUMBER;          -- 項目単位配列添え字
    lv_allow_null  VARCHAR2(30);    -- NULL許可
    ln_length      NUMBER;          -- 項目長
    lv_check       VARCHAR2(1);     -- チェック要否
    lv_warn_flag   VARCHAR2(1);     -- 警告有りフラグ
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- レコード単位のループ
    <<chk_line_loop>>
    FOR ln_line_cnt IN 2 .. it_route_emp_data_tab.COUNT LOOP
      -- 項目単位のループ
      <<chk_col_loop>>
      FOR ln_col_cnt IN 1 .. it_route_emp_data_tab(ln_line_cnt).COUNT LOOP
--
        -- 初期化
        lv_allow_null := NULL;  -- NULL許可
        ln_length     := NULL;  -- 項目長
        lv_check      := NULL;  -- チェック要否
        lv_warn_flag  := cv_no; -- 警告有りフラグ
--
        -- ===============================
        -- 入力データチェック仕様取得(A-3)
        -- ===============================
        get_check_spec(
           in_col_pos     => ln_col_cnt    -- 項目位置
          ,ov_check       => lv_check      -- チェック要否
          ,ov_allow_null  => lv_allow_null -- NULL許可
          ,on_length      => ln_length     -- 項目長
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- チェックが必要な場合のみ処理
        IF ( lv_check = cv_yes ) THEN
          -- ===============================
          -- 入力データチェック処理(A-4)
          -- ===============================
          fnc_check_data(
             in_line_cnt       => ln_line_cnt - 1
            ,iv_column         => it_route_emp_data_tab(cn_header_rec)(ln_col_cnt)
            ,iv_col_val        => it_route_emp_data_tab(ln_line_cnt)(ln_col_cnt)
            ,iv_allow_null     => lv_allow_null
            ,in_length         => ln_length
            ,ov_errbuf         => lv_errbuf
            ,ov_retcode        => lv_retcode
            ,ov_errmsg         => lv_errmsg
          );
          IF (lv_retcode = cv_status_warn) THEN
            lv_warn_flag := cv_yes;
          ELSIF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
--
        IF ( ln_col_cnt = cn_col_pos_reflect_method ) THEN
          -- 反映方法は、値の内容もチェック
          IF (
               ( it_route_emp_data_tab(ln_line_cnt)(ln_col_cnt) <> cv_immediate )   -- 即時
               AND
               ( it_route_emp_data_tab(ln_line_cnt)(ln_col_cnt) <> cv_reservation ) -- 予約
             )
          THEN
            -- データ区分チェックエラーメッセージ
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name
                            ,iv_name         => cv_msg_err_no_ref_method
                            ,iv_token_name1  => cv_tkn_data_div_val
                            ,iv_token_value1 => it_route_emp_data_tab(ln_line_cnt)(ln_col_cnt)
                            ,iv_token_name2  => cv_tkn_index
                            ,iv_token_value2 => ln_line_cnt - 1
                          );
            -- データ区分チェックエラーメッセージ出力
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
            lv_warn_flag := cv_yes;
          END IF;
--
        END IF;
--
        -- ステータス・警告件数設定
        IF ( lv_warn_flag = cv_yes ) THEN
          ov_retcode  := cv_status_warn;
          gn_warn_cnt := gn_warn_cnt + 1;
        END IF;
--
      END LOOP chk_col_loop;
--
    END LOOP chk_line_loop;
--
  EXCEPTION
    -- *** 処理エラー例外 ***
    WHEN global_process_expt THEN
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
  END check_input_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_route_emp_upload_work
   * Description      : ルートNo／営業員アップロード中間テーブル登録(A-6)
   ***********************************************************************************/
  PROCEDURE ins_route_emp_upload_work(
     in_file_id             IN  NUMBER             -- 1.ファイルID
    ,it_route_emp_data_tab  IN  gt_rec_data_ttype  -- 2.ルートNo／営業員データ配列v
    ,ov_errbuf              OUT VARCHAR2           --   エラー・メッセージ           --# 固定 #
    ,ov_retcode             OUT VARCHAR2           --   リターン・コード             --# 固定 #
    ,ov_errmsg              OUT VARCHAR2           --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_route_emp_upload_work'; -- プログラム名
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
    ln_line_cnt  NUMBER;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    <<ins_line_loop>>
    FOR ln_line_cnt IN 2 .. it_route_emp_data_tab.COUNT LOOP
      BEGIN
        INSERT INTO xxcso_tmp_rtn_rsrc_work(
           file_id
          ,line_no
          ,account_number
          ,new_route_no
          ,new_employee_number
          ,reflect_method
        ) VALUES (
           in_file_id
          ,ln_line_cnt - 1
          ,it_route_emp_data_tab(ln_line_cnt)(cn_col_pos_cust_code)
          ,it_route_emp_data_tab(ln_line_cnt)(cn_col_pos_new_route)
          ,it_route_emp_data_tab(ln_line_cnt)(cn_col_pos_new_emp)
          ,it_route_emp_data_tab(ln_line_cnt)(cn_col_pos_reflect_method)
        );
      EXCEPTION
        WHEN OTHERS THEN
          -- データ登録エラーメッセージ
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_err_ins_data
                         ,iv_token_name1  => cv_tkn_action
                         ,iv_token_value1 => cv_tbl_nm_work
                         ,iv_token_name2  => cv_tkn_error_message
                         ,iv_token_value2 => SQLERRM
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    END LOOP ins_line_loop;
--
  EXCEPTION
    --*** 処理エラー例外 ***
    WHEN global_process_expt THEN
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
  END ins_route_emp_upload_work;
--
  /**********************************************************************************
   * Procedure Name   : check_business_data
   * Description      : 業務エラーチェック(A-7)
   ***********************************************************************************/
  PROCEDURE check_business_data(
     in_file_id                 IN  NUMBER                   -- 1.ファイルID
    ,ot_ref_route_emp_data_tab  OUT gt_ref_route_emp_ttype   --   ルートNo/営業担当反映データ
    ,ov_errbuf                  OUT VARCHAR2                 --   エラー・メッセージ           --# 固定 #
    ,ov_retcode                 OUT VARCHAR2                 --   リターン・コード             --# 固定 #
    ,ov_errmsg                  OUT VARCHAR2                 --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_business_data'; -- プログラム名
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
    cv_00                      CONSTANT VARCHAR2(2) := '00';                      -- ダミー顧客区分
    cv_dummy                   CONSTANT VARCHAR2(1) := '#';                       -- 新担当・新ルートがNULLの場合のダミー値
--
    -- *** ローカル変数 ***
    ln_cust_cnt                NUMBER;                                            -- 顧客重複チェック用
    lt_cust_account_id         hz_cust_accounts.cust_account_id%TYPE;             -- 顧客情報（顧客ID）
    lt_customer_class_code     hz_cust_accounts.customer_class_code%TYPE;         -- 顧客情報（顧客区分)
    lt_customer_status         hz_parties.duns_number_c%TYPE;                     -- 顧客情報（顧客ステータス)
    lt_sale_base_code          xxcmm_cust_accounts.sale_base_code%TYPE;           -- 顧客情報（売上拠点)
    lt_rsv_sale_base_code      xxcmm_cust_accounts.rsv_sale_base_code%TYPE;       -- 顧客情報（予約売上拠点)
    lt_rsv_sale_base_act_date  xxcmm_cust_accounts.rsv_sale_base_act_date%TYPE;   -- 顧客情報（予約売上拠点有効開始日)
    lt_receiv_base_code        xxcmm_cust_accounts.receiv_base_code%TYPE;         -- 顧客情報（入金拠点コード)
    lt_receiv_cust_flag        fnd_lookup_values_vl.attribute1%TYPE;              -- 売掛金管理先顧客フラグ
    lt_trgt_resource           hz_org_profiles_ext_b.c_ext_attr1%TYPE;            -- 現担当(DB)
    lt_next_resource           hz_org_profiles_ext_b.c_ext_attr1%TYPE;            -- 新担当(DB)
    lt_next_resource_id        hz_org_profiles_ext_b.extension_id%TYPE;           -- 新担当拡張ID(DB)
    lt_trgt_resource_id        hz_org_profiles_ext_b.extension_id%TYPE;           -- 現担当拡張ID(DB)
    lt_next_route              hz_org_profiles_ext_b.c_ext_attr1%TYPE;            -- 新ルートNo(DB)
    lt_next_route_id           hz_org_profiles_ext_b.extension_id%TYPE;           -- 新ルートNo拡張ID(DB)
    lt_trgt_route_id           hz_org_profiles_ext_b.extension_id%TYPE;           -- 現ルートNo拡張ID(DB)
    ln_trgt_resource_cnt       NUMBER;                                            -- 顧客担当件数
    ln_next_resource_cnt       NUMBER;                                            -- 顧客担当件数（未来日）
    lv_err_msg                 VARCHAR2(5000);                                    -- エラー内容（共通関数）
    lt_check_base_code         xxcmm_cust_accounts.sale_base_code%TYPE;           -- チェック用拠点
    ld_judgment_date           DATE;                                              -- 判定日付
    ld_reflect_emp_date        DATE;                                              -- 反映日（担当）
    ld_reflect_route_date      DATE;                                              -- 反映日（ルート）
    lv_check_flag              VARCHAR2(1);                                       -- セキュリティチェック用フラグ
    lv_message_code            VARCHAR2(30);                                      -- メッセージコード
    lv_check_emp_flag          VARCHAR2(1);                                       -- 営業員所属拠点チェック用フラグ
    lv_warn_flag               VARCHAR2(1);                                       -- 警告有りフラグ
    lv_emp_change_flag         VARCHAR2(1);                                       -- 新担当変更フラグ
    lv_route_change_flag       VARCHAR2(1);                                       -- 新ルートNo変更フラグ
    ln_ref_cnt                 NUMBER := 0;                                       -- 反映用の配列添え字
--
    -- *** ローカル・カーソル ***
    -- ルートNo／営業員アップロード中間テーブル取得
    CURSOR route_emp_upload_work_cur
    IS
      SELECT  xtrrw.line_no              line_no
             ,xtrrw.account_number       account_number
             ,xtrrw.new_route_no         new_route_no
             ,xtrrw.new_employee_number  new_employee_number
             ,xtrrw.reflect_method       reflect_method
      FROM    xxcso_tmp_rtn_rsrc_work xtrrw
      WHERE   xtrrw.file_id = in_file_id
      ORDER BY
              xtrrw.line_no
      ;
    -- 担当のセキュリティチェック用
    CURSOR emp_base_code_cur(
        iv_employee_number VARCHAR2
       ,iv_base_code       VARCHAR2
       ,id_reflect_date    DATE
    )
    IS
      SELECT cv_yes emp_check
      FROM   xxcso_resources_v2 xrv2
      WHERE  xrv2.employee_number = iv_employee_number
      AND    xxcso_util_common_pkg.get_rs_base_code(
                xrv2.resource_id
               ,id_reflect_date
             ) = iv_base_code
      ;
--
    -- *** ローカル・レコード ***
    route_emp_upload_work_rec  route_emp_upload_work_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    <<business_data_check_loop>>
    FOR route_emp_upload_work_rec IN route_emp_upload_work_cur LOOP
--
      -- 初期化
      ln_cust_cnt                := 0;      -- 顧客重複チェック用
      lt_cust_account_id         := NULL;   -- 顧客情報（顧客ID）
      lt_customer_class_code     := NULL;   -- 顧客情報（顧客区分)
      lt_customer_status         := NULL;   -- 顧客情報（顧客ステータス)
      lt_sale_base_code          := NULL;   -- 顧客情報（売上拠点)
      lt_rsv_sale_base_code      := NULL;   -- 顧客情報（予約売上拠点)
      lt_rsv_sale_base_act_date  := NULL;   -- 顧客情報（予約売上拠点有効開始日)
      lt_receiv_base_code        := NULL;   -- 顧客情報（入金拠点コード)
      lt_receiv_cust_flag        := cv_no;  -- 売掛金管理先顧客フラグ
      lt_trgt_resource           := NULL;   -- 現担当(DB)
      lt_next_resource_id        := NULL;   -- 新担当拡張ID(DB)
      lt_trgt_resource_id        := NULL;   -- 現担当拡張ID(DB)
      lt_next_resource           := NULL;   -- 新担当(DB)
      lt_next_route              := NULL;   -- 新ルートNo(DB)
      lt_next_route_id           := NULL;   -- 新ルートNo拡張ID(DB)
      lt_trgt_route_id           := NULL;   -- 現ルートNo拡張ID(DB)
      ln_trgt_resource_cnt       := 0;      -- 顧客担当件数
      ln_next_resource_cnt       := 0;      -- 顧客担当件数（未来日）
      lv_err_msg                 := NULL;   -- エラー内容（共通関数）
      lt_check_base_code         := NULL;   -- チェック用拠点
      ld_judgment_date           := NULL;   -- 判定日付
      ld_reflect_emp_date        := NULL;   -- 反映日(担当)
      ld_reflect_route_date      := NULL;   -- 反映日(ルート)
      lv_check_flag              := cv_no;  -- セキュリティチェック用フラグ
      lv_message_code            := NULL;   -- メッセージコード
      lv_check_emp_flag          := cv_no;  -- 営業員所属拠点チェック用フラグ
      lv_warn_flag               := cv_no;  -- 警告有りフラグ
      lv_emp_change_flag         := cv_no;  -- 新担当変更フラグ
      lv_route_change_flag       := cv_no;  -- 新ルートNo変更フラグ
--
      --==================================================
      -- 2.更新対象のチェック
      --==================================================
      IF (
           ( route_emp_upload_work_rec.new_route_no IS NULL )
           AND
           ( route_emp_upload_work_rec.new_employee_number IS NULL )
         )
      THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_no_update
                       ,iv_token_name1  => cv_tkn_account
                       ,iv_token_value1 => route_emp_upload_work_rec.account_number
                       ,iv_token_name2  => cv_tkn_index
                       ,iv_token_value2 => route_emp_upload_work_rec.line_no
                     );
        -- 更新内容なしエラーメッセージ出力
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        lv_warn_flag := cv_yes;
      END IF;
--
      --==================================================
      -- 3.同一ファイル内、顧客重複チェック
      --==================================================
      SELECT COUNT(1)
      INTO   ln_cust_cnt
      FROM   xxcso_tmp_rtn_rsrc_work xtrrw
      WHERE  xtrrw.file_id        = in_file_id
      AND    xtrrw.account_number = route_emp_upload_work_rec.account_number -- 同一顧客
      AND    xtrrw.line_no       <> route_emp_upload_work_rec.line_no        -- 自身以外の行
      ;
      -- 0以外の場合
      IF ( ln_cust_cnt <> 0 ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_dup_cust
                       ,iv_token_name1  => cv_tkn_account
                       ,iv_token_value1 => route_emp_upload_work_rec.account_number
                       ,iv_token_name2  => cv_tkn_index
                       ,iv_token_value2 => route_emp_upload_work_rec.line_no
                     );
        -- 顧客重複エラーメッセージ出力
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        lv_warn_flag := cv_yes;
      END IF;
--
      --==================================================
      -- 4.顧客マスタのチェック
      --==================================================
      -- 4-1.マスタの取得
      BEGIN
        SELECT  hca.cust_account_id         cust_account_id         -- 顧客ID
               ,hca.customer_class_code     customer_class_code     -- 顧客区分
               ,hp.duns_number_c            customer_status         -- 顧客ステータス
               ,xca.sale_base_code          sale_base_code          -- 売上拠点
               ,xca.rsv_sale_base_code      rsv_sale_base_code      -- 予約売上拠点
               ,xca.rsv_sale_base_act_date  rsv_sale_base_act_date  -- 予約売上拠点有効開始日
               ,xca.receiv_base_code        receiv_base_code        -- 入金拠点
        INTO    lt_cust_account_id
               ,lt_customer_class_code
               ,lt_customer_status
               ,lt_sale_base_code
               ,lt_rsv_sale_base_code
               ,lt_rsv_sale_base_act_date
               ,lt_receiv_base_code
        FROM    hz_cust_accounts    hca
               ,hz_parties          hp
               ,xxcmm_cust_accounts xca
        WHERE   hca.account_number  = route_emp_upload_work_rec.account_number
        AND     hca.party_id        = hp.party_id
        AND     hca.cust_account_id = xca.customer_id(+)
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_err_no_cust
                         ,iv_token_name1  => cv_tkn_account
                         ,iv_token_value1 => route_emp_upload_work_rec.account_number
                         ,iv_token_name2  => cv_tkn_index
                         ,iv_token_value2 => route_emp_upload_work_rec.line_no
                       );
          -- 顧客取得エラーメッセージ出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          lv_warn_flag := cv_yes;
      END;
--
      -- 4-2.顧客区分・顧客ステータスが対象かチェック
      BEGIN
        SELECT flvv.attribute1 receiv_cust_flag
        INTO   lt_receiv_cust_flag
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type     = cv_lkup_route_mgr_cust_class
        AND    flvv.lookup_code     = NVL( lt_customer_class_code, cv_00) || '-' || lt_customer_status
        AND    gd_process_date      BETWEEN flvv.start_date_active
                                    AND     NVL( flvv.end_date_active, gd_process_date )
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_err_class_status
                         ,iv_token_name1  => cv_tkn_account
                         ,iv_token_value1 => route_emp_upload_work_rec.account_number
                         ,iv_token_name2  => cv_tkn_class
                         ,iv_token_value2 => lt_customer_class_code
                         ,iv_token_name3  => cv_tkn_status
                         ,iv_token_value3 => lt_customer_status
                         ,iv_token_name4  => cv_tkn_index
                         ,iv_token_value4 => route_emp_upload_work_rec.line_no
                       );
          -- 顧客区分・ステータス対象外エラーメッセージ出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          lv_warn_flag := cv_yes;
      END;
--
      --==================================================
      -- 5.ルートNo／担当営業のチェック
      --==================================================
      -- 5-1.ルートNo／担当営業取得
      BEGIN
        SELECT  xrrv.trgt_resource                 trgt_resource                -- 現担当
               ,xrrv.next_resource                 next_resource                -- 新担当
               ,xrrv.next_resource_extension_id    next_resource_extension_id   -- 新担当拡張ID
               ,xrrv.trgt_resource_extension_id    trgt_route_no_extension_id   -- 現担当拡張ID
               ,xrrv.next_route_no                 next_route                   -- 新ルートNo
               ,xrrv.next_route_no_extension_id    next_route_no_extension_id   -- 新ルートNo拡張ID
               ,xrrv.trgt_route_no_extension_id    trgt_route_no_extension_id   -- 現ルートNo拡張ID
               ,xrrv.trgt_resource_cnt             trgt_resource_cnt            -- 顧客担当者数
               ,xrrv.next_resource_cnt             next_resource_cnt            -- 顧客担当者数（未来日）
        INTO    lt_trgt_resource
               ,lt_next_resource
               ,lt_next_resource_id
               ,lt_trgt_resource_id
               ,lt_next_route
               ,lt_next_route_id
               ,lt_trgt_route_id
               ,ln_trgt_resource_cnt
               ,ln_next_resource_cnt
        FROM    xxcso_rtn_rsrc_v xrrv
        WHERE   xrrv.cust_account_id = lt_cust_account_id
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_err_cust_resouce
                         ,iv_token_name1  => cv_tkn_account
                         ,iv_token_value1 => route_emp_upload_work_rec.account_number
                         ,iv_token_name2  => cv_tkn_err_msg
                         ,iv_token_value2 => SQLERRM
                         ,iv_token_name3  => cv_tkn_index
                         ,iv_token_value3 => route_emp_upload_work_rec.line_no
                       );
          -- 顧客担当取得エラーメッセージ出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          lv_warn_flag := cv_yes;
      END;
--
      -- 5-2.対象の顧客について、処理前に既に重複していないことをチェック
      if ( ln_trgt_resource_cnt > 1 OR ln_next_resource_cnt > 1) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_err_dup_resouce
                         ,iv_token_name1  => cv_tkn_account
                         ,iv_token_value1 => route_emp_upload_work_rec.account_number
                         ,iv_token_name2  => cv_tkn_index
                         ,iv_token_value2 => route_emp_upload_work_rec.line_no
                       );
          -- 顧客担当取得エラーメッセージ出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          lv_warn_flag := cv_yes;
      END IF;
--
      -- 5-3.新担当が「-」(削除)で、予約でない場合
      IF (
           ( route_emp_upload_work_rec.new_employee_number = cv_delete )
           AND
           ( route_emp_upload_work_rec.reflect_method <> cv_reservation )
         ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_reflect_method
                       ,iv_token_name1  => cv_tkn_column
                       ,iv_token_value1 => cv_emp_date
                       ,iv_token_name2  => cv_tkn_account
                       ,iv_token_value2 => route_emp_upload_work_rec.account_number
                       ,iv_token_name3  => cv_tkn_index
                       ,iv_token_value3 => route_emp_upload_work_rec.line_no
                     );
        -- 反映方法指定エラーメッセージ出力
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        lv_warn_flag := cv_yes;
      END IF;
--
      --------------------------
      -- 6.売掛管理顧客以外
      --------------------------
      IF ( lt_receiv_cust_flag = cv_no ) THEN
--
         -- 6-1.ルートNoのチェック(ルートNoがNOT NULL)
         IF ( route_emp_upload_work_rec.new_route_no IS NOT NULL ) THEN
--
           -- 6-1-1.ルートNoが削除以外
           IF ( route_emp_upload_work_rec.new_route_no <> cv_delete ) THEN
             -- ROUTE関連共通関数による妥当性チェック
             IF ( xxcso_route_common_pkg.validate_route_no(
                    route_emp_upload_work_rec.new_route_no
                   ,lv_err_msg ) = FALSE ) THEN
               lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_app_name
                              ,iv_name         => cv_msg_err_route_chack
                              ,iv_token_name1  => cv_tkn_account
                              ,iv_token_value1 => route_emp_upload_work_rec.account_number
                              ,iv_token_name2  => cv_tkn_route
                              ,iv_token_value2 => route_emp_upload_work_rec.new_route_no
                              ,iv_token_name3  => cv_tkn_err_msg
                              ,iv_token_value3 => lv_err_msg
                              ,iv_token_name4  => cv_tkn_index
                              ,iv_token_value4 => route_emp_upload_work_rec.line_no
                            );
               -- ルートNo妥当性チェックエラーメッセージ出力
               fnd_file.put_line(
                  which  => FND_FILE.OUTPUT
                 ,buff   => lv_errmsg
               );
               lv_warn_flag := cv_yes;
             END IF;
           -- 6-2.ルートNoが削除の場合
           ELSE
             -- 反映方法が予約でない場合
             IF ( route_emp_upload_work_rec.reflect_method <> cv_reservation ) THEN
               lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_app_name
                              ,iv_name         => cv_msg_err_reflect_method
                              ,iv_token_name1  => cv_tkn_column
                              ,iv_token_value1 => cv_route_date
                              ,iv_token_name2  => cv_tkn_account
                              ,iv_token_value2 => route_emp_upload_work_rec.account_number
                              ,iv_token_name3  => cv_tkn_index
                              ,iv_token_value3 => route_emp_upload_work_rec.line_no
                            );
               -- 反映方法指定エラーメッセージ出力
               fnd_file.put_line(
                  which  => FND_FILE.OUTPUT
                 ,buff   => lv_errmsg
               );
               lv_warn_flag := cv_yes;
             END IF;
           END IF;
         END IF;
--
         -------------------------------------------------
         -- 6-3.売上拠点・予約売上拠点と判定する日付の判定
         -------------------------------------------------
         -- 6-3-1.即時
         IF ( route_emp_upload_work_rec.reflect_method = cv_immediate ) THEN
           -- 顧客の売上拠点
           lt_check_base_code := lt_sale_base_code;
           -- 判定日は業務日付
           ld_judgment_date   := gd_process_date;
           -- メッセージコード即時
           lv_message_code    := cv_msg_immediate;
         -- 6-3-2.予約
         ELSE
           -- ①.翌月1日 < 予約日 OR 予約日NULL
           IF (
                ( lt_rsv_sale_base_act_date IS NULL )
                OR
                ( gd_next_month_date < lt_rsv_sale_base_act_date )
              ) THEN
             -- 顧客の売上拠点
             lt_check_base_code := lt_sale_base_code;
-- Ver1.1 Mod Start
             -- 判定日は業務日付翌月1日
--             ld_judgment_date   := gd_process_date;
             ld_judgment_date   := gd_next_month_date;
-- Ver1.1 Mod End
           -- ②.翌月1日 >= 予約日
           ELSE
             -- 顧客の予約売上拠点
             lt_check_base_code := lt_rsv_sale_base_code;
             -- 判定日は業務日付翌月1日
             ld_judgment_date   := gd_next_month_date;
           END IF;
           -- メッセージコード予約
           lv_message_code    := cv_msg_reservation;
         END IF;
--
         -- 6-4.顧客の売上拠点・予約売上拠点がNULL、且つ、現担当がNULLでないかチェック（顧客の値リストのチェック）
         IF (
              ( lt_check_base_code IS NULL )
              AND
              ( lt_trgt_resource IS NULL )
            ) THEN
           lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name
                          ,iv_name         => cv_msg_err_cust_inadequacy
                          ,iv_token_name1  => cv_tkn_account
                          ,iv_token_value1 => route_emp_upload_work_rec.account_number
                          ,iv_token_name2  => cv_tkn_index
                          ,iv_token_value2 => route_emp_upload_work_rec.line_no
                        );
           -- 顧客設定不備エラーメッセージ出力
           fnd_file.put_line(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
           );
           lv_warn_flag := cv_yes;
         END IF;
--
         -- 6-5.売上拠点（予約売上拠点）がNULLでない場合
         IF ( lt_check_base_code IS NOT NULL ) THEN
           -- 6-5-1.セキュリティあり
           IF ( gv_security_019_a09 <> cv_no_security ) THEN
             -- ①.判定日時点で売上拠点（予約売上拠点）が実行者の自拠点でないかチェック（顧客と実行者のチェック）
             << base_chk >>
             FOR i IN 1.. gt_base_code_tab.COUNT LOOP
               -- 実行者の自拠点であるかチェック
               IF ( gt_base_code_tab(i) = lt_check_base_code ) THEN
                 lv_check_flag := cv_yes;
               END IF;
             END LOOP base_chk;
             -- チェックフラグがYでない場合
             IF ( lv_check_flag <> cv_yes ) THEN
               lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_app_name
                              ,iv_name         => cv_msg_err_security
                              ,iv_token_name1  => cv_tkn_data_div
                              ,iv_token_value1 => lv_message_code
                              ,iv_token_name2  => cv_tkn_account
                              ,iv_token_value2 => route_emp_upload_work_rec.account_number
                              ,iv_token_name3  => cv_tkn_base_code
                              ,iv_token_value3 => lt_check_base_code
                              ,iv_token_name4  => cv_tkn_index
                              ,iv_token_value4 => route_emp_upload_work_rec.line_no
                            );
               -- 顧客セキュリティエラーメッセージ出力
               fnd_file.put_line(
                  which  => FND_FILE.OUTPUT
                 ,buff   => lv_errmsg
               );
               lv_warn_flag := cv_yes;
             END IF;
           END IF;
--
           -- 6-5-2.セキュリティあり・なし共通
           -- 新担当が「-」以外
           IF ( route_emp_upload_work_rec.new_employee_number <> cv_delete ) THEN
             -- 売上拠点（予約売上拠点）が判定日時点での新担当の所属拠点が同じかチェック（顧客と新担当のチェック）
             OPEN emp_base_code_cur(
                route_emp_upload_work_rec.new_employee_number   -- 新担当
               ,lt_check_base_code                              -- 売上拠点（予約売上拠点）
               ,ld_judgment_date                                -- 反映日
             );
             FETCH emp_base_code_cur INTO lv_check_emp_flag;
             CLOSE emp_base_code_cur;
             -- 営業員所属拠点チェック用フラグが「Y」でない場合
             IF ( lv_check_emp_flag <> cv_yes ) THEN
               lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_app_name
                              ,iv_name         => cv_msg_err_emp_base
                              ,iv_token_name1  => cv_tkn_data_div
                              ,iv_token_value1 => lv_message_code
                              ,iv_token_name2  => cv_tkn_account
                              ,iv_token_value2 => route_emp_upload_work_rec.account_number
                              ,iv_token_name3  => cv_tkn_base_code
                              ,iv_token_value3 => lt_check_base_code
                              ,iv_token_name4  => cv_tkn_index
                              ,iv_token_value4 => route_emp_upload_work_rec.line_no
                            );
                 -- 担当セキュリティエラーメッセージ出力
                 fnd_file.put_line(
                    which  => FND_FILE.OUTPUT
                   ,buff   => lv_errmsg
                 );
                 lv_warn_flag := cv_yes;
             END IF;
           END IF;
         -- 6-6.売上拠点・予約売上拠点がNULLの場合
         ELSE
             -- 6-6-1.実行日時点の現担当の所属拠点を取得
             BEGIN
               SELECT xxcso_util_common_pkg.get_rs_base_code(
                         xrv2.resource_id
                        ,gd_process_date
                      ) trgt_emp_base
               INTO   lt_check_base_code
               FROM   xxcso_resources_v2 xrv2
               WHERE  xrv2.employee_number = lt_trgt_resource
               ;
             EXCEPTION
               WHEN OTHERS THEN
                 lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_app_name
                                ,iv_name         => cv_msg_err_trgt_emp_base
                                ,iv_token_name1  => cv_tkn_account
                                ,iv_token_value1 => route_emp_upload_work_rec.account_number
                                ,iv_token_name2  => cv_tkn_emp_code
                                ,iv_token_value2 => lt_trgt_resource
                                ,iv_token_name3  => cv_tkn_err_msg
                                ,iv_token_value3 => SQLERRM
                                ,iv_token_name4  => cv_tkn_index
                                ,iv_token_value4 => route_emp_upload_work_rec.line_no
                              );
                 -- 現担当取得エラーメッセージ出力
                 fnd_file.put_line(
                    which  => FND_FILE.OUTPUT
                   ,buff   => lv_errmsg
                 );
                 lv_warn_flag := cv_yes;
             END;
--
             -- 6-6-2.セキュリティあり
             IF ( gv_security_019_a09 <> cv_no_security ) THEN
               -- ①.現担当の所属拠点が実行日時点の実行者の自拠点でない（顧客と実行者のチェック）
               << base_chk2 >>
               FOR i IN 1.. gt_base_code_tab.COUNT LOOP
                 -- 現担当の所属拠点が実行者の自拠点であるかチェック
                 IF ( gt_base_code_tab(i) = lt_check_base_code ) THEN
                   lv_check_flag := cv_yes;
                 END IF;
               END LOOP base_chk2;
               -- チェックフラグが「Y」でない場合
               IF ( lv_check_flag <> cv_yes ) THEN
                 lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_app_name
                                ,iv_name         => cv_msg_err_security
                                ,iv_token_name1  => cv_tkn_data_div
                                ,iv_token_value1 => lv_message_code
                                ,iv_token_name2  => cv_tkn_account
                                ,iv_token_value2 => route_emp_upload_work_rec.account_number
                                ,iv_token_name3  => cv_tkn_base_code
                                ,iv_token_value3 => lt_check_base_code
                                ,iv_token_name4  => cv_tkn_index
                                ,iv_token_value4 => route_emp_upload_work_rec.line_no
                              );
                 -- 顧客セキュリティエラーメッセージ出力
                 fnd_file.put_line(
                    which  => FND_FILE.OUTPUT
                   ,buff   => lv_errmsg
                 );
                 lv_warn_flag := cv_yes;
               END IF;
             END IF;
--
             -- 6-6-2.セキュリティあり・なし共通
             -- 新担当が「-」以外
             IF ( route_emp_upload_work_rec.new_employee_number <> cv_delete ) THEN
               -- ①.現担当の所属拠点が判定日時点での新担当の所属拠点が同じかチェック（顧客と新担当のチェック）
               OPEN emp_base_code_cur(
                       route_emp_upload_work_rec.new_employee_number   -- 新担当
                      ,lt_check_base_code                              -- 現担当の拠点
                      ,ld_judgment_date                                -- 反映日
                    );
               FETCH emp_base_code_cur INTO lv_check_emp_flag;
               CLOSE emp_base_code_cur;
               -- 営業員所属拠点チェック用フラグが「Y」でない場合
               IF ( lv_check_emp_flag <> cv_yes ) THEN
                 lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_app_name
                                ,iv_name         => cv_msg_err_emp_base
                                ,iv_token_name1  => cv_tkn_data_div
                                ,iv_token_value1 => lv_message_code
                                ,iv_token_name2  => cv_tkn_account
                                ,iv_token_value2 => route_emp_upload_work_rec.account_number
                                ,iv_token_name3  => cv_tkn_base_code
                                ,iv_token_value3 => lt_check_base_code
                                ,iv_token_name4  => cv_tkn_index
                                ,iv_token_value4 => route_emp_upload_work_rec.line_no
                              );
                 -- 担当セキュリティエラーメッセージ出力
                 fnd_file.put_line(
                    which  => FND_FILE.OUTPUT
                   ,buff   => lv_errmsg
                 );
                 lv_warn_flag := cv_yes;
               END IF;
             END IF;
           END IF;
      --------------------------
      -- 7.売掛管理顧客
      --------------------------
      ELSE
--
         -- 判定日の設定
         ld_judgment_date := gd_process_date; -- 業務日付
--
         -- 7-1.新ルートNoがNOT NULLの場合
         IF ( route_emp_upload_work_rec.new_route_no IS NOT NULL ) THEN
           lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name
                        ,iv_name         => cv_msg_err_payment_cust_route
                        ,iv_token_name1  => cv_tkn_account
                        ,iv_token_value1 => route_emp_upload_work_rec.account_number
                        ,iv_token_name2  => cv_tkn_index
                        ,iv_token_value2 => route_emp_upload_work_rec.line_no
                      );
           -- 売掛金管理先顧客ルートNo設定エラーメッセージ出力
           fnd_file.put_line(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
           );
           lv_warn_flag := cv_yes;
         END IF;
         -- 7-2.予約反映の場合
         IF ( route_emp_upload_work_rec.reflect_method = cv_reservation ) THEN
           lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name
                        ,iv_name         => cv_msg_err_payment_reflect
                        ,iv_token_name1  => cv_tkn_account
                        ,iv_token_value1 => route_emp_upload_work_rec.account_number
                        ,iv_token_name2  => cv_tkn_index
                        ,iv_token_value2 => route_emp_upload_work_rec.line_no
                      );
           -- 売掛金管理先顧客反映方法エラメッセージ出力
           fnd_file.put_line(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
           );
           lv_warn_flag := cv_yes;
         END IF;
         -- 7-3.入金拠点がNULLの場合
         IF ( lt_receiv_base_code IS NULL ) THEN
           lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name
                        ,iv_name         => cv_msg_err_payment_base
                        ,iv_token_name1  => cv_tkn_account
                        ,iv_token_value1 => route_emp_upload_work_rec.account_number
                        ,iv_token_name2  => cv_tkn_index
                        ,iv_token_value2 => route_emp_upload_work_rec.line_no
                      );
           -- 売掛金管理先顧客入金必須エラーメッセージ出力
           fnd_file.put_line(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
           );
           lv_warn_flag := cv_yes;
         END IF;
         -- 7-4.新担当がNULLの場合
         IF ( route_emp_upload_work_rec.new_employee_number IS NULL ) THEN
           lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name
                        ,iv_name         => cv_msg_err_payment_emp
                        ,iv_token_name1  => cv_tkn_account
                        ,iv_token_value1 => route_emp_upload_work_rec.account_number
                        ,iv_token_name2  => cv_tkn_index
                        ,iv_token_value2 => route_emp_upload_work_rec.line_no
                      );
           -- 売掛金管理先顧客新担当必須エラーメッセージ出力
           fnd_file.put_line(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
           );
           lv_warn_flag := cv_yes;
         END IF;
--
         -- 7-5.セキュリティあり
         IF ( gv_security_019_a09 <> cv_no_security ) THEN
           -- 7-5-1.入金拠点が実行時点実行者の自拠点でない（顧客と実行者のチェック）
           << base_chk3 >>
           FOR i IN 1.. gt_base_code_tab.COUNT LOOP
             -- 現担当の所属拠点が実行者の自拠点であるかチェック
             IF ( gt_base_code_tab(i) = lt_receiv_base_code ) THEN
               lv_check_flag := cv_yes;
             END IF;
           END LOOP base_chk3;
           -- チェックフラグが「Y」でない場合
           IF ( lv_check_flag <> cv_yes ) THEN
             lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name
                            ,iv_name         => cv_msg_err_rcv_security
                            ,iv_token_name1  => cv_tkn_account
                            ,iv_token_value1 => route_emp_upload_work_rec.account_number
                            ,iv_token_name2  => cv_tkn_base_code
                            ,iv_token_value2 => lt_receiv_base_code
                            ,iv_token_name3  => cv_tkn_index
                            ,iv_token_value3 => route_emp_upload_work_rec.line_no
                          );
             -- 顧客セキュリティエラーメッセージ出力
             fnd_file.put_line(
                which  => FND_FILE.OUTPUT
               ,buff   => lv_errmsg
             );
             lv_warn_flag := cv_yes;
           END IF;
         END IF;
         -- 7-6.セキュリティあり・なし共通
         -- 新担当が「-」以外
         IF ( route_emp_upload_work_rec.new_employee_number <> cv_delete ) THEN
           -- 7-6-1.顧客の入金拠点と業務日付の新担当の所属拠点がちがう（顧客と新担当のチェック）
           OPEN emp_base_code_cur(
                   route_emp_upload_work_rec.new_employee_number   -- 新担当
                  ,lt_receiv_base_code                             -- 入金拠点
                  ,ld_judgment_date                                -- 反映日(業務日付)
                );
           FETCH emp_base_code_cur INTO lv_check_emp_flag;
           CLOSE emp_base_code_cur;
           -- 営業員所属拠点チェック用フラグが「Y」でない場合
           IF ( lv_check_emp_flag <> cv_yes ) THEN
             lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name
                            ,iv_name         => cv_msg_err_rcv_emp_base
                            ,iv_token_name1  => cv_tkn_account
                            ,iv_token_value1 => route_emp_upload_work_rec.account_number
                            ,iv_token_name2  => cv_tkn_base_code
                            ,iv_token_value2 => lt_receiv_base_code
                            ,iv_token_name3  => cv_tkn_index
                            ,iv_token_value3 => route_emp_upload_work_rec.line_no
                          );
             -- 担当セキュリティエラーメッセージ出力
             fnd_file.put_line(
                which  => FND_FILE.OUTPUT
               ,buff   => lv_errmsg
             );
             lv_warn_flag := cv_yes;
           END IF;
         END IF;
      END IF;
--
      -----------------------
      -- 8.配列編集
      -----------------------
      IF ( lv_warn_flag = cv_no ) THEN
        -- 新担当(CSV)が「-」(削除)
        IF ( route_emp_upload_work_rec.new_employee_number = cv_delete ) THEN
          -- 削除
          lv_emp_change_flag := cv_del;
        -- 新担当(CSV)がNULL
        ELSIF ( route_emp_upload_work_rec.new_employee_number IS NULL) THEN
          -- 変更なし
          lv_emp_change_flag := cv_no;
        ELSE
          -- 新担当(CSV)と新担当(DB)のデータが同じ
          IF ( route_emp_upload_work_rec.new_employee_number = NVL( lt_next_resource, cv_dummy ) ) THEN
            -- 変更なし
            lv_emp_change_flag := cv_no;
          -- 新担当(CSV)と新担当(DB)のデータが異なる
          ELSIF ( route_emp_upload_work_rec.new_employee_number <> NVL( lt_next_resource, cv_dummy ) ) THEN
            -- 作成・更新
            lv_emp_change_flag := cv_ins_upd;
          END IF;
        END IF;
--
        -- 新担当(CSV)が「-」(削除)
        IF ( route_emp_upload_work_rec.new_route_no = cv_delete ) THEN
          -- 削除
          lv_route_change_flag := cv_del;
        -- 新担当(CSV)がNULL
        ELSIF ( route_emp_upload_work_rec.new_route_no IS NULL) THEN
          -- 変更なし
          lv_route_change_flag := cv_no;
        ELSE
          -- 新担当(CSV)と新担当(DB)のデータが同じ
          IF ( route_emp_upload_work_rec.new_route_no = NVL( lt_next_route, cv_dummy ) ) THEN
            -- 変更なし
            lv_route_change_flag := cv_no;
          -- 新担当(CSV)と新担当(DB)のデータが異なる
          ELSIF ( route_emp_upload_work_rec.new_route_no <> NVL( lt_next_route, cv_dummy ) ) THEN
            -- 作成・更新
            lv_route_change_flag := cv_ins_upd;
          END IF;
        END IF;
--
        -- 反映日の編集
        -- 即時
        IF ( route_emp_upload_work_rec.reflect_method = cv_immediate ) THEN
          ld_reflect_emp_date   := gd_process_date;    -- 業務日付
          ld_reflect_route_date := gd_first_day_date;  -- 業務日付1日
        -- 予約
        ELSE
          ld_reflect_emp_date   := gd_next_month_date; -- 業務翌月1日
          ld_reflect_route_date := gd_next_month_date; -- 業務翌月1日
        END IF;
--
        -- 8-2.編集の結果、更新不要なデータのチェック
        IF (
             ( lv_emp_change_flag = cv_no )
             AND
             ( lv_route_change_flag = cv_no )
           ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_err_no_update
                         ,iv_token_name1  => cv_tkn_account
                         ,iv_token_value1 => route_emp_upload_work_rec.account_number
                         ,iv_token_name2  => cv_tkn_index
                         ,iv_token_value2 => route_emp_upload_work_rec.line_no
                       );
          -- 更新内容なしエラーメッセージメッセージ出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          lv_warn_flag := cv_yes;
        END IF;
      END IF;
--
      IF ( lv_warn_flag = cv_no ) THEN
        -- 8-3.配列の編集
        ln_ref_cnt := ln_ref_cnt + 1;
        ot_ref_route_emp_data_tab(ln_ref_cnt).line_no               := route_emp_upload_work_rec.line_no;
        ot_ref_route_emp_data_tab(ln_ref_cnt).account_number        := route_emp_upload_work_rec.account_number;
        ot_ref_route_emp_data_tab(ln_ref_cnt).new_employee_number   := route_emp_upload_work_rec.new_employee_number;
        ot_ref_route_emp_data_tab(ln_ref_cnt).new_employee_date     := ld_reflect_emp_date;
        ot_ref_route_emp_data_tab(ln_ref_cnt).trgt_resource_id      := lt_trgt_resource_id;
        ot_ref_route_emp_data_tab(ln_ref_cnt).next_resource_id      := lt_next_resource_id;
        ot_ref_route_emp_data_tab(ln_ref_cnt).new_route_no          := route_emp_upload_work_rec.new_route_no;
        ot_ref_route_emp_data_tab(ln_ref_cnt).new_route_date        := ld_reflect_route_date;
        ot_ref_route_emp_data_tab(ln_ref_cnt).trgt_route_id         := lt_trgt_route_id;
        ot_ref_route_emp_data_tab(ln_ref_cnt).next_route_id         := lt_next_route_id;
        ot_ref_route_emp_data_tab(ln_ref_cnt).employee_change_flag  := lv_emp_change_flag;
        ot_ref_route_emp_data_tab(ln_ref_cnt).route_no_change_flag  := lv_route_change_flag;
      ELSE
        -- 1件でも警告が存在する場合、処理結果を警告にする
        ov_retcode  := cv_status_warn;
        gn_warn_cnt := gn_warn_cnt + 1;
      END IF;
--
    END LOOP business_data_check_loop;
--
  EXCEPTION
    --*** 処理エラー例外 ***
    WHEN global_process_expt THEN
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
  END check_business_data;
--
  /**********************************************************************************
   * Procedure Name   : reflect_route_emp
   * Description      : ルートNo／営業担当反映処理(A-8)
   ***********************************************************************************/
  PROCEDURE reflect_route_emp(
     it_ref_route_emp_data_tab  IN  gt_ref_route_emp_ttype -- 1.ルートNo/営業担当反映データ
    ,ov_errbuf                  OUT VARCHAR2               --   エラー・メッセージ           --# 固定 #
    ,ov_retcode                 OUT VARCHAR2               --   リターン・コード             --# 固定 #
    ,ov_errmsg                  OUT VARCHAR2               --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'reflect_route_emp'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- *** ローカル変数 ***
    lv_warn_flag               VARCHAR2(1);   -- 警告有りフラグ
    lv_message_code            VARCHAR2(30);  -- メッセージコード
--
    -- *** ローカルカーソル ***
    -- 組織プロファイル拡張のロック用カーソル
    CURSOR ext_b_lock_cur(
      it_lock_id hz_org_profiles_ext_b.extension_id%TYPE
    )
    IS
      SELECT cv_yes lock_data
      FROM   hz_org_profiles_ext_b hopeb
      WHERE  hopeb.extension_id = it_lock_id
      FOR UPDATE OF
             hopeb.extension_id NOWAIT
    ;
--
    -- *** ローカルレコード ***
    ext_b_lock_rec ext_b_lock_cur%ROWTYPE;
--
    -- *** ローカル例外 ***
    local_lock_expt EXCEPTION;  -- ロック例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    << reflect_loop >>
    FOR i IN 1.. it_ref_route_emp_data_tab.COUNT LOOP
--
      BEGIN
        -- 初期化
        lv_warn_flag := cv_no;
--
        --==================================================
        -- ロック処理
        --==================================================
        IF (
             ( it_ref_route_emp_data_tab(i).employee_change_flag <> cv_no )
             AND
             ( it_ref_route_emp_data_tab(i).trgt_resource_id IS NOT NULL )
           ) THEN
          -- メッセージコード設定
          lv_message_code := cv_msg_trgt_route_date;
          -- 1-1.現担当のロック
          BEGIN
            OPEN  ext_b_lock_cur( it_ref_route_emp_data_tab(i).trgt_resource_id );
            FETCH ext_b_lock_cur INTO ext_b_lock_rec;
            CLOSE ext_b_lock_cur;
          EXCEPTION
            WHEN global_lock_expt THEN
              RAISE local_lock_expt;
          END;
        END IF;
--
        IF (
             ( it_ref_route_emp_data_tab(i).employee_change_flag <> cv_no )
             AND
             ( it_ref_route_emp_data_tab(i).next_resource_id IS NOT NULL )
           ) THEN
          -- メッセージコード設定
          lv_message_code := cv_emp_date;
          -- 1-2.新担当のロック
          BEGIN
            OPEN  ext_b_lock_cur( it_ref_route_emp_data_tab(i).next_resource_id );
            FETCH ext_b_lock_cur INTO ext_b_lock_rec;
            CLOSE ext_b_lock_cur;
          EXCEPTION
            WHEN global_lock_expt THEN
              RAISE local_lock_expt;
          END;
        END IF;
--
        IF (
             ( it_ref_route_emp_data_tab(i).route_no_change_flag <> cv_no )
             AND
             ( it_ref_route_emp_data_tab(i).trgt_route_id IS NOT NULL )
           ) THEN
          -- メッセージコード設定
          lv_message_code := cv_msg_trgt_emp_date;
          -- 1-3.現ルートNoのロック
          BEGIN
            OPEN  ext_b_lock_cur( it_ref_route_emp_data_tab(i).trgt_route_id );
            FETCH ext_b_lock_cur INTO ext_b_lock_rec;
            CLOSE ext_b_lock_cur;
          EXCEPTION
            WHEN global_lock_expt THEN
              RAISE local_lock_expt;
          END;
        END IF;
--
        IF (
             ( it_ref_route_emp_data_tab(i).route_no_change_flag <> cv_no )
             AND
             ( it_ref_route_emp_data_tab(i).next_route_id IS NOT NULL )
           ) THEN
          -- メッセージコード設定
          lv_message_code := cv_route_date;
          -- 1-4.新ルートNoのロック
          BEGIN
            OPEN  ext_b_lock_cur( it_ref_route_emp_data_tab(i).next_route_id );
            FETCH ext_b_lock_cur INTO ext_b_lock_rec;
            CLOSE ext_b_lock_cur;
          EXCEPTION
            WHEN global_lock_expt THEN
              RAISE local_lock_expt;
          END;
        END IF;
--
        -- セーブポイントの発行
        SAVEPOINT line_save;
--
        --==================================================
        -- 営業担当、ルートNoの反映
        --==================================================
        IF ( it_ref_route_emp_data_tab(i).employee_change_flag = cv_ins_upd ) THEN
--
          -- 1-5.担当の登録・更新
          xxcso_rtn_rsrc_pkg.regist_resource_no(
             iv_account_number    => it_ref_route_emp_data_tab(i).account_number
            ,iv_resource_no       => it_ref_route_emp_data_tab(i).new_employee_number
            ,id_start_date        => it_ref_route_emp_data_tab(i).new_employee_date
            ,ov_errbuf            => lv_errbuf
            ,ov_retcode           => lv_retcode
            ,ov_errmsg            => lv_errmsg
           );
          IF ( lv_retcode <> cv_status_normal ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name
                           ,iv_name         => cv_msg_err_common_pkg
                           ,iv_token_name1  => cv_tkn_column
                           ,iv_token_value1 => cv_emp_date
                           ,iv_token_name2  => cv_tkn_action
                           ,iv_token_value2 => cv_msg_insert
                           ,iv_token_name3  => cv_tkn_account
                           ,iv_token_value3 => it_ref_route_emp_data_tab(i).account_number
                           ,iv_token_name4  => cv_tkn_err_msg
                           ,iv_token_value4 => lv_errbuf
                           ,iv_token_name5  => cv_tkn_index
                           ,iv_token_value5 => it_ref_route_emp_data_tab(i).line_no
                         );
            -- ルートNo／担当営業共通関数エラーメッセージ出力
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
            lv_warn_flag  := cv_yes;
          END IF;
        ELSIF ( it_ref_route_emp_data_tab(i).employee_change_flag = cv_del ) THEN
          -- 1-6.担当の削除
          xxcso_rtn_rsrc_pkg.unregist_resource_no(
             iv_account_number    => it_ref_route_emp_data_tab(i).account_number
            ,iv_resource_no       => NULL
            ,id_start_date        => it_ref_route_emp_data_tab(i).new_employee_date
            ,ov_errbuf            => lv_errbuf
            ,ov_retcode           => lv_retcode
            ,ov_errmsg            => lv_errmsg
          );
          IF ( lv_retcode <> cv_status_normal ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name
                           ,iv_name         => cv_msg_err_common_pkg
                           ,iv_token_name1  => cv_tkn_column
                           ,iv_token_value1 => cv_emp_date
                           ,iv_token_name2  => cv_tkn_action
                           ,iv_token_value2 => cv_msg_delete
                           ,iv_token_name3  => cv_tkn_account
                           ,iv_token_value3 => it_ref_route_emp_data_tab(i).account_number
                           ,iv_token_name4  => cv_tkn_err_msg
                           ,iv_token_value4 => lv_errbuf
                           ,iv_token_name5  => cv_tkn_index
                           ,iv_token_value5 => it_ref_route_emp_data_tab(i).line_no
                         );
            -- ルートNo／担当営業共通関数エラーメッセージ出力
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
            lv_warn_flag  := cv_yes;
          END IF;
        END IF;
--
        IF ( it_ref_route_emp_data_tab(i).route_no_change_flag = cv_ins_upd ) THEN
          -- 1-7.ルートNoの登録・更新
          xxcso_rtn_rsrc_pkg.regist_route_no(
             iv_account_number    => it_ref_route_emp_data_tab(i).account_number
            ,iv_route_no          => it_ref_route_emp_data_tab(i).new_route_no
            ,id_start_date        => it_ref_route_emp_data_tab(i).new_route_date
            ,ov_errbuf            => lv_errbuf
            ,ov_retcode           => lv_retcode
            ,ov_errmsg            => lv_errmsg
          );
          IF ( lv_retcode <> cv_status_normal ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name
                           ,iv_name         => cv_msg_err_common_pkg
                           ,iv_token_name1  => cv_tkn_column
                           ,iv_token_value1 => cv_route_date
                           ,iv_token_name2  => cv_tkn_action
                           ,iv_token_value2 => cv_msg_insert
                           ,iv_token_name3  => cv_tkn_account
                           ,iv_token_value3 => it_ref_route_emp_data_tab(i).account_number
                           ,iv_token_name4  => cv_tkn_err_msg
                           ,iv_token_value4 => lv_errbuf
                           ,iv_token_name5  => cv_tkn_index
                           ,iv_token_value5 => it_ref_route_emp_data_tab(i).line_no
                         );
            -- ルートNo／担当営業共通関数エラーメッセージ出力
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
            lv_warn_flag  := cv_yes;
          END IF;
        ELSIF ( it_ref_route_emp_data_tab(i).route_no_change_flag = cv_del ) THEN
          -- 1-8.ルートNoの削除
          xxcso_rtn_rsrc_pkg.unregist_route_no(
             iv_account_number    => it_ref_route_emp_data_tab(i).account_number
            ,iv_route_no          => NULL
            ,id_start_date        => it_ref_route_emp_data_tab(i).new_route_date
            ,ov_errbuf            => lv_errbuf
            ,ov_retcode           => lv_retcode
            ,ov_errmsg            => lv_errmsg
          );
          IF ( lv_retcode <> cv_status_normal ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name
                           ,iv_name         => cv_msg_err_common_pkg
                           ,iv_token_name1  => cv_tkn_column
                           ,iv_token_value1 => cv_route_date
                           ,iv_token_name2  => cv_tkn_action
                           ,iv_token_value2 => cv_msg_delete
                           ,iv_token_name3  => cv_tkn_account
                           ,iv_token_value3 => it_ref_route_emp_data_tab(i).account_number
                           ,iv_token_name4  => cv_tkn_err_msg
                           ,iv_token_value4 => lv_errbuf
                           ,iv_token_name5  => cv_tkn_index
                           ,iv_token_value5 => it_ref_route_emp_data_tab(i).line_no
                         );
            -- ルートNo／担当営業共通関数エラーメッセージ出力
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
            lv_warn_flag  := cv_yes;
          END IF;
        END IF;
--
        -- 件数カウント
        IF ( lv_warn_flag = cv_no ) THEN
          -- 成功件数
          gn_normal_cnt := gn_normal_cnt + 1;
        ELSE
          -- ロールバック
          ROLLBACK TO SAVEPOINT line_save;
          -- 警告件数
          gn_warn_cnt   := gn_warn_cnt + 1;
          ov_retcode    := cv_status_warn;
        END IF;
--
      EXCEPTION
        -- ロックエラー例外
        WHEN local_lock_expt THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_err_lock_data
                         ,iv_token_name1  => cv_tkn_table
                         ,iv_token_value1 => cv_msg_table_hopeb
                         ,iv_token_name2  => cv_tkn_column
                         ,iv_token_value2 => lv_message_code
                         ,iv_token_name3  => cv_tkn_account
                         ,iv_token_value3 => it_ref_route_emp_data_tab(i).account_number
                         ,iv_token_name4  => cv_tkn_index
                         ,iv_token_value4 => it_ref_route_emp_data_tab(i).line_no
                       );
          -- ロックエラーメッセージ出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          -- 警告件数
          gn_warn_cnt   := gn_warn_cnt + 1;
          ov_retcode    := cv_status_warn;
      END;
--
    END LOOP reflect_loop;
--
  EXCEPTION
    --*** 処理エラー例外 ***
    WHEN global_process_expt THEN
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
  END reflect_route_emp;
--
  /**********************************************************************************
   * Procedure Name   : delete_file_ul_if
   * Description      : ファイルアップロードIFデータ削除(A-9)
   ***********************************************************************************/
  PROCEDURE delete_file_ul_if(
    in_file_id    IN  NUMBER,    -- ファイルID
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_file_ul_if'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
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
    BEGIN
      DELETE FROM xxccp_mrp_file_ul_interface xmfui
      WHERE xmfui.file_id = in_file_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- データ削除エラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_del_data
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => cv_tbl_nm_file_ul_if
                       ,iv_token_name2  => cv_tkn_error_message
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
  END delete_file_ul_if;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_file_id    IN  VARCHAR2,  -- 1.ファイルID
    iv_fmt_ptn    IN  VARCHAR2,  -- 2.フォーマットパターン
    ov_errbuf     OUT VARCHAR2,  --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,  --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)  --   ユーザー・エラー・メッセージ --# 固定 #
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
--
    -- *** ローカル変数 ***
    lt_route_emp_data_tab         gt_rec_data_ttype;
    lt_ref_route_emp_data_tab     gt_ref_route_emp_ttype;
    ln_file_id                    NUMBER;
    lv_warn_flag                  VARCHAR2(1);  -- 警告有りフラグ
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
    gn_warn_cnt   := 0;
--
    -- ユーザー変数の初期化
    lv_warn_flag  := cv_no;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    --==================================================
    -- A-1.初期処理
    --==================================================
    init(
       iv_file_id => iv_file_id  -- ファイルID
      ,iv_fmt_ptn => iv_fmt_ptn  -- フォーマットパターン
      ,on_file_id => ln_file_id  -- ファイルID(変換後)
      ,ov_errbuf  => lv_errbuf   -- エラー・メッセージ
      ,ov_retcode => lv_retcode  -- リターン・コード
      ,ov_errmsg  => lv_errmsg   -- ユーザー・エラー・メッセージ 
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --==================================================
    -- A-2.ファイルアップロードIFデータ抽出
    --==================================================
    get_upload_data(
       in_file_id             => ln_file_id
      ,ot_route_emp_data_tab  => lt_route_emp_data_tab
      ,ov_errbuf              => lv_errbuf
      ,ov_retcode             => lv_retcode
      ,ov_errmsg              => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      ov_retcode := lv_retcode;
    END IF;
--
    -- 正常時のみ以下を実行
    IF ( lv_retcode = cv_status_normal ) THEN
      --==================================================
      -- A-5.入力データチェック
      --==================================================
      check_input_data(
         iv_fmt_ptn             => iv_fmt_ptn
        ,it_route_emp_data_tab  => lt_route_emp_data_tab
        ,ov_errbuf              => lv_errbuf
        ,ov_retcode             => lv_retcode
        ,ov_errmsg              => lv_errmsg
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        lv_warn_flag := cv_yes;
      END IF;
    -- A-2.で警告の場合も以下を処理しない
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_warn_flag := cv_yes;
    END IF;
--
    -- 正常時のみ以下を実行
    IF ( lv_warn_flag = cv_no ) THEN
      --==================================================
      -- A-6.ルートNo／営業員アップロード中間テーブル登録
      --==================================================
      ins_route_emp_upload_work(
         in_file_id             => ln_file_id
        ,it_route_emp_data_tab  => lt_route_emp_data_tab
        ,ov_errbuf              => lv_errbuf
        ,ov_retcode             => lv_retcode
        ,ov_errmsg              => lv_errmsg
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      --==================================================
      -- A-7.業務エラーチェック
      --==================================================
      check_business_data(
         in_file_id                 => ln_file_id
        ,ot_ref_route_emp_data_tab  => lt_ref_route_emp_data_tab
        ,ov_errbuf                  => lv_errbuf
        ,ov_retcode                 => lv_retcode
        ,ov_errmsg                  => lv_errmsg
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        lv_warn_flag := cv_yes;
      END IF;
--
      --==================================================
      -- A-8.ルートNo／営業担当反映処理
      --==================================================
      reflect_route_emp(
         it_ref_route_emp_data_tab => lt_ref_route_emp_data_tab
        ,ov_errbuf                 => lv_errbuf
        ,ov_retcode                => lv_retcode
        ,ov_errmsg                 => lv_errmsg
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        lv_warn_flag := cv_yes;
      END IF;
    END IF;
--
    --==================================================
    -- A-9.ファイルアップロードIFデータ削除
    --==================================================
    delete_file_ul_if(
       in_file_id => ln_file_id
      ,ov_errbuf  => lv_errbuf
      ,ov_retcode => lv_retcode
      ,ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 警告の設定
    IF ( lv_warn_flag = cv_yes ) THEN
     ov_retcode := cv_status_warn;
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
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_file_id    IN  VARCHAR2,      -- 1.ファイルID
    iv_fmt_ptn    IN  VARCHAR2       -- 2.フォーマットパターン
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
    -- ユーザー・ローカル定数
    cv_warn_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00001'; -- 警告件数メッセージ
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
       iv_file_id
      ,iv_fmt_ptn
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
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
      gn_error_cnt  := gn_error_cnt + 1;
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_warn_cnt   := 0;
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
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
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
END XXCSO019A13C;
/
