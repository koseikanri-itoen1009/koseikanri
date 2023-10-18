CREATE OR REPLACE PACKAGE BODY APPS.XXCMM001A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 *
 * Package Name     : XXCMM001A02C (body)
 * Description      : 仕入先マスタIF抽出_EBSコンカレント
 * MD.050           : T_MD050_CMM_001_A02_仕入先マスタIF抽出_EBSコンカレント
 * Version          : 1.12
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  nvl_by_status_code     ステータス・コードによるNVL
 *  to_csv_string          CSVファイル用文字列変換（ステータス・コード指定あり）
 *  to_csv_string          CSVファイル用文字列変換
 *  init                   初期処理(A-1)
 *  output_supplier        「①サプライヤ」連携データの抽出・ファイル出力処理(A-2)
 *  output_sup_addr        「②サプライヤ・住所」連携データの抽出・ファイル出力処理(A-3)
 *  output_sup_site        「③サプライヤ・サイト」連携データの抽出・ファイル出力処理(A-4)
 *  output_sup_site_ass    「④サプライヤ・BU割当」連携データの抽出・ファイル出力処理(A-5)
 *  output_sup_contact     「⑤サプライヤ・担当者」連携データの抽出・ファイル出力処理(A-6)
 *  output_sup_contact_addr「⑥サプライヤ・担当者住所」連携データの抽出・ファイル出力処理(A-7)
 *  output_sup_payee       「⑦サプライヤ・支払先」連携データの抽出・ファイル出力処理(A-8)
 *  output_sup_bank_acct   「⑧サプライヤ・銀行口座」連携データの抽出・ファイル出力処理(A-9)
 *  output_sup_bank_use    「⑨サプライヤ・銀行口座割当」連携データの抽出・ファイル出力処理(A-10)
 *  output_party_tax_prf   「⑩パーティ税金プロファイル」連携データの抽出・ファイル出力処理(A-11)
 *  output_bank_update     「⑪銀行口座更新用」データの抽出・ファイル出力処理(A-12)
 *  update_mng_tbl         管理テーブル登録・更新処理(A-13)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2022-12-02    1.0   Y.Ooyama         新規作成
 *  2022-12-12    1.1   Y.Ooyama         E113対応
 *  2022-12-13    1.2   Y.Ooyama         E114,E115対応
 *  2022-12-15    1.3   Y.Ooyama         E117,E118,E119,E120,E121対応
 *  2022-12-20    1.4   Y.Ooyama         E123,E124,E125,E126対応
 *  2023-01-06    1.5   Y.Fuku           パラレル化対応（移行向け）
 *  2023-02-07    1.6   Y.Ooyama         移行障害No.11対応
 *  2023-02-08    1.7   Y.Ooyama         シナリオテスト不具合No.ST0003対応
 *  2023-02-21    1.8   Y.Ooyama         シナリオテスト不具合No.ST0018対応
 *  2023-03-22    1.9   Y.Ooyama         移行障害No.5対応
 *  2023-06-20    1.10  F.Hasebe         初期流動障害No.4対応
 *  2023-07-03    1.11  Y.Sato           E_本稼動_19314対応
 *  2023-09-21    1.12  S.hosonuma       E_本稼動_19311対応
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
  -- ロックエラー例外
  global_lock_expt          EXCEPTION;
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCMM001A02C'; -- パッケージ名
--
  -- アプリケーション短縮名
  cv_appl_xxcmm             CONSTANT VARCHAR2(5) := 'XXCMM';                -- アドオン：マスタ・マスタ領域
  cv_appl_xxccp             CONSTANT VARCHAR2(5) := 'XXCCP';                -- アドオン：共通・IF領域
  cv_appl_xxcoi             CONSTANT VARCHAR2(5) := 'XXCOI';                -- アドオン：在庫領域
--
  -- 日付書式
  cv_date_fmt               CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';
  cv_datetime_fmt           CONSTANT VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS';
  cv_datetime_id_fmt        CONSTANT VARCHAR2(16) := 'YYYYMMDDHH24MISS';
--
  -- 固定文字
  cv_slash                  CONSTANT VARCHAR2(1)  := '/';
  cv_comma                  CONSTANT VARCHAR2(1)  := ',';
  cv_space                  CONSTANT VARCHAR2(1)  := ' ';
  cv_ast                    CONSTANT VARCHAR2(1)  := '*';
--
  cv_open_mode_w            CONSTANT VARCHAR2(1)  := 'W';                               -- 書き込みモード
  cn_max_linesize           CONSTANT BINARY_INTEGER := 32767;                           -- ファイルサイズ
  cv_sharp_null             CONSTANT VARCHAR2(5)  := '#NULL';                           -- #NULL
--
  cv_target_ou_name         CONSTANT VARCHAR2(8)  := 'SALES-OU';                        -- 検索対象OU
  cv_status_create          CONSTANT VARCHAR2(6)  := 'CREATE';
  cv_status_update          CONSTANT VARCHAR2(6)  := 'UPDATE';
  cv_spend_authorized       CONSTANT VARCHAR2(16) := 'SPEND_AUTHORIZED';
  cv_employee               CONSTANT VARCHAR2(8)  := 'EMPLOYEE';
  cv_corporation            CONSTANT VARCHAR2(11) := 'Corporation';
  cv_jp                     CONSTANT VARCHAR2(2)  := 'JP';
  cv_express                CONSTANT VARCHAR2(7)  := 'EXPRESS';
  cv_email                  CONSTANT VARCHAR2(5)  := 'EMAIL';
  cv_fax                    CONSTANT VARCHAR2(3)  := 'FAX';
  cv_receipt                CONSTANT VARCHAR2(7)  := 'RECEIPT';
  cv_bearer_i               CONSTANT VARCHAR2(1)  := 'I';
  cv_bearer_x               CONSTANT VARCHAR2(1)  := 'X';
  cv_bearer_s               CONSTANT VARCHAR2(1)  := 'S';
  cv_bearer_n               CONSTANT VARCHAR2(1)  := 'N';
  cv_bearer_d               CONSTANT VARCHAR2(1)  := 'D';
  cv_sales_bu               CONSTANT VARCHAR2(8)  := 'SALES-BU';
  cv_party_sup              CONSTANT VARCHAR2(8)  := 'Supplier';
-- Ver1.3 Mod Start
--  cv_party_sup_site         CONSTANT VARCHAR2(13) := 'Supplier Site';
  cv_party_sup_site         CONSTANT VARCHAR2(13) := 'Supplier site';
-- Ver1.3 Mod End
  cv_line                   CONSTANT VARCHAR2(1)  := 'L';
  cv_line_desc              CONSTANT VARCHAR2(4)  := 'Line';
  cv_header                 CONSTANT VARCHAR2(1)  := 'Y';
  cv_header_desc            CONSTANT VARCHAR2(6)  := 'Header';
  cv_rule_n                 CONSTANT VARCHAR2(1)  := 'N';
-- Ver1.3 Mod Start
--  cv_rule_n_desc            CONSTANT VARCHAR2(4)  := 'Near';
  cv_rule_n_desc            CONSTANT VARCHAR2(7)  := 'Nearest';
-- Ver1.3 Mod End
  cv_rule_d                 CONSTANT VARCHAR2(1)  := 'D';
  cv_rule_d_desc            CONSTANT VARCHAR2(4)  := 'Down';
  cv_y                      CONSTANT VARCHAR2(1)  := 'Y';
  cv_yes                    CONSTANT VARCHAR2(3)  := 'Yes';
  cv_n                      CONSTANT VARCHAR2(1)  := 'N';
  cv_no                     CONSTANT VARCHAR2(2)  := 'No';
  cv_level_3                CONSTANT VARCHAR2(1)  := '3';
  cv_evac_create            CONSTANT VARCHAR2(1)  := 'C';
  cv_evac_update            CONSTANT VARCHAR2(1)  := 'U';
-- Ver1.4(E126) Add Start
  cv_yen                    CONSTANT VARCHAR2(3)  := 'JPY';
-- Ver1.4(E126) Add End
-- Ver1.9 Del Start
---- Ver1.5 Add Start
--  cn_divisor_ten            CONSTANT NUMBER       := 10;
---- Ver1.5 Add End
-- Ver1.9 Del End
--
  -- プロファイル
  -- XXCMM:OIC連携データファイル格納ディレクトリ名
  cv_prf_out_file_dir       CONSTANT VARCHAR2(30)  := 'XXCMM1_OIC_OUT_FILE_DIR';
  -- XXCMM:サプライヤ連携データファイル名（OIC連携）
  cv_prf_sup_out_file       CONSTANT VARCHAR2(30)  := 'XXCMM1_001A02_S_OUT_FILE_FIL';
  -- XXCMM:サプライヤ・住所連携データファイル名（OIC連携）
  cv_prf_sup_addr_out_file  CONSTANT VARCHAR2(30)  := 'XXCMM1_001A02_SA_OUT_FILE_FIL';
  -- XXCMM:サプライヤ・サイト連携データファイル名（OIC連携）
  cv_prf_site_out_file      CONSTANT VARCHAR2(30)  := 'XXCMM1_001A02_SS_OUT_FILE_FIL';
  -- XXCMM:サプライヤ・BU割当連携データファイル名（OIC連携）
  cv_prf_site_ass_out_file  CONSTANT VARCHAR2(30)  := 'XXCMM1_001A02_SSA_OUT_FILE_FIL';
  -- XXCMM:サプライヤ・担当者連携データファイル名（OIC連携）
  cv_prf_cont_out_file      CONSTANT VARCHAR2(30)  := 'XXCMM1_001A02_SC_OUT_FILE_FIL';
  -- XXCMM:サプライヤ・担当者住所連携データファイル名（OIC連携）
  cv_prf_cont_addr_out_file CONSTANT VARCHAR2(30)  := 'XXCMM1_001A02_SCA_OUT_FILE_FIL';
  -- XXCMM:サプライヤ・支払先連携データファイル名（OIC連携）
  cv_prf_payee_out_file     CONSTANT VARCHAR2(30)  := 'XXCMM1_001A02_SP_OUT_FILE_FIL';
  -- XXCMM:サプライヤ・銀行口座連携データファイル名（OIC連携）
  cv_prf_bnk_acct_out_file  CONSTANT VARCHAR2(30)  := 'XXCMM1_001A02_SBA_OUT_FILE_FIL';
  -- XXCMM:サプライヤ・銀行口座割当連携データファイル名（OIC連携）
  cv_prf_bnk_use_out_file   CONSTANT VARCHAR2(30)  := 'XXCMM1_001A02_SBU_OUT_FILE_FIL';
  -- XXCMM:パーティ税金プロファイル連携データファイル名（OIC連携）
  cv_prf_tax_prf_out_file   CONSTANT VARCHAR2(30)  := 'XXCMM1_001A02_TID_OUT_FILE_FIL';
  -- XXCMM:銀行口座更新用ファイル名（OIC連携）
  cv_prf_bnk_upd_out_file   CONSTANT VARCHAR2(30)  := 'XXCMM1_001A02_BAU_OUT_FILE_FIL';
  -- XXCMM:仕入先支払用ダミー（OIC連携）
  cv_prf_dmy_sup_payment    CONSTANT VARCHAR2(30)  := 'XXCMM1_001A02_DMY_SUP_PAYMENT';
-- Ver1.3 Add Start
  -- XXCMM:パーティ税金プロファイルレコードタイプ（OIC連携）
  cv_prf_ptp_record_type    CONSTANT VARCHAR2(30)  := 'XXCMM1_001A02_PTP_RECORD_TYPE';
-- Ver1.3 Add End
-- Ver1.9 Add Start
  -- XXCMM:パラレル数（OIC連携）
  cv_prf_parallel_num       CONSTANT VARCHAR2(30)  := 'XXCMM1_001A02_PARALLEL_NUM';
-- Ver1.9 Add End
--
  -- メッセージ名
  cv_prof_get_err_msg       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00002';                -- プロファイル取得エラーメッセージ
  cv_dir_path_get_err_msg   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-00029';                -- ディレクトリフルパス取得エラーメッセージ
  cv_if_file_name_msg       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60003';                -- IFファイル名出力メッセージ
  cv_file_exist_err_msg     CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60004';                -- 同一ファイル存在エラーメッセージ
  cv_lock_err_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00008';                -- ロックエラーメッセージ
  cv_process_date_msg       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60005';                -- 処理日時出力メッセージ
  cv_orgid_get_err_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00015';                -- 組織ID取得エラーメッセージ
  cv_search_trgt_cnt_msg    CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60006';                -- 検索対象・件数メッセージ
  cv_file_open_err_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00487';                -- ファイルオープンエラーメッセージ
  cv_file_write_err_msg     CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00488';                -- ファイル書き込みエラーメッセージ
  cv_file_trgt_cnt_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60007';                -- ファイル出力対象・件数メッセージ
  cv_insert_err_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00054';                -- 挿入エラーメッセージ
  cv_update_err_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00055';                -- 更新エラーメッセージ
  cv_evac_data_out_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60013';                -- 退避情報更新出力メッセージ
  -- メッセージ名(トークン)
  cv_oic_proc_mng_tbl_msg   CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60008';                -- OIC連携処理管理テーブル
  cv_oic_sup_evac_tbl_msg   CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60014';                -- OIC仕入先退避テーブル
  cv_oic_site_evac_tbl_msg  CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60015';                -- OIC仕入先サイト退避テーブル
  cv_oic_cont_evac_tbl_msg  CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60016';                -- OIC仕入先担当者退避テーブル
  cv_oic_bank_evac_tbl_msg  CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60017';                -- OIC銀行口座退避テーブル
  cv_sup_msg                CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60018';                -- サプライヤ
  cv_sup_addr_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60019';                -- サプライヤ・住所
  cv_site_msg               CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60020';                -- サプライヤ・サイト
  cv_site_ass_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60021';                -- サプライヤ・BU割当
  cv_cont_msg               CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60022';                -- サプライヤ・担当者
  cv_cont_addr_msg          CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60023';                -- サプライヤ・担当者住所
  cv_payee_msg              CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60024';                -- サプライヤ・支払先
  cv_bnk_acct_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60025';                -- サプライヤ・銀行口座
  cv_bnk_use_msg            CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60026';                -- サプライヤ・銀行口座割当
  cv_tax_prf_msg            CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60027';                -- パーティ税金プロファイル
  cv_bnk_upd_msg            CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60028';                -- 銀行口座更新用
--
  -- トークン名
  cv_tkn_ng_profile         CONSTANT VARCHAR2(30)  := 'NG_PROFILE';                      -- トークン名(NG_PROFILE)
  cv_tkn_dir_tok            CONSTANT VARCHAR2(30)  := 'DIR_TOK';                         -- トークン名(DIR_TOK)
  cv_tkn_file_name          CONSTANT VARCHAR2(30)  := 'FILE_NAME';                       -- トークン名(FILE_NAME)
  cv_tkn_ng_table           CONSTANT VARCHAR2(30)  := 'NG_TABLE';                        -- トークン名(NG_TABLE)
  cv_tkn_date1              CONSTANT VARCHAR2(30)  := 'DATE1';                           -- トークン名(DATE1)
  cv_tkn_date2              CONSTANT VARCHAR2(30)  := 'DATE2';                           -- トークン名(DATE2)
  cv_tkn_ng_ou_name         CONSTANT VARCHAR2(30)  := 'NG_OU_NAME';                      -- トークン名(NG_OU_NAME)
  cv_tkn_target             CONSTANT VARCHAR2(30)  := 'TARGET';                          -- トークン名(TARGET)
  cv_tkn_count              CONSTANT VARCHAR2(30)  := 'COUNT';                           -- トークン名(COUNT)
  cv_tkn_table              CONSTANT VARCHAR2(30)  := 'TABLE';                           -- トークン名(TABLE)
  cv_tkn_err_msg            CONSTANT VARCHAR2(30)  := 'ERR_MSG';                         -- トークン名(ERR_MSG)
  cv_tkn_sqlerrm            CONSTANT VARCHAR2(30)  := 'SQLERRM';                         -- トークン名(SQLERRM)
  cv_tkn_id                 CONSTANT VARCHAR2(30)  := 'ID';                              -- トークン名(ID)
  cv_tkn_before_value       CONSTANT VARCHAR2(30)  := 'BEFORE_VALUE';                    -- トークン名(BEFORE_VALUE)
  cv_tkn_after_value        CONSTANT VARCHAR2(30)  := 'AFTER_VALUE';                     -- トークン名(AFTER_VALUE)
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- プロファイル
  -- XXCMM:OIC連携データファイル格納ディレクトリ名
  gt_prf_val_out_file_dir       fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCMM:サプライヤ連携データファイル名（OIC連携）
  gt_prf_val_sup_out_file       fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCMM:サプライヤ・住所連携データファイル名（OIC連携）
  gt_prf_val_sup_addr_out_file  fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCMM:サプライヤ・サイト連携データファイル名（OIC連携）
  gt_prf_val_site_out_file      fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCMM:サプライヤ・BU割当連携データファイル名（OIC連携）
  gt_prf_val_site_ass_out_file  fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCMM:サプライヤ・担当者連携データファイル名（OIC連携）
  gt_prf_val_cont_out_file      fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCMM:サプライヤ・担当者住所連携データファイル名（OIC連携）
  gt_prf_val_cont_addr_out_file fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCMM:サプライヤ・支払先連携データファイル名（OIC連携）
  gt_prf_val_payee_out_file     fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCMM:サプライヤ・銀行口座連携データファイル名（OIC連携）
  gt_prf_val_bnk_acct_out_file  fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCMM:サプライヤ・銀行口座割当連携データファイル名（OIC連携）
  gt_prf_val_bnk_use_out_file   fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCMM:パーティ税金プロファイル連携データファイル名（OIC連携）
  gt_prf_val_tax_prf_out_file   fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCMM:銀行口座更新用ファイル名（OIC連携）
  gt_prf_val_bnk_upd_out_file   fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCMM:仕入先支払用ダミー（OIC連携）
  gt_prf_val_dmy_sup_payment    fnd_profile_option_values.profile_option_value%TYPE;
-- Ver1.3 Add Start
  -- XXCMM:パーティ税金プロファイルレコードタイプ（OIC連携）
  gt_prf_ptp_record_type        fnd_profile_option_values.profile_option_value%TYPE;
-- Ver1.3 Add End
-- Ver1.9 Add Start
  -- XXCMM:パラレル数（OIC連携）
  gt_prf_parallel_num           fnd_profile_option_values.profile_option_value%TYPE;
-- Ver1.9 Add End
--
  -- OIC連携処理管理テーブルの登録・更新データ
  gt_conc_program_name          fnd_concurrent_programs.concurrent_program_name%TYPE;    -- コンカレントプログラム名
  gt_pre_process_date           xxccp_oic_if_process_mng.pre_process_date%TYPE;          -- 前回処理日時
  gt_cur_process_date           xxccp_oic_if_process_mng.pre_process_date%TYPE;          -- 今回処理日時
--
  -- 検索条件
  gt_target_organization_id     hr_all_organization_units.organization_id%TYPE;          -- 検索対象組織ID
--
  -- ファイルハンドル
  gf_sup_file_handle            UTL_FILE.FILE_TYPE;         -- サプライヤ連携データファイル
  gf_sup_addr_file_handle       UTL_FILE.FILE_TYPE;         -- サプライヤ・住所連携データファイル
  gf_site_file_handle           UTL_FILE.FILE_TYPE;         -- サプライヤ・サイト連携データファイル
  gf_site_ass_file_handle       UTL_FILE.FILE_TYPE;         -- サプライヤ・BU割当連携データファイル
  gf_cont_file_handle           UTL_FILE.FILE_TYPE;         -- サプライヤ・担当者連携データファイル
  gf_cont_addr_file_handle      UTL_FILE.FILE_TYPE;         -- サプライヤ・担当者住所連携データファイル
  gf_payee_file_handle          UTL_FILE.FILE_TYPE;         -- サプライヤ・支払先連携データファイル
  gf_bnk_acct_file_handle       UTL_FILE.FILE_TYPE;         -- サプライヤ・銀行口座連携データファイル
  gf_bnk_use_file_handle        UTL_FILE.FILE_TYPE;         -- サプライヤ・銀行口座割当連携データファイル
  gf_tax_prf_file_handle        UTL_FILE.FILE_TYPE;         -- パーティ税金プロファイル連携データファイル
  gf_bnk_upd_file_handle        UTL_FILE.FILE_TYPE;         -- 銀行口座更新用ファイル
--
  -- 個別件数
  -- 抽出件数
  gn_get_sup_cnt                NUMBER;                     -- サプライヤ抽出件数
  gn_get_sup_addr_cnt           NUMBER;                     -- サプライヤ・住所抽出件数
  gn_get_site_cnt               NUMBER;                     -- サプライヤ・サイト抽出件数
  gn_get_site_ass_cnt           NUMBER;                     -- サプライヤ・BU割当抽出件数
  gn_get_cont_cnt               NUMBER;                     -- サプライヤ・担当者抽出件数
  gn_get_cont_addr_cnt          NUMBER;                     -- サプライヤ・担当者住所抽出件数
  gn_get_payee_cnt              NUMBER;                     -- サプライヤ・支払先抽出件数
  gn_get_bnk_acct_cnt           NUMBER;                     -- サプライヤ・銀行口座抽出件数
  gn_get_bnk_use_cnt            NUMBER;                     -- サプライヤ・銀行口座割当抽出件数
  gn_get_tax_prf_cnt            NUMBER;                     -- パーティ税金プロファイル抽出件数
  gn_get_bnk_upd_cnt            NUMBER;                     -- 銀行口座更新用抽出件数
  -- 出力件数
  gn_out_sup_cnt                NUMBER;                     -- サプライヤ連携データファイル出力件数
  gn_out_sup_addr_cnt           NUMBER;                     -- サプライヤ・住所連携データファイル出力件数
  gn_out_site_cnt               NUMBER;                     -- サプライヤ・サイト連携データファイル出力件数
  gn_out_site_ass_cnt           NUMBER;                     -- サプライヤ・BU割当連携データファイル出力件数
  gn_out_cont_cnt               NUMBER;                     -- サプライヤ・担当者連携データファイル出力件数
  gn_out_cont_addr_cnt          NUMBER;                     -- サプライヤ・担当者住所連携データファイル出力件数
  gn_out_payee_cnt              NUMBER;                     -- サプライヤ・支払先連携データファイル出力件数
  gn_out_bnk_acct_cnt           NUMBER;                     -- サプライヤ・銀行口座連携データファイル出力件数
  gn_out_bnk_use_cnt            NUMBER;                     -- サプライヤ・銀行口座割当連携データファイル出力件数
  gn_out_tax_prf_cnt            NUMBER;                     -- パーティ税金プロファイル連携データファイル出力件数
  gn_out_bnk_upd_cnt            NUMBER;                     -- 銀行口座更新用ファイル出力件数
--
-- Ver1.9 Add Start
  gn_parallel_num               NUMBER;                     -- プロファイル値「XXCMM:パラレル数（OIC連携）」を数値変換
-- Ver1.9 Add End
--
  /**********************************************************************************
   * Function Name    : nvl_by_status_code
   * Description      : ステータス・コードによるNVL
   ***********************************************************************************/
  FUNCTION nvl_by_status_code(
              iv_string          IN VARCHAR2,                 -- 対象文字列
              iv_status_code     IN VARCHAR2,                 -- ステータス・コード（CREATE/UPDATE）
              iv_c_nvl_string    IN VARCHAR2 DEFAULT NULL,    -- NULL時変換文字列(CREATE時)
              iv_u_nvl_string    IN VARCHAR2 DEFAULT NULL     -- NULL時変換文字列(UPDATE時)
           )
    RETURN VARCHAR2
  IS
  --
    -- *** ローカル定数 ***
    cv_prg_name         CONSTANT VARCHAR2(100) := 'nvl_by_status_code';
--
    -- *** ローカル変数 ***
    lv_string           VARCHAR2(3000);
  --
  BEGIN
--
    lv_string := iv_string;
    -- 
    IF ( lv_string IS NULL) THEN
      -- 対象文字列がNULLの場合
      IF ( iv_status_code = cv_status_create ) THEN
        -- ステータス・コードがCREATEの場合
        IF ( iv_c_nvl_string IS NOT NULL ) THEN
          -- NULL時変換文字列(CREATE時)の指定がある場合 → NULL時変換文字列(CREATE時)
          lv_string := iv_c_nvl_string;
        ELSE
          -- NULL時変換文字列(CREATE時)の指定がない場合 → NULL
          lv_string := NULL;
        END IF;
      --
      ELSE
        -- ステータス・コードがCREATE以外（UPDATE）の場合
        IF ( iv_u_nvl_string IS NOT NULL ) THEN
          -- NULL時変換文字列(UPDATE時)の指定がある場合 → NULL時変換文字列(UPDATE時)
          lv_string := iv_u_nvl_string;
        ELSE
          -- NULL時変換文字列(UPDATE時)の指定がない場合 → #NULL
          lv_string := cv_sharp_null;
        END IF;
      END IF;
    END IF;
--
    RETURN lv_string;
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
  END nvl_by_status_code;
--
--
  /**********************************************************************************
   * Function Name    : to_csv_string
   * Description      : CSVファイル用文字列変換（ステータス・コード指定あり）
   ***********************************************************************************/
  FUNCTION to_csv_string(
              iv_string          IN VARCHAR2,                 -- 対象文字列
              iv_status_code     IN VARCHAR2,                 -- ステータス・コード（CREATE/UPDATE）
              iv_c_nvl_string    IN VARCHAR2 DEFAULT NULL,    -- NULL時変換文字列(CREATE時)
              iv_u_nvl_string    IN VARCHAR2 DEFAULT NULL     -- NULL時変換文字列(UPDATE時)
           )
    RETURN VARCHAR2
  IS
  --
    -- *** ローカル定数 ***
    cv_prg_name         CONSTANT VARCHAR2(100) := 'to_csv_string';
--
    -- *** ローカル変数 ***
  --
  BEGIN
--
    -- 
    -- 対象文字列がNULLの場合
    IF ( iv_string IS NULL) THEN
      -- ステータス・コード（CREATE/UPDATE）によるNVLを実施
      RETURN nvl_by_status_code(
               iv_string
             , iv_status_code
             , iv_c_nvl_string
             , iv_u_nvl_string
             );
    END IF;
--
    -- 対象文字列がNOT NULLの場合
    -- OIC共通関数のCSVファイル用文字列変換を実施（LF置換単語は半角スペースを指定）
    RETURN xxccp_oiccommon_pkg.to_csv_string( iv_string , cv_space );
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
  END to_csv_string;
--
--
  /**********************************************************************************
   * Function Name    : to_csv_string
   * Description      : CSVファイル用文字列変換
   ***********************************************************************************/
  FUNCTION to_csv_string(
              iv_string          IN VARCHAR2                  -- 対象文字列
           )
    RETURN VARCHAR2
  IS
  --
    -- *** ローカル定数 ***
    cv_prg_name         CONSTANT VARCHAR2(100) := 'to_csv_string';
--
    -- *** ローカル変数 ***
  --
  BEGIN
--
    -- 対象文字列がNULLの場合
    IF ( iv_string IS NULL) THEN
      RETURN iv_string;
    END IF;
    --
    -- OIC共通関数のCSVファイル用文字列変換を実施（LF置換単語は半角スペースを指定）
    RETURN xxccp_oiccommon_pkg.to_csv_string( iv_string , cv_space );
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
  END to_csv_string;
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
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
--
    -- *** ローカル変数 ***
    lv_msg               VARCHAR2(3000);
    lt_dir_path          all_directories.directory_path%TYPE; -- ディレクトリパス
    lb_fexists           BOOLEAN;                             -- ファイルが存在するかどうか
    ln_file_length       NUMBER;                              -- ファイル長
    ln_block_size        NUMBER;                              -- ブロックサイズ
    ln_prf_idx           NUMBER;                              -- プロファイル用インデックス
    ln_file_name_idx     NUMBER;                              -- ファイル名用インデックス
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
    -- 入力パラメータなし
--
    -- ==============================================================
    -- 2.プロファイル値の取得
    -- ==============================================================
    ln_prf_idx := 0;
    -- 1.XXCMM:OIC連携データファイル格納ディレクトリ名
    gt_prf_val_out_file_dir := FND_PROFILE.VALUE( cv_prf_out_file_dir );
    -- プロファイル用テーブルに設定
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_out_file_dir;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_out_file_dir;
    --
    -- 2.XXCMM:サプライヤ連携データファイル名（OIC連携）
    gt_prf_val_sup_out_file := FND_PROFILE.VALUE( cv_prf_sup_out_file );
    -- プロファイル用テーブルに設定
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_sup_out_file;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_sup_out_file;
    --
    -- 3.XXCMM:サプライヤ・住所連携データファイル名（OIC連携）
    gt_prf_val_sup_addr_out_file := FND_PROFILE.VALUE( cv_prf_sup_addr_out_file );
    -- プロファイル用テーブルに設定
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_sup_addr_out_file;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_sup_addr_out_file;
    --
    -- 4.XXCMM:サプライヤ・サイト連携データファイル名（OIC連携）
    gt_prf_val_site_out_file := FND_PROFILE.VALUE( cv_prf_site_out_file );
    -- プロファイル用テーブルに設定
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_site_out_file;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_site_out_file;
    --
    -- 5.XXCMM:サプライヤ・BU割当連携データファイル名（OIC連携）
    gt_prf_val_site_ass_out_file := FND_PROFILE.VALUE( cv_prf_site_ass_out_file );
    -- プロファイル用テーブルに設定
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_site_ass_out_file;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_site_ass_out_file;
    --
    -- 6.XXCMM:サプライヤ・担当者連携データファイル名（OIC連携）
    gt_prf_val_cont_out_file := FND_PROFILE.VALUE( cv_prf_cont_out_file );
    -- プロファイル用テーブルに設定
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_cont_out_file;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_cont_out_file;
    --
    -- 7.XXCMM:サプライヤ・担当者住所連携データファイル名（OIC連携）
    gt_prf_val_cont_addr_out_file := FND_PROFILE.VALUE( cv_prf_cont_addr_out_file );
    -- プロファイル用テーブルに設定
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_cont_addr_out_file;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_cont_addr_out_file;
    --
    -- 8.XXCMM:サプライヤ・支払先連携データファイル名（OIC連携）
    gt_prf_val_payee_out_file := FND_PROFILE.VALUE( cv_prf_payee_out_file );
    -- プロファイル用テーブルに設定
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_payee_out_file;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_payee_out_file;
    --
    -- 9.XXCMM:サプライヤ・銀行口座連携データファイル名（OIC連携）
    gt_prf_val_bnk_acct_out_file := FND_PROFILE.VALUE( cv_prf_bnk_acct_out_file );
    -- プロファイル用テーブルに設定
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_bnk_acct_out_file;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_bnk_acct_out_file;
    --
    -- 10.XXCMM:サプライヤ・銀行口座割当連携データファイル名（OIC連携）
    gt_prf_val_bnk_use_out_file := FND_PROFILE.VALUE( cv_prf_bnk_use_out_file );
    -- プロファイル用テーブルに設定
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_bnk_use_out_file;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_bnk_use_out_file;
    --
    -- 11.XXCMM:パーティ税金プロファイル連携データファイル名（OIC連携）
    gt_prf_val_tax_prf_out_file := FND_PROFILE.VALUE( cv_prf_tax_prf_out_file );
    -- プロファイル用テーブルに設定
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_tax_prf_out_file;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_tax_prf_out_file;
    --
    -- 12.XXCMM:銀行口座更新用ファイル名（OIC連携）
    gt_prf_val_bnk_upd_out_file := FND_PROFILE.VALUE( cv_prf_bnk_upd_out_file );
    -- プロファイル用テーブルに設定
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_bnk_upd_out_file;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_bnk_upd_out_file;
    --
    -- 13.XXCMM:仕入先支払用ダミー（OIC連携）
    gt_prf_val_dmy_sup_payment := FND_PROFILE.VALUE( cv_prf_dmy_sup_payment );
    -- プロファイル用テーブルに設定
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_dmy_sup_payment;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_dmy_sup_payment;
    --
