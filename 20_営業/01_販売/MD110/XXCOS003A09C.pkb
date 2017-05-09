CREATE OR REPLACE PACKAGE BODY APPS.XXCOS003A09C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * Package Name     : XXCOS003A09C (body)
 * Description      : 特売価格表データダウンロード
 * MD.050           : 特売価格表データダウンロード <MD050_COS_003_A09>
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  check_parameter        パラメータチェック(A-2)
 *  get_price_list_data    特売価格表データ取得(A-3)
 *  output_data            データ出力(A-4)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                         終了処理(A-5)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2016/04/06    1.0   S.Niki           新規作成[E_本稼働_14024対応]
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
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;                 --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                            --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                 --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                            --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;         --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;            --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;         --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                            --PROGRAM_UPDATE_DATE
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
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
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  --*** 書式チェック例外 ***
  global_format_chk_expt            EXCEPTION;
  --*** 日付逆転チェック例外 ***
  global_date_rever_chk_expt        EXCEPTION;
  --*** 対象0件例外 ***
  global_no_data_expt               EXCEPTION;
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                    CONSTANT  VARCHAR2(100) := 'XXCOS003A09C';        -- パッケージ名
  cv_xxcos_short_name            CONSTANT  VARCHAR2(100) := 'XXCOS';               -- 販物領域短縮アプリ名
  cv_xxccp_short_name            CONSTANT  VARCHAR2(100) := 'XXCCP';               -- 共通領域短縮アプリ名
  -- メッセージ
  cv_msg_format_check_err        CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00002';    -- 日付書式チェックエラーメッセージ
  cv_msg_no_data                 CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00003';    -- 対象データなしメッセージ
  cv_msg_prof_err                CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00004';    -- プロファイル取得エラーメッセージ
  cv_msg_date_rever_err          CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00005';    -- 日付逆転エラーメッセージ
  cv_msg_proc_date_err           CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00014';    -- 業務日付取得エラーメッセージ
  cv_msg_inv_org_id_err          CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00091';    -- 在庫組織ID取得エラーメッセージ
  cv_msg_parameter               CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-15201';    -- パラメータ出力メッセージ
  cv_msg_date_from               CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-15202';    -- 期間(FROM)
  cv_msg_date_to                 CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-15203';    -- 期間(TO)
  -- トークン名
  cv_tkn_para_date               CONSTANT  VARCHAR2(100) := 'PARA_DATE';           -- 日付
  cv_tkn_base_code               CONSTANT  VARCHAR2(100) := 'BASE_CODE';           -- 拠点コード
  cv_tkn_customer_code           CONSTANT  VARCHAR2(100) := 'CUSTOMER_CODE';       -- 顧客コード
  cv_tkn_item_code               CONSTANT  VARCHAR2(100) := 'ITEM_CODE';           -- 品目コード
  cv_tkn_date_from               CONSTANT  VARCHAR2(100) := 'DATE_FROM';           -- 期間(FROM)
  cv_tkn_date_to                 CONSTANT  VARCHAR2(100) := 'DATE_TO';             -- 期間(TO)
  cv_tkn_profile                 CONSTANT  VARCHAR2(100) := 'PROFILE';             -- プロファイル名
  cv_tkn_org_code_tok            CONSTANT  VARCHAR2(100) := 'ORG_CODE_TOK';        -- 在庫組織コード
  -- 日付フォーマット
  cv_fmt_std                     CONSTANT  VARCHAR2(10)  := 'YYYY/MM/DD';          -- 書式：YYYY/MM/DD
  cv_flag_y                      CONSTANT  VARCHAR2(1)   := 'Y';                   -- フラグ：Y
  cv_flag_n                      CONSTANT  VARCHAR2(1)   := 'N';                   -- フラグ：N
  ct_lang                        CONSTANT  fnd_lookup_values.language%TYPE
                                                         := USERENV( 'LANG' );     -- 言語
  cv_qck_typ_head                CONSTANT  VARCHAR2(30)  := 'XXCOS1_EXCEL_OUTPUT_HEAD';    -- エクセル出力用見出し
  cv_qck_typ_003a09              CONSTANT  VARCHAR2(30)  := '003A09%';                     -- エクセル出力用見出しキー
  -- プロファイル
  cv_prof_inv_org_code           CONSTANT  VARCHAR2(30)  := 'XXCOI1_ORGANIZATION_CODE';    -- プロファイル名(在庫組織コード)
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 見出し
  TYPE g_head_ttype IS TABLE OF fnd_lookup_values.description%TYPE INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_process_date           DATE;                                        -- 業務日付
  gt_inv_org_id             mtl_parameters.organization_id%TYPE;         -- 在庫組織ID
