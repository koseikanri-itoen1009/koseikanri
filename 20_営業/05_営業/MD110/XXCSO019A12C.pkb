CREATE OR REPLACE PACKAGE BODY APPS.XXCSO019A12C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2018. All rights reserved.
 *
 * Package Name     : XXCSO005A02C(body)
 * Description      : ルートNo／営業員CSV出力
 * MD.050           : ルートNo／営業員CSV出力 (MD050_CSO_019A12)
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_route_emp_data     ルートNo／営業員情報取得(A-2)
 *  output_data            CSVファイル出力(A-3)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2018/03/08    1.0   K.Kiriu          新規作成(E_本稼動_14722)
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
  init_err_expt                 EXCEPTION;      -- 初期処理例外
  global_warn_expt              EXCEPTION;      -- データなし例外
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name              CONSTANT VARCHAR2(100) := 'XXCSO019A12C';                 -- パッケージ名
--
  -- アプリケーション短縮名
  cv_appl_name_xxcso       CONSTANT VARCHAR2(10)  := 'XXCSO';                        -- XXCSO
  -- 日付書式
  cv_fmt_yyyymmdd          CONSTANT VARCHAR2(50)  := 'YYYY/MM/DD';
  -- 文字区切り
  cv_comma                 CONSTANT VARCHAR2(1)   := ',';                            -- カンマ
  -- メッセージコード
  cv_msg_cso_00130         CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00130';             -- 拠点コード
  cv_msg_cso_00842         CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00842';             -- 営業員
  cv_msg_cso_00843         CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00843';             -- ルートNo
  cv_msg_cso_00011         CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00011';             -- 業務日付取得エラー
  cv_msg_cso_00649         CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00649';             -- データ追加エラー
  cv_msg_cso_00224         CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00224';             -- CSVファイル出力0件エラー
  cv_msg_cso_00844         CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00844';             -- ルートNo／営業員CSVヘッダ
  cv_msg_cso_00845         CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00845';             -- ルートNo／営業員CSV出力一時表
  -- トークン
  cv_tkn_err_message       CONSTANT VARCHAR2(11)  := 'ERR_MESSAGE';                  -- SQLエラーメッセージ
  cv_tkn_entry             CONSTANT VARCHAR2(5)   := 'ENTRY';                        -- 入力値
  cv_tkn_count             CONSTANT VARCHAR2(5)   := 'COUNT';                        -- 件数
  cv_tkn_table             CONSTANT VARCHAR2(5)   := 'TABLE';                        -- テーブル
  -- 参照タイプ
  cv_route_mgr_cust_class  CONSTANT VARCHAR2(27)  := 'XXCSO1_ROUTE_MGR_CUST_CLASS';  -- ルートNo管理対象顧客
  cv_customer_class        CONSTANT VARCHAR2(14)  := 'CUSTOMER CLASS';               -- 顧客区分
  -- 顧客区分ダミー
  cv_00                    CONSTANT VARCHAR2(2)   := '00';                           -- 顧客区分NULLの場合のダミー
  -- yes no
  cv_yes                   CONSTANT VARCHAR2(1)   := 'Y';                            -- YES
  cv_no                    CONSTANT VARCHAR2(1)   := 'N';                            -- NO
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- パラメータ格納用
  gt_base_code            jtf_rs_groups_vl.attribute1%TYPE;       -- パラメータ：拠点コード
  gt_employee_number      per_people_f.employee_number%TYPE;      -- パラメータ：営業員コード
  gt_route_no             hz_org_profiles_ext_b.c_ext_attr2%TYPE; -- パラメータ：ルートNo
  -- 処理日付用
  gd_process_date         DATE;                                   -- 業務日付
  gd_next_date            DATE;                                   -- 業務日付翌日
  gd_next_month_last_date DATE;                                   -- 業務日付の翌月末日
