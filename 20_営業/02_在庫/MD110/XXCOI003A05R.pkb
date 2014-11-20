create or replace
PACKAGE BODY XXCOI003A05R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI003A05R(body)
 * Description      : 入庫差異確認リスト
 * MD.050           : 入庫差異確認リスト MD050_COI_003_A05
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  del_work               ワークテーブルデータ削除(A-10)
 *  svf_request            SVF起動(A-9)
 *  ins_work_zero          ワークテーブルデータ登録(0件)(A-8)
 *  ins_work               ワークテーブルデータ登録(A-3,A-5,A-7)
 *  get_hht_data_c         差異有無HHT入出庫データ取得(A-6)
 *  get_hht_data_b         差異なしHHT入出庫データ取得(A-4)
 *  get_hht_data_a         差異有りHHT入出庫データ取得(A-2)
 *  init                   初期処理(A-1)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/20    1.0   SCS.Tsuboi       新規作成
 *  2009/08/06    1.1   N.Abe            [0000945]パフォーマンス改善
 *  2009/08/18    1.2   N.Abe            [0001090]出力桁数の修正
 *  2009/12/25    1.3   N.Abe            [E_本稼動_00222]顧客名称取得方法修正
 *                                       [E_本稼動_00610]パフォーマンス改善
 *  2010/11/29    1.4   H.Sasaki         [E_本稼動_05338]パフォーマンス改善
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
  get_name_expt             EXCEPTION;    -- 名称取得エラー
  get_output_standard_expt  EXCEPTION;    -- 出力基準取得Iエラー
-- == 2009/12/25 V1.3 Deleted START ===============================================================
--  lock_expt                 EXCEPTION;    -- ロック取得エラー
-- == 2009/12/25 V1.3 Deleted END   ===============================================================
  get_no_data_expt          EXCEPTION;    -- 取得データ0件
  svf_request_err_expt      EXCEPTION;    -- SVF起動APIエラー
--
-- == 2009/12/25 V1.3 Deleted START ===============================================================
--  PRAGMA EXCEPTION_INIT(lock_expt, -54);  -- ロック取得例外
-- == 2009/12/25 V1.3 Deleted END   ===============================================================
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name             CONSTANT VARCHAR2(100) := 'XXCOI003A05R';   -- パッケージ名
  cv_app_name             CONSTANT VARCHAR2(5)   := 'XXCOI';          -- アプリケーション短縮名
  cv_log                  CONSTANT VARCHAR2(3)   := 'LOG';            -- コンカレントヘッダ出力先
  cv_subinv_a             CONSTANT VARCHAR2(1)   := 'A';              -- 出庫側保管場所区分(A:倉庫)    
  cv_flg_o                CONSTANT VARCHAR2(1)   := 'O';              -- 入庫差異確認リスト区分(O:百貨店フラグ('1','2','3'))   
  cv_flg_i                CONSTANT VARCHAR2(1)   := 'I';              -- 入庫差異確認リスト区分(O:百貨店フラグ(A,B,'4'))    
  cn_status               CONSTANT NUMBER        :=  1;               -- 処理済ステータス(1:済)    
  cv_standard             CONSTANT VARCHAR2(1)   := '0';              -- 出力基準(0)    
  cv_customer_class_code  CONSTANT VARCHAR2(1)   := '1';              -- 顧客区分(1：拠点)
--
  -- メッセージ
  cv_msg_xxcoi_00008  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00008';   -- 0件メッセージ
  cv_msg_xxcoi_00005  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00005';   -- 在庫組織コード取得エラー
  cv_msg_xxcoi_00006  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00006';   -- 在庫組織ID取得エラー
  cv_msg_xxcoi_00009  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00009';   -- 拠点名取得エラー
  cv_msg_xxcoi_00010  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00010';   -- APIエラーメッセージ
-- == 2009/12/25 V1.3 Deleted START ===============================================================
--  cv_msg_xxcoi_10007  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10007';   -- ロック取得エラー(入庫差異確認リスト)
-- == 2009/12/25 V1.3 Deleted END   ===============================================================
  cv_msg_xxcoi_10021  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10021';   -- 出力基準名取得エラー
  cv_msg_xxcoi_10317  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10317';   -- 出力条件名取得エラー
  cv_msg_xxcoi_10158  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10158';   -- パラメータ.拠点メッセージ
  cv_msg_xxcoi_10159  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10159';   -- パラメータ.出力基準メッセージ
  cv_msg_xxcoi_10160  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10160';   -- パラメータ.出力条件メッセージ
  cv_msg_xxcoi_10355  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10355';   -- パラメータ.対象年月メッセージ
--
  -- トークン名
  cv_token_pro                CONSTANT VARCHAR2(30) := 'PRO_TOK';
  cv_token_org_code           CONSTANT VARCHAR2(30) := 'ORG_CODE_TOK';
  cv_token_dept_code          CONSTANT VARCHAR2(30) := 'DEPT_CODE_TOK';
  cv_token_lookup_type        CONSTANT VARCHAR2(30) := 'LOOKUP_TYPE_TOK';
  cv_token_lookup_code        CONSTANT VARCHAR2(30) := 'LOOKUP_CODE_TOK';
  cv_token_target_date        CONSTANT VARCHAR2(30) := 'P_TARGET_DATE';
  cv_token_base               CONSTANT VARCHAR2(30) := 'P_BASE';
  cv_token_standard           CONSTANT VARCHAR2(30) := 'P_STANDARD';
  cv_token_term               CONSTANT VARCHAR2(30) := 'P_TERM';
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 入力パラメータ格納用レコード変数
  TYPE gr_param_rec  IS RECORD(
      target_date       VARCHAR2(7)       -- 01 : 対象年月  (必須)
     ,base_code         VARCHAR2(4)       -- 02 : 拠点      (必須)
     ,output_standard   VARCHAR2(1)       -- 03 : 出力基準  (必須)
     ,output_term       VARCHAR2(1)       -- 04 : 出力条件  (必須)
    );
--
  -- HHT情報格納用レコード変数
  TYPE gr_hht_info_rec IS RECORD(
      outside_code              VARCHAR2(13)                                     -- 出庫側コード
    , outside_location_code     VARCHAR2(13)                                     -- 出庫側コード
-- == 2009/08/18 V1.2 Modified START ===============================================================
--    , outside_location_name     VARCHAR2(40)                                     -- 出庫場所名
-- == 2009/12/25 V1.3 Modified START ===============================================================
--    , outside_location_name     VARCHAR2(240)                                    -- 出庫場所名
    , outside_location_name     VARCHAR2(360)                                    -- 出庫場所名
-- == 2009/12/25 V1.3 Modified END   ===============================================================
-- == 2009/08/18 V1.2 Modified END   ===============================================================
    , invoice_date               xxcoi_hht_inv_transactions.invoice_date%TYPE    -- 伝票日付
    , item_code                  xxcoi_hht_inv_transactions.item_code%TYPE       -- 商品コード
    , item_name                  xxcmn_item_mst_b.item_short_name%TYPE           -- 商品名
    , outside_qty                NUMBER                                          -- 出庫側数量
    , inside_qty                 NUMBER                                          -- 入庫側数量
    , inside_code                VARCHAR2(13)                                     -- 出庫側コード
    , inside_location_code       VARCHAR2(13)                                    -- 入庫側コード
-- == 2009/08/18 V1.2 Modified START ===============================================================
--    , inside_location_name       VARCHAR2(40)                                    -- 入庫場所名
-- == 2009/12/25 V1.3 Modified START ===============================================================
--    , inside_location_name       VARCHAR2(240)                                    -- 入庫場所名
    , inside_location_name       VARCHAR2(360)                                    -- 入庫場所名
-- == 2009/12/25 V1.3 Modified END   ===============================================================
-- == 2009/08/18 V1.2 Modified END   ===============================================================
  );
--
  --  HHT情報格納用テーブル
  TYPE gt_hht_info_ttype IS TABLE OF gr_hht_info_rec INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_organization_id        mtl_parameters.organization_id%TYPE;              -- 在庫組織ID
  gv_base_name              hz_cust_accounts.account_name%TYPE;               -- 拠点名称(略称)
  gv_output_standard_name   fnd_lookup_values.meaning%TYPE;                   -- 出力基準名
  gv_output_term_name       fnd_lookup_values.meaning%TYPE;                   -- 出力条件名
  -- カウンタ
  gn_base_cnt               NUMBER;                                           -- 拠点コード件数
  gn_base_loop_cnt          NUMBER;                                           -- 拠点コードループカウンタ
  gn_hht_info_cnt           NUMBER;                                           -- HHT入出庫情報件数
  gn_hht_info_loop_cnt      NUMBER;                                           -- HHT入出庫情報ループカウンタ
  -- 
  gd_target_date_start      DATE;                                             -- 対象年月の1日
  gd_target_date_end        DATE;                                             -- 対象年月の月末日　
  --
  gr_param                  gr_param_rec;
  gt_hht_info_tab           gt_hht_info_ttype;
