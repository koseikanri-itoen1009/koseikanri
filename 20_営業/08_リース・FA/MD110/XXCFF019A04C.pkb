CREATE OR REPLACE PACKAGE BODY XXCFF019A04C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * Package Name     : XXCFF019A04C(body)
 * Description      : IFRS台帳修正
 * MD.050           : MD050_CFF_019_A04_IFRS台帳修正
 * Version          : 1.2
 *
 * Program List
 * ----------------------------- ----------------------------------------------------------
 *  Name                          Description
 * ----------------------------- ----------------------------------------------------------
 *  init                          初期処理                                  (A-1)
 *  get_profile_values            プロファイル取得                          (A-2)
 *  chk_period                    会計期間チェック                          (A-3)
 *  get_exec_date                 前回実行日時取得                          (A-4)
 *  get_ifrs_adj_data             IFRS台帳修正データ抽出・登録              (A-5)
 *  upd_exec_date                 実行日時更新                              (A-6)
 *  submain                       メイン処理プロシージャ
 *  main                          コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2017/11/30    1.0   SCSK小路         新規作成
 *  2018/04/27    1.1   SCSK森           E_本稼動_15041対応
 *  2018/12/14    1.2   SCSK小路         E_本稼動_15399対応
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
  --*** 会計期間チェックエラー
  chk_period_expt           EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  data_lock_expt            EXCEPTION;        -- レコードロックエラー
  PRAGMA EXCEPTION_INIT(data_lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100):= 'XXCFF019A04C'; -- パッケージ名
--
  -- ***アプリケーション短縮名
  cv_msg_kbn_cff            CONSTANT VARCHAR2(5)  := 'XXCFF';
--
  -- ***メッセージ名(本文)
  cv_msg_cff_00007          CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00007'; -- ロックエラー
  cv_msg_cff_00020          CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00020'; -- プロファイル取得エラー
  cv_msg_cff_00037          CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00037'; -- 会計期間チェックエラー
  cv_msg_cff_00165          CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00165'; -- 取得対象データ無しメッセージ
  cv_msg_cff_00267          CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00267'; -- 修正OIF登録メッセージ
  cv_msg_cff_00275          CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00275'; -- IFRS台帳修正登録エラー
  cv_msg_cff_00276          CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00276'; -- IFRS台帳修正スキップメッセージ
  cv_msg_cff_00281          CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00281'; -- 償却方法取得エラー
  -- ***メッセージ名(トークン)
  cv_msg_cff_50097          CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50097'; -- 償却方法
  cv_msg_cff_50228          CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50228'; -- XXCFF:台帳種類_固定資産台帳
  cv_msg_cff_50236          CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50236'; -- 固定資産（修正）情報
  cv_msg_cff_50314          CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50314'; -- XXCFF:台帳種類_IFRS台帳
  cv_msg_cff_50316          CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50316'; -- IFRS台帳連携セット
--
  -- ***トークン名
  cv_tkn_prof               CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_asset_number1      CONSTANT VARCHAR2(20) := 'ASSET_NUMBER1';
  cv_tkn_asset_number2      CONSTANT VARCHAR2(20) := 'ASSET_NUMBER2';
  cv_tkn_bk_type            CONSTANT VARCHAR2(20) := 'BOOK_TYPE_CODE';
  cv_tkn_period             CONSTANT VARCHAR2(20) := 'PERIOD_NAME';
  cv_tkn_get_data           CONSTANT VARCHAR2(20) := 'GET_DATA';
  cv_tkn_table_name         CONSTANT VARCHAR2(20) := 'TABLE_NAME';
  cv_tkn_category           CONSTANT VARCHAR2(20) := 'CATEGORY';
--
  -- ***プロファイル
  cv_fixed_asset_register   CONSTANT VARCHAR2(30) := 'XXCFF1_FIXED_ASSET_REGISTER';       -- 台帳種類_固定資産台帳
  cv_fixed_ifrs_asset_regi  CONSTANT VARCHAR2(35) := 'XXCFF1_FIXED_IFRS_ASSET_REGISTER';  -- 台帳種類_IFRS台帳
--
  -- ***ファイル出力
  cv_file_type_out          CONSTANT VARCHAR2(10) := 'OUTPUT'; -- メッセージ出力
  cv_file_type_log          CONSTANT VARCHAR2(10) := 'LOG';    -- ログ出力
--
  cv_yes                    CONSTANT VARCHAR2(1)  := 'Y';
-- 2018/12/14 1.2 ADD Y.Shoji START
  cv_no                     CONSTANT VARCHAR2(1)  := 'N';
