CREATE OR REPLACE PACKAGE BODY XXCMM004A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM004A06C(body)
 * Description      : 原価一覧作成
 * MD.050           : 原価一覧作成 MD050_CMM_004_A06
 * Version          : Draft2C
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  proc_init              初期処理
 *  get_cmp_cost           コンポーネント原価取得
 *  get_item_mst           品目情報取得
 *  output_csv             CSVファイル出力プロシージャ
 *  submain                処理の実行部
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/11    1.0   N.Nishimura      main新規作成
 *  2009/01/16    1.1   R.Takigawa       CSV形式データ出力エラーを削除
 *                                       品目共通固定値定義
 *  2009/04/08    1.2   H.Yoshikawa      障害No.T1_0184 対応
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_error;  --異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER  := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE    := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER  := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE    := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER  := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER  := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER  := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER  := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE    := SYSDATE;                    --PROGRAM_UPDATE_DATE
  cv_msg_part               CONSTANT VARCHAR2(3)  := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3)  := '.';
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
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name           CONSTANT VARCHAR2(100) := 'XXCMM004A06C';    -- パッケージ名
  cv_app_name_xxcmm     CONSTANT VARCHAR2(5)   := 'XXCMM';           -- アプリケーション短縮名
  -- エラーメッセージ
  cv_msg_xxcmm_00470    CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00470'; --対象データ無し
  cv_msg_xxcmm_00471    CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00471'; --CSV形式データ出力エラー
  cv_msg_xxcmm_00472    CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00472'; --CSVヘッダ
  -- ルックアップ
  cv_lookup_cost_cmpt   CONSTANT VARCHAR2(20)  := 'XXCMM1_COST_CMPT';        -- コンポーネント原価種別
  cv_lookup_csv_head    CONSTANT VARCHAR2(30)  := 'XXCMM1_004A06_ITEMLIST';  -- 項目タイトル
  -- トークン
  cv_tkn_year           CONSTANT VARCHAR2(10)  := 'YEAR';
  cv_tkn_cost_type      CONSTANT VARCHAR2(10)  := 'COST_TYPE';
  -- 定数
  cv_inp_calendar_code  CONSTANT VARCHAR2(30)  := '標準原価対象年度：';   -- 標準原価対象年度
  cv_inp_cost_type      CONSTANT VARCHAR2(30)  := '営業原価タイプ：';     -- 営業原価タイプ
  cv_seisakugun         CONSTANT VARCHAR2(20)  := '政策群コード';    -- 政策群コード
  cv_item_product_class CONSTANT VARCHAR2(20)  := '商品製品区分';    -- 商品製品区分
  cv_cost_cmpnt_01gen   CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_cost_cmpnt_01gen;   -- 原料
  cv_cost_cmpnt_02sai   CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_cost_cmpnt_02sai;   -- 再製費
  cv_cost_cmpnt_03szi   CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_cost_cmpnt_03szi;   -- 資材費
  cv_cost_cmpnt_04hou   CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_cost_cmpnt_04hou;   -- 包装費
  cv_cost_cmpnt_05gai   CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_cost_cmpnt_05gai;   -- 外注加工費
  cv_cost_cmpnt_06hkn   CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_cost_cmpnt_06hkn;   -- 保管費
  cv_cost_cmpnt_07kei   CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_cost_cmpnt_07kei;   -- その他経費
  cv_cost_type1         CONSTANT VARCHAR2(10)  := '確定済';     -- 原価タイプ:確定済
  cv_emargency_flag     CONSTANT VARCHAR2(1)   := '*';          -- 警告
  cv_update_div         CONSTANT VARCHAR2(1)   := 'D';          -- 更新区分
  cv_n                  CONSTANT VARCHAR2(1)   := 'N';          -- 適用フラグ
  cv_apply_date         CONSTANT VARCHAR2(10)  := '9999/99/99'; -- デフォルト日付
  cv_date_fmt_std        CONSTANT VARCHAR2(10) := xxcmm_004common_pkg.cv_date_fmt_std; -- デフォルト日付
  cv_space_1            CONSTANT VARCHAR2(1)   := ' ';          -- スペース1つ
  cv_space_2            CONSTANT VARCHAR2(2)   := '  ';         -- スペース2つ
  cv_sep_com            CONSTANT VARCHAR2(1)   := ',';          -- CSV形式データ区切り文字
  cv_csv_file           CONSTANT VARCHAR2(1)   := '0';          -- CSVファイル
  cv_output_log         CONSTANT VARCHAR2(3)   := 'LOG';
  cv_item_code_from     CONSTANT VARCHAR2(7)   := '0000001';    -- 品名コード開始
  cv_item_code_to       CONSTANT VARCHAR2(7)   := '3999999';    -- 品名コード終了
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- CSVデータ保存用レコード型変数
  TYPE g_item_mst_rtype IS RECORD(
    v_seisakugun            VARCHAR2(8),   -- 政策群コード
    v_item_no               VARCHAR2(7),   -- 品名コード
    v_cmpnt_cost1           VARCHAR2(12),  -- 原料
    v_cmpnt_cost2           VARCHAR2(12),  -- 再製費
    v_cmpnt_cost3           VARCHAR2(12),  -- 資材費
    v_cmpnt_cost4           VARCHAR2(12),  -- 包装費
    v_cmpnt_cost5           VARCHAR2(12),  -- 外注加工費
    v_cmpnt_cost6           VARCHAR2(12),  -- 保管費
    v_cmpnt_cost7           VARCHAR2(12),  -- その他経費
    v_cmpnt_cost            VARCHAR2(12),  -- 標準原価計
    v_discrete_cost         VARCHAR2(12),  -- 営業原価
    v_emargency_flag        VARCHAR2(6),   -- 警告
    v_update_div            VARCHAR2(10),  -- 更新区分
    v_apply_date            VARCHAR2(12),  -- 適用開始日
    v_item_name             VARCHAR2(42),  -- 正式名
    v_item_short_name       VARCHAR2(22),  -- 略称
    v_item_id               VARCHAR2(8)    -- 品目ID
  );
  --
  -- 品目情報格納用テーブル型定義
  TYPE g_item_mst_ttype IS TABLE OF g_item_mst_rtype INDEX BY PLS_INTEGER;
  g_item_mst_tab    g_item_mst_ttype;    -- 結合配列の定義
  --
  -- 標準原価格納用レコード型変数
  TYPE g_cost_rtype IS RECORD(
    cmpnt_cost1  cm_cmpt_dtl.cmpnt_cost%TYPE,  -- 原料
    cmpnt_cost2  cm_cmpt_dtl.cmpnt_cost%TYPE,  -- 再製費
    cmpnt_cost3  cm_cmpt_dtl.cmpnt_cost%TYPE,  -- 資材費
    cmpnt_cost4  cm_cmpt_dtl.cmpnt_cost%TYPE,  -- 包装費
    cmpnt_cost5  cm_cmpt_dtl.cmpnt_cost%TYPE,  -- 外注加工費
    cmpnt_cost6  cm_cmpt_dtl.cmpnt_cost%TYPE,  -- 保管費
    cmpnt_cost7  cm_cmpt_dtl.cmpnt_cost%TYPE,  -- その他経費
    cmpnt_cost   cm_cmpt_dtl.cmpnt_cost%TYPE   -- 標準原価計
  );
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_process_date  DATE;          -- 業務日付
  gv_calendar_code VARCHAR2(4);   -- カレンダコード
  gv_cost_type     VARCHAR2(10);  -- コストタイプ
