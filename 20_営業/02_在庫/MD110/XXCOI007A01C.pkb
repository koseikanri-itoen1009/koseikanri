CREATE OR REPLACE PACKAGE BODY XXCOI007A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI007A01C(body)
 * Description      : 資材配賦情報の差額仕訳※の生成。※原価差額(標準原価-営業原価)
 * MD.050           : 調整仕訳自動生成 MD050_COI_007_A01
 * Version          : 1.10
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理 (A-1)
 *  get_mtl_txn_acct       資材配賦情報の抽出 (A-2)
 *  del_xwcv_last_data     原価差額ワークテーブルの前回データ削除 (A-3)
 *  get_cost_info          原価情報取得処理 (A-4)
 *  ins_xwcv               原価差額ワークテーブルの作成 (A-5)
 *  ins_gl_if              原価差額情報GL-IF登録
 *                         - 原価差額情報の抽出 (A-6)
 *                         - 会計期間チェック処理 (A-7)
 *                         - GLインターフェース格納 (A-8)
 *  ins_gl_if_gr_comp      棚卸資産情報GL-IF登録(グループ会社) (A-10)
 *  ins_gl_if_reg          GL-IF登録処理(A-11)
 *  ins_xwcv_bk            在庫受払表（Ｇ会社）テーブルの作成 (A-12)
 *  ins_gl_if_round_Journal 丸め誤差GL-IF登録 (A-13)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                         終了処理 (A-9)
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/14    1.0   T.Kojima        新規作成
 *  2009/03/26    1.1   H.Sasaki        [障害T1_0120]
 *  2009/05/11    1.2   T.Nakamura      [障害T1_0933]
 *  2009/05/11    1.3   T.Nakamura      [T1_1327]営業原価更新時の調整仕分け処理を追加
 *  2009/07/14    1.4   S.Moriyama      [0000261]記帳日を取引日からパラメータ指定日or業務日付へ変更
 *                                      取引日が前月の場合は前月末日を記帳日とする
 *  2009/08/17    1.5   N.Abe           [0001089]PT対応
 *  2009/08/25    1.6   H.Sasaki        [0001159]PT対応
 *  2009/09/04    1.7   H.Sasaki        [0001241]勘定科目名の設定内容変更
 *  2009/09/28    1.8   H.Sasaki        [E_T3_00605]リカバリ処理を実装
 *  2010/01/29    1.9   H.Sasaki        [E_本稼動_01335]GLバッチID取得エラー時のエラーハンドリングを修正
 *  2024/03/18    1.10  R.Oikawa        [E_本稼動_19496] グループ会社対応
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
  gn_normal_cnt    NUMBER;                    -- 成功件数
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
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  profile_expt        EXCEPTION;    -- プロファイル値取得例外
-- == 2009/07/14 V1.4 Added START ===============================================================
  org_code_expt       EXCEPTION;    -- 在庫組織プロファイル値取得例外
-- == 2009/07/14 V1.4 Added END   ===============================================================
-- == 2009/08/17 V1.5 Added START ===============================================================
  period_name_expt    EXCEPTION;    -- 会計期間名取得エラー
-- == 2009/08/17 V1.5 Added END   ===============================================================
  lock_expt           EXCEPTION;    -- ロック処理例外
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                CONSTANT VARCHAR2(100) := 'XXCOI007A01C';     -- パッケージ名
  cv_appl_short_name_xxccp   CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
  cv_appl_short_name_xxcoi   CONSTANT VARCHAR2(10)  := 'XXCOI';            -- アドオン：在庫領域
  cv_appl_short_name_sqlgl   CONSTANT VARCHAR2(10)  := 'SQLGL';            -- General Ledger
  cv_normal_record           CONSTANT VARCHAR2(1)   := 'Y';                -- 通常レコード
  cv_error_record            CONSTANT VARCHAR2(1)   := 'N';                -- エラーレコード
  -- メッセージ
  cv_msg_no_prm              CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008';    -- コンカレント入力パラメータなし
  cv_msg_profile_get_err     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00032';    -- プロファイル値取得エラー
  cv_msg_group_id_get_err    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10320';    -- グループID取得エラー
  cv_msg_gl_batch_id_get_err CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10063';    -- GLバッチID取得エラーメッセージ
  cv_msg_no_data             CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00008';    -- 対象データ無しメッセージ
  cv_msg_acct_tbl_chk_err    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10123';    -- 勘定科目テーブルチェックエラーメッセージ
  cv_msg_std_cost_get_err    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10124';    -- 標準原価取得エラーメッセージ
  cv_msg_oprtn_cost_get_err  CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10125';    -- 営業原価取得エラーメッセージ
  cv_msg_acctg_period_err    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10319';    -- 会計期間エラーメッセージ
  cv_msg_lock_err            CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10064';    -- ロックエラーメッセージ原価差額ワークテーブル
  cv_msg_unit_mtl_txn_acct   CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10339';    -- 資材配賦情報単位件数メッセージ
  cv_msg_unit_cost_sum       CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10340';    -- 原価差額集約単位件数メッセージ
-- == 2009/06/04 V1.3 Added START ===============================================================
  cv_msg_code_xxcoi_10256    CONSTANT VARCHAR2(30)  :=  'APP-XXCOI1-10256';   -- 取引タイプID取得エラーメッセージ
-- == 2009/06/04 V1.3 Added END   ===============================================================
-- == 2009/07/14 V1.4 Added START ===============================================================
  cv_msg_code_xxcoi_00005    CONSTANT VARCHAR2(30)  :=  'APP-XXCOI1-00005';   -- 在庫組織コード取得エラーメッセージ
  cv_msg_code_xxcoi_10384    CONSTANT VARCHAR2(30)  :=  'APP-XXCOI1-10384';   -- パラメータ設定記帳日メッセージ
-- == 2009/07/14 V1.4 Added END   ===============================================================
-- == 2009/08/17 V1.5 Added START ===============================================================
  cv_msg_code_xxcoi_10399    CONSTANT VARCHAR2(30)  :=  'APP-XXCOI1-10399';   -- 会計期間名取得エラーメッセージ
-- == 2009/08/17 V1.5 Added END   ===============================================================
-- == 2009/09/28 V1.8 Added START ===============================================================
  cv_msg_code_xxcoi_10405    CONSTANT VARCHAR2(30)  :=  'APP-XXCOI1-10405';   -- 会計期間オープンチェックエラーメッセージ
  cv_msg_code_xxcoi_10406    CONSTANT VARCHAR2(30)  :=  'APP-XXCOI1-10406';   -- 記帳日チェックエラーメッセージ
-- == 2009/09/28 V1.8 Added END   ===============================================================
--
  -- トークン
  cv_tkn_profile             CONSTANT VARCHAR2(25)  := 'PRO_TOK';                 -- プロファイル名
  cv_tkn_source              CONSTANT VARCHAR2(25)  := 'SOURCE';                  -- 仕訳ソース名
  cv_tkn_account_id          CONSTANT VARCHAR2(25)  := 'ACCOUNT_ID';              -- 勘定科目ID
  cv_tkn_account             CONSTANT VARCHAR2(25)  := 'ACCOUNT';                 -- 勘定科目
  cv_tkn_item_code           CONSTANT VARCHAR2(25)  := 'ITEM_CODE';               -- 品目コード
  cv_tkn_dept                CONSTANT VARCHAR2(25)  := 'DEPT';                    -- 部門
  cv_tkn_period              CONSTANT VARCHAR2(25)  := 'PERIOD';                  -- 会計期間
-- == 2009/03/26 V1.1 Added START ===============================================================
  cv_tkn_subacct             CONSTANT VARCHAR2(25)  := 'SUBACCT';                 -- 補助科目コード
-- == 2009/03/26 V1.1 Added END   ===============================================================
-- == 2009/08/17 V1.5 Added START ===============================================================
  cv_date                    CONSTANT VARCHAR2(25)  := 'DATE';                     -- 会計期間
-- == 2009/08/17 V1.5 Added END   ===============================================================
-- == 2009/06/04 V1.3 Added START ===============================================================
  cv_tkn_transaction_type    CONSTANT VARCHAR2(30)  := 'TRANSACTION_TYPE_TOK';    -- 取引タイプ
-- == 2009/06/04 V1.3 Added END   ===============================================================
-- == 2009/07/14 V1.4 Added START ===============================================================
  cv_prf_org                 CONSTANT VARCHAR2(25) := 'XXCOI1_ORGANIZATION_CODE'; -- XXCOI:在庫組織コード
  cv_tkn_effective_date      CONSTANT VARCHAR2(25) := 'P_EFFECTIVE_DATE';         -- 設定記帳日
-- == 2009/07/14 V1.4 Added END   ===============================================================
-- == 2009/09/28 V1.8 Added START ===============================================================
  cv_tkn_xxcoi_msg_10405     CONSTANT VARCHAR2(30)  :=  'ACCT_PERIOD';            -- 会計期間比較対象日付
-- == 2009/09/28 V1.8 Added END   ===============================================================
-- Ver1.10 ADD START
  cv_prf_aff2_acc_dept_code  CONSTANT VARCHAR2(50)  :=  'XXCOI1_ACCOUT_DEPT_CODE';     -- XXCOI:経理部用部門コード
  cv_prf_gl_category_inv_gr  CONSTANT VARCHAR2(50)  :=  'XXCOI1_GL_CATEGORY_INV_GR';   -- XXCOI:仕訳カテゴリ_在庫グループ会社振替
  cv_company_profit_rate     CONSTANT VARCHAR2(30)  :=  'XXCOI1_COMPANY_PROFIT_RATE';  -- 各社利益率
  cv_conv_dept_code          CONSTANT VARCHAR2(30)  :=  'XXCFO1_CONV_DEPT_CODE';       -- 部門コード変換
  cv_conv_cost_dept          CONSTANT VARCHAR2(50)  :=  'XXCFO1_CONV_COST_DEPT';       -- 売上原価の計上部門
  cv_conv_cost_account       CONSTANT VARCHAR2(50)  :=  'XXCFO1_CONV_COST_ACCOUNT';    -- 売上原価の勘定科目・補助科目コード変換
  cv_msg_code_xxcoi_10750    CONSTANT VARCHAR2(100) :=  'APP-XXCOI1-10750';            -- 参照タイプ取得エラーメッセージ
  cv_msg_code_xxcoi_10751    CONSTANT VARCHAR2(100) :=  'APP-XXCOI1-10751';            -- グループ会社集約単位件数
  cv_tkn_lookup_type         CONSTANT VARCHAR2(25)  :=  'LOOKUP_TYPE';                 -- 参照タイプ
  cv_0                       CONSTANT VARCHAR2(1)   :=  '0';                           -- 0
  cv_1                       CONSTANT VARCHAR2(1)   :=  '1';                           -- 1
  cn_transaction_type_118    CONSTANT NUMBER        :=  118;                           -- 工場直送入庫
  cn_transaction_type_119    CONSTANT NUMBER        :=  119;                           -- 工場直送入庫振戻
  cn_transaction_type_120    CONSTANT NUMBER        :=  120;                           -- 工場直送出庫
  cn_transaction_type_121    CONSTANT NUMBER        :=  121;                           -- 工場直送出庫振戻
  cv_pkg_name_gr_comp        CONSTANT VARCHAR2(2)   :=  '_2';                          -- 仕訳名(グループ会社用)
-- Ver1.10 ADD END
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- 資材配賦情報格納用
  TYPE g_mtl_txn_acct_rtype IS RECORD(
      mta_transaction_id         mtl_transaction_accounts.transaction_id%TYPE         --  1.在庫取引ID
    , gcc_dept_code              gl_code_combinations.segment2%TYPE                   --  2.部門コード
    , xwcv_adj_dept_code         gl_code_combinations.segment2%TYPE                   --  3.調整部門コード
    , mta_account_id             mtl_transaction_accounts.reference_account%TYPE      --  4.勘定科目ID
    , gcc_account_code           gl_code_combinations.segment3%TYPE                   --  5.勘定科目コード
-- == 2009/03/26 V1.1 Added Start ===============================================================
    , gcc_subacct_code           gl_code_combinations.segment4%TYPE                   --  6.補助科目コード
-- == 2009/03/26 V1.1 Added END   ===============================================================
    , mta_inventory_item_id      mtl_transaction_accounts.inventory_item_id%TYPE      --  7.品目ID
    , msib_item_code             mtl_system_items_b.segment1%TYPE                     --  8.品目コード
    , mta_transaction_date       mtl_transaction_accounts.transaction_date%TYPE       --  9.取引日
    , mta_transaction_value      mtl_transaction_accounts.transaction_value%TYPE      -- 10.取引金額
    , mta_primary_quantity       mtl_transaction_accounts.primary_quantity%TYPE       -- 11.取引数量
    , mta_base_transaction_value mtl_transaction_accounts.base_transaction_value%TYPE -- 12.基準単位金額
    , mta_organization_id        mtl_transaction_accounts.organization_id%TYPE        -- 13.組織ID
    , mta_gl_batch_id            mtl_transaction_accounts.gl_batch_id%TYPE            -- 14.GLバッチID
-- == 2009/06/04 V1.3 Added Start ===============================================================
    , transaction_type_id        mtl_material_transactions.transaction_type_id%TYPE   -- 15.取引タイプID
-- == 2009/06/04 V1.3 Added END   ===============================================================
  );
  TYPE g_mtl_txn_acct_ttype IS TABLE OF g_mtl_txn_acct_rtype INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_target_sum_cnt              NUMBER;                                              -- 対象件数  (原価差額集約単位)
  gn_normal_sum_cnt              NUMBER;                                              -- 成功件数  (原価差額集約単位)
  gn_error_sum_cnt               NUMBER;                                              -- エラー件数(原価差額集約単位)
  gt_gl_set_of_bks_id            gl_interface.set_of_books_id%TYPE;                   -- 会計帳簿ID
  gt_gl_set_of_bks_name          gl_interface.context%TYPE;                           -- 会計帳簿名
  gt_aff1_company_code           gl_interface.segment1%TYPE;                          -- 会社コード
  gt_aff2_adj_dept_code          gl_interface.segment2%TYPE;                          -- 調整部門コード
  gt_aff3_shizuoka_factory       gl_interface.segment3%TYPE;                          -- 勘定科目_静岡工場勘定
  gt_aff4_dummy                  gl_interface.segment4%TYPE;                          -- 補助科目_ダミー値
  gt_aff5_dummy                  gl_interface.segment5%TYPE;                          -- 顧客コード_ダミー値
  gt_aff6_dummy                  gl_interface.segment6%TYPE;                          -- 企業コード_ダミー値
  gt_aff7_dummy                  gl_interface.segment7%TYPE;                          -- 予備１_ダミー値
  gt_aff8_dummy                  gl_interface.segment8%TYPE;                          -- 予備２_ダミー値
  gt_je_category_name_inv_cost   gl_interface.user_je_category_name%TYPE;             -- 仕訳カテゴリ名(在庫原価振替)
  gt_je_source_name_inv_cost     gl_interface.user_je_source_name%TYPE;               -- 仕訳ソース名  (在庫原価振替)
  gt_sales_calendar              gl_periods.period_set_name%TYPE;                     -- 会計カレンダ
  gt_je_batch_name               gl_interface.reference1%TYPE;                        -- 仕訳バッチ名
  gt_group_id                    gl_interface.group_id%TYPE;                          -- グループID
  gt_last_gl_batch_id            xxcoi_wk_cost_variance.gl_batch_id%TYPE;             -- 前回GLバッチID
  gt_pre_inventory_item_id       mtl_transaction_accounts.inventory_item_id%TYPE;     -- 前回情報：品目ID
  gt_pre_transaction_date        mtl_transaction_accounts.transaction_date%TYPE;      -- 前回情報：取引日
  gt_pre_errbuf_cmpnt_cost       VARCHAR2(1);                                         -- 前回情報：標準原価取得エラー・メッセージ
  gt_pre_retcode_cmpnt_cost      VARCHAR2(1);                                         -- 前回情報：標準原価取得リターン・コード
  gt_pre_errbuf_discrete_cost    VARCHAR2(1);                                         -- 前回情報：営業原価取得エラー・メッセージ
  gt_pre_retcode_discrete_cost   VARCHAR2(1);                                         -- 前回情報：営業原価取得リターン・コード
  g_mtl_txn_acct_tab             g_mtl_txn_acct_ttype;                                -- PL/SQL表：資材配賦情報格納用
  gn_mtl_txn_acct_cnt            NUMBER;                                              -- PL/SQL表インデックス
-- == 2009/06/04 V1.3 Added START ===============================================================
  gt_trans_type_std_cost_upd     mtl_transaction_types.transaction_type_id%TYPE;      -- 取引タイプID（標準原価更新）
-- == 2009/06/04 V1.3 Added END   ===============================================================
-- == 2009/07/14 V1.4 Added START ===============================================================
  gt_effective_date              gl_je_lines.effective_date%TYPE;                     -- 記帳日
  gt_last_period_date            gl_periods.end_date%TYPE;                            -- 前会計期間最終日
  gt_min_org_acct_date           org_acct_periods.period_start_date%TYPE;             -- 在庫会計期間オープン最古日付
  gt_org_code                    mtl_parameters.organization_code%TYPE;               -- 在庫組織コード
-- == 2009/07/14 V1.4 Added END   ===============================================================
-- == 2009/08/17 V1.5 Added START ===============================================================
  gt_period_name_tm              gl_periods.period_name%TYPE;                         --会計期間名(当月)
  gt_period_name_lm              gl_periods.period_name%TYPE;                         --会計期間名(前月)
-- == 2009/08/17 V1.5 Added END   ===============================================================
-- == 2009/09/04 V1.7 Added START ===============================================================
  gt_aff3_seihin                gl_interface.segment3%TYPE;                          -- 勘定科目_製品
  gt_aff3_shouhin               gl_interface.segment3%TYPE;                          -- 勘定科目_商品
-- == 2009/09/04 V1.7 Added END   ===============================================================
-- Ver1.10 ADD START
  gt_aff2_acc_dept_code         gl_interface.segment2%TYPE;                          -- 経理部用部門コード
  gt_aff2_cost_dept_dr          gl_interface.segment2%TYPE;                          -- 売上原価の計上部門（借方）
  gt_aff2_cost_dept_cr          gl_interface.segment2%TYPE;                          -- 売上原価の計上部門（貸方）
  gt_aff3_cost_account          gl_interface.segment3%TYPE;                          -- 売上原価の勘定科目
  gt_aff4_cost_sub_acct         gl_interface.segment4%TYPE;                          -- 売上原価の補助科目
  gt_aff3_payable               gl_interface.segment3%TYPE;                          -- 勘定科目_買掛金
  gt_aff4_payable               gl_interface.segment4%TYPE;                          -- 補助科目_買掛金
  gt_aff3_rounding_error        gl_interface.segment3%TYPE;                          -- 勘定科目_丸め誤差
  gt_aff4_rounding_error        gl_interface.segment4%TYPE;                          -- 補助科目_丸め誤差
  gt_je_category_name_inv_gr    gl_interface.user_je_category_name%TYPE;             -- 仕訳カテゴリ名(在庫グループ会社振替)
  gn_target_sum_cnt_gr          NUMBER;                                              -- 対象件数  (グループ会社集約単位)
  gn_error_sum_cnt_gr           NUMBER;                                              -- エラー件数(グループ会社集約単位)
-- Ver1.10 ADD END
--
-- == 2009/09/28 V1.8 Added START ===============================================================
  CURSOR mtl_txn_acct_cur
  IS
    SELECT  sub.mta_transaction_id                  --  1.在庫取引ID
           ,sub.gcc_dept_code                       --  2.部門コード
           ,sub.xwcv_adj_dept_code                  --  3.調整部門コード
           ,sub.mta_account_id                      --  4.勘定科目ID
           ,sub.gcc_account_code                    --  5.勘定科目コード
           ,sub.gcc_subacct_code                    --  6.補助科目コード
           ,sub.mta_inventory_item_id               --  7.品目ID
           ,sub.msib_item_code                      --  8.品目コード
           ,sub.mta_transaction_date                --  9.取引日
           ,sub.mta_transaction_value               -- 10.取引金額
           ,sub.mta_primary_quantity                -- 11.取引数量
           ,sub.mta_base_transaction_value          -- 12.基準単位金額
           ,sub.mta_organization_id                 -- 13.組織ID
           ,sub.mta_gl_batch_id                     -- 14.GLバッチID
           ,sub.transaction_type_id                 -- 15.取引タイプID
           ,sub.data_type                           -- 16.データタイプ（1:資材配賦データ、2:リカバリ用データ）
