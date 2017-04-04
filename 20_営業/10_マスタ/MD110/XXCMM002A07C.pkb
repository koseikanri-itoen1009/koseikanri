CREATE OR REPLACE PACKAGE BODY XXCMM002A07C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * Package Name     : XXCMM002A07C(body)
 * Description      : 社員マスタ連携（eSM）
 * MD.050           : MD050_CMM_002_A07_社員マスタ連携（eSM）
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  open_csv_file          ファイルオープン処理(A-2)
 *  get_emp_data           従業員データ取得処理(A-3)
 *  output_csv_data        CSVファイル出力処理(A-4)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                         終了処理(A-5)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2017/02/15    1.0   S.Niki           新規作成
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_error;  --異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER       := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE         := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER       := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE         := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER       := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER       := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER       := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER       := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE         := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  cv_msg_part               CONSTANT VARCHAR2(3)  := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3)  := '.';
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
  global_init_err_expt      EXCEPTION; -- 初期処理エラー
  global_f_open_err_expt    EXCEPTION; -- ファイルオープンエラー
  global_write_err_expt     EXCEPTION; -- CSVデータ出力エラー
  global_f_close_err_expt   EXCEPTION; -- ファイルクローズエラー
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(12)  := 'XXCMM002A07C';         -- パッケージ名
  -- アプリケーション短縮名
  cv_appl_xxcmm             CONSTANT VARCHAR2(5)   := 'XXCMM';                -- アドオン：マスタ・マスタ領域
  cv_appl_xxccp             CONSTANT VARCHAR2(5)   := 'XXCCP';                -- アドオン：共通・IF領域
--
  -- 文字列
  cv_comma                  CONSTANT VARCHAR2(1)   := ',';                    -- カンマ
  cv_space_full             CONSTANT VARCHAR2(2)   := '　';                   -- 全角スペース
  cv_hyphen                 CONSTANT VARCHAR2(1)   := '-';                    -- ハイフン
--
  -- プロファイル
  cv_prf_org_id             CONSTANT VARCHAR2(30)  := 'ORG_ID';                         -- 営業単位ID
  cv_prf_out_file_dir       CONSTANT VARCHAR2(30)  := 'XXCMM1_JIHANKI_OUT_DIR';         -- CSVファイル出力先
  cv_prf_out_file_name      CONSTANT VARCHAR2(30)  := 'XXCMM1_002A07_OUT_FILE';         -- CSVファイル名
  cv_prf_stop_bumon         CONSTANT VARCHAR2(30)  := 'XXCMM1_002A07_STOP_BUMON';       -- 利用停止部署名
  cv_prf_other_wk_honbu     CONSTANT VARCHAR2(30)  := 'XXCMM1_002A07_OTHER_WK_HONBU';   -- 他の担当業務（本部営業）
  cv_prf_other_wk_tenpo     CONSTANT VARCHAR2(30)  := 'XXCMM1_002A07_OTHER_WK_TENPO';   -- 他の担当業務（店舗営業）
  cv_prf_other_wk_shanai    CONSTANT VARCHAR2(30)  := 'XXCMM1_002A07_OTHER_WK_SHANAI';  -- 他の担当業務（社内業務）
  cv_prf_licensed_prdcts    CONSTANT VARCHAR2(30)  := 'XXCMM1_002A07_LICENSED_PRDCTS';  -- ライセンスする製品
  cv_prf_timezone           CONSTANT VARCHAR2(30)  := 'XXCMM1_002A07_TIMEZONE';         -- タイムゾーン
  cv_prf_date_format        CONSTANT VARCHAR2(30)  := 'XXCMM1_002A07_DATE_FORMAT';      -- 日付フォーマット
  cv_prf_language           CONSTANT VARCHAR2(30)  := 'XXCMM1_002A07_LANGUAGE';         -- 言語
  cv_prf_holiday_pattern    CONSTANT VARCHAR2(30)  := 'XXCMM1_002A07_HOLIDAY_PATTERN';  -- 休日パターン
  cv_prf_role               CONSTANT VARCHAR2(30)  := 'XXCMM1_002A07_ROLE';             -- ロール
--
  -- タイプ
  cv_lkp_qual_code          CONSTANT VARCHAR2(30)  := 'XXCMM_QUALIFICATION_CODE';       -- 資格コード
  cv_lkp_posi_code          CONSTANT VARCHAR2(30)  := 'XXCMM_POSITION_CODE';            -- 職位コード
  cv_lkp_main_work          CONSTANT VARCHAR2(30)  := 'XXCSO1_ESM_MAIN_WORK';           -- 主業務
--
  -- メッセージ
  cv_file_name_msg          CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-05102';     -- ファイル名メッセージ
  cv_input_param_msg        CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00225';     -- 入力パラメータ文字列
  cv_csv_header_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00226';     -- CSVヘッダ文字列
  cv_process_date_err_msg   CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00018';     -- 業務日付取得エラーメッセージ
  cv_profile_err_msg        CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00002';     -- プロファイル取得エラー
  cv_date_reversal_err_msg  CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00227';     -- 最終更新日逆転チェックエラー
  cv_e_date_select_err_msg  CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00220';     -- 最終更新日（終了）指定エラー
  cv_file_exists_err_msg    CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00010';     -- ファイル作成済みエラー
  cv_main_work_err_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00228';     -- eSM主業務未設定エラー
  cv_resource_err_msg       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00229';     -- リソースグループ役割重複エラー
  cv_file_open_err_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00487';     -- ファイルオープンエラー
  cv_file_write_err_msg     CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00488';     -- CSVデータ出力エラー
  cv_file_close_err_msg     CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00489';     -- ファイルクローズエラー
