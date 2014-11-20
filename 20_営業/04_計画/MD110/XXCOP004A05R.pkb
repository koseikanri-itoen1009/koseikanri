CREATE OR REPLACE PACKAGE BODY XXCOP004A05R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP004A05R(body)
 * Description      : 引取計画立案表出力ワーク登録
 * MD.050           : 引取計画立案表 MD050_COP_004_A05
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  get_header_data        対象拠点・帳票ヘッダ情報取得(A-2,A-3)
 *  get_detail_data        帳票明細情報取得(A-4)
 *  qty_editing_data_keep  数量振分け・データ保持(A-5)
 *  reference_qty_calc     当月参考数量計算(A-6)
 *  insert_svf_work_tbl    引取計画立案表帳票ワークテーブルデータ登録(A-7)
 *  svf_call               SVF起動(A-8) 
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/29    1.0  SCS.Kikuchi       新規作成
 *  2009/03/04    1.1  SCS.Kikuchi       SVF結合対応
 *  2009/04/28    1.2  SCS.Kikuchi       T1_0645,T1_0838対応
 *  2009/06/10    1.3  SCS.Kikuchi       T1_1411対応
 *  2009/06/23    1.4  SCS.Kikuchi       障害:0000025対応
 *  2009/10/13    1.5  SCS.Fukada        障害:E_T3_00556対応
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
--★1.1 2009/03/04 Add Start
  internal_process_expt        EXCEPTION;     -- 内部PROCEDURE/FUNCTIONエラーハンドリング用
--★1.1 2009/03/04 Add End
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                  CONSTANT VARCHAR2(100) := 'XXCOP004A05R';        -- パッケージ名
  cv_target_month_format       CONSTANT VARCHAR2(6)   := 'YYYYMM';              -- 対象年月書式
  cv_customer_class_code_base  CONSTANT VARCHAR2(1)   := '1';                   -- 顧客区分：拠点
  cv_forecast_class            CONSTANT VARCHAR2(2)   := '01';                  -- フォーキャスト分類：引取計画
  cv_prod_class_code_leaf      CONSTANT VARCHAR2(1)   := '1';                   -- 商品区分：リーフ
  cv_data_type_forecast        CONSTANT VARCHAR2(1)   := '1';                   -- データ種別：引取計画
  cv_data_type_result          CONSTANT VARCHAR2(1)   := '2';                   -- データ種別：出荷実績
  cv_dlv_invoice_class_1       CONSTANT VARCHAR2(1)   := '1';                   -- 納品伝票区分:納品
  cv_dlv_invoice_class_3       CONSTANT VARCHAR2(1)   := '3';                   -- 納品伝票区分:納品訂正
  cv_sales_class_1             CONSTANT VARCHAR2(1)   := '1';                   -- 売上区分:通常
  cv_sales_class_5             CONSTANT VARCHAR2(1)   := '5';                   -- 売上区分:協賛
  cv_sales_class_6             CONSTANT VARCHAR2(1)   := '6';                   -- 売上区分:見本
--20090428_Ver1.2_T1_0645_SCS.Kikuchi_DEL_START
--  cv_cmn_organization_id       CONSTANT VARCHAR2(19)  := 'XXCMN_MASTER_ORG_ID'; -- マスタ品目組織
--20090428_Ver1.2_T1_0645_SCS.Kikuchi_DEL_END
  cv_inv_item_status_20        CONSTANT VARCHAR2(2)   := '20';                  -- 品目ステータス：仮登録
  cv_inv_item_status_30        CONSTANT VARCHAR2(2)   := '30';                  -- 品目ステータス：本登録
  cv_inv_item_status_40        CONSTANT VARCHAR2(2)   := '40';                  -- 品目ステータス：廃

--20090428_Ver1.2_T1_0645_SCS.Kikuchi_ADD_START
  cv_sales_org_code            CONSTANT VARCHAR2(30)  := 'XXCOP1_SALES_ORG_CODE'; -- 営業組織
--20090428_Ver1.2_T1_0645_SCS.Kikuchi_ADD_END

  -- 入力パラメータログ出力用
  cv_pm_prod_class_code_tl     CONSTANT VARCHAR2(100) := '商品区分';
  cv_pm_base_code_tl           CONSTANT VARCHAR2(100) := '拠点';
  cv_pm_part                   CONSTANT VARCHAR2(6)   := '　：　';

  -- エラーメッセージ
  cv_msg_application           CONSTANT VARCHAR2(100) := 'XXCOP';
  cv_profile_chk_msg           CONSTANT VARCHAR2(19)  := 'APP-XXCOP1-00002';    -- プロファイル取得エラー：品目組織
  cv_profile_chk_msg_tkn_lbl1  CONSTANT VARCHAR2(100) := 'PROF_NAME';
--20090428_Ver1.2_T1_0645_SCS.Kikuchi_MOD_START
--  cv_profile_chk_msg_tkn_val1  CONSTANT VARCHAR2(100) := 'XXCMN:マスタ組織';
  cv_profile_chk_msg_tkn_val1  CONSTANT VARCHAR2(100) := 'XXCOP:営業組織';
--20090428_Ver1.2_T1_0645_SCS.Kikuchi_MOD_END

--★1.1 2009/03/04 Add Start
  cv_others_err_msg           CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00041'; -- CSVｱｳﾄﾌﾟｯﾄ機能システムエラーメッセージ
  cv_others_err_msg_tkn_lbl1  CONSTANT VARCHAR2(100) := 'ERRMSG';
  cv_api_err_msg              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00016'; -- API起動エラー
  cv_api_err_msg_tkn_lbl1     CONSTANT VARCHAR2(100) := 'PRG_NAME';
  cv_api_err_msg_tkn_lbl1_val CONSTANT VARCHAR2(100) := 'XXCCP_SVFCOMMON_PKG.SUBMIT_SVF_REQUEST';
  cv_api_err_msg_tkn_lbl2     CONSTANT VARCHAR2(100) := 'ERR_MSG';

  -- SVF出力対応
  cv_svf_date_format          CONSTANT VARCHAR2(16)  := 'YYYYMMDDHH24MISS';     -- パラメータ：対象年月書式
  cv_file_name                CONSTANT VARCHAR2(40)  := 'XXCOP004A05R'
                                                        || TO_CHAR(SYSDATE,cv_svf_date_format)
                                                        || '.pdf';              -- 出力ファイル名
  cv_output_mode              CONSTANT VARCHAR2(1)   := '1';                    -- 出力区分：”１”（ＰＤＦ）
  cv_frm_file                 CONSTANT VARCHAR2(20)  := 'XXCOP004A05S.xml';     -- フォーム様式ファイル名
  cv_vrq_file                 CONSTANT VARCHAR2(20)  := 'XXCOP004A05S.vrq';     -- クエリー様式ファイル名
--★1.1 2009/03/04 Add End
--

