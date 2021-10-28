CREATE OR REPLACE PACKAGE BODY APPS.XXCOK024A09C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A09C(body)
 * Description      : 控除データリカバリー(販売控除)
 * MD.050           : 控除データリカバリー(販売控除) MD050_COK_024_A09
 * Version          : 1.5
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   A-1.初期処理
 *  get_condition_data     A-2.控除情報更新対象抽出
 *  sales_deduction_delete A-3.販売控除取消処理
 *  get_data               A-4.控除データ抽出
 *  calculation_data       A-5.控除データ算出
 *  insert_data            A-6.販売控除データ登録
 *  condition_update       A-7.控除情報更新
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ(終了処理A-8を含む)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2020/05/13    1.0   H.Ishii          新規作成
 *  2020/12/03    1.1   SCSK Y.Koh       [E_本稼動_16026]
 *  2021/04/06    1.2   SCSK Y.Koh       [E_本稼動_16026]容器区分対応
 *                                       [E_本稼動_16026]定額控除複数明細対応
 *  2021/07/26    1.3   SCSK K.Yoshikawa [E_本稼働_17399]
 *  2021/09/17    1.4   SCSK K.Yoshikawa [E_本稼動_17540]マスタ削除時の支払済控除データの対応
 *  2021/10/21    1.5   SCSK K.Yoshikawa [E_本稼動_17546]控除マスタ削除アップロードの改修
 *
 *****************************************************************************************/
--
--########################  固定グローバル定数宣言部 START  ########################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- 異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;                 -- CREATED_BY
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                 -- LAST_UPDATED_BY
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;         -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;            -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;         -- PROGRAM_ID
  cd_creation_date          CONSTANT DATE        := SYSDATE;                            -- CREATION_DATE
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                            -- LAST_UPDATE_DATE
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                            -- PROGRAM_UPDATE_DATE
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--##################################  固定部 END  ##################################
--
--########################  固定グローバル変数宣言部 START  ########################
--
  gv_out_msg                VARCHAR2(2000);
  gv_sep_msg                VARCHAR2(2000);
  gv_exec_user              VARCHAR2(100);
  gv_conc_name              VARCHAR2(30);
  gv_conc_status            VARCHAR2(30);
  gn_del_target_cnt         NUMBER;                    -- 控除マスタ削除対象件数
  gn_add_target_cnt         NUMBER;                    -- 控除マスタ登録対象件数
  gn_del_cnt                NUMBER;                    -- 控除データ削除件数
  gn_add_cnt                NUMBER;                    -- 控除データ登録件数
  gn_cal_skip_cnt           NUMBER;                    -- 控除データ控除額算出スキップ件数
  gn_del_skip_cnt           NUMBER;                    -- 控除データ削除支払済スキップ件数
-- 2021/09/17 Ver1.4 ADD Start
  gn_del_ins_cnt            NUMBER;                    -- マイナス控除データ登録件数
-- 2021/09/17 Ver1.4 ADD End
  gn_add_skip_cnt           NUMBER;                    -- 控除データ登録支払済スキップ件数
  gn_error_cnt              NUMBER;                    -- エラー件数
--
--##################################  固定部 END  ##################################
--
--###########################  固定共通例外宣言部 START  ###########################
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
--##################################  固定部 END  ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT  VARCHAR2(100) := 'XXCOK024A09C';                   -- パッケージ名
  cv_xxcok_short_name       CONSTANT  VARCHAR2(100) := 'XXCOK';                          -- 販物領域短縮アプリ名
  --メッセージ
  cv_data_get_msg           CONSTANT  VARCHAR2(20)  := 'APP-XXCOK1-00001';               -- 対象データなしエラーメッセージ
  cv_msg_proc_date_err      CONSTANT  VARCHAR2(20)  := 'APP-XXCOK1-00028';               -- 業務日付取得エラーメッセージ
-- 2020/12/03 Ver1.1 ADD Start
  cv_msg_id_error           CONSTANT  VARCHAR2(20)  := 'APP-XXCOK1-10592';               -- 前回処理ID取得エラー
-- 2020/12/03 Ver1.1 ADD End
  cv_msg_cal_error          CONSTANT  VARCHAR2(20)  := 'APP-XXCOK1-10593';               -- 控除額算出エラー
  cv_msg_slip_date_err      CONSTANT  VARCHAR2(20)  := 'APP-XXCOK1-10708';               -- 支払処理対象外メッセージ
-- 2021/09/17 Ver1.4 ADD Start
  cv_msg_slip_date_ins      CONSTANT  VARCHAR2(20)  := 'APP-XXCOK1-10807';               -- 支払処理済マイナス控除データ登録メッセージ
-- 2021/09/17 Ver1.4 ADD End
-- 2021/10/21 Ver1.5 ADD Start
  cv_msg_slip_date_discount CONSTANT  VARCHAR2(20)  := 'APP-XXCOK1-10808';               -- 支払処理対象外メッセージ入金時値引
  cv_msg_slip_date_err_d    CONSTANT  VARCHAR2(20)  := 'APP-XXCOK1-10809';               -- 支払処理対象外メッセージ内訳
  cv_msg_slip_date_ins_d    CONSTANT  VARCHAR2(20)  := 'APP-XXCOK1-10810';               -- 支払処理済マイナス控除データ登録メッセージ内訳
  cv_msg_slip_date_dis_d    CONSTANT  VARCHAR2(20)  := 'APP-XXCOK1-10811';               -- 支払処理対象外メッセージ入金時値引内訳
-- 2021/10/21 Ver1.5 ADD End
  cv_msg_lock_err           CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10632';               -- ロックエラーメッセージ
  --トークン値
  cv_tkn_source_line_id     CONSTANT  VARCHAR2(15)  := 'SOURCE_LINE_ID';                 -- 販売実績明細IDのトークン名
  cv_tkn_item_code          CONSTANT  VARCHAR2(15)  := 'ITEM_CODE';                      -- 品目コードのトークン名
  cv_tkn_sales_uom_code     CONSTANT  VARCHAR2(15)  := 'SALES_UOM_CODE';                 -- 販売単位のトークン名
  cv_tkn_condition_no       CONSTANT  VARCHAR2(15)  := 'CONDITION_NO';                   -- 控除番号のトークン名
  cv_tkn_base_code          CONSTANT  VARCHAR2(15)  := 'BASE_CODE';                      -- 担当拠点のトークン名
  cv_tkn_errmsg             CONSTANT  VARCHAR2(15)  := 'ERRMSG';                         -- エラーメッセージのトークン名
  cv_tkn_recon_slip_num     CONSTANT  VARCHAR2(15)  := 'RECON_SLIP_NUM';                 -- 支払伝票番号のトークン名
-- 2021/09/17 Ver1.4 ADD Start
  cv_tkn_column_value       CONSTANT  VARCHAR2(15)  := 'COLUMN_VALUE';                   -- 控除番号、明細番号のトークン名
  cv_tkn_data_type          CONSTANT  VARCHAR2(15)  := 'DATA_TYPE';                      -- データ種類のトークン名
-- 2021/09/17 Ver1.4 ADD End
-- 2021/10/21 Ver1.5 ADD Start
  cv_tkn_target_date_end    CONSTANT  VARCHAR2(15)  := 'TARGET_DATE_END';                -- 対象期間（TO)のトークン名
  cv_tkn_due_date           CONSTANT  VARCHAR2(15)  := 'DUE_DATE';                       -- 支払予定日のトークン名
  cv_tkn_status             CONSTANT  VARCHAR2(15)  := 'STATUS';                         -- 支払伝票のステータスのトークン名
-- 2021/10/21 Ver1.5 ADD End
  --フラグ・区分定数
  cv_item_category          CONSTANT  VARCHAR2(12)  := '本社商品区分';                   -- 定数：本社商品区分
  cv_dummy_flag             CONSTANT  VARCHAR2(5)   := 'DUMMY';                          -- 定数：DUMMY
  cv_c_flag                 CONSTANT  VARCHAR2(1)   := 'C';                              -- 定数：C
  cv_d_flag                 CONSTANT  VARCHAR2(1)   := 'D';                              -- 定数：D
  cv_f_flag                 CONSTANT  VARCHAR2(1)   := 'F';                              -- 定数：F
  cv_i_flag                 CONSTANT  VARCHAR2(1)   := 'I';                              -- 定数：I
  cv_n_flag                 CONSTANT  VARCHAR2(1)   := 'N';                              -- 定数：N
  cv_r_flag                 CONSTANT  VARCHAR2(1)   := 'R';                              -- 定数：R
  cv_s_flag                 CONSTANT  VARCHAR2(1)   := 'S';                              -- 定数：S
  cv_t_flag                 CONSTANT  VARCHAR2(1)   := 'T';                              -- 定数：T
  cv_y_flag                 CONSTANT  VARCHAR2(1)   := 'Y';                              -- 定数：Y
  cv_u_flag                 CONSTANT  VARCHAR2(1)   := 'U';                              -- 定数：U
  cv_v_flag                 CONSTANT  VARCHAR2(1)   := 'V';                              -- 定数：V
  cv_0                      CONSTANT  VARCHAR2(1)   := '0';                              -- 定数：0
  cv_1                      CONSTANT  VARCHAR2(1)   := '1';                              -- 定数：1
  cn_1                      CONSTANT  NUMBER        := 1;                                -- 定数：1
  cn_2                      CONSTANT  NUMBER        := 2;                                -- 定数：2
  cn_3                      CONSTANT  NUMBER        := 3;                                -- 定数：3
  cn_4                      CONSTANT  NUMBER        := 4;                                -- 定数：4
  cv_deci_flag              CONSTANT  VARCHAR2(1)   := '1';                              -- 確定
-- 2021/09/17 Ver1.4 ADD Start
  cv_030                    CONSTANT  VARCHAR2(3)   := '030';                            -- 問屋未収（定額）
  cv_040                    CONSTANT  VARCHAR2(3)   := '040';                            -- 問屋未収（追加）
-- 2021/09/17 Ver1.4 ADD Start
--
  --クイックコード
  cv_lookup_dedu_code       CONSTANT  VARCHAR2(30)  := 'XXCOK1_DEDUCTION_DATA_TYPE';     -- 控除データ種類
  cv_lookup_chain_code      CONSTANT  VARCHAR2(30)  := 'XXCMM_CHAIN_CODE';               -- チェーンコード
  cv_lookup_gyotai_code     CONSTANT  VARCHAR2(30)  := 'XXCMM_CUST_GYOTAI_SHO';          -- 業態小分類
  cv_lookup_cls_code        CONSTANT  VARCHAR2(30)  := 'XXCOS1_MK_ORG_CLS_MST_013_A01';  -- 作成元区分
  cv_lookup_ded_type_code   CONSTANT  VARCHAR2(30)  := 'XXCOK1_DEDUCTION_TYPE';          -- 控除タイプ
  cv_business_type          CONSTANT  VARCHAR2(20)  := 'XX03_BUSINESS_TYPE';             -- ビジネスタイプ
-- 2021/10/21 Ver1.5 ADD Start
  cv_head_erase_status      CONSTANT  VARCHAR2(30)  := 'XXCOK1_HEAD_ERASE_STATUS';       -- 控除消込ヘッダーステータス
-- 2021/10/21 Ver1.5 ADD End
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  gn_request_id          NUMBER;                                                         -- 入力パラメータ：要求ID
  gn_condition_line_id   NUMBER;                                                         -- 入力パラメータ：控除詳細ID
--
  -- 控除条件ワークテーブル定義
  TYPE gr_condition_work_rec IS RECORD(
    condition_id                xxcok_condition_header.condition_id%TYPE                 -- 控除条件ID
   ,condition_no                xxcok_condition_header.condition_no%TYPE                 -- 控除番号
   ,enabled_flag_h              xxcok_condition_header.enabled_flag_h%TYPE               -- ヘッダ有効フラグ
   ,corp_code                   xxcok_condition_header.corp_code%TYPE                    -- 企業コード
   ,deduction_chain_code        xxcok_condition_header.deduction_chain_code%TYPE         -- 控除用チェーンコード
   ,customer_code               xxcok_condition_header.customer_code%TYPE                -- 顧客コード
   ,data_type                   xxcok_condition_header.data_type%TYPE                    -- データ種類
   ,tax_code                    xxcok_condition_header.tax_code%TYPE                     -- 税コード
   ,tax_rate                    xxcok_condition_header.tax_rate%TYPE                     -- 税コード
   ,start_date_active           xxcok_condition_header.start_date_active%TYPE            -- 開始日
   ,end_date_active             xxcok_condition_header.end_date_active%TYPE              -- 終了日
   ,content                     xxcok_condition_header.content%TYPE                      -- 内容
   ,decision_no                 xxcok_condition_header.decision_no%TYPE                  -- 決裁No
   ,agreement_no                xxcok_condition_header.agreement_no%TYPE                 -- 契約番号
   ,header_recovery_flag        xxcok_condition_header.header_recovery_flag%TYPE         -- リカバリ対象フラグ
   ,condition_line_id           xxcok_condition_lines.condition_line_id%TYPE             -- 控除詳細ID
   ,detail_number               xxcok_condition_lines.detail_number%TYPE                 -- 明細番号
   ,enabled_flag_l              xxcok_condition_lines.enabled_flag_l%TYPE                -- 明細有効フラグ
   ,target_category             xxcok_condition_lines.target_category%TYPE               -- 対象区分
   ,product_class               xxcok_condition_lines.product_class%TYPE                 -- 商品区分
   ,item_code                   xxcok_condition_lines.item_code%TYPE                     -- 品目コード
   ,uom_code                    xxcok_condition_lines.uom_code%TYPE                      -- 単位
   ,line_recovery_flag          xxcok_condition_lines.line_recovery_flag%TYPE            -- リカバリ対象フラグ
   ,shop_pay_1                  xxcok_condition_lines.shop_pay_1%TYPE                    -- 店納(％)
   ,material_rate_1             xxcok_condition_lines.material_rate_1%TYPE               -- 料率(％)
   ,condition_unit_price_en_2   xxcok_condition_lines.condition_unit_price_en_2%TYPE     -- 条件単価２(円)
   ,demand_en_3                 xxcok_condition_lines.demand_en_3%TYPE                   -- 請求(円)
   ,shop_pay_en_3               xxcok_condition_lines.shop_pay_en_3%TYPE                 -- 店納(円)
   ,compensation_en_3           xxcok_condition_lines.compensation_en_3%TYPE             -- 補填(円)
   ,wholesale_margin_en_3       xxcok_condition_lines.wholesale_margin_en_3%TYPE         -- 問屋マージン(円)
   ,wholesale_margin_per_3      xxcok_condition_lines.wholesale_margin_per_3%TYPE        -- 問屋マージン(％)
   ,accrued_en_3                xxcok_condition_lines.accrued_en_3%TYPE                  -- 未収計３(円)
   ,normal_shop_pay_en_4        xxcok_condition_lines.normal_shop_pay_en_4%TYPE          -- 通常店納(円)
   ,just_shop_pay_en_4          xxcok_condition_lines.just_shop_pay_en_4%TYPE            -- 今回店納(円)
   ,just_condition_en_4         xxcok_condition_lines.just_condition_en_4%TYPE           -- 今回条件(円)
   ,wholesale_adj_margin_en_4   xxcok_condition_lines.wholesale_adj_margin_en_4%TYPE     -- 問屋マージン修正(円)
   ,wholesale_adj_margin_per_4  xxcok_condition_lines.wholesale_adj_margin_per_4%TYPE    -- 問屋マージン修正(％)
   ,accrued_en_4                xxcok_condition_lines.accrued_en_4%TYPE                  -- 未収計４(円)
   ,prediction_qty_5            xxcok_condition_lines.prediction_qty_5%TYPE              -- 予測数量５(本)
   ,ratio_per_5                 xxcok_condition_lines.ratio_per_5%TYPE                   -- 比率(％)
   ,amount_prorated_en_5        xxcok_condition_lines.amount_prorated_en_5%TYPE          -- 金額按分(円)
   ,condition_unit_price_en_5   xxcok_condition_lines.condition_unit_price_en_5%TYPE     -- 条件単価５(円)
   ,support_amount_sum_en_5     xxcok_condition_lines.support_amount_sum_en_5%TYPE       -- 協賛金合計(円)
   ,prediction_qty_6            xxcok_condition_lines.prediction_qty_6%TYPE              -- 予測数量６(本)
   ,condition_unit_price_en_6   xxcok_condition_lines.condition_unit_price_en_6%TYPE     -- 条件単価６(円)
   ,target_rate_6               xxcok_condition_lines.target_rate_6%TYPE                 -- 対象率(％)
   ,deduction_unit_price_en_6   xxcok_condition_lines.deduction_unit_price_en_6%TYPE     -- 控除単価(円)
-- 2021/03/22 Ver1.2 MOD Start
--   ,accounting_base             xxcok_condition_lines.accounting_base%TYPE               -- 計上拠点
   ,accounting_customer_code    xxcok_condition_lines.accounting_customer_code%TYPE      -- 計上顧客
   ,sale_base_code              xxcmm_cust_accounts.sale_base_code%TYPE                  -- 売上拠点
-- 2021/03/22 Ver1.2 MOD End
   ,deduction_amount            xxcok_condition_lines.deduction_amount%TYPE              -- 控除額(本体)
   ,deduction_tax_amount        xxcok_condition_lines.deduction_tax_amount%TYPE          -- 控除税額
   ,deduction_type              fnd_lookup_values.attribute2%TYPE                        -- 控除タイプ
    );
--
  -- 販売控除更新用ワークテーブル定義
  TYPE gr_condition_work_1_rec IS RECORD(
    condition_id                xxcok_condition_header.condition_id%TYPE                 -- 控除条件ID
   ,condition_line_id           xxcok_condition_lines.condition_line_id%TYPE             -- 控除詳細ID
   ,end_date_active             xxcok_condition_header.end_date_active%TYPE              -- 終了日
    );
--
  -- ワークテーブル型定義
  -- 控除条件詳細情報
  TYPE g_condition_work_ttype  IS TABLE OF gr_condition_work_rec INDEX BY BINARY_INTEGER;
    gt_condition_work_tbl    g_condition_work_ttype;
--
  -- 販売控除更新用情報
  TYPE g_condition_work_1_ttype  IS TABLE OF gr_condition_work_1_rec INDEX BY BINARY_INTEGER;
    gt_condition_work_1_tbl    g_condition_work_1_ttype;

--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_proc_date              DATE;                                             -- 業務日付
  gd_work_date              DATE;                                             -- ワーク用
--
  gv_dedu_uom_code          VARCHAR2(3) DEFAULT NULL;                         -- 控除単位
  gn_dedu_unit_price        NUMBER      DEFAULT 0;                            -- 控除単価
  gn_dedu_quantity          NUMBER      DEFAULT 0;                            -- 控除数量
  gn_dedu_amount            NUMBER      DEFAULT 0;                            -- 控除額
-- 2020/12/03 Ver1.1 ADD Start
  gn_compensation             NUMBER;                                         -- 補填
  gn_margin                   NUMBER;                                         -- 問屋マージン
  gn_sales_promotion_expenses NUMBER;                                         -- 拡売
  gn_margin_reduction         NUMBER;                                         -- 問屋マージン減額
-- 2020/12/03 Ver1.1 ADD End
  gn_dedu_tax_amount        NUMBER      DEFAULT 0;                            -- 控除税額
-- 2020/12/03 Ver1.1 ADD Start
  gn_sales_id_1             NUMBER      DEFAULT 0;                            -- 前回処理ID(販売実績ヘッダーID)
  gn_sales_id_2             NUMBER      DEFAULT 0;                            -- 前回処理ID(売上実績振替情報ID)
-- 2020/12/03 Ver1.1 ADD End
-- 2020/12/03 Ver1.1 DEL Start
--  gd_prev_date              DATE ;                                            -- 前日業務日付
--  gd_prev_month_date        DATE ;                                            -- 前月末日付
-- 2020/12/03 Ver1.1 DEL End
  gv_tax_code               VARCHAR2(4) DEFAULT NULL;                         -- 税コード
  gn_tax_rate               NUMBER      DEFAULT 0;                            -- 税率
--
  -- ===============================
  -- ユーザー定義グローバル・カーソル
  -- ===============================
  -- 控除マスタ情報取得
  CURSOR get_condition_data_cur
  IS
    SELECT xch.condition_id                        condition_id                                  -- 控除条件ID
          ,xch.condition_no                        condition_no                                  -- 控除番号
          ,xch.enabled_flag_h                      enabled_flag_h                                -- ヘッダ有効フラグ
          ,xch.corp_code                           corp_code                                     -- 企業コード
          ,xch.deduction_chain_code                deduction_chain_code                          -- 控除用チェーンコード
          ,xch.customer_code                       customer_code                                 -- 顧客コード
          ,xch.data_type                           data_type                                     -- データ種類
          ,xch.tax_code                            tax_code                                      -- 税コード
          ,xch.tax_rate                            tax_rate                                      -- 税率
          ,xch.start_date_active                   start_date_active                             -- 開始日
          ,xch.end_date_active                     end_date_active                               -- 終了日
          ,xch.content                             content                                       -- 内容
          ,xch.decision_no                         decision_no                                   -- 決裁No
          ,xch.agreement_no                        agreement_no                                  -- 契約番号
          ,xch.header_recovery_flag                header_recovery_flag                          -- リカバリ対象フラグ
          ,xcl.condition_line_id                   condition_line_id                             -- 控除詳細ID
          ,xcl.detail_number                       detail_number                                 -- 明細番号
          ,xcl.enabled_flag_l                      enabled_flag_l                                -- 明細有効フラグ
          ,xcl.target_category                     target_category                               -- 対象区分
          ,xcl.product_class                       product_class                                 -- 商品区分
          ,xcl.item_code                           item_code                                     -- 品目コード
          ,xcl.uom_code                            uom_code                                      -- 単位
          ,xcl.line_recovery_flag                  line_recovery_flag                            -- リカバリ対象フラグ
          ,xcl.shop_pay_1                          shop_pay_1                                    -- 店納(％)
          ,xcl.material_rate_1                     material_rate_1                               -- 料率(％)
          ,xcl.condition_unit_price_en_2           condition_unit_price_en_2                     -- 条件単価２(円)
          ,xcl.demand_en_3                         demand_en_3                                   -- 請求(円)
          ,xcl.shop_pay_en_3                       shop_pay_en_3                                 -- 店納(円)
          ,xcl.compensation_en_3                   compensation_en_3                             -- 補填(円)
          ,xcl.wholesale_margin_en_3               wholesale_margin_en_3                         -- 問屋マージン(円)
          ,xcl.wholesale_margin_per_3              wholesale_margin_per_3                        -- 問屋マージン(％)
          ,xcl.accrued_en_3                        accrued_en_3                                  -- 未収計３(円)
          ,xcl.normal_shop_pay_en_4                normal_shop_pay_en_4                          -- 通常店納(円)
          ,xcl.just_shop_pay_en_4                  just_shop_pay_en_4                            -- 今回店納(円)
          ,xcl.just_condition_en_4                 just_condition_en_4                           -- 今回条件(円)
          ,xcl.wholesale_adj_margin_en_4           wholesale_adj_margin_en_4                     -- 問屋マージン修正(円)
          ,xcl.wholesale_adj_margin_per_4          wholesale_adj_margin_per_4                    -- 問屋マージン修正(％)
          ,xcl.accrued_en_4                        accrued_en_4                                  -- 未収計４(円)
          ,xcl.prediction_qty_5                    prediction_qty_5                              -- 予測数量５(本)
          ,xcl.ratio_per_5                         ratio_per_5                                   -- 比率(％)
          ,xcl.amount_prorated_en_5                amount_prorated_en_5                          -- 金額按分(円)
          ,xcl.condition_unit_price_en_5           condition_unit_price_en_5                     -- 条件単価５(円)
          ,xcl.support_amount_sum_en_5             support_amount_sum_en_5                       -- 協賛金合計(円)
          ,xcl.prediction_qty_6                    prediction_qty_6                              -- 予測数量６(本)
          ,xcl.condition_unit_price_en_6           condition_unit_price_en_6                     -- 条件単価６(円)
          ,xcl.target_rate_6                       target_rate_6                                 -- 対象率(％)
          ,xcl.deduction_unit_price_en_6           deduction_unit_price_en_6                     -- 控除単価(円)
-- 2021/03/22 Ver1.2 MOD Start
--          ,xcl.accounting_base                     accounting_base                               -- 計上拠点
          ,xcl.accounting_customer_code            accounting_customer_code                      -- 計上顧客
          ,xca.sale_base_code                      sale_base_code                                -- 売上拠点
-- 2021/03/22 Ver1.2 MOD End
          ,xcl.deduction_amount                    deduction_amount                              -- 控除額(本体)
          ,xcl.deduction_tax_amount                deduction_tax_amount                          -- 控除税額
          ,flv.attribute2                          deduction_type                                -- 控除タイプ
    FROM   xxcok_condition_header    xch                     -- 控除条件テーブル
          ,xxcok_condition_lines     xcl                     -- 控除詳細テーブル
          ,fnd_lookup_values         flv                     -- クイックコード
-- 2021/03/22 Ver1.2 ADD Start
          ,xxcmm_cust_accounts       xca                     -- 顧客追加情報
-- 2021/03/22 Ver1.2 ADD End
    WHERE  xch.condition_id              = xcl.condition_id     -- 控除条件ID
    AND    xch.data_type                 = flv.lookup_code      -- データ種類
    AND    flv.lookup_type               = cv_lookup_dedu_code  -- 控除データ種類
    AND    flv.enabled_flag              = cv_y_flag            -- 使用可能：Y
    AND    flv.language                  = USERENV('LANG')      -- 言語：USERENV('LANG')
    AND  ((    xch.header_recovery_flag <> cv_n_flag
           AND xcl.line_recovery_flag   <> cv_n_flag)
        OR(    xch.header_recovery_flag <> cv_n_flag
           AND xcl.line_recovery_flag    = cv_n_flag)
        OR(    xch.header_recovery_flag  = cv_n_flag
           AND xcl.line_recovery_flag   <> cv_n_flag))          -- リカバリ対象フラグ
    AND  (     xch.request_id            = gn_request_id
           OR  xcl.request_id            = gn_request_id)       -- 要求ID
-- 2021/03/22 Ver1.2 ADD Start
      AND xcl.accounting_customer_code   = xca.customer_code(+)          -- 控除詳細:計上顧客
-- 2021/03/22 Ver1.2 ADD End
    ORDER BY
           DECODE(xcl.line_recovery_flag,cv_d_flag,cn_1
                                        ,cv_i_flag,cn_2
                                        ,cv_u_flag,cn_3
                                        ,cn_4)                  -- 明細リカバリ対象フラグ
          ,xcl.condition_no                                     -- 控除番号
          ,xcl.detail_number                                    -- 明細番号
    ;
--
  -- 販売実績情報データ抽出
  CURSOR g_sales_exp_cur
  IS
    WITH
      flvc1 AS
       (SELECT /*+ MATERIALIZED */ lookup_code
        FROM   fnd_lookup_values flvc
        WHERE  flvc.lookup_type   = cv_lookup_ded_type_code
        AND    flvc.language      = USERENV('LANG')
        AND    flvc.enabled_flag  = cv_y_flag
        AND    flvc.attribute1    = cv_y_flag
       )
     ,flvc2 AS
       (SELECT /*+ MATERIALIZED */ meaning
        FROM   fnd_lookup_values flvc
        WHERE  flvc.lookup_type   = cv_lookup_cls_code
        AND    flvc.language      = USERENV('LANG')
        AND    flvc.enabled_flag  = cv_y_flag
        AND    flvc.attribute4    = cv_y_flag
       )
     ,flvc3 AS
       (SELECT /*+ MATERIALIZED */ lookup_code
        FROM   fnd_lookup_values flvc
        WHERE  flvc.lookup_type   = cv_lookup_gyotai_code
        AND    flvc.language      = USERENV('LANG')
        AND    flvc.enabled_flag  = cv_y_flag
        AND    flvc.attribute2    = cv_y_flag
       )
    -- ①顧客
    SELECT /*+ leading(xcrt xseh xsel xca chcd dtyp) FULL(xcrt)
               USE_NL(xseh) USE_NL(xsel) USE_NL(xca) USE_NL(chcd) USE_NL(dtyp) */
           xseh.sales_base_code                    sales_base_code              -- 売上拠点
          ,xseh.ship_to_customer_code              ship_to_customer_code        -- 顧客【納品先】
          ,xseh.delivery_date                      delivery_date                -- 納品日
          ,xsel.sales_exp_line_id                  sales_exp_line_id            -- 販売実績明細ID
          ,xsel.item_code                          div_item_code                -- 売上品目コード
          ,xsel.dlv_uom_code                       dlv_uom_code                 -- 納品単位
          ,xsel.dlv_unit_price                     dlv_unit_price               -- 納品単価
          ,xsel.dlv_qty                            dlv_qty                      -- 納品数量
          ,xsel.pure_amount                        pure_amount                  -- 本体金額
          ,xsel.tax_amount                         tax_amount                   -- 消費税金額
          ,xsel.tax_code                           tax_code                     -- 税金コード
          ,xsel.tax_rate                           tax_rate                     -- 消費税率
          ,xcrt.condition_id                       condition_id                 -- 控除条件ID
          ,xcrt.condition_no                       condition_no                 -- 控除番号
          ,xcrt.corp_code                          corp_code                    -- 企業コード
          ,xcrt.deduction_chain_code               deduction_chain_code         -- 控除用チェーンコード
          ,xcrt.customer_code                      customer_code                -- 顧客コード
          ,xcrt.data_type                          data_type                    -- データ種類
          ,xcrt.tax_code_con                       tax_code_con                 -- 税コード
          ,xcrt.tax_rate_con                       tax_rate_con                 -- 税率
          ,chcd.attribute3                         chain_base                   -- 本部担当拠点(チェーン店)
          ,xca.sale_base_code                      cust_base                    -- 売上拠点(顧客)
          ,xcrt.condition_line_id                  condition_line_id            -- 控除詳細ID
          ,xcrt.product_class                      product_class                -- 商品区分
          ,xcrt.item_code                          item_code                    -- 品目コード(条件)
          ,xcrt.uom_code                           uom_code                     -- 単位(条件)
          ,xcrt.target_category                    target_category              -- 対象区分
          ,xcrt.shop_pay_1                         shop_pay_1                   -- 店納(％)
          ,xcrt.material_rate_1                    material_rate_1              -- 料率(％)
          ,xcrt.condition_unit_price_en_2          condition_unit_price_en_2    -- 条件単価２(円)
          ,xcrt.accrued_en_3                       accrued_en_3                 -- 未収計３(円)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcrt.compensation_en_3                  compensation_en_3            -- 補填(円)
          ,xcrt.wholesale_margin_en_3              wholesale_margin_en_3        -- 問屋マージン(円)
