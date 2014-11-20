CREATE OR REPLACE PACKAGE BODY XXCOI006A09C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI006A09C(body)
 * Description      : 資材取引情報を元に月次在庫受払表（日次）を作成します
 * MD.050           : 日次在庫受払表作成<MD050_COI_006_A09>
 * Version          : 1.11
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                         Description
 * ---------------------------- ----------------------------------------------------------
 *  set_last_daily_sum           前月サマリ情報出力                   (A-7)
 *  finalize                     終了処理                             (A-9)
 *  set_reception_sum            累計受払データ出力                   (A-8)
 *  upd_last_transaction_id      最終取引ID更新                       (A-6)
 *  set_last_daily_data          当日未取引データ受払出力             (A-5)
 *                               前日受払データ抽出                   (A-4)
 *  set_mtl_transaction_data     当日データ月次在庫受払（日次）出力   (A-3)
 *                               資材取引データ抽出（日次）           (A-2)
 *  set_mtl_transaction_data2    当日データ月次在庫受払（累計）出力   (A-10)
 *                               資材取引データ抽出（累計）           (A-11)
 *  init                         初期処理                             (A-1)
 *  submain                      メイン処理プロシージャ
 *  main                         コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/05    1.0   Sai.u            新規作成
 *  2009/04/06    1.1   H.Sasaki         [T1_0197]月次在庫受払表（累計）の作成
 *  2009/05/08    1.2   T.Nakamura       [T1_0839]拠点間移動オーダーを受払データ作成対象に追加
 *  2009/05/14    1.3   H.Sasaki         [T1_0840][T1_0842]倉替数量の集計条件変更
 *  2009/05/28    1.4   H.Sasaki         [T1_1234]累計テーブルの作成方法修正
 *  2009/06/04    1.5   H.Sasaki         [T1_1324]当日取引データにて消化VDを対象外とする
 *  2009/06/05    1.6   H.Sasaki         [T1_1123]入出庫０の場合、累計データを作成しない
 *  2009/07/30    1.7   N.Abe            [0000638]数量の取得項目修正
 *  2009/08/26    1.8   N.Abe            [0000956]PT対応(起動パラメータによる処理分割)
 *  2009/08/31    1.9   H.Sasaki         [0001220]前日データ反映時の原価設定方法を修正
 *  2009/09/16    1.10  H.Sasaki         [0001384]PT対応（当日取引なしの場合、受払作成を行わない）
 *  2009/10/15    1.11  H.Sasaki         [E_最終移行リハ_00494]Ver1.10の修正
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
  lock_error_expt           EXCEPTION;
  PRAGMA EXCEPTION_INIT(lock_error_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name           CONSTANT VARCHAR2(100) := 'XXCOI006A09C'; -- パッケージ名
  -- 日付型
  cv_date               CONSTANT VARCHAR2(8)  :=  'YYYYMMDD';
  cv_month              CONSTANT VARCHAR2(6)  :=  'YYYYMM';
-- == 2009/08/26 V1.8 Added START ===============================================================
  cv_date_time          CONSTANT VARCHAR2(21) :=  'YYYY/MM/DD HH24:MI:SS';
-- == 2009/08/26 V1.8 Added END   ===============================================================
  -- 保管場所区分（1:倉庫  2:営業車  3:預け先  4:専門店）
  cv_subinv_1           CONSTANT VARCHAR2(1)  :=  '1';
  cv_subinv_2           CONSTANT VARCHAR2(1)  :=  '2';
  cv_subinv_3           CONSTANT VARCHAR2(1)  :=  '3';
  cv_subinv_4           CONSTANT VARCHAR2(1)  :=  '4';
  -- メッセージ関連
  cv_short_name         CONSTANT VARCHAR2(30) :=  'XXCOI';
  cv_msg_xxcoi1_00005   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-00005';
  cv_msg_xxcoi1_00006   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-00006';
  cv_msg_xxcoi1_00011   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-00011';
  cv_msg_xxcoi1_00023   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-00023';
  cv_msg_xxcoi1_10126   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10126';
  cv_msg_xxcoi1_10127   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10127';
  cv_msg_xxcoi1_10128   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10128';
  cv_msg_xxcoi1_10363   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10363';
  cv_msg_xxcoi1_10285   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10285';
  cv_msg_xxcoi1_10293   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10293';
-- == 2009/04/06 V1.1 Added START ===============================================================
  cv_msg_xxcoi1_10378   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10378';
-- == 2009/04/06 V1.1 Added END   ===============================================================
-- == 2009/08/26 V1.8 Added START ===============================================================
  cv_msg_xxcoi1_10365   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10365';         -- コンカレント入力パラメータ
  cv_msg_xxcoi1_10400   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10400';         -- 対象日未来日メッセージ
  cv_msg_xxcoi1_10401   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10401';         -- パラメータ対象日付メッセージ
-- == 2009/08/26 V1.8 Added END   ===============================================================
  cv_token_00005_1      CONSTANT VARCHAR2(30) :=  'PRO_TOK';
  cv_token_00006_1      CONSTANT VARCHAR2(30) :=  'ORG_CODE_TOK';
-- == 2009/08/26 V1.8 Added START ===============================================================
  cv_token_10365_1      CONSTANT VARCHAR2(30) :=  'EXEC_FLAG';
  cv_token_10401_1      CONSTANT VARCHAR2(30) :=  'DATE';
-- == 2009/08/26 V1.8 Added END   ===============================================================
  -- 受払集計キー（取引タイプ）
  cv_trans_type_010     CONSTANT VARCHAR2(3)  :=  '10';        -- 売上出庫
  cv_trans_type_020     CONSTANT VARCHAR2(3)  :=  '20';        -- 売上出庫振戻
  cv_trans_type_030     CONSTANT VARCHAR2(3)  :=  '30';        -- 返品
  cv_trans_type_040     CONSTANT VARCHAR2(3)  :=  '40';        -- 返品振戻
  cv_trans_type_050     CONSTANT VARCHAR2(3)  :=  '50';        -- 入出庫
  cv_trans_type_060     CONSTANT VARCHAR2(3)  :=  '60';        -- 倉替
  cv_trans_type_070     CONSTANT VARCHAR2(3)  :=  '70';        -- 商品振替（旧商品）
  cv_trans_type_080     CONSTANT VARCHAR2(3)  :=  '80';        -- 商品振替（新商品）
  cv_trans_type_090     CONSTANT VARCHAR2(3)  :=  '90';        -- 見本出庫
  cv_trans_type_100     CONSTANT VARCHAR2(3)  :=  '100';       -- 見本出庫振戻
  cv_trans_type_110     CONSTANT VARCHAR2(3)  :=  '110';       -- 顧客見本出庫
  cv_trans_type_120     CONSTANT VARCHAR2(3)  :=  '120';       -- 顧客見本出庫振戻
  cv_trans_type_130     CONSTANT VARCHAR2(3)  :=  '130';       -- 顧客協賛見本出庫
  cv_trans_type_140     CONSTANT VARCHAR2(3)  :=  '140';       -- 顧客協賛見本出庫振戻
  cv_trans_type_150     CONSTANT VARCHAR2(3)  :=  '150';       -- 消化VD補充
  cv_trans_type_160     CONSTANT VARCHAR2(3)  :=  '160';       -- 基準在庫変更
  cv_trans_type_170     CONSTANT VARCHAR2(3)  :=  '170';       -- 工場返品
  cv_trans_type_180     CONSTANT VARCHAR2(3)  :=  '180';       -- 工場返品振戻
  cv_trans_type_190     CONSTANT VARCHAR2(3)  :=  '190';       -- 工場倉替
  cv_trans_type_200     CONSTANT VARCHAR2(3)  :=  '200';       -- 工場倉替振戻
  cv_trans_type_210     CONSTANT VARCHAR2(3)  :=  '210';       -- 廃却
  cv_trans_type_220     CONSTANT VARCHAR2(3)  :=  '220';       -- 廃却振戻
  cv_trans_type_230     CONSTANT VARCHAR2(3)  :=  '230';       -- 工場入庫
  cv_trans_type_240     CONSTANT VARCHAR2(3)  :=  '240';       -- 工場入庫振戻
  cv_trans_type_250     CONSTANT VARCHAR2(3)  :=  '250';       -- 顧客広告宣伝費A自社商品
  cv_trans_type_260     CONSTANT VARCHAR2(3)  :=  '260';       -- 顧客広告宣伝費A自社商品振戻
  cv_trans_type_270     CONSTANT VARCHAR2(3)  :=  '270';       -- 棚卸減耗益
  cv_trans_type_280     CONSTANT VARCHAR2(3)  :=  '280';       -- 棚卸減耗損
  cv_trans_type_290     CONSTANT VARCHAR2(3)  :=  '290';       -- 移動オーダー移動
  -- その他
  cn_control_id         CONSTANT NUMBER       :=  50;                           -- データ連携制御ID（日次）
-- == 2009/08/26 V1.8 Added START ===============================================================
  cn_control_id2        CONSTANT NUMBER       :=  80;                           -- データ連携制御ID（累計）
-- == 2009/08/26 V1.8 Added END   ===============================================================
  cv_prf_name_orgcd     CONSTANT VARCHAR2(30) :=  'XXCOI1_ORGANIZATION_CODE';   -- プロファイル名（在庫組織コード）
  cv_pgsname_a09c       CONSTANT VARCHAR2(30) :=  'XXCOI006A09C';               -- データ連携制御テーブル用プログラム名
-- == 2009/08/26 V1.8 Added START ===============================================================
  cv_pgsname_b09c       CONSTANT VARCHAR2(12) :=  'XXCOI006B09C';               -- プログラム名(累計)
-- == 2009/08/26 V1.8 Added END   ===============================================================
  cv_space              CONSTANT VARCHAR2(1)  :=  ' ';                          -- 半角スペース（ログ空行用）
  cv_inv_type_5         CONSTANT VARCHAR2(1)  :=  '5';                          -- 保管場所区分（自販機）
  cv_inv_type_8         CONSTANT VARCHAR2(1)  :=  '8';                          -- 保管場所区分（直送）
-- == 2009/06/04 V1.5 Added START ===============================================================
  cv_subinv_class_7     CONSTANT VARCHAR2(1)  :=  '7';        -- 保管場所分類（7:消化VD）
-- == 2009/06/04 V1.5 Added END   ===============================================================
-- == 2009/08/26 V1.8 Added START ===============================================================
  cv_0                  CONSTANT VARCHAR2(1)  :=  '0';        -- 起動フラグ：月次在庫受払表(日次)作成
  cv_1                  CONSTANT VARCHAR2(1)  :=  '1';        -- 起動フラグ：月次在庫受払表(累計)作成
-- == 2009/08/26 V1.8 Added END   ===============================================================
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  TYPE quantity_type IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  gt_quantity           quantity_type;      -- 取引タイプ別数量
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 初期処理設定値
  gd_f_business_date          DATE;               -- 業務処理日付
  gv_f_organization_code      VARCHAR2(10);       -- 在庫組織コード
  gn_f_organization_id        NUMBER;             -- 在庫組織ID
  gn_f_last_transaction_id    NUMBER;             -- 処理済取引ID
  gd_f_last_cooperation_date  DATE;               -- 前回最終連携日
  gn_f_max_transaction_id     NUMBER;             -- 最大取引ID
  gd_f_max_practice_date      DATE;               -- 日次データ最大年月日（前月）
-- == 2009/08/26 V1.8 Added START ===============================================================
  gv_exec_flag                VARCHAR2(1);        -- 起動フラグ(0:日次作成,1:累計作成)
-- == 2009/08/26 V1.8 Added END   ===============================================================
-- == 2009/10/15 V1.11 Added START ===============================================================
  gn_material_flag            NUMBER;             -- 対象データ存在チェックフラグ
-- == 2009/10/15 V1.11 Added START ===============================================================
--
-- == 2009/08/26 V1.8 Delete START ===============================================================
--  /**********************************************************************************
--   * Procedure Name   : finalize
--   * Description      : 終了処理(A-9)
--   ***********************************************************************************/
--  PROCEDURE finalize(
--    ov_errbuf         OUT VARCHAR2,                     -- エラー・メッセージ                  --# 固定 #
--    ov_retcode        OUT VARCHAR2,                     -- リターン・コード                    --# 固定 #
--    ov_errmsg         OUT VARCHAR2)                     -- ユーザー・エラー・メッセージ        --# 固定 #
--  IS
--    -- ===============================
--    -- 固定ローカル定数
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'finalize'; -- プログラム名
----
----#######################  固定ローカル変数宣言部 START   ######################
----
--    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
--    lv_retcode VARCHAR2(1);     -- リターン・コード
--    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
----
----###########################  固定部 END   ####################################
----
--    -- ===============================
--    -- ユーザー宣言部
--    -- ===============================
--    -- *** ローカル定数 ***
----
--    -- *** ローカル変数 ***
----
--    -- ===============================
--    -- ローカル・カーソル
--    -- ===============================
--    -- <カーソル名>
--    -- <カーソル名>レコード型
--  BEGIN
----
----##################  固定ステータス初期化部 START   ###################
----
--    ov_retcode := cv_status_normal;
----
----###########################  固定部 END   ############################
----
--    -- ***************************************
--    -- ***        ループ処理の記述         ***
--    -- ***       処理部の呼び出し          ***
--    -- ***************************************
----
--    --==============================================================
--    --メッセージ出力をする必要がある場合は処理を記述
--    --==============================================================
----
--    -- 処理件数をカウント
--    SELECT  COUNT(1)
--    INTO    gn_target_cnt
--    FROM    xxcoi_inv_reception_daily
--    WHERE   request_id    =   cn_request_id;
--    -- 正常件数を設定
--    gn_normal_cnt   :=  gn_target_cnt;
----
--  EXCEPTION
----#################################  固定例外処理部 START   ####################################
----
--    -- *** 処理部共通例外ハンドラ ***
--    WHEN global_process_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** 共通関数例外ハンドラ ***
--    WHEN global_api_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
----
----#####################################  固定部 END   ##########################################
----
--  END finalize;
-- == 2009/08/26 V1.8 Delete END   ===============================================================
--
-- == 2009/05/28 V1.4 Modified START ===============================================================
-- == 2009/04/06 V1.1 Added START ===============================================================
--  /**********************************************************************************
--   * Procedure Name   : set_reception_sum
--   * Description      : 累計受払データ出力(A-7)(A-8)
--   ***********************************************************************************/
--  PROCEDURE set_reception_sum(
--    ov_errbuf                   OUT VARCHAR2,                     -- エラー・メッセージ                  --# 固定 #
--    ov_retcode                  OUT VARCHAR2,                     -- リターン・コード                    --# 固定 #
--    ov_errmsg                   OUT VARCHAR2)                     -- ユーザー・エラー・メッセージ        --# 固定 #
--  IS
--    -- ===============================
--    -- 固定ローカル定数
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_reception_sum'; -- プログラム名
----
----#######################  固定ローカル変数宣言部 START   ######################
----
--    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
--    lv_retcode VARCHAR2(1);     -- リターン・コード
--    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
----
----###########################  固定部 END   ####################################
----
--    -- ===============================
--    -- ユーザー宣言部
--    -- ===============================
--    -- *** ローカル定数 ***
----
--    -- *** ローカル変数 ***
--    ln_dummy      NUMBER;       -- ダミー変数
----
--    -- ===============================
--    -- ローカル・カーソル
--    -- ===============================
--    -- 累計情報取得カーソル
--    CURSOR  sum_data_cur
--    IS
--      SELECT  xird.base_code                  base_code                             -- 拠点コード
--             ,xird.organization_id            organization_id                       -- 組織ID
--             ,xird.subinventory_type          subinventory_type                     -- 保管場所区分
--             ,xird.subinventory_code          subinventory_code                     -- 保管場所
--             ,SUBSTRB(TO_CHAR(xird.practice_date, cv_date), 1, 6)
--                                              practice_date                         -- 年月
--             ,xird.inventory_item_id          inventory_item_id                     -- 品目ID
--             ,xird.operation_cost             operation_cost                        -- 営業原価
--             ,xird.standard_cost              standard_cost                         -- 標準原価
--             ,xird.sales_shipped              sales_shipped                         -- 売上出庫
--             ,xird.sales_shipped_b            sales_shipped_b                       -- 売上出庫振戻
--             ,xird.return_goods               return_goods                          -- 返品
--             ,xird.return_goods_b             return_goods_b                        -- 返品振戻
--             ,xird.warehouse_ship             warehouse_ship                        -- 倉庫へ返庫
--             ,xird.truck_ship                 truck_ship                            -- 営業車へ出庫
--             ,xird.others_ship                others_ship                           -- 入出庫＿その他出庫
--             ,xird.warehouse_stock            warehouse_stock                       -- 倉庫より入庫
--             ,xird.truck_stock                truck_stock                           -- 営業車より入庫
--             ,xird.others_stock               others_stock                          -- 入出庫＿その他入庫
--             ,xird.change_stock               change_stock                          -- 倉替入庫
--             ,xird.change_ship                change_ship                           -- 倉替出庫
--             ,xird.goods_transfer_old         goods_transfer_old                    -- 商品振替（旧商品）
--             ,xird.goods_transfer_new         goods_transfer_new                    -- 商品振替（新商品）
--             ,xird.sample_quantity            sample_quantity                       -- 見本出庫
--             ,xird.sample_quantity_b          sample_quantity_b                     -- 見本出庫振戻
--             ,xird.customer_sample_ship       customer_sample_ship                  -- 顧客見本出庫
--             ,xird.customer_sample_ship_b     customer_sample_ship_b                -- 顧客見本出庫振戻
--             ,xird.customer_support_ss        customer_support_ss                   -- 顧客協賛見本出庫
--             ,xird.customer_support_ss_b      customer_support_ss_b                 -- 顧客協賛見本出庫振戻
--             ,xird.vd_supplement_stock        vd_supplement_stock                   -- 消化VD補充入庫
--             ,xird.vd_supplement_ship         vd_supplement_ship                    -- 消化VD補充出庫
--             ,xird.inventory_change_in        inventory_change_in                   -- 基準在庫変更入庫
--             ,xird.inventory_change_out       inventory_change_out                  -- 基準在庫変更出庫
--             ,xird.factory_return             factory_return                        -- 工場返品
--             ,xird.factory_return_b           factory_return_b                      -- 工場返品振戻
--             ,xird.factory_change             factory_change                        -- 工場倉替
--             ,xird.factory_change_b           factory_change_b                      -- 工場倉替振戻
--             ,xird.removed_goods              removed_goods                         -- 廃却
--             ,xird.removed_goods_b            removed_goods_b                       -- 廃却振戻
--             ,xird.factory_stock              factory_stock                         -- 工場入庫
--             ,xird.factory_stock_b            factory_stock_b                       -- 工場入庫振戻
--             ,xird.ccm_sample_ship            ccm_sample_ship                       -- 顧客広告宣伝費A自社商品
--             ,xird.ccm_sample_ship_b          ccm_sample_ship_b                     -- 顧客広告宣伝費A自社商品振戻
--             ,xird.wear_decrease              wear_decrease                         -- 棚卸減耗増
--             ,xird.wear_increase              wear_increase                         -- 棚卸減耗減
--             ,xird.selfbase_ship              selfbase_ship                         -- 保管場所移動＿自拠点出庫
--             ,xird.selfbase_stock             selfbase_stock                        -- 保管場所移動＿自拠点入庫
--             ,xird.book_inventory_quantity    book_inventory_quantity               -- 帳簿在庫数
--      FROM    xxcoi_inv_reception_daily   xird                                      -- 月次在庫受払表（日時）
--      WHERE   xird.request_id     =   cn_request_id;
--    --
--    -- 累計情報取得レコード型
--    sum_data_rec  sum_data_cur%ROWTYPE;
--    --
--  BEGIN
----
----##################  固定ステータス初期化部 START   ###################
----
--    ov_retcode := cv_status_normal;
----
----###########################  固定部 END   ############################
----
--    -- ***************************************
--    -- ***        ループ処理の記述         ***
--    -- ***       処理部の呼び出し          ***
--    -- ***************************************
----
--    --==============================================================
--    --メッセージ出力をする必要がある場合は処理を記述
--    --==============================================================
----
--    <<set_sum_data_loop>>
--    FOR sum_data_rec IN sum_data_cur LOOP
--      BEGIN
--        -- ===================================
--        --  1.累計テーブルロック取得
--        -- ===================================
--        SELECT  1
--        INTO    ln_dummy
--        FROM    xxcoi_inv_reception_sum   xirs
--        WHERE   xirs.base_code            =   sum_data_rec.base_code
--        AND     xirs.subinventory_code    =   sum_data_rec.subinventory_code
--        AND     xirs.inventory_item_id    =   sum_data_rec.inventory_item_id
--        AND     xirs.practice_date        =   sum_data_rec.practice_date
--        AND     ROWNUM                    =   1
--        FOR UPDATE NOWAIT;
--        --
--        -- ===================================
--        --  2.累計テーブル更新
--        -- ===================================
--        -- ロックが取得された場合、入出庫数を更新する
--        UPDATE  xxcoi_inv_reception_sum
--        SET     sales_shipped             = sales_shipped           + sum_data_rec.sales_shipped            -- 01.売上出庫
--               ,sales_shipped_b           = sales_shipped_b         + sum_data_rec.sales_shipped_b          -- 02.売上出庫振戻
--               ,return_goods              = return_goods            + sum_data_rec.return_goods             -- 03.返品
--               ,return_goods_b            = return_goods_b          + sum_data_rec.return_goods_b           -- 04.返品振戻
--               ,warehouse_ship            = warehouse_ship          + sum_data_rec.warehouse_ship           -- 05.倉庫へ返庫
--               ,truck_ship                = truck_ship              + sum_data_rec.truck_ship               -- 06.営業車へ出庫
--               ,others_ship               = others_ship             + sum_data_rec.others_ship              -- 07.入出庫＿その他出庫
--               ,warehouse_stock           = warehouse_stock         + sum_data_rec.warehouse_stock          -- 08.倉庫より入庫
--               ,truck_stock               = truck_stock             + sum_data_rec.truck_stock              -- 09.営業車より入庫
--               ,others_stock              = others_stock            + sum_data_rec.others_stock             -- 10.入出庫＿その他入庫
--               ,change_stock              = change_stock            + sum_data_rec.change_stock             -- 11.倉替入庫
--               ,change_ship               = change_ship             + sum_data_rec.change_ship              -- 12.倉替出庫
--               ,goods_transfer_old        = goods_transfer_old      + sum_data_rec.goods_transfer_old       -- 13.商品振替（旧商品）
--               ,goods_transfer_new        = goods_transfer_new      + sum_data_rec.goods_transfer_new       -- 14.商品振替（新商品）
--               ,sample_quantity           = sample_quantity         + sum_data_rec.sample_quantity          -- 15.見本出庫
--               ,sample_quantity_b         = sample_quantity_b       + sum_data_rec.sample_quantity_b        -- 16.見本出庫振戻
--               ,customer_sample_ship      = customer_sample_ship    + sum_data_rec.customer_sample_ship     -- 17.顧客見本出庫
--               ,customer_sample_ship_b    = customer_sample_ship_b  + sum_data_rec.customer_sample_ship_b   -- 18.顧客見本出庫振戻
--               ,customer_support_ss       = customer_support_ss     + sum_data_rec.customer_support_ss      -- 19.顧客協賛見本出庫
--               ,customer_support_ss_b     = customer_support_ss_b   + sum_data_rec.customer_support_ss_b    -- 20.顧客協賛見本出庫振戻
--               ,ccm_sample_ship           = ccm_sample_ship         + sum_data_rec.ccm_sample_ship          -- 21.顧客広告宣伝費A自社商品
--               ,ccm_sample_ship_b         = ccm_sample_ship_b       + sum_data_rec.ccm_sample_ship_b        -- 22.顧客広告宣伝費A自社商品振戻
--               ,vd_supplement_stock       = vd_supplement_stock     + sum_data_rec.vd_supplement_stock      -- 23.消化VD補充入庫
--               ,vd_supplement_ship        = vd_supplement_ship      + sum_data_rec.vd_supplement_ship       -- 24.消化VD補充出庫
--               ,inventory_change_in       = inventory_change_in     + sum_data_rec.inventory_change_in      -- 25.基準在庫変更入庫
--               ,inventory_change_out      = inventory_change_out    + sum_data_rec.inventory_change_out     -- 26.基準在庫変更出庫
--               ,factory_return            = factory_return          + sum_data_rec.factory_return           -- 27.工場返品
--               ,factory_return_b          = factory_return_b        + sum_data_rec.factory_return_b         -- 28.工場返品振戻
--               ,factory_change            = factory_change          + sum_data_rec.factory_change           -- 29.工場倉替
--               ,factory_change_b          = factory_change_b        + sum_data_rec.factory_change_b         -- 30.工場倉替振戻
--               ,removed_goods             = removed_goods           + sum_data_rec.removed_goods            -- 31.廃却
--               ,removed_goods_b           = removed_goods_b         + sum_data_rec.removed_goods_b          -- 32.廃却振戻
--               ,factory_stock             = factory_stock           + sum_data_rec.factory_stock            -- 33.工場入庫
--               ,factory_stock_b           = factory_stock_b         + sum_data_rec.factory_stock_b          -- 34.工場入庫振戻
--               ,wear_decrease             = wear_decrease           + sum_data_rec.wear_decrease            -- 35.棚卸減耗増
--               ,wear_increase             = wear_increase           + sum_data_rec.wear_increase            -- 36.棚卸減耗減
--               ,selfbase_ship             = selfbase_ship           + sum_data_rec.selfbase_ship            -- 37.保管場所移動＿自拠点出庫
--               ,selfbase_stock            = selfbase_stock          + sum_data_rec.selfbase_stock           -- 38.保管場所移動＿自拠点入庫
--               ,book_inventory_quantity   = sum_data_rec.book_inventory_quantity                            -- 39.帳簿在庫数
--               ,last_updated_by           = cn_last_updated_by                                              -- 40.最終更新者
--               ,last_update_date          = SYSDATE                                                         -- 41.最終更新日
--               ,last_update_login         = cn_last_update_login                                            -- 42.最終更新ログイン
--               ,request_id                = cn_request_id                                                   -- 43.要求ID
--               ,program_application_id    = cn_program_application_id                                       -- 44.コンカレント・プログラム・アプリケーションID
--               ,program_id                = cn_program_id                                                   -- 45.コンカレント・プログラムID
--               ,program_update_date       = SYSDATE                                                         -- 46.プログラム更新日
--        WHERE   base_code                 = sum_data_rec.base_code
--        AND     subinventory_code         = sum_data_rec.subinventory_code
--        AND     inventory_item_id         = sum_data_rec.inventory_item_id
--        AND     practice_date             = sum_data_rec.practice_date;
--        --
--      EXCEPTION
--        WHEN  lock_error_expt THEN
--          -- ロックが取得されなかった場合
--          -- 月次在庫受払（累計）ロックエラーメッセージ
--          lv_errmsg   := xxccp_common_pkg.get_msg(
--                           iv_application  => cv_short_name
--                          ,iv_name         => cv_msg_xxcoi1_10378
--                         );
--          lv_errbuf   := lv_errmsg;
--          RAISE global_process_expt;
--          --
--        WHEN NO_DATA_FOUND THEN
--          -- ===================================
--          --  3.累計テーブル作成
--          -- ===================================
--          -- 対象データが存在しない場合、累計情報を新規作成する
--          INSERT INTO xxcoi_inv_reception_sum(
--            base_code                                   -- 01.拠点コード
--           ,organization_id                             -- 02.組織ID
--           ,subinventory_code                           -- 03.保管場所
--           ,subinventory_type                           -- 04.保管場所区分
--           ,practice_date                               -- 05.年月
--           ,inventory_item_id                           -- 06.品目ID
--           ,operation_cost                              -- 07.営業原価
--           ,standard_cost                               -- 08.標準原価
--           ,sales_shipped                               -- 09.売上出庫
--           ,sales_shipped_b                             -- 10.売上出庫振戻
--           ,return_goods                                -- 11.返品
--           ,return_goods_b                              -- 12.返品振戻
--           ,warehouse_ship                              -- 13.倉庫へ返庫
--           ,truck_ship                                  -- 14.営業車へ出庫
--           ,others_ship                                 -- 15.入出庫＿その他出庫
--           ,warehouse_stock                             -- 16.倉庫より入庫
--           ,truck_stock                                 -- 17.営業車より入庫
--           ,others_stock                                -- 18.入出庫＿その他入庫
--           ,change_stock                                -- 19.倉替入庫
--           ,change_ship                                 -- 20.倉替出庫
--           ,goods_transfer_old                          -- 21.商品振替（旧商品）
--           ,goods_transfer_new                          -- 22.商品振替（新商品）
--           ,sample_quantity                             -- 23.見本出庫
--           ,sample_quantity_b                           -- 24.見本出庫振戻
--           ,customer_sample_ship                        -- 25.顧客見本出庫
--           ,customer_sample_ship_b                      -- 26.顧客見本出庫振戻
--           ,customer_support_ss                         -- 27.顧客協賛見本出庫
--           ,customer_support_ss_b                       -- 28.顧客協賛見本出庫振戻
--           ,ccm_sample_ship                             -- 29.顧客広告宣伝費A自社商品
--           ,ccm_sample_ship_b                           -- 30.顧客広告宣伝費A自社商品振戻
--           ,vd_supplement_stock                         -- 31.消化VD補充入庫
--           ,vd_supplement_ship                          -- 32.消化VD補充出庫
--           ,inventory_change_in                         -- 33.基準在庫変更入庫
--           ,inventory_change_out                        -- 34.基準在庫変更出庫
--           ,factory_return                              -- 35.工場返品
--           ,factory_return_b                            -- 36.工場返品振戻
--           ,factory_change                              -- 37.工場倉替
--           ,factory_change_b                            -- 38.工場倉替振戻
--           ,removed_goods                               -- 39.廃却
--           ,removed_goods_b                             -- 40.廃却振戻
--           ,factory_stock                               -- 41.工場入庫
--           ,factory_stock_b                             -- 42.工場入庫振戻
--           ,wear_decrease                               -- 43.棚卸減耗増
--           ,wear_increase                               -- 44.棚卸減耗減
--           ,selfbase_ship                               -- 45.保管場所移動＿自拠点出庫
--           ,selfbase_stock                              -- 46.保管場所移動＿自拠点入庫
--           ,book_inventory_quantity                     -- 47.帳簿在庫数
--           ,created_by                                  -- 48.作成者
--           ,creation_date                               -- 49.作成日
--           ,last_updated_by                             -- 50.最終更新者
--           ,last_update_date                            -- 51.最終更新日
--           ,last_update_login                           -- 52.最終更新ログイン
--           ,request_id                                  -- 53.要求ID
--           ,program_application_id                      -- 54.コンカレント・プログラム・アプリケーションID
--           ,program_id                                  -- 55.コンカレント・プログラムID
--           ,program_update_date                         -- 56.プログラム更新日
--          )VALUES(
--            sum_data_rec.base_code                      -- 01
--           ,sum_data_rec.organization_id                -- 02
--           ,sum_data_rec.subinventory_code              -- 03
--           ,sum_data_rec.subinventory_type              -- 04
--           ,sum_data_rec.practice_date                  -- 05
--           ,sum_data_rec.inventory_item_id              -- 06
--           ,sum_data_rec.operation_cost                 -- 07
--           ,sum_data_rec.standard_cost                  -- 08
--           ,sum_data_rec.sales_shipped                  -- 09
--           ,sum_data_rec.sales_shipped_b                -- 10
--           ,sum_data_rec.return_goods                   -- 11
--           ,sum_data_rec.return_goods_b                 -- 12
--           ,sum_data_rec.warehouse_ship                 -- 13
--           ,sum_data_rec.truck_ship                     -- 14
--           ,sum_data_rec.others_ship                    -- 15
--           ,sum_data_rec.warehouse_stock                -- 16
--           ,sum_data_rec.truck_stock                    -- 17
--           ,sum_data_rec.others_stock                   -- 18
--           ,sum_data_rec.change_stock                   -- 19
--           ,sum_data_rec.change_ship                    -- 20
--           ,sum_data_rec.goods_transfer_old             -- 21
--           ,sum_data_rec.goods_transfer_new             -- 22
--           ,sum_data_rec.sample_quantity                -- 23
--           ,sum_data_rec.sample_quantity_b              -- 24
--           ,sum_data_rec.customer_sample_ship           -- 25
--           ,sum_data_rec.customer_sample_ship_b         -- 26
--           ,sum_data_rec.customer_support_ss            -- 27
--           ,sum_data_rec.customer_support_ss_b          -- 28
--           ,sum_data_rec.ccm_sample_ship                -- 29
--           ,sum_data_rec.ccm_sample_ship_b              -- 30
--           ,sum_data_rec.vd_supplement_stock            -- 31
--           ,sum_data_rec.vd_supplement_ship             -- 32
--           ,sum_data_rec.inventory_change_in            -- 33
--           ,sum_data_rec.inventory_change_out           -- 34
--           ,sum_data_rec.factory_return                 -- 35
--           ,sum_data_rec.factory_return_b               -- 36
--           ,sum_data_rec.factory_change                 -- 37
--           ,sum_data_rec.factory_change_b               -- 38
--           ,sum_data_rec.removed_goods                  -- 39
--           ,sum_data_rec.removed_goods_b                -- 40
--           ,sum_data_rec.factory_stock                  -- 41
--           ,sum_data_rec.factory_stock_b                -- 42
--           ,sum_data_rec.wear_decrease                  -- 43
--           ,sum_data_rec.wear_increase                  -- 44
--           ,sum_data_rec.selfbase_ship                  -- 45
--           ,sum_data_rec.selfbase_stock                 -- 46
--           ,sum_data_rec.book_inventory_quantity        -- 47
--           ,cn_created_by                               -- 48
--           ,SYSDATE                                     -- 49
--           ,cn_last_updated_by                          -- 50
--           ,SYSDATE                                     -- 51
--           ,cn_last_update_login                        -- 52
--           ,cn_request_id                               -- 53
--           ,cn_program_application_id                   -- 54
--           ,cn_program_id                               -- 55
--           ,SYSDATE                                     -- 56
--          );
--          --
--      END;
--      --
--    END LOOP set_sum_data_loop;
----
--  EXCEPTION
----#################################  固定例外処理部 START   ####################################
----
--    -- *** 処理部共通例外ハンドラ ***
--    WHEN global_process_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** 共通関数例外ハンドラ ***
--    WHEN global_api_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
----
----#####################################  固定部 END   ##########################################
----
--  END set_reception_sum;
---- == 2009/04/06 V1.1 Added END   ===============================================================
--
  /**********************************************************************************
   * Procedure Name   : set_reception_sum
   * Description      : 累計受払データ出力(A-8)
   ***********************************************************************************/
  PROCEDURE set_reception_sum(
    it_base_code                IN xxcoi_inv_reception_daily.base_code%TYPE,                  -- 01.拠点コード
    it_subinventory_code        IN xxcoi_inv_reception_daily.subinventory_code%TYPE,          -- 03.保管場所
    it_practice_date            IN xxcoi_inv_reception_daily.practice_date%TYPE,              -- 04.年月日
    it_inventory_item_id        IN xxcoi_inv_reception_daily.inventory_item_id%TYPE,          -- 05.品目ID
    it_subinventory_type        IN xxcoi_inv_reception_daily.subinventory_type%TYPE,          -- 06.保管場所区分
    it_operation_cost           IN xxcoi_inv_reception_daily.operation_cost%TYPE,             -- 07.営業原価
    it_standard_cost            IN xxcoi_inv_reception_daily.standard_cost%TYPE,              -- 08.標準原価
    it_sales_shipped            IN xxcoi_inv_reception_daily.sales_shipped%TYPE,              -- 10.売上出庫
    it_sales_shipped_b          IN xxcoi_inv_reception_daily.sales_shipped_b%TYPE,            -- 11.売上出庫振戻
    it_return_goods             IN xxcoi_inv_reception_daily.return_goods%TYPE,               -- 12.返品
    it_return_goods_b           IN xxcoi_inv_reception_daily.return_goods_b%TYPE,             -- 13.返品振戻
    it_warehouse_ship           IN xxcoi_inv_reception_daily.warehouse_ship%TYPE,             -- 14.倉庫へ返庫
    it_truck_ship               IN xxcoi_inv_reception_daily.truck_ship%TYPE,                 -- 15.営業車へ出庫
    it_others_ship              IN xxcoi_inv_reception_daily.others_ship%TYPE,                -- 16.入出庫＿その他出庫
    it_warehouse_stock          IN xxcoi_inv_reception_daily.warehouse_stock%TYPE,            -- 17.倉庫より入庫
    it_truck_stock              IN xxcoi_inv_reception_daily.truck_stock%TYPE,                -- 18.営業車より入庫
    it_others_stock             IN xxcoi_inv_reception_daily.others_stock%TYPE,               -- 19.入出庫＿その他入庫
    it_change_stock             IN xxcoi_inv_reception_daily.change_stock%TYPE,               -- 20.倉替入庫
    it_change_ship              IN xxcoi_inv_reception_daily.change_ship%TYPE,                -- 21.倉替出庫
    it_goods_transfer_old       IN xxcoi_inv_reception_daily.goods_transfer_old%TYPE,         -- 22.商品振替（旧商品）
    it_goods_transfer_new       IN xxcoi_inv_reception_daily.goods_transfer_new%TYPE,         -- 23.商品振替（新商品）
    it_sample_quantity          IN xxcoi_inv_reception_daily.sample_quantity%TYPE,            -- 24.見本出庫
    it_sample_quantity_b        IN xxcoi_inv_reception_daily.sample_quantity_b%TYPE,          -- 25.見本出庫振戻
    it_customer_sample_ship     IN xxcoi_inv_reception_daily.customer_sample_ship%TYPE,       -- 26.顧客見本出庫
    it_customer_sample_ship_b   IN xxcoi_inv_reception_daily.customer_sample_ship_b%TYPE,     -- 27.顧客見本出庫振戻
    it_customer_support_ss      IN xxcoi_inv_reception_daily.customer_support_ss%TYPE,        -- 28.顧客協賛見本出庫
    it_customer_support_ss_b    IN xxcoi_inv_reception_daily.customer_support_ss_b%TYPE,      -- 29.顧客協賛見本出庫振戻
    it_vd_supplement_stock      IN xxcoi_inv_reception_daily.vd_supplement_stock%TYPE,        -- 32.消化VD補充入庫
    it_vd_supplement_ship       IN xxcoi_inv_reception_daily.vd_supplement_ship%TYPE,         -- 33.消化VD補充出庫
    it_inventory_change_in      IN xxcoi_inv_reception_daily.inventory_change_in%TYPE,        -- 34.基準在庫変更入庫
    it_inventory_change_out     IN xxcoi_inv_reception_daily.inventory_change_out%TYPE,       -- 35.基準在庫変更出庫
    it_factory_return           IN xxcoi_inv_reception_daily.factory_return%TYPE,             -- 36.工場返品
    it_factory_return_b         IN xxcoi_inv_reception_daily.factory_return_b%TYPE,           -- 37.工場返品振戻
    it_factory_change           IN xxcoi_inv_reception_daily.factory_change%TYPE,             -- 38.工場倉替
    it_factory_change_b         IN xxcoi_inv_reception_daily.factory_change_b%TYPE,           -- 39.工場倉替振戻
    it_removed_goods            IN xxcoi_inv_reception_daily.removed_goods%TYPE,              -- 40.廃却
    it_removed_goods_b          IN xxcoi_inv_reception_daily.removed_goods_b%TYPE,            -- 41.廃却振戻
    it_factory_stock            IN xxcoi_inv_reception_daily.factory_stock%TYPE,              -- 42.工場入庫
    it_factory_stock_b          IN xxcoi_inv_reception_daily.factory_stock_b%TYPE,            -- 43.工場入庫振戻
    it_ccm_sample_ship          IN xxcoi_inv_reception_daily.ccm_sample_ship%TYPE,            -- 30.顧客広告宣伝費A自社商品
    it_ccm_sample_ship_b        IN xxcoi_inv_reception_daily.ccm_sample_ship_b%TYPE,          -- 31.顧客広告宣伝費A自社商品振戻
    it_wear_decrease            IN xxcoi_inv_reception_daily.wear_decrease%TYPE,              -- 44.棚卸減耗増
    it_wear_increase            IN xxcoi_inv_reception_daily.wear_increase%TYPE,              -- 45.棚卸減耗減
    it_selfbase_ship            IN xxcoi_inv_reception_daily.selfbase_ship%TYPE,              -- 46.保管場所移動＿自拠点出庫
    it_selfbase_stock           IN xxcoi_inv_reception_daily.selfbase_stock%TYPE,             -- 47.保管場所移動＿自拠点入庫
    it_book_inventory_quantity  IN xxcoi_inv_reception_daily.book_inventory_quantity%TYPE,    -- 48.帳簿在庫数
    ib_chk_result               IN BOOLEAN,                                                   -- 49.在庫会計期間OPEN判定
    ov_errbuf                   OUT VARCHAR2,                     -- エラー・メッセージ                  --# 固定 #
    ov_retcode                  OUT VARCHAR2,                     -- リターン・コード                    --# 固定 #
    ov_errmsg                   OUT VARCHAR2)                     -- ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_reception_sum'; -- プログラム名
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
    -- *** ローカル変数 ***
    ln_dummy                    NUMBER;         -- ダミー変数
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
    -- ***************************************
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
    IF ((it_practice_date = gd_f_business_date)
        OR
        (    (it_practice_date = gd_f_max_practice_date)
         AND (ib_chk_result) 
        )
       )
    THEN
      BEGIN
        -- 当月データ、または、前月データで前月の在庫会計期間がOPENしている場合以下を実行
        -- ===================================
        --  1.累計テーブルロック取得
        -- ===================================
        SELECT  1
        INTO    ln_dummy
        FROM    xxcoi_inv_reception_sum   xirs
        WHERE   xirs.base_code            =   it_base_code
---- == 2009/08/26 V1.8 Added START ===============================================================
        AND     xirs.organization_id      =   gn_f_organization_id
---- == 2009/08/26 V1.8 Added END   ===============================================================
        AND     xirs.subinventory_code    =   it_subinventory_code
        AND     xirs.inventory_item_id    =   it_inventory_item_id
        AND     xirs.practice_date        =   SUBSTRB(TO_CHAR(it_practice_date, cv_date), 1, 6)
        AND     ROWNUM                    =   1
        FOR UPDATE NOWAIT;
        --
        -- ===================================
        --  2.累計テーブル更新
        -- ===================================
        -- ロックが取得された場合、入出庫数を更新する
        UPDATE  xxcoi_inv_reception_sum
        SET     sales_shipped             = sales_shipped           + it_sales_shipped            -- 01.売上出庫
               ,sales_shipped_b           = sales_shipped_b         + it_sales_shipped_b          -- 02.売上出庫振戻
               ,return_goods              = return_goods            + it_return_goods             -- 03.返品
               ,return_goods_b            = return_goods_b          + it_return_goods_b           -- 04.返品振戻
               ,warehouse_ship            = warehouse_ship          + it_warehouse_ship           -- 05.倉庫へ返庫
               ,truck_ship                = truck_ship              + it_truck_ship               -- 06.営業車へ出庫
               ,others_ship               = others_ship             + it_others_ship              -- 07.入出庫＿その他出庫
               ,warehouse_stock           = warehouse_stock         + it_warehouse_stock          -- 08.倉庫より入庫
               ,truck_stock               = truck_stock             + it_truck_stock              -- 09.営業車より入庫
               ,others_stock              = others_stock            + it_others_stock             -- 10.入出庫＿その他入庫
               ,change_stock              = change_stock            + it_change_stock             -- 11.倉替入庫
               ,change_ship               = change_ship             + it_change_ship              -- 12.倉替出庫
               ,goods_transfer_old        = goods_transfer_old      + it_goods_transfer_old       -- 13.商品振替（旧商品）
               ,goods_transfer_new        = goods_transfer_new      + it_goods_transfer_new       -- 14.商品振替（新商品）
               ,sample_quantity           = sample_quantity         + it_sample_quantity          -- 15.見本出庫
               ,sample_quantity_b         = sample_quantity_b       + it_sample_quantity_b        -- 16.見本出庫振戻
               ,customer_sample_ship      = customer_sample_ship    + it_customer_sample_ship     -- 17.顧客見本出庫
               ,customer_sample_ship_b    = customer_sample_ship_b  + it_customer_sample_ship_b   -- 18.顧客見本出庫振戻
               ,customer_support_ss       = customer_support_ss     + it_customer_support_ss      -- 19.顧客協賛見本出庫
               ,customer_support_ss_b     = customer_support_ss_b   + it_customer_support_ss_b    -- 20.顧客協賛見本出庫振戻
               ,ccm_sample_ship           = ccm_sample_ship         + it_ccm_sample_ship          -- 21.顧客広告宣伝費A自社商品
               ,ccm_sample_ship_b         = ccm_sample_ship_b       + it_ccm_sample_ship_b        -- 22.顧客広告宣伝費A自社商品振戻
               ,vd_supplement_stock       = vd_supplement_stock     + it_vd_supplement_stock      -- 23.消化VD補充入庫
               ,vd_supplement_ship        = vd_supplement_ship      + it_vd_supplement_ship       -- 24.消化VD補充出庫
               ,inventory_change_in       = inventory_change_in     + it_inventory_change_in      -- 25.基準在庫変更入庫
               ,inventory_change_out      = inventory_change_out    + it_inventory_change_out     -- 26.基準在庫変更出庫
               ,factory_return            = factory_return          + it_factory_return           -- 27.工場返品
               ,factory_return_b          = factory_return_b        + it_factory_return_b         -- 28.工場返品振戻
               ,factory_change            = factory_change          + it_factory_change           -- 29.工場倉替
               ,factory_change_b          = factory_change_b        + it_factory_change_b         -- 30.工場倉替振戻
               ,removed_goods             = removed_goods           + it_removed_goods            -- 31.廃却
               ,removed_goods_b           = removed_goods_b         + it_removed_goods_b          -- 32.廃却振戻
               ,factory_stock             = factory_stock           + it_factory_stock            -- 33.工場入庫
               ,factory_stock_b           = factory_stock_b         + it_factory_stock_b          -- 34.工場入庫振戻
               ,wear_decrease             = wear_decrease           + it_wear_decrease            -- 35.棚卸減耗増
               ,wear_increase             = wear_increase           + it_wear_increase            -- 36.棚卸減耗減
               ,selfbase_ship             = selfbase_ship           + it_selfbase_ship            -- 37.保管場所移動＿自拠点出庫
               ,selfbase_stock            = selfbase_stock          + it_selfbase_stock           -- 38.保管場所移動＿自拠点入庫
               ,book_inventory_quantity   = book_inventory_quantity + it_book_inventory_quantity  -- 39.帳簿在庫数
               ,last_updated_by           = cn_last_updated_by                                    -- 40.最終更新者
               ,last_update_date          = SYSDATE                                               -- 41.最終更新日
               ,last_update_login         = cn_last_update_login                                  -- 42.最終更新ログイン
               ,request_id                = cn_request_id                                         -- 43.要求ID
               ,program_application_id    = cn_program_application_id                             -- 44.コンカレント・プログラム・アプリケーションID
               ,program_id                = cn_program_id                                         -- 45.コンカレント・プログラムID
               ,program_update_date       = SYSDATE                                               -- 46.プログラム更新日
        WHERE   base_code                 = it_base_code
---- == 2009/08/26 V1.8 Added START ===============================================================
        AND     organization_id           = gn_f_organization_id
---- == 2009/08/26 V1.8 Added END   ===============================================================
        AND     subinventory_code         = it_subinventory_code
        AND     inventory_item_id         = it_inventory_item_id
        AND     practice_date             = SUBSTRB(TO_CHAR(it_practice_date, cv_date), 1, 6);
        --
---- == 2009/08/26 V1.8 Added START ===============================================================
        gn_target_cnt := gn_target_cnt + 1;
---- == 2009/08/26 V1.8 Added END   ===============================================================
      EXCEPTION
        WHEN  lock_error_expt THEN
          -- ロックが取得されなかった場合
          -- 月次在庫受払（累計）ロックエラーメッセージ
          lv_errmsg   := xxccp_common_pkg.get_msg(
                           iv_application  => cv_short_name
                          ,iv_name         => cv_msg_xxcoi1_10378
                         );
          lv_errbuf   := lv_errmsg;
          RAISE global_process_expt;
          --
        WHEN NO_DATA_FOUND THEN
          -- ===================================
          --  3.累計テーブル作成
          -- ===================================
          -- 対象データが存在しない場合、累計情報を新規作成する
          INSERT INTO xxcoi_inv_reception_sum(
            base_code                                   -- 01.拠点コード
           ,organization_id                             -- 02.組織ID
           ,subinventory_code                           -- 03.保管場所
           ,subinventory_type                           -- 04.保管場所区分
           ,practice_date                               -- 05.年月
           ,inventory_item_id                           -- 06.品目ID
           ,operation_cost                              -- 07.営業原価
           ,standard_cost                               -- 08.標準原価
           ,sales_shipped                               -- 09.売上出庫
           ,sales_shipped_b                             -- 10.売上出庫振戻
           ,return_goods                                -- 11.返品
           ,return_goods_b                              -- 12.返品振戻
           ,warehouse_ship                              -- 13.倉庫へ返庫
           ,truck_ship                                  -- 14.営業車へ出庫
           ,others_ship                                 -- 15.入出庫＿その他出庫
           ,warehouse_stock                             -- 16.倉庫より入庫
           ,truck_stock                                 -- 17.営業車より入庫
           ,others_stock                                -- 18.入出庫＿その他入庫
           ,change_stock                                -- 19.倉替入庫
           ,change_ship                                 -- 20.倉替出庫
           ,goods_transfer_old                          -- 21.商品振替（旧商品）
           ,goods_transfer_new                          -- 22.商品振替（新商品）
           ,sample_quantity                             -- 23.見本出庫
           ,sample_quantity_b                           -- 24.見本出庫振戻
           ,customer_sample_ship                        -- 25.顧客見本出庫
           ,customer_sample_ship_b                      -- 26.顧客見本出庫振戻
           ,customer_support_ss                         -- 27.顧客協賛見本出庫
           ,customer_support_ss_b                       -- 28.顧客協賛見本出庫振戻
           ,ccm_sample_ship                             -- 29.顧客広告宣伝費A自社商品
           ,ccm_sample_ship_b                           -- 30.顧客広告宣伝費A自社商品振戻
           ,vd_supplement_stock                         -- 31.消化VD補充入庫
           ,vd_supplement_ship                          -- 32.消化VD補充出庫
           ,inventory_change_in                         -- 33.基準在庫変更入庫
           ,inventory_change_out                        -- 34.基準在庫変更出庫
           ,factory_return                              -- 35.工場返品
           ,factory_return_b                            -- 36.工場返品振戻
           ,factory_change                              -- 37.工場倉替
           ,factory_change_b                            -- 38.工場倉替振戻
           ,removed_goods                               -- 39.廃却
           ,removed_goods_b                             -- 40.廃却振戻
           ,factory_stock                               -- 41.工場入庫
           ,factory_stock_b                             -- 42.工場入庫振戻
           ,wear_decrease                               -- 43.棚卸減耗増
           ,wear_increase                               -- 44.棚卸減耗減
           ,selfbase_ship                               -- 45.保管場所移動＿自拠点出庫
           ,selfbase_stock                              -- 46.保管場所移動＿自拠点入庫
           ,book_inventory_quantity                     -- 47.帳簿在庫数
           ,created_by                                  -- 48.作成者
           ,creation_date                               -- 49.作成日
           ,last_updated_by                             -- 50.最終更新者
           ,last_update_date                            -- 51.最終更新日
           ,last_update_login                           -- 52.最終更新ログイン
           ,request_id                                  -- 53.要求ID
           ,program_application_id                      -- 54.コンカレント・プログラム・アプリケーションID
           ,program_id                                  -- 55.コンカレント・プログラムID
           ,program_update_date                         -- 56.プログラム更新日
          )VALUES(
            it_base_code                      -- 01
           ,gn_f_organization_id              -- 02
           ,it_subinventory_code              -- 03
           ,it_subinventory_type              -- 04
           ,SUBSTRB(TO_CHAR(it_practice_date, cv_date), 1, 6)
                                              -- 05
           ,it_inventory_item_id              -- 06
           ,it_operation_cost                 -- 07
           ,it_standard_cost                  -- 08
           ,it_sales_shipped                  -- 09
           ,it_sales_shipped_b                -- 10
           ,it_return_goods                   -- 11
           ,it_return_goods_b                 -- 12
           ,it_warehouse_ship                 -- 13
           ,it_truck_ship                     -- 14
           ,it_others_ship                    -- 15
           ,it_warehouse_stock                -- 16
           ,it_truck_stock                    -- 17
           ,it_others_stock                   -- 18
           ,it_change_stock                   -- 19
           ,it_change_ship                    -- 20
           ,it_goods_transfer_old             -- 21
           ,it_goods_transfer_new             -- 22
           ,it_sample_quantity                -- 23
           ,it_sample_quantity_b              -- 24
           ,it_customer_sample_ship           -- 25
           ,it_customer_sample_ship_b         -- 26
           ,it_customer_support_ss            -- 27
           ,it_customer_support_ss_b          -- 28
           ,it_ccm_sample_ship                -- 29
           ,it_ccm_sample_ship_b              -- 30
           ,it_vd_supplement_stock            -- 31
           ,it_vd_supplement_ship             -- 32
           ,it_inventory_change_in            -- 33
           ,it_inventory_change_out           -- 34
           ,it_factory_return                 -- 35
           ,it_factory_return_b               -- 36
           ,it_factory_change                 -- 37
           ,it_factory_change_b               -- 38
           ,it_removed_goods                  -- 39
           ,it_removed_goods_b                -- 40
           ,it_factory_stock                  -- 41
           ,it_factory_stock_b                -- 42
           ,it_wear_decrease                  -- 43
           ,it_wear_increase                  -- 44
           ,it_selfbase_ship                  -- 45
           ,it_selfbase_stock                 -- 46
           ,it_book_inventory_quantity        -- 47
           ,cn_created_by                     -- 48
           ,SYSDATE                           -- 49
           ,cn_last_updated_by                -- 50
           ,SYSDATE                           -- 51
           ,cn_last_update_login              -- 52
           ,cn_request_id                     -- 53
           ,cn_program_application_id         -- 54
           ,cn_program_id                     -- 55
           ,SYSDATE                           -- 56
          );
          --
---- == 2009/08/26 V1.8 Added START ===============================================================
          gn_target_cnt := gn_target_cnt + 1;
---- == 2009/08/26 V1.8 Added END   ===============================================================
      END;
    END IF;
    --
    --
    IF (it_practice_date = gd_f_max_practice_date) THEN
      -- 前月データの場合以下を実行
      BEGIN
        -- ===================================
        --  4.累計テーブルロック取得
        -- ===================================
        SELECT  1
        INTO    ln_dummy
        FROM    xxcoi_inv_reception_sum   xirs
        WHERE   xirs.base_code            =   it_base_code
---- == 2009/08/26 V1.8 Added START ===============================================================
        AND     xirs.organization_id      =   gn_f_organization_id
---- == 2009/08/26 V1.8 Added END   ===============================================================
        AND     xirs.subinventory_code    =   it_subinventory_code
        AND     xirs.inventory_item_id    =   it_inventory_item_id
        AND     xirs.practice_date        =   SUBSTRB(TO_CHAR(gd_f_business_date, cv_date), 1, 6)
        AND     ROWNUM                    =   1
        FOR UPDATE NOWAIT;
        --
        -- =======================================
        --  5.累計テーブル更新(前月分を当月に反映)
        -- =======================================
        -- ロックが取得された場合、入出庫数を更新する
        UPDATE  xxcoi_inv_reception_sum
        SET     book_inventory_quantity   = book_inventory_quantity + it_book_inventory_quantity            -- 39.帳簿在庫数
               ,last_updated_by           = cn_last_updated_by                                              -- 40.最終更新者
               ,last_update_date          = SYSDATE                                                         -- 41.最終更新日
               ,last_update_login         = cn_last_update_login                                            -- 42.最終更新ログイン
               ,request_id                = cn_request_id                                                   -- 43.要求ID
               ,program_application_id    = cn_program_application_id                                       -- 44.コンカレント・プログラム・アプリケーションID
               ,program_id                = cn_program_id                                                   -- 45.コンカレント・プログラムID
               ,program_update_date       = SYSDATE                                                         -- 46.プログラム更新日
        WHERE   base_code                 = it_base_code
---- == 2009/08/26 V1.8 Added START ===============================================================
        AND     organization_id           = gn_f_organization_id
---- == 2009/08/26 V1.8 Added END   ===============================================================
        AND     subinventory_code         = it_subinventory_code
        AND     inventory_item_id         = it_inventory_item_id
        AND     practice_date             = SUBSTRB(TO_CHAR(gd_f_business_date, cv_date), 1, 6);
        --
      EXCEPTION
        WHEN  lock_error_expt THEN
          -- ロックが取得されなかった場合
          -- 月次在庫受払（累計）ロックエラーメッセージ
          lv_errmsg   := xxccp_common_pkg.get_msg(
                           iv_application  => cv_short_name
                          ,iv_name         => cv_msg_xxcoi1_10378
                         );
          lv_errbuf   := lv_errmsg;
          RAISE global_process_expt;
          --
        WHEN NO_DATA_FOUND THEN
          -- =======================================
          --  6.累計テーブル作成(前月分を当月に反映)
          -- =======================================
          -- 対象データが存在しない場合、累計情報を新規作成する
          INSERT INTO xxcoi_inv_reception_sum(
            base_code                                   -- 01.拠点コード
           ,organization_id                             -- 02.組織ID
           ,subinventory_code                           -- 03.保管場所
           ,subinventory_type                           -- 04.保管場所区分
           ,practice_date                               -- 05.年月
           ,inventory_item_id                           -- 06.品目ID
           ,operation_cost                              -- 07.営業原価
           ,standard_cost                               -- 08.標準原価
           ,sales_shipped                               -- 09.売上出庫
           ,sales_shipped_b                             -- 10.売上出庫振戻
           ,return_goods                                -- 11.返品
           ,return_goods_b                              -- 12.返品振戻
           ,warehouse_ship                              -- 13.倉庫へ返庫
           ,truck_ship                                  -- 14.営業車へ出庫
           ,others_ship                                 -- 15.入出庫＿その他出庫
           ,warehouse_stock                             -- 16.倉庫より入庫
           ,truck_stock                                 -- 17.営業車より入庫
           ,others_stock                                -- 18.入出庫＿その他入庫
           ,change_stock                                -- 19.倉替入庫
           ,change_ship                                 -- 20.倉替出庫
           ,goods_transfer_old                          -- 21.商品振替（旧商品）
           ,goods_transfer_new                          -- 22.商品振替（新商品）
           ,sample_quantity                             -- 23.見本出庫
           ,sample_quantity_b                           -- 24.見本出庫振戻
           ,customer_sample_ship                        -- 25.顧客見本出庫
           ,customer_sample_ship_b                      -- 26.顧客見本出庫振戻
           ,customer_support_ss                         -- 27.顧客協賛見本出庫
           ,customer_support_ss_b                       -- 28.顧客協賛見本出庫振戻
           ,ccm_sample_ship                             -- 29.顧客広告宣伝費A自社商品
           ,ccm_sample_ship_b                           -- 30.顧客広告宣伝費A自社商品振戻
           ,vd_supplement_stock                         -- 31.消化VD補充入庫
           ,vd_supplement_ship                          -- 32.消化VD補充出庫
           ,inventory_change_in                         -- 33.基準在庫変更入庫
           ,inventory_change_out                        -- 34.基準在庫変更出庫
           ,factory_return                              -- 35.工場返品
           ,factory_return_b                            -- 36.工場返品振戻
           ,factory_change                              -- 37.工場倉替
           ,factory_change_b                            -- 38.工場倉替振戻
           ,removed_goods                               -- 39.廃却
           ,removed_goods_b                             -- 40.廃却振戻
           ,factory_stock                               -- 41.工場入庫
           ,factory_stock_b                             -- 42.工場入庫振戻
           ,wear_decrease                               -- 43.棚卸減耗増
           ,wear_increase                               -- 44.棚卸減耗減
           ,selfbase_ship                               -- 45.保管場所移動＿自拠点出庫
           ,selfbase_stock                              -- 46.保管場所移動＿自拠点入庫
           ,book_inventory_quantity                     -- 47.帳簿在庫数
           ,created_by                                  -- 48.作成者
           ,creation_date                               -- 49.作成日
           ,last_updated_by                             -- 50.最終更新者
           ,last_update_date                            -- 51.最終更新日
           ,last_update_login                           -- 52.最終更新ログイン
           ,request_id                                  -- 53.要求ID
           ,program_application_id                      -- 54.コンカレント・プログラム・アプリケーションID
           ,program_id                                  -- 55.コンカレント・プログラムID
           ,program_update_date                         -- 56.プログラム更新日
          )VALUES(
            it_base_code                      -- 01
           ,gn_f_organization_id              -- 02
           ,it_subinventory_code              -- 03
           ,it_subinventory_type              -- 04
           ,SUBSTRB(TO_CHAR(gd_f_business_date, cv_date), 1, 6)
                                              -- 05
           ,it_inventory_item_id              -- 06
           ,it_operation_cost                 -- 07
           ,it_standard_cost                  -- 08
           ,0                                 -- 09
           ,0                                 -- 10
           ,0                                 -- 11
           ,0                                 -- 12
           ,0                                 -- 13
           ,0                                 -- 14
           ,0                                 -- 15
           ,0                                 -- 16
           ,0                                 -- 17
           ,0                                 -- 18
           ,0                                 -- 19
           ,0                                 -- 20
           ,0                                 -- 21
           ,0                                 -- 22
           ,0                                 -- 23
           ,0                                 -- 24
           ,0                                 -- 25
           ,0                                 -- 26
           ,0                                 -- 27
           ,0                                 -- 28
           ,0                                 -- 29
           ,0                                 -- 30
           ,0                                 -- 31
           ,0                                 -- 32
           ,0                                 -- 33
           ,0                                 -- 34
           ,0                                 -- 35
           ,0                                 -- 36
           ,0                                 -- 37
           ,0                                 -- 38
           ,0                                 -- 39
           ,0                                 -- 40
           ,0                                 -- 41
           ,0                                 -- 42
           ,0                                 -- 43
           ,0                                 -- 44
           ,0                                 -- 45
           ,0                                 -- 46
           ,it_book_inventory_quantity        -- 47
           ,cn_created_by                     -- 48
           ,SYSDATE                           -- 49
           ,cn_last_updated_by                -- 50
           ,SYSDATE                           -- 51
           ,cn_last_update_login              -- 52
           ,cn_request_id                     -- 53
           ,cn_program_application_id         -- 54
           ,cn_program_id                     -- 55
           ,SYSDATE                           -- 56
          );
          --
---- == 2009/08/26 V1.8 Added START ===============================================================
          gn_target_cnt := gn_target_cnt + 1;
---- == 2009/08/26 V1.8 Added END   ===============================================================
      END;
    END IF;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END set_reception_sum;
-- == 2009/05/28 V1.4 Modified END   ===============================================================
-- == 2009/05/28 V1.4 Added START ===============================================================
  /**********************************************************************************
   * Procedure Name   : set_last_daily_sum
   * Description      : 前月サマリ情報出力(A-7)
   ***********************************************************************************/
  PROCEDURE set_last_daily_sum(
    ov_errbuf         OUT VARCHAR2,                     -- エラー・メッセージ                  --# 固定 #
    ov_retcode        OUT VARCHAR2,                     -- リターン・コード                    --# 固定 #
    ov_errmsg         OUT VARCHAR2)                     -- ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_last_daily_sum'; -- プログラム名
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
    -- *** ローカル変数 ***
-- == 2009/08/31 V1.9 Added START ===============================================================
    lt_standard_cost      xxcoi_inv_reception_sum.standard_cost%TYPE;
    lt_operation_cost     xxcoi_inv_reception_sum.operation_cost%TYPE;
-- == 2009/08/31 V1.9 Added START ===============================================================
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
    CURSOR  daily_sum_cur
    IS
      SELECT  xirs.base_code
             ,xirs.organization_id
             ,xirs.subinventory_code
             ,xirs.inventory_item_id
             ,xirs.subinventory_type
             ,xirs.operation_cost
             ,xirs.standard_cost
             ,xirs.book_inventory_quantity
      FROM    xxcoi_inv_reception_sum   xirs
      WHERE   xirs.organization_id  = gn_f_organization_id
      AND     xirs.practice_date    = SUBSTRB(TO_CHAR(ADD_MONTHS(gd_f_business_date, -1), cv_date), 1, 6);
    --
    -- <カーソル名>レコード型
    daily_sum_rec     daily_sum_cur%ROWTYPE;
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
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
    -- ===================================
    --  1.前月サマリ情報コピー
    -- ===================================
    <<set_last_sum_loop>>
    FOR daily_sum_rec  IN  daily_sum_cur  LOOP
-- == 2009/08/31 V1.9 Added START ===============================================================
      -- ===================================
      --  2.標準原価取得
      -- ===================================
      xxcoi_common_pkg.get_cmpnt_cost(
        in_item_id      =>  daily_sum_rec.inventory_item_id                 -- 品目ID
       ,in_org_id       =>  gn_f_organization_id                            -- 組織ID
       ,id_period_date  =>  gd_f_business_date                              -- 対象日
       ,ov_cmpnt_cost   =>  lt_standard_cost                                -- 標準原価
       ,ov_errbuf       =>  lv_errbuf                                       -- エラーメッセージ
       ,ov_retcode      =>  lv_retcode                                      -- リターン・コード
       ,ov_errmsg       =>  lv_errmsg                                       -- ユーザー・エラーメッセージ
      );
      -- 終了パラメータ判定
      IF (lv_retcode = cv_status_error) THEN
        lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_short_name
                        ,iv_name         => cv_msg_xxcoi1_10285
                       );
        lv_errbuf   := lv_errmsg;
        RAISE global_api_expt;
      END IF;
      --
      -- ===================================
      --  2.営業原価取得
      -- ===================================
      xxcoi_common_pkg.get_discrete_cost(
        in_item_id        =>  daily_sum_rec.inventory_item_id                 -- 品目ID
       ,in_org_id         =>  gn_f_organization_id                            -- 組織ID
       ,id_target_date    =>  gd_f_business_date                              -- 対象日
       ,ov_discrete_cost  =>  lt_operation_cost                               -- 営業原価
       ,ov_errbuf         =>  lv_errbuf                                       -- エラーメッセージ
       ,ov_retcode        =>  lv_retcode                                      -- リターン・コード
       ,ov_errmsg         =>  lv_errmsg                                       -- ユーザー・エラーメッセージ
      );
      -- 終了パラメータ判定
      IF (lv_retcode = cv_status_error) THEN
        lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_short_name
                        ,iv_name         => cv_msg_xxcoi1_10293
                       );
        lv_errbuf   := lv_errmsg;
        RAISE global_api_expt;
      END IF;