--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 引取計画立案表ヘッダ情報レコード型
  TYPE header_data_trec IS RECORD(
      base_code                   hz_cust_accounts.account_number                       %TYPE  -- 顧客コード
    , base_short_name             xxcmn_parties.party_short_name                        %TYPE  -- 拠点名
    , ope_days_last_month         xxcop_rep_forecast_planning.operation_days_last_month %TYPE  -- 前月実働日数
    , ope_days_this_month         xxcop_rep_forecast_planning.operation_days_this_month %TYPE  -- 当月稼動予定日数
    , ope_days_next_month         xxcop_rep_forecast_planning.operation_days_next_month %TYPE  -- 翌月稼動予定日数
    , ope_days_this_month_prevday xxcop_rep_forecast_planning.operation_days_this_month %TYPE  -- 当月実働日数
    );

  -- 引取計画立案表ヘッダ情報PL/SQL表
  TYPE header_data_ttype IS
    TABLE OF header_data_trec INDEX BY BINARY_INTEGER;

  -- 引取計画立案表明細情報レコード型
  TYPE detail_data_trec IS RECORD(
      data_type           VARCHAR2(1)                                              -- データ種別区分
    , detail_month        VARCHAR2(6)                                              -- 明細年月
    , prod_class_code     xxcop_rep_forecast_planning.prod_class_code  %TYPE       -- 商品区分
    , prod_class_name     xxcop_rep_forecast_planning.prod_class_name  %TYPE       -- 商品区分名
    , crowd_class_code    xxcop_rep_forecast_planning.crowd_class_code %TYPE       -- 群コード
    , inventory_item_id   xxcop_item_categories1_v.inventory_item_id   %TYPE       -- INV品目ID
    , organization_id     xxcop_item_categories1_v.organization_id     %TYPE       -- 組織ID
    , item_id             xxcop_item_categories1_v.item_id             %TYPE       -- OPM品目ID
    , parent_item_id      xxcop_item_categories1_v.parent_item_id      %TYPE       -- OPM親品目ID
    , item_no             xxcop_rep_forecast_planning.item_no          %TYPE       -- 商品コード
    , item_short_name     xxcop_rep_forecast_planning.item_short_name  %TYPE       -- 商品名
    , quantity            NUMBER                                                   -- 数量
    , num_of_cases        xxcop_item_categories1_v.num_of_cases        %TYPE       -- ケース入数
    , parent_item_no      xxcop_rep_forecast_planning.item_no          %TYPE       -- 親品目コード
    );

  -- 引取計画立案表明細情報PL/SQL表
  TYPE detail_data_ttype IS
    TABLE OF detail_data_trec INDEX BY BINARY_INTEGER;
    
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 入力パラメータ格納用
  gv_prod_class_code           VARCHAR2(1);
  gv_base_code                 VARCHAR2(4);

  -- 処理制御日付格納用
  gv_target_month              VARCHAR2(6);           -- 計画対象年月
  gd_target_date_st_day        DATE;                  -- 計画対象年月初日
  gd_target_date_ed_day        DATE;                  -- 計画対象年月末日
  gd_system_date               DATE;                  -- システム日付
  gd_last_month_start_day      DATE;                  -- 前月実働日数抽出開始日
  gd_last_month_end_day        DATE;                  -- 前月実働日数抽出終了日
  gd_this_month_start_day      DATE;                  -- 当月稼動予定日数抽出開始日
  gd_this_month_end_day        DATE;                  -- 当月稼動予定日数抽出終了日
  gd_next_month_start_day      DATE;                  -- 翌月稼動予定日数抽出開始日
  gd_next_month_end_day        DATE;                  -- 翌月稼動予定日数抽出終了日
  gd_prev_day                  DATE;                  -- 当月実働日数抽出終了日（システム日付の前日）
  gd_forecast_collect_st_day   DATE;                  -- 引取計画抽出開始日（計画対象年月－３ヶ月の初日）
  gd_forecast_collect_ed_day   DATE;                  -- 引取計画抽出終了日（計画対象年月の末日）
  gd_result_collect_st_day1    DATE;                  -- 出荷実績抽出開始日（計画対象年月－１年３ヶ月の初日）
  gd_result_collect_ed_day1    DATE;                  -- 出荷実績抽出終了日（計画対象年月－１１ヶ月末日）
  gd_result_collect_st_day2    DATE;                  -- 出荷実績抽出開始日（計画対象年月－３ヶ月の初日）
  gd_result_collect_ed_day2    DATE;                  -- 出荷実績抽出終了日（計画対象年月－１ヶ月の末日）
--20090428_Ver1.2_T1_0645_SCS.Kikuchi_DEL_START
--  gn_mater_org_id              mtl_parameters.organization_id%type;
--20090428_Ver1.2_T1_0645_SCS.Kikuchi_DEL_END
--20090428_Ver1.2_T1_0645_SCS.Kikuchi_ADD_START
  gv_sales_org_code            mtl_parameters.organization_code%type;
--20090428_Ver1.2_T1_0645_SCS.Kikuchi_ADD_END

  -- 出力対象データ格納用
  g_header_data_tbl            header_data_ttype;                   -- 引取計画チェックリスト出力対象拠点
  g_header_data_tbl_init       header_data_ttype;                   -- 引取計画チェックリスト出力対象拠点初期化用
  g_detail_data_tbl            detail_data_ttype;                   -- 引取計画チェックリスト出力データ
  g_detail_data_tbl_init       detail_data_ttype;                   -- 引取計画チェックリスト出力データ初期化用
  g_forecast_planning_rec      xxcop_rep_forecast_planning%ROWTYPE; -- 引取計画立案表出力ワークテーブル
  g_forecast_planning_rec_init xxcop_rep_forecast_planning%ROWTYPE; -- 引取計画立案表出力ワークテーブル初期化用

  -- 明細0件メッセージ格納用
  gv_rep_no_data_msg           VARCHAR2(5000);

  -- デバッグ出力判定用
  gv_debug_mode                VARCHAR2(30);
--
--
--
  /**********************************************************************************
   * Procedure Name   : num_edit
   * Description      : 有効範囲外桁対応
   ***********************************************************************************/
  FUNCTION num_edit(
     in_value             IN  NUMBER
  )RETURN VARCHAR2
  IS
  BEGIN
     -- 少数２桁以降は切り捨て
     RETURN TRUNC(in_value,2);
  END num_edit;

  /**********************************************************************************
   * Procedure Name   : add_months_to_char
   * Description      : 指定月数のADD_MONTHS後にVARCHAR2型（年月形式）で戻す
   ***********************************************************************************/
  FUNCTION add_months_to_char(
     id_date              IN  DATE
   , in_value             IN  NUMBER
  )RETURN VARCHAR2
  IS
  BEGIN
     RETURN TO_CHAR(ADD_MONTHS(id_date,in_value),cv_target_month_format);
  END add_months_to_char;

  /**********************************************************************************
   * Procedure Name   : get_header_data
   * Description      : 対象拠点・帳票ヘッダ情報取得（A-2,A-3）
   ***********************************************************************************/
  PROCEDURE get_header_data(
     ov_errbuf            OUT VARCHAR2    --   エラー・メッセージ           --# 固定 #
   , ov_retcode           OUT VARCHAR2    --   リターン・コード             --# 固定 #
   , ov_errmsg            OUT VARCHAR2    --   ユーザー・エラー・メッセージ --# 固定 #
  )IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_header_data'; -- プログラム名
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
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    ------------------------------------------------------------
    --  管理元拠点＋配下拠点抽出
    ------------------------------------------------------------
    SELECT hca.account_number        account_number                -- 顧客コード
    ,      xp.party_short_name       base_short_name               -- 拠点名
    ,      ( SELECT  count(*)
             FROM    bom_calendar_dates bom
             WHERE   calendar_code = mp.calendar_code
             AND     exception_set_id = mp.calendar_exception_set_id
             AND     calendar_date BETWEEN gd_last_month_start_day AND gd_last_month_end_day
             AND     seq_num is not null
           ) ope_days_last_month                                   -- 前月実働日数
    ,      ( SELECT  count(*)
             FROM    bom_calendar_dates bom
             WHERE   calendar_code = mp.calendar_code
             AND     exception_set_id = mp.calendar_exception_set_id
             AND     calendar_date BETWEEN gd_this_month_start_day AND gd_this_month_end_day
             AND     seq_num is not null
           ) ope_days_this_month                                   -- 当月稼動予定日数
    ,      ( SELECT  count(*)
             FROM    bom_calendar_dates bom
             WHERE   calendar_code = mp.calendar_code
             AND     exception_set_id = mp.calendar_exception_set_id
             AND     calendar_date BETWEEN gd_next_month_start_day AND gd_next_month_end_day
             AND     seq_num is not null
           ) ope_days_next_month                                   -- 翌月稼動予定日数
    ,      ( SELECT  count(*)
             FROM    bom_calendar_dates bom
             WHERE   calendar_code = mp.calendar_code
             AND     exception_set_id = mp.calendar_exception_set_id
             AND     calendar_date BETWEEN gd_this_month_start_day AND gd_prev_day
             AND     seq_num is not null
           ) ope_days_this_month_prevday                           -- 当月実働日数
    BULK COLLECT
    INTO   g_header_data_tbl
    FROM   hz_cust_accounts         hca            -- 顧客マスタ
    ,      xxcmn_parties            xp             -- パーティアドオンマスタ
    ,      mtl_parameters           mp             -- 組織パラメータ
    WHERE  hca.customer_class_code =  cv_customer_class_code_base
    AND (  hca.account_number      =  gv_base_code
        OR hca.cust_account_id     IN ( SELECT customer_id
                                        FROM   xxcmm_cust_accounts                      -- 顧客追加情報
                                        WHERE  management_base_code = gv_base_code      -- 管理元拠点コード
                                      )
        )
    AND    xp.party_id         (+) =  hca.party_id
    AND    xp.start_date_active(+) <= gd_system_date
    AND    xp.end_date_active  (+) >= gd_system_date
--20090428_Ver1.2_T1_0645_SCS.Kikuchi_MOD_START
--    AND    mp.organization_id      =  gn_mater_org_id
    AND    mp.organization_code    =  gv_sales_org_code
--20090428_Ver1.2_T1_0645_SCS.Kikuchi_MOD_END
    ;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--■当処理では使用しない■■■■■■■■■■■■■■■■■■■■■■