-- 2020/12/03 Ver1.1 ADD End
          ,xcrt.accrued_en_4                       accrued_en_4                 -- 未収計４(円)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcrt.just_condition_en_4                just_condition_en_4          -- 今回条件(円)
          ,xcrt.wholesale_adj_margin_en_4          wholesale_adj_margin_en_4    -- 問屋マージン修正(円)
-- 2020/12/03 Ver1.1 ADD End
          ,xcrt.condition_unit_price_en_5          condition_unit_price_en_5    -- 条件単価５(円)
          ,xcrt.deduction_unit_price_en_6          deduction_unit_price_en_6    -- 控除単価(円)
          ,dtyp.attribute2                         attribute2                   -- 控除タイプ
          ,xcrt.header_recovery_flag               header_recovery_flag         -- ヘッダーリカバリ対象フラグ
          ,xcrt.line_recovery_flag                 line_recovery_flag           -- 明細リカバリ対象フラグ
    FROM   fnd_lookup_values                                          dtyp  -- データ種類
          ,fnd_lookup_values                                          chcd  -- チェーン店
          ,xxcmm_cust_accounts                                        xca   -- 顧客追加情報
          ,xxcok_sales_exp_h                                          xseh  -- 販売実績ヘッダ
          ,xxcok_sales_exp_l                                          xsel  -- 販売実績明細
          ,xxcok_condition_recovery_temp                              xcrt  -- 控除マスタリカバリ用ワークテーブル
          ,flvc1                                                      d_typ
          ,flvc2                                                      mk_cls
          ,flvc3                                                      gyotai_sho
    WHERE  1=1
    AND    xseh.sales_exp_header_id          = xsel.sales_exp_header_id
    AND    xseh.create_class                 = mk_cls.meaning
    AND    xca.customer_code                 = xseh.ship_to_customer_code
    AND    xca.business_low_type             = gyotai_sho.lookup_code
    AND    chcd.lookup_type(+)               = cv_lookup_chain_code
    AND    chcd.lookup_code(+)               = xca.intro_chain_code2
    AND    chcd.language(+)                  = USERENV('LANG')
    AND    chcd.enabled_flag(+)              = cv_y_flag
    AND    xcrt.enabled_flag_h               = cv_y_flag
    AND    dtyp.lookup_type                  = cv_lookup_dedu_code
    AND    dtyp.lookup_code                  = xcrt.data_type
    AND    dtyp.language                     = USERENV('LANG')
    AND    dtyp.enabled_flag                 = cv_y_flag
    AND    xseh.ship_to_customer_code        = xcrt.customer_code
    AND    xcrt.customer_code           IS NOT NULL
-- 2020/12/03 Ver1.1 MOD Start
    AND    xseh.delivery_date          BETWEEN xcrt.start_date_active
                                       AND     xcrt.end_date_active
--    AND    xseh.delivery_date          BETWEEN xcrt.start_date_active
--               AND CASE WHEN xcrt.end_date_active < gd_prev_date 
--                     THEN xcrt.end_date_active
--                     ELSE gd_prev_date
--                   END
-- 2020/12/03 Ver1.1 MOD End
    AND    xcrt.enabled_flag_l               = cv_y_flag