--
  -- トークン
  cv_tkn_date_from          CONSTANT VARCHAR2(30)  := 'DATE_FROM';            -- 開始日
  cv_tkn_date_to            CONSTANT VARCHAR2(30)  := 'DATE_TO';              -- 終了日
  cv_tkn_file_name          CONSTANT VARCHAR2(30)  := 'FILE_NAME';            -- CSVファイル名
  cv_tkn_ng_profile         CONSTANT VARCHAR2(30)  := 'NG_PROFILE';           -- プロファイル名
  cv_tkn_sqlerrm            CONSTANT VARCHAR2(30)  := 'SQLERRM';              -- SQLエラーメッセージ
  cv_tkn_employee_number    CONSTANT VARCHAR2(30)  := 'EMPLOYEE_NUMBER';      -- 従業員番号
  cv_tkn_start_date_active  CONSTANT VARCHAR2(30)  := 'START_DATE_ACTIVE';    -- 適用開始日
--
  cv_fmt_std                CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';           -- 日付書式：YYYY/MM/DD
  cv_max_date               CONSTANT VARCHAR2(10)  := '9999/12/31';           -- 最大日付
  ct_lang                   CONSTANT fnd_lookup_values.language%TYPE
                                                   := USERENV('LANG');        -- 言語
  cv_category_emp           CONSTANT VARCHAR2(8)   := 'EMPLOYEE';             -- カテゴリ：従業員
  cv_resource_type_gm       CONSTANT VARCHAR2(15)  := 'RS_GROUP_MEMBER';      -- リソースタイプ：グループメンバー
  cv_cust_class_base        CONSTANT VARCHAR2(1)   := '1';                    -- 顧客区分：拠点
  cv_flag_y                 CONSTANT VARCHAR2(1)   := 'Y';                    -- フラグ：Y
  cv_flag_n                 CONSTANT VARCHAR2(1)   := 'N';                    -- フラグ：N
  cv_main_wk_honbu          CONSTANT VARCHAR2(1)   := '1';                    -- 主業務：本部営業
  cv_main_wk_tenpo          CONSTANT VARCHAR2(1)   := '2';                    -- 主業務：店舗営業
  cv_main_wk_shanai         CONSTANT VARCHAR2(1)   := '3';                    -- 主業務：社内業務
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_process_date           DATE;                -- 業務日付
  gf_file_handler           UTL_FILE.FILE_TYPE;  -- ファイル・ハンドラ
--
  gd_active_s_date          DATE;                -- 適用日(開始)
  gd_active_e_date          DATE;                -- 適用日(終了)
  gd_update_s_date          DATE;                -- 最終更新日(開始)
  gd_update_e_date          DATE;                -- 最終更新日(終了)
