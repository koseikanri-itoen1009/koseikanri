CREATE OR REPLACE PACKAGE BODY APPS.XXCOK024A41C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A41C (body)
 * Description      : 支払未連携控除データ出力
 * MD.050           : 支払未連携控除データ出力 MD050_COK_024_A41
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_order_list_cond    支払未連携控除データ抽出(A-2)
 *  output_data            データ出力(A-3)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2022/09/07    1.0   M.Akachi         新規作成
 *  2024/08/23    1.1   SCSK Y.Koh       E_本稼動_20159【収益認識】支払未連携控除出力機能のパフォーマンス向上
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- 異常:2
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg                VARCHAR2(2000)  DEFAULT NULL;
  gv_sep_msg                VARCHAR2(2000)  DEFAULT NULL;
  gv_exec_user              VARCHAR2(100)   DEFAULT NULL;
  gv_conc_name              VARCHAR2(30)    DEFAULT NULL;
  gv_conc_status            VARCHAR2(30)    DEFAULT NULL;
  gn_target_cnt             NUMBER          DEFAULT NULL;    -- 対象件数
  gn_normal_cnt             NUMBER          DEFAULT NULL;    -- 正常件数
  gn_error_cnt              NUMBER          DEFAULT NULL;    -- エラー件数
--
--################################  固定部 END   ##################################
--
--##########################  固定共通例外宣言部 START  ###########################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --*** 共通関数警告例外 ***
  global_api_warn_expt      EXCEPTION;
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
  --*** 出力日 日付逆転チェック例外 ***
  global_date_rever_old_chk_expt    EXCEPTION;
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_delimit                  CONSTANT  VARCHAR2(4)   := ',';                    -- 区切り文字
  cv_null                     CONSTANT  VARCHAR2(4)   := '';                     -- 空文字
  cv_half_space               CONSTANT  VARCHAR2(4)   := ' ';                    -- スペース
  cv_full_space               CONSTANT  VARCHAR2(4)   := '　';                   -- 全角スペース
  cv_const_y                  CONSTANT  VARCHAR2(1)   := 'Y';                    -- 'Y'
  cv_const_n                  CONSTANT  VARCHAR2(1)   := 'N';                    -- 'N'
  cv_perc                     CONSTANT  VARCHAR2(1)   := '%';                    -- '%'
  cv_lang                     CONSTANT  VARCHAR2(100) := USERENV( 'LANG' );      -- 言語
  -- 数値
  cn_zero                     CONSTANT  NUMBER        := 0;                      -- 0
  cn_one                      CONSTANT  NUMBER        := 1;                      -- 1
  --
  cv_pkg_name                 CONSTANT  VARCHAR2(100) := 'XXCOK024A41C';         -- パッケージ名
  cv_xxcok_short_name         CONSTANT  VARCHAR2(100) := 'XXCOK';                -- 販物領域短縮アプリ名
  -- 書式マスク
  cv_date_format              CONSTANT  VARCHAR2(10)  := 'YYYY/MM/DD';              -- 日付書式
  cv_date_format_time         CONSTANT  VARCHAR2(30)  := 'YYYY/MM/DD HH24:MI:SS';   -- 日付書式(日時)
  -- 参照タイプ
  cv_type_department          CONSTANT  VARCHAR2(30)  := 'XX03_DEPARTMENT';               -- 拠点コード
  cv_type_business_type       CONSTANT  VARCHAR2(30)  := 'XX03_BUSINESS_TYPE';            -- 企業コード
  cv_type_chain_code          CONSTANT  VARCHAR2(30)  := 'XXCMM_CHAIN_CODE';              -- 控除用チェーンコード
  cv_type_header              CONSTANT  VARCHAR2(30)  := 'XXCOK1_NOTLINK_DEDUCTION_HEAD'; -- 支払未連携控除データ出力用見出し
  cv_type_dec_pri_base        CONSTANT  VARCHAR2(30)  := 'XXCOK1_DEC_PRIVILEGE_BASE';     -- 控除マスタ特権拠点
  cv_type_deduction_data      CONSTANT  VARCHAR2(30)  := 'XXCOK1_DEDUCTION_DATA_TYPE';    -- 控除データ種類
  --メッセージ
  cv_msg_date_rever_err       CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-10651';     -- 日付逆転エラー
  cv_msg_parameter            CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-10848';     -- パラメータ出力メッセージ
  cv_msg_base_params_err      CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-10849';     -- パラメータ複数設定エラー（本部担当拠点、売上拠点）
  cv_msg_proc_date_err        CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-00028';     -- 業務日付取得エラーメッセージ
  cv_msg_user_id_err          CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-10594';     -- ユーザーID取得エラーメッセージ
  cv_msg_user_base_code_err   CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-00012';     -- 所属拠点コード取得エラーメッセージ
  cv_msg_no_data_err          CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-00001';     -- 対象データなしエラーメッセージ
  cv_msg_profile_err          CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-00003';     -- プロファイル取得エラーメッセージ
  --トークン名
  cv_tkn_nm_date_type         CONSTANT  VARCHAR2(100) := 'DATE_TYPE';            -- データ種類
  cv_tkn_nm_rec_date_from     CONSTANT  VARCHAR2(100) := 'RECORD_DATE_FROM';     -- 計上日（FROM）
  cv_tkn_nm_rec_date_to       CONSTANT  VARCHAR2(100) := 'RECORD_DATE_TO';       -- 計上日（TO）
  cv_tkn_nm_base_code         CONSTANT  VARCHAR2(100) := 'BASE_CODE';            -- 本部担当拠点
  cv_tkn_nm_sale_base_code    CONSTANT  VARCHAR2(100) := 'SALE_BASE_CODE';       -- 売上拠点
  cv_tkn_nm_user_id           CONSTANT  VARCHAR2(100) := 'USER_ID';              -- ユーザーID
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_proc_date              DATE           DEFAULT NULL;                     -- 業務日付
  gn_user_id                NUMBER         DEFAULT NULL;                     -- ユーザーID
  gv_user_base_code         VARCHAR2(150)  DEFAULT NULL;                     -- 所属拠点コード
  gn_privilege_base         NUMBER         DEFAULT NULL;                     -- 登録・更新特権（0：特権なし、1：特権あり）
  gv_privilege_flag         VARCHAR2(1)    DEFAULT NULL;                     -- 特権ユーザー判断フラグ
