CREATE OR REPLACE PACKAGE BODY XXCMM002A01C
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXCMM002A01C(body)
 * Description      : 社員データ取込処理
 * MD.050           : MD050_CMM_002_A01_社員データ取込
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init_get_profile       プロファイル取得プロシージャ
 *  init_file_lock         ファイルロック処理プロシージャ
 *  init                   初期処理を行うプロシージャ(A-2)
 *  check_aff_bumon        AFF部門マスタ存在チェック処理プロシージャ
 *  get_location_id        ユーザーIDを取得し存在チェックを行うプロシージャ
 *  in_if_check_emp        データ連携対象チェック処理プロシージャ
 *  in_if_check            データ妥当性チェック処理プロシージャ(A-4)
 *  check_fnd_user         ユーザーID取得処理プロシージャ
 *  check_fnd_lookup       コードテーブル（参照マスタ）存在ファンクション
 *  check_code             コード存在チェック処理
 *  get_fnd_responsibility 職責・管理者情報の取得処理プロシージャ(A-7)
 *  check_insert           社員データ登録分チェック処理プロシージャ(A-5)
 *  check_update           社員データ更新分チェック処理プロシージャ(A-6)
 *  add_report             社員データエラー情報格納処理(A-11)
 *  disp_report            レポート用データを出力するプロシージャ
 *  insert_resp_all        ユーザー職責マスタの登録処理を行うプロシージャ
 *  update_resp_all        ユーザー職責マスタの更新処理を行うプロシージャ
 *  delete_resp_all        ユーザー職責マスタのデータを無効化するプロシージャ
 *  get_service_id         サービス期間IDの取得を行うプロシージャ
 *  get_person_type        パーソンタイプの取得を行うプロシージャ
 *  changes_proc           異動処理を行うプロシージャ
 *  retire_proc            退職処理を行うプロシージャ
 *  re_hire_proc           再雇用処理を行うプロシージャ
 *  re_hire_ass_proc       再雇用処理(アサインメントマスタ)を行うプロシージャ
 *  insert_proc            新規社員の登録を行うプロシージャ
 *  update_proc            既存社員の更新を行うプロシージャ
 *  delete_proc            退職者の再雇用を行うプロシージャ
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/09    1.0   SCS 工藤 真純    初回作成
 *  2009/03/09    1.1   SCS 竹下 昭範    正常終了時だけ、CSVファイルを削除するように変更
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn   CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error  CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2

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
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);             -- 実行ユーザ名
  gv_conc_name     VARCHAR2(30);              -- 実行コンカレント名
  gv_conc_status   VARCHAR2(30);              -- 処理結果
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- エラー件数
  gn_warn_cnt      NUMBER;                    -- スキップ件数
  gn_skip_cnt      NUMBER;                    -- スキップ件数

--################################  固定部 END   ##################################
--
--##########################  固定共通例外宣言部 START  ###########################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  global_process2_expt      EXCEPTION;
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
  lock_expt                   EXCEPTION;     -- ロック取得例外
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_appl_short_name   CONSTANT VARCHAR2(10) := 'XXCMM';             -- アドオン：マスタ
  cv_common_short_name CONSTANT VARCHAR2(10) := 'XXCCP';             -- アドオン：共通・IF
  cv_pkg_name          CONSTANT VARCHAR2(15) := 'XXCMM002A01C';      -- パッケージ名

  -- 更新区分をあらわすステータス(masters_rec.proc_flg)
  gv_sts_error     CONSTANT VARCHAR2(1) := 'E';   --ステータス(更新中止)
  gv_sts_thru      CONSTANT VARCHAR2(1) := 'S';   --ステータス(変更なし)
  gv_sts_update    CONSTANT VARCHAR2(1) := 'U';   --ステータス(処理対象)
  -- 連携区分・入社日連携区分・退職連携・職責自動連携をあらわすステータス(masters_rec.proc_kbn,ymd_kbn,retire_kbn,resp_kbn,location_id_kbn)
  gv_sts_yes       CONSTANT VARCHAR2(1) := 'Y';   --ステータス(連携対象)
  -- 職責自動連携(masters_rec.resp_kbn)
  gv_sts_no        CONSTANT VARCHAR2(1) := 'N';   --ステータス(自動職責不可)
--
  -- 現社員状態をあらわすステータス(masters_rec.emp_kbn)
  gv_kbn_new       CONSTANT VARCHAR2(1) := 'I';   --ステータス(現データなし：新規社員)
  gv_kbn_employee  CONSTANT VARCHAR2(1) := 'U';   --ステータス(既存社員)
  gv_kbn_retiree   CONSTANT VARCHAR2(1) := 'D';   --ステータス(退職者)
--
  gv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
  gv_flg_on        CONSTANT VARCHAR2(1) := '1';
  gv_const_y       CONSTANT VARCHAR2(1) := 'Y';
--
  gv_def_sex       CONSTANT VARCHAR2(1) := 'M';
  gv_owner         CONSTANT VARCHAR2(4) := 'CUST';
  gv_info_category CONSTANT VARCHAR2(2) := 'JP';
  gv_in_if_name    CONSTANT VARCHAR2(100)   := 'xxcmm_in_people_if';
  gv_upd_mode      CONSTANT VARCHAR2(15)    := 'CORRECTION';
  gv_user_person_type    CONSTANT VARCHAR2(10) := '従業員';
  gv_user_person_type_ex CONSTANT VARCHAR2(10) := '退職者';
--
  --メッセージ番号
  --共通メッセージ番号
--
  -- メッセージ番号(マスタ)
  cv_file_data_no_err  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00001';  -- 対象データ無しメッセージ
  cv_prf_get_err       CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00002';  -- プロファイル取得エラー
  cv_file_pass_err     CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00003';  -- ファイルパス不正エラー
  cv_file_priv_err     CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00007';  -- ファイルアクセス権限エラー
  cv_file_lock_err     CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00008';  -- ロック取得NGメッセージ
  cv_csv_file_err      CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00219';  -- CSVファイル存在チェック
  cv_api_err           CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00014';  -- APIエラー(コンカレント)
  cv_shozoku_err       CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00015';  -- 登録外所属コード
  cv_dup_val_err       CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00016';  -- ユーザー登録分の重複チェックエラー
  cv_not_found_err     CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00017';  -- ユーザー更新分の存在チェックエラー
  cv_process_date_err  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00018';  -- 業務日付取得エラー
  cv_no_data_err       CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00025';  -- マスタ存在チェックエラー
  cv_log_err_msg       CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00039';  -- ログ出力失敗メッセージ
  cv_data_check_err    CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00200';  -- 取込チェックエラー
  cv_st_ymd_err1       CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00201';  -- 入社日過去日付け変更エラ
  cv_st_ymd_err2       CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00202';  -- 入社日＞退職日エラー
  cv_st_ymd_err3       CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00210';  -- 入社日未来日付社員（登録更新不可）エラー
  cv_retiree_err1      CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00203';  -- 退職者情報変更エラー
  cv_retiree_err2      CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00204';  -- 再雇用日エラー
--  cv_out_resp_msg      CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00206';  -- 職責自動割当て不可能(正常)
  cv_rep_msg           CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00207';  -- エラーの処理結果リストの見出し
  -- メッセージ番号(共通・IF)
  cv_target_rec_msg    CONSTANT VARCHAR2(30) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
  cv_success_rec_msg   CONSTANT VARCHAR2(30) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
  cv_error_rec_msg     CONSTANT VARCHAR2(30) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
  cv_skip_rec_msg      CONSTANT VARCHAR2(30) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
  cv_normal_msg        CONSTANT VARCHAR2(30) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
  cv_warn_msg          CONSTANT VARCHAR2(30) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
  cv_error_msg         CONSTANT VARCHAR2(30) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
  cv_file_name         CONSTANT VARCHAR2(20) := 'APP-XXCCP1-05102'; -- ファイル名メッセージ
  cv_input_no_msg      CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90008'; -- コンカレント入力パラメータなし

  --プロファイル
  cv_prf_dir           CONSTANT VARCHAR2(30) := 'XXCMM1_JINJI_IN_DIR';  -- 人事(INBOUND)連携用CSVファイル保管場所
  cv_prf_fil           CONSTANT VARCHAR2(30) := 'XXCMM1_002A01_IN_FILE';  -- 人事連携用社員データ取込用CSVファイル出力先
  cv_prf_supervisor    CONSTANT VARCHAR2(30) := 'XXCMM1_002A01_SUPERVISOR_CD'; -- 管理者従業員番号
  cv_prf_default       CONSTANT VARCHAR2(30) := 'XXCMM1_002A01_DEFAULT_CD';   -- デフォルト費用勘定
  cv_prf_password      CONSTANT VARCHAR2(30) := 'XXCMM1_002A01_PASSWORD';  -- 初期パスワード

  -- トークン
  cv_cnt_token          CONSTANT VARCHAR2(10) := 'COUNT';              -- 件数メッセージ用トークン名
  cv_tkn_ng_profile     CONSTANT VARCHAR2(15) := 'NG_PROFILE';         -- エラープロファイル名
  cv_tkn_ng_word        CONSTANT VARCHAR2(10) := 'NG_WORD';            -- エラー項目名
  cv_tkn_ng_data        CONSTANT VARCHAR2(10) := 'NG_DATA';            -- エラーデータ
  cv_tkn_ng_table       CONSTANT VARCHAR2(10) := 'NG_TABLE';           -- エラーテーブル
  cv_tkn_ng_code        CONSTANT VARCHAR2(10) := 'NG_CODE';            -- エラーコード
  cv_tkn_ng_user        CONSTANT VARCHAR2(10) := 'NG_USER';            -- エラー社員番号
  cv_tkn_ng_err         CONSTANT VARCHAR2(10) := 'NG_ERR';             -- エラー内容
  cv_tkn_filename       CONSTANT VARCHAR2(10) := 'FILE_NAME';          -- ファイル名
  cv_tkn_apiname        CONSTANT VARCHAR2(10) := 'API_NAME';           -- API名
  cv_prf_dir_nm         CONSTANT VARCHAR2(20) := 'CSVファイル出力先';  -- プロファイル;
  cv_prf_fil_nm         CONSTANT VARCHAR2(20) := 'CSVファイル名';      -- プロファイル;
  cv_prf_supervisor_nm  CONSTANT VARCHAR2(20) := '管理者従業員番号';   -- プロファイル;
  cv_prf_supervisor_nm2 CONSTANT VARCHAR2(40) := '管理者従業員番号(従業員未登録データ)'; -- プロファイル;
  cv_prf_default_nm     CONSTANT VARCHAR2(20) := 'デフォルト費用勘定'; -- プロファイル;
  cv_prf_password_nm    CONSTANT VARCHAR2(20) := '初期パスワード';     -- プロファイル;
  cv_xxcmm1_in_if_nm            CONSTANT VARCHAR2(20) := '社員インタフェース';   -- ファイル名
  cv_per_all_people_f_nm        CONSTANT VARCHAR2(20) := '従業員マスタ';         -- ファイル名
  cv_per_all_assignments_f_nm   CONSTANT VARCHAR2(30) := 'アサインメントマスタ'; -- ファイル名
  cv_fnd_user_nm                CONSTANT VARCHAR2(20) := 'ユーザーマスタ';       -- ファイル名
  cv_fnd_user_resp_group_a_nm   CONSTANT VARCHAR2(20) := 'ユーザー職責マスタ';   -- ファイル名
  cv_employee_nm        CONSTANT VARCHAR2(10) := '社員番号';            -- 項目名
  cv_employee_err_nm    CONSTANT VARCHAR2(20) := '社員番号重複';        -- 項目名
  cv_data_err           CONSTANT VARCHAR2(20) := 'データ異常';          -- 項目名

  --参照コードマスタ.タイプ(fnd_lookup_values_vl.lookup_type)
  cv_flv_license        CONSTANT VARCHAR2(30) := 'XXCMM_QUALIFICATION_CODE';    -- 資格テーブル
  cv_flv_job_post       CONSTANT VARCHAR2(30) := 'XXCMM_POSITION_CODE';         -- 職位テーブル
  cv_flv_job_duty       CONSTANT VARCHAR2(30) := 'XXCMM_JOB_CODE';              -- 職務テーブル
  cv_flv_job_type       CONSTANT VARCHAR2(30) := 'XXCMM_OCCUPATIONAL_CODE';     -- 職種テーブル
  cv_flv_job_system     CONSTANT VARCHAR2(30) := 'XXCMM_002A01_**';  -- 適用労働時間制テーブル
  cv_flv_consent        CONSTANT VARCHAR2(30) := 'XXCMM_002A01_**';  -- 承認区分テーブル
  cv_flv_agent          CONSTANT VARCHAR2(30) := 'XXCMM_002A01_**';  -- 代行区分テーブル
  cv_flv_responsibility CONSTANT VARCHAR2(30) := 'XXCMM1_002A01_RESP';  -- 職責自動割当テーブル
--
  -- テーブル名
  cd_sysdate           DATE := SYSDATE;     -- 処理開始時間(YYYYMMDDHH24MISS)
  cd_process_date      DATE;                -- 業務日付(YYYYMMDD)
  cc_process_date      CHAR(8);             -- 業務日付(YYYYMMDD)
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- 各マスタへの反映処理に必要なデータを格納するレコード
  TYPE masters_rec IS RECORD(
--   -- 従業員インタフェース
    -- 区分
    proc_flg                VARCHAR2(1),  -- 更新区分('U':処理対象(gv_sts_update),'E':更新不可能(gv_sts_error),'S':変更なし(gv_sts_thru))
    proc_kbn                VARCHAR2(1),  -- 連携区分('Y':連携するデータ)
    emp_kbn                 VARCHAR2(1),  -- 社員状態('I':新規社員(gv_kbn_new)、'U'：既存社員(gv_kbn_employee)、'D'：退職者(gv_kbn_retiree))
    ymd_kbn                 VARCHAR2(1),  -- 入社日連携区分('Y':日付変更データ)
    retire_kbn              VARCHAR2(1),  -- 退職区分('Y':退職するデータ)
    resp_kbn                VARCHAR2(1),  -- 職責・管理者変更区分('Y':変更するデータ,'N':自動割当不可,NULL：変更しない)
    location_id_kbn         VARCHAR2(1),  -- 事業所変更区分('Y':変更する)
    row_err_message         VARCHAR2(1000),  -- 警告メッセージ
    -- 社員取込インタフェース
    employee_number         xxcmm_in_people_if.employee_number%type,    --社員番号
    hire_date               xxcmm_in_people_if.hire_date%type,          --入社年月日
    actual_termination_date xxcmm_in_people_if.actual_termination_date%type,--退職年月日
    last_name_kanji         xxcmm_in_people_if.last_name_kanji%type,    --漢字姓
    first_name_kanji        xxcmm_in_people_if.first_name_kanji%type,   --漢字名
    last_name               xxcmm_in_people_if.last_name%type,          --カナ姓
    first_name              xxcmm_in_people_if.first_name%type,         --カナ名
    sex                     xxcmm_in_people_if.sex%type,                --性別
    employee_division       xxcmm_in_people_if.employee_division%type,  --社員・外部委託区分
    location_code           xxcmm_in_people_if.location_code%type,      --所属コード（新）
    change_code             xxcmm_in_people_if.change_code%type,        --異動事由コード
    announce_date           xxcmm_in_people_if.announce_date%type,      --発令日
    office_location_code    xxcmm_in_people_if.office_location_code%type, --勤務地拠点コード（新）
    license_code            xxcmm_in_people_if.license_code%type,       --資格コード（新）
    license_name            xxcmm_in_people_if.license_name%type,       --資格名（新）
    job_post                xxcmm_in_people_if.job_post%type,           --職位コード（新）
    job_post_name           xxcmm_in_people_if.job_post_name%type,      --職位名（新）
    job_duty                xxcmm_in_people_if.job_duty%type,           --職務コード（新）
    job_duty_name           xxcmm_in_people_if.job_duty_name%type,      --職務名（新）
    job_type                xxcmm_in_people_if.job_type%type,           --職種コード（新）
    job_type_name           xxcmm_in_people_if.job_type_name%type,      --職種名（新）
    job_system              xxcmm_in_people_if.job_system%type,         --適用労働時間制コード（新）
    job_system_name         xxcmm_in_people_if.job_system_name%type,    --適用労働名（新）
    job_post_order          xxcmm_in_people_if.job_post_order%type,     --職位並順コード（新）
    consent_division        xxcmm_in_people_if.consent_division%type,   --承認区分（新）
    agent_division          xxcmm_in_people_if.agent_division%type,     --代行区分（新）
    office_location_code_old xxcmm_in_people_if.office_location_code_old%type,--勤務地拠点コード（旧）
    location_code_old       xxcmm_in_people_if.location_code_old%type,  --所属コード（旧）
    license_code_old        xxcmm_in_people_if.license_code_old%type,   --資格コード（旧）
    license_code_name_old   xxcmm_in_people_if.license_code_name_old%type,--資格名（旧）
    job_post_old            xxcmm_in_people_if.job_post_old%type,       --職位コード（旧）
    job_post_name_old       xxcmm_in_people_if.job_post_name_old%type,  --職位名（旧）
    job_duty_old            xxcmm_in_people_if.job_duty_old%type,       --職務コード（旧）
    job_duty_name_old       xxcmm_in_people_if.job_duty_name_old%type,  --職務名（旧）
    job_type_old            xxcmm_in_people_if.job_type_old%type,       --職種コード（旧）
    job_type_name_old       xxcmm_in_people_if.job_type_name_old%type,  --職種名（旧）
    job_system_old          xxcmm_in_people_if.job_system_old%type,     --適用労働時間制コード（旧）
    job_system_name_old     xxcmm_in_people_if.job_system_name_old%type,--適用労働名（旧）
    job_post_order_old      xxcmm_in_people_if.job_post_order_old%type, --職位並順コード（旧）
    consent_division_old    xxcmm_in_people_if.consent_division_old%type, --承認区分（旧）
    agent_division_old      xxcmm_in_people_if.agent_division_old%type, --代行区分（旧）
    -- 従業員マスタ
    person_id               per_all_people_f.person_id%TYPE,                --従業員ID
    hire_date_old           per_all_people_f.effective_start_date%type,     --既存_入社年月日
    pap_version             per_all_people_f.object_version_number%TYPE,    --バージョン番号
    -- アサインメントマスタ
    assignment_id           per_all_assignments_f.assignment_id%TYPE,       --アサインメントID
    assignment_number       per_all_assignments_f.assignment_number%TYPE,   --アサインメント番号
    effective_start_date    per_all_assignments_f.effective_start_date%TYPE,--登録年月日
    effective_end_date      per_all_assignments_f.effective_end_date%TYPE,  --登録期限年月日
    location_id             per_all_assignments_f.location_id%TYPE,         --事業所
    supervisor_id           per_all_assignments_f.supervisor_id%TYPE,       --管理者
    paa_version             per_all_assignments_f.object_version_number%TYPE, --バージョン番号
    -- ユーザマスタ
    user_id                 fnd_user.user_id%TYPE,                            --ユーザーID
    -- サービス期間マスタ
    period_of_service_id    per_periods_of_service.period_of_service_id%TYPE, --サービスID
    ppos_version            per_periods_of_service.object_version_number%TYPE --バージョン番号
  );

--
  -- 各マスタへ反映するデータを格納する結合配列
  TYPE masters_tbl IS TABLE OF masters_rec INDEX BY BINARY_INTEGER;
--
  -- 各マスタのデータを格納するレコード
  TYPE check_rec IS RECORD(
    -- 従業員マスタ
    person_id               per_all_people_f.person_id%type,             -- 従業員ID
    effective_start_date    per_all_people_f.effective_start_date%type,  -- 登録年月日
    last_name               per_all_people_f.last_name%type,             -- カナ姓
    employee_number         per_all_people_f.employee_number%type,       -- 従業員番号
    first_name              per_all_people_f.first_name%type,            -- カナ名
    sex                     per_all_people_f.sex%type,                   -- 性別
    employee_division       per_all_people_f.attribute3%type,            -- 従業員区分
    license_code            per_all_people_f.attribute7%type,            -- 資格コード（新）
    license_name            per_all_people_f.attribute8%type,            -- 資格名（新）
    job_post                per_all_people_f.attribute11%type,           -- 職位コード（新）
    job_post_name           per_all_people_f.attribute12%type,           -- 職位名（新）
    job_duty                per_all_people_f.attribute15%type,           -- 職務コード（新）
    job_duty_name           per_all_people_f.attribute16%type,           -- 職務名（新）
    job_type                per_all_people_f.attribute19%type,           -- 職種コード（新）
    job_type_name           per_all_people_f.attribute20%type,           -- 職種名（新）
    license_code_old        per_all_people_f.attribute9%type,            -- 資格コード（旧）
    license_code_name_old   per_all_people_f.attribute10%type,           -- 資格名（旧）
    job_post_old            per_all_people_f.attribute13%type,           -- 職位コード（旧）
    job_post_name_old       per_all_people_f.attribute14%type,           -- 職位名（旧）
    job_duty_old            per_all_people_f.attribute17%type,           -- 職務コード（旧）
    job_duty_name_old       per_all_people_f.attribute18%type,           -- 務名（旧）
    job_type_old            per_all_people_f.attribute21%type,           -- 職種コード（旧）
    job_type_name_old       per_all_people_f.attribute22%type,           -- 職種名（旧）
    pap_location_id         per_all_people_f.attribute28%type,           -- 起票部門
    last_name_kanji         per_all_people_f.per_information18%type,     -- 漢字姓
    first_name_kanji        per_all_people_f.per_information19%type,     -- 漢字名
    pap_version             per_all_people_f.object_version_number%type, -- バージョン番号
    -- アサインメントマスタ
    assignment_id           per_all_assignments_f.assignment_id%type,    -- アサインメントID
    assignment_number       per_all_assignments_f.assignment_number%type,-- アサインメント番号
    paa_effective_start_date per_all_assignments_f.effective_start_date%type, -- 登録年月日
    paa_effective_end_date  per_all_assignments_f.effective_end_date%type, -- 登録期限年月日
    location_id             per_all_assignments_f.location_id%type,      -- 事業所
    supervisor_id           per_all_assignments_f.supervisor_id%type,    -- 管理者
    change_code             per_all_assignments_f.ass_attribute1%type,   -- 異動事由コード
    announce_date           per_all_assignments_f.ass_attribute2%type,   -- 発令日
    office_location_code    per_all_assignments_f.ass_attribute3%type,   -- 勤務地拠点コード（新）
    office_location_code_old per_all_assignments_f.ass_attribute4%type,  -- 勤務地拠点コード（旧）
    location_code           per_all_assignments_f.ass_attribute5%type,   -- 拠点コード（新）
    location_code_old       per_all_assignments_f.ass_attribute6%type,   -- 拠点コード（旧）
    job_system              per_all_assignments_f.ass_attribute7%type,   -- 適用労働時間制コード（新）
    job_system_name         per_all_assignments_f.ass_attribute8%type,   -- 適用労働名（新）
    job_system_old          per_all_assignments_f.ass_attribute9%type,   -- 適用労働時間制コード（旧）
    job_system_name_old     per_all_assignments_f.ass_attribute10%type,  -- 適用労働名（旧）
    job_post_order          per_all_assignments_f.ass_attribute11%type,  -- 職位並順コード（新）
    job_post_order_old      per_all_assignments_f.ass_attribute12%type,  -- 職位並順コード（旧）
    consent_division        per_all_assignments_f.ass_attribute13%type,  -- 承認区分（新）
    consent_division_old    per_all_assignments_f.ass_attribute14%type,  -- 承認区分（旧）
    agent_division          per_all_assignments_f.ass_attribute15%type,  -- 代行区分（新）
    agent_division_old      per_all_assignments_f.ass_attribute16%type,  -- 代行区分（旧）
    paa_version             per_all_assignments_f.object_version_number%type, -- バージョン番号(アサインメント)
    -- 従業員サービス期間マスタ
    period_of_service_id    per_periods_of_service.period_of_service_id%type, -- サービスID
    actual_termination_date per_periods_of_service.actual_termination_date%type, -- 退職年月日
    ppos_version            per_periods_of_service.object_version_number%type
  );
  lr_check_rec  check_rec;  -- マスタ取得データ格納エリア

  -- 出力するログを格納するレコード
  TYPE report_rec IS RECORD(
    -- 区分(masterと同じ)
    proc_flg                 VARCHAR2(1),  -- 更新区分('U':処理対象,'E':更新不可能,'S':変更なし)
    -- 出力内容(社員インターフェースと同じ)
    employee_number          xxcmm_in_people_if.employee_number%type,    --社員番号
    hire_date                xxcmm_in_people_if.hire_date%type,          --入社年月日
    actual_termination_date  xxcmm_in_people_if.actual_termination_date%type,--退職年月日
    last_name_kanji          xxcmm_in_people_if.last_name_kanji%type,    --漢字姓
    first_name_kanji         xxcmm_in_people_if.first_name_kanji%type,   --漢字名
    last_name                xxcmm_in_people_if.last_name%type,          --カナ姓
    first_name               xxcmm_in_people_if.first_name%type,         --カナ名
    sex                      xxcmm_in_people_if.sex%type,                --性別
    employee_division        xxcmm_in_people_if.employee_division%type,  --社員・外部委託区分
    location_code            xxcmm_in_people_if.location_code%type,      --所属コード（新）
    change_code              xxcmm_in_people_if.change_code%type,        --異動事由コード
    announce_date            xxcmm_in_people_if.announce_date%type,      --発令日
    office_location_code     xxcmm_in_people_if.office_location_code%type, --勤務地拠点コード（新）
    license_code             xxcmm_in_people_if.license_code%type,       --資格コード（新）
    license_name             xxcmm_in_people_if.license_name%type,       --資格名（新）
    job_post                 xxcmm_in_people_if.job_post%type,           --職位コード（新）
    job_post_name            xxcmm_in_people_if.job_post_name%type,      --職位名（新）
    job_duty                 xxcmm_in_people_if.job_duty%type,           --職務コード（新）
    job_duty_name            xxcmm_in_people_if.job_duty_name%type,      --職務名（新）
    job_type                 xxcmm_in_people_if.job_type%type,           --職種コード（新）
    job_type_name            xxcmm_in_people_if.job_type_name%type,      --職種名（新）
    job_system               xxcmm_in_people_if.job_system%type,         --適用労働時間制コード（新）
    job_system_name          xxcmm_in_people_if.job_system_name%type,    --適用労働名（新）
    job_post_order           xxcmm_in_people_if.job_post_order%type,     --職位並順コード（新）
    consent_division         xxcmm_in_people_if.consent_division%type,   --承認区分（新）
    agent_division           xxcmm_in_people_if.agent_division%type,     --代行区分（新）
    office_location_code_old xxcmm_in_people_if.office_location_code_old%type,--勤務地拠点コード（旧）
    location_code_old        xxcmm_in_people_if.location_code_old%type,  --所属コード（旧）
    license_code_old         xxcmm_in_people_if.license_code_old%type,   --資格コード（旧）
    license_code_name_old    xxcmm_in_people_if.license_code_name_old%type,--資格名（旧）
    job_post_old             xxcmm_in_people_if.job_post_old%type,       --職位コード（旧）
    job_post_name_old        xxcmm_in_people_if.job_post_name_old%type,  --職位名（旧）
    job_duty_old             xxcmm_in_people_if.job_duty_old%type,       --職務コード（旧）
    job_duty_name_old        xxcmm_in_people_if.job_duty_name_old%type,  --職務名（旧）
    job_type_old             xxcmm_in_people_if.job_type_old%type,       --職種コード（旧）
    job_type_name_old        xxcmm_in_people_if.job_type_name_old%type,  --職種名（旧）
    job_system_old           xxcmm_in_people_if.job_system_old%type,     --適用労働時間制コード（旧）
    job_system_name_old      xxcmm_in_people_if.job_system_name_old%type,--適用労働名（旧）
    job_post_order_old       xxcmm_in_people_if.job_post_order_old%type, --職位並順コード（旧）
    consent_division_old     xxcmm_in_people_if.consent_division_old%type, --承認区分（旧）
    agent_division_old       xxcmm_in_people_if.agent_division_old%type, --代行区分（旧）
--
    message                   VARCHAR2(1000)
  );
