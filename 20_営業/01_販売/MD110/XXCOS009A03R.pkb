CREATE OR REPLACE PACKAGE BODY APPS.XXCOS009A03R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS009A03R (body)
 * Description      : 原価割れチェックリスト
 * MD.050           : 原価割れチェックリスト MD050_COS_009_A03
 * Version          : 1.9
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  check_parameter        パラメータチェック(A-2)
 *  get_data               対象データ取得(A-3)
 *  check_cost             営業原価チェック(A-4)
 *  insert_rpt_wrk_data    帳票ワークテーブル登録(A-5)
 *  execute_svf            SVF起動(A-6)
 *  delete_rpt_wrk_data    帳票ワークテーブル削除(A-7)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/10    1.0   H.Ri             新規作成
 *  2009/02/17    1.1   H.Ri             get_msgのパッケージ名修正
 *  2009/04/21    1.2   K.Kiriu          [T1_0444]成績計上者コードの結合不正対応
 *  2009/06/17    1.3   N.Nishimura      [T1_1439]対象件数0件時、正常終了とする
 *  2009/06/25    1.4   N.Nishimura      [T1_1437]データパージ不具合対応
 *  2009/08/11    1.5   N.Maeda          [0000865]PT対応
 *  2009/08/13    1.5   N.Maeda          [0000865]レビュー指摘対応
 *  2009/09/02    1.6   M.Sano           [0001227]PT対応
 *  2009/10/02    1.7   S.Miyakoshi      [0001378対応]帳票ワークテーブルの桁あふれ対応
 *  2010/01/18    1.8   S.Miyakoshi      [E_本稼動_00711]PT対応 ログイン拠点情報VIEWからの取得をメインSQL外で処理する
 *  2010/02/17    1.9   N.Maeda          [E_本稼動_01553]INパラメータ(納品日)妥当性チェック内容の修正
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
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  --*** 会計期間区分取得例外 ***
  global_acc_period_cls_get_expt    EXCEPTION;
  --*** 会計期間取得例外 ***
  global_account_period_get_expt    EXCEPTION;
  --*** 書式チェック例外 ***
  global_format_chk_expt            EXCEPTION;
  --*** 日付逆転チェック例外 ***
  global_date_rever_chk_expt        EXCEPTION;
  --*** 日付範囲チェック例外 ***
  global_date_range_chk_expt        EXCEPTION;
  --*** 対象データ取得例外 ***
  global_data_get_expt              EXCEPTION;
  --*** 営業原価取得例外 ***
  global_sale_cost_get_expt         EXCEPTION;
  --*** 処理対象データ登録例外 ***
  global_data_insert_expt           EXCEPTION;
  --*** SVF起動例外 ***
  global_svf_excute_expt            EXCEPTION;
  --*** 対象データロック例外 ***
  global_data_lock_expt             EXCEPTION;
  --*** 対象データ削除例外 ***
  global_data_delete_expt           EXCEPTION;
  
  PRAGMA EXCEPTION_INIT( global_data_lock_expt, -54 );
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT  VARCHAR2(100) := 'XXCOS009A03R';         -- パッケージ名
  cv_conc_name              CONSTANT  VARCHAR2(100) := 'XXCOS009A03R';         -- コンカレント名
  --帳票出力関連
  cv_report_id              CONSTANT  VARCHAR2(100) := 'XXCOS009A03R';         -- 帳票ＩＤ
  cv_frm_file               CONSTANT  VARCHAR2(100) := 'XXCOS009A03S.xml';     -- フォーム様式ファイル名
  cv_vrq_file               CONSTANT  VARCHAR2(100) := 'XXCOS009A03S.vrq';     -- クエリー様式ファイル名
  cv_output_mode            CONSTANT  VARCHAR2(1)   := '1';                    -- 出力区分(PDF)
  cv_extension              CONSTANT  VARCHAR2(100) := '.pdf';                 -- 拡張子(PDF)
  cv_xxcos_short_name       CONSTANT  VARCHAR2(100) := 'XXCOS';                -- 販物領域短縮アプリ名
  cv_xxccp_short_name       CONSTANT  VARCHAR2(100) := 'XXCCP';                -- 共通領域短縮アプリ名
  cv_xxcoi_short_name       CONSTANT  VARCHAR2(100) := 'XXCOI';                -- 在庫領域短縮アプリ名
  --メッセージ
  cv_msg_format_check_err   CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00002';    -- 日付書式チェックエラーメッセージ
  cv_msg_acc_cls_get_err    CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11858';    -- 会計期間区分取得エラーメッセージ
  cv_msg_acc_perd_get_err   CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00026';    -- 会計期間取得エラーメッセージ
  cv_msg_date_rever_err     CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00005';    -- 日付逆転エラーメッセージ
  cv_msg_date_range_err     CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11851';    -- 日付範囲エラーメッセージ
  cv_msg_para_output_note   CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11853';    -- パラメータ出力メッセージ
  cv_msg_sale_cost_get_err  CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11852';    -- 営業原価取得エラーメッセージ
  cv_msg_insert_err         CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00010';    -- データ登録エラーメッセージ
  cv_msg_no_data_err        CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00018';    -- 明細0件エラーメッセージ
  cv_msg_select_err         CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00013';    -- データ抽出エラーメッセージ
  cv_msg_lock_err           CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00001';    -- ロック取得エラーメッセージ
  cv_msg_delete_err         CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00012';    -- データ削除エラーメッセージ
  cv_msg_api_err            CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00017';    -- APIエラーメッセージ
  cv_msg_parameter          CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11853';    -- パラメータ出力メッセージ
  cv_msg_org_cd_err         CONSTANT  VARCHAR2(100) :=  'APP-XXCOI1-00005';    -- 在庫組織コード取得エラーメッセージ
  cv_msg_org_id_err         CONSTANT  VARCHAR2(100) :=  'APP-XXCOI1-00006';    -- 在庫組織ID取得エラーメッセージ
  cv_msg_proc_date_err      CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00014';    -- 業務日付取得エラーメッセージ
  cv_msg_prof_err           CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00004';    -- プロファイル取得エラーメッセージ
-- ************************ 2010/01/18 S.Miyakoshi Var1.8 ADD START ************************ --
  cv_msg_login_view         CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00119';    -- ログイン拠点情報VIEW
-- ************************ 2010/01/18 S.Miyakoshi Var1.8 ADD  END  ************************ --
  --トークン名
  cv_tkn_nm_account         CONSTANT  VARCHAR2(100) :=  'ACCOUNT_NAME';        --会計期間種別名称
  cv_tkn_nm_para_date       CONSTANT  VARCHAR2(100) :=  'PARA_DATE';           --納品日(FROM)または納品日(TO)
  cv_tkn_nm_base_code       CONSTANT  VARCHAR2(100) :=  'BASE_CODE';           --売上拠点コード
  cv_tkn_nm_date_from       CONSTANT  VARCHAR2(100) :=  'DATE_FROM';           --納品日(FROM)
  cv_tkn_nm_date_to         CONSTANT  VARCHAR2(100) :=  'DATE_TO';             --納品日(TO)
  cv_tkn_nm_sale_emp        CONSTANT  VARCHAR2(100) :=  'SALE_EMP';            --営業担当
  cv_tkn_nm_ship_to         CONSTANT  VARCHAR2(100) :=  'SHIP_TO';             --出荷先
  cv_tkn_nm_date_min        CONSTANT  VARCHAR2(100) :=  'DATE_MIN';            --会計期間前月
  cv_tkn_nm_date_max        CONSTANT  VARCHAR2(100) :=  'DATE_MAX';            --会計期間当月
  cv_tkn_nm_item_code       CONSTANT  VARCHAR2(100) :=  'HINMOKU';             --品目コード
  cv_tkn_nm_table_name      CONSTANT  VARCHAR2(100) :=  'TABLE_NAME';          --テーブル名称
  cv_tkn_nm_table_lock      CONSTANT  VARCHAR2(100) :=  'TABLE';               --テーブル名称(ロックエラー時用)
  cv_tkn_nm_key_data        CONSTANT  VARCHAR2(100) :=  'KEY_DATA';            --キーデータ
  cv_tkn_nm_api_name        CONSTANT  VARCHAR2(100) :=  'API_NAME';            --API名称
  cv_tkn_nm_profile1        CONSTANT  VARCHAR2(100) :=  'PROFILE';             --プロファイル名(販売領域)
  cv_tkn_nm_profile2        CONSTANT  VARCHAR2(100) :=  'PRO_TOK';             --プロファイル名(在庫領域)
  cv_tkn_nm_org_cd          CONSTANT  VARCHAR2(100) :=  'ORG_CODE_TOK';        --在庫組織コード
  cv_tkn_nm_acc_type        CONSTANT  VARCHAR2(100) :=  'TYPE';                --会計期間区分参照タイプ
  --トークン値
  cv_msg_vl_acc_cls_ar      CONSTANT  VARCHAR2(100) :=  'AR';                  --AR
  cv_msg_vl_date_from       CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11854';    --納品日FROM
  cv_msg_vl_date_to         CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11855';    --納品日TO
  cv_msg_vl_table_name1     CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11856';    --帳票ワークテーブル名
  cv_msg_vl_table_name2     CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11857';    --販売実績テーブル名
  cv_msg_vl_api_name        CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00041';    --API名称
  cv_msg_vl_key_request_id  CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00088';    --要求ID
  cv_msg_vl_min_date        CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00120';    --MIN日付
  cv_msg_vl_max_date        CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00056';    --MAX日付
-- ******** 2010/02/17 1.9 N.Maeda MOD START ******** --
  cv_msg_vl_target_month    CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11859';    --原価割れチェックリスト取得対象月数
-- ******** 2010/02/17 1.9 N.Maeda MOD  END  ******** --
  --日付フォーマット
  cv_yyyymmdd               CONSTANT  VARCHAR2(100) :=  'YYYYMMDD';            --YYYYMMDD型
  cv_yyyy_mm_dd             CONSTANT  VARCHAR2(100) :=  'YYYY/MM/DD';          --YYYY/MM/DD型
  cv_yyyy_mm                CONSTANT  VARCHAR2(100) :=  'YYYY/MM';             --YYYY/MM型
  --クイックコード参照用
  --使用可能フラグ定数
  ct_enabled_flg_y          CONSTANT  fnd_lookup_values.enabled_flag%TYPE
                                                    :=  'Y';                   --使用可能
  cv_lang                   CONSTANT  VARCHAR2(100) :=  USERENV( 'LANG' );     --言語
  cv_type_acc               CONSTANT  VARCHAR2(100) :=  'XXCOS1_ACCOUNT_PERIOD';  --会計期間の種別
  cv_diff_y                 CONSTANT  VARCHAR2(100) :=  'Y';                   --Y
  cv_ord_src_type           CONSTANT  VARCHAR2(100) :=  'XXCOS1_ODR_SRC_MST_009_A03';
                                                                               --受注ソースのクイックタイプ
  cv_ord_src_code           CONSTANT  VARCHAR2(100) :=  'XXCOS_009_A03%';      --受注ソースのクイックコード
  cv_mk_org_type            CONSTANT  VARCHAR2(100) :=  'XXCOS1_MK_ORG_CLS_MST_009_A03';
                                                                               --作成元区分のクイックタイプ
  cv_mk_org_code1           CONSTANT  VARCHAR2(100) :=  'XXCOS_009_A03_1%';    --作成元区分のクイックコード(OM受注)
  cv_mk_org_code2           CONSTANT  VARCHAR2(100) :=  'XXCOS_009_A03_2%';    --作成元区分のクイックコード
                                                                               --(商品別売上計算)
  cv_sl_cls_type            CONSTANT  VARCHAR2(100) :=  'XXCOS1_SALE_CLASS_MST_009_A03';
                                                                               --売上区分のクイックタイプ
  cv_sl_cls_code1           CONSTANT  VARCHAR2(100) :=  'XXCOS_009_A03_1%';    --売上区分のクイックコード
                                                                               --(協賛、見本、広告宣伝費)
  cv_sl_cls_code2           CONSTANT  VARCHAR2(100) :=  'XXCOS_009_A03_2%';    --売上区分のクイックコード(消化・VD消化)
  cv_no_inv_item_type       CONSTANT  VARCHAR2(100) := 'XXCOS1_NO_INV_ITEM_CODE';
                                                                               --非在庫品目のクイックタイプ
  cv_cus_cls_type           CONSTANT  VARCHAR2(100) :=  'XXCOS1_CUS_CLASS_MST_009_A03';
                                                                               --顧客区分のクイックタイプ
  cv_cus_cls_code           CONSTANT  VARCHAR2(100) :=  'XXCOS_009_A03%';      --顧客区分のクイックコード
  --プロファイル関連
  cv_prof_org               CONSTANT  VARCHAR2(100) :=  'XXCOI1_ORGANIZATION_CODE';
                                                                               -- プロファイル名(在庫組織コード)
  cv_prof_min_date          CONSTANT  VARCHAR2(100) :=  'XXCOS1_MIN_DATE';     -- プロファイル名(MIN日付)
  cv_prof_max_date          CONSTANT  VARCHAR2(100) :=  'XXCOS1_MAX_DATE';     -- プロファイル名(MAX日付)
