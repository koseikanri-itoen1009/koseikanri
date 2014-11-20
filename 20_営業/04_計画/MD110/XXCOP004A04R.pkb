CREATE OR REPLACE PACKAGE BODY XXCOP004A04R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP004A04R(body)
 * Description      : 引取計画チェックリスト出力ワーク登録
 * MD.050           : 引取計画チェックリスト MD050_COP_004_A04
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  get_target_base_code   対象拠点取得（配下拠点）（A-2）
 *  qty_editing_data_keep  数量振分け・データ保持(A-4)
 *  insert_check_list      引取計画チェックリスト帳票ワークデータ登録(A-5)
 *  svf_call               SVF起動(A-6) 
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/03    1.0  SCS.Kikuchi       新規作成
 *  2009/03/03    1.1  SCS.Kikuchi       SVF結合対応
 *  2009/11/17    1.2  SCS.Miyagawa      SVFファイル名対応
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
--★1.1 2009/03/03 Add Start
  internal_process_expt        EXCEPTION;     -- 内部PROCEDURE/FUNCTIONエラーハンドリング用
--★1.1 2009/03/03 Add End
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                  CONSTANT VARCHAR2(100) := 'XXCOP004A04R';    -- パッケージ名
  cv_target_month_format       CONSTANT VARCHAR2(6)   := 'YYYYMM';          -- パラメータ：対象年月書式
  cv_customer_class_code_base  CONSTANT VARCHAR2(1)   := '1';               -- 顧客区分（拠点）
  cv_forecast_class            CONSTANT VARCHAR2(2)   := '01';              -- フォーキャスト分類：引取計画
  
  -- 入力パラメータログ出力用
  cv_pm_target_month_tl       CONSTANT VARCHAR2(100) := '対象年月';
  cv_pm_prod_class_code_tl    CONSTANT VARCHAR2(100) := '商品区分';
  cv_pm_base_code_tl          CONSTANT VARCHAR2(100) := '拠点';
  cv_pm_whse_code_tl          CONSTANT VARCHAR2(100) := '出荷元倉庫';
  cv_pm_part                  CONSTANT VARCHAR2(6)   := '　：　';

--★1.1 2009/03/03 Add Start
  -- メッセージ関連
  cv_msg_application          CONSTANT VARCHAR2(100) := 'XXCOP';
  cv_others_err_msg           CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00041'; -- CSVｱｳﾄﾌﾟｯﾄ機能システムエラーメッセージ
  cv_others_err_msg_tkn_lbl1  CONSTANT VARCHAR2(100) := 'ERRMSG';
  cv_api_err_msg              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00016'; -- API起動エラー
  cv_api_err_msg_tkn_lbl1     CONSTANT VARCHAR2(100) := 'PRG_NAME';
  cv_api_err_msg_tkn_lbl1_val CONSTANT VARCHAR2(100) := 'XXCCP_SVFCOMMON_PKG.SUBMIT_SVF_REQUEST';
  cv_api_err_msg_tkn_lbl2     CONSTANT VARCHAR2(100) := 'ERR_MSG';

  -- SVF出力対応
--★1.2 2009/11/17 Del Start
--  cv_svf_date_format          CONSTANT VARCHAR2(16)  := 'YYYYMMDDHH24MISS';     -- パラメータ：対象年月書式
--  cv_file_name                CONSTANT VARCHAR2(40)  := 'XXCOP004A04R'
--                                                        || TO_CHAR(SYSDATE,cv_svf_date_format)
--                                                        || '.pdf';              -- 出力ファイル名
--★1.2 2009/11/17 Del End
--★1.2 2009/11/17 Add Start
  cv_svf_date_format          CONSTANT VARCHAR2(16)  := 'YYYYMMDD';     -- パラメータ：対象年月書式
  cv_file_name                CONSTANT VARCHAR2(40)  := cv_pkg_name
                                                        || TO_CHAR(SYSDATE,cv_svf_date_format)
                                                        || cn_request_id
                                                        || '.pdf';              -- 出力ファイル名