--
  -- 出力するレポートを格納する結合配列
  TYPE report_normal_tbl IS TABLE OF report_rec INDEX BY BINARY_INTEGER;
  TYPE report_warn_tbl IS TABLE OF report_rec INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_if             NUMBER;     -- 社員インターフェースカウント
  gn_rep_n_cnt      NUMBER;     -- レポート件数(正常)
  gn_rep_w_cnt      NUMBER;     -- レポート件数(警告)

  gv_bisiness_grp_id    per_person_types.business_group_id%TYPE;    -- ビジネスグループID(従業員)
  gv_bisiness_grp_id_ex per_person_types.business_group_id%TYPE;    -- ビジネスグループID(退職者)
  gv_person_type        per_person_types.person_type_id%TYPE;       -- パーソンタイプ(従業員)
  gv_person_type_ex     per_person_types.person_type_id%TYPE;       -- パーソンタイプ(退職者)

--プロファイル
  gv_directory      VARCHAR2(255);         -- プロファイル・ファイルパス名
  gv_file_name      VARCHAR2(255);         -- プロファイル・ファイル名
  gv_supervisor     VARCHAR2(255);         -- プロファイル・管理者従業員番号
  gv_default        VARCHAR2(255);         -- プロファイル・デフォルト費用勘定
  gv_password       VARCHAR2(255);         -- プロファイル・初期パスワード
  gn_person_id      NUMBER(10);            -- ﾌﾟﾛﾌｧｲﾙ管理者従業員番号をパーソンIDに変換
  gn_person_start   DATE;                  -- ﾌﾟﾛﾌｧｲﾙ管理者の入社年月日
--
  gf_file_hand      UTL_FILE.FILE_TYPE;    -- ファイル・ハンドルの宣言

  gt_mst_tbl        masters_tbl;           -- 結合配列の定義
  gt_report_normal_tbl  report_normal_tbl; -- 結合配列の定義
  gt_report_warn_tbl    report_warn_tbl;     -- 結合配列の定義
--
  -- 定数
  gn_created_by               NUMBER;                     -- 作成者
  gd_creation_date            DATE;                       -- 作成日
  gd_last_update_date         DATE;                       -- 最終更新日
  gn_last_update_by           NUMBER;                     -- 最終更新者
  gn_last_update_login        NUMBER;                     -- 最終更新ログイン
  gn_request_id               NUMBER;                     -- 要求ID
  gn_program_application_id   NUMBER;                     -- プログラムアプリケーションID
  gn_program_id               NUMBER;                     -- プログラムID
  gd_program_update_date      DATE;                       -- プログラム更新日
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
--

  -- 社員インタフェース
  CURSOR gc_xip_cur
  IS
    SELECT xip.employee_number
    FROM   xxcmm_in_people_if xip    -- 従業員マスタ
    FOR UPDATE OF xip.employee_number NOWAIT;

  -- 従業員マスタ
  CURSOR gc_ppf_cur
  IS
    SELECT pap.person_id
    FROM   per_all_people_f pap    -- 従業員マスタ
    WHERE  EXISTS
          (SELECT xip.employee_number
           FROM   xxcmm_in_people_if xip    -- 社員インタフェース
           WHERE  xip.employee_number = pap.employee_number)
    FOR UPDATE OF pap.person_id NOWAIT;
--
  -- アサインメントマスタ
  CURSOR gc_paf_cur
  IS
    SELECT paa.assignment_id
    FROM   per_all_assignments_f paa    -- アサインメントマスタ
    WHERE  EXISTS
          (SELECT pap.person_id
           FROM   per_all_people_f pap    -- 従業員マスタ
           WHERE  EXISTS
                 (SELECT xip.employee_number
                  FROM   xxcmm_in_people_if xip    -- 社員インタフェース
                  WHERE  xip.employee_number = pap.employee_number)
           AND    pap.person_id = paa.person_id)
    FOR UPDATE OF paa.assignment_id NOWAIT;
--
  -- ユーザーマスタ
  CURSOR gc_fu_cur
  IS
    SELECT fu.user_id
    FROM   fnd_user fu    -- ユーザーマスタ
    WHERE  EXISTS
          (SELECT pap.person_id
           FROM   per_all_people_f pap    -- 従業員マスタ
           WHERE  EXISTS
                 (SELECT xip.employee_number
                  FROM   xxcmm_in_people_if xip    -- 社員インタフェース
                  WHERE  xip.employee_number = pap.employee_number)
           AND    pap.person_id = fu.employee_id)
    FOR UPDATE OF fu.user_id NOWAIT;
--
  -- ユーザー職責マスタ
  CURSOR gc_fug_cur
  IS
    SELECT fug.user_id
    FROM   fnd_user_resp_groups_all fug    -- ユーザー職責マスタ
    WHERE  EXISTS
          (SELECT fu.user_id
           FROM   fnd_user fu    -- ユーザーマスタ
           WHERE  EXISTS
                 (SELECT pap.person_id
                  FROM   per_all_people_f pap    -- 従業員マスタ
                  WHERE  EXISTS
                        (SELECT xip.employee_number
                         FROM   xxcmm_in_people_if xip    -- 社員インタフェース
                         WHERE  xip.employee_number = pap.employee_number)
                  AND    pap.person_id = fu.employee_id)
           AND    fu.user_id = fug.user_id)
    FOR UPDATE OF fug.user_id NOWAIT;
--
  /***********************************************************************************
   * Procedure Name   : init_get_profile
   * Description      : プロファイルより初期値を取得します。
   ***********************************************************************************/
  PROCEDURE init_get_profile(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init_get_profile'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_token_value1  VARCHAR2(40);
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
    -- 社員データ取込用CSVファイル保管場所の取得
    gv_directory := fnd_profile.value(cv_prf_dir);
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_directory IS NULL) THEN
      lv_token_value1 := cv_prf_dir_nm;
      RAISE global_process_expt;
    END IF;
--
    -- 社員データ取込用ファイル名取得
    gv_file_name := FND_PROFILE.VALUE(cv_prf_fil);
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_file_name IS NULL) THEN
      lv_token_value1 := cv_prf_fil_nm;
      RAISE global_process_expt;
    END IF;
--
    -- 管理者従業員番号取得
    gv_supervisor := fnd_profile.value(cv_prf_supervisor);
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_supervisor IS NULL) THEN
      lv_token_value1 := cv_prf_supervisor_nm;
      RAISE global_process_expt;
    ELSE
      -- 取得管理者の従業員番号を取得
      BEGIN
        SELECT paa.person_id,
               ppos.date_start
        INTO   gn_person_id,
               gn_person_start
        FROM   per_all_assignments_f paa,                           -- アサインメントマスタ
               per_periods_of_service ppos,                         -- 従業員サービス期間マスタ
               per_all_people_f pap                                 -- 従業員マスタ
        WHERE  pap.employee_number = gv_supervisor                  -- 従業員番号
        AND    pap.person_id = paa.person_id                        -- 従業員ID
        AND    paa.period_of_service_id = ppos.period_of_service_id -- サービスID
        AND    pap.effective_start_date = ppos.date_start           -- 登録年月日
        AND    ppos.actual_termination_date IS NULL;                -- 退職日
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
            lv_token_value1 := cv_prf_supervisor_nm2;
            RAISE global_process_expt;
        WHEN OTHERS THEN
            RAISE global_api_others_expt;
      END;
    END IF;
--
    -- デフォルト費用勘定取得
    gv_default := FND_PROFILE.VALUE(cv_prf_default);
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_default IS NULL) THEN
      lv_token_value1 := cv_prf_default_nm;
      RAISE global_process_expt;
    END IF;
--
    -- 初期パスワード取得
    gv_password := FND_PROFILE.VALUE(cv_prf_password);
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_password IS NULL) THEN
      lv_token_value1 := cv_prf_password_nm;
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_process_expt THEN                   --*** プロファイル取得エラー ***--
      -- *** 任意で例外処理を記述する ****
      lv_errmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                   ,iv_name         => cv_prf_get_err
                   ,iv_token_name1  => cv_tkn_ng_profile
                   ,iv_token_value1 => lv_token_value1
                  );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                   --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END init_get_profile;
--
  /***********************************************************************************
   * Procedure Name   : init_file_lock
   * Description      : ファイルロック処理を行います。
   ***********************************************************************************/
  PROCEDURE init_file_lock(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init_file_lock'; -- プログラム名
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
    lv_token_value1  VARCHAR2(40);
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
    -- 社員インタフェース
    BEGIN
      OPEN gc_xip_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_token_value1 := cv_xxcmm1_in_if_nm;
        RAISE global_process_expt;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
    CLOSE gc_xip_cur;
--
    -- 従業員マスタ
    BEGIN
      OPEN gc_ppf_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_token_value1 := cv_per_all_people_f_nm;
        RAISE global_process_expt;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
    CLOSE gc_ppf_cur;
--
    -- アサインメントマスタ
    BEGIN
      OPEN gc_paf_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_token_value1 := cv_per_all_assignments_f_nm;
        RAISE global_process_expt;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
    CLOSE gc_paf_cur;
--
    -- ユーザーマスタ
    BEGIN
      OPEN gc_fu_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_token_value1 := cv_fnd_user_nm;
        RAISE global_process_expt;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
    CLOSE gc_fu_cur;
--
    -- ユーザー職責マスタ
    BEGIN
      OPEN gc_fug_cur;
    EXCEPTION
      WHEN lock_expt THEN
        lv_token_value1 := cv_fnd_user_resp_group_a_nm;
        RAISE global_process_expt;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
    CLOSE gc_fug_cur;

    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
    -- *** 任意で例外処理を記述する ****
    WHEN global_process_expt THEN                           --*** ファイルロックエラー ***--
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_appl_short_name
                  ,iv_name         => cv_file_lock_err
                  ,iv_token_name1  => cv_tkn_ng_table
                  ,iv_token_value1 => lv_token_value1
                 );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
      IF (gc_xip_cur%ISOPEN) THEN
      -- カーソルのクローズ
         CLOSE gc_xip_cur;
      END IF;

    -- 従業員マスタ
      IF (gc_ppf_cur%ISOPEN) THEN
      -- カーソルのクローズ
         CLOSE gc_ppf_cur;
      END IF;

    -- アサインメントマスタ
      IF (gc_ppf_cur%ISOPEN) THEN
         -- カーソルのクローズ
         CLOSE gc_ppf_cur;
      END IF;
--
    -- ユーザーマスタ
      IF (gc_fu_cur%ISOPEN) THEN
         -- カーソルのクローズ
        CLOSE gc_fu_cur;
      END IF;
--
    -- ユーザー職責マスタ
      IF (gc_fug_cur%ISOPEN) THEN
      -- カーソルのクローズ
        CLOSE gc_fug_cur;
      END IF;
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
      IF (gc_xip_cur%ISOPEN) THEN
      -- カーソルのクローズ
         CLOSE gc_xip_cur;
      END IF;

    -- 従業員マスタ
      IF (gc_ppf_cur%ISOPEN) THEN
      -- カーソルのクローズ
         CLOSE gc_ppf_cur;
      END IF;

    -- アサインメントマスタ
      IF (gc_ppf_cur%ISOPEN) THEN
         -- カーソルのクローズ
         CLOSE gc_ppf_cur;
      END IF;
--
    -- ユーザーマスタ
      IF (gc_fu_cur%ISOPEN) THEN
         -- カーソルのクローズ
        CLOSE gc_fu_cur;
      END IF;
--
    -- ユーザー職責マスタ
      IF (gc_fug_cur%ISOPEN) THEN
      -- カーソルのクローズ
        CLOSE gc_fug_cur;
      END IF;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  固定部 END   ##########################################
--
  END init_file_lock;
--
  /***********************************************************************************
   * Procedure Name   : check_aff_bumon
   * Description      : AFF部門マスタチェック処理（業務日付時点・過去データ込み）
   ***********************************************************************************/
  PROCEDURE check_aff_bumon(
    iv_bumon      IN  VARCHAR2,     --   チェック対象データ
    iv_flg        IN  VARCHAR2,     --   業務日付時点でのAFF部門''、過去も含めたAFF部門'A'
    iv_token      IN  VARCHAR2,     --   エラー時のトークン
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_aff_bumon'; -- プログラム名
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
    lv_bumon    VARCHAR2(4);
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
    IF  iv_flg IS NULL THEN
      BEGIN
    -- AFF部門（部門階層ビュー）
        SELECT xhd.cur_dpt_cd
        INTO   lv_bumon
        FROM   xxcmm_hierarchy_dept_v xhd
        WHERE  xhd.cur_dpt_cd = iv_bumon   -- 最下層部門コードが同じ
        AND    ROWNUM = 1;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_bumon := NULL; -- 該当データなし
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
    ELSE
      BEGIN
    -- AFF部門（全部門階層ビュー）
        SELECT xhd.cur_dpt_cd
        INTO   lv_bumon
        FROM   xxcmm_hierarchy_dept_all_v xhd
        WHERE  xhd.cur_dpt_cd = iv_bumon   -- 最下層部門コードが同じ
        AND    ROWNUM = 1;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_bumon := NULL; -- 該当データなし
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
    END IF;
--
    IF (lv_bumon IS NULL) THEN
      -- マスタ存在チェックエラー
      lv_errmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                    ,iv_name         => cv_no_data_err
                    ,iv_token_name1  => cv_tkn_ng_word
                    ,iv_token_value1 => iv_token
                    ,iv_token_name2  => cv_tkn_ng_code
                    ,iv_token_value2 => iv_bumon
                    );
      RAISE global_api_expt;
    END IF;

    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
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
--####################################  固定部 END   ##########################################
--
  END check_aff_bumon;
--
  /***********************************************************************************
   * Procedure Name   : get_location_id
   * Description      : ロケーションID(事業所)の取得を行います。
   ***********************************************************************************/
  PROCEDURE get_location_id(
    ir_masters_rec IN OUT masters_rec,  -- 1.チェック対象データ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_location_id'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    cv_office_location  CONSTANT VARCHAR2(30) := '勤務地拠点コード(新)'; -- 項目名
    cv_locations_all_nm CONSTANT VARCHAR2(20) := '事業所マスタ';         -- ファイル名
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
    -- 事業所マスタ
      SELECT hla.location_id
      INTO   ir_masters_rec.location_id  -- ロケーションID
      FROM   hr_locations_all hla        -- 事業所マスタ
      WHERE  hla.location_code  = ir_masters_rec.office_location_code; -- 勤務地拠点コード(新)

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      -- マスタ存在チェックエラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_no_data_err
                    ,iv_token_name1  => cv_tkn_ng_word
                    ,iv_token_value1 => cv_locations_all_nm
                    ,iv_token_name2  => cv_tkn_ng_code
                    ,iv_token_value2 => cv_office_location||ir_masters_rec.location_code
                   );
        RAISE global_process_expt;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
    WHEN global_process_expt THEN                          --*** 警告(更新不可データ) ***--
      ov_errmsg  := lv_errmsg;                                                 --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;                                            --# 任意 # 警告
--#################################  固定例外処理部 START   #######################################
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
--#####################################  固定部 END   #############################################
--
  END get_location_id;
--
  /***********************************************************************************
   * Procedure Name   : in_if_check_emp
   * Description      : データ連携対象チェック
   ***********************************************************************************/
  PROCEDURE in_if_check_emp(
    ir_masters_rec IN OUT masters_rec,  -- 1.チェック対象データ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'in_if_check_emp'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
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
    -- 従業員マスタ/アサインメントマスタ/従業員サービス期間マスタ(※check_recと同じ並びにする）
    CURSOR gc_per_cur(lv_emp in varchar2)
    IS
      SELECT pap.person_id            person_id,            --従業員ID
             pap.effective_start_date effective_start_date, --登録年月日
             pap.last_name            last_name,            --カナ姓
             pap.employee_number      employee_number,      --従業員番号
             pap.first_name           first_name,           --カナ名
             pap.sex                  sex,                  --性別
             pap.attribute3           employee_division,    --従業員区分
             pap.attribute7           license_code,         --資格コード（新）
             pap.attribute8           license_name,         --資格名（新）
             pap.attribute11          job_post,             --職位コード（新）
             pap.attribute12          job_post_name,        --職位名（新）
             pap.attribute15          job_duty,             --職務コード（新）
             pap.attribute16          job_duty_name,        --職務名（新）
             pap.attribute19          job_type,             --職種コード（新）
             pap.attribute20          job_type_name,        --職種名（新）
             pap.attribute9           license_code_old,     --資格コード（旧）
             pap.attribute10          license_code_name_old,--資格名（旧）
             pap.attribute13          job_post_old,         --職位コード（旧）
             pap.attribute14          job_post_name_old,    --職位名（旧）
             pap.attribute17          job_duty_old,         --職務コード（旧）
             pap.attribute18          job_duty_name_old,    --務名（旧）
             pap.attribute21          job_type_old,         --職種コード（旧）
             pap.attribute22          job_type_name_old,    --職種名（旧）
             pap.attribute28          pap_location_code,    --起票部門
             pap.per_information18    last_name_kanji,      --漢字姓
             pap.per_information19    first_name_kanji,     --漢字名
             pap.object_version_number pap_version,         --バージョン番号
             paa.assignment_id        assignment_id,        --アサインメントID
             paa.assignment_number    assignment_number,    --アサインメント番号
             paa.effective_start_date paa_effective_start_date,--登録年月日
             paa.effective_end_date   paa_effective_end_date,--登録期限年月日
             paa.location_id          location_id,          --事業所
             paa.supervisor_id        supervisor_id,        --管理者
             paa.ass_attribute1       change_code,          --異動事由コード
             paa.ass_attribute2       announce_date,        --発令日
             paa.ass_attribute3       office_location_code, --勤務地拠点コード（新）
             paa.ass_attribute4       office_location_code_old,--勤務地拠点コード（旧）
             paa.ass_attribute5       location_code,        --拠点コード（新）
             paa.ass_attribute6       location_code_old,    --拠点コード（旧）
             paa.ass_attribute7       job_system,           --適用労働時間制コード（新）
             paa.ass_attribute8       job_system_name,      --適用労働名（新）
             paa.ass_attribute9       job_system_old,       --適用労働時間制コード（旧）
             paa.ass_attribute10      job_system_name_old,  --適用労働名（旧）
             paa.ass_attribute11      job_post_order,       --職位並順コード（新）
             paa.ass_attribute12      job_post_order_old,   --職位並順コード（旧）
             paa.ass_attribute13      consent_division,     --承認区分（新）
             paa.ass_attribute14      consent_division_old, --承認区分（旧）
             paa.ass_attribute15      agent_division,       --代行区分（新）
             paa.ass_attribute16      agent_division_old,   --代行区分（旧）
             paa.object_version_number paa_version,         --バージョン番号(アサインメント)
             ppos.period_of_service_id period_of_service_id,--サービスID
             ppos.actual_termination_date actual_termination_date,--退職年月日
             ppos.object_version_number ppos_version        --バージョン番号(サービス期間マスタ)
      FROM   per_periods_of_service ppos,                   -- 従業員サービス期間マスタ
             per_all_assignments_f paa,                     -- アサインメントマスタ
             per_all_people_f pap                           -- 従業員マスタ
      WHERE  pap.employee_number = lv_emp

      AND    pap.current_emp_or_apl_flag = gv_const_y             -- 履歴フラグ
      AND    pap.person_id = paa.person_id                        -- 従業員ID
      AND    paa.period_of_service_id = ppos.period_of_service_id -- サービスID
      AND    pap.effective_start_date = ppos.date_start           -- 登録年月日(入社日)
      ORDER BY pap.person_id,pap.effective_start_date desc ,pap.effective_end_date
    ;
--
    -- *** ローカル・レコード ***
    gc_per_rec gc_per_cur%ROWTYPE;
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
    -- 新規社員登録処理
    lr_check_rec.employee_number := NULL;     -- 社員コード
    <<per_loop>>
      FOR gc_per_rec IN gc_per_cur(ir_masters_rec.employee_number) LOOP
      lr_check_rec := gc_per_rec;
      EXIT;
    END LOOP per_loop;
--
    IF lr_check_rec.employee_number IS NULL THEN
      ir_masters_rec.emp_kbn  := gv_kbn_new;  -- 新規社員
      ir_masters_rec.proc_kbn := gv_sts_yes;  -- 連携データ
      ir_masters_rec.ymd_kbn  := NULL;        -- 日付変更なし
      ir_masters_rec.resp_kbn := gv_sts_yes;  -- 職責・管理者 変更
      ir_masters_rec.location_id_kbn := gv_sts_yes;  -- 事業所 変更
      lr_check_rec.license_code := NULL;     -- 資格コード（新）
      lr_check_rec.job_post := NULL;         -- 職位コード（新）
      lr_check_rec.job_duty := NULL;         -- 職務コード（新）
      lr_check_rec.job_type := NULL;         -- 職種コード（新）
      lr_check_rec.job_system := NULL;       -- 適用労働時間制コード（新）
      lr_check_rec.job_post_order := NULL;   -- 職位並順コード（新）
      lr_check_rec.consent_division := NULL; -- 承認区分（新）
      lr_check_rec.agent_division := NULL;   -- 代行区分（新）
      IF (ir_masters_rec.actual_termination_date IS NOT NULL) THEN
        ir_masters_rec.retire_kbn  := gv_sts_yes; -- 退職データ
      END IF;
      --事業所マスタチェック(ロケーションIDの取得)
      get_location_id(
          ir_masters_rec
        ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,lv_retcode  -- リターン・コード             --# 固定 #
        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_warn) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_error) THEN
        RAISE global_api_others_expt;
      END IF;
    END IF;
--
    IF (ir_masters_rec.emp_kbn IS NULL) THEN
      -- 連携前の退職日がNULLの場合
      IF (lr_check_rec.actual_termination_date IS NULL) THEN
        ir_masters_rec.emp_kbn  := gv_kbn_employee;  -- 既存社員
        IF (ir_masters_rec.actual_termination_date IS NOT NULL) THEN
          ir_masters_rec.retire_kbn  := gv_sts_yes;  -- 退職データ
        END IF;
      ELSE
        ir_masters_rec.emp_kbn  := gv_kbn_retiree;  -- 退職者
        ir_masters_rec.retire_kbn  := NULL;  --退職処理なし
      END IF;

      -- 入社年月日・退職年月日以外のデータ差異判断
      IF (lr_check_rec.employee_number||lr_check_rec.last_name_kanji||lr_check_rec.first_name_kanji
        ||lr_check_rec.last_name||lr_check_rec.first_name||lr_check_rec.sex||lr_check_rec.employee_division
        ||lr_check_rec.location_code||lr_check_rec.change_code
        ||lr_check_rec.announce_date||lr_check_rec.office_location_code||lr_check_rec.license_code||lr_check_rec.license_name
        ||lr_check_rec.job_post||lr_check_rec.job_post_name||lr_check_rec.job_duty||lr_check_rec.job_duty_name
        ||lr_check_rec.job_type||lr_check_rec.job_type_name||lr_check_rec.job_system||lr_check_rec.job_system_name
        ||lr_check_rec.job_post_order||lr_check_rec.consent_division||lr_check_rec.agent_division
        ||lr_check_rec.office_location_code_old||lr_check_rec.location_code_old||lr_check_rec.license_code_old||lr_check_rec.license_code_name_old
        ||lr_check_rec.job_post_old||lr_check_rec.job_post_name_old||lr_check_rec.job_duty_old||lr_check_rec.job_duty_name_old
        ||lr_check_rec.job_type_old||lr_check_rec.job_type_name_old||lr_check_rec.job_system_old||lr_check_rec.job_system_name_old
        ||lr_check_rec.job_post_order_old||lr_check_rec.consent_division_old||lr_check_rec.agent_division_old)
          =
         (ir_masters_rec.employee_number||ir_masters_rec.last_name_kanji||ir_masters_rec.first_name_kanji
        ||ir_masters_rec.last_name||ir_masters_rec.first_name||ir_masters_rec.sex||ir_masters_rec.employee_division
        ||ir_masters_rec.location_code||ir_masters_rec.change_code
        ||ir_masters_rec.announce_date||ir_masters_rec.office_location_code||ir_masters_rec.license_code||ir_masters_rec.license_name
        ||ir_masters_rec.job_post||ir_masters_rec.job_post_name||ir_masters_rec.job_duty||ir_masters_rec.job_duty_name
        ||ir_masters_rec.job_type||ir_masters_rec.job_type_name||ir_masters_rec.job_system||ir_masters_rec.job_system_name
        ||ir_masters_rec.job_post_order||ir_masters_rec.consent_division||ir_masters_rec.agent_division
        ||ir_masters_rec.office_location_code_old||ir_masters_rec.location_code_old||ir_masters_rec.license_code_old||ir_masters_rec.license_code_name_old
        ||ir_masters_rec.job_post_old||ir_masters_rec.job_post_name_old||ir_masters_rec.job_duty_old||ir_masters_rec.job_duty_name_old
        ||ir_masters_rec.job_type_old||ir_masters_rec.job_type_name_old||ir_masters_rec.job_system_old||ir_masters_rec.job_system_name_old
        ||ir_masters_rec.job_post_order_old||ir_masters_rec.consent_division_old||ir_masters_rec.agent_division_old) THEN

        ir_masters_rec.proc_kbn := NULL;  -- 連携なし（差異なし）
        ir_masters_rec.resp_kbn := NULL;  -- 職責・管理者変更なし
        ir_masters_rec.location_id_kbn := NULL;  -- 事業所 変更なし
      ELSE
        ir_masters_rec.proc_kbn := gv_sts_yes;  -- 連携データ（差異あり）
        -- 所属コード（拠点コード）の変更判断
        IF (lr_check_rec.location_code <> ir_masters_rec.location_code) THEN
          ir_masters_rec.resp_kbn := gv_sts_yes;  -- 職責・管理者変更あり
        END IF;
        -- 勤務地拠点コード(新)の変更判断
        IF (lr_check_rec.office_location_code <> ir_masters_rec.office_location_code) THEN
          ir_masters_rec.location_id_kbn := gv_sts_yes;  -- 事業所 変更
        END IF;
      END IF;
--
      --事業所マスタチェック(ロケーションIDの取得) (再雇用処理で使用する為、事業所は取得しておく)
      get_location_id(
        ir_masters_rec
        ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,lv_retcode  -- リターン・コード             --# 固定 #
        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_warn) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_error) THEN
        RAISE global_api_others_expt;
      END IF;
