CREATE OR REPLACE PACKAGE BODY XXCOK023A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK023A03C(body)
 * Description      : 運送費予算及び運送費実績を拠点別品目別（単品別）月別にCSVデータ形式で要求出力します。
 * MD.050           : 運送費予算一覧表出力 MD050_COK_023_A03
 * Version          : 2.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  put_base_sum_data     拠点計データ出力処理(A-8)
 *  edit_base_sum_data    拠点計データ編集処理(A-7)
 *  put_line_data         明細データ出力処理(A-6)
 *  edit_line_data        明細データ編集処理(A-5)
 *  put_head_data         ヘッダ出力処理(A-4)
 *  get_line_data         明細データ取得処理(A-3)
 *  get_base_data         拠点抽出処理(A-2)
 *  init                  初期処理(A-1)
 *  submain               メイン処理プロシージャ
 *  main                  コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/10    1.0   SCS T.Taniguchi  新規作成
 *  2009/02/06    1.1   SCS T.Taniguchi  [障害COK_017] クイックコードビューの有効日・無効日の判定追加
 *  2009/03/02    1.2   SCS T.Taniguchi  [障害COK_069] 入力パラメータ「職責タイプ」により、拠点の取得範囲を制御
 *  2009/05/15    1.3   SCS A.Yano       [障害T1_1001] 出力される金額単位を千円に修正
 *  2009/09/03    1.4   SCS S.Moriyama   [障害0001257] OPM品目マスタ取得条件追加
 *  2009/10/02    1.5   SCS S.Moriyama   [障害E_T3_00630] VDBM残高一覧表が出力されない（同類不具合調査）
 *  2009/12/07    1.6   SCS K.Nakamura   [障害E_本稼動_00022] PT対応（品目カテゴリから政策群コードを取得）
 *  2010/01/29    2.0   SCS K.Kiriu      [障害E_本稼動_01218] 予算のない実績を出力するように修正(作り変え)
 *
 *****************************************************************************************/
--
  -- ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
  -- WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(1) := '.';
-- グローバル変数
  gv_out_msg              VARCHAR2(2000) DEFAULT NULL;
  gn_target_cnt           NUMBER DEFAULT 0;       -- 対象件数
  gn_normal_cnt           NUMBER DEFAULT 0;       -- 正常件数
  gn_error_cnt            NUMBER DEFAULT 0;       -- エラー件数
  gn_warn_cnt             NUMBER DEFAULT 0;       -- スキップ件数
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
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
--  <exception_name>          EXCEPTION;     -- <例外のコメント>
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name               CONSTANT VARCHAR2(12) := 'XXCOK023A03C'; -- パッケージ名
  -- application_short_name
  cv_appl_name_xxcok        CONSTANT VARCHAR2(5)  := 'XXCOK';        -- アプリケーションショートネーム(XXCOK)
  cv_appl_name_xxccp        CONSTANT VARCHAR2(5)  := 'XXCCP';        -- アプリケーションショートネーム(XXCCP)
  -- メッセージ
  cv_normal_msg             CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
  cv_warn_msg               CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
  cv_error_msg              CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90006'; -- エラー終了メッセージ
  cv_msg_xxccp1_90000       CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90000'; -- 対象件数出力
  cv_msg_xxccp1_90001       CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90001'; -- 成功件数出力
  cv_msg_xxccp1_90002       CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90002'; -- エラー件数出力
  cv_msg_xxccp1_90003       CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90003'; -- スキップ件数出力
  cv_msg_xxcok1_10184       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10184'; -- 対象データ無し
  cv_msg_xxcok1_00003       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00003'; -- プロファイル取得エラー
  cv_msg_xxcok1_00013       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00013'; -- 在庫組織ID取得エラー
  cv_msg_xxcok1_00052       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00052'; -- 職責ID取得エラー
  cv_msg_xxcok1_10182       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10182'; -- 拠点取得エラー
  cv_msg_xxcok1_10183       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10183'; -- 商品名取得エラー
  cv_msg_xxcok1_00018       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00018'; -- コンカレント入力パラメータ(拠点コード)
  cv_msg_xxcok1_00019       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00019'; -- コンカレント入力パラメータ2(予算年度)
  cv_msg_xxcok1_00012       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00012'; -- 所属拠点エラー
  cv_msg_xxcok1_00015       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00015'; -- クイックコード取得エラー
  cv_msg_xxcok1_00028       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00028'; -- 業務処理日付取得エラー
  -- トークン
  cv_year                   CONSTANT VARCHAR2(4)  := 'YEAR';             -- 予算年度
  cv_resp_name              CONSTANT VARCHAR2(9)  := 'RESP_NAME';        -- 職責名
  cv_profile                CONSTANT VARCHAR2(7)  := 'PROFILE';          -- プロファイル・オプション名
  cv_location_code          CONSTANT VARCHAR2(13) := 'LOCATION_CODE';    -- 拠点コード
  cv_item_code              CONSTANT VARCHAR2(9)  := 'ITEM_CODE';        -- 品目コード
  cv_org_code               CONSTANT VARCHAR2(8)  := 'ORG_CODE';         -- 在庫組織コード
  cv_count                  CONSTANT VARCHAR2(5)  := 'COUNT';            -- 処理件数
  cv_user_id                CONSTANT VARCHAR2(7)  := 'USER_ID';          -- ユーザーID
  cv_token_lookup_value_set CONSTANT VARCHAR2(16) := 'LOOKUP_VALUE_SET'; -- クイックコード
  -- カスタム・プロファイル
  cv_pro_organization_code  CONSTANT VARCHAR2(21)  := 'XXCOK1_ORG_CODE_SALES';    -- 在庫組織コード
  cv_pro_head_office_code   CONSTANT VARCHAR2(20)  := 'XXCOK1_AFF2_DEPT_HON';     -- 本社の部門コード
  cv_pro_policy_group_code  CONSTANT VARCHAR2(24)  := 'XXCOK1_POLICY_GROUP_CODE'; -- 政策群コード
  -- 値セット名
  cv_flex_st_name_dept      CONSTANT VARCHAR2(15)  := 'XX03_DEPARTMENT';          -- 部門
  -- 参照タイプ
  cv_lookup_type_put_val    CONSTANT VARCHAR2(28)  := 'XXCOK1_COST_BUDGET_PUT_VALUE'; -- 運送費予算一覧表見出し
  cv_lookup_type_month_c    CONSTANT VARCHAR2(26)  := 'XXCOK1_DVL_COST_MONTH_CALC';   -- 運送費月別計算用
  -- 参照タイプコード
  cv_lookup_code_month_c    CONSTANT VARCHAR2(1)   := '1';
  -- 言語
  cv_lang                   CONSTANT VARCHAR2(4)   := USERENV('LANG');
  -- 拠点取得用
  cv_cust_cd_base           CONSTANT VARCHAR2(1)   := '1';                  -- 顧客区分('1':拠点)
  cv_put_code_line          CONSTANT VARCHAR2(1)   := '1';                  -- 出力区分('1':明細)
  cv_put_code_sum           CONSTANT VARCHAR2(1)   := '2';                  -- 出力区分('2':拠点計)
  cv_resp_type_0            CONSTANT VARCHAR2(1)   := '0';                  -- 主管部署担当者職責
  cv_resp_type_1            CONSTANT VARCHAR2(1)   := '1';                  -- 本部部門担当者職責
  cv_resp_type_2            CONSTANT VARCHAR2(1)   := '2';                  -- 拠点部門_担当者職責
  cv_resp_name_val          CONSTANT VARCHAR2(100) := fnd_global.resp_name; -- 職責名
  -- 明細データ取得用
  cv_kbn_koguchi            CONSTANT VARCHAR2(1)   := '1';          -- 小口区分('1':小口)
  cv_kbn_syatate            CONSTANT VARCHAR2(1)   := '0';          -- 小口区分('0':車立)
  cv_month01                CONSTANT VARCHAR2(2)   := '01';         -- 1月(実績の年度データ取得用)
  cn_round                  CONSTANT NUMBER        := -3;           -- 金額丸め桁位置
  cn_unit_amt               CONSTANT NUMBER        := 1000;         -- 金額表示単位(1/1000)
  --見出しチェック用
  cn_heading_cnt            CONSTANT NUMBER(2)     := 13;           -- 見出し項目数
  -- その他
  cv_flag_y                 CONSTANT VARCHAR2(1)   := 'Y';          -- フラグ('Y')
  cv_flag_n                 CONSTANT VARCHAR2(1)   := 'N';          -- フラグ('N')
  cn_number_0               CONSTANT NUMBER        := 0;            -- 数値(0)
  cn_number_1               CONSTANT NUMBER        := 1;            -- 数値(1)
  cv_yyyymmdd               CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD'; -- 日付フォーマット
  cv_comma                  CONSTANT VARCHAR2(1)   := ',';          -- カンマ
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_base_code            VARCHAR2(4)  DEFAULT NULL; -- 入力パラメータの拠点コード
  gv_budget_year          VARCHAR2(4)  DEFAULT NULL; -- 入力パラメータの予算年度
  gv_org_code             VARCHAR2(3)  DEFAULT NULL; -- 在庫組織コード
  gv_head_office_code     VARCHAR2(4)  DEFAULT NULL; -- 本社部門コード
  gv_policy_group_code    VARCHAR2(12) DEFAULT NULL; -- 政策群コード
  gn_org_id               NUMBER       DEFAULT NULL; -- 在庫組織ID
  gn_resp_id              NUMBER       DEFAULT NULL; -- ログイン職責ID
  gn_user_id              NUMBER       DEFAULT NULL; -- ログインユーザーID
  gn_put_count            NUMBER       DEFAULT 0;    -- 明細出力カウント
  gd_process_date         DATE         DEFAULT NULL; -- 業務処理日付
  gv_resp_type            VARCHAR2(1)  DEFAULT NULL; -- 職責タイプ
  gv_month_f              VARCHAR2(2)  DEFAULT NULL; -- 期末月(実績の年度データ取得用)