-- == 2010/11/29 V1.4 Added START ===============================================================
  gt_base_code              xxcoi_hht_inv_transactions.base_code%TYPE;        --  拠点コード
  gn_ins_cnt                NUMBER;                                           --  帳票ワーク挿入件数
-- == 2010/11/29 V1.4 Added END   ===============================================================
--
  /**********************************************************************************
   * Procedure Name   : del_work
   * Description      : ワークテーブルデータ削除(A-10)
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
-- == 2009/12/25 V1.3 Deleted START ===============================================================
--    -- ワークテーブルロック
--    CURSOR del_xsbl_tbl_cur
--    IS
--      SELECT 'X'
--      FROM   xxcoi_rep_stock_balance_list xsbl        -- 入庫差異確認リスト帳票ワークテーブル
--      WHERE  xsbl.request_id = cn_request_id      -- 要求ID
--      FOR UPDATE OF xsbl.request_id NOWAIT
--    ;
----
--    -- *** ローカル・レコード ***
--    del_xsbl_tbl_rec  del_xsbl_tbl_cur%ROWTYPE;
-- == 2009/12/25 V1.3 Deleted END   ===============================================================
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
-- == 2009/12/25 V1.3 Deleted START ===============================================================
--    -- カーソルオープン
--    OPEN del_xsbl_tbl_cur;
----
--    <<del_xsbl_tbl_cur_loop>>
--    LOOP
--      -- レコード読込
--      FETCH del_xsbl_tbl_cur INTO del_xsbl_tbl_rec;
--      EXIT WHEN del_xsbl_tbl_cur%NOTFOUND;
-- == 2009/12/25 V1.3 Deleted END   ===============================================================
--
      -- 入庫差異確認リスト帳票ワークテーブルの削除
      DELETE
      FROM   xxcoi_rep_stock_balance_list xsbl    -- 入庫差異確認リスト帳票ワークテーブル
      WHERE  xsbl.request_id = cn_request_id      -- 要求ID
      ;
--
-- == 2009/12/25 V1.3 Deleted START ===============================================================
--    END LOOP del_xrj_tbl_cur_loop;
----
--    -- カーソルクローズ
--    CLOSE del_xsbl_tbl_cur;
-- == 2009/12/25 V1.3 Deleted END   ===============================================================
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
-- == 2009/12/25 V1.3 Deleted START ===============================================================
--    -- ロック取得エラー
--    WHEN lock_expt THEN
--      -- カーソルがOPENしている場合
--      IF ( del_xsbl_tbl_cur%ISOPEN ) THEN
--        CLOSE del_xsbl_tbl_cur;
--      END IF;
--      lv_errmsg  := xxccp_common_pkg.get_msg(
--                        iv_application  => cv_app_name
--                      , iv_name         => cv_msg_xxcoi_10007
--                    );
--      lv_errbuf  := lv_errmsg;
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
--      ov_retcode := cv_status_error;
-- == 2009/12/25 V1.3 Deleted END   ===============================================================
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
-- == 2009/12/25 V1.3 Deleted START ===============================================================
--      -- カーソルがOPENしている場合
--      IF ( del_xsbl_tbl_cur%ISOPEN ) THEN
--        CLOSE del_xsbl_tbl_cur;
--      END IF;
-- == 2009/12/25 V1.3 Deleted END   ===============================================================
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
-- == 2009/12/25 V1.3 Deleted START ===============================================================
--      -- カーソルがOPENしている場合
--      IF ( del_xsbl_tbl_cur%ISOPEN ) THEN
--        CLOSE del_xsbl_tbl_cur;
--      END IF;
-- == 2009/12/25 V1.3 Deleted END   ===============================================================
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
-- == 2009/12/25 V1.3 Deleted START ===============================================================
--      -- カーソルがOPENしている場合
--      IF ( del_xsbl_tbl_cur%ISOPEN ) THEN
--        CLOSE del_xsbl_tbl_cur;
--      END IF;
-- == 2009/12/25 V1.3 Deleted END   ===============================================================
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END del_work;
--  
  /**********************************************************************************
   * Procedure Name   : svf_request
   * Description      : SVF起動(A-10)
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
    cv_output_mode  CONSTANT VARCHAR2(1) := '1';                    -- 出力区分(PDF出力)
    cv_frm_file     CONSTANT VARCHAR2(30) := 'XXCOI003A05S.xml';     -- フォーム様式ファイル名
    cv_vrq_file     CONSTANT VARCHAR2(30) := 'XXCOI003A05S.vrq';     -- クエリー様式ファイル名
    cv_api_name     CONSTANT VARCHAR2(7) := 'SVF起動';              -- SVF起動API名
--
    -- エラーコード
    cv_msg_xxcoi00010  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00010';   -- APIエラー
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
    -- 日付書式変換
    ld_date := TO_CHAR( cd_creation_date, 'YYYYMMDD' );
--
    -- 出力ファイル名
    lv_file_name := cv_pkg_name || ld_date || TO_CHAR(cn_request_id);
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
   * Procedure Name   : ins_work_zero
   * Description      : ワークテーブルデータ登録(0件)(A-8)
   ***********************************************************************************/
  PROCEDURE ins_work_zero(
    iv_nodata_msg              IN  VARCHAR2,     -- ゼロ件メッセージ 
    ov_errbuf                  OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode                 OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg                  OUT VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_work_zero'; -- プログラム名
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
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --入出庫ジャーナルチェックリスト帳票ワークテーブル登録処理
    INSERT INTO xxcoi_rep_stock_balance_list(
        stock_balance_list_id
       ,target_term
       ,base_code 
       ,base_name
       ,output_standard_code 
       ,output_standard_name
       ,outside_location_code
       ,outside_location_name
       ,invoice_date 
       ,item_code
       ,item_name
       ,outside_qty
       ,inside_qty
       ,inside_location_code
       ,inside_location_name
       ,no_data_msg
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
        xxcoi_rep_stock_balance_S01.NEXTVAL                                         -- 入庫差異確認リストID(シーケンス)
       ,gr_param.target_date                                                        -- 対象年月
       ,gr_param.base_code                                                          -- 拠点コード
       ,gv_base_name                                                                -- 拠点名
       ,gr_param.output_standard                                                    -- 出力基準コード
       ,gv_output_standard_name                                                     -- 出力基準名
       ,NULL                                                                        -- 出庫場所
       ,NULL                                                                        -- 出庫場所名
       ,NULL                                                                        -- 伝票日付
       ,NULL                                                                        -- 商品コード
       ,NULL                                                                        -- 商品名
       ,NULL                                                                        -- 出庫数量
       ,NULL                                                                        -- 入庫数量
       ,NULL                                                                        -- 入庫場所
       ,NULL                                                                        -- 入庫場所名
       ,iv_nodata_msg                                                               -- 0件メッセージ
       --WHOカラム
       ,cn_created_by
       ,cd_creation_date
       ,cn_last_updated_by
       ,cd_last_update_date
       ,cn_last_update_login
       ,cn_request_id
       ,cn_program_application_id
       ,cn_program_id
       ,cd_program_update_date
      );
--      
    -- コミット
    COMMIT;
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
  END ins_work_zero;
--
   /**********************************************************************************
   * Procedure Name   : ins_work
   * Description      : ワークテーブルデータ登録(A-3,A-5,A-7)
   ***********************************************************************************/
  PROCEDURE ins_work(
    gn_hht_info_loop_cnt       IN NUMBER,        -- HHT入出庫データ情報ループカウンタ
    ov_errbuf                  OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode                 OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg                  OUT VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --入庫差異確認リスト帳票ワークテーブル登録処理
    INSERT INTO xxcoi_rep_stock_balance_list(
        stock_balance_list_id
       ,target_term
       ,base_code 
       ,base_name
       ,output_standard_code 
       ,output_standard_name
       ,outside_location_code
       ,outside_location_name
       ,invoice_date 
       ,item_code
       ,item_name
       ,outside_qty
       ,inside_qty
       ,inside_location_code
       ,inside_location_name
       ,no_data_msg
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
        xxcoi_rep_stock_balance_s01.NEXTVAL                                         -- 入庫差異確認リストID(シーケンス)
       ,gr_param.target_date                                                        -- 対象年月
       ,gr_param.base_code                                                          -- 拠点コード
       ,gv_base_name                                                                -- 拠点名
       ,gr_param.output_standard                                                    -- 出力基準コード
       ,gv_output_standard_name                                                     -- 出力基準名
       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).outside_location_code               -- 出庫場所
-- == 2009/08/18 V1.2 Modified START ===============================================================
--       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).outside_location_name               -- 出庫場所名
       ,SUBSTRB(gt_hht_info_tab( gn_hht_info_loop_cnt ).outside_location_name, 1, 40) -- 出庫場所名
-- == 2009/08/18 V1.2 Modified END   ===============================================================
       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).invoice_date                        -- 伝票日付
       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).item_code                           -- 商品コード
       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).item_name                           -- 商品名
       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).outside_qty                         -- 出庫数量
       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).inside_qty                          -- 入庫数量
       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).inside_location_code                -- 入庫場所