-- 2021/04/06 Ver1.2 MOD Start
    AND (  xcrt.item_code IN (xsel.item_code, xsel.vessel_group_item_code)
--    AND (  xsel.item_code                    = xcrt.item_code
-- 2021/04/06 Ver1.2 MOD End
    OR     xsel.product_class                = xcrt.product_class)
    AND    dtyp.attribute2                   = d_typ.lookup_code
-- 2020/12/03 Ver1.1 ADD Start
    AND    xseh.sales_exp_header_id         <= gn_sales_id_1
-- 2020/12/03 Ver1.1 ADD End
    UNION ALL
    -- ②控除用チェーン
    SELECT /*+ leading(xcrt xca xseh xsel chcd dtyp) FULL(xcrt)
               USE_NL(xseh) USE_NL(xsel) USE_NL(xca) USE_NL(chcd) USE_NL(dtyp) */
           xseh.sales_base_code                    sales_base_code              -- 売上拠点
          ,xseh.ship_to_customer_code              ship_to_customer_code        -- 顧客【納品先】
          ,xseh.delivery_date                      delivery_date                -- 納品日
          ,xsel.sales_exp_line_id                  sales_exp_line_id            -- 販売実績明細ID
          ,xsel.item_code                          div_item_code                -- 売上品目コード
          ,xsel.dlv_uom_code                       dlv_uom_code                 -- 納品単位
          ,xsel.dlv_unit_price                     dlv_unit_price               -- 納品単価
          ,xsel.dlv_qty                            dlv_qty                      -- 納品数量
          ,xsel.pure_amount                        pure_amount                  -- 本体金額
          ,xsel.tax_amount                         tax_amount                   -- 消費税金額
          ,xsel.tax_code                           tax_code                     -- 税金コード
          ,xsel.tax_rate                           tax_rate                     -- 消費税率
          ,xcrt.condition_id                       condition_id                 -- 控除条件ID
          ,xcrt.condition_no                       condition_no                 -- 控除番号
          ,xcrt.corp_code                          corp_code                    -- 企業コード
          ,xcrt.deduction_chain_code               deduction_chain_code         -- 控除用チェーンコード
          ,xcrt.customer_code                      customer_code                -- 顧客コード
          ,xcrt.data_type                          data_type                    -- データ種類
          ,xcrt.tax_code_con                       tax_code_con                 -- 税コード
          ,xcrt.tax_rate_con                       tax_rate_con                 -- 税率
          ,chcd.attribute3                         chain_base                   -- 本部担当拠点(チェーン店)
          ,xca.sale_base_code                      cust_base                    -- 売上拠点(顧客)
          ,xcrt.condition_line_id                  condition_line_id            -- 控除詳細ID
          ,xcrt.product_class                      product_class                -- 商品区分
          ,xcrt.item_code                          item_code                    -- 品目コード(条件)
          ,xcrt.uom_code                           uom_code                     -- 単位(条件)
          ,xcrt.target_category                    target_category              -- 対象区分
          ,xcrt.shop_pay_1                         shop_pay_1                   -- 店納(％)
          ,xcrt.material_rate_1                    material_rate_1              -- 料率(％)
          ,xcrt.condition_unit_price_en_2          condition_unit_price_en_2    -- 条件単価２(円)
          ,xcrt.accrued_en_3                       accrued_en_3                 -- 未収計３(円)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcrt.compensation_en_3                  compensation_en_3            -- 補填(円)
          ,xcrt.wholesale_margin_en_3              wholesale_margin_en_3        -- 問屋マージン(円)
-- 2020/12/03 Ver1.1 ADD End
          ,xcrt.accrued_en_4                       accrued_en_4                 -- 未収計４(円)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcrt.just_condition_en_4                just_condition_en_4          -- 今回条件(円)
          ,xcrt.wholesale_adj_margin_en_4          wholesale_adj_margin_en_4    -- 問屋マージン修正(円)
-- 2020/12/03 Ver1.1 ADD End
          ,xcrt.condition_unit_price_en_5          condition_unit_price_en_5    -- 条件単価５(円)
          ,xcrt.deduction_unit_price_en_6          deduction_unit_price_en_6    -- 控除単価(円)
          ,dtyp.attribute2                         attribute2                   -- 控除タイプ
          ,xcrt.header_recovery_flag               header_recovery_flag         -- ヘッダーリカバリ対象フラグ
          ,xcrt.line_recovery_flag                 line_recovery_flag           -- 明細リカバリ対象フラグ
    FROM   fnd_lookup_values                                          dtyp  -- データ種類
          ,fnd_lookup_values                                          chcd  -- チェーン店
          ,xxcmm_cust_accounts                                        xca   -- 顧客追加情報
          ,xxcok_sales_exp_h                                          xseh  -- 販売実績ヘッダ
          ,xxcok_sales_exp_l                                          xsel  -- 販売実績明細
          ,xxcok_condition_recovery_temp                              xcrt  -- 控除マスタリカバリ用ワークテーブル
          ,flvc1                                                      d_typ
          ,flvc2                                                      mk_cls
          ,flvc3                                                      gyotai_sho
    WHERE  1=1
    AND    xseh.sales_exp_header_id          = xsel.sales_exp_header_id
    AND    xseh.create_class                 = mk_cls.meaning
    AND    xca.customer_code                 = xseh.ship_to_customer_code
    AND    xca.business_low_type             = gyotai_sho.lookup_code
    AND    chcd.lookup_type(+)               = cv_lookup_chain_code
    AND    chcd.lookup_code(+)               = xca.intro_chain_code2
    AND    chcd.language(+)                  = USERENV('LANG')
    AND    chcd.enabled_flag(+)              = cv_y_flag
    AND    xcrt.enabled_flag_h               = cv_y_flag
    AND    dtyp.lookup_type                  = cv_lookup_dedu_code
    AND    dtyp.lookup_code                  = xcrt.data_type
    AND    dtyp.language                     = USERENV('LANG')
    AND    dtyp.enabled_flag                 = cv_y_flag
    AND    xca.intro_chain_code2             = xcrt.deduction_chain_code
    AND    xcrt.deduction_chain_code    IS NOT NULL
-- 2020/12/03 Ver1.1 MOD Start
    AND    xseh.delivery_date          BETWEEN xcrt.start_date_active
                                       AND     xcrt.end_date_active
--    AND    xseh.delivery_date          BETWEEN xcrt.start_date_active
--               AND CASE WHEN xcrt.end_date_active < gd_prev_date 
--                     THEN xcrt.end_date_active
--                     ELSE gd_prev_date
--                   END
-- 2020/12/03 Ver1.1 MOD End
    AND    xcrt.enabled_flag_l               = cv_y_flag
-- 2021/04/06 Ver1.2 MOD Start
    AND (  xcrt.item_code IN (xsel.item_code, xsel.vessel_group_item_code)
--    AND (  xsel.item_code                    = xcrt.item_code
-- 2021/04/06 Ver1.2 MOD End
    OR     xsel.product_class                = xcrt.product_class)
    AND    dtyp.attribute2                   = d_typ.lookup_code
-- 2020/12/03 Ver1.1 ADD Start
    AND    xseh.sales_exp_header_id         <= gn_sales_id_1
-- 2020/12/03 Ver1.1 ADD End
    UNION ALL
    -- ③企業
    SELECT /*+ leading(xcrt chcd xca xseh xsel dtyp) FULL(xcrt)
               USE_NL(xseh) USE_NL(xsel) USE_NL(xca) USE_NL(chcd) USE_NL(dtyp) */
           xseh.sales_base_code                    sales_base_code              -- 売上拠点
          ,xseh.ship_to_customer_code              ship_to_customer_code        -- 顧客【納品先】
          ,xseh.delivery_date                      delivery_date                -- 納品日
          ,xsel.sales_exp_line_id                  sales_exp_line_id            -- 販売実績明細ID
          ,xsel.item_code                          div_item_code                -- 売上品目コード
          ,xsel.dlv_uom_code                       dlv_uom_code                 -- 納品単位
          ,xsel.dlv_unit_price                     dlv_unit_price               -- 納品単価
          ,xsel.dlv_qty                            dlv_qty                      -- 納品数量
          ,xsel.pure_amount                        pure_amount                  -- 本体金額
          ,xsel.tax_amount                         tax_amount                   -- 消費税金額
          ,xsel.tax_code                           tax_code                     -- 税金コード
          ,xsel.tax_rate                           tax_rate                     -- 消費税率
          ,xcrt.condition_id                       condition_id                 -- 控除条件ID
          ,xcrt.condition_no                       condition_no                 -- 控除番号
          ,xcrt.corp_code                          corp_code                    -- 企業コード
          ,xcrt.deduction_chain_code               deduction_chain_code         -- 控除用チェーンコード
          ,xcrt.customer_code                      customer_code                -- 顧客コード
          ,xcrt.data_type                          data_type                    -- データ種類
          ,xcrt.tax_code_con                       tax_code_con                 -- 税コード
          ,xcrt.tax_rate_con                       tax_rate_con                 -- 税率
          ,chcd.attribute3                         chain_base                   -- 本部担当拠点(チェーン店)
          ,xca.sale_base_code                      cust_base                    -- 売上拠点(顧客)
          ,xcrt.condition_line_id                  condition_line_id            -- 控除詳細ID
          ,xcrt.product_class                      product_class                -- 商品区分
          ,xcrt.item_code                          item_code                    -- 品目コード(条件)
          ,xcrt.uom_code                           uom_code                     -- 単位(条件)
          ,xcrt.target_category                    target_category              -- 対象区分
          ,xcrt.shop_pay_1                         shop_pay_1                   -- 店納(％)
          ,xcrt.material_rate_1                    material_rate_1              -- 料率(％)
          ,xcrt.condition_unit_price_en_2          condition_unit_price_en_2    -- 条件単価２(円)
          ,xcrt.accrued_en_3                       accrued_en_3                 -- 未収計３(円)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcrt.compensation_en_3                  compensation_en_3            -- 補填(円)
          ,xcrt.wholesale_margin_en_3              wholesale_margin_en_3        -- 問屋マージン(円)
-- 2020/12/03 Ver1.1 ADD End
          ,xcrt.accrued_en_4                       accrued_en_4                 -- 未収計４(円)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcrt.just_condition_en_4                just_condition_en_4          -- 今回条件(円)
          ,xcrt.wholesale_adj_margin_en_4          wholesale_adj_margin_en_4    -- 問屋マージン修正(円)
-- 2020/12/03 Ver1.1 ADD End
          ,xcrt.condition_unit_price_en_5          condition_unit_price_en_5    -- 条件単価５(円)
          ,xcrt.deduction_unit_price_en_6          deduction_unit_price_en_6    -- 控除単価(円)
          ,dtyp.attribute2                         attribute2                   -- 控除タイプ
          ,xcrt.header_recovery_flag               header_recovery_flag         -- ヘッダーリカバリ対象フラグ
          ,xcrt.line_recovery_flag                 line_recovery_flag           -- 明細リカバリ対象フラグ
    FROM   fnd_lookup_values                                          dtyp  -- データ種類
          ,fnd_lookup_values                                          chcd  -- チェーン店
          ,xxcmm_cust_accounts                                        xca   -- 顧客追加情報
          ,xxcok_sales_exp_h                                          xseh  -- 販売実績ヘッダ
          ,xxcok_sales_exp_l                                          xsel  -- 販売実績明細
          ,xxcok_condition_recovery_temp                              xcrt  -- 控除マスタリカバリ用ワークテーブル
          ,flvc1                                                      d_typ
          ,flvc2                                                      mk_cls
          ,flvc3                                                      gyotai_sho
    WHERE  1=1
    AND    xseh.sales_exp_header_id          = xsel.sales_exp_header_id
    AND    xseh.create_class                 = mk_cls.meaning
    AND    xca.customer_code                 = xseh.ship_to_customer_code
    AND    xca.business_low_type             = gyotai_sho.lookup_code
    AND    chcd.lookup_type                  = cv_lookup_chain_code
    AND    chcd.lookup_code                  = xca.intro_chain_code2
    AND    chcd.language                     = USERENV('LANG')
    AND    chcd.enabled_flag                 = cv_y_flag
    AND    xcrt.enabled_flag_h               = cv_y_flag
    AND    dtyp.lookup_type                  = cv_lookup_dedu_code
    AND    dtyp.lookup_code                  = xcrt.data_type
    AND    dtyp.language                     = USERENV('LANG')
    AND    dtyp.enabled_flag                 = cv_y_flag
    AND    chcd.attribute1                   = xcrt.corp_CODE
    AND    xcrt.corp_code               IS NOT NULL
-- 2020/12/03 Ver1.1 MOD Start
    AND    xseh.delivery_date          BETWEEN xcrt.start_date_active
                                       AND     xcrt.end_date_active
--    AND    xseh.delivery_date          BETWEEN xcrt.start_date_active
--               AND CASE WHEN xcrt.end_date_active < gd_prev_date 
--                     THEN xcrt.end_date_active
--                     ELSE gd_prev_date
--                   END
-- 2020/12/03 Ver1.1 MOD End
    AND    xcrt.enabled_flag_l               = cv_y_flag
-- 2021/04/06 Ver1.2 MOD Start
    AND (  xcrt.item_code IN (xsel.item_code, xsel.vessel_group_item_code)
--    AND (  xsel.item_code                    = xcrt.item_code
-- 2021/04/06 Ver1.2 MOD End
    OR     xsel.product_class                = xcrt.product_class)
    AND    dtyp.attribute2                   = d_typ.lookup_code
-- 2020/12/03 Ver1.1 ADD Start
    AND    xseh.sales_exp_header_id         <= gn_sales_id_1
-- 2020/12/03 Ver1.1 ADD End
    ;
--
  -- カーソルレコード取得用
  g_sales_exp_rec             g_sales_exp_cur%ROWTYPE;
--
  --実績振替情報(EDI)データ抽出
  CURSOR g_selling_trns_cur
  IS
    WITH
     flvc1 AS
        ( SELECT /*+ MATERIALIZED */ lookup_code AS lookup_code
          FROM  fnd_lookup_values flvc
          WHERE flvc.lookup_type  = cv_lookup_ded_type_code  -- 控除タイプ
          AND   flvc.language     = USERENV('LANG')
          AND   flvc.enabled_flag = cv_y_flag
          AND   flvc.attribute1   = cv_y_flag            )     -- 販売控除作成対象
     ,flvc3 AS
        ( SELECT /*+ MATERIALIZED */ lookup_code AS lookup_code
          FROM  fnd_lookup_values flvc
          WHERE flvc.lookup_type  = cv_lookup_gyotai_code  -- 業態(小分類)
          AND   flvc.language     = USERENV('LANG')
          AND   flvc.enabled_flag = cv_y_flag
          AND   flvc.attribute2   = cv_y_flag            )   -- 販売控除作成対象外
    -- ①顧客
    SELECT /*+ leading(xcrt xsi xca flv2 flv) full(xcrt)
               use_nl(xsi) use_nl(xca) use_nl(flv) use_nl(flv2) */
           xsi.delivery_base_code                    delivery_base_code           -- 振替元拠点
          ,xsi.selling_from_cust_code                selling_from_cust_code       -- 振替元顧客
          ,xsi.base_code                             base_code                    -- 振替先拠点
          ,xsi.cust_code                             cust_code                    -- 振替先顧客
          ,xsi.selling_date                          selling_date                 -- 売上計上日
          ,xsi.selling_trns_info_id                  selling_trns_info_id         -- 売上実績振替情報ID
          ,xsi.item_code                             item_code                    -- 品目コード
          ,xsi.unit_type                             unit_type                    -- 納品単位
          ,xsi.delivery_unit_price                   delivery_unit_price          -- 納品単価
          ,xsi.qty                                   qty                          -- 数量
          ,xsi.selling_amt_no_tax                    selling_amt_no_tax           -- 本体金額（税抜き）
          ,xsi.tax_code                              tax_code                     -- 消費税コード
          ,xsi.tax_rate                              tax_rate                     -- 消費税率
          ,xsi.selling_amt - xsi.selling_amt_no_tax  tax_amount                   -- 消費税額
          ,xcrt.condition_id                         condition_id                 -- 控除条件ID
          ,xcrt.condition_no                         condition_no                 -- 控除番号
          ,xcrt.corp_code                            corp_code                    -- 企業コード
          ,xcrt.deduction_chain_code                 deduction_chain_code         -- 控除用チェーンコード
          ,xcrt.customer_code                        customer_code                -- 顧客コード(条件)
          ,xcrt.data_type                            data_type                    -- データ種類
          ,xcrt.tax_code_con                         tax_code_con                 -- 税コード
          ,xcrt.tax_rate_con                         tax_rate_con                 -- 税率
          ,flv.attribute3                            attribute3                   -- 本部担当拠点(チェーン店)
          ,xca.sale_base_code                        sale_base_code               -- 売上拠点(顧客)
          ,xcrt.condition_line_id                    condition_line_id            -- 控除詳細ID
          ,xcrt.product_class                        product_class                -- 商品区分
          ,xcrt.item_code                            item_code_cond               -- 品目コード(条件)
          ,xcrt.uom_code                             uom_code                     -- 単位(条件)
          ,xcrt.target_category                      target_category              -- 対象区分
          ,xcrt.shop_pay_1                           shop_pay_1                   -- 店納(％)
          ,xcrt.material_rate_1                      material_rate_1              -- 料率(％)
          ,xcrt.condition_unit_price_en_2            condition_unit_price_en_2    -- 条件単価２(円)
          ,xcrt.accrued_en_3                         accrued_en_3                 -- 未収計３(円)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcrt.compensation_en_3                    compensation_en_3            -- 補填(円)
          ,xcrt.wholesale_margin_en_3                wholesale_margin_en_3        -- 問屋マージン(円)
-- 2020/12/03 Ver1.1 ADD End
          ,xcrt.accrued_en_4                         accrued_en_4                 -- 未収計４(円)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcrt.just_condition_en_4                  just_condition_en_4          -- 今回条件(円)
          ,xcrt.wholesale_adj_margin_en_4            wholesale_adj_margin_en_4    -- 問屋マージン修正(円)
-- 2020/12/03 Ver1.1 ADD End
          ,xcrt.condition_unit_price_en_5            condition_unit_price_en_5    -- 条件単価５(円)
          ,xcrt.deduction_unit_price_en_6            deduction_unit_price_en_6    -- 控除単価(円)
          ,flv2.attribute2                           attribute2                   -- 控除タイプ
          ,xcrt.header_recovery_flag                 header_recovery_flag         -- ヘッダーリカバリ対象フラグ
          ,xcrt.line_recovery_flag                   line_recovery_flag           -- 明細リカバリ対象フラグ
    FROM   xxcok_dedu_edi_sell_trns       xsi             -- 控除データ作成用EDI売上実績振替
          ,xxcmm_cust_accounts            xca             -- 顧客追加情報
          ,fnd_lookup_values              flv             -- チェーン店
          ,fnd_lookup_values              flv2            -- データ種類
          ,xxcok_condition_recovery_temp  xcrt            -- 控除マスタリカバリ用ワークテーブル
          ,flvc1                          d_typ
          ,flvc3                          gyotai_sho
    WHERE  1=1
    AND    xsi.report_decision_flag      = cv_1
    AND    xsi.selling_trns_type         = cv_1
    AND    xca.customer_code             = xsi.cust_code
    AND    xca.business_low_type         = gyotai_sho.lookup_code
    AND    flv.lookup_type(+)            = cv_lookup_chain_code
    AND    flv.lookup_code(+)            = xca.intro_chain_code2
    AND    flv.language(+)               = USERENV('LANG')
    AND    flv.enabled_flag(+)           = cv_y_flag
    AND    xcrt.enabled_flag_h           = cv_y_flag
    AND    flv2.lookup_type              = cv_lookup_dedu_code
    AND    flv2.lookup_code              = xcrt.data_type
    AND    flv2.language                 = USERENV('LANG')
    AND    flv2.enabled_flag             = cv_y_flag
    AND    flv2.attribute2               = d_typ.lookup_code
    AND    xsi.cust_code                 = xcrt.customer_code
    AND    xcrt.customer_code           IS NOT NULL
-- 2020/12/03 Ver1.1 MOD Start
    AND    xsi.selling_date        BETWEEN xcrt.start_date_active
                                       AND xcrt.end_date_active
--    AND    xsi.selling_date        BETWEEN xcrt.start_date_active
--               AND CASE WHEN xcrt.end_date_active < gd_prev_date 
--                     THEN xcrt.end_date_active
--                     ELSE gd_prev_date
--                   END
-- 2020/12/03 Ver1.1 MOD End
    AND    xcrt.enabled_flag_l           = cv_y_flag
    AND (  xsi.item_code                 = xcrt.item_code
    OR     xsi.product_class             = xcrt.product_class ) -- ★
-- 2020/12/03 Ver1.1 ADD Start
    AND    xsi.selling_trns_info_id     <= gn_sales_id_2
-- 2020/12/03 Ver1.1 ADD End
    UNION ALL
    -- ②控除用チェーン
    SELECT /*+ leading(xcrt xca xsi flv2 flv) full(xcrt)
               use_nl(xsi) use_nl(xca) use_nl(flv) use_nl(flv2) */
           xsi.delivery_base_code                    delivery_base_code           -- 振替元拠点
          ,xsi.selling_from_cust_code                selling_from_cust_code       -- 振替元顧客
          ,xsi.base_code                             base_code                    -- 振替先拠点
          ,xsi.cust_code                             cust_code                    -- 振替先顧客
          ,xsi.selling_date                          selling_date                 -- 売上計上日
          ,xsi.selling_trns_info_id                  selling_trns_info_id         -- 売上実績振替情報ID
          ,xsi.item_code                             item_code                    -- 品目コード
          ,xsi.unit_type                             unit_type                    -- 納品単位
          ,xsi.delivery_unit_price                   delivery_unit_price          -- 納品単価
          ,xsi.qty                                   qty                          -- 数量
          ,xsi.selling_amt_no_tax                    selling_amt_no_tax           -- 本体金額（税抜き）
          ,xsi.tax_code                              tax_code                     -- 消費税コード
          ,xsi.tax_rate                              tax_rate                     -- 消費税率
          ,xsi.selling_amt - xsi.selling_amt_no_tax  tax_amount                   -- 消費税額
          ,xcrt.condition_id                         condition_id                 -- 控除条件ID
          ,xcrt.condition_no                         condition_no                 -- 控除番号
          ,xcrt.corp_code                            corp_code                    -- 企業コード
          ,xcrt.deduction_chain_code                 deduction_chain_code         -- 控除用チェーンコード
          ,xcrt.customer_code                        customer_code                -- 顧客コード(条件)
          ,xcrt.data_type                            data_type                    -- データ種類
          ,xcrt.tax_code_con                         tax_code_con                 -- 税コード
          ,xcrt.tax_rate_con                         tax_rate_con                 -- 税率
          ,flv.attribute3                            attribute3                   -- 本部担当拠点(チェーン店)
          ,xca.sale_base_code                        sale_base_code               -- 売上拠点(顧客)
          ,xcrt.condition_line_id                    condition_line_id            -- 控除詳細ID
          ,xcrt.product_class                        product_class                -- 商品区分
          ,xcrt.item_code                            item_code_cond               -- 品目コード(条件)
          ,xcrt.uom_code                             uom_code                     -- 単位(条件)
          ,xcrt.target_category                      target_category              -- 対象区分
          ,xcrt.shop_pay_1                           shop_pay_1                   -- 店納(％)
          ,xcrt.material_rate_1                      material_rate_1              -- 料率(％)
          ,xcrt.condition_unit_price_en_2            condition_unit_price_en_2    -- 条件単価２(円)
          ,xcrt.accrued_en_3                         accrued_en_3                 -- 未収計３(円)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcrt.compensation_en_3                    compensation_en_3            -- 補填(円)
          ,xcrt.wholesale_margin_en_3                wholesale_margin_en_3        -- 問屋マージン(円)
-- 2020/12/03 Ver1.1 ADD End
          ,xcrt.accrued_en_4                         accrued_en_4                 -- 未収計４(円)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcrt.just_condition_en_4                  just_condition_en_4          -- 今回条件(円)
          ,xcrt.wholesale_adj_margin_en_4            wholesale_adj_margin_en_4    -- 問屋マージン修正(円)
-- 2020/12/03 Ver1.1 ADD End
          ,xcrt.condition_unit_price_en_5            condition_unit_price_en_5    -- 条件単価５(円)
          ,xcrt.deduction_unit_price_en_6            deduction_unit_price_en_6    -- 控除単価(円)
          ,flv2.attribute2                           attribute2                   -- 控除タイプ
          ,xcrt.header_recovery_flag                 header_recovery_flag         -- ヘッダーリカバリ対象フラグ
          ,xcrt.line_recovery_flag                   line_recovery_flag           -- 明細リカバリ対象フラグ
    FROM   xxcok_dedu_edi_sell_trns       xsi             -- 控除データ作成用EDI売上実績振替
          ,xxcmm_cust_accounts            xca             -- 顧客追加情報
          ,fnd_lookup_values              flv             -- チェーン店
          ,fnd_lookup_values              flv2            -- データ種類
          ,xxcok_condition_recovery_temp  xcrt            -- 控除マスタリカバリ用ワークテーブル
          ,flvc1                          d_typ
          ,flvc3                          gyotai_sho
    WHERE  1=1
    AND    xsi.report_decision_flag      = cv_1
    AND    xsi.selling_trns_type         = cv_1
    AND    xca.customer_code             = xsi.cust_code
    AND    xca.business_low_type         = gyotai_sho.lookup_code
    AND    flv.lookup_type(+)            = cv_lookup_chain_code
    AND    flv.lookup_code(+)            = xca.intro_chain_code2
    AND    flv.language(+)               = USERENV('LANG')
    AND    flv.enabled_flag(+)           = cv_y_flag
    AND    xcrt.enabled_flag_h           = cv_y_flag
    AND    flv2.lookup_type              = cv_lookup_dedu_code
    AND    flv2.lookup_code              = xcrt.data_type
    AND    flv2.language                 = USERENV('LANG')
    AND    flv2.enabled_flag             = cv_y_flag
    AND    flv2.attribute2               = d_typ.lookup_code
    AND    xca.intro_chain_code2         = xcrt.deduction_chain_code
    AND    xcrt.deduction_chain_code    IS NOT NULL
-- 2020/12/03 Ver1.1 MOD Start
    AND    xsi.selling_date        BETWEEN xcrt.start_date_active
                                       AND xcrt.end_date_active
--    AND    xsi.selling_date        BETWEEN xcrt.start_date_active
--               AND CASE WHEN xcrt.end_date_active < gd_prev_date 
--                     THEN xcrt.end_date_active
--                     ELSE gd_prev_date
--                   END
-- 2020/12/03 Ver1.1 MOD End
    AND    xcrt.enabled_flag_l           = cv_y_flag
    AND (  xsi.item_code                 = xcrt.item_code
    OR     xsi.product_class             = xcrt.product_class ) -- ★
-- 2020/12/03 Ver1.1 ADD Start
    AND    xsi.selling_trns_info_id     <= gn_sales_id_2
-- 2020/12/03 Ver1.1 ADD End
    UNION ALL
    -- ③企業
    SELECT /*+ leading(xcrt flv xca xsi flv2) full(xcrt)
               use_nl(xsi) use_nl(xca) use_nl(flv) use_nl(flv2) */
           xsi.delivery_base_code                    delivery_base_code           -- 振替元拠点
          ,xsi.selling_from_cust_code                selling_from_cust_code       -- 振替元顧客
          ,xsi.base_code                             base_code                    -- 振替先拠点
          ,xsi.cust_code                             cust_code                    -- 振替先顧客
          ,xsi.selling_date                          selling_date                 -- 売上計上日
          ,xsi.selling_trns_info_id                  selling_trns_info_id         -- 売上実績振替情報ID
          ,xsi.item_code                             item_code                    -- 品目コード
          ,xsi.unit_type                             unit_type                    -- 納品単位
          ,xsi.delivery_unit_price                   delivery_unit_price          -- 納品単価
          ,xsi.qty                                   qty                          -- 数量
          ,xsi.selling_amt_no_tax                    selling_amt_no_tax           -- 本体金額（税抜き）
          ,xsi.tax_code                              tax_code                     -- 消費税コード
          ,xsi.tax_rate                              tax_rate                     -- 消費税率
          ,xsi.selling_amt - xsi.selling_amt_no_tax  tax_amount                   -- 消費税額
          ,xcrt.condition_id                         condition_id                 -- 控除条件ID
          ,xcrt.condition_no                         condition_no                 -- 控除番号
          ,xcrt.corp_code                            corp_code                    -- 企業コード
          ,xcrt.deduction_chain_code                 deduction_chain_code         -- 控除用チェーンコード
          ,xcrt.customer_code                        customer_code                -- 顧客コード(条件)
          ,xcrt.data_type                            data_type                    -- データ種類
          ,xcrt.tax_code_con                         tax_code_con                 -- 税コード
          ,xcrt.tax_rate_con                         tax_rate_con                 -- 税率
          ,flv.attribute3                            attribute3                   -- 本部担当拠点(チェーン店)
          ,xca.sale_base_code                        sale_base_code               -- 売上拠点(顧客)
          ,xcrt.condition_line_id                    condition_line_id            -- 控除詳細ID
          ,xcrt.product_class                        product_class                -- 商品区分
          ,xcrt.item_code                            item_code_cond               -- 品目コード(条件)
          ,xcrt.uom_code                             uom_code                     -- 単位(条件)
          ,xcrt.target_category                      target_category              -- 対象区分
          ,xcrt.shop_pay_1                           shop_pay_1                   -- 店納(％)
          ,xcrt.material_rate_1                      material_rate_1              -- 料率(％)
          ,xcrt.condition_unit_price_en_2            condition_unit_price_en_2    -- 条件単価２(円)
          ,xcrt.accrued_en_3                         accrued_en_3                 -- 未収計３(円)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcrt.compensation_en_3                    compensation_en_3            -- 補填(円)
          ,xcrt.wholesale_margin_en_3                wholesale_margin_en_3        -- 問屋マージン(円)
-- 2020/12/03 Ver1.1 ADD End
          ,xcrt.accrued_en_4                         accrued_en_4                 -- 未収計４(円)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcrt.just_condition_en_4                  just_condition_en_4          -- 今回条件(円)
          ,xcrt.wholesale_adj_margin_en_4            wholesale_adj_margin_en_4    -- 問屋マージン修正(円)
-- 2020/12/03 Ver1.1 ADD End
          ,xcrt.condition_unit_price_en_5            condition_unit_price_en_5    -- 条件単価５(円)
          ,xcrt.deduction_unit_price_en_6            deduction_unit_price_en_6    -- 控除単価(円)
          ,flv2.attribute2                           attribute2                   -- 控除タイプ
          ,xcrt.header_recovery_flag                 header_recovery_flag         -- ヘッダーリカバリ対象フラグ
          ,xcrt.line_recovery_flag                   line_recovery_flag           -- 明細リカバリ対象フラグ
    FROM   xxcok_dedu_edi_sell_trns       xsi             -- 控除データ作成用EDI売上実績振替
          ,xxcmm_cust_accounts            xca             -- 顧客追加情報
          ,fnd_lookup_values              flv             -- チェーン店
          ,fnd_lookup_values              flv2            -- データ種類
          ,xxcok_condition_recovery_temp  xcrt            -- 控除マスタリカバリ用ワークテーブル
          ,flvc1                          d_typ
          ,flvc3                          gyotai_sho
    WHERE  1=1
    AND    xsi.report_decision_flag      = cv_1
    AND    xsi.selling_trns_type         = cv_1
    AND    xca.customer_code             = xsi.cust_code
    AND    xca.business_low_type         = gyotai_sho.lookup_code
    AND    flv.lookup_type               = cv_lookup_chain_code
    AND    flv.lookup_code               = xca.intro_chain_code2
    AND    flv.language                  = USERENV('LANG')
    AND    flv.enabled_flag              = cv_y_flag
    AND    xcrt.enabled_flag_h           = cv_y_flag
    AND    flv2.lookup_type              = cv_lookup_dedu_code
    AND    flv2.lookup_code              = xcrt.data_type
    AND    flv2.language                 = USERENV('LANG')
    AND    flv2.enabled_flag             = cv_y_flag
    AND    flv2.attribute2               = d_typ.lookup_code
    AND    flv.attribute1                = xcrt.corp_CODE
    AND    xcrt.corp_code           IS NOT NULL
-- 2020/12/03 Ver1.1 MOD Start
    AND    xsi.selling_date        BETWEEN xcrt.start_date_active
                                       AND xcrt.end_date_active
--    AND    xsi.selling_date        BETWEEN xcrt.start_date_active
--               AND CASE WHEN xcrt.end_date_active < gd_prev_date 
--                     THEN xcrt.end_date_active
--                     ELSE gd_prev_date
--                   END
-- 2020/12/03 Ver1.1 MOD End
    AND    xcrt.enabled_flag_l           = cv_y_flag
    AND (  xsi.item_code                 = xcrt.item_code
    OR     xsi.product_class             = xcrt.product_class ) -- ★
-- 2020/12/03 Ver1.1 ADD Start
    AND    xsi.selling_trns_info_id     <= gn_sales_id_2
-- 2020/12/03 Ver1.1 ADD End
    ;
--
  -- カーソルレコード取得用
  g_selling_trns_rec          g_selling_trns_cur%ROWTYPE;
--
  -- 実績振替情報（振替割合）取得
  CURSOR g_actual_trns_cur
  IS
    WITH
     flvc1 AS
        ( SELECT /*+ MATERIALIZED */ lookup_code AS lookup_code
          FROM  fnd_lookup_values flvc
          WHERE flvc.lookup_type  = cv_lookup_ded_type_code  -- 控除タイプ
          AND   flvc.language     = USERENV('LANG')
          AND   flvc.enabled_flag = cv_y_flag
          AND   flvc.attribute1   = cv_y_flag            )     -- 販売控除作成対象
     ,flvc3 AS
        ( SELECT /*+ MATERIALIZED */ lookup_code AS lookup_code
          FROM  fnd_lookup_values flvc
          WHERE flvc.lookup_type  = cv_lookup_gyotai_code  -- 業態(小分類)
          AND   flvc.language     = USERENV('LANG')
          AND   flvc.enabled_flag = cv_y_flag
          AND   flvc.attribute2   = cv_y_flag            )   -- 販売控除作成対象外
    -- ①顧客
    SELECT /*+ leading(xcrt xdst xca flv2 flv) full(xcrt)
               use_nl(xdst) use_nl(xca) use_nl(flv) use_nl(flv2) */
           xdst.delivery_base_code                     delivery_base_code           -- 振替元拠点
          ,xdst.selling_from_cust_code                 selling_from_cust_code       -- 振替元顧客
          ,xdst.base_code                              base_code                    -- 振替先拠点
          ,xdst.cust_code                              cust_code                    -- 振替先顧客
          ,xdst.selling_date                           selling_date                 -- 売上計上日
          ,xdst.selling_trns_info_id                   selling_trns_info_id         -- 売上実績振替情報ID
          ,xdst.item_code                              item_code                    -- 品目コード
          ,xdst.unit_type                              unit_type                    -- 納品単位
          ,xdst.delivery_unit_price                    delivery_unit_price          -- 納品単価
          ,xdst.qty                                    qty                          -- 数量
          ,xdst.selling_amt_no_tax                     selling_amt_no_tax           -- 本体金額（税抜き）
          ,xdst.tax_code                               tax_code                     -- 消費税コード
          ,xdst.tax_rate                               tax_rate                     -- 消費税率
          ,xdst.selling_amt - xdst.selling_amt_no_tax  tax_amount                   -- 消費税額
          ,xcrt.condition_id                           condition_id                 -- 控除条件ID
          ,xcrt.condition_no                           condition_no                 -- 控除番号
          ,xcrt.corp_code                              corp_code                    -- 企業コード
          ,xcrt.deduction_chain_code                   deduction_chain_code         -- 控除用チェーンコード
          ,xcrt.customer_code                          customer_code                -- 顧客コード(条件)
          ,xcrt.data_type                              data_type                    -- データ種類
          ,xcrt.tax_code_con                           tax_code_con                 -- 税コード
          ,xcrt.tax_rate_con                           tax_rate_con                 -- 税率
          ,flv.attribute3                              attribute3                   -- 本部担当拠点(チェーン店)
          ,xca.sale_base_code                          sale_base_code               -- 売上拠点(顧客)
          ,xcrt.condition_line_id                      condition_line_id            -- 控除詳細ID
          ,xcrt.product_class                          product_class                -- 商品区分
          ,xcrt.item_code                              item_code_cond               -- 品目コード(条件)
          ,xcrt.uom_code                               uom_code                     -- 単位(条件)
          ,xcrt.target_category                        target_category              -- 対象区分
          ,xcrt.shop_pay_1                             shop_pay_1                   -- 店納(％)
          ,xcrt.material_rate_1                        material_rate_1              -- 料率(％)
          ,xcrt.condition_unit_price_en_2              condition_unit_price_en_2    -- 条件単価２(円)
          ,xcrt.accrued_en_3                           accrued_en_3                 -- 未収計３(円)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcrt.compensation_en_3                      compensation_en_3            -- 補填(円)
          ,xcrt.wholesale_margin_en_3                  wholesale_margin_en_3        -- 問屋マージン(円)
-- 2020/12/03 Ver1.1 ADD End
          ,xcrt.accrued_en_4                           accrued_en_4                 -- 未収計４(円)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcrt.just_condition_en_4                    just_condition_en_4          -- 今回条件(円)
          ,xcrt.wholesale_adj_margin_en_4              wholesale_adj_margin_en_4    -- 問屋マージン修正(円)
-- 2020/12/03 Ver1.1 ADD End
          ,xcrt.condition_unit_price_en_5              condition_unit_price_en_5    -- 条件単価５(円)
          ,xcrt.deduction_unit_price_en_6              deduction_unit_price_en_6    -- 控除単価(円)
          ,flv2.attribute2                             attribute2                   -- 控除タイプ
          ,xcrt.header_recovery_flag                   header_recovery_flag         -- ヘッダーリカバリ対象フラグ
          ,xcrt.line_recovery_flag                     line_recovery_flag           -- 明細リカバリ対象フラグ
    FROM
           xxcok_dedu_sell_trns_info      xdst                            -- 控除用実績振替情報
          ,xxcmm_cust_accounts            xca                             -- 顧客追加情報
          ,fnd_lookup_values              flv                             -- チェーン店
          ,fnd_lookup_values              flv2                            -- データ種類
          ,xxcok_condition_recovery_temp  xcrt
          ,flvc1                          d_typ
          ,flvc3                          gyotai_sho
    WHERE  xdst.selling_trns_type        = cv_0    -- 実績振替区分:振替割合
    AND    xdst.report_decision_flag     = cv_1    -- 速報確定フラグ:確定
    AND    xca.customer_code             = xdst.cust_code
    AND    xca.business_low_type         = gyotai_sho.lookup_code
    AND    flv.lookup_type(+)            = cv_lookup_chain_code
    AND    flv.lookup_code(+)            = xca.intro_chain_code2
    AND    flv.language(+)               = USERENV('LANG')
    AND    flv.enabled_flag(+)           = cv_y_flag
    AND    xcrt.enabled_flag_h            = cv_y_flag
    AND    flv2.lookup_type              = cv_lookup_dedu_code
    AND    flv2.lookup_code              = xcrt.data_type
    AND    flv2.language                 = USERENV('LANG')
    AND    flv2.enabled_flag             = cv_y_flag
    AND    flv2.attribute2               = d_typ.lookup_code
    AND    xdst.cust_code                = xcrt.customer_code
    AND    xcrt.customer_code       IS NOT NULL
-- 2020/12/03 Ver1.1 MOD Start
    AND    xdst.selling_date       BETWEEN xcrt.start_date_active
                                       AND xcrt.end_date_active
--    AND    xdst.selling_date       BETWEEN xcrt.start_date_active
--               AND CASE WHEN xcrt.end_date_active < gd_prev_month_date 
--                     THEN xcrt.end_date_active
--                     ELSE gd_prev_month_date
--                   END
-- 2020/12/03 Ver1.1 MOD End
    AND    xcrt.enabled_flag_l           = cv_y_flag
    AND   (xdst.item_code                = xcrt.item_code
    OR     xdst.product_class            = xcrt.product_class) -- ★
    UNION ALL
    -- ②控除用チェーン
    SELECT /*+ leading(xcrt xca xdst flv2 flv) full(xcrt)
               use_nl(xdst) use_nl(xca) use_nl(flv) use_nl(flv2) */
           xdst.delivery_base_code                     delivery_base_code           -- 振替元拠点
          ,xdst.selling_from_cust_code                 selling_from_cust_code       -- 振替元顧客
          ,xdst.base_code                              base_code                    -- 振替先拠点
          ,xdst.cust_code                              cust_code                    -- 振替先顧客
          ,xdst.selling_date                           selling_date                 -- 売上計上日
          ,xdst.selling_trns_info_id                   selling_trns_info_id         -- 売上実績振替情報ID
          ,xdst.item_code                              item_code                    -- 品目コード
          ,xdst.unit_type                              unit_type                    -- 納品単位
          ,xdst.delivery_unit_price                    delivery_unit_price          -- 納品単価
          ,xdst.qty                                    qty                          -- 数量
          ,xdst.selling_amt_no_tax                     selling_amt_no_tax           -- 本体金額（税抜き）
          ,xdst.tax_code                               tax_code                     -- 消費税コード
          ,xdst.tax_rate                               tax_rate                     -- 消費税率
          ,xdst.selling_amt - xdst.selling_amt_no_tax  tax_amount                   -- 消費税額
          ,xcrt.condition_id                           condition_id                 -- 控除条件ID
          ,xcrt.condition_no                           condition_no                 -- 控除番号
          ,xcrt.corp_code                              corp_code                    -- 企業コード
          ,xcrt.deduction_chain_code                   deduction_chain_code         -- 控除用チェーンコード
          ,xcrt.customer_code                          customer_code                -- 顧客コード(条件)
          ,xcrt.data_type                              data_type                    -- データ種類
          ,xcrt.tax_code_con                           tax_code_con                 -- 税コード
          ,xcrt.tax_rate_con                           tax_rate_con                 -- 税率
          ,flv.attribute3                              attribute3                   -- 本部担当拠点(チェーン店)
          ,xca.sale_base_code                          sale_base_code               -- 売上拠点(顧客)
          ,xcrt.condition_line_id                      condition_line_id            -- 控除詳細ID
          ,xcrt.product_class                          product_class                -- 商品区分
          ,xcrt.item_code                              item_code_cond               -- 品目コード(条件)
          ,xcrt.uom_code                               uom_code                     -- 単位(条件)
          ,xcrt.target_category                        target_category              -- 対象区分
          ,xcrt.shop_pay_1                             shop_pay_1                   -- 店納(％)
          ,xcrt.material_rate_1                        material_rate_1              -- 料率(％)
          ,xcrt.condition_unit_price_en_2              condition_unit_price_en_2    -- 条件単価２(円)
          ,xcrt.accrued_en_3                           accrued_en_3                 -- 未収計３(円)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcrt.compensation_en_3                      compensation_en_3            -- 補填(円)
          ,xcrt.wholesale_margin_en_3                  wholesale_margin_en_3        -- 問屋マージン(円)
-- 2020/12/03 Ver1.1 ADD End
          ,xcrt.accrued_en_4                           accrued_en_4                 -- 未収計４(円)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcrt.just_condition_en_4                    just_condition_en_4          -- 今回条件(円)
          ,xcrt.wholesale_adj_margin_en_4              wholesale_adj_margin_en_4    -- 問屋マージン修正(円)
-- 2020/12/03 Ver1.1 ADD End
          ,xcrt.condition_unit_price_en_5              condition_unit_price_en_5    -- 条件単価５(円)
          ,xcrt.deduction_unit_price_en_6              deduction_unit_price_en_6    -- 控除単価(円)
          ,flv2.attribute2                             attribute2                   -- 控除タイプ
          ,xcrt.header_recovery_flag                   header_recovery_flag         -- ヘッダーリカバリ対象フラグ
          ,xcrt.line_recovery_flag                     line_recovery_flag           -- 明細リカバリ対象フラグ
    FROM
           xxcok_dedu_sell_trns_info      xdst                            -- 控除用実績振替情報
          ,xxcmm_cust_accounts            xca                             -- 顧客追加情報
          ,fnd_lookup_values              flv                             -- チェーン店
          ,fnd_lookup_values              flv2                            -- データ種類
          ,xxcok_condition_recovery_temp  xcrt
          ,flvc1                          d_typ
          ,flvc3                          gyotai_sho
    WHERE  xdst.selling_trns_type        = cv_0    -- 実績振替区分:振替割合
    AND    xdst.report_decision_flag     = cv_1    -- 速報確定フラグ:確定
    AND    xca.customer_code             = xdst.cust_code
    AND    xca.business_low_type         = gyotai_sho.lookup_code
    AND    flv.lookup_type               = cv_lookup_chain_code
    AND    flv.lookup_code               = xca.intro_chain_code2
    AND    flv.language                  = USERENV('LANG')
    AND    flv.enabled_flag              = cv_y_flag
    AND    xcrt.enabled_flag_h           = cv_y_flag
    AND    flv2.lookup_type              = cv_lookup_dedu_code
    AND    flv2.lookup_code              = xcrt.data_type
    AND    flv2.language                 = USERENV('LANG')
    AND    flv2.enabled_flag             = cv_y_flag
    AND    flv2.attribute2               = d_typ.lookup_code
    AND    xca.intro_chain_code2          = xcrt.deduction_chain_code
    AND    xcrt.deduction_chain_code IS NOT NULL
-- 2020/12/03 Ver1.1 MOD Start
    AND    xdst.selling_date       BETWEEN xcrt.start_date_active
                                       AND xcrt.end_date_active
--    AND    xdst.selling_date        BETWEEN xcrt.start_date_active
--               AND CASE WHEN xcrt.end_date_active < gd_prev_month_date 
--                     THEN xcrt.end_date_active
--                     ELSE gd_prev_month_date
--                   END
-- 2020/12/03 Ver1.1 MOD End
    AND    xcrt.enabled_flag_l            = cv_y_flag
    AND   (xdst.item_code                = xcrt.item_code
    OR     xdst.product_class            = xcrt.product_class) -- ★
    UNION ALL
    -- ③企業
    SELECT /*+ leading(xcrt flv xca xdst flv2) full(xcrt)
               use_nl(xdst) use_nl(xca) use_nl(flv) use_nl(flv2) */
           xdst.delivery_base_code                     delivery_base_code           -- 振替元拠点
          ,xdst.selling_from_cust_code                 selling_from_cust_code       -- 振替元顧客
          ,xdst.base_code                              base_code                    -- 振替先拠点
          ,xdst.cust_code                              cust_code                    -- 振替先顧客
          ,xdst.selling_date                           selling_date                 -- 売上計上日
          ,xdst.selling_trns_info_id                   selling_trns_info_id         -- 売上実績振替情報ID
          ,xdst.item_code                              item_code                    -- 品目コード
          ,xdst.unit_type                              unit_type                    -- 納品単位
          ,xdst.delivery_unit_price                    delivery_unit_price          -- 納品単価
          ,xdst.qty                                    qty                          -- 数量
          ,xdst.selling_amt_no_tax                     selling_amt_no_tax           -- 本体金額（税抜き）
          ,xdst.tax_code                               tax_code                     -- 消費税コード
          ,xdst.tax_rate                               tax_rate                     -- 消費税率
          ,xdst.selling_amt - xdst.selling_amt_no_tax  tax_amount                   -- 消費税額
          ,xcrt.condition_id                           condition_id                 -- 控除条件ID
          ,xcrt.condition_no                           condition_no                 -- 控除番号
          ,xcrt.corp_code                              corp_code                    -- 企業コード
          ,xcrt.deduction_chain_code                   deduction_chain_code         -- 控除用チェーンコード
          ,xcrt.customer_code                          customer_code                -- 顧客コード(条件)
          ,xcrt.data_type                              data_type                    -- データ種類
          ,xcrt.tax_code_con                           tax_code_con                 -- 税コード
          ,xcrt.tax_rate_con                           tax_rate_con                 -- 税率
          ,flv.attribute3                              attribute3                   -- 本部担当拠点(チェーン店)
          ,xca.sale_base_code                          sale_base_code               -- 売上拠点(顧客)
          ,xcrt.condition_line_id                      condition_line_id            -- 控除詳細ID
          ,xcrt.product_class                          product_class                -- 商品区分
          ,xcrt.item_code                              item_code_cond               -- 品目コード(条件)
          ,xcrt.uom_code                               uom_code                     -- 単位(条件)
          ,xcrt.target_category                        target_category              -- 対象区分
          ,xcrt.shop_pay_1                             shop_pay_1                   -- 店納(％)
          ,xcrt.material_rate_1                        material_rate_1              -- 料率(％)
          ,xcrt.condition_unit_price_en_2              condition_unit_price_en_2    -- 条件単価２(円)
          ,xcrt.accrued_en_3                           accrued_en_3                 -- 未収計３(円)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcrt.compensation_en_3                      compensation_en_3            -- 補填(円)
          ,xcrt.wholesale_margin_en_3                  wholesale_margin_en_3        -- 問屋マージン(円)
-- 2020/12/03 Ver1.1 ADD End
          ,xcrt.accrued_en_4                           accrued_en_4                 -- 未収計４(円)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcrt.just_condition_en_4                    just_condition_en_4          -- 今回条件(円)
          ,xcrt.wholesale_adj_margin_en_4              wholesale_adj_margin_en_4    -- 問屋マージン修正(円)
-- 2020/12/03 Ver1.1 ADD End
          ,xcrt.condition_unit_price_en_5              condition_unit_price_en_5    -- 条件単価５(円)
          ,xcrt.deduction_unit_price_en_6              deduction_unit_price_en_6    -- 控除単価(円)
          ,flv2.attribute2                             attribute2                   -- 控除タイプ
          ,xcrt.header_recovery_flag                   header_recovery_flag         -- ヘッダーリカバリ対象フラグ
          ,xcrt.line_recovery_flag                     line_recovery_flag           -- 明細リカバリ対象フラグ
    FROM
           xxcok_dedu_sell_trns_info      xdst                            -- 控除用実績振替情報
          ,xxcmm_cust_accounts            xca                             -- 顧客追加情報
          ,fnd_lookup_values              flv                             -- チェーン店
          ,fnd_lookup_values              flv2                            -- データ種類
          ,xxcok_condition_recovery_temp  xcrt
          ,flvc1                          d_typ
          ,flvc3                          gyotai_sho
    WHERE  xdst.selling_trns_type        = cv_0    -- 実績振替区分:振替割合
    AND    xdst.report_decision_flag     = cv_1    -- 速報確定フラグ:確定
    AND    xca.customer_code             = xdst.cust_code
    AND    xca.business_low_type         = gyotai_sho.lookup_code
    AND    flv.lookup_type               = cv_lookup_chain_code
    AND    flv.lookup_code               = xca.intro_chain_code2
    AND    flv.language                  = USERENV('LANG')
    AND    flv.enabled_flag              = cv_y_flag
    AND    xcrt.enabled_flag_h           = cv_y_flag
    AND    flv2.lookup_type              = cv_lookup_dedu_code
    AND    flv2.lookup_code              = xcrt.data_type
    AND    flv2.language                 = USERENV('LANG')
    AND    flv2.enabled_flag             = cv_y_flag
    AND    flv2.attribute2               = d_typ.lookup_code
    AND    flv.attribute1                = xcrt.corp_CODE
    AND    xcrt.corp_code           IS NOT NULL
-- 2020/12/03 Ver1.1 MOD Start
    AND    xdst.selling_date       BETWEEN xcrt.start_date_active
                                       AND xcrt.end_date_active
--    AND    xdst.selling_date       BETWEEN xcrt.start_date_active
--               AND CASE WHEN xcrt.end_date_active < gd_prev_month_date 
--                     THEN xcrt.end_date_active
--                     ELSE gd_prev_month_date
--                   END
-- 2020/12/03 Ver1.1 MOD End
    AND    xcrt.enabled_flag_l            = cv_y_flag
    AND   (xdst.item_code                = xcrt.item_code
    OR     xdst.product_class            = xcrt.product_class) -- ★
  ;
--
  -- カーソルレコード取得用
  g_actual_trns_rec          g_actual_trns_cur%ROWTYPE;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init( ov_errbuf  OUT VARCHAR2    -- エラー・メッセージ           --# 固定 #
                 ,ov_retcode OUT VARCHAR2    -- リターン・コード             --# 固定 #
                 ,ov_errmsg  OUT VARCHAR2    -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- プログラム名
--
--#########################  固定ローカル変数宣言部 START  #########################
--
    lv_errbuf  VARCHAR2(5000)      DEFAULT NULL;  -- エラー・メッセージ
    lv_retcode VARCHAR2(1)         DEFAULT NULL;  -- リターン・コード
    lv_errmsg  VARCHAR2(5000)      DEFAULT NULL;  -- ユーザー・エラー・メッセージ
--
--##################################  固定部 END  ##################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
  BEGIN
--
--#########################  固定ステータス初期化部 START  #########################
--
    ov_retcode := cv_status_normal;
--
--##################################  固定部 END  ##################################
--
-- 2020/12/03 Ver1.1 ADD Start
    --========================================
    -- 1.最大販売実績明細ID(販売実績情報)取得処理
    --========================================
    BEGIN
      SELECT MAX(xsdc.last_processing_id)          -- 前回処理ID(販売実績明細ID)
      INTO   gn_sales_id_1
      FROM   xxcok_sales_deduction_control  xsdc   -- 販売控除連携管理情報
      WHERE  xsdc.control_flag  = cv_s_flag        -- 管理情報フラグ:販売実績情報
      ;
--
    EXCEPTION
      WHEN  OTHERS THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg( cv_xxcok_short_name
                                              , cv_msg_id_error
                                               );
        lv_errbuf :=  lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- 前回処理ID(販売実績明細ID)が取得できなかった場合
    IF  (gn_sales_id_1 IS NULL) THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg( cv_xxcok_short_name
                                              , cv_msg_id_error
                                               );
        lv_errbuf :=  lv_errmsg;
        RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 2.最大売上実績振替情報ID(実績振替（EDI）)取得処理
    --========================================
    BEGIN
      SELECT MAX(xsdc.last_processing_id)            -- 前回処理ID(売上実績振替情報ID)
      INTO   gn_sales_id_2
      FROM   xxcok_sales_deduction_control  xsdc     -- 販売控除連携管理情報
      WHERE  xsdc.control_flag  = cv_t_flag          -- 管理情報フラグ:実績振替
      ;
--
    EXCEPTION
      WHEN  OTHERS THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg( cv_xxcok_short_name
                                              , cv_msg_id_error
                                               );
        lv_errbuf :=  lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- 前回処理ID(売上実績振替情報ID)が取得できなかった場合
    IF  (gn_sales_id_2 IS NULL) THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg( cv_xxcok_short_name
                                              , cv_msg_id_error
                                               );
        lv_errbuf :=  lv_errmsg;
        RAISE global_api_expt;
    END IF;
-- 2020/12/03 Ver1.1 ADD End
--
    --========================================
    -- 3.業務日付取得処理
    --========================================
    gd_proc_date := TRUNC( xxccp_common_pkg2.get_process_date );
--
    IF ( gd_proc_date IS NULL ) THEN
      lv_errmsg  :=  xxccp_common_pkg.get_msg( iv_application => cv_xxcok_short_name
                                              ,iv_name        => cv_msg_proc_date_err
                                              );
--
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- 2020/12/03 Ver1.1 DEL Start
--    --========================================
--    -- 3.前月末日、前日の取得
--    --========================================
--    gd_prev_date       := gd_proc_date - 1 ;
--    gd_prev_month_date := trunc(gd_proc_date,'MM') - 1 ;
-- 2020/12/03 Ver1.1 DEL End
--
  EXCEPTION
--
--############################    固定例外処理部 START  ############################
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
--##################################  固定部 END  ##################################
--
  END init;
--
--
  /***********************************************************************************
   * Procedure Name   : sales_deduction_delete
   * Description      : A-3.販売控除取消処理
   ***********************************************************************************/
  PROCEDURE sales_deduction_delete( in_condition_line_id IN  NUMBER    -- 控除詳細ID
                                   ,iv_syori_type        IN  VARCHAR2  -- 処理区分
                                   ,ov_errbuf            OUT VARCHAR2  -- エラー・メッセージ           -- # 固定 #
                                   ,ov_retcode           OUT VARCHAR2  -- リターン・コード             -- # 固定 #
                                   ,ov_errmsg            OUT VARCHAR2  -- ユーザー・エラー・メッセージ -- # 固定 #
                                   )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name      CONSTANT VARCHAR2(100) := 'sales_deduction_delete';  -- プログラム名
--
--###############################  固定ステータス初期化部 START  ###############################
--
    lv_errbuf        VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode       VARCHAR2(1);     -- リターン・コード
    lv_errmsg        VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--########################################  固定部 END  ########################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    ln_del_cnt       NUMBER;          -- エラー件数カウント用
--
  BEGIN
--
    ln_del_cnt := 0;
--
    -- 処理区分パラメータがNULLの場合
    IF iv_syori_type IS NULL  THEN
--
      SELECT COUNT(*) cnt
      INTO   ln_del_cnt
      FROM   xxcok_sales_deduction  xsd
      WHERE  xsd.recon_slip_num     IS NULL                                -- 支払伝票番号
      AND    xsd.gl_if_flag         IN ( cv_y_flag ,cv_n_flag )            -- GL連携フラグ(Y:連携済、N:未連携)
-- 2020/12/03 Ver1.1 ADD Start
      AND    xsd.source_category    IN ( cv_s_flag ,cv_t_flag
                                        ,cv_v_flag ,cv_f_flag)             -- 作成元区分
      AND  ( xsd.report_decision_flag   IS NULL         OR
             xsd.report_decision_flag    = cv_deci_flag )                  -- 速報確定フラグ
-- 2020/12/03 Ver1.1 ADD End
      AND    xsd.status              = cv_n_flag                           -- ステータス(N：新規)
      AND    xsd.condition_line_id   = in_condition_line_id                -- 控除詳細ID
-- 2021/09/17 Ver1.4 ADD Start
      AND    xsd.request_id          <> cn_request_id                       -- 要求ID
-- 2021/09/17 Ver1.4 ADD Start
      ;
--
      gn_del_cnt := gn_del_cnt + ln_del_cnt;
--
      -- 既存の控除データを論理削除
      UPDATE xxcok_sales_deduction  xsd                                  -- 販売控除情報
      SET    xsd.status                  = cv_c_flag                                -- ステータス
            ,xsd.gl_if_flag              = CASE
                                             WHEN xsd.gl_if_flag  = cv_n_flag THEN
                                               cv_u_flag
                                             ELSE
                                               cv_r_flag
                                           END                                      -- GL連携フラグ
            ,xsd.recovery_del_date       = gd_proc_date                             -- リカバリー日付
            ,xsd.cancel_flag             = cv_y_flag                                -- キャンセルフラグ
            ,xsd.recovery_del_request_id = cn_request_id                            -- リカバリデータ削除時要求ID
            ,xsd.cancel_user             = cn_created_by                            -- 取消ユーザID
            ,xsd.last_updated_by         = cn_last_updated_by                       -- 最終更新者
            ,xsd.last_update_date        = cd_last_update_date                      -- 最終更新日
            ,xsd.last_update_login       = cn_last_update_login                     -- 最終更新ログイン
            ,xsd.request_id              = cn_request_id                            -- 要求ID
            ,xsd.program_application_id  = cn_program_application_id                -- コンカレント・プログラム・アプリID
            ,xsd.program_id              = cn_program_id                            -- コンカレント・プログラムID
            ,xsd.program_update_date     = cd_program_update_date                   -- プログラム更新日
      WHERE  xsd.recon_slip_num     IS NULL                                -- 支払伝票番号
      AND    xsd.source_category    IN ( cv_s_flag ,cv_t_flag
                                        ,cv_v_flag ,cv_f_flag)             -- 作成元区分
      AND    xsd.gl_if_flag         IN ( cv_y_flag ,cv_n_flag )            -- GL連携フラグ(Y:連携済、N:未連携)
-- 2020/12/03 Ver1.1 ADD Start
      AND  ( xsd.report_decision_flag   IS NULL         OR
             xsd.report_decision_flag    = cv_deci_flag )                  -- 速報確定フラグ
-- 2020/12/03 Ver1.1 ADD End
      AND    xsd.status              = cv_n_flag                           -- ステータス(N：新規)
      AND    xsd.condition_line_id   = in_condition_line_id                -- 控除詳細ID
-- 2021/09/17 Ver1.4 ADD Start
      AND    xsd.request_id          <> cn_request_id                       -- 要求ID
-- 2021/09/17 Ver1.4 ADD Start
      ;
    -- 処理区分パラメータがNULL以外の場合
    ELSE
--
      SELECT COUNT(*) cnt
      INTO   ln_del_cnt
      FROM   xxcok_sales_deduction  xsd
      WHERE  xsd.recon_slip_num     IS NULL                                -- 支払伝票番号
      AND    xsd.source_category     = iv_syori_type                       -- 作成元区分
-- 2020/12/03 Ver1.1 ADD Start
      AND  ( xsd.report_decision_flag   IS NULL         OR
             xsd.report_decision_flag    = cv_deci_flag )                  -- 速報確定フラグ
-- 2020/12/03 Ver1.1 ADD End
      AND    xsd.gl_if_flag         IN ( cv_y_flag ,cv_n_flag )            -- GL連携フラグ(Y:連携済、N:未連携)
      AND    xsd.status              = cv_n_flag                           -- ステータス(N：新規)
      AND    xsd.condition_line_id   = in_condition_line_id                -- 控除詳細ID
      ;
--
      gn_del_cnt := gn_del_cnt + ln_del_cnt;
--
      UPDATE xxcok_sales_deduction  xsd                                  -- 販売控除情報
      SET    xsd.status                  = cv_c_flag                                -- ステータス
            ,xsd.gl_if_flag              = CASE
                                             WHEN xsd.gl_if_flag  = cv_n_flag THEN
                                               cv_u_flag
                                             ELSE
                                               cv_r_flag
                                           END                                      -- GL連携フラグ
            ,xsd.recovery_del_date       = gd_proc_date                             -- リカバリー日付
            ,xsd.cancel_flag             = cv_y_flag                                -- キャンセルフラグ
            ,xsd.recovery_del_request_id = cn_request_id                            -- リカバリデータ削除時要求ID
            ,xsd.cancel_user             = cn_created_by                            -- 取消ユーザID
            ,xsd.last_updated_by         = cn_last_updated_by                       -- 最終更新者
            ,xsd.last_update_date        = cd_last_update_date                      -- 最終更新日
            ,xsd.last_update_login       = cn_last_update_login                     -- 最終更新ログイン
            ,xsd.request_id              = cn_request_id                            -- 要求ID
            ,xsd.program_application_id  = cn_program_application_id                -- コンカレント・プログラム・アプリID
            ,xsd.program_id              = cn_program_id                            -- コンカレント・プログラムID
            ,xsd.program_update_date     = cd_program_update_date                   -- プログラム更新日
      WHERE  xsd.recon_slip_num     IS NULL                                -- 支払伝票番号
      AND    xsd.source_category     = iv_syori_type                       -- 作成元区分
-- 2020/12/03 Ver1.1 ADD Start
      AND  ( xsd.report_decision_flag   IS NULL         OR
             xsd.report_decision_flag    = cv_deci_flag )                  -- 速報確定フラグ
-- 2020/12/03 Ver1.1 ADD End
      AND    xsd.gl_if_flag         IN ( cv_y_flag ,cv_n_flag )            -- GL連携フラグ(Y:連携済、N:未連携)
      AND    xsd.status              = cv_n_flag                           -- ステータス(N：新規)
      AND    xsd.condition_line_id   = in_condition_line_id                -- 控除詳細ID
      ;
    END IF;
--
  EXCEPTION
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--##################################  固定部 END  ##################################
--
  END sales_deduction_delete;
--
  /**********************************************************************************
   * Procedure Name   : calculation_data
   * Description      : A-5.控除データ算出
   ***********************************************************************************/
  PROCEDURE calculation_data( iv_syori_type  IN   VARCHAR2  -- 処理区分
                            , ov_errbuf      OUT  VARCHAR2  -- エラー・メッセージ           -- # 固定 #
                            , ov_retcode     OUT  VARCHAR2  -- リターン・コード             -- # 固定 #
                            , ov_errmsg      OUT  VARCHAR2  -- ユーザー・エラー・メッセージ -- # 固定 #
                             )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name      CONSTANT VARCHAR2(100) := 'calculation_data';  -- プログラム名
--
    -- ==============================
    -- ローカル変数
    -- ==============================
    lv_base_code    VARCHAR2(4);                            -- 担当拠点
    lv_out_msg      VARCHAR2(1000)      DEFAULT NULL;       -- メッセージ出力変数
    lb_retcode      BOOLEAN             DEFAULT NULL;       -- メッセージ出力関数の戻り値
--
--###############################  固定ステータス初期化部 START  ###############################
--
    lv_errbuf        VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode       VARCHAR2(1);     -- リターン・コード
    lv_errmsg        VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--########################################  固定部 END  ########################################
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- 販売実績の場合
    IF ( iv_syori_type = cv_s_flag ) THEN
      -- ============================================================
      -- 共通関数 控除額算出
      -- ============================================================
      xxcok_common2_pkg.calculate_deduction_amount_p(
         ov_errbuf                     =>  lv_errbuf                                  -- エラーバッファ
        ,ov_retcode                    =>  lv_retcode                                 -- リターンコード
        ,ov_errmsg                     =>  lv_errmsg                                  -- エラーメッセージ
        ,iv_item_code                  =>  g_sales_exp_rec.div_item_code              -- 品目コード
        ,iv_sales_uom_code             =>  g_sales_exp_rec.dlv_uom_code               -- 販売単位
        ,in_sales_quantity             =>  g_sales_exp_rec.dlv_qty                    -- 販売数量
        ,in_sale_pure_amount           =>  g_sales_exp_rec.pure_amount                -- 売上本体金額
        ,iv_tax_code_trn               =>  g_sales_exp_rec.tax_code                   -- 税コード(TRN)
        ,in_tax_rate_trn               =>  g_sales_exp_rec.tax_rate                   -- 税率(TRN)
        ,iv_deduction_type             =>  g_sales_exp_rec.attribute2                 -- 控除タイプ
        ,iv_uom_code                   =>  g_sales_exp_rec.uom_code                   -- 単位(条件)
        ,iv_target_category            =>  g_sales_exp_rec.target_category            -- 対象区分
        ,in_shop_pay_1                 =>  g_sales_exp_rec.shop_pay_1                 -- 店納(％)
        ,in_material_rate_1            =>  g_sales_exp_rec.material_rate_1            -- 料率(％)
        ,in_condition_unit_price_en_2  =>  g_sales_exp_rec.condition_unit_price_en_2  -- 条件単価２(円)
        ,in_accrued_en_3               =>  g_sales_exp_rec.accrued_en_3               -- 未収計３(円)
-- 2020/12/03 Ver1.1 ADD Start
        ,in_compensation_en_3          =>  g_sales_exp_rec.compensation_en_3          -- 補填(円)
        ,in_wholesale_margin_en_3      =>  g_sales_exp_rec.wholesale_margin_en_3      -- 問屋マージン(円)
-- 2020/12/03 Ver1.1 ADD End
        ,in_accrued_en_4               =>  g_sales_exp_rec.accrued_en_4               -- 未収計４(円)
-- 2020/12/03 Ver1.1 ADD Start
        ,in_just_condition_en_4        =>  g_sales_exp_rec.just_condition_en_4        -- 今回条件(円)
        ,in_wholesale_adj_margin_en_4  =>  g_sales_exp_rec.wholesale_adj_margin_en_4  -- 問屋マージン修正(円)
-- 2020/12/03 Ver1.1 ADD End
        ,in_condition_unit_price_en_5  =>  g_sales_exp_rec.condition_unit_price_en_5  -- 条件単価５(円)
        ,in_deduction_unit_price_en_6  =>  g_sales_exp_rec.deduction_unit_price_en_6  -- 控除単価(円)
        ,iv_tax_code_mst               =>  g_sales_exp_rec.tax_code_con               -- 税コード(MST)
        ,in_tax_rate_mst               =>  g_sales_exp_rec.tax_rate_con               -- 税率(MST)
        ,ov_deduction_uom_code         =>  gv_dedu_uom_code                           -- 控除単位
        ,on_deduction_unit_price       =>  gn_dedu_unit_price                         -- 控除単価
        ,on_deduction_quantity         =>  gn_dedu_quantity                           -- 控除数量
        ,on_deduction_amount           =>  gn_dedu_amount                             -- 控除額
-- 2020/12/03 Ver1.1 ADD Start
        ,on_compensation               =>  gn_compensation                            -- 補填
        ,on_margin                     =>  gn_margin                                  -- 問屋マージン
        ,on_sales_promotion_expenses   =>  gn_sales_promotion_expenses                -- 拡売
        ,on_margin_reduction           =>  gn_margin_reduction                        -- 問屋マージン減額
-- 2020/12/03 Ver1.1 ADD End
        ,on_deduction_tax_amount       =>  gn_dedu_tax_amount                         -- 控除税額
        ,ov_tax_code                   =>  gv_tax_code                                -- 税コード
        ,on_tax_rate                   =>  gn_tax_rate                                -- 税率
      );
--
      -- 共通関数にてエラーが発生した場合
      IF  lv_retcode  !=  cv_status_normal  THEN
--
        -- 企業コードがNULL以外の場合
        IF  g_sales_exp_rec.corp_code IS NOT NULL  THEN
--
          -- 本部担当拠点(企業)を取得
          SELECT MAX(ffv.attribute2)
          INTO   lv_base_code
          FROM   fnd_flex_values     ffv
                ,fnd_flex_value_sets ffvs
          WHERE  ffvs.flex_value_set_name  = cv_business_type
          AND    ffv.flex_value_set_id     = ffvs.flex_value_set_id
          AND    ffv.flex_value            = g_sales_exp_rec.corp_code
          ;
--
        -- 控除用チェーンコードがNULL以外の場合
        ELSIF g_sales_exp_rec.deduction_chain_code IS  NOT NULL  THEN
          -- 本部担当拠点(チェーン店)を取得
          lv_base_code  :=  g_sales_exp_rec.chain_base;
--
        -- 顧客コード(条件)がNULL以外の場合
        ELSIF g_sales_exp_rec.customer_code IS  NOT NULL  THEN
          -- 売上拠点(顧客)を取得
          lv_base_code  :=  g_sales_exp_rec.cust_base;
        END IF;
--
        ov_retcode := cv_status_warn;
        lv_out_msg := xxccp_common_pkg.get_msg(
                        cv_xxcok_short_name
                      , cv_msg_cal_error
                      , cv_tkn_source_line_id
                      , g_sales_exp_rec.sales_exp_line_id
                      , cv_tkn_item_code
                      , g_sales_exp_rec.div_item_code
                      , cv_tkn_sales_uom_code
                      , g_sales_exp_rec.dlv_uom_code
                      , cv_tkn_condition_no
                      , g_sales_exp_rec.condition_no
                      , cv_tkn_base_code
                      , lv_base_code
                      , cv_tkn_errmsg
                      , lv_errmsg
                      );
        lb_retcode := xxcok_common_pkg.put_message_f( FND_FILE.OUTPUT    -- 出力区分
                                                     ,lv_out_msg         -- メッセージ
                                                     ,1                  -- 改行
                                                     );
      END IF;
--
    -- 実績振替(EDI)の場合
    ELSIF ( iv_syori_type = cv_t_flag ) THEN
      xxcok_common2_pkg.calculate_deduction_amount_p(
         ov_errbuf                     =>  lv_errbuf                                     -- エラーバッファ
        ,ov_retcode                    =>  lv_retcode                                    -- リターンコード
        ,ov_errmsg                     =>  lv_errmsg                                     -- エラーメッセージ
        ,iv_item_code                  =>  g_selling_trns_rec.item_code                  -- 品目コード
        ,iv_sales_uom_code             =>  g_selling_trns_rec.unit_type                  -- 販売単位
        ,in_sales_quantity             =>  g_selling_trns_rec.qty                        -- 販売数量
        ,in_sale_pure_amount           =>  g_selling_trns_rec.selling_amt_no_tax         -- 売上本体金額
        ,iv_tax_code_trn               =>  g_selling_trns_rec.tax_code                   -- 税コード(TRN)
        ,in_tax_rate_trn               =>  g_selling_trns_rec.tax_rate                   -- 税率(TRN)
        ,iv_deduction_type             =>  g_selling_trns_rec.attribute2                 -- 控除タイプ
        ,iv_uom_code                   =>  g_selling_trns_rec.uom_code                   -- 単位(条件)
        ,iv_target_category            =>  g_selling_trns_rec.target_category            -- 対象区分
        ,in_shop_pay_1                 =>  g_selling_trns_rec.shop_pay_1                 -- 店納(％)
        ,in_material_rate_1            =>  g_selling_trns_rec.material_rate_1            -- 料率(％)
        ,in_condition_unit_price_en_2  =>  g_selling_trns_rec.condition_unit_price_en_2  -- 条件単価２(円)
        ,in_accrued_en_3               =>  g_selling_trns_rec.accrued_en_3               -- 未収計３(円)
-- 2020/12/03 Ver1.1 ADD Start
        ,in_compensation_en_3          =>  g_selling_trns_rec.compensation_en_3          -- 補填(円)
        ,in_wholesale_margin_en_3      =>  g_selling_trns_rec.wholesale_margin_en_3      -- 問屋マージン(円)
-- 2020/12/03 Ver1.1 ADD End
        ,in_accrued_en_4               =>  g_selling_trns_rec.accrued_en_4               -- 未収計４(円)
-- 2020/12/03 Ver1.1 ADD Start
        ,in_just_condition_en_4        =>  g_selling_trns_rec.just_condition_en_4        -- 今回条件(円)
        ,in_wholesale_adj_margin_en_4  =>  g_selling_trns_rec.wholesale_adj_margin_en_4  -- 問屋マージン修正(円)
-- 2020/12/03 Ver1.1 ADD End
        ,in_condition_unit_price_en_5  =>  g_selling_trns_rec.condition_unit_price_en_5  -- 条件単価５(円)
        ,in_deduction_unit_price_en_6  =>  g_selling_trns_rec.deduction_unit_price_en_6  -- 控除単価(円)
        ,iv_tax_code_mst               =>  g_selling_trns_rec.tax_code_con               -- 税コード(MST)
        ,in_tax_rate_mst               =>  g_selling_trns_rec.tax_rate_con               -- 税率(MST)
        ,ov_deduction_uom_code         =>  gv_dedu_uom_code                              -- 控除単位
        ,on_deduction_unit_price       =>  gn_dedu_unit_price                            -- 控除単価
        ,on_deduction_quantity         =>  gn_dedu_quantity                              -- 控除数量
        ,on_deduction_amount           =>  gn_dedu_amount                                -- 控除額
-- 2020/12/03 Ver1.1 ADD Start
        ,on_compensation               =>  gn_compensation                               -- 補填
        ,on_margin                     =>  gn_margin                                     -- 問屋マージン
        ,on_sales_promotion_expenses   =>  gn_sales_promotion_expenses                   -- 拡売
        ,on_margin_reduction           =>  gn_margin_reduction                           -- 問屋マージン減額
-- 2020/12/03 Ver1.1 ADD End
        ,on_deduction_tax_amount       =>  gn_dedu_tax_amount                            -- 控除税額
        ,ov_tax_code                   =>  gv_tax_code                                  -- 税コード
        ,on_tax_rate                   =>  gn_tax_rate                                  -- 税率
      );
--
      -- 共通関数にてエラーが発生した
      IF  lv_retcode  !=  cv_status_normal  THEN
--
        -- 企業コードがNULL以外の場合
        IF  g_selling_trns_rec.corp_code IS NOT NULL  THEN
--
          -- 本部担当拠点(企業)を取得
          SELECT MAX(ffv.attribute2)
          INTO   lv_base_code
          FROM   fnd_flex_values     ffv
                ,fnd_flex_value_sets ffvs
          WHERE  ffvs.flex_value_set_name  = cv_business_type
          AND    ffv.flex_value_set_id     = ffvs.flex_value_set_id
          AND    ffv.flex_value            = g_selling_trns_rec.corp_code
          ;
--
        -- 控除用チェーンコードがNULL以外の場合
        ELSIF g_selling_trns_rec.deduction_chain_code IS  NOT NULL  THEN
          -- 本部担当拠点(チェーン店)を取得
          lv_base_code  :=  g_selling_trns_rec.attribute3;
--
        -- 顧客コード(条件)がNULL以外の場合
        ELSIF g_selling_trns_rec.customer_code IS  NOT NULL  THEN
          -- 売上拠点(顧客)を取得
          lv_base_code  :=  g_selling_trns_rec.sale_base_code;
        END IF;
--
        ov_retcode := cv_status_warn;
        lv_out_msg := xxccp_common_pkg.get_msg(
                        cv_xxcok_short_name
                      , cv_msg_cal_error
                      , cv_tkn_source_line_id
                      , g_selling_trns_rec.selling_trns_info_id
                      , cv_tkn_item_code
                      , g_selling_trns_rec.item_code
                      , cv_tkn_sales_uom_code
                      , g_selling_trns_rec.unit_type
                      , cv_tkn_condition_no
                      , g_selling_trns_rec.condition_no
                      , cv_tkn_base_code
                      , lv_base_code
                      , cv_tkn_errmsg
                      , lv_errmsg
                      );
        lb_retcode := xxcok_common_pkg.put_message_f( FND_FILE.OUTPUT    -- 出力区分
                                                     ,lv_out_msg         -- メッセージ
                                                     ,1                  -- 改行
                                                     );
      END IF;
--
    -- 実績振替(振替割合)の場合
    ELSIF ( iv_syori_type = cv_v_flag ) THEN
      xxcok_common2_pkg.calculate_deduction_amount_p(
         ov_errbuf                     =>  lv_errbuf                                    -- エラーバッファ
        ,ov_retcode                    =>  lv_retcode                                   -- リターンコード
        ,ov_errmsg                     =>  lv_errmsg                                    -- エラーメッセージ
        ,iv_item_code                  =>  g_actual_trns_rec.item_code                  -- 品目コード
        ,iv_sales_uom_code             =>  g_actual_trns_rec.unit_type                  -- 販売単位
        ,in_sales_quantity             =>  g_actual_trns_rec.qty                        -- 販売数量
        ,in_sale_pure_amount           =>  g_actual_trns_rec.selling_amt_no_tax         -- 売上本体金額
        ,iv_tax_code_trn               =>  g_actual_trns_rec.tax_code                   -- 税コード(TRN)
        ,in_tax_rate_trn               =>  g_actual_trns_rec.tax_rate                   -- 税率(TRN)
        ,iv_deduction_type             =>  g_actual_trns_rec.attribute2                 -- 控除タイプ
        ,iv_uom_code                   =>  g_actual_trns_rec.uom_code                   -- 単位(条件)
        ,iv_target_category            =>  g_actual_trns_rec.target_category            -- 対象区分
        ,in_shop_pay_1                 =>  g_actual_trns_rec.shop_pay_1                 -- 店納(％)
        ,in_material_rate_1            =>  g_actual_trns_rec.material_rate_1            -- 料率(％)
        ,in_condition_unit_price_en_2  =>  g_actual_trns_rec.condition_unit_price_en_2  -- 条件単価２(円)
        ,in_accrued_en_3               =>  g_actual_trns_rec.accrued_en_3               -- 未収計３(円)
-- 2020/12/03 Ver1.1 ADD Start
        ,in_compensation_en_3          =>  g_actual_trns_rec.compensation_en_3          -- 補填(円)
        ,in_wholesale_margin_en_3      =>  g_actual_trns_rec.wholesale_margin_en_3      -- 問屋マージン(円)
-- 2020/12/03 Ver1.1 ADD End
        ,in_accrued_en_4               =>  g_actual_trns_rec.accrued_en_4               -- 未収計４(円)
-- 2020/12/03 Ver1.1 ADD Start
        ,in_just_condition_en_4        =>  g_actual_trns_rec.just_condition_en_4        -- 今回条件(円)
        ,in_wholesale_adj_margin_en_4  =>  g_actual_trns_rec.wholesale_adj_margin_en_4  -- 問屋マージン修正(円)
-- 2020/12/03 Ver1.1 ADD End
        ,in_condition_unit_price_en_5  =>  g_actual_trns_rec.condition_unit_price_en_5  -- 条件単価５(円)
        ,in_deduction_unit_price_en_6  =>  g_actual_trns_rec.deduction_unit_price_en_6  -- 控除単価(円)
        ,iv_tax_code_mst               =>  g_actual_trns_rec.tax_code_con               -- 税コード(MST)
        ,in_tax_rate_mst               =>  g_actual_trns_rec.tax_rate_con               -- 税率(MST)
        ,ov_deduction_uom_code         =>  gv_dedu_uom_code                             -- 控除単位
        ,on_deduction_unit_price       =>  gn_dedu_unit_price                           -- 控除単価
        ,on_deduction_quantity         =>  gn_dedu_quantity                             -- 控除数量
        ,on_deduction_amount           =>  gn_dedu_amount                               -- 控除額
-- 2020/12/03 Ver1.1 ADD Start
        ,on_compensation               =>  gn_compensation                              -- 補填
        ,on_margin                     =>  gn_margin                                    -- 問屋マージン
        ,on_sales_promotion_expenses   =>  gn_sales_promotion_expenses                  -- 拡売
        ,on_margin_reduction           =>  gn_margin_reduction                          -- 問屋マージン減額
-- 2020/12/03 Ver1.1 ADD End
        ,on_deduction_tax_amount       =>  gn_dedu_tax_amount                           -- 控除税額
        ,ov_tax_code                   =>  gv_tax_code                                  -- 税コード
        ,on_tax_rate                   =>  gn_tax_rate                                  -- 税率
      );
--
      -- 共通関数にてエラーが発生した
      IF  lv_retcode  !=  cv_status_normal  THEN
--
        -- 企業コードがNULL以外の場合
        IF  g_actual_trns_rec.corp_code IS NOT NULL  THEN
--
          -- 本部担当拠点(企業)を取得
          SELECT MAX(ffv.attribute2)
          INTO   lv_base_code
          FROM   fnd_flex_values     ffv
                ,fnd_flex_value_sets ffvs
          WHERE  ffvs.flex_value_set_name  = cv_business_type
          AND    ffv.flex_value_set_id     = ffvs.flex_value_set_id
          AND    ffv.flex_value            = g_actual_trns_rec.corp_code
          ;
--
        -- 控除用チェーンコードがNULL以外の場合
        ELSIF g_actual_trns_rec.deduction_chain_code IS  NOT NULL  THEN
          -- 本部担当拠点(チェーン店)を取得
          lv_base_code  :=  g_actual_trns_rec.attribute3;
--
        -- 顧客コード(条件)がNULL以外の場合
        ELSIF g_actual_trns_rec.customer_code IS  NOT NULL  THEN
          -- 売上拠点(顧客)を取得
          lv_base_code  :=  g_actual_trns_rec.sale_base_code;
        END IF;
--
        ov_retcode := cv_status_warn;
        lv_out_msg := xxccp_common_pkg.get_msg(
                        cv_xxcok_short_name
                      , cv_msg_cal_error
                      , cv_tkn_source_line_id
                      , g_actual_trns_rec.selling_trns_info_id
                      , cv_tkn_item_code
                      , g_actual_trns_rec.item_code
                      , cv_tkn_sales_uom_code
                      , g_actual_trns_rec.unit_type
                      , cv_tkn_condition_no
                      , g_actual_trns_rec.condition_no
                      , cv_tkn_base_code
                      , lv_base_code
                      , cv_tkn_errmsg
                      , lv_errmsg
                      );
        lb_retcode := xxcok_common_pkg.put_message_f( FND_FILE.OUTPUT    -- 出力区分
                                                     ,lv_out_msg         -- メッセージ
                                                     ,1                  -- 改行
                                                     );
      END IF;
    END IF;
--
  EXCEPTION
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END calculation_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_data
   * Description      : A-6.販売控除データ登録
   ***********************************************************************************/
  PROCEDURE insert_data( iv_syori_type  IN     VARCHAR2    -- 処理区分
                        ,in_main_idx    IN     NUMBER      -- メインインデックス
                        ,ov_errbuf      OUT    VARCHAR2    -- エラー・メッセージ           -- # 固定 #
                        ,ov_retcode     OUT    VARCHAR2    -- リターン・コード             -- # 固定 #
                        ,ov_errmsg      OUT    VARCHAR2    -- ユーザー・エラー・メッセージ -- # 固定 #
                        )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_data'; -- プログラム名
--
--############################  固定ローカル変数宣言部 START  ############################
--
    lv_errbuf  VARCHAR2(5000);              -- エラー・メッセージ
    lv_retcode VARCHAR2(1);                 -- リターン・コード
    lv_errmsg  VARCHAR2(5000);              -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END  #####################################
--
  BEGIN
--
--############################  固定ステータス初期化部 START  ############################
--
    ov_retcode  := cv_status_normal;
--
--#############################  固定ステータス初期化部 END  #############################
--
    -- 販売控除データを登録する
    -- 販売実績の場合
    IF ( iv_syori_type = cv_s_flag ) THEN
      INSERT INTO xxcok_sales_deduction(
           sales_deduction_id                    -- 販売控除ID
          ,base_code_from                        -- 振替元拠点
          ,base_code_to                          -- 振替先拠点
          ,customer_code_from                    -- 振替元顧客コード
          ,customer_code_to                      -- 振替先顧客コード
          ,deduction_chain_code                  -- 控除用チェーンコード
          ,corp_code                             -- 企業コード
          ,record_date                           -- 計上日
          ,source_category                       -- 作成元区分
          ,source_line_id                        -- 作成元明細ID
          ,condition_id                          -- 控除条件ID
          ,condition_no                          -- 控除番号
          ,condition_line_id                     -- 控除詳細ID
          ,data_type                             -- データ種類
          ,status                                -- ステータス
          ,item_code                             -- 品目コード
          ,sales_uom_code                        -- 販売単位
          ,sales_unit_price                      -- 販売単価
          ,sales_quantity                        -- 販売数量
          ,sale_pure_amount                      -- 売上本体金額
          ,sale_tax_amount                       -- 売上消費税額
          ,deduction_uom_code                    -- 控除単位
          ,deduction_unit_price                  -- 控除単価
          ,deduction_quantity                    -- 控除数量
          ,deduction_amount                      -- 控除額
-- 2020/12/03 Ver1.1 ADD Start
          ,compensation                          -- 補填
          ,margin                                -- 問屋マージン
          ,sales_promotion_expenses              -- 拡売
          ,margin_reduction                      -- 問屋マージン減額
-- 2020/12/03 Ver1.1 ADD End
          ,tax_code                              -- 税コード
          ,tax_rate                              -- 税率
          ,recon_tax_code                        -- 消込時税コード
          ,recon_tax_rate                        -- 消込時税率
          ,deduction_tax_amount                  -- 控除税額
          ,remarks                               -- 備考
          ,application_no                        -- 申請書No.
          ,gl_if_flag                            -- GL連携フラグ
          ,gl_base_code                          -- GL計上拠点
          ,gl_date                               -- GL記帳日
          ,recovery_date                         -- リカバリデータ追加時日付
          ,recovery_add_request_id               -- リカバリデータ追加時要求ID
          ,recovery_del_date                     -- リカバリデータ削除時日付
          ,recovery_del_request_id               -- リカバリデータ削除時要求ID
          ,cancel_flag                           -- 取消フラグ
          ,cancel_base_code                      -- 取消時計上拠点
          ,cancel_gl_date                        -- 取消GL記帳日
          ,cancel_user                           -- 取消実施ユーザ
          ,recon_base_code                       -- 消込時計上拠点
          ,recon_slip_num                        -- 支払伝票番号
          ,carry_payment_slip_num                -- 繰越時支払伝票番号
          ,report_decision_flag                  -- 速報確定フラグ
          ,gl_interface_id                       -- GL連携ID
          ,cancel_gl_interface_id                -- 取消GL連携ID
          ,created_by                            -- 作成者
          ,creation_date                         -- 作成日
          ,last_updated_by                       -- 最終更新者
          ,last_update_date                      -- 最終更新日
          ,last_update_login                     -- 最終更新ログイン
          ,request_id                            -- 要求ID
          ,program_application_id                -- コンカレント・プログラム・アプリケーションID
          ,program_id                            -- コンカレント・プログラムID
          ,program_update_date                   -- プログラム更新日
        )VALUES(
           xxcok_sales_deduction_s01.nextval     -- 販売控除ID
          ,g_sales_exp_rec.sales_base_code       -- 振替元拠点
          ,g_sales_exp_rec.sales_base_code       -- 振替先拠点
          ,g_sales_exp_rec.ship_to_customer_code -- 振替元顧客コード
          ,g_sales_exp_rec.ship_to_customer_code -- 振替先顧客コード
          ,NULL                                  -- チェーン店コード
          ,NULL                                  -- 企業コード
          ,g_sales_exp_rec.delivery_date         -- 売上日
          ,cv_s_flag                             -- 作成元区分
          ,g_sales_exp_rec.sales_exp_line_id     -- 作成元明細ID
          ,g_sales_exp_rec.condition_id          -- 控除条件ID
          ,g_sales_exp_rec.condition_no          -- 控除番号
          ,g_sales_exp_rec.condition_line_id     -- 控除詳細ID
          ,g_sales_exp_rec.data_type             -- データ種類
          ,cv_n_flag                             -- ステータス
          ,g_sales_exp_rec.div_item_code         -- 品目コード
          ,g_sales_exp_rec.dlv_uom_code          -- 販売単位
          ,g_sales_exp_rec.dlv_unit_price        -- 販売単価
          ,g_sales_exp_rec.dlv_qty               -- 販売数量
          ,g_sales_exp_rec.pure_amount           -- 売上本体金額
          ,g_sales_exp_rec.tax_amount            -- 売上消費税額
          ,gv_dedu_uom_code                      -- 控除単位
          ,gn_dedu_unit_price                    -- 控除単価
          ,gn_dedu_quantity                      -- 控除数量
          ,gn_dedu_amount                        -- 控除額
-- 2020/12/03 Ver1.1 ADD Start
          ,gn_compensation                       -- 補填
          ,gn_margin                             -- 問屋マージン
          ,gn_sales_promotion_expenses           -- 拡売
          ,gn_margin_reduction                   -- 問屋マージン減額
-- 2020/12/03 Ver1.1 ADD End
          ,gv_tax_code                           -- 税コード
          ,gn_tax_rate                           -- 税率
          ,NULL                                  -- 消込時税コード
          ,NULL                                  -- 消込時税率
          ,gn_dedu_tax_amount                    -- 控除税額
          ,NULL                                  -- 備考
          ,NULL                                  -- 申請書No.
          ,cv_n_flag                             -- GL連携フラグ
          ,NULL                                  -- GL計上拠点
          ,NULL                                  -- GL記帳日
          ,gd_proc_date                          -- リカバリデータ追加時日付
          ,cn_request_id                         -- リカバリデータ追加時要求ID
          ,NULL                                  -- リカバリデータ削除時日付
          ,NULL                                  -- リカバリデータ削除時要求ID
          ,cv_n_flag                             -- 取消フラグ
          ,NULL                                  -- 取消時計上拠点
          ,NULL                                  -- 取消GL記帳日
          ,NULL                                  -- 取消実施ユーザ
          ,NULL                                  -- 消込時計上拠点
          ,NULL                                  -- 支払伝票番号
          ,NULL                                  -- 繰越時支払伝票番号
          ,NULL                                  -- 速報確定フラグ
          ,NULL                                  -- GL連携ID
          ,NULL                                  -- 取消GL連携ID
          ,cn_created_by                         -- 作成者
          ,cd_creation_date                      -- 作成日
          ,cn_last_updated_by                    -- 最終更新者
          ,cd_last_update_date                   -- 最終更新日
          ,cn_last_update_login                  -- 最終更新ログイン
          ,cn_request_id                         -- 要求ID
          ,cn_program_application_id             -- コンカレント・プログラム・アプリケーションID
          ,cn_program_id                         -- コンカレント・プログラムID
          ,cd_program_update_date                -- プログラム更新日
      );
--
    -- 実績振替(EDI)の場合
    ELSIF ( iv_syori_type = cv_t_flag ) THEN
      INSERT INTO xxcok_sales_deduction(
           sales_deduction_id                                       -- 販売控除ID
          ,base_code_from                                           -- 振替元拠点
          ,base_code_to                                             -- 振替先拠点
          ,customer_code_from                                       -- 振替元顧客コード
          ,customer_code_to                                         -- 振替先顧客コード
          ,deduction_chain_code                                     -- 控除用チェーンコード
          ,corp_code                                                -- 企業コード
          ,record_date                                              -- 計上日
          ,source_category                                          -- 作成元区分
          ,source_line_id                                           -- 作成元明細ID
          ,condition_id                                             -- 控除条件ID
          ,condition_no                                             -- 控除番号
          ,condition_line_id                                        -- 控除詳細ID
          ,data_type                                                -- データ種類
          ,status                                                   -- ステータス
          ,item_code                                                -- 品目コード
          ,sales_uom_code                                           -- 販売単位
          ,sales_unit_price                                         -- 販売単価
          ,sales_quantity                                           -- 販売数量
          ,sale_pure_amount                                         -- 売上本体金額
          ,sale_tax_amount                                          -- 売上消費税額
          ,deduction_uom_code                                       -- 控除単位
          ,deduction_unit_price                                     -- 控除単価
          ,deduction_quantity                                       -- 控除数量
          ,deduction_amount                                         -- 控除額
-- 2020/12/03 Ver1.1 ADD Start
          ,compensation                                             -- 補填
          ,margin                                                   -- 問屋マージン
          ,sales_promotion_expenses                                 -- 拡売
          ,margin_reduction                                         -- 問屋マージン減額
-- 2020/12/03 Ver1.1 ADD End
          ,tax_code                                                 -- 税コード
          ,tax_rate                                                 -- 税率
          ,recon_tax_code                                           -- 消込時税コード
          ,recon_tax_rate                                           -- 消込時税率
          ,deduction_tax_amount                                     -- 控除税額
          ,remarks                                                  -- 備考
          ,application_no                                           -- 申請書No.
          ,gl_if_flag                                               -- GL連携フラグ
          ,gl_base_code                                             -- GL計上拠点
          ,gl_date                                                  -- GL記帳日
          ,recovery_date                                            -- リカバリデータ追加時日付
          ,recovery_add_request_id                                  -- リカバリデータ追加時要求ID
          ,recovery_del_date                                        -- リカバリデータ削除時日付
          ,recovery_del_request_id                                  -- リカバリデータ削除時要求ID
          ,cancel_flag                                              -- 取消フラグ
          ,cancel_base_code                                         -- 取消時計上拠点
          ,cancel_gl_date                                           -- 取消GL記帳日
          ,cancel_user                                              -- 取消実施ユーザ
          ,recon_base_code                                          -- 消込時計上拠点
          ,recon_slip_num                                           -- 支払伝票番号
          ,carry_payment_slip_num                                   -- 繰越時支払伝票番号
          ,report_decision_flag                                     -- 速報確定フラグ
          ,gl_interface_id                                          -- GL連携ID
          ,cancel_gl_interface_id                                   -- 取消GL連携ID
          ,created_by                                               -- 作成者
          ,creation_date                                            -- 作成日
          ,last_updated_by                                          -- 最終更新者
          ,last_update_date                                         -- 最終更新日
          ,last_update_login                                        -- 最終更新ログイン
          ,request_id                                               -- 要求ID
          ,program_application_id                                   -- コンカレント・プログラム・アプリケーションID
          ,program_id                                               -- コンカレント・プログラムID
          ,program_update_date                                      -- プログラム更新日
        )VALUES(
           xxcok_sales_deduction_s01.nextval                        -- 販売控除ID
          ,g_selling_trns_rec.delivery_base_code                    -- 振替元拠点
          ,g_selling_trns_rec.base_code                             -- 振替先拠点
          ,g_selling_trns_rec.selling_from_cust_code                -- 振替元顧客コード
          ,g_selling_trns_rec.cust_code                             -- 振替先顧客コード
          ,NULL                                                     -- チェーン店コード
          ,NULL                                                     -- 企業コード
          ,g_selling_trns_rec.selling_date                          -- 売上日
          ,cv_t_flag                                                -- 作成元区分
          ,g_selling_trns_rec.selling_trns_info_id                  -- 作成元明細ID
          ,g_selling_trns_rec.condition_id                          -- 控除条件ID
          ,g_selling_trns_rec.condition_no                          -- 控除番号
          ,g_selling_trns_rec.condition_line_id                     -- 控除詳細ID
          ,g_selling_trns_rec.data_type                             -- データ種類
          ,cv_n_flag                                                -- ステータス
          ,g_selling_trns_rec.item_code                             -- 品目コード
          ,g_selling_trns_rec.unit_type                             -- 販売単位
          ,g_selling_trns_rec.delivery_unit_price                   -- 販売単価
          ,g_selling_trns_rec.qty                                   -- 販売数量
          ,g_selling_trns_rec.selling_amt_no_tax                    -- 売上本体金額
          ,g_selling_trns_rec.tax_amount                            -- 売上消費税額
          ,gv_dedu_uom_code                                         -- 控除単位
          ,gn_dedu_unit_price                                       -- 控除単価
          ,gn_dedu_quantity                                         -- 控除数量
          ,gn_dedu_amount                                           -- 控除額
-- 2020/12/03 Ver1.1 ADD Start
          ,gn_compensation                       -- 補填
          ,gn_margin                             -- 問屋マージン
          ,gn_sales_promotion_expenses           -- 拡売
          ,gn_margin_reduction                   -- 問屋マージン減額
-- 2020/12/03 Ver1.1 ADD End
          ,gv_tax_code                                              -- 税コード
          ,gn_tax_rate                                              -- 税率
          ,NULL                                                     -- 消込時税コード
          ,NULL                                                     -- 消込時税率
          ,gn_dedu_tax_amount                                       -- 控除税額
          ,NULL                                                     -- 備考
          ,NULL                                                     -- 申請書No.
          ,cv_n_flag                                                -- GL連携フラグ
          ,NULL                                                     -- GL計上拠点
          ,NULL                                                     -- GL記帳日
          ,gd_proc_date                                             -- リカバリデータ追加時日付
          ,cn_request_id                                            -- リカバリデータ追加時要求ID
          ,NULL                                                     -- リカバリデータ削除時日付
          ,NULL                                                     -- リカバリデータ削除時要求ID
          ,cv_n_flag                                                -- 取消フラグ
          ,NULL                                                     -- 取消時計上拠点
          ,NULL                                                     -- 取消GL記帳日
          ,NULL                                                     -- 取消実施ユーザ
          ,NULL                                                     -- 消込時計上拠点
          ,NULL                                                     -- 支払伝票番号
          ,NULL                                                     -- 繰越時支払伝票番号
          ,cv_deci_flag                                             -- 速報確定フラグ
          ,NULL                                                     -- GL連携ID
          ,NULL                                                     -- 取消GL連携ID
          ,cn_created_by                                            -- 作成者
          ,cd_creation_date                                         -- 作成日
          ,cn_last_updated_by                                       -- 最終更新者
          ,cd_last_update_date                                      -- 最終更新日
          ,cn_last_update_login                                     -- 最終更新ログイン
          ,cn_request_id                                            -- 要求ID
          ,cn_program_application_id                                -- コンカレント・プログラム・アプリケーションID
          ,cn_program_id                                            -- コンカレント・プログラムID
          ,cd_program_update_date                                   -- プログラム更新日
      );
--
    -- 実績振替(振替割合)の場合
    ELSIF ( iv_syori_type = cv_v_flag ) THEN
      INSERT INTO xxcok_sales_deduction(
           sales_deduction_id                                       -- 販売控除ID
          ,base_code_from                                           -- 振替元拠点
          ,base_code_to                                             -- 振替先拠点
          ,customer_code_from                                       -- 振替元顧客コード
          ,customer_code_to                                         -- 振替先顧客コード
          ,deduction_chain_code                                     -- 控除用チェーンコード
          ,corp_code                                                -- 企業コード
          ,record_date                                              -- 計上日
          ,source_category                                          -- 作成元区分
          ,source_line_id                                           -- 作成元明細ID
          ,condition_id                                             -- 控除条件ID
          ,condition_no                                             -- 控除番号
          ,condition_line_id                                        -- 控除詳細ID
          ,data_type                                                -- データ種類
          ,status                                                   -- ステータス
          ,item_code                                                -- 品目コード
          ,sales_uom_code                                           -- 販売単位
          ,sales_unit_price                                         -- 販売単価
          ,sales_quantity                                           -- 販売数量
          ,sale_pure_amount                                         -- 売上本体金額
          ,sale_tax_amount                                          -- 売上消費税額
          ,deduction_uom_code                                       -- 控除単位
          ,deduction_unit_price                                     -- 控除単価
          ,deduction_quantity                                       -- 控除数量
          ,deduction_amount                                         -- 控除額
-- 2020/12/03 Ver1.1 ADD Start
          ,compensation                                             -- 補填
          ,margin                                                   -- 問屋マージン
          ,sales_promotion_expenses                                 -- 拡売
          ,margin_reduction                                         -- 問屋マージン減額
-- 2020/12/03 Ver1.1 ADD End
          ,tax_code                                                 -- 税コード
          ,tax_rate                                                 -- 税率
          ,recon_tax_code                                           -- 消込時税コード
          ,recon_tax_rate                                           -- 消込時税率
          ,deduction_tax_amount                                     -- 控除税額
          ,remarks                                                  -- 備考
          ,application_no                                           -- 申請書No.
          ,gl_if_flag                                               -- GL連携フラグ
          ,gl_base_code                                             -- GL計上拠点
          ,gl_date                                                  -- GL記帳日
          ,recovery_date                                            -- リカバリデータ追加時日付
          ,recovery_add_request_id                                  -- リカバリデータ追加時要求ID
          ,recovery_del_date                                        -- リカバリデータ削除時日付
          ,recovery_del_request_id                                  -- リカバリデータ削除時要求ID
          ,cancel_flag                                              -- 取消フラグ
          ,cancel_base_code                                         -- 取消時計上拠点
          ,cancel_gl_date                                           -- 取消GL記帳日
          ,cancel_user                                              -- 取消実施ユーザ
          ,recon_base_code                                          -- 消込時計上拠点
          ,recon_slip_num                                           -- 支払伝票番号
          ,carry_payment_slip_num                                   -- 繰越時支払伝票番号
          ,report_decision_flag                                     -- 速報確定フラグ
          ,gl_interface_id                                          -- GL連携ID
          ,cancel_gl_interface_id                                   -- 取消GL連携ID
          ,created_by                                               -- 作成者
          ,creation_date                                            -- 作成日
          ,last_updated_by                                          -- 最終更新者
          ,last_update_date                                         -- 最終更新日
          ,last_update_login                                        -- 最終更新ログイン
          ,request_id                                               -- 要求ID
          ,program_application_id                                   -- コンカレント・プログラム・アプリケーションID
          ,program_id                                               -- コンカレント・プログラムID
          ,program_update_date                                      -- プログラム更新日
        )VALUES(
           xxcok_sales_deduction_s01.nextval                        -- 販売控除ID
          ,g_actual_trns_rec.delivery_base_code                     -- 振替元拠点
          ,g_actual_trns_rec.base_code                              -- 振替先拠点
          ,g_actual_trns_rec.selling_from_cust_code                 -- 振替元顧客コード
          ,g_actual_trns_rec.cust_code                              -- 振替先顧客コード
          ,NULL                                                     -- チェーン店コード
          ,NULL                                                     -- 企業コード
          ,g_actual_trns_rec.selling_date                           -- 売上日
          ,cv_v_flag                                                -- 作成元区分
          ,g_actual_trns_rec.selling_trns_info_id                   -- 作成元明細ID
          ,g_actual_trns_rec.condition_id                           -- 控除条件ID
          ,g_actual_trns_rec.condition_no                           -- 控除番号
          ,g_actual_trns_rec.condition_line_id                      -- 控除詳細ID
          ,g_actual_trns_rec.data_type                              -- データ種類
          ,cv_n_flag                                                -- ステータス
          ,g_actual_trns_rec.item_code                              -- 品目コード
          ,g_actual_trns_rec.unit_type                              -- 販売単位
          ,g_actual_trns_rec.delivery_unit_price                    -- 販売単価
          ,g_actual_trns_rec.qty                                    -- 販売数量
          ,g_actual_trns_rec.selling_amt_no_tax                     -- 売上本体金額
          ,g_actual_trns_rec.tax_amount                             -- 売上消費税額
          ,gv_dedu_uom_code                                         -- 控除単位
          ,gn_dedu_unit_price                                       -- 控除単価
          ,gn_dedu_quantity                                         -- 控除数量
          ,gn_dedu_amount                                           -- 控除額
-- 2020/12/03 Ver1.1 ADD Start
          ,gn_compensation                       -- 補填
          ,gn_margin                             -- 問屋マージン
          ,gn_sales_promotion_expenses           -- 拡売
          ,gn_margin_reduction                   -- 問屋マージン減額
-- 2020/12/03 Ver1.1 ADD End
          ,gv_tax_code                                              -- 税コード
          ,gn_tax_rate                                              -- 税率
          ,NULL                                                     -- 消込時税コード
          ,NULL                                                     -- 消込時税率
          ,gn_dedu_tax_amount                                       -- 控除税額
          ,NULL                                                     -- 備考
          ,NULL                                                     -- 申請書No.
          ,cv_n_flag                                                -- GL連携フラグ
          ,NULL                                                     -- GL計上拠点
          ,NULL                                                     -- GL記帳日
          ,gd_proc_date                                             -- リカバリデータ追加時日付
          ,cn_request_id                                            -- リカバリデータ追加時要求ID
          ,NULL                                                     -- リカバリデータ削除時日付
          ,NULL                                                     -- リカバリデータ削除時要求ID
          ,cv_n_flag                                                -- 取消フラグ
          ,NULL                                                     -- 取消時計上拠点
          ,NULL                                                     -- 取消GL記帳日
          ,NULL                                                     -- 取消実施ユーザ
          ,NULL                                                     -- 消込時計上拠点
          ,NULL                                                     -- 支払伝票番号
          ,NULL                                                     -- 繰越時支払伝票番号
          ,cv_deci_flag                                             -- 速報確定フラグ
          ,NULL                                                     -- GL連携ID
          ,NULL                                                     -- 取消GL連携ID
          ,cn_created_by                                            -- 作成者
          ,cd_creation_date                                         -- 作成日
          ,cn_last_updated_by                                       -- 最終更新者
          ,cd_last_update_date                                      -- 最終更新日
          ,cn_last_update_login                                     -- 最終更新ログイン
          ,cn_request_id                                            -- 要求ID
          ,cn_program_application_id                                -- コンカレント・プログラム・アプリケーションID
          ,cn_program_id                                            -- コンカレント・プログラムID
          ,cd_program_update_date                                   -- プログラム更新日
      );
--
    -- 定額控除の場合
    ELSIF ( iv_syori_type = cv_f_flag ) THEN
      INSERT INTO xxcok_sales_deduction(
           sales_deduction_id                                       -- 販売控除ID
          ,base_code_from                                           -- 振替元拠点
          ,base_code_to                                             -- 振替先拠点
          ,customer_code_from                                       -- 振替元顧客コード
          ,customer_code_to                                         -- 振替先顧客コード
          ,deduction_chain_code                                     -- 控除用チェーンコード
          ,corp_code                                                -- 企業コード
          ,record_date                                              -- 計上日
          ,source_category                                          -- 作成元区分
          ,source_line_id                                           -- 作成元明細ID
          ,condition_id                                             -- 控除条件ID
          ,condition_no                                             -- 控除番号
          ,condition_line_id                                        -- 控除詳細ID
          ,data_type                                                -- データ種類
          ,status                                                   -- ステータス
          ,item_code                                                -- 品目コード
          ,sales_uom_code                                           -- 販売単位
          ,sales_unit_price                                         -- 販売単価
          ,sales_quantity                                           -- 販売数量
          ,sale_pure_amount                                         -- 売上本体金額
          ,sale_tax_amount                                          -- 売上消費税額
          ,deduction_uom_code                                       -- 控除単位
          ,deduction_unit_price                                     -- 控除単価
          ,deduction_quantity                                       -- 控除数量
          ,deduction_amount                                         -- 控除額
-- 2020/12/03 Ver1.1 ADD Start
          ,compensation                                             -- 補填
          ,margin                                                   -- 問屋マージン
          ,sales_promotion_expenses                                 -- 拡売
          ,margin_reduction                                         -- 問屋マージン減額
-- 2020/12/03 Ver1.1 ADD End
          ,tax_code                                                 -- 税コード
          ,tax_rate                                                 -- 税率
          ,recon_tax_code                                           -- 消込時税コード
          ,recon_tax_rate                                           -- 消込時税率
          ,deduction_tax_amount                                     -- 控除税額
          ,remarks                                                  -- 備考
          ,application_no                                           -- 申請書No.
          ,gl_if_flag                                               -- GL連携フラグ
          ,gl_base_code                                             -- GL計上拠点
          ,gl_date                                                  -- GL記帳日
          ,recovery_date                                            -- リカバリデータ追加時日付
          ,recovery_add_request_id                                  -- リカバリデータ追加時要求ID
          ,recovery_del_date                                        -- リカバリデータ削除時日付
          ,recovery_del_request_id                                  -- リカバリデータ削除時要求ID
          ,cancel_flag                                              -- 取消フラグ
          ,cancel_base_code                                         -- 取消時計上拠点
          ,cancel_gl_date                                           -- 取消GL記帳日
          ,cancel_user                                              -- 取消実施ユーザ
          ,recon_base_code                                          -- 消込時計上拠点
          ,recon_slip_num                                           -- 支払伝票番号
          ,carry_payment_slip_num                                   -- 繰越時支払伝票番号
          ,report_decision_flag                                     -- 速報確定フラグ
          ,gl_interface_id                                          -- GL連携ID
          ,cancel_gl_interface_id                                   -- 取消GL連携ID
          ,created_by                                               -- 作成者
          ,creation_date                                            -- 作成日
          ,last_updated_by                                          -- 最終更新者
          ,last_update_date                                         -- 最終更新日
          ,last_update_login                                        -- 最終更新ログイン
          ,request_id                                               -- 要求ID
          ,program_application_id                                   -- コンカレント・プログラム・アプリケーションID
          ,program_id                                               -- コンカレント・プログラムID
          ,program_update_date                                      -- プログラム更新日
        )VALUES(
           xxcok_sales_deduction_s01.nextval                           -- 販売控除ID
-- 2021/03/22 Ver1.2 MOD Start
--          ,gt_condition_work_tbl(in_main_idx).accounting_base          -- 振替元拠点
          ,gt_condition_work_tbl(in_main_idx).sale_base_code           -- 振替元拠点
--          ,gt_condition_work_tbl(in_main_idx).accounting_base          -- 振替先拠点
          ,gt_condition_work_tbl(in_main_idx).sale_base_code           -- 振替元拠点
--          ,gt_condition_work_tbl(in_main_idx).customer_code            -- 振替元顧客コード
          ,gt_condition_work_tbl(in_main_idx).accounting_customer_code -- 振替元顧客コード
--          ,gt_condition_work_tbl(in_main_idx).customer_code            -- 振替先顧客コード
          ,gt_condition_work_tbl(in_main_idx).accounting_customer_code -- 振替先顧客コード
--          ,gt_condition_work_tbl(in_main_idx).deduction_chain_code     -- 控除用チェーンコード
          ,NULL                                                        -- 控除用チェーンコード
--          ,gt_condition_work_tbl(in_main_idx).corp_code                -- 企業コード
          ,NULL                                                        -- 企業コード
-- 2021/03/22 Ver1.2 MOD End
          ,gd_work_date                                                -- 計上日
          ,cv_f_flag                                                   -- 作成元区分
          ,NULL                                                        -- 作成元明細ID
          ,gt_condition_work_tbl(in_main_idx).condition_id             -- 控除条件ID
          ,gt_condition_work_tbl(in_main_idx).condition_no             -- 控除番号
          ,gt_condition_work_tbl(in_main_idx).condition_line_id        -- 控除詳細ID
          ,gt_condition_work_tbl(in_main_idx).data_type                -- データ種類
          ,cv_n_flag                                                   -- ステータス
          ,NULL                                                        -- 品目コード
          ,NULL                                                        -- 販売単位
          ,NULL                                                        -- 販売単価
          ,NULL                                                        -- 販売数量
          ,NULL                                                        -- 売上本体金額
          ,NULL                                                        -- 売上消費税額
          ,NULL                                                        -- 控除単位
          ,NULL                                                        -- 控除単価
          ,NULL                                                        -- 控除数量
          ,gt_condition_work_tbl(in_main_idx).deduction_amount         -- 控除額
-- 2020/12/03 Ver1.1 ADD Start
          ,NULL                                                        -- 補填
          ,NULL                                                        -- 問屋マージン
          ,NULL                                                        -- 拡売
          ,NULL                                                        -- 問屋マージン減額
-- 2020/12/03 Ver1.1 ADD End
          ,gt_condition_work_tbl(in_main_idx).tax_code                 -- 税コード
          ,NULL                                                        -- 税率
          ,NULL                                                        -- 消込時税コード
          ,NULL                                                        -- 消込時税率
          ,gt_condition_work_tbl(in_main_idx).deduction_tax_amount     -- 控除税額
          ,NULL                                                        -- 備考
          ,NULL                                                        -- 申請書No.
          ,cv_n_flag                                                   -- GL連携フラグ
          ,NULL                                                        -- GL計上拠点
          ,NULL                                                        -- GL記帳日
          ,gd_proc_date                                                -- リカバリデータ追加時日付
          ,cn_request_id                                               -- リカバリデータ追加時要求ID
          ,NULL                                                        -- リカバリデータ削除時日付
          ,NULL                                                        -- リカバリデータ削除時要求ID
          ,cv_n_flag                                                   -- 取消フラグ
          ,NULL                                                        -- 取消時計上拠点
          ,NULL                                                        -- 取消GL記帳日
          ,NULL                                                        -- 取消実施ユーザ
          ,NULL                                                        -- 消込時計上拠点
          ,NULL                                                        -- 支払伝票番号
          ,NULL                                                        -- 繰越時支払伝票番号
          ,NULL                                                        -- 速報確定フラグ
          ,NULL                                                        -- GL連携ID
          ,NULL                                                        -- 取消GL連携ID
          ,cn_created_by                                               -- 作成者
          ,cd_creation_date                                            -- 作成日
          ,cn_last_updated_by                                          -- 最終更新者
          ,cd_last_update_date                                         -- 最終更新日
          ,cn_last_update_login                                        -- 最終更新ログイン
          ,cn_request_id                                               -- 要求ID
          ,cn_program_application_id                                   -- コンカレント・プログラム・アプリケーションID
          ,cn_program_id                                               -- コンカレント・プログラムID
          ,cd_program_update_date                                      -- プログラム更新日
      );
--
    END IF;
--
  EXCEPTION
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END insert_data;
--
  /**********************************************************************************
   * Procedure Name   : get_data
   * Description      : A-4.控除データ抽出
   ***********************************************************************************/
--  PROCEDURE get_data( iv_recovery_h_flag  IN     VARCHAR2  -- 控除ヘッダーリカバリ対象フラグ
--                    , iv_recovery_l_flag  IN     VARCHAR2  -- 控除明細リカバリ対象フラグ
  PROCEDURE get_data( ov_errbuf           OUT    VARCHAR2  -- エラー・メッセージ           -- # 固定 #
                    , ov_retcode          OUT    VARCHAR2  -- リターン・コード             -- # 固定 #
                    , ov_errmsg           OUT    VARCHAR2  -- ユーザー・エラー・メッセージ -- # 固定 #
                        )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(10) := 'get_data'; -- プログラム名
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_condition_line_id       NUMBER DEFAULT 0;                               -- 控除明細ID存在確認用
    ln_condition_line_id_1     NUMBER DEFAULT 0;                               -- 控除明細ID存在確認用
    ln_condition_line_id_2     NUMBER DEFAULT 0;                               -- 控除明細ID存在確認用
    lv_recon_slip_num          VARCHAR2(30);                                   -- 伝票番号存在確認用
    lv_out_msg                 VARCHAR2(1000)      DEFAULT NULL;               -- メッセージ出力変数
    lb_retcode                 BOOLEAN             DEFAULT NULL;               -- メッセージ出力関数の戻り値
--
--############################  固定ローカル変数宣言部 START  ############################
--
    lv_errbuf  VARCHAR2(5000);              -- エラー・メッセージ
    lv_retcode VARCHAR2(1);                 -- リターン・コード
    lv_errmsg  VARCHAR2(5000);              -- ユーザー・エラー・メッセージ
--
--#############################  固定ローカル変数宣言部 END  #############################
--
  BEGIN
--
--#########################  固定ステータス初期化部 START  #########################
--
    ov_retcode := cv_status_normal;
--
--##################################  固定部 END  ##################################
--
    -- 販売実績情報カーソルオープン
    OPEN g_sales_exp_cur;       --要求ID
--
    LOOP
      -- データ取得
      FETCH g_sales_exp_cur INTO g_sales_exp_rec;
      EXIT WHEN g_sales_exp_cur%NOTFOUND;
--
      -- 控除明細ID存在確認用、伝票番号存在確認初期化
      ln_condition_line_id  := 0;
      lv_recon_slip_num     := NULL;
--
      BEGIN
        SELECT NVL(xsd.condition_line_id,0)            -- 控除詳細ID
              ,NVL(xsd.recon_slip_num, cv_dummy_flag)  -- 支払伝票番号
        INTO   ln_condition_line_id
              ,lv_recon_slip_num
        FROM   xxcok_sales_deduction     xsd                     -- 販売控除情報
        WHERE  xsd.condition_id       = g_sales_exp_rec.condition_id       -- 控除条件ID
        AND    xsd.source_line_id     = g_sales_exp_rec.sales_exp_line_id  -- 作成元明細ID
        AND    xsd.source_category    = cv_s_flag                          -- 作成元区分：販売実績
        AND    xsd.status             = cv_n_flag                          -- ステータス：新規
        AND    ROWNUM                 = 1
        ;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          ln_condition_line_id  := 0;
          lv_recon_slip_num     := cv_dummy_flag;
      END;
--
      -- データが取得できなかった場合、新規控除
      IF (ln_condition_line_id = 0 AND lv_recon_slip_num = cv_dummy_flag )THEN
--
        -- ============================================================
        -- A-5.控除データ算出の呼び出し
        -- ============================================================
        calculation_data(iv_syori_type        => cv_s_flag   -- 処理区分
                        ,ov_errbuf            => lv_errbuf   -- エラー・メッセージ
                        ,ov_retcode           => lv_retcode  -- リターン・コード
                        ,ov_errmsg            => lv_errmsg   -- ユーザー・エラー・メッセージ
                         );
--
        IF lv_retcode  = cv_status_normal  THEN
          -- ============================================================
          -- A-6.販売控除データ登録の呼び出し
          -- ============================================================
          insert_data(iv_syori_type    => cv_s_flag   -- 処理区分
                     ,in_main_idx      => NULL        -- メインインデックス
                     ,ov_errbuf        => lv_errbuf   -- エラー・メッセージ
                     ,ov_retcode       => lv_retcode  -- リターン・コード
                     ,ov_errmsg        => lv_errmsg   -- ユーザー・エラー・メッセージ
                      );
--
          IF  lv_retcode  = cv_status_normal  THEN
            gn_add_cnt      :=  gn_add_cnt + 1;
          ELSE
            RAISE global_process_expt;
          END IF;
        ELSIF lv_retcode  = cv_status_warn  THEN
          ov_retcode        := cv_status_warn;
          gn_cal_skip_cnt   :=  gn_cal_skip_cnt   + 1;
        ELSE
          RAISE global_process_expt;
        END IF;
--
      -- 支払伝票番号が設定されている場合（支払済）
      ELSIF ( ln_condition_line_id != 0 AND lv_recon_slip_num != cv_dummy_flag ) THEN
        lv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_name
                                               ,iv_name         => cv_msg_slip_date_err
                                               ,iv_token_name1  => cv_tkn_recon_slip_num
                                               ,iv_token_value1 => lv_recon_slip_num        -- 支払伝票番号
                                               );
--
        lb_retcode := xxcok_common_pkg.put_message_f( FND_FILE.OUTPUT    -- 出力区分
                                                     ,lv_out_msg         -- メッセージ
                                                     ,1                  -- 改行
                                                     );
--
        -- 控除データ登録支払済スキップ件数
        gn_add_skip_cnt := gn_add_skip_cnt + 1;
--
      -- 支払伝票番号が未設定である場合（未払）
      ELSIF ( ln_condition_line_id != 0 AND lv_recon_slip_num = cv_dummy_flag ) THEN
--
        -- 控除ヘッダのリカバリ対象フラグが「U:更新」、または
        -- 控除明細の「リカバリ対象フラグが「U:更新」の場合
        IF    ((g_sales_exp_rec.header_recovery_flag = cv_u_flag)
          OR   (g_sales_exp_rec.line_recovery_flag = cv_u_flag))THEN
--
          -- 控除明細ID存在確認用初期化
          ln_condition_line_id_1 := 0;
--
          -- 未払の存在確認
          BEGIN
            SELECT NVL(xsd.condition_line_id,0)  -- 控除詳細ID
            INTO   ln_condition_line_id_1
            FROM   xxcok_sales_deduction     xsd                     -- 販売控除情報
            WHERE  xsd.source_line_id     = g_sales_exp_rec.sales_exp_line_id  -- 作成元明細ID
            AND    xsd.condition_line_id  = g_sales_exp_rec.condition_line_id  -- 控除詳細ID
            AND    xsd.source_category    = cv_s_flag                          -- 作成元区分：販売実績
            AND    xsd.status             = cv_n_flag                          -- ステータス：新規
            AND    xsd.recon_slip_num    IS NULL                               -- 支払伝票番号
            ;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              ln_condition_line_id_1  := 0;
          END;
--
          -- 未払の控除が存在した場合
          IF (ln_condition_line_id_1 != 0) THEN
--
            -- 控除詳細IDが前処理と変わっていた場合、削除実施
            IF (ln_condition_line_id_1 != ln_condition_line_id_2) THEN
--
              -- ============================================================
              -- A-3.販売控除取消処理の呼び出し
              -- ============================================================
                sales_deduction_delete(in_condition_line_id => ln_condition_line_id_1  -- 控除詳細ID
                                      ,iv_syori_type        => cv_s_flag               -- 処理区分
                                      ,ov_errbuf            => lv_errbuf               -- エラー・メッセージ
                                      ,ov_retcode           => lv_retcode              -- リターン・コード
                                      ,ov_errmsg            => lv_errmsg               -- ユーザー・エラー・メッセージ
                                       );
--
            END IF;
--
            ln_condition_line_id_2 := ln_condition_line_id_1;
--
          END IF;
        END IF;
--
        -- ============================================================
        -- A-5.控除データ算出の呼び出し
        -- ============================================================
        calculation_data(iv_syori_type        => cv_s_flag   -- 処理区分
                        ,ov_errbuf            => lv_errbuf   -- エラー・メッセージ
                        ,ov_retcode           => lv_retcode  -- リターン・コード
                        ,ov_errmsg            => lv_errmsg   -- ユーザー・エラー・メッセージ
                         );
--
        IF lv_retcode  = cv_status_normal  THEN
          -- ============================================================
          -- A-6.販売控除データ登録の呼び出し
          -- ============================================================
          insert_data(iv_syori_type    => cv_s_flag   -- 処理区分
                     ,in_main_idx      => NULL        -- メインインデックス
                     ,ov_errbuf        => lv_errbuf   -- エラー・メッセージ
                     ,ov_retcode       => lv_retcode  -- リターン・コード
                     ,ov_errmsg        => lv_errmsg   -- ユーザー・エラー・メッセージ
                      );
--
          IF  lv_retcode  = cv_status_normal  THEN
            gn_add_cnt   :=  gn_add_cnt + 1;
          ELSE
            RAISE global_process_expt;
          END IF;
        ELSIF lv_retcode  = cv_status_warn  THEN
          ov_retcode        := cv_status_warn;
          gn_cal_skip_cnt   :=  gn_cal_skip_cnt   + 1;
        ELSE
          RAISE global_process_expt;
        END IF;
--
      END IF;
    END LOOP;
    -- カーソルクローズ
    CLOSE g_sales_exp_cur;
--
    ln_condition_line_id_2 := 0;
--
    -- 実績振替情報(EDI)カーソルオープン
    OPEN g_selling_trns_cur;
--
    LOOP
      -- データ取得
      FETCH g_selling_trns_cur INTO g_selling_trns_rec;
      EXIT WHEN g_selling_trns_cur%NOTFOUND;
--
      -- 控除明細ID存在確認用、伝票番号存在確認初期化
      ln_condition_line_id  := 0;
      lv_recon_slip_num     := NULL;
--
      -- 販売控除データ存在確認
      BEGIN
        SELECT NVL(xsd.condition_line_id,0)            -- 控除詳細ID
              ,NVL(xsd.recon_slip_num, cv_dummy_flag)  -- 支払伝票番号
        INTO   ln_condition_line_id
              ,lv_recon_slip_num
        FROM   xxcok_sales_deduction     xsd                            -- 販売控除情報
        WHERE  xsd.condition_id       = g_selling_trns_rec.condition_id          -- 控除条件ID
        AND    xsd.source_line_id     = g_selling_trns_rec.selling_trns_info_id  -- 作成元明細ID
        AND    xsd.source_category    = cv_t_flag                                -- 作成元区分：EDI
        AND    xsd.status             = cv_n_flag                                -- ステータス：新規
        AND    ROWNUM                 = 1
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          ln_condition_line_id  := 0;
          lv_recon_slip_num     := cv_dummy_flag;
      END;
--
      -- データが取得できなかった場合、新規控除
      IF (ln_condition_line_id = 0 AND lv_recon_slip_num = cv_dummy_flag )THEN
--
        -- ============================================================
        -- A-5.控除データ算出の呼び出し
        -- ============================================================
        calculation_data(iv_syori_type   => cv_t_flag   -- 処理区分：EDI
                        ,ov_errbuf       => lv_errbuf   -- エラー・メッセージ
                        ,ov_retcode      => lv_retcode  -- リターン・コード
                        ,ov_errmsg       => lv_errmsg   -- ユーザー・エラー・メッセージ
                         );
--
        IF lv_retcode  = cv_status_normal  THEN
          -- ============================================================
          -- A-6.販売控除データ登録の呼び出し
          -- ============================================================
          insert_data(iv_syori_type        => cv_t_flag  -- 処理区分：EDI
                     ,in_main_idx          => NULL        -- メインインデックス
                     ,ov_errbuf            => lv_errbuf   -- エラー・メッセージ
                     ,ov_retcode           => lv_retcode  -- リターン・コード
                     ,ov_errmsg            => lv_errmsg   -- ユーザー・エラー・メッセージ
                      );
--
          IF  lv_retcode  = cv_status_normal  THEN
            gn_add_cnt :=  gn_add_cnt + 1;
          ELSE
            RAISE global_process_expt;
          END IF;
        ELSIF lv_retcode  = cv_status_warn  THEN
          ov_retcode    := cv_status_warn;
          gn_cal_skip_cnt   :=  gn_cal_skip_cnt   + 1;
        ELSE
          RAISE global_process_expt;
        END IF;
--
      -- 支払伝票番号が設定されている場合（支払済）
      ELSIF ( ln_condition_line_id != 0 AND lv_recon_slip_num != cv_dummy_flag ) THEN
        lv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_name
                                               ,iv_name         => cv_msg_slip_date_err
                                               ,iv_token_name1  => cv_tkn_recon_slip_num
                                               ,iv_token_value1 => lv_recon_slip_num        -- 支払伝票番号
                                               );
--
        lb_retcode := xxcok_common_pkg.put_message_f( FND_FILE.OUTPUT    -- 出力区分
                                                     ,lv_out_msg         -- メッセージ
                                                     ,1                  -- 改行
                                                     );
--
        -- 控除データ登録支払済スキップ件数
        gn_add_skip_cnt := gn_add_skip_cnt + 1;
--
      -- 支払伝票番号が未設定である場合（未払）
      ELSIF ( ln_condition_line_id != 0 AND lv_recon_slip_num = cv_dummy_flag ) THEN
--
        -- 控除ヘッダのリカバリ対象フラグが「U:更新」、または
        -- 控除明細の「リカバリ対象フラグが「U:更新」の場合
        IF    ((g_selling_trns_rec.header_recovery_flag = cv_u_flag)
          OR   (g_selling_trns_rec.line_recovery_flag = cv_u_flag))THEN
--
          -- 控除明細ID存在確認用初期化
          ln_condition_line_id_1 := 0;
--
          -- 未払の存在確認
          BEGIN
            SELECT NVL(xsd.condition_line_id,0)  -- 控除詳細ID
            INTO   ln_condition_line_id_1
            FROM   xxcok_sales_deduction     xsd                     -- 販売控除情報
            WHERE  xsd.source_line_id     = g_selling_trns_rec.selling_trns_info_id  -- 作成元明細ID
            AND    xsd.condition_line_id  = g_selling_trns_rec.condition_line_id     -- 控除詳細ID
            AND    xsd.source_category    = cv_t_flag                                -- 作成元区分：EDI
            AND    xsd.status             = cv_n_flag                                -- ステータス：新規
            AND    xsd.recon_slip_num    IS NULL                                     -- 支払伝票番号
            ;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              ln_condition_line_id_1  := 0;
          END;
--
          -- 未払の控除が存在した場合は削除実施
          IF (ln_condition_line_id_1 != 0) THEN
            -- 控除詳細IDが前処理と変わっていた場合、削除実施
            IF (ln_condition_line_id_1 != ln_condition_line_id_2) THEN
--
              -- ============================================================
              -- A-3.販売控除取消処理の呼び出し
              -- ============================================================
                sales_deduction_delete(in_condition_line_id => ln_condition_line_id_1  -- 控除詳細ID
                                      ,iv_syori_type        => cv_t_flag               -- 処理区分
                                      ,ov_errbuf            => lv_errbuf               -- エラー・メッセージ
                                      ,ov_retcode           => lv_retcode              -- リターン・コード
                                      ,ov_errmsg            => lv_errmsg               -- ユーザー・エラー・メッセージ
                                       );
--
            END IF;
--
            ln_condition_line_id_2 := ln_condition_line_id_1;
--
          END IF;
        END IF;
--
        -- ============================================================
        -- A-5.控除データ算出の呼び出し
        -- ============================================================
        calculation_data(iv_syori_type        => cv_t_flag  -- 処理区分
                        ,ov_errbuf            => lv_errbuf   -- エラー・メッセージ
                        ,ov_retcode           => lv_retcode  -- リターン・コード
                        ,ov_errmsg            => lv_errmsg   -- ユーザー・エラー・メッセージ
                         );
--
        IF lv_retcode  = cv_status_normal  THEN
          -- ============================================================
          -- A-6.販売控除データ登録の呼び出し
          -- ============================================================
          insert_data(iv_syori_type        => cv_t_flag  -- 処理区分：T
                     ,in_main_idx          => NULL        -- メインインデックス
                     ,ov_errbuf            => lv_errbuf   -- エラー・メッセージ
                     ,ov_retcode           => lv_retcode  -- リターン・コード
                     ,ov_errmsg            => lv_errmsg   -- ユーザー・エラー・メッセージ
                      );
--
          IF  lv_retcode  = cv_status_normal  THEN
            gn_add_cnt :=  gn_add_cnt + 1;
          ELSE
            RAISE global_process_expt;
          END IF;
        ELSIF lv_retcode  = cv_status_warn  THEN
          ov_retcode    := cv_status_warn;
          gn_cal_skip_cnt   :=  gn_cal_skip_cnt   + 1;
        ELSE
          RAISE global_process_expt;
        END IF;
--
      END IF;
    END LOOP;
    -- カーソルクローズ
    CLOSE g_selling_trns_cur;
--
    ln_condition_line_id_2 := 0;
--
    -- 実績振替情報（振替割合）カーソルオープン
    OPEN g_actual_trns_cur;       --要求ID
--
    LOOP
      -- データ取得
      FETCH g_actual_trns_cur INTO g_actual_trns_rec;
      EXIT WHEN g_actual_trns_cur%NOTFOUND;
--
      -- 控除明細ID存在確認用、伝票番号存在確認初期化
      ln_condition_line_id  := 0;
      lv_recon_slip_num     := NULL;
--
      -- 販売控除データ存在確認
      BEGIN
        SELECT NVL(xsd.condition_line_id,0)            -- 控除詳細ID
              ,NVL(xsd.recon_slip_num, cv_dummy_flag)  -- 支払伝票番号
        INTO   ln_condition_line_id
              ,lv_recon_slip_num
        FROM   xxcok_sales_deduction     xsd                            -- 販売控除情報
        WHERE  xsd.condition_id       = g_actual_trns_rec.condition_id          -- 控除条件ID
        AND    xsd.source_line_id     = g_actual_trns_rec.selling_trns_info_id  -- 作成元明細ID
        AND    xsd.source_category    = cv_v_flag                               -- 作成元区分：振替割合
        AND    xsd.status             = cv_n_flag                               -- ステータス：新規
        AND    ROWNUM                 = 1
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          ln_condition_line_id  := 0;
          lv_recon_slip_num     := cv_dummy_flag;
      END;
--
      -- データが取得できなかった場合、新規控除
      IF (ln_condition_line_id = 0 AND lv_recon_slip_num = cv_dummy_flag )THEN
--
        -- ============================================================
        -- A-5.控除データ算出の呼び出し
        -- ============================================================
        calculation_data(iv_syori_type   => cv_v_flag   -- 処理区分：振替割合
                        ,ov_errbuf       => lv_errbuf   -- エラー・メッセージ
                        ,ov_retcode      => lv_retcode  -- リターン・コード
                        ,ov_errmsg       => lv_errmsg   -- ユーザー・エラー・メッセージ
                         );
--
        IF lv_retcode  = cv_status_normal  THEN
          -- ============================================================
          -- A-6.販売控除データ登録の呼び出し
          -- ============================================================
          insert_data(iv_syori_type        => cv_v_flag   -- 処理区分：振替割合
                     ,in_main_idx          => NULL        -- メインインデックス
                     ,ov_errbuf            => lv_errbuf   -- エラー・メッセージ
                     ,ov_retcode           => lv_retcode  -- リターン・コード
                     ,ov_errmsg            => lv_errmsg   -- ユーザー・エラー・メッセージ
                      );
--
          IF  lv_retcode  = cv_status_normal  THEN
            gn_add_cnt :=  gn_add_cnt + 1;
          ELSE
            RAISE global_process_expt;
          END IF;
        ELSIF lv_retcode  = cv_status_warn  THEN
          ov_retcode    := cv_status_warn;
          gn_cal_skip_cnt   :=  gn_cal_skip_cnt   + 1;
        ELSE
          RAISE global_process_expt;
        END IF;
--
      -- 支払伝票番号が設定されている場合（支払済）
      ELSIF ( ln_condition_line_id != 0 AND lv_recon_slip_num != cv_dummy_flag ) THEN
        lv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_name
                                               ,iv_name         => cv_msg_slip_date_err
                                               ,iv_token_name1  => cv_tkn_recon_slip_num
                                               ,iv_token_value1 => lv_recon_slip_num        -- 支払伝票番号
                                               );
--
        lb_retcode := xxcok_common_pkg.put_message_f( FND_FILE.OUTPUT    -- 出力区分
                                                     ,lv_out_msg         -- メッセージ
                                                     ,1                  -- 改行
                                                     );
--
        -- 控除データ登録支払済スキップ件数
        gn_add_skip_cnt := gn_add_skip_cnt + 1;
--
      -- 支払伝票番号が未設定である場合（未払）
      ELSIF ( ln_condition_line_id != 0 AND lv_recon_slip_num = cv_dummy_flag ) THEN
--
        -- 控除ヘッダのリカバリ対象フラグが「U:更新」、または
        -- 控除明細の「リカバリ対象フラグが「U:更新」の場合
        IF    ((g_actual_trns_rec.header_recovery_flag = cv_u_flag)
          OR   (g_actual_trns_rec.line_recovery_flag = cv_u_flag))THEN
--
          -- 控除明細ID存在確認用初期化
          ln_condition_line_id_1 := 0;
--
          -- 未払の存在確認
          BEGIN
            SELECT NVL(xsd.condition_line_id,0)  -- 控除詳細ID
            INTO   ln_condition_line_id_1
            FROM   xxcok_sales_deduction     xsd                     -- 販売控除情報
            WHERE  xsd.source_line_id     = g_actual_trns_rec.selling_trns_info_id   -- 作成元明細ID
            AND    xsd.condition_line_id  = g_actual_trns_rec.condition_line_id      -- 控除詳細ID
            AND    xsd.source_category    = cv_v_flag                                -- 作成元区分：振替割合
            AND    xsd.status             = cv_n_flag                                -- ステータス：新規
            AND    xsd.recon_slip_num    IS NULL                                     -- 支払伝票番号
            ;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              ln_condition_line_id_1  := 0;
          END;
--
          -- 未払の控除が存在した場合は削除実施
          IF (ln_condition_line_id_1 != 0) THEN
--
            -- 控除詳細IDが前処理と変わっていた場合、削除実施
            IF (ln_condition_line_id_1 != ln_condition_line_id_2) THEN
              -- ============================================================
              -- A-3.販売控除取消処理の呼び出し
              -- ============================================================
                sales_deduction_delete(in_condition_line_id => ln_condition_line_id_1  -- 控除詳細ID
                                      ,iv_syori_type        => cv_v_flag               -- 処理区分
                                      ,ov_errbuf            => lv_errbuf               -- エラー・メッセージ
                                      ,ov_retcode           => lv_retcode              -- リターン・コード
                                      ,ov_errmsg            => lv_errmsg               -- ユーザー・エラー・メッセージ
                                       );
--
            END IF;
--
            ln_condition_line_id_2 := ln_condition_line_id_1;
--
          END IF;
        END IF;
--
        -- ============================================================
        -- A-5.控除データ算出の呼び出し
        -- ============================================================
        calculation_data(iv_syori_type        => cv_v_flag   -- 処理区分
                        ,ov_errbuf            => lv_errbuf   -- エラー・メッセージ
                        ,ov_retcode           => lv_retcode  -- リターン・コード
                        ,ov_errmsg            => lv_errmsg   -- ユーザー・エラー・メッセージ
                         );
--
        IF lv_retcode  = cv_status_normal  THEN
          -- ============================================================
          -- A-6.販売控除データ登録の呼び出し
          -- ============================================================
          insert_data(iv_syori_type  => cv_v_flag      -- 処理区分：T
                     ,in_main_idx    => NULL           -- メインインデックス
                     ,ov_errbuf      => lv_errbuf      -- エラー・メッセージ
                     ,ov_retcode     => lv_retcode     -- リターン・コード
                     ,ov_errmsg      => lv_errmsg      -- ユーザー・エラー・メッセージ
                      );
--
          IF  lv_retcode  = cv_status_normal  THEN
            gn_add_cnt :=  gn_add_cnt + 1;
          ELSE
            RAISE global_process_expt;
          END IF;
        ELSIF lv_retcode  = cv_status_warn  THEN
          ov_retcode    := cv_status_warn;
          gn_cal_skip_cnt   :=  gn_cal_skip_cnt   + 1;
        ELSE
          RAISE global_process_expt;
        END IF;
--
      END IF;
    END LOOP;
    -- カーソルクローズ
    CLOSE g_actual_trns_cur;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END get_data;
--
  /**********************************************************************************
   * Procedure Name   : get_condition_data
   * Description      : A-2.控除情報更新対象抽出
   ***********************************************************************************/
  PROCEDURE get_condition_data(ov_errbuf   OUT  VARCHAR2    -- エラー・メッセージ           --# 固定 #
                              ,ov_retcode  OUT  VARCHAR2    -- リターン・コード             --# 固定 #
                              ,ov_errmsg   OUT  VARCHAR2    -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_condition_data'; -- プログラム名
--
--#########################  固定ローカル変数宣言部 START  #########################
--
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;  -- エラー・メッセージ
    lv_retcode VARCHAR2(1)    DEFAULT NULL;  -- リターン・コード
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;  -- ユーザー・エラー・メッセージ
--
--##################################  固定部 END  ##################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_main_idx             NUMBER DEFAULT 0;                          -- メインカーソルインデックス退避用
    ln_work_idx             NUMBER DEFAULT 0;                          -- ワークテーブルインデックス退避用
    lv_get_data_flag        VARCHAR2(1)    DEFAULT NULL;               -- データ作成処理フラグ
    lv_out_msg              VARCHAR2(1000) DEFAULT NULL;               -- メッセージ出力変数
    lb_retcode              BOOLEAN        DEFAULT NULL;               -- メッセージ出力関数の戻り値
-- 2021/10/21 Ver1.5 ADD Start
    ln_msg_err_cnt          NUMBER DEFAULT 0;                          -- メッセージ見出し制御
    ln_msg_dis_cnt          NUMBER DEFAULT 0;                          -- メッセージ見出し制御
    ln_msg_ins_cnt          NUMBER DEFAULT 0;                          -- メッセージ見出し制御
-- 2021/10/21 Ver1.5 ADD End
--
    -- *** ローカル例外 ***
    no_data_expt              EXCEPTION;               -- 対象データ0件エラー
--
    -- *** ローカル・カーソル ***
    -- リカバリ対象外削除件数取得用カーソル
    CURSOR l_del_cnt_cur
    IS
-- 2021/09/17 Ver1.4 MOD Start
--      SELECT xsd.recon_slip_num     recon_slip_num
      SELECT xsd.sales_deduction_id               sales_deduction_id              --販売控除ID
             ,xsd.base_code_from                  base_code_from                  --振替元拠点
             ,xsd.base_code_to                    base_code_to                    --振替先拠点
             ,xsd.customer_code_from              customer_code_from              --振替元顧客コード
             ,xsd.customer_code_to                customer_code_to                --振替先顧客コード
             ,xsd.deduction_chain_code            deduction_chain_code            --控除用チェーンコード
             ,xsd.corp_code                       corp_code                       --企業コード
             ,xsd.record_date                     record_date                     --計上日
             ,xsd.source_category                 source_category                 --作成元区分
             ,xsd.source_line_id                  source_line_id                  --作成元明細ID
             ,xsd.condition_id                    condition_id                    --控除条件ID
             ,xsd.condition_no                    condition_no                    --控除番号
             ,xsd.condition_line_id               condition_line_id               --控除詳細ID
             ,xsd.data_type                       data_type                       --データ種類
             ,xsd.status                          status                          --ステータス
             ,xsd.item_code                       item_code                       --品目コード
             ,xsd.sales_uom_code                  sales_uom_code                  --販売単位
             ,xsd.sales_unit_price                sales_unit_price                --販売単価
             ,xsd.sales_quantity                  sales_quantity                  --販売数量
             ,xsd.sale_pure_amount                sale_pure_amount                --売上本体金額
             ,xsd.sale_tax_amount                 sale_tax_amount                 --売上消費税額
             ,xsd.deduction_uom_code              deduction_uom_code              --控除単位
             ,xsd.deduction_unit_price            deduction_unit_price            --控除単価
             ,xsd.deduction_quantity              deduction_quantity              --控除数量
             ,xsd.deduction_amount                deduction_amount                --控除額
             ,xsd.compensation                    compensation                    --補填
             ,xsd.margin                          margin                          --問屋マージン
             ,xsd.sales_promotion_expenses        sales_promotion_expenses        --拡売
             ,xsd.margin_reduction                margin_reduction                --問屋マージン減額
             ,xsd.tax_code                        tax_code                        --税コード
             ,xsd.tax_rate                        tax_rate                        --税率
             ,xsd.recon_tax_code                  recon_tax_code                  --消込時税コード
             ,xsd.recon_tax_rate                  recon_tax_rate                  --消込時税率
             ,xsd.deduction_tax_amount            deduction_tax_amount            --控除税額
             ,xsd.remarks                         remarks                         --備考
             ,xsd.application_no                  application_no                  --申請書No.
             ,xsd.gl_if_flag                      gl_if_flag                      --GL連携フラグ
             ,xsd.gl_base_code                    gl_base_code                    --GL計上拠点
             ,xsd.gl_date                         gl_date                         --GL記帳日
             ,xsd.recovery_date                   recovery_date                   --リカバリー日付
             ,xsd.recovery_add_request_id         recovery_add_request_id         --リカバリデータ追加時要求ID
             ,xsd.recovery_del_date               recovery_del_date               --リカバリデータ削除時日付
             ,xsd.recovery_del_request_id         recovery_del_request_id         --リカバリデータ削除時要求ID
             ,xsd.cancel_flag                     cancel_flag                     --取消フラグ
             ,xsd.cancel_base_code                cancel_base_code                --取消時計上拠点
             ,xsd.cancel_gl_date                  cancel_gl_date                  --取消GL記帳日
             ,xsd.cancel_user                     cancel_user                     --取消実施ユーザ
             ,xsd.recon_base_code                 recon_base_code                 --消込時計上拠点
             ,xsd.recon_slip_num                  recon_slip_num                  --支払伝票番号
             ,xsd.carry_payment_slip_num          carry_payment_slip_num          --繰越時支払伝票番号
             ,xsd.report_decision_flag            report_decision_flag            --速報確定フラグ
             ,xsd.gl_interface_id                 gl_interface_id                 --GL連携ID
             ,xsd.cancel_gl_interface_id          cancel_gl_interface_id          --取消GL連携ID
             ,flv.attribute2                      dedu_type                       --控除タイプ
             ,flv.meaning                         dedu_type_name                  --控除タイプ
             ,xcl.detail_number                   detail_number                   --明細番号
-- 2021/09/17 Ver1.4 MOD End
      FROM   xxcok_sales_deduction  xsd                                  -- 販売控除情報
-- 2021/09/17 Ver1.4 ADD Start
            ,fnd_lookup_values      flv                                  -- データ種類
            ,xxcok_condition_lines  xcl                                  -- 控除詳細情報
-- 2021/09/17 Ver1.4 ADD End
      WHERE  xsd.recon_slip_num     IS NOT NULL                            -- 支払伝票番号
      AND    xsd.source_category    IN ( cv_s_flag ,cv_t_flag
                                        ,cv_v_flag ,cv_f_flag)             -- 作成元区分
      AND    xsd.gl_if_flag         IN ( cv_y_flag ,cv_n_flag )            -- GL連携フラグ(Y:連携済、N:未連携)
      AND    xsd.status              = cv_n_flag                           -- ステータス(N：新規)
      AND    xsd.condition_line_id   = gn_condition_line_id                -- 控除詳細ID
-- 2021/09/17 Ver1.4 ADD Start
      AND  ( xsd.report_decision_flag   IS NULL         OR
             xsd.report_decision_flag    = cv_deci_flag )                  -- 速報確定フラグ
      AND    flv.lookup_type         = cv_lookup_dedu_code
      AND    flv.lookup_code         = xsd.data_type
      AND    flv.language            = USERENV('LANG')
      AND    flv.enabled_flag        = cv_y_flag
      AND    xsd.condition_line_id   = xcl.condition_line_id
      ORDER BY
             xsd.condition_id
            ,xsd.condition_line_id
-- 2021/09/17 Ver1.4 ADD End
      ;
--
    l_del_cnt_rec           l_del_cnt_cur%ROWTYPE;
--
-- 2021/10/21 Ver1.5 ADD Start
    -- *** ローカル・カーソル ***
    -- リカバリ対象外削除メッセージ出力用カーソル
    CURSOR l_del_message_cur
    IS
      SELECT 
            recon.condition_no                   condition_no                           -- 控除番号
           ,recon.deduction_type                 deduction_type                         -- 控除タイプ
           ,recon.discount_target                discount_target                        -- 入金時値引対象
           ,recon.recon_slip_num                 recon_slip_num                         -- 支払伝票番号
           ,recon.recon_status                   recon_status                           -- 消込ステータス
           ,to_char(recon.max_recon_due_date,'YYYY/MM/DD')             max_recon_due_date                     -- 支払予定日
           ,to_char(recon.target_date_end,'YYYY/MM/DD')                target_date_end                        -- 対象期間(to)
      FROM (
           SELECT 
                    xsd.sales_deduction_id               sales_deduction_id             -- 販売控除ID
                   ,xsd.condition_no                    condition_no                    -- 控除番号
                   ,xsd.condition_line_id               condition_line_id               -- 控除詳細ID
                   ,flv.attribute2                      deduction_type                  -- 控除タイプ
                   ,flv.attribute10                     discount_target                 -- 入金時値引対象
                   ,xdrh.deduction_recon_head_id        deduction_recon_head_id         -- 控除消込ヘッダーID
                   ,xdrh.recon_slip_num                 recon_slip_num                  -- 支払伝票番号
                   ,flv2.meaning                        recon_status                    -- 消込ステータス
                   ,xdrh.recon_due_date                 recon_due_date                  -- 支払予定日
                   ,max(xdrh.recon_due_date) over(partition by  xsd.condition_line_id)  
                                                        max_recon_due_date              -- MAX支払予定日
                   ,xdrh.target_date_end                target_date_end                 -- 対象期間(to)
            FROM   xxcok_sales_deduction      xsd                                       -- 販売控除情報
                  ,fnd_lookup_values          flv                                       -- データ種類
                  ,fnd_lookup_values          flv2                                      -- 控除消込ヘッダーステータス
                  ,xxcok_deduction_recon_head xdrh                                      -- 控除消込ヘッダー
            WHERE  xsd.recon_slip_num     IS NOT NULL                                   -- 支払伝票番号
            AND    xsd.source_category    IN ( cv_s_flag ,cv_t_flag
                                              ,cv_v_flag ,cv_f_flag)                    -- 作成元区分
            AND    xsd.gl_if_flag         IN ( cv_y_flag ,cv_n_flag )                   -- GL連携フラグ(Y:連携済、N:未連携)
            AND    xsd.status              = cv_n_flag                                  -- ステータス(N：新規)
            AND    xsd.condition_line_id  IN (SELECT xcl.condition_line_id     condition_line_id       -- 控除詳細ID
                                              FROM   xxcok_condition_header    xch                     -- 控除条件テーブル
                                                    ,xxcok_condition_lines     xcl                     -- 控除詳細テーブル
                                              WHERE  xch.condition_id              = xcl.condition_id  -- 控除条件ID
                                              AND (  (    xch.header_recovery_flag  = cv_d_flag)
                                                   OR(    xch.header_recovery_flag  = cv_u_flag
                                                      AND xcl.line_recovery_flag    = cv_d_flag)
                                                   OR(    xch.header_recovery_flag  = cv_n_flag
                                                      AND xcl.line_recovery_flag    = cv_d_flag))       -- リカバリ対象フラグ
                                              AND (     xch.request_id            = gn_request_id
                                                    OR  xcl.request_id            = gn_request_id)    -- 要求ID
                                             )
            AND  ( xsd.report_decision_flag   IS NULL         OR
                   xsd.report_decision_flag    = cv_deci_flag )                         -- 速報確定フラグ
            AND    flv.lookup_type         = cv_lookup_dedu_code
            AND    flv.lookup_code         = xsd.data_type
            AND    flv.language            = USERENV('LANG')
            AND    flv.enabled_flag        = cv_y_flag
            AND    flv.attribute10         = cv_n_flag                                  -- 入金時値引以外
            AND    flv2.lookup_type        = cv_head_erase_status
            AND    flv2.lookup_code        = xdrh.recon_status
            AND    flv2.language           = USERENV('LANG')
            AND    flv2.enabled_flag       = cv_y_flag
            AND    xsd.recon_slip_num      = xdrh.recon_slip_num
            UNION ALL
            SELECT xsd.sales_deduction_id              sales_deduction_id               -- 販売控除ID
                  ,xsd.condition_no                    condition_no                     -- 控除番号
                  ,xsd.condition_line_id               condition_line_id                -- 控除詳細ID
                  ,null                                deduction_type                   -- 控除タイプ
                  ,flv.attribute10                     discount_target                  -- 入金時値引対象
                  ,rct.customer_trx_id                 deduction_recon_head_id          -- 控除消込ヘッダーID
                  ,xsd.recon_slip_num                  recon_slip_num                   -- 支払伝票番号
                  ,null                                recon_status                     -- 消込ステータス
                  ,aps.due_date                        due_date                         -- 支払予定日
                  ,max(aps.due_date) over(partition by  xsd.condition_line_id)  
                                                              max_recon_due_date        -- MAX支払予定日
                  ,null                                target_date_end                  -- 対象期間(to)
            FROM   xxcok_sales_deduction      xsd                                       -- 販売控除情報
                  ,fnd_lookup_values          flv                                       -- データ種類
                  ,ra_customer_trx_all        rct                                       -- AR取引ヘッダー
                  ,ar_payment_schedules_all   aps                                       -- AR入金予定
            WHERE  xsd.recon_slip_num     IS NOT NULL                                   -- 支払伝票番号
            AND    xsd.source_category    IN ( cv_s_flag ,cv_t_flag
                                              ,cv_v_flag ,cv_f_flag)                    -- 作成元区分
            AND    xsd.gl_if_flag         IN ( cv_y_flag ,cv_n_flag )                   -- GL連携フラグ(Y:連携済、N:未連携)
            AND    xsd.status              = cv_n_flag                                  -- ステータス(N：新規)
            AND    xsd.condition_line_id  IN  (SELECT xcl.condition_line_id     condition_line_id       -- 控除詳細ID
                                               FROM   xxcok_condition_header    xch                     -- 控除条件テーブル
                                                     ,xxcok_condition_lines     xcl                     -- 控除詳細テーブル
                                               WHERE  xch.condition_id              = xcl.condition_id  -- 控除条件ID
                                               AND (  (    xch.header_recovery_flag  = cv_d_flag)
                                                    OR(    xch.header_recovery_flag  = cv_u_flag
                                                       AND xcl.line_recovery_flag    = cv_d_flag)
                                                    OR(    xch.header_recovery_flag  = cv_n_flag
                                                       AND xcl.line_recovery_flag    = cv_d_flag))       -- リカバリ対象フラグ
                                                AND  (     xch.request_id            = gn_request_id
                                                       OR  xcl.request_id            = gn_request_id)    -- 要求ID
                                               )
           AND  ( xsd.report_decision_flag   IS NULL         OR
                   xsd.report_decision_flag    = cv_deci_flag )                         -- 速報確定フラグ
            AND    flv.lookup_type         = cv_lookup_dedu_code
            AND    flv.lookup_code         = xsd.data_type
            AND    flv.language            = USERENV('LANG')
            AND    flv.enabled_flag        = cv_y_flag
            AND    flv.attribute10         = cv_y_flag                                  -- 入金時値引
            AND    xsd.recon_slip_num      = rct.trx_number
            AND    rct.customer_trx_id     = aps.customer_trx_id
            )recon
      WHERE recon.recon_due_date = recon.max_recon_due_date
      GROUP BY
            recon.condition_no                                                          -- 控除番号
           ,condition_line_id                                                           -- 控除詳細ID
           ,recon.deduction_type                                                        -- データ種類
           ,discount_target                                                             -- 入金時値引対象
           ,recon.recon_slip_num                                                        -- 支払伝票番号
           ,recon.recon_status                                                          -- 消込ステータス
           ,recon.max_recon_due_date                                                    -- 支払予定日
           ,recon.target_date_end                                                       -- 対象期間(to)
      ORDER BY 
            decode(recon.deduction_type,cv_030,'XXX', 
                   decode(recon.deduction_type,cv_040,'XXX','000'))                     -- データ種類
           ,recon.discount_target                                                       -- 入金時値引対象
           ,recon.condition_no                                                          -- 控除番号
           ,condition_line_id                                                           -- 控除詳細ID
           ,recon.recon_slip_num                                                        -- 支払伝票番号
      ;
--
    l_del_message_rec           l_del_message_cur%ROWTYPE;
--
-- 2021/10/21 Ver1.5 ADD End
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--#########################  固定ステータス初期化部 START  #########################
--
    ov_retcode := cv_status_normal;
--
--##################################  固定部 END  ##################################
--
    -- カーソルオープン
    OPEN get_condition_data_cur;       --要求ID
    -- データ取得
    FETCH get_condition_data_cur BULK COLLECT INTO gt_condition_work_tbl;
    -- カーソルクローズ
    CLOSE get_condition_data_cur;
--
    -- 取得データが０件の場合
    IF ( gt_condition_work_tbl.COUNT = 0 ) THEN
--
      -- 対象データ無しエラー
      RAISE no_data_expt;
    END IF;
--
-- 2021/10/21 Ver1.5 ADD Start
    -- リカバリ対象外メッセージ出力用カーソルオープン
    OPEN l_del_message_cur;
    LOOP
    -- データ取得
    FETCH l_del_message_cur INTO l_del_message_rec;
    EXIT WHEN l_del_message_cur%NOTFOUND;
--
      IF l_del_message_rec.deduction_type IN (cv_030,cv_040)  THEN
        IF ln_msg_ins_cnt = 0 THEN
          --支払処理中の控除を相殺する控除データ作成メッセージ見出し
          lv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_name
                                                 ,iv_name         => cv_msg_slip_date_ins_d
                                                );
--
          lb_retcode := xxcok_common_pkg.put_message_f( FND_FILE.OUTPUT    -- 出力区分
                                                       ,lv_out_msg         -- メッセージ
                                                       ,1                  -- 改行
                                                       );
        END IF;
        ln_msg_ins_cnt := ln_msg_ins_cnt + 1;
--
        --支払処理中の控除を相殺する控除データ作成メッセージ
        lv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_name
                                               ,iv_name         => cv_msg_slip_date_ins
                                               ,iv_token_name1  => cv_tkn_condition_no
                                               ,iv_token_value1 => l_del_message_rec.condition_no          -- 控除番号
                                               ,iv_token_name2  => cv_tkn_recon_slip_num
                                               ,iv_token_value2 => l_del_message_rec.recon_slip_num        -- 支払伝票番号
                                               ,iv_token_name3  => cv_tkn_target_date_end
                                               ,iv_token_value3 => l_del_message_rec.target_date_end       -- 対象期間（TO)
                                               ,iv_token_name4  => cv_tkn_due_date
                                               ,iv_token_value4 => l_del_message_rec.max_recon_due_date    -- 支払予定日
                                               ,iv_token_name5  => cv_tkn_status
                                               ,iv_token_value5 => l_del_message_rec.recon_status          -- ステータス
                                               );