--
      -- 入社年月日差異判断
      IF (lr_check_rec.effective_start_date = ir_masters_rec.hire_date) THEN
        ir_masters_rec.ymd_kbn  := NULL;  -- 入社日変更なし
      ELSE
        ir_masters_rec.ymd_kbn  := gv_sts_yes;  -- 入社日変更
      END IF;

      -- データ登録に必要なデータ格納
      -- 従業員マスタ
      ir_masters_rec.person_id            := lr_check_rec.person_id;     -- 従業員ID
      ir_masters_rec.pap_version          := lr_check_rec.pap_version;   -- バージョン番号
      ir_masters_rec.hire_date_old        := lr_check_rec.effective_start_date;   -- 既存_入社年月日
      -- アサインメントマスタ
      ir_masters_rec.assignment_id        := lr_check_rec.assignment_id;     -- アサインメントID
      ir_masters_rec.assignment_number    := lr_check_rec.assignment_number; -- アサインメント番号
      ir_masters_rec.supervisor_id        := lr_check_rec.supervisor_id;     -- 管理者
      ir_masters_rec.effective_start_date := lr_check_rec.paa_effective_start_date;  -- 登録年月日
      ir_masters_rec.effective_end_date   := lr_check_rec.paa_effective_end_date;    -- 登録期限年月日
      ir_masters_rec.paa_version          := lr_check_rec.paa_version;       -- バージョン番号
      -- サービス期間マスタ
      ir_masters_rec.period_of_service_id := lr_check_rec.period_of_service_id;  -- サービスID
      ir_masters_rec.ppos_version         := lr_check_rec.ppos_version;          -- バージョン番号

    END IF;

    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
    WHEN global_process_expt THEN                          --*** 警告(更新不可データ) ***--
      ov_errmsg  := lv_errmsg;                                                 --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;                                            --# 任意 # 警告
--#################################  固定例外処理部 START   #######################################
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
--#####################################  固定部 END   #############################################
--
  END in_if_check_emp;