--
  -- ===============================
  -- ユーザー定義グローバル・カーソル
  -- ===============================
  CURSOR route_emp_cur
  IS
    SELECT  sub.customer_class_name  customer_class_name  -- 顧客区分名
           ,sub.account_number       account_number       -- 顧客コード
           ,sub.party_name           party_name           -- 顧客名
           ,sub.trgt_resource        trgt_resource        -- 現担当
           ,sub.trgt_route_no        trgt_route_no        -- 現ルートNo
           ,sub.next_resource        next_resource        -- 新担当
           ,sub.next_route_no        next_route_no        -- 新ルートNo
    FROM    (
              -- 現担当 ※売掛金管理先顧客以外
              SELECT  /*+
                        LEADING(xrcv1.fa xrcv1.efdfc xrrv1.rtn_ctx xrrv1.rsrc_ctx xtrr1)
                        INDEX(xrcv1.fa fnd_application_u3)
                        USE_NL(xrcv1.fa xrcv1.efdfce xrrv1.rtn_ctx xrrv1.rsrc_ctx xtrr1)
                      */
                      '1'                                sort_code
                     ,xcav1.customer_class_name          customer_class_name
                     ,xrrv1.account_number               account_number
                     ,xcav1.party_name                   party_name
                     ,xrrv1.trgt_resource                trgt_resource
                     ,xrrv1.trgt_route_no                trgt_route_no
                     ,xrrv1.next_resource                next_resource
                     ,xrrv1.next_route_no                next_route_no
              FROM    xxcso_tmp_rtn_rsrc      xtrr1  -- ルートNo／営業員CSV出力一時表
                     ,xxcso_resource_custs_v2 xrcv1  -- 顧客担当営業員（最新）ビュー
                     ,xxcso_rtn_rsrc_v        xrrv1  -- 訪問・売上計画／ルートNo担当営業員一括更新画面用ビュー
                     ,xxcso_cust_accounts_v   xcav1  -- 顧客マスタビュー
                     ,fnd_lookup_values_vl    flvv1  -- 参照タイプ「ルートNo管理対象顧客」
              WHERE   xtrr1.employee_number  = xrcv1.employee_number
              AND     xrcv1.account_number   = xrrv1.account_number
              AND     xrrv1.account_number   = xcav1.account_number
              AND     (
                        xcav1.sale_base_code = xtrr1.base_code
                        OR
                        xcav1.sale_base_code IS NULL  -- 画面より作成したMC候補・MCの場合の条件
                      )
              AND     flvv1.lookup_type      = cv_route_mgr_cust_class
              AND     gd_process_date        BETWEEN flvv1.start_date_active
                                             AND     NVL( flvv1.end_date_active, gd_process_date )
              AND     flvv1.attribute1       = cv_no  -- 売掛金管理先以外
              AND     NVL( xcav1.customer_class_code, cv_00 ) || '-' || xcav1.customer_status = flvv1.lookup_code
              AND     (
                        (
                          ( gt_route_no IS NOT NULL )
                          AND
                          ( EXISTS(
                              SELECT  /*+
                                        LEADING(xcrv1.hca)
                                        USE_NL(xcrv1.hca xcrv1.fa xcrv1.hp xcrv1.hop xcrv1.efdfce xcrv1.hopeb)
                                      */
                                      1
                               FROM   xxcso_cust_routes_v2  xcrv1
                               WHERE  xcrv1.route_number    = gt_route_no
                               AND    xcrv1.account_number  = xcav1.account_number
                            )
                          )
                        )
                        OR
                        ( gt_route_no IS NULL )
                      )
              UNION ALL
              -- 予約(新担当) ※売掛金管理先顧客以外
              SELECT  /*+
                        LEADING(xrcv2.fa xrcv2.efdfc xrrv2.rtn_ctx xrrv2.rsrc_ctx xtrr2 )
                        INDEX(xrcv2.fa fnd_application_u3)
                        USE_NL(xrcv2.fa xrcv2.efdfce xrrv2.rtn_ctx xrrv2.rsrc_ctx xtrr2)
                      */
                      '1'                                sort_code
                     ,xcav2.customer_class_name          customer_class_name
                     ,xrrv2.account_number               account_number
                     ,xcav2.party_name                   party_name
                     ,xrrv2.trgt_resource                trgt_resource
                     ,xrrv2.trgt_route_no                trgt_route_no
                     ,xrrv2.next_resource                next_resource
                     ,xrrv2.next_route_no                next_route_no
              FROM    xxcso_tmp_rtn_rsrc      xtrr2  -- ルートNo／営業員CSV出力一時表
                     ,xxcso_resource_custs_v  xrcv2  -- 顧客担当営業員ビュー
                     ,xxcso_rtn_rsrc_v        xrrv2  -- 訪問・売上計画／ルートNo担当営業員一括更新画面用ビュー
                     ,xxcso_cust_accounts_v   xcav2  -- 顧客マスタビュー
                     ,fnd_lookup_values_vl    flvv2  -- 参照タイプ「ルートNo管理対象顧客」
              WHERE   xtrr2.employee_number         = xrcv2.employee_number
              AND     xrcv2.start_date_active       > gd_process_date         -- 翌日以降
              AND     xrcv2.end_date_active         IS NULL
              AND     xrcv2.account_number          = xrrv2.account_number
              AND     xrrv2.account_number          = xcav2.account_number
              AND     flvv2.lookup_type             = cv_route_mgr_cust_class
              AND     gd_process_date               BETWEEN flvv2.start_date_active
                                                    AND     NVL( flvv2.end_date_active, gd_process_date )
              AND     flvv2.attribute1              = cv_no                   -- 売掛金管理先以外
              AND     NVL( xcav2.customer_class_code, cv_00 ) || '-' || xcav2.customer_status = flvv2.lookup_code
              AND     xcav2.rsv_sale_base_code      = xtrr2.base_code
              AND     xcav2.rsv_sale_base_act_date >= gd_next_date            -- 業務日付の翌日以降
              AND     xcav2.rsv_sale_base_act_date <= gd_next_month_last_date -- 業務日付の翌月月末
              AND     (
                        (
                          ( gt_route_no IS NOT NULL )
                          AND
                          ( EXISTS(
                              SELECT  /*+ 
                                        LEADING(xcrv2.hca)
                                        USE_NL(xcrv2.hca xcrv2.fa xcrv2.hp xcrv2.hop xcrv2.efdfce xcrv2.hopeb)
                                      */
                                      1
                              FROM    xxcso_cust_routes_v  xcrv2
                              WHERE   xcrv2.route_number       = gt_route_no
                              AND     xcrv2.start_date_active  > gd_process_date --翌日以降
                              AND     xcrv2.end_date_active    IS NULL
                              AND     xcrv2.account_number     = xcav2.account_number
                            )
                          )
                        )
                        OR
                        ( gt_route_no IS NULL )
                      )
              UNION ALL
              -- 売上金管理先顧客
              SELECT  /*+
                        LEADING(xrcv3.fa xrcv3.efdfc xrrv3.rtn_ctx xrrv3.rsrc_ctx xtrr3)
                        INDEX(xrcv3.fa fnd_application_u3)
                        USE_NL(xrcv3.fa xrcv3.efdfce xrrv3.rtn_ctx xrrv3.rsrc_ctx xtrr3)
                      */
                      '3'                                sort_code
                     ,xxcso_util_common_pkg.get_lookup_meaning(
                        cv_customer_class
                       ,hca3.customer_class_code
                       ,gd_process_date
                      )                                  customer_class_name
                     ,xrrv3.account_number               account_number
                     ,hp3.party_name                     party_name
                     ,xrrv3.trgt_resource                trgt_resource
                     ,xrrv3.trgt_route_no                trgt_route_no
                     ,xrrv3.next_resource                next_resource
                     ,xrrv3.next_route_no                next_route_no
              FROM    xxcso_tmp_rtn_rsrc       xtrr3  -- ルートNo／営業員CSV出力一時表
                     ,xxcso_resource_custs_v2  xrcv3  -- 顧客担当営業員ビュー
                     ,xxcso_rtn_rsrc_v         xrrv3  -- 訪問・売上計画／ルートNo担当営業員一括更新画面用ビュー
                     ,hz_cust_accounts         hca3   -- 顧客マスタ
                     ,hz_parties               hp3    -- パーティマスタ
                     ,xxcmm_cust_accounts      xca3   -- 顧客追加情報
                     ,fnd_lookup_values_vl     flvv3  -- 参照タイプ「ルートNo管理対象顧客」
              WHERE   xtrr3.employee_number     = xrcv3.employee_number
              AND     xrcv3.account_number      = xrrv3.account_number
              AND     xrrv3.account_number      = hca3.account_number
              AND     hca3.party_id             = hp3.party_id
              AND     hca3.cust_account_id      = xca3.customer_id
              AND     flvv3.lookup_type         = cv_route_mgr_cust_class
              AND     gd_process_date           BETWEEN flvv3.start_date_active
                                                AND     NVL( flvv3.end_date_active, gd_process_date )
              AND     flvv3.attribute1          = cv_yes  -- 売掛金管理先
              AND     hca3.customer_class_code || '-' || hp3.duns_number_c = flvv3.lookup_code
              AND     xca3.receiv_base_code     = xtrr3.base_code
              AND     gt_route_no IS NULL                 -- 売掛金管理先顧客にルートNoはない
            ) sub
    ORDER BY
      sub.trgt_resource   -- 現担当
     ,sub.sort_code       -- ソートコード(売掛金管理先顧客以外が優先）
     ,sub.account_number  -- 顧客コード
    ;
--
  --取得データ格納変数定義
  TYPE g_out_file_ttype IS TABLE OF route_emp_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  gt_out_file_tab       g_out_file_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_base_code       IN  VARCHAR2  -- 1.拠点コード
   ,iv_employee_number IN  VARCHAR2  -- 2.営業員
   ,iv_route_no        IN  VARCHAR2  -- 3.ルートNo
   ,ov_errbuf          OUT VARCHAR2  --   エラー・メッセージ           --# 固定 #
   ,ov_retcode         OUT VARCHAR2  --   リターン・コード             --# 固定 #
   ,ov_errmsg          OUT VARCHAR2  --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_msg_base_code   VARCHAR2(100);  -- 拠点コード出力用
    lv_msg_emp_number  VARCHAR2(100);  -- 営業員出力用
    lv_msg_route_no    VARCHAR2(100);  -- ルートNo出力用
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
    --==================================================
    -- 入力パラメータ格納
    --==================================================
--
    gt_base_code       := iv_base_code;
    gt_employee_number := iv_employee_number;
    gt_route_no        := iv_route_no;
--
    --==================================================
    -- ログ出力
    --==================================================
--
    -- 拠点コード
    lv_msg_base_code   := xxccp_common_pkg.get_msg(
                            iv_application  => cv_appl_name_xxcso  -- アプリケーション短縮名
                          , iv_name         => cv_msg_cso_00130    -- メッセージコード
                          , iv_token_name1  => cv_tkn_entry        -- トークンコード1
                          , iv_token_value1 => gt_base_code        -- トークン値1
                          );
    -- 営業員
    lv_msg_emp_number  := xxccp_common_pkg.get_msg(
                            iv_application  => cv_appl_name_xxcso  -- アプリケーション短縮名
                          , iv_name         => cv_msg_cso_00842    -- メッセージコード
                          , iv_token_name1  => cv_tkn_entry        -- トークンコード1
                          , iv_token_value1 => gt_employee_number  -- トークン値1
                          );
    -- ルートNo
    lv_msg_route_no    := xxccp_common_pkg.get_msg(
                            iv_application  => cv_appl_name_xxcso  -- アプリケーション短縮名
                          , iv_name         => cv_msg_cso_00843    -- メッセージコード
                          , iv_token_name1  => cv_tkn_entry        -- トークンコード1
                          , iv_token_value1 => gt_route_no         -- トークン値1
                          );
--
    -- ログに出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''                || CHR(10) ||
                 lv_msg_base_code  || CHR(10) ||  -- 拠点コード
                 lv_msg_emp_number || CHR(10) ||  -- 営業員
                 lv_msg_route_no   || CHR(10)     -- ルートNo
    );