-- == 2009/08/18 V1.2 Modified START ===============================================================
--       ,gt_hht_info_tab( gn_hht_info_loop_cnt ).inside_location_name                -- 入庫場所名
       ,SUBSTRB(gt_hht_info_tab( gn_hht_info_loop_cnt ).inside_location_name, 1, 40)  -- 入庫場所名
-- == 2009/08/18 V1.2 Modified END   ===============================================================
       ,NULL                                                               -- 0件メッセージ
       --WHOカラム
       ,cn_created_by
       ,cd_creation_date
       ,cn_last_updated_by
       ,cd_last_update_date
       ,cn_last_update_login
       ,cn_request_id
       ,cn_program_application_id
       ,cn_program_id
       ,cd_program_update_date
      );
--      
    -- コミット
    COMMIT;
-- == 2010/11/29 V1.4 Added START ===============================================================
    --  帳票ワーク挿入件数
    gn_ins_cnt :=  gn_ins_cnt + 1;
-- == 2010/11/29 V1.4 Added END   ===============================================================
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
   * Procedure Name   : get_hht_dat_c(ループ部)
   * Description      : 差異有無HHT入出庫データ取得(A-6)
   ***********************************************************************************/
  PROCEDURE get_hht_data_c(
    ov_errbuf        OUT VARCHAR2,    --   エラー・メッセージ                --# 固定 #
    ov_retcode       OUT VARCHAR2,    --   リターン・コード                  --# 固定 #
    ov_errmsg        OUT VARCHAR2)    --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_hht_data_c'; -- プログラム名
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
    -- 参照タイプ
--
    -- 参照コード
--   
    -- *** ローカル変数 ***
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 差異有無HHT入出庫データ
    CURSOR info_hht_cur_c
    IS
      SELECT
         NULL
        ,CASE hht.outside_subinv_code_conv_div
            WHEN cv_subinv_a THEN  hht.base_code||' '||hht.outside_code
            ELSE hht.outside_code
            END AS outside_code
        ,CASE hht.outside_subinv_code_conv_div
            WHEN cv_subinv_a THEN  msi1.description
-- == 2009/12/25 V1.3 Modified START ===============================================================
--            ELSE hca1.account_name
            ELSE hp1.party_name
-- == 2009/12/25 V1.3 Modified END   ===============================================================
            END AS outside_name
        ,hht.invoice_date                                        AS invoice_date
        ,hht.item_code                                           AS item_code
        ,ximb.item_short_name                                    AS item_name
        ,NVL( hht.outside_sum_qty,0 )                            AS outside_qty
        ,NVL( hht.inside_sum_qty,0 )                             AS inside_qty
        ,NULL
        ,CASE hht.inside_subinv_code_conv_div
           WHEN cv_subinv_a THEN  hht.base_code||' '||hht.inside_code
           ELSE hht.inside_code
           END AS inside_code
        ,CASE hht.inside_subinv_code_conv_div
           WHEN cv_subinv_a THEN  msi2.description
-- == 2009/12/25 V1.3 Modified START ===============================================================
--           ELSE hca2.account_name
           ELSE hp2.party_name
-- == 2009/12/25 V1.3 Modified END   ===============================================================
           END AS inside_name
      FROM
        (
         -- 差異有無情報
         SELECT
              hht2.base_code                                     AS base_code
             ,hht2.outside_base_code                             AS outside_base_code
             ,hht2.outside_code                                  AS outside_code
             ,hht2.outside_subinv_code                           AS outside_subinv_code 
             ,hht2.outside_cust_code                             AS outside_cust_code
             ,hht2.outside_subinv_code_conv_div                  AS outside_subinv_code_conv_div
             ,hht2.item_code                                     AS item_code
             ,hht2.invoice_date                                  AS invoice_date
             ,SUM(hht2.out_quantity)                             AS outside_sum_qty
             ,SUM(hht2.in_quantity)                              AS inside_sum_qty
             ,hht2.inside_base_code                              AS inside_base_code
             ,hht2.inside_code                                   AS inside_code
             ,hht2.inside_subinv_code                            AS inside_subinv_code
             ,hht2.inside_cust_code                              AS inside_cust_code
             ,hht2.inside_subinv_code_conv_div                   AS inside_subinv_code_conv_div
         FROM
           (
            SELECT 
                xhit.base_code                                   AS base_code
               ,xhit.outside_base_code                           AS outside_base_code
               ,xhit.outside_code                                AS outside_code
               ,xhit.outside_subinv_code                         AS outside_subinv_code
               ,xhit.outside_cust_code                           AS outside_cust_code 
               ,xhit.outside_subinv_code_conv_div                AS outside_subinv_code_conv_div
               ,xhit.item_code                                   AS item_code
               ,xhit.invoice_date                                AS invoice_date
               ,CASE xhit.stock_balance_list_div
                WHEN cv_flg_o THEN NVL(xhit.total_quantity,0 )
                ELSE 0
                END  AS out_quantity
               ,CASE xhit.stock_balance_list_div
                WHEN cv_flg_i THEN NVL(xhit.total_quantity,0 )
                ELSE 0
                END  AS in_quantity
               ,xhit.inside_base_code                            AS inside_base_code
               ,xhit.inside_code                                 AS inside_code
               ,xhit.inside_subinv_code                          AS inside_subinv_code
               ,xhit.inside_cust_code                            AS inside_cust_code
               ,xhit.inside_subinv_code_conv_div                 AS inside_subinv_code_conv_div
               ,xhit.stock_balance_list_div                      AS stock_balance_list_div
           FROM xxcoi_hht_inv_transactions xhit
          WHERE xhit.stock_balance_list_div IN (cv_flg_o,cv_flg_i)
            AND (xhit.invoice_date BETWEEN gd_target_date_start AND gd_target_date_end)
            AND xhit.status = cn_status
-- == 2010/11/29 V1.4 Added START ===============================================================
            AND xhit.base_code    =   gt_base_code
-- == 2010/11/29 V1.4 Added END   ===============================================================
-- == 2009/08/06 V1.1 Modified START ===============================================================
--            AND EXISTS (SELECT 1 FROM xxcoi_base_info2_v  xbiv 
--                        WHERE xbiv.focus_base_code = gr_param.base_code
--                        AND   xbiv.base_code IN(xhit.outside_base_code,xhit.inside_base_code))
            AND EXISTS (SELECT 1
                        FROM   hz_cust_accounts    hca
                              ,xxcmm_cust_accounts xca
                        WHERE  xca.management_base_code =  gr_param.base_code
                        AND    hca.account_number       IN (xhit.outside_base_code, xhit.inside_base_code)
                        AND    hca.status               =  'A'
                        AND    hca.customer_class_code  =  '1'
                        AND    hca.cust_account_id      =  xca.customer_id
                        UNION ALL
                        SELECT 1
                        FROM   hz_cust_accounts    hca
                              ,xxcmm_cust_accounts xca
                        WHERE  hca.account_number       =  gr_param.base_code
                        AND    hca.account_number       IN (xhit.outside_base_code, xhit.inside_base_code)
                        AND    hca.status               = 'A'
                        AND    hca.customer_class_code  = '1'
                        AND    hca.cust_account_id      = xca.customer_id
                        AND    hca.account_number      <> NVL(xca.management_base_code,'99999')
                       )
-- == 2009/08/06 V1.1 Modified END   ===============================================================
         ) hht2
         GROUP BY 
               hht2.base_code   
              ,hht2.outside_base_code   
              ,hht2.outside_code
              ,hht2.outside_subinv_code
              ,hht2.outside_cust_code
              ,hht2.item_code
              ,hht2.outside_subinv_code_conv_div
              ,hht2.invoice_date  
              ,hht2.inside_base_code
              ,hht2.inside_code
              ,hht2.inside_subinv_code
              ,hht2.inside_cust_code
              ,hht2.inside_subinv_code_conv_div
        ) hht                                                        -- 差異あり情報
      ,ic_item_mst_b              iimb                               -- OPM品目マスタ
      ,xxcmn_item_mst_b           ximb                               -- OPM品目マスタアドオン
      ,mtl_secondary_inventories  msi1                               -- 出庫側保管場所マスタ
      ,mtl_secondary_inventories  msi2                               -- 入庫側保管場所マスタ
      ,hz_cust_accounts           hca1                               -- 出庫側顧客アカウント
      ,hz_cust_accounts           hca2                               -- 入庫側顧客アカウント
-- == 2009/12/25 V1.3 Added START ===============================================================
      ,hz_parties                 hp1                                -- 入庫側パーティマスタ
      ,hz_parties                 hp2                                -- 出庫側パーティマスタ
