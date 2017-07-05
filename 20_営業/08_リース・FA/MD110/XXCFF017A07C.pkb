CREATE OR REPLACE PACKAGE BODY XXCFF017A07C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * Package Name     : XXCFF017A07C(body)
 * Description      : 自販機部門振替
 * MD.050           : MD050_CFF_017_A07_自販機部門振替
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                       初期処理                                  (A-1)
 *  get_profile_values         プロファイル値取得                        (A-2)
 *  chk_period                 会計期間チェック                          (A-3)
 *  chk_data_exist             前回作成済み部門振替仕訳存在チェック      (A-4)
 *  ins_gl_oif_lease           一般会計OIF登録処理（リース物件振替）     (A-5)
 *  ins_gl_oif_vd              一般会計OIF登録処理（自販機物件振替）     (A-6)
 *  submain                    メイン処理プロシージャ
 *  main                       コンカレント実行ファイル登録プロシージャ
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2017/04/14    1.0   SCSK小路恭弘     新規作成
 *  2017/05/15    1.1   SCSK小路恭弘     E_本稼動_14030 パフォーマンス対応
 *  2017/06/22    1.2   SCSK小路恭弘     E_本稼動_14369対応
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn   CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error  CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
  --WHOカラム
  cn_created_by    CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
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
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name            CONSTANT VARCHAR2(20) := 'XXCFF017A07C';     --パッケージ名
--
  -- ***アプリケーション短縮名
  cv_msg_kbn_cff         CONSTANT VARCHAR2(5)  := 'XXCFF';
--
  -- ***メッセージ名(本文)
  cv_msg_xxcff_00020     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00020'; -- プロファイル取得エラー
  cv_msg_xxcff_00115     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00115'; -- 一般会計OIF作成メッセージ
  cv_msg_xxcff_00130     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00130'; -- GL会計期間チェックエラー
  cv_msg_xxcff_00165     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00165'; -- 取得対象データ無し
  cv_msg_xxcff_00181     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00181'; -- 取得エラー
  cv_msg_xxcff_00246     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00246'; -- リース物件部門振替仕訳存在チェック（OIF）
  cv_msg_xxcff_00247     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00247'; -- 自販機物件部門振替仕訳存在チェック（OIF）
  cv_msg_xxcff_00248     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00248'; -- リース物件部門振替仕訳存在チェック（仕訳ヘッダ）
  cv_msg_xxcff_00249     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00249'; -- 自販機物件部門振替仕訳存在チェック（仕訳ヘッダ）
  cv_msg_xxcff_00250     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00250'; -- リース物件部門振替仕訳件数
  cv_msg_xxcff_00251     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00251'; -- 自販機物件部門振替仕訳件数
--
  -- ***メッセージ名(トークン)
  cv_msg_xxcff_50078     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50078'; -- XXCFF:部門コード_調整部門
  cv_msg_xxcff_50079     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50079'; -- XXCFF:顧客コード_定義なし
  cv_msg_xxcff_50080     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50080'; -- XXCFF:企業コード_定義なし
  cv_msg_xxcff_50081     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50081'; -- XXCFF:予備1_定義なし
  cv_msg_xxcff_50082     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50082'; -- XXCFF:予備2_定義なし
  cv_msg_xxcff_50146     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50146'; -- XXCFF:仕訳ソース_リース
  cv_msg_xxcff_50154     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50154'; -- ログイン(ユーザ名,所属部門)情報
  cv_msg_xxcff_50155     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50155'; -- XXCFF:伝票番号_リース
  cv_msg_xxcff_50160     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50160'; -- 会計帳簿名
  cv_msg_xxcff_50167     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50167'; -- ログインユーザID=
  cv_msg_xxcff_50168     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50168'; -- 会計帳簿ID
  cv_msg_xxcff_50255     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50255'; -- XXCFF:仕訳ソース_自販機物件
  cv_msg_xxcff_50273     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50273'; -- XXCFF:台帳名
  cv_msg_xxcff_50287     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50287'; -- XXCFF:台帳名_FINリース台帳
  cv_msg_xxcff_50288     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50288'; -- XXCFF:仕訳カテゴリ_自販機部門振替
  cv_msg_xxcff_50289     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50289'; -- リース物件振替
  cv_msg_xxcff_50290     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50290'; -- 自販機物件振替
  cv_msg_xxcff_50291     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50291'; -- XXCFF:仕訳ソース_資産管理
  cv_msg_xxcff_50292     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50292'; -- XXCFF:仕訳カテゴリ_減価償却
--
  -- ***トークン名
  cv_tkn_table           CONSTANT VARCHAR2(20) := 'TABLE_NAME';
  cv_tkn_key_name        CONSTANT VARCHAR2(20) := 'KEY_NAME';
  cv_tkn_key_val         CONSTANT VARCHAR2(20) := 'KEY_VAL';
  cv_tkn_prof            CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_period          CONSTANT VARCHAR2(20) := 'PERIOD_NAME';
  cv_tkn_get_data        CONSTANT VARCHAR2(20) := 'GET_DATA';
--
  -- ***プロファイル
  cv_fin_lease_books     CONSTANT VARCHAR2(40) := 'XXCFF1_FIN_LEASE_BOOKS';             -- 台帳名_FINリース台帳
  cv_fixed_assets_books  CONSTANT VARCHAR2(40) := 'XXCFF1_FIXED_ASSETS_BOOKS';          -- 台帳名
  cv_je_src_lease        CONSTANT VARCHAR2(40) := 'XXCFF1_JE_SOURCE_LEASE';             -- 仕訳ソース_リース
  cv_je_src_vending      CONSTANT VARCHAR2(40) := 'XXCFF1_JE_SOURCE_VENDING';           -- 仕訳ソース_自販機物件
  cv_je_src_asset_man    CONSTANT VARCHAR2(40) := 'XXCFF1_JE_SOURCE_ASSET_MANAGEMENT';  -- 仕訳ソース_資産管理
  cv_je_cat_vd_dep       CONSTANT VARCHAR2(40) := 'XXCFF1_JE_CATEGORY_VD_DEP';          -- 仕訳カテゴリ_自販機部門振替
  cv_je_cat_dep          CONSTANT VARCHAR2(40) := 'XXCFF1_JE_CATEGORY_DEPRECIATION';    -- 仕訳カテゴリ_減価償却
  cv_dep_cd_chosei       CONSTANT VARCHAR2(40) := 'XXCFF1_DEP_CD_CHOSEI';               -- 部門コード_調整部門
  cv_ptnr_cd_dammy       CONSTANT VARCHAR2(40) := 'XXCFF1_PTNR_CD_DAMMY';               -- 顧客コード_定義なし
  cv_busi_cd_dammy       CONSTANT VARCHAR2(40) := 'XXCFF1_BUSI_CD_DAMMY';               -- 企業コード_定義なし
  cv_project_dammy       CONSTANT VARCHAR2(40) := 'XXCFF1_PROJECT_DAMMY';               -- 予備1_定義なし
  cv_future_dammy        CONSTANT VARCHAR2(40) := 'XXCFF1_FUTURE_DAMMY';                -- 予備2_定義なし
  cv_slip_num_lease      CONSTANT VARCHAR2(40) := 'XXCFF1_SLIP_NUM_LEASE';              -- 伝票番号_リース
--
  -- ***ファイル出力
  cv_file_type_out       CONSTANT VARCHAR2(10) := 'OUTPUT';                     --メッセージ出力
  cv_file_type_log       CONSTANT VARCHAR2(10) := 'LOG';                        --ログ出力
--
  -- ***情報抽出用
  cv_flag_y              CONSTANT VARCHAR2(1)  := 'Y';
  cv_flag_n              CONSTANT VARCHAR2(1)  := 'N';
  cv_lang                CONSTANT VARCHAR2(50) := USERENV('LANG');
  cv_actual_flag_a       CONSTANT VARCHAR2(1)  := 'A';
-- 2017/06/22 Ver.1.2 Y.Shoji ADD Start
  ct_adj_type_expense    CONSTANT fa_adjustments.adjustment_type%TYPE  := 'EXPENSE';       -- 調整タイプ
-- 2017/06/22 Ver.1.2 Y.Shoji ADD End
--
  -- ***登録用
  cv_status_new          CONSTANT VARCHAR2(3)  := 'NEW';
  cv_tax_code            CONSTANT VARCHAR2(4)  := '0000';