--
  -- プロファイル
  gt_org_id                 mtl_parameters.organization_id%TYPE;
                                                 -- 営業単位ID
  gv_out_file_dir           VARCHAR2(100);       -- CSVファイル出力先
  gv_out_file_name          VARCHAR2(100);       -- CSVファイル名
  gv_stop_bumon             VARCHAR2(100);       -- 利用停止部署名
  gv_other_wk_honbu         VARCHAR2(500);       -- 他の担当業務（本部営業）
  gv_other_wk_tenpo         VARCHAR2(500);       -- 他の担当業務（店舗営業）
  gv_other_wk_shanai        VARCHAR2(500);       -- 他の担当業務（社内業務）
  gv_licensed_prdcts        VARCHAR2(500);       -- ライセンスする製品
  gv_timezone               VARCHAR2(100);       -- タイムゾーン
  gv_date_format            VARCHAR2(100);       -- 日付フォーマット
  gv_language               VARCHAR2(100);       -- 言語
  gv_holiday_pattern        VARCHAR2(100);       -- 休日パターン
  gv_role                   VARCHAR2(500);       -- ロール
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
  CURSOR get_emp_data_cur
  IS
    SELECT /*+
             INDEX( jrrr JTF_RS_ROLE_RELATIONS_N1 )
           */
           papf.employee_number                    AS employee_number     -- 社員番号
         , papf.per_information18
             || cv_space_full
             || papf.per_information19             AS employee_name       -- 社員氏名
         , papf.last_name
             || cv_space_full
             || papf.first_name                    AS employee_name_kana  -- 社員氏名(カナ)
         , flvq.job_duty_name                      AS job_duty_name1      -- 役職名1
         , flvp.job_duty_name                      AS job_duty_name2      -- 役職名2
         , NVL( flvq.un_licence_kbn ,cv_flag_n )   AS un_licence_kbn      -- 製品ライセンス不要区分
         , hp.party_name                           AS location_name       -- 部署名
         , papf.attribute28                        AS location_code       -- 部署番号
         , SUBSTRB( hl.postal_code ,1 ,3 )
             || cv_hyphen
             || SUBSTRB( hl.postal_code ,4 ,4 )    AS postal_code         -- 郵便番号
         , hl.state
             || hl.city
             || hl.address1
             || hl.address2                        AS address             -- 住所
         , jrrr.start_date_active                  AS start_date_active   -- リソースグループ役割開始日
         , ( CASE
               WHEN ppos.actual_termination_date IS NOT NULL THEN
                 cv_flag_n
               ELSE
                 jrrr.attribute1
             END )                                 AS emp_enabled_flag    -- 従業員有効フラグ
         , jrrr.attribute2                         AS main_work           -- 主業務
         , flvm.main_work_name                     AS main_work_name      -- 主業務名
      FROM jtf_rs_resource_extns   jrse      -- リソースマスタ
         , jtf_rs_group_members    jrgm      -- リソースグループメンバー
         , jtf_rs_groups_vl        jrgv      -- リソースグループ
         , jtf_rs_role_relations   jrrr      -- リソースグループ役割
         , per_all_people_f        papf      -- 従業員マスタ
         , per_all_assignments_f   paaf      -- アサイメントマスタ
         , per_periods_of_service  ppos      -- 従業員サービス期間マスタ
         , hz_cust_accounts        hca       -- 顧客マスタ
         , hz_parties              hp        -- パーティマスタ
         , hz_party_sites          hps       -- パーティサイトマスタ
         , hz_cust_acct_sites_all  hcasa     -- 顧客所在地マスタ
         , hz_locations            hl        -- 顧客事業所マスタ
         , ( SELECT flv.lookup_code       AS qual_code
                  , flv.attribute1        AS job_duty_name
                  , flv.attribute2        AS un_licence_kbn
               FROM fnd_lookup_values flv
              WHERE flv.language     = ct_lang
                AND flv.lookup_type  = cv_lkp_qual_code      -- タイプ：資格コード
                AND flv.enabled_flag = cv_flag_y
           )                       flvq      -- LOOKUP表(資格)
         , ( SELECT flv.lookup_code       AS posi_code
                  , flv.attribute1        AS job_duty_name
               FROM fnd_lookup_values flv
              WHERE flv.language     = ct_lang
                AND flv.lookup_type  = cv_lkp_posi_code      -- タイプ：職位コード
                AND flv.enabled_flag = cv_flag_y
           )                       flvp      -- LOOKUP表(職位)
         , ( SELECT flv.lookup_code       AS main_work
                  , flv.description       AS main_work_name
               FROM fnd_lookup_values flv
              WHERE flv.language     = ct_lang
                AND flv.lookup_type  = cv_lkp_main_work      -- タイプ：eSM主業務
                AND flv.enabled_flag = cv_flag_y
           )                       flvm      -- LOOKUP表(主業務)
     WHERE jrse.category                       = cv_category_emp            -- カテゴリ：従業員
       AND jrse.resource_id                    = jrgm.resource_id
       AND NVL( jrgm.delete_flag ,cv_flag_n )  = cv_flag_n
       AND jrgm.group_id                       = jrgv.group_id
       AND jrgm.group_member_id                = jrrr.role_resource_id
       AND jrrr.role_resource_type             = cv_resource_type_gm
       AND NVL( jrrr.delete_flag ,cv_flag_n )  = cv_flag_n
       AND (
             -- リソースグループ役割の開始日
             ( jrrr.start_date_active         >= gd_active_s_date )
             -- リソースグループ役割の最終更新日
         OR  ( TRUNC( jrrr.last_update_date ) >= gd_update_s_date
           AND TRUNC( jrrr.last_update_date ) <= gd_update_e_date )
             -- 従業員マスタの最終更新日
         OR  ( TRUNC( papf.last_update_date ) >= gd_update_s_date
           AND TRUNC( papf.last_update_date ) <= gd_update_e_date )
             -- パーティマスタの最終更新日
         OR  ( TRUNC( hp.last_update_date )   >= gd_update_s_date
           AND TRUNC( hp.last_update_date )   <= gd_update_e_date )
             -- 顧客事業所マスタの最終更新日
         OR  ( TRUNC( hl.last_update_date )   >= gd_update_s_date
           AND TRUNC( hl.last_update_date )   <= gd_update_e_date )
           )
       AND jrrr.start_date_active             <= gd_active_e_date
       AND jrse.source_id                      = papf.person_id
       AND papf.person_id                      = paaf.person_id
       AND paaf.period_of_service_id           = ppos.period_of_service_id
       AND papf.effective_start_date           = ppos.date_start
       AND papf.attribute28                    = ( CASE
                                                     WHEN ppos.actual_termination_date IS NOT NULL THEN
                                                       papf.attribute28
                                                     ELSE
                                                       jrgv.attribute1
                                                   END )
       AND gd_process_date                     BETWEEN papf.effective_start_date
                                                   AND TO_DATE( cv_max_date ,cv_fmt_std )
       AND gd_process_date                     BETWEEN paaf.effective_start_date
                                                   AND TO_DATE( cv_max_date ,cv_fmt_std )
       AND hca.customer_class_code             = cv_cust_class_base         -- 顧客区分：拠点
       AND hca.cust_account_id                 = hcasa.cust_account_id
       AND hca.party_id                        = hp.party_id
       AND hcasa.party_site_id                 = hps.party_site_id
       AND hps.location_id                     = hl.location_id
       AND hcasa.org_id                        = gt_org_id                  -- 営業単位ID
       AND hca.account_number                  = papf.attribute28           -- 所属部門
       AND papf.attribute7                     = flvq.qual_code             -- 資格コード
       AND papf.attribute11                    = flvp.posi_code             -- 職位コード
       AND jrrr.attribute2                     = flvm.main_work(+)          -- 主業務
       AND jrrr.attribute1                     IS NOT NULL
    ORDER BY
           papf.employee_number    ASC    -- 従業員番号
         , jrrr.start_date_active  DESC   -- 開始日（降順）
         , jrrr.last_update_date   DESC   -- 最終更新日（降順）
    ;