-- == 2009/12/25 V1.3 Added END   ===============================================================
    WHERE  
          hht.outside_subinv_code = msi1.secondary_inventory_name
      AND msi1.organization_id    = gn_organization_id
      AND hht.inside_subinv_code  = msi2.secondary_inventory_name
      AND msi2.organization_id    = gn_organization_id
      AND hht.outside_cust_code   = hca1.account_number(+)
      AND hht.inside_cust_code    = hca2.account_number(+)
-- == 2009/12/25 V1.3 Added START ===============================================================
      AND hca1.party_id           = hp1.party_id(+)
      AND hca2.party_id           = hp2.party_id(+)
-- == 2009/12/25 V1.3 Added END   ===============================================================
      AND item_code               = iimb.item_no
      AND iimb.item_id            = ximb.item_id
      AND (hht.invoice_date BETWEEN ximb.start_date_active AND ximb.end_date_active)
    ORDER BY 
          DECODE(gr_param.output_standard,cv_standard,hht.inside_code,hht.outside_code)
         ,hht.invoice_date
         ,hht.item_code 
    ;    
--
    -- ローカル・レコード
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
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
    -- HHT入出庫情報件数初期化
    gn_hht_info_cnt := 0;
--
    -- カーソルオープン
    OPEN info_hht_cur_c;
--
    -- レコード読込
    FETCH info_hht_cur_c BULK COLLECT INTO gt_hht_info_tab;
--
    -- HHT入出庫情報カウントセット
    gn_hht_info_cnt := gt_hht_info_tab.COUNT;
--
    -- カーソルクローズ
    CLOSE info_hht_cur_c;
--
    -- 対象処理件数
    gn_target_cnt := gn_target_cnt + gn_hht_info_cnt;
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
      IF ( info_hht_cur_c%ISOPEN ) THEN
        CLOSE info_hht_cur_c;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルがOPENしている場合
      IF ( info_hht_cur_c%ISOPEN ) THEN
        CLOSE info_hht_cur_c;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルがOPENしている場合
      IF ( info_hht_cur_c%ISOPEN ) THEN
        CLOSE info_hht_cur_c;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルがOPENしている場合
      IF ( info_hht_cur_c%ISOPEN ) THEN
        CLOSE info_hht_cur_c;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_hht_data_c;
--
  /**********************************************************************************
   * Procedure Name   : get_hht_dat_b(ループ部)
   * Description      : 差異無しHHT入出庫データ取得(A-4)
   ***********************************************************************************/
  PROCEDURE get_hht_data_b(
    ov_errbuf        OUT VARCHAR2,    --   エラー・メッセージ                --# 固定 #
    ov_retcode       OUT VARCHAR2,    --   リターン・コード                  --# 固定 #
    ov_errmsg        OUT VARCHAR2)    --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_hht_data_b'; -- プログラム名
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
    -- 参照タイプ
--
    -- 参照コード
--   
    -- *** ローカル変数 ***
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 差異無しHHT入出庫データ
    CURSOR info_hht_cur_b
    IS
      SELECT
         NULL
        ,CASE outside.outside_subinv_code_conv_div
            WHEN cv_subinv_a THEN  outside.base_code||' '||outside.outside_code
            ELSE outside.outside_code
            END AS outside_code
        ,CASE outside.outside_subinv_code_conv_div
            WHEN cv_subinv_a THEN  msi1.description
-- == 2009/12/25 V1.3 Modified START ===============================================================
--            ELSE hca1.account_name
            ELSE hp1.party_name
-- == 2009/12/25 V1.3 Modified END   ===============================================================
            END AS outside_name
        ,outside.invoice_date                                    AS invoice_date
        ,outside.item_code                                       AS item_code
        ,ximb.item_short_name                                    AS item_name
        ,NVL( outside.sum_quantity,0 )                           AS outside_qty
        ,NVL( inside.sum_quantity,0 )                            AS inside_qty
        ,NULL
        ,CASE inside.inside_subinv_code_conv_div
            WHEN cv_subinv_a THEN inside.base_code||' '||inside.inside_code
            ELSE inside.inside_code
            END AS inside_code
        ,CASE inside.inside_subinv_code_conv_div
            WHEN cv_subinv_a THEN  msi2.description
-- == 2009/12/25 V1.3 Modified START ===============================================================
--            ELSE hca2.account_name
            ELSE hp2.party_name
-- == 2009/12/25 V1.3 Modified END   ===============================================================
            END AS inside_name
      FROM
        (
         -- 出庫側情報
         SELECT 
              xhit.base_code                                     AS base_code 
             ,xhit.outside_base_code                             AS outside_base_code
             ,xhit.outside_code                                  AS outside_code
             ,xhit.outside_subinv_code                           AS outside_subinv_code
             ,xhit.outside_cust_code                             AS outside_cust_code
             ,xhit.outside_subinv_code_conv_div                  AS outside_subinv_code_conv_div
             ,xhit.item_code                                     AS item_code 
             ,xhit.invoice_date                                  AS invoice_date
             ,SUM( NVL(xhit.total_quantity,0 ) )                 AS sum_quantity
             ,xhit.inside_base_code                              AS inside_base_code
             ,xhit.inside_code                                   AS inside_code
             ,xhit.inside_subinv_code                            AS inside_subinv_code
             ,xhit.inside_cust_code                              AS inside_cust_code
             ,xhit.inside_subinv_code_conv_div                   AS inside_subinv_code_conv_div
         FROM xxcoi_hht_inv_transactions xhit
        WHERE xhit.stock_balance_list_div = cv_flg_o
          AND (xhit.invoice_date BETWEEN gd_target_date_start AND gd_target_date_end)
          AND  xhit.status = cn_status
-- == 2009/08/06 V1.1 Modified START ===============================================================
--            AND EXISTS (SELECT 1 FROM xxcoi_base_info2_v  xbiv 
--                        WHERE xbiv.focus_base_code = gr_param.base_code
--                        AND   xbiv.base_code IN(xhit.outside_base_code,xhit.inside_base_code))
            AND EXISTS (SELECT 1
                        FROM   hz_cust_accounts    hca
                              ,xxcmm_cust_accounts xca
                        WHERE  xca.management_base_code =  gr_param.base_code
                        AND    hca.account_number       IN (xhit.outside_base_code, xhit.inside_base_code)
                        AND    hca.status               =  'A'
                        AND    hca.customer_class_code  =  '1'
                        AND    hca.cust_account_id      =  xca.customer_id
                        UNION ALL
                        SELECT 1
                        FROM   hz_cust_accounts    hca
                              ,xxcmm_cust_accounts xca
                        WHERE  hca.account_number       =  gr_param.base_code
                        AND    hca.account_number       IN (xhit.outside_base_code, xhit.inside_base_code)
                        AND    hca.status               = 'A'
                        AND    hca.customer_class_code  = '1'
                        AND    hca.cust_account_id      = xca.customer_id
                        AND    hca.account_number      <> NVL(xca.management_base_code,'99999')
                       )
-- == 2009/08/06 V1.1 Modified END   ===============================================================
        GROUP BY
              xhit.base_code
             ,xhit.outside_base_code
             ,xhit.outside_code
             ,xhit.outside_subinv_code
             ,xhit.outside_cust_code
             ,xhit.outside_subinv_code_conv_div
             ,xhit.item_code
             ,xhit.invoice_date
             ,xhit.inside_base_code
             ,xhit.inside_code
             ,xhit.inside_subinv_code
             ,xhit.inside_cust_code
             ,xhit.inside_subinv_code_conv_div ) outside ,     -- 出庫側情報インラインビュー
       -- 入庫側情報
       (SELECT
              xhit.base_code                                     AS base_code
             ,xhit.outside_base_code                             AS outside_base_code
             ,xhit.outside_code                                  AS outside_code
             ,xhit.outside_subinv_code                           AS outside_subinv_code
             ,xhit.outside_cust_code                             AS outside_cust_code
             ,xhit.outside_subinv_code_conv_div                  AS outside_subinv_code_conv_div
             ,xhit.item_code                                     AS item_code
             ,xhit.invoice_date                                  AS invoice_date
             ,SUM( nvl(xhit.total_quantity,0 ) )                 AS sum_quantity
             ,xhit.inside_base_code                              AS inside_base_code 
             ,xhit.inside_code                                   AS inside_code  
             ,xhit.inside_subinv_code                            AS inside_subinv_code
             ,xhit.inside_cust_code                              AS inside_cust_code
             ,xhit.inside_subinv_code_conv_div                   AS inside_subinv_code_conv_div
         FROM xxcoi_hht_inv_transactions xhit
        WHERE xhit.stock_balance_list_div = cv_flg_i
         AND (xhit.invoice_date BETWEEN gd_target_date_start AND gd_target_date_end)
          AND  xhit.status = cn_status
-- == 2009/08/06 V1.1 Modified START ===============================================================
--            AND EXISTS (SELECT 1 FROM xxcoi_base_info2_v  xbiv 
--                        WHERE xbiv.focus_base_code = gr_param.base_code
--                        AND   xbiv.base_code IN(xhit.outside_base_code,xhit.inside_base_code))
            AND EXISTS (SELECT 1
                        FROM   hz_cust_accounts    hca
                              ,xxcmm_cust_accounts xca
                        WHERE  xca.management_base_code =  gr_param.base_code
                        AND    hca.account_number       IN (xhit.outside_base_code, xhit.inside_base_code)
                        AND    hca.status               =  'A'
                        AND    hca.customer_class_code  =  '1'
                        AND    hca.cust_account_id      =  xca.customer_id
                        UNION ALL
                        SELECT 1
                        FROM   hz_cust_accounts    hca
                              ,xxcmm_cust_accounts xca
                        WHERE  hca.account_number       =  gr_param.base_code
                        AND    hca.account_number       IN (xhit.outside_base_code, xhit.inside_base_code)
                        AND    hca.status               = 'A'
                        AND    hca.customer_class_code  = '1'
                        AND    hca.cust_account_id      = xca.customer_id
                        AND    hca.account_number      <> NVL(xca.management_base_code,'99999')
                       )
-- == 2009/08/06 V1.1 Modified END   ===============================================================
       GROUP BY
             xhit.base_code
            ,xhit.outside_base_code
            ,xhit.outside_code
            ,xhit.outside_subinv_code
            ,xhit.outside_cust_code
            ,xhit.outside_subinv_code_conv_div
            ,xhit.item_code
            ,xhit.invoice_date
            ,xhit.inside_base_code
            ,xhit.inside_code
            ,xhit.inside_subinv_code
            ,xhit.inside_cust_code
            ,xhit.inside_subinv_code_conv_div ) inside                -- 入庫側情報インラインビュー 
         ,ic_item_mst_b              iimb                             -- OPM品目マスタ
         ,xxcmn_item_mst_b           ximb                             -- OPM品目マスタアドオン
         ,mtl_secondary_inventories  msi1                             -- 出庫側保管場所マスタ
         ,mtl_secondary_inventories  msi2                             -- 入庫側保管場所マスタ
         ,hz_cust_accounts           hca1                             -- 出庫側顧客アカウント
         ,hz_cust_accounts           hca2                             -- 入庫側顧客アカウント