--★1.2 2009/11/17 Add End
  cv_output_mode              CONSTANT VARCHAR2(1)   := '1';                    -- 出力区分：”１”（ＰＤＦ）
  cv_frm_file                 CONSTANT VARCHAR2(20)  := 'XXCOP004A04S.xml';     -- フォーム様式ファイル名
  cv_vrq_file                 CONSTANT VARCHAR2(20)  := 'XXCOP004A04S.vrq';     -- クエリー様式ファイル名

--★1.1 2009/03/03 Add End
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 引取計画チェックリスト出力対象拠点レコード型
  TYPE target_base_trec IS RECORD(
      account_number           hz_cust_accounts.account_number %TYPE  -- 顧客コード
    , base_short_name          xxcmn_parties.party_short_name  %TYPE  -- 拠点名
    );

  -- 引取計画チェックリスト出力対象拠点PL/SQL表
  TYPE target_base_ttype IS
    TABLE OF target_base_trec INDEX BY BINARY_INTEGER;

  -- 引取計画チェックリスト出力データレコード
  TYPE check_list_data_trec IS RECORD(
      target_month     xxcop_rep_forecast_check_list.target_month %TYPE     -- 対象年月
    , prod_class_code  xxcop_item_categories1_v.prod_class_code   %TYPE     -- 商品区分
    , prod_class_name  xxcop_item_categories1_v.prod_class_name   %TYPE     -- 商品区分名
    , base_code        mrp_forecast_designators.attribute3        %TYPE     -- 拠点コード
    , base_short_name  xxcmn_parties.party_short_name             %TYPE     -- 拠点名
    , whse_code        mrp_forecast_designators.attribute2        %TYPE     -- 出荷元倉庫コード
    , whse_short_name  mtl_item_locations.attribute11             %TYPE     -- 出荷元倉庫名
    , crowd_class_code xxcop_item_categories1_v.crowd_class_code  %TYPE     -- 群コード
    , item_no          xxcop_item_categories1_v.item_no           %TYPE     -- 商品コード
    , item_short_name  xxcop_item_categories1_v.item_short_name   %TYPE     -- 商品名
    , num_of_cases     xxcop_item_categories1_v.num_of_cases      %TYPE     -- ケース入数
    );

  -- 引取計画チェックリスト引取計画数量（1～末日）PL/SQL表
  TYPE check_list_qty_ttype IS
    TABLE OF xxcop_rep_forecast_check_list.forecast_quantity_day1%TYPE INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 入力パラメータ格納用
  gv_target_month              VARCHAR2(6);
  gv_prod_class_code           VARCHAR2(1);
  gv_base_code                 VARCHAR2(4);
  gv_whse_code                 VARCHAR2(4);

  -- 対象年月開始日、終了日、システム日付格納用
  gd_target_month_start_day    DATE;
  gd_target_month_end_day      DATE;
  gd_system_date               DATE;

  -- 出力対象データ格納用
  g_target_base_tbl            target_base_ttype;     -- 引取計画チェックリスト出力対象拠点
  g_target_base_tbl_init       target_base_ttype;     -- 引取計画チェックリスト出力対象拠点初期化用
  g_check_list_data_rec        check_list_data_trec;  -- 引取計画チェックリスト出力データ
  g_check_list_data_rec_init   check_list_data_trec;  -- 引取計画チェックリスト出力データ初期化用
  g_check_list_qty_tbl         check_list_qty_ttype;  -- 引取計画チェックリスト引取計画数量（1～末日）
  g_check_list_qty_tbl_init    check_list_qty_ttype;  -- 引取計画チェックリスト引取計画数量（1～末日）初期化用

  -- 明細0件メッセージ格納用
  gv_rep_no_data_msg           VARCHAR2(5000);

  gv_debug_mode                VARCHAR2(30);          -- デバッグ出力判定用