-- Ver1.3 Add Start
    -- 14.XXCMM:パーティ税金プロファイルレコードタイプ（OIC連携）
    gt_prf_ptp_record_type := FND_PROFILE.VALUE( cv_prf_ptp_record_type );
    -- プロファイル用テーブルに設定
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_ptp_record_type;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_ptp_record_type;
-- Ver1.3 Add End
    --
-- Ver1.9 Add Start
    -- 15.XXCMM:パラレル数（OIC連携）
    gt_prf_parallel_num := FND_PROFILE.VALUE( cv_prf_parallel_num );
    -- プロファイル用テーブルに設定
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_parallel_num;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_parallel_num;
-- Ver1.9 Add End
    --
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
-- Ver1.9 Add Start
    -- プロファイル値「XXCMM:パラレル数（OIC連携）」の数値変換
    BEGIN
      gn_parallel_num := TO_NUMBER(gt_prf_parallel_num);
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_xxcmm              -- アプリケーション短縮名：XXCMM
                      , iv_name         => cv_prof_get_err_msg        -- メッセージ名：プロファイル取得エラーメッセージ
                      , iv_token_name1  => cv_tkn_ng_profile          -- トークン名1：NG_PROFILE
                      , iv_token_value1 => cv_prf_parallel_num      -- トークン値1：プロファイル
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
-- Ver1.9 Add End
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
    -- 4.IFファイル名の出力
    -- ==============================================================
    ln_file_name_idx := 0;
    --
    -- サプライヤ連携データファイル名
    ln_file_name_idx := ln_file_name_idx + 1;
    l_file_name_tab(ln_file_name_idx) := gt_prf_val_sup_out_file;
    --
    -- サプライヤ・住所連携データファイル名
    ln_file_name_idx := ln_file_name_idx + 1;
    l_file_name_tab(ln_file_name_idx) := gt_prf_val_sup_addr_out_file;
    --
    -- サプライヤ・サイト連携データファイル名
    ln_file_name_idx := ln_file_name_idx + 1;
    l_file_name_tab(ln_file_name_idx) := gt_prf_val_site_out_file;
    --
    -- サプライヤ・BU割当連携データファイル名
    ln_file_name_idx := ln_file_name_idx + 1;
    l_file_name_tab(ln_file_name_idx) := gt_prf_val_site_ass_out_file;
    --
    -- サプライヤ・担当者連携データファイル名
    ln_file_name_idx := ln_file_name_idx + 1;
    l_file_name_tab(ln_file_name_idx) := gt_prf_val_cont_out_file;
    --
    -- サプライヤ・担当者住所連携データファイル名
    ln_file_name_idx := ln_file_name_idx + 1;
    l_file_name_tab(ln_file_name_idx) := gt_prf_val_cont_addr_out_file;
    --
    -- サプライヤ・支払先連携データファイル名
    ln_file_name_idx := ln_file_name_idx + 1;
    l_file_name_tab(ln_file_name_idx) := gt_prf_val_payee_out_file;
    --
    -- サプライヤ・銀行口座連携データファイル名
    ln_file_name_idx := ln_file_name_idx + 1;
    l_file_name_tab(ln_file_name_idx) := gt_prf_val_bnk_acct_out_file;
    --
    -- サプライヤ・銀行口座割当連携データファイル名
    ln_file_name_idx := ln_file_name_idx + 1;
    l_file_name_tab(ln_file_name_idx) := gt_prf_val_bnk_use_out_file;
    --
    -- パーティ税金プロファイル連携データファイル名
    ln_file_name_idx := ln_file_name_idx + 1;
    l_file_name_tab(ln_file_name_idx) := gt_prf_val_tax_prf_out_file;
    --
    -- 銀行口座更新用ファイル名
    ln_file_name_idx := ln_file_name_idx + 1;
    l_file_name_tab(ln_file_name_idx) := gt_prf_val_bnk_upd_out_file;
    --
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
    -- 5.ファイル存在チェック
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
    -- 6.コンカレントプログラム名、および前回処理日時の取得
    -- ==============================================================
    SELECT
        fcp.concurrent_program_name     AS conc_program_name        -- コンカレントプログラム名
      , xoipm.pre_process_date          AS pre_process_date         -- 前回処理日時
    INTO
        gt_conc_program_name
      , gt_pre_process_date
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
    -- 7.今回処理日時の取得
    -- ==============================================================
    gt_cur_process_date := SYSDATE;
--
    -- ==============================================================
    -- 8.前回・今回処理日時の出力
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
    -- 9.組織IDの取得
    -- ==============================================================
    BEGIN
      SELECT
          haouv.organization_id       AS  organization_id        -- 組織ID
      INTO
          gt_target_organization_id
      FROM
          hr_all_organization_units_vl  haouv     -- 組織単位ビュー
      WHERE
          haouv.name = cv_target_ou_name
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errbuf :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_xxcmm             -- アプリケーション短縮名：XXCMM
                      , iv_name         => cv_orgid_get_err_msg      -- メッセージ名：組織ID取得エラーメッセージ
                      , iv_token_name1  => cv_tkn_ng_ou_name         -- トークン名1：NG_OU_NAME
                      , iv_token_value1 => cv_target_ou_name         -- トークン値1：検索対象OU
                      );
        --
        lv_errmsg :=  lv_errbuf;
        RAISE  global_process_expt;
    END;
--
    -- ==============================================================
    -- 10.ファイルオープン
    -- ==============================================================
    BEGIN
      -- サプライヤ連携データファイル
      gf_sup_file_handle       := UTL_FILE.FOPEN(
                                    location     => gt_prf_val_out_file_dir
                                  , filename     => gt_prf_val_sup_out_file
                                  , open_mode    => cv_open_mode_w
                                  , max_linesize => cn_max_linesize
                                  );
      --
      -- サプライヤ・住所連携データファイル
      gf_sup_addr_file_handle  := UTL_FILE.FOPEN(
                                    location     => gt_prf_val_out_file_dir
                                  , filename     => gt_prf_val_sup_addr_out_file
                                  , open_mode    => cv_open_mode_w
                                  , max_linesize => cn_max_linesize
                                  );
      --
      -- サプライヤ・サイト連携データファイル
      gf_site_file_handle      := UTL_FILE.FOPEN(
                                    location     => gt_prf_val_out_file_dir
                                  , filename     => gt_prf_val_site_out_file
                                  , open_mode    => cv_open_mode_w
                                  , max_linesize => cn_max_linesize
                                  );
      --
      -- サプライヤ・BU割当連携データファイル
      gf_site_ass_file_handle  := UTL_FILE.FOPEN(
                                    location     => gt_prf_val_out_file_dir
                                  , filename     => gt_prf_val_site_ass_out_file
                                  , open_mode    => cv_open_mode_w
                                  , max_linesize => cn_max_linesize
                                  );
      --
      -- サプライヤ・担当者連携データファイル
      gf_cont_file_handle      := UTL_FILE.FOPEN(
                                    location     => gt_prf_val_out_file_dir
                                  , filename     => gt_prf_val_cont_out_file
                                  , open_mode    => cv_open_mode_w
                                  , max_linesize => cn_max_linesize
                                  );
      --
      -- サプライヤ・担当者住所連携データファイル
      gf_cont_addr_file_handle := UTL_FILE.FOPEN(
                                    location     => gt_prf_val_out_file_dir
                                  , filename     => gt_prf_val_cont_addr_out_file
                                  , open_mode    => cv_open_mode_w
                                  , max_linesize => cn_max_linesize
                                  );
      --
      -- サプライヤ・支払先連携データファイル
      gf_payee_file_handle     := UTL_FILE.FOPEN(
                                    location     => gt_prf_val_out_file_dir
                                  , filename     => gt_prf_val_payee_out_file
                                  , open_mode    => cv_open_mode_w
                                  , max_linesize => cn_max_linesize
                                  );
      --
      -- サプライヤ・銀行口座連携データファイル
      gf_bnk_acct_file_handle  := UTL_FILE.FOPEN(
                                    location     => gt_prf_val_out_file_dir
                                  , filename     => gt_prf_val_bnk_acct_out_file
                                  , open_mode    => cv_open_mode_w
                                  , max_linesize => cn_max_linesize
                                  );
      --
      -- サプライヤ・銀行口座割当連携データファイル
      gf_bnk_use_file_handle   := UTL_FILE.FOPEN(
                                    location     => gt_prf_val_out_file_dir
                                  , filename     => gt_prf_val_bnk_use_out_file
                                  , open_mode    => cv_open_mode_w
                                  , max_linesize => cn_max_linesize
                                  );
      --
      -- パーティ税金プロファイル連携データファイル
      gf_tax_prf_file_handle   := UTL_FILE.FOPEN(
                                    location     => gt_prf_val_out_file_dir
                                  , filename     => gt_prf_val_tax_prf_out_file
                                  , open_mode    => cv_open_mode_w
                                  , max_linesize => cn_max_linesize
                                  );
      --
      -- 銀行口座更新用ファイル
      gf_bnk_upd_file_handle   := UTL_FILE.FOPEN(
                                    location     => gt_prf_val_out_file_dir
                                  , filename     => gt_prf_val_bnk_upd_out_file
                                  , open_mode    => cv_open_mode_w
                                  , max_linesize => cn_max_linesize
                                  );
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
  EXCEPTION
--
    -- *** ロックエラー例外ハンドラ ***
    WHEN global_lock_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm             -- アプリケーション短縮名：XXCMM
                   , iv_name         => cv_lock_err_msg           -- メッセージ名：ロックエラーメッセージ
                   , iv_token_name1  => cv_tkn_ng_table           -- トークン名1：NG_TABLE
                   , iv_token_value1 => cv_oic_proc_mng_tbl_msg   -- トークン値1：テーブル名：OIC連携処理管理テーブル
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
   * Procedure Name   : output_supplier
   * Description      : 「①サプライヤ」連携データの抽出・ファイル出力処理(A-2)
   ***********************************************************************************/
  PROCEDURE output_supplier(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_supplier';       -- プログラム名
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
    lv_file_data         VARCHAR2(30000) DEFAULT NULL;       -- 出力内容
--
    -- *** ローカル・カーソル ***
    -- 「①サプライヤ」の抽出カーソル
    CURSOR supplier_cur
    IS
      SELECT
          (CASE
             WHEN (    gt_pre_process_date IS NULL
                   OR  pv.creation_date > gt_pre_process_date) THEN
               cv_status_create
             ELSE
               cv_status_update
           END)                                          AS status_code                -- ステータス・コード
        , (CASE
             WHEN xove.vendor_id IS NOT NULL THEN
               xove.vendor_name
             ELSE
               pv.vendor_name
           END)                                          AS vendor_name                -- 仕入先名
        , (CASE
             WHEN (xove.vendor_id IS NOT NULL
                   AND xove.vendor_name <> pv.vendor_name) THEN
               pv.vendor_name
             ELSE
               NULL
           END)                                          AS new_vendor_name            -- 新仕入先名
        , pv.segment1                                    AS segment1                   -- 仕入先番号
        , pv.vendor_name_alt                             AS vendor_name_alt            -- 仕入先名カナ
        , pv.vendor_type_lookup_code                     AS vendor_type_lookup_code    -- 仕入先タイプ
        , TO_CHAR(pv.end_date_active, cv_date_fmt)       AS end_date_active            -- 無効日
        , (CASE
             WHEN (    gt_pre_process_date IS NULL
                   OR  pv.creation_date > gt_pre_process_date) THEN
               cv_spend_authorized
             ELSE
               NULL
           END)                                          AS business_relationship      -- ビジネス関連
        , pv.one_time_flag                               AS one_time_flag              -- 一時フラグ
        , pv.auto_tax_calc_override                      AS auto_tax_calc_override     -- 自動税金計算上書き
        , pv.pay_group_lookup_code                       AS pay_group_lookup_code      -- 支払グループ
        , pv.vendor_id                                   AS vendor_id                  -- 仕入先ID
        , pv.vendor_name                                 AS pv_vendor_name             -- 仕入先名（マスタ）
        , xove.vendor_name                               AS xove_vendor_name           -- 仕入先名（退避テーブル）
        , (CASE
             WHEN xove.vendor_id IS NULL THEN
               cv_evac_create
             WHEN xove.vendor_name <> pv.vendor_name THEN
               cv_evac_update
             ELSE
               NULL
           END)                                          AS key_ins_upd_flag           -- キー情報登録・更新フラグ
-- Ver1.5 Add Start
        , (CASE 
            WHEN ( gt_pre_process_date IS NULL ) THEN 
-- Ver1.9 Mod Start
--              TO_CHAR( gt_cur_process_date , cv_datetime_id_fmt ) || MOD( pv.vendor_id , cn_divisor_ten )
              TO_CHAR( gt_cur_process_date , cv_datetime_id_fmt ) || MOD( pv.vendor_id , gn_parallel_num )
-- Ver1.9 Mod End
            ELSE
              NULL
          END)                                           AS batch_id                   -- バッチID
-- Ver1.5 Add End
      FROM
          po_vendors         pv    -- 仕入先マスタ
        , xxcmm_oic_vd_evac  xove  -- OIC仕入先退避テーブル
      WHERE
          (   gt_pre_process_date IS NULL
-- Ver1.11 Mod Start
--           OR pv.last_update_date > gt_pre_process_date)
           OR (    pv.last_update_date > gt_pre_process_date
               AND pv.last_update_date <= gt_cur_process_date)
           )
-- Ver1.11 Mod End
      AND NVL(pv.vendor_type_lookup_code, 'X') <> cv_employee
      AND EXISTS (
              SELECT
                  1  AS flag
              FROM
                  po_vendor_sites_all  pvsa  -- 仕入先サイト
              WHERE
                  pvsa.vendor_id = pv.vendor_id
              AND pvsa.org_id    = gt_target_organization_id
          )
      AND pv.vendor_id = xove.vendor_id (+)
      ORDER BY
          pv.segment1 ASC  -- 仕入先番号
      FOR UPDATE OF xove.vendor_name NOWAIT  -- 行ロック：OIC仕入先退避テーブル
    ;
--
    -- *** ローカル・レコード ***
    -- 「①サプライヤ」の抽出カーソルレコード
    l_supplier_rec     supplier_cur%ROWTYPE;
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
    -- 「①サプライヤ」の抽出
    -- ==============================================================
    -- カーソルオープン
    OPEN  supplier_cur;
    <<output_supplier_loop>>
    LOOP
      --
      FETCH supplier_cur INTO l_supplier_rec;
      EXIT WHEN supplier_cur%NOTFOUND;
      --
      -- 抽出件数カウントアップ
      gn_get_sup_cnt := gn_get_sup_cnt + 1;
      --
      -- ==============================================================
      -- 「①サプライヤ」のファイル出力
      -- ==============================================================
      -- データ行の作成
      lv_file_data := l_supplier_rec.status_code;                     --   1 : Import Action * (ステータス・コード)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
-- Ver1.6 Mod Start
--                        l_supplier_rec.vendor_name
                        xxccp_oiccommon_pkg.trim_space_tab(l_supplier_rec.vendor_name)
-- Ver1.6 Mod End
                      , l_supplier_rec.status_code
                      );                                              --   2 : Supplier Name* (サプライヤ名称)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
-- Ver1.6 Mod Start
--                        l_supplier_rec.new_vendor_name
                        xxccp_oiccommon_pkg.trim_space_tab(l_supplier_rec.new_vendor_name)
-- Ver1.6 Mod End
-- Ver1.3 Del Start(関連対応)
--                      , l_supplier_rec.status_code
-- Ver1.3 Del End
                      );                                              --   3 : Supplier Name New (新サプライヤ名称)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_supplier_rec.segment1
                      , l_supplier_rec.status_code
                      );                                              --   4 : Supplier Number (サプライヤ番号)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_supplier_rec.vendor_name_alt
                      , l_supplier_rec.status_code
                      );                                              --   5 : Alternate Name (サプライヤ名称(カナ))
      lv_file_data := lv_file_data || cv_comma || cv_corporation;     --   6 : Tax Organization Type (税組織タイプ)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_supplier_rec.vendor_type_lookup_code
                      , l_supplier_rec.status_code
                      );                                              --   7 : Supplier Type (サプライヤ・タイプ)
      lv_file_data := lv_file_data || cv_comma || 
                      nvl_by_status_code(
                        l_supplier_rec.end_date_active
                      , l_supplier_rec.status_code
                      );                                              --   8 : Inactive Date (非アクティブ日)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_supplier_rec.business_relationship
-- Ver1.3 Del Start(関連対応)
--                      , l_supplier_rec.status_code
-- Ver1.3 Del End
                      );                                              --   9 : Business Relationship* (ビジネス関連)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  10 : Parent Supplier (親サプライヤ)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  11 : Alias (別名)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  12 : D-U-N-S Number (D-U-N-S番号)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_supplier_rec.one_time_flag
                      , l_supplier_rec.status_code
                      , cv_n
                      , cv_n
                      );                                              --  13 : One-time supplier (一時サプライヤ)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  14 : Customer Number (顧客番号)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  15 : SIC (標準産業分類)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  16 : National Insurance Number (国民保険番号)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  17 : Corporate Web Site (法人Webサイト)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  18 : Chief Executive Title (最高経営責任者タイトル)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  19 : Chief Executive Name (最高経営責任者名)
      lv_file_data := lv_file_data || cv_comma || cv_y;               --  20 : Business Classifications Not Applicable (事業分類の有無)
      lv_file_data := lv_file_data || cv_comma || cv_jp;              --  21 : Taxpayer Country (納税者国)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  22 : Taxpayer ID (納税者ID)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  23 : Federal reportable (連邦レポート可能)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  24 : Federal Income Tax Type (連邦所得税タイプ)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  25 : State reportable (都道府県レポート可能)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  26 : Tax Reporting Name (税金レポート名)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  27 : Name Control (名前管理)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  28 : Tax Verification Date (確認日)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  29 : Use withholding tax (源泉徴収税の使用)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  30 : Withholding Tax Group (源泉徴収税グループ)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  31 : Vat Code (付加価値税コード)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  32 : Tax Registration Number (付加価値税登録番号)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_supplier_rec.auto_tax_calc_override
                      , l_supplier_rec.status_code
                      , cv_n
                      , cv_n
                      );                                              --  33 : Auto Tax Calc Override (自動税金計算上書き)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_supplier_rec.pay_group_lookup_code
                      , l_supplier_rec.status_code
                      );                                              --  34 : Payment Method (支払方法)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  35 : Delivery Channel (決済チャネル)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  36 : Bank Instruction 1 (銀行指図1)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  37 : Bank Instruction 2 (銀行指図2)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  38 : Bank Instruction (銀行指図詳細)
      lv_file_data := lv_file_data || cv_comma || cv_express;         --  39 : Settlement Priority (精算優先度)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  40 : Payment Text Message 1 (支払テキスト・メッセージ1)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  41 : Payment Text Message 2 (支払テキスト・メッセージ2)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  42 : Payment Text Message 3 (支払テキスト・メッセージ3)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  43 : Bank Charge Bearer (銀行手数料負担者)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  44 : Payment Reason (支払事由)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  45 : Payment Reason Comments (支払事由コメント)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  46 : Payment Format (支払フォーマットコード)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  47 : ATTRIBUTE_CATEGORY (追加情報カテゴリ)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  48 : ATTRIBUTE1 (追加情報1)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  49 : ATTRIBUTE2 (追加情報2)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  50 : ATTRIBUTE3 (追加情報3)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  51 : ATTRIBUTE4 (追加情報4)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  52 : ATTRIBUTE5 (追加情報5)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  53 : ATTRIBUTE6 (追加情報6)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  54 : ATTRIBUTE7 (追加情報7)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  55 : ATTRIBUTE8 (追加情報8)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  56 : ATTRIBUTE9 (追加情報9)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  57 : ATTRIBUTE10 (追加情報10)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  58 : ATTRIBUTE11 (追加情報11)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  59 : ATTRIBUTE12 (追加情報12)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  60 : ATTRIBUTE13 (追加情報13)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  61 : ATTRIBUTE14 (追加情報14)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  62 : ATTRIBUTE15 (追加情報15)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  63 : ATTRIBUTE16 (追加情報16)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  64 : ATTRIBUTE17 (追加情報17)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  65 : ATTRIBUTE18 (追加情報18)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  66 : ATTRIBUTE19 (追加情報19)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  67 : ATTRIBUTE20 (追加情報20)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  68 : ATTRIBUTE_DATE1 (追加情報_日付1)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  69 : ATTRIBUTE_DATE2 (追加情報_日付2)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  70 : ATTRIBUTE_DATE3 (追加情報_日付3)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  71 : ATTRIBUTE_DATE4 (追加情報_日付4)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  72 : ATTRIBUTE_DATE5 (追加情報_日付5)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  73 : ATTRIBUTE_DATE6 (追加情報_日付6)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  74 : ATTRIBUTE_DATE7 (追加情報_日付7)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  75 : ATTRIBUTE_DATE8 (追加情報_日付8)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  76 : ATTRIBUTE_DATE9 (追加情報_日付9)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  77 : ATTRIBUTE_DATE10 (追加情報_日付10)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  78 : ATTRIBUTE_TIMESTAMP1 (追加情報_ﾀｲﾑｽﾀﾝﾌﾟ1)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  79 : ATTRIBUTE_TIMESTAMP2 (追加情報_ﾀｲﾑｽﾀﾝﾌﾟ2)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  80 : ATTRIBUTE_TIMESTAMP3 (追加情報_ﾀｲﾑｽﾀﾝﾌﾟ3)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  81 : ATTRIBUTE_TIMESTAMP4 (追加情報_ﾀｲﾑｽﾀﾝﾌﾟ4)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  82 : ATTRIBUTE_TIMESTAMP5 (追加情報_ﾀｲﾑｽﾀﾝﾌﾟ5)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  83 : ATTRIBUTE_TIMESTAMP6 (追加情報_ﾀｲﾑｽﾀﾝﾌﾟ6)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  84 : ATTRIBUTE_TIMESTAMP7 (追加情報_ﾀｲﾑｽﾀﾝﾌﾟ7)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  85 : ATTRIBUTE_TIMESTAMP8 (追加情報_ﾀｲﾑｽﾀﾝﾌﾟ8)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  86 : ATTRIBUTE_TIMESTAMP9 (追加情報_ﾀｲﾑｽﾀﾝﾌﾟ9)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  87 : ATTRIBUTE_TIMESTAMP10 (追加情報_ﾀｲﾑｽﾀﾝﾌﾟ10)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  88 : ATTRIBUTE_NUMBER1 (追加情報_番号1)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  89 : ATTRIBUTE_NUMBER2 (追加情報_番号2)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  90 : ATTRIBUTE_NUMBER3 (追加情報_番号3)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  91 : ATTRIBUTE_NUMBER4 (追加情報_番号4)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  92 : ATTRIBUTE_NUMBER5 (追加情報_番号5)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  93 : ATTRIBUTE_NUMBER6 (追加情報_番号6)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  94 : ATTRIBUTE_NUMBER7 (追加情報_番号7)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  95 : ATTRIBUTE_NUMBER8 (追加情報_番号8)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  96 : ATTRIBUTE_NUMBER9 (追加情報_番号9)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  97 : ATTRIBUTE_NUMBER10 (追加情報_番号10)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  98 : GLOBAL_ATTRIBUTE_CATEGORY (追加情報カテゴリ)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  99 : GLOBAL_ATTRIBUTE1 (追加情報1)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 100 : GLOBAL_ATTRIBUTE2 (追加情報2)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 101 : GLOBAL_ATTRIBUTE3 (追加情報3)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 102 : GLOBAL_ATTRIBUTE4 (追加情報4)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 103 : GLOBAL_ATTRIBUTE5 (追加情報5)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 104 : GLOBAL_ATTRIBUTE6 (追加情報6)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 105 : GLOBAL_ATTRIBUTE7 (追加情報7)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 106 : GLOBAL_ATTRIBUTE8 (追加情報8)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 107 : GLOBAL_ATTRIBUTE9 (追加情報9)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 108 : GLOBAL_ATTRIBUTE10 (追加情報10)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 109 : GLOBAL_ATTRIBUTE11 (追加情報11)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 110 : GLOBAL_ATTRIBUTE12 (追加情報12)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 111 : GLOBAL_ATTRIBUTE13 (追加情報13)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 112 : GLOBAL_ATTRIBUTE14 (追加情報14)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 113 : GLOBAL_ATTRIBUTE15 (追加情報15)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 114 : GLOBAL_ATTRIBUTE16 (追加情報16)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 115 : GLOBAL_ATTRIBUTE17 (追加情報17)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 116 : GLOBAL_ATTRIBUTE18 (追加情報18)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 117 : GLOBAL_ATTRIBUTE19 (追加情報19)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 118 : GLOBAL_ATTRIBUTE20 (追加情報20)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 119 : GLOBAL_ATTRIBUTE_DATE1 (追加情報_日付1)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 120 : GLOBAL_ATTRIBUTE_DATE2 (追加情報_日付2)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 121 : GLOBAL_ATTRIBUTE_DATE3 (追加情報_日付3)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 122 : GLOBAL_ATTRIBUTE_DATE4 (追加情報_日付4)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 123 : GLOBAL_ATTRIBUTE_DATE5 (追加情報_日付5)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 124 : GLOBAL_ATTRIBUTE_DATE6 (追加情報_日付6)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 125 : GLOBAL_ATTRIBUTE_DATE7 (追加情報_日付7)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 126 : GLOBAL_ATTRIBUTE_DATE8 (追加情報_日付8)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 127 : GLOBAL_ATTRIBUTE_DATE9 (追加情報_日付9)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 128 : GLOBAL_ATTRIBUTE_DATE10 (追加情報_日付10)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 129 : GLOBAL_ATTRIBUTE_TIMESTAMP1 (追加情報_ﾀｲﾑｽﾀﾝﾌﾟ1)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 130 : GLOBAL_ATTRIBUTE_TIMESTAMP2 (追加情報_ﾀｲﾑｽﾀﾝﾌﾟ2)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 131 : GLOBAL_ATTRIBUTE_TIMESTAMP3 (追加情報_ﾀｲﾑｽﾀﾝﾌﾟ3)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 132 : GLOBAL_ATTRIBUTE_TIMESTAMP4 (追加情報_ﾀｲﾑｽﾀﾝﾌﾟ4)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 133 : GLOBAL_ATTRIBUTE_TIMESTAMP5 (追加情報_ﾀｲﾑｽﾀﾝﾌﾟ5)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 134 : GLOBAL_ATTRIBUTE_TIMESTAMP6 (追加情報_ﾀｲﾑｽﾀﾝﾌﾟ6)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 135 : GLOBAL_ATTRIBUTE_TIMESTAMP7 (追加情報_ﾀｲﾑｽﾀﾝﾌﾟ7)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 136 : GLOBAL_ATTRIBUTE_TIMESTAMP8 (追加情報_ﾀｲﾑｽﾀﾝﾌﾟ8)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 137 : GLOBAL_ATTRIBUTE_TIMESTAMP9 (追加情報_ﾀｲﾑｽﾀﾝﾌﾟ9)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 138 : GLOBAL_ATTRIBUTE_TIMESTAMP10 (追加情報_ﾀｲﾑｽﾀﾝﾌﾟ10)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 139 : GLOBAL_ATTRIBUTE_NUMBER1 (追加情報_番号1)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 140 : GLOBAL_ATTRIBUTE_NUMBER2 (追加情報_番号2)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 141 : GLOBAL_ATTRIBUTE_NUMBER3 (追加情報_番号3)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 142 : GLOBAL_ATTRIBUTE_NUMBER4 (追加情報_番号4)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 143 : GLOBAL_ATTRIBUTE_NUMBER5 (追加情報_番号5)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 144 : GLOBAL_ATTRIBUTE_NUMBER6 (追加情報_番号6)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 145 : GLOBAL_ATTRIBUTE_NUMBER7 (追加情報_番号7)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 146 : GLOBAL_ATTRIBUTE_NUMBER8 (追加情報_番号8)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 147 : GLOBAL_ATTRIBUTE_NUMBER9 (追加情報_番号9)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 148 : GLOBAL_ATTRIBUTE_NUMBER10 (追加情報_番号10)
-- Ver1.5 Mod Start
--    lv_file_data := lv_file_data || cv_comma || NULL;               -- 149 : Batch ID (バッチID)
      lv_file_data := lv_file_data || cv_comma 
        || l_supplier_rec.batch_id;                                   -- 149 : Batch ID (バッチID)
-- Ver1.5 Mod End
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 150 : Registry ID (登録ID)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 151 : Payee Service Level ()
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 152 : Pay Each Document Alone ()
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 153 : Delivery Method ()
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 154 : Remittance E-mail ()
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 155 : Remittance Fax ()
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 156 : DataFox ID ()
      --
      BEGIN
        -- データ行のファイル出力
        UTL_FILE.PUT_LINE( gf_sup_file_handle
                         , lv_file_data
                         );
        --
        -- 出力件数カウントアップ
        gn_out_sup_cnt := gn_out_sup_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
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
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
      --
      -- ==============================================================
      -- OIC仕入先退避テーブルの登録・更新
      -- ==============================================================
      IF ( l_supplier_rec.key_ins_upd_flag = cv_evac_create ) THEN
        -- 退避テーブル登録・更新フラグがCreateの場合
        BEGIN
          -- OIC仕入先退避テーブルの登録
          INSERT INTO xxcmm_oic_vd_evac (
              vendor_id                      -- 仕入先ID
            , vendor_name                    -- 仕入先名
            , created_by                     -- 作成者
            , creation_date                  -- 作成日
            , last_updated_by                -- 最終更新者
            , last_update_date               -- 最終更新日
            , last_update_login              -- 最終更新ログイン
            , request_id                     -- 要求ID
            , program_application_id         -- コンカレント・プログラム・アプリケーションID
            , program_id                     -- コンカレント・プログラムID
            , program_update_date            -- プログラム更新日
          ) VALUES (
              l_supplier_rec.vendor_id       -- 仕入先ID
            , l_supplier_rec.pv_vendor_name  -- 仕入先名
            , cn_created_by                  -- 作成者
            , cd_creation_date               -- 作成日
            , cn_last_updated_by             -- 最終更新者
            , cd_last_update_date            -- 最終更新日
            , cn_last_update_login           -- 最終更新ログイン
            , cn_request_id                  -- 要求ID
            , cn_program_application_id      -- コンカレント・プログラム・アプリケーションID
            , cn_program_id                  -- コンカレント・プログラムID
            , cd_program_update_date         -- プログラム更新日
          );
        EXCEPTION
          WHEN OTHERS THEN
            -- 登録に失敗した場合
            lv_errmsg := SUBSTRB(
                           xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_xxcmm             -- アプリケーション短縮名：XXCMM
                           , iv_name         => cv_insert_err_msg         -- メッセージ名：挿入エラーメッセージ
                           , iv_token_name1  => cv_tkn_table              -- トークン名1：TABLE
                           , iv_token_value1 => cv_oic_sup_evac_tbl_msg   -- トークン値1：OIC仕入先退避テーブル
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
      ELSIF ( l_supplier_rec.key_ins_upd_flag = cv_evac_update ) THEN
        -- 退避テーブル登録・更新フラグがUpdateの場合
        BEGIN
          -- OIC仕入先退避テーブルの更新
          UPDATE
              xxcmm_oic_vd_evac  xove  -- OIC仕入先退避テーブル
          SET
              xove.vendor_name            = l_supplier_rec.pv_vendor_name  -- 仕入先名
            , xove.last_update_date       = cd_last_update_date            -- 最終更新日
            , xove.last_updated_by        = cn_last_updated_by             -- 最終更新者
            , xove.last_update_login      = cn_last_update_login           -- 最終更新ログイン
            , xove.request_id             = cn_request_id                  -- 要求ID
            , xove.program_application_id = cn_program_application_id      -- プログラムアプリケーションID
            , xove.program_id             = cn_program_id                  -- プログラムID
            , xove.program_update_date    = cd_program_update_date         -- プログラム更新日
          WHERE
              xove.vendor_id              = l_supplier_rec.vendor_id       -- 仕入先ID
          ;
        EXCEPTION
          WHEN OTHERS THEN
            -- 更新に失敗した場合
            lv_errmsg := SUBSTRB(
                           xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_xxcmm             -- アプリケーション短縮名：XXCMM
                           , iv_name         => cv_update_err_msg         -- メッセージ名：更新エラーメッセージ
                           , iv_token_name1  => cv_tkn_table              -- トークン名1：TABLE
                           , iv_token_value1 => cv_oic_sup_evac_tbl_msg   -- トークン値1：OIC仕入先退避テーブル
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
        -- 更新に成功した場合、更新前と更新後の仕入先名を出力
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_xxcmm                      -- アプリケーション短縮名：XXCMM
                  , iv_name         => cv_evac_data_out_msg               -- メッセージ名：退避情報更新出力メッセージ
                  , iv_token_name1  => cv_tkn_table                       -- トークン名1：TABLE
                  , iv_token_value1 => cv_oic_sup_evac_tbl_msg            -- トークン値1：OIC仕入先退避テーブル
                  , iv_token_name2  => cv_tkn_id                          -- トークン名2：ID
                  , iv_token_value2 => TO_CHAR(l_supplier_rec.vendor_id)  -- トークン値2：仕入先ID
                  , iv_token_name3  => cv_tkn_before_value                -- トークン名3：BEFORE_VALUE
                  , iv_token_value3 => l_supplier_rec.xove_vendor_name    -- トークン値3：仕入先名（退避テーブル）
                  , iv_token_name4  => cv_tkn_after_value                 -- トークン名4：AFTER_VALUE
                  , iv_token_value4 => l_supplier_rec.pv_vendor_name      -- トークン値4：仕入先名（マスタ）
                  );
        --
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_msg
        );
      END IF;
    --
    END LOOP output_supplier_loop;
