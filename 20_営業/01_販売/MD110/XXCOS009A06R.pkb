CREATE OR REPLACE PACKAGE BODY APPS.XXCOS009A06R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS009A06R (body)
 * Description      : EDI納品予定未納リスト
 * MD.050           : EDI納品予定未納リスト MD050_COS_009_A06
 * Version          : 1.7
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_data               対象データ取得(A-2)
 *  insert_rpt_wrk_data    帳票ワークテーブル登録(A-3)
 *  execute_svf            SVF起動(A-4)
 *  delete_rpt_wrk_data    帳票ワークテーブル削除(A-5)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/07    1.0   H.Ri             新規作成
 *  2009/02/17    1.1   H.Ri             get_msgのパッケージ名修正
 *  2009/06/18    1.2   T.Tominaga       障害対応[T1_1436]
 *                                       EDI納品予定未納リスト情報取得SQLにorg_idを条件に加える
 *  2009/06/19    1.3   T.Tominaga       障害対応[T1_1439]
 *                                       対象データ0件の場合、警告終了から正常終了に変更
 *  2009/06/26    1.4   N.Nishimura      障害対応[T1_1437]データパージ不具合対応
 *  2009/07/13    1.5   K.Kiriu          障害対応[0000488]PT対応
 *  2009/10/09    1.6   M.Sano           障害対応[0001378]帳票テーブルの桁あふれ対応
 *  2011/08/24    1.7   K.Kiriu          [E_本稼動_08181]PT対応
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
  cn_per_business_group_id  CONSTANT NUMBER      := fnd_global.per_business_group_id; --PER_BUSINESS_GROUP_ID
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
  cv_pkg_name               CONSTANT  VARCHAR2(100) := 'XXCOS009A06R';         -- パッケージ名
  cv_conc_name              CONSTANT  VARCHAR2(100) := 'XXCOS009A06R';         -- コンカレント名
  --帳票出力関連
  cv_report_id              CONSTANT  VARCHAR2(100) := 'XXCOS009A06R';         -- 帳票ＩＤ
  cv_frm_file               CONSTANT  VARCHAR2(100) := 'XXCOS009A06S.xml';     -- フォーム様式ファイル名
  cv_vrq_file               CONSTANT  VARCHAR2(100) := 'XXCOS009A06S.vrq';     -- クエリー様式ファイル名
  cv_output_mode            CONSTANT  VARCHAR2(1)   := '1';                    -- 出力区分(PDF)
  cv_extension              CONSTANT  VARCHAR2(100) := '.pdf';                 -- 拡張子(PDF)
  cv_xxcos_short_name       CONSTANT  VARCHAR2(100) := 'XXCOS';                -- 販物領域短縮アプリ名
  cv_xxccp_short_name       CONSTANT  VARCHAR2(100) := 'XXCCP';                -- 共通領域短縮アプリ名
  cv_half_space             CONSTANT  VARCHAR2(100) := ' ';                    -- 半角スペース
  --メッセージ
  cv_msg_insert_err         CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00010';    -- データ登録エラーメッセージ
  cv_msg_no_data_err        CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00018';    -- 明細0件エラーメッセージ
  cv_msg_lock_err           CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00001';    -- ロック取得エラーメッセージ
  cv_msg_delete_err         CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00012';    -- データ削除エラーメッセージ
  cv_msg_api_err            CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00017';    -- APIエラーメッセージ
  cv_msg_proc_date_err      CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00014';    -- 業務日付取得エラーメッセージ
  cv_msg_prof_err           CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00004';    -- プロファイル取得エラーメッセージ
  --トークン名
  cv_tkn_nm_table_name      CONSTANT  VARCHAR2(100) :=  'TABLE_NAME';          --テーブル名称
  cv_tkn_nm_table_lock      CONSTANT  VARCHAR2(100) :=  'TABLE';               --テーブル名称(ロックエラー時用)
  cv_tkn_nm_key_data        CONSTANT  VARCHAR2(100) :=  'KEY_DATA';            --キーデータ
  cv_tkn_nm_api_name        CONSTANT  VARCHAR2(100) :=  'API_NAME';            --API名称
  cv_tkn_nm_profile         CONSTANT  VARCHAR2(100) :=  'PROFILE';             --プロファイル名(販売領域)
  --トークン値
  cv_msg_vl_table_name      CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11901';    --帳票ワークテーブル名
  cv_msg_vl_api_name        CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00041';    --API名称
  cv_msg_vl_key_request_id  CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00088';    --要求ID
  cv_msg_vl_min_date        CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00120';    --MIN日付
  cv_msg_vl_max_date        CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00056';    --MAX日付
  --日付フォーマット
  cv_yyyymmdd               CONSTANT  VARCHAR2(100) :=  'YYYYMMDD';            --YYYYMMDD型
  cv_yyyy_mm_dd             CONSTANT  VARCHAR2(100) :=  'YYYY/MM/DD';          --YYYY/MM/DD型
  cv_yyyy_mm                CONSTANT  VARCHAR2(100) :=  'YYYY/MM';             --YYYY/MM型
  --クイックコード参照用
  --使用可能フラグ定数
  ct_enabled_flg_y          CONSTANT  fnd_lookup_values.enabled_flag%TYPE :=  'Y';    --使用可能
  cv_lang                   CONSTANT  VARCHAR2(100) :=  USERENV( 'LANG' );            --言語
  cv_ord_src_type           CONSTANT  VARCHAR2(100) :=  'XXCOS1_ODR_SRC_MST_009_A06'; --受注ソースのクイックタイプ
  cv_ord_src_code           CONSTANT  VARCHAR2(100) :=  'XXCOS_009_A06_01';           --受注ソースのクイックコード
  cv_hokan_type             CONSTANT  VARCHAR2(100) :=  'XXCOS1_HOKAN_TYPE_MST_009_A06'; --保管場所のクイックタイプ
  cv_hokan_code             CONSTANT  VARCHAR2(100) :=  'XXCOS_009_A06_01';           --保管場所のクイックコード
  --プロファイル関連
  cv_prof_min_date          CONSTANT  VARCHAR2(100) :=  'XXCOS1_MIN_DATE';     -- プロファイル名(MIN日付)
  cv_prof_max_date          CONSTANT  VARCHAR2(100) :=  'XXCOS1_MAX_DATE';     -- プロファイル名(MAX日付)
  --カテゴリ／ステータス
  cv_emp                    CONSTANT  VARCHAR2(100) := 'EMP';                  -- 従業員
  cv_oh_status_booked       CONSTANT  VARCHAR2(100) := 'BOOKED';               -- 受注ヘッダステータス(記帳済)
  cv_ol_status_closed       CONSTANT  VARCHAR2(100) := 'CLOSED';               -- 受注明細ステータス(クローズ)
  cv_ol_status_cancelled    CONSTANT  VARCHAR2(100) := 'CANCELLED';            -- 受注明細ステータス(取消)
  cv_order_return           CONSTANT  VARCHAR2(100) := 'RETURN';               -- マイナス受注タイプ