--
  -- ***日付書式
  cv_yyyymm              CONSTANT VARCHAR2(7)  := 'YYYY-MM';
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ***バルクフェッチ用定義
  TYPE g_segment1_ttype       IS TABLE OF gl_code_combinations.segment1%TYPE INDEX BY PLS_INTEGER;
  TYPE g_segment3_ttype       IS TABLE OF gl_code_combinations.segment3%TYPE INDEX BY PLS_INTEGER;
  TYPE g_segment4_ttype       IS TABLE OF gl_code_combinations.segment4%TYPE INDEX BY PLS_INTEGER;
  TYPE g_segment3_to_ttype    IS TABLE OF fnd_lookup_values.attribute2%TYPE INDEX BY PLS_INTEGER;
  TYPE g_segment4_to_ttype    IS TABLE OF fnd_lookup_values.attribute3%TYPE INDEX BY PLS_INTEGER;
  TYPE g_amount_ttype         IS TABLE OF fa_deprn_detail.deprn_amount%TYPE INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- ***バルクフェッチ用定義
  g_segment1_tab             g_segment1_ttype;
  g_segment3_tab             g_segment3_ttype;
  g_segment4_tab             g_segment4_ttype;
  g_segment3_to_tab          g_segment3_to_ttype;
  g_segment4_to_tab          g_segment4_to_ttype;
  g_amount_tab               g_amount_ttype;
--
  -- ***処理件数
  -- 一般会計OIF登録処理における件数出力
  gn_target_lease_cnt       NUMBER;     -- 対象件数(リース)
  gn_target_vd_cnt          NUMBER;     -- 対象件数(自販機)
  gn_normal_lease_cnt       NUMBER;     -- 正常件数(リース)
  gn_normal_vd_cnt          NUMBER;     -- 正常件数(自販機)
  gn_error_cnt              NUMBER;     -- エラー件数
--
  -- 初期値情報
  g_init_rec      xxcff_common1_pkg.init_rtype;
--
  -- パラメータ会計期間名
  gv_period_name  VARCHAR2(100);
--
  -- ***ユーザ情報
  -- ログインユーザ
  gt_login_user_name  xx03_users_v.user_name%TYPE;
  -- 起票部門(所属部門)
  gt_login_dept_code  per_people_f.attribute28%TYPE;
  -- ***会計帳簿情報
  -- 会計帳簿名
  gt_sob_name         gl_sets_of_books.name%TYPE;
--
  -- ***プロファイル値
  gv_fin_lease_books       VARCHAR2(100);    -- 台帳名_FINリース台帳
  gv_fixed_assets_books    VARCHAR2(100);    -- 台帳名
  gv_je_src_lease          VARCHAR2(100);    -- 仕訳ソース_リース
  gv_je_src_vending        VARCHAR2(100);    -- 仕訳ソース_自販機物件
  gv_je_src_asset_man      VARCHAR2(100);    -- 仕訳ソース_資産管理
  gv_je_cat_vd_dep         VARCHAR2(100);    -- 仕訳カテゴリ_自販機部門振替
  gv_je_cat_dep            VARCHAR2(100);    -- 仕訳カテゴリ_減価償却
  gv_dep_cd_chosei         VARCHAR2(100);    -- 部門コード_調整部門
  gv_ptnr_cd_dammy         VARCHAR2(100);    -- 顧客コード_定義なし
  gv_busi_cd_dammy         VARCHAR2(100);    -- 企業コード_定義なし
  gv_project_dammy         VARCHAR2(100);    -- 予備1_定義なし
  gv_future_dammy          VARCHAR2(100);    -- 予備2_定義なし
  gv_slip_num_lease        VARCHAR2(100);    -- 伝票番号_リース
--
  -- ***カーソル定義
--
  -- ***テーブル型配列