-- == 2009/12/25 V1.3 Added START ===============================================================
         ,hz_parties                 hp1                              -- 入庫側パーティマスタ
         ,hz_parties                 hp2                              -- 出庫側パーティマスタ
-- == 2009/12/25 V1.3 Added END   ===============================================================
      WHERE outside.outside_base_code            = inside.outside_base_code
        AND outside.outside_code                 = inside.outside_code
        AND outside.invoice_date                 = inside.invoice_date
        AND outside.item_code                    = inside.item_code
        AND outside.inside_base_code             = inside.inside_base_code
        AND outside.inside_code                  = inside.inside_code
        AND outside.sum_quantity                 = inside.sum_quantity
        AND outside.item_code                    = iimb.item_no
        AND iimb.item_id                         = ximb.item_id
        AND (outside.invoice_date BETWEEN ximb.start_date_active AND ximb.end_date_active)
        AND outside.outside_subinv_code          = msi1.secondary_inventory_name
        AND msi1.organization_id                 = gn_organization_id
        AND outside.outside_cust_code            = hca1.account_number(+)
        AND inside.inside_subinv_code            = msi2.secondary_inventory_name
        AND msi2.organization_id                 = gn_organization_id
        AND inside.inside_cust_code              = hca2.account_number(+)
-- == 2009/12/25 V1.3 Added START ===============================================================
        AND hca1.party_id                        = hp1.party_id(+)
        AND hca2.party_id                        = hp2.party_id(+)
-- == 2009/12/25 V1.3 Added END   ===============================================================
      ORDER BY 
          DECODE(gr_param.output_standard,cv_standard,inside.inside_code,outside.outside_code)
         ,outside.invoice_date
         ,outside.item_code 
    ;    
--
    -- ローカル・レコード
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
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
    -- 差異無しHHT入出庫情報件数初期化
    gn_hht_info_cnt := 0;
--
    -- カーソルオープン
    OPEN info_hht_cur_b;
--
    -- レコード読込
    FETCH info_hht_cur_b BULK COLLECT INTO gt_hht_info_tab;
--
    -- HHT入出庫情報カウントセット
    gn_hht_info_cnt := gt_hht_info_tab.COUNT;
--
    -- カーソルクローズ
    CLOSE info_hht_cur_b;
--
    -- 対象処理件数
    gn_target_cnt := gn_target_cnt + gn_hht_info_cnt;
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
      IF ( info_hht_cur_b%ISOPEN ) THEN
        CLOSE info_hht_cur_b;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルがOPENしている場合
      IF ( info_hht_cur_b%ISOPEN ) THEN
        CLOSE info_hht_cur_b;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルがOPENしている場合
      IF ( info_hht_cur_b%ISOPEN ) THEN
        CLOSE info_hht_cur_b;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルがOPENしている場合
      IF ( info_hht_cur_b%ISOPEN ) THEN
        CLOSE info_hht_cur_b;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_hht_data_b;
