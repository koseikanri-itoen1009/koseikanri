CREATE OR REPLACE PACKAGE BODY APPS.XXCSM002A17C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2019. All rights reserved.
 *
 * Package Name     : XXCSM002A17C(body)
 * Description      : CSVデータアップロード（年間商品計画）
 * MD.050           : MD050_CSM_002_A17_CSVデータアップロード（年間商品計画）
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_upload_data        ファイルアップロードIF取得(A-2)
 *  del_upload_data        アップロードデータ削除処理(A-3)
 *  split_plan_data        年間商品計画データの項目分割処理(A-4)
 *  item_check             項目チェック(A-5)
 *  ins_plan_tmp           商品計画アップロードワーク登録処理(A-6)
 *  chk_base_code          拠点コード、年度チェック処理(A-8)
 *  chk_record_kind        レコード区分チェック処理(A-9)
 *  chk_master_data        商品群マスタチェック処理(A-10)
 *  chk_budget_value       予算値チェック
 *  chk_budget_item        予算項目チェック処理(A-11)
 *  ins_plan_headers       商品計画ヘッダ登録処理(A-12)
 *  ins_plan_loc_bdgt      拠点予算登録・更新処理(A-13)
 *  calc_budget_item       商品群予算値算出
 *  calc_budget_new_item   新商品予算値算出
 *  ins_plan_line          商品群予算登録・更新処理(A-14)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                         終了処理(A-15)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2019/02/08    1.0   N.Koyama          main新規作成
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
  global_proc_date_err_expt         EXCEPTION;    -- 業務日付取得例外ハンドラ
  global_get_profile_expt           EXCEPTION;    -- プロファイル取得例外ハンドラ
  global_get_org_id_expt            EXCEPTION;    -- 在庫組織ID取得例外ハンドラ
  global_get_file_id_lock_expt      EXCEPTION;    -- ファイルIDの取得ハンドラ
  global_get_file_id_data_expt      EXCEPTION;    -- ファイルIDの取得ハンドラ
  global_get_f_uplod_name_expt      EXCEPTION;    -- ファイルアップロード名称の取得ハンドラ
  global_get_f_csv_name_expt        EXCEPTION;    -- CSVファイル名の取得ハンドラ
  global_item_check_expt            EXCEPTION;    -- 項目チェックハンドラ
  global_del_ul_interface_expt      EXCEPTION;    -- レコード削除例外ハンドラ
--
  global_data_lock_expt             EXCEPTION;    -- データロック例外
  PRAGMA EXCEPTION_INIT( global_data_lock_expt, -54 );
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  --プログラム名称
  cv_pkg_name                       CONSTANT VARCHAR2(100) := 'XXCSM002A17C';   --パッケージ名
  --アプリケーション短縮名
  cv_xxcsm_appl_short_name          CONSTANT VARCHAR2(100) := 'XXCSM';          --経営短縮アプリ名
  cv_xxccp_appl_short_name          CONSTANT VARCHAR2(100) := 'XXCCP';          --共通
--
  --メッセージ
  cv_msg_plan_year_err              CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-00004';    --予算年度チェックエラー
  cv_msg_profile_err                CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-00005';    --プロファイル取得エラー
  cv_msg_not_exist_calendar         CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-00006';    --年間販売計画カレンダー未存在エラー
  cv_msg_user_base_code             CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-00059';    --ログインユーザー在籍拠点取得エラー
  cv_msg_new_item_err               CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10138';    --新商品コード取得エラー
  --
  cv_msg_no_plan_kind_err           CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10200';    --拠点予算、商品群予算無しエラー
  cv_msg_base_code                  CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10201';    --拠点コード
  cv_msg_year                       CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10202';    --年度
  cv_msg_plan_kind                  CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10203';    --予算区分
  cv_msg_record_kind                CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10204';    --レコード区分
  cv_msg_sales_budget               CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10205';    --売上予算
  cv_msg_receipt_discount           CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10206';    --入金値引
  cv_msg_sales_discount             CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10207';    --売上値引
  cv_msg_item_sales_budget          CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10208';    --売上
  cv_msg_amount_gross_margin        CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10209';    --粗利額
  cv_msg_margin_rate                CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10210';    --粗利率
  cv_msg_base_total                 CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10211';    --拠点計
  cv_msg_add_err                    CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10212';    --テーブル登録エラー
  cv_msg_tmp_tbl                    CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10213';    --商品計画アップロードワークテーブル
  cv_msg_upload_name_get            CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10215';    --ファイルアップロード名称取得エラー
  cv_msg_security_err               CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10216';    --指定拠点エラー
  cv_msg_extract_err                CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10217';    --データ抽出エラー
  cv_msg_master_err                 CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10218';    --商品群マスタエラー
  cv_msg_no_found_rec_kubun         CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10219';    --レコード区分無しエラー
  cv_msg_too_many_rec_kubun         CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10220';    --レコード区分複数エラー
  cv_msg_fail_rec_kubun             CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10221';    --レコード区分誤り
  cv_msg_sales_budget_err           CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10222';    --売上指定エラー
  cv_msg_decimal_point_err          CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10223';    --小数点以下指定エラー
  cv_msg_disconut_item_err          CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10224';    --値引項目指定エラー
  cv_msg_multi_designation_err      CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10225';    --粗利額、粗利率複数指定エラー
  cv_msg_file_up_load               CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10226';    --ファイルアップロードIF
  cv_msg_item_group_calc_err        CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10227';    --商品群予算値算出エラー
  cv_msg_get_f_csv_name             CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10228';    --CSVファイル名取得エラー
  cv_msg_get_rep_h1                 CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10229';    --フォーマットパターン
  cv_msg_get_rep_h2                 CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10230';    --CSVファイル名
  cv_msg_process_date_err           CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10231';    --業務日付取得エラー
  cv_msg_delete_data_err            CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10232';    --データ削除エラー
  cv_msg_get_data_err               CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10233';    --データ抽出エラー
  cv_msg_get_lock_err               CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10234';    --ロックエラー
  cv_msg_chk_rec_err                CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10235';    --ファイルレコード不一致エラー
  cv_msg_value_over_err             CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10236';    --許容範囲エラー
  cv_msg_item_plan_loc_bdgt         CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10237';    --商品計画拠点別予算テーブル
  cv_msg_item_plan_lines            CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10238';    --商品計画明細テーブル
  cv_msg_null_err                   CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10239';    --未指定エラー
  --
  cv_msg_get_format_err             CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10302';    --項目不備エラー
  cv_msg_no_upload_date             CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10305';    --アップロード処理対象なしエラー
  cv_msg_multi_base_code_err        CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10307';    --複数拠点エラー
  cv_msg_budget_year_err            CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10308';    --指定予算年度エラー
  cv_msg_multi_year_err             CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10309';    --複数予算年度エラー
  cv_msg_discrete_cost_err          CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10315';    --営業原価取得エラー
  cv_msg_fixed_price_err            CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10316';    --定価取得エラー
  cv_msg_new_item_calc_err          CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10326';    --新商品予算値算出エラー
  --トークン
  cv_tkn_file_id                    CONSTANT VARCHAR2(20)  := 'FILE_ID ';            --ファイルID
  cv_tkn_profile                    CONSTANT VARCHAR2(20)  := 'PROFILE';             --プロファイル名
  cv_tkn_org_code                   CONSTANT VARCHAR2(20)  := 'ORG_CODE_TOK';        --在庫組織コード
  cv_tkn_table                      CONSTANT VARCHAR2(20)  := 'TABLE';               --テーブル名
  cv_tkn_key_data                   CONSTANT VARCHAR2(20)  := 'KEY_DATA';            --キー情報
  cv_tkn_table_name                 CONSTANT VARCHAR2(20)  := 'TABLE_NAME';          --テーブル名
  cv_tkn_data                       CONSTANT VARCHAR2(20)  := 'DATA';                --レコードデータ
  cv_tkn_param1                     CONSTANT VARCHAR2(20)  := 'PARAM1';              --パラメータ1
  cv_tkn_param2                     CONSTANT VARCHAR2(20)  := 'PARAM2';              --パラメータ2
  cv_tkn_param3                     CONSTANT VARCHAR2(20)  := 'PARAM3';              --パラメータ3
  cv_tkn_param4                     CONSTANT VARCHAR2(20)  := 'PARAM4';              --パラメータ4
  cv_tkn_column                     CONSTANT VARCHAR2(20)  := 'COLUMN';              --項目名
  cv_tkn_base_code                  CONSTANT VARCHAR2(20)  := 'BASE_CODE';           --拠点
  cv_tkn_year                       CONSTANT VARCHAR2(20)  := 'YEAR';                --年度
  cv_tkn_item                       CONSTANT VARCHAR2(20)  := 'ITEM';                --項目
  cv_tkn_plan_kind                  CONSTANT VARCHAR2(20)  := 'PLAN_KIND';           --予算区分
  cv_tkn_record_kind                CONSTANT VARCHAR2(20)  := 'RECORD_KIND';         --レコード区分
  cv_tkn_month                      CONSTANT VARCHAR2(20)  := 'MONTH';               --月
  cv_tkn_prof_name                  CONSTANT VARCHAR2(20)  := 'PROF_NAME';           --プロファイル名
  cv_tkn_yosan_nendo                CONSTANT VARCHAR2(20)  := 'YOSAN_NENDO';         --予算年度
  cv_tkn_deal_cd                    CONSTANT VARCHAR2(20)  := 'DEAL_CD';             --商品群
  cv_tkn_errmsg                     CONSTANT VARCHAR2(20)  := 'ERRMSG';              --エラー内容詳細
  cv_tkn_item_cd                    CONSTANT VARCHAR2(20)  := 'ITEM_CD';             --商品コード
  cv_tkn_min                        CONSTANT VARCHAR2(20)  := 'MIN';                 --最小値
  cv_tkn_max                        CONSTANT VARCHAR2(20)  := 'MAX';                 --最大値
  cv_tkn_value                      CONSTANT VARCHAR2(20)  := 'VALUE';               --値
  cv_tkn_user_id                    CONSTANT VARCHAR2(20)  := 'USER_ID';             --ユーザID
  cv_tkn_row_num                    CONSTANT VARCHAR2(20)  := 'ROW_NUM';             --エラー行
--
  --プロファイルオプション名
  cv_prof_yearplan_calender         CONSTANT VARCHAR2(30)  := 'XXCSM1_YEARPLAN_CALENDER';  -- XXCSM:年間販売計画カレンダー名
  cv_xxcsm1_dummy_dept_ref          CONSTANT VARCHAR2(30)  := 'XXCSM1_DUMMY_DEPT_REF';     -- XXCSM:ダミー部門階層参照
  cv_gl_set_of_bks_id_nm            CONSTANT VARCHAR2(30)  := 'GL_SET_OF_BKS_ID';          -- GL会計帳簿ID
--
  --クイックコード
  cv_look_file_upload_obj           CONSTANT VARCHAR2(50)  := 'XXCCP1_FILE_UPLOAD_OBJ';    --ファイルアップロードオブジェクト
  cv_look_dummy_dept                CONSTANT VARCHAR2(50)  := 'XXCSM1_DUMMY_DEPT';         --ダミー部門階層参照
--
  cv_comma                          CONSTANT VARCHAR2(1)   := ',';         --区切り文字
  cv_dobule_quote                   CONSTANT VARCHAR2(1)   := '"';         --括り文字
  cv_line_feed                      CONSTANT VARCHAR2(1)   := CHR(10);     --改行コード
  cn_c_header                       CONSTANT NUMBER        := 17;          --ファイル項目数
  cn_begin_line                     CONSTANT NUMBER        := 2;           --最初の行
  cn_line_zero                      CONSTANT NUMBER        := 0;           --0行
  cn_item_header                    CONSTANT NUMBER        := 1;           --項目名
  cv_msg_comma                      CONSTANT VARCHAR2(2)   := '、';        --メッセージ用区切り文字
  ct_user_lang                      CONSTANT fnd_lookup_values.language%TYPE := USERENV( 'LANG' );
  cn_gl_set_of_bks_id               CONSTANT NUMBER        := FND_PROFILE.VALUE( cv_gl_set_of_bks_id_nm );         -- 会計帳簿ID
--
  --CSVレイアウト（レイアウト順序を定義）
  cn_base_code                      CONSTANT NUMBER        := 1;           --拠点コード
  cn_plan_year                      CONSTANT NUMBER        := 2;           --年度
  cn_plan_kind                      CONSTANT NUMBER        := 3;           --予算区分
  cn_record_kind                    CONSTANT NUMBER        := 4;           --レコード区分
  cn_may                            CONSTANT NUMBER        := 5;           --5月予算
  cn_jun                            CONSTANT NUMBER        := 6;           --6月予算
  cn_jul                            CONSTANT NUMBER        := 7;           --7月予算
  cn_aug                            CONSTANT NUMBER        := 8;           --8月予算
  cn_sep                            CONSTANT NUMBER        := 9;           --9月予算
  cn_oct                            CONSTANT NUMBER        := 10;          --10月予算
  cn_nov                            CONSTANT NUMBER        := 11;          --11月予算
  cn_dec                            CONSTANT NUMBER        := 12;          --12月予算
  cn_jan                            CONSTANT NUMBER        := 13;          --1月予算
  cn_feb                            CONSTANT NUMBER        := 14;          --2月予算
  cn_mar                            CONSTANT NUMBER        := 15;          --3月予算
  cn_apr                            CONSTANT NUMBER        := 16;          --4月予算
  cn_sum                            CONSTANT NUMBER        := 17;          --年間計
--
  --項目長（各項目の項目長を定義）
  cn_base_code_length               CONSTANT NUMBER        := 4;           --拠点コード
  cn_plan_year_length               CONSTANT NUMBER        := 4;           --年度
  cn_plan_year_point                CONSTANT NUMBER        := 0;           --年度（小数点以下）
  cn_plan_kind_length               CONSTANT NUMBER        := 6;           --予算区分
  cn_rec_kind_length                CONSTANT NUMBER        := 8;           --レコード区分
  cn_budget_length                  CONSTANT NUMBER        := 14;          --全体（整数+小数）の最大桁
  cn_budget_point                   CONSTANT NUMBER        := 2;           --小数の最大桁
  --範囲チェック用
  cn_min_discount                   CONSTANT NUMBER       := -99999999;      --値引項目最小値
  cn_max_discount                   CONSTANT NUMBER       := 0;              --値引項目最大値
  cn_min_gross                      CONSTANT NUMBER       := -99999999999;   --粗利額最小値
  cn_max_gross                      CONSTANT NUMBER       := 999999999999;   --粗利額最大値
  cn_min_rate                       CONSTANT NUMBER       := -999.99;        --粗利率最小率
  cn_max_rate                       CONSTANT NUMBER       := 9999.99;        --粗利率最大率
  --
  -- 商品販売計画商品区分
  cv_item_kbn_group                CONSTANT VARCHAR2(1)   := '0';            -- 0:商品群
  cv_item_kbn_tanpin               CONSTANT VARCHAR2(1)   := '1';            -- 1:単品
  cv_item_kbn_new                  CONSTANT VARCHAR2(1)   := '2';            -- 2:新商品
  -- 年間群予算区分
  cv_budget_kbn_month              CONSTANT VARCHAR2(1)   := '0';            -- 0:各月単位予算
  cv_budget_kbn_year               CONSTANT VARCHAR2(1)   := '1';            -- 1:年間群予算
  --
  --商品計画明細.月
  cn_month_no_1                    CONSTANT NUMBER        := 1;           --1月
  cn_month_no_2                    CONSTANT NUMBER        := 2;           --1月
  cn_month_no_3                    CONSTANT NUMBER        := 3;           --1月
  cn_month_no_4                    CONSTANT NUMBER        := 4;           --1月
  cn_month_no_5                    CONSTANT NUMBER        := 5;           --5月
  cn_month_no_6                    CONSTANT NUMBER        := 6;           --6月
  cn_month_no_7                    CONSTANT NUMBER        := 7;           --7月
  cn_month_no_8                    CONSTANT NUMBER        := 8;           --8月
  cn_month_no_9                    CONSTANT NUMBER        := 9;           --9月
  cn_month_no_10                   CONSTANT NUMBER        := 10;          --10月
  cn_month_no_11                   CONSTANT NUMBER        := 11;          --11月
  cn_month_no_12                   CONSTANT NUMBER        := 12;          --12月
  cn_month_no_99                   CONSTANT NUMBER        := 99;          -- 年間計の月
  --
  cv_sum                           CONSTANT VARCHAR2(10)  := '年間計';    -- 年間計
  cv_sum_kyoten                    CONSTANT VARCHAR2(10)  := '拠点計';    -- 拠点計
  cv_item_group                    CONSTANT VARCHAR2(10)  := '商品群';    -- 商品群
  --日付フォーマット
  cv_fmt_std                        CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';
  cv_fmt_hh24miss                   CONSTANT VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS';
  cv_fmt_mm                         CONSTANT VARCHAR2(2)  := 'MM';
--
  cv_no                             CONSTANT VARCHAR2(1)  := 'N';
  cv_yes                            CONSTANT VARCHAR2(1)  := 'Y';
  cv_status_check                   CONSTANT VARCHAR2(1)  := '9';            --チェックエラー:9
  cv_blank                          CONSTANT VARCHAR2(1)  := ' ';            --半角スペース
--
  --項目チェック＆メッセージ出力用の項目名称用変数
  gv_base_code                      VARCHAR2(200);                           --拠点コード
  gv_yaer                           VARCHAR2(200);                           --年度
  gv_plan_kind                      VARCHAR2(200);                           --予算区分
  gv_record_kind                    VARCHAR2(200);                           --レコード区分
  gv_sales_budget                   VARCHAR2(200);                           --売上予算
  gv_receipt_discount               VARCHAR2(200);                           --入金値引
  gv_sales_discount                 VARCHAR2(200);                           --売上値引
  gv_item_sales_budget              VARCHAR2(200);                           --売上
  gv_amount_gross_margin            VARCHAR2(200);                           --粗利額
  gv_margin_rate                    VARCHAR2(200);                           --粗利率
  gv_loc_bdgt                       VARCHAR2(200);                           --拠点計
  gv_tkn1                           VARCHAR2(200);                           --任意用
  gv_chk_base_code                  VARCHAR2(200);                           --同一拠点チェック用
  gv_chk_year                       VARCHAR2(200);                           --同一年度チェック用
  gv_user_base                      VARCHAR2(200);                           --実行ユーザー拠点
  gv_employee_code                  VARCHAR2(200);                           --実行ユーザー従業員
  gv_no_flv_tag                     VARCHAR2(200);                           --セキュリティ判定
  gv_sec_retcode                    VARCHAR2(1);                             --セキュリティ判定ステータス保持
  gv_before_plan_kind               VARCHAR2(200);                           --前レコード予算区分
  gv_before_record_kind             VARCHAR2(200);                           --前レコードレコード区分
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  --年間商品計画データ BLOB型
  gt_plan_data                      xxccp_common_pkg2.g_file_data_tbl;
--
  TYPE gt_var_data1                 IS TABLE OF VARCHAR(32767) INDEX BY BINARY_INTEGER;        --1次元配列
  TYPE gt_var_data2                 IS TABLE OF gt_var_data1 INDEX BY BINARY_INTEGER;          --2次元配列
  gr_plan_work_data                 gt_var_data2;                                              --分活用変数
--
  TYPE g_tab_plan_header_rec        IS TABLE OF xxcsm_item_plan_headers%ROWTYPE   INDEX BY PLS_INTEGER;  --商品計画ヘッダテーブル
  TYPE g_tab_plan_loc_rec           IS TABLE OF xxcsm_item_plan_loc_bdgt%ROWTYPE  INDEX BY PLS_INTEGER;  --商品計画拠点別予算テーブル
  TYPE g_tab_plan_line_rec          IS TABLE OF xxcsm_item_plan_lines%ROWTYPE     INDEX BY PLS_INTEGER;  --商品計画明細テーブル
--
  gr_plan_header_data1              g_tab_plan_header_rec;          --商品計画ヘッダ
  gr_plan_loc_data1                 g_tab_plan_loc_rec;             --商品計画拠点別予算
  gr_plan_line_data2                g_tab_plan_line_rec;            --商品計画明細
--
  --==================================================
  -- ユーザー定義グローバルカーソル
  --==================================================
--
    -- 年間商品計画一時表取得カーソル
    CURSOR get_plan_tmp_cur
    IS
      SELECT  xpt.record_id         AS record_id    -- 01:レコードNo.
             ,xpt.base_code         AS base_code    -- 02:拠点コード
             ,xpt.plan_year         AS plan_year    -- 03:年度
             ,xpt.plan_kind         AS plan_kind    -- 04:予算区分
             ,xpt.record_kind       AS record_kind  -- 05:レコード区分
             ,xpt.plan_may          AS plan_may     -- 06:5月予算
             ,xpt.plan_jun          AS plan_jun     -- 07:6月予算
             ,xpt.plan_jul          AS plan_jul     -- 08:7月予算
             ,xpt.plan_aug          AS plan_aug     -- 09:8月予算
             ,xpt.plan_sep          AS plan_sep     -- 10:9月予算
             ,xpt.plan_oct          AS plan_oct     -- 11:10月予算
             ,xpt.plan_nov          AS plan_nov     -- 12:11月予算
             ,xpt.plan_dec          AS plan_dec     -- 13:12月予算
             ,xpt.plan_jan          AS plan_jan     -- 14:1月予算
             ,xpt.plan_feb          AS plan_feb     -- 15:2月予算
             ,xpt.plan_mar          AS plan_mar     -- 16:3月予算
             ,xpt.plan_apr          AS plan_apr     -- 17:4月予算
             ,xpt.plan_sum          AS plan_sum     -- 18:商品群年間予算
       FROM   xxcsm_plan_tmp xpt
--    ORDER BY  xpt.base_code
--             ,xpt.plan_year
    ORDER BY  decode(xpt.plan_kind,gv_loc_bdgt,'0',xpt.plan_kind)
             ,decode(xpt.record_kind,gv_sales_discount,1
                                    ,gv_receipt_discount,2
                                    ,gv_sales_budget,3
                                    ,gv_item_sales_budget,4
                                    ,gv_amount_gross_margin,5
                                    ,gv_margin_rate,6
                                    ,7)
    ;
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- *** グローバルテーブル ***
  TYPE gr_plan_tmp_ttype IS TABLE OF get_plan_tmp_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  -- *** グローバル配列 ***
  gr_plan_tmps_tab gr_plan_tmp_ttype;
  --
  gv_upload_file_name                       VARCHAR2(128);                                      --ファイルアップロード名称
  gv_csv_file_name                          VARCHAR2(256);                                      --CSVファイル名
  gd_process_date                           DATE;                                               --業務日付
  gt_file_id                                xxccp_mrp_file_ul_interface.file_id%TYPE;           --ファイルID
  gt_item_plan_header_id                    xxcsm_item_plan_headers.item_plan_header_id%TYPE;   --商品計画ヘッダID
--
  --金額合計用
  gt_sale_amount_sum                        xxcos_sales_exp_headers.sale_amount_sum%TYPE;       --売上金額合計
  gt_pure_amount_sum                        xxcos_sales_exp_headers.pure_amount_sum%TYPE;       --本体金額合計
  gt_tax_amount_sum                         xxcos_sales_exp_headers.tax_amount_sum%TYPE;        --消費税金額合計
--
  --プロファイル値格納用
  gv_prof_yearplan_calender                 VARCHAR2(100);  --XXCSM:年間販売計画カレンダー名
  gv_dummy_dept_ref                         VARCHAR2(1);    --XXCSM:ダミー部門階層参照
  gn_gl_set_of_bks_id                       NUMBER;         --会計帳簿ID
--
  --カウンタ他制御用
  gt_plan_year                              xxcsm_item_plan_headers.plan_year%TYPE;    -- 予算年度
  gd_start_date                             DATE;
  gn_get_counter_data                       NUMBER;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     iv_get_format     IN  VARCHAR2  -- 入力フォーマットパターン
    ,in_file_id        IN  NUMBER    -- ファイルID
    ,ov_errbuf         OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
    ,ov_retcode        OUT VARCHAR2  -- リターン・コード             --# 固定 #
    ,ov_errmsg         OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    lv_key_info      VARCHAR2(5000);  --key情報
    lv_max_date      VARCHAR2(5000);  --MAX日付
    lv_tab_name      VARCHAR2(500);   --テーブル名
    lv_status        VARCHAR2(1);     --共通関数ステータス
    lv_out_msg       VARCHAR2(2000);  -- メッセージ
    ln_count         NUMBER;
--
    -- *** ローカル・カーソル ***
    CURSOR get_login_base_cur
    IS
      SELECT lbi.base_code   AS base_code
        FROM xxcos_login_base_info_v lbi   --ログインユーザ拠点ビュー
      ;
--
    -- 会計カレンダから当年度の月を取得
    CURSOR cur_get_month_this_year
    IS 
    SELECT   glpds.start_date                                   AS start_date  -- 年度開始日
    FROM     gl_periods        glpds,                                          -- 会計カレンダテーブル
             gl_sets_of_books  glsob                                           -- 会計帳簿マスタ
    WHERE    glsob.set_of_books_id        = cn_gl_set_of_bks_id                -- 会計帳簿ID
    AND      glpds.period_set_name        = glsob.period_set_name              -- カレンダ名
    AND      glpds.period_year            = gt_plan_year                       -- 予算年度
    AND      glpds.adjustment_period_flag = cv_no                              -- 調整会計期間外
    AND      glpds.period_num             = 1;                                 -- 年度開始月