--
  TYPE g_emp_data_ttype IS TABLE OF get_emp_data_cur%ROWTYPE INDEX BY PLS_INTEGER;
  gt_emp_data           g_emp_data_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_update_from  IN  VARCHAR2     --  最終更新日（開始）
  , iv_update_to    IN  VARCHAR2     --  最終更新日（終了）
  , ov_errbuf       OUT VARCHAR2     --  エラー・メッセージ           --# 固定 #
  , ov_retcode      OUT VARCHAR2     --  リターン・コード             --# 固定 #
  , ov_errmsg       OUT VARCHAR2     --  ユーザー・エラー・メッセージ --# 固定 #
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
    lb_fexists              BOOLEAN;          -- ファイルが存在するかどうか
    ln_file_length          NUMBER;           -- ファイル長
    ln_block_size           NUMBER;           -- ブロックサイズ
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
    --================================
    -- 入力パラメータ出力
    --================================
    lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_appl_xxcmm             -- アプリケーション短縮名
                 , iv_name         => cv_input_param_msg        -- メッセージコード
                 , iv_token_name1  => cv_tkn_date_from          -- トークンコード1
                 , iv_token_value1 => iv_update_from            -- トークン値1
                 , iv_token_name2  => cv_tkn_date_to            -- トークンコード2
                 , iv_token_value2 => iv_update_to              -- トークン値2
                 );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg
    );
--
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --================================
    -- 業務日付取得
    --================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- 業務日付が取得できない場合
    IF ( gd_process_date IS NULL ) THEN
      -- 業務日付取得エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_appl_xxcmm            -- アプリケーション短縮名
                   , iv_name        => cv_process_date_err_msg  -- メッセージコード
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    --================================
    -- 処理期間（開始日・終了日）取得
    --================================
    IF  ( iv_update_from IS NULL )
      AND ( iv_update_to IS NULL ) THEN
      -- 適用日（開始）、適用日（終了）に業務日付＋1をセット
      gd_active_s_date := gd_process_date + 1;
      gd_active_e_date := gd_process_date + 1;
      -- 最終更新日（開始）、最終更新日（終了）に業務日付をセット
      gd_update_s_date := gd_process_date;
      gd_update_e_date := gd_process_date + 1;
    ELSE
      -- 適用日（開始）、適用日（終了）に入力パラメータ値をセット
      gd_active_s_date := TO_DATE( iv_update_from ,cv_fmt_std );
      gd_active_e_date := TO_DATE( iv_update_to   ,cv_fmt_std );
      -- 最終更新日に適用日と同じ値をセット
      gd_update_s_date := gd_active_s_date;
      gd_update_e_date := gd_active_e_date;
    END IF;