-- 2018/12/14 1.2 ADD Y.Shoji END
  cv_space                  CONSTANT VARCHAR2(1)  := ' ';      -- スペース
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- ***バルクフェッチ用定義
  -- IFRS台帳修正対象データレコード型
  TYPE g_ifrs_adj_rtype IS RECORD(
     asset_id                      fa_additions_b.asset_id%TYPE                  -- 資産ID
    ,asset_number_fixed            fa_additions_b.asset_number%TYPE              -- 資産番号（固定資産台帳）
    ,asset_number_ifrs             fa_additions_b.asset_number%TYPE              -- 資産番号（IFRS台帳）
    ,date_placed_in_service_ifrs   fa_books.date_placed_in_service%TYPE          -- 事業供用日（IFRS台帳）
    ,asset_category_id_ifrs        fa_additions_b.asset_category_id%TYPE         -- 資産カテゴリID（IFRS台帳）
    ,category_code_ifrs            fa_additions_b.attribute_category_code%TYPE   -- 資産カテゴリコード（IFRS台帳）
    ,date_placed_in_service_fixed  fa_books.date_placed_in_service%TYPE          -- 事業供用日（固定資産台帳）
    ,description_fixed             fa_additions_tl.description%TYPE              -- 摘要（固定資産台帳）
    ,description_ifrs              fa_additions_tl.description%TYPE              -- 摘要（IFRS台帳）
    ,current_units                 fa_additions_b.current_units%TYPE             -- 単位
    ,cost_fixed                    fa_books.cost%TYPE                            -- 取得価額（固定資産台帳）
    ,cost_ifrs                     fa_books.cost%TYPE                            -- 取得価額（IFRS台帳）
    ,original_cost                 fa_books.original_cost%TYPE                   -- 当初取得価額
    ,tag_number                    fa_additions_b.tag_number%TYPE                -- 現品票番号
    ,serial_number                 fa_additions_b.serial_number%TYPE             -- シリアル番号
    ,asset_key_ccid                fa_additions_b.asset_key_ccid%TYPE            -- 資産キーCCID
    ,key_segment1                  fa_asset_keywords.segment1%TYPE               -- 資産キーセグメント1
    ,key_segment2                  fa_asset_keywords.segment2%TYPE               -- 資産キーセグメント2
    ,parent_asset_id               fa_additions_b.parent_asset_id%TYPE           -- 親資産ID
    ,lease_id                      fa_additions_b.lease_id%TYPE                  -- リースID
    ,model_number                  fa_additions_b.model_number%TYPE              -- モデル
    ,in_use_flag                   fa_additions_b.in_use_flag%TYPE               -- 使用状況
    ,inventorial                   fa_additions_b.inventorial%TYPE               -- 実地棚卸フラグ
    ,owned_leased                  fa_additions_b.owned_leased%TYPE              -- 所有権
    ,new_used                      fa_additions_b.new_used%TYPE                  -- 新品/中古
    ,attribute1                    fa_additions_b.attribute1%TYPE                -- カテゴリDFF1
    ,attribute2_ifrs               fa_additions_b.attribute2%TYPE                -- 取得日（IFRS台帳）
    ,attribute3                    fa_additions_b.attribute3%TYPE                -- カテゴリDFF3
    ,attribute4                    fa_additions_b.attribute4%TYPE                -- カテゴリDFF4
    ,attribute5                    fa_additions_b.attribute5%TYPE                -- カテゴリDFF5
    ,attribute6                    fa_additions_b.attribute6%TYPE                -- カテゴリDFF6
    ,attribute7                    fa_additions_b.attribute7%TYPE                -- カテゴリDFF7
    ,attribute8                    fa_additions_b.attribute8%TYPE                -- カテゴリDFF8
    ,attribute9                    fa_additions_b.attribute9%TYPE                -- カテゴリDFF9
    ,attribute10                   fa_additions_b.attribute10%TYPE               -- カテゴリDFF10
    ,attribute11                   fa_additions_b.attribute11%TYPE               -- カテゴリDFF11
    ,attribute12                   fa_additions_b.attribute12%TYPE               -- カテゴリDFF12
    ,attribute13                   fa_additions_b.attribute13%TYPE               -- カテゴリDFF13
    ,attribute14                   fa_additions_b.attribute14%TYPE               -- カテゴリDFF14
    ,attribute15_ifrs              fa_additions_b.attribute15%TYPE               -- IFRS耐用年数（IFRS台帳）
    ,attribute16_ifrs              fa_additions_b.attribute16%TYPE               -- IFRS償却（IFRS台帳）
    ,attribute17_ifrs              fa_additions_b.attribute17%TYPE               -- 不動産取得税（IFRS台帳）
    ,attribute18_ifrs              fa_additions_b.attribute18%TYPE               -- 借入コスト（IFRS台帳）
    ,attribute19_ifrs              fa_additions_b.attribute19%TYPE               -- その他（IFRS台帳）
    ,attribute20_ifrs              fa_additions_b.attribute20%TYPE               -- IFRS資産科目（IFRS台帳）
    ,attribute21_ifrs              fa_additions_b.attribute21%TYPE               -- 修正年月日（IFRS台帳）
    ,attribute22                   fa_additions_b.attribute22%TYPE               -- カテゴリDFF22
    ,attribute23                   fa_additions_b.attribute23%TYPE               -- カテゴリDFF23
    ,attribute24                   fa_additions_b.attribute24%TYPE               -- カテゴリDFF24
    ,attribute25                   fa_additions_b.attribute25%TYPE               -- カテゴリDFF27
    ,attribute26                   fa_additions_b.attribute26%TYPE               -- カテゴリDFF25
    ,attribute27                   fa_additions_b.attribute27%TYPE               -- カテゴリDFF26
    ,attribute28                   fa_additions_b.attribute28%TYPE               -- カテゴリDFF28
    ,attribute29                   fa_additions_b.attribute29%TYPE               -- カテゴリDFF29
    ,attribute30                   fa_additions_b.attribute30%TYPE               -- カテゴリDFF30
    ,salvage_value                 fa_books.salvage_value%TYPE                   -- 残存価額
    ,percent_salvage_value         fa_books.percent_salvage_value%TYPE           -- 残存価額%
    ,allowed_deprn_limit_amount    fa_books.allowed_deprn_limit_amount%TYPE      -- 償却限度額
    ,allowed_deprn_limit           fa_books.allowed_deprn_limit%TYPE             -- 償却限度率
    ,depreciate_flag               fa_books.depreciate_flag%TYPE                 -- 償却費計上フラグ
    ,deprn_method_code             fa_books.deprn_method_code%TYPE               -- 償却方法
    ,basic_rate                    fa_books.basic_rate%TYPE                      -- 普通償却率
    ,adjusted_rate                 fa_books.adjusted_rate%TYPE                   -- 割増後償却率
    ,life_in_months                fa_books.life_in_months%TYPE                  -- 耐用年数+月数
    ,bonus_rule                    fa_books.bonus_rule%TYPE                      -- ボーナスルール
    ,cat_segment1                  fa_categories.segment1%TYPE                   -- 資産カテゴリ-種類（IFRS台帳）
    ,cat_segment2                  fa_categories.segment2%TYPE                   -- 資産カテゴリ-申告償却（IFRS台帳）
    ,cat_segment3                  fa_categories.segment3%TYPE                   -- 資産カテゴリ-資産勘定（IFRS台帳）
    ,cat_segment4                  fa_categories.segment4%TYPE                   -- 資産カテゴリ-償却科目（IFRS台帳）
    ,cat_segment5                  fa_categories.segment5%TYPE                   -- 資産カテゴリ-耐用年数（IFRS台帳）
    ,cat_segment6                  fa_categories.segment6%TYPE                   -- 資産カテゴリ-償却方法（IFRS台帳）
    ,cat_segment7                  fa_categories.segment7%TYPE                   -- 資産カテゴリ-リース種別（IFRS台帳）
    ,attribute2_fixed              fa_additions_b.attribute2%TYPE                -- 取得日（固定資産台帳）
    ,attribute15_fixed             fa_additions_b.attribute15%TYPE               -- IFRS耐用年数（固定資産台帳）
    ,attribute16_fixed             fa_additions_b.attribute16%TYPE               -- IFRS償却（固定資産台帳）
    ,attribute17_fixed             fa_additions_b.attribute17%TYPE               -- 不動産取得税（固定資産台帳）
    ,attribute18_fixed             fa_additions_b.attribute18%TYPE               -- 借入コスト（固定資産台帳）
    ,attribute19_fixed             fa_additions_b.attribute19%TYPE               -- その他（固定資産台帳）
    ,attribute20_fixed             fa_additions_b.attribute20%TYPE               -- IFRS資産科目（固定資産台帳）
    ,attribute21_fixed             fa_additions_b.attribute21%TYPE               -- 修正年月日（固定資産台帳）
-- 2018/12/14 1.2 ADD Y.Shoji START
    ,amortized_flag                xx01_adjustment_oif.amortized_flag%TYPE             -- 修正額償却フラグ
    ,amortization_start_date       fa_transaction_headers.amortization_start_date%TYPE -- 償却開始日
-- 2018/12/14 1.2 ADD Y.Shoji END
  );
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- ***バルクフェッチ用定義
  -- IFRS台帳修正対象データレコード配列
  TYPE g_ifrs_adj_ttype IS TABLE OF g_ifrs_adj_rtype
  INDEX BY BINARY_INTEGER;
--
  g_ifrs_adj_tab            g_ifrs_adj_ttype;  -- IFRS台帳修正対象データ
--
  -- パラメータ会計期間名
  gv_period_name            VARCHAR2(100);
--
  -- 前回実行日時
  gt_exec_date              xxcff_ifrs_sets.exec_date%TYPE;
--
  -- ***プロファイル値
  gv_fixed_asset_register   VARCHAR2(100);  -- 台帳種類_固定資産台帳
  gv_fixed_ifrs_asset_regi  VARCHAR2(100);  -- 台帳種類_IFRS台帳
--
  -- ***処理件数
  -- IFRS台帳一括追加処理における件数
  gn_loop_cnt               NUMBER;     -- 処理中件数
  gn_target_cnt             NUMBER;     -- 対象件数
  gn_normal_cnt             NUMBER;     -- 正常件数
  gn_skip_cnt               NUMBER;     -- スキップ件数
  gn_err_cnt                NUMBER;     -- エラー件数
