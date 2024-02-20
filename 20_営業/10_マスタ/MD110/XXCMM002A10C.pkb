CREATE OR REPLACE PACKAGE BODY APPS.XXCMM002A10C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 *
 * Package Name     : XXCMM002A10C (body)
 * Description      : 社員データIF抽出_EBSコンカレント
 * MD.050           : T_MD050_CMM_002_A10_社員データIF抽出_EBSコンカレント
 * Version          : 1.21
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  nvl_for_hdl            HDL用NVL
 *  init                   初期処理(A-1)
 *  output_worker          従業員情報の抽出・ファイル出力処理(A-2)
 *  output_user            ユーザー情報の抽出・ファイル出力処理(A-3)
 *  output_worker2         従業員情報（上長・新規採用退職者）の抽出・ファイル出力処理(A-4)
 *  output_emp_bank_acct   従業員経費口座情報の抽出・ファイル出力処理(A-5)
 *  output_emp_info        社員差分情報の抽出・ファイル出力処理（PaaS処理用）(A-6)
 *  update_mng_tbl         管理テーブル登録・更新処理(A-7)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2023-01-12    1.0   Y.Ooyama         新規作成
 *  2023-01-16    1.1   Y.Ooyama         E054
 *  2023-01-23    1.2   Y.Ooyama         E055, E056
 *  2023-01-29    1.3   Y.Ooyama         外部結合テスト不具合対応（No.0010）
 *  2023-01-30    1.4   F.Hasebe         外部結合テスト不具合対応（No.0012）
 *  2023-01-31    1.5   Y.Ooyama         外部結合テスト不具合対応（No.0013）
 *  2023-01-31    1.6   Y.Ooyama         外部結合テスト不具合対応（No.0014）
 *  2023-02-16    1.7   Y.Ooyama         開発残課題No.12（外部結合テスト不具合No.0006）
 *  2023-02-27    1.8   Y.Ooyama         シナリオテスト不具合No.0035
 *  2023-03-02    1.9   Y.Ooyama         シナリオテスト不具合No.0053
 *  2023-03-03    1.10  Y.Ooyama         シナリオテスト不具合No.0057
 *  2023-03-06    1.11  Y.Ooyama         シナリオテスト不具合No.0028
 *  2023-03-15    1.12  Y.Ooyama         シナリオテスト不具合No.0085
 *  2023-03-22    1.13  Y.Ooyama         シナリオテスト不具合No.0093
 *  2023-04-18    1.14  T.Mizutani       PTテスト不具合No.0009
 *  2023-05-22    1.15  F.Hasebe         システム統合テストNo.5修正対応
 *  2023-06-05    1.16  F.Hasebe         内部ToDoNo.50修正対応
 *  2023-07-11    1.17  F.Hasebe         E_本稼働_19324対応
 *  2023-07-06    1.18  F.Hasebe         E_本稼働_19314対応
 *  2023-09-21    1.19  Y.Koh            E_本稼動_19311【マスタ】ERP銀行口座 対応
 *  2023-12-22    1.20  K.Sudo           E_本稼働_19379【マスタ】新規従業員判別フラグの初期化対応
 *  2024-01-30    1.21  K.Sudo           E_本稼動_19791【マスタ】経費口座紐づけ（ERP)
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
  -- ロックエラー例外
  global_lock_expt          EXCEPTION;
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
  -- ファイル出力時例外
  global_fileout_expt       EXCEPTION;
  PRAGMA EXCEPTION_INIT(global_fileout_expt, -20010);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCMM002A10C'; -- パッケージ名
--
  -- アプリケーション短縮名
  cv_appl_xxcmm             CONSTANT VARCHAR2(5)   := 'XXCMM';              -- アドオン：マスタ・マスタ領域
  cv_appl_xxccp             CONSTANT VARCHAR2(5)   := 'XXCCP';              -- アドオン：共通・IF領域
  cv_appl_xxcoi             CONSTANT VARCHAR2(5)   := 'XXCOI';              -- アドオン：在庫領域
--
  -- 日付書式
  cv_datetime_fmt           CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS';
  cv_date_fmt               CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
--
  -- 固定文字
  cv_slash                  CONSTANT VARCHAR2(1)   := '/';
  cv_comma                  CONSTANT VARCHAR2(1)   := ',';
  cv_pipe                   CONSTANT VARCHAR2(1)   := '|';
  cv_space                  CONSTANT VARCHAR2(1)   := ' ';
  cv_hyphen                 CONSTANT VARCHAR2(1)   := '-';
--
  cv_open_mode_w            CONSTANT VARCHAR2(1)   := 'W';                  -- 書き込みモード
  cn_max_linesize           CONSTANT BINARY_INTEGER := 32767;               -- ファイルサイズ
--
  cv_emp_kbn_internal       CONSTANT VARCHAR2(1)   := '1';                  -- 従業員区分：1(内部)
  cv_emp_kbn_external       CONSTANT VARCHAR2(1)   := '2';                  -- 従業員区分：2(外部)
  cv_emp_kbn_dummy          CONSTANT VARCHAR2(1)   := '4';                  -- 従業員区分：4(ダミー)
  cv_vd_type_employee       CONSTANT VARCHAR2(8)   := 'EMPLOYEE';
  cv_wk_terms_suffix        CONSTANT VARCHAR2(2)   := 'WT';
  cv_wt                     CONSTANT VARCHAR2(2)   := 'WT';
  cv_itoen_email_suffix     CONSTANT VARCHAR2(3)   := 'ing';
  cv_itoen_email_domain     CONSTANT VARCHAR2(12)  := '@itoen.co.jp';
  cv_y                      CONSTANT VARCHAR2(1)   := 'Y';
  cv_n                      CONSTANT VARCHAR2(1)   := 'N';
  cv_act_cd_termination     CONSTANT VARCHAR2(11)  := 'TERMINATION';
  cv_act_cd_hire            CONSTANT VARCHAR2(4)   := 'HIRE';
  cv_act_cd_rehire          CONSTANT VARCHAR2(6)   := 'REHIRE';
  cv_act_cd_mng_chg         CONSTANT VARCHAR2(14)  := 'MANAGER_CHANGE';
  cv_meta_merge             CONSTANT VARCHAR2(5)   := 'MERGE';
  cv_meta_delete            CONSTANT VARCHAR2(6)   := 'DELETE';
  cv_ebs                    CONSTANT VARCHAR2(3)   := 'EBS';
  cv_jp                     CONSTANT VARCHAR2(2)   := 'JP';
  cv_global                 CONSTANT VARCHAR2(6)   := 'GLOBAL';
  cv_w1                     CONSTANT VARCHAR2(2)   := 'W1';
  cv_sales_le               CONSTANT VARCHAR2(8)   := 'SALES-LE';
  cv_sales_bu               CONSTANT VARCHAR2(8)   := 'SALES-BU';
  cv_wk_type_e              CONSTANT VARCHAR2(1)   := 'E';
  cv_sys_per_type_emp       CONSTANT VARCHAR2(3)   := 'EMP';
  cv_ass_type_et            CONSTANT VARCHAR2(2)   := 'ET';
  cv_per_type_employee      CONSTANT VARCHAR2(8)   := 'Employee';
  cv_seq_1                  CONSTANT VARCHAR2(1)   := '1';
  cv_ass_status_act         CONSTANT VARCHAR2(14)  := 'ACTIVE_PROCESS';
  cv_sup_type_line_manager  CONSTANT VARCHAR2(12)  := 'LINE_MANAGER';
  cv_proc_type_dept         CONSTANT VARCHAR2(1)   := '2';                  -- 処理区分：2(部門)
  cv_acct_type_sup          CONSTANT VARCHAR2(8)   := 'SUPPLIER';
-- Ver1.1 Add Start
  cv_yen                    CONSTANT VARCHAR2(3)  := 'JPY';
-- Ver1.1 Add End
--
  cv_cls_worker             CONSTANT VARCHAR2(6)   := 'Worker';
  cv_cls_per_name           CONSTANT VARCHAR2(10)  := 'PersonName';
  cv_cls_per_legi           CONSTANT VARCHAR2(21)  := 'PersonLegislativeData';
  cv_cls_per_email          CONSTANT VARCHAR2(11)  := 'PersonEmail';
  cv_cls_wk_rel             CONSTANT VARCHAR2(16)  := 'WorkRelationship';
  cv_cls_per_user           CONSTANT VARCHAR2(21)  := 'PersonUserInformation';
  cv_cls_wk_terms           CONSTANT VARCHAR2(9)   := 'WorkTerms';
  cv_cls_user               CONSTANT VARCHAR2(4)   := 'User';
  cv_cls_assignment         CONSTANT VARCHAR2(10)  := 'Assignment';
  cv_cls_ass_super          CONSTANT VARCHAR2(20)  := 'AssignmentSupervisor';
  cv_per_persons_dff        CONSTANT VARCHAR2(20)  := 'ITO_SALES_USE_ITEM';
  cv_per_asg_df             CONSTANT VARCHAR2(20)  := 'ITO_SALES_USE_ITEM';
--
  -- 抽出対象外従業員番号
  cv_not_get_emp1           CONSTANT VARCHAR2(10)  := '99983';
  cv_not_get_emp2           CONSTANT VARCHAR2(10)  := '99984';
  cv_not_get_emp3           CONSTANT VARCHAR2(10)  := '99985';
  cv_not_get_emp4           CONSTANT VARCHAR2(10)  := '99989';
  cv_not_get_emp5           CONSTANT VARCHAR2(10)  := '99997';
  cv_not_get_emp6           CONSTANT VARCHAR2(10)  := '99998';
  cv_not_get_emp7           CONSTANT VARCHAR2(10)  := '99999';
  cv_not_get_emp8           CONSTANT VARCHAR2(10)  := 'XXSCV_2';
--
  -- データタイプ別NVL変換値
  cv_nvl_v                  CONSTANT VARCHAR2(5)   := '#NULL';
  cv_nvl_d                  CONSTANT VARCHAR2(10)  := '4712/01/01';
  cv_nvl_n                  CONSTANT VARCHAR2(10)  := '-999999991';
--
  -- プロファイル
  -- XXCMM:OIC連携データファイル格納ディレクトリ名
  cv_prf_out_file_dir       CONSTANT VARCHAR2(30)  := 'XXCMM1_OIC_OUT_FILE_DIR';
  -- XXCMM:従業員情報連携データファイル名（OIC連携）
  cv_prf_wrk_out_file       CONSTANT VARCHAR2(30)  := 'XXCMM1_002A10_W_OUT_FILE_FIL';
  -- XXCMM:従業員情報（上長・新規採用退職者）連携データファイル名（OIC連携）
  cv_prf_wrk2_out_file      CONSTANT VARCHAR2(30)  := 'XXCMM1_002A10_W2_OUT_FILE_FIL';
  -- XXCMM:ユーザー情報連携データファイル名（OIC連携）
  cv_prf_usr_out_file       CONSTANT VARCHAR2(30)  := 'XXCMM1_002A10_U_OUT_FILE_FIL';
-- Ver1.2(E055) Add Start
  -- XXCMM:ユーザー情報（削除）連携データファイル名（OIC連携）
  cv_prf_usr2_out_file      CONSTANT VARCHAR2(30)  := 'XXCMM1_002A10_U2_OUT_FILE_FIL';
-- Ver1.2(E055) Add End
  -- XXCMM:PaaS処理用の新規ユーザー情報ファイル名（OIC連携）
  cv_prf_new_usr_out_file   CONSTANT VARCHAR2(30)  := 'XXCMM1_002A10_NU_OUT_FILE_FIL';
  -- XXCMM:PaaS処理用の従業員経費口座情報ファイル名（OIC連携）
  cv_prf_emp_bnk_out_file   CONSTANT VARCHAR2(30)  := 'XXCMM1_002A10_EBA_OUT_FILE_FIL';
  -- XXCMM:PaaS処理用の社員差分情報ファイル名（OIC連携）
  cv_prf_emp_inf_out_file   CONSTANT VARCHAR2(30)  := 'XXCMM1_002A10_EDI_OUT_FILE_FIL';
  -- XXCMM:社員データIF初回検索基準日時（OIC連携）
  cv_prf_1st_srch_date      CONSTANT VARCHAR2(30)  := 'XXCMM1_002A10_1ST_SC_DATE';
-- Ver1.15 Del Start
--  -- XXCMM:ERP_Cloud初期パスワード（OIC連携）
--  cv_prf_password           CONSTANT VARCHAR2(30)  := 'XXCMM1_002A10_PASSWORD';
-- Ver1.15 Del End
  -- XXCMM:デフォルト費用勘定の勘定科目（OIC連携）
  cv_prf_def_account_cd     CONSTANT VARCHAR2(30)  := 'XXCMM1_002A10_DEF_ACCOUNT_CD';
  -- XXCMM:デフォルト費用勘定の補助科目（OIC連携）
  cv_prf_def_sub_acct_cd    CONSTANT VARCHAR2(30)  := 'XXCMM1_002A10_DEF_SUB_ACCT_CD';
-- Ver1.17 Add Start
  -- XXCMM:PaaS処理用の新入社員情報ファイル名（OIC連携）
  cv_prf_new_emp_out_file   CONSTANT VARCHAR2(30)  := 'XXCMM1_002A10_NE_OUT_FILE_FIL';
-- Ver1.17 Add End
--
  -- メッセージ名
  cv_input_param_msg        CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60001';       -- パラメータ出力メッセージ
  cv_prof_get_err_msg       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00002';       -- プロファイル取得エラーメッセージ
  cv_dir_path_get_err_msg   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-00029';       -- ディレクトリフルパス取得エラーメッセージ
  cv_to_date_err_msg        CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60029';       -- 日付型変換エラーメッセージ
  cv_if_file_name_msg       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60003';       -- IFファイル名出力メッセージ
  cv_file_exist_err_msg     CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60004';       -- 同一ファイル存在エラーメッセージ
  cv_lock_err_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00008';       -- ロックエラーメッセージ
  cv_proc_date_get_err_msg  CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00018';       -- 業務日付取得エラーメッセージ
  cv_process_date_msg       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60005';       -- 処理日時出力メッセージ
  cv_search_trgt_cnt_msg    CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60006';       -- 検索対象・件数メッセージ
  cv_file_open_err_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00487';       -- ファイルオープンエラーメッセージ
  cv_file_write_err_msg     CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00488';       -- ファイル書き込みエラーメッセージ
  cv_file_trgt_cnt_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60007';       -- ファイル出力対象・件数メッセージ
  cv_insert_err_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00054';       -- 挿入エラーメッセージ
  cv_update_err_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00055';       -- 更新エラーメッセージ
  cv_proc_date_msg          CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60050';       -- 業務日付出力メッセージ
  cv_if_date_msg            CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60051';       -- 連携日付出力メッセージ
--
  -- メッセージ名(トークン)
  cv_rec_proc_date_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60030';       -- 業務日付（リカバリ用）
  cv_oic_proc_mng_tbl_msg   CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60008';       -- OIC連携処理管理テーブル
  cv_oic_emp_info_tbl_msg   CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60031';       -- OIC社員差分情報テーブル
  cv_oic_emp_inf_bk_tbl_msg CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60032';       -- OIC社員差分情報バックアップテーブル
  cv_oic_wk_hiera_dept_msg  CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60047';       -- 部門階層ワーク
  cv_worker_msg             CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60033';       -- 就業者
  cv_per_name_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60044';       -- 個人名
  cv_per_legi_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60045';       -- 個人国別仕様データ
  cv_per_email_msg          CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60046';       -- 個人Eメール
  cv_work_relation_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60034';       -- 雇用関係（退職者）
  cv_new_user_info_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60035';       -- ユーザー情報（新規）
  cv_new_user_info_paas_msg CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60049';       -- ユーザー情報（新規）PaaS用
  cv_work_term_msg          CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60036';       -- 雇用条件
  cv_assignment_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60037';       -- アサイメント情報
  cv_user_info_msg          CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60038';       -- ユーザー情報
-- Ver1.2(E055) Add Start
  cv_user2_info_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60052';       -- ユーザー情報（削除）
-- Ver1.2(E055) Add End
  cv_sup_assignment_msg     CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60039';       -- アサイメント情報（上長）
  cv_work_relation_2_msg    CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60040';       -- 雇用関係（新規採用退職者）
  cv_emp_bank_acct_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60041';       -- 従業員経費口座情報
  cv_emp_info_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60042';       -- 社員差分情報
--
  -- トークン名
  cv_tkn_param_name         CONSTANT VARCHAR2(30)  := 'PARAM_NAME';             -- トークン名(PARAM_NAME)
  cv_tkn_param_val          CONSTANT VARCHAR2(30)  := 'PARAM_VAL';              -- トークン名(PARAM_VAL)
  cv_tkn_ng_profile         CONSTANT VARCHAR2(30)  := 'NG_PROFILE';             -- トークン名(NG_PROFILE)
  cv_tkn_dir_tok            CONSTANT VARCHAR2(30)  := 'DIR_TOK';                -- トークン名(DIR_TOK)
  cv_tkn_item               CONSTANT VARCHAR2(30)  := 'ITEM';                   -- トークン名(ITEM)
  cv_tkn_value              CONSTANT VARCHAR2(30)  := 'VALUE';                  -- トークン名(VALUE)
  cv_tkn_format             CONSTANT VARCHAR2(30)  := 'FORMAT';                 -- トークン名(FORMAT)
  cv_tkn_file_name          CONSTANT VARCHAR2(30)  := 'FILE_NAME';              -- トークン名(FILE_NAME)
  cv_tkn_ng_table           CONSTANT VARCHAR2(30)  := 'NG_TABLE';               -- トークン名(NG_TABLE)
  cv_tkn_date1              CONSTANT VARCHAR2(30)  := 'DATE1';                  -- トークン名(DATE1)
  cv_tkn_date2              CONSTANT VARCHAR2(30)  := 'DATE2';                  -- トークン名(DATE2)
  cv_tkn_date               CONSTANT VARCHAR2(30)  := 'DATE';                   -- トークン名(DATE)
  cv_tkn_target             CONSTANT VARCHAR2(30)  := 'TARGET';                 -- トークン名(TARGET)
  cv_tkn_count              CONSTANT VARCHAR2(30)  := 'COUNT';                  -- トークン名(COUNT)
  cv_tkn_table              CONSTANT VARCHAR2(30)  := 'TABLE';                  -- トークン名(TABLE)
  cv_tkn_err_msg            CONSTANT VARCHAR2(30)  := 'ERR_MSG';                -- トークン名(ERR_MSG)
  cv_tkn_sqlerrm            CONSTANT VARCHAR2(30)  := 'SQLERRM';                -- トークン名(SQLERRM)
-- Ver1.2(E056) Add Start
  cv_site_code_comp         CONSTANT VARCHAR2(10)  := '会社';
-- Ver1.2(E056) Add End
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- プロファイル値
  -- XXCMM:OIC連携データファイル格納ディレクトリ名
  gt_prf_val_out_file_dir       fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCMM:従業員情報連携データファイル名（OIC連携）
  gt_prf_val_wrk_out_file       fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCMM:従業員情報（上長・新規採用退職者）連携データファイル名（OIC連携）
  gt_prf_val_wrk2_out_file      fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCMM:ユーザー情報連携データファイル名（OIC連携）
  gt_prf_val_usr_out_file       fnd_profile_option_values.profile_option_value%TYPE;
-- Ver1.2(E055) Add Start
  -- XXCMM:ユーザー情報（削除）連携データファイル名（OIC連携）
  gt_prf_val_usr2_out_file      fnd_profile_option_values.profile_option_value%TYPE;
-- Ver1.2(E055) Add End
  -- XXCMM:PaaS処理用の新規ユーザー情報ファイル名（OIC連携）
  gt_prf_val_new_usr_out_file   fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCMM:PaaS処理用の従業員経費口座情報ファイル名（OIC連携）
  gt_prf_val_emp_bnk_out_file   fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCMM:PaaS処理用の社員差分情報ファイル名（OIC連携）
  gt_prf_val_emp_inf_out_file   fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCMM:社員データIF初回検索基準日時（OIC連携）
  gt_prf_val_1st_srch_date      fnd_profile_option_values.profile_option_value%TYPE;
-- Ver1.15 Del Start
--  -- XXCMM:ERP_Cloud初期パスワード（OIC連携）
--  gt_prf_val_password           fnd_profile_option_values.profile_option_value%TYPE;
-- Ver1.15 Del End
  -- XXCMM:デフォルト費用勘定の勘定科目（OIC連携）
  gt_prf_val_def_account_cd     fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCMM:デフォルト費用勘定の補助科目（OIC連携）
  gt_prf_val_def_sub_acct_cd    fnd_profile_option_values.profile_option_value%TYPE;
-- Ver1.17 Add Start
  -- XXCMM:PaaS処理用の新入社員情報ファイル名（OIC連携）
  gt_prf_val_new_emp_out_file   fnd_profile_option_values.profile_option_value%TYPE;
-- Ver1.17 Add End
--
  -- OIC連携処理管理テーブルの登録・更新データ
  gt_conc_program_name          fnd_concurrent_programs.concurrent_program_name%TYPE;    -- コンカレントプログラム名
  gt_pre_process_date           xxccp_oic_if_process_mng.pre_process_date%TYPE;          -- 前回処理日時
  gv_first_proc_flag            VARCHAR2(1);                                             -- 初回処理フラグ(Y/N)
  gt_cur_process_date           xxccp_oic_if_process_mng.pre_process_date%TYPE;          -- 今回処理日時
--
  gt_if_dest_date               DATE;                                                    -- 連携日付
  gv_str_pre_process_date       VARCHAR2(19);                                            -- 前回処理日時（文字列）
-- Ver1.18 Add Start
  gv_str_cur_process_date       VARCHAR2(19);                                            -- 今回処理日時（文字列）
-- Ver1.18 Add End
--
  -- ファイルハンドル
  gf_wrk_file_handle            UTL_FILE.FILE_TYPE;         -- 従業員情報連携データファイル
  gf_wrk2_file_handle           UTL_FILE.FILE_TYPE;         -- 従業員情報（上長・新規採用退職者）連携データファイル
  gf_usr_file_handle            UTL_FILE.FILE_TYPE;         -- ユーザー情報連携データファイル
-- Ver1.2(E055) Add Start
  gf_usr2_file_handle           UTL_FILE.FILE_TYPE;         -- ユーザー情報（削除）連携データファイル
-- Ver1.2(E055) Add End
  gf_new_usr_file_handle        UTL_FILE.FILE_TYPE;         -- PaaS処理用の新規ユーザー情報ファイル
  gf_emp_bnk_file_handle        UTL_FILE.FILE_TYPE;         -- PaaS処理用の従業員経費口座情報ファイル
  gf_emp_inf_file_handle        UTL_FILE.FILE_TYPE;         -- PaaS処理用の社員差分情報ファイル
-- Ver1.17 Add Start
  gf_new_emp_file_handle        UTL_FILE.FILE_TYPE;         -- PaaS処理用の新入社員情報ファイル
-- Ver1.17 Add End
--
  -- 個別件数
  -- 抽出件数
  gn_get_wk_cnt                 NUMBER;                     -- 就業者抽出件数
  gn_get_per_name_cnt           NUMBER;                     -- 個人名抽出件数
  gn_get_per_legi_cnt           NUMBER;                     -- 個人国別仕様データ抽出件数
  gn_get_per_email_cnt          NUMBER;                     -- 個人Eメール抽出件数
  gn_get_wk_rel_cnt             NUMBER;                     -- 雇用関係（退職者）抽出件数
  gn_get_new_user_cnt           NUMBER;                     -- ユーザー情報（新規）抽出件数
  gn_get_new_user_paas_cnt      NUMBER;                     -- ユーザー情報（新規）PaaS用抽出件数
  gn_get_wk_terms_cnt           NUMBER;                     -- 雇用条件抽出件数
  gn_get_ass_cnt                NUMBER;                     -- アサイメント情報抽出件数
  gn_get_user_cnt               NUMBER;                     -- ユーザー情報抽出件数
-- Ver1.2(E055) Add Start
  gn_get_user2_cnt              NUMBER;                     -- ユーザー情報（削除）抽出件数
-- Ver1.2(E055) Add End
  gn_get_ass_sup_cnt            NUMBER;                     -- アサイメント情報（上長）抽出件数
  gn_get_wk_rel2_cnt            NUMBER;                     -- 雇用関係（新規採用退職者）抽出件数
  gn_get_bank_acc_cnt           NUMBER;                     -- 従業員経費口座情報抽出件数
  gn_get_emp_info_cnt           NUMBER;                     -- 社員差分情報抽出件数
  -- 出力件数
  gn_out_wk_cnt                 NUMBER;                     -- 従業員情報連携データファイル出力件数
  gn_out_p_new_user_cnt         NUMBER;                     -- PaaS処理用の新規ユーザー情報ファイル出力件数
  gn_out_user_cnt               NUMBER;                     -- ユーザー情報連携データファイル出力件数
-- Ver1.2(E055) Add Start
  gn_out_user2_cnt              NUMBER;                     -- ユーザー情報（削除）連携データファイル出力件数
-- Ver1.2(E055) Add End
  gn_out_wk2_cnt                NUMBER;                     -- 従業員情報（上長・新規採用退職者）連携データファイル出力件数
  gn_out_p_bank_acct_cnt        NUMBER;                     -- PaaS処理用の従業員経費口座情報ファイル出力件数
  gn_out_p_emp_info_cnt         NUMBER;                     -- PaaS処理用の社員差分情報ファイル出力件数
-- Ver1.17 Add Start
  gn_out_p_new_emp_cnt          NUMBER;                     -- PaaS処理用の新入社員情報ファイル出力件数
-- Ver1.17 Add End
--  
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
--
--
  /**********************************************************************************
   * Function Name    : nvl_for_hdl
   * Description      : HDL用NVL
   ***********************************************************************************/
  FUNCTION nvl_for_hdl(
              iv_string          IN VARCHAR2,     -- 対象文字列
              iv_new_reg_flag    IN VARCHAR2,     -- 新規登録フラグ
              iv_nvl_string      IN VARCHAR2      -- NVL変換値
           )
    RETURN VARCHAR2
  IS
  --
    -- *** ローカル定数 ***
    cv_prg_name         CONSTANT VARCHAR2(100) := 'nvl_for_hdl';
--
    -- *** ローカル変数 ***
  --
  BEGIN
--
    IF ( iv_new_reg_flag = cv_n ) THEN
      -- 新規登録でない（更新）の場合
      IF ( iv_string IS NULL) THEN
        -- 対象文字列がNULLの場合、NVL変換値を返却
        RETURN iv_nvl_string;
      END IF;
    END IF;
--
    RETURN iv_string;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END nvl_for_hdl;
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_proc_date_for_recovery  IN  VARCHAR2,     --   業務日付（リカバリ用）
    ov_errbuf                  OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode                 OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg                  OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_msg               VARCHAR2(3000);
    lt_dir_path          all_directories.directory_path%TYPE;    -- ディレクトリパス
    ld_1st_srch_date     DATE;                                   -- 社員データIF初回検索基準日時
    lb_fexists           BOOLEAN;                                -- ファイルが存在するかどうか
    ln_file_length       NUMBER;                                 -- ファイル長
    ln_block_size        NUMBER;                                 -- ブロックサイズ
    ld_process_date      DATE;                                   -- 業務日付（DB）
    ln_prf_idx           NUMBER;                                 -- プロファイル用インデックス
    ln_file_name_idx     NUMBER;                                 -- ファイル名用インデックス
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    -- プロファイル用レコード
    TYPE l_prf_rtype IS RECORD
    (
      prf_name           VARCHAR2(30)
    , prf_value          fnd_profile_option_values.profile_option_value%TYPE
    );
    -- プロファイル用テーブル
    TYPE l_prf_ttype IS TABLE OF l_prf_rtype INDEX BY BINARY_INTEGER;
    l_prf_tab    l_prf_ttype;
--
    -- ファイル名用テーブル
    TYPE l_file_name_ttype IS TABLE OF fnd_profile_option_values.profile_option_value%TYPE INDEX BY BINARY_INTEGER;
    l_file_name_tab      l_file_name_ttype;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ==============================================================
    -- 1.入力パラメータの出力
    -- ==============================================================
    -- 入力パラメータ名：業務日付（リカバリ用）
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_appl_xxcmm             -- アプリケーション短縮名：XXCMM
              , iv_name         => cv_input_param_msg        -- メッセージ名：パラメータ出力メッセージ
              , iv_token_name1  => cv_tkn_param_name         -- トークン名1：PARAM_NAME
              , iv_token_value1 => cv_rec_proc_date_msg      -- トークン値1：業務日付（リカバリ用）
              , iv_token_name2  => cv_tkn_param_val          -- トークン名2：PARAM_VAL
              , iv_token_value2 => iv_proc_date_for_recovery -- トークン値2：パラメータ値
              );
    --
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => lv_msg
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => ''
    );
    --
    -- パラメータ出力メッセージをログ(LOG)にも出力
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
    , buff   => lv_msg
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
    , buff   => ''
    );
    --
    -- ==============================================================
    -- 2.プロファイル値の取得
    -- ==============================================================
    ln_prf_idx := 0;
    --
    -- 1.XXCMM:OIC連携データファイル格納ディレクトリ名
    gt_prf_val_out_file_dir := FND_PROFILE.VALUE( cv_prf_out_file_dir );
    -- プロファイル用テーブルに設定
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_out_file_dir;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_out_file_dir;
    --
    -- 2.XXCMM:従業員情報連携データファイル名（OIC連携）
    gt_prf_val_wrk_out_file := FND_PROFILE.VALUE( cv_prf_wrk_out_file );
    -- プロファイル用テーブルに設定
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_wrk_out_file;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_wrk_out_file;
    --
    -- 3.XXCMM:従業員情報（上長・新規採用退職者）連携データファイル名（OIC連携）
    gt_prf_val_wrk2_out_file := FND_PROFILE.VALUE( cv_prf_wrk2_out_file );
    -- プロファイル用テーブルに設定
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_wrk2_out_file;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_wrk2_out_file;
    --
    -- 4.XXCMM:ユーザー情報連携データファイル名（OIC連携）
    gt_prf_val_usr_out_file := FND_PROFILE.VALUE( cv_prf_usr_out_file );
    -- プロファイル用テーブルに設定
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_usr_out_file;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_usr_out_file;
-- Ver1.2(E055) Add Start
    --
    -- 5.XXCMM:ユーザー情報（削除）連携データファイル名（OIC連携）
    gt_prf_val_usr2_out_file := FND_PROFILE.VALUE( cv_prf_usr2_out_file );
    -- プロファイル用テーブルに設定
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_usr2_out_file;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_usr2_out_file;
-- Ver1.2(E055) Add End
    --
    -- 6.XXCMM:PaaS処理用の新規ユーザー情報ファイル名（OIC連携）
    gt_prf_val_new_usr_out_file := FND_PROFILE.VALUE( cv_prf_new_usr_out_file );
    -- プロファイル用テーブルに設定
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_new_usr_out_file;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_new_usr_out_file;
    --
    -- 7.XXCMM:PaaS処理用の従業員経費口座情報ファイル名（OIC連携）
    gt_prf_val_emp_bnk_out_file := FND_PROFILE.VALUE( cv_prf_emp_bnk_out_file );
    -- プロファイル用テーブルに設定
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_emp_bnk_out_file;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_emp_bnk_out_file;
    --
    -- 8.XXCMM:PaaS処理用の社員差分情報ファイル名（OIC連携）
    gt_prf_val_emp_inf_out_file := FND_PROFILE.VALUE( cv_prf_emp_inf_out_file );
    -- プロファイル用テーブルに設定
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_emp_inf_out_file;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_emp_inf_out_file;
    --
    -- 9.XXCMM:社員データIF初回検索基準日時（OIC連携）
    gt_prf_val_1st_srch_date := FND_PROFILE.VALUE( cv_prf_1st_srch_date );
    -- プロファイル用テーブルに設定
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_1st_srch_date;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_1st_srch_date;
    --