--
    rec_get_month_this_year cur_get_month_this_year%ROWTYPE;
    -- 会計カレンダから昨年度の月を取得
    CURSOR cur_get_month_last_year
    IS
    SELECT   glpds.start_date                                   AS start_date  -- 年度開始日
    FROM     gl_periods        glpds,                                          -- 会計カレンダテーブル
             gl_sets_of_books  glsob                                           -- 会計帳簿マスタ
    WHERE    glsob.set_of_books_id        = cn_gl_set_of_bks_id                -- 会計帳簿ID
    AND      glpds.period_set_name        = glsob.period_set_name              -- カレンダ名
    AND      glpds.period_year            = gt_plan_year - 1                   -- 予算年度
    AND      glpds.adjustment_period_flag = cv_no                              -- 調整会計期間外
    AND      glpds.period_num             = 1;                                 -- 年度開始月
--
    rec_get_month_last_year cur_get_month_last_year%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
--  ************************************************
    -- 1.パラメータ出力
--  ************************************************
    --コンカレントプログラム入力項目の出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                   iv_application   => cv_xxcsm_appl_short_name
                  ,iv_name          => cv_msg_get_rep_h1
                  ,iv_token_name1   => cv_tkn_param1                 --パラメータ１
                  ,iv_token_value1  => in_file_id                    --ファイルID
                  ,iv_token_name2   => cv_tkn_param2                 --パラメータ２
                  ,iv_token_value2  => iv_get_format                 --フォーマットパターン
                 );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
--  ************************************************
    -- 2.業務日付取得
--  ************************************************
--
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- 業務日付が取得できない場合
    IF ( gd_process_date IS NULL ) THEN
      RAISE global_proc_date_err_expt;
    END IF;
--
--  ************************************************
    --3.ファイルアップロード名称・ファイル名出力
--  ************************************************
    ------------------------------------
    --3-1.ファイルアップロード名称取得
    ------------------------------------
    BEGIN
      SELECT flv.meaning    AS upload_file_name
        INTO gv_upload_file_name
        FROM fnd_lookup_types  flt    --クイックタイプ
            ,fnd_application   fa     --アプリケーション
            ,fnd_lookup_values flv    --クイックコード
       WHERE flt.lookup_type            = flv.lookup_type
         AND fa.application_short_name  = cv_xxccp_appl_short_name
         AND flt.application_id         = fa.application_id
         AND flt.lookup_type            = cv_look_file_upload_obj
         AND flv.lookup_code            = iv_get_format
         AND flv.language               = ct_user_lang
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE global_get_f_uplod_name_expt;
    END;
--
    ------------------------------------
    -- 3-2.CSVファイル名取得＆ロック取得
    ------------------------------------
    BEGIN
      SELECT xmf.file_name  AS csv_file_name
        INTO gv_csv_file_name
        FROM xxccp_mrp_file_ul_interface xmf  --ファイルアップロードIF
       WHERE xmf.file_id = in_file_id
       FOR UPDATE NOWAIT
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE global_get_f_csv_name_expt;
      --*** ロック取得エラーハンドラ ***
      WHEN global_data_lock_expt THEN
        --キー情報の編集処理
        lv_tab_name := xxccp_common_pkg.get_msg(
                                 iv_application => cv_xxcsm_appl_short_name
                                ,iv_name        => cv_msg_file_up_load
                               );
        RAISE global_data_lock_expt;
    END;
--
    --アップロードファイル名の出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                   iv_application   => cv_xxcsm_appl_short_name
                  ,iv_name          => cv_msg_get_rep_h2
                  ,iv_token_name1   => cv_tkn_param3                 --ファイルアップロード名称(メッセージ文字列)
                  ,iv_token_value1  => gv_upload_file_name           --ファイルアップロード名称
                  ,iv_token_name2   => cv_tkn_param4                 --CSVファイル名(メッセージ文字列)
                  ,iv_token_value2  => gv_csv_file_name              --CSVファイル名
                 );
    --
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --1行空白
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => NULL
    );
--
--  ************************************************
    -- 4.プロファイル値取得  ***
--  ************************************************
--
    ------------------------------------
    -- 4-1.XXCSM:年間販売計画カレンダー名
    ------------------------------------
    gv_prof_yearplan_calender := FND_PROFILE.VALUE(cv_prof_yearplan_calender);
    IF( gv_prof_yearplan_calender IS NULL ) THEN
      lv_out_msg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_xxcsm_appl_short_name
                     ,iv_name                 => cv_msg_profile_err
                     ,iv_token_name1          => cv_tkn_prof_name
                     ,iv_token_value1         => cv_prof_yearplan_calender
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000)
      );
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
    END IF;
--
    ------------------------------------
    -- 4-2.XXCSM:ダミー部門階層参照
    ------------------------------------
    gv_dummy_dept_ref := FND_PROFILE.VALUE( cv_xxcsm1_dummy_dept_ref );
    IF( gv_dummy_dept_ref IS NULL ) THEN
      lv_out_msg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_xxcsm_appl_short_name
                     ,iv_name                 => cv_msg_profile_err
                     ,iv_token_name1          => cv_tkn_prof_name
                     ,iv_token_value1         => cv_xxcsm1_dummy_dept_ref
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000)
      );
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
    END IF;
--
    ------------------------------------
    -- 4-3.GL会計帳簿ID
    ------------------------------------
    gn_gl_set_of_bks_id         := FND_PROFILE.VALUE( cv_gl_set_of_bks_id_nm );
    IF( gn_gl_set_of_bks_id IS NULL ) THEN
      lv_out_msg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_xxcsm_appl_short_name
                     ,iv_name                 => cv_msg_profile_err
                     ,iv_token_name1          => cv_tkn_prof_name
                     ,iv_token_value1         => cv_gl_set_of_bks_id_nm
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000)
      );
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
    END IF;
--
--  ************************************************
    -- 5.年間販売計画カレンダ存在チェック
--  ************************************************
    SELECT COUNT(*)  AS cnt
    INTO   ln_count
    FROM   fnd_flex_value_sets ffvs
    WHERE  flex_value_set_name = gv_prof_yearplan_calender
    ;
    -- カレンダ定義が存在しない場合
    IF (ln_count = 0) THEN
      lv_out_msg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_xxcsm_appl_short_name
                     ,iv_name                 => cv_msg_not_exist_calendar
                     ,iv_token_name1          => cv_tkn_item
                     ,iv_token_value1         => gv_prof_yearplan_calender
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000)
      );
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
    END IF;
    --
--  ************************************************
    -- 6.予算年度取得
--  ************************************************
    xxcsm_common_pkg.get_yearplan_calender(
      id_comparison_date => gd_process_date        -- 運用日
     ,ov_status          => lv_status              -- 処理結果(0：正常、1：異常)
     ,on_active_year     => gt_plan_year           -- 取得した予算年度
     ,ov_retcode         => lv_retcode             -- リターンコード
     ,ov_errbuf          => lv_errbuf              -- エラーメッセージ
     ,ov_errmsg          => lv_errmsg              -- ユーザー・エラーメッセージ
    );
    -- 予算年度が存在しない場合
    IF ( lv_status <> cv_status_normal ) THEN
      lv_out_msg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_xxcsm_appl_short_name
                     ,iv_name                 => cv_msg_plan_year_err
                     ,iv_token_name1          => cv_tkn_item
                     ,iv_token_value1         => gv_prof_yearplan_calender
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000)
      );
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
    END IF;
    --
--  ************************************************
    -- 7.実行ユーザーの拠点取得
--  ************************************************
    -- 初期化
    lv_retcode    := NULL;  -- リターンコード
    lv_errbuf     := NULL;  -- エラーメッセージ
    lv_errmsg     := NULL;  -- ユーザー・エラーメッセージ
    xxcsm_common_pkg.get_login_user_foothold(
       in_user_id         => fnd_global.user_id          -- ユーザーID
      ,ov_foothold_code   => gv_user_base                -- 拠点コード
      ,ov_employee_code   => gv_employee_code            -- 従業員コード
      ,ov_retcode         => lv_retcode                  -- リターンコード
      ,ov_errbuf          => lv_errbuf                   -- エラーメッセージ
      ,ov_errmsg          => lv_errmsg                   -- ユーザー・エラーメッセージ
    );
    -- ログインユーザー在籍拠点が存在しない場合
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_out_msg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_xxcsm_appl_short_name
                     ,iv_name                 => cv_msg_user_base_code
                     ,iv_token_name1          => cv_tkn_user_id
                     ,iv_token_value1         => fnd_global.user_id
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg
      );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000)
      );
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
    END IF;
    --
    IF ov_retcode = cv_status_error THEN
      RETURN;
    END IF;
    --
    --===============================================
    -- 8.営業企画部、地域営業管理部、情報管理部判定処理
    --===============================================
    -- 初期化
    gv_sec_retcode    := NULL;  -- リターンコード
    lv_errbuf         := NULL;  -- エラーメッセージ
    lv_errmsg         := NULL;  -- ユーザー・エラーメッセージ
    --
    xxcsm_common_pkg.year_item_plan_security(
       in_user_id          => fnd_global.user_id            --ユーザID
      ,ov_lv6_kyoten_list  => gv_no_flv_tag                 --セキュリティ戻り値
      ,ov_retcode          => gv_sec_retcode                --リターンコード
      ,ov_errbuf           => lv_errbuf                     --エラーメッセージ
      ,ov_errmsg           => lv_errmsg                     --ユーザー・エラーメッセージ
    );
    --画面に合わせエラー判定はしない
    --
--  ************************************************
    -- 9.年度開始日取得
--  ************************************************
    -- 初期化
    gd_start_date := NULL;
    -- 年度開始日を取得
    OPEN cur_get_month_this_year;
    FETCH cur_get_month_this_year INTO rec_get_month_this_year;
    CLOSE cur_get_month_this_year;
    -- 年度開始日をセット
    gd_start_date := rec_get_month_this_year.start_date;
    --
    -- 会計カレンダに翌年度の会計期間が定義されていなかった場合
    IF (gd_start_date IS NULL) THEN
      -- 年度開始日を取得
      OPEN cur_get_month_last_year;
      FETCH cur_get_month_last_year INTO rec_get_month_last_year;
      CLOSE cur_get_month_last_year;
      -- 年度開始日をセット
      gd_start_date := rec_get_month_last_year.start_date;
    END IF;
--
--  ************************************************
    -- 10.項目チェック＆メッセージ出力用の項目名称取得
--  ************************************************
      --拠点コード
      gv_base_code := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcsm_appl_short_name
                      ,iv_name        => cv_msg_base_code                      --拠点コード
                     );
      --
      --年度
      gv_yaer := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcsm_appl_short_name
                      ,iv_name        => cv_msg_year                           --年度
                     );
      --予算区分
      gv_plan_kind := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcsm_appl_short_name
                      ,iv_name        => cv_msg_plan_kind                      --予算区分
                     );
      --レコード区分
      gv_record_kind := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcsm_appl_short_name
                      ,iv_name        => cv_msg_record_kind                    --レコード区分
                     );
      --売上予算
      gv_sales_budget := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcsm_appl_short_name
                      ,iv_name        => cv_msg_sales_budget                   --売上予算
                     );
      --入金値引
      gv_receipt_discount := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcsm_appl_short_name
                      ,iv_name        => cv_msg_receipt_discount               --入金値引
                     );
      --売上値引
      gv_sales_discount := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcsm_appl_short_name
                      ,iv_name        => cv_msg_sales_discount                 --売上値引
                     );
      --売上
      gv_item_sales_budget := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcsm_appl_short_name
                      ,iv_name        => cv_msg_item_sales_budget              --売上
                     );
      --粗利額
      gv_amount_gross_margin := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcsm_appl_short_name
                      ,iv_name        => cv_msg_amount_gross_margin            --粗利額
                     );
      --粗利率
      gv_margin_rate := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcsm_appl_short_name
                      ,iv_name        => cv_msg_margin_rate                    --粗利率
                     );
      --拠点計
      gv_loc_bdgt    := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcsm_appl_short_name
                      ,iv_name        => cv_msg_base_total                     --拠点計
                     );
--
    ------------------------------------
    -- 例外処理
    ------------------------------------
  EXCEPTION
--
    -- *** 業務日付取得例外ハンドラ ***
    WHEN global_proc_date_err_expt THEN
      ov_errmsg  :=  xxccp_common_pkg.get_msg(
                       iv_application   =>  cv_xxcsm_appl_short_name
                      ,iv_name          =>  cv_msg_process_date_err
                     );
      ov_errbuf   :=  SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => ov_errmsg
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => ov_errbuf
      );
      ov_retcode  :=  cv_status_error;
--
    --*** ファイルアップロード名称取得ハンドラ ***
    WHEN global_get_f_uplod_name_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcsm_appl_short_name
                    ,iv_name         => cv_msg_upload_name_get
                  );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => ov_errmsg
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => ov_errbuf
      );
      ov_retcode := cv_status_error;
--
    --*** CSVファイル名取得ハンドラ ***
    WHEN global_get_f_csv_name_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcsm_appl_short_name
                    ,iv_name         => cv_msg_get_f_csv_name
                    ,iv_token_name1  => cv_tkn_key_data
                    ,iv_token_value1 => in_file_id
                  );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => ov_errmsg
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => ov_errbuf
      );
      ov_retcode := cv_status_error;
--
    --*** ロック取得エラーハンドラ ***
    WHEN global_data_lock_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcsm_appl_short_name
                    ,iv_name         => cv_msg_get_lock_err
                    ,iv_token_name1  => cv_tkn_table
                    ,iv_token_value1 => lv_tab_name
                  );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => ov_errmsg
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => ov_errbuf
      );
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => ov_errmsg
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => ov_errbuf
      );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => ov_errbuf
      );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => ov_errbuf
      );
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_upload_data
   * Description      : ファイルアップロードIF取得(A-2)
   ***********************************************************************************/
   PROCEDURE get_upload_data (
     in_file_id            IN  NUMBER       -- FILE_ID
    ,on_get_counter_data   OUT NUMBER       -- データ数
    ,ov_errbuf     OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT VARCHAR2  -- リターン・コード             --# 固定 #
    ,ov_errmsg     OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
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
--
    -- *** ローカル変数 ***
    lv_tab_name      VARCHAR2(500);   --テーブル名
    lv_out_msg       VARCHAR2(2000);  -- メッセージ
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
    ------------------------------------
    -- 年間商品計画データ取得
    ------------------------------------
    xxccp_common_pkg2.blob_to_varchar2(
      in_file_id   => in_file_id           -- ファイルＩＤ
     ,ov_file_data => gt_plan_data         -- 年間商品計画データ(配列型)
     ,ov_errbuf    => lv_errbuf            -- エラー・メッセージ           --# 固定 #
     ,ov_retcode   => lv_retcode           -- リターン・コード             --# 固定 #
     ,ov_errmsg    => lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --戻り値チェック
    IF ( lv_retcode = cv_status_error ) THEN
      lv_tab_name := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcsm_appl_short_name
                      ,iv_name        => cv_msg_file_up_load
                     );
      lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcsm_appl_short_name
                    ,iv_name         => cv_msg_get_data_err
                    ,iv_token_name1  => cv_tkn_table_name
                    ,iv_token_value1 => lv_tab_name
                    ,iv_token_name2  => cv_tkn_key_data
                    ,iv_token_value2 => in_file_id
                   );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg
      );
      RAISE global_api_expt;
    END IF;
    --
    -- 年間商品計画データの取得ができない場合のエラー編集
    IF ( gt_plan_data.LAST < cn_begin_line ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcsm_appl_short_name
                      ,iv_name        => cv_msg_no_upload_date
                     );
      ov_errmsg  := lv_out_msg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
    END IF;
--
    ------------------------------------
    -- データ数件数の取得
    ------------------------------------
    --データ数件数
    on_get_counter_data := gt_plan_data.COUNT;
    gn_target_cnt       := gt_plan_data.COUNT - 1;
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
  END get_upload_data;
--
  /**********************************************************************************
   * Procedure Name   : del_upload_data
   * Description      : アップロードデータ削除処理(A-3)
   ***********************************************************************************/
  PROCEDURE del_upload_data(
     in_file_id    IN  NUMBER    -- 1.FILE_ID
    ,ov_errbuf     OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT VARCHAR2  -- リターン・コード             --# 固定 #
    ,ov_errmsg     OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_upload_data'; -- プログラム名
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
    lv_tab_name   VARCHAR2(100);    --テーブル名
    lv_key_info   VARCHAR2(100);    --キー情報
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
    -- ************************************
    -- ***  年間商品計画データ削除処理  ***
    -- ************************************
--
    BEGIN
      DELETE
        FROM xxccp_mrp_file_ul_interface xmf  --ファイルアップロードIF
       WHERE xmf.file_id = in_file_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        --キー情報の編集処理
        lv_tab_name := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcsm_appl_short_name
                       ,iv_name         => cv_msg_file_up_load
                     );
        lv_key_info := SQLERRM;
        RAISE global_del_ul_interface_expt;
    END;
--
  EXCEPTION
--
    --*** レコード削除例外ハンドラ ***
    WHEN global_del_ul_interface_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcsm_appl_short_name
                    ,iv_name         => cv_msg_delete_data_err
                    ,iv_token_name1  => cv_tkn_table_name
                    ,iv_token_value1 => lv_tab_name
                    ,iv_token_name2  => cv_tkn_key_data
                    ,iv_token_value2 => lv_key_info
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END del_upload_data;
--
  /**********************************************************************************
   * Procedure Name   : split_plan_data
   * Description      : 年間商品計画データの項目分割処理(A-4)
   ***********************************************************************************/
  PROCEDURE split_plan_data(
     in_cnt        IN  NUMBER    -- データ数
    ,ov_errbuf     OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT VARCHAR2  -- リターン・コード             --# 固定 #
    ,ov_errmsg     OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'split_plan_data'; -- プログラム名
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_rec_data     VARCHAR2(32765);
    lv_err_msg      VARCHAR2(5000);  --エラーメッセージ
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
    <<get_plan_loop>>
    FOR i IN 1 .. in_cnt LOOP
--
      ------------------------------------
      -- 全項目数チェック
      ------------------------------------
      IF ( ( NVL( LENGTH( gt_plan_data(i) ), 0 )
           - NVL( LENGTH( REPLACE( gt_plan_data(i), cv_comma, NULL ) ), 0 ) ) <> ( cn_c_header - 1 ) )
      THEN
        --エラー
        lv_rec_data := gt_plan_data(i);
        lv_err_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcsm_appl_short_name
                       ,iv_name         => cv_msg_chk_rec_err
                       ,iv_token_name1  => cv_tkn_data
                       ,iv_token_value1 => lv_rec_data
                      );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_err_msg
        );
        ov_retcode := cv_status_check;
      END IF;
      --カラム分割
      FOR j IN 1 .. cn_c_header LOOP
--
        ------------------------------------
        -- 項目分割
        ------------------------------------
        gr_plan_work_data(i)(j) := TRIM( REPLACE( xxccp_common_pkg.char_delim_partition(
                                                     iv_char     => gt_plan_data(i)
                                                    ,iv_delim    => cv_comma
                                                    ,in_part_num => j
                                                  ) ,cv_dobule_quote, NULL
                                                )
                                       );
      END LOOP;
--
    END LOOP get_plan_loop;
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
  END split_plan_data;