--
    -- カーソルクローズ
    CLOSE supplier_cur;
--
    -- 退避情報更新出力メッセージを出力している場合
    IF ( lv_msg IS NOT NULL ) THEN
      -- 空行挿入
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
      );
    END IF;
--
  EXCEPTION
--
    -- *** ロックエラー例外ハンドラ ***
    WHEN global_lock_expt THEN
      -- カーソルクローズ
      IF ( supplier_cur%ISOPEN ) THEN
        CLOSE supplier_cur;
      END IF;
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm             -- アプリケーション短縮名：XXCMM
                   , iv_name         => cv_lock_err_msg           -- メッセージ名：ロックエラーメッセージ
                   , iv_token_name1  => cv_tkn_ng_table           -- トークン名1：NG_TABLE
                   , iv_token_value1 => cv_oic_sup_evac_tbl_msg   -- トークン値1：テーブル名：OIC仕入先退避テーブル
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
      IF ( supplier_cur%ISOPEN ) THEN
        CLOSE supplier_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルクローズ
      IF ( supplier_cur%ISOPEN ) THEN
        CLOSE supplier_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF ( supplier_cur%ISOPEN ) THEN
        CLOSE supplier_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF ( supplier_cur%ISOPEN ) THEN
        CLOSE supplier_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END output_supplier;
--
--
  /**********************************************************************************
   * Procedure Name   : output_sup_addr
   * Description      : 「②サプライヤ・住所」連携データの抽出・ファイル出力処理(A-3)
   ***********************************************************************************/
  PROCEDURE output_sup_addr(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_sup_addr';       -- プログラム名
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
    lv_file_data         VARCHAR2(30000) DEFAULT NULL;       -- 出力内容
--
    -- *** ローカル・カーソル ***
    -- 「②サプライヤ・住所」の抽出カーソル
    CURSOR sup_addr_cur
    IS
      SELECT
          (CASE
             WHEN (    gt_pre_process_date IS NULL
                   OR  pv.creation_date > gt_pre_process_date) THEN
               cv_status_create
             ELSE
               cv_status_update
           END)                                          AS status_code                -- ステータス・コード
        , pv.vendor_name                                 AS vendor_name                -- 仕入先名
        , (CASE
              WHEN xovse.vendor_site_id IS NOT NULL THEN
                xovse.vendor_site_code
              ELSE
                pvsa.vendor_site_code
           END)                                          AS vendor_site_code           -- 仕入先サイトコード
        , (CASE
             WHEN (xovse.vendor_site_id IS NOT NULL
                   AND xovse.vendor_site_code <> pvsa.vendor_site_code) THEN
               pvsa.vendor_site_code
             ELSE
               NULL
           END)                                          AS new_vendor_site_code       -- 新仕入先サイトコード
-- Ver1.2 Mod Start
--        , pvsa.country                                   AS country                    -- 国
        , NVL(pvsa.country, cv_jp)                       AS country                    -- 国
-- Ver1.2 Mod End
-- Ver1.2 Mod Start
--        , pvsa.address_line1                             AS address_line1              -- 住所1
        , NVL(pvsa.address_line1 ,cv_ast)                AS address_line1              -- 住所1
-- Ver1.2 Mod End
        , pvsa.address_line2                             AS address_line2              -- 住所2
        , pvsa.address_line3                             AS address_line3              -- 住所3
        , pvsa.address_line4                             AS address_line4              -- 住所4
        , pvsa.address_lines_alt                         AS address_lines_alt          -- 住所カナ
        , pvsa.city                                      AS city                       -- 市
        , pvsa.state                                     AS state                      -- 州
        , pvsa.province                                  AS province                   -- 都道府県
        , pvsa.county                                    AS county                     -- 郡
-- Ver1.2 Mod Start
--        , pvsa.zip                                       AS zip                        -- 郵便番号
        , NVL(pvsa.zip ,cv_ast)                          AS zip                        -- 郵便番号
-- Ver1.2 Mod End
        , TO_CHAR(pvsa.inactive_date, cv_date_fmt)       AS inactive_date              -- 無効日
        , pvsa.area_code                                 AS area_code                  -- 市外局番
        , pvsa.phone                                     AS phone                      -- 電話番号
        , pvsa.fax_area_code                             AS fax_area_code              -- FAX市外局番
        , pvsa.fax                                       AS fax                        -- FAX番号
        , pvsa.rfq_only_site_flag                        AS rfq_only_site_flag         -- サイト使用：見積のみ
        , pvsa.purchasing_site_flag                      AS purchasing_site_flag       -- サイト使用：購買
-- Ver1.3 Mod Start
--        , pvsa.pay_site_flag                             AS pay_site_flag              -- サイト使用：支払
        , (CASE
             WHEN (    NVL(pvsa.pay_site_flag        , cv_n) = cv_n
                   AND NVL(pvsa.rfq_only_site_flag   , cv_n) = cv_n
                   AND NVL(pvsa.purchasing_site_flag , cv_n) = cv_n) THEN
               cv_y
             ELSE
               pvsa.pay_site_flag
           END)                                          AS pay_site_flag              -- サイト使用：支払
-- Ver1.3 Mod End
        , pvsa.email_address                             AS email_address              -- 電子メールアドレス
-- Ver1.5 Add Start
        , (CASE 
            WHEN ( gt_pre_process_date IS NULL ) THEN 
-- Ver1.9 Mod Start
--              TO_CHAR( gt_cur_process_date , cv_datetime_id_fmt ) || MOD( pv.vendor_id , cn_divisor_ten )
              TO_CHAR( gt_cur_process_date , cv_datetime_id_fmt ) || MOD( pv.vendor_id , gn_parallel_num )
-- Ver1.9 Mod End
            ELSE
              NULL
          END)                                           AS batch_id                   -- バッチID
-- Ver1.5 Add End
      FROM
          po_vendor_sites_all     pvsa   -- 仕入先サイト
        , po_vendors              pv     -- 仕入先マスタ
        , xxcmm_oic_vd_site_evac  xovse  -- OIC仕入先サイト退避テーブル
      WHERE
          (   gt_pre_process_date IS NULL
-- Ver1.11 Mod Start
--           OR pvsa.last_update_date > gt_pre_process_date)
           OR (    pvsa.last_update_date > gt_pre_process_date
               AND pvsa.last_update_date <= gt_cur_process_date)
           )
-- Ver1.11 Mod End
      AND pvsa.org_id         = gt_target_organization_id
      AND pvsa.vendor_id      = pv.vendor_id
      AND NVL(pv.vendor_type_lookup_code, 'X') <> cv_employee
      AND pvsa.vendor_site_id = xovse.vendor_site_id (+)
      ORDER BY
          pv.segment1           ASC  -- 仕入先番号
        , pvsa.vendor_site_code ASC  -- 仕入先サイトコード
    ;
--
    -- *** ローカル・レコード ***
    -- 「②サプライヤ・住所」の抽出カーソルレコード
    l_sup_addr_rec     sup_addr_cur%ROWTYPE;
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
    -- 「②サプライヤ・住所」の抽出
    -- ==============================================================
    -- カーソルオープン
    OPEN  sup_addr_cur;
    <<output_sup_addr_loop>>
    LOOP
      --
      FETCH sup_addr_cur INTO l_sup_addr_rec;
      EXIT WHEN sup_addr_cur%NOTFOUND;
      --
      -- 抽出件数カウントアップ
      gn_get_sup_addr_cnt := gn_get_sup_addr_cnt + 1;
      --
      -- ==============================================================
      -- 「②サプライヤ・住所」のファイル出力
      -- ==============================================================
      -- データ行の作成
      lv_file_data := l_sup_addr_rec.status_code;                     --   1 : Import Action * (ステータス・コード)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
-- Ver1.6 Mod Start
--                        l_sup_addr_rec.vendor_name
                        xxccp_oiccommon_pkg.trim_space_tab(l_sup_addr_rec.vendor_name)
-- Ver1.6 Mod End
                      , l_sup_addr_rec.status_code
                      );                                              --   2 : Supplier Name* (サプライヤ名称)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
-- Ver1.6 Mod Start
--                        l_sup_addr_rec.vendor_site_code
                        xxccp_oiccommon_pkg.trim_space_tab(l_sup_addr_rec.vendor_site_code)
-- Ver1.6 Mod End
                      , l_sup_addr_rec.status_code
                      );                                              --   3 : Address Name * (住所名)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
-- Ver1.6 Mod Start
--                        l_sup_addr_rec.new_vendor_site_code
                        xxccp_oiccommon_pkg.trim_space_tab(l_sup_addr_rec.new_vendor_site_code)
-- Ver1.6 Mod End
-- Ver1.3 Del Start(関連対応)
--                      , l_sup_addr_rec.status_code
-- Ver1.3 Del End
                      );                                              --   4 : Address Name New (住所名)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_addr_rec.country
                      , l_sup_addr_rec.status_code
                      );                                              --   5 : Country (国)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_addr_rec.address_line1
                      , l_sup_addr_rec.status_code
                      );                                              --   6 : Address Line 1 (住所1)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_addr_rec.address_line2
                      , l_sup_addr_rec.status_code
                      );                                              --   7 : Address Line 2 (住所2)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_addr_rec.address_line3
                      , l_sup_addr_rec.status_code
                      );                                              --   8 : Address Line 3 (住所3)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_addr_rec.address_line4
                      , l_sup_addr_rec.status_code
                      );                                              --   9 : Address Line 4 (住所4)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_addr_rec.address_lines_alt
                      , l_sup_addr_rec.status_code
                      );                                              --  10 : Phonetic Address Line (カナ住所)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  11 : Address Element Attribute 1 (住所追加情報1)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  12 : Address Element Attribute 2 (住所追加情報2)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  13 : Address Element Attribute 3 (住所追加情報3)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  14 : Address Element Attribute 4 (住所追加情報4)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  15 : Address Element Attribute 5 (住所追加情報5)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  16 : Building (建物名)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  17 : Floor Number (フロア番号)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_addr_rec.city
                      , l_sup_addr_rec.status_code
                      );                                              --  18 : City (市区町村)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_addr_rec.state
                      , l_sup_addr_rec.status_code
                      );                                              --  19 : State (州)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_addr_rec.province
                      , l_sup_addr_rec.status_code
                      );                                              --  20 : Province (都道府県)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_addr_rec.county
                      , l_sup_addr_rec.status_code
                      );                                              --  21 : County (郡)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_addr_rec.zip
                      , l_sup_addr_rec.status_code
                      );                                              --  22 : Postal code (郵便番号)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  23 : Postal Plus 4 code (追加郵便番号)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  24 : Addressee (名宛人)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  25 : Global Location Number (グローバル地域情報)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  26 : Language (言語)
      lv_file_data := lv_file_data || cv_comma || 
                      nvl_by_status_code(
                        l_sup_addr_rec.inactive_date
                      , l_sup_addr_rec.status_code
                      );                                              --  27 : Inactive Date (非アクティブ日)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  28 : Phone Country Code (電話国コード)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_addr_rec.area_code
                      , l_sup_addr_rec.status_code
                      );                                              --  29 : Phone Area Code (電話市外局番)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_addr_rec.phone
                      , l_sup_addr_rec.status_code
                      );                                              --  30 : Phone (電話番号)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  31 : Phone Extension (電話番号内線)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  32 : Fax Country Code (FAX国コード)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_addr_rec.fax_area_code
                      , l_sup_addr_rec.status_code
                      );                                              --  33 : Fax Area Code (FAX市外局番)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_addr_rec.fax
                      , l_sup_addr_rec.status_code
                      );                                              --  34 : Fax (FAX番号)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_addr_rec.rfq_only_site_flag
                      , l_sup_addr_rec.status_code
                      , cv_n
                      , cv_n
                      );                                              --  35 : RFQ Or Bidding (【住所目的】見積依頼または入札)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_addr_rec.purchasing_site_flag
                      , l_sup_addr_rec.status_code
                      , cv_n
                      , cv_n
                      );                                              --  36 : Ordering (【住所目的】オーダー)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_addr_rec.pay_site_flag
                      , l_sup_addr_rec.status_code
                      , cv_n
                      , cv_n
                      );                                              --  37 : Pay (【住所目的】送金先)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  38 : ATTRIBUTE_CATEGORY (追加カテゴリ)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  39 : ATTRIBUTE1 (追加情報1)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  40 : ATTRIBUTE2 (追加情報2)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  41 : ATTRIBUTE3 (追加情報3)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  42 : ATTRIBUTE4 (追加情報4)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  43 : ATTRIBUTE5 (追加情報5)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  44 : ATTRIBUTE6 (追加情報6)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  45 : ATTRIBUTE7 (追加情報7)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  46 : ATTRIBUTE8 (追加情報8)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  47 : ATTRIBUTE9 (追加情報9)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  48 : ATTRIBUTE10 (追加情報10)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  49 : ATTRIBUTE11 (追加情報11)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  50 : ATTRIBUTE12 (追加情報12)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  51 : ATTRIBUTE13 (追加情報13)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  52 : ATTRIBUTE14 (追加情報14)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  53 : ATTRIBUTE15 (追加情報15)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  54 : ATTRIBUTE16 (追加情報16)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  55 : ATTRIBUTE17 (追加情報17)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  56 : ATTRIBUTE18 (追加情報18)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  57 : ATTRIBUTE19 (追加情報19)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  58 : ATTRIBUTE20 (追加情報20)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  59 : ATTRIBUTE21 (追加情報21)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  60 : ATTRIBUTE22 (追加情報22)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  61 : ATTRIBUTE23 (追加情報23)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  62 : ATTRIBUTE24 (追加情報24)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  63 : ATTRIBUTE25 (追加情報25)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  64 : ATTRIBUTE26 (追加情報26)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  65 : ATTRIBUTE27 (追加情報27)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  66 : ATTRIBUTE28 (追加情報28)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  67 : ATTRIBUTE29 (追加情報29)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  68 : ATTRIBUTE30 (追加情報30)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  69 : ATTRIBUTE_NUMBER1 (追加番号1)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  70 : ATTRIBUTE_NUMBER2 (追加番号2)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  71 : ATTRIBUTE_NUMBER3 (追加番号3)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  72 : ATTRIBUTE_NUMBER4 (追加番号4)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  73 : ATTRIBUTE_NUMBER5 (追加番号5)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  74 : ATTRIBUTE_NUMBER6 (追加番号6)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  75 : ATTRIBUTE_NUMBER7 (追加番号7)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  76 : ATTRIBUTE_NUMBER8 (追加番号8)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  77 : ATTRIBUTE_NUMBER9 (追加番号9)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  78 : ATTRIBUTE_NUMBER10 (追加番号10)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  79 : ATTRIBUTE_NUMBER11 (追加番号11)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  80 : ATTRIBUTE_NUMBER12 (追加番号12)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  81 : ATTRIBUTE_DATE1 (追加日付1)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  82 : ATTRIBUTE_DATE2 (追加日付2)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  83 : ATTRIBUTE_DATE3 (追加日付3)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  84 : ATTRIBUTE_DATE4 (追加日付4)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  85 : ATTRIBUTE_DATE5 (追加日付5)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  86 : ATTRIBUTE_DATE6 (追加日付6)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  87 : ATTRIBUTE_DATE7 (追加日付7)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  88 : ATTRIBUTE_DATE8 (追加日付8)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  89 : ATTRIBUTE_DATE9 (追加日付9)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  90 : ATTRIBUTE_DATE10 (追加日付10)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  91 : ATTRIBUTE_DATE11 (追加日付11)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  92 : ATTRIBUTE_DATE12 (追加日付12)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_addr_rec.email_address
                      , l_sup_addr_rec.status_code
                      );                                              --  93 : E-Mail (電子メールアドレス)
-- Ver1.5 Mod Start
--      lv_file_data := lv_file_data || cv_comma || NULL;               --  94 : Batch ID (バッチID)
      lv_file_data := lv_file_data || cv_comma || 
                      l_sup_addr_rec.batch_id;                        --  94 : Batch ID (バッチID)
-- Ver1.5 Mod End
      lv_file_data := lv_file_data || cv_comma || NULL;               --  95 : Delivery Channel (決済チャネル)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  96 : Bank Instruction 1 (銀行指図1)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  97 : Bank Instruction 2 (銀行指図2)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  98 : Bank Instruction (銀行指図詳細)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  99 : Settlement Priority (精算優先度)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 100 : Payment Text Message 1 (支払テキスト・メッセージ1)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 101 : Payment Text Message 2 (支払テキスト・メッセージ2)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 102 : Payment Text Message 3 (支払テキスト・メッセージ3)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 103 : Payee Service Level (受取人サービスレベル)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 104 : Pay Each Document Alone (単独支払)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 105 : Bank Charge Bearer (銀行手数料負担者)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 106 : Payment Reason (支払事由)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 107 : Payment Reason Comments (支払事由コメント)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 108 : Delivery Method (通知方法)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 109 : Remittance E-Mail (送付先E-Mailアドレス)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 110 : Remittance Fax (送付先FAX)
      --
      BEGIN
        -- データ行のファイル出力
        UTL_FILE.PUT_LINE( gf_sup_addr_file_handle
                         , lv_file_data
                         );
        --
        -- 出力件数カウントアップ
        gn_out_sup_addr_cnt := gn_out_sup_addr_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
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
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    --
    END LOOP output_sup_addr_loop;
--
    -- カーソルクローズ
    CLOSE sup_addr_cur;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- カーソルクローズ
      IF ( sup_addr_cur%ISOPEN ) THEN
        CLOSE sup_addr_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルクローズ
      IF ( sup_addr_cur%ISOPEN ) THEN
        CLOSE sup_addr_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF ( sup_addr_cur%ISOPEN ) THEN
        CLOSE sup_addr_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF ( sup_addr_cur%ISOPEN ) THEN
        CLOSE sup_addr_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END output_sup_addr;
--
--
  /**********************************************************************************
   * Procedure Name   : output_sup_site
   * Description      : 「③サプライヤ・サイト」連携データの抽出・ファイル出力処理(A-4)
   ***********************************************************************************/
  PROCEDURE output_sup_site(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_sup_site';       -- プログラム名
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
    lv_file_data         VARCHAR2(30000) DEFAULT NULL;       -- 出力内容
--
    -- *** ローカル・カーソル ***
    -- 「③サプライヤ・サイト」の抽出カーソル
    CURSOR sup_site_cur
    IS
      SELECT
          (CASE
             WHEN (    gt_pre_process_date IS NULL
                   OR  pvsa.creation_date > gt_pre_process_date) THEN
               cv_status_create
             ELSE
               cv_status_update
           END)                                          AS status_code                     -- ステータス・コード
        , pv.vendor_name                                 AS vendor_name                     -- 仕入先名
        , (CASE
             WHEN (    gt_pre_process_date IS NULL
                   OR  pvsa.creation_date > gt_pre_process_date) THEN
               pvsa.vendor_site_code
             ELSE
               NULL
           END)                                          AS vendor_site_code_new            -- 仕入先サイトコード(新規)
        , (CASE
             WHEN xovse.vendor_site_id IS NOT NULL THEN
               xovse.vendor_site_code
             ELSE
               pvsa.vendor_site_code
           END)                                          AS vendor_site_code                -- 仕入先サイトコード
        , (CASE
             WHEN (xovse.vendor_site_id IS NOT NULL
                   AND xovse.vendor_site_code <> pvsa.vendor_site_code) THEN
               pvsa.vendor_site_code
             ELSE
               NULL
           END)                                          AS new_vendor_site_code            -- 新仕入先サイトコード
        , TO_CHAR(pvsa.inactive_date, cv_date_fmt)       AS inactive_date                   -- 無効日
        , pvsa.rfq_only_site_flag                        AS rfq_only_site_flag              -- サイト使用：ソーシングのみ
        , pvsa.purchasing_site_flag                      AS purchasing_site_flag            -- サイト使用：購買
-- Ver1.7 Mod Start
--        , pvsa.purchasing_site_flag                      AS procurement_site_flag           -- サイト使用：調達カード
        , (CASE
             WHEN pvsa.purchasing_site_flag = cv_y THEN
               pvsa.pcard_site_flag
             ELSE
               cv_n
           END)                                          AS procurement_site_flag           -- サイト使用：調達カード
-- Ver1.7 Mod End
-- Ver1.3 Mod Start
--        , pvsa.pay_site_flag                             AS pay_site_flag                   -- サイト使用：支払
        , (CASE
             WHEN (    NVL(pvsa.pay_site_flag        , cv_n) = cv_n
                   AND NVL(pvsa.rfq_only_site_flag   , cv_n) = cv_n
                   AND NVL(pvsa.purchasing_site_flag , cv_n) = cv_n) THEN
               cv_y
             ELSE
               pvsa.pay_site_flag
           END)                                          AS pay_site_flag              -- サイト使用：支払
-- Ver1.3 Mod End
        , pvsa.primary_pay_site_flag                     AS primary_pay_site_flag           -- サイト使用：主支払
        , pvsa.vendor_site_code_alt                      AS vendor_site_code_alt            -- 仕入先サイトカナ
        , pvsa.customer_num                              AS customer_num                    -- 顧客番号
        , pvsa.supplier_notif_method                     AS supplier_notif_method           -- 仕入先通知方法
        , (CASE
             WHEN pvsa.supplier_notif_method = cv_email THEN
               pvsa.email_address
             ELSE
               NULL
           END)                                          AS email_address                   -- メールアドレス
        , (CASE
             WHEN pvsa.supplier_notif_method = cv_fax THEN
               pvsa.fax_area_code
             ELSE
               NULL
           END)                                          AS fax_area_code                   -- FAX市外局番
        , (CASE
             WHEN pvsa.supplier_notif_method = cv_fax
               THEN pvsa.fax
             ELSE
               NULL
           END)                                          AS fax                             -- FAX番号
        , pvsa.hold_reason                               AS hold_reason                     -- 保留理由
        , pvsa.ship_via_lookup_code                      AS ship_via_lookup_code            -- 運送方法
-- Ver1.3 Del Start
--        , pvsa.freight_terms_lookup_code                 AS freight_terms_lookup_code       -- 運送条件：購買
-- Ver1.3 Del End
        , (CASE
             WHEN pvsa.pay_on_code = cv_receipt THEN
               cv_y
             ELSE
-- Ver1.4(E123) Mod Start
--               NULL
               cv_n
-- Ver1.4(E123) Mod End
           END)                                          AS pay_on_code                     -- 受入時支払の支払日
        , pvsa.fob_lookup_code                           AS fob_lookup_code                 -- FOBコード
--        , pvsa.country_of_origin_code                    AS country_of_origin_code          -- 原産国 -- 疎通確認時に不要判定
        , pvsa_pay.vendor_site_code                      AS pay_vendor_site_code            -- デフォルト支払サイト
-- Ver1.4(E123) Mod Start
--        , pvsa.pay_on_receipt_summary_code               AS pay_on_receipt_summary_code     -- 受入時支払の請求要約レベル
        , (CASE
             WHEN pvsa.pay_on_code = cv_receipt THEN
               pvsa.pay_on_receipt_summary_code
             ELSE
               NULL
           END)                                          AS pay_on_receipt_summary_code     -- 受入時支払の請求要約レベル
-- Ver1.4(E123) Mod End
--        , pvsa.gapless_inv_num_flag                      AS gapless_inv_num_flag            -- 欠番なしの請求書採番 -- 疎通確認時に不要判定
-- Ver1.3 Del Start
--        , pvsa.selling_company_identifier                AS selling_company_identifier      -- 販売会社識別子
-- Ver1.3 Del End
        , pvsa.invoice_currency_code                     AS invoice_currency_code           -- 請求書通貨
        , pvsa.invoice_amount_limit                      AS invoice_amount_limit            -- 請求書限度額
        , pvsa.match_option                              AS match_option                    -- 請求書照合オプション
        , pvsa.payment_currency_code                     AS payment_currency_code           -- 支払通貨
        , pvsa.payment_priority                          AS payment_priority                -- 支払優先度
        , pvsa.hold_all_payments_flag                    AS hold_all_payments_flag          -- すべての請求書の保留
        , pvsa.hold_unmatched_invoices_flag              AS hold_unmatched_invoices_flag    -- 未照合請求書の保留
        , pvsa.hold_future_payments_flag                 AS hold_future_payments_flag       -- 未検証請求書の保留
        , pvsa.hold_reason                               AS pay_hold_reason                 -- 支払保留事由
        , at.name                                        AS name                            -- 支払条件名
        , pvsa.terms_date_basis                          AS terms_date_basis                -- 支払起算日
        , pvsa.pay_date_basis_lookup_code                AS pay_date_basis_lookup_code      -- 支払期日基準
        , (CASE
             WHEN pvsa.bank_charge_bearer = cv_bearer_i THEN
               cv_bearer_x
             WHEN pvsa.bank_charge_bearer = cv_bearer_s THEN
               cv_bearer_s
             WHEN pvsa.bank_charge_bearer = cv_bearer_n THEN
               cv_bearer_n
             WHEN pvsa.bank_charge_bearer IS NULL THEN
               cv_bearer_d
          END)                                           AS bank_charge_bearer              -- 銀行手数料負担者
        , pvsa.always_take_disc_flag                     AS always_take_disc_flag           -- 割引常時計上
        , pvsa.exclude_freight_from_discount             AS exclude_freight_from_discount   -- 割引から運送費を除く
        , pvsa.pay_group_lookup_code                     AS pay_group_lookup_code           -- 支払グループ
        , (CASE
             WHEN pvsa.remittance_email IS NOT NULL THEN
               cv_email
             ELSE
               NULL
           END)                                          AS remittance_notif_method         -- 通知方法
        , pvsa.remittance_email                          AS remittance_email                -- 送付先E-Mailアドレス
        , pvsa.attribute1                                AS pvsa_attribute1                 -- 仕入先正式名称
        , pvsa.attribute2                                AS pvsa_attribute2                 -- 支払通知方法
        , pvsa.attribute3                                AS pvsa_attribute3                 -- 部門入力税計算レベル
        , pvsa.attribute4                                AS pvsa_attribute4                 -- BM支払区分
        , pvsa.attribute5                                AS pvsa_attribute5                 -- 問合せ担当拠点コード
        , pvsa.attribute6                                AS pvsa_attribute6                 -- BM税区分
        , pvsa.attribute7                                AS pvsa_attribute7                 -- 仕入先サイトEメールアドレス
        , pvsa.vendor_site_id                            AS vendor_site_id                  -- 仕入先サイトID
        , pvsa.vendor_site_code                          AS pvsa_vendor_site_code           -- 仕入先サイトコード（マスタ）
        , xovse.vendor_site_code                         AS xovse_vendor_site_code          -- 仕入先サイトコード（退避テーブル）
        , (CASE
             WHEN xovse.vendor_site_id IS NULL THEN
               cv_evac_create
             WHEN pvsa.vendor_site_code <> xovse.vendor_site_code THEN
               cv_evac_update
             ELSE
               NULL
           END)                                           AS key_ins_upd_flag                -- キー情報登録・更新フラグ
-- Ver1.5 Add Start
        , (CASE 
            WHEN ( gt_pre_process_date IS NULL ) THEN 
-- Ver1.9 Mod Start
--              TO_CHAR( gt_cur_process_date , cv_datetime_id_fmt ) || MOD( pv.vendor_id , cn_divisor_ten )
              TO_CHAR( gt_cur_process_date , cv_datetime_id_fmt ) || MOD( pv.vendor_id , gn_parallel_num )
-- Ver1.9 Mod End
            ELSE
              NULL
          END)                                           AS batch_id                   -- バッチID
-- Ver1.5 Add Start
      FROM
          po_vendor_sites_all     pvsa      -- 仕入先サイト
        , po_vendors              pv        -- 仕入先マスタ
        , xxcmm_oic_vd_site_evac  xovse     -- OIC仕入先サイト退避テーブル
        , po_vendor_sites_all     pvsa_pay  -- 仕入先サイト_支払
        , ap_terms                at        -- 支払条件
      WHERE
          (   gt_pre_process_date IS NULL
-- Ver1.11 Mod Start
--           OR pvsa.last_update_date > gt_pre_process_date)
           OR (    pvsa.last_update_date > gt_pre_process_date
               AND pvsa.last_update_date <= gt_cur_process_date)
           )
-- Ver1.11 Mod End
      AND pvsa.org_id              = gt_target_organization_id
      AND pvsa.vendor_id           = pv.vendor_id
      AND NVL(pv.vendor_type_lookup_code, 'X') <> cv_employee
      AND pvsa.vendor_site_id      = xovse.vendor_site_id (+)
      AND pvsa.default_pay_site_id = pvsa_pay.vendor_site_id (+)
      AND pvsa.terms_id            = at.term_id (+)
      ORDER BY
          pv.segment1           ASC  -- 仕入先番号
        , pvsa.vendor_site_code ASC  -- 仕入先サイトコード
      FOR UPDATE OF xovse.vendor_site_code NOWAIT  -- 行ロック：OIC仕入先サイト退避テーブル
    ;