-- Ver1.10 ADD START
           ,CASE WHEN sub.transaction_type_id IN (cn_transaction_type_118,cn_transaction_type_119,
                                              cn_transaction_type_120,cn_transaction_type_121) THEN  -- 工場直送入庫/出庫
                   NVL(sub.company_code, gt_aff1_company_code)
                 ELSE
                   xbdciv.company_code_bd
            END company_code                                  -- 17.会社コード
           ,NVL(mtt.attribute6, cv_0) transfer_ownership_flg  -- 18.所有権移転取引フラグ
-- Ver1.10 ADD END
    FROM    (SELECT  /*+ LEADING(MTA) USE_NL(MTA MMT GCC MSIB) */
                     mta.transaction_id              AS mta_transaction_id            --  1
                    ,gcc.segment2                    AS gcc_dept_code                 --  2
                    ,CASE WHEN gcc.segment3 IN(gt_aff3_shizuoka_factory, gt_aff3_seihin, gt_aff3_shouhin) THEN  -- 勘定科目コードが静岡工場勘定の場合
                            gcc.segment2                                                                        -- 部門コード
                          ELSE                                                                                  -- それ以外の場合
                            gt_aff2_adj_dept_code                                                               -- A-1.で取得した調整部門コード
                     END                             AS xwcv_adj_dept_code            --  3
                    ,mta.reference_account           AS mta_account_id                --  4
                    ,gcc.segment3                    AS gcc_account_code              --  5
                    ,gcc.segment4                    AS gcc_subacct_code              --  6
                    ,mta.inventory_item_id           AS mta_inventory_item_id         --  7
                    ,msib.segment1                   AS msib_item_code                --  8
                    ,mta.transaction_date            AS mta_transaction_date          --  9
                    ,mta.transaction_value           AS mta_transaction_value         -- 10
                    ,mta.primary_quantity            AS mta_primary_quantity          -- 11
                    ,mta.base_transaction_value      AS mta_base_transaction_value    -- 12
                    ,mta.organization_id             AS mta_organization_id           -- 13
                    ,mta.gl_batch_id                 AS mta_gl_batch_id               -- 14
                    ,mmt.transaction_type_id         AS transaction_type_id           -- 15
                    ,1                               AS data_type                     -- 16
-- Ver1.10 ADD START
                    ,mmt.attribute7                  AS company_code                  -- 17
-- Ver1.10 ADD END
             FROM    mtl_transaction_accounts        mta                              -- 資材配賦テーブル
                    ,gl_code_combinations            gcc                              -- 勘定科目テーブル
                    ,mtl_system_items_b              msib                             -- Disc品目マスタ
                    ,mtl_material_transactions       mmt                              -- 資材取引
             WHERE  mta.reference_account       = gcc.code_combination_id             -- CCID
             AND    mta.gl_batch_id             > gt_last_gl_batch_id                 -- GLバッチID > 前回GLバッチID
             AND    msib.inventory_item_id      = mta.inventory_item_id               -- 品目ID
             AND    msib.organization_id        = mta.organization_id                 -- 組織ID
             AND    mta.transaction_id          = mmt.transaction_id                  -- 取引ID
             AND    mta.transaction_date        BETWEEN gt_min_org_acct_date AND SYSDATE
             UNION ALL
             SELECT  xwecv.transaction_id            AS mta_transaction_id            --  1
                    ,xwecv.dept_code                 AS gcc_dept_code                 --  2
                    ,xwecv.adj_dept_code             AS xwcv_adj_dept_code            --  3
                    ,xwecv.account_id                AS mta_account_id                --  4
                    ,xwecv.account_code              AS gcc_account_code              --  5
                    ,xwecv.subacct_code              AS gcc_subacct_code              --  6
                    ,xwecv.inventory_item_id         AS mta_inventory_item_id         --  7
                    ,xwecv.item_code                 AS msib_item_code                --  8
                    ,xwecv.transaction_date          AS mta_transaction_date          --  9
                    ,xwecv.transaction_value         AS mta_transaction_value         -- 10
                    ,xwecv.primary_quantity          AS mta_primary_quantity          -- 11
                    ,xwecv.base_transaction_value    AS mta_base_transaction_value    -- 12
                    ,xwecv.organization_id           AS mta_organization_id           -- 13
                    ,xwecv.gl_batch_id               AS mta_gl_batch_id               -- 14
                    ,xwecv.transaction_type_id       AS transaction_type_id           -- 15
                    ,2                               AS data_type                     -- 16
-- Ver1.10 ADD START
                    ,xwecv.company_code              AS company_code                  -- 17
-- Ver1.10 ADD END
             FROM    xxcoi_wk_error_cost_variance    xwecv                            -- 原価差額ワークテーブル（エラー）
            ) sub
-- Ver1.10 ADD START
            ,xxcfr_bd_dept_comp_info_v xbdciv                              -- 基準日部門会社情報ビュー
            ,mtl_transaction_types     mtt                                 -- 取引タイプマスタ
    WHERE  xbdciv.dept_code        = sub.gcc_dept_code                     -- 部門
    AND    xbdciv.set_of_books_id  = gt_gl_set_of_bks_id                   -- 会計帳簿ID
    AND    xbdciv.enabled_flag     = 'Y'
    AND    sub.mta_transaction_date BETWEEN NVL( xbdciv.comp_start_date, sub.mta_transaction_date )
                                AND     NVL( xbdciv.comp_end_date, sub.mta_transaction_date )
    AND    mtt.transaction_type_id = sub.transaction_type_id
-- Ver1.10 ADD END
    ORDER BY sub.mta_inventory_item_id                                                -- 品目ID
           , sub.mta_transaction_date;                                                -- 取引日
  --
  mtl_txn_acct_rec    mtl_txn_acct_cur%ROWTYPE;
-- == 2009/09/28 V1.8 Added END   ===============================================================
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理 (A-1)
   ***********************************************************************************/
  PROCEDURE init(
-- == 2009/07/14 V1.4 Added START ===============================================================
      iv_effective_date  IN  VARCHAR2      -- 記帳日
-- == 2009/07/14 V1.4 Added END   ===============================================================
    , ov_errbuf       OUT VARCHAR2      -- エラー・メッセージ           --# 固定 #
    , ov_retcode      OUT VARCHAR2      -- リターン・コード             --# 固定 #
    , ov_errmsg       OUT VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- プロファイル
    cv_prf_gl_set_of_bks_id           CONSTANT VARCHAR2(50) := 'GL_SET_OF_BKS_ID';                  -- 会計帳簿ID
    cv_prf_gl_set_of_bks_name         CONSTANT VARCHAR2(50) := 'GL_SET_OF_BKS_NAME';                -- 会計帳簿名
    cv_prf_company_code               CONSTANT VARCHAR2(50) := 'XXCOI1_COMPANY_CODE';               -- XXCOI:会社コード
    cv_prf_aff2_adj_dept_code         CONSTANT VARCHAR2(50) := 'XXCOI1_AFF2_ADJUSTMENT_DEPT_CODE';  -- XXCOI:調整部門コード
    cv_prf_aff3_shizuoka_factory      CONSTANT VARCHAR2(50) := 'XXCOI1_AFF3_SHIZUOKA_FACTORY';      -- XXCOI:勘定科目_静岡工場勘定
    cv_prf_aff4_subacct_dummy         CONSTANT VARCHAR2(50) := 'XXCOK1_AFF4_SUBACCT_DUMMY';         -- XXCOK:補助科目_ダミー値
    cv_prf_aff5_customer_dummy        CONSTANT VARCHAR2(50) := 'XXCOK1_AFF5_CUSTOMER_DUMMY';        -- XXCOK:顧客コード_ダミー値
    cv_prf_aff6_company_dummy         CONSTANT VARCHAR2(50) := 'XXCOK1_AFF6_COMPANY_DUMMY';         -- XXCOK:企業コード_ダミー値
    cv_prf_aff7_preliminary1_dummy    CONSTANT VARCHAR2(50) := 'XXCOK1_AFF7_PRELIMINARY1_DUMMY';    -- XXCOK:予備１_ダミー値
    cv_prf_aff8_preliminary2_dummy    CONSTANT VARCHAR2(50) := 'XXCOK1_AFF8_PRELIMINARY2_DUMMY';    -- XXCOK:予備２_ダミー値
    cv_prf_gl_category_inv_cost       CONSTANT VARCHAR2(50) := 'XXCOI1_GL_CATEGORY_INV_COST';       -- XXCOI:仕訳カテゴリ_在庫原価振替
    cv_prf_gl_source_inv_cost         CONSTANT VARCHAR2(50) := 'XXCOI1_GL_SOURCE_INV_COST';         -- XXCOI:仕訳ソース_在庫原価振替
    cv_prf_sales_calendar             CONSTANT VARCHAR2(50) := 'XXCOI1_SALES_CALENDAR';             -- XXCOI:会計カレンダ
-- == 2009/06/04 V1.3 Added START ===============================================================
    cv_prf_trans_type_std_cost_upd    CONSTANT VARCHAR2(50) := 'XXCOI1_TRANS_TYPE_STD_COST_UPD';    -- XXCOI:取引タイプ名_標準原価更新
-- == 2009/06/04 V1.3 Added END   ===============================================================
-- == 2009/09/04 V1.7 Added START ===============================================================
    cv_prf_aff3_seihin                CONSTANT VARCHAR2(30) :=  'XXCOI1_AFF3_SEIHIN';               -- XXCOI:勘定科目_製品
    cv_prf_aff3_shouhin               CONSTANT VARCHAR2(30) :=  'XXCOI1_AFF3_SHOUHIN';              -- XXCOI:勘定科目_商品
-- == 2009/09/04 V1.7 Added END   ===============================================================
-- == 2009/08/17 V1.5 Added START ===============================================================
    cv_flag_n                          CONSTANT VARCHAR2(1)  := 'N';                                -- フラグ値：N
-- == 2009/08/17 V1.5 Added END   ===============================================================
-- Ver1.10 ADD START
    cv_prf_aff3_payable               CONSTANT VARCHAR2(50) := 'XXCOI1_AFF3_PAYABLE';               -- XXCOI:勘定科目_買掛金
    cv_prf_aff4_payable               CONSTANT VARCHAR2(50) := 'XXCOI1_AFF4_PAYABLE';               -- XXCOI:勘定科目_買掛金
    cv_prf_aff3_rounding_error        CONSTANT VARCHAR2(50) := 'XXCOI1_AFF3_ROUNDING_ERROR';        -- XXCOI:勘定科目_丸め誤差
    cv_prf_aff4_rounding_error        CONSTANT VARCHAR2(50) := 'XXCOI1_AFF4_ROUNDING_ERROR';        -- XXCOI:補助科目_丸め誤差
-- Ver1.10 ADD END
--
    -- *** ローカル変数 ***
    lv_tkn_profile   VARCHAR2(50);  -- トークン：プロファイル
-- == 2009/06/04 V1.3 Added START ===============================================================
    lt_std_cost_upd  mtl_transaction_types.transaction_type_name%TYPE;                              -- 取引タイプ名（標準原価更新）
-- == 2009/06/04 V1.3 Added END   ===============================================================
-- == 2009/07/14 V1.4 Added START ===============================================================
    lv_effective_date  VARCHAR2(10);                                                                -- 記帳日
-- == 2009/07/14 V1.4 Added END   ===============================================================
-- == 2009/09/28 V1.8 Added START ===============================================================
    lb_acctg_period_chk BOOLEAN;                                                                    -- 会計期間チェック用 TRUE：オープン/FALSE：クローズ
-- == 2009/09/28 V1.8 Added END   ===============================================================
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
-- == 2009/07/14 V1.4 Mod START ===============================================================
--    -- ==============================================================
--    -- コンカレント入力パラメータなしメッセージ出力
--    -- ==============================================================
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                      iv_application => cv_appl_short_name_xxccp
--                    , iv_name        => cv_msg_no_prm
--                  );
    --==============================================================
    --コンカレントパラメータ出力
    --==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_xxcoi
                    , iv_name         => cv_msg_code_xxcoi_10384
                    , iv_token_name1  => cv_tkn_effective_date
                    , iv_token_value1 => SUBSTRB ( iv_effective_date , 1 , 10)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => gv_out_msg
    );
-- == 2009/07/14 V1.4 Mod END ===============================================================
    -- 空行出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => ''
    );
--
    -- ==============================================================
    -- プロファイル値取得
    -- ==============================================================
    -- 会計帳簿ID
    gt_gl_set_of_bks_id := fnd_profile.value( cv_prf_gl_set_of_bks_id );
    IF( gt_gl_set_of_bks_id IS NULL ) THEN
      lv_tkn_profile := cv_prf_gl_set_of_bks_id;
      RAISE profile_expt;
    END IF;
--
    -- 会計帳簿名
    gt_gl_set_of_bks_name := fnd_profile.value( cv_prf_gl_set_of_bks_name );
    IF( gt_gl_set_of_bks_name IS NULL ) THEN
      lv_tkn_profile := cv_prf_gl_set_of_bks_name;
      RAISE profile_expt;
    END IF;
--
    -- 会社コード
    gt_aff1_company_code := fnd_profile.value( cv_prf_company_code );
    IF( gt_aff1_company_code IS NULL ) THEN
      lv_tkn_profile := cv_prf_company_code;
      RAISE profile_expt;
    END IF;
--
    -- 調整部門コード
    gt_aff2_adj_dept_code := fnd_profile.value( cv_prf_aff2_adj_dept_code );
    IF( gt_aff2_adj_dept_code IS NULL ) THEN
      lv_tkn_profile := cv_prf_aff2_adj_dept_code;
      RAISE profile_expt;
    END IF;
--
-- Ver1.10 ADD START
    -- 経理部用部門コード
    gt_aff2_acc_dept_code := fnd_profile.value( cv_prf_aff2_acc_dept_code );
    IF( gt_aff2_acc_dept_code IS NULL ) THEN
      lv_tkn_profile := cv_prf_aff2_acc_dept_code;
      RAISE profile_expt;
    END IF;
--
    -- 勘定科目_買掛金
    gt_aff3_payable := fnd_profile.value( cv_prf_aff3_payable );
    IF( gt_aff3_payable IS NULL ) THEN
      lv_tkn_profile := cv_prf_aff3_payable;
      RAISE profile_expt;
    END IF;
--
    -- 補助科目_買掛金
    gt_aff4_payable := fnd_profile.value( cv_prf_aff4_payable );
    IF( gt_aff4_payable IS NULL ) THEN
      lv_tkn_profile := cv_prf_aff4_payable;
      RAISE profile_expt;
    END IF;
--
    -- 仕訳カテゴリ名(在庫グループ会社振替)
    gt_je_category_name_inv_gr := fnd_profile.value( cv_prf_gl_category_inv_gr );
    IF( gt_je_category_name_inv_gr IS NULL ) THEN
      lv_tkn_profile := cv_prf_gl_category_inv_gr;
      RAISE profile_expt;
    END IF;
--
    -- 勘定科目_丸め誤差
    gt_aff3_rounding_error := fnd_profile.value( cv_prf_aff3_rounding_error );
    IF( gt_aff3_rounding_error IS NULL ) THEN
      lv_tkn_profile := cv_prf_aff3_rounding_error;
      RAISE profile_expt;
    END IF;
--
    -- 補助科目_丸め誤差
    gt_aff4_rounding_error := fnd_profile.value( cv_prf_aff4_rounding_error );
    IF( gt_aff4_rounding_error IS NULL ) THEN
      lv_tkn_profile := cv_prf_aff4_rounding_error;
      RAISE profile_expt;
    END IF;
-- Ver1.10 ADD END
    -- 勘定科目_静岡工場勘定
    gt_aff3_shizuoka_factory := fnd_profile.value( cv_prf_aff3_shizuoka_factory );
    IF( gt_aff3_shizuoka_factory IS NULL ) THEN
      lv_tkn_profile := cv_prf_aff3_shizuoka_factory;
      RAISE profile_expt;
    END IF;
--
-- == 2009/03/26 V1.1 Deleted START ===============================================================
    -- 補助科目_ダミー値
--    gt_aff4_dummy := fnd_profile.value( cv_prf_aff4_subacct_dummy );
--    IF( gt_aff4_dummy IS NULL ) THEN
--      lv_tkn_profile := cv_prf_aff4_subacct_dummy;
--      RAISE profile_expt;
--    END IF;
-- == 2009/03/26 V1.1 Deleted END   ===============================================================
--
    -- 顧客コード_ダミー値
    gt_aff5_dummy := fnd_profile.value( cv_prf_aff5_customer_dummy );
    IF( gt_aff5_dummy IS NULL ) THEN
      lv_tkn_profile := cv_prf_aff5_customer_dummy;
      RAISE profile_expt;
    END IF;
--
    -- 企業コード_ダミー値
    gt_aff6_dummy := fnd_profile.value( cv_prf_aff6_company_dummy );
    IF( gt_aff6_dummy IS NULL ) THEN
      lv_tkn_profile := cv_prf_aff6_company_dummy;
      RAISE profile_expt;
    END IF;
--
    -- 予備１_ダミー値
    gt_aff7_dummy := fnd_profile.value( cv_prf_aff7_preliminary1_dummy );
    IF( gt_aff7_dummy IS NULL ) THEN
      lv_tkn_profile := cv_prf_aff7_preliminary1_dummy;
      RAISE profile_expt;
    END IF;
--
    -- 予備２_ダミー値
    gt_aff8_dummy := fnd_profile.value( cv_prf_aff8_preliminary2_dummy );
    IF( gt_aff8_dummy IS NULL ) THEN
      lv_tkn_profile := cv_prf_aff8_preliminary2_dummy;
      RAISE profile_expt;
    END IF;
--
    -- 仕訳カテゴリ名(在庫原価振替)
    gt_je_category_name_inv_cost := fnd_profile.value( cv_prf_gl_category_inv_cost );
    IF( gt_je_category_name_inv_cost IS NULL ) THEN
      lv_tkn_profile := cv_prf_gl_category_inv_cost;
      RAISE profile_expt;
    END IF;
--
    -- 仕訳ソース名(在庫原価振替)
    gt_je_source_name_inv_cost := fnd_profile.value( cv_prf_gl_source_inv_cost );
    IF( gt_je_source_name_inv_cost IS NULL ) THEN
      lv_tkn_profile := cv_prf_gl_source_inv_cost;
      RAISE profile_expt;
    END IF;
--
    -- 会計カレンダ
    gt_sales_calendar := fnd_profile.value( cv_prf_sales_calendar );
    IF( gt_sales_calendar IS NULL ) THEN
      lv_tkn_profile := cv_prf_sales_calendar;
      RAISE profile_expt;
    END IF;
--
-- == 2009/09/04 V1.7 Added START ===============================================================
    -- 勘定科目_製品
    gt_aff3_seihin := fnd_profile.value( cv_prf_aff3_seihin );
    IF( gt_aff3_seihin IS NULL ) THEN
      lv_tkn_profile := cv_prf_aff3_seihin;
      RAISE profile_expt;
    END IF;
--
    -- 勘定科目_商品
    gt_aff3_shouhin := fnd_profile.value(cv_prf_aff3_shouhin  );
    IF( gt_aff3_shouhin IS NULL ) THEN
      lv_tkn_profile := cv_prf_aff3_shouhin;
      RAISE profile_expt;
    END IF;
-- == 2009/09/04 V1.7 Added END   ===============================================================
    -- ==============================================================
    -- 仕訳バッチ名取得
    -- ==============================================================
    gt_je_batch_name := xxcok_common_pkg.get_batch_name_f( gt_je_category_name_inv_cost );
--
    -- ==============================================================
    -- グループID取得
    -- ==============================================================
    SELECT gjs.attribute1 AS group_id
    INTO   gt_group_id
    FROM   gl_je_sources gjs
    WHERE  gjs.user_je_source_name = gt_je_source_name_inv_cost
    AND    gjs.language            = USERENV( 'LANG' )
    ;
    -- グループID取得エラー(仕訳ソース登録済でグループID未登録の場合)
    IF( gt_group_id IS NULL ) THEN
      RAISE NO_DATA_FOUND;
    END IF;
--
    -- ==============================================================
    -- 原価差額ワークテーブルの前回GLバッチID取得
    -- ==============================================================
    SELECT MAX( xwcv.gl_batch_id ) AS gl_batch_id
    INTO   gt_last_gl_batch_id
    FROM   xxcoi_wk_cost_variance xwcv
    ;
    -- 前回GLバッチID取得エラー