--
  /**********************************************************************************
   * Procedure Name   : in_if_check
   * Description      : データ妥当性チェック処理(A-4)
   ***********************************************************************************/
  PROCEDURE in_if_check(
    ir_masters_rec IN OUT masters_rec,  -- 1.チェック対象データ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'in_if_check'; -- プログラム名
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
    cv_ymd_err_nm       CONSTANT VARCHAR2(20) := '入社年月日未設定';    -- 項目名
    cv_hire_date_nm     CONSTANT VARCHAR2(20) := '入社年月日';          -- 項目名
    cv_retire_date_nm   CONSTANT VARCHAR2(20) := '退職年月日';          -- 項目名
    cv_last_name_err_nm CONSTANT VARCHAR2(20) := 'カナ姓未設定';        -- 項目名
    cv_last_name_nm     CONSTANT VARCHAR2(10) := 'カナ姓';              -- 項目名
    cv_first_name_nm    CONSTANT VARCHAR2(10) := 'カナ名';              -- 項目名
    cv_last_kanji_nm    CONSTANT VARCHAR2(10) := '漢字姓';              -- 項目名
    cv_first_kanji_nm   CONSTANT VARCHAR2(10) := '漢字名';              -- 項目名
    cv_announce_date_nm CONSTANT VARCHAR2(20) := '発令日';              -- 項目名
    cv_announce_date_nm1 CONSTANT VARCHAR2(20) := '発令日未設定';       -- 項目名
    cv_announce_date_nm2 CONSTANT VARCHAR2(20) := '発令日未来日付';     -- 項目名
    cv_sex_nm           CONSTANT VARCHAR2(10) := '性別';                -- 項目名
    cv_division_nm      CONSTANT VARCHAR2(20) := '社員・外部委託区分';  -- 項目名
    cv_location_cd      CONSTANT VARCHAR2(20) := '所属コード';          -- 項目名
    cv_office_location  CONSTANT VARCHAR2(20) := '勤務地拠点コード';    -- 項目名
    cv_new              CONSTANT VARCHAR2(10) := '(新)';                -- 項目名
    cv_old              CONSTANT VARCHAR2(10) := '(旧)';                -- 項目名

    cv_all              CONSTANT VARCHAR2(1) := 'A';
--
    -- *** ローカル変数 ***
    lv_token_value2  VARCHAR2(30);
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
      --入社年月日
    IF (ir_masters_rec.hire_date IS NULL) THEN
       lv_token_value2 := cv_ymd_err_nm; -- '入社年月日未設定'
       RAISE global_process_expt;
    ELSIF (ir_masters_rec.hire_date) > cd_sysdate THEN -- 入社年月日とシステム日付の比較
       lv_errmsg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_st_ymd_err3
                    ,iv_token_name1  => cv_tkn_ng_word
                    ,iv_token_value1 => cv_employee_nm -- '社員番号'
                    ,iv_token_name2  => cv_tkn_ng_user
                    ,iv_token_value2 => ir_masters_rec.employee_number
                    );
       RAISE global_process2_expt;
    ELSIF (LENGTHB(TO_CHAR(ir_masters_rec.hire_date,'YYYYMMDD')) <> 8) THEN -- 日付妥当性チェック
       lv_token_value2 := cv_hire_date_nm; -- '入社年月日'
       RAISE global_process_expt;
    END IF;

    --退職年月日
    IF (ir_masters_rec.actual_termination_date IS NOT NULL) THEN
      IF (LENGTHB(TO_CHAR(ir_masters_rec.actual_termination_date,'YYYYMMDD')) <> 8) THEN -- 日付妥当性チェック
        lv_token_value2 := cv_retire_date_nm; -- '退職年月日'
        RAISE global_process_expt;
      ELSIF (ir_masters_rec.hire_date > ir_masters_rec.actual_termination_date) THEN -- 入社年月日と退職年月日の比較
        lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                     ,iv_name         => cv_st_ymd_err2
                     ,iv_token_name1  => cv_tkn_ng_word
                     ,iv_token_value1 => cv_employee_nm -- '社員番号'
                     ,iv_token_name2  => cv_tkn_ng_user
                     ,iv_token_value2 => ir_masters_rec.employee_number
                     );
        RAISE global_process2_expt;
      END IF;
    END IF;

    --カナ姓・カナ名
    IF (ir_masters_rec.last_name IS NULL) then
      lv_token_value2 := cv_last_name_err_nm;  -- 'カナ姓未設定';
      RAISE global_process_expt;
    ELSIF (NOT xxccp_common_pkg.chk_single_byte_kana(ir_masters_rec.last_name)) THEN -- 半角カタカナチェック
      lv_token_value2 := cv_last_name_nm;  -- 'カナ姓';
      RAISE global_process_expt;
    ELSIF (xxccp_common_pkg.chk_single_byte_kana(ir_masters_rec.first_name) = FALSE) THEN -- 半角カタカナチェック（NULL正常）
      lv_token_value2 := cv_first_name_nm; -- 'カナ名'
      RAISE global_process_expt;
    END IF;

    --漢字姓・漢字名
    IF (xxccp_common_pkg.chk_double_byte(ir_masters_rec.last_name_kanji) = FALSE) THEN
      lv_token_value2 := cv_last_kanji_nm; -- '漢字姓'
      RAISE global_process_expt;
    ELSIF (xxccp_common_pkg.chk_double_byte(ir_masters_rec.first_name_kanji) = FALSE) THEN
      lv_token_value2 := cv_first_kanji_nm; -- '漢字名'
      RAISE global_process_expt;
    END IF;

    --発令日
    IF (ir_masters_rec.announce_date IS NULL) THEN
      lv_token_value2 := cv_announce_date_nm1; -- '発令日未設定'
      RAISE global_process_expt;
    ELSIF (xxccp_common_pkg.chk_number(ir_masters_rec.announce_date) = FALSE) THEN -- 半角数字チェック（NULL正常）
      lv_token_value2 := cv_announce_date_nm; -- '発令日'
      RAISE global_process_expt;
    ELSIF (LENGTHB(ir_masters_rec.announce_date) <> 8) THEN -- 日付妥当性チェック
      lv_token_value2 := cv_announce_date_nm; -- '発令日'
      RAISE global_process_expt;
    ELSIF (ir_masters_rec.announce_date > cc_process_date) THEN
      lv_token_value2 := cv_announce_date_nm2; -- '発令日未来日付'
      RAISE global_process_expt;
    END IF;

    --性別
    IF (ir_masters_rec.sex NOT IN ('M','F')) THEN
      lv_token_value2 := cv_sex_nm; -- '性別'
      RAISE global_process_expt;
    END IF;

    --社員・外部委託区分
    IF (ir_masters_rec.employee_division NOT IN ('1','2')) THEN
      lv_token_value2 := cv_division_nm; -- '社員・外部委託区分'
      RAISE global_process_expt;
    END IF;

    --所属コード(新)
    IF (ir_masters_rec.location_code IS NULL) THEN
      lv_token_value2 := cv_location_cd||cv_new; -- '所属コード(新)'
      RAISE global_process_expt;
    ELSE
      check_aff_bumon(      --AFF部門コード存在チェック
        ir_masters_rec.location_code
        ,NULL                 -- 業務日付時点での使用部門
        ,cv_location_cd||cv_new  -- エラー用トークン:'所属コード(新)'
        ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,lv_retcode  -- リターン・コード             --# 固定 #
        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process2_expt;
      END IF;
    END IF;

    --勤務地拠点コード(新)
    IF (ir_masters_rec.office_location_code IS NULL) THEN
      lv_token_value2 := cv_office_location||cv_new; -- '勤務地拠点コード(新)'
      RAISE global_process_expt;
    ELSE
      check_aff_bumon(            --AFF部門コード存在チェック
        ir_masters_rec.office_location_code
        ,NULL                         -- 業務日付時点での使用部門
        ,cv_office_location||cv_new   -- エラー用トークン:'勤務地拠点コード(新)'
        ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,lv_retcode  -- リターン・コード             --# 固定 #
        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process2_expt;
      END IF;
    END IF;
--
    --所属コード(旧)
    IF (ir_masters_rec.location_code_old IS NOT NULL) THEN
      check_aff_bumon(    --AFF部門コード存在チェック
         ir_masters_rec.location_code_old
        ,cv_all               -- 全部門でのチェック
        ,cv_location_cd||cv_old  -- エラー用トークン:'所属コード(旧)'
        ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,lv_retcode  -- リターン・コード             --# 固定 #
        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process2_expt;
      END IF;
    END IF;

    --勤務地拠点コード(旧)
    IF (ir_masters_rec.office_location_code_old IS NOT NULL) THEN
      check_aff_bumon(            --AFF部門コード存在チェック
         ir_masters_rec.office_location_code_old
        ,cv_all                       -- 全部門でのチェック
        ,cv_office_location||cv_old   -- エラー用トークン:'勤務地拠点コード(旧)'
        ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,lv_retcode  -- リターン・コード             --# 固定 #
        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process2_expt;
      END IF;
    END IF;

    -- データ連携対象チェック
    in_if_check_emp(
       ir_masters_rec
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = cv_status_warn) THEN
      RAISE global_process2_expt;
    ELSIF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;

    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** 任意で例外処理を記述する ****
    WHEN global_process_expt THEN                           --*** 警告1(更新不可データ) ***--
      lv_errmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                   ,iv_name         => cv_data_check_err
                   ,iv_token_name1  => cv_tkn_ng_user
                   ,iv_token_value1 => ir_masters_rec.employee_number
                   ,iv_token_name2  => cv_tkn_ng_err
                   ,iv_token_value2 => lv_token_value2
                   );
      ov_errmsg  := lv_errmsg;                                                 --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;                                            --# 任意 # 警告
    WHEN global_process2_expt THEN                          --*** 警告2(更新不可データ) ***--
      ov_errmsg  := lv_errmsg;                                                 --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;                                            --# 任意 # 警告
--
--#################################  固定例外処理部 START   #######################################
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
  END in_if_check;
--
  /***********************************************************************************
   * Procedure Name   : check_fnd_user
   * Description      : ユーザーIDを取得し存在チェックを行います。
   ***********************************************************************************/
  PROCEDURE check_fnd_user(
    ir_masters_rec IN OUT masters_rec,  -- 1.チェック対象データ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_fnd_user'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
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
    BEGIN
      -- ユーザーマスタ
      SELECT fu.user_id
      INTO   ir_masters_rec.user_id
      FROM   fnd_user fu,          -- ユーザーマスタ
             per_all_people_f pap  -- 従業員マスタ
      WHERE  pap.employee_number = ir_masters_rec.employee_number
      AND    pap.person_id       = fu.employee_id
      AND    ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ir_masters_rec.user_id := NULL; -- 該当データなし
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
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
--#####################################  固定部 END   #############################################
--
  END check_fnd_user;
--
  /***********************************************************************************
   * Procedure Name   : check_fnd_lookup
   * Description      : 参照コードマスタ 情報取得処理
   ***********************************************************************************/
  PROCEDURE check_fnd_lookup(
    iv_type       IN  VARCHAR2,     -- 1.タイプ
    iv_code       IN  VARCHAR2,     -- 2.参照コード
    iv_token      IN  VARCHAR2,     -- 3.エラー時のトークン
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_fnd_lookup'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_flg  VARCHAR2(1) := NULL;
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
      -- 参照コードテーブル
      SELECT '1'
      INTO   lv_flg
      FROM   fnd_lookup_values_vl flv  -- 参照コードテーブル
      WHERE  flv.lookup_type = iv_type
      AND    flv.lookup_code = iv_code
      AND    flv.enabled_flag = gv_const_y
      AND    NVL(flv.start_date_active,cd_process_date) <= cd_process_date
      AND    NVL(flv.end_date_active,cd_process_date) >= cd_process_date
      AND    ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN       -- 該当データなし
        NULL;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    IF (lv_flg IS NULL) THEN
      -- マスタ存在チェックエラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_appl_short_name
                  ,iv_name         => cv_no_data_err
                  ,iv_token_name1  => cv_tkn_ng_word
                  ,iv_token_value1 => iv_token
                  ,iv_token_name2  => cv_tkn_ng_code
                  ,iv_token_value2 => iv_code
                 );
      RAISE global_process_expt;
    END IF;
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
    WHEN global_process_expt THEN                          --*** 警告(更新不可データ) ***--
      ov_errmsg  := lv_errmsg;                                                 --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;                                            --# 任意 # 警告
--
--#################################  固定例外処理部 START   #######################################
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
--#####################################  固定部 END   #############################################
--
  END check_fnd_lookup;
--
  /***********************************************************************************
   * Procedure Name   : check_code
   * Description      : コード存在チェック処理
   ***********************************************************************************/
  PROCEDURE check_code(
    ir_masters_rec IN OUT masters_rec,  -- 1.チェック対象データ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_code'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    lv_license_nm     CONSTANT VARCHAR2(30) := '資格コード(新)';  -- 資格名
    lv_job_post_nm    CONSTANT VARCHAR2(30) := '職位コード(新)';  -- 職位コード
    lv_job_duty_nm    CONSTANT VARCHAR2(30) := '職務コード(新)';  -- 職務コード
    lv_job_type_nm    CONSTANT VARCHAR2(30) := '職種コード(新)';  -- 職種コード
    lv_job_system_nm  CONSTANT VARCHAR2(30) := '適用労働時間制コード(新)';  -- 適用労働時間制コード
    lv_post_order_nm  CONSTANT VARCHAR2(30) := '職位並順コード(新)';  -- 職位並順コード
    lv_consent_nm     CONSTANT VARCHAR2(30) := '承認区分(新)';  -- 承認区分
    lv_agent_nm       CONSTANT VARCHAR2(30) := '代行区分(新)';  -- 代行区分
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
    -- 資格コード(新)
    IF (((ir_masters_rec.emp_kbn = gv_kbn_new) AND (ir_masters_rec.license_code IS NOT NULL))
      OR (NVL(ir_masters_rec.license_code,' ') <> NVL(lr_check_rec.license_code,' '))) THEN
      -- 参照コードマスタ 情報取得処理
      check_fnd_lookup(
         cv_flv_license
        ,ir_masters_rec.license_code
        ,lv_license_nm
        ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,lv_retcode  -- リターン・コード             --# 固定 #
        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_normal) THEN
        ir_masters_rec.resp_kbn := gv_sts_yes;  -- 職責・管理者変更あり
      ELSIF (lv_retcode = cv_status_warn) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- 職位コード(新)
    IF (((ir_masters_rec.emp_kbn = gv_kbn_new) AND (ir_masters_rec.job_post IS NOT NULL))
      OR (NVL(ir_masters_rec.job_post,' ') <> NVL(lr_check_rec.job_post,' '))) THEN
      -- 参照コードマスタ 情報取得処理
      check_fnd_lookup(
         cv_flv_job_post
        ,ir_masters_rec.job_post
        ,lv_job_post_nm
        ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,lv_retcode  -- リターン・コード             --# 固定 #
        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_normal) THEN
        ir_masters_rec.resp_kbn := gv_sts_yes;  -- 職責・管理者変更あり
      ELSIF (lv_retcode = cv_status_warn) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- 職務コード(新)
    IF (((ir_masters_rec.emp_kbn = gv_kbn_new) AND (ir_masters_rec.job_duty IS NOT NULL))
      OR (NVL(ir_masters_rec.job_duty,' ') <> NVL(lr_check_rec.job_duty,' '))) THEN
      -- 参照コードマスタ 情報取得処理
      check_fnd_lookup(
         cv_flv_job_duty
        ,ir_masters_rec.job_duty
        ,lv_job_duty_nm
        ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,lv_retcode  -- リターン・コード             --# 固定 #
        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_normal) THEN
        ir_masters_rec.resp_kbn := gv_sts_yes;  -- 職責・管理者変更あり
      ELSIF (lv_retcode = cv_status_warn) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- 職種コード(新)
    IF (((ir_masters_rec.emp_kbn = gv_kbn_new) AND (ir_masters_rec.job_type IS NOT NULL))
      OR (NVL(ir_masters_rec.job_type,' ') <> NVL(lr_check_rec.job_type,' '))) THEN
      -- 参照コードマスタ 情報取得処理
      check_fnd_lookup(
         cv_flv_job_type
        ,ir_masters_rec.job_type
        ,lv_job_type_nm
        ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,lv_retcode  -- リターン・コード             --# 固定 #
        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_normal) THEN
        ir_masters_rec.resp_kbn := gv_sts_yes;  -- 職責・管理者変更あり
      ELSIF (lv_retcode = cv_status_warn) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- 職位並順コード(新)
    IF (((ir_masters_rec.emp_kbn = gv_kbn_new) AND (ir_masters_rec.job_post_order IS NOT NULL))
      OR (NVL(ir_masters_rec.job_post_order,' ') <> NVL(lr_check_rec.job_post_order,' '))) THEN
      -- 数値(0～99)以外はエラー
      IF (ir_masters_rec.job_post_order >= ' 0')
        AND (ir_masters_rec.job_post_order <= '99') THEN
        ir_masters_rec.resp_kbn := gv_sts_yes;  -- 職責・管理者変更あり
      ELSE
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_data_check_err
                    ,iv_token_name1  => cv_tkn_ng_user
                    ,iv_token_value1 => ir_masters_rec.employee_number
                    ,iv_token_name2  => cv_tkn_ng_err
                    ,iv_token_value2 => lv_post_order_nm
                   );
        RAISE global_process_expt;
      END IF;
    END IF;
--
--★★★参照コードマスタに設定する項目になった場合、ここから↓↓↓↓↓↓↓↓★★★
/*
    -- 適用労働時間制コード(新)
    IF (((ir_masters_rec.emp_kbn = gv_kbn_new) AND (ir_masters_rec.job_system IS NOT NULL))
      OR (NVL(ir_masters_rec.job_system,' ') <> NVL(lr_check_rec.job_system,' '))) THEN
      -- 参照コードマスタ 情報取得処理
      check_fnd_lookup(
         cv_flv_job_system
        ,ir_masters_rec.job_system
        ,lv_job_system_nm
        ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,lv_retcode  -- リターン・コード             --# 固定 #
        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_normal) THEN
        NULL;
      ELSIF (lv_retcode = cv_status_warn) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- 承認区分(新)
    IF (((ir_masters_rec.emp_kbn = gv_kbn_new) AND (ir_masters_rec.consent_division IS NOT NULL))
      OR (NVL(ir_masters_rec.consent_division,' ') <> NVL(lr_check_rec.consent_division,' '))) THEN
      -- 参照コードマスタ 情報取得処理
      check_fnd_lookup(
         cv_flv_agent
        ,ir_masters_rec.consent_division
        ,lv_consent_nm
        ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,lv_retcode  -- リターン・コード             --# 固定 #
        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_normal) THEN
        NULL;
      ELSIF (lv_retcode = cv_status_warn) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- 代行区分(新)
    IF (((ir_masters_rec.emp_kbn = gv_kbn_new) AND (ir_masters_rec.agent_division IS NOT NULL))
      OR (NVL(ir_masters_rec.agent_division,' ') <> NVL(lr_check_rec.agent_division,' '))) THEN
      -- 参照コードマスタ 情報取得処理
      check_fnd_lookup(
         cv_flv_job_type
        ,ir_masters_rec.agent_division
        ,lv_agent_nm
        ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,lv_retcode  -- リターン・コード             --# 固定 #
        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_normal) THEN
        NULL;
      ELSIF (lv_retcode = cv_status_warn) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
*/
--★★★↑↑↑↑↑↑↑↑↑↑↑↑↑ここまで削除↑↑↑↑↑↑↑★★★
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** 任意で例外処理を記述する ****
    WHEN global_process_expt THEN                           --*** 警告(更新不可データ) ***--
      ov_errmsg  := lv_errmsg;                                                 --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;                                            --# 任意 # 警告
--
--#################################  固定例外処理部 START   #######################################
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
--#####################################  固定部 END   #############################################
--
  END check_code;
--
  /***********************************************************************************
   * Procedure Name   : get_fnd_responsibility(A-7)
   * Description      : 職責・管理者情報の取得を行います。
   ***********************************************************************************/
  PROCEDURE get_fnd_responsibility(
    ir_masters_rec IN OUT masters_rec,  -- 1.チェック対象データ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_fnd_responsibility'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_level1  CONSTANT VARCHAR2(2):= 'L1';  -- レベル１
    cv_level2  CONSTANT VARCHAR2(2):= 'L2';  -- レベル２
    cv_level3  CONSTANT VARCHAR2(2):= 'L3';  -- レベル３
    cv_level4  CONSTANT VARCHAR2(2):= 'L4';  -- レベル４
    cv_level5  CONSTANT VARCHAR2(2):= 'L5';  -- レベル５
    cv_level6  CONSTANT VARCHAR2(2):= 'L6';  -- レベル６
    cv_all     CONSTANT VARCHAR2(1):= '-';   -- 全コート対象
--
    -- *** ローカル変数 ***
    lv_location_cd  VARCHAR2(60);  -- 最下層部門コード
    lv_location_cd1 VARCHAR2(60);  -- １階層目部門コード
    lv_location_cd2 VARCHAR2(60);  -- ２階層目部門コード
    lv_location_cd3 VARCHAR2(60);  -- ３階層目部門コード
    lv_location_cd4 VARCHAR2(60);  -- ４階層目部門コード
    lv_location_cd5 VARCHAR2(60);  -- ５階層目部門コード
    lv_location_cd6 VARCHAR2(60);  -- ６階層目部門コード
    ln_resp_cnt     NUMBER := 0;
    ln_person_cnt   NUMBER := 0;
    ln_post_order   NUMBER := NULL;
    ln_application_id           fnd_responsibility.application_id%TYPE;     -- アプリケーションID
    lv_responsibility_key       fnd_responsibility.responsibility_key%TYPE; -- 職責キー
    lv_application_short_name   fnd_application.application_short_name%TYPE;-- アプリケーション名
    ld_st_date      DATE;
--
    -- *** ローカル・カーソル ***
    -- 職責自動割当カーソル
    CURSOR resp_cur
    IS
      SELECT flv.description        responsibility_id,  -- 職責ID
             flv.attribute1         location_level,     -- 階層レベル
             flv.attribute2         location            -- 拠点コード
      FROM   fnd_lookup_values_vl flv   -- 参照コードマスタ
      WHERE  flv.lookup_type = cv_flv_responsibility  -- 職責自動割当テーブル
      AND    flv.enabled_flag = gv_const_y
      AND    NVL(flv.start_date_active,ld_st_date) <= ld_st_date
      AND    NVL(flv.end_date_active,ld_st_date) >= ld_st_date
      AND   ((NVL(flv.attribute3,cv_all) = cv_all) OR
             (NVL(flv.attribute3,cv_all) = ir_masters_rec.license_code)) -- 資格コード
      AND   ((NVL(flv.attribute4,cv_all) = cv_all) OR
             (NVL(flv.attribute4,cv_all) = ir_masters_rec.job_post))     -- 職位コード
      AND   ((NVL(flv.attribute5,cv_all) = cv_all) OR
             (NVL(flv.attribute5,cv_all) = ir_masters_rec.job_duty))     -- 職務コード
      AND   ((NVL(flv.attribute6,cv_all) = cv_all)  OR
             (NVL(flv.attribute6,cv_all) = ir_masters_rec.job_type))     -- 職種コード
      ORDER BY flv.attribute1,flv.attribute2;
--
    -- 管理者割当カーソル
    CURSOR person_cur
    IS
      SELECT paa.person_id                  person_id,
             TO_NUMBER(paa.ass_attribute11) post_order
      FROM   per_periods_of_service ppos,               -- 従業員サービス期間マスタ
             per_all_assignments_f paa                  -- アサインメントマスタ
      WHERE  paa.ass_attribute3 = ir_masters_rec.office_location_code   -- 勤務地拠点コード(新)
      AND    TO_NUMBER(NVL(paa.ass_attribute11,'99')) > 0               -- 職位並順コード（新)
      AND    TO_NUMBER(NVL(paa.ass_attribute11,'99')) <= TO_NUMBER(ir_masters_rec.job_post_order)
      AND    paa.period_of_service_id = ppos.period_of_service_id       -- サービスID
      AND    ppos.date_start <= ir_masters_rec.hire_date -- 入社日
      AND    NVL(ppos.actual_termination_date ,ir_masters_rec.hire_date) >= ir_masters_rec.hire_date -- 退職日
      ORDER BY post_order;
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

-- 職責の取得
-- 職責の取得時に使用する日付
    --新規社員・再雇用時は入社日にて職責検索／既存社員で
    IF (ir_masters_rec.ymd_kbn  = gv_sts_yes)       -- 入社日変更
    OR (ir_masters_rec.emp_kbn  = gv_kbn_new) THEN  -- 新規社員
      ld_st_date := ir_masters_rec.hire_date;
    ELSIF (ir_masters_rec.actual_termination_date IS NULL)
       OR (TO_DATE(ir_masters_rec.announce_date,'YYYYMMDD') < ir_masters_rec.actual_termination_date) THEN
      ld_st_date := TO_DATE(ir_masters_rec.announce_date,'YYYYMMDD');
    ELSE
      ld_st_date := ir_masters_rec.actual_termination_date;
    END IF;

    BEGIN
    -- AFF部門（部門階層ビュー）
      SELECT xhd.cur_dpt_cd,        -- 最下層部門コード
             xhd.dpt1_cd,           -- １階層目部門コード
             xhd.dpt2_cd,           -- ２階層目部門コード
             xhd.dpt3_cd,           -- ３階層目部門コード
             xhd.dpt4_cd,           -- ４階層目部門コード
             xhd.dpt5_cd,           -- ５階層目部門コード
             xhd.dpt6_cd            -- ６階層目部門コード
      INTO   lv_location_cd,
             lv_location_cd1,
             lv_location_cd2,
             lv_location_cd3,
             lv_location_cd4,
             lv_location_cd5,
             lv_location_cd6
      FROM   xxcmm_hierarchy_dept_v xhd
      WHERE  xhd.cur_dpt_cd = ir_masters_rec.location_code   -- 最下層部門コードが同じ
      AND    ROWNUM = 1;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    <<resp_loop>>
    FOR resp_rec IN resp_cur LOOP
      IF (resp_rec.location_level = cv_level1 AND resp_rec.location = lv_location_cd1)
        OR (resp_rec.location_level = cv_level2 AND resp_rec.location = lv_location_cd2)
        OR (resp_rec.location_level = cv_level3 AND resp_rec.location = lv_location_cd3)
        OR (resp_rec.location_level = cv_level4 AND resp_rec.location = lv_location_cd4)
        OR (resp_rec.location_level = cv_level5 AND resp_rec.location = lv_location_cd5)
        OR (resp_rec.location_level = cv_level6 AND resp_rec.location = lv_location_cd6) THEN

        BEGIN
          -- 職責マスタ存在チェック
          SELECT fres.application_id,
                  fres.responsibility_key,
                  fapp.application_short_name
          INTO   ln_application_id,
                  lv_responsibility_key,
                  lv_application_short_name
          FROM   fnd_application    fapp,
                  fnd_responsibility fres                    -- 職責マスタ
          WHERE  fres.responsibility_id  = TO_NUMBER(resp_rec.responsibility_id)
          AND    NVL(fres.start_date,ld_st_date)  <= ld_st_date
          AND    NVL(fres.end_date,ld_st_date)  >= ld_st_date
          AND    fapp.application_id = fres.application_id
          AND    ROWNUM = 1;

        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            ln_application_id := NULL;
            lv_responsibility_key := NULL;
            lv_application_short_name := NULL;
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;

        IF ln_application_id IS NOT NULL THEN
          BEGIN
            -- 職責自動割当ワークへ待避
            INSERT INTO xxcmm_wk_people_resp(
                employee_number,
                responsibility_id,
                user_id,
                employee_kbn,
                responsibility_key,
                application_id,
                application_short_name,
                start_date,
                end_date
            )VALUES(
                ir_masters_rec.employee_number,
                TO_NUMBER(resp_rec.responsibility_id),
                ir_masters_rec.user_id,
                ir_masters_rec.emp_kbn,
                lv_responsibility_key,
                ln_application_id,
                lv_application_short_name,
                ld_st_date,
                ir_masters_rec.actual_termination_date
            );
        ln_resp_cnt := ln_resp_cnt + 1;
          EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN  -- 同じ社員番号に同じ職責が存在した場合は、skipする
              ln_application_id := NULL;
              lv_responsibility_key := NULL;
              lv_application_short_name := NULL;
            WHEN OTHERS THEN
              RAISE global_api_others_expt;
          END;
        END IF;
      END IF;
    END LOOP resp_loop;

    IF (ln_resp_cnt = 0) THEN
/*  --職責が割当られなかった時の警告エラーはなし（コメントにしておく）
        -- 自動職責割当て不可メッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_appl_short_name
                  ,iv_name         => cv_out_resp_msg
                  ,iv_token_name1  => cv_tkn_ng_word
                  ,iv_token_value1 => cv_employee_nm    -- '社員番号'
                  ,iv_token_name2  => cv_tkn_ng_user
                  ,iv_token_value2 => ir_masters_rec.employee_number
                 );
      ir_status_rec.row_err_message   := iv_message;
      ir_status_rec.row_level_status  := cv_status_normal;  --処理継続
*/
      ir_masters_rec.resp_kbn := gv_sts_no;  -- 職責自動連携不可
    END IF;
--
-- 管理者情報の取得
    IF (ir_masters_rec.hire_date >= gn_person_start) THEN
      ir_masters_rec.supervisor_id := gn_person_id; --プロファイルの設定された社員のperson_idを初期設定
    END IF;
    <<person_loop>>
    FOR person_rec IN person_cur  LOOP
      ln_person_cnt := ln_person_cnt + 1;
      -- 管理者に並順が1番の社員を設定
      IF (ln_person_cnt = 1) THEN
        -- 並順1番のperson_idが本人以外の場合、person_idを設定
        IF (person_rec.person_id <> ir_masters_rec.person_id)
          OR (ir_masters_rec.person_id IS NULL ) THEN         -- 新規社員
          ir_masters_rec.supervisor_id := person_rec.person_id;
          EXIT person_loop;
        END IF;
      ELSE  --2件目でEXITする
        -- 並順1番が複数いる場合、本人以外を設定
        IF (person_rec.post_order = ln_post_order)
          AND (person_rec.person_id <> ir_masters_rec.person_id) THEN
            ir_masters_rec.supervisor_id := person_rec.person_id;
        END IF;
        EXIT person_loop;
      END IF;
      ln_post_order := person_rec.post_order;

    END LOOP person_loop;

    -- 管理者が本人だった場合はNULLを設定
    IF (ir_masters_rec.supervisor_id = ir_masters_rec.person_id) THEN
      ir_masters_rec.supervisor_id := NULL;
    END IF;
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
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
--#####################################  固定部 END   #############################################
--
  END get_fnd_responsibility;
--
  /***********************************************************************************
   * Procedure Name   : check_insert
   * Description      : 社員データ登録分チェック処理(A-5)
   ***********************************************************************************/
  PROCEDURE check_insert(
    ir_masters_rec IN OUT masters_rec,  -- 1.チェック対象データ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_insert'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
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
    -- ユーザマスタ存在チェック
    check_fnd_user(
       ir_masters_rec
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- ユーザ取得エラー
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    -- ユーザ登録済エラー
    ELSIF (ir_masters_rec.user_id IS NOT NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_appl_short_name
                  ,iv_name         => cv_dup_val_err
                  ,iv_token_name1  => cv_tkn_ng_word
                  ,iv_token_value1 => cv_employee_nm    -- '社員番号'
                  ,iv_token_name2  => cv_tkn_ng_data
                  ,iv_token_value2 => ir_masters_rec.employee_number
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;

    -- コードチェック処理(資格・職位・職務・職種・適用労働時間制・承認区分・代行区分)
    check_code(
       ir_masters_rec
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_normal) THEN     -- 正常
      NULL;
    ELSIF (lv_retcode = cv_status_warn) THEN    -- コード未登録エラー
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_error) THEN   -- その他のエラー
      RAISE global_api_expt;
    END IF;
--
    -- =================================
    -- 職責・管理者情報の取得処理(A-7)
    -- =================================
    get_fnd_responsibility(
       ir_masters_rec
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN  -- SQLエラーのみ
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** 任意で例外処理を記述する ****
    WHEN global_process_expt THEN                           --*** 警告(更新不可データ) ***--
      ov_errmsg  := lv_errmsg;                                                 --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;                                            --# 任意 # 警告
--
--#################################  固定例外処理部 START   #######################################
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
--#####################################  固定部 END   #############################################
--
  END check_insert;
--
  /***********************************************************************************
   * Procedure Name   : check_update
   * Description      : 更新用データのチェック処理を行います。(A-6)
   ***********************************************************************************/
  PROCEDURE check_update(
    ir_masters_rec IN OUT masters_rec,  -- 1.チェック対象データ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_update'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
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
    -- ユーザマスタ存在チェック
    check_fnd_user(
       ir_masters_rec
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );

    -- ユーザ取得エラー
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    -- ユーザ未登録エラー
    ELSIF (ir_masters_rec.user_id IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_appl_short_name
                  ,iv_name         => cv_not_found_err
                  ,iv_token_name1  => cv_tkn_ng_word
                  ,iv_token_value1 => cv_employee_nm    -- '社員番号'
                  ,iv_token_name2  => cv_tkn_ng_data
                  ,iv_token_value2 => ir_masters_rec.employee_number
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;

    -- 社員インタフェース.入社日＜アサインメントマスタ.登録年月日
    IF (ir_masters_rec.hire_date < lr_check_rec.paa_effective_start_date) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_appl_short_name
                  ,iv_name         => cv_st_ymd_err1
                  ,iv_token_name1  => cv_tkn_ng_word
                  ,iv_token_value1 => cv_employee_nm    -- '社員番号'
                  ,iv_token_name2  => cv_tkn_ng_user
                  ,iv_token_value2 => ir_masters_rec.employee_number
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 社員インタフェース.退職年月日＜アサインメントマスタ.登録年月日の場合、エラー
    IF (ir_masters_rec.actual_termination_date < lr_check_rec.paa_effective_start_date) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_appl_short_name
                  ,iv_name         => cv_st_ymd_err2
                  ,iv_token_name1  => cv_tkn_ng_word
                  ,iv_token_value1 => cv_employee_nm    -- '社員番号'
                  ,iv_token_name2  => cv_tkn_ng_user
                  ,iv_token_value2 => ir_masters_rec.employee_number
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 退職者の場合
    IF (ir_masters_rec.emp_kbn = gv_kbn_retiree) THEN
      -- 連携区分が’Y’(入社年月日・退職年月日以外にデータ差異がある)の場合、
      IF (ir_masters_rec.proc_kbn = gv_sts_yes) THEN
        --社員インタフェース.入社日に差異がない場合エラー（退職者の情報変更はエラー）
        IF (ir_masters_rec.hire_date = lr_check_rec.paa_effective_start_date) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_retiree_err1
                      ,iv_token_name1  => cv_tkn_ng_word
                      ,iv_token_value1 => cv_employee_nm    -- '社員番号'
                      ,iv_token_name2  => cv_tkn_ng_user
                      ,iv_token_value2 => ir_masters_rec.employee_number
                      );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
        ELSE
          -- 社員インタフェース.入社日＞サービス期間マスタ.退職日の場合、再雇用データ
          -- 再雇用の場合は、職責・管理者変更処理を行う（新規社員に同様）
          IF (ir_masters_rec.hire_date > lr_check_rec.actual_termination_date) THEN
            ir_masters_rec.ymd_kbn := gv_sts_yes;   -- 入社日連携区分('Y':日付変更データ)
            ir_masters_rec.resp_kbn := gv_sts_yes;   -- 職責・管理者変更区分('Y':日付変更データ)
          ELSE
          -- 社員インタフェース.入社日≦サービス期間マスタ.退職日の場合、エラーとします。
            lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                        ,iv_name         => cv_retiree_err2
                        ,iv_token_name1  => cv_tkn_ng_word
                        ,iv_token_value1 => cv_employee_nm  -- '社員番号'
                        ,iv_token_name2  => cv_tkn_ng_user
                        ,iv_token_value2 => ir_masters_rec.employee_number
                        );
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
          END IF;
        END IF;
      END IF;
    END IF;

    -- 資格・職位・職務・職種・適用労働時間制・職位並順・承認区分・代行区分に差分がある場合、コードチェックを行う
    IF ((ir_masters_rec.license_code||ir_masters_rec.job_post||ir_masters_rec.job_duty||ir_masters_rec.job_type
      ||ir_masters_rec.job_system||ir_masters_rec.job_post_order
      ||ir_masters_rec.consent_division||ir_masters_rec.agent_division)
      <> (lr_check_rec.license_code||lr_check_rec.job_post||lr_check_rec.job_duty||lr_check_rec.job_type
      ||lr_check_rec.job_system||lr_check_rec.job_post_order
      ||lr_check_rec.consent_division||lr_check_rec.agent_division)) THEN
      -- コードチェック処理(資格・職位・職務・職種・適用労働時間制・職位並順・承認区分・代行区分)
      check_code(
         ir_masters_rec
        ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,lv_retcode  -- リターン・コード             --# 固定 #
        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_normal) THEN     -- 正常
        NULL;
      ELSIF (lv_retcode = cv_status_warn) THEN    -- コード未登録エラー
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_error) THEN   -- その他のエラー
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- =================================
    -- 職責・管理者情報の取得処理(A-7)
    -- =================================
    IF (ir_masters_rec.resp_kbn = gv_sts_yes) THEN  -- 職責・管理者変更あり
      get_fnd_responsibility(
         ir_masters_rec
        ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,lv_retcode  -- リターン・コード             --# 固定 #
        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_error) THEN  -- SQLエラーのみ
        RAISE global_process_expt;
      END IF;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
    -- *** 任意で例外処理を記述する ****
    WHEN global_process_expt THEN                           --*** 警告(更新不可データ) ***--
      ir_masters_rec.proc_flg := gv_sts_error;  -- 更新不可能
      ir_masters_rec.row_err_message := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                 --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;                                            --# 任意 # 警告
--
--#################################  固定例外処理部 START   #######################################
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
--#####################################  固定部 END   #############################################
--
  END check_update;
--
  /***********************************************************************************
   * Procedure Name   : add_report
   * Description      : 社員データのログ出力情報を格納します。(A-11)
   ***********************************************************************************/
  PROCEDURE add_report(
    ir_masters_rec IN OUT masters_rec,  -- 1.チェック対象データ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'add_report'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lr_report_rec report_rec;
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
    -- レポートレコードに値を設定
    lr_report_rec.employee_number          := ir_masters_rec.employee_number;    --社員番号
    lr_report_rec.hire_date                := ir_masters_rec.hire_date;          --入社年月日
    lr_report_rec.actual_termination_date  := ir_masters_rec.actual_termination_date;--退職年月日
    lr_report_rec.last_name_kanji          := ir_masters_rec.last_name_kanji;    --漢字姓
    lr_report_rec.first_name_kanji         := ir_masters_rec.first_name_kanji;   --漢字名
    lr_report_rec.last_name                := ir_masters_rec.last_name;          --カナ姓
    lr_report_rec.first_name               := ir_masters_rec.first_name;         --カナ名
    lr_report_rec.sex                      := ir_masters_rec.sex;               --性別
    lr_report_rec.employee_division        := ir_masters_rec.employee_division;  --社員・外部委託区分
    lr_report_rec.location_code            := ir_masters_rec.location_code;      --所属コード（新）
    lr_report_rec.change_code              := ir_masters_rec.change_code;        --異動事由コード
    lr_report_rec.announce_date            := ir_masters_rec.announce_date;      --発令日
    lr_report_rec.office_location_code     := ir_masters_rec.office_location_code; --勤務地拠点コード（新）
    lr_report_rec.license_code             := ir_masters_rec.license_code;       --資格コード（新）
    lr_report_rec.license_name             := ir_masters_rec.license_name;       --資格名（新）
    lr_report_rec.job_post                 := ir_masters_rec.job_post;           --職位コード（新）
    lr_report_rec.job_post_name            := ir_masters_rec.job_post_name;      --職位名（新）
    lr_report_rec.job_duty                 := ir_masters_rec.job_duty;           --職務コード（新）
    lr_report_rec.job_duty_name            := ir_masters_rec.job_duty_name;      --職務名（新）
    lr_report_rec.job_type                 := ir_masters_rec.job_type;           --職種コード（新）
    lr_report_rec.job_type_name            := ir_masters_rec.job_type_name;      --職種名（新）
    lr_report_rec.job_system               := ir_masters_rec.job_system;         --適用労働時間制コード（新）
    lr_report_rec.job_system_name          := ir_masters_rec.job_system_name;    --適用労働名（新）
    lr_report_rec.job_post_order           := ir_masters_rec.job_post_order;     --職位並順コード（新）
    lr_report_rec.consent_division         := ir_masters_rec.consent_division;   --承認区分（新）
    lr_report_rec.agent_division           := ir_masters_rec.agent_division;     --代行区分（新）
    lr_report_rec.office_location_code_old := ir_masters_rec.office_location_code_old; --勤務地拠点コード（旧）
    lr_report_rec.location_code_old        := ir_masters_rec.location_code_old;  --所属コード（旧）
    lr_report_rec.license_code_old         := ir_masters_rec.license_code_old;   --資格コード（旧）
    lr_report_rec.license_code_name_old    := ir_masters_rec.license_code_name_old;--資格名（旧）
    lr_report_rec.job_post_old             := ir_masters_rec.job_post_old;       --職位コード（旧）
    lr_report_rec.job_post_name_old        := ir_masters_rec.job_post_name_old;  --職位名（旧）
    lr_report_rec.job_duty_old             := ir_masters_rec.job_duty_old;       --職務コード（旧）
    lr_report_rec.job_duty_name_old        := ir_masters_rec.job_duty_name_old;  --職務名（旧）
    lr_report_rec.job_type_old             := ir_masters_rec.job_type_old;       --職種コード（旧）
    lr_report_rec.job_type_name_old        := ir_masters_rec.job_type_name_old;  --職種名（旧）
    lr_report_rec.job_system_old           := ir_masters_rec.job_system_old;     --適用労働時間制コード（旧）
    lr_report_rec.job_system_name_old      := ir_masters_rec.job_system_name_old;--適用労働名（旧）
    lr_report_rec.job_post_order_old       := ir_masters_rec.job_post_order_old; --職位並順コード（旧）
    lr_report_rec.consent_division_old     := ir_masters_rec.consent_division_old; --承認区分（旧）
    lr_report_rec.agent_division_old       := ir_masters_rec.agent_division_old; --代行区分（旧）

    lr_report_rec.message                  := ir_masters_rec.row_err_message;
--
    -- レポートテーブルに追加
    IF  ir_masters_rec.proc_flg = gv_sts_update THEN
      gt_report_normal_tbl(gn_normal_cnt) := lr_report_rec;
    ELSIF  ir_masters_rec.proc_flg = gv_sts_error THEN
      gt_report_warn_tbl(gn_warn_cnt) := lr_report_rec;
    END IF;

--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
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
--#####################################  固定部 END   #############################################
--
  END add_report;
--
  /***********************************************************************************
   * Procedure Name   : disp_report
   * Description      : レポート用データを出力します。(C-11)
   ***********************************************************************************/
  PROCEDURE disp_report(
    iv_disp_kbn    IN VARCHAR2,     -- 1.表示対象区分(cv_status_normal:正常,cv_status_warn:警告)
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'disp_report'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_normal     CONSTANT VARCHAR2(20) := '<<正常データ>>';  -- 見出し
    cv_warning    CONSTANT VARCHAR2(20) := '<<警告データ>>';  -- 見出し
    cv_errmsg     CONSTANT VARCHAR2(20) := ' [エラーメッセージ]';  -- エラーメッセージ
    lv_sep_com    CONSTANT VARCHAR2(1)  := ',';     -- カンマ
--
    -- *** ローカル変数 ***
    lv_dspbuf     VARCHAR2(5000);  -- エラー・メッセージ
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
    -- ログ見出し
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appl_short_name
                 ,iv_name         => cv_rep_msg
                );

    IF (iv_disp_kbn = cv_status_warn) THEN
      -- ログ見出し
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
         ,buff => cv_warning --見出し１
      );
     FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff => gv_out_msg --見出し２
      );
      <<report_w_loop>>
      FOR ln_disp_cnt IN 1..gn_warn_cnt LOOP
        lv_dspbuf := gt_report_warn_tbl(ln_disp_cnt).employee_number||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).hire_date||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).actual_termination_date||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).last_name_kanji||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).first_name_kanji||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).last_name||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).first_name||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).sex||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).employee_division||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).location_code||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).change_code||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).announce_date||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).office_location_code||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).license_code||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).license_name||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_post||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_post_name||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_duty||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_duty_name||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_type||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_type_name||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_system||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_system_name ||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_post_order||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).consent_division||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).agent_division||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).office_location_code_old||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).location_code_old||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).license_code_old||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).license_code_name_old||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_post_old||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_post_name_old||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_duty_old||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_duty_name_old ||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_type_old||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_type_name_old||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_system_old||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_system_name_old||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_post_order_old||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).consent_division_old||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).agent_division_old||
                    cv_errmsg||gt_report_warn_tbl(ln_disp_cnt).message
                    ;
        -- ログ出力
        FND_FILE.PUT_LINE(
            which  => FND_FILE.LOG
           ,buff => lv_dspbuf --警告データログ
        );
        -- 出力メッセージ
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gt_report_warn_tbl(ln_disp_cnt).message
        );
      END LOOP report_w_loop;
      -- 空白行
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
    END IF;

    IF (iv_disp_kbn = cv_status_normal) THEN
      -- ログ見出し
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
         ,buff => cv_normal --見出し１
      );
     FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff => gv_out_msg --見出し２
      );
      <<report_n_loop>>
      FOR ln_disp_cnt IN 1..gn_normal_cnt LOOP
        lv_dspbuf := gt_report_normal_tbl(ln_disp_cnt).employee_number||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).hire_date||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).actual_termination_date||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).last_name_kanji||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).first_name_kanji||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).last_name||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).first_name||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).sex||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).employee_division||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).location_code||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).change_code||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).announce_date||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).office_location_code||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).license_code||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).license_name||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_post||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_post_name||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_duty||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_duty_name||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_type||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_type_name||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_system||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_system_name ||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_post_order||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).consent_division||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).agent_division||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).office_location_code_old||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).location_code_old||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).license_code_old||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).license_code_name_old||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_post_old||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_post_name_old||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_duty_old||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_duty_name_old ||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_type_old||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_type_name_old||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_system_old||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_system_name_old||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_post_order_old||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).consent_division_old||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).agent_division_old
                    ;
        FND_FILE.PUT_LINE(
            which  => FND_FILE.LOG
           ,buff => lv_dspbuf --正常データログ
        );
      END LOOP report_n_loop;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
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
--#####################################  固定部 END   #############################################
--
  END disp_report;