--
    -- *** ローカル・レコード ***
    -- 「③サプライヤ・サイト」の抽出カーソルレコード
    l_sup_site_rec     sup_site_cur%ROWTYPE;
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
    -- 「③サプライヤ・サイト」の抽出
    -- ==============================================================
    -- カーソルオープン
    OPEN  sup_site_cur;
    <<output_sup_site_loop>>
    LOOP
      --
      FETCH sup_site_cur INTO l_sup_site_rec;
      EXIT WHEN sup_site_cur%NOTFOUND;
      --
      -- 抽出件数カウントアップ
      gn_get_site_cnt := gn_get_site_cnt + 1;
      --
      -- ==============================================================
      -- 「③サプライヤ・サイト」のファイル出力
      -- ==============================================================
      -- データ行の作成
      lv_file_data := l_sup_site_rec.status_code;                     --   1 : Import Action * (ステータス・コード)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
-- Ver1.6 Mod Start
--                        l_sup_site_rec.vendor_name
                        xxccp_oiccommon_pkg.trim_space_tab(l_sup_site_rec.vendor_name)
-- Ver1.6 Mod End
                      , l_sup_site_rec.status_code
                      );                                              --   2 : Supplier Name* (サプライヤ名称)
      lv_file_data := lv_file_data || cv_comma || cv_sales_bu;        --   3 : Procurement BU* (調達ビジネス・ユニット)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
-- Ver1.6 Mod Start
--                        l_sup_site_rec.vendor_site_code_new
                        xxccp_oiccommon_pkg.trim_space_tab(l_sup_site_rec.vendor_site_code_new)
-- Ver1.6 Mod End
-- Ver1.3 Del Start(関連対応)
--                      , l_sup_site_rec.status_code
-- Ver1.3 Del End
                      );                                              --   4 : Address Name  (住所名)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
-- Ver1.6 Mod Start
--                        l_sup_site_rec.vendor_site_code
                        xxccp_oiccommon_pkg.trim_space_tab(l_sup_site_rec.vendor_site_code)
-- Ver1.6 Mod End
                      , l_sup_site_rec.status_code
                      );                                              --   5 : Supplier Site* (サプライヤ・サイトコード)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
-- Ver1.6 Mod Start
--                        l_sup_site_rec.new_vendor_site_code
                        xxccp_oiccommon_pkg.trim_space_tab(l_sup_site_rec.new_vendor_site_code)
-- Ver1.6 Mod End
-- Ver1.3 Del Start(関連対応)
--                      , l_sup_site_rec.status_code
-- Ver1.3 Del End
                      );                                              --   6 : Supplier Site New (新サプライヤ・サイトコード)
      lv_file_data := lv_file_data || cv_comma || 
                      nvl_by_status_code(
                        l_sup_site_rec.inactive_date
                      , l_sup_site_rec.status_code
                      );                                              --   7 : Inactive Date (非アクティブ日)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.rfq_only_site_flag
                      , l_sup_site_rec.status_code
                      , cv_n
                      , cv_n
                      );                                              --   8 : Sourcing only (【サイト目的】ソーシングのみ)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.purchasing_site_flag
                      , l_sup_site_rec.status_code
                      , cv_n
                      , cv_n
                      );                                              --   9 : Purchasing (【サイト目的】購買)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.procurement_site_flag
                      , l_sup_site_rec.status_code
                      , cv_n
                      , cv_n
                      );                                              --  10 : Procurement card (【サイト目的】調達カード)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.pay_site_flag
                      , l_sup_site_rec.status_code
                      , cv_n
                      , cv_n
                      );                                              --  11 : Pay (【サイト目的】支払)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.primary_pay_site_flag
                      , l_sup_site_rec.status_code
                      , cv_n
                      , cv_n
                      );                                              --  12 : Primary Pay (【サイト目的】プライマリ支払)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  13 : Income tax reporting site (所得税レポートサイト)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.vendor_site_code_alt
                      , l_sup_site_rec.status_code
                      );                                              --  14 : Alternate Site Name (サプライヤ・サイト(代替名))
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.customer_num
                      , l_sup_site_rec.status_code
                      );                                              --  15 : Customer Number (顧客番号)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  16 : Enable B2B Messaging (B2B通信方法)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  17 : B2B Supplier Site Code (B2Bサプライヤサイトコード)"
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.supplier_notif_method
                      , l_sup_site_rec.status_code
                      );                                              --  18 : Communication Method (通信方法)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.email_address
                      , l_sup_site_rec.status_code
                      );                                              --  19 : E-Mail (E-Mailアドレス)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  20 : Fax Country Code (FAX国コード)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.fax_area_code
                      , l_sup_site_rec.status_code
                      );                                              --  21 : Fax Area Code (FAX市外局番)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.fax
                      , l_sup_site_rec.status_code
                      );                                              --  22 : Fax (FAX番号)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  23 : Hold all new purchasing documents (全新規購買文書の保留)
-- Ver1.3 Mod Start
--      lv_file_data := lv_file_data || cv_comma || 
--                      to_csv_string(
--                        l_sup_site_rec.hold_reason
--                      , l_sup_site_rec.status_code
--                      );                                              --  24 : Purchasing Hold Reason (保留事由)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  24 : Purchasing Hold Reason (保留事由)
-- Ver1.3 Mod End
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.ship_via_lookup_code
                      , l_sup_site_rec.status_code
                      );                                              --  25 : Carrier (出荷方法)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  26 : Mode of Transport (輸送条件)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  27 : Service Level (サービスレベル)
-- Ver1.3 Mod Start
--      lv_file_data := lv_file_data || cv_comma || 
--                      to_csv_string(
--                        l_sup_site_rec.freight_terms_lookup_code
--                      , l_sup_site_rec.status_code
--                      );                                              --  28 : Freight Terms (運送条件)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  28 : Freight Terms (運送条件)
-- Ver1.3 Mod End
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.pay_on_code
                      , l_sup_site_rec.status_code
                      );                                              --  29 : Pay on receipt (受入時支払)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.fob_lookup_code
                      , l_sup_site_rec.status_code
                      );                                              --  30 : FOB (FOB)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  31 : Country of Origin (原産国)
      lv_file_data := lv_file_data || cv_comma || cv_n;               --  32 : Buyer Managed Transportation (Buyer Managed Transportation)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  33 : Pay on use (使用時支払)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  34 : Aging Onset Point (経過期間開始時点)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  35 : Aging Period Days (経過期間日数)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  36 : Consumption Advice Frequency (消費通知頻度)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  37 : Consumption Advice Summary (消費通知要約)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
-- Ver1.6 Mod Start
--                        l_sup_site_rec.pay_vendor_site_code
                        xxccp_oiccommon_pkg.trim_space_tab(l_sup_site_rec.pay_vendor_site_code)
-- Ver1.6 Mod End
                      , l_sup_site_rec.status_code
                      );                                              --  38 : Alternate Pay Site (デフォルト支払サイト)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.pay_on_receipt_summary_code
                      , l_sup_site_rec.status_code
                      );                                              --  39 : Invoice Summary Level (請求書要約レベル)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  40 : Gapless invoice numbering (欠番なしの請求書採番)
-- Ver1.3 Mod Start
--      lv_file_data := lv_file_data || cv_comma || 
--                      to_csv_string(
--                        l_sup_site_rec.selling_company_identifier
--                      , l_sup_site_rec.status_code
--                      );                                              --  41 : Selling Company Identifier (販売会社識別子)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  41 : Selling Company Identifier (販売会社識別子)
-- Ver1.3 Mod End
      lv_file_data := lv_file_data || cv_comma || cv_y;               --  42 : Create debit memo from return (返品からのデビット・メモの作成)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  43 : Ship-to Exception Action  (出荷先例外処理)
      lv_file_data := lv_file_data || cv_comma || cv_level_3;         --  44 : Receipt Routing (受入経路)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  45 : Over-receipt Tolerance (超過受入許容範囲)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  46 : Over-receipt Action (超過受入処理)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  47 : Early Receipt Tolerance in Days (納期前受入許容日数)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  48 : Late Receipt Tolerance in Days (納期後受入許容日数)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  49 : Allow Substitute Receipts (代替受入の許可)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  50 : Allow unordered receipts (未オーダー受入の許可)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  51 : Receipt Date Exception (受入日例外)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.invoice_currency_code
                      , l_sup_site_rec.status_code
                      );                                              --  52 : Invoice Currency (請求書通貨)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.invoice_amount_limit
                      , l_sup_site_rec.status_code
                      );                                              --  53 : Invoice Amount Limit (請求書限度額)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.match_option
                      , l_sup_site_rec.status_code
                      );                                              --  54 : Invoice Match Option (請求書照合オプション)
      lv_file_data := lv_file_data || cv_comma || cv_level_3;         --  55 : Match Approval Level (照合承認レベル)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.payment_currency_code
                      , l_sup_site_rec.status_code
                      );                                              --  56 : Payment Currency (支払通貨)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.payment_priority
                      , l_sup_site_rec.status_code
                      );                                              --  57 : Payment Priority (支払優先度)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        gt_prf_val_dmy_sup_payment
                      , l_sup_site_rec.status_code
                      );                                              --  58 : Pay Group (支払グループ)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  59 : Quantity Tolerances (数量許容範囲)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  60 : Amount Tolerance (金額許容範囲)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.hold_all_payments_flag
                      , l_sup_site_rec.status_code
                      , cv_n
                      , cv_n
                      );                                              --  61 : Hold All Invoices (すべての請求書の保留)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.hold_unmatched_invoices_flag
                      , l_sup_site_rec.status_code
                      , cv_n
                      , cv_n
                      );                                              --  62 : Hold Unmatched Invoices (未照合請求書の保留)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.hold_future_payments_flag
                      , l_sup_site_rec.status_code
                      , cv_n
                      , cv_n
                      );                                              --  63 : Hold Unvalidated Invoices (未検証請求書の保留)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  64 : Payment Hold By (支払保留者)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  65 : Payment Hold Date (支払保留した日付)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.pay_hold_reason
                      , l_sup_site_rec.status_code
                      );                                              --  66 : Payment Hold Reason (支払保留事由)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.name
                      , l_sup_site_rec.status_code
                      );                                              --  67 : Payment Terms (支払条件)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.terms_date_basis
                      , l_sup_site_rec.status_code
                      );                                              --  68 : Terms Date Basis (支払起算日)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.pay_date_basis_lookup_code
                      , l_sup_site_rec.status_code
                      );                                              --  69 : Pay Date Basis (支払期日基準)
      lv_file_data := lv_file_data || cv_comma || 
                      l_sup_site_rec.bank_charge_bearer;              --  70 : Bank Charge Deduction Type (銀行手数料控除タイプ)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.always_take_disc_flag
                      , l_sup_site_rec.status_code
                      , cv_n
                      , cv_n
                      );                                              --  71 : Always Take Discount (割引常時計上)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.exclude_freight_from_discount
                      , l_sup_site_rec.status_code
                      , cv_n
                      , cv_n
                      );                                              --  72 : Exclude Freight From Discount (割引から運送費を除く)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  73 : Exclude Tax From Discount (割引から税金を除く)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  74 : Create Interest Invoices (利息請求書の作成)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  75 : Vat Code-Obsoleted (付加価値税コード)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  76 : Tax Registration Number-Obsoleted (付加価値税登録番号)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.pay_group_lookup_code
                      , l_sup_site_rec.status_code
                      );                                              --  77 : Payment Method (支払方法)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  78 : Delivery Channel (決済チャネル)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  79 : Bank Instruction 1 (銀行指図1)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  80 : Bank Instruction 2 (銀行指図2)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  81 : Bank Instruction (銀行指図詳細)
      lv_file_data := lv_file_data || cv_comma || cv_express;         --  82 : Settlement Priority (精算優先度)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  83 : Payment Text Message 1 (支払テキストメッセージ1)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  84 : Payment Text Message 2 (支払テキストメッセージ2)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  85 : Payment Text Message 3 (支払テキストメッセージ3)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  86 : Bank Charge Bearer (銀行手数料負担者)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  87 : Payment Reason (支払事由)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  88 : Payment Reason Comments (支払事由コメント)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.remittance_notif_method
                      , l_sup_site_rec.status_code
                      );                                              --  89 : Delivery Method (通知方法)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.remittance_email
                      , l_sup_site_rec.status_code
                      );                                              --  90 : Remittance E-Mail (送付先E-Mailアドレス)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  91 : Remittance Fax (送付先FAX)
      lv_file_data := lv_file_data || cv_comma || cv_sales_bu;        --  92 : ATTRIBUTE_CATEGORY (追加情報カテゴリ)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.pvsa_attribute1
                      , l_sup_site_rec.status_code
                      );                                              --  93 : ATTRIBUTE1（仕入先正式名称）
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.pvsa_attribute2
                      , l_sup_site_rec.status_code
                      );                                              --  94 : ATTRIBUTE2（支払通知方法）
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.pvsa_attribute3
                      , l_sup_site_rec.status_code
                      );                                              --  95 : ATTRIBUTE3（部門入力税計算レベル）
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.pvsa_attribute4
                      , l_sup_site_rec.status_code
                      );                                              --  96 : ATTRIBUTE4（BM支払区分）
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.pvsa_attribute5
                      , l_sup_site_rec.status_code
                      );                                              --  97 : ATTRIBUTE5（問合せ担当拠点コード）
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.pvsa_attribute6
                      , l_sup_site_rec.status_code
                      );                                              --  98 : ATTRIBUTE6（BM税区分）
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_rec.pvsa_attribute7
                      , l_sup_site_rec.status_code
                      );                                              --  99 : ATTRIBUTE7（仕入先サイトEメールアドレス）
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 100 : ATTRIBUTE8 (追加情報8)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 101 : ATTRIBUTE9 (追加情報9)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 102 : ATTRIBUTE10 (追加情報10)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 103 : ATTRIBUTE11 (追加情報11)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 104 : ATTRIBUTE12 (追加情報12)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 105 : ATTRIBUTE13 (追加情報13)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 106 : ATTRIBUTE14 (追加情報14)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 107 : ATTRIBUTE15 (追加情報15)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 108 : ATTRIBUTE16 (追加情報16)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 109 : ATTRIBUTE17 (追加情報17)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 110 : ATTRIBUTE18 (追加情報18)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 111 : ATTRIBUTE19 (追加情報19)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 112 : ATTRIBUTE20 (追加情報20)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 113 : ATTRIBUTE_DATE1 (追加情報_日付1)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 114 : ATTRIBUTE_DATE2 (追加情報_日付2)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 115 : ATTRIBUTE_DATE3 (追加情報_日付3)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 116 : ATTRIBUTE_DATE4 (追加情報_日付4)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 117 : ATTRIBUTE_DATE5 (追加情報_日付5)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 118 : ATTRIBUTE_DATE6 (追加情報_日付6)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 119 : ATTRIBUTE_DATE7 (追加情報_日付7)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 120 : ATTRIBUTE_DATE8 (追加情報_日付8)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 121 : ATTRIBUTE_DATE9 (追加情報_日付9)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 122 : ATTRIBUTE_DATE10 (追加情報_日付10)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 123 : ATTRIBUTE_TIMESTAMP1 (追加情報_ﾀｲﾑｽﾀﾝﾌﾟ1)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 124 : ATTRIBUTE_TIMESTAMP2 (追加情報_ﾀｲﾑｽﾀﾝﾌﾟ2)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 125 : ATTRIBUTE_TIMESTAMP3 (追加情報_ﾀｲﾑｽﾀﾝﾌﾟ3)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 126 : ATTRIBUTE_TIMESTAMP4 (追加情報_ﾀｲﾑｽﾀﾝﾌﾟ4)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 127 : ATTRIBUTE_TIMESTAMP5 (追加情報_ﾀｲﾑｽﾀﾝﾌﾟ5)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 128 : ATTRIBUTE_TIMESTAMP6 (追加情報_ﾀｲﾑｽﾀﾝﾌﾟ6)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 129 : ATTRIBUTE_TIMESTAMP7 (追加情報_ﾀｲﾑｽﾀﾝﾌﾟ7)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 130 : ATTRIBUTE_TIMESTAMP8 (追加情報_ﾀｲﾑｽﾀﾝﾌﾟ8)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 131 : ATTRIBUTE_TIMESTAMP9 (追加情報_ﾀｲﾑｽﾀﾝﾌﾟ9)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 132 : ATTRIBUTE_TIMESTAMP10 (追加情報_ﾀｲﾑｽﾀﾝﾌﾟ10)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 133 : ATTRIBUTE_NUMBER1 (追加情報_番号1)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 134 : ATTRIBUTE_NUMBER2 (追加情報_番号2)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 135 : ATTRIBUTE_NUMBER3 (追加情報_番号3)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 136 : ATTRIBUTE_NUMBER4 (追加情報_番号4)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 137 : ATTRIBUTE_NUMBER5 (追加情報_番号5)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 138 : ATTRIBUTE_NUMBER6 (追加情報_番号6)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 139 : ATTRIBUTE_NUMBER7 (追加情報_番号7)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 140 : ATTRIBUTE_NUMBER8 (追加情報_番号8)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 141 : ATTRIBUTE_NUMBER9 (追加情報_番号9)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 142 : ATTRIBUTE_NUMBER10 (追加情報_番号10)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 143 : GLOBAL_ATTRIBUTE_CATEGORY (ｸﾞﾛｰﾊﾞﾙ追加情報カテゴリ)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 144 : GLOBAL_ATTRIBUTE1 (ｸﾞﾛｰﾊﾞﾙ追加情報1)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 145 : GLOBAL_ATTRIBUTE2 (ｸﾞﾛｰﾊﾞﾙ追加情報2)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 146 : GLOBAL_ATTRIBUTE3 (ｸﾞﾛｰﾊﾞﾙ追加情報3)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 147 : GLOBAL_ATTRIBUTE4 (ｸﾞﾛｰﾊﾞﾙ追加情報4)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 148 : GLOBAL_ATTRIBUTE5 (ｸﾞﾛｰﾊﾞﾙ追加情報5)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 149 : GLOBAL_ATTRIBUTE6 (ｸﾞﾛｰﾊﾞﾙ追加情報6)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 150 : GLOBAL_ATTRIBUTE7 (ｸﾞﾛｰﾊﾞﾙ追加情報7)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 151 : GLOBAL_ATTRIBUTE8 (ｸﾞﾛｰﾊﾞﾙ追加情報8)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 152 : GLOBAL_ATTRIBUTE9 (ｸﾞﾛｰﾊﾞﾙ追加情報9)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 153 : GLOBAL_ATTRIBUTE10 (ｸﾞﾛｰﾊﾞﾙ追加情報10)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 154 : GLOBAL_ATTRIBUTE11 (ｸﾞﾛｰﾊﾞﾙ追加情報11)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 155 : GLOBAL_ATTRIBUTE12 (ｸﾞﾛｰﾊﾞﾙ追加情報12)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 156 : GLOBAL_ATTRIBUTE13 (ｸﾞﾛｰﾊﾞﾙ追加情報13)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 157 : GLOBAL_ATTRIBUTE14 (ｸﾞﾛｰﾊﾞﾙ追加情報14)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 158 : GLOBAL_ATTRIBUTE15 (ｸﾞﾛｰﾊﾞﾙ追加情報15)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 159 : GLOBAL_ATTRIBUTE16 (ｸﾞﾛｰﾊﾞﾙ追加情報16)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 160 : GLOBAL_ATTRIBUTE17 (ｸﾞﾛｰﾊﾞﾙ追加情報17)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 161 : GLOBAL_ATTRIBUTE18 (ｸﾞﾛｰﾊﾞﾙ追加情報18)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 162 : GLOBAL_ATTRIBUTE19 (ｸﾞﾛｰﾊﾞﾙ追加情報19)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 163 : GLOBAL_ATTRIBUTE20 (ｸﾞﾛｰﾊﾞﾙ追加情報20)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 164 : GLOBAL_ATTRIBUTE_DATE1 (ｸﾞﾛｰﾊﾞﾙ追加情報_日付1)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 165 : GLOBAL_ATTRIBUTE_DATE2 (ｸﾞﾛｰﾊﾞﾙ追加情報_日付2)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 166 : GLOBAL_ATTRIBUTE_DATE3 (ｸﾞﾛｰﾊﾞﾙ追加情報_日付3)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 167 : GLOBAL_ATTRIBUTE_DATE4 (ｸﾞﾛｰﾊﾞﾙ追加情報_日付4)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 168 : GLOBAL_ATTRIBUTE_DATE5 (ｸﾞﾛｰﾊﾞﾙ追加情報_日付5)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 169 : GLOBAL_ATTRIBUTE_DATE6 (ｸﾞﾛｰﾊﾞﾙ追加情報_日付6)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 170 : GLOBAL_ATTRIBUTE_DATE7 (ｸﾞﾛｰﾊﾞﾙ追加情報_日付7)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 171 : GLOBAL_ATTRIBUTE_DATE8 (ｸﾞﾛｰﾊﾞﾙ追加情報_日付8)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 172 : GLOBAL_ATTRIBUTE_DATE9 (ｸﾞﾛｰﾊﾞﾙ追加情報_日付9)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 173 : GLOBAL_ATTRIBUTE_DATE10 (ｸﾞﾛｰﾊﾞﾙ追加情報_日付10)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 174 : GLOBAL_ATTRIBUTE_TIMESTAMP1 (ｸﾞﾛｰﾊﾞﾙ追加情報_ﾀｲﾑｽﾀﾝﾌﾟ1)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 175 : GLOBAL_ATTRIBUTE_TIMESTAMP2 (ｸﾞﾛｰﾊﾞﾙ追加情報_ﾀｲﾑｽﾀﾝﾌﾟ2)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 176 : GLOBAL_ATTRIBUTE_TIMESTAMP3 (ｸﾞﾛｰﾊﾞﾙ追加情報_ﾀｲﾑｽﾀﾝﾌﾟ3)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 177 : GLOBAL_ATTRIBUTE_TIMESTAMP4 (ｸﾞﾛｰﾊﾞﾙ追加情報_ﾀｲﾑｽﾀﾝﾌﾟ4)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 178 : GLOBAL_ATTRIBUTE_TIMESTAMP5 (ｸﾞﾛｰﾊﾞﾙ追加情報_ﾀｲﾑｽﾀﾝﾌﾟ5)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 179 : GLOBAL_ATTRIBUTE_TIMESTAMP6 (ｸﾞﾛｰﾊﾞﾙ追加情報_ﾀｲﾑｽﾀﾝﾌﾟ6)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 180 : GLOBAL_ATTRIBUTE_TIMESTAMP7 (ｸﾞﾛｰﾊﾞﾙ追加情報_ﾀｲﾑｽﾀﾝﾌﾟ7)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 181 : GLOBAL_ATTRIBUTE_TIMESTAMP8 (ｸﾞﾛｰﾊﾞﾙ追加情報_ﾀｲﾑｽﾀﾝﾌﾟ8)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 182 : GLOBAL_ATTRIBUTE_TIMESTAMP9 (ｸﾞﾛｰﾊﾞﾙ追加情報_ﾀｲﾑｽﾀﾝﾌﾟ9)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 183 : GLOBAL_ATTRIBUTE_TIMESTAMP10 (ｸﾞﾛｰﾊﾞﾙ追加情報_ﾀｲﾑｽﾀﾝﾌﾟ10)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 184 : GLOBAL_ATTRIBUTE_NUMBER1 (ｸﾞﾛｰﾊﾞﾙ追加情報_番号1)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 185 : GLOBAL_ATTRIBUTE_NUMBER2 (ｸﾞﾛｰﾊﾞﾙ追加情報_番号2)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 186 : GLOBAL_ATTRIBUTE_NUMBER3 (ｸﾞﾛｰﾊﾞﾙ追加情報_番号3)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 187 : GLOBAL_ATTRIBUTE_NUMBER4 (ｸﾞﾛｰﾊﾞﾙ追加情報_番号4)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 188 : GLOBAL_ATTRIBUTE_NUMBER5 (ｸﾞﾛｰﾊﾞﾙ追加情報_番号5)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 189 : GLOBAL_ATTRIBUTE_NUMBER6 (ｸﾞﾛｰﾊﾞﾙ追加情報_番号6)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 190 : GLOBAL_ATTRIBUTE_NUMBER7 (ｸﾞﾛｰﾊﾞﾙ追加情報_番号7)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 191 : GLOBAL_ATTRIBUTE_NUMBER8 (ｸﾞﾛｰﾊﾞﾙ追加情報_番号8)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 192 : GLOBAL_ATTRIBUTE_NUMBER9 (ｸﾞﾛｰﾊﾞﾙ追加情報_番号9)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 193 : GLOBAL_ATTRIBUTE_NUMBER10 (ｸﾞﾛｰﾊﾞﾙ追加情報_番号10)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 194 : Required Acknowledgement (要確認)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 195 : Acknowledge Within Days (確認期限日数)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 196 : Invoice Channel (請求チャネル)
-- Ver1.5 Mod Start
--      lv_file_data := lv_file_data || cv_comma || NULL;               -- 197 : Batch ID (バッチID)
      lv_file_data := lv_file_data || cv_comma || 
                        l_sup_site_rec.batch_id;                      -- 197 : Batch ID (バッチID)
-- Ver1.5 Mod End
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 198 : Payee Service Level (受取人サービスレベル)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 199 : Pay Each Document Alone (単独支払)
      --
      BEGIN
        -- データ行のファイル出力
        UTL_FILE.PUT_LINE( gf_site_file_handle
                         , lv_file_data
                         );
        --
        -- 出力件数カウントアップ
        gn_out_site_cnt := gn_out_site_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
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
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
      --
      -- ==============================================================
      -- OIC仕入先サイト退避テーブルの登録・更新
      -- ==============================================================
      IF ( l_sup_site_rec.key_ins_upd_flag = cv_evac_create ) THEN
        -- 退避テーブル登録・更新フラグがCreateの場合
        BEGIN
          -- OIC仕入先サイト退避テーブルの登録
          INSERT INTO xxcmm_oic_vd_site_evac (
              vendor_site_id                        -- 仕入先サイトID
            , vendor_site_code                      -- 仕入先サイトコード
            , created_by                            -- 作成者
            , creation_date                         -- 作成日
            , last_updated_by                       -- 最終更新者
            , last_update_date                      -- 最終更新日
            , last_update_login                     -- 最終更新ログイン
            , request_id                            -- 要求ID
            , program_application_id                -- コンカレント・プログラム・アプリケーションID
            , program_id                            -- コンカレント・プログラムID
            , program_update_date                   -- プログラム更新日
          ) VALUES (
              l_sup_site_rec.vendor_site_id         -- 仕入先サイトID
            , l_sup_site_rec.pvsa_vendor_site_code  -- 仕入先サイトコード
            , cn_created_by                         -- 作成者
            , cd_creation_date                      -- 作成日
            , cn_last_updated_by                    -- 最終更新者
            , cd_last_update_date                   -- 最終更新日
            , cn_last_update_login                  -- 最終更新ログイン
            , cn_request_id                         -- 要求ID
            , cn_program_application_id             -- コンカレント・プログラム・アプリケーションID
            , cn_program_id                         -- コンカレント・プログラムID
            , cd_program_update_date                -- プログラム更新日
          );
        EXCEPTION
          WHEN OTHERS THEN
            -- 登録に失敗した場合
            lv_errmsg := SUBSTRB(
                           xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_xxcmm             -- アプリケーション短縮名：XXCMM
                           , iv_name         => cv_insert_err_msg         -- メッセージ名：挿入エラーメッセージ
                           , iv_token_name1  => cv_tkn_table              -- トークン名1：TABLE
                           , iv_token_value1 => cv_oic_site_evac_tbl_msg  -- トークン値1：OIC仕入先サイト退避テーブル
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
      ELSIF ( l_sup_site_rec.key_ins_upd_flag = cv_evac_update ) THEN
        -- 退避テーブル登録・更新フラグがUpdateの場合
        BEGIN
          -- OIC仕入先サイト退避テーブルの更新
          UPDATE
              xxcmm_oic_vd_site_evac  xovse  -- OIC仕入先サイト退避テーブル
          SET
              xovse.vendor_site_code       = l_sup_site_rec.pvsa_vendor_site_code  -- 仕入先サイトコード
            , xovse.last_update_date       = cd_last_update_date                   -- 最終更新日
            , xovse.last_updated_by        = cn_last_updated_by                    -- 最終更新者
            , xovse.last_update_login      = cn_last_update_login                  -- 最終更新ログイン
            , xovse.request_id             = cn_request_id                         -- 要求ID
            , xovse.program_application_id = cn_program_application_id             -- プログラムアプリケーションID
            , xovse.program_id             = cn_program_id                         -- プログラムID
            , xovse.program_update_date    = cd_program_update_date                -- プログラム更新日
          WHERE
              xovse.vendor_site_id         = l_sup_site_rec.vendor_site_id         -- 仕入先サイトID
          ;
        EXCEPTION
          WHEN OTHERS THEN
            -- 更新に失敗した場合
            lv_errmsg := SUBSTRB(
                           xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_xxcmm             -- アプリケーション短縮名：XXCMM
                           , iv_name         => cv_update_err_msg         -- メッセージ名：更新エラーメッセージ
                           , iv_token_name1  => cv_tkn_table              -- トークン名1：TABLE
                           , iv_token_value1 => cv_oic_site_evac_tbl_msg  -- トークン値1：OIC仕入先サイト退避テーブル
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
        -- 更新に成功した場合、更新前と更新後の仕入先名を出力
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_xxcmm                           -- アプリケーション短縮名：XXCMM
                  , iv_name         => cv_evac_data_out_msg                    -- メッセージ名：退避情報更新出力メッセージ
                  , iv_token_name1  => cv_tkn_table                            -- トークン名1：TABLE
                  , iv_token_value1 => cv_oic_site_evac_tbl_msg                -- トークン値1：OIC仕入先サイト退避テーブル
                  , iv_token_name2  => cv_tkn_id                               -- トークン名2：ID
                  , iv_token_value2 => TO_CHAR(l_sup_site_rec.vendor_site_id)  -- トークン値2：仕入先サイトID
                  , iv_token_name3  => cv_tkn_before_value                     -- トークン名3：BEFORE_VALUE
                  , iv_token_value3 => l_sup_site_rec.xovse_vendor_site_code   -- トークン値3：仕入先サイトコード（退避テーブル）
                  , iv_token_name4  => cv_tkn_after_value                      -- トークン名4：AFTER_VALUE
                  , iv_token_value4 => l_sup_site_rec.pvsa_vendor_site_code    -- トークン値4：仕入先サイトコード（マスタ）
                  );
        --
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_msg
        );
      END IF;
    --
    END LOOP output_sup_site_loop;
--
    -- カーソルクローズ
    CLOSE sup_site_cur;
--
    -- 退避情報更新出力メッセージを出力している場合
    IF ( lv_msg IS NOT NULL ) THEN
      -- 空行挿入
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
      );
    END IF;
--
  EXCEPTION
--
    -- *** ロックエラー例外ハンドラ ***
    WHEN global_lock_expt THEN
      -- カーソルクローズ
      IF ( sup_site_cur%ISOPEN ) THEN
        CLOSE sup_site_cur;
      END IF;
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm             -- アプリケーション短縮名：XXCMM
                   , iv_name         => cv_lock_err_msg           -- メッセージ名：ロックエラーメッセージ
                   , iv_token_name1  => cv_tkn_ng_table           -- トークン名1：NG_TABLE
                   , iv_token_value1 => cv_oic_site_evac_tbl_msg  -- トークン値1：テーブル名：OIC仕入先サイト退避テーブル
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
      IF ( sup_site_cur%ISOPEN ) THEN
        CLOSE sup_site_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルクローズ
      IF ( sup_site_cur%ISOPEN ) THEN
        CLOSE sup_site_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF ( sup_site_cur%ISOPEN ) THEN
        CLOSE sup_site_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF ( sup_site_cur%ISOPEN ) THEN
        CLOSE sup_site_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END output_sup_site;