-- == 2009/09/28 V1.8 Modified START ===============================================================
--    IF( gt_last_gl_batch_id IS NULL ) THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_appl_short_name_xxcoi
--                     , iv_name         => cv_msg_gl_batch_id_get_err
--                   );
--      RAISE NO_DATA_FOUND;
--    END IF;
    IF( gt_last_gl_batch_id IS NULL ) THEN
      -- 原価差額ワークテーブルより取得されない場合は、エラーテーブルより取得
      SELECT MAX( xwecv.gl_batch_id ) AS gl_batch_id
      INTO   gt_last_gl_batch_id
      FROM   xxcoi_wk_error_cost_variance xwecv
      ;
      IF( gt_last_gl_batch_id IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name_xxcoi
                       , iv_name         => cv_msg_gl_batch_id_get_err
                     );
-- == 2010/01/29 V1.9 Modified START ===============================================================
--        RAISE NO_DATA_FOUND;
        RAISE global_api_expt;
-- == 2010/01/29 V1.9 Modified END   ===============================================================
      END IF;
    END IF;
-- == 2009/09/28 V1.8 Modified END   ===============================================================
--
    -- ==============================================================
    -- 標準原価更新の取引タイプID取得
    -- ==============================================================
-- == 2009/06/04 V1.3 Added START ===============================================================
    lt_std_cost_upd :=  fnd_profile.value(cv_prf_trans_type_std_cost_upd);
    --
    IF (lt_std_cost_upd IS NULL) THEN
      lv_tkn_profile := cv_prf_trans_type_std_cost_upd;
      RAISE profile_expt;
    END IF;
    --
    SELECT  mtt.transaction_type_id
    INTO    gt_trans_type_std_cost_upd
    FROM    mtl_transaction_types       mtt
    WHERE   mtt.transaction_type_name   =   lt_std_cost_upd
    AND     TRUNC(SYSDATE)             <=   TRUNC(NVL(mtt.disable_date, SYSDATE));
-- == 2009/06/04 V1.3 Added END   ===============================================================
-- == 2009/07/14 V1.4 Added START ===============================================================
    -- ==============================================================
    -- 在庫組織コード取得
    -- ==============================================================
    gt_org_code := fnd_profile.value( cv_prf_org );
    IF( gt_org_code IS NULL ) THEN
      lv_tkn_profile := cv_prf_org;
      RAISE org_code_expt;
    END IF;
--
    -- ==============================================================
    -- 在庫原価振替設定記帳日取得
    -- ==============================================================
    lv_effective_date := SUBSTRB(iv_effective_date,1,10);
    gt_effective_date := NVL ( TO_DATE( lv_effective_date ,'YYYY/MM/DD') , TRUNC(xxccp_common_pkg2.get_process_date) );
--
    -- ==============================================================
    -- 前月会計期間末日取得
    -- ==============================================================
    SELECT gp.end_date
-- == 2009/08/17 V1.5 Added START ===============================================================
          ,gp.period_name       -- 会計期間名(前月)
-- == 2009/08/17 V1.5 Added START ===============================================================
    INTO   gt_last_period_date
-- == 2009/08/17 V1.5 Added START ===============================================================
          ,gt_period_name_lm
-- == 2009/08/17 V1.5 Added START ===============================================================
    FROM   gl_periods gp
    WHERE  gp.period_set_name = gt_sales_calendar
    AND    ADD_MONTHS ( xxccp_common_pkg2.get_process_date , -1 ) BETWEEN gp.start_date AND gp.end_date
    AND    gp.adjustment_period_flag = cv_error_record;
--
    -- ==============================================================
    -- 資材配賦抽出条件用在庫会計期間オープン在庫日付取得
    -- ==============================================================
    SELECT MIN(oap.period_start_date)
    INTO   gt_min_org_acct_date
    FROM   org_acct_periods oap
    WHERE  oap.organization_id = xxcoi_common_pkg.get_organization_id ( gt_org_code )
    AND    oap.open_flag = cv_normal_record;
-- == 2009/07/14 V1.4 Added END   ===============================================================
-- == 2009/08/17 V1.5 Added START ===============================================================
    BEGIN
      --当月の会計期間名
      SELECT gp.period_name
      INTO   gt_period_name_tm
      FROM   gl_periods   gp                                  -- 会計カレンダ
      WHERE  gp.period_set_name         = gt_sales_calendar   -- 会計カレンダ名：SALES_CALENDAR
      AND    gp.adjustment_period_flag  = cv_flag_n           -- 調整期間フラグ：N
      AND    gt_effective_date BETWEEN gp.start_date
                               AND     gp.end_date;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE period_name_expt;
    END;
-- == 2009/08/17 V1.5 Added END   ===============================================================
-- == 2009/09/28 V1.8 Added START ===============================================================
    -- ==================================
    --  在庫会計期間とGL会計期間チェック
    -- ==================================
    lb_acctg_period_chk := xxcok_common_pkg.check_acctg_period_f(
                               gt_gl_set_of_bks_id
                             , gt_min_org_acct_date
                             , cv_appl_short_name_sqlgl
                           );
    -- 在庫会計期間がOPENで、GL会計期間がクローズしている場合エラー
    IF NOT(lb_acctg_period_chk) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_msg_code_xxcoi_10405
                     , iv_token_name1  => cv_tkn_xxcoi_msg_10405
                     , iv_token_value1 => TO_CHAR(gt_min_org_acct_date, 'YYYY/MM/DD')
                   );
      lv_errbuf :=  lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- ==================================
    --  記帳日チェック
    -- ==================================
    lb_acctg_period_chk := xxcok_common_pkg.check_acctg_period_f(
                               gt_gl_set_of_bks_id
                             , gt_effective_date
                             , cv_appl_short_name_sqlgl
                           );
    -- パラメータ記帳日で、GL会計期間がクローズしている場合エラー
    IF NOT(lb_acctg_period_chk) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_msg_code_xxcoi_10406
                     , iv_token_name1  => cv_tkn_xxcoi_msg_10405
                     , iv_token_value1 => TO_CHAR(gt_effective_date, 'YYYY/MM/DD')
                   );
      lv_errbuf :=  lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
-- == 2009/09/28 V1.8 Added END   ===============================================================
  EXCEPTION
-- == 2009/08/17 V1.5 Added START ===============================================================
    -- *** 会計期間名取得例外 ***
    WHEN period_name_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_msg_code_xxcoi_10399
                     , iv_token_name1  => cv_date
                     , iv_token_value1 => TO_CHAR(gt_effective_date, 'YYYY/MM')
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
-- == 2009/08/17 V1.5 Added END   ===============================================================
-- == 2009/07/14 V1.4 Added START ===============================================================
    -- *** プロファイル値取得例外 ***
    WHEN org_code_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_msg_code_xxcoi_00005
                     , iv_token_name1  => cv_tkn_profile
                     , iv_token_value1 => cv_prf_org
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
-- == 2009/07/14 V1.4 Added END   ===============================================================
    -- *** プロファイル値取得例外 ***
    WHEN profile_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_msg_profile_get_err
                     , iv_token_name1  => cv_tkn_profile
                     , iv_token_value1 => lv_tkn_profile
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
    -- *** グループID/前回GLバッチID取得例外 ***
    WHEN NO_DATA_FOUND THEN
      -- グループID取得エラー
      IF( gt_group_id IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name_xxcoi
                       , iv_name         => cv_msg_group_id_get_err
                       , iv_token_name1  => cv_tkn_source
                       , iv_token_value1 => gt_je_source_name_inv_cost
                     );
      END IF;
-- == 2009/06/04 V1.3 Added START ===============================================================
      IF( gt_trans_type_std_cost_upd IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name_xxcoi
                       , iv_name         => cv_msg_code_xxcoi_10256
                       , iv_token_name1  => cv_tkn_transaction_type
                       , iv_token_value1 => lt_std_cost_upd
                     );
      END IF;
-- == 2009/06/04 V1.3 Added END   ===============================================================
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
-- == 2009/09/28 V1.8 Deleted START ===============================================================
--  /**********************************************************************************
--   * Procedure Name   : get_mtl_txn_acct
--   * Description      : 資材配賦情報の抽出 (A-2)
--   ***********************************************************************************/
--  PROCEDURE get_mtl_txn_acct(
--      on_mtl_txn_acct_cnt OUT NUMBER        -- 取得件数
--    , ov_errbuf           OUT VARCHAR2      -- エラー・メッセージ           --# 固定 #
--    , ov_retcode          OUT VARCHAR2      -- リターン・コード             --# 固定 #
--    , ov_errmsg           OUT VARCHAR2 )    -- ユーザー・エラー・メッセージ --# 固定 #
--  IS
--    -- ===============================
--    -- 固定ローカル定数
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_mtl_txn_acct'; -- プログラム名
----
----#####################  固定ローカル変数宣言部 START   ########################
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
--    -- *** ローカル・カーソル ***
--    -- 資材配賦情報取得
--    CURSOR mtl_txn_acct_cur
--    IS
---- == 2009/08/25 V1.6 Modified START ===============================================================
------ == 2009/07/14 V1.4 Added START ===============================================================
------      SELECT mta.transaction_id          AS mta_transaction_id           --  1.在庫取引ID
------ == 2009/08/17 V1.5 Modified START ===============================================================
------      SELECT /*+ index(gcc xxcoi_gl_code_combinations_n34) */
----      SELECT /*+ use_nl(mta,gcc,mmt,msib) index(gcc xxcoi_gl_code_combinations_n34) */
------ == 2009/08/17 V1.5 Modified END   ===============================================================
----             mta.transaction_id          AS mta_transaction_id           --  1.在庫取引ID
------ == 2009/07/14 V1.4 Added End ===============================================================
----           , gcc.segment2                AS gcc_dept_code                --  2.部門コード
----           , CASE WHEN gcc.segment3      = gt_aff3_shizuoka_factory THEN --   5.勘定科目コードが静岡工場勘定の場合
----                    gcc.segment2                                         --     2.部門コード
----                  ELSE                                                   --   それ以外の場合
----                    gt_aff2_adj_dept_code                                --     A-1.で取得した調整部門コード
----             END                         AS xwcv_adj_dept_code           --  3.調整部門コード
----           , mta.reference_account       AS mta_account_id               --  4.勘定科目ID
----           , gcc.segment3                AS gcc_account_code             --  5.勘定科目コード
------ == 2009/03/26 V1.1 Added START ===============================================================
----           , gcc.segment4                AS gcc_subacct_code             --  6.補助科目コード
------ == 2009/03/26 V1.1 Added END   ===============================================================
----           , mta.inventory_item_id       AS mta_inventory_item_id        --  7.品目ID
----           , msib.segment1               AS msib_item_code               --  8.品目コード
----           , mta.transaction_date        AS mta_transaction_date         --  9.取引日
----           , mta.transaction_value       AS mta_transaction_value        -- 10.取引金額
----           , mta.primary_quantity        AS mta_primary_quantity         -- 11.取引数量
----           , mta.base_transaction_value  AS mta_base_transaction_value   -- 12.基準単位金額
----           , mta.organization_id         AS mta_organization_id          -- 13.組織ID
----           , mta.gl_batch_id             AS mta_gl_batch_id              -- 14.GLバッチID
------ == 2009/06/04 V1.3 Added START ===============================================================
----           , mmt.transaction_type_id     AS transaction_type_id          -- 15.取引タイプID
------ == 2009/06/04 V1.3 Added END   ===============================================================
----      FROM   mtl_transaction_accounts    mta                             -- 資材配賦テーブル
----           , gl_code_combinations        gcc                             -- 勘定科目テーブル
----           , mtl_system_items_b          msib                            -- Disc品目マスタ
------ == 2009/06/04 V1.3 Added START ===============================================================
----           ,mtl_material_transactions    mmt                             -- 資材取引
------ == 2009/06/04 V1.3 Added END   ===============================================================
----      WHERE  mta.reference_account       = gcc.code_combination_id       -- CCID
----      AND    mta.gl_batch_id             > gt_last_gl_batch_id           -- GLバッチID > 前回GLバッチID
----      AND    msib.inventory_item_id      = mta.inventory_item_id         -- 品目ID
----      AND    msib.organization_id        = mta.organization_id           -- 組織ID
------ == 2009/06/04 V1.3 Added START ===============================================================
----      AND    mta.transaction_id          = mmt.transaction_id            -- 取引ID
------ == 2009/06/04 V1.3 Added END   ===============================================================
------ == 2009/07/14 V1.4 Added START ===============================================================
----      AND    mta.transaction_date        BETWEEN gt_min_org_acct_date AND TRUNC(SYSDATE)
------ == 2009/07/14 V1.4 Added END   ===============================================================
----      ORDER BY mta.inventory_item_id                                     -- 品目ID
----             , mta.transaction_date;                                     -- 取引日
----
--      SELECT /*+ LEADING(MTA) USE_NL(MTA MMT GCC MSIB) */
--             mta.transaction_id          AS mta_transaction_id           --  1.在庫取引ID
--           , gcc.segment2                AS gcc_dept_code                --  2.部門コード
---- == 2009/09/04 V1.7 Added START ===============================================================
----           , CASE WHEN gcc.segment3      = gt_aff3_shizuoka_factory THEN --   5.勘定科目コードが静岡工場勘定の場合
--           , CASE WHEN gcc.segment3 IN(gt_aff3_shizuoka_factory, gt_aff3_seihin, gt_aff3_shouhin) THEN --   5.勘定科目コードが静岡工場勘定の場合
---- == 2009/09/04 V1.7 Added END   ===============================================================
--                    gcc.segment2                                         --     2.部門コード
--                  ELSE                                                   --   それ以外の場合
--                    gt_aff2_adj_dept_code                                --     A-1.で取得した調整部門コード
--             END                         AS xwcv_adj_dept_code           --  3.調整部門コード
--           , mta.reference_account       AS mta_account_id               --  4.勘定科目ID
--           , gcc.segment3                AS gcc_account_code             --  5.勘定科目コード
--           , gcc.segment4                AS gcc_subacct_code             --  6.補助科目コード
--           , mta.inventory_item_id       AS mta_inventory_item_id        --  7.品目ID
--           , msib.segment1               AS msib_item_code               --  8.品目コード
--           , mta.transaction_date        AS mta_transaction_date         --  9.取引日
--           , mta.transaction_value       AS mta_transaction_value        -- 10.取引金額
--           , mta.primary_quantity        AS mta_primary_quantity         -- 11.取引数量
--           , mta.base_transaction_value  AS mta_base_transaction_value   -- 12.基準単位金額
--           , mta.organization_id         AS mta_organization_id          -- 13.組織ID
--           , mta.gl_batch_id             AS mta_gl_batch_id              -- 14.GLバッチID
--           , mmt.transaction_type_id     AS transaction_type_id          -- 15.取引タイプID
--      FROM   mtl_transaction_accounts    mta                             -- 資材配賦テーブル
--           , gl_code_combinations        gcc                             -- 勘定科目テーブル
--           , mtl_system_items_b          msib                            -- Disc品目マスタ
--           ,mtl_material_transactions    mmt                             -- 資材取引
--      WHERE  mta.reference_account       = gcc.code_combination_id       -- CCID
--      AND    mta.gl_batch_id             > gt_last_gl_batch_id           -- GLバッチID > 前回GLバッチID
--      AND    msib.inventory_item_id      = mta.inventory_item_id         -- 品目ID
--      AND    msib.organization_id        = mta.organization_id           -- 組織ID
--      AND    mta.transaction_id          = mmt.transaction_id            -- 取引ID
--      AND    mta.transaction_date        BETWEEN gt_min_org_acct_date AND TRUNC(SYSDATE)
--      ORDER BY mta.inventory_item_id                                     -- 品目ID
--             , mta.transaction_date;                                     -- 取引日
---- == 2009/08/25 V1.6 Modified END   ===============================================================
----
--  BEGIN
----
----##################  固定ステータス初期化部 START   ###################
----
--    ov_retcode := cv_status_normal;
----
----###########################  固定部 END   ############################
----
--    -- カーソルオープン
--    OPEN mtl_txn_acct_cur;
--    -- フェッチ
--    FETCH mtl_txn_acct_cur BULK COLLECT INTO g_mtl_txn_acct_tab;
--    -- 取得件数セット
--    on_mtl_txn_acct_cnt := g_mtl_txn_acct_tab.COUNT;
--    -- カーソルクローズ
--    CLOSE mtl_txn_acct_cur;
----
--  EXCEPTION
----
----#################################  固定例外処理部 START   ####################################
----
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
--  END get_mtl_txn_acct;
-- == 2009/09/28 V1.8 Deleted END   ===============================================================
--
  /**********************************************************************************
   * Procedure Name   : del_xwcv_last_data
   * Description      : 原価差額ワークテーブルの前回データ削除 (A-3)
   ***********************************************************************************/
  PROCEDURE del_xwcv_last_data(
      ov_errbuf             OUT VARCHAR2      -- エラー・メッセージ           --# 固定 #
    , ov_retcode            OUT VARCHAR2      -- リターン・コード             --# 固定 #
    , ov_errmsg             OUT VARCHAR2 )    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_xwcv_last_data'; -- プログラム名
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
    -- *** ローカル・カーソル ***
    CURSOR del_xwcv_tbl_cur
    IS
      -- 原価差額ワークテーブルのロック取得
      SELECT 'X'
      FROM   xxcoi_wk_cost_variance  xwcv             -- 原価差額ワークテーブル
      FOR UPDATE NOWAIT;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ロック取得
    OPEN  del_xwcv_tbl_cur;
    CLOSE del_xwcv_tbl_cur;
    -- 原価差額ワークテーブル削除 
    DELETE FROM xxcoi_wk_cost_variance  xwcv;
--
  EXCEPTION
    -- *** ロックエラーハンドラ ***
    WHEN lock_expt THEN
      -- カーソルがオープンしていたらクローズ
      IF ( del_xwcv_tbl_cur%ISOPEN ) THEN
        CLOSE del_xwcv_tbl_cur;
      END IF;
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_xxcoi
                      , iv_name         => cv_msg_lock_err
                    );
      lv_errbuf  := lv_errmsg;
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
      -- カーソルがオープンしていたらクローズ
      IF ( del_xwcv_tbl_cur%ISOPEN ) THEN
        CLOSE del_xwcv_tbl_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END del_xwcv_last_data;
--
--
  /**********************************************************************************
   * Procedure Name   : get_cost_info
   * Description      : 原価情報取得処理 (A-4)
   ***********************************************************************************/
  PROCEDURE get_cost_info(
      ion_standard_cost  IN OUT NUMBER     -- 標準原価
    , ion_operation_cost IN OUT NUMBER     -- 営業原価
    , ion_cost_variance  IN OUT NUMBER     -- 原価差額
-- == 2009/09/28 V1.8 Added START ===============================================================
    , ir_txn_acct_rec    IN  mtl_txn_acct_cur%ROWTYPE                      -- 資材配賦情報
-- == 2009/09/28 V1.8 Added END   ===============================================================
    , ov_errbuf          OUT VARCHAR2      -- エラー・メッセージ           --# 固定 #
    , ov_retcode         OUT VARCHAR2      -- リターン・コード             --# 固定 #
    , ov_errmsg          OUT VARCHAR2 )    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cost_info'; -- プログラム名
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
--
    -- *** ローカル変数 ***
    lv_errbuf_cmpnt_cost     VARCHAR2(1); -- 標準原価取得エラー・メッセージ
    lv_retcode_cmpnt_cost    VARCHAR2(1); -- 標準原価取得リターン・コード
    lv_errbuf_discrete_cost  VARCHAR2(1); -- 営業原価取得エラー・メッセージ
    lv_retcode_discrete_cost VARCHAR2(1); -- 営業原価取得リターン・コード
    ln_standard_cost         NUMBER;      -- 標準原価
    ln_operation_cost        NUMBER;      -- 営業原価
    ln_cost_variance         NUMBER;      -- 原価差額
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ローカルステータス初期化
    lv_retcode := cv_status_normal;
--
    -- 前回情報と品目/取引日が違う場合は、原価情報取得
-- == 2009/09/28 V1.8 Modified START ===============================================================
--    IF       (( gt_pre_inventory_item_id IS NULL )  
--         AND  ( gt_pre_transaction_date  IS NULL ))
--      OR NOT (( gt_pre_inventory_item_id = g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_inventory_item_id )
--         AND  ( gt_pre_transaction_date  = g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_transaction_date ))
--    THEN
    IF       (( gt_pre_inventory_item_id IS NULL )  
         AND  ( gt_pre_transaction_date  IS NULL ))
      OR NOT (( gt_pre_inventory_item_id = ir_txn_acct_rec.mta_inventory_item_id )
         AND  ( gt_pre_transaction_date  = ir_txn_acct_rec.mta_transaction_date ))
    THEN