-- ******** 2010/02/17 1.9 N.Maeda MOD START ******** --
  cv_prof_target_month      CONSTANT  VARCHAR2(100) :=  'XXCOS1_BELOW_COST_CL_TARGET_MONTH'; -- プロファイル名(原価割れチェックリスト取得対象月数)
-- ******** 2010/02/17 1.9 N.Maeda MOD  END  ******** --
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  --原価割れチェックリスト帳票ワークテーブル型
  TYPE g_rpt_data_ttype IS TABLE OF xxcos_rep_cost_div_list%ROWTYPE INDEX BY BINARY_INTEGER;
  --品目コードテーブル型
  TYPE g_item_cd_ttype  IS TABLE OF xxcos_sales_exp_lines.item_code%TYPE INDEX BY BINARY_INTEGER;
-- ************************ 2010/01/18 S.Miyakoshi Var1.8 ADD START ************************ --
  --拠点情報テーブル型
  TYPE g_rec_base_info  IS RECORD
    (
      base_code             hz_cust_accounts.account_number%TYPE,               --拠点コード
      base_name             hz_parties.party_name%TYPE                          --拠点名称
    );
  TYPE g_base_info_ttype IS TABLE OF g_rec_base_info INDEX BY PLS_INTEGER;
-- ************************ 2010/01/18 S.Miyakoshi Var1.8 ADD  END  ************************ --
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  g_report_data_tab         g_rpt_data_ttype;                                   --帳票データコレクション
  g_err_item_cd_tab         g_item_cd_ttype;                                    --営業原価未設定の品目コード
  gt_org_id                 mtl_parameters.organization_id%TYPE;                --在庫組織ID
  gd_proc_date              DATE;                                               --業務日付
  gd_min_date               DATE;                                               --MIN日付
  gd_max_date               DATE;                                               --MAX日付
-- ******** 2010/02/17 1.9 N.Maeda MOD START ******** --
  gn_target_month           NUMBER;                                             --原価割れチェックリスト取得対象月数
  gv_date_err_flag          VARCHAR2(10);
-- ******** 2010/02/17 1.9 N.Maeda MOD  END  ******** --
-- ************************ 2010/01/18 S.Miyakoshi Var1.8 ADD START ************************ --
  g_base_info_tab           g_base_info_ttype;                                  --拠点情報コレクション
  gv_base_code              hz_cust_accounts.account_number%TYPE;               --拠点コード
  gv_base_name              hz_parties.party_name%TYPE;                         --拠点名称
-- ************************ 2010/01/18 S.Miyakoshi Var1.8 ADD  END  ************************ --
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_sale_base_code   IN  VARCHAR2,     --   売上拠点コード
    iv_dlv_date_from    IN  VARCHAR2,     --   納品日(FROM)
    iv_dlv_date_to      IN  VARCHAR2,     --   納品日(TO)
    iv_sale_emp_code    IN  VARCHAR2,     --   営業担当者コード
    iv_ship_to_code     IN  VARCHAR2,     --   出荷先コード
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'init';                 -- プログラム名
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
    lv_para_msg   VARCHAR2(5000);                         -- パラメータ出力メッセージ
    lt_org_cd     mtl_parameters.organization_code%TYPE;  -- 在庫組織コード
    lv_date_item  VARCHAR2(100);                          -- MIN日付/MAX日付
-- ************************ 2010/01/18 S.Miyakoshi Var1.8 ADD START ************************ --
    lv_login_view VARCHAR2(100);                          -- ログイン拠点情報VIEW
-- ************************ 2010/01/18 S.Miyakoshi Var1.8 ADD  END  ************************ --
--
    -- *** ローカル・カーソル ***
-- ************************ 2010/01/18 S.Miyakoshi Var1.8 ADD START ************************ --
    --拠点情報取得
    CURSOR base_cur
    IS
      SELECT  lbiv.base_code          base_code              --拠点コード
             ,lbiv.base_name          base_name              --拠点名
      FROM    xxcos_login_base_info_v lbiv                   --ログインユーザ拠点ビュー
      WHERE   ( ( iv_sale_base_code IS NULL )
                OR ( iv_sale_base_code IS NOT NULL AND iv_sale_base_code = lbiv.base_code ) )
      ;
-- ************************ 2010/01/18 S.Miyakoshi Var1.8 ADD  END  ************************ --
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
    --========================================
    -- 1.パラメータ出力処理
    --========================================
    lv_para_msg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_parameter,
        iv_token_name1        =>  cv_tkn_nm_base_code,
        iv_token_value1       =>  iv_sale_base_code,
        iv_token_name2        =>  cv_tkn_nm_date_from,
        iv_token_value2       =>  iv_dlv_date_from,
        iv_token_name3        =>  cv_tkn_nm_date_to,
        iv_token_value3       =>  iv_dlv_date_to,
        iv_token_name4        =>  cv_tkn_nm_sale_emp,
        iv_token_value4       =>  iv_sale_emp_code,
        iv_token_name5        =>  cv_tkn_nm_ship_to,
        iv_token_value5       =>  iv_ship_to_code
      );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_para_msg
    );
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --========================================
    -- 2.在庫組織コード取得処理
    --========================================
    lt_org_cd := FND_PROFILE.VALUE( cv_prof_org );
    IF ( lt_org_cd IS NULL ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcoi_short_name,
        iv_name               =>  cv_msg_org_cd_err,
        iv_token_name1        =>  cv_tkn_nm_profile2,
        iv_token_value1       =>  cv_prof_org
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 3.在庫組織ID取得処理
    --========================================
    gt_org_id := xxcoi_common_pkg.get_organization_id( lt_org_cd );
    IF ( gt_org_id IS NULL ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcoi_short_name,
        iv_name               =>  cv_msg_org_id_err,
        iv_token_name1        =>  cv_tkn_nm_org_cd,
        iv_token_value1       =>  lt_org_cd
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 4.業務日付取得処理
    --========================================
    gd_proc_date := TRUNC( xxccp_common_pkg2.get_process_date );
    IF ( gd_proc_date IS NULL ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_proc_date_err
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 5.MIN日付取得処理
    --========================================
    gd_min_date := FND_DATE.STRING_TO_DATE( FND_PROFILE.VALUE( cv_prof_min_date ), cv_yyyy_mm_dd );
    IF ( gd_min_date IS NULL ) THEN
      lv_date_item            :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_min_date
      );
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_prof_err,
        iv_token_name1        =>  cv_tkn_nm_profile1,
        iv_token_value1       =>  lv_date_item
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 6.MAX日付取得処理
    --========================================
    gd_max_date := FND_DATE.STRING_TO_DATE( FND_PROFILE.VALUE( cv_prof_max_date ), cv_yyyy_mm_dd );
    IF ( gd_max_date IS NULL ) THEN
      lv_date_item            :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_max_date
      );
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_prof_err,
        iv_token_name1        =>  cv_tkn_nm_profile1,
        iv_token_value1       =>  lv_date_item
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- ************************ 2010/01/18 S.Miyakoshi Var1.8 ADD START ************************ --
    --========================================
    -- 7.配下拠点コード取得処理
    --========================================
    BEGIN
      -- カーソルOPEN
      OPEN  base_cur;
      -- バルクフェッチ
      FETCH base_cur BULK COLLECT INTO g_base_info_tab;
      -- カーソルCLOSE
      CLOSE base_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- カーソルCLOSE
        IF ( base_cur%ISOPEN ) THEN
          CLOSE base_cur;
        END IF;
--
      lv_login_view           :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_login_view
      );
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_select_err,
        iv_token_name1        =>  cv_tkn_nm_table_name,
        iv_token_value1       =>  lv_login_view,
        iv_token_name2        =>  cv_tkn_nm_key_data,
        iv_token_value2       =>  NULL
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END;
-- ************************ 2010/01/18 S.Miyakoshi Var1.8 ADD  END  ************************ --
-- ******** 2010/02/17 1.9 N.Maeda MOD START ******** --
    -- ===================================================
    -- プロファイル:原価割れチェックリスト取得対象月数取得
    -- ===================================================
    gn_target_month := FND_PROFILE.VALUE( cv_prof_target_month );
    IF ( gn_target_month IS NULL ) THEN
      lv_date_item            :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_target_month
      );
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_prof_err,
        iv_token_name1        =>  cv_tkn_nm_profile1,
        iv_token_value1       =>  lv_date_item
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
-- ******** 2010/02/17 1.9 N.Maeda MOD  END  ******** --
--
--#################################  固定例外処理部 START   ####################################
--
  EXCEPTION
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
    iv_dlv_date_from    IN  VARCHAR2,     --   納品日(FROM)
    iv_dlv_date_to      IN  VARCHAR2,     --   納品日(TO)
    od_dlv_date_from    OUT DATE,         --   納品日(FROM)_チェックOK
    od_dlv_date_to      OUT DATE,         --   納品日(TO)_チェックOK
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
-- ******** 2010/02/17 1.9 N.Maeda DEL START ******** --
--    lt_account_cls       fnd_lookup_values.meaning%TYPE;   --会計区分
--    ld_acc_date_from     DATE;                             --会計期間(FROM)
--    ld_acc_date_to       DATE;                             --会計期間(TO)
-- ******** 2010/02/17 1.9 N.Maeda DEL  END  ******** --
    ld_dlv_date_from     DATE;                             --納品日(FROM)
    ld_dlv_date_to       DATE;                             --納品日(TO)
    lv_check_item        VARCHAR2(100);                    --納品日(FROM)又は納品日(TO)文言
    lv_check_item1       VARCHAR2(100);                    --納品日(FROM)文言
    lv_check_item2       VARCHAR2(100);                    --納品日(TO)文言
-- ******** 2010/02/17 1.9 N.Maeda DEL START ******** --
--    ld_acc_date_from_ym  DATE;                             --会計期間(FROM)_年月
--    ld_acc_date_pre_ym   DATE;                             --会計期間前月_年月
-- ******** 2010/02/17 1.9 N.Maeda DEL  END  ******** --
    ld_dlv_date_from_ym  DATE;                             --納品日(FROM)_年月
    ld_dlv_date_to_ym    DATE;                             --納品日(TO)_年月