--
  /**********************************************************************************
   * Procedure Name   : item_check
   * Description      : 項目チェック(A-5)
   ***********************************************************************************/
  PROCEDURE item_check(
     in_cnt             IN  NUMBER    -- データカウンタ
    ,ov_base_code       OUT VARCHAR2  -- 拠点コード
    ,ov_plan_year       OUT VARCHAR2  -- 年度
    ,ov_plan_kind       OUT VARCHAR2  -- 予算区分
    ,ov_record_kind     OUT VARCHAR2  -- レコード区分
    ,on_may             OUT NUMBER    -- 5月予算
    ,on_jun             OUT NUMBER    -- 6月予算
    ,on_jul             OUT NUMBER    -- 7月予算
    ,on_aug             OUT NUMBER    -- 8月予算
    ,on_sep             OUT NUMBER    -- 9月予算
    ,on_oct             OUT NUMBER    -- 10月予算
    ,on_nov             OUT NUMBER    -- 11月予算
    ,on_dec             OUT NUMBER    -- 12月予算
    ,on_jan             OUT NUMBER    -- 1月予算
    ,on_feb             OUT NUMBER    -- 2月予算
    ,on_mar             OUT NUMBER    -- 3月予算
    ,on_apr             OUT NUMBER    -- 4月予算
    ,on_sum             OUT NUMBER    -- 商品群年間計予算
    ,ov_errbuf          OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
    ,ov_retcode         OUT VARCHAR2  -- リターン・コード             --# 固定 #
    ,ov_errmsg          OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                     CONSTANT VARCHAR2(100) := 'item_check'; -- プログラム名
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
    lv_err_msg         VARCHAR2(32767);  --エラーメッセージ
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
    --初期化
    lv_err_msg := NULL;
--
    -- **********************
    -- ***  拠点コード  ***
    -- **********************
--
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_plan_work_data(cn_item_header)(cn_base_code)    -- 1.項目名称
     ,iv_item_value   => gr_plan_work_data(in_cnt)(cn_base_code)            -- 2.項目の値
     ,in_item_len     => cn_base_code_length                                -- 3.項目の長さ
     ,in_item_decimal => NULL                                               -- 4.項目の長さ(小数点以下)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ng                       -- 5.必須フラグ
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2                      -- 6.項目属性
     ,ov_errbuf       => lv_errbuf   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode      => lv_retcode  -- リターン・コード             --# 固定 #
     ,ov_errmsg       => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      -- 項目不備エラーメッセージ
      lv_err_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcsm_appl_short_name             -- アプリケーション短縮名
                      , iv_name         => cv_msg_get_format_err                -- メッセージコード
                      , iv_token_name1  => cv_tkn_item                          -- トークンコード1
                      , iv_token_value1 => gr_plan_work_data(cn_item_header)(cn_base_code)  -- トークン値1
                      , iv_token_name2  => cv_tkn_errmsg                        -- トークンコード2
                      , iv_token_value2 => lv_errmsg                            -- トークン値2
                      , iv_token_name3  => cv_tkn_row_num                       -- トークンコード3
                      , iv_token_value3 => in_cnt                               -- トークン値3（見出し込みの行数）
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --値を返却
      ov_base_code := gr_plan_work_data(in_cnt)(cn_base_code);
    END IF;
--
    -- **********************
    -- ***  年度          ***
    -- **********************
--
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_plan_work_data(cn_item_header)(cn_plan_year)            -- 1.項目名称
     ,iv_item_value   => gr_plan_work_data(in_cnt)(cn_plan_year)                    -- 2.項目の値
     ,in_item_len     => cn_plan_year_length                                        -- 3.項目の長さ
     ,in_item_decimal => cn_plan_year_point                                         -- 4.項目の長さ(小数点以下)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ng                               -- 5.必須フラグ
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_num                              -- 6.項目属性
     ,ov_errbuf       => lv_errbuf   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode      => lv_retcode  -- リターン・コード             --# 固定 #
     ,ov_errmsg       => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      -- 項目不備エラーメッセージ
      lv_err_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcsm_appl_short_name             -- アプリケーション短縮名
                      , iv_name         => cv_msg_get_format_err                -- メッセージコード
                      , iv_token_name1  => cv_tkn_item                          -- トークンコード1
                      , iv_token_value1 => gr_plan_work_data(cn_item_header)(cn_plan_year)  -- トークン値1
                      , iv_token_name2  => cv_tkn_errmsg                        -- トークンコード2
                      , iv_token_value2 => lv_errmsg                            -- トークン値2
                      , iv_token_name3  => cv_tkn_row_num                       -- トークンコード3
                      , iv_token_value3 => in_cnt                               -- トークン値3（見出し込みの行数）
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --値を返却
      ov_plan_year := gr_plan_work_data(in_cnt)(cn_plan_year);
    END IF;
--
    -- ********************
    -- ***  予算区分    ***
    -- ********************
--
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_plan_work_data(cn_item_header)(cn_plan_kind)            -- 1.項目名称
     ,iv_item_value   => gr_plan_work_data(in_cnt)(cn_plan_kind)                    -- 2.項目の値
     ,in_item_len     => cn_plan_kind_length                                        -- 3.項目の長さ
     ,in_item_decimal => NULL                                                       -- 4.項目の長さ(小数点以下)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ng                               -- 5.必須フラグ
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2                              -- 6.項目属性
     ,ov_errbuf       => lv_errbuf   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode      => lv_retcode  -- リターン・コード             --# 固定 #
     ,ov_errmsg       => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcsm_appl_short_name             -- アプリケーション短縮名
                      , iv_name         => cv_msg_get_format_err                -- メッセージコード
                      , iv_token_name1  => cv_tkn_item                          -- トークンコード1
                      , iv_token_value1 => gr_plan_work_data(cn_item_header)(cn_plan_kind)  -- トークン値1
                      , iv_token_name2  => cv_tkn_errmsg                        -- トークンコード2
                      , iv_token_value2 => lv_errmsg                            -- トークン値2
                      , iv_token_name3  => cv_tkn_row_num                       -- トークンコード3
                      , iv_token_value3 => in_cnt                               -- トークン値3（見出し込みの行数）
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --値を返却
      ov_plan_kind := gr_plan_work_data(in_cnt)(cn_plan_kind);
    END IF;
--
    -- *********************
    -- ***  レコード区分
    -- *********************
--
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_plan_work_data(cn_item_header)(cn_record_kind)          -- 1.項目名称
     ,iv_item_value   => gr_plan_work_data(in_cnt)(cn_record_kind)                  -- 2.項目の値
     ,in_item_len     => cn_rec_kind_length                                         -- 3.項目の長さ
     ,in_item_decimal => NULL                                                       -- 4.項目の長さ(小数点以下)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ng                               -- 5.必須フラグ
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2                              -- 6.項目属性
     ,ov_errbuf       => lv_errbuf   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode      => lv_retcode  -- リターン・コード             --# 固定 #
     ,ov_errmsg       => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcsm_appl_short_name             -- アプリケーション短縮名
                      , iv_name         => cv_msg_get_format_err                -- メッセージコード
                      , iv_token_name1  => cv_tkn_item                          -- トークンコード1
                      , iv_token_value1 => gr_plan_work_data(cn_item_header)(cn_record_kind)  -- トークン値1
                      , iv_token_name2  => cv_tkn_errmsg                        -- トークンコード2
                      , iv_token_value2 => lv_errmsg                            -- トークン値2
                      , iv_token_name3  => cv_tkn_row_num                       -- トークンコード3
                      , iv_token_value3 => in_cnt                               -- トークン値3（見出し込みの行数）
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --値を返却
      ov_record_kind := gr_plan_work_data(in_cnt)(cn_record_kind);
    END IF;
--
    -- **************
    -- ***  5月予算
    -- **************
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_plan_work_data(cn_item_header)(cn_may)             -- 1.項目名称
     ,iv_item_value   => gr_plan_work_data(in_cnt)(cn_may)                     -- 2.項目の値
     ,in_item_len     => cn_budget_length                                      -- 3.項目の長さ
     ,in_item_decimal => cn_budget_point                                       -- 4.項目の長さ(小数点以下)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ok                          -- 5.必須フラグ
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_num                         -- 6.項目属性
     ,ov_errbuf       => lv_errbuf   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode      => lv_retcode  -- リターン・コード             --# 固定 #
     ,ov_errmsg       => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcsm_appl_short_name             -- アプリケーション短縮名
                      , iv_name         => cv_msg_get_format_err                -- メッセージコード
                      , iv_token_name1  => cv_tkn_item                          -- トークンコード1
                      , iv_token_value1 => gr_plan_work_data(cn_item_header)(cn_may)  -- トークン値1
                      , iv_token_name2  => cv_tkn_errmsg                        -- トークンコード2
                      , iv_token_value2 => lv_errmsg                            -- トークン値2
                      , iv_token_name3  => cv_tkn_row_num                       -- トークンコード3
                      , iv_token_value3 => in_cnt                               -- トークン値3（見出し込みの行数）
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --値を返却
      on_may := gr_plan_work_data(in_cnt)(cn_may);
    END IF;
--
    -- **************
    -- ***  6月予算
    -- **************
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_plan_work_data(cn_item_header)(cn_jun)             -- 1.項目名称
     ,iv_item_value   => gr_plan_work_data(in_cnt)(cn_jun)                     -- 2.項目の値
     ,in_item_len     => cn_budget_length                                      -- 3.項目の長さ
     ,in_item_decimal => cn_budget_point                                       -- 4.項目の長さ(小数点以下)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ok                          -- 5.必須フラグ
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_num                         -- 6.項目属性
     ,ov_errbuf       => lv_errbuf   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode      => lv_retcode  -- リターン・コード             --# 固定 #
     ,ov_errmsg       => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcsm_appl_short_name             -- アプリケーション短縮名
                      , iv_name         => cv_msg_get_format_err                -- メッセージコード
                      , iv_token_name1  => cv_tkn_item                          -- トークンコード1
                      , iv_token_value1 => gr_plan_work_data(cn_item_header)(cn_jun)  -- トークン値1
                      , iv_token_name2  => cv_tkn_errmsg                        -- トークンコード2
                      , iv_token_value2 => lv_errmsg                            -- トークン値2
                      , iv_token_name3  => cv_tkn_row_num                       -- トークンコード3
                      , iv_token_value3 => in_cnt                               -- トークン値3（見出し込みの行数）
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --値を返却
      on_jun := gr_plan_work_data(in_cnt)(cn_jun);
    END IF;
--
    -- **************
    -- ***  7月予算
    -- **************
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_plan_work_data(cn_item_header)(cn_jul)             -- 1.項目名称
     ,iv_item_value   => gr_plan_work_data(in_cnt)(cn_jul)                     -- 2.項目の値
     ,in_item_len     => cn_budget_length                                      -- 3.項目の長さ
     ,in_item_decimal => cn_budget_point                                       -- 4.項目の長さ(小数点以下)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ok                          -- 5.必須フラグ
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_num                         -- 6.項目属性
     ,ov_errbuf       => lv_errbuf   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode      => lv_retcode  -- リターン・コード             --# 固定 #
     ,ov_errmsg       => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcsm_appl_short_name             -- アプリケーション短縮名
                      , iv_name         => cv_msg_get_format_err                -- メッセージコード
                      , iv_token_name1  => cv_tkn_item                          -- トークンコード1
                      , iv_token_value1 => gr_plan_work_data(cn_item_header)(cn_jul)  -- トークン値1
                      , iv_token_name2  => cv_tkn_errmsg                        -- トークンコード2
                      , iv_token_value2 => lv_errmsg                            -- トークン値2
                      , iv_token_name3  => cv_tkn_row_num                       -- トークンコード3
                      , iv_token_value3 => in_cnt                               -- トークン値3（見出し込みの行数）
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --値を返却
      on_jul := gr_plan_work_data(in_cnt)(cn_jul);
    END IF;
--
     -- **************
    -- ***  8月予算
    -- **************
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_plan_work_data(cn_item_header)(cn_aug)             -- 1.項目名称
     ,iv_item_value   => gr_plan_work_data(in_cnt)(cn_aug)                     -- 2.項目の値
     ,in_item_len     => cn_budget_length                                      -- 3.項目の長さ
     ,in_item_decimal => cn_budget_point                                       -- 4.項目の長さ(小数点以下)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ok                          -- 5.必須フラグ
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_num                         -- 6.項目属性
     ,ov_errbuf       => lv_errbuf   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode      => lv_retcode  -- リターン・コード             --# 固定 #
     ,ov_errmsg       => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcsm_appl_short_name             -- アプリケーション短縮名
                      , iv_name         => cv_msg_get_format_err                -- メッセージコード
                      , iv_token_name1  => cv_tkn_item                          -- トークンコード1
                      , iv_token_value1 => gr_plan_work_data(cn_item_header)(cn_aug)  -- トークン値1
                      , iv_token_name2  => cv_tkn_errmsg                        -- トークンコード2
                      , iv_token_value2 => lv_errmsg                            -- トークン値2
                      , iv_token_name3  => cv_tkn_row_num                       -- トークンコード3
                      , iv_token_value3 => in_cnt                               -- トークン値3（見出し込みの行数）
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --値を返却
      on_aug := gr_plan_work_data(in_cnt)(cn_aug);
    END IF;
--
    -- **************
    -- ***  9月予算
    -- **************
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_plan_work_data(cn_item_header)(cn_sep)             -- 1.項目名称
     ,iv_item_value   => gr_plan_work_data(in_cnt)(cn_sep)                     -- 2.項目の値
     ,in_item_len     => cn_budget_length                                      -- 3.項目の長さ
     ,in_item_decimal => cn_budget_point                                       -- 4.項目の長さ(小数点以下)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ok                          -- 5.必須フラグ
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_num                         -- 6.項目属性
     ,ov_errbuf       => lv_errbuf   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode      => lv_retcode  -- リターン・コード             --# 固定 #
     ,ov_errmsg       => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcsm_appl_short_name             -- アプリケーション短縮名
                      , iv_name         => cv_msg_get_format_err                -- メッセージコード
                      , iv_token_name1  => cv_tkn_item                          -- トークンコード1
                      , iv_token_value1 => gr_plan_work_data(cn_item_header)(cn_sep)  -- トークン値1
                      , iv_token_name2  => cv_tkn_errmsg                        -- トークンコード2
                      , iv_token_value2 => lv_errmsg                            -- トークン値2
                      , iv_token_name3  => cv_tkn_row_num                       -- トークンコード3
                      , iv_token_value3 => in_cnt                               -- トークン値3（見出し込みの行数）
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --値を返却
      on_sep := gr_plan_work_data(in_cnt)(cn_sep);
    END IF;
--
    -- **************
    -- ***  10月予算
    -- **************
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_plan_work_data(cn_item_header)(cn_oct)             -- 1.項目名称
     ,iv_item_value   => gr_plan_work_data(in_cnt)(cn_oct)                     -- 2.項目の値
     ,in_item_len     => cn_budget_length                                      -- 3.項目の長さ
     ,in_item_decimal => cn_budget_point                                       -- 4.項目の長さ(小数点以下)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ok                          -- 5.必須フラグ
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_num                         -- 6.項目属性
     ,ov_errbuf       => lv_errbuf   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode      => lv_retcode  -- リターン・コード             --# 固定 #
     ,ov_errmsg       => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcsm_appl_short_name             -- アプリケーション短縮名
                      , iv_name         => cv_msg_get_format_err                -- メッセージコード
                      , iv_token_name1  => cv_tkn_item                          -- トークンコード1
                      , iv_token_value1 => gr_plan_work_data(cn_item_header)(cn_oct)  -- トークン値1
                      , iv_token_name2  => cv_tkn_errmsg                        -- トークンコード2
                      , iv_token_value2 => lv_errmsg                            -- トークン値2
                      , iv_token_name3  => cv_tkn_row_num                       -- トークンコード3
                      , iv_token_value3 => in_cnt                               -- トークン値3（見出し込みの行数）
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --値を返却
      on_oct := gr_plan_work_data(in_cnt)(cn_oct);
    END IF;
--
    -- **************
    -- ***  11月予算
    -- **************
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_plan_work_data(cn_item_header)(cn_nov)             -- 1.項目名称
     ,iv_item_value   => gr_plan_work_data(in_cnt)(cn_nov)                     -- 2.項目の値
     ,in_item_len     => cn_budget_length                                      -- 3.項目の長さ
     ,in_item_decimal => cn_budget_point                                       -- 4.項目の長さ(小数点以下)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ok                          -- 5.必須フラグ
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_num                         -- 6.項目属性
     ,ov_errbuf       => lv_errbuf   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode      => lv_retcode  -- リターン・コード             --# 固定 #
     ,ov_errmsg       => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcsm_appl_short_name             -- アプリケーション短縮名
                      , iv_name         => cv_msg_get_format_err                -- メッセージコード
                      , iv_token_name1  => cv_tkn_item                          -- トークンコード1
                      , iv_token_value1 => gr_plan_work_data(cn_item_header)(cn_nov)  -- トークン値1
                      , iv_token_name2  => cv_tkn_errmsg                        -- トークンコード2
                      , iv_token_value2 => lv_errmsg                            -- トークン値2
                      , iv_token_name3  => cv_tkn_row_num                       -- トークンコード3
                      , iv_token_value3 => in_cnt                               -- トークン値3（見出し込みの行数）
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --値を返却
      on_nov := gr_plan_work_data(in_cnt)(cn_nov);
    END IF;
--
    -- **************
    -- ***  12月予算
    -- **************
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_plan_work_data(cn_item_header)(cn_dec)             -- 1.項目名称
     ,iv_item_value   => gr_plan_work_data(in_cnt)(cn_dec)                     -- 2.項目の値
     ,in_item_len     => cn_budget_length                                      -- 3.項目の長さ
     ,in_item_decimal => cn_budget_point                                       -- 4.項目の長さ(小数点以下)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ok                          -- 5.必須フラグ
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_num                         -- 6.項目属性
     ,ov_errbuf       => lv_errbuf   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode      => lv_retcode  -- リターン・コード             --# 固定 #
     ,ov_errmsg       => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcsm_appl_short_name             -- アプリケーション短縮名
                      , iv_name         => cv_msg_get_format_err                -- メッセージコード
                      , iv_token_name1  => cv_tkn_item                          -- トークンコード1
                      , iv_token_value1 => gr_plan_work_data(cn_item_header)(cn_dec)  -- トークン値1
                      , iv_token_name2  => cv_tkn_errmsg                        -- トークンコード2
                      , iv_token_value2 => lv_errmsg                            -- トークン値2
                      , iv_token_name3  => cv_tkn_row_num                       -- トークンコード3
                      , iv_token_value3 => in_cnt                               -- トークン値3（見出し込みの行数）
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --値を返却
      on_dec := gr_plan_work_data(in_cnt)(cn_dec);
    END IF;
--
    -- **************
    -- ***  1月予算
    -- **************
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_plan_work_data(cn_item_header)(cn_jan)             -- 1.項目名称
     ,iv_item_value   => gr_plan_work_data(in_cnt)(cn_jan)                     -- 2.項目の値
     ,in_item_len     => cn_budget_length                                      -- 3.項目の長さ
     ,in_item_decimal => cn_budget_point                                       -- 4.項目の長さ(小数点以下)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ok                          -- 5.必須フラグ
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_num                         -- 6.項目属性
     ,ov_errbuf       => lv_errbuf   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode      => lv_retcode  -- リターン・コード             --# 固定 #
     ,ov_errmsg       => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcsm_appl_short_name             -- アプリケーション短縮名
                      , iv_name         => cv_msg_get_format_err                -- メッセージコード
                      , iv_token_name1  => cv_tkn_item                          -- トークンコード1
                      , iv_token_value1 => gr_plan_work_data(cn_item_header)(cn_jan)  -- トークン値1
                      , iv_token_name2  => cv_tkn_errmsg                        -- トークンコード2
                      , iv_token_value2 => lv_errmsg                            -- トークン値2
                      , iv_token_name3  => cv_tkn_row_num                       -- トークンコード3
                      , iv_token_value3 => in_cnt                               -- トークン値3（見出し込みの行数）
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --値を返却
      on_jan := gr_plan_work_data(in_cnt)(cn_jan);
    END IF;
--
    -- **************
    -- ***  2月予算
    -- **************
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_plan_work_data(cn_item_header)(cn_feb)             -- 1.項目名称
     ,iv_item_value   => gr_plan_work_data(in_cnt)(cn_feb)                     -- 2.項目の値
     ,in_item_len     => cn_budget_length                                      -- 3.項目の長さ
     ,in_item_decimal => cn_budget_point                                       -- 4.項目の長さ(小数点以下)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ok                          -- 5.必須フラグ
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_num                         -- 6.項目属性
     ,ov_errbuf       => lv_errbuf   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode      => lv_retcode  -- リターン・コード             --# 固定 #
     ,ov_errmsg       => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcsm_appl_short_name             -- アプリケーション短縮名
                      , iv_name         => cv_msg_get_format_err                -- メッセージコード
                      , iv_token_name1  => cv_tkn_item                          -- トークンコード1
                      , iv_token_value1 => gr_plan_work_data(cn_item_header)(cn_feb)  -- トークン値1
                      , iv_token_name2  => cv_tkn_errmsg                        -- トークンコード2
                      , iv_token_value2 => lv_errmsg                            -- トークン値2
                      , iv_token_name3  => cv_tkn_row_num                       -- トークンコード3
                      , iv_token_value3 => in_cnt                               -- トークン値3（見出し込みの行数）
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --値を返却
      on_feb := gr_plan_work_data(in_cnt)(cn_feb);
    END IF;
--
    -- **************
    -- ***  3月予算
    -- **************
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_plan_work_data(cn_item_header)(cn_mar)             -- 1.項目名称
     ,iv_item_value   => gr_plan_work_data(in_cnt)(cn_mar)                     -- 2.項目の値
     ,in_item_len     => cn_budget_length                                      -- 3.項目の長さ
     ,in_item_decimal => cn_budget_point                                       -- 4.項目の長さ(小数点以下)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ok                          -- 5.必須フラグ
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_num                         -- 6.項目属性
     ,ov_errbuf       => lv_errbuf   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode      => lv_retcode  -- リターン・コード             --# 固定 #
     ,ov_errmsg       => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcsm_appl_short_name             -- アプリケーション短縮名
                      , iv_name         => cv_msg_get_format_err                -- メッセージコード
                      , iv_token_name1  => cv_tkn_item                          -- トークンコード1
                      , iv_token_value1 => gr_plan_work_data(cn_item_header)(cn_mar)  -- トークン値1
                      , iv_token_name2  => cv_tkn_errmsg                        -- トークンコード2
                      , iv_token_value2 => lv_errmsg                            -- トークン値2
                      , iv_token_name3  => cv_tkn_row_num                       -- トークンコード3
                      , iv_token_value3 => in_cnt                               -- トークン値3（見出し込みの行数）
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --値を返却
      on_mar := gr_plan_work_data(in_cnt)(cn_mar);
    END IF;
--
    -- **************
    -- ***  4月予算
    -- **************
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_plan_work_data(cn_item_header)(cn_apr)             -- 1.項目名称
     ,iv_item_value   => gr_plan_work_data(in_cnt)(cn_apr)                     -- 2.項目の値
     ,in_item_len     => cn_budget_length                                      -- 3.項目の長さ
     ,in_item_decimal => cn_budget_point                                       -- 4.項目の長さ(小数点以下)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ok                          -- 5.必須フラグ
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_num                         -- 6.項目属性
     ,ov_errbuf       => lv_errbuf   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode      => lv_retcode  -- リターン・コード             --# 固定 #
     ,ov_errmsg       => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcsm_appl_short_name             -- アプリケーション短縮名
                      , iv_name         => cv_msg_get_format_err                -- メッセージコード
                      , iv_token_name1  => cv_tkn_item                          -- トークンコード1
                      , iv_token_value1 => gr_plan_work_data(cn_item_header)(cn_apr)  -- トークン値1
                      , iv_token_name2  => cv_tkn_errmsg                        -- トークンコード2
                      , iv_token_value2 => lv_errmsg                            -- トークン値2
                      , iv_token_name3  => cv_tkn_row_num                       -- トークンコード3
                      , iv_token_value3 => in_cnt                               -- トークン値3（見出し込みの行数）
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --値を返却
      on_apr := gr_plan_work_data(in_cnt)(cn_apr);
    END IF;
--
    IF ( gr_plan_work_data(in_cnt)(cn_plan_kind) = gv_loc_bdgt ) THEN
      on_sum := NULL;
    ELSE
      -- **************
      -- ***  商品群年間計予算
      -- **************
      xxccp_common_pkg2.upload_item_check(
        iv_item_name    => gr_plan_work_data(cn_item_header)(cn_sum)             -- 1.項目名称
       ,iv_item_value   => gr_plan_work_data(in_cnt)(cn_sum)                     -- 2.項目の値
       ,in_item_len     => cn_budget_length                                      -- 3.項目の長さ
       ,in_item_decimal => cn_budget_point                                       -- 4.項目の長さ(小数点以下)
       ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ok                          -- 5.必須フラグ
       ,iv_item_attr    => xxccp_common_pkg2.gv_attr_num                         -- 6.項目属性
       ,ov_errbuf       => lv_errbuf   -- エラー・メッセージ           --# 固定 #
       ,ov_retcode      => lv_retcode  -- リターン・コード             --# 固定 #
       ,ov_errmsg       => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      --ワーニング
      IF ( lv_retcode = cv_status_warn ) THEN
        lv_err_msg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcsm_appl_short_name             -- アプリケーション短縮名
                        , iv_name         => cv_msg_get_format_err                -- メッセージコード
                        , iv_token_name1  => cv_tkn_item                          -- トークンコード1
                        , iv_token_value1 => gr_plan_work_data(cn_item_header)(cn_sum)  -- トークン値1
                        , iv_token_name2  => cv_tkn_errmsg                        -- トークンコード2
                        , iv_token_value2 => lv_errmsg                            -- トークン値2
                        , iv_token_name3  => cv_tkn_row_num                       -- トークンコード3
                        , iv_token_value3 => in_cnt                               -- トークン値3（見出し込みの行数）
                      );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_err_msg
        );
      --共通関数エラー
      ELSIF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      --正常終了
      ELSIF ( lv_retcode = cv_status_normal ) THEN
        --値を返却
        on_sum := gr_plan_work_data(in_cnt)(cn_sum);
      END IF;
--
    END IF;
--
    --ワーニングメッセージ確認
    IF ( lv_err_msg IS NULL ) THEN
      NULL;
    ELSE
      RAISE global_item_check_expt;
    END IF;
--
  EXCEPTION
--
    -- *** 項目チェックエラーハンドラ ***
    WHEN global_item_check_expt THEN
      ov_retcode := cv_status_check;
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
  END item_check;
--
  /**********************************************************************************
   * Procedure Name   : ins_plan_tmp
   * Description      : 商品計画アップロードワーク登録処理(A-6)
   ***********************************************************************************/
  PROCEDURE ins_plan_tmp(
     in_cnt                   IN  NUMBER    -- データカウンタ
    ,iv_base_code             IN  VARCHAR2  -- 拠点コード
    ,iv_plan_year             IN  VARCHAR2  -- 年度
    ,iv_plan_kind             IN  VARCHAR2  -- 予算区分
    ,iv_record_kind           IN  VARCHAR2  -- レコード区分
    ,in_may                   IN  NUMBER    -- 5月予算
    ,in_jun                   IN  NUMBER    -- 6月予算
    ,in_jul                   IN  NUMBER    -- 7月予算
    ,in_aug                   IN  NUMBER    -- 8月予算
    ,in_sep                   IN  NUMBER    -- 9月予算
    ,in_oct                   IN  NUMBER    -- 10月予算
    ,in_nov                   IN  NUMBER    -- 11月予算
    ,in_dec                   IN  NUMBER    -- 12月予算
    ,in_jan                   IN  NUMBER    -- 1月予算
    ,in_feb                   IN  NUMBER    -- 2月予算
    ,in_mar                   IN  NUMBER    -- 3月予算
    ,in_apr                   IN  NUMBER    -- 4月予算
    ,in_sum                   IN  NUMBER    -- 商品群年間予算
    ,ov_errbuf                OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
    ,ov_retcode               OUT VARCHAR2  -- リターン・コード             --# 固定 #
    ,ov_errmsg                OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_plan_tmp'; -- プログラム名
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
    lv_err_msg         VARCHAR2(32767);  --エラーメッセージ
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --初期化
    lv_err_msg := NULL;
--
    BEGIN
      INSERT INTO xxcsm_plan_tmp(
          record_id           -- 01:レコードNo.
         ,base_code           -- 02:拠点コード
         ,plan_year           -- 03:年度
         ,plan_kind           -- 04:予算区分
         ,record_kind         -- 05:レコード区分
         ,plan_may            -- 06:5月予算
         ,plan_jun            -- 07:6月予算
         ,plan_jul            -- 08:7月予算
         ,plan_aug            -- 09:8月予算
         ,plan_sep            -- 10:9月予算
         ,plan_oct            -- 11:10月予算
         ,plan_nov            -- 12:11月予算
         ,plan_dec            -- 13:12月予算
         ,plan_jan            -- 14:1月予算
         ,plan_feb            -- 15:2月予算
         ,plan_mar            -- 16:3月予算
         ,plan_apr            -- 17:4月予算
         ,plan_sum            -- 18:商品群年間計
         ) VALUES (
          in_cnt               -- 01:レコードNo.
         ,iv_base_code         -- 02:拠点コード
         ,iv_plan_year         -- 03:年度
         ,iv_plan_kind         -- 04:予算区分
         ,iv_record_kind       -- 05:レコード区分
         ,in_may               -- 06:5月予算
         ,in_jun               -- 07:6月予算
         ,in_jul               -- 08:7月予算
         ,in_aug               -- 09:8月予算
         ,in_sep               -- 10:9月予算
         ,in_oct               -- 11:10月予算
         ,in_nov               -- 12:11月予算
         ,in_dec               -- 13:12月予算
         ,in_jan               -- 14:1月予算
         ,in_feb               -- 15:2月予算
         ,in_mar               -- 16:3月予算
         ,in_apr               -- 17:4月予算
         ,in_sum               -- 18:商品群年間計
      );
--
    EXCEPTION
      WHEN OTHERS THEN
        --
        gv_tkn1   := xxccp_common_pkg.get_msg( cv_xxcsm_appl_short_name, cv_msg_tmp_tbl );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_xxcsm_appl_short_name, cv_msg_add_err, cv_tkn_table, gv_tkn1 );
        lv_errbuf := SQLERRM;
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
  END ins_plan_tmp;