-- Ver1.15 Del Start
--    -- 10.XXCMM:ERP_Cloud初期パスワード（OIC連携）
--    gt_prf_val_password := FND_PROFILE.VALUE( cv_prf_password );
--    -- プロファイル用テーブルに設定
--    ln_prf_idx := ln_prf_idx + 1;
--    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_password;
--    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_password;
--    --
-- Ver1.15 Del End
    -- 11.XXCMM:デフォルト費用勘定の勘定科目（OIC連携）
    gt_prf_val_def_account_cd := FND_PROFILE.VALUE( cv_prf_def_account_cd );
    -- プロファイル用テーブルに設定
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_def_account_cd;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_def_account_cd;
    --
    -- 12.XXCMM:デフォルト費用勘定の補助科目（OIC連携）
    gt_prf_val_def_sub_acct_cd := FND_PROFILE.VALUE( cv_prf_def_sub_acct_cd );
    -- プロファイル用テーブルに設定
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_def_sub_acct_cd;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_def_sub_acct_cd;
    --
-- Ver1.17 Add Start
    -- 13.XXCMM:PaaS処理用の新入社員情報ファイル名（OIC連携）
    gt_prf_val_new_emp_out_file := FND_PROFILE.VALUE( cv_prf_new_emp_out_file );
    -- プロファイル用テーブルに設定
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_new_emp_out_file;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_new_emp_out_file;
    --
-- Ver1.17 Add End
    -- プロファイル値チェック
    <<prf_chk_loop>>
    FOR i IN 1..l_prf_tab.COUNT LOOP
      -- プロファイル値がNULLの場合
      IF ( l_prf_tab(i).prf_value IS NULL ) THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_xxcmm              -- アプリケーション短縮名：XXCMM
                      , iv_name         => cv_prof_get_err_msg        -- メッセージ名：プロファイル取得エラーメッセージ
                      , iv_token_name1  => cv_tkn_ng_profile          -- トークン名1：NG_PROFILE
                      , iv_token_value1 => l_prf_tab(i).prf_name      -- トークン値1：プロファイル
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
      END IF;
    END LOOP prf_chk_loop;
--
    -- ==============================================================
    -- 3.ディレクトリパス取得
    -- ==============================================================
    BEGIN
      SELECT
          RTRIM( ad.directory_path , cv_slash )   AS  directory_path        -- ディレクトリパス
      INTO
          lt_dir_path
      FROM
          all_directories  ad     -- ディレクトリ情報
      WHERE
          ad.directory_name = gt_prf_val_out_file_dir
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errbuf :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_xxcoi             -- アプリケーション短縮名：XXCOI
                      , iv_name         => cv_dir_path_get_err_msg   -- メッセージ名：ディレクトリフルパス取得エラーメッセージ
                      , iv_token_name1  => cv_tkn_dir_tok            -- トークン名1：DIR_TOK
                      , iv_token_value1 => gt_prf_val_out_file_dir   -- トークン値1：ディレクトリ名
                      );
        --
        lv_errmsg :=  lv_errbuf;
        RAISE  global_process_expt;
    END;
--
    -- ==============================================================
    -- 4.プロファイル値「社員データIF初回検索基準日時」の日付型変換
    -- ==============================================================
    BEGIN
      ld_1st_srch_date := TO_DATE( gt_prf_val_1st_srch_date , cv_datetime_fmt );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_xxcmm             -- アプリケーション短縮名：XXCMM
                      , iv_name         => cv_to_date_err_msg        -- メッセージ名：日付型変換エラーメッセージ
                      , iv_token_name1  => cv_tkn_item               -- トークン名1：ITEM
                      , iv_token_value1 => cv_prf_1st_srch_date      -- トークン値1：プロファイル名
                      , iv_token_name2  => cv_tkn_value              -- トークン名2：VALUE
                      , iv_token_value2 => gt_prf_val_1st_srch_date  -- トークン値2：プロファイル値
                      , iv_token_name3  => cv_tkn_format             -- トークン名3：FORMAT
                      , iv_token_value3 => cv_datetime_fmt           -- トークン値3：変換書式
                      );
        --
        lv_errmsg :=  lv_errbuf;
        RAISE  global_process_expt;
    END;
--
    -- ==============================================================
    -- 5.IFファイル名の出力
    -- ==============================================================
    ln_file_name_idx := 0;
    --
    -- 従業員情報連携データファイル名
    ln_file_name_idx := ln_file_name_idx + 1;
    l_file_name_tab(ln_file_name_idx) := gt_prf_val_wrk_out_file;
    --
    -- 従業員情報（上長・新規採用退職者）連携データファイル名
    ln_file_name_idx := ln_file_name_idx + 1;
    l_file_name_tab(ln_file_name_idx) := gt_prf_val_wrk2_out_file;
    --
    -- ユーザー情報連携データファイル名
    ln_file_name_idx := ln_file_name_idx + 1;
    l_file_name_tab(ln_file_name_idx) := gt_prf_val_usr_out_file;
-- Ver1.2(E055) Add Start
    --
    -- ユーザー情報（削除）連携データファイル名
    ln_file_name_idx := ln_file_name_idx + 1;
    l_file_name_tab(ln_file_name_idx) := gt_prf_val_usr2_out_file;
-- Ver1.2(E055) Add End
    --
    -- PaaS処理用の新規ユーザー情報ファイル名
    ln_file_name_idx := ln_file_name_idx + 1;
    l_file_name_tab(ln_file_name_idx) := gt_prf_val_new_usr_out_file;
    --
    -- PaaS処理用の従業員経費口座情報ファイル名
    ln_file_name_idx := ln_file_name_idx + 1;
    l_file_name_tab(ln_file_name_idx) := gt_prf_val_emp_bnk_out_file;
    --
    -- PaaS処理用の社員差分情報ファイル名
    ln_file_name_idx := ln_file_name_idx + 1;
    l_file_name_tab(ln_file_name_idx) := gt_prf_val_emp_inf_out_file;
    --
-- Ver1.17 Add Start
    -- PaaS処理用の新入社員情報ファイル名
    ln_file_name_idx := ln_file_name_idx + 1;
    l_file_name_tab(ln_file_name_idx) := gt_prf_val_new_emp_out_file;
    --
-- Ver1.17 Add End
    <<file_name_out_loop>>
    FOR i IN 1..l_file_name_tab.COUNT LOOP
      --
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appl_xxcmm             -- アプリケーション短縮名：XXCMM
                , iv_name         => cv_if_file_name_msg       -- メッセージ名：IFファイル名出力メッセージ
                , iv_token_name1  => cv_tkn_file_name          -- トークン名1：FILE_NAME
                , iv_token_value1 => lt_dir_path
                                       || cv_slash
                                       || l_file_name_tab(i)   -- トークン値1：ディレクトリパス＋ファイル名
                );
      --
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msg
      );
    END LOOP file_name_out_loop;
    --
    -- 空行挿入
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => ''
    );
--
    -- ==============================================================
    -- 6.ファイル存在チェック
    -- ==============================================================
    <<file_exist_chk_loop>>
    FOR i IN 1..l_file_name_tab.COUNT LOOP
      --
      UTL_FILE.FGETATTR(
        location     => gt_prf_val_out_file_dir
      , filename     => l_file_name_tab(i)
      , fexists      => lb_fexists
      , file_length  => ln_file_length
      , block_size   => ln_block_size
      );
      --
      IF ( lb_fexists = TRUE ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application => cv_appl_xxcmm             -- アプリケーション短縮名
                     , iv_name        => cv_file_exist_err_msg     -- メッセージコード
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
    END LOOP file_exist_chk_loop;
--
    -- ==============================================================
    -- 7.コンカレントプログラム名、および前回処理日時の取得
    -- ==============================================================
    SELECT
        fcp.concurrent_program_name                    AS conc_program_name        -- コンカレントプログラム名
      , NVL(xoipm.pre_process_date, ld_1st_srch_date)  AS pre_process_date         -- 前回処理日時
      , (CASE
           WHEN xoipm.pre_process_date IS NOT NULL THEN
             cv_n
           ELSE
             cv_y
         END)                                          AS first_proc_flag          -- 初回処理フラグ
    INTO
        gt_conc_program_name
      , gt_pre_process_date
      , gv_first_proc_flag
    FROM
        fnd_concurrent_programs    fcp       -- コンカレントプログラム
      , xxccp_oic_if_process_mng   xoipm     -- OIC連携処理管理テーブル
    WHERE
        fcp.concurrent_program_id   = cn_program_id
    AND fcp.concurrent_program_name = xoipm.program_name(+)
    FOR UPDATE OF xoipm.pre_process_date NOWAIT
    ;
--
    -- ==============================================================
    -- 8.今回処理日時の取得
    -- ==============================================================
    gt_cur_process_date := SYSDATE;
--
    -- ==============================================================
    -- 9.前回・今回処理日時の出力
    -- ==============================================================
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_appl_xxcmm             -- アプリケーション短縮名：XXCMM
              , iv_name         => cv_process_date_msg       -- メッセージ名：処理日時出力メッセージ
              , iv_token_name1  => cv_tkn_date1              -- トークン名1：DATE1
              , iv_token_value1 => TO_CHAR(
                                     gt_pre_process_date
                                   , cv_datetime_fmt
                                   )                         -- トークン値1：前回処理日時
              , iv_token_name2  => cv_tkn_date2              -- トークン名2：DATE2
              , iv_token_value2 => TO_CHAR(
                                     gt_cur_process_date
                                   , cv_datetime_fmt
                                   )                         -- トークン値2：今回処理日時
              );
    --
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => lv_msg
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => ''
    );
--
    -- ==============================================================
    -- 10.業務日付の取得
    -- ==============================================================
    ld_process_date := xxccp_common_pkg2.get_process_date;
--
    IF ( ld_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm             -- アプリケーション短縮名：XXCMM
                   , iv_name         => cv_proc_date_get_err_msg  -- メッセージ名：業務日付取得エラーメッセージ
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_appl_xxcmm             -- アプリケーション短縮名：XXCMM
              , iv_name         => cv_proc_date_msg          -- メッセージ名：業務日付出力メッセージ
              , iv_token_name1  => cv_tkn_date               -- トークン名1：DATE
              , iv_token_value1 => TO_CHAR(
                                     ld_process_date
                                   , cv_date_fmt
                                   )                         -- トークン値1：業務日付（テーブル）
              );
    --
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => lv_msg
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => ''
    );
--
    -- ==============================================================
    -- 11.連携日付の設定
    -- ==============================================================
    IF ( iv_proc_date_for_recovery IS NOT NULL ) THEN
      gt_if_dest_date := TO_DATE( iv_proc_date_for_recovery , cv_datetime_fmt ) + 1;
    ELSE
      gt_if_dest_date := ld_process_date + 1;
    END IF;
    --
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_appl_xxcmm             -- アプリケーション短縮名：XXCMM
              , iv_name         => cv_if_date_msg            -- メッセージ名：連携日付出力メッセージ
              , iv_token_name1  => cv_tkn_date               -- トークン名1：DATE
              , iv_token_value1 => TO_CHAR(
                                     gt_if_dest_date
                                   , cv_date_fmt
                                   )                         -- トークン値1：連携日付
              );
    --
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => lv_msg
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => ''
    );
--
    -- ==============================================================
    -- 12.前回処理日時（文字列）の設定
    -- （従業員マスタ、アサイメントマスタのDFF検索用）
    -- ==============================================================
    gv_str_pre_process_date := TO_CHAR( gt_pre_process_date , cv_datetime_fmt );
--
    -- ==============================================================
    -- 13.ファイルオープン
    -- ==============================================================
    BEGIN
      -- 従業員情報連携データファイル
      gf_wrk_file_handle      := UTL_FILE.FOPEN(
                                   location     => gt_prf_val_out_file_dir
                                 , filename     => gt_prf_val_wrk_out_file
                                 , open_mode    => cv_open_mode_w
                                 , max_linesize => cn_max_linesize
                                 );
      --
      -- 従業員情報（上長・新規採用退職者）連携データファイル
      gf_wrk2_file_handle     := UTL_FILE.FOPEN(
                                   location     => gt_prf_val_out_file_dir
                                 , filename     => gt_prf_val_wrk2_out_file
                                 , open_mode    => cv_open_mode_w
                                 , max_linesize => cn_max_linesize
                                 );
      --
      -- ユーザー情報連携データファイル
      gf_usr_file_handle      := UTL_FILE.FOPEN(
                                   location     => gt_prf_val_out_file_dir
                                 , filename     => gt_prf_val_usr_out_file
                                 , open_mode    => cv_open_mode_w
                                 , max_linesize => cn_max_linesize
                                 );
-- Ver1.2(E055) Add Start
      --
      -- ユーザー情報（削除）連携データファイル
      gf_usr2_file_handle     := UTL_FILE.FOPEN(
                                   location     => gt_prf_val_out_file_dir
                                 , filename     => gt_prf_val_usr2_out_file
                                 , open_mode    => cv_open_mode_w
                                 , max_linesize => cn_max_linesize
                                 );
-- Ver1.2(E055) Add End
      --
      -- PaaS処理用の新規ユーザー情報ファイル
      gf_new_usr_file_handle  := UTL_FILE.FOPEN(
                                   location     => gt_prf_val_out_file_dir
                                 , filename     => gt_prf_val_new_usr_out_file
                                 , open_mode    => cv_open_mode_w
                                 , max_linesize => cn_max_linesize
                                 );
      --
      -- PaaS処理用の従業員経費口座情報ファイル
      gf_emp_bnk_file_handle  := UTL_FILE.FOPEN(
                                   location     => gt_prf_val_out_file_dir
                                 , filename     => gt_prf_val_emp_bnk_out_file
                                 , open_mode    => cv_open_mode_w
                                 , max_linesize => cn_max_linesize
                                 );
      --
      -- PaaS処理用の社員差分情報ファイル
      gf_emp_inf_file_handle  := UTL_FILE.FOPEN(
                                   location     => gt_prf_val_out_file_dir
                                 , filename     => gt_prf_val_emp_inf_out_file
                                 , open_mode    => cv_open_mode_w
                                 , max_linesize => cn_max_linesize
                                 );
-- Ver1.17 Add Start
      --
      -- PaaS処理用の新入社員情報ファイル
      gf_new_emp_file_handle  := UTL_FILE.FOPEN(
                                   location     => gt_prf_val_out_file_dir
                                 , filename     => gt_prf_val_new_emp_out_file
                                 , open_mode    => cv_open_mode_w
                                 , max_linesize => cn_max_linesize
                                 );
-- Ver1.17 Add End
  EXCEPTION
    WHEN OTHERS THEN
      lv_errmsg := SUBSTRB(
                     xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_xxcmm             -- アプリケーション短縮名：XXCMM
                     , iv_name         => cv_file_open_err_msg      -- メッセージ名：ファイルオープンエラーメッセージ
                     , iv_token_name1  => cv_tkn_sqlerrm            -- トークン名1：SQLERRM
                     , iv_token_value1 => SQLERRM                   -- トークン値1：SQLERRM
                     )
                   , 1
                   , 5000
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END;
--
-- Ver1.18 Add Start
    -- ==============================================================
    -- 14.今回処理日時（文字列）の設定
    -- （従業員マスタ、アサイメントマスタのDFF検索用）
    -- ==============================================================
    gv_str_cur_process_date := TO_CHAR( gt_cur_process_date , cv_datetime_fmt );
--
-- Ver1.18 Add Start
  EXCEPTION
    -- *** ロックエラー例外ハンドラ ***
    WHEN global_lock_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm             -- アプリケーション短縮名：XXCMM
                   , iv_name         => cv_lock_err_msg           -- メッセージ名：ロックエラーメッセージ
                   , iv_token_name1  => cv_tkn_ng_table           -- トークン名1：NG_TABLE
                   , iv_token_value1 => cv_oic_proc_mng_tbl_msg   -- トークン値1：OIC連携処理管理テーブル
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
  END init;
--
--
  /**********************************************************************************
   * Procedure Name   : output_worker
   * Description      : 従業員情報の抽出・ファイル出力処理(A-2)
   ***********************************************************************************/
  PROCEDURE output_worker(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_worker';       -- プログラム名
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
    lv_wt_header_wrk     VARCHAR2(1);
    lv_wt_header_wrk2    VARCHAR2(1);
    lv_ass_header_wrk    VARCHAR2(1);
    lv_ass_header_wrk2   VARCHAR2(1);
--
    ------------------------------------
    --ヘッダー行(Worker)
    ------------------------------------
    cv_worker_header     CONSTANT VARCHAR2(10000) :=
                    'METADATA'                                                     --  1 : METADATA
      || cv_pipe || 'Worker'                                                       --  2 : Worker
      || cv_pipe || 'FLEX:PER_PERSONS_DFF'                                         --  3 : FLEX:PER_PERSONS_DFF（コンテキスト）
      || cv_pipe || 'PersonNumber'                                                 --  4 : PersonNumber（個人番号）
      || cv_pipe || 'EffectiveStartDate'                                           --  5 : EffectiveStartDate（有効開始日）
      || cv_pipe || 'ActionCode'                                                   --  6 : ActionCode（処理コード）
      || cv_pipe || 'StartDate'                                                    --  7 : StartDate（開始日）
                                                                                   --      (↓PER_PERSONS_DFF=ITO_SALES_USE_ITEM)
      || cv_pipe || 'point(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'                    --  8 : point（ポイント)
      || cv_pipe || 'qualificationCode(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'        --  9 : qualificationCode（資格コード)
      || cv_pipe || 'employeeClass(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'            -- 10 : employeeClass（従業員区分)
      || cv_pipe || 'vendorCode(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'               -- 11 : vendorCode（仕入先コード)
      || cv_pipe || 'representativeCarrier(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'    -- 12 : representativeCarrier（運送業者)
      || cv_pipe || 'vendorsSiteCode(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'          -- 13 : vendorsSiteCode（仕入先サイトコード)
      || cv_pipe || 'qualificationCodeNew(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'     -- 14 : qualificationCodeNew（資格コード（新）)
      || cv_pipe || 'qualificationNameNew(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'     -- 15 : qualificationNameNew（資格名（新）)
      || cv_pipe || 'qualificationCodeOld(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'     -- 16 : qualificationCodeOld（資格コード（旧）)
      || cv_pipe || 'qualificationNameOld(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'     -- 17 : qualificationNameOld（資格名（旧）)
      || cv_pipe || 'positionCodeNew(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'          -- 18 : positionCodeNew（職位コード（新）)
      || cv_pipe || 'positionNameNew(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'          -- 19 : positionNameNew（職位名（新）)
      || cv_pipe || 'positionCodeOld(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'          -- 20 : positionCodeOld（職位コード（旧）)
      || cv_pipe || 'positionNameOld(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'          -- 21 : positionNameOld（職位名（旧）)
      || cv_pipe || 'jobCodeNew(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'               -- 22 : jobCodeNew（職務コード（新）)
      || cv_pipe || 'jobNameNew(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'               -- 23 : jobNameNew（職務名（新）)
      || cv_pipe || 'jobCodeOld(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'               -- 24 : jobCodeOld（職務コード（旧）)
      || cv_pipe || 'jobNameOld(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'               -- 25 : jobNameOld（職務名（旧）)
      || cv_pipe || 'occupationalCodeNew(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'      -- 26 : occupationalCodeNew（職種コード（新）)
      || cv_pipe || 'occupationalNameNew(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'      -- 27 : occupationalNameNew（職種名（新）)
      || cv_pipe || 'occupationalCodeOld(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'      -- 28 : occupationalCodeOld（職種コード（旧）)
      || cv_pipe || 'occupationalNameOld(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'      -- 29 : occupationalNameOld（職種名（旧）)
      || cv_pipe || 'DepartmentChild(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'          -- 30 : DepartmentChild（所属部門)
      || cv_pipe || 'referrenceDepartment(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'     -- 31 : referrenceDepartment（照会範囲)
      || cv_pipe || 'approvalDepartment(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'       -- 32 : approvalDepartment（承認者範囲)
      || cv_pipe || 'paymentMethod(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'            -- 33 : paymentMethod（支払方法)
      || cv_pipe || 'inquiryBaseCodeP(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'         -- 34 : inquiryBaseCodeP（問合せ担当拠点コード)
                                                                                   --      (↑PER_PERSONS_DFF=ITO_SALES_USE_ITEM)
      || cv_pipe || 'SourceSystemOwner'                                            -- 35 : SourceSystemOwner（ソース・システム所有者）
      || cv_pipe || 'SourceSystemId'                                               -- 36 : SourceSystemId（ソース・システムID）
    ;
    --
    ------------------------------------
    --ヘッダー行(PersonName)
    ------------------------------------
    cv_per_name_header   CONSTANT VARCHAR2(3000) :=
                    'METADATA'                         --  1 : METADATA
      || cv_pipe || 'PersonName'                       --  2 : PersonName
      || cv_pipe || 'PersonNumber'                     --  3 : PersonNumber（個人番号）
      || cv_pipe || 'NameType'                         --  4 : NameType（名前タイプ）
      || cv_pipe || 'EffectiveStartDate'               --  5 : EffectiveStartDate（有効開始日）
      || cv_pipe || 'LegislationCode'                  --  6 : LegislationCode（国別仕様コード）
      || cv_pipe || 'FirstName'                        --  7 : FirstName（名）
      || cv_pipe || 'LastName'                         --  8 : LastName（姓）
      || cv_pipe || 'NameInformation1'                 --  9 : NameInformation1（名前情報1）
      || cv_pipe || 'NameInformation2'                 -- 10 : NameInformation2（名前情報2）
      || cv_pipe || 'SourceSystemOwner'                -- 11 : SourceSystemOwner（ソース・システム所有者）
      || cv_pipe || 'SourceSystemId'                   -- 12 : SourceSystemId（ソース・システムID）
    ;
    --
    ------------------------------------
    --ヘッダー行(PersonLegislativeData)
    ------------------------------------
    cv_per_legi_header   CONSTANT VARCHAR2(3000) :=
                    'METADATA'                         -- 1 : METADATA
      || cv_pipe || 'PersonLegislativeData'            -- 2 : PersonLegislativeData
      || cv_pipe || 'PersonNumber'                     -- 3 : PersonNumber（個人番号）
      || cv_pipe || 'LegislationCode'                  -- 4 : LegislationCode（国別仕様コード）
      || cv_pipe || 'EffectiveStartDate'               -- 5 : EffectiveStartDate（有効開始日）
      || cv_pipe || 'Sex'                              -- 6 : Sex（性別）
      || cv_pipe || 'SourceSystemOwner'                -- 7 : SourceSystemOwner（ソース・システム所有者）
      || cv_pipe || 'SourceSystemId'                   -- 8 : SourceSystemId（ソース・システムID）
    ;
    --
    ------------------------------------
    --ヘッダー行(PersonEmail)
    ------------------------------------
    cv_per_email_header   CONSTANT VARCHAR2(3000) :=
                    'METADATA'                         -- 1 : METADATA
      || cv_pipe || 'PersonEmail'                      -- 2 : PersonEmail
      || cv_pipe || 'EmailAddress'                     -- 3 : EmailAddress（Eメール・アドレス）
      || cv_pipe || 'EmailType'                        -- 4 : EmailType（Eメール・タイプ）
      || cv_pipe || 'PersonNumber'                     -- 5 : PersonNumber（個人番号）
      || cv_pipe || 'DateFrom'                         -- 6 : DateFrom（日付: 自）
      || cv_pipe || 'SourceSystemOwner'                -- 7 : SourceSystemOwner（ソース・システム所有者）
      || cv_pipe || 'SourceSystemId'                   -- 8 : SourceSystemId（ソース・システムID）
    ;
    --
    ------------------------------------
    --ヘッダー行(WorkRelationship)
    ------------------------------------
    cv_wk_rel_header      CONSTANT VARCHAR2(3000) :=
                    'METADATA'                         --  1 : METADATA
      || cv_pipe || 'WorkRelationship'                 --  2 : WorkRelationship
      || cv_pipe || 'PersonNumber'                     --  3 : PersonNumber（個人番号）
      || cv_pipe || 'WorkerType'                       --  4 : WorkerType（就業者タイプ）
      || cv_pipe || 'DateStart'                        --  5 : DateStart（開始日）
      || cv_pipe || 'LegalEmployerName'                --  6 : LegalEmployerName（雇用主）
      || cv_pipe || 'PrimaryFlag'                      --  7 : PrimaryFlag（プライマリ雇用）
      || cv_pipe || 'ActualTerminationDate'            --  8 : ActualTerminationDate（実績退職日）
      || cv_pipe || 'TerminateWorkRelationshipFlag'    --  9 : TerminateWorkRelationshipFlag（雇用関係の終了）
      || cv_pipe || 'ReverseTerminationFlag'           -- 10 : ReverseTerminationFlag（退職の取消）
      || cv_pipe || 'ActionCode'                       -- 11 : ActionCode（処理コード）
      || cv_pipe || 'SourceSystemOwner'                -- 12 : SourceSystemOwner（ソース・システム所有者）
      || cv_pipe || 'SourceSystemId'                   -- 13 : SourceSystemId（ソース・システムID）
    ;
    --
    ------------------------------------
    --ヘッダー行(PersonUserInformation)
    ------------------------------------
    cv_per_user_header   CONSTANT VARCHAR2(3000) :=
                    'METADATA'                         -- 1 : METADATA
      || cv_pipe || 'PersonUserInformation'            -- 2 : PersonUserInformation
      || cv_pipe || 'UserName'                         -- 3 : UserName（ユーザー名）
      || cv_pipe || 'PersonNumber'                     -- 4 : PersonNumber（個人番号）
      || cv_pipe || 'StartDate'                        -- 5 : StartDate（開始日）
      || cv_pipe || 'GeneratedUserAccountFlag'         -- 6 : GeneratedUserAccountFlag（生成済ユーザー・アカウント）
      || cv_pipe || 'SendCredentialsEmailFlag'         -- 7 : SendCredentialsEmailFlag（資格証明Eメールの送信）
    ;
    --
    ------------------------------------
    --ヘッダー行(WorkTerms)
    ------------------------------------
    cv_wk_terms_header   CONSTANT VARCHAR2(3000) :=
                    'METADATA'                         --  1 : METADATA
      || cv_pipe || 'WorkTerms'                        --  2 : WorkTerms
      || cv_pipe || 'AssignmentNumber'                 --  3 : AssignmentNumber（アサイメント番号）
      || cv_pipe || 'PersonNumber'                     --  4 : PersonNumber（個人番号）
      || cv_pipe || 'WorkerType'                       --  5 : WorkerType（就業者タイプ）
      || cv_pipe || 'DateStart'                        --  6 : DateStart（開始日）
      || cv_pipe || 'LegalEmployerName'                --  7 : LegalEmployerName（雇用主名）
      || cv_pipe || 'EffectiveLatestChange'            --  8 : EffectiveLatestChange（有効最終変更）
      || cv_pipe || 'EffectiveStartDate'               --  9 : EffectiveStartDate（有効開始日）
      || cv_pipe || 'EffectiveSequence'                -- 10 : EffectiveSequence（有効順序）
      || cv_pipe || 'AssignmentStatusTypeCode'         -- 11 : AssignmentStatusTypeCode（アサイメント・ステータス・タイプ）
      || cv_pipe || 'AssignmentType'                   -- 12 : AssignmentType（アサイメント・タイプ）
      || cv_pipe || 'AssignmentName'                   -- 13 : AssignmentName（アサイメント名）
      || cv_pipe || 'SystemPersonType'                 -- 14 : SystemPersonType（システムPersonタイプ）
      || cv_pipe || 'BusinessUnitShortCode'            -- 15 : BusinessUnitShortCode（ビジネス・ユニット）
      || cv_pipe || 'ActionCode'                       -- 16 : ActionCode（処理コード）
      || cv_pipe || 'PrimaryWorkTermsFlag'             -- 17 : PrimaryWorkTermsFlag（雇用関係のプライマリ雇用条件）
      || cv_pipe || 'SourceSystemOwner'                -- 18 : SourceSystemOwner（ソース・システム所有者）
      || cv_pipe || 'SourceSystemId'                   -- 19 : SourceSystemId（ソース・システムID）
    ;
    --
    ------------------------------------
    --ヘッダー行(Assignment)
    ------------------------------------
    cv_ass_header        CONSTANT VARCHAR2(10000) :=
                    'METADATA'                                                --  1 : METADATA
      || cv_pipe || 'Assignment'                                              --  2 : Assignment
      || cv_pipe || 'FLEX:PER_ASG_DF'                                         --  3 : FLEX:PER_ASG_DF（コンテキスト）
      || cv_pipe || 'AssignmentNumber'                                        --  4 : AssignmentNumber（アサイメント番号）
      || cv_pipe || 'WorkTermsNumber'                                         --  5 : WorkTermsNumber（勤務条件番号）
      || cv_pipe || 'EffectiveLatestChange'                                   --  6 : EffectiveLatestChange（有効最終変更）
      || cv_pipe || 'EffectiveStartDate'                                      --  7 : EffectiveStartDate（有効開始日）
      || cv_pipe || 'EffectiveSequence'                                       --  8 : EffectiveSequence（有効順序）
      || cv_pipe || 'PersonTypeCode'                                          --  9 : PersonTypeCode（Personタイプ）
      || cv_pipe || 'AssignmentStatusTypeCode'                                -- 10 : AssignmentStatusTypeCode（アサイメント・ステータス・タイプ）
      || cv_pipe || 'AssignmentType'                                          -- 11 : AssignmentType（アサイメント・タイプ）
      || cv_pipe || 'SystemPersonType'                                        -- 12 : SystemPersonType（システムPersonタイプ）
      || cv_pipe || 'AssignmentName'                                          -- 13 : AssignmentName（アサイメント名）
      || cv_pipe || 'JobCode'                                                 -- 14 : JobCode（ジョブ・コード）
      || cv_pipe || 'DefaultExpenseAccount'                                   -- 15 : DefaultExpenseAccount（デフォルト費用勘定）
      || cv_pipe || 'BusinessUnitShortCode'                                   -- 16 : BusinessUnitShortCode（ビジネス・ユニット）
      || cv_pipe || 'ManagerFlag'                                             -- 17 : ManagerFlag（マネージャ）
      || cv_pipe || 'LocationCode'                                            -- 18 : LocationCode（事業所コード）
      || cv_pipe || 'PersonNumber'                                            -- 19 : PersonNumber（個人番号）
      || cv_pipe || 'ActionCode'                                              -- 20 : ActionCode（処理コード）
      || cv_pipe || 'WorkerType'                                              -- 21 : WorkerType（就業者タイプ）
      || cv_pipe || 'DepartmentName'                                          -- 22 : DepartmentName（部門）
      || cv_pipe || 'DateStart'                                               -- 23 : DateStart（開始日）
      || cv_pipe || 'LegalEmployerName'                                       -- 24 : LegalEmployerName（雇用主名）
      || cv_pipe || 'PrimaryAssignmentFlag'                                   -- 25 : PrimaryAssignmentFlag（雇用関係のプライマリ・アサイメント）
                                                                              --      (↓PER_ASG_DF=ITO_SALES_USE_ITEM)
      || cv_pipe || 'transferReasonCode(PER_ASG_DF=ITO_SALES_USE_ITEM)'       -- 26 : transferReasonCode（異動事由コード)
      || cv_pipe || 'announceDate(PER_ASG_DF=ITO_SALES_USE_ITEM)'             -- 27 : announceDate（発令日)
      || cv_pipe || 'workLocDepartmentNew(PER_ASG_DF=ITO_SALES_USE_ITEM)'     -- 28 : workLocDepartmentNew（勤務地拠点コード（新）)
      || cv_pipe || 'workLocDepartmentOld(PER_ASG_DF=ITO_SALES_USE_ITEM)'     -- 29 : workLocDepartmentOld（勤務地拠点コード（旧）)
      || cv_pipe || 'departmentNew(PER_ASG_DF=ITO_SALES_USE_ITEM)'            -- 30 : departmentNew（拠点コード（新））
      || cv_pipe || 'departmentOld(PER_ASG_DF=ITO_SALES_USE_ITEM)'            -- 31 : departmentOld（拠点コード（旧）)
      || cv_pipe || 'appWorkTimeCodeNew(PER_ASG_DF=ITO_SALES_USE_ITEM)'       -- 32 : appWorkTimeCodeNew（適用労働時間制コード（新）)
      || cv_pipe || 'appWorkTimeNameNew(PER_ASG_DF=ITO_SALES_USE_ITEM)'       -- 33 : appWorkTimeNameNew（適用労働名（新）)
      || cv_pipe || 'appWorkTimeCodeOld(PER_ASG_DF=ITO_SALES_USE_ITEM)'       -- 34 : appWorkTimeCodeOld（適用労働時間制コード（旧）)
      || cv_pipe || 'appWorkTimeNameOld(PER_ASG_DF=ITO_SALES_USE_ITEM)'       -- 35 : appWorkTimeNameOld（適用労働名（旧）)
      || cv_pipe || 'positionSortCodeNew(PER_ASG_DF=ITO_SALES_USE_ITEM)'      -- 36 : positionSortCodeNew（職位並順コード（新）)
      || cv_pipe || 'positionSortCodeOld(PER_ASG_DF=ITO_SALES_USE_ITEM)'      -- 37 : positionSortCodeOld（職位並順コード（旧）)
      || cv_pipe || 'approvalClassNew(PER_ASG_DF=ITO_SALES_USE_ITEM)'         -- 38 : approvalClassNew（承認区分（新）)
      || cv_pipe || 'approvalClassOld(PER_ASG_DF=ITO_SALES_USE_ITEM)'         -- 39 : approvalClassOld（承認区分（旧））
      || cv_pipe || 'alternateClassNew(PER_ASG_DF=ITO_SALES_USE_ITEM)'        -- 40 : alternateClassNew（代行区分（新）)
      || cv_pipe || 'alternateClassOld(PER_ASG_DF=ITO_SALES_USE_ITEM)'        -- 41 : alternateClassOld（代行区分（旧）)
      || cv_pipe || 'transferDateVend(PER_ASG_DF=ITO_SALES_USE_ITEM)'         -- 42 : transferDateVend（差分連携用日付（自販機）)
      || cv_pipe || 'transferDateRep(PER_ASG_DF=ITO_SALES_USE_ITEM)'          -- 43 : transferDateRep（差分連携用日付（帳票）)
                                                                              --      (↑PER_ASG_DF=ITO_SALES_USE_ITEM)
      || cv_pipe || 'SourceSystemOwner'                                       -- 44 : SourceSystemOwner（ソース・システム所有者）
      || cv_pipe || 'SourceSystemId'                                          -- 45 : SourceSystemId（ソース・システムID）
    ;