-- == 2009/08/31 V1.9 Added END   ===============================================================
--
      INSERT INTO xxcoi_inv_reception_sum(
        base_code                                   -- 01.拠点コード
       ,organization_id                             -- 02.組織ID
       ,subinventory_code                           -- 03.保管場所
       ,subinventory_type                           -- 04.保管場所区分
       ,practice_date                               -- 05.年月
       ,inventory_item_id                           -- 06.品目ID
       ,operation_cost                              -- 07.営業原価
       ,standard_cost                               -- 08.標準原価
       ,sales_shipped                               -- 09.売上出庫
       ,sales_shipped_b                             -- 10.売上出庫振戻
       ,return_goods                                -- 11.返品
       ,return_goods_b                              -- 12.返品振戻
       ,warehouse_ship                              -- 13.倉庫へ返庫
       ,truck_ship                                  -- 14.営業車へ出庫
       ,others_ship                                 -- 15.入出庫＿その他出庫
       ,warehouse_stock                             -- 16.倉庫より入庫
       ,truck_stock                                 -- 17.営業車より入庫
       ,others_stock                                -- 18.入出庫＿その他入庫
       ,change_stock                                -- 19.倉替入庫
       ,change_ship                                 -- 20.倉替出庫
       ,goods_transfer_old                          -- 21.商品振替（旧商品）
       ,goods_transfer_new                          -- 22.商品振替（新商品）
       ,sample_quantity                             -- 23.見本出庫
       ,sample_quantity_b                           -- 24.見本出庫振戻
       ,customer_sample_ship                        -- 25.顧客見本出庫
       ,customer_sample_ship_b                      -- 26.顧客見本出庫振戻
       ,customer_support_ss                         -- 27.顧客協賛見本出庫
       ,customer_support_ss_b                       -- 28.顧客協賛見本出庫振戻
       ,ccm_sample_ship                             -- 29.顧客広告宣伝費A自社商品
       ,ccm_sample_ship_b                           -- 30.顧客広告宣伝費A自社商品振戻
       ,vd_supplement_stock                         -- 31.消化VD補充入庫
       ,vd_supplement_ship                          -- 32.消化VD補充出庫
       ,inventory_change_in                         -- 33.基準在庫変更入庫
       ,inventory_change_out                        -- 34.基準在庫変更出庫
       ,factory_return                              -- 35.工場返品
       ,factory_return_b                            -- 36.工場返品振戻
       ,factory_change                              -- 37.工場倉替
       ,factory_change_b                            -- 38.工場倉替振戻
       ,removed_goods                               -- 39.廃却
       ,removed_goods_b                             -- 40.廃却振戻
       ,factory_stock                               -- 41.工場入庫
       ,factory_stock_b                             -- 42.工場入庫振戻
       ,wear_decrease                               -- 43.棚卸減耗増
       ,wear_increase                               -- 44.棚卸減耗減
       ,selfbase_ship                               -- 45.保管場所移動＿自拠点出庫
       ,selfbase_stock                              -- 46.保管場所移動＿自拠点入庫
       ,book_inventory_quantity                     -- 47.帳簿在庫数
       ,created_by                                  -- 48.作成者
       ,creation_date                               -- 49.作成日
       ,last_updated_by                             -- 50.最終更新者
       ,last_update_date                            -- 51.最終更新日
       ,last_update_login                           -- 52.最終更新ログイン
       ,request_id                                  -- 53.要求ID
       ,program_application_id                      -- 54.コンカレント・プログラム・アプリケーションID
       ,program_id                                  -- 55.コンカレント・プログラムID
       ,program_update_date                         -- 56.プログラム更新日
      )VALUES(
        daily_sum_rec.base_code                                 -- 01
       ,daily_sum_rec.organization_id                           -- 02
       ,daily_sum_rec.subinventory_code                         -- 03
       ,daily_sum_rec.subinventory_type                         -- 04
       ,SUBSTRB(TO_CHAR(gd_f_business_date, cv_date), 1, 6)     -- 05
       ,daily_sum_rec.inventory_item_id                         -- 06
-- == 2009/08/31 V1.9 Modified START ===============================================================
--       ,daily_sum_rec.operation_cost
--       ,daily_sum_rec.standard_cost
       ,lt_operation_cost                                       -- 07
       ,lt_standard_cost                                        -- 08
-- == 2009/08/31 V1.9 Modified END   ===============================================================
       ,0                                                       -- 09
       ,0                                                       -- 10
       ,0                                                       -- 11
       ,0                                                       -- 12
       ,0                                                       -- 13
       ,0                                                       -- 14
       ,0                                                       -- 15
       ,0                                                       -- 16
       ,0                                                       -- 17
       ,0                                                       -- 18
       ,0                                                       -- 19
       ,0                                                       -- 20
       ,0                                                       -- 21
       ,0                                                       -- 22
       ,0                                                       -- 23
       ,0                                                       -- 24
       ,0                                                       -- 25
       ,0                                                       -- 26
       ,0                                                       -- 27
       ,0                                                       -- 28
       ,0                                                       -- 29
       ,0                                                       -- 30
       ,0                                                       -- 31
       ,0                                                       -- 32
       ,0                                                       -- 33
       ,0                                                       -- 34
       ,0                                                       -- 35
       ,0                                                       -- 36
       ,0                                                       -- 37
       ,0                                                       -- 38
       ,0                                                       -- 39
       ,0                                                       -- 40
       ,0                                                       -- 41
       ,0                                                       -- 42
       ,0                                                       -- 43
       ,0                                                       -- 44
       ,0                                                       -- 45
       ,0                                                       -- 46
       ,daily_sum_rec.book_inventory_quantity                   -- 47
       ,cn_created_by                                           -- 48
       ,SYSDATE                                                 -- 49
       ,cn_last_updated_by                                      -- 50
       ,SYSDATE                                                 -- 51
       ,cn_last_update_login                                    -- 52
       ,cn_request_id                                           -- 53
       ,cn_program_application_id                               -- 54
       ,cn_program_id                                           -- 55
       ,SYSDATE                                                 -- 56
      );