--
  /**********************************************************************************
   * Procedure Name   : chk_base_code
   * Description      : 拠点コード、年度チェック処理(A-8)
   ***********************************************************************************/
  PROCEDURE chk_base_code(
     ov_errbuf     OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT VARCHAR2  -- リターン・コード             --# 固定 #
    ,ov_errmsg     OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_base_code'; -- プログラム名
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
    -- セキュリティ判定用
    cv_kyoten                         CONSTANT VARCHAR2(1)  := '1';     -- 拠点
    cv_security_mgr                   CONSTANT VARCHAR2(1)  := '2';     -- 管理元拠点
    cv_security_etc                   CONSTANT VARCHAR2(1)  := '3';     -- 営業企画部、地域営業管理部、情報管理部以外
    -- 処理ステータス
    cv_msg_retcode_ok                 CONSTANT VARCHAR2(1)  := '0';     -- 正常
    cv_msg_retcode_alert              CONSTANT VARCHAR2(1)  := '1';     -- 警告
--
    -- *** ローカル変数 ***
    lv_chk_status         VARCHAR2(1);
    ln_sec_cnt            NUMBER;
    lt_account_number     hz_cust_accounts.account_number%TYPE;
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
    lv_chk_status := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    <<chk_base_code_loop>>
    FOR i IN 1.. gn_target_cnt LOOP
--
      -- ***********************************
      -- ***  拠点コード、年度チェック
      -- ***********************************
      IF ( i = 1 ) THEN
        -- 1行目のチェック
        -- **********************
        -- 拠点セキュリティチェック
        -- **********************
        IF ( gv_no_flv_tag = cv_security_mgr -- 2：管理元拠点
          OR gv_no_flv_tag = cv_security_etc -- 3：その他
          OR gv_sec_retcode = cv_msg_retcode_alert )
        THEN
          IF ( gv_dummy_dept_ref = cv_yes ) THEN
          -- ダミー階層使用
            SELECT  COUNT(1)                    AS sec_cnt
              INTO  ln_sec_cnt
              FROM (SELECT  flv.description     AS account_number
                      FROM  fnd_lookup_values   flv
                     WHERE  flv.language        = ct_user_lang
                       AND  flv.lookup_type     = cv_look_dummy_dept
                       AND  flv.enabled_flag    = 'Y'
                       AND  flv.attribute2      = gv_user_base
                   UNION ALL
                    SELECT  hca.account_number  AS account_number
                      FROM  apps.hz_cust_accounts    hca
                           ,apps.hz_parties          hps
                           ,apps.xxcmm_cust_accounts xca
                     WHERE  hca.party_id              = hps.party_id
                       AND  hca.cust_account_id       = xca.customer_id
                       AND (hps.duns_number_c <> '90'
                        OR  hps.duns_number_c IS NULL)
                       AND (xca.management_base_code  = gv_user_base
                        OR  hca.account_number        = gv_user_base))
             WHERE  account_number = gr_plan_tmps_tab(i).base_code
            ;
          ELSE
            -- ダミー階層未使用
            SELECT COUNT(1)                    AS sec_cnt
              INTO  ln_sec_cnt
              FROM (SELECT  hca.account_number AS account_number
                      FROM  hz_cust_accounts   hca
                           ,hz_parties         hps
                     WHERE  hca.party_id       = hps.party_id
                       AND  hca.customer_class_code = '1'
                       AND (hps.duns_number_c <> '90'
                        OR  hps.duns_number_c IS NULL)
                       AND  hca.account_number = gv_user_base
                   UNION ALL
                    SELECT  hca.account_number  AS account_number
                      FROM  hz_cust_accounts    hca
                           ,hz_parties          hps
                           ,xxcmm_cust_accounts xca
                     WHERE  hca.party_id              = hps.party_id
                       AND  hca.cust_account_id      = xca.customer_id
                       AND  hca.customer_class_code = '1'
                       AND (hps.duns_number_c <> '90'
                        OR  hps.duns_number_c IS NULL)
                       AND  xca.management_base_code = gv_user_base)
              WHERE  account_number = gr_plan_tmps_tab(i).base_code
            ;
          END IF;
        ELSE
        -- 営業企画部、地域営業管理部、情報管理部
          SELECT COUNT(1)                    AS sec_cnt
            INTO  ln_sec_cnt
          FROM   hz_cust_accounts    hca
                ,hz_parties          hps
          WHERE  hca.party_id            = hps.party_id
            AND  hca.customer_class_code = '1'
            AND (hps.duns_number_c <> '90'
             OR  hps.duns_number_c IS NULL)
            AND  hca.account_number = gr_plan_tmps_tab(i).base_code
          ;
        END IF;
        --
        IF ( ln_sec_cnt = 0 ) THEN
          --メッセージ情報の編集処理
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_xxcsm_appl_short_name
                        ,iv_name          => cv_msg_security_err                  -- 拠点セキュリティエラー
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          ov_retcode := cv_status_check;
        END IF;
        --
        -- **********************
        -- 年度チェック
        -- **********************
        IF gr_plan_tmps_tab(i).plan_year <> gt_plan_year THEN
          -- 年度エラーメッセージ出力し、異常終了
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcsm_appl_short_name -- アプリケーション短縮名
                         , iv_name         => cv_msg_budget_year_err   -- メッセージコード
                         , iv_token_name1  => cv_tkn_yosan_nendo       -- トークンコード1
                         , iv_token_value1 => TO_CHAR(gt_plan_year)    -- トークン値1（予算年度）
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          ov_retcode := cv_status_check;
        END IF;
        --
      ELSE
        IF lv_chk_status = cv_status_normal THEN
          --正常の場合のみチェックを続ける（大量メッセージ出力抑止）
          --2行目以降のチェック
          --拠点コードチェック
          IF gr_plan_tmps_tab(i).base_code <> gr_plan_tmps_tab(1).base_code THEN
            --複数拠点指定不可エラーメッセージを出力し処理中止
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_xxcsm_appl_short_name    -- アプリケーション短縮名
                           , iv_name         => cv_msg_multi_base_code_err  -- メッセージコード
                         );
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
            ov_retcode := cv_status_check;
            lv_chk_status := cv_status_check;
          END IF;
          --年度チェック
          IF gr_plan_tmps_tab(i).plan_year <> gr_plan_tmps_tab(1).plan_year THEN
            --複数予算年度指定不可エラーメッセージを出力し処理中止
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_xxcsm_appl_short_name   -- アプリケーション短縮名
                           , iv_name         => cv_msg_multi_year_err      -- メッセージコード
                         );
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
            ov_retcode := cv_status_check;
            lv_chk_status := cv_status_check;
          END IF;
          --
        END IF;
        --
      END IF;
--
    END LOOP chk_base_code_loop;
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
  END chk_base_code;
--
  /**********************************************************************************
   * Procedure Name   : chk_record_kind
   * Description      : レコード区分チェック処理(A-9)
   ***********************************************************************************/
  PROCEDURE chk_record_kind(
     ov_errbuf     OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT VARCHAR2  -- リターン・コード             --# 固定 #
    ,ov_errmsg     OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_record_kind'; -- プログラム名
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
    -- 拠点計、商品群ごとのレコード区分件数を格納するレコード
    TYPE l_plan_kind_rtype IS RECORD (
      plan_kind             VARCHAR2(50)  --拠点計   or 商品群コード
     ,record_kind_a         NUMBER        --売上値引 or 売上
     ,record_kind_b         NUMBER        --入金値引 or 粗利額
     ,record_kind_c         NUMBER        --売上予算 or 粗利率
     ,else_kind             NUMBER
    );
    -- 拠点、年度、予算区分（商品群）ごとのレコード区分件数を格納するレコード
    TYPE l_plan_kind_ttype IS TABLE OF l_plan_kind_rtype INDEX BY BINARY_INTEGER;
    l_plan_kind_tab   l_plan_kind_ttype;
    --
    ln_plan_cnt                 NUMBER;
    --前レコード保持
    lv_before_plan_kind         VARCHAR2(20);              -- 予算区分
    --
    lv_record_kind_a_name       VARCHAR2(20);
    lv_record_kind_b_name       VARCHAR2(20);
    lv_record_kind_c_name       VARCHAR2(20);
--
    lv_plan_kind_kyoten         VARCHAR2(1);
    lv_plan_kind_item_group     VARCHAR2(1);
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
    -- 初期化
    lv_before_plan_kind     := cv_blank;
    ln_plan_cnt             := 0;
    lv_plan_kind_kyoten     := cv_no;
    lv_plan_kind_item_group := cv_no;
--
    <<chk_record_kind_loop>>
    FOR i IN 1.. gn_target_cnt LOOP
--
      -- 前回処理予算区分と異なれば、レコード区分件数ワーク初期化
      IF lv_before_plan_kind <> gr_plan_tmps_tab(i).plan_kind THEN
        ln_plan_cnt := ln_plan_cnt + 1;
        l_plan_kind_tab(ln_plan_cnt).plan_kind     := gr_plan_tmps_tab(i).plan_kind;
        l_plan_kind_tab(ln_plan_cnt).record_kind_a := 0;
        l_plan_kind_tab(ln_plan_cnt).record_kind_b := 0;
        l_plan_kind_tab(ln_plan_cnt).record_kind_c := 0;
        l_plan_kind_tab(ln_plan_cnt).else_kind     := 0;
      END IF;
      --
      --レコード区分判定およびレコード区分数インクリメント
      IF gr_plan_tmps_tab(i).plan_kind = gv_loc_bdgt THEN              --拠点計
        IF gr_plan_tmps_tab(i).record_kind = gv_sales_discount THEN       --売上値引
          l_plan_kind_tab(ln_plan_cnt).record_kind_a := l_plan_kind_tab(ln_plan_cnt).record_kind_a + 1;
        ELSIF gr_plan_tmps_tab(i).record_kind = gv_receipt_discount THEN  --入金値引
          l_plan_kind_tab(ln_plan_cnt).record_kind_b := l_plan_kind_tab(ln_plan_cnt).record_kind_b + 1;
        ELSIF gr_plan_tmps_tab(i).record_kind = gv_sales_budget THEN      --売上予算
          l_plan_kind_tab(ln_plan_cnt).record_kind_c := l_plan_kind_tab(ln_plan_cnt).record_kind_c + 1;
        ELSE
          l_plan_kind_tab(ln_plan_cnt).else_kind := l_plan_kind_tab(ln_plan_cnt).else_kind + 1;
        END IF;
      ELSE                                                              --商品群コード
        IF gr_plan_tmps_tab(i).record_kind = gv_item_sales_budget THEN       --売上
          l_plan_kind_tab(ln_plan_cnt).record_kind_a := l_plan_kind_tab(ln_plan_cnt).record_kind_a + 1;
        ELSIF gr_plan_tmps_tab(i).record_kind = gv_amount_gross_margin THEN  --粗利額
          l_plan_kind_tab(ln_plan_cnt).record_kind_b := l_plan_kind_tab(ln_plan_cnt).record_kind_b + 1;
        ELSIF gr_plan_tmps_tab(i).record_kind = gv_margin_rate THEN          --粗利率
          l_plan_kind_tab(ln_plan_cnt).record_kind_c := l_plan_kind_tab(ln_plan_cnt).record_kind_c + 1;
        ELSE
          l_plan_kind_tab(ln_plan_cnt).else_kind := l_plan_kind_tab(ln_plan_cnt).else_kind + 1;
        END IF;
      END IF;
      --
      lv_before_plan_kind := gr_plan_tmps_tab(i).plan_kind;
      --
    END LOOP  chk_record_kind_loop;
    --
    --対象レコード区分の件数エラーをログ出力
    << outlog_loop >>
    FOR i IN 1..l_plan_kind_tab.COUNT LOOP
      IF l_plan_kind_tab(i).plan_kind = gv_loc_bdgt THEN              --拠点計
        lv_record_kind_a_name := gv_sales_discount;
        lv_record_kind_b_name := gv_receipt_discount;
        lv_record_kind_c_name := gv_sales_budget;
        lv_plan_kind_kyoten   := cv_yes;
      ELSE
        lv_record_kind_a_name   := gv_item_sales_budget;
        lv_record_kind_b_name   := gv_amount_gross_margin;
        lv_record_kind_c_name   := gv_margin_rate;
        lv_plan_kind_item_group := cv_yes;
      END IF;
      --
      -- 売上値引or売上レコード
      IF l_plan_kind_tab(i).record_kind_a = 0 THEN
        --未存在エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcsm_appl_short_name      -- アプリケーション短縮名
                       , iv_name         => cv_msg_no_found_rec_kubun     -- メッセージコード
                       , iv_token_name1  => cv_tkn_plan_kind              -- トークンコード1
                       , iv_token_value1 => l_plan_kind_tab(i).plan_kind  -- トークン値1（予算区分）
                       , iv_token_name2  => cv_tkn_record_kind            -- トークンコード2
                       , iv_token_value2 => lv_record_kind_a_name         -- トークン値2（レコード区分）
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_check;
      END IF;
      IF l_plan_kind_tab(i).record_kind_a > 1 THEN
        --複数存在エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcsm_appl_short_name      -- アプリケーション短縮名
                       , iv_name         => cv_msg_too_many_rec_kubun     -- メッセージコード
                       , iv_token_name1  => cv_tkn_plan_kind              -- トークンコード1
                       , iv_token_value1 => l_plan_kind_tab(i).plan_kind  -- トークン値1（予算区分）
                       , iv_token_name2  => cv_tkn_record_kind            -- トークンコード2
                       , iv_token_value2 => lv_record_kind_a_name         -- トークン値2（レコード区分）
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_check;
      END IF;
      -- 入金値引or粗利額レコード
      IF l_plan_kind_tab(i).record_kind_b = 0 THEN
        --未存在エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcsm_appl_short_name      -- アプリケーション短縮名
                       , iv_name         => cv_msg_no_found_rec_kubun     -- メッセージコード
                       , iv_token_name1  => cv_tkn_plan_kind              -- トークンコード1
                       , iv_token_value1 => l_plan_kind_tab(i).plan_kind  -- トークン値1（予算区分）
                       , iv_token_name2  => cv_tkn_record_kind            -- トークンコード2
                       , iv_token_value2 => lv_record_kind_b_name         -- トークン値2（レコード区分）
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_check;
      END IF;
      IF l_plan_kind_tab(i).record_kind_b > 1 THEN
        --複数存在エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcsm_appl_short_name      -- アプリケーション短縮名
                       , iv_name         => cv_msg_too_many_rec_kubun     -- メッセージコード
                       , iv_token_name1  => cv_tkn_plan_kind              -- トークンコード1
                       , iv_token_value1 => l_plan_kind_tab(i).plan_kind  -- トークン値1（予算区分）
                       , iv_token_name2  => cv_tkn_record_kind            -- トークンコード2
                       , iv_token_value2 => lv_record_kind_b_name         -- トークン値2（レコード区分）
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_check;
      END IF;
      -- 売上予算or粗利率レコード
      IF l_plan_kind_tab(i).record_kind_c = 0 THEN
        --未存在エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcsm_appl_short_name      -- アプリケーション短縮名
                       , iv_name         => cv_msg_no_found_rec_kubun     -- メッセージコード
                       , iv_token_name1  => cv_tkn_plan_kind              -- トークンコード1
                       , iv_token_value1 => l_plan_kind_tab(i).plan_kind  -- トークン値1（予算区分）
                       , iv_token_name2  => cv_tkn_record_kind            -- トークンコード2
                       , iv_token_value2 => lv_record_kind_c_name         -- トークン値2（レコード区分）
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_check;
      END IF;
      IF l_plan_kind_tab(i).record_kind_c > 1 THEN
        --複数存在エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcsm_appl_short_name      -- アプリケーション短縮名
                       , iv_name         => cv_msg_too_many_rec_kubun     -- メッセージコード
                       , iv_token_name1  => cv_tkn_plan_kind              -- トークンコード1
                       , iv_token_value1 => l_plan_kind_tab(i).plan_kind  -- トークン値1（予算区分）
                       , iv_token_name2  => cv_tkn_record_kind            -- トークンコード2
                       , iv_token_value2 => lv_record_kind_c_name         -- トークン値2（レコード区分）
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_check;
      END IF;
      -- 売上値引、入金値引、売上予算、売上、粗利額、粗利率以外のレコード存在エラー
      IF l_plan_kind_tab(i).else_kind > 0 THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcsm_appl_short_name      -- アプリケーション短縮名
                       , iv_name         => cv_msg_fail_rec_kubun         -- メッセージコード
                       , iv_token_name1  => cv_tkn_plan_kind              -- トークンコード1
                       , iv_token_value1 => l_plan_kind_tab(i).plan_kind  -- トークン値1（予算区分）
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_check;
      END IF;
      --
    END LOOP  outlog_loop;
    --
    --予算区分チェック
    --「拠点計」予算存在チェック
    IF lv_plan_kind_kyoten = cv_no THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcsm_appl_short_name      -- アプリケーション短縮名
                     , iv_name         => cv_msg_no_plan_kind_err       -- メッセージコード
                     , iv_token_name1  => cv_tkn_plan_kind              -- トークンコード1
                     , iv_token_value1 => cv_sum_kyoten                 -- トークン値1（拠点計）
                   );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      ov_retcode := cv_status_check;
    END IF;
    --
    --商品群予算存在チェック
    IF lv_plan_kind_item_group = cv_no THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcsm_appl_short_name      -- アプリケーション短縮名
                     , iv_name         => cv_msg_no_plan_kind_err       -- メッセージコード
                     , iv_token_name1  => cv_tkn_plan_kind              -- トークンコード1
                     , iv_token_value1 => cv_item_group                 -- トークン値1（商品群）
                   );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      ov_retcode := cv_status_check;
    END IF;
    --
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
  END chk_record_kind;
--
  /**********************************************************************************
   * Procedure Name   : chk_master_data
   * Description      : 商品群マスタチェック処理(A-10)
   ***********************************************************************************/
  PROCEDURE chk_master_data(
     ov_errbuf     OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT VARCHAR2  -- リターン・コード             --# 固定 #
    ,ov_errmsg     OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_master_data'; -- プログラム名
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
    lt_item_group_nm        xxcsm_item_group_3_nm_v.item_group_nm%TYPE;
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
    <<chk_master_data_loop>>
    FOR i IN 4.. gn_target_cnt LOOP
      IF MOD(i, 3) <> 1 THEN
        CONTINUE;
      END IF;
      --
      -- ***********************************
      -- ***  商品群マスタ存在チェック
      -- ***********************************
      BEGIN
        SELECT item_group_nm  AS item_group_nm
        INTO   lt_item_group_nm
        FROM   xxcsm_item_group_3_nm_v
        WHERE item_group_cd = gr_plan_tmps_tab(i).plan_kind
        ;
        --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          --商品群がマスタに存在しません
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcsm_appl_short_name                     -- アプリケーション短縮名
                         , iv_name         => cv_msg_master_err                            -- メッセージコード
                         , iv_token_name1  => cv_tkn_deal_cd                               -- トークンコード1
                         , iv_token_value1 => gr_plan_tmps_tab(i).plan_kind                -- トークン値1（商品群）
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          ov_retcode := cv_status_check;
      END;
      --
    END LOOP  chk_master_data_loop;
    --
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
  END chk_master_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_budget_value
   * Description      : 予算値チェック
   ***********************************************************************************/
  PROCEDURE chk_budget_value(
     ov_errbuf               OUT VARCHAR2    -- エラー・メッセージ
    ,ov_retcode              OUT VARCHAR2    -- リターン・コード
    ,ov_errmsg               OUT VARCHAR2    -- ユーザー・エラー・メッセージ
    ,iv_plan_kind            IN  VARCHAR2    -- 拠点計 or 商品群
    ,iv_month                IN  VARCHAR2    -- 月
    ,in_value1               IN  NUMBER      -- 売上値引 or 売上
    ,in_value2               IN  NUMBER      -- 入金値引 or 粗利額
    ,in_value3               IN  NUMBER      -- 売上予算 or 粗利率
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'chk_budget_value'; -- プログラム名
    --
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf        VARCHAR2(5000);      -- エラー・メッセージ
    lv_retcode       VARCHAR2(1);         -- リターン・コード
    lv_errmsg        VARCHAR2(5000);      -- ユーザー・エラー・メッセージ
    lv_out_msg       VARCHAR2(2000);      -- メッセージ
    lb_retcode       BOOLEAN;             -- APIリターン・メッセージ用
    --
    ln_cnt           NUMBER;              -- カウンタ
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.初期化
    -------------------------------------------------
    ov_retcode  := cv_status_normal;
    --
    IF iv_plan_kind = gv_loc_bdgt THEN
      -------------------------------------------------
      -- 1.拠点計の予算値チェック
      -------------------------------------------------
      --売上値引チェック
      IF in_value1 IS NULL THEN
        --売上値引を指定してください
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcsm_appl_short_name    -- アプリケーション短縮名
                       , iv_name         => cv_msg_null_err             -- メッセージコード
                       , iv_token_name1  => cv_tkn_plan_kind
                       , iv_token_value1 => iv_plan_kind
                       , iv_token_name2  => cv_tkn_month
                       , iv_token_value2 => iv_month
                       , iv_token_name3  => cv_tkn_column
                       , iv_token_value3 => gv_sales_discount
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_check;
        --
      ELSE
        -- プラス値不可チェック
        IF in_value1 > 0 THEN
          --0より大きい値は指定できません
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcsm_appl_short_name    -- アプリケーション短縮名
                         , iv_name         => cv_msg_disconut_item_err    -- メッセージコード
                         , iv_token_name1  => cv_tkn_plan_kind
                         , iv_token_value1 => iv_plan_kind
                         , iv_token_name2  => cv_tkn_month
                         , iv_token_value2 => iv_month
                         , iv_token_name3  => cv_tkn_column
                         , iv_token_value3 => gv_sales_discount
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          ov_retcode := cv_status_check;
        END IF;
        --
        -- 小数点以下チェック
        IF MOD(ABS(in_value1), 1) > 0 THEN
          --小数点以下を指定できません
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcsm_appl_short_name    -- アプリケーション短縮名
                       , iv_name         => cv_msg_decimal_point_err    -- メッセージコード
                       , iv_token_name1  => cv_tkn_plan_kind
                       , iv_token_value1 => iv_plan_kind
                       , iv_token_name2  => cv_tkn_month
                       , iv_token_value2 => iv_month
                       , iv_token_name3  => cv_tkn_column
                       , iv_token_value3 => gv_sales_discount
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          ov_retcode := cv_status_check;
        END IF;
        --
        -- 許容範囲チェック
        IF in_value1 < cn_min_discount THEN
          --売上値引が許容範囲を超えています
          lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application          => cv_xxcsm_appl_short_name
                        ,iv_name                 => cv_msg_value_over_err
                        ,iv_token_name1          => cv_tkn_plan_kind
                        ,iv_token_value1         => iv_plan_kind
                        ,iv_token_name2          => cv_tkn_month
                        ,iv_token_value2         => iv_month
                        ,iv_token_name3          => cv_tkn_column
                        ,iv_token_value3         => gv_sales_discount
                        ,iv_token_name4          => cv_tkn_min
                        ,iv_token_value4         => TO_CHAR(cn_min_discount)
                        ,iv_token_name5          => cv_tkn_max
                        ,iv_token_value5         => TO_CHAR(cn_max_discount)
                        ,iv_token_name6          => cv_tkn_value
                        ,iv_token_value6         => TO_CHAR(in_value1)
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          ov_retcode := cv_status_check;
        END IF;
        --
      END IF;
      --
      --入金値引チェック
      IF in_value2 IS NULL THEN
        --入金値引を指定してください
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcsm_appl_short_name    -- アプリケーション短縮名
                       , iv_name         => cv_msg_null_err             -- メッセージコード
                       , iv_token_name1  => cv_tkn_plan_kind
                       , iv_token_value1 => iv_plan_kind
                       , iv_token_name2  => cv_tkn_month
                       , iv_token_value2 => iv_month
                       , iv_token_name3  => cv_tkn_column
                       , iv_token_value3 => gv_receipt_discount
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_check;
        --
      ELSE
        -- プラス値不可チェック
        IF in_value2 > 0 THEN
          --0より大きい値は指定できません
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcsm_appl_short_name    -- アプリケーション短縮名
                         , iv_name         => cv_msg_disconut_item_err    -- メッセージコード
                         , iv_token_name1  => cv_tkn_plan_kind
                         , iv_token_value1 => iv_plan_kind
                         , iv_token_name2  => cv_tkn_month
                         , iv_token_value2 => iv_month
                         , iv_token_name3  => cv_tkn_column
                         , iv_token_value3 => gv_receipt_discount
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          ov_retcode := cv_status_check;
        END IF;
        --
        -- 小数点以下チェック
        IF MOD(ABS(in_value2), 1) > 0 THEN
          --小数点以下を指定できません
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcsm_appl_short_name    -- アプリケーション短縮名
                       , iv_name         => cv_msg_decimal_point_err    -- メッセージコード
                       , iv_token_name1  => cv_tkn_plan_kind
                       , iv_token_value1 => iv_plan_kind
                       , iv_token_name2  => cv_tkn_month
                       , iv_token_value2 => iv_month
                       , iv_token_name3  => cv_tkn_column
                       , iv_token_value3 => gv_receipt_discount
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          ov_retcode := cv_status_check;
        END IF;
        --
        -- 許容範囲チェック
        IF in_value2 < cn_min_discount THEN
          --入金値引が許容範囲を超えています
          lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application          => cv_xxcsm_appl_short_name
                        ,iv_name                 => cv_msg_value_over_err
                        ,iv_token_name1          => cv_tkn_plan_kind
                        ,iv_token_value1         => iv_plan_kind
                        ,iv_token_name2          => cv_tkn_month
                        ,iv_token_value2         => iv_month
                        ,iv_token_name3          => cv_tkn_column
                        ,iv_token_value3         => gv_receipt_discount
                        ,iv_token_name4          => cv_tkn_min
                        ,iv_token_value4         => TO_CHAR(cn_min_discount)
                        ,iv_token_name5          => cv_tkn_max
                        ,iv_token_value5         => TO_CHAR(cn_max_discount)
                        ,iv_token_name6          => cv_tkn_value
                        ,iv_token_value6         => TO_CHAR(in_value2)
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          ov_retcode := cv_status_check;
        END IF;
        --
      END IF;
      --
      --売上予算チェック
      IF in_value3 IS NULL THEN
        --売上予算を指定してください
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcsm_appl_short_name    -- アプリケーション短縮名
                       , iv_name         => cv_msg_null_err             -- メッセージコード
                       , iv_token_name1  => cv_tkn_plan_kind
                       , iv_token_value1 => iv_plan_kind
                       , iv_token_name2  => cv_tkn_month
                       , iv_token_value2 => iv_month
                       , iv_token_name3  => cv_tkn_column
                       , iv_token_value3 => gv_sales_budget
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_check;
        --
      ELSE
        -- 売上予算マイナス不可チェック
        IF in_value3 < 0 THEN
          --売上予算は0以上を設定してください
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcsm_appl_short_name    -- アプリケーション短縮名
                         , iv_name         => cv_msg_sales_budget_err     -- メッセージコード
                         , iv_token_name1  => cv_tkn_plan_kind
                         , iv_token_value1 => iv_plan_kind
                         , iv_token_name2  => cv_tkn_month
                         , iv_token_value2 => iv_month
                         , iv_token_name3  => cv_tkn_column
                         , iv_token_value3 => gv_sales_budget
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          ov_retcode := cv_status_check;
        END IF;
        --
        -- 売上予算小数点以下チェック
        IF MOD(in_value3, 1) > 0 THEN
          --売上予算は小数点以下を指定できません
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcsm_appl_short_name    -- アプリケーション短縮名
                       , iv_name         => cv_msg_decimal_point_err    -- メッセージコード
                       , iv_token_name1  => cv_tkn_plan_kind
                       , iv_token_value1 => iv_plan_kind
                       , iv_token_name2  => cv_tkn_month
                       , iv_token_value2 => iv_month
                       , iv_token_name3  => cv_tkn_column
                       , iv_token_value3 => gv_sales_budget
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          ov_retcode := cv_status_check;
          --
        END IF;
        --
      END IF;
      --
    ELSE
      -------------------------------------------------
      -- 2.商品群の予算値チェック
      -------------------------------------------------
      --売上チェック
      IF in_value1 IS NULL THEN
        --売上を指定してください
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcsm_appl_short_name    -- アプリケーション短縮名
                       , iv_name         => cv_msg_null_err             -- メッセージコード
                       , iv_token_name1  => cv_tkn_plan_kind
                       , iv_token_value1 => iv_plan_kind
                       , iv_token_name2  => cv_tkn_month
                       , iv_token_value2 => iv_month
                       , iv_token_name3  => cv_tkn_column
                       , iv_token_value3 => gv_item_sales_budget
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_check;
        --
      ELSE
        -- 売上マイナス不可チェック
        IF in_value1 < 0 THEN
          --売上は0以上を設定してください
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcsm_appl_short_name    -- アプリケーション短縮名
                         , iv_name         => cv_msg_sales_budget_err     -- メッセージコード
                         , iv_token_name1  => cv_tkn_plan_kind
                         , iv_token_value1 => iv_plan_kind
                         , iv_token_name2  => cv_tkn_month
                         , iv_token_value2 => iv_month
                         , iv_token_name3  => cv_tkn_column
                         , iv_token_value3 => gv_item_sales_budget
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          ov_retcode := cv_status_check;
        END IF;
        --
        -- 売上小数点以下チェック
        IF MOD(in_value1, 1) > 0 THEN
          --売上は小数点以下を指定できません
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcsm_appl_short_name    -- アプリケーション短縮名
                       , iv_name         => cv_msg_decimal_point_err    -- メッセージコード
                       , iv_token_name1  => cv_tkn_plan_kind
                       , iv_token_value1 => iv_plan_kind
                       , iv_token_name2  => cv_tkn_month
                       , iv_token_value2 => iv_month
                       , iv_token_name3  => cv_tkn_column
                       , iv_token_value3 => gv_item_sales_budget
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          ov_retcode := cv_status_check;
          --
        END IF;
      --
      END IF;
      --
      --粗利額、粗利率
      SELECT NVL2(in_value2, 1, 0) + NVL2(in_value3, 1, 0)  AS rec_cnt
      INTO  ln_cnt
      FROM  dual
      ;
      IF ln_cnt = 1 THEN
        IF in_value2 IS NOT NULL THEN
          -- 粗利額小数点以下チェック
          IF MOD(in_value2, 1) > 0 THEN
            --粗利額は小数点以下を指定できません
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcsm_appl_short_name    -- アプリケーション短縮名
                         , iv_name         => cv_msg_decimal_point_err    -- メッセージコード
                         , iv_token_name1  => cv_tkn_plan_kind
                         , iv_token_value1 => iv_plan_kind
                         , iv_token_name2  => cv_tkn_month
                         , iv_token_value2 => iv_month
                         , iv_token_name3  => cv_tkn_column
                         , iv_token_value3 => gv_amount_gross_margin
                         );
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
            ov_retcode := cv_status_check;
          END IF;
          --
        END IF;
        --
      ELSE
        -- 1項目指定チェック
        --粗利額、粗利率はいずれか1項目を設定してください
        lv_out_msg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_xxcsm_appl_short_name
                       ,iv_name                 => cv_msg_multi_designation_err
                       ,iv_token_name1          => cv_tkn_plan_kind
                       ,iv_token_value1         => iv_plan_kind
                       ,iv_token_name2          => cv_tkn_month
                       ,iv_token_value2         => iv_month
                      );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_out_msg
        );
        ov_retcode := cv_status_check;
      END IF;
      --
    END IF;
    --
  EXCEPTION
    ----------------------------------------------------------
    -- 共通関数OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||'商品群='||iv_plan_kind||' 月='||iv_month||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  --
  END chk_budget_value;