-- == 2009/09/28 V1.8 Modified END   ===============================================================
      -- ===============================
      -- 標準原価取得
      -- ===============================
-- == 2009/09/28 V1.8 Modified START ===============================================================
--      xxcoi_common_pkg.get_cmpnt_cost(
--          in_item_id      => g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_inventory_item_id  -- 品目ID
--        , in_org_id       => g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_organization_id    -- 組織ID
--        , id_period_date  => g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_transaction_date   -- 対象日
--        , ov_cmpnt_cost   => ln_standard_cost                                                 -- 標準原価
--        , ov_errbuf       => lv_errbuf_cmpnt_cost                                             -- エラー・メッセージ
--        , ov_retcode      => lv_retcode_cmpnt_cost                                            -- リターンコード
--        , ov_errmsg       => lv_errmsg                                                        -- ユーザー・エラー・メッセージ
--      );
      xxcoi_common_pkg.get_cmpnt_cost(
          in_item_id      => ir_txn_acct_rec.mta_inventory_item_id  -- 品目ID
        , in_org_id       => ir_txn_acct_rec.mta_organization_id    -- 組織ID
        , id_period_date  => ir_txn_acct_rec.mta_transaction_date   -- 対象日
        , ov_cmpnt_cost   => ln_standard_cost                                                 -- 標準原価
        , ov_errbuf       => lv_errbuf_cmpnt_cost                                             -- エラー・メッセージ
        , ov_retcode      => lv_retcode_cmpnt_cost                                            -- リターンコード
        , ov_errmsg       => lv_errmsg                                                        -- ユーザー・エラー・メッセージ
      );
-- == 2009/09/28 V1.8 Modified END   ===============================================================
      IF ( lv_retcode_cmpnt_cost <> cv_status_normal ) THEN
        ln_standard_cost  := 0;
      END IF;
--
      -- ===============================
      -- 営業原価取得
      -- ===============================
-- == 2009/09/28 V1.8 Modified START ===============================================================
--      xxcoi_common_pkg.get_discrete_cost(
--          in_item_id       => g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_inventory_item_id  -- 品目ID
--        , in_org_id        => g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_organization_id    -- 組織ID
--        , id_target_date   => g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_transaction_date   -- 対象日
--        , ov_discrete_cost => ln_operation_cost                                                -- 営業原価
--        , ov_errbuf        => lv_errbuf_discrete_cost                                          -- エラー・メッセージ
--        , ov_retcode       => lv_retcode_discrete_cost                                         -- リターンコード
--        , ov_errmsg        => lv_errmsg                                                        -- ユーザー・エラー・メッセージ
--      );
      xxcoi_common_pkg.get_discrete_cost(
          in_item_id       => ir_txn_acct_rec.mta_inventory_item_id  -- 品目ID
        , in_org_id        => ir_txn_acct_rec.mta_organization_id    -- 組織ID
        , id_target_date   => ir_txn_acct_rec.mta_transaction_date   -- 対象日
        , ov_discrete_cost => ln_operation_cost                                                -- 営業原価
        , ov_errbuf        => lv_errbuf_discrete_cost                                          -- エラー・メッセージ
        , ov_retcode       => lv_retcode_discrete_cost                                         -- リターンコード
        , ov_errmsg        => lv_errmsg                                                        -- ユーザー・エラー・メッセージ
      );
-- == 2009/09/28 V1.8 Modified END   ===============================================================
      IF   ( lv_retcode_discrete_cost <> cv_status_normal ) 
        OR ( ln_operation_cost IS NULL )
      THEN
        lv_retcode_discrete_cost := cv_status_error;
        ln_operation_cost        := 0;
      END IF;
--
      -- 前回情報に現レコード情報セット
-- == 2009/09/28 V1.8 Modified START ===============================================================
--      gt_pre_inventory_item_id     := g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_inventory_item_id;
--      gt_pre_transaction_date      := g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_transaction_date;
      gt_pre_inventory_item_id     := ir_txn_acct_rec.mta_inventory_item_id;
      gt_pre_transaction_date      := ir_txn_acct_rec.mta_transaction_date;
-- == 2009/09/28 V1.8 Modified END   ===============================================================
      gt_pre_errbuf_cmpnt_cost     := lv_errbuf_cmpnt_cost;
      gt_pre_retcode_cmpnt_cost    := lv_retcode_cmpnt_cost;
      gt_pre_errbuf_discrete_cost  := lv_errbuf_discrete_cost;
      gt_pre_retcode_discrete_cost := lv_retcode_discrete_cost;
--
    -- 前回情報と品目/取引日が同じ場合は、前回情報を使用
    ELSE
      -- 前回情報をセット
      lv_errbuf_cmpnt_cost     := gt_pre_errbuf_cmpnt_cost;
      lv_retcode_cmpnt_cost    := gt_pre_retcode_cmpnt_cost;
      lv_errbuf_discrete_cost  := gt_pre_errbuf_discrete_cost;
      lv_retcode_discrete_cost := gt_pre_retcode_discrete_cost;
      ln_standard_cost         := ion_standard_cost ;
      ln_operation_cost        := ion_operation_cost;
    END IF;
--
    -- 原価取得エラーメッセージ出力
    -- 標準原価取得エラーの場合
    IF ( lv_retcode_cmpnt_cost = cv_status_error ) THEN
-- == 2009/09/28 V1.8 Modified START ===============================================================
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_appl_short_name_xxcoi
--                     , iv_name         => cv_msg_std_cost_get_err
--                     , iv_token_name1  => cv_tkn_item_code
--                     , iv_token_value1 => g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).msib_item_code
--                     , iv_token_name2  => cv_tkn_period
--                     , iv_token_value2 => TO_CHAR( g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_transaction_date, 'YYYY-MM' )
--                     , iv_token_name3  => cv_tkn_dept
--                     , iv_token_value3 => g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).xwcv_adj_dept_code
--                     , iv_token_name4  => cv_tkn_account
--                     , iv_token_value4 => g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).gcc_account_code
---- == 2009/03/26 V1.1 Added START ===============================================================
--                     , iv_token_name5  => cv_tkn_subacct
--                     , iv_token_value5 => g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).gcc_subacct_code
---- == 2009/03/26 V1.1 Added END   ===============================================================
--                   );
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_msg_std_cost_get_err
                     , iv_token_name1  => cv_tkn_item_code
                     , iv_token_value1 => ir_txn_acct_rec.msib_item_code
                     , iv_token_name2  => cv_tkn_period
                     , iv_token_value2 => TO_CHAR( ir_txn_acct_rec.mta_transaction_date, 'YYYY-MM' )
                     , iv_token_name3  => cv_tkn_dept
                     , iv_token_value3 => ir_txn_acct_rec.xwcv_adj_dept_code
                     , iv_token_name4  => cv_tkn_account
                     , iv_token_value4 => ir_txn_acct_rec.gcc_account_code
                     , iv_token_name5  => cv_tkn_subacct
                     , iv_token_value5 => ir_txn_acct_rec.gcc_subacct_code
                   );
-- == 2009/09/28 V1.8 Modified END   ===============================================================
      lv_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf_cmpnt_cost, 1, 5000 );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_errbuf
      );
      lv_retcode := cv_status_warn;
    END IF;
    -- 営業原価取得エラーの場合
    IF ( lv_retcode_discrete_cost = cv_status_error ) THEN
-- == 2009/09/28 V1.8 Modified START ===============================================================
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_appl_short_name_xxcoi
--                     , iv_name         => cv_msg_oprtn_cost_get_err
--                     , iv_token_name1  => cv_tkn_item_code
--                     , iv_token_value1 => g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).msib_item_code
--                     , iv_token_name2  => cv_tkn_period
--                     , iv_token_value2 => TO_CHAR( g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_transaction_date, 'YYYY-MM' )
--                     , iv_token_name3  => cv_tkn_dept
--                     , iv_token_value3 => g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).xwcv_adj_dept_code
--                     , iv_token_name4  => cv_tkn_account
--                     , iv_token_value4 => g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).gcc_account_code
---- == 2009/03/26 V1.1 Added START ===============================================================
--                     , iv_token_name5  => cv_tkn_subacct
--                     , iv_token_value5 => g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).gcc_subacct_code
---- == 2009/03/26 V1.1 Added END   ===============================================================
--                   );
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_msg_oprtn_cost_get_err
                     , iv_token_name1  => cv_tkn_item_code
                     , iv_token_value1 => ir_txn_acct_rec.msib_item_code
                     , iv_token_name2  => cv_tkn_period
                     , iv_token_value2 => TO_CHAR( ir_txn_acct_rec.mta_transaction_date, 'YYYY-MM' )
                     , iv_token_name3  => cv_tkn_dept
                     , iv_token_value3 => ir_txn_acct_rec.xwcv_adj_dept_code
                     , iv_token_name4  => cv_tkn_account
                     , iv_token_value4 => ir_txn_acct_rec.gcc_account_code
                     , iv_token_name5  => cv_tkn_subacct
                     , iv_token_value5 => ir_txn_acct_rec.gcc_subacct_code
                   );
-- == 2009/09/28 V1.8 Modified END   ===============================================================
      lv_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf_discrete_cost, 1, 5000 );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_errbuf
      );
      lv_retcode := cv_status_warn;
    END IF;
--
    -- 標準/営業原価取得成功時
    IF    ( lv_retcode_cmpnt_cost    = cv_status_normal )
      AND ( lv_retcode_discrete_cost = cv_status_normal ) THEN
      -- ===============================
      -- 原価差額算出
      -- ===============================
-- == 2009/09/28 V1.8 Modified START ===============================================================
---- == 2009/06/04 V1.3 Modified START ===============================================================
----      ln_cost_variance := g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_primary_quantity 
----                            * ( ln_standard_cost - ln_operation_cost );
----
--      IF (g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).transaction_type_id = gt_trans_type_std_cost_upd) THEN
--        -- 原価差額 = 基準単位金額 * (-1)
--        ln_cost_variance  :=  ROUND(g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_base_transaction_value * (-1));
--      ELSE
--        -- 原価差額 = 取引数量 * ( 標準原価 － 営業原価 ) （小数点以下四捨五入）
--        ln_cost_variance := ROUND(g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_primary_quantity 
--                                    * ( ln_standard_cost - ln_operation_cost ), 0);
--      END IF;
---- == 2009/06/04 V1.3 Modified END   ===============================================================
--    ELSE
--      ln_cost_variance := 0;
--    END IF;
      IF (ir_txn_acct_rec.transaction_type_id = gt_trans_type_std_cost_upd) THEN
        -- 原価差額 = 基準単位金額 * (-1)
        ln_cost_variance  :=  ROUND(ir_txn_acct_rec.mta_base_transaction_value * (-1));
      ELSE
        -- 原価差額 = 取引数量 * ( 標準原価 － 営業原価 ) （小数点以下四捨五入）
        ln_cost_variance := ROUND(ir_txn_acct_rec.mta_primary_quantity 
                                    * ( ln_standard_cost - ln_operation_cost ), 0);
      END IF;
    ELSE
      ln_cost_variance := 0;
    END IF;
-- == 2009/09/28 V1.8 Modified END   ===============================================================
    -- 戻り値セット
    ion_standard_cost  := ln_standard_cost;
    ion_operation_cost := ln_operation_cost;
    ion_cost_variance  := ln_cost_variance;
-- == 2009/03/26 V1.1 Deleted START ===============================================================
    -- ===============================
    -- 必須項目チェック処理
    -- ===============================
    -- 部門コードと勘定科目コードのNULLチェック
--    IF   g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).gcc_dept_code    IS NULL
--      OR g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).gcc_account_code IS NULL 
--    THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_appl_short_name_xxcoi
--                     , iv_name         => cv_msg_acct_tbl_chk_err
--                     , iv_token_name1  => cv_tkn_account_id
--                     , iv_token_value1 => TO_CHAR( g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_account_id )
--                     , iv_token_name2  => cv_tkn_period
--                     , iv_token_value2 => TO_CHAR( g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_transaction_date, 'YYYY-MM' )
--                     , iv_token_name3  => cv_tkn_dept
--                     , iv_token_value3 => g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).xwcv_adj_dept_code
--                     , iv_token_name4  => cv_tkn_account
--                     , iv_token_value4 => g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).gcc_account_code
--                   );
--      lv_errbuf := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
--      FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT
--        , buff   => lv_errmsg
--      );
--      FND_FILE.PUT_LINE(
--          which  => FND_FILE.LOG
--        , buff   => lv_errbuf
--      );
--      lv_retcode := cv_status_warn;
--    END IF;
-- == 2009/03/26 V1.1 Deleted END   ===============================================================
--
    -- リターン・コードセット
    ov_retcode := lv_retcode;
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
  END get_cost_info;
--
  /**********************************************************************************
   * Procedure Name   : ins_xwcv
   * Description      : 原価差額ワークテーブルの作成 (A-5)
   ***********************************************************************************/
  PROCEDURE ins_xwcv(
      in_standard_cost  IN  NUMBER        -- 標準原価
    , in_operation_cost IN  NUMBER        -- 営業原価
    , in_cost_variance  IN  NUMBER        -- 原価差額
    , iv_status         IN  VARCHAR2      -- ステータス
-- == 2009/09/28 V1.8 Added START ===============================================================
    , ir_txn_acct_rec   IN  mtl_txn_acct_cur%ROWTYPE                      -- 資材配賦情報
-- == 2009/09/28 V1.8 Added END   ===============================================================
    , ov_errbuf         OUT VARCHAR2      -- エラー・メッセージ           --# 固定 #
    , ov_retcode        OUT VARCHAR2      -- リターン・コード             --# 固定 #
    , ov_errmsg         OUT VARCHAR2 )    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_xwcv'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
-- Ver1.10 ADD START
    lv_group_company_flg         xxcoi_wk_cost_variance.group_company_flg%TYPE;       -- グループ会社フラグ
-- Ver1.10 ADD END
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
-- == 2009/09/28 V1.8 Modified START ===============================================================
--    -- 原価差額ワークテーブル挿入処理
--    INSERT INTO xxcoi_wk_cost_variance(
--        transaction_id                                                       --  1.在庫取引ID
--      , dept_code                                                            --  2.部門コード
--      , adj_dept_code                                                        --  3.調整部門コード
--      , account_code                                                         --  4.勘定科目コード
---- == 2009/03/26 V1.1 Added Start ===============================================================
--      , subacct_code                                                         --  5.補助科目コード
---- == 2009/03/26 V1.1 Added END   ===============================================================
--      , inventory_item_id                                                    --  6.品目ID
--      , transaction_date                                                     --  7.取引日
--      , transaction_value                                                    --  8.取引金額
--      , primary_quantity                                                     --  9.取引数量
--      , base_transaction_value                                               -- 10.基準単位金額
--      , organization_id                                                      -- 11.組織ID
--      , gl_batch_id                                                          -- 12.GLバッチID
--      , standard_cost                                                        -- 13.標準原価
--      , operation_cost                                                       -- 14.営業原価
--      , cost_variance                                                        -- 15.原価差額
--      , status                                                               -- 16.ステータス
--      , created_by                                                           -- 17.作成者
--      , creation_date                                                        -- 18.作成日
--      , last_updated_by                                                      -- 19.最終更新者
--      , last_update_date                                                     -- 20.最終更新日
--      , last_update_login                                                    -- 21.最終更新ログイン
--      , request_id                                                           -- 22.要求ID
--      , program_application_id                                               -- 23.コンカレント・プログラム・アプリケーションID
--      , program_id                                                           -- 24.コンカレント・プログラムID
--      , program_update_date                                                  -- 25.プログラム更新日
--    ) VALUES (
--        g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_transaction_id         --  1.在庫取引ID
--      , g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).gcc_dept_code              --  2.部門コード
--      , g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).xwcv_adj_dept_code         --  3.調整部門コード
--      , g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).gcc_account_code           --  4.勘定科目コード
---- == 2009/03/26 V1.1 Added Start ===============================================================
--      , g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).gcc_subacct_code           --  5.補助科目コード
---- == 2009/03/26 V1.1 Added END   ===============================================================
--      , g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_inventory_item_id      --  6.品目ID
---- == 2009/07/14 V1.4 Mod Start ===============================================================
----      , g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_transaction_date       --  7.取引日
--      , CASE WHEN g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_transaction_date > gt_last_period_date
--        THEN gt_effective_date
--        ELSE gt_last_period_date END                                         --  7.取引日
---- == 2009/07/14 V1.4 Mod END   ===============================================================
--      , g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_transaction_value      --  8.取引金額
--      , g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_primary_quantity       --  9.取引数量
--      , g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_base_transaction_value -- 10.基準単位金額
--      , g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_organization_id        -- 11.組織ID
--      , g_mtl_txn_acct_tab( gn_mtl_txn_acct_cnt ).mta_gl_batch_id            -- 12.GLバッチID
--      , in_standard_cost                                                     -- 13.標準原価
--      , in_operation_cost                                                    -- 14.営業原価
--      , in_cost_variance                                                     -- 15.原価差額
--      , iv_status                                                            -- 16.ステータス
--      , cn_created_by                                                        -- 17.作成者
--      , SYSDATE                                                              -- 18.作成日
--      , cn_last_updated_by                                                   -- 19.最終更新者
--      , SYSDATE                                                              -- 20.最終更新日
--      , cn_last_update_login                                                 -- 21.最終更新ログイン
--      , cn_request_id                                                        -- 22.要求ID
--      , cn_program_application_id                                            -- 23.コンカレント・プログラム・アプリケーションID
--      , cn_program_id                                                        -- 24.コンカレント・プログラムID
--      , SYSDATE                                                              -- 25.プログラム更新日
--    );
--
-- Ver1.10 ADD START
    -- グループ会社判定
    IF ( ir_txn_acct_rec.company_code = gt_aff1_company_code ) THEN
      lv_group_company_flg := cv_0;
    ELSE
      lv_group_company_flg := cv_1;
    END IF;