---- == 2009/08/26 V1.8 Added START ===============================================================
      gn_target_cnt := gn_target_cnt + 1;
---- == 2009/08/26 V1.8 Added END   ===============================================================
    END LOOP set_last_sum_loop;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END set_last_daily_sum;
-- == 2009/05/28 V1.4 Added END   ===============================================================
--
--
  /**********************************************************************************
   * Procedure Name   : upd_last_transaction_id
   * Description      : 最終取引ID更新(A-6)
   ***********************************************************************************/
  PROCEDURE upd_last_transaction_id(
    ov_errbuf         OUT VARCHAR2,                     -- エラー・メッセージ                  --# 固定 #
    ov_retcode        OUT VARCHAR2,                     -- リターン・コード                    --# 固定 #
    ov_errmsg         OUT VARCHAR2)                     -- ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_last_transaction_id'; -- プログラム名
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
    -- *** ローカル変数 ***
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
    -- <カーソル名>レコード型
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
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
    IF (gn_f_last_transaction_id = 0) THEN
      INSERT INTO xxcoi_cooperation_control(
        control_id                      -- 01.制御ID
       ,last_cooperation_date           -- 02.最終連携日時
       ,transaction_id                  -- 03.取引ID
       ,program_short_name              -- 04.プログラム略称
       ,last_update_date                -- 05.最終更新日
       ,last_updated_by                 -- 06.最終更新者
       ,creation_date                   -- 07.作成日
       ,created_by                      -- 08.作成者
       ,last_update_login               -- 09.最終更新ユーザ
       ,request_id                      -- 10.要求ID
       ,program_application_id          -- 11.プログラムアプリケーションID
       ,program_id                      -- 12.プログラムID
       ,program_update_date             -- 13.プログラム更新日
      )VALUES(
-- == 2009/08/26 V1.8 Modified START ===============================================================
--        cn_control_id                   -- 01
        DECODE(gv_exec_flag, cv_0, cn_control_id
                                 , cn_control_id2)
                                        -- 01
-- == 2009/08/26 V1.8 Modified END   ===============================================================
       ,gd_f_business_date              -- 02
       ,gn_f_max_transaction_id         -- 03
-- == 2009/08/26 V1.8 Modified START ===============================================================
--       ,cv_pgsname_a09c                 -- 04
       ,DECODE(gv_exec_flag, cv_0, cv_pgsname_a09c
                                 , cv_pgsname_b09c)
                                        -- 04
-- == 2009/08/26 V1.8 Modified END   ===============================================================
       ,SYSDATE                         -- 05
       ,cn_last_updated_by              -- 06
       ,SYSDATE                         -- 07
       ,cn_created_by                   -- 08
       ,cn_last_update_login            -- 09
       ,cn_request_id                   -- 10
       ,cn_program_application_id       -- 11
       ,cn_program_id                   -- 12
       ,SYSDATE                         -- 13
      );
      --
    ELSE
      UPDATE  xxcoi_cooperation_control
      SET     last_cooperation_date       =   gd_f_business_date            -- 最終連携日時
             ,transaction_id              =   gn_f_max_transaction_id       -- 取引ID
             ,last_update_date            =   SYSDATE                       -- 最終更新日
             ,last_updated_by             =   cn_last_updated_by            -- 最終更新者
             ,last_update_login           =   cn_last_update_login          -- 最終更新ユーザ
             ,request_id                  =   cn_request_id                 -- 要求ID
             ,program_application_id      =   cn_program_application_id     -- プログラムアプリケーションID
             ,program_id                  =   cn_program_id                 -- プログラムID
             ,program_update_date         =   SYSDATE                       -- プログラム更新日
-- == 2009/08/26 V1.8 Modified START ===============================================================
--      WHERE   control_id            =   cn_control_id
--      AND     program_short_name    =   cv_pgsname_a09c;
      WHERE   control_id            =   DECODE(gv_exec_flag, cv_0, cn_control_id
                                                                 , cn_control_id2)
      AND     program_short_name    =   DECODE(gv_exec_flag, cv_0, cv_pgsname_a09c
                                                                 , cv_pgsname_b09c);
-- == 2009/08/26 V1.8 Modified END   ===============================================================
      --
    END IF;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END upd_last_transaction_id;
--
  /**********************************************************************************
   * Procedure Name   : set_mtl_transaction_data
   * Description      : 当日データ月次在庫受払（日次）出力(A-2, A-3)
   ***********************************************************************************/
  PROCEDURE set_mtl_transaction_data(
    ov_errbuf         OUT VARCHAR2,                     -- エラー・メッセージ                  --# 固定 #
    ov_retcode        OUT VARCHAR2,                     -- リターン・コード                    --# 固定 #
    ov_errmsg         OUT VARCHAR2)                     -- ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_mtl_transaction_data'; -- プログラム名
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
    -- *** ローカル変数 ***
    lb_chk_result                   BOOLEAN;        -- 在庫会計期間OPENフラグ（OPEN:TRUE, CLOSE:FALSE）
    ln_dummy                        NUMBER;         -- ダミー変数
    ln_material_flag                NUMBER  := 0;   -- 資材取引データ取得フラグ
    ln_today_data                   NUMBER  := 0;   -- 資材取引当日分データ件数
    --
    lt_base_code                    xxcoi_inv_reception_daily.base_code%TYPE;               -- 拠点コード
    lt_subinventory_code            xxcoi_inv_reception_daily.subinventory_code%TYPE;       -- 保管場所コード
    lt_inventory_item_id            xxcoi_inv_reception_daily.inventory_item_id%TYPE;       -- 品目ID
    lv_transaction_month            VARCHAR2(6);                                            -- 取引年月
    lt_transaction_date             mtl_material_transactions.transaction_date%TYPE;        -- 取引日
    lt_last_book_inv_quantity       xxcoi_inv_reception_daily.book_inventory_quantity%TYPE; -- 帳簿在庫（当日）
    lt_today_book_inv_quantity      xxcoi_inv_reception_daily.book_inventory_quantity%TYPE; -- 帳簿在庫（前月）
    lt_subinventory_type            xxcoi_inv_reception_daily.subinventory_type%TYPE;       -- 保管場所区分
    lt_standard_cost                xxcoi_inv_reception_daily.standard_cost%TYPE;           -- 標準原価
    lt_operation_cost               xxcoi_inv_reception_daily.operation_cost%TYPE;          -- 営業原価
    lt_sales_shipped                xxcoi_inv_reception_daily.sales_shipped%TYPE;           -- 売上出庫
    lt_sales_shipped_b              xxcoi_inv_reception_daily.sales_shipped_b%TYPE;         -- 売上出庫振戻
    lt_return_goods                 xxcoi_inv_reception_daily.return_goods%TYPE;            -- 返品
    lt_return_goods_b               xxcoi_inv_reception_daily.return_goods_b%TYPE;          -- 返品振戻
    lt_warehouse_ship               xxcoi_inv_reception_daily.warehouse_ship%TYPE;          -- 倉庫へ返庫
    lt_truck_ship                   xxcoi_inv_reception_daily.truck_ship%TYPE;              -- 営業車へ出庫
    lt_others_ship                  xxcoi_inv_reception_daily.others_ship%TYPE;             -- 入出庫＿その他出庫
    lt_warehouse_stock              xxcoi_inv_reception_daily.warehouse_stock%TYPE;         -- 倉庫より入庫
    lt_truck_stock                  xxcoi_inv_reception_daily.truck_stock%TYPE;             -- 営業車より入庫
    lt_others_stock                 xxcoi_inv_reception_daily.others_stock%TYPE;            -- 入出庫＿その他入庫
    lt_change_stock                 xxcoi_inv_reception_daily.change_stock%TYPE;            -- 倉替入庫
    lt_change_ship                  xxcoi_inv_reception_daily.change_ship%TYPE;             -- 倉替出庫
    lt_goods_transfer_old           xxcoi_inv_reception_daily.goods_transfer_old%TYPE;      -- 商品振替（旧商品）
    lt_goods_transfer_new           xxcoi_inv_reception_daily.goods_transfer_new%TYPE;      -- 商品振替（新商品）
    lt_sample_quantity              xxcoi_inv_reception_daily.sample_quantity%TYPE;         -- 見本出庫
    lt_sample_quantity_b            xxcoi_inv_reception_daily.sample_quantity_b%TYPE;       -- 見本出庫振戻
    lt_customer_sample_ship         xxcoi_inv_reception_daily.customer_sample_ship%TYPE;    -- 顧客見本出庫
    lt_customer_sample_ship_b       xxcoi_inv_reception_daily.customer_sample_ship_b%TYPE;  -- 顧客見本出庫振戻
    lt_customer_support_ss          xxcoi_inv_reception_daily.customer_support_ss%TYPE;     -- 顧客協賛見本出庫
    lt_customer_support_ss_b        xxcoi_inv_reception_daily.customer_support_ss_b%TYPE;   -- 顧客協賛見本出庫振戻
    lt_vd_supplement_stock          xxcoi_inv_reception_daily.vd_supplement_stock%TYPE;     -- 消化VD補充入庫
    lt_vd_supplement_ship           xxcoi_inv_reception_daily.vd_supplement_ship%TYPE;      -- 消化VD補充出庫
    lt_inventory_change_in          xxcoi_inv_reception_daily.inventory_change_in%TYPE;     -- 基準在庫変更入庫
    lt_inventory_change_out         xxcoi_inv_reception_daily.inventory_change_out%TYPE;    -- 基準在庫変更出庫
    lt_factory_return               xxcoi_inv_reception_daily.factory_return%TYPE;          -- 工場返品
    lt_factory_return_b             xxcoi_inv_reception_daily.factory_return_b%TYPE;        -- 工場返品振戻
    lt_factory_change               xxcoi_inv_reception_daily.factory_change%TYPE;          -- 工場倉替
    lt_factory_change_b             xxcoi_inv_reception_daily.factory_change_b%TYPE;        -- 工場倉替振戻
    lt_removed_goods                xxcoi_inv_reception_daily.removed_goods%TYPE;           -- 廃却
    lt_removed_goods_b              xxcoi_inv_reception_daily.removed_goods_b%TYPE;         -- 廃却振戻
    lt_factory_stock                xxcoi_inv_reception_daily.factory_stock%TYPE;           -- 工場入庫
    lt_factory_stock_b              xxcoi_inv_reception_daily.factory_stock_b%TYPE;         -- 工場入庫振戻
    lt_ccm_sample_ship              xxcoi_inv_reception_daily.ccm_sample_ship%TYPE;         -- 顧客広告宣伝費A自社商品
    lt_ccm_sample_ship_b            xxcoi_inv_reception_daily.ccm_sample_ship_b%TYPE;       -- 顧客広告宣伝費A自社商品振戻
    lt_wear_decrease                xxcoi_inv_reception_daily.wear_decrease%TYPE;           -- 棚卸減耗増
    lt_wear_increase                xxcoi_inv_reception_daily.wear_increase%TYPE;           -- 棚卸減耗減
    lt_selfbase_ship                xxcoi_inv_reception_daily.selfbase_ship%TYPE;           -- 保管場所移動＿自拠点出庫
    lt_selfbase_stock               xxcoi_inv_reception_daily.selfbase_stock%TYPE;          -- 保管場所移動＿自拠点入庫
    lt_book_inventory_quantity      xxcoi_inv_reception_daily.book_inventory_quantity%TYPE; -- 帳簿在庫数