--
        lb_retcode := xxcok_common_pkg.put_message_f( FND_FILE.OUTPUT    -- 出力区分
                                                     ,lv_out_msg         -- メッセージ
                                                     ,1                  -- 改行
                                                     );
--
      ELSIF l_del_message_rec.discount_target = cv_y_flag  THEN
        IF ln_msg_dis_cnt = 0 THEN
          --支払処理確定済(支払伝票が承認済)の控除データの削除スキップメッセージ(入金時値引)見出し
          lv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_name
                                                 ,iv_name         => cv_msg_slip_date_dis_d
                                                 );
--
          lb_retcode := xxcok_common_pkg.put_message_f( FND_FILE.OUTPUT    -- 出力区分
                                                       ,lv_out_msg         -- メッセージ
                                                       ,1                  -- 改行
                                                       );
        END IF;
        ln_msg_dis_cnt := ln_msg_dis_cnt + 1;
--
        --支払処理確定済(支払伝票が承認済)の控除データの削除スキップメッセージ(入金時値引)
        lv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_name
                                               ,iv_name         => cv_msg_slip_date_discount
                                               ,iv_token_name1  => cv_tkn_condition_no
                                               ,iv_token_value1 => l_del_message_rec.condition_no          -- 控除番号
                                               ,iv_token_name2  => cv_tkn_recon_slip_num
                                               ,iv_token_value2 => l_del_message_rec.recon_slip_num        -- 支払伝票番号
                                               ,iv_token_name3  => cv_tkn_due_date
                                               ,iv_token_value3 => l_del_message_rec.max_recon_due_date    -- 支払期日
                                               );