--
  /**********************************************************************************
   * Procedure Name   : upd_exec_date
   * Description      : 実行日時更新(A-6)
   ***********************************************************************************/
  PROCEDURE upd_exec_date(
    ov_errbuf      OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg      OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_exec_date'; -- プログラム名
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
    UPDATE xxcff_ifrs_sets  xis       -- IFRS台帳連携セット
    SET    xis.exec_date              = cd_last_update_date         -- 実行日時
          ,xis.last_updated_by        = cn_last_updated_by          -- 最終更新者
          ,xis.last_update_date       = cd_last_update_date         -- 最終更新日
          ,xis.last_update_login      = cn_last_update_login        -- 最終更新ログインID
          ,xis.request_id             = cn_request_id               -- 要求ID
          ,xis.program_application_id = cn_program_application_id   -- コンカレント・プログラム・アプリケーションID
          ,xis.program_id             = cn_program_id               -- コンカレント・プログラムID
          ,xis.program_update_date    = cd_program_update_date      -- プログラム更新日
    WHERE  xis.exec_id                = cv_pkg_name                 -- 処理ID
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
  END upd_exec_date;
--
  /**********************************************************************************
   * Procedure Name   : get_ifrs_adj_data
   * Description      : IFRS台帳修正データ抽出・登録(A-5)
   ***********************************************************************************/
  PROCEDURE get_ifrs_adj_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name           CONSTANT VARCHAR2(100) := 'get_ifrs_adj_data';    -- プログラム名
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
    cv_value_zero       CONSTANT VARCHAR2(1)  := '0';          -- 文字型のゼロ
    cv_lang             CONSTANT fa_additions_tl.language%TYPE := USERENV( 'LANG' );      -- 言語
    cv_tran_type_adj    CONSTANT VARCHAR2(10) := 'ADJUSTMENT'; -- 取引タイプコード(調整)
    cv_format_yyyymm    CONSTANT VARCHAR2(7)  := 'YYYY-MM';    -- 日付形式：YYYY-MM
    cv_status_pending   CONSTANT VARCHAR2(7)  := 'PENDING';    -- ステータス：PENDING
    cv_haifun           CONSTANT VARCHAR2(1)  := '-';          -- ハイフン
--
    -- *** ローカル変数 ***
    ld_start_date         DATE;                                                   -- 会計期間開始年月日
    ld_end_date           DATE;                                                   -- 会計期間終了年月日
    ld_dpis_date          DATE;                                                   -- 事業基準日
    lt_segment1           fa_categories.segment1%TYPE;                            -- 種類
    lt_segment2           fa_categories.segment2%TYPE;                            -- 申告償却
    lt_segment3           fa_categories.segment3%TYPE;                            -- 資産勘定
    lt_segment4           fa_categories.segment4%TYPE;                            -- 償却科目
    lt_segment5           fa_categories.segment5%TYPE;                            -- 耐用年数
    lt_segment6           fa_categories.segment6%TYPE;                            -- 償却方法
    lt_segment7           fa_categories.segment7%TYPE;                            -- リース種別
    lt_asset_category_id  xx01_adjustment_oif.category_id_new%TYPE;               -- 資産カテゴリCCID
    lt_deprn_method       fa_category_book_defaults.deprn_method%TYPE;            -- 償却方法
    lt_ifrs_assets_cost   xx01_adjustment_oif.cost%TYPE;                          -- 取得価額
    lt_deprn_reserve      xx01_adjustment_oif.deprn_reserve%TYPE;                 -- 償却累計額
    ln_reval_rsv          NUMBER;                                                 -- 再評価積立金
    lt_ytd_deprn          xx01_adjustment_oif.ytd_deprn%TYPE;                     -- 年償却累計額
    ln_deprn_exp          NUMBER;                                                 -- 減価償却費
    lt_bonus_deprn_rsv    xx01_adjustment_oif.bonus_deprn_reserve%TYPE;           -- ボーナス償却累計額
    lt_bonus_ytd_deprn    xx01_adjustment_oif.bonus_ytd_deprn%TYPE;               -- ボーナス年償却累計額
    lt_life_years         xx01_adjustment_oif.life_years%TYPE;                    -- 耐用年数
    lt_life_months        xx01_adjustment_oif.life_months%TYPE;                   -- 耐用月数
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- メインカーソル
    CURSOR ifrs_adj_cur
    IS
      SELECT 
             /*+
                LEADING(a)
                INDEX(fb_fixed FA_BOOKS_N1)
                INDEX(fab_fixed FA_ADDITIONS_B_U1)
                INDEX(fat_fixed FA_ADDITIONS_TL_U1)
                INDEX(fab_ifrs XXCFF_FA_ADDITIONS_B_N07)
                INDEX(fb_ifrs FA_BOOKS_N1)
                INDEX(fat_ifrs FA_ADDITIONS_TL_U1)
                INDEX(fc_ifrs.b FA_CATEGORIES_B_U1)
                INDEX(fc_ifrs.t FA_CATEGORIES_TL_U1)
                INDEX(fak_ifrs FA_ASSET_KEYWORDS_U1)
-- 2018/12/14 1.2 ADD Y.Shoji START
                INDEX(fth_ifrs FA_TRANSACTION_HEADERS_U1)
-- 2018/12/14 1.2 ADD Y.Shoji END
             */
              fab_ifrs.asset_id                   AS asset_id                      -- 資産ID
             ,fab_fixed.asset_number              AS asset_number_fixed            -- 資産番号（固定資産台帳）
             ,fab_ifrs.asset_number               AS asset_number_ifrs             -- 資産番号（IFRS台帳）
             ,fb_ifrs.date_placed_in_service      AS date_placed_in_service_ifrs   -- 事業供用日（IFRS台帳）
             ,fab_ifrs.asset_category_id          AS asset_category_id_ifrs        -- 資産カテゴリID（IFRS台帳）
             ,fab_ifrs.attribute_category_code    AS category_code_ifrs            -- 資産カテゴリコード（IFRS台帳）
             ,fb_fixed.date_placed_in_service     AS date_placed_in_service_fixed  -- 事業供用日（固定資産台帳）
             ,fat_fixed.description               AS description_fixed             -- 摘要（固定資産台帳）
             ,fat_ifrs.description                AS description_ifrs              -- 摘要（IFRS台帳）
             ,fab_ifrs.current_units              AS current_units                 -- 単位
-- 2018/04/27 1.1 MOD H.Mori START
--             ,fb_fixed.cost                       AS cost_fixed                    -- 取得価額（固定資産台帳）
             ,DECODE(fb_fixed.cost,0,fb_ifrs.cost,fb_fixed.cost) AS cost_fixed     -- 取得価額（固定資産台帳）
-- 2018/04/27 1.1 MOD H.Mori END
             ,fb_ifrs.cost                        AS cost_ifrs                     -- 取得価額（IFRS台帳）
             ,fb_ifrs.original_cost               AS original_cost                 -- 当初取得価額
             ,fab_ifrs.tag_number                 AS tag_number                    -- 現品票番号
             ,fab_ifrs.serial_number              AS serial_number                 -- シリアル番号
             ,fab_ifrs.asset_key_ccid             AS asset_key_ccid                -- 資産キーCCID
             ,fak_ifrs.segment1                   AS key_segment1                  -- 資産キーセグメント1
             ,fak_ifrs.segment2                   AS key_segment2                  -- 資産キーセグメント2
             ,fab_ifrs.parent_asset_id            AS parent_asset_id               -- 親資産ID
             ,fab_ifrs.lease_id                   AS lease_id                      -- リースID
             ,fab_ifrs.model_number               AS model_number                  -- モデル
             ,fab_ifrs.in_use_flag                AS in_use_flag                   -- 使用状況
             ,fab_ifrs.inventorial                AS inventorial                   -- 実地棚卸フラグ
             ,fab_ifrs.owned_leased               AS owned_leased                  -- 所有権
             ,fab_ifrs.new_used                   AS new_used                      -- 新品/中古
             ,fab_ifrs.attribute1                 AS attribute1                    -- カテゴリDFF1
             ,fab_ifrs.attribute2                 AS attribute2_ifrs               -- 取得日（IFRS台帳）
             ,fab_ifrs.attribute3                 AS attribute3                    -- カテゴリDFF3
             ,fab_ifrs.attribute4                 AS attribute4                    -- カテゴリDFF4
             ,fab_ifrs.attribute5                 AS attribute5                    -- カテゴリDFF5
             ,fab_ifrs.attribute6                 AS attribute6                    -- カテゴリDFF6
             ,fab_ifrs.attribute7                 AS attribute7                    -- カテゴリDFF7
             ,fab_ifrs.attribute8                 AS attribute8                    -- カテゴリDFF8
             ,fab_ifrs.attribute9                 AS attribute9                    -- カテゴリDFF9
             ,fab_ifrs.attribute10                AS attribute10                   -- カテゴリDFF10
             ,fab_ifrs.attribute11                AS attribute11                   -- カテゴリDFF11
             ,fab_ifrs.attribute12                AS attribute12                   -- カテゴリDFF12
             ,fab_ifrs.attribute13                AS attribute13                   -- カテゴリDFF13
             ,fab_ifrs.attribute14                AS attribute14                   -- カテゴリDFF14
             ,fab_ifrs.attribute15                AS attribute15_ifrs              -- IFRS耐用年数（IFRS台帳）
             ,fab_ifrs.attribute16                AS attribute16_ifrs              -- IFRS償却（IFRS台帳）
             ,fab_ifrs.attribute17                AS attribute17_ifrs              -- 不動産取得税（IFRS台帳）
             ,fab_ifrs.attribute18                AS attribute18_ifrs              -- 借入コスト（IFRS台帳）
             ,fab_ifrs.attribute19                AS attribute19_ifrs              -- その他（IFRS台帳）
             ,fab_ifrs.attribute20                AS attribute20_ifrs              -- IFRS資産科目（IFRS台帳）
             ,fab_ifrs.attribute21                AS attribute21_ifrs              -- 修正年月日（IFRS台帳）
             ,fab_ifrs.attribute22                AS attribute22                   -- カテゴリDFF22
             ,fab_ifrs.attribute23                AS attribute23                   -- カテゴリDFF23
             ,fab_ifrs.attribute24                AS attribute24                   -- カテゴリDFF24
             ,fab_ifrs.attribute25                AS attribute25                   -- カテゴリDFF27
             ,fab_ifrs.attribute26                AS attribute26                   -- カテゴリDFF25
             ,fab_ifrs.attribute27                AS attribute27                   -- カテゴリDFF26
             ,fab_ifrs.attribute28                AS attribute28                   -- カテゴリDFF28
             ,fab_ifrs.attribute29                AS attribute29                   -- カテゴリDFF29
             ,fab_ifrs.attribute30                AS attribute30                   -- カテゴリDFF30
             ,fb_ifrs.salvage_value               AS salvage_value                 -- 残存価額
             ,fb_ifrs.percent_salvage_value       AS percent_salvage_value         -- 残存価額%
             ,fb_ifrs.allowed_deprn_limit_amount  AS allowed_deprn_limit_amount    -- 償却限度額
             ,fb_ifrs.allowed_deprn_limit         AS allowed_deprn_limit           -- 償却限度率
             ,fb_ifrs.depreciate_flag             AS depreciate_flag               -- 償却費計上フラグ
             ,fb_ifrs.deprn_method_code           AS deprn_method_code             -- 償却方法
             ,fb_ifrs.basic_rate                  AS basic_rate                    -- 普通償却率
             ,fb_ifrs.adjusted_rate               AS adjusted_rate                 -- 割増後償却率
             ,fb_ifrs.life_in_months              AS life_in_months                -- 耐用年数+月数
             ,fb_ifrs.bonus_rule                  AS bonus_rule                    -- ボーナスルール
             ,fc_ifrs.segment1                    AS cat_segment1                  -- 資産カテゴリ-種類（IFRS台帳）
             ,fc_ifrs.segment2                    AS cat_segment2                  -- 資産カテゴリ-申告償却（IFRS台帳）
             ,fc_ifrs.segment3                    AS cat_segment3                  -- 資産カテゴリ-資産勘定（IFRS台帳）
             ,fc_ifrs.segment4                    AS cat_segment4                  -- 資産カテゴリ-償却科目（IFRS台帳）
             ,fc_ifrs.segment5                    AS cat_segment5                  -- 資産カテゴリ-耐用年数（IFRS台帳）
             ,fc_ifrs.segment6                    AS cat_segment6                  -- 資産カテゴリ-償却方法（IFRS台帳）
             ,fc_ifrs.segment7                    AS cat_segment7                  -- 資産カテゴリ-リース種別（IFRS台帳）
             ,fab_fixed.attribute2                AS attribute2_fixed              -- 取得日（固定資産台帳）
             ,fab_fixed.attribute15               AS attribute15_fixed             -- IFRS耐用年数（固定資産台帳）
             ,fab_fixed.attribute16               AS attribute16_fixed             -- IFRS償却（固定資産台帳）
             ,fab_fixed.attribute17               AS attribute17_fixed             -- 不動産取得税（固定資産台帳）
             ,fab_fixed.attribute18               AS attribute18_fixed             -- 借入コスト（固定資産台帳）
             ,fab_fixed.attribute19               AS attribute19_fixed             -- その他（固定資産台帳）
             ,fab_fixed.attribute20               AS attribute20_fixed             -- IFRS資産科目（固定資産台帳）
             ,fab_fixed.attribute21               AS attribute21_fixed             -- 修正年月日（固定資産台帳）
-- 2018/12/14 1.2 ADD Y.Shoji START
             ,DECODE(fth_ifrs.amortization_start_date
                    ,NULL ,cv_no
                          ,cv_yes)                AS amortized_flag                -- 修正額償却フラグ
             ,fth_ifrs.amortization_start_date    AS amortization_start_date       -- 償却開始日
-- 2018/12/14 1.2 ADD Y.Shoji END
      FROM    fa_books                fb_fixed    -- 資産台帳情報（固定資産台帳）
             ,fa_additions_b          fab_fixed   -- 資産詳細情報（固定資産台帳）
             ,fa_additions_tl         fat_fixed   -- 資産摘要情報（固定資産台帳）
             ,fa_books                fb_ifrs     -- 資産台帳情報（IFRS台帳）
             ,fa_additions_b          fab_ifrs    -- 資産詳細情報（IFRS台帳）
             ,fa_additions_tl         fat_ifrs    -- 資産摘要情報（IFRS台帳）
             ,fa_categories           fc_ifrs     -- 資産カテゴリ（IFRS台帳）
             ,fa_asset_keywords       fak_ifrs    -- 資産キー（IFRS台帳）
-- 2018/12/14 1.2 ADD Y.Shoji START
             ,fa_transaction_headers  fth_ifrs    -- 資産取引ヘッダ（IFRS台帳）
-- 2018/12/14 1.2 ADD Y.Shoji END
             ,(SELECT 
                      /*+
                          QB_NAME(a)
                      */
                      trn.asset_id  asset_id
               FROM   (
                       -- 条件①：修正年月日が対象の会計期間
                       SELECT 
                              /*+
                                 INDEX(fab1 XXCFF_FA_ADDITIONS_B_N05)
                                 INDEX(fb1 FA_BOOKS_N1)
                              */
                              fab1.asset_id  asset_id
                       FROM   fa_additions_b fab1      -- 資産詳細情報
                             ,fa_books       fb1       -- 資産台帳情報
                       WHERE  TO_DATE(fab1.attribute21 ,'YYYY/MM/DD') BETWEEN ld_start_date
                                                                      AND     ld_end_date
                       AND    fab1.asset_id                                 = fb1.asset_id
                       AND    fb1.book_type_code                            = gv_fixed_asset_register  -- 台帳種類_固定資産台帳
                       AND    fb1.date_ineffective                          IS NULL
                       --
                       UNION ALL
                       -- 条件②：摘要が前回実行時間以降に更新
                       SELECT 
                              /*+
                                 INDEX(fat2 XXCFF_FA_ADDITIONS_TL_N01)
                                 INDEX(fb2 FA_BOOKS_N1)
                              */
                              fat2.asset_id  asset_id
                       FROM   fa_additions_tl fat2      -- 資産摘要情報
                             ,fa_books        fb2       -- 資産台帳情報
                       WHERE  fat2.language         = cv_lang
                       AND    fat2.last_update_date > gt_exec_date             -- 前回実行日時
                       AND    fat2.last_update_date <> fat2.creation_date
                       AND    fat2.asset_id         = fb2.asset_id
                       AND    fb2.book_type_code    = gv_fixed_asset_register  -- 台帳種類_固定資産台帳
                       AND    fb2.date_ineffective  IS NULL
                       --
                       UNION ALL
                       -- 条件③：前回実行時間以降に調整の取引が発生
                       SELECT 
                              /*+
                                 INDEX(fth3 FA_TRANSACTION_HEADERS)
                              */
                              fth3.asset_id  asset_id
                       FROM   fa_transaction_headers fth3  -- 資産取引ヘッダ
                       WHERE  fth3.transaction_type_code = cv_tran_type_adj         -- 取引タイプコード(調整)
                       AND    fth3.book_type_code        = gv_fixed_asset_register  -- 台帳種類_固定資産台帳
                       AND    fth3.date_effective        > gt_exec_date             -- 前回実行日時
                       ) trn
               GROUP BY trn.asset_id
              ) target                            -- 対象の資産
      WHERE   target.asset_id                  = fb_fixed.asset_id
      AND     fb_fixed.book_type_code          = gv_fixed_asset_register  -- 台帳種類_固定資産台帳
      AND     fb_fixed.date_ineffective        IS NULL
      AND     fb_fixed.asset_id                = fab_fixed.asset_id
      AND     fab_fixed.asset_id               = fat_fixed.asset_id
      AND     fat_fixed.language               = cv_lang
      AND     fab_fixed.asset_number           = fab_ifrs.attribute22
      AND     fab_ifrs.attribute23             IS NULL                    -- IFRS対象資産番号
      AND     fab_ifrs.asset_id                = fb_ifrs.asset_id
      AND     fb_ifrs.book_type_code           = gv_fixed_ifrs_asset_regi -- 台帳種類_IFRS台帳
      AND     fb_ifrs.date_ineffective         IS NULL
      AND     fab_ifrs.asset_id                = fat_ifrs.asset_id
      AND     fat_ifrs.language                = cv_lang
      AND     fab_ifrs.asset_category_id       = fc_ifrs.category_id
      AND     fab_ifrs.asset_key_ccid          = fak_ifrs.code_combination_id(+)
-- 2018/12/14 1.2 ADD Y.Shoji START
      AND     fb_ifrs.transaction_header_id_in = fth_ifrs.transaction_header_id(+)
-- 2018/12/14 1.2 ADD Y.Shoji END
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
    -- 会計期間の開始年月日を取得
    ld_start_date := TO_DATE(gv_period_name ,cv_format_yyyymm);
    -- 会計期間の終了年月日を取得
    ld_end_date   := LAST_DAY(ld_start_date);
    -- 会計期間の翌月一日を取得
    ld_dpis_date  := ADD_MONTHS(TO_DATE(gv_period_name ,cv_format_yyyymm) ,1);
--
    --==============================================================
    --メインデータ抽出
    --==============================================================
    -- カーソルオープン
    OPEN ifrs_adj_cur;
    -- データの一括取得
    FETCH ifrs_adj_cur BULK COLLECT INTO  g_ifrs_adj_tab;
    -- カーソルクローズ
    CLOSE ifrs_adj_cur;
    -- 対象件数の取得
    gn_target_cnt := g_ifrs_adj_tab.COUNT;
--
    -- 新規登録対象件数が0件の場合
    IF ( gn_target_cnt = 0 ) THEN
      --メッセージの設定
      gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                     ,cv_msg_cff_00165     -- 取得対象データ無し
                                                     ,cv_tkn_get_data      -- トークン'GET_DATA'
                                                     ,cv_msg_cff_50236)    -- 固定資産（修正）情報
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG  --ログ(システム管理者用メッセージ)出力
        ,buff   => gv_out_msg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
        ,buff   => gv_out_msg
      );
    END IF;