--
  /**********************************************************************************
   * Procedure Name   : proc_init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE proc_init(
    iv_calendar_code     IN  VARCHAR2,     -- 標準原価対象年度
    iv_cost_type         IN  VARCHAR2,     -- 営業原価タイプ
    ov_errbuf            OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode           OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg            OUT VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_init'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf     VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);     -- リターン・コード
    lv_errmsg     VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_step       VARCHAR2(100);   -- ステップ
    lv_msg_token  VARCHAR2(100);   -- デバッグ用トークン
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
    -- 業務日付取得
    lv_step      := 'A-1.1';
    lv_msg_token := '業務日付取得';
    gd_process_date := xxccp_common_pkg2.get_process_date;
    --入力パラメータの設定
    lv_step      := 'A-1.1';
    lv_msg_token := '入力パラメータの設定';
    gv_calendar_code := iv_calendar_code;  -- カレンダコード
    gv_cost_type     := iv_cost_type;      -- コストタイプ
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    -- 入力パラメータメッセージ出力、ログ出力
    lv_step      := 'A-1.1';
    lv_msg_token := '入力パラメータ出力';
    lv_errmsg    := cv_inp_calendar_code || gv_calendar_code;
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg
    );
    lv_errmsg    := cv_inp_cost_type || gv_cost_type;
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg
    );
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_init;
--
  /**********************************************************************************
   * Procedure Name   : get_cmp_cost
   * Description      : 標準原価取得(A-3.1,A-3.2)
   ***********************************************************************************/
  PROCEDURE get_cmp_cost(
    in_item_id            IN  NUMBER,              -- 品目ID
    o_cost_rec            OUT g_cost_rtype,        -- レコード型変数
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cmp_cost'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf     VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);     -- リターン・コード
    lv_errmsg     VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_step       VARCHAR2(100);   -- ステップ
    lv_msg_token  VARCHAR2(100);   -- デバッグ用トークン
    ln_flag       NUMBER;          -- 標準原価が「0」の場合を判定
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_sum_cost   NUMBER;
    ln_cnt        NUMBER;
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    --
    -- 標準原価をコンポーネントIDごとに取得する
    CURSOR      cnp_cost_cur
    IS
      SELECT    ccmd.cost_cmpntcls_id,
                ccmv.cost_cmpntcls_code,
                ccmd.cmpnt_cost
      FROM      cm_cmpt_dtl          ccmd,
                cm_cldr_dtl          cclr,
                cm_cmpt_mst_vl       ccmv,
                fnd_lookup_values_vl flv
      WHERE     ccmd.calendar_code       = cclr.calendar_code
      AND       ccmd.cost_cmpntcls_id    = ccmv.cost_cmpntcls_id
      AND       ccmv.cost_cmpntcls_code  = flv.meaning
      AND       ccmd.item_id             = in_item_id
      AND       ccmd.calendar_code       = gv_calendar_code
      AND       flv.lookup_type          = cv_lookup_cost_cmpt;
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
    -- 標準原価取得(A-3.1)
    -- ===============================
    --
    -- コンポーネントIDごとに標準原価を変数に格納する
    -- 標準原価を足しこむ
    lv_step := 'A-3';
    --変数初期化
    ln_sum_cost := 0;
    ln_cnt      := 0;
    <<cnp_cost_loop>>
    FOR l_cost_rec IN cnp_cost_cur LOOP
      lv_step      := 'A-3.1';
      lv_msg_token := '標準原価取得';
      ln_cnt := ln_cnt + 1;
      --
      CASE
        WHEN ( l_cost_rec.cost_cmpntcls_code = cv_cost_cmpnt_01gen ) THEN
          o_cost_rec.cmpnt_cost1 := l_cost_rec.cmpnt_cost;
          ln_sum_cost := ln_sum_cost + l_cost_rec.cmpnt_cost;
        WHEN ( l_cost_rec.cost_cmpntcls_code = cv_cost_cmpnt_02sai ) THEN
          o_cost_rec.cmpnt_cost2 := l_cost_rec.cmpnt_cost;
          ln_sum_cost := ln_sum_cost + l_cost_rec.cmpnt_cost;
        WHEN ( l_cost_rec.cost_cmpntcls_code = cv_cost_cmpnt_03szi ) THEN
          o_cost_rec.cmpnt_cost3 := l_cost_rec.cmpnt_cost;
          ln_sum_cost := ln_sum_cost + l_cost_rec.cmpnt_cost;
        WHEN ( l_cost_rec.cost_cmpntcls_code = cv_cost_cmpnt_04hou ) THEN
          o_cost_rec.cmpnt_cost4 := l_cost_rec.cmpnt_cost;
          ln_sum_cost := ln_sum_cost + l_cost_rec.cmpnt_cost;
        WHEN ( l_cost_rec.cost_cmpntcls_code = cv_cost_cmpnt_05gai ) THEN
          o_cost_rec.cmpnt_cost5 := l_cost_rec.cmpnt_cost;
          ln_sum_cost := ln_sum_cost + l_cost_rec.cmpnt_cost;
        WHEN ( l_cost_rec.cost_cmpntcls_code = cv_cost_cmpnt_06hkn ) THEN
          o_cost_rec.cmpnt_cost6 := l_cost_rec.cmpnt_cost;
          ln_sum_cost := ln_sum_cost + l_cost_rec.cmpnt_cost;
        WHEN ( l_cost_rec.cost_cmpntcls_code = cv_cost_cmpnt_07kei ) THEN
          o_cost_rec.cmpnt_cost7 := l_cost_rec.cmpnt_cost;
          ln_sum_cost := ln_sum_cost + l_cost_rec.cmpnt_cost;
      END CASE;
    END LOOP cnp_cost_loop;
    --
    -- ===============================
    -- 標準原価取得(A-3.2)
    -- ===============================
    --
    -- 足しこんだ標準原価を変数に格納する
    lv_step      := 'A-3.2';
    lv_msg_token := '標準原価合計';
    IF ( ln_cnt > 0 ) THEN
      o_cost_rec.cmpnt_cost := ln_sum_cost;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_cmp_cost;
--
--
  /**********************************************************************************
   * Procedure Name   : get_item_mst
   * Description      : 品目情報取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_item_mst(
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_item_mst'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf     VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);     -- リターン・コード
    lv_errmsg     VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_step       VARCHAR2(100);   -- ステップ
    lv_msg_token  VARCHAR2(100);   -- デバッグ用トークン
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
-- Ver1.2  2009/04/08  Add H.Yoshikawa  障害No.T1_0184 対応
    -- 品目ステータス：仮登録
    cn_itm_status_pre_reg    CONSTANT NUMBER := xxcmm_004common_pkg.cn_itm_status_pre_reg;
-- End
--
    -- *** ローカル変数 ***
    l_cost_rec               g_cost_rtype;  -- 標準原価取得用レコード型変数
    ln_c                     NUMBER;        -- カウンタ
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    --
    -- 品目情報を取得する
    CURSOR      item_csv_cur
    IS
      SELECT    xoiv.item_id,
                xoiv.item_no,
                xoiv.item_name,
                xoiv.item_short_name,
                se.seisakugun,
                xoiv.opt_cost_new      discrete_cost
      FROM      xxcmm_opmmtl_items_v   xoiv,
-- Ver1.2  2009/04/08  Del H.Yoshikawa  障害No.T1_0184 対応
--                financials_system_parameters fsp,
-- End
               (SELECT      gic_se.item_id       AS item_id
                           ,mcv_se.segment1      AS seisakugun
                           ,mcv_se.description   AS seisakugun_name
                FROM        gmi_item_categories  gic_se
                           ,mtl_category_sets_vl mcsv_se
                           ,mtl_categories_vl    mcv_se
                WHERE       gic_se.category_set_id    = mcsv_se.category_set_id
                AND         mcsv_se.category_set_name = cv_seisakugun
                AND         gic_se.category_id        = mcv_se.category_id
                ) se
      WHERE     xoiv.item_id            = xoiv.parent_item_id
-- Ver1.2  2009/04/08  Mod H.Yoshikawa  障害No.T1_0184 対応
--      AND       xoiv.organization_id    = fsp.inventory_organization_id
      AND       xoiv.item_status       >= cn_itm_status_pre_reg
-- End
      AND       xoiv.item_id            = se.item_id(+)
      AND       xoiv.item_no BETWEEN cv_item_code_from AND cv_item_code_to
      AND       xoiv.start_date_active  <= TRUNC( SYSDATE )
      AND       xoiv.end_date_active    >= TRUNC( SYSDATE )
      ORDER BY  se.seisakugun,
                xoiv.item_no;
--
    -- ===============================
    -- ユーザー定義例外
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
    -- ===============================
    -- 品目情報取得(A-2.1)
    -- ===============================
    --
    -- 取得した情報を変数に格納する
    lv_step := 'A-2';
    ln_c := 0;
    --
    <<item_info_loop>>
    FOR lr_item_csv_rec IN item_csv_cur LOOP
      lv_step      := 'A-2.1';
      lv_msg_token := '品目情報取得';
      ln_c := ln_c + 1;
      g_item_mst_tab(ln_c).v_item_id         := cv_space_1 || TO_CHAR( lr_item_csv_rec.item_id );
      g_item_mst_tab(ln_c).v_item_no         := lr_item_csv_rec.item_no;
      g_item_mst_tab(ln_c).v_item_name       := cv_space_2 || lr_item_csv_rec.item_name;
      g_item_mst_tab(ln_c).v_item_short_name := cv_space_2 || lr_item_csv_rec.item_short_name;
      g_item_mst_tab(ln_c).v_seisakugun      := lr_item_csv_rec.seisakugun;
      --
      -- ===============================
      -- 営業原価取得(A-2.2)
      -- ===============================
      --
      -- 営業原価タイプ別に営業原価の取得方法が変わる
      lv_step      := 'A-2.2';
      lv_msg_token := '営業原価取得';
      IF ( gv_cost_type = cv_cost_type1 ) THEN    -- 確定済
        g_item_mst_tab(ln_c).v_discrete_cost := lr_item_csv_rec.discrete_cost;
        g_item_mst_tab(ln_c).v_apply_date    := cv_apply_date;
      ELSE                                        -- 保留原価
        BEGIN
          SELECT    xsibh.discrete_cost,
                    TO_CHAR( xsibh.apply_date, cv_date_fmt_std )
          INTO      g_item_mst_tab(ln_c).v_discrete_cost,
                    g_item_mst_tab(ln_c).v_apply_date
          FROM      ic_item_mst_b            iimb,
                    xxcmm_system_items_b_hst xsibh,
                  ( SELECT   xsibh.item_code,
                             MIN(xsibh.apply_date)    apply_date
                    FROM     xxcmm_system_items_b_hst xsibh
                    WHERE    item_id           =  lr_item_csv_rec.item_id
                    AND      xsibh.apply_date  >= gd_process_date
                    AND      xsibh.apply_flag  =  cv_n
                    GROUP BY xsibh.item_code
                  ) hst
          WHERE     iimb.item_no      =  xsibh.item_code
          AND       xsibh.apply_flag  =  cv_n
          AND       iimb.item_no      =  hst.item_code
          AND       xsibh.apply_date  =  hst.apply_date
          AND       iimb.item_id      =  lr_item_csv_rec.item_id;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN  -- データが無い場合、デフォルト値を設定する
            g_item_mst_tab(ln_c).v_discrete_cost := NULL;
            g_item_mst_tab(ln_c).v_apply_date    := cv_apply_date;
        END;
      END IF;
      -- =======================================
      -- 標準原価取得(A-3.1),標準原価取得(A-3.2)
      -- =======================================
      --
      -- 標準原価を取得する
      lv_step      := 'A-3.1';
      lv_msg_token := '標準原価取得';
      get_cmp_cost(
        in_item_id    => lr_item_csv_rec.item_id,  -- IN  品目ID
        o_cost_rec    => l_cost_rec,               -- OUT レコード型変数
        ov_errbuf     => lv_errbuf,                -- OUT エラー・メッセージ           --# 固定 #
        ov_retcode    => lv_retcode,               -- OUT リターン・コード             --# 固定 #
        ov_errmsg     => lv_errmsg);               -- OUT ユーザー・エラー・メッセージ --# 固定 #
      IF ( lv_retcode != cv_status_normal ) THEN
        RAISE global_api_expt;
      END IF;
      -- 取得した標準原価をコンポーネントIDごとに変数に格納する
      g_item_mst_tab(ln_c).v_cmpnt_cost1     := TO_CHAR( l_cost_rec.cmpnt_cost1 );
      g_item_mst_tab(ln_c).v_cmpnt_cost2     := TO_CHAR( l_cost_rec.cmpnt_cost2 );
      g_item_mst_tab(ln_c).v_cmpnt_cost3     := TO_CHAR( l_cost_rec.cmpnt_cost3 );
      g_item_mst_tab(ln_c).v_cmpnt_cost4     := TO_CHAR( l_cost_rec.cmpnt_cost4 );
      g_item_mst_tab(ln_c).v_cmpnt_cost5     := TO_CHAR( l_cost_rec.cmpnt_cost5 );
      g_item_mst_tab(ln_c).v_cmpnt_cost6     := TO_CHAR( l_cost_rec.cmpnt_cost6 );
      g_item_mst_tab(ln_c).v_cmpnt_cost7     := TO_CHAR( l_cost_rec.cmpnt_cost7 );
      g_item_mst_tab(ln_c).v_cmpnt_cost      := TO_CHAR( l_cost_rec.cmpnt_cost );
      IF ( l_cost_rec.cmpnt_cost IS NULL ) THEN  -- 標準原価が無い場合、警告に'*'をセットする
        g_item_mst_tab(ln_c).v_emargency_flag := cv_emargency_flag;
      END IF;
      -- ===============================
      -- 標準原価取得(A-3.3)
      -- ===============================
      --
      -- 標準原価と営業原価を比較し、営業原価のほうが小さければ、警告に'*'をセットする
      lv_step      := 'A-3.3';
      lv_msg_token := '標準原価と営業原価の比較';
      IF ( l_cost_rec.cmpnt_cost > NVL( g_item_mst_tab(ln_c).v_discrete_cost, 0 ) ) THEN
        g_item_mst_tab(ln_c).v_emargency_flag := cv_emargency_flag;
      END IF;
      -- ===============================
      -- 標準原価取得(A-3.4)
      -- ===============================
      --
      -- 標準原価が小数点以下の数値を持っていれば、警告に'*'をセットする
      lv_step      := 'A-3.4';
      lv_msg_token := '標準原価小数点チェック';
      IF ( l_cost_rec.cmpnt_cost <> TRUNC( l_cost_rec.cmpnt_cost, 0 ) ) THEN
        g_item_mst_tab(ln_c).v_emargency_flag := cv_emargency_flag;
      END IF;
      -- ===============================
      -- 更新区分設定
      -- ===============================
      --
      -- すべてのレコードの更新区分に'D'をセットする
      lv_step      := 'A-3.5';
      lv_msg_token := '更新区分設定';
      g_item_mst_tab(ln_c).v_update_div := cv_update_div;
    END LOOP item_info_loop;
    --
-- Ver1.1
--    -- 品目の対象データが無い場合、対象データ無しメッセージを表示する
--    IF ( ln_c = 0 ) THEN
--      lv_errmsg  := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_app_name_xxcmm,
--                      iv_name         => cv_msg_xxcmm_00470,
--                      iv_token_name1  => cv_tkn_year,
--                      iv_token_value1 => gv_calendar_code,
--                      iv_token_name2  => cv_tkn_cost_type,
--                      iv_token_value2 => gv_cost_type
--                    );
--      FND_FILE.PUT_LINE(
--         which  => FND_FILE.LOG
--        ,buff   => lv_errmsg
--      );
--    END IF;
--
    -- 対象件数
    gn_target_cnt := ln_c;
    --
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_item_mst;
--
--
  /**********************************************************************************
   * Procedure Name   : output_csv（ループ部）
   * Description      : CSV形式データ出力(A-4,A-5)
   ***********************************************************************************/
  PROCEDURE output_csv(
    iv_file_type      IN  VARCHAR2,            -- ファイル種別
    ov_errbuf         OUT NOCOPY VARCHAR2,     -- エラー・メッセージ                  --# 固定 #
    ov_retcode        OUT NOCOPY VARCHAR2,     -- リターン・コード                    --# 固定 #
    ov_errmsg         OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_csv'; -- プログラム名
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
    lv_csv_file     VARCHAR2(5000);        -- 出力情報
    ln_c            NUMBER;
    lv_step         VARCHAR2(100);   -- ステップ
    lv_msg_token    VARCHAR2(100);   -- デバッグ用トークン
-- Ver1.1
    lv_out_msg      VARCHAR2(2000);
-- End
    --
    -- CSV形式データのフィールド桁数格納用変数
    TYPE arrayitm IS TABLE OF NUMBER(2,0);
    dec_array arrayitm;
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- ルックアップより項目タイトルを取得する
    CURSOR    lookup_gen_cur
    IS
    SELECT    flv.lookup_type,
              flv.lookup_code,
              flv.meaning,
              flv.attribute1    fld_dec
    FROM      fnd_lookup_values_vl flv
    WHERE     flv.lookup_type = cv_lookup_csv_head
    ORDER BY  flv.lookup_code;
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
  --
  BEGIN
--
--################## 固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================
    -- ヘッダ項目取得(A-4.1)
    -- ===============================
    --
    -- CSV形式データのヘッダを取得する
    lv_step      := 'A-4.1';
    lv_msg_token := 'ヘッダ項目取得';
-- Ver1.1
--    gv_out_msg := xxccp_common_pkg.get_msg(
    lv_out_msg := xxccp_common_pkg.get_msg(
-- End
                     iv_application  => cv_app_name_xxcmm,
                     iv_name         => cv_msg_xxcmm_00472,
                     iv_token_name1  => cv_tkn_year,
                     iv_token_value1 => gv_calendar_code,
                     iv_token_name2  => cv_tkn_cost_type,
                     iv_token_value2 => gv_cost_type
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
-- Ver1.1
--      ,buff   => gv_out_msg
      ,buff   => lv_out_msg
-- End
    );
    --
    -- 変数初期化
    ln_c := 0;
    lv_csv_file := NULL;
    dec_array := arrayitm();
    dec_array.EXTEND(17);
    --
    -- ===============================
    -- ヘッダ項目取得(A-4.2)
    -- ===============================
    --
    -- CSV形式データの項目タイトルを取得し、書式を整える
    lv_step      := 'A-4.2';
    lv_msg_token := 'CSV形式データ項目タイトル取得';
    <<head_info_loop>>
    FOR l_head_info_rec IN lookup_gen_cur LOOP
      ln_c := ln_c + 1;
      CASE
        WHEN ( ln_c = 1 ) THEN  -- 政策群
          lv_step     := 'A-4.2:政策群';
          lv_csv_file := lv_csv_file
                         || RPAD( l_head_info_rec.meaning, l_head_info_rec.fld_dec )
                         || cv_sep_com;
        WHEN ( ln_c = 2 ) THEN  -- 品名コード
          lv_step     := 'A-4.2:品名コード';
          lv_csv_file := lv_csv_file
                         || RPAD( l_head_info_rec.meaning, l_head_info_rec.fld_dec )
                         || cv_sep_com;
        WHEN ( ln_c = 3 ) THEN  -- 原料
          lv_step     := 'A-4.2:原料';
          lv_csv_file := lv_csv_file
                         || LPAD( l_head_info_rec.meaning, l_head_info_rec.fld_dec )
                         || cv_sep_com;
        WHEN ( ln_c = 4 ) THEN  -- 再製費
          lv_step     := 'A-4.2:再製費';
          lv_csv_file := lv_csv_file
                         || LPAD( l_head_info_rec.meaning, l_head_info_rec.fld_dec )
                         || cv_sep_com;
        WHEN ( ln_c = 5 ) THEN  -- 資材費
          lv_step     := 'A-4.2:資材費';
          lv_csv_file := lv_csv_file
                         || LPAD( l_head_info_rec.meaning, l_head_info_rec.fld_dec )
                         || cv_sep_com;
        WHEN ( ln_c = 6 ) THEN  -- 包装費
          lv_step     := 'A-4.2:包装費';
          lv_csv_file := lv_csv_file
                         || LPAD( l_head_info_rec.meaning, l_head_info_rec.fld_dec )
                         || cv_sep_com;
        WHEN ( ln_c = 7 ) THEN  -- 外注加工費
          lv_step     := 'A-4.2:外注加工費';
          lv_csv_file := lv_csv_file
                         || LPAD( l_head_info_rec.meaning, l_head_info_rec.fld_dec )
                         || cv_sep_com;
        WHEN ( ln_c = 8 ) THEN  -- 保管費
          lv_step     := 'A-4.2:保管費';
          lv_csv_file := lv_csv_file
                         || LPAD( l_head_info_rec.meaning, l_head_info_rec.fld_dec )
                         || cv_sep_com;
        WHEN ( ln_c = 9 ) THEN  -- その他経費
          lv_step     := 'A-4.2:その他経費';
          lv_csv_file := lv_csv_file
                         || LPAD( l_head_info_rec.meaning, l_head_info_rec.fld_dec )
                         || cv_sep_com;
        WHEN ( ln_c = 10 ) THEN  -- 標準原価計
          lv_step     := 'A-4.2:標準原価計';
          lv_csv_file := lv_csv_file
                         || LPAD( l_head_info_rec.meaning, l_head_info_rec.fld_dec )
                         || cv_sep_com;
        WHEN ( ln_c = 11 ) THEN  -- 営業原価
          lv_step     := 'A-4.2:営業原価';
          lv_csv_file := lv_csv_file
                         || LPAD( l_head_info_rec.meaning, l_head_info_rec.fld_dec )
                         || cv_sep_com;
        WHEN ( ln_c = 12 ) THEN  -- 警告
          lv_step     := 'A-4.2:警告';
          lv_csv_file := lv_csv_file
                         || RPAD( l_head_info_rec.meaning, l_head_info_rec.fld_dec )
                         || cv_sep_com;
        WHEN ( ln_c = 13 ) THEN  -- 更新区分
          lv_step     := 'A-4.2:更新区分';
          lv_csv_file := lv_csv_file
                         || RPAD( l_head_info_rec.meaning, l_head_info_rec.fld_dec )
                         || cv_sep_com;
        WHEN ( ln_c = 14 ) THEN  -- 適用開始日
          lv_step     := 'A-4.2:適用開始日';
          lv_csv_file := lv_csv_file
                         || LPAD( l_head_info_rec.meaning, l_head_info_rec.fld_dec )
                         || cv_sep_com;
        WHEN ( ln_c = 15 ) THEN  -- 正式名
          lv_step     := 'A-4.2:正式名';
          lv_csv_file := lv_csv_file
                         || RPAD( cv_space_2 || l_head_info_rec.meaning, l_head_info_rec.fld_dec )
                         || cv_sep_com;
        WHEN ( ln_c = 16 ) THEN  -- 略称
          lv_step     := 'A-4.2:略称';
          lv_csv_file := lv_csv_file
                         || RPAD( cv_space_2 || l_head_info_rec.meaning, l_head_info_rec.fld_dec )
                         || cv_sep_com;
        WHEN ( ln_c = 17 ) THEN  -- 品目ID
          lv_step     := 'A-4.2:品目ID';
          lv_csv_file := lv_csv_file
                         || RPAD( cv_space_1 || l_head_info_rec.meaning, l_head_info_rec.fld_dec )
                         || cv_sep_com;
      END CASE;
      dec_array(ln_c) := l_head_info_rec.fld_dec;
    END LOOP head_info_loop;
    --
-- Ver1.1
--    IF ( ln_c = 0 ) THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_app_name_xxcmm,
--                     iv_name         => cv_msg_xxcmm_00471
--                   );
--      FND_FILE.PUT_LINE(
--         which  => FND_FILE.LOG
--        ,buff   => lv_errmsg
--      );
--    END IF;
-- End
    --
    lv_csv_file := SUBSTRB( lv_csv_file, 1, LENGTHB( lv_csv_file ) - 1 );
    --
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_csv_file
    );
    --
    -- ===============================
    -- CSV形式データの出力(A-5)
    -- ===============================
    --
    -- 品目情報書式を整えて出力する
    lv_step      := 'A-5';
    lv_msg_token := 'CSV形式データの出力';
    IF ( g_item_mst_tab.COUNT IS NULL ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
    END IF;
    IF ( g_item_mst_tab.COUNT <> 0 ) THEN
      ln_c := 0;
      <<g_item_mst_tab_loop>>
      FOR ln IN g_item_mst_tab.FIRST .. g_item_mst_tab.LAST LOOP
        ln_c := ln_c + 1;
        lv_csv_file :=    RPAD( NVL( g_item_mst_tab(ln).v_seisakugun, cv_space_1 ),      dec_array(1) )
                       || cv_sep_com   -- 政策群
                       || RPAD( NVL( g_item_mst_tab(ln).v_item_no, cv_space_1 ),         dec_array(2) )
                       || cv_sep_com   -- 品名コード
                       || LPAD( NVL( g_item_mst_tab(ln).v_cmpnt_cost1, cv_space_1 ),     dec_array(3) )
                       || cv_sep_com   -- 原料
                       || LPAD( NVL( g_item_mst_tab(ln).v_cmpnt_cost2, cv_space_1 ),     dec_array(4) )
                       || cv_sep_com   -- 再製費
                       || LPAD( NVL( g_item_mst_tab(ln).v_cmpnt_cost3, cv_space_1 ),     dec_array(5) )
                       || cv_sep_com   -- 資材費
                       || LPAD( NVL( g_item_mst_tab(ln).v_cmpnt_cost4, cv_space_1 ),     dec_array(6) )
                       || cv_sep_com   -- 包装費
                       || LPAD( NVL( g_item_mst_tab(ln).v_cmpnt_cost5, cv_space_1 ),     dec_array(7) )
                       || cv_sep_com   -- 外注加工費
                       || LPAD( NVL( g_item_mst_tab(ln).v_cmpnt_cost6, cv_space_1 ),     dec_array(8) )
                       || cv_sep_com   -- 保管費
                       || LPAD( NVL( g_item_mst_tab(ln).v_cmpnt_cost7, cv_space_1 ),     dec_array(9) )
                       || cv_sep_com   -- その他経費
                       || LPAD( NVL( g_item_mst_tab(ln).v_cmpnt_cost, cv_space_1 ),      dec_array(10) )
                       || cv_sep_com   -- 標準原価合計
                       || LPAD( NVL( g_item_mst_tab(ln).v_discrete_cost, cv_space_1 ),   dec_array(11) )
                       || cv_sep_com   -- 営業原価
                       || RPAD( NVL( g_item_mst_tab(ln).v_emargency_flag, cv_space_1 ),  dec_array(12) )
                       || cv_sep_com   -- 警告
                       || RPAD( NVL( g_item_mst_tab(ln).v_update_div, cv_space_1 ),      dec_array(13) )
                       || cv_sep_com   -- 更新区分
                       || LPAD( NVL( g_item_mst_tab(ln).v_apply_date, cv_space_1 ),      dec_array(14) )
                       || cv_sep_com   -- 適用開始日
                       || RPAD( NVL( g_item_mst_tab(ln).v_item_name, cv_space_1 ),       dec_array(15) )
                       || cv_sep_com   -- 正式名
                       || RPAD( NVL( g_item_mst_tab(ln).v_item_short_name, cv_space_1 ), dec_array(16) )
                       || cv_sep_com   -- 略称
                       || RPAD( NVL( g_item_mst_tab(ln).v_item_id, cv_space_1 ),         dec_array(17) )
                       ;               -- 品目ID
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_csv_file
        );
-- Ver1.1
--        -- 成功件数
--        gn_normal_cnt := ln_c;
-- End
      END LOOP g_item_mst_tab_loop;
      --
      -- 成功件数
      gn_normal_cnt := ln_c;
-- Ver1.1
--      IF ( ln_c = 0 ) THEN
--        FND_FILE.PUT_LINE(
--           which  => FND_FILE.LOG
--          ,buff   => lv_errmsg
--        );
--      END IF;
-- End
    END IF;
  --
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- エラー件数
      gn_error_cnt := ln_c;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END output_csv;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_calendar_code     IN  VARCHAR2,     --   標準原価対象年度
    iv_cost_type         IN  VARCHAR2,     --   営業原価タイプ
    ov_errbuf            OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode           OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg            OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_step           VARCHAR2(100);   -- ステップ
    lv_msg_token      VARCHAR2(100);   -- デバッグ用トークン
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    subprog_err_expt  EXCEPTION;
    --
  BEGIN
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
    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    lv_step      := 'A-1';
    lv_msg_token := '初期処理';
    proc_init(
      iv_calendar_code  => iv_calendar_code,  -- 標準原価対象年度
      iv_cost_type      => iv_cost_type,      -- 営業原価タイプ
      ov_errbuf         => lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      ov_retcode        => lv_retcode,        -- リターン・コード             --# 固定 #
      ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE subprog_err_expt;
    END IF;
    -- ===================================
    -- 品目情報取得(A-2),標準原価取得(A-3)
    -- ===================================
    lv_step      := 'A-2,A-3';
    lv_msg_token := '品目情報、標準原価取得';
    get_item_mst(
      ov_errbuf    => lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      ov_retcode   => lv_retcode,        -- リターン・コード             --# 固定 #
      ov_errmsg    => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE subprog_err_expt;
    END IF;
    -- ==========================================
    -- ヘッダ項目取得(A-4),CSV形式データ出力(A-5)
    -- ==========================================
    lv_step      := 'A-4,A-5';
    lv_msg_token := 'ヘッダ項目取得、CSV形式データ出力';
    output_csv(
      iv_file_type => cv_csv_file,       -- CSVファイル
      ov_errbuf    => lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      ov_retcode   => lv_retcode,        -- リターン・コード             --# 固定 #
      ov_errmsg    => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE subprog_err_expt;
    END IF;
--
--
  EXCEPTION
    WHEN subprog_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||lv_errbuf;
      ov_retcode := cv_status_error;
    --
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      --エラー出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_msg_token --ユーザー・エラーメッセージ
      );
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END submain;
--
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf            OUT VARCHAR2,    -- エラー・メッセージ  --# 固定 #
    retcode           OUT VARCHAR2,    -- リターン・コード    --# 固定 #
    iv_calendar_code  IN  VARCHAR2,    -- 標準原価対象年度
    iv_cost_type      IN  VARCHAR2     -- 営業原価タイプ
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
    lv_step            VARCHAR2(100);   -- ステップ
    lv_msg_token       VARCHAR2(100);   -- デバッグ用トークン
    --
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_output_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    lv_step      := 'submain';
    submain(
       iv_calendar_code  => iv_calendar_code,  -- 標準原価対象年度
       iv_cost_type      => iv_cost_type,      -- 営業原価タイプ
       ov_errbuf         => lv_errbuf,         -- エラー・メッセージ           --# 固定 #
       ov_retcode        => lv_retcode,        -- リターン・コード             --# 固定 #
       ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    lv_step      := 'A-6:err';
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
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --対象件数出力
    lv_step      := 'A-6:対象件数出力';
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    lv_step      := 'A-6:成功件数出力';
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    lv_step      := 'A-6:エラー件数出力';
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --終了メッセージ
    lv_step      := 'A-6:終了メッセージ';
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCMM004A06C;
/