--
    -- *** ローカル変数 ***
    lv_file_data         VARCHAR2(30000) DEFAULT NULL;       -- 出力内容
--
    -- *** ローカル・カーソル ***
    --------------------------------------
    -- 就業者の抽出カーソル
    --------------------------------------
    CURSOR worker_cur
    IS
      SELECT
          papf.employee_number                              AS employee_number            -- 従業員番号
        , (SELECT
               TO_CHAR(MIN(papf3.effective_start_date), cv_date_fmt)
           FROM
               per_all_people_f     papf3  -- 従業員マスタ
           WHERE
               papf3.person_id = papf.person_id
          )                                                 AS effective_start_date       -- 有効開始日
-- Ver1.8 Mod Start
--        , TO_CHAR(papf.start_date, cv_date_fmt)             AS start_date                 -- 開始日
        , (SELECT
               TO_CHAR(MIN(papf4.effective_start_date), cv_date_fmt)
           FROM
               per_all_people_f     papf4  -- 従業員マスタ
           WHERE
               papf4.person_id = papf.person_id
          )                                                 AS start_date                 -- 開始日
-- Ver1.8 Mod Start
        , papf.attribute1                                   AS attribute1                 -- ポイント
        , papf.attribute2                                   AS attribute2                 -- 資格コード
        , papf.attribute3                                   AS attribute3                 -- 従業員区分
        , papf.attribute4                                   AS attribute4                 -- 仕入先コード
        , papf.attribute5                                   AS attribute5                 -- 運送業者
        , papf.attribute6                                   AS attribute6                 -- 仕入先サイトコード
        , papf.attribute7                                   AS attribute7                 -- 資格コード（新）
        , papf.attribute8                                   AS attribute8                 -- 資格名（新）
        , papf.attribute9                                   AS attribute9                 -- 資格コード（旧）
        , papf.attribute10                                  AS attribute10                -- 資格名（旧）
        , papf.attribute11                                  AS attribute11                -- 職位コード（新）
        , papf.attribute12                                  AS attribute12                -- 職位名（新）
        , papf.attribute13                                  AS attribute13                -- 職位コード（旧）
        , papf.attribute14                                  AS attribute14                -- 職位名（旧）
        , papf.attribute15                                  AS attribute15                -- 職務コード（新）
        , papf.attribute16                                  AS attribute16                -- 職務名（新）
        , papf.attribute17                                  AS attribute17                -- 職務コード（旧）
        , papf.attribute18                                  AS attribute18                -- 職務名（旧）
        , papf.attribute19                                  AS attribute19                -- 職種コード（新）
        , papf.attribute20                                  AS attribute20                -- 職種名（新）
        , papf.attribute21                                  AS attribute21                -- 職種コード（旧）
        , papf.attribute22                                  AS attribute22                -- 職種名（旧）
        , papf.attribute28                                  AS attribute28                -- 所属部門
        , papf.attribute29                                  AS attribute29                -- 照会範囲
        , papf.attribute30                                  AS attribute30                -- 承認者範囲
        , pvsa.pay_group_lookup_code                        AS pay_group_lookup_code      -- 支払グループ
        , pvsa.attribute5                                   AS inquiry_base_code_p        -- 問合せ担当拠点コード
        , papf.person_id                                    AS person_id                  -- 個人ID
        , (CASE
             WHEN papf.creation_date >= gt_pre_process_date THEN
               cv_y
             ELSE
               cv_n
           END)                                             AS new_reg_flag               -- 新規登録フラグ
      FROM
          per_all_people_f     papf  -- 従業員マスタ
        , po_vendors           pv    -- 仕入先マスタ
        , po_vendor_sites_all  pvsa  -- 仕入先サイトマスタ
      WHERE
          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external , cv_emp_kbn_dummy)  -- 従業員区分（1:内部、2:外部、4:ダミー）
      AND papf.attribute4 IS NULL    -- 仕入先コード
      AND papf.attribute5 IS NULL    -- 運送業者
      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- 従業員番号
      AND papf.effective_start_date = 
              (SELECT
                   MAX(papf2.effective_start_date)
               FROM
                   per_all_people_f  papf2 -- 従業員マスタ
               WHERE
                   papf2.person_id = papf.person_id
              )
      AND papf.person_id                = pv.employee_id(+)
      AND pv.vendor_type_lookup_code(+) = cv_vd_type_employee
      AND pv.vendor_id                  = pvsa.vendor_id(+)
-- Ver1.2(E056) Add Start
      AND pvsa.vendor_site_code(+)      = cv_site_code_comp
-- Ver1.2(E056) Add End
-- Ver1.18 Mod Start
--      AND (   papf.last_update_date >= gt_pre_process_date
---- Ver1.13 Mod Start
----           OR papf.attribute23      >= gv_str_pre_process_date)
--           OR papf.attribute23      >= gv_str_pre_process_date
--           OR pvsa.last_update_date >= gt_pre_process_date
--          )
---- Ver1.13 Mod End
      AND (   
              (     papf.last_update_date >= gt_pre_process_date
                AND papf.last_update_date <  gt_cur_process_date
              )
           OR (
                    papf.attribute23      >= gv_str_pre_process_date
                AND papf.attribute23      <  gv_str_cur_process_date
              )
           OR (
                    pvsa.last_update_date >= gt_pre_process_date
                AND pvsa.last_update_date <  gt_cur_process_date
              )
          )
-- Ver1.18 Mod End
      ORDER BY
          papf.employee_number ASC
    ;
--
    --------------------------------------
    -- 個人名の抽出カーソル
    --------------------------------------
    CURSOR per_name_cur
    IS
      SELECT
          papf.employee_number                              AS employee_number            -- 従業員番号
        , (SELECT
               TO_CHAR(MIN(papf3.effective_start_date), cv_date_fmt)
           FROM
               per_all_people_f  papf3  -- 従業員マスタ
           WHERE
               papf3.person_id = papf.person_id
          )                                                 AS effective_start_date       -- 有効開始日
        , papf.person_id                                    AS person_id                  -- 個人ID
        , papf.first_name                                   AS first_name                 -- 名
        , papf.last_name                                    AS last_name                  -- 姓
        , papf.per_information18                            AS per_information18          -- 漢字姓
        , papf.per_information19                            AS per_information19          -- 漢字名
        , (CASE
             WHEN papf.creation_date >= gt_pre_process_date THEN
               cv_y
             ELSE
               cv_n
           END)                                             AS new_reg_flag               -- 新規登録フラグ
      FROM
          per_all_people_f       papf   -- 従業員マスタ
        , po_vendors             pv     -- 仕入先マスタ
      WHERE
          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external , cv_emp_kbn_dummy)  -- 従業員区分（1:内部、2:外部、4:ダミー）
      AND papf.attribute4 IS NULL    -- 仕入先コード
      AND papf.attribute5 IS NULL    -- 運送業者
      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- 従業員番号
      AND papf.effective_start_date = 
              (SELECT
                   MAX(papf2.effective_start_date)
               FROM
                   per_all_people_f  papf2 -- 従業員マスタ
               WHERE
                   papf2.person_id = papf.person_id
              )
      AND papf.person_id                = pv.employee_id(+)
      AND pv.vendor_type_lookup_code(+) = cv_vd_type_employee
-- Ver1.18 Mod Start
--      AND (   papf.last_update_date >= gt_pre_process_date
--           OR papf.attribute23      >= gv_str_pre_process_date)
      AND (   
              (     papf.last_update_date >= gt_pre_process_date
                AND papf.last_update_date <  gt_cur_process_date
              )
           OR (
                    papf.attribute23      >= gv_str_pre_process_date
                AND papf.attribute23      <  gv_str_cur_process_date
              )
          )
-- Ver1.18 Mod End
      ORDER BY
          papf.employee_number ASC
    ;
--
    --------------------------------------
    -- 個人国別仕様データの抽出カーソル
    --------------------------------------
    CURSOR per_legi_cur
    IS
      SELECT
          papf.employee_number                              AS employee_number            -- 従業員番号
        , (SELECT
               TO_CHAR(MIN(papf3.effective_start_date), cv_date_fmt)
           FROM
               per_all_people_f  papf3  -- 従業員マスタ
           WHERE
               papf3.person_id = papf.person_id
          )                                                 AS effective_start_date       -- 有効開始日
        , papf.person_id                                    AS person_id                  -- 個人ID
        , papf.sex                                          AS sex                        -- 性別
        , (CASE
             WHEN papf.creation_date >= gt_pre_process_date THEN
               cv_y
             ELSE
               cv_n
           END)                                             AS new_reg_flag               -- 新規登録フラグ
      FROM
          per_all_people_f       papf   -- 従業員マスタ
        , po_vendors             pv     -- 仕入先マスタ
      WHERE
          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external , cv_emp_kbn_dummy)  -- 従業員区分（1:内部、2:外部、4:ダミー）
      AND papf.attribute4 IS NULL    -- 仕入先コード
      AND papf.attribute5 IS NULL    -- 運送業者
      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- 従業員番号
      AND papf.effective_start_date = 
              (SELECT
                   MAX(papf2.effective_start_date)
               FROM
                   per_all_people_f  papf2  -- 従業員マスタ
               WHERE
                   papf2.person_id = papf.person_id
              )
      AND papf.person_id                = pv.employee_id(+)
      AND pv.vendor_type_lookup_code(+) = cv_vd_type_employee
-- Ver1.18 Mod Start
--      AND (   papf.last_update_date >= gt_pre_process_date
--           OR papf.attribute23      >= gv_str_pre_process_date)
      AND (   
              (     papf.last_update_date >= gt_pre_process_date
                AND papf.last_update_date <  gt_cur_process_date
              )
           OR (
                    papf.attribute23      >= gv_str_pre_process_date
                AND papf.attribute23      <  gv_str_cur_process_date
              )
          )
-- Ver1.18 Mod End
      ORDER BY
          papf.employee_number ASC
    ;
--
    --------------------------------------
    -- 個人Eメールの抽出カーソル
    --------------------------------------
    CURSOR per_email_cur
    IS
      SELECT
          papf.employee_number                              AS employee_number            -- 従業員番号
        , (SELECT
               TO_CHAR(MIN(papf3.effective_start_date), cv_date_fmt)
           FROM
               per_all_people_f  papf3  -- 従業員マスタ
           WHERE
               papf3.person_id = papf.person_id
           )                                                AS effective_start_date       -- 有効開始日
        , papf.person_id                                    AS person_id                  -- 個人ID
        , (cv_itoen_email_suffix ||
           papf.employee_number  ||
           cv_itoen_email_domain)                           AS email_address              -- Eメール・アドレス
      FROM
          per_all_people_f       papf   -- 従業員マスタ
        , po_vendors             pv     -- 仕入先マスタ
      WHERE
-- Ver1.10 Mod Start
--          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external)  -- 従業員区分（1:内部、2:外部）
          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external , cv_emp_kbn_dummy)  -- 従業員区分（1:内部、2:外部、4:ダミー）
-- Ver1.10 Mod End
      AND papf.attribute4 IS NULL    -- 仕入先コード
      AND papf.attribute5 IS NULL    -- 運送業者
      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- 従業員番号
      AND papf.effective_start_date = 
              (SELECT
                   MAX(papf2.effective_start_date)
               FROM
                   per_all_people_f  papf2 -- 従業員マスタ
               WHERE
                   papf2.person_id = papf.person_id
               )
      AND papf.person_id                = pv.employee_id(+)
      AND pv.vendor_type_lookup_code(+) = cv_vd_type_employee
-- Ver1.18 Mod Start
---- Ver1.10 Mod Start
----      AND (   papf.last_update_date >= gt_pre_process_date
----           OR papf.attribute23      >= gv_str_pre_process_date)
--      AND papf.creation_date >= gt_pre_process_date
---- Ver1.10 Mod End
      AND (
                papf.creation_date >= gt_pre_process_date
            AND papf.creation_date <  gt_cur_process_date
          )
-- Ver1.18 Mod End
      ORDER BY
          papf.employee_number ASC
    ;
--
    --------------------------------------
    -- 雇用関係（退職者）の抽出カーソル
    --------------------------------------
    CURSOR wk_rel_cur
    IS
      SELECT
          papf.employee_number                              AS employee_number            -- 従業員番号
        , TO_CHAR(ppos.date_start, cv_date_fmt)             AS date_start                 -- 開始日
        , (CASE 
             WHEN xoedi.person_id IS NOT NULL THEN
               TO_CHAR(ppos.actual_termination_date, cv_date_fmt)
             ELSE 
               NULL
           END)                                             AS actual_termination_date    -- 実績退職日
        , (CASE 
             WHEN (xoedi.person_id IS NOT NULL
                   AND  ppos.actual_termination_date IS NOT NULL) THEN
               cv_y
             ELSE 
               NULL
           END)                                             AS terminate_work_rel_flag    -- 雇用関係の終了
        , (CASE 
             WHEN (xoedi.actual_termination_date IS NOT NULL
                   AND  ppos.actual_termination_date IS NULL) THEN
               cv_y
             ELSE 
               NULL
           END)                                             AS reverse_termination_flag   -- 退職の取消
        , (CASE 
             WHEN (xoedi.person_id IS NOT NULL
                   AND  ppos.actual_termination_date IS NOT NULL) THEN
               cv_act_cd_termination
-- Ver1.4 Add Start
             WHEN  xoedi_new.person_id IS NOT NULL THEN
               cv_act_cd_rehire
-- Ver1.4 Add End
             ELSE
               cv_act_cd_hire
           END)                                             AS action_code                -- 処理コード
        , ppos.period_of_service_id                         AS period_of_service_id       -- 就業情報ID
        , (CASE
             WHEN ppos.creation_date >= gt_pre_process_date THEN
               cv_y
             ELSE
               cv_n
           END)                                             AS new_reg_flag               -- 新規登録フラグ
      FROM
           per_all_people_f              papf      -- 従業員マスタ
         , per_all_assignments_f         paaf      -- アサイメントマスタ
         , per_periods_of_service        ppos      -- 就業情報
         , xxcmm_oic_emp_diff_info       xoedi     -- OIC社員差分情報テーブル
-- Ver1.4 Add Start
         , xxcmm_oic_emp_diff_info       xoedi_new -- OIC社員差分情報テーブル【新規】
-- Ver1.4 Add End
      WHERE
          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external , cv_emp_kbn_dummy)  -- 従業員区分（1:内部、2:外部、4:ダミー）
      AND papf.attribute4 IS NULL    -- 仕入先コード
      AND papf.attribute5 IS NULL    -- 運送業者
      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- 従業員番号
      AND papf.effective_start_date = 
              (SELECT
                   MAX(papf2.effective_start_date)
               FROM
                   per_all_people_f  papf2 -- 従業員マスタ
               WHERE
                   papf2.person_id = papf.person_id
              )
      AND papf.person_id            = paaf.person_id
      AND paaf.period_of_service_id = ppos.period_of_service_id
      AND ppos.person_id            = xoedi.person_id(+)
      AND ppos.date_start           = xoedi.date_start(+)
-- Ver1.4 Add Start
      AND ppos.person_id            = xoedi_new.person_id(+)
-- Ver1.4 Add End
-- Ver1.18 Mod Start
--      AND ppos.last_update_date     >= gt_pre_process_date      
      AND (
                ppos.last_update_date >= gt_pre_process_date
            AND ppos.last_update_date <  gt_cur_process_date
          )
-- Ver1.18 Mod End
      ORDER BY
          papf.employee_number ASC
        , ppos.date_start ASC
    ;
--
    --------------------------------------
    -- ユーザー情報（新規）の抽出カーソル
    --------------------------------------
    CURSOR new_user_cur
    IS
      -- ユーザーマスタが存在する場合
      SELECT
          fu.user_name                                      AS user_name                    -- ユーザー名
        , papf.employee_number                              AS employee_number              -- 従業員番号
        , TO_CHAR(fu.start_date, cv_date_fmt)               AS start_date                   -- 開始日
        , cv_y                                              AS generated_user_account_flag  -- 生成済ユーザー・アカウント
      FROM
          per_all_people_f     papf  -- 従業員マスタ
        , fnd_user             fu    -- ユーザーマスタ
      WHERE
          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external , cv_emp_kbn_dummy)  -- 従業員区分（1:内部、2:外部、4:ダミー）
      AND papf.attribute4 IS NULL    -- 仕入先コード
      AND papf.attribute5 IS NULL    -- 運送業者
      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- 従業員番号
      AND papf.effective_start_date = 
              (SELECT
                   MAX(papf2.effective_start_date)
               FROM
                   per_all_people_f  papf2 -- 従業員マスタ
               WHERE
                   papf2.person_id = papf.person_id
              )
      AND papf.person_id     = fu.employee_id
-- Ver1.18 Mod Start
--      AND papf.creation_date >= gt_pre_process_date
--      AND fu.creation_date   >= gt_pre_process_date
      AND (
                papf.creation_date >= gt_pre_process_date
            AND papf.creation_date <  gt_cur_process_date
          )
      AND (
                fu.creation_date   >= gt_pre_process_date
            AND fu.creation_date   <  gt_cur_process_date
          )
-- Ver1.18 Mod End
      --
      UNION ALL
      -- ユーザーマスタが存在しない場合
      SELECT
          papf.employee_number                              AS user_name                    -- ユーザー名
        , papf.employee_number                              AS employee_number              -- 従業員番号
        , TO_CHAR(gt_if_dest_date, cv_date_fmt)             AS start_date                   -- 開始日
        , cv_n                                              AS generated_user_account_flag  -- 生成済ユーザー・アカウント
      FROM
          per_all_people_f     papf  -- 従業員マスタ
      WHERE
          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external , cv_emp_kbn_dummy)  -- 従業員区分（1:内部、2:外部、4:ダミー）
      AND papf.attribute4 IS NULL    -- 仕入先コード
      AND papf.attribute5 IS NULL    -- 運送業者
      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- 従業員番号
      AND papf.effective_start_date = 
              (SELECT
                   MAX(papf2.effective_start_date)
               FROM
                   per_all_people_f  papf2 -- 従業員マスタ
               WHERE
                   papf2.person_id = papf.person_id
              )
      AND NOT EXISTS (
              SELECT
                  1 AS flag
              FROM
                  fnd_user  fu    -- ユーザーマスタ
              WHERE
                  fu.employee_id = papf.person_id
          )
-- Ver 1.2(E055) Mod Start
--      AND (papf.last_update_date >= gt_pre_process_date
--           OR
--           papf.attribute23 >= gv_str_pre_process_date
--           OR
--           EXISTS (
--               SELECT
--                   1 AS flag
--               FROM 
--                   per_all_assignments_f   paaf  -- アサイメントマスタ
--               WHERE
--                   paaf.person_id = papf.person_id
--               AND (paaf.last_update_date >= gt_pre_process_date
--                    OR
--                    paaf.ass_attribute19  >= gv_str_pre_process_date))
--          )
-- Ver1.18 Mod Start
--      AND papf.creation_date >= gt_pre_process_date
      AND (
                papf.creation_date >= gt_pre_process_date
            AND papf.creation_date <  gt_cur_process_date
          )
-- Ver1.18 Mod Start
-- Ver 1.2(E055) Mod End
      --
      ORDER BY
          employee_number ASC
    ;
--
    --------------------------------------
    -- 雇用条件の抽出カーソル
    --------------------------------------
    CURSOR wk_terms_cur
    IS
      SELECT
          (paaf.assignment_number || cv_wk_terms_suffix)    AS assignment_number          -- アサイメント番号
        , papf.employee_number                              AS employee_number            -- 従業員番号
-- Ver1.4 Mod Start
--        , TO_CHAR(papf.start_date, cv_date_fmt)             AS start_date                 -- 開始日
        , TO_CHAR(ppos.date_start, cv_date_fmt)             AS start_date                 -- 開始日
-- Ver1.4 Mod End
        , (CASE
             WHEN xoedi.person_id IS NULL THEN
               TO_CHAR(paaf.effective_start_date, cv_date_fmt)
             ELSE
               TO_CHAR(gt_if_dest_date, cv_date_fmt)  -- 連携日付
           END)                                             AS effective_start_date       -- 有効開始日
        , paaf.assignment_number                            AS assignment_name            -- アサイメント名
        , (cv_wt || paaf.assignment_id)                     AS source_system_id           -- ソース・システムID
        , (CASE
             WHEN xoedi_new.person_id IS NULL THEN
               cv_act_cd_hire
             WHEN xoedi.person_id IS NULL THEN
               cv_act_cd_rehire
             ELSE
               cv_act_cd_mng_chg
           END)                                             AS action_code                -- 処理コード
        , (CASE
             WHEN xoedi.person_id IS NULL THEN
               cv_n
             WHEN NVL(xoedi.sup_assignment_number, '@') <> NVL(paaf_sup.assignment_number, '@') THEN
               cv_y
             ELSE
               cv_n
           END)                                             AS sup_chg_flag               -- 上長変更フラグ
      FROM
          per_all_people_f            papf      -- 従業員マスタ
        , per_all_assignments_f       paaf      -- アサイメントマスタ
        , per_periods_of_service      ppos      -- 就業情報
        , xxcmm_oic_emp_diff_info     xoedi_new -- OIC社員差分情報テーブル【新規】
        , xxcmm_oic_emp_diff_info     xoedi     -- OIC社員差分情報テーブル
        , (SELECT
               paaf_s.person_id           AS person_id           -- 個人ID
             , paaf_s.assignment_number   AS assignment_number   -- アサイメント番号
           FROM
               per_all_assignments_f    paaf_s  -- アサイメントマスタ(上長)
             , per_periods_of_service   ppos_s  -- 就業情報(上長)
           WHERE
               paaf_s.period_of_service_id = ppos_s.period_of_service_id
           AND ppos_s.actual_termination_date IS NULL
          )                           paaf_sup  -- アサイメントマスタ(上長)
      WHERE
          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external , cv_emp_kbn_dummy)  -- 従業員区分（1:内部、2:外部、4:ダミー）
      AND papf.attribute4 IS NULL    -- 仕入先コード
      AND papf.attribute5 IS NULL    -- 運送業者
      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- 従業員番号
      AND papf.effective_start_date = 
              (SELECT
                   MAX(papf2.effective_start_date)
               FROM
                   per_all_people_f  papf2 -- 従業員マスタ
               WHERE
                   papf2.person_id = papf.person_id
              )
      AND papf.person_id = paaf.person_id
      AND paaf.effective_start_date = 
              (SELECT
                   MAX(paaf2.effective_start_date)
               FROM
                   per_all_assignments_f   paaf2  -- アサイメントマスタ
               WHERE
                   paaf2.person_id = paaf.person_id
              )
      AND paaf.period_of_service_id = ppos.period_of_service_id
      AND ppos.person_id            = xoedi_new.person_id(+)
      AND ppos.person_id            = xoedi.person_id(+)
      AND ppos.date_start           = xoedi.date_start(+)
      AND paaf.supervisor_id        = paaf_sup.person_id(+)
      AND (   ppos.actual_termination_date IS NULL
           OR xoedi.person_id IS NULL)
-- Ver1.18 Mod Start
--      AND (   paaf.last_update_date >= gt_pre_process_date
--           OR paaf.ass_attribute19  >= gv_str_pre_process_date)
      AND (   
              (     paaf.last_update_date >= gt_pre_process_date
                AND paaf.last_update_date <  gt_cur_process_date
              )
           OR (
                    paaf.ass_attribute19  >= gv_str_pre_process_date
                AND paaf.ass_attribute19  <  gv_str_cur_process_date
              )
          )
-- Ver1.18 Mod End
      ORDER BY
          papf.employee_number ASC
    ;
--
    --------------------------------------
    -- アサイメントの抽出カーソル
    --------------------------------------
    CURSOR ass_cur
    IS
      SELECT
          paaf.assignment_number                            AS assignment_number          -- アサイメント番号
        , (paaf.assignment_number || cv_wk_terms_suffix)    AS work_terms_number          -- 勤務条件番号
        , (CASE
             WHEN xoedi.person_id IS NULL THEN
               TO_CHAR(paaf.effective_start_date, cv_date_fmt)
             ELSE
               TO_CHAR(gt_if_dest_date, cv_date_fmt)  -- 連携日付
           END)                                             AS effective_start_date       -- 有効開始日
        , paaf.assignment_type                              AS assignment_type            -- アサイメント・タイプ
        , pjd.segment3                                      AS job_code                   -- 役職コード
        , (CASE
             WHEN gcc.code_combination_id IS NOT NULL THEN
               (gcc.segment1               || cv_hyphen ||
                gcc.segment2               || cv_hyphen ||
                gt_prf_val_def_account_cd  || cv_hyphen ||
                gt_prf_val_def_sub_acct_cd || cv_hyphen ||
                gcc.segment5               || cv_hyphen ||
                gcc.segment6               || cv_hyphen ||
                gcc.segment7               || cv_hyphen ||
                gcc.segment8
               )
             ELSE
               NULL
           END)                                             AS default_expense_account    -- デフォルト費用勘定
        , (CASE
             WHEN
               (SELECT
                    COUNT(1)  AS cnt
                FROM 
                    per_all_assignments_f   paaf_staff  -- アサイメントマスタ(部下)
                  , per_periods_of_service  ppos_staff  -- 就業情報(部下)
                WHERE 
                    paaf_staff.supervisor_id        = paaf.person_id
                AND paaf_staff.period_of_service_id = ppos_staff.period_of_service_id
                AND ppos_staff.actual_termination_date IS NULL
               ) > 0 THEN 
               cv_y
             ELSE
               NULL
           END)                                             AS manager_flag               -- マネージャ
        , hla.location_code                                 AS location_code              -- 事業所コード
        , papf.employee_number                              AS employee_number            -- 従業員番号
-- Ver1.4 Mod Start
--        , TO_CHAR(papf.start_date, cv_date_fmt)             AS start_date                 -- 開始日
        , TO_CHAR(ppos.date_start, cv_date_fmt)             AS start_date                 -- 開始日
-- Ver1.4 Mod End
        , paaf.primary_flag                                 AS primary_flag               -- プライマリ・フラグ
        , paaf.ass_attribute1                               AS ass_attribute1             -- 異動事由コード
        , paaf.ass_attribute2                               AS ass_attribute2             -- 発令日
        , paaf.ass_attribute3                               AS ass_attribute3             -- 勤務地拠点コード(新)
        , paaf.ass_attribute4                               AS ass_attribute4             -- 勤務地拠点コード(旧)
        , paaf.ass_attribute5                               AS ass_attribute5             -- 拠点コード(新)
        , paaf.ass_attribute6                               AS ass_attribute6             -- 拠点コード(旧)
        , paaf.ass_attribute7                               AS ass_attribute7             -- 適用労働時間制コード(新)
        , paaf.ass_attribute8                               AS ass_attribute8             -- 適用労働名(新)
        , paaf.ass_attribute9                               AS ass_attribute9             -- 適用労働時間制コード(旧)
        , paaf.ass_attribute10                              AS ass_attribute10            -- 適用労働名(旧)
        , paaf.ass_attribute11                              AS ass_attribute11            -- 職位並順コード(新)
        , paaf.ass_attribute12                              AS ass_attribute12            -- 職位並順コード(旧)
        , paaf.ass_attribute13                              AS ass_attribute13            -- 承認区分(新)
        , paaf.ass_attribute14                              AS ass_attribute14            -- 承認区分(旧)
        , paaf.ass_attribute15                              AS ass_attribute15            -- 代行区分(新)
        , paaf.ass_attribute16                              AS ass_attribute16            -- 代行区分(旧)
        , paaf.ass_attribute17                              AS ass_attribute17            -- 差分連携用日付(自販機)
        , paaf.ass_attribute18                              AS ass_attribute18            -- 差分連携用日付(帳票)
        , paaf.assignment_id                                AS source_system_id           -- ソース・システムID
        , (CASE
             WHEN paaf.creation_date >= gt_pre_process_date THEN
               cv_y
             ELSE
               cv_n
           END)                                             AS new_reg_flag               -- 新規登録フラグ
        , (CASE
             WHEN xoedi_new.person_id IS NULL THEN
               cv_act_cd_hire
             WHEN xoedi.person_id IS NULL THEN
               cv_act_cd_rehire
             ELSE
               cv_act_cd_mng_chg
           END)                                             AS action_code                -- 処理コード
        , (CASE
             WHEN xoedi.person_id IS NULL THEN
               cv_n
             WHEN NVL(xoedi.sup_assignment_number, '@') <> NVL(paaf_sup.assignment_number, '@') THEN
               cv_y
             ELSE
               cv_n
           END)                                             AS sup_chg_flag               -- 上長変更フラグ
      FROM
          per_all_people_f            papf      -- 従業員マスタ
        , per_all_assignments_f       paaf      -- アサイメントマスタ
        , per_jobs                    pj        -- 役職マスタ
        , per_job_definitions         pjd       -- 役職定義マスタ
        , hr_locations_all            hla       -- 事業所マスタ
        , gl_code_combinations        gcc       -- 勘定科目組合せ
        , per_periods_of_service      ppos      -- 就業情報
        , xxcmm_oic_emp_diff_info     xoedi_new -- OIC社員差分情報テーブル【新規】
        , xxcmm_oic_emp_diff_info     xoedi     -- OIC社員差分情報テーブル
        , (SELECT
               paaf_s.person_id           AS person_id           -- 個人ID
             , paaf_s.assignment_number   AS assignment_number   -- アサイメント番号
           FROM
               per_all_assignments_f    paaf_s  -- アサイメントマスタ(上長)
             , per_periods_of_service   ppos_s  -- 就業情報(上長)
           WHERE
               paaf_s.period_of_service_id = ppos_s.period_of_service_id
           AND ppos_s.actual_termination_date IS NULL
          )                           paaf_sup  -- アサイメントマスタ(上長)
      WHERE
          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external , cv_emp_kbn_dummy)  -- 従業員区分（1:内部、2:外部、4:ダミー）
      AND papf.attribute4 IS NULL    -- 仕入先コード
      AND papf.attribute5 IS NULL    -- 運送業者
      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- 従業員番号
      AND papf.effective_start_date = 
             (SELECT
                  MAX(papf2.effective_start_date)
              FROM
                  per_all_people_f  papf2 -- 従業員マスタ
              WHERE
                  papf2.person_id = papf.person_id
             )
      AND papf.person_id = paaf.person_id
      AND paaf.effective_start_date = 
             (SELECT
                  MAX(paaf2.effective_start_date)
              FROM
                  per_all_assignments_f  paaf2  -- アサイメントマスタ
              WHERE
                  paaf2.person_id = paaf.person_id
             )
      AND paaf.job_id               = pj.job_id(+)
      AND pj.job_definition_id      = pjd.job_definition_id(+)
      AND paaf.default_code_comb_id = gcc.code_combination_id(+)
      AND paaf.location_id          = hla.location_id(+)
      AND paaf.period_of_service_id = ppos.period_of_service_id
      AND ppos.person_id            = xoedi_new.person_id(+)
      AND ppos.person_id            = xoedi.person_id(+)
      AND ppos.date_start           = xoedi.date_start(+)
      AND paaf.supervisor_id        = paaf_sup.person_id(+)
      AND (   ppos.actual_termination_date IS NULL
           OR xoedi.person_id IS NULL)