-- ******** 2010/02/17 1.9 N.Maeda DEL START ******** --
--    lv_acc_status        VARCHAR2(100);                    --会計期間ステータス
-- ******** 2010/02/17 1.9 N.Maeda DEL  END  ******** --
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
-- ******** 2010/02/17 1.9 N.Maeda DEL START ******** --
--    --会計区分取得
--    BEGIN
---- ******** 2009/08/11 1.5 N.Maeda MOD START *********** --
--      SELECT  look_val.meaning            acc_cls
--      INTO    lt_account_cls
--      FROM    fnd_lookup_values           look_val
--      WHERE   look_val.language           = cv_lang
--      AND     look_val.lookup_type        = cv_type_acc
--      AND     look_val.attribute1         = cv_diff_y
--      AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
--      AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
--      AND     look_val.enabled_flag       = ct_enabled_flg_y
--      AND     rownum                      = 1
--      ;
----
----      SELECT  look_val.meaning            acc_cls
----      INTO    lt_account_cls
----      FROM    fnd_lookup_values           look_val,
----              fnd_lookup_types_tl         types_tl,
----              fnd_lookup_types            types,
----              fnd_application_tl          appl,
----              fnd_application             app
----      WHERE   appl.application_id         = types.application_id
----      AND     app.application_id          = appl.application_id
----      AND     types_tl.lookup_type        = look_val.lookup_type
----      AND     types.lookup_type           = types_tl.lookup_type
----      AND     types.security_group_id     = types_tl.security_group_id
----      AND     types.view_application_id   = types_tl.view_application_id
----      AND     types_tl.language           = cv_lang
----      AND     look_val.language           = cv_lang
----      AND     appl.language               = cv_lang
----      AND     app.application_short_name  = cv_xxcos_short_name
----      AND     look_val.lookup_type        = cv_type_acc
----      AND     look_val.attribute1         = cv_diff_y
----      AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
----      AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
----      AND     look_val.enabled_flag       = ct_enabled_flg_y
----      AND     rownum                      = 1
----      ;
---- ******** 2009/08/11 1.5 N.Maeda MOD END *********** --
--    EXCEPTION
--      WHEN NO_DATA_FOUND THEN
--        RAISE global_acc_period_cls_get_expt;
--    END;
--    --会計期間情報取得
--    xxcos_common_pkg.get_account_period(
--      iv_account_period     =>  lt_account_cls,           --会計区分
--      id_base_date          =>  NULL,                     --基準日
--      ov_status             =>  lv_acc_status,            --会計期間ステータス
--      od_start_date         =>  ld_acc_date_from,         --会計(FROM)
--      od_end_date           =>  ld_acc_date_to,           --会計(TO)
--      ov_errbuf             =>  lv_errbuf,                --エラーメッセージ
--      ov_retcode            =>  lv_retcode,               --リターンコード
--      ov_errmsg             =>  lv_errmsg                 --ユーザ・エラー・メッセージ
--    );
--    --会計期間情報取得失敗
--    IF ( lv_retcode <> cv_status_normal ) THEN
--      RAISE global_account_period_get_expt;
--    END IF;
--
-- ******** 2010/02/17 1.9 N.Maeda DEL  END  ******** --
    --納品日(FROM)書式チェック
    ld_dlv_date_from := FND_DATE.STRING_TO_DATE( iv_dlv_date_from, cv_yyyy_mm_dd );
    IF ( ld_dlv_date_from IS NULL ) THEN
      lv_check_item         :=  xxccp_common_pkg.get_msg(
        iv_application      =>  cv_xxcos_short_name,
        iv_name             =>  cv_msg_vl_date_from
      );
      RAISE global_format_chk_expt;
    END IF;
    --納品日(TO)書式チェック
    ld_dlv_date_to := FND_DATE.STRING_TO_DATE( iv_dlv_date_to, cv_yyyy_mm_dd );
    IF ( ld_dlv_date_to IS NULL ) THEN
      lv_check_item         :=  xxccp_common_pkg.get_msg(
        iv_application      =>  cv_xxcos_short_name,
        iv_name             =>  cv_msg_vl_date_to
      );
      RAISE global_format_chk_expt;
    END IF;
--
    --納品日(FROM)／納品日(TO)日付逆転チェック
    IF ( ld_dlv_date_from > ld_dlv_date_to ) THEN
      RAISE global_date_rever_chk_expt;
    END IF;
-- ******** 2010/02/17 1.9 N.Maeda MOD START ******** --
--
--    --会計期間(FROM)年月取得
--    ld_acc_date_from_ym := FND_DATE.STRING_TO_DATE( TO_CHAR( ld_acc_date_from, cv_yyyy_mm ), cv_yyyy_mm );
--    --会計期間前月取得
--    ld_acc_date_pre_ym := ADD_MONTHS( ld_acc_date_from_ym, -1 );
--    --納品日(FROM)日付範囲チェック
--    ld_dlv_date_from_ym := FND_DATE.STRING_TO_DATE( TO_CHAR( ld_dlv_date_from, cv_yyyy_mm ), cv_yyyy_mm );
    -- 取得開始可能月-月初日付取得
    ld_dlv_date_from_ym := FND_DATE.STRING_TO_DATE( TO_CHAR( (   add_months( gd_proc_date 
                                                               , ( gn_target_month * (-1) ) 
                                                                           ) 
                                                             )
                                                             , cv_yyyy_mm 
                                                            )
                                                    , cv_yyyy_mm );
    -- 取得開始可能月-最終日取得
    ld_dlv_date_to_ym := LAST_DAY( gd_proc_date );
--    IF ( ld_dlv_date_from_ym >= ld_acc_date_pre_ym AND ld_dlv_date_from_ym <= ld_acc_date_from_ym ) THEN
    IF ( ld_dlv_date_from_ym <= ld_dlv_date_from ) AND ( ld_dlv_date_to_ym >= ld_dlv_date_from )THEN
      NULL;
    ELSE
      lv_check_item         :=  xxccp_common_pkg.get_msg(
        iv_application      =>  cv_xxcos_short_name,
        iv_name             =>  cv_msg_vl_date_from
      );
-- ******** 2010/02/17 1.9 N.Maeda MOD START ******** --
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_date_range_err,
        iv_token_name1        =>  cv_tkn_nm_para_date,
        iv_token_value1       =>  lv_check_item,
        iv_token_name2        =>  cv_tkn_nm_date_min,
        iv_token_value2       =>  TO_CHAR( ld_dlv_date_from_ym, cv_yyyy_mm ),
        iv_token_name3        =>  cv_tkn_nm_date_max,
        iv_token_value3       =>  TO_CHAR( ld_dlv_date_to_ym , cv_yyyy_mm )
      );
      FND_FILE.PUT_LINE( which  => FND_FILE.LOG ,buff   => lv_errmsg );
      gv_date_err_flag := cv_status_error;
--      RAISE global_date_range_chk_expt;
-- ******** 2010/02/17 1.9 N.Maeda MOD  END  ******** --
    END IF;
--    --納品日(TO)日付範囲チェック
--    ld_dlv_date_to_ym := FND_DATE.STRING_TO_DATE( TO_CHAR( ld_dlv_date_to, cv_yyyy_mm ), cv_yyyy_mm );
--    IF ( ld_dlv_date_to_ym >= ld_acc_date_pre_ym AND ld_dlv_date_to_ym <= ld_acc_date_from_ym ) THEN
    -- 取得可能最終日チェック
    IF ( ld_dlv_date_from_ym <= ld_dlv_date_to ) AND ( ld_dlv_date_to_ym >= ld_dlv_date_to )THEN
      NULL;
    ELSE
      lv_check_item         :=  xxccp_common_pkg.get_msg(
        iv_application      =>  cv_xxcos_short_name,
        iv_name             =>  cv_msg_vl_date_to
      );
-- ******** 2010/02/17 1.9 N.Maeda MOD START ******** --
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_date_range_err,
        iv_token_name1        =>  cv_tkn_nm_para_date,
        iv_token_value1       =>  lv_check_item,
        iv_token_name2        =>  cv_tkn_nm_date_min,
        iv_token_value2       =>  TO_CHAR( ld_dlv_date_from_ym, cv_yyyy_mm ),
        iv_token_name3        =>  cv_tkn_nm_date_max,
        iv_token_value3       =>  TO_CHAR( ld_dlv_date_to_ym , cv_yyyy_mm )
      );
      FND_FILE.PUT_LINE( which  => FND_FILE.LOG ,buff   => lv_errmsg );
      gv_date_err_flag := cv_status_error;
--      RAISE global_date_range_chk_expt;
-- ******** 2010/02/17 1.9 N.Maeda MOD  END  ******** --
    END IF;
--
-- ******** 2010/02/17 1.9 N.Maeda MOD  END  ******** --
    --チェックOK
    od_dlv_date_from := ld_dlv_date_from;
    od_dlv_date_to   := ld_dlv_date_to;
--
  EXCEPTION