--
  /***********************************************************************************
   * Procedure Name   : update_resp_all
   * Description      : ユーザ職責マスタの更新処理を行います。
   ***********************************************************************************/
  PROCEDURE update_resp_all(
    ir_masters_rec IN OUT masters_rec,  -- 1.チェック対象データ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_resp_all'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_retcd                 NUMBER;
    lb_retst                 BOOLEAN;
    ln_responsibility_id     fnd_user_resp_groups_all.responsibility_id%TYPE;
    ln_responsibility_app_id fnd_user_resp_groups_all.responsibility_application_id%TYPE;
    ln_security_group_id     fnd_user_resp_groups_all.security_group_id%TYPE;
    ld_start_date            fnd_user_resp_groups_all.start_date%TYPE;
    ld_start_date_u          fnd_user_resp_groups_all.start_date%TYPE;
--
    lv_api_name              VARCHAR2(200);
    lv_update_flg            VARCHAR2(1);
--
    -- *** ローカル・カーソル ***
--
    -- 職責自動割当ワーク
    CURSOR wk_pr1_cur
    IS
      SELECT xwpr.employee_number       employee_number,
             xwpr.responsibility_id     responsibility_id,
             xwpr.user_id               user_id,
             xwpr.responsibility_key    responsibility_key,
             xwpr.application_short_name    application_short_name,
             xwpr.start_date            start_date,
             xwpr.end_date              end_date
      FROM   xxcmm_wk_people_resp xwpr
      WHERE  xwpr.employee_number = ir_masters_rec.employee_number
      AND    xwpr.responsibility_id > 0
      ORDER BY xwpr.employee_number,xwpr.responsibility_id;

    -- ユーザー職責マスタ
    CURSOR furg_cur(in_responsibility_id in number)
    IS
      SELECT fug.responsibility_application_id  responsibility_application_id,
             fug.security_group_id              security_group_id
      FROM   fnd_user_resp_groups_all fug                  -- ユーザー職責マスタ
      WHERE  fug.user_id           = ir_masters_rec.user_id
      AND    fug.responsibility_id = in_responsibility_id
      AND    ROWNUM = 1;

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

    <<wk_pr1_loop>>
    FOR wk_pr1_rec IN wk_pr1_cur LOOP
      lv_update_flg := NULL;
      <<furg_rec_loop>>
      FOR furg_rec IN furg_cur(wk_pr1_rec.responsibility_id) LOOP
        EXIT WHEN furg_cur%NOTFOUND;

        BEGIN
          FND_USER_RESP_GROUPS_API.UPDATE_ASSIGNMENT(
             USER_ID                       => wk_pr1_rec.user_id
            ,RESPONSIBILITY_ID             => wk_pr1_rec.responsibility_id
            ,RESPONSIBILITY_APPLICATION_ID => furg_rec.responsibility_application_id
            ,SECURITY_GROUP_ID             => furg_rec.security_group_id
            ,START_DATE                    => wk_pr1_rec.start_date
            ,END_DATE                      => wk_pr1_rec.end_date
            ,DESCRIPTION                   => gv_const_y
          );
          lv_update_flg := gv_flg_on;
        EXCEPTION
          WHEN OTHERS THEN
            lv_api_name := 'FND_USER_RESP_GROUPS_API.UPDATE_ASSIGNMENT';
            lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                        ,iv_name         => cv_api_err
                        ,iv_token_name1  => cv_tkn_apiname
                        ,iv_token_value1 => lv_api_name
                        ,iv_token_name2  => cv_tkn_ng_word
                        ,iv_token_value2 => cv_employee_nm    -- '社員番号'
                        ,iv_token_name3  => cv_tkn_ng_data
                        ,iv_token_value3 => ir_masters_rec.employee_number
                        );
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
        END;
      END LOOP furg_rec_loop;

      IF lv_update_flg IS NULL THEN
         -- 新規社員職責登録
      -- ユーザ職責マスタ
        BEGIN
          FND_USER_RESP_GROUPS_API.LOAD_ROW(
            X_USER_NAME         => wk_pr1_rec.employee_number
           ,X_RESP_KEY          => wk_pr1_rec.responsibility_key
           ,X_APP_SHORT_NAME    => wk_pr1_rec.application_short_name
           ,X_SECURITY_GROUP    => 'STANDARD'
           ,X_OWNER             => gn_created_by
           ,X_START_DATE        => TO_CHAR(wk_pr1_rec.start_date,'YYYY/MM/DD')
           ,X_END_DATE          => TO_CHAR(wk_pr1_rec.end_date,'YYYY/MM/DD')
           ,X_DESCRIPTION       => NULL
           ,X_LAST_UPDATE_DATE  => SYSDATE
          );
        EXCEPTION
          WHEN OTHERS THEN
            lv_api_name := 'FND_USER_RESP_GROUPS_API.LOAD_ROW';
            lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                        ,iv_name         => cv_api_err
                        ,iv_token_name1  => cv_tkn_apiname
                        ,iv_token_value1 => lv_api_name
                        ,iv_token_name2  => cv_tkn_ng_word
                        ,iv_token_value2 => cv_employee_nm    -- '社員番号'
                        ,iv_token_name3  => cv_tkn_ng_data
                        ,iv_token_value3 => wk_pr1_rec.employee_number
                        );
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
        END;
      END IF;
    END LOOP wk_pr1_loop;

    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** API関数エラー時(関数使用直後) ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   #######################################
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
--#####################################  固定部 END   #############################################
--
  END update_resp_all;
--
  /***********************************************************************************
   * Procedure Name   : delete_resp_all
   * Description      : ユーザー職責マスタのデータの無効化を行います。
   ***********************************************************************************/
  PROCEDURE delete_resp_all(
    ir_masters_rec IN OUT masters_rec,  -- 1.チェック対象データ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_resp_all'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_user_id                  fnd_user_resp_groups_all.user_id%TYPE;
    ln_responsibility_id        fnd_user_resp_groups_all.responsibility_id%TYPE;
    ln_responsibility_app_id    fnd_user_resp_groups_all.responsibility_application_id%TYPE;
    ln_security_group_id        fnd_user_resp_groups_all.security_group_id%TYPE;
    ld_start_date               fnd_user_resp_groups_all.start_date%TYPE;
--
    lv_api_name                 VARCHAR2(200); -- エラートークン用
--
    -- *** ローカル・カーソル ***
    CURSOR fug_cur
    IS
      SELECT fug.user_id            user_id,
             fug.responsibility_id  responsibility_id,
             fug.responsibility_application_id  responsibility_application_id,
             fug.security_group_id  security_group_id,
             fug.start_date         start_date
      FROM   fnd_user_resp_groups_all fug                      -- ユーザー職責マスタ
      WHERE  fug.user_id = ir_masters_rec.user_id;
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
    <<fug_cur_loop>>
    FOR fug_rec IN fug_cur LOOP
--
      BEGIN
        -- API起動
        FND_USER_RESP_GROUPS_API.UPDATE_ASSIGNMENT(
            USER_ID                       => fug_rec.user_id
           ,RESPONSIBILITY_ID             => fug_rec.responsibility_id
           ,RESPONSIBILITY_APPLICATION_ID => fug_rec.responsibility_application_id
           ,SECURITY_GROUP_ID             => fug_rec.security_group_id
           ,START_DATE                    => fug_rec.start_date
           ,END_DATE                      => cd_process_date
           ,DESCRIPTION                   => gv_const_y
        );
--
      EXCEPTION
        WHEN OTHERS THEN
          lv_api_name := 'FND_USER_RESP_GROUPS_API.UPDATE_ASSIGNMENT';
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_api_err
                      ,iv_token_name1  => cv_tkn_apiname
                      ,iv_token_value1 => lv_api_name
                      ,iv_token_name2  => cv_tkn_ng_word
                      ,iv_token_value2 => cv_employee_nm    -- '社員番号'
                      ,iv_token_name3  => cv_tkn_ng_data
                      ,iv_token_value3 => ir_masters_rec.employee_number
                      );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    END LOOP fug_cur_loop;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** API関数エラー時(関数使用直後) ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   #######################################
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
--#####################################  固定部 END   #############################################
--
  END delete_resp_all;