--
  -- ===============================
  -- ユーザー定義グローバル・カーソル
  -- ===============================
  CURSOR get_deduction_list_data_cur (
           iv_data_type                  VARCHAR2              -- データ種類
          ,iv_record_date_from           VARCHAR2              -- 計上日(FROM)
          ,iv_record_date_to             VARCHAR2              -- 計上日(TO)
          ,iv_base_code                  VARCHAR2              -- 本部担当拠点
          ,iv_sale_base_code             VARCHAR2              -- 売上拠点
          )
  IS
-- 2024/08/23 Ver1.1 MOD Start
    SELECT  /*+ LEADING ( xch xsd ) */
            xsd.base_code_to          AS  base_code_to        , -- 拠点コード
--    SELECT  xsd.base_code_to          AS  base_code_to        , -- 拠点コード
-- 2024/08/23 Ver1.1 MOD End
            ffvt.description          AS  base_code_name      , -- 拠点名
            papf.employee_number      AS  employee_number     , -- ヘッダ最終更新者従業員番号
            papf.per_information18    AS  employee_first_name , -- ヘッダ最終更新者姓
            papf.per_information19    AS  employee_last_name  , -- ヘッダ最終更新者名
            xch.corp_code             AS  corp_code           , -- 企業コード
            ffvv.attribute2           AS  base_code_corp      , -- 本部担当拠点（企業）
            xch.deduction_chain_code  AS  deduction_chain_code, -- 控除用チェーンコード
            flv.attribute3            AS  base_code_chain     , -- 本部担当拠点（チェーン）
            xch.customer_code         AS  customer_code       , -- 顧客コード
            xca.sale_base_code        AS  sale_base_code      , -- 売上拠点
            xch.data_type             AS  data_type           , -- データ種類
            xch.condition_no          AS  condition_no        , -- 控除番号
            xch.content               AS  content             , -- 内容
            xch.decision_no           AS  decision_no         , -- 決済No.
            xch.start_date_active     AS  start_date_active   , -- 開始日
            xch.end_date_active       AS  end_date_active     , -- 終了日
            xch.last_update_date      AS  last_update_date    , -- 最終更新日
            sum(xsd.sale_pure_amount) AS  sale_pure_amount    , -- 売上本体金額
            sum(xsd.deduction_amount) AS  deduction_amount      -- 控除額
    FROM    xxcok_condition_header    xch,                      -- 控除条件
            xxcok_sales_deduction     xsd ,                     -- 販売控除情報
            fnd_flex_values_tl        ffvt,                     -- 値日本語(拠点)
            fnd_flex_values           ffv ,                     -- 値(拠点)
            fnd_flex_value_sets       ffvs,                     -- 値セット(拠点)
            per_all_people_f          papf,                     -- 従業員マスタ
            fnd_user                  fu  ,                     -- ユーザーマスタ
            fnd_flex_values_vl        ffvv,                     -- 企業
            fnd_lookup_values         flv,                      -- チェーンコード
            xxcmm_cust_accounts       xca,                      -- 顧客
            xxcmm_cust_accounts       xca2                      -- 顧客
    WHERE   xsd.recon_slip_num          IS      NULL
    AND     xsd.data_type               IN      ( SELECT REGEXP_SUBSTR(iv_data_type, '[^,]+', 1, LEVEL) FROM DUAL
                                                  CONNECT BY REGEXP_SUBSTR(iv_data_type, '[^,]+', 1, LEVEL) IS NOT NULL )    -- データ種類
    AND     xsd.record_date             BETWEEN to_date(iv_record_date_from,cv_date_format)
                                        AND     to_date(iv_record_date_to,cv_date_format)
    AND     xsd.status                  =       cv_const_n
    AND     xch.condition_no            =       xsd.condition_no
    AND     ffvs.flex_value_set_name    =       cv_type_department
    AND     ffv.flex_value_set_id       =       ffvs.flex_value_set_id
    AND     ffv.flex_value              =       xsd.base_code_to
    AND     ffvt.flex_value_id          =       ffv.flex_value_id
    AND     ffvt.language               =       cv_lang
    -- 企業
    AND     ffvv.value_category(+)      =       cv_type_business_type
    AND     ffvv.flex_value(+)          =       xch.corp_code
    -- チェーン
    AND     flv.lookup_type(+)          =       cv_type_chain_code
    AND     flv.lookup_code(+)          =       xch.deduction_chain_code
    AND     flv.language(+)             =       cv_lang
    -- 顧客
    AND     xca.customer_code(+)        =       xch.customer_code
    -- 振替先顧客
    AND     xsd.customer_code_to        =       xca2.customer_code           -- 販売控除情報.振替先顧客コード = 顧客マスタ.顧客コード
    -- ユーザ
    AND     fu.user_id                  =       xch.created_by
    AND     papf.person_id              =       fu.employee_id
    AND     papf.current_employee_flag  =       cv_const_y
    AND     papf.effective_start_date   =       ( SELECT MAX(papf2.effective_start_date) effective_start_date
                                                  FROM   per_all_people_f papf2
                                                  WHERE  papf2.current_employee_flag  = cv_const_y
                                                  AND    papf2.person_id              = papf.person_id )
    AND (
         -- <本部担当拠点の抽出条件>
         (( ffvv.attribute2 = iv_base_code OR flv.attribute3 = iv_base_code OR xca.sale_base_code = iv_base_code OR iv_base_code IS NULL )
          AND  ( gv_privilege_flag = cv_const_y OR ffvv.attribute2 = gv_user_base_code OR flv.attribute3 = gv_user_base_code OR xca.sale_base_code = gv_user_base_code )
          AND  ( iv_sale_base_code IS NULL )
         )
         OR 
         -- <売上拠点の抽出条件>  
         (( xca2.sale_base_code = iv_sale_base_code OR iv_sale_base_code IS NULL )
          AND  ( gv_privilege_flag =  cv_const_y OR xca2.sale_base_code = gv_user_base_code )
          AND  ( iv_base_code IS NULL )
         )
        )