-- Ver1.10 ADD END
    IF (iv_status = cv_error_record AND ir_txn_acct_rec.data_type = 1)  THEN
      -- エラーデータで、資材配賦情報の場合
      INSERT INTO xxcoi_wk_error_cost_variance(
        transaction_id                                    -- 01.在庫取引ID
       ,dept_code                                         -- 02.部門コード
       ,adj_dept_code                                     -- 03.調整部門コード
       ,account_id                                        -- 04.勘定科目ID
       ,account_code                                      -- 05.勘定科目コード
       ,subacct_code                                      -- 06.補助科目コード
       ,inventory_item_id                                 -- 07.品目ID
       ,item_code                                         -- 08.品目コード
       ,transaction_date                                  -- 09.取引日
       ,transaction_value                                 -- 10.取引金額
       ,primary_quantity                                  -- 11.取引数量
       ,base_transaction_value                            -- 12.基準単位金額
       ,organization_id                                   -- 13.組織ID
       ,gl_batch_id                                       -- 14.GLバッチID
       ,transaction_type_id                               -- 15.取引タイプID
       ,standard_cost                                     -- 16.標準原価
       ,operation_cost                                    -- 17.営業原価
       ,cost_variance                                     -- 18.原価差額
       ,status                                            -- 19.ステータス
       ,created_by                                        -- 20.作成者
       ,creation_date                                     -- 21.作成日
       ,last_updated_by                                   -- 22.最終更新者
       ,last_update_date                                  -- 23.最終更新日
       ,last_update_login                                 -- 24.最終更新ログイン
       ,request_id                                        -- 25.要求ID
       ,program_application_id                            -- 26.コンカレント・プログラム・アプリケーションID
       ,program_id                                        -- 27.コンカレント・プログラムID
       ,program_update_date                               -- 28.プログラム更新日
-- Ver1.10 ADD START
       ,company_code                                      -- 29.会社コード
       ,group_company_flg                                 -- 30.グループ会社フラグ
       ,transfer_ownership_flg                            -- 31.所有権移転取引フラグ
-- Ver1.10 ADD END
      )VALUES(
        ir_txn_acct_rec.mta_transaction_id                -- 01
       ,ir_txn_acct_rec.gcc_dept_code                     -- 02
       ,ir_txn_acct_rec.xwcv_adj_dept_code                -- 03
       ,ir_txn_acct_rec.mta_account_id                    -- 04
       ,ir_txn_acct_rec.gcc_account_code                  -- 05
       ,ir_txn_acct_rec.gcc_subacct_code                  -- 06
       ,ir_txn_acct_rec.mta_inventory_item_id             -- 07
       ,ir_txn_acct_rec.msib_item_code                    -- 08
       ,CASE WHEN ir_txn_acct_rec.mta_transaction_date > gt_last_period_date
          THEN gt_effective_date
          ELSE gt_last_period_date
        END                                               -- 09
       ,ir_txn_acct_rec.mta_transaction_value             -- 10
       ,ir_txn_acct_rec.mta_primary_quantity              -- 11
       ,ir_txn_acct_rec.mta_base_transaction_value        -- 12
       ,ir_txn_acct_rec.mta_organization_id               -- 13
       ,ir_txn_acct_rec.mta_gl_batch_id                   -- 14
       ,ir_txn_acct_rec.transaction_type_id               -- 15
       ,in_standard_cost                                  -- 16
       ,in_operation_cost                                 -- 17
       ,in_cost_variance                                  -- 18
       ,iv_status                                         -- 19
       ,cn_created_by                                     -- 20
       ,SYSDATE                                           -- 21
       ,cn_last_updated_by                                -- 22
       ,SYSDATE                                           -- 23
       ,cn_last_update_login                              -- 24
       ,cn_request_id                                     -- 25
       ,cn_program_application_id                         -- 26
       ,cn_program_id                                     -- 27
       ,SYSDATE                                           -- 28
-- Ver1.10 ADD START
       ,ir_txn_acct_rec.company_code                      -- 29
       ,lv_group_company_flg                              -- 30
       ,ir_txn_acct_rec.transfer_ownership_flg            -- 31
-- Ver1.10 ADD END
      );
      --
    ELSIF (iv_status <> cv_error_record)  THEN
      -- 正常データの場合
      -- 原価差額ワークテーブル挿入処理
      INSERT INTO xxcoi_wk_cost_variance(
          transaction_id                                  --  1.在庫取引ID
        , dept_code                                       --  2.部門コード
        , adj_dept_code                                   --  3.調整部門コード
        , account_code                                    --  4.勘定科目コード
        , subacct_code                                    --  5.補助科目コード
        , inventory_item_id                               --  6.品目ID
        , transaction_date                                --  7.取引日
        , transaction_value                               --  8.取引金額
        , primary_quantity                                --  9.取引数量
        , base_transaction_value                          -- 10.基準単位金額
        , organization_id                                 -- 11.組織ID
        , gl_batch_id                                     -- 12.GLバッチID
        , standard_cost                                   -- 13.標準原価
        , operation_cost                                  -- 14.営業原価
        , cost_variance                                   -- 15.原価差額
        , status                                          -- 16.ステータス
        , created_by                                      -- 17.作成者
        , creation_date                                   -- 18.作成日
        , last_updated_by                                 -- 19.最終更新者
        , last_update_date                                -- 20.最終更新日
        , last_update_login                               -- 21.最終更新ログイン
        , request_id                                      -- 22.要求ID
        , program_application_id                          -- 23.コンカレント・プログラム・アプリケーションID
        , program_id                                      -- 24.コンカレント・プログラムID
        , program_update_date                             -- 25.プログラム更新日
-- Ver1.10 ADD START
        , company_code                                    -- 26.会社コード
        , transaction_type_id                             -- 27.取引タイプID
        , group_company_flg                               -- 28.グループ会社フラグ
        , transfer_ownership_flg                          -- 29.所有権移転取引フラグ
        , reverse_flg                                     -- 30.反転フラグ
-- Ver1.10 ADD END
      ) VALUES (
          ir_txn_acct_rec.mta_transaction_id              --  1.在庫取引ID
        , ir_txn_acct_rec.gcc_dept_code                   --  2.部門コード
        , ir_txn_acct_rec.xwcv_adj_dept_code              --  3.調整部門コード
        , ir_txn_acct_rec.gcc_account_code                --  4.勘定科目コード
        , ir_txn_acct_rec.gcc_subacct_code                --  5.補助科目コード
        , ir_txn_acct_rec.mta_inventory_item_id           --  6.品目ID
        , CASE WHEN ir_txn_acct_rec.mta_transaction_date > gt_last_period_date
            THEN gt_effective_date
            ELSE gt_last_period_date
          END                                             --  7.取引日
        , ir_txn_acct_rec.mta_transaction_value           --  8.取引金額
        , ir_txn_acct_rec.mta_primary_quantity            --  9.取引数量
        , ir_txn_acct_rec.mta_base_transaction_value      -- 10.基準単位金額
        , ir_txn_acct_rec.mta_organization_id             -- 11.組織ID
        , ir_txn_acct_rec.mta_gl_batch_id                 -- 12.GLバッチID
        , in_standard_cost                                -- 13.標準原価
        , in_operation_cost                               -- 14.営業原価
        , in_cost_variance                                -- 15.原価差額
        , iv_status                                       -- 16.ステータス
        , cn_created_by                                   -- 17.作成者
        , SYSDATE                                         -- 18.作成日
        , cn_last_updated_by                              -- 19.最終更新者
        , SYSDATE                                         -- 20.最終更新日
        , cn_last_update_login                            -- 21.最終更新ログイン
        , cn_request_id                                   -- 22.要求ID
        , cn_program_application_id                       -- 23.コンカレント・プログラム・アプリケーションID
        , cn_program_id                                   -- 24.コンカレント・プログラムID
        , SYSDATE                                         -- 25.プログラム更新日
-- Ver1.10 ADD START
        , ir_txn_acct_rec.company_code                    -- 26.会社コード
        , ir_txn_acct_rec.transaction_type_id             -- 27.取引タイプID
        , lv_group_company_flg                            -- 28.グループ会社フラグ
        , ir_txn_acct_rec.transfer_ownership_flg          -- 29.所有権移転取引フラグ
        , cv_0                                            -- 30.反転フラグ
-- Ver1.10 ADD END
      );
      --
-- Ver1.10 ADD START
      -- 伊藤園以外は赤データ作成
      IF ( ir_txn_acct_rec.company_code <> gt_aff1_company_code ) THEN
        INSERT INTO xxcoi_wk_cost_variance(
            transaction_id                                  --  1.在庫取引ID
          , dept_code                                       --  2.部門コード
          , adj_dept_code                                   --  3.調整部門コード
          , account_code                                    --  4.勘定科目コード
          , subacct_code                                    --  5.補助科目コード
          , inventory_item_id                               --  6.品目ID
          , transaction_date                                --  7.取引日
          , transaction_value                               --  8.取引金額
          , primary_quantity                                --  9.取引数量
          , base_transaction_value                          -- 10.基準単位金額
          , organization_id                                 -- 11.組織ID
          , gl_batch_id                                     -- 12.GLバッチID
          , standard_cost                                   -- 13.標準原価
          , operation_cost                                  -- 14.営業原価
          , cost_variance                                   -- 15.原価差額
          , status                                          -- 16.ステータス
          , created_by                                      -- 17.作成者
          , creation_date                                   -- 18.作成日
          , last_updated_by                                 -- 19.最終更新者
          , last_update_date                                -- 20.最終更新日
          , last_update_login                               -- 21.最終更新ログイン
          , request_id                                      -- 22.要求ID
          , program_application_id                          -- 23.コンカレント・プログラム・アプリケーションID
          , program_id                                      -- 24.コンカレント・プログラムID
          , program_update_date                             -- 25.プログラム更新日
          , company_code                                    -- 26.会社コード
          , transaction_type_id                             -- 27.取引タイプID
          , group_company_flg                               -- 28.グループ会社フラグ
          , transfer_ownership_flg                          -- 29.所有権移転取引フラグ
          , reverse_flg                                     -- 30.反転フラグ
        ) VALUES (
            ir_txn_acct_rec.mta_transaction_id              --  1.在庫取引ID
          , ir_txn_acct_rec.gcc_dept_code                   --  2.部門コード
          , ir_txn_acct_rec.xwcv_adj_dept_code              --  3.調整部門コード
          , ir_txn_acct_rec.gcc_account_code                --  4.勘定科目コード
          , ir_txn_acct_rec.gcc_subacct_code                --  5.補助科目コード
          , ir_txn_acct_rec.mta_inventory_item_id           --  6.品目ID
          , CASE WHEN ir_txn_acct_rec.mta_transaction_date > gt_last_period_date
              THEN gt_effective_date
              ELSE gt_last_period_date
            END                                               --  7.取引日
          , ir_txn_acct_rec.mta_transaction_value             --  8.取引金額
          , (ir_txn_acct_rec.mta_primary_quantity * -1)       --  9.取引数量
          , (ir_txn_acct_rec.mta_base_transaction_value * -1) -- 10.基準単位金額
          , ir_txn_acct_rec.mta_organization_id               -- 11.組織ID
          , ir_txn_acct_rec.mta_gl_batch_id                   -- 12.GLバッチID
          , in_standard_cost                                  -- 13.標準原価
          , in_operation_cost                                 -- 14.営業原価
          , (in_cost_variance * -1)                           -- 15.原価差額
          , iv_status                                         -- 16.ステータス
          , cn_created_by                                     -- 17.作成者
          , SYSDATE                                           -- 18.作成日
          , cn_last_updated_by                                -- 19.最終更新者
          , SYSDATE                                           -- 20.最終更新日
          , cn_last_update_login                              -- 21.最終更新ログイン
          , cn_request_id                                     -- 22.要求ID
          , cn_program_application_id                         -- 23.コンカレント・プログラム・アプリケーションID
          , cn_program_id                                     -- 24.コンカレント・プログラムID
          , SYSDATE                                           -- 25.プログラム更新日
          , ir_txn_acct_rec.company_code                      -- 26.会社コード
          , ir_txn_acct_rec.transaction_type_id               -- 27.取引タイプID
          , lv_group_company_flg                              -- 28.グループ会社フラグ
          , ir_txn_acct_rec.transfer_ownership_flg            -- 29.所有権移転取引フラグ
          , cv_1                                              -- 30.反転フラグ
        );
      END IF;
-- Ver1.10 ADD END
      IF (ir_txn_acct_rec.data_type = 2) THEN
        -- リカバリ用データの場合
        DELETE  xxcoi_wk_error_cost_variance
        WHERE   transaction_id  =   ir_txn_acct_rec.mta_transaction_id;
      END IF;
    END IF;
-- == 2009/09/28 V1.8 Modified END   ===============================================================
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
  END ins_xwcv;