--
    -- 初期化
    gn_loop_cnt   := 0;
    gn_normal_cnt := 0;
    gn_skip_cnt   := 0;
--
    -- ***************************************
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
    --==============================================================
    --メインループ処理
    --==============================================================
    <<ifrs_fa_add_loop>>
    FOR ln_loop_cnt IN 1 .. gn_target_cnt LOOP
--
      -- LOOP数取得
      gn_loop_cnt := ln_loop_cnt;
--
      --==============================================================
      -- 資産カテゴリCCID取得 (A-5-1)
      --==============================================================
      -- 資産カテゴリのsegment1-7の値を設定
      lt_segment1 := g_ifrs_adj_tab(ln_loop_cnt).cat_segment1;         -- 資産カテゴリ-種類（IFRS台帳）
      lt_segment2 := g_ifrs_adj_tab(ln_loop_cnt).cat_segment2;         -- 資産カテゴリ-申告償却（IFRS台帳）
      --
      -- 資産勘定
      -- IFRS資産科目（固定資産台帳）に値が設定されている場合
      IF (g_ifrs_adj_tab(ln_loop_cnt).attribute20_fixed IS NOT NULL) THEN
        lt_segment3 := g_ifrs_adj_tab(ln_loop_cnt).attribute20_fixed;  -- IFRS資産科目（固定資産台帳）
      ELSE
        lt_segment3 := g_ifrs_adj_tab(ln_loop_cnt).cat_segment3;       -- 資産カテゴリ-資産勘定（IFRS台帳）
      END IF;
      --
      lt_segment4 := g_ifrs_adj_tab(ln_loop_cnt).cat_segment4;         -- 資産カテゴリ-償却科目（IFRS台帳）
      --
      -- 耐用年数
      -- IFRS耐用年数（固定資産台帳）に値が設定されている場合
      IF (g_ifrs_adj_tab(ln_loop_cnt).attribute15_fixed IS NOT NULL) THEN
        lt_segment5 := g_ifrs_adj_tab(ln_loop_cnt).attribute15_fixed;  -- IFRS耐用年数（固定資産台帳）
        -- OIF登録用項目を設定
        lt_life_years  := g_ifrs_adj_tab(ln_loop_cnt).attribute15_fixed;            -- 耐用年数
        lt_life_months := 0;                                                        -- 耐用月数
      ELSE
        lt_segment5 := g_ifrs_adj_tab(ln_loop_cnt).cat_segment5;       -- 資産カテゴリ-耐用年数（IFRS台帳）
        -- OIF登録用項目を設定
        lt_life_years  := TRUNC(g_ifrs_adj_tab(ln_loop_cnt).life_in_months / 12);   -- 耐用年数
        lt_life_months := MOD(g_ifrs_adj_tab(ln_loop_cnt).life_in_months, 12);      -- 耐用月数
      END IF;
      --
      -- 償却方法
      -- IFRS償却（固定資産台帳）に値が設定されている場合
      IF (g_ifrs_adj_tab(ln_loop_cnt).attribute16_fixed IS NOT NULL) THEN
        lt_segment6 := g_ifrs_adj_tab(ln_loop_cnt).attribute16_fixed;  -- IFRS償却（固定資産台帳）
      ELSE
        lt_segment6 := g_ifrs_adj_tab(ln_loop_cnt).cat_segment6;       -- 資産カテゴリ-償却方法（IFRS台帳）
      END IF;
      --
      lt_segment7 := g_ifrs_adj_tab(ln_loop_cnt).cat_segment7;         -- 資産カテゴリ-リース種別（IFRS台帳）