-- == 2009/08/26 V1.8 Deleted START ===============================================================
---- == 2009/05/28 V1.4 Added START ===============================================================
--    lt_practice_date                xxcoi_inv_reception_daily.practice_date%TYPE;             -- 年月
---- == 2009/05/28 V1.4 Added START ===============================================================
-- == 2009/08/26 V1.8 Deleted END   ===============================================================
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 資材取引データ取得
    CURSOR  material_transaction_cur
    IS
-- == 2009/08/26 V1.8 Modified START ===============================================================
--      SELECT  msi1.attribute7                         base_code                   -- 拠点コード
      SELECT  /*+ LEADING(MMT)
                  USE_NL(MMT MSI1 MTT)
                  USE_NL(MMT MSI2)
                  USE_NL(MMT xird_last)
                  USE_NL(MMT xird_today)
                  INDEX(MMT MTL_MATERIAL_TRANSACTIONS_U1)
                  */
              msi1.attribute7                         base_code                   -- 拠点コード
-- == 2009/08/26 V1.8 Modified END   ===============================================================
             ,msi1.attribute1                         inventory_type              -- 保管場所区分
             ,msi2.attribute7                         sub_base_code               -- 相手先拠点コード
             ,msi2.attribute1                         subinventory_type           -- 相手先保管場所区分
             ,mmt.subinventory_code                   subinventory_code           -- 保管場所コード
             ,mtt.attribute3                          transaction_type            -- 受払表集計キー
             ,mmt.inventory_item_id                   inventory_item_id           -- 品目ID
             ,TO_CHAR(mmt.transaction_date, cv_month) transaction_month           -- 取引年月
             ,TRUNC(mmt.transaction_date)             transaction_date            -- 取引日
-- == 2009/07/30 V1.7 Modified START ===============================================================
--             ,mmt.transaction_quantity                transaction_qty             -- 取引数量
             ,mmt.primary_quantity                    transaction_qty             -- 基準単位数量
-- == 2009/07/30 V1.7 Modified END   ===============================================================
             ,xird_last.book_inventory_quantity       last_book_inv_quantity      -- 帳簿在庫数（前月）
             ,xird_today.book_inventory_quantity      today_book_inv_quantity     -- 帳簿在庫数（当日）
-- == 2009/06/04 V1.5 Added START ===============================================================
             ,msi1.attribute13                        subinv_class                -- 保管場所分類
-- == 2009/06/04 V1.5 Added END   ===============================================================
      FROM    mtl_material_transactions     mmt                                   -- 資材取引テーブル
             ,mtl_secondary_inventories     msi1                                  -- 保管場所
             ,mtl_secondary_inventories     msi2                                  -- 保管場所
             ,xxcoi_inv_reception_daily     xird_last                             -- 月次在庫受払表（日時）（前月分）
             ,xxcoi_inv_reception_daily     xird_today                            -- 月次在庫受払表（日次）（当日分）
             ,mtl_transaction_types         mtt                                   -- 取引タイプマスタ
      WHERE   mmt.organization_id         =   gn_f_organization_id
      AND     mmt.transaction_id          >   gn_f_last_transaction_id
      AND     mmt.transaction_id         <=   gn_f_max_transaction_id
      AND     TRUNC(mmt.transaction_date)
                  BETWEEN TO_DATE(TO_CHAR(ADD_MONTHS(gd_f_business_date, -1), cv_month) || '01', cv_date)
                  AND     gd_f_business_date
      AND     mmt.subinventory_code       =   msi1.secondary_inventory_name
      AND     mmt.organization_id         =   msi1.organization_id
      AND     mmt.transfer_subinventory   =   msi2.secondary_inventory_name(+)
-- == 2009/08/26 V1.8 Added START ===============================================================
      AND     mmt.transfer_organization_id  =  msi2.organization_id(+)
-- == 2009/08/26 V1.8 Added END   ===============================================================
      AND     msi1.attribute1            <>   cv_inv_type_5
      AND     msi1.attribute1            <>   cv_inv_type_8
      AND     mmt.organization_id         =   xird_last.organization_id(+)
      AND     mmt.subinventory_code       =   xird_last.subinventory_code(+)
      AND     mmt.inventory_item_id       =   xird_last.inventory_item_id(+)
      AND     gd_f_max_practice_date      =   xird_last.practice_date(+)
      AND     mmt.organization_id         =   xird_today.organization_id(+)
      AND     mmt.subinventory_code       =   xird_today.subinventory_code(+)
      AND     mmt.inventory_item_id       =   xird_today.inventory_item_id(+)
      AND     gd_f_business_date          =   xird_today.practice_date(+)
      AND     mmt.transaction_type_id     =   mtt.transaction_type_id
      AND     mtt.attribute3       IS NOT NULL
      ORDER BY  msi1.attribute7
               ,mmt.subinventory_code
               ,mmt.inventory_item_id
               ,mmt.transaction_date  DESC;
    --
    -- 資材取引データ取得レコード型
    material_transaction_rec    material_transaction_cur%ROWTYPE;
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
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
    -- ===================================
    --  1.在庫会計期間CLOSEチェック
    -- ===================================
    xxcoi_common_pkg.org_acct_period_chk(
       in_organization_id   =>  gn_f_organization_id                  -- 組織ID
      ,id_target_date       =>  ADD_MONTHS(gd_f_business_date, -1)    -- 業務処理日付の前月
      ,ob_chk_result        =>  lb_chk_result                         -- チェック結果
      ,ov_errbuf            =>  lv_errbuf
      ,ov_retcode           =>  lv_retcode
      ,ov_errmsg            =>  lv_errmsg
    );
    -- 終了判定
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- ===================================
    --  日時データ作成
    -- ===================================
    -- カーソルOPEN
    OPEN  material_transaction_cur;
    FETCH material_transaction_cur  INTO  material_transaction_rec;
    --
    lt_base_code                :=  material_transaction_rec.base_code;
    lt_subinventory_code        :=  material_transaction_rec.subinventory_code;
    lt_inventory_item_id        :=  material_transaction_rec.inventory_item_id;
    lv_transaction_month        :=  material_transaction_rec.transaction_month;
    --
    <<set_material_loop>>
    LOOP
      -- 資材取引データが１件も取得されない場合、LOOP処理終了
      EXIT set_material_loop WHEN material_transaction_cur%NOTFOUND AND ln_material_flag = 0;
      --
      -- 拠点、保管場所、品目、取引日（年月）のいずれかが前レコードと一致しない場合、または、
      -- 最終レコードの処理完了後の場合、日時データを挿入、または、更新
      IF (    (material_transaction_rec.base_code          <>  lt_base_code)
          OR  (material_transaction_rec.subinventory_code  <>  lt_subinventory_code)
          OR  (material_transaction_rec.inventory_item_id  <>  lt_inventory_item_id)
          OR  (material_transaction_rec.transaction_month  <>  lv_transaction_month)
          OR  (material_transaction_cur%NOTFOUND)
         )
      THEN
        --
        -- ===================================
        --  2.標準原価取得
        -- ===================================
        xxcoi_common_pkg.get_cmpnt_cost(
          in_item_id      =>  lt_inventory_item_id                            -- 品目ID
         ,in_org_id       =>  gn_f_organization_id                            -- 組織ID
         ,id_period_date  =>  lt_transaction_date                             -- 対象日
         ,ov_cmpnt_cost   =>  lt_standard_cost                                -- 標準原価
         ,ov_errbuf       =>  lv_errbuf                                       -- エラーメッセージ
         ,ov_retcode      =>  lv_retcode                                      -- リターン・コード
         ,ov_errmsg       =>  lv_errmsg                                       -- ユーザー・エラーメッセージ
        );
        -- 終了パラメータ判定
        IF (lv_retcode = cv_status_error) THEN
          lv_errmsg   := xxccp_common_pkg.get_msg(
                           iv_application  => cv_short_name
                          ,iv_name         => cv_msg_xxcoi1_10285
                         );
          lv_errbuf   := lv_errmsg;
          RAISE global_api_expt;
        END IF;
        --
        -- ===================================
        --  2.営業原価取得
        -- ===================================
        xxcoi_common_pkg.get_discrete_cost(
          in_item_id        =>  lt_inventory_item_id                            -- 品目ID
         ,in_org_id         =>  gn_f_organization_id                            -- 組織ID
         ,id_target_date    =>  lt_transaction_date                             -- 対象日
         ,ov_discrete_cost  =>  lt_operation_cost                               -- 営業原価
         ,ov_errbuf         =>  lv_errbuf                                       -- エラーメッセージ
         ,ov_retcode        =>  lv_retcode                                      -- リターン・コード
         ,ov_errmsg         =>  lv_errmsg                                       -- ユーザー・エラーメッセージ
        );
        -- 終了パラメータ判定
        IF (lv_retcode = cv_status_error) THEN
          lv_errmsg   := xxccp_common_pkg.get_msg(
                           iv_application  => cv_short_name
                          ,iv_name         => cv_msg_xxcoi1_10293
                         );
          lv_errbuf   := lv_errmsg;
          RAISE global_api_expt;
        END IF;
        --
        -- ==========================
        --  更新用データ設定
        -- ==========================
        lt_sales_shipped            :=  gt_quantity(1)  * -1  ;       -- 売上出庫
        lt_sales_shipped_b          :=  gt_quantity(2)        ;       -- 売上出庫振戻
        lt_return_goods             :=  gt_quantity(3)        ;       -- 返品
        lt_return_goods_b           :=  gt_quantity(4)  * -1  ;       -- 返品振戻
        lt_warehouse_ship           :=  gt_quantity(5)  * -1  ;       -- 倉庫へ返庫
        lt_truck_ship               :=  gt_quantity(6)  * -1  ;       -- 営業車へ出庫
        lt_others_ship              :=  gt_quantity(7)  * -1  ;       -- 入出庫＿その他出庫
        lt_warehouse_stock          :=  gt_quantity(8)        ;       -- 倉庫より入庫
        lt_truck_stock              :=  gt_quantity(9)        ;       -- 営業車より入庫
        lt_others_stock             :=  gt_quantity(10)       ;       -- 入出庫＿その他入庫
        lt_change_stock             :=  gt_quantity(11)       ;       -- 倉替入庫
        lt_change_ship              :=  gt_quantity(12) * -1  ;       -- 倉替出庫
        lt_goods_transfer_old       :=  gt_quantity(13) * -1  ;       -- 商品振替（旧商品）
        lt_goods_transfer_new       :=  gt_quantity(14)       ;       -- 商品振替（新商品）
        lt_sample_quantity          :=  gt_quantity(15) * -1  ;       -- 見本出庫
        lt_sample_quantity_b        :=  gt_quantity(16)       ;       -- 見本出庫振戻
        lt_customer_sample_ship     :=  gt_quantity(17) * -1  ;       -- 顧客見本出庫
        lt_customer_sample_ship_b   :=  gt_quantity(18)       ;       -- 顧客見本出庫振戻
        lt_customer_support_ss      :=  gt_quantity(19) * -1  ;       -- 顧客協賛見本出庫
        lt_customer_support_ss_b    :=  gt_quantity(20)       ;       -- 顧客協賛見本出庫振戻
        lt_vd_supplement_stock      :=  gt_quantity(21)       ;       -- 消化VD補充入庫
        lt_vd_supplement_ship       :=  gt_quantity(22) * -1  ;       -- 消化VD補充出庫
        lt_inventory_change_in      :=  gt_quantity(23)       ;       -- 基準在庫変更入庫
        lt_inventory_change_out     :=  gt_quantity(24) * -1  ;       -- 基準在庫変更出庫
        lt_factory_return           :=  gt_quantity(25) * -1  ;       -- 工場返品
        lt_factory_return_b         :=  gt_quantity(26)       ;       -- 工場返品振戻
        lt_factory_change           :=  gt_quantity(27) * -1  ;       -- 工場倉替
        lt_factory_change_b         :=  gt_quantity(28)       ;       -- 工場倉替振戻
        lt_removed_goods            :=  gt_quantity(29) * -1  ;       -- 廃却
        lt_removed_goods_b          :=  gt_quantity(30)       ;       -- 廃却振戻
        lt_factory_stock            :=  gt_quantity(31)       ;       -- 工場入庫
        lt_factory_stock_b          :=  gt_quantity(32) * -1  ;       -- 工場入庫振戻
        lt_ccm_sample_ship          :=  gt_quantity(33) * -1  ;       -- 顧客広告宣伝費A自社商品
        lt_ccm_sample_ship_b        :=  gt_quantity(34)       ;       -- 顧客広告宣伝費A自社商品振戻
        lt_wear_decrease            :=  gt_quantity(35)       ;       -- 棚卸減耗増
        lt_wear_increase            :=  gt_quantity(36) * -1  ;       -- 棚卸減耗減
        lt_selfbase_ship            :=  gt_quantity(37) * -1  ;       -- 保管場所移動＿自拠点出庫
        lt_selfbase_stock           :=  gt_quantity(38)       ;       -- 保管場所移動＿自拠点入庫
        -- 帳簿在庫数
        lt_book_inventory_quantity  :=  gt_quantity(1)  + gt_quantity(2)  + gt_quantity(3)
                                      + gt_quantity(4)  + gt_quantity(5)  + gt_quantity(6)
                                      + gt_quantity(7)  + gt_quantity(8)  + gt_quantity(9)
                                      + gt_quantity(10) + gt_quantity(11) + gt_quantity(12)
                                      + gt_quantity(13) + gt_quantity(14) + gt_quantity(15)
                                      + gt_quantity(16) + gt_quantity(17) + gt_quantity(18)
                                      + gt_quantity(19) + gt_quantity(20) + gt_quantity(21)
                                      + gt_quantity(22) + gt_quantity(23) + gt_quantity(24)
                                      + gt_quantity(25) + gt_quantity(26) + gt_quantity(27)
                                      + gt_quantity(28) + gt_quantity(29) + gt_quantity(30)
                                      + gt_quantity(31) + gt_quantity(32) + gt_quantity(33)
                                      + gt_quantity(34) + gt_quantity(35) + gt_quantity(36)
                                      + gt_quantity(37) + gt_quantity(38);
        --
        IF (    (lt_sales_shipped            = 0)   -- 売上出庫
            AND (lt_sales_shipped_b          = 0)   -- 売上出庫振戻
            AND (lt_return_goods             = 0)   -- 返品
            AND (lt_return_goods_b           = 0)   -- 返品振戻
            AND (lt_warehouse_ship           = 0)   -- 倉庫へ返庫
            AND (lt_truck_ship               = 0)   -- 営業車へ出庫
            AND (lt_others_ship              = 0)   -- 入出庫＿その他出庫
            AND (lt_warehouse_stock          = 0)   -- 倉庫より入庫
            AND (lt_truck_stock              = 0)   -- 営業車より入庫
            AND (lt_others_stock             = 0)   -- 入出庫＿その他入庫
            AND (lt_change_stock             = 0)   -- 倉替入庫
            AND (lt_change_ship              = 0)   -- 倉替出庫
            AND (lt_goods_transfer_old       = 0)   -- 商品振替（旧商品）
            AND (lt_goods_transfer_new       = 0)   -- 商品振替（新商品）
            AND (lt_sample_quantity          = 0)   -- 見本出庫
            AND (lt_sample_quantity_b        = 0)   -- 見本出庫振戻
            AND (lt_customer_sample_ship     = 0)   -- 顧客見本出庫
            AND (lt_customer_sample_ship_b   = 0)   -- 顧客見本出庫振戻
            AND (lt_customer_support_ss      = 0)   -- 顧客協賛見本出庫
            AND (lt_customer_support_ss_b    = 0)   -- 顧客協賛見本出庫振戻
            AND (lt_vd_supplement_stock      = 0)   -- 消化VD補充入庫
            AND (lt_vd_supplement_ship       = 0)   -- 消化VD補充出庫
            AND (lt_inventory_change_in      = 0)   -- 基準在庫変更入庫
            AND (lt_inventory_change_out     = 0)   -- 基準在庫変更出庫
            AND (lt_factory_return           = 0)   -- 工場返品
            AND (lt_factory_return_b         = 0)   -- 工場返品振戻
            AND (lt_factory_change           = 0)   -- 工場倉替
            AND (lt_factory_change_b         = 0)   -- 工場倉替振戻
            AND (lt_removed_goods            = 0)   -- 廃却
            AND (lt_removed_goods_b          = 0)   -- 廃却振戻
            AND (lt_factory_stock            = 0)   -- 工場入庫
            AND (lt_factory_stock_b          = 0)   -- 工場入庫振戻
            AND (lt_ccm_sample_ship          = 0)   -- 顧客広告宣伝費A自社商品
            AND (lt_ccm_sample_ship_b        = 0)   -- 顧客広告宣伝費A自社商品振戻
            AND (lt_wear_decrease            = 0)   -- 棚卸減耗増
            AND (lt_wear_increase            = 0)   -- 棚卸減耗減
            AND (lt_selfbase_ship            = 0)   -- 保管場所移動＿自拠点出庫
            AND (lt_selfbase_stock           = 0)   -- 保管場所移動＿自拠点入庫
            AND (lt_book_inventory_quantity  = 0)   -- 帳簿在庫数
           )
        THEN
          -- 全項目０の場合、日時在庫受払表を作成しない
-- == 2009/08/26 V1.8 Modified START ===============================================================
---- == 2009/06/05 V1.6 Added START ===============================================================
--          -- 累計テーブル作成用年月を設定
--          lt_practice_date  :=  NULL;
---- == 2009/06/05 V1.6 Added START ===============================================================
          -- 何もしない
          NULL;
-- == 2009/08/26 V1.8 Modified END   ===============================================================
          --
        ELSIF (lv_transaction_month = TO_CHAR(gd_f_business_date, cv_month)) THEN
          -- 取引日が業務年月と同一の場合、当日データとして処理
          -- ==========================
          --  日時データ作成（当日分）
          -- ==========================
          -- 当日分（INSERT）
          ln_today_data         :=  ln_today_data + 1;        -- 資材取引当日分データ件数カウント
          --
          IF (lt_today_book_inv_quantity IS NOT NULL) THEN
            -- 当日分データが存在する場合、当日分をUPDATE
            UPDATE  xxcoi_inv_reception_daily
            SET     sales_shipped               = sales_shipped           + lt_sales_shipped            -- 10.売上出庫
                   ,sales_shipped_b             = sales_shipped_b         + lt_sales_shipped_b          -- 11.売上出庫振戻
                   ,return_goods                = return_goods            + lt_return_goods             -- 12.返品
                   ,return_goods_b              = return_goods_b          + lt_return_goods_b           -- 13.返品振戻
                   ,warehouse_ship              = warehouse_ship          + lt_warehouse_ship           -- 14.倉庫へ返庫
                   ,truck_ship                  = truck_ship              + lt_truck_ship               -- 15.営業車へ出庫
                   ,others_ship                 = others_ship             + lt_others_ship              -- 16.入出庫＿その他出庫
                   ,warehouse_stock             = warehouse_stock         + lt_warehouse_stock          -- 17.倉庫より入庫
                   ,truck_stock                 = truck_stock             + lt_truck_stock              -- 18.営業車より入庫
                   ,others_stock                = others_stock            + lt_others_stock             -- 19.入出庫＿その他入庫
                   ,change_stock                = change_stock            + lt_change_stock             -- 20.倉替入庫
                   ,change_ship                 = change_ship             + lt_change_ship              -- 21.倉替出庫
                   ,goods_transfer_old          = goods_transfer_old      + lt_goods_transfer_old       -- 22.商品振替（旧商品）
                   ,goods_transfer_new          = goods_transfer_new      + lt_goods_transfer_new       -- 23.商品振替（新商品）
                   ,sample_quantity             = sample_quantity         + lt_sample_quantity          -- 24.見本出庫
                   ,sample_quantity_b           = sample_quantity_b       + lt_sample_quantity_b        -- 25.見本出庫振戻
                   ,customer_sample_ship        = customer_sample_ship    + lt_customer_sample_ship     -- 26.顧客見本出庫
                   ,customer_sample_ship_b      = customer_sample_ship_b  + lt_customer_sample_ship_b   -- 27.顧客見本出庫振戻
                   ,customer_support_ss         = customer_support_ss     + lt_customer_support_ss      -- 28.顧客協賛見本出庫
                   ,customer_support_ss_b       = customer_support_ss_b   + lt_customer_support_ss_b    -- 29.顧客協賛見本出庫振戻
                   ,vd_supplement_stock         = vd_supplement_stock     + lt_vd_supplement_stock      -- 32.消化VD補充入庫
                   ,vd_supplement_ship          = vd_supplement_ship      + lt_vd_supplement_ship       -- 33.消化VD補充出庫
                   ,inventory_change_in         = inventory_change_in     + lt_inventory_change_in      -- 34.基準在庫変更入庫
                   ,inventory_change_out        = inventory_change_out    + lt_inventory_change_out     -- 35.基準在庫変更出庫
                   ,factory_return              = factory_return          + lt_factory_return           -- 36.工場返品
                   ,factory_return_b            = factory_return_b        + lt_factory_return_b         -- 37.工場返品振戻
                   ,factory_change              = factory_change          + lt_factory_change           -- 38.工場倉替
                   ,factory_change_b            = factory_change_b        + lt_factory_change_b         -- 39.工場倉替振戻
                   ,removed_goods               = removed_goods           + lt_removed_goods            -- 40.廃却
                   ,removed_goods_b             = removed_goods_b         + lt_removed_goods_b          -- 41.廃却振戻
                   ,factory_stock               = factory_stock           + lt_factory_stock            -- 42.工場入庫
                   ,factory_stock_b             = factory_stock_b         + lt_factory_stock_b          -- 43.工場入庫振戻
                   ,ccm_sample_ship             = ccm_sample_ship         + lt_ccm_sample_ship          -- 30.顧客広告宣伝費A自社商品
                   ,ccm_sample_ship_b           = ccm_sample_ship_b       + lt_ccm_sample_ship_b        -- 31.顧客広告宣伝費A自社商品振戻
                   ,wear_decrease               = wear_decrease           + lt_wear_decrease            -- 44.棚卸減耗増
                   ,wear_increase               = wear_increase           + lt_wear_increase            -- 45.棚卸減耗減
                   ,selfbase_ship               = selfbase_ship           + lt_selfbase_ship            -- 46.保管場所移動＿自拠点出庫
                   ,selfbase_stock              = selfbase_stock          + lt_selfbase_stock           -- 47.保管場所移動＿自拠点入庫
                   ,book_inventory_quantity     = book_inventory_quantity + lt_book_inventory_quantity  -- 48.帳簿在庫
                   ,last_update_date            = SYSDATE                                               -- 49.最終更新日
                   ,last_updated_by             = cn_last_updated_by                                    -- 50.最終更新者
                   ,last_update_login           = cn_last_update_login                                  -- 53.最終更新ユーザ
                   ,request_id                  = cn_request_id                                         -- 54.要求ID
                   ,program_application_id      = cn_program_application_id                             -- 55.プログラムアプリケーションID
                   ,program_id                  = cn_program_id                                         -- 56.プログラムID
                   ,program_update_date         = SYSDATE                                               -- 57.プログラム更新日
            WHERE   base_code           =   lt_base_code
---- == 2009/08/26 V1.8 Added START ===============================================================
            AND     organization_id     =   gn_f_organization_id
