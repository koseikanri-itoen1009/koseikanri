create or replace
PACKAGE BODY XXCOI002A04R
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOI002A04R(body)
 * Description      : 製品廃却伝票
 * MD.050           : 製品廃却伝票 MD050_COI_002_A04
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  del_work               ワークテーブルデータ削除(A-6)
 *  svf_request            SVF起動(A-5)
 *  ins_work               ワークテーブルデータ登録(A-4)
 *  get_kuragae_data       製品廃却伝票データ取得(A-3)
 *  get_base_data          拠点情報取得処理(A-2)
 *  init                   初期処理(A-1)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/09/05    1.0   K.Furuyama       新規作成
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
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
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
  get_value_expt            EXCEPTION;    -- 値取得エラー
  svf_request_err_expt      EXCEPTION;    -- SVF起動APIエラー
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name          CONSTANT VARCHAR2(100) := 'XXCOI002A04R';   -- パッケージ名
  cv_app_name          CONSTANT VARCHAR2(5)   := 'XXCOI';          -- アプリケーション短縮名
  cv_0                 CONSTANT VARCHAR2(1)   := '0';              -- 定数
  cv_1                 CONSTANT VARCHAR2(1)   := '1';              -- 定数
  cv_2                 CONSTANT VARCHAR2(1)   := '2';              -- 定数
  cv_log               CONSTANT VARCHAR2(3)   := 'LOG';            -- コンカレントヘッダ出力先
  cv_ymd               CONSTANT VARCHAR2(20)  := 'YYYYMMDD';       -- 日付(YYYYMMDD)
  cv_ym                CONSTANT VARCHAR2(10)  := 'YYYYMM';         -- 日付(YYYYMM)
--
  -- メッセージ
  cv_msg_xxcoi00008  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00008';   -- 0件メッセージ
  cv_msg_xxcoi10003  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10003';   -- 日付入力エラー
  cv_msg_xxcoi00005  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00005';   -- 在庫組織コード取得エラー
  cv_msg_xxcoi00006  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00006';   -- 在庫組織ID取得エラー
  cv_msg_xxcoi00011  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00011';   -- 業務日付取得エラー
  cv_msg_xxcoi00012  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00012';   -- 取引タイプ取得エラー
  cv_msg_xxcoi00022  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00022';   -- 取引タイプ名取得エラー
  cv_msg_xxcoi00030  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00030';   -- マスタ組織コード取得エラー
  cv_msg_xxcoi00031  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00031';   -- マスタ組織ID取得エラー
  cv_msg_xxcoi10070  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10070';   -- 日付範囲(日)エラー
  cv_msg_xxcoi10092  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10092';   -- 所属拠点取得エラー
  cv_msg_xxcoi10067  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10067';   -- パラメータ.年月日メッセージ
  cv_msg_xxcoi10307  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10307';   -- パラメータ.拠点メッセージ
  cv_msg_xxcoi10293  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10293';   -- 営業原価取得失敗エラー
--
  -- トークン名
  cv_token_pro                CONSTANT VARCHAR2(30) := 'PRO_TOK';
  cv_token_org_code           CONSTANT VARCHAR2(30) := 'ORG_CODE_TOK';
  cv_token_mst_org_code       CONSTANT VARCHAR2(30) := 'MST_ORG_CODE_TOK';
  cv_token_date               CONSTANT VARCHAR2(30) := 'P_DATE';
  cv_token_base_code          CONSTANT VARCHAR2(30) := 'P_BASE_CODE';
  cv_token_lookup_type        CONSTANT VARCHAR2(20) := 'LOOKUP_TYPE';            -- 参照タイプ
  cv_token_lookup_code        CONSTANT VARCHAR2(20) := 'LOOKUP_CODE';            -- 参照コード
  cv_token_item_code          CONSTANT VARCHAR2(20) := 'ITEM_CODE';              -- 品目コード
  cv_token_tran_type          CONSTANT VARCHAR2(20) := 'TRANSACTION_TYPE_TOK';   -- 取引タイプ
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 入力パラメータ格納用レコード変数
  TYPE gr_param_rec  IS RECORD(
      year_month        VARCHAR2(7)       -- 01 : 処理年月      (必須)
     ,a_day             VARCHAR2(2)       -- 02 : 処理日        (任意)
     ,kyoten_code       VARCHAR2(4)       -- 03 : 拠点          (任意)
     ,output_dpt        VARCHAR2(1)       -- 04 : 帳票出力場所  (必須)
    );
--
  -- 拠点情報格納用レコード変数
  TYPE gr_base_num_rec IS RECORD
    (
      hca_cust_num                   hz_cust_accounts.account_number%TYPE    -- 拠点コード
    );