--
  /**********************************************************************************
   * Procedure Name   : delete_collections
   * Description      : コレクション削除
   ***********************************************************************************/
  PROCEDURE delete_collections(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_collections'; -- プログラム名
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
    --コレクション結合配列の削除
    g_segment1_tab.DELETE;     -- 会社コード
    g_segment3_tab.DELETE;     -- 勘定科目
    g_segment4_tab.DELETE;     -- 補助科目
    g_segment3_to_tab.DELETE;  -- 振替先勘定科目
    g_segment4_to_tab.DELETE;  -- 振替先補助科目
    g_amount_tab.DELETE;       -- 借方合計
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
  END delete_collections;
--
  /**********************************************************************************
   * Procedure Name   : ins_gl_oif_vd
   * Description      : 一般会計OIF登録処理（自販機物件振替） (A-6)
   ***********************************************************************************/
  PROCEDURE ins_gl_oif_vd(
    ov_errbuf         OUT    VARCHAR2      --   エラー・メッセージ           --# 固定 #
   ,ov_retcode        OUT    VARCHAR2      --   リターン・コード             --# 固定 #
   ,ov_errmsg         OUT    VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_gl_oif_vd'; -- プログラム名
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
    cv_xxcff1_asset_category_id  CONSTANT VARCHAR2(30)  := 'XXCFF1_ASSET_CATEGORY_ID'; -- 参照タイプ：自販機資産カテゴリ固定値
    cv_attribute9_1              CONSTANT VARCHAR2(1)   := '1';                        -- DFF9：1
    cv_attribute9_3              CONSTANT VARCHAR2(1)   := '3';                        -- DFF9：3
--
    -- *** ローカル変数 ***
    ln_cnt_chk     NUMBER DEFAULT 0;    -- チェック用件数
--
    -- *** ローカル・カーソル ***
    -- 固定資産台帳の減価償却の仕訳抽出カーソル
    CURSOR gl_oif_vd_cur
    IS
-- 2017/06/22 Ver.1.2 Y.Shoji MOD Start
--      SELECT 
--             /*+
--               INDEX(gjh GL_JE_HEADERS_N2)
--               INDEX(gjl GL_JE_LINES_U1)
--               INDEX(fdp FA_DEPRN_PERIODS_U1)
--               INDEX(fdd FA_DEPRN_DETAIL_N3)
--               INDEX(fab FA_ADDITIONS_B_U1)
--               INDEX(xvoh XXCFF_VD_OBJECT_HEADERS_U01)
--             */
--             gcc.segment1           AS segment1        -- 会社コード
--            ,gcc.segment3           AS segment3        -- 勘定科目
--            ,gcc.segment4           AS segment4        -- 補助科目
--            ,flv.attribute10        AS segment3_to     -- 振替先勘定科目
--            ,flv.attribute11        AS segment4_to     -- 振替先補助科目
--            ,SUM(fdd.deprn_amount)  AS amount          -- 借方合計
--      FROM   gl_je_headers            gjh   -- 仕訳ヘッダ
--            ,gl_je_lines              gjl   -- 仕訳明細
--            ,gl_je_sources_tl         gjst  -- 仕訳ソース
--            ,gl_je_categories_tl      gjct  -- 仕訳カテゴリ
--            ,gl_code_combinations     gcc   -- 勘定科目組合せマスタ
--            ,fa_deprn_detail          fdd   -- 減価償却詳細
--            ,fa_deprn_periods         fdp   -- 減価償却期間
--            ,fa_additions_b           fab   -- 資産詳細情報
--            ,xxcff_vd_object_headers  xvoh  -- 自販機物件
--            ,fnd_lookup_values        flv   -- 参照表
--      WHERE  gjh.je_source              = gjst.je_source_name
--      AND    gjst.language              = cv_lang
--      AND    gjst.user_je_source_name   = gv_je_src_asset_man
--      AND    gjh.je_category            = gjct.je_category_name
--      AND    gjct.language              = cv_lang
--      AND    gjct.user_je_category_name = gv_je_cat_dep
--      AND    gjh.set_of_books_id        = g_init_rec.set_of_books_id    -- 会計帳簿ID
--      AND    gjh.period_name            = gv_period_name                -- 会計期間
--      AND    gjh.actual_flag            = cv_actual_flag_a              -- 残高タイプ
--      AND    gjh.je_header_id           = gjl.je_header_id
--      AND    gjl.reference_5            = gv_fixed_assets_books         -- 台帳
--      AND    gjl.code_combination_id    = gcc.code_combination_id
--      AND    gcc.segment3               = flv.attribute4
--      AND    gcc.segment4               = flv.attribute8
--      AND    gjl.je_header_id           = fdd.je_header_id
--      AND    gjl.je_line_num            = fdd.deprn_expense_je_line_num
--      AND    fdd.book_type_code         = gv_fixed_assets_books         -- 台帳
--      AND    fdd.book_type_code         = fdp.book_type_code
--      AND    fdd.period_counter         = fdp.period_counter
--      AND    fdp.period_name            = gv_period_name                -- 会計期間
--      AND    fdd.asset_id               = fab.asset_id
--      AND    fab.tag_number             = xvoh.object_code
--      AND    xvoh.machine_type          = flv.lookup_code
--      AND    flv.lookup_type            = cv_xxcff1_asset_category_id
--      AND    flv.attribute9             IN (cv_attribute9_1 ,cv_attribute9_3)
--      AND    flv.language               = cv_lang
--      AND    flv.enabled_flag           = cv_flag_y
--      AND    LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)) BETWEEN NVL(flv.start_date_active, LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)))
--                                                          AND     NVL(flv.end_date_active  , LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)))
--      GROUP BY gcc.segment1
--              ,gcc.segment3
--              ,gcc.segment4
--              ,flv.attribute10
--              ,flv.attribute11
      SELECT trn.segment1             segment1      -- 会社コード
            ,trn.segment3             segment3      -- 勘定科目
            ,trn.segment4             segment4      -- 補助科目
            ,trn.segment3_to          segment3_to   -- 振替先勘定科目
            ,trn.segment4_to          segment4_to   -- 振替先補助科目
            ,SUM(trn.amount)          amount        -- 金額
      FROM  (SELECT 
                    /*+ 
                        INDEX(fdp FA_DEPRN_PERIODS_U1)
                        INDEX(flv FND_LOOKUP_VALUES_U2)
                        INDEX(fdd FA_DEPRN_DETAIL_N2)
                        INDEX(fab FA_ADDITIONS_B_U1)
                        INDEX(xvoh XXCFF_VD_OBJECT_HEADERS_U01)
                        INDEX(gcc GL_CODE_COMBINATIONS_U1)
                     */
                    gcc.segment1             segment1       -- 会社コード
                   ,gcc.segment3             segment3       -- 勘定科目
                   ,gcc.segment4             segment4       -- 補助科目
                   ,flv.attribute10          segment3_to    -- 振替先勘定科目
                   ,flv.attribute11          segment4_to    -- 振替先補助科目
                   ,fdd.deprn_amount - fdd.deprn_adjustment_amount
                                             amount         -- 金額
             FROM   fa_deprn_periods         fdp   -- 減価償却期間
                   ,fa_deprn_detail          fdd   -- 減価償却詳細
                   ,fa_additions_b           fab   -- 資産詳細情報
                   ,gl_code_combinations     gcc   -- 勘定科目組合せマスタ
                   ,xxcff_vd_object_headers  xvoh  -- 自販機物件
                   ,fnd_lookup_values        flv   -- 自販機資産カテゴリ固定値
             WHERE  fdp.book_type_code                           = gv_fixed_assets_books         -- 台帳
             AND    fdp.period_name                              = gv_period_name                -- 会計期間
             AND    fdp.book_type_code                           = fdd.book_type_code
             AND    fdp.period_counter                           = fdd.period_counter
             AND    fdd.deprn_expense_je_line_num                IS NOT NULL
             AND    fdd.deprn_expense_ccid                       = gcc.code_combination_id
             AND    gcc.segment3                                 = flv.attribute4
             AND    gcc.segment4                                 = flv.attribute8
             AND    fdd.asset_id                                 = fab.asset_id
             AND    fab.tag_number                               = xvoh.object_code
             AND    xvoh.machine_type                            = flv.lookup_code
             AND    flv.lookup_type                              = cv_xxcff1_asset_category_id
             AND    flv.attribute9                               IN (cv_attribute9_1 ,cv_attribute9_3)
             AND    flv.language                                 = cv_lang
             AND    flv.enabled_flag                             = cv_flag_y
             AND    LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)) BETWEEN NVL(flv.start_date_active, LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)))
                                                                 AND     NVL(flv.end_date_active  , LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)))
             UNION ALL
             SELECT 
                    /*+ 
                        INDEX(fdp FA_DEPRN_PERIODS_U1)
                        INDEX(flv FND_LOOKUP_VALUES_U2)
                        INDEX(faj FA_ADJUSTMENTS_N4)
                        INDEX(fab FA_ADDITIONS_B_U1)
                        INDEX(xvoh XXCFF_VD_OBJECT_HEADERS_U01) 
                        INDEX(gcc GL_CODE_COMBINATIONS_U1)
                     */
                    gcc.segment1             segment1       -- 会社コード
                   ,gcc.segment3             segment3       -- 勘定科目
                   ,gcc.segment4             segment4       -- 補助科目
                   ,flv.attribute10          segment3_to    -- 振替先勘定科目
                   ,flv.attribute11          segment4_to    -- 振替先補助科目
                   ,faj.adjustment_amount    amount         -- 金額
             FROM   fa_deprn_periods         fdp   -- 減価償却期間
                   ,fa_adjustments           faj   -- 資産調整情報
                   ,fa_additions_b           fab   -- 資産詳細情報
                   ,gl_code_combinations     gcc   -- 勘定科目組合せマスタ
                   ,xxcff_vd_object_headers  xvoh  -- 自販機物件
                   ,fnd_lookup_values        flv   -- 自販機資産カテゴリ固定値
             WHERE  fdp.book_type_code                           = gv_fixed_assets_books         -- 台帳
             AND    fdp.period_name                              = gv_period_name                -- 会計期間
             AND    fdp.book_type_code                           = faj.book_type_code
             AND    fdp.period_counter                           = faj.period_counter_created
             AND    faj.adjustment_type                          = ct_adj_type_expense           -- 調整タイプ：EXPENSE
             AND    faj.code_combination_id                      = gcc.code_combination_id
             AND    gcc.segment3                                 = flv.attribute4
             AND    gcc.segment4                                 = flv.attribute8
             AND    faj.asset_id                                 = fab.asset_id
             AND    fab.tag_number                               = xvoh.object_code
             AND    xvoh.machine_type                            = flv.lookup_code
             AND    flv.lookup_type                              = cv_xxcff1_asset_category_id
             AND    flv.attribute9                               IN (cv_attribute9_1 ,cv_attribute9_3)
             AND    flv.language                                 = cv_lang
             AND    flv.enabled_flag                             = cv_flag_y
             AND    LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)) BETWEEN NVL(flv.start_date_active, LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)))
                                                                 AND     NVL(flv.end_date_active  , LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)))
            )     trn
      GROUP BY trn.segment1
              ,trn.segment3
              ,trn.segment4
              ,trn.segment3_to
              ,trn.segment4_to
-- 2017/06/22 Ver.1.2 Y.Shoji MOD End
      ;
    g_gl_oif_vd_rec  gl_oif_vd_cur%ROWTYPE;
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
    --コレクション削除
    --==============================================================
    delete_collections(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- 1.自販機物件のFA減価償却の仕訳データを取得
    OPEN  gl_oif_vd_cur;
    FETCH gl_oif_vd_cur
    BULK COLLECT INTO 
                      g_segment1_tab     -- 会社コード
                     ,g_segment3_tab     -- 勘定科目
                     ,g_segment4_tab     -- 補助科目
                     ,g_segment3_to_tab  -- 振替先勘定科目
                     ,g_segment4_to_tab  -- 振替先補助科目
                     ,g_amount_tab       -- 借方合計
                     ;
    --対象件数カウント
    gn_target_vd_cnt := g_segment1_tab.COUNT; -- test
    CLOSE gl_oif_vd_cur;
--
    -- 取得した件数が0件の場合
    IF ( gn_target_vd_cnt = 0 ) THEN
--
      -- 2.部門振替対象の機器区分存在チェック
      SELECT COUNT(0) cnt_chk
      INTO   ln_cnt_chk
      FROM   fnd_lookup_values     flv   -- 参照表
      WHERE  flv.lookup_type            = cv_xxcff1_asset_category_id
      AND    flv.attribute9             IN (cv_attribute9_1 ,cv_attribute9_3)
      AND    flv.language               = cv_lang
      AND    flv.enabled_flag           = cv_flag_y
      AND    LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)) BETWEEN NVL(flv.start_date_active, LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)))
                                                          AND     NVL(flv.end_date_active  , LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)))
      ;
--
      -- 取得した件数が1件以上の場合
      IF ( ln_cnt_chk > 0 ) THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                      ,cv_msg_xxcff_00165   -- 取得対象データ無し
                                                      ,cv_tkn_get_data      -- トークン'GET_DATA'
                                                      ,cv_msg_xxcff_50290)  -- 自販機物件振替
                                                      ,1
                                                      ,5000);
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    -- 取得した件数が1件以上の場合
    ELSE
      <<gl_oif_vd_loop>>
      FOR ln_loop_cnt IN 1 .. gn_target_vd_cnt LOOP