--
--
  /**********************************************************************************
   * Procedure Name   : output_sup_site_ass
   * Description      : 「④サプライヤ・BU割当」連携データの抽出・ファイル出力処理(A-5)
   ***********************************************************************************/
  PROCEDURE output_sup_site_ass(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_sup_site_ass';       -- プログラム名
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
    lv_file_data         VARCHAR2(30000) DEFAULT NULL;       -- 出力内容
--
    -- *** ローカル・カーソル ***
    -- 「④サプライヤ・BU割当」の抽出カーソル
    CURSOR sup_site_ass_cur
    IS
      SELECT
          (CASE
             WHEN (    gt_pre_process_date IS NULL
                   OR  pvsa.creation_date > gt_pre_process_date) THEN
               cv_status_create
             ELSE
               cv_status_update
           END)                                          AS status_code                -- ステータス・コード
        , pv.vendor_name                                 AS vendor_name                -- 仕入先名
        , pvsa.vendor_site_code                          AS vendor_site_code           -- 仕入先サイトコード
        , hl_ship.location_code                          AS ship_loc_code              -- 事業所コード（出荷先）
        , hl_bill.location_code                          AS bill_loc_code              -- 事業所コード（請求先）
-- Ver1.3 Mod Start
--        , gcck_accts_pay.concatenated_segments           AS accts_pay_conc_segments    -- 連結セグメント（負債配分）
--        , gcck_prepay.concatenated_segments              AS prepay_conc_segments       -- 連結セグメント（前払配分）
--        , gcck_future_pay.concatenated_segments          AS future_pay_conc_segments   -- 連結セグメント（支払手形配分）
        , (CASE
             WHEN gcck_accts_pay.code_combination_id IS NOT NULL THEN
               (gcck_accts_pay.segment1 || '-' ||
                gcck_accts_pay.segment2 || '-' ||
                gcck_accts_pay.segment3 || '-' ||
                gcck_accts_pay.segment3 || gcck_accts_pay.segment4 || '-' ||
                gcck_accts_pay.segment5 || '-' ||
                gcck_accts_pay.segment6 || '-' ||
                gcck_accts_pay.segment7 || '-' ||
                gcck_accts_pay.segment8)
             ELSE
               NULL
           END)                                          AS accts_pay_conc_segments    -- 連結セグメント（負債配分）
        , (CASE
             WHEN gcck_prepay.code_combination_id IS NOT NULL THEN
               (gcck_prepay.segment1 || '-' ||
                gcck_prepay.segment2 || '-' ||
                gcck_prepay.segment3 || '-' ||
                gcck_prepay.segment3 || gcck_prepay.segment4 || '-' ||
                gcck_prepay.segment5 || '-' ||
                gcck_prepay.segment6 || '-' ||
                gcck_prepay.segment7 || '-' ||
                gcck_prepay.segment8)
             ELSE
               NULL
           END)                                          AS prepay_conc_segments       -- 連結セグメント（前払配分）
        , (CASE
             WHEN gcck_future_pay.code_combination_id IS NOT NULL THEN
               (gcck_future_pay.segment1 || '-' ||
                gcck_future_pay.segment2 || '-' ||
                gcck_future_pay.segment3 || '-' ||
                gcck_future_pay.segment3 || gcck_future_pay.segment4 || '-' ||
                gcck_future_pay.segment5 || '-' ||
                gcck_future_pay.segment6 || '-' ||
                gcck_future_pay.segment7 || '-' ||
                gcck_future_pay.segment8)
             ELSE
               NULL
           END)                                          AS future_pay_conc_segments   -- 連結セグメント（支払手形配分）
-- Ver1.3 Mod End
        , ads.distribution_set_name                      AS distribution_set_name      -- 配分セット名
        , TO_CHAR(pvsa.inactive_date, cv_date_fmt)       AS inactive_date              -- 無効日
-- Ver1.5 Add Start
        , (CASE 
            WHEN ( gt_pre_process_date IS NULL ) THEN 
-- Ver1.9 Mod Start
--              TO_CHAR( gt_cur_process_date , cv_datetime_id_fmt ) || MOD( pv.vendor_id , cn_divisor_ten )
              TO_CHAR( gt_cur_process_date , cv_datetime_id_fmt ) || MOD( pv.vendor_id , gn_parallel_num )
-- Ver1.9 Mod End
            ELSE
              NULL
          END)                                           AS batch_id                   -- バッチID
-- Ver1.5 Add End
      FROM
          po_vendor_sites_all       pvsa             -- 仕入先サイト
        , po_vendors                pv               -- 仕入先マスタ
        , hr_locations              hl_ship          -- 事業所マスタ_出荷先
        , hr_locations              hl_bill          -- 事業所マスタ_請求先
        , gl_code_combinations_kfv  gcck_accts_pay   -- 勘定科目組み合わせ_KFV_負債配分
        , gl_code_combinations_kfv  gcck_prepay      -- 勘定科目組み合わせ_KFV_前払配分
        , gl_code_combinations_kfv  gcck_future_pay  -- 勘定科目組み合わせ_KFV_支払手形配分
        , ap_distribution_sets      ads              -- 配分セット
      WHERE
          (   gt_pre_process_date IS NULL
-- Ver1.11 Mod Start
--           OR pvsa.last_update_date > gt_pre_process_date)
           OR (    pvsa.last_update_date > gt_pre_process_date
               AND pvsa.last_update_date <= gt_cur_process_date)
           )
-- Ver1.11 Mod End
      AND pvsa.org_id                        = gt_target_organization_id
      AND pvsa.vendor_id                     = pv.vendor_id
      AND NVL(pv.vendor_type_lookup_code, 'X') <> cv_employee
      AND pvsa.ship_to_location_id           = hl_ship.location_id (+)
      AND pvsa.bill_to_location_id           = hl_bill.location_id (+)
      AND pvsa.accts_pay_code_combination_id = gcck_accts_pay.code_combination_id (+)
      AND pvsa.prepay_code_combination_id    = gcck_prepay.code_combination_id (+)
      AND pvsa.future_dated_payment_ccid     = gcck_future_pay.code_combination_id (+)
      AND pvsa.distribution_set_id           = ads.distribution_set_id (+)
      ORDER BY
          pv.segment1           ASC  -- 仕入先番号
        , pvsa.vendor_site_code ASC  -- 仕入先サイトコード
    ;
--
    -- *** ローカル・レコード ***
    -- 「④サプライヤ・BU割当」の抽出カーソルレコード
    l_sup_site_ass_rec     sup_site_ass_cur%ROWTYPE;
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
    -- 「④サプライヤ・BU割当」の抽出
    -- ==============================================================
    -- カーソルオープン
    OPEN  sup_site_ass_cur;
    <<output_sup_site_ass_loop>>
    LOOP
      --
      FETCH sup_site_ass_cur INTO l_sup_site_ass_rec;
      EXIT WHEN sup_site_ass_cur%NOTFOUND;
      --
      -- 抽出件数カウントアップ
      gn_get_site_ass_cnt := gn_get_site_ass_cnt + 1;
      --
      -- ==============================================================
      -- 「④サプライヤ・BU割当」のファイル出力
      -- ==============================================================
      -- データ行の作成
      lv_file_data := l_sup_site_ass_rec.status_code;                 --  1 : Import Action * (ステータス・コード)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
-- Ver1.6 Mod Start
--                        l_sup_site_ass_rec.vendor_name
                        xxccp_oiccommon_pkg.trim_space_tab(l_sup_site_ass_rec.vendor_name)
-- Ver1.6 Mod End
                      , l_sup_site_ass_rec.status_code
                      );                                              --  2 : Supplier Name* (サプライヤ名称)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
-- Ver1.6 Mod Start
--                        l_sup_site_ass_rec.vendor_site_code
                        xxccp_oiccommon_pkg.trim_space_tab(l_sup_site_ass_rec.vendor_site_code)
-- Ver1.6 Mod End
                      , l_sup_site_ass_rec.status_code
                      );                                              --  3 : Supplier Site* (サプライヤ・サイト・コード)
      lv_file_data := lv_file_data || cv_comma || cv_sales_bu;        --  4 : Procurement BU* (調達ビジネス・ユニット)
      lv_file_data := lv_file_data || cv_comma || cv_sales_bu;        --  5 : Client BU* (クライアントビジネス・ユニット)
      lv_file_data := lv_file_data || cv_comma || cv_sales_bu;        --  6 : Bill-to BU (請求先ビジネス・ユニット)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_ass_rec.ship_loc_code
                      , l_sup_site_ass_rec.status_code
                      );                                              --  7 : Ship-to Location (出荷先事業所)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_ass_rec.bill_loc_code
                      , l_sup_site_ass_rec.status_code
                      );                                              --  8 : Bill-to Location (請求先事業所)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  9 : Use Withholding Tax (源泉徴収税の使用)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 10 : Withholding Tax Group (源泉徴収税グループ)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_ass_rec.accts_pay_conc_segments
                      , l_sup_site_ass_rec.status_code
                      );                                              -- 11 : Liability Distribution (負債配分)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_ass_rec.prepay_conc_segments
                      , l_sup_site_ass_rec.status_code
                      );                                              -- 12 : Prepayment Distribution (前払配分)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_ass_rec.future_pay_conc_segments
                      , l_sup_site_ass_rec.status_code
                      );                                              -- 13 : Bills Payable Distribution (支払手形配分)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_site_ass_rec.distribution_set_name
                      , l_sup_site_ass_rec.status_code
                      );                                              -- 14 : Distribution Set (配分セット)
      lv_file_data := lv_file_data || cv_comma || 
                      nvl_by_status_code(
                        l_sup_site_ass_rec.inactive_date
                      , l_sup_site_ass_rec.status_code
                      );                                              -- 15 : Inactive Date (非アクティブ日)
-- Ver1.5 Mod Start
--      lv_file_data := lv_file_data || cv_comma || NULL;               -- 16 : Batch ID (バッチID)
      lv_file_data := lv_file_data || cv_comma || 
                        l_sup_site_ass_rec.batch_id;                  -- 16 : Batch ID (バッチID)
-- Ver1.5 Mod Start
      --
      BEGIN
        -- データ行のファイル出力
        UTL_FILE.PUT_LINE( gf_site_ass_file_handle
                         , lv_file_data
                         );
        --
        -- 出力件数カウントアップ
        gn_out_site_ass_cnt := gn_out_site_ass_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
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
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    --
    END LOOP output_sup_site_ass_loop;
--
    -- カーソルクローズ
    CLOSE sup_site_ass_cur;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- カーソルクローズ
      IF ( sup_site_ass_cur%ISOPEN ) THEN
        CLOSE sup_site_ass_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルクローズ
      IF ( sup_site_ass_cur%ISOPEN ) THEN
        CLOSE sup_site_ass_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF ( sup_site_ass_cur%ISOPEN ) THEN
        CLOSE sup_site_ass_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF ( sup_site_ass_cur%ISOPEN ) THEN
        CLOSE sup_site_ass_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END output_sup_site_ass;
--
--
  /**********************************************************************************
   * Procedure Name   : output_sup_contact
   * Description      : 「⑤サプライヤ・担当者」連携データの抽出・ファイル出力処理(A-6)
   ***********************************************************************************/
  PROCEDURE output_sup_contact(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_sup_contact';       -- プログラム名
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
    lv_file_data         VARCHAR2(30000) DEFAULT NULL;       -- 出力内容
--
    -- *** ローカル・カーソル ***
    -- 「⑤サプライヤ・担当者」の抽出カーソル
    CURSOR sup_contact_cur
    IS
      SELECT
          (CASE
             WHEN (    gt_pre_process_date IS NULL
                   OR  pvc.creation_date > gt_pre_process_date) THEN
               cv_status_create
             ELSE
               cv_status_update
           END)                                          AS status_code                -- ステータス・コード
        , pv.vendor_name                                 AS vendor_name                -- 仕入先名
-- Ver1.3 Del Start
--        , pvc.prefix                                     AS prefix                     -- 敬称
-- Ver1.3 Del End
        , (CASE
             WHEN xovce.vendor_contact_id IS NOT NULL THEN
               xovce.first_name
             ELSE
-- Ver1.3 Mod Start
--               pvc.first_name
               NVL(pvc.first_name, cv_ast)
-- Ver1.3 Mod End
           END)                                          AS first_name                 -- 仕入先担当者名(名)
        , (CASE
             WHEN (    xovce.vendor_contact_id IS NOT NULL
-- Ver1.3 Mod Start
--                   AND NVL(xovce.first_name, '@') <> NVL(pvc.first_name, '@') ) THEN
                   AND xovce.first_name <> NVL(pvc.first_name, cv_ast) ) THEN
-- Ver1.3 Mod End
-- Ver1.3 Mod Start
--               pvc.first_name
               NVL(pvc.first_name, cv_ast)
-- Ver1.3 Mod End
             ELSE
               NULL
           END)                                          AS first_name_new             -- 新仕入先担当者名(名)
        , pvc.middle_name                                AS middle_name                -- ミドルネーム
        , (CASE
             WHEN xovce.vendor_contact_id IS NOT NULL THEN
               xovce.last_name
             ELSE
               pvc.last_name
           END)                                          AS last_name                  -- 仕入先担当者名(姓)
        , (CASE
             WHEN (    xovce.vendor_contact_id IS NOT NULL
-- Ver1.3 Mod Start(姓は必須項目のため当対応にてNVL削除)
--                   AND NVL(xovce.last_name, '@') <> NVL(pvc.last_name, '@') ) THEN
                   AND xovce.last_name <> pvc.last_name ) THEN
-- Ver1.3 Mod End
               pvc.last_name
             ELSE
               NULL
           END)                                          AS last_name_new              -- 新仕入先担当者名(姓)
        , pvc.title                                      AS title                      -- ジョブタイトル
        , (CASE
             WHEN ROW_NUMBER()
                  OVER(PARTITION BY pv.vendor_id ORDER BY pvc.vendor_contact_id) = 1 THEN
               cv_y
             ELSE
               cv_n
           END)                                          AS admin_contact              -- 管理担当
-- Ver1.4(E124) Mod Start
--        , pvc.email_address                              AS email_address              -- Eメール
        , (CASE
             WHEN (    gt_pre_process_date IS NULL
                   OR  pvc.creation_date > gt_pre_process_date) THEN
               pvc.email_address
             ELSE
               NULL
           END)                                          AS email_address              -- Eメール
-- Ver1.4(E124) Mod End
-- Ver1.3 Add Start
        , (CASE
             WHEN (    gt_pre_process_date IS NULL
                   OR  pvc.creation_date > gt_pre_process_date) THEN
               NULL
             ELSE
               pvc.email_address
           END)                                          AS email_address_new          -- Eメール（更新用）
-- Ver1.3 Add End
        , pvc.area_code                                  AS area_code                  -- 市外局番
        , pvc.phone                                      AS phone                      -- 電話番号
        , pvc.fax_area_code                              AS fax_area_code              -- FAX市外局番
        , pvc.fax                                        AS fax                        -- FAX番号
-- Ver1.3 Del Start
--        , TO_CHAR(pvc.inactive_date, cv_date_fmt)        AS inactive_date              -- 無効日
-- Ver1.3 Del End
        , pvc.vendor_contact_id                          AS vendor_contact_id          -- 仕入先担当者ID
-- Ver1.3 Mod Start
--        , pvc.first_name                                 AS pvc_first_name             -- 仕入先担当者（名）（マスタ）
        , NVL(pvc.first_name, cv_ast)                    AS pvc_first_name             -- 仕入先担当者（名）（マスタ）
-- Ver1.3 Mod End
        , pvc.last_name                                  AS pvc_last_name              -- 仕入先担当者（姓）（マスタ）
        , xovce.first_name                               AS xovce_first_name           -- 仕入先担当者（名）（退避テーブル）
        , xovce.last_name                                AS xovce_last_name            -- 仕入先担当者（姓）（退避テーブル）
        , (CASE
             WHEN xovce.vendor_contact_id IS NULL THEN
               cv_evac_create
-- Ver1.3 Mod Start(姓は必須項目のため当対応にてNVL削除)
--             WHEN (   NVL(xovce.first_name, '@') <> NVL(pvc.first_name, '@')
--                   OR NVL(xovce.last_name , '@') <> NVL(pvc.last_name , '@') ) THEN
             WHEN (   xovce.first_name <> NVL(pvc.first_name, cv_ast)
                   OR xovce.last_name  <> pvc.last_name ) THEN
-- Ver1.3 Mod End
               cv_evac_update
             ELSE
               NULL
           END)                                          AS key_ins_upd_flag           -- キー情報登録・更新フラグ
      FROM
          po_vendor_contacts         pvc    -- 仕入先担当者
        , po_vendor_sites_all        pvsa   -- 仕入先サイト
        , po_vendors                 pv     -- 仕入先マスタ
        , xxcmm_oic_vd_contact_evac  xovce  -- OIC仕入先担当者退避テーブル
      WHERE
          (   gt_pre_process_date IS NULL
-- Ver1.11 Mod Start
--           OR pvc.last_update_date > gt_pre_process_date
           OR (    pvc.last_update_date > gt_pre_process_date
               AND pvc.last_update_date <= gt_cur_process_date)
           )
-- Ver1.11 Mod End
      AND pvc.vendor_site_id    = pvsa.vendor_site_id
      AND pvsa.org_id           = gt_target_organization_id
      AND pvsa.vendor_id        = pv.vendor_id
      AND NVL(pv.vendor_type_lookup_code, 'X') <> cv_employee
      AND pvc.vendor_contact_id = xovce.vendor_contact_id (+)
      ORDER BY
          pv.segment1           ASC  -- 仕入先番号
        , pvsa.vendor_site_code ASC  -- 仕入先サイトコード
        , pvc.vendor_contact_id ASC  -- 仕入先担当者ID
      FOR UPDATE OF xovce.first_name NOWAIT  -- 行ロック：OIC仕入先担当者退避テーブル
    ;
--
    -- *** ローカル・レコード ***
    -- 「⑤サプライヤ・担当者」の抽出カーソルレコード
    l_sup_contact_rec     sup_contact_cur%ROWTYPE;
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
    -- 「⑤サプライヤ・担当者」の抽出
    -- ==============================================================
    -- カーソルオープン
    OPEN  sup_contact_cur;
    <<output_sup_contact_loop>>
    LOOP
      --
      FETCH sup_contact_cur INTO l_sup_contact_rec;
      EXIT WHEN sup_contact_cur%NOTFOUND;
      --
      -- 抽出件数カウントアップ
      gn_get_cont_cnt := gn_get_cont_cnt + 1;
      --
      -- ==============================================================
      -- 「⑤サプライヤ・担当者」のファイル出力
      -- ==============================================================
      -- データ行の作成
      lv_file_data := l_sup_contact_rec.status_code;                  --  1 : Import Action * (ステータス・コード)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
-- Ver1.6 Mod Start
--                        l_sup_contact_rec.vendor_name
                        xxccp_oiccommon_pkg.trim_space_tab(l_sup_contact_rec.vendor_name)
-- Ver1.6 Mod End
                      , l_sup_contact_rec.status_code
                      );                                              --  2 : Supplier Name* (サプライヤ名称)
-- Ver1.3 Mod Start
--      lv_file_data := lv_file_data || cv_comma || 
--                      to_csv_string(
--                        l_sup_contact_rec.prefix
--                      , l_sup_contact_rec.status_code
--                      );                                              --  3 : Prefix (敬称)
      lv_file_data := lv_file_data || cv_comma || NULL;               --  3 : Prefix (敬称)
-- Ver1.3 Mod End
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_contact_rec.first_name
                      , l_sup_contact_rec.status_code
                      );                                              --  4 : First Name (名)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_contact_rec.first_name_new
-- Ver1.3 Del Start(関連対応)
--                      , l_sup_contact_rec.status_code
-- Ver1.3 Del End
                      );                                              --  5 : First Name New (名（更新用）)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_contact_rec.middle_name
                      , l_sup_contact_rec.status_code
                      );                                              --  6 : Middle Name (ミドルネーム)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_contact_rec.last_name
                      , l_sup_contact_rec.status_code
                      );                                              --  7 : Last Name (姓)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_contact_rec.last_name_new
-- Ver1.3 Del Start(関連対応)
--                      , l_sup_contact_rec.status_code
-- Ver1.3 Del End
                      );                                              --  8 : Last Name New (姓（更新用）)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_contact_rec.title
                      , l_sup_contact_rec.status_code
                      );                                              --  9 : Job Title (ジョブタイトル)
      lv_file_data := lv_file_data || cv_comma || 
                      l_sup_contact_rec.admin_contact;                -- 10 : Administrative Contact (管理担当)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_contact_rec.email_address
                      , l_sup_contact_rec.status_code
                      );                                              -- 11 : E-Mail (Eメール)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
-- Ver1.3 Mod Start
--                        l_sup_contact_rec.email_address
                        l_sup_contact_rec.email_address_new
-- Ver1.3 Mod End
                      , l_sup_contact_rec.status_code
                      );                                              -- 12 : E-Mail New (Eメール（更新用）)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 13 : Phone Country Code (電話国コード)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_contact_rec.area_code
                      , l_sup_contact_rec.status_code
                      );                                              -- 14 : Phone Area Code (電話市外局番)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_contact_rec.phone
                      , l_sup_contact_rec.status_code
                      );                                              -- 15 : Phone (電話番号)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 16 : Phone Extension (電話番号内線)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 17 : Fax Country Code (FAX国コード)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_contact_rec.fax_area_code
                      , l_sup_contact_rec.status_code
                      );                                              -- 18 : Fax Area Code (FAX市外局番)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_contact_rec.fax
                      , l_sup_contact_rec.status_code
                      );                                              -- 19 : Fax (FAX番号)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 20 : Mobile Country Code (国番号（携帯))
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 21 : Mobile Area Code (地域番号(携帯))
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 22 : Mobile (携帯番号)
-- Ver1.3 Mod Start
--      lv_file_data := lv_file_data || cv_comma || 
--                      nvl_by_status_code(
--                        l_sup_contact_rec.inactive_date
--                      , l_sup_contact_rec.status_code
--                      );                                              -- 23 : Inactive Date (非アクティブ日)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 23 : Inactive Date (非アクティブ日)
-- Ver1.3 Mod End
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 24 : ATTRIBUTE_CATEGORY (追加カテゴリ)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 25 : ATTRIBUTE1 (追加情報1)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 26 : ATTRIBUTE2 (追加情報2)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 27 : ATTRIBUTE3 (追加情報3)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 28 : ATTRIBUTE4 (追加情報4)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 29 : ATTRIBUTE5 (追加情報5)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 30 : ATTRIBUTE6 (追加情報6)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 31 : ATTRIBUTE7 (追加情報7)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 32 : ATTRIBUTE8 (追加情報8)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 33 : ATTRIBUTE9 (追加情報9)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 34 : ATTRIBUTE10 (追加情報10)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 35 : ATTRIBUTE11 (追加情報11)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 36 : ATTRIBUTE12 (追加情報12)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 37 : ATTRIBUTE13 (追加情報13)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 38 : ATTRIBUTE14 (追加情報14)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 39 : ATTRIBUTE15 (追加情報15)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 40 : ATTRIBUTE16 (追加情報16)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 41 : ATTRIBUTE17 (追加情報17)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 42 : ATTRIBUTE18 (追加情報18)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 43 : ATTRIBUTE19 (追加情報19)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 44 : ATTRIBUTE20 (追加情報20)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 45 : ATTRIBUTE21 (追加情報21)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 46 : ATTRIBUTE22 (追加情報22)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 47 : ATTRIBUTE23 (追加情報23)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 48 : ATTRIBUTE24 (追加情報24)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 49 : ATTRIBUTE25 (追加情報25)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 50 : ATTRIBUTE26 (追加情報26)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 51 : ATTRIBUTE27 (追加情報27)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 52 : ATTRIBUTE28 (追加情報28)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 53 : ATTRIBUTE29 (追加情報29)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 54 : ATTRIBUTE30 (追加情報30)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 55 : ATTRIBUTE_NUMBER1 (追加番号1)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 56 : ATTRIBUTE_NUMBER2 (追加番号2)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 57 : ATTRIBUTE_NUMBER3 (追加番号3)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 58 : ATTRIBUTE_NUMBER4 (追加番号4)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 59 : ATTRIBUTE_NUMBER5 (追加番号5)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 60 : ATTRIBUTE_NUMBER6 (追加番号6)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 61 : ATTRIBUTE_NUMBER7 (追加番号7)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 62 : ATTRIBUTE_NUMBER8 (追加番号8)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 63 : ATTRIBUTE_NUMBER9 (追加番号9)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 64 : ATTRIBUTE_NUMBER10 (追加番号10)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 65 : ATTRIBUTE_NUMBER11 (追加番号11)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 66 : ATTRIBUTE_NUMBER12 (追加番号12)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 67 : ATTRIBUTE_DATE1 (追加日付1)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 68 : ATTRIBUTE_DATE2 (追加日付2)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 69 : ATTRIBUTE_DATE3 (追加日付3)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 70 : ATTRIBUTE_DATE4 (追加日付4)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 71 : ATTRIBUTE_DATE5 (追加日付5)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 72 : ATTRIBUTE_DATE6 (追加日付6)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 73 : ATTRIBUTE_DATE7 (追加日付7)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 74 : ATTRIBUTE_DATE8 (追加日付8)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 75 : ATTRIBUTE_DATE9 (追加日付9)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 76 : ATTRIBUTE_DATE10 (追加日付10)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 77 : ATTRIBUTE_DATE11 (追加日付11)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 78 : ATTRIBUTE_DATE12 (追加日付12)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 79 : Batch ID (バッチID)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 80 : User Account Action (ユーザー・アカウント・アクション)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 81 : Role 1 (ロール1)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 82 : Role 2 (ロール2)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 83 : Role 3 (ロール3)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 84 : Role 4 (ロール4)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 85 : Role 5 (ロール5)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 86 : Role 6 (ロール6)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 87 : Role 7 (ロール7)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 88 : Role 8 (ロール8)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 89 : Role 9 (ロール9)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 90 : Role 10 (ロール10)
      --
      BEGIN
        -- データ行のファイル出力
        UTL_FILE.PUT_LINE( gf_cont_file_handle
                         , lv_file_data
                         );
        --
        -- 出力件数カウントアップ
        gn_out_cont_cnt := gn_out_cont_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
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
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
      --
      -- ==============================================================
      -- OIC仕入先担当者退避テーブルの登録・更新
      -- ==============================================================
      IF ( l_sup_contact_rec.key_ins_upd_flag = cv_evac_create ) THEN
        -- 退避テーブル登録・更新フラグがCreateの場合
        BEGIN
          -- OIC仕入先担当者退避テーブルの登録
          INSERT INTO xxcmm_oic_vd_contact_evac (
              vendor_contact_id                    -- 仕入先担当者ID
            , first_name                           -- 名
            , last_name                            -- 姓
            , created_by                           -- 作成者
            , creation_date                        -- 作成日
            , last_updated_by                      -- 最終更新者
            , last_update_date                     -- 最終更新日
            , last_update_login                    -- 最終更新ログイン
            , request_id                           -- 要求ID
            , program_application_id               -- コンカレント・プログラム・アプリケーションID
            , program_id                           -- コンカレント・プログラムID
            , program_update_date                  -- プログラム更新日
          ) VALUES (
              l_sup_contact_rec.vendor_contact_id  -- 仕入先担当者ID
            , l_sup_contact_rec.pvc_first_name     -- 名
            , l_sup_contact_rec.pvc_last_name      -- 姓
            , cn_created_by                        -- 作成者
            , cd_creation_date                     -- 作成日
            , cn_last_updated_by                   -- 最終更新者
            , cd_last_update_date                  -- 最終更新日
            , cn_last_update_login                 -- 最終更新ログイン
            , cn_request_id                        -- 要求ID
            , cn_program_application_id            -- コンカレント・プログラム・アプリケーションID
            , cn_program_id                        -- コンカレント・プログラムID
            , cd_program_update_date               -- プログラム更新日
          );
        EXCEPTION
          WHEN OTHERS THEN
            -- 登録に失敗した場合
            lv_errmsg := SUBSTRB(
                           xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_xxcmm             -- アプリケーション短縮名：XXCMM
                           , iv_name         => cv_insert_err_msg         -- メッセージ名：挿入エラーメッセージ
                           , iv_token_name1  => cv_tkn_table              -- トークン名1：TABLE
                           , iv_token_value1 => cv_oic_cont_evac_tbl_msg  -- トークン値1：OIC仕入先担当者退避テーブル
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
      ELSIF ( l_sup_contact_rec.key_ins_upd_flag = cv_evac_update ) THEN
        -- 退避テーブル登録・更新フラグがUpdateの場合
        BEGIN
          -- OIC仕入先担当者退避テーブルの更新
          UPDATE
              xxcmm_oic_vd_contact_evac  xovce  -- OIC仕入先担当者退避テーブル
          SET
              xovce.first_name             = l_sup_contact_rec.pvc_first_name     -- 名
            , xovce.last_name              = l_sup_contact_rec.pvc_last_name      -- 姓
            , xovce.last_update_date       = cd_last_update_date                  -- 最終更新日
            , xovce.last_updated_by        = cn_last_updated_by                   -- 最終更新者
            , xovce.last_update_login      = cn_last_update_login                 -- 最終更新ログイン
            , xovce.request_id             = cn_request_id                        -- 要求ID
            , xovce.program_application_id = cn_program_application_id            -- プログラムアプリケーションID
            , xovce.program_id             = cn_program_id                        -- プログラムID
            , xovce.program_update_date    = cd_program_update_date               -- プログラム更新日
          WHERE
              xovce.vendor_contact_id      = l_sup_contact_rec.vendor_contact_id  -- 仕入先担当者ID
          ;
        EXCEPTION
          WHEN OTHERS THEN
            -- 更新に失敗した場合
            lv_errmsg := SUBSTRB(
                           xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_xxcmm             -- アプリケーション短縮名：XXCMM
                           , iv_name         => cv_update_err_msg         -- メッセージ名：更新エラーメッセージ
                           , iv_token_name1  => cv_tkn_table              -- トークン名1：TABLE
                           , iv_token_value1 => cv_oic_cont_evac_tbl_msg  -- トークン値1：OIC仕入先担当者退避テーブル
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
        -- 更新に成功した場合、更新前と更新後の仕入先名を出力
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_xxcmm                                 -- アプリケーション短縮名：XXCMM
                  , iv_name         => cv_evac_data_out_msg                          -- メッセージ名：退避情報更新出力メッセージ
                  , iv_token_name1  => cv_tkn_table                                  -- トークン名1：TABLE
                  , iv_token_value1 => cv_oic_cont_evac_tbl_msg                      -- トークン値1：OIC仕入先担当者退避テーブル
                  , iv_token_name2  => cv_tkn_id                                     -- トークン名2：ID
                  , iv_token_value2 => TO_CHAR(l_sup_contact_rec.vendor_contact_id)  -- トークン値2：仕入先担当者ID
                  , iv_token_name3  => cv_tkn_before_value                           -- トークン名3：BEFORE_VALUE
                  , iv_token_value3 => l_sup_contact_rec.xovce_first_name
                                         || ' , '
                                         || l_sup_contact_rec.xovce_last_name        -- トークン値3：仕入先担当者（名）（退避テーブル）＋
                                                                                     --              仕入先担当者（姓）（退避テーブル）
                  , iv_token_name4  => cv_tkn_after_value                            -- トークン名4：AFTER_VALUE
                  , iv_token_value4 => l_sup_contact_rec.pvc_first_name
                                         || ' , '
                                         || l_sup_contact_rec.pvc_last_name          -- トークン値4：仕入先担当者（名）（マスタ）＋
                                                                                     --              仕入先担当者（姓）（マスタ）
                  );
        --
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_msg
        );
      END IF;
    --
    END LOOP output_sup_contact_loop;
--
    -- カーソルクローズ
    CLOSE sup_contact_cur;