-- 2024/08/23 Ver1.1 ADD Start
    AND     xch.data_type               IN      ( SELECT REGEXP_SUBSTR(iv_data_type, '[^,]+', 1, LEVEL) FROM DUAL
                                                  CONNECT BY REGEXP_SUBSTR(iv_data_type, '[^,]+', 1, LEVEL) IS NOT NULL )    -- データ種類
    AND     xch.START_DATE_ACTIVE       <=      to_date(iv_record_date_to,cv_date_format)
    AND     xch.END_DATE_ACTIVE         >=      to_date(iv_record_date_from,cv_date_format)
-- 2024/08/23 Ver1.1 ADD End
    GROUP BY
            ffv.attribute9            , -- 拠点本部コード
            xsd.base_code_to          , -- 拠点コード
            ffvt.description          , -- 拠点名
            papf.employee_number      , -- ヘッダ最終更新者従業員番号
            papf.per_information18    , -- ヘッダ最終更新者姓
            papf.per_information19    , -- ヘッダ最終更新者名
            xch.corp_code             , -- 企業コード
            ffvv.attribute2           , -- 本部担当拠点（企業）
            xch.deduction_chain_code  , -- 控除用チェーンコード
            flv.attribute3            , -- 本部担当拠点（チェーン）
            xch.customer_code         , -- 顧客コード
            xca.sale_base_code        , -- 売上拠点
            xch.data_type             , -- データ種類
            xch.condition_no          , -- 控除番号
            xch.content               , -- 内容
            xch.decision_no           , -- 決済No.
            xch.start_date_active     , -- 開始日
            xch.end_date_active       , -- 終了日
            xch.last_update_date        -- 最終更新日
    ORDER BY
            ffv.attribute9            , -- 拠点コード
            xch.corp_code             , -- 企業コード
            xch.deduction_chain_code  , -- 控除用チェーンコード
            xch.customer_code         , -- 顧客コード
            xch.condition_no            -- 控除番号
    ;