--
      -- 資産カテゴリの組合せチェックおよびCCID取得
      xxcff_common1_pkg.chk_fa_category(
         iv_segment1      => lt_segment1            -- 種類
        ,iv_segment2      => lt_segment2            -- 申告償却
        ,iv_segment3      => lt_segment3            -- 資産勘定
        ,iv_segment4      => lt_segment4            -- 償却科目
        ,iv_segment5      => lt_segment5            -- 耐用年数
        ,iv_segment6      => lt_segment6            -- 償却方法
        ,iv_segment7      => lt_segment7            -- リース種別
        ,on_category_id   => lt_asset_category_id   -- 資産カテゴリCCID
        ,ov_errbuf        => lv_errbuf              -- エラー・メッセージ           --# 固定 #
        ,ov_retcode       => lv_retcode             -- リターン・コード             --# 固定 #
        ,ov_errmsg        => lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
      --==============================================================
      -- 償却方法取得（A-5-2）
      --==============================================================
      BEGIN
        SELECT  fcbd.deprn_method   AS deprn_method     -- 償却方法
        INTO    lt_deprn_method
        FROM    fa_category_book_defaults  fcbd    -- 資産カテゴリ償却基準
        WHERE   fcbd.category_id                 =  lt_asset_category_id      -- カテゴリID
        AND     fcbd.book_type_code              =  gv_fixed_ifrs_asset_regi  -- 台帳種類_IFRS台帳
        AND     fcbd.start_dpis                  <  ld_dpis_date
        AND     NVL(fcbd.end_dpis ,ld_dpis_date) >= ld_dpis_date
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff           -- XXCFF
                                                        ,cv_msg_cff_00281         -- 償却方法取得エラー
                                                        ,cv_tkn_category          -- トークン'CATEGORY'
                                                        ,lt_segment1 || cv_haifun ||  -- 種類
                                                         lt_segment2 || cv_haifun ||  -- 申告償却
                                                         lt_segment3 || cv_haifun ||  -- 資産勘定
                                                         lt_segment4 || cv_haifun ||  -- 償却科目
                                                         lt_segment5 || cv_haifun ||  -- 耐用年数
                                                         lt_segment6 || cv_haifun ||  -- 償却方法
                                                         lt_segment7                  -- リース種別
                                                                                  -- カテゴリコード
                                                        ,cv_tkn_bk_type           -- トークン'BOOK_TYPE_CODE'
                                                        ,gv_fixed_ifrs_asset_regi -- 台帳種類_IFRS台帳
                                                        )    -- 
                                                        ,1
                                                        ,5000);
          lv_errbuf  := lv_errmsg;
          RAISE global_api_expt;
      END;