--■    -- *** 共通関数例外ハンドラ ***
--■    WHEN global_api_expt THEN
--■      ov_errmsg  := lv_errmsg;
--■      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--■      ov_retcode := cv_status_error;
--■    -- *** 共通関数OTHERS例外ハンドラ ***
--■    WHEN global_api_others_expt THEN
--■      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--■      ov_retcode := cv_status_error;
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_header_data;
--
  /**********************************************************************************
   * Procedure Name   : get_detail_data
   * Description      : 帳票明細情報取得(A-4)
   ***********************************************************************************/
  PROCEDURE get_detail_data(
     in_header_index      IN  NUMBER      -- ヘッダ情報レコードINDEX
   , ov_errbuf            OUT VARCHAR2    --   エラー・メッセージ           --# 固定 #
   , ov_retcode           OUT VARCHAR2    --   リターン・コード             --# 固定 #
   , ov_errmsg            OUT VARCHAR2    --   ユーザー・エラー・メッセージ --# 固定 #
  )IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_detail_data'; -- プログラム名
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
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    ------------------------------------------------------------
    --  帳票出力明細情報取得
    ------------------------------------------------------------
    SELECT data_type              data_type            -- データ種別区分
    ,      detail_month           detail_month         -- 明細年月
    ,      prod_class_code        prod_class_code      -- 商品区分
    ,      prod_class_name        prod_class_name      -- 商品区分名
    ,      crowd_class_code       crowd_class_code     -- 群コード
    ,      inventory_item_id      inventory_item_id    -- INV品目ID
    ,      organization_id        organization_id      -- 組織ID
    ,      item_id                item_id              -- OPM品目ID
    ,      parent_item_id         parent_item_id       -- OPM親品目ID
    ,      item_no                item_no              -- 商品コード
    ,      item_short_name        item_short_name      -- 商品名
    ,      quantity               quantity             -- 数量
    ,      num_of_cases           num_of_cases         -- ケース入数
    ,      parent_item_no         parent_item_no       -- 親品目コード
    BULK COLLECT
    INTO   g_detail_data_tbl
    FROM
    ( SELECT cv_data_type_forecast                          data_type                -- データ種別区分
      ,      TO_CHAR(forecast_date,cv_target_month_format)  detail_month             -- 明細年月
      ,      xic1v.prod_class_code                          prod_class_code          -- 商品区分
      ,      xic1v.prod_class_name                          prod_class_name          -- 商品区分名
      ,      SUBSTRB(xic1v.crowd_class_code,1,3)            crowd_class_code         -- 群コード
      ,      xic1v.inventory_item_id                        inventory_item_id        -- INV品目ID
      ,      xic1v.organization_id                          organization_id          -- 組織ID
      ,      xic1v.item_id                                  item_id                  -- OPM品目ID
      ,      xic1v.parent_item_id                           parent_item_id           -- OPM親品目ID
      ,      xic1v.item_no                                  item_no                  -- 商品コード
      ,      xic1v.item_short_name                          item_short_name          -- 商品名
      ,      SUM(mfda.original_forecast_quantity)           quantity                 -- 数量
      ,      xic1v.num_of_cases                             num_of_cases             -- ケース入数
      ,      xic1v.parent_item_no                           parent_item_no           -- 親品目コード
      FROM
             mrp_forecast_designators mfde                           -- フォーキャスト名
      ,      mrp_forecast_dates       mfda                           -- フォーキャスト日付
      ,      xxcop_item_categories1_v xic1v                          -- 計画_品目カテゴリビュー1
      ,      xxcmm_system_items_b     xsib                           -- Disc品目アドオン
      WHERE
             mfde.forecast_designator   =  mfda.forecast_designator
      AND    mfde.organization_id       =  mfda.organization_id
      AND    mfde.attribute1            =  cv_forecast_class         -- FORECAST分類：引取計画
      AND    mfde.attribute3            =  g_header_data_tbl(in_header_index).base_code
      AND    mfda.forecast_date         BETWEEN gd_forecast_collect_st_day
                                        AND     gd_forecast_collect_ed_day
      AND    xic1v.inventory_item_id    =  mfda.inventory_item_id
      AND    xic1v.start_date_active    <= gd_system_date
      AND    xic1v.end_date_active      >= gd_system_date
      AND    xic1v.prod_class_code      =  gv_prod_class_code
      AND    xic1v.item_id              =  xsib.item_id
      AND    xsib.item_status           IN ( cv_inv_item_status_20
                                           , cv_inv_item_status_30
                                           , cv_inv_item_status_40 ) -- 品目ステータス
      AND    NVL( xsib.item_status_apply_date, gd_system_date )
                                        <= gd_system_date            -- 品目ステータス適用日
      GROUP
      BY     TO_CHAR(forecast_date,cv_target_month_format)           -- 明細年月
      ,      xic1v.prod_class_code                                   -- 商品区分
      ,      xic1v.prod_class_name                                   -- 商品区分名
      ,      SUBSTRB(xic1v.crowd_class_code,1,3)                     -- 群コード
      ,      xic1v.inventory_item_id                                 -- INV品目ID
      ,      xic1v.organization_id                                   -- 組織ID
      ,      xic1v.item_id                                           -- OPM品目ID
      ,      xic1v.parent_item_id                                    -- OPM親品目ID
      ,      xic1v.item_no                                           -- 商品コード
      ,      xic1v.item_short_name                                   -- 商品名
      ,      xic1v.num_of_cases                                      -- ケース入数
      ,      xic1v.parent_item_no                                    -- 親品目コード
      UNION ALL
      SELECT cv_data_type_result                            data_type                -- データ種別区分
--20090623_Ver1.4_0000025_SCS.Kikuchi_MOD_START
--      ,      TO_CHAR(shipment_date,cv_target_month_format)  detail_month             -- 明細年月
      ,      TO_CHAR(xsrst.shipment_date,cv_target_month_format)  detail_month             -- 明細年月
--20090623_Ver1.4_0000025_SCS.Kikuchi_MOD_END
      ,      xic1v.prod_class_code                          prod_class_code          -- 商品区分
      ,      xic1v.prod_class_name                          prod_class_name          -- 商品区分名
      ,      SUBSTRB(xic1v.crowd_class_code,1,3)            crowd_class_code         -- 群コード
      ,      xic1v.inventory_item_id                        inventory_item_id        -- INV品目ID
      ,      xic1v.organization_id                          organization_id          -- 組織ID
      ,      xic1v.item_id                                  item_id                  -- OPM品目ID
      ,      xic1v.parent_item_id                           parent_item_id           -- OPM親品目ID
      ,      xic1v.item_no                                  item_no                  -- 商品コード
      ,      xic1v.item_short_name                          item_short_name          -- 商品名
      ,      SUM(xsrst.quantity)                            quantity                 -- 数量
      ,      xic1v.num_of_cases                             num_of_cases             -- ケース入数
      ,      xic1v.parent_item_no                           parent_item_no           -- 親品目コード
      FROM
--20090623_Ver1.4_0000025_SCS.Kikuchi_MOD_START
           ( SELECT xsr1.shipment_date
             ,      xsr1.item_no
             ,      xsr1.quantity
             FROM   xxcop_shipment_results   xsr1
             WHERE  xsr1.shipment_date  BETWEEN gd_result_collect_st_day1
                                          AND     gd_result_collect_ed_day1
             AND    xsr1.base_code      =       g_header_data_tbl(in_header_index).base_code
--20091013_Ver1.5_E_T3_00556_SCS.Fukada_MOD_START
--             UNION
             UNION ALL
--20091013_Ver1.5_E_T3_00556_SCS.Fukada_MOD_END
             SELECT xsr2.shipment_date
             ,      xsr2.item_no
             ,      xsr2.quantity
             FROM   xxcop_shipment_results   xsr2
             WHERE  xsr2.shipment_date  BETWEEN gd_result_collect_st_day2
                                          AND     gd_result_collect_ed_day2
             AND    xsr2.base_code      =       g_header_data_tbl(in_header_index).base_code
             )xsrst                                                  -- 親コード出荷実績表
--             xxcop_shipment_results   xsrst                          -- 親コード出荷実績表
--20090623_Ver1.4_0000025_SCS.Kikuchi_MOD_END
      ,      xxcop_item_categories1_v xic1v                          -- 計画_品目カテゴリビュー1
      ,      xxcmm_system_items_b     xsib                           -- Disc品目アドオン
      WHERE
--20090623_Ver1.4_0000025_SCS.Kikuchi_MOD_START
--             xsrst.base_code            =       g_header_data_tbl(in_header_index).base_code
--      AND    (   xsrst.shipment_date    BETWEEN gd_result_collect_st_day1
--                                        AND     gd_result_collect_ed_day1
--             OR  xsrst.shipment_date    BETWEEN gd_result_collect_st_day2
--                                        AND     gd_result_collect_ed_day2
--             )
--      AND    xic1v.item_no              =       xsrst.item_no
             xic1v.item_no              =       xsrst.item_no
--20090623_Ver1.4_0000025_SCS.Kikuchi_MOD_END
      AND    xic1v.start_date_active    <=      gd_system_date
      AND    xic1v.end_date_active      >=      gd_system_date
      AND    xic1v.prod_class_code      =       gv_prod_class_code
      AND    xic1v.item_id              =       xsib.item_id
      AND    xsib.item_status           IN ( cv_inv_item_status_20
                                           , cv_inv_item_status_30
                                           , cv_inv_item_status_40 ) -- 品目ステータス
      AND    NVL( xsib.item_status_apply_date, gd_system_date )
                                        <= gd_system_date            -- 品目ステータス適用日
      GROUP
      BY     TO_CHAR(shipment_date,cv_target_month_format)           -- 明細年月
      ,      xic1v.prod_class_code                                   -- 商品区分
      ,      xic1v.prod_class_name                                   -- 商品区分名
      ,      SUBSTRB(xic1v.crowd_class_code,1,3)                     -- 群コード
      ,      xic1v.inventory_item_id                                 -- INV品目ID
      ,      xic1v.organization_id                                   -- 組織ID
      ,      xic1v.item_id                                           -- OPM品目ID
      ,      xic1v.parent_item_id                                    -- OPM親品目ID
      ,      xic1v.item_no                                           -- 商品コード
      ,      xic1v.item_short_name                                   -- 商品名
      ,      xic1v.num_of_cases                                      -- ケース入数
      ,      xic1v.parent_item_no                                    -- 親品目コード
    )
    ORDER
    BY     item_no                 -- 商品コード
    ,      data_type               -- データ種別区分
    ,      detail_month            -- 明細年月
    ;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--■当処理では使用しない■■■■■■■■■■■■■■■■■■■■■■