--
        lb_retcode := xxcok_common_pkg.put_message_f( FND_FILE.OUTPUT    -- 出力区分
                                                     ,lv_out_msg         -- メッセージ
                                                     ,1                  -- 改行
                                                     );
--
      ELSE
        IF ln_msg_err_cnt = 0 THEN
          --支払処理確定済(支払伝票が承認済)の控除データの削除スキップメッセージ見出し
          lv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_name
                                                 ,iv_name         => cv_msg_slip_date_err_d
                                                 );
--
          lb_retcode := xxcok_common_pkg.put_message_f( FND_FILE.OUTPUT    -- 出力区分
                                                       ,lv_out_msg         -- メッセージ
                                                       ,1                  -- 改行
                                                       );
--
        END IF;
        ln_msg_err_cnt := ln_msg_err_cnt + 1;
--
        --支払処理確定済(支払伝票が承認済)の控除データの削除スキップメッセージ
        lv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_name
                                               ,iv_name         => cv_msg_slip_date_err
                                               ,iv_token_name1  => cv_tkn_condition_no
                                               ,iv_token_value1 => l_del_message_rec.condition_no          -- 控除番号
                                               ,iv_token_name2  => cv_tkn_recon_slip_num
                                               ,iv_token_value2 => l_del_message_rec.recon_slip_num        -- 支払伝票番号
                                               ,iv_token_name3  => cv_tkn_target_date_end
                                               ,iv_token_value3 => l_del_message_rec.target_date_end       -- 対象期間（TO)
                                               ,iv_token_name4  => cv_tkn_due_date
                                               ,iv_token_value4 => l_del_message_rec.max_recon_due_date    -- 支払予定日
                                               );