--
    --================================
    -- 処理対象期間チェック
    --================================
    -- 最終更新日（開始） > 最終更新日（終了）の場合
    IF ( gd_update_s_date > gd_update_e_date ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm               -- アプリケーション短縮名
                   , iv_name         => cv_date_reversal_err_msg    -- メッセージコード
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    --================================
    -- 終了日チェック
    --================================
    -- 入力パラメータ.最終更新日（終了） ≠ 業務日付の場合
    IF ( TO_DATE( iv_update_to ,cv_fmt_std ) <> gd_process_date ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm               -- アプリケーション短縮名
                   , iv_name         => cv_e_date_select_err_msg    -- メッセージコード
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    --================================
    -- プロファイル値取得
    --================================
    -- *******************************
    --  営業単位
    -- *******************************
    gt_org_id := FND_PROFILE.VALUE( cv_prf_org_id );
    -- 取得値がNULLの場合
    IF ( gt_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm           -- アプリケーション短縮名
                   , iv_name         => cv_profile_err_msg      -- メッセージコード
                   , iv_token_name1  => cv_tkn_ng_profile       -- トークンコード1
                   , iv_token_value1 => cv_prf_org_id           -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    -- *******************************
    --  CSVファイル出力先
    -- *******************************
    gv_out_file_dir := FND_PROFILE.VALUE( cv_prf_out_file_dir );
    -- 取得値がNULLの場合
    IF ( gv_out_file_dir IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm           -- アプリケーション短縮名
                   , iv_name         => cv_profile_err_msg      -- メッセージコード
                   , iv_token_name1  => cv_tkn_ng_profile       -- トークンコード1
                   , iv_token_value1 => cv_prf_out_file_dir     -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    -- *******************************
    --  CSVファイル名
    -- *******************************
    gv_out_file_name := FND_PROFILE.VALUE( cv_prf_out_file_name );
    -- 取得値がNULLの場合
    IF ( gv_out_file_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm           -- アプリケーション短縮名
                   , iv_name         => cv_profile_err_msg      -- メッセージコード
                   , iv_token_name1  => cv_tkn_ng_profile       -- トークンコード1
                   , iv_token_value1 => cv_prf_out_file_name    -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    -- *******************************
    --  利用停止部署
    -- *******************************
    gv_stop_bumon := FND_PROFILE.VALUE( cv_prf_stop_bumon );
    -- 取得値がNULLの場合
    IF ( gv_stop_bumon IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm           -- アプリケーション短縮名
                   , iv_name         => cv_profile_err_msg      -- メッセージコード
                   , iv_token_name1  => cv_tkn_ng_profile       -- トークンコード1
                   , iv_token_value1 => cv_prf_stop_bumon       -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    -- *******************************
    --  他の担当業務（本部営業）
    -- *******************************
    gv_other_wk_honbu := FND_PROFILE.VALUE( cv_prf_other_wk_honbu );
    -- 取得値がNULLの場合
    IF ( gv_other_wk_honbu IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm           -- アプリケーション短縮名
                   , iv_name         => cv_profile_err_msg      -- メッセージコード
                   , iv_token_name1  => cv_tkn_ng_profile       -- トークンコード1
                   , iv_token_value1 => cv_prf_other_wk_honbu   -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    -- *******************************
    --  他の担当業務（店舗営業）
    -- *******************************
    gv_other_wk_tenpo := FND_PROFILE.VALUE( cv_prf_other_wk_tenpo );
    -- 取得値がNULLの場合
    IF ( gv_other_wk_tenpo IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm           -- アプリケーション短縮名
                   , iv_name         => cv_profile_err_msg      -- メッセージコード
                   , iv_token_name1  => cv_tkn_ng_profile       -- トークンコード1
                   , iv_token_value1 => cv_prf_other_wk_tenpo   -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    -- *******************************
    --  他の担当業務（社内業務）
    -- *******************************
    gv_other_wk_shanai := FND_PROFILE.VALUE( cv_prf_other_wk_shanai );
    -- 取得値がNULLの場合
    IF ( gv_other_wk_shanai IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm           -- アプリケーション短縮名
                   , iv_name         => cv_profile_err_msg      -- メッセージコード
                   , iv_token_name1  => cv_tkn_ng_profile       -- トークンコード1
                   , iv_token_value1 => cv_prf_other_wk_shanai  -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    -- *******************************
    --  ライセンスする製品
    -- *******************************
    gv_licensed_prdcts := FND_PROFILE.VALUE( cv_prf_licensed_prdcts );
    -- 取得値がNULLの場合
    IF ( gv_licensed_prdcts IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm           -- アプリケーション短縮名
                   , iv_name         => cv_profile_err_msg      -- メッセージコード
                   , iv_token_name1  => cv_tkn_ng_profile       -- トークンコード1
                   , iv_token_value1 => cv_prf_licensed_prdcts  -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    -- *******************************
    --  タイムゾーン
    -- *******************************
    gv_timezone := FND_PROFILE.VALUE( cv_prf_timezone );
    -- 取得値がNULLの場合
    IF ( gv_timezone IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm           -- アプリケーション短縮名
                   , iv_name         => cv_profile_err_msg      -- メッセージコード
                   , iv_token_name1  => cv_tkn_ng_profile       -- トークンコード1
                   , iv_token_value1 => cv_prf_timezone         -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    -- *******************************
    --  日付フォーマット
    -- *******************************
    gv_date_format := FND_PROFILE.VALUE( cv_prf_date_format );
    -- 取得値がNULLの場合
    IF ( gv_date_format IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm           -- アプリケーション短縮名
                   , iv_name         => cv_profile_err_msg      -- メッセージコード
                   , iv_token_name1  => cv_tkn_ng_profile       -- トークンコード1
                   , iv_token_value1 => cv_prf_date_format      -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    -- *******************************
    --  言語
    -- *******************************
    gv_language := FND_PROFILE.VALUE( cv_prf_language );
    -- 取得値がNULLの場合
    IF ( gv_language IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm           -- アプリケーション短縮名
                   , iv_name         => cv_profile_err_msg      -- メッセージコード
                   , iv_token_name1  => cv_tkn_ng_profile       -- トークンコード1
                   , iv_token_value1 => cv_prf_language         -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    -- *******************************
    --  休日パターン
    -- *******************************
    gv_holiday_pattern := FND_PROFILE.VALUE( cv_prf_holiday_pattern );
    -- 取得値がNULLの場合
    IF ( gv_holiday_pattern IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm           -- アプリケーション短縮名
                   , iv_name         => cv_profile_err_msg      -- メッセージコード
                   , iv_token_name1  => cv_tkn_ng_profile       -- トークンコード1
                   , iv_token_value1 => cv_prf_holiday_pattern  -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    -- *******************************
    --  ロール
    -- *******************************
    gv_role := FND_PROFILE.VALUE( cv_prf_role );
    -- 取得値がNULLの場合
    IF ( gv_role IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm           -- アプリケーション短縮名
                   , iv_name         => cv_profile_err_msg      -- メッセージコード
                   , iv_token_name1  => cv_tkn_ng_profile       -- トークンコード1
                   , iv_token_value1 => cv_prf_role             -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    --================================
    -- CSVファイル名出力
    --================================
    lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_appl_xxccp             -- アプリケーション短縮名
                 , iv_name         => cv_file_name_msg          -- メッセージコード
                 , iv_token_name1  => cv_tkn_file_name          -- トークンコード1
                 , iv_token_value1 => gv_out_file_name          -- トークン値1
                 );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => lv_errmsg
    );
--
    --================================
    -- CSVファイル存在チェック
    --================================
    UTL_FILE.FGETATTR(
      location     => gv_out_file_dir     -- CSVファイル出力先
    , filename     => gv_out_file_name    -- CSVファイル名
    , fexists      => lb_fexists
    , file_length  => ln_file_length
    , block_size   => ln_block_size
    );
    IF ( lb_fexists = TRUE ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_appl_xxcmm             -- アプリケーション短縮名
                   , iv_name        => cv_file_exists_err_msg    -- メッセージコード
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    -- 空行挿入
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => ''
    );
--
  EXCEPTION
    --*** 初期処理例外 ***
    WHEN global_init_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
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
   * Procedure Name   : open_csv_file
   * Description      : ファイルオープン処理(A-2)
   ***********************************************************************************/
  PROCEDURE open_csv_file(
    ov_errbuf       OUT VARCHAR2             --   エラー・メッセージ                  --# 固定 #
  , ov_retcode      OUT VARCHAR2             --   リターン・コード                    --# 固定 #
  , ov_errmsg       OUT VARCHAR2             --   ユーザー・エラー・メッセージ        --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'open_csv_file'; -- プログラム名
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
    cn_record_byte  CONSTANT NUMBER       := 5000;  -- ファイル読み込み文字数
    cv_file_mode    CONSTANT VARCHAR2(1)  := 'W';   -- 書き込みモード
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
    BEGIN
      --================================
      -- ファイルオープン
      --================================
      gf_file_handler := UTL_FILE.FOPEN(
                           location      => gv_out_file_dir      -- CSVファイル出力先
                         , filename      => gv_out_file_name     -- CSVファイル名
                         , open_mode     => cv_file_mode         -- 書き込みモード
                         , max_linesize  => cn_record_byte
                         );
    EXCEPTION
      -- ファイルオープンエラー
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_xxcmm              -- アプリケーション短縮名
                     , iv_name         => cv_file_open_err_msg       -- メッセージコード
                     , iv_token_name1  => cv_tkn_sqlerrm             -- トークンコード1
                     , iv_token_value1 => SQLERRM                    -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_f_open_err_expt;
    END;
--
  EXCEPTION
    --*** ファイルオープンエラー ***
    WHEN global_f_open_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END open_csv_file;
--
  /**********************************************************************************
   * Procedure Name   : get_emp_data
   * Description      : 従業員データ取得処理(A-3)
   ***********************************************************************************/
  PROCEDURE get_emp_data(
    ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
  , ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
  , ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_emp_data';       -- プログラム名
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
    -- カーソルオープン
    OPEN get_emp_data_cur;
    FETCH get_emp_data_cur BULK COLLECT INTO gt_emp_data;
--
    -- 対象件数カウント
    gn_target_cnt := gt_emp_data.COUNT;
--
    -- カーソルクローズ
    CLOSE get_emp_data_cur;
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
  END get_emp_data;
--
  /**********************************************************************************
   * Procedure Name   : output_csv_data
   * Description      : CSVファイル出力処理(A-4)
   ***********************************************************************************/
  PROCEDURE output_csv_data(
    ov_errbuf               OUT VARCHAR2               --   エラー・メッセージ                  --# 固定 #
  , ov_retcode              OUT VARCHAR2               --   リターン・コード                    --# 固定 #
  , ov_errmsg               OUT VARCHAR2               --   ユーザー・エラー・メッセージ        --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'output_csv_data'; -- プログラム名
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
    ln_cnt                 NUMBER;               -- ループカウンタ
    lv_hdr_text            VARCHAR2(2000);       -- ヘッダ文字列格納用変数
    lv_csv_text            VARCHAR2(5000);       -- 出力文字列格納用変数
--
    lt_employee_number     per_all_people_f.employee_number%TYPE;
                                                 -- 従業員番号退避用
    lv_job_duty_name       VARCHAR2(100);        -- 役職名
    lv_location_name       VARCHAR2(50);         -- 部署名
    lv_location_code       VARCHAR2(9);          -- 部署番号
    lv_other_work          VARCHAR2(500);        -- 他の担当業務
    lv_licensed_prdcts     VARCHAR2(500);        -- ライセンスする製品
    lv_role                VARCHAR2(500);        -- ロール
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
--
      -- ローカル変数の初期化
      lt_employee_number := NULL;  -- 従業員番号退避用
--
      -- ===============================
      -- CSVファイルヘッダ取得
      -- ===============================
      lv_hdr_text := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_xxcmm       -- アプリケーション短縮名
                     , iv_name         => cv_csv_header_msg   -- メッセージコード
                     );
--
      -- ===============================
      -- CSVファイルヘッダ出力
      -- ===============================
      -- ファイル書き込み
      UTL_FILE.PUT_LINE(
        file      => gf_file_handler
      , buffer    => lv_hdr_text
      , autoflush => FALSE
      );
--
      -- ===============================
      -- 従業員データ出力
      -- ===============================
      -- 対象レコードが存在する場合
      IF ( gn_target_cnt > 0 ) THEN
--
        <<emp_data_loop>>
        FOR ln_cnt IN gt_emp_data.FIRST..gt_emp_data.LAST LOOP
--
          -- *******************************
          --  主業務NULLチェック
          -- *******************************
          IF ( gt_emp_data(ln_cnt).main_work IS NULL ) THEN
--
           -- eSM主業務未設定エラー
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_xxcmm                         -- アプリケーション短縮名
                         , iv_name         => cv_main_work_err_msg                  -- メッセージコード
                         , iv_token_name1  => cv_tkn_employee_number                -- トークンコード1
                         , iv_token_value1 => gt_emp_data(ln_cnt).employee_number   -- トークン値1
                         , iv_token_name2  => cv_tkn_start_date_active              -- トークンコード2
                         , iv_token_value2 => TO_CHAR( gt_emp_data(ln_cnt).start_date_active ,cv_fmt_std )
                                                                                    -- トークン値2
                         );
            -- メッセージ出力
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
            , buff   => lv_errmsg --ユーザー・エラーメッセージ
            );
            -- スキップ件数カウント
            gn_warn_cnt := gn_warn_cnt + 1;
--
          -- 上記以外の場合
          ELSE
--
            -- *******************************
            --  リソースグループ役割重複チェック
            -- *******************************
            -- 最初のレコード、または前レコードと従業員番号が異なる場合
            IF ( lt_employee_number IS NULL )
              OR ( lt_employee_number <> gt_emp_data(ln_cnt).employee_number ) THEN
--
              -- ローカル変数の初期化
              lv_job_duty_name   := NULL;  -- 役職名
              lv_location_name   := NULL;  -- 部署名
              lv_location_code   := NULL;  -- 部署番号
              lv_other_work      := NULL;  -- 他の担当業務
              lv_licensed_prdcts := NULL;  -- ライセンスする製品
              lv_role            := NULL;  -- ロール
--
              -- *******************************
              --  CSV出力値設定
              -- *******************************
              -- 役職1がNULL以外の場合
              IF ( gt_emp_data(ln_cnt).job_duty_name1 IS NOT NULL ) THEN
                -- 役職名
                lv_job_duty_name   := SUBSTRB ( gt_emp_data(ln_cnt).job_duty_name1 ,1 ,100 );
              ELSE
                -- 役職名
                lv_job_duty_name   := SUBSTRB ( gt_emp_data(ln_cnt).job_duty_name2 ,1 ,100 );
              END IF;
--
              -- 有効な社員の場合
              IF ( gt_emp_data(ln_cnt).emp_enabled_flag = cv_flag_y ) THEN
                -- 部署名
                lv_location_name   := SUBSTRB ( REPLACE( gt_emp_data(ln_cnt).location_name ,cv_comma ,NULL ) ,1 ,50 );
                -- 部署番号
                lv_location_code   := gt_emp_data(ln_cnt).location_code;
                -- ライセンスする製品
                lv_licensed_prdcts := gv_licensed_prdcts;
                -- ロール
                lv_role            := gv_role;
              ELSE
                -- 部署名
                lv_location_name   := NULL;
                -- 部署番号
                lv_location_code   := gv_stop_bumon;
                -- ライセンスする製品
                lv_licensed_prdcts := NULL;
                -- ロール
                lv_role            := NULL;
              END IF;
--
              -- ライセンス不要の場合
              IF ( gt_emp_data(ln_cnt).un_licence_kbn = cv_flag_y ) THEN
                -- ライセンスする製品
                lv_licensed_prdcts := NULL;
              END IF;
--
              -- 主業務が「本部営業」の場合
              IF ( gt_emp_data(ln_cnt).main_work = cv_main_wk_honbu ) THEN
                -- 他の担当業務
                lv_other_work      := gv_other_wk_honbu;
              -- 主業務が「店舗営業」の場合
              ELSIF ( gt_emp_data(ln_cnt).main_work = cv_main_wk_tenpo ) THEN
                -- 他の担当業務
                lv_other_work      := gv_other_wk_tenpo;
              -- 主業務が「社内業務」の場合
              ELSIF ( gt_emp_data(ln_cnt).main_work = cv_main_wk_shanai ) THEN
                -- 他の担当業務
                lv_other_work      := gv_other_wk_shanai;
              ELSE
                -- 他の担当業務
                lv_other_work      := NULL;
              END IF;
--
              -- *******************************
              --  出力文字列の生成
              -- *******************************
              lv_csv_text :=   SUBSTRB( gt_emp_data(ln_cnt).employee_number ,1 ,50 )  -- 社員番号
                || cv_comma || SUBSTRB( REPLACE( gt_emp_data(ln_cnt).employee_name ,cv_comma ,NULL ) ,1 ,100 )
                                                                                      -- 社員氏名
                || cv_comma || SUBSTRB( REPLACE( gt_emp_data(ln_cnt).employee_name_kana ,cv_comma ,NULL ) ,1 ,50 )
                                                                                      -- 社員氏名（カナ）
                || cv_comma || lv_job_duty_name                                       -- 役職名
                || cv_comma || lv_location_name                                       -- 部署名
                || cv_comma || lv_location_code                                       -- 部署番号
                || cv_comma || gt_emp_data(ln_cnt).postal_code                        -- 郵便番号
                || cv_comma || SUBSTRB( REPLACE( gt_emp_data(ln_cnt).address ,cv_comma ,NULL ) ,1 ,900 )
                                                                                      -- 住所
                || cv_comma || NULL                                                   -- 電話番号
                || cv_comma || NULL                                                   -- 電話番号2
                || cv_comma || NULL                                                   -- 電話番号3
                || cv_comma || NULL                                                   -- email
                || cv_comma || NULL                                                   -- パスワード
                || cv_comma || SUBSTRB( gt_emp_data(ln_cnt).main_work_name ,1 ,60 )   -- 主業務
                || cv_comma || lv_other_work                                          -- 他の担当業務
                || cv_comma || lv_licensed_prdcts                                     -- ライセンスする製品
                || cv_comma || NULL                                                   -- 携帯端末ID
                || cv_comma || gv_timezone                                            -- タイムゾーン
                || cv_comma || gv_date_format                                         -- 日付フォーマット
                || cv_comma || gv_language                                            -- 言語
                || cv_comma || gv_holiday_pattern                                     -- 休日パターン
                || cv_comma || lv_role                                                -- ロール
                || cv_comma || NULL                                                   -- 建物名
                || cv_comma || NULL                                                   -- 講演セミナー
              ;
--
              -- *******************************
              --  CSVファイル書き込み
              -- *******************************
              UTL_FILE.PUT_LINE(
                file      => gf_file_handler
              , buffer    => lv_csv_text
              , autoflush => FALSE
              );
--
              -- 成功件数カウント
              gn_normal_cnt := gn_normal_cnt + 1;
              -- 従業員番号退避
              lt_employee_number := gt_emp_data(ln_cnt).employee_number;
--
            -- 上記以外の場合
            ELSE
              -- リソースグループ役割重複エラー
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_xxcmm                         -- アプリケーション短縮名
                           , iv_name         => cv_resource_err_msg                   -- メッセージコード
                           , iv_token_name1  => cv_tkn_employee_number                -- トークンコード1
                           , iv_token_value1 => gt_emp_data(ln_cnt).employee_number   -- トークン値1
                           , iv_token_name2  => cv_tkn_start_date_active              -- トークンコード2
                           , iv_token_value2 => TO_CHAR( gt_emp_data(ln_cnt).start_date_active ,cv_fmt_std )
                                                                                      -- トークン値2
                           );
              -- メッセージ出力
              FND_FILE.PUT_LINE(
                which  => FND_FILE.OUTPUT
              , buff   => lv_errmsg --ユーザー・エラーメッセージ
              );
              -- スキップ件数カウント
              gn_warn_cnt := gn_warn_cnt + 1;
            END IF;
--
          END IF;
--
        END LOOP emp_data_loop;
--
      END IF;
--
    EXCEPTION
      -- CSVデータ出力エラー
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_xxcmm             -- アプリケーション短縮名
                     , iv_name         => cv_file_write_err_msg     -- メッセージコード
                     , iv_token_name1  => cv_tkn_sqlerrm            -- トークンコード1
                     , iv_token_value1 => SQLERRM                   -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
    END;
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
  END output_csv_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf                 OUT VARCHAR2    -- エラー・メッセージ           --# 固定 #
  , ov_retcode                OUT VARCHAR2    -- リターン・コード             --# 固定 #
  , ov_errmsg                 OUT VARCHAR2    -- ユーザー・エラー・メッセージ --# 固定 #
  , iv_update_from            IN  VARCHAR2    -- 最終更新日（開始）
  , iv_update_to              IN  VARCHAR2    -- 最終更新日（終了）
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
    gn_warn_cnt   := 0;
    gn_error_cnt  := 0;
--
    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    init(
      iv_update_from     -- 最終更新日（開始）
    , iv_update_to       -- 最終更新日（終了）
    , lv_errbuf          -- エラー・メッセージ           --# 固定 #
    , lv_retcode         -- リターン・コード             --# 固定 #
    , lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      -- エラー処理
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ファイルオープン処理(A-2)
    -- ===============================
    open_csv_file(
      lv_errbuf          -- エラー・メッセージ           --# 固定 #
    , lv_retcode         -- リターン・コード             --# 固定 #
    , lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      -- エラー処理
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 従業員データ取得処理(A-3)
    -- ===============================
    get_emp_data(
      lv_errbuf               -- エラー・メッセージ           --# 固定 #
    , lv_retcode              -- リターン・コード             --# 固定 #
    , lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- CSVファイル出力処理(A-4)
    -- ===============================
    output_csv_data(
      lv_errbuf               -- エラー・メッセージ           --# 固定 #
    , lv_retcode              -- リターン・コード             --# 固定 #
    , lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 終了処理(A-5)
    -- ===============================
    BEGIN
      -- ファイルクローズ処理
      IF ( UTL_FILE.IS_OPEN( gf_file_handler ) ) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE( gf_file_handler );
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_xxcmm           -- アプリケーション短縮名
                  , iv_name         => cv_file_close_err_msg   -- メッセージコード
                  , iv_token_name1  => cv_tkn_sqlerrm          -- トークンコード1
                  , iv_token_value1 => SQLERRM                 -- トークン値1
                  );
        lv_errbuf := lv_errmsg;
        RAISE global_f_close_err_expt;
    END;
--
    -- スキップ件数が1件以上の場合は警告を返却
    IF ( gn_warn_cnt > 0 ) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
    -- *** ファイルクローズエラー ***
    WHEN global_f_close_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
    errbuf                    OUT VARCHAR2      -- エラー・メッセージ  --# 固定 #
  , retcode                   OUT VARCHAR2      -- リターン・コード    --# 固定 #
  , iv_update_from            IN  VARCHAR2      -- 最終更新日（開始）
  , iv_update_to              IN  VARCHAR2      -- 最終更新日（終了）
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
--
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
    , ov_errbuf  => lv_errbuf
    , ov_errmsg  => lv_errmsg
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      lv_errbuf        -- エラー・メッセージ           --# 固定 #
    , lv_retcode       -- リターン・コード             --# 固定 #
    , lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
    , iv_update_from   -- 最終更新日（開始）
    , iv_update_to     -- 最終更新日（終了）
    );
--
    -- ===============================
    -- 終了処理(A-5)
    -- ===============================
    -- エラー出力
    IF ( lv_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => lv_errbuf --エラーメッセージ
      );
      -- エラー時件数カウント
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_warn_cnt   := 0;
      gn_error_cnt  := 1;
    END IF;
--
    -- 空行挿入
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => ''
    );
--
    -- 対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                  , iv_name         => cv_target_rec_msg
                  , iv_token_name1  => cv_cnt_token
                  , iv_token_value1 => TO_CHAR( gn_target_cnt )
                  );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => gv_out_msg
    );
--
    -- 成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                  , iv_name         => cv_success_rec_msg
                  , iv_token_name1  => cv_cnt_token
                  , iv_token_value1 => TO_CHAR( gn_normal_cnt )
                  );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => gv_out_msg
    );
--
    -- スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                  , iv_name         => cv_skip_rec_msg
                  , iv_token_name1  => cv_cnt_token
                  , iv_token_value1 => TO_CHAR( gn_warn_cnt )
                  );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => gv_out_msg
    );
--
    -- エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => gv_out_msg
    );
--
    -- 終了メッセージ
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                  , iv_name         => lv_message_code
                  );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => gv_out_msg
    );
--
    -- ファイルがクローズされていなかった場合、クローズする
    IF ( UTL_FILE.IS_OPEN( gf_file_handler ) ) THEN
      -- ファイルクローズ
      UTL_FILE.FCLOSE( gf_file_handler );
    END IF;
--
    -- ステータスセット
    retcode := lv_retcode;
--
    -- 終了ステータスがエラーの場合はROLLBACKする
    IF ( retcode = cv_status_error ) THEN
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
END XXCMM002A07C;
/