--
  -- 取得データ格納変数定義 (全出力)
  TYPE g_out_file_ttype IS TABLE OF get_deduction_list_data_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  gt_out_file_tab       g_out_file_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_data_type                    IN     VARCHAR2     -- データ種類
   ,iv_record_date_from             IN     VARCHAR2     -- 計上日(FROM)
   ,iv_record_date_to               IN     VARCHAR2     -- 計上日(TO)
   ,iv_base_code                    IN     VARCHAR2     -- 本部担当拠点
   ,iv_sale_base_code               IN     VARCHAR2     -- 売上拠点
   ,ov_errbuf                       OUT    VARCHAR2     -- エラー・メッセージ           --# 固定 #
   ,ov_retcode                      OUT    VARCHAR2     -- リターン・コード             --# 固定 #
   ,ov_errmsg                       OUT    VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000)  DEFAULT NULL;  -- エラー・メッセージ
    lv_retcode VARCHAR2(1)     DEFAULT NULL;  -- リターン・コード
    lv_errmsg  VARCHAR2(5000)  DEFAULT NULL;  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_para_msg                     VARCHAR2(5000)  DEFAULT NULL;     -- パラメータ出力メッセージ
    lv_para_msg2                    VARCHAR2(5000)  DEFAULT NULL;     -- パラメータ出力メッセージ
    ln_option_param_count           NUMBER := cn_zero;        -- 任意パラメータ設定数
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode        := cv_status_normal;
    gv_privilege_flag := NULL;
    gn_privilege_base := cn_zero;