/* 2009/07/13 Ver1.5 Add Start */
  --取引タイプ(受注明細)
  cv_line                   CONSTANT  VARCHAR2(100) := 'LINE';                 -- 受注明細取引タイプ
/* 2009/07/13 Ver1.5 Add End   */
-- ******************** 2009/06/18 Var.1.2 T.Tominaga ADD START  *****************************************
  --MO:営業単位
  ct_prof_org_id            CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'ORG_ID'; -- MO:営業単位
  cv_str_profile_nm         CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00047';     -- MO:営業単位
-- ******************** 2009/06/18 Var.1.2 T.Tominaga ADD END    *****************************************
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  --EDI納品予定未納リスト帳票ワークテーブル型
  TYPE g_rpt_data_ttype IS TABLE OF xxcos_rep_sch_dlv_list%ROWTYPE INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  g_report_data_tab         g_rpt_data_ttype;                                   --帳票データコレクション
  gd_proc_date              DATE;                                               --業務日付
  gd_min_date               DATE;                                               --MIN日付
  gd_max_date               DATE;                                               --MAX日付
-- ******************** 2009/06/18 Var.1.2 T.Tominaga ADD START  *****************************************
  -- 営業単位
  gn_org_id                 NUMBER;
-- ******************** 2009/06/18 Var.1.2 T.Tominaga ADD END    *****************************************
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'init';                 -- プログラム名
    cv_msg_no_para  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008';     -- パラメータ無しメッセージ名
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
    lv_no_para_msg  VARCHAR2(5000);  -- パラメータ無しメッセージ
    lv_date_item    VARCHAR2(100);   -- MIN日付/MAX日付