---- == 2009/08/26 V1.8 Added END   ===============================================================
            AND     subinventory_code   =   lt_subinventory_code
            AND     inventory_item_id   =   lt_inventory_item_id
            AND     practice_date       =   gd_f_business_date;
            --
          ELSE
            -- 当日分データが存在しない場合、当日分をINSERT
            INSERT INTO xxcoi_inv_reception_daily(
              base_code                             -- 01.拠点コード
             ,organization_id                       -- 02.組織ID
             ,subinventory_code                     -- 03.保管場所
             ,practice_date                         -- 04.年月日
             ,inventory_item_id                     -- 05.品目ID
             ,subinventory_type                     -- 06.保管場所区分
             ,operation_cost                        -- 07.営業原価
             ,standard_cost                         -- 08.標準原価
             ,previous_inventory_quantity           -- 09.前日在庫数
             ,sales_shipped                         -- 10.売上出庫
             ,sales_shipped_b                       -- 11.売上出庫振戻
             ,return_goods                          -- 12.返品
             ,return_goods_b                        -- 13.返品振戻
             ,warehouse_ship                        -- 14.倉庫へ返庫
             ,truck_ship                            -- 15.営業車へ出庫
             ,others_ship                           -- 16.入出庫＿その他出庫
             ,warehouse_stock                       -- 17.倉庫より入庫
             ,truck_stock                           -- 18.営業車より入庫
             ,others_stock                          -- 19.入出庫＿その他入庫
             ,change_stock                          -- 20.倉替入庫
             ,change_ship                           -- 21.倉替出庫
             ,goods_transfer_old                    -- 22.商品振替（旧商品）
             ,goods_transfer_new                    -- 23.商品振替（新商品）
             ,sample_quantity                       -- 24.見本出庫
             ,sample_quantity_b                     -- 25.見本出庫振戻
             ,customer_sample_ship                  -- 26.顧客見本出庫
             ,customer_sample_ship_b                -- 27.顧客見本出庫振戻
             ,customer_support_ss                   -- 28.顧客協賛見本出庫
             ,customer_support_ss_b                 -- 29.顧客協賛見本出庫振戻
             ,vd_supplement_stock                   -- 32.消化VD補充入庫
             ,vd_supplement_ship                    -- 33.消化VD補充出庫
             ,inventory_change_in                   -- 34.基準在庫変更入庫
             ,inventory_change_out                  -- 35.基準在庫変更出庫
             ,factory_return                        -- 36.工場返品
             ,factory_return_b                      -- 37.工場返品振戻
             ,factory_change                        -- 38.工場倉替
             ,factory_change_b                      -- 39.工場倉替振戻
             ,removed_goods                         -- 40.廃却
             ,removed_goods_b                       -- 41.廃却振戻
             ,factory_stock                         -- 42.工場入庫
             ,factory_stock_b                       -- 43.工場入庫振戻
             ,ccm_sample_ship                       -- 30.顧客広告宣伝費A自社商品
             ,ccm_sample_ship_b                     -- 31.顧客広告宣伝費A自社商品振戻
             ,wear_decrease                         -- 44.棚卸減耗増
             ,wear_increase                         -- 45.棚卸減耗減
             ,selfbase_ship                         -- 46.保管場所移動＿自拠点出庫
             ,selfbase_stock                        -- 47.保管場所移動＿自拠点入庫
             ,book_inventory_quantity               -- 48.帳簿在庫数
             ,last_update_date                      -- 49.最終更新日
             ,last_updated_by                       -- 50.最終更新者
             ,creation_date                         -- 51.作成日
             ,created_by                            -- 52.作成者
             ,last_update_login                     -- 53.最終更新ユーザ
             ,request_id                            -- 54.要求ID
             ,program_application_id                -- 55.プログラムアプリケーションID
             ,program_id                            -- 56.プログラムID
             ,program_update_date                   -- 57.プログラム更新日
            )VALUES(
              lt_base_code                          -- 01
             ,gn_f_organization_id                  -- 02
             ,lt_subinventory_code                  -- 03
             ,gd_f_business_date                    -- 04
             ,lt_inventory_item_id                  -- 05
             ,lt_subinventory_type                  -- 06
             ,lt_operation_cost                     -- 07
             ,lt_standard_cost                      -- 08
             ,0                                     -- 09
             ,lt_sales_shipped                      -- 10
             ,lt_sales_shipped_b                    -- 11
             ,lt_return_goods                       -- 12
             ,lt_return_goods_b                     -- 13
             ,lt_warehouse_ship                     -- 14
             ,lt_truck_ship                         -- 15
             ,lt_others_ship                        -- 16
             ,lt_warehouse_stock                    -- 17
             ,lt_truck_stock                        -- 18
             ,lt_others_stock                       -- 19
             ,lt_change_stock                       -- 20
             ,lt_change_ship                        -- 21
             ,lt_goods_transfer_old                 -- 22
             ,lt_goods_transfer_new                 -- 23
             ,lt_sample_quantity                    -- 24
             ,lt_sample_quantity_b                  -- 25
             ,lt_customer_sample_ship               -- 26
             ,lt_customer_sample_ship_b             -- 27
             ,lt_customer_support_ss                -- 28
             ,lt_customer_support_ss_b              -- 29
             ,lt_vd_supplement_stock                -- 32
             ,lt_vd_supplement_ship                 -- 33
             ,lt_inventory_change_in                -- 34
             ,lt_inventory_change_out               -- 35
             ,lt_factory_return                     -- 36
             ,lt_factory_return_b                   -- 37
             ,lt_factory_change                     -- 38
             ,lt_factory_change_b                   -- 39
             ,lt_removed_goods                      -- 40
             ,lt_removed_goods_b                    -- 41
             ,lt_factory_stock                      -- 42
             ,lt_factory_stock_b                    -- 43
             ,lt_ccm_sample_ship                    -- 30
             ,lt_ccm_sample_ship_b                  -- 31
             ,lt_wear_decrease                      -- 44
             ,lt_wear_increase                      -- 45
             ,lt_selfbase_ship                      -- 46
             ,lt_selfbase_stock                     -- 47
             ,lt_book_inventory_quantity            -- 48
             ,SYSDATE                               -- 49
             ,cn_last_updated_by                    -- 50
             ,SYSDATE                               -- 51
             ,cn_created_by                         -- 52
             ,cn_last_update_login                  -- 53
             ,cn_request_id                         -- 54
             ,cn_program_application_id             -- 55
             ,cn_program_id                         -- 56
             ,SYSDATE                               -- 57
            );
            --
---- == 2009/08/26 V1.8 Added START ===============================================================
            gn_target_cnt := gn_target_cnt + 1;
---- == 2009/08/26 V1.8 Added END   ===============================================================
          END IF;
          --
-- == 2009/08/26 V1.8 Deleted START ===============================================================
---- == 2009/05/28 V1.4 Added START ===============================================================
--          -- 累計テーブル作成用年月を設定
--          lt_practice_date  :=  gd_f_business_date;
---- == 2009/05/28 V1.4 Added START ===============================================================
-- == 2009/08/26 V1.8 Deleted END   ===============================================================
        ELSE
          -- ========================================
          --  日時データ作成（前月分）
          -- ========================================
          -- 取引日が業務年月と不一致の場合、前月データとして処理
          -- 在庫会計期間がOPEN
          IF (lb_chk_result) THEN
            IF (lt_last_book_inv_quantity IS NOT NULL) THEN
              -- ロック処理を実行
              BEGIN
                SELECT  1
                INTO    ln_dummy
                FROM    xxcoi_inv_reception_daily   xird
                WHERE   xird.base_code           =   lt_base_code
---- == 2009/08/26 V1.8 Added START ===============================================================
                AND     xird.organization_id     =   gn_f_organization_id
---- == 2009/08/26 V1.8 Added END   ===============================================================
                AND     xird.subinventory_code   =   lt_subinventory_code
                AND     xird.inventory_item_id   =   lt_inventory_item_id
                AND     xird.practice_date       =   gd_f_max_practice_date
                FOR UPDATE NOWAIT;
                --
              EXCEPTION
                WHEN  lock_error_expt THEN
                  lv_errmsg   := xxccp_common_pkg.get_msg(
                                   iv_application  => cv_short_name
                                  ,iv_name         => cv_msg_xxcoi1_10363
                                 );
                  lv_errbuf   := lv_errmsg;
                  RAISE global_process_expt;
                  --
              END;
              --
              -- 前月データが存在する場合、前月分をUPDATE
              UPDATE  xxcoi_inv_reception_daily
              SET     sales_shipped             = sales_shipped           + lt_sales_shipped            -- 10.売上出庫
                     ,sales_shipped_b           = sales_shipped_b         + lt_sales_shipped_b          -- 11.売上出庫振戻
                     ,return_goods              = return_goods            + lt_return_goods             -- 12.返品
                     ,return_goods_b            = return_goods_b          + lt_return_goods_b           -- 13.返品振戻
                     ,warehouse_ship            = warehouse_ship          + lt_warehouse_ship           -- 14.倉庫へ返庫
                     ,truck_ship                = truck_ship              + lt_truck_ship               -- 15.営業車へ出庫
                     ,others_ship               = others_ship             + lt_others_ship              -- 16.入出庫＿その他出庫
                     ,warehouse_stock           = warehouse_stock         + lt_warehouse_stock          -- 17.倉庫より入庫
                     ,truck_stock               = truck_stock             + lt_truck_stock              -- 18.営業車より入庫
                     ,others_stock              = others_stock            + lt_others_stock             -- 19.入出庫＿その他入庫
                     ,change_stock              = change_stock            + lt_change_stock             -- 20.倉替入庫
                     ,change_ship               = change_ship             + lt_change_ship              -- 21.倉替出庫
                     ,goods_transfer_old        = goods_transfer_old      + lt_goods_transfer_old       -- 22.商品振替（旧商品）
                     ,goods_transfer_new        = goods_transfer_new      + lt_goods_transfer_new       -- 23.商品振替（新商品）
                     ,sample_quantity           = sample_quantity         + lt_sample_quantity          -- 24.見本出庫
                     ,sample_quantity_b         = sample_quantity_b       + lt_sample_quantity_b        -- 25.見本出庫振戻
                     ,customer_sample_ship      = customer_sample_ship    + lt_customer_sample_ship     -- 26.顧客見本出庫
                     ,customer_sample_ship_b    = customer_sample_ship_b  + lt_customer_sample_ship_b   -- 27.顧客見本出庫振戻
                     ,customer_support_ss       = customer_support_ss     + lt_customer_support_ss      -- 28.顧客協賛見本出庫
                     ,customer_support_ss_b     = customer_support_ss_b   + lt_customer_support_ss_b    -- 29.顧客協賛見本出庫振戻
                     ,vd_supplement_stock       = vd_supplement_stock     + lt_vd_supplement_stock      -- 32.消化VD補充入庫
                     ,vd_supplement_ship        = vd_supplement_ship      + lt_vd_supplement_ship       -- 33.消化VD補充出庫
                     ,inventory_change_in       = inventory_change_in     + lt_inventory_change_in      -- 34.基準在庫変更入庫
                     ,inventory_change_out      = inventory_change_out    + lt_inventory_change_out     -- 35.基準在庫変更出庫
                     ,factory_return            = factory_return          + lt_factory_return           -- 36.工場返品
                     ,factory_return_b          = factory_return_b        + lt_factory_return_b         -- 37.工場返品振戻
                     ,factory_change            = factory_change          + lt_factory_change           -- 38.工場倉替
                     ,factory_change_b          = factory_change_b        + lt_factory_change_b         -- 39.工場倉替振戻
                     ,removed_goods             = removed_goods           + lt_removed_goods            -- 40.廃却
                     ,removed_goods_b           = removed_goods_b         + lt_removed_goods_b          -- 41.廃却振戻
                     ,factory_stock             = factory_stock           + lt_factory_stock            -- 42.工場入庫
                     ,factory_stock_b           = factory_stock_b         + lt_factory_stock_b          -- 43.工場入庫振戻
                     ,ccm_sample_ship           = ccm_sample_ship         + lt_ccm_sample_ship          -- 30.顧客広告宣伝費A自社商品
                     ,ccm_sample_ship_b         = ccm_sample_ship_b       + lt_ccm_sample_ship_b        -- 31.顧客広告宣伝費A自社商品振戻
                     ,wear_decrease             = wear_decrease           + lt_wear_decrease            -- 44.棚卸減耗増
                     ,wear_increase             = wear_increase           + lt_wear_increase            -- 45.棚卸減耗減
                     ,selfbase_ship             = selfbase_ship           + lt_selfbase_ship            -- 46.保管場所移動＿自拠点出庫
                     ,selfbase_stock            = selfbase_stock          + lt_selfbase_stock           -- 47.保管場所移動＿自拠点入庫
                     ,book_inventory_quantity   = book_inventory_quantity + lt_book_inventory_quantity  -- 48.帳簿在庫
                     ,last_update_date          = SYSDATE                                               -- 49.最終更新日
                     ,last_updated_by           = cn_last_updated_by                                    -- 50.最終更新者
                     ,last_update_login         = cn_last_update_login                                  -- 53.最終更新ユーザ
                     ,request_id                = cn_request_id                                         -- 54.要求ID
                     ,program_application_id    = cn_program_application_id                             -- 55.プログラムアプリケーションID
                     ,program_id                = cn_program_id                                         -- 56.プログラムID
                     ,program_update_date       = SYSDATE                                               -- 57.プログラム更新日
              WHERE   base_code           =   lt_base_code
---- == 2009/08/26 V1.8 Added START ===============================================================
              AND     organization_id     =   gn_f_organization_id
---- == 2009/08/26 V1.8 Added END   ===============================================================
              AND     subinventory_code   =   lt_subinventory_code
              AND     inventory_item_id   =   lt_inventory_item_id
              AND     practice_date       =   gd_f_max_practice_date;
              --
---- == 2009/08/26 V1.8 Added START ===============================================================
              gn_target_cnt := gn_target_cnt + 1;
---- == 2009/08/26 V1.8 Added END   ===============================================================
            ELSE
              -- 前月データが存在しない場合、前月分をINSERT
              INSERT INTO xxcoi_inv_reception_daily(
                base_code                             -- 01.拠点コード
               ,organization_id                       -- 02.組織ID
               ,subinventory_code                     -- 03.保管場所
               ,practice_date                         -- 04.年月日
               ,inventory_item_id                     -- 05.品目ID
               ,subinventory_type                     -- 06.保管場所区分
               ,operation_cost                        -- 07.営業原価
               ,standard_cost                         -- 08.標準原価
               ,previous_inventory_quantity           -- 09.前日在庫数
               ,sales_shipped                         -- 10.売上出庫
               ,sales_shipped_b                       -- 11.売上出庫振戻
               ,return_goods                          -- 12.返品
               ,return_goods_b                        -- 13.返品振戻
               ,warehouse_ship                        -- 14.倉庫へ返庫
               ,truck_ship                            -- 15.営業車へ出庫
               ,others_ship                           -- 16.入出庫＿その他出庫
               ,warehouse_stock                       -- 17.倉庫より入庫
               ,truck_stock                           -- 18.営業車より入庫
               ,others_stock                          -- 19.入出庫＿その他入庫
               ,change_stock                          -- 20.倉替入庫
               ,change_ship                           -- 21.倉替出庫
               ,goods_transfer_old                    -- 22.商品振替（旧商品）
               ,goods_transfer_new                    -- 23.商品振替（新商品）
               ,sample_quantity                       -- 24.見本出庫
               ,sample_quantity_b                     -- 25.見本出庫振戻
               ,customer_sample_ship                  -- 26.顧客見本出庫
               ,customer_sample_ship_b                -- 27.顧客見本出庫振戻
               ,customer_support_ss                   -- 28.顧客協賛見本出庫
               ,customer_support_ss_b                 -- 29.顧客協賛見本出庫振戻
               ,vd_supplement_stock                   -- 32.消化VD補充入庫
               ,vd_supplement_ship                    -- 33.消化VD補充出庫
               ,inventory_change_in                   -- 34.基準在庫変更入庫
               ,inventory_change_out                  -- 35.基準在庫変更出庫
               ,factory_return                        -- 36.工場返品
               ,factory_return_b                      -- 37.工場返品振戻
               ,factory_change                        -- 38.工場倉替
               ,factory_change_b                      -- 39.工場倉替振戻
               ,removed_goods                         -- 40.廃却
               ,removed_goods_b                       -- 41.廃却振戻
               ,factory_stock                         -- 42.工場入庫
               ,factory_stock_b                       -- 43.工場入庫振戻
               ,ccm_sample_ship                       -- 30.顧客広告宣伝費A自社商品
               ,ccm_sample_ship_b                     -- 31.顧客広告宣伝費A自社商品振戻
               ,wear_decrease                         -- 44.棚卸減耗増
               ,wear_increase                         -- 45.棚卸減耗減
               ,selfbase_ship                         -- 46.保管場所移動＿自拠点出庫
               ,selfbase_stock                        -- 47.保管場所移動＿自拠点入庫
               ,book_inventory_quantity               -- 48.帳簿在庫数
               ,last_update_date                      -- 49.最終更新日
               ,last_updated_by                       -- 50.最終更新者
               ,creation_date                         -- 51.作成日
               ,created_by                            -- 52.作成者
               ,last_update_login                     -- 53.最終更新ユーザ
               ,request_id                            -- 54.要求ID
               ,program_application_id                -- 55.プログラムアプリケーションID
               ,program_id                            -- 56.プログラムID
               ,program_update_date                   -- 57.プログラム更新日
              )VALUES(
                lt_base_code                          -- 01
               ,gn_f_organization_id                  -- 02
               ,lt_subinventory_code                  -- 03
               ,gd_f_max_practice_date                -- 04
               ,lt_inventory_item_id                  -- 05
               ,lt_subinventory_type                  -- 06
               ,lt_operation_cost                     -- 07
               ,lt_standard_cost                      -- 08
               ,0                                     -- 09
               ,lt_sales_shipped                      -- 10
               ,lt_sales_shipped_b                    -- 11
               ,lt_return_goods                       -- 12
               ,lt_return_goods_b                     -- 13
               ,lt_warehouse_ship                     -- 14
               ,lt_truck_ship                         -- 15
               ,lt_others_ship                        -- 16
               ,lt_warehouse_stock                    -- 17
               ,lt_truck_stock                        -- 18
               ,lt_others_stock                       -- 19
               ,lt_change_stock                       -- 20
               ,lt_change_ship                        -- 21
               ,lt_goods_transfer_old                 -- 22
               ,lt_goods_transfer_new                 -- 23
               ,lt_sample_quantity                    -- 24
               ,lt_sample_quantity_b                  -- 25
               ,lt_customer_sample_ship               -- 26
               ,lt_customer_sample_ship_b             -- 27
               ,lt_customer_support_ss                -- 28
               ,lt_customer_support_ss_b              -- 29
               ,lt_vd_supplement_stock                -- 32
               ,lt_vd_supplement_ship                 -- 33
               ,lt_inventory_change_in                -- 34
               ,lt_inventory_change_out               -- 35
               ,lt_factory_return                     -- 36
               ,lt_factory_return_b                   -- 37
               ,lt_factory_change                     -- 38
               ,lt_factory_change_b                   -- 39
               ,lt_removed_goods                      -- 40
               ,lt_removed_goods_b                    -- 41
               ,lt_factory_stock                      -- 42
               ,lt_factory_stock_b                    -- 43
               ,lt_ccm_sample_ship                    -- 30
               ,lt_ccm_sample_ship_b                  -- 31
               ,lt_wear_decrease                      -- 44
               ,lt_wear_increase                      -- 45
               ,lt_selfbase_ship                      -- 46
               ,lt_selfbase_stock                     -- 47
               ,lt_book_inventory_quantity            -- 48
               ,SYSDATE                               -- 49
               ,cn_last_updated_by                    -- 50
               ,SYSDATE                               -- 51
               ,cn_created_by                         -- 52
               ,cn_last_update_login                  -- 53
               ,cn_request_id                         -- 54
               ,cn_program_application_id             -- 55
               ,cn_program_id                         -- 56
               ,SYSDATE                               -- 57
              );
              --
---- == 2009/08/26 V1.8 Added START ===============================================================
              gn_target_cnt := gn_target_cnt + 1;
---- == 2009/08/26 V1.8 Added END   ===============================================================
            END IF;
            --
          END IF;
          --
          -- ========================================
          --  日時データ作成（前月分を当日分に反映）
          -- ========================================
          BEGIN
            -- 当日レコードの存在チェック
            SELECT  1
            INTO    ln_dummy
            FROM    xxcoi_inv_reception_daily   xird
            WHERE   xird.base_code           =   lt_base_code
---- == 2009/08/26 V1.8 Added START ===============================================================
            AND     xird.organization_id     =   gn_f_organization_id
---- == 2009/08/26 V1.8 Added END   ===============================================================
            AND     xird.subinventory_code   =   lt_subinventory_code
            AND     xird.inventory_item_id   =   lt_inventory_item_id
            AND     xird.practice_date       =   gd_f_business_date
            AND     ROWNUM = 1;
            --
            -- 当月データが存在する場合、当月分をUPDATE
            UPDATE  xxcoi_inv_reception_daily
            SET     previous_inventory_quantity = previous_inventory_quantity + lt_book_inventory_quantity  -- 09.前日在庫数
                   ,book_inventory_quantity     = book_inventory_quantity     + lt_book_inventory_quantity  -- 48.帳簿在庫
                   ,last_update_date            = SYSDATE                                                   -- 49.最終更新日
                   ,last_updated_by             = cn_last_updated_by                                        -- 50.最終更新者
                   ,last_update_login           = cn_last_update_login                                      -- 53.最終更新ユーザ
                   ,request_id                  = cn_request_id                                             -- 54.要求ID
                   ,program_application_id      = cn_program_application_id                                 -- 55.プログラムアプリケーションID
                   ,program_id                  = cn_program_id                                             -- 56.プログラムID
                   ,program_update_date         = SYSDATE                                                   -- 57.プログラム更新日
            WHERE   base_code           =   lt_base_code
---- == 2009/08/26 V1.8 Added START ===============================================================
            AND     organization_id     =   gn_f_organization_id
---- == 2009/08/26 V1.8 Added END   ===============================================================
            AND     subinventory_code   =   lt_subinventory_code
            AND     inventory_item_id   =   lt_inventory_item_id
            AND     practice_date       =   gd_f_business_date;
            --
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- 当月データが存在しない場合、当月分をINSERT
              INSERT INTO xxcoi_inv_reception_daily(
                base_code                             -- 01.拠点コード
               ,organization_id                       -- 02.組織ID
               ,subinventory_code                     -- 03.保管場所
               ,practice_date                         -- 04.年月日
               ,inventory_item_id                     -- 05.品目ID
               ,subinventory_type                     -- 06.保管場所区分
               ,operation_cost                        -- 07.営業原価
               ,standard_cost                         -- 08.標準原価
               ,previous_inventory_quantity           -- 09.前日在庫数
               ,sales_shipped                         -- 10.売上出庫
               ,sales_shipped_b                       -- 11.売上出庫振戻
               ,return_goods                          -- 12.返品
               ,return_goods_b                        -- 13.返品振戻
               ,warehouse_ship                        -- 14.倉庫へ返庫
               ,truck_ship                            -- 15.営業車へ出庫
               ,others_ship                           -- 16.入出庫＿その他出庫
               ,warehouse_stock                       -- 17.倉庫より入庫
               ,truck_stock                           -- 18.営業車より入庫
               ,others_stock                          -- 19.入出庫＿その他入庫
               ,change_stock                          -- 20.倉替入庫
               ,change_ship                           -- 21.倉替出庫
               ,goods_transfer_old                    -- 22.商品振替（旧商品）
               ,goods_transfer_new                    -- 23.商品振替（新商品）
               ,sample_quantity                       -- 24.見本出庫
               ,sample_quantity_b                     -- 25.見本出庫振戻
               ,customer_sample_ship                  -- 26.顧客見本出庫
               ,customer_sample_ship_b                -- 27.顧客見本出庫振戻
               ,customer_support_ss                   -- 28.顧客協賛見本出庫
               ,customer_support_ss_b                 -- 29.顧客協賛見本出庫振戻
               ,vd_supplement_stock                   -- 32.消化VD補充入庫
               ,vd_supplement_ship                    -- 33.消化VD補充出庫
               ,inventory_change_in                   -- 34.基準在庫変更入庫
               ,inventory_change_out                  -- 35.基準在庫変更出庫
               ,factory_return                        -- 36.工場返品
               ,factory_return_b                      -- 37.工場返品振戻
               ,factory_change                        -- 38.工場倉替
               ,factory_change_b                      -- 39.工場倉替振戻
               ,removed_goods                         -- 40.廃却
               ,removed_goods_b                       -- 41.廃却振戻
               ,factory_stock                         -- 42.工場入庫
               ,factory_stock_b                       -- 43.工場入庫振戻
               ,ccm_sample_ship                       -- 30.顧客広告宣伝費A自社商品
               ,ccm_sample_ship_b                     -- 31.顧客広告宣伝費A自社商品振戻
               ,wear_decrease                         -- 44.棚卸減耗増
               ,wear_increase                         -- 45.棚卸減耗減
               ,selfbase_ship                         -- 46.保管場所移動＿自拠点出庫
               ,selfbase_stock                        -- 47.保管場所移動＿自拠点入庫
               ,book_inventory_quantity               -- 48.帳簿在庫数
               ,last_update_date                      -- 49.最終更新日
               ,last_updated_by                       -- 50.最終更新者
               ,creation_date                         -- 51.作成日
               ,created_by                            -- 52.作成者
               ,last_update_login                     -- 53.最終更新ユーザ
               ,request_id                            -- 54.要求ID
               ,program_application_id                -- 55.プログラムアプリケーションID
               ,program_id                            -- 56.プログラムID
               ,program_update_date                   -- 57.プログラム更新日
              )VALUES(
                lt_base_code                          -- 01
               ,gn_f_organization_id                  -- 02
               ,lt_subinventory_code                  -- 03
               ,gd_f_business_date                    -- 04
               ,lt_inventory_item_id                  -- 05
               ,lt_subinventory_type                  -- 06
               ,lt_operation_cost                     -- 07
               ,lt_standard_cost                      -- 08
               ,lt_book_inventory_quantity            -- 09
               ,0                                     -- 10
               ,0                                     -- 11
               ,0                                     -- 12
               ,0                                     -- 13
               ,0                                     -- 14
               ,0                                     -- 15
               ,0                                     -- 16
               ,0                                     -- 17
               ,0                                     -- 18
               ,0                                     -- 19
               ,0                                     -- 20
               ,0                                     -- 21
               ,0                                     -- 22
               ,0                                     -- 23
               ,0                                     -- 24
               ,0                                     -- 25
               ,0                                     -- 26
               ,0                                     -- 27
               ,0                                     -- 28
               ,0                                     -- 29
               ,0                                     -- 32
               ,0                                     -- 33
               ,0                                     -- 34
               ,0                                     -- 35
               ,0                                     -- 36
               ,0                                     -- 37
               ,0                                     -- 38
               ,0                                     -- 39
               ,0                                     -- 40
               ,0                                     -- 41
               ,0                                     -- 42
               ,0                                     -- 43
               ,0                                     -- 30
               ,0                                     -- 31
               ,0                                     -- 44
               ,0                                     -- 45
               ,0                                     -- 46
               ,0                                     -- 47
               ,lt_book_inventory_quantity            -- 48
               ,SYSDATE                               -- 49
               ,cn_last_updated_by                    -- 50
               ,SYSDATE                               -- 51
               ,cn_created_by                         -- 52
               ,cn_last_update_login                  -- 53
               ,cn_request_id                         -- 54
               ,cn_program_application_id             -- 55
               ,cn_program_id                         -- 56
               ,SYSDATE                               -- 57
              );
              --
---- == 2009/08/26 V1.8 Added START ===============================================================
              gn_target_cnt := gn_target_cnt + 1;
---- == 2009/08/26 V1.8 Added END   ===============================================================
          END;
          --
-- == 2009/08/26 V1.8 Deleted START ===============================================================
---- == 2009/05/28 V1.4 Added START ===============================================================
--          -- 累計テーブル作成用年月を設定
--          lt_practice_date  :=  gd_f_max_practice_date;
---- == 2009/05/28 V1.4 Added START ===============================================================
-- == 2009/08/26 V1.8 Deleted END   ===============================================================
        END IF;
        --