--
        -- 3.一般会計OIFテーブルへ登録（借方）
        INSERT INTO gl_interface(
           status                -- ステータス
          ,set_of_books_id       -- 会計帳簿ID
          ,accounting_date       -- 仕訳有効日付
          ,currency_code         -- 通貨コード
          ,date_created          -- 新規作成日付
          ,created_by            -- 新規作成者ID
          ,actual_flag           -- 残高タイプ
          ,user_je_category_name -- 仕訳カテゴリ名
          ,user_je_source_name   -- 仕訳ソース名
          ,segment1              -- 会社コード
          ,segment2              -- 部門コード
          ,segment3              -- 勘定科目コード
          ,segment4              -- 補助科目コード
          ,segment5              -- 顧客コード
          ,segment6              -- 企業コード
          ,segment7              -- 予備1
          ,segment8              -- 予備2
          ,entered_dr            -- 借方金額
          ,entered_cr            -- 貸方金額
          ,period_name           -- 会計期間名
          ,attribute1            -- 税区分
          ,attribute3            -- 伝票番号
          ,attribute4            -- 起票部門
          ,attribute5            -- 伝票入力者
          ,context               -- コンテキスト
        ) VALUES (
           cv_status_new                                -- ステータス
          ,g_init_rec.set_of_books_id                   -- 会計帳簿ID
          ,LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)) -- 仕訳有効日付
          ,g_init_rec.currency_code                     -- 通貨コード
          ,cd_creation_date                             -- 新規作成日付
          ,cn_created_by                                -- 新規作成者ID
          ,cv_actual_flag_a                             -- 残高タイプ
          ,gv_je_cat_vd_dep                             -- 仕訳カテゴリ名
          ,gv_je_src_vending                            -- 仕訳ソース名
          ,g_segment1_tab(ln_loop_cnt)                  -- 会社コード
          ,gv_dep_cd_chosei                             -- 部門コード
          ,g_segment3_to_tab(ln_loop_cnt)               -- 勘定科目コード
          ,g_segment4_to_tab(ln_loop_cnt)               -- 補助科目コード
          ,gv_ptnr_cd_dammy                             -- 顧客コード
          ,gv_busi_cd_dammy                             -- 企業コード
          ,gv_project_dammy                             -- 予備1
          ,gv_future_dammy                              -- 予備2
          ,g_amount_tab(ln_loop_cnt)                    -- 借方金額
          ,0                                            -- 貸方金額
          ,gv_period_name                               -- 会計期間名
          ,cv_tax_code                                  -- 税区分
          ,gv_slip_num_lease                            -- 伝票番号
          ,gt_login_dept_code                           -- 起票部門
          ,gt_login_user_name                           -- 伝票入力者
          ,gt_sob_name                                  -- 会計帳簿名
        );
--
        -- 4.一般会計OIFテーブルへ登録（貸方）
        INSERT INTO gl_interface(
           status                -- ステータス
          ,set_of_books_id       -- 会計帳簿ID
          ,accounting_date       -- 仕訳有効日付
          ,currency_code         -- 通貨コード
          ,date_created          -- 新規作成日付
          ,created_by            -- 新規作成者ID
          ,actual_flag           -- 残高タイプ
          ,user_je_category_name -- 仕訳カテゴリ名
          ,user_je_source_name   -- 仕訳ソース名
          ,segment1              -- 会社コード
          ,segment2              -- 部門コード
          ,segment3              -- 勘定科目コード
          ,segment4              -- 補助科目コード
          ,segment5              -- 顧客コード
          ,segment6              -- 企業コード
          ,segment7              -- 予備1
          ,segment8              -- 予備2
          ,entered_dr            -- 借方金額
          ,entered_cr            -- 貸方金額
          ,period_name           -- 会計期間名
          ,attribute1            -- 税区分
          ,attribute3            -- 伝票番号
          ,attribute4            -- 起票部門
          ,attribute5            -- 伝票入力者
          ,context               -- コンテキスト
        ) VALUES (
           cv_status_new                                -- ステータス
          ,g_init_rec.set_of_books_id                   -- 会計帳簿ID
          ,LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)) -- 仕訳有効日付
          ,g_init_rec.currency_code                     -- 通貨コード
          ,cd_creation_date                             -- 新規作成日付
          ,cn_created_by                                -- 新規作成者ID
          ,cv_actual_flag_a                             -- 残高タイプ
          ,gv_je_cat_vd_dep                             -- 仕訳カテゴリ名
          ,gv_je_src_vending                            -- 仕訳ソース名
          ,g_segment1_tab(ln_loop_cnt)                  -- 会社コード
          ,gv_dep_cd_chosei                             -- 部門コード
          ,g_segment3_tab(ln_loop_cnt)                  -- 勘定科目コード
          ,g_segment4_tab(ln_loop_cnt)                  -- 補助科目コード
          ,gv_ptnr_cd_dammy                             -- 顧客コード
          ,gv_busi_cd_dammy                             -- 企業コード
          ,gv_project_dammy                             -- 予備1
          ,gv_future_dammy                              -- 予備2
          ,0                                            -- 借方金額
          ,g_amount_tab(ln_loop_cnt)                    -- 貸方金額
          ,gv_period_name                               -- 会計期間名
          ,cv_tax_code                                  -- 税区分
          ,gv_slip_num_lease                            -- 伝票番号
          ,gt_login_dept_code                           -- 起票部門
          ,gt_login_user_name                           -- 伝票入力者
          ,gt_sob_name                                  -- 会計帳簿名
        );
--
        -- 成功件数カウント
        gn_normal_vd_cnt := gn_normal_vd_cnt + 1;
--
      END LOOP gl_oif_lease_loop;
--
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
  END ins_gl_oif_vd;