--
--###########################  固定部 END   ############################
--
    --========================================
    -- 1.パラメータ出力処理
    --========================================
    lv_para_msg   :=  xxccp_common_pkg.get_msg( iv_application        =>  cv_xxcok_short_name           -- アプリ短縮名
                                               ,iv_name               =>  cv_msg_parameter              -- パラメータ出力メッセージ
                                               ,iv_token_name1        =>  cv_tkn_nm_date_type           -- トークン：データ種類
                                               ,iv_token_value1       =>  iv_data_type                  -- データ種類
                                               ,iv_token_name2        =>  cv_tkn_nm_rec_date_from       -- トークン：計上日（FROM）
                                               ,iv_token_value2       =>  iv_record_date_from           -- 計上日（FROM）
                                               ,iv_token_name3        =>  cv_tkn_nm_rec_date_to         -- トークン：計上日（TO）
                                               ,iv_token_value3       =>  iv_record_date_to             -- 計上日（TO）
                                               ,iv_token_name4        =>  cv_tkn_nm_base_code           -- トークン：本部担当拠点
                                               ,iv_token_value4       =>  iv_base_code                  -- 本部担当拠点
                                               ,iv_token_name5        =>  cv_tkn_nm_sale_base_code      -- トークン：売上拠点
                                               ,iv_token_value5       =>  iv_sale_base_code             -- 売上拠点
                                               );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_para_msg
    );