-- == 2009/08/26 V1.8 Deleted START ===============================================================
---- == 2009/05/28 V1.4 Added START ===============================================================
---- == 2009/06/05 V1.6 Added START ===============================================================
--          -- 累計テーブル作成用年月が設定されている場合、累計情報を作成
--        IF (lt_practice_date  IS NOT NULL)  THEN
---- == 2009/06/05 V1.6 Added START ===============================================================
--          -- ==============================================
--          --  A-8.累計受払データ出力
--          -- ==============================================
--          set_reception_sum(
--            it_base_code                =>  lt_base_code                          -- 01.拠点コード
--           ,it_subinventory_code        =>  lt_subinventory_code                  -- 03.保管場所
--           ,it_practice_date            =>  lt_practice_date                      -- 04.年月日
--           ,it_inventory_item_id        =>  lt_inventory_item_id                  -- 05.品目ID
--           ,it_subinventory_type        =>  lt_subinventory_type                  -- 06.保管場所区分
--           ,it_operation_cost           =>  lt_operation_cost                     -- 07.営業原価
--           ,it_standard_cost            =>  lt_standard_cost                      -- 08.標準原価
--           ,it_sales_shipped            =>  lt_sales_shipped                      -- 10.売上出庫
--           ,it_sales_shipped_b          =>  lt_sales_shipped_b                    -- 11.売上出庫振戻
--           ,it_return_goods             =>  lt_return_goods                       -- 12.返品
--           ,it_return_goods_b           =>  lt_return_goods_b                     -- 13.返品振戻
--           ,it_warehouse_ship           =>  lt_warehouse_ship                     -- 14.倉庫へ返庫
--           ,it_truck_ship               =>  lt_truck_ship                         -- 15.営業車へ出庫
--           ,it_others_ship              =>  lt_others_ship                        -- 16.入出庫＿その他出庫
--           ,it_warehouse_stock          =>  lt_warehouse_stock                    -- 17.倉庫より入庫
--           ,it_truck_stock              =>  lt_truck_stock                        -- 18.営業車より入庫
--           ,it_others_stock             =>  lt_others_stock                       -- 19.入出庫＿その他入庫
--           ,it_change_stock             =>  lt_change_stock                       -- 20.倉替入庫
--           ,it_change_ship              =>  lt_change_ship                        -- 21.倉替出庫
--           ,it_goods_transfer_old       =>  lt_goods_transfer_old                 -- 22.商品振替（旧商品）
--           ,it_goods_transfer_new       =>  lt_goods_transfer_new                 -- 23.商品振替（新商品）
--           ,it_sample_quantity          =>  lt_sample_quantity                    -- 24.見本出庫
--           ,it_sample_quantity_b        =>  lt_sample_quantity_b                  -- 25.見本出庫振戻
--           ,it_customer_sample_ship     =>  lt_customer_sample_ship               -- 26.顧客見本出庫
--           ,it_customer_sample_ship_b   =>  lt_customer_sample_ship_b             -- 27.顧客見本出庫振戻
--           ,it_customer_support_ss      =>  lt_customer_support_ss                -- 28.顧客協賛見本出庫
--           ,it_customer_support_ss_b    =>  lt_customer_support_ss_b              -- 29.顧客協賛見本出庫振戻
--           ,it_vd_supplement_stock      =>  lt_vd_supplement_stock                -- 32.消化VD補充入庫
--           ,it_vd_supplement_ship       =>  lt_vd_supplement_ship                 -- 33.消化VD補充出庫
--           ,it_inventory_change_in      =>  lt_inventory_change_in                -- 34.基準在庫変更入庫
--           ,it_inventory_change_out     =>  lt_inventory_change_out               -- 35.基準在庫変更出庫
--           ,it_factory_return           =>  lt_factory_return                     -- 36.工場返品
--           ,it_factory_return_b         =>  lt_factory_return_b                   -- 37.工場返品振戻
--           ,it_factory_change           =>  lt_factory_change                     -- 38.工場倉替
--           ,it_factory_change_b         =>  lt_factory_change_b                   -- 39.工場倉替振戻
--           ,it_removed_goods            =>  lt_removed_goods                      -- 40.廃却
--           ,it_removed_goods_b          =>  lt_removed_goods_b                    -- 41.廃却振戻
--           ,it_factory_stock            =>  lt_factory_stock                      -- 42.工場入庫
--           ,it_factory_stock_b          =>  lt_factory_stock_b                    -- 43.工場入庫振戻
--           ,it_ccm_sample_ship          =>  lt_ccm_sample_ship                    -- 30.顧客広告宣伝費A自社商品
--           ,it_ccm_sample_ship_b        =>  lt_ccm_sample_ship_b                  -- 31.顧客広告宣伝費A自社商品振戻
--           ,it_wear_decrease            =>  lt_wear_decrease                      -- 44.棚卸減耗増
--           ,it_wear_increase            =>  lt_wear_increase                      -- 45.棚卸減耗減
--           ,it_selfbase_ship            =>  lt_selfbase_ship                      -- 46.保管場所移動＿自拠点出庫
--           ,it_selfbase_stock           =>  lt_selfbase_stock                     -- 47.保管場所移動＿自拠点入庫
--           ,it_book_inventory_quantity  =>  lt_book_inventory_quantity            -- 48.帳簿在庫数
--           ,ib_chk_result               =>  lb_chk_result                         -- 49.在庫会計期間OPEN判定
--           ,ov_errbuf                   =>  lv_errbuf       --   エラー・メッセージ           --# 固定 #
--           ,ov_retcode                  =>  lv_retcode      --   リターン・コード             --# 固定 #
--           ,ov_errmsg                   =>  lv_errmsg       --   ユーザー・エラー・メッセージ --# 固定 #
--          );
--          -- 終了パラメータ判定
--          IF (lv_retcode = cv_status_error) THEN
--            RAISE global_process_expt;
--          END IF;
---- == 2009/06/05 V1.6 Added START ===============================================================
--        END IF;
---- == 2009/06/05 V1.6 Added START ===============================================================
---- == 2009/05/28 V1.4 Added END   ===============================================================
-- == 2009/08/26 V1.8 Deleted END   ===============================================================
        -- 集計項目初期化
        FOR i IN  1 .. 38 LOOP
          gt_quantity(i)  :=  0;
        END LOOP;
        --
      END IF;
      --
      -- 終了判定
      EXIT set_material_loop WHEN material_transaction_cur%NOTFOUND;
      --
      -- 受払集計（取引タイプ別）
      CASE  material_transaction_rec.transaction_type
        WHEN  cv_trans_type_010  THEN   -- 01.売上出庫
          gt_quantity(1)   :=  gt_quantity(1) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_020  THEN   -- 02.売上出庫振戻
          gt_quantity(2)   :=  gt_quantity(2) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_030  THEN   -- 03.返品
          gt_quantity(3)   :=  gt_quantity(3) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_040  THEN   -- 04.返品振戻
          gt_quantity(4)   :=  gt_quantity(4) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_050  THEN
          IF (    (material_transaction_rec.transaction_qty    < 0)
              AND (material_transaction_rec.inventory_type     = cv_subinv_2)
              AND (material_transaction_rec.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
             )
          THEN
            -- 05.倉庫へ返庫
            gt_quantity(5)   :=  gt_quantity(5) + material_transaction_rec.transaction_qty;
          ELSIF (    (material_transaction_rec.transaction_qty    < 0)
                 AND (material_transaction_rec.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                 AND (material_transaction_rec.subinventory_type  = cv_subinv_2)
                )
          THEN
            -- 06.営業車へ出庫
            gt_quantity(6)   :=  gt_quantity(6) + material_transaction_rec.transaction_qty;
          ELSIF (    (material_transaction_rec.transaction_qty    < 0)
                 AND (material_transaction_rec.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                 AND (material_transaction_rec.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                )
          THEN
            -- 07.入出庫＿その他出庫
            gt_quantity(7)   :=  gt_quantity(7) + material_transaction_rec.transaction_qty;
          ELSIF (    (material_transaction_rec.transaction_qty    > 0)
                 AND (material_transaction_rec.inventory_type     = cv_subinv_2)
                 AND (material_transaction_rec.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                )
          THEN
            -- 08.倉庫より入庫
            gt_quantity(8)   :=  gt_quantity(8) + material_transaction_rec.transaction_qty;
          ELSIF (    (material_transaction_rec.transaction_qty    > 0)
                 AND (material_transaction_rec.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                 AND (material_transaction_rec.subinventory_type  = cv_subinv_2)
                )
          THEN
            -- 09.営業車より入庫
            gt_quantity(9)   :=  gt_quantity(9) + material_transaction_rec.transaction_qty;
          ELSIF (    (material_transaction_rec.transaction_qty    > 0)
                 AND (material_transaction_rec.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                 AND (material_transaction_rec.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                )
          THEN
            -- 10.入出庫＿その他入庫
            gt_quantity(10)  :=  gt_quantity(10) + material_transaction_rec.transaction_qty;
            --
          END IF;
        WHEN  cv_trans_type_060  THEN
-- == 2009/05/14 V1.3 Modified START ===============================================================
--          IF (material_transaction_rec.transaction_qty >= 0) THEN
--            -- 11.倉替入庫
--            gt_quantity(11)  :=  gt_quantity(11) + material_transaction_rec.transaction_qty;
--          ELSIF (material_transaction_rec.transaction_qty < 0) THEN
--            -- 12.倉替出庫
--            gt_quantity(12)  :=  gt_quantity(12) + material_transaction_rec.transaction_qty;
--          END IF;
--
          IF (    (material_transaction_rec.transaction_qty    < 0)
              AND (material_transaction_rec.inventory_type     = cv_subinv_2)
              AND (material_transaction_rec.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
             )
          THEN
            -- 05.倉庫へ返庫
            gt_quantity(5)   :=  gt_quantity(5) + material_transaction_rec.transaction_qty;
          ELSIF (    (material_transaction_rec.transaction_qty    < 0)
                 AND (material_transaction_rec.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                 AND (material_transaction_rec.subinventory_type  = cv_subinv_2)
                )
          THEN
            -- 06.営業車へ出庫
            gt_quantity(6)   :=  gt_quantity(6) + material_transaction_rec.transaction_qty;
          ELSIF (    (material_transaction_rec.transaction_qty    < 0)
                 AND (material_transaction_rec.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                 AND (material_transaction_rec.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                )
          THEN
            -- 12.倉替出庫
            gt_quantity(12)  :=  gt_quantity(12) + material_transaction_rec.transaction_qty;
          ELSIF (    (material_transaction_rec.transaction_qty    > 0)
                 AND (material_transaction_rec.inventory_type     = cv_subinv_2)
                 AND (material_transaction_rec.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                )
          THEN
            -- 08.倉庫より入庫
            gt_quantity(8)   :=  gt_quantity(8) + material_transaction_rec.transaction_qty;
          ELSIF (    (material_transaction_rec.transaction_qty    > 0)
                 AND (material_transaction_rec.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                 AND (material_transaction_rec.subinventory_type  = cv_subinv_2)
                )
          THEN
            -- 09.営業車より入庫
            gt_quantity(9)   :=  gt_quantity(9) + material_transaction_rec.transaction_qty;
          ELSIF (    (material_transaction_rec.transaction_qty    > 0)
                 AND (material_transaction_rec.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                 AND (material_transaction_rec.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                )
          THEN
            -- 11.倉替入庫
            gt_quantity(11)  :=  gt_quantity(11) + material_transaction_rec.transaction_qty;
            --
          END IF;
-- == 2009/05/14 V1.3 Modified END   ===============================================================
        WHEN  cv_trans_type_070  THEN   -- 13.商品振替（旧商品）
          gt_quantity(13)  :=  gt_quantity(13) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_080  THEN   -- 14.商品振替（新商品）
          gt_quantity(14)  :=  gt_quantity(14) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_090  THEN   -- 15.見本出庫
          gt_quantity(15)  :=  gt_quantity(15) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_100 THEN   -- 16.見本出庫振戻
          gt_quantity(16)  :=  gt_quantity(16) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_110 THEN   -- 17.顧客見本出庫
          gt_quantity(17)  :=  gt_quantity(17) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_120 THEN   -- 18.顧客見本出庫振戻
          gt_quantity(18)  :=  gt_quantity(18) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_130 THEN   -- 19.顧客協賛見本出庫
          gt_quantity(19)  :=  gt_quantity(19) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_140 THEN   -- 20.顧客協賛見本出庫振戻
          gt_quantity(20)  :=  gt_quantity(20) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_150 THEN
          IF (material_transaction_rec.transaction_qty >= 0) THEN
            -- 21.消化VD補充入庫
            gt_quantity(21)  :=  gt_quantity(21) + material_transaction_rec.transaction_qty;
          ELSIF (material_transaction_rec.transaction_qty < 0) THEN
            -- 22.消化VD補充出庫
            gt_quantity(22)  :=  gt_quantity(22) + material_transaction_rec.transaction_qty;
          END IF;
        WHEN  cv_trans_type_160 THEN
-- == 2009/06/04 V1.5 Modified START ===============================================================
--          IF (material_transaction_rec.transaction_qty   >= 0) THEN
--            -- 23.基準在庫変更入庫
--            gt_quantity(23)  :=  gt_quantity(23) + material_transaction_rec.transaction_qty;
--          ELSIF (material_transaction_rec.transaction_qty < 0) THEN
--            -- 24.基準在庫変更出庫
--            gt_quantity(24)  :=  gt_quantity(24) + material_transaction_rec.transaction_qty;
--          END IF;
--
          IF (material_transaction_rec.subinv_class = cv_subinv_class_7)  THEN
            -- 消化VDは対象外
            NULL;
          ELSIF (material_transaction_rec.transaction_qty   >= 0) THEN
            -- 23.基準在庫変更入庫
            gt_quantity(23)  :=  gt_quantity(23) + material_transaction_rec.transaction_qty;
          ELSIF (material_transaction_rec.transaction_qty < 0) THEN
            -- 24.基準在庫変更出庫
            gt_quantity(24)  :=  gt_quantity(24) + material_transaction_rec.transaction_qty;
          END IF;
-- == 2009/06/04 V1.5 Modified END   ===============================================================
        WHEN  cv_trans_type_170 THEN   -- 25.工場返品
          gt_quantity(25)  :=  gt_quantity(25) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_180 THEN   -- 26.工場返品振戻
          gt_quantity(26)  :=  gt_quantity(26) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_190 THEN   -- 27.工場倉替
          gt_quantity(27)  :=  gt_quantity(27) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_200 THEN   -- 28.工場倉替振戻
          gt_quantity(28)  :=  gt_quantity(28) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_210 THEN   -- 29.廃却
          gt_quantity(29)  :=  gt_quantity(29) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_220 THEN   -- 30.廃却振戻
          gt_quantity(30)  :=  gt_quantity(30) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_230 THEN   -- 31.工場入庫
          gt_quantity(31)  :=  gt_quantity(31) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_240 THEN   -- 32.工場入庫振戻
          gt_quantity(32)  :=  gt_quantity(32) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_250 THEN   -- 33.顧客広告宣伝費A自社商品
          gt_quantity(33)  :=  gt_quantity(33) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_260 THEN   -- 34.顧客広告宣伝費A自社商品振戻
          gt_quantity(34)  :=  gt_quantity(34) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_270 THEN   -- 35.棚卸減耗増
          gt_quantity(35)  :=  gt_quantity(35) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_280 THEN   -- 36.棚卸減耗減
          gt_quantity(36)  :=  gt_quantity(36) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_290 THEN
-- == 2009/05/08 V1.2 Deleted START ===============================================================
--          IF (material_transaction_rec.base_code = material_transaction_rec.sub_base_code) THEN
-- == 2009/05/08 V1.2 Deleted END   ===============================================================
            IF (material_transaction_rec.transaction_qty < 0) THEN
              -- 37.保管場所移動＿自拠点出庫
              gt_quantity(37)  :=  gt_quantity(37) + material_transaction_rec.transaction_qty;
            ELSIF (material_transaction_rec.transaction_qty >= 0) THEN
              -- 38.保管場所移動＿自拠点入庫
              gt_quantity(38)  :=  gt_quantity(38) + material_transaction_rec.transaction_qty;
            END IF;
-- == 2009/05/08 V1.2 Deleted START ===============================================================
--          END IF;
-- == 2009/05/08 V1.2 Deleted END   ===============================================================
        ELSE  NULL;
      END CASE;
      --
      -- レコード変更チェック用変数保持
      lt_base_code                :=  material_transaction_rec.base_code;
      lt_subinventory_code        :=  material_transaction_rec.subinventory_code;
      lt_inventory_item_id        :=  material_transaction_rec.inventory_item_id;
      lv_transaction_month        :=  material_transaction_rec.transaction_month;
      lt_transaction_date         :=  material_transaction_rec.transaction_date;
      lt_last_book_inv_quantity   :=  material_transaction_rec.last_book_inv_quantity;
      lt_today_book_inv_quantity  :=  material_transaction_rec.today_book_inv_quantity;
      lt_subinventory_type        :=  material_transaction_rec.inventory_type;
      --
      ln_material_flag    :=  1;
      FETCH material_transaction_cur  INTO  material_transaction_rec;
      --
    END LOOP set_material_loop;
    --
    CLOSE material_transaction_cur;
-- == 2009/10/15 V1.11 Added START ===============================================================
    gn_material_flag    :=  ln_material_flag;
-- == 2009/10/15 V1.11 Added START ===============================================================
    --
    IF (ln_today_data = 0) THEN
      -- 資材取引（当日分）データなし
      ov_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_short_name
                       ,iv_name         =>  cv_msg_xxcoi1_10128
                      );
      ov_errbuf   :=  ov_errmsg;
      ov_retcode  :=  cv_status_warn;
      gn_warn_cnt :=  gn_warn_cnt + 1;      -- 警告件数カウント
    END IF;
    --
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END set_mtl_transaction_data;
--
-- == 2009/08/26 V1.8 Added START ===============================================================
  /**********************************************************************************
   * Procedure Name   : set_mtl_transaction_data2
   * Description      : 当日データ月次在庫受払（累計）出力(A-10, A-11)
   ***********************************************************************************/
  PROCEDURE set_mtl_transaction_data2(
    ov_errbuf         OUT VARCHAR2,                     -- エラー・メッセージ                  --# 固定 #
    ov_retcode        OUT VARCHAR2,                     -- リターン・コード                    --# 固定 #
    ov_errmsg         OUT VARCHAR2)                     -- ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_mtl_transaction_data2'; -- プログラム名
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
    -- *** ローカル変数 ***
    lb_chk_result                   BOOLEAN;        -- 在庫会計期間OPENフラグ（OPEN:TRUE, CLOSE:FALSE）
    ln_material_flag                NUMBER  := 0;   -- 資材取引データ取得フラグ
    ln_today_data                   NUMBER  := 0;   -- 資材取引当日分データ件数
    --
    lt_base_code                    xxcoi_inv_reception_daily.base_code%TYPE;               -- 拠点コード
    lt_subinventory_code            xxcoi_inv_reception_daily.subinventory_code%TYPE;       -- 保管場所コード
    lt_inventory_item_id            xxcoi_inv_reception_daily.inventory_item_id%TYPE;       -- 品目ID
    lv_transaction_month            VARCHAR2(6);                                            -- 取引年月
    lt_transaction_date             mtl_material_transactions.transaction_date%TYPE;        -- 取引日
    lt_subinventory_type            xxcoi_inv_reception_daily.subinventory_type%TYPE;       -- 保管場所区分
    lt_standard_cost                xxcoi_inv_reception_daily.standard_cost%TYPE;           -- 標準原価
    lt_operation_cost               xxcoi_inv_reception_daily.operation_cost%TYPE;          -- 営業原価
    lt_sales_shipped                xxcoi_inv_reception_daily.sales_shipped%TYPE;           -- 売上出庫
    lt_sales_shipped_b              xxcoi_inv_reception_daily.sales_shipped_b%TYPE;         -- 売上出庫振戻
    lt_return_goods                 xxcoi_inv_reception_daily.return_goods%TYPE;            -- 返品
    lt_return_goods_b               xxcoi_inv_reception_daily.return_goods_b%TYPE;          -- 返品振戻
    lt_warehouse_ship               xxcoi_inv_reception_daily.warehouse_ship%TYPE;          -- 倉庫へ返庫
    lt_truck_ship                   xxcoi_inv_reception_daily.truck_ship%TYPE;              -- 営業車へ出庫
    lt_others_ship                  xxcoi_inv_reception_daily.others_ship%TYPE;             -- 入出庫＿その他出庫
    lt_warehouse_stock              xxcoi_inv_reception_daily.warehouse_stock%TYPE;         -- 倉庫より入庫
    lt_truck_stock                  xxcoi_inv_reception_daily.truck_stock%TYPE;             -- 営業車より入庫
    lt_others_stock                 xxcoi_inv_reception_daily.others_stock%TYPE;            -- 入出庫＿その他入庫
    lt_change_stock                 xxcoi_inv_reception_daily.change_stock%TYPE;            -- 倉替入庫
    lt_change_ship                  xxcoi_inv_reception_daily.change_ship%TYPE;             -- 倉替出庫
    lt_goods_transfer_old           xxcoi_inv_reception_daily.goods_transfer_old%TYPE;      -- 商品振替（旧商品）
    lt_goods_transfer_new           xxcoi_inv_reception_daily.goods_transfer_new%TYPE;      -- 商品振替（新商品）
    lt_sample_quantity              xxcoi_inv_reception_daily.sample_quantity%TYPE;         -- 見本出庫
    lt_sample_quantity_b            xxcoi_inv_reception_daily.sample_quantity_b%TYPE;       -- 見本出庫振戻
    lt_customer_sample_ship         xxcoi_inv_reception_daily.customer_sample_ship%TYPE;    -- 顧客見本出庫
    lt_customer_sample_ship_b       xxcoi_inv_reception_daily.customer_sample_ship_b%TYPE;  -- 顧客見本出庫振戻
    lt_customer_support_ss          xxcoi_inv_reception_daily.customer_support_ss%TYPE;     -- 顧客協賛見本出庫
    lt_customer_support_ss_b        xxcoi_inv_reception_daily.customer_support_ss_b%TYPE;   -- 顧客協賛見本出庫振戻
    lt_vd_supplement_stock          xxcoi_inv_reception_daily.vd_supplement_stock%TYPE;     -- 消化VD補充入庫
    lt_vd_supplement_ship           xxcoi_inv_reception_daily.vd_supplement_ship%TYPE;      -- 消化VD補充出庫
    lt_inventory_change_in          xxcoi_inv_reception_daily.inventory_change_in%TYPE;     -- 基準在庫変更入庫
    lt_inventory_change_out         xxcoi_inv_reception_daily.inventory_change_out%TYPE;    -- 基準在庫変更出庫
    lt_factory_return               xxcoi_inv_reception_daily.factory_return%TYPE;          -- 工場返品
    lt_factory_return_b             xxcoi_inv_reception_daily.factory_return_b%TYPE;        -- 工場返品振戻
    lt_factory_change               xxcoi_inv_reception_daily.factory_change%TYPE;          -- 工場倉替
    lt_factory_change_b             xxcoi_inv_reception_daily.factory_change_b%TYPE;        -- 工場倉替振戻
    lt_removed_goods                xxcoi_inv_reception_daily.removed_goods%TYPE;           -- 廃却
    lt_removed_goods_b              xxcoi_inv_reception_daily.removed_goods_b%TYPE;         -- 廃却振戻
    lt_factory_stock                xxcoi_inv_reception_daily.factory_stock%TYPE;           -- 工場入庫
    lt_factory_stock_b              xxcoi_inv_reception_daily.factory_stock_b%TYPE;         -- 工場入庫振戻
    lt_ccm_sample_ship              xxcoi_inv_reception_daily.ccm_sample_ship%TYPE;         -- 顧客広告宣伝費A自社商品
    lt_ccm_sample_ship_b            xxcoi_inv_reception_daily.ccm_sample_ship_b%TYPE;       -- 顧客広告宣伝費A自社商品振戻
    lt_wear_decrease                xxcoi_inv_reception_daily.wear_decrease%TYPE;           -- 棚卸減耗増
    lt_wear_increase                xxcoi_inv_reception_daily.wear_increase%TYPE;           -- 棚卸減耗減
    lt_selfbase_ship                xxcoi_inv_reception_daily.selfbase_ship%TYPE;           -- 保管場所移動＿自拠点出庫
    lt_selfbase_stock               xxcoi_inv_reception_daily.selfbase_stock%TYPE;          -- 保管場所移動＿自拠点入庫
    lt_book_inventory_quantity      xxcoi_inv_reception_daily.book_inventory_quantity%TYPE; -- 帳簿在庫数
    lt_practice_date                xxcoi_inv_reception_daily.practice_date%TYPE;           -- 年月
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 資材取引データ取得(累計用)
    CURSOR  material_transaction_cur
    IS
      SELECT  /*+ LEADING(MMT)
                  USE_NL(MMT MSI1 MTT)
                  USE_NL(MMT MSI2)
                  INDEX(MMT MTL_MATERIAL_TRANSACTIONS_U1)
                  */
              msi1.attribute7                         base_code                   -- 拠点コード
             ,msi1.attribute1                         inventory_type              -- 保管場所区分
             ,msi2.attribute7                         sub_base_code               -- 相手先拠点コード
             ,msi2.attribute1                         subinventory_type           -- 相手先保管場所区分
             ,mmt.subinventory_code                   subinventory_code           -- 保管場所コード
             ,mtt.attribute3                          transaction_type            -- 受払表集計キー
             ,mmt.inventory_item_id                   inventory_item_id           -- 品目ID
             ,TO_CHAR(mmt.transaction_date, cv_month) transaction_month           -- 取引年月
             ,TRUNC(mmt.transaction_date)             transaction_date            -- 取引日
             ,mmt.primary_quantity                    transaction_qty             -- 基準単位数量
             ,msi1.attribute13                        subinv_class                -- 保管場所分類
      FROM    mtl_material_transactions     mmt                                   -- 資材取引テーブル
             ,mtl_secondary_inventories     msi1                                  -- 保管場所
             ,mtl_secondary_inventories     msi2                                  -- 保管場所
             ,mtl_transaction_types         mtt                                   -- 取引タイプマスタ
      WHERE   mmt.organization_id         =   gn_f_organization_id
      AND     mmt.transaction_id          >   gn_f_last_transaction_id
      AND     mmt.transaction_id         <=   gn_f_max_transaction_id
      AND     TRUNC(mmt.transaction_date)
                  BETWEEN TO_DATE(TO_CHAR(ADD_MONTHS(gd_f_business_date, -1), cv_month) || '01', cv_date)
                  AND     gd_f_business_date
      AND     mmt.subinventory_code       =   msi1.secondary_inventory_name
      AND     mmt.organization_id         =   msi1.organization_id
      AND     mmt.transfer_subinventory   =   msi2.secondary_inventory_name(+)
      AND     mmt.transfer_organization_id =  msi2.organization_id(+)
      AND     msi1.attribute1            <>   cv_inv_type_5
      AND     msi1.attribute1            <>   cv_inv_type_8
      AND     mmt.transaction_type_id     =   mtt.transaction_type_id
      AND     mtt.attribute3       IS NOT NULL
      ORDER BY  msi1.attribute7
               ,mmt.subinventory_code
               ,mmt.inventory_item_id
               ,mmt.transaction_date  DESC;
    --
    -- 資材取引データ取得レコード型
    material_transaction_rec    material_transaction_cur%ROWTYPE;
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
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
    -- ===================================
    --  1.在庫会計期間CLOSEチェック
    -- ===================================
    xxcoi_common_pkg.org_acct_period_chk(
       in_organization_id   =>  gn_f_organization_id                  -- 組織ID
      ,id_target_date       =>  ADD_MONTHS(gd_f_business_date, -1)    -- 業務処理日付の前月
      ,ob_chk_result        =>  lb_chk_result                         -- チェック結果
      ,ov_errbuf            =>  lv_errbuf
      ,ov_retcode           =>  lv_retcode
      ,ov_errmsg            =>  lv_errmsg
    );
    -- 終了判定
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- ===================================
    --  日時データ作成
    -- ===================================
    -- カーソルOPEN
    OPEN  material_transaction_cur;
    FETCH material_transaction_cur  INTO  material_transaction_rec;
    --
    lt_base_code                :=  material_transaction_rec.base_code;
    lt_subinventory_code        :=  material_transaction_rec.subinventory_code;
    lt_inventory_item_id        :=  material_transaction_rec.inventory_item_id;
    lv_transaction_month        :=  material_transaction_rec.transaction_month;
    --
    <<set_material_loop>>
    LOOP
      -- 資材取引データが１件も取得されない場合、LOOP処理終了
      EXIT set_material_loop WHEN material_transaction_cur%NOTFOUND AND ln_material_flag = 0;
      --
      -- 拠点、保管場所、品目、取引日（年月）のいずれかが前レコードと一致しない場合、または、
      -- 最終レコードの処理完了後の場合、日時データを挿入、または、更新
      IF (    (material_transaction_rec.base_code          <>  lt_base_code)
          OR  (material_transaction_rec.subinventory_code  <>  lt_subinventory_code)
          OR  (material_transaction_rec.inventory_item_id  <>  lt_inventory_item_id)
          OR  (material_transaction_rec.transaction_month  <>  lv_transaction_month)
          OR  (material_transaction_cur%NOTFOUND)
         )
      THEN
        --
        -- ===================================
        --  2.標準原価取得
        -- ===================================
        xxcoi_common_pkg.get_cmpnt_cost(
          in_item_id      =>  lt_inventory_item_id                            -- 品目ID
         ,in_org_id       =>  gn_f_organization_id                            -- 組織ID
         ,id_period_date  =>  lt_transaction_date                             -- 対象日
         ,ov_cmpnt_cost   =>  lt_standard_cost                                -- 標準原価
         ,ov_errbuf       =>  lv_errbuf                                       -- エラーメッセージ
         ,ov_retcode      =>  lv_retcode                                      -- リターン・コード
         ,ov_errmsg       =>  lv_errmsg                                       -- ユーザー・エラーメッセージ
        );
        -- 終了パラメータ判定
        IF (lv_retcode = cv_status_error) THEN
          lv_errmsg   := xxccp_common_pkg.get_msg(
                           iv_application  => cv_short_name
                          ,iv_name         => cv_msg_xxcoi1_10285
                         );
          lv_errbuf   := lv_errmsg;
          RAISE global_api_expt;
        END IF;
        --
        -- ===================================
        --  2.営業原価取得
        -- ===================================
        xxcoi_common_pkg.get_discrete_cost(
          in_item_id        =>  lt_inventory_item_id                            -- 品目ID
         ,in_org_id         =>  gn_f_organization_id                            -- 組織ID
         ,id_target_date    =>  lt_transaction_date                             -- 対象日
         ,ov_discrete_cost  =>  lt_operation_cost                               -- 営業原価
         ,ov_errbuf         =>  lv_errbuf                                       -- エラーメッセージ
         ,ov_retcode        =>  lv_retcode                                      -- リターン・コード
         ,ov_errmsg         =>  lv_errmsg                                       -- ユーザー・エラーメッセージ
        );
        -- 終了パラメータ判定
        IF (lv_retcode = cv_status_error) THEN
          lv_errmsg   := xxccp_common_pkg.get_msg(
                           iv_application  => cv_short_name
                          ,iv_name         => cv_msg_xxcoi1_10293
                         );
          lv_errbuf   := lv_errmsg;
          RAISE global_api_expt;
        END IF;
        --
        -- ==========================
        --  更新用データ設定
        -- ==========================
        lt_sales_shipped            :=  gt_quantity(1)  * -1  ;       -- 売上出庫
        lt_sales_shipped_b          :=  gt_quantity(2)        ;       -- 売上出庫振戻
        lt_return_goods             :=  gt_quantity(3)        ;       -- 返品
        lt_return_goods_b           :=  gt_quantity(4)  * -1  ;       -- 返品振戻
        lt_warehouse_ship           :=  gt_quantity(5)  * -1  ;       -- 倉庫へ返庫
        lt_truck_ship               :=  gt_quantity(6)  * -1  ;       -- 営業車へ出庫
        lt_others_ship              :=  gt_quantity(7)  * -1  ;       -- 入出庫＿その他出庫
        lt_warehouse_stock          :=  gt_quantity(8)        ;       -- 倉庫より入庫
        lt_truck_stock              :=  gt_quantity(9)        ;       -- 営業車より入庫
        lt_others_stock             :=  gt_quantity(10)       ;       -- 入出庫＿その他入庫
        lt_change_stock             :=  gt_quantity(11)       ;       -- 倉替入庫
        lt_change_ship              :=  gt_quantity(12) * -1  ;       -- 倉替出庫
        lt_goods_transfer_old       :=  gt_quantity(13) * -1  ;       -- 商品振替（旧商品）
        lt_goods_transfer_new       :=  gt_quantity(14)       ;       -- 商品振替（新商品）
        lt_sample_quantity          :=  gt_quantity(15) * -1  ;       -- 見本出庫
        lt_sample_quantity_b        :=  gt_quantity(16)       ;       -- 見本出庫振戻
        lt_customer_sample_ship     :=  gt_quantity(17) * -1  ;       -- 顧客見本出庫
        lt_customer_sample_ship_b   :=  gt_quantity(18)       ;       -- 顧客見本出庫振戻
        lt_customer_support_ss      :=  gt_quantity(19) * -1  ;       -- 顧客協賛見本出庫
        lt_customer_support_ss_b    :=  gt_quantity(20)       ;       -- 顧客協賛見本出庫振戻
        lt_vd_supplement_stock      :=  gt_quantity(21)       ;       -- 消化VD補充入庫
        lt_vd_supplement_ship       :=  gt_quantity(22) * -1  ;       -- 消化VD補充出庫
        lt_inventory_change_in      :=  gt_quantity(23)       ;       -- 基準在庫変更入庫
        lt_inventory_change_out     :=  gt_quantity(24) * -1  ;       -- 基準在庫変更出庫
        lt_factory_return           :=  gt_quantity(25) * -1  ;       -- 工場返品
        lt_factory_return_b         :=  gt_quantity(26)       ;       -- 工場返品振戻
        lt_factory_change           :=  gt_quantity(27) * -1  ;       -- 工場倉替
        lt_factory_change_b         :=  gt_quantity(28)       ;       -- 工場倉替振戻
        lt_removed_goods            :=  gt_quantity(29) * -1  ;       -- 廃却
        lt_removed_goods_b          :=  gt_quantity(30)       ;       -- 廃却振戻
        lt_factory_stock            :=  gt_quantity(31)       ;       -- 工場入庫
        lt_factory_stock_b          :=  gt_quantity(32) * -1  ;       -- 工場入庫振戻
        lt_ccm_sample_ship          :=  gt_quantity(33) * -1  ;       -- 顧客広告宣伝費A自社商品
        lt_ccm_sample_ship_b        :=  gt_quantity(34)       ;       -- 顧客広告宣伝費A自社商品振戻
        lt_wear_decrease            :=  gt_quantity(35)       ;       -- 棚卸減耗増
        lt_wear_increase            :=  gt_quantity(36) * -1  ;       -- 棚卸減耗減
        lt_selfbase_ship            :=  gt_quantity(37) * -1  ;       -- 保管場所移動＿自拠点出庫
        lt_selfbase_stock           :=  gt_quantity(38)       ;       -- 保管場所移動＿自拠点入庫
        -- 帳簿在庫数
        lt_book_inventory_quantity  :=  gt_quantity(1)  + gt_quantity(2)  + gt_quantity(3)
                                      + gt_quantity(4)  + gt_quantity(5)  + gt_quantity(6)
                                      + gt_quantity(7)  + gt_quantity(8)  + gt_quantity(9)
                                      + gt_quantity(10) + gt_quantity(11) + gt_quantity(12)
                                      + gt_quantity(13) + gt_quantity(14) + gt_quantity(15)
                                      + gt_quantity(16) + gt_quantity(17) + gt_quantity(18)
                                      + gt_quantity(19) + gt_quantity(20) + gt_quantity(21)
                                      + gt_quantity(22) + gt_quantity(23) + gt_quantity(24)
                                      + gt_quantity(25) + gt_quantity(26) + gt_quantity(27)
                                      + gt_quantity(28) + gt_quantity(29) + gt_quantity(30)
                                      + gt_quantity(31) + gt_quantity(32) + gt_quantity(33)
                                      + gt_quantity(34) + gt_quantity(35) + gt_quantity(36)
                                      + gt_quantity(37) + gt_quantity(38);
        --
        IF (    (lt_sales_shipped            = 0)   -- 売上出庫
            AND (lt_sales_shipped_b          = 0)   -- 売上出庫振戻
            AND (lt_return_goods             = 0)   -- 返品
            AND (lt_return_goods_b           = 0)   -- 返品振戻
            AND (lt_warehouse_ship           = 0)   -- 倉庫へ返庫
            AND (lt_truck_ship               = 0)   -- 営業車へ出庫
            AND (lt_others_ship              = 0)   -- 入出庫＿その他出庫
            AND (lt_warehouse_stock          = 0)   -- 倉庫より入庫
            AND (lt_truck_stock              = 0)   -- 営業車より入庫
            AND (lt_others_stock             = 0)   -- 入出庫＿その他入庫
            AND (lt_change_stock             = 0)   -- 倉替入庫
            AND (lt_change_ship              = 0)   -- 倉替出庫
            AND (lt_goods_transfer_old       = 0)   -- 商品振替（旧商品）
            AND (lt_goods_transfer_new       = 0)   -- 商品振替（新商品）
            AND (lt_sample_quantity          = 0)   -- 見本出庫
            AND (lt_sample_quantity_b        = 0)   -- 見本出庫振戻
            AND (lt_customer_sample_ship     = 0)   -- 顧客見本出庫
            AND (lt_customer_sample_ship_b   = 0)   -- 顧客見本出庫振戻
            AND (lt_customer_support_ss      = 0)   -- 顧客協賛見本出庫
            AND (lt_customer_support_ss_b    = 0)   -- 顧客協賛見本出庫振戻
            AND (lt_vd_supplement_stock      = 0)   -- 消化VD補充入庫
            AND (lt_vd_supplement_ship       = 0)   -- 消化VD補充出庫
            AND (lt_inventory_change_in      = 0)   -- 基準在庫変更入庫
            AND (lt_inventory_change_out     = 0)   -- 基準在庫変更出庫
            AND (lt_factory_return           = 0)   -- 工場返品
            AND (lt_factory_return_b         = 0)   -- 工場返品振戻
            AND (lt_factory_change           = 0)   -- 工場倉替
            AND (lt_factory_change_b         = 0)   -- 工場倉替振戻
            AND (lt_removed_goods            = 0)   -- 廃却
            AND (lt_removed_goods_b          = 0)   -- 廃却振戻
            AND (lt_factory_stock            = 0)   -- 工場入庫
            AND (lt_factory_stock_b          = 0)   -- 工場入庫振戻
            AND (lt_ccm_sample_ship          = 0)   -- 顧客広告宣伝費A自社商品
            AND (lt_ccm_sample_ship_b        = 0)   -- 顧客広告宣伝費A自社商品振戻
            AND (lt_wear_decrease            = 0)   -- 棚卸減耗増
            AND (lt_wear_increase            = 0)   -- 棚卸減耗減
            AND (lt_selfbase_ship            = 0)   -- 保管場所移動＿自拠点出庫
            AND (lt_selfbase_stock           = 0)   -- 保管場所移動＿自拠点入庫
            AND (lt_book_inventory_quantity  = 0)   -- 帳簿在庫数
           )
        THEN
          -- 全項目０の場合、日時在庫受払表を作成しない
          -- 累計テーブル作成用年月を設定
          lt_practice_date  :=  NULL;
          --
        ELSIF (lv_transaction_month = TO_CHAR(gd_f_business_date, cv_month)) THEN
          -- 取引日が業務年月と同一の場合、当日データとして処理
          -- 資材取引当日分データ件数カウント
          ln_today_data     :=  ln_today_data + 1;
          -- 累計テーブル作成用年月を設定(業務処理日付)
          lt_practice_date  :=  gd_f_business_date;
        ELSE
          -- 累計テーブル作成用年月を設定(日次最大年月日)
          lt_practice_date  :=  gd_f_max_practice_date;
        END IF;
          -- 累計テーブル作成用年月が設定されている場合、累計情報を作成
        IF (lt_practice_date  IS NOT NULL)  THEN
          -- ==============================================
          --  A-8.累計受払データ出力
          -- ==============================================
          set_reception_sum(
            it_base_code                =>  lt_base_code                          -- 01.拠点コード
           ,it_subinventory_code        =>  lt_subinventory_code                  -- 03.保管場所
           ,it_practice_date            =>  lt_practice_date                      -- 04.年月日
           ,it_inventory_item_id        =>  lt_inventory_item_id                  -- 05.品目ID
           ,it_subinventory_type        =>  lt_subinventory_type                  -- 06.保管場所区分
           ,it_operation_cost           =>  lt_operation_cost                     -- 07.営業原価
           ,it_standard_cost            =>  lt_standard_cost                      -- 08.標準原価
           ,it_sales_shipped            =>  lt_sales_shipped                      -- 10.売上出庫
           ,it_sales_shipped_b          =>  lt_sales_shipped_b                    -- 11.売上出庫振戻
           ,it_return_goods             =>  lt_return_goods                       -- 12.返品
           ,it_return_goods_b           =>  lt_return_goods_b                     -- 13.返品振戻
           ,it_warehouse_ship           =>  lt_warehouse_ship                     -- 14.倉庫へ返庫
           ,it_truck_ship               =>  lt_truck_ship                         -- 15.営業車へ出庫
           ,it_others_ship              =>  lt_others_ship                        -- 16.入出庫＿その他出庫
           ,it_warehouse_stock          =>  lt_warehouse_stock                    -- 17.倉庫より入庫
           ,it_truck_stock              =>  lt_truck_stock                        -- 18.営業車より入庫
           ,it_others_stock             =>  lt_others_stock                       -- 19.入出庫＿その他入庫
           ,it_change_stock             =>  lt_change_stock                       -- 20.倉替入庫
           ,it_change_ship              =>  lt_change_ship                        -- 21.倉替出庫
           ,it_goods_transfer_old       =>  lt_goods_transfer_old                 -- 22.商品振替（旧商品）
           ,it_goods_transfer_new       =>  lt_goods_transfer_new                 -- 23.商品振替（新商品）
           ,it_sample_quantity          =>  lt_sample_quantity                    -- 24.見本出庫
           ,it_sample_quantity_b        =>  lt_sample_quantity_b                  -- 25.見本出庫振戻
           ,it_customer_sample_ship     =>  lt_customer_sample_ship               -- 26.顧客見本出庫
           ,it_customer_sample_ship_b   =>  lt_customer_sample_ship_b             -- 27.顧客見本出庫振戻
           ,it_customer_support_ss      =>  lt_customer_support_ss                -- 28.顧客協賛見本出庫
           ,it_customer_support_ss_b    =>  lt_customer_support_ss_b              -- 29.顧客協賛見本出庫振戻
           ,it_vd_supplement_stock      =>  lt_vd_supplement_stock                -- 32.消化VD補充入庫
           ,it_vd_supplement_ship       =>  lt_vd_supplement_ship                 -- 33.消化VD補充出庫
           ,it_inventory_change_in      =>  lt_inventory_change_in                -- 34.基準在庫変更入庫
           ,it_inventory_change_out     =>  lt_inventory_change_out               -- 35.基準在庫変更出庫
           ,it_factory_return           =>  lt_factory_return                     -- 36.工場返品
           ,it_factory_return_b         =>  lt_factory_return_b                   -- 37.工場返品振戻
           ,it_factory_change           =>  lt_factory_change                     -- 38.工場倉替
           ,it_factory_change_b         =>  lt_factory_change_b                   -- 39.工場倉替振戻
           ,it_removed_goods            =>  lt_removed_goods                      -- 40.廃却
           ,it_removed_goods_b          =>  lt_removed_goods_b                    -- 41.廃却振戻
           ,it_factory_stock            =>  lt_factory_stock                      -- 42.工場入庫
           ,it_factory_stock_b          =>  lt_factory_stock_b                    -- 43.工場入庫振戻
           ,it_ccm_sample_ship          =>  lt_ccm_sample_ship                    -- 30.顧客広告宣伝費A自社商品
           ,it_ccm_sample_ship_b        =>  lt_ccm_sample_ship_b                  -- 31.顧客広告宣伝費A自社商品振戻
           ,it_wear_decrease            =>  lt_wear_decrease                      -- 44.棚卸減耗増
           ,it_wear_increase            =>  lt_wear_increase                      -- 45.棚卸減耗減
           ,it_selfbase_ship            =>  lt_selfbase_ship                      -- 46.保管場所移動＿自拠点出庫
           ,it_selfbase_stock           =>  lt_selfbase_stock                     -- 47.保管場所移動＿自拠点入庫
           ,it_book_inventory_quantity  =>  lt_book_inventory_quantity            -- 48.帳簿在庫数
           ,ib_chk_result               =>  lb_chk_result                         -- 49.在庫会計期間OPEN判定
           ,ov_errbuf                   =>  lv_errbuf       --   エラー・メッセージ           --# 固定 #
           ,ov_retcode                  =>  lv_retcode      --   リターン・コード             --# 固定 #
           ,ov_errmsg                   =>  lv_errmsg       --   ユーザー・エラー・メッセージ --# 固定 #
          );
          -- 終了パラメータ判定
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
        -- 集計項目初期化
        FOR i IN  1 .. 38 LOOP
          gt_quantity(i)  :=  0;
        END LOOP;
        --
      END IF;
      --
      -- 終了判定
      EXIT set_material_loop WHEN material_transaction_cur%NOTFOUND;
      --
      -- 受払集計（取引タイプ別）
      CASE  material_transaction_rec.transaction_type
        WHEN  cv_trans_type_010  THEN   -- 01.売上出庫
          gt_quantity(1)   :=  gt_quantity(1) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_020  THEN   -- 02.売上出庫振戻
          gt_quantity(2)   :=  gt_quantity(2) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_030  THEN   -- 03.返品
          gt_quantity(3)   :=  gt_quantity(3) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_040  THEN   -- 04.返品振戻
          gt_quantity(4)   :=  gt_quantity(4) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_050  THEN
          IF (    (material_transaction_rec.transaction_qty    < 0)
              AND (material_transaction_rec.inventory_type     = cv_subinv_2)
              AND (material_transaction_rec.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
             )
          THEN
            -- 05.倉庫へ返庫
            gt_quantity(5)   :=  gt_quantity(5) + material_transaction_rec.transaction_qty;
          ELSIF (    (material_transaction_rec.transaction_qty    < 0)
                 AND (material_transaction_rec.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                 AND (material_transaction_rec.subinventory_type  = cv_subinv_2)
                )
          THEN
            -- 06.営業車へ出庫
            gt_quantity(6)   :=  gt_quantity(6) + material_transaction_rec.transaction_qty;
          ELSIF (    (material_transaction_rec.transaction_qty    < 0)
                 AND (material_transaction_rec.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                 AND (material_transaction_rec.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                )
          THEN
            -- 07.入出庫＿その他出庫
            gt_quantity(7)   :=  gt_quantity(7) + material_transaction_rec.transaction_qty;
          ELSIF (    (material_transaction_rec.transaction_qty    > 0)
                 AND (material_transaction_rec.inventory_type     = cv_subinv_2)
                 AND (material_transaction_rec.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                )
          THEN
            -- 08.倉庫より入庫
            gt_quantity(8)   :=  gt_quantity(8) + material_transaction_rec.transaction_qty;
          ELSIF (    (material_transaction_rec.transaction_qty    > 0)
                 AND (material_transaction_rec.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                 AND (material_transaction_rec.subinventory_type  = cv_subinv_2)
                )
          THEN
            -- 09.営業車より入庫
            gt_quantity(9)   :=  gt_quantity(9) + material_transaction_rec.transaction_qty;
          ELSIF (    (material_transaction_rec.transaction_qty    > 0)
                 AND (material_transaction_rec.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                 AND (material_transaction_rec.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                )
          THEN
            -- 10.入出庫＿その他入庫
            gt_quantity(10)  :=  gt_quantity(10) + material_transaction_rec.transaction_qty;
            --
          END IF;
        WHEN  cv_trans_type_060  THEN
          IF (    (material_transaction_rec.transaction_qty    < 0)
              AND (material_transaction_rec.inventory_type     = cv_subinv_2)
              AND (material_transaction_rec.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
             )
          THEN
            -- 05.倉庫へ返庫
            gt_quantity(5)   :=  gt_quantity(5) + material_transaction_rec.transaction_qty;
          ELSIF (    (material_transaction_rec.transaction_qty    < 0)
                 AND (material_transaction_rec.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                 AND (material_transaction_rec.subinventory_type  = cv_subinv_2)
                )
          THEN
            -- 06.営業車へ出庫
            gt_quantity(6)   :=  gt_quantity(6) + material_transaction_rec.transaction_qty;
          ELSIF (    (material_transaction_rec.transaction_qty    < 0)
                 AND (material_transaction_rec.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                 AND (material_transaction_rec.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                )
          THEN
            -- 12.倉替出庫
            gt_quantity(12)  :=  gt_quantity(12) + material_transaction_rec.transaction_qty;
          ELSIF (    (material_transaction_rec.transaction_qty    > 0)
                 AND (material_transaction_rec.inventory_type     = cv_subinv_2)
                 AND (material_transaction_rec.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                )
          THEN
            -- 08.倉庫より入庫
            gt_quantity(8)   :=  gt_quantity(8) + material_transaction_rec.transaction_qty;
          ELSIF (    (material_transaction_rec.transaction_qty    > 0)
                 AND (material_transaction_rec.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                 AND (material_transaction_rec.subinventory_type  = cv_subinv_2)
                )
          THEN
            -- 09.営業車より入庫
            gt_quantity(9)   :=  gt_quantity(9) + material_transaction_rec.transaction_qty;
          ELSIF (    (material_transaction_rec.transaction_qty    > 0)
                 AND (material_transaction_rec.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                 AND (material_transaction_rec.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                )
          THEN
            -- 11.倉替入庫
            gt_quantity(11)  :=  gt_quantity(11) + material_transaction_rec.transaction_qty;
            --
          END IF;
        WHEN  cv_trans_type_070  THEN   -- 13.商品振替（旧商品）
          gt_quantity(13)  :=  gt_quantity(13) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_080  THEN   -- 14.商品振替（新商品）
          gt_quantity(14)  :=  gt_quantity(14) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_090  THEN   -- 15.見本出庫
          gt_quantity(15)  :=  gt_quantity(15) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_100 THEN   -- 16.見本出庫振戻
          gt_quantity(16)  :=  gt_quantity(16) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_110 THEN   -- 17.顧客見本出庫
          gt_quantity(17)  :=  gt_quantity(17) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_120 THEN   -- 18.顧客見本出庫振戻
          gt_quantity(18)  :=  gt_quantity(18) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_130 THEN   -- 19.顧客協賛見本出庫
          gt_quantity(19)  :=  gt_quantity(19) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_140 THEN   -- 20.顧客協賛見本出庫振戻
          gt_quantity(20)  :=  gt_quantity(20) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_150 THEN
          IF (material_transaction_rec.transaction_qty >= 0) THEN
            -- 21.消化VD補充入庫
            gt_quantity(21)  :=  gt_quantity(21) + material_transaction_rec.transaction_qty;
          ELSIF (material_transaction_rec.transaction_qty < 0) THEN
            -- 22.消化VD補充出庫
            gt_quantity(22)  :=  gt_quantity(22) + material_transaction_rec.transaction_qty;
          END IF;
        WHEN  cv_trans_type_160 THEN
          IF (material_transaction_rec.subinv_class = cv_subinv_class_7)  THEN
            -- 消化VDは対象外
            NULL;
          ELSIF (material_transaction_rec.transaction_qty   >= 0) THEN
            -- 23.基準在庫変更入庫
            gt_quantity(23)  :=  gt_quantity(23) + material_transaction_rec.transaction_qty;
          ELSIF (material_transaction_rec.transaction_qty < 0) THEN
            -- 24.基準在庫変更出庫
            gt_quantity(24)  :=  gt_quantity(24) + material_transaction_rec.transaction_qty;
          END IF;
        WHEN  cv_trans_type_170 THEN   -- 25.工場返品
          gt_quantity(25)  :=  gt_quantity(25) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_180 THEN   -- 26.工場返品振戻
          gt_quantity(26)  :=  gt_quantity(26) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_190 THEN   -- 27.工場倉替
          gt_quantity(27)  :=  gt_quantity(27) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_200 THEN   -- 28.工場倉替振戻
          gt_quantity(28)  :=  gt_quantity(28) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_210 THEN   -- 29.廃却
          gt_quantity(29)  :=  gt_quantity(29) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_220 THEN   -- 30.廃却振戻
          gt_quantity(30)  :=  gt_quantity(30) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_230 THEN   -- 31.工場入庫
          gt_quantity(31)  :=  gt_quantity(31) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_240 THEN   -- 32.工場入庫振戻
          gt_quantity(32)  :=  gt_quantity(32) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_250 THEN   -- 33.顧客広告宣伝費A自社商品
          gt_quantity(33)  :=  gt_quantity(33) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_260 THEN   -- 34.顧客広告宣伝費A自社商品振戻
          gt_quantity(34)  :=  gt_quantity(34) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_270 THEN   -- 35.棚卸減耗増
          gt_quantity(35)  :=  gt_quantity(35) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_280 THEN   -- 36.棚卸減耗減
          gt_quantity(36)  :=  gt_quantity(36) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_290 THEN
          IF (material_transaction_rec.transaction_qty < 0) THEN
            -- 37.保管場所移動＿自拠点出庫
            gt_quantity(37)  :=  gt_quantity(37) + material_transaction_rec.transaction_qty;
          ELSIF (material_transaction_rec.transaction_qty >= 0) THEN
            -- 38.保管場所移動＿自拠点入庫
            gt_quantity(38)  :=  gt_quantity(38) + material_transaction_rec.transaction_qty;
          END IF;
        ELSE  NULL;
      END CASE;
      --
      -- レコード変更チェック用変数保持
      lt_base_code                :=  material_transaction_rec.base_code;
      lt_subinventory_code        :=  material_transaction_rec.subinventory_code;
      lt_inventory_item_id        :=  material_transaction_rec.inventory_item_id;
      lv_transaction_month        :=  material_transaction_rec.transaction_month;
      lt_transaction_date         :=  material_transaction_rec.transaction_date;
      lt_subinventory_type        :=  material_transaction_rec.inventory_type;
      --
      ln_material_flag    :=  1;
      FETCH material_transaction_cur  INTO  material_transaction_rec;
      --
    END LOOP set_material_loop;
    --
    CLOSE material_transaction_cur;
    --
-- == 2009/10/15 V1.11 Added START ===============================================================
    gn_material_flag    :=  ln_material_flag;
-- == 2009/10/15 V1.11 Added START ===============================================================
    IF (ln_today_data = 0) THEN
      -- 資材取引（当日分）データなし
      ov_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_short_name
                       ,iv_name         =>  cv_msg_xxcoi1_10128
                      );
      ov_errbuf   :=  ov_errmsg;
      ov_retcode  :=  cv_status_warn;
      gn_warn_cnt :=  gn_warn_cnt + 1;      -- 警告件数カウント
    END IF;
    --
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END set_mtl_transaction_data2;
--
-- == 2009/08/26 V1.8 Added END   ===============================================================
  /**********************************************************************************
   * Procedure Name   : set_last_daily_data
   * Description      : 前回連携受払データ出力(A-4, A-5)
   ***********************************************************************************/
  PROCEDURE set_last_daily_data(
    ov_errbuf         OUT VARCHAR2,                     -- エラー・メッセージ                  --# 固定 #
    ov_retcode        OUT VARCHAR2,                     -- リターン・コード                    --# 固定 #
    ov_errmsg         OUT VARCHAR2)                     -- ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_last_daily_data'; -- プログラム名
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
    -- *** ローカル変数 ***
-- == 2009/08/31 V1.9 Added START ===============================================================
    lt_standard_cost      xxcoi_inv_reception_daily.standard_cost%TYPE;
    lt_operation_cost     xxcoi_inv_reception_daily.operation_cost%TYPE;
-- == 2009/08/31 V1.9 Added START ===============================================================
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
    CURSOR  daily_data_cur
    IS
      SELECT  xird.base_code                          -- 拠点コード
             ,xird.organization_id                    -- 組織ID
             ,xird.subinventory_code                  -- 保管場所
             ,xird.practice_date                      -- 年月日
             ,xird.inventory_item_id                  -- 品目ID
             ,xird.subinventory_type                  -- 保管場所区分
             ,xird.operation_cost                     -- 営業原価
             ,xird.standard_cost                      -- 標準原価
             ,xird.book_inventory_quantity            -- 帳簿在庫数
      FROM    xxcoi_inv_reception_daily   xird        -- 前回最終処理分の日時受払
      WHERE   xird.organization_id    =   gn_f_organization_id
      AND     xird.practice_date      =   gd_f_last_cooperation_date;
      --
    -- <カーソル名>レコード型
    daily_data_rec    daily_data_cur%ROWTYPE;
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
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
    -- ===============================
    --  当日未取引データ反映
    -- ===============================
    -- 当日未取引で、以前に取引のあったデータを、業務処理日付で日時情報として登録
    <<set_last_data_loop>>
    FOR daily_data_rec  IN  daily_data_cur  LOOP
-- == 2009/08/31 V1.9 Added START ===============================================================
      -- ===================================
      --  2.標準原価取得
      -- ===================================
      xxcoi_common_pkg.get_cmpnt_cost(
        in_item_id      =>  daily_data_rec.inventory_item_id                -- 品目ID
       ,in_org_id       =>  gn_f_organization_id                            -- 組織ID
       ,id_period_date  =>  gd_f_business_date                              -- 対象日
       ,ov_cmpnt_cost   =>  lt_standard_cost                                -- 標準原価
       ,ov_errbuf       =>  lv_errbuf                                       -- エラーメッセージ
       ,ov_retcode      =>  lv_retcode                                      -- リターン・コード
       ,ov_errmsg       =>  lv_errmsg                                       -- ユーザー・エラーメッセージ
      );
      -- 終了パラメータ判定
      IF (lv_retcode = cv_status_error) THEN
        lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_short_name
                        ,iv_name         => cv_msg_xxcoi1_10285
                       );
        lv_errbuf   := lv_errmsg;
        RAISE global_api_expt;
      END IF;
      --
      -- ===================================
      --  2.営業原価取得
      -- ===================================
      xxcoi_common_pkg.get_discrete_cost(
        in_item_id        =>  daily_data_rec.inventory_item_id                -- 品目ID
       ,in_org_id         =>  gn_f_organization_id                            -- 組織ID
       ,id_target_date    =>  gd_f_business_date                              -- 対象日
       ,ov_discrete_cost  =>  lt_operation_cost                               -- 営業原価
       ,ov_errbuf         =>  lv_errbuf                                       -- エラーメッセージ
       ,ov_retcode        =>  lv_retcode                                      -- リターン・コード
       ,ov_errmsg         =>  lv_errmsg                                       -- ユーザー・エラーメッセージ
      );
      -- 終了パラメータ判定
      IF (lv_retcode = cv_status_error) THEN
        lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_short_name
                        ,iv_name         => cv_msg_xxcoi1_10293
                       );
        lv_errbuf   := lv_errmsg;
        RAISE global_api_expt;
      END IF;
-- == 2009/08/31 V1.9 Added END   ===============================================================
--
      INSERT INTO xxcoi_inv_reception_daily(
            base_code                                        -- 01.拠点コード
           ,organization_id                                  -- 02.組織ID
           ,subinventory_code                                -- 03.保管場所
           ,practice_date                                    -- 04.年月日
           ,inventory_item_id                                -- 05.品目ID
           ,subinventory_type                                -- 06.保管場所区分
           ,operation_cost                                   -- 07.営業原価
           ,standard_cost                                    -- 08.標準原価
           ,previous_inventory_quantity                      -- 09.前日在庫数
           ,sales_shipped                                    -- 10.売上出庫
           ,sales_shipped_b                                  -- 11.売上出庫振戻
           ,return_goods                                     -- 12.返品
           ,return_goods_b                                   -- 13.返品振戻
           ,warehouse_ship                                   -- 14.倉庫へ返庫
           ,truck_ship                                       -- 15.営業車へ出庫
           ,others_ship                                      -- 16.入出庫＿その他出庫
           ,warehouse_stock                                  -- 17.倉庫より入庫
           ,truck_stock                                      -- 18.営業車より入庫
           ,others_stock                                     -- 19.入出庫＿その他入庫
           ,change_stock                                     -- 20.倉替入庫
           ,change_ship                                      -- 21.倉替出庫
           ,goods_transfer_old                               -- 22.商品振替（旧商品）
           ,goods_transfer_new                               -- 23.商品振替（新商品）
           ,sample_quantity                                  -- 24.見本出庫
           ,sample_quantity_b                                -- 25.見本出庫振戻
           ,customer_sample_ship                             -- 26.顧客見本出庫
           ,customer_sample_ship_b                           -- 27.顧客見本出庫振戻
           ,customer_support_ss                              -- 28.顧客協賛見本出庫
           ,customer_support_ss_b                            -- 29.顧客協賛見本出庫振戻
           ,vd_supplement_stock                              -- 32.消化VD補充入庫
           ,vd_supplement_ship                               -- 33.消化VD補充出庫
           ,inventory_change_in                              -- 34.基準在庫変更入庫
           ,inventory_change_out                             -- 35.基準在庫変更出庫
           ,factory_return                                   -- 36.工場返品
           ,factory_return_b                                 -- 37.工場返品振戻
           ,factory_change                                   -- 38.工場倉替
           ,factory_change_b                                 -- 39.工場倉替振戻
           ,removed_goods                                    -- 40.廃却
           ,removed_goods_b                                  -- 41.廃却振戻
           ,factory_stock                                    -- 42.工場入庫
           ,factory_stock_b                                  -- 43.工場入庫振戻
           ,ccm_sample_ship                                  -- 30.顧客広告宣伝費A自社商品
           ,ccm_sample_ship_b                                -- 31.顧客広告宣伝費A自社商品振戻
           ,wear_decrease                                    -- 44.棚卸減耗増
           ,wear_increase                                    -- 45.棚卸減耗減
           ,selfbase_ship                                    -- 46.保管場所移動＿自拠点出庫
           ,selfbase_stock                                   -- 47.保管場所移動＿自拠点入庫
           ,book_inventory_quantity                          -- 48.帳簿在庫数
           ,last_update_date                                 -- 49.最終更新日
           ,last_updated_by                                  -- 50.最終更新者
           ,creation_date                                    -- 51.作成日
           ,created_by                                       -- 52.作成者
           ,last_update_login                                -- 53.最終更新ユーザ
           ,request_id                                       -- 54.要求ID
           ,program_application_id                           -- 55.プログラムアプリケーションID
           ,program_id                                       -- 56.プログラムID
           ,program_update_date                              -- 57.プログラム更新日
          )VALUES(
            daily_data_rec.base_code                         -- 01
           ,daily_data_rec.organization_id                   -- 02
           ,daily_data_rec.subinventory_code                 -- 03
           ,gd_f_business_date                               -- 04
           ,daily_data_rec.inventory_item_id                 -- 05
           ,daily_data_rec.subinventory_type                 -- 06
-- == 2009/08/31 V1.9 Modified START ===============================================================
--           ,daily_data_rec.operation_cost
--           ,daily_data_rec.standard_cost
           ,lt_operation_cost                                -- 07
           ,lt_standard_cost                                 -- 08
-- == 2009/08/31 V1.9 Modified END   ===============================================================
           ,daily_data_rec.book_inventory_quantity           -- 09
           ,0                                                -- 10
           ,0                                                -- 11
           ,0                                                -- 12
           ,0                                                -- 13
           ,0                                                -- 14
           ,0                                                -- 15
           ,0                                                -- 16
           ,0                                                -- 17
           ,0                                                -- 18
           ,0                                                -- 19
           ,0                                                -- 20
           ,0                                                -- 21
           ,0                                                -- 22
           ,0                                                -- 23
           ,0                                                -- 24
           ,0                                                -- 25
           ,0                                                -- 26
           ,0                                                -- 27
           ,0                                                -- 28
           ,0                                                -- 29
           ,0                                                -- 32
           ,0                                                -- 33
           ,0                                                -- 34
           ,0                                                -- 35
           ,0                                                -- 36
           ,0                                                -- 37
           ,0                                                -- 38
           ,0                                                -- 39
           ,0                                                -- 40
           ,0                                                -- 41
           ,0                                                -- 42
           ,0                                                -- 43
           ,0                                                -- 30
           ,0                                                -- 31
           ,0                                                -- 44
           ,0                                                -- 45
           ,0                                                -- 46
           ,0                                                -- 47
           ,daily_data_rec.book_inventory_quantity           -- 48
           ,SYSDATE                                          -- 49
           ,cn_last_updated_by                               -- 50
           ,SYSDATE                                          -- 51
           ,cn_created_by                                    -- 52
           ,cn_last_update_login                             -- 53
           ,cn_request_id                                    -- 54
           ,cn_program_application_id                        -- 55
           ,cn_program_id                                    -- 56
           ,SYSDATE                                          -- 57
          );
          --
---- == 2009/08/26 V1.8 Added START ===============================================================
          gn_target_cnt := gn_target_cnt + 1;
---- == 2009/08/26 V1.8 Added END   ===============================================================
    END LOOP set_last_data_loop;
    --
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END set_last_daily_data;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
-- == 2009/08/26 V1.8 Added START ===============================================================
    iv_exec_flag    IN VARCHAR2,    --   起動フラグ
    iv_process_date IN VARCHAR2,    --   対象日付
-- == 2009/08/26 V1.8 Added END   ===============================================================
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
-- == 2009/08/26 V1.8 Added START ===============================================================
    gv_exec_flag        := iv_exec_flag;
-- == 2009/08/26 V1.8 Added END   ===============================================================
    -- ===================================
    --  1.起動パラメータログ出力
    -- ===================================
-- == 2009/08/26 V1.8 Modified START ===============================================================
--    -- コンカレント入力パラメータなしメッセージ
--    gv_out_msg  :=  xxccp_common_pkg.get_msg(
--                      iv_application  =>  cv_short_name
--                     ,iv_name         =>  cv_msg_xxcoi1_00023
--                    );
    -- 起動フラグ：&PROCESS_FLAG
    gv_out_msg  :=  xxccp_common_pkg.get_msg(
                      iv_application  => cv_short_name
                     ,iv_name         => cv_msg_xxcoi1_10365
                     ,iv_token_name1  => cv_token_10365_1
                     ,iv_token_value1 => gv_exec_flag
                    );
-- == 2009/08/26 V1.8 Modified END   ===============================================================
    fnd_file.put_line(which       =>  FND_FILE.OUTPUT
                     ,buff        =>  gv_out_msg
    );
-- == 2009/08/26 V1.8 Added START ===============================================================
    IF (iv_process_date IS NOT NULL) THEN
      -- 対象日付：&DATE
      gv_out_msg  :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_short_name
                       ,iv_name         => cv_msg_xxcoi1_10401
                       ,iv_token_name1  => cv_token_10401_1
                       ,iv_token_value1 => iv_process_date
                      );
      fnd_file.put_line(which       =>  FND_FILE.OUTPUT
                       ,buff        =>  gv_out_msg
      );
    END IF;
-- == 2009/08/26 V1.8 Added END   ===============================================================
    -- 空行出力
    fnd_file.put_line(which       =>  FND_FILE.OUTPUT
                     ,buff        =>  cv_space
    );
    --
    -- ===================================
    --  2.業務処理日付取得
    -- ===================================
-- == 2009/08/26 V1.8 Modified START ===============================================================
    IF (iv_process_date IS NOT NULL) THEN
      IF (TO_DATE(iv_process_date, cv_date_time) >= xxccp_common_pkg2.get_process_date) THEN
        -- 業務日付の取得に失敗しました。
        lv_errbuf   :=  xxccp_common_pkg.get_msg(
                          iv_application  => cv_short_name
                         ,iv_name         => cv_msg_xxcoi1_10400
                        );
        lv_errmsg   :=  lv_errbuf;
        RAISE global_process_expt;
      END IF;
      --
      gd_f_business_date  :=  TO_DATE(iv_process_date, cv_date_time);
    ELSE
      gd_f_business_date  :=  xxccp_common_pkg2.get_process_date;
    END IF;
-- == 2009/08/26 V1.8 Modified END   ===============================================================
    --
    IF (gd_f_business_date IS NULL) THEN
      -- 業務日付の取得に失敗しました。
      lv_errbuf   :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_short_name
                       ,iv_name         => cv_msg_xxcoi1_00011
                      );
      lv_errmsg   :=  lv_errbuf;
      RAISE global_process_expt;
    END IF;
    --
    -- ===================================
    --  3.在庫組織コード取得
    -- ===================================
    gv_f_organization_code  :=  fnd_profile.value(cv_prf_name_orgcd);
    --
    IF (gv_f_organization_code IS NULL) THEN
      -- プロファイル:在庫組織コード( &PRO_TOK )の取得に失敗しました。
      lv_errbuf   :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_short_name
                       ,iv_name         => cv_msg_xxcoi1_00005
                       ,iv_token_name1  => cv_token_00005_1
                       ,iv_token_value1 => cv_prf_name_orgcd
                      );
      lv_errmsg   :=  lv_errbuf;
      RAISE global_process_expt;
    END IF;
    --
    -- ===================================
    --  4.在庫組織ID取得
    -- ===================================
    gn_f_organization_id  :=  xxcoi_common_pkg.get_organization_id(gv_f_organization_code);
    --
    IF (gn_f_organization_id IS NULL) THEN
      -- 在庫組織コード( &ORG_CODE_TOK )に対する在庫組織IDの取得に失敗しました。
      lv_errbuf   :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_short_name
                       ,iv_name         => cv_msg_xxcoi1_00006
                       ,iv_token_name1  => cv_token_00006_1
                       ,iv_token_value1 => gv_f_organization_code
                      );
      lv_errmsg   :=  lv_errbuf;
      RAISE global_process_expt;
    END IF;
    --
    -- ===================================
    --  5.WHOカラム取得
    -- ===================================
    -- グローバル固定値の設定部で取得しています。
    --
    -- ===================================
    --  6-1.前回連携時取引ID取得
    -- ===================================
    BEGIN
      SELECT  xcc.transaction_id                      -- 取引ID
             ,TRUNC(xcc.last_cooperation_date)        -- 最終連携日時
      INTO    gn_f_last_transaction_id                -- 処理済取引ID
             ,gd_f_last_cooperation_date              -- 処理日
      FROM    xxcoi_cooperation_control   xcc         -- データ連携制御テーブル
-- == 2009/08/26 V1.8 Modified START ===============================================================
--      WHERE   xcc.program_short_name  =   cv_pgsname_a09c;
      WHERE   xcc.program_short_name  =   DECODE(gv_exec_flag, cv_0, cv_pgsname_a09c
                                                                   , cv_pgsname_b09c);
-- == 2009/08/26 V1.8 Modified END   ===============================================================
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- 取得できなかった場合は、処理日＝業務処理日付の前日、
        -- 処理済取引IDを０とします。
        gn_f_last_transaction_id    := 0;
        gd_f_last_cooperation_date  := gd_f_business_date - 1;
    END;
    --
    -- ===================================
    --  6-2.処理済み判定
    -- ===================================
    IF (gd_f_last_cooperation_date = gd_f_business_date) THEN
      -- 本日分の処理は既に実施済みです。
      lv_errbuf   :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_short_name
                       ,iv_name         => cv_msg_xxcoi1_10126
                      );
      lv_errmsg   :=  lv_errbuf;
      RAISE global_process_expt;
    END IF;
    --
    -- ===================================
    --  7.資材取引 最大取引ID取得
    -- ===================================
    SELECT  MAX(mmt.transaction_id)
    INTO    gn_f_max_transaction_id
    FROM    mtl_material_transactions   mmt
    WHERE   mmt.organization_id   =   gn_f_organization_id
    AND     mmt.transaction_id   >=   gn_f_last_transaction_id;
    --
    IF (gn_f_max_transaction_id IS NULL) THEN
      -- 最大取引IDの取得に失敗しました。
      lv_errbuf   :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_short_name
                       ,iv_name         => cv_msg_xxcoi1_10127
                      );
      lv_errmsg   :=  lv_errbuf;
      RAISE global_process_expt;
    END IF;
    --
    -- ===================================
    --  8.日次データ最大年月日取得（前月）
    -- ===================================
    SELECT  MAX(xird.practice_date)
    INTO    gd_f_max_practice_date
    FROM    xxcoi_inv_reception_daily   xird
-- == 2009/08/26 V1.8 Modified START ===============================================================
--    WHERE   TO_CHAR(xird.practice_date, cv_month)   =   TO_CHAR(ADD_MONTHS(gd_f_business_date, -1), cv_month);
    WHERE   xird.practice_date  >= TRUNC(LAST_DAY(ADD_MONTHS(gd_f_business_date, -2)) + 1)
    AND     xird.practice_date  <  TRUNC(LAST_DAY(ADD_MONTHS(gd_f_business_date, -1)) + 1)
    ;
-- == 2009/08/26 V1.8 Modified END   ===============================================================
    --
    IF (gd_f_max_practice_date IS NULL) THEN
      gd_f_max_practice_date  :=  LAST_DAY(ADD_MONTHS(gd_f_business_date, -1));
    END IF;
    --
  EXCEPTION
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
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
-- == 2009/08/26 V1.8 Added START ===============================================================
    iv_exec_flag      IN  VARCHAR2,     -- 起動フラグ
    iv_process_date   IN  VARCHAR2,     -- 対象日付
-- == 2009/08/26 V1.8 Added END   ===============================================================
    ov_errbuf         OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
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
    ln_main_end         NUMBER;
    lv_base_code        VARCHAR2(4);
-- == 2009/05/28 V1.4 Added START ===============================================================
    lt_practice_date    xxcoi_inv_reception_sum.practice_date%TYPE;
-- == 2009/05/28 V1.4 Added END   ===============================================================
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
--
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    --  集計項目初期化
    -- ===============================
    FOR i IN  1 .. 38 LOOP
      gt_quantity(i)  :=  0;
    END LOOP;
    --
    -- ===============================
    --  A-1.初期処理
    -- ===============================
    init(
-- == 2009/08/26 V1.8 Added START ===============================================================
      iv_exec_flag    => iv_exec_flag     -- 起動フラグ
     ,iv_process_date => iv_process_date  -- 対象日付
-- == 2009/08/26 V1.8 Added END   ===============================================================
     ,ov_errbuf     =>  lv_errbuf       --   エラー・メッセージ           --# 固定 #
     ,ov_retcode    =>  lv_retcode      --   リターン・コード             --# 固定 #
     ,ov_errmsg     =>  lv_errmsg       --   ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 終了パラメータ判定
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
-- == 2009/08/26 V1.8 Added START ===============================================================
    IF (gv_exec_flag = cv_0) THEN
      --日次起動時のみ実施
-- == 2009/08/26 V1.8 Added END   ===============================================================
      -- ==============================================
      --  A-4, A-5.前回連携受払データ出力
      -- ==============================================
      -- 月次在庫受払（日次）
      set_last_daily_data(
        ov_errbuf     =>  lv_errbuf       --   エラー・メッセージ           --# 固定 #
       ,ov_retcode    =>  lv_retcode      --   リターン・コード             --# 固定 #
       ,ov_errmsg     =>  lv_errmsg       --   ユーザー・エラー・メッセージ --# 固定 #
      );
      -- 終了パラメータ判定
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
      --
-- == 2009/08/26 V1.8 Added START ===============================================================
    END IF;
--
    IF (gv_exec_flag = cv_1) THEN
      --累計起動のみ実施
-- == 2009/08/26 V1.8 Added END   ===============================================================
  -- == 2009/05/28 V1.4 Added START ===============================================================
      -- ==============================================
      --  A-7.前月サマリ情報出力
      -- ==============================================
      BEGIN
        SELECT  MAX(xirs.practice_date)
        INTO    lt_practice_date
        FROM    xxcoi_inv_reception_sum   xirs;
        --
        -- 月初の起動の場合以下を実行
        IF (lt_practice_date = SUBSTRB(TO_CHAR(ADD_MONTHS(gd_f_business_date, -1), cv_date), 1, 6)) THEN
          set_last_daily_sum(
            ov_errbuf     =>  lv_errbuf       --   エラー・メッセージ           --# 固定 #
           ,ov_retcode    =>  lv_retcode      --   リターン・コード             --# 固定 #
           ,ov_errmsg     =>  lv_errmsg       --   ユーザー・エラー・メッセージ --# 固定 #
          );
          -- 終了パラメータ判定
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
  -- == 2009/05/28 V1.4 Added END   ===============================================================
-- == 2009/08/26 V1.8 Added START ===============================================================
    END IF;
-- == 2009/08/26 V1.8 Added END   ===============================================================
--
-- == 2009/08/26 V1.8 Adeed START ===============================================================
    IF (gv_exec_flag = cv_0) THEN
      -- 日次起動の場合
-- == 2009/08/26 V1.8 Adeed END   ===============================================================
      -- ==============================================
      --  A-2, A-3.当日データ月次在庫受払（日次）出力
      -- ==============================================
      set_mtl_transaction_data(
        ov_errbuf     =>  lv_errbuf       --   エラー・メッセージ           --# 固定 #
       ,ov_retcode    =>  lv_retcode      --   リターン・コード             --# 固定 #
       ,ov_errmsg     =>  lv_errmsg       --   ユーザー・エラー・メッセージ --# 固定 #
      );
      -- 終了パラメータ判定
      IF (lv_retcode = cv_status_error) THEN
        -- エラー終了
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_warn) THEN
        -- 警告終了
        ov_errbuf     :=  lv_errbuf;        --  エラー・メッセージ
        ov_retcode    :=  lv_retcode;       --  リターン・コード
        ov_errmsg     :=  lv_errmsg;        --  ユーザー・エラー・メッセージ
      END IF;
-- == 2009/08/26 V1.8 Adeed START ===============================================================
    ELSIF (gv_exec_flag = cv_1) THEN
      -- 累計起動の場合
      -- ==============================================
      --  A-10, A-11.当日データ月次在庫受払（累計）出力
      -- ==============================================
      set_mtl_transaction_data2(
        ov_errbuf     =>  lv_errbuf       --   エラー・メッセージ           --# 固定 #
       ,ov_retcode    =>  lv_retcode      --   リターン・コード             --# 固定 #
       ,ov_errmsg     =>  lv_errmsg       --   ユーザー・エラー・メッセージ --# 固定 #
      );
      -- 終了パラメータ判定
      IF (lv_retcode = cv_status_error) THEN
        -- エラー終了
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_warn) THEN
        -- 警告終了
        ov_errbuf     :=  lv_errbuf;        --  エラー・メッセージ
        ov_retcode    :=  lv_retcode;       --  リターン・コード
        ov_errmsg     :=  lv_errmsg;        --  ユーザー・エラー・メッセージ
      END IF;
    END IF;
-- == 2009/08/26 V1.8 Added END   ===============================================================
    --
-- == 2009/08/26 V1.8 Added START ===============================================================
    IF (gv_exec_flag IN (cv_0, cv_1)) THEN
-- == 2009/08/26 V1.8 Added END   ===============================================================
      -- ==============================================
      --  A-6.最終取引ID更新
      -- ==============================================
      upd_last_transaction_id(
        ov_errbuf     =>  lv_errbuf       --   エラー・メッセージ           --# 固定 #
       ,ov_retcode    =>  lv_retcode      --   リターン・コード             --# 固定 #
       ,ov_errmsg     =>  lv_errmsg       --   ユーザー・エラー・メッセージ --# 固定 #
      );
      -- 終了パラメータ判定
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
-- == 2009/08/26 V1.8 Added START ===============================================================
    END IF;
-- == 2009/08/26 V1.8 Added END   ===============================================================
    --
-- == 2009/05/28 V1.4 Deleted START ===============================================================
-- == 2009/04/06 V1.1 Added START ===============================================================
--    -- ==============================================
--    --  A-7, A-8.累計受払データ出力
--    -- ==============================================
--    set_reception_sum(
--      ov_errbuf     =>  lv_errbuf       --   エラー・メッセージ           --# 固定 #
--     ,ov_retcode    =>  lv_retcode      --   リターン・コード             --# 固定 #
--     ,ov_errmsg     =>  lv_errmsg       --   ユーザー・エラー・メッセージ --# 固定 #
--    );
--    -- 終了パラメータ判定
--    IF (lv_retcode = cv_status_error) THEN
--      RAISE global_process_expt;
--    END IF;
-- == 2009/04/06 V1.1 Added END   ===============================================================
-- == 2009/05/28 V1.4 Deleted END   ===============================================================
    --
-- == 2009/08/26 V1.8 Modified START ===============================================================
--    -- ==============================================
--    --  A-9.終了処理
--    -- ==============================================
--    finalize(
--      ov_errbuf     =>  lv_errbuf       --   エラー・メッセージ           --# 固定 #
--     ,ov_retcode    =>  lv_retcode      --   リターン・コード             --# 固定 #
--     ,ov_errmsg     =>  lv_errmsg       --   ユーザー・エラー・メッセージ --# 固定 #
--    );
--    -- 終了パラメータ判定
--    IF (lv_retcode = cv_status_error) THEN
--      RAISE global_process_expt;
--    END IF;
    -- 対象件数を成功件数へ
    gn_normal_cnt := gn_target_cnt;
-- == 2009/08/26 V1.8 Modified END   ===============================================================
    --
  EXCEPTION
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- 処理件数
      gn_error_cnt  :=  gn_error_cnt + 1;
      gn_normal_cnt :=  0;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- 処理件数
      gn_error_cnt  :=  gn_error_cnt + 1;
      gn_normal_cnt :=  0;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- 処理件数
      gn_error_cnt  :=  gn_error_cnt + 1;
      gn_normal_cnt :=  0;
      --
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
    errbuf              OUT VARCHAR2,       -- エラー・メッセージ  --# 固定 #
    retcode             OUT VARCHAR2,       -- リターン・コード    --# 固定 #
-- == 2009/08/26 V1.8 Added START ===============================================================
    iv_exec_flag        IN  VARCHAR2,       -- 起動フラグ
    iv_process_date     IN  VARCHAR2        -- 対象日付
-- == 2009/08/26 V1.8 Added END   ===============================================================
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
       ov_retcode => lv_retcode
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
-- == 2009/08/26 V1.8 Added START ===============================================================
        iv_exec_flag        =>  iv_exec_flag        -- 起動フラグ
       ,iv_process_date     =>  iv_process_date     -- 対象日付
-- == 2009/08/26 V1.8 Added END   ===============================================================
       ,ov_errbuf           =>  lv_errbuf           -- エラー・メッセージ             --# 固定 #
       ,ov_retcode          =>  lv_retcode          -- リターン・コード               --# 固定 #
       ,ov_errmsg           =>  lv_errmsg           -- ユーザー・エラー・メッセージ   --# 固定 #
    );
--
    IF (lv_retcode <> cv_status_normal) THEN
      --エラー出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
      -- 空行を出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => cv_space
      );
-- == 2009/10/15 V1.11 Modified START ===============================================================
---- == 2009/09/16 V1.10 Added START ===============================================================
--      gn_target_cnt :=  0;
--      gn_normal_cnt :=  0;
---- == 2009/09/16 V1.10 Added END   ===============================================================
      IF (lv_retcode = cv_status_warn AND gn_material_flag = 0) THEN
        gn_target_cnt :=  0;
        gn_normal_cnt :=  0;
      END IF;
-- == 2009/10/15 V1.11 Modified END   ===============================================================
    END IF;
    --
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
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
       which  => FND_FILE.OUTPUT
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
       which  => FND_FILE.OUTPUT
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
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    -- 空行を出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => cv_space
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
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
-- == 2009/10/15 V1.11 Modified START ===============================================================
-- == 2009/09/16 V1.10 Modified START ===============================================================
--    --終了ステータスがエラーの場合はROLLBACKする
--    IF (retcode = cv_status_error) THEN
--      ROLLBACK;
--    END IF;
--    --終了ステータスがエラーの場合はROLLBACKする
--    IF (retcode <> cv_status_normal) THEN
--      ROLLBACK;
--    END IF;
-- == 2009/09/16 V1.10 Modified END   ===============================================================
    -- 終了ステータスがエラーの場合
    -- または、対象の資材取引データが存在しない場合はROLLBACKする
    IF (retcode = cv_status_error OR gn_material_flag = 0)  THEN
      ROLLBACK;
    END IF;
-- == 2009/10/15 V1.11 Modified END   ===============================================================
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
END XXCOI006A09C;
/