--
  /**********************************************************************************
   * Procedure Name   : ins_gl_oif_lease
   * Description      : 一般会計OIF登録処理（リース物件振替） (A-5)
   ***********************************************************************************/
  PROCEDURE ins_gl_oif_lease(
    ov_errbuf         OUT    VARCHAR2      --   エラー・メッセージ           --# 固定 #
   ,ov_retcode        OUT    VARCHAR2      --   リターン・コード             --# 固定 #
   ,ov_errmsg         OUT    VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_gl_oif_lease'; -- プログラム名
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
    cv_xxcff1_lease_class_check  CONSTANT VARCHAR2(30)  := 'XXCFF1_LEASE_CLASS_CHECK'; -- 参照タイプ：リース種別チェック
--
    -- *** ローカル変数 ***
    ln_cnt_chk     NUMBER DEFAULT 0;    -- チェック用件数
--
    -- *** ローカル・カーソル ***
    -- FINリース台帳の減価償却の仕訳抽出カーソル
    CURSOR gl_oif_lease_cur
    IS
-- 2017/06/22 Ver.1.2 Y.Shoji MOD Start
--      SELECT 
--             /*+
---- 2017/05/15 Ver.1.1 Y.Shoji MOD Start
----               INDEX(gjh GL_JE_HEADERS_N2)
--               LEADING(xlcv.ffvs fdp gjct gjst flv xlcv.ffv gcc gjl fdd fab xcl)
--               USE_NL(gjl gjh)
--               USE_NL(xcl xoh)
--               INDEX(xoh XXCFF_OBJECT_HEADERS_PK)
---- 2017/05/15 Ver.1.1 Y.Shoji MOD End
--             */
--             gcc.segment1           AS segment1        -- 会社コード
--            ,gcc.segment3           AS segment3        -- 勘定科目
--            ,gcc.segment4           AS segment4        -- 補助科目
--            ,flv.attribute2         AS segment3_to     -- 振替先勘定科目
--            ,flv.attribute3         AS segment4_to     -- 振替先補助科目
--            ,SUM(fdd.deprn_amount)  AS amount          -- 借方合計
--      FROM   gl_je_headers         gjh   -- 仕訳ヘッダ
--            ,gl_je_lines           gjl   -- 仕訳明細
--            ,gl_je_sources_tl      gjst  -- 仕訳ソース
--            ,gl_je_categories_tl   gjct  -- 仕訳カテゴリ
--            ,gl_code_combinations  gcc   -- 勘定科目組合せマスタ
--            ,fa_deprn_detail       fdd   -- 減価償却詳細
--            ,fa_deprn_periods      fdp   -- 減価償却期間
--            ,fa_additions_b        fab   -- 資産詳細情報
--            ,xxcff_contract_lines  xcl   -- リース契約明細
--            ,xxcff_object_headers  xoh   -- リース物件
--            ,xxcff_lease_class_v   xlcv  -- リース種別ビュー
--            ,fnd_lookup_values     flv   -- 参照表
--      WHERE  gjh.je_source              = gjst.je_source_name
--      AND    gjst.language              = cv_lang
--      AND    gjst.user_je_source_name   = gv_je_src_asset_man
--      AND    gjh.je_category            = gjct.je_category_name
--      AND    gjct.language              = cv_lang
--      AND    gjct.user_je_category_name = gv_je_cat_dep
--      AND    gjh.set_of_books_id        = g_init_rec.set_of_books_id    -- 会計帳簿ID
--      AND    gjh.period_name            = gv_period_name                -- 会計期間
--      AND    gjh.actual_flag            = cv_actual_flag_a              -- 残高タイプ
--      AND    gjh.je_header_id           = gjl.je_header_id
--      AND    gjl.reference_5            = gv_fin_lease_books            -- 台帳
--      AND    gjl.code_combination_id    = gcc.code_combination_id
--      AND    gcc.segment3               = xlcv.deprn_acct
--      AND    gcc.segment4               = xlcv.deprn_sub_acct
--      AND    gjl.je_header_id           = fdd.je_header_id
--      AND    gjl.je_line_num            = fdd.deprn_expense_je_line_num
--      AND    fdd.book_type_code         = gv_fin_lease_books            -- 台帳
--      AND    fdd.book_type_code         = fdp.book_type_code
--      AND    fdd.period_counter         = fdp.period_counter
--      AND    fdp.period_name            = gv_period_name                -- 会計期間
--      AND    fdd.asset_id               = fab.asset_id
--      AND    TO_NUMBER(fab.attribute10) = xcl.contract_line_id
--      AND    xcl.object_header_id       = xoh.object_header_id
--      AND    xoh.lease_class            = xlcv.lease_class_code
--      AND    xlcv.lease_class_code      = flv.lookup_code
--      AND    flv.lookup_type            = cv_xxcff1_lease_class_check
--      AND    flv.attribute1             = cv_flag_y
--      AND    flv.language               = cv_lang
--      AND    flv.enabled_flag           = cv_flag_y
--      AND    LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)) BETWEEN NVL(flv.start_date_active, LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)))
--                                                          AND     NVL(flv.end_date_active  , LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)))
--      GROUP BY gcc.segment1
--              ,gcc.segment3
--              ,gcc.segment4
--              ,flv.attribute2
--              ,flv.attribute3
      SELECT trn.segment1             segment1      -- 会社コード
            ,trn.segment3             segment3      -- 勘定科目
            ,trn.segment4             segment4      -- 補助科目
            ,trn.segment3_to          segment3_to   -- 振替先勘定科目
            ,trn.segment4_to          segment4_to   -- 振替先補助科目
            ,SUM(trn.amount)          amount        -- 金額
      FROM  (SELECT 
                    /*+ 
                        LEADING(a)
                        INDEX(fdp FA_DEPRN_PERIODS_U1)
                        INDEX(fdd FA_DEPRN_DETAIL_N2)
                        INDEX(fab FA_ADDITIONS_B_U1)
                        INDEX(xcl XXCFF_CONTRACT_LINES_PK)
                        INDEX(xoh XXCFF_OBJECT_HEADERS_PK)
                        INDEX(gcc GL_CODE_COMBINATIONS_U1)
                     */
                    gcc.segment1             segment1       -- 会社コード
                   ,gcc.segment3             segment3       -- 勘定科目
                   ,gcc.segment4             segment4       -- 補助科目
                   ,xlcv2.segment3_to        segment3_to    -- 振替先勘定科目
                   ,xlcv2.segment4_to        segment4_to    -- 振替先補助科目
                   ,fdd.deprn_amount - fdd.deprn_adjustment_amount
                                             amount         -- 金額
             FROM   
                    fa_deprn_periods      fdp   -- 減価償却期間
                   ,fa_deprn_detail       fdd   -- 減価償却詳細
                   ,fa_additions_b        fab   -- 資産詳細情報
                   ,gl_code_combinations  gcc   -- 勘定科目組合せマスタ
                   ,xxcff_contract_lines  xcl   -- リース契約明細
                   ,xxcff_object_headers  xoh   -- リース物件
                   ,(SELECT 
                            /*+ 
                                QB_NAME(a)
                                LEADING(flv xlcv.ffvs xlcv.ffvt xlcv.ffv)
                                INDEX(flv FND_LOOKUP_VALUES_U2)
                                INDEX(xlcv.ffv FND_FLEX_VALUES_N1)
                                INDEX(xlcv.ffvt FND_FLEX_VALUES_TL_U1)
                                INDEX(xlcv.ffvt FND_FLEX_VALUE_SETS_U2)
                             */
                            xlcv.lease_class_code  lease_class_code -- リース種別コード
                           ,xlcv.deprn_acct        deprn_acct       -- 振替元勘定科目
                           ,xlcv.deprn_sub_acct    deprn_sub_acct   -- 振替元補助科目
                           ,flv.attribute2         segment3_to      -- 振替先勘定科目
                           ,flv.attribute3         segment4_to      -- 振替先補助科目
                     FROM   xxcff_lease_class_v   xlcv  -- リース種別ビュー
                           ,fnd_lookup_values     flv   -- リース種別チェック
                     WHERE  flv.lookup_code                              = xlcv.lease_class_code
                     AND    flv.lookup_type                              = cv_xxcff1_lease_class_check
                     AND    flv.attribute1                               = cv_flag_y
                     AND    flv.language                                 = cv_lang
                     AND    flv.enabled_flag                             = cv_flag_y
                     AND    LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)) BETWEEN NVL(flv.start_date_active, LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)))
                                                                         AND     NVL(flv.end_date_active  , LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)))
                    )                          xlcv2
             WHERE  fdp.book_type_code         = gv_fin_lease_books            -- 台帳
             AND    fdp.period_name            = gv_period_name                -- 会計期間
             AND    fdp.book_type_code         = fdd.book_type_code
             AND    fdp.period_counter         = fdd.period_counter
             AND    fdd.deprn_expense_je_line_num IS NOT NULL
             AND    fdd.deprn_expense_ccid     = gcc.code_combination_id
             AND    gcc.segment3               = xlcv2.deprn_acct 
             AND    gcc.segment4               = xlcv2.deprn_sub_acct
             AND    fdd.asset_id               = fab.asset_id
             AND    TO_NUMBER(fab.attribute10) = xcl.contract_line_id
             AND    xcl.object_header_id       = xoh.object_header_id
             AND    xoh.lease_class            = xlcv2.lease_class_code
             UNION ALL
             SELECT 
                    /*+ 
                        LEADING(b)
                        INDEX(fdp FA_DEPRN_PERIODS_U1)
                        INDEX(faj FA_ADJUSTMENTS_N4)
                        INDEX(fab FA_ADDITIONS_B_U1)
                        INDEX(xcl XXCFF_CONTRACT_LINES_PK)
                        INDEX(xoh XXCFF_OBJECT_HEADERS_PK)
                        INDEX(gcc GL_CODE_COMBINATIONS_U1)
                     */
                    gcc.segment1             segment1       -- 会社コード
                   ,gcc.segment3             segment3       -- 勘定科目
                   ,gcc.segment4             segment4       -- 補助科目
                   ,xlcv2.segment3_to        segment3_to    -- 振替先勘定科目
                   ,xlcv2.segment4_to        segment4_to    -- 振替先補助科目
                   ,faj.adjustment_amount    amount         -- 金額
             FROM   fa_deprn_periods      fdp   -- 減価償却期間
                   ,fa_adjustments        faj   -- 資産調整情報
                   ,fa_additions_b        fab   -- 資産詳細情報
                   ,gl_code_combinations  gcc   -- 勘定科目組合せマスタ
                   ,xxcff_contract_lines  xcl   -- リース契約明細
                   ,xxcff_object_headers  xoh   -- リース物件
                   ,(SELECT 
                            /*+ 
                                QB_NAME(b)
                                LEADING(flv xlcv.ffvs xlcv.ffvt xlcv.ffv)
                                INDEX(flv FND_LOOKUP_VALUES_U2)
                                INDEX(xlcv.ffv FND_FLEX_VALUES_N1)
                                INDEX(xlcv.ffvt FND_FLEX_VALUES_TL_U1)
                                INDEX(xlcv.ffvt FND_FLEX_VALUE_SETS_U2)
                             */
                            xlcv.lease_class_code  lease_class_code -- リース種別コード
                           ,xlcv.deprn_acct        deprn_acct       -- 振替元勘定科目
                           ,xlcv.deprn_sub_acct    deprn_sub_acct   -- 振替元補助科目
                           ,flv.attribute2         segment3_to      -- 振替先勘定科目
                           ,flv.attribute3         segment4_to      -- 振替先補助科目
                     FROM   xxcff_lease_class_v   xlcv  -- リース種別ビュー
                           ,fnd_lookup_values     flv   -- リース種別チェック
                     WHERE  flv.lookup_code                              = xlcv.lease_class_code
                     AND    flv.lookup_type                              = cv_xxcff1_lease_class_check
                     AND    flv.attribute1                               = cv_flag_y
                     AND    flv.language                                 = cv_lang
                     AND    flv.enabled_flag                             = cv_flag_y
                     AND    LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)) BETWEEN NVL(flv.start_date_active, LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)))
                                                                         AND     NVL(flv.end_date_active  , LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)))
                    )                          xlcv2
             WHERE  fdp.book_type_code         = gv_fin_lease_books            -- 台帳
             AND    fdp.period_name            = gv_period_name                -- 会計期間
             AND    fdp.book_type_code         = faj.book_type_code
             AND    fdp.period_counter         = faj.period_counter_created
             AND    faj.adjustment_type        = ct_adj_type_expense           -- 調整タイプ：EXPENSE
             AND    faj.code_combination_id    = gcc.code_combination_id
             AND    gcc.segment3               = xlcv2.deprn_acct 
             AND    gcc.segment4               = xlcv2.deprn_sub_acct
             AND    faj.asset_id               = fab.asset_id
             AND    TO_NUMBER(fab.attribute10) = xcl.contract_line_id
             AND    xcl.object_header_id       = xoh.object_header_id
             AND    xoh.lease_class            = xlcv2.lease_class_code
             ) trn
      GROUP BY trn.segment1
              ,trn.segment3
              ,trn.segment4
              ,trn.segment3_to
              ,trn.segment4_to