-- Ver1.18 Mod Start
--      AND (   paaf.last_update_date >= gt_pre_process_date
--           OR paaf.ass_attribute19  >= gv_str_pre_process_date)
           
      AND (   
              (     paaf.last_update_date >= gt_pre_process_date
                AND paaf.last_update_date <  gt_cur_process_date
              )
           OR (
                    paaf.ass_attribute19  >= gv_str_pre_process_date
                AND paaf.ass_attribute19  <  gv_str_cur_process_date
              )
          )
-- Ver1.18 Mod End
      ORDER BY
          paaf.assignment_number ASC
    ;
--
    -- *** ローカル・レコード ***
    l_worker_rec       worker_cur%ROWTYPE;        -- 就業者の抽出カーソルレコード
    l_per_name_rec     per_name_cur%ROWTYPE;      -- 個人名の抽出カーソルレコード
    l_per_legi_rec     per_legi_cur%ROWTYPE;      -- 個人国別仕様データの抽出カーソルレコード
    l_per_email_rec    per_email_cur%ROWTYPE;     -- 個人Eメールの抽出カーソルレコード
    l_wk_rel_rec       wk_rel_cur%ROWTYPE;        -- 雇用関係（退職者）の抽出カーソルレコード
    l_new_user_rec     new_user_cur%ROWTYPE;      -- ユーザー情報（新規）の抽出カーソルレコード
    l_wk_terms_rec     wk_terms_cur%ROWTYPE;      -- 雇用条件の抽出カーソルレコード
    l_ass_rec          ass_cur%ROWTYPE;           -- アサイメントの抽出カーソルレコード
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
    lv_wt_header_wrk   := cv_n;
    lv_wt_header_wrk2  := cv_n;
    lv_ass_header_wrk  := cv_n;
    lv_ass_header_wrk2 := cv_n;
--
    -- ==============================================================
    -- 就業者の抽出(A-2-1)
    -- ==============================================================
    -- カーソルオープン
    OPEN worker_cur;
    <<output_worker_loop>>
    LOOP
      --
      FETCH worker_cur INTO l_worker_rec;
      EXIT WHEN worker_cur%NOTFOUND;
      --
      -- 抽出件数カウントアップ
      gn_get_wk_cnt := gn_get_wk_cnt + 1;
      --
      -- ==============================================================
      -- 就業者のファイル出力(A-2-2)
      -- ==============================================================
      -- ヘッダー行の作成（初回のみ）
      IF ( gn_get_wk_cnt = 1 ) THEN
        --
        BEGIN
          -- ヘッダー行のファイル出力
          UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- 従業員情報連携データファイル
                           , cv_worker_header
                           );
        EXCEPTION
          WHEN OTHERS THEN
            RAISE global_fileout_expt;
        END;
      END IF;
      --
      -- データ行の作成
      lv_file_data := cv_meta_merge;                                                 --  1 : METADATA
      lv_file_data := lv_file_data || cv_pipe || cv_cls_worker;                      --  2 : Worker
      lv_file_data := lv_file_data || cv_pipe || cv_per_persons_dff;                 --  3 : FLEX:PER_PERSONS_DFF（コンテキスト）
      lv_file_data := lv_file_data || cv_pipe || l_worker_rec.employee_number;       --  4 : PersonNumber（個人番号）
      lv_file_data := lv_file_data || cv_pipe || l_worker_rec.effective_start_date;  --  5 : EffectiveStartDate（有効開始日）
      lv_file_data := lv_file_data || cv_pipe || cv_act_cd_hire;                     --  6 : ActionCode（処理コード）
      lv_file_data := lv_file_data || cv_pipe || l_worker_rec.start_date;            --  7 : StartDate（開始日）
                                                                                     --      (↓PER_PERSONS_DFF=ITO_SALES_USE_ITEM)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute1
                                 , l_worker_rec.new_reg_flag
-- Ver1.3 Mod Start
--                                 , cv_nvl_n
                                 , cv_nvl_v
-- Ver1.3 Mod End
                                 );                                                  --  8 : point（ポイント)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute2
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  --  9 : qualificationCode（資格コード)

      lv_file_data := lv_file_data || cv_pipe || l_worker_rec.attribute3;            -- 10 : employeeClass（従業員区分)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute4
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 11 : vendorCode（仕入先コード)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute5
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 12 : representativeCarrier（運送業者)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute6
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 13 : vendorsSiteCode（仕入先サイトコード)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute7
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 14 : qualificationCodeNew（資格コード（新）)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute8
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 15 : qualificationNameNew（資格名（新）)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute9
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 16 : qualificationCodeOld（資格コード（旧）)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute10
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 17 : qualificationNameOld（資格名（旧）)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute11
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 18 : positionCodeNew（職位コード（新）)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute12
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 19 : positionNameNew（職位名（新）)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute13
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 20 : positionCodeOld（職位コード（旧）)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute14
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 21 : positionNameOld（職位名（旧）)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute15
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 22 : jobCodeNew（職務コード（新）)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute16
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 23 : jobNameNew（職務名（新）)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute17
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 24 : jobCodeOld（職務コード（旧）)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute18
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 25 : jobNameOld（職務名（旧）)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute19
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 26 : occupationalCodeNew（職種コード（新）)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute20
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 27 : occupationalNameNew（職種名（新）)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute21
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 28 : occupationalCodeOld（職種コード（旧）)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute22
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 29 : occupationalNameOld（職種名（旧）)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute28
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 30 : DepartmentChild（所属部門)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute29
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 31 : referrenceDepartment（照会範囲)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute30
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 32 : approvalDepartment（承認者範囲)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.pay_group_lookup_code
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 33 : paymentMethod（支払方法)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.inquiry_base_code_p
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 34 : inquiryBaseCodeP（問合せ担当拠点コード)
                                                                                     --      (↑PER_PERSONS_DFF=ITO_SALES_USE_ITEM)
      lv_file_data := lv_file_data || cv_pipe || cv_ebs;                             -- 35 : SourceSystemOwner（ソース・システム所有者）
      lv_file_data := lv_file_data || cv_pipe || l_worker_rec.person_id;             -- 36 : SourceSystemId（ソース・システムID）
      --
      BEGIN
        -- データ行のファイル出力
        UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- 従業員情報連携データファイル
                         , lv_file_data
                         );
        -- 出力件数カウントアップ
        gn_out_wk_cnt := gn_out_wk_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    --
    END LOOP output_worker_loop;
--
    -- 抽出件数が1件以上ある場合
    IF ( gn_get_wk_cnt > 0 ) THEN
      BEGIN
        -- 空行をファイル出力
        UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- 従業員情報連携データファイル
                         , ''
                         );
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    END IF;
--
    -- カーソルクローズ
    CLOSE worker_cur;
--
--
    -- ==============================================================
    -- 個人名の抽出(A-2-3)
    -- ==============================================================
    -- カーソルオープン
    OPEN per_name_cur;
    <<output_per_name_loop>>
    LOOP
      --
      FETCH per_name_cur INTO l_per_name_rec;
      EXIT WHEN per_name_cur%NOTFOUND;
      --
      -- 抽出件数カウントアップ
      gn_get_per_name_cnt := gn_get_per_name_cnt + 1;
      --
      -- ==============================================================
      -- 個人名のファイル出力(A-2-4)
      -- ==============================================================
      -- ヘッダー行の作成（初回のみ）
      IF ( gn_get_per_name_cnt = 1 ) THEN
        --
        BEGIN
          -- ヘッダー行のファイル出力
          UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- 従業員情報連携データファイル
                           , cv_per_name_header
                           );
        EXCEPTION
          WHEN OTHERS THEN
            RAISE global_fileout_expt;
        END;
      END IF;
      --
      -- データ行の作成
      lv_file_data := cv_meta_merge;                                                      --  1 : METADATA
      lv_file_data := lv_file_data || cv_pipe || cv_cls_per_name;                         --  2 : PersonName
      lv_file_data := lv_file_data || cv_pipe || l_per_name_rec.employee_number;          --  3 : PersonNumber（個人番号）
      lv_file_data := lv_file_data || cv_pipe || cv_global;                               --  4 : NameType（名前タイプ）
      lv_file_data := lv_file_data || cv_pipe || l_per_name_rec.effective_start_date;     --  5 : EffectiveStartDate（有効開始日）
      lv_file_data := lv_file_data || cv_pipe || cv_jp;                                   --  6 : LegislationCode（国別仕様コード）
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_per_name_rec.first_name
                                 , l_per_name_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       --  7 : FirstName（名）
      lv_file_data := lv_file_data || cv_pipe || l_per_name_rec.last_name;                --  8 : LastName（姓）
      lv_file_data := lv_file_data || cv_pipe || l_per_name_rec.per_information18;        --  9 : NameInformation1（名前情報1）
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_per_name_rec.per_information19
                                 , l_per_name_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 10 : NameInformation2（名前情報2）
      lv_file_data := lv_file_data || cv_pipe || cv_ebs;                                  -- 11 : SourceSystemOwner（ソース・システム所有者）
      lv_file_data := lv_file_data || cv_pipe || l_per_name_rec.person_id;                -- 12 : SourceSystemId（ソース・システムID）
      --
      BEGIN
        -- データ行のファイル出力
        UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- 従業員情報連携データファイル
                         , lv_file_data
                         );
        -- 出力件数カウントアップ
        gn_out_wk_cnt := gn_out_wk_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    --
    END LOOP output_per_name_loop;
    --
    -- 抽出件数が1件以上ある場合
    IF ( gn_get_per_name_cnt > 0 ) THEN
      BEGIN
        -- 空行挿入
        UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- 従業員情報連携データファイル
                         , ''
                         );
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    END IF;
--
    -- カーソルクローズ
    CLOSE per_name_cur;
--
--
    -- ==============================================================
    -- 個人国別仕様データの抽出(A-2-5)
    -- ==============================================================
    -- カーソルオープン
    OPEN per_legi_cur;
    <<output_per_legi_loop>>
    LOOP
      --
      FETCH per_legi_cur INTO l_per_legi_rec;
      EXIT WHEN per_legi_cur%NOTFOUND;
      --
      -- 抽出件数カウントアップ
      gn_get_per_legi_cnt := gn_get_per_legi_cnt + 1;
      --
      -- ==============================================================
      -- 個人国別仕様データのファイル出力(A-2-6)
      -- ==============================================================
      -- ヘッダー行の作成（初回のみ）
      IF ( gn_get_per_legi_cnt = 1 ) THEN
        --
        BEGIN
          -- ヘッダー行のファイル出力
          UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- 従業員情報連携データファイル
                           , cv_per_legi_header
                           );
        EXCEPTION
          WHEN OTHERS THEN
            RAISE global_fileout_expt;
        END;
      END IF;
      --
      -- データ行の作成
      lv_file_data := cv_meta_merge;                                                      -- 1 : METADATA
      lv_file_data := lv_file_data || cv_pipe || cv_cls_per_legi;                         -- 2 : PersonLegislativeData
      lv_file_data := lv_file_data || cv_pipe || l_per_legi_rec.employee_number;          -- 3 : PersonNumber（個人番号）
      lv_file_data := lv_file_data || cv_pipe || cv_jp;                                   -- 4 : LegislationCode（国別仕様コード）
      lv_file_data := lv_file_data || cv_pipe || l_per_legi_rec.effective_start_date;     -- 5 : EffectiveStartDate（有効開始日）
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_per_legi_rec.sex
                                 , l_per_legi_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 6 : Sex（性別）
      lv_file_data := lv_file_data || cv_pipe || cv_ebs;                                  -- 7 : SourceSystemOwner（ソース・システム所有者）
      lv_file_data := lv_file_data || cv_pipe || l_per_legi_rec.person_id;                -- 8 : SourceSystemId（ソース・システムID）
      --
      BEGIN
        -- データ行のファイル出力
        UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- 従業員情報連携データファイル
                         , lv_file_data
                         );
        -- 出力件数カウントアップ
        gn_out_wk_cnt := gn_out_wk_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    --
    END LOOP output_per_legi_loop;
--
    -- 抽出件数が1件以上ある場合
    IF ( gn_get_per_legi_cnt > 0 ) THEN
      BEGIN
        -- 空行をファイル出力
        UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- 従業員情報連携データファイル
                         , ''
                         );
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    END IF;
--
    -- カーソルクローズ
    CLOSE per_legi_cur;
--
--
    -- ==============================================================
    -- 個人Eメールの抽出(A-2-7)
    -- ==============================================================
    -- カーソルオープン
    OPEN per_email_cur;
    <<output_per_email_loop>>
    LOOP
      --
      FETCH per_email_cur INTO l_per_email_rec;
      EXIT WHEN per_email_cur%NOTFOUND;
      --
      -- 抽出件数カウントアップ
      gn_get_per_email_cnt := gn_get_per_email_cnt + 1;
      --
      -- ==============================================================
      -- 個人Eメールのファイル出力(A-2-8)
      -- ==============================================================
      -- ヘッダー行の作成（初回のみ）
      IF ( gn_get_per_email_cnt = 1 ) THEN
        --
        BEGIN
          -- ヘッダー行のファイル出力
          UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- 従業員情報連携データファイル
                           , cv_per_email_header
                           );
        EXCEPTION
          WHEN OTHERS THEN
            RAISE global_fileout_expt;
        END;
      END IF;
      --
      -- データ行の作成
      lv_file_data := cv_meta_merge;                                                      -- 1 : METADATA
      lv_file_data := lv_file_data || cv_pipe || cv_cls_per_email;                        -- 2 : PersonEmail
      lv_file_data := lv_file_data || cv_pipe || l_per_email_rec.email_address;           -- 3 : EmailAddress（Eメール・アドレス）
      lv_file_data := lv_file_data || cv_pipe || cv_w1;                                   -- 4 : EmailType（Eメール・タイプ）
      lv_file_data := lv_file_data || cv_pipe || l_per_email_rec.employee_number;         -- 5 : PersonNumber（個人番号）
      lv_file_data := lv_file_data || cv_pipe || l_per_email_rec.effective_start_date;    -- 6 : DateFrom（日付: 自）
      lv_file_data := lv_file_data || cv_pipe || cv_ebs;                                  -- 7 : SourceSystemOwner（ソース・システム所有者）
      lv_file_data := lv_file_data || cv_pipe || l_per_email_rec.person_id;               -- 8 : SourceSystemId（ソース・システムID）
      --
      BEGIN
        -- データ行のファイル出力
        UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- 従業員情報連携データファイル
                         , lv_file_data
                         );
        -- 出力件数カウントアップ
        gn_out_wk_cnt := gn_out_wk_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    --
    END LOOP output_per_email_loop;
--
    -- 抽出件数が1件以上ある場合
    IF ( gn_get_per_email_cnt > 0 ) THEN
      BEGIN
        -- 空行をファイル出力
        UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- 従業員情報連携データファイル
                         , ''
                         );
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    END IF;
--
    -- カーソルクローズ
    CLOSE per_email_cur;
--
--
    -- ==============================================================
    -- 雇用関係（退職者）の抽出(A-2-9)
    -- ==============================================================
    -- カーソルオープン
    OPEN wk_rel_cur;
    <<output_wk_rel_loop>>
    LOOP
      --
      FETCH wk_rel_cur INTO l_wk_rel_rec;
      EXIT WHEN wk_rel_cur%NOTFOUND;
      --
      -- 抽出件数カウントアップ
      gn_get_wk_rel_cnt := gn_get_wk_rel_cnt + 1;
      --
      -- ==============================================================
      -- 雇用関係（退職者）のファイル出力(A-2-10)
      -- ==============================================================
      -- ヘッダー行の作成（初回のみ）
      IF ( gn_get_wk_rel_cnt = 1 ) THEN
        --
        BEGIN
          -- ヘッダー行のファイル出力
          UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- 従業員情報連携データファイル
                           , cv_wk_rel_header
                           );
        EXCEPTION
          WHEN OTHERS THEN
            RAISE global_fileout_expt;
        END;
      END IF;
      --
      -- データ行の作成
      lv_file_data := cv_meta_merge;                                                      --  1 : METADATA
      lv_file_data := lv_file_data || cv_pipe || cv_cls_wk_rel;                           --  2 : WorkRelationship
      lv_file_data := lv_file_data || cv_pipe || l_wk_rel_rec.employee_number;            --  3 : PersonNumber（個人番号）
      lv_file_data := lv_file_data || cv_pipe || cv_wk_type_e;                            --  4 : WorkerType（就業者タイプ）
      lv_file_data := lv_file_data || cv_pipe || l_wk_rel_rec.date_start;                 --  5 : DateStart（開始日）
      lv_file_data := lv_file_data || cv_pipe || cv_sales_le;                             --  6 : LegalEmployerName（雇用主）
      lv_file_data := lv_file_data || cv_pipe || cv_y;                                    --  7 : PrimaryFlag（プライマリ雇用）
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_wk_rel_rec.actual_termination_date
                                 , l_wk_rel_rec.new_reg_flag
                                 , cv_nvl_d
                                 );                                                       --  8 : ActualTerminationDate（実績退職日）
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_wk_rel_rec.terminate_work_rel_flag
                                 , l_wk_rel_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       --  9 : TerminateWorkRelationshipFlag（雇用関係の終了）
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_wk_rel_rec.reverse_termination_flag
                                 , l_wk_rel_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 10 : ReverseTerminationFlag（退職の取消）
      lv_file_data := lv_file_data || cv_pipe || l_wk_rel_rec.action_code;                -- 11 : ActionCode（処理コード）
      lv_file_data := lv_file_data || cv_pipe || cv_ebs;                                  -- 12 : SourceSystemOwner（ソース・システム所有者）
      lv_file_data := lv_file_data || cv_pipe || l_wk_rel_rec.period_of_service_id;       -- 13 : SourceSystemId（ソース・システムID）
      --
      BEGIN
        -- データ行のファイル出力
        UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- 従業員情報連携データファイル
                         , lv_file_data
                         );
        -- 出力件数カウントアップ
        gn_out_wk_cnt := gn_out_wk_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    --
    END LOOP output_wk_rel_loop;
--
    -- 抽出件数が1件以上ある場合
    IF ( gn_get_wk_rel_cnt > 0 ) THEN
      BEGIN
        -- 空行をファイル出力
        UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- 従業員情報連携データファイル
                         , ''
                         );
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    END IF;
--
    -- カーソルクローズ
    CLOSE wk_rel_cur;
--
--
    -- ==============================================================
    -- ユーザー情報（新規）の抽出(A-2-11)
    -- ==============================================================
    -- カーソルオープン
    OPEN new_user_cur;
    <<output_new_user_loop>>
    LOOP
      --
      FETCH new_user_cur INTO l_new_user_rec;
      EXIT WHEN new_user_cur%NOTFOUND;
      --
      -- 抽出件数カウントアップ
      gn_get_new_user_cnt      := gn_get_new_user_cnt + 1;
-- Ver1.15 Del Start
--      gn_get_new_user_paas_cnt := gn_get_new_user_paas_cnt + 1;
-- Ver1.15 Del End
      --
      -- ==============================================================
      -- ユーザー情報（新規）のファイル出力(A-2-12)
      -- ==============================================================
      -- ヘッダー行の作成（初回のみ）
      IF ( gn_get_new_user_cnt = 1 ) THEN
        --
        BEGIN
          -- ヘッダー行のファイル出力
          UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- 従業員情報連携データファイル
                           , cv_per_user_header
                           );
        EXCEPTION
          WHEN OTHERS THEN
            RAISE global_fileout_expt;
        END;
      END IF;
      --
      -- データ行の作成
      lv_file_data := cv_meta_merge;                                                          -- 1 : METADATA
      lv_file_data := lv_file_data || cv_pipe || cv_cls_per_user;                             -- 2 : PersonUserInformation
      lv_file_data := lv_file_data || cv_pipe || l_new_user_rec.user_name;                    -- 3 : UserName（ユーザー名）
      lv_file_data := lv_file_data || cv_pipe || l_new_user_rec.employee_number;              -- 4 : PersonNumber（個人番号）
      lv_file_data := lv_file_data || cv_pipe || l_new_user_rec.start_date;                   -- 5 : StartDate（開始日）
      lv_file_data := lv_file_data || cv_pipe || l_new_user_rec.generated_user_account_flag;  -- 6 : GeneratedUserAccountFlag（生成済ユーザー・アカウント）
      lv_file_data := lv_file_data || cv_pipe || cv_n;                                        -- 7 : SendCredentialsEmailFlag（資格証明Eメールの送信）
      --
      BEGIN
        -- データ行のファイル出力
        UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- 従業員情報連携データファイル
                         , lv_file_data
                         );
        -- 出力件数カウントアップ
        gn_out_wk_cnt := gn_out_wk_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
      --
-- Ver1.15 Del Start
--      -- ==============================================================
--      -- PaaS処理用の新規ユーザー情報のファイル出力(A-2-13)
--      -- ==============================================================
--      IF (l_new_user_rec.generated_user_account_flag = cv_y) THEN
--        -- 生成済ユーザー・アカウントがYの場合（ユーザーマスタが存在する場合）
--        -- データ行の作成
--        lv_file_data := xxccp_oiccommon_pkg.to_csv_string( l_new_user_rec.user_name , cv_space );  -- 1 : ユーザー名
--        lv_file_data := lv_file_data || cv_comma ||
--                        xxccp_oiccommon_pkg.to_csv_string( gt_prf_val_password      , cv_space );  -- 2 : 初期パスワード
--        --
--        BEGIN
--          -- データ行のファイル出力
--          UTL_FILE.PUT_LINE( gf_new_usr_file_handle  -- PaaS処理用の新規ユーザー情報ファイル
--                           , lv_file_data
--                           );
--          -- 出力件数カウントアップ
--          gn_out_p_new_user_cnt := gn_out_p_new_user_cnt + 1;
--        EXCEPTION
--          WHEN OTHERS THEN
--            RAISE global_fileout_expt;
--        END;
--      ELSE
--        -- 生成済ユーザー・アカウントがNの場合（ユーザーマスタが存在しない場合）
--        -- スキップ件数をカウントアップ
--        gn_warn_cnt := gn_warn_cnt + 1;
--      END IF;
-- Ver1.15 Del End
    --
    END LOOP output_new_user_loop;
--
    -- 抽出件数が1件以上ある場合
    IF ( gn_get_new_user_cnt > 0 ) THEN
      BEGIN
        -- 空行をファイル出力
        UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- 従業員情報連携データファイル
                         , ''
                         );
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    END IF;
--
    -- カーソルクローズ
    CLOSE new_user_cur;
--
--
    -- ==============================================================
    -- 雇用条件の抽出(A-2-14)
    -- ==============================================================
    -- カーソルオープン
    OPEN wk_terms_cur;
    <<output_wk_terms_loop>>
    LOOP
      --
      FETCH wk_terms_cur INTO l_wk_terms_rec;
      EXIT WHEN wk_terms_cur%NOTFOUND;
      --
      -- 抽出件数カウントアップ
      gn_get_wk_terms_cnt := gn_get_wk_terms_cnt + 1;
      --
      -- ==============================================================
      -- 雇用条件のファイル出力(A-2-15)
      -- ==============================================================
      -- ヘッダー行の作成
      BEGIN
        IF ( l_wk_terms_rec.sup_chg_flag = cv_n AND lv_wt_header_wrk = cv_n ) THEN
          -- 上長変更なし、かつヘッダー行が未作成の場合
          -- ヘッダー行のファイル出力
          UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- 従業員情報連携データファイル
                           , cv_wk_terms_header
                           );
          --
          -- ヘッダー行作成済
          lv_wt_header_wrk := cv_y;
        ELSIF ( l_wk_terms_rec.sup_chg_flag = cv_y AND lv_wt_header_wrk2 = cv_n ) THEN
          -- 上長変更あり、かつヘッダー行が未作成の場合
          -- ヘッダー行のファイル出力
          UTL_FILE.PUT_LINE( gf_wrk2_file_handle  -- 従業員情報（上長・新規採用退職者）連携データファイル
                           , cv_wk_terms_header
                           );
          --
          -- ヘッダー行作成済
          lv_wt_header_wrk2 := cv_y;
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
      --
      -- データ行の作成
      lv_file_data := cv_meta_merge;                                                      --  1 : METADATA
      lv_file_data := lv_file_data || cv_pipe || cv_cls_wk_terms;                         --  2 : WorkTerms
      lv_file_data := lv_file_data || cv_pipe || l_wk_terms_rec.assignment_number;        --  3 : AssignmentNumber（アサイメント番号）
      lv_file_data := lv_file_data || cv_pipe || l_wk_terms_rec.employee_number;          --  4 : PersonNumber（個人番号）
      lv_file_data := lv_file_data || cv_pipe || cv_wk_type_e;                            --  5 : WorkerType（就業者タイプ）
      lv_file_data := lv_file_data || cv_pipe || l_wk_terms_rec.start_date;               --  6 : DateStart（開始日）
      lv_file_data := lv_file_data || cv_pipe || cv_sales_le;                             --  7 : LegalEmployerName（雇用主名）
      lv_file_data := lv_file_data || cv_pipe || cv_y;                                    --  8 : EffectiveLatestChange（有効最終変更）
      lv_file_data := lv_file_data || cv_pipe || l_wk_terms_rec.effective_start_date;     --  9 : EffectiveStartDate（有効開始日）
      lv_file_data := lv_file_data || cv_pipe || cv_seq_1;                                -- 10 : EffectiveSequence（有効順序）
      lv_file_data := lv_file_data || cv_pipe || cv_ass_status_act;                       -- 11 : AssignmentStatusTypeCode（アサイメント・ステータス・タイプ）
      lv_file_data := lv_file_data || cv_pipe || cv_ass_type_et;                          -- 12 : AssignmentType（アサイメント・タイプ）
      lv_file_data := lv_file_data || cv_pipe || l_wk_terms_rec.assignment_name;          -- 13 : AssignmentName（アサイメント名）
      lv_file_data := lv_file_data || cv_pipe || cv_sys_per_type_emp;                     -- 14 : SystemPersonType（システムPersonタイプ）
      lv_file_data := lv_file_data || cv_pipe || cv_sales_bu;                             -- 15 : BusinessUnitShortCode（ビジネス・ユニット）
      lv_file_data := lv_file_data || cv_pipe || l_wk_terms_rec.action_code;              -- 16 : ActionCode（処理コード）
      lv_file_data := lv_file_data || cv_pipe || cv_y;                                    -- 17 : PrimaryWorkTermsFlag（雇用関係のプライマリ雇用条件）
      lv_file_data := lv_file_data || cv_pipe || cv_ebs;                                  -- 18 : SourceSystemOwner（ソース・システム所有者）
      lv_file_data := lv_file_data || cv_pipe || l_wk_terms_rec.source_system_id;         -- 19 : SourceSystemId（ソース・システムID）
      --
      BEGIN
        IF ( l_wk_terms_rec.sup_chg_flag = cv_n ) THEN
          -- 上長変更なし
          -- データ行のファイル出力
          UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- 従業員情報連携データファイル
                           , lv_file_data
                           );
          -- 出力件数カウントアップ
          gn_out_wk_cnt := gn_out_wk_cnt + 1;
        ELSE
          -- 上長変更あり
          -- データ行のファイル出力
          UTL_FILE.PUT_LINE( gf_wrk2_file_handle  -- 従業員情報（上長・新規採用退職者）連携データファイル
                           , lv_file_data
                           );
          -- 出力件数カウントアップ
          gn_out_wk2_cnt := gn_out_wk2_cnt + 1;
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    --
    END LOOP output_wk_terms_loop;
--
    BEGIN
      -- ヘッダー行を出力している場合
      IF ( lv_wt_header_wrk = cv_y ) THEN
        -- 空行をファイル出力
        UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- 従業員情報連携データファイル
                         , ''
                         );
      END IF;
      --
      IF ( lv_wt_header_wrk2 = cv_y ) THEN
        -- 空行をファイル出力
        UTL_FILE.PUT_LINE( gf_wrk2_file_handle  -- 従業員情報（上長・新規採用退職者）連携データファイル
                         , ''
                         );
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_fileout_expt;
    END;
--
    -- カーソルクローズ
    CLOSE wk_terms_cur;