--
        lb_retcode := xxcok_common_pkg.put_message_f( FND_FILE.OUTPUT    -- 出力区分
                                                     ,lv_out_msg         -- メッセージ
                                                     ,1                  -- 改行
                                                     );
      END IF;
    END LOOP;
    -- カーソルクローズ
    CLOSE l_del_message_cur;
   --
-- 2021/10/21 Ver1.5 ADD End
--
    -- 控除条件のループスタート
    <<main_data_loop>>
    FOR i IN 1..gt_condition_work_tbl.COUNT LOOP
--
      -- カーソルパラメータ用に控除詳細IDを退避
      gn_condition_line_id := gt_condition_work_tbl(i).condition_line_id;
--
--      gn_target_cnt :=  gn_target_cnt + 1;
--
      -- ヘッダーのリカバリフラグが「D：削除」または、
      -- ヘッダーのリカバリフラグが「U：更新」、明細のリカバリフラグが「D：削除」または、
      -- ヘッダーのリカバリフラグが「N：対象外」、明細のリカバリフラグが「D：削除」
      IF    ((gt_condition_work_tbl(i).header_recovery_flag  = cv_d_flag)
        OR   (gt_condition_work_tbl(i).header_recovery_flag  = cv_u_flag
        AND   gt_condition_work_tbl(i).line_recovery_flag    = cv_d_flag)
        OR   (gt_condition_work_tbl(i).header_recovery_flag  = cv_n_flag
        AND   gt_condition_work_tbl(i).line_recovery_flag    = cv_d_flag)) THEN