--
    --==================================================
    -- 処理用の日付の取得
    --==================================================
    -- 業務日付
    gd_process_date := TRUNC( xxccp_common_pkg2.get_process_date );
--
    -- 業務日付の取得に失敗した場合はエラー
    IF( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application  => cv_appl_name_xxcso
         ,iv_name         => cv_msg_cso_00011
      );
      lv_errbuf  := lv_errmsg;
      RAISE init_err_expt;
    END IF;
--
    -- 業務日付の翌日
    gd_next_date := TRUNC( gd_process_date + 1 );
--
   -- 業務日付の翌月月末
   gd_next_month_last_date := TRUNC( LAST_DAY( ADD_MONTHS( gd_process_date, 1 ) ) );
--
  EXCEPTION
    -- *** エラー終了 ***
    WHEN init_err_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
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
   * Procedure Name   : get_route_emp_data
   * Description      : ルートNo／営業員情報取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_route_emp_data(
    ov_errbuf                       OUT    VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode                      OUT    VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg                       OUT    VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_route_emp_data'; -- プログラム名
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
    ln_emp_cnt  NUMBER;  -- 拠点営業員の件数
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
    --==================================================
    -- 対象営業員情報データ取得
    --==================================================
    BEGIN
--
      -- 拠点のみ指定(営業員の指定なし)
      IF ( gt_employee_number IS NULL ) THEN
--
        -- 一次表に対象の拠点の営業員を挿入
        INSERT INTO xxcso_tmp_rtn_rsrc (
           base_code           -- 所属拠点
          ,employee_number     -- 営業員
        )
        SELECT  /*+
                  LEADING( xrmev.jrgb )
                  INDEX( xrmev.jrgb xxcso_jtf_rs_groups_n01 )
                  USE_NL( xrmev.jrgb xrmev.jrgm xrmev.xrv2 )
                */
                gt_base_code           base_code
               ,xrmev.employee_number  employee_number
        FROM    xxcso_route_management_emp_v xrmev
        WHERE   xrmev.employee_base_code = gt_base_code
        ;
--
        -- 拠点営業員の件数
        ln_emp_cnt := SQL%ROWCOUNT;
--
      -- 営業員の指定あり
      ELSE
--
        -- 一次表に対象の拠点の営業員を挿入
        INSERT INTO xxcso_tmp_rtn_rsrc (
           base_code           -- 所属拠点
          ,employee_number     -- 営業員
        )
        SELECT  /*+
                  LEADING( xrmev.xrv2.ppf )
                  INDEX( xrmev.xrv2.ppf per_people_f_n51 )
                  USE_NL( xrmev.xrv2 xrmev.jrgm xrmev.jrgb  )
                */
                gt_base_code           base_code
               ,xrmev.employee_number  employee_number
        FROM    xxcso_route_management_emp_v xrmev
        WHERE   xrmev.employee_base_code = gt_base_code
        AND     xrmev.employee_number    = gt_employee_number
        ;
--
        -- 拠点営業員の件数
        ln_emp_cnt := SQL%ROWCOUNT;
--
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcso
                      ,iv_name         => cv_msg_cso_00649
                      ,iv_token_name1  => cv_tkn_table
                      ,iv_token_value1 => cv_msg_cso_00845
                      ,iv_token_name2  => cv_tkn_err_message
                      ,iv_token_value2 => SQLERRM
                     );
        RAISE global_api_expt; 
    END;