-- 2017/06/22 Ver.1.2 Y.Shoji MOD End
      ;
    g_gl_oif_lease_rec  gl_oif_lease_cur%ROWTYPE;
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
    --コレクション削除
    --==============================================================
    delete_collections(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- 1.リース物件のFA減価償却の仕訳データを取得
    OPEN  gl_oif_lease_cur;
    FETCH gl_oif_lease_cur
    BULK COLLECT INTO 
                      g_segment1_tab     -- 会社コード
                     ,g_segment3_tab     -- 勘定科目
                     ,g_segment4_tab     -- 補助科目
                     ,g_segment3_to_tab  -- 振替先勘定科目
                     ,g_segment4_to_tab  -- 振替先補助科目
                     ,g_amount_tab       -- 借方合計
                     ;
    --対象件数カウント
    gn_target_lease_cnt := g_segment1_tab.COUNT; -- test
    CLOSE gl_oif_lease_cur;
--
    -- 取得した件数が0件の場合
    IF ( gn_target_lease_cnt = 0 ) THEN
--
      -- 2.部門振替対象のリース種別存在チェック
      SELECT COUNT(0) cnt_chk
      INTO   ln_cnt_chk
      FROM   fnd_lookup_values     flv   -- 参照表
      WHERE  flv.lookup_type            = cv_xxcff1_lease_class_check
      AND    flv.attribute1             = cv_flag_y
      AND    flv.language               = cv_lang
      AND    flv.enabled_flag           = cv_flag_y
      AND    LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)) BETWEEN NVL(flv.start_date_active, LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)))
                                                          AND     NVL(flv.end_date_active  , LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)))
      ;
--
      -- 取得した件数が1件以上の場合
      IF ( ln_cnt_chk > 0 ) THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                      ,cv_msg_xxcff_00165   -- 取得対象データ無し
                                                      ,cv_tkn_get_data      -- トークン'GET_DATA'
                                                      ,cv_msg_xxcff_50289)  -- リース物件振替
                                                      ,1
                                                      ,5000);
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    -- 取得した件数が1件以上の場合
    ELSE
      <<gl_oif_lease_loop>>
      FOR ln_loop_cnt IN 1 .. gn_target_lease_cnt LOOP
--
        -- 3.一般会計OIFテーブルへ登録（借方）
        INSERT INTO gl_interface(
           status                -- ステータス
          ,set_of_books_id       -- 会計帳簿ID
          ,accounting_date       -- 仕訳有効日付
          ,currency_code         -- 通貨コード
          ,date_created          -- 新規作成日付
          ,created_by            -- 新規作成者ID
          ,actual_flag           -- 残高タイプ
          ,user_je_category_name -- 仕訳カテゴリ名
          ,user_je_source_name   -- 仕訳ソース名
          ,segment1              -- 会社コード
          ,segment2              -- 部門コード
          ,segment3              -- 勘定科目コード
          ,segment4              -- 補助科目コード
          ,segment5              -- 顧客コード
          ,segment6              -- 企業コード
          ,segment7              -- 予備1
          ,segment8              -- 予備2
          ,entered_dr            -- 借方金額
          ,entered_cr            -- 貸方金額
          ,period_name           -- 会計期間名
          ,attribute1            -- 税区分
          ,attribute3            -- 伝票番号
          ,attribute4            -- 起票部門
          ,attribute5            -- 伝票入力者
          ,context               -- コンテキスト
        ) VALUES (
           cv_status_new                                -- ステータス
          ,g_init_rec.set_of_books_id                   -- 会計帳簿ID
          ,LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)) -- 仕訳有効日付
          ,g_init_rec.currency_code                     -- 通貨コード
          ,cd_creation_date                             -- 新規作成日付
          ,cn_created_by                                -- 新規作成者ID
          ,cv_actual_flag_a                             -- 残高タイプ
          ,gv_je_cat_vd_dep                             -- 仕訳カテゴリ名
          ,gv_je_src_lease                              -- 仕訳ソース名
          ,g_segment1_tab(ln_loop_cnt)                  -- 会社コード
          ,gv_dep_cd_chosei                             -- 部門コード
          ,g_segment3_to_tab(ln_loop_cnt)               -- 勘定科目コード
          ,g_segment4_to_tab(ln_loop_cnt)               -- 補助科目コード
          ,gv_ptnr_cd_dammy                             -- 顧客コード
          ,gv_busi_cd_dammy                             -- 企業コード
          ,gv_project_dammy                             -- 予備1
          ,gv_future_dammy                              -- 予備2
          ,g_amount_tab(ln_loop_cnt)                    -- 借方金額
          ,0                                            -- 貸方金額
          ,gv_period_name                               -- 会計期間名
          ,cv_tax_code                                  -- 税区分
          ,gv_slip_num_lease                            -- 伝票番号
          ,gt_login_dept_code                           -- 起票部門
          ,gt_login_user_name                           -- 伝票入力者
          ,gt_sob_name                                  -- 会計帳簿名
        );