--
      -- 取得価額を算出
      lt_ifrs_assets_cost :=   NVL(g_ifrs_adj_tab(ln_loop_cnt).cost_fixed, 0)                                 -- 取得価額（固定資産台帳）
                             + TO_NUMBER(NVL(g_ifrs_adj_tab(ln_loop_cnt).attribute17_fixed, cv_value_zero))   -- 不動産取得税（固定資産台帳）
                             + TO_NUMBER(NVL(g_ifrs_adj_tab(ln_loop_cnt).attribute18_fixed, cv_value_zero))   -- 借入コスト（固定資産台帳）
                             + TO_NUMBER(NVL(g_ifrs_adj_tab(ln_loop_cnt).attribute19_fixed, cv_value_zero));  -- その他（固定資産台帳）
--
      -- 修正対象の項目に1つでも修正がある場合
      IF ( ( g_ifrs_adj_tab(ln_loop_cnt).date_placed_in_service_ifrs     <> g_ifrs_adj_tab(ln_loop_cnt).date_placed_in_service_fixed )-- 事業供用日
        OR ( g_ifrs_adj_tab(ln_loop_cnt).description_ifrs                <> g_ifrs_adj_tab(ln_loop_cnt).description_fixed )       -- 摘要
        OR ( g_ifrs_adj_tab(ln_loop_cnt).asset_category_id_ifrs          <> lt_asset_category_id )                                -- 資産カテゴリID
        OR ( g_ifrs_adj_tab(ln_loop_cnt).deprn_method_code               <> lt_deprn_method )                                     -- 償却方法
        OR ( g_ifrs_adj_tab(ln_loop_cnt).cost_ifrs                       <> lt_ifrs_assets_cost )                                 -- 取得価額
        OR ( NVL(g_ifrs_adj_tab(ln_loop_cnt).attribute2_ifrs, cv_space ) <> 
                                                            NVL(g_ifrs_adj_tab(ln_loop_cnt).attribute2_fixed, cv_space ) )        -- 取得日
        OR ( NVL(g_ifrs_adj_tab(ln_loop_cnt).attribute15_ifrs, cv_space) <> 
                                                            NVL(g_ifrs_adj_tab(ln_loop_cnt).attribute15_fixed, cv_space ) )       -- IFRS耐用年数
        OR ( NVL(g_ifrs_adj_tab(ln_loop_cnt).attribute16_ifrs, cv_space) <> 
                                                            NVL(g_ifrs_adj_tab(ln_loop_cnt).attribute16_fixed, cv_space ) )       -- IFRS償却
        OR ( NVL(g_ifrs_adj_tab(ln_loop_cnt).attribute17_ifrs, cv_space) <> 
                                                            NVL(g_ifrs_adj_tab(ln_loop_cnt).attribute17_fixed, cv_space ) )       -- 不動産取得税
        OR ( NVL(g_ifrs_adj_tab(ln_loop_cnt).attribute18_ifrs, cv_space) <> 
                                                            NVL(g_ifrs_adj_tab(ln_loop_cnt).attribute18_fixed, cv_space ) )       -- 借入コスト
        OR ( NVL(g_ifrs_adj_tab(ln_loop_cnt).attribute19_ifrs, cv_space) <> 
                                                            NVL(g_ifrs_adj_tab(ln_loop_cnt).attribute19_fixed, cv_space ) )       -- その他
        OR ( NVL(g_ifrs_adj_tab(ln_loop_cnt).attribute20_ifrs, cv_space) <> 
                                                            NVL(g_ifrs_adj_tab(ln_loop_cnt).attribute20_fixed, cv_space ) )       -- IFRS資産科目
        OR ( NVL(g_ifrs_adj_tab(ln_loop_cnt).attribute21_ifrs, cv_space) <> 
                                                            NVL(g_ifrs_adj_tab(ln_loop_cnt).attribute21_fixed, cv_space ) )       -- 修正年月日
         ) THEN
        --==============================================================
        -- 累計額取得（A-5-3）
        --==============================================================
        -- 償却累計額・年償却累計額・ボーナス償却累計額・ボーナス年償却累計額の取得
        xx01_conc_util_pkg.query_balances_bonus(
           in_asset_id         => g_ifrs_adj_tab(ln_loop_cnt).asset_id       -- 資産ID
          ,iv_book_type_code   => gv_fixed_ifrs_asset_regi                   -- XXCFF:台帳種類_IFRS台帳
          ,on_deprn_rsv        => lt_deprn_reserve                           -- 償却累計額
          ,on_reval_rsv        => ln_reval_rsv                               -- 再評価積立金
          ,on_ytd_deprn        => lt_ytd_deprn                               -- 年償却累計額
          ,on_deprn_exp        => ln_deprn_exp                               -- 減価償却費
          ,on_bonus_deprn_rsv  => lt_bonus_deprn_rsv                         -- ボーナス償却累計額
          ,on_bonus_ytd_deprn  => lt_bonus_ytd_deprn                         -- ボーナス年償却累計額
        );