--
--
    -- ==============================================================
    -- アサイメント情報の抽出(A-2-16)
    -- ==============================================================
    -- カーソルオープン
    OPEN ass_cur;
    <<output_ass_loop>>
    LOOP
      --
      FETCH ass_cur INTO l_ass_rec;
      EXIT WHEN ass_cur%NOTFOUND;
      --
      -- 抽出件数カウントアップ
      gn_get_ass_cnt := gn_get_ass_cnt + 1;
      --
      -- ==============================================================
      -- アサイメント情報のファイル出力(A-2-17)
      -- ==============================================================
      -- ヘッダー行の作成
      BEGIN
        IF ( l_ass_rec.sup_chg_flag = cv_n AND lv_ass_header_wrk = cv_n ) THEN
          -- 上長変更なし、かつヘッダー行が未作成の場合
          -- ヘッダー行のファイル出力
          UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- 従業員情報連携データファイル
                           , cv_ass_header
                           );
          --
          -- ヘッダー行作成済
          lv_ass_header_wrk := cv_y;
        ELSIF ( l_ass_rec.sup_chg_flag = cv_y AND lv_ass_header_wrk2 = cv_n ) THEN
          -- 上長変更あり、かつヘッダー行が未作成の場合
          -- ヘッダー行のファイル出力
          UTL_FILE.PUT_LINE( gf_wrk2_file_handle  -- 従業員情報（上長・新規採用退職者）連携データファイル
                           , cv_ass_header
                           );
          --
          -- ヘッダー行作成済
          lv_ass_header_wrk2 := cv_y;
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
      --
      -- データ行の作成
      lv_file_data :=                            cv_meta_merge;                           --  1 : METADATA
      lv_file_data := lv_file_data || cv_pipe || cv_cls_assignment;                       --  2 : Assignment
      lv_file_data := lv_file_data || cv_pipe || cv_per_asg_df;                           --  3 : FLEX:PER_ASG_DF（コンテキスト）
      lv_file_data := lv_file_data || cv_pipe || l_ass_rec.assignment_number;             --  4 : AssignmentNumber（アサイメント番号）
      lv_file_data := lv_file_data || cv_pipe || l_ass_rec.work_terms_number;             --  5 : WorkTermsNumber（勤務条件番号）
      lv_file_data := lv_file_data || cv_pipe || cv_y;                                    --  6 : EffectiveLatestChange（有効最終変更）
      lv_file_data := lv_file_data || cv_pipe || l_ass_rec.effective_start_date;          --  7 : EffectiveStartDate（有効開始日）
      lv_file_data := lv_file_data || cv_pipe || cv_seq_1;                                --  8 : EffectiveSequence（有効順序）
      lv_file_data := lv_file_data || cv_pipe || cv_per_type_employee;                    --  9 : PersonTypeCode（Personタイプ）
      lv_file_data := lv_file_data || cv_pipe || cv_ass_status_act;                       -- 10 : AssignmentStatusTypeCode（アサイメント・ステータス・タイプ）
      lv_file_data := lv_file_data || cv_pipe || l_ass_rec.assignment_type;               -- 11 : AssignmentType（アサイメント・タイプ）
      lv_file_data := lv_file_data || cv_pipe || cv_sys_per_type_emp;                     -- 12 : SystemPersonType（システムPersonタイプ）
      lv_file_data := lv_file_data || cv_pipe || l_ass_rec.assignment_number;             -- 13 : AssignmentName（アサイメント名）
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.job_code
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 14 : JobCode（ジョブ・コード）
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.default_expense_account
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 15 : DefaultExpenseAccount（デフォルト費用勘定）
      lv_file_data := lv_file_data || cv_pipe || cv_sales_bu;                             -- 16 : BusinessUnitShortCode（ビジネス・ユニット）
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.manager_flag
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 17 : ManagerFlag（マネージャ）
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.location_code
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 18 : LocationCode（事業所コード）
      lv_file_data := lv_file_data || cv_pipe || l_ass_rec.employee_number;               -- 19 : PersonNumber（個人番号）
      lv_file_data := lv_file_data || cv_pipe || l_ass_rec.action_code;                   -- 20 : ActionCode（処理コード）
      lv_file_data := lv_file_data || cv_pipe || cv_wk_type_e;                            -- 21 : WorkerType（就業者タイプ）
      lv_file_data := lv_file_data || cv_pipe || NULL;                                    -- 22 : DepartmentName（部門）
      lv_file_data := lv_file_data || cv_pipe || l_ass_rec.start_date;                    -- 23 : DateStart（開始日）
      lv_file_data := lv_file_data || cv_pipe || cv_sales_le;                             -- 24 : LegalEmployerName（雇用主名）
      lv_file_data := lv_file_data || cv_pipe || l_ass_rec.primary_flag;                  -- 25 : PrimaryAssignmentFlag（雇用関係のプライマリ・アサイメント）
                                                                                          --      (↓PER_ASG_DF=ITO_SALES_USE_ITEM)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute1
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 26 : transferReasonCode（異動事由コード)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute2
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 27 : announceDate（発令日)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute3
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 28 : workLocDepartmentNew（勤務地拠点コード（新）)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute4
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 29 : workLocDepartmentOld（勤務地拠点コード（旧）)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute5
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 30 : departmentNew（拠点コード（新））
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute6
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 31 : departmentOld（拠点コード（旧）)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute7
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 32 : appWorkTimeCodeNew（適用労働時間制コード（新）)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute8
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 33 : appWorkTimeNameNew（適用労働名（新）)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute9
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 34 : appWorkTimeCodeOld（適用労働時間制コード（旧）)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute10
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 35 : appWorkTimeNameOld（適用労働名（旧）)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute11
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 36 : positionSortCodeNew（職位並順コード（新）)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute12
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 37 : positionSortCodeOld（職位並順コード（旧）)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute13
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 38 : approvalClassNew（承認区分（新）)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute14
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 39 : approvalClassOld（承認区分（旧））
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute15
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 40 : alternateClassNew（代行区分（新）)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute16
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 41 : alternateClassOld（代行区分（旧）)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute17
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 42 : transferDateVend（差分連携用日付（自販機）)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute18
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 43 : transferDateRep（差分連携用日付（帳票）)
                                                                                          --      (↑PER_ASG_DF=ITO_SALES_USE_ITEM)
      lv_file_data := lv_file_data || cv_pipe || cv_ebs;                                  -- 44 : SourceSystemOwner（ソース・システム所有者）
      lv_file_data := lv_file_data || cv_pipe || l_ass_rec.source_system_id;              -- 45 : SourceSystemId（ソース・システムID）
      --
      BEGIN
        IF ( l_ass_rec.sup_chg_flag = cv_n ) THEN
          -- 上長変更なし
          -- データ行のファイル出力
          UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- 従業員情報連携データファイル
                           , lv_file_data
                           );
          -- 出力件数カウントアップ
          gn_out_wk_cnt := gn_out_wk_cnt + 1;
        ELSE
          -- 上長変更あり
          -- データ行のファイル出力
          UTL_FILE.PUT_LINE( gf_wrk2_file_handle  -- 従業員情報（上長・新規採用退職者）連携データファイル
                           , lv_file_data
                           );
          -- 出力件数カウントアップ
          gn_out_wk2_cnt := gn_out_wk2_cnt + 1;
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    --
    END LOOP output_ass_loop;
--
    BEGIN
      -- ヘッダー行を出力している場合
      IF ( lv_ass_header_wrk2 = cv_y ) THEN
        -- 空行をファイル出力
        UTL_FILE.PUT_LINE( gf_wrk2_file_handle  -- 従業員情報（上長・新規採用退職者）連携データファイル
                         , ''
                         );
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_fileout_expt;
    END;
--
    -- カーソルクローズ
    CLOSE ass_cur;
--
--
  EXCEPTION
    -- *** ファイル出力時例外ハンドラ ***
    WHEN global_fileout_expt THEN
      -- カーソルクローズ
      IF ( worker_cur%ISOPEN )    THEN CLOSE worker_cur;    END IF;
      IF ( per_name_cur%ISOPEN )  THEN CLOSE per_name_cur;  END IF;
      IF ( per_legi_cur%ISOPEN )  THEN CLOSE per_legi_cur;  END IF;
      IF ( per_email_cur%ISOPEN ) THEN CLOSE per_email_cur; END IF;
      IF ( wk_rel_cur%ISOPEN )    THEN CLOSE wk_rel_cur;    END IF;
      IF ( new_user_cur%ISOPEN )  THEN CLOSE new_user_cur;  END IF;
      IF ( wk_terms_cur%ISOPEN )  THEN CLOSE wk_terms_cur;  END IF;
      IF ( ass_cur%ISOPEN )       THEN CLOSE ass_cur;       END IF;
      --
      lv_errmsg := SUBSTRB(
                     xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_xxcmm             -- アプリケーション短縮名：XXCMM
                     , iv_name         => cv_file_write_err_msg     -- メッセージ名：ファイル書き込みエラーメッセージ
                     , iv_token_name1  => cv_tkn_sqlerrm            -- トークン名1：SQLERRM
                     , iv_token_value1 => SQLERRM                   -- トークン値1：SQLERRM
                     )
                   , 1
                   , 5000
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- カーソルクローズ
      IF ( worker_cur%ISOPEN )    THEN CLOSE worker_cur;    END IF;
      IF ( per_name_cur%ISOPEN )  THEN CLOSE per_name_cur;  END IF;
      IF ( per_legi_cur%ISOPEN )  THEN CLOSE per_legi_cur;  END IF;
      IF ( per_email_cur%ISOPEN ) THEN CLOSE per_email_cur; END IF;
      IF ( wk_rel_cur%ISOPEN )    THEN CLOSE wk_rel_cur;    END IF;
      IF ( new_user_cur%ISOPEN )  THEN CLOSE new_user_cur;  END IF;
      IF ( wk_terms_cur%ISOPEN )  THEN CLOSE wk_terms_cur;  END IF;
      IF ( ass_cur%ISOPEN )       THEN CLOSE ass_cur;       END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルクローズ
      IF ( worker_cur%ISOPEN )    THEN CLOSE worker_cur;    END IF;
      IF ( per_name_cur%ISOPEN )  THEN CLOSE per_name_cur;  END IF;
      IF ( per_legi_cur%ISOPEN )  THEN CLOSE per_legi_cur;  END IF;
      IF ( per_email_cur%ISOPEN ) THEN CLOSE per_email_cur; END IF;
      IF ( wk_rel_cur%ISOPEN )    THEN CLOSE wk_rel_cur;    END IF;
      IF ( new_user_cur%ISOPEN )  THEN CLOSE new_user_cur;  END IF;
      IF ( wk_terms_cur%ISOPEN )  THEN CLOSE wk_terms_cur;  END IF;
      IF ( ass_cur%ISOPEN )       THEN CLOSE ass_cur;       END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF ( worker_cur%ISOPEN )    THEN CLOSE worker_cur;    END IF;
      IF ( per_name_cur%ISOPEN )  THEN CLOSE per_name_cur;  END IF;
      IF ( per_legi_cur%ISOPEN )  THEN CLOSE per_legi_cur;  END IF;
      IF ( per_email_cur%ISOPEN ) THEN CLOSE per_email_cur; END IF;
      IF ( wk_rel_cur%ISOPEN )    THEN CLOSE wk_rel_cur;    END IF;
      IF ( new_user_cur%ISOPEN )  THEN CLOSE new_user_cur;  END IF;
      IF ( wk_terms_cur%ISOPEN )  THEN CLOSE wk_terms_cur;  END IF;
      IF ( ass_cur%ISOPEN )       THEN CLOSE ass_cur;       END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF ( worker_cur%ISOPEN )    THEN CLOSE worker_cur;    END IF;
      IF ( per_name_cur%ISOPEN )  THEN CLOSE per_name_cur;  END IF;
      IF ( per_legi_cur%ISOPEN )  THEN CLOSE per_legi_cur;  END IF;
      IF ( per_email_cur%ISOPEN ) THEN CLOSE per_email_cur; END IF;
      IF ( wk_rel_cur%ISOPEN )    THEN CLOSE wk_rel_cur;    END IF;
      IF ( new_user_cur%ISOPEN )  THEN CLOSE new_user_cur;  END IF;
      IF ( wk_terms_cur%ISOPEN )  THEN CLOSE wk_terms_cur;  END IF;
      IF ( ass_cur%ISOPEN )       THEN CLOSE ass_cur;       END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END output_worker;
--
--
  /**********************************************************************************
   * Procedure Name   : output_user
   * Description      : ユーザー情報の抽出・ファイル出力処理(A-3)
   ***********************************************************************************/
  PROCEDURE output_user(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_user';       -- プログラム名
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
    ------------------------------------
    --ヘッダー行(User)
    ------------------------------------
    cv_user_header   CONSTANT VARCHAR2(3000) :=
                    'METADATA'          -- 1 : METADATA
      || cv_pipe || 'User'              -- 2 : User
      || cv_pipe || 'PersonNumber'      -- 3 : PersonNumber（個人番号）
      || cv_pipe || 'Username'          -- 4 : Username（ユーザー名）
      || cv_pipe || 'Suspended'         -- 5 : Suspended（停止）
    ;
-- Ver1.2(E055) Add Start
    --
    ------------------------------------
    --ヘッダー行(User2)
    ------------------------------------
    cv_user2_header  CONSTANT VARCHAR2(3000) :=
                    'METADATA'               -- 1 : METADATA
      || cv_pipe || 'User'                   -- 2 : User
      || cv_pipe || 'PersonNumber'           -- 3 : PersonNumber（個人番号）
      || cv_pipe || 'CredentialsEmailSent'   -- 4 : CredentialsEmailSent（資格証明Eメール送信済）
    ;
-- Ver1.2(E055) Add End
--
    -- *** ローカル変数 ***
    lv_file_data         VARCHAR2(30000) DEFAULT NULL;       -- 出力内容
-- Ver1.17 Add Start
    lv_new_emp_flag      VARCHAR2(1);                        -- 新入社員フラグ
-- Ver1.17 Add End
--
    -- *** ローカル・カーソル ***
    --------------------------------------
    -- ユーザーの抽出カーソル
    --------------------------------------
    CURSOR user_cur
    IS
      SELECT
          papf.employee_number          AS employee_number      -- 従業員番号
        , fu.user_name                  AS user_name            -- ユーザー名
        , (CASE
             WHEN fu.end_date <= gt_if_dest_date THEN
               cv_y
             ELSE
               cv_n
           END)                         AS suspended            -- 停止
-- Ver1.17 Add Start
        , papf.person_id                AS person_id            -- 個人ID
-- Ver1.17 Add End
      FROM
          per_all_people_f  papf  -- 従業員マスタ
        , fnd_user          fu    -- ユーザーマスタ
      WHERE
          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external , cv_emp_kbn_dummy)  -- 従業員区分（1:内部、2:外部、4:ダミー）
      AND papf.attribute4 IS NULL    -- 仕入先コード
      AND papf.attribute5 IS NULL    -- 運送業者
      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- 従業員番号
      AND papf.effective_start_date = 
              (SELECT
                   MAX(papf2.effective_start_date)
               FROM
                   per_all_people_f  papf2 -- 従業員マスタ
               WHERE
                   papf2.person_id = papf.person_id
              )
      AND papf.person_id       = fu.employee_id
      AND NOT EXISTS
              (SELECT
                   1  AS flag
               FROM
                   xxcmm_oic_emp_diff_info   xoedi -- OIC社員差分情報テーブル
               WHERE
                   xoedi.person_id  = papf.person_id
               AND xoedi.user_name IS NULL
              )
-- Ver1.18 Mod Start
--      AND (   fu.last_update_date >= gt_pre_process_date
--           OR fu.end_date         = gt_if_dest_date)
      AND (   
            (     fu.last_update_date >= gt_pre_process_date
              AND fu.last_update_date <  gt_cur_process_date
            )
           OR     fu.end_date         = gt_if_dest_date
          )
-- Ver1.18 Mod End
      ORDER BY
          papf.employee_number ASC
    ;
-- Ver1.2(E055) Add Start
    --
    --------------------------------------
    -- ユーザー（削除）の抽出カーソル
    --------------------------------------
    CURSOR user2_cur
    IS
      SELECT
          papf.employee_number          AS employee_number      -- 従業員番号
      FROM
          per_all_people_f         papf  -- 従業員マスタ
-- Ver1.13 Add Start
        , po_vendors               pv    -- 仕入先マスタ
        , po_vendor_sites_all      pvsa  -- 仕入先サイトマスタ
-- Ver1.13 Add End
        , per_all_assignments_f    paaf  -- アサインメントマスタ
        , per_periods_of_service   ppos  -- 就業情報
      WHERE
          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external , cv_emp_kbn_dummy)  -- 従業員区分（1:内部、2:外部、4:ダミー）
      AND papf.attribute4 IS NULL    -- 仕入先コード
      AND papf.attribute5 IS NULL    -- 運送業者
      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- 従業員番号
      AND papf.effective_start_date = 
              (SELECT
                   MAX(papf2.effective_start_date)
               FROM
                   per_all_people_f  papf2 -- 従業員マスタ
               WHERE
                   papf2.person_id = papf.person_id
              )
-- Ver1.13 Add Start
      AND papf.person_id                = pv.employee_id(+)
      AND pv.vendor_type_lookup_code(+) = cv_vd_type_employee
      AND pv.vendor_id                  = pvsa.vendor_id(+)
      AND pvsa.vendor_site_code(+)      = cv_site_code_comp
-- Ver1.13 Add End
      AND papf.person_id            = paaf.person_id
      AND paaf.effective_start_date =
              (SELECT
                   MAX(paaf2.effective_start_date)
               FROM
                   per_all_assignments_f  paaf2  -- アサイメントマスタ
               WHERE
                   paaf2.person_id = paaf.person_id
              )
      AND paaf.period_of_service_id = ppos.period_of_service_id
      AND NOT EXISTS (
              SELECT
                  1 AS flag
              FROM
                  fnd_user  fu    -- ユーザーマスタ
              WHERE
                  fu.employee_id = papf.person_id
          )
-- Ver1.5 Mod Start
--      AND papf.creation_date < gt_pre_process_date
--      AND (   papf.last_update_date >= gt_pre_process_date
--           OR papf.attribute23      >= gv_str_pre_process_date
--           OR paaf.last_update_date >= gt_pre_process_date
--           OR paaf.ass_attribute19  >= gv_str_pre_process_date
--           OR ppos.last_update_date >= gt_pre_process_date
--          )
      AND (
            (    papf.creation_date >= gt_pre_process_date
             AND (   paaf.supervisor_id IS NOT NULL
                  OR actual_termination_date IS NOT NULL
                 )
            ) OR (
                 papf.creation_date < gt_pre_process_date
             AND (   papf.last_update_date >= gt_pre_process_date
                  OR papf.attribute23      >= gv_str_pre_process_date
-- Ver1.13 Add Start
                  OR pvsa.last_update_date >= gt_pre_process_date
-- Ver1.13 Add End
                  OR paaf.last_update_date >= gt_pre_process_date
                  OR paaf.ass_attribute19  >= gv_str_pre_process_date
                  OR ppos.last_update_date >= gt_pre_process_date
                 )
            )
          )
-- Ver1.5 Mod End
      ORDER BY
          papf.employee_number ASC
    ;
-- Ver1.2(E055) Add End
-- Ver1.17 Add Start
--
    --------------------------------------
    -- 新入社員情報の抽出カーソル
    --------------------------------------
    CURSOR new_emp_cur (
             in_person_id IN NUMBER
    )
    IS
      SELECT
          fu.user_name                                      AS user_name                    -- ユーザー名
        , papf.employee_number                              AS employee_number              -- 従業員番号
        , TO_CHAR(fu.start_date, cv_date_fmt)               AS start_date                   -- 開始日
        , cv_y                                              AS generated_user_account_flag  -- 生成済ユーザー・アカウント
        , papf.person_id                                    AS person_id                    -- 個人ID
      FROM
          per_all_people_f     papf  -- 従業員マスタ
        , fnd_user             fu    -- ユーザーマスタ
      WHERE
          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external , cv_emp_kbn_dummy)  -- 従業員区分（1:内部、2:外部、4:ダミー）
      AND papf.attribute4 IS NULL    -- 仕入先コード
      AND papf.attribute5 IS NULL    -- 運送業者
      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- 従業員番号
      AND papf.effective_start_date = 
              (SELECT
                   MAX(papf2.effective_start_date)
               FROM
                   per_all_people_f  papf2 -- 従業員マスタ
               WHERE
                   papf2.person_id = papf.person_id
              )
      AND papf.person_id     = fu.employee_id
-- Ver1.18 Mod Start
--      AND papf.creation_date >= gt_pre_process_date
--      AND fu.creation_date   >= gt_pre_process_date
      AND (
                papf.creation_date >= gt_pre_process_date
            AND papf.creation_date <  gt_cur_process_date
           )
      AND ( 
                fu.creation_date   >= gt_pre_process_date
            AND fu.creation_date   <  gt_cur_process_date
          )
-- Ver1.18 Mod End
      AND papf.person_id = in_person_id
      ORDER BY
          employee_number ASC
    ;
-- Ver1.17 Add End
--
    -- *** ローカル・レコード ***
    l_user_rec     user_cur%ROWTYPE;    -- ユーザーの抽出カーソルレコード
-- Ver1.2(E055) Add Start
    l_user2_rec    user2_cur%ROWTYPE;   -- ユーザー（削除）の抽出カーソルレコード
-- Ver1.2(E055) Add End
-- Ver1.17 Add Start
    l_new_emp_rec  new_emp_cur%ROWTYPE; -- 新入社員情報の抽出カーソルレコード
-- Ver1.17 Add End
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ==============================================================
    -- ユーザー情報の抽出(A-3-1)
    -- ==============================================================
    -- カーソルオープン
    OPEN user_cur;
    <<output_user_loop>>
    LOOP
      --
      FETCH user_cur INTO l_user_rec;
      EXIT WHEN user_cur%NOTFOUND;
      --
      -- 抽出件数カウントアップ
      gn_get_user_cnt := gn_get_user_cnt + 1;
      --
-- Ver1.17 Del Start
--      -- ==============================================================
--      -- ユーザー情報のファイル出力(A-3-2)
--      -- ==============================================================
      -- ヘッダー行の作成（初回のみ）
--      IF ( gn_get_user_cnt = 1 ) THEN
--        --
--        BEGIN
--          -- ヘッダー行のファイル出力
--          UTL_FILE.PUT_LINE( gf_usr_file_handle  -- ユーザー情報連携データファイル
--                           , cv_user_header
--                           );
--        EXCEPTION
--          WHEN OTHERS THEN
--            RAISE global_fileout_expt;
--        END;
--      END IF;
-- Ver1.17 Del End
      --
      -- データ行の作成
      lv_file_data := cv_meta_merge;                                                      -- 1 : METADATA
      lv_file_data := lv_file_data || cv_pipe || cv_cls_user;                             -- 2 : User
      lv_file_data := lv_file_data || cv_pipe || l_user_rec.employee_number;              -- 3 : PersonNumber（個人番号）
      lv_file_data := lv_file_data || cv_pipe || l_user_rec.user_name;                    -- 4 : Username（ユーザー名）
      lv_file_data := lv_file_data || cv_pipe || l_user_rec.suspended;                    -- 5 : Suspended（停止）
      --
-- Ver1.17 Mod Start
--      BEGIN
--        -- データ行のファイル出力
--        UTL_FILE.PUT_LINE( gf_usr_file_handle  -- ユーザー情報連携データファイル
--                         , lv_file_data
--                         );
--        -- 出力件数カウントアップ
--        gn_out_user_cnt := gn_out_user_cnt + 1;
      -- ==============================================================
      -- 新入社員情報の抽出(A-3-2)
      -- ==============================================================
-- Ver1.20 Add Start
      lv_new_emp_flag := cv_n;
-- Ver1.20 Add End

      -- カーソルオープン
      OPEN new_emp_cur (
             l_user_rec.person_id
           );
      <<output_new_emp_loop>>
      LOOP
        --
        FETCH new_emp_cur INTO l_new_emp_rec;
        EXIT WHEN new_emp_cur%NOTFOUND;
        --
          lv_new_emp_flag := cv_y;
          -- 一致する場合Yフラグをたてる
      END LOOP output_new_emp_loop;
--
      -- カーソルクローズ
      CLOSE new_emp_cur;
--
      -- ==============================================================
      -- ユーザー情報のファイル出力(A-3-3)
      -- ==============================================================
      BEGIN
        IF ( lv_new_emp_flag = cv_y ) THEN
          -- データ行のファイル出力しない
          gn_get_user_cnt := gn_get_user_cnt - 1;
        ELSE
          -- ヘッダー行の作成（2回目以降は出力しない）
          IF ( gn_get_user_cnt = 1 ) THEN
            --
            BEGIN
              -- ヘッダー行のファイル出力
              UTL_FILE.PUT_LINE( gf_usr_file_handle  -- ユーザー情報連携データファイル
                               , cv_user_header
                               );
            EXCEPTION
              WHEN OTHERS THEN
                RAISE global_fileout_expt;
            END;
          END IF;         
          -- データ行のファイル出力する
          UTL_FILE.PUT_LINE( gf_usr_file_handle  -- ユーザー情報連携データファイル
                           , lv_file_data
                           );
          -- 出力件数カウントアップ
          gn_out_user_cnt := gn_out_user_cnt + 1;
        END IF;
-- Ver1.17 Mod End
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    --
    END LOOP output_user_loop;
--
    -- カーソルクローズ
    CLOSE user_cur;
--
-- Ver1.14 Del Start
---- Ver1.2(E055) Add Start
--    -- ==============================================================
--    -- ユーザー情報（削除）の抽出(A-3-3)
--    -- ==============================================================
--    -- カーソルオープン
--    OPEN user2_cur;
--    <<output_user2_loop>>
--    LOOP
--      --
--      FETCH user2_cur INTO l_user2_rec;
--      EXIT WHEN user2_cur%NOTFOUND;
--      --
--      -- 抽出件数カウントアップ
--      gn_get_user2_cnt := gn_get_user2_cnt + 1;
--      --
--      -- ==============================================================
--      -- ユーザー情報（削除）のファイル出力(A-3-4)
--      -- ==============================================================
--      -- ヘッダー行の作成（初回のみ）
--      IF ( gn_get_user2_cnt = 1 ) THEN
--        --
--        BEGIN
--          -- ヘッダー行のファイル出力
--          UTL_FILE.PUT_LINE( gf_usr2_file_handle  -- ユーザー情報（削除）連携データファイル
--                           , cv_user2_header
--                           );
--        EXCEPTION
--          WHEN OTHERS THEN
--            RAISE global_fileout_expt;
--        END;
--      END IF;
--      --
--      -- データ行の作成
--      lv_file_data := cv_meta_delete;                                                     -- 1 : METADATA
--      lv_file_data := lv_file_data || cv_pipe || cv_cls_user;                             -- 2 : User
--      lv_file_data := lv_file_data || cv_pipe || l_user2_rec.employee_number;             -- 3 : PersonNumber（個人番号）
--      lv_file_data := lv_file_data || cv_pipe || cv_y;                                    -- 4 : CredentialsEmailSent（資格証明Eメール送信済）
--      --
--      BEGIN
--        -- データ行のファイル出力
--        UTL_FILE.PUT_LINE( gf_usr2_file_handle  -- ユーザー情報（削除）連携データファイル
--                         , lv_file_data
--                         );
--        -- 出力件数カウントアップ
--        gn_out_user2_cnt := gn_out_user2_cnt + 1;
--      EXCEPTION
--        WHEN OTHERS THEN
--          RAISE global_fileout_expt;
--      END;
--    --
--    END LOOP output_user2_loop;
----
--    -- カーソルクローズ
--    CLOSE user2_cur;
---- Ver1.2(E055) Add End
-- Ver1.14 Del End
--
  EXCEPTION
    -- *** ファイル出力時例外ハンドラ ***
    WHEN global_fileout_expt THEN
      -- カーソルクローズ
      IF ( user_cur%ISOPEN ) THEN
        CLOSE user_cur;
      END IF;
-- Ver1.2(E055) Add Start
      -- カーソルクローズ
      IF ( user2_cur%ISOPEN ) THEN
        CLOSE user2_cur;
      END IF;
-- Ver1.2(E055) Add End
-- Ver1.17 Add Start
      -- カーソルクローズ
      IF ( new_emp_cur%ISOPEN ) THEN
        CLOSE new_emp_cur;
      END IF;
-- Ver1.17 Add End
      --
      lv_errmsg := SUBSTRB(
                     xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_xxcmm             -- アプリケーション短縮名：XXCMM
                     , iv_name         => cv_file_write_err_msg     -- メッセージ名：ファイル書き込みエラーメッセージ
                     , iv_token_name1  => cv_tkn_sqlerrm            -- トークン名1：SQLERRM
                     , iv_token_value1 => SQLERRM                   -- トークン値1：SQLERRM
                     )
                   , 1
                   , 5000
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- カーソルクローズ
      IF ( user_cur%ISOPEN ) THEN
        CLOSE user_cur;
      END IF;
-- Ver1.2(E055) Add Start
      -- カーソルクローズ
      IF ( user2_cur%ISOPEN ) THEN
        CLOSE user2_cur;
      END IF;
-- Ver1.2(E055) Add End
-- Ver1.17 Add Start
      -- カーソルクローズ
      IF ( new_emp_cur%ISOPEN ) THEN
        CLOSE new_emp_cur;
      END IF;
-- Ver1.17 Add End
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルクローズ
      IF ( user_cur%ISOPEN ) THEN
        CLOSE user_cur;
      END IF;
-- Ver1.2(E055) Add Start
      -- カーソルクローズ
      IF ( user2_cur%ISOPEN ) THEN
        CLOSE user2_cur;
     END IF;
-- Ver1.2(E055) Add End
-- Ver1.17 Add Start
      -- カーソルクローズ
      IF ( new_emp_cur%ISOPEN ) THEN
        CLOSE new_emp_cur;
      END IF;
-- Ver1.17 Add End
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF ( user_cur%ISOPEN ) THEN
        CLOSE user_cur;
      END IF;
-- Ver1.2(E055) Add Start
      -- カーソルクローズ
      IF ( user2_cur%ISOPEN ) THEN
        CLOSE user2_cur;
      END IF;
-- Ver1.2(E055) Add End
-- Ver1.17 Add Start
      -- カーソルクローズ
      IF ( new_emp_cur%ISOPEN ) THEN
        CLOSE new_emp_cur;
      END IF;
-- Ver1.17 Add End
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF ( user_cur%ISOPEN ) THEN
        CLOSE user_cur;
      END IF;
-- Ver1.2(E055) Add Start
      -- カーソルクローズ
      IF ( user2_cur%ISOPEN ) THEN
        CLOSE user2_cur;
      END IF;
-- Ver1.2(E055) Add End
-- Ver1.17 Add Start
      -- カーソルクローズ
      IF ( new_emp_cur%ISOPEN ) THEN
        CLOSE new_emp_cur;
      END IF;