--
--
--
  /**********************************************************************************
   * Procedure Name   : get_target_base_code
   * Description      : 対象拠点取得（配下拠点）（A-2）
   ***********************************************************************************/
  PROCEDURE get_target_base_code(
     ov_errbuf            OUT VARCHAR2    --   エラー・メッセージ           --# 固定 #
   , ov_retcode           OUT VARCHAR2    --   リターン・コード             --# 固定 #
   , ov_errmsg            OUT VARCHAR2    --   ユーザー・エラー・メッセージ --# 固定 #
  )IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_target_base_code'; -- プログラム名
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
    SELECT hca.account_number   account_number     -- 顧客コード
    ,      xp.party_short_name  base_short_name    -- 拠点名
    BULK COLLECT
    INTO   g_target_base_tbl
    FROM   hz_cust_accounts         hca            -- 顧客マスタ
    ,      xxcmn_parties            xp             -- パーティアドオンマスタ
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
  END get_target_base_code;
--
  /**********************************************************************************
   * Procedure Name   : qty_editing_data_keep
   * Description      : 数量振分け・データ保持(A-4)
   ***********************************************************************************/
  PROCEDURE qty_editing_data_keep(
     id_forecast_date     IN  mrp_forecast_dates.forecast_date%type              -- フォーキャスト日付
   , in_forecast_qty      IN  mrp_forecast_dates.original_forecast_quantity%type -- 日別計画数量
   , in_num_of_cases      IN  xxcop_item_categories1_v.num_of_cases%type         -- ケース入数
   , iv_prod_class_code   IN  xxcop_item_categories1_v.prod_class_code%type      -- 商品区分
   , iv_prod_class_name   IN  xxcop_item_categories1_v.prod_class_name%type      -- 商品区分名
   , iv_base_code         IN  mrp_forecast_designators.attribute3%type           -- 拠点コード
   , iv_base_short_name   IN  xxcmn_parties.party_short_name%type                -- 拠点名
   , iv_whse_code         IN  mrp_forecast_designators.attribute2%type           -- 出荷元倉庫コード
   , iv_whse_short_name   IN  mtl_item_locations.attribute12%type                -- 出荷元倉庫名
   , iv_crowd_class_code  IN  xxcop_item_categories1_v.crowd_class_code%type     -- 群コード
   , iv_item_no           IN  xxcop_item_categories1_v.item_no%type              -- 商品コード
   , iv_item_short_name   IN  xxcop_item_categories1_v.item_short_name%type      -- 商品名
   , ov_errbuf            OUT VARCHAR2    --   エラー・メッセージ           --# 固定 #
   , ov_retcode           OUT VARCHAR2    --   リターン・コード             --# 固定 #
   , ov_errmsg            OUT VARCHAR2    --   ユーザー・エラー・メッセージ --# 固定 #
     
  )IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_xxcop_rep_forecast_check_list'; -- プログラム名
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
    ln_index number;
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
    -- フォーキャスト日付の日にちをPL/SQL表のindex番号に設定する。
    ln_index := TO_NUMBER(TO_CHAR(id_forecast_date,'dd'));

    -- PL/SQL表に引取計画数量（フォーキャスト数量÷ケース入数）を少数切捨し、格納する。
    g_check_list_qty_tbl(ln_index) := TRUNC( in_forecast_qty / NVL( in_num_of_cases ,1 ) );

    -- indexゼロを合計として加算する。
    g_check_list_qty_tbl(0) := NVL(g_check_list_qty_tbl(0),0) + NVL(g_check_list_qty_tbl(ln_index),0);

    -- ブレイク判定・テーブル登録用にデータを保持する。

    -- 対象年月の編集
    g_check_list_data_rec.target_month     := SUBSTRB(TO_CHAR(id_forecast_date,cv_target_month_format),1,6);

    g_check_list_data_rec.prod_class_code  := iv_prod_class_code;            -- 商品区分
    g_check_list_data_rec.prod_class_name  := iv_prod_class_name;            -- 商品区分名
    g_check_list_data_rec.base_code        := iv_base_code;                  -- 拠点コード
    g_check_list_data_rec.base_short_name  := iv_base_short_name;            -- 拠点名
    g_check_list_data_rec.whse_code        := iv_whse_code;                  -- 出荷元倉庫コード
    g_check_list_data_rec.whse_short_name  := iv_whse_short_name;            -- 出荷元倉庫名
    g_check_list_data_rec.crowd_class_code := iv_crowd_class_code;           -- 群コード
    g_check_list_data_rec.item_no          := iv_item_no;                    -- 商品コード
    g_check_list_data_rec.item_short_name  := iv_item_short_name;            -- 商品名

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
--
  /**********************************************************************************
   * Procedure Name   : insert_check_list
   * Description      : 引取計画チェックリスト帳票ワークデータ登録(A-5)
   ***********************************************************************************/
  PROCEDURE insert_check_list(
     ov_errbuf   OUT VARCHAR2            --   エラー・メッセージ           --# 固定 #
   , ov_retcode  OUT VARCHAR2            --   リターン・コード             --# 固定 #
   , ov_errmsg   OUT VARCHAR2            --   ユーザー・エラー・メッセージ --# 固定 #
  )IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_xxcop_rep_forecast_check_list'; -- プログラム名
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
    -- 引取計画チェックリスト帳票ワークテーブルデータ登録処理
    -----------------------------------------------------------------
    INSERT INTO xxcop_rep_forecast_check_list
      ( target_month                   -- 対象年月
      , prod_class_code                -- 商品区分
      , prod_class_name                -- 商品区分名
      , base_code                      -- 拠点コード
      , base_short_name                -- 拠点名
      , whse_code                      -- 出荷元倉庫コード
      , whse_short_name                -- 出荷元倉庫名
      , crowd_class_code               -- 群コード
      , item_no                        -- 商品コード
      , item_short_name                -- 商品名
      , forecast_quantity_total        -- 合計  引取計画数量
      , forecast_quantity_day1         -- 1日  引取計画数量
      , forecast_quantity_day2         -- 2日  引取計画数量
      , forecast_quantity_day3         -- 3日  引取計画数量
      , forecast_quantity_day4         -- 4日  引取計画数量
      , forecast_quantity_day5         -- 5日  引取計画数量
      , forecast_quantity_day6         -- 6日  引取計画数量
      , forecast_quantity_day7         -- 7日  引取計画数量
      , forecast_quantity_day8         -- 8日  引取計画数量
      , forecast_quantity_day9         -- 9日  引取計画数量
      , forecast_quantity_day10        -- 10日 引取計画数量
      , forecast_quantity_day11        -- 11日 引取計画数量
      , forecast_quantity_day12        -- 12日 引取計画数量
      , forecast_quantity_day13        -- 13日 引取計画数量
      , forecast_quantity_day14        -- 14日 引取計画数量
      , forecast_quantity_day15        -- 15日 引取計画数量
      , forecast_quantity_day16        -- 16日 引取計画数量
      , forecast_quantity_day17        -- 17日 引取計画数量
      , forecast_quantity_day18        -- 18日 引取計画数量
      , forecast_quantity_day19        -- 19日 引取計画数量
      , forecast_quantity_day20        -- 20日 引取計画数量
      , forecast_quantity_day21        -- 21日 引取計画数量
      , forecast_quantity_day22        -- 22日 引取計画数量
      , forecast_quantity_day23        -- 23日 引取計画数量
      , forecast_quantity_day24        -- 24日 引取計画数量
      , forecast_quantity_day25        -- 25日 引取計画数量
      , forecast_quantity_day26        -- 26日 引取計画数量
      , forecast_quantity_day27        -- 27日 引取計画数量
      , forecast_quantity_day28        -- 28日 引取計画数量
      , forecast_quantity_day29        -- 29日 引取計画数量
      , forecast_quantity_day30        -- 30日 引取計画数量
      , forecast_quantity_day31        -- 31日 引取計画数量
      , created_by                     -- 作成者
      , creation_date                  -- 作成日
      , last_updated_by                -- 最終更新者
      , last_update_date               -- 最終更新日
      , last_update_login              -- 最終更新ログイン
      , request_id                     -- 要求ID
      , program_application_id         -- プログラムアプリケーションID
      , program_id                     -- プログラムID
      , program_update_date            -- プログラム更新日
      )
    VALUES
      ( g_check_list_data_rec.target_month               -- 対象年月
      , g_check_list_data_rec.prod_class_code            -- 商品区分
      , g_check_list_data_rec.prod_class_name            -- 商品区分名
      , g_check_list_data_rec.base_code                  -- 拠点コード
      , g_check_list_data_rec.base_short_name            -- 拠点名
      , g_check_list_data_rec.whse_code                  -- 出荷元倉庫コード
      , g_check_list_data_rec.whse_short_name            -- 出荷元倉庫名
      , g_check_list_data_rec.crowd_class_code           -- 群コード
      , g_check_list_data_rec.item_no                    -- 商品コード
      , g_check_list_data_rec.item_short_name            -- 商品名
      , g_check_list_qty_tbl(0)                          -- 合計  引取計画数量
      , g_check_list_qty_tbl(1)                          -- 1日  引取計画数量
      , g_check_list_qty_tbl(2)                          -- 2日  引取計画数量
      , g_check_list_qty_tbl(3)                          -- 3日  引取計画数量
      , g_check_list_qty_tbl(4)                          -- 4日  引取計画数量
      , g_check_list_qty_tbl(5)                          -- 5日  引取計画数量
      , g_check_list_qty_tbl(6)                          -- 6日  引取計画数量
      , g_check_list_qty_tbl(7)                          -- 7日  引取計画数量
      , g_check_list_qty_tbl(8)                          -- 8日  引取計画数量
      , g_check_list_qty_tbl(9)                          -- 9日  引取計画数量
      , g_check_list_qty_tbl(10)                         -- 10日 引取計画数量
      , g_check_list_qty_tbl(11)                         -- 11日 引取計画数量
      , g_check_list_qty_tbl(12)                         -- 12日 引取計画数量
      , g_check_list_qty_tbl(13)                         -- 13日 引取計画数量
      , g_check_list_qty_tbl(14)                         -- 14日 引取計画数量
      , g_check_list_qty_tbl(15)                         -- 15日 引取計画数量
      , g_check_list_qty_tbl(16)                         -- 16日 引取計画数量
      , g_check_list_qty_tbl(17)                         -- 17日 引取計画数量
      , g_check_list_qty_tbl(18)                         -- 18日 引取計画数量
      , g_check_list_qty_tbl(19)                         -- 19日 引取計画数量
      , g_check_list_qty_tbl(20)                         -- 20日 引取計画数量
      , g_check_list_qty_tbl(21)                         -- 21日 引取計画数量
      , g_check_list_qty_tbl(22)                         -- 22日 引取計画数量
      , g_check_list_qty_tbl(23)                         -- 23日 引取計画数量
      , g_check_list_qty_tbl(24)                         -- 24日 引取計画数量
      , g_check_list_qty_tbl(25)                         -- 25日 引取計画数量
      , g_check_list_qty_tbl(26)                         -- 26日 引取計画数量
      , g_check_list_qty_tbl(27)                         -- 27日 引取計画数量
      , g_check_list_qty_tbl(28)                         -- 28日 引取計画数量
      , g_check_list_qty_tbl(29)                         -- 29日 引取計画数量
      , g_check_list_qty_tbl(30)                         -- 30日 引取計画数量
      , g_check_list_qty_tbl(31)                         -- 31日 引取計画数量
      , cn_created_by                                    -- 作成者
      , cd_creation_date                                 -- 作成日
      , cn_last_updated_by                               -- 最終更新者
      , cd_last_update_date                              -- 最終更新日
      , cn_last_update_login                             -- 最終更新ログイン
      , cn_request_id                                    -- 要求ID
      , cn_program_application_id                        -- プログラムアプリケーションID
      , cn_program_id                                    -- プログラムID
      , cd_program_update_date                           -- プログラム更新日
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
  END insert_check_list;
--
--
--★1.1 2009/03/03 Add Start
  /**********************************************************************************
   * Procedure Name   : svf_call
   * Description      : SVF起動(A-6)
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
--★1.1 2009/03/03 Add End
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_target_month     IN     VARCHAR2,     -- 1.対象年月
    iv_prod_class_code  IN     VARCHAR2,     -- 2.商品区分
    iv_base_code        IN     VARCHAR2,     -- 3.拠点
    iv_whse_code        IN     VARCHAR2,     -- 4.出荷元倉庫
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
    cv_msg_application         CONSTANT VARCHAR2(100) := 'XXCOP' ;               -- 正常終了メッセージ
    cv_param_chk1_msg          CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00029';     -- 対象年月チェックエラーメッセージ
    cv_param_chk1_msg_tkn_lbl  CONSTANT VARCHAR2(100) := 'item';                 --   トークン名
    cv_param_chk1_msg_tkn_val  CONSTANT VARCHAR2(100) := '対象年月';             --   トークンセット値
--
    -- *** ローカル変数 ***
    ln_which NUMBER;
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- A-3 出力データ取得カーソル
    CURSOR get_output_data_cur(
      civ_base_code  IN  VARCHAR2
    )IS
      SELECT xic1v.prod_class_code            prod_class_code             -- 商品区分
      ,      xic1v.prod_class_name            prod_class_name             -- 商品区分名
      ,      mfde.attribute3                  base_code                   -- 拠点コード
      ,      mfde.attribute2                  whse_code                   -- 出荷元倉庫コード
      ,      mil.attribute12                  whse_short_name             -- 出荷元倉庫名
      ,      xic1v.crowd_class_code           crowd_class_code            -- 群コード
      ,      xic1v.item_no                    item_no                     -- 商品コード
      ,      xic1v.item_short_name            item_short_name             -- 商品名
      ,      mfda.forecast_date               forecast_date               -- フォーキャスト日付
      ,      mfda.original_forecast_quantity  original_forecast_quantity  -- 数量
      ,      xic1v.num_of_cases               num_of_cases                -- ケース入数
      FROM
             mrp_forecast_designators mfde                                -- フォーキャスト名
      ,      mrp_forecast_dates       mfda                                -- フォーキャスト日付
      ,      xxcop_item_categories1_v xic1v                               -- 計画_品目カテゴリビュー1
      ,      mtl_item_locations       mil                                 -- OPM保管場所マスタ
      WHERE
             mfde.forecast_designator =  mfda.forecast_designator
      AND    mfde.organization_id     =  mfda.organization_id
      AND    mfde.attribute1          =  cv_forecast_class                                 -- FORECAST分類：引取計画
      AND    mfde.attribute2          =  nvl( gv_whse_code ,mfde.attribute2 )              -- 出庫元倉庫
      AND    mfde.attribute3          =  civ_base_code                                     -- 拠点コード
      AND    mfda.forecast_date       BETWEEN gd_target_month_start_day
                                      AND     gd_target_month_end_day
      AND    xic1v.inventory_item_id  =  mfda.inventory_item_id
      AND    xic1v.start_date_active  <= gd_system_date
      AND    xic1v.end_date_active    >= gd_system_date
      AND    xic1v.prod_class_code    =  nvl( gv_prod_class_code ,xic1v.prod_class_code )  -- 商品区分
      AND    mil.segment1             =  mfde.attribute2                                   -- 出庫元倉庫
      ORDER
      BY     xic1v.prod_class_code                     -- 商品区分
      ,      mfde.attribute3                           -- 拠点コード
      ,      mfde.attribute2                           -- 出荷元倉庫コード
      ,      xic1v.crowd_class_code                    -- 群コード
      ,      xic1v.item_no                             -- 商品コード
      ,      mfda.forecast_date                        -- フォーキャスト日付
      ;
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
--    FOR ix IN 1..2 LOOP      --★1.1 2009/03/03 Upd
    -- 出力先はログのみとする
    FOR ix IN 1..1 LOOP        --★1.1 2009/03/03 Upd
    
      IF (ix=1) THEN
        ln_which := FND_FILE.LOG;
      ELSE
        ln_which := FND_FILE.OUTPUT;
      END IF;

      FND_FILE.PUT_LINE(ln_which,'');    -- 改行
      FND_FILE.PUT_LINE(ln_which,cv_pm_target_month_tl    || cv_pm_part  || iv_target_month    );
      FND_FILE.PUT_LINE(ln_which,cv_pm_prod_class_code_tl || cv_pm_part  || iv_prod_class_code );
      FND_FILE.PUT_LINE(ln_which,cv_pm_base_code_tl       || cv_pm_part  || iv_base_code       );
      FND_FILE.PUT_LINE(ln_which,cv_pm_whse_code_tl       || cv_pm_part  || iv_whse_code       );
      FND_FILE.PUT_LINE(ln_which,'');    -- 改行

    END LOOP;

    -- グローバル変数にパラメータを設定
    gv_target_month    := RTRIM( iv_target_month );
    gv_prod_class_code := RTRIM( iv_prod_class_code );
    gv_base_code       := RTRIM( iv_base_code );
    gv_whse_code       := RTRIM( iv_whse_code );
    
    -- PLSQL表クリア用ワーク初期化
    FOR ix IN 0..31 LOOP
      g_check_list_qty_tbl_init(ix) := 0;
    END LOOP;
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
    -- 2.パラメータチェック
    --   要求発行画面のパラメータ入力時に即時チェック済み
    -- ===============================
    -- 抽出対象年月日設定
    --   開始日       … 入力パラメータ対象年月の１日    ０時  ０分  ０秒
    --   終了日       … 入力パラメータ対象年月の月末日２３時５９分５９秒
    --   マスタ基準日 … システム日付（時分秒切捨て）
    gd_target_month_start_day := TO_DATE(gv_target_month,cv_target_month_format);
    gd_target_month_end_day   := ADD_MONTHS(TO_DATE(gv_target_month,cv_target_month_format),1) - (1/24/60/60);
    gd_system_date            := TRUNC(SYSDATE);

    -- ===============================
    --  A-2 対象拠点取得（配下拠点）
    -- ===============================
    get_target_base_code(
      lv_errbuf                            -- エラー・メッセージ           --# 固定 #
     ,lv_retcode                           -- リターン・コード             --# 固定 #
     ,lv_errmsg                            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;

    <<a2_get_target_base_loop>>
    FOR ix IN 1..g_target_base_tbl.COUNT LOOP

      -- 登録用レコードワーククリア
      g_check_list_data_rec := g_check_list_data_rec_init;
      g_check_list_qty_tbl  := g_check_list_qty_tbl_init;

      -- ===============================
      --       A-3 出力データ取得
      -- ===============================
      <<a3_get_output_data_loop>>
      FOR get_output_data_rec IN get_output_data_cur(g_target_base_tbl(ix).account_number)
      LOOP
        -- 振分けキーがブレイクした場合、ワークテーブル登録を行なう。
        IF (  (g_check_list_data_rec.prod_class_code <> get_output_data_rec.prod_class_code)
           OR (g_check_list_data_rec.base_code       <> get_output_data_rec.base_code)
           OR (g_check_list_data_rec.whse_code       <> get_output_data_rec.whse_code)
           OR (g_check_list_data_rec.item_no         <> get_output_data_rec.item_no)
           ) THEN
          -- ===============================
          --  A-5 ワークテーブルデータ登録
          -- ===============================
          insert_check_list(
            lv_errbuf                            -- エラー・メッセージ           --# 固定 #
           ,lv_retcode                           -- リターン・コード             --# 固定 #
           ,lv_errmsg                            -- ユーザー・エラー・メッセージ --# 固定 #
          );
          IF (lv_retcode = cv_status_error) THEN
            gn_error_cnt := gn_error_cnt + 1;
            RAISE global_process_expt;
          END IF;

          -- 登録用レコードワーククリア
          g_check_list_data_rec := g_check_list_data_rec_init;
          g_check_list_qty_tbl  := g_check_list_qty_tbl_init;
        END IF;

        -- ===============================
        --   A-4 数量振分け・データ保持
        -- ===============================
        qty_editing_data_keep(
          id_forecast_date    => get_output_data_rec.forecast_date               -- フォーキャスト日付
         ,in_forecast_qty     => get_output_data_rec.original_forecast_quantity  -- 日別計画数量
         ,in_num_of_cases     => get_output_data_rec.num_of_cases                -- ケース入数
         ,iv_prod_class_code  => get_output_data_rec.prod_class_code             -- 商品区分
         ,iv_prod_class_name  => get_output_data_rec.prod_class_name             -- 商品区分名
         ,iv_base_code        => get_output_data_rec.base_code                   -- 拠点コード
         ,iv_base_short_name  => g_target_base_tbl(ix).base_short_name           -- 拠点名
         ,iv_whse_code        => get_output_data_rec.whse_code                   -- 出荷元倉庫コード
         ,iv_whse_short_name  => get_output_data_rec.whse_short_name             -- 出荷元倉庫名
         ,iv_crowd_class_code => get_output_data_rec.crowd_class_code            -- 群コード
         ,iv_item_no          => get_output_data_rec.item_no                     -- 商品コード
         ,iv_item_short_name  => get_output_data_rec.item_short_name             -- 商品名
         ,ov_errbuf           => lv_errbuf       -- エラー・メッセージ           --# 固定 #
         ,ov_retcode          => lv_retcode      -- リターン・コード             --# 固定 #
         ,ov_errmsg           => lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
         );

        IF (lv_retcode = cv_status_error) THEN
          gn_error_cnt := gn_error_cnt + 1;
          RAISE global_process_expt;
        END IF;

      END LOOP a3_get_output_data_loop;

      -- 対象データが存在した場合（品目が設定されている場合）、
      -- 最終データはブレイクと判断し、ワーク登録を行なう。
      IF (g_check_list_data_rec.item_no IS NOT NULL) THEN

        -- ===============================
        --  A-5 ワークテーブルデータ登録
        -- ===============================
        insert_check_list(
          lv_errbuf                            -- エラー・メッセージ           --# 固定 #
         ,lv_retcode                           -- リターン・コード             --# 固定 #
         ,lv_errmsg                            -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode = cv_status_error) THEN
          gn_error_cnt := gn_error_cnt + 1;
          RAISE global_process_expt;
        END IF;

      END IF;

    END LOOP a2_get_output_data_loop;

    -- 出力件数カウントアップ
    gn_target_cnt := gn_normal_cnt;

    -- SVF起動前にコミットを行なう
    COMMIT;

--★1.1 2009/03/03 Add Start
    -- ===============================
    --  A-6 SVF起動
    -- ===============================
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
    --  A-7 ワークテーブルデータ削除
    -- ===============================
    DELETE
    FROM    xxcop_rep_forecast_check_list
    WHERE   REQUEST_ID = cn_request_id
    ;

  EXCEPTION
    -- *** 任意で例外処理を記述する ****
    -- カーソルのクローズをここに記述する
    WHEN internal_process_expt THEN
      ov_errmsg  := lv_errmsg;
      IF (lv_errbuf IS NULL) THEN
        ov_errbuf := NULL;
      ELSE
        ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      END IF;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt	 THEN
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
    iv_target_month     IN  VARCHAR2,      -- 1.対象年月
    iv_prod_class_code  IN  VARCHAR2,      -- 2.商品区分
    iv_base_code        IN  VARCHAR2,      -- 3.拠点
    iv_whse_code        IN  VARCHAR2       -- 4.出荷元倉庫
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
       iv_target_month     -- 1.対象年月
      ,iv_prod_class_code  -- 2.商品区分
      ,iv_base_code        -- 3.拠点
      ,iv_whse_code        -- 4.出荷元倉庫
      ,lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,lv_retcode          -- リターン・コード             --# 固定 #
      ,lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
--★1.1 2009/03/03 Upd Start
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
--★1.1 2009/03/03 Upd End
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT   --★1.1 2009/03/03 Upd
       which  => FND_FILE.LOG        --★1.1 2009/03/03 Upd
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
--       which  => FND_FILE.OUTPUT   --★1.1 2009/03/03 Upd
       which  => FND_FILE.LOG        --★1.1 2009/03/03 Upd
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
--       which  => FND_FILE.OUTPUT   --★1.1 2009/03/03 Upd
       which  => FND_FILE.LOG        --★1.1 2009/03/03 Upd
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
--       which  => FND_FILE.OUTPUT   --★1.1 2009/03/03 Upd
       which  => FND_FILE.LOG        --★1.1 2009/03/03 Upd
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
--       which  => FND_FILE.OUTPUT   --★1.1 2009/03/03 Upd
       which  => FND_FILE.LOG        --★1.1 2009/03/03 Upd
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
--       which  => FND_FILE.OUTPUT   --★1.1 2009/03/03 Upd
       which  => FND_FILE.LOG        --★1.1 2009/03/03 Upd
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
END XXCOP004A04R;
/