--
        -- 4.一般会計OIFテーブルへ登録（貸方）
        INSERT INTO gl_interface(
           status                -- ステータス
          ,set_of_books_id       -- 会計帳簿ID
          ,accounting_date       -- 仕訳有効日付
          ,currency_code         -- 通貨コード
          ,date_created          -- 新規作成日付
          ,created_by            -- 新規作成者ID
          ,actual_flag           -- 残高タイプ
          ,user_je_category_name -- 仕訳カテゴリ名
          ,user_je_source_name   -- 仕訳ソース名
          ,segment1              -- 会社コード
          ,segment2              -- 部門コード
          ,segment3              -- 勘定科目コード
          ,segment4              -- 補助科目コード
          ,segment5              -- 顧客コード
          ,segment6              -- 企業コード
          ,segment7              -- 予備1
          ,segment8              -- 予備2
          ,entered_dr            -- 借方金額
          ,entered_cr            -- 貸方金額
          ,period_name           -- 会計期間名
          ,attribute1            -- 税区分
          ,attribute3            -- 伝票番号
          ,attribute4            -- 起票部門
          ,attribute5            -- 伝票入力者
          ,context               -- コンテキスト
        ) VALUES (
           cv_status_new                                -- ステータス
          ,g_init_rec.set_of_books_id                   -- 会計帳簿ID
          ,LAST_DAY(TO_DATE(gv_period_name ,cv_yyyymm)) -- 仕訳有効日付
          ,g_init_rec.currency_code                     -- 通貨コード
          ,cd_creation_date                             -- 新規作成日付
          ,cn_created_by                                -- 新規作成者ID
          ,cv_actual_flag_a                             -- 残高タイプ
          ,gv_je_cat_vd_dep                             -- 仕訳カテゴリ名
          ,gv_je_src_lease                              -- 仕訳ソース名
          ,g_segment1_tab(ln_loop_cnt)                  -- 会社コード
          ,gv_dep_cd_chosei                             -- 部門コード
          ,g_segment3_tab(ln_loop_cnt)                  -- 勘定科目コード
          ,g_segment4_tab(ln_loop_cnt)                  -- 補助科目コード
          ,gv_ptnr_cd_dammy                             -- 顧客コード
          ,gv_busi_cd_dammy                             -- 企業コード
          ,gv_project_dammy                             -- 予備1
          ,gv_future_dammy                              -- 予備2
          ,0                                            -- 借方金額
          ,g_amount_tab(ln_loop_cnt)                    -- 貸方金額
          ,gv_period_name                               -- 会計期間名
          ,cv_tax_code                                  -- 税区分
          ,gv_slip_num_lease                            -- 伝票番号
          ,gt_login_dept_code                           -- 起票部門
          ,gt_login_user_name                           -- 伝票入力者
          ,gt_sob_name                                  -- 会計帳簿名
        );
--
        -- 成功件数カウント
        gn_normal_lease_cnt := gn_normal_lease_cnt + 1;
--
      END LOOP gl_oif_lease_loop;
--
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
  END ins_gl_oif_lease;
--
  /**********************************************************************************
   * Procedure Name   : chk_data_exist
   * Description      : 前回作成済み部門振替仕訳存在チェック(A-4)
   ***********************************************************************************/
  PROCEDURE chk_data_exist(
    ov_errbuf      OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg      OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_data_exist'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
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
    ln_cnt_chk     NUMBER DEFAULT 0;    -- チェック用件数
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
    --==============================================================
    -- 1.一般会計OIFにリース物件の部門振替仕訳が存在しないことを確認
    --==============================================================
    SELECT COUNT(0) cnt_chk
    INTO   ln_cnt_chk
    FROM   gl_interface    gi -- 一般会計OIF
    WHERE  gi.user_je_source_name   = gv_je_src_lease   -- 仕訳ソース_リース
    AND    gi.user_je_category_name = gv_je_cat_vd_dep  -- 仕訳カテゴリ_自販機部門振替
    AND    gi.period_name           = gv_period_name
    ;
--
    -- 取得した件数が1件以上の場合
    IF ( ln_cnt_chk > 0 ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_xxcff_00246   -- リース物件仕訳存在チェック(一般会計OIF)
                                                    ,cv_tkn_period        -- トークン'PERIOD_NAME'
                                                    ,gv_period_name)      -- 会計期間名
                                                    ,1
                                                    ,5000);
      lv_errbuf  := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 2.一般会計OIFに自販機物件の部門振替仕訳が存在しないことを確認
    --==============================================================
    SELECT COUNT(0) cnt_chk
    INTO   ln_cnt_chk
    FROM   gl_interface    gi -- 一般会計OIF
    WHERE  gi.user_je_source_name   = gv_je_src_vending  -- 仕訳ソース_自販機物件
    AND    gi.user_je_category_name = gv_je_cat_vd_dep   -- 仕訳カテゴリ_自販機部門振替
    AND    gi.period_name           = gv_period_name
    ;
--
    -- 取得した件数が1件以上の場合
    IF ( ln_cnt_chk > 0 ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_xxcff_00247   -- 自販機物件仕訳存在チェック(一般会計OIF)
                                                    ,cv_tkn_period        -- トークン'PERIOD_NAME'
                                                    ,gv_period_name)      -- 会計期間名
                                                    ,1
                                                    ,5000);
      lv_errbuf  := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 3.仕訳ヘッダにリース物件の部門振替仕訳が存在しないことを確認
    --==============================================================
    SELECT COUNT(0) cnt_chk
    INTO   ln_cnt_chk
    FROM   gl_je_headers       gjh  -- 仕訳ヘッダ
          ,gl_je_sources_tl    gjst -- 仕訳ソース
          ,gl_je_categories_tl gjct -- 仕訳カテゴリ
    WHERE  gjh.je_source              = gjst.je_source_name
    AND    gjst.language              = cv_lang
    AND    gjst.user_je_source_name   = gv_je_src_lease          -- 仕訳ソース_リース
    AND    gjh.je_category            = gjct.je_category_name
    AND    gjct.language              = cv_lang
    AND    gjct.user_je_category_name = gv_je_cat_vd_dep         -- 仕訳カテゴリ_自販機部門振替
    AND    gjh.period_name            = gv_period_name
    ;
--
    -- 取得した件数が1件以上の場合
    IF ( ln_cnt_chk > 0 ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_xxcff_00248   -- リース物件部門振替仕訳存在チェック（仕訳ヘッダ）
                                                    ,cv_tkn_period        -- トークン'PERIOD_NAME'
                                                    ,gv_period_name)      -- 会計期間名
                                                    ,1
                                                    ,5000);
      lv_errbuf  := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 4.仕訳ヘッダに自販機物件の部門振替仕訳が存在しないことを確認
    --==============================================================
    SELECT COUNT(0) cnt_chk
    INTO   ln_cnt_chk
    FROM   gl_je_headers       gjh  -- 仕訳ヘッダ
          ,gl_je_sources_tl    gjst -- 仕訳ソース
          ,gl_je_categories_tl gjct -- 仕訳カテゴリ
    WHERE  gjh.je_source              = gjst.je_source_name
    AND    gjst.language              = cv_lang
    AND    gjst.user_je_source_name   = gv_je_src_vending      -- 仕訳ソース_自販機物件
    AND    gjh.je_category            = gjct.je_category_name
    AND    gjct.language              = cv_lang
    AND    gjct.user_je_category_name = gv_je_cat_vd_dep       -- 仕訳カテゴリ_自販機部門振替
    AND    gjh.period_name            = gv_period_name
    ;
--
    -- 取得した件数が1件以上の場合
    IF ( ln_cnt_chk > 0 ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_xxcff_00249   -- 自販機物件部門振替仕訳存在チェック（仕訳ヘッダ）
                                                    ,cv_tkn_period        -- トークン'PERIOD_NAME'
                                                    ,gv_period_name)      -- 会計期間名
                                                    ,1
                                                    ,5000);
      lv_errbuf  := lv_errmsg;
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
  END chk_data_exist;
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
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_closing_status_o   CONSTANT VARCHAR2(1)  := 'O';      -- ステータス：オープン
    cv_app_short_name     CONSTANT VARCHAR2(5)  := 'SQLGL';  -- GL
--
    -- *** ローカル変数 ***
    ln_cnt_chk            NUMBER DEFAULT 0;    -- チェック用件数
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
    --======================================
    -- GL会計期間チェック
    --======================================
    SELECT count(0)   cnt_chk
    INTO   ln_cnt_chk
    FROM   gl_period_statuses  gps   -- 会計カレンダステータス
          ,fnd_application     fa    -- アプリケーション
    WHERE  gps.period_name            = gv_period_name
    AND    gps.closing_status         = cv_closing_status_o
    AND    gps.adjustment_period_flag = cv_flag_n
    AND    gps.set_of_books_id        = g_init_rec.set_of_books_id
    AND    gps.application_id         = fa.application_id
    AND    fa.application_short_name  = cv_app_short_name
    ;
--
    -- 会計期間ステータス取得
    IF ( ln_cnt_chk = 0 ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_xxcff_00130   -- GL会計期間チェックエラー
                                                    ,cv_tkn_period        -- トークン'PERIOD_NAME'
                                                    ,gv_period_name)      -- 会計期間名
                                                    ,1
                                                    ,5000);
      lv_errbuf  := lv_errmsg;
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
  END chk_period;