--■    -- *** 共通関数例外ハンドラ ***
--■    WHEN global_api_expt THEN
--■      ov_errmsg  := lv_errmsg;
--■      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--■      ov_retcode := cv_status_error;
--■    -- *** 共通関数OTHERS例外ハンドラ ***
--■    WHEN global_api_others_expt THEN
--■      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--■      ov_retcode := cv_status_error;
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_detail_data;
--
  /**********************************************************************************
   * Procedure Name   : qty_editing_data_keep
   * Description      : 数量振分け・データ保持(A-5)
   ***********************************************************************************/
  PROCEDURE qty_editing_data_keep(
     in_header_index      IN  NUMBER      -- 1.ヘッダ情報レコードINDEX
   , in_detail_index      IN  NUMBER      -- 2.明細情報レコードINDEX
   , ov_errbuf            OUT VARCHAR2    --   エラー・メッセージ           --# 固定 #
   , ov_retcode           OUT VARCHAR2    --   リターン・コード             --# 固定 #
   , ov_errmsg            OUT VARCHAR2    --   ユーザー・エラー・メッセージ --# 固定 #
  )IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'qty_editing_data_keep'; -- プログラム名
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
    ld_target_date    DATE;
    ln_case_quantity  NUMBER;
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
    -- 対象年月を日付型に変換する
    ld_target_date   := TO_DATE(gv_target_month,cv_target_month_format);


    -- 引取計画数量をケース換算する
    ln_case_quantity := num_edit(g_detail_data_tbl(in_detail_index).quantity
                              / NVL(g_detail_data_tbl(in_detail_index).num_of_cases,1));

    -- 明細年月が１年３ヶ月前の場合
    IF (g_detail_data_tbl(in_detail_index).detail_month = add_months_to_char(ld_target_date,-15)) THEN
      g_forecast_planning_rec.ship_to_quantity_15_months_ago := ln_case_quantity;

    -- 明細年月が１年２ヶ月前の場合
    ELSIF (g_detail_data_tbl(in_detail_index).detail_month = add_months_to_char(ld_target_date,-14)) THEN
      g_forecast_planning_rec.ship_to_quantity_14_months_ago := ln_case_quantity;

    -- 明細年月が１年１ヶ月前の場合
    ELSIF (g_detail_data_tbl(in_detail_index).detail_month = add_months_to_char(ld_target_date,-13)) THEN
      g_forecast_planning_rec.ship_to_quantity_13_months_ago := ln_case_quantity;

    -- 明細年月が１年前の場合
    ELSIF (g_detail_data_tbl(in_detail_index).detail_month = add_months_to_char(ld_target_date,-12)) THEN
      g_forecast_planning_rec.ship_to_quantity_12_months_ago := ln_case_quantity;

    -- 明細年月が１１ヶ月前の場合
    ELSIF (g_detail_data_tbl(in_detail_index).detail_month = add_months_to_char(ld_target_date,-11)) THEN
      g_forecast_planning_rec.ship_to_quantity_11_months_ago := ln_case_quantity;

    -- 明細年月が３ヶ月前の場合
    ELSIF (g_detail_data_tbl(in_detail_index).detail_month = add_months_to_char(ld_target_date,-3)) THEN
    
      IF (g_detail_data_tbl(in_detail_index).data_type = cv_data_type_forecast) THEN
        g_forecast_planning_rec.forecast_quantity_3_months_ago := ln_case_quantity;
      ELSE
        g_forecast_planning_rec.ship_to_quantity_3_months_ago  := ln_case_quantity;
      END IF;

    -- 明細年月が２ヶ月前の場合
    ELSIF (g_detail_data_tbl(in_detail_index).detail_month = add_months_to_char(ld_target_date,-2)) THEN

      IF (g_detail_data_tbl(in_detail_index).data_type = cv_data_type_forecast) THEN
        g_forecast_planning_rec.forecast_quantity_2_months_ago := ln_case_quantity;
      ELSE
        g_forecast_planning_rec.ship_to_quantity_2_months_ago  := ln_case_quantity;
      END IF;

    -- 明細年月が１ヶ月前の場合
    ELSIF (g_detail_data_tbl(in_detail_index).detail_month = add_months_to_char(ld_target_date,-1)) THEN

      IF (g_detail_data_tbl(in_detail_index).data_type = cv_data_type_forecast) THEN
        g_forecast_planning_rec.forecast_quantity_1_months_ago := ln_case_quantity;
      ELSE
        g_forecast_planning_rec.ship_to_quantity_1_months_ago  := ln_case_quantity;
      END IF;

    -- 明細年月が計画対象年月の場合
    ELSIF (g_detail_data_tbl(in_detail_index).detail_month = add_months_to_char(ld_target_date,0)) THEN
      g_forecast_planning_rec.forecast_quantity := ln_case_quantity;

    END IF;

    -- 集計キー保持
    g_forecast_planning_rec.prod_class_code  := g_detail_data_tbl(in_detail_index).prod_class_code;  -- 商品区分
    g_forecast_planning_rec.prod_class_name  := g_detail_data_tbl(in_detail_index).prod_class_name;  -- 商品区分名
    g_forecast_planning_rec.crowd_class_code := g_detail_data_tbl(in_detail_index).crowd_class_code; -- 群コード
    g_forecast_planning_rec.item_no          := g_detail_data_tbl(in_detail_index).item_no;          -- 商品コード
    g_forecast_planning_rec.item_short_name  := g_detail_data_tbl(in_detail_index).item_short_name;  -- 商品名
    g_forecast_planning_rec.parent_item_no   := g_detail_data_tbl(in_detail_index).parent_item_no;   -- 親品目コード
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
--■当処理では使用しない■■■■■■■■■■■■■■■■■■■■■■
--■    -- *** 共通関数例外ハンドラ ***
--■    WHEN global_api_expt THEN
--■      ov_errmsg  := lv_errmsg;
--■      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--■      ov_retcode := cv_status_error;
--■    -- *** 共通関数OTHERS例外ハンドラ ***
--■    WHEN global_api_others_expt THEN
--■      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--■      ov_retcode := cv_status_error;
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END qty_editing_data_keep;
  /**********************************************************************************
   * Procedure Name   : insert_check_list
   * Description      : 当月参考数量計算(A-6)
   ***********************************************************************************/
  PROCEDURE reference_qty_calc(
     in_header_index      IN  NUMBER      -- 1.ヘッダ情報レコードINDEX
   , in_detail_index      IN  NUMBER      -- 2.明細情報レコードINDEX
   , ov_errbuf            OUT VARCHAR2    --   エラー・メッセージ           --# 固定 #
   , ov_retcode           OUT VARCHAR2    --   リターン・コード             --# 固定 #
   , ov_errmsg            OUT VARCHAR2    --   ユーザー・エラー・メッセージ --# 固定 #
  )IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'reference_qty_calc'; -- プログラム名
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
    ln_book_inventory_quantity   NUMBER;
    ln_standard_qty              NUMBER;
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
    ---------------------------------------------------------------------------
    -- 登録情報設定
    ---------------------------------------------------------------------------
    -- 帳票ヘッダ情報
    g_forecast_planning_rec.base_code                 := g_header_data_tbl(in_header_index).base_code;
    g_forecast_planning_rec.base_short_name           := g_header_data_tbl(in_header_index).base_short_name;
    g_forecast_planning_rec.target_month              := gv_target_month;
    g_forecast_planning_rec.operation_days_last_month := g_header_data_tbl(in_header_index).ope_days_last_month;