--
  /**********************************************************************************
   * Procedure Name   : get_hht_dat_a(ループ部)
   * Description      : 差異有りHHT入出庫データ取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_hht_data_a(
    ov_errbuf        OUT VARCHAR2,    --   エラー・メッセージ                --# 固定 #
    ov_retcode       OUT VARCHAR2,    --   リターン・コード                  --# 固定 #
    ov_errmsg        OUT VARCHAR2)    --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_hht_data_a'; -- プログラム名
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
    -- 参照タイプ
--
    -- 参照コード
--   
    -- *** ローカル変数 ***
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 差異有りHHT入出庫データ
    CURSOR info_hht_cur_a
    IS
      SELECT
         NULL
        ,CASE hht.outside_subinv_code_conv_div
            WHEN cv_subinv_a THEN  hht.base_code||' '||hht.outside_code
            ELSE hht.outside_code
            END AS outside_code
        ,CASE hht.outside_subinv_code_conv_div
            WHEN cv_subinv_a THEN  msi1.description
-- == 2009/12/25 V1.3 Modified START ===============================================================
--            ELSE hca1.account_name
            ELSE hp1.party_name
-- == 2009/12/25 V1.3 Modified END   ===============================================================
            END AS outside_name
        ,hht.invoice_date                                        AS invoice_date
        ,hht.item_code                                           AS item_code
        ,ximb.item_short_name                                    AS item_name
        ,NVL( hht.outside_sum_qty,0 )                            AS outside_qty
        ,NVL( hht.inside_sum_qty,0 )                             AS inside_qty
        ,NULL
        ,CASE hht.inside_subinv_code_conv_div
           WHEN cv_subinv_a THEN  hht.base_code||' '||hht.inside_code
           ELSE hht.inside_code
           END AS inside_code
        ,CASE hht.inside_subinv_code_conv_div
           WHEN cv_subinv_a THEN  msi2.description
-- == 2009/12/25 V1.3 Modified START ===============================================================
--           ELSE hca2.account_name
           ELSE hp2.party_name
-- == 2009/12/25 V1.3 Modified END   ===============================================================
           END AS inside_name
      FROM
        (
         -- 差異有無情報
         SELECT
              hht2.base_code                                     AS base_code
             ,hht2.outside_base_code                             AS outside_base_code
             ,hht2.outside_code                                  AS outside_code
             ,hht2.outside_subinv_code                           AS outside_subinv_code 
             ,hht2.outside_cust_code                             AS outside_cust_code
             ,hht2.outside_subinv_code_conv_div                  AS outside_subinv_code_conv_div
             ,hht2.item_code                                     AS item_code
             ,hht2.invoice_date                                  AS invoice_date
             ,SUM(hht2.out_quantity)                             AS outside_sum_qty
             ,SUM(hht2.in_quantity)                              AS inside_sum_qty
             ,hht2.inside_base_code                              AS inside_base_code
             ,hht2.inside_code                                   AS inside_code
             ,hht2.inside_subinv_code                            AS inside_subinv_code
             ,hht2.inside_cust_code                              AS inside_cust_code
             ,hht2.inside_subinv_code_conv_div                   AS inside_subinv_code_conv_div
         FROM
           (
            SELECT 
                xhit.base_code                                   AS base_code
               ,xhit.outside_base_code                           AS outside_base_code
               ,xhit.outside_code                                AS outside_code
               ,xhit.outside_subinv_code                         AS outside_subinv_code
               ,xhit.outside_cust_code                           AS outside_cust_code 
               ,xhit.outside_subinv_code_conv_div                AS outside_subinv_code_conv_div
               ,xhit.item_code                                   AS item_code
               ,xhit.invoice_date                                AS invoice_date
               ,CASE xhit.stock_balance_list_div
                WHEN cv_flg_o THEN NVL(xhit.total_quantity,0 )
                ELSE 0
                END  AS out_quantity
               ,CASE xhit.stock_balance_list_div
                WHEN cv_flg_i THEN NVL(xhit.total_quantity,0 )
                ELSE 0
                END  AS in_quantity
               ,xhit.inside_base_code                            AS inside_base_code
               ,xhit.inside_code                                 AS inside_code
               ,xhit.inside_subinv_code                          AS inside_subinv_code
               ,xhit.inside_cust_code                            AS inside_cust_code
               ,xhit.inside_subinv_code_conv_div                 AS inside_subinv_code_conv_div
               ,xhit.stock_balance_list_div                      AS stock_balance_list_div
           FROM xxcoi_hht_inv_transactions xhit
          WHERE xhit.stock_balance_list_div IN (cv_flg_o,cv_flg_i)
            AND (xhit.invoice_date BETWEEN gd_target_date_start AND gd_target_date_end)
            AND xhit.status = cn_status
-- == 2009/08/06 V1.1 Modified START ===============================================================
--            AND EXISTS (SELECT 1 FROM xxcoi_base_info2_v  xbiv 
--                        WHERE xbiv.focus_base_code = gr_param.base_code
--                        AND   xbiv.base_code IN(xhit.outside_base_code,xhit.inside_base_code))
            AND EXISTS (SELECT 1
                        FROM   hz_cust_accounts    hca
                              ,xxcmm_cust_accounts xca
                        WHERE  xca.management_base_code =  gr_param.base_code
                        AND    hca.account_number       IN (xhit.outside_base_code, xhit.inside_base_code)
                        AND    hca.status               =  'A'
                        AND    hca.customer_class_code  =  '1'
                        AND    hca.cust_account_id      =  xca.customer_id
                        UNION ALL
                        SELECT 1
                        FROM   hz_cust_accounts    hca
                              ,xxcmm_cust_accounts xca
                        WHERE  hca.account_number       =  gr_param.base_code
                        AND    hca.account_number       IN (xhit.outside_base_code, xhit.inside_base_code)
                        AND    hca.status               = 'A'
                        AND    hca.customer_class_code  = '1'
                        AND    hca.cust_account_id      = xca.customer_id
                        AND    hca.account_number      <> NVL(xca.management_base_code,'99999')
                       )
-- == 2009/08/06 V1.1 Modified END   ===============================================================
         ) hht2
         GROUP BY 
               hht2.base_code   
              ,hht2.outside_base_code   
              ,hht2.outside_code
              ,hht2.outside_subinv_code
              ,hht2.outside_cust_code
              ,hht2.item_code
              ,hht2.outside_subinv_code_conv_div
              ,hht2.invoice_date  
              ,hht2.inside_base_code
              ,hht2.inside_code
              ,hht2.inside_subinv_code
              ,hht2.inside_cust_code
              ,hht2.inside_subinv_code_conv_div
         MINUS
         SELECT
              outside.base_code                                  AS base_code
             ,outside.outside_base_code                          AS outside_base_code
             ,outside.outside_code                               AS outside_code
             ,outside.outside_subinv_code                        AS outside_subinv_code
             ,outside.outside_cust_code                          AS outside_cust_code
             ,outside.outside_subinv_code_conv_div               AS outside_subinv_code_conv_di
             ,outside.item_code                                  AS item_code
             ,outside.invoice_date                               AS invoice_date
             ,outside.sum_quantity                               AS sum_quantity
             ,inside.sum_quantity                                AS sum_quantity
             ,outside.inside_base_code                           AS inside_base_code
             ,outside.inside_code                                AS inside_code
             ,outside.inside_subinv_code                         AS inside_subinv_code
             ,outside.inside_cust_code                           AS inside_cust_code
             ,outside.inside_subinv_code_conv_div                AS inside_subinv_code_conv_div
         FROM
           -- 出庫側情報
           (
            SELECT 
                xhit.base_code                                   AS base_code
               ,xhit.outside_base_code                           AS outside_base_code
               ,xhit.outside_code                                AS outside_code
               ,xhit.outside_subinv_code                         AS outside_subinv_code
               ,xhit.outside_cust_code                           AS outside_cust_code
               ,xhit.outside_subinv_code_conv_div                AS outside_subinv_code_conv_div
               ,xhit.item_code                                   AS item_code
               ,xhit.invoice_date                                AS invoice_date
               ,SUM(NVL(xhit.total_quantity,0))                  AS sum_quantity
               ,xhit.inside_base_code                            AS inside_base_code
               ,xhit.inside_code                                 AS inside_code
               ,xhit.inside_subinv_code                          AS inside_subinv_code
               ,xhit.inside_cust_code                            AS inside_cust_code
               ,xhit.inside_subinv_code_conv_div                 AS inside_subinv_code_conv_div
               ,xhit.stock_balance_list_div                      AS stock_balance_list_div
           FROM xxcoi_hht_inv_transactions xhit
          WHERE xhit.stock_balance_list_div = cv_flg_o
            AND (xhit.invoice_date BETWEEN gd_target_date_start AND gd_target_date_end)
            AND  xhit.status = 1
-- == 2009/08/06 V1.1 Modified START ===============================================================
--            AND EXISTS (SELECT 1 FROM xxcoi_base_info2_v  xbiv 
--                        WHERE xbiv.focus_base_code = gr_param.base_code
--                        AND   xbiv.base_code IN(xhit.outside_base_code,xhit.inside_base_code))
            AND EXISTS (SELECT 1
                        FROM   hz_cust_accounts    hca
                              ,xxcmm_cust_accounts xca
                        WHERE  xca.management_base_code =  gr_param.base_code
                        AND    hca.account_number       IN (xhit.outside_base_code, xhit.inside_base_code)
                        AND    hca.status               =  'A'
                        AND    hca.customer_class_code  =  '1'
                        AND    hca.cust_account_id      =  xca.customer_id
                        UNION ALL
                        SELECT 1
                        FROM   hz_cust_accounts    hca
                              ,xxcmm_cust_accounts xca
                        WHERE  hca.account_number       =  gr_param.base_code
                        AND    hca.account_number       IN (xhit.outside_base_code, xhit.inside_base_code)
                        AND    hca.status               = 'A'
                        AND    hca.customer_class_code  = '1'
                        AND    hca.cust_account_id      = xca.customer_id
                        AND    hca.account_number      <> NVL(xca.management_base_code,'99999')
                       )
-- == 2009/08/06 V1.1 Modified END   ===============================================================
         GROUP BY
               xhit.base_code
              ,xhit.outside_base_code
              ,xhit.outside_code
              ,xhit.outside_subinv_code
              ,xhit.outside_cust_code
              ,xhit.outside_subinv_code_conv_div
              ,xhit.item_code
              ,xhit.invoice_date
              ,xhit.inside_base_code
              ,xhit.inside_code
              ,xhit.inside_subinv_code
              ,xhit.inside_cust_code
              ,xhit.inside_subinv_code_conv_div
              ,xhit.stock_balance_list_div ) outside,     
           -- 入庫側情報
          (
           SELECT
               xhit.base_code                                    AS base_code
              ,xhit.outside_base_code                            AS outside_base_code
              ,xhit.outside_code                                 AS outside_code
              ,xhit.outside_subinv_code                          AS outside_subinv_code
              ,xhit.outside_cust_code                            AS outside_cust_code
              ,xhit.outside_subinv_code_conv_div                 AS outside_subinv_code_conv_div
              ,xhit.item_code                                    AS item_code
              ,xhit.invoice_date                                 AS invoice_date
              ,SUM(nvl(xhit.total_quantity,0))                   AS sum_quantity
              ,xhit.inside_base_code                             AS inside_base_code
              ,xhit.inside_code                                  AS inside_code
              ,xhit.inside_subinv_code                           AS inside_subinv_code
              ,xhit.inside_cust_code                             AS inside_cust_code
              ,xhit.inside_subinv_code_conv_div                  AS inside_subinv_code_conv_div
              ,xhit.stock_balance_list_div                       AS stock_balance_list_div
          FROM xxcoi_hht_inv_transactions xhit
         WHERE xhit.stock_balance_list_div = cv_flg_i
           AND (xhit.invoice_date BETWEEN gd_target_date_start AND gd_target_date_end)
           AND  xhit.status = 1
-- == 2009/08/06 V1.1 Modified START ===============================================================
--            AND EXISTS (SELECT 1 FROM xxcoi_base_info2_v  xbiv 
--                        WHERE xbiv.focus_base_code = gr_param.base_code
--                        AND   xbiv.base_code IN(xhit.outside_base_code,xhit.inside_base_code))
            AND EXISTS (SELECT 1
                        FROM   hz_cust_accounts    hca
                              ,xxcmm_cust_accounts xca
                        WHERE  xca.management_base_code =  gr_param.base_code
                        AND    hca.account_number       IN (xhit.outside_base_code, xhit.inside_base_code)
                        AND    hca.status               =  'A'
                        AND    hca.customer_class_code  =  '1'
                        AND    hca.cust_account_id      =  xca.customer_id
                        UNION ALL
                        SELECT 1
                        FROM   hz_cust_accounts    hca
                              ,xxcmm_cust_accounts xca
                        WHERE  hca.account_number       =  gr_param.base_code
                        AND    hca.account_number       IN (xhit.outside_base_code, xhit.inside_base_code)
                        AND    hca.status               = 'A'
                        AND    hca.customer_class_code  = '1'
                        AND    hca.cust_account_id      = xca.customer_id
                        AND    hca.account_number      <> NVL(xca.management_base_code,'99999')
                       )
-- == 2009/08/06 V1.1 Modified END   ===============================================================
        GROUP BY
              xhit.base_code
             ,xhit.outside_base_code
             ,xhit.outside_code
             ,xhit.outside_subinv_code
             ,xhit.outside_cust_code
             ,xhit.outside_subinv_code_conv_div
             ,xhit.item_code
             ,xhit.invoice_date
             ,xhit.inside_base_code
             ,xhit.inside_code
             ,xhit.inside_subinv_code
             ,xhit.inside_cust_code
             ,xhit.inside_subinv_code_conv_div
             ,xhit.stock_balance_list_div ) inside                
      WHERE outside.outside_base_code            = inside.outside_base_code
        AND outside.outside_code                 = inside.outside_code
        AND outside.invoice_date                 = inside.invoice_date
        AND outside.item_code                    = inside.item_code
        AND outside.inside_base_code             = inside.inside_base_code
        AND outside.inside_code                  = inside.inside_code
        AND outside.sum_quantity                 = inside.sum_quantity
        ) hht                                                        -- 差異あり情報
      ,ic_item_mst_b              iimb                               -- OPM品目マスタ
      ,xxcmn_item_mst_b           ximb                               -- OPM品目マスタアドオン
      ,mtl_secondary_inventories  msi1                               -- 出庫側保管場所マスタ
      ,mtl_secondary_inventories  msi2                               -- 入庫側保管場所マスタ
      ,hz_cust_accounts           hca1                               -- 出庫側顧客アカウント
      ,hz_cust_accounts           hca2                               -- 入庫側顧客アカウント
-- == 2009/12/25 V1.3 Added START ===============================================================
      ,hz_parties                 hp1                                -- 入庫側パーティマスタ
      ,hz_parties                 hp2                                -- 出庫側パーティマスタ
-- == 2009/12/25 V1.3 Added END   ===============================================================
    WHERE  
          hht.outside_subinv_code = msi1.secondary_inventory_name
      AND msi1.organization_id    = gn_organization_id
      AND hht.inside_subinv_code  = msi2.secondary_inventory_name
      AND msi2.organization_id    = gn_organization_id
      AND hht.outside_cust_code   = hca1.account_number(+)
      AND hht.inside_cust_code    = hca2.account_number(+)
-- == 2009/12/25 V1.3 Added START ===============================================================
      AND hca1.party_id           = hp1.party_id(+)
      AND hca2.party_id           = hp2.party_id(+)
-- == 2009/12/25 V1.3 Added END   ===============================================================
      AND item_code               = iimb.item_no
      AND iimb.item_id            = ximb.item_id
      AND (hht.invoice_date BETWEEN ximb.start_date_active AND ximb.end_date_active)
    ORDER BY 
          DECODE(gr_param.output_standard,cv_standard,hht.inside_code,hht.outside_code)
         ,hht.invoice_date
         ,hht.item_code 
    ;    
--
    -- ローカル・レコード
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
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
    -- 差異有りHHT入出庫情報件数初期化
    gn_hht_info_cnt := 0;
--
    -- カーソルオープン
    OPEN info_hht_cur_a;
--
    -- レコード読込
    FETCH info_hht_cur_a BULK COLLECT INTO gt_hht_info_tab;
--
    -- HHT入出庫情報カウントセット
    gn_hht_info_cnt := gt_hht_info_tab.COUNT;
--
    -- カーソルクローズ
    CLOSE info_hht_cur_a;
--
    -- 対象処理件数
    gn_target_cnt := gn_target_cnt + gn_hht_info_cnt;
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
      IF ( info_hht_cur_a%ISOPEN ) THEN
        CLOSE info_hht_cur_a;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルがOPENしている場合
      IF ( info_hht_cur_a%ISOPEN ) THEN
        CLOSE info_hht_cur_a;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルがOPENしている場合
      IF ( info_hht_cur_a%ISOPEN ) THEN
        CLOSE info_hht_cur_a;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルがOPENしている場合
      IF ( info_hht_cur_a%ISOPEN ) THEN
        CLOSE info_hht_cur_a;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_hht_data_a;
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
    cv_profile_name     CONSTANT VARCHAR2(30)   := 'XXCOI1_ORGANIZATION_CODE';        -- プロファイル名(在庫組織コード)
    cv_output_standard  CONSTANT VARCHAR2(30)   := 'XXCOI1_OUTPUT_STANDARD';          -- 参照タイプ(出力基準)
    cv_output_term      CONSTANT VARCHAR2(30)   := 'XXCOI1_OUTPUT_TERM';              -- 参照タイプ(出力条件)
--
    -- *** ローカル変数 ***
    lv_organization_code mtl_parameters.organization_code%TYPE;  -- 在庫組織コード
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
    -- プロファイル値取得(在庫組織コード)   
    -- =====================================
    lv_organization_code := FND_PROFILE.VALUE(cv_profile_name);
    IF ( lv_organization_code IS NULL ) THEN
      -- エラーメッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg( 
                       iv_application  => cv_app_name
                     , iv_name         => cv_msg_xxcoi_00005
                     , iv_token_name1  => cv_token_pro
                     , iv_token_value1 => cv_profile_name
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
                     , iv_name         => cv_msg_xxcoi_00006
                     , iv_token_name1  => cv_token_org_code
                     , iv_token_value1 => lv_organization_code
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;         
--
    -- =====================================
    -- 拠点名称(略)取得                       
    -- =====================================
    BEGIN
      SELECT SUBSTRB(hca.account_name,1,8)  account_name
      INTO   gv_base_name
      FROM   hz_cust_accounts hca
      WHERE  hca.account_number = gr_param.base_code
      AND    hca.customer_class_code = cv_customer_class_code ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name
                       , iv_name         => cv_msg_xxcoi_00009
                       , iv_token_name1  => cv_token_dept_code
                       , iv_token_value1 => gr_param.base_code
                    );
        lv_errbuf := lv_errmsg;
        RAISE get_name_expt;
    END;
--
    -- =====================================
    -- 出力基準名取得                       
    -- =====================================
    gv_output_standard_name := xxcoi_common_pkg.get_meaning(
                                  iv_lookup_type => cv_output_standard
                                , iv_lookup_code => gr_param.output_standard
                              );
    IF (gv_output_standard_name IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                     , iv_name         => cv_msg_xxcoi_10021
                     , iv_token_name1  => cv_token_lookup_type
                     , iv_token_value1 => cv_output_standard
                     , iv_token_name2  => cv_token_lookup_code
                     , iv_token_value2 => gr_param.output_standard
                   );
      lv_errbuf := lv_errmsg;
      RAISE get_name_expt;
    END IF;
--
    -- =====================================
    -- 出力条件名取得                       
    -- =====================================
    gv_output_term_name := xxcoi_common_pkg.get_meaning(
                                iv_lookup_type => cv_output_term
                              , iv_lookup_code => gr_param.output_term
                            );
    IF (gv_output_term_name IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                     , iv_name         => cv_msg_xxcoi_10317
                     , iv_token_name1  => cv_token_lookup_type
                     , iv_token_value1 => cv_output_term
                     , iv_token_name2  => cv_token_lookup_code
                     , iv_token_value2 => gr_param.output_term
                   );
      lv_errbuf := lv_errmsg;
      RAISE get_name_expt;
    END IF;
--
    --==============================================================
    -- コンカレント入力パラメータ出力
    --==============================================================
    -- パラメータ.対象年月
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_app_name
                    , iv_name         =>  cv_msg_xxcoi_10355
                    , iv_token_name1  =>  cv_token_target_date
                    , iv_token_value1 =>  gr_param.target_date
                  );
    fnd_file.put_line(
      which  => FND_FILE.LOG
    , buff   => gv_out_msg
    );
--
    -- パラメータ.拠点
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_app_name
                    , iv_name         =>  cv_msg_xxcoi_10158
                    , iv_token_name1  =>  cv_token_base
                    , iv_token_value1 =>  gr_param.base_code
                  );
    fnd_file.put_line(
      which  => FND_FILE.LOG
    , buff   => gv_out_msg
    );
--
    -- パラメータ.出力基準
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_app_name
                    , iv_name         =>  cv_msg_xxcoi_10159
                    , iv_token_name1  =>  cv_token_standard
                    , iv_token_value1 =>  gv_output_standard_name
                  );
    fnd_file.put_line(
      which  => FND_FILE.LOG
    , buff   => gv_out_msg
    );
--
    -- パラメータ.出力条件
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_app_name
                    , iv_name         =>  cv_msg_xxcoi_10160
                    , iv_token_name1  =>  cv_token_term
                    , iv_token_value1 =>  gv_output_term_name
                  );
    fnd_file.put_line(
      which  => FND_FILE.LOG
    , buff   => gv_out_msg
    );
--
-- == 2010/11/29 V1.4 Added START ===============================================================
    --  対照拠点コード取得
    SELECT  DECODE(xca.dept_hht_div, '1', xca.management_base_code, hca.account_number)
    INTO    gt_base_code
    FROM    hz_cust_accounts      hca
          , xxcmm_cust_accounts   xca
    WHERE   hca.cust_account_id       =   xca.customer_id
    AND     hca.customer_class_code   =   '1'
    AND     hca.account_number        =   gr_param.base_code;
-- == 2010/11/29 V1.4 Added END   ===============================================================
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
    WHEN get_name_expt THEN                        --*** 名称取得エラー ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
    iv_target_date       IN  VARCHAR2,         --   1.対象年月
    iv_base_code         IN  VARCHAR2,         --   2.拠点
    iv_output_standard   IN  VARCHAR2,         --   3.出力基準
    iv_output_term       IN  VARCHAR2,         --   4.出力条件
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
    cv_output_term_0    CONSTANT VARCHAR2(1) := '0';       -- 出力条件(差異有り)
    cv_output_term_1    CONSTANT VARCHAR2(1) := '1';       -- 出力条件(差異無し)
    cv_output_term_2    CONSTANT VARCHAR2(1) := '2';       -- 出力条件(差異有無)
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
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
-- == 2010/11/29 V1.4 Added START ===============================================================
    gn_ins_cnt    := 0;
-- == 2010/11/29 V1.4 Added END   ===============================================================
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- =====================================================
    -- パラメータ値の格納
    -- =====================================================
    gr_param.target_date       := iv_target_date;        -- 01 : 対象年月  (必須)
    gr_param.base_code         := iv_base_code;          -- 02 : 拠点      (必須)
    gr_param.output_standard   := iv_output_standard;    -- 03 : 出力基準  (必須)
    gr_param.output_term       := iv_output_term;        -- 04 : 出力条件  (必須)
--
    -- =====================================================
    -- 対象年月の月初日と月末日を格納
    -- =====================================================
    gd_target_date_start := TO_DATE(gr_param.target_date||'-01','YYYY/MM/DD');
    gd_target_date_end   := LAST_DAY(gd_target_date_start);
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
-- == 2010/11/29 V1.4 Modified START ===============================================================
--    -- 出力条件が「差異有り」の場合
--    IF ( gr_param.output_term = cv_output_term_0 ) THEN
--         -- =====================================================
--         -- 差異有りHHT入出庫データ取得(A-2)
--         -- =====================================================
--         get_hht_data_a(
--            lv_errbuf            -- エラー・メッセージ           --# 固定 #
--          , lv_retcode           -- リターン・コード             --# 固定 #
--          , lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
--         );
--         IF ( lv_retcode = cv_status_error ) THEN
--           -- エラー処理
--           RAISE global_process_expt ;
--         END IF;
--    ELSIF
--      -- 出力条件が「差異無し」の場合
--      ( gr_param.output_term = cv_output_term_1 ) THEN
--         -- =====================================================
--         -- 差異無しHHT入出庫データ取得(A-4)
--         -- =====================================================
--         get_hht_data_b(
--             lv_errbuf            -- エラー・メッセージ           --# 固定 #
--           , lv_retcode           -- リターン・コード             --# 固定 #
--           , lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
--         );
--         IF ( lv_retcode = cv_status_error ) THEN
--           -- エラー処理
--           RAISE global_process_expt ;
--         END IF;
--    ELSIF
--      -- 出力条件が「差異有無」の場合
--      ( gr_param.output_term = cv_output_term_2 ) THEN
--        -- =====================================================
--        -- 差異有無HHT入出庫データ取得(A-6)
--        -- =====================================================
--        get_hht_data_c(
--            lv_errbuf            -- エラー・メッセージ           --# 固定 #
--          , lv_retcode           -- リターン・コード             --# 固定 #
--          , lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
--        );
--        IF ( lv_retcode = cv_status_error ) THEN
--          -- エラー処理
--          RAISE global_process_expt ;
--        END IF;
--    END IF;
    -- =====================================================
    -- 差異有無HHT入出庫データ取得(A-6)
    -- =====================================================
    get_hht_data_c(
        lv_errbuf            -- エラー・メッセージ           --# 固定 #
      , lv_retcode           -- リターン・コード             --# 固定 #
      , lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      -- エラー処理
      RAISE global_process_expt ;
    END IF;
-- == 2010/11/29 V1.4 Modified END   ===============================================================
--
    -- HHT入出庫データが1件以上取得できた場合
    IF ( gn_hht_info_cnt > 0 ) THEN
       lv_nodata_msg := NULL;
--
       -- HHT入出庫データループ開始
       <<gn_hht_info_cnt_loop>>
       FOR gn_hht_info_loop_cnt IN 1 .. gn_hht_info_cnt LOOP
--
-- == 2010/11/29 V1.4 Added START ===============================================================
        IF  (     gr_param.output_term = cv_output_term_0
              AND gt_hht_info_tab(gn_hht_info_loop_cnt).outside_qty <> gt_hht_info_tab(gn_hht_info_loop_cnt).inside_qty
            )
            OR
            (     gr_param.output_term = cv_output_term_1
              AND gt_hht_info_tab(gn_hht_info_loop_cnt).outside_qty =  gt_hht_info_tab(gn_hht_info_loop_cnt).inside_qty
            )
            OR
            (gr_param.output_term = cv_output_term_2)
        THEN
          --  パラメータ差異ありで、入庫数量、出庫数量不一致のデータ
          --  パラメータ差異なしで、入庫数量、出庫数量一致のデータ
          --  パラメータ差異有無で、全データ
-- == 2010/11/29 V1.4 Added END   ===============================================================
          -- ======================================
          -- ワークテーブルデータ登録(A-3,A-5,A-7)
          -- ======================================
          ins_work(
              gn_hht_info_loop_cnt => gn_hht_info_loop_cnt -- HHT入出庫データループカウンタ
            , ov_errbuf            => lv_errbuf            -- エラー・メッセージ           --# 固定 #
            , ov_retcode           => lv_retcode           -- リターン・コード             --# 固定 #
            , ov_errmsg            => lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
          );
--
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
-- == 2010/11/29 V1.4 Added START ===============================================================
        END IF;
-- == 2010/11/29 V1.4 Added END   ===============================================================
--
       END LOOP gn_hht_info_cnt_loop;
--
    END IF;
--
    -- 出力対象件数が0件の場合、ワークテーブルにパラメータ情報のみを登録
-- == 2010/11/29 V1.4 Modified START ===============================================================
--    IF (gn_target_cnt = 0) THEN
    IF (gn_ins_cnt = 0) THEN
-- == 2010/11/29 V1.4 Modified END   ===============================================================
--
      -- 0件メッセージの取得
      lv_nodata_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name
                          ,iv_name         => cv_msg_xxcoi_00008
                         );
--
      -- ==============================================
      --  ワークテーブルデータ登録(0件)(A-8)
      -- ==============================================
      ins_work_zero(
           iv_nodata_msg        => lv_nodata_msg        -- ゼロ件メッセージ
         , ov_errbuf            => lv_errbuf            -- エラー・メッセージ           --# 固定 #
         , ov_retcode           => lv_retcode           -- リターン・コード             --# 固定 #
         , ov_errmsg            => lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
      );
      -- 終了パラメータ判定
      IF ( lv_retcode = cv_status_error ) THEN
        -- エラー処理
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- =====================================================
    -- SVF起動(A-9)
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
    -- ワークテーブルデータ削除(A-10)
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
    iv_target_date       IN  VARCHAR2,      --   1.対象年月
    iv_base_code         IN  VARCHAR2,      --   2.拠点
    iv_output_standard   IN  VARCHAR2,      --   3.出力基準
    iv_output_term       IN  VARCHAR2)      --   4.出力条件
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
       iv_which   =>  cv_log
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
       iv_target_date       --   1.対象年月
      ,iv_base_code         --   2.拠点
      ,iv_output_standard   --   3.出力基準
      ,iv_output_term       --   4.出力条件
      ,lv_errbuf       -- エラー・メッセージ           --# 固定 #
      ,lv_retcode      -- リターン・コード             --# 固定 #
      ,lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
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
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
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
END XXCOI003A05R;
/