-- Ver1.17 Add End
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END output_user;
--
--
  /**********************************************************************************
   * Procedure Name   : output_worker2
   * Description      : 従業員情報（上長・新規採用退職者）の抽出・ファイル出力処理(A-4)
   ***********************************************************************************/
  PROCEDURE output_worker2(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_worker2';       -- プログラム名
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
    ------------------------------------
    --ヘッダー行(AssignmentSupervisor)
    ------------------------------------
    cv_ass_sup_header   CONSTANT VARCHAR2(3000) :=
                    'METADATA'                         --  1 : METADATA
      || cv_pipe || 'AssignmentSupervisor'             --  2 : AssignmentSupervisor
      || cv_pipe || 'AssignmentNumber'                 --  3 : AssignmentNumber（アサイメント番号）
      || cv_pipe || 'ManagerType'                      --  4 : ManagerType（タイプ）
      || cv_pipe || 'ManagerAssignmentNumber'          --  5 : ManagerAssignmentNumber（上長アサイメント番号）
      || cv_pipe || 'EffectiveStartDate'               --  6 : EffectiveStartDate（有効開始日）
      || cv_pipe || 'PrimaryFlag'                      --  7 : PrimaryFlag（プライマリ）
      || cv_pipe || 'NewManagerType'                   --  8 : NewManagerType（新規上長タイプ）
      || cv_pipe || 'NewManagerAssignmentNumber'       --  9 : NewManagerAssignmentNumber（新規上長アサイメント番号）
    ;
    --
    ------------------------------------
    --ヘッダー行(WorkRelationship)
    ------------------------------------
    cv_wk_rel_header   CONSTANT VARCHAR2(3000) :=
                    'METADATA'                         --  1 : METADATA
      || cv_pipe || 'WorkRelationship'                 --  2 : WorkRelationship
      || cv_pipe || 'PersonNumber'                     --  3 : PersonNumber（個人番号）
      || cv_pipe || 'WorkerType'                       --  4 : WorkerType（就業者タイプ）
      || cv_pipe || 'DateStart'                        --  5 : DateStart（開始日）
      || cv_pipe || 'LegalEmployerName'                --  6 : LegalEmployerName（雇用主）
      || cv_pipe || 'PrimaryFlag'                      --  7 : PrimaryFlag（プライマリ雇用）
      || cv_pipe || 'ActualTerminationDate'            --  8 : ActualTerminationDate（実績退職日）
      || cv_pipe || 'TerminateWorkRelationshipFlag'    --  9 : TerminateWorkRelationshipFlag（雇用関係の終了）
      || cv_pipe || 'ReverseTerminationFlag'           -- 10 : ReverseTerminationFlag（退職の取消）
      || cv_pipe || 'ActionCode'                       -- 11 : ActionCode（処理コード）
      || cv_pipe || 'SourceSystemOwner'                -- 12 : SourceSystemOwner（ソース・システム所有者）
      || cv_pipe || 'SourceSystemId'                   -- 13 : SourceSystemId（ソース・システムID）
    ;
--
    -- *** ローカル変数 ***
    lv_file_data         VARCHAR2(30000) DEFAULT NULL;       -- 出力内容
--
    -- *** ローカル・カーソル ***
    --------------------------------------
    -- アサイメント上長の抽出カーソル
    --------------------------------------
    CURSOR ass_sup_cur
    IS
      SELECT
          (CASE
             WHEN (xoedi.sup_assignment_number IS NOT NULL
                   AND paaf_sup.assignment_number IS NULL) THEN
               cv_meta_delete
             ELSE
               cv_meta_merge
           END)                                             AS metadata                   -- METADATA
        , paaf.assignment_number                            AS assignment_number          -- アサイメント番号
        , (CASE
-- Ver1.6 Mod Start
--             WHEN (xoedi.sup_assignment_number IS NOT NULL
--                   AND paaf_sup.assignment_number IS NULL) THEN
             WHEN xoedi.sup_assignment_number IS NOT NULL THEN
-- Ver1.6 Mod End
               xoedi.sup_assignment_number
             ELSE 
               paaf_sup.assignment_number
           END)                                             AS sup_ass_number             -- 上長アサイメント番号
        , (CASE
             WHEN xoedi.person_id IS NULL THEN
               TO_CHAR(paaf.effective_start_date, cv_date_fmt)
             ELSE
               TO_CHAR(gt_if_dest_date, cv_date_fmt)  -- 連携日付
           END)                                             AS effective_start_date       -- 有効開始日

        , (CASE
             WHEN (xoedi.sup_assignment_number IS NOT NULL
                   AND paaf_sup.assignment_number IS NOT NULL) THEN
               cv_sup_type_line_manager
             ELSE 
               NULL
           END)                                             AS new_sup_type               -- 新規上長タイプ
        , (CASE
             WHEN (xoedi.sup_assignment_number IS NOT NULL
                   AND paaf_sup.assignment_number IS NOT NULL) THEN
               paaf_sup.assignment_number
             ELSE 
               NULL
           END)                                             AS new_sup_ass_number         -- 新規上長アサイメント番号
      FROM
          per_all_people_f            papf  -- 従業員マスタ
        , per_all_assignments_f       paaf  -- アサイメントマスタ
        , per_periods_of_service      ppos  -- 就業情報
        , xxcmm_oic_emp_diff_info     xoedi -- OIC社員差分情報テーブル
        , (SELECT
               paaf_s.person_id           AS person_id           -- 個人ID
             , paaf_s.assignment_number   AS assignment_number   -- アサイメント番号
           FROM
               per_all_assignments_f    paaf_s  -- アサイメントマスタ(上長)
             , per_periods_of_service   ppos_s  -- 就業情報(上長)
           WHERE
               paaf_s.period_of_service_id = ppos_s.period_of_service_id
           AND ppos_s.actual_termination_date IS NULL
          )                           paaf_sup  -- アサイメントマスタ(上長)
      WHERE
          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external , cv_emp_kbn_dummy)  -- 従業員区分（1:内部、2:外部、4:ダミー）
      AND papf.attribute4 IS NULL    -- 仕入先コード
      AND papf.attribute5 IS NULL    -- 運送業者
      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- 従業員番号
      AND papf.effective_start_date = 
              (SELECT
                   MAX(papf2.effective_start_date)
               FROM
                   per_all_people_f  papf2 -- 従業員マスタ
               WHERE
                   papf2.person_id = papf.person_id
              )
      AND papf.person_id = paaf.person_id
      AND paaf.effective_start_date = 
              (SELECT
                   MAX(paaf2.effective_start_date)
               FROM
                   per_all_assignments_f  paaf2  -- アサイメントマスタ
               WHERE
                   paaf2.person_id = paaf.person_id
              )
      AND paaf.period_of_service_id = ppos.period_of_service_id
      AND ppos.person_id            = xoedi.person_id(+)
      AND ppos.date_start           = xoedi.date_start(+)
      AND paaf.supervisor_id        = paaf_sup.person_id(+)
      AND (   xoedi.sup_assignment_number IS NOT NULL
           OR paaf.supervisor_id IS NOT NULL)
-- Ver1.12 Add Start
      AND (   ppos.actual_termination_date IS NULL
           OR xoedi.person_id IS NULL)
-- Ver1.12 Add End
-- Ver1.18 Mod Start
--      AND (   paaf.last_update_date >= gt_pre_process_date
--           OR paaf.ass_attribute19  >= gv_str_pre_process_date)
           
      AND (
              (     paaf.last_update_date >= gt_pre_process_date
                AND paaf.last_update_date <  gt_cur_process_date
              )
           OR (
                    paaf.ass_attribute19  >= gv_str_pre_process_date
                AND paaf.ass_attribute19  <  gv_str_cur_process_date
              )
          )
-- Ver1.18 Mod End
      ORDER BY
        paaf.assignment_number ASC
    ;
--
    --------------------------------------
    -- 雇用関係（新規採用退職者）の抽出カーソル
    --------------------------------------
    CURSOR wk_rel2_cur
    IS
      SELECT
          papf.employee_number                              AS employee_number            -- 従業員番号
        , TO_CHAR(ppos.date_start, cv_date_fmt)             AS date_start                 -- 開始日
        , TO_CHAR(ppos.actual_termination_date
                  , cv_date_fmt)                            AS actual_termination_date    -- 実績退職日
        , ppos.period_of_service_id                         AS period_of_service_id       -- 就業情報ID
      FROM
          per_all_people_f              papf  -- 従業員マスタ
        , per_all_assignments_f         paaf  -- アサイメントマスタ
        , per_periods_of_service        ppos  -- 就業情報
      WHERE
          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external , cv_emp_kbn_dummy)  -- 従業員区分（1:内部、2:外部、4:ダミー）
      AND papf.attribute4 IS NULL    -- 仕入先コード
      AND papf.attribute5 IS NULL    -- 運送業者
      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- 従業員番号
      AND papf.effective_start_date = 
              (SELECT
                   MAX(papf2.effective_start_date)
               FROM
                   per_all_people_f        papf2 -- 従業員マスタ
               WHERE
                   papf2.person_id = papf.person_id
              )
      AND papf.person_id = paaf.person_id
      AND paaf.effective_start_date = 
              (SELECT
                   MAX(paaf2.effective_start_date)
               FROM
                   per_all_assignments_f   paaf2  -- アサイメントマスタ
               WHERE
                   paaf2.person_id = paaf.person_id
              )
      AND paaf.period_of_service_id = ppos.period_of_service_id
      AND ppos.actual_termination_date IS NOT NULL
      AND NOT EXISTS
              (SELECT
                   1  AS flag
               FROM
                   xxcmm_oic_emp_diff_info   xoedi -- OIC社員差分情報テーブル
               WHERE
                   xoedi.person_id  = ppos.person_id
               AND xoedi.date_start = ppos.date_start
              )
-- Ver1.18 Mod Start
--      AND ppos.last_update_date >= gt_pre_process_date
      AND (
                ppos.last_update_date >= gt_pre_process_date
            AND ppos.last_update_date <  gt_cur_process_date
          )
-- Ver1.18 Mod End
      ORDER BY
          papf.employee_number ASC
    ;
--
    -- *** ローカル・レコード ***
    l_ass_sup_rec      ass_sup_cur%ROWTYPE;    -- アサイメント上長の抽出カーソルレコード
    l_wk_rel2_rec      wk_rel2_cur%ROWTYPE;    -- 雇用関係（新規採用退職者）の抽出カーソルレコード
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ==============================================================
    -- アサイメント情報（上長）の抽出(A-4-1)
    -- ==============================================================
    -- カーソルオープン
    OPEN ass_sup_cur;
    <<output_ass_sup_loop>>
    LOOP
      --
      FETCH ass_sup_cur INTO l_ass_sup_rec;
      EXIT WHEN ass_sup_cur%NOTFOUND;
      --
      -- 抽出件数カウントアップ
      gn_get_ass_sup_cnt := gn_get_ass_sup_cnt + 1;
      --
      -- ==============================================================
      -- アサイメント情報（上長）のファイル出力(A-4-2)
      -- ==============================================================
      -- ヘッダー行の作成（初回のみ）
      IF ( gn_get_ass_sup_cnt = 1 ) THEN
        --
        BEGIN
          -- ヘッダー行のファイル出力
          UTL_FILE.PUT_LINE( gf_wrk2_file_handle  -- 従業員情報（上長・新規採用退職者）連携データファイル
                           , cv_ass_sup_header
                           );
        EXCEPTION
          WHEN OTHERS THEN
            RAISE global_fileout_expt;
        END;
      END IF;
      --
      -- データ行の作成
      lv_file_data := l_ass_sup_rec.metadata;                                             -- 1 : METADATA
      lv_file_data := lv_file_data || cv_pipe || cv_cls_ass_super;                        -- 2 : AssignmentSupervisor
      lv_file_data := lv_file_data || cv_pipe || l_ass_sup_rec.assignment_number;         -- 3 : AssignmentNumber（アサイメント番号）
      lv_file_data := lv_file_data || cv_pipe || cv_sup_type_line_manager;                -- 4 : ManagerType（タイプ）
      lv_file_data := lv_file_data || cv_pipe || l_ass_sup_rec.sup_ass_number;            -- 5 : ManagerAssignmentNumber（上長アサイメント番号）
      lv_file_data := lv_file_data || cv_pipe || l_ass_sup_rec.effective_start_date;      -- 6 : EffectiveStartDate（有効開始日）
      lv_file_data := lv_file_data || cv_pipe || cv_y;                                    -- 7 : PrimaryFlag（プライマリ）
      lv_file_data := lv_file_data || cv_pipe || l_ass_sup_rec.new_sup_type;              -- 8 : NewManagerType（新規上長タイプ）
      lv_file_data := lv_file_data || cv_pipe || l_ass_sup_rec.new_sup_ass_number;        -- 9 : NewManagerAssignmentNumber（新規上長アサイメント番号）
      --
      BEGIN
        -- データ行のファイル出力
        UTL_FILE.PUT_LINE( gf_wrk2_file_handle  -- 従業員情報（上長・新規採用退職者）連携データファイル
                         , lv_file_data
                         );
        -- 出力件数カウントアップ
        gn_out_wk2_cnt := gn_out_wk2_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    --
    END LOOP output_ass_sup_loop;
--
    -- 抽出件数が1件以上ある場合
    IF ( gn_get_ass_sup_cnt > 0 ) THEN
      BEGIN
        -- 空行をファイル出力
        UTL_FILE.PUT_LINE( gf_wrk2_file_handle  -- 従業員情報（上長・新規採用退職者）連携データファイル
                         , ''
                         );
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    END IF;
--
    -- カーソルクローズ
    CLOSE ass_sup_cur;
--
--
    -- ==============================================================
    -- 雇用関係（新規採用退職者）の抽出(A-4-3)
    -- ==============================================================
    -- カーソルオープン
    OPEN wk_rel2_cur;
    <<output_wk_rel2_loop>>
    LOOP
      --
      FETCH wk_rel2_cur INTO l_wk_rel2_rec;
      EXIT WHEN wk_rel2_cur%NOTFOUND;
      --
      -- 抽出件数カウントアップ
      gn_get_wk_rel2_cnt := gn_get_wk_rel2_cnt + 1;
      --
      -- ==============================================================
      -- 雇用関係（新規採用退職者）のファイル出力(A-4-4)
      -- ==============================================================
      -- ヘッダー行の作成（初回のみ）
      IF ( gn_get_wk_rel2_cnt = 1 ) THEN
        --
        BEGIN
          -- ヘッダー行のファイル出力
          UTL_FILE.PUT_LINE( gf_wrk2_file_handle  -- 従業員情報（上長・新規採用退職者）連携データファイル
                           , cv_wk_rel_header
                           );
        EXCEPTION
          WHEN OTHERS THEN
            RAISE global_fileout_expt;
        END;
      END IF;
      --
      -- データ行の作成
      lv_file_data := cv_meta_merge;                                                      --  1 : METADATA
      lv_file_data := lv_file_data || cv_pipe || cv_cls_wk_rel;                           --  2 : WorkRelationship
      lv_file_data := lv_file_data || cv_pipe || l_wk_rel2_rec.employee_number;           --  3 : PersonNumber（個人番号）
      lv_file_data := lv_file_data || cv_pipe || cv_wk_type_e;                            --  4 : WorkerType（就業者タイプ）
      lv_file_data := lv_file_data || cv_pipe || l_wk_rel2_rec.date_start;                --  5 : DateStart（開始日）
      lv_file_data := lv_file_data || cv_pipe || cv_sales_le;                             --  6 : LegalEmployerName（雇用主）
      lv_file_data := lv_file_data || cv_pipe || cv_y;                                    --  7 : PrimaryFlag（プライマリ雇用）
      lv_file_data := lv_file_data || cv_pipe || l_wk_rel2_rec.actual_termination_date;   --  8 : ActualTerminationDate（実績退職日）
      lv_file_data := lv_file_data || cv_pipe || cv_y;                                    --  9 : TerminateWorkRelationshipFlag（雇用関係の終了）
      lv_file_data := lv_file_data || cv_pipe || NULL;                                    -- 10 : ReverseTerminationFlag（退職の取消）
      lv_file_data := lv_file_data || cv_pipe || cv_act_cd_termination;                   -- 11 : ActionCode（処理コード）
      lv_file_data := lv_file_data || cv_pipe || cv_ebs;                                  -- 12 : SourceSystemOwner（ソース・システム所有者）
      lv_file_data := lv_file_data || cv_pipe || l_wk_rel2_rec.period_of_service_id;      -- 13 : SourceSystemId（ソース・システムID）
      --
      BEGIN
        -- データ行のファイル出力
        UTL_FILE.PUT_LINE( gf_wrk2_file_handle  -- 従業員情報（上長・新規採用退職者）連携データファイル
                         , lv_file_data
                         );
        -- 出力件数カウントアップ
        gn_out_wk2_cnt := gn_out_wk2_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    --
    END LOOP output_wk_rel2_loop;
--
    -- カーソルクローズ
    CLOSE wk_rel2_cur;
--
  EXCEPTION
    -- *** ファイル出力時例外ハンドラ ***
    WHEN global_fileout_expt THEN
      -- カーソルクローズ
      IF ( ass_sup_cur%ISOPEN ) THEN
        CLOSE ass_sup_cur;
      END IF;
      --
      IF ( wk_rel2_cur%ISOPEN ) THEN
        CLOSE wk_rel2_cur;
      END IF;
      --
      lv_errmsg := SUBSTRB(
                     xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_xxcmm             -- アプリケーション短縮名：XXCMM
                     , iv_name         => cv_file_write_err_msg     -- メッセージ名：ファイル書き込みエラーメッセージ
                     , iv_token_name1  => cv_tkn_sqlerrm            -- トークン名1：SQLERRM
                     , iv_token_value1 => SQLERRM                   -- トークン値1：SQLERRM
                     )
                   , 1
                   , 5000
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- カーソルクローズ
      IF ( ass_sup_cur%ISOPEN ) THEN
        CLOSE ass_sup_cur;
      END IF;
      --
      IF ( wk_rel2_cur%ISOPEN ) THEN
        CLOSE wk_rel2_cur;
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルクローズ
      IF ( ass_sup_cur%ISOPEN ) THEN
        CLOSE ass_sup_cur;
      END IF;
      --
      IF ( wk_rel2_cur%ISOPEN ) THEN
        CLOSE wk_rel2_cur;
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF ( ass_sup_cur%ISOPEN ) THEN
        CLOSE ass_sup_cur;
      END IF;
      --
      IF ( wk_rel2_cur%ISOPEN ) THEN
        CLOSE wk_rel2_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF ( ass_sup_cur%ISOPEN ) THEN
        CLOSE ass_sup_cur;
      END IF;
      --
      IF ( wk_rel2_cur%ISOPEN ) THEN
        CLOSE wk_rel2_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END output_worker2;
--
--
  /**********************************************************************************
   * Procedure Name   : output_emp_bank_acct
   * Description      : 従業員経費口座情報の抽出・ファイル出力処理(A-5)
   ***********************************************************************************/
  PROCEDURE output_emp_bank_acct(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_emp_bank_acct';       -- プログラム名
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
    lv_file_data         VARCHAR2(30000) DEFAULT NULL;       -- 出力内容
--
    -- *** ローカル・カーソル ***
    --------------------------------------
    -- 従業員経費口座情報の抽出カーソル
    --------------------------------------
    CURSOR bank_acc_cur
    IS
-- Ver1.21 Mod Start
--      SELECT
--          papf.employee_number          AS employee_number         -- 従業員番号
--        , abb.bank_number               AS bank_number             -- 銀行番号
--        , abb.bank_num                  AS bank_num                -- 銀行支店番号
--        , abb.bank_name                 AS bank_name               -- 銀行名
--        , abb.bank_branch_name          AS bank_branch_name        -- 銀行支店名
--        , abaa.bank_account_type        AS bank_account_type       -- 口座種別
--        , abaa.bank_account_num         AS bank_account_num        -- 口座番号
---- Ver1.1 Mod Start
----        , abb.country                   AS country                 -- 国
----        , abaa.currency_code            AS currency_code           -- 通貨コード
--        , NVL(abb.country, cv_jp)       AS country                 -- 国
---- Ver1.7 Mod Start
----        , NVL(abaa.currency_code, cv_yen) AS currency_code         -- 通貨コード
--        , cv_nvl_v                      AS currency_code           -- 通貨コード
---- Ver1.7 Mod End
---- Ver1.1 Mod End
--        , abaa.account_holder_name      AS account_holder_name     -- 口座名義人
--        , abaa.account_holder_name_alt  AS account_holder_name_alt -- 口座名義人カナ
--        , (CASE
--             WHEN abaa.inactive_date <= gt_if_dest_date THEN
--               cv_y
--             ELSE
---- Ver1.9 Mod Start
----               NULL
--               cv_n
---- Ver1.9 Mod End
--           END)                         AS inactive_flag           -- 非アクティブ
--        , (CASE
--             WHEN ROW_NUMBER() OVER(
--                    PARTITION BY abb.bank_number
--                               , abb.bank_num
---- Ver1.11 Add Start
--                               , abb.bank_name
--                               , abb.bank_branch_name
---- Ver1.11 Add End
--                               , abaa.bank_account_type
--                               , abaa.bank_account_num
---- Ver1.1 Mod Start
----                               , abaa.currency_code
----                               , abb.country
--                               , NVL(abaa.currency_code, cv_yen)
--                               , NVL(abb.country, cv_jp)
---- Ver1.1 Mod End
--                    ORDER BY  abb.bank_number
--                            , abb.bank_num
---- Ver1.11 Add Start
--                            , abb.bank_name
--                            , abb.bank_branch_name
---- Ver1.11 Add End
--                            , abaa.bank_account_type
--                            , abaa.bank_account_num
---- Ver1.1 Mod Start
----                            , abaa.currency_code
----                            , abb.country
--                            , NVL(abaa.currency_code, cv_yen)
--                            , NVL(abb.country, cv_jp)
---- Ver1.1 Mod End
--                            , abaua.bank_account_uses_id
--                  ) = 1 THEN
--               cv_y
--             ELSE
--               cv_n
--           END)                         AS primary_flag             -- プライマリフラグ
--        , abaua.primary_flag            AS expense_primary_flag     -- 経費プライマリフラグ
--      FROM
--          per_all_people_f           papf  -- 従業員マスタ
--        , po_vendors                 pv    -- 仕入先マスタ
--        , po_vendor_sites_all        pvsa  -- 仕入先サイトマスタ
--        , ap_bank_accounts_all       abaa  -- 銀行口座マスタ
--        , ap_bank_branches           abb   -- 銀行支店マスタ
--        , ap_bank_account_uses_all   abaua -- 銀行口座使用マスタ 
--      WHERE
--          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_dummy)  -- 従業員区分（1:内部、4:ダミー）
---- Ver1.9 Add Start
--      AND papf.attribute4 IS NULL    -- 仕入先コード
--      AND papf.attribute5 IS NULL    -- 運送業者
---- Ver1.9 Add End
--      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
--                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- 従業員番号
--      AND papf.effective_start_date = 
--              (SELECT
--                   MAX(papf2.effective_start_date)
--               FROM
--                   per_all_people_f  papf2 -- 従業員マスタ
--               WHERE
--                   papf2.person_id = papf.person_id
--              )
--      AND papf.person_id                 = pv.employee_id
--      AND pv.vendor_type_lookup_code     = cv_vd_type_employee
--      AND pv.vendor_id                   = pvsa.vendor_id
---- Ver1.2(E056) Add Start
--      AND pvsa.vendor_site_code          = cv_site_code_comp
---- Ver1.2(E056) Add End
--      AND pvsa.vendor_id                 = abaua.vendor_id
--      AND pvsa.vendor_site_id            = abaua.vendor_site_id
--      AND abaua.external_bank_account_id = abaa.bank_account_id
--      AND abaa.account_type              = cv_acct_type_sup
--      AND abaa.bank_branch_id            = abb.bank_branch_id
---- Ver1.18 Mod Start
----      AND (   abaua.creation_date   >= gt_pre_process_date
----           OR abaa.last_update_date >= gt_pre_process_date
----           OR abaa.inactive_date    =  gt_if_dest_date)
--      AND (
--               (      abaua.creation_date   >= gt_pre_process_date
--                  AND abaua.creation_date   <  gt_cur_process_date
--               )
--           OR  (
--                      abaa.last_update_date >= gt_pre_process_date
--                  AND abaa.last_update_date <  gt_cur_process_date
--               )
---- Ver1.19 Add Start
--           OR  (
--                      abb.last_update_date  >= gt_pre_process_date
--                  AND abb.last_update_date  <  gt_cur_process_date
--               )
---- Ver1.19 Add End
--           OR         abaa.inactive_date    =  gt_if_dest_date
--          )
---- Ver1.18 Mod End
--      ORDER BY
--          abb.bank_number
--        , abb.bank_num
---- Ver1.11 Add Start
--        , abb.bank_name
--        , abb.bank_branch_name
---- Ver1.11 Add End
--        , abaa.bank_account_type
--        , abaa.bank_account_num
---- Ver1.1 Mod Start
----        , abaa.currency_code
----        , abb.country
--        , NVL(abaa.currency_code, cv_yen)
--        , NVL(abb.country, cv_jp)
---- Ver1.1 Mod End
--        , abaua.bank_account_uses_id

      SELECT
          abset.employee_number          AS employee_number         -- 1.従業員番号
        , abset.bank_number              AS bank_number             -- 2.銀行番号
        , abset.bank_num                 AS bank_num                -- 3.銀行支店番号
        , abset.bank_name                AS bank_name               -- 4.銀行名
        , abset.bank_branch_name         AS bank_branch_name        -- 5.銀行支店名
        , abset.bank_account_type        AS bank_account_type       -- 6.口座種別
        , abset.bank_account_num         AS bank_account_num        -- 7.口座番号
        , abset.country                  AS country                 -- 8.国コード
        , abset.currency_code            AS currency_code           -- 9.通貨コード
        , abset.account_holder_name      AS account_holder_name     -- 10.口座名義人
        , abset.account_holder_name_alt  AS account_holder_name_alt -- 11.口座名義人カナ
        , abset.inactive_flag            AS inactive_flag           -- 12.非アクティブ
        , abset.primary_flag             AS primary_flag            -- 13.プライマリフラグ
        , abset.expense_primary_flag     AS expense_primary_flag    -- 14.経費プライマリフラグ
      FROM
          (
            SELECT
                papf.employee_number          AS employee_number         -- 1.従業員番号
              , abb.bank_number               AS bank_number             -- 2.銀行番号
              , abb.bank_num                  AS bank_num                -- 3.銀行支店番号
              , abb.bank_name                 AS bank_name               -- 4.銀行名
              , abb.bank_branch_name          AS bank_branch_name        -- 5.銀行支店名
              , abaa.bank_account_type        AS bank_account_type       -- 6.口座種別
              , abaa.bank_account_num         AS bank_account_num        -- 7.口座番号
              , NVL(abb.country, cv_jp)       AS country                 -- 8.国コード
              , cv_nvl_v                      AS currency_code           -- 9.通貨コード
              , abaa.account_holder_name      AS account_holder_name     -- 10.口座名義人
              , abaa.account_holder_name_alt  AS account_holder_name_alt -- 11.口座名義人カナ
              , (CASE
                   WHEN abaa.inactive_date <= gt_if_dest_date THEN
                     cv_y
                   ELSE
                     cv_n
                 END)                         AS inactive_flag           -- 12.非アクティブ
              , (CASE
                   WHEN ROW_NUMBER() OVER(
                          PARTITION BY abb.bank_number
                                     , abb.bank_num
                                     , abb.bank_name
                                     , abb.bank_branch_name
                                     , abaa.bank_account_type
                                     , abaa.bank_account_num
                                     , NVL(abaa.currency_code, cv_yen)
                                     , NVL(abb.country, cv_jp)
                          ORDER BY  abb.bank_number
                                  , abb.bank_num
                                  , abb.bank_name
                                  , abb.bank_branch_name
                                  , abaa.bank_account_type
                                  , abaa.bank_account_num
                                  , NVL(abaa.currency_code, cv_yen)
                                  , NVL(abb.country, cv_jp)
                                  , abaua.bank_account_uses_id
                        ) = 1 THEN
                     cv_y
                   ELSE
                     cv_n
                 END)                         AS primary_flag             -- 13.プライマリフラグ
              , abaua.primary_flag            AS expense_primary_flag     -- 14.経費プライマリフラグ
              , abaua.bank_account_uses_id    AS bank_account_uses_id     -- 15.口座ユーザーID
              , abaua.creation_date           AS abaua_creation_date      -- 16.銀行口座使用マスタの作成日付
              , abaa.last_update_date         AS abaa_last_update_date    -- 17.銀行口座マスタの最終更新日
              , abb.last_update_date          AS abb_last_update_date     -- 18.銀行支店マスタの最終更新日
              , abaa.inactive_date            AS abaa_inactive_date       -- 19.銀行口座マスタの無効日
            FROM
                per_all_people_f           papf  -- 従業員マスタ
              , po_vendors                 pv    -- 仕入先マスタ
              , po_vendor_sites_all        pvsa  -- 仕入先サイトマスタ
              , ap_bank_accounts_all       abaa  -- 銀行口座マスタ
              , ap_bank_branches           abb   -- 銀行支店マスタ
              , ap_bank_account_uses_all   abaua -- 銀行口座使用マスタ 
            WHERE
                papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_dummy)  -- 従業員区分（1:内部、4:ダミー）
            AND papf.attribute4 IS NULL    -- 仕入先コード
            AND papf.attribute5 IS NULL    -- 運送業者
            AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                             cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- 従業員番号
            AND papf.effective_start_date = 
                    (SELECT
                         MAX(papf2.effective_start_date)
                     FROM
                         per_all_people_f  papf2  -- 従業員マスタ
                     WHERE
                         papf2.person_id = papf.person_id
                    )
            AND papf.person_id                 = pv.employee_id
            AND pv.vendor_type_lookup_code     = cv_vd_type_employee
            AND pv.vendor_id                   = pvsa.vendor_id
            AND pvsa.vendor_site_code          = cv_site_code_comp
            AND pvsa.vendor_id                 = abaua.vendor_id
            AND pvsa.vendor_site_id            = abaua.vendor_site_id
            AND abaua.external_bank_account_id = abaa.bank_account_id
            AND abaa.account_type              = cv_acct_type_sup
            AND abaa.bank_branch_id            = abb.bank_branch_id
          )  abset  -- 銀行口座関連テーブル
      WHERE
          (
               (      abset.abaua_creation_date   >= gt_pre_process_date
                  AND abset.abaua_creation_date   <  gt_cur_process_date
               )
           OR  (
                      abset.abaa_last_update_date >= gt_pre_process_date
                  AND abset.abaa_last_update_date <  gt_cur_process_date
               )
           OR  (
                      abset.abb_last_update_date  >= gt_pre_process_date
                  AND abset.abb_last_update_date  <  gt_cur_process_date
               )
           OR         abset.abaa_inactive_date    =  gt_if_dest_date
          )
      ORDER BY
          abset.bank_number
        , abset.bank_num
        , abset.bank_name
        , abset.bank_branch_name
        , abset.bank_account_type
        , abset.bank_account_num
        , abset.currency_code
        , abset.country
        , abset.bank_account_uses_id
-- Ver1.21 Mod End
    ;
--
    -- *** ローカル・レコード ***
    l_bank_acc_rec      bank_acc_cur%ROWTYPE;    -- 従業員経費口座情報の抽出カーソルレコード
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ==============================================================
    -- 従業員経費口座情報の抽出(A-5-1)
    -- ==============================================================
    -- カーソルオープン
    OPEN bank_acc_cur;
    <<output_bank_acc_loop>>
    LOOP
      --
      FETCH bank_acc_cur INTO l_bank_acc_rec;
      EXIT WHEN bank_acc_cur%NOTFOUND;
      --
      -- 抽出件数カウントアップ
      gn_get_bank_acc_cnt := gn_get_bank_acc_cnt + 1;
      --
      -- ==============================================================
      -- 従業員経費口座情報のファイル出力(A-5-2)
      -- ==============================================================
      -- データ行の作成
      lv_file_data := xxccp_oiccommon_pkg.to_csv_string( l_bank_acc_rec.employee_number         , cv_space );  --  1 : 従業員番号
      lv_file_data := lv_file_data || cv_comma ||
                      xxccp_oiccommon_pkg.to_csv_string( l_bank_acc_rec.bank_number             , cv_space );  --  2 : 銀行番号
      lv_file_data := lv_file_data || cv_comma ||
                      xxccp_oiccommon_pkg.to_csv_string( l_bank_acc_rec.bank_num                , cv_space );  --  3 : 銀行支店番号
      lv_file_data := lv_file_data || cv_comma ||
                      xxccp_oiccommon_pkg.to_csv_string( l_bank_acc_rec.bank_name               , cv_space );  --  4 : 銀行名
      lv_file_data := lv_file_data || cv_comma ||
                      xxccp_oiccommon_pkg.to_csv_string( l_bank_acc_rec.bank_branch_name        , cv_space );  --  5 : 銀行支店名
      lv_file_data := lv_file_data || cv_comma ||
                      xxccp_oiccommon_pkg.to_csv_string( l_bank_acc_rec.bank_account_type       , cv_space );  --  6 : 口座種別
      lv_file_data := lv_file_data || cv_comma ||
                      xxccp_oiccommon_pkg.to_csv_string( l_bank_acc_rec.bank_account_num        , cv_space );  --  7 : 口座番号
      lv_file_data := lv_file_data || cv_comma ||
                      xxccp_oiccommon_pkg.to_csv_string( l_bank_acc_rec.country                 , cv_space );  --  8 : 国コード
      lv_file_data := lv_file_data || cv_comma ||
                      xxccp_oiccommon_pkg.to_csv_string( l_bank_acc_rec.currency_code           , cv_space );  --  9 : 通貨コード
      lv_file_data := lv_file_data || cv_comma ||
                      xxccp_oiccommon_pkg.to_csv_string( l_bank_acc_rec.account_holder_name     , cv_space );  -- 10 : 口座名義人
      lv_file_data := lv_file_data || cv_comma ||
                      xxccp_oiccommon_pkg.to_csv_string( l_bank_acc_rec.account_holder_name_alt , cv_space );  -- 11 : カナ口座名義
      lv_file_data := lv_file_data || cv_comma ||
                      xxccp_oiccommon_pkg.to_csv_string( l_bank_acc_rec.inactive_flag           , cv_space );  -- 12 : 非アクティブ
      lv_file_data := lv_file_data || cv_comma ||
                      xxccp_oiccommon_pkg.to_csv_string( l_bank_acc_rec.primary_flag            , cv_space );  -- 13 : プライマリフラグ
      lv_file_data := lv_file_data || cv_comma ||
                      xxccp_oiccommon_pkg.to_csv_string( l_bank_acc_rec.expense_primary_flag    , cv_space );  -- 14 : 経費プライマリフラグ
      --
      BEGIN
        -- データ行のファイル出力
        UTL_FILE.PUT_LINE( gf_emp_bnk_file_handle  -- PaaS処理用の従業員経費口座情報ファイル
                         , lv_file_data
                         );
        -- 出力件数カウントアップ
        gn_out_p_bank_acct_cnt := gn_out_p_bank_acct_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    --
    END LOOP output_bank_acc_loop;