--    g_forecast_planning_rec.operation_days_this_month := g_header_data_tbl(in_header_index).ope_days_this_month;
    g_forecast_planning_rec.operation_days_this_month := g_header_data_tbl(in_header_index).ope_days_this_month_prevday;
    g_forecast_planning_rec.operation_days_next_month := g_header_data_tbl(in_header_index).ope_days_next_month;

    -- 各数量のNULLを0に置換する
    g_forecast_planning_rec.ship_to_quantity_15_months_ago
                                     := NVL(g_forecast_planning_rec.ship_to_quantity_15_months_ago,0);
    g_forecast_planning_rec.ship_to_quantity_14_months_ago
                                     := NVL(g_forecast_planning_rec.ship_to_quantity_14_months_ago,0);
    g_forecast_planning_rec.ship_to_quantity_13_months_ago
                                     := NVL(g_forecast_planning_rec.ship_to_quantity_13_months_ago,0);
    g_forecast_planning_rec.ship_to_quantity_12_months_ago
                                     := NVL(g_forecast_planning_rec.ship_to_quantity_12_months_ago,0);
    g_forecast_planning_rec.ship_to_quantity_11_months_ago
                                     := NVL(g_forecast_planning_rec.ship_to_quantity_11_months_ago,0);
    g_forecast_planning_rec.forecast_quantity_3_months_ago
                                     := NVL(g_forecast_planning_rec.forecast_quantity_3_months_ago,0);
    g_forecast_planning_rec.ship_to_quantity_3_months_ago
                                     := NVL(g_forecast_planning_rec.ship_to_quantity_3_months_ago ,0);
    g_forecast_planning_rec.forecast_quantity_2_months_ago
                                     := NVL(g_forecast_planning_rec.forecast_quantity_2_months_ago,0);
    g_forecast_planning_rec.ship_to_quantity_2_months_ago
                                     := NVL(g_forecast_planning_rec.ship_to_quantity_2_months_ago ,0);
    g_forecast_planning_rec.forecast_quantity_1_months_ago
                                     := NVL(g_forecast_planning_rec.forecast_quantity_1_months_ago,0);
    g_forecast_planning_rec.ship_to_quantity_1_months_ago
                                     := NVL(g_forecast_planning_rec.ship_to_quantity_1_months_ago ,0);
    g_forecast_planning_rec.forecast_quantity
                                     := NVL(g_forecast_planning_rec.forecast_quantity             ,0);


    -- 親品目で無い場合（OPM品目IDとOPM親品目IDが異なる）、当月参考情報は設定しない。
    IF (g_detail_data_tbl(in_detail_index).item_id<>g_detail_data_tbl(in_detail_index).parent_item_id) THEN
       g_forecast_planning_rec.present_stock_quantity      := NULL;
       g_forecast_planning_rec.delivery_forecast_quantity  := NULL;
       g_forecast_planning_rec.ship_to_quantity_forecast   := NULL;
--       g_forecast_planning_rec.forecast_remainder_quantity := NULL;
       -- 引取計画残数量
       g_forecast_planning_rec.forecast_remainder_quantity := 
             num_edit(g_forecast_planning_rec.forecast_quantity_1_months_ago
                      - g_forecast_planning_rec.ship_to_quantity_1_months_ago
             );
       g_forecast_planning_rec.stock_forecast_quantity     := NULL;
       RETURN;
    END IF;

    -----------------------------------------------------------------
    -- 月次在庫受払表（日次）データ取得
    -----------------------------------------------------------------
    SELECT NVL(SUM(book_inventory_quantity),0) book_inventory_quantity
    INTO   ln_book_inventory_quantity
    FROM   xxcoi_inv_reception_daily                     -- 月次在庫受払表（日次）
    WHERE  (base_code,organization_id,practice_date,subinventory_code,inventory_item_id) IN
             ( SELECT base_code
                    , organization_id
                    , MAX(practice_date)
                    , subinventory_code
                    , inventory_item_id
               FROM   xxcoi_inv_reception_daily          -- 月次在庫受払表（日次）
               WHERE  base_code         = g_header_data_tbl(in_header_index).base_code
               AND    inventory_item_id = g_detail_data_tbl(in_detail_index).inventory_item_id
--20090428_Ver1.2_T1_0838_SCS.Kikuchi_MOD_START
--               AND    practice_date     BETWEEN gd_this_month_start_day
--                                        AND     gd_prev_day
               AND    practice_date     <= gd_prev_day
--20090428_Ver1.2_T1_0838_SCS.Kikuchi_MOD_END
               GROUP
               BY     base_code
                    , organization_id
                    , subinventory_code
                    , inventory_item_id
             )
    ;

    -----------------------------------------------------------------
    -- 販売実績データ取得
    -----------------------------------------------------------------
    SELECT NVL(SUM(standard_qty),0) standard_qty
    INTO   ln_standard_qty
    FROM   xxcos_sales_exp_headers xseh           -- 販売実績ヘッダ
    ,      xxcos_sales_exp_lines   xsel           -- 販売実績明細
    WHERE  xseh.sales_exp_header_id =  xsel.sales_exp_header_id
    AND    xsel.item_code           =  g_detail_data_tbl(in_detail_index).item_no
    AND    xsel.delivery_base_code  =  g_header_data_tbl(in_header_index).base_code
    AND    xseh.dlv_invoice_class   IN (cv_dlv_invoice_class_1,cv_dlv_invoice_class_3)         -- 納品伝票区分
    AND    xsel.sales_class         IN (cv_sales_class_1,cv_sales_class_5,cv_sales_class_6)    -- 売上区分
    AND    xseh.delivery_date       BETWEEN gd_this_month_start_day
                                    AND     gd_prev_day
    ;
    -----------------------------------------------------------------
    -- 月次在庫、販売実績をケース換算する
    -----------------------------------------------------------------
    ln_book_inventory_quantity := ln_book_inventory_quantity / NVL(g_detail_data_tbl(in_detail_index).num_of_cases,1);
    ln_standard_qty            := ln_standard_qty / NVL(g_detail_data_tbl(in_detail_index).num_of_cases,1);

    -----------------------------------------------------------------
    -- 当月参考数量算出
    -----------------------------------------------------------------
    -- 現在庫数量
    g_forecast_planning_rec.present_stock_quantity      := num_edit(ln_book_inventory_quantity);

    -- 今後出庫予測数量
    IF ( g_header_data_tbl(in_header_index).ope_days_this_month_prevday = 0 ) THEN
      g_forecast_planning_rec.delivery_forecast_quantity  := 0;
    ELSE
      g_forecast_planning_rec.delivery_forecast_quantity  := 
            num_edit( ( ln_standard_qty / g_header_data_tbl(in_header_index).ope_days_this_month_prevday )
                   *  ( g_header_data_tbl(in_header_index).ope_days_this_month
--20090610_Ver1.3_T1_1411_SCS.Kikuchi_MOD_START
                      - g_header_data_tbl(in_header_index).ope_days_this_month_prevday )
--                      - g_header_data_tbl(in_header_index).ope_days_this_month_prevday + 1 )
--20090610_Ver1.3_T1_1411_SCS.Kikuchi_MOD_END
              );
    END IF;

    -- 当年度 対象月予測数量
    IF (  ( g_forecast_planning_rec.ship_to_quantity_12_months_ago = 0 )
       OR ( g_forecast_planning_rec.ship_to_quantity_13_months_ago = 0 )
       )
    THEN
      g_forecast_planning_rec.ship_to_quantity_forecast   := 0;
    ELSE
      g_forecast_planning_rec.ship_to_quantity_forecast   := 
            num_edit( ( g_forecast_planning_rec.ship_to_quantity_12_months_ago
              / g_forecast_planning_rec.ship_to_quantity_13_months_ago )
              *  ( ln_standard_qty + g_forecast_planning_rec.delivery_forecast_quantity )
              );
    END IF;

    -- 引取計画残数量
    g_forecast_planning_rec.forecast_remainder_quantity := 
          num_edit(g_forecast_planning_rec.forecast_quantity_1_months_ago
                   - g_forecast_planning_rec.ship_to_quantity_1_months_ago
          );

    -- 月末在庫予測数量
    g_forecast_planning_rec.stock_forecast_quantity     :=
          num_edit( ln_book_inventory_quantity - g_forecast_planning_rec.delivery_forecast_quantity
                    + g_forecast_planning_rec.forecast_remainder_quantity
          );

    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