-- ******** 2010/02/17 1.9 N.Maeda DEL START ******** --
--    -- *** 会計期間区分取得例外ハンドラ ***
--    WHEN global_acc_period_cls_get_expt THEN
--      ov_errmsg               :=  xxccp_common_pkg.get_msg(
--        iv_application        =>  cv_xxcos_short_name,
--        iv_name               =>  cv_msg_acc_cls_get_err,
--        iv_token_name1        =>  cv_tkn_nm_account,
--        iv_token_value1       =>  cv_msg_vl_acc_cls_ar,
--        iv_token_name2        =>  cv_tkn_nm_acc_type,
--        iv_token_value2       =>  cv_type_acc
--      );
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** 会計期間取得例外ハンドラ ***
--    WHEN global_account_period_get_expt THEN
--      ov_errmsg               :=  xxccp_common_pkg.get_msg(
--        iv_application        =>  cv_xxcos_short_name,
--        iv_name               =>  cv_msg_acc_perd_get_err,
--        iv_token_name1        =>  cv_tkn_nm_account,
--        iv_token_value1       =>  cv_msg_vl_acc_cls_ar
--      );
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
--      ov_retcode := cv_status_error;
-- ******** 2010/02/17 1.9 N.Maeda DEL  END  ******** --
    -- *** 書式チェック例外ハンドラ ***
    WHEN global_format_chk_expt THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_format_check_err,
        iv_token_name1        =>  cv_tkn_nm_para_date,
        iv_token_value1       =>  lv_check_item
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 日付逆転チェック例外ハンドラ ***
    WHEN global_date_rever_chk_expt THEN
      lv_check_item1          :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_date_from
      );
      lv_check_item2          :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_date_to
      );
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_date_rever_err,
        iv_token_name1        =>  cv_tkn_nm_date_from,
        iv_token_value1       =>  lv_check_item1,
        iv_token_name2        =>  cv_tkn_nm_date_to,
        iv_token_value2       =>  lv_check_item2
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--    -- *** 日付範囲チェック例外ハンドラ ***
--    WHEN global_date_range_chk_expt THEN
--      ov_errmsg               :=  xxccp_common_pkg.get_msg(
--        iv_application        =>  cv_xxcos_short_name,
--        iv_name               =>  cv_msg_date_range_err,
--        iv_token_name1        =>  cv_tkn_nm_para_date,
--        iv_token_value1       =>  lv_check_item,
--        iv_token_name2        =>  cv_tkn_nm_date_min,
--        iv_token_value2       =>  TO_CHAR( ld_acc_date_pre_ym, cv_yyyy_mm ),
--        iv_token_name3        =>  cv_tkn_nm_date_max,
--        iv_token_value3       =>  TO_CHAR( ld_acc_date_from_ym, cv_yyyy_mm )
--      );
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
--      ov_retcode := cv_status_error;
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
   * Procedure Name   : get_data
   * Description      : 処理対象データ取得(A-3)
   ***********************************************************************************/
  PROCEDURE get_data(
    iv_sale_base_code   IN  VARCHAR2,     --   売上拠点コード
    id_dlv_date_from    IN  DATE,         --   納品日(FROM)
    id_dlv_date_to      IN  DATE,         --   納品日(TO)
    iv_sale_emp_code    IN  VARCHAR2,     --   営業担当者コード
    iv_ship_to_code     IN  VARCHAR2,     --   出荷先コード
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_data'; -- プログラム名
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
    lv_tkn_vl_table_name      VARCHAR2(100);
    ln_idx                    NUMBER;                                 --メインループカウント
    ln_err_item_idx           NUMBER;                                 --営業原価未設定ループカウント
    lt_record_id              xxcos_rep_cost_div_list.record_id%TYPE; --レコードID
    lb_ext_flg                BOOLEAN;                                --エラー品目コード設定済フラグ
--
    -- *** ローカル・カーソル ***
    CURSOR data_cur
    IS
      --作成元が受注系機能のSQL
      SELECT  
-- 2009/09/02 Ver.1.6 Add Start
        /*+
-- 2010/01/18 Ver1.8 Del Start
--          LEADING ( lbiv.obc.fu )
--          INDEX   ( lbiv.obc.fu fnd_user_u1)
--          USE_NL  ( lbiv.obc.papf )
--          INDEX   ( lbiv.obc.papf per_people_f_pk)
--          USE_NL  ( lbiv.obc.ppt )
--          INDEX   ( lbiv.obc.ppt per_person_types_pk)
--          USE_NL  ( lbiv.obc.paaf )
--          INDEX   ( lbiv.obc.paaf per_assignments_f_n12)
--          USE_NL  ( lbiv.xca )
--          INDEX   ( lbiv.xca xxcmm_cust_accounts_pk )
-- 2010/01/18 Ver1.8 Del End
          USE_NL  ( seh )
          INDEX   ( seh xxcos_sales_exp_headers_n01 )
        */
-- 2009/09/02 Ver.1.6 Add End
        seh.sales_base_code               base_code,        --売上拠点コード
-- 2010/01/18 Ver1.8 Mod Start
--        lbiv.base_name                    base_name,        --売上拠点名
        gv_base_name                      base_name,        --売上拠点名
-- 2010/01/18 Ver1.8 Mod End
        seh.results_employee_code         emp_code,         --営業担当者コード
/* 2009/04/21 Ver1.2 Mod Start */
--        riv.employee_name                 emp_name,         --営業担当者名
        papf.per_information18 || ' ' || papf.per_information19
                                          emp_name,         --営業担当者名
/* 2009/04/21 Ver1.2 Mod End   */
        seh.ship_to_customer_code         ship_to_cd,       --出荷先コード
        hp.party_name                     ship_to_nm,       --出荷先名
        seh.delivery_date                 dlv_date,         --納品日
        seh.dlv_invoice_number            dlv_slip_num,     --納品伝票番号
        sel.item_code                     item_cd,          --品目コード
        ximb.item_short_name              item_nm,          --品目名
        sel.standard_qty                  quantity,         --数量
        sel.standard_uom_code             unit,             --単位
        sel.standard_unit_price_excluded  dlv_price,        --納品単価
        sel.business_cost                 biz_cost          --営業原価
      FROM    
        xxcos_sales_exp_headers seh,                        --販売実績ヘッダ
        xxcos_sales_exp_lines   sel,                        --販売実績明細
        oe_order_sources        oos,                        --受注ソースマスタ
-- 2010/01/18 Ver1.8 Del Start
--        xxcos_login_base_info_v lbiv,                       --ログインユーザ拠点ビュー
-- 2010/01/18 Ver1.8 Del End
/* 2009/04/21 Ver1.2 Mod Start */
--        xxcos_rs_info_v         riv,                        --営業員情報ビュー
        per_all_people_f        papf,                       --従業員マスタ
/* 2009/04/21 Ver1.2 Mod End   */
        hz_cust_accounts        hca,                        --顧客マスタ
        hz_parties              hp,                         --パーティ
        mtl_system_items_b      msib,                       --Disc品目マスタ
        ic_item_mst_b           iimb,                       --OPM品目マスタ
        xxcmn_item_mst_b        ximb                        --OPM品目アドオン
      WHERE seh.sales_exp_header_id = sel.sales_exp_header_id                         --販売実績ヘッダID
      AND   seh.order_source_id     = oos.order_source_id                             --受注ソースID
      --受注ソースのクイック参照
      AND   EXISTS(
-- ******** 2009/08/11 1.5 N.Maeda MOD START *********** --
              SELECT  'Y'                         ext_flg
              FROM    fnd_lookup_values           look_val
              WHERE   look_val.language           = cv_lang
              AND     look_val.lookup_type        = cv_ord_src_type
              AND     look_val.lookup_code        LIKE cv_ord_src_code
              AND     look_val.meaning            = oos.name
              AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
              AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
              AND     look_val.enabled_flag       = ct_enabled_flg_y
--
--              SELECT  'Y'                         ext_flg
--              FROM    fnd_lookup_values           look_val,
--                      fnd_lookup_types_tl         types_tl,
--                      fnd_lookup_types            types,
--                      fnd_application_tl          appl,
--                      fnd_application             app
--              WHERE   appl.application_id         = types.application_id
--              AND     app.application_id          = appl.application_id
--              AND     types_tl.lookup_type        = look_val.lookup_type
--              AND     types.lookup_type           = types_tl.lookup_type
--              AND     types.security_group_id     = types_tl.security_group_id
--              AND     types.view_application_id   = types_tl.view_application_id
--              AND     types_tl.language           = cv_lang
--              AND     look_val.language           = cv_lang
--              AND     appl.language               = cv_lang
--              AND     app.application_short_name  = cv_xxcos_short_name
--              AND     look_val.lookup_type        = cv_ord_src_type
--              AND     look_val.lookup_code        LIKE cv_ord_src_code
--              AND     look_val.meaning            = oos.name
--              AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
--              AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
--              AND     look_val.enabled_flag       = ct_enabled_flg_y
-- ******** 2009/08/11 1.5 N.Maeda MOD END *********** --
                  )
      --作成元区分のクイック参照
      AND   EXISTS(
-- ******** 2009/08/11 1.5 N.Maeda MOD START *********** --
              SELECT  'Y'                         ext_flg
              FROM    fnd_lookup_values           look_val
              WHERE   look_val.language           = cv_lang
              AND     look_val.lookup_type        = cv_mk_org_type
              AND     look_val.lookup_code        LIKE cv_mk_org_code1
              AND     look_val.meaning            = seh.create_class
              AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
              AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
              AND     look_val.enabled_flag       = ct_enabled_flg_y
--
--              SELECT  'Y'                         ext_flg
--              FROM    fnd_lookup_values           look_val,
--                      fnd_lookup_types_tl         types_tl,
--                      fnd_lookup_types            types,
--                      fnd_application_tl          appl,
--                      fnd_application             app
--              WHERE   appl.application_id         = types.application_id
--              AND     app.application_id          = appl.application_id
--              AND     types_tl.lookup_type        = look_val.lookup_type
--              AND     types.lookup_type           = types_tl.lookup_type
--              AND     types.security_group_id     = types_tl.security_group_id
--              AND     types.view_application_id   = types_tl.view_application_id
--              AND     types_tl.language           = cv_lang
--              AND     look_val.language           = cv_lang
--              AND     appl.language               = cv_lang
--              AND     app.application_short_name  = cv_xxcos_short_name
--              AND     look_val.lookup_type        = cv_mk_org_type
--              AND     look_val.lookup_code        LIKE cv_mk_org_code1
--              AND     look_val.meaning            = seh.create_class
--              AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
--              AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
--              AND     look_val.enabled_flag       = ct_enabled_flg_y
-- ******** 2009/08/11 1.5 N.Maeda MOD END *********** --
                  )
      --売上区分のクイック参照
      AND   NOT EXISTS(
-- ******** 2009/08/11 1.5 N.Maeda MOD START *********** --
              SELECT  'Y'                         ext_flg
              FROM    fnd_lookup_values           look_val
              WHERE   look_val.language           = cv_lang
              AND     look_val.lookup_type        = cv_sl_cls_type
              AND     look_val.lookup_code        LIKE cv_sl_cls_code1
              AND     look_val.meaning            = sel.sales_class
              AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
              AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
              AND     look_val.enabled_flag       = ct_enabled_flg_y
--
--              SELECT  'Y'                         ext_flg
--              FROM    fnd_lookup_values           look_val,
--                      fnd_lookup_types_tl         types_tl,
--                      fnd_lookup_types            types,
--                      fnd_application_tl          appl,
--                      fnd_application             app
--              WHERE   appl.application_id         = types.application_id
--              AND     app.application_id          = appl.application_id
--              AND     types_tl.lookup_type        = look_val.lookup_type
--              AND     types.lookup_type           = types_tl.lookup_type
--              AND     types.security_group_id     = types_tl.security_group_id
--              AND     types.view_application_id   = types_tl.view_application_id
--              AND     types_tl.language           = cv_lang
--              AND     look_val.language           = cv_lang
--              AND     appl.language               = cv_lang
--              AND     app.application_short_name  = cv_xxcos_short_name
--              AND     look_val.lookup_type        = cv_sl_cls_type
--              AND     look_val.lookup_code        LIKE cv_sl_cls_code1
--              AND     look_val.meaning            = sel.sales_class
--              AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
--              AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
--              AND     look_val.enabled_flag       = ct_enabled_flg_y
-- ******** 2009/08/11 1.5 N.Maeda MOD END *********** --
                  )
      --非在庫品目コードのクイック参照
      AND   NOT EXISTS(
-- ******** 2009/08/11 1.5 N.Maeda MOD START *********** --
              SELECT  'Y'                         ext_flg
              FROM    fnd_lookup_values           look_val
              WHERE   look_val.language           = cv_lang
              AND     look_val.lookup_type        = cv_no_inv_item_type
              AND     look_val.lookup_code        = sel.item_code
              AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
              AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
              AND     look_val.enabled_flag       = ct_enabled_flg_y
--
--              SELECT  'Y'                         ext_flg
--              FROM    fnd_lookup_values           look_val,
--                      fnd_lookup_types_tl         types_tl,
--                      fnd_lookup_types            types,
--                      fnd_application_tl          appl,
--                      fnd_application             app
--              WHERE   appl.application_id         = types.application_id
--              AND     app.application_id          = appl.application_id
--              AND     types_tl.lookup_type        = look_val.lookup_type
--              AND     types.lookup_type           = types_tl.lookup_type
--              AND     types.security_group_id     = types_tl.security_group_id
--              AND     types.view_application_id   = types_tl.view_application_id
--              AND     types_tl.language           = cv_lang
--              AND     look_val.language           = cv_lang
--              AND     appl.language               = cv_lang
--              AND     app.application_short_name  = cv_xxcos_short_name
--              AND     look_val.lookup_type        = cv_no_inv_item_type
--              AND     look_val.lookup_code        = sel.item_code
--              AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
--              AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
--              AND     look_val.enabled_flag       = ct_enabled_flg_y
-- ******** 2009/08/11 1.5 N.Maeda MOD END *********** --
                      )
      --売上拠点コードを絞込み
-- 2010/01/18 Ver1.8 Mod Start
      AND   seh.sales_base_code                   = gv_base_code
---- ******** 2009/08/13 1.5 N.Maeda MOD START *********** --
---- 2009/09/02 Ver.1.6 Mod Start
--      AND   ( ( iv_sale_base_code IS NULL )
----      AND   ( ( iv_sale_base_code IS NULL AND EXISTS( SELECT 'Y'
----                                                      FROM   xxcos_login_base_info_v lbiv1
----                                                      WHERE  seh.sales_base_code = lbiv1.base_code ) )
---- 2009/09/02 Ver.1.6 Mod End
--        OR ( iv_sale_base_code IS NOT NULL AND iv_sale_base_code = seh.sales_base_code ) )
----      AND   1 = (
----                 CASE
----                  WHEN iv_sale_base_code IS NULL AND EXISTS( SELECT 'Y' 
----                                                             FROM   xxcos_login_base_info_v lbiv1 
----                                                             WHERE  seh.sales_base_code = lbiv1.base_code 
----                                                           ) THEN
----                    1
----                  WHEN iv_sale_base_code IS NOT NULL AND iv_sale_base_code = seh.sales_base_code THEN
----                    1
----                  ELSE
----                    0
----                 END
----                )
---- ******** 2009/08/13 1.5 N.Maeda MOD END *********** --
-- 2010/01/18 Ver1.8 Mod End
      --納品日を絞込み
      AND   seh.delivery_date >= id_dlv_date_from 
      AND   seh.delivery_date <= id_dlv_date_to
      --営業担当を絞込み
-- ******** 2009/08/13 1.5 N.Maeda MOD START *********** --
      AND  ( ( iv_sale_emp_code IS NULL )
             OR ( iv_sale_emp_code IS NOT NULL AND iv_sale_emp_code = seh.results_employee_code ) )
--      AND   1 = (
--                 CASE
--/* 2009/04/21 Ver1.2 Mod Start */
----                  WHEN iv_sale_emp_code IS NULL AND EXISTS( SELECT 'Y' 
----                                                            FROM   xxcos_rs_info_v riv1 
----                                                            WHERE  seh.sales_base_code       = riv1.base_code 
----                                                            AND    seh.results_employee_code = riv1.employee_number
----                                                            AND    seh.delivery_date >= riv1.effective_start_date
----                                                            AND    seh.delivery_date <= riv1.effective_end_date
----                                                          ) THEN
--                  WHEN iv_sale_emp_code IS NULL THEN
--/* 2009/04/21 Ver1.2 Mod End   */
--                    1
--                  WHEN iv_sale_emp_code IS NOT NULL AND iv_sale_emp_code = seh.results_employee_code THEN
--                    1
--                  ELSE
--                    0
--                 END
--                )
-- ******** 2009/08/13 1.5 N.Maeda MOD END *********** --
      --出荷先を絞込み
-- ******** 2009/08/13 1.5 N.Maeda MOD START *********** --
      AND ( ( iv_ship_to_code IS NULL AND EXISTS( SELECT 'Y' 
                                                  FROM   hz_cust_accounts    hca1,
                                                         xxcmm_cust_accounts xca1,
                                                         fnd_lookup_values   look_val
                                                  WHERE  hca1.cust_account_id  = xca1.customer_id 
                                                  AND    seh.sales_base_code   = xca1.sale_base_code
                                                  AND    look_val.language     = cv_lang
                                                  AND    look_val.lookup_type  = cv_cus_cls_type
                                                  AND    look_val.lookup_code  LIKE cv_cus_cls_code
                                                  AND    look_val.meaning      = hca1.customer_class_code
                                                  AND    gd_proc_date >= NVL( look_val.start_date_active, gd_min_date )
                                                  AND    gd_proc_date <= NVL( look_val.end_date_active, gd_max_date )
                                                  AND    look_val.enabled_flag = ct_enabled_flg_y
                                                  AND    seh.ship_to_customer_code = hca1.account_number ) )
            OR ( iv_ship_to_code IS NOT NULL AND iv_ship_to_code = seh.ship_to_customer_code ) )
--      AND   1 = (
--                 CASE
--                  WHEN iv_ship_to_code IS NULL 
--                    AND EXISTS( 
--                               SELECT 'Y' 
--                               FROM   hz_cust_accounts hca1,
--                                      xxcmm_cust_accounts xca1
--                               WHERE  hca1.cust_account_id  = xca1.customer_id 
--                               AND    seh.sales_base_code   = xca1.sale_base_code
--                               AND    EXISTS (
---- ******** 2009/08/11 1.5 N.Maeda MOD START *********** --
--                                             SELECT  'X'                         
--                                             FROM    fnd_lookup_values           look_val
--                                             WHERE   look_val.language           = cv_lang
--                                             AND     look_val.lookup_type        = cv_cus_cls_type
--                                             AND     look_val.lookup_code        LIKE cv_cus_cls_code
--                                             AND     look_val.meaning            = hca1.customer_class_code
--                                             AND     gd_proc_date >= NVL( look_val.start_date_active, gd_min_date )
--                                             AND     gd_proc_date <= NVL( look_val.end_date_active, gd_max_date )
--                                             AND     look_val.enabled_flag       = ct_enabled_flg_y
----
----                                             SELECT  'X'                         
----                                             FROM    fnd_lookup_values           look_val,
----                                                     fnd_lookup_types_tl         types_tl,
----                                                     fnd_lookup_types            types,
----                                                     fnd_application_tl          appl,
----                                                     fnd_application             app
----                                             WHERE   appl.application_id         = types.application_id
----                                             AND     app.application_id          = appl.application_id
----                                             AND     types_tl.lookup_type        = look_val.lookup_type
----                                             AND     types.lookup_type           = types_tl.lookup_type
----                                             AND     types.security_group_id     = types_tl.security_group_id
----                                             AND     types.view_application_id   = types_tl.view_application_id
----                                             AND     types_tl.language           = cv_lang
----                                             AND     look_val.language           = cv_lang
----                                             AND     appl.language               = cv_lang
----                                             AND     app.application_short_name  = cv_xxcos_short_name
----                                             AND     look_val.lookup_type        = cv_cus_cls_type
----                                             AND     look_val.lookup_code        LIKE cv_cus_cls_code
----                                             AND     look_val.meaning            = hca1.customer_class_code
----                                             AND     gd_proc_date >= NVL( look_val.start_date_active, gd_min_date )
----                                             AND     gd_proc_date <= NVL( look_val.end_date_active, gd_max_date )
----                                             AND     look_val.enabled_flag       = ct_enabled_flg_y
---- ******** 2009/08/11 1.5 N.Maeda MOD END *********** --
--                                             )
--                               AND    seh.ship_to_customer_code = hca1.account_number
--                              ) THEN
--                    1
--                  WHEN iv_ship_to_code IS NOT NULL AND iv_ship_to_code = seh.ship_to_customer_code THEN
--                    1
--                  ELSE
--                    0
--                 END
--                )
-- ******** 2009/08/13 1.5 N.Maeda MOD END *********** --
            --営業原価 IS NULL OR 納品単価 < 営業原価
      AND   ( sel.business_cost IS NULL OR NVL( sel.standard_unit_price_excluded, 0 ) < sel.business_cost )
-- 2010/01/18 Ver1.8 Del Start
--      AND   seh.sales_base_code       = lbiv.base_code            --売上拠点コード
-- 2010/01/18 Ver1.8 Del End
/* 2009/04/21 Ver1.2 Mod Start */
--      AND   seh.sales_base_code       = riv.base_code
--      AND   seh.results_employee_code = riv.employee_number       --営業担当者コード
--      AND   seh.delivery_date         >= riv.effective_start_date --納品日>=営業員情報ビュー.適用開始日
--      AND   seh.delivery_date         <= riv.effective_end_date   --納品日<=営業員情報ビュー.適用終了日
      AND   seh.results_employee_code = papf.employee_number       --従業員コード
      AND   seh.delivery_date         >= papf.effective_start_date --納品日>=従業員マスタ.適用開始日
      AND   seh.delivery_date         <= papf.effective_end_date   --納品日<=従業員マスタ.適用終了日
/* 2009/04/21 Ver1.2 Mod End   */
      AND   seh.ship_to_customer_code = hca.account_number        --出荷先コード
      AND   hca.party_id              = hp.party_id               --パーティーID
      AND   sel.item_code             = msib.segment1             --品目コード
      AND   msib.organization_id      = gt_org_id                 --在庫組織ID
      AND   msib.segment1             = iimb.item_no              --OPM品目コード
      AND   iimb.item_id              = ximb.item_id              --OPMアドオン品目ID
      AND   seh.delivery_date         >= ximb.start_date_active   --納品日>=OPM品目アドオン.適用開始日
      AND   seh.delivery_date         <= ximb.end_date_active     --納品日<=OPM品目アドオン.適用終了日
      UNION ALL
      --作成元が消化計算の商品別売上計算（百貨店・インショップ／専門店・直営）機能のSQL
      SELECT  
-- 2009/09/02 Ver.1.6 Add Start
        /*+
-- 2010/01/18 Ver1.8 Del Start
--          LEADING ( lbiv.obc.fu )
--          INDEX   ( lbiv.obc.fu fnd_user_u1)
--          USE_NL  ( lbiv.obc.papf )
--          INDEX   ( lbiv.obc.papf per_people_f_pk)
--          USE_NL  ( lbiv.obc.ppt )
--          INDEX   ( lbiv.obc.ppt per_person_types_pk)
--          USE_NL  ( lbiv.obc.paaf )
--          INDEX   ( lbiv.obc.paaf per_assignments_f_n12)
--          USE_NL  ( lbiv.xca )
--          INDEX   ( lbiv.xca xxcmm_cust_accounts_pk )
-- 2010/01/18 Ver1.8 Del End
          USE_NL  ( seh )
          INDEX   ( seh xxcos_sales_exp_headers_n01 )
        */
-- 2009/09/02 Ver.1.6 Add End
        seh.sales_base_code               base_code,        --売上拠点コード
-- 2010/01/18 Ver1.8 Mod Start
--        lbiv.base_name                    base_name,        --売上拠点名
        gv_base_name                      base_name,        --売上拠点名
-- 2010/01/18 Ver1.8 Mod End
        seh.results_employee_code         emp_code,         --営業担当者コード
/* 2009/04/21 Ver1.2 Mod Start */
--        riv.employee_name                 emp_name,         --営業担当者名
        papf.per_information18 || ' ' || papf.per_information19
                                          emp_name,         --営業担当者名
/* 2009/04/21 Ver1.2 Mod End   */
        seh.ship_to_customer_code         ship_to_cd,       --出荷先コード
        hp.party_name                     ship_to_nm,       --出荷先名
        seh.delivery_date                 dlv_date,         --納品日
        seh.dlv_invoice_number            dlv_slip_num,     --納品伝票番号
        sel.item_code                     item_cd,          --品目コード
        ximb.item_short_name              item_nm,          --品目名
        sel.standard_qty                  quantity,         --数量
        sel.standard_uom_code             unit,             --単位
        sel.standard_unit_price_excluded  dlv_price,        --納品単価
        sel.business_cost                 biz_cost          --営業原価
      FROM    
        xxcos_sales_exp_headers seh,                        --販売実績ヘッダ
        xxcos_sales_exp_lines   sel,                        --販売実績明細
-- 2010/01/18 Ver1.8 Del Start
--        xxcos_login_base_info_v lbiv,                       --ログインユーザ拠点ビュー
-- 2010/01/18 Ver1.8 Del End
/* 2009/04/21 Ver1.2 Mod Start */
--        xxcos_rs_info_v         riv,                        --営業員情報ビュー
        per_all_people_f        papf,                       --従業員マスタ
/* 2009/04/21 Ver1.2 Mod End   */
        hz_cust_accounts        hca,                        --顧客マスタ
        hz_parties              hp,                         --パーティ
        mtl_system_items_b      msib,                       --Disc品目マスタ
        ic_item_mst_b           iimb,                       --OPM品目マスタ
        xxcmn_item_mst_b        ximb                        --OPM品目アドオン
      WHERE seh.sales_exp_header_id = sel.sales_exp_header_id                         --販売実績ヘッダID
      --作成元区分のクイック参照
      AND   EXISTS(
-- ******** 2009/08/11 1.5 N.Maeda MOD START *********** --
              SELECT  'Y'                         ext_flg
              FROM    fnd_lookup_values           look_val
              WHERE   look_val.language           = cv_lang
              AND     look_val.lookup_type        = cv_mk_org_type
              AND     look_val.lookup_code        LIKE cv_mk_org_code2
              AND     look_val.meaning            = seh.create_class
              AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
              AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
              AND     look_val.enabled_flag       = ct_enabled_flg_y
--
--              SELECT  'Y'                         ext_flg
--              FROM    fnd_lookup_values           look_val,
--                      fnd_lookup_types_tl         types_tl,
--                      fnd_lookup_types            types,
--                      fnd_application_tl          appl,
--                      fnd_application             app
--              WHERE   appl.application_id         = types.application_id
--              AND     app.application_id          = appl.application_id
--              AND     types_tl.lookup_type        = look_val.lookup_type
--              AND     types.lookup_type           = types_tl.lookup_type
--              AND     types.security_group_id     = types_tl.security_group_id
--              AND     types.view_application_id   = types_tl.view_application_id
--              AND     types_tl.language           = cv_lang
--              AND     look_val.language           = cv_lang
--              AND     appl.language               = cv_lang
--              AND     app.application_short_name  = cv_xxcos_short_name
--              AND     look_val.lookup_type        = cv_mk_org_type
--              AND     look_val.lookup_code        LIKE cv_mk_org_code2
--              AND     look_val.meaning            = seh.create_class
--              AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
--              AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
--              AND     look_val.enabled_flag       = ct_enabled_flg_y
-- ******** 2009/08/11 1.5 N.Maeda MOD END *********** --
                  )
      --売上区分のクイック参照
      AND   EXISTS(
-- ******** 2009/08/11 1.5 N.Maeda MOD START *********** --
              SELECT  'Y'                         ext_flg
              FROM    fnd_lookup_values           look_val
              WHERE   look_val.language           = cv_lang
              AND     look_val.lookup_type        = cv_sl_cls_type
              AND     look_val.lookup_code        LIKE cv_sl_cls_code2
              AND     look_val.meaning            = sel.sales_class
              AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
              AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
              AND     look_val.enabled_flag       = ct_enabled_flg_y
--
--              SELECT  'Y'                         ext_flg
--              FROM    fnd_lookup_values           look_val,
--                      fnd_lookup_types_tl         types_tl,
--                      fnd_lookup_types            types,
--                      fnd_application_tl          appl,
--                      fnd_application             app
--              WHERE   appl.application_id         = types.application_id
--              AND     app.application_id          = appl.application_id
--              AND     types_tl.lookup_type        = look_val.lookup_type
--              AND     types.lookup_type           = types_tl.lookup_type
--              AND     types.security_group_id     = types_tl.security_group_id
--              AND     types.view_application_id   = types_tl.view_application_id
--              AND     types_tl.language           = cv_lang
--              AND     look_val.language           = cv_lang
--              AND     appl.language               = cv_lang
--              AND     app.application_short_name  = cv_xxcos_short_name
--              AND     look_val.lookup_type        = cv_sl_cls_type
--              AND     look_val.lookup_code        LIKE cv_sl_cls_code2
--              AND     look_val.meaning            = sel.sales_class
--              AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
--              AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
--              AND     look_val.enabled_flag       = ct_enabled_flg_y
-- ******** 2009/08/11 1.5 N.Maeda MOD END *********** --
                  )
      --非在庫品目コードのクイック参照
      AND   NOT EXISTS(
-- ******** 2009/08/11 1.5 N.Maeda MOD START *********** --
              SELECT  'Y'                         ext_flg
              FROM    fnd_lookup_values           look_val
              WHERE   look_val.language           = cv_lang
              AND     look_val.lookup_type        = cv_no_inv_item_type
              AND     look_val.lookup_code        = sel.item_code
              AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
              AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
              AND     look_val.enabled_flag       = ct_enabled_flg_y
--
--              SELECT  'Y'                         ext_flg
--              FROM    fnd_lookup_values           look_val,
--                      fnd_lookup_types_tl         types_tl,
--                      fnd_lookup_types            types,
--                      fnd_application_tl          appl,
--                      fnd_application             app
--              WHERE   appl.application_id         = types.application_id
--              AND     app.application_id          = appl.application_id
--              AND     types_tl.lookup_type        = look_val.lookup_type
--              AND     types.lookup_type           = types_tl.lookup_type
--              AND     types.security_group_id     = types_tl.security_group_id
--              AND     types.view_application_id   = types_tl.view_application_id
--              AND     types_tl.language           = cv_lang
--              AND     look_val.language           = cv_lang
--              AND     appl.language               = cv_lang
--              AND     app.application_short_name  = cv_xxcos_short_name
--              AND     look_val.lookup_type        = cv_no_inv_item_type
--              AND     look_val.lookup_code        = sel.item_code
--              AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
--              AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
--              AND     look_val.enabled_flag       = ct_enabled_flg_y
-- ******** 2009/08/11 1.5 N.Maeda MOD END *********** --
                      )
      --売上拠点コードを絞込み
-- 2010/01/18 Ver1.8 Mod Start
      AND   seh.sales_base_code                   = gv_base_code
---- ******** 2009/08/13 1.5 N.Maeda MOD START *********** --
---- 2009/09/02 Ver.1.6 Mod Start
--      AND  ( ( iv_sale_base_code IS NULL )
----      AND  ( ( iv_sale_base_code IS NULL AND EXISTS( SELECT 'Y' 
----                                                     FROM   xxcos_login_base_info_v lbiv1 
----                                                     WHERE  seh.sales_base_code = lbiv1.base_code ) )
---- 2009/09/02 Ver.1.6 Mod End
--             OR ( iv_sale_base_code IS NOT NULL AND iv_sale_base_code = seh.sales_base_code ) )
----      AND   1 = (
----                 CASE
----                  WHEN iv_sale_base_code IS NULL AND EXISTS( SELECT 'Y' 
----                                                             FROM   xxcos_login_base_info_v lbiv1 
----                                                             WHERE  seh.sales_base_code = lbiv1.base_code 
----                                                           ) THEN
----                    1
----                  WHEN iv_sale_base_code IS NOT NULL AND iv_sale_base_code = seh.sales_base_code THEN
----                    1
----                  ELSE
----                    0
----                 END
----                )
---- ******** 2009/08/13 1.5 N.Maeda MOD END *********** --
-- 2010/01/18 Ver1.8 Mod End
      --納品日を絞込み
      AND   seh.delivery_date >= id_dlv_date_from 
      AND   seh.delivery_date <= id_dlv_date_to
      --営業担当を絞込み
-- ******** 2009/08/13 1.5 N.Maeda MOD START *********** --
      AND   ( ( iv_sale_emp_code IS NULL )
              OR ( iv_sale_emp_code IS NOT NULL AND iv_sale_emp_code = seh.results_employee_code ) )
--      AND   1 = (
--                 CASE
--/* 2009/04/21 Ver1.2 Mod Start */
----                  WHEN iv_sale_emp_code IS NULL AND EXISTS( SELECT 'Y' 
----                                                            FROM   xxcos_rs_info_v riv1 
----                                                            WHERE  seh.sales_base_code       = riv1.base_code 
----                                                            AND    seh.results_employee_code = riv1.employee_number
----                                                            AND    seh.delivery_date >= riv1.effective_start_date
----                                                           AND    seh.delivery_date <= riv1.effective_end_date
----                                                          ) THEN
--                  WHEN iv_sale_emp_code IS NULL THEN
--/* 2009/04/21 Ver1.2 Mod End   */
--                    1
--                  WHEN iv_sale_emp_code IS NOT NULL AND iv_sale_emp_code = seh.results_employee_code THEN
--                    1
--                  ELSE
--                    0
--                 END
--                )
-- ******** 2009/08/13 1.5 N.Maeda MOD END *********** --
      --出荷先を絞込み
-- ******** 2009/08/13 1.5 N.Maeda MOD START *********** --
      AND  ( ( iv_ship_to_code IS NULL AND EXISTS( SELECT 'Y' 
                                                   FROM   hz_cust_accounts    hca1,
                                                          xxcmm_cust_accounts xca1,
                                                          fnd_lookup_values   look_val
                                                   WHERE  hca1.cust_account_id  = xca1.customer_id 
                                                   AND    seh.sales_base_code   = xca1.sale_base_code
                                                   AND    look_val.language     = cv_lang
                                                   AND    look_val.lookup_type = cv_cus_cls_type
                                                   AND    look_val.lookup_code LIKE cv_cus_cls_code
                                                   AND    look_val.meaning     = hca1.customer_class_code
                                                   AND    gd_proc_date >= NVL( look_val.start_date_active, gd_min_date )
                                                   AND    gd_proc_date <= NVL( look_val.end_date_active, gd_max_date )
                                                   AND    look_val.enabled_flag = ct_enabled_flg_y
                                                   AND    seh.ship_to_customer_code = hca1.account_number ) )
             OR ( iv_ship_to_code IS NOT NULL AND iv_ship_to_code = seh.ship_to_customer_code ) )
--      AND   1 = (
--                 CASE
--                  WHEN iv_ship_to_code IS NULL 
--                    AND EXISTS( 
--                               SELECT 'Y' 
--                               FROM   hz_cust_accounts hca1,
--                                      xxcmm_cust_accounts xca1
--                               WHERE  hca1.cust_account_id  = xca1.customer_id 
--                               AND    seh.sales_base_code   = xca1.sale_base_code
--                               AND    EXISTS (
---- ******** 2009/08/11 1.5 N.Maeda MOD START *********** --
--                                             SELECT  'X'                         
--                                             FROM    fnd_lookup_values           look_val
--                                             WHERE   look_val.language           = cv_lang
--                                             AND     look_val.lookup_type        = cv_cus_cls_type
--                                             AND     look_val.lookup_code        LIKE cv_cus_cls_code
--                                             AND     look_val.meaning            = hca1.customer_class_code
--                                             AND     gd_proc_date >= NVL( look_val.start_date_active, gd_min_date )
--                                             AND     gd_proc_date <= NVL( look_val.end_date_active, gd_max_date )
--                                             AND     look_val.enabled_flag       = ct_enabled_flg_y
----
----                                             SELECT  'X'                         
----                                             FROM    fnd_lookup_values           look_val,
----                                                     fnd_lookup_types_tl         types_tl,
----                                                     fnd_lookup_types            types,
----                                                     fnd_application_tl          appl,
----                                                     fnd_application             app
----                                             WHERE   appl.application_id         = types.application_id
----                                             AND     app.application_id          = appl.application_id
----                                             AND     types_tl.lookup_type        = look_val.lookup_type
----                                             AND     types.lookup_type           = types_tl.lookup_type
----                                             AND     types.security_group_id     = types_tl.security_group_id
----                                             AND     types.view_application_id   = types_tl.view_application_id
----                                             AND     types_tl.language           = cv_lang
----                                             AND     look_val.language           = cv_lang
----                                             AND     appl.language               = cv_lang
----                                             AND     app.application_short_name  = cv_xxcos_short_name
----                                             AND     look_val.lookup_type        = cv_cus_cls_type
----                                             AND     look_val.lookup_code        LIKE cv_cus_cls_code
----                                             AND     look_val.meaning            = hca1.customer_class_code
----                                             AND     gd_proc_date >= NVL( look_val.start_date_active, gd_min_date )
----                                             AND     gd_proc_date <= NVL( look_val.end_date_active, gd_max_date )
----                                             AND     look_val.enabled_flag       = ct_enabled_flg_y
---- ******** 2009/08/11 1.5 N.Maeda MOD END *********** --
--                                             )
--                               AND    seh.ship_to_customer_code = hca1.account_number
--                              ) THEN
--                    1
--                  WHEN iv_ship_to_code IS NOT NULL AND iv_ship_to_code = seh.ship_to_customer_code THEN
--                    1
--                  ELSE
--                    0
--                 END
--                )
-- ******** 2009/08/13 1.5 N.Maeda MOD END *********** --
            --営業原価 IS NULL OR 納品単価 < 営業原価
      AND   ( sel.business_cost IS NULL OR NVL( sel.standard_unit_price_excluded, 0 ) < sel.business_cost )
-- 2010/01/18 Ver1.8 Del Start
--      AND   seh.sales_base_code       = lbiv.base_code            --売上拠点コード
-- 2010/01/18 Ver1.8 Del End
/* 2009/04/21 Ver1.2 Mod Start */
--      AND   seh.sales_base_code       = riv.base_code
--      AND   seh.results_employee_code = riv.employee_number       --営業担当者コード
--      AND   seh.delivery_date         >= riv.effective_start_date --納品日>=営業員情報ビュー.適用開始日
--      AND   seh.delivery_date         <= riv.effective_end_date   --納品日<=営業員情報ビュー.適用終了日
      AND   seh.results_employee_code = papf.employee_number       --従業員コード
      AND   seh.delivery_date         >= papf.effective_start_date --納品日>=従業員マスタ.適用開始日
      AND   seh.delivery_date         <= papf.effective_end_date   --納品日<=従業員マスタ.適用終了日
/* 2009/04/21 Ver1.2 Mod End   */
      AND   seh.ship_to_customer_code = hca.account_number        --出荷先コード
      AND   hca.party_id              = hp.party_id               --パーティーID
      AND   sel.item_code             = msib.segment1             --品目コード
      AND   msib.organization_id      = gt_org_id                 --在庫組織ID
      AND   msib.segment1             = iimb.item_no              --OPM品目コード
      AND   iimb.item_id              = ximb.item_id              --OPMアドオン品目ID
      AND   seh.delivery_date         >= ximb.start_date_active   --納品日>=OPM品目アドオン.適用開始日
      AND   seh.delivery_date         <= ximb.end_date_active     --納品日<=OPM品目アドオン.適用終了日
      ;
--
    -- *** ローカル・レコード ***
    l_data_rec                data_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --ループカウント初期化
    ln_idx          := 0;
    ln_err_item_idx := 0;
-- ************************ 2010/01/18 S.Miyakoshi Var1.8 ADD START ************************ --
    FOR i IN 1..g_base_info_tab.COUNT LOOP
      gv_base_code := g_base_info_tab(i).base_code;      --拠点コード
      gv_base_name := g_base_info_tab(i).base_name;      --拠点名称
-- ************************ 2010/01/18 S.Miyakoshi Var1.8 ADD  END  ************************ --
    --フラグ初期化
    lb_ext_flg      := FALSE;
    --対象データ取得
    <<loop_get_data>>
    FOR l_data_rec IN data_cur LOOP
      -- レコードIDの取得
      BEGIN
        SELECT
          xxcos_rep_cost_div_list_s01.NEXTVAL     redord_id
        INTO
          lt_record_id
        FROM
          dual
        ;
      END;
      --
      ln_idx := ln_idx + 1;
      g_report_data_tab(ln_idx).record_id              := lt_record_id;                --レコードID
      g_report_data_tab(ln_idx).base_code              := l_data_rec.base_code;        --拠点コード
-- ************************ 2009/10/02 S.Miyakoshi Var1.7 MOD START ************************ --
--      g_report_data_tab(ln_idx).base_name              := l_data_rec.base_name;        --拠点名称
      g_report_data_tab(ln_idx).base_name              := SUBSTRB( l_data_rec.base_name, 1, 40 );
                                                                                       --拠点名称
-- ************************ 2009/10/02 S.Miyakoshi Var1.7 MOD  END  ************************ --
      g_report_data_tab(ln_idx).dlv_date_start         := id_dlv_date_from;            --納品日開始
      g_report_data_tab(ln_idx).dlv_date_end           := id_dlv_date_to;              --納品日終了
      g_report_data_tab(ln_idx).employee_base_code     := l_data_rec.emp_code;         --営業担当者コード
      g_report_data_tab(ln_idx).employee_base_name     := SUBSTRB( l_data_rec.emp_name, 1, 14 );
                                                                                       --営業担当者名
      g_report_data_tab(ln_idx).deliver_to_code        := l_data_rec.ship_to_cd;       --出荷先コード
      g_report_data_tab(ln_idx).deliver_to_name        := SUBSTRB( l_data_rec.ship_to_nm, 1, 30 );
                                                                                       --出荷先名
      g_report_data_tab(ln_idx).dlv_date               := l_data_rec.dlv_date;         --納品日
      g_report_data_tab(ln_idx).dlv_invoice_number     := l_data_rec.dlv_slip_num;     --納品伝票番号
      g_report_data_tab(ln_idx).item_code              := l_data_rec.item_cd;          --品目コード
      g_report_data_tab(ln_idx).order_item_name        := l_data_rec.item_nm;          --受注品名
      g_report_data_tab(ln_idx).quantity               := l_data_rec.quantity;         --数量
      g_report_data_tab(ln_idx).uom_code               := l_data_rec.unit;             --単位
      g_report_data_tab(ln_idx).dlv_unit_price         := l_data_rec.dlv_price;        --納品単価
      g_report_data_tab(ln_idx).sale_amount            := l_data_rec.quantity * l_data_rec.dlv_price;
                                                                                       --売上金額
      g_report_data_tab(ln_idx).created_by             := cn_created_by;               --作成者
      g_report_data_tab(ln_idx).creation_date          := cd_creation_date;            --作成日
      g_report_data_tab(ln_idx).last_updated_by        := cn_last_updated_by;          --最終更新者
      g_report_data_tab(ln_idx).last_update_date       := cd_last_update_date;         --最終更新日
      g_report_data_tab(ln_idx).last_update_login      := cn_last_update_login;        --最終更新ﾛｸﾞｲﾝ
      g_report_data_tab(ln_idx).request_id             := cn_request_id;               --要求ID
      g_report_data_tab(ln_idx).program_application_id := cn_program_application_id;   --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
      g_report_data_tab(ln_idx).program_id             := cn_program_id;               --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
      g_report_data_tab(ln_idx).program_update_date    := cd_program_update_date;      --ﾌﾟﾛｸﾞﾗﾑ更新日
      --営業原価先行チェック
      IF ( l_data_rec.biz_cost IS NULL ) THEN
        --警告件数計上
        gn_warn_cnt := gn_warn_cnt + 1;
        --フラグクリア
        lb_ext_flg  := FALSE;
        --該当品目コードの設定済チェック
        <<loop_search>>
        FOR ln_search IN 1 .. g_err_item_cd_tab.COUNT LOOP
          IF ( g_err_item_cd_tab(ln_search) = l_data_rec.item_cd ) THEN
            lb_ext_flg := TRUE;
            EXIT;
          END IF;
        END LOOP loop_search;
        --該当品目コードが未設定の場合、設定へ
        IF ( lb_ext_flg = FALSE ) THEN
          ln_err_item_idx                    := ln_err_item_idx + 1;
          --営業原価未設定の品目コードを集約して保持
          g_err_item_cd_tab(ln_err_item_idx) := l_data_rec.item_cd;
        END IF;
      END IF;
    END LOOP loop_get_data;
-- ************************ 2010/01/18 S.Miyakoshi Var1.8 ADD START ************************ --
    END LOOP;
-- ************************ 2010/01/18 S.Miyakoshi Var1.8 ADD  END  ************************ --
--
    --処理件数カウント
    gn_target_cnt := g_report_data_tab.COUNT;
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
  END get_data;
--
  /**********************************************************************************
   * Procedure Name   : check_cost
   * Description      : 営業原価チェック(A-4)
   ***********************************************************************************/
  PROCEDURE check_cost(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_cost'; -- プログラム名
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
    ln_cnt      NUMBER;          -- エラー品目コード件数
    lv_warnmsg  VARCHAR2(5000);  -- ユーザー・警告・メッセージ
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
    --営業原価取得エラーメッセージ出力
    ln_cnt := g_err_item_cd_tab.COUNT;
    <<msg_out_loop>>
    FOR ln_inx IN 1..ln_cnt LOOP
      --メッセージ取得
      lv_warnmsg              :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_sale_cost_get_err,
        iv_token_name1        =>  cv_tkn_nm_item_code,
        iv_token_value1       =>  g_err_item_cd_tab(ln_inx)
      );
      --メッセージ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_warnmsg --ユーザー・警告・メッセージ
      );
    END LOOP msg_out_loop;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
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
  END check_cost;
--
  /**********************************************************************************
   * Procedure Name   : insert_rpt_wrk_data
   * Description      : 帳票ワークテーブル登録(A-5)
   ***********************************************************************************/
  PROCEDURE insert_rpt_wrk_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_rpt_wrk_data'; -- プログラム名
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
    lv_tkn_vl_table_name      VARCHAR2(100);      --対象テーブル名
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
    --帳票ワークテーブル登録処理
    BEGIN
      FORALL ln_cnt IN g_report_data_tab.FIRST .. g_report_data_tab.LAST
        INSERT INTO 
          xxcos_rep_cost_div_list
        VALUES
          g_report_data_tab(ln_cnt)
        ;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_data_insert_expt;
    END;
--
    --正常件数取得
    gn_normal_cnt := g_report_data_tab.COUNT;
--
  EXCEPTION
    --*** 処理対象データ登録例外 ***
    WHEN global_data_insert_expt THEN
      lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_table_name1
      );
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_insert_err,
        iv_token_name1        =>  cv_tkn_nm_table_name,
        iv_token_value1       =>  lv_tkn_vl_table_name,
        iv_token_name2        =>  cv_tkn_nm_key_data,
        iv_token_value2       =>  NULL
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
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
  END insert_rpt_wrk_data;
--
  /**********************************************************************************
   * Procedure Name   : execute_svf
   * Description      : SVF起動(A-6)
   ***********************************************************************************/
  PROCEDURE execute_svf(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'execute_svf'; -- プログラム名
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
    lv_nodata_msg       VARCHAR2(5000);   --明細0件用メッセージ
    lv_file_name        VARCHAR2(100);    --出力ファイル名
    lv_tkn_vl_api_name  VARCHAR2(100);    --API名
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --明細0件用メッセージ取得
    lv_nodata_msg           :=  xxccp_common_pkg.get_msg(
      iv_application        =>  cv_xxcos_short_name,
      iv_name               =>  cv_msg_no_data_err
    );
--
    --出力ファイル名編集
    lv_file_name := cv_report_id || TO_CHAR( SYSDATE, cv_yyyymmdd ) || TO_CHAR( cn_request_id ) || cv_extension;
--
    --SVF起動
    xxccp_svfcommon_pkg.submit_svf_request(
      ov_retcode              =>  lv_retcode,
      ov_errbuf               =>  lv_errbuf,
      ov_errmsg               =>  lv_errmsg,
      iv_conc_name            =>  cv_conc_name,
      iv_file_name            =>  lv_file_name,
      iv_file_id              =>  cv_report_id,
      iv_output_mode          =>  cv_output_mode,
      iv_frm_file             =>  cv_frm_file,
      iv_vrq_file             =>  cv_vrq_file,
      iv_org_id               =>  NULL,
      iv_user_name            =>  NULL,
      iv_resp_name            =>  NULL,
      iv_doc_name             =>  NULL,
      iv_printer_name         =>  NULL,
      iv_request_id           =>  TO_CHAR( cn_request_id ),
      iv_nodata_msg           =>  lv_nodata_msg,
      iv_svf_param1           =>  NULL,
      iv_svf_param2           =>  NULL,
      iv_svf_param3           =>  NULL,
      iv_svf_param4           =>  NULL,
      iv_svf_param5           =>  NULL,
      iv_svf_param6           =>  NULL,
      iv_svf_param7           =>  NULL,
      iv_svf_param8           =>  NULL,
      iv_svf_param9           =>  NULL,
      iv_svf_param10          =>  NULL,
      iv_svf_param11          =>  NULL,
      iv_svf_param12          =>  NULL,
      iv_svf_param13          =>  NULL,
      iv_svf_param14          =>  NULL,
      iv_svf_param15          =>  NULL
    );
    --SVF起動失敗
    IF  ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_svf_excute_expt;
    END IF;
--
  EXCEPTION
    --*** SVF起動例外 ***
    WHEN global_svf_excute_expt THEN
      lv_tkn_vl_api_name      :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_api_name
      );
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_api_err,
        iv_token_name1        =>  cv_tkn_nm_api_name,
        iv_token_value1       =>  lv_tkn_vl_api_name
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
  END execute_svf;
--
--
  /**********************************************************************************
   * Procedure Name   : delete_rpt_wrk_data
   * Description      : 帳票ワークテーブル削除(A-7)
   ***********************************************************************************/
  PROCEDURE delete_rpt_wrk_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_rpt_wrk_data'; -- プログラム名
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
    lv_key_info               VARCHAR2(5000);     --キー情報
    lv_tkn_vl_key_request_id  VARCHAR2(100);      --要求IDの文言
    lv_tkn_vl_table_name      VARCHAR2(100);      --対象テーブル名
--
    -- *** ローカル・カーソル ***
    CURSOR lock_cur
    IS
      SELECT cdl.record_id rec_id
      FROM   xxcos_rep_cost_div_list cdl       --原価割れチェックリスト帳票ワークテーブル
      WHERE cdl.request_id = cn_request_id     --要求ID
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
    --対象データロック
    BEGIN
      -- ロック用カーソルオープン
      OPEN lock_cur;
      -- ロック用カーソルクローズ
      CLOSE lock_cur;
    EXCEPTION
      --対象データロック例外
      WHEN global_data_lock_expt THEN
        RAISE global_data_lock_expt;
    END;
--
    --対象データ削除
    BEGIN
      DELETE FROM 
        xxcos_rep_cost_div_list cdl            --原価割れチェックリスト帳票ワークテーブル
      WHERE cdl.request_id = cn_request_id     --要求ID
      ;
    EXCEPTION
     --対象データ削除失敗
     WHEN OTHERS THEN
      lv_tkn_vl_key_request_id  :=  xxccp_common_pkg.get_msg(
        iv_application          =>  cv_xxcos_short_name,
        iv_name                 =>  cv_msg_vl_key_request_id
      );
      xxcos_common_pkg.makeup_key_info(
        iv_item_name1         =>  lv_tkn_vl_key_request_id,   --要求IDの文言
        iv_data_value1        =>  TO_CHAR( cn_request_id ),   --要求ID
        ov_key_info           =>  lv_key_info,                --編集されたキー情報
        ov_errbuf             =>  lv_errbuf,                  --エラーメッセージ
        ov_retcode            =>  lv_retcode,                 --リターンコード
        ov_errmsg             =>  lv_errmsg                   --ユーザ・エラー・メッセージ
      );
      IF ( lv_retcode = cv_status_normal ) THEN
        RAISE global_data_delete_expt;
      ELSE
        RAISE global_api_expt;
      END IF;
    END;
--
  EXCEPTION
    -- *** 処理対象データロック例外ハンドラ ***
    WHEN global_data_lock_expt THEN
      -- カーソルオープン時、クローズへ
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_table_name1
      );
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_lock_err,
        iv_token_name1        =>  cv_tkn_nm_table_lock,
        iv_token_value1       =>  lv_tkn_vl_table_name
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    --*** 処理対象データ削除例外ハンドラ ***
    WHEN global_data_delete_expt THEN
      lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_table_name1
      );
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_delete_err,
        iv_token_name1        =>  cv_tkn_nm_table_name,
        iv_token_value1       =>  lv_tkn_vl_table_name,
        iv_token_name2        =>  cv_tkn_nm_key_data,
        iv_token_value2       =>  lv_key_info
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
  END delete_rpt_wrk_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_sale_base_code   IN  VARCHAR2,     --   売上拠点コード
    iv_dlv_date_from    IN  VARCHAR2,     --   納品日(FROM)
    iv_dlv_date_to      IN  VARCHAR2,     --   納品日(TO)
    iv_sale_emp_code    IN  VARCHAR2,     --   営業担当者コード
    iv_ship_to_code     IN  VARCHAR2,     --   出荷先コード
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
    ld_dlv_date_from    DATE;         --   納品日(FROM)
    ld_dlv_date_to      DATE;         --   納品日(TO)