--
    -- カーソルクローズ
    CLOSE bank_acc_cur;
--
  EXCEPTION
    -- *** ファイル出力時例外ハンドラ ***
    WHEN global_fileout_expt THEN
      -- カーソルクローズ
      IF ( bank_acc_cur%ISOPEN ) THEN
        CLOSE bank_acc_cur;
      END IF;
      --
      lv_errmsg := SUBSTRB(
                     xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_xxcmm             -- アプリケーション短縮名：XXCMM
                     , iv_name         => cv_file_write_err_msg     -- メッセージ名：ファイル書き込みエラーメッセージ
                     , iv_token_name1  => cv_tkn_sqlerrm            -- トークン名1：SQLERRM
                     , iv_token_value1 => SQLERRM                   -- トークン値1：SQLERRM
                     )
                   , 1
                   , 5000
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- カーソルクローズ
      IF ( bank_acc_cur%ISOPEN ) THEN
        CLOSE bank_acc_cur;
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルクローズ
      IF ( bank_acc_cur%ISOPEN ) THEN
        CLOSE bank_acc_cur;
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF ( bank_acc_cur%ISOPEN ) THEN
        CLOSE bank_acc_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF ( bank_acc_cur%ISOPEN ) THEN
        CLOSE bank_acc_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END output_emp_bank_acct;
--
--
  /**********************************************************************************
   * Procedure Name   : output_emp_info
   * Description      : 社員差分情報の抽出・ファイル出力処理（PaaS処理用）(A-6)
   ***********************************************************************************/
  PROCEDURE output_emp_info(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_emp_info';       -- プログラム名
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
    lv_file_data         VARCHAR2(30000) DEFAULT NULL;       -- 出力内容
-- Ver1.17 Add Start
    lv_new_emp_flag      VARCHAR2(1);                        -- 新入社員フラグ
-- Ver1.17 Add End
--
    -- *** ローカル・カーソル ***
    --------------------------------------
    -- 社員差分情報の抽出カーソル
    --------------------------------------
    CURSOR emp_info_cur
    IS
      SELECT
          fu.user_name                      AS user_name                    -- ユーザー名
        , papf.employee_number              AS employee_number              -- 従業員番号
        , papf.person_id                    AS person_id                    -- 個人ID
        , papf.last_name                    AS last_name                    -- カナ姓
        , papf.first_name                   AS first_name                   -- カナ名
        , papf.attribute28                  AS location_code                -- 拠点コード
        , papf.attribute7                   AS license_code                 -- 資格コード(新)
        , papf.attribute11                  AS job_post                     -- 職位コード(新)
        , papf.attribute15                  AS job_duty                     -- 職務コード(新)
        , papf.attribute19                  AS job_type                     -- 職種コード(新)
        , xwhd.dpt1_cd                      AS dpt1_cd                      -- 1階層目部門コード
        , xwhd.dpt2_cd                      AS dpt2_cd                      -- 2階層目部門コード
        , xwhd.dpt3_cd                      AS dpt3_cd                      -- 3階層目部門コード
        , xwhd.dpt4_cd                      AS dpt4_cd                      -- 4階層目部門コード
        , xwhd.dpt5_cd                      AS dpt5_cd                      -- 5階層目部門コード
        , xwhd.dpt6_cd                      AS dpt6_cd                      -- 6階層目部門コード
        , paaf_sup.assignment_number        AS sup_assignment_number        -- 上長アサイメント番号
        , ppos.date_start                   AS date_start                   -- 開始日
        , ppos.actual_termination_date      AS actual_termination_date      -- 退職日
        , (CASE
             WHEN (fu.user_id IS NULL OR
                   (xoedi.person_id IS NOT NULL AND xoedi.user_name IS NULL)) THEN
               cv_n
             WHEN xoedi.person_id IS NULL THEN
               cv_y
             ELSE
               (CASE
                  WHEN (   papf.last_name             <> xoedi.last_name
                        OR NVL(papf.first_name , '@') <> NVL(xoedi.first_name,    '@')
                        OR NVL(papf.attribute28, '@') <> NVL(xoedi.location_code, '@')
                        OR NVL(papf.attribute7,  '@') <> NVL(xoedi.license_code,  '@')
                        OR NVL(papf.attribute11, '@') <> NVL(xoedi.job_post,      '@')
                        OR NVL(papf.attribute15, '@') <> NVL(xoedi.job_duty,      '@')
                        OR NVL(papf.attribute19, '@') <> NVL(xoedi.job_type,      '@')
-- Ver1.16 Add Start
                        OR ppos.date_start            <> xoedi.date_start
-- Ver1.16 Add End
                       ) THEN
                    cv_y
                  ELSE
                    cv_n
                END)
           END)                             AS roll_change_flag             -- ロール変更フラグ
        , (CASE
             WHEN xoedi.person_id IS NULL THEN
               cv_y
             ELSE
               (CASE
                  WHEN (   NVL(xwhd.dpt1_cd, '@')                 <> NVL(xoedi.dpt1_cd,   '@')
                        OR NVL(xwhd.dpt2_cd, '@')                 <> NVL(xoedi.dpt2_cd,   '@')
                        OR NVL(xwhd.dpt3_cd, '@')                 <> NVL(xoedi.dpt3_cd,   '@')
                        OR NVL(xwhd.dpt4_cd, '@')                 <> NVL(xoedi.dpt4_cd,   '@')
                        OR NVL(xwhd.dpt5_cd, '@')                 <> NVL(xoedi.dpt5_cd,   '@')
                        OR NVL(xwhd.dpt6_cd, '@')                 <> NVL(xoedi.dpt6_cd,   '@')
                        OR NVL(paaf_sup.assignment_number,   '@') <> NVL(xoedi.sup_assignment_number,   '@')
                        OR ppos.date_start                        <> xoedi.date_start
                        OR NVL(ppos.actual_termination_date, gt_cur_process_date) <> NVL(xoedi.actual_termination_date, gt_cur_process_date)
                       ) THEN
                    cv_y 
                  ELSE
                    cv_n
                END)
           END)                             AS other_change_flag            -- その他変更フラグ
        , xoedi.person_id                   AS xoedi_person_id              -- 個人ID（社員差分情報）
        , xoedi.last_name                   AS pre_last_name                -- 前回カナ姓
        , xoedi.first_name                  AS pre_first_name               -- 前回カナ名
        , xoedi.location_code               AS pre_location_code            -- 前回拠点コード
        , xoedi.license_code                AS pre_license_code             -- 前回資格コード
        , xoedi.job_post                    AS pre_job_post                 -- 前回職位コード
        , xoedi.job_duty                    AS pre_job_duty                 -- 前回職務コード
        , xoedi.job_type                    AS pre_job_type                 -- 前回職種コード
        , xoedi.dpt1_cd                     AS pre_dpt1_cd                  -- 前回1階層目部門コード
        , xoedi.dpt2_cd                     AS pre_dpt2_cd                  -- 前回2階層目部門コード
        , xoedi.dpt3_cd                     AS pre_dpt3_cd                  -- 前回3階層目部門コード
        , xoedi.dpt4_cd                     AS pre_dpt4_cd                  -- 前回4階層目部門コード
        , xoedi.dpt5_cd                     AS pre_dpt5_cd                  -- 前回5階層目部門コード
        , xoedi.dpt6_cd                     AS pre_dpt6_cd                  -- 前回6階層目部門コード
        , xoedi.sup_assignment_number       AS pre_sup_assignment_number    -- 前回上長アサイメント番号
        , xoedi.date_start                  AS pre_date_start               -- 前回開始日
        , xoedi.actual_termination_date     AS pre_actual_termination_date  -- 前回退職日
      FROM
          xxcmm_oic_emp_diff_info  xoedi     -- OIC社員差分情報テーブル
        , fnd_user                 fu        -- ユーザーマスタ
        , per_all_people_f         papf      -- 従業員マスタ
        , (SELECT
               xwhd_sub.cur_dpt_cd          AS cur_dpt_cd               -- 最下層部門コード
             , xwhd_sub.dpt1_cd             AS dpt1_cd                  -- １階層目部門コード
             , xwhd_sub.dpt2_cd             AS dpt2_cd                  -- ２階層目部門コード
             , xwhd_sub.dpt3_cd             AS dpt3_cd                  -- ３階層目部門コード
             , xwhd_sub.dpt4_cd             AS dpt4_cd                  -- ４階層目部門コード
             , xwhd_sub.dpt5_cd             AS dpt5_cd                  -- ５階層目部門コード
             , xwhd_sub.dpt6_cd             AS dpt6_cd                  -- ６階層目部門コード
             , ROW_NUMBER() OVER(
                 PARTITION BY xwhd_sub.cur_dpt_cd
                 ORDER BY xwhd_sub.cur_dpt_cd
               )                            AS row_num                  -- 行番号（最下層部門コード単位）
           FROM
               xxcmm_wk_hiera_dept xwhd_sub  -- 部門階層ワーク
           WHERE
               xwhd_sub.process_kbn = cv_proc_type_dept
          )                        xwhd      -- 部門階層ワーク
        , per_all_assignments_f    paaf      -- アサインメントマスタ
        , (SELECT
               paaf_s.person_id             AS person_id                -- 個人ID
              ,paaf_s.assignment_number     AS assignment_number        -- アサイメント番号
           FROM
               per_all_assignments_f    paaf_s  -- アサイメントマスタ(上長)
              ,per_periods_of_service   ppos_s  -- 就業情報(上長)
           WHERE
               paaf_s.period_of_service_id = ppos_s.period_of_service_id
           AND ppos_s.actual_termination_date IS NULL
          )                           paaf_sup  -- アサイメントマスタ(上長)
        , per_periods_of_service      ppos      -- 就業情報
      WHERE
          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external , cv_emp_kbn_dummy)  -- 従業員区分（1:内部、2:外部、4:ダミー）
      AND papf.attribute4 IS NULL    -- 仕入先コード
      AND papf.attribute5 IS NULL    -- 運送業者
      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- 従業員番号
      AND papf.person_id = fu.employee_id(+)
      AND papf.effective_start_date = 
              (SELECT
                   MAX(papf2.effective_start_date)
               FROM
                   per_all_people_f       papf2  -- 従業員マスタ
               WHERE
                   papf2.person_id = papf.person_id
              )
      AND papf.attribute28          = xwhd.cur_dpt_cd(+)
      AND xwhd.row_num(+)           = 1
      AND papf.person_id            = paaf.person_id
      AND paaf.effective_start_date =
              (SELECT
                   MAX(paaf2.effective_start_date)
               FROM
                   per_all_assignments_f  paaf2  -- アサイメントマスタ
               WHERE
                   paaf2.person_id = paaf.person_id
              )
      AND paaf.period_of_service_id = ppos.period_of_service_id
      AND paaf.supervisor_id        = paaf_sup.person_id(+)
      AND papf.employee_number      = xoedi.employee_number(+)
-- Ver1.18 Mod Start
--      AND (   papf.last_update_date >= gt_pre_process_date
--           OR papf.attribute23      >= gv_str_pre_process_date
--           OR paaf.last_update_date >= gt_pre_process_date
--           OR paaf.ass_attribute19  >= gv_str_pre_process_date
--           OR ppos.last_update_date >= gt_pre_process_date
--          )
      AND (   
              (     papf.last_update_date >= gt_pre_process_date
                AND papf.last_update_date <  gt_cur_process_date
            )
           OR (
                    papf.attribute23 >= gv_str_pre_process_date
                AND papf.attribute23 <  gv_str_cur_process_date
              )
           OR (
                    paaf.last_update_date >= gt_pre_process_date
                AND paaf.last_update_date <  gt_cur_process_date
              )
           OR (
                    paaf.ass_attribute19 >= gv_str_pre_process_date
                AND paaf.ass_attribute19 <  gv_str_cur_process_date
              )
           OR (
                    ppos.last_update_date >= gt_pre_process_date
                AND ppos.last_update_date <  gt_cur_process_date
              )
          )
-- Ver1.18 Mod End
      ORDER BY
          papf.employee_number ASC
      FOR UPDATE OF xoedi.person_id NOWAIT
    ;
--
-- Ver1.17 Add Start
    --------------------------------------
    -- 新入社員情報の抽出カーソル
    --------------------------------------
    CURSOR new_emp_cur (
             in_person_id IN NUMBER
    )
    IS
      SELECT
          fu.user_name                                      AS user_name                    -- ユーザー名
        , papf.employee_number                              AS employee_number              -- 従業員番号
        , TO_CHAR(fu.start_date, cv_date_fmt)               AS start_date                   -- 開始日
        , cv_y                                              AS generated_user_account_flag  -- 生成済ユーザー・アカウント
        , papf.person_id                                    AS person_id                    -- 個人ID
      FROM
          per_all_people_f     papf  -- 従業員マスタ
        , fnd_user             fu    -- ユーザーマスタ
      WHERE
          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external , cv_emp_kbn_dummy)  -- 従業員区分（1:内部、2:外部、4:ダミー）
      AND papf.attribute4 IS NULL    -- 仕入先コード
      AND papf.attribute5 IS NULL    -- 運送業者
      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- 従業員番号
      AND papf.effective_start_date = 
              (SELECT
                   MAX(papf2.effective_start_date)
               FROM
                   per_all_people_f  papf2 -- 従業員マスタ
               WHERE
                   papf2.person_id = papf.person_id
              )
      AND papf.person_id     = fu.employee_id
-- Ver1.18 Mod Start
--      AND papf.creation_date >= gt_pre_process_date
--      AND fu.creation_date   >= gt_pre_process_date
      AND (
                papf.creation_date >= gt_pre_process_date
            AND papf.creation_date <  gt_cur_process_date
          )
      AND (
                fu.creation_date   >= gt_pre_process_date
            AND fu.creation_date   <  gt_cur_process_date
          )
-- Ver1.18 Mod End
      AND papf.person_id = in_person_id
      ORDER BY
          employee_number ASC
    ;
--
-- Ver1.7 Add End
    -- *** ローカル・レコード ***
    l_emp_info_rec      emp_info_cur%ROWTYPE;    -- 社員差分情報の抽出カーソルレコード
-- Ver1.17 Add Start
    l_new_emp_rec       new_emp_cur%ROWTYPE;     -- 新入社員情報の抽出カーソルレコード
-- Ver1.17 Add End
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ==============================================================
    -- 部門階層ワーク（一時表）の登録(A-6-1)
    -- ==============================================================
    BEGIN
      --
      INSERT INTO xxcmm_wk_hiera_dept (
          cur_dpt_cd                              -- 最下層部門コード
        , dpt1_cd                                 -- １階層目部門コード
        , dpt2_cd                                 -- ２階層目部門コード
        , dpt3_cd                                 -- ３階層目部門コード
        , dpt4_cd                                 -- ４階層目部門コード
        , dpt5_cd                                 -- ５階層目部門コード
        , dpt6_cd                                 -- ６階層目部門コード
        , process_kbn                             -- 処理区分
      )
      SELECT
          xhdv.cur_dpt_cd     AS cur_dpt_cd       -- 最下層部門コード
        , xhdv.dpt1_cd        AS dpt1_cd          -- １階層目部門コード
        , xhdv.dpt2_cd        AS dpt2_cd          -- ２階層目部門コード
        , xhdv.dpt3_cd        AS dpt3_cd          -- ３階層目部門コード
        , xhdv.dpt4_cd        AS dpt4_cd          -- ４階層目部門コード
        , xhdv.dpt5_cd        AS dpt5_cd          -- ５階層目部門コード
        , xhdv.dpt6_cd        AS dpt6_cd          -- ６階層目部門コード
        , cv_proc_type_dept   AS process_kbn      -- 処理区分
      FROM
          xxcmm_hierarchy_dept_v  xhdv  -- 部門階層ビュー
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- 登録に失敗した場合
        lv_errmsg := SUBSTRB(
                       xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_xxcmm             -- アプリケーション短縮名：XXCMM
                       , iv_name         => cv_insert_err_msg         -- メッセージ名：挿入エラーメッセージ
                       , iv_token_name1  => cv_tkn_table              -- トークン名1：TABLE
                       , iv_token_value1 => cv_oic_wk_hiera_dept_msg  -- トークン値1：部門階層ワーク
                       , iv_token_name2  => cv_tkn_err_msg            -- トークン名2：ERR_MSG
                       , iv_token_value2 => SQLERRM                   -- トークン値2：SQLERRM
                       )
                     , 1
                     , 5000
                     );
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ==============================================================
    -- 社員差分情報の抽出(A-6-2)
    -- ==============================================================
    -- カーソルオープン
    OPEN emp_info_cur;
    <<output_emp_info_loop>>
    LOOP
      --
      FETCH emp_info_cur INTO l_emp_info_rec;
      EXIT WHEN emp_info_cur%NOTFOUND;
      --
      -- 抽出件数カウントアップ
      gn_get_emp_info_cnt := gn_get_emp_info_cnt + 1;
      --
      IF ( l_emp_info_rec.roll_change_flag = cv_y ) THEN
        -- ロール変更フラグがYの場合
        --
-- Ver1.17 Del Start
        -- ==============================================================
        -- 社員差分情報のファイル出力(A-6-3)
        -- ==============================================================
-- Ver1.17 Del End
        -- データ行の作成
        lv_file_data := xxccp_oiccommon_pkg.to_csv_string( l_emp_info_rec.user_name       , cv_space );  --  1 : ユーザー名
        lv_file_data := lv_file_data || cv_comma ||
                        xxccp_oiccommon_pkg.to_csv_string( l_emp_info_rec.employee_number , cv_space );  --  2 : 従業員番号
        lv_file_data := lv_file_data || cv_comma ||
                        xxccp_oiccommon_pkg.to_csv_string( l_emp_info_rec.last_name       , cv_space );  --  3 : カナ姓
        lv_file_data := lv_file_data || cv_comma ||
                        xxccp_oiccommon_pkg.to_csv_string( l_emp_info_rec.first_name      , cv_space );  --  4 : カナ名
        lv_file_data := lv_file_data || cv_comma ||
                        xxccp_oiccommon_pkg.to_csv_string( l_emp_info_rec.location_code   , cv_space );  --  5 : 拠点コード
        lv_file_data := lv_file_data || cv_comma ||
                        xxccp_oiccommon_pkg.to_csv_string( l_emp_info_rec.license_code    , cv_space );  --  6 : 資格コード
        lv_file_data := lv_file_data || cv_comma ||
                        xxccp_oiccommon_pkg.to_csv_string( l_emp_info_rec.job_post        , cv_space );  --  7 : 職位コード
        lv_file_data := lv_file_data || cv_comma ||
                        xxccp_oiccommon_pkg.to_csv_string( l_emp_info_rec.job_duty        , cv_space );  --  8 : 職務コード
        lv_file_data := lv_file_data || cv_comma ||
                        xxccp_oiccommon_pkg.to_csv_string( l_emp_info_rec.job_type        , cv_space );  --  9 : 職種コード
        lv_file_data := lv_file_data || cv_comma ||
                        xxccp_oiccommon_pkg.to_csv_string( l_emp_info_rec.dpt1_cd         , cv_space );  -- 10 : １階層目部門コード
        lv_file_data := lv_file_data || cv_comma ||
                        xxccp_oiccommon_pkg.to_csv_string( l_emp_info_rec.dpt2_cd         , cv_space );  -- 11 : ２階層目部門コード
        lv_file_data := lv_file_data || cv_comma ||
                        xxccp_oiccommon_pkg.to_csv_string( l_emp_info_rec.dpt3_cd         , cv_space );  -- 12 : ３階層目部門コード
        lv_file_data := lv_file_data || cv_comma ||
                        xxccp_oiccommon_pkg.to_csv_string( l_emp_info_rec.dpt4_cd         , cv_space );  -- 13 : ４階層目部門コード
        lv_file_data := lv_file_data || cv_comma ||
                        xxccp_oiccommon_pkg.to_csv_string( l_emp_info_rec.dpt5_cd         , cv_space );  -- 14 : ５階層目部門コード
        lv_file_data := lv_file_data || cv_comma ||
                        xxccp_oiccommon_pkg.to_csv_string( l_emp_info_rec.dpt6_cd         , cv_space );  -- 15 : ６階層目部門コード
        --
-- Ver1.17 Mod Start
--        BEGIN
--         -- データ行のファイル出力
--          UTL_FILE.PUT_LINE( gf_emp_inf_file_handle  -- PaaS処理用の社員差分情報ファイル
--                           , lv_file_data
--                           );
--          -- 出力件数カウントアップ
--          gn_out_p_emp_info_cnt := gn_out_p_emp_info_cnt + 1;
    -- ==============================================================
    -- 新入社員情報の抽出(A-6-3)
    -- ==============================================================
-- Ver1.20 Add Start
      lv_new_emp_flag := cv_n;
-- Ver1.20 Add End

      -- カーソルオープン
      OPEN new_emp_cur (
             l_emp_info_rec.person_id
           );
      <<output_new_emp_loop>>
      LOOP
        --
        FETCH new_emp_cur INTO l_new_emp_rec;
        EXIT WHEN new_emp_cur%NOTFOUND;
        --
        -- emp_info_curとnew_emp_curを比較
--        IF ( l_emp_info_rec.person_id = l_new_emp_rec.person_id ) THEN
          lv_new_emp_flag := cv_y;
          -- 一致する場合Yフラグをたてる
--        END IF;
      END LOOP output_new_emp_loop;
--
      -- カーソルクローズ
      CLOSE new_emp_cur;
        -- ==============================================================
        -- 社員差分情報のファイル出力(A-6-4)
        -- ==============================================================
        BEGIN
          IF ( lv_new_emp_flag = cv_y ) THEN
            -- データ行のファイル出力
            UTL_FILE.PUT_LINE( gf_new_emp_file_handle  -- PaaS処理用の新入社員情報ファイル
                             , lv_file_data
                             );
            -- 出力件数カウントアップ
            gn_out_p_new_emp_cnt := gn_out_p_new_emp_cnt + 1;
          ELSE
            UTL_FILE.PUT_LINE( gf_emp_inf_file_handle  -- PaaS処理用の社員差分情報ファイル
                             , lv_file_data
                             );
            -- 出力件数カウントアップ
            gn_out_p_emp_info_cnt := gn_out_p_emp_info_cnt + 1;
          END IF;
          --
-- Ver1.17 Mod End
        EXCEPTION
          WHEN OTHERS THEN
            RAISE global_fileout_expt;
        END;
      --
      ELSE
        -- ロール変更フラグがNの場合
        -- スキップ件数をカウントアップ
        gn_warn_cnt := gn_warn_cnt + 1;
      END IF;
      --
      --
-- Ver1.17 Mod Start
--      -- ==============================================================
--      -- OIC社員差分情報テーブルの登録・更新処理(A-6-4)
--      -- ==============================================================
      -- ==============================================================
      -- OIC社員差分情報テーブルの登録・更新処理(A-6-5)
      -- ==============================================================
-- Ver1.17 Mod End
      IF (    l_emp_info_rec.roll_change_flag  = cv_y
           OR l_emp_info_rec.other_change_flag = cv_y ) THEN
        -- ロール変更フラグがY、または、その他変更フラグがYの場合
        --
        IF ( l_emp_info_rec.xoedi_person_id IS NULL ) THEN
          -- 個人ID（社員差分情報）がNULLの場合
          --
          BEGIN
            -- OIC社員差分情報テーブルの登録
            INSERT INTO xxcmm_oic_emp_diff_info (
                person_id                                     -- 個人ID
              , employee_number                               -- 従業員番号
              , user_name                                     -- ユーザー名
              , last_name                                     -- カナ姓
              , first_name                                    -- カナ名
              , location_code                                 -- 拠点コード
              , license_code                                  -- 資格コード
              , job_post                                      -- 職位コード
              , job_duty                                      -- 職務コード
              , job_type                                      -- 職種コード
              , dpt1_cd                                       -- １階層目部門コード
              , dpt2_cd                                       -- ２階層目部門コード
              , dpt3_cd                                       -- ３階層目部門コード
              , dpt4_cd                                       -- ４階層目部門コード
              , dpt5_cd                                       -- ５階層目部門コード
              , dpt6_cd                                       -- ６階層目部門コード
              , sup_assignment_number                         -- 上長アサイメント番号
              , date_start                                    -- 開始日
              , actual_termination_date                       -- 退職日
              , created_by                                    -- 作成者
              , creation_date                                 -- 作成日
              , last_updated_by                               -- 最終更新者
              , last_update_date                              -- 最終更新日
              , last_update_login                             -- 最終更新ログイン
              , request_id                                    -- 要求ID
              , program_application_id                        -- コンカレント・プログラム・アプリケーションID
              , program_id                                    -- コンカレント・プログラムID
              , program_update_date                           -- プログラム更新日
            ) VALUES (
                l_emp_info_rec.person_id                      -- 個人ID
              , l_emp_info_rec.employee_number                -- 従業員番号
              , l_emp_info_rec.user_name                      -- ユーザー名
              , l_emp_info_rec.last_name                      -- カナ姓
              , l_emp_info_rec.first_name                     -- カナ名
              , l_emp_info_rec.location_code                  -- 拠点コード
              , l_emp_info_rec.license_code                   -- 資格コード
              , l_emp_info_rec.job_post                       -- 職位コード
              , l_emp_info_rec.job_duty                       -- 職務コード
              , l_emp_info_rec.job_type                       -- 職種コード
              , l_emp_info_rec.dpt1_cd                        -- １階層目部門コード
              , l_emp_info_rec.dpt2_cd                        -- ２階層目部門コード
              , l_emp_info_rec.dpt3_cd                        -- ３階層目部門コード
              , l_emp_info_rec.dpt4_cd                        -- ４階層目部門コード
              , l_emp_info_rec.dpt5_cd                        -- ５階層目部門コード
              , l_emp_info_rec.dpt6_cd                        -- ６階層目部門コード
              , l_emp_info_rec.sup_assignment_number          -- 上長アサイメント番号
              , l_emp_info_rec.date_start                     -- 開始日
              , l_emp_info_rec.actual_termination_date        -- 退職日
              , cn_created_by                                 -- 作成者
              , cd_creation_date                              -- 作成日
              , cn_last_updated_by                            -- 最終更新者
              , cd_last_update_date                           -- 最終更新日
              , cn_last_update_login                          -- 最終更新ログイン
              , cn_request_id                                 -- 要求ID
              , cn_program_application_id                     -- コンカレント・プログラム・アプリケーションID
              , cn_program_id                                 -- コンカレント・プログラムID
              , cd_program_update_date                        -- プログラム更新日
            );
          EXCEPTION
            WHEN OTHERS THEN
              -- 登録に失敗した場合
              lv_errmsg := SUBSTRB(
                             xxccp_common_pkg.get_msg(
                               iv_application  => cv_appl_xxcmm             -- アプリケーション短縮名：XXCMM
                             , iv_name         => cv_insert_err_msg         -- メッセージ名：挿入エラーメッセージ
                             , iv_token_name1  => cv_tkn_table              -- トークン名1：TABLE
                             , iv_token_value1 => cv_oic_emp_info_tbl_msg   -- トークン値1：OIC社員差分情報テーブル
                             , iv_token_name2  => cv_tkn_err_msg            -- トークン名2：ERR_MSG
                             , iv_token_value2 => SQLERRM                   -- トークン値2：SQLERRM
                             )
                           , 1
                           , 5000
                           );
              lv_errbuf  := lv_errmsg;
              RAISE global_process_expt;
          END;
        --
        ELSE
          -- 個人ID（社員差分情報）がNOT NULLの場合
          --
          BEGIN
            -- OIC社員差分情報テーブルの更新
            UPDATE
                xxcmm_oic_emp_diff_info  xoedi  -- OIC社員差分情報テーブル
            SET
                xoedi.last_name                = l_emp_info_rec.last_name                   -- カナ姓
              , xoedi.first_name               = l_emp_info_rec.first_name                  -- カナ名
              , xoedi.location_code            = l_emp_info_rec.location_code               -- 拠点コード
              , xoedi.license_code             = l_emp_info_rec.license_code                -- 資格コード
              , xoedi.job_post                 = l_emp_info_rec.job_post                    -- 職位コード
              , xoedi.job_duty                 = l_emp_info_rec.job_duty                    -- 職務コード
              , xoedi.job_type                 = l_emp_info_rec.job_type                    -- 職種コード
              , xoedi.dpt1_cd                  = l_emp_info_rec.dpt1_cd                     -- １階層目部門コード
              , xoedi.dpt2_cd                  = l_emp_info_rec.dpt2_cd                     -- ２階層目部門コード
              , xoedi.dpt3_cd                  = l_emp_info_rec.dpt3_cd                     -- ３階層目部門コード
              , xoedi.dpt4_cd                  = l_emp_info_rec.dpt4_cd                     -- ４階層目部門コード
              , xoedi.dpt5_cd                  = l_emp_info_rec.dpt5_cd                     -- ５階層目部門コード
              , xoedi.dpt6_cd                  = l_emp_info_rec.dpt6_cd                     -- ６階層目部門コード
              , xoedi.sup_assignment_number    = l_emp_info_rec.sup_assignment_number       -- 上長アサイメント番号
              , xoedi.date_start               = l_emp_info_rec.date_start                  -- 開始日
              , xoedi.actual_termination_date  = l_emp_info_rec.actual_termination_date     -- 退職日
              , xoedi.last_update_date         = cd_last_update_date                        -- 最終更新日
              , xoedi.last_updated_by          = cn_last_updated_by                         -- 最終更新者
              , xoedi.last_update_login        = cn_last_update_login                       -- 最終更新ログイン
              , xoedi.request_id               = cn_request_id                              -- 要求ID
              , xoedi.program_application_id   = cn_program_application_id                  -- プログラムアプリケーションID
              , xoedi.program_id               = cn_program_id                              -- プログラムID
              , xoedi.program_update_date      = cd_program_update_date                     -- プログラム更新日
            WHERE
                xoedi.person_id                = l_emp_info_rec.xoedi_person_id             -- 個人ID（社員差分情報）
            ;
          EXCEPTION
            WHEN OTHERS THEN
              -- 更新に失敗した場合
              lv_errmsg := SUBSTRB(
                             xxccp_common_pkg.get_msg(
                               iv_application  => cv_appl_xxcmm             -- アプリケーション短縮名：XXCMM
                             , iv_name         => cv_update_err_msg         -- メッセージ名：更新エラーメッセージ
                             , iv_token_name1  => cv_tkn_table              -- トークン名1：TABLE
                             , iv_token_value1 => cv_oic_emp_info_tbl_msg   -- トークン値1：OIC社員差分情報テーブル
                             , iv_token_name2  => cv_tkn_err_msg            -- トークン名2：ERR_MSG
                             , iv_token_value2 => SQLERRM                   -- トークン値2：SQLERRM
                             )
                           , 1
                           , 5000
                           );
              lv_errbuf  := lv_errmsg;
              RAISE global_process_expt;
          END;
        END IF;
      END IF;
      --
      --
-- Ver1.17 Mod Start
--      -- ==============================================================
--      -- OIC社員差分情報バックアップテーブルの登録処理(A-6-5)
--      -- ==============================================================
      -- ==============================================================
      -- OIC社員差分情報バックアップテーブルの登録処理(A-6-6)
      -- ==============================================================