-- ******************** 2009/06/18 Var.1.2 T.Tominaga ADD START  *****************************************
    lv_profile_name VARCHAR2(5000);  -- MO:営業単位
-- ******************** 2009/06/18 Var.1.2 T.Tominaga ADD END    *****************************************
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
    --========================================
    -- 1.パラメータ無しメッセージ出力処理
    --========================================
    lv_no_para_msg            :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxccp_short_name,
        iv_name               =>  cv_msg_no_para
      );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_no_para_msg
    );
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --========================================
    -- 2.業務日付取得処理
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
    -- 3.MIN日付取得処理
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
        iv_token_name1        =>  cv_tkn_nm_profile,
        iv_token_value1       =>  lv_date_item
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 4.MAX日付取得処理
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
        iv_token_name1        =>  cv_tkn_nm_profile,
        iv_token_value1       =>  lv_date_item
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- ******************** 2009/06/18 Var.1.2 T.Tominaga ADD START  *****************************************
    --==================================
    -- 5.MO:営業単位取得処理
    --==================================
    gn_org_id := FND_PROFILE.VALUE( ct_prof_org_id );
--
    -- プロファイルが取得できない場合はエラー
    IF ( gn_org_id IS NULL ) THEN
      --プロファイル名文字列取得
      lv_profile_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_short_name,
                           iv_name        => cv_str_profile_nm
                         );