--
    -- 退避情報更新出力メッセージを出力している場合
    IF ( lv_msg IS NOT NULL ) THEN
        -- 空行挿入
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => ''
        );
    END IF;
--
  EXCEPTION
--
    -- *** ロックエラー例外ハンドラ ***
    WHEN global_lock_expt THEN
      -- カーソルクローズ
      IF ( sup_contact_cur%ISOPEN ) THEN
        CLOSE sup_contact_cur;
      END IF;
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm             -- アプリケーション短縮名：XXCMM
                   , iv_name         => cv_lock_err_msg           -- メッセージ名：ロックエラーメッセージ
                   , iv_token_name1  => cv_tkn_ng_table           -- トークン名1：NG_TABLE
                   , iv_token_value1 => cv_oic_cont_evac_tbl_msg  -- トークン値1：テーブル名：OIC仕入先担当者退避テーブル
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
      IF ( sup_contact_cur%ISOPEN ) THEN
        CLOSE sup_contact_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルクローズ
      IF ( sup_contact_cur%ISOPEN ) THEN
        CLOSE sup_contact_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF ( sup_contact_cur%ISOPEN ) THEN
        CLOSE sup_contact_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF ( sup_contact_cur%ISOPEN ) THEN
        CLOSE sup_contact_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END output_sup_contact;
--
--
  /**********************************************************************************
   * Procedure Name   : output_sup_contact_addr
   * Description      : 「⑥サプライヤ・担当者住所」連携データの抽出・ファイル出力処理(A-7)
   ***********************************************************************************/
  PROCEDURE output_sup_contact_addr(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_sup_contact_addr';       -- プログラム名
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
    lv_file_data         VARCHAR2(30000) DEFAULT NULL;       -- 出力内容
--
    -- *** ローカル・カーソル ***
    -- 「⑥サプライヤ・担当者住所」の抽出カーソル
    CURSOR sup_contact_addr_cur
    IS
      SELECT
-- Ver1.4(E125) Mod Start
--          (CASE
--             WHEN (    gt_pre_process_date IS NULL
--                   OR  pvc.creation_date > gt_pre_process_date) THEN
--               cv_status_create
--             ELSE
--               cv_status_update
--           END)                                          AS status_code                -- ステータス・コード
           cv_status_create                              AS status_code                -- ステータス・コード
-- Ver1.4(E125) Mod End
         , pv.vendor_name                                AS vendor_name                -- 仕入先名
         , pvsa.vendor_site_code                         AS vendor_site_code           -- 仕入先サイトコード
-- Ver1.3 Mod Start
--         , pvc.first_name                                AS first_name                 -- 仕入先担当者名(名)
         , NVL(pvc.first_name, cv_ast)                   AS first_name                 -- 仕入先担当者名(名)
-- Ver1.3 Mod End
         , pvc.last_name                                 AS last_name                  -- 仕入先担当者名(姓)
         , pvc.email_address                             AS email_address              -- Eメール
      FROM
          po_vendor_contacts   pvc   -- 仕入先担当者
        , po_vendor_sites_all  pvsa  -- 仕入先サイト
        , po_vendors           pv    -- 仕入先マスタ
      WHERE
-- Ver1.4(E125) Mod Start
--          (   gt_pre_process_date IS NULL
--           OR pvc.last_update_date > gt_pre_process_date)
          (   gt_pre_process_date IS NULL
-- Ver1.11 Mod Start
--           OR pvc.creation_date > gt_pre_process_date)
           OR (    pvc.creation_date > gt_pre_process_date
               AND pvc.creation_date <= gt_cur_process_date)
          )
-- Ver1.11 Mod End
-- Ver1.4(E125) Mod End
      AND pvc.vendor_site_id = pvsa.vendor_site_id
      AND pvsa.org_id        = gt_target_organization_id
      AND pvsa.vendor_id     = pv.vendor_id
      AND NVL(pv.vendor_type_lookup_code, 'X') <> cv_employee
      ORDER BY
          pv.segment1           ASC  -- 仕入先番号
        , pvsa.vendor_site_code ASC  -- 仕入先サイトコード
        , pvc.vendor_contact_id ASC  -- 仕入先担当者ID
    ;
--
    -- *** ローカル・レコード ***
    -- 「⑥サプライヤ・担当者住所」の抽出カーソルレコード
    l_sup_contact_addr_rec     sup_contact_addr_cur%ROWTYPE;
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
    -- 「⑥サプライヤ・担当者住所」の抽出
    -- ==============================================================
    -- カーソルオープン
    OPEN  sup_contact_addr_cur;
    <<output_sup_contact_addr_loop>>
    LOOP
      --
      FETCH sup_contact_addr_cur INTO l_sup_contact_addr_rec;
      EXIT WHEN sup_contact_addr_cur%NOTFOUND;
      --
      -- 抽出件数カウントアップ
      gn_get_cont_addr_cnt := gn_get_cont_addr_cnt + 1;
      --
      -- ==============================================================
      -- 「⑥サプライヤ・担当者住所」のファイル出力
      -- ==============================================================
      -- データ行の作成
      lv_file_data := l_sup_contact_addr_rec.status_code;             -- 1 : Import Action * (ステータス・コード)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
-- Ver1.6 Mod Start
--                        l_sup_contact_addr_rec.vendor_name
                        xxccp_oiccommon_pkg.trim_space_tab(l_sup_contact_addr_rec.vendor_name)
-- Ver1.6 Mod End
                      , l_sup_contact_addr_rec.status_code
                      );                                              -- 2 : Supplier Name* (サプライヤ名称)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
-- Ver1.6 Mod Start
--                        l_sup_contact_addr_rec.vendor_site_code
                        xxccp_oiccommon_pkg.trim_space_tab(l_sup_contact_addr_rec.vendor_site_code)
-- Ver1.6 Mod End
                      , l_sup_contact_addr_rec.status_code
                      );                                              -- 3 : Address Name * (住所名)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_contact_addr_rec.first_name
                      , l_sup_contact_addr_rec.status_code
                      );                                              -- 4 : First Name (名)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_contact_addr_rec.last_name
                      , l_sup_contact_addr_rec.status_code
                      );                                              -- 5 : Last Name (姓)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string(
                        l_sup_contact_addr_rec.email_address
                      , l_sup_contact_addr_rec.status_code
                      );                                              -- 6 : E-Mail (Eメール)
      lv_file_data := lv_file_data || cv_comma || NULL;               -- 7 : Batch ID (バッチID)
      --
      BEGIN
        -- データ行のファイル出力
        UTL_FILE.PUT_LINE( gf_cont_addr_file_handle
                         , lv_file_data
                         );
        --
        -- 出力件数カウントアップ
        gn_out_cont_addr_cnt := gn_out_cont_addr_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
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
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    --
    END LOOP output_sup_contact_addr_loop;
--
    -- カーソルクローズ
    CLOSE sup_contact_addr_cur;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- カーソルクローズ
      IF ( sup_contact_addr_cur%ISOPEN ) THEN
        CLOSE sup_contact_addr_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルクローズ
      IF ( sup_contact_addr_cur%ISOPEN ) THEN
        CLOSE sup_contact_addr_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF ( sup_contact_addr_cur%ISOPEN ) THEN
        CLOSE sup_contact_addr_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF ( sup_contact_addr_cur%ISOPEN ) THEN
        CLOSE sup_contact_addr_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END output_sup_contact_addr;
--
--
  /**********************************************************************************
   * Procedure Name   : output_sup_payee
   * Description      : 「⑦サプライヤ・支払先」連携データの抽出・ファイル出力処理(A-8)
   ***********************************************************************************/
  PROCEDURE output_sup_payee(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_sup_payee';       -- プログラム名
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
    lv_file_data         VARCHAR2(30000) DEFAULT NULL;       -- 出力内容
--
    -- *** ローカル・カーソル ***
    -- 「⑦サプライヤ・支払先」の抽出カーソル
    CURSOR sup_payee_cur
    IS
-- Ver1.8 Add Start
      WITH add_filter AS (
        SELECT
            pvsa.vendor_id                   AS vendor_id
          , pvsa.vendor_site_id              AS vendor_site_id
-- Ver1.10 Mod Start
--          , pv.last_update_date              AS last_update_date_pv
--          , pvsa.last_update_date            AS last_update_date_pvsa
--          , abaua.last_update_date           AS last_update_date_abaua
          , pv.creation_date                 AS creation_date_pv
          , pvsa.creation_date               AS creation_date_pvsa
          , abaua.creation_date              AS creation_date_abaua
-- Ver1.10 Mod End
          , abaa.last_update_date            AS last_update_date_abaa
-- Ver1.12 Add Start
          , abb. last_update_date            AS last_update_date_abb
-- Ver1.12 Add End
          , (CASE
               WHEN (   NVL(xobae.bank_account_num, '@')   <> NVL(abaa.bank_account_num, '@')
                     OR NVL(xobae.bank_number, '@')        <> NVL(abb.bank_number, '@')
                     OR NVL(xobae.bank_branch_number, '@') <> NVL(abb.bank_num, '@') ) THEN
                 cv_y
               ELSE
                 cv_n
             END)                            AS spec_items_chg_flag
        FROM
            ap_bank_branches          abb    -- 銀行支店
          , ap_bank_accounts_all      abaa   -- 銀行口座
          , ap_bank_account_uses_all  abaua  -- 銀行口座使用
          , po_vendor_sites_all       pvsa   -- 仕入先サイト
          , po_vendors                pv     -- 仕入先マスタ
          , xxcmm_oic_bank_acct_evac  xobae  -- OIC銀行口座退避テーブル
        WHERE
-- Ver1.11 Mod Start
--            (   abaa.last_update_date  > gt_pre_process_date
--             OR abaua.last_update_date > gt_pre_process_date)
            (   (      abaa.last_update_date  > gt_pre_process_date
                   AND abaa.last_update_date  <= gt_cur_process_date)
             OR (      abaua.last_update_date > gt_pre_process_date
-- Ver1.12 Mod Start
--                   AND abaua.last_update_date <= gt_cur_process_date))
                   AND abaua.last_update_date <= gt_cur_process_date)
             OR (
                       abb.last_update_date > gt_pre_process_date
                   AND abb.last_update_date <= gt_cur_process_date)
            )
-- Ver1.12 Mod End
-- Ver1.11 Mod End
        AND abb.bank_branch_id   = abaa.bank_branch_id
        AND abaa.bank_account_id = abaua.external_bank_account_id
        AND abaua.vendor_id      = pvsa.vendor_id
        AND abaua.vendor_site_id = pvsa.vendor_site_id
        AND pvsa.org_id          = gt_target_organization_id
        AND pvsa.vendor_id       = pv.vendor_id
        AND NVL(pv.vendor_type_lookup_code, 'X') <> cv_employee
        AND abaa.bank_account_id = xobae.bank_account_id (+)
      )
-- Ver1.8 Add End
      SELECT
          pvsa.vendor_site_id                            AS vendor_site_id             -- 仕入先サイトID
        , pv.segment1                                    AS segment1                   -- 仕入先番号
        , pvsa.vendor_site_code                          AS vendor_site_code           -- 仕入先サイトコード
        , pvsa.exclusive_payment_flag                    AS exclusive_payment_flag     -- 個別支払
        , pvsa.pay_group_lookup_code                     AS pay_group_lookup_code      -- 支払グループ
        , (CASE
              WHEN pvsa.remittance_email IS NOT NULL THEN
                cv_email
              ELSE
                NULL 
            END)                                         AS remit_delivery_method      -- 送金通知方法
        , pvsa.remittance_email                          AS remittance_email           -- 送付先E-Mailアドレス
-- Ver1.5 Add Start
        , (CASE 
            WHEN ( gt_pre_process_date IS NULL ) THEN 
-- Ver1.9 Mod Start
--              TO_CHAR( gt_cur_process_date , cv_datetime_id_fmt ) || MOD( pv.vendor_id , cn_divisor_ten )
              TO_CHAR( gt_cur_process_date , cv_datetime_id_fmt ) || MOD( pv.vendor_id , gn_parallel_num )
-- Ver1.9 Mod End
            ELSE
              TO_CHAR( gt_cur_process_date , cv_datetime_id_fmt )
          END)                                           AS batch_id                   -- バッチID
-- Ver1.5 Add End
      FROM
          po_vendor_sites_all  pvsa  -- 仕入先サイト
        , po_vendors           pv    -- 仕入先マスタ
      WHERE
          pvsa.org_id    = gt_target_organization_id
      AND pvsa.vendor_id = pv.vendor_id
      AND NVL(pv.vendor_type_lookup_code, 'X') <> cv_employee
-- Ver1.12 Add Start
      AND ( pvsa.inactive_date IS NULL
            OR pvsa.inactive_date > gt_cur_process_date
          )
      AND ( pv.end_date_active IS NULL
            OR pv.end_date_active > gt_cur_process_date
          )
-- Ver1.12 Add End
      AND EXISTS (
              SELECT
                  1  AS flag
              FROM
                  ap_bank_accounts_all      abaa
                  ,ap_bank_account_uses_all  abaua
-- Ver1.12 Add Start
                  ,ap_bank_branches         abb
-- Ver1.12 Add End
              WHERE
                  (   gt_pre_process_date IS NULL
-- Ver1.11 Mod Start
--                   OR abaa.last_update_date  > gt_pre_process_date
--                   OR abaua.last_update_date > gt_pre_process_date)
                   OR (    abaa.last_update_date  > gt_pre_process_date
                       AND abaa.last_update_date  <= gt_cur_process_date)
                   OR (    abaua.last_update_date > gt_pre_process_date
                       AND abaua.last_update_date <= gt_cur_process_date)
-- Ver1.12 Add Start
                   OR (    abb.last_update_date > gt_pre_process_date
                       AND abb.last_update_date <= gt_cur_process_date)
-- Ver1.12 Add End
                  )
-- Ver1.11 Mod End
-- Ver1.12 Add Start
              AND abb.bank_branch_id   = abaa.bank_branch_id
-- Ver1.12 Add End
              AND abaa.bank_account_id = abaua.external_bank_account_id
              AND abaua.vendor_id      = pvsa.vendor_id
              AND abaua.vendor_site_id = pvsa.vendor_site_id
          )