-- Ver1.17 Mod End
      IF (    l_emp_info_rec.roll_change_flag  = cv_y
           OR l_emp_info_rec.other_change_flag = cv_y ) THEN
        -- ロール変更フラグがY、または、その他変更フラグがYの場合
        --
        BEGIN
          -- OIC社員差分情報バックアップテーブルの登録
          INSERT INTO xxcmm_oic_emp_diff_info_bk (
              person_id                                     -- 個人ID
            , employee_number                               -- 従業員番号
            , user_name                                     -- ユーザー名
            , pre_last_name                                 -- 前回カナ姓
            , pre_first_name                                -- 前回カナ名
            , pre_location_code                             -- 前回拠点コード
            , pre_license_code                              -- 前回資格コード
            , pre_job_post                                  -- 前回職位コード
            , pre_job_duty                                  -- 前回職務コード
            , pre_job_type                                  -- 前回職種コード
            , pre_dpt1_cd                                   -- 前回１階層目部門コード
            , pre_dpt2_cd                                   -- 前回２階層目部門コード
            , pre_dpt3_cd                                   -- 前回３階層目部門コード
            , pre_dpt4_cd                                   -- 前回４階層目部門コード
            , pre_dpt5_cd                                   -- 前回５階層目部門コード
            , pre_dpt6_cd                                   -- 前回６階層目部門コード
            , pre_sup_assignment_number                     -- 前回上長アサイメント番号
            , pre_date_start                                -- 前回開始日
            , pre_actual_termination_date                   -- 前回退職日
            , last_name                                     -- カナ姓
            , first_name                                    -- カナ名
            , location_code                                 -- 拠点コード
            , license_code                                  -- 資格コード
            , job_post                                      -- 職位コード
            , job_duty                                      -- 職務コード
            , job_type                                      -- 職種コード
            , dpt1_cd                                       -- １階層目部門コード
            , dpt2_cd                                       -- ２階層目部門コード
            , dpt3_cd                                       -- ３階層目部門コード
            , dpt4_cd                                       -- ４階層目部門コード
            , dpt5_cd                                       -- ５階層目部門コード
            , dpt6_cd                                       -- ６階層目部門コード
            , sup_assignment_number                         -- 上長アサイメント番号
            , date_start                                    -- 開始日
            , actual_termination_date                       -- 退職日
            , created_by                                    -- 作成者
            , creation_date                                 -- 作成日
            , last_updated_by                               -- 最終更新者
            , last_update_date                              -- 最終更新日
            , last_update_login                             -- 最終更新ログイン
            , request_id                                    -- 要求ID
            , program_application_id                        -- コンカレント・プログラム・アプリケーションID
            , program_id                                    -- コンカレント・プログラムID
            , program_update_date                           -- プログラム更新日
          ) VALUES (
              l_emp_info_rec.person_id                      -- 個人ID
            , l_emp_info_rec.employee_number                -- 従業員番号
            , l_emp_info_rec.user_name                      -- ユーザー名
            , l_emp_info_rec.pre_last_name                  -- 前回カナ姓
            , l_emp_info_rec.pre_first_name                 -- 前回カナ名
            , l_emp_info_rec.pre_location_code              -- 前回拠点コード
            , l_emp_info_rec.pre_license_code               -- 前回資格コード
            , l_emp_info_rec.pre_job_post                   -- 前回職位コード
            , l_emp_info_rec.pre_job_duty                   -- 前回職務コード
            , l_emp_info_rec.pre_job_type                   -- 前回職種コード
            , l_emp_info_rec.pre_dpt1_cd                    -- 前回１階層目部門コード
            , l_emp_info_rec.pre_dpt2_cd                    -- 前回２階層目部門コード
            , l_emp_info_rec.pre_dpt3_cd                    -- 前回３階層目部門コード
            , l_emp_info_rec.pre_dpt4_cd                    -- 前回４階層目部門コード
            , l_emp_info_rec.pre_dpt5_cd                    -- 前回５階層目部門コード
            , l_emp_info_rec.pre_dpt6_cd                    -- 前回６階層目部門コード
            , l_emp_info_rec.pre_sup_assignment_number      -- 前回上長アサイメント番号
            , l_emp_info_rec.pre_date_start                 -- 前回開始日
            , l_emp_info_rec.pre_actual_termination_date    -- 前回退職日
            , l_emp_info_rec.last_name                      -- カナ姓
            , l_emp_info_rec.first_name                     -- カナ名
            , l_emp_info_rec.location_code                  -- 拠点コード
            , l_emp_info_rec.license_code                   -- 資格コード
            , l_emp_info_rec.job_post                       -- 職位コード
            , l_emp_info_rec.job_duty                       -- 職務コード
            , l_emp_info_rec.job_type                       -- 職種コード
            , l_emp_info_rec.dpt1_cd                        -- １階層目部門コード
            , l_emp_info_rec.dpt2_cd                        -- ２階層目部門コード
            , l_emp_info_rec.dpt3_cd                        -- ３階層目部門コード
            , l_emp_info_rec.dpt4_cd                        -- ４階層目部門コード
            , l_emp_info_rec.dpt5_cd                        -- ５階層目部門コード
            , l_emp_info_rec.dpt6_cd                        -- ６階層目部門コード
            , l_emp_info_rec.sup_assignment_number          -- 上長アサイメント番号
            , l_emp_info_rec.date_start                     -- 開始日
            , l_emp_info_rec.actual_termination_date        -- 退職日
            , cn_created_by                                 -- 作成者
            , cd_creation_date                              -- 作成日
            , cn_last_updated_by                            -- 最終更新者
            , cd_last_update_date                           -- 最終更新日
            , cn_last_update_login                          -- 最終更新ログイン
            , cn_request_id                                 -- 要求ID
            , cn_program_application_id                     -- コンカレント・プログラム・アプリケーションID
            , cn_program_id                                 -- コンカレント・プログラムID
            , cd_program_update_date                        -- プログラム更新日
          );
        EXCEPTION
          WHEN OTHERS THEN
            -- 登録に失敗した場合
            lv_errmsg := SUBSTRB(
                           xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_xxcmm             -- アプリケーション短縮名：XXCMM
                           , iv_name         => cv_insert_err_msg         -- メッセージ名：挿入エラーメッセージ
                           , iv_token_name1  => cv_tkn_table              -- トークン名1：TABLE
                           , iv_token_value1 => cv_oic_emp_inf_bk_tbl_msg -- トークン値1：OIC社員差分情報バックアップテーブル
                           , iv_token_name2  => cv_tkn_err_msg            -- トークン名2：ERR_MSG
                           , iv_token_value2 => SQLERRM                   -- トークン値2：SQLERRM
                           )
                         , 1
                         , 5000
                         );
            lv_errbuf  := lv_errmsg;
            RAISE global_process_expt;
        END;
      END IF;
    --
    END LOOP output_emp_info_loop;
--
    -- カーソルクローズ
    CLOSE emp_info_cur;
--
  EXCEPTION
    -- *** ロックエラー例外ハンドラ ***
    WHEN global_lock_expt THEN
      -- カーソルクローズ
      IF ( emp_info_cur%ISOPEN ) THEN
        CLOSE emp_info_cur;
      END IF;
-- Ver1.17 Add Start
      -- カーソルクローズ
      IF ( new_emp_cur%ISOPEN ) THEN
        CLOSE new_emp_cur;
      END IF;
-- Ver1.17 Add End
      --
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm             -- アプリケーション短縮名：XXCMM
                   , iv_name         => cv_lock_err_msg           -- メッセージ名：ロックエラーメッセージ
                   , iv_token_name1  => cv_tkn_ng_table           -- トークン名1：NG_TABLE
                   , iv_token_value1 => cv_oic_emp_info_tbl_msg   -- トークン値1：OIC社員差分情報
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ファイル出力時例外ハンドラ ***
    WHEN global_fileout_expt THEN
      -- カーソルクローズ
      IF ( emp_info_cur%ISOPEN ) THEN
        CLOSE emp_info_cur;
      END IF;
-- Ver1.17 Add Start
      -- カーソルクローズ
      IF ( new_emp_cur%ISOPEN ) THEN
        CLOSE new_emp_cur;
      END IF;
-- Ver1.17 Add End
      --
      lv_errmsg := SUBSTRB(
                     xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_xxcmm             -- アプリケーション短縮名：XXCMM
                     , iv_name         => cv_file_write_err_msg     -- メッセージ名：ファイル書き込みエラーメッセージ
                     , iv_token_name1  => cv_tkn_sqlerrm            -- トークン名1：SQLERRM
                     , iv_token_value1 => SQLERRM                   -- トークン値1：SQLERRM
                     )
                   , 1
                   , 5000
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- カーソルクローズ
      IF ( emp_info_cur%ISOPEN ) THEN
        CLOSE emp_info_cur;
      END IF;
-- Ver1.17 Add Start
      -- カーソルクローズ
      IF ( new_emp_cur%ISOPEN ) THEN
        CLOSE new_emp_cur;
      END IF;
-- Ver1.17 Add End
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルクローズ
      IF ( emp_info_cur%ISOPEN ) THEN
        CLOSE emp_info_cur;
      END IF;
-- Ver1.17 Add Start
      -- カーソルクローズ
      IF ( new_emp_cur%ISOPEN ) THEN
        CLOSE new_emp_cur;
      END IF;
-- Ver1.17 Add End
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF ( emp_info_cur%ISOPEN ) THEN
        CLOSE emp_info_cur;
      END IF;
-- Ver1.17 Add Start
      -- カーソルクローズ
      IF ( new_emp_cur%ISOPEN ) THEN
        CLOSE new_emp_cur;
      END IF;
-- Ver1.17 Add End
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF ( emp_info_cur%ISOPEN ) THEN
        CLOSE emp_info_cur;
      END IF;
-- Ver1.17 Add Start
      -- カーソルクローズ
      IF ( new_emp_cur%ISOPEN ) THEN
        CLOSE new_emp_cur;
      END IF;
-- Ver1.17 Add End
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END output_emp_info;
--
--
  /**********************************************************************************
   * Procedure Name   : update_mng_tbl
   * Description      : 管理テーブル登録・更新処理(A-7)
   ***********************************************************************************/
  PROCEDURE update_mng_tbl(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_mng_tbl';       -- プログラム名
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
    IF ( gv_first_proc_flag = cv_y ) THEN
      -- 初回処理フラグがYの場合
      --
      BEGIN
        -- OIC連携処理管理テーブルの登録
        INSERT INTO xxccp_oic_if_process_mng (
            program_name                -- プログラム名
          , pre_process_date            -- 前回処理日時
          , created_by                  -- 作成者
          , creation_date               -- 作成日
          , last_updated_by             -- 最終更新者
          , last_update_date            -- 最終更新日
          , last_update_login           -- 最終更新ログイン
          , request_id                  -- 要求ID
          , program_application_id      -- コンカレント・プログラム・アプリケーションID
          , program_id                  -- コンカレント・プログラムID
          , program_update_date         -- プログラム更新日
        ) VALUES (
            gt_conc_program_name        -- プログラム名
          , gt_cur_process_date         -- 前回処理日時
          , cn_created_by               -- 作成者
          , cd_creation_date            -- 作成日
          , cn_last_updated_by          -- 最終更新者
          , cd_last_update_date         -- 最終更新日
          , cn_last_update_login        -- 最終更新ログイン
          , cn_request_id               -- 要求ID
          , cn_program_application_id   -- コンカレント・プログラム・アプリケーションID
          , cn_program_id               -- コンカレント・プログラムID
          , cd_program_update_date      -- プログラム更新日
        );
      EXCEPTION
        WHEN OTHERS THEN
          -- 登録に失敗した場合
          lv_errmsg := SUBSTRB(
                         xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_xxcmm             -- アプリケーション短縮名：XXCMM
                         , iv_name         => cv_insert_err_msg         -- メッセージ名：挿入エラーメッセージ
                         , iv_token_name1  => cv_tkn_table              -- トークン名1：TABLE
                         , iv_token_value1 => cv_oic_proc_mng_tbl_msg   -- トークン値1：OIC連携処理管理テーブル
                         , iv_token_name2  => cv_tkn_err_msg            -- トークン名2：ERR_MSG
                         , iv_token_value2 => SQLERRM                   -- トークン値2：SQLERRM
                         )
                       , 1
                       , 5000
                       );
          lv_errbuf  := lv_errmsg;
          RAISE global_process_expt;
      END;
    --
    ELSE
      --
      -- 初回処理フラグがNの場合
      BEGIN
        -- OIC連携処理管理テーブルの更新
        UPDATE
            xxccp_oic_if_process_mng  xoipm  -- OIC連携処理管理テーブル
        SET
            xoipm.pre_process_date       = gt_cur_process_date          -- 前回処理日時
          , xoipm.last_update_date       = cd_last_update_date          -- 最終更新日
          , xoipm.last_updated_by        = cn_last_updated_by           -- 最終更新者
          , xoipm.last_update_login      = cn_last_update_login         -- 最終更新ログイン
          , xoipm.request_id             = cn_request_id                -- 要求ID
          , xoipm.program_application_id = cn_program_application_id    -- プログラムアプリケーションID
          , xoipm.program_id             = cn_program_id                -- プログラムID
          , xoipm.program_update_date    = cd_program_update_date       -- プログラム更新日
        WHERE
            xoipm.program_name           = gt_conc_program_name         -- プログラム名
        ;
      EXCEPTION
        WHEN OTHERS THEN
          -- 更新に失敗した場合
          lv_errmsg := SUBSTRB(
                         xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_xxcmm             -- アプリケーション短縮名：XXCMM
                         , iv_name         => cv_update_err_msg         -- メッセージ名：更新エラーメッセージ
                         , iv_token_name1  => cv_tkn_table              -- トークン名1：TABLE
                         , iv_token_value1 => cv_oic_proc_mng_tbl_msg   -- トークン値1：OIC連携処理管理テーブル
                         , iv_token_name2  => cv_tkn_err_msg            -- トークン名2：ERR_MSG
                         , iv_token_value2 => SQLERRM                   -- トークン値2：SQLERRM
                         )
                       , 1
                       , 5000
                       );
          lv_errbuf  := lv_errmsg;
          RAISE global_process_expt;
      END;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END update_mng_tbl;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_proc_date_for_recovery  IN   VARCHAR2,       -- 1.業務日付（リカバリ用）
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
    -- 個別件数の初期化
    -- 抽出件数
    gn_get_wk_cnt             := 0;     -- 就業者抽出件数
    gn_get_per_name_cnt       := 0;     -- 個人名抽出件数
    gn_get_per_legi_cnt       := 0;     -- 個人国別仕様データ抽出件数
    gn_get_per_email_cnt      := 0;     -- 個人Eメール抽出件数
    gn_get_wk_rel_cnt         := 0;     -- 雇用関係（退職者）抽出件数
    gn_get_new_user_cnt       := 0;     -- ユーザー情報（新規）抽出件数
    gn_get_new_user_paas_cnt  := 0;     -- ユーザー情報（新規）PaaS用抽出件数
    gn_get_wk_terms_cnt       := 0;     -- 雇用条件抽出件数
    gn_get_ass_cnt            := 0;     -- アサイメント情報抽出件数
    gn_get_user_cnt           := 0;     -- ユーザー情報抽出件数
-- Ver1.2(E055) Add Start
    gn_get_user2_cnt          := 0;     -- ユーザー情報（削除）抽出件数
-- Ver1.2(E055) Add End
    gn_get_ass_sup_cnt        := 0;     -- アサイメント情報（上長）抽出件数
    gn_get_wk_rel2_cnt        := 0;     -- 雇用関係（新規採用退職者）抽出件数
    gn_get_bank_acc_cnt       := 0;     -- 従業員経費口座情報抽出件数
    gn_get_emp_info_cnt       := 0;     -- 社員差分情報抽出件数
    -- 出力件数
    gn_out_wk_cnt             := 0;     -- 従業員情報連携データファイル出力件数
    gn_out_p_new_user_cnt     := 0;     -- PaaS処理用の新規ユーザー情報ファイル出力件数
    gn_out_user_cnt           := 0;     -- ユーザー情報連携データファイル出力件数
-- Ver1.2(E055) Add Start
    gn_out_user2_cnt          := 0;     -- ユーザー情報（削除）連携データファイル出力件数
-- Ver1.2(E055) Add End
    gn_out_wk2_cnt            := 0;     -- 従業員情報（上長・新規採用退職者）連携データファイル出力件数
    gn_out_p_bank_acct_cnt    := 0;     -- PaaS処理用の従業員経費口座情報ファイル出力件数
    gn_out_p_emp_info_cnt     := 0;     -- PaaS処理用の社員差分情報ファイル出力件数
-- Ver1.17 Add Start
    gn_out_p_new_emp_cnt      := 0;     -- PaaS処理用の新入社員情報ファイル出力件数
-- Ver1.17 Add End
--
    --
    --===============================================
    -- 初期処理(A-1)
    --===============================================
    init(
      iv_proc_date_for_recovery => iv_proc_date_for_recovery  -- 業務日付（リカバリ用）ID
    , ov_errbuf                 => lv_errbuf                  -- エラー・メッセージ
    , ov_retcode                => lv_retcode                 -- リターン・コード
    , ov_errmsg                 => lv_errmsg                  -- ユーザー・エラー・メッセージ
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --================================================================
    -- 従業員情報の抽出・ファイル出力処理(A-2)
    --================================================================
    output_worker(
      ov_errbuf          => lv_errbuf           -- エラー・メッセージ
    , ov_retcode         => lv_retcode          -- リターン・コード
    , ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --================================================================
    -- ユーザー情報の抽出・ファイル出力処理(A-3)
    --================================================================
    output_user(
      ov_errbuf          => lv_errbuf           -- エラー・メッセージ
    , ov_retcode         => lv_retcode          -- リターン・コード
    , ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --================================================================
    -- 従業員情報（上長・新規採用退職者）の抽出・ファイル出力処理(A-4)
    --================================================================
    output_worker2(
      ov_errbuf          => lv_errbuf           -- エラー・メッセージ
    , ov_retcode         => lv_retcode          -- リターン・コード
    , ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --================================================================
    -- 従業員経費口座情報の抽出・ファイル出力処理(A-5)
    --================================================================
    output_emp_bank_acct(
      ov_errbuf          => lv_errbuf           -- エラー・メッセージ
    , ov_retcode         => lv_retcode          -- リターン・コード
    , ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --================================================================
    -- 社員差分情報の抽出・ファイル出力処理（PaaS処理用）(A-6)
    --================================================================
    output_emp_info(
      ov_errbuf          => lv_errbuf           -- エラー・メッセージ
    , ov_retcode         => lv_retcode          -- リターン・コード
    , ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --===============================================
    -- 管理テーブル登録・更新処理(A-7)
    --===============================================
    update_mng_tbl(
      ov_errbuf          => lv_errbuf           -- エラー・メッセージ
    , ov_retcode         => lv_retcode          -- リターン・コード
    , ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    --
    IF (lv_retcode = cv_status_error) THEN
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
    errbuf                     OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode                    OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_proc_date_for_recovery  IN  VARCHAR2       --   業務日付（リカバリ用）
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
--
    lv_msg             VARCHAR2(3000);  -- メッセージ
    -- 抽出件数用レコード
    TYPE l_get_cnt_rtype IS RECORD
    (
      target           VARCHAR2(100)    -- 抽出対象
    , cnt              VARCHAR2(10)     -- 件数（メッセージ用）
    );
    -- 抽出件数用テーブル
    TYPE l_get_cnt_ttype IS TABLE OF l_get_cnt_rtype INDEX BY BINARY_INTEGER;
    l_get_cnt_tab    l_get_cnt_ttype;
--
    -- 出力件数用レコード
    TYPE l_out_cnt_rtype IS RECORD
    (
      target           VARCHAR2(100)    -- 出力対象
    , cnt              VARCHAR2(10)     -- 件数（メッセージ用）
    );
    -- 出力件数用テーブル
    TYPE l_out_cnt_ttype IS TABLE OF l_out_cnt_rtype INDEX BY BINARY_INTEGER;
    l_out_cnt_tab    l_out_cnt_ttype;
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
       iv_proc_date_for_recovery
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    -- エラーの場合
    IF (lv_retcode = cv_status_error) THEN
      --
      -- 各出力件数の初期化（0件）
      gn_out_wk_cnt           := 0;     -- 従業員情報連携データファイル出力件数
      gn_out_p_new_user_cnt   := 0;     -- PaaS処理用の新規ユーザー情報ファイル出力件数
      gn_out_user_cnt         := 0;     -- ユーザー情報連携データファイル出力件数
-- Ver1.2(E055) Add Start
      gn_out_user2_cnt        := 0;     -- ユーザー情報（削除）連携データファイル出力件数
-- Ver1.2(E055) Add End
      gn_out_wk2_cnt          := 0;     -- 従業員情報（上長・新規採用退職者）連携データファイル出力件数
      gn_out_p_bank_acct_cnt  := 0;     -- PaaS処理用の従業員経費口座情報ファイル出力件数
      gn_out_p_emp_info_cnt   := 0;     -- PaaS処理用の社員差分情報ファイル出力件数
-- Ver1.17 Add Start
      gn_out_p_new_emp_cnt    := 0;     -- PaaS処理用の新入社員情報ファイル出力件数
-- Ver1.17 Add End
      --
      -- エラー件数の設定
      gn_error_cnt            := 1;
      --
      -- スキップ件数の初期化（0件）
      gn_warn_cnt             := 0;
      --
      -- エラーメッセージの出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --===============================================
    -- 終了処理(A-8)
    --===============================================
--
    -------------------------------------------------
    -- ファイルクローズ
    -------------------------------------------------
    -- 従業員情報連携データファイル
    IF ( UTL_FILE.IS_OPEN ( gf_wrk_file_handle )) THEN
      UTL_FILE.FCLOSE( gf_wrk_file_handle );
    END IF;
    -- 従業員情報（上長・新規採用退職者）連携データファイル
    IF ( UTL_FILE.IS_OPEN ( gf_wrk2_file_handle )) THEN
      UTL_FILE.FCLOSE( gf_wrk2_file_handle );
    END IF;
    -- ユーザー情報連携データファイル
    IF ( UTL_FILE.IS_OPEN ( gf_usr_file_handle )) THEN
      UTL_FILE.FCLOSE( gf_usr_file_handle );
    END IF;
-- Ver1.2(E055) Add Start
    -- ユーザー情報（削除）連携データファイル
    IF ( UTL_FILE.IS_OPEN ( gf_usr2_file_handle )) THEN
      UTL_FILE.FCLOSE( gf_usr2_file_handle );
    END IF;
-- Ver1.2(E055) Add End
    -- PaaS処理用の新規ユーザー情報ファイル
    IF ( UTL_FILE.IS_OPEN ( gf_new_usr_file_handle )) THEN
      UTL_FILE.FCLOSE( gf_new_usr_file_handle );
    END IF;
    -- PaaS処理用の従業員経費口座情報ファイル
    IF ( UTL_FILE.IS_OPEN ( gf_emp_bnk_file_handle )) THEN
      UTL_FILE.FCLOSE( gf_emp_bnk_file_handle );
    END IF;
    -- PaaS処理用の社員差分情報ファイル
    IF ( UTL_FILE.IS_OPEN ( gf_emp_inf_file_handle )) THEN
      UTL_FILE.FCLOSE( gf_emp_inf_file_handle );
    END IF;
-- Ver1.17 Add Start
    -- PaaS処理用の新入社員情報ファイル
    IF ( UTL_FILE.IS_OPEN ( gf_new_emp_file_handle )) THEN
      UTL_FILE.FCLOSE( gf_new_emp_file_handle );
    END IF;
-- Ver1.17 Add End
--    
    -------------------------------------------------
    -- 抽出件数の出力
    -------------------------------------------------
    -- 就業者抽出件数
    l_get_cnt_tab(1).target  := cv_worker_msg;
    l_get_cnt_tab(1).cnt     := TO_CHAR(gn_get_wk_cnt);
    -- 個人名抽出件数
    l_get_cnt_tab(2).target  := cv_per_name_msg;
    l_get_cnt_tab(2).cnt     := TO_CHAR(gn_get_per_name_cnt);
    -- 個人国別仕様データ抽出件数
    l_get_cnt_tab(3).target  := cv_per_legi_msg;
    l_get_cnt_tab(3).cnt     := TO_CHAR(gn_get_per_legi_cnt);
    -- 個人Eメール抽出件数
    l_get_cnt_tab(4).target  := cv_per_email_msg;
    l_get_cnt_tab(4).cnt     := TO_CHAR(gn_get_per_email_cnt);
    -- 雇用関係（退職者）抽出件数
    l_get_cnt_tab(5).target  := cv_work_relation_msg;
    l_get_cnt_tab(5).cnt     := TO_CHAR(gn_get_wk_rel_cnt);
    -- ユーザー情報（新規）抽出件数
    l_get_cnt_tab(6).target  := cv_new_user_info_msg;
    l_get_cnt_tab(6).cnt     := TO_CHAR(gn_get_new_user_cnt);
    -- ユーザー情報（新規）PaaS用抽出件数
    l_get_cnt_tab(7).target  := cv_new_user_info_paas_msg;
    l_get_cnt_tab(7).cnt     := TO_CHAR(gn_get_new_user_paas_cnt);
    -- 雇用条件抽出件数
    l_get_cnt_tab(8).target  := cv_work_term_msg;
    l_get_cnt_tab(8).cnt     := TO_CHAR(gn_get_wk_terms_cnt);
    -- アサイメント情報抽出件数
    l_get_cnt_tab(9).target  := cv_assignment_msg;
    l_get_cnt_tab(9).cnt     := TO_CHAR(gn_get_ass_cnt);
    -- ユーザー情報抽出件数
    l_get_cnt_tab(10).target  := cv_user_info_msg;
    l_get_cnt_tab(10).cnt     := TO_CHAR(gn_get_user_cnt);
-- Ver1.2(E055) Add Start
    -- ユーザー情報（削除）抽出件数
    l_get_cnt_tab(11).target  := cv_user2_info_msg;
    l_get_cnt_tab(11).cnt     := TO_CHAR(gn_get_user2_cnt);
-- Ver1.2(E055) Add End
    -- アサイメント情報（上長）抽出件数
    l_get_cnt_tab(12).target := cv_sup_assignment_msg;
    l_get_cnt_tab(12).cnt    := TO_CHAR(gn_get_ass_sup_cnt);
    -- 雇用関係（新規採用退職者）抽出件数
    l_get_cnt_tab(13).target := cv_work_relation_2_msg;
    l_get_cnt_tab(13).cnt    := TO_CHAR(gn_get_wk_rel2_cnt);
    -- 従業員経費口座情報抽出件数
    l_get_cnt_tab(14).target := cv_emp_bank_acct_msg;
    l_get_cnt_tab(14).cnt    := TO_CHAR(gn_get_bank_acc_cnt);
    -- 社員差分情報抽出件数
    l_get_cnt_tab(15).target := cv_emp_info_msg;
    l_get_cnt_tab(15).cnt    := TO_CHAR(gn_get_emp_info_cnt);
    --
    <<get_count_out_loop>>
    FOR i IN 1..l_get_cnt_tab.COUNT LOOP
      --
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appl_xxcmm             -- アプリケーション短縮名：XXCMM
                , iv_name         => cv_search_trgt_cnt_msg    -- メッセージ名：検索対象・件数メッセージ
                , iv_token_name1  => cv_tkn_target             -- トークン名1：TARGET
                , iv_token_value1 => l_get_cnt_tab(i).target   -- トークン値1：抽出対象
                , iv_token_name2  => cv_tkn_count              -- トークン名2：COUNT
                , iv_token_value2 => l_get_cnt_tab(i).cnt      -- トークン値2：抽出件数
                );
      --
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msg
      );
    END LOOP file_name_out_loop;
    --
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--  
    -------------------------------------------------
    -- 出力件数の出力
    -------------------------------------------------
    -- 従業員情報連携データファイル
    l_out_cnt_tab(1).target  := gt_prf_val_wrk_out_file;
    l_out_cnt_tab(1).cnt     := TO_CHAR(gn_out_wk_cnt);
    -- PaaS処理用の新規ユーザー情報ファイル
    l_out_cnt_tab(2).target  := gt_prf_val_new_usr_out_file;
    l_out_cnt_tab(2).cnt     := TO_CHAR(gn_out_p_new_user_cnt);
    -- ユーザー情報連携データファイル
    l_out_cnt_tab(3).target  := gt_prf_val_usr_out_file;
    l_out_cnt_tab(3).cnt     := TO_CHAR(gn_out_user_cnt);
-- Ver1.2(E055) Add Start
    -- ユーザー情報（削除）連携データファイル
    l_out_cnt_tab(4).target  := gt_prf_val_usr2_out_file;
    l_out_cnt_tab(4).cnt     := TO_CHAR(gn_out_user2_cnt);
-- Ver1.2(E055) Add End
    -- 従業員情報（上長・新規採用退職者）連携データファイル
    l_out_cnt_tab(5).target  := gt_prf_val_wrk2_out_file;
    l_out_cnt_tab(5).cnt     := TO_CHAR(gn_out_wk2_cnt);
    -- PaaS処理用の従業員経費口座情報ファイル
    l_out_cnt_tab(6).target  := gt_prf_val_emp_bnk_out_file;
    l_out_cnt_tab(6).cnt     := TO_CHAR(gn_out_p_bank_acct_cnt);
    -- PaaS処理用の社員差分情報ファイル
    l_out_cnt_tab(7).target  := gt_prf_val_emp_inf_out_file;
    l_out_cnt_tab(7).cnt     := TO_CHAR(gn_out_p_emp_info_cnt);
-- Ver1.17 Add Start
    -- PaaS処理用の新入社員情報ファイル
    l_out_cnt_tab(8).target  := gt_prf_val_new_emp_out_file;
    l_out_cnt_tab(8).cnt     := TO_CHAR(gn_out_p_new_emp_cnt);
-- Ver1.17 Add End
    --
    <<out_count_out_loop>>
    FOR i IN 1..l_out_cnt_tab.COUNT LOOP
      --
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appl_xxcmm             -- アプリケーション短縮名：XXCMM
                , iv_name         => cv_file_trgt_cnt_msg      -- メッセージ名：ファイル出力対象・件数メッセージ
                , iv_token_name1  => cv_tkn_target             -- トークン名1：TARGET
                , iv_token_value1 => l_out_cnt_tab(i).target   -- トークン値1：出力対象
                , iv_token_name2  => cv_tkn_count              -- トークン名2：COUNT
                , iv_token_value2 => l_out_cnt_tab(i).cnt      -- トークン値2：出力件数
                );
      --
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msg
      );
    END LOOP out_count_out_loop;
    --
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -------------------------------------------------
    -- 合計件数の出力
    -------------------------------------------------
    -- 対象件数（抽出件数の合計）を設定
    gn_target_cnt := gn_get_wk_cnt +
                     gn_get_per_name_cnt +
                     gn_get_per_legi_cnt +
                     gn_get_per_email_cnt +
                     gn_get_wk_rel_cnt +
                     gn_get_new_user_cnt +
                     gn_get_new_user_paas_cnt +
                     gn_get_wk_terms_cnt +
                     gn_get_ass_cnt +
                     gn_get_user_cnt +
-- Ver1.2(E055) Add Start
                     gn_get_user2_cnt +
-- Ver1.2(E055) Add End
                     gn_get_ass_sup_cnt +
                     gn_get_wk_rel2_cnt +
                     gn_get_bank_acc_cnt +
                     gn_get_emp_info_cnt;
    --
    -- 成功件数（出力件数の合計）を設定
    gn_normal_cnt := gn_out_wk_cnt +
                     gn_out_p_new_user_cnt +
                     gn_out_user_cnt +
-- Ver1.2(E055) Add Start
                     gn_out_user2_cnt +
-- Ver1.2(E055) Add End
                     gn_out_wk2_cnt +
                     gn_out_p_bank_acct_cnt +
-- Ver1.17 Mod Start
--                     gn_out_p_emp_info_cnt;
                     gn_out_p_emp_info_cnt +
                     gn_out_p_new_emp_cnt;
-- Ver1.17 Mod End
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
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
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
END XXCMM002A10C;
/