--
        --==============================================================
        -- 修正OIF登録 (A-5-4)
        --==============================================================
        INSERT INTO xx01_adjustment_oif(
           adjustment_oif_id               -- ID
          ,book_type_code                  -- 台帳名
          ,asset_number_old                -- 資産番号
          ,dpis_old                        -- 事業供用日（修正前）
          ,category_id_old                 -- 資産カテゴリID（修正前）
          ,cat_attribute_category_old      -- 資産カテゴリコード（修正前）
          ,dpis_new                        -- 事業供用日（修正後）
          ,description                     -- 摘要（修正後）
          ,transaction_units               -- 単位
          ,cost                            -- 取得価額
          ,original_cost                   -- 当初取得価額
          ,posting_flag                    -- 転記チェックフラグ
          ,status                          -- ステータス
-- 2018/12/14 1.2 ADD Y.Shoji START
          ,amortized_flag                  -- 修正額償却フラグ
          ,amortization_start_date         -- 償却開始日
-- 2018/12/14 1.2 ADD Y.Shoji END
          ,asset_number_new                -- 資産番号（修正後）
          ,tag_number                      -- 現品票番号
          ,category_id_new                 -- 資産カテゴリID（修正後）
          ,serial_number                   -- シリアル番号
          ,asset_key_ccid                  -- 資産キーCCID
          ,key_segment1                    -- 資産キーセグメント1
          ,key_segment2                    -- 資産キーセグメント2
          ,parent_asset_id                 -- 親資産ID
          ,lease_id                        -- リースID
          ,model_number                    -- モデル
          ,in_use_flag                     -- 使用状況
          ,inventorial                     -- 実地棚卸フラグ
          ,owned_leased                    -- 所有権
          ,new_used                        -- 新品/中古
          ,cat_attribute1                  -- カテゴリDFF1
          ,cat_attribute2                  -- カテゴリDFF2
          ,cat_attribute3                  -- カテゴリDFF3
          ,cat_attribute4                  -- カテゴリDFF4
          ,cat_attribute5                  -- カテゴリDFF5
          ,cat_attribute6                  -- カテゴリDFF6
          ,cat_attribute7                  -- カテゴリDFF7
          ,cat_attribute8                  -- カテゴリDFF8
          ,cat_attribute9                  -- カテゴリDFF9
          ,cat_attribute10                 -- カテゴリDFF10
          ,cat_attribute11                 -- カテゴリDFF11
          ,cat_attribute12                 -- カテゴリDFF12
          ,cat_attribute13                 -- カテゴリDFF13
          ,cat_attribute14                 -- カテゴリDFF14
          ,cat_attribute15                 -- カテゴリDFF15
          ,cat_attribute16                 -- カテゴリDFF16
          ,cat_attribute17                 -- カテゴリDFF17
          ,cat_attribute18                 -- カテゴリDFF18
          ,cat_attribute19                 -- カテゴリDFF19
          ,cat_attribute20                 -- カテゴリDFF20
          ,cat_attribute21                 -- カテゴリDFF21
          ,cat_attribute22                 -- カテゴリDFF22
          ,cat_attribute23                 -- カテゴリDFF23
          ,cat_attribute24                 -- カテゴリDFF24
          ,cat_attribute25                 -- カテゴリDFF25
          ,cat_attribute26                 -- カテゴリDFF26
          ,cat_attribute27                 -- カテゴリDFF27
          ,cat_attribute28                 -- カテゴリDFF28
          ,cat_attribute29                 -- カテゴリDFF29
          ,cat_attribute30                 -- カテゴリDFF30
          ,cat_attribute_category_new      -- 資産カテゴリコード（修正後）
          ,salvage_value                   -- 残存価額
          ,percent_salvage_value           -- 残存価額%
          ,allowed_deprn_limit_amount      -- 償却限度額
          ,allowed_deprn_limit             -- 償却限度率
          ,ytd_deprn                       -- 年償却累計額
          ,deprn_reserve                   -- 償却累計額
          ,depreciate_flag                 -- 償却費計上フラグ
          ,deprn_method_code               -- 償却方法
          ,basic_rate                      -- 普通償却率
          ,adjusted_rate                   -- 割増後償却率
          ,life_years                      -- 耐用年数
          ,life_months                     -- 耐用月数
          ,bonus_rule                      -- ボーナスルール
          ,bonus_ytd_deprn                 -- ボーナス年償却累計額
          ,bonus_deprn_reserve             -- ボーナス償却累計額
          ,created_by                      -- 作成者
          ,creation_date                   -- 作成日
          ,last_updated_by                 -- 最終更新者
          ,last_update_date                -- 最終更新日
          ,last_update_login               -- 最終更新ログインID
          ,request_id                      -- 要求ID
          ,program_application_id          -- アプリケーションID
          ,program_id                      -- プログラムID
          ,program_update_date             -- プログラム最終更新日
        )
        VALUES (
           xx01_adjustment_oif_s.NEXTVAL                             -- ID
          ,gv_fixed_ifrs_asset_regi                                  -- 台帳名
          ,g_ifrs_adj_tab(ln_loop_cnt).asset_number_ifrs             -- 資産番号
          ,g_ifrs_adj_tab(ln_loop_cnt).date_placed_in_service_ifrs   -- 事業供用日（修正前）
          ,g_ifrs_adj_tab(ln_loop_cnt).asset_category_id_ifrs        -- 資産カテゴリID（修正前）
          ,g_ifrs_adj_tab(ln_loop_cnt).category_code_ifrs            -- 資産カテゴリコード（修正前）
          ,g_ifrs_adj_tab(ln_loop_cnt).date_placed_in_service_fixed  -- 事業供用日（修正後）
          ,g_ifrs_adj_tab(ln_loop_cnt).description_fixed             -- 摘要（修正後）
          ,g_ifrs_adj_tab(ln_loop_cnt).current_units                 -- 単位
          ,lt_ifrs_assets_cost                                       -- 取得価額
          ,g_ifrs_adj_tab(ln_loop_cnt).original_cost                 -- 当初取得価額
          ,cv_yes                                                    -- 転記チェックフラグ
          ,cv_status_pending                                         -- ステータス
-- 2018/12/14 1.2 ADD Y.Shoji START
          ,g_ifrs_adj_tab(ln_loop_cnt).amortized_flag                -- 修正額償却フラグ
          ,g_ifrs_adj_tab(ln_loop_cnt).amortization_start_date       -- 償却開始日
-- 2018/12/14 1.2 ADD Y.Shoji END
          ,g_ifrs_adj_tab(ln_loop_cnt).asset_number_ifrs             -- 資産番号（修正後）
          ,g_ifrs_adj_tab(ln_loop_cnt).tag_number                    -- 現品票番号
          ,lt_asset_category_id                                      -- 資産カテゴリID（修正後）
          ,g_ifrs_adj_tab(ln_loop_cnt).serial_number                 -- シリアル番号
          ,g_ifrs_adj_tab(ln_loop_cnt).asset_key_ccid                -- 資産キーCCID
          ,g_ifrs_adj_tab(ln_loop_cnt).key_segment1                  -- 資産キーセグメント1
          ,g_ifrs_adj_tab(ln_loop_cnt).key_segment2                  -- 資産キーセグメント2
          ,g_ifrs_adj_tab(ln_loop_cnt).parent_asset_id               -- 親資産ID
          ,g_ifrs_adj_tab(ln_loop_cnt).lease_id                      -- リースID
          ,g_ifrs_adj_tab(ln_loop_cnt).model_number                  -- モデル
          ,g_ifrs_adj_tab(ln_loop_cnt).in_use_flag                   -- 使用状況
          ,g_ifrs_adj_tab(ln_loop_cnt).inventorial                   -- 実地棚卸フラグ
          ,g_ifrs_adj_tab(ln_loop_cnt).owned_leased                  -- 所有権
          ,g_ifrs_adj_tab(ln_loop_cnt).new_used                      -- 新品/中古
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute1                    -- カテゴリDFF1
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute2_fixed              -- カテゴリDFF2（取得日）
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute3                    -- カテゴリDFF3
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute4                    -- カテゴリDFF4
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute5                    -- カテゴリDFF5
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute6                    -- カテゴリDFF6
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute7                    -- カテゴリDFF7
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute8                    -- カテゴリDFF8
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute9                    -- カテゴリDFF9
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute10                   -- カテゴリDFF10
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute11                   -- カテゴリDFF11
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute12                   -- カテゴリDFF12
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute13                   -- カテゴリDFF13
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute14                   -- カテゴリDFF14
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute15_fixed             -- カテゴリDFF15（IFRS耐用年数）
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute16_fixed             -- カテゴリDFF16（IFRS償却）
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute17_fixed             -- カテゴリDFF17（不動産取得税）
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute18_fixed             -- カテゴリDFF18（借入コスト）
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute19_fixed             -- カテゴリDFF19（その他）
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute20_fixed             -- カテゴリDFF20（IFRS資産科目）
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute21_fixed             -- カテゴリDFF21（修正年月日）
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute22                   -- カテゴリDFF22
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute23                   -- カテゴリDFF23
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute24                   -- カテゴリDFF24
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute25                   -- カテゴリDFF25
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute26                   -- カテゴリDFF26
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute27                   -- カテゴリDFF27
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute28                   -- カテゴリDFF28
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute29                   -- カテゴリDFF29
          ,g_ifrs_adj_tab(ln_loop_cnt).attribute30                   -- カテゴリDFF30
          ,lt_segment1 || cv_haifun ||  -- 種類
           lt_segment2 || cv_haifun ||  -- 申告償却
           lt_segment3 || cv_haifun ||  -- 資産勘定
           lt_segment4 || cv_haifun ||  -- 償却科目
           lt_segment5 || cv_haifun ||  -- 耐用年数
           lt_segment6 || cv_haifun ||  -- 償却方法
           lt_segment7                  -- リース種別
                                                                     -- 資産カテゴリコード（修正後）
          ,g_ifrs_adj_tab(ln_loop_cnt).salvage_value                 -- 残存価額
          ,g_ifrs_adj_tab(ln_loop_cnt).percent_salvage_value         -- 残存価額%
          ,g_ifrs_adj_tab(ln_loop_cnt).allowed_deprn_limit_amount    -- 償却限度額
          ,g_ifrs_adj_tab(ln_loop_cnt).allowed_deprn_limit           -- 償却限度率
          ,lt_ytd_deprn                                              -- 年償却累計額
          ,lt_deprn_reserve                                          -- 償却累計額
          ,g_ifrs_adj_tab(ln_loop_cnt).depreciate_flag               -- 償却費計上フラグ
          ,lt_deprn_method                                           -- 償却方法
          ,g_ifrs_adj_tab(ln_loop_cnt).basic_rate                    -- 普通償却率
          ,g_ifrs_adj_tab(ln_loop_cnt).adjusted_rate                 -- 割増後償却率
          ,lt_life_years                                             -- 耐用年数
          ,lt_life_months                                            -- 耐用月数
          ,g_ifrs_adj_tab(ln_loop_cnt).bonus_rule                    -- ボーナスルール
          ,lt_bonus_ytd_deprn                                        -- ボーナス年償却累計額
          ,lt_bonus_deprn_rsv                                        -- ボーナス償却累計額
          ,cn_created_by                                             -- 作成者
          ,cd_creation_date                                          -- 作成日
          ,cn_last_updated_by                                        -- 最終更新者
          ,cd_last_update_date                                       -- 最終更新日
          ,cn_last_update_login                                      -- 最終更新ログインID
          ,cn_request_id                                             -- リクエストID
          ,cn_program_application_id                                 -- アプリケーションID
          ,cn_program_id                                             -- プログラムID
          ,cd_program_update_date                                    -- プログラム最終更新日
        )
        ;