--■当処理では使用しない■■■■■■■■■■■■■■■■■■■■■■
--■    -- *** 共通関数例外ハンドラ ***
--■    WHEN global_api_expt THEN
--■      ov_errmsg  := lv_errmsg;
--■      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--■      ov_retcode := cv_status_error;
--■    -- *** 共通関数OTHERS例外ハンドラ ***
--■    WHEN global_api_others_expt THEN
--■      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--■      ov_retcode := cv_status_error;
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END reference_qty_calc;
--
  /**********************************************************************************
   * Procedure Name   : insert_check_list
   * Description      : 引取計画立案表帳票ワークテーブルデータ登録(A-7)
   ***********************************************************************************/
  PROCEDURE insert_svf_work_tbl(
     ov_errbuf   OUT VARCHAR2            --   エラー・メッセージ           --# 固定 #
   , ov_retcode  OUT VARCHAR2            --   リターン・コード             --# 固定 #
   , ov_errmsg   OUT VARCHAR2            --   ユーザー・エラー・メッセージ --# 固定 #
  )IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_svf_work_tbl'; -- プログラム名
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
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--

    -----------------------------------------------------------------
    -- 引取計画立案表帳票ワークテーブルデータ登録処理
    -----------------------------------------------------------------
    INSERT INTO xxcop_rep_forecast_planning
      ( target_month                                                 -- 立案対象年月
      , prod_class_code                                              -- 商品区分
      , prod_class_name                                              -- 商品区分名
      , base_code                                                    -- 拠点コード
      , base_short_name                                              -- 拠点名
      , operation_days_last_month                                    -- 前月稼動実績日数
      , operation_days_this_month                                    -- 当月稼動実績日数
      , operation_days_next_month                                    -- 翌月稼動予定日数
      , crowd_class_code                                             -- 群コード（上３桁）
      , item_no                                                      -- 商品コード
      , item_short_name                                              -- 商品名
      , ship_to_quantity_15_months_ago                               -- 前年度 対象３ヶ月前実績数量
      , ship_to_quantity_14_months_ago                               -- 前年度 対象前々月実績数量
      , ship_to_quantity_13_months_ago                               -- 前年度 対象前月実績数量
      , ship_to_quantity_12_months_ago                               -- 前年度 対象月実績数量
      , ship_to_quantity_11_months_ago                               -- 前年度 対象翌月実績数量
      , ship_to_quantity_3_months_ago                                -- 当年度 対象３ヶ月前実績数量
      , ship_to_quantity_2_months_ago                                -- 当年度 対象前々月実績数量
      , ship_to_quantity_1_months_ago                                -- 当年度 対象前月実績数量
      , ship_to_quantity_forecast                                    -- 当年度 対象月予測数量
      , forecast_quantity_3_months_ago                               -- 当年度 対象３ヶ月前計画数量
      , forecast_quantity_2_months_ago                               -- 当年度 対象前々月計画数量
      , forecast_quantity_1_months_ago                               -- 当年度 対象前月計画数量
      , forecast_quantity                                            -- 当年度 対象月計画数量
      , present_stock_quantity                                       -- 現在庫数量
      , forecast_remainder_quantity                                  -- 引取計画残数量
      , delivery_forecast_quantity                                   -- 今後出庫予測数量
      , stock_forecast_quantity                                      -- 月末在庫予測数量
      , parent_item_no                                               -- 親品目コード
      , created_by                                                   -- 作成者
      , creation_date                                                -- 作成日
      , last_updated_by                                              -- 最終更新者
      , last_update_date                                             -- 最終更新日
      , last_update_login                                            -- 最終更新ログイン
      , request_id                                                   -- 要求ID
      , program_application_id                                       -- プログラムアプリケーションID
      , program_id                                                   -- プログラムID
      , program_update_date                                          -- プログラム更新日
      )
    VALUES
      ( g_forecast_planning_rec.target_month                         -- 立案対象年月
      , g_forecast_planning_rec.prod_class_code                      -- 商品区分
      , g_forecast_planning_rec.prod_class_name                      -- 商品区分名
      , g_forecast_planning_rec.base_code                            -- 拠点コード
      , g_forecast_planning_rec.base_short_name                      -- 拠点名
      , g_forecast_planning_rec.operation_days_last_month            -- 前月稼動実績日数
      , g_forecast_planning_rec.operation_days_this_month            -- 当月稼動実績日数
      , g_forecast_planning_rec.operation_days_next_month            -- 翌月稼動予定日数
      , g_forecast_planning_rec.crowd_class_code                     -- 群コード（上３桁）
      , g_forecast_planning_rec.item_no                              -- 商品コード
      , g_forecast_planning_rec.item_short_name                      -- 商品名
      , g_forecast_planning_rec.ship_to_quantity_15_months_ago       -- 前年度 対象３ヶ月前実績数量
      , g_forecast_planning_rec.ship_to_quantity_14_months_ago       -- 前年度 対象前々月実績数量
      , g_forecast_planning_rec.ship_to_quantity_13_months_ago       -- 前年度 対象前月実績数量
      , g_forecast_planning_rec.ship_to_quantity_12_months_ago       -- 前年度 対象月実績数量
      , g_forecast_planning_rec.ship_to_quantity_11_months_ago       -- 前年度 対象翌月実績数量
      , g_forecast_planning_rec.ship_to_quantity_3_months_ago        -- 当年度 対象３ヶ月前実績数量
      , g_forecast_planning_rec.ship_to_quantity_2_months_ago        -- 当年度 対象前々月実績数量
      , g_forecast_planning_rec.ship_to_quantity_1_months_ago        -- 当年度 対象前月実績数量
      , g_forecast_planning_rec.ship_to_quantity_forecast            -- 当年度 対象月予測数量
      , g_forecast_planning_rec.forecast_quantity_3_months_ago       -- 当年度 対象３ヶ月前計画数量
      , g_forecast_planning_rec.forecast_quantity_2_months_ago       -- 当年度 対象前々月計画数量
      , g_forecast_planning_rec.forecast_quantity_1_months_ago       -- 当年度 対象前月計画数量
      , g_forecast_planning_rec.forecast_quantity                    -- 当年度 対象月計画数量
      , g_forecast_planning_rec.present_stock_quantity               -- 現在庫数量
      , g_forecast_planning_rec.forecast_remainder_quantity          -- 引取計画残数量
      , g_forecast_planning_rec.delivery_forecast_quantity           -- 今後出庫予測数量
      , g_forecast_planning_rec.stock_forecast_quantity              -- 月末在庫予測数量
      , g_forecast_planning_rec.parent_item_no                       -- 親品目コード
      , cn_created_by                                                -- 作成者
      , cd_creation_date                                             -- 作成日
      , cn_last_updated_by                                           -- 最終更新者
      , cd_last_update_date                                          -- 最終更新日
      , cn_last_update_login                                         -- 最終更新ログイン
      , cn_request_id                                                -- 要求ID
      , cn_program_application_id                                    -- プログラムアプリケーションID
      , cn_program_id                                                -- プログラムID
      , cd_program_update_date                                       -- プログラム更新日
      );

      -- 正常件数カウントアップ
      gn_normal_cnt := gn_normal_cnt + 1;

    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