--
  /**********************************************************************************
   * Procedure Name   : get_profile_values
   * Description      : プロファイル取得処理(A-2)
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
    -- 1.台帳名_FINリース台帳
    gv_fin_lease_books := FND_PROFILE.VALUE(cv_fin_lease_books);
    IF (gv_fin_lease_books IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_xxcff_00020   -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_xxcff_50287)  -- XXCFF:台帳名_FINリース台帳
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 2.台帳名
    gv_fixed_assets_books := FND_PROFILE.VALUE(cv_fixed_assets_books);
    IF (gv_fixed_assets_books IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_xxcff_00020   -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_xxcff_50273)  -- XXCFF:台帳名
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 3.仕訳ソース_リース
    gv_je_src_lease := FND_PROFILE.VALUE(cv_je_src_lease);
    IF (gv_je_src_lease IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_xxcff_00020   -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_xxcff_50146)  -- XXCFF:仕訳ソース_リース
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 4.仕訳ソース_自販機物件
    gv_je_src_vending := FND_PROFILE.VALUE(cv_je_src_vending);
    IF (gv_je_src_vending IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_xxcff_00020   -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_xxcff_50255)  -- XXCFF:仕訳ソース_自販機物件
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 5.仕訳ソース_資産管理
    gv_je_src_asset_man := FND_PROFILE.VALUE(cv_je_src_asset_man);
    IF (gv_je_src_asset_man IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_xxcff_00020   -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_xxcff_50291)  -- XXCFF:仕訳ソース_資産管理
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 6.仕訳カテゴリ_自販機部門振替
    gv_je_cat_vd_dep := FND_PROFILE.VALUE(cv_je_cat_vd_dep);
    IF (gv_je_cat_vd_dep IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_xxcff_00020   -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_xxcff_50288)  -- XXCFF:仕訳カテゴリ_自販機部門振替
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 7.仕訳カテゴリ_減価償却
    gv_je_cat_dep := FND_PROFILE.VALUE(cv_je_cat_dep);
    IF (gv_je_cat_dep IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_xxcff_00020   -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_xxcff_50292)  -- XXCFF:仕訳カテゴリ_減価償却
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 8.部門コード_調整部門
    gv_dep_cd_chosei := FND_PROFILE.VALUE(cv_dep_cd_chosei);
    IF (gv_dep_cd_chosei IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_xxcff_00020   -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_xxcff_50078)  -- XXCFF:部門コード_調整部門
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 9.顧客コード_定義なし
    gv_ptnr_cd_dammy := FND_PROFILE.VALUE(cv_ptnr_cd_dammy);
    IF (gv_ptnr_cd_dammy IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_xxcff_00020   -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_xxcff_50079)  -- XXCFF:顧客コード_定義なし
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 10.企業コード_定義なし
    gv_busi_cd_dammy := FND_PROFILE.VALUE(cv_busi_cd_dammy);
    IF (gv_busi_cd_dammy IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_xxcff_00020   -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_xxcff_50080)  -- XXCFF:企業コード_定義なし
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 11.予備1_定義なし
    gv_project_dammy := FND_PROFILE.VALUE(cv_project_dammy);
    IF (gv_project_dammy IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_xxcff_00020   -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_xxcff_50081)  -- XXCFF:予備1_定義なし
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 12.予備2_定義なし
    gv_future_dammy := FND_PROFILE.VALUE(cv_future_dammy);
    IF (gv_future_dammy IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_xxcff_00020   -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_xxcff_50082)  -- XXCFF:予備2_定義なし
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 13.伝票番号_リース
    gv_slip_num_lease := FND_PROFILE.VALUE(cv_slip_num_lease);
    IF (gv_slip_num_lease IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_xxcff_00020   -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_xxcff_50155)  -- XXCFF:伝票番号_リース
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
    -- 初期値情報の取得
    xxcff_common1_pkg.init(
       or_init_rec => g_init_rec           -- 初期値情報
      ,ov_errbuf   => lv_errbuf            -- エラー・メッセージ           --# 固定 #
      ,ov_retcode  => lv_retcode           -- リターン・コード             --# 固定 #
      ,ov_errmsg   => lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> ov_retcode) THEN
      RAISE global_api_expt;
    END IF;
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
    -- コンカレントパラメータ値出力(ログ)
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
    --===========================================
    -- ユーザ情報(ログインユーザ、所属部門)取得
    --===========================================
    BEGIN
      SELECT xuv.user_name   login_user_name   --ログインユーザ
            ,ppf.attribute28 login_dept_code   --起票部門 (所属部門)
      INTO   gt_login_user_name
            ,gt_login_dept_code
      FROM   xx03_users_v xuv
            ,per_people_f ppf
      WHERE  xuv.user_id     = cn_created_by
      AND    xuv.employee_id = ppf.person_id
      AND    SYSDATE         BETWEEN ppf.effective_start_date
                             AND     ppf.effective_end_date
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cff       -- XXCFF
                                                       ,cv_msg_xxcff_00181   -- 取得エラー
                                                       ,cv_tkn_table         -- トークン'TABLE_NAME'
                                                       ,cv_msg_xxcff_50154   -- ログイン(ユーザ名,所属部門)情報
                                                       ,cv_tkn_key_name      -- トークン'KEY_NAME'
                                                       ,cv_msg_xxcff_50167   -- ログインユーザID=
                                                       ,cv_tkn_key_val       -- トークン'KEY_VAL'
                                                       ,cn_created_by)       -- ログインユーザID
                                                       ,1
                                                       ,5000);
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --===========================================
    -- 会計帳簿名称取得
    --===========================================
    BEGIN
      SELECT gsob.name   sob_name   --会計帳簿名
      INTO   gt_sob_name
      FROM   gl_sets_of_books gsob
      WHERE  gsob.set_of_books_id = g_init_rec.set_of_books_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cff              -- XXCFF
                                                       ,cv_msg_xxcff_00181          -- 取得エラー
                                                       ,cv_tkn_table                -- トークン'TABLE_NAME'
                                                       ,cv_msg_xxcff_50160          -- 会計帳簿名
                                                       ,cv_tkn_key_name             -- トークン'KEY_NAME'
                                                       ,cv_msg_xxcff_50168          -- 会計帳簿ID=
                                                       ,cv_tkn_key_val              -- トークン'KEY_VAL'
                                                       ,g_init_rec.set_of_books_id) -- 会計帳簿ID
                                                       ,1
                                                       ,5000);
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
    END;
--
  EXCEPTION
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
--
    -- グローバル変数の初期化
    gn_warn_cnt           := 0;
    gn_target_lease_cnt   := 0;
    gn_target_vd_cnt      := 0;
    gn_normal_lease_cnt   := 0;
    gn_normal_vd_cnt      := 0;
    gn_error_cnt          := 0;
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
    -- プロファイル値取得 (A-2)
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
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- 前回作成済み部門振替仕訳存在チェック (A-4)
    -- ============================================
    chk_data_exist(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ====================================
    -- 一般会計OIF登録処理（リース物件振替） (A-5)
    -- ====================================
    ins_gl_oif_lease(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ====================================
    -- 一般会計OIF登録処理（自販機物件振替） (A-6)
    -- ====================================
    ins_gl_oif_vd(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
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
    iv_period_name IN  VARCHAR2       -- 1.会計期間名
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
       iv_period_name -- 会計期間名
      ,lv_errbuf      -- エラー・メッセージ           --# 固定 #
      ,lv_retcode     -- リターン・コード             --# 固定 #
      ,lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --===============================================================
    -- エラー時の出力件数設定
    --===============================================================
    IF (lv_retcode = cv_status_error) THEN
      -- 成功件数をゼロにクリアする
      gn_normal_lease_cnt      := 0;
      gn_normal_vd_cnt         := 0;
      -- エラー件数に対象件数を設定する
      gn_error_cnt             := gn_target_lease_cnt + gn_target_vd_cnt;
    END IF;
--
    --===============================================================
    -- 一般会計OIF登録処理における件数出力
    --===============================================================
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    -- 自販機物件仕訳作成メッセージ出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff
                    ,iv_name         => cv_msg_xxcff_00115
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --===============================================================
    -- リース物件部門振替仕訳件数
    --===============================================================
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --リース物件部門振替仕訳件数
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff
                    ,iv_name         => cv_msg_xxcff_00250
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
                    ,iv_token_value1 => TO_CHAR(gn_target_lease_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_lease_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --===============================================================
    -- 自販機物件部門振替仕訳件数
    --===============================================================
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --自販機物件部門振替仕訳件数
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff
                    ,iv_name         => cv_msg_xxcff_00251
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
                    ,iv_token_value1 => TO_CHAR(gn_target_vd_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_vd_cnt)
                   );
    FND_FILE.PUT_LINE(
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
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
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
END XXCFF017A07C;
/