--
  /**********************************************************************************
   * Procedure Name   : chk_budget_item
   * Description      : 予算項目チェック処理(A-11)
   ***********************************************************************************/
  PROCEDURE chk_budget_item(
     ov_errbuf     OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT VARCHAR2  -- リターン・コード             --# 固定 #
    ,ov_errmsg     OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_budget_item'; -- プログラム名
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
    ln_max_column           NUMBER;
    lv_month                VARCHAR(100);
    lv_plan_kind            VARCHAR(100);
    ln_value1               NUMBER;
    ln_value2               NUMBER;
    ln_value3               NUMBER;
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
    <<chk_budget_value_loop>>
    FOR i IN 1.. gn_target_cnt LOOP
      IF MOD(i, 3) <> 1 THEN
        CONTINUE;
      END IF;
      --
      -- ***********************************
      -- ***  予算値チェック
      -- ***********************************
      IF i < 4 THEN
        ln_max_column := 12;
      ELSE
        ln_max_column := 13;
      END IF;
      --
      FOR j IN 1..ln_max_column LOOP
        IF j = 1 THEN
          ln_value1 := gr_plan_tmps_tab(i).plan_may;      -- 売上値引 or 売上
          ln_value2 := gr_plan_tmps_tab(i + 1).plan_may;  -- 入金値引 or 粗利額
          ln_value3 := gr_plan_tmps_tab(i + 2).plan_may;  -- 売上予算 or 粗利率
        ELSIF j = 2 THEN
          ln_value1 := gr_plan_tmps_tab(i).plan_jun;
          ln_value2 := gr_plan_tmps_tab(i + 1).plan_jun;
          ln_value3 := gr_plan_tmps_tab(i + 2).plan_jun;
        ELSIF j = 3 THEN
          ln_value1 := gr_plan_tmps_tab(i).plan_jul;
          ln_value2 := gr_plan_tmps_tab(i + 1).plan_jul;
          ln_value3 := gr_plan_tmps_tab(i + 2).plan_jul;
        ELSIF j = 4 THEN
          ln_value1 := gr_plan_tmps_tab(i).plan_aug;
          ln_value2 := gr_plan_tmps_tab(i + 1).plan_aug;
          ln_value3 := gr_plan_tmps_tab(i + 2).plan_aug;
        ELSIF j = 5 THEN
          ln_value1 := gr_plan_tmps_tab(i).plan_sep;
          ln_value2 := gr_plan_tmps_tab(i + 1).plan_sep;
          ln_value3 := gr_plan_tmps_tab(i + 2).plan_sep;
        ELSIF j = 6 THEN
          ln_value1 := gr_plan_tmps_tab(i).plan_oct;
          ln_value2 := gr_plan_tmps_tab(i + 1).plan_oct;
          ln_value3 := gr_plan_tmps_tab(i + 2).plan_oct;
        ELSIF j = 7 THEN
          ln_value1 := gr_plan_tmps_tab(i).plan_nov;
          ln_value2 := gr_plan_tmps_tab(i + 1).plan_nov;
          ln_value3 := gr_plan_tmps_tab(i + 2).plan_nov;
        ELSIF j = 8 THEN
          ln_value1 := gr_plan_tmps_tab(i).plan_dec;
          ln_value2 := gr_plan_tmps_tab(i + 1).plan_dec;
          ln_value3 := gr_plan_tmps_tab(i + 2).plan_dec;
        ELSIF j = 9 THEN
          ln_value1 := gr_plan_tmps_tab(i).plan_jan;
          ln_value2 := gr_plan_tmps_tab(i + 1).plan_jan;
          ln_value3 := gr_plan_tmps_tab(i + 2).plan_jan;
        ELSIF j = 10 THEN
          ln_value1 := gr_plan_tmps_tab(i).plan_feb;
          ln_value2 := gr_plan_tmps_tab(i + 1).plan_feb;
          ln_value3 := gr_plan_tmps_tab(i + 2).plan_feb;
        ELSIF j = 11 THEN
          ln_value1 := gr_plan_tmps_tab(i).plan_mar;
          ln_value2 := gr_plan_tmps_tab(i + 1).plan_mar;
          ln_value3 := gr_plan_tmps_tab(i + 2).plan_mar;
        ELSIF j = 12 THEN
          ln_value1 := gr_plan_tmps_tab(i).plan_apr;
          ln_value2 := gr_plan_tmps_tab(i + 1).plan_apr;
          ln_value3 := gr_plan_tmps_tab(i + 2).plan_apr;
        ELSIF j = 13 THEN
          ln_value1 := gr_plan_tmps_tab(i).plan_sum;
          ln_value2 := gr_plan_tmps_tab(i + 1).plan_sum;
          ln_value3 := gr_plan_tmps_tab(i + 2).plan_sum;
        END IF;
        --
        IF j = 13 THEN
          lv_month := cv_sum;
        ELSE
          lv_month := TO_CHAR(ADD_MONTHS(gd_start_date, j - 1),'MM');
        END IF;
        lv_plan_kind := gr_plan_tmps_tab(i).plan_kind;
        -------------------------------------------------
        -- 6-1.予算値チェック
        -------------------------------------------------
        chk_budget_value(
          ov_errbuf               => lv_errbuf          -- エラー・メッセージ
         ,ov_retcode              => lv_retcode         -- リターン・コード
         ,ov_errmsg               => lv_errmsg          -- ユーザー・エラー・メッセージ
         ,iv_plan_kind            => lv_plan_kind       -- 拠点計 or 商品群
         ,iv_month                => lv_month
         ,in_value1               => ln_value1          -- 売上予算 or 売上
         ,in_value2               => ln_value2          -- 入金値引 or 粗利額
         ,in_value3               => ln_value3          -- 売上値引 or 粗利率
        );
        -- ステータスエラー判定
        IF ( lv_retcode = cv_status_check ) THEN
          ov_retcode := cv_status_check;
        ELSIF ( lv_retcode = cv_status_error ) THEN
          RAISE global_api_expt;
        END IF;
        --
      END LOOP;
      --
    END LOOP chk_budget_value_loop;
    --
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||'商品群='||lv_plan_kind||' 月='||lv_month||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END chk_budget_item;
--
  /**********************************************************************************
   * Procedure Name   : ins_plan_headers
   * Description      : 商品計画ヘッダ登録処理(A-12)
   ***********************************************************************************/
  PROCEDURE ins_plan_headers(
     ov_errbuf     OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT VARCHAR2  -- リターン・コード             --# 固定 #
    ,ov_errmsg     OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_plan_headers'; -- プログラム名
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
    -------------------------------------------------
    -- 1.商品計画ヘッダID取得
    -------------------------------------------------
    BEGIN
      SELECT xiph.item_plan_header_id  AS item_plan_header_id
      INTO   gt_item_plan_header_id
      FROM   xxcsm_item_plan_headers xiph
      WHERE  xiph.plan_year = gr_plan_tmps_tab(1).plan_year
      AND    xiph.location_cd = gr_plan_tmps_tab(1).base_code
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
    --
    -------------------------------------------------
    -- 2.商品計画ヘッダ登録
    -------------------------------------------------
    IF gt_item_plan_header_id IS NULL THEN
      gt_item_plan_header_id := xxcsm_item_plan_header_s01.NEXTVAL;
      --
      INSERT INTO xxcsm_item_plan_headers(
        item_plan_header_id                 --商品計画ヘッダID
       ,plan_year                           --予算年度
       ,location_cd                         --拠点コード
       ,created_by                          --作成者
       ,creation_date                       --作成日
       ,last_updated_by                     --最終更新者
       ,last_update_date                    --最終更新日
       ,last_update_login                   --最終更新ログイン
       ,request_id                          --要求ID
       ,program_application_id              --コンカレント・プログラム・アプリケーションID
       ,program_id                          --コンカレント・プログラムID
       ,program_update_date                 --プログラム更新日
      ) VALUES (
        gt_item_plan_header_id              --商品計画ヘッダID
       ,gr_plan_tmps_tab(1).plan_year       --予算年度
       ,gr_plan_tmps_tab(1).base_code       --拠点コード
       ,cn_created_by                       --作成者
       ,cd_creation_date                    --作成日
       ,cn_last_updated_by                  --最終更新者
       ,cd_last_update_date                 --最終更新日
       ,cn_last_update_login                --最終更新ログイン
       ,cn_request_id                       --要求ID
       ,cn_program_application_id           --コンカレント・プログラム・アプリケーションID
       ,cn_program_id                       --コンカレント・プログラムID
       ,cd_program_update_date              --プログラム更新日
      );
      --
    END IF;
    --
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
  END ins_plan_headers;
--
  /**********************************************************************************
   * Procedure Name   : ins_plan_loc_bdgt
   * Description      : 拠点予算登録・更新処理(A-13)
   ***********************************************************************************/
  PROCEDURE ins_plan_loc_bdgt(
     ov_errbuf     OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT VARCHAR2  -- リターン・コード             --# 固定 #
    ,ov_errmsg     OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_plan_loc_bdgt'; -- プログラム名
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
    --商品計画拠点別予算登録用
    TYPE t_item_plan_loc_bdgt_ttype IS TABLE OF xxcsm_item_plan_loc_bdgt%ROWTYPE INDEX BY BINARY_INTEGER;
    l_item_plan_loc_bdgt_tab            t_item_plan_loc_bdgt_ttype;
    lv_tab_name                 VARCHAR2(500);   --テーブル名
--
    -- *** ローカル・カーソル ***
    -- 商品計画拠点別予算テーブル行ロック
    CURSOR cur_lock_item_plan_loc_bdgt IS
      SELECT NULL                        AS item_plan_header_id
            ,xipb.item_plan_loc_bdgt_id  AS item_plan_loc_bdgt_id
            ,NULL                        AS year_month
            ,xipb.month_no               AS month_no
            ,xipb.sales_discount         AS sales_discount
            ,xipb.receipt_discount       AS receipt_discount
            ,xipb.sales_budget           AS sales_budget
            ,NULL                        AS created_by
            ,NULL                        AS creation_date
            ,NULL                        AS last_updated_by
            ,NULL                        AS last_update_date
            ,NULL                        AS last_update_login
            ,NULL                        AS request_id
            ,NULL                        AS program_application_id
            ,NULL                        AS program_id
            ,NULL                        AS program_update_date
      FROM   xxcsm_item_plan_loc_bdgt  xipb
      WHERE  xipb.item_plan_header_id = gt_item_plan_header_id
      FOR UPDATE NOWAIT
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
    -------------------------------------------------
    -- 1.商品計画拠点別予算取得およびロック
    -------------------------------------------------
    OPEN cur_lock_item_plan_loc_bdgt;
    FETCH cur_lock_item_plan_loc_bdgt BULK COLLECT INTO l_item_plan_loc_bdgt_tab;
    CLOSE cur_lock_item_plan_loc_bdgt;
    --
    -- 商品計画拠点別予算登録・更新
    IF l_item_plan_loc_bdgt_tab.COUNT = 0 THEN
      -------------------------------------------------
      -- 2.商品計画拠点別予算登録
      -------------------------------------------------
      FOR i IN 1..12 LOOP
        l_item_plan_loc_bdgt_tab(i).item_plan_header_id    := gt_item_plan_header_id;                                        --商品計画ヘッダID
        l_item_plan_loc_bdgt_tab(i).item_plan_loc_bdgt_id  := xxcsm_item_plan_bdgt_s01.NEXTVAL;                              --商品計画拠点別ID
        l_item_plan_loc_bdgt_tab(i).year_month             := TO_NUMBER(TO_CHAR(ADD_MONTHS(gd_start_date, i - 1),'YYYYMM')); --年月
        l_item_plan_loc_bdgt_tab(i).month_no               := TO_NUMBER(TO_CHAR(ADD_MONTHS(gd_start_date, i - 1),'MM'));     --月
        IF i = 1 THEN
          l_item_plan_loc_bdgt_tab(i).sales_discount       := gr_plan_tmps_tab(1).plan_may * 1000;  --売上値引
          l_item_plan_loc_bdgt_tab(i).receipt_discount     := gr_plan_tmps_tab(2).plan_may * 1000;  --入金値引
          l_item_plan_loc_bdgt_tab(i).sales_budget         := gr_plan_tmps_tab(3).plan_may * 1000;  --売上予算
        ELSIF i = 2 THEN
          l_item_plan_loc_bdgt_tab(i).sales_discount       := gr_plan_tmps_tab(1).plan_jun * 1000;  --売上値引
          l_item_plan_loc_bdgt_tab(i).receipt_discount     := gr_plan_tmps_tab(2).plan_jun * 1000;  --入金値引
          l_item_plan_loc_bdgt_tab(i).sales_budget         := gr_plan_tmps_tab(3).plan_jun * 1000;  --売上予算
        ELSIF i = 3 THEN
          l_item_plan_loc_bdgt_tab(i).sales_discount       := gr_plan_tmps_tab(1).plan_jul * 1000;  --売上値引
          l_item_plan_loc_bdgt_tab(i).receipt_discount     := gr_plan_tmps_tab(2).plan_jul * 1000;  --入金値引
          l_item_plan_loc_bdgt_tab(i).sales_budget         := gr_plan_tmps_tab(3).plan_jul * 1000;  --売上予算
        ELSIF i = 4 THEN
          l_item_plan_loc_bdgt_tab(i).sales_discount       := gr_plan_tmps_tab(1).plan_aug * 1000;  --売上値引
          l_item_plan_loc_bdgt_tab(i).receipt_discount     := gr_plan_tmps_tab(2).plan_aug * 1000;  --入金値引
          l_item_plan_loc_bdgt_tab(i).sales_budget         := gr_plan_tmps_tab(3).plan_aug * 1000;  --売上予算
        ELSIF i = 5 THEN
          l_item_plan_loc_bdgt_tab(i).sales_discount       := gr_plan_tmps_tab(1).plan_sep * 1000;  --売上値引
          l_item_plan_loc_bdgt_tab(i).receipt_discount     := gr_plan_tmps_tab(2).plan_sep * 1000;  --入金値引
          l_item_plan_loc_bdgt_tab(i).sales_budget         := gr_plan_tmps_tab(3).plan_sep * 1000;  --売上予算
        ELSIF i = 6 THEN
          l_item_plan_loc_bdgt_tab(i).sales_discount       := gr_plan_tmps_tab(1).plan_oct * 1000;  --売上値引
          l_item_plan_loc_bdgt_tab(i).receipt_discount     := gr_plan_tmps_tab(2).plan_oct * 1000;  --入金値引
          l_item_plan_loc_bdgt_tab(i).sales_budget         := gr_plan_tmps_tab(3).plan_oct * 1000;  --売上予算
        ELSIF i = 7 THEN
          l_item_plan_loc_bdgt_tab(i).sales_discount       := gr_plan_tmps_tab(1).plan_nov * 1000;  --売上値引
          l_item_plan_loc_bdgt_tab(i).receipt_discount     := gr_plan_tmps_tab(2).plan_nov * 1000;  --入金値引
          l_item_plan_loc_bdgt_tab(i).sales_budget         := gr_plan_tmps_tab(3).plan_nov * 1000;  --売上予算
        ELSIF i = 8 THEN
          l_item_plan_loc_bdgt_tab(i).sales_discount       := gr_plan_tmps_tab(1).plan_dec * 1000;  --売上値引
          l_item_plan_loc_bdgt_tab(i).receipt_discount     := gr_plan_tmps_tab(2).plan_dec * 1000;  --入金値引
          l_item_plan_loc_bdgt_tab(i).sales_budget         := gr_plan_tmps_tab(3).plan_dec * 1000;  --売上予算
        ELSIF i = 9 THEN
          l_item_plan_loc_bdgt_tab(i).sales_discount       := gr_plan_tmps_tab(1).plan_jan * 1000;  --売上値引
          l_item_plan_loc_bdgt_tab(i).receipt_discount     := gr_plan_tmps_tab(2).plan_jan * 1000;  --入金値引
          l_item_plan_loc_bdgt_tab(i).sales_budget         := gr_plan_tmps_tab(3).plan_jan * 1000;  --売上予算
        ELSIF i = 10 THEN
          l_item_plan_loc_bdgt_tab(i).sales_discount       := gr_plan_tmps_tab(1).plan_feb * 1000;  --売上値引
          l_item_plan_loc_bdgt_tab(i).receipt_discount     := gr_plan_tmps_tab(2).plan_feb * 1000;  --入金値引
          l_item_plan_loc_bdgt_tab(i).sales_budget         := gr_plan_tmps_tab(3).plan_feb * 1000;  --売上予算
        ELSIF i = 11 THEN
          l_item_plan_loc_bdgt_tab(i).sales_discount       := gr_plan_tmps_tab(1).plan_mar * 1000;  --売上値引
          l_item_plan_loc_bdgt_tab(i).receipt_discount     := gr_plan_tmps_tab(2).plan_mar * 1000;  --入金値引
          l_item_plan_loc_bdgt_tab(i).sales_budget         := gr_plan_tmps_tab(3).plan_mar * 1000;  --売上予算
        ELSIF i = 12 THEN
          l_item_plan_loc_bdgt_tab(i).sales_discount       := gr_plan_tmps_tab(1).plan_apr * 1000;  --売上値引
          l_item_plan_loc_bdgt_tab(i).receipt_discount     := gr_plan_tmps_tab(2).plan_apr * 1000;  --入金値引
          l_item_plan_loc_bdgt_tab(i).sales_budget         := gr_plan_tmps_tab(3).plan_apr * 1000;  --売上予算
        END IF;
        --who
        l_item_plan_loc_bdgt_tab(i).created_by             := cn_created_by;                  --作成者
        l_item_plan_loc_bdgt_tab(i).creation_date          := cd_creation_date;               --作成日
        l_item_plan_loc_bdgt_tab(i).last_updated_by        := cn_last_updated_by;             --最終更新者
        l_item_plan_loc_bdgt_tab(i).last_update_date       := cd_last_update_date;            --最終更新日
        l_item_plan_loc_bdgt_tab(i).last_update_login      := cn_last_update_login;           --最終更新ログイン
        l_item_plan_loc_bdgt_tab(i).request_id             := cn_request_id;                  --要求ID
        l_item_plan_loc_bdgt_tab(i).program_application_id := cn_program_application_id;      --コンカレント・プログラム・アプリケーションID
        l_item_plan_loc_bdgt_tab(i).program_id             := cn_program_id;                  --コンカレント・プログラムID
        l_item_plan_loc_bdgt_tab(i).program_update_date    := cd_program_update_date;         --プログラム更新日
      END LOOP;
      --
      FORALL i in 1..12
        INSERT INTO xxcsm_item_plan_loc_bdgt VALUES l_item_plan_loc_bdgt_tab(i);
      --
    ELSE
      -------------------------------------------------
      -- 3.商品計画拠点別予算更新
      -------------------------------------------------
      FOR i IN 1..l_item_plan_loc_bdgt_tab.COUNT LOOP
        IF l_item_plan_loc_bdgt_tab(i).month_no = cn_month_no_5 THEN
          l_item_plan_loc_bdgt_tab(i).sales_discount       := gr_plan_tmps_tab(1).plan_may * 1000;  --売上値引
          l_item_plan_loc_bdgt_tab(i).receipt_discount     := gr_plan_tmps_tab(2).plan_may * 1000;  --入金値引
          l_item_plan_loc_bdgt_tab(i).sales_budget         := gr_plan_tmps_tab(3).plan_may * 1000;  --売上予算
        ELSIF l_item_plan_loc_bdgt_tab(i).month_no = cn_month_no_6 THEN
          l_item_plan_loc_bdgt_tab(i).sales_discount       := gr_plan_tmps_tab(1).plan_jun * 1000;  --売上値引
          l_item_plan_loc_bdgt_tab(i).receipt_discount     := gr_plan_tmps_tab(2).plan_jun * 1000;  --入金値引
          l_item_plan_loc_bdgt_tab(i).sales_budget         := gr_plan_tmps_tab(3).plan_jun * 1000;  --売上予算
        ELSIF l_item_plan_loc_bdgt_tab(i).month_no = cn_month_no_7 THEN
          l_item_plan_loc_bdgt_tab(i).sales_discount       := gr_plan_tmps_tab(1).plan_jul * 1000;  --売上値引
          l_item_plan_loc_bdgt_tab(i).receipt_discount     := gr_plan_tmps_tab(2).plan_jul * 1000;  --入金値引
          l_item_plan_loc_bdgt_tab(i).sales_budget         := gr_plan_tmps_tab(3).plan_jul * 1000;  --売上予算
        ELSIF l_item_plan_loc_bdgt_tab(i).month_no = cn_month_no_8 THEN
          l_item_plan_loc_bdgt_tab(i).sales_discount       := gr_plan_tmps_tab(1).plan_aug * 1000;  --売上値引
          l_item_plan_loc_bdgt_tab(i).receipt_discount     := gr_plan_tmps_tab(2).plan_aug * 1000;  --入金値引
          l_item_plan_loc_bdgt_tab(i).sales_budget         := gr_plan_tmps_tab(3).plan_aug * 1000;  --売上予算
        ELSIF l_item_plan_loc_bdgt_tab(i).month_no = cn_month_no_9 THEN
          l_item_plan_loc_bdgt_tab(i).sales_discount       := gr_plan_tmps_tab(1).plan_sep * 1000;  --売上値引
          l_item_plan_loc_bdgt_tab(i).receipt_discount     := gr_plan_tmps_tab(2).plan_sep * 1000;  --入金値引
          l_item_plan_loc_bdgt_tab(i).sales_budget         := gr_plan_tmps_tab(3).plan_sep * 1000;  --売上予算
        ELSIF l_item_plan_loc_bdgt_tab(i).month_no = cn_month_no_10 THEN
          l_item_plan_loc_bdgt_tab(i).sales_discount       := gr_plan_tmps_tab(1).plan_oct * 1000;  --売上値引
          l_item_plan_loc_bdgt_tab(i).receipt_discount     := gr_plan_tmps_tab(2).plan_oct * 1000;  --入金値引
          l_item_plan_loc_bdgt_tab(i).sales_budget         := gr_plan_tmps_tab(3).plan_oct * 1000;  --売上予算
        ELSIF l_item_plan_loc_bdgt_tab(i).month_no = cn_month_no_11 THEN
          l_item_plan_loc_bdgt_tab(i).sales_discount       := gr_plan_tmps_tab(1).plan_nov * 1000;  --売上値引
          l_item_plan_loc_bdgt_tab(i).receipt_discount     := gr_plan_tmps_tab(2).plan_nov * 1000;  --入金値引
          l_item_plan_loc_bdgt_tab(i).sales_budget         := gr_plan_tmps_tab(3).plan_nov * 1000;  --売上予算
        ELSIF l_item_plan_loc_bdgt_tab(i).month_no = cn_month_no_12 THEN
          l_item_plan_loc_bdgt_tab(i).sales_discount       := gr_plan_tmps_tab(1).plan_dec * 1000;  --売上値引
          l_item_plan_loc_bdgt_tab(i).receipt_discount     := gr_plan_tmps_tab(2).plan_dec * 1000;  --入金値引
          l_item_plan_loc_bdgt_tab(i).sales_budget         := gr_plan_tmps_tab(3).plan_dec * 1000;  --売上予算
        ELSIF l_item_plan_loc_bdgt_tab(i).month_no = cn_month_no_1 THEN
          l_item_plan_loc_bdgt_tab(i).sales_discount       := gr_plan_tmps_tab(1).plan_jan * 1000;  --売上値引
          l_item_plan_loc_bdgt_tab(i).receipt_discount     := gr_plan_tmps_tab(2).plan_jan * 1000;  --入金値引
          l_item_plan_loc_bdgt_tab(i).sales_budget         := gr_plan_tmps_tab(3).plan_jan * 1000;  --売上予算
        ELSIF l_item_plan_loc_bdgt_tab(i).month_no = cn_month_no_2 THEN
          l_item_plan_loc_bdgt_tab(i).sales_discount       := gr_plan_tmps_tab(1).plan_feb * 1000;  --売上値引
          l_item_plan_loc_bdgt_tab(i).receipt_discount     := gr_plan_tmps_tab(2).plan_feb * 1000;  --入金値引
          l_item_plan_loc_bdgt_tab(i).sales_budget         := gr_plan_tmps_tab(3).plan_feb * 1000;  --売上予算
        ELSIF l_item_plan_loc_bdgt_tab(i).month_no = cn_month_no_3 THEN
          l_item_plan_loc_bdgt_tab(i).sales_discount       := gr_plan_tmps_tab(1).plan_mar * 1000;  --売上値引
          l_item_plan_loc_bdgt_tab(i).receipt_discount     := gr_plan_tmps_tab(2).plan_mar * 1000;  --入金値引
          l_item_plan_loc_bdgt_tab(i).sales_budget         := gr_plan_tmps_tab(3).plan_mar * 1000;  --売上予算
        ELSIF l_item_plan_loc_bdgt_tab(i).month_no = cn_month_no_4 THEN
          l_item_plan_loc_bdgt_tab(i).sales_discount       := gr_plan_tmps_tab(1).plan_apr * 1000;  --売上値引
          l_item_plan_loc_bdgt_tab(i).receipt_discount     := gr_plan_tmps_tab(2).plan_apr * 1000;  --入金値引
          l_item_plan_loc_bdgt_tab(i).sales_budget         := gr_plan_tmps_tab(3).plan_apr * 1000;  --売上予算
        END IF;
        --who
        l_item_plan_loc_bdgt_tab(i).last_updated_by        := cn_last_updated_by;             --最終更新者
        l_item_plan_loc_bdgt_tab(i).last_update_date       := cd_last_update_date;            --最終更新日
        l_item_plan_loc_bdgt_tab(i).last_update_login      := cn_last_update_login;           --最終更新ログイン
        l_item_plan_loc_bdgt_tab(i).request_id             := cn_request_id;                  --要求ID
        l_item_plan_loc_bdgt_tab(i).program_application_id := cn_program_application_id;      --コンカレント・プログラム・アプリケーションID
        l_item_plan_loc_bdgt_tab(i).program_id             := cn_program_id;                  --コンカレント・プログラムID
        l_item_plan_loc_bdgt_tab(i).program_update_date    := cd_program_update_date;         --プログラム更新日
      END LOOP;
      -------------------------------------------------
      -- 5.商品計画拠点別予算更新
      -------------------------------------------------
      FORALL i in 1..l_item_plan_loc_bdgt_tab.COUNT
        UPDATE xxcsm_item_plan_loc_bdgt
        SET sales_discount         = l_item_plan_loc_bdgt_tab(i).sales_discount          --売上値引
           ,receipt_discount       = l_item_plan_loc_bdgt_tab(i).receipt_discount        --入金値引
           ,sales_budget           = l_item_plan_loc_bdgt_tab(i).sales_budget            --売上予算
           ,last_updated_by        = l_item_plan_loc_bdgt_tab(i).last_updated_by         --最終更新者
           ,last_update_date       = l_item_plan_loc_bdgt_tab(i).last_update_date        --最終更新日
           ,last_update_login      = l_item_plan_loc_bdgt_tab(i).last_update_login       --最終更新ログイン
           ,request_id             = l_item_plan_loc_bdgt_tab(i).request_id              --要求ID
           ,program_application_id = l_item_plan_loc_bdgt_tab(i).program_application_id  --コンカレント・プログラム・アプリケーションID
           ,program_id             = l_item_plan_loc_bdgt_tab(i).program_id              --コンカレント・プログラムID
           ,program_update_date    = l_item_plan_loc_bdgt_tab(i).program_update_date     --プログラム更新日
        WHERE item_plan_loc_bdgt_id = l_item_plan_loc_bdgt_tab(i).item_plan_loc_bdgt_id   --商品計画拠点別ID
        ;
    END IF;
--
  EXCEPTION
    --*** ロック取得エラーハンドラ ***
    WHEN global_data_lock_expt THEN
      lv_tab_name := xxccp_common_pkg.get_msg(
                               iv_application => cv_xxcsm_appl_short_name
                              ,iv_name        => cv_msg_item_plan_loc_bdgt
                             );
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcsm_appl_short_name
                    ,iv_name         => cv_msg_get_lock_err
                    ,iv_token_name1  => cv_tkn_table
                    ,iv_token_value1 => lv_tab_name
                  );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_plan_loc_bdgt;
--
  /**********************************************************************************
   * Procedure Name   : calc_budget_item
   * Description      : 商品群予算値算出
   ***********************************************************************************/
  PROCEDURE calc_budget_item(
     ov_errbuf               OUT VARCHAR2    -- エラー・メッセージ
    ,ov_retcode              OUT VARCHAR2    -- リターン・コード
    ,ov_errmsg               OUT VARCHAR2    -- ユーザー・エラー・メッセージ
    ,on_sales_budget         OUT xxcsm_item_plan_lines.sales_budget%TYPE          -- 算出結果_売上(単位：円)
    ,on_amount_gross_margin  OUT xxcsm_item_plan_lines.amount_gross_margin%TYPE   -- 算出結果_粗利額(単位：円)
    ,on_margin_rate          OUT xxcsm_item_plan_lines.margin_rate%TYPE           -- 算出結果_粗利率
    ,iv_item_group_no        IN  VARCHAR2    -- 入力_商品群
    ,iv_month                IN  VARCHAR2    -- 入力_月
    ,in_sales_budget         IN  NUMBER      -- 入力_売上(単位：千円)（必須）
    ,in_amount_gross_margin  IN  NUMBER      -- 入力_粗利額(単位：千円)
    ,in_margin_rate          IN  NUMBER      -- 入力_粗利率
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'calc_budget_item'; -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf                 VARCHAR2(5000); -- エラー・メッセージ
    lv_retcode                VARCHAR2(1);    -- リターン・コード
    lv_errmsg                 VARCHAR2(5000); -- ユーザー・エラー・メッセージ
    lv_out_msg                VARCHAR2(2000); -- メッセージ
    lb_retcode                BOOLEAN;        -- メッセージ戻り値
    lv_step                   VARCHAR2(200);
  BEGIN
  --
    -------------------------------------------------
    -- 0.初期化
    -------------------------------------------------
    ov_retcode  := cv_status_normal;
    --
    lv_step := '初期化';
    --売上(円) = 売上(千円) * 1000
    on_sales_budget := in_sales_budget * 1000;
    --
    -------------------------------------------------
    -- 1.粗利額、粗利率の算出
    -------------------------------------------------
    IF in_amount_gross_margin IS NOT NULL THEN
      -------------------------------------------------
      -- 粗利額が指定されている場合
      -------------------------------------------------
      lv_step := '粗利額指定 粗利額';
      --粗利額 = アップロード値 * 1000
      on_amount_gross_margin := in_amount_gross_margin * 1000;
      --粗利率 = ( 粗利益額 / 売上 * 100 ) の小数点第3位を四捨五入
      lv_step := '粗利額指定 粗利率';
      IF on_sales_budget = 0 THEN
        on_margin_rate := 0;
      ELSE
        BEGIN
          on_margin_rate := ROUND( ( on_amount_gross_margin / on_sales_budget * 100 ), 2);
        EXCEPTION
          WHEN VALUE_ERROR THEN
            lv_errbuf := xxccp_common_pkg.get_msg(
                             iv_application  => cv_xxcsm_appl_short_name     -- アプリケーション短縮名
                           , iv_name         => cv_msg_item_group_calc_err   -- メッセージコード
                           , iv_token_name1  => cv_tkn_plan_kind
                           , iv_token_value1 => iv_item_group_no
                           , iv_token_name2  => cv_tkn_month
                           , iv_token_value2 => iv_month
                           , iv_token_name3  => cv_tkn_errmsg
                           , iv_token_value3 => '粗利額指定 粗利率算出 > 粗利額(千円)='||TO_CHAR(on_amount_gross_margin / 1000)||' 売上(千円)='||TO_CHAR(on_sales_budget / 1000)||' エラー内容='||SQLERRM
                         );
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errbuf
            );
            ov_retcode := cv_status_check;
        END;
      END IF;
    ELSIF in_margin_rate IS NOT NULL THEN
      -------------------------------------------------
      -- 粗利率が指定されている場合
      -------------------------------------------------
      lv_step := '粗利率指定 粗利額';
      --粗利額 = ( 売上 * 粗利益率 / 100 / 1000 ) の小数点第1位を四捨五入して、単位を円に変更(×1000する)
      BEGIN
        on_amount_gross_margin := ROUND( ( on_sales_budget * in_margin_rate / 100 / 1000), 0) * 1000;
      EXCEPTION
        WHEN VALUE_ERROR THEN
          lv_errbuf := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcsm_appl_short_name     -- アプリケーション短縮名
                         , iv_name         => cv_msg_item_group_calc_err   -- メッセージコード
                         , iv_token_name1  => cv_tkn_plan_kind
                         , iv_token_value1 => iv_item_group_no
                         , iv_token_name2  => cv_tkn_month
                         , iv_token_value2 => iv_month
                         , iv_token_name3  => cv_tkn_errmsg
                         , iv_token_value3 => '粗利率指定 粗利額算出 > 売上(千円)='||TO_CHAR(on_sales_budget / 1000)||' 粗利率='||TO_CHAR(in_margin_rate)||' エラー内容='||SQLERRM
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errbuf
          );
          ov_retcode := cv_status_check;
      END;
      --
      lv_step := '粗利率指定 粗利率';
      --粗利率 = アップロード値
      on_margin_rate := in_margin_rate;
      --
    END IF;
    --
    -------------------------------------------------
    -- 2.許容範囲チェック
    -------------------------------------------------
    lv_step := '許容範囲チェック';
    --0
    IF on_sales_budget = 0 AND on_amount_gross_margin = 0 AND on_margin_rate = 0 THEN
      --全項目0はokとする
      NULL;
    ELSE
      --粗利額
      IF ( ( on_amount_gross_margin / 1000 ) < cn_min_gross ) OR ( cn_max_gross < ( on_amount_gross_margin / 1000 ) ) THEN
        --粗利額は許容範囲を超えてしまいます。
        lv_out_msg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_xxcsm_appl_short_name
                       ,iv_name                 => cv_msg_value_over_err
                       ,iv_token_name1          => cv_tkn_plan_kind
                       ,iv_token_value1         => iv_item_group_no
                       ,iv_token_name2          => cv_tkn_month
                       ,iv_token_value2         => iv_month
                       ,iv_token_name3          => cv_tkn_column
                       ,iv_token_value3         => gv_amount_gross_margin
                       ,iv_token_name4          => cv_tkn_min
                       ,iv_token_value4         => TO_CHAR(cn_min_gross)
                       ,iv_token_name5          => cv_tkn_max
                       ,iv_token_value5         => TO_CHAR(cn_max_gross)
                       ,iv_token_name6          => cv_tkn_value
                       ,iv_token_value6         => TO_CHAR(on_amount_gross_margin / 1000)
                      );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_out_msg
        );
        ov_retcode := cv_status_check;
      END IF;
      --
      --粗利率
      IF ( on_margin_rate < cn_min_rate ) OR ( cn_max_rate < on_margin_rate ) THEN
        --粗利率は許容範囲を超えてしまいます。
        lv_out_msg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_xxcsm_appl_short_name
                       ,iv_name                 => cv_msg_value_over_err
                       ,iv_token_name1          => cv_tkn_plan_kind
                       ,iv_token_value1         => iv_item_group_no
                       ,iv_token_name2          => cv_tkn_month
                       ,iv_token_value2         => iv_month
                       ,iv_token_name3          => cv_tkn_column
                       ,iv_token_value3         => gv_margin_rate
                       ,iv_token_name4          => cv_tkn_min
                       ,iv_token_value4         => TO_CHAR(cn_min_rate)
                       ,iv_token_name5          => cv_tkn_max
                       ,iv_token_value5         => TO_CHAR(cn_max_rate)
                       ,iv_token_name6          => cv_tkn_value
                       ,iv_token_value6         => TO_CHAR(on_margin_rate,'FM999999999990.09')
                      );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_out_msg
        );
        ov_retcode := cv_status_check;
      END IF;
      --
    END IF;
    --
  EXCEPTION
    ----------------------------------------------------------
    -- 共通関数OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    --
  END calc_budget_item;
  --
