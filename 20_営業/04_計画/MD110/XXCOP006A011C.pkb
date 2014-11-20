CREATE OR REPLACE PACKAGE BODY XXCOP006A011C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP006A011C(body)
 * Description      : 横持計画
 * MD.050           : 横持計画 MD050_COP_006_A01
 * Version          : 3.5
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  put_log_level          ログレベル出力                                       (B-26)
 *  entry_xwypo            横持計画出力ワークテーブル登録                       (B-25)
 *  entry_xli_lot          横持計画手持在庫テーブル登録(ロット計画数)           (B-24)
 *  update_xwyl_schedule   横持計画品目別代表倉庫ワークテーブル更新             (B-23)
 *  entry_xli_balance      横持計画手持在庫テーブル登録(バランス計画数)         (B-22)
 *  entry_supply_failed    横持計画出力ワークテーブル登録(計画不可)             (B-21)
 *  proc_lot_quantity      計画ロットの決定                                     (B-20)
 *  proc_balance_quantity  バランス計画数の計算                                 (B-19)
 *  proc_ship_loct         移動元倉庫の特定                                     (B-18)
 *  proc_safety_quantity   安全在庫の計算                                       (B-17)
 *  entry_xli_shipment     横持計画手持在庫テーブル登録(出荷ペース)             (B-16)
 *  entry_xli_po           横持計画手持在庫テーブル登録(購入計画)               (B-15)
 *  entry_xli_fs           横持計画手持在庫テーブル登録(工場出荷計画)           (B-14)
 *  entry_xwyp             横持計画物流ワークテーブル登録                       (B-13)
 *  chk_freshness_cond     鮮度条件チェック                                     (B-12)
 *  chk_effective_route    特別横持計画有効期間チェック                         (B-11)
 *  init                   初期処理                                             (B-1)
 *  get_msr_route          横持計画制御マスタ取得                               (B-2)
 *  entry_xwyl             品目別代表倉庫取得                                   (B-3)
 *  proc_shipping_pace     出荷ペースの計算                                     (B-4)
 *  proc_total_pace        総出荷ペースの計算                                   (B-5)
 *  create_xli             手持在庫テーブル作成                                 (B-6)
 *  get_msd_schedule       基準計画トランザクション作成                         (B-7)
 *  get_shipment_schedule  出荷トランザクション作成                             (B-8)
 *  create_yoko_plan       横持計画作成                                         (B-9)
 *  output_xwypo           横持計画CSV成形                                      (B-10)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/19    1.0   Y.Goto           新規作成
 *  2009/04/07    1.1   Y.Goto           T1_0273,T1_0274,T1_0289,T1_0366,T1_0367対応
 *  2009/04/14    1.2   Y.Goto           T1_0539,T1_0541対応
 *  2009/04/28    1.3   Y.Goto           T1_0846,T1_0920対応
 *  2009/06/12    1.4   Y.Goto           T1_1394対応
 *  2009/07/13    2.0   Y.Goto           0000669対応(共通課題IE479)
 *  2009/10/20    2.1   Y.Goto           I_E_479_001
 *  2009/10/20    2.2   Y.Goto           I_E_479_002
 *  2009/10/22    2.3   Y.Goto           I_E_479_003
 *  2009/10/26    2.4   Y.Goto           I_E_479_004
 *  2009/10/27    2.5   Y.Goto           I_E_479_005
 *  2009/10/28    2.6   Y.Goto           I_E_479_006
 *  2009/11/09    2.7   Y.Goto           I_E_479_011,I_E_479_012
 *  2009/11/11    2.8   Y.Goto           I_E_479_013
 *  2009/11/17    2.9   Y.Goto           I_E_479_015
 *  2009/11/19    2.10  Y.Goto           I_E_479_017
 *  2009/11/30    3.0   Y.Goto           I_E_479_019(横持計画パラレル化対応、アプリPT対応、プログラムIDの変更)
 *  2009/12/17    3.1   Y.Goto           E_本稼動_00519
 *  2010/01/07    3.2   Y.Goto           E_本稼動_00936
 *  2010/01/25    3.3   Y.Goto           E_本稼動_01250
 *  2010/02/03    3.4   Y.Goto           E_本稼動_01222
 *  2010/02/10    3.5   Y.Goto           E_本稼動_01560
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
  internal_api_expt         EXCEPTION;     -- コンカレント内部共通例外
  param_invalid_expt        EXCEPTION;     -- 入力パラメータチェックエラー
  date_invalid_expt         EXCEPTION;     -- 日付チェックエラー
  date_reverse_expt         EXCEPTION;     -- FROM-TO逆転チェックエラー
  past_date_invalid_expt    EXCEPTION;     -- 過去日チェックエラー
  prior_date_invalid_expt   EXCEPTION;     -- 未来日チェックエラー
  profile_invalid_expt      EXCEPTION;     -- プロファイル値エラー
  stock_days_expt           EXCEPTION;     -- 在庫日数チェックエラー
  no_condition_expt         EXCEPTION;     -- 鮮度条件未登録エラー
  obsolete_skip_expt        EXCEPTION;     -- 廃止スキップ例外
  short_supply_expt         EXCEPTION;     -- 在庫不足例外
  nested_loop_expt          EXCEPTION;     -- 階層ループエラー
  not_need_expt             EXCEPTION;     -- 計画不要例外
  outside_scope_expt        EXCEPTION;     -- 対象外例外
  lot_skip_expt             EXCEPTION;     -- ロットスキップ例外
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_ADD_START
  manufacture_skip_expt     EXCEPTION;     -- 製造年月日スキップ例外
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_ADD_END
--
  PRAGMA EXCEPTION_INIT(nested_loop_expt, -01436);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOP006A011C';          -- パッケージ名
  --メッセージ共通
  cv_msg_appl_cont          CONSTANT VARCHAR2(100) := 'XXCOP';                  -- アプリケーション短縮名
  --言語
  cv_lang                   CONSTANT VARCHAR2(100) := USERENV('LANG');          -- 言語
  --プログラム実行年月日
  cd_sysdate                CONSTANT DATE := TRUNC(SYSDATE);                    -- システム日付（年月日）
  --日付型フォーマット
  cv_date_format            CONSTANT VARCHAR2(100) := 'YYYY/MM/DD';             -- 年月日
  cv_trunc_month            CONSTANT VARCHAR2(100) := 'MM';                     -- 年月
  --タイムスタンプ型フォーマット
  cv_timestamp_format       CONSTANT VARCHAR2(100) := 'HH24:MI:SS.FF3';         -- 年月日時分秒
  --数値型フォーマット
  cv_num42_format           CONSTANT VARCHAR2(100) := '9999.99';                -- 数値4,2
  --日付
  cd_lower_limit_date       CONSTANT DATE := TO_DATE('1900/01/01', cv_date_format);-- 最小年月日
  cd_upper_limit_date       CONSTANT DATE := TO_DATE('9999/12/31', cv_date_format);-- 最大年月日
  --デバックメッセージインデント
  cv_indent_2               CONSTANT CHAR(2) := '  ';                           -- 2文字空白
  cv_indent_4               CONSTANT CHAR(4) := '    ';                         -- 4文字空白
  --メッセージ名
  cv_msg_00065              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00065';
  cv_msg_00042              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00042';
  cv_msg_00055              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00055';
  cv_msg_00011              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00011';
  cv_msg_00047              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00047';
  cv_msg_10009              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10009';
  cv_msg_00025              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00025';
  cv_msg_00002              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00002';
  cv_msg_00027              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00027';
  cv_msg_00028              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00028';
  cv_msg_00061              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00061';
  cv_msg_00049              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00049';
  cv_msg_00050              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00050';
  cv_msg_00053              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00053';
  cv_msg_10039              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10039';
  cv_msg_00068              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00068';
  cv_msg_10040              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10040';
  cv_msg_10041              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10041';
  cv_msg_10038              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10038';
  cv_msg_00003              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00003';
  cv_msg_00060              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00060';
  cv_msg_00041              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00041';
  cv_msg_00056              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00056';
  cv_msg_00057              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00057';
  cv_msg_00066              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00066';
  cv_msg_00067              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00067';
  cv_msg_10045              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10045';
--20100203_Ver3.4_E_本稼動_01222_SCS.Goto_ADD_START
  cv_msg_10057              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10057';
--20100203_Ver3.4_E_本稼動_01222_SCS.Goto_ADD_END
  cv_msg_10047              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10047';
  cv_msg_10050              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10050';
  cv_msg_10051              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10051';
  --メッセージトークン
  cv_msg_00042_token_1      CONSTANT VARCHAR2(100) := 'TABLE';
  cv_msg_00011_token_1      CONSTANT VARCHAR2(100) := 'ITEM';
  cv_msg_00047_token_1      CONSTANT VARCHAR2(100) := 'ITEM_NAME';
  cv_msg_10009_token_1      CONSTANT VARCHAR2(100) := 'ITEM_NAME';
  cv_msg_00025_token_1      CONSTANT VARCHAR2(100) := 'PERIOD_FROM';
  cv_msg_00025_token_2      CONSTANT VARCHAR2(100) := 'PERIOD_TO';
  cv_msg_00002_token_1      CONSTANT VARCHAR2(100) := 'PROF_NAME';
  cv_msg_00027_token_1      CONSTANT VARCHAR2(100) := 'TABLE';
  cv_msg_00028_token_1      CONSTANT VARCHAR2(100) := 'TABLE';
  cv_msg_00061_token_1      CONSTANT VARCHAR2(100) := 'ITEM';
  cv_msg_00053_token_1      CONSTANT VARCHAR2(100) := 'WHSE_CODE_FROM';
  cv_msg_00053_token_2      CONSTANT VARCHAR2(100) := 'WHSE_CODE_TO';
  cv_msg_10039_token_1      CONSTANT VARCHAR2(100) := 'WHSE_CODE';
  cv_msg_10039_token_2      CONSTANT VARCHAR2(100) := 'ITEM';
  cv_msg_00068_token_1      CONSTANT VARCHAR2(100) := 'WHSE_CODE';
  cv_msg_00068_token_2      CONSTANT VARCHAR2(100) := 'ITEM';
  cv_msg_10040_token_1      CONSTANT VARCHAR2(100) := 'WHSE_CODE';
  cv_msg_10040_token_2      CONSTANT VARCHAR2(100) := 'ITEM';
  cv_msg_10040_token_3      CONSTANT VARCHAR2(100) := 'FRESHNESS_COND';
  cv_msg_10041_token_1      CONSTANT VARCHAR2(100) := 'WHSE_CODE';
  cv_msg_10041_token_2      CONSTANT VARCHAR2(100) := 'ITEM';
  cv_msg_10041_token_3      CONSTANT VARCHAR2(100) := 'FRESHNESS_COND';
  cv_msg_10041_token_4      CONSTANT VARCHAR2(100) := 'ITEM_NAME';
  cv_msg_10038_token_1      CONSTANT VARCHAR2(100) := 'WHSE_CODE';
  cv_msg_10038_token_2      CONSTANT VARCHAR2(100) := 'ITEM';
  cv_msg_00060_token_1      CONSTANT VARCHAR2(100) := 'WHSE_CODE';
  cv_msg_00060_token_2      CONSTANT VARCHAR2(100) := 'ITEM';
  cv_msg_00041_token_1      CONSTANT VARCHAR2(100) := 'ERRMSG';
  cv_msg_00049_token_1      CONSTANT VARCHAR2(100) := 'ITEMID';
  cv_msg_00050_token_1      CONSTANT VARCHAR2(100) := 'ORGID';
  cv_msg_00056_token_1      CONSTANT VARCHAR2(100) := 'FROM_DATE';
  cv_msg_00056_token_2      CONSTANT VARCHAR2(100) := 'TO_DATE';
  cv_msg_00066_token_1      CONSTANT VARCHAR2(100) := 'WHSE_CODE';
  cv_msg_00066_token_2      CONSTANT VARCHAR2(100) := 'CALENDAR_CODE';
  cv_msg_00066_token_3      CONSTANT VARCHAR2(100) := 'SHIP_DATE';
  cv_msg_00067_token_1      CONSTANT VARCHAR2(100) := 'WHSE_CODE';
  cv_msg_00067_token_2      CONSTANT VARCHAR2(100) := 'CALENDAR_CODE';
  cv_msg_00067_token_3      CONSTANT VARCHAR2(100) := 'RECEIPT_DATE';
  cv_msg_10045_token_1      CONSTANT VARCHAR2(100) := 'PLANNING_DATE_FROM';
  cv_msg_10045_token_2      CONSTANT VARCHAR2(100) := 'PLANNING_DATE_TO';
  cv_msg_10045_token_3      CONSTANT VARCHAR2(100) := 'PLAN_TYPE';
  cv_msg_10045_token_4      CONSTANT VARCHAR2(100) := 'SHIPMENT_DATE_FROM';
  cv_msg_10045_token_5      CONSTANT VARCHAR2(100) := 'SHIPMENT_DATE_TO';
  cv_msg_10045_token_6      CONSTANT VARCHAR2(100) := 'FORECAST_DATE_FROM';
  cv_msg_10045_token_7      CONSTANT VARCHAR2(100) := 'FORECAST_DATE_TO';
  cv_msg_10045_token_8      CONSTANT VARCHAR2(100) := 'ALLOCATED_DATE';
  cv_msg_10045_token_9      CONSTANT VARCHAR2(100) := 'ITEM_NO';
--20100203_Ver3.4_E_本稼動_01222_SCS.Goto_ADD_START
  cv_msg_10057_token_1      CONSTANT VARCHAR2(100) := 'WORKING_DAYS';
  cv_msg_10057_token_2      CONSTANT VARCHAR2(100) := 'STOCK_ADJUST_VALUE';
--20100203_Ver3.4_E_本稼動_01222_SCS.Goto_ADD_END
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
--
  --メッセージトークン値
  cv_table_xwypo            CONSTANT VARCHAR2(100) := '横持計画出力ワークテーブル';
  cv_table_xwyp             CONSTANT VARCHAR2(100) := '横持計画物流ワークテーブル';
  cv_table_xli              CONSTANT VARCHAR2(100) := '横持計画手持在庫テーブル';
  cv_table_xwyl             CONSTANT VARCHAR2(100) := '横持計画品目別代表倉庫ワークテーブル';
  cv_msg_10041_value_1      CONSTANT VARCHAR2(100) := '安全在庫日数';
  cv_msg_10041_value_2      CONSTANT VARCHAR2(100) := '最大在庫日数';
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
--20100203_Ver3.4_E_本稼動_01222_SCS.Goto_ADD_START
  cv_working_days_tl        CONSTANT VARCHAR2(100) := '稼働日数';
  cv_stock_adjust_value_tl  CONSTANT VARCHAR2(100) := '在庫日数調整値';
--20100203_Ver3.4_E_本稼動_01222_SCS.Goto_ADD_END
  --プロファイル
  cv_pf_master_org_id       CONSTANT VARCHAR2(100) := 'XXCMN_MASTER_ORG_ID';
  cv_pf_source_org_id       CONSTANT VARCHAR2(100) := 'XXCOP1_DUMMY_SOURCE_ORG_ID';
  cv_pf_fresh_buffer_days   CONSTANT VARCHAR2(100) := 'XXCOP1_FRESHNESS_BUFFER_DAYS';
  cv_pf_frq_loct_code       CONSTANT VARCHAR2(100) := 'XXCMN_DUMMY_FREQUENT_WHSE';
  cv_pf_partition_num       CONSTANT VARCHAR2(100) := 'XXCOP1_PARTITION_NUM';
  cv_pf_debug_mode          CONSTANT VARCHAR2(100) := 'XXCOP1_DEBUG_MODE';
  --クイックコードタイプ
  cv_flv_assignment_name    CONSTANT VARCHAR2(100) := 'XXCOP1_ASSIGNMENT_NAME';
  cv_flv_assign_priority    CONSTANT VARCHAR2(100) := 'XXCOP1_ASSIGN_TYPE_PRIORITY';
  cv_flv_freshness_cond     CONSTANT VARCHAR2(100) := 'XXCMN_FRESHNESS_CONDITION';
  cv_enable                 CONSTANT VARCHAR2(100) := 'Y';
  --出荷計画区分
  cv_plan_type_shipped      CONSTANT VARCHAR2(100) := '1';                      -- 出荷ペース
  cv_plan_type_forecate     CONSTANT VARCHAR2(100) := '2';                      -- 出荷予測
  --割当セット区分
  cv_base_plan              CONSTANT VARCHAR2(1)   := '1';                      -- 基本横持計画
  cv_custom_plan            CONSTANT VARCHAR2(1)   := '2';                      -- 特別横持計画
  cv_factory_ship_plan      CONSTANT VARCHAR2(1)   := '3';                      -- 工場出荷計画
  --割当先区分
  cv_assign_type_global     CONSTANT NUMBER        := 1;                        -- グローバル
  cv_assign_type_org        CONSTANT NUMBER        := 4;                        -- 組織
  cv_assign_type_item       CONSTANT NUMBER        := 3;                        -- 品目
  cv_assign_type_item_org   CONSTANT NUMBER        := 6;                        -- 品目-組織
  --出荷元区分
  cn_location_source        CONSTANT NUMBER        := 1;                        -- 移動元
  cn_location_manufacture   CONSTANT NUMBER        := 2;                        -- 製造場所
  cn_location_vendor        CONSTANT NUMBER        := 3;                        -- 購買元
  --鮮度条件の分類
  cv_condition_general      CONSTANT VARCHAR2(1)   := '0';                      -- 一般
  cv_condition_expiration   CONSTANT VARCHAR2(1)   := '1';                      -- 賞味期限基準
  cv_condition_manufacture  CONSTANT VARCHAR2(1)   := '2';                      -- 製造日基準
  --計画タイプ
  cv_plan_balance           CONSTANT VARCHAR2(1)   := '0';                      -- バランス
  cv_plan_minimum           CONSTANT VARCHAR2(1)   := '1';                      -- 最小
  cv_plan_maximum           CONSTANT VARCHAR2(1)   := '2';                      -- 最大
  --基準計画分類
  cv_msd_forecast           CONSTANT VARCHAR2(10)  := '1';                      -- 出荷予測
  cv_msd_fs_sched           CONSTANT VARCHAR2(10)  := '2';                      -- 工場出荷計画
  cv_msd_po_sched           CONSTANT VARCHAR2(10)  := '3';                      -- 購入計画
  --製造・購入品フラグ
  cv_manufacture            CONSTANT VARCHAR2(10)  := '1';                      -- 製造品
  cv_purchase               CONSTANT VARCHAR2(10)  := '2';                      -- 購入品
  --スケジュールLEVEL
  cn_schedule_level         CONSTANT NUMBER        := 2;                        -- 
  --計画立案フラグ
  cv_planning_yes           CONSTANT VARCHAR2(10)  := 'Y';                      -- YES
  cv_planning_no            CONSTANT VARCHAR2(10)  := 'N';                      -- NO
  cv_planning_omit          CONSTANT VARCHAR2(10)  := 'O';                      -- 除外
  --倉庫識別
  cv_inc_loct               CONSTANT VARCHAR2(10)  := '1';                      -- 代表倉庫＋工場倉庫
  cv_off_loct               CONSTANT VARCHAR2(10)  := '2';                      -- 工場倉庫の代表倉庫
  --擬似更新フラグ
  cv_simulate_yes           CONSTANT VARCHAR2(10)  := 'Y';                      -- YES
  --安全在庫判定ステータス
  cv_enough                 CONSTANT VARCHAR2(10)  := '0';                      -- 安全在庫以上
  cv_shortage               CONSTANT VARCHAR2(10)  := '1';                      -- 安全在庫未満
  --計画立案ステータス
  cv_complete               CONSTANT VARCHAR2(10)  := '0';                      -- 計画完了
  cv_incomplete             CONSTANT VARCHAR2(10)  := '1';                      -- 計画継続
  cv_failed                 CONSTANT VARCHAR2(10)  := '2';                      -- 計画不可
  --品目マスタステータス
  cn_iimb_status_active     CONSTANT NUMBER := 0;                               -- ステータス
  cn_ximb_status_active     CONSTANT NUMBER := 0;                               -- ステータス
  cv_shipping_enable        CONSTANT NUMBER := '1';                             -- ステータス
  --横持計画手持在庫テーブル
  cv_xli_type_inv           CONSTANT VARCHAR2(10)  := '00';                     -- 手持在庫
  cv_xli_type_po            CONSTANT VARCHAR2(10)  := '10';                     -- 基準計画(購入計画)
  cv_xli_type_fs            CONSTANT VARCHAR2(10)  := '20';                     -- 基準計画(工場出荷計画)
  cv_xli_type_sp            CONSTANT VARCHAR2(10)  := '30';                     -- 出荷ペース
  cv_xli_type_bq            CONSTANT VARCHAR2(10)  := '40';                     -- 横持計画(バランス計算引当数)
  cv_xli_type_lq            CONSTANT VARCHAR2(10)  := '50';                     -- 横持計画(ロット計画数)
  --CSVファイル出力フォーマット
  cv_csv_mark               CONSTANT VARCHAR2(1)   := '*';                      -- アスタリスク
  --ログ出力レベル
  cv_log_level1             CONSTANT VARCHAR2(1)   := '1';                      -- 
  cv_log_level2             CONSTANT VARCHAR2(1)   := '2';                      -- 
  cv_log_level3             CONSTANT VARCHAR2(1)   := '3';                      -- 
  --補充ステータス
  cv_supply_enough          CONSTANT VARCHAR2(1)   := '1';                      -- 補充完了
  cv_supply_shortage        CONSTANT VARCHAR2(1)   := '0';                      -- 補充数不足
  --出力対象フラグ
  cv_output_off             CONSTANT VARCHAR2(1)   := '0';                      -- 対象外
  cv_output_on              CONSTANT VARCHAR2(1)   := '1';                      -- 対象
--20100107_Ver3.2_E_本稼動_00936_SCS.Goto_ADD_START
  --品目カテゴリ
  cv_category_crowd_class   CONSTANT VARCHAR2(8)   := '群コード';               -- 群コード
--20100107_Ver3.2_E_本稼動_00936_SCS.Goto_ADD_END
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  --横持計画物流ワークテーブルコレクション型
  TYPE g_xwyp_ttype IS TABLE OF xxcop_wk_yoko_planning%ROWTYPE
    INDEX BY BINARY_INTEGER;
  --横持計画出力ワークテーブルコレクション型
  TYPE g_xwypo_ttype IS TABLE OF xxcop_wk_yoko_plan_output%ROWTYPE
    INDEX BY BINARY_INTEGER;
  --横持計画手持在庫テーブルコレクション型
  TYPE g_xli_ttype IS TABLE OF xxcop_loct_inv%ROWTYPE
    INDEX BY BINARY_INTEGER;
  --横持計画品目別代表倉庫ワークテーブルコレクション型
  TYPE g_xwyl_ttype IS TABLE OF xxcop_wk_yoko_locations%ROWTYPE
    INDEX BY BINARY_INTEGER;
  --インデックスコレクション型
  TYPE g_idx_ttype IS TABLE OF NUMBER
    INDEX BY BINARY_INTEGER;
  --ROWIDコレクション型
  TYPE g_rowid_ttype IS TABLE OF ROWID
    INDEX BY BINARY_INTEGER;
--
  --鮮度条件レコード型
  TYPE g_freshness_condition_rtype IS RECORD (
     freshness_priority       xxcop_wk_yoko_planning.freshness_priority%TYPE
    ,freshness_condition      xxcop_wk_yoko_planning.freshness_condition%TYPE
    ,freshness_class          xxcop_wk_yoko_planning.freshness_class%TYPE
    ,freshness_check_value    xxcop_wk_yoko_planning.freshness_check_value%TYPE
    ,freshness_adjust_value   xxcop_wk_yoko_planning.freshness_adjust_value%TYPE
    ,safety_stock_days        xxcop_wk_yoko_planning.safety_stock_days%TYPE
    ,max_stock_days           xxcop_wk_yoko_planning.max_stock_days%TYPE
  );
  --鮮度条件コレクション型
  TYPE g_fc_ttype IS TABLE OF g_freshness_condition_rtype
    INDEX BY BINARY_INTEGER;
--
  --出荷ペースレコード型
  TYPE g_shipping_pace_rtype IS RECORD (
     shipping_pace            xxcop_wk_yoko_planning.shipping_pace%TYPE
    ,forecast_pace            xxcop_wk_yoko_planning.forecast_pace%TYPE
    ,shipping_quantity        NUMBER
    ,forecast_quantity        NUMBER
  );
  --出荷ペースコレクション型
  TYPE g_sp_ttype IS TABLE OF g_shipping_pace_rtype
    INDEX BY BINARY_INTEGER;
--
  --出荷ペース在庫引当レコード型
  TYPE g_shipping_allocate_rtype IS RECORD (
     item_id                  xxcop_wk_yoko_planning.item_id%TYPE
    ,item_no                  xxcop_wk_yoko_planning.item_no%TYPE
    ,rcpt_organization_id     xxcop_wk_yoko_planning.rcpt_organization_id%TYPE
    ,rcpt_organization_code   xxcop_wk_yoko_planning.rcpt_organization_code%TYPE
    ,rcpt_loct_id             xxcop_wk_yoko_planning.rcpt_loct_id%TYPE
    ,rcpt_loct_code           xxcop_wk_yoko_planning.rcpt_loct_code%TYPE
    ,rcpt_calendar_code       xxcop_wk_yoko_planning.rcpt_calendar_code%TYPE
    ,shipping_type            xxcop_wk_yoko_planning.shipping_type%TYPE
    ,shipping_pace            xxcop_wk_yoko_planning.shipping_pace%TYPE
    ,freshness_priority       xxcop_wk_yoko_planning.freshness_priority%TYPE
    ,freshness_class          xxcop_wk_yoko_planning.freshness_class%TYPE
    ,freshness_check_value    xxcop_wk_yoko_planning.freshness_check_value%TYPE
    ,freshness_adjust_value   xxcop_wk_yoko_planning.freshness_adjust_value%TYPE
    ,max_stock_days           xxcop_wk_yoko_planning.max_stock_days%TYPE
    ,allocate_quantity        NUMBER
  );
  --出荷ペース在庫引当コレクション型
  TYPE g_sa_ttype IS TABLE OF g_shipping_allocate_rtype
    INDEX BY BINARY_INTEGER;
--
  --倉庫情報レコード型
  TYPE g_loct_rtype IS RECORD (
     loct_id                  xxcop_wk_yoko_planning.rcpt_loct_id%TYPE
    ,loct_code                xxcop_wk_yoko_planning.rcpt_loct_code%TYPE
    ,delivery_lead_time       xxcop_wk_yoko_planning.delivery_lead_time%TYPE
    ,shipping_pace            xxcop_wk_yoko_planning.shipping_pace%TYPE
    ,target_date              xxcop_wk_yoko_planning.receipt_date%TYPE
  );
  --倉庫情報コレクション型
  TYPE g_loct_ttype IS TABLE OF g_loct_rtype
    INDEX BY BINARY_INTEGER;
--
  --品目情報レコード型
  TYPE g_item_rtype IS RECORD (
     item_id                  xxcop_wk_yoko_planning.item_id%TYPE
    ,item_no                  xxcop_wk_yoko_planning.item_no%TYPE
  );
  --品目情報コレクション型
  TYPE g_item_ttype IS TABLE OF g_item_rtype
    INDEX BY BINARY_INTEGER;
--
  --鮮度条件別在庫引当レコード型
  TYPE g_freshness_quantity_rtype IS RECORD (
     freshness_priority       xxcop_wk_yoko_planning.freshness_priority%TYPE
    ,freshness_condition      xxcop_wk_yoko_planning.freshness_condition%TYPE
    ,freshness_class          xxcop_wk_yoko_planning.freshness_class%TYPE
    ,freshness_check_value    xxcop_wk_yoko_planning.freshness_check_value%TYPE
    ,freshness_adjust_value   xxcop_wk_yoko_planning.freshness_adjust_value%TYPE
    ,safety_stock_days        xxcop_wk_yoko_planning.safety_stock_days%TYPE
    ,max_stock_days           xxcop_wk_yoko_planning.max_stock_days%TYPE
    ,shipping_pace            xxcop_wk_yoko_planning.shipping_pace%TYPE
    ,safety_stock_quantity    NUMBER
    ,max_stock_quantity       NUMBER
    ,allocate_quantity        NUMBER
    ,sy_manufacture_date      xxcop_wk_yoko_planning.sy_manufacture_date%TYPE
    ,sy_maxmum_quantity       xxcop_wk_yoko_planning.sy_maxmum_quantity%TYPE
    ,sy_stocked_quantity      xxcop_wk_yoko_planning.sy_stocked_quantity%TYPE
  );
  --鮮度条件別在庫引当コレクション型
  TYPE g_fq_ttype IS TABLE OF g_freshness_quantity_rtype
    INDEX BY BINARY_INTEGER;
--
  --移動元倉庫優先順位レコード型
  TYPE g_loct_priority_rtype IS RECORD (
     manufacture_date        DATE
    ,stock_days              NUMBER
    ,delivery_lead_time      NUMBER
    ,priority_idx            NUMBER
  );
  --移動元倉庫優先順位コレクション型
  TYPE g_lp_ttype IS TABLE OF g_loct_priority_rtype
    INDEX BY BINARY_INTEGER;
--
  --バランス横持計画レコード型
  TYPE g_balance_quantity_rtype IS RECORD (
     freshness_condition      xxcop_wk_yoko_plan_output.freshness_condition%TYPE
    ,freshness_class          xxcop_wk_yoko_plan_output.freshness_class%TYPE
    ,freshness_check_value    xxcop_wk_yoko_plan_output.freshness_check_value%TYPE
    ,freshness_adjust_value   xxcop_wk_yoko_plan_output.freshness_adjust_value%TYPE
    ,manufacture_date         xxcop_wk_yoko_plan_output.manufacture_date%TYPE
    ,plan_bal_quantity        xxcop_wk_yoko_plan_output.plan_bal_quantity%TYPE
    ,before_stock             xxcop_wk_yoko_plan_output.before_stock%TYPE
    ,after_stock              xxcop_wk_yoko_plan_output.after_stock%TYPE
    ,safety_stock_days        xxcop_wk_yoko_plan_output.safety_stock_days%TYPE
    ,max_stock_days           xxcop_wk_yoko_plan_output.max_stock_days%TYPE
    ,shipping_type            xxcop_wk_yoko_plan_output.shipping_type%TYPE
    ,shipping_pace            xxcop_wk_yoko_plan_output.shipping_pace%TYPE

  );
  --バランス横持計画コレクション型
  TYPE g_bq_ttype IS TABLE OF g_balance_quantity_rtype
    INDEX BY BINARY_INTEGER;
--
  --計画ロットレコード型
  TYPE g_lot_rtype IS RECORD (
     critical_date            xxcop_loct_inv.manufacture_date%TYPE              --鮮度条件基準日
    ,lot_quantity             xxcop_loct_inv.loct_onhand%TYPE                   --ロット引当数(ロット)
    ,freshness_quantity       xxcop_loct_inv.loct_onhand%TYPE                   --鮮度条件別在庫数(合計)
    ,plan_bal_quantity        xxcop_loct_inv.loct_onhand%TYPE                   --鮮度条件別バランス計画数(合計)
    ,adjust_quantity          xxcop_loct_inv.loct_onhand%TYPE                   --過不足数
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_ADD_START
    ,plan_lot_quantity        xxcop_loct_inv.loct_onhand%TYPE                   --ロット計画数
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_ADD_END
    ,stock_proc_flag          VARCHAR2(1)                                       --鮮度条件別在庫計算フラグ
    ,adjust_proc_flag         VARCHAR2(1)                                       --バランス計算フラグ
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_DEL_START
--    ,proc_flag                VARCHAR2(1)                                       --計画対象フラグ(Y/N)
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_DEL_END
  );
  --計画ロットコレクション型
  TYPE g_lot_ttype IS TABLE OF g_lot_rtype
    INDEX BY BINARY_INTEGER;
--
  --ロット在庫レコード型
  TYPE g_loct_inv_rtype IS RECORD (
     lot_id                   xxcop_loct_inv.lot_id%TYPE                        --ロットID
    ,lot_no                   xxcop_loct_inv.lot_no%TYPE                        --ロットNO
    ,manufacture_date         xxcop_loct_inv.manufacture_date%TYPE              --製造年月日
    ,expiration_date          xxcop_loct_inv.expiration_date%TYPE               --賞味期限
    ,unique_sign              xxcop_loct_inv.unique_sign%TYPE                   --固有記号
    ,lot_status               xxcop_loct_inv.lot_status%TYPE                    --ロットステータス
    ,loct_onhand              xxcop_loct_inv.loct_onhand%TYPE                   --在庫数
    ,loct_id                  xxcop_loct_inv.loct_id%TYPE                       --保管場所ID
    ,record_class             NUMBER                                            --レコード区分
  );
  --ロット在庫コレクション型
  TYPE g_li_ttype IS TABLE OF g_loct_inv_rtype
    INDEX BY BINARY_INTEGER;
--
  --ROWIDコレクション型
  TYPE g_rowid_tab_ttype IS TABLE OF g_rowid_ttype
    INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_planning_date          DATE;                                               --計画立案日
  gd_process_date           DATE;                                               --業務日付
  gn_transaction_id         NUMBER;                                             --トランザクションID
  gv_log_buffer             VARCHAR2(5000);                                     --ログ出力領域
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
--20100203_Ver3.4_E_本稼動_01222_SCS.Goto_ADD_START
  gn_working_days           NUMBER;                                             --稼働日数
  gn_stock_adjust_value     NUMBER;                                             --在庫日数調整値
--20100203_Ver3.4_E_本稼動_01222_SCS.Goto_ADD_END
  --プロファイル値
  gv_debug_mode             VARCHAR2(256);                                      --デバックモード
  gn_master_org_id          NUMBER;                                             --供給ルール(ダミー)組織ID
  gn_source_org_id          NUMBER;                                             --パッカー倉庫(ダミー)組織ID
  gn_freshness_buffer_days  NUMBER;                                             --鮮度条件バッファ日数
  gv_dummy_frequent_whse    VARCHAR2(4);                                        --ダミー代表倉庫
  gn_partition_num          NUMBER;                                             --パーティション数
--
  --品目別代表倉庫テーブルROWID
  g_xwyl_tab                g_rowid_tab_ttype;
--
/************************************************************************
 * Procedure Name  : put_log_level
 * Description     : ログレベル出力(B-26)
 ************************************************************************/
  PROCEDURE put_log_level(
    iv_log_level            IN     VARCHAR2,       -- メッセージレベル
    id_receipt_date         IN     DATE,           -- 着日
    iv_item_no              IN     VARCHAR2,       -- 品目
    iv_loct_code            IN     VARCHAR2,       -- 倉庫
    iv_freshness_condition  IN     VARCHAR2,       -- 鮮度条件
    in_stock_quantity       IN     NUMBER,         -- 引当可能数
    in_shipping_pace        IN     NUMBER,         -- 出荷ペース
    in_supplies_quantity    IN     NUMBER,         -- 補充可能数
    id_manufacture_date     IN     DATE,           -- 製造年月日
    ov_errbuf               OUT    VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode              OUT    VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg               OUT    VARCHAR2        --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_log_level'; -- プログラム名
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
    ln_stock_days             NUMBER;
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
    --初期化
    ln_stock_days := NULL;
--
    IF (gv_debug_mode <= iv_log_level) THEN
      --ログメッセージヘッダーの出力
      IF (gv_log_buffer IS NULL) THEN
        gv_log_buffer := xxccp_common_pkg.get_msg(
                            iv_application   => cv_msg_appl_cont
                           ,iv_name          => cv_msg_10050
                         );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_log_buffer
        );
      END IF;
--
      --ログメッセージーの出力
      IF (in_shipping_pace <> 0) THEN
        ln_stock_days := in_stock_quantity / in_shipping_pace;
      END IF;
      gv_log_buffer := xxccp_common_pkg.get_msg(
                          iv_application   => cv_msg_appl_cont
                         ,iv_name          => cv_msg_10051
                         ,iv_token_name1   => cv_msg_10051_token_1
                         ,iv_token_value1  => iv_log_level
                         ,iv_token_name2   => cv_msg_10051_token_2
                         ,iv_token_value2  => TO_CHAR(id_receipt_date, cv_date_format)
                         ,iv_token_name3   => cv_msg_10051_token_3
                         ,iv_token_value3  => iv_item_no
                         ,iv_token_name4   => cv_msg_10051_token_4
                         ,iv_token_value4  => iv_loct_code
                         ,iv_token_name5   => cv_msg_10051_token_5
                         ,iv_token_value5  => iv_freshness_condition
                         ,iv_token_name6   => cv_msg_10051_token_6
                         ,iv_token_value6  => in_stock_quantity
                         ,iv_token_name7   => cv_msg_10051_token_7
                         ,iv_token_value7  => in_shipping_pace
                         ,iv_token_name8   => cv_msg_10051_token_8
                         ,iv_token_value8  => ROUND(ln_stock_days, 2)
                         ,iv_token_name9   => cv_msg_10051_token_9
                         ,iv_token_value9  => in_supplies_quantity
                         ,iv_token_name10  => cv_msg_10051_token_10
                         ,iv_token_value10 => TO_CHAR(id_manufacture_date, cv_date_format)
                       );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => gv_log_buffer
      );
    END IF;
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
  END put_log_level;
--
  /**********************************************************************************
   * Procedure Name   : entry_xwypo
   * Description      : 横持計画出力ワークテーブル登録(B-25)
   ***********************************************************************************/
  PROCEDURE entry_xwypo(
    iv_supply_status IN     VARCHAR2,       --   ステータス
    i_xwypo_rec      IN     xxcop_wk_yoko_plan_output%ROWTYPE,
    ov_errbuf        OUT    VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT    VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg        OUT    VARCHAR2        --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'entry_xwypo'; -- プログラム名
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
    l_xwypo_rec               xxcop_wk_yoko_plan_output%ROWTYPE;
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
--    --デバックメッセージ出力
--    xxcop_common_pkg.put_debug_message(
--       iov_debug_mode => gv_debug_mode
--      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
--                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
--    );
--
    --初期化
    l_xwypo_rec := NULL;
--
    BEGIN
      IF (iv_supply_status = cv_complete) THEN
        --移動先倉庫のロット別バランス計画数が1以上ある場合
        IF (i_xwypo_rec.plan_lot_quantity > 0) THEN
          --横持計画手持在庫テーブルに登録
          INSERT INTO xxcop_wk_yoko_plan_output VALUES i_xwypo_rec;
        END IF;
      ELSE
        --横持計画手持在庫テーブルに登録
        INSERT INTO xxcop_wk_yoko_plan_output VALUES i_xwypo_rec;
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := SQLERRM;
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00027
                       ,iv_token_name1  => cv_msg_00027_token_1
                       ,iv_token_value1 => cv_table_xwypo
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
  END entry_xwypo;
--
  /**********************************************************************************
   * Procedure Name   : entry_xli_lot
   * Description      : 横持計画手持在庫テーブル登録(ロット計画数)(B-24)
   ***********************************************************************************/
  PROCEDURE entry_xli_lot(
    i_xliv_rec       IN     g_loct_inv_rtype,
    i_xwypo_rec      IN     xxcop_wk_yoko_plan_output%ROWTYPE,
    it_rcpt_loct_id  IN     xxcop_wk_yoko_plan_output.rcpt_loct_id%TYPE,
    ov_errbuf        OUT    VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT    VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg        OUT    VARCHAR2        --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'entry_xli_lot'; -- プログラム名
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
    ln_xli_idx                NUMBER;
    lv_simulate_flag          VARCHAR2(1);
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    l_xli_tab                 g_xli_ttype;
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
--    --デバックメッセージ出力
--    xxcop_common_pkg.put_debug_message(
--       iov_debug_mode => gv_debug_mode
--      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
--                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
--    );
--
    --初期化
    ln_xli_idx        := NULL;
    lv_simulate_flag  := NULL;
    l_xli_tab.DELETE;
--
    BEGIN
      --移動先倉庫のロット別バランス計画数が1以上ある場合、ロット在庫を取得
      IF (i_xwypo_rec.plan_lot_quantity > 0) THEN
        --擬似更新フラグの設定
        IF (i_xwypo_rec.rcpt_loct_id = it_rcpt_loct_id) THEN
          lv_simulate_flag := NULL;
        ELSE
          lv_simulate_flag := cv_simulate_yes;
        END IF;
        --移動先倉庫の入庫トランザクションを横持計画手持在庫テーブルコレクション型に格納
        ln_xli_idx := 1;
        l_xli_tab(ln_xli_idx).transaction_id          := gn_transaction_id;
        l_xli_tab(ln_xli_idx).loct_id                 := i_xwypo_rec.rcpt_loct_id;
        l_xli_tab(ln_xli_idx).loct_code               := i_xwypo_rec.rcpt_loct_code;
        l_xli_tab(ln_xli_idx).item_id                 := i_xwypo_rec.item_id;
        l_xli_tab(ln_xli_idx).item_no                 := i_xwypo_rec.item_no;
        l_xli_tab(ln_xli_idx).lot_id                  := i_xliv_rec.lot_id;
        l_xli_tab(ln_xli_idx).lot_no                  := i_xliv_rec.lot_no;
        l_xli_tab(ln_xli_idx).manufacture_date        := i_xliv_rec.manufacture_date;
        l_xli_tab(ln_xli_idx).expiration_date         := i_xliv_rec.expiration_date;
        l_xli_tab(ln_xli_idx).unique_sign             := i_xliv_rec.unique_sign;
        l_xli_tab(ln_xli_idx).lot_status              := i_xliv_rec.lot_status;
        l_xli_tab(ln_xli_idx).loct_onhand             := i_xwypo_rec.plan_lot_quantity;
        l_xli_tab(ln_xli_idx).schedule_date           := i_xwypo_rec.receipt_date;
        l_xli_tab(ln_xli_idx).shipment_date           := cd_lower_limit_date;
        l_xli_tab(ln_xli_idx).transaction_type        := cv_xli_type_lq;
        l_xli_tab(ln_xli_idx).simulate_flag           := lv_simulate_flag;
        l_xli_tab(ln_xli_idx).created_by              := cn_created_by;
        l_xli_tab(ln_xli_idx).creation_date           := cd_creation_date;
        l_xli_tab(ln_xli_idx).last_updated_by         := cn_last_updated_by;
        l_xli_tab(ln_xli_idx).last_update_date        := cd_last_update_date;
        l_xli_tab(ln_xli_idx).last_update_login       := cn_last_update_login;
        l_xli_tab(ln_xli_idx).request_id              := cn_request_id;
        l_xli_tab(ln_xli_idx).program_application_id  := cn_program_application_id;
        l_xli_tab(ln_xli_idx).program_id              := cn_program_id;
        l_xli_tab(ln_xli_idx).program_update_date     := cd_program_update_date;
--
        --移動元倉庫の出庫トランザクションを横持計画手持在庫テーブルコレクション型に格納
        ln_xli_idx := 2;
        l_xli_tab(ln_xli_idx).transaction_id          := gn_transaction_id;
        l_xli_tab(ln_xli_idx).loct_id                 := i_xwypo_rec.ship_loct_id;
        l_xli_tab(ln_xli_idx).loct_code               := i_xwypo_rec.ship_loct_code;
        l_xli_tab(ln_xli_idx).item_id                 := i_xwypo_rec.item_id;
        l_xli_tab(ln_xli_idx).item_no                 := i_xwypo_rec.item_no;
        l_xli_tab(ln_xli_idx).lot_id                  := i_xliv_rec.lot_id;
        l_xli_tab(ln_xli_idx).lot_no                  := i_xliv_rec.lot_no;
        l_xli_tab(ln_xli_idx).manufacture_date        := i_xliv_rec.manufacture_date;
        l_xli_tab(ln_xli_idx).expiration_date         := i_xliv_rec.expiration_date;
        l_xli_tab(ln_xli_idx).unique_sign             := i_xliv_rec.unique_sign;
        l_xli_tab(ln_xli_idx).lot_status              := i_xliv_rec.lot_status;
        l_xli_tab(ln_xli_idx).loct_onhand             := i_xwypo_rec.plan_lot_quantity * -1;
        l_xli_tab(ln_xli_idx).schedule_date           := i_xwypo_rec.shipping_date;
        l_xli_tab(ln_xli_idx).shipment_date           := cd_lower_limit_date;
        l_xli_tab(ln_xli_idx).transaction_type        := cv_xli_type_lq;
        l_xli_tab(ln_xli_idx).simulate_flag           := lv_simulate_flag;
        l_xli_tab(ln_xli_idx).created_by              := cn_created_by;
        l_xli_tab(ln_xli_idx).creation_date           := cd_creation_date;
        l_xli_tab(ln_xli_idx).last_updated_by         := cn_last_updated_by;
        l_xli_tab(ln_xli_idx).last_update_date        := cd_last_update_date;
        l_xli_tab(ln_xli_idx).last_update_login       := cn_last_update_login;
        l_xli_tab(ln_xli_idx).request_id              := cn_request_id;
        l_xli_tab(ln_xli_idx).program_application_id  := cn_program_application_id;
        l_xli_tab(ln_xli_idx).program_id              := cn_program_id;
        l_xli_tab(ln_xli_idx).program_update_date     := cd_program_update_date;
--
        --横持前在庫数を横持計画手持在庫テーブルに登録
        FORALL ln_xli_idx in 1..l_xli_tab.COUNT
          INSERT INTO xxcop_loct_inv VALUES l_xli_tab(ln_xli_idx);
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := SQLERRM;
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00027
                       ,iv_token_name1  => cv_msg_00027_token_1
                       ,iv_token_value1 => cv_table_xli
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
  END entry_xli_lot;
--
  /**********************************************************************************
   * Procedure Name   : update_xwyl_schedule
   * Description      : 横持計画品目別代表倉庫ワークテーブル更新(B-23)
   ***********************************************************************************/
  PROCEDURE update_xwyl_schedule(
    it_item_id       IN     xxcop_wk_yoko_planning.item_id%TYPE,
    i_ship_rec       IN     g_loct_rtype,   --   移動元倉庫レコード型
    i_xwypo_tab      IN     g_xwypo_ttype,  --   横持計画出力ワークテーブルコレクション型
    ov_errbuf        OUT    VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT    VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg        OUT    VARCHAR2        --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_xwyl_schedule'; -- プログラム名
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
    ln_clear_count            NUMBER;
    ln_check_count            NUMBER;
    ln_xwyl_idx               NUMBER;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    l_xwyl_rowid_tab          g_rowid_ttype;
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
    --初期化
    ln_clear_count := 0;
    ln_check_count := 0;
    ln_xwyl_idx    := 1;
    l_xwyl_rowid_tab.DELETE;
--
    BEGIN
      --計画立案フラグを初期化
      <<xwyl_row_loop>>
      FOR ln_xwyl_row_idx IN 1 .. g_xwyl_tab.COUNT LOOP
        FOR ln_xwyl_col_idx IN 1 .. g_xwyl_tab(ln_xwyl_row_idx).COUNT LOOP
          UPDATE xxcop_wk_yoko_locations xwyl
          SET   xwyl.planning_flag        = NULL
          WHERE xwyl.rowid                = g_xwyl_tab(ln_xwyl_row_idx)(ln_xwyl_col_idx)
          ;
          ln_clear_count := ln_clear_count + SQL%ROWCOUNT;
--
        END LOOP xwyl_col_loop;
      END LOOP xwyl_row_loop;
      g_xwyl_tab.DELETE;
--
      --移動元倉庫＝代表倉庫の計画立案フラグ、計画日を更新
      UPDATE xxcop_wk_yoko_locations xwyl
      SET   xwyl.planning_flag        = cv_inc_loct
           ,xwyl.schedule_date        = i_ship_rec.target_date
      WHERE xwyl.transaction_id       = gn_transaction_id
        AND xwyl.request_id           = cn_request_id
        AND xwyl.frq_loct_id          = i_ship_rec.loct_id
        AND xwyl.item_id              = it_item_id
      RETURNING xwyl.ROWID
      BULK COLLECT INTO l_xwyl_rowid_tab
      ;
      ln_check_count := ln_check_count + SQL%ROWCOUNT;
      IF (l_xwyl_rowid_tab.COUNT > 0) THEN
        g_xwyl_tab(ln_xwyl_idx) := l_xwyl_rowid_tab;
        ln_xwyl_idx := ln_xwyl_idx + 1;
      END IF;
--
      --移動元倉庫＝工場倉庫の計画立案フラグ、計画日を更新
      UPDATE xxcop_wk_yoko_locations xwyl
      SET   xwyl.planning_flag        = cv_off_loct
           ,xwyl.schedule_date        = i_ship_rec.target_date
      WHERE xwyl.transaction_id       = gn_transaction_id
        AND xwyl.request_id           = cn_request_id
        AND xwyl.frq_loct_id         <> xwyl.loct_id
        AND xwyl.loct_id              = i_ship_rec.loct_id
        AND xwyl.item_id              = it_item_id
      RETURNING xwyl.ROWID
      BULK COLLECT INTO l_xwyl_rowid_tab
      ;
      ln_check_count := ln_check_count + SQL%ROWCOUNT;
      IF (l_xwyl_rowid_tab.COUNT > 0) THEN
        g_xwyl_tab(ln_xwyl_idx) := l_xwyl_rowid_tab;
        ln_xwyl_idx := ln_xwyl_idx + 1;
      END IF;
--
      <<rcpt_loop>>
      FOR ln_rcpt_idx IN i_xwypo_tab.FIRST .. i_xwypo_tab.LAST LOOP
        --移動先倉庫＝代表倉庫の計画立案フラグ、計画日を更新
        UPDATE xxcop_wk_yoko_locations xwyl
        SET   xwyl.planning_flag        = cv_inc_loct
             ,xwyl.schedule_date        = i_xwypo_tab(ln_rcpt_idx).receipt_date
        WHERE xwyl.transaction_id       = gn_transaction_id
          AND xwyl.request_id           = cn_request_id
          AND xwyl.frq_loct_id          = i_xwypo_tab(ln_rcpt_idx).rcpt_loct_id
          AND xwyl.item_id              = it_item_id
        RETURNING xwyl.ROWID
        BULK COLLECT INTO l_xwyl_rowid_tab
        ;
        ln_check_count := ln_check_count + SQL%ROWCOUNT;
        IF (l_xwyl_rowid_tab.COUNT > 0) THEN
          g_xwyl_tab(ln_xwyl_idx) := l_xwyl_rowid_tab;
          ln_xwyl_idx := ln_xwyl_idx + 1;
        END IF;
        --移動先倉庫＝工場倉庫の計画立案フラグ、計画日を更新
        UPDATE xxcop_wk_yoko_locations xwyl
        SET   xwyl.planning_flag        = cv_off_loct
             ,xwyl.schedule_date        = i_xwypo_tab(ln_rcpt_idx).receipt_date
        WHERE xwyl.transaction_id       = gn_transaction_id
          AND xwyl.request_id           = cn_request_id
          AND xwyl.frq_loct_id         <> xwyl.loct_id
          AND xwyl.loct_id              = i_xwypo_tab(ln_rcpt_idx).rcpt_loct_id
          AND xwyl.item_id              = it_item_id
        RETURNING xwyl.ROWID
        BULK COLLECT INTO l_xwyl_rowid_tab
        ;
        ln_check_count := ln_check_count + SQL%ROWCOUNT;
        IF (l_xwyl_rowid_tab.COUNT > 0) THEN
          g_xwyl_tab(ln_xwyl_idx) := l_xwyl_rowid_tab;
          ln_xwyl_idx := ln_xwyl_idx + 1;
        END IF;
      END LOOP rcpt_loop;
--
      --デバックメッセージ出力(対象倉庫件数)
      xxcop_common_pkg.put_debug_message(
         iov_debug_mode => gv_debug_mode
        ,iv_value       => cv_indent_2 || cv_prg_name || ':'
                        || 'xwyl_update(COUNT):'
                        || ln_clear_count  || ','
                        || ln_check_count  || ','
      );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := SQLERRM;
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00027
                       ,iv_token_name1  => cv_msg_00027_token_1
                       ,iv_token_value1 => cv_table_xwyl
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
  END update_xwyl_schedule;
--
  /**********************************************************************************
   * Procedure Name   : entry_xli_balance
   * Description      : 横持計画手持在庫テーブル登録(バランス計画数)(B-22)
   ***********************************************************************************/
  PROCEDURE entry_xli_balance(
    it_loct_id                 IN     xxcop_loct_inv.loct_id%TYPE,
    it_loct_code               IN     xxcop_loct_inv.loct_code%TYPE,
    it_item_id                 IN     xxcop_loct_inv.item_id%TYPE,
    it_item_no                 IN     xxcop_loct_inv.item_no%TYPE,
    it_schedule_date           IN     xxcop_loct_inv.schedule_date%TYPE,
    it_schedule_quantity       IN     xxcop_loct_inv.loct_onhand%TYPE,
    it_freshness_class         IN     xxcop_wk_yoko_plan_output.freshness_class%TYPE,
    it_freshness_check_value   IN     xxcop_wk_yoko_plan_output.freshness_check_value%TYPE,
    it_freshness_adjust_value  IN     xxcop_wk_yoko_plan_output.freshness_adjust_value%TYPE,
    it_max_stock_days          IN     xxcop_wk_yoko_plan_output.max_stock_days%TYPE,
    it_sy_manufacture_date     IN     xxcop_wk_yoko_plan_output.sy_manufacture_date%TYPE,
    ov_errbuf                  OUT    VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode                 OUT    VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg                  OUT    VARCHAR2        --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'entry_xli_balance'; -- プログラム名
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
    ln_stock_quantity         NUMBER;
    ln_allocated_quantity     NUMBER;
    ln_xli_idx                NUMBER;
--
    -- *** ローカル・カーソル ***
    --在庫の取得
    CURSOR xliv_cur(
       in_item_id             NUMBER
      ,in_loct_id             NUMBER
    ) IS
      SELECT xliv.lot_id                                lot_id
            ,xliv.lot_no                                lot_no
            ,xliv.manufacture_date                      manufacture_date
            ,xliv.expiration_date                       expiration_date
            ,xliv.unique_sign                           unique_sign
            ,xliv.lot_status                            lot_status
            ,CASE WHEN SUM(xliv.unlimited_loct_onhand) < SUM(xliv.limited_loct_onhand)
               THEN SUM(xliv.unlimited_loct_onhand)
               ELSE SUM(xliv.limited_loct_onhand)
             END                                        loct_onhand
      FROM (
        SELECT xli.lot_id                               lot_id
              ,xli.lot_no                               lot_no
              ,xli.manufacture_date                     manufacture_date
              ,xli.expiration_date                      expiration_date
              ,xli.unique_sign                          unique_sign
              ,xli.lot_status                           lot_status
              ,xli.loct_onhand                          unlimited_loct_onhand
              ,CASE WHEN xli.schedule_date <= it_schedule_date
                 THEN xli.loct_onhand
                 ELSE 0
               END                                      limited_loct_onhand
        FROM xxcop_loct_inv          xli
            ,xxcop_wk_yoko_locations xwyl
        WHERE xli.transaction_id      = gn_transaction_id
          AND xli.request_id          = cn_request_id
          AND xli.item_id             = xwyl.item_id
          AND xli.loct_id             = xwyl.loct_id
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_MOD_START
--          AND xli.shipment_date      <= gd_allocated_date
          AND xli.shipment_date      <= GREATEST(gd_allocated_date, it_schedule_date)
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_MOD_END
          AND xwyl.transaction_id     = gn_transaction_id
          AND xwyl.request_id         = cn_request_id
          AND xwyl.item_id            = in_item_id
          AND xwyl.frq_loct_id        = in_loct_id
        UNION ALL
        SELECT xli.lot_id                               lot_id
              ,xli.lot_no                               lot_no
              ,xli.manufacture_date                     manufacture_date
              ,xli.expiration_date                      expiration_date
              ,xli.unique_sign                          unique_sign
              ,xli.lot_status                           lot_status
              ,LEAST(xli.loct_onhand, 0)                unlimited_loct_onhand
              ,CASE WHEN xli.schedule_date <= it_schedule_date
                 THEN LEAST(xli.loct_onhand, 0)
                 ELSE 0
               END                                      limited_loct_onhand
        FROM (
          SELECT xli.lot_id                               lot_id
                ,xli.lot_no                               lot_no
                ,xli.manufacture_date                     manufacture_date
                ,xli.expiration_date                      expiration_date
                ,xli.unique_sign                          unique_sign
                ,xli.lot_status                           lot_status
                ,xli.schedule_date                        schedule_date
                ,SUM(xli.loct_onhand)                     loct_onhand
          FROM xxcop_loct_inv          xli
              ,xxcop_wk_yoko_locations xwyl
          WHERE xli.transaction_id      = gn_transaction_id
            AND xli.request_id          = cn_request_id
            AND xli.item_id             = xwyl.item_id
            AND xli.loct_id             = xwyl.frq_loct_id
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_MOD_START
--            AND xli.shipment_date      <= gd_allocated_date
            AND xli.shipment_date      <= GREATEST(gd_allocated_date, it_schedule_date)
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_MOD_END
            AND xwyl.transaction_id     = gn_transaction_id
            AND xwyl.request_id         = cn_request_id
            AND xwyl.frq_loct_id       <> xwyl.loct_id
            AND xwyl.item_id            = in_item_id
            AND xwyl.loct_id            = in_loct_id
          GROUP BY xli.lot_id
                  ,xli.lot_no
                  ,xli.manufacture_date
                  ,xli.expiration_date
                  ,xli.unique_sign
                  ,xli.lot_status
                  ,xli.schedule_date
        ) xli
      ) xliv
      WHERE xxcop_common_pkg2.get_critical_date_f(
               it_freshness_class
              ,it_freshness_check_value
              ,it_freshness_adjust_value
              ,it_max_stock_days
              ,gn_freshness_buffer_days
              ,xliv.manufacture_date
              ,xliv.expiration_date
            ) >= it_schedule_date
        AND xliv.manufacture_date >= NVL(it_sy_manufacture_date, xliv.manufacture_date)
      GROUP BY xliv.lot_id
              ,xliv.lot_no
              ,xliv.manufacture_date
              ,xliv.expiration_date
              ,xliv.unique_sign
              ,xliv.lot_status
      ORDER BY xliv.manufacture_date
              ,xliv.expiration_date
              ,xliv.lot_status
    ;
--
    -- *** ローカル・レコード ***
    l_xli_tab                 g_xli_ttype;
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
--    --デバックメッセージ出力
--    xxcop_common_pkg.put_debug_message(
--       iov_debug_mode => gv_debug_mode
--      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
--                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
--    );
--
    --初期化
    ln_stock_quantity     := 0;
    ln_allocated_quantity := 0;
    ln_xli_idx            := 0;
    l_xli_tab.DELETE;
--
    BEGIN
--
--      --デバックメッセージ出力(移動数)
--      xxcop_common_pkg.put_debug_message(
--         iov_debug_mode => gv_debug_mode
--        ,iv_value       => cv_indent_2 || cv_prg_name || ':'
--                        || 'entry_loct:'
--                        || it_loct_code                               || ','
--                        || it_item_no                                 || ','
--                        || TO_CHAR(it_schedule_date, cv_date_format)  || ','
--                        || it_schedule_quantity                       || ','
--      );
--
      --移動先倉庫の鮮度条件別横持前在庫数が0以外の場合、ロット在庫を取得
      IF (it_schedule_quantity <> 0) THEN
        --鮮度条件に合致するロット別在庫数を取得
        <<xliv_loop>>
        FOR l_xliv_rec IN xliv_cur(it_item_id
                                 , it_loct_id
        ) LOOP
          BEGIN
            --ロット在庫数が0の場合、スキップ
            IF (l_xliv_rec.loct_onhand = 0) THEN
              RAISE lot_skip_expt;
            END IF;
--
            ln_xli_idx := ln_xli_idx + 1;
            --ロット在庫の引当数を計算
            ln_stock_quantity     := LEAST(it_schedule_quantity - ln_allocated_quantity, l_xliv_rec.loct_onhand);
            ln_allocated_quantity := ln_allocated_quantity + ln_stock_quantity;
--
            --横持計画手持在庫テーブルコレクション型に格納
            l_xli_tab(ln_xli_idx).transaction_id          := gn_transaction_id;
            l_xli_tab(ln_xli_idx).loct_id                 := it_loct_id;
            l_xli_tab(ln_xli_idx).loct_code               := it_loct_code;
            l_xli_tab(ln_xli_idx).item_id                 := it_item_id;
            l_xli_tab(ln_xli_idx).item_no                 := it_item_no;
            l_xli_tab(ln_xli_idx).lot_id                  := l_xliv_rec.lot_id;
            l_xli_tab(ln_xli_idx).lot_no                  := l_xliv_rec.lot_no;
            l_xli_tab(ln_xli_idx).manufacture_date        := l_xliv_rec.manufacture_date;
            l_xli_tab(ln_xli_idx).expiration_date         := l_xliv_rec.expiration_date;
            l_xli_tab(ln_xli_idx).unique_sign             := l_xliv_rec.unique_sign;
            l_xli_tab(ln_xli_idx).lot_status              := l_xliv_rec.lot_status;
            l_xli_tab(ln_xli_idx).loct_onhand             := ln_stock_quantity * -1;
            l_xli_tab(ln_xli_idx).schedule_date           := it_schedule_date;
            l_xli_tab(ln_xli_idx).shipment_date           := cd_lower_limit_date;
            l_xli_tab(ln_xli_idx).transaction_type        := cv_xli_type_bq;
            l_xli_tab(ln_xli_idx).simulate_flag           := cv_simulate_yes;
            l_xli_tab(ln_xli_idx).created_by              := cn_created_by;
            l_xli_tab(ln_xli_idx).creation_date           := cd_creation_date;
            l_xli_tab(ln_xli_idx).last_updated_by         := cn_last_updated_by;
            l_xli_tab(ln_xli_idx).last_update_date        := cd_last_update_date;
            l_xli_tab(ln_xli_idx).last_update_login       := cn_last_update_login;
            l_xli_tab(ln_xli_idx).request_id              := cn_request_id;
            l_xli_tab(ln_xli_idx).program_application_id  := cn_program_application_id;
            l_xli_tab(ln_xli_idx).program_id              := cn_program_id;
            l_xli_tab(ln_xli_idx).program_update_date     := cd_program_update_date;
--
            --鮮度条件別在庫数の合計が横持前在庫を超えた場合、終了
            IF (it_schedule_quantity <= ln_allocated_quantity) THEN
              EXIT xliv_loop;
            END IF;
          EXCEPTION
            WHEN lot_skip_expt THEN
              NULL;
          END;
        END LOOP xliv_loop;
        --横持前在庫数を横持計画手持在庫テーブルに登録
        FORALL ln_xli_idx in 1..l_xli_tab.COUNT
          INSERT INTO xxcop_loct_inv VALUES l_xli_tab(ln_xli_idx);
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := SQLERRM;
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00027
                       ,iv_token_name1  => cv_msg_00027_token_1
                       ,iv_token_value1 => cv_table_xli
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
  END entry_xli_balance;
--
  /**********************************************************************************
   * Procedure Name   : entry_supply_failed
   * Description      : 横持計画出力ワークテーブル登録(計画不可)(B-21)
   ***********************************************************************************/
  PROCEDURE entry_supply_failed(
    i_rcpt_rec       IN     g_loct_rtype,   --   移動先倉庫レコード型
    io_xwypo_tab     IN OUT g_xwypo_ttype,  --   横持計画出力ワークテーブルコレクション型
    ov_errbuf        OUT    VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT    VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg        OUT    VARCHAR2        --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'entry_supply_failed'; -- プログラム名
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
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
    );
--
    <<xwypo_loop>>
    FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
      IF (i_rcpt_rec.loct_id = io_xwypo_tab(ln_xwypo_idx).rcpt_loct_id) THEN
        IF    (io_xwypo_tab(ln_xwypo_idx).plan_lot_quantity = 0)
          AND (io_xwypo_tab(ln_xwypo_idx).before_stock < io_xwypo_tab(ln_xwypo_idx).shipping_pace
                                                       * io_xwypo_tab(ln_xwypo_idx).max_stock_days)
        THEN
          --バランス計算で補充可能数が不足しているため、
          --移動元倉庫から移動先倉庫に移動が不可能な場合
          --デバックメッセージ出力
          xxcop_common_pkg.put_debug_message(
             iov_debug_mode => gv_debug_mode
            ,iv_value       => cv_indent_2 || cv_prg_name || ':'
                            || 'not_alloc_lot:'
                            || TO_CHAR(gd_planning_date, cv_date_format)                        || ','
                            || TO_CHAR(io_xwypo_tab(ln_xwypo_idx).receipt_date, cv_date_format) || ','
                            || io_xwypo_tab(ln_xwypo_idx).item_no                               || ','
                            || io_xwypo_tab(ln_xwypo_idx).rcpt_loct_code                        || ','
                            || io_xwypo_tab(ln_xwypo_idx).freshness_condition                   || ','
          );
          --ロット情報のクリア
          io_xwypo_tab(ln_xwypo_idx).manufacture_date := NULL;
          io_xwypo_tab(ln_xwypo_idx).lot_status       := NULL;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_ADD_START
          io_xwypo_tab(ln_xwypo_idx).before_lot_stock := io_xwypo_tab(ln_xwypo_idx).before_stock;
          io_xwypo_tab(ln_xwypo_idx).after_lot_stock  := io_xwypo_tab(ln_xwypo_idx).after_stock;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_ADD_END
          -- ===============================
          -- B-25．横持計画出力ワークテーブル登録
          -- ===============================
          entry_xwypo(
             iv_supply_status           => cv_failed
            ,i_xwypo_rec                => io_xwypo_tab(ln_xwypo_idx)
            ,ov_errbuf                  => lv_errbuf
            ,ov_retcode                 => lv_retcode
            ,ov_errmsg                  => lv_errmsg
          );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_api_expt;
          END IF;
        END IF;
      END IF;
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
  END entry_supply_failed;
--
  /**********************************************************************************
   * Procedure Name   : proc_lot_quantity
   * Description      : 計画ロットの決定(B-20)
   ***********************************************************************************/
  PROCEDURE proc_lot_quantity(
    i_item_rec              IN     g_item_rtype,   --   品目情報レコード型
    i_ship_rec              IN     g_loct_rtype,   --   移動元倉庫レコード型
    i_rcpt_rec              IN     g_loct_rtype,   --   移動先倉庫レコード型
    it_sy_manufacture_date  IN     xxcop_wk_yoko_plan_output.sy_manufacture_date%TYPE,
    io_gbqt_tab             IN OUT g_bq_ttype,     --   バランス横持計画コレクション型
    io_xwypo_tab            IN OUT g_xwypo_ttype,  --   横持計画出力ワークテーブルコレクション型
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_ADD_START
    ov_stock_result            OUT VARCHAR2,       --   ロットバランスの計画ステータス
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_ADD_END
    ov_errbuf               OUT    VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode              OUT    VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg               OUT    VARCHAR2        --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_lot_quantity'; -- プログラム名
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
    ln_lot_quantity           NUMBER;         --ロット在庫数(倉庫別)
    ln_lot_freshness_quantity NUMBER;         --鮮度条件別ロット在庫数(出荷ペースで按分した結果)
    ln_shipping_pace          NUMBER;         --出荷ペースの合計(倉庫別)
    ln_balance_quantity       NUMBER;         --ロット別バランス計画数の合計(倉庫別)
--
    ln_total_lot_quantity     NUMBER;         --ロット在庫数(製造年月日合計)
    ln_total_shipping_pace    NUMBER;         --出荷ペースの合計(製造年月日合計)
    ln_surpluses_quantity     NUMBER;         --移動元倉庫の余剰在庫数
    ln_lot_supplies_quantity  NUMBER;         --補充可能数(製造年月日合計)
    ln_div_quantity           NUMBER;         --按分在庫数
    ln_adjust_quantity        NUMBER;         --ロット過不足数
    ln_plan_lot_quantity      NUMBER;         --ロット計画数合計
    ln_require_quantity       NUMBER;         --補充要求数
    ln_require_shipping_pace  NUMBER;         --出荷ペースの合計(補充要求数)
    ln_supplies_quantity      NUMBER;         --補充可能数(補充要求数按分計算)
    ln_lot_count              NUMBER;         --同一ロットの件数
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_ADD_START
    ln_condition_count        NUMBER;         --ロットが鮮度条件に合致した件数
    ln_condition_idx          NUMBER;         --鮮度条件に合致した鮮度条件のINDEX
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_ADD_END
    lv_stock_proc_flag        VARCHAR2(1);
    lv_stock_filled_flag      VARCHAR2(1);
    ln_filled_quantity        NUMBER;         --鮮度条件に引当されたロット在庫数合計
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_ADD_START
    ln_max_filled_count       NUMBER;         --計画数(最大)まで補充した鮮度条件の件数
    ln_bal_filled_count       NUMBER;         --計画数(バランス)まで補充した鮮度条件の件数
    ln_sy_stocked_quantity    NUMBER;         --特別横持計画の移動数合計(更新値)
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_ADD_END
--
    -- *** ローカル・カーソル ***
    --在庫の取得
    CURSOR xliv_cur(
       in_item_id             NUMBER
    ) IS
      SELECT xliv.lot_id                                lot_id
            ,xliv.lot_no                                lot_no
            ,xliv.manufacture_date                      manufacture_date
            ,xliv.expiration_date                       expiration_date
            ,xliv.unique_sign                           unique_sign
            ,xliv.lot_status                            lot_status
            ,CASE WHEN SUM(xliv.unlimited_loct_onhand) < SUM(xliv.limited_loct_onhand)
               THEN SUM(xliv.unlimited_loct_onhand)
               ELSE SUM(xliv.limited_loct_onhand)
             END                                        loct_onhand
            ,xliv.loct_id                               loct_id
            ,GROUPING_ID(xliv.lot_id
                        ,xliv.lot_no
                        ,xliv.manufacture_date
                        ,xliv.expiration_date
                        ,xliv.unique_sign
                        ,xliv.lot_status
                        ,xliv.loct_id
             )                                          record_class
      FROM (
        SELECT /*+ LEADING(xwyl) */
               xwyl.frq_loct_id                         loct_id
              ,xwyl.frq_loct_code                       loct_code
              ,xli.lot_id                               lot_id
              ,xli.lot_no                               lot_no
              ,xli.manufacture_date                     manufacture_date
              ,xli.expiration_date                      expiration_date
              ,xli.unique_sign                          unique_sign
              ,xli.lot_status                           lot_status
              ,xli.loct_onhand                          unlimited_loct_onhand
              ,CASE WHEN xli.schedule_date <= xwyl.schedule_date
                 THEN xli.loct_onhand
                 ELSE 0
               END                                      limited_loct_onhand
        FROM xxcop_loct_inv          xli
            ,xxcop_wk_yoko_locations xwyl
        WHERE xli.transaction_id      = gn_transaction_id
          AND xli.request_id          = cn_request_id
          AND xli.item_id             = xwyl.item_id
          AND xli.loct_id             = xwyl.loct_id
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_MOD_START
--          AND xli.shipment_date      <= gd_allocated_date
          AND xli.shipment_date      <= GREATEST(gd_allocated_date, xwyl.schedule_date)
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_MOD_END
          AND xli.transaction_type  NOT IN (cv_xli_type_bq)
          AND xwyl.transaction_id     = gn_transaction_id
          AND xwyl.request_id         = cn_request_id
          AND xwyl.item_id            = in_item_id
          AND xwyl.planning_flag      = cv_inc_loct
        UNION ALL
        SELECT xli.loct_id                              loct_id
              ,xli.loct_code                            loct_code
              ,xli.lot_id                               lot_id
              ,xli.lot_no                               lot_no
              ,xli.manufacture_date                     manufacture_date
              ,xli.expiration_date                      expiration_date
              ,xli.unique_sign                          unique_sign
              ,xli.lot_status                           lot_status
              ,LEAST(xli.loct_onhand, 0)                unlimited_loct_onhand
              ,CASE WHEN xli.schedule_date <= xli.target_date
                 THEN LEAST(xli.loct_onhand, 0)
                 ELSE 0
               END                                      limited_loct_onhand
        FROM (
          SELECT /*+ LEADING(xwyl) */
                 xwyl.loct_id                           loct_id
                ,xwyl.loct_code                         loct_code
                ,xli.lot_id                             lot_id
                ,xli.lot_no                             lot_no
                ,xli.manufacture_date                   manufacture_date
                ,xli.expiration_date                    expiration_date
                ,xli.unique_sign                        unique_sign
                ,xli.lot_status                         lot_status
                ,xli.schedule_date                      schedule_date
                ,xwyl.schedule_date                     target_date
                ,SUM(xli.loct_onhand)                   loct_onhand
          FROM xxcop_loct_inv          xli
              ,xxcop_wk_yoko_locations xwyl
          WHERE xli.transaction_id      = gn_transaction_id
            AND xli.request_id          = cn_request_id
            AND xli.item_id             = xwyl.item_id
            AND xli.loct_id             = xwyl.frq_loct_id
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_MOD_START
--            AND xli.shipment_date      <= gd_allocated_date
            AND xli.shipment_date      <= GREATEST(gd_allocated_date, xwyl.schedule_date)
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_MOD_END
            AND xli.transaction_type  NOT IN (cv_xli_type_bq)
            AND xwyl.transaction_id     = gn_transaction_id
            AND xwyl.request_id         = cn_request_id
            AND xwyl.frq_loct_id       <> xwyl.loct_id
            AND xwyl.item_id            = in_item_id
            AND xwyl.planning_flag      = cv_off_loct
          GROUP BY xwyl.loct_id
                  ,xwyl.loct_code
                  ,xli.lot_id
                  ,xli.lot_no
                  ,xli.manufacture_date
                  ,xli.expiration_date
                  ,xli.unique_sign
                  ,xli.lot_status
                  ,xli.schedule_date
                  ,xwyl.schedule_date
        ) xli
      ) xliv
      GROUP BY ROLLUP(
         xliv.lot_id
        ,xliv.lot_no
        ,xliv.manufacture_date
        ,xliv.expiration_date
        ,xliv.unique_sign
        ,xliv.lot_status
        ,xliv.loct_id
      )
      HAVING GROUPING_ID(
                xliv.lot_id
               ,xliv.lot_no
               ,xliv.manufacture_date
               ,xliv.expiration_date
               ,xliv.unique_sign
               ,xliv.lot_status
               ,xliv.loct_id
             ) < 2
      ORDER BY xliv.manufacture_date
              ,xliv.unique_sign
              ,xliv.expiration_date
              ,xliv.loct_id
    ;
--
    -- *** ローカル・レコード ***
    l_xliv_rec                g_loct_inv_rtype;
    l_ship_lot_tab            g_lot_ttype;
    l_rcpt_lot_tab            g_lot_ttype;
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
    --初期化
    ln_lot_quantity           := NULL;
    ln_lot_freshness_quantity := NULL;
    ln_shipping_pace          := NULL;
    ln_balance_quantity       := NULL;
    ln_total_lot_quantity     := NULL;
    ln_total_shipping_pace    := NULL;
    ln_surpluses_quantity     := NULL;
    ln_lot_supplies_quantity  := NULL;
    ln_div_quantity           := NULL;
    ln_adjust_quantity        := NULL;
    ln_plan_lot_quantity      := NULL;
    ln_require_quantity       := NULL;
    ln_require_shipping_pace  := NULL;
    ln_supplies_quantity      := NULL;
    ln_lot_count              := NULL;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_ADD_START
    ln_condition_count        := NULL;
    ln_condition_idx          := NULL;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_ADD_END
    lv_stock_proc_flag        := NULL;
    lv_stock_filled_flag      := NULL;
    ln_filled_quantity        := NULL;
    l_xliv_rec                := NULL;
    l_ship_lot_tab.DELETE;
    l_rcpt_lot_tab.DELETE;
--
    --移動元、移動先倉庫の計画立案FLAG、計画日を更新
    -- ===============================
    -- B-23．横持計画品目別代表倉庫ワークテーブル更新
    -- ===============================
    update_xwyl_schedule(
       it_item_id        => i_item_rec.item_id
      ,i_ship_rec        => i_ship_rec
      ,i_xwypo_tab       => io_xwypo_tab
      ,ov_errbuf         => lv_errbuf
      ,ov_retcode        => lv_retcode
      ,ov_errmsg         => lv_errmsg
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    --初期化
    ln_lot_count := 0;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_ADD_START
    ln_condition_count        := 0;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_ADD_END
    ln_lot_supplies_quantity  := 0;
    ln_surpluses_quantity     := 0;
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_ADD_START
    ln_max_filled_count       := 0;
    ln_bal_filled_count       := 0;
    ov_stock_result           := cv_failed;
    ln_sy_stocked_quantity    := NULL;
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_ADD_END
--
    --移動元倉庫、移動先倉庫のロット別在庫数を取得
    OPEN xliv_cur(i_item_rec.item_id);
    <<xliv_loop>>
    LOOP
      FETCH xliv_cur INTO l_xliv_rec;
      EXIT WHEN xliv_cur%NOTFOUND;
      BEGIN
--
        --デバックメッセージ出力(ロット)
        xxcop_common_pkg.put_debug_message(
           iov_debug_mode => gv_debug_mode
          ,iv_value       => cv_indent_2 || cv_prg_name || ':'
                          || 'xliv_cur:'
                          || '(' || l_xliv_rec.record_class || ')'                || ','
                          || l_xliv_rec.loct_id                                   || ','
                          || l_xliv_rec.loct_onhand                               || ','
                          || l_xliv_rec.lot_status                                || ','
                          || TO_CHAR(l_xliv_rec.manufacture_date, cv_date_format) || ','
                          || TO_CHAR(l_xliv_rec.expiration_date , cv_date_format) || ','
                          || l_xliv_rec.lot_no                                    || ','
                          || ln_condition_count                                   || ','
        );
--
        IF (l_xliv_rec.record_class = 0) THEN
          --明細レコード
          --ロット在庫数が0の場合、スキップ
          IF (l_xliv_rec.loct_onhand = 0) THEN
            RAISE lot_skip_expt;
          END IF;
--
          --ロットが鮮度条件に合致するかチェック
          IF (ln_lot_count = 0) THEN
            --初期化
            --ロットが移動元倉庫の鮮度条件に合致するかチェック
            <<ship_critical_date_loop>>
            FOR ln_ship_idx IN io_gbqt_tab.FIRST .. io_gbqt_tab.LAST LOOP
              --製造年月日違いのロットで初期化
              l_ship_lot_tab(ln_ship_idx).lot_quantity       := NULL;
              l_ship_lot_tab(ln_ship_idx).freshness_quantity := NVL(l_ship_lot_tab(ln_ship_idx).freshness_quantity, 0);
              l_ship_lot_tab(ln_ship_idx).plan_bal_quantity  := NVL(l_ship_lot_tab(ln_ship_idx).plan_bal_quantity, 0);
              l_ship_lot_tab(ln_ship_idx).adjust_quantity    := NVL(l_ship_lot_tab(ln_ship_idx).adjust_quantity, 0);
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_DEL_START
--              --鮮度条件別在庫が横持後在庫まで引当されていない場合、フラグをYESにする
--              IF (io_gbqt_tab(ln_ship_idx).after_stock > l_ship_lot_tab(ln_ship_idx).freshness_quantity) THEN
--                l_ship_lot_tab(ln_ship_idx).stock_proc_flag  := cv_planning_yes;
--                l_ship_lot_tab(ln_ship_idx).adjust_proc_flag := cv_planning_yes;
--              ELSE
--                l_ship_lot_tab(ln_ship_idx).stock_proc_flag  := cv_planning_no;
--                l_ship_lot_tab(ln_ship_idx).adjust_proc_flag := cv_planning_no;
--                l_ship_lot_tab(ln_ship_idx).adjust_quantity  := 0;
--              END IF;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_DEL_END
              --鮮度条件基準日取得関数
              l_ship_lot_tab(ln_ship_idx).critical_date := (
                xxcop_common_pkg2.get_critical_date_f(
                   iv_freshness_class        => io_gbqt_tab(ln_ship_idx).freshness_class
                  ,in_freshness_check_value  => io_gbqt_tab(ln_ship_idx).freshness_check_value
                  ,in_freshness_adjust_value => io_gbqt_tab(ln_ship_idx).freshness_adjust_value
                  ,in_max_stock_days         => io_gbqt_tab(ln_ship_idx).max_stock_days
                  ,in_freshness_buffer_days  => gn_freshness_buffer_days
                  ,id_manufacture_date       => l_xliv_rec.manufacture_date
                  ,id_expiration_date        => l_xliv_rec.expiration_date
                )
              );
              --鮮度条件が一致しない場合は対象外
              IF (i_ship_rec.target_date > l_ship_lot_tab(ln_ship_idx).critical_date) THEN
                l_ship_lot_tab(ln_ship_idx).stock_proc_flag  := cv_planning_no;
                l_ship_lot_tab(ln_ship_idx).adjust_proc_flag := cv_planning_no;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_ADD_START
              ELSE
                l_ship_lot_tab(ln_ship_idx).stock_proc_flag  := cv_planning_yes;
                l_ship_lot_tab(ln_ship_idx).adjust_proc_flag := cv_planning_yes;
                ln_condition_count := ln_condition_count + 1;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_ADD_END
              END IF;
--
              --デバックメッセージ出力(初期化)
              xxcop_common_pkg.put_debug_message(
                 iov_debug_mode => gv_debug_mode
                ,iv_value       => cv_indent_4 || cv_prg_name || ':'
                                || 'proc_lot_init(ship):'
                                || i_ship_rec.loct_code                                 || ','
                                || io_gbqt_tab(ln_ship_idx).freshness_condition         || ','
                                || NVL(l_ship_lot_tab(ln_ship_idx).lot_quantity, -999)  || ','
                                || l_ship_lot_tab(ln_ship_idx).freshness_quantity       || ','
                                || l_ship_lot_tab(ln_ship_idx).plan_bal_quantity        || ','
                                || l_ship_lot_tab(ln_ship_idx).adjust_quantity          || ','
                                || l_ship_lot_tab(ln_ship_idx).stock_proc_flag          || ','
                                || l_ship_lot_tab(ln_ship_idx).adjust_proc_flag         || ','
                                || TO_CHAR(l_ship_lot_tab(ln_ship_idx).critical_date, cv_date_format) || ','
              );
--
            END LOOP ship_critical_date_loop;
--
            --ロットが移動先倉庫の鮮度条件に合致するかチェック
            <<rcpt_critical_date_loop>>
            FOR ln_rcpt_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
              --製造年月日違いのロットで初期化
              l_rcpt_lot_tab(ln_rcpt_idx).lot_quantity       := NULL;
              l_rcpt_lot_tab(ln_rcpt_idx).freshness_quantity := NVL(l_rcpt_lot_tab(ln_rcpt_idx).freshness_quantity, 0);
              l_rcpt_lot_tab(ln_rcpt_idx).plan_bal_quantity  := NVL(l_rcpt_lot_tab(ln_rcpt_idx).plan_bal_quantity, 0);
              l_rcpt_lot_tab(ln_rcpt_idx).adjust_quantity    := NVL(l_rcpt_lot_tab(ln_rcpt_idx).adjust_quantity, 0);
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_DEL_START
--              --鮮度条件別在庫が横持前在庫まで引当されていない場合、フラグをYESにする
--              IF (io_xwypo_tab(ln_rcpt_idx).before_stock <> l_rcpt_lot_tab(ln_rcpt_idx).freshness_quantity) THEN
--                l_rcpt_lot_tab(ln_rcpt_idx).stock_proc_flag  := cv_planning_yes;
--              ELSE
--                l_rcpt_lot_tab(ln_rcpt_idx).stock_proc_flag  := cv_planning_no;
--              END IF;
--              --鮮度条件別在庫が横持前在庫まで引当されていない場合、または
--              --ロット別計画数がバランス計画数まで引当されていない場合、フラグをYESにする
--              IF   (io_xwypo_tab(ln_rcpt_idx).before_stock     <> l_rcpt_lot_tab(ln_rcpt_idx).freshness_quantity)
--                OR (io_xwypo_tab(ln_rcpt_idx).plan_bal_quantity > l_rcpt_lot_tab(ln_rcpt_idx).plan_bal_quantity) THEN
--                l_rcpt_lot_tab(ln_rcpt_idx).adjust_proc_flag := cv_planning_yes;
--              ELSE
--                l_rcpt_lot_tab(ln_rcpt_idx).adjust_proc_flag := cv_planning_no;
--                l_rcpt_lot_tab(ln_rcpt_idx).adjust_quantity  := 0;
--              END IF;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_DEL_END
              io_xwypo_tab(ln_rcpt_idx).plan_lot_quantity    := 0;
              --鮮度条件基準日取得関数
              l_rcpt_lot_tab(ln_rcpt_idx).critical_date := (
                xxcop_common_pkg2.get_critical_date_f(
                   iv_freshness_class        => io_xwypo_tab(ln_rcpt_idx).freshness_class
                  ,in_freshness_check_value  => io_xwypo_tab(ln_rcpt_idx).freshness_check_value
                  ,in_freshness_adjust_value => io_xwypo_tab(ln_rcpt_idx).freshness_adjust_value
                  ,in_max_stock_days         => io_xwypo_tab(ln_rcpt_idx).max_stock_days
                  ,in_freshness_buffer_days  => gn_freshness_buffer_days
                  ,id_manufacture_date       => l_xliv_rec.manufacture_date
                  ,id_expiration_date        => l_xliv_rec.expiration_date
                )
              );
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_ADD_START
              --鮮度条件が一致しない場合は対象外
              IF (io_xwypo_tab(ln_rcpt_idx).receipt_date > l_rcpt_lot_tab(ln_rcpt_idx).critical_date) THEN
                l_rcpt_lot_tab(ln_rcpt_idx).stock_proc_flag  := cv_planning_no;
                l_rcpt_lot_tab(ln_rcpt_idx).adjust_proc_flag := cv_planning_no;
              ELSE
                --鮮度条件別在庫が横持前在庫まで引当されていない場合、フラグをYESにする
                --横持前在庫が正値の場合、横持前在庫＞鮮度条件別在庫まで
                --横持前在庫が負値の場合、横持前在庫＜鮮度条件別在庫まで
                IF ((io_xwypo_tab(ln_rcpt_idx).before_stock > 0)
                    AND (io_xwypo_tab(ln_rcpt_idx).before_stock > l_rcpt_lot_tab(ln_rcpt_idx).freshness_quantity))
                  OR ((io_xwypo_tab(ln_rcpt_idx).before_stock < 0)
                    AND (io_xwypo_tab(ln_rcpt_idx).before_stock < l_rcpt_lot_tab(ln_rcpt_idx).freshness_quantity))
                THEN
                  l_rcpt_lot_tab(ln_rcpt_idx).stock_proc_flag  := cv_planning_yes;
                ELSE
                  l_rcpt_lot_tab(ln_rcpt_idx).stock_proc_flag  := cv_planning_no;
                END IF;
                l_rcpt_lot_tab(ln_rcpt_idx).adjust_proc_flag := cv_planning_yes;
                ln_condition_count := ln_condition_count + 1;
              END IF;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_ADD_END
--
              --デバックメッセージ出力(初期化)
              xxcop_common_pkg.put_debug_message(
                 iov_debug_mode => gv_debug_mode
                ,iv_value       => cv_indent_4 || cv_prg_name || ':'
                                || 'proc_lot_init(rcpt):'
                                || io_xwypo_tab(ln_rcpt_idx).rcpt_loct_code             || ','
                                || io_xwypo_tab(ln_rcpt_idx).freshness_condition        || ','
                                || NVL(l_rcpt_lot_tab(ln_rcpt_idx).lot_quantity, -999)  || ','
                                || l_rcpt_lot_tab(ln_rcpt_idx).freshness_quantity       || ','
                                || l_rcpt_lot_tab(ln_rcpt_idx).plan_bal_quantity        || ','
                                || l_rcpt_lot_tab(ln_rcpt_idx).adjust_quantity          || ','
                                || l_rcpt_lot_tab(ln_rcpt_idx).stock_proc_flag          || ','
                                || l_rcpt_lot_tab(ln_rcpt_idx).adjust_proc_flag         || ','
                                || TO_CHAR(l_rcpt_lot_tab(ln_rcpt_idx).critical_date, cv_date_format) || ','
              );
--
            END LOOP rcpt_critical_date_loop;
          END IF;
          ln_lot_count := ln_lot_count + 1;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_ADD_START
          --鮮度条件に合致しない場合、スキップ
          IF (ln_condition_count = 0) THEN
            RAISE lot_skip_expt;
          END IF;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_ADD_END
--
          IF (i_ship_rec.loct_id = l_xliv_rec.loct_id) THEN
            -- ===============================
            -- 移動元倉庫のロット
            -- ===============================
            --ロット在庫を出荷ペースの比率で鮮度条件別在庫に按分
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_DEL_START
--            ln_lot_quantity := l_xliv_rec.loct_onhand;
--            lv_stock_filled_flag := cv_planning_no;
--            ln_filled_quantity   := 0;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_DEL_END
            <<ship_div_lot_stock_loop>>
            LOOP
              --初期化
              lv_stock_proc_flag  := cv_planning_yes;
              ln_shipping_pace    := 0;
              ln_balance_quantity := 0;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_MOD_START
--              ln_lot_quantity     := l_xliv_rec.loct_onhand - ln_filled_quantity;
              ln_lot_quantity     := l_xliv_rec.loct_onhand;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_MOD_END
              --鮮度条件に合致する出荷ペースを集計
              <<ship_div_lot_summary_loop>>
              FOR ln_ship_idx IN io_gbqt_tab.FIRST .. io_gbqt_tab.LAST LOOP
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_DEL_START
--                IF (lv_stock_filled_flag = cv_planning_yes)
--                  AND (l_ship_lot_tab(ln_ship_idx).stock_proc_flag = cv_planning_omit)
--                THEN
--                  l_ship_lot_tab(ln_ship_idx).stock_proc_flag := cv_planning_yes;
--                END IF;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_DEL_END
                IF (l_ship_lot_tab(ln_ship_idx).stock_proc_flag = cv_planning_yes) THEN
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_DEL_START
--                  --鮮度条件に合致した場合
--                  IF (i_ship_rec.target_date <= l_ship_lot_tab(ln_ship_idx).critical_date) THEN
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_DEL_END
                  --鮮度条件に合致した出荷ペース合計
                  ln_shipping_pace := ln_shipping_pace + io_gbqt_tab(ln_ship_idx).shipping_pace;
                  --ロット在庫数＋過不足数の合計
                  ln_lot_quantity := ln_lot_quantity + l_ship_lot_tab(ln_ship_idx).adjust_quantity;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_DEL_START
--                  ELSE
--                    l_ship_lot_tab(ln_ship_idx).stock_proc_flag := cv_planning_no;
--                  END IF;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_DEL_END
                END IF;
              END LOOP ship_div_lot_summary_loop;
              --ロットが全ての鮮度条件に合致しない場合、計算を終了
              IF (ln_shipping_pace = 0) THEN
                EXIT ship_div_lot_stock_loop;
              END IF;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_DEL_START
--              lv_stock_filled_flag := cv_planning_no;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_DEL_END
              --出荷ペースの比率で鮮度条件別在庫に按分
              <<ship_div_balance_loop>>
              FOR ln_ship_idx IN io_gbqt_tab.FIRST .. io_gbqt_tab.LAST LOOP
                IF (l_ship_lot_tab(ln_ship_idx).stock_proc_flag = cv_planning_yes) THEN
--20100107_Ver3.2_E_本稼動_00936_SCS.Goto_ADD_START
                  IF (io_gbqt_tab(ln_ship_idx).shipping_pace > 0) THEN
--20100107_Ver3.2_E_本稼動_00936_SCS.Goto_ADD_END
                    --ロット別バランス計画数の計算
                    --端数は優先順位の高い鮮度条件に引き当てる
                    ln_lot_freshness_quantity := CEIL(ln_lot_quantity
                                                    * io_gbqt_tab(ln_ship_idx).shipping_pace
                                                    / ln_shipping_pace
                                                 );
                    l_ship_lot_tab(ln_ship_idx).lot_quantity := ln_lot_freshness_quantity
                                                              - l_ship_lot_tab(ln_ship_idx).adjust_quantity;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_DEL_START
--                  --横持後在庫数が上限
--                  l_ship_lot_tab(ln_ship_idx).lot_quantity := LEAST(l_ship_lot_tab(ln_ship_idx).lot_quantity
--                                                                  , io_gbqt_tab(ln_ship_idx).after_stock
--                                                                  - l_ship_lot_tab(ln_ship_idx).freshness_quantity
--                                                              );
--                  --鮮度条件別在庫数が横持前在庫まで引当できた場合、鮮度条件1から再計算する。
--                  IF ( io_gbqt_tab(ln_ship_idx).after_stock = l_ship_lot_tab(ln_ship_idx).freshness_quantity
--                                                            + l_ship_lot_tab(ln_ship_idx).lot_quantity)
--                  THEN
--                    lv_stock_proc_flag   := cv_planning_no;
--                    lv_stock_filled_flag := cv_planning_yes;
--                    ln_filled_quantity := ln_filled_quantity + l_ship_lot_tab(ln_ship_idx).lot_quantity;
--                    l_ship_lot_tab(ln_ship_idx).stock_proc_flag := cv_planning_no;
--                    EXIT ship_div_balance_loop;
--                  END IF;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_DEL_END
                    --ロット別バランス計画数の合計
                    ln_balance_quantity := ln_balance_quantity + l_ship_lot_tab(ln_ship_idx).lot_quantity;
                    --鮮度条件別在庫に引当したロット在庫数を減算
                    ln_lot_quantity := ln_lot_quantity - ln_lot_freshness_quantity;
                    ln_shipping_pace := ln_shipping_pace - io_gbqt_tab(ln_ship_idx).shipping_pace;
                    --ロット在庫数の符号と鮮度条件別ロット在庫数の符号が違う場合、按分から除外する
                    IF (SIGN(l_xliv_rec.loct_onhand) <> SIGN(l_ship_lot_tab(ln_ship_idx).lot_quantity)) THEN
                      lv_stock_proc_flag  := cv_planning_no;
                      --鮮度条件別ロット在庫数の初期化
                      l_ship_lot_tab(ln_ship_idx).lot_quantity := 0;
                      l_ship_lot_tab(ln_ship_idx).stock_proc_flag := cv_planning_omit;
                    END IF;
--20100107_Ver3.2_E_本稼動_00936_SCS.Goto_ADD_START
                  END IF;
--20100107_Ver3.2_E_本稼動_00936_SCS.Goto_ADD_END
                END IF;
              END LOOP ship_div_balance_loop;
              IF (lv_stock_proc_flag = cv_planning_yes) THEN
                EXIT ship_div_lot_stock_loop;
              END IF;
            END LOOP ship_div_lot_stock_loop;
            --引当されていないロット在庫補数
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_MOD_START
--            ln_lot_supplies_quantity := l_xliv_rec.loct_onhand - ln_balance_quantity - ln_filled_quantity;
            ln_lot_supplies_quantity := l_xliv_rec.loct_onhand - ln_balance_quantity;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_MOD_END
--
          ELSE
            -- ===============================
            -- 移動先倉庫のロット
            -- ===============================
            --ロット在庫を出荷ペースの比率で鮮度条件別在庫に按分
            ln_lot_quantity := l_xliv_rec.loct_onhand;
            lv_stock_filled_flag := cv_planning_no;
            ln_filled_quantity   := 0;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_ADD_START
            ln_condition_idx     := NULL;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_ADD_END
            <<rcpt_div_lot_stock_loop>>
            LOOP
              --初期化
              lv_stock_proc_flag  := cv_planning_yes;
              ln_shipping_pace    := 0;
              ln_balance_quantity := 0;
              ln_lot_quantity     := l_xliv_rec.loct_onhand - ln_filled_quantity;
              --鮮度条件に合致する出荷ペースを集計
              <<rcpt_div_proc_loop>>
              FOR ln_rcpt_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
                --自倉庫のロットの場合
                IF (io_xwypo_tab(ln_rcpt_idx).rcpt_loct_id  = l_xliv_rec.loct_id) THEN
                  IF (lv_stock_filled_flag = cv_planning_yes)
                    AND (l_rcpt_lot_tab(ln_rcpt_idx).stock_proc_flag = cv_planning_omit)
                  THEN
                    l_rcpt_lot_tab(ln_rcpt_idx).stock_proc_flag := cv_planning_yes;
                  END IF;
                  IF (l_rcpt_lot_tab(ln_rcpt_idx).stock_proc_flag = cv_planning_yes) THEN
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_DEL_START
--                    --鮮度条件に合致した場合
--                    IF (io_xwypo_tab(ln_rcpt_idx).receipt_date <= l_rcpt_lot_tab(ln_rcpt_idx).critical_date) THEN
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_DEL_END
                    --鮮度条件に合致した出荷ペース合計
                    ln_shipping_pace := ln_shipping_pace + io_xwypo_tab(ln_rcpt_idx).shipping_pace;
                    --ロット在庫数＋過不足数の合計
                    ln_lot_quantity := ln_lot_quantity + l_rcpt_lot_tab(ln_rcpt_idx).adjust_quantity;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_DEL_START
--                    ELSE
--                      l_rcpt_lot_tab(ln_rcpt_idx).stock_proc_flag := cv_planning_no;
--                    END IF;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_DEL_END
                  END IF;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_ADD_START
                  --合致している鮮度条件のINDEXを保持
                  IF (l_rcpt_lot_tab(ln_rcpt_idx).adjust_proc_flag = cv_planning_yes) THEN
                    ln_condition_idx := NVL( ln_condition_idx, ln_rcpt_idx);
                  END IF;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_ADD_END
                END IF;
              END LOOP rcpt_div_proc_loop;
              --ロットが鮮度条件に合致しない場合、計算を終了
              IF (ln_shipping_pace = 0) THEN
                EXIT rcpt_div_lot_stock_loop;
              END IF;
              lv_stock_filled_flag := cv_planning_no;
              --出荷ペースの比率で鮮度条件別在庫に按分
              <<rcpt_div_balance_loop>>
              FOR ln_rcpt_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
                --自倉庫のロットの場合
                IF (io_xwypo_tab(ln_rcpt_idx).rcpt_loct_id  = l_xliv_rec.loct_id) THEN
                  IF (l_rcpt_lot_tab(ln_rcpt_idx).stock_proc_flag = cv_planning_yes) THEN
                    --ロット別バランス計画数の計算
                    --端数は優先順位の高い鮮度条件に引き当てる
                    ln_lot_freshness_quantity := CEIL(ln_lot_quantity
                                                    * io_xwypo_tab(ln_rcpt_idx).shipping_pace
                                                    / ln_shipping_pace
                                                 );
                    l_rcpt_lot_tab(ln_rcpt_idx).lot_quantity := ln_lot_freshness_quantity
                                                              - l_rcpt_lot_tab(ln_rcpt_idx).adjust_quantity;
                    --横持前在庫数が上限
                    l_rcpt_lot_tab(ln_rcpt_idx).lot_quantity := LEAST(l_rcpt_lot_tab(ln_rcpt_idx).lot_quantity
                                                                    , io_xwypo_tab(ln_rcpt_idx).before_stock
                                                                    - l_rcpt_lot_tab(ln_rcpt_idx).freshness_quantity
                                                                );
                    --鮮度条件別在庫数が横持前在庫まで引当できた場合、鮮度条件1から再計算する。
                    IF ( io_xwypo_tab(ln_rcpt_idx).before_stock = l_rcpt_lot_tab(ln_rcpt_idx).freshness_quantity
                                                                + l_rcpt_lot_tab(ln_rcpt_idx).lot_quantity)
                    THEN
                      lv_stock_proc_flag   := cv_planning_no;
                      lv_stock_filled_flag := cv_planning_yes;
                      ln_filled_quantity := ln_filled_quantity + l_rcpt_lot_tab(ln_rcpt_idx).lot_quantity;
                      l_rcpt_lot_tab(ln_rcpt_idx).stock_proc_flag := cv_planning_no;
                      EXIT rcpt_div_balance_loop;
                    END IF;
                    --ロット別バランス計画数の合計
                    ln_balance_quantity := ln_balance_quantity + l_rcpt_lot_tab(ln_rcpt_idx).lot_quantity;
                    --鮮度条件別在庫に引当したロット在庫数を減算
                    ln_lot_quantity := ln_lot_quantity - ln_lot_freshness_quantity;
                    ln_shipping_pace := ln_shipping_pace - io_xwypo_tab(ln_rcpt_idx).shipping_pace;
                    --ロット在庫数の符号と鮮度条件別ロット在庫数の符号が違う場合、按分から除外する
                    IF (SIGN(l_xliv_rec.loct_onhand) <> SIGN(l_rcpt_lot_tab(ln_rcpt_idx).lot_quantity)) THEN
                      lv_stock_proc_flag  := cv_planning_no;
                      --鮮度条件別ロット在庫数の初期化
                      l_rcpt_lot_tab(ln_rcpt_idx).lot_quantity := 0;
                      l_rcpt_lot_tab(ln_rcpt_idx).stock_proc_flag := cv_planning_omit;
                    END IF;
                  END IF;
                END IF;
              END LOOP rcpt_div_balance_loop;
              IF (lv_stock_proc_flag = cv_planning_yes) THEN
                EXIT rcpt_div_lot_stock_loop;
              END IF;
            END LOOP rcpt_div_lot_stock_loop;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_ADD_START
            --鮮度条件別在庫に案分しなかった在庫数を加算
            IF (ln_condition_idx IS NOT NULL) THEN
              l_rcpt_lot_tab(ln_condition_idx).lot_quantity := NVL(l_rcpt_lot_tab(ln_condition_idx).lot_quantity, 0)
                                                             + l_xliv_rec.loct_onhand
                                                             - ln_filled_quantity
                                                             - ln_balance_quantity;
            END IF;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_ADD_END
          END IF;
        ELSE
          --合計レコード
          --ロット在庫数が全て0の場合、スキップ
          IF (ln_lot_count = 0) THEN
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_MOD_START
--            RAISE lot_skip_expt;
            RAISE manufacture_skip_expt;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_MOD_END
          END IF;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_ADD_START
          --鮮度条件に合致しない場合、スキップ
          IF (ln_condition_count = 0) THEN
            RAISE manufacture_skip_expt;
          END IF;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_ADD_END
          -- ===============================
          -- ロット計画数の計算
          -- ===============================
          --
          -- (1) 鮮度条件に合致する出荷ペースを集計
          --
          --初期化
          ln_total_lot_quantity     := 0;
          ln_total_shipping_pace    := 0;
          ln_require_shipping_pace  := 0;
          ln_require_quantity       := 0;
          ln_plan_lot_quantity      := 0;
--
          <<ship_proc_summary_loop>>
          FOR ln_ship_idx IN io_gbqt_tab.FIRST .. io_gbqt_tab.LAST LOOP
            --鮮度条件別ロット在庫数が引当されていない場合、0をセット
            l_ship_lot_tab(ln_ship_idx).lot_quantity := NVL(l_ship_lot_tab(ln_ship_idx).lot_quantity, 0);
            IF (l_ship_lot_tab(ln_ship_idx).adjust_proc_flag = cv_planning_yes) THEN
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_DEL_START
--              --鮮度条件に合致した場合
--              IF (i_ship_rec.target_date <= l_ship_lot_tab(ln_ship_idx).critical_date) THEN
--                --横持後在庫まで引当された場合、対象外とする
--                IF (io_gbqt_tab(ln_ship_idx).after_stock > l_ship_lot_tab(ln_ship_idx).freshness_quantity
--                                                         + l_ship_lot_tab(ln_ship_idx).lot_quantity)
--                THEN
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_DEL_END
              --出荷ペースの合計を集計
              ln_total_shipping_pace := ln_total_shipping_pace + io_gbqt_tab(ln_ship_idx).shipping_pace;
              --ロット在庫数の合計を集計
              ln_total_lot_quantity := ln_total_lot_quantity + l_ship_lot_tab(ln_ship_idx).lot_quantity;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_DEL_START
--                ELSE
--                  l_ship_lot_tab(ln_ship_idx).adjust_proc_flag := cv_planning_no;
--                END IF;
--              ELSE
--                l_ship_lot_tab(ln_ship_idx).adjust_proc_flag := cv_planning_no;
--              END IF;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_DEL_END
            END IF;
          END LOOP ship_proc_summary_loop;
--
          <<rcpt_proc_summary_loop>>
          FOR ln_rcpt_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
            --鮮度条件別ロット在庫数が引当されていない場合、0をセット
            l_rcpt_lot_tab(ln_rcpt_idx).lot_quantity := NVL(l_rcpt_lot_tab(ln_rcpt_idx).lot_quantity, 0);
            IF (l_rcpt_lot_tab(ln_rcpt_idx).adjust_proc_flag = cv_planning_yes) THEN
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_DEL_START
--              --鮮度条件に合致した場合
--              IF (io_xwypo_tab(ln_rcpt_idx).receipt_date <= l_rcpt_lot_tab(ln_rcpt_idx).critical_date) THEN
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_DEL_END
              --出荷ペースの合計を集計
              ln_total_shipping_pace := ln_total_shipping_pace + io_xwypo_tab(ln_rcpt_idx).shipping_pace;
              --ロット在庫数の合計を集計
              ln_total_lot_quantity := ln_total_lot_quantity + l_rcpt_lot_tab(ln_rcpt_idx).lot_quantity;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_DEL_START
--              ELSE
--                l_rcpt_lot_tab(ln_rcpt_idx).adjust_proc_flag := cv_planning_no;
--              END IF;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_DEL_END
            END IF;
          END LOOP rcpt_proc_summary_loop;
--
          --デバックメッセージ出力(補充可能数、総出荷ペース)
          xxcop_common_pkg.put_debug_message(
             iov_debug_mode => gv_debug_mode
            ,iv_value       => cv_indent_4 || cv_prg_name || ':'
                            || 'proc_lot_balance(1):'
                            || ln_lot_supplies_quantity   || ','
                            || ln_total_lot_quantity      || ','
                            || ln_total_shipping_pace     || ','
          );
--
          --
          -- (2) 鮮度条件別ロット在庫の過不足数を計算
          --
          <<ship_proc_adjust_loop>>
          FOR ln_ship_idx IN io_gbqt_tab.FIRST .. io_gbqt_tab.LAST LOOP
            --計画対象フラグ
            IF (l_ship_lot_tab(ln_ship_idx).adjust_proc_flag = cv_planning_yes) THEN
--20100210_Ver3.5_E_本稼動_01560_SCS.Goto_ADD_START
              IF (ln_total_shipping_pace > 0) THEN
--20100210_Ver3.5_E_本稼動_01560_SCS.Goto_ADD_END
              --按分計算
              ln_div_quantity := CEIL(ln_total_lot_quantity
                                    * io_gbqt_tab(ln_ship_idx).shipping_pace
                                    / ln_total_shipping_pace
                                 );
              --過不足数の計算
              ln_adjust_quantity := l_ship_lot_tab(ln_ship_idx).lot_quantity - ln_div_quantity;
              --古いロットの過不足数を加算
              l_ship_lot_tab(ln_ship_idx).adjust_quantity := l_ship_lot_tab(ln_ship_idx).adjust_quantity
                                                           + ln_adjust_quantity;
              --案分在庫数を減算
              ln_total_lot_quantity := ln_total_lot_quantity - ln_div_quantity;
              ln_total_shipping_pace := ln_total_shipping_pace - io_gbqt_tab(ln_ship_idx).shipping_pace;
              ln_surpluses_quantity := ln_surpluses_quantity
                                     + LEAST(GREATEST(l_ship_lot_tab(ln_ship_idx).adjust_quantity, 0)
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_MOD_START
--                                           , GREATEST(ln_adjust_quantity, 0)
                                           , GREATEST(l_ship_lot_tab(ln_ship_idx).lot_quantity, 0)
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_MOD_END
                                       );
--20100210_Ver3.5_E_本稼動_01560_SCS.Goto_ADD_START
              END IF;
--20100210_Ver3.5_E_本稼動_01560_SCS.Goto_ADD_END
            END IF;
          END LOOP ship_proc_adjust_loop;
--
          --移動先倉庫の過不足数は引当在庫数＋補充可能数
          ln_total_lot_quantity := ln_total_lot_quantity + ln_lot_supplies_quantity;
          --補充可能数に移動元倉庫の余剰数を加算
          ln_lot_supplies_quantity := ln_lot_supplies_quantity + ln_surpluses_quantity;
          <<rcpt_proc_adjust_loop>>
          FOR ln_rcpt_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
            --計画対象フラグ
            IF (l_rcpt_lot_tab(ln_rcpt_idx).adjust_proc_flag = cv_planning_yes) THEN
--20100210_Ver3.5_E_本稼動_01560_SCS.Goto_ADD_START
              IF (ln_total_shipping_pace > 0) THEN
--20100210_Ver3.5_E_本稼動_01560_SCS.Goto_ADD_END
              --按分計算
              ln_div_quantity := CEIL(ln_total_lot_quantity
                                    * io_xwypo_tab(ln_rcpt_idx).shipping_pace
                                    / ln_total_shipping_pace
                                 );
              --過不足数の計算
              ln_adjust_quantity := l_rcpt_lot_tab(ln_rcpt_idx).lot_quantity - ln_div_quantity;
              --古いロットの過不足数を加算
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_MOD_START
--              l_rcpt_lot_tab(ln_rcpt_idx).adjust_quantity := GREATEST(l_rcpt_lot_tab(ln_rcpt_idx).adjust_quantity
--                                                                    + ln_adjust_quantity
--                                                                    , l_rcpt_lot_tab(ln_rcpt_idx).plan_bal_quantity
--                                                                    - io_xwypo_tab(ln_rcpt_idx).plan_bal_quantity
--                                                             );
              l_rcpt_lot_tab(ln_rcpt_idx).adjust_quantity := l_rcpt_lot_tab(ln_rcpt_idx).adjust_quantity
                                                           + ln_adjust_quantity;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_MOD_END
              --案分在庫数を減算
              ln_total_lot_quantity := ln_total_lot_quantity - ln_div_quantity;
              ln_total_shipping_pace := ln_total_shipping_pace - io_xwypo_tab(ln_rcpt_idx).shipping_pace;
              IF (ln_lot_supplies_quantity > 0) THEN
                IF (l_xliv_rec.manufacture_date >= NVL(it_sy_manufacture_date, l_xliv_rec.manufacture_date)) THEN
                  --過不足数がマイナスの場合、ロットバランス計画数を設定、補充要求数に加算
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_MOD_START
--                  IF (l_rcpt_lot_tab(ln_rcpt_idx).adjust_quantity < 0) THEN
--                    io_xwypo_tab(ln_rcpt_idx).plan_lot_quantity := l_rcpt_lot_tab(ln_rcpt_idx).adjust_quantity * -1;
                  --計画数を計算
                  l_rcpt_lot_tab(ln_rcpt_idx).plan_lot_quantity :=
                    GREATEST(LEAST(l_rcpt_lot_tab(ln_rcpt_idx).adjust_quantity * -1
                                 , io_xwypo_tab(ln_rcpt_idx).plan_bal_quantity
                                 - l_rcpt_lot_tab(ln_rcpt_idx).plan_bal_quantity
                             )
                           , 0
                    );
                  io_xwypo_tab(ln_rcpt_idx).plan_lot_quantity := l_rcpt_lot_tab(ln_rcpt_idx).plan_lot_quantity;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_MOD_END
                  ln_plan_lot_quantity := ln_plan_lot_quantity + io_xwypo_tab(ln_rcpt_idx).plan_lot_quantity;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_DEL_START
--                  END IF;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_DEL_END
                END IF;
              END IF;
--20100210_Ver3.5_E_本稼動_01560_SCS.Goto_ADD_START
              END IF;
--20100210_Ver3.5_E_本稼動_01560_SCS.Goto_ADD_END
            END IF;
          END LOOP rcpt_proc_adjust_loop;
--
          --デバックメッセージ出力(補充可能数、計画数)
          xxcop_common_pkg.put_debug_message(
             iov_debug_mode => gv_debug_mode
            ,iv_value       => cv_indent_4 || cv_prg_name || ':'
                            || 'proc_lot_balance(2):'
                            || ln_lot_supplies_quantity   || ','
                            || ln_plan_lot_quantity       || ','
          );
--
          --
          -- (3) 過不足数がマイナスの倉庫でロット計画数を計算
          --
          IF (ln_lot_supplies_quantity > 0) THEN
            --開始製造年月日以降のロットで計画数を計算
            IF (l_xliv_rec.manufacture_date >= NVL(it_sy_manufacture_date, l_xliv_rec.manufacture_date)) THEN
              --補充可能数＜ロット計画数の場合、補充可能数を出荷ペースの比率で按分
              <<rcpt_proc_division_loop>>
              WHILE (ln_lot_supplies_quantity < ln_plan_lot_quantity) LOOP
                ln_supplies_quantity := ln_lot_supplies_quantity;
                ln_plan_lot_quantity := 0;
                ln_require_quantity  := 0;
                ln_require_shipping_pace := 0;
                <<rcpt_proc_div_loop>>
                FOR ln_rcpt_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
                  --計画対象フラグ
                  IF (l_rcpt_lot_tab(ln_rcpt_idx).adjust_proc_flag = cv_planning_yes) THEN
                    --ロット計画数が0より大きい場合
                    IF (io_xwypo_tab(ln_rcpt_idx).plan_lot_quantity > 0) THEN
                      --補充要求数合計
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_MOD_START
--                      ln_require_quantity := ln_require_quantity + l_rcpt_lot_tab(ln_rcpt_idx).adjust_quantity;
                      ln_require_quantity := ln_require_quantity - l_rcpt_lot_tab(ln_rcpt_idx).plan_lot_quantity;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_MOD_END
                      --出荷ペース合計
                      ln_require_shipping_pace := ln_require_shipping_pace + io_xwypo_tab(ln_rcpt_idx).shipping_pace;
                    END IF;
                  END IF;
                END LOOP rcpt_proc_div_loop;
                --出荷ペースの比率で計画ロットに按分
                <<rcpt_proc_balance_loop>>
                FOR ln_rcpt_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
                  --計画対象フラグ
                  IF (l_rcpt_lot_tab(ln_rcpt_idx).adjust_proc_flag = cv_planning_yes) THEN
                    --ロット計画数が0より大きい場合
                    IF (io_xwypo_tab(ln_rcpt_idx).plan_lot_quantity > 0) THEN
                      --ロット計画数の計算
                      io_xwypo_tab(ln_rcpt_idx).plan_lot_quantity :=
                        GREATEST(CEIL((ln_supplies_quantity + ln_require_quantity)
                                     * io_xwypo_tab(ln_rcpt_idx).shipping_pace
                                     / ln_require_shipping_pace
                                 )
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_MOD_START
--                               - l_rcpt_lot_tab(ln_rcpt_idx).adjust_quantity
                               + l_rcpt_lot_tab(ln_rcpt_idx).plan_lot_quantity
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_MOD_END
                               , 0
                        );
                      --調整したロット在庫数を減算
                      ln_supplies_quantity := ln_supplies_quantity - io_xwypo_tab(ln_rcpt_idx).plan_lot_quantity;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_MOD_START
--                      ln_require_quantity  := ln_require_quantity  - l_rcpt_lot_tab(ln_rcpt_idx).adjust_quantity;
                      ln_require_quantity  := ln_require_quantity  + l_rcpt_lot_tab(ln_rcpt_idx).plan_lot_quantity;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_MOD_END
                      ln_require_shipping_pace := ln_require_shipping_pace - io_xwypo_tab(ln_rcpt_idx).shipping_pace;
                      ln_plan_lot_quantity := ln_plan_lot_quantity + io_xwypo_tab(ln_rcpt_idx).plan_lot_quantity;
                    END IF;
                  END IF;
                END LOOP rcpt_proc_balance_loop;
              END LOOP rcpt_proc_division_loop;
            END IF;
          END IF;
--
          --デバックメッセージ出力(補充可能数、計画数)
          xxcop_common_pkg.put_debug_message(
             iov_debug_mode => gv_debug_mode
            ,iv_value       => cv_indent_4 || cv_prg_name || ':'
                            || 'proc_lot_balance(3):'
                            || ln_lot_supplies_quantity   || ','
                            || ln_plan_lot_quantity       || ','
                            || ln_supplies_quantity       || ','
          );
--
          --
          -- (4) ロット計画数の確定
          --
          <<ship_commit_loop>>
          FOR ln_ship_idx IN io_gbqt_tab.FIRST .. io_gbqt_tab.LAST LOOP
            --鮮度条件別ロット在庫数の計画数を計算
            ln_supplies_quantity := LEAST(GREATEST(l_ship_lot_tab(ln_ship_idx).lot_quantity   , 0)
                                        , GREATEST(l_ship_lot_tab(ln_ship_idx).adjust_quantity, 0)
                                        , GREATEST(ln_plan_lot_quantity                       , 0)
                                    );
            --移動元倉庫の過不足数から減算した在庫数を計画数合計から減算
            ln_plan_lot_quantity := ln_plan_lot_quantity - ln_supplies_quantity;
            --過不足数を減算
            l_ship_lot_tab(ln_ship_idx).adjust_quantity := l_ship_lot_tab(ln_ship_idx).adjust_quantity
                                                         - ln_supplies_quantity;
            --鮮度条件別ロット在庫数を鮮度条件別在庫数に加算
            l_ship_lot_tab(ln_ship_idx).freshness_quantity := l_ship_lot_tab(ln_ship_idx).freshness_quantity
                                                            + l_ship_lot_tab(ln_ship_idx).lot_quantity
                                                            - ln_supplies_quantity;
--
            --デバックメッセージ出力(移動元ロット在庫)
            xxcop_common_pkg.put_debug_message(
               iov_debug_mode => gv_debug_mode
              ,iv_value       => cv_indent_4 || cv_prg_name || ':'
                              || 'proc_lot_stock(ship):'
                              || i_ship_rec.loct_code                                 || ','
                              || io_gbqt_tab(ln_ship_idx).freshness_condition         || ','
                              || NVL(l_ship_lot_tab(ln_ship_idx).lot_quantity, -999)  || ','
                              || l_ship_lot_tab(ln_ship_idx).freshness_quantity       || ','
                              || l_ship_lot_tab(ln_ship_idx).plan_bal_quantity        || ','
                              || l_ship_lot_tab(ln_ship_idx).adjust_quantity          || ','
                              || l_ship_lot_tab(ln_ship_idx).stock_proc_flag          || ','
                              || l_ship_lot_tab(ln_ship_idx).adjust_proc_flag         || ','
                              || ln_lot_supplies_quantity                             || ','
                              || ln_supplies_quantity                                 || ','
            );
--
            -- ===============================
            -- B-26．ログレベル出力
            -- ===============================
            put_log_level(
               iv_log_level           => cv_log_level3
              ,id_receipt_date        => gd_planning_date
              ,iv_item_no             => i_item_rec.item_no
              ,iv_loct_code           => i_ship_rec.loct_code
              ,iv_freshness_condition => io_gbqt_tab(ln_ship_idx).freshness_condition
--20100203_Ver3.4_E_本稼動_01222_SCS.Goto_MOD_START
--              ,in_stock_quantity      => l_ship_lot_tab(ln_ship_idx).freshness_quantity
              ,in_stock_quantity      => l_ship_lot_tab(ln_ship_idx).lot_quantity
--20100203_Ver3.4_E_本稼動_01222_SCS.Goto_MOD_END
              ,in_shipping_pace       => io_gbqt_tab(ln_ship_idx).shipping_pace
              ,in_supplies_quantity   => ln_lot_supplies_quantity
              ,id_manufacture_date    => l_xliv_rec.manufacture_date
              ,ov_errbuf              => lv_errbuf
              ,ov_retcode             => lv_retcode
              ,ov_errmsg              => lv_errmsg
            );
            IF (lv_retcode <> cv_status_normal) THEN
              RAISE global_api_others_expt;
            END IF;
--
          END LOOP ship_commit_loop;
--
          <<rcpt_commit_loop>>
          FOR ln_rcpt_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
            --ロット情報を設定
            io_xwypo_tab(ln_rcpt_idx).before_lot_stock := l_rcpt_lot_tab(ln_rcpt_idx).lot_quantity;
            io_xwypo_tab(ln_rcpt_idx).after_lot_stock  := io_xwypo_tab(ln_rcpt_idx).before_lot_stock
                                                        + io_xwypo_tab(ln_rcpt_idx).plan_lot_quantity;
            io_xwypo_tab(ln_rcpt_idx).manufacture_date := l_xliv_rec.manufacture_date;
            io_xwypo_tab(ln_rcpt_idx).lot_status       := l_xliv_rec.lot_status;
            --ロット逆転フラグを設定
            IF (io_xwypo_tab(ln_rcpt_idx).latest_manufacture_date > io_xwypo_tab(ln_rcpt_idx).manufacture_date) THEN
              io_xwypo_tab(ln_rcpt_idx).lot_reverse_flag := cv_csv_mark;
            ELSE
              io_xwypo_tab(ln_rcpt_idx).lot_reverse_flag := NULL;
            END IF;
            --CSV出力対象フラグを設定
            io_xwypo_tab(ln_rcpt_idx).output_flag := cv_output_off;
--
            --横持計画手持在庫テーブル登録
            -- ===============================
            -- B-24．横持計画手持在庫テーブル登録(ロット計画数)
            -- ===============================
            entry_xli_lot(
               i_xliv_rec                 => l_xliv_rec
              ,i_xwypo_rec                => io_xwypo_tab(ln_rcpt_idx)
              ,it_rcpt_loct_id            => i_rcpt_rec.loct_id
              ,ov_errbuf                  => lv_errbuf
              ,ov_retcode                 => lv_retcode
              ,ov_errmsg                  => lv_errmsg
            );
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_api_expt;
            END IF;
            --横持計画出力ワークテーブル登録
            IF (i_rcpt_rec.loct_id = io_xwypo_tab(ln_rcpt_idx).rcpt_loct_id) THEN
              -- ===============================
              -- B-25．横持計画出力ワークテーブル登録
              -- ===============================
              entry_xwypo(
                 iv_supply_status           => cv_complete
                ,i_xwypo_rec                => io_xwypo_tab(ln_rcpt_idx)
                ,ov_errbuf                  => lv_errbuf
                ,ov_retcode                 => lv_retcode
                ,ov_errmsg                  => lv_errmsg
              );
              IF (lv_retcode = cv_status_error) THEN
                RAISE global_api_expt;
              END IF;
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_ADD_START
              --特別横持計画の場合
              IF (io_xwypo_tab(ln_rcpt_idx).assignment_set_type = cv_custom_plan) THEN
                ln_sy_stocked_quantity := NVL(ln_sy_stocked_quantity, io_xwypo_tab(ln_rcpt_idx).sy_stocked_quantity)
                                        + io_xwypo_tab(ln_rcpt_idx).plan_lot_quantity;
                --特別横持制御マスタの移動数を更新
                --鮮度条件は条件に含めない
                UPDATE xxcop_wk_yoko_planning xwyp
                SET    xwyp.sy_stocked_quantity = ln_sy_stocked_quantity
                WHERE xwyp.transaction_id       = gn_transaction_id
                  AND xwyp.request_id           = cn_request_id
                  AND xwyp.assignment_set_type  = cv_custom_plan
                  AND xwyp.shipping_date        = io_xwypo_tab(ln_rcpt_idx).shipping_date
                  AND xwyp.receipt_date         = io_xwypo_tab(ln_rcpt_idx).receipt_date
                  AND xwyp.item_id              = io_xwypo_tab(ln_rcpt_idx).item_id
                  AND xwyp.ship_loct_id         = io_xwypo_tab(ln_rcpt_idx).ship_loct_id
                  AND xwyp.rcpt_loct_id         = io_xwypo_tab(ln_rcpt_idx).rcpt_loct_id
                ;
              END IF;
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_ADD_END
            END IF;
            --バランス計画数にロット計画数を加算
            l_rcpt_lot_tab(ln_rcpt_idx).plan_bal_quantity := l_rcpt_lot_tab(ln_rcpt_idx).plan_bal_quantity
                                                           + io_xwypo_tab(ln_rcpt_idx).plan_lot_quantity;
            --過不足数を加算
            l_rcpt_lot_tab(ln_rcpt_idx).adjust_quantity := l_rcpt_lot_tab(ln_rcpt_idx).adjust_quantity
                                                         + io_xwypo_tab(ln_rcpt_idx).plan_lot_quantity;
            --鮮度条件別ロット在庫数を鮮度条件別在庫数に加算
            l_rcpt_lot_tab(ln_rcpt_idx).freshness_quantity := l_rcpt_lot_tab(ln_rcpt_idx).freshness_quantity
                                                            + l_rcpt_lot_tab(ln_rcpt_idx).lot_quantity;
--
            --デバックメッセージ出力(移動先ロット在庫)
            xxcop_common_pkg.put_debug_message(
               iov_debug_mode => gv_debug_mode
              ,iv_value       => cv_indent_4 || cv_prg_name || ':'
                              || 'proc_lot_stock(rcpt):'
                              || io_xwypo_tab(ln_rcpt_idx).rcpt_loct_code             || ','
                              || io_xwypo_tab(ln_rcpt_idx).freshness_condition        || ','
                              || NVL(l_rcpt_lot_tab(ln_rcpt_idx).lot_quantity, -999)  || ','
                              || l_rcpt_lot_tab(ln_rcpt_idx).freshness_quantity       || ','
                              || l_rcpt_lot_tab(ln_rcpt_idx).plan_bal_quantity        || ','
                              || l_rcpt_lot_tab(ln_rcpt_idx).adjust_quantity          || ','
                              || l_rcpt_lot_tab(ln_rcpt_idx).stock_proc_flag          || ','
                              || l_rcpt_lot_tab(ln_rcpt_idx).adjust_proc_flag         || ','
                              || io_xwypo_tab(ln_rcpt_idx).plan_lot_quantity          || ','
            );
            --ロット計画数にロット別計画数の合計を設定
            io_xwypo_tab(ln_rcpt_idx).plan_lot_quantity := l_rcpt_lot_tab(ln_rcpt_idx).plan_bal_quantity;
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_ADD_START
            IF (i_rcpt_rec.loct_id = io_xwypo_tab(ln_rcpt_idx).rcpt_loct_id) THEN
              --計画数(最大)まで補充した鮮度条件をカウント
              IF (io_xwypo_tab(ln_rcpt_idx).plan_max_quantity = io_xwypo_tab(ln_rcpt_idx).plan_lot_quantity) THEN
                ln_max_filled_count := ln_max_filled_count + 1;
              END IF;
              --計画数(バランス)まで補充した鮮度条件をカウント
              IF (io_xwypo_tab(ln_rcpt_idx).plan_bal_quantity = io_xwypo_tab(ln_rcpt_idx).plan_lot_quantity) THEN
                ln_bal_filled_count := ln_bal_filled_count + 1;
              END IF;
            END IF;
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_ADD_END
            -- ===============================
            -- B-26．ログレベル出力
            -- ===============================
            put_log_level(
               iv_log_level           => cv_log_level2
              ,id_receipt_date        => gd_planning_date
              ,iv_item_no             => io_xwypo_tab(ln_rcpt_idx).item_no
              ,iv_loct_code           => io_xwypo_tab(ln_rcpt_idx).rcpt_loct_code
              ,iv_freshness_condition => io_xwypo_tab(ln_rcpt_idx).freshness_condition
--20100203_Ver3.4_E_本稼動_01222_SCS.Goto_MOD_START
--              ,in_stock_quantity      => l_rcpt_lot_tab(ln_rcpt_idx).freshness_quantity
              ,in_stock_quantity      => l_rcpt_lot_tab(ln_rcpt_idx).lot_quantity
--20100203_Ver3.4_E_本稼動_01222_SCS.Goto_MOD_END
              ,in_shipping_pace       => io_xwypo_tab(ln_rcpt_idx).shipping_pace
              ,in_supplies_quantity   => '0'
              ,id_manufacture_date    => l_xliv_rec.manufacture_date
              ,ov_errbuf              => lv_errbuf
              ,ov_retcode             => lv_retcode
              ,ov_errmsg              => lv_errmsg
            );
            IF (lv_retcode <> cv_status_normal) THEN
              RAISE global_api_others_expt;
            END IF;
--
          END LOOP rcpt_commit_loop;
          --
          -- (5) 初期化
          --
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_ADD_START
          --計画数(バランス)まで補充した場合、ロットバランスの計算を終了
          IF (io_gbqt_tab.COUNT = ln_bal_filled_count) THEN
            --計画数(最大)まで補充できた場合、補充ステータスを計画完了にする
            IF (io_gbqt_tab.COUNT = ln_max_filled_count) THEN
              ov_stock_result := cv_complete;
            END IF;
            EXIT xliv_loop;
          END IF;
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_ADD_END
          ln_lot_count              := 0;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_ADD_START
          ln_condition_count        := 0;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_ADD_END
          ln_total_lot_quantity     := 0;
          ln_lot_supplies_quantity  := 0;
          ln_surpluses_quantity     := 0;
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_ADD_START
          ln_max_filled_count       := 0;
          ln_bal_filled_count       := 0;
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_ADD_END
        END IF;
      EXCEPTION
        WHEN lot_skip_expt THEN
          NULL;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_ADD_START
        WHEN manufacture_skip_expt THEN
          ln_lot_count              := 0;
          ln_condition_count        := 0;
          ln_total_lot_quantity     := 0;
          ln_lot_supplies_quantity  := 0;
          ln_surpluses_quantity     := 0;
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_ADD_END
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_ADD_START
          ln_max_filled_count       := 0;
          ln_bal_filled_count       := 0;
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_ADD_END
      END;
    END LOOP xliv_loop;
    CLOSE xliv_cur;
--
  EXCEPTION
    WHEN internal_api_expt THEN
      IF (xliv_cur%ISOPEN) THEN
        CLOSE xliv_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF (xliv_cur%ISOPEN) THEN
        CLOSE xliv_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF (xliv_cur%ISOPEN) THEN
        CLOSE xliv_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (xliv_cur%ISOPEN) THEN
        CLOSE xliv_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_lot_quantity;
--
  /********************************************************************************** 
   * Procedure Name   : proc_balance_quantity
   * Description      : バランス計画数の計算(B-19)
   ***********************************************************************************/
  PROCEDURE proc_balance_quantity(
    iv_assign_type   IN     VARCHAR2,       --   割当セット区分
    i_item_rec       IN     g_item_rtype,   --   品目情報レコード型
    i_ship_rec       IN     g_loct_rtype,   --   移動元倉庫レコード型
    i_rcpt_rec       IN     g_loct_rtype,   --   移動先倉庫レコード型
    i_gfqt_tab       IN     g_fq_ttype,     --   鮮度条件別在庫引当コレクション型
    o_gbqt_tab       OUT    g_bq_ttype,     --   バランス横持計画コレクション型
    o_xwypo_tab      OUT    g_xwypo_ttype,  --   横持計画出力ワークテーブルコレクション型
    ov_stock_result  OUT    VARCHAR2,       --   バランス計画数の引当ステータス
    ov_errbuf        OUT    VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT    VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg        OUT    VARCHAR2        --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_balance_quantity'; -- プログラム名
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
    ln_rcpt_stock_quantity    NUMBER;         --移動先倉庫の鮮度条件別在庫数合計
    ln_rcpt_shipping_pace     NUMBER;         --移動先倉庫の総出荷ペース合計
    ln_supplies_quantity      NUMBER;         --補充可能数
    ln_balance_quantity       NUMBER;         --移動先倉庫のバランス計画数合計
    ln_balance_stock_days     NUMBER;         --バランス在庫日数
    ln_rcpt_count             NUMBER;
    ln_rcpt_idx               NUMBER;
    ln_plan_bal_quantity      NUMBER;         --計画数の合計
    ln_max_fill               NUMBER;         --最大在庫数を満たした鮮度条件のカウント
    ln_ship_idx               NUMBER;         --移動元倉庫の鮮度条件
--
    -- *** ローカル・カーソル ***
    --鮮度条件指定で移動先倉庫情報を取得
    CURSOR rcpt_xwyp_cur(
       id_shipping_date       DATE
      ,in_ship_loct_id        NUMBER
      ,in_item_id             NUMBER
      ,iv_freshness_condition VARCHAR2
    ) IS
      SELECT xwyp.transaction_id                              transaction_id
            ,xwyp.shipping_date                               shipping_date
            ,xwyp.receipt_date                                receipt_date
            ,xwyp.ship_loct_id                                ship_loct_id
            ,xwyp.ship_loct_code                              ship_loct_code
            ,xwyp.ship_loct_name                              ship_loct_name
            ,xwyp.rcpt_loct_id                                rcpt_loct_id
            ,xwyp.rcpt_loct_code                              rcpt_loct_code
            ,xwyp.rcpt_loct_name                              rcpt_loct_name
            ,xwyp.item_id                                     item_id
            ,xwyp.item_no                                     item_no
            ,xwyp.item_name                                   item_name
            ,xwyp.freshness_priority                          freshness_priority
            ,xwyp.freshness_condition                         freshness_condition
            ,xwyp.freshness_class                             freshness_class
            ,xwyp.freshness_check_value                       freshness_check_value
            ,xwyp.freshness_adjust_value                      freshness_adjust_value
            ,xwyp.num_of_case                                 num_of_case
            ,xwyp.palette_max_cs_qty                          palette_max_cs_qty
            ,xwyp.palette_max_step_qty                        palette_max_step_qty
            ,xwyp.delivery_unit                               delivery_unit
            ,xwyp.safety_stock_days                           safety_stock_days
            ,xwyp.max_stock_days                              max_stock_days
            ,xwyp.shipping_type                               shipping_type
            ,CASE
               WHEN xwyp.shipping_type = cv_plan_type_shipped  THEN
                 xwyp.total_shipping_pace
               WHEN xwyp.shipping_type = cv_plan_type_forecate THEN
                 xwyp.total_forecast_pace
               ELSE
                 0
             END                                              shipping_pace
            ,xwyp.assignment_set_type                         assignment_set_type
            ,xwyp.sy_manufacture_date                         sy_manufacture_date
            ,xwyp.sy_effective_date                           sy_effective_date
            ,xwyp.sy_disable_date                             sy_disable_date
            ,xwyp.sy_maxmum_quantity                          sy_maxmum_quantity
            ,xwyp.sy_stocked_quantity                         sy_stocked_quantity
--20100107_Ver3.2_E_本稼動_00936_SCS.Goto_ADD_START
            ,xwyp.crowd_class_code                            crowd_class_code
            ,xwyp.expiration_day                              expiration_day
--20100107_Ver3.2_E_本稼動_00936_SCS.Goto_ADD_END
            ,xwyp.created_by                                  created_by
            ,xwyp.creation_date                               creation_date
            ,xwyp.last_updated_by                             last_updated_by
            ,xwyp.last_update_date                            last_update_date
            ,xwyp.last_update_login                           last_update_login
            ,xwyp.request_id                                  request_id
            ,xwyp.program_application_id                      program_application_id
            ,xwyp.program_id                                  program_id
            ,xwyp.program_update_date                         program_update_date
            ,xwyp.rowid                                       xwyp_rowid
      FROM xxcop_wk_yoko_planning xwyp
      WHERE xwyp.transaction_id      = gn_transaction_id
        AND xwyp.request_id          = cn_request_id
        AND xwyp.shipping_date       = id_shipping_date
        AND xwyp.assignment_set_type = iv_assign_type
        AND xwyp.shipping_type       = NVL(gv_plan_type, xwyp.shipping_type)
        AND xwyp.ship_loct_id        = in_ship_loct_id
        AND xwyp.item_id             = in_item_id
        AND xwyp.freshness_condition = iv_freshness_condition
        AND CASE
              WHEN xwyp.shipping_type = cv_plan_type_shipped  THEN
                xwyp.total_shipping_pace
              WHEN xwyp.shipping_type = cv_plan_type_forecate THEN
                xwyp.total_forecast_pace
              ELSE
                0
            END > 0
    ORDER BY xwyp.rcpt_loct_code
    ;
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
--
    --初期化
    ln_rcpt_stock_quantity    := 0;
    ln_rcpt_shipping_pace     := 0;
    ln_supplies_quantity      := 0;
    ln_balance_quantity       := 0;
    ln_balance_stock_days     := 0;
    ln_rcpt_count             := 0;
    ln_rcpt_idx               := 0;
    ln_plan_bal_quantity      := 0;
    ln_max_fill               := 0;
    ln_ship_idx               := 1;
    l_rowid_tab.DELETE;
--
    ov_stock_result           := cv_failed;
--
    --鮮度条件の優先順にバランス計算を行う
    <<gfqt_loop>>
    FOR ln_gfqt_idx IN REVERSE i_gfqt_tab.FIRST .. i_gfqt_tab.LAST LOOP
      BEGIN
        --鮮度条件違いでローカル変数の初期化
        ln_rcpt_stock_quantity  := 0;   --移動先倉庫の鮮度条件別在庫数合計
        ln_rcpt_shipping_pace   := 0;   --移動先倉庫の総出荷ペース合計
        ln_supplies_quantity    := 0;   --補充可能数
        ln_balance_quantity     := 0;   --移動先倉庫のバランス計画数合計
        ln_balance_stock_days   := 0;   --バランス在庫日数
        ln_rcpt_count           := NVL(o_xwypo_tab.LAST, 0);
--
        --デバックメッセージ出力(鮮度条件)
        xxcop_common_pkg.put_debug_message(
           iov_debug_mode => gv_debug_mode
          ,iv_value       => cv_indent_2 || cv_prg_name || ':'
                          || 'freshness_condition:'
                          || '(' || ln_gfqt_idx || ')'                    || ','
                          || i_gfqt_tab(ln_gfqt_idx).freshness_condition  || ','
        );
--
        --鮮度条件指定で移動元倉庫情報を取得
        BEGIN
          SELECT xwyp.freshness_condition                         freshness_condition
                ,xwyp.freshness_class                             freshness_class
                ,xwyp.freshness_check_value                       freshness_check_value
                ,xwyp.freshness_adjust_value                      freshness_adjust_value
                ,NULL                                             manufacture_date
                ,0                                                plan_bal_quantity
                ,0                                                before_stock
                ,0                                                after_stock
                ,xwyp.safety_stock_days                           safety_stock_days
                ,xwyp.max_stock_days                              max_stock_days
                ,xwyp.shipping_type                               shipping_type
                ,CASE
                   WHEN xwyp.shipping_type = cv_plan_type_shipped  THEN
                     xwyp.shipping_pace
                   WHEN xwyp.shipping_type = cv_plan_type_forecate THEN
                     xwyp.forecast_pace
                   ELSE
                     0
                 END                                              shipping_pace
          INTO   o_gbqt_tab(ln_ship_idx)
          FROM xxcop_wk_yoko_planning xwyp
          WHERE xwyp.transaction_id       = gn_transaction_id
            AND xwyp.request_id           = cn_request_id
            AND xwyp.shipping_date        = i_ship_rec.target_date
            AND xwyp.assignment_set_type  = cv_base_plan
            AND xwyp.shipping_type        = NVL(gv_plan_type, xwyp.shipping_type)
            AND xwyp.rcpt_loct_id         = i_ship_rec.loct_id
            AND xwyp.item_id              = i_item_rec.item_id
            AND xwyp.freshness_condition  = i_gfqt_tab(ln_gfqt_idx).freshness_condition
            AND CASE
                  WHEN xwyp.shipping_type = cv_plan_type_shipped  THEN
                    xwyp.shipping_pace
                  WHEN xwyp.shipping_type = cv_plan_type_forecate THEN
                    xwyp.forecast_pace
                  ELSE
                    0
                END > 0
            AND ROWNUM                    = 1
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            o_gbqt_tab(ln_ship_idx).freshness_condition     := i_gfqt_tab(ln_gfqt_idx).freshness_condition;
            o_gbqt_tab(ln_ship_idx).freshness_class         := i_gfqt_tab(ln_gfqt_idx).freshness_class;
            o_gbqt_tab(ln_ship_idx).freshness_check_value   := i_gfqt_tab(ln_gfqt_idx).freshness_check_value;
            o_gbqt_tab(ln_ship_idx).freshness_adjust_value  := i_gfqt_tab(ln_gfqt_idx).freshness_adjust_value;
            o_gbqt_tab(ln_ship_idx).manufacture_date        := NULL;
            o_gbqt_tab(ln_ship_idx).plan_bal_quantity       := 0;
            o_gbqt_tab(ln_ship_idx).before_stock            := 0;
            o_gbqt_tab(ln_ship_idx).after_stock             := 0;
            o_gbqt_tab(ln_ship_idx).safety_stock_days       := 0;
            o_gbqt_tab(ln_ship_idx).max_stock_days          := 0;
            o_gbqt_tab(ln_ship_idx).shipping_type           := NULL;
            o_gbqt_tab(ln_ship_idx).shipping_pace           := 0;
        END;
        --移動元倉庫の鮮度条件別在庫数
        SELECT MIN(xliv.manufacture_date)                     manufacture_date
              ,NVL(SUM(xliv.loct_onhand), 0)                  loct_onhand
              ,NVL(SUM(CASE
                         WHEN (xliv.manufacture_date >= NVL(i_gfqt_tab(ln_gfqt_idx).sy_manufacture_date
                                                          , xliv.manufacture_date))
                         THEN xliv.loct_onhand
                         ELSE 0
                       END)
                 , 0)                                         supplies_quantity
        INTO o_gbqt_tab(ln_ship_idx).manufacture_date
            ,o_gbqt_tab(ln_ship_idx).before_stock
            ,ln_supplies_quantity
        FROM (
          SELECT xliv.lot_id                                  lot_id
                ,xliv.lot_no                                  lot_no
                ,xliv.manufacture_date                        manufacture_date
                ,xliv.expiration_date                         expiration_date
                ,xliv.unique_sign                             unique_sign
                ,xliv.lot_status                              lot_status
                ,CASE WHEN SUM(xliv.unlimited_loct_onhand) < SUM(xliv.limited_loct_onhand)
                   THEN SUM(xliv.unlimited_loct_onhand)
                   ELSE SUM(xliv.limited_loct_onhand)
                 END                                          loct_onhand
          FROM (
            SELECT /*+ LEADING(xwyl) */
                   xli.lot_id                                 lot_id
                  ,xli.lot_no                                 lot_no
                  ,xli.manufacture_date                       manufacture_date
                  ,xli.expiration_date                        expiration_date
                  ,xli.unique_sign                            unique_sign
                  ,xli.lot_status                             lot_status
                  ,xli.loct_onhand                            unlimited_loct_onhand
                  ,CASE WHEN xli.schedule_date <= i_ship_rec.target_date
                     THEN xli.loct_onhand
                     ELSE 0
                   END                                        limited_loct_onhand
            FROM xxcop_loct_inv          xli
                ,xxcop_wk_yoko_locations xwyl
            WHERE xli.transaction_id      = gn_transaction_id
              AND xli.request_id          = cn_request_id
              AND xli.item_id             = xwyl.item_id
              AND xli.loct_id             = xwyl.loct_id
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_MOD_START
--              AND xli.shipment_date      <= gd_allocated_date
              AND xli.shipment_date      <= GREATEST(gd_allocated_date, i_ship_rec.target_date)
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_MOD_END
              AND xwyl.transaction_id     = gn_transaction_id
              AND xwyl.request_id         = cn_request_id
              AND xwyl.item_id            = i_item_rec.item_id
              AND xwyl.frq_loct_id        = i_ship_rec.loct_id
            UNION ALL
            SELECT xli.lot_id                                 lot_id
                  ,xli.lot_no                                 lot_no
                  ,xli.manufacture_date                       manufacture_date
                  ,xli.expiration_date                        expiration_date
                  ,xli.unique_sign                            unique_sign
                  ,xli.lot_status                             lot_status
                  ,LEAST(xli.loct_onhand, 0)                  unlimited_loct_onhand
                  ,CASE WHEN xli.schedule_date <= i_ship_rec.target_date
                     THEN LEAST(xli.loct_onhand, 0)
                     ELSE 0
                   END                                        limited_loct_onhand
            FROM (
              SELECT /*+ LEADING(xwyl) */
                     xli.lot_id                               lot_id
                    ,xli.lot_no                               lot_no
                    ,xli.manufacture_date                     manufacture_date
                    ,xli.expiration_date                      expiration_date
                    ,xli.unique_sign                          unique_sign
                    ,xli.lot_status                           lot_status
                    ,xli.schedule_date                        schedule_date
                    ,SUM(xli.loct_onhand)                     loct_onhand
              FROM xxcop_loct_inv          xli
                  ,xxcop_wk_yoko_locations xwyl
              WHERE xli.transaction_id      = gn_transaction_id
                AND xli.request_id          = cn_request_id
                AND xli.item_id             = xwyl.item_id
                AND xli.loct_id             = xwyl.frq_loct_id
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_MOD_START
--                AND xli.shipment_date      <= gd_allocated_date
                AND xli.shipment_date      <= GREATEST(gd_allocated_date, i_ship_rec.target_date)
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_MOD_END
                AND xwyl.transaction_id     = gn_transaction_id
                AND xwyl.request_id         = cn_request_id
                AND xwyl.frq_loct_id       <> xwyl.loct_id
                AND xwyl.item_id            = i_item_rec.item_id
                AND xwyl.loct_id            = i_ship_rec.loct_id
              GROUP BY xli.lot_id
                      ,xli.lot_no
                      ,xli.manufacture_date
                      ,xli.expiration_date
                      ,xli.unique_sign
                      ,xli.lot_status
                      ,xli.schedule_date
            ) xli
          ) xliv
          GROUP BY xliv.lot_id
                  ,xliv.lot_no
                  ,xliv.manufacture_date
                  ,xliv.expiration_date
                  ,xliv.unique_sign
                  ,xliv.lot_status
        ) xliv
        WHERE xxcop_common_pkg2.get_critical_date_f(
                 i_gfqt_tab(ln_gfqt_idx).freshness_class
                ,i_gfqt_tab(ln_gfqt_idx).freshness_check_value
                ,i_gfqt_tab(ln_gfqt_idx).freshness_adjust_value
                ,o_gbqt_tab(ln_ship_idx).max_stock_days
                ,gn_freshness_buffer_days
                ,xliv.manufacture_date
                ,xliv.expiration_date
              ) >= i_ship_rec.target_date
        ;
--
        --デバックメッセージ出力(移動元倉庫の在庫数)
        xxcop_common_pkg.put_debug_message(
           iov_debug_mode => gv_debug_mode
          ,iv_value       => cv_indent_4 || cv_prg_name || ':'
                          || 'ship_loct_code:'
                          || '(' || ln_gfqt_idx || ')'                    || ','
                          || i_ship_rec.loct_code                         || ','
                          || o_gbqt_tab(ln_ship_idx).before_stock         || ','
                          || o_gbqt_tab(ln_ship_idx).shipping_pace        || ','
                          || TO_CHAR(o_gbqt_tab(ln_ship_idx).manufacture_date, cv_date_format) || ','
                          || ln_supplies_quantity                         || ','
        );
--
        ln_rcpt_idx := ln_rcpt_count + 1;
        OPEN rcpt_xwyp_cur(i_ship_rec.target_date
                          ,i_ship_rec.loct_id
                          ,i_item_rec.item_id
                          ,i_gfqt_tab(ln_gfqt_idx).freshness_condition
        );
        <<rcpt_xwyp_loop>>
        LOOP
          --鮮度条件指定で移動先倉庫情報を取得
          FETCH rcpt_xwyp_cur INTO o_xwypo_tab(ln_rcpt_idx).transaction_id
                                  ,o_xwypo_tab(ln_rcpt_idx).shipping_date
                                  ,o_xwypo_tab(ln_rcpt_idx).receipt_date
                                  ,o_xwypo_tab(ln_rcpt_idx).ship_loct_id
                                  ,o_xwypo_tab(ln_rcpt_idx).ship_loct_code
                                  ,o_xwypo_tab(ln_rcpt_idx).ship_loct_name
                                  ,o_xwypo_tab(ln_rcpt_idx).rcpt_loct_id
                                  ,o_xwypo_tab(ln_rcpt_idx).rcpt_loct_code
                                  ,o_xwypo_tab(ln_rcpt_idx).rcpt_loct_name
                                  ,o_xwypo_tab(ln_rcpt_idx).item_id
                                  ,o_xwypo_tab(ln_rcpt_idx).item_no
                                  ,o_xwypo_tab(ln_rcpt_idx).item_name
                                  ,o_xwypo_tab(ln_rcpt_idx).freshness_priority
                                  ,o_xwypo_tab(ln_rcpt_idx).freshness_condition
                                  ,o_xwypo_tab(ln_rcpt_idx).freshness_class
                                  ,o_xwypo_tab(ln_rcpt_idx).freshness_check_value
                                  ,o_xwypo_tab(ln_rcpt_idx).freshness_adjust_value
                                  ,o_xwypo_tab(ln_rcpt_idx).num_of_case
                                  ,o_xwypo_tab(ln_rcpt_idx).palette_max_cs_qty
                                  ,o_xwypo_tab(ln_rcpt_idx).palette_max_step_qty
                                  ,o_xwypo_tab(ln_rcpt_idx).delivery_unit
                                  ,o_xwypo_tab(ln_rcpt_idx).safety_stock_days
                                  ,o_xwypo_tab(ln_rcpt_idx).max_stock_days
                                  ,o_xwypo_tab(ln_rcpt_idx).shipping_type
                                  ,o_xwypo_tab(ln_rcpt_idx).shipping_pace
                                  ,o_xwypo_tab(ln_rcpt_idx).assignment_set_type
                                  ,o_xwypo_tab(ln_rcpt_idx).sy_manufacture_date
                                  ,o_xwypo_tab(ln_rcpt_idx).sy_effective_date
                                  ,o_xwypo_tab(ln_rcpt_idx).sy_disable_date
                                  ,o_xwypo_tab(ln_rcpt_idx).sy_maxmum_quantity
                                  ,o_xwypo_tab(ln_rcpt_idx).sy_stocked_quantity
--20100107_Ver3.2_E_本稼動_00936_SCS.Goto_ADD_START
                                  ,o_xwypo_tab(ln_rcpt_idx).crowd_class_code
                                  ,o_xwypo_tab(ln_rcpt_idx).expiration_day
--20100107_Ver3.2_E_本稼動_00936_SCS.Goto_ADD_END
                                  ,o_xwypo_tab(ln_rcpt_idx).created_by
                                  ,o_xwypo_tab(ln_rcpt_idx).creation_date
                                  ,o_xwypo_tab(ln_rcpt_idx).last_updated_by
                                  ,o_xwypo_tab(ln_rcpt_idx).last_update_date
                                  ,o_xwypo_tab(ln_rcpt_idx).last_update_login
                                  ,o_xwypo_tab(ln_rcpt_idx).request_id
                                  ,o_xwypo_tab(ln_rcpt_idx).program_application_id
                                  ,o_xwypo_tab(ln_rcpt_idx).program_id
                                  ,o_xwypo_tab(ln_rcpt_idx).program_update_date
                                  ,l_rowid_tab(ln_rcpt_idx)
          ;
          EXIT WHEN rcpt_xwyp_cur%NOTFOUND;
          --安全在庫数の設定
          o_xwypo_tab(ln_rcpt_idx).safety_stock_quantity := o_xwypo_tab(ln_rcpt_idx).shipping_pace
                                                          * o_xwypo_tab(ln_rcpt_idx).safety_stock_days;
          --最大在庫数の設定
          o_xwypo_tab(ln_rcpt_idx).max_stock_quantity    := o_xwypo_tab(ln_rcpt_idx).shipping_pace
                                                          * o_xwypo_tab(ln_rcpt_idx).max_stock_days;
--
          --移動先倉庫の鮮度条件別在庫数
          SELECT MIN(xliv.manufacture_date)                   manufacture_date
                ,NVL(SUM(xliv.loct_onhand), 0)                loct_onhand
          INTO o_xwypo_tab(ln_rcpt_idx).manufacture_date
              ,o_xwypo_tab(ln_rcpt_idx).before_stock
          FROM (
            SELECT xliv.lot_id                                lot_id
                  ,xliv.lot_no                                lot_no
                  ,xliv.manufacture_date                      manufacture_date
                  ,xliv.expiration_date                       expiration_date
                  ,xliv.unique_sign                           unique_sign
                  ,xliv.lot_status                            lot_status
                  ,CASE WHEN SUM(xliv.unlimited_loct_onhand) < SUM(xliv.limited_loct_onhand)
                     THEN SUM(xliv.unlimited_loct_onhand)
                     ELSE SUM(xliv.limited_loct_onhand)
                   END                                        loct_onhand
            FROM (
              SELECT /*+ LEADING(xwyl) */
                     xli.lot_id                               lot_id
                    ,xli.lot_no                               lot_no
                    ,xli.manufacture_date                     manufacture_date
                    ,xli.expiration_date                      expiration_date
                    ,xli.unique_sign                          unique_sign
                    ,xli.lot_status                           lot_status
                    ,xli.loct_onhand                          unlimited_loct_onhand
                    ,CASE WHEN xli.schedule_date <= o_xwypo_tab(ln_rcpt_idx).receipt_date
                       THEN xli.loct_onhand
                       ELSE 0
                     END                                      limited_loct_onhand
              FROM xxcop_loct_inv          xli
                  ,xxcop_wk_yoko_locations xwyl
              WHERE xli.transaction_id      = gn_transaction_id
                AND xli.request_id          = cn_request_id
                AND xli.item_id             = xwyl.item_id
                AND xli.loct_id             = xwyl.loct_id
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_MOD_START
--                AND xli.shipment_date      <= gd_allocated_date
                AND xli.shipment_date      <= GREATEST(gd_allocated_date, o_xwypo_tab(ln_rcpt_idx).receipt_date)
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_MOD_END
                AND xwyl.transaction_id     = gn_transaction_id
                AND xwyl.request_id         = cn_request_id
                AND xwyl.item_id            = i_item_rec.item_id
                AND xwyl.frq_loct_id        = o_xwypo_tab(ln_rcpt_idx).rcpt_loct_id
              UNION ALL
              SELECT xli.lot_id                               lot_id
                    ,xli.lot_no                               lot_no
                    ,xli.manufacture_date                     manufacture_date
                    ,xli.expiration_date                      expiration_date
                    ,xli.unique_sign                          unique_sign
                    ,xli.lot_status                           lot_status
                    ,LEAST(xli.loct_onhand, 0)                unlimited_loct_onhand
                    ,CASE WHEN xli.schedule_date <= o_xwypo_tab(ln_rcpt_idx).receipt_date
                       THEN LEAST(xli.loct_onhand, 0)
                       ELSE 0
                     END                                      limited_loct_onhand
              FROM (
                SELECT /*+ LEADING(xwyl) */
                       xli.lot_id                             lot_id
                      ,xli.lot_no                             lot_no
                      ,xli.manufacture_date                   manufacture_date
                      ,xli.expiration_date                    expiration_date
                      ,xli.unique_sign                        unique_sign
                      ,xli.lot_status                         lot_status
                      ,xli.schedule_date                      schedule_date
                      ,SUM(xli.loct_onhand)                   loct_onhand
                FROM xxcop_loct_inv          xli
                    ,xxcop_wk_yoko_locations xwyl
                WHERE xli.transaction_id      = gn_transaction_id
                  AND xli.request_id          = cn_request_id
                  AND xli.item_id             = xwyl.item_id
                  AND xli.loct_id             = xwyl.frq_loct_id
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_MOD_START
--                  AND xli.shipment_date      <= gd_allocated_date
                  AND xli.shipment_date      <= GREATEST(gd_allocated_date, o_xwypo_tab(ln_rcpt_idx).receipt_date)
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_MOD_END
                  AND xwyl.transaction_id     = gn_transaction_id
                  AND xwyl.request_id         = cn_request_id
                  AND xwyl.frq_loct_id       <> xwyl.loct_id
                  AND xwyl.item_id            = i_item_rec.item_id
                  AND xwyl.loct_id            = o_xwypo_tab(ln_rcpt_idx).rcpt_loct_id
                GROUP BY xli.lot_id
                        ,xli.lot_no
                        ,xli.manufacture_date
                        ,xli.expiration_date
                        ,xli.unique_sign
                        ,xli.lot_status
                        ,xli.schedule_date
              ) xli
            ) xliv
            GROUP BY xliv.lot_id
                    ,xliv.lot_no
                    ,xliv.manufacture_date
                    ,xliv.expiration_date
                    ,xliv.unique_sign
                    ,xliv.lot_status
          ) xliv
          WHERE xxcop_common_pkg2.get_critical_date_f(
                   i_gfqt_tab(ln_gfqt_idx).freshness_class
                  ,i_gfqt_tab(ln_gfqt_idx).freshness_check_value
                  ,i_gfqt_tab(ln_gfqt_idx).freshness_adjust_value
                  ,o_xwypo_tab(ln_rcpt_idx).max_stock_days
                  ,gn_freshness_buffer_days
                  ,xliv.manufacture_date
                  ,xliv.expiration_date
                ) >= o_xwypo_tab(ln_rcpt_idx).receipt_date
          ;
          --横持前在庫は最大在庫数が上限
          o_xwypo_tab(ln_rcpt_idx).before_stock := LEAST(o_xwypo_tab(ln_rcpt_idx).before_stock
                                                       , o_xwypo_tab(ln_rcpt_idx).max_stock_days
                                                       * o_xwypo_tab(ln_rcpt_idx).shipping_pace
                                                   );
          --移動先倉庫の最大製造年月日を取得
          SELECT MAX(xli.manufacture_date)                    manufacture_date
          INTO o_xwypo_tab(ln_rcpt_idx).latest_manufacture_date
          FROM xxcop_loct_inv          xli
          WHERE xli.transaction_id      = gn_transaction_id
            AND xli.request_id          = cn_request_id
            AND xli.item_id             = i_item_rec.item_id
            AND xli.loct_id             = o_xwypo_tab(ln_rcpt_idx).rcpt_loct_id
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_MOD_START
--            AND xli.shipment_date      <= gd_allocated_date
            AND xli.shipment_date      <= GREATEST(gd_allocated_date, o_xwypo_tab(ln_rcpt_idx).receipt_date)
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_MOD_END
            AND xli.schedule_date      <= o_xwypo_tab(ln_rcpt_idx).receipt_date
            AND xli.transaction_type   IN (cv_xli_type_inv)
          ;
--
          --特別横持計画の場合、移動数を取得
          IF (o_xwypo_tab(ln_rcpt_idx).assignment_set_type = cv_custom_plan) THEN
            SELECT NVL(MAX(xwyp.sy_stocked_quantity), 0)      sy_allocated_quantity
            INTO o_xwypo_tab(ln_rcpt_idx).sy_stocked_quantity
            FROM xxcop_wk_yoko_planning xwyp
            WHERE xwyp.transaction_id       = gn_transaction_id
              AND xwyp.request_id           = cn_request_id
              AND xwyp.planning_flag        = cv_planning_yes
              AND xwyp.assignment_set_type  = cv_custom_plan
              AND xwyp.rcpt_loct_id         = o_xwypo_tab(ln_rcpt_idx).rcpt_loct_id
              AND xwyp.item_id              = i_item_rec.item_id
            ;
            --特別横持フラグを設定
            o_xwypo_tab(ln_rcpt_idx).special_yoko_flag := cv_csv_mark;
          END IF;
--
          --デバックメッセージ出力(移動先倉庫の在庫数)
          xxcop_common_pkg.put_debug_message(
             iov_debug_mode => gv_debug_mode
            ,iv_value       => cv_indent_4 || cv_prg_name || ':'
                            || 'rcpt_loct_code:'
                            || '(' || ln_gfqt_idx || '-' || ln_rcpt_idx || ')'  || ','
                            || o_xwypo_tab(ln_rcpt_idx).rcpt_loct_code          || ','
                            || o_xwypo_tab(ln_rcpt_idx).before_stock            || ','
                            || o_xwypo_tab(ln_rcpt_idx).shipping_pace           || ','
                            || TO_CHAR(o_xwypo_tab(ln_rcpt_idx).manufacture_date, cv_date_format)  || ','
          );
--
          --移動先倉庫の鮮度条件別在庫数合計
          ln_rcpt_stock_quantity := ln_rcpt_stock_quantity + o_xwypo_tab(ln_rcpt_idx).before_stock;
          --移動先倉庫の出荷ペース合計
          ln_rcpt_shipping_pace  := ln_rcpt_shipping_pace  + o_xwypo_tab(ln_rcpt_idx).shipping_pace;
          --移動先倉庫数をカウント
          ln_rcpt_idx := ln_rcpt_idx + 1;
        END LOOP rcpt_xwyp_loop;
        CLOSE rcpt_xwyp_cur;
--
        --バランス在庫日数の計算(鮮度条件別在庫数合計÷出荷ペース合計)
        ln_balance_stock_days := TRUNC((o_gbqt_tab(ln_ship_idx).before_stock  + ln_rcpt_stock_quantity)
                                     / (o_gbqt_tab(ln_ship_idx).shipping_pace + ln_rcpt_shipping_pace )
                                     , 2);
        --補充可能数の計算
        ln_supplies_quantity := GREATEST(LEAST(FLOOR(o_gbqt_tab(ln_ship_idx).before_stock
                                                  - (ln_balance_stock_days * o_gbqt_tab(ln_ship_idx).shipping_pace)
                                               )
                                             , ln_supplies_quantity
                                         )
                                       , 0
                                );
--
        --デバックメッセージ出力(バランス在庫日数)
        xxcop_common_pkg.put_debug_message(
           iov_debug_mode => gv_debug_mode
          ,iv_value       => cv_indent_2 || cv_prg_name || ':'
                          || 'balance_proc:'
                          || ln_balance_stock_days    || ','
                          || ln_supplies_quantity     || ','
        );
--
        IF (ln_supplies_quantity <= 0) THEN
          --補充可能数が0以下のためバランス計算は行わない
          RAISE short_supply_expt;
        END IF;
--
        <<balance_loop>>
        FOR ln_rcpt_idx IN ln_rcpt_count + 1 .. o_xwypo_tab.LAST LOOP
          --バランス計画数の計算
          o_xwypo_tab(ln_rcpt_idx).plan_bal_quantity := GREATEST(
                                                          FLOOR(
                                                            LEAST(ln_balance_stock_days
                                                                , o_xwypo_tab(ln_rcpt_idx).max_stock_days)
                                                                * o_xwypo_tab(ln_rcpt_idx).shipping_pace
                                                          ) - o_xwypo_tab(ln_rcpt_idx).before_stock
                                                        , 0
                                                        );
          --特別横持計画の場合、設定数が上限
          IF   ((o_xwypo_tab(ln_rcpt_idx).assignment_set_type = cv_custom_plan)
            AND (o_xwypo_tab(ln_rcpt_idx).sy_maxmum_quantity IS NOT NULL))
          THEN
            o_xwypo_tab(ln_rcpt_idx).plan_bal_quantity := LEAST(o_xwypo_tab(ln_rcpt_idx).plan_bal_quantity
                                                             , (o_xwypo_tab(ln_rcpt_idx).sy_maxmum_quantity
                                                              - o_xwypo_tab(ln_rcpt_idx).sy_stocked_quantity)
                                                          );
          END IF;
          --バランス計画数の合計
          ln_balance_quantity := ln_balance_quantity + o_xwypo_tab(ln_rcpt_idx).plan_bal_quantity;
        END LOOP balance_loop;
--
        --補充可能数がバランス計画数に満たない場合、移動先倉庫の出荷ペースで按分
        IF ((ln_supplies_quantity < ln_balance_quantity ) AND ( ln_balance_quantity > 0)) THEN
          <<division_loop>>
          FOR ln_div_idx IN ln_rcpt_count + 1 .. o_xwypo_tab.LAST LOOP
            --初期化
            ln_rcpt_stock_quantity := 0;
            ln_rcpt_shipping_pace  := 0;
            ln_balance_quantity    := 0;
            --按分在庫日数の計算
            <<div_proc_loop>>
            FOR ln_rcpt_idx IN ln_rcpt_count + 1 .. o_xwypo_tab.LAST LOOP
              IF (o_xwypo_tab(ln_rcpt_idx).plan_bal_quantity > 0) THEN
                --バランス計画数が0以上の移動先倉庫の在庫数合計
                ln_rcpt_stock_quantity := ln_rcpt_stock_quantity + o_xwypo_tab(ln_rcpt_idx).before_stock;
                --バランス計画数が0以上の出荷ペース合計
                ln_rcpt_shipping_pace := ln_rcpt_shipping_pace + o_xwypo_tab(ln_rcpt_idx).shipping_pace;
              END IF;
            END LOOP div_proc_loop;
            --按分バランス在庫日数の計算
            ln_balance_stock_days := TRUNC((ln_supplies_quantity + ln_rcpt_stock_quantity) / ln_rcpt_shipping_pace, 2);
            --按分在庫日数でバランス計画数を計算
            <<div_balance_loop>>
            FOR ln_rcpt_idx IN ln_rcpt_count + 1 .. o_xwypo_tab.LAST LOOP
              IF (o_xwypo_tab(ln_rcpt_idx).plan_bal_quantity > 0) THEN
                --バランス計画数の計算
                o_xwypo_tab(ln_rcpt_idx).plan_bal_quantity := GREATEST(
                                                                 FLOOR(ln_balance_stock_days
                                                                     * o_xwypo_tab(ln_rcpt_idx).shipping_pace
                                                                 )
                                                               - o_xwypo_tab(ln_rcpt_idx).before_stock
                                                               , 0
                                                              );
                --特別横持計画の場合、設定数が上限
                IF   ((o_xwypo_tab(ln_rcpt_idx).assignment_set_type = cv_custom_plan)
                  AND (o_xwypo_tab(ln_rcpt_idx).sy_maxmum_quantity IS NOT NULL))
                THEN
                  o_xwypo_tab(ln_rcpt_idx).plan_bal_quantity := LEAST(o_xwypo_tab(ln_rcpt_idx).plan_bal_quantity
                                                                   , (o_xwypo_tab(ln_rcpt_idx).sy_maxmum_quantity
                                                                    - o_xwypo_tab(ln_rcpt_idx).sy_stocked_quantity)
                                                                );
                END IF;
                --バランス計画数の合計
                ln_balance_quantity := ln_balance_quantity + o_xwypo_tab(ln_rcpt_idx).plan_bal_quantity;
              END IF;
            END LOOP div_balance_loop;
            IF (ln_supplies_quantity >= ln_balance_quantity) THEN
              EXIT division_loop;
            END IF;
          END LOOP division_loop;
        END IF;
--
      EXCEPTION
        WHEN short_supply_expt THEN
          NULL;
      END;
--
      <<entry_xli_loop>>
      FOR ln_rcpt_idx IN ln_rcpt_count + 1 .. o_xwypo_tab.LAST LOOP
        --補充不可の場合、在庫数、計画数に0をセット
        o_xwypo_tab(ln_rcpt_idx).manufacture_date  := NULL;
        o_xwypo_tab(ln_rcpt_idx).plan_bal_quantity := NVL(o_xwypo_tab(ln_rcpt_idx).plan_bal_quantity, 0);
        o_xwypo_tab(ln_rcpt_idx).plan_lot_quantity := NVL(o_xwypo_tab(ln_rcpt_idx).plan_lot_quantity, 0);
        o_xwypo_tab(ln_rcpt_idx).before_stock      := NVL(o_xwypo_tab(ln_rcpt_idx).before_stock, 0);
        o_xwypo_tab(ln_rcpt_idx).after_stock       := NVL(o_xwypo_tab(ln_rcpt_idx).before_stock, 0);
        o_xwypo_tab(ln_rcpt_idx).before_lot_stock  := NVL(o_xwypo_tab(ln_rcpt_idx).before_stock, 0);
        o_xwypo_tab(ln_rcpt_idx).after_lot_stock   := NVL(o_xwypo_tab(ln_rcpt_idx).after_stock, 0);
        o_xwypo_tab(ln_rcpt_idx).before_lot_stock  := NVL(o_xwypo_tab(ln_rcpt_idx).before_lot_stock, 0);
        o_xwypo_tab(ln_rcpt_idx).after_lot_stock   := NVL(o_xwypo_tab(ln_rcpt_idx).after_lot_stock, 0);
        --バランス計算後の移動先倉庫の鮮度条件別在庫数を計算
        o_xwypo_tab(ln_rcpt_idx).after_stock := o_xwypo_tab(ln_rcpt_idx).before_stock
                                              + o_xwypo_tab(ln_rcpt_idx).plan_bal_quantity;
--
        --移動先倉庫で鮮度条件に引当てた横持前在庫数を横持計画手持在庫テーブルに登録
        -- ===============================
        -- B-22．横持計画手持在庫テーブル登録(バランス計画数)
        -- ===============================
        entry_xli_balance(
           it_loct_id                 => o_xwypo_tab(ln_rcpt_idx).rcpt_loct_id
          ,it_loct_code               => o_xwypo_tab(ln_rcpt_idx).rcpt_loct_code
          ,it_item_id                 => o_xwypo_tab(ln_rcpt_idx).item_id
          ,it_item_no                 => o_xwypo_tab(ln_rcpt_idx).item_no
          ,it_schedule_date           => o_xwypo_tab(ln_rcpt_idx).receipt_date
          ,it_schedule_quantity       => o_xwypo_tab(ln_rcpt_idx).before_stock
          ,it_freshness_class         => o_xwypo_tab(ln_rcpt_idx).freshness_class
          ,it_freshness_check_value   => o_xwypo_tab(ln_rcpt_idx).freshness_check_value
          ,it_freshness_adjust_value  => o_xwypo_tab(ln_rcpt_idx).freshness_adjust_value
          ,it_max_stock_days          => o_xwypo_tab(ln_rcpt_idx).max_stock_days
          ,it_sy_manufacture_date     => NULL
          ,ov_errbuf                  => lv_errbuf
          ,ov_retcode                 => lv_retcode
          ,ov_errmsg                  => lv_errmsg
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        --移動元倉庫で鮮度条件に引当てたバランス計画数を横持計画手持在庫テーブルに登録
        -- ===============================
        -- B-22．横持計画手持在庫テーブル登録(バランス計画数)
        -- ===============================
        entry_xli_balance(
           it_loct_id                 => o_xwypo_tab(ln_rcpt_idx).ship_loct_id
          ,it_loct_code               => o_xwypo_tab(ln_rcpt_idx).ship_loct_code
          ,it_item_id                 => o_xwypo_tab(ln_rcpt_idx).item_id
          ,it_item_no                 => o_xwypo_tab(ln_rcpt_idx).item_no
          ,it_schedule_date           => o_xwypo_tab(ln_rcpt_idx).shipping_date
          ,it_schedule_quantity       => o_xwypo_tab(ln_rcpt_idx).plan_bal_quantity
          ,it_freshness_class         => o_xwypo_tab(ln_rcpt_idx).freshness_class
          ,it_freshness_check_value   => o_xwypo_tab(ln_rcpt_idx).freshness_check_value
          ,it_freshness_adjust_value  => o_xwypo_tab(ln_rcpt_idx).freshness_adjust_value
          ,it_max_stock_days          => o_gbqt_tab(ln_ship_idx).max_stock_days
          ,it_sy_manufacture_date     => i_gfqt_tab(ln_gfqt_idx).sy_manufacture_date
          ,ov_errbuf                  => lv_errbuf
          ,ov_retcode                 => lv_retcode
          ,ov_errmsg                  => lv_errmsg
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        END IF;
        --計画数の合計を集計
        ln_plan_bal_quantity := ln_plan_bal_quantity + o_xwypo_tab(ln_rcpt_idx).plan_bal_quantity;
        --移動元倉庫の計画数に移動先倉庫の計画数を加算
        o_gbqt_tab(ln_ship_idx).plan_bal_quantity := o_gbqt_tab(ln_ship_idx).plan_bal_quantity
                                                   + o_xwypo_tab(ln_rcpt_idx).plan_bal_quantity;
        --最大在庫数まで引当されたか確認
        IF (i_rcpt_rec.loct_id = o_xwypo_tab(ln_rcpt_idx).rcpt_loct_id) THEN
          --横持前在庫＋計画数＝最大在庫数の場合
          IF (o_xwypo_tab(ln_rcpt_idx).before_stock + o_xwypo_tab(ln_rcpt_idx).plan_bal_quantity
            = o_xwypo_tab(ln_rcpt_idx).max_stock_days * o_xwypo_tab(ln_rcpt_idx).shipping_pace)
          THEN
            ln_max_fill := ln_max_fill + 1;
          END IF;
        END IF;
        --特別横持計画の場合、移動数を更新
        IF (o_xwypo_tab(ln_rcpt_idx).assignment_set_type = cv_custom_plan) THEN
          UPDATE xxcop_wk_yoko_planning xwyp
          SET    xwyp.sy_stocked_quantity = o_xwypo_tab(ln_rcpt_idx).sy_stocked_quantity
                                          + o_xwypo_tab(ln_rcpt_idx).plan_bal_quantity
          WHERE xwyp.rowid                = l_rowid_tab(ln_rcpt_idx)
          ;
        END IF;
--
        --デバックメッセージ出力(横持後在庫数)
        xxcop_common_pkg.put_debug_message(
           iov_debug_mode => gv_debug_mode
          ,iv_value       => cv_indent_4 || cv_prg_name || ':'
                          || 'proc_balanced_stock(rcpt):'
                          || '(' || ln_gfqt_idx || '-' || ln_rcpt_idx || ')'  || ','
                          || o_xwypo_tab(ln_rcpt_idx).rcpt_loct_code          || ','
                          || o_xwypo_tab(ln_rcpt_idx).before_stock            || ','
                          || o_xwypo_tab(ln_rcpt_idx).plan_bal_quantity       || ','
                          || o_xwypo_tab(ln_rcpt_idx).after_stock             || ','
                          || o_xwypo_tab(ln_rcpt_idx).sy_stocked_quantity     || ','
                          || o_xwypo_tab(ln_rcpt_idx).sy_maxmum_quantity      || ','
        );
--
        -- ===============================
        -- B-26．ログレベル出力
        -- ===============================
        put_log_level(
           iv_log_level           => cv_log_level1
          ,id_receipt_date        => gd_planning_date
          ,iv_item_no             => o_xwypo_tab(ln_rcpt_idx).item_no
          ,iv_loct_code           => o_xwypo_tab(ln_rcpt_idx).rcpt_loct_code
          ,iv_freshness_condition => o_xwypo_tab(ln_rcpt_idx).freshness_condition
          ,in_stock_quantity      => o_xwypo_tab(ln_rcpt_idx).before_stock
          ,in_shipping_pace       => o_xwypo_tab(ln_rcpt_idx).shipping_pace
--20100203_Ver3.4_E_本稼動_01222_SCS.Goto_MOD_START
--          ,in_supplies_quantity   => ln_supplies_quantity
          ,in_supplies_quantity   => o_xwypo_tab(ln_rcpt_idx).plan_bal_quantity
--20100203_Ver3.4_E_本稼動_01222_SCS.Goto_MOD_END
          ,id_manufacture_date    => NULL
          ,ov_errbuf              => lv_errbuf
          ,ov_retcode             => lv_retcode
          ,ov_errmsg              => lv_errmsg
        );
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_api_others_expt;
        END IF;
      END LOOP entry_xli_loop;
      --移動元倉庫の横持前在庫、横持後在庫を計算
      o_gbqt_tab(ln_ship_idx).after_stock := LEAST(o_gbqt_tab(ln_ship_idx).before_stock
                                                 - o_gbqt_tab(ln_ship_idx).plan_bal_quantity
                                                 , o_gbqt_tab(ln_ship_idx).max_stock_days
                                                 * o_gbqt_tab(ln_ship_idx).shipping_pace
                                             );
      o_gbqt_tab(ln_ship_idx).before_stock := o_gbqt_tab(ln_ship_idx).after_stock
                                            + o_gbqt_tab(ln_ship_idx).plan_bal_quantity;
--
      --移動元倉庫で鮮度条件に引当てた在庫数を横持計画手持在庫テーブルに登録
      -- ===============================
      -- B-22．横持計画手持在庫テーブル登録(バランス計画数)
      -- ===============================
      entry_xli_balance(
         it_loct_id                 => i_ship_rec.loct_id
        ,it_loct_code               => i_ship_rec.loct_code
        ,it_item_id                 => i_item_rec.item_id
        ,it_item_no                 => i_item_rec.item_no
        ,it_schedule_date           => i_ship_rec.target_date
        ,it_schedule_quantity       => o_gbqt_tab(ln_ship_idx).after_stock
        ,it_freshness_class         => i_gfqt_tab(ln_gfqt_idx).freshness_class
        ,it_freshness_check_value   => i_gfqt_tab(ln_gfqt_idx).freshness_check_value
        ,it_freshness_adjust_value  => i_gfqt_tab(ln_gfqt_idx).freshness_adjust_value
        ,it_max_stock_days          => o_gbqt_tab(ln_ship_idx).max_stock_days
        ,it_sy_manufacture_date     => NULL
        ,ov_errbuf                  => lv_errbuf
        ,ov_retcode                 => lv_retcode
        ,ov_errmsg                  => lv_errmsg
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      --デバックメッセージ出力(横持後在庫数)
      xxcop_common_pkg.put_debug_message(
         iov_debug_mode => gv_debug_mode
        ,iv_value       => cv_indent_4 || cv_prg_name || ':'
                        || 'proc_balanced_stock(ship):'
                        || '(' || ln_gfqt_idx || ')'                    || ','
                        || i_ship_rec.loct_code                         || ','
                        || o_gbqt_tab(ln_ship_idx).before_stock         || ','
                        || o_gbqt_tab(ln_ship_idx).plan_bal_quantity    || ','
                        || o_gbqt_tab(ln_ship_idx).after_stock          || ','
      );
--
      -- ===============================
      -- B-26．ログレベル出力
      -- ===============================
      put_log_level(
         iv_log_level           => cv_log_level1
        ,id_receipt_date        => gd_planning_date
        ,iv_item_no             => i_item_rec.item_no
        ,iv_loct_code           => i_ship_rec.loct_code
        ,iv_freshness_condition => i_gfqt_tab(ln_gfqt_idx).freshness_condition
        ,in_stock_quantity      => o_gbqt_tab(ln_ship_idx).before_stock
        ,in_shipping_pace       => o_gbqt_tab(ln_ship_idx).shipping_pace
--20100203_Ver3.4_E_本稼動_01222_SCS.Goto_MOD_START
--        ,in_supplies_quantity   => o_gbqt_tab(ln_ship_idx).plan_bal_quantity
        ,in_supplies_quantity   => ln_supplies_quantity
--20100203_Ver3.4_E_本稼動_01222_SCS.Goto_MOD_END
        ,id_manufacture_date    => NULL
        ,ov_errbuf              => lv_errbuf
        ,ov_retcode             => lv_retcode
        ,ov_errmsg              => lv_errmsg
      );
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_api_others_expt;
      END IF;
--
      ln_ship_idx := ln_ship_idx + 1;
--
    END LOOP gfqt_loop;
    --計画数の合計が0の場合、バランス計画数の引当結果を警告にする
    IF (o_gbqt_tab.COUNT = ln_max_fill) THEN
      ov_stock_result := cv_complete;
    ELSIF (ln_plan_bal_quantity > 0) THEN
      ov_stock_result := cv_incomplete;
    ELSE
      ov_stock_result := cv_failed;
    END IF;
--
  EXCEPTION
    WHEN internal_api_expt THEN
      IF (rcpt_xwyp_cur%ISOPEN) THEN
        CLOSE rcpt_xwyp_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF (rcpt_xwyp_cur%ISOPEN) THEN
        CLOSE rcpt_xwyp_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF (rcpt_xwyp_cur%ISOPEN) THEN
        CLOSE rcpt_xwyp_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (rcpt_xwyp_cur%ISOPEN) THEN
        CLOSE rcpt_xwyp_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_balance_quantity;
--
  /********************************************************************************** 
   * Procedure Name   : proc_ship_loct
   * Description      : 移動元倉庫の特定(B-18)
   ***********************************************************************************/
  PROCEDURE proc_ship_loct(
    i_item_rec       IN     g_item_rtype,   --   品目レコード型
    i_ship_tab       IN     g_loct_ttype,   --   移動元倉庫コレクション型
    i_gfqt_tab       IN     g_fq_ttype,     --   鮮度条件別在庫引当コレクション型
    o_git_tab        OUT    g_idx_ttype,    --   移動元倉庫優先順位コレクション型
    ov_errbuf        OUT    VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT    VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg        OUT    VARCHAR2        --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_ship_loct'; -- プログラム名
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
    ld_critical_date          DATE;         --鮮度条件基準日
    ln_glpt_idx               NUMBER;
--
    -- *** ローカル・カーソル ***
    --在庫の取得
    CURSOR xliv_cur(
       in_item_id             NUMBER
      ,in_loct_id             NUMBER
      ,id_target_date         DATE
      ,id_manufacture_date    DATE
    ) IS
      SELECT xliv.manufacture_date                            manufacture_date
            ,xliv.expiration_date                             expiration_date
            ,NVL(SUM(xliv.loct_onhand), 0)                    loct_onhand
      FROM (
        SELECT xliv.lot_id                                    lot_id
              ,xliv.lot_no                                    lot_no
              ,xliv.manufacture_date                          manufacture_date
              ,xliv.expiration_date                           expiration_date
              ,xliv.unique_sign                               unique_sign
              ,xliv.lot_status                                lot_status
              ,CASE WHEN SUM(xliv.unlimited_loct_onhand) < SUM(xliv.limited_loct_onhand)
                 THEN SUM(xliv.unlimited_loct_onhand)
                 ELSE SUM(xliv.limited_loct_onhand)
               END                                            loct_onhand
        FROM (
          SELECT /*+ LEADING(xwyl)*/
                 xli.lot_id                                   lot_id
                ,xli.lot_no                                   lot_no
                ,xli.manufacture_date                         manufacture_date
                ,xli.expiration_date                          expiration_date
                ,xli.unique_sign                              unique_sign
                ,xli.lot_status                               lot_status
                ,xli.loct_onhand                              unlimited_loct_onhand
                ,CASE WHEN xli.schedule_date <= id_target_date
                   THEN xli.loct_onhand
                   ELSE 0
                 END                                          limited_loct_onhand
          FROM xxcop_loct_inv          xli
              ,xxcop_wk_yoko_locations xwyl
          WHERE xli.transaction_id      = gn_transaction_id
            AND xli.request_id          = cn_request_id
            AND xli.item_id             = xwyl.item_id
            AND xli.loct_id             = xwyl.loct_id
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_MOD_START
--            AND xli.shipment_date      <= gd_allocated_date
            AND xli.shipment_date      <= GREATEST(gd_allocated_date, id_target_date)
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_MOD_END
            AND xli.transaction_type  NOT IN (cv_xli_type_bq)
            AND xwyl.transaction_id     = gn_transaction_id
            AND xwyl.request_id         = cn_request_id
            AND xwyl.item_id            = in_item_id
            AND xwyl.frq_loct_id        = in_loct_id
          UNION ALL
          SELECT xli.lot_id                                   lot_id
                ,xli.lot_no                                   lot_no
                ,xli.manufacture_date                         manufacture_date
                ,xli.expiration_date                          expiration_date
                ,xli.unique_sign                              unique_sign
                ,xli.lot_status                               lot_status
                ,LEAST(xli.loct_onhand, 0)                    unlimited_loct_onhand
                ,CASE WHEN xli.schedule_date <= id_target_date
                   THEN LEAST(xli.loct_onhand, 0)
                   ELSE 0
                 END                                          limited_loct_onhand
          FROM (
            SELECT /*+ LEADING(xwyl)*/
                   xli.lot_id                                 lot_id
                  ,xli.lot_no                                 lot_no
                  ,xli.manufacture_date                       manufacture_date
                  ,xli.expiration_date                        expiration_date
                  ,xli.unique_sign                            unique_sign
                  ,xli.lot_status                             lot_status
                  ,xli.schedule_date                          schedule_date
                  ,SUM(xli.loct_onhand)                       loct_onhand
            FROM xxcop_loct_inv          xli
                ,xxcop_wk_yoko_locations xwyl
            WHERE xli.transaction_id      = gn_transaction_id
              AND xli.request_id          = cn_request_id
              AND xli.item_id             = xwyl.item_id
              AND xli.loct_id             = xwyl.frq_loct_id
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_MOD_START
--              AND xli.shipment_date      <= gd_allocated_date
              AND xli.shipment_date      <= GREATEST(gd_allocated_date, id_target_date)
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_MOD_END
              AND xli.transaction_type  NOT IN (cv_xli_type_bq)
              AND xwyl.transaction_id     = gn_transaction_id
              AND xwyl.request_id         = cn_request_id
              AND xwyl.frq_loct_id       <> xwyl.loct_id
              AND xwyl.item_id            = in_item_id
              AND xwyl.loct_id            = in_loct_id
            GROUP BY xli.lot_id
                    ,xli.lot_no
                    ,xli.manufacture_date
                    ,xli.expiration_date
                    ,xli.unique_sign
                    ,xli.lot_status
                    ,xli.schedule_date
          ) xli
        ) xliv
        GROUP BY xliv.lot_id
                ,xliv.lot_no
                ,xliv.manufacture_date
                ,xliv.expiration_date
                ,xliv.unique_sign
                ,xliv.lot_status
      ) xliv
      WHERE xliv.manufacture_date >= NVL(id_manufacture_date, xliv.manufacture_date)
      GROUP BY xliv.manufacture_date
              ,xliv.expiration_date
      HAVING NVL(SUM(xliv.loct_onhand), 0) > 0
      ORDER BY xliv.manufacture_date
    ;
--
    -- *** ローカル・レコード ***
    --移動元倉庫優先順位
    l_glpt_tab                g_lp_ttype;
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
    --初期化
    ld_critical_date          := NULL;
    ln_glpt_idx               := 0;
    l_glpt_tab.DELETE;
--
    <<ship_loop>>
    FOR ln_ship_idx IN i_ship_tab.FIRST .. i_ship_tab.LAST LOOP
      --移動元倉庫のロット別在庫を取得
      <<xliv_loop>>
      FOR l_xliv_rec IN xliv_cur(i_item_rec.item_id
                               , i_ship_tab(ln_ship_idx).loct_id
                               , i_ship_tab(ln_ship_idx).target_date
                               , i_gfqt_tab(1).sy_manufacture_date
      ) LOOP
        --移動先倉庫の鮮度条件に合致するか判定
        <<gsqt_loop>>
        FOR ln_gsqt_idx IN i_gfqt_tab.FIRST .. i_gfqt_tab.LAST LOOP
          --鮮度条件基準日取得関数
          ld_critical_date := xxcop_common_pkg2.get_critical_date_f(
                                 iv_freshness_class        => i_gfqt_tab(ln_gsqt_idx).freshness_class
                                ,in_freshness_check_value  => i_gfqt_tab(ln_gsqt_idx).freshness_check_value
                                ,in_freshness_adjust_value => i_gfqt_tab(ln_gsqt_idx).freshness_adjust_value
                                ,in_max_stock_days         => i_gfqt_tab(ln_gsqt_idx).max_stock_days
                                ,in_freshness_buffer_days  => gn_freshness_buffer_days
                                ,id_manufacture_date       => l_xliv_rec.manufacture_date
                                ,id_expiration_date        => l_xliv_rec.expiration_date
                              );
          --鮮度条件に合致した場合
          IF (i_ship_tab(ln_ship_idx).target_date <= ld_critical_date) THEN
            l_glpt_tab(ln_ship_idx).manufacture_date := l_xliv_rec.manufacture_date;
            IF (i_ship_tab(ln_ship_idx).shipping_pace = 0) THEN
              l_glpt_tab(ln_ship_idx).stock_days     := l_xliv_rec.loct_onhand;
            ELSE
              l_glpt_tab(ln_ship_idx).stock_days     := TRUNC(l_xliv_rec.loct_onhand
                                                            / i_ship_tab(ln_ship_idx).shipping_pace
                                                            , 2
                                                        );
            END IF;
            l_glpt_tab(ln_ship_idx).delivery_lead_time := i_ship_tab(ln_ship_idx).delivery_lead_time;
            EXIT xliv_loop;
          END IF;
        END LOOP gsqt_loop;
      END LOOP xliv_loop;
      IF (NOT l_glpt_tab.EXISTS(ln_ship_idx)) THEN
        l_glpt_tab(ln_ship_idx).manufacture_date   := cd_upper_limit_date;
        l_glpt_tab(ln_ship_idx).stock_days         := 0;
        l_glpt_tab(ln_ship_idx).delivery_lead_time := i_ship_tab(ln_ship_idx).delivery_lead_time;
      END IF;
    END LOOP ship_loop;
--
    --移動元倉庫の優先順位を決定
    <<priority_loop>>
    FOR ln_priority_idx IN 1 .. l_glpt_tab.COUNT LOOP
      ln_glpt_idx                := l_glpt_tab.FIRST;
      o_git_tab(ln_priority_idx) := l_glpt_tab.FIRST;
      <<glpt_loop>>
      LOOP
        IF (ln_glpt_idx IS NULL) THEN
          EXIT glpt_loop;
        END IF;
        --ロットの製造年月日で判定
        CASE
          WHEN (l_glpt_tab(o_git_tab(ln_priority_idx)).manufacture_date
              > l_glpt_tab(ln_glpt_idx).manufacture_date)
            THEN
              o_git_tab(ln_priority_idx)  := ln_glpt_idx;
          WHEN (l_glpt_tab(o_git_tab(ln_priority_idx)).manufacture_date
              = l_glpt_tab(ln_glpt_idx).manufacture_date)
            THEN
              --ロットの製造年月日が同じ場合、在庫日数で判定
              CASE
                WHEN (l_glpt_tab(o_git_tab(ln_priority_idx)).stock_days
                    < l_glpt_tab(ln_glpt_idx).stock_days)
                  THEN
                    o_git_tab(ln_priority_idx)  := ln_glpt_idx;
                WHEN (l_glpt_tab(o_git_tab(ln_priority_idx)).stock_days
                    = l_glpt_tab(ln_glpt_idx).stock_days)
                  THEN
                    --在庫日数が同じ場合、配送リードタイムで判定
                    CASE
                      WHEN (l_glpt_tab(o_git_tab(ln_priority_idx)).delivery_lead_time
                          > l_glpt_tab(ln_glpt_idx).delivery_lead_time)
                        THEN
                          o_git_tab(ln_priority_idx)  := ln_glpt_idx;
                        ELSE
                          NULL;
                    END CASE;
                ELSE
                  NULL;
              END CASE;
          ELSE
            NULL;
        END CASE;
        ln_glpt_idx := l_glpt_tab.NEXT(ln_glpt_idx);
      END LOOP glpt_loop;
      l_glpt_tab.DELETE(o_git_tab(ln_priority_idx));
    END LOOP priority_loop;
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
  END proc_ship_loct;
--
  /**********************************************************************************
   * Procedure Name   : proc_safety_quantity
   * Description      : 安全在庫の計算(B-17)
   ***********************************************************************************/
  PROCEDURE proc_safety_quantity(
    iv_assign_type   IN     VARCHAR2,       --   割当セット区分
    it_loct_id       IN     xxcop_wk_yoko_planning.rcpt_loct_id%TYPE,
    i_item_rec       IN     g_item_rtype,   --   品目レコード型
    io_gfqt_tab      IN OUT g_fq_ttype,     --   鮮度条件別在庫引当コレクション型
    ov_stock_result  OUT    VARCHAR2,       --   安全在庫の引当ステータス
    ov_errbuf        OUT    VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT    VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg        OUT    VARCHAR2        --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_safety_quantity'; -- プログラム名
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
    ld_critical_date          DATE;         --鮮度条件基準日
    ln_allocate_quantity      NUMBER;       --引当数
    ln_safety_fill            NUMBER;       --安全在庫数を満たした鮮度条件のカウント
--20100107_Ver3.2_E_本稼動_00936_SCS.Goto_DEL_START
--    ln_max_fill               NUMBER;       --最大在庫数を満たした鮮度条件のカウント
--20100107_Ver3.2_E_本稼動_00936_SCS.Goto_DEL_END
    ln_exists                 NUMBER;
    ln_stock_quantity         NUMBER;       --引当在庫数合計
--
    -- *** ローカル・カーソル ***
    --在庫の取得
    CURSOR xliv_cur(
       in_item_id             NUMBER
      ,in_loct_id             NUMBER
    ) IS
      SELECT xliv.lot_id                                      lot_id
            ,xliv.lot_no                                      lot_no
            ,xliv.manufacture_date                            manufacture_date
            ,xliv.expiration_date                             expiration_date
            ,xliv.unique_sign                                 unique_sign
            ,xliv.lot_status                                  lot_status
            ,CASE WHEN SUM(xliv.unlimited_loct_onhand) < SUM(xliv.limited_loct_onhand)
               THEN SUM(xliv.unlimited_loct_onhand)
               ELSE SUM(xliv.limited_loct_onhand)
             END                                              loct_onhand
      FROM (
        SELECT /*+ LEADING(xwyl) */
               xli.lot_id                                     lot_id
              ,xli.lot_no                                     lot_no
              ,xli.manufacture_date                           manufacture_date
              ,xli.expiration_date                            expiration_date
              ,xli.unique_sign                                unique_sign
              ,xli.lot_status                                 lot_status
              ,xli.loct_onhand                                unlimited_loct_onhand
              ,CASE WHEN xli.schedule_date <= gd_planning_date
                 THEN xli.loct_onhand
                 ELSE 0
               END                                            limited_loct_onhand
        FROM xxcop_loct_inv          xli
            ,xxcop_wk_yoko_locations xwyl
        WHERE xli.transaction_id      = gn_transaction_id
          AND xli.request_id          = cn_request_id
          AND xli.item_id             = xwyl.item_id
          AND xli.loct_id             = xwyl.loct_id
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_MOD_START
--          AND xli.shipment_date      <= gd_allocated_date
          AND xli.shipment_date      <= GREATEST(gd_allocated_date, gd_planning_date)
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_MOD_END
          AND xli.transaction_type  NOT IN (cv_xli_type_bq)
          AND xwyl.transaction_id     = gn_transaction_id
          AND xwyl.request_id         = cn_request_id
          AND xwyl.item_id            = in_item_id
          AND xwyl.frq_loct_id        = in_loct_id
        UNION ALL
        SELECT xli.lot_id                                     lot_id
              ,xli.lot_no                                     lot_no
              ,xli.manufacture_date                           manufacture_date
              ,xli.expiration_date                            expiration_date
              ,xli.unique_sign                                unique_sign
              ,xli.lot_status                                 lot_status
              ,LEAST(xli.loct_onhand, 0)                      unlimited_loct_onhand
              ,CASE WHEN xli.schedule_date <= gd_planning_date
                 THEN LEAST(xli.loct_onhand, 0)
                 ELSE 0
               END                                            limited_loct_onhand
        FROM (
          SELECT /*+ LEADING(xwyl) */
                 xli.lot_id                                   lot_id
                ,xli.lot_no                                   lot_no
                ,xli.manufacture_date                         manufacture_date
                ,xli.expiration_date                          expiration_date
                ,xli.unique_sign                              unique_sign
                ,xli.lot_status                               lot_status
                ,xli.schedule_date                            schedule_date
                ,SUM(xli.loct_onhand)                         loct_onhand
          FROM xxcop_loct_inv          xli
              ,xxcop_wk_yoko_locations xwyl
          WHERE xli.transaction_id      = gn_transaction_id
            AND xli.request_id          = cn_request_id
            AND xli.item_id             = xwyl.item_id
            AND xli.loct_id             = xwyl.frq_loct_id
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_MOD_START
--            AND xli.shipment_date      <= gd_allocated_date
            AND xli.shipment_date      <= GREATEST(gd_allocated_date, gd_planning_date)
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_MOD_END
            AND xli.transaction_type  NOT IN (cv_xli_type_bq)
            AND xwyl.transaction_id     = gn_transaction_id
            AND xwyl.request_id         = cn_request_id
            AND xwyl.frq_loct_id       <> xwyl.loct_id
            AND xwyl.item_id            = in_item_id
            AND xwyl.loct_id            = in_loct_id
          GROUP BY xli.lot_id
                  ,xli.lot_no
                  ,xli.manufacture_date
                  ,xli.expiration_date
                  ,xli.unique_sign
                  ,xli.lot_status
                  ,xli.schedule_date
        ) xli
      ) xliv
      GROUP BY xliv.lot_id
              ,xliv.lot_no
              ,xliv.manufacture_date
              ,xliv.expiration_date
              ,xliv.unique_sign
              ,xliv.lot_status
      ORDER BY xliv.manufacture_date
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
    --ローカル変数の初期化
    ld_critical_date          := NULL;
    ln_allocate_quantity      := NULL;
    ln_safety_fill            := NULL;
--20100107_Ver3.2_E_本稼動_00936_SCS.Goto_DEL_START
--    ln_max_fill               := NULL;
--20100107_Ver3.2_E_本稼動_00936_SCS.Goto_DEL_END
    ln_exists                 := NULL;
    ln_stock_quantity         := 0;
--
    ov_stock_result           := cv_shortage;
--
    --特別横持計画かつ移動数が設定数以上の場合、計画を立てない
    IF (iv_assign_type = cv_custom_plan) THEN
      SELECT COUNT(*)
      INTO ln_exists
      FROM xxcop_wk_yoko_planning xwyp
      WHERE xwyp.transaction_id       = gn_transaction_id
        AND xwyp.request_id           = cn_request_id
        AND xwyp.planning_flag        = cv_planning_yes
        AND xwyp.assignment_set_type  = cv_custom_plan
        AND xwyp.rcpt_loct_id         = it_loct_id
        AND xwyp.item_id              = i_item_rec.item_id
        AND xwyp.sy_maxmum_quantity  IS NOT NULL
        AND xwyp.sy_maxmum_quantity  <= xwyp.sy_stocked_quantity
      ;
      IF (ln_exists > 0) THEN
        ov_stock_result := cv_enough;
        RETURN;
      END IF;
    END IF;
--
    --手持在庫の取得
    <<xliv_loop>>
    FOR l_xliv_rec IN xliv_cur(i_item_rec.item_id
                             , it_loct_id
    ) LOOP
      BEGIN
        --ロット在庫数が0の場合、スキップ
        IF (l_xliv_rec.loct_onhand = 0) THEN
          RAISE lot_skip_expt;
        END IF;
--
        --デバックメッセージ出力(安全在庫ロット)
        xxcop_common_pkg.put_debug_message(
           iov_debug_mode => gv_debug_mode
          ,iv_value       => cv_indent_2 || cv_prg_name || ':'
                          || 'safety_stock_quantity(lot):'
                          || xliv_cur%ROWCOUNT || ','
                          || TO_CHAR(l_xliv_rec.manufacture_date, cv_date_format) || ','
                          || l_xliv_rec.unique_sign                               || ','
                          || TO_CHAR(l_xliv_rec.expiration_date , cv_date_format) || ','
                          || l_xliv_rec.loct_onhand                               || ','
        );
        ln_safety_fill := 0;
--20100107_Ver3.2_E_本稼動_00936_SCS.Goto_DEL_START
--        ln_max_fill    := 0;
--20100107_Ver3.2_E_本稼動_00936_SCS.Goto_DEL_END
        --優先順位の低い順に鮮度条件に合致するかチェック
        <<gsqt_loop>>
        FOR ln_gsqt_idx IN io_gfqt_tab.FIRST .. io_gfqt_tab.LAST LOOP
--20100107_Ver3.2_E_本稼動_00936_SCS.Goto_MOD_START
--          --引当数が最大在庫数より小さい場合、鮮度条件に合致するかチェック
--          IF (io_gfqt_tab(ln_gsqt_idx).max_stock_quantity > io_gfqt_tab(ln_gsqt_idx).allocate_quantity) THEN
          --引当数が安全在庫数より小さい場合、鮮度条件に合致するかチェック
          IF (io_gfqt_tab(ln_gsqt_idx).safety_stock_quantity > io_gfqt_tab(ln_gsqt_idx).allocate_quantity) THEN
--20100107_Ver3.2_E_本稼動_00936_SCS.Goto_MOD_END
            --鮮度条件基準日取得関数
            ld_critical_date := xxcop_common_pkg2.get_critical_date_f(
                                   iv_freshness_class        => io_gfqt_tab(ln_gsqt_idx).freshness_class
                                  ,in_freshness_check_value  => io_gfqt_tab(ln_gsqt_idx).freshness_check_value
                                  ,in_freshness_adjust_value => io_gfqt_tab(ln_gsqt_idx).freshness_adjust_value
                                  ,in_max_stock_days         => io_gfqt_tab(ln_gsqt_idx).max_stock_days
                                  ,in_freshness_buffer_days  => gn_freshness_buffer_days
                                  ,id_manufacture_date       => l_xliv_rec.manufacture_date
                                  ,id_expiration_date        => l_xliv_rec.expiration_date
                                );
            --鮮度条件に合致した場合、鮮度条件に引当
            IF (gd_planning_date <= ld_critical_date) THEN
--20100107_Ver3.2_E_本稼動_00936_SCS.Goto_MOD_START
--              --引当数を計算
--              ln_allocate_quantity := LEAST((io_gfqt_tab(ln_gsqt_idx).max_stock_quantity
--                                           - io_gfqt_tab(ln_gsqt_idx).allocate_quantity)
--                                           , l_xliv_rec.loct_onhand
--                                      );
              --安全在庫数まで引当数を計算
              ln_allocate_quantity := LEAST((io_gfqt_tab(ln_gsqt_idx).safety_stock_quantity
                                           - io_gfqt_tab(ln_gsqt_idx).allocate_quantity)
                                           , l_xliv_rec.loct_onhand
                                      );
--20100107_Ver3.2_E_本稼動_00936_SCS.Goto_MOD_END
              io_gfqt_tab(ln_gsqt_idx).allocate_quantity := io_gfqt_tab(ln_gsqt_idx).allocate_quantity
                                                          + ln_allocate_quantity;
              l_xliv_rec.loct_onhand := l_xliv_rec.loct_onhand - ln_allocate_quantity;
              ln_stock_quantity      := ln_stock_quantity + ln_allocate_quantity;
            END IF;
          END IF;
          --安全在庫数以上引当された場合
          IF (io_gfqt_tab(ln_gsqt_idx).safety_stock_quantity <= io_gfqt_tab(ln_gsqt_idx).allocate_quantity) THEN
            ln_safety_fill := ln_safety_fill + 1;
          END IF;
--20100107_Ver3.2_E_本稼動_00936_SCS.Goto_DEL_START
--          --最大在庫数以上引当された場合
--          IF (io_gfqt_tab(ln_gsqt_idx).max_stock_quantity    <= io_gfqt_tab(ln_gsqt_idx).allocate_quantity) THEN
--            ln_max_fill := ln_max_fill + 1;
--          END IF;
--20100107_Ver3.2_E_本稼動_00936_SCS.Goto_DEL_END
          --引当後のロット在庫数が0の場合は次のロット
          IF (l_xliv_rec.loct_onhand = 0) THEN
            EXIT gsqt_loop;
          END IF;
        END LOOP gsqt_loop;
--20100107_Ver3.2_E_本稼動_00936_SCS.Goto_MOD_START
--        --全ての鮮度条件で最大在庫数まで引当した場合、終了
--        IF (io_gfqt_tab.COUNT = ln_max_fill) THEN
--          ov_stock_result := cv_enough;
--          EXIT xliv_loop;
--        END IF;
        --全ての鮮度条件で安全在庫数まで引当した場合、終了
        IF (io_gfqt_tab.COUNT = ln_safety_fill) THEN
          ov_stock_result := cv_enough;
          EXIT xliv_loop;
        END IF;
--20100107_Ver3.2_E_本稼動_00936_SCS.Goto_MOD_END
      EXCEPTION
        WHEN lot_skip_expt THEN
          NULL;
      END;
    END LOOP xliv_loop;
    --安全在庫を満たしている場合、横持計画を作成しない
    IF (io_gfqt_tab.COUNT = ln_safety_fill) THEN
      ov_stock_result := cv_enough;
    END IF;
    --デバックメッセージ出力(安全在庫)
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => cv_indent_2 || cv_prg_name || ':'
                      || 'safety_stock_quantity:'
                      || ln_safety_fill             || ','
                      || ln_stock_quantity          || ','
    );
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
  END proc_safety_quantity;
--
  /**********************************************************************************
   * Procedure Name   : entry_xli_shipment
   * Description      : 横持計画手持在庫テーブル登録(出荷ペース)(B-16)
   ***********************************************************************************/
  PROCEDURE entry_xli_shipment(
    it_shipment_date IN     xxcop_loct_inv.schedule_date%TYPE,
    io_gsat_tab      IN OUT g_sa_ttype,     --   出荷ペース在庫引当コレクション型
    ov_errbuf        OUT    VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT    VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg        OUT    VARCHAR2        --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'entry_xli_shipment'; -- プログラム名
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
    ld_critical_date          DATE;         --鮮度条件基準日
    ln_allocate_quantity      NUMBER;       --引当数
    ln_alloc_fill             NUMBER;       --最大在庫数を満たした鮮度条件のカウント
--
    -- *** ローカル・カーソル ***
    --在庫の取得
    CURSOR xliv_cur(
       in_item_id             NUMBER
      ,in_loct_id             NUMBER
    ) IS
      SELECT xliv.lot_id                                      lot_id
            ,xliv.lot_no                                      lot_no
            ,xliv.manufacture_date                            manufacture_date
            ,xliv.expiration_date                             expiration_date
            ,xliv.unique_sign                                 unique_sign
            ,xliv.lot_status                                  lot_status
            ,CASE WHEN SUM(xliv.unlimited_loct_onhand) < SUM(xliv.limited_loct_onhand)
               THEN SUM(xliv.unlimited_loct_onhand)
               ELSE SUM(xliv.limited_loct_onhand)
             END                                              loct_onhand
      FROM (
        SELECT /*+ LEADING(xwyl) */
               xli.lot_id                                     lot_id
              ,xli.lot_no                                     lot_no
              ,xli.manufacture_date                           manufacture_date
              ,xli.expiration_date                            expiration_date
              ,xli.unique_sign                                unique_sign
              ,xli.lot_status                                 lot_status
              ,xli.loct_onhand                                unlimited_loct_onhand
--20100210_Ver3.5_E_本稼動_01560_SCS.Goto_MOD_START
--              ,CASE WHEN xli.schedule_date <= it_shipment_date
--                 THEN xli.loct_onhand
--                 ELSE 0
--               END                                            limited_loct_onhand
              ,CASE WHEN xli.schedule_date <= it_shipment_date AND xli.transaction_type NOT IN (cv_xli_type_lq)
                      THEN xli.loct_onhand
                    WHEN xli.schedule_date <  it_shipment_date AND xli.transaction_type IN (cv_xli_type_lq)
                      THEN xli.loct_onhand
                    ELSE 0
               END                                            limited_loct_onhand
--20100210_Ver3.5_E_本稼動_01560_SCS.Goto_MOD_END
        FROM xxcop_loct_inv          xli
            ,xxcop_wk_yoko_locations xwyl
        WHERE xli.transaction_id      = gn_transaction_id
          AND xli.request_id          = cn_request_id
          AND xli.item_id             = xwyl.item_id
          AND xli.loct_id             = xwyl.loct_id
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_DEL_START
--          AND xli.shipment_date      <= gd_allocated_date
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_DEL_END
          AND xli.transaction_type  NOT IN (cv_xli_type_bq)
          AND xwyl.transaction_id     = gn_transaction_id
          AND xwyl.request_id         = cn_request_id
          AND xwyl.item_id            = in_item_id
          AND xwyl.frq_loct_id        = in_loct_id
        UNION ALL
        SELECT xli.lot_id                                     lot_id
              ,xli.lot_no                                     lot_no
              ,xli.manufacture_date                           manufacture_date
              ,xli.expiration_date                            expiration_date
              ,xli.unique_sign                                unique_sign
              ,xli.lot_status                                 lot_status
              ,LEAST(xli.loct_onhand, 0)                      unlimited_loct_onhand
              ,CASE WHEN xli.schedule_date <= it_shipment_date
                 THEN LEAST(xli.loct_onhand, 0)
                 ELSE 0
               END                                            limited_loct_onhand
        FROM (
          SELECT /*+ LEADING(xwyl) */
                 xli.lot_id                                   lot_id
                ,xli.lot_no                                   lot_no
                ,xli.manufacture_date                         manufacture_date
                ,xli.expiration_date                          expiration_date
                ,xli.unique_sign                              unique_sign
                ,xli.lot_status                               lot_status
                ,xli.schedule_date                            schedule_date
                ,SUM(xli.loct_onhand)                         loct_onhand
          FROM xxcop_loct_inv          xli
              ,xxcop_wk_yoko_locations xwyl
          WHERE xli.transaction_id      = gn_transaction_id
            AND xli.request_id          = cn_request_id
            AND xli.item_id             = xwyl.item_id
            AND xli.loct_id             = xwyl.frq_loct_id
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_DEL_START
--            AND xli.shipment_date      <= gd_allocated_date
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_DEL_END
            AND xli.transaction_type  NOT IN (cv_xli_type_bq)
            AND xwyl.transaction_id     = gn_transaction_id
            AND xwyl.request_id         = cn_request_id
            AND xwyl.frq_loct_id       <> xwyl.loct_id
            AND xwyl.item_id            = in_item_id
            AND xwyl.loct_id            = in_loct_id
          GROUP BY xli.lot_id
                  ,xli.lot_no
                  ,xli.manufacture_date
                  ,xli.expiration_date
                  ,xli.unique_sign
                  ,xli.lot_status
                  ,xli.schedule_date
        ) xli
      ) xliv
      GROUP BY xliv.lot_id
              ,xliv.lot_no
              ,xliv.manufacture_date
              ,xliv.expiration_date
              ,xliv.unique_sign
              ,xliv.lot_status
      ORDER BY xliv.manufacture_date
    ;
--
    -- *** ローカル・レコード ***
    l_xli_rec                 xxcop_loct_inv%ROWTYPE;
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
    --初期化
    ld_critical_date          := NULL;
    ln_allocate_quantity      := 0;
    ln_alloc_fill             := 0;
    l_xli_rec                 := NULL;
--
    --要求固定値を出力レコード型にセット
    l_xli_rec.transaction_id               := gn_transaction_id;
    l_xli_rec.created_by                   := cn_created_by;
    l_xli_rec.creation_date                := cd_creation_date;
    l_xli_rec.last_updated_by              := cn_last_updated_by;
    l_xli_rec.last_update_date             := cd_last_update_date;
    l_xli_rec.last_update_login            := cn_last_update_login;
    l_xli_rec.request_id                   := cn_request_id;
    l_xli_rec.program_application_id       := cn_program_application_id;
    l_xli_rec.program_id                   := cn_program_id;
    l_xli_rec.program_update_date          := cd_program_update_date;
--
    --倉庫、品目を出力レコード型にセット
    l_xli_rec.loct_id                      := io_gsat_tab(1).rcpt_loct_id;
    l_xli_rec.loct_code                    := io_gsat_tab(1).rcpt_loct_code;
    l_xli_rec.organization_id              := io_gsat_tab(1).rcpt_organization_id;
    l_xli_rec.organization_code            := io_gsat_tab(1).rcpt_organization_code;
    l_xli_rec.item_id                      := io_gsat_tab(1).item_id;
    l_xli_rec.item_no                      := io_gsat_tab(1).item_no;
    --引当数の初期化
    <<init_loop>>
    FOR ln_gsat_idx IN io_gsat_tab.FIRST .. io_gsat_tab.LAST LOOP
      io_gsat_tab(ln_gsat_idx).allocate_quantity := 0;
    END LOOP init_loop;
--
    --在庫を取得
    <<xliv_loop>>
    FOR l_xliv_rec IN xliv_cur(io_gsat_tab(1).item_id
                             , io_gsat_tab(1).rcpt_loct_id
    ) LOOP
      BEGIN
        --ロット在庫数が0以下の場合、スキップ
        IF (l_xliv_rec.loct_onhand <= 0) THEN
          RAISE lot_skip_expt;
        END IF;
--
        ln_alloc_fill  := 0;
        --移動先倉庫の鮮度条件に合致するか判定
        <<gsat_loop>>
        FOR ln_gsat_idx IN io_gsat_tab.FIRST .. io_gsat_tab.LAST LOOP
          --引当数が出荷ペースより小さい場合、鮮度条件に合致するかチェック
          IF (io_gsat_tab(ln_gsat_idx).shipping_pace > io_gsat_tab(ln_gsat_idx).allocate_quantity) THEN
            --鮮度条件基準日取得関数
            ld_critical_date := xxcop_common_pkg2.get_critical_date_f(
                                   iv_freshness_class        => io_gsat_tab(ln_gsat_idx).freshness_class
                                  ,in_freshness_check_value  => io_gsat_tab(ln_gsat_idx).freshness_check_value
                                  ,in_freshness_adjust_value => io_gsat_tab(ln_gsat_idx).freshness_adjust_value
                                  ,in_max_stock_days         => io_gsat_tab(ln_gsat_idx).max_stock_days
                                  ,in_freshness_buffer_days  => gn_freshness_buffer_days
                                  ,id_manufacture_date       => l_xliv_rec.manufacture_date
                                  ,id_expiration_date        => l_xliv_rec.expiration_date
                                );
            --鮮度条件に合致した場合、鮮度条件に引当
            IF (it_shipment_date <= ld_critical_date) THEN
              --引当数を計算
              ln_allocate_quantity := LEAST((io_gsat_tab(ln_gsat_idx).shipping_pace
                                           - io_gsat_tab(ln_gsat_idx).allocate_quantity)
                                          , l_xliv_rec.loct_onhand
                                      );
              io_gsat_tab(ln_gsat_idx).allocate_quantity := io_gsat_tab(ln_gsat_idx).allocate_quantity
                                                          + ln_allocate_quantity;
              l_xliv_rec.loct_onhand := l_xliv_rec.loct_onhand - ln_allocate_quantity;
              BEGIN
                --ロット情報を出力レコード型にセット
                l_xli_rec.lot_id             := l_xliv_rec.lot_id;
                l_xli_rec.lot_no             := l_xliv_rec.lot_no;
                l_xli_rec.manufacture_date   := l_xliv_rec.manufacture_date;
                l_xli_rec.expiration_date    := l_xliv_rec.expiration_date;
                l_xli_rec.unique_sign        := l_xliv_rec.unique_sign;
                l_xli_rec.lot_status         := l_xliv_rec.lot_status;
                l_xli_rec.loct_onhand        := ln_allocate_quantity * -1;
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_MOD_START
--                l_xli_rec.schedule_date      := it_shipment_date;
--                l_xli_rec.shipment_date      := cd_lower_limit_date;
                l_xli_rec.schedule_date      := cd_lower_limit_date;
                l_xli_rec.shipment_date      := it_shipment_date;
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_MOD_END
                l_xli_rec.transaction_type   := cv_xli_type_sp;
                --出荷ペースを横持計画手持在庫テーブルに登録
                INSERT INTO xxcop_loct_inv VALUES l_xli_rec;
              EXCEPTION
                WHEN OTHERS THEN
                  lv_errbuf := SQLERRM;
                  lv_errmsg := xxccp_common_pkg.get_msg(
                                  iv_application  => cv_msg_appl_cont
                                 ,iv_name         => cv_msg_00027
                                 ,iv_token_name1  => cv_msg_00027_token_1
                                 ,iv_token_value1 => cv_table_xli
                               );
                  RAISE global_api_expt;
              END;
            END IF;
          END IF;
          --出荷ペース以上引当されたか確認
          IF (io_gsat_tab(ln_gsat_idx).shipping_pace <= io_gsat_tab(ln_gsat_idx).allocate_quantity) THEN
            ln_alloc_fill := ln_alloc_fill + 1;
          END IF;
          --引当後のロット在庫数が0の場合は次のロット
          IF (l_xliv_rec.loct_onhand = 0) THEN
            EXIT gsat_loop;
          END IF;
        END LOOP gsat_loop;
        --全ての鮮度条件で出荷ペースまで引当した場合、終了
        IF (io_gsat_tab.COUNT = ln_alloc_fill) THEN
          EXIT xliv_loop;
        END IF;
      EXCEPTION
        WHEN lot_skip_expt THEN
          NULL;
      END;
    END LOOP xliv_loop;
--20100210_Ver3.5_E_本稼動_01560_SCS.Goto_DEL_START
--    --ロットに引当出来ない鮮度条件がある場合、ロット情報なしで横持計画手持在庫テーブルに登録
--    IF (io_gsat_tab.COUNT > ln_alloc_fill) THEN
--      --ロット情報をクリア
--      l_xli_rec.lot_id             := NULL;
--      l_xli_rec.lot_no             := NULL;
--      l_xli_rec.manufacture_date   := cd_upper_limit_date;
--      l_xli_rec.expiration_date    := NULL;
--      l_xli_rec.unique_sign        := NULL;
--      l_xli_rec.lot_status         := NULL;
----20100125_Ver3.3_E_本稼動_01250_SCS.Goto_MOD_START
----      l_xli_rec.schedule_date      := it_shipment_date;
----      l_xli_rec.shipment_date      := cd_lower_limit_date;
--      l_xli_rec.schedule_date      := cd_lower_limit_date;
--      l_xli_rec.shipment_date      := it_shipment_date;
----20100125_Ver3.3_E_本稼動_01250_SCS.Goto_MOD_END
--      l_xli_rec.transaction_type   := cv_xli_type_sp;
--      <<no_lot_loop>>
--      FOR ln_gsat_idx IN io_gsat_tab.FIRST .. io_gsat_tab.LAST LOOP
--        BEGIN
--          IF (io_gsat_tab(ln_gsat_idx).shipping_pace > io_gsat_tab(ln_gsat_idx).allocate_quantity) THEN
--            l_xli_rec.loct_onhand  := (io_gsat_tab(ln_gsat_idx).shipping_pace
--                                     - io_gsat_tab(ln_gsat_idx).allocate_quantity)
--                                     * -1;
--            INSERT INTO xxcop_loct_inv VALUES l_xli_rec;
--          END IF;
--        EXCEPTION
--          WHEN OTHERS THEN
--            lv_errbuf := SQLERRM;
--            lv_errmsg := xxccp_common_pkg.get_msg(
--                            iv_application  => cv_msg_appl_cont
--                           ,iv_name         => cv_msg_00027
--                           ,iv_token_name1  => cv_msg_00027_token_1
--                           ,iv_token_value1 => cv_table_xli
--                         );
--            RAISE global_api_expt;
--        END;
--      END LOOP no_lot_loop;
--    END IF;
--20100210_Ver3.5_E_本稼動_01560_SCS.Goto_DEL_END
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
  END entry_xli_shipment;
--
  /**********************************************************************************
   * Procedure Name   : entry_xli_po
   * Description      : 横持計画手持在庫テーブル登録(購入計画)(B-15)
   ***********************************************************************************/
  PROCEDURE entry_xli_po(
    ov_errbuf        OUT    VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT    VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg        OUT    VARCHAR2        --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'entry_xli_po'; -- プログラム名
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
    ln_entry_xli              NUMBER;
--
    -- *** ローカル・カーソル ***
    --購入計画の取得
    CURSOR msd_po_sched_cur IS
      SELECT msi.organization_id                              organization_id
            ,msi.inventory_item_id                            inventory_item_id
      FROM mrp_schedule_designators ms
          ,mrp_schedule_items       msi
      WHERE ms.attribute1           = cv_msd_po_sched
        AND msi.schedule_designator = ms.schedule_designator
        AND msi.organization_id     = ms.organization_id
        AND EXISTS(
              SELECT 'X'
              FROM mrp_schedule_dates msd
              WHERE msd.schedule_designator = ms.schedule_designator
                AND msd.organization_id     = ms.organization_id
                AND msd.inventory_item_id   = msi.inventory_item_id
                AND msd.schedule_level      = cn_schedule_level
            )
        AND EXISTS(
              SELECT 'X'
              FROM xxcop_wk_yoko_planning xwyp
              WHERE xwyp.transaction_id     = gn_transaction_id
                AND xwyp.request_id         = cn_request_id
                AND xwyp.planning_flag      = cv_planning_yes
                AND xwyp.inventory_item_id  = msi.inventory_item_id
            )
      GROUP BY msi.organization_id
              ,msi.inventory_item_id
    ;
--
    -- *** ローカル・レコード ***
    l_xwyp_rec                xxcop_wk_yoko_planning%ROWTYPE;
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
    --初期化
    ln_entry_xli              := 0;
    l_xwyp_rec                := NULL;
--
    OPEN msd_po_sched_cur;
    <<msd_po_sched_loop>>
    LOOP
      BEGIN
        --購入計画の取得
        FETCH msd_po_sched_cur INTO l_xwyp_rec.rcpt_organization_id
                                   ,l_xwyp_rec.inventory_item_id
        ;
        EXIT WHEN msd_po_sched_cur%NOTFOUND;
          --品目情報を取得
          xxcop_common_pkg2.get_item_info(
             id_target_date           => gd_process_date
            ,in_organization_id       => l_xwyp_rec.rcpt_organization_id
            ,in_inventory_item_id     => l_xwyp_rec.inventory_item_id
            ,on_item_id               => l_xwyp_rec.item_id
            ,ov_item_no               => l_xwyp_rec.item_no
            ,ov_item_name             => l_xwyp_rec.item_name
            ,on_num_of_case           => l_xwyp_rec.num_of_case
            ,on_palette_max_cs_qty    => l_xwyp_rec.palette_max_cs_qty
            ,on_palette_max_step_qty  => l_xwyp_rec.palette_max_step_qty
            ,ov_errbuf                => lv_errbuf
            ,ov_retcode               => lv_retcode
            ,ov_errmsg                => lv_errmsg
          );
          --品目情報が取得できない品目は対象外
          IF (lv_retcode = cv_status_error) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_appl_cont
                           ,iv_name         => cv_msg_00049
                           ,iv_token_name1  => cv_msg_00049_token_1
                           ,iv_token_value1 => l_xwyp_rec.inventory_item_id
                         );
            RAISE global_api_expt;
          ELSIF (lv_retcode = cv_status_warn) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_appl_cont
                           ,iv_name         => cv_msg_00049
                           ,iv_token_name1  => cv_msg_00049_token_1
                           ,iv_token_value1 => l_xwyp_rec.item_no
                         );
            --警告件数を加算
            gn_warn_cnt := gn_warn_cnt + 1;
            --ログに警告メッセージを出力
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff => lv_errmsg
            );
            RAISE outside_scope_expt;
          END IF;
          --入庫倉庫情報を取得
          xxcop_common_pkg2.get_loct_info(
             id_target_date           => gd_process_date
            ,in_organization_id       => l_xwyp_rec.rcpt_organization_id
            ,ov_organization_code     => l_xwyp_rec.rcpt_organization_code
            ,ov_organization_name     => l_xwyp_rec.rcpt_organization_name
            ,on_loct_id               => l_xwyp_rec.rcpt_loct_id
            ,ov_loct_code             => l_xwyp_rec.rcpt_loct_code
            ,ov_loct_name             => l_xwyp_rec.rcpt_loct_name
            ,ov_calendar_code         => l_xwyp_rec.rcpt_calendar_code
            ,ov_errbuf                => lv_errbuf
            ,ov_retcode               => lv_retcode
            ,ov_errmsg                => lv_errmsg
          );
          --入庫倉庫情報が取得できない倉庫は対象外
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_api_expt;
          ELSIF (lv_retcode = cv_status_warn) THEN
            RAISE outside_scope_expt;
          END IF;
--
          --最終購入日以降の購入計画を取得し、横持計画手持在庫テーブルに登録
          INSERT INTO xxcop_loct_inv (
             transaction_id
            ,loct_id
            ,loct_code
            ,organization_id
            ,organization_code
            ,item_id
            ,item_no
            ,lot_id
            ,lot_no
            ,manufacture_date
            ,expiration_date
            ,unique_sign
            ,lot_status
            ,loct_onhand
            ,schedule_date
            ,shipment_date
            ,voucher_no
            ,transaction_type
            ,simulate_flag
            ,created_by
            ,creation_date
            ,last_updated_by
            ,last_update_date
            ,last_update_login
            ,request_id
            ,program_application_id
            ,program_id
            ,program_update_date
          )
          SELECT gn_transaction_id                            transaction_id
                ,l_xwyp_rec.rcpt_loct_id                      loct_id
                ,l_xwyp_rec.rcpt_loct_code                    loct_code
                ,l_xwyp_rec.rcpt_organization_id              organization_id
                ,l_xwyp_rec.rcpt_organization_code            organization_code
                ,l_xwyp_rec.item_id                           item_id
                ,l_xwyp_rec.item_no                           item_no
                ,NULL                                         lot_id
                ,NULL                                         lot_no
                ,CASE
                   WHEN msd.attribute6 = cv_manufacture THEN
                     NVL(TO_DATE(msd.attribute5, cv_date_format), msd.schedule_date)
                   WHEN msd.attribute6 = cv_purchase    THEN
                     NVL(TO_DATE(msd.attribute5, cv_date_format), cd_upper_limit_date)
                 END                                          manufacture_date
                ,NULL                                         expiration_date
                ,NULL                                         unique_sign
                ,NULL                                         lot_status
                ,TRUNC(SUM(msd.schedule_quantity) / l_xwyp_rec.num_of_case)
                                                              loct_onhand
                ,msd.schedule_date                            schedule_date
                ,cd_lower_limit_date                          shipment_date
                ,NULL                                         voucher_no
                ,cv_xli_type_po                               transaction_type
                ,NULL                                         simulate_flag
                ,cn_created_by                                created_by
                ,cd_creation_date                             creation_date
                ,cn_last_updated_by                           last_updated_by
                ,cd_last_update_date                          last_update_date
                ,cn_last_update_login                         last_update_login
                ,cn_request_id                                request_id
                ,cn_program_application_id                    program_application_id
                ,cn_program_id                                program_id
                ,cd_program_update_date                       program_update_date
          FROM mrp_schedule_designators ms
              ,mrp_schedule_items       msi
              ,mrp_schedule_dates       msd
          WHERE ms.attribute1           = cv_msd_po_sched
            AND msi.schedule_designator = ms.schedule_designator
            AND msi.organization_id     = ms.organization_id
            AND msd.schedule_designator = msi.schedule_designator
            AND msd.organization_id     = msi.organization_id
            AND msd.inventory_item_id   = msi.inventory_item_id
            AND msd.schedule_level      = cn_schedule_level
            AND msd.schedule_quantity   > 0
            AND msd.attribute6         IS NOT NULL
            AND msd.organization_id     = l_xwyp_rec.rcpt_organization_id
            AND msd.inventory_item_id   = l_xwyp_rec.inventory_item_id
            AND xxcop_common_pkg2.get_last_purchase_date_f(
                   l_xwyp_rec.rcpt_loct_id
                  ,l_xwyp_rec.item_id
                ) < msd.schedule_date
          GROUP BY msd.schedule_date
                  ,msd.attribute6
                  ,msd.attribute5
          ;
          --登録件数カウント
          ln_entry_xli := ln_entry_xli + SQL%ROWCOUNT;
--
      EXCEPTION
        WHEN outside_scope_expt THEN
          NULL;
        WHEN OTHERS THEN
          lv_errbuf := SQLERRM;
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_appl_cont
                         ,iv_name         => cv_msg_00027
                         ,iv_token_name1  => cv_msg_00027_token_1
                         ,iv_token_value1 => cv_table_xli
                       );
          RAISE global_api_expt;
      END;
    END LOOP msd_po_sched_loop;
    CLOSE msd_po_sched_cur;
--
    --デバックメッセージ出力(購入計画)
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => cv_indent_2 || cv_prg_name || ':'
                      || 'entry_xli_po(COUNT):'
                      || ln_entry_xli
    );
--
  EXCEPTION
    WHEN internal_api_expt THEN
      IF (msd_po_sched_cur%ISOPEN) THEN
        CLOSE msd_po_sched_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF (msd_po_sched_cur%ISOPEN) THEN
        CLOSE msd_po_sched_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF (msd_po_sched_cur%ISOPEN) THEN
        CLOSE msd_po_sched_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (msd_po_sched_cur%ISOPEN) THEN
        CLOSE msd_po_sched_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END entry_xli_po;
--
  /**********************************************************************************
   * Procedure Name   : entry_xli_fs
   * Description      : 横持計画手持在庫テーブル登録(工場出荷計画)(B-14)
   ***********************************************************************************/
  PROCEDURE entry_xli_fs(
    ov_errbuf        OUT    VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT    VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg        OUT    VARCHAR2        --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'entry_xli_fs'; -- プログラム名
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
    ln_entry_xli              NUMBER;
--
    -- *** ローカル・カーソル ***
    --工場出荷計画
    CURSOR msd_fs_sched_cur IS
      SELECT msd.organization_id                              rcpt_organization_id
            ,mp.organization_id                               ship_organization_id
            ,msd.inventory_item_id                            inventory_item_id
      FROM mrp_schedule_designators ms
          ,mrp_schedule_items       msi
          ,mrp_schedule_dates       msd
          ,mtl_parameters           mp
      WHERE ms.attribute1           = cv_msd_fs_sched
        AND msi.schedule_designator = ms.schedule_designator
        AND msi.organization_id     = ms.organization_id
        AND msd.schedule_designator = msi.schedule_designator
        AND msd.organization_id     = msi.organization_id
        AND msd.inventory_item_id   = msi.inventory_item_id
        AND msd.schedule_level      = cn_schedule_level
        AND mp.organization_code    = msd.attribute2
        AND EXISTS(
              SELECT 'X'
              FROM xxcop_wk_yoko_planning xwyp
              WHERE xwyp.transaction_id     = gn_transaction_id
                AND xwyp.request_id         = cn_request_id
                AND xwyp.planning_flag      = cv_planning_yes
                AND xwyp.inventory_item_id  = msi.inventory_item_id
            )
      GROUP BY msd.organization_id
              ,mp.organization_id
              ,msd.inventory_item_id
    ;
--
    -- *** ローカル・レコード ***
    l_xwyp_rec                xxcop_wk_yoko_planning%ROWTYPE;
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
    --初期化
    ln_entry_xli              := 0;
    l_xwyp_rec                := NULL;
--
    OPEN msd_fs_sched_cur;
    <<msd_fs_sched_loop>>
    LOOP
      BEGIN
        --工場出荷計画の取得
        FETCH msd_fs_sched_cur INTO l_xwyp_rec.rcpt_organization_id
                                   ,l_xwyp_rec.ship_organization_id
                                   ,l_xwyp_rec.inventory_item_id
        ;
        EXIT WHEN msd_fs_sched_cur%NOTFOUND;
          --品目情報を取得
          xxcop_common_pkg2.get_item_info(
             id_target_date           => gd_process_date
            ,in_organization_id       => l_xwyp_rec.rcpt_organization_id
            ,in_inventory_item_id     => l_xwyp_rec.inventory_item_id
            ,on_item_id               => l_xwyp_rec.item_id
            ,ov_item_no               => l_xwyp_rec.item_no
            ,ov_item_name             => l_xwyp_rec.item_name
            ,on_num_of_case           => l_xwyp_rec.num_of_case
            ,on_palette_max_cs_qty    => l_xwyp_rec.palette_max_cs_qty
            ,on_palette_max_step_qty  => l_xwyp_rec.palette_max_step_qty
            ,ov_errbuf                => lv_errbuf
            ,ov_retcode               => lv_retcode
            ,ov_errmsg                => lv_errmsg
          );
          --品目情報が取得できない品目は対象外
          IF (lv_retcode = cv_status_error) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_appl_cont
                           ,iv_name         => cv_msg_00049
                           ,iv_token_name1  => cv_msg_00049_token_1
                           ,iv_token_value1 => l_xwyp_rec.inventory_item_id
                         );
            RAISE global_api_expt;
          ELSIF (lv_retcode = cv_status_warn) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_appl_cont
                           ,iv_name         => cv_msg_00049
                           ,iv_token_name1  => cv_msg_00049_token_1
                           ,iv_token_value1 => l_xwyp_rec.item_no
                         );
            --警告件数を加算
            gn_warn_cnt := gn_warn_cnt + 1;
            --ログに警告メッセージを出力
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff => lv_errmsg
            );
            RAISE outside_scope_expt;
          END IF;
          --移動先倉庫情報を取得
          xxcop_common_pkg2.get_loct_info(
             id_target_date           => gd_process_date
            ,in_organization_id       => l_xwyp_rec.rcpt_organization_id
            ,ov_organization_code     => l_xwyp_rec.rcpt_organization_code
            ,ov_organization_name     => l_xwyp_rec.rcpt_organization_name
            ,on_loct_id               => l_xwyp_rec.rcpt_loct_id
            ,ov_loct_code             => l_xwyp_rec.rcpt_loct_code
            ,ov_loct_name             => l_xwyp_rec.rcpt_loct_name
            ,ov_calendar_code         => l_xwyp_rec.rcpt_calendar_code
            ,ov_errbuf                => lv_errbuf
            ,ov_retcode               => lv_retcode
            ,ov_errmsg                => lv_errmsg
          );
          --移動先倉庫情報が取得できない倉庫は対象外
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_api_expt;
          ELSIF (lv_retcode = cv_status_warn) THEN
            RAISE outside_scope_expt;
          END IF;
          --移動元倉庫情報を取得
          xxcop_common_pkg2.get_loct_info(
             id_target_date           => gd_process_date
            ,in_organization_id       => l_xwyp_rec.ship_organization_id
            ,ov_organization_code     => l_xwyp_rec.ship_organization_code
            ,ov_organization_name     => l_xwyp_rec.ship_organization_name
            ,on_loct_id               => l_xwyp_rec.ship_loct_id
            ,ov_loct_code             => l_xwyp_rec.ship_loct_code
            ,ov_loct_name             => l_xwyp_rec.ship_loct_name
            ,ov_calendar_code         => l_xwyp_rec.ship_calendar_code
            ,ov_errbuf                => lv_errbuf
            ,ov_retcode               => lv_retcode
            ,ov_errmsg                => lv_errmsg
          );
          --移動元倉庫情報が取得できない倉庫は対象外
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_api_expt;
          ELSIF (lv_retcode = cv_status_warn) THEN
            RAISE outside_scope_expt;
          END IF;
--
          --最終入庫日以降の工場出荷計画を取得し、横持計画手持在庫テーブルに登録
          INSERT INTO xxcop_loct_inv (
             transaction_id
            ,loct_id
            ,loct_code
            ,organization_id
            ,organization_code
            ,item_id
            ,item_no
            ,lot_id
            ,lot_no
            ,manufacture_date
            ,expiration_date
            ,unique_sign
            ,lot_status
            ,loct_onhand
            ,schedule_date
            ,shipment_date
            ,voucher_no
            ,transaction_type
            ,simulate_flag
            ,created_by
            ,creation_date
            ,last_updated_by
            ,last_update_date
            ,last_update_login
            ,request_id
            ,program_application_id
            ,program_id
            ,program_update_date
          )
          SELECT gn_transaction_id                            transaction_id
                ,msdvv.loct_id                                loct_id
                ,msdvv.loct_code                              loct_code
                ,msdvv.organization_id                        organization_id
                ,msdvv.organization_code                      organization_code
                ,l_xwyp_rec.item_id                           item_id
                ,l_xwyp_rec.item_no                           item_no
                ,NULL                                         lot_id
                ,NULL                                         lot_no
                ,msdvv.manufacture_date                       manufacture_date
                ,NULL                                         expiration_date
                ,NULL                                         unique_sign
                ,NULL                                         lot_status
                ,TRUNC(SUM(msdvv.schedule_quantity) / l_xwyp_rec.num_of_case)
                                                              loct_onhand
                ,msdvv.schedule_date                          schedule_date
                ,cd_lower_limit_date                          shipment_date
                ,NULL                                         voucher_no
                ,cv_xli_type_fs                               transaction_type
                ,NULL                                         simulate_flag
                ,cn_created_by                                created_by
                ,cd_creation_date                             creation_date
                ,cn_last_updated_by                           last_updated_by
                ,cd_last_update_date                          last_update_date
                ,cn_last_update_login                         last_update_login
                ,cn_request_id                                request_id
                ,cn_program_application_id                    program_application_id
                ,cn_program_id                                program_id
                ,cd_program_update_date                       program_update_date
          FROM (
            SELECT l_xwyp_rec.rcpt_loct_id                    loct_id
                  ,l_xwyp_rec.rcpt_loct_code                  loct_code
                  ,l_xwyp_rec.rcpt_organization_id            organization_id
                  ,l_xwyp_rec.rcpt_organization_code          organization_code
                  ,msd.schedule_date                          schedule_date
                  ,msd.schedule_quantity                      schedule_quantity
                  ,NVL(TO_DATE(msd.attribute5, cv_date_format)
                     , TO_DATE(msd.attribute3, cv_date_format))
                                                              manufacture_date
            FROM mrp_schedule_designators ms
                ,mrp_schedule_items       msi
                ,mrp_schedule_dates       msd
            WHERE ms.attribute1           = cv_msd_fs_sched
              AND msi.schedule_designator = ms.schedule_designator
              AND msi.organization_id     = ms.organization_id
              AND msd.schedule_designator = msi.schedule_designator
              AND msd.organization_id     = msi.organization_id
              AND msd.inventory_item_id   = msi.inventory_item_id
              AND msd.schedule_level      = cn_schedule_level
              AND msd.schedule_quantity   > 0
              AND msd.attribute3         IS NOT NULL
              AND msd.organization_id     = l_xwyp_rec.rcpt_organization_id
              AND msd.inventory_item_id   = l_xwyp_rec.inventory_item_id
              AND msd.attribute2          = l_xwyp_rec.ship_organization_code
              AND xxcop_common_pkg2.get_last_arrival_date_f(
                     l_xwyp_rec.rcpt_loct_id
                    ,l_xwyp_rec.ship_loct_id
                    ,l_xwyp_rec.item_id
                  ) < msd.schedule_date
            UNION ALL
            SELECT l_xwyp_rec.ship_loct_id                    loct_id
                  ,l_xwyp_rec.ship_loct_code                  loct_code
                  ,l_xwyp_rec.ship_organization_id            organization_id
                  ,l_xwyp_rec.ship_organization_code          organization_code
                  ,TO_DATE(msd.attribute3, cv_date_format)    schedule_date
                  ,msd.schedule_quantity * -1                 schedule_quantity
                  ,NVL(TO_DATE(msd.attribute5, cv_date_format)
                     , TO_DATE(msd.attribute3, cv_date_format))
                                                              manufacture_date
            FROM mrp_schedule_designators ms
                ,mrp_schedule_items       msi
                ,mrp_schedule_dates       msd
            WHERE ms.attribute1           = cv_msd_fs_sched
              AND msi.schedule_designator = ms.schedule_designator
              AND msi.organization_id     = ms.organization_id
              AND msd.schedule_designator = msi.schedule_designator
              AND msd.organization_id     = msi.organization_id
              AND msd.inventory_item_id   = msi.inventory_item_id
              AND msd.schedule_level      = cn_schedule_level
              AND msd.schedule_quantity   > 0
              AND msd.attribute3         IS NOT NULL
              AND msd.organization_id     = l_xwyp_rec.rcpt_organization_id
              AND msd.inventory_item_id   = l_xwyp_rec.inventory_item_id
              AND msd.attribute2          = l_xwyp_rec.ship_organization_code
              AND xxcop_common_pkg2.get_last_arrival_date_f(
                     l_xwyp_rec.rcpt_loct_id
                    ,l_xwyp_rec.ship_loct_id
                    ,l_xwyp_rec.item_id
                  ) < msd.schedule_date
          ) msdvv
          GROUP BY msdvv.loct_id
                  ,msdvv.loct_code
                  ,msdvv.organization_id
                  ,msdvv.organization_code
                  ,msdvv.manufacture_date
                  ,msdvv.schedule_date
          ;
          --登録件数カウント
          ln_entry_xli := ln_entry_xli + SQL%ROWCOUNT;
--
      EXCEPTION
        WHEN outside_scope_expt THEN
          NULL;
        WHEN OTHERS THEN
          lv_errbuf := SQLERRM;
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_appl_cont
                         ,iv_name         => cv_msg_00027
                         ,iv_token_name1  => cv_msg_00027_token_1
                         ,iv_token_value1 => cv_table_xli
                       );
          RAISE global_api_expt;
      END;
    END LOOP msd_fs_sched_loop;
    CLOSE msd_fs_sched_cur;
--
    --デバックメッセージ出力(工場出荷計画)
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => cv_indent_2 || cv_prg_name || ':'
                      || 'entry_xli_fs(COUNT):'
                      || ln_entry_xli
    );
--
  EXCEPTION
    WHEN internal_api_expt THEN
      IF (msd_fs_sched_cur%ISOPEN) THEN
        CLOSE msd_fs_sched_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF (msd_fs_sched_cur%ISOPEN) THEN
        CLOSE msd_fs_sched_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF (msd_fs_sched_cur%ISOPEN) THEN
        CLOSE msd_fs_sched_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (msd_fs_sched_cur%ISOPEN) THEN
        CLOSE msd_fs_sched_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END entry_xli_fs;
--
  /**********************************************************************************
   * Procedure Name   : entry_xwyp
   * Description      : 横持計画物流ワークテーブル登録(B-13)
   ***********************************************************************************/
  PROCEDURE entry_xwyp(
    i_xwyp_rec       IN     xxcop_wk_yoko_planning%ROWTYPE,
    i_gfct_tab       IN     g_fc_ttype,
    ov_errbuf        OUT    VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT    VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg        OUT    VARCHAR2        --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'entry_xwyp'; -- プログラム名
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
    l_xwyp_rec                xxcop_wk_yoko_planning%ROWTYPE;
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
--    --デバックメッセージ出力
--    xxcop_common_pkg.put_debug_message(
--       iov_debug_mode => gv_debug_mode
--      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
--                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
--    );
--
    --初期化
    l_xwyp_rec        := NULL;
--
    BEGIN
      --要求固定値の設定
      l_xwyp_rec                            := i_xwyp_rec;
      l_xwyp_rec.transaction_id             := gn_transaction_id;
      l_xwyp_rec.created_by                 := cn_created_by;
      l_xwyp_rec.creation_date              := cd_creation_date;
      l_xwyp_rec.last_updated_by            := cn_last_updated_by;
      l_xwyp_rec.last_update_date           := cd_last_update_date;
      l_xwyp_rec.last_update_login          := cn_last_update_login;
      l_xwyp_rec.request_id                 := cn_request_id;
      l_xwyp_rec.program_application_id     := cn_program_application_id;
      l_xwyp_rec.program_id                 := cn_program_id;
      l_xwyp_rec.program_update_date        := cd_program_update_date;
      <<condition_loop>>
      FOR ln_priority_idx IN i_gfct_tab.FIRST .. i_gfct_tab.LAST LOOP
        IF (i_gfct_tab(ln_priority_idx).freshness_condition IS NOT NULL) THEN
          l_xwyp_rec.freshness_priority     := ln_priority_idx;
          l_xwyp_rec.freshness_condition    := i_gfct_tab(ln_priority_idx).freshness_condition;
          l_xwyp_rec.freshness_class        := i_gfct_tab(ln_priority_idx).freshness_class;
          l_xwyp_rec.freshness_check_value  := i_gfct_tab(ln_priority_idx).freshness_check_value;
          l_xwyp_rec.freshness_adjust_value := i_gfct_tab(ln_priority_idx).freshness_adjust_value;
          l_xwyp_rec.safety_stock_days      := i_gfct_tab(ln_priority_idx).safety_stock_days;
          l_xwyp_rec.max_stock_days         := i_gfct_tab(ln_priority_idx).max_stock_days;
          --横持計画物流ワークテーブル登録
          INSERT INTO xxcop_wk_yoko_planning VALUES l_xwyp_rec;
        END IF;
      END LOOP condition_loop;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := SQLERRM;
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00027
                       ,iv_token_name1  => cv_msg_00027_token_1
                       ,iv_token_value1 => cv_table_xwyp
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
  END entry_xwyp;
--
  /**********************************************************************************
   * Procedure Name   : chk_freshness_cond
   * Description      : 鮮度条件チェック(B-12)
   ***********************************************************************************/
  PROCEDURE chk_freshness_cond(
    i_xwyp_rec       IN     xxcop_wk_yoko_planning%ROWTYPE,
    io_gfct_tab      IN OUT g_fc_ttype,
    ov_errbuf        OUT    VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT    VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg        OUT    VARCHAR2        --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_freshness_cond'; -- プログラム名
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
    ln_priority_idx           NUMBER;
    ln_condition_cnt          NUMBER;
    lv_item_name              VARCHAR2(100);
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
--    --デバックメッセージ出力
--    xxcop_common_pkg.put_debug_message(
--       iov_debug_mode => gv_debug_mode
--      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
--                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
--    );
--
    --初期化
    ln_priority_idx           := NULL;
    ln_condition_cnt          := 0;
    lv_item_name              := NULL;
--
    --出荷計画区分
    IF  ((i_xwyp_rec.shipping_type NOT IN (cv_plan_type_shipped, cv_plan_type_forecate))
      OR (i_xwyp_rec.shipping_type IS NULL ))
    THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_appl_cont
                     ,iv_name         => cv_msg_00068
                     ,iv_token_name1  => cv_msg_00068_token_1
                     ,iv_token_value1 => i_xwyp_rec.rcpt_organization_code
                     ,iv_token_name2  => cv_msg_00068_token_2
                     ,iv_token_value2 => i_xwyp_rec.item_no
                   );
      RAISE internal_api_expt;
    END IF;
--
    <<priority_loop>>
    FOR ln_priority_idx IN 1 .. io_gfct_tab.COUNT LOOP
      BEGIN
        --鮮度条件
        IF (io_gfct_tab(ln_priority_idx).freshness_condition IS NOT NULL) THEN
          --鮮度条件コードチェック
          SELECT flv.attribute1                               freshness_class
                ,TO_NUMBER(flv.attribute2)                    freshness_check_value
                ,TO_NUMBER(flv.attribute3)                    freshness_adjust_value
          INTO io_gfct_tab(ln_priority_idx).freshness_class
              ,io_gfct_tab(ln_priority_idx).freshness_check_value
              ,io_gfct_tab(ln_priority_idx).freshness_adjust_value
          FROM fnd_lookup_values flv
          WHERE flv.lookup_type          = cv_flv_freshness_cond
            AND flv.lookup_code          = io_gfct_tab(ln_priority_idx).freshness_condition
            AND flv.language             = cv_lang
            AND flv.source_lang          = cv_lang
            AND flv.enabled_flag         = cv_enable
            AND gd_process_date BETWEEN NVL(flv.start_date_active, gd_process_date)
                                    AND NVL(flv.end_date_active,   gd_process_date)
          ;
--20100203_Ver3.4_E_本稼動_01222_SCS.Goto_ADD_START
          --在庫日数調整値を加算
          io_gfct_tab(ln_priority_idx).safety_stock_days := io_gfct_tab(ln_priority_idx).safety_stock_days
                                                          + gn_stock_adjust_value;
          io_gfct_tab(ln_priority_idx).max_stock_days    := io_gfct_tab(ln_priority_idx).max_stock_days
                                                          + gn_stock_adjust_value;
--20100203_Ver3.4_E_本稼動_01222_SCS.Goto_ADD_END
          --安全在庫日数
          IF (NVL(io_gfct_tab(ln_priority_idx).safety_stock_days, -1) < 0) THEN
            lv_item_name := cv_msg_10041_value_1;
            RAISE stock_days_expt;
          END IF;
          --最大在庫日数
          IF (NVL(io_gfct_tab(ln_priority_idx).max_stock_days, -1) < 0) THEN
            lv_item_name := cv_msg_10041_value_2;
            RAISE stock_days_expt;
          END IF;
          ln_condition_cnt := ln_condition_cnt + 1;
          --優先順位
          io_gfct_tab(ln_priority_idx).freshness_priority := ln_condition_cnt;
        END IF;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_appl_cont
                         ,iv_name         => cv_msg_10040
                         ,iv_token_name1  => cv_msg_10040_token_1
                         ,iv_token_value1 => i_xwyp_rec.rcpt_organization_code
                         ,iv_token_name2  => cv_msg_10040_token_2
                         ,iv_token_value2 => i_xwyp_rec.item_no
                         ,iv_token_name3  => cv_msg_10040_token_3
                         ,iv_token_value3 => io_gfct_tab(ln_priority_idx).freshness_condition
                       );
          RAISE internal_api_expt;
        WHEN stock_days_expt THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_appl_cont
                         ,iv_name         => cv_msg_10041
                         ,iv_token_name1  => cv_msg_10041_token_1
                         ,iv_token_value1 => i_xwyp_rec.rcpt_organization_code
                         ,iv_token_name2  => cv_msg_10041_token_2
                         ,iv_token_value2 => i_xwyp_rec.item_no
                         ,iv_token_name3  => cv_msg_10041_token_3
                         ,iv_token_value3 => io_gfct_tab(ln_priority_idx).freshness_condition
                         ,iv_token_name4  => cv_msg_10041_token_4
                         ,iv_token_value4 => lv_item_name
                       );
          RAISE internal_api_expt;
      END;
    END LOOP priority_loop;
--
    --鮮度条件が登録されていない場合
    IF (ln_condition_cnt = 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_appl_cont
                     ,iv_name         => cv_msg_10038
                     ,iv_token_name1  => cv_msg_10038_token_1
                     ,iv_token_value1 => i_xwyp_rec.rcpt_organization_code
                     ,iv_token_name2  => cv_msg_10038_token_2
                     ,iv_token_value2 => i_xwyp_rec.item_no
                   );
      RAISE internal_api_expt;
    END IF;
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
  END chk_freshness_cond;
--
  /**********************************************************************************
   * Procedure Name   : chk_effective_route
   * Description      : 特別横持計画有効期間チェック(B-11)
   ***********************************************************************************/
  PROCEDURE chk_effective_route(
    i_xwyp_rec       IN     xxcop_wk_yoko_planning%ROWTYPE,
    ov_effective     OUT    VARCHAR2,       --   有効判定結果
    ov_errbuf        OUT    VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT    VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg        OUT    VARCHAR2        --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_effective_route'; -- プログラム名
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
--    --デバックメッセージ出力
--    xxcop_common_pkg.put_debug_message(
--       iov_debug_mode => gv_debug_mode
--      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
--                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
--    );
--
    --初期化
    ov_effective := cv_status_normal;
--
    --有効判定
    BEGIN
      --有効開始日判定
      IF (i_xwyp_rec.sy_effective_date IS NOT NULL) THEN
        IF (i_xwyp_rec.sy_effective_date > i_xwyp_rec.receipt_date) THEN
          RAISE obsolete_skip_expt;
        END IF;
      END IF;
--
      --有効終了日判定
      IF (i_xwyp_rec.sy_disable_date IS NOT NULL) THEN
        IF (i_xwyp_rec.sy_disable_date < i_xwyp_rec.receipt_date) THEN
          RAISE obsolete_skip_expt;
        END IF;
      END IF;
--
      --設定数判定
      IF (i_xwyp_rec.sy_maxmum_quantity IS NOT NULL) THEN
        IF (i_xwyp_rec.sy_maxmum_quantity <= NVL(i_xwyp_rec.sy_stocked_quantity, 0)) THEN
          RAISE obsolete_skip_expt;
        END IF;
      END IF;
--
      --開始製造年月日または有効開始日が設定されている
      IF ((i_xwyp_rec.sy_manufacture_date IS NULL) AND (i_xwyp_rec.sy_effective_date IS NULL)) THEN
        RAISE no_condition_expt;
      END IF;
--
      --数量または有効終了日が設定されていること
      IF ((i_xwyp_rec.sy_maxmum_quantity IS NULL) AND (i_xwyp_rec.sy_disable_date IS NULL)) THEN
        RAISE no_condition_expt;
      END IF;
--
    EXCEPTION
      WHEN obsolete_skip_expt THEN
        ov_effective := cv_status_warn;
      WHEN no_condition_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_10039
                       ,iv_token_name1  => cv_msg_10039_token_1
                       ,iv_token_value1 => i_xwyp_rec.rcpt_organization_code
                       ,iv_token_name2  => cv_msg_10039_token_2
                       ,iv_token_value2 => i_xwyp_rec.item_no
                     );
        RAISE internal_api_expt;
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
  END chk_effective_route;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(B-1)
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
--20100203_Ver3.4_E_本稼動_01222_SCS.Goto_ADD_START
    ,iv_working_days        IN     VARCHAR2                 --10.稼動日数
    ,iv_stock_adjust_value  IN     VARCHAR2                 --11.在庫日数調整値
--20100203_Ver3.4_E_本稼動_01222_SCS.Goto_ADD_END
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
    lb_chk_value              BOOLEAN;         -- 日付型フォーマットチェック結果
    lv_chk_parameter          VARCHAR2(100);   -- チェック項目名
    lv_chk_date_from          VARCHAR2(100);   -- 範囲チェック項目名(FROM)
    lv_chk_date_to            VARCHAR2(100);   -- 範囲チェック項目名(TO)
    lv_value                  VARCHAR2(100);   -- プロファイル値
    lv_profile_name           VARCHAR2(100);   -- ユーザプロファイル名
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
    --初期化
    lb_chk_value              := NULL;
    lv_chk_parameter          := NULL;
    lv_chk_date_from          := NULL;
    lv_chk_date_to            := NULL;
    lv_value                  := NULL;
    lv_profile_name           := NULL;
--
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
--20100203_Ver3.4_E_本稼動_01222_SCS.Goto_ADD_START
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
--20100203_Ver3.4_E_本稼動_01222_SCS.Goto_ADD_END
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
--
      -- ===============================
      -- 品目コード
      -- ===============================
      lv_chk_parameter := cv_item_code_tl;
      --値のNULLチェック
      IF (iv_item_code IS NULL) THEN
        RAISE param_invalid_expt;
      END IF;
      gv_item_code := iv_item_code;
--
--20100203_Ver3.4_E_本稼動_01222_SCS.Goto_ADD_START
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
        gn_stock_adjust_value := TO_NUMBER(NVL(iv_stock_adjust_value, 0));
      EXCEPTION
        WHEN OTHERS THEN
        RAISE param_invalid_expt;
      END;
--
--20100203_Ver3.4_E_本稼動_01222_SCS.Goto_ADD_END
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
    -- トランザクションIDの取得
    -- ===============================
    gn_transaction_id := MOD(cn_request_id, gn_partition_num);
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
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_msr_route
   * Description      : 横持計画制御マスタ取得(B-2)
   ***********************************************************************************/
  PROCEDURE get_msr_route(
    ov_errbuf        OUT    VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT    VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg        OUT    VARCHAR2        --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_msr_route'; -- プログラム名
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
    ln_exists                 NUMBER;         --存在チェック
    lv_effective              VARCHAR2(1);    --特別横持計画有効判定
    ln_work_day               NUMBER;         --計画立案日の稼働日チェック
    ld_planning_date          DATE;           --計画立案日
--20100107_Ver3.2_E_本稼動_00936_SCS.Goto_DEL_START
--    ln_planning_count         NUMBER;         --計画立案経路のカウント
--20100107_Ver3.2_E_本稼動_00936_SCS.Goto_DEL_END
--
    -- *** ローカル・カーソル ***
--
    --対象品目の取得
    CURSOR item_cur(
       id_planning_date       DATE
    ) IS
      SELECT msib.inventory_item_id                           inventory_item_id           --在庫品目ID
            ,iimb.item_id                                     item_id                     --OPM品目ID
            ,iimb.item_no                                     item_no                     --品目コード
            ,ximb.item_short_name                             item_name                   --品目名称
            ,NVL(TO_NUMBER(iimb.attribute11), 1)              num_of_case                 --ケース入数
            ,NVL(DECODE(ximb.palette_max_cs_qty
                      , 0, 1
                      , ximb.palette_max_cs_qty
                 ), 1)                                        palette_max_cs_qty          --配数
            ,NVL(DECODE(ximb.palette_max_step_qty
                      , 0, 1
                      , ximb.palette_max_step_qty
                 ), 1)                                        palette_max_step_qty        --段数
--20100107_Ver3.2_E_本稼動_00936_SCS.Goto_ADD_START
            ,ximb.expiration_day                              expiration_day              --賞味期間
--20100107_Ver3.2_E_本稼動_00936_SCS.Goto_ADD_END
      FROM   ic_item_mst_b             iimb      --OPM品目マスタ
            ,xxcmn_item_mst_b          ximb      --OPM品目アドオンマスタ
            ,mtl_system_items_b        msib      --DISC品目マスタ
      WHERE iimb.inactive_ind                = cn_iimb_status_active
        AND iimb.attribute18                 = cv_shipping_enable
        AND ximb.item_id                     = iimb.item_id
        AND ximb.obsolete_class              = cn_ximb_status_active
        AND id_planning_date           BETWEEN NVL(ximb.start_date_active, id_planning_date)
                                           AND NVL(ximb.end_date_active  , id_planning_date)
        AND msib.segment1                    = iimb.item_no
        AND msib.organization_id             = gn_master_org_id
        AND msib.segment1                    = gv_item_code
    ;
    --経路情報の取得
    CURSOR msr_cur(
       id_planning_date       DATE
      ,in_inventory_item_id   NUMBER
    ) IS
      WITH msr_vw AS (
        --全経路(基本横持計画、特別横持計画、供給ルールダミー経路、パッカー倉庫ダミー経路)
        SELECT mas.assignment_set_name                    assignment_set_name --割当セット名
              ,mas.attribute1                             assignment_set_type --割当セット区分
              ,msa.assignment_type                            assignment_type --割当先タイプ
              ,msa.organization_id                            organization_id --組織
              ,msa.inventory_item_id                        inventory_item_id --品目
              ,msa.sourcing_rule_type                      sourcing_rule_type --ソースルールタイプ
              ,msr.sourcing_rule_name                      sourcing_rule_name --ソースルール名
              ,msso.source_organization_id             source_organization_id --移動元組織ID
              ,NVL(msro.receipt_organization_id, msa.organization_id)
                                                      receipt_organization_id --移動先組織ID
              ,msa.attribute1                                      attribute1 --
              ,msa.attribute2                                      attribute2 --
              ,msa.attribute3                                      attribute3 --
              ,msa.attribute4                                      attribute4 --
              ,msa.attribute5                                      attribute5 --
              ,msa.attribute6                                      attribute6 --
              ,msa.attribute7                                      attribute7 --
              ,msa.attribute8                                      attribute8 --
              ,msa.attribute9                                      attribute9 --
              ,msa.attribute10                                    attribute10 --
              ,msa.attribute11                                    attribute11 --
              ,msa.attribute12                                    attribute12 --
              ,msa.attribute13                                    attribute13 --
              ,flv2.description                          assign_type_priority --割当先タイプ優先度
              ,RANK () OVER (PARTITION BY NVL(msro.receipt_organization_id, msa.organization_id)
                                         ,msso.source_organization_id
                                         ,mas.attribute1
                             ORDER BY     flv2.description                    ASC
                                         ,msa.sourcing_rule_type              DESC
                                         ,mas.assignment_set_name             ASC
                       )                                       overlap_priority --重複経路優先順位
              ,RANK () OVER (PARTITION BY DECODE(msso.source_organization_id, gn_master_org_id, 1, 0)
                                         ,NVL(msro.receipt_organization_id, msa.organization_id)
                                         ,mas.attribute1
                             ORDER BY     flv2.description                    ASC
                                         ,msa.sourcing_rule_type              DESC
                                         ,mas.assignment_set_name             ASC
                                         ,msso.source_organization_id         DESC
                       )                               sourcing_rule_priority --供給ルール優先順位
        FROM mrp_assignment_sets    mas                 --割当セット
            ,mrp_sr_assignments     msa                 --割当セット明細
            ,mrp_sourcing_rules     msr                 --ソースルール
            ,mrp_sr_receipt_org     msro                --ソースルール受入組織
            ,mrp_sr_source_org      msso                --ソースルール出荷組織
            ,fnd_lookup_values      flv1                --参照タイプ(割当セット名)
            ,fnd_lookup_values      flv2                --参照タイプ(割当先タイプ優先度)
        WHERE mas.attribute1             IN (cv_base_plan, cv_custom_plan)
          AND msa.assignment_set_id       = mas.assignment_set_id
          AND msr.sourcing_rule_id        = msa.sourcing_rule_id
          AND msro.sourcing_rule_id       = msr.sourcing_rule_id
          AND msso.sr_receipt_id          = msro.sr_receipt_id
          AND msso.source_type            = cn_location_source
          AND id_planning_date BETWEEN NVL(msro.effective_date, id_planning_date)
                                   AND NVL(msro.disable_date  , id_planning_date)
          AND flv1.lookup_type            = cv_flv_assignment_name
          AND flv1.lookup_code            = mas.assignment_set_name
          AND flv1.language               = cv_lang
          AND flv1.source_lang            = cv_lang
          AND flv1.enabled_flag           = cv_enable
          AND gd_process_date BETWEEN NVL(flv1.start_date_active, gd_process_date)
                                  AND NVL(flv1.end_date_active  , gd_process_date)
          AND flv2.lookup_type            = cv_flv_assign_priority
          AND flv2.lookup_code            = msa.assignment_type
          AND flv2.language               = cv_lang
          AND flv2.source_lang            = cv_lang
          AND flv2.enabled_flag           = cv_enable
          AND gd_process_date BETWEEN NVL(flv2.start_date_active, gd_process_date)
                                  AND NVL(flv2.end_date_active  , gd_process_date)
          AND NVL(msa.inventory_item_id, in_inventory_item_id) = in_inventory_item_id
      )
      , msr_base_vw AS (
        --基本横持計画
        SELECT msrv.assignment_set_name                   assignment_set_name --割当セット名
              ,msrv.assignment_set_type                   assignment_set_type --割当セット区分
              ,msrv.assignment_type                           assignment_type --割当先タイプ
              ,msrv.organization_id                           organization_id --組織
              ,msrv.inventory_item_id                       inventory_item_id --品目
              ,msrv.sourcing_rule_type                     sourcing_rule_type --ソースルールタイプ
              ,msrv.sourcing_rule_name                     sourcing_rule_name --ソースルール名
              ,msrv.source_organization_id             source_organization_id --移動元組織ID
              ,msrv.receipt_organization_id           receipt_organization_id --移動先組織ID
              ,CASE
                 WHEN mdv.source_organization_id IS NOT NULL
                   THEN '1'
                   ELSE NULL
               END                                   sourcing_rule_dummy_flag --供給ルールダミーFLAG
              ,CASE
                 WHEN mdv.source_organization_id IS NOT NULL
                   THEN TO_NUMBER(mdv.attribute1)
                   ELSE TO_NUMBER(msv.attribute1)
               END                                              shipping_type --出荷計画区分
              ,CASE
                 WHEN mdv.source_organization_id IS NOT NULL
                   THEN mdv.attribute2
                   ELSE msv.attribute2
               END                                       freshness_condition1 --鮮度条件1
              ,CASE
                 WHEN mdv.source_organization_id IS NOT NULL
                   THEN TO_NUMBER(mdv.attribute3)
                   ELSE TO_NUMBER(msv.attribute3)
               END                                         safety_stock_days1 --安全在庫日数1
              ,CASE
                 WHEN mdv.source_organization_id IS NOT NULL
                   THEN TO_NUMBER(mdv.attribute4)
                   ELSE TO_NUMBER(msv.attribute4)
               END                                            max_stock_days1 --最大在庫日数1
              ,CASE
                 WHEN mdv.source_organization_id IS NOT NULL
                   THEN mdv.attribute5
                   ELSE msv.attribute5
               END                                       freshness_condition2 --鮮度条件2
              ,CASE
                 WHEN mdv.source_organization_id IS NOT NULL
                   THEN TO_NUMBER(mdv.attribute6)
                   ELSE TO_NUMBER(msv.attribute6)
               END                                         safety_stock_days2 --安全在庫日数2
              ,CASE
                 WHEN mdv.source_organization_id IS NOT NULL
                   THEN TO_NUMBER(mdv.attribute7)
                   ELSE TO_NUMBER(msv.attribute7)
               END                                            max_stock_days2 --最大在庫日数2
              ,CASE
                 WHEN mdv.source_organization_id IS NOT NULL
                   THEN mdv.attribute8
                   ELSE msv.attribute8
               END                                       freshness_condition3 --鮮度条件3
              ,CASE
                 WHEN mdv.source_organization_id IS NOT NULL
                   THEN TO_NUMBER(mdv.attribute9)
                   ELSE TO_NUMBER(msv.attribute9)
               END                                         safety_stock_days3 --安全在庫日数3
              ,CASE
                 WHEN mdv.source_organization_id IS NOT NULL
                   THEN TO_NUMBER(mdv.attribute10)
                   ELSE TO_NUMBER(msv.attribute10)
               END                                            max_stock_days3 --最大在庫日数3
              ,CASE
                 WHEN mdv.source_organization_id IS NOT NULL
                   THEN mdv.attribute11
                   ELSE msv.attribute11
               END                                       freshness_condition4 --鮮度条件4
              ,CASE
                 WHEN mdv.source_organization_id IS NOT NULL
                   THEN TO_NUMBER(mdv.attribute12)
                   ELSE TO_NUMBER(msv.attribute12)
               END                                         safety_stock_days4 --安全在庫日数4
              ,CASE
                 WHEN mdv.source_organization_id IS NOT NULL
                   THEN TO_NUMBER(mdv.attribute13)
                   ELSE TO_NUMBER(msv.attribute13)
               END                                            max_stock_days4 --最大在庫日数4
              ,msrv.overlap_priority                         overlap_priority --重複経路優先順位
              ,msrv.sourcing_rule_priority             sourcing_rule_priority --供給ルール優先順位
        FROM msr_vw msrv            --基本横持計画経路
            ,msr_vw msv             --基本横持計画供給ルール
            ,msr_vw mdv             --供給ルールダミー経路
        WHERE msrv.assignment_set_type        IN (cv_base_plan)
          AND msrv.source_organization_id NOT IN (gn_master_org_id)
          AND msrv.overlap_priority            = 1
          AND msv.assignment_set_type         IN (cv_base_plan)
          AND msv.source_organization_id  NOT IN (gn_master_org_id)
          AND msv.sourcing_rule_priority       = 1
          AND msrv.receipt_organization_id     = msv.receipt_organization_id
          AND mdv.assignment_set_type(+)      IN (cv_base_plan)
          AND mdv.source_organization_id(+)   IN (gn_master_org_id)
          AND msv.sourcing_rule_priority(+)    = 1
          AND mdv.receipt_organization_id(+)   = msrv.receipt_organization_id
      )
      , msr_custom_vw AS (
        --特別横持計画
        SELECT
               msrv.assignment_set_name                   assignment_set_name --割当セット名
              ,msrv.assignment_set_type                   assignment_set_type --割当セット区分
              ,msrv.assignment_type                           assignment_type --割当先タイプ
              ,msrv.organization_id                           organization_id --組織
              ,msrv.inventory_item_id                       inventory_item_id --品目
              ,msrv.sourcing_rule_type                     sourcing_rule_type --ソースルールタイプ
              ,msrv.sourcing_rule_name                     sourcing_rule_name --ソースルール名
              ,msrv.source_organization_id             source_organization_id --移動元組織ID
              ,msrv.receipt_organization_id           receipt_organization_id --移動先組織ID
              ,mbv.sourcing_rule_dummy_flag          sourcing_rule_dummy_flag --供給ルールダミーFLAG
              ,mbv.shipping_type                                shipping_type --出荷計画区分
              ,mbv.freshness_condition1                  freshness_condition1 --鮮度条件1
              ,mbv.safety_stock_days1                      safety_stock_days1 --安全在庫日数1
              ,mbv.max_stock_days1                            max_stock_days1 --最大在庫日数1
              ,mbv.freshness_condition2                  freshness_condition2 --鮮度条件2
              ,mbv.safety_stock_days2                      safety_stock_days2 --安全在庫日数2
              ,mbv.max_stock_days2                            max_stock_days2 --最大在庫日数2
              ,mbv.freshness_condition3                  freshness_condition3 --鮮度条件3
              ,mbv.safety_stock_days3                      safety_stock_days3 --安全在庫日数3
              ,mbv.max_stock_days3                            max_stock_days3 --最大在庫日数3
              ,mbv.freshness_condition4                  freshness_condition4 --鮮度条件4
              ,mbv.safety_stock_days4                      safety_stock_days4 --安全在庫日数4
              ,mbv.max_stock_days4                            max_stock_days4 --最大在庫日数4
              ,TO_DATE(msrv.attribute1, cv_date_format)      manufacture_date --開始製造年月日
              ,CASE
                 WHEN msrv.attribute1 IS NULL
                   THEN TO_DATE(msrv.attribute2, cv_date_format)
                   ELSE NULL
               END                                             effective_date --有効開始日
              ,TO_DATE(msrv.attribute3, cv_date_format)          disable_date --有効終了日
              ,TO_NUMBER(msrv.attribute4)                     maxmum_quantity --設定数量
              ,TO_NUMBER(msrv.attribute5)                    stocked_quantity --移動数
        FROM msr_vw      msrv       --特別横持計画経路
            ,msr_base_vw mbv        --基本横持計画経路
        WHERE msrv.assignment_set_type        IN (cv_custom_plan)
          AND msrv.source_organization_id NOT IN (gn_master_org_id, gn_source_org_id)
          AND msrv.assignment_type            IN (cv_assign_type_item_org)
          AND msrv.receipt_organization_id     = mbv.receipt_organization_id
          AND mbv.sourcing_rule_priority       = 1
      )
      SELECT
             mbv.assignment_set_name                    assignment_set_name --割当セット名
            ,mbv.assignment_set_type                    assignment_set_type --割当セット区分
            ,mbv.assignment_type                            assignment_type --割当先タイプ
            ,mbv.sourcing_rule_type                      sourcing_rule_type --ソースルールタイプ
            ,mbv.sourcing_rule_name                      sourcing_rule_name --ソースルール名
            ,mbv.source_organization_id              source_organization_id --移動元組織ID
            ,mbv.receipt_organization_id            receipt_organization_id --移動先組織ID
            ,mbv.sourcing_rule_dummy_flag          sourcing_rule_dummy_flag --供給ルールダミーFLAG
            ,mbv.shipping_type                                shipping_type --出荷計画区分
            ,mbv.freshness_condition1                  freshness_condition1 --鮮度条件1
            ,mbv.safety_stock_days1                      safety_stock_days1 --安全在庫日数1
            ,mbv.max_stock_days1                            max_stock_days1 --最大在庫日数1
            ,mbv.freshness_condition2                  freshness_condition2 --鮮度条件2
            ,mbv.safety_stock_days2                      safety_stock_days2 --安全在庫日数2
            ,mbv.max_stock_days2                            max_stock_days2 --最大在庫日数2
            ,mbv.freshness_condition3                  freshness_condition3 --鮮度条件3
            ,mbv.safety_stock_days3                      safety_stock_days3 --安全在庫日数3
            ,mbv.max_stock_days3                            max_stock_days3 --最大在庫日数3
            ,mbv.freshness_condition4                  freshness_condition4 --鮮度条件4
            ,mbv.safety_stock_days4                      safety_stock_days4 --安全在庫日数4
            ,mbv.max_stock_days4                            max_stock_days4 --最大在庫日数4
            ,NULL                                          manufacture_date --開始製造年月日
            ,NULL                                            effective_date --有効開始日
            ,NULL                                              disable_date --有効終了日
            ,NULL                                           maxmum_quantity --設定数量
            ,NULL                                          stocked_quantity --移動数
      FROM msr_base_vw mbv
      UNION ALL
      SELECT
             mcv.assignment_set_name                    assignment_set_name --割当セット名
            ,mcv.assignment_set_type                    assignment_set_type --割当セット区分
            ,mcv.assignment_type                            assignment_type --割当先タイプ
            ,mcv.sourcing_rule_type                      sourcing_rule_type --ソースルールタイプ
            ,mcv.sourcing_rule_name                      sourcing_rule_name --ソースルール名
            ,mcv.source_organization_id              source_organization_id --移動元組織ID
            ,mcv.receipt_organization_id            receipt_organization_id --移動先組織ID
            ,mcv.sourcing_rule_dummy_flag          sourcing_rule_dummy_flag --供給ルールダミーFLAG
            ,mcv.shipping_type                                shipping_type --出荷計画区分
            ,mcv.freshness_condition1                  freshness_condition1 --鮮度条件1
            ,mcv.safety_stock_days1                      safety_stock_days1 --安全在庫日数1
            ,mcv.max_stock_days1                            max_stock_days1 --最大在庫日数1
            ,mcv.freshness_condition2                  freshness_condition2 --鮮度条件2
            ,mcv.safety_stock_days2                      safety_stock_days2 --安全在庫日数2
            ,mcv.max_stock_days2                            max_stock_days2 --最大在庫日数2
            ,mcv.freshness_condition3                  freshness_condition3 --鮮度条件3
            ,mcv.safety_stock_days3                      safety_stock_days3 --安全在庫日数3
            ,mcv.max_stock_days3                            max_stock_days3 --最大在庫日数3
            ,mcv.freshness_condition4                  freshness_condition4 --鮮度条件4
            ,mcv.safety_stock_days4                      safety_stock_days4 --安全在庫日数4
            ,mcv.max_stock_days4                            max_stock_days4 --最大在庫日数4
            ,mcv.manufacture_date                          manufacture_date --開始製造年月日
            ,mcv.effective_date                              effective_date --有効開始日
            ,mcv.disable_date                                  disable_date --有効終了日
            ,mcv.maxmum_quantity                            maxmum_quantity --設定数量
            ,mcv.stocked_quantity                          stocked_quantity --移動数
      FROM msr_custom_vw mcv
    ;
    -- *** ローカル・レコード ***
    l_xwyp_rec                xxcop_wk_yoko_planning%ROWTYPE;
    l_gfct_tab                g_fc_ttype;
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
    --初期化
    ln_exists                 := NULL;
    lv_effective              := NULL;
    ln_work_day               := NULL;
    ld_planning_date          := NULL;
--20100107_Ver3.2_E_本稼動_00936_SCS.Goto_DEL_START
--    ln_planning_count         := NULL;
--20100107_Ver3.2_E_本稼動_00936_SCS.Goto_DEL_END
    l_xwyp_rec                := NULL;
    l_gfct_tab.DELETE;
--
--20100107_Ver3.2_E_本稼動_00936_SCS.Goto_MOD_START
--    ld_planning_date := gd_planning_date_to;
    ld_planning_date := gd_planning_date_from;
--20100107_Ver3.2_E_本稼動_00936_SCS.Goto_MOD_END
    <<planning_loop>>
--20100107_Ver3.2_E_本稼動_00936_SCS.Goto_MOD_START
--    LOOP
    WHILE (ld_planning_date <= gd_planning_date_to) LOOP
--20100107_Ver3.2_E_本稼動_00936_SCS.Goto_MOD_END
      BEGIN
        --計画立案日で初期化
--20100107_Ver3.2_E_本稼動_00936_SCS.Goto_DEL_START
--        ln_planning_count := 0;
--20100107_Ver3.2_E_本稼動_00936_SCS.Goto_DEL_END
        OPEN item_cur( ld_planning_date );
        <<item_loop>>
        LOOP
          BEGIN
            --品目情報の取得
            FETCH item_cur INTO l_xwyp_rec.inventory_item_id
                               ,l_xwyp_rec.item_id
                               ,l_xwyp_rec.item_no
                               ,l_xwyp_rec.item_name
                               ,l_xwyp_rec.num_of_case
                               ,l_xwyp_rec.palette_max_cs_qty
                               ,l_xwyp_rec.palette_max_step_qty
--20100107_Ver3.2_E_本稼動_00936_SCS.Goto_ADD_START
                               ,l_xwyp_rec.expiration_day
--20100107_Ver3.2_E_本稼動_00936_SCS.Goto_ADD_END
            ;
            EXIT WHEN item_cur%NOTFOUND;
            --ケース入数チェック
            IF (l_xwyp_rec.num_of_case = 0) THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => cv_msg_appl_cont
                             ,iv_name         => cv_msg_00061
                             ,iv_token_name1  => cv_msg_00061_token_1
                             ,iv_token_value1 => l_xwyp_rec.item_no
                           );
              RAISE internal_api_expt;
            END IF;
--
--20100107_Ver3.2_E_本稼動_00936_SCS.Goto_ADD_START
            --品目カテゴリ取得(群コード)
            l_xwyp_rec.crowd_class_code := xxcop_common_pkg2.get_item_category_f(
                                              iv_category_set => cv_category_crowd_class
                                             ,in_item_id      => l_xwyp_rec.item_id
                                           );
--20100107_Ver3.2_E_本稼動_00936_SCS.Goto_ADD_END
--
            OPEN msr_cur( ld_planning_date, l_xwyp_rec.inventory_item_id );
            <<msr_loop>>
            LOOP
              BEGIN
                --経路情報の取得
                FETCH msr_cur INTO l_xwyp_rec.assignment_set_name
                                  ,l_xwyp_rec.assignment_set_type
                                  ,l_xwyp_rec.assignment_type
                                  ,l_xwyp_rec.sourcing_rule_type
                                  ,l_xwyp_rec.sourcing_rule_name
                                  ,l_xwyp_rec.ship_organization_id
                                  ,l_xwyp_rec.rcpt_organization_id
                                  ,l_xwyp_rec.sourcing_rule_dummy_flag
                                  ,l_xwyp_rec.shipping_type
                                  ,l_gfct_tab(1).freshness_condition
                                  ,l_gfct_tab(1).safety_stock_days
                                  ,l_gfct_tab(1).max_stock_days
                                  ,l_gfct_tab(2).freshness_condition
                                  ,l_gfct_tab(2).safety_stock_days
                                  ,l_gfct_tab(2).max_stock_days
                                  ,l_gfct_tab(3).freshness_condition
                                  ,l_gfct_tab(3).safety_stock_days
                                  ,l_gfct_tab(3).max_stock_days
                                  ,l_gfct_tab(4).safety_stock_days
                                  ,l_gfct_tab(4).safety_stock_days
                                  ,l_gfct_tab(4).max_stock_days
                                  ,l_xwyp_rec.sy_manufacture_date
                                  ,l_xwyp_rec.sy_effective_date
                                  ,l_xwyp_rec.sy_disable_date
                                  ,l_xwyp_rec.sy_maxmum_quantity
                                  ,l_xwyp_rec.sy_stocked_quantity
                ;
                EXIT WHEN msr_cur%NOTFOUND;
                --移動元倉庫情報の取得
                xxcop_common_pkg2.get_loct_info(
                   id_target_date        => ld_planning_date
                  ,in_organization_id    => l_xwyp_rec.ship_organization_id
                  ,ov_organization_code  => l_xwyp_rec.ship_organization_code
                  ,ov_organization_name  => l_xwyp_rec.ship_organization_name
                  ,on_loct_id            => l_xwyp_rec.ship_loct_id
                  ,ov_loct_code          => l_xwyp_rec.ship_loct_code
                  ,ov_loct_name          => l_xwyp_rec.ship_loct_name
                  ,ov_calendar_code      => l_xwyp_rec.ship_calendar_code
                  ,ov_errbuf             => lv_errbuf
                  ,ov_retcode            => lv_retcode
                  ,ov_errmsg             => lv_errmsg
                );
                IF (lv_retcode = cv_status_error) THEN
                  lv_errmsg := xxccp_common_pkg.get_msg(
                                  iv_application  => cv_msg_appl_cont
                                 ,iv_name         => cv_msg_00050
                                 ,iv_token_name1  => cv_msg_00050_token_1
                                 ,iv_token_value1 => l_xwyp_rec.ship_organization_id
                               );
                  RAISE global_api_expt;
                ELSIF (lv_retcode = cv_status_warn) THEN
                  lv_errmsg := xxccp_common_pkg.get_msg(
                                  iv_application  => cv_msg_appl_cont
                                 ,iv_name         => cv_msg_00050
                                 ,iv_token_name1  => cv_msg_00050_token_1
                                 ,iv_token_value1 => l_xwyp_rec.ship_organization_code
                               );
                  RAISE internal_api_expt;
                END IF;
                --移動先倉庫情報の取得
                xxcop_common_pkg2.get_loct_info(
                   id_target_date        => ld_planning_date
                  ,in_organization_id    => l_xwyp_rec.rcpt_organization_id
                  ,ov_organization_code  => l_xwyp_rec.rcpt_organization_code
                  ,ov_organization_name  => l_xwyp_rec.rcpt_organization_name
                  ,on_loct_id            => l_xwyp_rec.rcpt_loct_id
                  ,ov_loct_code          => l_xwyp_rec.rcpt_loct_code
                  ,ov_loct_name          => l_xwyp_rec.rcpt_loct_name
                  ,ov_calendar_code      => l_xwyp_rec.rcpt_calendar_code
                  ,ov_errbuf             => lv_errbuf
                  ,ov_retcode            => lv_retcode
                  ,ov_errmsg             => lv_errmsg
                );
                IF (lv_retcode = cv_status_error) THEN
                  lv_errmsg := xxccp_common_pkg.get_msg(
                                  iv_application  => cv_msg_appl_cont
                                 ,iv_name         => cv_msg_00050
                                 ,iv_token_name1  => cv_msg_00050_token_1
                                 ,iv_token_value1 => l_xwyp_rec.rcpt_organization_id
                               );
                  RAISE global_api_expt;
                ELSIF (lv_retcode = cv_status_warn) THEN
                  lv_errmsg := xxccp_common_pkg.get_msg(
                                  iv_application  => cv_msg_appl_cont
                                 ,iv_name         => cv_msg_00050
                                 ,iv_token_name1  => cv_msg_00050_token_1
                                 ,iv_token_value1 => l_xwyp_rec.rcpt_organization_code
                               );
                  RAISE internal_api_expt;
                END IF;
                --移動元倉庫の稼働日チェック
                xxcop_common_pkg2.get_working_days(
                   iv_calendar_code   => l_xwyp_rec.ship_calendar_code
                  ,in_organization_id => l_xwyp_rec.ship_organization_id
                  ,in_loct_id         => l_xwyp_rec.ship_loct_id
                  ,id_from_date       => ld_planning_date
                  ,id_to_date         => ld_planning_date
                  ,on_working_days    => ln_work_day
                  ,ov_errbuf          => lv_errbuf
                  ,ov_retcode         => lv_retcode
                  ,ov_errmsg          => lv_errmsg
                );
                IF (lv_retcode = cv_status_error) THEN
                  RAISE global_api_expt;
                END IF;
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_ADD_START
                IF (l_xwyp_rec.ship_organization_id = gn_source_org_id) THEN
                  --移動元倉庫がパッカー倉庫ダミーの場合、配送リードタイムに0を設定
                  l_xwyp_rec.delivery_lead_time := 0;
                ELSE
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_ADD_END
                  --配送リードタイムの取得
                  xxcop_common_pkg2.get_deliv_lead_time(
                     id_target_date        => ld_planning_date
                    ,iv_from_loct_code     => l_xwyp_rec.ship_loct_code
                    ,iv_to_loct_code       => l_xwyp_rec.rcpt_loct_code
                    ,on_delivery_lt        => l_xwyp_rec.delivery_lead_time
                    ,ov_errbuf             => lv_errbuf
                    ,ov_retcode            => lv_retcode
                    ,ov_errmsg             => lv_errmsg
                  );
                  IF (lv_retcode = cv_status_error) THEN
                    RAISE global_api_expt;
                  ELSIF (lv_retcode = cv_status_warn) THEN
                    lv_errmsg := xxccp_common_pkg.get_msg(
                                    iv_application  => cv_msg_appl_cont
                                   ,iv_name         => cv_msg_00053
                                   ,iv_token_name1  => cv_msg_00053_token_1
                                   ,iv_token_value1 => l_xwyp_rec.ship_loct_code
                                   ,iv_token_name2  => cv_msg_00053_token_2
                                   ,iv_token_value2 => l_xwyp_rec.rcpt_loct_code
                                 );
                    RAISE internal_api_expt;
                  END IF;
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_ADD_START
                END IF;
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_ADD_END
                --出荷日の取得
                l_xwyp_rec.shipping_date := ld_planning_date;
                --着日の取得
                xxcop_common_pkg2.get_receipt_date(
                   iv_calendar_code   => l_xwyp_rec.rcpt_calendar_code
                  ,in_organization_id => NULL
                  ,in_loct_id         => NULL
                  ,id_shipment_date   => ld_planning_date
                  ,in_lead_time       => l_xwyp_rec.delivery_lead_time
                  ,od_receipt_date    => l_xwyp_rec.receipt_date
                  ,ov_errbuf          => lv_errbuf
                  ,ov_retcode         => lv_retcode
                  ,ov_errmsg          => lv_errmsg
                );
                IF (lv_retcode = cv_status_error) THEN
                  RAISE global_api_expt;
                END IF;
                IF (l_xwyp_rec.receipt_date IS NULL) THEN
                  lv_errmsg := xxccp_common_pkg.get_msg(
                                  iv_application  => cv_msg_appl_cont
                                 ,iv_name         => cv_msg_00066
                                 ,iv_token_name1  => cv_msg_00066_token_1
                                 ,iv_token_value1 => l_xwyp_rec.rcpt_loct_code
                                 ,iv_token_name2  => cv_msg_00066_token_2
                                 ,iv_token_value2 => l_xwyp_rec.rcpt_calendar_code
                                 ,iv_token_name3  => cv_msg_00066_token_3
                                 ,iv_token_value3 => TO_CHAR(ld_planning_date, cv_date_format)
                               );
                  RAISE internal_api_expt;
                END IF;
                --特別横持の場合
                IF (l_xwyp_rec.assignment_set_type = cv_custom_plan) THEN
                  -- ===============================
                  -- B-11．特別横持計画有効期間チェック
                  -- ===============================
                  chk_effective_route(
                     i_xwyp_rec            => l_xwyp_rec
                    ,ov_effective          => lv_effective
                    ,ov_errbuf             => lv_errbuf
                    ,ov_retcode            => lv_retcode
                    ,ov_errmsg             => lv_errmsg
                  );
                  IF (lv_retcode = cv_status_error) THEN
                    IF (lv_errbuf IS NULL) THEN
                      RAISE internal_api_expt;
                    ELSE
                      RAISE global_api_expt;
                    END IF;
                  END IF;
                  --計画立案日が有効終了日を過ぎているまたは設定数を超えている場合
                  IF (lv_effective <> cv_status_normal) THEN
                    RAISE obsolete_skip_expt;
                  END IF;
                END IF;
                -- ===============================
                -- B-12．鮮度条件チェック
                -- ===============================
                chk_freshness_cond(
                   i_xwyp_rec            => l_xwyp_rec
                  ,io_gfct_tab           => l_gfct_tab
                  ,ov_errbuf             => lv_errbuf
                  ,ov_retcode            => lv_retcode
                  ,ov_errmsg             => lv_errmsg
                );
                IF (lv_retcode <> cv_status_normal) THEN
                  IF (lv_errbuf IS NULL) THEN
                    RAISE internal_api_expt;
                  ELSE
                    RAISE global_api_expt;
                  END IF;
                END IF;
                --計画立案フラグの設定
--20100107_Ver3.2_E_本稼動_00936_SCS.Goto_MOD_START
--                IF (l_xwyp_rec.receipt_date >= gd_planning_date_from) THEN
--                  IF (ln_work_day > 0) THEN
--                    l_xwyp_rec.planning_flag := cv_planning_yes;
--                  ELSE
--                    l_xwyp_rec.planning_flag := cv_planning_no;
--                  END IF;
--                  ln_planning_count := ln_planning_count + 1;
--                ELSE
--                  l_xwyp_rec.planning_flag := cv_planning_no;
--                END IF;
                  IF (ln_work_day > 0) THEN
                    l_xwyp_rec.planning_flag := cv_planning_yes;
                  ELSE
                    l_xwyp_rec.planning_flag := cv_planning_no;
                  END IF;
--20100107_Ver3.2_E_本稼動_00936_SCS.Goto_MOD_END
                -- ===============================
                -- B-13．横持計画物流ワークテーブル登録
                -- ===============================
                entry_xwyp(
                   i_xwyp_rec   => l_xwyp_rec
                  ,i_gfct_tab   => l_gfct_tab
                  ,ov_retcode   => lv_retcode
                  ,ov_errbuf    => lv_errbuf
                  ,ov_errmsg    => lv_errmsg
                );
                IF (lv_retcode <> cv_status_normal) THEN
                  IF (lv_errbuf IS NULL) THEN
                    RAISE internal_api_expt;
                  ELSE
                    RAISE global_api_expt;
                  END IF;
                END IF;
              EXCEPTION
                WHEN obsolete_skip_expt THEN
                  NULL;
              END;
            END LOOP msr_loop;
            CLOSE msr_cur;
          EXCEPTION
            WHEN outside_scope_expt THEN
              NULL;
          END;
        END LOOP item_loop;
--
        --デバックメッセージ出力
        xxcop_common_pkg.put_debug_message(
           iov_debug_mode => gv_debug_mode
          ,iv_value       => cv_indent_2 || cv_prg_name || ':'
                          || 'item_cur(COUNT):'
                          || item_cur%ROWCOUNT                          || ','
                          || TO_CHAR(ld_planning_date, cv_date_format)  || ','
        );
--
        CLOSE item_cur;
      EXCEPTION
        WHEN obsolete_skip_expt THEN
          NULL;
      END;
--20100107_Ver3.2_E_本稼動_00936_SCS.Goto_DEL_START
--      --計画立案日の終了判定
--      IF (ln_planning_count = 0) THEN
--        EXIT planning_loop;
--      END IF;
--20100107_Ver3.2_E_本稼動_00936_SCS.Goto_DEL_END
--20100107_Ver3.2_E_本稼動_00936_SCS.Goto_MOD_START
--      -- 計画立案日をデクリメント
--      ld_planning_date := ld_planning_date - 1;
      -- 計画立案日をインクリメント
      ld_planning_date := ld_planning_date + 1;
--20100107_Ver3.2_E_本稼動_00936_SCS.Goto_MOD_END
    END LOOP planning_loop;
--
    --対象件数の確認
    SELECT COUNT(*)
    INTO   ln_exists
    FROM xxcop_wk_yoko_planning xwyp
    WHERE xwyp.transaction_id = gn_transaction_id
      AND xwyp.request_id     = cn_request_id
      AND xwyp.planning_flag  = cv_planning_yes
    ;
    --対象件数が0件の場合、終了
    IF (ln_exists = 0) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
    WHEN internal_api_expt THEN
      IF (item_cur%ISOPEN) THEN
        CLOSE item_cur;
      END IF;
      IF (msr_cur%ISOPEN) THEN
        CLOSE msr_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF (item_cur%ISOPEN) THEN
        CLOSE item_cur;
      END IF;
      IF (msr_cur%ISOPEN) THEN
        CLOSE msr_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF (item_cur%ISOPEN) THEN
        CLOSE item_cur;
      END IF;
      IF (msr_cur%ISOPEN) THEN
        CLOSE msr_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (item_cur%ISOPEN) THEN
        CLOSE item_cur;
      END IF;
      IF (msr_cur%ISOPEN) THEN
        CLOSE msr_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_msr_route;
--
  /**********************************************************************************
   * Procedure Name   : entry_xwyl
   * Description      : 品目別代表倉庫取得(B-3)
   ***********************************************************************************/
  PROCEDURE entry_xwyl(
    ov_errbuf        OUT    VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT    VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg        OUT    VARCHAR2        --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'entry_xwyl'; -- プログラム名
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
    lt_loct_id                mtl_item_locations.inventory_location_id%TYPE;
    lt_loct_code              mtl_item_locations.segment1%TYPE;
    lt_frq_loct_id            mtl_item_locations.inventory_location_id%TYPE;
    lt_frq_loct_code          mtl_item_locations.segment1%TYPE;
    ln_entry_xwyl             NUMBER;
--
    -- *** ローカル・カーソル ***
    --横持倉庫の取得
    CURSOR xwyp_cur IS
      SELECT xwyp.rcpt_loct_id            loct_id
            ,xwyp.rcpt_loct_code          loct_code
            ,xwyp.item_id                 item_id
            ,xwyp.item_no                 item_no
      FROM xxcop_wk_yoko_planning xwyp
      WHERE xwyp.transaction_id         = gn_transaction_id
        AND xwyp.request_id             = cn_request_id
      UNION
      SELECT xwyp.ship_loct_id            loct_id
            ,xwyp.ship_loct_code          loct_code
            ,xwyp.item_id                 item_id
            ,xwyp.item_no                 item_no
      FROM xxcop_wk_yoko_planning xwyp
      WHERE xwyp.transaction_id         = gn_transaction_id
        AND xwyp.request_id             = cn_request_id
        AND xwyp.ship_organization_id  <> gn_source_org_id
    ;
--
    -- *** ローカル・レコード ***
    l_xwyl_rec                xxcop_wk_yoko_locations%ROWTYPE;
    l_xwyl_tab                g_xwyl_ttype;
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
    --初期化
    lt_loct_id                := NULL;
    lt_loct_code              := NULL;
    lt_frq_loct_id            := NULL;
    lt_frq_loct_code          := NULL;
    ln_entry_xwyl             := 0;
    l_xwyl_rec                := NULL;
    l_xwyl_tab.DELETE;
--
    BEGIN
      --横持倉庫の取得
      <<xwyl_loop>>
      FOR l_xwyp_rec IN xwyp_cur LOOP
        --代表倉庫を取得
        SELECT mil.inventory_location_id    loct_id
              ,mil.segment1                 loct_code
              ,mil.attribute5               frq_loct_code
        INTO lt_loct_id
            ,lt_loct_code
            ,lt_frq_loct_code
        FROM mtl_item_locations             mil
        WHERE mil.inventory_location_id = l_xwyp_rec.loct_id
        ;
--
        l_xwyl_rec.transaction_id           := gn_transaction_id;
        l_xwyl_rec.planning_flag            := NULL;
        l_xwyl_rec.frq_loct_id              := lt_loct_id;
        l_xwyl_rec.frq_loct_code            := lt_loct_code;
        l_xwyl_rec.loct_id                  := lt_loct_id;
        l_xwyl_rec.loct_code                := lt_loct_code;
        l_xwyl_rec.item_id                  := l_xwyp_rec.item_id;
        l_xwyl_rec.item_no                  := l_xwyp_rec.item_no;
        l_xwyl_rec.schedule_date            := NULL;
        l_xwyl_rec.created_by               := cn_created_by;
        l_xwyl_rec.creation_date            := cd_creation_date;
        l_xwyl_rec.last_updated_by          := cn_last_updated_by;
        l_xwyl_rec.last_update_date         := cd_last_update_date;
        l_xwyl_rec.last_update_login        := cn_last_update_login;
        l_xwyl_rec.request_id               := cn_request_id;
        l_xwyl_rec.program_application_id   := cn_program_application_id;
        l_xwyl_rec.program_id               := cn_program_id;
        l_xwyl_rec.program_update_date      := cd_program_update_date;
--
        BEGIN
          --横持計画品目別代表倉庫ワークテーブル登録
          INSERT INTO xxcop_wk_yoko_locations VALUES l_xwyl_rec;
          ln_entry_xwyl := ln_entry_xwyl + SQL%ROWCOUNT;
        EXCEPTION
          WHEN DUP_VAL_ON_INDEX THEN
            NULL;
        END;
--
        IF (lt_frq_loct_code IS NULL) THEN
          --代表倉庫でない場合
          NULL;
        ELSIF (lt_frq_loct_code = lt_loct_code) THEN
          --代表倉庫(親)の場合
          BEGIN
            --OPM保管場所マスタの代表倉庫を横持計画品目別代表倉庫ワークテーブルに登録
            INSERT INTO xxcop_wk_yoko_locations (
               transaction_id
              ,planning_flag
              ,frq_loct_id
              ,frq_loct_code
              ,loct_id
              ,loct_code
              ,item_id
              ,item_no
              ,schedule_date
              ,created_by
              ,creation_date
              ,last_updated_by
              ,last_update_date
              ,last_update_login
              ,request_id
              ,program_application_id
              ,program_id
              ,program_update_date
            )
            SELECT gn_transaction_id            transaction_id
                  ,NULL                         planning_flag
                  ,lt_loct_id                   frq_loct_id
                  ,lt_loct_code                 frq_loct_code
                  ,mil.inventory_location_id    loct_id
                  ,mil.segment1                 loct_code
                  ,l_xwyp_rec.item_id           item_id
                  ,l_xwyp_rec.item_no           item_no
                  ,NULL                         schedule_date
                  ,cn_created_by                created_by
                  ,cd_creation_date             creation_date
                  ,cn_last_updated_by           last_updated_by
                  ,cd_last_update_date          last_update_date
                  ,cn_last_update_login         last_update_login
                  ,cn_request_id                request_id
                  ,cn_program_application_id    program_application_id
                  ,cn_program_id                program_id
                  ,cd_program_update_date       program_update_date
            FROM mtl_item_locations         mil
            WHERE mil.attribute5          = lt_frq_loct_code
              AND mil.segment1           <> mil.attribute5
            ;
            ln_entry_xwyl := ln_entry_xwyl + SQL%ROWCOUNT;
          EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
              NULL;
          END;
--
          BEGIN
            --倉庫品目アドオンマスタの品目別代表倉庫を横持計画品目別代表倉庫ワークテーブルに登録
            INSERT INTO xxcop_wk_yoko_locations (
               transaction_id
              ,planning_flag
              ,frq_loct_id
              ,frq_loct_code
              ,loct_id
              ,loct_code
              ,item_id
              ,item_no
              ,schedule_date
              ,created_by
              ,creation_date
              ,last_updated_by
              ,last_update_date
              ,last_update_login
              ,request_id
              ,program_application_id
              ,program_id
              ,program_update_date
            )
            SELECT gn_transaction_id            transaction_id
                  ,NULL                         planning_flag
                  ,lt_loct_id                   frq_loct_id
                  ,lt_loct_code                 frq_loct_code
                  ,xfil.item_location_id        loct_id
                  ,xfil.item_location_code      loct_code
                  ,l_xwyp_rec.item_id           item_id
                  ,l_xwyp_rec.item_no           item_no
                  ,NULL                         schedule_date
                  ,cn_created_by                created_by
                  ,cd_creation_date             creation_date
                  ,cn_last_updated_by           last_updated_by
                  ,cd_last_update_date          last_update_date
                  ,cn_last_update_login         last_update_login
                  ,cn_request_id                request_id
                  ,cn_program_application_id    program_application_id
                  ,cn_program_id                program_id
                  ,cd_program_update_date       program_update_date
            FROM mtl_item_locations         mil
                ,xxwsh_frq_item_locations   xfil
            WHERE mil.inventory_location_id   = xfil.item_location_id
              AND xfil.frq_item_location_code = lt_frq_loct_code
              AND xfil.item_id                = l_xwyp_rec.item_id
            ;
            ln_entry_xwyl := ln_entry_xwyl + SQL%ROWCOUNT;
          EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
              NULL;
          END;
        ELSE
          --代表倉庫(子)の場合
          IF (gv_dummy_frequent_whse = lt_frq_loct_code) THEN
            BEGIN
              --倉庫品目アドオンマスタの品目別代表倉庫を横持計画品目別代表倉庫ワークテーブルに登録
              INSERT INTO xxcop_wk_yoko_locations (
                 transaction_id
                ,planning_flag
                ,frq_loct_id
                ,frq_loct_code
                ,loct_id
                ,loct_code
                ,item_id
                ,item_no
                ,schedule_date
                ,created_by
                ,creation_date
                ,last_updated_by
                ,last_update_date
                ,last_update_login
                ,request_id
                ,program_application_id
                ,program_id
                ,program_update_date
              )
              SELECT gn_transaction_id            transaction_id
                    ,NULL                         planning_flag
                    ,xfil.frq_item_location_id    frq_loct_id
                    ,xfil.frq_item_location_code  frq_loct_code
                    ,lt_loct_id                   loct_id
                    ,lt_loct_code                 loct_code
                    ,l_xwyp_rec.item_id           item_id
                    ,l_xwyp_rec.item_no           item_no
                    ,NULL                         schedule_date
                    ,cn_created_by                created_by
                    ,cd_creation_date             creation_date
                    ,cn_last_updated_by           last_updated_by
                    ,cd_last_update_date          last_update_date
                    ,cn_last_update_login         last_update_login
                    ,cn_request_id                request_id
                    ,cn_program_application_id    program_application_id
                    ,cn_program_id                program_id
                    ,cd_program_update_date       program_update_date
              FROM xxwsh_frq_item_locations   xfil
              WHERE xfil.item_location_code     = lt_loct_code
                AND xfil.item_id                = l_xwyp_rec.item_id
              ;
              ln_entry_xwyl := ln_entry_xwyl + SQL%ROWCOUNT;
            EXCEPTION
              WHEN DUP_VAL_ON_INDEX THEN
                NULL;
            END;
          ELSE
            BEGIN
              --OPM保管場所マスタの代表倉庫を横持計画品目別代表倉庫ワークテーブルに登録
              INSERT INTO xxcop_wk_yoko_locations (
                 transaction_id
                ,planning_flag
                ,frq_loct_id
                ,frq_loct_code
                ,loct_id
                ,loct_code
                ,item_id
                ,item_no
                ,schedule_date
                ,created_by
                ,creation_date
                ,last_updated_by
                ,last_update_date
                ,last_update_login
                ,request_id
                ,program_application_id
                ,program_id
                ,program_update_date
              )
              SELECT gn_transaction_id            transaction_id
                    ,NULL                         planning_flag
                    ,mil2.inventory_location_id   frq_loct_id
                    ,mil2.segment1                frq_loct_code
                    ,mil1.inventory_location_id   loct_id
                    ,mil1.segment1                loct_code
                    ,l_xwyp_rec.item_id           item_id
                    ,l_xwyp_rec.item_no           item_no
                    ,NULL                         schedule_date
                    ,cn_created_by                created_by
                    ,cd_creation_date             creation_date
                    ,cn_last_updated_by           last_updated_by
                    ,cd_last_update_date          last_update_date
                    ,cn_last_update_login         last_update_login
                    ,cn_request_id                request_id
                    ,cn_program_application_id    program_application_id
                    ,cn_program_id                program_id
                    ,cd_program_update_date       program_update_date
              FROM mtl_item_locations         mil1
                  ,mtl_item_locations         mil2
              WHERE mil1.attribute5         = lt_frq_loct_code
                AND mil1.segment1          <> mil1.attribute5
                AND mil2.segment1           = mil1.attribute5
              ;
              ln_entry_xwyl := ln_entry_xwyl + SQL%ROWCOUNT;
            EXCEPTION
              WHEN DUP_VAL_ON_INDEX THEN
                NULL;
            END;
          END IF;
        END IF;
      END LOOP xwyl_loop;
--
      --デバックメッセージ出力
      xxcop_common_pkg.put_debug_message(
         iov_debug_mode => gv_debug_mode
        ,iv_value       => cv_indent_2 || cv_prg_name || ':'
                        || 'xwyl(COUNT):'
                        || ln_entry_xwyl
      );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := SQLERRM;
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00027
                       ,iv_token_name1  => cv_msg_00027_token_1
                       ,iv_token_value1 => cv_table_xwyl
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
  END entry_xwyl;
--
  /**********************************************************************************
   * Procedure Name   : proc_shipping_pace
   * Description      : 出荷ペースの計算(B-4)
   ***********************************************************************************/
  PROCEDURE proc_shipping_pace(
    ov_errbuf        OUT    VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT    VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg        OUT    VARCHAR2        --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_shipping_pace'; -- プログラム名
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
    ln_shipment_days          NUMBER;       --出荷実績期間の稼動日数
    ln_forecast_days          NUMBER;       --出荷予測期間の稼動日数
    ln_shipping_quantity      NUMBER;       --出荷実績数
    ln_forecast_quantity      NUMBER;       --出荷予測数
    ld_critical_date          DATE;         --鮮度条件基準日
    ln_earliest_idx           NUMBER;       --最大鮮度条件基準日インデックス
    ld_earliest_date          DATE;         --最大鮮度条件基準日
    ld_manufacture_date       DATE;         --ロットの製造年月日
    ld_expiration_date        DATE;         --ロットの賞味期限
    ld_date_from              DATE;
    ld_date_to                DATE;
--
    -- *** ローカル・カーソル ***
    --品目－移動先倉庫の取得
    CURSOR xwyp_cur IS
      SELECT xwyp.item_id                           item_id
            ,xwyp.inventory_item_id                 inventory_item_id
            ,xwyp.item_no                           item_no
            ,xwyp.num_of_case                       num_of_case
            ,xwyp.rcpt_organization_id              rcpt_organization_id
            ,xwyp.rcpt_organization_code            rcpt_organization_code
            ,xwyp.rcpt_loct_id                      rcpt_loct_id
            ,xwyp.rcpt_loct_code                    rcpt_loct_code
            ,xwyp.rcpt_calendar_code                rcpt_calendar_code
      FROM xxcop_wk_yoko_planning xwyp
      WHERE xwyp.transaction_id = gn_transaction_id
        AND xwyp.request_id     = cn_request_id
      GROUP BY xwyp.item_id
              ,xwyp.inventory_item_id
              ,xwyp.item_no
              ,xwyp.num_of_case
              ,xwyp.rcpt_organization_id
              ,xwyp.rcpt_organization_code
              ,xwyp.rcpt_loct_id
              ,xwyp.rcpt_loct_code
              ,xwyp.rcpt_calendar_code
      ;
--
    -- *** ローカル・レコード ***
    l_gfct_tab                g_fc_ttype;                 --鮮度条件コレクション型
    l_gspt_tab                g_sp_ttype;                 --出荷ペースコレクション型
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
    --初期化
    ln_shipment_days          := NULL;
    ln_forecast_days          := NULL;
    ln_shipping_quantity      := NULL;
    ln_forecast_quantity      := NULL;
    ld_critical_date          := NULL;
    ln_earliest_idx           := NULL;
    ld_earliest_date          := NULL;
    ld_manufacture_date       := NULL;
    ld_expiration_date        := NULL;
    ld_date_from              := NULL;
    ld_date_to                := NULL;
--
    --品目－移動先倉庫の取得
    <<xwyp_loop>>
    FOR l_xwyp_rec IN xwyp_cur LOOP
      --初期化
      ln_shipping_quantity := 0;
      ln_forecast_quantity := 0;
      l_gspt_tab.DELETE;
--
      --鮮度条件取得
      SELECT xwyp.freshness_priority                freshness_priority
            ,xwyp.freshness_condition               freshness_condition
            ,xwyp.freshness_class                   freshness_class
            ,xwyp.freshness_check_value             freshness_check_value
            ,xwyp.freshness_adjust_value            freshness_adjust_value
            ,0                                      safety_stock_days
            ,xwyp.max_stock_days                    max_stock_days
      BULK COLLECT INTO l_gfct_tab
      FROM xxcop_wk_yoko_planning xwyp
      WHERE xwyp.transaction_id = gn_transaction_id
        AND xwyp.request_id     = cn_request_id
        AND xwyp.item_id        = l_xwyp_rec.item_id
        AND xwyp.rcpt_loct_id   = l_xwyp_rec.rcpt_loct_id
      GROUP BY xwyp.freshness_priority
              ,xwyp.freshness_condition
              ,xwyp.freshness_class
              ,xwyp.freshness_check_value
              ,xwyp.freshness_adjust_value
              ,xwyp.max_stock_days
      ORDER BY xwyp.freshness_priority
      ;
--
--20100203_Ver3.4_E_本稼動_01222_SCS.Goto_MOD_START
--      --出荷実績期間の稼働日数の取得
--      xxcop_common_pkg2.get_working_days(
--         iv_calendar_code   => l_xwyp_rec.rcpt_calendar_code
--        ,in_organization_id => l_xwyp_rec.rcpt_organization_id
--        ,in_loct_id         => l_xwyp_rec.rcpt_loct_id
--        ,id_from_date       => gd_shipment_date_from
--        ,id_to_date         => gd_shipment_date_to
--        ,on_working_days    => ln_shipment_days
--        ,ov_errbuf          => lv_errbuf
--        ,ov_retcode         => lv_retcode
--        ,ov_errmsg          => lv_errmsg
--      );
--      IF (lv_retcode = cv_status_error) THEN
--        RAISE global_api_expt;
--      END IF;
--      IF (ln_shipment_days = 0) THEN
--        lv_errmsg := xxccp_common_pkg.get_msg(
--                        iv_application  => cv_msg_appl_cont
--                       ,iv_name         => cv_msg_00056
--                       ,iv_token_name1  => cv_msg_00056_token_1
--                       ,iv_token_value1 => TO_CHAR(gd_shipment_date_from, cv_date_format)
--                       ,iv_token_name2  => cv_msg_00056_token_2
--                       ,iv_token_value2 => TO_CHAR(gd_shipment_date_to  , cv_date_format)
--                     );
--        RAISE internal_api_expt;
--      END IF;
      --出荷実績の稼働日数
      ln_shipment_days := gn_working_days;
--20100203_Ver3.4_E_本稼動_01222_SCS.Goto_MOD_END
--
      --出荷実績の集計
      <<shipping_loop>>
      FOR ln_gfct_idx IN l_gfct_tab.FIRST .. l_gfct_tab.LAST LOOP
        --出荷実績の取得
        xxcop_common_pkg2.get_num_of_shipped(
           in_deliver_from_id        => l_xwyp_rec.rcpt_loct_id
          ,in_item_id                => l_xwyp_rec.item_id
          ,id_shipment_date_from     => gd_shipment_date_from
          ,id_shipment_date_to       => gd_shipment_date_to
          ,iv_freshness_condition    => l_gfct_tab(ln_gfct_idx).freshness_condition
          ,in_inventory_item_id      => l_xwyp_rec.inventory_item_id
          ,on_shipped_quantity       => l_gspt_tab(ln_gfct_idx).shipping_quantity
          ,ov_errbuf                 => lv_errbuf
          ,ov_retcode                => lv_retcode
          ,ov_errmsg                 => lv_errmsg
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        END IF;
        --出荷実績のケース換算
        l_gspt_tab(ln_gfct_idx).shipping_quantity := ROUND(l_gspt_tab(ln_gfct_idx).shipping_quantity
                                                         / l_xwyp_rec.num_of_case
                                                     );
        --出荷実績ペースの計算
        l_gspt_tab(ln_gfct_idx).shipping_pace := ROUND(l_gspt_tab(ln_gfct_idx).shipping_quantity
                                                     / ln_shipment_days
                                                 );
        --出荷実績の合計
        ln_shipping_quantity := ln_shipping_quantity + l_gspt_tab(ln_gfct_idx).shipping_quantity;
      END LOOP shipping_loop;
--
      IF (cv_plan_type_forecate = NVL(gv_plan_type, cv_plan_type_forecate)) THEN
        --出荷予測期間の稼働日数の取得
        xxcop_common_pkg2.get_working_days(
           iv_calendar_code   => l_xwyp_rec.rcpt_calendar_code
          ,in_organization_id => l_xwyp_rec.rcpt_organization_id
          ,in_loct_id         => l_xwyp_rec.rcpt_loct_id
          ,id_from_date       => gd_forecast_date_from
          ,id_to_date         => gd_forecast_date_to
          ,on_working_days    => ln_forecast_days
          ,ov_errbuf          => lv_errbuf
          ,ov_retcode         => lv_retcode
          ,ov_errmsg          => lv_errmsg
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        END IF;
        IF (ln_forecast_days = 0) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_appl_cont
                         ,iv_name         => cv_msg_00056
                         ,iv_token_name1  => cv_msg_00056_token_1
                         ,iv_token_value1 => TO_CHAR(gd_forecast_date_from, cv_date_format)
                         ,iv_token_name2  => cv_msg_00056_token_2
                         ,iv_token_value2 => TO_CHAR(gd_forecast_date_to  , cv_date_format)
                       );
          RAISE internal_api_expt;
        END IF;
--
        --出荷予測の取得
        xxcop_common_pkg2.get_num_of_forecast(
           in_organization_id   => l_xwyp_rec.rcpt_organization_id
          ,in_inventory_item_id => l_xwyp_rec.inventory_item_id
          ,id_plan_date_from    => gd_forecast_date_from
          ,id_plan_date_to      => gd_forecast_date_to
          ,in_loct_id           => l_xwyp_rec.rcpt_loct_id
          ,on_quantity          => ln_forecast_quantity
          ,ov_errbuf            => lv_errbuf
          ,ov_retcode           => lv_retcode
          ,ov_errmsg            => lv_errmsg
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        IF (ln_forecast_quantity > 0) THEN
          --出荷予測のケース換算
          ln_forecast_quantity := ROUND(ln_forecast_quantity / l_xwyp_rec.num_of_case);
--
          --出荷実績の合計数を判定
          IF (ln_shipping_quantity > 0) THEN
            --出荷実績がある場合、鮮度条件別に出荷実績で按分
            <<div_forecast_loop>>
            FOR ln_gfct_idx IN l_gfct_tab.FIRST .. l_gfct_tab.LAST LOOP
              --鮮度条件別の出荷予測数
              l_gspt_tab(ln_gfct_idx).forecast_quantity := ROUND(ln_forecast_quantity
                                                               * l_gspt_tab(ln_gfct_idx).shipping_quantity
                                                               / ln_shipping_quantity
                                                           );
              --出荷予測ペース
              l_gspt_tab(ln_gfct_idx).forecast_pace := ROUND(l_gspt_tab(ln_gfct_idx).forecast_quantity
                                                           / ln_forecast_days
                                                       );
            END LOOP div_forecast_loop;
          ELSE
            BEGIN
              --出荷実績がない場合、基準日が短い鮮度条件に一括
              --品目の製造年月日、賞味期限を取得
              SELECT TO_DATE(ilm.attribute1, cv_date_format)  manufacture_date
                    ,TO_DATE(ilm.attribute3, cv_date_format)  expiration_date
              INTO ld_manufacture_date
                  ,ld_expiration_date
              FROM ic_lots_mst ilm
              WHERE ilm.item_id       = l_xwyp_rec.item_id
                AND ilm.lot_id       <> 0
                AND ROWNUM = 1
              ;
              <<critical_loop>>
              FOR ln_gfct_idx IN l_gfct_tab.FIRST .. l_gfct_tab.LAST LOOP
                --鮮度条件別基準日の取得
                ld_critical_date := xxcop_common_pkg2.get_critical_date_f(
                                       iv_freshness_class        => l_gfct_tab(ln_gfct_idx).freshness_class
                                      ,in_freshness_check_value  => l_gfct_tab(ln_gfct_idx).freshness_check_value
                                      ,in_freshness_adjust_value => l_gfct_tab(ln_gfct_idx).freshness_adjust_value
                                      ,in_max_stock_days         => l_gfct_tab(ln_gfct_idx).max_stock_days
                                      ,in_freshness_buffer_days  => gn_freshness_buffer_days
                                      ,id_manufacture_date       => ld_manufacture_date
                                      ,id_expiration_date        => ld_expiration_date
                                    );
                IF ((ld_earliest_date > ld_critical_date) OR (ld_earliest_date IS NULL)) THEN
                  ld_earliest_date := ld_critical_date;
                  ln_earliest_idx  := ln_gfct_idx;
                END IF;
              END LOOP critical_loop;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                --対象品目のロットがない場合、鮮度条件基準日を判定できないため鮮度条件1に一括設定
                ln_earliest_idx := 1;
            END;
            --鮮度条件別の出荷予測数
            l_gspt_tab(ln_earliest_idx).forecast_quantity := ln_forecast_quantity;
            --出荷予測ペース
            l_gspt_tab(ln_earliest_idx).forecast_pace     := ROUND(ln_forecast_quantity / ln_forecast_days);
          END IF;
        END IF;
      END IF;
--
      --出荷ペースの更新
      <<xwyp_update_loop>>
      FOR ln_gfct_idx IN l_gfct_tab.FIRST .. l_gfct_tab.LAST LOOP
        BEGIN
          UPDATE xxcop_wk_yoko_planning xwyp
          SET    xwyp.shipping_pace     = NVL(l_gspt_tab(ln_gfct_idx).shipping_pace, 0)
                ,xwyp.forecast_pace     = NVL(l_gspt_tab(ln_gfct_idx).forecast_pace, 0)
          WHERE xwyp.transaction_id      = gn_transaction_id
            AND xwyp.request_id          = cn_request_id
            AND xwyp.item_id             = l_xwyp_rec.item_id
            AND xwyp.rcpt_loct_id        = l_xwyp_rec.rcpt_loct_id
            AND xwyp.freshness_condition = l_gfct_tab(ln_gfct_idx).freshness_condition
          ;
        EXCEPTION
          WHEN OTHERS THEN
            lv_errbuf := SQLERRM;
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_appl_cont
                           ,iv_name         => cv_msg_00028
                           ,iv_token_name1  => cv_msg_00028_token_1
                           ,iv_token_value1 => cv_table_xwyp
                         );
            RAISE global_api_expt;
        END;
      END LOOP xwyp_update_loop;
    END LOOP xwyp_loop;
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
  END proc_shipping_pace;
--
  /**********************************************************************************
   * Procedure Name   : proc_total_pace
   * Description      : 総出荷ペースの計算(B-5)
   ***********************************************************************************/
  PROCEDURE proc_total_pace(
    ov_errbuf        OUT    VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT    VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg        OUT    VARCHAR2        --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_total_pace'; -- プログラム名
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
    lt_total_shipping_pace    xxcop_wk_yoko_planning.total_shipping_pace%TYPE;  --総出荷実績ペース
    lt_total_forecast_pace    xxcop_wk_yoko_planning.total_forecast_pace%TYPE;  --総出荷予測ペース
    lt_shipping_unit          xxcop_wk_yoko_planning.delivery_unit%TYPE;        --出荷実績配送単位
    lt_forecast_unit          xxcop_wk_yoko_planning.delivery_unit%TYPE;        --出荷予測配送単位
--
    -- *** ローカル・カーソル ***
    --品目－移動先倉庫－鮮度条件の取得
    CURSOR xwyp_cur IS
      SELECT xwyp.shipping_date                     shipping_date
            ,xwyp.item_id                           item_id
            ,xwyp.item_no                           item_no
            ,xwyp.palette_max_cs_qty                palette_max_cs_qty
            ,xwyp.palette_max_step_qty              palette_max_step_qty
            ,xwyp.rcpt_loct_id                      rcpt_loct_id
            ,xwyp.rcpt_loct_code                    rcpt_loct_code
            ,xwyp.freshness_condition               freshness_condition
            ,MAX(xwyp.shipping_pace)                shipping_pace
            ,MAX(xwyp.forecast_pace)                forecast_pace
      FROM xxcop_wk_yoko_planning xwyp
      WHERE xwyp.transaction_id = gn_transaction_id
        AND xwyp.request_id     = cn_request_id
      GROUP BY xwyp.shipping_date
              ,xwyp.item_id
              ,xwyp.item_no
              ,xwyp.palette_max_cs_qty
              ,xwyp.palette_max_step_qty
              ,xwyp.rcpt_loct_id
              ,xwyp.rcpt_loct_code
              ,xwyp.freshness_condition
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
    --初期化
    lt_total_shipping_pace    := NULL;
    lt_total_forecast_pace    := NULL;
    lt_shipping_unit          := NULL;
    lt_forecast_unit          := NULL;
--
    --品目－移動先倉庫－鮮度条件の取得
    <<xwyp_loop>>
    FOR l_xwyp_rec IN xwyp_cur LOOP
      BEGIN
        --総出荷ペースの集計
        SELECT NVL(SUM(xwypv.shipping_pace), 0) + l_xwyp_rec.shipping_pace        total_shipping_pace
              ,NVL(SUM(xwypv.forecast_pace), 0) + l_xwyp_rec.forecast_pace        total_forecast_pace
        INTO lt_total_shipping_pace
            ,lt_total_forecast_pace
        FROM (
          SELECT xwyp.ship_loct_id                  ship_loct_id
                ,xwyp.rcpt_loct_id                  rcpt_loct_id
                ,SUM(CASE
                       WHEN xwyp.freshness_condition = l_xwyp_rec.freshness_condition THEN
                         xwyp.shipping_pace
                       ELSE
                         0
                     END)                           shipping_pace
                ,SUM(CASE
                       WHEN xwyp.freshness_condition = l_xwyp_rec.freshness_condition THEN
                         xwyp.forecast_pace
                       ELSE
                         0
                     END)                           forecast_pace
          FROM xxcop_wk_yoko_planning xwyp
          WHERE xwyp.transaction_id       = gn_transaction_id
            AND xwyp.request_id           = cn_request_id
            AND xwyp.shipping_date        = l_xwyp_rec.shipping_date
            AND xwyp.assignment_set_type  = cv_base_plan
            AND xwyp.item_id              = l_xwyp_rec.item_id
          GROUP BY xwyp.ship_loct_id
                  ,xwyp.rcpt_loct_id
          UNION ALL
          SELECT xwyl.loct_id                       ship_loct_id
                ,xwyl.frq_loct_id                   rcpt_loct_id
                ,0                                  shipping_pace
                ,0                                  forecast_pace
          FROM xxcop_wk_yoko_locations xwyl
          WHERE xwyl.transaction_id       = gn_transaction_id
            AND xwyl.request_id           = cn_request_id
            AND xwyl.item_id              = l_xwyp_rec.item_id
            AND xwyl.frq_loct_id <> xwyl.loct_id
        ) xwypv
        START WITH       xwypv.ship_loct_id  = l_xwyp_rec.rcpt_loct_id
        CONNECT BY PRIOR xwypv.rcpt_loct_id  = xwypv.ship_loct_id
        ;
      EXCEPTION
        WHEN nested_loop_expt THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_appl_cont
                         ,iv_name         => cv_msg_00060
                         ,iv_token_name1  => cv_msg_00060_token_1
                         ,iv_token_value1 => l_xwyp_rec.rcpt_loct_code
                         ,iv_token_name2  => cv_msg_00060_token_2
                         ,iv_token_value2 => l_xwyp_rec.item_no
                       );
          RAISE internal_api_expt;
      END;
--
      lt_shipping_unit := NULL;
      IF ((lt_total_shipping_pace > 0) AND (cv_plan_type_shipped = NVL(gv_plan_type, cv_plan_type_shipped))) THEN
        --出荷実績の配送単位を取得
        xxcop_common_pkg2.get_delivery_unit(
           in_shipping_pace         => lt_total_shipping_pace
          ,in_palette_max_cs_qty    => l_xwyp_rec.palette_max_cs_qty
          ,in_palette_max_step_qty  => l_xwyp_rec.palette_max_step_qty
          ,ov_unit_delivery         => lt_shipping_unit
          ,ov_errbuf                => lv_errbuf
          ,ov_retcode               => lv_retcode
          ,ov_errmsg                => lv_errmsg
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        END IF;
      END IF;
--
      lt_forecast_unit := NULL;
      IF ((lt_total_forecast_pace > 0) AND (cv_plan_type_forecate = NVL(gv_plan_type, cv_plan_type_forecate))) THEN
        --出荷予測の配送単位を取得
        xxcop_common_pkg2.get_delivery_unit(
           in_shipping_pace         => lt_total_forecast_pace
          ,in_palette_max_cs_qty    => l_xwyp_rec.palette_max_cs_qty
          ,in_palette_max_step_qty  => l_xwyp_rec.palette_max_step_qty
          ,ov_unit_delivery         => lt_forecast_unit
          ,ov_errbuf                => lv_errbuf
          ,ov_retcode               => lv_retcode
          ,ov_errmsg                => lv_errmsg
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        END IF;
      END IF;
--
      BEGIN
        --総出荷ペースの更新
        UPDATE xxcop_wk_yoko_planning xwyp
        SET    xwyp.total_shipping_pace = lt_total_shipping_pace
              ,xwyp.total_forecast_pace = lt_total_forecast_pace
              ,xwyp.delivery_unit       = CASE
                                            WHEN xwyp.shipping_type = cv_plan_type_shipped  THEN
                                              lt_shipping_unit
                                            WHEN xwyp.shipping_type = cv_plan_type_forecate THEN
                                              lt_forecast_unit
                                            ELSE
                                              NULL
                                          END
        WHERE xwyp.transaction_id       = gn_transaction_id
          AND xwyp.request_id           = cn_request_id
          AND xwyp.shipping_date        = l_xwyp_rec.shipping_date
          AND xwyp.item_id              = l_xwyp_rec.item_id
          AND xwyp.rcpt_loct_id         = l_xwyp_rec.rcpt_loct_id
          AND xwyp.freshness_condition  = l_xwyp_rec.freshness_condition
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errbuf := SQLERRM;
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_appl_cont
                         ,iv_name         => cv_msg_00028
                         ,iv_token_name1  => cv_msg_00028_token_1
                         ,iv_token_value1 => cv_table_xwyp
                       );
          RAISE global_api_expt;
      END;
    END LOOP xwyp_loop;
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
  END proc_total_pace;
--
  /**********************************************************************************
   * Procedure Name   : create_xli
   * Description      : 手持在庫テーブル作成(B-6)
   ***********************************************************************************/
  PROCEDURE create_xli(
    ov_errbuf        OUT    VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT    VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg        OUT    VARCHAR2        --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_xli'; -- プログラム名
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
    CURSOR xwyp_cur IS
      SELECT xwyp.item_id                 item_id
            ,xwyp.num_of_case             num_of_case
      FROM xxcop_wk_yoko_planning xwyp
      WHERE xwyp.transaction_id = gn_transaction_id
        AND xwyp.request_id     = cn_request_id
        AND xwyp.planning_flag  = cv_planning_yes
      GROUP BY xwyp.item_id
              ,xwyp.num_of_case
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
    BEGIN
      <<xwyp_loop>>
      FOR l_xwyp_rec IN xwyp_cur LOOP
        INSERT INTO xxcop_loct_inv (
           transaction_id
          ,loct_id
          ,loct_code
          ,organization_id
          ,organization_code
          ,item_id
          ,item_no
          ,lot_id
          ,lot_no
          ,manufacture_date
          ,expiration_date
          ,unique_sign
          ,lot_status
          ,loct_onhand
          ,schedule_date
          ,shipment_date
          ,voucher_no
          ,transaction_type
          ,simulate_flag
          ,created_by
          ,creation_date
          ,last_updated_by
          ,last_update_date
          ,last_update_login
          ,request_id
          ,program_application_id
          ,program_id
          ,program_update_date
        )
        SELECT gn_transaction_id                                          transaction_id
              ,xliv.loct_id                                               loct_id
              ,xliv.loct_code                                             loct_code
              ,xliv.organization_id                                       organization_id
              ,xliv.organization_code                                     organization_code
              ,xliv.item_id                                               item_id
              ,xliv.item_no                                               item_no
              ,xliv.lot_id                                                lot_id
              ,xliv.lot_no                                                lot_no
              ,xliv.manufacture_date                                      manufacture_date
              ,xliv.expiration_date                                       expiration_date
              ,xliv.unique_sign                                           unique_sign
              ,xliv.lot_status                                            lot_status
              ,TRUNC(SUM(xliv.loct_onhand) / l_xwyp_rec.num_of_case)      loct_onhand
              ,xliv.schedule_date                                         schedule_date
              ,xliv.shipment_date                                         shipment_date
              ,NULL                                                       voucher_no
              ,cv_xli_type_inv                                            transaction_type
              ,NULL                                                       simulate_flag
              ,cn_created_by                                              created_by
              ,cd_creation_date                                           creation_date
              ,cn_last_updated_by                                         last_updated_by
              ,cd_last_update_date                                        last_update_date
              ,cn_last_update_login                                       last_update_login
              ,cn_request_id                                              request_id
              ,cn_program_application_id                                  program_application_id
              ,cn_program_id                                              program_id
              ,cd_program_update_date                                     program_update_date
        FROM xxcop_loct_inv_v           xliv
        WHERE xliv.item_id            = l_xwyp_rec.item_id
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_ADD_START
          AND xliv.shipment_date     <= gd_allocated_date
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_ADD_END
          AND EXISTS(
                SELECT 'X'
                FROM xxcop_wk_yoko_locations  xwyl
                WHERE xwyl.transaction_id = gn_transaction_id
                  AND xwyl.request_id     = cn_request_id
                  AND xwyl.item_id        = l_xwyp_rec.item_id
                  AND xwyl.loct_id        = xliv.loct_id
                UNION ALL
                SELECT 'X'
                FROM xxcop_wk_yoko_locations  xwyl
                WHERE xwyl.transaction_id = gn_transaction_id
                  AND xwyl.request_id     = cn_request_id
                  AND xwyl.item_id        = l_xwyp_rec.item_id
                  AND xwyl.frq_loct_id    = xliv.loct_id
              )
        GROUP BY xliv.loct_id
                ,xliv.loct_code
                ,xliv.organization_id
                ,xliv.organization_code
                ,xliv.item_id
                ,xliv.item_no
                ,xliv.lot_id
                ,xliv.lot_no
                ,xliv.manufacture_date
                ,xliv.expiration_date
                ,xliv.unique_sign
                ,xliv.lot_status
                ,xliv.schedule_date
                ,xliv.shipment_date
        ;
      END LOOP xwyp_loop;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := SQLERRM;
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00027
                       ,iv_token_name1  => cv_msg_00027_token_1
                       ,iv_token_value1 => cv_table_xli
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
  END create_xli;
--
  /**********************************************************************************
   * Procedure Name   : get_msd_schedule
   * Description      : 基準計画トランザクション作成(B-7)
   ***********************************************************************************/
  PROCEDURE get_msd_schedule(
    ov_errbuf        OUT    VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT    VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg        OUT    VARCHAR2        --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_msd_schedule'; -- プログラム名
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
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
    );
--
    -- ===============================
    -- B-14. 横持計画手持在庫テーブル登録(工場出荷計画)
    -- ===============================
    entry_xli_fs(
       ov_errbuf             => lv_errbuf
      ,ov_retcode            => lv_retcode
      ,ov_errmsg             => lv_errmsg
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- B-15. 横持計画手持在庫テーブル登録(購入計画)
    -- ===============================
    entry_xli_po(
       ov_errbuf             => lv_errbuf
      ,ov_retcode            => lv_retcode
      ,ov_errmsg             => lv_errmsg
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
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
  END get_msd_schedule;
--
  /**********************************************************************************
   * Procedure Name   : get_shipment_schedule
   * Description      : 横持計画手持在庫テーブル登録(出荷ペース)(B-8)
   ***********************************************************************************/
  PROCEDURE get_shipment_schedule(
    ov_errbuf        OUT    VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT    VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg        OUT    VARCHAR2        --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_shipment_schedule'; -- プログラム名
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
    lt_latest_shipment_date   xxcop_loct_inv.schedule_date%TYPE;
    ln_working_day            NUMBER;       --稼働日チェック
--
    -- *** ローカル・カーソル ***
    --移動先倉庫の取得
    CURSOR rcpt_loct_cur IS
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_MOD_START
--      SELECT xwyp.rcpt_loct_id                      rcpt_loct_id
--            ,xwyp.item_id                           item_id
--            ,xwyp.shipping_type                     shipping_type
--      FROM xxcop_wk_yoko_planning xwyp
--      WHERE xwyp.transaction_id   = gn_transaction_id
--        AND xwyp.request_id       = cn_request_id
--        AND xwyp.receipt_date     = gd_planning_date
--        AND xwyp.shipping_type    = NVL(gv_plan_type, xwyp.shipping_type)
--        AND CASE
--              WHEN xwyp.shipping_type = cv_plan_type_shipped  THEN
--                xwyp.shipping_pace
--              WHEN xwyp.shipping_type = cv_plan_type_forecate THEN
--                xwyp.forecast_pace
--              ELSE
--                0
--            END > 0
--      GROUP BY xwyp.rcpt_loct_id
--              ,xwyp.item_id
--              ,xwyp.shipping_type
      WITH ship_loct_vw AS (
        SELECT xwyp.shipping_date                     shipping_date
              ,xwyp.ship_loct_id                      ship_loct_id
              ,xwyp.item_id                           item_id
        FROM xxcop_wk_yoko_planning xwyp
        WHERE xwyp.transaction_id         = gn_transaction_id
          AND xwyp.request_id             = cn_request_id
          AND xwyp.receipt_date           = gd_planning_date
          AND xwyp.ship_organization_id  <> gn_source_org_id
        GROUP BY xwyp.shipping_date
                ,xwyp.ship_loct_id
                ,xwyp.item_id
      )
      SELECT MAX(receipt_date)                        receipt_date
            ,rcpt_loct_id                             rcpt_loct_id
            ,item_id                                  item_id
            ,shipping_type                            shipping_type
      FROM (
        SELECT xwyp.receipt_date                      receipt_date
              ,xwyp.rcpt_loct_id                      rcpt_loct_id
              ,xwyp.item_id                           item_id
              ,xwyp.shipping_type                     shipping_type
        FROM xxcop_wk_yoko_planning xwyp
            ,ship_loct_vw           slv
        WHERE xwyp.transaction_id         = gn_transaction_id
          AND xwyp.request_id             = cn_request_id
          AND xwyp.receipt_date           > gd_allocated_date
          AND xwyp.shipping_date          = slv.shipping_date
          AND xwyp.ship_loct_id           = slv.ship_loct_id
          AND xwyp.item_id                = slv.item_id
          AND xwyp.shipping_type          = NVL(gv_plan_type, xwyp.shipping_type)
          AND CASE
                WHEN xwyp.shipping_type = cv_plan_type_shipped  THEN
                  xwyp.shipping_pace
                WHEN xwyp.shipping_type = cv_plan_type_forecate THEN
                  xwyp.forecast_pace
                ELSE
                  0
              END > 0
        UNION ALL
        SELECT xwyp.receipt_date                      receipt_date
              ,xwyp.rcpt_loct_id                      rcpt_loct_id
              ,xwyp.item_id                           item_id
              ,xwyp.shipping_type                     shipping_type
        FROM xxcop_wk_yoko_planning xwyp
            ,ship_loct_vw           slv
        WHERE xwyp.transaction_id         = gn_transaction_id
          AND xwyp.request_id             = cn_request_id
          AND xwyp.receipt_date           > gd_allocated_date
          AND xwyp.shipping_date          = slv.shipping_date
          AND xwyp.rcpt_loct_id           = slv.ship_loct_id
          AND xwyp.item_id                = slv.item_id
          AND xwyp.ship_organization_id   = gn_source_org_id
          AND xwyp.shipping_type          = NVL(gv_plan_type, xwyp.shipping_type)
          AND CASE
                WHEN xwyp.shipping_type = cv_plan_type_shipped  THEN
                  xwyp.shipping_pace
                WHEN xwyp.shipping_type = cv_plan_type_forecate THEN
                  xwyp.forecast_pace
                ELSE
                  0
              END > 0
      )
      GROUP BY rcpt_loct_id
              ,item_id
              ,shipping_type
    ;
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_MOD_END
--
    -- *** ローカル・レコード ***
    l_gsat_tab                      g_sa_ttype;     --出荷ペース在庫引当コレクション型
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
    --初期化
    lt_latest_shipment_date   := NULL;
    ln_working_day            := NULL;
    l_gsat_tab.DELETE;
--
    --出荷引当済日以降の場合、出荷ペースを横持計画手持在庫テーブルに登録
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_DEL_START
--    IF (gd_planning_date > gd_allocated_date) THEN
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_DEL_END
    <<rcpt_loct_loop>>
    FOR l_rcpt_rec IN rcpt_loct_cur LOOP
      BEGIN
        --出荷ペーストランザクションが作成された日付を取得
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_MOD_START
--        SELECT NVL(MAX(xli.schedule_date), gd_allocated_date)    latest_shipment_date
        SELECT NVL(MAX(xli.shipment_date), gd_allocated_date)    latest_shipment_date
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_MOD_END
        INTO lt_latest_shipment_date
        FROM xxcop_loct_inv xli
        WHERE xli.transaction_id   = gn_transaction_id
          AND xli.request_id       = cn_request_id
          AND xli.loct_id          = l_rcpt_rec.rcpt_loct_id
          AND xli.item_id          = l_rcpt_rec.item_id
          AND xli.transaction_type = cv_xli_type_sp
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_MOD_START
--          AND xli.schedule_date    > gd_allocated_date
          AND xli.shipment_date    > gd_allocated_date
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_MOD_END
        ;
        --出荷ペーストランザクションが着日まで作成されている場合、以降をスキップ
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_MOD_START
--        IF (lt_latest_shipment_date >= gd_planning_date) THEN
        IF (lt_latest_shipment_date >= l_rcpt_rec.receipt_date) THEN
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_MOD_END
          RAISE not_need_expt;
        END IF;
        --倉庫-品目の鮮度条件を取得
        SELECT xwyp.item_id                                       item_id
              ,xwyp.item_no                                       item_no
              ,xwyp.rcpt_organization_id                          rcpt_organization_id
              ,xwyp.rcpt_organization_code                        rcpt_organization_code
              ,xwyp.rcpt_loct_id                                  rcpt_loct_id
              ,xwyp.rcpt_loct_code                                rcpt_loct_code
              ,xwyp.rcpt_calendar_code                            rcpt_calendar_code
              ,xwyp.shipping_type                                 shipping_type
              ,CASE
                 WHEN xwyp.shipping_type = cv_plan_type_shipped  THEN
                   xwyp.shipping_pace
                 WHEN xwyp.shipping_type = cv_plan_type_forecate THEN
                   xwyp.forecast_pace
                 ELSE
                   0
               END                                                shipping_pace
              ,xwyp.freshness_priority                            freshness_priority
              ,xwyp.freshness_class                               freshness_class
              ,xwyp.freshness_check_value                         freshness_check_value
              ,xwyp.freshness_adjust_value                        freshness_adjust_value
              ,xwyp.max_stock_days                                max_stock_days
              ,0                                                  allocate_quantity
        BULK COLLECT INTO l_gsat_tab
        FROM xxcop_wk_yoko_planning xwyp
        WHERE xwyp.transaction_id   = gn_transaction_id
          AND xwyp.request_id       = cn_request_id
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_MOD_START
--          AND xwyp.receipt_date     = gd_planning_date
          AND xwyp.receipt_date     = l_rcpt_rec.receipt_date
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_MOD_END
          AND xwyp.shipping_type    = l_rcpt_rec.shipping_type
          AND xwyp.rcpt_loct_id     = l_rcpt_rec.rcpt_loct_id
          AND xwyp.item_id          = l_rcpt_rec.item_id
          AND CASE
                WHEN xwyp.shipping_type = cv_plan_type_shipped  THEN
                  xwyp.shipping_pace
                WHEN xwyp.shipping_type = cv_plan_type_forecate THEN
                  xwyp.forecast_pace
                ELSE
                  0
              END > 0
        GROUP BY xwyp.item_id
                ,xwyp.item_no
                ,xwyp.rcpt_organization_id
                ,xwyp.rcpt_organization_code
                ,xwyp.rcpt_loct_id
                ,xwyp.rcpt_loct_code
                ,xwyp.rcpt_calendar_code
                ,xwyp.shipping_type
                ,xwyp.freshness_priority
                ,xwyp.freshness_class
                ,xwyp.freshness_check_value
                ,xwyp.freshness_adjust_value
                ,xwyp.max_stock_days
                ,xwyp.shipping_pace
                ,xwyp.forecast_pace
        ORDER BY xwyp.freshness_priority
        ;
        --品目の全ての鮮度条件で出荷ペースが0の場合、以降をスキップ
        IF (l_gsat_tab.COUNT = 0) THEN
          RAISE not_need_expt;
        END IF;
        --出荷ペーストランザクションを着日まで作成
        lt_latest_shipment_date := lt_latest_shipment_date + 1;
        <<date_loop>>
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_MOD_START
--        WHILE (lt_latest_shipment_date <= gd_planning_date) LOOP
        WHILE (lt_latest_shipment_date <= l_rcpt_rec.receipt_date) LOOP
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_MOD_END
          --稼働日チェック
          xxcop_common_pkg2.get_working_days(
             iv_calendar_code   => l_gsat_tab(1).rcpt_calendar_code
            ,in_organization_id => l_gsat_tab(1).rcpt_organization_id
            ,in_loct_id         => l_gsat_tab(1).rcpt_loct_id
            ,id_from_date       => lt_latest_shipment_date
            ,id_to_date         => lt_latest_shipment_date
            ,on_working_days    => ln_working_day
            ,ov_errbuf          => lv_errbuf
            ,ov_retcode         => lv_retcode
            ,ov_errmsg          => lv_errmsg
          );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_api_expt;
          END IF;
          --非稼働日の場合、スキップ
          IF (ln_working_day > 0) THEN
            --横持計画手持在庫テーブル登録に登録
            -- ===============================
            -- B-16．横持計画手持在庫テーブル登録(出荷ペース)
            -- ===============================
            entry_xli_shipment(
               it_shipment_date   => lt_latest_shipment_date
              ,io_gsat_tab        => l_gsat_tab
              ,ov_errbuf          => lv_errbuf
              ,ov_retcode         => lv_retcode
              ,ov_errmsg          => lv_errmsg
            );
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_api_expt;
            END IF;
          END IF;
          --日付をインクリメント
          lt_latest_shipment_date := lt_latest_shipment_date + 1;
        END LOOP date_loop;
      EXCEPTION
        WHEN not_need_expt THEN
          NULL;
      END;
    END LOOP rcpt_loct_loop;
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_DEL_START
--    END IF;
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_DEL_END
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
  END get_shipment_schedule;
--
  /**********************************************************************************
   * Procedure Name   : create_yoko_plan
   * Description      : 横持計画作成(B-9)
   ***********************************************************************************/
  PROCEDURE create_yoko_plan(
    iv_assign_type   IN     VARCHAR2,       --   割当セット区分
    ov_errbuf        OUT    VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT    VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg        OUT    VARCHAR2        --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_yoko_plan'; -- プログラム名
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
    lv_safety_result                VARCHAR2(1);    --安全在庫数判定
    lv_stock_result                 VARCHAR2(1);    --在庫引当判定
--
    l_item_tab                      g_item_ttype;   --品目コレクション型
    l_ship_tab                      g_loct_ttype;   --移動元倉庫コレクション型
    l_rcpt_tab                      g_loct_ttype;   --移動先倉庫コレクション型
    l_gfqt_tab                      g_fq_ttype;     --鮮度条件別在庫引当コレクション型
    l_gbqt_tab                      g_bq_ttype;     --移動元倉庫バランス横持計画コレクション型
    l_xwypo_tab                     g_xwypo_ttype;  --横持計画出力ワークテーブルコレクション型
    l_git_tab                       g_idx_ttype;    --インデックスコレクション型
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
--
    --初期化
    lv_safety_result                := NULL;
    lv_stock_result                 := NULL;
    l_item_tab.DELETE;
    l_ship_tab.DELETE;
    l_rcpt_tab.DELETE;
    l_gfqt_tab.DELETE;
    l_gbqt_tab.DELETE;
    l_xwypo_tab.DELETE;
    l_git_tab.DELETE;
--
    -- ===============================
    -- 移動先倉庫の取得
    -- ===============================
    SELECT xwyp.rcpt_loct_id              loct_id
          ,xwyp.rcpt_loct_code            loct_code
          ,NULL                           delivery_lead_time
          ,NULL                           shipping_pace
          ,NULL                           target_date
    BULK COLLECT INTO l_rcpt_tab
    FROM xxcop_wk_yoko_planning xwyp
    WHERE xwyp.transaction_id        = gn_transaction_id
      AND xwyp.request_id            = cn_request_id
      AND xwyp.planning_flag         = cv_planning_yes
      AND xwyp.receipt_date          = gd_planning_date
      AND xwyp.assignment_set_type   = iv_assign_type
      AND xwyp.shipping_type         = NVL(gv_plan_type, xwyp.shipping_type)
      AND CASE
            WHEN xwyp.shipping_type  = cv_plan_type_shipped  THEN
              xwyp.shipping_pace
            WHEN xwyp.shipping_type  = cv_plan_type_forecate THEN
              xwyp.forecast_pace
            ELSE
              0
          END > 0
      AND xwyp.ship_organization_id <> gn_source_org_id
    GROUP BY xwyp.rcpt_loct_id
            ,xwyp.rcpt_loct_code
            ,xwyp.sy_manufacture_date
    ORDER BY MIN(xwyp.shipping_date)
            ,xwyp.sy_manufacture_date
            ,xwyp.rcpt_loct_code
    ;
    <<rcpt_loop>>
    FOR ln_rcpt_idx IN 1 .. l_rcpt_tab.COUNT LOOP
      -- ===============================
      -- 品目の取得
      -- ===============================
      SELECT xwyp.item_id               item_id
            ,xwyp.item_no               item_no
      BULK COLLECT INTO l_item_tab
      FROM xxcop_wk_yoko_planning xwyp
      WHERE xwyp.transaction_id        = gn_transaction_id
        AND xwyp.request_id            = cn_request_id
        AND xwyp.planning_flag         = cv_planning_yes
        AND xwyp.receipt_date          = gd_planning_date
        AND xwyp.assignment_set_type   = iv_assign_type
        AND xwyp.shipping_type         = NVL(gv_plan_type, xwyp.shipping_type)
        AND CASE
              WHEN xwyp.shipping_type  = cv_plan_type_shipped  THEN
                xwyp.shipping_pace
              WHEN xwyp.shipping_type  = cv_plan_type_forecate THEN
                xwyp.forecast_pace
              ELSE
                0
            END > 0
        AND xwyp.ship_organization_id <> gn_source_org_id
        AND xwyp.rcpt_loct_id          = l_rcpt_tab(ln_rcpt_idx).loct_id
      GROUP BY xwyp.item_id
              ,xwyp.item_no
      ORDER BY xwyp.item_no
      ;
      <<item_loop>>
      FOR ln_item_idx IN 1 .. l_item_tab.COUNT LOOP
        BEGIN
          -- ===============================
          -- 鮮度条件取得
          -- ===============================
          SELECT xwyp.freshness_priority          freshness_priority
                ,xwyp.freshness_condition         freshness_condition
                ,xwyp.freshness_class             freshness_class
                ,xwyp.freshness_check_value       freshness_check_value
                ,xwyp.freshness_adjust_value      freshness_adjust_value
                ,xwyp.safety_stock_days           safety_stock_days
                ,xwyp.max_stock_days              max_stock_days
                ,CASE
                   WHEN xwyp.shipping_type = cv_plan_type_shipped  THEN
                     xwyp.total_shipping_pace
                   WHEN xwyp.shipping_type = cv_plan_type_forecate THEN
                     xwyp.total_forecast_pace
                   ELSE
                     0
                 END                              shipping_pace
                ,CASE
                   WHEN xwyp.shipping_type = cv_plan_type_shipped  THEN
                     xwyp.safety_stock_days * xwyp.total_shipping_pace
                   WHEN xwyp.shipping_type = cv_plan_type_forecate THEN
                     xwyp.safety_stock_days * xwyp.total_forecast_pace
                   ELSE
                     0
                 END                              safety_stock_quantity
                ,CASE
                   WHEN xwyp.shipping_type = cv_plan_type_shipped  THEN
                     xwyp.max_stock_days * xwyp.total_shipping_pace
                   WHEN xwyp.shipping_type = cv_plan_type_forecate THEN
                     xwyp.max_stock_days * xwyp.total_forecast_pace
                   ELSE
                     0
                 END                              max_stock_quantity
                ,0                                allocate_quantity
                ,xwyp.sy_manufacture_date         sy_manufacture_date
                ,xwyp.sy_maxmum_quantity          sy_maxmum_quantity
                ,xwyp.sy_stocked_quantity         sy_stocked_quantity
          BULK COLLECT INTO l_gfqt_tab
          FROM xxcop_wk_yoko_planning xwyp
          WHERE xwyp.transaction_id      = gn_transaction_id
            AND xwyp.request_id          = cn_request_id
            AND xwyp.planning_flag       = cv_planning_yes
            AND xwyp.receipt_date        = gd_planning_date
            AND xwyp.assignment_set_type = iv_assign_type
            AND xwyp.shipping_type       = NVL(gv_plan_type, xwyp.shipping_type)
            AND xwyp.rcpt_loct_id        = l_rcpt_tab(ln_rcpt_idx).loct_id
            AND xwyp.item_id             = l_item_tab(ln_item_idx).item_id
            AND CASE
                  WHEN xwyp.shipping_type = cv_plan_type_shipped  THEN
                    xwyp.max_stock_days * xwyp.total_shipping_pace
                  WHEN xwyp.shipping_type = cv_plan_type_forecate THEN
                    xwyp.max_stock_days * xwyp.total_forecast_pace
                  ELSE
                    0
                END > 0
          GROUP BY xwyp.freshness_priority
                  ,xwyp.freshness_condition
                  ,xwyp.freshness_class
                  ,xwyp.freshness_check_value
                  ,xwyp.freshness_adjust_value
                  ,xwyp.safety_stock_days
                  ,xwyp.max_stock_days
                  ,xwyp.shipping_type
                  ,xwyp.total_shipping_pace
                  ,xwyp.total_forecast_pace
                  ,xwyp.sy_manufacture_date
                  ,xwyp.sy_maxmum_quantity
                  ,xwyp.sy_stocked_quantity
          ORDER BY xwyp.freshness_priority DESC
          ;
          --品目の全ての鮮度条件が対象外の場合、以降をスキップ
          IF (l_gfqt_tab.COUNT = 0) THEN
            RAISE not_need_expt;
          END IF;
          -- ===============================
          -- B-17．安全在庫の計算
          -- ===============================
          proc_safety_quantity(
             iv_assign_type   => iv_assign_type
            ,it_loct_id       => l_rcpt_tab(ln_rcpt_idx).loct_id
            ,i_item_rec       => l_item_tab(ln_item_idx)
            ,io_gfqt_tab      => l_gfqt_tab
            ,ov_stock_result  => lv_stock_result
            ,ov_errbuf        => lv_errbuf
            ,ov_retcode       => lv_retcode
            ,ov_errmsg        => lv_errmsg
          );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_api_expt;
          END IF;
          --安全在庫以上在庫がある場合、以降をスキップ
          IF (lv_stock_result = cv_enough) THEN
            --デバックメッセージ出力(安全在庫あり)
            xxcop_common_pkg.put_debug_message(
               iov_debug_mode => gv_debug_mode
              ,iv_value       => cv_indent_2 || cv_prg_name || ':'
                              || 'rcpt_loct_check:'
                              || 'safe_balance_proc:'
                              || iv_assign_type                     || ','
                              || l_rcpt_tab(ln_rcpt_idx).loct_code  || ','
                              || l_item_tab(ln_item_idx).item_no    || ','
            );
            RAISE not_need_expt;
          END IF;
          --デバックメッセージ出力(安全在庫なし)
          xxcop_common_pkg.put_debug_message(
             iov_debug_mode => gv_debug_mode
            ,iv_value       => cv_indent_2 || cv_prg_name || ':'
                            || 'rcpt_loct_check:'
                            || 'need_balance_proc:'
                            || iv_assign_type                     || ','
                            || l_rcpt_tab(ln_rcpt_idx).loct_code  || ','
                            || l_item_tab(ln_item_idx).item_no    || ','
          );
          -- ===============================
          -- 移動元倉庫取得
          -- ===============================
          WITH xwyp_ship_vw AS (
            SELECT xwyp.ship_loct_id              ship_loct_id
                  ,xwyp.ship_loct_code            ship_loct_code
                  ,xwyp.delivery_lead_time        delivery_lead_time
                  ,xwyp.shipping_date             shipping_date
            FROM xxcop_wk_yoko_planning xwyp
            WHERE xwyp.transaction_id         = gn_transaction_id
              AND xwyp.request_id             = cn_request_id
              AND xwyp.planning_flag          = cv_planning_yes
              AND xwyp.receipt_date           = gd_planning_date
              AND xwyp.assignment_set_type    = iv_assign_type
              AND xwyp.ship_organization_id  <> gn_source_org_id
              AND xwyp.shipping_type          = NVL(gv_plan_type, xwyp.shipping_type)
              AND xwyp.rcpt_loct_id           = l_rcpt_tab(ln_rcpt_idx).loct_id
              AND xwyp.item_id                = l_item_tab(ln_item_idx).item_id
            GROUP BY xwyp.ship_loct_id
                    ,xwyp.ship_loct_code
                    ,xwyp.delivery_lead_time
                    ,xwyp.shipping_date
          )
          , xwyp_rcpt_vw AS (
            SELECT xrv.ship_loct_id               ship_loct_id
                  ,xrv.rcpt_loct_id               rcpt_loct_id
                  ,xrv.shipping_pace              shipping_pace
            FROM (
              SELECT xwyp.ship_loct_id            ship_loct_id
                    ,xwyp.rcpt_loct_id            rcpt_loct_id
                    ,SUM(CASE
                           WHEN xwyp.shipping_type = cv_plan_type_shipped  THEN
                             xwyp.shipping_pace
                           WHEN xwyp.shipping_type = cv_plan_type_forecate THEN
                             xwyp.forecast_pace
                           ELSE
                             0
                         END)                     shipping_pace
                    ,ROW_NUMBER() OVER (PARTITION BY xwyp.rcpt_loct_id
                                        ORDER BY     xwyp.ship_loct_id
                                  )               row_number
              FROM xxcop_wk_yoko_planning xwyp
                  ,xwyp_ship_vw           xsv
              WHERE xwyp.transaction_id      = gn_transaction_id
                AND xwyp.request_id          = cn_request_id
                AND xwyp.receipt_date        = gd_planning_date
                AND xwyp.assignment_set_type = iv_assign_type
                AND xwyp.shipping_type       = NVL(gv_plan_type, xwyp.shipping_type)
                AND xwyp.rcpt_loct_id        = xsv.ship_loct_id
                AND xwyp.item_id             = l_item_tab(ln_item_idx).item_id
              GROUP BY xwyp.rcpt_loct_id
                      ,xwyp.ship_loct_id
            ) xrv
            WHERE xrv.row_number = 1
          )
          SELECT xsv.ship_loct_id                 loct_id
                ,xsv.ship_loct_code               loct_code
                ,xsv.delivery_lead_time           delivery_lead_time
                ,NVL(xrv.shipping_pace, 0)        shipping_pace 
                ,xsv.shipping_date                target_date
          BULK COLLECT INTO l_ship_tab
          FROM xwyp_ship_vw xsv
              ,xwyp_rcpt_vw xrv
          WHERE xsv.ship_loct_id = xrv.rcpt_loct_id(+)
          ;
          -- ===============================
          -- B-18．移動元倉庫の特定
          -- ===============================
          proc_ship_loct(
             i_item_rec       => l_item_tab(ln_item_idx)
            ,i_ship_tab       => l_ship_tab
            ,i_gfqt_tab       => l_gfqt_tab
            ,o_git_tab        => l_git_tab
            ,ov_errbuf        => lv_errbuf
            ,ov_retcode       => lv_retcode
            ,ov_errmsg        => lv_errmsg
          );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_api_expt;
          END IF;
          --デバックメッセージ出力
          xxcop_common_pkg.put_debug_message(
             iov_debug_mode => gv_debug_mode
            ,iv_value       => '=============================================================='
          );
          <<balance_loop>>
          FOR ln_git_idx IN l_git_tab.FIRST .. l_git_tab.LAST LOOP
            --デバックメッセージ出力
            xxcop_common_pkg.put_debug_message(
               iov_debug_mode => gv_debug_mode
              ,iv_value       => cv_indent_2 || cv_prg_name || ':'
                              || 'ship_loct_code:'
                              || '(' || ln_git_idx || ')' || ','
                              || l_ship_tab(l_git_tab(ln_git_idx)).loct_code || ','
                              || l_item_tab(ln_item_idx).item_no             || ','
                              || TO_CHAR(l_ship_tab(l_git_tab(ln_git_idx)).target_date, cv_date_format) || ','
            );
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_ADD_START
            SAVEPOINT pre_balance_proc_svp;
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_ADD_END
            -- ===============================
            -- B-19．バランス計画数の計算
            -- ===============================
            proc_balance_quantity(
               iv_assign_type   => iv_assign_type
              ,i_item_rec       => l_item_tab(ln_item_idx)
              ,i_ship_rec       => l_ship_tab(l_git_tab(ln_git_idx))
              ,i_rcpt_rec       => l_rcpt_tab(ln_rcpt_idx)
              ,i_gfqt_tab       => l_gfqt_tab
              ,o_gbqt_tab       => l_gbqt_tab
              ,o_xwypo_tab      => l_xwypo_tab
              ,ov_stock_result  => lv_stock_result
              ,ov_errbuf        => lv_errbuf
              ,ov_retcode       => lv_retcode
              ,ov_errmsg        => lv_errmsg
            );
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_api_expt;
            END IF;
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_MOD_START
----
--            BEGIN
--              --バランス計画数のトランザクションを削除
--              DELETE xxcop_loct_inv xli
--              WHERE xli.transaction_id    = gn_transaction_id
--                AND xli.request_id        = cn_request_id
--                AND xli.transaction_type  = cv_xli_type_bq
--                AND xli.simulate_flag     = cv_simulate_yes
--              ;
--            EXCEPTION
--              WHEN NO_DATA_FOUND THEN
--                NULL;
--              WHEN OTHERS THEN
--                lv_errbuf := SQLERRM;
--                lv_errmsg := xxccp_common_pkg.get_msg(
--                                iv_application  => cv_msg_appl_cont
--                               ,iv_name         => cv_msg_00042
--                               ,iv_token_name1  => cv_msg_00042_token_1
--                               ,iv_token_value1 => cv_table_xli
--                             );
--                RAISE global_api_expt;
--            END;
            ROLLBACK TO SAVEPOINT pre_balance_proc_svp;
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_MOD_END
--
            --バランス計算結果を判定
            IF (lv_stock_result IN (cv_complete, cv_incomplete)) THEN
              --バランス計算で移動元倉庫から移動先倉庫に移動が可能な場合
              -- ===============================
              -- B-20．計画ロットの決定
              -- ===============================
              proc_lot_quantity(
                 i_item_rec             => l_item_tab(ln_item_idx)
                ,i_ship_rec             => l_ship_tab(l_git_tab(ln_git_idx))
                ,i_rcpt_rec             => l_rcpt_tab(ln_rcpt_idx)
                ,it_sy_manufacture_date => l_gfqt_tab(1).sy_manufacture_date
                ,io_gbqt_tab            => l_gbqt_tab
                ,io_xwypo_tab           => l_xwypo_tab
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_ADD_START
                ,ov_stock_result        => lv_stock_result
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_ADD_END
                ,ov_errbuf              => lv_errbuf
                ,ov_retcode             => lv_retcode
                ,ov_errmsg              => lv_errmsg
              );
              IF (lv_retcode = cv_status_error) THEN
                RAISE global_api_expt;
              END IF;
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_DEL_START
--              --全ての鮮度条件で最大在庫まで横持計画ができた場合、以降をスキップ
--              IF (lv_stock_result = cv_complete) THEN
--                EXIT balance_loop;
--              END IF;
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_DEL_END
            END IF;
            -- ===============================
            -- B-21．横持計画手持在庫テーブル登録(計画不可)
            -- ===============================
            entry_supply_failed(
               i_rcpt_rec       => l_rcpt_tab(ln_rcpt_idx)
              ,io_xwypo_tab     => l_xwypo_tab
              ,ov_errbuf        => lv_errbuf
              ,ov_retcode       => lv_retcode
              ,ov_errmsg        => lv_errmsg
            );
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_api_expt;
            END IF;
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_ADD_START
            --全ての鮮度条件で最大在庫まで横持計画ができた場合、以降をスキップ
            IF (lv_stock_result = cv_complete) THEN
              EXIT balance_loop;
            END IF;
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_ADD_END
          END LOOP balance_loop;
--
          BEGIN
            --対象倉庫以外のトランザクションを削除
            DELETE xxcop_loct_inv xli
            WHERE xli.transaction_id    = gn_transaction_id
              AND xli.request_id        = cn_request_id
              AND xli.simulate_flag     = cv_simulate_yes
            ;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              NULL;
            WHEN OTHERS THEN
              lv_errbuf := SQLERRM;
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => cv_msg_appl_cont
                             ,iv_name         => cv_msg_00042
                             ,iv_token_name1  => cv_msg_00042_token_1
                             ,iv_token_value1 => cv_table_xli
                           );
              RAISE global_api_expt;
          END;
--
        EXCEPTION
          WHEN not_need_expt THEN
            NULL;
        END;
      END LOOP item_loop;
    END LOOP rcpt_loop;
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
  END create_yoko_plan;
--
  /**********************************************************************************
   * Procedure Name   : output_xwypo
   * Description      : 横持計画CSV成形(B-10)
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
    ln_plan_min_quantity      NUMBER;                     --計画数（最小）
    ln_plan_max_quantity      NUMBER;                     --計画数（最大）
--
    -- *** ローカル・カーソル ***
    CURSOR xwypo_cur IS
      WITH xwypo_supply_vw AS (
        SELECT xwypo.transaction_id                             transaction_id
              ,xwypo.request_id                                 request_id
              ,xwypo.shipping_date                              shipping_date
              ,xwypo.receipt_date                               receipt_date
              ,xwypo.ship_loct_id                               ship_loct_id
              ,xwypo.rcpt_loct_id                               rcpt_loct_id
              ,xwypo.item_id                                    item_id
              ,xwypo.freshness_condition                        freshness_condition
              ,xwypo.assignment_set_type                        assignment_set_type
              ,CASE WHEN SUM(xwypo.plan_lot_quantity) >= (xwypo.max_stock_quantity - MIN(xwypo.before_stock))
                 THEN cv_supply_enough
                 ELSE cv_supply_shortage
               END                                              supply_status
        FROM xxcop_wk_yoko_plan_output  xwypo
        WHERE xwypo.transaction_id      = gn_transaction_id
          AND xwypo.request_id          = cn_request_id
        GROUP BY xwypo.transaction_id
                ,xwypo.request_id
                ,xwypo.shipping_date
                ,xwypo.receipt_date
                ,xwypo.ship_loct_id
                ,xwypo.rcpt_loct_id
                ,xwypo.item_id
                ,xwypo.freshness_condition
                ,xwypo.assignment_set_type
                ,xwypo.max_stock_quantity
      )
      , xwypo_rcpt_supply_vw AS (
        SELECT xsv.transaction_id                               transaction_id
              ,xsv.request_id                                   request_id
              ,xsv.receipt_date                                 receipt_date
              ,xsv.rcpt_loct_id                                 rcpt_loct_id
              ,xsv.item_id                                      item_id
              ,xsv.freshness_condition                          freshness_condition
              ,MAX(xsv.supply_status)                           supply_status
        FROM xwypo_supply_vw            xsv
        GROUP BY xsv.transaction_id
                ,xsv.request_id
                ,xsv.receipt_date
                ,xsv.rcpt_loct_id
                ,xsv.item_id
                ,xsv.freshness_condition
      )
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_ADD_START
      , xwypo_rcpt_lot_vw AS (
        SELECT xwypov.transaction_id                              transaction_id
              ,xwypov.request_id                                  request_id
              ,xwypov.receipt_date                                receipt_date
              ,xwypov.rcpt_loct_id                                rcpt_loct_id
              ,xwypov.item_id                                     item_id
              ,xwypov.freshness_condition                         freshness_condition
              ,xwypov.manufacture_date                            manufacture_date
              ,MIN(xwypov.before_lot_stock)                       before_lot_stock
        FROM (
          SELECT xwypo.transaction_id                             transaction_id
                ,xwypo.request_id                                 request_id
                ,xwypo.shipping_date                              shipping_date
                ,xwypo.receipt_date                               receipt_date
                ,xwypo.ship_loct_id                               ship_loct_id
                ,xwypo.rcpt_loct_id                               rcpt_loct_id
                ,xwypo.item_id                                    item_id
                ,xwypo.freshness_condition                        freshness_condition
                ,xwypo.assignment_set_type                        assignment_set_type
                ,xwypo.manufacture_date                           manufacture_date
                ,SUM(xwypo.before_lot_stock)                      before_lot_stock
          FROM xxcop_wk_yoko_plan_output    xwypo
          WHERE xwypo.transaction_id      = gn_transaction_id
            AND xwypo.request_id          = cn_request_id
            AND xwypo.manufacture_date   IS NOT NULL
          GROUP BY xwypo.transaction_id
                  ,xwypo.request_id
                  ,xwypo.shipping_date
                  ,xwypo.receipt_date
                  ,xwypo.ship_loct_id
                  ,xwypo.rcpt_loct_id
                  ,xwypo.item_id
                  ,xwypo.freshness_condition
                  ,xwypo.assignment_set_type
                  ,xwypo.manufacture_date
        ) xwypov
        GROUP BY xwypov.transaction_id
                ,xwypov.request_id
                ,xwypov.receipt_date
                ,xwypov.rcpt_loct_id
                ,xwypov.item_id
                ,xwypov.freshness_condition
                ,xwypov.manufacture_date
      )
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_ADD_END
      SELECT xwypo.rowid                                        xwypo_rowid
            ,xwypo.transaction_id                               transaction_id
            ,xwypo.request_id                                   request_id
            ,xwypo.shipping_date                                shipping_date
            ,xwypo.receipt_date                                 receipt_date
            ,xwypo.ship_loct_id                                 ship_loct_id
            ,xwypo.rcpt_loct_id                                 rcpt_loct_id
            ,xwypo.item_id                                      item_id
            ,xwypo.freshness_condition                          freshness_condition
            ,xwypo.assignment_set_type                          assignment_set_type
            ,xwypo.manufacture_date                             manufacture_date
            ,xwypo.safety_stock_quantity                        safety_stock_quantity
            ,xwypo.max_stock_quantity                           max_stock_quantity
            ,xwypo.before_stock                                 before_stock
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_MOD_START
--            ,SUM(xwypo.before_lot_stock) OVER (PARTITION BY xwypo.transaction_id
--                                                           ,xwypo.request_id
--                                                           ,xwypo.shipping_date
--                                                           ,xwypo.receipt_date
--                                                           ,xwypo.ship_loct_id
--                                                           ,xwypo.rcpt_loct_id
--                                                           ,xwypo.item_id
--                                                           ,xwypo.freshness_condition
--                                                           ,xwypo.assignment_set_type
--                                                           ,xwypo.manufacture_date
--                                         )                      before_lot_stock
            ,NVL(xrlv.before_lot_stock, xwypo.before_lot_stock) before_lot_stock
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_MOD_END
            ,SUM(xwypo.plan_lot_quantity) OVER (PARTITION BY xwypo.transaction_id
                                                            ,xwypo.request_id
                                                            ,xwypo.shipping_date
                                                            ,xwypo.receipt_date
                                                            ,xwypo.ship_loct_id
                                                            ,xwypo.rcpt_loct_id
                                                            ,xwypo.item_id
                                                            ,xwypo.freshness_condition
                                                            ,xwypo.assignment_set_type
                                                            ,xwypo.manufacture_date
                                          )                     plan_lot_quantity
            ,DENSE_RANK() OVER (PARTITION BY xwypo.transaction_id
                                            ,xwypo.request_id
                                            ,xwypo.shipping_date
                                            ,xwypo.receipt_date
                                            ,xwypo.ship_loct_code
                                            ,xwypo.rcpt_loct_code
                                            ,xwypo.item_no
                                            ,xwypo.freshness_condition
                                            ,xwypo.assignment_set_type
                                ORDER BY     xwypo.transaction_id
                                            ,xwypo.request_id
                                            ,xwypo.shipping_date
                                            ,xwypo.receipt_date
                                            ,xwypo.ship_loct_code
                                            ,xwypo.rcpt_loct_code
                                            ,xwypo.item_no
                                            ,xwypo.freshness_condition
                                            ,xwypo.assignment_set_type
                                            ,xwypo.manufacture_date
                          )                                     output_num
            ,ROW_NUMBER() OVER (PARTITION BY xwypo.transaction_id
                                            ,xwypo.request_id
                                            ,xwypo.shipping_date
                                            ,xwypo.receipt_date
                                            ,xwypo.ship_loct_code
                                            ,xwypo.rcpt_loct_code
                                            ,xwypo.item_no
                                            ,xwypo.freshness_condition
                                            ,xwypo.assignment_set_type
                                            ,xwypo.manufacture_date
                                ORDER BY     xwypo.transaction_id
                                            ,xwypo.request_id
                                            ,xwypo.shipping_date
                                            ,xwypo.receipt_date
                                            ,xwypo.ship_loct_code
                                            ,xwypo.rcpt_loct_code
                                            ,xwypo.item_no
                                            ,xwypo.freshness_condition
                                            ,xwypo.assignment_set_type
                                            ,xwypo.manufacture_date
                          )                                     duplex_num
            ,xrsv.supply_status                                 supply_status
      FROM xxcop_wk_yoko_plan_output    xwypo
          ,xwypo_rcpt_supply_vw         xrsv
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_ADD_START
          ,xwypo_rcpt_lot_vw            xrlv
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_ADD_END
      WHERE xwypo.transaction_id      = gn_transaction_id
        AND xwypo.request_id          = cn_request_id
        AND xwypo.transaction_id      = xrsv.transaction_id
        AND xwypo.request_id          = xrsv.request_id
        AND xwypo.receipt_date        = xrsv.receipt_date
        AND xwypo.rcpt_loct_id        = xrsv.rcpt_loct_id
        AND xwypo.item_id             = xrsv.item_id
        AND xwypo.freshness_condition = xrsv.freshness_condition
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_ADD_START
        AND xwypo.transaction_id      = xrlv.transaction_id(+)
        AND xwypo.request_id          = xrlv.request_id(+)
        AND xwypo.receipt_date        = xrlv.receipt_date(+)
        AND xwypo.rcpt_loct_id        = xrlv.rcpt_loct_id(+)
        AND xwypo.item_id             = xrlv.item_id(+)
        AND xwypo.freshness_condition = xrlv.freshness_condition(+)
        AND xwypo.manufacture_date    = xrlv.manufacture_date(+)
--20091217_Ver3.1_E_本稼動_00519_SCS.Goto_ADD_END
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
    --初期化
    ln_plan_min_quantity      := NULL;
    ln_plan_max_quantity      := NULL;
--
    <<xwypo_loop>>
    FOR l_xwypo_rec IN xwypo_cur LOOP
      IF (l_xwypo_rec.duplex_num = 1) THEN
        --計画数（最小）の計算
        ln_plan_min_quantity := l_xwypo_rec.safety_stock_quantity - l_xwypo_rec.before_stock
        ;
        --計画数（最大）の計算
        ln_plan_max_quantity := l_xwypo_rec.max_stock_quantity    - l_xwypo_rec.before_stock
        ;
        --出力項目の更新
        UPDATE xxcop_wk_yoko_plan_output xwypo
        SET    xwypo.plan_min_quantity    = GREATEST(ln_plan_min_quantity, 0)
              ,xwypo.plan_max_quantity    = GREATEST(ln_plan_max_quantity, 0)
              ,xwypo.plan_lot_quantity    = l_xwypo_rec.plan_lot_quantity
              ,xwypo.before_lot_stock     = l_xwypo_rec.before_lot_stock
              ,xwypo.after_lot_stock      = l_xwypo_rec.before_lot_stock + l_xwypo_rec.plan_lot_quantity
              ,xwypo.special_yoko_flag    = CASE WHEN l_xwypo_rec.assignment_set_type = cv_base_plan
                                              THEN NULL
                                              ELSE cv_csv_mark
                                            END
              ,xwypo.short_supply_flag    = CASE WHEN l_xwypo_rec.supply_status = cv_supply_enough
                                              THEN NULL
                                              ELSE cv_csv_mark
                                            END
              ,xwypo.output_num           = l_xwypo_rec.output_num
        WHERE xwypo.rowid               = l_xwypo_rec.xwypo_rowid
        ;
      ELSE
        --重複製造年月日の削除
        DELETE xxcop_wk_yoko_plan_output xwypo
        WHERE xwypo.rowid = l_xwypo_rec.xwypo_rowid
        ;
      END IF;
    END LOOP xwypo_loop;
--
    --横持計画出力ワークテーブル更新
    UPDATE xxcop_wk_yoko_plan_output xwypo
    SET    xwypo.output_flag        = cv_output_on
    WHERE xwypo.transaction_id      = gn_transaction_id
      AND xwypo.request_id          = cn_request_id
    ;
    gn_target_cnt := SQL%ROWCOUNT;
    gn_normal_cnt := SQL%ROWCOUNT;
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
--20100203_Ver3.4_E_本稼動_01222_SCS.Goto_ADD_START
    ,iv_working_days        IN     VARCHAR2                 --10.稼動日数
    ,iv_stock_adjust_value  IN     VARCHAR2                 --11.在庫日数調整値
--20100203_Ver3.4_E_本稼動_01222_SCS.Goto_ADD_END
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
    --初期化
    ld_planning_date_from          := NULL;
    ld_planning_date_to            := NULL;
--
    BEGIN
      -- ===============================
      -- B-1．初期処理
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
--20100203_Ver3.4_E_本稼動_01222_SCS.Goto_ADD_START
       ,iv_working_days        => iv_working_days             -- 稼動日数
       ,iv_stock_adjust_value  => iv_stock_adjust_value       -- 在庫日数調整値
--20100203_Ver3.4_E_本稼動_01222_SCS.Goto_ADD_END
        ,ov_errbuf             => lv_errbuf                   -- エラー・メッセージ           --# 固定 #
        ,ov_retcode            => lv_retcode                  -- リターン・コード             --# 固定 #
        ,ov_errmsg             => lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
      -- ===============================
      -- B-2．横持計画制御マスタ取得
      -- ===============================
      get_msr_route(
         ov_errbuf        => lv_errbuf        -- エラー・メッセージ           --# 固定 #
        ,ov_retcode       => lv_retcode       -- リターン・コード             --# 固定 #
        ,ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_warn) THEN
        RAISE obsolete_skip_expt;
      ELSIF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
      -- ===============================
      -- B-3．代表倉庫取得
      -- ===============================
      entry_xwyl(
         ov_errbuf        => lv_errbuf        -- エラー・メッセージ           --# 固定 #
        ,ov_retcode       => lv_retcode       -- リターン・コード             --# 固定 #
        ,ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
      -- ===============================
      -- B-4．出荷ペースの計算
      -- ===============================
      proc_shipping_pace(
         ov_errbuf        => lv_errbuf        -- エラー・メッセージ           --# 固定 #
        ,ov_retcode       => lv_retcode       -- リターン・コード             --# 固定 #
        ,ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
      -- ===============================
      -- B-5．総出荷ペースの計算
      -- ===============================
      proc_total_pace(
         ov_errbuf        => lv_errbuf        -- エラー・メッセージ           --# 固定 #
        ,ov_retcode       => lv_retcode       -- リターン・コード             --# 固定 #
        ,ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
      -- ===============================
      -- B-6．手持在庫テーブル作成
      -- ===============================
      create_xli(
         ov_errbuf        => lv_errbuf        -- エラー・メッセージ           --# 固定 #
        ,ov_retcode       => lv_retcode       -- リターン・コード             --# 固定 #
        ,ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
      -- ===============================
      -- B-7. 基準計画トランザクション作成
      -- ===============================
      get_msd_schedule(
         ov_errbuf        => lv_errbuf        -- エラー・メッセージ           --# 固定 #
        ,ov_retcode       => lv_retcode       -- リターン・コード             --# 固定 #
        ,ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
      -- ===============================
      -- 計画立案期間(FROM-TO)
      -- ===============================
      <<planning_loop>>
      FOR l_planning_rec IN (
        SELECT xwyp.receipt_date    receipt_date
        FROM xxcop_wk_yoko_planning xwyp
        WHERE xwyp.transaction_id         = gn_transaction_id
          AND xwyp.request_id             = cn_request_id
          AND xwyp.planning_flag          = cv_planning_yes
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_ADD_START
          AND xwyp.ship_organization_id  <> gn_source_org_id
--20100125_Ver3.3_E_本稼動_01250_SCS.Goto_ADD_END
        GROUP BY xwyp.receipt_date
        ORDER BY xwyp.receipt_date
      ) LOOP
        gd_planning_date := l_planning_rec.receipt_date;
        xxcop_common_pkg.put_debug_message(
           iov_debug_mode => gv_debug_mode
          ,iv_value       => '========================================' || ','
        );
        --デバックメッセージ出力(計画立案日)
        xxcop_common_pkg.put_debug_message(
           iov_debug_mode => gv_debug_mode
          ,iv_value       => cv_prg_name || ':' || 'planning_date:'
                          || TO_CHAR(gd_planning_date, cv_date_format)  || ','
        );
        xxcop_common_pkg.put_debug_message(
           iov_debug_mode => gv_debug_mode
          ,iv_value       => '========================================' || ','
        );
        -- ===============================
        -- B-8．出荷トランザクション作成
        -- ===============================
        get_shipment_schedule(
           ov_errbuf        => lv_errbuf        -- エラー・メッセージ           --# 固定 #
          ,ov_retcode       => lv_retcode       -- リターン・コード             --# 固定 #
          ,ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
        -- ===============================
        -- B-9. 横持計画作成(特別横持計画)
        -- ===============================
        create_yoko_plan(
           iv_assign_type   => cv_custom_plan   -- 割当セット区分(特別横持計画)
          ,ov_errbuf        => lv_errbuf        -- エラー・メッセージ           --# 固定 #
          ,ov_retcode       => lv_retcode       -- リターン・コード             --# 固定 #
          ,ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
        -- ===============================
        -- B-9. 横持計画作成(基本横持計画)
        -- ===============================
        create_yoko_plan(
           iv_assign_type   => cv_base_plan     -- 割当セット区分(基本横持計画)
          ,ov_errbuf        => lv_errbuf        -- エラー・メッセージ           --# 固定 #
          ,ov_retcode       => lv_retcode       -- リターン・コード             --# 固定 #
          ,ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
        -- 計画立案日をインクリメント
        gd_planning_date := gd_planning_date + 1;
      END LOOP planning_loop;
--
      -- ===============================
      -- B-10. 横持計画CSV成形
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
      WHEN global_process_expt THEN
        --対象件数、エラー件数のカウント
        gn_target_cnt := gn_target_cnt + 1;
        gn_error_cnt  := gn_error_cnt + 1;
        --SQLERRMメッセージが設定されている場合、共通例外
        IF (lv_errbuf IS NOT NULL) THEN
          RAISE global_process_expt;
        ELSE
          RAISE internal_api_expt;
        END IF;
      WHEN obsolete_skip_expt THEN
        NULL;
    END;
--
  EXCEPTION
    WHEN internal_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
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
--20100203_Ver3.4_E_本稼動_01222_SCS.Goto_ADD_START
    ,iv_working_days        IN     VARCHAR2                 --10.稼動日数
    ,iv_stock_adjust_value  IN     VARCHAR2                 --11.在庫日数調整値
--20100203_Ver3.4_E_本稼動_01222_SCS.Goto_ADD_END
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
--20100203_Ver3.4_E_本稼動_01222_SCS.Goto_ADD_START
      ,iv_working_days       => iv_working_days             -- 稼動日数
      ,iv_stock_adjust_value => iv_stock_adjust_value       -- 在庫日数調整値
--20100203_Ver3.4_E_本稼動_01222_SCS.Goto_ADD_END
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
    IF (lv_retcode <> cv_status_normal) THEN
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
--    fnd_file.put_line(
--       which  => FND_FILE.OUTPUT
--      ,buff => gv_out_msg
--    );
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
--    fnd_file.put_line(
--       which  => FND_FILE.OUTPUT
--      ,buff => gv_out_msg
--    );
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
--    fnd_file.put_line(
--       which  => FND_FILE.OUTPUT
--      ,buff => gv_out_msg
--    );
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
--    fnd_file.put_line(
--       which  => FND_FILE.OUTPUT
--      ,buff => gv_out_msg
--    );
    --CSV出力のためログに出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff => gv_out_msg
    );
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
--    fnd_file.put_line(
--       which  => FND_FILE.OUTPUT
--      ,buff => gv_out_msg
--    );
    --CSV出力のためログに出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
--    --終了ステータスがエラーの場合はROLLBACKする
--    IF (retcode = cv_status_error) THEN
--      ROLLBACK;
--    END IF;
    --ワークテーブルの内容を残すためCOMMITする
    COMMIT;
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
END XXCOP006A011C;
/