--■当処理では使用しない■■■■■■■■■■■■■■■■■■■■■■
--■    -- *** 共通関数例外ハンドラ ***
--■    WHEN global_api_expt THEN
--■      ov_errmsg  := lv_errmsg;
--■      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--■      ov_retcode := cv_status_error;
--■    -- *** 共通関数OTHERS例外ハンドラ ***
--■    WHEN global_api_others_expt THEN
--■      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--■      ov_retcode := cv_status_error;
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END insert_svf_work_tbl;
--
--★1.1 2009/03/04 Add Start
  /**********************************************************************************
   * Procedure Name   : svf_call
   * Description      : SVF起動(A-8)
   ***********************************************************************************/
  PROCEDURE svf_call(
     ov_errbuf   OUT VARCHAR2            --   エラー・メッセージ           --# 固定 #
   , ov_retcode  OUT VARCHAR2            --   リターン・コード             --# 固定 #
   , ov_errmsg   OUT VARCHAR2            --   ユーザー・エラー・メッセージ --# 固定 #
  )IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'svf_call'; -- プログラム名
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
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 対象件数がゼロ件の場合、
    -- SVF帳票共通関数(0件出力メッセージ)
    IF (gn_normal_cnt = 0) THEN
      gv_rep_no_data_msg := xxccp_svfcommon_pkg.no_data_msg;
    END IF;

    BEGIN
      -- SVF帳票共通関数(SVFコンカレントの起動）
      xxccp_svfcommon_pkg.submit_svf_request(
            ov_retcode      =>  lv_retcode                  -- リターンコード
          , ov_errbuf       =>  lv_errbuf                   -- エラーメッセージ
          , ov_errmsg       =>  lv_errmsg                   -- ユーザー・エラーメッセージ
          , iv_conc_name    =>  cv_pkg_name                 -- コンカレント名
          , iv_file_name    =>  cv_file_name                -- 出力ファイル名
          , iv_file_id      =>  cv_pkg_name                 -- 帳票ID
          , iv_output_mode  =>  cv_output_mode              -- 出力区分
          , iv_frm_file     =>  cv_frm_file                 -- フォーム様式ファイル名
          , iv_vrq_file     =>  cv_vrq_file                 -- クエリー様式ファイル名
          , iv_org_id       =>  fnd_global.org_id           -- ORG_ID
          , iv_user_name    =>  cn_created_by               -- ログイン・ユーザ名
          , iv_resp_name    =>  fnd_global.resp_name        -- ログイン・ユーザの職責名
          , iv_doc_name     =>  NULL                        -- 文書名
          , iv_printer_name =>  NULL                        -- プリンタ名
          , iv_request_id   =>  cn_request_id               -- 要求ID
          , iv_nodata_msg   =>  NULL                        -- データなしメッセージ
          , iv_svf_param1   =>  NULL                        -- svf可変パラメータ1
          , iv_svf_param2   =>  NULL                        -- svf可変パラメータ2
          , iv_svf_param3   =>  NULL                        -- svf可変パラメータ3
          , iv_svf_param4   =>  NULL                        -- svf可変パラメータ4
          , iv_svf_param5   =>  NULL                        -- svf可変パラメータ5
          , iv_svf_param6   =>  NULL                        -- svf可変パラメータ6
          , iv_svf_param7   =>  NULL                        -- svf可変パラメータ7
          , iv_svf_param8   =>  NULL                        -- svf可変パラメータ8
          , iv_svf_param9   =>  NULL                        -- svf可変パラメータ9
          , iv_svf_param10  =>  NULL                        -- svf可変パラメータ10
          , iv_svf_param11  =>  NULL                        -- svf可変パラメータ11
          , iv_svf_param12  =>  NULL                        -- svf可変パラメータ12
          , iv_svf_param13  =>  NULL                        -- svf可変パラメータ13
          , iv_svf_param14  =>  NULL                        -- svf可変パラメータ14
          , iv_svf_param15  =>  NULL                        -- svf可変パラメータ15
          );

      -- エラーハンドリング
      IF (lv_retcode <> cv_status_normal) THEN
        ov_retcode := cv_status_error;
        ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_application
                     ,iv_name         => cv_api_err_msg
                     ,iv_token_name1  => cv_api_err_msg_tkn_lbl1
                     ,iv_token_value1 => cv_api_err_msg_tkn_lbl1_val
                     ,iv_token_name2  => cv_api_err_msg_tkn_lbl2
                     ,iv_token_value2 => lv_errmsg
                     );
      END IF;

    EXCEPTION
      WHEN OTHERS THEN
        ov_retcode := cv_status_error;
        ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_application
                     ,iv_name         => cv_api_err_msg
                     ,iv_token_name1  => cv_api_err_msg_tkn_lbl1
                     ,iv_token_value1 => cv_api_err_msg_tkn_lbl1_val
                     ,iv_token_name2  => cv_api_err_msg_tkn_lbl2
                     ,iv_token_value2 => SQLERRM
                     );
    END;

    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
--■当処理では使用しない■■■■■■■■■■■■■■■■■■■■■■
--■    -- *** 共通関数例外ハンドラ ***
--■    WHEN global_api_expt THEN
--■      ov_errmsg  := lv_errmsg;
--■      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--■      ov_retcode := cv_status_error;
--■    -- *** 共通関数OTHERS例外ハンドラ ***
--■    WHEN global_api_others_expt THEN
--■      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--■      ov_retcode := cv_status_error;
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END svf_call;
--★1.1 2009/03/04 Add End
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_prod_class_code  IN     VARCHAR2,     -- 1.商品区分
    iv_base_code        IN     VARCHAR2,     -- 2.拠点
    ov_errbuf           OUT    VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT    VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT    VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    ln_which   NUMBER;
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
    gn_warn_cnt   := 0;

    -- パラメータを処理結果レポートとログに出力
    FOR ix IN 1..1 LOOP

      IF (ix=1) THEN
        ln_which := FND_FILE.LOG;
      ELSE
        ln_which := FND_FILE.OUTPUT;
      END IF;

      FND_FILE.PUT_LINE(ln_which,'');    -- 改行
      FND_FILE.PUT_LINE(ln_which,cv_pm_prod_class_code_tl || cv_pm_part  || iv_prod_class_code );
      FND_FILE.PUT_LINE(ln_which,cv_pm_base_code_tl       || cv_pm_part  || iv_base_code       );
      FND_FILE.PUT_LINE(ln_which,'');    -- 改行

    END LOOP;

    -- グローバル変数にパラメータを設定
    gv_prod_class_code := RTRIM( iv_prod_class_code );
    gv_base_code       := RTRIM( iv_base_code );
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    --        A-1 初期処理
    -- 1.WHO情報取得
    --   ※変数定義部で設定済み
    -- ===============================
    -- マスタ検索用日付設定
    gd_system_date             := TRUNC(SYSDATE);

    gd_this_month_start_day    := TO_DATE(TO_CHAR(gd_system_date,cv_target_month_format),cv_target_month_format);
    gd_this_month_end_day      := ADD_MONTHS(gd_this_month_start_day,1) - (1/24/60/60);
    gd_last_month_start_day    := ADD_MONTHS(gd_this_month_start_day,-1);
    gd_last_month_end_day      := ADD_MONTHS(gd_this_month_end_day  ,-1);
    gd_next_month_start_day    := ADD_MONTHS(gd_this_month_start_day,1);
    gd_next_month_end_day      := ADD_MONTHS(gd_this_month_end_day  ,1);
    gd_prev_day                := gd_system_date - (1/24/60/60);

    -- 計画、実績数量取得用日付設定
    gv_target_month            := TO_CHAR(ADD_MONTHS(gd_system_date,1),cv_target_month_format);
    gd_target_date_st_day      := TO_DATE(gv_target_month,cv_target_month_format);
    gd_target_date_ed_day      := TO_DATE(ADD_MONTHS(gd_target_date_st_day,1) - (1/24/60/60));
    gd_forecast_collect_st_day := ADD_MONTHS(gd_target_date_st_day,-3);
    gd_forecast_collect_ed_day := gd_target_date_ed_day;
    gd_result_collect_st_day1  := ADD_MONTHS(gd_target_date_st_day,-15);
    gd_result_collect_ed_day1  := ADD_MONTHS(gd_target_date_ed_day  ,-11);
    gd_result_collect_st_day2  := ADD_MONTHS(gd_target_date_st_day,-3);
    gd_result_collect_ed_day2  := ADD_MONTHS(gd_target_date_ed_day  ,-1);

    -- ヘッダー情報ワーククリア
    g_header_data_tbl := g_header_data_tbl_init;