--
  /**********************************************************************************
   * Procedure Name   : calc_budget_new_item
   * Description      : 新商品予算値算出
   ***********************************************************************************/
  PROCEDURE calc_budget_new_item(
     ov_errbuf                   OUT VARCHAR2    -- エラー・メッセージ
    ,ov_retcode                  OUT VARCHAR2    -- リターン・コード
    ,ov_errmsg                   OUT VARCHAR2    -- ユーザー・エラー・メッセージ
    ,on_credit_rate              OUT xxcsm_item_plan_lines.credit_rate%TYPE           -- 算出結果_掛率
    ,on_amount                   OUT xxcsm_item_plan_lines.amount%TYPE                -- 算出結果_数量
    ,iv_item_group_no            IN  VARCHAR2    -- 入力_商品群
    ,iv_new_item_no              IN  VARCHAR2    -- 入力_新商品コード
    ,iv_month                    IN  VARCHAR2    -- 入力_月
    ,in_sales_budget             IN  NUMBER      -- 入力_新商品の売上(単位：円)
    ,in_amount_gross_margin      IN  NUMBER      -- 入力_新商品の粗利額(単位：円)
    ,in_new_item_discrete_cost   IN  NUMBER      -- 入力_新商品の営業原価
    ,in_new_item_fixed_price     IN  NUMBER      -- 入力_新商品の定価
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'calc_budget_new_item'; -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf      VARCHAR2(5000); -- エラー・メッセージ
    lv_retcode     VARCHAR2(1);    -- リターン・コード
    lv_errmsg      VARCHAR2(5000); -- ユーザー・エラー・メッセージ
    lv_out_msg     VARCHAR2(2000); -- メッセージ
    lb_retcode     BOOLEAN;        -- メッセージ戻り値
    lv_step        VARCHAR2(200);
    --
  BEGIN
  --
    -------------------------------------------------
    -- 0.初期化
    -------------------------------------------------
    ov_retcode  := cv_status_normal;
    --
    --新商品数量
    lv_step := '新商品の数量算出['||iv_item_group_no||' / '||iv_new_item_no||' / '||iv_month||']';
    IF in_new_item_discrete_cost = 0 THEN
      on_amount := 0;
    ELSE
      BEGIN
        --数量 = (商品群の売上 - 商品群の粗利益額) / 新商品の営業原価の小数点第2位を四捨五入
        on_amount := ROUND( ( in_sales_budget - in_amount_gross_margin ) / in_new_item_discrete_cost, 1);
      EXCEPTION
        WHEN VALUE_ERROR THEN
          lv_errbuf := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcsm_appl_short_name     -- アプリケーション短縮名
                         , iv_name         => cv_msg_new_item_calc_err     -- メッセージコード
                         , iv_token_name1  => cv_tkn_deal_cd
                         , iv_token_value1 => iv_item_group_no
                         , iv_token_name2  => cv_tkn_item_cd
                         , iv_token_value2 => iv_new_item_no
                         , iv_token_name3  => cv_tkn_month
                         , iv_token_value3 => iv_month
                         , iv_token_name4  => cv_tkn_errmsg
                         , iv_token_value4 => '新商品の数量算出 > 商品群売上(千円)='||TO_CHAR(in_sales_budget / 1000)||' 商品群粗利額(千円)='||TO_CHAR(in_amount_gross_margin / 1000)||' 新商品営業原価='||TO_CHAR(in_new_item_discrete_cost)||' エラー内容='||SQLERRM
                       );
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff   => lv_errbuf
          );
          ov_retcode := cv_status_check;
      END;
      --
    END IF;
    --
    --新商品掛率
    lv_step := '新商品の掛率算出['||iv_item_group_no||' / '||iv_new_item_no||' / '||iv_month||']';
    IF on_amount * in_new_item_fixed_price = 0 THEN
      on_credit_rate := 0;
    ELSE
      --掛率 = ( 商品群の売上 / (新商品の定価 * 新商品の数量) * 100 )の小数点第4位を四捨五入
      BEGIN
        on_credit_rate := ROUND( ( in_sales_budget / ( in_new_item_fixed_price * on_amount ) * 100 ), 3);
      EXCEPTION
        WHEN VALUE_ERROR THEN
          lv_errbuf := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcsm_appl_short_name     -- アプリケーション短縮名
                         , iv_name         => cv_msg_new_item_calc_err     -- メッセージコード
                         , iv_token_name1  => cv_tkn_deal_cd
                         , iv_token_value1 => iv_item_group_no
                         , iv_token_name2  => cv_tkn_item_cd
                         , iv_token_value2 => iv_new_item_no
                         , iv_token_name3  => cv_tkn_month
                         , iv_token_value3 => iv_month
                         , iv_token_name4  => cv_tkn_errmsg
                         , iv_token_value4 => '新商品の掛率算出 > 商品群売上(千円)='||TO_CHAR(in_sales_budget / 1000)||' 新商品定価='||TO_CHAR(in_new_item_fixed_price)||' 新商品数量='||TO_CHAR(on_amount)||' エラー内容='||SQLERRM
                       );
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff   => lv_errbuf
          );
          ov_retcode := cv_status_check;
      END;
      --
    END IF;
    --
  EXCEPTION
    ----------------------------------------------------------
    -- 共通関数OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    --
  END calc_budget_new_item;
  --
  /**********************************************************************************
   * Procedure Name   : ins_plan_line
   * Description      : 商品群予算登録・更新処理(A-14)
   ***********************************************************************************/
  PROCEDURE ins_plan_line(
     ov_errbuf     OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT VARCHAR2  -- リターン・コード             --# 固定 #
    ,ov_errmsg     OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_plan_line'; -- プログラム名
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
    --商品計画明細登録用
    TYPE t_item_plan_lines_ttype IS TABLE OF xxcsm_item_plan_lines%ROWTYPE INDEX BY BINARY_INTEGER;
    l_item_plan_lines_tab            t_item_plan_lines_ttype;
    --商品群予算算出結果退避用
    TYPE l_group_bdgt_rtype IS RECORD (
      sales_budget          xxcsm_item_plan_lines.sales_budget%TYPE
     ,amount_gross_margin   xxcsm_item_plan_lines.amount_gross_margin%TYPE
     ,margin_rate           xxcsm_item_plan_lines.margin_rate%TYPE
    );
    TYPE l_group_bdgt_ttype IS TABLE OF l_group_bdgt_rtype INDEX BY BINARY_INTEGER;
    l_group_bdgt_tab     l_group_bdgt_ttype;
    --
    --新商品予算算出結果退避用
    TYPE l_new_item_bdgt_rtype IS RECORD (
      sales_budget          xxcsm_item_plan_lines.sales_budget%TYPE
     ,amount_gross_margin   xxcsm_item_plan_lines.amount_gross_margin%TYPE
     ,credit_rate           xxcsm_item_plan_lines.credit_rate%TYPE
     ,amount                xxcsm_item_plan_lines.amount%TYPE
    );
    TYPE l_new_item_bdgt_ttype IS TABLE OF l_new_item_bdgt_rtype INDEX BY BINARY_INTEGER;
    l_new_item_bdgt_tab     l_new_item_bdgt_ttype;
    --
    ln_sales_budget                 NUMBER;
    ln_amount_gross_margin          NUMBER;
    ln_margin_rate                  NUMBER;
    ln_line_cnt                     NUMBER;
    ln_cnt                          NUMBER;
    ln_sum_sales_budget             xxcsm_item_plan_lines.sales_budget%TYPE;         --単品予算売上合計
    ln_sum_amount_gross_margin      xxcsm_item_plan_lines.amount_gross_margin%TYPE;  --単品予算粗利額合計
--
    lv_step                         VARCHAR2(200);
    lt_item_group_no                xxcsm_item_plan_lines.item_group_no%TYPE;
    lt_new_item_no                  xxcsm_item_plan_lines.item_no%TYPE;
    lv_month                        VARCHAR(100);
    lv_out_msg                      VARCHAR2(2000);  -- メッセージ
    lt_new_item_discrete_cost       xxcmm_system_items_b_hst.discrete_cost%TYPE;     --営業原価
    lt_new_item_fixed_price         xxcmm_system_items_b_hst.fixed_price%TYPE;       --定価
    lv_tab_name                     VARCHAR2(500);   --テーブル名
--
    -- *** ローカル・カーソル ***
    -- 商品計画明細テーブル行ロック
    CURSOR cur_lock_item_plan_lines IS
      SELECT NULL                          AS item_plan_header_id
            ,xipl.item_plan_lines_id       AS item_plan_lines_id
            ,NULL                          AS year_month
            ,xipl.month_no                 AS month_no
            ,NULL                          AS year_bdgt_kbn
            ,NULL                          AS item_kbn
            ,NULL                          AS item_no
            ,NULL                          AS item_group_no
            ,xipl.amount                   AS amount
            ,xipl.sales_budget             AS sales_budget
            ,xipl.amount_gross_margin      AS amount_gross_margin
            ,xipl.credit_rate              AS credit_rate
            ,xipl.margin_rate              AS margin_rate
            ,NULL                          AS created_by
            ,NULL                          AS creation_date
            ,NULL                          AS last_updated_by
            ,NULL                          AS last_update_date
            ,NULL                          AS last_update_login
            ,NULL                          AS request_id
            ,NULL                          AS program_application_id
            ,NULL                          AS program_id
            ,NULL                          AS program_update_date
      FROM   xxcsm_item_plan_lines  xipl
      WHERE  xipl.item_plan_header_id = gt_item_plan_header_id
      AND    xipl.item_group_no = lt_item_group_no
      AND    xipl.item_kbn IN (cv_item_kbn_group, cv_item_kbn_new)
      ORDER BY xipl.item_kbn
              ,xipl.month_no
      FOR UPDATE NOWAIT
    ;
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
    --
    <<ins_plan_line_loop>>
    FOR i IN 4.. gn_target_cnt LOOP  --アップロードデータループ
      IF MOD(i, 3) <> 1 THEN
        CONTINUE;
      END IF;
      --
      lt_item_group_no := gr_plan_tmps_tab(i).plan_kind;
      -------------------------------------------------
      -- 1.商品群予算算出
      -------------------------------------------------
      l_group_bdgt_tab.DELETE;
      FOR j IN 1..13 LOOP       --月別ループ
        --
        IF j = 1 THEN  --5月分
          ln_sales_budget        := gr_plan_tmps_tab(i).plan_may;
          ln_amount_gross_margin := gr_plan_tmps_tab(i + 1).plan_may;
          ln_margin_rate         := gr_plan_tmps_tab(i + 2).plan_may;
        ELSIF j = 2 THEN  --6月分
          ln_sales_budget        := gr_plan_tmps_tab(i).plan_jun;
          ln_amount_gross_margin := gr_plan_tmps_tab(i + 1).plan_jun;
          ln_margin_rate         := gr_plan_tmps_tab(i + 2).plan_jun;
        ELSIF j = 3 THEN  --7月分
          ln_sales_budget        := gr_plan_tmps_tab(i).plan_jul;
          ln_amount_gross_margin := gr_plan_tmps_tab(i + 1).plan_jul;
          ln_margin_rate         := gr_plan_tmps_tab(i + 2).plan_jul;
        ELSIF j = 4 THEN  --8月分
          ln_sales_budget        := gr_plan_tmps_tab(i).plan_aug;
          ln_amount_gross_margin := gr_plan_tmps_tab(i + 1).plan_aug;
          ln_margin_rate         := gr_plan_tmps_tab(i + 2).plan_aug;
        ELSIF j = 5 THEN  --9月分
          ln_sales_budget        := gr_plan_tmps_tab(i).plan_sep;
          ln_amount_gross_margin := gr_plan_tmps_tab(i + 1).plan_sep;
          ln_margin_rate         := gr_plan_tmps_tab(i + 2).plan_sep;
        ELSIF j = 6 THEN  --10月分
          ln_sales_budget        := gr_plan_tmps_tab(i).plan_oct;
          ln_amount_gross_margin := gr_plan_tmps_tab(i + 1).plan_oct;
          ln_margin_rate         := gr_plan_tmps_tab(i + 2).plan_oct;
        ELSIF j = 7 THEN  --11月分
          ln_sales_budget        := gr_plan_tmps_tab(i).plan_nov;
          ln_amount_gross_margin := gr_plan_tmps_tab(i + 1).plan_nov;
          ln_margin_rate         := gr_plan_tmps_tab(i + 2).plan_nov;
        ELSIF j = 8 THEN  --12月分
          ln_sales_budget        := gr_plan_tmps_tab(i).plan_dec;
          ln_amount_gross_margin := gr_plan_tmps_tab(i + 1).plan_dec;
          ln_margin_rate         := gr_plan_tmps_tab(i + 2).plan_dec;
        ELSIF j = 9 THEN  --1月分
          ln_sales_budget        := gr_plan_tmps_tab(i).plan_jan;
          ln_amount_gross_margin := gr_plan_tmps_tab(i + 1).plan_jan;
          ln_margin_rate         := gr_plan_tmps_tab(i + 2).plan_jan;
        ELSIF j = 10 THEN  --2月分
          ln_sales_budget        := gr_plan_tmps_tab(i).plan_feb;
          ln_amount_gross_margin := gr_plan_tmps_tab(i + 1).plan_feb;
          ln_margin_rate         := gr_plan_tmps_tab(i + 2).plan_feb;
        ELSIF j = 11 THEN  --3月分
          ln_sales_budget        := gr_plan_tmps_tab(i).plan_mar;
          ln_amount_gross_margin := gr_plan_tmps_tab(i + 1).plan_mar;
          ln_margin_rate         := gr_plan_tmps_tab(i + 2).plan_mar;
        ELSIF j = 12 THEN  --4月分
          ln_sales_budget        := gr_plan_tmps_tab(i).plan_apr;
          ln_amount_gross_margin := gr_plan_tmps_tab(i + 1).plan_apr;
          ln_margin_rate         := gr_plan_tmps_tab(i + 2).plan_apr;
        ELSIF j = 13 THEN  --年間計
          ln_sales_budget        := gr_plan_tmps_tab(i).plan_sum;
          ln_amount_gross_margin := gr_plan_tmps_tab(i + 1).plan_sum;
          ln_margin_rate         := gr_plan_tmps_tab(i + 2).plan_sum;
        END IF;
        --
        IF j = 13 THEN
          lv_month := cv_sum;
        ELSE
          lv_month := TO_CHAR(ADD_MONTHS(gd_start_date, j - 1),'MM');
        END IF;
        -------------------------------------------------
        -- 商品群予算項目算出
        -------------------------------------------------
        calc_budget_item(
          ov_errbuf              => lv_errbuf                                  -- エラー・メッセージ
         ,ov_retcode             => lv_retcode                                 -- リターン・コード
         ,ov_errmsg              => lv_errmsg                                  -- ユーザー・エラー・メッセージ
         ,on_sales_budget        => l_group_bdgt_tab(j).sales_budget           -- 算出結果_売上(単位：円)
         ,on_amount_gross_margin => l_group_bdgt_tab(j).amount_gross_margin    -- 算出結果_粗利額(単位：円)
         ,on_margin_rate         => l_group_bdgt_tab(j).margin_rate            -- 算出結果_粗利率
         ,iv_item_group_no       => lt_item_group_no                           -- 入力_商品群
         ,iv_month               => lv_month                                   -- 入力_月
         ,in_sales_budget        => ln_sales_budget                            -- 入力_売上(単位：千円)（必須）
         ,in_amount_gross_margin => ln_amount_gross_margin                     -- 入力_粗利額(単位：千円)
         ,in_margin_rate         => ln_margin_rate                             -- 入力_粗利率
        );
        --
        IF ( lv_retcode = cv_status_check ) THEN
          ov_retcode := cv_status_check;
        ELSIF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        --
      END LOOP;
      --
      --商品計画明細格納域初期化
      l_item_plan_lines_tab.DELETE;
      ln_line_cnt := 0;
      -------------------------------------------------
      -- 2.商品計画明細取得およびロック
      -------------------------------------------------
      OPEN cur_lock_item_plan_lines;
      FETCH cur_lock_item_plan_lines BULK COLLECT INTO l_item_plan_lines_tab;
      ln_cnt := l_item_plan_lines_tab.COUNT;
      CLOSE cur_lock_item_plan_lines;
      --
      -- 商品計画明細登録・更新
      IF ln_cnt = 0 THEN
        -------------------------------------------------
        -- 3.商品群予算未登録時の商品群予算設定
        -------------------------------------------------
        FOR j IN 1..13 LOOP       --商品群の月別ループ
          --
          --登録値設定処理
          ln_line_cnt := ln_line_cnt + 1;
          --
          l_item_plan_lines_tab(ln_line_cnt).item_plan_header_id := gt_item_plan_header_id;             --商品計画ヘッダID
          l_item_plan_lines_tab(ln_line_cnt).item_plan_lines_id  := xxcsm_item_plan_lines_s01.NEXTVAL;  --商品計画明細ID
          IF j = 13 THEN  -- 年間計
            l_item_plan_lines_tab(ln_line_cnt).year_month    := NULL;                    --年月
            l_item_plan_lines_tab(ln_line_cnt).month_no      := cn_month_no_99;          --月
            l_item_plan_lines_tab(ln_line_cnt).year_bdgt_kbn := cv_budget_kbn_year;      -- 1:年間群予算
          ELSE
            l_item_plan_lines_tab(ln_line_cnt).year_month    := TO_NUMBER(TO_CHAR(ADD_MONTHS(gd_start_date, j - 1),'YYYYMM'));  --年月
            l_item_plan_lines_tab(ln_line_cnt).month_no      := TO_NUMBER(TO_CHAR(ADD_MONTHS(gd_start_date, j - 1),'MM'));      --月
            l_item_plan_lines_tab(ln_line_cnt).year_bdgt_kbn := cv_budget_kbn_month;     -- 0:各月単位予算
          END IF;
          l_item_plan_lines_tab(ln_line_cnt).item_kbn               := cv_item_kbn_group;                   --商品区分
          l_item_plan_lines_tab(ln_line_cnt).item_no                := NULL;                                --商品コード
          l_item_plan_lines_tab(ln_line_cnt).item_group_no          := lt_item_group_no;                    --商品群コード
          --
          l_item_plan_lines_tab(ln_line_cnt).sales_budget           := l_group_bdgt_tab(j).sales_budget;          --売上
          l_item_plan_lines_tab(ln_line_cnt).amount_gross_margin    := l_group_bdgt_tab(j).amount_gross_margin;   --粗利額
          l_item_plan_lines_tab(ln_line_cnt).margin_rate            := l_group_bdgt_tab(j).margin_rate;           --粗利率
          l_item_plan_lines_tab(ln_line_cnt).credit_rate            := 0;                                         --掛率
          l_item_plan_lines_tab(ln_line_cnt).amount                 := 0;                                         --数量
          --who
          l_item_plan_lines_tab(ln_line_cnt).created_by             := cn_created_by;                       --作成者
          l_item_plan_lines_tab(ln_line_cnt).creation_date          := cd_creation_date;                    --作成日
          l_item_plan_lines_tab(ln_line_cnt).last_updated_by        := cn_last_updated_by;                  --最終更新者
          l_item_plan_lines_tab(ln_line_cnt).last_update_date       := cd_last_update_date;                 --最終更新日
          l_item_plan_lines_tab(ln_line_cnt).last_update_login      := cn_last_update_login;                --最終更新ログイン
          l_item_plan_lines_tab(ln_line_cnt).request_id             := cn_request_id;                       --要求ID
          l_item_plan_lines_tab(ln_line_cnt).program_application_id := cn_program_application_id;           --コンカレント・プログラム・アプリケーションID
          l_item_plan_lines_tab(ln_line_cnt).program_id             := cn_program_id;                       --コンカレント・プログラムID
          l_item_plan_lines_tab(ln_line_cnt).program_update_date    := cd_program_update_date;              --プログラム更新日
          --
        END LOOP;
        --
      ELSE
        -------------------------------------------------
        -- 4.商品群予算登録済時の商品群予算設定
        -------------------------------------------------
        FOR k IN 1..13 LOOP
          IF l_item_plan_lines_tab(k).month_no = cn_month_no_5 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_group_bdgt_tab(1).sales_budget;          -- 売上
            l_item_plan_lines_tab(k).amount_gross_margin    := l_group_bdgt_tab(1).amount_gross_margin;   -- 粗利額
            l_item_plan_lines_tab(k).margin_rate            := l_group_bdgt_tab(1).margin_rate;           -- 粗利率
          ELSIF l_item_plan_lines_tab(k).month_no = cn_month_no_6 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_group_bdgt_tab(2).sales_budget;          -- 売上
            l_item_plan_lines_tab(k).amount_gross_margin    := l_group_bdgt_tab(2).amount_gross_margin;   -- 粗利額
            l_item_plan_lines_tab(k).margin_rate            := l_group_bdgt_tab(2).margin_rate;           -- 粗利率
          ELSIF l_item_plan_lines_tab(k).month_no = cn_month_no_7 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_group_bdgt_tab(3).sales_budget;          -- 売上
            l_item_plan_lines_tab(k).amount_gross_margin    := l_group_bdgt_tab(3).amount_gross_margin;   -- 粗利額
            l_item_plan_lines_tab(k).margin_rate            := l_group_bdgt_tab(3).margin_rate;           -- 粗利率
          ELSIF l_item_plan_lines_tab(k).month_no = cn_month_no_8 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_group_bdgt_tab(4).sales_budget;          -- 売上
            l_item_plan_lines_tab(k).amount_gross_margin    := l_group_bdgt_tab(4).amount_gross_margin;   -- 粗利額
            l_item_plan_lines_tab(k).margin_rate            := l_group_bdgt_tab(4).margin_rate;           -- 粗利率
          ELSIF l_item_plan_lines_tab(k).month_no = cn_month_no_9 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_group_bdgt_tab(5).sales_budget;          -- 売上
            l_item_plan_lines_tab(k).amount_gross_margin    := l_group_bdgt_tab(5).amount_gross_margin;   -- 粗利額
            l_item_plan_lines_tab(k).margin_rate            := l_group_bdgt_tab(5).margin_rate;           -- 粗利率
          ELSIF l_item_plan_lines_tab(k).month_no = cn_month_no_10 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_group_bdgt_tab(6).sales_budget;          -- 売上
            l_item_plan_lines_tab(k).amount_gross_margin    := l_group_bdgt_tab(6).amount_gross_margin;   -- 粗利額
            l_item_plan_lines_tab(k).margin_rate            := l_group_bdgt_tab(6).margin_rate;           -- 粗利率
          ELSIF l_item_plan_lines_tab(k).month_no = cn_month_no_11 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_group_bdgt_tab(7).sales_budget;          -- 売上
            l_item_plan_lines_tab(k).amount_gross_margin    := l_group_bdgt_tab(7).amount_gross_margin;   -- 粗利額
            l_item_plan_lines_tab(k).margin_rate            := l_group_bdgt_tab(7).margin_rate;           -- 粗利率
          ELSIF l_item_plan_lines_tab(k).month_no = cn_month_no_12 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_group_bdgt_tab(8).sales_budget;          -- 売上
            l_item_plan_lines_tab(k).amount_gross_margin    := l_group_bdgt_tab(8).amount_gross_margin;   -- 粗利額
            l_item_plan_lines_tab(k).margin_rate            := l_group_bdgt_tab(8).margin_rate;           -- 粗利率
          ELSIF l_item_plan_lines_tab(k).month_no = cn_month_no_1 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_group_bdgt_tab(9).sales_budget;          -- 売上
            l_item_plan_lines_tab(k).amount_gross_margin    := l_group_bdgt_tab(9).amount_gross_margin;   -- 粗利額
            l_item_plan_lines_tab(k).margin_rate            := l_group_bdgt_tab(9).margin_rate;           -- 粗利率
          ELSIF l_item_plan_lines_tab(k).month_no = cn_month_no_2 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_group_bdgt_tab(10).sales_budget;          -- 売上
            l_item_plan_lines_tab(k).amount_gross_margin    := l_group_bdgt_tab(10).amount_gross_margin;   -- 粗利額
            l_item_plan_lines_tab(k).margin_rate            := l_group_bdgt_tab(10).margin_rate;           -- 粗利率
          ELSIF l_item_plan_lines_tab(k).month_no = cn_month_no_3 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_group_bdgt_tab(11).sales_budget;          -- 売上
            l_item_plan_lines_tab(k).amount_gross_margin    := l_group_bdgt_tab(11).amount_gross_margin;   -- 粗利額
            l_item_plan_lines_tab(k).margin_rate            := l_group_bdgt_tab(11).margin_rate;           -- 粗利率
          ELSIF l_item_plan_lines_tab(k).month_no = cn_month_no_4 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_group_bdgt_tab(12).sales_budget;          -- 売上
            l_item_plan_lines_tab(k).amount_gross_margin    := l_group_bdgt_tab(12).amount_gross_margin;   -- 粗利額
            l_item_plan_lines_tab(k).margin_rate            := l_group_bdgt_tab(12).margin_rate;           -- 粗利率
          ELSIF l_item_plan_lines_tab(k).month_no = cn_month_no_99 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_group_bdgt_tab(13).sales_budget;          -- 売上
            l_item_plan_lines_tab(k).amount_gross_margin    := l_group_bdgt_tab(13).amount_gross_margin;   -- 粗利額
            l_item_plan_lines_tab(k).margin_rate            := l_group_bdgt_tab(13).margin_rate;           -- 粗利率
          END IF;
          --who
          l_item_plan_lines_tab(k).last_updated_by        := cn_last_updated_by;                  --最終更新者
          l_item_plan_lines_tab(k).last_update_date       := cd_last_update_date;                 --最終更新日
          l_item_plan_lines_tab(k).last_update_login      := cn_last_update_login;                --最終更新ログイン
          l_item_plan_lines_tab(k).request_id             := cn_request_id;                       --要求ID
          l_item_plan_lines_tab(k).program_application_id := cn_program_application_id;           --コンカレント・プログラム・アプリケーションID
          l_item_plan_lines_tab(k).program_id             := cn_program_id;                       --コンカレント・プログラムID
          l_item_plan_lines_tab(k).program_update_date    := cd_program_update_date;              --プログラム更新日
          --
        END LOOP;
        --
      END IF;
      --
      -------------------------------------------------
      -- 5-1.新商品コード取得
      -------------------------------------------------
      lv_step := '新商品コード取得 ';
      BEGIN
        SELECT  DISTINCT  xicv.attribute3                             --  新商品コード
        INTO    lt_new_item_no
        FROM    xxcsm_item_category_v xicv                            --  品目カテゴリビュー
        WHERE   xicv.segment1 LIKE REPLACE(lt_item_group_no,'*','_')  --  商品群コード
        AND     xicv.attribute3 IS NOT NULL                           --  新商品コード
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
          lv_out_msg  := xxccp_common_pkg.get_msg(
                          iv_application          => cv_xxcsm_appl_short_name
                         ,iv_name                 => cv_msg_new_item_err
                         ,iv_token_name1          => cv_tkn_deal_cd
                         ,iv_token_value1         => lt_item_group_no
                        );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_out_msg
          );
          ov_retcode := cv_status_check;
      END;
      -------------------------------------------------
      -- 5-2.新商品営業原価取得
      -------------------------------------------------
      lv_step := '新商品営業原価取得 ';
      BEGIN
        -- 前年度の営業原価を品目変更履歴から取得
        SELECT xsibh.discrete_cost                           -- 営業原価
        INTO   lt_new_item_discrete_cost
        FROM   xxcmm_system_items_b_hst   xsibh              -- 品目変更履歴テーブル
              ,(SELECT MAX(item_hst_id)   item_hst_id        -- 品目変更履歴ID
                FROM   xxcmm_system_items_b_hst              -- 品目変更履歴
                WHERE  item_code  = lt_new_item_no           -- 品目コード
                AND    apply_date < gd_start_date            -- 年度開始日前
                AND    apply_flag = cv_yes                   -- 適用済み
                AND    discrete_cost IS NOT NULL             -- 営業原価 IS NOT NULL
               ) xsibh_view
        WHERE  xsibh.item_hst_id = xsibh_view.item_hst_id    -- 品目変更履歴ID
        AND    xsibh.item_code   = lt_new_item_no            -- 新商品コード
        AND    xsibh.apply_flag  = cv_yes                    -- 適用済み
        AND    xsibh.discrete_cost IS NOT NULL
        ;
          --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          --営業原価取得エラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcsm_appl_short_name          -- アプリケーション短縮名
                         , iv_name         => cv_msg_discrete_cost_err          -- メッセージコード
                         , iv_token_name1  => cv_tkn_deal_cd                    -- トークンコード1
                         , iv_token_value1 => lt_item_group_no                  -- トークン値1（商品群）
                         , iv_token_name2  => cv_tkn_item_cd                    -- トークンコード2
                         , iv_token_value2 => lt_new_item_no                    -- トークン値2（商品コード）
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          ov_retcode := cv_status_check;
      END;
      --
      -------------------------------------------------
      -- 5-3.新商品定価取得
      -------------------------------------------------
      lv_step := '新商品定価取得 ';
      BEGIN
        -- 前年度の定価を品目変更履歴から取得
        SELECT xsibh.fixed_price                             -- 定価
        INTO   lt_new_item_fixed_price
        FROM   xxcmm_system_items_b_hst   xsibh              -- 品目変更履歴テーブル
              ,(SELECT MAX(item_hst_id)   item_hst_id        -- 品目変更履歴ID
                FROM   xxcmm_system_items_b_hst              -- 品目変更履歴
                WHERE  item_code  = lt_new_item_no           -- 品目コード
                AND    apply_date < gd_start_date            -- 年度開始日前
                AND    apply_flag = cv_yes                   -- 適用済み
                AND    fixed_price IS NOT NULL               -- 定価 IS NOT NULL
                  ) xsibh_view
        WHERE  xsibh.item_hst_id = xsibh_view.item_hst_id    -- 品目変更履歴ID
        AND    xsibh.item_code   = lt_new_item_no            -- 新商品コード
        AND    xsibh.apply_flag  = cv_yes                    -- 適用済み
        AND    xsibh.fixed_price IS NOT NULL
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          --定価取得エラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcsm_appl_short_name          -- アプリケーション短縮名
                         , iv_name         => cv_msg_fixed_price_err            -- メッセージコード
                         , iv_token_name1  => cv_tkn_deal_cd                    -- トークンコード1
                         , iv_token_value1 => lt_item_group_no                  -- トークン値1（商品群）
                         , iv_token_name2  => cv_tkn_item_cd                    -- トークンコード2
                         , iv_token_value2 => lt_new_item_no                    -- トークン値2（商品コード）
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          ov_retcode := cv_status_check;
      END;
      --
      -------------------------------------------------
      -- 6.新商品予算算出
      -------------------------------------------------
      l_new_item_bdgt_tab.DELETE;
      FOR j IN 1..12 LOOP            --新商品の月別ループ
        -------------------------------------------------
        -- 単品予算合計額取得
        -------------------------------------------------
        SELECT  NVL(SUM(xipl.sales_budget), 0)         AS  sum_sales_budget         --売上合計額
               ,NVL(SUM(xipl.amount_gross_margin), 0)  AS  sum_amount_gross_margin  --粗利合計額
        INTO    ln_sum_sales_budget
               ,ln_sum_amount_gross_margin
        FROM    xxcsm_item_plan_lines   xipl
        WHERE   xipl.item_plan_header_id = gt_item_plan_header_id
        AND     xipl.item_group_no = lt_item_group_no
        AND     xipl.item_kbn = cv_item_kbn_tanpin
        AND     xipl.month_no = TO_NUMBER(TO_CHAR(ADD_MONTHS(gd_start_date, j - 1),'MM'))
        ;
        -------------------------------------------------
        --新商品の売上、粗利額算出
        -------------------------------------------------
        l_new_item_bdgt_tab(j).sales_budget        := l_group_bdgt_tab(j).sales_budget - ln_sum_sales_budget;
        l_new_item_bdgt_tab(j).amount_gross_margin := l_group_bdgt_tab(j).amount_gross_margin - ln_sum_amount_gross_margin;
        --
        lv_month := TO_CHAR(ADD_MONTHS(gd_start_date, j - 1),'MM');
        --
        -------------------------------------------------
        -- 新商品予算項目設定
        -------------------------------------------------
        calc_budget_new_item(
          ov_errbuf                 => lv_errbuf                                         -- エラー・メッセージ
         ,ov_retcode                => lv_retcode                                        -- リターン・コード
         ,ov_errmsg                 => lv_errmsg                                         -- ユーザー・エラー・メッセージ
         ,on_credit_rate            => l_new_item_bdgt_tab(j).credit_rate                -- 算出結果_掛率
         ,on_amount                 => l_new_item_bdgt_tab(j).amount                     -- 算出結果_数量
         ,iv_item_group_no          => lt_item_group_no                                  -- 入力_商品群
         ,iv_new_item_no            => lt_new_item_no                                    -- 入力_新商品コード
         ,iv_month                  => lv_month                                          -- 入力_月
         ,in_sales_budget           => l_new_item_bdgt_tab(j).sales_budget               -- 入力_新商品の売上(単位：円)
         ,in_amount_gross_margin    => l_new_item_bdgt_tab(j).amount_gross_margin        -- 入力_新商品の粗利額(単位：円)
         ,in_new_item_discrete_cost => lt_new_item_discrete_cost                         -- 入力_新商品の営業原価(単位：円)
         ,in_new_item_fixed_price   => lt_new_item_fixed_price                           -- 入力_新商品の定価(単位：円)
        );
        --
        IF ( lv_retcode = cv_status_check ) THEN
          ov_retcode := cv_status_check;
        ELSIF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        --
      END LOOP;
      --
      -- 商品計画明細登録・更新
      IF ln_cnt = 0 THEN
        -------------------------------------------------
        -- 7.商品群予算未登録時の新商品予算設定
        -------------------------------------------------
        FOR j IN 1..12 LOOP       --新商品の月別ループ
          --
          --登録値設定処理
          ln_line_cnt := ln_line_cnt + 1;
          --
          l_item_plan_lines_tab(ln_line_cnt).item_plan_header_id    := gt_item_plan_header_id;             --商品計画ヘッダID
          l_item_plan_lines_tab(ln_line_cnt).item_plan_lines_id     := xxcsm_item_plan_lines_s01.NEXTVAL;  --商品計画明細ID
          l_item_plan_lines_tab(ln_line_cnt).year_month             := TO_NUMBER(TO_CHAR(ADD_MONTHS(gd_start_date, j - 1),'YYYYMM'));  --年月
          l_item_plan_lines_tab(ln_line_cnt).month_no               := TO_NUMBER(TO_CHAR(ADD_MONTHS(gd_start_date, j - 1),'MM'));      --月
          l_item_plan_lines_tab(ln_line_cnt).year_bdgt_kbn          := cv_budget_kbn_month;                --0:各月単位予算
          l_item_plan_lines_tab(ln_line_cnt).item_kbn               := cv_item_kbn_new;                    --商品区分
          l_item_plan_lines_tab(ln_line_cnt).item_no                := lt_new_item_no;                     --商品コード
          l_item_plan_lines_tab(ln_line_cnt).item_group_no          := lt_item_group_no;                   --商品群コード
          --
          l_item_plan_lines_tab(ln_line_cnt).sales_budget           := l_new_item_bdgt_tab(j).sales_budget;          --売上
          l_item_plan_lines_tab(ln_line_cnt).amount_gross_margin    := l_new_item_bdgt_tab(j).amount_gross_margin;   --粗利額
          l_item_plan_lines_tab(ln_line_cnt).margin_rate            := 0;                                            --粗利率
          l_item_plan_lines_tab(ln_line_cnt).credit_rate            := l_new_item_bdgt_tab(j).credit_rate;           --掛率
          l_item_plan_lines_tab(ln_line_cnt).amount                 := l_new_item_bdgt_tab(j).amount;                --数量
          --who
          l_item_plan_lines_tab(ln_line_cnt).created_by             := cn_created_by;                   --作成者
          l_item_plan_lines_tab(ln_line_cnt).creation_date          := cd_creation_date;                --作成日
          l_item_plan_lines_tab(ln_line_cnt).last_updated_by        := cn_last_updated_by;              --最終更新者
          l_item_plan_lines_tab(ln_line_cnt).last_update_date       := cd_last_update_date;             --最終更新日
          l_item_plan_lines_tab(ln_line_cnt).last_update_login      := cn_last_update_login;            --最終更新ログイン
          l_item_plan_lines_tab(ln_line_cnt).request_id             := cn_request_id;                   --要求ID
          l_item_plan_lines_tab(ln_line_cnt).program_application_id := cn_program_application_id;       --コンカレント・プログラム・アプリケーションID
          l_item_plan_lines_tab(ln_line_cnt).program_id             := cn_program_id;                   --コンカレント・プログラムID
          l_item_plan_lines_tab(ln_line_cnt).program_update_date    := cd_program_update_date;          --プログラム更新日
          --
        END LOOP;
        --
        -------------------------------------------------
        -- 8.商品計画明細登録（商品群、新商品）
        -------------------------------------------------
        IF ov_retcode = cv_status_normal THEN
          FORALL l in 1..ln_line_cnt
            INSERT INTO xxcsm_item_plan_lines VALUES l_item_plan_lines_tab(l);
        END IF;
        --
      ELSE
        -------------------------------------------------
        -- 9.商品群予算登録済時の新商品予算設定
        -------------------------------------------------
        FOR k IN 14..25 LOOP       --新商品の月別ループ
          --
          IF l_item_plan_lines_tab(k).month_no = cn_month_no_5 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_new_item_bdgt_tab(1).sales_budget;          --売上
            l_item_plan_lines_tab(k).amount_gross_margin    := l_new_item_bdgt_tab(1).amount_gross_margin;   --粗利額
            l_item_plan_lines_tab(k).credit_rate            := l_new_item_bdgt_tab(1).credit_rate;           --掛率
            l_item_plan_lines_tab(k).amount                 := l_new_item_bdgt_tab(1).amount;                --数量
          ELSIF l_item_plan_lines_tab(k).month_no = cn_month_no_6 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_new_item_bdgt_tab(2).sales_budget;          --売上
            l_item_plan_lines_tab(k).amount_gross_margin    := l_new_item_bdgt_tab(2).amount_gross_margin;   --粗利額
            l_item_plan_lines_tab(k).credit_rate            := l_new_item_bdgt_tab(2).credit_rate;           --掛率
            l_item_plan_lines_tab(k).amount                 := l_new_item_bdgt_tab(2).amount;                --数量
          ELSIF l_item_plan_lines_tab(k).month_no = cn_month_no_7 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_new_item_bdgt_tab(3).sales_budget;          --売上
            l_item_plan_lines_tab(k).amount_gross_margin    := l_new_item_bdgt_tab(3).amount_gross_margin;   --粗利額
            l_item_plan_lines_tab(k).credit_rate            := l_new_item_bdgt_tab(3).credit_rate;           --掛率
            l_item_plan_lines_tab(k).amount                 := l_new_item_bdgt_tab(3).amount;                --数量
          ELSIF l_item_plan_lines_tab(k).month_no = cn_month_no_8 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_new_item_bdgt_tab(4).sales_budget;          --売上
            l_item_plan_lines_tab(k).amount_gross_margin    := l_new_item_bdgt_tab(4).amount_gross_margin;   --粗利額
            l_item_plan_lines_tab(k).credit_rate            := l_new_item_bdgt_tab(4).credit_rate;           --掛率
            l_item_plan_lines_tab(k).amount                 := l_new_item_bdgt_tab(4).amount;                --数量
          ELSIF l_item_plan_lines_tab(k).month_no = cn_month_no_9 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_new_item_bdgt_tab(5).sales_budget;          --売上
            l_item_plan_lines_tab(k).amount_gross_margin    := l_new_item_bdgt_tab(5).amount_gross_margin;   --粗利額
            l_item_plan_lines_tab(k).credit_rate            := l_new_item_bdgt_tab(5).credit_rate;           --掛率
            l_item_plan_lines_tab(k).amount                 := l_new_item_bdgt_tab(5).amount;                --数量
          ELSIF l_item_plan_lines_tab(k).month_no = cn_month_no_10 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_new_item_bdgt_tab(6).sales_budget;          --売上
            l_item_plan_lines_tab(k).amount_gross_margin    := l_new_item_bdgt_tab(6).amount_gross_margin;   --粗利額
            l_item_plan_lines_tab(k).credit_rate            := l_new_item_bdgt_tab(6).credit_rate;           --掛率
            l_item_plan_lines_tab(k).amount                 := l_new_item_bdgt_tab(6).amount;                --数量
          ELSIF l_item_plan_lines_tab(k).month_no = cn_month_no_11 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_new_item_bdgt_tab(7).sales_budget;          --売上
            l_item_plan_lines_tab(k).amount_gross_margin    := l_new_item_bdgt_tab(7).amount_gross_margin;   --粗利額
            l_item_plan_lines_tab(k).credit_rate            := l_new_item_bdgt_tab(7).credit_rate;           --掛率
            l_item_plan_lines_tab(k).amount                 := l_new_item_bdgt_tab(7).amount;                --数量
          ELSIF l_item_plan_lines_tab(k).month_no = cn_month_no_12 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_new_item_bdgt_tab(8).sales_budget;          --売上
            l_item_plan_lines_tab(k).amount_gross_margin    := l_new_item_bdgt_tab(8).amount_gross_margin;   --粗利額
            l_item_plan_lines_tab(k).credit_rate            := l_new_item_bdgt_tab(8).credit_rate;           --掛率
            l_item_plan_lines_tab(k).amount                 := l_new_item_bdgt_tab(8).amount;                --数量
          ELSIF l_item_plan_lines_tab(k).month_no = cn_month_no_1 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_new_item_bdgt_tab(9).sales_budget;          --売上
            l_item_plan_lines_tab(k).amount_gross_margin    := l_new_item_bdgt_tab(9).amount_gross_margin;   --粗利額
            l_item_plan_lines_tab(k).credit_rate            := l_new_item_bdgt_tab(9).credit_rate;           --掛率
            l_item_plan_lines_tab(k).amount                 := l_new_item_bdgt_tab(9).amount;                --数量
          ELSIF l_item_plan_lines_tab(k).month_no = cn_month_no_2 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_new_item_bdgt_tab(10).sales_budget;         --売上
            l_item_plan_lines_tab(k).amount_gross_margin    := l_new_item_bdgt_tab(10).amount_gross_margin;  --粗利額
            l_item_plan_lines_tab(k).credit_rate            := l_new_item_bdgt_tab(10).credit_rate;          --掛率
            l_item_plan_lines_tab(k).amount                 := l_new_item_bdgt_tab(10).amount;               --数量
          ELSIF l_item_plan_lines_tab(k).month_no = cn_month_no_3 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_new_item_bdgt_tab(11).sales_budget;         --売上
            l_item_plan_lines_tab(k).amount_gross_margin    := l_new_item_bdgt_tab(11).amount_gross_margin;  --粗利額
            l_item_plan_lines_tab(k).credit_rate            := l_new_item_bdgt_tab(11).credit_rate;          --掛率
            l_item_plan_lines_tab(k).amount                 := l_new_item_bdgt_tab(11).amount;               --数量
          ELSIF l_item_plan_lines_tab(k).month_no = cn_month_no_4 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_new_item_bdgt_tab(12).sales_budget;         --売上
            l_item_plan_lines_tab(k).amount_gross_margin    := l_new_item_bdgt_tab(12).amount_gross_margin;  --粗利額
            l_item_plan_lines_tab(k).credit_rate            := l_new_item_bdgt_tab(12).credit_rate;          --掛率
            l_item_plan_lines_tab(k).amount                 := l_new_item_bdgt_tab(12).amount;               --数量
          END IF;
          --who
          l_item_plan_lines_tab(k).last_updated_by        := cn_last_updated_by;                  --最終更新者
          l_item_plan_lines_tab(k).last_update_date       := cd_last_update_date;                 --最終更新日
          l_item_plan_lines_tab(k).last_update_login      := cn_last_update_login;                --最終更新ログイン
          l_item_plan_lines_tab(k).request_id             := cn_request_id;                       --要求ID
          l_item_plan_lines_tab(k).program_application_id := cn_program_application_id;           --コンカレント・プログラム・アプリケーションID
          l_item_plan_lines_tab(k).program_id             := cn_program_id;                       --コンカレント・プログラムID
          l_item_plan_lines_tab(k).program_update_date    := cd_program_update_date;              --プログラム更新日
          --
        END LOOP;
        --
        -------------------------------------------------
        -- 10.商品計画明細更新（商品群、新商品）
        -------------------------------------------------
        IF ov_retcode = cv_status_normal THEN
          FORALL l in 1..l_item_plan_lines_tab.COUNT
            UPDATE xxcsm_item_plan_lines
            SET sales_budget           = l_item_plan_lines_tab(l).sales_budget            --売上
               ,amount_gross_margin    = l_item_plan_lines_tab(l).amount_gross_margin     --粗利額
               ,margin_rate            = l_item_plan_lines_tab(l).margin_rate             --粗利率
               ,credit_rate            = l_item_plan_lines_tab(l).credit_rate             --掛率
               ,amount                 = l_item_plan_lines_tab(l).amount                  --数量
               ,last_updated_by        = l_item_plan_lines_tab(l).last_updated_by         --最終更新者
               ,last_update_date       = l_item_plan_lines_tab(l).last_update_date        --最終更新日
               ,last_update_login      = l_item_plan_lines_tab(l).last_update_login       --最終更新ログイン
               ,request_id             = l_item_plan_lines_tab(l).request_id              --要求ID
               ,program_application_id = l_item_plan_lines_tab(l).program_application_id  --コンカレント・プログラム・アプリケーションID
               ,program_id             = l_item_plan_lines_tab(l).program_id              --コンカレント・プログラムID
               ,program_update_date    = l_item_plan_lines_tab(l).program_update_date     --プログラム更新日
            WHERE item_plan_lines_id = l_item_plan_lines_tab(l).item_plan_lines_id      --商品計画明細ID
            ;
        END IF;
        --
      END IF;
      --
    END LOOP;
    --