--
    -- 営業員が取得できた場合
    IF ( ln_emp_cnt > 0 ) THEN
--
      OPEN  route_emp_cur;
      FETCH route_emp_cur BULK COLLECT INTO gt_out_file_tab;
      CLOSE route_emp_cur;
--
      --処理件数カウント
      gn_target_cnt := gt_out_file_tab.COUNT;
--
    ELSE
--
      -- 処理件数カウント
      gn_target_cnt := 0;
--
    END IF;
--
    -- 出力対象が存在しない場合
    IF ( gn_target_cnt = 0 ) THEN
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
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END get_route_emp_data;
--
--
  /**********************************************************************************
   * Procedure Name   : output_data
   * Description      : CSVファイル出力(A-3)
   ***********************************************************************************/
  PROCEDURE output_data(
    ov_errbuf                       OUT    VARCHAR2,  --   エラー・メッセージ           --# 固定 #
    ov_retcode                      OUT    VARCHAR2,  --   リターン・コード             --# 固定 #
    ov_errmsg                       OUT    VARCHAR2)  --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_data'; -- プログラム名
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
    lv_line_data            VARCHAR2(5000);         -- OUTPUTデータ編集用
    lv_out_process_time     VARCHAR2(10);           -- 編集後の処理時刻
    lv_csv_header           VARCHAR2(5000);         -- CSVヘッダ出力用
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    TYPE g_head_ttype IS TABLE OF fnd_lookup_values.description%TYPE INDEX BY BINARY_INTEGER;
    -- *** ローカル・テーブル ***
    lt_head_tab g_head_ttype;
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
    -- CSVヘッダ出力
    --==================================================
    -- メッセージ取得
    lv_csv_header := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcso
                    ,iv_name         => cv_msg_cso_00844
                   );