--
        -- 控除マスタ削除対象件数
        gn_del_target_cnt := gn_del_target_cnt + 1;
--
        -- リカバリ対象外削除件数取得用カーソルオープン
        OPEN l_del_cnt_cur;
--
        LOOP
        -- データ取得
        FETCH l_del_cnt_cur INTO l_del_cnt_rec;
        EXIT WHEN l_del_cnt_cur%NOTFOUND;
--
-- 2021/09/17 Ver1.4 ADD Start
          IF l_del_cnt_rec.dedu_type IN (cv_030,cv_040)  THEN
            INSERT INTO xxcok_sales_deduction(
              sales_deduction_id       --販売控除ID
             ,base_code_from           --振替元拠点
             ,base_code_to             --振替先拠点
             ,customer_code_from       --振替元顧客コード
             ,customer_code_to         --振替先顧客コード
             ,deduction_chain_code     --控除用チェーンコード
             ,corp_code                --企業コード
             ,record_date              --計上日
             ,source_category          --作成元区分
             ,source_line_id           --作成元明細ID
             ,condition_id             --控除条件ID
             ,condition_no             --控除番号
             ,condition_line_id        --控除詳細ID
             ,data_type                --データ種類
             ,status                   --ステータス
             ,item_code                --品目コード
             ,sales_uom_code           --販売単位
             ,sales_unit_price         --販売単価
             ,sales_quantity           --販売数量
             ,sale_pure_amount         --売上本体金額
             ,sale_tax_amount          --売上消費税額
             ,deduction_uom_code       --控除単位
             ,deduction_unit_price     --控除単価
             ,deduction_quantity       --控除数量
             ,deduction_amount         --控除額
             ,compensation             --補填
             ,margin                   --問屋マージン
             ,sales_promotion_expenses --拡売
             ,margin_reduction         --問屋マージン減額
             ,tax_code                 --税コード
             ,tax_rate                 --税率
             ,recon_tax_code           --消込時税コード
             ,recon_tax_rate           --消込時税率
             ,deduction_tax_amount     --控除税額
             ,remarks                  --備考
             ,application_no           --申請書No.
             ,gl_if_flag               --GL連携フラグ
             ,gl_base_code             --GL計上拠点
             ,gl_date                  --GL記帳日
             ,recovery_date            --リカバリー日付
             ,recovery_add_request_id  --リカバリデータ追加時要求ID
             ,recovery_del_date        --リカバリデータ削除時日付
             ,recovery_del_request_id  --リカバリデータ削除時要求ID
             ,cancel_flag              --取消フラグ
             ,cancel_base_code         --取消時計上拠点
             ,cancel_gl_date           --取消GL記帳日
             ,cancel_user              --取消実施ユーザ
             ,recon_base_code          --消込時計上拠点
             ,recon_slip_num           --支払伝票番号
             ,carry_payment_slip_num   --繰越時支払伝票番号
             ,report_decision_flag     --速報確定フラグ
             ,gl_interface_id          --GL連携ID
             ,cancel_gl_interface_id   --取消GL連携ID
             ,created_by               --作成者
             ,creation_date            --作成日
             ,last_updated_by          --最終更新者
             ,last_update_date         --最終更新日
             ,last_update_login        --最終更新ログイン
             ,request_id               --要求ID
             ,program_application_id   --コンカレント・プログラム・アプリケーションID
             ,program_id               --コンカレント・プログラムID
             ,program_update_date      --プログラム更新日
              )
            VALUES
             (
              xxcok_sales_deduction_s01.nextval           --販売控除ID
             ,l_del_cnt_rec.base_code_from                --振替元拠点
             ,l_del_cnt_rec.base_code_to                  --振替先拠点
             ,l_del_cnt_rec.customer_code_from            --振替元顧客コード
             ,l_del_cnt_rec.customer_code_to              --振替先顧客コード
             ,l_del_cnt_rec.deduction_chain_code          --控除用チェーンコード
             ,l_del_cnt_rec.corp_code                     --企業コード
             ,l_del_cnt_rec.record_date                   --計上日
             ,l_del_cnt_rec.source_category               --作成元区分
             ,l_del_cnt_rec.source_line_id                --作成元明細ID
             ,l_del_cnt_rec.condition_id                  --控除条件ID
             ,l_del_cnt_rec.condition_no                  --控除番号
             ,l_del_cnt_rec.condition_line_id             --控除詳細ID
             ,l_del_cnt_rec.data_type                     --データ種類
             ,cv_n_flag                                   --ステータス
             ,l_del_cnt_rec.item_code                     --品目コード
             ,l_del_cnt_rec.sales_uom_code                --販売単位
             ,l_del_cnt_rec.sales_unit_price              --販売単価
             ,l_del_cnt_rec.sales_quantity * -1           --販売数量
             ,l_del_cnt_rec.sale_pure_amount * -1         --売上本体金額
             ,l_del_cnt_rec.sale_tax_amount * -1          --売上消費税額
             ,l_del_cnt_rec.deduction_uom_code            --控除単位
             ,l_del_cnt_rec.deduction_unit_price          --控除単価
             ,l_del_cnt_rec.deduction_quantity * -1       --控除数量
             ,l_del_cnt_rec.deduction_amount * -1         --控除額
             ,l_del_cnt_rec.compensation * -1             --補填
             ,l_del_cnt_rec.margin * -1                   --問屋マージン
             ,l_del_cnt_rec.sales_promotion_expenses * -1 --拡売
             ,l_del_cnt_rec.margin_reduction * -1         --問屋マージン減額
             ,l_del_cnt_rec.tax_code                      --税コード
             ,l_del_cnt_rec.tax_rate                      --税率
             ,NULL                                        --消込時税コード
             ,NULL                                        --消込時税率
             ,l_del_cnt_rec.deduction_tax_amount * -1     --控除税額
             ,l_del_cnt_rec.sales_deduction_id            --備考
             ,l_del_cnt_rec.application_no                --申請書No.
             ,cv_n_flag                                   --GL連携フラグ
             ,NULL                                        --GL計上拠点
             ,NULL                                        --GL記帳日
             ,gd_proc_date                                --リカバリー日付
             ,cn_request_id                               --リカバリデータ追加時要求ID
             ,NULL                                        --リカバリデータ削除時日付
             ,NULL                                        --リカバリデータ削除時要求ID
             ,cv_n_flag                                   --取消フラグ
             ,NULL                                        --取消時計上拠点
             ,NULL                                        --取消GL記帳日
             ,NULL                                        --取消実施ユーザ
             ,NULL                                        --消込時計上拠点
             ,NULL                                        --支払伝票番号
             ,NULL                                        --繰越時支払伝票番号
             ,l_del_cnt_rec.report_decision_flag          --速報確定フラグ
             ,NULL                                        --GL連携ID
             ,NULL                                        --取消GL連携ID
             ,cn_created_by                               -- 作成者
             ,cd_creation_date                            -- 作成日
             ,cn_last_updated_by                          -- 最終更新者
             ,cd_last_update_date                         -- 最終更新日
             ,cn_last_update_login                        -- 最終更新ログイン
             ,cn_request_id                               -- 要求ID
             ,cn_program_application_id                   -- コンカレント・プログラム・アプリケーションID
             ,cn_program_id                               -- コンカレント・プログラムID
             ,cd_program_update_date                      -- プログラム更新日
             );