--
  -- ===============================
  -- ユーザー定義カーソル
  -- ===============================
  --明細データカーソル(品目別科目別運送費予算実績)
  CURSOR get_cost_cur(
    iv_base_code IN VARCHAR2 )
  IS
    SELECT cost.item_code                   AS item_code,      -- 品目コード
           item.item_short_name             AS item_name,      -- 品目名称
           cost.line_num                    AS line_num,       -- 明細番号(1:実績(車立) 2:実績(小口) 3:予算)
           SUM(cost.qty_1)                  AS qty_month1,     -- 期首数量
           SUM(cost.amt_1)                  AS amt_month1,     -- 期首金額
           SUM(cost.qty_2)                  AS qty_month2,     -- 2数量
           SUM(cost.amt_2)                  AS amt_month2,     -- 2金額
           SUM(cost.qty_3)                  AS qty_month3,     -- 3数量
           SUM(cost.amt_3)                  AS amt_month3,     -- 3金額
           SUM(cost.qty_4)                  AS qty_month4,     -- 4数量
           SUM(cost.amt_4)                  AS amt_month4,     -- 4金額
           SUM(cost.qty_5)                  AS qty_month5,     -- 5数量
           SUM(cost.amt_5)                  AS amt_month5,     -- 5金額
           SUM(cost.qty_6)                  AS qty_month6,     -- 6数量
           SUM(cost.amt_6)                  AS amt_month6,     -- 6金額
           SUM( cost.qty_1 + cost.qty_2 +
                cost.qty_3 + cost.qty_4 +
                cost.qty_5 + cost.qty_6 )   AS qty_first_half, -- 半期数量
           SUM( cost.amt_1 + cost.amt_2 +
                cost.amt_3 + cost.amt_4 +
                cost.amt_5 + cost.amt_6 )   AS amt_first_half, -- 半期金額
           SUM(cost.qty_7)                  AS qty_month7,     -- 7数量
           SUM(cost.amt_7)                  AS amt_month7,     -- 7金額
           SUM(cost.qty_8)                  AS qty_month8,     -- 8数量
           SUM(cost.amt_8)                  AS amt_month8,     -- 8金額
           SUM(cost.qty_9)                  AS qty_month9,     -- 9数量
           SUM(cost.amt_9)                  AS amt_month9,     -- 9金額
           SUM(cost.qty_10)                 AS qty_month10,    -- 10数量
           SUM(cost.amt_10)                 AS amt_month10,    -- 10金額
           SUM(cost.qty_11)                 AS qty_month11,    -- 11数量
           SUM(cost.amt_11)                 AS amt_month11,    -- 11金額
           SUM(cost.qty_12)                 AS qty_month12,    -- 12数量
           SUM(cost.amt_12)                 AS amt_month12,    -- 12金額
           SUM( cost.qty_1  + cost.qty_2  +
                cost.qty_3  + cost.qty_4  +
                cost.qty_5  + cost.qty_6  +
                cost.qty_7  + cost.qty_8  +
                cost.qty_9  + cost.qty_10 +
                cost.qty_11 + cost.qty_12 )  AS qty_year_sum,  -- 年間計数量
           SUM( cost.amt_1  + cost.amt_2  +
                cost.amt_3  + cost.amt_4  +
                cost.amt_5  + cost.amt_6  +
                cost.amt_7  + cost.amt_8  +
                cost.amt_9  + cost.amt_10 +
                cost.amt_11 + cost.amt_12 )  AS amt_year_sum  -- 年間計金額
    FROM  (
           SELECT /*+
                      LEADING(flv)
                      INDEX(xdccb XXCOK_DLV_COST_CALC_BUDGET_N01)
                  */
                  xdccb.item_code              AS item_code,
                  3                            AS line_num,
                  DECODE( flv.attribute1
                         ,xdccb.target_month, NVL( xdccb.cs_qty, 0 )
                         ,0
                  )                            AS qty_1,
                  ROUND( DECODE( flv.attribute1
                                ,xdccb.target_month, NVL( xdccb.dlv_cost_budget_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_1,
                  DECODE( flv.attribute2
                         ,xdccb.target_month, NVL( xdccb.cs_qty, 0 )
                         ,0
                  )                            AS qty_2,
                  ROUND( DECODE( flv.attribute2
                                ,xdccb.target_month, NVL( xdccb.dlv_cost_budget_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_2,
                  DECODE( flv.attribute3
                         ,xdccb.target_month, NVL( xdccb.cs_qty, 0 )
                         ,0
                  )                            AS qty_3,
                  ROUND( DECODE( flv.attribute3
                                ,xdccb.target_month, NVL( xdccb.dlv_cost_budget_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_3,
                  DECODE( flv.attribute4
                         ,xdccb.target_month, NVL( xdccb.cs_qty, 0 )
                         ,0
                  )                            AS qty_4,
                  ROUND( DECODE( flv.attribute4
                                 ,xdccb.target_month, xdccb.dlv_cost_budget_amt
                                 ,0
                  ), cn_round ) / cn_unit_amt  AS amt_4,
                  DECODE( flv.attribute5
                         ,xdccb.target_month, NVL( xdccb.cs_qty, 0 )
                         ,0
                  )                            AS qty_5,
                  ROUND( DECODE( flv.attribute5
                                ,xdccb.target_month, NVL( xdccb.dlv_cost_budget_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_5,
                  DECODE( flv.attribute6
                         ,xdccb.target_month, NVL( xdccb.cs_qty, 0 )
                         ,0
                  )                            AS qty_6,
                  ROUND( DECODE( flv.attribute6
                                ,xdccb.target_month, NVL( xdccb.dlv_cost_budget_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_6,
                  DECODE( flv.attribute7
                         ,xdccb.target_month, NVL( xdccb.cs_qty, 0 )
                         ,0
                  )                            AS qty_7,
                  ROUND( DECODE( flv.attribute7
                                ,xdccb.target_month, NVL( xdccb.dlv_cost_budget_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_7,
                  DECODE( flv.attribute8
                         ,xdccb.target_month, NVL( xdccb.cs_qty, 0 )
                         ,0
                  )                            AS qty_8,
                  ROUND( DECODE( flv.attribute8
                                ,xdccb.target_month, NVL( xdccb.dlv_cost_budget_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_8,
                  DECODE( flv.attribute9
                         ,xdccb.target_month, xdccb.cs_qty
                         ,0
                  )                            AS qty_9,
                  ROUND( DECODE( flv.attribute9
                                ,xdccb.target_month, NVL( xdccb.dlv_cost_budget_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_9,
                  DECODE( flv.attribute10
                         ,xdccb.target_month, NVL( xdccb.cs_qty, 0 )
                         ,0
                  )                            AS qty_10,
                  ROUND( DECODE( flv.attribute10
                                ,xdccb.target_month, NVL( xdccb.dlv_cost_budget_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_10,
                  DECODE( flv.attribute11
                         ,xdccb.target_month, NVL( xdccb.cs_qty, 0 )
                         ,0
                  )                            AS qty_11,
                  ROUND( DECODE( flv.attribute11
                                ,xdccb.target_month, NVL( xdccb.dlv_cost_budget_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_11,
                  DECODE( flv.attribute12
                         ,xdccb.target_month, NVL( xdccb.cs_qty, 0 )
                         ,0
                  )                            AS qty_12,
                  ROUND( DECODE( flv.attribute12
                                ,xdccb.target_month, xdccb.dlv_cost_budget_amt
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_12
           FROM   xxcok_dlv_cost_calc_budget xdccb,    -- 運送費予算テーブル
                  fnd_lookup_values          flv
           WHERE  xdccb.base_code     = iv_base_code   -- 拠点コード
           AND    xdccb.budget_year   = gv_budget_year -- 入力パラメータの予算年度
           AND    flv.lookup_type     = cv_lookup_type_month_c
           AND    flv.lookup_code     = cv_lookup_code_month_c
           AND    flv.enabled_flag    = cv_flag_y
           AND    flv.language        = cv_lang
           AND    NVL( flv.start_date_active, gd_process_date ) <= gd_process_date  -- 適用開始日
           AND    NVL( flv.end_date_active, gd_process_date )   >= gd_process_date  -- 適用終了日
           UNION ALL
           SELECT /*+
                      LEADING(flv)
                      INDEX(xdcrs1 xxcok_dlv_cost_result_sum_n01)
                  */
                  xdcrs1.item_code             AS item_code,
                  1                            AS line_num,
                  DECODE( flv.attribute1
                         ,xdcrs1.target_month, NVL( xdcrs1.sum_cs_qty, 0 )
                         ,0
                  )                            AS qty_1,
                  ROUND( DECODE( flv.attribute1
                                ,xdcrs1.target_month, NVL( xdcrs1.sum_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_1,
                  DECODE( flv.attribute2
                         ,xdcrs1.target_month, NVL( xdcrs1.sum_cs_qty, 0 )
                         ,0
                  )                            AS qty_2,
                  ROUND( DECODE( flv.attribute2
                                ,xdcrs1.target_month, NVL( xdcrs1.sum_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_2,
                  DECODE( flv.attribute3
                         ,xdcrs1.target_month, NVL( xdcrs1.sum_cs_qty, 0 )
                         ,0
                  )                            AS qty_3,
                  ROUND( DECODE( flv.attribute3
                                ,xdcrs1.target_month, NVL( xdcrs1.sum_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_3,
                  DECODE( flv.attribute4
                         ,xdcrs1.target_month, NVL( xdcrs1.sum_cs_qty, 0 )
                         ,0
                  )                            AS qty_4,
                  ROUND( DECODE( flv.attribute4
                                 ,xdcrs1.target_month, xdcrs1.sum_amt
                                 ,0
                  ), cn_round ) / cn_unit_amt  AS amt_4,
                  DECODE( flv.attribute5
                         ,xdcrs1.target_month, NVL( xdcrs1.sum_cs_qty, 0 )
                         ,0
                  )                            AS qty_5,
                  ROUND( DECODE( flv.attribute5
                                ,xdcrs1.target_month, NVL( xdcrs1.sum_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_5,
                  DECODE( flv.attribute6
                         ,xdcrs1.target_month, NVL( xdcrs1.sum_cs_qty, 0 )
                         ,0
                  )                            AS qty_6,
                  ROUND( DECODE( flv.attribute6
                                ,xdcrs1.target_month, NVL( xdcrs1.sum_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_6,
                  DECODE( flv.attribute7
                         ,xdcrs1.target_month, NVL( xdcrs1.sum_cs_qty, 0 )
                         ,0
                  )                            AS qty_7,
                  ROUND( DECODE( flv.attribute7
                                ,xdcrs1.target_month, NVL( xdcrs1.sum_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_7,
                  DECODE( flv.attribute8
                         ,xdcrs1.target_month, NVL( xdcrs1.sum_cs_qty, 0 )
                         ,0
                  )                            AS qty_8,
                  ROUND( DECODE( flv.attribute8
                                ,xdcrs1.target_month, NVL( xdcrs1.sum_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_8,
                  DECODE( flv.attribute9
                         ,xdcrs1.target_month, xdcrs1.sum_cs_qty
                         ,0
                  )                            AS qty_9,
                  ROUND( DECODE( flv.attribute9
                                ,xdcrs1.target_month, NVL( xdcrs1.sum_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_9,
                  DECODE( flv.attribute10
                         ,xdcrs1.target_month, NVL( xdcrs1.sum_cs_qty, 0 )
                         ,0
                  )                            AS qty_10,
                  ROUND( DECODE( flv.attribute10
                                ,xdcrs1.target_month, NVL( xdcrs1.sum_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_10,
                  DECODE( flv.attribute11
                         ,xdcrs1.target_month, NVL( xdcrs1.sum_cs_qty, 0 )
                         ,0
                  )                            AS qty_11,
                  ROUND( DECODE( flv.attribute11
                                ,xdcrs1.target_month, NVL( xdcrs1.sum_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_11,
                  DECODE( flv.attribute12
                         ,xdcrs1.target_month, NVL( xdcrs1.sum_cs_qty, 0 )
                         ,0
                  )                            AS qty_12,
                  ROUND( DECODE( flv.attribute12
                                ,xdcrs1.target_month, xdcrs1.sum_amt
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_12
           FROM   xxcok_dlv_cost_result_sum  xdcrs1,  -- 運送費実績月別集計テーブル
                  fnd_lookup_values          flv
           WHERE  xdcrs1.base_code          = iv_base_code  -- 拠点コード
           AND    xdcrs1.target_year        = CASE
                                               WHEN xdcrs1.target_month BETWEEN cv_month01 AND gv_month_f THEN
                                                 TO_CHAR( gv_budget_year + 1 )  --翌年
                                               ELSE
                                                 gv_budget_year                 --当年
                                              END           --年度を年に変換して比較
           AND    xdcrs1.small_amt_type     = cv_kbn_syatate  --車立
           AND    flv.lookup_type           = cv_lookup_type_month_c
           AND    flv.lookup_code           = cv_lookup_code_month_c
           AND    flv.enabled_flag          = cv_flag_y
           AND    flv.language              = cv_lang
           AND    NVL( flv.start_date_active, gd_process_date ) <= gd_process_date  -- 適用開始日
           AND    NVL( flv.end_date_active, gd_process_date )   >= gd_process_date  -- 適用終了日
           UNION ALL
           SELECT /*+
                      LEADING(flv)
                      INDEX(xdcrs2 xxcok_dlv_cost_result_sum_n01)
                  */
                  xdcrs2.item_code             AS item_code,
                  2                            AS line_num,
                  DECODE( flv.attribute1
                         ,xdcrs2.target_month, NVL( xdcrs2.sum_cs_qty, 0 )
                         ,0
                  )                            AS qty_1,
                  ROUND( DECODE( flv.attribute1
                                ,xdcrs2.target_month, NVL( xdcrs2.sum_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_1,
                  DECODE( flv.attribute2
                         ,xdcrs2.target_month, NVL( xdcrs2.sum_cs_qty, 0 )
                         ,0
                  )                            AS qty_2,
                  ROUND( DECODE( flv.attribute2
                                ,xdcrs2.target_month, NVL( xdcrs2.sum_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_2,
                  DECODE( flv.attribute3
                         ,xdcrs2.target_month, NVL( xdcrs2.sum_cs_qty, 0 )
                         ,0
                  )                            AS qty_3,
                  ROUND( DECODE( flv.attribute3
                                ,xdcrs2.target_month, NVL( xdcrs2.sum_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_3,
                  DECODE( flv.attribute4
                         ,xdcrs2.target_month, NVL( xdcrs2.sum_cs_qty, 0 )
                         ,0
                  )                            AS qty_4,
                  ROUND( DECODE( flv.attribute4
                                 ,xdcrs2.target_month, xdcrs2.sum_amt
                                 ,0
                  ), cn_round ) / cn_unit_amt  AS amt_4,
                  DECODE( flv.attribute5
                         ,xdcrs2.target_month, NVL( xdcrs2.sum_cs_qty, 0 )
                         ,0
                  )                            AS qty_5,
                  ROUND( DECODE( flv.attribute5
                                ,xdcrs2.target_month, NVL( xdcrs2.sum_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_5,
                  DECODE( flv.attribute6
                         ,xdcrs2.target_month, NVL( xdcrs2.sum_cs_qty, 0 )
                         ,0
                  )                            AS qty_6,
                  ROUND( DECODE( flv.attribute6
                                ,xdcrs2.target_month, NVL( xdcrs2.sum_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_6,
                  DECODE( flv.attribute7
                         ,xdcrs2.target_month, NVL( xdcrs2.sum_cs_qty, 0 )
                         ,0
                  )                            AS qty_7,
                  ROUND( DECODE( flv.attribute7
                                ,xdcrs2.target_month, NVL( xdcrs2.sum_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_7,
                  DECODE( flv.attribute8
                         ,xdcrs2.target_month, NVL( xdcrs2.sum_cs_qty, 0 )
                         ,0
                  )                            AS qty_8,
                  ROUND( DECODE( flv.attribute8
                                ,xdcrs2.target_month, NVL( xdcrs2.sum_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_8,
                  DECODE( flv.attribute9
                         ,xdcrs2.target_month, xdcrs2.sum_cs_qty
                         ,0
                  )                            AS qty_9,
                  ROUND( DECODE( flv.attribute9
                                ,xdcrs2.target_month, NVL( xdcrs2.sum_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_9,
                  DECODE( flv.attribute10
                         ,xdcrs2.target_month, NVL( xdcrs2.sum_cs_qty, 0 )
                         ,0
                  )                            AS qty_10,
                  ROUND( DECODE( flv.attribute10
                                ,xdcrs2.target_month, NVL( xdcrs2.sum_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_10,
                  DECODE( flv.attribute11
                         ,xdcrs2.target_month, NVL( xdcrs2.sum_cs_qty, 0 )
                         ,0
                  )                            AS qty_11,
                  ROUND( DECODE( flv.attribute11
                                ,xdcrs2.target_month, NVL( xdcrs2.sum_amt, 0 )
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_11,
                  DECODE( flv.attribute12
                         ,xdcrs2.target_month, NVL( xdcrs2.sum_cs_qty, 0 )
                         ,0
                  )                            AS qty_12,
                  ROUND( DECODE( flv.attribute12
                                ,xdcrs2.target_month, xdcrs2.sum_amt
                                ,0
                  ), cn_round ) / cn_unit_amt  AS amt_12
           FROM   xxcok_dlv_cost_result_sum  xdcrs2,  -- 運送費実績月別集計テーブル
                  fnd_lookup_values          flv
           WHERE  xdcrs2.base_code          = iv_base_code  -- 拠点コード
           AND    xdcrs2.target_year        = CASE
                                               WHEN xdcrs2.target_month BETWEEN cv_month01 AND gv_month_f THEN
                                                 TO_CHAR( gv_budget_year + 1 )  --翌年
                                               ELSE
                                                 gv_budget_year                 --当年
                                              END          --年度を年に変換して比較
           AND    xdcrs2.small_amt_type     = cv_kbn_koguchi  --小口
           AND    flv.lookup_type           = cv_lookup_type_month_c
           AND    flv.lookup_code           = cv_lookup_code_month_c
           AND    flv.enabled_flag          = cv_flag_y
           AND    flv.language              = cv_lang
           AND    NVL( flv.start_date_active, gd_process_date ) <= gd_process_date  -- 適用開始日
           AND    NVL( flv.end_date_active, gd_process_date )   >= gd_process_date  -- 適用終了日
       ) cost,
       (SELECT /*+
                   USE_NL( msib,iimc,ximb )
                   USE_NL( mic,mcb,mcsb,mcst )
               */
               iimb.item_no,                      -- 品目コード
               ximb.item_short_name,              -- 略称
               SUBSTRB( mcb.segment1,1,3 ) AS policy_group_code -- 政策群コード
        FROM   ic_item_mst_b              iimb,   -- opm品目マスタ
               xxcmn_item_mst_b           ximb,   -- opm品目アドオンマスタ
               mtl_system_items_b         msib,   -- 品目マスタ
               mtl_category_sets_b        mcsb,   -- 品目カテゴリセット
               mtl_category_sets_tl       mcst,   -- 品目カテゴリセット日本語
               mtl_categories_b           mcb ,   -- 品目カテゴリマスタ
               mtl_item_categories        mic     -- 品目カテゴリ割当
        WHERE  ximb.item_id           = iimb.item_id
        AND    iimb.item_no           = msib.segment1
        AND    msib.organization_id   = gn_org_id
        AND    mcst.category_set_id   = mcsb.category_set_id
        AND    mcb.structure_id       = mcsb.structure_id
        AND    mcb.category_id        = mic.category_id
        AND    mcsb.category_set_id   = mic.category_set_id
        AND    mcst.language          = cv_lang
        AND    mcst.category_set_name = gv_policy_group_code
        AND    mcb.segment1           IS NOT NULL
        AND    msib.organization_id   = mic.organization_id
        AND    msib.inventory_item_id = mic.inventory_item_id
        AND    gd_process_date BETWEEN ximb.start_date_active
                                               AND NVL ( ximb.end_date_active , gd_process_date )
        )item
    WHERE cost.item_code   = item.item_no(+)
    GROUP BY
          item.policy_group_code, -- 政策群コード
          cost.item_code,         -- 品目コード
          item.item_short_name,   -- 品目名称
          cost.line_num           -- 明細番号
    ORDER BY
          item.policy_group_code, -- 政策群コード
          cost.item_code,         -- 品目コード
          cost.line_num           -- 明細番号(1:実績(車立) 2:実績(小口) 3:予算)
  ;
  -- 見出し取得カーソル
  CURSOR put_value_cur
  IS
    SELECT flv.attribute1 AS put_val
    FROM   fnd_lookup_values flv
    WHERE  flv.lookup_type                               = cv_lookup_type_put_val
    AND    flv.enabled_flag                              = cv_flag_y
    AND    flv.language                                  = cv_lang
    AND    NVL( flv.start_date_active,gd_process_date ) <= gd_process_date  -- 適用開始日
    AND    NVL( flv.end_date_active,gd_process_date )   >= gd_process_date  -- 適用終了日
    ORDER BY
           TO_NUMBER(flv.lookup_code)
  ;
--
  -- ===============================
  -- レコードタイプの宣言部
  -- ===============================
--
  -- 拠点情報のレコードタイプ
  TYPE base_rec IS RECORD(
    base_code        VARCHAR2(4), -- 拠点コード
    base_name        VARCHAR2(50) -- 拠点名
  );
--
  -- ===============================
  -- テーブルタイプの宣言部
  -- ===============================
--
  -- 見出しのテーブルタイプ
  TYPE put_value_ttype IS TABLE OF put_value_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  -- 拠点情報のテーブルタイプ
  TYPE base_ttype IS TABLE OF base_rec INDEX BY BINARY_INTEGER;
  -- 明細データのテーブルタイプ
  TYPE get_cost_ttype is TABLE OF get_cost_cur%ROWTYPE INDEX BY BINARY_INTEGER;
--
  g_put_value_tab      put_value_ttype;    -- 見出し
  g_base_tab           base_ttype;         -- 拠点情報
  g_cost_line_tab      get_cost_ttype;     -- 明細データ
  g_cost_base_sum_tab  get_cost_ttype;     -- 拠点計データ
  g_cost_dummy_tab     get_cost_ttype;     -- ダミー用
--
  /**********************************************************************************
   * Procedure Name   : put_base_sum_data
   * Description      : 拠点計データ出力処理(A-8)
   ***********************************************************************************/
  PROCEDURE put_base_sum_data(
    ov_errbuf            OUT VARCHAR2,       -- エラー・メッセージ           --# 固定 #
    ov_retcode           OUT VARCHAR2,       -- リターン・コード             --# 固定 #
    ov_errmsg            OUT VARCHAR2)       -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(17) := 'put_base_sum_data'; -- プログラム名
--
    lv_errbuf         VARCHAR2(5000) DEFAULT NULL;  -- エラー・メッセージ
    lv_retcode        VARCHAR2(1)    DEFAULT NULL;  -- リターン・コード
    lv_errmsg         VARCHAR2(5000) DEFAULT NULL;  -- ユーザー・エラー・メッセージ
    -- *** ローカル変数 ***
    lb_retcode        BOOLEAN        DEFAULT TRUE;  -- メッセージ出力関数戻り値
    lv_put_value_amt  VARCHAR2(500);                -- 出力編集用
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    --実績(車立)、実績(小口)、予算、実績計、予-実の5行分ループし出力
    <<put_base_sum_loop>>
    FOR i IN 1 .. g_cost_base_sum_tab.COUNT LOOP
--
      -- 拠点計各行の見出しの編集
      IF ( i = 1 ) THEN
        lv_put_value_amt := g_put_value_tab(9).put_val;   --見出し(車立)
      ELSIF ( i = 2 ) THEN
        lv_put_value_amt := g_put_value_tab(10).put_val;  --見出し(小口)
      ELSIF ( i = 3 ) THEN
        lv_put_value_amt := g_put_value_tab(11).put_val;  --見出し(予算)
      ELSIF ( i = 4 ) THEN
        lv_put_value_amt := g_put_value_tab(12).put_val;  --見出し(実績)
      ELSIF ( i = 5 ) THEN
        lv_put_value_amt := g_put_value_tab(13).put_val;  --見出し(予算-実績)
      END IF;
--
      -- 見出し+金額の編集
      lv_put_value_amt := lv_put_value_amt                               || cv_comma ||  -- 見出し
                          TO_CHAR(g_cost_base_sum_tab(i).amt_month1)     || cv_comma ||  -- 期首金額
                          TO_CHAR(g_cost_base_sum_tab(i).amt_month2)     || cv_comma ||  -- 2
                          TO_CHAR(g_cost_base_sum_tab(i).amt_month3)     || cv_comma ||  -- 3
                          TO_CHAR(g_cost_base_sum_tab(i).amt_month4)     || cv_comma ||  -- 4
                          TO_CHAR(g_cost_base_sum_tab(i).amt_month5)     || cv_comma ||  -- 5
                          TO_CHAR(g_cost_base_sum_tab(i).amt_month6)     || cv_comma ||  -- 6
                          TO_CHAR(g_cost_base_sum_tab(i).amt_first_half) || cv_comma ||  -- 半期金額
                          TO_CHAR(g_cost_base_sum_tab(i).amt_month7)     || cv_comma ||  -- 7
                          TO_CHAR(g_cost_base_sum_tab(i).amt_month8)     || cv_comma ||  -- 8
                          TO_CHAR(g_cost_base_sum_tab(i).amt_month9)     || cv_comma ||  -- 9
                          TO_CHAR(g_cost_base_sum_tab(i).amt_month10)    || cv_comma ||  -- 10
                          TO_CHAR(g_cost_base_sum_tab(i).amt_month11)    || cv_comma ||  -- 11
                          TO_CHAR(g_cost_base_sum_tab(i).amt_month12)    || cv_comma ||  -- 12
                          TO_CHAR(g_cost_base_sum_tab(i).amt_year_sum)                   -- 年間計金額
                          ;
--
      -- 出力
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT,
                      iv_message  => lv_put_value_amt,  -- 出力データ
                      in_new_line => cn_number_0        -- 改行数
                    );
--
    END LOOP put_base_sum_loop;
--
  EXCEPTION
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END put_base_sum_data;
--
  /**********************************************************************************
   * Procedure Name   : edit_base_sum_data
   * Description      : 拠点計データ編集処理(A-7)
   ***********************************************************************************/
  PROCEDURE edit_base_sum_data(
    ov_errbuf            OUT VARCHAR2,       -- エラー・メッセージ           --# 固定 #
    ov_retcode           OUT VARCHAR2,       -- リターン・コード             --# 固定 #
    ov_errmsg            OUT VARCHAR2,       -- ユーザー・エラー・メッセージ --# 固定 #
    iv_process_flag      IN  NUMBER,         -- 処理フラグ(0:初期化 1:明細足しこみ)
    i_cost_base_sum_tab  IN  get_cost_ttype) -- 明細数量・金額
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(18) := 'edit_base_sum_data'; -- プログラム名
--
    lv_errbuf         VARCHAR2(5000) DEFAULT NULL;  -- エラー・メッセージ
    lv_retcode        VARCHAR2(1)    DEFAULT NULL;  -- リターン・コード
    lv_errmsg         VARCHAR2(5000) DEFAULT NULL;  -- ユーザー・エラー・メッセージ
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    -- 初期化の場合
    IF ( iv_process_flag = cn_number_0 ) THEN
--
      -- 実績(車立)、実績(小口)、予算、実績計、予-実の5行分ループ
      <<item_init_loop>>
      FOR i IN 1 .. 5 LOOP
        -- 拠点計用テーブル変数の初期化(パラメータにダミーが設定されている為、金額0となる)
        g_cost_base_sum_tab(i).amt_month1     := i_cost_base_sum_tab(1).amt_month1;
        g_cost_base_sum_tab(i).amt_month2     := i_cost_base_sum_tab(1).amt_month2;
        g_cost_base_sum_tab(i).amt_month3     := i_cost_base_sum_tab(1).amt_month3;
        g_cost_base_sum_tab(i).amt_month4     := i_cost_base_sum_tab(1).amt_month4;
        g_cost_base_sum_tab(i).amt_month5     := i_cost_base_sum_tab(1).amt_month5;
        g_cost_base_sum_tab(i).amt_month6     := i_cost_base_sum_tab(1).amt_month6;
        g_cost_base_sum_tab(i).amt_first_half := i_cost_base_sum_tab(1).amt_first_half;
        g_cost_base_sum_tab(i).amt_month7     := i_cost_base_sum_tab(1).amt_month7;
        g_cost_base_sum_tab(i).amt_month8     := i_cost_base_sum_tab(1).amt_month8;
        g_cost_base_sum_tab(i).amt_month9     := i_cost_base_sum_tab(1).amt_month9;
        g_cost_base_sum_tab(i).amt_month10    := i_cost_base_sum_tab(1).amt_month10;
        g_cost_base_sum_tab(i).amt_month11    := i_cost_base_sum_tab(1).amt_month11;
        g_cost_base_sum_tab(i).amt_month12    := i_cost_base_sum_tab(1).amt_month12;
        g_cost_base_sum_tab(i).amt_year_sum   := i_cost_base_sum_tab(1).amt_year_sum;
      END LOOP item_init_loop;
--
    -- 明細足しこみの場合
    ELSIF ( iv_process_flag = cn_number_1 ) THEN
--
      -- 実績(車立)、実績(小口)、予算、実績計、予-実の5行分ループ
      <<base_sum_loop>>
      FOR i IN 1 .. i_cost_base_sum_tab.COUNT LOOP
        -- 明細行の足しこみ
        g_cost_base_sum_tab(i).amt_month1     := g_cost_base_sum_tab(i).amt_month1     + i_cost_base_sum_tab(i).amt_month1;
        g_cost_base_sum_tab(i).amt_month2     := g_cost_base_sum_tab(i).amt_month2     + i_cost_base_sum_tab(i).amt_month2;
        g_cost_base_sum_tab(i).amt_month3     := g_cost_base_sum_tab(i).amt_month3     + i_cost_base_sum_tab(i).amt_month3;
        g_cost_base_sum_tab(i).amt_month4     := g_cost_base_sum_tab(i).amt_month4     + i_cost_base_sum_tab(i).amt_month4;
        g_cost_base_sum_tab(i).amt_month5     := g_cost_base_sum_tab(i).amt_month5     + i_cost_base_sum_tab(i).amt_month5;
        g_cost_base_sum_tab(i).amt_month6     := g_cost_base_sum_tab(i).amt_month6     + i_cost_base_sum_tab(i).amt_month6;
        g_cost_base_sum_tab(i).amt_first_half := g_cost_base_sum_tab(i).amt_first_half + i_cost_base_sum_tab(i).amt_first_half;
        g_cost_base_sum_tab(i).amt_month7     := g_cost_base_sum_tab(i).amt_month7     + i_cost_base_sum_tab(i).amt_month7;
        g_cost_base_sum_tab(i).amt_month8     := g_cost_base_sum_tab(i).amt_month8     + i_cost_base_sum_tab(i).amt_month8;
        g_cost_base_sum_tab(i).amt_month9     := g_cost_base_sum_tab(i).amt_month9     + i_cost_base_sum_tab(i).amt_month9;
        g_cost_base_sum_tab(i).amt_month10    := g_cost_base_sum_tab(i).amt_month10    + i_cost_base_sum_tab(i).amt_month10;
        g_cost_base_sum_tab(i).amt_month11    := g_cost_base_sum_tab(i).amt_month11    + i_cost_base_sum_tab(i).amt_month11;
        g_cost_base_sum_tab(i).amt_month12    := g_cost_base_sum_tab(i).amt_month12    + i_cost_base_sum_tab(i).amt_month12;
        g_cost_base_sum_tab(i).amt_year_sum   := g_cost_base_sum_tab(i).amt_year_sum   + i_cost_base_sum_tab(i).amt_year_sum;
      END LOOP base_sum_loop;
--
    END IF;
--
  EXCEPTION
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END edit_base_sum_data;
--
  /**********************************************************************************
   * Procedure Name   : put_line_data
   * Description      : 明細データ出力処理(A-6)
   ***********************************************************************************/
  PROCEDURE put_line_data(
    ov_errbuf           OUT   VARCHAR2,       -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT   VARCHAR2,       -- リターン・コード             --# 固定 #
    ov_errmsg           OUT   VARCHAR2,       -- ユーザー・エラー・メッセージ --# 固定 #
    iv_item_code        IN    VARCHAR2,       -- 品目コード
    iv_item_name        IN    VARCHAR2,       -- 品目名称
    i_cost_tab          IN    get_cost_ttype) -- 明細数量・金額データ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(13) := 'put_line_data'; -- プログラム名
--
    lv_errbuf     VARCHAR2(5000) DEFAULT NULL; -- エラー・メッセージ
    lv_retcode    VARCHAR2(1)    DEFAULT NULL; -- リターン・コード
    lv_errmsg     VARCHAR2(5000) DEFAULT NULL; -- ユーザー・エラー・メッセージ
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    lb_retcode        BOOLEAN         DEFAULT TRUE;  -- メッセージ出力関数戻り値
    lv_put_value_qty  VARCHAR2(500);                 -- 数量行の出力
    lv_put_value_amt  VARCHAR2(500);                 -- 金額行の出力
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    -- 明細行4回分ループ
    <<put_line_loop>>
    FOR i IN 1 .. i_cost_tab.COUNT LOOP
--
      -- 各行の見出しの編集
      IF ( i = 1 ) THEN
        -- 実績(車立)の数量行
        lv_put_value_qty := iv_item_code                || cv_comma ||  --品目コード
                            iv_item_name                ||              --品目名称
                            g_put_value_tab(4).put_val                  --見出し(実績(車立))
                            ;
      ELSIF ( i = 2 ) THEN
        -- 実績(小口)の数量行
        lv_put_value_qty := g_put_value_tab(6).put_val;                 --見出し(実績(小口))
      ELSIF ( i = 3 ) THEN
        -- 予算の数量行
        lv_put_value_qty := g_put_value_tab(7).put_val;                 --見出し(予算)
      ELSIF ( i = 4 ) THEN
        -- 実績計数量行
        lv_put_value_qty := g_put_value_tab(8).put_val;                 --見出し(実績計)
      END IF;
--
      -- 見出し+金額の編集(数量行)
      lv_put_value_qty := lv_put_value_qty                      || cv_comma ||  --見出し(編集後)
                          TO_CHAR(i_cost_tab(i).qty_month1)     || cv_comma ||  --期首数量
                          TO_CHAR(i_cost_tab(i).qty_month2)     || cv_comma ||  --2
                          TO_CHAR(i_cost_tab(i).qty_month3)     || cv_comma ||  --3
                          TO_CHAR(i_cost_tab(i).qty_month4)     || cv_comma ||  --4
                          TO_CHAR(i_cost_tab(i).qty_month5)     || cv_comma ||  --5
                          TO_CHAR(i_cost_tab(i).qty_month6)     || cv_comma ||  --6
                          TO_CHAR(i_cost_tab(i).qty_first_half) || cv_comma ||  --半期数量
                          TO_CHAR(i_cost_tab(i).qty_month7)     || cv_comma ||  --7
                          TO_CHAR(i_cost_tab(i).qty_month8)     || cv_comma ||  --8
                          TO_CHAR(i_cost_tab(i).qty_month9)     || cv_comma ||  --9
                          TO_CHAR(i_cost_tab(i).qty_month10)    || cv_comma ||  --10
                          TO_CHAR(i_cost_tab(i).qty_month11)    || cv_comma ||  --11
                          TO_CHAR(i_cost_tab(i).qty_month12)    || cv_comma ||  --12
                          TO_CHAR(i_cost_tab(i).qty_year_sum)                   --年間計
                          ;
      -- 見出し+金額の編集(金額行)
      lv_put_value_amt := g_put_value_tab(5).put_val            || cv_comma ||  --見出し(共通)
                          TO_CHAR(i_cost_tab(i).amt_month1)     || cv_comma ||  --期首数量
                          TO_CHAR(i_cost_tab(i).amt_month2)     || cv_comma ||  --2
                          TO_CHAR(i_cost_tab(i).amt_month3)     || cv_comma ||  --3
                          TO_CHAR(i_cost_tab(i).amt_month4)     || cv_comma ||  --4
                          TO_CHAR(i_cost_tab(i).amt_month5)     || cv_comma ||  --5
                          TO_CHAR(i_cost_tab(i).amt_month6)     || cv_comma ||  --6
                          TO_CHAR(i_cost_tab(i).amt_first_half) || cv_comma ||  --半期数量
                          TO_CHAR(i_cost_tab(i).amt_month7)     || cv_comma ||  --7
                          TO_CHAR(i_cost_tab(i).amt_month8)     || cv_comma ||  --8
                          TO_CHAR(i_cost_tab(i).amt_month9)     || cv_comma ||  --9
                          TO_CHAR(i_cost_tab(i).amt_month10)    || cv_comma ||  --10
                          TO_CHAR(i_cost_tab(i).amt_month11)    || cv_comma ||  --11
                          TO_CHAR(i_cost_tab(i).amt_month12)    || cv_comma ||  --12
                          TO_CHAR(i_cost_tab(i).amt_year_sum)                   --年間計
                          ;
--
      -- 出力(数量行)
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT,
                      iv_message  => lv_put_value_qty,  -- 出力データ
                      in_new_line => cn_number_0        -- 改行数
                    );
      -- 出力(金額行)
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT,
                      iv_message  => lv_put_value_amt,  -- 出力データ
                      in_new_line => cn_number_0        -- 改行数
                    );
--
    END LOOP put_line_loop;
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END put_line_data;
--
  /**********************************************************************************
   * Procedure Name   : edit_line_data
   * Description      : 明細データ編集処理(A-5)
   ***********************************************************************************/
  PROCEDURE edit_line_data(
    ov_errbuf                   OUT VARCHAR2,              -- エラー・メッセージ           --# 固定 #
    ov_retcode                  OUT VARCHAR2,              -- リターン・コード             --# 固定 #
    ov_errmsg                   OUT VARCHAR2,              -- ユーザー・エラー・メッセージ --# 固定 #
    iv_item_code                IN  VARCHAR2 DEFAULT NULL, -- 商品コード
    iv_item_name                IN  VARCHAR2 DEFAULT NULL, -- 商品名(略称)
    i_cost_tab                  IN  get_cost_ttype)
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(14) := 'edit_line_data'; -- プログラム名
--
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;  -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)    DEFAULT NULL;  -- リターン・コード
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;  -- ユーザー・エラー・メッセージ
    -- *** ローカル変数 ***
    lb_retcode      BOOLEAN        DEFAULT TRUE;  -- メッセージ出力関数戻り値
    lv_result_s     VARCHAR2(1)    DEFAULT cv_flag_n;
    lv_result_k     VARCHAR2(1)    DEFAULT cv_flag_n;
    lv_budget       VARCHAR2(1)    DEFAULT cv_flag_n;
    -- *** ローカルテーブル ***
    l_cost_line_tab get_cost_ttype;
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    -- 対象件数カウント(品目単位の為、ここでカウント)
    gn_target_cnt := gn_target_cnt + 1;
--
    -----------------------------
    -- 明細行の編集
    -----------------------------
    -- 品目に実績(車立)、実績(小口)、予算の行が存在するかチェックする
    <<line_check_loop>>
    FOR i IN 1.. i_cost_tab.COUNT LOOP
      -- 実績(車立)行の存在
      IF ( i_cost_tab(i).line_num = 1 ) THEN
        lv_result_s        := cv_flag_y;
        l_cost_line_tab(1) := i_cost_tab(i);
      -- 実績(小口)行の存在
      ELSIF ( i_cost_tab(i).line_num = 2 ) THEN
        lv_result_k        := cv_flag_y;
        l_cost_line_tab(2) := i_cost_tab(i);
      -- 予算行の存在
      ELSIF ( i_cost_tab(i).line_num = 3 ) THEN
        lv_budget          := cv_flag_y;
        l_cost_line_tab(3) := i_cost_tab(i);
      END IF;
    END LOOP line_check_loop;
--
    --各行が存在しない場合、存在しない行にダミー行(全て0の行)を設定する
    IF ( lv_result_s = cv_flag_n ) THEN
      l_cost_line_tab(1) := g_cost_dummy_tab(1);  --実績(車立)行
    END IF;
    IF ( lv_result_k = cv_flag_n ) THEN
      l_cost_line_tab(2) := g_cost_dummy_tab(1);  --実績(小口)行
    END IF;
    IF ( lv_budget   = cv_flag_n ) THEN
      l_cost_line_tab(3) := g_cost_dummy_tab(1);  --予算行
    END IF;
--
    -- 実績計(車立+小口)行の編集
    l_cost_line_tab(4).qty_month1     := l_cost_line_tab(1).qty_month1     + l_cost_line_tab(2).qty_month1;
    l_cost_line_tab(4).amt_month1     := l_cost_line_tab(1).amt_month1     + l_cost_line_tab(2).amt_month1;
    l_cost_line_tab(4).qty_month2     := l_cost_line_tab(1).qty_month2     + l_cost_line_tab(2).qty_month2;
    l_cost_line_tab(4).amt_month2     := l_cost_line_tab(1).amt_month2     + l_cost_line_tab(2).amt_month2;
    l_cost_line_tab(4).qty_month3     := l_cost_line_tab(1).qty_month3     + l_cost_line_tab(2).qty_month3;
    l_cost_line_tab(4).amt_month3     := l_cost_line_tab(1).amt_month3     + l_cost_line_tab(2).amt_month3;
    l_cost_line_tab(4).qty_month4     := l_cost_line_tab(1).qty_month4     + l_cost_line_tab(2).qty_month4;
    l_cost_line_tab(4).amt_month4     := l_cost_line_tab(1).amt_month4     + l_cost_line_tab(2).amt_month4;
    l_cost_line_tab(4).qty_month5     := l_cost_line_tab(1).qty_month5     + l_cost_line_tab(2).qty_month5;
    l_cost_line_tab(4).amt_month5     := l_cost_line_tab(1).amt_month5     + l_cost_line_tab(2).amt_month5;
    l_cost_line_tab(4).qty_month6     := l_cost_line_tab(1).qty_month6     + l_cost_line_tab(2).qty_month6;
    l_cost_line_tab(4).amt_month6     := l_cost_line_tab(1).amt_month6     + l_cost_line_tab(2).amt_month6;
    l_cost_line_tab(4).qty_first_half := l_cost_line_tab(1).qty_first_half + l_cost_line_tab(2).qty_first_half;
    l_cost_line_tab(4).amt_first_half := l_cost_line_tab(1).amt_first_half + l_cost_line_tab(2).amt_first_half;
    l_cost_line_tab(4).qty_month7     := l_cost_line_tab(1).qty_month7     + l_cost_line_tab(2).qty_month7;
    l_cost_line_tab(4).amt_month7     := l_cost_line_tab(1).amt_month7     + l_cost_line_tab(2).amt_month7;
    l_cost_line_tab(4).qty_month8     := l_cost_line_tab(1).qty_month8     + l_cost_line_tab(2).qty_month8;
    l_cost_line_tab(4).amt_month8     := l_cost_line_tab(1).amt_month8     + l_cost_line_tab(2).amt_month8;
    l_cost_line_tab(4).qty_month9     := l_cost_line_tab(1).qty_month9     + l_cost_line_tab(2).qty_month9;
    l_cost_line_tab(4).amt_month9     := l_cost_line_tab(1).amt_month9     + l_cost_line_tab(2).amt_month9;
    l_cost_line_tab(4).qty_month10    := l_cost_line_tab(1).qty_month10    + l_cost_line_tab(2).qty_month10;
    l_cost_line_tab(4).amt_month10    := l_cost_line_tab(1).amt_month10    + l_cost_line_tab(2).amt_month10;
    l_cost_line_tab(4).qty_month11    := l_cost_line_tab(1).qty_month11    + l_cost_line_tab(2).qty_month11;
    l_cost_line_tab(4).amt_month11    := l_cost_line_tab(1).amt_month11    + l_cost_line_tab(2).amt_month11;
    l_cost_line_tab(4).qty_month12    := l_cost_line_tab(1).qty_month12    + l_cost_line_tab(2).qty_month12;
    l_cost_line_tab(4).amt_month12    := l_cost_line_tab(1).amt_month12    + l_cost_line_tab(2).amt_month12;
    l_cost_line_tab(4).qty_year_sum   := l_cost_line_tab(1).qty_year_sum   + l_cost_line_tab(2).qty_year_sum;
    l_cost_line_tab(4).amt_year_sum   := l_cost_line_tab(1).amt_year_sum   + l_cost_line_tab(2).amt_year_sum;
--
    -- ==========================
    -- 明細データ出力処理
    -- ==========================
    put_line_data(
       ov_errbuf    => lv_errbuf
      ,ov_retcode   => lv_retcode
      ,ov_errmsg    => lv_errmsg
      ,iv_item_code => iv_item_code    -- 品目コード
      ,iv_item_name => iv_item_name    -- 品目名称
      ,i_cost_tab   => l_cost_line_tab -- 品目毎の明細数量・金額データ
    );
    -- エラー判定
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 成功件数カウント(品目単位の為、ここでカウント)
    gn_normal_cnt := gn_normal_cnt + cn_number_1;
    -- 明細出力件数の取得(品目単位の為、ここでカウント)
    gn_put_count  := gn_put_count + cn_number_1;
--
    -----------------------------
    -- 拠点計の編集
    -----------------------------
    -- 拠点計(予算-実績)行の編集
    l_cost_line_tab(5).amt_month1     := l_cost_line_tab(3).amt_month1     - l_cost_line_tab(4).amt_month1;
    l_cost_line_tab(5).amt_month2     := l_cost_line_tab(3).amt_month2     - l_cost_line_tab(4).amt_month2;
    l_cost_line_tab(5).amt_month3     := l_cost_line_tab(3).amt_month3     - l_cost_line_tab(4).amt_month3;
    l_cost_line_tab(5).amt_month4     := l_cost_line_tab(3).amt_month4     - l_cost_line_tab(4).amt_month4;
    l_cost_line_tab(5).amt_month5     := l_cost_line_tab(3).amt_month5     - l_cost_line_tab(4).amt_month5;
    l_cost_line_tab(5).amt_month6     := l_cost_line_tab(3).amt_month6     - l_cost_line_tab(4).amt_month6;
    l_cost_line_tab(5).amt_first_half := l_cost_line_tab(3).amt_first_half - l_cost_line_tab(4).amt_first_half;
    l_cost_line_tab(5).amt_month7     := l_cost_line_tab(3).amt_month7     - l_cost_line_tab(4).amt_month7;
    l_cost_line_tab(5).amt_month8     := l_cost_line_tab(3).amt_month8     - l_cost_line_tab(4).amt_month8;
    l_cost_line_tab(5).amt_month9     := l_cost_line_tab(3).amt_month9     - l_cost_line_tab(4).amt_month9;
    l_cost_line_tab(5).amt_month10    := l_cost_line_tab(3).amt_month10    - l_cost_line_tab(4).amt_month10;
    l_cost_line_tab(5).amt_month11    := l_cost_line_tab(3).amt_month11    - l_cost_line_tab(4).amt_month11;
    l_cost_line_tab(5).amt_month12    := l_cost_line_tab(3).amt_month12    - l_cost_line_tab(4).amt_month12;
    l_cost_line_tab(5).amt_year_sum   := l_cost_line_tab(3).amt_year_sum   - l_cost_line_tab(4).amt_year_sum;
--
    -- ==========================
    -- 拠点計データ編集処理
    -- ==========================
    edit_base_sum_data(
       ov_errbuf            => lv_errbuf
      ,ov_retcode           => lv_retcode
      ,ov_errmsg            => lv_errmsg
      ,iv_process_flag      => cn_number_1     -- 処理フラグ(1:明細足しこみ)
      ,i_cost_base_sum_tab  => l_cost_line_tab -- 品目毎の明細数量・金額データ
    );
    -- エラー判定
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END edit_line_data;
--
  /**********************************************************************************
   * Procedure Name   : put_head_data
   * Description      : ヘッダデータ出力処理(A-4)
   ***********************************************************************************/
  PROCEDURE put_head_data(
    ov_errbuf     OUT VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2, -- ユーザー・エラー・メッセージ --# 固定 #
    iv_base_code  IN  VARCHAR2, -- 拠点コード
    iv_base_name  IN  VARCHAR2) -- 拠点名
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(13) := 'put_head_data'; -- プログラム名
--
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;  -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)    DEFAULT NULL;  -- リターン・コード
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;  -- ユーザー・エラー・メッセージ
    -- *** ローカル変数 ***
    lb_retcode      BOOLEAN        DEFAULT TRUE;  -- メッセージ出力関数戻り値
    lv_put_value_h  VARCHAR2(500);
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    ------------------------
    -- 拠点行出力
    ------------------------
    -- 拠点データ編集
    lv_put_value_h := g_put_value_tab(1).put_val ||
                      iv_base_code               || cv_comma ||
                      iv_base_name
                      ;
    -- 拠点出力
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which    => FND_FILE.OUTPUT
                    ,iv_message  => lv_put_value_h     -- 出力データ
                    ,in_new_line => cn_number_0        -- 改行数
                  );
    ------------------------
    -- 単位行出力
    ------------------------
    -- 単位行データ編集
    lv_put_value_h := g_put_value_tab(2).put_val;
    -- 単位行出力
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which    => FND_FILE.OUTPUT
                    ,iv_message  => lv_put_value_h     -- 出力データ
                    ,in_new_line => cn_number_0        -- 改行数
                  );
    ------------------------
    -- 項目見出し行出力
    ------------------------
    -- 項目見出し行データ編集
    lv_put_value_h := g_put_value_tab(3).put_val;
    -- 項目見出し行出力
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which    => FND_FILE.OUTPUT
                    ,iv_message  => lv_put_value_h     -- 出力データ
                    ,in_new_line => cn_number_0        -- 改行数
                  );
--
  EXCEPTION
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END put_head_data;
--
  /**********************************************************************************
   * Procedure Name   : get_line_data
   * Description      : 明細データ取得処理(A-3)
   ***********************************************************************************/
  PROCEDURE get_line_data(
    ov_errbuf     OUT  VARCHAR2, -- エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT  VARCHAR2, -- リターン・コード                    --# 固定 #
    ov_errmsg     OUT  VARCHAR2) -- ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(17) := 'get_line_data'; -- プログラム名
--
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL; -- エラー・メッセージ
    lv_retcode VARCHAR2(1)    DEFAULT NULL; -- リターン・コード
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL; -- ユーザー・エラー・メッセージ
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    lb_retcode    BOOLEAN                               DEFAULT TRUE; -- メッセージ出力関数戻り値
    lt_item_code  ic_item_mst_b.item_no%TYPE;                         -- 品目コード保持用
    lt_item_name  xxcmn_item_mst_b.item_short_name%TYPE;              -- 品目名称保持用
    ln_item_cnt   BINARY_INTEGER;                                     -- 明細データ用テーブル(同一品目)添字
--
    -- *** ローカルテーブル ***
    l_cost_l_item_tab  get_cost_ttype;                                -- 明細データ用テーブル(同一品目)
--
    -- *** ローカル例外 ***
    no_data_expt  EXCEPTION;                                          -- 品目名称チェック例外
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    -- 拠点ループ
    <<base_loop>>
    FOR base_cnt IN 1 .. g_base_tab.COUNT LOOP
--
      -- 拠点単位の初期化
      g_cost_base_sum_tab.DELETE;  -- 拠点計用テーブル
      g_cost_line_tab.DELETE;      -- 明細データ用テーブル(拠点単位全件)
      l_cost_l_item_tab.DELETE;    -- 明細データ用テーブル(同一品目)
      ln_item_cnt    := 0;         -- 明細データ用テーブル(同一品目)添字
      lt_item_code   := NULL;      -- 品目コード
      lt_item_name   := NULL;      -- 品目名称
      -- ===========================
      -- 拠点計用データ編集(初期化)
      -- ===========================
      edit_base_sum_data(
         ov_errbuf            => lv_errbuf
        ,ov_retcode           => lv_retcode
        ,ov_errmsg            => lv_errmsg
        ,iv_process_flag      => cn_number_0      -- 処理フラグ(0:初期化)
        ,i_cost_base_sum_tab  => g_cost_dummy_tab -- ダミー(全て0)のデータ
      );
      -- エラー判定
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- 明細データ取得
      OPEN get_cost_cur( g_base_tab(base_cnt).base_code );
      FETCH get_cost_cur BULK COLLECT INTO g_cost_line_tab;
      CLOSE get_cost_cur;
--
      -- 対象拠点に明細データがある場合のみ以下の処理
      IF ( g_cost_line_tab.COUNT > 0 ) THEN
--
        -- =======================
        -- ヘッダ出力処理
        -- =======================
        put_head_data(
           ov_errbuf     => lv_errbuf
          ,ov_retcode    => lv_retcode
          ,ov_errmsg     => lv_errmsg
          ,iv_base_code  => g_base_tab(base_cnt).base_code
          ,iv_base_name  => g_base_tab(base_cnt).base_name
        );
        -- エラー判定
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        --明細データループ
        <<line_loop>>
        FOR line_cnt IN 1 .. g_cost_line_tab.COUNT LOOP
--
          -- 品目名称のチェック
          IF ( g_cost_line_tab(line_cnt).item_name IS NULL ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcok,
                       iv_name         => cv_msg_xxcok1_10183,
                       iv_token_name1  => cv_item_code,
                       iv_token_value1 => g_cost_line_tab(line_cnt).item_code
                     );
            lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG
                      , iv_message  => lv_errmsg
                      , in_new_line => cn_number_0
                     );
            RAISE no_data_expt;
          END IF;
--
          -- 最初の1行目
          IF ( lt_item_code IS NULL ) THEN
            -- ブレーク時の保持変数設定
            lt_item_code                   := g_cost_line_tab(line_cnt).item_code;
            lt_item_name                   := g_cost_line_tab(line_cnt).item_name;
            ln_item_cnt                    := 1;
            l_cost_l_item_tab(ln_item_cnt) := g_cost_line_tab(line_cnt);
          -- 品目ブレーク(1品目につき実績(車立)、実績(小口)、予算の最大3レコードとなる)
          ELSIF ( g_cost_line_tab(line_cnt).item_code <> lt_item_code ) THEN
            -- =======================
            -- 明細データ編集(品目毎)
            -- =======================
            edit_line_data(
               ov_errbuf     => lv_errbuf
              ,ov_retcode    => lv_retcode
              ,ov_errmsg     => lv_errmsg
              ,iv_item_code  => lt_item_code
              ,iv_item_name  => lt_item_name
              ,i_cost_tab    => l_cost_l_item_tab
            );
            -- エラー判定
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            END IF;
            -- 品目単位テーブルの初期化
            l_cost_l_item_tab.DELETE;
            -- ブレーク時の保持
            lt_item_code                   := g_cost_line_tab(line_cnt).item_code;
            lt_item_name                   := g_cost_line_tab(line_cnt).item_name;
            ln_item_cnt                    := 1;
            l_cost_l_item_tab(ln_item_cnt) := g_cost_line_tab(line_cnt);
          -- 同一品目のデータ
          ELSE
            -- 配列にデータを保持
            ln_item_cnt                    := ln_item_cnt + 1;
            l_cost_l_item_tab(ln_item_cnt) := g_cost_line_tab(line_cnt);
          END IF;
--
        END LOOP line_loop;
--
        -- =======================
        -- 明細データ編集(最終行分)
        -- =======================
        edit_line_data(
           ov_errbuf     => lv_errbuf
          ,ov_retcode    => lv_retcode
          ,ov_errmsg     => lv_errmsg
          ,iv_item_code  => lt_item_code
          ,iv_item_name  => lt_item_name
          ,i_cost_tab    => l_cost_l_item_tab
        );
        -- エラー判定
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        -- =======================
        -- 拠点計データ出力処理
        -- =======================
        put_base_sum_data(
            ov_errbuf     => lv_errbuf
           ,ov_retcode    => lv_retcode
           ,ov_errmsg     => lv_errmsg
        );
        -- エラー判定
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
      END IF;
--
    END LOOP base_loop;
--
  EXCEPTION
    -- *** データ取得例外 ***
    WHEN no_data_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( gv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      --カーソルがオープンしている場合はクローズ
      IF ( get_cost_cur%ISOPEN ) THEN
        CLOSE get_cost_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END get_line_data;
--
  /**********************************************************************************
   * Procedure Name   : get_base_data
   * Description      : 拠点抽出処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_base_data(
    ov_errbuf           OUT     VARCHAR2,   -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT     VARCHAR2,   -- リターン・コード             --# 固定 #
    ov_errmsg           OUT     VARCHAR2,   -- ユーザー・エラー・メッセージ --# 固定 #
    o_base_tab          OUT     base_ttype) -- 拠点情報
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(13) := 'get_base_data'; -- プログラム名
--
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL; -- エラー・メッセージ
    lv_retcode VARCHAR2(1)    DEFAULT NULL; -- リターン・コード
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL; -- ユーザー・エラー・メッセージ
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    ln_base_index     NUMBER       DEFAULT 1;    -- 拠点情報用インデックス
    lv_resp_nm        VARCHAR2(40) DEFAULT NULL; -- 職責名
    ln_admin_resp_id  NUMBER       DEFAULT NULL; -- 主管部署担当者
    ln_main_resp_id   NUMBER       DEFAULT NULL; -- 本部部門担当者
    ln_sales_resp_id  NUMBER       DEFAULT NULL; -- 拠点部門担当者
    lv_belong_base_cd VARCHAR2(4)  DEFAULT NULL; -- 所属拠点
    lb_retcode        BOOLEAN      DEFAULT TRUE; -- メッセージ出力関数戻り値
--
    -- *** ローカル・カーソル ***
--
    -- 拠点名カーソル
    CURSOR base_name_cur(
      iv_base_code IN VARCHAR2) -- 拠点コード
    IS
      SELECT account_name AS base_name
      FROM   hz_cust_accounts
      WHERE  account_number      = iv_base_code
      AND    customer_class_code = cv_cust_cd_base -- 拠点
    ;
    -- 拠点名カーソルレコード型
    base_name_rec base_name_cur%ROWTYPE;
    -- 全拠点カーソル
    CURSOR all_base_cur
    IS
      SELECT  ffvnh.child_flex_value_high AS base_code, -- 拠点コード
              hca.account_name            AS base_name  -- 拠点名
      FROM    fnd_flex_value_norm_hierarchy ffvnh,
              fnd_flex_values_vl            ffvv,
              hz_cust_accounts              hca
      WHERE   ffvnh.parent_flex_value IN
          (SELECT  ffvnh.child_flex_value_high
           FROM    fnd_flex_value_norm_hierarchy ffvnh,
                   fnd_flex_values_vl            ffvv
           WHERE   ffvnh.parent_flex_value IN
              (SELECT  ffvnh.child_flex_value_high
               FROM    fnd_flex_value_norm_hierarchy ffvnh,
                       fnd_flex_values_vl            ffvv
               WHERE   ffvnh.parent_flex_value IN
                  (SELECT ffvnh.child_flex_value_high
                   FROM   fnd_flex_value_norm_hierarchy ffvnh,
                          fnd_flex_values_vl            ffvv
                   WHERE  ffvnh.parent_flex_value IN
                      (SELECT  ffvnh.child_flex_value_high
                       FROM    fnd_flex_value_norm_hierarchy ffvnh,
                               fnd_flex_values_vl            ffvv
                       WHERE   ffvnh.parent_flex_value     = gv_head_office_code -- 本社部門コード
                       AND     ffvv.value_category         = cv_flex_st_name_dept
                       AND     ffvnh.child_flex_value_high = ffvv.flex_value
                      )
                   AND    ffvv.value_category         = cv_flex_st_name_dept
                   AND    ffvnh.child_flex_value_high = ffvv.flex_value
                  )
               AND     ffvv.value_category         = cv_flex_st_name_dept
               AND     ffvnh.child_flex_value_high = ffvv.flex_value
              )
           AND     ffvv.value_category         = cv_flex_st_name_dept
           AND     ffvnh.child_flex_value_high = ffvv.flex_value
          )
      AND     ffvv.value_category         = cv_flex_st_name_dept
      AND     ffvnh.child_flex_value_high = ffvv.flex_value
      AND     hca.account_number          = ffvv.flex_value
      AND     hca.customer_class_code     = cv_cust_cd_base -- 拠点
      ORDER BY ffvnh.child_flex_value_high
    ;
    -- 全拠点カーソルレコード型
    all_base_rec all_base_cur%ROWTYPE;
    -- 配下拠点カーソル
    CURSOR child_base_cur(
      iv_base_code IN VARCHAR2) -- 拠点コード
    IS
      SELECT  ffvnh.child_flex_value_high AS base_code, -- 拠点コード
              hca.account_name            AS base_name  -- 拠点名
      FROM    fnd_flex_value_norm_hierarchy ffvnh,
              fnd_flex_values_vl ffvv,
              hz_cust_accounts hca
      WHERE   ffvnh.parent_flex_value = (SELECT ffvnh.parent_flex_value
                                         FROM   fnd_flex_value_sets ffvs,
                                                fnd_flex_value_norm_hierarchy ffvnh
                                         WHERE  ffvs.flex_value_set_name    = cv_flex_st_name_dept
                                         AND    ffvs.flex_value_set_id      = ffvnh.flex_value_set_id
                                         AND    ffvnh.child_flex_value_high = iv_base_code -- 所属拠点コード
                                        )
      AND     ffvv.value_category         = cv_flex_st_name_dept
      AND     ffvnh.child_flex_value_high = ffvv.flex_value
      AND     hca.account_number          = ffvv.flex_value
      AND     hca.customer_class_code     = cv_cust_cd_base -- 拠点
      ORDER BY ffvnh.child_flex_value_high
    ;
    -- 配下拠点カーソルレコード型
    child_base_rec child_base_cur%ROWTYPE;
--
    -- *** ローカル・例外 ***
    no_resp_id_expt   EXCEPTION;
    no_resp_data_expt EXCEPTION;
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    -- ===============================
    -- 拠点情報の取得
    -- ===============================
    -- 入力パラメータの拠点情報を取得
    IF (gv_base_code IS NOT NULL) THEN
      <<base_name_loop>>
      FOR base_name_rec IN base_name_cur( gv_base_code ) LOOP
        o_base_tab(ln_base_index).base_code := gv_base_code;            -- 拠点コード
        o_base_tab(ln_base_index).base_name := base_name_rec.base_name; -- 拠点名
      END LOOP base_name_loop;
      -- 拠点情報が取得できなかった場合
      IF ( o_base_tab(1).base_name IS NULL ) THEN
        -- エラー処理
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcok,
                       iv_name         => cv_msg_xxcok1_10182,
                       iv_token_name1  => cv_resp_name,
                       iv_token_value1 => cv_resp_name_val,
                       iv_token_name2  => cv_location_code,
                       iv_token_value2 => gv_base_code
                     );
        lv_errbuf := lv_errmsg;
--
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG
                      , iv_message  => lv_errmsg
                      , in_new_line => cn_number_0
                      );
        RAISE no_resp_data_expt;
      END IF;
    -- 職責別に拠点を取得
    ELSE
      -- ===============================
      -- 職責別の拠点取得処理
      -- ===============================
      ----------------------------
      -- 主管部署担当者職責の場合
      ----------------------------
      IF ( gv_resp_type = cv_resp_type_0 ) THEN
        -- 全拠点コードと拠点名を取得
        <<all_base_loop>>
        FOR all_base_rec IN all_base_cur LOOP
          o_base_tab(ln_base_index).base_code := all_base_rec.base_code; -- 拠点コード
          o_base_tab(ln_base_index).base_name := all_base_rec.base_name; -- 拠点名
          ln_base_index := ln_base_index + 1;
        END LOOP all_base_loop;
      ----------------------------
      -- 本部部門担当者職責の場合
      ----------------------------
      ELSE
        -- 所属拠点取得
        lv_belong_base_cd := xxcok_common_pkg.get_base_code_f( gd_process_date, cn_created_by );
        IF ( lv_belong_base_cd IS NULL ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcok,
                         iv_name         => cv_msg_xxcok1_00012,
                         iv_token_name1  => cv_user_id,
                         iv_token_value1 => cn_created_by
                       );
--
            lb_retcode := xxcok_common_pkg.put_message_f(
                            in_which    => FND_FILE.LOG
                          , iv_message  => lv_errmsg
                          , in_new_line => cn_number_0
                          );
            RAISE no_resp_data_expt;
        END IF;
--
        IF ( gv_resp_type = cv_resp_type_1 ) THEN
          -- ログインユーザーの自拠点より配下の拠点を取得
          <<child_base_loop>>
          FOR child_base_rec IN child_base_cur( lv_belong_base_cd ) LOOP
            o_base_tab(ln_base_index).base_code := child_base_rec.base_code; -- 拠点コード
            o_base_tab(ln_base_index).base_name := child_base_rec.base_name; -- 拠点名
            ln_base_index := ln_base_index + 1;
          END LOOP child_base_loop;
        ----------------------------
        -- 拠点部門_担当者職責の場合
        ----------------------------
        ELSE
          -- 自拠点を取得
          o_base_tab(ln_base_index).base_code   := lv_belong_base_cd;        -- 拠点コード
          <<resp_loop>>
          FOR base_name_rec IN base_name_cur( lv_belong_base_cd ) LOOP
            o_base_tab(ln_base_index).base_name := base_name_rec.base_name;  -- 拠点名
          END LOOP resp_loop;
        END IF;
      END IF;
    END IF;
--
  EXCEPTION
    --*** 職責ID取得エラー ***
    WHEN no_resp_id_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok,
                      iv_name         => cv_msg_xxcok1_00052,
                      iv_token_name1  => cv_resp_name,
                      iv_token_value1 => lv_resp_nm
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( gv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 拠点取得例外 ***
    WHEN no_resp_data_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( gv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END get_base_data;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf       OUT VARCHAR2,              -- エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,              -- リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2,              -- ユーザー・エラー・メッセージ --# 固定 #
    iv_base_code    IN  VARCHAR2 DEFAULT NULL, -- 拠点コード
    iv_budget_year  IN  VARCHAR2 DEFAULT NULL, -- 予算年度
    iv_resp_type    IN  VARCHAR2 DEFAULT NULL  -- 職責タイプ
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(4) := 'init'; -- プログラム名
--
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL; -- エラー・メッセージ
    lv_retcode  VARCHAR2(1)    DEFAULT NULL; -- リターン・コード
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL; -- ユーザー・エラー・メッセージ
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    lv_profile_nm   VARCHAR2(30) DEFAULT NULL; -- プロファイル名称の格納用
    lb_retcode      BOOLEAN;
--
    -- *** ローカル・例外 ***
    no_profile_expt EXCEPTION; -- プロファイル値取得エラー
    no_org_id_expt  EXCEPTION; -- 在庫組織ID取得エラー
    no_process_date EXCEPTION; -- 業務日付取得エラー
    no_data_expt    EXCEPTION; -- データ取得エラー
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================
    -- 入力パラメータの退避
    -- ===============================
    gv_base_code   := iv_base_code;   -- 拠点コード
    gv_budget_year := iv_budget_year; -- 予算年度
    gv_resp_type   := iv_resp_type;   -- 職責タイプ
--
    -- ===============================
    -- 入力パラメータの出力
    -- ===============================
    -- コンカレント入力パラメータメッセージ出力(1:拠点コード)
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_name_xxcok,
                    iv_name         => cv_msg_xxcok1_00018,
                    iv_token_name1  => cv_location_code,
                    iv_token_value1 => gv_base_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG,   -- LOG
                    iv_message  => gv_out_msg,     -- メッセージ
                    in_new_line => cn_number_0     -- 改行数
                  );
    -- コンカレント入力パラメータメッセージ出力(2:予算年度)
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_name_xxcok,
                    iv_name         => cv_msg_xxcok1_00019,
                    iv_token_name1  => cv_year,
                    iv_token_value1 => gv_budget_year
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG,   -- LOG
                    iv_message  => gv_out_msg,     -- メッセージ
                    in_new_line => cn_number_1     -- 改行数
                  );
    -- ===============================
    -- プロファイル値取得
    -- ===============================
    -- カスタム・プロファイルの在庫組織コードを取得します。
    gv_org_code := fnd_profile.value(cv_pro_organization_code);
    IF ( gv_org_code IS NULL ) THEN
      lv_profile_nm := cv_pro_organization_code;
      RAISE no_profile_expt;
    END IF;
    -- カスタム・プロファイルの本社の部門コードを取得します。
    gv_head_office_code := fnd_profile.value(cv_pro_head_office_code);
    IF ( gv_head_office_code IS NULL ) THEN
      lv_profile_nm := cv_pro_head_office_code;
      RAISE no_profile_expt;
    END IF;
    -- カスタム・プロファイルの政策群コードを取得します。
    gv_policy_group_code := fnd_profile.value(cv_pro_policy_group_code);
    IF ( gv_policy_group_code IS NULL ) THEN
      lv_profile_nm := cv_pro_policy_group_code;
      RAISE no_profile_expt;
    END IF;
    -- ===============================
    -- 在庫組織IDの取得
    -- ===============================
    gn_org_id := xxcoi_common_pkg.get_organization_id(gv_org_code);
    IF ( gn_org_id IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok
                    , iv_name         => cv_msg_xxcok1_00013
                    , iv_token_name1  => cv_org_code
                    , iv_token_value1 => gv_org_code
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
      RAISE no_org_id_expt;
    END IF;
    -- ===============================
    -- ログイン時の情報取得
    -- ===============================
    gn_resp_id := fnd_global.resp_id; -- 職責ID
    gn_user_id := fnd_global.user_id; -- ユーザーID
    -- =============================================
    -- 業務処理日付取得
    -- =============================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF( gd_process_date IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok
                    , iv_name         => cv_msg_xxcok1_00028
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
      RAISE no_process_date;
    END IF;
    -- =============================================
    -- 項目見出しの取得
    -- =============================================
    OPEN  put_value_cur;
    FETCH put_value_cur BULK COLLECT INTO g_put_value_tab;
    CLOSE put_value_cur;
    -- 対象件数チェック
    IF ( g_put_value_tab.COUNT <> cn_heading_cnt ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcok,
                     iv_name         => cv_msg_xxcok1_00015,
                     iv_token_name1  => cv_token_lookup_value_set,
                     iv_token_value1 => cv_lookup_type_put_val
                   );
      RAISE no_data_expt;
    END IF;
    -- =============================================
    -- 期末月の取得
    -- =============================================
    BEGIN
      SELECT flv.attribute12
      INTO   gv_month_f
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_type           = cv_lookup_type_month_c
      AND    flv.lookup_code           = cv_lookup_code_month_c
      AND    flv.enabled_flag          = cv_flag_y
      AND    flv.language              = cv_lang
      AND    NVL( flv.start_date_active, gd_process_date ) <= gd_process_date  -- 適用開始日
      AND    NVL( flv.end_date_active, gd_process_date )   >= gd_process_date  -- 適用終了日
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcok,
                       iv_name         => cv_msg_xxcok1_00015,
                       iv_token_name1  => cv_token_lookup_value_set,
                       iv_token_value1 => cv_lookup_type_month_c
                     );
        RAISE no_data_expt;
    END;
    --NULLチェック
    IF ( gv_month_f IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcok,
                     iv_name         => cv_msg_xxcok1_00015,
                     iv_token_name1  => cv_token_lookup_value_set,
                     iv_token_value1 => cv_lookup_type_month_c
                   );
      RAISE no_data_expt;
    END IF;
    -- =============================================
    -- ダミー行(金額・数量全て0)の編集
    -- =============================================
    g_cost_dummy_tab(1).qty_month1     := 0;
    g_cost_dummy_tab(1).amt_month1     := 0;
    g_cost_dummy_tab(1).qty_month2     := 0;
    g_cost_dummy_tab(1).amt_month2     := 0;
    g_cost_dummy_tab(1).qty_month3     := 0;
    g_cost_dummy_tab(1).amt_month3     := 0;
    g_cost_dummy_tab(1).qty_month4     := 0;
    g_cost_dummy_tab(1).amt_month4     := 0;
    g_cost_dummy_tab(1).qty_month5     := 0;
    g_cost_dummy_tab(1).amt_month5     := 0;
    g_cost_dummy_tab(1).qty_month6     := 0;
    g_cost_dummy_tab(1).amt_month6     := 0;
    g_cost_dummy_tab(1).qty_first_half := 0;
    g_cost_dummy_tab(1).amt_first_half := 0;
    g_cost_dummy_tab(1).qty_month7     := 0;
    g_cost_dummy_tab(1).amt_month7     := 0;
    g_cost_dummy_tab(1).qty_month8     := 0;
    g_cost_dummy_tab(1).amt_month8     := 0;
    g_cost_dummy_tab(1).qty_month9     := 0;
    g_cost_dummy_tab(1).amt_month9     := 0;
    g_cost_dummy_tab(1).qty_month10    := 0;
    g_cost_dummy_tab(1).amt_month10    := 0;
    g_cost_dummy_tab(1).qty_month11    := 0;
    g_cost_dummy_tab(1).amt_month11    := 0;
    g_cost_dummy_tab(1).qty_month12    := 0;
    g_cost_dummy_tab(1).amt_month12    := 0;
    g_cost_dummy_tab(1).qty_year_sum   := 0;
    g_cost_dummy_tab(1).amt_year_sum   := 0;
--
  EXCEPTION
    --*** プロファイル値取得エラー ***
    WHEN no_profile_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcok,
                     iv_name         => cv_msg_xxcok1_00003,
                     iv_token_name1  => cv_profile,
                     iv_token_value1 => lv_profile_nm
                   );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
--
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( gv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    --*** 在庫組織ID取得エラー ***
    WHEN no_org_id_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( gv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    --*** 業務日付取得取得エラー ***
    WHEN no_process_date THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( gv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** データ取得例外 ***
    WHEN no_data_expt THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( gv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      --カーソルがOPENの場合はCLOSE
      IF ( put_value_cur%ISOPEN ) THEN
        CLOSE put_value_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf       OUT VARCHAR2,              -- エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,              -- リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2,              -- ユーザー・エラー・メッセージ --# 固定 #
    iv_base_code    IN  VARCHAR2 DEFAULT NULL, -- 拠点コード
    iv_budget_year  IN  VARCHAR2 DEFAULT NULL, -- 予算年度
    iv_resp_type    IN  VARCHAR2 DEFAULT NULL  -- 職責タイプ
    )
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(7) := 'submain'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;  -- エラー・メッセージ
    lv_retcode VARCHAR2(1)    DEFAULT NULL;     -- リターン・コード
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;  -- ユーザー・エラー・メッセージ
--
  BEGIN
--
    ov_retcode := cv_status_normal;
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
      ov_errbuf      => lv_errbuf,      -- エラー・メッセージ
      ov_retcode     => lv_retcode,     -- リターン・コード
      ov_errmsg      => lv_errmsg,      -- ユーザー・エラー・メッセージ
      iv_base_code   => iv_base_code,   -- 拠点コード
      iv_budget_year => iv_budget_year, -- 予算年度
      iv_resp_type   => iv_resp_type    -- 職責タイプ
    );
    -- エラー判定
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- ===============================
    -- 拠点データの取得(A-2)
    -- ===============================
    get_base_data(
      ov_errbuf      => lv_errbuf,     -- エラー・メッセージ
      ov_retcode     => lv_retcode,    -- リターン・コード
      ov_errmsg      => lv_errmsg,     -- ユーザー・エラー・メッセージ
      o_base_tab     => g_base_tab     -- 拠点情報
    );
    -- エラー判定
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- ===============================
    -- 明細データ取得処理(A-3)
    -- ===============================
    get_line_data(
      lv_errbuf,  -- エラー・メッセージ           --# 固定 #
      lv_retcode, -- リターン・コード             --# 固定 #
      lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- エラー判定
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf         OUT VARCHAR2, -- エラー・メッセージ --# 固定 #
    retcode        OUT VARCHAR2, -- リターン・コード   --# 固定 #
    iv_base_code   IN  VARCHAR2, -- 1.拠点コード
    iv_budget_year IN  VARCHAR2, -- 2.予算年度
    iv_resp_type   IN  VARCHAR2  -- 3.職責タイプ
  )
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(4)  := 'main';  -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL; -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)    DEFAULT NULL; -- リターン・コード
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL; -- ユーザー・エラー・メッセージ
    lv_message_code VARCHAR2(16)   DEFAULT NULL; -- メッセージコード
    lb_retcode      BOOLEAN;
--
  BEGIN
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
      ov_retcode => lv_retcode
    , ov_errbuf  => lv_errbuf
    , ov_errmsg  => lv_errmsg
    , iv_which   => 'LOG'-- ログ出力
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- submainの呼び出し
    -- ===============================
    submain(
      ov_errbuf      => lv_errbuf,      -- エラー・メッセージ           --# 固定 #
      ov_retcode     => lv_retcode,     -- リターン・コード             --# 固定 #
      ov_errmsg      => lv_errmsg,      -- ユーザー・エラー・メッセージ --# 固定 #
      iv_base_code   => iv_base_code,   -- 拠点コード
      iv_budget_year => iv_budget_year, -- 予算年度
      iv_resp_type   => iv_resp_type    -- 職責タイプ
    );
    --エラー出力
    IF ( lv_retcode = cv_status_error ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG   -- 出力区分
                    , iv_message  => lv_errmsg      -- メッセージ
                    , in_new_line => cn_number_0    -- 改行
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG   -- 出力区分
                    , iv_message  => lv_errbuf      -- メッセージ
                    , in_new_line => cn_number_1    -- 改行
                    );
      -- 対象件数・成功件数・エラー件数の設定
      gn_error_cnt  := 1;
    END IF;
    -- 明細出力件数が0件の場合
    IF ( gn_put_count = 0 ) AND ( lv_retcode = cv_status_normal ) THEN
      -- 対象データ無しのメッセージ出力
      gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok,
                      iv_name         => cv_msg_xxcok1_10184,
                      iv_token_name1  => cv_year,
                      iv_token_value1 => gv_budget_year
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which    => FND_FILE.LOG,   -- LOG
                     iv_message  => gv_out_msg,     -- メッセージ
                     in_new_line => cn_number_1     -- 改行数
                    );
    END IF;
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_name_xxccp,
                    iv_name         => cv_msg_xxccp1_90000,
                    iv_token_name1  => cv_count,
                    iv_token_value1 => TO_CHAR( gn_target_cnt )
                   );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG,   -- LOG
                    iv_message  => gv_out_msg,     -- メッセージ
                    in_new_line => cn_number_0     -- 改行数
                  );
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_name_xxccp,
                    iv_name         => cv_msg_xxccp1_90001,
                    iv_token_name1  => cv_count,
                    iv_token_value1 => TO_CHAR( gn_normal_cnt )
                   );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG,   -- LOG
                    iv_message  => gv_out_msg,     -- メッセージ
                    in_new_line => cn_number_0     -- 改行数
                  );
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_name_xxccp,
                    iv_name         => cv_msg_xxccp1_90002,
                    iv_token_name1  => cv_count,
                    iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG,   -- LOG
                    iv_message  => gv_out_msg,     -- メッセージ
                    in_new_line => cn_number_1     -- 改行数
                  );
    --終了メッセージ
    IF ( lv_retcode = cv_status_normal )   THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn )  THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_name_xxccp,
                    iv_name         => lv_message_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG,   -- LOG
                    iv_message  => gv_out_msg,     -- メッセージ
                    in_new_line => cn_number_0     -- 改行数
                  );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      errbuf  := SUBSTRB( gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
END XXCOK023A03C;
/