--
  /***********************************************************************************
   * Procedure Name   : insert_resp_all
   * Description      : ユーザ職責マスタへの登録を行います。
   ***********************************************************************************/
  PROCEDURE insert_resp_all(
    iv_emp_number  IN VARCHAR2, -- 1.社員番号
    iv_resp_key    IN VARCHAR2, -- 2.職責キー
    iv_app_name    IN VARCHAR2, -- 3.アプリケーション名
    iv_st_date     IN DATE,     -- 4.有効日(自)
    iv_en_date     IN DATE,     -- 5.有効日(至)
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_resp_all'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_api_name                 VARCHAR2(200); -- エラートークン用
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

      -- ユーザ職責マスタ
      FND_USER_RESP_GROUPS_API.LOAD_ROW(
        X_USER_NAME         => iv_emp_number
       ,X_RESP_KEY          => iv_resp_key
       ,X_APP_SHORT_NAME    => iv_app_name
       ,X_SECURITY_GROUP    => 'STANDARD'
       ,X_OWNER             => gn_created_by
       ,X_START_DATE        => TO_CHAR(iv_st_date,'YYYY/MM/DD')
       ,X_END_DATE          => TO_CHAR(iv_en_date,'YYYY/MM/DD')
       ,X_DESCRIPTION       => NULL
       ,X_LAST_UPDATE_DATE  => SYSDATE
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_api_name := 'FND_USER_RESP_GROUPS_API.LOAD_ROW';
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_api_err
                    ,iv_token_name1  => cv_tkn_apiname
                    ,iv_token_value1 => lv_api_name
                    ,iv_token_name2  => cv_tkn_ng_word
                    ,iv_token_value2 => cv_employee_nm    -- '社員番号'
                    ,iv_token_name3  => cv_tkn_ng_data
                    ,iv_token_value3 => iv_emp_number
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** API関数エラー時(関数使用直後) ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   #######################################
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
--#####################################  固定部 END   #############################################
--
  END insert_resp_all;
--
  /***********************************************************************************
   * Procedure Name   : get_service_id
   * Description      : サービス期間IDの取得を行います。(退職処理前情報の取得)
   ***********************************************************************************/
  PROCEDURE get_service_id(
    ir_masters_rec IN OUT masters_rec,  -- 1.退職対象データ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_service_id'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
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
--  退職処理に使用（退職前の対象従業員のｻｰﾋﾞｽIDを求める）
    SELECT ppos.period_of_service_id,           -- サービスID
           ppos.object_version_number           -- ｻｰﾋﾞｽ期間ﾏｽﾀのﾊﾞｰｼﾞｮﾝ
    INTO   ir_masters_rec.period_of_service_id,
           ir_masters_rec.ppos_version
    FROM   per_periods_of_service ppos,         -- サービス期間マスタ
           per_all_people_f pap                   -- 従業員マスタ
    WHERE  ppos.person_id = ir_masters_rec.person_id
    AND    ppos.actual_termination_date IS NULL
    AND    ROWNUM = 1;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
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
--#####################################  固定部 END   #############################################
--
  END get_service_id;
--
  /***********************************************************************************
   * Procedure Name   : get_person_type
   * Description      : パーソンタイプの取得を行います。
   ***********************************************************************************/
  PROCEDURE get_person_type(
    iv_user_person_type   IN VARCHAR2, -- 1.パーソンタイプ
    ov_person_type_id    OUT VARCHAR2, -- 2.パーソンタイプID
    ov_business_group_id OUT VARCHAR2, -- 3.ビジネスグループID
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_person_type'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
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
    -- ===============================
    -- パーソンタイプの取得
    -- ===============================
    BEGIN
      SELECT ppt.person_type_id,
             ppt.business_group_id
      INTO   ov_person_type_id,
             ov_business_group_id
      FROM   per_person_types ppt     -- パーソンタイプマスタ
      WHERE  ppt.user_person_type = iv_user_person_type
      AND    ROWNUM = 1;
    EXCEPTION
      -- データなしの場合も継続
      WHEN NO_DATA_FOUND THEN
        ov_person_type_id    := NULL;
        ov_business_group_id := NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
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
--#####################################  固定部 END   #############################################
--
  END get_person_type;
--
  /***********************************************************************************
   * Procedure Name   : changes_proc
   * Description      : 異動処理を行うプロシージャ
   ***********************************************************************************/
  PROCEDURE changes_proc(
    ir_masters_rec IN OUT masters_rec,  -- 1.異動対象データ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'changes_proc'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    -- HR_PERSON_API.UPDATE_PERSON
    lv_full_name                per_all_people_f.full_name%TYPE;
    ln_comment_id               per_all_people_f.comment_id%TYPE;
    lb_name_combination_warning BOOLEAN;
    lb_assign_payroll_warning   BOOLEAN;
    lb_orig_hire_warning        BOOLEAN;
--
    -- HR_ASSIGNMENT_API.UPDATE_EMP_ASG
    lv_concatenated_segments    VARCHAR2(200);
    ln_soft_coding_keyflex_id   per_all_assignments_f.soft_coding_keyflex_id%type;
    lb_no_managers_warning      BOOLEAN;
    lb_other_manager_warning    BOOLEAN;

    -- HR_ASSIGNMENT_API.UPDATE_EMP_ASG_CRITERIA
    ln_special_ceiling_step_id      per_all_assignments_f.special_ceiling_step_id%type;
    ln_people_group_id              per_all_assignments_f.people_group_id%type;
    lv_group_name                   VARCHAR2(200);
    lb_org_now_no_manager_warning   BOOLEAN;
    lb_spp_delete_warning           BOOLEAN;
    lv_entries_changes_warn         VARCHAR2(1);
    lb_tax_district_changed_warn    BOOLEAN;

    lv_api_name                   VARCHAR2(200); -- エラートークン用
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

    -- 従業員マスタ(API)
    BEGIN

      HR_PERSON_API.UPDATE_PERSON(
         P_VALIDATE                =>  FALSE
        ,P_EFFECTIVE_DATE          =>  SYSDATE
        ,P_DATETRACK_UPDATE_MODE   =>  gv_upd_mode                      -- 'CORRECTION'
        ,P_PERSON_ID               =>  ir_masters_rec.person_id         -- 従業員ID
        ,P_OBJECT_VERSION_NUMBER   =>  ir_masters_rec.pap_version       -- 従業員ﾏｽﾀﾊﾞｰｼﾞｮﾝ(IN/OUT)
        ,P_PERSON_TYPE_ID          =>  gv_person_type                   -- パーソンタイプ
        ,P_LAST_NAME               =>  ir_masters_rec.last_name         -- カナ姓
        ,P_EMPLOYEE_NUMBER         =>  ir_masters_rec.employee_number   -- 社員番号(IN/OUT)
        ,P_FIRST_NAME              =>  ir_masters_rec.first_name        -- カナ名
        ,P_SEX                     =>  ir_masters_rec.sex               -- 性別
        ,P_ATTRIBUTE3              =>  ir_masters_rec.employee_division -- 従業員区分
        ,P_ATTRIBUTE7              =>  ir_masters_rec.license_code      -- 資格コード（新）
        ,P_ATTRIBUTE8              =>  ir_masters_rec.license_name      -- 資格名（新）
        ,P_ATTRIBUTE9              =>  ir_masters_rec.license_code_old  -- 資格コード（旧）
        ,P_ATTRIBUTE10             =>  ir_masters_rec.license_code_name_old -- 資格名（旧）
        ,P_ATTRIBUTE11             =>  ir_masters_rec.job_post          -- 職位コード（新）
        ,P_ATTRIBUTE12             =>  ir_masters_rec.job_post_name     -- 職位名（新）
        ,P_ATTRIBUTE13             =>  ir_masters_rec.job_post_old      -- 職位コード（旧）
        ,P_ATTRIBUTE14             =>  ir_masters_rec.job_post_name_old -- 職位名（旧）
        ,P_ATTRIBUTE15             =>  ir_masters_rec.job_duty          -- 職務コード（新）
        ,P_ATTRIBUTE16             =>  ir_masters_rec.job_duty_name     -- 職務名（新）
        ,P_ATTRIBUTE17             =>  ir_masters_rec.job_duty_old      -- 職務コード（旧）
        ,P_ATTRIBUTE18             =>  ir_masters_rec.job_duty_name_old -- 職務名（旧）
        ,P_ATTRIBUTE19             =>  ir_masters_rec.job_type          -- 職種コード（新）
        ,P_ATTRIBUTE20             =>  ir_masters_rec.job_type_name     -- 職種名（新）
        ,P_ATTRIBUTE21             =>  ir_masters_rec.job_type_old      -- 職種コード（旧）
        ,P_ATTRIBUTE22             =>  ir_masters_rec.job_type_name_old -- 職種名（旧）
        ,P_ATTRIBUTE28             =>  ir_masters_rec.location_code     -- 起票部門(所属コード（新）)
        ,P_ATTRIBUTE29             =>  ir_masters_rec.location_code     -- 照会範囲(所属コード（新）)
        ,P_ATTRIBUTE30             =>  ir_masters_rec.location_code     -- 承認者範囲(所属コード（新）)
        ,P_PER_INFORMATION_CATEGORY => gv_info_category                 -- 'JP'
        ,P_PER_INFORMATION18       =>  ir_masters_rec.last_name_kanji   -- 漢字姓
        ,P_PER_INFORMATION19       =>  ir_masters_rec.first_name_kanji  -- 漢字名
        ,P_EFFECTIVE_START_DATE    =>  ir_masters_rec.effective_start_date -- OUT(登録年月日)
        ,P_EFFECTIVE_END_DATE      =>  ir_masters_rec.effective_end_date   -- OUT(登録期限年月日)
        ,P_FULL_NAME               =>  lv_full_name                        -- OUT
        ,P_COMMENT_ID              =>  ln_comment_id                       -- OUT
        ,P_NAME_COMBINATION_WARNING => lb_name_combination_warning         -- OUT
        ,P_ASSIGN_PAYROLL_WARNING  =>  lb_assign_payroll_warning           -- OUT
        ,P_ORIG_HIRE_WARNING       =>  lb_orig_hire_warning                -- OUT
        );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_api_name := 'HR_PERSON_API.UPDATE_PERSON';
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_api_err
                    ,iv_token_name1  => cv_tkn_apiname
                    ,iv_token_value1 => lv_api_name
                    ,iv_token_name2  => cv_tkn_ng_word
                    ,iv_token_value2 => cv_employee_nm    -- '社員番号'
                    ,iv_token_name3  => cv_tkn_ng_data
                    ,iv_token_value3 => ir_masters_rec.employee_number
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- アサインメントマスタ(API)
    BEGIN
      HR_ASSIGNMENT_API.UPDATE_EMP_ASG(
         P_VALIDATE               =>  FALSE
        ,P_EFFECTIVE_DATE         =>  SYSDATE
        ,P_DATETRACK_UPDATE_MODE  =>  gv_upd_mode                       -- 'CORRECTION'
        ,P_ASSIGNMENT_ID          =>  ir_masters_rec.assignment_id      -- ｱｻｲﾝﾒﾝﾄID(ﾁｪｯｸ時取得)
        ,P_OBJECT_VERSION_NUMBER  =>  ir_masters_rec.paa_version        -- ｱｻｲﾝﾒﾝﾄﾏｽﾀﾊﾞｰｼﾞｮﾝ番号(IN/OUT)
        ,P_SUPERVISOR_ID          =>  ir_masters_rec.supervisor_id      -- 管理者
        ,P_ASSIGNMENT_NUMBER      =>  ir_masters_rec.assignment_number  -- ｱｻｲﾝﾒﾝﾄ番号(ﾁｪｯｸ時取得)
        ,P_DEFAULT_CODE_COMB_ID   =>  gv_default                        -- ﾌﾟﾛﾌｧｲﾙｵﾌﾟｼｮﾝ.ﾃﾞﾌｫﾙﾄ費用勘定
        ,P_ASS_ATTRIBUTE1         =>  ir_masters_rec.change_code        -- 異動事由コード
        ,P_ASS_ATTRIBUTE2         =>  ir_masters_rec.announce_date      -- 発令日
        ,P_ASS_ATTRIBUTE3         =>  ir_masters_rec.office_location_code -- 勤務地拠点コード（新）
        ,P_ASS_ATTRIBUTE4         =>  ir_masters_rec.office_location_code_old -- 勤務地拠点コード（旧）
        ,P_ASS_ATTRIBUTE5         =>  ir_masters_rec.location_code      -- 拠点コード（新）
        ,P_ASS_ATTRIBUTE6         =>  ir_masters_rec.location_code_old  -- 拠点コード（旧）
        ,P_ASS_ATTRIBUTE7         =>  ir_masters_rec.job_system         -- 適用労働時間制コード（新）
        ,P_ASS_ATTRIBUTE8         =>  ir_masters_rec.job_system_name    -- 適用労働名（新）
        ,P_ASS_ATTRIBUTE9         =>  ir_masters_rec.job_system_old     -- 適用労働時間制コード（旧）
        ,P_ASS_ATTRIBUTE10        =>  ir_masters_rec.job_system_name_old -- 適用労働名（旧）
        ,P_ASS_ATTRIBUTE11        =>  ir_masters_rec.job_post_order     -- 職位並順コード（新）
        ,P_ASS_ATTRIBUTE12        =>  ir_masters_rec.job_post_order_old -- 職位並順コード（旧）
        ,P_ASS_ATTRIBUTE13        =>  ir_masters_rec.consent_division   -- 承認区分（新）
        ,P_ASS_ATTRIBUTE14        =>  ir_masters_rec.consent_division_old -- 承認区分（旧）
        ,P_ASS_ATTRIBUTE15        =>  ir_masters_rec.agent_division     -- 代行区分（新）
        ,P_ASS_ATTRIBUTE16        =>  ir_masters_rec.agent_division_old -- 代行区分（旧）
        ,P_ASS_ATTRIBUTE17        =>  NULL                              -- 差分連携用日付（自販機）
        ,P_ASS_ATTRIBUTE18        =>  NULL                              -- 差分連携用日付（帳票）
        ,P_CONCATENATED_SEGMENTS  =>  lv_concatenated_segments          -- OUT
        ,P_SOFT_CODING_KEYFLEX_ID =>  ln_soft_coding_keyflex_id         -- IN/OUT
        ,P_COMMENT_ID             =>  ln_comment_id                     -- OUT
        ,P_EFFECTIVE_START_DATE   =>  ir_masters_rec.effective_start_date -- OUT（登録年月日）
        ,P_EFFECTIVE_END_DATE     =>  ir_masters_rec.effective_end_date -- OUT（登録期限年月日）
        ,P_NO_MANAGERS_WARNING    =>  lb_no_managers_warning            -- OUT
        ,P_OTHER_MANAGER_WARNING  =>  lb_other_manager_warning          -- OUT
    );

    EXCEPTION
      WHEN OTHERS THEN
        lv_api_name := 'HR_ASSIGNMENT_API.UPDATE_EMP_ASG';
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_api_err
                    ,iv_token_name1  => cv_tkn_apiname
                    ,iv_token_value1 => lv_api_name
                    ,iv_token_name2  => cv_tkn_ng_word
                    ,iv_token_value2 => cv_employee_nm    -- '社員番号'
                    ,iv_token_name3  => cv_tkn_ng_data
                    ,iv_token_value3 => ir_masters_rec.employee_number
                   );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;

    IF (ir_masters_rec.location_id_kbn = gv_sts_yes) THEN  -- 事業所 変更あり
      -- アサインメントマスタ(API)
      BEGIN
        HR_ASSIGNMENT_API.UPDATE_EMP_ASG_CRITERIA(
           P_VALIDATE                      =>  FALSE
          ,P_EFFECTIVE_DATE                =>  SYSDATE
          ,P_DATETRACK_UPDATE_MODE         =>  gv_upd_mode                      -- 'CORRECTION'
          ,P_ASSIGNMENT_ID                 =>  ir_masters_rec.assignment_id     -- ｱｻｲﾝﾒﾝﾄID(ﾁｪｯｸ時取得)
          ,P_LOCATION_ID                   =>  ir_masters_rec.location_id       -- 事業所(勤務地拠点コード変更時）
          ,P_OBJECT_VERSION_NUMBER         =>  ir_masters_rec.paa_version       -- ｱｻｲﾝﾒﾝﾄﾏｽﾀﾊﾞｰｼﾞｮﾝ番号(IN/OUT)
          ,P_SPECIAL_CEILING_STEP_ID       =>  ln_special_ceiling_step_id       -- OUT
          ,P_PEOPLE_GROUP_ID               =>  ln_people_group_id               -- OUT
          ,P_GROUP_NAME                    =>  lv_group_name                    -- OUT
          ,P_EFFECTIVE_START_DATE          =>  ir_masters_rec.effective_start_date --OUT（登録年月日）
          ,P_EFFECTIVE_END_DATE            =>  ir_masters_rec.effective_end_date -- OUT（登録期限年月日）
          ,P_ORG_NOW_NO_MANAGER_WARNING    =>  lb_org_now_no_manager_warning    -- OUT
          ,P_OTHER_MANAGER_WARNING         =>  lb_other_manager_warning         -- OUT
          ,P_SPP_DELETE_WARNING            =>  lb_spp_delete_warning            -- OUT
          ,P_ENTRIES_CHANGED_WARNING       =>  lv_entries_changes_warn          -- OUT
          ,P_TAX_DISTRICT_CHANGED_WARNING  =>  lb_tax_district_changed_warn     -- OUT
        );
      EXCEPTION
        WHEN OTHERS THEN
          lv_api_name := 'HR_ASSIGNMENT_API.UPDATE_EMP_ASG_CRITERIA';
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_api_err
                      ,iv_token_name1  => cv_tkn_apiname
                      ,iv_token_value1 => lv_api_name
                      ,iv_token_name2  => cv_tkn_ng_word
                      ,iv_token_value2 => cv_employee_nm    -- '社員番号'
                      ,iv_token_name3  => cv_tkn_ng_data
                      ,iv_token_value3 => ir_masters_rec.employee_number
                      );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** API関数エラー時(関数使用直後) ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   #######################################
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
--#####################################  固定部 END   #############################################
--
  END changes_proc;
--
  /***********************************************************************************
   * Procedure Name   : retire_proc
   * Description      : 退職処理を行うプロシージャ
   ***********************************************************************************/
  PROCEDURE retire_proc(
    ir_masters_rec IN OUT masters_rec,  -- 1.退職対象データ
    ir_retire_date IN OUT DATE,         -- 2.退職日を設定
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'retire_proc'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    -- HR_EX_EMPLOYEE_API.ACTUAL_TERMINATION_EMP
    ld_last_std_process_date    DATE;
    lb_supervisor_warn          BOOLEAN;
    lb_event_warn               BOOLEAN;
    lb_interview_warn           BOOLEAN;
    lb_review_warn              BOOLEAN;
    lb_recruiter_warn           BOOLEAN;
    lb_asg_future_changes_warn  BOOLEAN;
    lv_entries_changed_warn     VARCHAR2(200);
    lb_pay_proposal_warn        BOOLEAN;
    lb_dod_warn                 BOOLEAN;

    -- HR_EX_EMPLOYEE_API.FINAL_PROCESS_EMP(
    lb_org_now_no_manager_warning   BOOLEAN;
    lb_asg_future_changes_warning   BOOLEAN;
    lv_entries_changed_warning      VARCHAR2(1);
--
    lv_api_name                 VARCHAR2(200); -- エラートークン用
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
    -- サービス期間ID取得
    get_service_id(
       ir_masters_rec
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- サービス期間ID取得エラー
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    BEGIN
      -- 従業員マスタ(API)
      HR_EX_EMPLOYEE_API.ACTUAL_TERMINATION_EMP(
        P_VALIDATE                   => FALSE
       ,P_EFFECTIVE_DATE             => (ir_retire_date - 1)                    -- 登録期限年月日
       ,P_PERIOD_OF_SERVICE_ID       => ir_masters_rec.period_of_service_id     -- サービスID
       ,P_OBJECT_VERSION_NUMBER      => ir_masters_rec.ppos_version             -- ｻｰﾋﾞｽ期間ﾏｽﾀﾊﾞｰｼﾞｮﾝ番号
       ,P_ACTUAL_TERMINATION_DATE    => ir_retire_date                          -- 退職日
       ,P_LAST_STANDARD_PROCESS_DATE => ir_retire_date                          -- 最終給与処理日
       ,P_PERSON_TYPE_ID             => gv_person_type_ex                       -- パーソンタイプ(退職者)
       ,P_LAST_STD_PROCESS_DATE_OUT  => ld_last_std_process_date    -- OUT
       ,P_SUPERVISOR_WARNING         => lb_supervisor_warn          -- OUT
       ,P_EVENT_WARNING              => lb_event_warn               -- OUT
       ,P_INTERVIEW_WARNING          => lb_interview_warn           -- OUT
       ,P_REVIEW_WARNING             => lb_review_warn              -- OUT
       ,P_RECRUITER_WARNING          => lb_recruiter_warn           -- OUT
       ,P_ASG_FUTURE_CHANGES_WARNING => lb_asg_future_changes_warn  -- OUT
       ,P_ENTRIES_CHANGED_WARNING    => lv_entries_changed_warn     -- OUT
       ,P_PAY_PROPOSAL_WARNING       => lb_pay_proposal_warn        -- OUT
       ,P_DOD_WARNING                => lb_dod_warn                 -- OUT
      );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_api_name := 'HR_EX_EMPLOYEE_API.ACTUAL_TERMINATION_EMP';
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_api_err
                    ,iv_token_name1  => cv_tkn_apiname
                    ,iv_token_value1 => lv_api_name
                    ,iv_token_name2  => cv_tkn_ng_word
                    ,iv_token_value2 => cv_employee_nm    -- '社員番号'
                    ,iv_token_name3  => cv_tkn_ng_data
                    ,iv_token_value3 => ir_masters_rec.employee_number
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    BEGIN
      HR_EX_EMPLOYEE_API.FINAL_PROCESS_EMP(
        P_VALIDATE                      => FALSE
       ,P_PERIOD_OF_SERVICE_ID          => ir_masters_rec.period_of_service_id  -- ｻｰﾋﾞｽID
       ,P_OBJECT_VERSION_NUMBER         => ir_masters_rec.ppos_version          -- ｻｰﾋﾞｽ期間ﾏｽﾀﾊﾞｰｼﾞｮﾝ番号
       ,P_FINAL_PROCESS_DATE            => ir_retire_date    -- 退職日(IN/OUT)（P_ACTUAL_TERMINATION_DATEと同じ日を設定）
       ,P_ORG_NOW_NO_MANAGER_WARNING    => lb_org_now_no_manager_warning    -- OUT
       ,P_ASG_FUTURE_CHANGES_WARNING    => lb_asg_future_changes_warning    -- OUT
       ,P_ENTRIES_CHANGED_WARNING       => lv_entries_changed_warning   -- OUT
      );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_api_name := 'HR_EX_EMPLOYEE_API.FINAL_PROCESS_EMP';
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_api_err
                    ,iv_token_name1  => cv_tkn_apiname
                    ,iv_token_value1 => lv_api_name
                    ,iv_token_name2  => cv_tkn_ng_word
                    ,iv_token_value2 => cv_employee_nm    -- '社員番号'
                    ,iv_token_name3  => cv_tkn_ng_data
                    ,iv_token_value3 => ir_masters_rec.employee_number
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    IF ir_masters_rec.emp_kbn = gv_kbn_new THEN  -- 新規社員はinsert_procにて更新
      NULL;
    ELSE
      -- ユーザマスタ(API)
      BEGIN
        FND_USER_PKG.UPDATEUSER(
           X_USER_NAME            => ir_masters_rec.employee_number -- 社員番号
          ,X_OWNER                => gv_owner                       -- 'CUST'
          ,X_END_DATE             => ir_retire_date                 -- 有効日（至）
        );
--
      EXCEPTION
        WHEN OTHERS THEN
          lv_api_name := 'FND_USER_PKG.UPDATEUSER';
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_api_err
                      ,iv_token_name1  => cv_tkn_apiname
                      ,iv_token_value1 => lv_api_name
                      ,iv_token_name2  => cv_tkn_ng_word
                      ,iv_token_value2 => cv_employee_nm    -- '社員番号'
                      ,iv_token_name3  => cv_tkn_ng_data
                      ,iv_token_value3 => ir_masters_rec.employee_number
                      );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** API関数エラー時(関数使用直後) ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   #######################################
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
--#####################################  固定部 END   #############################################
--
  END retire_proc;
--
  /***********************************************************************************
   * Procedure Name   : re_hire_proc
   * Description      : 退職者を再雇用登録を行うプロシージャ
   ***********************************************************************************/
  PROCEDURE re_hire_proc(
    ir_masters_rec IN OUT masters_rec,  -- 1.再雇用対象データ
    ir_retire_date IN DATE,             -- 2.退職日
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 're_hire_proc'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    -- HR_EX_EMPLOYEE_API.RE_HIRE_EX_EMPLOYEE
    ln_assignment_sequence      per_all_assignments_f.assignment_sequence%TYPE;
    lb_assign_payroll_warning   BOOLEAN;
--
    -- 退職データの待避(PERSON_TYPE_ID:'EMP')
    ln_assignment_id_old        per_all_assignments_f.assignment_id%TYPE;
    ld_effective_start_date_old per_all_assignments_f.effective_start_date%TYPE;
--
    lv_api_name                 VARCHAR2(200); -- エラートークン用
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
    -- ユーザ存在チェック
    check_fnd_user(
       ir_masters_rec
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- ユーザ取得エラー
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;

    -- 従業員マスタの退職後レコードの取得（PERSON_TYPE_ID:EX_EMP のレコードを再雇用レコードに更新）
    BEGIN
      SELECT object_version_number
      INTO   ir_masters_rec.pap_version
      FROM   per_all_people_f pap           -- 従業員マスタ
      WHERE  pap.person_id = ir_masters_rec.person_id           -- パーソンID
      AND    pap.effective_start_date = (ir_retire_date + 1)    -- 登録年月日(入社日)
      AND    pap.effective_end_date >= (ir_retire_date + 1)     -- 登録期限年月日
      ;
    EXCEPTION
      WHEN OTHERS THEN
          RAISE global_api_others_expt;
    END;
--
    -- 従業員マスタの履歴レコードの待避
    ln_assignment_id_old        := ir_masters_rec.assignment_id;
    ld_effective_start_date_old := ir_masters_rec.effective_start_date;

    BEGIN
      -- 従業員マスタ(API) -- 再雇用 --
      HR_EMPLOYEE_API.RE_HIRE_EX_EMPLOYEE(
        P_VALIDATE                  => FALSE
       ,P_HIRE_DATE                 =>  ir_masters_rec.hire_date    -- 社員ｲﾝﾀﾌｪｰｽ.入社年月日
       ,P_PERSON_ID                 =>  ir_masters_rec.person_id    -- 従業員ID
       ,P_PER_OBJECT_VERSION_NUMBER =>  ir_masters_rec.pap_version  -- 従業員ﾏｽﾀﾊﾞｰｼﾞｮﾝ番号(IN/OUT)
       ,P_PERSON_TYPE_ID            =>  gv_person_type              -- パーソンタイプ
       ,P_REHIRE_REASON             =>  NULL
       ,P_ASSIGNMENT_ID             =>  ir_masters_rec.assignment_id        -- OUT（新ｱｻｲﾝﾒﾝﾄID）
       ,P_ASG_OBJECT_VERSION_NUMBER =>  ir_masters_rec.paa_version          -- OUT（新ｱｻｲﾝﾒﾝﾄﾏｽﾀﾊﾞｰｼﾞｮﾝ番号）
       ,P_PER_EFFECTIVE_START_DATE  =>  ir_masters_rec.effective_start_date -- OUT（新登録年月日）
       ,P_PER_EFFECTIVE_END_DATE    =>  ir_masters_rec.effective_end_date   -- OUT（新登録期限年月日）
       ,P_ASSIGNMENT_SEQUENCE       =>  ln_assignment_sequence              -- OUT
       ,P_ASSIGNMENT_NUMBER         =>  ir_masters_rec.assignment_number    -- OUT（新ｱｻｲﾝﾒﾝﾄ番号）
       ,P_ASSIGN_PAYROLL_WARNING    =>  lb_assign_payroll_warning           -- OUT
        );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_api_name := 'HR_EMPLOYEE_API.RE_HIRE_EX_EMPLOYEE';
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_api_err
                    ,iv_token_name1  => cv_tkn_apiname
                    ,iv_token_value1 => lv_api_name
                    ,iv_token_name2  => cv_tkn_ng_word
                    ,iv_token_value2 => cv_employee_nm    -- '社員番号'
                    ,iv_token_name3  => cv_tkn_ng_data
                    ,iv_token_value3 => ir_masters_rec.employee_number
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;

    -- アサインメントマスタに新レコードが作成された場合(UPDATEではなく履歴が作成 assignment_sequenceもｶｳﾝﾄｱｯﾌﾟ)
    IF ir_masters_rec.assignment_id <> ln_assignment_id_old THEN
      -- 自販機・営業帳票側に、更新レコードとして２レコードが送られる為、旧データの
      -- 差分連携用日付（自販機）差分連携用日付（帳票）に更新日付をセットし回避する
      BEGIN
        UPDATE per_all_assignments_f
        SET    ASS_ATTRIBUTE17 = TO_CHAR(gd_last_update_date,'YYYYMMDD HH24:MI:SS')
              ,ASS_ATTRIBUTE18 = TO_CHAR(gd_last_update_date,'YYYYMMDD HH24:MI:SS')
        WHERE  assignment_id        = ln_assignment_id_old
        AND    effective_start_date = ld_effective_start_date_old
        AND    effective_end_date   >= ld_effective_start_date_old
        ;
      EXCEPTION
        WHEN OTHERS THEN
            RAISE global_api_others_expt;
      END;
    END IF;

    -- アサインメントマスタ・サービス期間マスタの新情報取得
    --(再雇用処理ではupdatemodeがない為、ｱｻｲﾝﾒﾝﾄﾏｽﾀ・ｻｰﾋﾞｽ期間ﾏｽﾀが履歴として作成される。情報を再取得する）
    BEGIN
      SELECT paa.period_of_service_id,
             ppos.object_version_number
      INTO   ir_masters_rec.period_of_service_id,
             ir_masters_rec.ppos_version
      FROM   per_all_assignments_f paa,     -- アサインメントマスタ
             per_periods_of_service ppos    -- 従業員サービス期間マスタ
      WHERE  paa.assignment_id    = ir_masters_rec.assignment_id        -- 新アサインメントID
      AND    effective_start_date = ir_masters_rec.effective_start_date -- 登録年月日
      AND    effective_end_date   = ir_masters_rec.effective_end_date   -- 登録期限年月日
      AND    ppos.period_of_service_id = paa.period_of_service_id;  -- サービスID
    EXCEPTION
      WHEN OTHERS THEN
          RAISE global_api_others_expt;
    END;
--
    -- 再雇用処理後時は事業所の更新を行う
    ir_masters_rec.location_id_kbn := gv_sts_yes;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** API関数エラー時(関数使用直後) ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   #######################################
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
--#####################################  固定部 END   #############################################
--
  END re_hire_proc;
--
  /***********************************************************************************
   * Procedure Name   : re_hire_ass_proc
   * Description      : 再雇用登録を行った社員のアサインメントを登録するプロシージャ
   ***********************************************************************************/
  PROCEDURE re_hire_ass_proc(
    ir_masters_rec IN OUT masters_rec,  -- 1.再雇用対象データ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 're_hire_ass_proc'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    -- HR_ASSIGNMENT_API.UPDATE_EMP_ASG
    lv_concatenated_segments    VARCHAR2(200);
    ln_soft_coding_keyflex_id   per_all_assignments_f.soft_coding_keyflex_id%type;
    ln_comment_id               per_all_people_f.comment_id%TYPE;
    lb_no_managers_warning      BOOLEAN;
    lb_other_manager_warning    BOOLEAN;

    -- HR_ASSIGNMENT_API.UPDATE_EMP_ASG_CRITERIA
    ln_special_ceiling_step_id      per_all_assignments_f.special_ceiling_step_id%type;
    ln_people_group_id              per_all_assignments_f.people_group_id%type;
    lv_group_name                   VARCHAR2(200);
    lb_org_now_no_manager_warning   BOOLEAN;
    lb_spp_delete_warning           BOOLEAN;
    lv_entries_changes_warn         VARCHAR2(1);
    lb_tax_district_changed_warn    BOOLEAN;

    lv_api_name                   VARCHAR2(200); -- エラートークン用
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
    -- アサインメントマスタ(API)
    BEGIN
      HR_ASSIGNMENT_API.UPDATE_EMP_ASG(
         P_VALIDATE               =>  FALSE
        ,P_EFFECTIVE_DATE         =>  SYSDATE
        ,P_DATETRACK_UPDATE_MODE  =>  gv_upd_mode                       -- 'CORRECTION'
        ,P_ASSIGNMENT_ID          =>  ir_masters_rec.assignment_id      -- ｱｻｲﾝﾒﾝﾄID(ﾁｪｯｸ時取得)
        ,P_OBJECT_VERSION_NUMBER  =>  ir_masters_rec.paa_version        -- ｱｻｲﾝﾒﾝﾄﾏｽﾀﾊﾞｰｼﾞｮﾝ番号(IN/OUT)
        ,P_SUPERVISOR_ID          =>  ir_masters_rec.supervisor_id      -- 管理者
        ,P_ASSIGNMENT_NUMBER      =>  ir_masters_rec.assignment_number  -- ｱｻｲﾝﾒﾝﾄ番号(ﾁｪｯｸ時取得)
        ,P_DEFAULT_CODE_COMB_ID   =>  gv_default                        -- ﾌﾟﾛﾌｧｲﾙｵﾌﾟｼｮﾝ.ﾃﾞﾌｫﾙﾄ費用勘定
        ,P_ASS_ATTRIBUTE1         =>  ir_masters_rec.change_code        -- 異動事由コード
        ,P_ASS_ATTRIBUTE2         =>  ir_masters_rec.announce_date      -- 発令日
        ,P_ASS_ATTRIBUTE3         =>  ir_masters_rec.office_location_code -- 勤務地拠点コード（新）
        ,P_ASS_ATTRIBUTE4         =>  ir_masters_rec.office_location_code_old -- 勤務地拠点コード（旧）
        ,P_ASS_ATTRIBUTE5         =>  ir_masters_rec.location_code      -- 拠点コード（新）
        ,P_ASS_ATTRIBUTE6         =>  ir_masters_rec.location_code_old  -- 拠点コード（旧）
        ,P_ASS_ATTRIBUTE7         =>  ir_masters_rec.job_system         -- 適用労働時間制コード（新）
        ,P_ASS_ATTRIBUTE8         =>  ir_masters_rec.job_system_name    -- 適用労働名（新）
        ,P_ASS_ATTRIBUTE9         =>  ir_masters_rec.job_system_old     -- 適用労働時間制コード（旧）
        ,P_ASS_ATTRIBUTE10        =>  ir_masters_rec.job_system_name_old -- 適用労働名（旧）
        ,P_ASS_ATTRIBUTE11        =>  ir_masters_rec.job_post_order     -- 職位並順コード（新）
        ,P_ASS_ATTRIBUTE12        =>  ir_masters_rec.job_post_order_old -- 職位並順コード（旧）
        ,P_ASS_ATTRIBUTE13        =>  ir_masters_rec.consent_division   -- 承認区分（新）
        ,P_ASS_ATTRIBUTE14        =>  ir_masters_rec.consent_division_old -- 承認区分（旧）
        ,P_ASS_ATTRIBUTE15        =>  ir_masters_rec.agent_division     -- 代行区分（新）
        ,P_ASS_ATTRIBUTE16        =>  ir_masters_rec.agent_division_old -- 代行区分（旧）
        ,P_CONCATENATED_SEGMENTS  =>  lv_concatenated_segments          -- OUT
        ,P_SOFT_CODING_KEYFLEX_ID =>  ln_soft_coding_keyflex_id         -- IN/OUT
        ,P_COMMENT_ID             =>  ln_comment_id                     -- OUT
        ,P_EFFECTIVE_START_DATE   =>  ir_masters_rec.effective_start_date -- OUT（登録年月日）
        ,P_EFFECTIVE_END_DATE     =>  ir_masters_rec.effective_end_date -- OUT（登録期限年月日）
        ,P_NO_MANAGERS_WARNING    =>  lb_no_managers_warning            -- OUT
        ,P_OTHER_MANAGER_WARNING  =>  lb_other_manager_warning          -- OUT
    );

    EXCEPTION
      WHEN OTHERS THEN
        lv_api_name := 'HR_ASSIGNMENT_API.UPDATE_EMP_ASG';
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_api_err
                    ,iv_token_name1  => cv_tkn_apiname
                    ,iv_token_value1 => lv_api_name
                    ,iv_token_name2  => cv_tkn_ng_word
                    ,iv_token_value2 => cv_employee_nm    -- '社員番号'
                    ,iv_token_name3  => cv_tkn_ng_data
                    ,iv_token_value3 => ir_masters_rec.employee_number
                   );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;

    -- アサインメントマスタ(API)
    BEGIN
      HR_ASSIGNMENT_API.UPDATE_EMP_ASG_CRITERIA(
          P_VALIDATE                      =>  FALSE
        ,P_EFFECTIVE_DATE                =>  SYSDATE
        ,P_DATETRACK_UPDATE_MODE         =>  gv_upd_mode                      -- 'CORRECTION'
        ,P_ASSIGNMENT_ID                 =>  ir_masters_rec.assignment_id     -- ｱｻｲﾝﾒﾝﾄID(ﾁｪｯｸ時取得)
        ,P_LOCATION_ID                   =>  ir_masters_rec.location_id       -- 事業所(勤務地拠点コード変更時）
        ,P_OBJECT_VERSION_NUMBER         =>  ir_masters_rec.paa_version       -- ｱｻｲﾝﾒﾝﾄﾏｽﾀﾊﾞｰｼﾞｮﾝ番号(IN/OUT)
        ,P_SPECIAL_CEILING_STEP_ID       =>  ln_special_ceiling_step_id       -- OUT
        ,P_PEOPLE_GROUP_ID               =>  ln_people_group_id               -- OUT
        ,P_GROUP_NAME                    =>  lv_group_name                    -- OUT
        ,P_EFFECTIVE_START_DATE          =>  ir_masters_rec.effective_start_date --OUT（登録年月日）
        ,P_EFFECTIVE_END_DATE            =>  ir_masters_rec.effective_end_date -- OUT（登録期限年月日）
        ,P_ORG_NOW_NO_MANAGER_WARNING    =>  lb_org_now_no_manager_warning    -- OUT
        ,P_OTHER_MANAGER_WARNING         =>  lb_other_manager_warning         -- OUT
        ,P_SPP_DELETE_WARNING            =>  lb_spp_delete_warning            -- OUT
        ,P_ENTRIES_CHANGED_WARNING       =>  lv_entries_changes_warn          -- OUT
        ,P_TAX_DISTRICT_CHANGED_WARNING  =>  lb_tax_district_changed_warn     -- OUT
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_api_name := 'HR_ASSIGNMENT_API.UPDATE_EMP_ASG_CRITERIA';
        lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    ,iv_name         => cv_api_err
                    ,iv_token_name1  => cv_tkn_apiname
                    ,iv_token_value1 => lv_api_name
                    ,iv_token_name2  => cv_tkn_ng_word
                    ,iv_token_value2 => cv_employee_nm    -- '社員番号'
                    ,iv_token_name3  => cv_tkn_ng_data
                    ,iv_token_value3 => ir_masters_rec.employee_number
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;

--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** API関数エラー時(関数使用直後) ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   #######################################
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
--#####################################  固定部 END   #############################################
--
  END re_hire_ass_proc;
--
  /***********************************************************************************
   * Procedure Name   : insert_proc
   * Description      : 新規社員の登録を行うプロシージャ
   ***********************************************************************************/
  PROCEDURE insert_proc(
    ir_masters_rec IN OUT masters_rec,  -- 1.登録対象データ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_proc'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- HR_EMPLOYEE_API.CREATE_EMPLOYEE
    lv_full_name                per_all_people_f.full_name%type;  -- フルネーム
    ln_per_comment_id           per_all_people_f.comment_id%type;
    ln_assignment_sequence      per_all_assignments_f.assignment_sequence%type;
    lb_name_combination_warning BOOLEAN;
    lb_assign_payroll_warning   BOOLEAN;
    lb_orig_hire_warning        BOOLEAN;

    -- HR_ASSIGNMENT_API.UPDATE_EMP_ASG
    lv_concatenated_segments    VARCHAR2(200);
    ln_soft_coding_keyflex_id   per_all_assignments_f.soft_coding_keyflex_id%type;
    ln_comment_id               per_all_people_f.comment_id%TYPE;
    lb_no_managers_warning      BOOLEAN;

    -- HR_ASSIGNMENT_API.UPDATE_EMP_ASG_CRITERIA
    ln_people_group_id              per_all_assignments_f.people_group_id%type;
    ln_special_ceiling_step_id      per_all_assignments_f.special_ceiling_step_id %type;
    lv_group_name                   VARCHAR2(200);
    lb_org_now_no_manager_warning   BOOLEAN;
    lb_other_manager_warning        BOOLEAN;
    lb_spp_delete_warning           BOOLEAN;
    lv_entries_changes_warn         VARCHAR2(200);
    lb_tax_district_changed_warn    BOOLEAN;
--
    lv_api_name                   VARCHAR2(200); -- エラートークン用
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
    -- 新規登録社員

    -- 従業員マスタ(API)
    BEGIN
--
      HR_EMPLOYEE_API.CREATE_EMPLOYEE(
         P_VALIDATE                  =>  FALSE
        ,P_HIRE_DATE                 =>  ir_masters_rec.hire_date            -- 入社年月日
        ,P_BUSINESS_GROUP_ID         =>  gv_bisiness_grp_id                  -- ビジネスグループID
        ,P_LAST_NAME                 =>  ir_masters_rec.last_name            -- カナ姓
        ,P_SEX                       =>  ir_masters_rec.sex                  -- 性別
        ,P_PERSON_TYPE_ID            =>  gv_person_type                      -- パーソンタイプ
        ,P_EMPLOYEE_NUMBER           =>  ir_masters_rec.employee_number      -- 社員番号
        ,P_FIRST_NAME                =>  ir_masters_rec.first_name           -- カナ名
        ,P_ATTRIBUTE3                =>  ir_masters_rec.employee_division    -- 従業員区分
        ,P_ATTRIBUTE7                =>  ir_masters_rec.license_code         -- 資格コード（新）
        ,P_ATTRIBUTE8                =>  ir_masters_rec.license_name         -- 資格名（新）
        ,P_ATTRIBUTE9                =>  ir_masters_rec.license_code_old     -- 資格コード（旧）
        ,P_ATTRIBUTE10               =>  ir_masters_rec.license_code_name_old -- 資格名（旧）
        ,P_ATTRIBUTE11               =>  ir_masters_rec.job_post             -- 職位コード（新）
        ,P_ATTRIBUTE12               =>  ir_masters_rec.job_post_name        -- 職位名（新）
        ,P_ATTRIBUTE13               =>  ir_masters_rec.job_post_old         -- 職位コード（旧）
        ,P_ATTRIBUTE14               =>  ir_masters_rec.job_post_name_old    -- 職位名（旧）
        ,P_ATTRIBUTE15               =>  ir_masters_rec.job_duty             -- 職務コード（新）
        ,P_ATTRIBUTE16               =>  ir_masters_rec.job_duty_name        -- 職務名（新）
        ,P_ATTRIBUTE17               =>  ir_masters_rec.job_duty_old         -- 職務コード（旧）
        ,P_ATTRIBUTE18               =>  ir_masters_rec.job_duty_name_old    -- 職務名（旧）
        ,P_ATTRIBUTE19               =>  ir_masters_rec.job_type             -- 職種コード（新）
        ,P_ATTRIBUTE20               =>  ir_masters_rec.job_type_name        -- 職種名（新）
        ,P_ATTRIBUTE21               =>  ir_masters_rec.job_type_old         -- 職種コード（旧）
        ,P_ATTRIBUTE22               =>  ir_masters_rec.job_type_name_old    -- 職種名（旧）
        ,P_ATTRIBUTE28               =>  ir_masters_rec.location_code        -- 起票部門(所属コード（新）)
        ,P_ATTRIBUTE29               =>  ir_masters_rec.location_code        -- 照会範囲(所属コード（新）)
        ,P_ATTRIBUTE30               =>  ir_masters_rec.location_code        -- 承認者範囲(所属コード（新）)
        ,P_PER_INFORMATION_CATEGORY  =>  gv_info_category                    -- 'JP'
        ,P_PER_INFORMATION18         =>  ir_masters_rec.last_name_kanji      -- 漢字姓
        ,P_PER_INFORMATION19         =>  ir_masters_rec.first_name_kanji     -- 漢字名
        ,P_PERSON_ID                 =>  ir_masters_rec.person_id            -- OUT（従業員ID）
        ,P_ASSIGNMENT_ID             =>  ir_masters_rec.assignment_id        -- OUT（ｱｻｲﾝﾒﾝﾄID）
        ,P_PER_OBJECT_VERSION_NUMBER =>  ir_masters_rec.pap_version          -- OUT（従業員ﾏｽﾀﾊﾞｰｼﾞｮﾝ番号）
        ,P_ASG_OBJECT_VERSION_NUMBER =>  ir_masters_rec.paa_version          -- OUT（ｱｻｲﾝﾒﾝﾄﾏｽﾀﾊﾞｰｼﾞｮﾝ番号）
        ,P_PER_EFFECTIVE_START_DATE  =>  ir_masters_rec.effective_start_date -- OUT（登録年月日）
        ,P_PER_EFFECTIVE_END_DATE    =>  ir_masters_rec.effective_end_date   -- OUT（登録期限年月日）
        ,P_FULL_NAME                 =>  lv_full_name                        -- OUT（フルネーム）
        ,P_PER_COMMENT_ID            =>  ln_per_comment_id                   -- OUT
        ,P_ASSIGNMENT_SEQUENCE       =>  ln_assignment_sequence              -- OUT
        ,P_ASSIGNMENT_NUMBER         =>  ir_masters_rec.assignment_number    -- OUT（ｱｻｲﾝﾒﾝﾄ番号）
        ,P_NAME_COMBINATION_WARNING  =>  lb_name_combination_warning         -- OUT
        ,P_ASSIGN_PAYROLL_WARNING    =>  lb_assign_payroll_warning           -- OUT
        ,P_ORIG_HIRE_WARNING         =>  lb_orig_hire_warning                -- OUT
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_api_name := 'HR_EMPLOYEE_API.CREATE_EMPLOYEE';
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_api_err
                    ,iv_token_name1  => cv_tkn_apiname
                    ,iv_token_value1 => lv_api_name
                    ,iv_token_name2  => cv_tkn_ng_word
                    ,iv_token_value2 => cv_employee_nm    -- '社員番号'
                    ,iv_token_name3  => cv_tkn_ng_data
                    ,iv_token_value3 => ir_masters_rec.employee_number
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- アサインメントマスタ(API)
    BEGIN
      HR_ASSIGNMENT_API.UPDATE_EMP_ASG(
         P_VALIDATE              =>  FALSE
        ,P_EFFECTIVE_DATE        =>  SYSDATE
        ,P_DATETRACK_UPDATE_MODE =>  gv_upd_mode                             -- 'CORRECTION'
        ,P_ASSIGNMENT_ID         =>  ir_masters_rec.assignment_id            -- HR_EMPLOYEE_API.CREATE_EMPLOYEEの出力項目のP_ASSIGNMENT_ID
        ,P_OBJECT_VERSION_NUMBER =>  ir_masters_rec.paa_version              -- IN/OUT(ｱｻｲﾝﾒﾝﾄﾏｽﾀﾊﾞｰｼﾞｮﾝ番号)
        ,P_SUPERVISOR_ID         =>  ir_masters_rec.supervisor_id            -- 管理者
        ,P_ASSIGNMENT_NUMBER     =>  ir_masters_rec.assignment_number        -- HR_EMPLOYEE_API.CREATE_EMPLOYEEの出力項目のP_ASSIGNMENT_NUMBER
        ,P_DEFAULT_CODE_COMB_ID  =>  gv_default                              -- ﾌﾟﾛﾌｧｲﾙｵﾌﾟｼｮﾝ.ﾃﾞﾌｫﾙﾄ費用勘定
        ,P_ASS_ATTRIBUTE1        =>  ir_masters_rec.change_code              -- 異動事由コード
        ,P_ASS_ATTRIBUTE2        =>  ir_masters_rec.announce_date            -- 発令日
        ,P_ASS_ATTRIBUTE3        =>  ir_masters_rec.office_location_code     -- 勤務地拠点コード（新）
        ,P_ASS_ATTRIBUTE4        =>  ir_masters_rec.office_location_code_old -- 勤務地拠点コード（旧）
        ,P_ASS_ATTRIBUTE5        =>  ir_masters_rec.location_code            -- 拠点コード（新）
        ,P_ASS_ATTRIBUTE6        =>  ir_masters_rec.location_code_old        -- 拠点コード（旧）
        ,P_ASS_ATTRIBUTE7        =>  ir_masters_rec.job_system               -- 適用労働時間制コード（新）
        ,P_ASS_ATTRIBUTE8        =>  ir_masters_rec.job_system_name          -- 適用労働名（新）
        ,P_ASS_ATTRIBUTE9        =>  ir_masters_rec.job_system_old           -- 適用労働時間制コード（旧）
        ,P_ASS_ATTRIBUTE10       =>  ir_masters_rec.job_system_name_old      -- 適用労働名（旧）
        ,P_ASS_ATTRIBUTE11       =>  ir_masters_rec.job_post_order           -- 職位並順コード（新）
        ,P_ASS_ATTRIBUTE12       =>  ir_masters_rec.job_post_order_old       -- 職位並順コード（旧）
        ,P_ASS_ATTRIBUTE13       =>  ir_masters_rec.consent_division         -- 承認区分（新）
        ,P_ASS_ATTRIBUTE14       =>  ir_masters_rec.consent_division_old     -- 承認区分（旧）
        ,P_ASS_ATTRIBUTE15       =>  ir_masters_rec.agent_division           -- 代行区分（新）
        ,P_ASS_ATTRIBUTE16       =>  ir_masters_rec.agent_division_old       -- 代行区分（旧）
        ,P_ASS_ATTRIBUTE17       =>  NULL                                    -- 差分連携用日付（自販機）
        ,P_ASS_ATTRIBUTE18       =>  NULL                                    -- 差分連携用日付（帳票）
        ,P_CONCATENATED_SEGMENTS  => lv_concatenated_segments           -- OUT
        ,P_SOFT_CODING_KEYFLEX_ID => ln_soft_coding_keyflex_id          -- IN/OUT
        ,P_COMMENT_ID             => ln_comment_id                      -- OUT
        ,P_EFFECTIVE_START_DATE   => ir_masters_rec.effective_start_date -- OUT（登録年月日）
        ,P_EFFECTIVE_END_DATE     => ir_masters_rec.effective_end_date   -- OUT（登録期限年月日）
        ,P_NO_MANAGERS_WARNING    => lb_no_managers_warning             -- OUT
        ,P_OTHER_MANAGER_WARNING  => lb_other_manager_warning           -- OUT
        );

    EXCEPTION
      WHEN OTHERS THEN
        lv_api_name := 'HR_ASSIGNMENT_API.UPDATE_EMP_ASG';
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_api_err
                    ,iv_token_name1  => cv_tkn_apiname
                    ,iv_token_value1 => lv_api_name
                    ,iv_token_name2  => cv_tkn_ng_word
                    ,iv_token_value2 => cv_employee_nm    -- '社員番号'
                    ,iv_token_name3  => cv_tkn_ng_data
                    ,iv_token_value3 => ir_masters_rec.employee_number
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;

    -- アサインメントマスタ(API)
    BEGIN
      HR_ASSIGNMENT_API.UPDATE_EMP_ASG_CRITERIA(
         P_VALIDATE                      =>  FALSE
        ,P_EFFECTIVE_DATE                =>  SYSDATE
        ,P_DATETRACK_UPDATE_MODE         =>  gv_upd_mode                        -- 'CORRECTION'
        ,P_ASSIGNMENT_ID                 =>  ir_masters_rec.assignment_id       -- ｱｻｲﾝﾒﾝﾄID(ﾁｪｯｸ時取得)
        ,P_LOCATION_ID                   =>  ir_masters_rec.location_id         -- 事業所(勤務地拠点コードから求めたID）
        ,P_OBJECT_VERSION_NUMBER         =>  ir_masters_rec.paa_version         -- ｱｻｲﾝﾒﾝﾄﾏｽﾀﾊﾞｰｼﾞｮﾝ番号(IN/OUT)
        ,P_SPECIAL_CEILING_STEP_ID       =>  ln_special_ceiling_step_id         -- OUT
        ,P_PEOPLE_GROUP_ID               =>  ln_people_group_id                 -- OUT
        ,P_GROUP_NAME                    =>  lv_group_name                      -- OUT
        ,P_EFFECTIVE_START_DATE          =>  ir_masters_rec.effective_start_date --OUT（登録年月日）
        ,P_EFFECTIVE_END_DATE            =>  ir_masters_rec.effective_end_date  -- OUT（登録期限年月日）
        ,P_ORG_NOW_NO_MANAGER_WARNING    =>  lb_org_now_no_manager_warning      -- OUT
        ,P_OTHER_MANAGER_WARNING         =>  lb_other_manager_warning           -- OUT
        ,P_SPP_DELETE_WARNING            =>  lb_spp_delete_warning              -- OUT
        ,P_ENTRIES_CHANGED_WARNING       =>  lv_entries_changes_warn            -- OUT
        ,P_TAX_DISTRICT_CHANGED_WARNING  =>  lb_tax_district_changed_warn       -- OUT
      );
      EXCEPTION
        WHEN OTHERS THEN
          lv_api_name := 'HR_ASSIGNMENT_API.UPDATE_EMP_ASG_CRITERIA';
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_api_err
                      ,iv_token_name1  => cv_tkn_apiname
                      ,iv_token_value1 => lv_api_name
                      ,iv_token_name2  => cv_tkn_ng_word
                      ,iv_token_value2 => cv_employee_nm    -- '社員番号'
                      ,iv_token_name3  => cv_tkn_ng_data
                      ,iv_token_value3 => ir_masters_rec.employee_number
                      );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;

--
    -- 退職処理 (退職区分=’Y’）** 新規登録社員データに退職年月日が設定されている場合 **
    IF ir_masters_rec.retire_kbn = gv_sts_yes THEN
      retire_proc(
        ir_masters_rec
       ,ir_masters_rec.actual_termination_date  -- 退職日
       ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
       ,lv_retcode  -- リターン・コード             --# 固定 #
       ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );

      IF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;

    -- ユーザマスタ(API)
    -- 新規登録データで退職年月日が設定されている場合にも対応
    BEGIN
      ir_masters_rec.user_id := FND_USER_PKG.CREATEUSERID(
                                X_USER_NAME             => ir_masters_rec.employee_number -- 社員番号
                               ,X_OWNER                 => gv_owner --'CUST'
                               ,X_UNENCRYPTED_PASSWORD  => gv_password -- ﾌﾟﾛﾌｧｲﾙ
                               ,X_START_DATE            => ir_masters_rec.hire_date -- 入社年月日
                               ,X_END_DATE              => ir_masters_rec.actual_termination_date -- 退職年月日
                               ,X_DESCRIPTION           => ir_masters_rec.last_name -- カナ姓
                               ,X_EMPLOYEE_ID           => ir_masters_rec.person_id --HR_EMPLOYEE_API.CREATE_EMPLOYEEの出力項目のP_PERSON_ID
                               );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_api_name := 'FND_USER_PKG.CREATEUSERID';
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_api_err
                    ,iv_token_name1  => cv_tkn_apiname
                    ,iv_token_value1 => lv_api_name
                    ,iv_token_name2  => cv_tkn_ng_word
                    ,iv_token_value2 => cv_employee_nm    -- '社員番号'
                    ,iv_token_name3  => cv_tkn_ng_data
                    ,iv_token_value3 => ir_masters_rec.employee_number
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** API関数エラー時(関数使用直後) ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   #######################################
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
--#####################################  固定部 END   #############################################
--
  END insert_proc;
--
  /***********************************************************************************
   * Procedure Name   : update_proc
   * Description      : 既存社員の更新を行うプロシージャ
   ***********************************************************************************/
  PROCEDURE update_proc(
    ir_masters_rec IN OUT masters_rec,  -- 1.異動対象データ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_proc'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    lv_api_name                 VARCHAR2(200); -- エラートークン用
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
    -- 既存社員の入社年月日の変更(入社日連携区分 = 'Y'）
      -- 1.入社年月日を退職年月日として設定し、退職処理を行う。
      -- 2.新入社年月日で再雇用処理を行う。
    IF ir_masters_rec.ymd_kbn = gv_sts_yes THEN
      -- 退職処理
      retire_proc(
        ir_masters_rec
       ,ir_masters_rec.hire_date_old   -- 退職日に既存入社日セット
       ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
       ,lv_retcode  -- リターン・コード             --# 固定 #
       ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );

      IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
      END IF;

      -- 再雇用処理
      re_hire_proc(
        ir_masters_rec
       ,ir_masters_rec.hire_date_old        -- 退職日に既存入社日をセット
       ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
       ,lv_retcode  -- リターン・コード             --# 固定 #
       ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );

      IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
      END IF;
    END IF;

    -- 既存社員の情報変更(連携区分 = 'Y'）
    IF ir_masters_rec.proc_kbn = gv_sts_yes THEN
      -- 異動処理
      changes_proc(
        ir_masters_rec
       ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
       ,lv_retcode  -- リターン・コード             --# 固定 #
       ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );

      IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
      END IF;
    -- 既存社員の情報変更なしの場合、再雇用情報引継ぎ処理を行う (連携区分 = NULL,入社日変更区分 = 'Y')
       -- 退職処理だけのデータは更新は行わない
    ELSIF ir_masters_rec.ymd_kbn = gv_sts_yes THEN
      -- 再雇用(アサインメントマスタ)処理
      re_hire_ass_proc(
        ir_masters_rec
       ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
       ,lv_retcode  -- リターン・コード             --# 固定 #
       ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );

      IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
      END IF;
    END IF;

    -- 退職年月日が設定されている場合(退職区分=’Y’）
    IF ir_masters_rec.retire_kbn = gv_sts_yes THEN
      retire_proc(
        ir_masters_rec
       ,ir_masters_rec.actual_termination_date  -- 退職日をセット
       ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
       ,lv_retcode  -- リターン・コード             --# 固定 #
       ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );

      IF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    IF  (ir_masters_rec.resp_kbn = gv_sts_yes)
     OR (ir_masters_rec.retire_kbn = gv_sts_yes) THEN  --退職者
      --ユーザ職責マスタの無効化
      delete_resp_all(
        ir_masters_rec
       ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
       ,lv_retcode  -- リターン・コード             --# 固定 #
       ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- ユーザ職責マスタ更新
      IF (ir_masters_rec.resp_kbn = gv_sts_yes) THEN
      --ユーザ職責マスタの設定
        update_resp_all(
          ir_masters_rec
         ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
         ,lv_retcode  -- リターン・コード             --# 固定 #
         ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        END IF;
      END IF;
      END IF;
--
    -- 退職年月日が設定されていない場合(退職区分=NULL）END_DATEをNULLに設定
    -- (退職されている場合は、retire_procで更新済み)
    IF (ir_masters_rec.retire_kbn IS NULL) THEN
   -- ユーザマスタ(API)
      BEGIN
        FND_USER_PKG.UPDATEUSER(
          X_USER_NAME             =>  ir_masters_rec.employee_number  -- 社員番号
         ,X_OWNER                 =>  gv_owner                        --'CUST'
         ,X_START_DATE            =>  ir_masters_rec.hire_date        -- 入社年月日
         ,X_END_DATE              =>  FND_USER_PKG.NULL_DATE          -- 有効日（NULL）
        );
  --
      EXCEPTION
        WHEN OTHERS THEN
          lv_api_name := 'FND_USER_PKG.UPDATEUSER';
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_api_err
                      ,iv_token_name1  => cv_tkn_apiname
                      ,iv_token_value1 => lv_api_name
                      ,iv_token_name2  => cv_tkn_ng_word
                      ,iv_token_value2 => cv_employee_nm    -- '社員番号'
                      ,iv_token_name3  => cv_tkn_ng_data
                      ,iv_token_value3 => ir_masters_rec.employee_number
                      );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    END IF;

    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** API関数エラー時(関数使用直後) ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   #######################################
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
--#####################################  固定部 END   #############################################
--
  END update_proc;
--
  /***********************************************************************************
   * Procedure Name   : delete_proc
   * Description      : 退職者の処理を行うプロシージャ
   ***********************************************************************************/
  PROCEDURE delete_proc(
    ir_masters_rec IN OUT masters_rec,  -- 1.退職対象データ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_proc'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    lv_api_name                 VARCHAR2(200); -- エラートークン用
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
    -- 再雇用処理
    re_hire_proc(
      ir_masters_rec
     ,ir_masters_rec.effective_end_date   -- 退職日に既存退職日セット
     ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
     ,lv_retcode  -- リターン・コード             --# 固定 #
     ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );

    IF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
    END IF;

    -- 既存社員の情報変更(連携区分 = 'Y'）
    IF (ir_masters_rec.proc_kbn = gv_sts_yes) THEN
      -- 異動処理
      changes_proc(
        ir_masters_rec
       ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
       ,lv_retcode  -- リターン・コード             --# 固定 #
       ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );

      IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
      END IF;
    -- 既存社員の情報変更なしの場合、再雇用情報引継ぎ処理を行う(連携区分 = NULL）
    ELSE
      -- 再雇用(アサインメントマスタ)処理
      re_hire_ass_proc(
        ir_masters_rec
       ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
       ,lv_retcode  -- リターン・コード             --# 固定 #
       ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );

      IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
      END IF;
    END IF;

    IF (ir_masters_rec.retire_kbn = gv_sts_yes) THEN
      -- 退職処理
      retire_proc(
        ir_masters_rec
       ,ir_masters_rec.actual_termination_date  -- 退職日セット
       ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
       ,lv_retcode  -- リターン・コード             --# 固定 #
       ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );

      IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
      END IF;

    END IF;
--
    -- ユーザ職責マスタ(API)
    IF  (ir_masters_rec.resp_kbn = gv_sts_yes) THEN -- 退職者は職責未設定(delete_resp_allは不要)
      -- ユーザ職責マスタ更新
      update_resp_all(
        ir_masters_rec
       ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
       ,lv_retcode  -- リターン・コード             --# 固定 #
       ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- 退職年月日が設定されていない場合(退職区分=NULL）END_DATEをNULLに設定
    -- (退職されている場合は、retire_procで更新済み)
    IF (ir_masters_rec.retire_kbn IS NULL) THEN
      -- ユーザマスタ(API)
      BEGIN
        FND_USER_PKG.UPDATEUSER(
          X_USER_NAME             =>  ir_masters_rec.employee_number  -- 社員番号
         ,X_OWNER                 =>  gv_owner                        --'CUST'
         ,X_START_DATE            =>  ir_masters_rec.hire_date        -- 入社年月日
         ,X_END_DATE              =>  FND_USER_PKG.NULL_DATE          -- 有効日（NULL）
        );
  --
      EXCEPTION
        WHEN OTHERS THEN
          lv_api_name := 'FND_USER_PKG.UPDATEUSER';
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_api_err
                      ,iv_token_name1  => cv_tkn_apiname
                      ,iv_token_value1 => lv_api_name
                      ,iv_token_name2  => cv_tkn_ng_word
                      ,iv_token_value2 => cv_employee_nm    -- '社員番号'
                      ,iv_token_name3  => cv_tkn_ng_data
                      ,iv_token_value3 => ir_masters_rec.employee_number
                      );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
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
--#####################################  固定部 END   #############################################
--
  END delete_proc;
--
  /***********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-2)
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
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_file_chk   BOOLEAN;   --存在チェック結果
    lv_file_size  NUMBER;    --ファイルサイズ
    lv_block_size NUMBER;    --ブロックサイズ
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
    -- ===============================
    -- コンカレントメッセージ出力
    -- ===============================
    --入力パラメータなしメッセージ出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_common_short_name
                 ,iv_name         => cv_input_no_msg
                );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );

    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );

    -- ===============================
    -- プロファイル取得
    -- ===============================
    init_get_profile(
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- CSVファイル存在チェック
    -- ===============================
    UTL_FILE.FGETATTR(gv_directory,
                      gv_file_name,
                      lv_file_chk,
                      lv_file_size,
                      lv_block_size
    );
    -- ファイルが存在しない場合エラー
    IF (NOT lv_file_chk) THEN
       lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                   ,iv_name         => cv_csv_file_err
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 職責自動割当ワーク削除処理
    -- ===============================
    DELETE xxcmm.xxcmm_wk_people_resp;
--
    -- ===============================
    -- 業務日付の取得
    -- ===============================
    cd_process_date := xxccp_common_pkg2.get_process_date;   -- 業務日付 --# 固定 #
--
    IF (cd_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_appl_short_name
                  ,iv_name         => cv_process_date_err
                 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    cc_process_date := TO_CHAR(cd_process_date,'YYYYMMDD');
--
    -- ===============================
    -- パーソンタイプの取得
    -- ===============================
    -- 従業員
    get_person_type(
       gv_user_person_type
      ,gv_person_type
      ,gv_bisiness_grp_id
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- パーソンタイプID取得エラー
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;

    -- 退職者
    get_person_type(
       gv_user_person_type_ex
      ,gv_person_type_ex
      ,gv_bisiness_grp_id_ex
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- パーソンタイプID取得エラー
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 社員インタフェース０件チェック
    -- ===============================
    BEGIN
      SELECT 1
      INTO   gn_target_cnt
      FROM   xxcmm_in_people_if xip     -- 社員インタフェース
      WHERE  ROWNUM = 1;
    EXCEPTION
      -- データなしの場合エラー
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_file_data_no_err
                   );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- ===============================
    -- ファイルロック処理
    -- ===============================
    init_file_lock(
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 初期設定処理
    -- ===============================
--
    -- WHOカラムの取得
    gn_created_by             := FND_GLOBAL.USER_ID;           -- 作成者
    gd_creation_date          := SYSDATE;                      -- 作成日
    gn_last_update_by         := FND_GLOBAL.USER_ID;           -- 最終更新者
    gd_last_update_date       := SYSDATE;                      -- 最終更新日
    gn_last_update_login      := FND_GLOBAL.LOGIN_ID;          -- 最終更新ログイン
    gn_request_id             := FND_GLOBAL.CONC_REQUEST_ID;   -- 要求ID
    gn_program_application_id := FND_GLOBAL.PROG_APPL_ID;      -- プログラムアプリケーションID
    gn_program_id             := FND_GLOBAL.CONC_PROGRAM_ID;   -- プログラムID
    gd_program_update_date    := SYSDATE;                      -- プログラム更新日
--
  EXCEPTION
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
--#################################  固定例外処理部 START   #######################################
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
--#####################################  固定部 END   #############################################
--
  END init;
--
  /***********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル変数宣言部 START   ########################
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
    lr_masters_rec masters_rec; -- 処理対象データ格納レコード
--
    lt_insert_masters masters_tbl; -- 各マスタへ登録するデータ
    lt_update_masters masters_tbl; -- 各マスタへ更新するデータ
    lt_delete_masters masters_tbl; -- 各マスタへ削除するデータ
--
    ln_insert_cnt NUMBER;          -- 登録件数
    ln_update_cnt NUMBER;          -- 更新件数
    ln_delete_cnt NUMBER;          -- 削除件数
    ln_exec_cnt   NUMBER;
    ln_log_cnt    NUMBER;
    lc_flg        CHAR(1) := ' ';  -- 重複データ用フラグ
    lb_retcd      BOOLEAN;         -- 検索結果
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
--
    -- 社員取込インターフェース
    CURSOR in_if_cur
    IS
      SELECT xip.employee_number        employee_number,
             xip.hire_date              hire_date,
             xip.actual_termination_date  actual_termination_date,
             xip.last_name_kanji        last_name_kanji,
             xip.first_name_kanji       first_name_kanji,
             xip.last_name              last_name,
             xip.first_name             first_name,
             UPPER(xip.sex)             sex,
             NVL(xip.employee_division,'1')  employee_division,
             xip.location_code          location_code,
             xip.change_code            change_code,
             xip.announce_date          announce_date,
             xip.office_location_code   office_location_code,
             xip.license_code           license_code,
             xip.license_name           license_name,
             xip.job_post               job_post,
             xip.job_post_name          job_post_name,
             xip.job_duty               job_duty,
             xip.job_duty_name          job_duty_name,
             xip.job_type               job_type,
             xip.job_type_name          job_type_name,
             xip.job_system             job_system,
             xip.job_system_name        job_system_name,
             xip.job_post_order         job_post_order,
             xip.consent_division       consent_division,
             xip.agent_division         agent_division,
             xip.office_location_code_old  office_location_code_old,
             xip.location_code_old      location_code_old,
             xip.license_code_old       license_code_old,
             xip.license_code_name_old  license_code_name_old,
             xip.job_post_old           job_post_old,
             xip.job_post_name_old      job_post_name_old,
             xip.job_duty_old           job_duty_old,
             xip.job_duty_name_old      job_duty_name_old,
             xip.job_type_old           job_type_old,
             xip.job_type_name_old      job_type_name_old,
             xip.job_system_old         job_system_old,
             xip.job_system_name_old    job_system_name_old,
             xip.job_post_order_old     job_post_order_old,
             xip.consent_division_old   consent_division_old,
             xip.agent_division_old     agent_division_old
      FROM   xxcmm_in_people_if xip
      ORDER BY xip.employee_number;

--
    -- 職責自動割当ワーク
    CURSOR wk_pr2_cur(lv_emp_kbn IN VARCHAR2)
    IS
      SELECT xwpr.employee_number,
             xwpr.responsibility_id,
             xwpr.user_id,
             xwpr.employee_kbn,
             xwpr.responsibility_key,
             xwpr.application_short_name,
             xwpr.start_date,
             xwpr.end_date
      FROM   xxcmm_wk_people_resp xwpr
      WHERE  xwpr.employee_kbn = lv_emp_kbn
      ORDER BY xwpr.employee_number,xwpr.responsibility_id;

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
    gn_target_cnt := 0; -- 処理件数
    gn_normal_cnt := 0; -- 成功件数
    gn_warn_cnt   := 0; -- 警告件数
    gn_error_cnt  := 0; -- エラー件数
    gn_skip_cnt   := 0; -- スキップ件数
    gn_rep_n_cnt  := 0; -- レポート件
    gn_rep_w_cnt  := 0; -- レポート件
    ln_insert_cnt := 0;
    ln_update_cnt := 0;
    ln_delete_cnt := 0;
    gn_if := 0; -- 社員インターフェース件数
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- 初期処理(A-2)
    -- ===============================
    init(
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
--
    -- ===============================
    -- 社員インタフェース情報取得(A-3)
    -- ===============================
--
    -- IF件数の初期化
    gn_target_cnt := 0;

    <<in_if_loop>>
    FOR in_if_rec IN in_if_cur LOOP
      -- ステータスの初期化
      gt_mst_tbl(gn_if).proc_flg := NULL;   -- 更新区分
      gt_mst_tbl(gn_if).proc_kbn := NULL;   -- 連携区分
      gt_mst_tbl(gn_if).emp_kbn := NULL;    -- 社員状態
      gt_mst_tbl(gn_if).ymd_kbn := NULL;    -- 入社日連携区分
      gt_mst_tbl(gn_if).retire_kbn := NULL; -- 退職区分
      gt_mst_tbl(gn_if).resp_kbn := NULL;   -- 職責・管理者変更区分

      -- 退避したレコードと次レコードとの比較後に、退避レコードを登録更新エリアに格納(社員番号重複データは更新しない為)
      IF (gn_target_cnt = 0) THEN
        NULL;
      ELSE
        IF (gt_mst_tbl(gn_if).employee_number <> in_if_rec.employee_number) THEN
          IF (lc_flg <> gv_flg_on) THEN
            NULL;  --処理続ける
          ELSE
            lc_flg := ' ';
            lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                        ,iv_name         => cv_data_check_err
                        ,iv_token_name1  => cv_tkn_ng_user
                        ,iv_token_value1 => gt_mst_tbl(gn_if).employee_number
                        ,iv_token_name2  => cv_tkn_ng_err
                        ,iv_token_value2 => cv_employee_err_nm  -- '社員番号重複'
                       );
            gt_mst_tbl(gn_if).proc_flg := gv_sts_error;  -- 更新不可能
            gt_mst_tbl(gn_if).row_err_message := lv_errmsg;
          END IF;
        ELSE
          lc_flg := gv_flg_on;
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_data_check_err
                      ,iv_token_name1  => cv_tkn_ng_user
                      ,iv_token_value1 => gt_mst_tbl(gn_if).employee_number
                      ,iv_token_name2  => cv_tkn_ng_err
                      ,iv_token_value2 => cv_employee_err_nm  -- '社員番号重複'
                     );
          gt_mst_tbl(gn_if).proc_flg := gv_sts_error;  -- 更新不可能
          gt_mst_tbl(gn_if).row_err_message := lv_errmsg;
        END IF;
      END IF;

      IF (gt_mst_tbl(gn_if).proc_flg IS NULL) AND (gn_target_cnt > 0) THEN
        -- ===============================
        -- データ妥当性チェック処理(A-4)
        -- ===============================
        in_if_check(
           gt_mst_tbl(gn_if)  -- 待避エリア
          ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
          ,lv_retcode  -- リターン・コード             --# 固定 #
          ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
        );
--
        --エラー処理（処理中止）
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        --警告処理（警告データ更新不可・次データ処理継続）
        ELSIF (lv_retcode = cv_status_warn) THEN
          gt_mst_tbl(gn_if).proc_flg := gv_sts_error;  -- 更新不可能
          gt_mst_tbl(gn_if).row_err_message := lv_errmsg;
        --正常処理：異動なし社員データ（SKIP）
        ELSIF ((gt_mst_tbl(gn_if).proc_kbn IS NULL)         -- 連携なし
          AND (gt_mst_tbl(gn_if).ymd_kbn IS NULL)           -- 入社日変更なし
          AND (gt_mst_tbl(gn_if).retire_kbn IS NULL)) THEN  -- 退職処理なし
          gt_mst_tbl(gn_if).proc_flg := gv_sts_thru; -- 変更なし
--
        --正常処理：新規社員データ（登録）
        ELSIF (gt_mst_tbl(gn_if).emp_kbn  = gv_kbn_new) THEN  -- 新規社員
          -- =================================
          -- 社員データ登録分チェック処理(A-5)
          -- =================================
          check_insert(
             gt_mst_tbl(gn_if)  -- 待避エリア
            ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
            ,lv_retcode  -- リターン・コード             --# 固定 #
            ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
          );
          --エラー処理（処理中止）
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_api_expt;
          --警告処理（警告データ更新不可・次データ処理継続）
          ELSIF (lv_retcode = cv_status_warn) THEN
            gt_mst_tbl(gn_if).proc_flg := gv_sts_error;  -- 更新不可能
            gt_mst_tbl(gn_if).row_err_message := lv_errmsg;
          --正常処理：新規社員データ（登録）
          ELSE
            -- =================================
            -- 社員データ登録情報格納処理(A-8)
            -- =================================
            gt_mst_tbl(gn_if).proc_flg := gv_sts_update;  -- 処理対象
            ln_insert_cnt := ln_insert_cnt + 1;
            lt_insert_masters(ln_insert_cnt) := gt_mst_tbl(gn_if);
          END IF;
--
        --正常処理：既存社員異動データ・退職社員再雇用データ（更新）
        ELSE --(emp_kbn 'U'：既存社員、'D'：退職者)
          -- =================================
          -- 社員データ更新分チェック処理(A-6)
          -- =================================
          check_update(
             gt_mst_tbl(gn_if)  -- 待避エリア
            ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
            ,lv_retcode  -- リターン・コード             --# 固定 #
            ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
          );
          --エラー処理（処理中止）
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_api_expt;
          --警告処理（警告データ更新不可・次データ処理継続）
          ELSIF (lv_retcode = cv_status_warn) THEN
            gt_mst_tbl(gn_if).proc_flg := gv_sts_error;  -- 更新不可能
            gt_mst_tbl(gn_if).row_err_message := lv_errmsg;
          --正常処理：異動なし（SKIP）
          ELSIF (gt_mst_tbl(gn_if).proc_flg  = gv_sts_thru) THEN
            NULL;
          --正常処理：既存社員データ（更新）
          ELSIF (gt_mst_tbl(gn_if).emp_kbn  = gv_kbn_employee) THEN
            -- =================================
            -- 社員データ更新情報格納処理(A-9)
            -- =================================
            gt_mst_tbl(gn_if).proc_flg := gv_sts_update;  -- 処理対象
            ln_update_cnt := ln_update_cnt + 1;
            lt_update_masters(ln_update_cnt) := gt_mst_tbl(gn_if);
          --正常処理：退職社員データ（更新）
          ELSIF (gt_mst_tbl(gn_if).emp_kbn  = gv_kbn_retiree) THEN
            -- =================================
            -- 社員データ削除情報格納処理(A-10)
            -- =================================
            gt_mst_tbl(gn_if).proc_flg := gv_sts_update;  -- 処理対象
            ln_delete_cnt := ln_delete_cnt + 1;
            lt_delete_masters(ln_delete_cnt) := gt_mst_tbl(gn_if);
          END IF;
        END IF;
      END IF;

      -- 件数のカウントアップ（異常時以外、処理件数=gn_skip_cnt + gn_normal_cnt + gn_warn_cnt ）
      -- 異動なし件数（スキップ）をカウントアップ
      IF (gt_mst_tbl(gn_if).proc_flg = gv_sts_thru) THEN  -- 異動なしデータ
        gn_skip_cnt := gn_skip_cnt + 1;
      -- 更新対象件数（正常）をカウントアップ
      ELSIF (gt_mst_tbl(gn_if).proc_flg = gv_sts_update) THEN  -- 更新対象
        gn_normal_cnt := gn_normal_cnt + 1;
      -- 更新対象件数（異常）をカウントアップ
      ELSIF (gt_mst_tbl(gn_if).proc_flg = gv_sts_error) THEN  -- 更新不可能
        gn_warn_cnt := gn_warn_cnt + 1;
      -- 異常件数をカウントアップ
      ELSE
        gn_error_cnt := gn_error_cnt +1;
      END IF;
--
      -- ==================================
      -- 社員データエラー情報格納処理(A-11)
      -- ==================================
      add_report(
        gt_mst_tbl(gn_if)  -- 待避エリア
--          ,lt_report_tbl
        ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,lv_retcode  -- リターン・コード             --# 固定 #
        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--

      -- 社員取込インタフェースの内容をチェックテーブルに待避(処理はここから始まる)
      gn_target_cnt := gn_target_cnt + 1; -- 処理件数カウントアップ
      BEGIN
        gn_if := gn_if + 1;
        gt_mst_tbl(gn_if).employee_number          := in_if_rec.employee_number;    --社員番号
        gt_mst_tbl(gn_if).hire_date                := in_if_rec.hire_date;          --入社年月日
        gt_mst_tbl(gn_if).actual_termination_date  := in_if_rec.actual_termination_date;--退職年月日
        gt_mst_tbl(gn_if).last_name_kanji          := in_if_rec.last_name_kanji;    --漢字姓
        gt_mst_tbl(gn_if).first_name_kanji         := in_if_rec.first_name_kanji;   --漢字名
        gt_mst_tbl(gn_if).last_name                := in_if_rec.last_name;          --カナ姓
        gt_mst_tbl(gn_if).first_name               := in_if_rec.first_name;         --カナ名
        gt_mst_tbl(gn_if).sex                      := UPPER(in_if_rec.sex);         --性別
        gt_mst_tbl(gn_if).employee_division        := NVL(in_if_rec.employee_division,'1');  --社員・外部委託区分
        gt_mst_tbl(gn_if).location_code            := in_if_rec.location_code;      --所属コード（新）
        gt_mst_tbl(gn_if).change_code              := in_if_rec.change_code;        --異動事由コード
        gt_mst_tbl(gn_if).announce_date            := in_if_rec.announce_date;      --発令日
        gt_mst_tbl(gn_if).office_location_code     := in_if_rec.office_location_code; --勤務地拠点コード（新）
        gt_mst_tbl(gn_if).license_code             := in_if_rec.license_code;       --資格コード（新）
        gt_mst_tbl(gn_if).license_name             := in_if_rec.license_name;       --資格名（新）
        gt_mst_tbl(gn_if).job_post                 := in_if_rec.job_post;           --職位コード（新）
        gt_mst_tbl(gn_if).job_post_name            := in_if_rec.job_post_name;      --職位名（新）
        gt_mst_tbl(gn_if).job_duty                 := in_if_rec.job_duty;           --職務コード（新）
        gt_mst_tbl(gn_if).job_duty_name            := in_if_rec.job_duty_name;      --職務名（新）
        gt_mst_tbl(gn_if).job_type                 := in_if_rec.job_type;           --職種コード（新）
        gt_mst_tbl(gn_if).job_type_name            := in_if_rec.job_type_name;      --職種名（新）
        gt_mst_tbl(gn_if).job_system               := in_if_rec.job_system;         --適用労働時間制コード（新）
        gt_mst_tbl(gn_if).job_system_name          := in_if_rec.job_system_name;    --適用労働名（新）
        gt_mst_tbl(gn_if).job_post_order           := in_if_rec.job_post_order;     --職位並順コード（新）
        gt_mst_tbl(gn_if).consent_division         := in_if_rec.consent_division;   --承認区分（新）
        gt_mst_tbl(gn_if).agent_division           := in_if_rec.agent_division;     --代行区分（新）
        gt_mst_tbl(gn_if).office_location_code_old := in_if_rec.office_location_code_old; --勤務地拠点コード（旧）
        gt_mst_tbl(gn_if).location_code_old        := in_if_rec.location_code_old;  --所属コード（旧）
        gt_mst_tbl(gn_if).license_code_old         := in_if_rec.license_code_old;   --資格コード（旧）
        gt_mst_tbl(gn_if).license_code_name_old    := in_if_rec.license_code_name_old;--資格名（旧）
        gt_mst_tbl(gn_if).job_post_old             := in_if_rec.job_post_old;       --職位コード（旧）
        gt_mst_tbl(gn_if).job_post_name_old        := in_if_rec.job_post_name_old;  --職位名（旧）
        gt_mst_tbl(gn_if).job_duty_old             := in_if_rec.job_duty_old;       --職務コード（旧）
        gt_mst_tbl(gn_if).job_duty_name_old        := in_if_rec.job_duty_name_old;  --職務名（旧）
        gt_mst_tbl(gn_if).job_type_old             := in_if_rec.job_type_old;       --職種コード（旧）
        gt_mst_tbl(gn_if).job_type_name_old        := in_if_rec.job_type_name_old;  --職種名（旧）
        gt_mst_tbl(gn_if).job_system_old           := in_if_rec.job_system_old;     --適用労働時間制コード（旧）
        gt_mst_tbl(gn_if).job_system_name_old      := in_if_rec.job_system_name_old;--適用労働名（旧）
        gt_mst_tbl(gn_if).job_post_order_old       := in_if_rec.job_post_order_old; --職位並順コード（旧）
        gt_mst_tbl(gn_if).consent_division_old     := in_if_rec.consent_division_old; --承認区分（旧）
        gt_mst_tbl(gn_if).agent_division_old       := in_if_rec.agent_division_old; --代行区分（旧）
        gt_mst_tbl(gn_if).proc_flg := NULL;   -- 更新区分
      EXCEPTION
        WHEN VALUE_ERROR THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_data_check_err
                      ,iv_token_name1  => cv_tkn_ng_user
                      ,iv_token_value1 => gt_mst_tbl(gn_if).employee_number
                      ,iv_token_name2  => cv_tkn_ng_err
                      ,iv_token_value2 => cv_data_err  -- 'データ異常'
                     );
          RAISE global_api_expt;
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
    END LOOP in_if_loop;
--
    -- 最終データチェック処理(in_if_loopの内容と同様)
    -- ステータスの初期化
    gt_mst_tbl(gn_if).proc_kbn := NULL;   -- 連携区分
    gt_mst_tbl(gn_if).emp_kbn := NULL;    -- 社員状態
    gt_mst_tbl(gn_if).ymd_kbn := NULL;    -- 入社日連携区分
    gt_mst_tbl(gn_if).retire_kbn := NULL; -- 退職区分
    gt_mst_tbl(gn_if).proc_flg := NULL;   -- 更新区分
    -- 社員データ重複チェック（前のデータと同じ場合）
    IF (lc_flg = gv_flg_on) THEN
      lc_flg := ' ';
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_appl_short_name
                  ,iv_name         => cv_data_check_err
                  ,iv_token_name1  => cv_tkn_ng_user
                  ,iv_token_value1 => gt_mst_tbl(gn_if).employee_number
                  ,iv_token_name2  => cv_tkn_ng_err
                  ,iv_token_value2 => cv_employee_err_nm  -- '社員番号重複'
                  );
      gt_mst_tbl(gn_if).proc_flg := gv_sts_error;  -- 更新不可能
      gt_mst_tbl(gn_if).row_err_message := lv_errmsg;
    ELSE
      -- ===============================
      -- データ妥当性チェック処理(A-4)
      -- ===============================
      in_if_check(
         gt_mst_tbl(gn_if)  -- 待避エリア
        ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,lv_retcode  -- リターン・コード             --# 固定 #
        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      --エラー処理（処理中止）
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
--
      --警告処理（警告データ更新不可・次データ処理継続）
      ELSIF (lv_retcode = cv_status_warn) THEN
        gt_mst_tbl(gn_if).proc_flg := gv_sts_error;  -- 更新不可能
        gt_mst_tbl(gn_if).row_err_message := lv_errmsg;
--
      --正常処理：異動なし社員データ（SKIP）
      ELSIF ((gt_mst_tbl(gn_if).proc_kbn IS NULL)         -- 連携なし
        AND (gt_mst_tbl(gn_if).ymd_kbn IS NULL)           -- 入社日変更なし
        AND (gt_mst_tbl(gn_if).retire_kbn IS NULL)) THEN  -- 退職処理なし
        gt_mst_tbl(gn_if).proc_flg := gv_sts_thru; -- 変更なし
--
      --正常処理：新規社員データ（登録）
      ELSIF (gt_mst_tbl(gn_if).emp_kbn  = gv_kbn_new) THEN  -- 新規社員
        -- =================================
        -- 社員データ登録分チェック処理(A-5)
        -- =================================
        check_insert(
           gt_mst_tbl(gn_if)  -- 待避エリア
          ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
          ,lv_retcode  -- リターン・コード             --# 固定 #
          ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
        );
        --エラー処理（処理中止）
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        --警告処理（警告データ更新不可・次データ処理継続）
        ELSIF (lv_retcode = cv_status_warn) THEN
          gt_mst_tbl(gn_if).proc_flg := gv_sts_error;  -- 更新不可能
          gt_mst_tbl(gn_if).row_err_message := lv_errmsg;
        --正常処理：新規社員データ（登録）
        ELSE
          -- =================================
          -- 社員データ登録情報格納処理(A-8)
          -- =================================
          gt_mst_tbl(gn_if).proc_flg := gv_sts_update;  -- 処理対象
          ln_insert_cnt := ln_insert_cnt + 1;
          lt_insert_masters(ln_insert_cnt) := gt_mst_tbl(gn_if);
        END IF;

      --正常処理：既存社員異動データ・退職社員再雇用データ（更新）
      ELSE --(emp_kbn 'U'：既存社員、'D'：退職者)
        -- =================================
        -- 社員データ更新分チェック処理(A-6)
        -- =================================
        check_update(
           gt_mst_tbl(gn_if)  -- 待避エリア
          ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
          ,lv_retcode  -- リターン・コード             --# 固定 #
          ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
        );
        --エラー処理（処理中止）
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        --警告処理（警告データ更新不可・次データ処理継続）
        ELSIF (lv_retcode = cv_status_warn) THEN
          gt_mst_tbl(gn_if).proc_flg := gv_sts_error;  -- 更新不可能
          gt_mst_tbl(gn_if).row_err_message := lv_errmsg;
        --正常処理：既存社員データ（更新）
        ELSIF (gt_mst_tbl(gn_if).emp_kbn  = gv_kbn_employee) THEN
          -- =================================
          -- 社員データ更新情報格納処理(A-9)
          -- =================================
          gt_mst_tbl(gn_if).proc_flg := gv_sts_update;  -- 処理対象
          ln_update_cnt := ln_update_cnt + 1;
          lt_update_masters(ln_update_cnt) := gt_mst_tbl(gn_if);
        --正常処理：異動なし（SKIP）
        ELSIF (gt_mst_tbl(gn_if).proc_flg  = gv_sts_thru) THEN
          NULL;
        --正常処理：退職社員データ（更新）
        ELSIF (gt_mst_tbl(gn_if).emp_kbn  = gv_kbn_retiree) THEN
          -- =================================
          -- 社員データ削除情報格納処理(A-10)
          -- =================================
          gt_mst_tbl(gn_if).proc_flg := gv_sts_update;  -- 処理対象
          ln_delete_cnt := ln_delete_cnt + 1;
          lt_delete_masters(ln_delete_cnt) := gt_mst_tbl(gn_if);
        END IF;
      END IF;
    END IF;

    -- 件数のカウントアップ（異常時以外、処理件数=gn_skip_cnt + gn_normal_cnt + gn_warn_cnt ）
    -- 異動なし件数（スキップ）をカウントアップ
    IF (gt_mst_tbl(gn_if).proc_flg = gv_sts_thru) THEN  -- 異動なしデータ
      gn_skip_cnt := gn_skip_cnt + 1;
    -- 更新対象件数（正常）をカウントアップ
    ELSIF (gt_mst_tbl(gn_if).proc_flg = gv_sts_update) THEN  -- 更新対象
      gn_normal_cnt := gn_normal_cnt + 1;
    -- 更新対象件数（異常）をカウントアップ
    ELSIF (gt_mst_tbl(gn_if).proc_flg = gv_sts_error) THEN  -- 更新不可能
      gn_warn_cnt := gn_warn_cnt + 1;
    -- 異常件数をカウントアップ
    ELSE
      gn_error_cnt := gn_error_cnt +1;
    END IF;
--
    -- ==================================
    -- 社員データエラー情報格納処理(A-11)
    -- ==================================
    add_report(
      gt_mst_tbl(gn_if)  -- 待避エリア
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ================================
    -- 社員データ反映処理(A-12)
    -- ================================
--
    IF (ln_insert_cnt > 0) THEN
      -- 新規社員登録処理
      <<lt_insert_masters_loop>>
      FOR ln_cnt IN 1 .. ln_insert_cnt LOOP
        -- 新規社員登録処理
        insert_proc(
           lt_insert_masters(ln_cnt)
          ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
          ,lv_retcode  -- リターン・コード             --# 固定 #
          ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
        );
--
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        END IF;
      END LOOP lt_insert_masters_loop;

      -- 新規社員の職責は社員職責自動割当ワークより一括登録
      <<wk_pr2_loop>>
      FOR wk_pr2_rec IN wk_pr2_cur(gv_kbn_new) LOOP
      -- 新規社員登録処理
        insert_resp_all(
            wk_pr2_rec.employee_number
          ,wk_pr2_rec.responsibility_key
          ,wk_pr2_rec.application_short_name
          ,wk_pr2_rec.start_date
          ,wk_pr2_rec.end_date
          ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
          ,lv_retcode  -- リターン・コード             --# 固定 #
          ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        END IF;
      END LOOP wk_pr2_loop;
    END IF;
--
    IF (ln_update_cnt > 0) THEN
      -- 既存社員更新処理
      <<lt_update_masters_loop>>
      FOR ln_cnt IN 1 .. ln_update_cnt LOOP
        -- 既存社員異動処理
        update_proc(
           lt_update_masters(ln_cnt)
          ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
          ,lv_retcode  -- リターン・コード             --# 固定 #
          ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
        );
--
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        END IF;
      END LOOP lt_update_masters_loop;
    END IF;
--
    IF (ln_delete_cnt > 0) THEN
      -- 退職者再雇用処理
      <<lt_delete_masters_loop>>
      FOR ln_cnt IN 1..ln_delete_cnt LOOP
        -- 退職者処理
        delete_proc(
           lt_delete_masters(ln_cnt)
          ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
          ,lv_retcode  -- リターン・コード             --# 固定 #
          ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
        );
--
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        END IF;
      END LOOP lt_update_masters_loop;
    END IF;
--
    -- 初期化
    ov_retcode := cv_status_normal;

    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      -- カーソルが開いていれば
--
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
  PROCEDURE main(
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2       --   リターン・コード    --# 固定 #
  )
  IS
--
--###########################  固定部 START   ###########################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
    cv_normal     CONSTANT VARCHAR2(20) := '正常データの';  -- メッセージ
    cv_warning    CONSTANT VARCHAR2(20) := '警告データの';  -- メッセージ
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);   -- 終了メッセージコード

    lv_msgbuf  VARCHAR2(5000);  -- エラー・メッセージ
--
--#####################################  固定部 END   #############################################
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
    -- ======================
    -- エラー・メッセージ出力
    -- ======================
    IF (lv_retcode = cv_status_error) THEN
      --エラー出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff => lv_errbuf --エラーメッセージ
      );
      --空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      --異常エラー時は、成功件数０件、スキップ件数０件、エラー件数１件と固定表示
      gn_normal_cnt := 0;
      gn_warn_cnt := 0;
      gn_error_cnt := 1;
      gn_skip_cnt := 0;
    ELSE
      IF (gn_normal_cnt > 0) THEN
      -- ログ出力処理(成功データ出力)
        disp_report(
          cv_status_normal
         ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
         ,lv_retcode  -- リターン・コード             --# 固定 #
         ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
        );
--
        IF (lv_retcode = cv_status_error) THEN
          gv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name
                       ,iv_name         => cv_log_err_msg
                       ,iv_token_name1  => cv_tkn_ng_word
                       ,iv_token_value1 => cv_normal    -- '正常データの'
                      );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg
          );
          lv_retcode := cv_status_normal;
        END IF;
      END IF;
--
    -- ログ出力・処理結果出力 処理(警告データ出力：未更新)
      IF (gn_warn_cnt > 0) THEN
        disp_report(
          cv_status_warn
         ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
         ,lv_retcode  -- リターン・コード             --# 固定 #
         ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
        );
--
        IF (lv_retcode = cv_status_error) THEN
          gv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name
                       ,iv_name         => cv_log_err_msg
                       ,iv_token_name1  => cv_tkn_ng_word
                       ,iv_token_value1 => cv_warning    -- '警告データの'
                      );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg
          );
        END IF;
        -- ワーニングデータがある場合は、正常データ有ってもワーニング終了する。
        lv_retcode := cv_status_warn;
      END IF;
      --警告件数をエラー件数として設定
      gn_error_cnt := gn_warn_cnt;
    END IF;
--
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_common_short_name
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
                  iv_application  => cv_common_short_name
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
                  iv_application  => cv_common_short_name
                 ,iv_name         => cv_error_rec_msg
                 ,iv_token_name1  => cv_cnt_token
                 ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_common_short_name
                 ,iv_name         => cv_skip_rec_msg
                 ,iv_token_name1  => cv_cnt_token
                 ,iv_token_value1 => TO_CHAR(gn_skip_cnt)
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
                  iv_application  => cv_common_short_name
                 ,iv_name         => lv_message_code
                );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );

    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合・正常件数０件の場合はROLLBACKする
    IF (retcode = cv_status_error)
    OR (gn_normal_cnt = 0) THEN
      ROLLBACK;
    END IF;

    -- ===============================
    -- CSVファイル削除処理
    -- ===============================
    IF (retcode = cv_status_normal) THEN
      UTL_FILE.FREMOVE(gv_directory,   -- 出力先
                       gv_file_name    -- CSVファイル名
      );
    END IF;

    -- ===============================
    -- 職責自動割当ワーク削除処理
    -- ===============================
    DELETE xxcmm.xxcmm_wk_people_resp;

    -- ===============================
    -- 社員インタフェース削除処理
    -- ===============================
    DELETE xxcmm_in_people_if;
--
    COMMIT;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
--      UTL_FILE.FREMOVE(gv_directory,   -- 出力先
--                       gv_file_name    -- CSVファイル名
--      );
      DELETE xxcmm_in_people_if;
      DELETE xxcmm_wk_people_resp;
      COMMIT;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
--      UTL_FILE.FREMOVE(gv_directory,   -- 出力先
--                       gv_file_name    -- CSVファイル名
--      );
      DELETE xxcmm_in_people_if;
      DELETE xxcmm_wk_people_resp;
      COMMIT;
  END main;
--
--#####################################  固定部 END   #############################################
--
END XXCMM002A01C;
/