--
  -- ===============================
  -- ユーザー定義グローバル・カーソル
  -- ===============================
  -- 特売価格表データ取得
  CURSOR get_price_list_cur(
           icp_base_code           VARCHAR2   -- 拠点コード
          ,icp_customer_code       VARCHAR2   -- 顧客コード
          ,icp_item_code           VARCHAR2   -- 品目コード
          ,icp_date_from           DATE       -- 期間(FROM)
          ,icp_date_to             DATE       -- 期間(TO)
         )
  IS
    SELECT
       NULL                            AS proc_kbn             -- 処理区分
      ,hca.account_number              AS customer_code        -- 顧客コード
      ,hp.party_name                   AS customer_name        -- 顧客名称
      ,msib.segment1                   AS item_code            -- 品目コード
      ,msib.description                AS item_name            -- 品目名称
      ,xspl.price                      AS price                -- 価格
      ,xspl.start_date_active          AS start_date_active    -- 有効開始日
      ,xspl.end_date_active            AS end_date_active      -- 有効終了日
    FROM
       xxcos_sale_price_lists  xspl    -- 特売価格表
      ,hz_cust_accounts        hca     -- 顧客マスタ
      ,hz_parties              hp      -- パーティマスタ
      ,xxcmm_cust_accounts     xca     -- 顧客追加情報
      ,mtl_system_items_b      msib    -- DISC品目マスタ
    WHERE
        hca.cust_account_id      = xspl.customer_id
    AND hca.party_id             = hp.party_id
    AND hca.cust_account_id      = xca.customer_id
    AND xspl.item_id             = msib.inventory_item_id(+)
    AND msib.organization_id(+)  = gt_inv_org_id
    -- パラメータ.拠点コード
    AND (  ( icp_base_code  IS NULL )
         OR
           -- パラメータ.拠点コード = 売上拠点コード
           ( icp_base_code  = xca.sale_base_code )
         OR
           -- パラメータ.拠点コード = 納品拠点コード
           ( icp_base_code  = xca.delivery_base_code )
         OR
           -- パラメータ.拠点コード = 販売先本部担当拠点
           ( icp_base_code  = xca.sales_head_base_code )
        )
    -- パラメータ.顧客コード
    AND (  ( icp_customer_code  IS NULL )
         OR
           ( hca.account_number = icp_customer_code )
        )
    -- パラメータ.品目コード
    AND (  ( icp_item_code      IS NULL )
         OR
           ( msib.segment1      = icp_item_code )
        )
    -- パラメータ.期間(FROM)(TO)
    AND (  (     ( icp_date_from  IS NULL )
             AND ( icp_date_to    IS NULL )
           )
         OR
           (     ( icp_date_from  <= NVL( xspl.end_date_active   ,icp_date_from ) )
             AND ( icp_date_to    >= NVL( xspl.start_date_active ,icp_date_to   ) )
           )
        )
    ORDER BY
        hca.account_number          -- 顧客コード
       ,msib.segment1               -- 品目コード
       ,xspl.start_date_active      -- 有効開始日
    ;