--
        -- 正常件数カウント
        gn_normal_cnt := gn_normal_cnt + 1;
      -- 修正項目に修正がない場合
      ELSE
        -- スキップとなった資産情報を出力する
        gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                                  -- XXCFF
                                                       ,cv_msg_cff_00276                                -- IFRS台帳修正スキップメッセージ
                                                       ,cv_tkn_asset_number1                            -- トークン'ASSET_NUMBER1'
                                                       ,g_ifrs_adj_tab(gn_loop_cnt).asset_number_fixed  -- 固定資産台帳の資産番号
                                                       ,cv_tkn_asset_number2                            -- トークン'ASSET_NUMBER2'
                                                       ,g_ifrs_adj_tab(gn_loop_cnt).asset_number_ifrs)  -- IFRS台帳の資産番号
                                                       ,1
                                                       ,2000);
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
        -- スキップ件数カウント
        gn_skip_cnt := gn_skip_cnt + 1;
      END IF;
--
    END LOOP ifrs_fa_add_loop;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルクローズ
      IF (ifrs_adj_cur%ISOPEN) THEN
        CLOSE ifrs_adj_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF (ifrs_adj_cur%ISOPEN) THEN
        CLOSE ifrs_adj_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF (ifrs_adj_cur%ISOPEN) THEN
        CLOSE ifrs_adj_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_ifrs_adj_data;
--
  /**********************************************************************************
   * Procedure Name   : get_exec_date
   * Description      : 前回実行日時取得処理(A-4)
   ***********************************************************************************/
  PROCEDURE get_exec_date(
    ov_errbuf      OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg      OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_exec_date'; -- プログラム名
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
    BEGIN
      SELECT  xis.exec_date AS exec_date  -- 前回実行日時
      INTO    gt_exec_date
      FROM    xxcff_ifrs_sets  xis        -- IFRS台帳連携セット
      WHERE   xis.exec_id = cv_pkg_name
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                      ,cv_msg_cff_00165     -- 取得対象データ無し
                                                      ,cv_tkn_get_data      -- トークン'GET_DATA'
                                                      ,cv_msg_cff_50316)    -- IFRS台帳連携セット
                                                      ,1
                                                      ,5000);
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN data_lock_expt THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                      ,cv_msg_cff_00007     -- ロックエラー
                                                      ,cv_tkn_table_name    -- トークン'TABLE_NAME'
                                                      ,cv_msg_cff_50316)    -- IFRS台帳連携セット
                                                      ,1
                                                      ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
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
  END get_exec_date;
--
  /**********************************************************************************
   * Procedure Name   : chk_period
   * Description      : 会計期間チェック(A-3)
   ***********************************************************************************/
  PROCEDURE chk_period(
    ov_errbuf      OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg      OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_period'; -- プログラム名
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
    lt_deprn_run          fa_deprn_periods.deprn_run%TYPE := NULL;  -- 減価償却実行フラグ
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
    BEGIN
      -- 会計期間チェック
      SELECT  fdp.deprn_run        AS deprn_run   -- 減価償却実行フラグ
      INTO    lt_deprn_run
      FROM    fa_deprn_periods  fdp               -- 減価償却期間
      WHERE   fdp.book_type_code    = gv_fixed_ifrs_asset_regi
      AND     fdp.period_name       = gv_period_name
      AND     fdp.period_close_date IS NULL
      ;
    EXCEPTION
      -- 会計期間の取得件数がゼロ件の場合
      WHEN NO_DATA_FOUND THEN
        RAISE chk_period_expt;
    END;
--
    -- 減価償却が実行されている場合
    IF lt_deprn_run = cv_yes THEN
      RAISE chk_period_expt;
    END IF;
--
  EXCEPTION
    -- *** 会計期間チェックエラーハンドラ ***
    WHEN chk_period_expt THEN
      -- エラーメッセージをセット
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff            -- XXCFF
                                                    ,cv_msg_cff_00037          -- 会計期間チェックエラー
                                                    ,cv_tkn_bk_type            -- トークン'BOOK_TYPE_CODE'
                                                    ,gv_fixed_ifrs_asset_regi  -- 資産台帳名
                                                    ,cv_tkn_period             -- トークン'PERIOD_NAME'
                                                    ,gv_period_name)           -- 会計期間名
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      --
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      -- 終了ステータスはエラーとする
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
  END chk_period;
--
  /**********************************************************************************
   * Procedure Name   : get_profile_values
   * Description      : プロファイル取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_profile_values(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile_values'; -- プログラム名
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
    -- XXCFF:台帳種類_固定資産台帳
    gv_fixed_asset_register := FND_PROFILE.VALUE(cv_fixed_asset_register);
    IF (gv_fixed_asset_register IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_cff_00020     -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_cff_50228)    -- XXCFF:台帳種類_固定資産台帳
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:台帳種類_IFRS台帳
    gv_fixed_ifrs_asset_regi := FND_PROFILE.VALUE(cv_fixed_ifrs_asset_regi);
    IF (gv_fixed_ifrs_asset_regi IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_cff_00020     -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_cff_50314)    -- XXCFF:台帳種類_IFRS台帳
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
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
  END get_profile_values;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
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
    -- コンカレントパラメータ値出力(出力の表示)
    xxcff_common1_pkg.put_log_param(
       iv_which         => cv_file_type_out    -- 出力区分
      ,ov_errbuf        => lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,ov_retcode       => lv_retcode          -- リターン・コード             --# 固定 #
      ,ov_errmsg        => lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> ov_retcode) THEN
      RAISE global_api_expt;
    END IF;
--
    -- コンカレントパラメータ値出力(ログの表示)
    xxcff_common1_pkg.put_log_param(
       iv_which         => cv_file_type_log    -- 出力区分
      ,ov_errbuf        => lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,ov_retcode       => lv_retcode          -- リターン・コード             --# 固定 #
      ,ov_errmsg        => lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> ov_retcode) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** 共通関数コメント ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
    iv_period_name  IN  VARCHAR2,     -- 1.会計期間名
    ov_errbuf       OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain';      -- プログラム名
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
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- INパラメータ(会計期間名)をグローバル変数に設定
    gv_period_name := iv_period_name;
--
    -- ===============================
    -- 初期処理 (A-1)
    -- ===============================
    init(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- プロファイル取得 (A-2)
    -- ===============================
    get_profile_values(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 会計期間チェック (A-3)
    -- ===============================
    chk_period(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- 前回実行日時取得 (A-4)
    -- =========================================
    get_exec_date(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- IFRS台帳修正データ抽出・登録 (A-5)
    -- =========================================
    get_ifrs_adj_data(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- 実行日時更新(A-6)
    -- =========================================
    upd_exec_date(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
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
    errbuf         OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode        OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_period_name IN  VARCHAR2       --   1.会計期間名
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
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
--
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
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_err_cnt    := 0;
    --
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_period_name -- 会計期間名
      ,lv_errbuf      -- エラー・メッセージ           --# 固定 #
      ,lv_retcode     -- リターン・コード             --# 固定 #
      ,lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
  /**********************************************************************************
   * Description      : 終了処理(A-7)
   ***********************************************************************************/
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      -- 正常件数を0に設定
      gn_normal_cnt := 0;
      -- スキップ件数を0に設定
      gn_skip_cnt   := 0;
      -- エラー件数を1に設定
      gn_err_cnt    := 1;
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
      -- 対象件数がカウントされている場合
      IF ( gn_target_cnt > 0 ) THEN
        -- エラーとなった資産情報を出力する
        gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                                  -- XXCFF
                                                       ,cv_msg_cff_00275                                -- IFRS台帳修正登録エラー
                                                       ,cv_tkn_asset_number1                            -- トークン'ASSET_NUMBER1'
                                                       ,g_ifrs_adj_tab(gn_loop_cnt).asset_number_fixed  -- 固定資産台帳の資産番号
                                                       ,cv_tkn_asset_number2                            -- トークン'ASSET_NUMBER2'
                                                       ,g_ifrs_adj_tab(gn_loop_cnt).asset_number_ifrs)  -- IFRS台帳の資産番号
                                                       ,1
                                                       ,2000);
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
    -- 対象件数が0件、またはスキップ件数が存在する場合
    ELSIF ( ( gn_target_cnt = 0 )
      OR    ( gn_skip_cnt   > 0 ) ) THEN
      -- ステータスを警告にする
      lv_retcode := cv_status_warn;
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- ===============================================================
    -- IFRS台帳修正における件数出力
    -- ===============================================================
    -- 修正OIF登録メッセージ出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff
                    ,iv_name         => cv_msg_cff_00267
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_skip_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_err_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
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
END XXCFF019A04C;
/