--
  /**********************************************************************************
   * Procedure Name   : ins_gl_if
   * Description      : 原価差額情報GL-IF登録 (A-6、A-7、A-8)
   ***********************************************************************************/
  PROCEDURE ins_gl_if(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_gl_if'; -- プログラム名
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
    cv_flag_n            CONSTANT VARCHAR2(1) := 'N';     -- フラグ値：N
    cv_status_new        CONSTANT VARCHAR2(3) := 'NEW';   -- 固定値：NEW
    cv_code_jpy          CONSTANT VARCHAR2(3) := 'JPY';   -- 固定値：JPY
    cv_flag_a            CONSTANT VARCHAR2(1) := 'A';     -- 固定値：A
--
    -- *** ローカル変数 ***
-- == 2009/09/28 V1.8 Deleted START ===============================================================
--    lb_acctg_period_chk  BOOLEAN;                         -- 会計期間チェック用 TRUE：オープン/FALSE：クローズ
-- == 2009/09/28 V1.8 Deleted END   ===============================================================
    lt_entered_dr        gl_interface.entered_dr%TYPE;    -- 借方金額
    lt_entered_cr        gl_interface.entered_cr%TYPE;    -- 貸方金額
--
    -- ===============================
    -- 原価差額情報の抽出 (A-6)
    -- ===============================
    -- 原価差額情報カーソル
    CURSOR xwcv_sum_cur
    IS
-- == 2009/08/17 V1.5 Modified START ===============================================================
--      SELECT   xwcv.adj_dept_code           AS xwcv_adj_dept_code          -- 調整部門コード
--             , xwcv.account_code            AS xwcv_account_code           -- 勘定科目コード
---- == 2009/03/26 V1.1 Added START ===============================================================
--             , xwcv.subacct_code            AS xwcv_subacct_code           -- 補助科目コード
---- == 2009/03/26 V1.1 Added END   ===============================================================
--             , xwcv.transaction_date        AS xwcv_transaction_date       -- 取引日
--             , xwcv.gl_batch_id             AS xwcv_gl_batch_id            -- GLバッチID
--             , SUM( xwcv.cost_variance )    AS xwcv_cost_variance_sum      -- 原価差額(集約値)
--             , gp.period_name               AS gp_period_name              -- 会計期間名
--      FROM     xxcoi_wk_cost_variance       xwcv                           -- 原価差額ワークテーブル
--             , gl_periods                   gp                             -- 会計カレンダテーブル
--      WHERE    xwcv.transaction_date BETWEEN gp.start_date AND gp.end_date -- 取引日が開始日と終了日の間
--      AND      gp.period_set_name          = gt_sales_calendar             -- 会計カレンダ名：SALES_CALENDAR
--      AND      gp.adjustment_period_flag   = cv_flag_n                     -- 調整期間フラグ：N
--      AND      xwcv.status                <> cv_error_record               -- エラーレコードでない
--      GROUP BY xwcv.adj_dept_code
--             , xwcv.account_code
---- == 2009/03/26 V1.1 Added START ===============================================================
--             , xwcv.subacct_code
---- == 2009/03/26 V1.1 Added END   ===============================================================
--             , xwcv.transaction_date
--             , xwcv.gl_batch_id
--             , gp.period_name
--      HAVING   SUM( xwcv.cost_variance )  <> 0                             -- 原価差額(集約値)が0でない
--      ;
      SELECT   xwcv.adj_dept_code           AS xwcv_adj_dept_code          -- 調整部門コード
             , xwcv.account_code            AS xwcv_account_code           -- 勘定科目コード
             , xwcv.subacct_code            AS xwcv_subacct_code           -- 補助科目コード
             , xwcv.transaction_date        AS xwcv_transaction_date       -- 取引日
             , xwcv.gl_batch_id             AS xwcv_gl_batch_id            -- GLバッチID
             , SUM( xwcv.cost_variance )    AS xwcv_cost_variance_sum      -- 原価差額(集約値)
             , NULL                         AS gp_period_name              -- 会計期間名
      FROM     xxcoi_wk_cost_variance       xwcv                           -- 原価差額ワークテーブル
-- == 2009/09/28 V1.8 Deleted START ===============================================================
--      WHERE    xwcv.status                <> cv_error_record               -- エラーレコードでない
-- == 2009/09/28 V1.8 Deleted END   ===============================================================
-- Ver1.10 ADD START
      WHERE   xwcv.group_company_flg = cv_0                               -- 会社：伊藤園
-- Ver1.10 ADD END
      GROUP BY xwcv.adj_dept_code
             , xwcv.account_code
             , xwcv.subacct_code
             , xwcv.transaction_date
             , xwcv.gl_batch_id
      ;
-- == 2009/08/17 V1.5 Modified END   ===============================================================
    -- 原価差額情報カーソル レコード型
    xwcv_sumr_rec xwcv_sum_cur%ROWTYPE;
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    OPEN xwcv_sum_cur;
    LOOP
      FETCH xwcv_sum_cur INTO xwcv_sumr_rec;
      EXIT WHEN xwcv_sum_cur%NOTFOUND; 
--
-- == 2009/08/17 V1.5 Modified START ===============================================================
      IF (xwcv_sumr_rec.xwcv_cost_variance_sum <> 0) THEN
        --原価差額(集約値)が0でなければ以下の処理を実施する
        IF (xwcv_sumr_rec.xwcv_transaction_date > gt_last_period_date) THEN
          xwcv_sumr_rec.gp_period_name := gt_period_name_tm;
        ELSE
          xwcv_sumr_rec.gp_period_name := gt_period_name_lm;
        END IF;
-- == 2009/08/17 V1.5 Modified END   ===============================================================
        -- 初期化
        lt_entered_dr  := NULL;  -- 借方金額
        lt_entered_cr  := NULL;  -- 貸方金額
-- == 2009/09/28 V1.8 Modified START ===============================================================
--        -- ===============================
--        -- 会計期間チェック処理 (A-7)
--        -- ===============================
--        lb_acctg_period_chk := xxcok_common_pkg.check_acctg_period_f(
--                                   gt_gl_set_of_bks_id
--                                 , xwcv_sumr_rec.xwcv_transaction_date
--                                 , cv_appl_short_name_sqlgl
--                               );
--        -- 取引日の会計期間がクローズしていた場合
--        IF( lb_acctg_period_chk = FALSE ) THEN
--          lv_errmsg := xxccp_common_pkg.get_msg(
--                           iv_application  => cv_appl_short_name_xxcoi
--                         , iv_name         => cv_msg_acctg_period_err
--                         , iv_token_name1  => cv_tkn_period
--                         , iv_token_value1 => xwcv_sumr_rec.gp_period_name
--                         , iv_token_name2  => cv_tkn_dept
--                         , iv_token_value2 => xwcv_sumr_rec.xwcv_adj_dept_code
--                         , iv_token_name3  => cv_tkn_account
--                         , iv_token_value3 => xwcv_sumr_rec.xwcv_account_code
--  -- == 2009/03/26 V1.1 Added START ===============================================================
--                         , iv_token_name4  => cv_tkn_subacct
--                         , iv_token_value4 => xwcv_sumr_rec.xwcv_subacct_code
--  -- == 2009/03/26 V1.1 Added END   ===============================================================
--                       );
--          lv_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
--          FND_FILE.PUT_LINE(
--              which  => FND_FILE.OUTPUT
--            , buff   => lv_errmsg
--          );
--          FND_FILE.PUT_LINE(
--              which  => FND_FILE.LOG
--            , buff   => lv_errbuf
--          );
--          -- エラー件数(原価差額集約単位)カウント
--          gn_error_sum_cnt := gn_error_sum_cnt + 1;
--        ELSE
--          -- ===============================
--          -- GLインターフェース格納 (A-8)
--          -- ===============================
--          -- 原価差額が＋なら借方金額にセット
--  -- == 2009/05/11 V1.2 Modified START ===============================================================
--  --        IF xwcv_sumr_rec.xwcv_cost_variance_sum < 0 THEN
--          IF xwcv_sumr_rec.xwcv_cost_variance_sum > 0 THEN
--  -- == 2009/05/11 V1.2 Modified END   ===============================================================
--            lt_entered_dr := ABS( xwcv_sumr_rec.xwcv_cost_variance_sum );
--          -- 原価差額が－なら貸方金額にセット
--          ELSE
--            lt_entered_cr := ABS( xwcv_sumr_rec.xwcv_cost_variance_sum );
--          END IF;
--          -- 一般会計OIF挿入(GLインターフェース)
--          INSERT INTO gl_interface(
--              status                                    --  1.ステータス
--            , set_of_books_id                           --  2.会計帳簿ID
--            , accounting_date                           --  3.仕訳有効日付
--            , currency_code                             --  4.通貨コード
--            , date_created                              --  5.新規作成日付
--            , created_by                                --  6.新規作成者ID
--            , actual_flag                               --  7.残高タイプ
--            , user_je_category_name                     --  8.仕訳カテゴリ名
--            , user_je_source_name                       --  9.仕訳ソース名
--            , segment1                                  -- 10.会社コード
--            , segment2                                  -- 11.部門コード
--            , segment3                                  -- 12.勘定科目コード
--            , segment4                                  -- 13.補助科目コード
--            , segment5                                  -- 14.顧客コード
--            , segment6                                  -- 15.企業コード
--            , segment7                                  -- 16.予備1
--            , segment8                                  -- 17.予備2
--            , entered_dr                                -- 18.借方金額
--            , entered_cr                                -- 19.貸方金額
--            , reference1                                -- 20.仕訳バッチ名
--            , reference4                                -- 21.仕訳名
--            , reference21                               -- 22.GLバッチID
--            , period_name                               -- 23.会計期間名
--            , group_id                                  -- 24.グループID
--            , attribute3                                -- 25.伝票番号
--            , attribute4                                -- 26.起票部門コード
--            , attribute5                                -- 27.伝票入力者
--            , context                                   -- 28.DFFコンテキスト
--          ) VALUES (
--              cv_status_new                             --  1.固定値：NEW
--            , gt_gl_set_of_bks_id                       --  2.プロファイル値：会計帳簿ID
--            , xwcv_sumr_rec.xwcv_transaction_date       --  3.取引日
--            , cv_code_jpy                               --  4.固定値：JPY
--            , SYSDATE                                   --  5.システム日付
--            , cn_created_by                             --  6.ユーザーID
--            , cv_flag_a                                 --  7.固定値：A
--            , gt_je_category_name_inv_cost              --  8.プロファイル値：在庫原価振替
--            , gt_je_source_name_inv_cost                --  9.プロファイル値：在庫原価振替
--            , gt_aff1_company_code                      -- 10.プロファイル値：会社コード
--            , xwcv_sumr_rec.xwcv_adj_dept_code          -- 11.調整部門コード
--            , xwcv_sumr_rec.xwcv_account_code           -- 12.勘定科目コード
--  -- == 2009/03/26 V1.1 Added START ===============================================================
--  --          , gt_aff4_dummy                             -- 13.プロファイル値：補助科目_ダミー値
--            , xwcv_sumr_rec.xwcv_subacct_code           -- 13.補助科目コード
--  -- == 2009/03/26 V1.1 Added END   ===============================================================
--            , gt_aff5_dummy                             -- 14.プロファイル値：顧客コード_ダミー値
--            , gt_aff6_dummy                             -- 15.プロファイル値：企業コード_ダミー値
--            , gt_aff7_dummy                             -- 16.プロファイル値：予備１_ダミー値
--            , gt_aff8_dummy                             -- 17.プロファイル値：予備２_ダミー値
--            , lt_entered_dr                             -- 18.借方金額
--            , lt_entered_cr                             -- 19.貸方金額
--            , gt_je_batch_name                          -- 20.仕訳バッチ名
--            , cv_pkg_name                               -- 21.固定値：XCOI007A01C(プログラム短縮名)
--            , TO_CHAR( xwcv_sumr_rec.xwcv_gl_batch_id ) -- 22.GLバッチID
--            , xwcv_sumr_rec.gp_period_name              -- 23.会計期間名
--            , gt_group_id                               -- 24.グループID
--            , TO_CHAR( cn_request_id )                  -- 25.要求ID
--            , xwcv_sumr_rec.xwcv_adj_dept_code          -- 26.調整部門コード
--            , TO_CHAR( cn_created_by )                  -- 27.ユーザーID
--            , gt_gl_set_of_bks_name                     -- 28.プロファイル値：会計帳簿名
--          );
--          -- 成功件数(原価差額集約単位)カウント
--          gn_normal_sum_cnt := gn_normal_sum_cnt + 1;
--        END IF;
--
        -- ===============================
        -- GLインターフェース格納 (A-8)
        -- ===============================
        -- 原価差額が＋なら借方金額にセット
        IF xwcv_sumr_rec.xwcv_cost_variance_sum > 0 THEN
          lt_entered_dr := ABS( xwcv_sumr_rec.xwcv_cost_variance_sum );
        -- 原価差額が－なら貸方金額にセット
        ELSE
          lt_entered_cr := ABS( xwcv_sumr_rec.xwcv_cost_variance_sum );
        END IF;
        -- 一般会計OIF挿入(GLインターフェース)
        INSERT INTO gl_interface(
            status                                    --  1.ステータス
          , set_of_books_id                           --  2.会計帳簿ID
          , accounting_date                           --  3.仕訳有効日付
          , currency_code                             --  4.通貨コード
          , date_created                              --  5.新規作成日付
          , created_by                                --  6.新規作成者ID
          , actual_flag                               --  7.残高タイプ
          , user_je_category_name                     --  8.仕訳カテゴリ名
          , user_je_source_name                       --  9.仕訳ソース名
          , segment1                                  -- 10.会社コード
          , segment2                                  -- 11.部門コード
          , segment3                                  -- 12.勘定科目コード
          , segment4                                  -- 13.補助科目コード
          , segment5                                  -- 14.顧客コード
          , segment6                                  -- 15.企業コード
          , segment7                                  -- 16.予備1
          , segment8                                  -- 17.予備2
          , entered_dr                                -- 18.借方金額
          , entered_cr                                -- 19.貸方金額
          , reference1                                -- 20.仕訳バッチ名
          , reference4                                -- 21.仕訳名
          , reference21                               -- 22.GLバッチID
          , period_name                               -- 23.会計期間名
          , group_id                                  -- 24.グループID
          , attribute3                                -- 25.伝票番号
          , attribute4                                -- 26.起票部門コード
          , attribute5                                -- 27.伝票入力者
          , context                                   -- 28.DFFコンテキスト
        ) VALUES (
            cv_status_new                             --  1.固定値：NEW
          , gt_gl_set_of_bks_id                       --  2.プロファイル値：会計帳簿ID
          , xwcv_sumr_rec.xwcv_transaction_date       --  3.取引日
          , cv_code_jpy                               --  4.固定値：JPY
          , SYSDATE                                   --  5.システム日付
          , cn_created_by                             --  6.ユーザーID
          , cv_flag_a                                 --  7.固定値：A
          , gt_je_category_name_inv_cost              --  8.プロファイル値：在庫原価振替
          , gt_je_source_name_inv_cost                --  9.プロファイル値：在庫原価振替
          , gt_aff1_company_code                      -- 10.プロファイル値：会社コード
          , xwcv_sumr_rec.xwcv_adj_dept_code          -- 11.調整部門コード
          , xwcv_sumr_rec.xwcv_account_code           -- 12.勘定科目コード
          , xwcv_sumr_rec.xwcv_subacct_code           -- 13.補助科目コード
          , gt_aff5_dummy                             -- 14.プロファイル値：顧客コード_ダミー値
          , gt_aff6_dummy                             -- 15.プロファイル値：企業コード_ダミー値
          , gt_aff7_dummy                             -- 16.プロファイル値：予備１_ダミー値
          , gt_aff8_dummy                             -- 17.プロファイル値：予備２_ダミー値
          , lt_entered_dr                             -- 18.借方金額
          , lt_entered_cr                             -- 19.貸方金額
          , gt_je_batch_name                          -- 20.仕訳バッチ名
          , cv_pkg_name                               -- 21.固定値：XCOI007A01C(プログラム短縮名)
          , TO_CHAR( xwcv_sumr_rec.xwcv_gl_batch_id ) -- 22.GLバッチID
          , xwcv_sumr_rec.gp_period_name              -- 23.会計期間名
          , gt_group_id                               -- 24.グループID
          , TO_CHAR( cn_request_id )                  -- 25.要求ID
          , xwcv_sumr_rec.xwcv_adj_dept_code          -- 26.調整部門コード
          , TO_CHAR( cn_created_by )                  -- 27.ユーザーID
          , gt_gl_set_of_bks_name                     -- 28.プロファイル値：会計帳簿名
        );
        -- 成功件数(原価差額集約単位)カウント
        gn_normal_sum_cnt := gn_normal_sum_cnt + 1;
-- == 2009/09/28 V1.8 Modified END   ===============================================================
-- == 2009/08/17 V1.5 Modified START ===============================================================
      END IF;
-- == 2009/08/17 V1.5 Modified END   ===============================================================
    END LOOP;
    -- 対象件数(原価差額集約単位)セット
    gn_target_sum_cnt := xwcv_sum_cur%ROWCOUNT;
    CLOSE xwcv_sum_cur;
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
      -- カーソルがオープンしていたらクローズ
      IF ( xwcv_sum_cur%ISOPEN ) THEN
        CLOSE xwcv_sum_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_gl_if;
--
-- Ver1.10 ADD START
  /**********************************************************************************
   * Procedure Name   : ins_gl_if_reg
   * Description      : GL-IF登録処理 (A-11)
   ***********************************************************************************/
  PROCEDURE ins_gl_if_reg(
    id_accounting_date       IN  DATE,         --   仕訳有効日付
    iv_segment1              IN  VARCHAR2,     --   会社コード
    iv_segment2              IN  VARCHAR2,     --   部門コード
    iv_segment3              IN  VARCHAR2,     --   勘定科目コード
    iv_segment4              IN  VARCHAR2,     --   補助科目コード
    in_entered_dr            IN  NUMBER,       --   借方金額
    in_entered_cr            IN  NUMBER,       --   貸方金額
    iv_reference21           IN  VARCHAR2,     --   GLバッチID
    iv_period_name           IN  VARCHAR2,     --   会計期間名
    iv_user_je_category_name IN  VARCHAR2,     --   仕訳カテゴリ名
    ov_errbuf                OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode               OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg                OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_gl_if_reg'; -- プログラム名
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
    cv_flag_n            CONSTANT VARCHAR2(1) := 'N';     -- フラグ値：N
    cv_status_new        CONSTANT VARCHAR2(3) := 'NEW';   -- 固定値：NEW
    cv_code_jpy          CONSTANT VARCHAR2(3) := 'JPY';   -- 固定値：JPY
    cv_flag_a            CONSTANT VARCHAR2(1) := 'A';     -- 固定値：A
--
    -- *** ローカル変数 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 一般会計OIF挿入
    INSERT INTO gl_interface(
        status                               --  1.ステータス
      , set_of_books_id                      --  2.会計帳簿ID
      , accounting_date                      --  3.仕訳有効日付
      , currency_code                        --  4.通貨コード
      , date_created                         --  5.新規作成日付
      , created_by                           --  6.新規作成者ID
      , actual_flag                          --  7.残高タイプ
      , user_je_category_name                --  8.仕訳カテゴリ名
      , user_je_source_name                  --  9.仕訳ソース名
      , segment1                             -- 10.会社コード
      , segment2                             -- 11.部門コード
      , segment3                             -- 12.勘定科目コード
      , segment4                             -- 13.補助科目コード
      , segment5                             -- 14.顧客コード
      , segment6                             -- 15.企業コード
      , segment7                             -- 16.予備1
      , segment8                             -- 17.予備2
      , entered_dr                           -- 18.借方金額
      , entered_cr                           -- 19.貸方金額
      , reference1                           -- 20.仕訳バッチ名
      , reference4                           -- 21.仕訳名
      , reference21                          -- 22.GLバッチID
      , period_name                          -- 23.会計期間名
      , group_id                             -- 24.グループID
      , attribute3                           -- 25.伝票番号
      , attribute4                           -- 26.起票部門コード
      , attribute5                           -- 27.伝票入力者
      , context                              -- 28.DFFコンテキスト
    ) VALUES (
        cv_status_new                        --  1.固定値：NEW
      , gt_gl_set_of_bks_id                  --  2.プロファイル値：会計帳簿ID
      , id_accounting_date                   --  3.取引日
      , cv_code_jpy                          --  4.固定値：JPY
      , SYSDATE                              --  5.システム日付
      , cn_created_by                        --  6.ユーザーID
      , cv_flag_a                            --  7.固定値：A
      , iv_user_je_category_name             --  8.仕訳カテゴリ名
      , gt_je_source_name_inv_cost           --  9.プロファイル値：在庫原価振替
      , iv_segment1                          -- 10.会社コード
      , iv_segment2                          -- 11.調整部門コード
      , iv_segment3                          -- 12.勘定科目コード
      , iv_segment4                          -- 13.補助科目コード
      , gt_aff5_dummy                        -- 14.プロファイル値：顧客コード_ダミー値
      , gt_aff6_dummy                        -- 15.プロファイル値：企業コード_ダミー値
      , gt_aff7_dummy                        -- 16.プロファイル値：予備１_ダミー値
      , gt_aff8_dummy                        -- 17.プロファイル値：予備２_ダミー値
      , in_entered_dr                        -- 18.借方金額
      , in_entered_cr                        -- 19.貸方金額
      , gt_je_batch_name                     -- 20.仕訳バッチ名
      , cv_pkg_name || cv_pkg_name_gr_comp   -- 21.固定値：XCOI007A01C(プログラム短縮名)
      , iv_reference21                       -- 22.GLバッチID
      , iv_period_name                       -- 23.会計期間名
      , gt_group_id                          -- 24.グループID
      , TO_CHAR( cn_request_id )             -- 25.要求ID
      , gt_aff2_adj_dept_code                -- 26.調整部門コード
      , TO_CHAR( cn_created_by )             -- 27.ユーザーID
      , gt_gl_set_of_bks_name                -- 28.プロファイル値：会計帳簿名
    );
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
  END ins_gl_if_reg;
--
  /**********************************************************************************
   * Procedure Name   : ins_gl_if_gr_comp
   * Description      : 棚卸資産情報GL-IF登録(グループ会社) (A-10)
   ***********************************************************************************/
  PROCEDURE ins_gl_if_gr_comp(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_gl_if_gr_comp'; -- プログラム名
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
    cv_flag_n            CONSTANT VARCHAR2(1) := 'N';     -- フラグ値：N
    cv_status_new        CONSTANT VARCHAR2(3) := 'NEW';   -- 固定値：NEW
    cv_code_jpy          CONSTANT VARCHAR2(3) := 'JPY';   -- 固定値：JPY
    cv_flag_a            CONSTANT VARCHAR2(1) := 'A';     -- 固定値：A
--
    -- *** ローカル変数 ***
    lt_entered_dr        gl_interface.entered_dr%TYPE;    -- 借方金額
    lt_entered_cr        gl_interface.entered_cr%TYPE;    -- 貸方金額
    lt_segment2          gl_interface.segment2%TYPE;      -- 部門
    lt_segment3          gl_interface.segment3%TYPE;      -- 勘定科目
    lt_segment4          gl_interface.segment4%TYPE;      -- 補助科目
--
    -- ===============================
    -- 棚卸資産情報の抽出
    -- ===============================
    -- 棚卸資産仕訳情報カーソル
    CURSOR xwcv_sum_gr_cur
    IS
      SELECT
              xwcv2.dept_code                    AS xwcv_dept_code              -- 部門コード
            , xwcv2.grcp_adj_dept_code           AS xwcv_grcp_adj_dept_code     -- 変換後調整部門コード
            , xwcv2.account_code                 AS xwcv_account_code           -- 勘定科目コード
            , xwcv2.subacct_code                 AS xwcv_subacct_code           -- 補助科目コード
            , xwcv2.transaction_date             AS xwcv_transaction_date       -- 取引日
            , xwcv2.gl_batch_id                  AS xwcv_gl_batch_id            -- GLバッチID
            , NULL                               AS gp_period_name              -- 会計期間名
            , xwcv2.company_code                 AS xwcv_company_code           -- 会社コード
            , xwcv2.transfer_ownership_flg       AS transfer_ownership_flg      -- 所有権移転取引フラグ
            , ROUND( SUM( xwcv2.primary_quantity * operation_cost ),0)
                                                 AS sum_amount                  -- 営業原価金額
            , ROUND( SUM( xwcv2.primary_quantity * standard_cost ),0)
                                                 AS sum_cost_amount             -- 標準原価金額
            , ROUND( SUM( xwcv2.primary_quantity *
                ROUND( xwcv2.standard_cost * ( 1 + ( flv.attribute1 / 100 )),2)),0)
                                                 AS sum_purchase_amount         -- 購入金額
      FROM    xxcoi_wk_cost_variance    xwcv2                              -- 原価差額ワークテーブル
            , xxcfr_bd_company_info_v   flv                                -- 各社利益率
      WHERE   xwcv2.group_company_flg = cv_1                               -- 1:グループ会社
      AND     xwcv2.reverse_flg       = cv_0                               -- 0:元データ
      AND     flv.lookup_type         = cv_company_profit_rate
      AND     flv.company_code        = xwcv2.company_code
      AND     TRUNC( xwcv2.transaction_date )  BETWEEN NVL( flv.start_date_active, xwcv2.transaction_date )
                                           AND     NVL( flv.end_date_active, xwcv2.transaction_date )
      AND     xwcv2.transaction_type_id <> gt_trans_type_std_cost_upd      -- 標準原価更新は除く
      GROUP BY xwcv2.dept_code
             , xwcv2.grcp_adj_dept_code
             , xwcv2.account_code
             , xwcv2.subacct_code
             , xwcv2.transaction_date
             , xwcv2.gl_batch_id
             , xwcv2.company_code
             , xwcv2.transfer_ownership_flg
      ;
    -- 棚卸資産情報カーソル レコード型
    xwcv_sumr_gr_rec xwcv_sum_gr_cur%ROWTYPE;
--
    -- ===============================
    -- 標準原価更新情報の抽出
    -- ===============================
    -- 標準原価更新情報カーソル
    CURSOR xwcv_sum_gr_cur2
    IS
      SELECT
              xwcv2.dept_code                    AS xwcv_dept_code              -- 部門コード
            , xwcv2.grcp_adj_dept_code           AS xwcv_grcp_adj_dept_code     -- 変換後調整部門コード
            , xwcv2.account_code                 AS xwcv_account_code           -- 勘定科目コード
            , xwcv2.subacct_code                 AS xwcv_subacct_code           -- 補助科目コード
            , xwcv2.transaction_date             AS xwcv_transaction_date       -- 取引日
            , xwcv2.gl_batch_id                  AS xwcv_gl_batch_id            -- GLバッチID
            , NULL                               AS gp_period_name              -- 会計期間名
            , xwcv2.company_code                 AS xwcv_company_code           -- 会社コード
            , xwcv2.transfer_ownership_flg       AS transfer_ownership_flg      -- 所有権移転取引フラグ
            , ROUND(SUM(xwcv2.base_transaction_value),0)
                                                 AS sum_amount                  -- 営業原価金額
      FROM    xxcoi_wk_cost_variance    xwcv2                                -- 原価差額ワークテーブル
      WHERE   xwcv2.group_company_flg   = cv_1                               -- 1:グループ会社
      AND     xwcv2.reverse_flg         = cv_0                               -- 0:元データ
      AND     xwcv2.transaction_type_id = gt_trans_type_std_cost_upd         -- 標準原価更新
      GROUP BY xwcv2.dept_code
             , xwcv2.grcp_adj_dept_code
             , xwcv2.account_code
             , xwcv2.subacct_code
             , xwcv2.transaction_date
             , xwcv2.gl_batch_id
             , xwcv2.company_code
             , xwcv2.transfer_ownership_flg
      ;
    -- 標準原価更新情報カーソル レコード型
    xwcv_sumr_gr_rec2 xwcv_sum_gr_cur2%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ============================================================
    -- グループ会社と対になる仕訳が伊藤園の場合、グループ会社と判定
    -- ============================================================
    -- グループ会社フラグを更新
    UPDATE xxcoi_wk_cost_variance xwcv
    SET    xwcv.group_company_flg = cv_1   -- 1:グループ会社
    WHERE  EXISTS ( SELECT 1
                    FROM   xxcoi_wk_cost_variance xwcv2
                    WHERE  xwcv.transaction_id     = xwcv2.transaction_id
                    AND    xwcv2.group_company_flg = cv_1
                  )
    ;
--
    -- 対になる伊藤園仕訳の赤データ作成
    INSERT INTO xxcoi_wk_cost_variance(
        transaction_id                                  --  1.在庫取引ID
      , dept_code                                       --  2.部門コード
      , adj_dept_code                                   --  3.調整部門コード
      , account_code                                    --  4.勘定科目コード
      , subacct_code                                    --  5.補助科目コード
      , inventory_item_id                               --  6.品目ID
      , transaction_date                                --  7.取引日
      , transaction_value                               --  8.取引金額
      , primary_quantity                                --  9.取引数量
      , base_transaction_value                          -- 10.基準単位金額
      , organization_id                                 -- 11.組織ID
      , gl_batch_id                                     -- 12.GLバッチID
      , standard_cost                                   -- 13.標準原価
      , operation_cost                                  -- 14.営業原価
      , cost_variance                                   -- 15.原価差額
      , status                                          -- 16.ステータス
      , created_by                                      -- 17.作成者
      , creation_date                                   -- 18.作成日
      , last_updated_by                                 -- 19.最終更新者
      , last_update_date                                -- 20.最終更新日
      , last_update_login                               -- 21.最終更新ログイン
      , request_id                                      -- 22.要求ID
      , program_application_id                          -- 23.コンカレント・プログラム・アプリケーションID
      , program_id                                      -- 24.コンカレント・プログラムID
      , program_update_date                             -- 25.プログラム更新日
      , company_code                                    -- 26.会社コード
      , transaction_type_id                             -- 27.取引タイプID
      , group_company_flg                               -- 28.グループ会社フラグ
      , transfer_ownership_flg                          -- 29.所有権移転取引フラグ
      , reverse_flg                                     -- 30.反転フラグ
    )
    SELECT
        xwcv.transaction_id                             --  1.在庫取引ID
      , xwcv.dept_code                                  --  2.部門コード
      , xwcv.adj_dept_code                              --  3.調整部門コード
      , xwcv.account_code                               --  4.勘定科目コード
      , xwcv.subacct_code                               --  5.補助科目コード
      , xwcv.inventory_item_id                          --  6.品目ID
      , xwcv.transaction_date                           --  7.取引日
      , xwcv.transaction_value                          --  8.取引金額
      , (xwcv.primary_quantity * -1)                    --  9.取引数量
      , (xwcv.base_transaction_value * -1)              -- 10.基準単位金額
      , xwcv.organization_id                            -- 11.組織ID
      , xwcv.gl_batch_id                                -- 12.GLバッチID
      , xwcv.standard_cost                              -- 13.標準原価
      , xwcv.operation_cost                             -- 14.営業原価
      , (xwcv.cost_variance * -1)                       -- 15.原価差額
      , xwcv.status                                     -- 16.ステータス
      , xwcv.created_by                                 -- 17.作成者
      , xwcv.creation_date                              -- 18.作成日
      , xwcv.last_updated_by                            -- 19.最終更新者
      , xwcv.last_update_date                           -- 20.最終更新日
      , xwcv.last_update_login                          -- 21.最終更新ログイン
      , xwcv.request_id                                 -- 22.要求ID
      , xwcv.program_application_id                     -- 23.コンカレント・プログラム・アプリケーションID
      , xwcv.program_id                                 -- 24.コンカレント・プログラムID
      , xwcv.program_update_date                        -- 25.プログラム更新日
      , xwcv.company_code                               -- 26.会社コード
      , xwcv.transaction_type_id                        -- 27.取引タイプID
      , xwcv.group_company_flg                          -- 28.グループ会社フラグ
      , xwcv.transfer_ownership_flg                     -- 29.所有権移転取引フラグ
      , cv_1                                            -- 30.反転フラグ
    FROM  xxcoi_wk_cost_variance xwcv
    WHERE xwcv.group_company_flg = cv_1
    AND   xwcv.company_code      = gt_aff1_company_code
    ;
--
    -- ============================================================
    -- グループ会社を更新
    -- ============================================================
    UPDATE xxcoi_wk_cost_variance xwcv
    SET    xwcv.company_code = (SELECT xwcv2.company_code
                                FROM   xxcoi_wk_cost_variance xwcv2
                                WHERE  xwcv.transaction_id    = xwcv2.transaction_id
                                AND    xwcv2.company_code    <> gt_aff1_company_code
                                AND    ROWNUM = 1)
    WHERE  xwcv.group_company_flg = cv_1                  -- 1:グループ会社
    AND    xwcv.company_code      = gt_aff1_company_code  -- 伊藤園
    ;
--
    -- ============================================================
    -- グループ会社の調整部門変換
    -- ============================================================
    UPDATE xxcoi_wk_cost_variance xwcv
    SET    xwcv.grcp_adj_dept_code = (CASE
                                      WHEN (xwcv.dept_code IN (gt_aff2_adj_dept_code,gt_aff2_acc_dept_code)  ) THEN
                                          (SELECT flv.attribute3
                                           FROM   fnd_lookup_values   flv
                                           WHERE  flv.lookup_type   = cv_conv_dept_code
                                           AND    flv.attribute1    = xwcv.company_code
                                           AND    flv.attribute2    = xwcv.dept_code
                                           AND    flv.language      = USERENV( 'LANG' ))
                                      ELSE
                                        xwcv.dept_code
                                      END)
    WHERE  xwcv.group_company_flg = cv_1      -- 1:グループ会社
    ;
--
    -- ====================================
    -- GLインターフェース格納(棚卸資産情報)
    -- ====================================
    OPEN xwcv_sum_gr_cur;
    LOOP
      FETCH xwcv_sum_gr_cur INTO xwcv_sumr_gr_rec;
      EXIT WHEN xwcv_sum_gr_cur%NOTFOUND; 
--
      IF (xwcv_sumr_gr_rec.sum_amount <> 0) THEN
        --金額が0でなければ以下の処理を実施する
        IF (xwcv_sumr_gr_rec.xwcv_transaction_date > gt_last_period_date) THEN
          xwcv_sumr_gr_rec.gp_period_name := gt_period_name_tm;
        ELSE
          xwcv_sumr_gr_rec.gp_period_name := gt_period_name_lm;
        END IF;
--
        -- 初期化
        lt_entered_dr      := NULL;  -- 借方金額
        lt_entered_cr      := NULL;  -- 貸方金額
--
        -- 金額が＋なら借方金額にセット
        IF ( xwcv_sumr_gr_rec.sum_amount * -1 ) > 0 THEN
          lt_entered_dr := ABS( xwcv_sumr_gr_rec.sum_amount );
        -- 金額が－なら貸方金額にセット
        ELSE
          lt_entered_cr := ABS( xwcv_sumr_gr_rec.sum_amount );
        END IF;
--
        -- ===============================
        -- GL-IF登録処理（振り戻し）
        -- ===============================
        ins_gl_if_reg(
            id_accounting_date       => xwcv_sumr_gr_rec.xwcv_transaction_date,        -- 仕訳有効日付
            iv_segment1              => gt_aff1_company_code,                          -- 会社コード
            iv_segment2              => xwcv_sumr_gr_rec.xwcv_dept_code,               -- 部門コード
            iv_segment3              => xwcv_sumr_gr_rec.xwcv_account_code,            -- 勘定科目コード
            iv_segment4              => xwcv_sumr_gr_rec.xwcv_subacct_code,            -- 補助科目コード
            in_entered_dr            => lt_entered_dr,                                 -- 借方金額
            in_entered_cr            => lt_entered_cr,                                 -- 貸方金額
            iv_reference21           => TO_CHAR( xwcv_sumr_gr_rec.xwcv_gl_batch_id ),  -- GLバッチID
            iv_period_name           => xwcv_sumr_gr_rec.gp_period_name,               -- 会計期間名
            iv_user_je_category_name => gt_je_category_name_inv_gr,                    -- 仕訳カテゴリ名
            ov_errbuf                => lv_errbuf    -- エラー・メッセージ
          , ov_retcode               => lv_retcode   -- リターン・コード
          , ov_errmsg                => lv_errmsg    -- ユーザー・エラー・メッセージ
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        -- 所有権移転取引の場合
        IF ( xwcv_sumr_gr_rec.transfer_ownership_flg = cv_1 ) THEN
          -- 初期化
          lt_entered_dr      := NULL;  -- 借方金額
          lt_entered_cr      := NULL;  -- 貸方金額
          lt_segment2        := NULL;  -- 部門
          lt_segment3        := NULL;  -- 勘定科目
          lt_segment4        := NULL;  -- 補助科目
--
          -- 計上部門取得
          BEGIN
            SELECT  flv.attribute1  AS attribute1
                  , flv.attribute2  AS attribute2
            INTO    gt_aff2_cost_dept_dr
                  , gt_aff2_cost_dept_cr
            FROM   fnd_lookup_values   flv
            WHERE  flv.lookup_type   = cv_conv_cost_dept
            AND    flv.language      = USERENV( 'LANG' )
            AND    flv.enabled_flag  = 'Y'
            AND    TRUNC( xwcv_sumr_gr_rec.xwcv_transaction_date )  BETWEEN NVL( flv.start_date_active, xwcv_sumr_gr_rec.xwcv_transaction_date )
                                             AND     NVL( flv.end_date_active, xwcv_sumr_gr_rec.xwcv_transaction_date )
            ;
          EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name_xxcoi
                           , iv_name         => cv_msg_code_xxcoi_10750
                           , iv_token_name1  => cv_tkn_lookup_type
                           , iv_token_value1 => cv_conv_cost_dept
                         );
            lv_errbuf :=  lv_errmsg;
            RAISE global_api_expt;
          END;
--
          -- 売上原価の勘定科目・補助科目取得
          BEGIN
            SELECT  flv.attribute1  AS attribute1
                  , flv.attribute2  AS attribute2
            INTO    gt_aff3_cost_account
                  , gt_aff4_cost_sub_acct
            FROM    fnd_lookup_values   flv
            WHERE   flv.lookup_type   = cv_conv_cost_account
            AND     flv.attribute3    = xwcv_sumr_gr_rec.xwcv_account_code
            AND     flv.attribute4    = xwcv_sumr_gr_rec.xwcv_subacct_code
            AND     flv.language      = USERENV( 'LANG' )
            AND     flv.enabled_flag  = 'Y'
            AND     TRUNC( xwcv_sumr_gr_rec.xwcv_transaction_date )  BETWEEN NVL( flv.start_date_active, xwcv_sumr_gr_rec.xwcv_transaction_date )
                                              AND     NVL( flv.end_date_active, xwcv_sumr_gr_rec.xwcv_transaction_date )
            ;
          EXCEPTION
          WHEN OTHERS THEN
            -- 変換対象外の勘定科目
            gt_aff3_cost_account  := xwcv_sumr_gr_rec.xwcv_account_code;
            gt_aff4_cost_sub_acct := xwcv_sumr_gr_rec.xwcv_subacct_code;
          END;
--
          -- 金額が＋なら借方金額にセット
          IF xwcv_sumr_gr_rec.sum_cost_amount > 0 THEN
            lt_entered_dr := ABS( xwcv_sumr_gr_rec.sum_cost_amount );
            lt_segment2   := gt_aff2_cost_dept_dr;
            lt_segment3   := gt_aff3_cost_account;
            lt_segment4   := gt_aff4_cost_sub_acct;
          -- 金額が－なら貸方金額にセット
          ELSE
            lt_entered_cr := ABS( xwcv_sumr_gr_rec.sum_cost_amount );
            lt_segment2   := gt_aff2_cost_dept_cr;
            lt_segment3   := xwcv_sumr_gr_rec.xwcv_account_code;
            lt_segment4   := xwcv_sumr_gr_rec.xwcv_subacct_code;
          END IF;
--
          -- ===============================
          -- GL-IF登録処理（売上原価）
          -- ===============================
          ins_gl_if_reg(
              id_accounting_date       => xwcv_sumr_gr_rec.xwcv_transaction_date,        -- 仕訳有効日付
              iv_segment1              => gt_aff1_company_code,                          -- 会社コード
              iv_segment2              => lt_segment2,                                   -- 部門コード
              iv_segment3              => lt_segment3,                                   -- 勘定科目コード
              iv_segment4              => lt_segment4,                                   -- 補助科目コード
              in_entered_dr            => lt_entered_dr,                                 -- 借方金額
              in_entered_cr            => lt_entered_cr,                                 -- 貸方金額
              iv_reference21           => TO_CHAR( xwcv_sumr_gr_rec.xwcv_gl_batch_id ),  -- GLバッチID
              iv_period_name           => xwcv_sumr_gr_rec.gp_period_name,               -- 会計期間名
              iv_user_je_category_name => gt_je_category_name_inv_gr,                    -- 仕訳カテゴリ名
              ov_errbuf                => lv_errbuf   -- エラー・メッセージ
            , ov_retcode               => lv_retcode  -- リターン・コード
            , ov_errmsg                => lv_errmsg   -- ユーザー・エラー・メッセージ
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
          -- 初期化
          lt_entered_dr      := NULL;  -- 借方金額
          lt_entered_cr      := NULL;  -- 貸方金額
          lt_segment2        := NULL;  -- 部門
          lt_segment3        := NULL;  -- 勘定科目
          lt_segment4        := NULL;  -- 補助科目
          -- 金額が＋なら借方金額にセット
          IF xwcv_sumr_gr_rec.sum_purchase_amount > 0 THEN
            lt_entered_dr := ABS( xwcv_sumr_gr_rec.sum_purchase_amount );
            lt_segment2   := xwcv_sumr_gr_rec.xwcv_grcp_adj_dept_code;
            lt_segment3   := xwcv_sumr_gr_rec.xwcv_account_code;
            lt_segment4   := xwcv_sumr_gr_rec.xwcv_subacct_code;
          -- 金額が－なら貸方金額にセット
          ELSE
            lt_entered_cr := ABS( xwcv_sumr_gr_rec.sum_purchase_amount );
            lt_segment2   := xwcv_sumr_gr_rec.xwcv_grcp_adj_dept_code;
            lt_segment3   := gt_aff3_payable;    -- 買掛金
            lt_segment4   := gt_aff4_payable;    -- 買掛金(補助)
          END IF;
          -- ===============================
          -- GL-IF登録処理（棚卸資産仕訳）
          -- ===============================
          ins_gl_if_reg(
              id_accounting_date       => xwcv_sumr_gr_rec.xwcv_transaction_date,        -- 仕訳有効日付
              iv_segment1              => xwcv_sumr_gr_rec.xwcv_company_code,            -- 会社コード
              iv_segment2              => lt_segment2,                                   -- 部門コード
              iv_segment3              => lt_segment3,                                   -- 勘定科目コード
              iv_segment4              => lt_segment4,                                   -- 補助科目コード
              in_entered_dr            => lt_entered_dr,                                 -- 借方金額
              in_entered_cr            => lt_entered_cr,                                 -- 貸方金額
              iv_reference21           => TO_CHAR( xwcv_sumr_gr_rec.xwcv_gl_batch_id ),  -- GLバッチID
              iv_period_name           => xwcv_sumr_gr_rec.gp_period_name,               -- 会計期間名
              iv_user_je_category_name => gt_je_category_name_inv_gr,                    -- 仕訳カテゴリ名
              ov_errbuf                => lv_errbuf   -- エラー・メッセージ
            , ov_retcode               => lv_retcode  -- リターン・コード
            , ov_errmsg                => lv_errmsg   -- ユーザー・エラー・メッセージ
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
        ELSE
          -- 所有権移転取引以外
          -- 初期化
          lt_entered_dr      := NULL;  -- 借方金額
          lt_entered_cr      := NULL;  -- 貸方金額
          -- 金額が＋なら借方金額にセット
          IF xwcv_sumr_gr_rec.sum_purchase_amount > 0 THEN
            lt_entered_dr := ABS( xwcv_sumr_gr_rec.sum_purchase_amount );
          -- 金額が－なら貸方金額にセット
          ELSE
            lt_entered_cr := ABS( xwcv_sumr_gr_rec.sum_purchase_amount );
          END IF;
--
          -- ===============================
          -- GL-IF登録処理（棚卸資産仕訳）
          -- ===============================
          ins_gl_if_reg(
              id_accounting_date       => xwcv_sumr_gr_rec.xwcv_transaction_date,        -- 仕訳有効日付
              iv_segment1              => xwcv_sumr_gr_rec.xwcv_company_code,            -- 会社コード
              iv_segment2              => xwcv_sumr_gr_rec.xwcv_grcp_adj_dept_code,      -- 部門コード
              iv_segment3              => xwcv_sumr_gr_rec.xwcv_account_code,            -- 勘定科目コード
              iv_segment4              => xwcv_sumr_gr_rec.xwcv_subacct_code,            -- 補助科目コード
              in_entered_dr            => lt_entered_dr,                                 -- 借方金額
              in_entered_cr            => lt_entered_cr,                                 -- 貸方金額
              iv_reference21           => TO_CHAR( xwcv_sumr_gr_rec.xwcv_gl_batch_id ),  -- GLバッチID
              iv_period_name           => xwcv_sumr_gr_rec.gp_period_name,               -- 会計期間名
              iv_user_je_category_name => gt_je_category_name_inv_gr,                    -- 仕訳カテゴリ名
              ov_errbuf                => lv_errbuf   -- エラー・メッセージ
            , ov_retcode               => lv_retcode  -- リターン・コード
            , ov_errmsg                => lv_errmsg   -- ユーザー・エラー・メッセージ
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
      END IF;
    END LOOP;
    -- 対象件数(グループ会社集約単位)セット
    gn_target_sum_cnt_gr := xwcv_sum_gr_cur%ROWCOUNT;
    CLOSE xwcv_sum_gr_cur;
--
    -- ========================================
    -- GLインターフェース格納(標準原価更新情報)
    -- ========================================
    OPEN xwcv_sum_gr_cur2;
    LOOP
      FETCH xwcv_sum_gr_cur2 INTO xwcv_sumr_gr_rec2;
      EXIT WHEN xwcv_sum_gr_cur2%NOTFOUND; 
--
      IF (xwcv_sumr_gr_rec2.sum_amount <> 0) THEN
        --金額が0でなければ以下の処理を実施する
        IF (xwcv_sumr_gr_rec2.xwcv_transaction_date > gt_last_period_date) THEN
          xwcv_sumr_gr_rec2.gp_period_name := gt_period_name_tm;
        ELSE
          xwcv_sumr_gr_rec2.gp_period_name := gt_period_name_lm;
        END IF;
--
        -- 初期化
        lt_entered_dr      := NULL;  -- 借方金額
        lt_entered_cr      := NULL;  -- 貸方金額
--
        -- 金額が＋なら借方金額にセット
        IF ( xwcv_sumr_gr_rec2.sum_amount * -1 ) > 0 THEN
          lt_entered_dr := ABS( xwcv_sumr_gr_rec2.sum_amount );
        -- 金額が－なら貸方金額にセット
        ELSE
          lt_entered_cr := ABS( xwcv_sumr_gr_rec2.sum_amount );
        END IF;
--
        -- ===============================
        -- GL-IF登録処理（振り戻し）
        -- ===============================
        ins_gl_if_reg(
            id_accounting_date       => xwcv_sumr_gr_rec2.xwcv_transaction_date,        -- 仕訳有効日付
            iv_segment1              => gt_aff1_company_code,                           -- 会社コード
            iv_segment2              => xwcv_sumr_gr_rec2.xwcv_dept_code,               -- 部門コード
            iv_segment3              => xwcv_sumr_gr_rec2.xwcv_account_code,            -- 勘定科目コード
            iv_segment4              => xwcv_sumr_gr_rec2.xwcv_subacct_code,            -- 補助科目コード
            in_entered_dr            => lt_entered_dr,                                  -- 借方金額
            in_entered_cr            => lt_entered_cr,                                  -- 貸方金額
            iv_reference21           => TO_CHAR( xwcv_sumr_gr_rec2.xwcv_gl_batch_id ),  -- GLバッチID
            iv_period_name           => xwcv_sumr_gr_rec2.gp_period_name,               -- 会計期間名
            iv_user_je_category_name => gt_je_category_name_inv_gr,                     -- 仕訳カテゴリ名
            ov_errbuf                => lv_errbuf    -- エラー・メッセージ
          , ov_retcode               => lv_retcode   -- リターン・コード
          , ov_errmsg                => lv_errmsg    -- ユーザー・エラー・メッセージ
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
    END LOOP;
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
      -- カーソルがオープンしていたらクローズ
      IF ( xwcv_sum_gr_cur%ISOPEN ) THEN
        CLOSE xwcv_sum_gr_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_gl_if_gr_comp;
--
  /**********************************************************************************
   * Procedure Name   : ins_xwcv_bk
   * Description      : 在庫受払表（Ｇ会社）テーブルの作成 (A-12)
   ***********************************************************************************/
  PROCEDURE ins_xwcv_bk(
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_xwcv_bk'; -- プログラム名
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 在庫受払表（Ｇ会社）テーブル登録
    INSERT INTO xxcoi_inv_recept_g_company(
            company_code                                                   -- 01.会社コード
          , grcp_adj_dept_code                                             -- 02.計上拠点
          , transaction_date                                               -- 03.取引日
          , item_code                                                      -- 04.品目コード
          , subinventory_code                                              -- 05.保管場所
          , quantity                                                       -- 06.数量
          , purchase_unit_price                                            -- 07.購入単価
          , purchase_amount                                                -- 08.購入金額
          , transaction_type_name                                          -- 09.取引タイプ名
          , slip_number                                                    -- 10.伝票番号
          , transfer_ownership_flg                                         -- 11.所有権移転取引フラグ
          , transfer_subinventory                                          -- 12.移動元保管場所
          , sales_base_code                                                -- 13.売上拠点
          , standard_cost                                                  -- 14.元標準原価
          , created_by                                                     -- 15.作成者
          , creation_date                                                  -- 16.作成日
          , last_updated_by                                                -- 17.最終更新者
          , last_update_date                                               -- 18.最終更新日
          , last_update_login                                              -- 19.最終更新ログイン
          , request_id                                                     -- 20.要求ID
          , program_application_id                                         -- 21.コンカレント・プログラム・アプリケーションID
          , program_id                                                     -- 22.コンカレント・プログラムID
          , program_update_date                                            -- 23.プログラム更新日
    )
    SELECT
            xwcv.company_code                   AS company_code            -- 01.会社コード
          , xwcv.grcp_adj_dept_code             AS grcp_adj_dept_code      -- 02.計上拠点
          , mmt.transaction_date                AS transaction_date        -- 03.取引日
          , msib.segment1                       AS segment1                -- 04.品目コード
          , mmt.subinventory_code               AS subinventory_code       -- 05.保管場所
          , xwcv.primary_quantity               AS transaction_quantity    -- 06.数量
          , ROUND( xwcv.standard_cost * ( 1 + ( flv.attribute1 / 100 )),2)
                                                AS purchase_unit_price     -- 07.購入単価
          , ROUND( xwcv.primary_quantity *
            ROUND( xwcv.standard_cost * ( 1 + ( flv.attribute1 / 100 )),2),2)
                                                AS purchase_amount         -- 08.購入金額
          , mtt.transaction_type_name           AS transaction_type_name   -- 09.取引タイプ名
          , mmt.attribute1                      AS attribute1              -- 10.伝票番号
          , xwcv.transfer_ownership_flg         AS transfer_ownership_flg  -- 11.所有権移転取引フラグ
          , mmt.transfer_subinventory           AS transfer_subinventory   -- 12.移動元保管場所
          , NULL                                AS sales_base_code         -- 13.売上拠点
          , xwcv.standard_cost                  AS standard_cost           -- 14.元標準原価
          , cn_created_by                       AS created_by              -- 15.作成者
          , SYSDATE                             AS creation_date           -- 16.作成日
          , cn_last_updated_by                  AS last_updated_by         -- 17.最終更新者
          , SYSDATE                             AS last_update_date        -- 18.最終更新日
          , cn_last_update_login                AS last_update_login       -- 19.最終更新ログイン
          , cn_request_id                       AS request_id              -- 20.要求ID
          , cn_program_application_id           AS program_application_id  -- 21.コンカレント・プログラム・アプリケーションID
          , cn_program_id                       AS program_id              -- 22.コンカレント・プログラムID
          , SYSDATE                             AS program_update_date     -- 23.プログラム更新日
    FROM    xxcoi_wk_cost_variance    xwcv     -- 原価差額ワークテーブル
          , mtl_material_transactions mmt      -- 資材取引
          , mtl_system_items_b        msib     -- Disc品目マスタ
          , mtl_transaction_types     mtt      -- 取引タイプマスタ
          , xxcfr_bd_company_info_v   flv      -- 各社利益率
    WHERE   xwcv.group_company_flg   = cv_1                                -- 1:グループ会社
    AND     xwcv.reverse_flg         = cv_0                                -- 0:元データ
    AND     xwcv.account_code        IN ( gt_aff3_seihin,gt_aff3_shouhin ) -- （12204：製品、12109：商品）
    AND     xwcv.transaction_id      = mmt.transaction_id                  -- 取引ID
    AND     msib.inventory_item_id   = mmt.inventory_item_id
    AND     msib.organization_id     = mmt.organization_id
    AND     mtt.transaction_type_id  = xwcv.transaction_type_id
    AND     mmt.organization_id      = xxcoi_common_pkg.get_organization_id ( gt_org_code )
    AND     flv.lookup_type          = cv_company_profit_rate
    AND     flv.company_code         = xwcv.company_code
      AND     TRUNC( xwcv.transaction_date )  BETWEEN NVL( flv.start_date_active, xwcv.transaction_date )
                                           AND     NVL( flv.end_date_active, xwcv.transaction_date )
    AND     xwcv.transaction_type_id <> gt_trans_type_std_cost_upd  -- 標準原価更新は除く
    ;
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
  END ins_xwcv_bk;
--
  /**********************************************************************************
   * Procedure Name   : ins_gl_if_round_Journal
   * Description      : 丸め誤差GL-IF登録 (A-13)
   ***********************************************************************************/
  PROCEDURE ins_gl_if_round_Journal(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_gl_if_round_Journal'; -- プログラム名
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
    cv_flag_n            CONSTANT VARCHAR2(1) := 'N';           -- フラグ値：N
    cv_status_new        CONSTANT VARCHAR2(3) := 'NEW';         -- 固定値：NEW
    cv_code_jpy          CONSTANT VARCHAR2(3) := 'JPY';         -- 固定値：JPY
    cv_flag_a            CONSTANT VARCHAR2(1) := 'A';           -- 固定値：A
    cv_yyyymm            CONSTANT VARCHAR2(7) := 'YYYY/MM';     -- 固定値：YYYY/MM
--
    -- *** ローカル変数 ***
    lt_entered_dr        gl_interface.entered_dr%TYPE;    -- 借方金額
    lt_entered_cr        gl_interface.entered_cr%TYPE;    -- 貸方金額
    lt_segment2          gl_interface.segment2%TYPE;      -- 部門
    lt_segment3          gl_interface.segment3%TYPE;      -- 勘定科目
    lt_segment4          gl_interface.segment4%TYPE;      -- 補助科目
--
    -- ===============================
    -- 丸め誤差情報の抽出
    -- ===============================
    -- 丸め誤差情報カーソル
    CURSOR gl_if_round_cur
    IS
      SELECT
              gi.segment1               AS company_code,          -- 会社
              gi.user_je_category_name  AS user_je_category_name, -- 仕訳カテゴリ名
              gi.period_name            AS period_name,           -- 会計期間名
              gi.reference21            AS gl_batch_id,           -- GLバッチID
              MAX( gi.accounting_date ) AS max_accounting_date,   -- 仕訳有効日付
              SUM( gi.entered_dr ) - SUM( gi.entered_cr )
                                        AS sum_adjustment_amount  -- 合計貸借差額
      FROM    gl_interface   gi
      WHERE   gi.user_je_category_name IN (gt_je_category_name_inv_gr,gt_je_category_name_inv_cost)
      AND     gi.user_je_source_name   = gt_je_category_name_inv_cost
      GROUP BY gi.segment1,
               gi.user_je_category_name,
               gi.period_name,
               gi.reference21
      ;
    -- 丸め誤差情報カーソル レコード型
    gl_if_round_rec gl_if_round_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================
    -- GLインターフェース格納
    -- ===============================
    OPEN gl_if_round_cur;
    LOOP
      FETCH gl_if_round_cur INTO gl_if_round_rec;
      EXIT WHEN gl_if_round_cur%NOTFOUND;
--
      IF ( gl_if_round_rec.sum_adjustment_amount = 0) THEN
        NULL;
      ELSE
        -- 初期化
        lt_segment2        := NULL;  -- 部門コード
        lt_entered_dr      := NULL;  -- 借方金額
        lt_entered_cr      := NULL;  -- 貸方金額
--
        -- 部門コード取得
        SELECT flv.attribute3
        INTO   lt_segment2
        FROM   fnd_lookup_values   flv
        WHERE  flv.lookup_type   = cv_conv_dept_code
        AND    flv.attribute1    = gl_if_round_rec.company_code
        AND    flv.attribute2    = gt_aff2_adj_dept_code        -- 調整部門
        AND    flv.language      = USERENV( 'LANG' );
--
        -- 合計貸借差額が－なら借方金額にセット
        IF ( gl_if_round_rec.sum_adjustment_amount * -1 ) > 0 THEN
          lt_entered_dr := ABS( gl_if_round_rec.sum_adjustment_amount );
        -- 合計貸借差額が＋なら貸方金額にセット
        ELSE
          lt_entered_cr := ABS( gl_if_round_rec.sum_adjustment_amount );
        END IF;
--
        -- ===============================
        -- GL-IF登録処理（丸め誤差）
        -- ===============================
        ins_gl_if_reg(
            id_accounting_date       => gl_if_round_rec.max_accounting_date,       -- 仕訳有効日付
            iv_segment1              => gl_if_round_rec.company_code,              -- 会社コード
            iv_segment2              => lt_segment2,                               -- 部門コード
            iv_segment3              => gt_aff3_rounding_error,                    -- 勘定科目コード
            iv_segment4              => gt_aff4_rounding_error,                    -- 補助科目コード
            in_entered_dr            => lt_entered_dr,                             -- 借方金額
            in_entered_cr            => lt_entered_cr,                             -- 貸方金額
            iv_reference21           => gl_if_round_rec.gl_batch_id,               -- GLバッチID
            iv_period_name           => gl_if_round_rec.period_name,               -- 会計期間名
            iv_user_je_category_name => gl_if_round_rec.user_je_category_name,     -- 仕訳カテゴリ名
            ov_errbuf                => lv_errbuf   -- エラー・メッセージ
          , ov_retcode               => lv_retcode  -- リターン・コード
          , ov_errmsg                => lv_errmsg   -- ユーザー・エラー・メッセージ
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
    END LOOP;
    CLOSE gl_if_round_cur;
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
      -- カーソルがオープンしていたらクローズ
      IF ( gl_if_round_cur%ISOPEN ) THEN
        CLOSE gl_if_round_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_gl_if_round_Journal;
--
-- Ver1.10 ADD END
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
-- == 2009/07/14 V1.4 Added START ===============================================================
    iv_effective_date  IN VARCHAR2, -- 記帳日
-- == 2009/07/14 V1.4 Added END   ===============================================================
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    ln_mtl_txn_acct_cnt  NUMBER DEFAULT 0;  -- 取得件数：資材配賦情報
    ln_standard_cost     NUMBER DEFAULT 0;  -- 標準原価
    ln_operation_cost    NUMBER DEFAULT 0;  -- 営業原価
    ln_cost_variance     NUMBER DEFAULT 0;  -- 原価差額
    lv_status            VARCHAR2(1);       -- ステータス
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
    gn_target_cnt     := 0; -- 対象件数  (資材配賦情報単位)
    gn_normal_cnt     := 0; -- 成功件数  (資材配賦情報単位)
    gn_error_cnt      := 0; -- エラー件数(資材配賦情報単位)
    gn_target_sum_cnt := 0; -- 対象件数  (原価差額集約単位)
    gn_normal_sum_cnt := 0; -- 成功件数  (原価差額集約単位)
    gn_error_sum_cnt  := 0; -- エラー件数(原価差額集約単位)
-- Ver1.10 ADD START
    gn_target_sum_cnt_gr := 0; -- 対象件数  (グループ会社集約単位)
    gn_error_sum_cnt_gr  := 0; -- エラー件数(グループ会社集約単位)
-- Ver1.10 ADD END
--
    -- ===============================
    -- 初期処理 (A-1)
    -- ===============================
    init(
-- == 2009/07/14 V1.4 Added START ===============================================================
        iv_effective_date  => iv_effective_date   -- 記帳日
-- == 2009/07/14 V1.4 Added END   ===============================================================
      , ov_errbuf       => lv_errbuf        -- エラー・メッセージ
      , ov_retcode      => lv_retcode       -- リターン・コード
      , ov_errmsg       => lv_errmsg        -- ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
-- == 2009/09/28 V1.8 Deleted START ===============================================================
--    -- ===============================
--    -- 資材配賦情報の抽出 (A-2)
--    -- ===============================
--    get_mtl_txn_acct(
--        on_mtl_txn_acct_cnt => ln_mtl_txn_acct_cnt -- 取得件数
--      , ov_errbuf           => lv_errbuf           -- エラー・メッセージ
--      , ov_retcode          => lv_retcode          -- リターン・コード
--      , ov_errmsg           => lv_errmsg           -- ユーザー・エラー・メッセージ
--    );
--    IF ( lv_retcode = cv_status_error ) THEN
--      RAISE global_process_expt;
--    END IF;
--    -- 取得件数0件の場合
--    IF ( ln_mtl_txn_acct_cnt = 0 ) THEN
--      -- 対象データ無しメッセージ出力
--      gv_out_msg  := xxccp_common_pkg.get_msg(
--                         iv_application  => cv_appl_short_name_xxcoi
--                       , iv_name         => cv_msg_no_data
--                     );
--      FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT
--        , buff   => gv_out_msg
--      );
--      RETURN;
--    END IF;
--    -- 対象件数セット(資材配賦情報単位)
--    gn_target_cnt := ln_mtl_txn_acct_cnt;
-- == 2009/09/28 V1.8 Deleted END   ===============================================================
--
    -- =============================================
    -- 原価差額ワークテーブルの前回データ削除 (A-3)
    -- =============================================
    del_xwcv_last_data(
        ov_errbuf   => lv_errbuf   -- エラー・メッセージ
      , ov_retcode  => lv_retcode  -- リターン・コード
      , ov_errmsg   => lv_errmsg   -- ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
-- == 2009/09/28 V1.8 Modified START ===============================================================
--    <<loop_1>>  -- 原価差額情報格納ループ
--    FOR i IN 1 .. ln_mtl_txn_acct_cnt LOOP
--      -- 初期化
--      gn_mtl_txn_acct_cnt := i;                -- PL/SQL表インデックス
--
    OPEN  mtl_txn_acct_cur;
    <<loop_1>>
    LOOP
      FETCH mtl_txn_acct_cur  INTO  mtl_txn_acct_rec;
      EXIT WHEN mtl_txn_acct_cur%NOTFOUND;
      --
      -- 対象件数セット(資材配賦情報単位)
      gn_target_cnt := gn_target_cnt + 1;
-- == 2009/09/28 V1.8 Modified END   ===============================================================
      lv_status           := cv_normal_record; -- ステータス：正常
--
      -- ===============================
      -- 原価情報取得処理 (A-4)
      -- ===============================
      get_cost_info(
          ion_standard_cost  => ln_standard_cost  -- 標準原価
        , ion_operation_cost => ln_operation_cost -- 営業原価
        , ion_cost_variance  => ln_cost_variance  -- 原価差額
-- == 2009/09/28 V1.8 Added START ===============================================================
        , ir_txn_acct_rec    => mtl_txn_acct_rec  -- 資材配賦情報
-- == 2009/09/28 V1.8 Added END   ===============================================================
        , ov_errbuf          => lv_errbuf         -- エラー・メッセージ
        , ov_retcode         => lv_retcode        -- リターン・コード
        , ov_errmsg          => lv_errmsg         -- ユーザー・エラー・メッセージ
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      -- リターン・コードが警告の場合、ステータスにNセット
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        lv_status := cv_error_record;
      END IF;
--
      -- ===================================
      -- 原価差額ワークテーブルの作成 (A-5)
      -- ===================================
      ins_xwcv(
          in_standard_cost  => ln_standard_cost  -- 標準原価
        , in_operation_cost => ln_operation_cost -- 営業原価
        , in_cost_variance  => ln_cost_variance  -- 原価差額
        , iv_status         => lv_status         -- ステータス
-- == 2009/09/28 V1.8 Added START ===============================================================
        , ir_txn_acct_rec   => mtl_txn_acct_rec  -- 資材配賦情報
-- == 2009/09/28 V1.8 Added END   ===============================================================
        , ov_errbuf         => lv_errbuf         -- エラー・メッセージ
        , ov_retcode        => lv_retcode        -- リターン・コード
        , ov_errmsg         => lv_errmsg         -- ユーザー・エラー・メッセージ
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      ELSE
        -- エラーデータ登録 エラー件数(資材配賦情報単位)カウント
        IF ( lv_status = cv_error_record ) THEN
          gn_error_cnt := gn_error_cnt + 1;
        -- 正常データ登録   成功件数(資材配賦情報単位)カウント
        ELSE
          gn_normal_cnt := gn_normal_cnt + 1;
        END IF;
      END IF;
    END LOOP loop_1;
--
-- == 2009/09/28 V1.8 Added START ===============================================================
    IF ( gn_target_cnt = 0 ) THEN
      -- 対象データ無しメッセージ出力
      gv_out_msg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name_xxcoi
                       , iv_name         => cv_msg_no_data
                     );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => gv_out_msg
      );
      RETURN;
    END IF;
-- == 2009/09/28 V1.8 Added END   ===============================================================
-- Ver1.10 ADD START
    -- ===================================================
    -- 棚卸資産情報GL-IF登録(グループ会社) (A-10)
    -- ===================================================
    ins_gl_if_gr_comp(
        ov_errbuf   => lv_errbuf   -- エラー・メッセージ
      , ov_retcode  => lv_retcode  -- リターン・コード
      , ov_errmsg   => lv_errmsg   -- ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
-- Ver1.10 ADD END
    -- =======================================
    -- 原価差額情報GL-IF登録 (A-6、A-7、A-8)
    -- =======================================
    ins_gl_if(
        ov_errbuf   => lv_errbuf   -- エラー・メッセージ
      , ov_retcode  => lv_retcode  -- リターン・コード
      , ov_errmsg   => lv_errmsg   -- ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 資材配賦情報単位もしくは原価差額集約単位で1件でもエラーがあった場合
    IF gn_error_cnt > 0 OR gn_error_sum_cnt > 0 THEN
      -- 終了ステータスに警告セット
      ov_retcode := cv_status_warn;
    END IF;
-- Ver1.10 ADD START
    -- ===================================================
    -- 在庫受払表（Ｇ会社）テーブルの作成 (A-12)
    -- ===================================================
    ins_xwcv_bk(
        ov_errbuf   => lv_errbuf   -- エラー・メッセージ
      , ov_retcode  => lv_retcode  -- リターン・コード
      , ov_errmsg   => lv_errmsg   -- ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===================================================
    -- 丸め誤差GL-IF登録 (A-13)
    -- ===================================================
    ins_gl_if_round_Journal(
        ov_errbuf   => lv_errbuf   -- エラー・メッセージ
      , ov_retcode  => lv_retcode  -- リターン・コード
      , ov_errmsg   => lv_errmsg   -- ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
-- Ver1.10 ADD END
--
  EXCEPTION
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
      errbuf          OUT VARCHAR2     --  エラーメッセージ #固定#
    , retcode         OUT VARCHAR2     --  エラーコード     #固定#
-- == 2009/07/14 V1.4 Added START ===============================================================
    , iv_effective_date  IN  VARCHAR2  --  記帳日
-- == 2009/07/14 V1.4 Added END   ===============================================================
  )
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
      , ov_errbuf  => lv_errbuf
      , ov_errmsg  => lv_errmsg
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
-- == 2009/07/14 V1.4 Added START ===============================================================
        iv_effective_date  => iv_effective_date   --  記帳日
-- == 2009/07/14 V1.4 Added END   ===============================================================
      , ov_errbuf       => lv_errbuf        -- エラー・メッセージ           --# 固定 #
      , ov_retcode      => lv_retcode       -- リターン・コード             --# 固定 #
      , ov_errmsg       => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- ステータス：異常
    IF ( lv_retcode = cv_status_error ) THEN
      -- 件数セット
      gn_target_cnt     := 0;
      gn_normal_cnt     := 0;
      gn_error_cnt      := 1;
      gn_target_sum_cnt := 0;
      gn_normal_sum_cnt := 0;
      gn_error_sum_cnt  := 0;
-- Ver1.10 ADD START
      gn_target_sum_cnt_gr := 0;
      gn_error_sum_cnt_gr  := 0;
-- Ver1.10 ADD END
      -- エラー出力
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_errmsg -- ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_errbuf -- エラーメッセージ
      );
    END IF;
    -- 空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
    -- 資材配賦情報単位件数メッセージ
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appl_short_name_xxcoi
                , iv_name         => cv_msg_unit_mtl_txn_acct
              );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --対象件数出力(資材配賦情報単位)
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --成功件数出力(資材配賦情報単位)
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --エラー件数出力(資材配賦情報単位)
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- 原価差額集約単位件数メッセージ
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appl_short_name_xxcoi
                , iv_name         => cv_msg_unit_cost_sum
              );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --対象件数出力(原価差額集約単位)
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_target_sum_cnt)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --成功件数出力(原価差額集約単位)
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_normal_sum_cnt)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --エラー件数出力(原価差額集約単位)
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_error_sum_cnt)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
--
-- Ver1.10 ADD START
    -- グループ会社集約単位件数メッセージ
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appl_short_name_xxcoi
                , iv_name         => cv_msg_code_xxcoi_10751
              );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --対象件数出力(棚卸資産集約単位)
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_target_sum_cnt_gr)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --成功件数出力(棚卸資産集約単位)
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_target_sum_cnt_gr)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --エラー件数出力(棚卸資産集約単位)
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_error_sum_cnt_gr)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
-- Ver1.10 ADD END
    -- 空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
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
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
-- == 2009/09/28 V1.8 Modified START ===============================================================
--    IF (retcode = cv_status_error) THEN
--      ROLLBACK;
--    END IF;
    IF (   (retcode = cv_status_error)
        OR (gn_target_cnt = 0)
       )
    THEN
      ROLLBACK;
    END IF;
-- == 2009/09/28 V1.8 Modified END   ===============================================================
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
END XXCOI007A01C;
/