--20090428_Ver1.2_T1_0645_SCS.Kikuchi_DEL_START
--    ---------------------------------------------------
--    --  マスタ品目組織の取得
--    ---------------------------------------------------
--    BEGIN
--      gn_mater_org_id  :=  TO_NUMBER(fnd_profile.value(cv_cmn_organization_id));
--    EXCEPTION
--      WHEN OTHERS THEN
--        gn_mater_org_id  :=  NULL;
--    END;
--    -- プロファイル：マスタ品目組織が取得出来ない＆エラーとなる場合
--    IF ( gn_mater_org_id IS NULL ) THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_msg_application
--                    ,iv_name         => cv_profile_chk_msg
--                    ,iv_token_name1  => cv_profile_chk_msg_tkn_lbl1
--                    ,iv_token_value1 => cv_profile_chk_msg_tkn_val1
--                   );
--      gn_error_cnt := gn_error_cnt + 1;
--      RAISE global_process_expt;
--    END IF;
--20090428_Ver1.2_T1_0645_SCS.Kikuchi_DEL_END
--20090428_Ver1.2_T1_0645_SCS.Kikuchi_ADD_START
    ---------------------------------------------------
    --  営業組織コードの取得
    ---------------------------------------------------
    BEGIN
      gv_sales_org_code := fnd_profile.value(cv_sales_org_code);
    EXCEPTION
      WHEN OTHERS THEN
        gv_sales_org_code := NULL;
    END;
    -- プロファイル：営業組織が取得出来ない場合
    IF ( gv_sales_org_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_application
                    ,iv_name         => cv_profile_chk_msg
                    ,iv_token_name1  => cv_profile_chk_msg_tkn_lbl1
                    ,iv_token_value1 => cv_profile_chk_msg_tkn_val1
                   );
      gn_error_cnt := gn_error_cnt + 1;
      RAISE internal_process_expt;
    END IF;
--20090428_Ver1.2_T1_0645_SCS.Kikuchi_ADD_END

    -- ================================================
    --  A-2,A-3 対象拠点・帳票ヘッダ情報取得
    -- ================================================
    get_header_data(
      lv_errbuf                            -- エラー・メッセージ           --# 固定 #
     ,lv_retcode                           -- リターン・コード             --# 固定 #
     ,lv_errmsg                            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;

    <<get_header_data_loop>>
    FOR header_ix IN 1..g_header_data_tbl.COUNT LOOP

      -- 明細情報ワーククリア
      g_detail_data_tbl       := g_detail_data_tbl_init;

      -- 登録用ワーククリア
      g_forecast_planning_rec := g_forecast_planning_rec_init;

      -- ================================================
      --  A-4 帳票明細情報取得
      -- ================================================
      get_detail_data(
        header_ix                            -- ヘッダ情報レコードINDEX
       ,lv_errbuf                            -- エラー・メッセージ           --# 固定 #
       ,lv_retcode                           -- リターン・コード             --# 固定 #
       ,lv_errmsg                            -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_error) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;

      <<get_detail_data_loop>>
      FOR detail_ix IN 1..g_detail_data_tbl.COUNT LOOP

        -- ======================================================
        --   A-5 数量振分け・データ保持
        -- ======================================================
        qty_editing_data_keep(
          in_header_index     => header_ix          -- 1.ヘッダ情報レコードINDEX
         ,in_detail_index     => detail_ix          -- 2.明細情報レコードINDEX
         ,ov_errbuf           => lv_errbuf          --   エラー・メッセージ           --# 固定 #
         ,ov_retcode          => lv_retcode         --   リターン・コード             --# 固定 #
         ,ov_errmsg           => lv_errmsg          --   ユーザー・エラー・メッセージ --# 固定 #
         );

        IF (lv_retcode = cv_status_error) THEN
          gn_error_cnt := gn_error_cnt + 1;
          RAISE global_process_expt;
        END IF;

        -- 最終レコード、または、次レコードの品目が異なる場合、ワークテーブル登録を行なう。
        IF  (  (detail_ix = g_detail_data_tbl.COUNT)
            OR (g_detail_data_tbl(detail_ix + 1).item_no <> g_detail_data_tbl(detail_ix).item_no) ) THEN

          -- ======================================================
          --  A-6 当月参考数量計算
          -- ======================================================
          reference_qty_calc(
            in_header_index     => header_ix          -- 1.ヘッダ情報レコードINDEX
           ,in_detail_index     => detail_ix          -- 2.明細情報レコードINDEX
           ,ov_errbuf           => lv_errbuf          -- エラー・メッセージ           --# 固定 #
           ,ov_retcode          => lv_retcode         -- リターン・コード             --# 固定 #
           ,ov_errmsg           => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
          );
          IF (lv_retcode = cv_status_error) THEN
            gn_error_cnt := gn_error_cnt + 1;
            RAISE global_process_expt;
          END IF;

          -- ======================================================
          --  A-7 引取計画立案表帳票ワークテーブルデータ登録
          -- ======================================================
          insert_svf_work_tbl(
            lv_errbuf                            -- エラー・メッセージ           --# 固定 #
           ,lv_retcode                           -- リターン・コード             --# 固定 #
           ,lv_errmsg                            -- ユーザー・エラー・メッセージ --# 固定 #
          );
          IF (lv_retcode = cv_status_error) THEN
            gn_error_cnt := gn_error_cnt + 1;
            RAISE global_process_expt;
          END IF;

          -- 登録用ワーククリア
          g_forecast_planning_rec := g_forecast_planning_rec_init;

        END IF;

      END LOOP get_detail_data_loop;

    END LOOP get_header_data_loop;

    -- 出力件数カウントアップ
    gn_target_cnt := gn_normal_cnt;

    -- SVF起動前にコミットを行なう
    COMMIT;
    
    -- ===============================
    --  A-8 SVF起動
    -- ===============================
--★1.1 2009/03/03 Add Start
    svf_call(
      lv_errbuf                            -- エラー・メッセージ           --# 固定 #
     ,lv_retcode                           -- リターン・コード             --# 固定 #
     ,lv_errmsg                            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      gn_normal_cnt := 0;
      gn_error_cnt  := gn_error_cnt + 1;
      RAISE internal_process_expt;
    END IF;
--★1.1 2009/03/03 Add End

    -- ===============================
    --  A-9 ワークテーブルデータ削除
    -- ===============================
    DELETE
    FROM    xxcop_rep_forecast_planning
    WHERE   request_id = cn_request_id
    ;

  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
--20090428_Ver1.2_T1_0645_SCS.Kikuchi_ADD_START
    WHEN internal_process_expt THEN
      ov_errmsg  := lv_errmsg;
      IF (lv_errbuf IS NULL) THEN
        ov_errbuf := NULL;
      ELSE
        ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      END IF;
      ov_retcode := cv_status_error;
--20090428_Ver1.2_T1_0645_SCS.Kikuchi_ADD_END
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
    errbuf              OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode             OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_prod_class_code  IN  VARCHAR2,      -- 1.商品区分
    iv_base_code        IN  VARCHAR2       -- 2.拠点
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
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       IV_WHICH   => 'LOG'              --★1.1 2009/03/04 Add
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
       iv_prod_class_code  -- 1.商品区分
      ,iv_base_code        -- 2.拠点
      ,lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,lv_retcode          -- リターン・コード             --# 固定 #
      ,lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
--★1.1 2009/03/04 Upd Start
--★      FND_FILE.PUT_LINE(
--★         which  => FND_FILE.OUTPUT
--★        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
--★      );
--★      FND_FILE.PUT_LINE(
--★         which  => FND_FILE.LOG
--★        ,buff => lv_errbuf --エラーメッセージ
--★      );

      -- ユーザエラーメッセージをログ出力
      IF (lv_errmsg IS NOT NULL) THEN
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => ''
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff =>   lv_errmsg
        );
      END IF;
      -- システムエラーメッセージをログ出力
      IF (lv_errbuf IS NOT NULL) THEN
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => ''
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff =>   xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_application
                    ,iv_name         => cv_others_err_msg
                    ,iv_token_name1  => cv_others_err_msg_tkn_lbl1
                    ,iv_token_value1 => cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf
                    )
        );
      END IF;
--★1.1 2009/03/04 Upd End
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT   --★1.1 2009/03/04 Upd
       which  => FND_FILE.LOG        --★1.1 2009/03/04 Upd
      ,buff   => ''
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT   --★1.1 2009/03/04 Upd
       which  => FND_FILE.LOG        --★1.1 2009/03/04 Upd
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
--       which  => FND_FILE.OUTPUT   --★1.1 2009/03/04 Upd
       which  => FND_FILE.LOG        --★1.1 2009/03/04 Upd
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
--       which  => FND_FILE.OUTPUT   --★1.1 2009/03/04 Upd
       which  => FND_FILE.LOG        --★1.1 2009/03/04 Upd
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
    --空行挿入
    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT   --★1.1 2009/03/04 Upd
       which  => FND_FILE.LOG        --★1.1 2009/03/04 Upd
      ,buff   => ''
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
--       which  => FND_FILE.OUTPUT   --★1.1 2009/03/04 Upd
       which  => FND_FILE.LOG        --★1.1 2009/03/04 Upd
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
END XXCOP004A05R;
/
