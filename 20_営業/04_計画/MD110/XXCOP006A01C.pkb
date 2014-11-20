CREATE OR REPLACE PACKAGE BODY XXCOP006A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP006A01C(body)
 * Description      : 横持計画
 * MD.050           : 横持計画 MD050_COP_006_A01
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理                                             (A-1)
 *  delete_table           テーブルデータ削除処理                               (A-2)
 *  request_conc           子コンカレント発行処理                               (A-3)
 *  output_xwypo           横持計画CSV出力                                      (A-4)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/11/13    1.0   M.Hokkanji       新規作成
 *  2010/01/07    1.1   Y.Goto           E_本稼動_00936
 *  2010/02/03    1.2   Y.Goto           E_本稼動_01222
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
  nested_loop_expt          EXCEPTION;     -- 階層ループエラー
  resource_busy_expt        EXCEPTION;     -- デッドロックエラー
  internal_api_expt         EXCEPTION;     -- コンカレント内部共通例外
  param_invalid_expt        EXCEPTION;     -- 入力パラメータチェックエラー
  date_invalid_expt         EXCEPTION;     -- 日付チェックエラー
  prior_date_invalid_expt   EXCEPTION;     -- 未来日チェックエラー
  past_date_invalid_expt    EXCEPTION;     -- 過去日チェックエラー
  date_reverse_expt         EXCEPTION;     -- FROM-TO逆転チェックエラー
  profile_invalid_expt      EXCEPTION;     -- プロファイル値エラー

  PRAGMA EXCEPTION_INIT(resource_busy_expt, -54);
  PRAGMA EXCEPTION_INIT(nested_loop_expt, -01436);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOP006A01C';           -- パッケージ名
  cv_pkg_name_child         CONSTANT VARCHAR2(100) := 'XXCOP006A011C';           -- パッケージ名（子コンカレント名）
  --メッセージ共通
  cv_msg_appl_cont          CONSTANT VARCHAR2(100) := 'XXCOP';                  -- アプリケーション短縮名
  --言語
  cv_lang                   CONSTANT VARCHAR2(100) := USERENV('LANG');          -- 言語
  --プログラム実行年月日
  cd_sysdate                CONSTANT DATE := TRUNC(SYSDATE);                    -- システム日付（年月日）
  --日付型フォーマット
  cv_date_format            CONSTANT VARCHAR2(100) := 'YYYY/MM/DD';             -- 年月日
  --タイムスタンプ型フォーマット
  cv_timestamp_format       CONSTANT VARCHAR2(100) := 'HH24:MI:SS.FF3';         -- 年月日時分秒
  --デバックメッセージインデント
  cv_indent_2               CONSTANT CHAR(2) := '  ';                           -- 2文字空白
  cv_indent_4               CONSTANT CHAR(4) := '    ';                         -- 4文字空白
  --入力パラメータ
  cv_plan_type_tl           CONSTANT VARCHAR2(100) := '出荷計画区分';
  cv_planning_date_from_tl  CONSTANT VARCHAR2(100) := '計画立案期間(FROM)';
  cv_planning_date_to_tl    CONSTANT VARCHAR2(100) := '計画立案期間(TO)';
  cv_shipment_date_from_tl  CONSTANT VARCHAR2(100) := '出荷ペース計画期間(FROM)';
  cv_shipment_date_to_tl    CONSTANT VARCHAR2(100) := '出荷ペース計画期間(TO)';
  cv_forecast_date_from_tl  CONSTANT VARCHAR2(100) := '出荷予測期間(FROM)';
  cv_forecast_date_to_tl    CONSTANT VARCHAR2(100) := '出荷予測期間(TO)';
  cv_allocated_date_tl      CONSTANT VARCHAR2(100) := '出荷引当済日';
  cv_item_code_tl           CONSTANT VARCHAR2(100) := '品目コード';
--20100203_Ver1.2_E_本稼動_01222_SCS.Goto_ADD_START
  cv_working_days_tl        CONSTANT VARCHAR2(100) := '稼働日数';
  cv_stock_adjust_value_tl  CONSTANT VARCHAR2(100) := '在庫日数調整値';
--20100203_Ver1.2_E_本稼動_01222_SCS.Goto_ADD_END
  --プロファイル
  cv_pf_master_org_id       CONSTANT VARCHAR2(100) := 'XXCMN_MASTER_ORG_ID';
  cv_pf_source_org_id       CONSTANT VARCHAR2(100) := 'XXCOP1_DUMMY_SOURCE_ORG_ID';
  cv_pf_fresh_buffer_days   CONSTANT VARCHAR2(100) := 'XXCOP1_FRESHNESS_BUFFER_DAYS';
  cv_pf_frq_loct_code       CONSTANT VARCHAR2(100) := 'XXCMN_DUMMY_FREQUENT_WHSE';
  cv_pf_partition_num       CONSTANT VARCHAR2(100) := 'XXCOP1_PARTITION_NUM';
  cv_pf_debug_mode          CONSTANT VARCHAR2(100) := 'XXCOP1_DEBUG_MODE';
  cv_pf_interval            CONSTANT VARCHAR2(100) := 'XXCOP1_CONCURRENT_INTERVAL';
  cv_pf_max_wait            CONSTANT VARCHAR2(100) := 'XXCOP1_CONCURRENT_MAX_WAIT';
  
  --メッセージトークン値
  cv_table_xwypo            CONSTANT VARCHAR2(100) := '横持計画出力ワークテーブル';
  cv_table_xwyp             CONSTANT VARCHAR2(100) := '横持計画物流ワークテーブル';
  cv_table_xli              CONSTANT VARCHAR2(100) := '横持計画手持在庫テーブル';
  cv_table_xwyl             CONSTANT VARCHAR2(100) := '横持計画品目別代表倉庫ワークテーブル';
--
  -- メッセージ名
  cv_msg_00002              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00002';
  cv_msg_00003              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00003';
  cv_msg_00007              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00007';
  cv_msg_00011              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00011';
  cv_msg_00025              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00025';
  cv_msg_00041              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00041';
  cv_msg_00042              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00042';
  cv_msg_00047              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00047';
  cv_msg_00055              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00055';
  cv_msg_00065              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00065';
  cv_msg_10009              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10009';
  cv_msg_10045              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10045';
--20100203_Ver1.2_E_本稼動_01222_SCS.Goto_ADD_START
  cv_msg_10057              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10057';
--20100203_Ver1.2_E_本稼動_01222_SCS.Goto_ADD_END
  cv_msg_10046              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10046';
  cv_msg_10047              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10047';
  cv_msg_10050              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10050';
  cv_msg_10051              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10051';
  cv_msg_10052              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10052';
  cv_msg_10053              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10053';
  cv_msg_10054              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10054';
  -- メッセージトークン
  cv_msg_00002_token_1      CONSTANT VARCHAR2(100) := 'PROF_NAME';
  cv_msg_00007_token_1      CONSTANT VARCHAR2(100) := 'TABLE';
  cv_msg_00011_token_1      CONSTANT VARCHAR2(100) := 'ITEM';
  cv_msg_00025_token_1      CONSTANT VARCHAR2(100) := 'PERIOD_FROM';
  cv_msg_00025_token_2      CONSTANT VARCHAR2(100) := 'PERIOD_TO';
  cv_msg_00041_token_1      CONSTANT VARCHAR2(100) := 'ERRMSG';
  cv_msg_00042_token_1      CONSTANT VARCHAR2(100) := 'TABLE';
  cv_msg_00047_token_1      CONSTANT VARCHAR2(100) := 'ITEM_NAME';
  cv_msg_10009_token_1      CONSTANT VARCHAR2(100) := 'ITEM_NAME';
  cv_msg_10045_token_1      CONSTANT VARCHAR2(100) := 'PLANNING_DATE_FROM';
  cv_msg_10045_token_2      CONSTANT VARCHAR2(100) := 'PLANNING_DATE_TO';
  cv_msg_10045_token_3      CONSTANT VARCHAR2(100) := 'PLAN_TYPE';
  cv_msg_10045_token_4      CONSTANT VARCHAR2(100) := 'SHIPMENT_DATE_FROM';
  cv_msg_10045_token_5      CONSTANT VARCHAR2(100) := 'SHIPMENT_DATE_TO';
  cv_msg_10045_token_6      CONSTANT VARCHAR2(100) := 'FORECAST_DATE_FROM';
  cv_msg_10045_token_7      CONSTANT VARCHAR2(100) := 'FORECAST_DATE_TO';
  cv_msg_10045_token_8      CONSTANT VARCHAR2(100) := 'ALLOCATED_DATE';
  cv_msg_10045_token_9      CONSTANT VARCHAR2(100) := 'ITEM_NO';
--20100203_Ver1.2_E_本稼動_01222_SCS.Goto_ADD_START
  cv_msg_10057_token_1      CONSTANT VARCHAR2(100) := 'WORKING_DAYS';
  cv_msg_10057_token_2      CONSTANT VARCHAR2(100) := 'STOCK_ADJUST_VALUE';