--
    -- ヘッダ出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_csv_header
    );
--
    --==================================================
    -- データ出力
    --==================================================
    --データを取得
    <<data_output>>
    FOR i IN 1..gt_out_file_tab.COUNT LOOP
      --初期化
      lv_line_data := NULL;
      --データを編集
      lv_line_data :=                gt_out_file_tab(i).customer_class_name  -- 顧客区分名
                      || cv_comma || gt_out_file_tab(i).account_number       -- 顧客コード
                      || cv_comma || gt_out_file_tab(i).party_name           -- 顧客名
                      || cv_comma || gt_out_file_tab(i).trgt_resource        -- 現担当
                      || cv_comma || gt_out_file_tab(i).trgt_route_no        -- 現ルートNo
                      || cv_comma || gt_out_file_tab(i).next_resource        -- 新担当
                      || cv_comma || gt_out_file_tab(i).next_route_no        -- 新ルートNo
                      ;
      --データを出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_line_data
      );
--
      --成功件数カウント
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP data_output;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END output_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_base_code        IN  VARCHAR2,     -- 1.拠点コード
    iv_employee_number  IN  VARCHAR2,     -- 2.営業員
    iv_route_no         IN  VARCHAR2,     -- 3.ルートNo
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
       iv_base_code       => iv_base_code        -- 1.拠点コード
      ,iv_employee_number => iv_employee_number  -- 2.営業員
      ,iv_route_no        => iv_route_no         -- 3.ルートNo
      ,ov_errbuf          => lv_errbuf           --   エラー・メッセージ           --# 固定 #
      ,ov_retcode         => lv_retcode          --   リターン・コード             --# 固定 #
      ,ov_errmsg          => lv_errmsg           --   ユーザー・エラー・メッセージ --# 固定 #
    );           
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ルートNo／営業員情報取得(A-2)
    -- ===============================
    get_route_emp_data(
       ov_errbuf  => lv_errbuf  -- エラー・メッセージ           --# 固定 #
      ,ov_retcode => lv_retcode -- リターン・コード             --# 固定 #
      ,ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      --警告処理
      RAISE global_warn_expt;
    END IF;
--
    -- ===============================
    -- CSVファイル出力(A-3)
    -- ===============================
    output_data(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    --データなし警告
    WHEN global_warn_expt THEN
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := ov_errmsg;
      ov_retcode := lv_retcode;
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
    errbuf             OUT VARCHAR2,   --   エラー・メッセージ  --# 固定 #
    retcode            OUT VARCHAR2,   --   リターン・コード    --# 固定 #
    iv_base_code       IN  VARCHAR2,   -- 1.拠点コード
    iv_employee_number IN  VARCHAR2,   -- 2.営業員
    iv_route_no        IN  VARCHAR2    -- 3.ルートNo
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
    cv_appl_name_xxccp CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
--
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- コンカレントヘッダメッセージ出力先：ログ
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
       iv_which   => cv_log_header_log
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
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_base_code       => iv_base_code        -- 1.拠点コード
      ,iv_employee_number => iv_employee_number  -- 2.営業員
      ,iv_route_no        => iv_route_no         -- 3.ルートNo
      ,ov_errbuf          => lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,ov_retcode         => lv_retcode          -- リターン・コード             --# 固定 #
      ,ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- ===============================
    -- 終了処理(A-6)
    -- ===============================
    --ステータス判定
    IF (lv_retcode = cv_status_warn) THEN
      --CSVファイル出力0件エラー
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcso
                      ,iv_name         => cv_msg_cso_00224
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => gv_out_msg
      );
    ELSIF (lv_retcode = cv_status_error) THEN
      gn_target_cnt := 0;  --対象件数
      gn_normal_cnt := 0;  --成功件数
      gn_error_cnt  := 1;  --エラー件数
      --
      --エラー出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
END XXCSO019A12C;
/