--
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --========================================
    -- 2.入力パラメータチェック
    --========================================
    -- 計上日(FROM)が計上日(TO)より未来日の場合エラー
    IF ( iv_record_date_from > iv_record_date_to ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcok_short_name,
        iv_name               =>  cv_msg_date_rever_err
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 本部担当拠点、売上拠点の両方が入力されている場合エラー
    IF ( iv_base_code IS NOT NULL AND iv_sale_base_code IS NOT NULL ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcok_short_name,
        iv_name               =>  cv_msg_base_params_err
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 3.業務日付取得処理
    --========================================
    gd_proc_date := TRUNC( xxccp_common_pkg2.get_process_date );
    IF ( gd_proc_date IS NULL ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcok_short_name,
        iv_name               =>  cv_msg_proc_date_err
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 4.ユーザーID取得処理
    --========================================
    gn_user_id := fnd_global.user_id;
    IF ( gn_user_id IS NULL ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcok_short_name,
        iv_name               =>  cv_msg_user_id_err
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 5.所属拠点コード取得処理
    --========================================
    gv_user_base_code := xxcok_common_pkg.get_base_code_f(
      id_proc_date            =>  gd_proc_date,
      in_user_id              =>  gn_user_id
      );
    IF ( gv_user_base_code IS NULL ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcok_short_name,
        iv_name               =>  cv_msg_user_base_code_err,
        iv_token_name1        =>  cv_tkn_nm_user_id,
        iv_token_value1       =>  gn_user_id
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 6.特権ユーザー確認処理
    --========================================
    -- 6-1 特権拠点の所属ユーザーか確認
    BEGIN
      SELECT  COUNT(1)            AS privilege_base_cnt
      INTO    gn_privilege_base
      FROM    fnd_lookup_values flv
      WHERE   flv.lookup_type      = cv_type_dec_pri_base
      AND     flv.lookup_code      = gv_user_base_code
      AND     flv.enabled_flag     = cv_const_y
      AND     flv.language         = cv_lang
      AND     gd_proc_date BETWEEN flv.start_date_active 
                               AND NVL(flv.end_date_active,gd_proc_date)
      ;
    END;
--
    -- 6-1 特権拠点ユーザーの判別
    IF (gn_privilege_base >= cn_one) THEN
      gv_privilege_flag  := cv_const_y;
    END IF;
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_order_list_cond
   * Description      : 支払未連携控除データ抽出(A-2)
   ***********************************************************************************/
  PROCEDURE get_order_list_cond(
    iv_data_type                    IN     VARCHAR2     -- データ種類
   ,iv_record_date_from             IN     VARCHAR2     -- 計上日(FROM)
   ,iv_record_date_to               IN     VARCHAR2     -- 計上日(TO)
   ,iv_base_code                    IN     VARCHAR2     -- 本部担当拠点
   ,iv_sale_base_code               IN     VARCHAR2     -- 売上拠点
   ,ov_errbuf                       OUT    VARCHAR2     -- エラー・メッセージ           --# 固定 #
   ,ov_retcode                      OUT    VARCHAR2     -- リターン・コード             --# 固定 #
   ,ov_errmsg                       OUT    VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_order_list_cond'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000)  DEFAULT NULL;  -- エラー・メッセージ
    lv_retcode VARCHAR2(1)     DEFAULT NULL;  -- リターン・コード
    lv_errmsg  VARCHAR2(5000)  DEFAULT NULL;  -- ユーザー・エラー・メッセージ
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
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode    := cv_status_normal;
    gn_target_cnt := cn_zero;
--
--###########################  固定部 END   ############################
--
    -- 対象データ取得
    OPEN get_deduction_list_data_cur (
           iv_data_type                  -- データ種類
          ,iv_record_date_from           -- 計上日(FROM)
          ,iv_record_date_to             -- 計上日(TO)
          ,iv_base_code                  -- 本部担当拠点
          ,iv_sale_base_code             -- 売上拠点
          );
    FETCH get_deduction_list_data_cur BULK COLLECT INTO gt_out_file_tab;
    CLOSE get_deduction_list_data_cur;
    -- 処理件数カウント
    gn_target_cnt := gt_out_file_tab.COUNT;
--
    -- 抽出データが0件だった場合警告
    IF  gn_target_cnt = cn_zero THEN
      RAISE global_api_warn_expt;
    END IF;
--
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 警告ハンドラ ***
    WHEN global_api_warn_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF get_deduction_list_data_cur%ISOPEN THEN
        CLOSE get_deduction_list_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_order_list_cond;
--
  /**********************************************************************************
   * Procedure Name   : output_data
   * Description      : データ出力(A-3)
   ***********************************************************************************/
  PROCEDURE output_data(
    ov_errbuf                       OUT    VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode                      OUT    VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg                       OUT    VARCHAR2   -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf     VARCHAR2(5000)  DEFAULT NULL;  -- エラー・メッセージ
    lv_retcode    VARCHAR2(1)     DEFAULT NULL;  -- リターン・コード
    lv_errmsg     VARCHAR2(5000)  DEFAULT NULL;  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_code_eoh_024a41    CONSTANT  VARCHAR2(100) := '024A41%';                 -- クイックコード（控除マスタ出力用見出し）
--
    -- *** ローカル変数 ***
    lv_line_data              VARCHAR2(5000)  DEFAULT NULL;                     -- OUTPUTデータ編集用
--
    -- *** ローカル・カーソル ***
    --見出し取得用カーソル
    CURSOR header_cur
    IS
      SELECT  flv.description  head                                             -- 摘要：出力用見出し
      FROM    fnd_lookup_values flv
      WHERE   flv.language        = cv_lang                                     -- 言語
      AND     flv.lookup_type     = cv_type_header                              -- 支払未連携控除データ出力用見出し
      AND     flv.lookup_code  LIKE cv_code_eoh_024a41                          -- クイックコード（支払未連携控除データ出力用見出し）
      AND     gd_proc_date       >= NVL( flv.start_date_active, gd_proc_date )  -- 有効開始日
      AND     gd_proc_date       <= NVL( flv.end_date_active,   gd_proc_date )  -- 有効終了日
      AND     flv.enabled_flag    = cv_const_y                                  -- 使用可能
      ORDER BY
              TO_NUMBER(flv.attribute1)
      ;
    --見出し
    TYPE l_header_ttype IS TABLE OF fnd_lookup_values.description%TYPE INDEX BY BINARY_INTEGER;
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル・テーブル ***
    lt_header_tab l_header_ttype;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    ------------------------------------------
    -- 見出しの出力
    ------------------------------------------
    -- データの見出しを取得
    OPEN  header_cur;
    FETCH header_cur BULK COLLECT INTO lt_header_tab;
    CLOSE header_cur;
--
    --データの見出しを編集
    <<data_head_output>>
    FOR i IN 1..lt_header_tab.COUNT LOOP
      IF ( i = 1 ) THEN
        lv_line_data := lt_header_tab(i);
      ELSE
        lv_line_data := lv_line_data || cv_delimit || lt_header_tab(i);
      END IF;
    END LOOP data_head_output;
--
    --データの見出しを出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_line_data
    );
    ------------------------------------------
    -- データ出力
    ------------------------------------------
    <<data_output>>
    FOR i IN 1..gt_out_file_tab.COUNT LOOP
--
      --データを編集
      lv_line_data :=     gt_out_file_tab(i).base_code_to          -- 拠点コード
         || cv_delimit || gt_out_file_tab(i).base_code_name        -- 拠点名
         || cv_delimit || gt_out_file_tab(i).employee_number       -- 社員コード
         || cv_delimit || gt_out_file_tab(i).employee_first_name || cv_half_space || gt_out_file_tab(i).employee_last_name  -- 作成者名
         || cv_delimit || gt_out_file_tab(i).corp_code             -- 企業コード 
         || cv_delimit || gt_out_file_tab(i).base_code_corp        -- 本部担当拠点（企業）
         || cv_delimit || gt_out_file_tab(i).deduction_chain_code  -- 控除用チェーンコード
         || cv_delimit || gt_out_file_tab(i).base_code_chain       -- 本部担当拠点（チェーン）
         || cv_delimit || gt_out_file_tab(i).customer_code         -- 顧客コード
         || cv_delimit || gt_out_file_tab(i).sale_base_code        -- 売上拠点
         || cv_delimit || gt_out_file_tab(i).data_type             -- データ種類
         || cv_delimit || gt_out_file_tab(i).condition_no          -- 控除番号
         || cv_delimit || gt_out_file_tab(i).content               -- 内容
         || cv_delimit || gt_out_file_tab(i).decision_no           -- 決済No.
         || cv_delimit || TO_CHAR(gt_out_file_tab(i).start_date_active,cv_date_format)  -- 開始日(YYYY/MM/DD)
         || cv_delimit || TO_CHAR(gt_out_file_tab(i).end_date_active,cv_date_format)    -- 終了日(YYYY/MM/DD)
         || cv_delimit || TO_CHAR(gt_out_file_tab(i).last_update_date,cv_date_format_time)   -- 最終更新日(YYYY/MM/DD HH24:MI:SS)
         || cv_delimit || gt_out_file_tab(i).sale_pure_amount      -- 売上本体金額
         || cv_delimit || gt_out_file_tab(i).deduction_amount      -- 控除額
      ;
      -- データを出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_line_data
      );
      -- 成功件数カウント
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP data_output;
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
      IF header_cur%ISOPEN THEN
        CLOSE header_cur;
      END IF;
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
  PROCEDURE submain( iv_data_type                    IN     VARCHAR2  -- データ種類
                    ,iv_record_date_from             IN     VARCHAR2  -- 計上日(FROM)
                    ,iv_record_date_to               IN     VARCHAR2  -- 計上日(TO)
                    ,iv_base_code                    IN     VARCHAR2  -- 本部担当拠点
                    ,iv_sale_base_code               IN     VARCHAR2  -- 売上拠点
                    ,ov_errbuf                       OUT    VARCHAR2  -- エラー・メッセージ           --# 固定 #
                    ,ov_retcode                      OUT    VARCHAR2  -- リターン・コード             --# 固定 #
                    ,ov_errmsg                       OUT    VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
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
    lv_errbuf  VARCHAR2(5000)  DEFAULT NULL;  -- エラー・メッセージ
    lv_retcode VARCHAR2(1)     DEFAULT NULL;  -- リターン・コード
    lv_errmsg  VARCHAR2(5000)  DEFAULT NULL;  -- ユーザー・エラー・メッセージ
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
--
    -- ===============================
    -- A-1  初期処理
    -- ===============================
    init( iv_data_type                   -- データ種類
         ,iv_record_date_from            -- 計上日(FROM)
         ,iv_record_date_to              -- 計上日(TO)
         ,iv_base_code                   -- 本部担当拠点
         ,iv_sale_base_code              -- 売上拠点
         ,lv_errbuf                      -- エラー・メッセージ           --# 固定 #
         ,lv_retcode                     -- リターン・コード             --# 固定 #
         ,lv_errmsg                      -- ユーザー・エラー・メッセージ --# 固定 #
         );
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2  支払未連携控除データ抽出
    -- ===============================
    get_order_list_cond( iv_data_type                 -- データ種類
                        ,iv_record_date_from          -- 計上日(FROM)
                        ,iv_record_date_to            -- 計上日(TO)
                        ,iv_base_code                 -- 本部担当拠点
                        ,iv_sale_base_code            -- 売上拠点
                        ,lv_errbuf                    -- エラー・メッセージ           --# 固定 #
                        ,lv_retcode                   -- リターン・コード             --# 固定 #
                        ,lv_errmsg                    -- ユーザー・エラー・メッセージ --# 固定 #
                        );
--
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( iv_application        =>  cv_xxcok_short_name,
                                             iv_name               =>  cv_msg_no_data_err
                                            );
      RAISE global_api_warn_expt;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    ELSE
      NULL;
    END IF;
--
    -- ===============================
    -- A-3  データ出力
    -- ===============================
    output_data(
      lv_errbuf,                    -- エラー・メッセージ           --# 固定 #
      lv_retcode,                   -- リターン・コード             --# 固定 #
      lv_errmsg                     -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
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
    -- *** 警告ハンドラ ***
    WHEN global_api_warn_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
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
    errbuf                          OUT    VARCHAR2          -- エラーメッセージ #固定#
   ,retcode                         OUT    VARCHAR2          -- エラーコード     #固定#
   ,iv_data_type                    IN     VARCHAR2          -- データ種類
   ,iv_record_date_from             IN     VARCHAR2          -- 計上日(FROM)
   ,iv_record_date_to               IN     VARCHAR2          -- 計上日(TO)
   ,iv_base_code                    IN     VARCHAR2          -- 本部担当拠点
   ,iv_sale_base_code               IN     VARCHAR2          -- 売上拠点
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
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- コンカレントヘッダメッセージ出力先：出力
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- コンカレントヘッダメッセージ出力先：ログ
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000)  DEFAULT NULL;  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1)     DEFAULT NULL;  -- リターン・コード
    lv_errmsg          VARCHAR2(5000)  DEFAULT NULL;  -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100)   DEFAULT NULL;  -- 終了メッセージコード
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
       iv_data_type                    -- データ種類
      ,iv_record_date_from             -- 計上日(FROM)
      ,iv_record_date_to               -- 計上日(TO)
      ,iv_base_code                    -- 本部担当拠点
      ,iv_sale_base_code               -- 売上拠点
      ,lv_errbuf                       -- エラー・メッセージ           --# 固定 #
      ,lv_retcode                      -- リターン・コード             --# 固定 #
      ,lv_errmsg                       -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- ===============================
    -- A-4.終了処理
    -- ===============================
--
    --エラー出力
    IF ( lv_retcode <> cv_status_normal ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
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
    --
    --エラーの場合成功件数クリア、エラー件数固定
    IF ( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := cn_zero;
      gn_error_cnt  := cn_one;
    END IF;
    --
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_target_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    --終了メッセージ
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
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
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
END XXCOK024A41C;
/