--20100203_Ver1.2_E_本稼動_01222_SCS.Goto_ADD_END
  cv_msg_10046_token_1      CONSTANT VARCHAR2(100) := 'GATEGORY_NAME';
  cv_msg_10051_token_1      CONSTANT VARCHAR2(100) := 'DEBUG_LEVEL';
  cv_msg_10051_token_2      CONSTANT VARCHAR2(100) := 'RECEIPT_DATE';
  cv_msg_10051_token_3      CONSTANT VARCHAR2(100) := 'ITEM_NO';
  cv_msg_10051_token_4      CONSTANT VARCHAR2(100) := 'LOCT_CODE';
  cv_msg_10051_token_5      CONSTANT VARCHAR2(100) := 'FRESHNESS_CONDITION';
  cv_msg_10051_token_6      CONSTANT VARCHAR2(100) := 'STOCK_QUANTITY';
  cv_msg_10051_token_7      CONSTANT VARCHAR2(100) := 'SHIPPING_PACE';
  cv_msg_10051_token_8      CONSTANT VARCHAR2(100) := 'STOCK_DAYS';
  cv_msg_10051_token_9      CONSTANT VARCHAR2(100) := 'SUPPLIES_QUANTITY';
  cv_msg_10051_token_10     CONSTANT VARCHAR2(100) := 'MANUFACTURE_DATE';
  cv_msg_10052_token_1      CONSTANT VARCHAR2(100) := 'ITEM_NO';
  cv_msg_10053_token_1      CONSTANT VARCHAR2(100) := 'REQUEST_ID';
  cv_msg_10053_token_2      CONSTANT VARCHAR2(100) := 'ITEM_NO';
  cv_msg_10054_token_1      CONSTANT VARCHAR2(100) := 'REQUEST_ID';
  cv_msg_10054_token_2      CONSTANT VARCHAR2(100) := 'ITEM_NO';
  --出荷計画区分
  cv_plan_type_shipped      CONSTANT VARCHAR2(100) := '1';                      -- 出荷ペース
  cv_plan_type_forecate     CONSTANT VARCHAR2(100) := '2';                      -- 出荷予測
  --割当セット区分
  cv_base_plan              CONSTANT VARCHAR2(1)   := '1';                      -- 基本横持計画
  cv_custom_plan            CONSTANT VARCHAR2(1)   := '2';                      -- 特別横持計画
  cv_factory_ship_plan      CONSTANT VARCHAR2(1)   := '3';                      -- 工場出荷計画
  --品目カテゴリ
  cv_category_prod_class    CONSTANT VARCHAR2(100) := '本社商品区分';
  cv_category_article_class CONSTANT VARCHAR2(100) := '商品製品区分';
  cv_category_item_class    CONSTANT VARCHAR2(100) := '品目区分';
  --品目カテゴリ値
  cv_prod_class_leaf        CONSTANT VARCHAR2(100) := '1';  --リーフ
  cv_prod_class_drink       CONSTANT VARCHAR2(100) := '2';  --ドリンク
  cv_article_class_product  CONSTANT VARCHAR2(100) := '2';  --製品
  cv_item_class_product     CONSTANT VARCHAR2(100) := '5';  --製品
  --クイックコードタイプ
  cv_flv_assignment_name    CONSTANT VARCHAR2(100) := 'XXCOP1_ASSIGNMENT_NAME';
  cv_flv_assign_priority    CONSTANT VARCHAR2(100) := 'XXCOP1_ASSIGN_TYPE_PRIORITY';
  cv_flv_lot_status         CONSTANT VARCHAR2(100) := 'XXCMN_LOT_STATUS';
  cv_flv_freshness_cond     CONSTANT VARCHAR2(100) := 'XXCMN_FRESHNESS_CONDITION';
  cv_flv_unit_delivery      CONSTANT VARCHAR2(100) := 'XXCOP1_UNIT_DELIVERY';
  cv_enable                 CONSTANT VARCHAR2(100) := 'Y';
  --CSVファイル出力フォーマット
  cv_csv_date_format        CONSTANT VARCHAR2(10)  := 'YYYYMMDD';               -- 年月日
  cv_csv_char_bracket       CONSTANT VARCHAR2(1)   := '''';                     -- シングルクォーテーション
  cv_csv_delimiter          CONSTANT VARCHAR2(1)   := ',';                      -- カンマ
  cv_csv_mark               CONSTANT VARCHAR2(1)   := '*';                      -- アスタリスク
--
  --ログ出力レベル
  cv_log_level1             CONSTANT VARCHAR2(1)   := '1';                      -- 
  cv_log_level2             CONSTANT VARCHAR2(1)   := '2';                      -- 
  cv_log_level3             CONSTANT VARCHAR2(1)   := '3';                      -- 
--
  -- コンカレントパラメータ
  cv_conc_p_c               CONSTANT VARCHAR2(100) := 'COMPLETE';
  cv_conc_s_n               CONSTANT VARCHAR2(100) := 'NORMAL';
  cv_conc_s_e               CONSTANT VARCHAR2(100) := 'ERROR';
--
  -- 品目ステータス
  cv_shipping_enable        CONSTANT NUMBER := '1';                             -- ステータス
  cn_iimb_status_active     CONSTANT NUMBER :=  0;                              -- ステータス
  -- 出力対象区分
  cv_output_flg_enable      CONSTANT VARCHAR2(1) := '1';                        -- 対象
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  --ROWIDコレクション型
  TYPE g_rowid_ttype IS TABLE OF ROWID
    INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_planning_date          DATE;                                               --計画立案日
  gd_process_date           DATE;                                               --業務日付
  gn_transaction_id         NUMBER;                                             --トランザクションID
  gv_log_buffer             VARCHAR2(5000);                                     --ログ出力領域
  --プロファイル値
  gv_debug_mode             VARCHAR2(256);                                      --デバックモード
  gn_master_org_id          NUMBER;                                             --供給ルール(ダミー)組織ID
  gn_source_org_id          NUMBER;                                             --パッカー倉庫(ダミー)組織ID
  gn_freshness_buffer_days  NUMBER;                                             --鮮度条件バッファ日数
  gv_dummy_frequent_whse    VARCHAR2(4);                                        --ダミー代表倉庫
  gn_partition_num          NUMBER;                                             --パーティション数
  gn_interval               NUMBER;                                             --コンカレント発行時の確認間隔
  gn_max_wait               NUMBER;                                             --コンカレント発行時の最大待機時間
  --起動パラメータ
  gv_plan_type              VARCHAR2(1);                                        --出荷計画区分
  gd_planning_date_from     DATE;                                               --計画立案期間(FROM)
  gd_planning_date_to       DATE;                                               --計画立案期間(TO)
  gd_shipment_date_from     DATE;                                               --出荷ペース計画期間FROM
  gd_shipment_date_to       DATE;                                               --出荷ペース計画期間TO
  gd_forecast_date_from     DATE;                                               --出荷予測期間FROM
  gd_forecast_date_to       DATE;                                               --出荷予測期間TO
  gd_allocated_date         DATE;                                               --出荷引当済日
  gv_item_code              VARCHAR2(7);                                        --品目コード
--20100203_Ver1.2_E_本稼動_01222_SCS.Goto_ADD_START
  gn_working_days           NUMBER;                                             --稼動日数
  gn_stock_adjust_value     NUMBER;                                             --在庫日数調整値
--20100203_Ver1.2_E_本稼動_01222_SCS.Goto_ADD_END
  --品目カテゴリセットID
  gn_prod_class_set_id      NUMBER;                                             --品目カテゴリ:本社商品区分
  gn_crowd_class_set_id     NUMBER;                                             --政策群コード
  gn_item_class_set_id      NUMBER;                                             --品目区分
  gn_article_class_set_id   NUMBER;                                             --商品製品区分
--
  /**********************************************************************************
   * Procedure Name   : delete_table
   * Description      : テーブルデータ削除(A-2)
   ***********************************************************************************/
  PROCEDURE delete_table(
    ov_errbuf        OUT    VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT    VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg        OUT    VARCHAR2        --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_table'; -- プログラム名
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
    lv_table_name             VARCHAR2(100);
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    l_rowid_tab               g_rowid_ttype;
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
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
    );
    -- ===============================
    -- 横持計画物流ワークテーブル
    -- ===============================
    BEGIN
      lv_table_name := cv_table_xwyp;
      --ロックの取得
      SELECT xwyp.ROWID
      BULK COLLECT INTO l_rowid_tab
      FROM xxcop_wk_yoko_planning xwyp
      FOR UPDATE NOWAIT;
      --データ削除
      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcop.xxcop_wk_yoko_planning';
--
    EXCEPTION
      WHEN resource_busy_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00007
                       ,iv_token_name1  => cv_msg_00007_token_1
                       ,iv_token_value1 => lv_table_name
                     );
        RAISE internal_api_expt;
      WHEN NO_DATA_FOUND THEN
        NULL;
      WHEN OTHERS THEN
        lv_errbuf := SQLERRM;
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00042
                       ,iv_token_name1  => cv_msg_00042_token_1
                       ,iv_token_value1 => lv_table_name
                     );
        RAISE global_api_expt;
    END;
--
    -- ===============================
    -- 横持計画手持在庫テーブル
    -- ===============================
    BEGIN
      lv_table_name := cv_table_xli;
      --ロックの取得
      SELECT xli.ROWID
      BULK COLLECT INTO l_rowid_tab
      FROM xxcop_loct_inv xli
      FOR UPDATE NOWAIT;
      --データ削除
      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcop.xxcop_loct_inv';
--
    EXCEPTION
      WHEN resource_busy_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00007
                       ,iv_token_name1  => cv_msg_00007_token_1
                       ,iv_token_value1 => lv_table_name
                     );
        RAISE internal_api_expt;
      WHEN NO_DATA_FOUND THEN
        NULL;
      WHEN OTHERS THEN
        lv_errbuf := SQLERRM;
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00042
                       ,iv_token_name1  => cv_msg_00042_token_1
                       ,iv_token_value1 => lv_table_name
                     );
        RAISE global_api_expt;
    END;
--
    -- ===============================
    -- 横持計画品目別代表倉庫ワークテーブル
    -- ===============================
    BEGIN
      lv_table_name := cv_table_xwyl;
      --ロックの取得
      SELECT xwyl.ROWID
      BULK COLLECT INTO l_rowid_tab
      FROM xxcop_wk_yoko_locations xwyl
      FOR UPDATE NOWAIT;
      --データ削除
      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcop.xxcop_wk_yoko_locations';
--
    EXCEPTION
      WHEN resource_busy_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00007
                       ,iv_token_name1  => cv_msg_00007_token_1
                       ,iv_token_value1 => lv_table_name
                     );
        RAISE internal_api_expt;
      WHEN NO_DATA_FOUND THEN
        NULL;
      WHEN OTHERS THEN
        lv_errbuf := SQLERRM;
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00042
                       ,iv_token_name1  => cv_msg_00042_token_1
                       ,iv_token_value1 => lv_table_name
                     );
        RAISE global_api_expt;
    END;
--
    -- ===============================
    -- 横持計画出力ワークテーブル
    -- ===============================
    BEGIN
      lv_table_name := cv_table_xwypo;
      --ロックの取得
      SELECT xwypo.ROWID
      BULK COLLECT INTO l_rowid_tab
      FROM xxcop_wk_yoko_plan_output xwypo
      FOR UPDATE NOWAIT;
      --データ削除
      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcop.xxcop_wk_yoko_plan_output';
--
    EXCEPTION
      WHEN resource_busy_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00007
                       ,iv_token_name1  => cv_msg_00007_token_1
                       ,iv_token_value1 => lv_table_name
                     );
        RAISE internal_api_expt;
      WHEN NO_DATA_FOUND THEN
        NULL;
      WHEN OTHERS THEN
        lv_errbuf := SQLERRM;
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00042
                       ,iv_token_name1  => cv_msg_00042_token_1
                       ,iv_token_value1 => lv_table_name
                     );
        RAISE global_api_expt;
    END;
--
  EXCEPTION
    WHEN internal_api_expt THEN
      ov_errmsg  := lv_errmsg;
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
  END delete_table;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     iv_planning_date_from  IN     VARCHAR2                 -- 1.計画立案期間(FROM)
    ,iv_planning_date_to    IN     VARCHAR2                 -- 2.計画立案期間(TO)
    ,iv_plan_type           IN     VARCHAR2                 -- 3.出荷計画区分
    ,iv_shipment_date_from  IN     VARCHAR2                 -- 4.出荷ペース計画期間(FROM)
    ,iv_shipment_date_to    IN     VARCHAR2                 -- 5.出荷ペース計画期間(TO)
    ,iv_forecast_date_from  IN     VARCHAR2                 -- 6.出荷予測期間(FROM)
    ,iv_forecast_date_to    IN     VARCHAR2                 -- 7.出荷予測期間(TO)
    ,iv_allocated_date      IN     VARCHAR2                 -- 8.出荷引当済日
    ,iv_item_code           IN     VARCHAR2                 -- 9.品目コード
--20100203_Ver1.2_E_本稼動_01222_SCS.Goto_ADD_START
    ,iv_working_days        IN     VARCHAR2                 --10.稼動日数
    ,iv_stock_adjust_value  IN     VARCHAR2                 --11.在庫日数調整値
--20100203_Ver1.2_E_本稼動_01222_SCS.Goto_ADD_END
    ,ov_errbuf              OUT    VARCHAR2                 --   エラー・メッセージ           --# 固定 #
    ,ov_retcode             OUT    VARCHAR2                 --   リターン・コード             --# 固定 #
    ,ov_errmsg              OUT    VARCHAR2                 --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_param_msg              VARCHAR2(100);   -- パラメータ出力
    lb_chk_value              BOOLEAN;         -- 日付型フォーマットチェック結果
    lv_chk_parameter          VARCHAR2(100);   -- チェック項目名
    lv_chk_date_from          VARCHAR2(100);   -- 範囲チェック項目名(FROM)
    lv_chk_date_to            VARCHAR2(100);   -- 範囲チェック項目名(TO)
    lv_value                  VARCHAR2(100);   -- プロファイル値
    lv_profile_name           VARCHAR2(100);   -- ユーザプロファイル名
    lv_category_name          VARCHAR2(100);   -- 品目カテゴリ名
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
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
    );
    -- ===============================
    -- 入力パラメータの出力
    -- ===============================
    lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_msg_appl_cont
                   ,iv_name         => cv_msg_10045
                   ,iv_token_name1  => cv_msg_10045_token_1
                   ,iv_token_value1 => iv_planning_date_from
                   ,iv_token_name2  => cv_msg_10045_token_2
                   ,iv_token_value2 => iv_planning_date_to
                   ,iv_token_name3  => cv_msg_10045_token_3
                   ,iv_token_value3 => iv_plan_type
                   ,iv_token_name4  => cv_msg_10045_token_4
                   ,iv_token_value4 => iv_shipment_date_from
                   ,iv_token_name5  => cv_msg_10045_token_5
                   ,iv_token_value5 => iv_shipment_date_to
                   ,iv_token_name6  => cv_msg_10045_token_6
                   ,iv_token_value6 => iv_forecast_date_from
                   ,iv_token_name7  => cv_msg_10045_token_7
                   ,iv_token_value7 => iv_forecast_date_to
                   ,iv_token_name8  => cv_msg_10045_token_8
                   ,iv_token_value8 => iv_allocated_date
                   ,iv_token_name9  => cv_msg_10045_token_9
                   ,iv_token_value9 => iv_item_code
                 );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg
    );
--20100203_Ver1.2_E_本稼動_01222_SCS.Goto_ADD_START
    lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_msg_appl_cont
                   ,iv_name         => cv_msg_10057
                   ,iv_token_name1  => cv_msg_10057_token_1
                   ,iv_token_value1 => iv_working_days
                   ,iv_token_name2  => cv_msg_10057_token_2
                   ,iv_token_value2 => iv_stock_adjust_value
                 );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg
    );
--20100203_Ver1.2_E_本稼動_01222_SCS.Goto_ADD_END
    --空白行を挿入
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
--
    -- ===============================
    -- 業務日付の取得
    -- ===============================
    gd_process_date  :=  xxccp_common_pkg2.get_process_date;
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_appl_cont
                     ,iv_name         => cv_msg_00065
                   );
      RAISE internal_api_expt;
    END IF;
--
    -- ===============================
    -- 起動パラメータチェック
    -- ===============================
    BEGIN
      -- ===============================
      -- 計画立案期間(FROM)
      -- ===============================
      lv_chk_parameter := cv_planning_date_from_tl;
      --値のNULLチェック
      IF (iv_planning_date_from IS NULL) THEN
        RAISE param_invalid_expt;
      END IF;
      --DATE型チェック
      lb_chk_value := xxcop_common_pkg.chk_date_format(
                         iv_value       => iv_planning_date_from
                        ,iv_format      => cv_date_format
                      );
      IF (NOT lb_chk_value) THEN
        RAISE date_invalid_expt;
      END IF;
      gd_planning_date_from := TO_DATE(iv_planning_date_from, cv_date_format);
      --過去日の場合、エラー
      IF (gd_process_date > gd_planning_date_from) THEN
        RAISE prior_date_invalid_expt;
      END IF;
--
      -- ===============================
      -- 計画立案期間(TO)
      -- ===============================
      lv_chk_parameter := cv_planning_date_to_tl;
      --値のNULLチェック
      IF (iv_planning_date_to IS NULL) THEN
        RAISE param_invalid_expt;
      END IF;
      --DATE型チェック
      lb_chk_value := xxcop_common_pkg.chk_date_format(
                         iv_value       => iv_planning_date_to
                        ,iv_format      => cv_date_format
                      );
      IF (NOT lb_chk_value) THEN
        RAISE date_invalid_expt;
      END IF;
      gd_planning_date_to := TO_DATE(iv_planning_date_to, cv_date_format);
      --過去日の場合、エラー
      IF (gd_process_date > gd_planning_date_to) THEN
        RAISE prior_date_invalid_expt;
      END IF;
--
      -- ===============================
      -- 計画立案期間(FROM-TO)逆転チェック
      -- ===============================
      IF (gd_planning_date_from > gd_planning_date_to) THEN
        lv_chk_date_from := cv_planning_date_from_tl;
        lv_chk_date_to   := cv_planning_date_to_tl;
        RAISE date_reverse_expt;
      END IF;
--
      -- ===============================
      -- 出荷計画区分
      -- ===============================
      lv_chk_parameter := cv_plan_type_tl;
      --値の妥当性チェック
      IF (iv_plan_type NOT IN (cv_plan_type_shipped, cv_plan_type_forecate)) THEN
        RAISE param_invalid_expt;
      END IF;
      gv_plan_type := iv_plan_type;
--
      -- ===============================
      -- 出荷ペース計画期間(FROM)
      -- ===============================
      lv_chk_parameter := cv_shipment_date_from_tl;
      --値のNULLチェック
      IF (iv_shipment_date_from IS NULL) THEN
        RAISE param_invalid_expt;
      END IF;
      --DATE型チェック
      lb_chk_value := xxcop_common_pkg.chk_date_format(
                         iv_value       => iv_shipment_date_from
                        ,iv_format      => cv_date_format
                      );
      IF (NOT lb_chk_value) THEN
        RAISE date_invalid_expt;
      END IF;
      gd_shipment_date_from := TO_DATE(iv_shipment_date_from, cv_date_format);
      -- 未来日の場合、エラー
      IF (gd_shipment_date_from > gd_process_date) THEN
        RAISE past_date_invalid_expt;
      END IF;
--
      -- ===============================
      -- 出荷ペース計画期間(TO)
      -- ===============================
      lv_chk_parameter := cv_shipment_date_to_tl;
      --値のNULLチェック
      IF (iv_shipment_date_to IS NULL) THEN
        RAISE param_invalid_expt;
      END IF;
      --DATE型チェック
      lb_chk_value := xxcop_common_pkg.chk_date_format(
                         iv_value       => iv_shipment_date_to
                        ,iv_format      => cv_date_format
                      );
      IF (NOT lb_chk_value) THEN
        RAISE date_invalid_expt;
      END IF;
      gd_shipment_date_to := TO_DATE(iv_shipment_date_to, cv_date_format);
      -- 未来日の場合エラー
      IF (gd_shipment_date_to > gd_process_date) THEN
        RAISE past_date_invalid_expt;
      END IF;
--
      -- ===============================
      -- 出荷ペース計画期間(FROM-TO)逆転チェック
      -- ===============================
      IF (gd_shipment_date_from > gd_shipment_date_to) THEN
        lv_chk_date_from := cv_shipment_date_from_tl;
        lv_chk_date_to   := cv_shipment_date_to_tl;
        RAISE date_reverse_expt;
      END IF;
--
      --出荷計画区分が出荷予測の場合、チェックする
      IF (NVL(iv_plan_type, cv_plan_type_forecate) = cv_plan_type_forecate) THEN
        -- ===============================
        -- 出荷予測期間(FROM)
        -- ===============================
        lv_chk_parameter := cv_forecast_date_from_tl;
        --値のNULLチェック
        IF (iv_forecast_date_from IS NULL) THEN
          RAISE param_invalid_expt;
        END IF;
        --DATE型チェック
        lb_chk_value := xxcop_common_pkg.chk_date_format(
                           iv_value       => iv_forecast_date_from
                          ,iv_format      => cv_date_format
                        );
        IF (NOT lb_chk_value) THEN
          RAISE date_invalid_expt;
        END IF;
        gd_forecast_date_from := TO_DATE(iv_forecast_date_from, cv_date_format);
--
        -- ===============================
        -- 出荷予測期間(TO)
        -- ===============================
        lv_chk_parameter := cv_forecast_date_to_tl;
        --値のNULLチェック
        IF (iv_forecast_date_to IS NULL) THEN
          RAISE param_invalid_expt;
        END IF;
        --DATE型チェック
        lb_chk_value := xxcop_common_pkg.chk_date_format(
                           iv_value       => iv_forecast_date_to
                          ,iv_format      => cv_date_format
                        );
        IF (NOT lb_chk_value) THEN
          RAISE date_invalid_expt;
        END IF;
        gd_forecast_date_to := TO_DATE(iv_forecast_date_to, cv_date_format);
--
        -- ===============================
        -- 出荷予測期間(FROM-TO)逆転チェック
        -- ===============================
        IF (gd_forecast_date_from > gd_forecast_date_to) THEN
          lv_chk_date_from := cv_forecast_date_from_tl;
          lv_chk_date_to   := cv_forecast_date_to_tl;
          RAISE date_reverse_expt;
        END IF;
      END IF;
--
      -- ===============================
      -- 出荷引当済日
      -- ===============================
      lv_chk_parameter := cv_allocated_date_tl;
      --値のNULLチェック
      IF (iv_allocated_date IS NULL) THEN
        RAISE param_invalid_expt;
      END IF;
      --DATE型チェック
      lb_chk_value := xxcop_common_pkg.chk_date_format(
                         iv_value       => iv_allocated_date
                        ,iv_format      => cv_date_format
                      );
      IF (NOT lb_chk_value) THEN
        RAISE date_invalid_expt;
      END IF;
      gd_allocated_date := TO_DATE(iv_allocated_date, cv_date_format);
      -- ===============================
      -- 品目コード
      -- ===============================
      lv_chk_parameter := cv_item_code_tl;
      gv_item_code := iv_item_code;
--
--20100203_Ver1.2_E_本稼動_01222_SCS.Goto_ADD_START
      -- ===============================
      -- 稼動日数
      -- ===============================
      lv_chk_parameter := cv_working_days_tl;
      --値のNULLチェック
      IF (iv_working_days IS NULL) THEN
        RAISE param_invalid_expt;
      END IF;
      --数値型チェック
      BEGIN
        gn_working_days := TO_NUMBER(iv_working_days);
      EXCEPTION
        WHEN OTHERS THEN
        RAISE param_invalid_expt;
      END;
      IF (gn_working_days <= 0) THEN
        RAISE param_invalid_expt;
      END IF;
--
      -- ===============================
      -- 在庫日数調整値
      -- ===============================
      lv_chk_parameter := cv_stock_adjust_value_tl;
      --数値型チェック
      BEGIN
        gn_stock_adjust_value := TO_NUMBER(iv_stock_adjust_value);
      EXCEPTION
        WHEN OTHERS THEN
        RAISE param_invalid_expt;
      END;
--
--20100203_Ver1.2_E_本稼動_01222_SCS.Goto_ADD_END
    EXCEPTION
      WHEN param_invalid_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00055
                     );
        RAISE internal_api_expt;
      WHEN date_invalid_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00011
                       ,iv_token_name1  => cv_msg_00011_token_1
                       ,iv_token_value1 => lv_chk_parameter
                     );
        RAISE internal_api_expt;
      WHEN past_date_invalid_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_appl_cont
                        ,iv_name         => cv_msg_00047
                        ,iv_token_name1  => cv_msg_00047_token_1
                        ,iv_token_value1 => lv_chk_parameter
                      );
        RAISE internal_api_expt;
      WHEN prior_date_invalid_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_appl_cont
                        ,iv_name         => cv_msg_10009
                        ,iv_token_name1  => cv_msg_10009_token_1
                        ,iv_token_value1 => lv_chk_parameter
                      );
        RAISE internal_api_expt;
      WHEN date_reverse_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00025
                       ,iv_token_name1  => cv_msg_00025_token_1
                       ,iv_token_value1 => lv_chk_date_from
                       ,iv_token_name2  => cv_msg_00025_token_2
                       ,iv_token_value2 => lv_chk_date_to
                     );
        RAISE internal_api_expt;
    END;
    -- ===============================
    -- プロファイルの取得
    -- ===============================
    BEGIN
      --マスタ組織
      lv_profile_name := cv_pf_master_org_id;
      lv_value := fnd_profile.value( lv_profile_name );
      IF (lv_value IS NULL) THEN
        RAISE profile_invalid_expt;
      END IF;
      gn_master_org_id := TO_NUMBER(lv_value);
--
      --ダミー出荷組織
      lv_profile_name := cv_pf_source_org_id;
      lv_value := fnd_profile.value( lv_profile_name );
      IF (lv_value IS NULL) THEN
        RAISE profile_invalid_expt;
      END IF;
      BEGIN
        SELECT mp.organization_id         organization_id
        INTO gn_source_org_id
        FROM mtl_parameters mp
        WHERE mp.organization_code = lv_value;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RAISE profile_invalid_expt;
      END;
--
      --鮮度条件バッファ日数
      lv_profile_name := cv_pf_fresh_buffer_days;
      lv_value := fnd_profile.value( lv_profile_name );
      IF (lv_value IS NULL) THEN
        RAISE profile_invalid_expt;
      END IF;
      gn_freshness_buffer_days := TO_NUMBER(lv_value);
--
      --ダミー代表倉庫
      lv_profile_name := cv_pf_frq_loct_code;
      lv_value := fnd_profile.value( lv_profile_name );
      IF (lv_value IS NULL) THEN
        RAISE profile_invalid_expt;
      END IF;
      gv_dummy_frequent_whse := lv_value;
--
      --パーティション数
      lv_profile_name := cv_pf_partition_num;
      lv_value := fnd_profile.value( lv_profile_name );
      IF (lv_value IS NULL) THEN
        RAISE profile_invalid_expt;
      END IF;
      gn_partition_num := TO_NUMBER(lv_value);
--
      --デバックモード
      lv_profile_name := cv_pf_debug_mode;
      gv_debug_mode := fnd_profile.value( lv_profile_name );
--
      --インターバル
      lv_profile_name :=  cv_pf_interval;
      lv_value := fnd_profile.value( lv_profile_name );
      IF (lv_value IS NULL) THEN
        RAISE profile_invalid_expt;
      END IF;
      gn_interval     := TO_NUMBER(lv_value);
--
      --最大待機時間
      lv_profile_name :=  cv_pf_max_wait;
      lv_value := fnd_profile.value( lv_profile_name );
      IF (lv_value IS NULL) THEN
        RAISE profile_invalid_expt;
      END IF;
      gn_max_wait     := TO_NUMBER(lv_value);
--
    EXCEPTION
      WHEN profile_invalid_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00002
                       ,iv_token_name1  => cv_msg_00002_token_1
                       ,iv_token_value1 => lv_profile_name
                     );
        RAISE internal_api_expt;
      WHEN VALUE_ERROR THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00002
                       ,iv_token_name1  => cv_msg_00002_token_1
                       ,iv_token_value1 => lv_profile_name
                     );
        RAISE internal_api_expt;
    END;
--
    -- ===============================
    -- 品目カテゴリセットの取得
    -- ===============================
    BEGIN
      --本社商品区分
      lv_category_name :=cv_category_prod_class;
      SELECT mcst.category_set_id         category_set_id
      INTO   gn_prod_class_set_id
      FROM   mtl_category_sets_tl   mcst
      WHERE  mcst.category_set_name = lv_category_name
        AND  mcst.source_lang       = cv_lang
        AND  mcst.language          = cv_lang
      ;
      --商品製品区分
      lv_category_name :=cv_category_article_class;
      SELECT mcst.category_set_id         category_set_id
      INTO   gn_article_class_set_id
      FROM   mtl_category_sets_tl   mcst
      WHERE  mcst.category_set_name = lv_category_name
        AND  mcst.source_lang       = cv_lang
        AND  mcst.language          = cv_lang
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_10046
                       ,iv_token_name1  => cv_msg_10046_token_1
                       ,iv_token_value1 => lv_category_name
                     );
        RAISE internal_api_expt;
    END;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN internal_api_expt THEN
      ov_errmsg  := lv_errmsg;
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
  END init;
  /**********************************************************************************
   * Procedure Name   : request_conc(A-3)
   * Description      : 子コンカレント発行処理
   ***********************************************************************************/
  PROCEDURE request_conc(
    ov_errbuf        OUT    VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT    VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg        OUT    VARCHAR2        --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'request_conc'; -- プログラム名
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
    lv_item_category          VARCHAR2(100);  --品目カテゴリ
    ln_target_cnt             NUMBER;         --処理データ件数
    lv_phase                  VARCHAR2(100);
    lv_status                 VARCHAR2(100);
    lv_dev_phase              VARCHAR2(100);
    lv_dev_status             VARCHAR2(100);
    -- 子コンカレント対象データを格納するレコード
    TYPE item_type IS RECORD(
       item_id            ic_item_mst_b.item_id%TYPE                    -- 在庫品目ID
     , item_no            ic_item_mst_b.item_no%TYPE                    -- 品目コード
    );
    TYPE item_tbl IS TABLE OF item_type INDEX BY PLS_INTEGER;
    item_rec  item_tbl;
--
    TYPE req_type IS RECORD(
       request_id         NUMBER
     , item_no            ic_item_mst_b.item_no%TYPE                    -- 品目コード
    );
    TYPE req_tbl IS TABLE OF req_type INDEX BY PLS_INTEGER;
    req_rec  req_tbl;
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
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
    );
--
    -- 品目が指定されていない場合
    IF (gv_item_code IS NULL) THEN
      -- 対象となる品目を一括取得
      SELECT  iimb.item_id
             ,iimb.item_no BULK COLLECT
        INTO  item_rec
        FROM  mrp_assignment_sets       mas    --割当セット
             ,mrp_sr_assignments        msa    --割当セット明細
             ,fnd_lookup_values         flv1   --参照タイプ(割当セット名)
             ,mtl_system_items_b        msib   --Disc品目マスタ
             ,ic_item_mst_b             iimb   --OPM品目マスタ
             ,gmi_item_categories       gic_p  --OPM品目カテゴリ(本社商品区分)
             ,mtl_categories_b          mcb_p  --品目カテゴリマスタ(本社商品区分)
             ,gmi_item_categories       gic_a  --OPM品目カテゴリ(商品製品区分)
             ,mtl_categories_b          mcb_a  --品目カテゴリマスタ(商品製品区分)
       WHERE  mas.attribute1            = cv_base_plan
         AND  msa.assignment_set_id     = mas.assignment_set_id
         AND  flv1.lookup_type          = cv_flv_assignment_name
         AND  flv1.lookup_code          = mas.assignment_set_name
         AND  flv1.language             = cv_lang
         AND  flv1.source_lang          = cv_lang
         AND  flv1.enabled_flag         = cv_enable
         AND  gd_process_date BETWEEN NVL(flv1.start_date_active, gd_process_date)
                                  AND NVL(flv1.end_date_active  , gd_process_date)
         AND  msib.inventory_item_id    = msa.inventory_item_id
         AND  msib.organization_id      = gn_master_org_id
         AND  iimb.item_no              = msib.segment1
         AND  iimb.inactive_ind         = cn_iimb_status_active
         AND  iimb.attribute18          = cv_shipping_enable
         AND  iimb.item_id              = gic_p.item_id
         AND  gic_p.category_id         = mcb_p.category_id
         AND  gic_p.category_set_id     = gn_prod_class_set_id
         AND  mcb_p.segment1            = cv_prod_class_drink
         AND  iimb.item_id              = gic_a.item_id
         AND  gic_a.category_id         = mcb_a.category_id
         AND  gic_a.category_set_id     = gn_article_class_set_id
         AND  mcb_a.segment1            = cv_article_class_product
       GROUP BY iimb.item_id,
                iimb.item_no;
    ELSE
      SELECT  iimb.item_id
             ,iimb.item_no BULK COLLECT
        INTO  item_rec
        FROM  mrp_assignment_sets       mas    --割当セット
             ,mrp_sr_assignments        msa    --割当セット明細
             ,fnd_lookup_values         flv1   --参照タイプ(割当セット名)
             ,mtl_system_items_b        msib   --Disc品目マスタ
             ,ic_item_mst_b             iimb   --OPM品目マスタ
             ,gmi_item_categories       gic_p  --OPM品目カテゴリ(本社商品区分)
             ,mtl_categories_b          mcb_p  --品目カテゴリマスタ(本社商品区分)
             ,gmi_item_categories       gic_a  --OPM品目カテゴリ(商品製品区分)
             ,mtl_categories_b          mcb_a  --品目カテゴリマスタ(商品製品区分)
       WHERE  mas.attribute1            = cv_base_plan
         AND  msa.assignment_set_id     = mas.assignment_set_id
         AND  flv1.lookup_type          = cv_flv_assignment_name
         AND  flv1.lookup_code          = mas.assignment_set_name
         AND  flv1.language             = cv_lang
         AND  flv1.source_lang          = cv_lang
         AND  flv1.enabled_flag         = cv_enable
         AND  gd_process_date BETWEEN NVL(flv1.start_date_active, gd_process_date)
                                  AND NVL(flv1.end_date_active  , gd_process_date)
         AND  msib.inventory_item_id    = msa.inventory_item_id
         AND  msib.organization_id      = gn_master_org_id
         AND  msib.segment1             = gv_item_code
         AND  iimb.item_no              = msib.segment1
         AND  iimb.inactive_ind         = cn_iimb_status_active
         AND  iimb.attribute18          = cv_shipping_enable
         AND  iimb.item_id              = gic_p.item_id
         AND  gic_p.category_id         = mcb_p.category_id
         AND  gic_p.category_set_id     = gn_prod_class_set_id
         AND  mcb_p.segment1            = cv_prod_class_drink
         AND  iimb.item_id              = gic_a.item_id
         AND  gic_a.category_id         = mcb_a.category_id
         AND  gic_a.category_set_id     = gn_article_class_set_id
         AND  mcb_a.segment1            = cv_article_class_product
       GROUP BY iimb.item_id,
                iimb.item_no;
    END IF;
--
    -- 処理前に初期化
    gn_target_cnt := item_rec.COUNT; -- 対象件数
    ln_target_cnt := 0;
--
    -- 品目件数分ループ
    <<item_rec_loop>>
    FOR i IN 1 .. item_rec.COUNT LOOP
      --品目区分チェック
      lv_item_category := NULL;
      lv_item_category := xxcop_common_pkg2.get_item_category_f(
                            iv_category_set => cv_category_item_class
                           ,in_item_id      => item_rec(i).item_id
                          );
      --品目区分が製品もしくはNULLの場合に子コンカレントを発行
      IF (lv_item_category IS NULL OR
          lv_item_category = cv_item_class_product) THEN
        ln_target_cnt := ln_target_cnt + 1;
        req_rec(ln_target_cnt).request_id := FND_REQUEST.SUBMIT_REQUEST(
                                               application       => cv_msg_appl_cont                                --アプリケーション短縮名
                                             , program           => cv_pkg_name_child                               --プログラム名
                                             , argument1         => TO_CHAR(gd_planning_date_from,'YYYY/MM/DD')     --計画立案期間(FROM)
                                             , argument2         => TO_CHAR(gd_planning_date_to,'YYYY/MM/DD')       --計画立案期間(TO)
                                             , argument3         => gv_plan_type                                    --出荷計画区分
                                             , argument4         => TO_CHAR(gd_shipment_date_from,'YYYY/MM/DD')     --出荷ペース計画期間FROM
                                             , argument5         => TO_CHAR(gd_shipment_date_to,'YYYY/MM/DD')       --出荷ペース計画期間TO
                                             , argument6         => TO_CHAR(gd_forecast_date_from,'YYYY/MM/DD')     --出荷予測期間FROM
                                             , argument7         => TO_CHAR(gd_forecast_date_to,'YYYY/MM/DD')       --出荷予測期間TO
                                             , argument8         => TO_CHAR(gd_allocated_date,'YYYY/MM/DD')         --出荷引当済日
                                             , argument9         => item_rec(i).item_no                             --品目コード
--20100203_Ver1.2_E_本稼動_01222_SCS.Goto_ADD_START
                                             , argument10        => TO_CHAR(gn_working_days)                        --稼動日数
                                             , argument11        => TO_CHAR(gn_stock_adjust_value)                  --在庫日数調整値
--20100203_Ver1.2_E_本稼動_01222_SCS.Goto_ADD_END
                                             );
        -- エラーの場合
        IF ( req_rec(ln_target_cnt).request_id = 0 ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_appl_cont
                        ,iv_name         => cv_msg_10052
                        ,iv_token_name1  => cv_msg_10052_token_1
                        ,iv_token_value1 => item_rec(i).item_no
                       );
          RAISE internal_api_expt;
        ELSE
          req_rec(ln_target_cnt).item_no := item_rec(i).item_no;
          --コミットしないと発行されないため発行ごとにコミット
          COMMIT;
        END IF;
      ELSE
        -- 処理対象外のためスキップ件数をカウント
        gn_warn_cnt := gn_warn_cnt + 1;
      END IF;
    END LOOP item_rec_loop;
--
    <<chk_status>>
    FOR j IN 1 .. req_rec.COUNT LOOP
      IF ( FND_CONCURRENT.WAIT_FOR_REQUEST(
             request_id => req_rec(j).request_id
            ,interval   => gn_interval
            ,max_wait   => gn_max_wait
            ,phase      => lv_phase
            ,status     => lv_status
            ,dev_phase  => lv_dev_phase
            ,dev_status => lv_dev_status
            ,message    => lv_errmsg
           ) ) THEN
        -- ステータス反映
        -- フェーズ:完了
        IF ( lv_dev_phase = cv_conc_p_c ) THEN
          -- ステータス:正常
          IF ( lv_dev_status = cv_conc_s_n ) THEN
            gn_normal_cnt := gn_normal_cnt + 1;
          -- ステータス:正常以外(エラー、警告)
          ELSE
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_appl_cont
                          ,iv_name         => cv_msg_10054
                          ,iv_token_name1  => cv_msg_10054_token_1
                          ,iv_token_value1 => TO_CHAR(req_rec(j).request_id)
                          ,iv_token_name2  => cv_msg_10054_token_2
                          ,iv_token_value2 => req_rec(j).item_no
                         );
            fnd_file.put_line(
              which  => FND_FILE.LOG
             ,buff => lv_errmsg --ユーザー・エラーメッセージ
            );
            gn_error_cnt := gn_error_cnt + 1;
          END IF;
        END IF;
      ELSE
        -- コンカレント問合せが正常にできなかった場合（エラー処理）
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_appl_cont
                      ,iv_name         => cv_msg_10053
                      ,iv_token_name1  => cv_msg_10053_token_1
                      ,iv_token_value1 => TO_CHAR(req_rec(j).request_id)
                      ,iv_token_name2  => cv_msg_10053_token_2
                      ,iv_token_value2 => req_rec(j).item_no
                     );
        RAISE internal_api_expt;
      END IF;
    END LOOP chk_status;
--
  EXCEPTION
    WHEN internal_api_expt THEN
      ov_errmsg  := lv_errmsg;
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
  END request_conc;
--
  /**********************************************************************************
   * Procedure Name   : output_xwypo
   * Description      : 横持計画CSV出力(A-4)
   ***********************************************************************************/
  PROCEDURE output_xwypo(
    ov_errbuf        OUT    VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT    VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg        OUT    VARCHAR2        --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_xwypo'; -- プログラム名
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
    lv_csvbuff                VARCHAR2(5000);             -- 横持計画出力領域
--
    -- *** ローカル・カーソル ***
    CURSOR xwypo_cur IS
      SELECT xwypo.shipping_date                              shipping_date
            ,xwypo.receipt_date                               receipt_date
            ,xwypo.ship_loct_code                             ship_loct_code
            ,xwypo.ship_loct_name                             ship_loct_name
            ,xwypo.rcpt_loct_code                             rcpt_loct_code
            ,xwypo.rcpt_loct_name                             rcpt_loct_name
            ,xwypo.item_no                                    item_no
            ,xwypo.item_name                                  item_name
            ,flv1.description                                 freshness_cond_desc
            ,xwypo.manufacture_date                           manufacture_date
            ,flv2.meaning                                     lot_meaning
            ,xwypo.plan_min_quantity                          plan_min_quantity
            ,xwypo.plan_max_quantity                          plan_max_quantity
            ,xwypo.plan_lot_quantity                          plan_lot_quantity
            ,xwypo.delivery_unit                              delivery_unit
            ,xwypo.palette_max_cs_qty                         palette_max_cs_qty
            ,xwypo.palette_max_step_qty                       palette_max_step_qty
--20100107_Ver1.1_E_本稼動_00936_SCS.Goto_ADD_START
            ,xwypo.crowd_class_code                           crowd_class_code
            ,xwypo.expiration_day                             expiration_day
--20100107_Ver1.1_E_本稼動_00936_SCS.Goto_ADD_END
            ,xwypo.before_lot_stock                           before_lot_stock
            ,xwypo.after_lot_stock                            after_lot_stock
            ,xwypo.safety_stock_quantity                      safety_stock_quantity
            ,xwypo.max_stock_quantity                         max_stock_quantity
            ,xwypo.shipping_pace                              shipping_pace
            ,xwypo.special_yoko_flag                          special_yoko_flag
            ,xwypo.short_supply_flag                          short_supply_flag
            ,xwypo.lot_reverse_flag                           lot_reverse_flag
            ,xwypo.output_num                                 output_num
      FROM xxcop_wk_yoko_plan_output xwypo
          ,fnd_lookup_values         flv1
          ,fnd_lookup_values         flv2
      WHERE xwypo.output_flag    = cv_output_flg_enable
        AND flv1.lookup_type     = cv_flv_freshness_cond
        AND flv1.lookup_code     = xwypo.freshness_condition
        AND flv1.language        = cv_lang
        AND flv1.source_lang     = cv_lang
        AND flv1.enabled_flag    = cv_enable
        AND gd_process_date BETWEEN NVL(flv1.start_date_active, gd_process_date)
                                AND NVL(flv1.end_date_active, gd_process_date)
        AND flv2.lookup_type(+)  = cv_flv_lot_status
        AND flv2.lookup_code(+)  = xwypo.lot_status
        AND flv2.language(+)     = cv_lang
        AND flv2.source_lang(+)  = cv_lang
        AND flv2.enabled_flag(+) = cv_enable
        AND gd_process_date BETWEEN NVL(flv2.start_date_active(+), gd_process_date)
                                AND NVL(flv2.end_date_active(+), gd_process_date)
      ORDER BY xwypo.shipping_date        ASC
              ,xwypo.receipt_date         ASC
              ,xwypo.ship_loct_code       ASC
              ,xwypo.rcpt_loct_code       ASC
              ,xwypo.item_no              ASC
              ,xwypo.freshness_condition  DESC
              ,xwypo.manufacture_date     ASC
              ,xwypo.output_num           ASC
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
    );
--
    --CSVファイルヘッダ出力
    lv_csvbuff := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_appl_cont
                    ,iv_name         => cv_msg_10047
                  );
    --処理結果レポートに出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_csvbuff
    );
    --CSVファイル明細出力
    <<xwypo_loop>>
    FOR l_xwypo_rec IN xwypo_cur LOOP
      --初期化
      lv_csvbuff := NULL;
      --項目の編集
      --出荷日
      lv_csvbuff := TO_CHAR(l_xwypo_rec.shipping_date, cv_csv_date_format)
                 || cv_csv_delimiter
      ;
      --着日
      lv_csvbuff := lv_csvbuff
                 || TO_CHAR(l_xwypo_rec.receipt_date , cv_csv_date_format)
                 || cv_csv_delimiter
      ;
      --移動元倉庫コード
      lv_csvbuff := lv_csvbuff
                 || l_xwypo_rec.ship_loct_code
                 || cv_csv_delimiter
      ;
      --移動元倉庫名
      lv_csvbuff := lv_csvbuff
                 || l_xwypo_rec.ship_loct_name
                 || cv_csv_delimiter
      ;
      --移動先倉庫コード
      lv_csvbuff := lv_csvbuff
                 || l_xwypo_rec.rcpt_loct_code
                 || cv_csv_delimiter
      ;
      --移動先倉庫名
      lv_csvbuff := lv_csvbuff
                 || l_xwypo_rec.rcpt_loct_name
                 || cv_csv_delimiter
      ;
--20100107_Ver1.1_E_本稼動_00936_SCS.Goto_ADD_START
      --群コード
      lv_csvbuff := lv_csvbuff
                 || l_xwypo_rec.crowd_class_code
                 || cv_csv_delimiter
      ;
--20100107_Ver1.1_E_本稼動_00936_SCS.Goto_ADD_END
      --品目コード
      lv_csvbuff := lv_csvbuff
                 || l_xwypo_rec.item_no
                 || cv_csv_delimiter
      ;
      --品目名
      lv_csvbuff := lv_csvbuff
                 || l_xwypo_rec.item_name
                 || cv_csv_delimiter
      ;
      --鮮度条件
      lv_csvbuff := lv_csvbuff
                 || l_xwypo_rec.freshness_cond_desc
                 || cv_csv_delimiter
      ;
      --製造年月日
      lv_csvbuff := lv_csvbuff
                 || TO_CHAR(l_xwypo_rec.manufacture_date, cv_csv_date_format)
                 || cv_csv_delimiter
      ;
--20100107_Ver1.1_E_本稼動_00936_SCS.Goto_ADD_START
      --賞味期間
      lv_csvbuff := lv_csvbuff
                 || TO_CHAR(l_xwypo_rec.expiration_day)
                 || cv_csv_delimiter
      ;
--20100107_Ver1.1_E_本稼動_00936_SCS.Goto_ADD_END
      --品質
      lv_csvbuff := lv_csvbuff
                 || l_xwypo_rec.lot_meaning
                 || cv_csv_delimiter
      ;
      --計画数(最小)
      IF (l_xwypo_rec.output_num = 1) THEN
        lv_csvbuff := lv_csvbuff
                   || TO_CHAR(l_xwypo_rec.plan_min_quantity)
                   || cv_csv_delimiter
        ;
      ELSE
        lv_csvbuff := lv_csvbuff
                   || cv_csv_delimiter
        ;
      END IF;
      --計画数(最大)
      IF (l_xwypo_rec.output_num = 1) THEN
        lv_csvbuff := lv_csvbuff
                   || TO_CHAR(l_xwypo_rec.plan_max_quantity)
                   || cv_csv_delimiter
        ;
      ELSE
        lv_csvbuff := lv_csvbuff
                   || cv_csv_delimiter
        ;
      END IF;
      --計画数(バランス)
      lv_csvbuff := lv_csvbuff
                 || TO_CHAR(l_xwypo_rec.plan_lot_quantity)
                 || cv_csv_delimiter
      ;
      --配送単位
      IF (l_xwypo_rec.output_num = 1) THEN
        lv_csvbuff := lv_csvbuff
                   || l_xwypo_rec.delivery_unit
                   || cv_csv_delimiter
        ;
      ELSE
        lv_csvbuff := lv_csvbuff
                   || cv_csv_delimiter
        ;
      END IF;
      --配数
      IF (l_xwypo_rec.output_num = 1) THEN
        lv_csvbuff := lv_csvbuff
                   || TO_CHAR(l_xwypo_rec.palette_max_cs_qty)
                   || cv_csv_delimiter
        ;
      ELSE
        lv_csvbuff := lv_csvbuff
                   || cv_csv_delimiter
        ;
      END IF;
      --段数
      IF (l_xwypo_rec.output_num = 1) THEN
        lv_csvbuff := lv_csvbuff
                   || TO_CHAR(l_xwypo_rec.palette_max_step_qty)
                   || cv_csv_delimiter
        ;
      ELSE
        lv_csvbuff := lv_csvbuff
                   || cv_csv_delimiter
        ;
      END IF;
      --横持前在庫
      lv_csvbuff := lv_csvbuff
                 || TO_CHAR(l_xwypo_rec.before_lot_stock)
                 || cv_csv_delimiter
      ;
      --横持後在庫
      lv_csvbuff := lv_csvbuff
                 || TO_CHAR(l_xwypo_rec.after_lot_stock)
                 || cv_csv_delimiter
      ;
      --安全在庫数
      IF (l_xwypo_rec.output_num = 1) THEN
        lv_csvbuff := lv_csvbuff
                   || TO_CHAR(l_xwypo_rec.safety_stock_quantity)
                   || cv_csv_delimiter
        ;
      ELSE
        lv_csvbuff := lv_csvbuff
                   || cv_csv_delimiter
        ;
      END IF;
      --最大在庫数
      IF (l_xwypo_rec.output_num = 1) THEN
        lv_csvbuff := lv_csvbuff
                   || TO_CHAR(l_xwypo_rec.max_stock_quantity)
                   || cv_csv_delimiter
        ;
      ELSE
        lv_csvbuff := lv_csvbuff
                   || cv_csv_delimiter
        ;
      END IF;
      --出荷ペース
      IF (l_xwypo_rec.output_num = 1) THEN
        lv_csvbuff := lv_csvbuff
                   || TO_CHAR(l_xwypo_rec.shipping_pace)
                   || cv_csv_delimiter
        ;
      ELSE
        lv_csvbuff := lv_csvbuff
                   || cv_csv_delimiter
        ;
      END IF;
      --特別横持
      IF (l_xwypo_rec.output_num = 1) THEN
        lv_csvbuff := lv_csvbuff
                   || l_xwypo_rec.special_yoko_flag
                   || cv_csv_delimiter
        ;
      ELSE
        lv_csvbuff := lv_csvbuff
                   || cv_csv_delimiter
        ;
      END IF;
      --補充不可
      lv_csvbuff := lv_csvbuff
                  || l_xwypo_rec.short_supply_flag
                  || cv_csv_delimiter
      ;
      --ロット逆転
      lv_csvbuff := lv_csvbuff
                 || l_xwypo_rec.lot_reverse_flag
      ;
      --処理結果レポートに出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_csvbuff
      );
    END LOOP xwypo_loop;
--
  EXCEPTION
    WHEN internal_api_expt THEN
      ov_errmsg  := lv_errmsg;
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
  END output_xwypo;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
     iv_planning_date_from  IN     VARCHAR2                 -- 1.計画立案期間(FROM)
    ,iv_planning_date_to    IN     VARCHAR2                 -- 2.計画立案期間(TO)
    ,iv_plan_type           IN     VARCHAR2                 -- 3.出荷計画区分
    ,iv_shipment_date_from  IN     VARCHAR2                 -- 4.出荷ペース計画期間(FROM)
    ,iv_shipment_date_to    IN     VARCHAR2                 -- 5.出荷ペース計画期間(TO)
    ,iv_forecast_date_from  IN     VARCHAR2                 -- 6.出荷予測期間(FROM)
    ,iv_forecast_date_to    IN     VARCHAR2                 -- 7.出荷予測期間(TO)
    ,iv_allocated_date      IN     VARCHAR2                 -- 8.出荷引当済日
    ,iv_item_code           IN     VARCHAR2                 -- 9.品目コード
--20100203_Ver1.2_E_本稼動_01222_SCS.Goto_ADD_START
    ,iv_working_days        IN     VARCHAR2                 --10.稼動日数
    ,iv_stock_adjust_value  IN     VARCHAR2                 --11.在庫日数調整値
--20100203_Ver1.2_E_本稼動_01222_SCS.Goto_ADD_END
    ,ov_errbuf              OUT    VARCHAR2                 --   エラー・メッセージ           --# 固定 #
    ,ov_retcode             OUT    VARCHAR2                 --   リターン・コード             --# 固定 #
    ,ov_errmsg              OUT    VARCHAR2                 --   ユーザー・エラー・メッセージ --# 固定 #
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
    ld_planning_date_from          DATE;    --
    ld_planning_date_to            DATE;    --
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
    -- ===============================
    -- A-1．初期処理
    -- ===============================
    init(
        iv_planning_date_from => iv_planning_date_from       -- 計画立案期間(FROM)
       ,iv_planning_date_to   => iv_planning_date_to         -- 計画立案期間(TO)
       ,iv_plan_type          => iv_plan_type                -- 出荷計画区分
       ,iv_shipment_date_from => iv_shipment_date_from       -- 出荷ペース計画期間(FROM)
       ,iv_shipment_date_to   => iv_shipment_date_to         -- 出荷ペース計画期間(TO)
       ,iv_forecast_date_from => iv_forecast_date_from       -- 出荷予測期間(FROM)
       ,iv_forecast_date_to   => iv_forecast_date_to         -- 出荷予測期間(TO)
       ,iv_allocated_date     => iv_allocated_date           -- 出荷引当済日
       ,iv_item_code          => iv_item_code                -- 品目コード
--20100203_Ver1.2_E_本稼動_01222_SCS.Goto_ADD_START
       ,iv_working_days       => iv_working_days             -- 稼動日数
       ,iv_stock_adjust_value => iv_stock_adjust_value       -- 在庫日数調整値
--20100203_Ver1.2_E_本稼動_01222_SCS.Goto_ADD_END
       ,ov_errbuf             => lv_errbuf                   -- エラー・メッセージ           --# 固定 #
       ,ov_retcode            => lv_retcode                  -- リターン・コード             --# 固定 #
       ,ov_errmsg             => lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    -- ===============================
    -- A-2. 関連テーブル削除
    -- ===============================
    delete_table(
       ov_errbuf  => lv_errbuf
      ,ov_retcode => lv_retcode
      ,ov_errmsg  => lv_errmsg
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    -- ===============================
    -- A-3．子コンカレント発行処理
    -- ===============================
    request_conc(
        ov_errbuf        => lv_errbuf        -- エラー・メッセージ           --# 固定 #
       ,ov_retcode       => lv_retcode       -- リターン・コード             --# 固定 #
       ,ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-4. 横持計画CSV出力
    -- ===============================
    output_xwypo(
        ov_errbuf        => lv_errbuf        -- エラー・メッセージ           --# 固定 #
       ,ov_retcode       => lv_retcode       -- リターン・コード             --# 固定 #
       ,ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      IF (lv_errbuf IS NOT NULL) THEN
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      END IF;
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
     errbuf                 OUT    VARCHAR2                 --   エラーメッセージ #固定#
    ,retcode                OUT    VARCHAR2                 --   エラーコード     #固定#
    ,iv_planning_date_from  IN     VARCHAR2                 -- 1.計画立案期間(FROM)
    ,iv_planning_date_to    IN     VARCHAR2                 -- 2.計画立案期間(TO)
    ,iv_plan_type           IN     VARCHAR2                 -- 3.出荷計画区分
    ,iv_shipment_date_from  IN     VARCHAR2                 -- 4.出荷ペース計画期間(FROM)
    ,iv_shipment_date_to    IN     VARCHAR2                 -- 5.出荷ペース計画期間(TO)
    ,iv_forecast_date_from  IN     VARCHAR2                 -- 6.出荷予測期間(FROM)
    ,iv_forecast_date_to    IN     VARCHAR2                 -- 7.出荷予測期間(TO)
    ,iv_allocated_date      IN     VARCHAR2                 -- 8.出荷引当済日
    ,iv_item_code           IN     VARCHAR2                 -- 9.品目コード
--20100203_Ver1.2_E_本稼動_01222_SCS.Goto_ADD_START
    ,iv_working_days        IN     VARCHAR2                 --10.稼動日数
    ,iv_stock_adjust_value  IN     VARCHAR2                 --11.在庫日数調整値
--20100203_Ver1.2_E_本稼動_01222_SCS.Goto_ADD_END
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code        VARCHAR2(100);
--
    cv_normal_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; --正常終了メッセージ
    cv_warn_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; --警告終了メッセージ
--    cv_error_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; --異常終了メッセージ
    cv_error_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90007'; --異常終了メッセージ
    --
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       iv_which   => 'LOG'
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
       iv_planning_date_from => iv_planning_date_from       -- 計画立案期間(FROM)
      ,iv_planning_date_to   => iv_planning_date_to         -- 計画立案期間(TO)
      ,iv_plan_type          => iv_plan_type                -- 出荷計画区分
      ,iv_shipment_date_from => iv_shipment_date_from       -- 出荷ペース計画期間(FROM)
      ,iv_shipment_date_to   => iv_shipment_date_to         -- 出荷ペース計画期間(TO)
      ,iv_forecast_date_from => iv_forecast_date_from       -- 出荷予測期間(FROM)
      ,iv_forecast_date_to   => iv_forecast_date_to         -- 出荷予測期間(TO)
      ,iv_allocated_date     => iv_allocated_date           -- 出荷引当済日
      ,iv_item_code          => iv_item_code                -- 品目コード
--20100203_Ver1.2_E_本稼動_01222_SCS.Goto_ADD_START
      ,iv_working_days       => iv_working_days             -- 稼動日数
      ,iv_stock_adjust_value => iv_stock_adjust_value       -- 在庫日数調整値
--20100203_Ver1.2_E_本稼動_01222_SCS.Goto_ADD_END
      ,ov_errbuf             => lv_errbuf                   -- エラー・メッセージ           --# 固定 #
      ,ov_retcode            => lv_retcode                  -- リターン・コード             --# 固定 #
      ,ov_errmsg             => lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (gv_debug_mode IS NOT NULL) AND (gv_log_buffer IS NOT NULL) THEN
      --空白行出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => NULL
      );
    END IF;
    IF ( lv_retcode = cv_status_error ) THEN
      -- エラーの場合、成功件数の初期化とエラー件数のセット
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
      gn_warn_cnt   := 0;
      --エラー出力(CSV出力のためログに出力)
      IF (lv_errmsg IS NOT NULL) THEN
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff => lv_errmsg --ユーザー・エラーメッセージ
        );
      END IF;
      IF (lv_errbuf IS NOT NULL) THEN
        --システムエラーの編集
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00041
                       ,iv_token_name1  => cv_msg_00041_token_1
                       ,iv_token_value1 => lv_errbuf
                     );
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff => lv_errbuf --エラーメッセージ
        );
      END IF;
      --空行挿入
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => NULL
      );
    END IF;
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => 'XXCCP'
                    ,iv_name         => 'APP-XXCCP1-90000'
                    ,iv_token_name1  => 'COUNT'
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    --CSV出力のためログに出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => 'XXCCP'
                    ,iv_name         => 'APP-XXCCP1-90001'
                    ,iv_token_name1  => 'COUNT'
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    --CSV出力のためログに出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => 'XXCCP'
                    ,iv_name         => 'APP-XXCCP1-90002'
                    ,iv_token_name1  => 'COUNT'
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    --CSV出力のためログに出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff => gv_out_msg
    );
    --
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => 'XXCCP'
                    ,iv_name         => 'APP-XXCCP1-90003'
                    ,iv_token_name1  => 'COUNT'
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    --CSV出力のためログに出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff => gv_out_msg
    );
--
    -- 正常終了で子コンカレントに1件でもエラーがある場合警告終了
    IF (lv_retcode = cv_status_normal AND gn_error_cnt > 0) THEN
      lv_retcode := cv_status_warn;
    END IF;
--
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF (lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF (lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => 'XXCCP'
                    ,iv_name         => lv_message_code
                   );
    --CSV出力のためログに出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff => gv_out_msg
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
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCOP006A01C;
/