-- Ver1.8 Add Start
      AND (
            gt_pre_process_date IS NULL
            OR
            EXISTS (
                SELECT
                    1  AS flag
                FROM
                    add_filter  af
                WHERE
                    af.vendor_id      = pvsa.vendor_id
                AND af.vendor_site_id = pvsa.vendor_site_id
-- Ver1.10 Mod Start
--                AND ((   af.last_update_date_pv    > gt_pre_process_date
--                      OR af.last_update_date_pvsa  > gt_pre_process_date
--                      OR af.last_update_date_abaua > gt_pre_process_date
-- Ver1.11 Mod Start
--                AND ((   af.creation_date_pv    > gt_pre_process_date
--                      OR af.creation_date_pvsa  > gt_pre_process_date
--                      OR af.creation_date_abaua > gt_pre_process_date
                AND ((   (    af.creation_date_pv    > gt_pre_process_date
                          AND af.creation_date_pv    <= gt_cur_process_date)
                      OR (    af.creation_date_pvsa  > gt_pre_process_date
                          AND af.creation_date_pvsa  <= gt_cur_process_date)
                      OR (    af.creation_date_abaua > gt_pre_process_date
                          AND af.creation_date_abaua <= gt_cur_process_date)
-- Ver1.11 Mod End
-- Ver1.10 Mod End
                     )
                     OR
-- Ver1.11 Mod Start
--                     (    af.last_update_date_abaa > gt_pre_process_date
-- Ver1.12 Mod Start
--                     (  (      af.last_update_date_abaa > gt_pre_process_date
--                           AND af.last_update_date_abaa <= gt_cur_process_date)
                     ((  (      af.last_update_date_abaa > gt_pre_process_date
                           AND af.last_update_date_abaa <= gt_cur_process_date)
                      OR (    af.last_update_date_abb > gt_pre_process_date
                              AND af.last_update_date_abb <= gt_cur_process_date)
                      )
-- Ver1.12 Mod End
-- Ver1.11 Mod End
                      AND af.spec_items_chg_flag = cv_y
                     ))
            )
          )
-- Ver1.8 Add End
      ORDER BY
          pv.segment1           ASC  -- 仕入先番号
        , pvsa.vendor_site_code ASC  -- 仕入先サイトコード
    ;
--
    -- *** ローカル・レコード ***
    -- 「⑦サプライヤ・支払先」の抽出カーソルレコード
    l_sup_payee_rec     sup_payee_cur%ROWTYPE;
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
    -- 「⑦サプライヤ・支払先」の抽出
    -- ==============================================================
    -- カーソルオープン
    OPEN  sup_payee_cur;
    <<output_sup_payee_loop>>
    LOOP
      --
      FETCH sup_payee_cur INTO l_sup_payee_rec;
      EXIT WHEN sup_payee_cur%NOTFOUND;
      --
      -- 抽出件数カウントアップ
      gn_get_payee_cnt := gn_get_payee_cnt + 1;
      --
      -- ==============================================================
      -- 「⑦サプライヤ・支払先」のファイル出力
      -- ==============================================================
      -- データ行の作成
-- Ver1.5 Mod Start
--      lv_file_data := TO_CHAR( gt_cur_process_date , cv_datetime_id_fmt );      --  1 : *Import Batch Identifier (インポート・バッチ識別子)
      lv_file_data := l_sup_payee_rec.batch_id;                                 --  1 : *Import Batch Identifier (インポート・バッチ識別子)
-- Ver1.5 Mod End
      lv_file_data := lv_file_data || cv_comma || 
                      l_sup_payee_rec.vendor_site_id;                           --  2 : *Payee Identifier (支払先識別子)
      lv_file_data := lv_file_data || cv_comma || cv_sales_bu;                  --  3 : Business Unit Name (ビジネス・ユニット名)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string( l_sup_payee_rec.segment1 );                --  4 : *Supplier Number (サプライヤ番号)
      lv_file_data := lv_file_data || cv_comma || 
-- Ver1.6 Mod Start
--                      to_csv_string( l_sup_payee_rec.vendor_site_code );        --  5 : Supplier Site (サプライヤ・サイト名)
                      to_csv_string( 
                        xxccp_oiccommon_pkg.trim_space_tab(l_sup_payee_rec.vendor_site_code)
                      );                                                        --  5 : Supplier Site (サプライヤ・サイト名)
-- Ver1.6 Mod End
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string( l_sup_payee_rec.exclusive_payment_flag );  --  6 : *Pay Each Document Alone (排他支払フラグ)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string( l_sup_payee_rec.pay_group_lookup_code );   --  7 : Payment Method Code (支払方法コード)
      lv_file_data := lv_file_data || cv_comma || NULL;                         --  8 : Delivery Channel Code (支払チャネルコード)
      lv_file_data := lv_file_data || cv_comma || cv_express;                   --  9 : Settlement Priority (決済優先度)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string( l_sup_payee_rec.remit_delivery_method );   -- 10 : Remit Delivery Method (送金通知方法)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string( l_sup_payee_rec.remittance_email );        -- 11 : Remit Advice Email (送金通知メールアドレス)
      lv_file_data := lv_file_data || cv_comma || NULL;                         -- 12 : Remit Advice Fax (送金通知Fax)
      lv_file_data := lv_file_data || cv_comma || NULL;                         -- 13 : Bank Instructions 1 (銀行指図1)
      lv_file_data := lv_file_data || cv_comma || NULL;                         -- 14 : Bank Instructions 2 (銀行指図2)
      lv_file_data := lv_file_data || cv_comma || NULL;                         -- 15 : Bank Instruction Details (銀行指図詳細)
      lv_file_data := lv_file_data || cv_comma || NULL;                         -- 16 : Payment Reason Code (支払事由コード)
      lv_file_data := lv_file_data || cv_comma || NULL;                         -- 17 : Payment Reason Comments (支払事由コメント)
      lv_file_data := lv_file_data || cv_comma || NULL;                         -- 18 : Payment Message1 (支払メッセージ1)
      lv_file_data := lv_file_data || cv_comma || NULL;                         -- 19 : Payment Message2 (支払メッセージ2)
      lv_file_data := lv_file_data || cv_comma || NULL;                         -- 20 : Payment Message3 (支払メッセージ3)
      lv_file_data := lv_file_data || cv_comma || NULL;                         -- 21 : Bank Charge Bearer Code (手数料負担者コード)
      --
      BEGIN
        -- データ行のファイル出力
        UTL_FILE.PUT_LINE( gf_payee_file_handle
                         , lv_file_data
                         );
        --
        -- 出力件数カウントアップ
        gn_out_payee_cnt := gn_out_payee_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
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
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    --
    END LOOP output_sup_payee_loop;
--
    -- カーソルクローズ
    CLOSE sup_payee_cur;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- カーソルクローズ
      IF ( sup_payee_cur%ISOPEN ) THEN
        CLOSE sup_payee_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルクローズ
      IF ( sup_payee_cur%ISOPEN ) THEN
        CLOSE sup_payee_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF ( sup_payee_cur%ISOPEN ) THEN
        CLOSE sup_payee_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF ( sup_payee_cur%ISOPEN ) THEN
        CLOSE sup_payee_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END output_sup_payee;
--
--
  /**********************************************************************************
   * Procedure Name   : output_sup_bank_acct
   * Description      : 「⑧サプライヤ・銀行口座」連携データの抽出・ファイル出力処理(A-9)
   ***********************************************************************************/
  PROCEDURE output_sup_bank_acct(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_sup_bank_acct';       -- プログラム名
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
    lv_file_data         VARCHAR2(30000) DEFAULT NULL;       -- 出力内容
--
    -- *** ローカル・カーソル ***
    -- 「⑧サプライヤ・銀行口座」の抽出カーソル
    CURSOR sup_bank_acct_cur
    IS
-- Ver1.8 Add Start
      WITH add_filter AS (
        SELECT
            pvsa.vendor_id                   AS vendor_id
          , pvsa.vendor_site_id              AS vendor_site_id
-- Ver1.10 Mod Start
--          , pv.last_update_date              AS last_update_date_pv
--          , pvsa.last_update_date            AS last_update_date_pvsa
--          , abaua.last_update_date           AS last_update_date_abaua
          , pv.creation_date                 AS creation_date_pv
          , pvsa.creation_date               AS creation_date_pvsa
          , abaua.creation_date              AS creation_date_abaua
-- Ver1.10 Mod End
          , abaa.last_update_date            AS last_update_date_abaa
-- Ver1.12 Add Start
          , abb. last_update_date            AS last_update_date_abb
-- Ver1.12 Add End
          , (CASE
               WHEN (   NVL(xobae.bank_account_num, '@')   <> NVL(abaa.bank_account_num, '@')
                     OR NVL(xobae.bank_number, '@')        <> NVL(abb.bank_number, '@')
                     OR NVL(xobae.bank_branch_number, '@') <> NVL(abb.bank_num, '@') ) THEN
                 cv_y
               ELSE
                 cv_n
             END)                            AS spec_items_chg_flag
        FROM
            ap_bank_branches          abb    -- 銀行支店
          , ap_bank_accounts_all      abaa   -- 銀行口座
          , ap_bank_account_uses_all  abaua  -- 銀行口座使用
          , po_vendor_sites_all       pvsa   -- 仕入先サイト
          , po_vendors                pv     -- 仕入先マスタ
          , xxcmm_oic_bank_acct_evac  xobae  -- OIC銀行口座退避テーブル
        WHERE
-- Ver1.11 Mod Start
--            (   abaa.last_update_date  > gt_pre_process_date
--             OR abaua.last_update_date > gt_pre_process_date)
            (   (      abaa.last_update_date  > gt_pre_process_date
                   AND abaa.last_update_date  <= gt_cur_process_date)
             OR (      abaua.last_update_date > gt_pre_process_date
-- Ver1.12 Mod Start
--                   AND abaua.last_update_date <= gt_cur_process_date))
                   AND abaua.last_update_date <= gt_cur_process_date)
             OR (      abb.last_update_date > gt_pre_process_date
                   AND abb.last_update_date <= gt_cur_process_date)
            )
-- Ver1.12 Mod End
-- Ver1.11 Mod End
        AND abb.bank_branch_id   = abaa.bank_branch_id
        AND abaa.bank_account_id = abaua.external_bank_account_id
        AND abaua.vendor_id      = pvsa.vendor_id
        AND abaua.vendor_site_id = pvsa.vendor_site_id
        AND pvsa.org_id          = gt_target_organization_id
        AND pvsa.vendor_id       = pv.vendor_id
        AND NVL(pv.vendor_type_lookup_code, 'X') <> cv_employee
        AND abaa.bank_account_id = xobae.bank_account_id (+)
      )
-- Ver1.8 Add End
      SELECT
          pvsa.vendor_site_id                            AS vendor_site_id             -- 仕入先サイトID
        , abaua.bank_account_uses_id                     AS bank_account_uses_id       -- 銀行口座使用ID
        , abb.bank_name                                  AS bank_name                  -- 銀行名
        , abb.bank_branch_name                           AS bank_branch_name           -- 銀行支店名
-- Ver1.1 Mod Start
--        , abb.country                                    AS country                    -- 国
        , NVL(abb.country, cv_jp)                        AS country                    -- 国
-- Ver1.1 Mod End
        , abaa.account_holder_name                       AS account_holder_name        -- 口座名義人
        , (CASE
             WHEN xobae.bank_account_id IS NOT NULL THEN
               xobae.bank_account_num
             ELSE
               abaa.bank_account_num
           END)                                          AS bank_account_num           -- 銀行口座番号
-- Ver1.4(E126) Mod Start
--        , abaa.currency_code                             AS currency_code              -- 通貨
        , NVL(abaa.currency_code, cv_yen)                AS currency_code              -- 通貨
-- Ver1.4(E126) Mod End
        , abaa.multi_currency_flag                       AS multi_currency_flag        -- 多通貨機能
        , TO_CHAR(abaa.creation_date, cv_date_fmt)       AS creation_date              -- 作成日
        , TO_CHAR(abaa.inactive_date, cv_date_fmt)       AS inactive_date              -- 非アクティブ日
        , abaa.account_holder_name_alt                   AS account_holder_name_alt    -- 口座名義人カナ
        , abaa.bank_account_type                         AS bank_account_type          -- 銀行口座の種類
        , abaa.bank_account_name                         AS bank_account_name          -- 銀行口座名
-- Ver1.5 Add Start
        , (CASE 
            WHEN ( gt_pre_process_date IS NULL ) THEN 
-- Ver1.9 Mod Start
--              TO_CHAR( gt_cur_process_date , cv_datetime_id_fmt ) || MOD( pv.vendor_id , cn_divisor_ten )
              TO_CHAR( gt_cur_process_date , cv_datetime_id_fmt ) || MOD( pv.vendor_id , gn_parallel_num )
-- Ver1.9 Mod End
            ELSE
              TO_CHAR( gt_cur_process_date , cv_datetime_id_fmt )
          END)                                           AS batch_id                   -- バッチID
-- Ver1.5 Add End
      FROM
          ap_bank_branches          abb    -- 銀行支店
        , ap_bank_accounts_all      abaa   -- 銀行口座
        , ap_bank_account_uses_all  abaua  -- 銀行口座使用
        , po_vendor_sites_all       pvsa   -- 仕入先サイト
        , po_vendors                pv     -- 仕入先マスタ
        , xxcmm_oic_bank_acct_evac  xobae  -- OIC銀行口座退避テーブル
      WHERE
          (   gt_pre_process_date IS NULL
-- Ver1.11 Mod Start
--           OR abaa.last_update_date  > gt_pre_process_date
--           OR abaua.last_update_date > gt_pre_process_date)
              OR (   (      abaa.last_update_date  > gt_pre_process_date
                        AND abaa.last_update_date  <= gt_cur_process_date)
              OR (          abaua.last_update_date > gt_pre_process_date
-- Ver1.12 Mod Start             
--                        AND abaua.last_update_date <= gt_cur_process_date))
                        AND abaua.last_update_date <= gt_cur_process_date)
              OR (          abb.last_update_date > gt_pre_process_date
                        AND abb.last_update_date <= gt_cur_process_date)
                )
           )
-- Ver1.12 Mod End
-- Ver1.11 Mod End
      AND abb.bank_branch_id   = abaa.bank_branch_id
      AND abaa.bank_account_id = abaua.external_bank_account_id
      AND abaua.vendor_id      = pvsa.vendor_id
      AND abaua.vendor_site_id = pvsa.vendor_site_id
      AND pvsa.org_id          = gt_target_organization_id
      AND pvsa.vendor_id       = pv.vendor_id
      AND NVL(pv.vendor_type_lookup_code, 'X') <> cv_employee
      AND abaa.bank_account_id = xobae.bank_account_id (+)
-- Ver1.12 Add Start
      AND ( pvsa.inactive_date IS NULL
            OR pvsa.inactive_date > gt_cur_process_date
          )
      AND ( pv.end_date_active IS NULL
            OR pv.end_date_active > gt_cur_process_date
          )
-- Ver1.12 Add End
-- Ver1.8 Add Start
      AND (
            gt_pre_process_date IS NULL
            OR
            EXISTS (
                SELECT
                    1  AS flag
                FROM
                    add_filter  af
                WHERE
                    af.vendor_id      = pvsa.vendor_id
                AND af.vendor_site_id = pvsa.vendor_site_id
-- Ver1.10 Mod Start
--                AND ((   af.last_update_date_pv    > gt_pre_process_date
--                      OR af.last_update_date_pvsa  > gt_pre_process_date
--                      OR af.last_update_date_abaua > gt_pre_process_date
-- Ver1.11 Mod Start
--                AND ((   af.creation_date_pv    > gt_pre_process_date
--                      OR af.creation_date_pvsa  > gt_pre_process_date
--                      OR af.creation_date_abaua > gt_pre_process_date
                AND ((   (    af.creation_date_pv    > gt_pre_process_date
                          AND af.creation_date_pv    <= gt_cur_process_date)
                      OR (    af.creation_date_pvsa  > gt_pre_process_date
                          AND af.creation_date_pvsa  <= gt_cur_process_date)
                      OR (    af.creation_date_abaua > gt_pre_process_date
                          AND af.creation_date_abaua <= gt_cur_process_date)
-- Ver1.11 Mod End
-- Ver1.10 Mod End
                     )
                     OR
-- Ver1.11 Mod Start
--                     (    af.last_update_date_abaa > gt_pre_process_date
-- Ver1.12 Mod Start
--                     (  (      af.last_update_date_abaa > gt_pre_process_date
--                           AND af.last_update_date_abaa <= gt_cur_process_date)
                     ((  (      af.last_update_date_abaa > gt_pre_process_date
                           AND af.last_update_date_abaa <= gt_cur_process_date)
                      OR (    af.last_update_date_abb > gt_pre_process_date
                              AND af.last_update_date_abb <= gt_cur_process_date)
                      )
-- Ver1.12 Mod End
-- Ver1.11 Mod End
                      AND af.spec_items_chg_flag = cv_y
                     ))
            )
          )
-- Ver1.8 Add End
      ORDER BY
          pv.segment1           ASC  -- 仕入先番号
        , pvsa.vendor_site_code ASC  -- 仕入先サイトコード
        , abaa.bank_account_num ASC  -- 銀行口座番号
    ;
--
    -- *** ローカル・レコード ***
    -- 「⑧サプライヤ・銀行口座」の抽出カーソルレコード
    l_sup_bank_acct_rec     sup_bank_acct_cur%ROWTYPE;
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
    -- 「⑧サプライヤ・銀行口座」の抽出
    -- ==============================================================
    -- カーソルオープン
    OPEN  sup_bank_acct_cur;
    <<output_sup_bank_acct_loop>>
    LOOP
      --
      FETCH sup_bank_acct_cur INTO l_sup_bank_acct_rec;
      EXIT WHEN sup_bank_acct_cur%NOTFOUND;
      --
      -- 抽出件数カウントアップ
      gn_get_bnk_acct_cnt := gn_get_bnk_acct_cnt + 1;
      --
      -- ==============================================================
      -- 「⑧サプライヤ・銀行口座」のファイル出力
      -- ==============================================================
      -- データ行の作成
-- Ver1.5 Mod Start
--      lv_file_data := TO_CHAR( gt_cur_process_date , cv_datetime_id_fmt );           --  1 : *Import Batch Identifier (インポート・バッチ識別子)
      lv_file_data := l_sup_bank_acct_rec.batch_id;                                  --  1 : *Import Batch Identifier (インポート・バッチ識別子)
-- Ver1.5 Mod End
      lv_file_data := lv_file_data || cv_comma || 
                      l_sup_bank_acct_rec.vendor_site_id;                            --  2 : *Payee Identifier (支払先識別子)
      lv_file_data := lv_file_data || cv_comma || 
                      l_sup_bank_acct_rec.bank_account_uses_id;                      --  3 : *Payee Bank Account Identifier (支払先銀行口座識別子)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string( l_sup_bank_acct_rec.bank_name );                --  4 : **Bank Name (銀行名)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string( l_sup_bank_acct_rec.bank_branch_name );         --  5 : **Branch Name (銀行支店名)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string( l_sup_bank_acct_rec.country );                  --  6 : *Account Country Code (口座国コード)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string( l_sup_bank_acct_rec.account_holder_name );      --  7 : Account Name (口座名)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string( l_sup_bank_acct_rec.bank_account_num );         --  8 : *Account Number (口座番号)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string( l_sup_bank_acct_rec.currency_code );            --  9 : Account Currency Code (口座通貨コード)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string( l_sup_bank_acct_rec.multi_currency_flag );      -- 10 : Allow International Payments (国外支払許可フラグ)
      lv_file_data := lv_file_data || cv_comma || 
                      l_sup_bank_acct_rec.creation_date;                             -- 11 : Account Start Date (日付：自)
      lv_file_data := lv_file_data || cv_comma || 
                      l_sup_bank_acct_rec.inactive_date;                             -- 12 : Account End Date (非アクティブ日)
      lv_file_data := lv_file_data || cv_comma || NULL;                              -- 13 : IBAN (IBAN)
      lv_file_data := lv_file_data || cv_comma || NULL;                              -- 14 : Check Digits (チェック・ディジット)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string( l_sup_bank_acct_rec.account_holder_name_alt );  -- 15 : Account Alternate Name (口座別名)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string( l_sup_bank_acct_rec.bank_account_type );        -- 16 : Account Type Code (口座タイプコード)
      lv_file_data := lv_file_data || cv_comma || NULL;                              -- 17 : Account Suffix (口座接尾辞)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string( l_sup_bank_acct_rec.bank_account_name );        -- 18 : Account Description (口座摘要)
      lv_file_data := lv_file_data || cv_comma || NULL;                              -- 19 : Agency Location Code (代理店所在地コード)
      lv_file_data := lv_file_data || cv_comma || NULL;                              -- 20 : Exchange Rate Agreement Number (為替レート契約番号)
      lv_file_data := lv_file_data || cv_comma || NULL;                              -- 21 : Exchange Rate Agreement Type (為替レート契約タイプ)
      lv_file_data := lv_file_data || cv_comma || NULL;                              -- 22 : Exchange Rate (為替レート)
      lv_file_data := lv_file_data || cv_comma || NULL;                              -- 23 : Secondary Account Reference (第二参照口座)
      lv_file_data := lv_file_data || cv_comma || NULL;                              -- 24 : Attribute Category (追加情報カテゴリ)
      lv_file_data := lv_file_data || cv_comma || NULL;                              -- 25 : Attribute 1 (追加情報1)
      lv_file_data := lv_file_data || cv_comma || NULL;                              -- 26 : Attribute 2 (追加情報2)
      lv_file_data := lv_file_data || cv_comma || NULL;                              -- 27 : Attribute 3 (追加情報3)
      lv_file_data := lv_file_data || cv_comma || NULL;                              -- 28 : Attribute 4 (追加情報4)
      lv_file_data := lv_file_data || cv_comma || NULL;                              -- 29 : Attribute 5 (追加情報5)
      lv_file_data := lv_file_data || cv_comma || NULL;                              -- 30 : Attribute 6 (追加情報6)
      lv_file_data := lv_file_data || cv_comma || NULL;                              -- 31 : Attribute 7 (追加情報7)
      lv_file_data := lv_file_data || cv_comma || NULL;                              -- 32 : Attribute 8 (追加情報8)
      lv_file_data := lv_file_data || cv_comma || NULL;                              -- 33 : Attribute 9 (追加情報9)
      lv_file_data := lv_file_data || cv_comma || NULL;                              -- 34 : Attribute 10 (追加情報10)
      lv_file_data := lv_file_data || cv_comma || NULL;                              -- 35 : Attribute 11 (追加情報11)
      lv_file_data := lv_file_data || cv_comma || NULL;                              -- 36 : Attribute 12 (追加情報12)
      lv_file_data := lv_file_data || cv_comma || NULL;                              -- 37 : Attribute 13 (追加情報13)
      lv_file_data := lv_file_data || cv_comma || NULL;                              -- 38 : Attribute 14 (追加情報14)
      lv_file_data := lv_file_data || cv_comma || NULL;                              -- 39 : Attribute 15 (追加情報15)
      --
      BEGIN
        -- データ行のファイル出力
        UTL_FILE.PUT_LINE( gf_bnk_acct_file_handle
                         , lv_file_data
                         );
        --
        -- 出力件数カウントアップ
        gn_out_bnk_acct_cnt := gn_out_bnk_acct_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
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
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    --
    END LOOP output_sup_bank_acct_loop;
--
    -- カーソルクローズ
    CLOSE sup_bank_acct_cur;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- カーソルクローズ
      IF ( sup_bank_acct_cur%ISOPEN ) THEN
        CLOSE sup_bank_acct_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルクローズ
      IF ( sup_bank_acct_cur%ISOPEN ) THEN
        CLOSE sup_bank_acct_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF ( sup_bank_acct_cur%ISOPEN ) THEN
        CLOSE sup_bank_acct_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF ( sup_bank_acct_cur%ISOPEN ) THEN
        CLOSE sup_bank_acct_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END output_sup_bank_acct;
--
--
  /**********************************************************************************
   * Procedure Name   : output_sup_bank_use
   * Description      : 「⑨サプライヤ・銀行口座割当」連携データの抽出・ファイル出力処理(A-10)
   ***********************************************************************************/
  PROCEDURE output_sup_bank_use(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_sup_bank_use';       -- プログラム名
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
    lv_file_data         VARCHAR2(30000) DEFAULT NULL;       -- 出力内容
--
    -- *** ローカル・カーソル ***
    -- 「⑨サプライヤ・銀行口座割当」の抽出カーソル
    CURSOR sup_bank_use_cur
    IS
-- Ver1.8 Add Start
      WITH add_filter AS (
        SELECT
            pvsa.vendor_id                   AS vendor_id
          , pvsa.vendor_site_id              AS vendor_site_id
-- Ver1.10 Mod Start
--          , pv.last_update_date              AS last_update_date_pv
--          , pvsa.last_update_date            AS last_update_date_pvsa
--          , abaua.last_update_date           AS last_update_date_abaua
          , pv.creation_date                 AS creation_date_pv
          , pvsa.creation_date               AS creation_date_pvsa
          , abaua.creation_date              AS creation_date_abaua
-- Ver1.10 Mod End
          , abaa.last_update_date            AS last_update_date_abaa
-- Ver1.12 Add Start
          , abb. last_update_date            AS last_update_date_abb
-- Ver1.12 Add End
          , (CASE
               WHEN (   NVL(xobae.bank_account_num, '@')   <> NVL(abaa.bank_account_num, '@')
                     OR NVL(xobae.bank_number, '@')        <> NVL(abb.bank_number, '@')
                     OR NVL(xobae.bank_branch_number, '@') <> NVL(abb.bank_num, '@') ) THEN
                 cv_y
               ELSE
                 cv_n
             END)                            AS spec_items_chg_flag
        FROM
            ap_bank_branches          abb    -- 銀行支店
          , ap_bank_accounts_all      abaa   -- 銀行口座
          , ap_bank_account_uses_all  abaua  -- 銀行口座使用
          , po_vendor_sites_all       pvsa   -- 仕入先サイト
          , po_vendors                pv     -- 仕入先マスタ
          , xxcmm_oic_bank_acct_evac  xobae  -- OIC銀行口座退避テーブル
        WHERE
-- Ver1.11 Mod Start
--            (   abaa.last_update_date  > gt_pre_process_date
--             OR abaua.last_update_date > gt_pre_process_date)
            (   (      abaa.last_update_date  > gt_pre_process_date
                   AND abaa.last_update_date  <= gt_cur_process_date)
             OR (      abaua.last_update_date > gt_pre_process_date
-- Ver1.12 Mod Start
--                   AND abaua.last_update_date <= gt_cur_process_date))
                   AND abaua.last_update_date <= gt_cur_process_date)
             OR (
                       abb.last_update_date > gt_pre_process_date
                   AND abb.last_update_date <= gt_cur_process_date)
            )
-- Ver1.12 Mod End
-- Ver1.11 Mod End
        AND abb.bank_branch_id   = abaa.bank_branch_id
        AND abaa.bank_account_id = abaua.external_bank_account_id
        AND abaua.vendor_id      = pvsa.vendor_id
        AND abaua.vendor_site_id = pvsa.vendor_site_id
        AND pvsa.org_id          = gt_target_organization_id
        AND pvsa.vendor_id       = pv.vendor_id
        AND NVL(pv.vendor_type_lookup_code, 'X') <> cv_employee
        AND abaa.bank_account_id = xobae.bank_account_id (+)
      )
-- Ver1.8 Add End
      SELECT
          pvsa.vendor_site_id                            AS vendor_site_id             -- 仕入先サイトID
        , abaua.bank_account_uses_id                     AS bank_account_uses_id       -- 銀行口座使用ID
        , abaua.primary_flag                             AS primary_flag               -- プライマリ・フラグ
        , TO_CHAR(abaua.start_date, cv_date_fmt)         AS start_date                 -- 開始日
        , TO_CHAR(abaua.end_date, cv_date_fmt)           AS end_date                   -- 終了日
-- Ver1.5 Add Start
        , (CASE 
            WHEN ( gt_pre_process_date IS NULL ) THEN 
-- Ver1.9 Mod Start
--              TO_CHAR( gt_cur_process_date , cv_datetime_id_fmt ) || MOD( pv.vendor_id , cn_divisor_ten )
              TO_CHAR( gt_cur_process_date , cv_datetime_id_fmt ) || MOD( pv.vendor_id , gn_parallel_num )
-- Ver1.9 Mod End
            ELSE
              TO_CHAR( gt_cur_process_date , cv_datetime_id_fmt )
          END)                                           AS batch_id                   -- バッチID
-- Ver1.5 Add End
      FROM
          ap_bank_accounts_all      abaa   -- 銀行口座
        , ap_bank_account_uses_all  abaua  -- 銀行口座使用
        , po_vendor_sites_all       pvsa   -- 仕入先サイト
        , po_vendors                pv     -- 仕入先マスタ
-- Ver1.12 Add Start
        , ap_bank_branches          abb    -- 銀行支店
-- Ver1.12 Add End
      WHERE
          (   gt_pre_process_date IS NULL
-- Ver1.11 Mod Start
--           OR abaa.last_update_date  > gt_pre_process_date
--           OR abaua.last_update_date > gt_pre_process_date)
             OR  (      abaa.last_update_date  > gt_pre_process_date
                   AND abaa.last_update_date  <= gt_cur_process_date)
             OR (      abaua.last_update_date > gt_pre_process_date
-- Ver1.12 Mod Start
--                   AND abaua.last_update_date <= gt_cur_process_date))
                   AND abaua.last_update_date <= gt_cur_process_date)
                   OR (    abb.last_update_date > gt_pre_process_date
                       AND abb.last_update_date <= gt_cur_process_date)
          )
-- Ver1.12 Mod End
-- Ver1.11 Mod End
-- Ver1.12 Add Start
      AND abb.bank_branch_id = abaa.bank_branch_id
-- Ver1.12 Add End
      AND abaa.bank_account_id = abaua.external_bank_account_id
      AND abaua.vendor_id      = pvsa.vendor_id
      AND abaua.vendor_site_id = pvsa.vendor_site_id
      AND pvsa.org_id          = gt_target_organization_id
      AND pvsa.vendor_id       = pv.vendor_id
      AND NVL(pv.vendor_type_lookup_code, 'X') <> cv_employee
-- Ver1.12 Add Start
      AND ( pvsa.inactive_date IS NULL
            OR pvsa.inactive_date > gt_cur_process_date
          )
      AND ( pv.end_date_active IS NULL
            OR pv.end_date_active > gt_cur_process_date
          )
-- Ver1.12 Add End
-- Ver1.8 Add Start
      AND (
            gt_pre_process_date IS NULL
            OR
            EXISTS (
                SELECT
                    1  AS flag
                FROM
                    add_filter  af
                WHERE
                    af.vendor_id      = pvsa.vendor_id
                AND af.vendor_site_id = pvsa.vendor_site_id
-- Ver1.10 Mod Start
--                AND ((   af.last_update_date_pv    > gt_pre_process_date
--                      OR af.last_update_date_pvsa  > gt_pre_process_date
--                      OR af.last_update_date_abaua > gt_pre_process_date
-- Ver1.11 Mod Start
--                AND ((   af.creation_date_pv    > gt_pre_process_date
--                      OR af.creation_date_pvsa  > gt_pre_process_date
--                      OR af.creation_date_abaua > gt_pre_process_date
                AND ((   (    af.creation_date_pv    > gt_pre_process_date
                          AND af.creation_date_pv    <= gt_cur_process_date)
                      OR (    af.creation_date_pvsa  > gt_pre_process_date
                          AND af.creation_date_pvsa  <= gt_cur_process_date)
                      OR (    af.creation_date_abaua > gt_pre_process_date
                          AND af.creation_date_abaua <= gt_cur_process_date)
-- Ver1.11 Mod End
-- Ver1.10 Mod End
                     )
                     OR
-- Ver1.11 Mod Start
--                     (    af.last_update_date_abaa > gt_pre_process_date
-- Ver1.12 Mod Start
--                     (  (      af.last_update_date_abaa > gt_pre_process_date
--                           AND af.last_update_date_abaa <= gt_cur_process_date)
                     ((  (      af.last_update_date_abaa > gt_pre_process_date
                           AND af.last_update_date_abaa <= gt_cur_process_date)
                      OR (    af.last_update_date_abb > gt_pre_process_date
                              AND af.last_update_date_abb <= gt_cur_process_date)
                      )
-- Ver1.11 Mod End
                      AND af.spec_items_chg_flag = cv_y
                     ))
            )
          )
-- Ver1.8 Add End
      ORDER BY
          pv.segment1           ASC  -- 仕入先番号
        , pvsa.vendor_site_code ASC  -- 仕入先サイトコード
        , abaa.bank_account_num ASC  -- 銀行口座番号
    ;
--
    -- *** ローカル・レコード ***
    -- 「⑨サプライヤ・銀行口座割当」の抽出カーソルレコード
    l_sup_bank_use_rec     sup_bank_use_cur%ROWTYPE;
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
    -- 「⑨サプライヤ・銀行口座割当」の抽出
    -- ==============================================================
    -- カーソルオープン
    OPEN  sup_bank_use_cur;
    <<output_sup_bank_use_loop>>
    LOOP
      --
      FETCH sup_bank_use_cur INTO l_sup_bank_use_rec;
      EXIT WHEN sup_bank_use_cur%NOTFOUND;
      --
      -- 抽出件数カウントアップ
      gn_get_bnk_use_cnt := gn_get_bnk_use_cnt + 1;
      --
      -- ==============================================================
      -- 「⑨サプライヤ・銀行口座割当」のファイル出力
      -- ==============================================================
      -- データ行の作成
-- Ver1.5 Mod Start
--      lv_file_data := TO_CHAR( gt_cur_process_date , cv_datetime_id_fmt );  -- 1 : *Import Batch Identifier (インポート・バッチ識別子)
      lv_file_data := l_sup_bank_use_rec.batch_id;                          -- 1 : *Import Batch Identifier (インポート・バッチ識別子)
-- Ver1.5 Mod Start
      lv_file_data := lv_file_data || cv_comma || 
                      l_sup_bank_use_rec.vendor_site_id;                    -- 2 : *Payee Identifier (支払先識別子)
      lv_file_data := lv_file_data || cv_comma || 
                      l_sup_bank_use_rec.bank_account_uses_id;              -- 3 : *Payee Bank Account Identifier (支払先銀行口座識別子)
      lv_file_data := lv_file_data || cv_comma || 
                      l_sup_bank_use_rec.bank_account_uses_id;              -- 4 : *Payee Bank Account Assignment Identifier (支払先銀行口座割当識別子)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string( l_sup_bank_use_rec.primary_flag );     -- 5 : *Primary Flag (プライマリ・フラグ)
      lv_file_data := lv_file_data || cv_comma || 
                      l_sup_bank_use_rec.start_date;                        -- 6 : Account Assignment Start Date (割当日：自)
      lv_file_data := lv_file_data || cv_comma || 
                      l_sup_bank_use_rec.end_date;                          -- 7 : Account Assignment End Date (割当日非アクティブ日)
      --
      BEGIN
        -- データ行のファイル出力
        UTL_FILE.PUT_LINE( gf_bnk_use_file_handle
                         , lv_file_data
                         );
        --
        -- 出力件数カウントアップ
        gn_out_bnk_use_cnt := gn_out_bnk_use_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
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
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    --
    END LOOP output_sup_bank_use_loop;
--
    -- カーソルクローズ
    CLOSE sup_bank_use_cur;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- カーソルクローズ
      IF ( sup_bank_use_cur%ISOPEN ) THEN
        CLOSE sup_bank_use_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルクローズ
      IF ( sup_bank_use_cur%ISOPEN ) THEN
        CLOSE sup_bank_use_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF ( sup_bank_use_cur%ISOPEN ) THEN
        CLOSE sup_bank_use_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF ( sup_bank_use_cur%ISOPEN ) THEN
        CLOSE sup_bank_use_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END output_sup_bank_use;
--
--
  /**********************************************************************************
   * Procedure Name   : output_party_tax_prf
   * Description      : 「⑩パーティ税金プロファイル」連携データの抽出・ファイル出力処理(A-11)
   ***********************************************************************************/
  PROCEDURE output_party_tax_prf(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_party_tax_prf';       -- プログラム名
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
    lv_file_data         VARCHAR2(30000) DEFAULT NULL;       -- 出力内容
--
    -- *** ローカル・カーソル ***
    -- 「⑩パーティ税金プロファイル」の抽出カーソル
    CURSOR party_tax_prf_cur
    IS
      -- 仕入先の場合
      SELECT
          cv_party_sup                                   AS party_type                 -- パーティータイプ
        , pv.segment1                                    AS party_num                  -- パーティー番号
        , NULL                                           AS party_name                 -- パーティー名
        , cv_yes                                         AS allow_tax_appl             -- 税金適用の許可
        , (CASE
             WHEN pv.auto_tax_calc_flag = cv_line THEN
               cv_line_desc
             WHEN pv.auto_tax_calc_flag = cv_header THEN
               cv_header_desc
             ELSE
               NULL 
           END)                                          AS auto_tax_calc_flag         -- 端数処理レベル
        , (CASE
             WHEN pv.ap_tax_rounding_rule  = cv_rule_n THEN
               cv_rule_n_desc
             WHEN pv.ap_tax_rounding_rule  = cv_rule_d THEN
               cv_rule_d_desc
             ELSE
               NULL 
           END)                                          AS ap_tax_rounding_rule       -- 端数処理ルール
        , pv.vat_code                                    AS vat_code                   -- 税分類コード
        , (CASE
             WHEN pv.amount_includes_tax_flag  = cv_n THEN
               cv_no
             WHEN pv.amount_includes_tax_flag  = cv_y THEN
               cv_yes
             ELSE
               NULL 
           END)                                          AS amt_includes_tax_flag      -- 税金配分金額
        , (CASE
             WHEN pv.offset_tax_flag  = cv_n THEN
               cv_no
             WHEN pv.offset_tax_flag  = cv_y THEN
               cv_yes
             ELSE
               NULL
           END)                                          AS offset_tax_flag            -- 相殺税の使用
      FROM
          po_vendors  pv  -- 仕入先マスタ
      WHERE
          (   gt_pre_process_date IS NULL
-- Ver1.11 Mod Start
--           OR pv.last_update_date > gt_pre_process_date)
           OR (    pv.last_update_date > gt_pre_process_date
               AND pv.last_update_date <= gt_cur_process_date)
          )
-- Ver1.11 Mod End
      AND NVL(pv.vendor_type_lookup_code, 'X') <> cv_employee
      AND EXISTS (
              SELECT
                  1  AS flag
              FROM
                  po_vendor_sites_all  pvsa  -- 仕入先サイト
              WHERE
                  pvsa.vendor_id = pv.vendor_id
              AND pvsa.org_id    = gt_target_organization_id
          )
      UNION ALL
      -- 仕入先サイトの場合
      SELECT
          cv_party_sup_site                              AS party_type                 -- パーティータイプ
        , pvsa.vendor_site_code                          AS party_num                  -- パーティー番号
        , pv.vendor_name                                 AS party_name                 -- パーティー名
        , cv_yes                                         AS allow_tax_appl             -- 税金適用の許可
        , (CASE
             WHEN pvsa.auto_tax_calc_flag = cv_line THEN
               cv_line_desc
             WHEN pvsa.auto_tax_calc_flag = cv_header THEN
               cv_header_desc
             ELSE
               NULL 
           END)                                          AS auto_tax_calc_flag         -- 端数処理レベル
        , (CASE
             WHEN pvsa.ap_tax_rounding_rule  = cv_rule_n THEN
               cv_rule_n_desc
             WHEN pvsa.ap_tax_rounding_rule  = cv_rule_d THEN
               cv_rule_d_desc
             ELSE
               NULL 
           END)                                          AS ap_tax_rounding_rule       -- 端数処理ルール
        , pvsa.vat_code                                  AS vat_code                   -- 税分類コード
        , (CASE
             WHEN pvsa.amount_includes_tax_flag  = cv_n THEN
               cv_no
             WHEN pvsa.amount_includes_tax_flag  = cv_y THEN
               cv_yes
             ELSE
               NULL 
           END)                                          AS amt_includes_tax_flag      -- 税金配分金額
        , (CASE
             WHEN pvsa.offset_tax_flag  = cv_n THEN
               cv_no
             WHEN pvsa.offset_tax_flag  = cv_y THEN
               cv_yes
             ELSE
               NULL
           END)                                          AS offset_tax_flag            -- 相殺税の使用
      FROM
          po_vendor_sites_all  pvsa  -- 仕入先サイト
        , po_vendors           pv    -- 仕入先マスタ
      WHERE
          (   gt_pre_process_date IS NULL
-- Ver1.11 Mod Start
--           OR pvsa.last_update_date > gt_pre_process_date)
           OR (    pvsa.last_update_date > gt_pre_process_date
               AND pvsa.last_update_date <= gt_cur_process_date)
           )
-- Ver1.11 Mod End
      AND pvsa.org_id    = gt_target_organization_id
      AND pvsa.vendor_id = pv.vendor_id
      AND NVL(pv.vendor_type_lookup_code, 'X') <> cv_employee
      ORDER BY
          party_type  ASC  -- パーティータイプ
        , party_num   ASC  -- パーティー番号
    ;
--
    -- *** ローカル・レコード ***
    -- 「⑩パーティ税金プロファイル」の抽出カーソルレコード
    l_party_tax_prf_rec     party_tax_prf_cur%ROWTYPE;
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
    -- 「⑩パーティ税金プロファイル」の抽出
    -- ==============================================================
    -- カーソルオープン
    OPEN  party_tax_prf_cur;
    <<output_party_tax_prf_loop>>
    LOOP
      --
      FETCH party_tax_prf_cur INTO l_party_tax_prf_rec;
      EXIT WHEN party_tax_prf_cur%NOTFOUND;
      --
      -- 抽出件数カウントアップ
      gn_get_tax_prf_cnt := gn_get_tax_prf_cnt + 1;
      --
      -- ==============================================================
      -- 「⑩パーティ税金プロファイル」のファイル出力
      -- ==============================================================
      -- データ行の作成
-- Ver1.3 Add Start
      lv_file_data := to_csv_string( gt_prf_ptp_record_type );                     --  1 : *Record Type (レコードタイプ)
-- Ver1.3 Add End
-- Ver1.3 Mod Start
--      lv_file_data := to_csv_string( l_party_tax_prf_rec.party_type );             --  1 : *Party Type (パーティータイプ)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string( l_party_tax_prf_rec.party_type );             --  2 : *Party Type (パーティータイプ)
-- Ver1.3 Mod End
      lv_file_data := lv_file_data || cv_comma || 
-- Ver1.6 Mod Start
--                      to_csv_string( l_party_tax_prf_rec.party_num );              --  3 : *Party Number (パーティー番号)
                      to_csv_string(
                        xxccp_oiccommon_pkg.trim_space_tab(l_party_tax_prf_rec.party_num)
                      );                                                           --  3 : *Party Number (パーティー番号)
-- Ver1.6 Mod End
      lv_file_data := lv_file_data || cv_comma || 
-- Ver1.6 Mod Start
--                      to_csv_string( l_party_tax_prf_rec.party_name );             --  4 : Party Name (パーティー名)
                      to_csv_string(
                        xxccp_oiccommon_pkg.trim_space_tab(l_party_tax_prf_rec.party_name)
                      );                                                           --  4 : Party Name (パーティー名)
-- Ver1.6 Mod End
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string( l_party_tax_prf_rec.allow_tax_appl );         --  5 : Allow tax applicability (税金適用の許可)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string( l_party_tax_prf_rec.auto_tax_calc_flag );     --  6 : Rounding Level (端数処理レベル)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string( l_party_tax_prf_rec.ap_tax_rounding_rule );   --  7 : Rounding Rule (端数処理ルール)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string( l_party_tax_prf_rec.vat_code );               --  8 : Tax Classification (税分類コード)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string( l_party_tax_prf_rec.amt_includes_tax_flag );  --  9 : Set Invoice value as Tax Inclusive (税金配分金額)
      lv_file_data := lv_file_data || cv_comma || 
                      to_csv_string( l_party_tax_prf_rec.offset_tax_flag );        -- 10 : Allow Offset Taxes (相殺税の使用)
      lv_file_data := lv_file_data || cv_comma || NULL;                            -- 11 : Country Code ()
      lv_file_data := lv_file_data || cv_comma || NULL;                            -- 12 : Tax Registration Type  ()
      lv_file_data := lv_file_data || cv_comma || NULL;                            -- 13 : Registration Number ()
      --
      BEGIN
        -- データ行のファイル出力
        UTL_FILE.PUT_LINE( gf_tax_prf_file_handle
                         , lv_file_data
                         );
        --
        -- 出力件数カウントアップ
        gn_out_tax_prf_cnt := gn_out_tax_prf_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
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
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    --
    END LOOP output_party_tax_prf_loop;
--
    -- カーソルクローズ
    CLOSE party_tax_prf_cur;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- カーソルクローズ
      IF ( party_tax_prf_cur%ISOPEN ) THEN
        CLOSE party_tax_prf_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルクローズ
      IF ( party_tax_prf_cur%ISOPEN ) THEN
        CLOSE party_tax_prf_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF ( party_tax_prf_cur%ISOPEN ) THEN
        CLOSE party_tax_prf_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF ( party_tax_prf_cur%ISOPEN ) THEN
        CLOSE party_tax_prf_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END output_party_tax_prf;
--
--
  /**********************************************************************************
   * Procedure Name   : output_bank_update
   * Description      : 「⑪銀行口座更新用」データの抽出・ファイル出力処理(A-12)
   ***********************************************************************************/
  PROCEDURE output_bank_update(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_bank_update';       -- プログラム名
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
    lv_file_data         VARCHAR2(30000) DEFAULT NULL;       -- 出力内容
--
    -- *** ローカル・カーソル ***
    -- 「⑪銀行口座更新用」の抽出カーソル
    CURSOR bank_update_cur
    IS
      SELECT
          abb.bank_name                                  AS bank_name                  -- 銀行名
        , abb.bank_branch_name                           AS bank_branch_name           -- 銀行支店名
-- Ver1.1 Mod Start
--        , abb.country                                    AS country                    -- 国
        , NVL(abb.country, cv_jp)                        AS country                    -- 国
-- Ver1.1 Mod End
        , abaa.account_holder_name                       AS account_holder_name        -- 口座名義人
        , abaa.bank_account_num                          AS bank_account_num           -- 銀行口座番号
-- Ver1.4(E126) Mod Start
--        , abaa.currency_code                             AS currency_code              -- 通貨
        , NVL(abaa.currency_code, cv_yen)                AS currency_code              -- 通貨
-- Ver1.4(E126) Mod End
        , abaa.multi_currency_flag                       AS multi_currency_flag        -- 多通貨機能
        , TO_CHAR(abaa.creation_date, cv_date_fmt)       AS creation_date              -- 作成日
        , TO_CHAR(abaa.inactive_date, cv_date_fmt)       AS inactive_date              -- 非アクティブ日
        , abaa.account_holder_name_alt                   AS account_holder_name_alt    -- 口座名義人カナ
        , abaa.bank_account_type                         AS bank_account_type          -- 銀行口座の種類
        , (CASE
             WHEN xobae.bank_account_id IS NOT NULL THEN
               xobae.bank_account_num
             ELSE
               abaa.bank_account_num
           END)                                          AS bank_account_num_for_id    -- 銀行口座番号（内部ID取得用）
        , abaa.bank_account_id                           AS bank_account_id            -- 銀行口座ID
-- Ver1.8 Add Start
        , abb.bank_number                                AS bank_number                -- 銀行番号
        , abb.bank_num                                   AS bank_num                   -- 銀行支店番号
-- Ver1.8 Add End
        , xobae.bank_account_num                         AS xobae_bank_account_num     -- 銀行口座番号（退避テーブル）
-- Ver1.8 Add Start
        , xobae.bank_number                              AS xobae_bank_number          -- 銀行番号（退避テーブル）
        , xobae.bank_branch_number                       AS xobae_bank_num             -- 銀行支店番号（退避テーブル）
-- Ver1.8 Add End
        , (CASE
             WHEN xobae.bank_account_id IS NULL THEN
               cv_evac_create
-- Ver1.8 Mod Start
--             WHEN xobae.bank_account_num <> abaa.bank_account_num  THEN
             WHEN (   NVL(xobae.bank_account_num, '@')   <> NVL(abaa.bank_account_num, '@')
                   OR NVL(xobae.bank_number, '@')        <> NVL(abb.bank_number, '@')
                   OR NVL(xobae.bank_branch_number, '@') <> NVL(abb.bank_num, '@')
                  ) THEN
-- Ver1.8 Mod End
               cv_evac_update
             ELSE
               NULL
           END)                                          AS key_ins_upd_flag           -- キー情報登録・更新フラグ
      FROM
          ap_bank_accounts_all      abaa   -- 銀行口座
        , ap_bank_branches          abb    -- 銀行支店
        , xxcmm_oic_bank_acct_evac  xobae  -- OIC銀行口座退避テーブル
      WHERE
          abaa.bank_branch_id  = abb.bank_branch_id
      AND abaa.bank_account_id = xobae.bank_account_id (+)
      AND EXISTS (
              SELECT
                  1  AS flag
              FROM
                  ap_bank_accounts_all      abaa_sub   -- 銀行口座
                , ap_bank_account_uses_all  abaua      -- 銀行口座使用
                , po_vendor_sites_all       pvsa       -- 仕入先サイト
                , po_vendors                pv         -- 仕入先マスタ
-- Ver1.12 Add Start
                , ap_bank_branches          abb_sub    -- 銀行支店
-- Ver1.12 Add End
              WHERE
                   (   gt_pre_process_date IS NULL
-- Ver1.11 Mod Start
--                    OR abaa_sub.last_update_date > gt_pre_process_date
--                    OR abaua.last_update_date    > gt_pre_process_date)
                    OR (      abaa_sub.last_update_date > gt_pre_process_date
                          AND abaa_sub.last_update_date <= gt_cur_process_date)
                    OR (      abaua.last_update_date    > gt_pre_process_date
-- Ver1.12 Mod Start
--                          AND abaua.last_update_date    <= gt_cur_process_date))
                          AND abaua.last_update_date    <= gt_cur_process_date)
                    OR (     abb_sub.last_update_date > gt_pre_process_date
                          AND abb_sub.last_update_date <= gt_cur_process_date)
                  )
-- Ver1.12 Mod End
-- Ver1.11 Mod End
-- Ver1.12 Add Start
                AND ( pvsa.inactive_date IS NULL
                      OR pvsa.inactive_date > gt_cur_process_date
                    )
                AND ( pv.end_date_active IS NULL
                      OR pv.end_date_active > gt_cur_process_date
                    )
                AND abb_sub.bank_branch_id = abaa_sub.bank_branch_id
-- Ver1.12 Add End
               AND abaa_sub.bank_account_id = abaa.bank_account_id
               AND abaa_sub.bank_account_id = abaua.external_bank_account_id
               AND abaua.vendor_id          = pvsa.vendor_id
               AND abaua.vendor_site_id     = pvsa.vendor_site_id
               AND pvsa.org_id              = gt_target_organization_id
               AND pvsa.vendor_id           = pv.vendor_id
               AND NVL(pv.vendor_type_lookup_code, 'X') <> cv_employee
          )
      ORDER BY
          abaa.bank_account_num ASC  -- 銀行口座番号
      FOR UPDATE OF xobae.bank_account_num NOWAIT  -- 行ロック：OIC銀行口座退避テーブル
    ;
--
    -- *** ローカル・レコード ***
    -- 「⑪銀行口座更新用」の抽出カーソルレコード
    l_bank_update_rec     bank_update_cur%ROWTYPE;
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
    -- 「⑪銀行口座更新用」の抽出
    -- ==============================================================
    -- カーソルオープン
    OPEN  bank_update_cur;
    <<output_bank_update_loop>>
    LOOP
      --
      FETCH bank_update_cur INTO l_bank_update_rec;
      EXIT WHEN bank_update_cur%NOTFOUND;
      --
      -- 抽出件数カウントアップ
      gn_get_bnk_upd_cnt := gn_get_bnk_upd_cnt + 1;
      --
      -- ==============================================================
      -- 「⑪銀行口座更新用」のファイル出力
      -- ==============================================================
      -- 初回処理時（前回処理日時がNULLの場合）、ファイル出力は行わない
      IF (gt_pre_process_date IS NOT NULL) THEN
        -- データ行の作成
        lv_file_data := to_csv_string( l_bank_update_rec.bank_name );                --  1 : Bank Name (銀行名)
        lv_file_data := lv_file_data || cv_comma || 
                        to_csv_string( l_bank_update_rec.bank_branch_name );         --  2 : Branch Name (銀行支店名)
        lv_file_data := lv_file_data || cv_comma || 
                        to_csv_string( l_bank_update_rec.country );                  --  3 : Account Country Code (口座国コード)
        lv_file_data := lv_file_data || cv_comma || 
                        to_csv_string( l_bank_update_rec.account_holder_name );      --  4 : Account Name (口座名)
        lv_file_data := lv_file_data || cv_comma || 
                        to_csv_string( l_bank_update_rec.bank_account_num );         --  5 : *Account Number (口座番号)
        lv_file_data := lv_file_data || cv_comma || 
                        to_csv_string( l_bank_update_rec.currency_code );            --  6 : Account Currency Code (口座通貨コード)
        lv_file_data := lv_file_data || cv_comma || 
                        to_csv_string( l_bank_update_rec.multi_currency_flag );      --  7 : Allow International Payments (国外支払許可フラグ)
        lv_file_data := lv_file_data || cv_comma || 
                        l_bank_update_rec.creation_date;                             --  8 : Account Start Date (日付：自)
        lv_file_data := lv_file_data || cv_comma || 
                        l_bank_update_rec.inactive_date;                             --  9 : Account End Date (非アクティブ日)
        lv_file_data := lv_file_data || cv_comma || 
                        to_csv_string( l_bank_update_rec.account_holder_name_alt );  -- 10 : Account Alternate Name (口座別名)
        lv_file_data := lv_file_data || cv_comma || 
                        to_csv_string( l_bank_update_rec.bank_account_type );        -- 11 : Account Type Code (口座タイプコード)
        lv_file_data := lv_file_data || cv_comma || 
                        to_csv_string( l_bank_update_rec.bank_account_num_for_id );  -- 12 : *Account Number for Search(内部ID取得用口座番号)
        --
        BEGIN
          -- データ行のファイル出力
          UTL_FILE.PUT_LINE( gf_bnk_upd_file_handle
                           , lv_file_data
                           );
          --
          -- 出力件数カウントアップ
          gn_out_bnk_upd_cnt := gn_out_bnk_upd_cnt + 1;
        EXCEPTION
          WHEN OTHERS THEN
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
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
        END;
      --
      END IF;
      --
      -- ==============================================================
      -- OIC銀行口座退避テーブルの登録・更新
      -- ==============================================================
      IF ( l_bank_update_rec.key_ins_upd_flag = cv_evac_create ) THEN
        -- 退避テーブル登録・更新フラグがCreateの場合
        BEGIN
          -- OIC銀行口座退避テーブルの登録
          INSERT INTO xxcmm_oic_bank_acct_evac (
              bank_account_id                     -- 銀行口座ID
            , bank_account_num                    -- 銀行口座番号
-- Ver1.8 Add Start
            , bank_number                         -- 銀行番号
            , bank_branch_number                  -- 銀行支店番号
-- Ver1.8 Add End
            , created_by                          -- 作成者
            , creation_date                       -- 作成日
            , last_updated_by                     -- 最終更新者
            , last_update_date                    -- 最終更新日
            , last_update_login                   -- 最終更新ログイン
            , request_id                          -- 要求ID
            , program_application_id              -- コンカレント・プログラム・アプリケーションID
            , program_id                          -- コンカレント・プログラムID
            , program_update_date                 -- プログラム更新日
          ) VALUES (
              l_bank_update_rec.bank_account_id   -- 銀行口座ID
            , l_bank_update_rec.bank_account_num  -- 銀行口座番号
-- Ver1.8 Add Start
            , l_bank_update_rec.bank_number       -- 銀行番号
            , l_bank_update_rec.bank_num          -- 銀行支店番号
-- Ver1.8 Add End
            , cn_created_by                       -- 作成者
            , cd_creation_date                    -- 作成日
            , cn_last_updated_by                  -- 最終更新者
            , cd_last_update_date                 -- 最終更新日
            , cn_last_update_login                -- 最終更新ログイン
            , cn_request_id                       -- 要求ID
            , cn_program_application_id           -- コンカレント・プログラム・アプリケーションID
            , cn_program_id                       -- コンカレント・プログラムID
            , cd_program_update_date              -- プログラム更新日
          );
        EXCEPTION
          WHEN OTHERS THEN
            -- 登録に失敗した場合
            lv_errmsg := SUBSTRB(
                           xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_xxcmm             -- アプリケーション短縮名：XXCMM
                           , iv_name         => cv_insert_err_msg         -- メッセージ名：挿入エラーメッセージ
                           , iv_token_name1  => cv_tkn_table              -- トークン名1：TABLE
                           , iv_token_value1 => cv_oic_bank_evac_tbl_msg  -- トークン値1：OIC銀行口座退避テーブル
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
      ELSIF ( l_bank_update_rec.key_ins_upd_flag = cv_evac_update ) THEN
        -- 退避テーブル登録・更新フラグがUpdateの場合
        BEGIN
          -- OIC銀行口座退避テーブルの更新
          UPDATE
              xxcmm_oic_bank_acct_evac  xobae  -- OIC銀行口座退避テーブル
          SET
              xobae.bank_account_num       = l_bank_update_rec.bank_account_num  -- 銀行口座番号
-- Ver1.8 Add Start
            , xobae.bank_number            = l_bank_update_rec.bank_number       -- 銀行番号
            , xobae.bank_branch_number     = l_bank_update_rec.bank_num          -- 銀行支店番号
-- Ver1.8 Add End
            , xobae.last_update_date       = cd_last_update_date                 -- 最終更新日
            , xobae.last_updated_by        = cn_last_updated_by                  -- 最終更新者
            , xobae.last_update_login      = cn_last_update_login                -- 最終更新ログイン
            , xobae.request_id             = cn_request_id                       -- 要求ID
            , xobae.program_application_id = cn_program_application_id           -- プログラムアプリケーションID
            , xobae.program_id             = cn_program_id                       -- プログラムID
            , xobae.program_update_date    = cd_program_update_date              -- プログラム更新日
          WHERE
              xobae.bank_account_id        = l_bank_update_rec.bank_account_id   -- 銀行口座ID
          ;
        EXCEPTION
          WHEN OTHERS THEN
            -- 更新に失敗した場合
            lv_errmsg := SUBSTRB(
                           xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_xxcmm             -- アプリケーション短縮名：XXCMM
                           , iv_name         => cv_update_err_msg         -- メッセージ名：更新エラーメッセージ
                           , iv_token_name1  => cv_tkn_table              -- トークン名1：TABLE
                           , iv_token_value1 => cv_oic_bank_evac_tbl_msg  -- トークン値1：OIC銀行口座退避テーブル
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
        -- 更新に成功した場合、更新前と更新後の銀行口座番号、銀行番号、銀行支店番号を出力
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_xxcmm                               -- アプリケーション短縮名：XXCMM
                  , iv_name         => cv_evac_data_out_msg                        -- メッセージ名：退避情報更新出力メッセージ
                  , iv_token_name1  => cv_tkn_table                                -- トークン名1：TABLE
                  , iv_token_value1 => cv_oic_bank_evac_tbl_msg                    -- トークン値1：OIC銀行口座退避テーブル
                  , iv_token_name2  => cv_tkn_id                                   -- トークン名2：ID
-- Ver1.8 Mod Start
--                  , iv_token_value2 => TO_CHAR(l_bank_update_rec.bank_account_id)  -- トークン値2：銀行口座ID
                  , iv_token_value2 => TO_CHAR(l_bank_update_rec.bank_account_id)  -- トークン値2：銀行口座ID
                                       || ' [BANK_ACCOUNT_NUM]'                    -- トークン値1：銀行口座ID＋[BANK_ACCOUNT_NUM]
-- Ver1.8 Mod End
                  , iv_token_name3  => cv_tkn_before_value                         -- トークン名3：BEFORE_VALUE
                  , iv_token_value3 => l_bank_update_rec.xobae_bank_account_num    -- トークン値3：銀行口座番号（退避テーブル）
                  , iv_token_name4  => cv_tkn_after_value                          -- トークン名4：AFTER_VALUE
                  , iv_token_value4 => l_bank_update_rec.bank_account_num          -- トークン値4：銀行口座番号
                  );
        --
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_msg
        );
        --
-- Ver1.8 Add Start
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_xxcmm                               -- アプリケーション短縮名：XXCMM
                  , iv_name         => cv_evac_data_out_msg                        -- メッセージ名：退避情報更新出力メッセージ
                  , iv_token_name1  => cv_tkn_table                                -- トークン名1：TABLE
                  , iv_token_value1 => cv_oic_bank_evac_tbl_msg                    -- トークン値1：OIC銀行口座退避テーブル
                  , iv_token_name2  => cv_tkn_id                                   -- トークン名2：ID
                  , iv_token_value2 => TO_CHAR(l_bank_update_rec.bank_account_id)
                                       || ' [BANK_NUMBER]'                         -- トークン値1：銀行口座ID＋[BANK_NUMBER]
                  , iv_token_name3  => cv_tkn_before_value                         -- トークン名3：BEFORE_VALUE
                  , iv_token_value3 => l_bank_update_rec.xobae_bank_number         -- トークン値3：銀行番号（退避テーブル）
                  , iv_token_name4  => cv_tkn_after_value                          -- トークン名4：AFTER_VALUE
                  , iv_token_value4 => l_bank_update_rec.bank_number               -- トークン値4：銀行番号
                  );
        --
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_msg
        );
        --
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_xxcmm                               -- アプリケーション短縮名：XXCMM
                  , iv_name         => cv_evac_data_out_msg                        -- メッセージ名：退避情報更新出力メッセージ
                  , iv_token_name1  => cv_tkn_table                                -- トークン名1：TABLE
                  , iv_token_value1 => cv_oic_bank_evac_tbl_msg                    -- トークン値1：OIC銀行口座退避テーブル
                  , iv_token_name2  => cv_tkn_id                                   -- トークン名2：ID
                  , iv_token_value2 => TO_CHAR(l_bank_update_rec.bank_account_id)
                                       || ' [BANK_BRANCH_NUMBER]'                  -- トークン値1：銀行口座ID＋[BANK_BRANCH_NUMBER]
                  , iv_token_name3  => cv_tkn_before_value                         -- トークン名3：BEFORE_VALUE
                  , iv_token_value3 => l_bank_update_rec.xobae_bank_num            -- トークン値3：銀行支店番号（退避テーブル）
                  , iv_token_name4  => cv_tkn_after_value                          -- トークン名4：AFTER_VALUE
                  , iv_token_value4 => l_bank_update_rec.bank_num                  -- トークン値4：銀行支店番号
                  );
        --
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_msg
        );
-- Ver1.8 Add End
      END IF;
    --
    END LOOP output_bank_update_loop;
--
    -- カーソルクローズ
    CLOSE bank_update_cur;
--
    -- 退避情報更新出力メッセージを出力している場合
    IF ( lv_msg IS NOT NULL ) THEN
        -- 空行挿入
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => ''
        );
    END IF;
--
  EXCEPTION
--
    -- *** ロックエラー例外ハンドラ ***
    WHEN global_lock_expt THEN
      -- カーソルクローズ
      IF ( bank_update_cur%ISOPEN ) THEN
        CLOSE bank_update_cur;
      END IF;
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm             -- アプリケーション短縮名：XXCMM
                   , iv_name         => cv_lock_err_msg           -- メッセージ名：ロックエラーメッセージ
                   , iv_token_name1  => cv_tkn_ng_table           -- トークン名1：NG_TABLE
                   , iv_token_value1 => cv_oic_bank_evac_tbl_msg  -- トークン値1：テーブル名：OIC銀行口座退避テーブル
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
      IF ( bank_update_cur%ISOPEN ) THEN
        CLOSE bank_update_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルクローズ
      IF ( bank_update_cur%ISOPEN ) THEN
        CLOSE bank_update_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF ( bank_update_cur%ISOPEN ) THEN
        CLOSE bank_update_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF ( bank_update_cur%ISOPEN ) THEN
        CLOSE bank_update_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END output_bank_update;
--
--
  /**********************************************************************************
   * Procedure Name   : update_mng_tbl
   * Description      : 管理テーブル登録・更新処理(A-14)
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
    IF ( gt_pre_process_date IS NULL ) THEN
      -- 前回処理日時がNULLの場合
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
                       , 5000);
          lv_errbuf  := lv_errmsg;
          RAISE global_process_expt;
      END;
    --
    ELSE
      -- 前回処理日時がNOT NULLの場合
      --
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
                       , 5000);
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
    gn_get_sup_cnt        := 0;         -- サプライヤ抽出件数
    gn_out_sup_cnt        := 0;         -- サプライヤ出力件数
    gn_get_sup_addr_cnt   := 0;         -- サプライヤ・住所抽出件数
    gn_out_sup_addr_cnt   := 0;         -- サプライヤ・住所出力件数
    gn_get_site_cnt       := 0;         -- サプライヤ・サイト抽出件数
    gn_out_site_cnt       := 0;         -- サプライヤ・サイト出力件数
    gn_get_site_ass_cnt   := 0;         -- サプライヤ・BU割当抽出件数
    gn_out_site_ass_cnt   := 0;         -- サプライヤ・BU割当出力件数
    gn_get_cont_cnt       := 0;         -- サプライヤ・担当者抽出件数
    gn_out_cont_cnt       := 0;         -- サプライヤ・担当者出力件数
    gn_get_cont_addr_cnt  := 0;         -- サプライヤ・担当者住所抽出件数
    gn_out_cont_addr_cnt  := 0;         -- サプライヤ・担当者住所出力件数
    gn_get_payee_cnt      := 0;         -- サプライヤ・支払先抽出件数
    gn_out_payee_cnt      := 0;         -- サプライヤ・支払先出力件数
    gn_get_bnk_acct_cnt   := 0;         -- サプライヤ・銀行口座抽出件数
    gn_out_bnk_acct_cnt   := 0;         -- サプライヤ・銀行口座出力件数
    gn_get_bnk_use_cnt    := 0;         -- サプライヤ・銀行口座割当抽出件数
    gn_out_bnk_use_cnt    := 0;         -- サプライヤ・銀行口座割当出力件数
    gn_get_tax_prf_cnt    := 0;         -- パーティ税金プロファイル抽出件数
    gn_out_tax_prf_cnt    := 0;         -- パーティ税金プロファイル出力件数
    gn_get_bnk_upd_cnt    := 0;         -- 銀行口座更新用抽出件数
    gn_out_bnk_upd_cnt    := 0;         -- 銀行口座更新用出力件数
--
    --
    --===============================================
    -- 初期処理(A-1)
    --===============================================
    init(
      ov_errbuf          => lv_errbuf           -- エラー・メッセージ
    , ov_retcode         => lv_retcode          -- リターン・コード
    , ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --==========================================================================
    -- 「①サプライヤ」連携データの抽出・ファイル出力処理(A-2)
    --==========================================================================
    output_supplier(
      ov_errbuf          => lv_errbuf           -- エラー・メッセージ
    , ov_retcode         => lv_retcode          -- リターン・コード
    , ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --==========================================================================
    -- 「②サプライヤ・住所」連携データの抽出・ファイル出力処理(A-3)
    --==========================================================================
    output_sup_addr(
      ov_errbuf          => lv_errbuf           -- エラー・メッセージ
    , ov_retcode         => lv_retcode          -- リターン・コード
    , ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --==========================================================================
    -- 「③サプライヤ・サイト」連携データの抽出・ファイル出力処理(A-4)
    --==========================================================================
    output_sup_site(
      ov_errbuf          => lv_errbuf           -- エラー・メッセージ
    , ov_retcode         => lv_retcode          -- リターン・コード
    , ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --==========================================================================
    -- 「④サプライヤ・BU割当」連携データの抽出・ファイル出力処理(A-5)
    --==========================================================================
    output_sup_site_ass(
      ov_errbuf          => lv_errbuf           -- エラー・メッセージ
    , ov_retcode         => lv_retcode          -- リターン・コード
    , ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --==========================================================================
    -- 「⑤サプライヤ・担当者」連携データの抽出・ファイル出力処理(A-6)
    --==========================================================================
    output_sup_contact(
      ov_errbuf          => lv_errbuf           -- エラー・メッセージ
    , ov_retcode         => lv_retcode          -- リターン・コード
    , ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --==========================================================================
    -- 「⑥サプライヤ・担当者住所」連携データの抽出・ファイル出力処理(A-7)
    --==========================================================================
    output_sup_contact_addr(
      ov_errbuf          => lv_errbuf           -- エラー・メッセージ
    , ov_retcode         => lv_retcode          -- リターン・コード
    , ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --==========================================================================
    -- 「⑦サプライヤ・支払先」連携データの抽出・ファイル出力処理(A-8)
    --==========================================================================
    output_sup_payee(
      ov_errbuf          => lv_errbuf           -- エラー・メッセージ
    , ov_retcode         => lv_retcode          -- リターン・コード
    , ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --==========================================================================
    -- 「⑧サプライヤ・銀行口座」連携データの抽出・ファイル出力処理(A-9)
    --==========================================================================
    output_sup_bank_acct(
      ov_errbuf          => lv_errbuf           -- エラー・メッセージ
    , ov_retcode         => lv_retcode          -- リターン・コード
    , ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --==========================================================================
    -- 「⑨サプライヤ・銀行口座割当」連携データの抽出・ファイル出力処理(A-10)
    --==========================================================================
    output_sup_bank_use(
      ov_errbuf          => lv_errbuf           -- エラー・メッセージ
    , ov_retcode         => lv_retcode          -- リターン・コード
    , ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --==========================================================================
    -- 「⑩パーティ税金プロファイル」連携データの抽出・ファイル出力処理(A-11)
    --==========================================================================
    output_party_tax_prf(
      ov_errbuf          => lv_errbuf           -- エラー・メッセージ
    , ov_retcode         => lv_retcode          -- リターン・コード
    , ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --==========================================================================
    -- 「⑪銀行口座更新用」データの抽出・ファイル出力処理(A-12)
    --==========================================================================
    output_bank_update(
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
    -- 管理テーブル登録・更新処理(A-13)
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
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    -- エラーの場合
    IF (lv_retcode = cv_status_error) THEN
      --
      -- 各出力件数の初期化（0件）
      gn_out_sup_cnt          := 0;     -- サプライヤ連携データファイル出力件数
      gn_out_sup_addr_cnt     := 0;     -- サプライヤ・住所連携データファイル出力件数
      gn_out_site_cnt         := 0;     -- サプライヤ・サイト連携データファイル出力件数
      gn_out_site_ass_cnt     := 0;     -- サプライヤ・BU割当連携データファイル出力件数
      gn_out_cont_cnt         := 0;     -- サプライヤ・担当者連携データファイル出力件数
      gn_out_cont_addr_cnt    := 0;     -- サプライヤ・担当者住所連携データファイル出力件数
      gn_out_payee_cnt        := 0;     -- サプライヤ・支払先連携データファイル出力件数
      gn_out_bnk_acct_cnt     := 0;     -- サプライヤ・銀行口座連携データファイル出力件数
      gn_out_bnk_use_cnt      := 0;     -- サプライヤ・銀行口座割当連携データファイル出力件数
      gn_out_tax_prf_cnt      := 0;     -- パーティ税金プロファイル連携データファイル出力件数
      gn_out_bnk_upd_cnt      := 0;     -- 銀行口座更新用ファイル出力件数
      --
      -- エラー件数の設定
      gn_error_cnt            := 1;
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
    -- 終了処理(A-14)
    --===============================================
--
    -------------------------------------------------
    -- ファイルクローズ
    -------------------------------------------------
    -- サプライヤ連携データファイル
    IF ( UTL_FILE.IS_OPEN ( gf_sup_file_handle )) THEN
      UTL_FILE.FCLOSE( gf_sup_file_handle );
    END IF;
    -- サプライヤ・住所連携データファイル
    IF ( UTL_FILE.IS_OPEN ( gf_sup_addr_file_handle )) THEN
      UTL_FILE.FCLOSE( gf_sup_addr_file_handle );
    END IF;
    -- サプライヤ・サイト連携データファイル
    IF ( UTL_FILE.IS_OPEN ( gf_site_file_handle )) THEN
      UTL_FILE.FCLOSE( gf_site_file_handle );
    END IF;
    -- サプライヤ・BU割当連携データファイル
    IF ( UTL_FILE.IS_OPEN ( gf_site_ass_file_handle )) THEN
      UTL_FILE.FCLOSE( gf_site_ass_file_handle );
    END IF;
    -- サプライヤ・担当者連携データファイル
    IF ( UTL_FILE.IS_OPEN ( gf_cont_file_handle )) THEN
      UTL_FILE.FCLOSE( gf_cont_file_handle );
    END IF;
    -- サプライヤ・担当者住所連携データファイル
    IF ( UTL_FILE.IS_OPEN ( gf_cont_addr_file_handle )) THEN
      UTL_FILE.FCLOSE( gf_cont_addr_file_handle );
    END IF;
    -- サプライヤ・支払先連携データファイル
    IF ( UTL_FILE.IS_OPEN ( gf_payee_file_handle )) THEN
      UTL_FILE.FCLOSE( gf_payee_file_handle );
    END IF;
    -- サプライヤ・銀行口座連携データファイル
    IF ( UTL_FILE.IS_OPEN ( gf_bnk_acct_file_handle )) THEN
      UTL_FILE.FCLOSE( gf_bnk_acct_file_handle );
    END IF;
    -- サプライヤ・銀行口座割当連携データファイル
    IF ( UTL_FILE.IS_OPEN ( gf_bnk_use_file_handle )) THEN
      UTL_FILE.FCLOSE( gf_bnk_use_file_handle );
    END IF;
    -- パーティ税金プロファイル連携データファイル
    IF ( UTL_FILE.IS_OPEN ( gf_tax_prf_file_handle )) THEN
      UTL_FILE.FCLOSE( gf_tax_prf_file_handle );
    END IF;
    -- 銀行口座更新用ファイル
    IF ( UTL_FILE.IS_OPEN ( gf_bnk_upd_file_handle )) THEN
      UTL_FILE.FCLOSE( gf_bnk_upd_file_handle );
    END IF;
--
    -------------------------------------------------
    -- 抽出件数の出力
    -------------------------------------------------
    -- サプライヤ抽出件数
    l_get_cnt_tab(1).target  := cv_sup_msg;
    l_get_cnt_tab(1).cnt     := TO_CHAR(gn_get_sup_cnt);
    -- サプライヤ・住所抽出件数
    l_get_cnt_tab(2).target  := cv_sup_addr_msg;
    l_get_cnt_tab(2).cnt     := TO_CHAR(gn_get_sup_addr_cnt);
    -- サプライヤ・サイト抽出件数
    l_get_cnt_tab(3).target  := cv_site_msg;
    l_get_cnt_tab(3).cnt     := TO_CHAR(gn_get_site_cnt);
    -- サプライヤ・BU割当抽出件数
    l_get_cnt_tab(4).target  := cv_site_ass_msg;
    l_get_cnt_tab(4).cnt     := TO_CHAR(gn_get_site_ass_cnt);
    -- サプライヤ・担当者抽出件数
    l_get_cnt_tab(5).target  := cv_cont_msg;
    l_get_cnt_tab(5).cnt     := TO_CHAR(gn_get_cont_cnt);
    -- サプライヤ・担当者住所抽出件数
    l_get_cnt_tab(6).target  := cv_cont_addr_msg;
    l_get_cnt_tab(6).cnt     := TO_CHAR(gn_get_cont_addr_cnt);
    -- サプライヤ・支払先抽出件数
    l_get_cnt_tab(7).target  := cv_payee_msg;
    l_get_cnt_tab(7).cnt     := TO_CHAR(gn_get_payee_cnt);
    -- サプライヤ・銀行口座抽出件数
    l_get_cnt_tab(8).target  := cv_bnk_acct_msg;
    l_get_cnt_tab(8).cnt     := TO_CHAR(gn_get_bnk_acct_cnt);
    -- サプライヤ・銀行口座割当抽出件数
    l_get_cnt_tab(9).target  := cv_bnk_use_msg;
    l_get_cnt_tab(9).cnt     := TO_CHAR(gn_get_bnk_use_cnt);
    -- パーティ税金プロファイル抽出件数
    l_get_cnt_tab(10).target := cv_tax_prf_msg;
    l_get_cnt_tab(10).cnt    := TO_CHAR(gn_get_tax_prf_cnt);
    -- 銀行口座更新用抽出件数
    l_get_cnt_tab(11).target := cv_bnk_upd_msg;
    l_get_cnt_tab(11).cnt    := TO_CHAR(gn_get_bnk_upd_cnt);
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
    -- サプライヤ連携データファイル出力件数
    l_out_cnt_tab(1).target  := gt_prf_val_sup_out_file;
    l_out_cnt_tab(1).cnt     := TO_CHAR(gn_out_sup_cnt);
    -- サプライヤ・住所連携データファイル出力件数
    l_out_cnt_tab(2).target  := gt_prf_val_sup_addr_out_file;
    l_out_cnt_tab(2).cnt     := TO_CHAR(gn_out_sup_addr_cnt);
    -- サプライヤ・サイト連携データファイル出力件数
    l_out_cnt_tab(3).target  := gt_prf_val_site_out_file;
    l_out_cnt_tab(3).cnt     := TO_CHAR(gn_out_site_cnt);
    -- サプライヤ・BU割当連携データファイル出力件数
    l_out_cnt_tab(4).target  := gt_prf_val_site_ass_out_file;
    l_out_cnt_tab(4).cnt     := TO_CHAR(gn_out_site_ass_cnt);
    -- サプライヤ・担当者連携データファイル出力件数
    l_out_cnt_tab(5).target  := gt_prf_val_cont_out_file;
    l_out_cnt_tab(5).cnt     := TO_CHAR(gn_out_cont_cnt);
    -- サプライヤ・担当者住所連携データファイル出力件数
    l_out_cnt_tab(6).target  := gt_prf_val_cont_addr_out_file;
    l_out_cnt_tab(6).cnt     := TO_CHAR(gn_out_cont_addr_cnt);
    -- サプライヤ・支払先連携データファイル出力件数
    l_out_cnt_tab(7).target  := gt_prf_val_payee_out_file;
    l_out_cnt_tab(7).cnt     := TO_CHAR(gn_out_payee_cnt);
    -- サプライヤ・銀行口座連携データファイル出力件数
    l_out_cnt_tab(8).target  := gt_prf_val_bnk_acct_out_file;
    l_out_cnt_tab(8).cnt     := TO_CHAR(gn_out_bnk_acct_cnt);
    -- サプライヤ・銀行口座割当連携データファイル出力件数
    l_out_cnt_tab(9).target  := gt_prf_val_bnk_use_out_file;
    l_out_cnt_tab(9).cnt     := TO_CHAR(gn_out_bnk_use_cnt);
    -- パーティ税金プロファイル連携データファイル出力件数
    l_out_cnt_tab(10).target := gt_prf_val_tax_prf_out_file;
    l_out_cnt_tab(10).cnt    := TO_CHAR(gn_out_tax_prf_cnt);
    -- 銀行口座更新用ファイル出力件数
    l_out_cnt_tab(11).target := gt_prf_val_bnk_upd_out_file;
    l_out_cnt_tab(11).cnt    := TO_CHAR(gn_out_bnk_upd_cnt);
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
    gn_target_cnt := gn_get_sup_cnt +
                     gn_get_sup_addr_cnt +
                     gn_get_site_cnt +
                     gn_get_site_ass_cnt +
                     gn_get_cont_cnt +
                     gn_get_cont_addr_cnt +
                     gn_get_payee_cnt +
                     gn_get_bnk_acct_cnt +
                     gn_get_bnk_use_cnt +
                     gn_get_tax_prf_cnt +
                     gn_get_bnk_upd_cnt;
    --
    -- 成功件数（出力件数の合計）を設定
    gn_normal_cnt := gn_out_sup_cnt +
                     gn_out_sup_addr_cnt +
                     gn_out_site_cnt +
                     gn_out_site_ass_cnt +
                     gn_out_cont_cnt +
                     gn_out_cont_addr_cnt +
                     gn_out_payee_cnt +
                     gn_out_bnk_acct_cnt +
                     gn_out_bnk_use_cnt +
                     gn_out_tax_prf_cnt +
                     gn_out_bnk_upd_cnt;
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
END XXCMM001A02C;
/