--
  EXCEPTION
    --*** ロック取得エラーハンドラ ***
    WHEN global_data_lock_expt THEN
      lv_tab_name := xxccp_common_pkg.get_msg(
                               iv_application => cv_xxcsm_appl_short_name
                              ,iv_name        => cv_msg_item_plan_lines
                             );
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcsm_appl_short_name
                    ,iv_name         => cv_msg_get_lock_err
                    ,iv_token_name1  => cv_tkn_table
                    ,iv_token_value1 => lv_tab_name
                  );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END ins_plan_line;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
     in_get_file_id    IN  NUMBER    -- ファイルID
    ,iv_get_format_pat IN  VARCHAR2  -- フォーマットパターン
    ,ov_errbuf         OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
    ,ov_retcode        OUT VARCHAR2  -- リターン・コード             --# 固定 #
    ,ov_errmsg         OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
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
    ln_cnt           NUMBER;        -- カウンタ
    lv_ret_status    VARCHAR2(1);   -- リターン・ステータス
--
    --取得値の格納変数
    lv_base_code         VARCHAR2(4);               -- 拠点コード
    lv_plan_year         VARCHAR2(4);               -- 年度
    lv_plan_kind         VARCHAR2(20);              -- 予算区分
    lv_record_kind       VARCHAR2(20);              -- レコード区分
    ln_may               NUMBER;                    -- 5月予算
    ln_jun               NUMBER;                    -- 6月予算
    ln_jul               NUMBER;                    -- 7月予算
    ln_aug               NUMBER;                    -- 8月予算
    ln_sep               NUMBER;                    -- 9月予算
    ln_oct               NUMBER;                    -- 10月予算
    ln_nov               NUMBER;                    -- 11月予算
    ln_dec               NUMBER;                    -- 12月予算
    ln_jan               NUMBER;                    -- 1月予算
    ln_feb               NUMBER;                    -- 2月予算
    ln_mar               NUMBER;                    -- 3月予算
    ln_apr               NUMBER;                    -- 4月予算
    ln_sum               NUMBER;                    -- 商品群年間計
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --カウンタ
    gn_get_counter_data      := 0;     --データ数