--
  --  拠点情報格納用テーブル
  TYPE gt_base_num_ttype IS TABLE OF gr_base_num_rec INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_process_date           DATE;                                             -- 業務日付
  gv_base_code              hz_cust_accounts.account_number%TYPE;             -- 拠点コード
  -- カウンタ
  gn_base_cnt               NUMBER;                                           -- 拠点コード件数
  gn_base_loop_cnt          NUMBER;                                           -- 拠点コードループカウンタ
  gn_haikyaku_cnt           NUMBER;                                           -- 製品廃却伝票情報件数
  gn_haikyaku_loop_cnt      NUMBER;                                           -- 製品廃却伝票情報ループカウンタ
  gn_organization_id        mtl_parameters.organization_id%TYPE;              -- 在庫組織ID
  gn_mst_organization_id    mtl_parameters.organization_id%TYPE;              -- マスタ組織ID
  gv_transaction_type_name  mtl_transaction_types.transaction_type_name%TYPE; -- 取引タイプ名
  -- 
  gr_param                  gr_param_rec;
  gt_base_num_tab           gt_base_num_ttype;
  gd_trans_date_from        DATE;                                             -- 取引日FROM
  gd_trans_date_to          DATE;                                             -- 取引日TO
--
  /**********************************************************************************
   * Procedure Name   : del_work
   * Description      : ワークテーブルデータ削除(A-6)
   ***********************************************************************************/
  PROCEDURE del_work(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_work'; -- プログラム名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***    ワークテーブルデータ削除     ***
    -- ***************************************
--
    --帳票用ワークテーブルから対象データを削除
    DELETE xxcoi_rep_haikyaku_ship xrh
    WHERE  xrh.request_id = cn_request_id
    ;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
  END del_work;
--  
  /**********************************************************************************
   * Procedure Name   : svf_request
   * Description      : SVF起動(A-5)
   ***********************************************************************************/
  PROCEDURE svf_request(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'svf_request'; -- プログラム名
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
    cv_output_mode  CONSTANT VARCHAR2(1)  := '1';                    -- 出力区分(PDF出力)
    cv_frm_file     CONSTANT VARCHAR2(30) := 'XXCOI002A04S.xml';     -- フォーム様式ファイル名
    cv_vrq_file     CONSTANT VARCHAR2(30) := 'XXCOI002A04S.vrq';     -- クエリー様式ファイル名
    cv_api_name     CONSTANT VARCHAR2(7)  := 'SVF起動';              -- SVF起動API名
--
    -- エラーコード
    cv_msg_xxcoi00010  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00010';  -- APIエラー
--
    -- トークン名
    cv_token_name_1  CONSTANT VARCHAR2(30) := 'API_NAME';
--
    -- *** ローカル変数 ***
    ld_date       VARCHAR2(8);   -- 日付
    lv_file_name  VARCHAR2(100); -- 出力ファイル名
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
    -- ***         SVFの起動               ***
    -- ***************************************
--
    -- 日付書式変換
    ld_date := TO_CHAR( cd_creation_date, cv_ymd );
--
    -- 出力ファイル名
    lv_file_name := cv_pkg_name || ld_date || TO_CHAR(cn_request_id) || '.pdf';
--
    --SVF起動処理
      xxccp_svfcommon_pkg.submit_svf_request(
        ov_retcode      => lv_retcode             -- リターンコード
       ,ov_errbuf       => lv_errbuf              -- エラーメッセージ
       ,ov_errmsg       => lv_errmsg              -- ユーザー・エラーメッセージ
       ,iv_conc_name    => cv_pkg_name            -- コンカレント名
       ,iv_file_name    => lv_file_name           -- 出力ファイル名
       ,iv_file_id      => cv_pkg_name            -- 帳票ID
       ,iv_output_mode  => cv_output_mode         -- 出力区分
       ,iv_frm_file     => cv_frm_file            -- フォーム様式ファイル名
       ,iv_vrq_file     => cv_vrq_file            -- クエリー様式ファイル名
       ,iv_org_id       => fnd_global.org_id      -- ORG_ID
       ,iv_user_name    => fnd_global.user_name   -- ログイン・ユーザ名
       ,iv_resp_name    => fnd_global.resp_name   -- ログイン・ユーザの職責名
       ,iv_doc_name     => NULL                   -- 文書名
       ,iv_printer_name => NULL                   -- プリンタ名
       ,iv_request_id   => cn_request_id          -- 要求ID
       ,iv_nodata_msg   => NULL                   -- データなしメッセージ
      );
--
    --==============================================================
    --エラーメッセージ出力
    --==============================================================
    IF lv_retcode <> cv_status_normal THEN
      RAISE svf_request_err_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** SVF起動APIエラー ***
    WHEN svf_request_err_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                    , iv_name         => cv_msg_xxcoi00010
                    , iv_token_name1  => cv_token_name_1
                    , iv_token_value1 => cv_api_name
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END svf_request;
--
  /**********************************************************************************
   * Procedure Name   : ins_work
   * Description      : ワークテーブルデータ登録(A-4)
   ***********************************************************************************/
  PROCEDURE ins_work(
    it_out_base_code           IN hz_cust_accounts.account_number%TYPE,                -- 拠点
    it_out_base_name           IN hz_cust_accounts.account_name%TYPE,                  -- 拠点名
    it_transaction_date        IN mtl_material_transactions.transaction_date%TYPE,     -- 取引日
    it_item_code               IN mtl_system_items_b.segment1%TYPE,                    -- 商品
    it_item_name               IN xxcmn_item_mst_b.item_short_name%TYPE,               -- 商品名
    it_slip_no                 IN mtl_material_transactions.attribute1%TYPE,           -- 伝票No
    it_transaction_qty         IN mtl_material_transactions.primary_quantity%TYPE,     -- 基準単位数量
    iv_trading_cost            IN NUMBER,                                              -- 営業原価額
    iv_nodata_msg              IN VARCHAR2,                                            -- ０件メッセージ
    ov_errbuf                  OUT VARCHAR2,                                           -- エラー・メッセージ           --# 固定 #
    ov_retcode                 OUT VARCHAR2,                                           -- リターン・コード             --# 固定 #
    ov_errmsg                  OUT VARCHAR2)                                           -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_work'; -- プログラム名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***    ワークテーブルデータ登録     ***
    -- ***************************************
--
    --製品廃却伝票帳票ワークテーブル登録処理
    INSERT INTO xxcoi_rep_haikyaku_ship(
       target_term
      ,base_code
      ,base_name
      ,transaction_date
      ,item_code
      ,item_name
      ,slip_no
      ,transaction_qty
      ,trading_cost
      ,nodata_msg
      --WHOカラム
      ,created_by
      ,creation_date
      ,last_updated_by
      ,last_update_date
      ,last_update_login
      ,request_id
      ,program_application_id
      ,program_id
      ,program_update_date
    )VALUES(
       gr_param.year_month||gr_param.a_day          -- 対象年月日
      ,it_out_base_code                             -- 拠点
      ,it_out_base_name                             -- 拠点名
      ,TO_CHAR(it_transaction_date,cv_ymd)      -- 取引日
      ,it_item_code                                 -- 商品
      ,it_item_name                                 -- 商品名
      ,it_slip_no                                   -- 伝票No
      ,it_transaction_qty                           -- 取引数量
      ,iv_trading_cost                              -- 営業原価額
      ,iv_nodata_msg                                -- ０件メッセージ
      --WHOカラム
      ,cn_created_by
      ,sysdate
      ,cn_last_updated_by
      ,sysdate
      ,cn_last_update_login
      ,cn_request_id
      ,cn_program_application_id
      ,cn_program_id
      ,sysdate
     );
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
  END ins_work;
--
  /**********************************************************************************
   * Procedure Name   : get_haikyaku_data（ループ部）
   * Description      : 製品廃却伝票データ取得(A-3)
   ***********************************************************************************/
  PROCEDURE get_haikyaku_data(
    gn_base_loop_cnt IN NUMBER,       --   カウント
    ov_errbuf        OUT VARCHAR2,    --   エラー・メッセージ                --# 固定 #
    ov_retcode       OUT VARCHAR2,    --   リターン・コード                  --# 固定 #
    ov_errmsg        OUT VARCHAR2)    --   ユーザー・エラー・メッセージ      --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_haikyaku_data'; -- プログラム名
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
    cv_flag                        CONSTANT VARCHAR2(1)  := 'Y';                      -- 使用可能フラグ 'Y'
--
    -- 参照タイプ
    -- ユーザー定義取引タイプ名称
    cv_tran_type                   CONSTANT VARCHAR2(30)  := 'XXCOI1_TRANSACTION_TYPE_NAME';
--
    -- 参照コード
    cv_tran_type_haikyaku          CONSTANT VARCHAR2(3)   := '130';  -- 取引タイプコード 廃却
    cv_tran_type_haikyaku_b        CONSTANT VARCHAR2(3)   := '140';  -- 取引タイプコード 廃却振戻
--
    -- *** ローカル変数 ***
    lv_tran_type_haikyaku          mtl_transaction_types.transaction_type_name%TYPE;   -- 取引タイプ名 廃却
    ln_tran_type_haikyaku          mtl_transaction_types.transaction_type_id%TYPE;     -- 取引タイプID 廃却
    lv_tran_type_haikyaku_b        mtl_transaction_types.transaction_type_name%TYPE;   -- 取引タイプ名 廃却振戻
    ln_tran_type_haikyaku_b        mtl_transaction_types.transaction_type_id%TYPE;     -- 取引タイプID 廃却振戻
    ln_set_unit_price              xxwip_drink_trans_deli_chrgs.setting_amount%TYPE;   -- 設定単価
    lv_discrete_cost               xxcmm_system_items_b_hst.discrete_cost%TYPE;        -- 営業原価
    ln_discrete_cost               NUMBER;                                             -- 営業原価(型変換) 
    ln_cnt                         NUMBER       DEFAULT  0;                            -- ループカウンタ
    lv_zero_message                VARCHAR2(30) DEFAULT  NULL;                         -- ゼロ件メッセージ
    ln_sql_cnt                     NUMBER       DEFAULT  0;
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 製品廃却伝票情報
    CURSOR info_haikyaku_cur(
                            ln_tran_type_haikyaku     NUMBER
                           ,ln_tran_type_haikyaku_b   NUMBER)
    IS
      --廃却
      SELECT  mmt.transaction_id                                        -- 取引ID
             ,msi.attribute7                  out_base_code             -- 拠点 
             ,SUBSTRB(hca.account_name,1,8)   out_base_name             -- 拠点名
             ,mmt.transaction_date            transaction_date          -- 取引日
             ,mmt.attribute1                  slip_no                   -- 伝票No
             ,mmt.inventory_item_id           inventory_item_id         -- 品目ID
             ,msib.segment1                   item_no                   -- 品目コード
             ,ximb.item_short_name            item_short_name           -- 略称
             ,mmt.primary_quantity            transaction_qty           -- 基準単位数量
      FROM    mtl_material_transactions  mmt                            -- 資材取引
             ,mtl_transaction_types      mtt                            -- 取引タイプマスタ
             ,mtl_secondary_inventories  msi                            -- 保管場所マスタ
             ,hz_cust_accounts           hca                            -- 顧客マスタ
             ,mtl_system_items_b         msib                           -- 品目マスタ
             ,ic_item_mst_b              iimb                           -- OPM品目マスタ  
             ,xxcmn_item_mst_b           ximb                           -- OPM品目アドオンマスタ
      WHERE  mmt.transaction_type_id             =  mtt.transaction_type_id
        AND  mmt.transaction_type_id IN (ln_tran_type_haikyaku,ln_tran_type_haikyaku_b)
        AND  mmt.transaction_date               >=  gd_trans_date_from
        AND  mmt.transaction_date               <   gd_trans_date_to
        AND  mmt.subinventory_code               =  msi.secondary_inventory_name
        AND  mmt.organization_id                 =  msi.organization_id
        AND  msi.attribute7                      =  gt_base_num_tab(gn_base_loop_cnt).hca_cust_num
        AND  hca.account_number                  =  msi.attribute7
        AND  hca.customer_class_code             =  cv_1
        AND  msib.inventory_item_id              =  mmt.inventory_item_id
        AND  msib.organization_id                =  gn_organization_id
        AND  msib.segment1                       =  iimb.item_no
        AND  iimb.item_id                        =  ximb.item_id
        AND  mmt.transaction_date  BETWEEN ximb.start_date_active
                                   AND     NVL(ximb.end_date_active, mmt.transaction_date)
      ;
--
    -- ローカル・レコード
    lr_info_haikyaku_rec info_haikyaku_cur%ROWTYPE;
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================
    -- 取引タイプ名取得：廃却
    -- ===============================
    lv_tran_type_haikyaku := xxcoi_common_pkg.get_meaning(cv_tran_type,cv_tran_type_haikyaku);
    --
    -- リターンコードがNULLの場合はエラー
    IF ( lv_tran_type_haikyaku IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00022
                     ,iv_token_name1  => cv_token_lookup_type
                     ,iv_token_value1 => cv_tran_type
                     ,iv_token_name2  => cv_token_lookup_code
                     ,iv_token_value2 => cv_tran_type_haikyaku
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 取引タイプID取得：廃却
    -- ===============================
    ln_tran_type_haikyaku := xxcoi_common_pkg.get_transaction_type_id(lv_tran_type_haikyaku);
    --
    -- リターンコードがNULLの場合はエラー
    IF ( ln_tran_type_haikyaku IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00012
                     ,iv_token_name1  => cv_token_tran_type
                     ,iv_token_value1 => lv_tran_type_haikyaku
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 取引タイプ名取得：廃却振戻
    -- ===============================
    lv_tran_type_haikyaku_b := xxcoi_common_pkg.get_meaning(cv_tran_type,cv_tran_type_haikyaku_b);
    --
    -- リターンコードがNULLの場合はエラー
    IF ( lv_tran_type_haikyaku_b IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00022
                     ,iv_token_name1  => cv_token_lookup_type
                     ,iv_token_value1 => cv_tran_type
                     ,iv_token_name2  => cv_token_lookup_code
                     ,iv_token_value2 => cv_tran_type_haikyaku_b
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 取引タイプID取得：廃却振戻
    -- ===============================
    ln_tran_type_haikyaku_b := xxcoi_common_pkg.get_transaction_type_id(lv_tran_type_haikyaku_b);
    --
    -- リターンコードがNULLの場合はエラー
    IF ( ln_tran_type_haikyaku_b IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00012
                     ,iv_token_name1  => cv_token_tran_type
                     ,iv_token_value1 => lv_tran_type_haikyaku_b
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ***************************************
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
    -- 製品廃却伝票情報件数初期化
    gn_haikyaku_cnt := 0;
--
    -- カーソルオープン
    OPEN  info_haikyaku_cur(
                           ln_tran_type_haikyaku
                          ,ln_tran_type_haikyaku_b);
--
    <<ins_work_loop>>
    LOOP
    FETCH info_haikyaku_cur INTO lr_info_haikyaku_rec;
    EXIT WHEN info_haikyaku_cur%NOTFOUND;
--
    -- 対象件数カウント
    gn_target_cnt :=  gn_target_cnt + 1;
    -- 営業原価初期化
    ln_discrete_cost := 0;
--
      -- ==============================================
      --  営業原価取得
      -- ==============================================
      xxcoi_common_pkg.get_discrete_cost(in_item_id       => lr_info_haikyaku_rec.inventory_item_id  -- 品目ID
                                        ,in_org_id        => gn_mst_organization_id                  -- 在庫組織ID
                                        ,id_target_date   => lr_info_haikyaku_rec.transaction_date   -- 取引日
                                        ,ov_discrete_cost => lv_discrete_cost                        -- 営業原価
                                        ,ov_retcode       => lv_retcode                              -- リターンコード
                                        ,ov_errbuf        => lv_errbuf                               -- エラーメッセージ
                                        ,ov_errmsg        => lv_errmsg);                             -- エラーメッセージ
--
      IF (lv_retcode <> cv_status_normal) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcoi10293
                      );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      -- 営業原価額の符号変換
      ln_discrete_cost := ROUND(TO_NUMBER(lv_discrete_cost)*lr_info_haikyaku_rec.transaction_qty);
--
      -- ==============================================
      --  ワークテーブルデータ登録(A-4)
      -- ==============================================
      ins_work(
          lr_info_haikyaku_rec.out_base_code             -- 拠点
         ,lr_info_haikyaku_rec.out_base_name             -- 拠点名
         ,lr_info_haikyaku_rec.transaction_date          -- 取引日
         ,lr_info_haikyaku_rec.item_no                   -- 商品
         ,lr_info_haikyaku_rec.item_short_name           -- 略称
         ,lr_info_haikyaku_rec.slip_no                   -- 伝票No
         ,NVL(lr_info_haikyaku_rec.transaction_qty,0)*-1 -- 取引数量
         ,ln_discrete_cost*-1                            -- 営業原価額
         ,NULL                                           -- ０件メッセージ
         ,lv_errbuf                                      -- エラー・メッセージ           --# 固定 #
         ,lv_retcode                                     -- リターン・コード             --# 固定 #
         ,lv_errmsg                                      -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt ;
      END IF;
--
    END LOOP;
--
    -- カーソルクローズ
    CLOSE info_haikyaku_cur;
--
    -- コミット処理
    COMMIT;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- カーソルがOPENしている場合
      IF ( info_haikyaku_cur%ISOPEN ) THEN
        CLOSE info_haikyaku_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルがOPENしている場合
      IF ( info_haikyaku_cur%ISOPEN ) THEN
        CLOSE info_haikyaku_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルがOPENしている場合
      IF ( info_haikyaku_cur%ISOPEN ) THEN
        CLOSE info_haikyaku_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルがOPENしている場合
      IF ( info_haikyaku_cur%ISOPEN ) THEN
        CLOSE info_haikyaku_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_haikyaku_data;
--
  /**********************************************************************************
   * Procedure Name   : get_base_data
   * Description      : 拠点情報取得処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_base_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_base_data'; -- プログラム名
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
    -- 拠点情報(管理元拠点)
    CURSOR info_base1_cur
    IS
      SELECT hca.account_number account_num                         -- 顧客コード
      FROM   hz_cust_accounts hca                                   -- 顧客マスタ
            ,xxcmm_cust_accounts xca                                -- 顧客追加情報アドオンマスタ
      WHERE  hca.cust_account_id = xca.customer_id
        AND  hca.customer_class_code = cv_1
        AND  hca.account_number = NVL( gr_param.kyoten_code,hca.account_number )
        AND  xca.management_base_code = gv_base_code
      ORDER BY hca.account_number
    ;
--
    -- 拠点情報
    CURSOR info_base2_cur
    IS
      SELECT  hca.account_number account_num                         -- 顧客コード
        FROM  hz_cust_accounts hca                                   -- 顧客マスタ
       WHERE  hca.customer_class_code = cv_1
         AND  hca.account_number = NVL( gr_param.kyoten_code,hca.account_number )
       ORDER BY hca.account_number
    ;
--
    -- *** ローカル・レコード ***
    lr_info_base1_rec   info_base1_cur%ROWTYPE;
    lr_info_base2_rec   info_base2_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 管理元拠点で起動の時
    IF ( gr_param.output_dpt = cv_2 ) THEN
      OPEN info_base1_cur;
--
      -- レコード読み込み
      FETCH info_base1_cur BULK COLLECT INTO gt_base_num_tab;
      -- 拠点コード件数
      gn_base_cnt := gt_base_num_tab.COUNT;
      -- カーソルクローズ
      CLOSE info_base1_cur;
--
    -- 拠点で起動の時
    ELSIF ( gr_param.output_dpt = cv_1 ) THEN
      OPEN info_base2_cur;
      -- レコード読み込み
      FETCH info_base2_cur BULK COLLECT INTO gt_base_num_tab;
      -- 拠点コード件数
      gn_base_cnt := gt_base_num_tab.COUNT;
      -- カーソルクローズ
      CLOSE info_base2_cur;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- カーソルがOPENしている場合
      IF ( info_base1_cur%ISOPEN ) THEN
        CLOSE info_base1_cur;
      ELSIF ( info_base2_cur%ISOPEN ) THEN
        CLOSE info_base2_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルがOPENしている場合
      IF ( info_base1_cur%ISOPEN ) THEN
        CLOSE info_base1_cur;
      ELSIF ( info_base2_cur%ISOPEN ) THEN
        CLOSE info_base2_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルがOPENしている場合
      IF ( info_base1_cur%ISOPEN ) THEN
        CLOSE info_base1_cur;
      ELSIF ( info_base2_cur%ISOPEN ) THEN
        CLOSE info_base2_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルがOPENしている場合
      IF ( info_base1_cur%ISOPEN ) THEN
        CLOSE info_base1_cur;
      ELSIF ( info_base2_cur%ISOPEN ) THEN
        CLOSE info_base2_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_base_data;
--
    /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2,      --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,      --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)      --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100)  := 'init';                      -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);       -- エラー・メッセージ
    lv_retcode VARCHAR2(1);          -- リターン・コード
    lv_errmsg  VARCHAR2(5000);       -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- 定数
    cv_01                   CONSTANT VARCHAR2(2)    := '01';                            -- 妥当性チェック用(1月)
    cv_mstorg_code          CONSTANT VARCHAR2(30)   := 'XXCOI1_MST_ORGANIZATION_CODE';  -- プロファイル名(マスタ組織コード)
    cv_profile_name         CONSTANT VARCHAR2(24)   := 'XXCOI1_ORGANIZATION_CODE';      -- プロファイル名(在庫組織コード)
--
    -- *** ローカル変数 ***
    lv_organization_code mtl_parameters.organization_code%TYPE;      -- 在庫組織コード
    lv_mst_organization_code mtl_parameters.organization_code%TYPE;  -- マスタ組織コード
    ld_date                 DATE;
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- =====================================
    -- 業務日付取得(共通関数)
    -- =====================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    --
      -- 業務日付が取得できない場合はエラー
      IF ( gd_process_date IS NULL ) THEN
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcoi00011
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    -- =====================================
    -- パラメータ妥当性チェック(日)
    -- =====================================
    -- パラメータ.日がNULLでない場合
    IF gr_param.a_day IS NOT NULL THEN
      --
      IF (   (TO_NUMBER(gr_param.a_day) < 1)
          OR (TO_NUMBER(gr_param.a_day) > 31)
         )
      THEN
      --
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcoi10070
                    );
        lv_errbuf := lv_errmsg;
        RAISE get_value_expt;
      ELSE 
        -- パラメータ.日が1桁だったら、前に0を付加
        IF length(gr_param.a_day) = 1 THEN
          gr_param.a_day := cv_0||gr_param.a_day;
        END IF;
        -- 
      -- パラメータ.年月とパラメータ.日を結合し日付の妥当性チェックを行う
      ld_date := TO_DATE((gr_param.year_month||gr_param.a_day),cv_ymd);
      --
      -- パラメータ.年月とパラメータ.日を結合し、業務日付と比較
        IF ( TO_CHAR( ( gd_process_date ), cv_ymd ) < 
            ( gr_param.year_month||gr_param.a_day ) ) THEN
          -- エラーメッセージ取得
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_xxcoi10003
                      );
          lv_errbuf := lv_errmsg;
          RAISE get_value_expt;
        END IF;
      END IF;
    END IF;
--
    -- パラメータ.日がNULLの場合
    IF gr_param.a_day IS NULL THEN
      -- パラメータ.年月と業務日付(年月)を比較
      IF ( TO_CHAR( ( gd_process_date ), cv_ym ) < ( gr_param.year_month ) ) THEN
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcoi10003
                    );
        lv_errbuf := lv_errmsg;
        RAISE get_value_expt;
      END IF;
    END IF;
--
    -- =====================================
    -- プロファイル値取得(在庫組織コード)
    -- =====================================
    lv_organization_code := FND_PROFILE.VALUE(cv_profile_name);
    IF ( lv_organization_code IS NULL ) THEN
      -- エラーメッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg( 
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00005
                     ,iv_token_name1  => cv_token_pro
                     ,iv_token_value1 => cv_profile_name
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- =====================================
    -- 在庫組織ID取得
    -- =====================================
    gn_organization_id := xxcoi_common_pkg.get_organization_id(lv_organization_code);
    IF ( gn_organization_id IS NULL ) THEN
      -- エラーメッセージ取得
      lv_errmsg := xxcmn_common_pkg.get_msg( 
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00006
                     ,iv_token_name1  => cv_token_org_code
                     ,iv_token_value1 => lv_organization_code
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- =====================================
    -- プロファイル値取得(マスタ組織コード)
    -- =====================================
    lv_mst_organization_code := FND_PROFILE.VALUE(cv_mstorg_code);
    IF ( lv_mst_organization_code IS NULL ) THEN
      -- エラーメッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg( 
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00030
                     ,iv_token_name1  => cv_token_pro
                     ,iv_token_value1 => cv_mstorg_code
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- =====================================
    -- マスタ品目組織ID取得
    -- =====================================
    gn_mst_organization_id := xxcoi_common_pkg.get_organization_id(lv_mst_organization_code);
    IF ( gn_mst_organization_id IS NULL ) THEN
      -- エラーメッセージ取得
      lv_errmsg := xxcmn_common_pkg.get_msg( 
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00031
                     ,iv_token_name1  => cv_token_mst_org_code
                     ,iv_token_value1 => lv_mst_organization_code
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- =====================================
    -- 所属拠点取得
    -- =====================================
    gv_base_code := xxcoi_common_pkg.get_base_code( 
                        in_user_id     => cn_created_by     -- ユーザーID
                       ,id_target_date => gd_process_date); -- 対象日
    IF ( gv_base_code IS NULL ) THEN
      -- エラーメッセージ取得
      lv_errmsg := xxcmn_common_pkg.get_msg( 
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi10092);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- コンカレント入力パラメータ出力
    --==============================================================
    -- パラメータ.年月日
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  =>  cv_app_name
                    ,iv_name         =>  cv_msg_xxcoi10067
                    ,iv_token_name1  => cv_token_date
                    ,iv_token_value1 => gr_param.year_month||gr_param.a_day
                  );
    fnd_file.put_line(
      which  => FND_FILE.LOG
    , buff   => gv_out_msg
    );
--
    -- パラメータ.拠点
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  =>  cv_app_name
                    ,iv_name         =>  cv_msg_xxcoi10307
                    ,iv_token_name1  => cv_token_base_code
                    ,iv_token_value1 => gr_param.kyoten_code
                  );
    fnd_file.put_line(
      which  => FND_FILE.LOG
    , buff   => gv_out_msg
    );
--
    --  取引日はXX以上(>=)、XX未満(<)で範囲指定する
    -- ===============================
    -- 対象取引日指定
    -- ===============================
    IF  (gr_param.a_day IS NULL)  THEN
      --  月指定のみの場合、指定月１日から翌月１日
      gd_trans_date_from    :=  TRUNC(TO_DATE(gr_param.year_month || cv_01, cv_ymd));
      gd_trans_date_to      :=  ADD_MONTHS(gd_trans_date_from, 1);
    ELSE
      --  日付指定ありの場合、指定年月日から翌日
      gd_trans_date_from    :=  TRUNC(TO_DATE(gr_param.year_month || gr_param.a_day, cv_ymd));
      gd_trans_date_to      :=  gd_trans_date_from + 1;
    END IF;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
    --*** 値エラー ***
    WHEN get_value_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_year_month        IN  VARCHAR2,         --   1.年月
    iv_day               IN  VARCHAR2,         --   2.日
    iv_kyoten            IN  VARCHAR2,         --   3.拠点
    iv_output_dpt        IN  VARCHAR2,         --   4.帳票出力場所
    ov_errbuf            OUT VARCHAR2,         --   エラー・メッセージ           --# 固定 #
    ov_retcode           OUT VARCHAR2,         --   リターン・コード             --# 固定 #
    ov_errmsg            OUT VARCHAR2)         --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_nodata_msg VARCHAR2(50);
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
    -- <カーソル名>レコード型
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
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- =====================================================
    -- パラメータ値の格納
    -- =====================================================
--
    gr_param.year_month        := SUBSTRB(iv_year_month,1,4)
                                  ||SUBSTRB(iv_year_month,6,7);  -- 01 : 処理年月      (必須)
    gr_param.a_day             := iv_day;                        -- 02 : 処理日        (任意)
    gr_param.kyoten_code       := iv_kyoten;                     -- 03 : 拠点         （任意)
    gr_param.output_dpt        := iv_output_dpt;                 -- 04 : 出力場所      (必須)
--
    -- =====================================================
    -- 初期処理(A-1)
    -- =====================================================
    init(
        lv_errbuf            -- エラー・メッセージ           --# 固定 #
      , lv_retcode           -- リターン・コード             --# 固定 #
      , lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
      );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt ;
    END IF;
--
    -- =====================================================
    -- 拠点情報取得処理(A-2)
    -- =====================================================
    get_base_data(
        lv_errbuf            -- エラー・メッセージ           --# 固定 #
      , lv_retcode           -- リターン・コード             --# 固定 #
      , lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 拠点情報が１件以上取得出来た場合
    IF ( gn_base_cnt > 0 ) THEN
--
      -- 拠点単位ループ開始
      <<gt_param_tab_loop>>
       FOR gn_base_loop_cnt IN 1 .. gn_base_cnt LOOP
--
         -- =====================================================
         -- 製品廃却伝票データ取得(A-3)
         -- =====================================================
         get_haikyaku_data(
             gn_base_loop_cnt
            ,lv_errbuf            -- エラー・メッセージ           --# 固定 #
            ,lv_retcode           -- リターン・コード             --# 固定 #
            ,lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
         );
         IF ( lv_retcode = cv_status_error ) THEN
           -- エラー処理
           RAISE global_process_expt ;
         END IF;
--
       END LOOP gt_param_tab_loop;
    END IF;
--
    -- 出力対象件数が0件の場合、ワークテーブルにパラメータ情報のみを登録
    IF (gn_target_cnt = 0) THEN
--
      -- 0件メッセージの取得
      lv_nodata_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name
                          ,iv_name         => cv_msg_xxcoi00008
                         );
--
      -- ==============================================
      --  ワークテーブルデータ登録(A-4)
      -- ==============================================
      ins_work(
          NULL                                      -- 拠点
         ,NULL                                      -- 拠点名
         ,NULL                                      -- 取引日
         ,NULL                                      -- 商品
         ,NULL                                      -- 商品名
         ,NULL                                      -- 伝票No
         ,NULL                                      -- 取引数量
         ,NULL                                      -- 営業原価額
         ,lv_nodata_msg                             -- 0件メッセージ
         ,lv_errbuf                                 -- エラー・メッセージ           --# 固定 #
         ,lv_retcode                                -- リターン・コード             --# 固定 #
         ,lv_errmsg                                 -- ユーザー・エラー・メッセージ --# 固定 #
      );
      -- 終了パラメータ判定
         IF ( lv_retcode = cv_status_error ) THEN
           -- エラー処理
           RAISE global_process_expt;
         END IF;
    END IF;
--
    -- =====================================================
    -- SVF起動(A-5)
    -- =====================================================
    svf_request(
        ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt ;
    END IF;
--
    -- =====================================================
    -- ワークテーブルデータ削除(A-6)
    -- =====================================================
    del_work(
        ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt ;
    END IF;
--
    -- 正常終了件数
    gn_normal_cnt := gn_target_cnt - gn_warn_cnt;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- 処理件数
      gn_error_cnt  :=  gn_error_cnt + 1;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- 処理件数
      gn_error_cnt  :=  gn_error_cnt + 1;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- 処理件数
      gn_error_cnt  :=  gn_error_cnt + 1;
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
    errbuf               OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode              OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_year_month        IN  VARCHAR2,      --   1.年月
    iv_day               IN  VARCHAR2,      --   2.日
    iv_kyoten            IN  VARCHAR2,      --   3.拠点
    iv_output_dpt        IN  VARCHAR2)      --   4.帳票出力場所
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
       iv_which   => cv_log
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
       iv_year_month        --   1.年月
      ,iv_day               --   2.日
      ,iv_kyoten            --   3.拠点
      ,iv_output_dpt        --   4.帳票出力場所
      ,lv_errbuf            --   エラー・メッセージ           --# 固定 #
      ,lv_retcode           --   リターン・コード             --# 固定 #
      ,lv_errmsg            --   ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- エラー出力
    IF (lv_retcode = cv_status_error) THEN
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
--
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
    fnd_file.put_line(
       which  => FND_FILE.LOG
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
    fnd_file.put_line(
       which  => FND_FILE.LOG
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
    fnd_file.put_line(
       which  => FND_FILE.LOG
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
    fnd_file.put_line(
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
    -- 終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => 'XXCCP'
                    ,iv_name         => lv_message_code
                   );
    fnd_file.put_line(
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
END XXCOI002A04R;
/