--
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_prof_err,
        iv_token_name1        =>  cv_tkn_nm_profile,
        iv_token_value1       =>  lv_profile_name
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
-- ******************** 2009/06/18 Var.1.2 T.Tominaga ADD END    *****************************************
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
   * Procedure Name   : get_data
   * Description      : 処理対象データ取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_data(
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
    lt_record_id              xxcos_rep_sch_dlv_list.record_id%TYPE;  --レコードID
--
    -- *** ローカル・カーソル ***
    CURSOR data_cur
    IS
      SELECT  
/* 2011/08/24 Ver1.7 Add Start */
        /*+
          NO_MERGE(lbiv)
          LEADING(lbiv)
        */
/* 2011/08/24 Ver1.7 Add End   */
        lbiv.base_code                    base_code,        --納品拠点コード
        MAX( lbiv.base_name )             base_name,        --納品拠点名
        ooha.request_date                 req_date,         --要求日
        jrre.source_number                emp_code,         --従業員番号
        MAX( papf.per_information18 || 
        cv_half_space               || 
        papf.per_information19 )          emp_name,         --漢字姓 + 漢字名
        hca.account_number                cust_code,        --顧客コード
        MAX( hp.party_name )              cust_name,        --顧客名称
        ooha.order_number                 order_no,         --受注番号
        ooha.cust_po_number               entry_no,         --顧客発注
        ooha.ordered_date                 ord_date,         --受注日
        --金額合計
        SUM( 
          oola.ordered_quantity * DECODE( otta.order_category_code, cv_order_return, -1, 1 ) * oola.unit_selling_price
        )                                 amount            --金額
      FROM  
/* 2009/07/13 Ver1.5 Mod Start */
--        oe_order_headers_all      ooha,                     --受注ヘッダテーブル
--        oe_order_lines_all        oola,                     --受注明細テーブル
--        mtl_secondary_inventories msi,                      --保管場所マスタ
--        oe_order_sources          oos,                      --受注ソースマスタ
--        xxcos_login_base_info_v   lbiv,                     --ログインユーザ拠点ビュー
--        hz_cust_accounts          hca,                      --顧客マスタ
--        xxcmm_cust_accounts       xca,                      --顧客アドオン
--        hz_parties                hp,                       --パーティ
--        jtf_rs_resource_extns     jrre,                     --リソースマスタ
--        jtf_rs_salesreps          jrs,                      --jtf_rs_salesreps
--        per_all_people_f          papf,                     --従業員マスタ
--        per_person_types          ppt,                      --従業員タイプマスタ
--        oe_transaction_types_tl   ottt,                     --受注明細摘要用取引タイプ
--        oe_transaction_types_all  otta                      --受注明細用取引タイプ
--      WHERE ooha.header_id       = oola.header_id           --受注ヘッダ.ヘッダID = 受注明細.ヘッダID
--      AND   ooha.order_source_id = oos.order_source_id      --受注ヘッダ.受注ソースID = 受注ソース.受注ソースID
--      --受注ソースのクイック参照(EDI受注)
--      AND   EXISTS(
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
--              AND     look_val.lookup_code        = cv_ord_src_code
--              AND     look_val.meaning            = oos.name
--              AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
--              AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
--              AND     look_val.enabled_flag       = ct_enabled_flg_y
--                  )
---- ******************** 2009/06/18 Var.1.2 T.Tominaga ADD START  *****************************************
--      AND   ooha.org_id             = gn_org_id             --組織ID
---- ******************** 2009/06/18 Var.1.2 T.Tominaga ADD END    *****************************************
--      AND   ooha.flow_status_code   = cv_oh_status_booked   --受注ヘッダ.ステータス = 記帳済
--                                                            --受注明細.ステータス <> クローズ、取消
--      AND   oola.flow_status_code   NOT IN ( cv_ol_status_closed, cv_ol_status_cancelled )
--      AND   oola.request_date       < gd_proc_date          --受注明細.要求日 < 業務日付
--      AND   oola.subinventory       = msi.secondary_inventory_name  --受注明細.保管場所 = 保管場所マスタ.名称
--      AND   oola.ship_from_org_id   = msi.organization_id   --受注明細.出荷元組織ID = 保管場所マスタ.在庫組織ID
--      --保管場所のクイック参照(営業車)
--      AND   EXISTS(
--              SELECT  'Y'                         ext_flg
--              FROM    fnd_lookup_values           look_val,
--                     fnd_lookup_types_tl         types_tl,
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
--              AND     look_val.lookup_type        = cv_hokan_type
--              AND     look_val.lookup_code        = cv_hokan_code
--              AND     look_val.meaning            = msi.attribute13
--              AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
--              AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
--              AND     look_val.enabled_flag       = ct_enabled_flg_y
--                    )
--      AND   ooha.sold_to_org_id     = hca.cust_account_id   --受注ヘッダ.顧客ID = 顧客マスタ.顧客ID
--      AND   hca.party_id            = hp.party_id           --顧客マスタ.パーティーID = パーティ.パーティーID
--      AND   hca.cust_account_id     = xca.customer_id       --顧客マスタ.顧客ID = 顧客アドオン.顧客ID
--      AND   xca.delivery_base_code  = lbiv.base_code        --顧客アドオン.納品拠点コード = 拠点ビュー.拠点コード
--      --営業担当者の取得用
--      AND   ooha.salesrep_id        = jrs.salesrep_id       --受注ヘッダ.営業担当ID = jtf_rs_salesreps.営業担当ID
--      AND   jrs.resource_id         = jrre.resource_id
--      AND   jrre.source_id          = papf.person_id
--      AND   gd_proc_date            >= NVL( papf.effective_start_date, gd_min_date )
--      AND   gd_proc_date            <= NVL( papf.effective_end_date, gd_max_date )
--      AND   ppt.business_group_id   = cn_per_business_group_id
--      AND   ppt.system_person_type  = cv_emp
--      AND   ppt.active_flag         = ct_enabled_flg_y
--      AND   papf.person_type_id     = ppt.person_type_id
--      --プラス／マイナス受注タイプ判定用
--      AND   oola.line_type_id         = ottt.transaction_type_id
--      AND   ottt.transaction_type_id  = otta.transaction_type_id
--      AND   ottt.language             = cv_lang
        oe_order_lines_all        oola,                     --受注明細テーブル
        oe_order_headers_all      ooha,                     --受注ヘッダテーブル
        hz_parties                hp,                       --パーティ
        hz_cust_accounts          hca,                      --顧客マスタ
        xxcmm_cust_accounts       xca,                      --顧客アドオン
        per_all_people_f          papf,                     --従業員マスタ
        mtl_secondary_inventories msi,                      --保管場所マスタ
        jtf_rs_resource_extns     jrre,                     --リソースマスタ
        jtf_rs_salesreps          jrs,                      --jtf_rs_salesreps
        oe_transaction_types_all  otta,                     --受注明細用取引タイプ
        per_person_types          ppt,                      --従業員タイプマスタ
        oe_order_sources          oos,                      --受注ソースマスタ
        xxcos_login_base_info_v   lbiv,                     --ログインユーザ拠点ビュー
        ( SELECT  look_val.meaning   meaning
          FROM    fnd_lookup_values  look_val
          WHERE   look_val.lookup_type  = cv_ord_src_type
          AND     look_val.lookup_code  = cv_ord_src_code
          AND     look_val.enabled_flag = ct_enabled_flg_y
          AND     look_val.language     = cv_lang
          AND     gd_proc_date BETWEEN NVL( look_val.start_date_active, gd_min_date )
                               AND     NVL( look_val.end_date_active, gd_max_date )
        )                         flv_osc,                  --クイックコード(受注ソース:EDI受注)
        ( SELECT  look_val.meaning   meaning
          FROM    fnd_lookup_values  look_val
          WHERE   look_val.lookup_type  = cv_hokan_type
          AND     look_val.lookup_code  = cv_hokan_code
          AND     look_val.enabled_flag = ct_enabled_flg_y
          AND     look_val.language     = cv_lang
          AND     gd_proc_date BETWEEN NVL( look_val.start_date_active, gd_min_date )
                               AND     NVL( look_val.end_date_active, gd_max_date )
        )                         flv_hc                    --クイックコード(保管場所:営業車)
      WHERE ooha.flow_status_code   = cv_oh_status_booked   --受注ヘッダ.ステータス = 記帳済
      AND   ooha.org_id             = gn_org_id             --組織ID
                                                            --受注明細.ステータス <> クローズ、取消
      AND   oola.flow_status_code   NOT IN ( cv_ol_status_closed, cv_ol_status_cancelled )
      AND   oola.request_date       < gd_proc_date          --受注明細.要求日 < 業務日付
      AND   msi.attribute13         = flv_hc.meaning        --クイックコード(保管場所:営業車) = 保管場所マスタ.保管場所分類
      AND   gd_proc_date            BETWEEN NVL( papf.effective_start_date, gd_min_date )
                                    AND     NVL( papf.effective_end_date, gd_max_date )
      AND   ppt.business_group_id   = cn_per_business_group_id
      AND   ppt.system_person_type  = cv_emp
      AND   ppt.active_flag         = ct_enabled_flg_y
      AND   otta.transaction_type_code = cv_line
      AND   oos.name                = flv_osc.meaning       --クイックコード(受注ソース:EDI受注) = 受注ソースマスタ.名称
      AND   ooha.order_source_id    = oos.order_source_id   --受注ヘッダ.受注ソースID = 受注ソース.受注ソースID
      AND   ooha.header_id          = oola.header_id        --受注ヘッダ.ヘッダID = 受注明細.ヘッダID
      AND   oola.subinventory       = msi.secondary_inventory_name  --受注明細.保管場所 = 保管場所マスタ.名称
      AND   oola.ship_from_org_id   = msi.organization_id   --受注明細.出荷元組織ID = 保管場所マスタ.在庫組織ID
      AND   ooha.sold_to_org_id     = hca.cust_account_id   --受注ヘッダ.顧客ID = 顧客マスタ.顧客ID
      AND   hca.party_id            = hp.party_id           --顧客マスタ.パーティーID = パーティ.パーティーID
      AND   hca.cust_account_id     = xca.customer_id       --顧客マスタ.顧客ID = 顧客アドオン.顧客ID
      AND   xca.delivery_base_code  = lbiv.base_code        --顧客アドオン.納品拠点コード = 拠点ビュー.拠点コード
            --営業担当者の取得用
      AND   ooha.salesrep_id        = jrs.salesrep_id       --受注ヘッダ.営業担当ID = jtf_rs_salesreps.営業担当ID
      AND   jrs.resource_id         = jrre.resource_id
      AND   jrre.source_id          = papf.person_id
      AND   papf.person_type_id     = ppt.person_type_id
      AND   oola.line_type_id       = otta.transaction_type_id  --受注明細.取引タイプID = 受注明細用取引タイプ.取引タイプID
/* 2009/07/13 Ver1.5 Mod End   */
      GROUP BY  lbiv.base_code,                                       --納品拠点コード
                ooha.request_date,                                    --要求日
                jrre.source_number,                                   --従業員番号
                hca.account_number,                                   --顧客コード
                ooha.order_number,                                    --受注番号
                ooha.cust_po_number,                                  --顧客発注
                ooha.ordered_date                                     --受注日
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
    --対象データ取得
    <<loop_get_data>>
    FOR l_data_rec IN data_cur LOOP
      -- レコードIDの取得
      BEGIN
        SELECT
          xxcos_rep_sch_dlv_list_s01.NEXTVAL     redord_id
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
/* 2009/10/08 Ver1.6 Mod Start */
--      g_report_data_tab(ln_idx).base_name              := l_data_rec.base_name;        --拠点名称
      g_report_data_tab(ln_idx).base_name              := SUBSTRB( l_data_rec.base_name, 1, 40 ); --拠点名称
/* 2009/10/08 Ver1.6 Mod End   */
      g_report_data_tab(ln_idx).schedule_dlv_date      := l_data_rec.req_date;         --納品予定日
      g_report_data_tab(ln_idx).employee_base_code     := l_data_rec.emp_code;         --営業担当者コード
      g_report_data_tab(ln_idx).employee_base_name     := SUBSTRB( l_data_rec.emp_name, 1, 12 );  --営業担当者名
      g_report_data_tab(ln_idx).customer_number        := l_data_rec.cust_code;                   --顧客番号
      g_report_data_tab(ln_idx).customer_name          := SUBSTRB( l_data_rec.cust_name, 1, 20 ); --顧客名
      g_report_data_tab(ln_idx).order_number           := l_data_rec.order_no;         --受注番号
/* 2009/10/08 Ver1.6 Mod Start */
--      g_report_data_tab(ln_idx).entry_number           := l_data_rec.entry_no;         --伝票番号
      g_report_data_tab(ln_idx).entry_number           := SUBSTRB( l_data_rec.entry_no, 1, 12 );  --伝票番号
/* 2009/10/08 Ver1.6 Mod End   */
      g_report_data_tab(ln_idx).amount                 := l_data_rec.amount;           --金額
      g_report_data_tab(ln_idx).ordered_date           := l_data_rec.ord_date;         --受注日                        
      g_report_data_tab(ln_idx).created_by             := cn_created_by;               --作成者
      g_report_data_tab(ln_idx).creation_date          := cd_creation_date;            --作成日
      g_report_data_tab(ln_idx).last_updated_by        := cn_last_updated_by;          --最終更新者
      g_report_data_tab(ln_idx).last_update_date       := cd_last_update_date;         --最終更新日
      g_report_data_tab(ln_idx).last_update_login      := cn_last_update_login;        --最終更新ﾛｸﾞｲﾝ
      g_report_data_tab(ln_idx).request_id             := cn_request_id;               --要求ID
      g_report_data_tab(ln_idx).program_application_id := cn_program_application_id;   --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
      g_report_data_tab(ln_idx).program_id             := cn_program_id;               --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
      g_report_data_tab(ln_idx).program_update_date    := cd_program_update_date;      --ﾌﾟﾛｸﾞﾗﾑ更新日
    END LOOP loop_get_data;
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
   * Procedure Name   : insert_rpt_wrk_data
   * Description      : 帳票ワークテーブル登録(A-3)
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
    lv_tkn_vl_table_name      VARCHAR2(100);      --帳票ワークテーブル日本語名
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
          xxcos_rep_sch_dlv_list
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
        iv_name               =>  cv_msg_vl_table_name
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
   * Description      : SVF起動(A-4)
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
    IF ( lv_retcode <> cv_status_normal ) THEN
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
   * Description      : 帳票ワークテーブル削除(A-5)
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
    lv_tkn_vl_table_name      VARCHAR2(100);      --帳票ワークテーブル日本語名
--
    -- *** ローカル・カーソル ***
    CURSOR lock_cur
    IS
      SELECT sdl.record_id rec_id
      FROM   xxcos_rep_sch_dlv_list sdl         --EDI納品予定未納リスト帳票ワークテーブル
      WHERE sdl.request_id = cn_request_id      --要求ID
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
        xxcos_rep_sch_dlv_list sdl              --EDI納品予定未納リスト帳票ワークテーブル
      WHERE sdl.request_id = cn_request_id      --要求ID
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
        iv_name               =>  cv_msg_vl_table_name
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
        iv_name               =>  cv_msg_vl_table_name
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
--2009/06/26  Ver1.4 T1_1437  Add start
    lv_errbuf_svf  VARCHAR2(5000);  -- エラー・メッセージ(SVF実行結果保持用)
    lv_retcode_svf VARCHAR2(1);     -- リターン・コード(SVF実行結果保持用)
    lv_errmsg_svf  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ(SVF実行結果保持用)
--2009/06/26  Ver1.4 T1_1437  Add end
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
    init(
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
    -- A-2  対象データ取得
    -- ===============================
    get_data(
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
    -- A-3  帳票ワークテーブル登録
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
    -- A-4  SVF起動
    -- ===============================
    execute_svf(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
-- 2009/06/26  Ver1.4  T1_1437  Mod Start
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
-- 2009/06/26  Ver1.4 T1_1437  Mod End
--
    -- ===============================
    -- A-5  帳票ワークテーブル削除
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
-- 2009/06/26  Ver1.4 T1_1437  Add start
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
-- 2009/06/26  Ver1.4 T1_1437  Add End
--
-- ******************** 2009/06/19 Var.1.3 T.Tominaga MOD START  *****************************************
--    --明細0件時ステータス制御処理
--  IF ( gn_target_cnt = 0 ) THEN
    IF ( gn_target_cnt <> 0 ) THEN
      ov_retcode := cv_status_warn;
    END IF;
-- ******************** 2009/06/19 Var.1.3 T.Tominaga MOD END    *****************************************
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
    retcode             OUT VARCHAR2       --   リターン・コード    --# 固定 #
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
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
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
END XXCOS009A06R;
/