--
    --ローカル変数の初期化
    ln_cnt        := 0;
    lv_ret_status := cv_status_normal;
--
    -- ===============================================
    -- 初期処理(A-1)
    -- ===============================================
    init(
      iv_get_format => iv_get_format_pat -- フォーマットパターン
     ,in_file_id    => in_get_file_id    -- ファイルID
     ,ov_errbuf     => lv_errbuf         -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    => lv_retcode        -- リターン・コード             --# 固定 #
     ,ov_errmsg     => lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
      RETURN;
    END IF;
--
    -- ===============================================
    -- ファイルアップロードIF取得(A-2)
    -- ===============================================
    get_upload_data(
      in_file_id           => in_get_file_id       -- FILE_ID
     ,on_get_counter_data  => gn_get_counter_data  -- データ数
     ,ov_errbuf            => lv_errbuf            -- エラー・メッセージ           --# 固定 #
     ,ov_retcode           => lv_retcode           -- リターン・コード             --# 固定 #
     ,ov_errmsg            => lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- アップロードデータ削除処理(A-3)
    -- ===============================================
    del_upload_data(
      in_file_id  => in_get_file_id   -- ファイルID
     ,ov_errbuf   => lv_errbuf        -- エラー・メッセージ           --# 固定 #
     ,ov_retcode  => lv_retcode       -- リターン・コード             --# 固定 #
     ,ov_errmsg   => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      --コミット
      COMMIT;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- 年間商品計画データの項目分割処理(A-4)
    -- ===============================================
    split_plan_data(
      in_cnt            => gn_get_counter_data  -- データ数
     ,ov_errbuf         => lv_errbuf            -- エラー・メッセージ           --# 固定 #
     ,ov_retcode        => lv_retcode           -- リターン・コード             --# 固定 #
     ,ov_errmsg         => lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_check ) THEN
      ov_retcode := cv_status_error;
      RETURN;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    FOR i IN cn_begin_line .. gn_get_counter_data LOOP
--
      -- ===============================================
      -- 項目チェック(A-5)
      -- ===============================================
      item_check(
        in_cnt               => i                    -- データカウンタ
       ,ov_base_code         => lv_base_code         -- 拠点コード
       ,ov_plan_year         => lv_plan_year         -- 年度
       ,ov_plan_kind         => lv_plan_kind         -- 予算区分
       ,ov_record_kind       => lv_record_kind       -- レコード区分
       ,on_may               => ln_may               -- 5月予算
       ,on_jun               => ln_jun               -- 6月予算
       ,on_jul               => ln_jul               -- 7月予算
       ,on_aug               => ln_aug               -- 8月予算
       ,on_sep               => ln_sep               -- 9月予算
       ,on_oct               => ln_oct               -- 10月予算
       ,on_nov               => ln_nov               -- 11月予算
       ,on_dec               => ln_dec               -- 12月予算
       ,on_jan               => ln_jan               -- 1月予算
       ,on_feb               => ln_feb               -- 2月予算
       ,on_mar               => ln_mar               -- 3月予算
       ,on_apr               => ln_apr               -- 4月予算
       ,on_sum               => ln_sum               -- 商品群年間計
       ,ov_errbuf            => lv_errbuf            -- エラー・メッセージ           --# 固定 #
       ,ov_retcode           => lv_retcode           -- リターン・コード             --# 固定 #
       ,ov_errmsg            => lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      ELSIF ( lv_retcode = cv_status_check ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        --ワーニング保持
        lv_ret_status := cv_status_check;
      END IF;
--
      IF ( lv_ret_status = cv_status_normal ) THEN
        -- ===============================================
        -- 商品計画アップロードワーク登録処理(A-6)
        -- ===============================================
        ins_plan_tmp(
          in_cnt               => i                    -- データカウンタ
         ,iv_base_code         => lv_base_code         -- 拠点コード
         ,iv_plan_year         => lv_plan_year         -- 年度
         ,iv_plan_kind         => lv_plan_kind         -- 予算区分
         ,iv_record_kind       => lv_record_kind       -- レコード区分
         ,in_may               => ln_may               -- 5月予算
         ,in_jun               => ln_jun               -- 6月予算
         ,in_jul               => ln_jul               -- 7月予算
         ,in_aug               => ln_aug               -- 8月予算
         ,in_sep               => ln_sep               -- 9月予算
         ,in_oct               => ln_oct               -- 10月予算
         ,in_nov               => ln_nov               -- 11月予算
         ,in_dec               => ln_dec               -- 12月予算
         ,in_jan               => ln_jan               -- 1月予算
         ,in_feb               => ln_feb               -- 2月予算
         ,in_mar               => ln_mar               -- 3月予算
         ,in_apr               => ln_apr               -- 4月予算
         ,in_sum               => ln_sum               -- 商品群年間計
         ,ov_errbuf            => lv_errbuf            -- エラー・メッセージ           --# 固定 #
         ,ov_retcode           => lv_retcode           -- リターン・コード             --# 固定 #
         ,ov_errmsg            => lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
          );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
      --
    END LOOP;
    --
    IF lv_ret_status <> cv_status_normal THEN
      ov_retcode := cv_status_error;
      RETURN;
    END IF;
--
    -- ===============================================
    -- 商品計画アップロードワーク取得処理(A-7)
    -- ===============================================
    -- オープン
    OPEN get_plan_tmp_cur;
    -- データ取得
    FETCH get_plan_tmp_cur BULK COLLECT INTO gr_plan_tmps_tab;
    -- クローズ
    CLOSE get_plan_tmp_cur;
--
    -- ===============================================
    -- 拠点コード、年度チェック処理(A-8)
    -- ===============================================
    chk_base_code(
        ov_errbuf                  => lv_errbuf   -- エラー・メッセージ           --# 固定 #
       ,ov_retcode                 => lv_retcode  -- リターン・コード             --# 固定 #
       ,ov_errmsg                  => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_check ) THEN
      ov_retcode := cv_status_error;
      RETURN;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- レコード区分チェック処理(A-9)
    -- ===============================================
    chk_record_kind(
        ov_errbuf                  => lv_errbuf   -- エラー・メッセージ           --# 固定 #
       ,ov_retcode                 => lv_retcode  -- リターン・コード             --# 固定 #
       ,ov_errmsg                  => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_check ) THEN
      ov_retcode := cv_status_error;
      RETURN;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- 商品群マスタチェック処理(A-10)
    -- ===============================================
    chk_master_data(
        ov_errbuf                  => lv_errbuf   -- エラー・メッセージ           --# 固定 #
       ,ov_retcode                 => lv_retcode  -- リターン・コード             --# 固定 #
       ,ov_errmsg                  => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_check ) THEN
      ov_retcode := cv_status_error;
      RETURN;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- 予算項目チェック処理(A-11)
    -- ===============================================
    chk_budget_item(
        ov_errbuf                  => lv_errbuf   -- エラー・メッセージ           --# 固定 #
       ,ov_retcode                 => lv_retcode  -- リターン・コード             --# 固定 #
       ,ov_errmsg                  => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_check ) THEN
      ov_retcode := cv_status_error;
      RETURN;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- ===============================================
    -- 商品計画ヘッダ登録処理(A-12)
    -- ===============================================
    ins_plan_headers(
        ov_errbuf                  => lv_errbuf   -- エラー・メッセージ           --# 固定 #
       ,ov_retcode                 => lv_retcode  -- リターン・コード             --# 固定 #
       ,ov_errmsg                  => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- ===============================================
    -- 拠点予算登録・更新処理(A-13)
    -- ===============================================
    ins_plan_loc_bdgt(
        ov_errbuf                  => lv_errbuf   -- エラー・メッセージ           --# 固定 #
       ,ov_retcode                 => lv_retcode  -- リターン・コード             --# 固定 #
       ,ov_errmsg                  => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- ===============================================
    -- 商品群予算登録・更新処理(A-14)
    -- ===============================================
    ins_plan_line(
        ov_errbuf                  => lv_errbuf   -- エラー・メッセージ           --# 固定 #
       ,ov_retcode                 => lv_retcode  -- リターン・コード             --# 固定 #
       ,ov_errmsg                  => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF ( lv_retcode = cv_status_check ) THEN
      ov_retcode := cv_status_error;
      RETURN;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --
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
    errbuf            OUT VARCHAR2  -- エラー・メッセージ  --# 固定 #
   ,retcode           OUT VARCHAR2  -- リターン・コード    --# 固定 #
   ,in_get_file_id    IN  NUMBER    -- ファイルID
   ,iv_get_format_pat IN  VARCHAR2  -- フォーマットパターン
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
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- コンカレントヘッダメッセージ出力先：出力
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- コンカレントヘッダメッセージ出力先：ログ(帳票のみ)
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
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log_header_out
      ,ov_retcode => lv_retcode
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
    -- submainの呼び出し(実際の処理はsubmainで行う)
    -- ===============================================
    submain(
      in_get_file_id     -- ファイルID
     ,iv_get_format_pat  -- フォーマットパターン
     ,lv_errbuf      -- エラー・メッセージ           --# 固定 #
     ,lv_retcode     -- リターン・コード             --# 固定 #
     ,lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
--###########################  固定部 START   #####################################################
--
    -- ===============================================
    -- 終了処理(A-15)
    -- ===============================================
    --エラー時処理
    IF ( lv_retcode = cv_status_error ) THEN
      --エラーメッセージ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
      --エラー件数設定
      gn_error_cnt    := 1;
      --エラー時のROLLBACK
      ROLLBACK;
    ELSE
      gn_normal_cnt := gn_target_cnt;
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
--
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
END XXCSM002A17C;
/