--
--2009/06/25  Ver1.4 T1_1437  Add start
    lv_errbuf_svf  VARCHAR2(5000);  -- エラー・メッセージ(SVF実行結果保持用)
    lv_retcode_svf VARCHAR2(1);     -- リターン・コード(SVF実行結果保持用)
    lv_errmsg_svf  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ(SVF実行結果保持用)
--2009/06/25  Ver1.4 T1_1437  Add end
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
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
-- ******** 2010/02/17 1.9 N.Maeda ADD START ******** --
    gv_date_err_flag := cv_status_normal;
-- ******** 2010/02/17 1.9 N.Maeda ADD  END  ******** --
--
    -- ===============================
    -- A-1  初期処理
    -- ===============================
    init(
      iv_sale_base_code,  -- 売上拠点コード
      iv_dlv_date_from,   -- 納品日(FROM)
      iv_dlv_date_to,     -- 納品日(TO)
      iv_sale_emp_code,   -- 営業担当者コード
      iv_ship_to_code,    -- 出荷先コード
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2  パラメータチェック
    -- ===============================
    check_parameter(
      iv_dlv_date_from,   -- 納品日(FROM)
      iv_dlv_date_to,     -- 納品日(TO)
      ld_dlv_date_from,   -- 納品日(FROM)_チェックOK
      ld_dlv_date_to,     -- 納品日(TO)_チェックOK
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
-- ******** 2010/02/17 1.9 N.Maeda ADD START ******** --
    IF ( gv_date_err_flag = cv_status_normal ) THEN
-- ******** 2010/02/17 1.9 N.Maeda ADD  END  ******** --
      -- ===============================
      -- A-3  対象データ取得
      -- ===============================
      get_data(
        iv_sale_base_code,  -- 売上拠点コード
        ld_dlv_date_from,   -- 納品日(FROM)
        ld_dlv_date_to,     -- 納品日(TO)
        iv_sale_emp_code,   -- 営業担当者コード
        iv_ship_to_code,    -- 出荷先コード
        lv_errbuf,          -- エラー・メッセージ           --# 固定 #
        lv_retcode,         -- リターン・コード             --# 固定 #
        lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
      IF ( lv_retcode = cv_status_normal ) THEN
        NULL;
      ELSE
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- A-4  営業原価チェック
      -- ===============================
      IF ( g_err_item_cd_tab.COUNT > 0 ) THEN
       check_cost(
         lv_errbuf,         -- エラー・メッセージ           --# 固定 #
         lv_retcode,        -- リターン・コード             --# 固定 #
         lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
       IF ( lv_retcode = cv_status_normal ) THEN
         NULL;
       ELSE
         RAISE global_process_expt;
       END IF;
      END IF;
--
      -- ===============================
      -- A-5  帳票ワークテーブル登録
      -- ===============================
      insert_rpt_wrk_data(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF ( lv_retcode = cv_status_normal ) THEN
        COMMIT;
      ELSE
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- A-6  SVF起動
      -- ===============================
      execute_svf(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
-- 2009/06/25  Ver1.4  T1_1437  Mod Start
--    IF ( lv_retcode = cv_status_normal ) THEN
--      NULL;
--    ELSE
--      RAISE global_process_expt;
--    END IF;
      --
      --エラーでもワークテーブルを削除する為、エラー情報を保持
      lv_errbuf_svf  := lv_errbuf;
      lv_retcode_svf := lv_retcode;
      lv_errmsg_svf  := lv_errmsg;
-- 2009/06/25  Ver1.4 T1_1437  Mod End
--
      -- ===============================
      -- A-7  帳票ワークテーブル削除
      -- ===============================
      delete_rpt_wrk_data(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF ( lv_retcode = cv_status_normal ) THEN
        NULL;
      ELSE
        RAISE global_process_expt;
      END IF;
--
-- 2009/06/25  Ver1.4 T1_1437  Add start
      --エラーの場合、ロールバックするのでここでコミット
      COMMIT;
--
      --SVF実行結果確認
      IF ( lv_retcode_svf = cv_status_error ) THEN
        lv_errbuf  := lv_errbuf_svf;
        lv_retcode := lv_retcode_svf;
        lv_errmsg  := lv_errmsg_svf;
        RAISE global_process_expt;
      END IF;
  -- 2009/06/25  Ver1.4 T1_1437  Add End
-- ******** 2010/02/17 1.9 N.Maeda ADD START ******** --
    END IF;
-- ******** 2010/02/17 1.9 N.Maeda ADD  END  ******** --
--
    --明細0件時／営業原価チェックエラー時ステータス制御処理
--****************************** 2009/06/17 1.3 N.Nishimura MOD START ******************************--
--    IF ( gn_target_cnt = 0 OR gn_warn_cnt > 0 ) THEN
-- ******** 2010/02/17 1.9 N.Maeda MOD START ******** --
--    IF ( gn_target_cnt <> 0 ) THEN
    IF ( gn_target_cnt <> 0 ) OR ( gv_date_err_flag != cv_status_normal ) THEN
-- ******** 2010/02/17 1.9 N.Maeda MOD  END  ******** --
--****************************** 2009/06/17 1.3 N.Nishimura MOD  END  ******************************--
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
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
    errbuf              OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode             OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_sale_base_code   IN  VARCHAR2,      --   売上拠点コード
    iv_dlv_date_from    IN  VARCHAR2,      --   納品日(FROM)
    iv_dlv_date_to      IN  VARCHAR2,      --   納品日(TO)
    iv_sale_emp_code    IN  VARCHAR2,      --   営業担当者コード
    iv_ship_to_code     IN  VARCHAR2       --   出荷先コード
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
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- コンカレントヘッダメッセージ出力先：出力
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- コンカレントヘッダメッセージ出力先：ログ
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
       iv_sale_base_code
      ,iv_dlv_date_from
      ,iv_dlv_date_to
      ,iv_sale_emp_code
      ,iv_ship_to_code
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF ( lv_retcode = cv_status_error ) THEN
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
    --対象件数出力
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
    --成功件数出力
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
    --エラー件数出力
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
    --
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxccp_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_warn_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
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
                     iv_application  => cv_xxccp_short_name
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
END XXCOS009A03R;
/