--
  -- 取得データ格納変数定義
  TYPE g_out_file_ttype IS TABLE OF get_price_list_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  gt_out_file_tab       g_out_file_ttype;
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_base_code           IN   VARCHAR2  -- 拠点コード
   ,iv_customer_code       IN   VARCHAR2  -- 顧客コード
   ,iv_item_code           IN   VARCHAR2  -- 品目コード
   ,iv_date_from           IN   VARCHAR2  -- 期間(FROM)
   ,iv_date_to             IN   VARCHAR2  -- 期間(TO)
   ,ov_errbuf              OUT  VARCHAR2  -- エラー・メッセージ           --# 固定 #
   ,ov_retcode             OUT  VARCHAR2  -- リターン・コード             --# 固定 #
   ,ov_errmsg              OUT  VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'init';  -- プログラム名
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
    lv_para_msg            VARCHAR2(5000);                         -- パラメータ出力メッセージ
    lt_inv_org_code        mtl_parameters.organization_code%TYPE;  -- 在庫組織コード
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
    --========================================
    -- パラメータ出力処理
    --========================================
    -- パラメータ出力メッセージ取得
    lv_para_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name        -- アプリケーション短縮名
                    ,iv_name         => cv_msg_parameter           -- メッセージコード
                    ,iv_token_name1  => cv_tkn_base_code           -- トークンコード1
                    ,iv_token_value1 => iv_base_code               -- トークン値1
                    ,iv_token_name2  => cv_tkn_customer_code       -- トークンコード2
                    ,iv_token_value2 => iv_customer_code           -- トークン値2
                    ,iv_token_name3  => cv_tkn_item_code           -- トークンコード3
                    ,iv_token_value3 => iv_item_code               -- トークン値3
                    ,iv_token_name4  => cv_tkn_date_from           -- トークンコード4
                    ,iv_token_value4 => iv_date_from               -- トークン値4
                    ,iv_token_name5  => cv_tkn_date_to             -- トークンコード5
                    ,iv_token_value5 => iv_date_to                 -- トークン値5
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_para_msg
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --========================================
    -- 業務日付取得
    --========================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name    -- アプリケーション短縮名
                    ,iv_name         => cv_msg_proc_date_err   -- メッセージコード
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 在庫組織コード
    --========================================
    lt_inv_org_code := FND_PROFILE.VALUE( cv_prof_inv_org_code );
    IF ( lt_inv_org_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name    -- アプリケーション短縮名
                    ,iv_name         => cv_msg_prof_err        -- メッセージコード
                    ,iv_token_name1  => cv_tkn_profile         -- トークンコード1
                    ,iv_token_value1 => cv_prof_inv_org_code   -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 在庫組織ID
    --========================================
    gt_inv_org_id := xxcoi_common_pkg.get_organization_id(
                       iv_organization_code => lt_inv_org_code
                     );
    IF ( gt_inv_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name    -- アプリケーション短縮名
                    ,iv_name         => cv_msg_inv_org_id_err  -- メッセージコード
                    ,iv_token_name1  => cv_tkn_org_code_tok    -- トークンコード1
                    ,iv_token_value1 => lt_inv_org_code        -- トークン値1
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
   * Procedure Name   : check_parameter
   * Description      : パラメータチェック(A-2)
   ***********************************************************************************/
  PROCEDURE check_parameter(
    iv_date_from           IN   VARCHAR2  -- 期間(FROM)
   ,iv_date_to             IN   VARCHAR2  -- 期間(TO)
   ,od_date_from           OUT  DATE      -- 期間(FROM)
   ,od_date_to             OUT  DATE      -- 期間(TO)
   ,ov_errbuf              OUT  VARCHAR2  -- エラー・メッセージ           --# 固定 #
   ,ov_retcode             OUT  VARCHAR2  -- リターン・コード             --# 固定 #
   ,ov_errmsg              OUT  VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_parameter'; -- プログラム名
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
    lv_check_item          VARCHAR2(100); -- メッセージ出力用
    ld_date_from           DATE;          -- 期間(FROM)
    ld_date_to             DATE;          -- 期間(TO)
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
    -- 日付書式に変換
    ld_date_from  := FND_DATE.STRING_TO_DATE( iv_date_from ,cv_fmt_std );
    ld_date_to    := FND_DATE.STRING_TO_DATE( iv_date_to ,cv_fmt_std );
--
    -- 期間(FROM)必須チェック
    IF ( ( iv_date_from IS NULL ) AND ( iv_date_to IS NOT NULL ) ) THEN
      lv_check_item := cv_msg_date_from;
      RAISE global_format_chk_expt;
    END IF;
    -- 期間(TO)必須チェック
    IF ( ( iv_date_from IS NOT NULL ) AND ( iv_date_to IS NULL ) ) THEN
      lv_check_item := cv_msg_date_to;
      RAISE global_format_chk_expt;
    END IF;
--
    -- 期間(FROM)、期間(TO)両方入力された場合
    IF ( ( iv_date_from IS NOT NULL ) AND ( iv_date_to IS NOT NULL ) ) THEN
      -- 期間(FROM)／期間(TO)日付逆転チェック
      IF ( ld_date_from > ld_date_to ) THEN
        RAISE global_date_rever_chk_expt;
      END IF;
    END IF;
--
    -- 戻り値を返却
    od_date_from  := ld_date_from; -- 期間(FROM)
    od_date_to    := ld_date_to;   -- 期間(TO)
--
  EXCEPTION
--
    -- *** 書式チェック例外ハンドラ ***
    WHEN global_format_chk_expt THEN
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_short_name         -- アプリケーション短縮名
                     ,iv_name         => cv_msg_format_check_err     -- メッセージコード
                     ,iv_token_name1  => cv_tkn_para_date            -- トークンコード1
                     ,iv_token_value1 => lv_check_item               -- トークン値1
                    );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    -- *** 日付逆転チェック例外ハンドラ ***
    WHEN global_date_rever_chk_expt THEN
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_short_name         -- アプリケーション短縮名
                     ,iv_name         => cv_msg_date_rever_err       -- メッセージコード
                     ,iv_token_name1  => cv_tkn_date_from            -- トークンコード1
                     ,iv_token_value1 => cv_msg_date_from            -- トークン値1
                     ,iv_token_name2  => cv_tkn_date_to              -- トークンコード2
                     ,iv_token_value2 => cv_msg_date_to              -- トークン値2
                   );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
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
  END check_parameter;
--
  /**********************************************************************************
   * Procedure Name   : get_price_list_data
   * Description      : 特売価格表データ取得(A-3)
   ***********************************************************************************/
  PROCEDURE get_price_list_data(
    iv_base_code           IN   VARCHAR2  --  拠点コード
   ,iv_customer_code       IN   VARCHAR2  --  顧客コード
   ,iv_item_code           IN   VARCHAR2  --  品目コード
   ,id_date_from           IN   DATE      --  期間(FROM)
   ,id_date_to             IN   DATE      --  期間(TO)
   ,ov_errbuf              OUT  VARCHAR2  --  エラー・メッセージ           --# 固定 #
   ,ov_retcode             OUT  VARCHAR2  --  リターン・コード             --# 固定 #
   ,ov_errmsg              OUT  VARCHAR2  --  ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_price_list_data'; -- プログラム名
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
    -- 対象データ取得
    OPEN get_price_list_cur(
           iv_base_code         -- 拠点コード
          ,iv_customer_code     -- 顧客コード
          ,iv_item_code         -- 品目コード
          ,id_date_from         -- 期間(FROM)
          ,id_date_to           -- 期間(TO)
         );
--
    FETCH get_price_list_cur BULK COLLECT INTO gt_out_file_tab;
    CLOSE get_price_list_cur;
--
    -- 対象件数カウント
    gn_target_cnt := gt_out_file_tab.COUNT;
--
  EXCEPTION
    -- *** 対象0件例外ハンドラ ***
    WHEN global_no_data_expt THEN
      ov_retcode := cv_status_warn;
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
      IF ( get_price_list_cur%ISOPEN ) THEN
        CLOSE get_price_list_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_price_list_data;
--
  /**********************************************************************************
   * Procedure Name   : output_data
   * Description      : データ出力(A-4)
   ***********************************************************************************/
  PROCEDURE output_data(
    ov_errbuf              OUT  VARCHAR2  -- エラー・メッセージ           --# 固定 #
   ,ov_retcode             OUT  VARCHAR2  -- リターン・コード             --# 固定 #
   ,ov_errmsg              OUT  VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
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
    lv_delimit          CONSTANT  VARCHAR2(1) := ',';       -- 区切り文字
--
    -- *** ローカル変数 ***
    lv_line_data        VARCHAR2(5000); -- OUTPUTデータ編集用
--
    -- *** ローカル・カーソル ***
    --見出し取得用カーソル
    CURSOR head_cur
    IS
      SELECT flv.description AS head
      FROM   fnd_lookup_values flv
      WHERE  flv.language      = ct_lang
      AND    flv.lookup_type   = cv_qck_typ_head
      AND    gd_process_date  >= NVL( flv.start_date_active ,gd_process_date )
      AND    gd_process_date  <= NVL( flv.end_date_active   ,gd_process_date )
      AND    flv.enabled_flag  = cv_flag_y
      AND    flv.meaning       LIKE cv_qck_typ_003a09
      ORDER BY
             flv.meaning
      ;
--
    -- *** ローカル・レコード ***
--
    lt_head_tab g_head_ttype;
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    ----------------------
    -- データ見出し出力
    ----------------------
    -- データの見出しを取得
    OPEN  head_cur;
    FETCH head_cur BULK COLLECT INTO lt_head_tab;
    CLOSE head_cur;
--
    -- データの見出しを編集
    <<data_head_output>>
    FOR i IN 1..lt_head_tab.COUNT LOOP
      IF ( i = 1 ) THEN
        lv_line_data := lt_head_tab(i);
      ELSE
        lv_line_data := lv_line_data || lv_delimit || lt_head_tab(i);
      END IF;
    END LOOP data_head_output;
--
    -- データの見出しを出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_line_data
    );
--
    ----------------------
    -- データ出力
    ----------------------
    -- データを取得
    <<data_output>>
    FOR i IN 1..gt_out_file_tab.COUNT LOOP
      -- 初期化
      lv_line_data := NULL;
      -- データを編集
      lv_line_data :=    gt_out_file_tab(i).proc_kbn                                  -- 処理区分
        || lv_delimit || gt_out_file_tab(i).customer_code                             -- 顧客コード
        || lv_delimit || gt_out_file_tab(i).customer_name                             -- 顧客名称
        || lv_delimit || gt_out_file_tab(i).item_code                                 -- 品目コード
        || lv_delimit || gt_out_file_tab(i).item_name                                 -- 品目名称
        || lv_delimit || TO_CHAR( gt_out_file_tab(i).price )                          -- 価格
        || lv_delimit || TO_CHAR( gt_out_file_tab(i).start_date_active ,cv_fmt_std )  -- 有効開始日
        || lv_delimit || TO_CHAR( gt_out_file_tab(i).end_date_active   ,cv_fmt_std )  -- 有効終了日
        ;
--
      -- データを出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_line_data
      );
--
      -- 成功件数カウント
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
      IF ( head_cur%ISOPEN ) THEN
        CLOSE head_cur;
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
  PROCEDURE submain(
    iv_base_code        IN   VARCHAR2  -- 拠点コード
   ,iv_customer_code    IN   VARCHAR2  -- 顧客コード
   ,iv_item_code        IN   VARCHAR2  -- 品目コード
   ,iv_date_from        IN   VARCHAR2  -- 期間(FROM)
   ,iv_date_to          IN   VARCHAR2  -- 期間(TO)
   ,ov_errbuf           OUT  VARCHAR2  -- エラー・メッセージ           --# 固定 #
   ,ov_retcode          OUT  VARCHAR2  -- リターン・コード             --# 固定 #
   ,ov_errmsg           OUT  VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
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
    ld_date_from          DATE;  -- 期間(FROM)
    ld_date_to            DATE;  -- 期間(TO)
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
--
    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    init(
      iv_base_code          => iv_base_code           -- 拠点コード
     ,iv_customer_code      => iv_customer_code       -- 顧客コード
     ,iv_item_code          => iv_item_code           -- 品目コード
     ,iv_date_from          => iv_date_from           -- 期間(FROM)
     ,iv_date_to            => iv_date_to             -- 期間(TO)
     ,ov_errbuf             => lv_errbuf              -- エラー・メッセージ           --# 固定 #
     ,ov_retcode            => lv_retcode             -- リターン・コード             --# 固定 #
     ,ov_errmsg             => lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- エラー処理
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- パラメータチェック(A-2)
    -- ===============================
    check_parameter(
      iv_date_from          => iv_date_from           -- 期間(FROM)
     ,iv_date_to            => iv_date_to             -- 期間(TO)
     ,od_date_from          => ld_date_from           -- 期間(FROM)
     ,od_date_to            => ld_date_to             -- 期間(TO)
     ,ov_errbuf             => lv_errbuf              -- エラー・メッセージ           --# 固定 #
     ,ov_retcode            => lv_retcode             -- リターン・コード             --# 固定 #
     ,ov_errmsg             => lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- エラー処理
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 特売価格表データ取得(A-3)
    -- ===============================
    get_price_list_data(
      iv_base_code          => iv_base_code           -- 拠点コード
     ,iv_customer_code      => iv_customer_code       -- 顧客コード
     ,iv_item_code          => iv_item_code           -- 品目コード
     ,id_date_from          => ld_date_from           -- 期間(FROM)
     ,id_date_to            => ld_date_to             -- 期間(TO)
     ,ov_errbuf             => lv_errbuf              -- エラー・メッセージ           --# 固定 #
     ,ov_retcode            => lv_retcode             -- リターン・コード             --# 固定 #
     ,ov_errmsg             => lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- エラー処理
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 対象件数が0件
    IF ( gn_target_cnt = 0 ) THEN
      RAISE global_no_data_expt;
    END IF;
--
    -- ===============================
    -- データ出力(A-4)
    -- ===============================
    output_data(
       ov_errbuf              => lv_errbuf              -- エラー・メッセージ           --# 固定 #
      ,ov_retcode             => lv_retcode             -- リターン・コード             --# 固定 #
      ,ov_errmsg              => lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- エラー処理
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** 対象0件例外ハンドラ ***
    WHEN global_no_data_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_xxcos_short_name
                    ,iv_name        => cv_msg_no_data
                   );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_warn;
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
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
    errbuf                 OUT  VARCHAR2  -- エラー・メッセージ  --# 固定 #
   ,retcode                OUT  VARCHAR2  -- リターン・コード    --# 固定 #
   ,iv_base_code           IN   VARCHAR2  -- 拠点コード
   ,iv_customer_code       IN   VARCHAR2  -- 顧客コード
   ,iv_item_code           IN   VARCHAR2  -- 品目コード
   ,iv_date_from           IN   VARCHAR2  -- 期間(FROM)
   ,iv_date_to             IN   VARCHAR2  -- 期間(TO)
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
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
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
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      iv_base_code          => iv_base_code           -- 拠点コード
     ,iv_customer_code      => iv_customer_code       -- 顧客コード
     ,iv_item_code          => iv_item_code           -- 品目コード
     ,iv_date_from          => iv_date_from           -- 期間(FROM)
     ,iv_date_to            => iv_date_to             -- 期間(TO)
     ,ov_errbuf             => lv_errbuf              -- エラー・メッセージ           --# 固定 #
     ,ov_retcode            => lv_retcode             -- リターン・コード             --# 固定 #
     ,ov_errmsg             => lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- エラー出力
    IF ( lv_retcode = cv_status_warn ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      -- 空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
    -- エラー出力
    ELSIF ( lv_retcode = cv_status_error ) THEN
      -- 件数クリア、エラー件数セット
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
      -- 空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
    END IF;
    --
    -- 対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_short_name
                   ,iv_name         => cv_target_rec_msg
                   ,iv_token_name1  => cv_cnt_token
                   ,iv_token_value1 => TO_CHAR( gn_target_cnt )
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    -- 成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_short_name
                   ,iv_name         => cv_success_rec_msg
                   ,iv_token_name1  => cv_cnt_token
                  ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    -- エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_short_name
                   ,iv_name         => cv_error_rec_msg
                   ,iv_token_name1  => cv_cnt_token
                   ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
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
                    iv_application  => cv_xxccp_short_name
                   ,iv_name         => lv_message_code
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    -- ステータスセット
    retcode := lv_retcode;
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
END XXCOS003A09C;
/