--
-- 2021/10/21 Ver1.5 DELL Start
--            lv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_name
--                                                   ,iv_name         => cv_msg_slip_date_ins
--                                                   ,iv_token_name1  => cv_tkn_column_value
--                                                   ,iv_token_value1 => l_del_cnt_rec.condition_no ||',' ||l_del_cnt_rec.detail_number  -- 控除番号、明細番号
--                                                   ,iv_token_name2  => cv_tkn_data_type
--                                                   ,iv_token_value2 => l_del_cnt_rec.dedu_type_name                                    -- データ種類
--                                                   ,iv_token_name3  => cv_tkn_recon_slip_num
--                                                   ,iv_token_value3 => l_del_cnt_rec.recon_slip_num                                    -- 支払伝票番号
--                                                   );
--
--            lb_retcode := xxcok_common_pkg.put_message_f( FND_FILE.OUTPUT    -- 出力区分
--                                                         ,lv_out_msg         -- メッセージ
--                                                         ,1                  -- 改行
--                                                         );
-- 2021/10/21 Ver1.5 DELL End
--
            gn_del_ins_cnt := gn_del_ins_cnt + 1;
-- 2021/09/17 Ver1.4 ADD End
-- 2021/09/17 Ver1.4 MOD Start
          ELSE
-- 2021/10/21 Ver1.5 DELL Start
--            lv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_name
--                                                   ,iv_name         => cv_msg_slip_date_err
--                                                   ,iv_token_name1  => cv_tkn_recon_slip_num
--                                                   ,iv_token_value1 => l_del_cnt_rec.recon_slip_num        -- 支払伝票番号
--                                                   );
--
--            lb_retcode := xxcok_common_pkg.put_message_f( FND_FILE.OUTPUT    -- 出力区分
--                                                         ,lv_out_msg         -- メッセージ
--                                                         ,1                  -- 改行
--                                                         );
-- 2021/10/21 Ver1.5 DELL End
--
            gn_del_skip_cnt := gn_del_skip_cnt + 1;
          END IF;
-- 2021/09/17 Ver1.4 MOD End
        END LOOP;
        -- カーソルクローズ
        CLOSE l_del_cnt_cur;
--
        -- ============================================================
        -- A-3.販売控除取消処理の呼び出し
        -- ============================================================
        sales_deduction_delete(in_condition_line_id => gn_condition_line_id
                              ,iv_syori_type        => NULL                 -- 処理区分
                              ,ov_errbuf            => lv_errbuf            -- エラー・メッセージ
                              ,ov_retcode           => lv_retcode           -- リターン・コード
                              ,ov_errmsg            => lv_errmsg            -- ユーザー・エラー・メッセージ
                               );
--
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
      -- 控除タイプが「070：定額控除」以外且つ
      ELSIF  gt_condition_work_tbl(i).deduction_type       <> '070' THEN
--
        -- ヘッダーのリカバリフラグが「I：追加」、明細のリカバリフラグが「I：追加」または、
        -- ヘッダーのリカバリフラグが「U：更新」、明細のリカバリフラグが「I：追加」、「U：更新」、「N：対象外」または、
        -- ヘッダーのリカバリフラグが「N：対象外」、明細のリカバリフラグが「I：追加」、「U：更新」
        IF    (gt_condition_work_tbl(i).header_recovery_flag = cv_i_flag
          AND  gt_condition_work_tbl(i).line_recovery_flag   = cv_i_flag)
          OR  (gt_condition_work_tbl(i).header_recovery_flag = cv_u_flag
          AND  gt_condition_work_tbl(i).line_recovery_flag  IN (cv_i_flag,cv_u_flag,cv_n_flag))
          OR  (gt_condition_work_tbl(i).header_recovery_flag = cv_n_flag
          AND  gt_condition_work_tbl(i).line_recovery_flag  IN (cv_i_flag,cv_u_flag)) THEN
--
          -- 控除マスタ登録対象件数
          gn_add_target_cnt := gn_add_target_cnt + 1;
--
          -- 未来日付の控除データ発生時の削除処理用にワークへ控除条件ID、控除詳細ID、終了日を退避
          IF  (gt_condition_work_tbl(i).header_recovery_flag = cv_u_flag) THEN
--
            -- カウントアップ
            ln_work_idx := ln_work_idx + 1;
--
            gt_condition_work_1_tbl(ln_work_idx).condition_id       :=gt_condition_work_tbl(i).condition_id;       -- 控除条件ID
            gt_condition_work_1_tbl(ln_work_idx).condition_line_id  :=gt_condition_work_tbl(i).condition_line_id;  -- 控除詳細ID
            gt_condition_work_1_tbl(ln_work_idx).end_date_active    :=gt_condition_work_tbl(i).end_date_active;    -- 終了日
          END IF;
--
--
          INSERT INTO xxcok_condition_recovery_temp(
            condition_id                                         -- 控除条件ID
           ,condition_no                                         -- 控除番号
           ,corp_code                                            -- 企業コード
           ,deduction_chain_code                                 -- 控除用チェーンコード
           ,customer_code                                        -- 顧客コード
           ,start_date_active                                    -- 開始日
           ,end_date_active                                      -- 終了日
           ,data_type                                            -- データ種類
           ,tax_code_con                                         -- 税コード
           ,tax_rate_con                                         -- 税率
           ,enabled_flag_h                                       -- ヘッダ有効フラグ
           ,header_recovery_flag                                 -- ヘッダーリカバリ対象フラグ
           ,condition_line_id                                    -- 控除詳細ID
           ,product_class                                        -- 商品区分
           ,item_code                                            -- 品目コード
           ,uom_code                                             -- 単位
           ,target_category                                      -- 対象区分
           ,shop_pay_1                                           -- 店納(％)
           ,material_rate_1                                      -- 料率(％)
           ,condition_unit_price_en_2                            -- 条件単価２(円)
-- 2020/12/03 Ver1.1 ADD Start
           ,compensation_en_3                                    -- 補填(円)
           ,wholesale_margin_en_3                                -- 問屋マージン(円)
-- 2020/12/03 Ver1.1 ADD End
           ,accrued_en_3                                         -- 未収計３(円)
-- 2020/12/03 Ver1.1 ADD Start
           ,just_condition_en_4                                  -- 今回条件(円)
           ,wholesale_adj_margin_en_4                            -- 問屋マージン修正(円)
-- 2020/12/03 Ver1.1 ADD End
           ,accrued_en_4                                         -- 未収計４(円)
           ,condition_unit_price_en_5                            -- 条件単価５(円)
           ,deduction_unit_price_en_6                            -- 控除単価(円)
           ,enabled_flag_l                                       -- 明細有効フラグ
           ,line_recovery_flag                                   -- 明細リカバリ対象フラグ
          )VALUES(
            gt_condition_work_tbl(i).condition_id                -- 控除条件ID
           ,gt_condition_work_tbl(i).condition_no                -- 控除番号
           ,gt_condition_work_tbl(i).corp_code                   -- 企業コード
           ,gt_condition_work_tbl(i).deduction_chain_code        -- 控除用チェーンコード
           ,gt_condition_work_tbl(i).customer_code               -- 顧客コード
           ,gt_condition_work_tbl(i).start_date_active           -- 開始日
           ,gt_condition_work_tbl(i).end_date_active             -- 終了日
           ,gt_condition_work_tbl(i).data_type                   -- データ種類
           ,gt_condition_work_tbl(i).tax_code                    -- 税コード
           ,gt_condition_work_tbl(i).tax_rate                    -- 税率
           ,gt_condition_work_tbl(i).enabled_flag_h              -- ヘッダ有効フラグ
           ,gt_condition_work_tbl(i).header_recovery_flag        -- ヘッダーリカバリ対象フラグ
           ,gt_condition_work_tbl(i).condition_line_id           -- 控除詳細ID
           ,gt_condition_work_tbl(i).product_class               -- 商品区分
           ,gt_condition_work_tbl(i).item_code                   -- 品目コード
           ,gt_condition_work_tbl(i).uom_code                    -- 単位
           ,gt_condition_work_tbl(i).target_category             -- 対象区分
           ,gt_condition_work_tbl(i).shop_pay_1                  -- 店納(％)
           ,gt_condition_work_tbl(i).material_rate_1             -- 料率(％)
           ,gt_condition_work_tbl(i).condition_unit_price_en_2   -- 条件単価２(円)
-- 2020/12/03 Ver1.1 ADD Start
           ,gt_condition_work_tbl(i).compensation_en_3           -- 補填(円)
           ,gt_condition_work_tbl(i).wholesale_margin_en_3       -- 問屋マージン(円)
-- 2020/12/03 Ver1.1 ADD End
           ,gt_condition_work_tbl(i).accrued_en_3                -- 未収計３(円)
-- 2020/12/03 Ver1.1 ADD Start
           ,gt_condition_work_tbl(i).just_condition_en_4         -- 今回条件(円)
           ,gt_condition_work_tbl(i).wholesale_adj_margin_en_4   -- 問屋マージン修正(円)
-- 2020/12/03 Ver1.1 ADD End
           ,gt_condition_work_tbl(i).accrued_en_4                -- 未収計４(円)
           ,gt_condition_work_tbl(i).condition_unit_price_en_5   -- 条件単価５(円)
           ,gt_condition_work_tbl(i).deduction_unit_price_en_6   -- 控除単価(円)
           ,gt_condition_work_tbl(i).enabled_flag_l              -- 明細有効フラグ
           ,gt_condition_work_tbl(i).line_recovery_flag          -- 明細リカバリ対象フラグ
            )
          ;
--
          lv_get_data_flag := cv_y_flag;
--
        END IF;
      -- 控除タイプが「070：定額控除」
      ELSIF   gt_condition_work_tbl(i).deduction_type       = '070' THEN
--
        -- ヘッダーのリカバリフラグが「I：追加」、明細のリカバリフラグが「I：追加」または、
        -- ヘッダーのリカバリフラグが「U：更新」、明細のリカバリフラグが「I：追加」、「U：更新」、「N：対象外」または、
        -- ヘッダーのリカバリフラグが「N：対象外」、明細のリカバリフラグが「I：追加」、「U：更新」
        IF    ( gt_condition_work_tbl(i).header_recovery_flag = cv_i_flag
          AND   gt_condition_work_tbl(i).line_recovery_flag   = cv_i_flag)
          OR  ( gt_condition_work_tbl(i).header_recovery_flag = cv_u_flag
          AND   gt_condition_work_tbl(i).line_recovery_flag  IN (cv_i_flag,cv_u_flag,cv_n_flag))
          OR  ( gt_condition_work_tbl(i).header_recovery_flag = cv_n_flag
          AND   gt_condition_work_tbl(i).line_recovery_flag  IN (cv_i_flag,cv_u_flag)) THEN
--
          -- 控除マスタ登録対象件数
          gn_add_target_cnt := gn_add_target_cnt + 1;
--
          -- メインカーソルのインデックス退避
          ln_main_idx := i ;
--
          -- 開始期間確認
          -- 開始日が業務日付より未来の控除マスタの場合
-- 2021/07/26 Ver1.3 MOD Start
--          IF gt_condition_work_tbl(i).start_date_active > gd_proc_date THEN
          IF gt_condition_work_tbl(i).start_date_active > gd_proc_date -1 THEN
-- 2021/07/26 Ver1.3 MOD End
             NULL;
          ELSE
--
            -- 終了日が業務日付より未来の場合
-- 2021/07/26 Ver1.3 MOD Start
--            IF gt_condition_work_tbl(i).end_date_active > gd_proc_date THEN
            IF gt_condition_work_tbl(i).end_date_active > gd_proc_date -1  THEN
-- 2021/07/26 Ver1.3 MOD End
--
              -- ワーク日付に業務日付の当月月初を設定
-- 2021/07/26 Ver1.3 MOD Start
--              gd_work_date := LAST_DAY(ADD_MONTHS(gd_proc_date,-1)) + cn_1;
              gd_work_date := LAST_DAY(ADD_MONTHS(gd_proc_date -1,-1)) + cn_1;
-- 2021/07/26 Ver1.3 MOD End
--
              -- ワーク日付(業務日付)が開始日よりも大きい間は繰返し処理を実施
              WHILE gd_work_date >= gt_condition_work_tbl(i).start_date_active  LOOP
--
                -- ============================================================
                -- A-6.販売控除データ登録の呼び出し
                -- ============================================================
                insert_data( iv_syori_type => cv_f_flag              -- 処理区分
                            ,in_main_idx   => ln_main_idx            -- メインインデックス
                            ,ov_errbuf     => lv_errbuf              -- エラー・メッセージ
                            ,ov_retcode    => lv_retcode             -- リターン・コード
                            ,ov_errmsg     => lv_errmsg              -- ユーザー・エラー・メッセージ
                            );
--
                IF  lv_retcode  = cv_status_normal  THEN
                  gn_add_cnt :=  gn_add_cnt + 1;
                ELSIF lv_retcode  = cv_status_warn  THEN
                  ov_retcode    := cv_status_warn;
                  gn_cal_skip_cnt   :=  gn_cal_skip_cnt   + 1;
                ELSE
                  RAISE global_process_expt;
                END IF;
--
                -- ワーク日付の月をカウントダウン
                gd_work_date := ADD_MONTHS(gd_work_date,-1);
--
              END LOOP;
--
            -- 終了日が業務日付より過去の場合
            ELSE
--
              -- ワーク日付に終了日の当月月初を設定
              gd_work_date := LAST_DAY(ADD_MONTHS(gt_condition_work_tbl(i).end_date_active,-1)) + cn_1;
--
              -- ワーク日付が開始日よりも大きい間は繰返し処理を実施
              WHILE gd_work_date >= gt_condition_work_tbl(i).start_date_active  LOOP
--
                -- ============================================================
                -- A-6.販売控除データ登録の呼び出し
                -- ============================================================
                insert_data( iv_syori_type => cv_f_flag              -- 処理区分
                            ,in_main_idx   => ln_main_idx            -- メインインデックス
                            ,ov_errbuf     => lv_errbuf              -- エラー・メッセージ
                            ,ov_retcode    => lv_retcode             -- リターン・コード
                            ,ov_errmsg     => lv_errmsg              -- ユーザー・エラー・メッセージ
                            );
--
                IF  lv_retcode  = cv_status_normal  THEN
                  gn_add_cnt :=  gn_add_cnt + 1;
                ELSIF lv_retcode  = cv_status_warn  THEN
                  ov_retcode    := cv_status_warn;
                  gn_cal_skip_cnt   :=  gn_cal_skip_cnt   + 1;
                ELSE
                  RAISE global_process_expt;
                END IF;
--
                -- ワーク日付の月をカウントダウン
                gd_work_date := ADD_MONTHS(gd_work_date,-1);
--
              END LOOP;
--
            END IF;
          END IF;
--
        END IF;
      END IF;
    END LOOP main_data_loop;
--
--
    -- ============================================================
    -- A-4.控除データ抽出の呼び出し
    -- ============================================================
    IF ( lv_get_data_flag = cv_y_flag ) THEN
      get_data(ov_errbuf           =>  lv_errbuf                                      -- エラー・メッセージ
              ,ov_retcode          =>  lv_retcode                                     -- リターン・コード
              ,ov_errmsg           =>  lv_errmsg                                      -- ユーザー・エラー・メッセージ
               );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
  EXCEPTION
    -- データ取得エラー（データ0件） ***
    WHEN no_data_expt THEN
      ov_retcode := cv_status_warn;
      gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_short_name
                   ,iv_name         => cv_data_get_msg
                   );
--
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg                --ユーザー・エラーメッセージ
      );
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルクローズ
      IF ( get_condition_data_cur%ISOPEN ) THEN
        CLOSE get_condition_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF ( get_condition_data_cur%ISOPEN ) THEN
        CLOSE get_condition_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF ( get_condition_data_cur%ISOPEN ) THEN
        CLOSE get_condition_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--##################################  固定部 END  ##################################
--
  END get_condition_data;
--
  /**********************************************************************************
   * Procedure Name   : condition_update
   * Description      : A-7.控除情報更新
   ***********************************************************************************/
  PROCEDURE condition_update( ov_errbuf      OUT    VARCHAR2    -- エラー・メッセージ           -- # 固定 #
                            , ov_retcode     OUT    VARCHAR2    -- リターン・コード             -- # 固定 #
                            , ov_errmsg      OUT    VARCHAR2    -- ユーザー・エラー・メッセージ -- # 固定 #
                             )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'condition_update'; -- プログラム名
--
    -- *** ローカル・カーソル ***
    -- 排他制御削除用カーソル
    CURSOR l_target_ctl_info_del_cur
    IS
      SELECT  eci.request_id
      FROM    xxcok_exclusive_ctl_info eci
      WHERE   eci.request_id  = gn_request_id
      FOR UPDATE NOWAIT
      ;
    l_target_ctl_info_del_rec    l_target_ctl_info_del_cur%ROWTYPE;
--
    -- *** ローカル例外 ***
    lock_expt       EXCEPTION;
    PRAGMA EXCEPTION_INIT(lock_expt, -54);                  -- ロックエラー
    --

--############################  固定ローカル変数宣言部 START  ############################
--
    lv_errbuf  VARCHAR2(5000);              -- エラー・メッセージ
    lv_retcode VARCHAR2(1);                 -- リターン・コード
    lv_errmsg  VARCHAR2(5000);              -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END  #####################################
--
  BEGIN
--
--############################  固定ステータス初期化部 START  ############################
--
    ov_retcode := cv_status_normal;
--
--#####################################  固定部 END  #####################################
--
    --==============================================================
    -- 終了日よりも未来に発生している控除データを削除
    --==============================================================
    -- 処理対象データが0件以上の場合更新処理を実施する
    IF ( gt_condition_work_1_tbl.COUNT > 0 ) THEN
      BEGIN
        FORALL i IN 1..gt_condition_work_1_tbl.COUNT
          UPDATE xxcok_sales_deduction  xsd                                  -- 販売控除情報
          SET    xsd.status                  = cv_c_flag                                -- ステータス
                ,xsd.gl_if_flag              = CASE
                                                 WHEN xsd.gl_if_flag  = cv_n_flag THEN
                                                   cv_u_flag
                                                 ELSE
                                                   cv_r_flag
                                               END                                      -- GL連携フラグ
                ,xsd.recovery_del_date       = gd_proc_date                             -- リカバリー日付
                ,xsd.cancel_flag             = cv_y_flag                                -- キャンセルフラグ
                ,xsd.recovery_del_request_id = cn_request_id                            -- リカバリデータ削除時要求ID
                ,xsd.cancel_user             = cn_created_by                            -- 取消ユーザID
                ,xsd.last_updated_by         = cn_last_updated_by                       -- 最終更新者
                ,xsd.last_update_date        = cd_last_update_date                      -- 最終更新日
                ,xsd.last_update_login       = cn_last_update_login                     -- 最終更新ログイン
                ,xsd.request_id              = cn_request_id                            -- 要求ID
                ,xsd.program_application_id  = cn_program_application_id                -- コンカレント・プログラム・アプリID
                ,xsd.program_id              = cn_program_id                            -- コンカレント・プログラムID
                ,xsd.program_update_date     = cd_program_update_date                   -- プログラム更新日
          WHERE  xsd.condition_id        = gt_condition_work_1_tbl(i).condition_id       -- 控除条件ID
          AND    xsd.condition_line_id   = gt_condition_work_1_tbl(i).condition_line_id  -- 控除詳細ID
          AND    xsd.record_date         > gt_condition_work_1_tbl(i).end_date_active    -- 売上日
          AND    xsd.recon_slip_num     IS NULL                                          -- 支払伝票番号
          AND    xsd.source_category    IN ( cv_s_flag ,cv_t_flag
                                            ,cv_v_flag ,cv_f_flag )                      -- 作成元区分
          AND    xsd.gl_if_flag         IN ( cv_y_flag ,cv_n_flag )                      -- GL連携フラグ(Y:連携済、N:未連携)
          AND    xsd.status              = cv_n_flag                                     -- ステータス(N：新規)
          ;
--
        EXCEPTION
          WHEN OTHERS THEN
            ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
            ov_retcode := cv_status_error;
      END;
    END IF;
--
    --==============================================================
    -- 控除条件テーブルのデータ更新
    --==============================================================
    UPDATE xxcok_condition_header
    SET    header_recovery_flag = cv_n_flag
    WHERE  request_id           = gn_request_id
    ;
--
    --==============================================================
    -- 控除詳細テーブルのデータ更新
    --==============================================================
    UPDATE xxcok_condition_lines
    SET    line_recovery_flag   = cv_n_flag
    WHERE  request_id           = gn_request_id
    ;

    BEGIN
      -- 排他制御削除用カーソルオープン
      OPEN  l_target_ctl_info_del_cur;
      FETCH l_target_ctl_info_del_cur INTO l_target_ctl_info_del_rec;
      CLOSE l_target_ctl_info_del_cur;
--
      --==============================================================
      -- 排他制御管理テーブルのデータ削除
      --==============================================================
      DELETE FROM xxcok_exclusive_ctl_info eci
      WHERE  eci.request_id  = gn_request_id
      ;
--
    EXCEPTION
      -- ロックエラー
      WHEN lock_expt THEN
        -- カーソルクローズ
        IF ( l_target_ctl_info_del_cur%ISOPEN ) THEN
          CLOSE l_target_ctl_info_del_cur;
        END IF;
        -- ロックエラーメッセージ
        ov_errmsg := xxccp_common_pkg.get_msg( cv_xxcok_short_name
                                              ,cv_msg_lock_err
                                               );
        ov_errbuf :=  cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg||SQLERRM;
        ov_retcode := cv_status_error;
      -- *** 処理部共通例外ハンドラ ***
    END
    ;
--
  EXCEPTION
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END condition_update;
--
/**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain( ov_errbuf   OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
                    ,ov_retcode  OUT VARCHAR2  -- リターン・コード             --# 固定 #
                    ,ov_errmsg   OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
                    )
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
--
    -- ===============================
    -- 固定ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000)      DEFAULT NULL;  -- エラー・メッセージ
    lv_retcode VARCHAR2(1)         DEFAULT NULL;  -- リターン・コード
    lv_errmsg  VARCHAR2(5000)      DEFAULT NULL;  -- ユーザー・エラー・メッセージ
--
  BEGIN
--
--#########################  固定ステータス初期化部 START  #########################
--
    ov_retcode := cv_status_normal;
--
--##################################  固定部 END  ##################################
--
    -- グローバル変数の初期化
    gn_del_target_cnt :=  0;
    gn_add_target_cnt :=  0;
    gn_del_cnt        :=  0;
    gn_add_cnt        :=  0;
    gn_cal_skip_cnt   :=  0;
    gn_del_skip_cnt   :=  0;
-- 2021/09/17 Ver1.4 ADD Start
    gn_del_ins_cnt    :=  0;
-- 2021/09/17 Ver1.4 ADD End
    gn_add_skip_cnt   :=  0;
    gn_error_cnt  :=  0;
--
    -- ===============================
    -- A-1  初期処理
    -- ===============================
    init( ov_errbuf   =>  lv_errbuf                          -- エラー・メッセージ
         ,ov_retcode  =>  lv_retcode                         -- リターン・コード
         ,ov_errmsg   =>  lv_errmsg                          -- ユーザー・エラー・メッセージ
         );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2  控除情報更新対象抽出
    -- ===============================
    get_condition_data( ov_errbuf   =>  lv_errbuf            -- エラー・メッセージ
                       ,ov_retcode  =>  lv_retcode           -- リターン・コード
                       ,ov_errmsg   =>  lv_errmsg            -- ユーザー・エラー・メッセージ
                       );
--
    IF  ( lv_retcode  = cv_status_warn)  THEN
      ov_retcode  :=  cv_status_warn;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-7  控除情報更新
    -- ===============================
    condition_update( ov_errbuf   =>  lv_errbuf              -- エラー・メッセージ
                     ,ov_retcode  =>  lv_retcode             -- リターン・コード
                     ,ov_errmsg   =>  lv_errmsg              -- ユーザー・エラー・メッセージ
                     );
--
    IF  ( lv_retcode  = cv_status_warn)  THEN
      ov_retcode  :=  cv_status_warn;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
--############################    固定例外処理部 START  ############################
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
--##################################  固定部 END  ##################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ(終了処理A-8を含む)
   **********************************************************************************/
--
  PROCEDURE main( errbuf        OUT    VARCHAR2         -- エラー・メッセージ  --# 固定 #
                 ,retcode       OUT    VARCHAR2         -- リターン・コード    --# 固定 #
                 ,in_request_id IN     NUMBER           -- 要求ID
                 )
--
--#################################  固定部 START  #################################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';                -- プログラム名
--
    cv_appl_short_name CONSTANT VARCHAR2(20)  := 'XXCCP';               -- アドオン：共通・IF領域
    cv_error_rec_msg   CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90002';    -- エラー件数メッセージ
    cv_del_target_msg  CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10719';    -- 控除マスタ削除対象件数
    cv_add_target_msg  CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10720';    -- 控除マスタ登録対象件数
    cv_del_msg         CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10721';    -- 控除データ削除件数
    cv_add_msg         CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10722';    -- 控除データ登録件数
    cv_cal_skip_msg    CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10723';    -- 控除データ控除額算出スキップ件数
    cv_del_skip_msg    CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10724';    -- 控除データ削除支払済スキップ件数
-- 2021/09/17 Ver1.4 ADD Start
    cv_del_ins_msg     CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10806';    -- マイナス控除データ登録件数
-- 2021/09/17 Ver1.4 ADD End
    cv_add_skip_msg    CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10725';    -- 控除データ登録支払済スキップ件数
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';               -- 件数メッセージ用トークン名
    cv_data_no_get_msg CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00001';    -- 対象なしメッセージ
    cv_normal_msg      CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90004';    -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90005';    -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90006';    -- エラー終了全ロールバック
    cv_msg_cok_10593   CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10593';    -- 控除額算出エラー
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000)      DEFAULT NULL;    -- エラー・メッセージ
    lv_retcode         VARCHAR2(1)         DEFAULT NULL;    -- リターン・コード
    lv_errmsg          VARCHAR2(5000)      DEFAULT NULL;    -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100)       DEFAULT NULL;    -- 終了メッセージコード
--
  BEGIN
--
--#################################  固定部 START  #################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header( ov_retcode => lv_retcode
                                    ,ov_errbuf  => lv_errbuf
                                    ,ov_errmsg  => lv_errmsg
                                    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--##################################  固定部 END  ##################################
--
    -- 入力パラメータを変数に格納
    gn_request_id := in_request_id;
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain( ov_errbuf  => lv_errbuf                 -- エラー・メッセージ
            ,ov_retcode => lv_retcode                -- リターン・コード
            ,ov_errmsg  => lv_errmsg                 -- ユーザー・エラー・メッセージ
            );
--
    -- ===============================
    -- A-8.終了処理
    -- ===============================
    -- エラー出力
    IF ( lv_retcode <> cv_status_normal ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg      -- ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf      -- エラーメッセージ
      );
-- 2021/10/21 Ver1.5 ADD Start 支払済データが存在する場合は警告
    ELSE
      IF gn_add_skip_cnt > 0 or gn_del_ins_cnt > 0 THEN
         lv_retcode := cv_status_warn;
      END IF;
-- 2021/10/21 Ver1.5 END Start
    END IF;
--
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- エラーの場合、成功件数クリア
    IF ( lv_retcode = cv_status_error ) THEN
      gn_del_target_cnt := 0;                    -- 控除マスタ削除対象件数
      gn_add_target_cnt := 0;                    -- 控除マスタ登録対象件数
      gn_del_cnt        := 0;                    -- 控除データ削除件数
      gn_add_cnt        := 0;                    -- 控除データ登録件数
      gn_cal_skip_cnt   := 0;                    -- 控除データ控除額算出スキップ件数
      gn_del_skip_cnt   := 0;                    -- 控除データ削除支払済スキップ件数
-- 2021/09/17 Ver1.4 ADD Start
      gn_del_ins_cnt    := 0;                    -- 控除データ削除マイナス控除データ登録件数
-- 2021/09/17 Ver1.4 ADD End
      gn_add_skip_cnt   := 0;                    -- 控除データ登録支払済スキップ件数
      gn_error_cnt      := 1;                    -- エラー件数
    END IF;
--
    -- 控除マスタ削除対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcok_short_name
                    ,iv_name         => cv_del_target_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_del_target_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- 控除マスタ登録対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcok_short_name
                    ,iv_name         => cv_add_target_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_add_target_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- 控除データ削除件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcok_short_name
                    ,iv_name         => cv_del_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_del_cnt )

                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- 控除データ登録件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcok_short_name
                    ,iv_name         => cv_add_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_add_cnt )
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- 控除データ控除額算出スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcok_short_name
                    ,iv_name         => cv_cal_skip_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_cal_skip_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- 控除データ削除支払済スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcok_short_name
                    ,iv_name         => cv_del_skip_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_del_skip_cnt )

                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
-- 2021/09/17 Ver1.4 ADD Start
    -- 控除データ削除マイナス控除データ登録件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcok_short_name
                    ,iv_name         => cv_del_ins_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_del_ins_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
-- 2021/09/17 Ver1.4 ADD End    -- 控除データ登録支払済スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcok_short_name
                    ,iv_name         => cv_add_skip_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_add_skip_cnt )
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- 終了メッセージ
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
--
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_appl_short_name
                                           ,iv_name         => lv_message_code
                                           );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    -- ステータスセット
    retcode := lv_retcode;
    -- 終了ステータスがエラーの場合はROLLBACKする
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    ELSE
      COMMIT;
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
--##################################  固定部 END  ##################################
--
END XXCOK024A09C;
/
