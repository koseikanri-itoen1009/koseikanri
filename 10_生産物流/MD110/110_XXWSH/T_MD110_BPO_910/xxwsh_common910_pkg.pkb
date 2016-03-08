CREATE OR REPLACE PACKAGE BODY xxwsh_common910_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name           : xxwsh_common910_pkg(BODY)
 * Description            : 共通関数(BODY)
 * MD.070(CMD.050)        : なし
 * Version                : 1.38
 *
 * Program List
 *  -------------------- ---- ----- --------------------------------------------------
 *   Name                Type  Ret   Description
 *  -------------------- ---- ----- --------------------------------------------------
 *  comp_round_up          F         小数点切り上げ関数
 *  calc_total_value       P         B.積載効率チェック(合計値算出)
 *  calc_load_efficiency   P         C.積載効率チェック(積載効率算出)
 *  check_lot_reversal     P         D.ロット逆転防止チェック
 *  check_lot_reversal2    P         D.ロット逆転防止チェック(依頼No指定あり)
 *  check_fresh_condition  P         E.鮮度条件チェック
 *  get_fresh_pass_date    P         E.鮮度条件合格製造日取得
 *  calc_lead_time         P         F.リードタイム算出
 *  check_shipping_judgment
 *                         P         G.出荷可否チェック
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/03/13   1.0   ORACLE石渡賢和   新規作成
 *  2008/05/19   1.1   ORACLE石渡賢和   メッセージ修正
 *  2008/05/23   1.2   ORACLE北寒寺正夫 鮮度条件チェックのOTHERS例外処理コードを
 *                                      global_api_others_exptに変更
 *                                      鮮度条件チェックの入力パラメータをロットNoから
 *                                      ロットIDに変更
 *  2008/05/24   1.3   ORACLE北寒寺正夫 鮮度条件チェックの鮮度条件区分のエラーチェックに
 *                                      NULLの場合を追加。
 *                                      鮮度条件区分が一般の場合、賞味期限がセットされて
 *                                      いない場合、エラーとするように修正
 *  2008/05/28   1.4   ORACLE石渡賢和   [ロット逆転防止チェック]
 *                                      移動ロット詳細のレコードタイプ値を修正
 *  2008/05/30   1.5   ORACLE椎名昭圭   内部変更要求#116対応
 *  2008/06/02   1.6   ORACLE石渡賢和   [出荷可否チェック] フォーキャストの抽出条件変更
 *                                      [積載効率チェック(積載効率算出)]抽出条件改良
 *  2008/06/13   1.7   ORACLE石渡賢和   [ロット逆転防止チェック] 移動指示の着日条件を変更
 *  2008/06/19   1.8   ORACLE山根一浩   [出荷可否チェック] 内部変更要求No143対応
 *  2008/06/26   1.9   ORACLE石渡賢和   [出荷可否チェック] 移動指示の着日条件を変更
 *  2008/07/08   1.10  ORACLE椎名昭圭   [出荷可否チェック] ST不具合#405対応
 *  2008/07/14   1.11  ORACLE福田直樹   [積載効率チェック(積載効率算出)] 変更要求対応#95
 *  2008/07/17   1.12  ORACLE福田直樹   [積載効率チェック(積載効率算出)] 変更要求対応#95のバグ対応
 *  2008/07/30   1.13  ORACLE高山洋平   [出荷可否チェック]内部変更要求#182対応
 *  2008/08/04   1.14  ORACLE伊藤ひとみ [積載効率チェック(積載効率算出)] 変更要求対応#95のバグ対応
 *  2008/08/06   1.14  ORACLE伊藤ひとみ [積載効率チェック(積載効率算出)] 変更要求対応#164対応
 *  2008/08/22   1.15  ORACLE伊藤ひとみ [出荷可否チェック] PT 2-2_15 指摘20
 *  2008/09/05   1.16  ORACLE伊藤ひとみ [積載効率チェック(積載効率算出)] PT 6-2_34 指摘#34対応
 *  2008/09/08   1.17  ORACLE椎名昭圭   [ロット逆転防止チェック] PT 6-1_28 指摘#44対応
 *  2008/09/11   1.18  ORACLE椎名昭圭   [ロット逆転防止チェック] PT 6-1_28 指摘#73対応
 *  2008/09/17   1.19  ORACLE椎名昭圭   [ロット逆転防止チェック] PT 6-1_28 指摘#73追加修正
 *  2008/10/06   1.20  ORACLE伊藤ひとみ [積載効率チェック(合計値算出)] 統合テスト指摘240対応 積載効率チェック(合計値算出)基準日ありを追加
 *  2008/10/15   1.21  ORACLE伊藤ひとみ [積載効率チェック(積載効率算出)] 統合テスト指摘298対応
 *  2008/10/15   1.22  ORACLE伊藤ひとみ [鮮度条件チェック] 統合テスト指摘379対応
 *  2008/11/04   1.23  ORACLE伊藤ひとみ [ロット逆転防止チェック] T_S_573対応
 *  2008/11/12   1.24  ORACLE伊藤ひとみ [積載効率チェック(合計値算出)] 統合テスト指摘597対応
 *  2008/11/12   1.25  ORACLE伊藤ひとみ [積載効率チェック(合計値算出)] 統合テスト指摘311対応
 *  2008/12/07   1.26  ORACLE北寒寺正夫 [出荷可否チェック]本番障害#318対応
 *  2008/12/23   1.27  ORACLE北寒寺正夫 [積載効率チェック(合計値算出)] 本番指摘#781対応
 *  2009/01/22   1.28  SCS   伊藤ひとみ [ロット逆転防止チェック(依頼No指定あり)] 本番障害#1000対応
 *  2009/01/23   1.29  SCS   伊藤ひとみ [鮮度条件合格製造日取得] 本番障害#936対応
 *  2009/01/26   1.30  SCS   二瓶大輔   [ロット逆転防止チェック] 本番障害#936対応
 *  2009/03/03   1.31  SCS   風間由紀   [出荷可否チェック] 本番障害#1243対応
 *  2009/03/19   1.32  SCS   飯田甫     [積載効率チェック(合計値算出)] 統合テスト指摘311対応
 *  2009/04/23   1.33  SCS   風間由紀   [リードタイム算出] 本番障害#1398対応
 *  2009/10/15   1.37  SCS   伊藤ひとみ [ロット逆転防止チェック] 本番障害#1661対応
 *  2016/02/18   1.38  SCSK  菅原大輔   [ロット逆転防止チェック] E_本稼動_13468対応
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
--  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
  gv_status_error  CONSTANT VARCHAR2(1) := '1';
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'xxwsh_common910_pkg'; -- パッケージ名
  --
  gv_cnst_xxwsh    CONSTANT VARCHAR2(5)   := 'XXWSH';
  --
  gv_yyyymmdd      CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
--
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  /************************************************************************
   * Procedure Name  : comp_round_up
   * Description     : 小数点切り上げ関数
   ************************************************************************/
  FUNCTION comp_round_up(
    pn_number1  IN NUMBER  -- 対象の数値
   ,pn_number2  IN NUMBER  -- 切上後の少数桁
  ) RETURN  NUMBER         -- 切上後の数値
  IS
  BEGIN
--
    RETURN TRUNC(pn_number1 + (0.9 / POWER(10, pn_number2)), pn_number2);
--
  END comp_round_up;
--
-- 2008/10/06 H.Itou Del Start 統合テスト指摘240
--  /**********************************************************************************
--   * Procedure Name   : calc_total_value
--   * Description      : 積載効率チェック(合計値算出)
--   ***********************************************************************************/
--  PROCEDURE calc_total_value(
--    iv_item_no                    IN  xxcmn_item_mst_v.item_no%TYPE,   -- 1.品目コード
--    in_quantity                   IN  NUMBER,                          -- 2.数量
--    ov_retcode                    OUT NOCOPY VARCHAR2,                 -- 3.リターンコード
--    ov_errmsg_code                OUT NOCOPY VARCHAR2,                 -- 4.エラーメッセージコード
--    ov_errmsg                     OUT NOCOPY VARCHAR2,                 -- 5.エラーメッセージ
--    on_sum_weight                 OUT NOCOPY NUMBER,                   -- 6.合計重量
--    on_sum_capacity               OUT NOCOPY NUMBER,                   -- 7.合計容積
--    on_sum_pallet_weight          OUT NOCOPY NUMBER                    -- 8.合計パレット重量
--  )
--  IS
--    -- ===============================
--    -- 固定ローカル定数
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'calc_total_value';        --プログラム名
--    --
--    -- ===============================
--    -- ユーザー宣言部
--    -- ===============================
--    -- *** ローカル定数 ***
--    -- メッセージID
--    cv_xxwsh_no_data_found_err CONSTANT VARCHAR2(100) := 'APP-XXWSH-12551'; -- 対象データなしエラーメッセージ
--    cv_xxwsh_palette_steps_err CONSTANT VARCHAR2(100) := 'APP-XXWSH-12552'; -- パレット当り最大段数値ゼロエラーメッセージ
--    cv_xxwsh_get_prof_err      CONSTANT VARCHAR2(100) := 'APP-XXWSH-12553'; -- プロファイル取得エラーメッセージ
--    cv_xxwsh_get_deliv_qty_err CONSTANT VARCHAR2(100) := 'APP-XXWSH-12554'; -- 配数値ゼロエラーメッセージ
--    cv_xxwsh_indispensable_err CONSTANT VARCHAR2(100) := 'APP-XXWSH-12555'; -- 必須入力パラメータ未設定エラーメッセージ
--    cv_xxwsh_num_of_case_err   CONSTANT VARCHAR2(100) := 'APP-XXWSH-12556'; -- ケース入数値ゼロエラーメッセージ
--    cv_xxwsh_d_num_of_case_err CONSTANT VARCHAR2(100) := 'APP-XXWSH-12557'; -- ドリンクケース入数値ゼロエラーメッセージ
--    -- トークン
--    cv_tkn_item_code      CONSTANT VARCHAR2(100) := 'ITEM_CODE';
--    cv_tkn_prof_name      CONSTANT VARCHAR2(100) := 'PROF_NAME';
--    cv_tkn_in_parm        CONSTANT VARCHAR2(100) := 'IN_PARM';
--    -- トークンセット値
--    cv_item_code_char     CONSTANT VARCHAR2(100) := '品目コード';
--    cv_qty_char           CONSTANT VARCHAR2(100) := '数量';
--    -- プロファイル
--    cv_prof_mast_org_id   CONSTANT VARCHAR2(30)  := 'XXCMN_MASTER_ORG_ID'; -- XXCMN:マスタ組織
--    cv_prof_pallet_waight CONSTANT VARCHAR2(30)  := 'XXWSH_PALLET_WEIGHT'; -- XXWSH:パレット重量
--    -- 商品区分
--    cv_prod_class_drink   CONSTANT VARCHAR2(1)   := '2';                   -- ドリンク
--    -- 品目区分
--    cv_item_class_product CONSTANT VARCHAR2(1)   := '5';                   -- 製品
--    -- 切り上げ用定数
--    cn_rounup_const_no    CONSTANT NUMBER        := 0.9;
--    -- 丸め桁数
--    cn_roundup_digits     CONSTANT NUMBER        := 0;
--    -- 単位換算(1) 立法センチメートル->立方メートル
--    cn_conv_cm3_to_m3     CONSTANT NUMBER        := 1000000;
--    -- 単位換算(2) グラム->キログラム
--    cn_conv_g_to_kg       CONSTANT NUMBER        := 1000;
----
--    -- *** ローカル変数 ***
--    -- エラー変数
--    lv_errmsg             VARCHAR2(1000);
--    lv_err_cd             VARCHAR2(30);
----
--    -- プロファイル変数
--    ln_mst_org_id         mtl_parameters.organization_id%TYPE;            -- マスタ組織ID
--    ln_pallet_waight      NUMBER;                                         -- パレット重量
----
--    -- 品目マスタ項目
--    ln_weight             NUMBER;                                         -- 重量
--    ln_capacity           NUMBER;                                         -- 容積
--    ln_delivery_qty       NUMBER;                                         -- 配数
--    ln_max_palette_steps  NUMBER;                                         -- パレット当り最大段数
--    ln_num_of_cases       NUMBER;                                         -- ケース入数
--    lv_conv_unit          xxcmn_item_mst_v.conv_unit%TYPE;                -- 入出庫換算単位
--    lv_prod_class_code    xxcmn_item_categories5_v.prod_class_code%TYPE;  -- 商品区分
--    lv_item_class_code    xxcmn_item_categories5_v.item_class_code%TYPE;  -- 品目区分
----
--    ln_pallet_qty         NUMBER DEFAULT 0;                               -- パレット枚数
--    ln_pallet_sum_weight  NUMBER DEFAULT 0;                               -- 合計パレット重量
----
--    -- *** ローカル・カーソル ***
----
--    -- *** ローカル・レコード ***
----
--    -- ===============================
--    -- ユーザー定義例外
--    -- ===============================
----
--  BEGIN
----
--    -- ***********************************************
--    -- ***      共通関数処理ロジックの記述         ***
--    -- ***********************************************
----
--    /*************************************
--     *  プロファイル取得(B-1)            *
--     *************************************/
--    --
--    ln_mst_org_id    := to_number( fnd_profile.valuE( cv_prof_mast_org_id ));   -- 品目マスタ組織ID
--    ln_pallet_waight := to_number( fnd_profile.valuE( cv_prof_pallet_waight )); -- パレット重量
--    --
--    -- エラー処理
--    -- 「XXCMN:マスタ組織」取得失敗
--    IF ( ln_mst_org_id    IS NULL ) THEN
--      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
--                                            cv_xxwsh_get_prof_err,
--                                            cv_tkn_prof_name,
--                                            cv_prof_mast_org_id);
--      lv_err_cd := cv_xxwsh_get_prof_err;
--      RAISE global_api_expt;
--    --
--    -- 「XXWSH:パレット重量」取得失敗
--    ELSIF ( ln_pallet_waight IS NULL ) THEN
--      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
--                                            cv_xxwsh_get_prof_err,
--                                            cv_tkn_prof_name,
--                                            cv_prof_pallet_waight);
--      lv_err_cd := cv_xxwsh_get_prof_err;
--      RAISE global_api_expt;
--    END IF;
----
--    /*************************************
--     *  必須入力パラメータチェック(B-2)  *
--     *************************************/
--    --
--    -- 品目コード
--    IF ( iv_item_no  IS NULL ) THEN
--      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
--                                            cv_xxwsh_indispensable_err,
--                                            cv_tkn_in_parm,
--                                            cv_item_code_char);
--      lv_err_cd := cv_xxwsh_indispensable_err;
--      RAISE global_api_expt;
--    --
--    -- 数量
--    ELSIF ( in_quantity IS NULL ) THEN
--      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
--                                            cv_xxwsh_indispensable_err,
--                                            cv_tkn_in_parm,
--                                            cv_qty_char);
--      lv_err_cd := cv_xxwsh_indispensable_err;
--      RAISE global_api_expt;
--    END IF;
----
--    /*************************************
--     *  品目マスタ抽出(B-3)              *
--     *************************************/
--    --
--    BEGIN
--      SELECT  to_number( ximv.unit ),               -- 重量
--              to_number( ximv.capacity ),           -- 容積
--              to_number( ximv.delivery_qty ),       -- 配数
--              to_number( ximv.max_palette_steps ),  -- パレット当り最大段数
--              to_number( ximv.num_of_cases ),       -- ケース入数
--              ximv.conv_unit,                       -- 入出庫換算単位
--              xicv.prod_class_code,                 -- 商品区分
--              xicv.item_class_code                  -- 品目区分
--      INTO    ln_weight,
--              ln_capacity,
--              ln_delivery_qty,
--              ln_max_palette_steps,
--              ln_num_of_cases,
--              lv_conv_unit,
--              lv_prod_class_code,
--              lv_item_class_code
--      FROM    xxcmn_item_mst2_v         ximv,      -- OPM品目情報VIEW2
--              xxcmn_item_categories5_v  xicv       -- OPM品目カテゴリ割当情報VIEW5
--      WHERE   ximv.item_no           =  iv_item_no
--        AND   xicv.item_id           =  ximv.item_id
---- 2008/10/06 H.Itou Del Start 統合テスト指摘240
----        AND   ROWNUM                 =  1
---- 2008/10/06 H.Itou Del End
---- 2008/10/06 H.Itou Add Start 統合テスト指摘240
--        AND   TRUNC(SYSDATE) BETWEEN ximv.start_date_active AND ximv.end_date_active
---- 2008/10/06 H.Itou Add End
--      ;
--    EXCEPTION
--      WHEN  NO_DATA_FOUND THEN
--        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
--                                              cv_xxwsh_no_data_found_err,
--                                              cv_tkn_item_code,
--                                              iv_item_no);
--        lv_err_cd := cv_xxwsh_no_data_found_err;
--        RAISE global_api_expt;
--    END;
----
--     -- 業務例外チェック
--    -- ドリンクかつ製品の品目の場合
--    IF (  ( lv_prod_class_code = cv_prod_class_drink   )
--      AND ( lv_item_class_code = cv_item_class_product )) THEN
--    --
--    -- 配数が0またはNULLならエラー
--      IF ( NVL(ln_delivery_qty, 0) = 0 ) THEN
--        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
--                                              cv_xxwsh_get_deliv_qty_err,
--                                              cv_tkn_item_code,
--                                              iv_item_no);
--        lv_err_cd := cv_xxwsh_get_deliv_qty_err;
--        RAISE global_api_expt;
--    --
--    -- パレット当り最大段数が0またはNULLならエラー
--      ELSIF ( NVL(ln_max_palette_steps, 0) = 0 ) THEN
--        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
--                                              cv_xxwsh_palette_steps_err,
--                                              cv_tkn_item_code,
--                                              iv_item_no);
--        lv_err_cd := cv_xxwsh_palette_steps_err;
--        RAISE global_api_expt;
--    --
--    -- ケース入数が0またはNULLならエラー
--      ELSIF ( NVL(ln_num_of_cases, 0) = 0 ) THEN
--        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
--                                              cv_xxwsh_d_num_of_case_err,
--                                              cv_tkn_item_code,
--                                              iv_item_no);
--        lv_err_cd := cv_xxwsh_d_num_of_case_err;
--        RAISE global_api_expt;
--      END IF;
--    END IF;
--    --
--    -- 入出庫換算単位がNULL以外の場合、ケース入数が0またはNULLならエラー
--    IF (  ( lv_conv_unit IS NOT NULL )
--      AND ( NVL(ln_num_of_cases, 0) = 0 ) ) THEN
--        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
--                                              cv_xxwsh_num_of_case_err,
--                                              cv_tkn_item_code,
--                                              iv_item_no);
--        lv_err_cd := cv_xxwsh_num_of_case_err;
--        RAISE global_api_expt;
--    END IF;
----
--    /**********************************
--     *  合計パレット重量の算出(B-4)   *
--     **********************************/
--    --
--    -- ドリンク製品の場合のみ、数量分のパレット重量を算出する。
--    IF (  ( lv_prod_class_code = cv_prod_class_drink   )
--      AND ( lv_item_class_code = cv_item_class_product ) )
--    THEN
--      --「パレット枚数」の算出
--      ln_pallet_qty
--        := ( (  ( in_quantity   / ln_num_of_cases  ) / ln_delivery_qty  ) / ln_max_palette_steps);
--      ln_pallet_qty
--        := TRUNC( ln_pallet_qty + cn_rounup_const_no , cn_roundup_digits );
--      --
--      -- 「合計パレット重量」の算出
--      ln_pallet_sum_weight
--                    := ln_pallet_qty * ln_pallet_waight;
--    END IF;
--    --
----
--    /**********************************
--     *  合計値の算出(B-5)             *
--     **********************************/
--    --
--    -- 出力パラメータ「合計容積」「合計重量」
--    on_sum_capacity      := ( ln_capacity * in_quantity ) / cn_conv_cm3_to_m3;
--    on_sum_weight        := ( ln_weight   * in_quantity ) / cn_conv_g_to_kg;
--    -- 出力パラメータ「合計パレット重量」
--    on_sum_pallet_weight := ln_pallet_sum_weight;
--    --
--    -- ステータスコードセット
--    ov_retcode           := gv_status_normal;   -- リターンコード
--    ov_errmsg_code       := NULL;               -- エラーメッセージコード
--    ov_errmsg            := NULL;               -- エラーメッセージ
--    --
----
--    --==============================================================
--    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
--    --==============================================================
----
--  EXCEPTION
----
----#################################  固定例外処理部 START   ####################################
----
--    -- *** 共通関数例外ハンドラ ***
--    WHEN global_api_expt THEN
--      ov_errmsg      := lv_errmsg;
--      ov_errmsg_code := lv_err_cd;
--      ov_retcode     := gv_status_error;
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      ov_errmsg      := SQLERRM;
--      ov_errmsg_code := SQLCODE;
--      ov_retcode     := gv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errmsg      := SQLERRM;
--      ov_errmsg_code := SQLCODE;
--      ov_retcode     := gv_status_error;
----
----#####################################  固定部 END   ##########################################
----
--  END calc_total_value;
-- 2008/10/06 H.Itou Del End
--
-- 2009/03/19 H.Iida Del Start 統合テスト指摘311
---- 2008/10/06 H.Itou Add Start 統合テスト指摘240
--  /**********************************************************************************
--   * Procedure Name   : calc_total_value
--   * Description      : 積載効率チェック(合計値算出)
--   ***********************************************************************************/
--  PROCEDURE calc_total_value(
--    iv_item_no                    IN  xxcmn_item_mst_v.item_no%TYPE,   -- 1.品目コード
--    in_quantity                   IN  NUMBER,                          -- 2.数量
--    ov_retcode                    OUT NOCOPY VARCHAR2,                 -- 3.リターンコード
--    ov_errmsg_code                OUT NOCOPY VARCHAR2,                 -- 4.エラーメッセージコード
--    ov_errmsg                     OUT NOCOPY VARCHAR2,                 -- 5.エラーメッセージ
--    on_sum_weight                 OUT NOCOPY NUMBER,                   -- 6.合計重量
--    on_sum_capacity               OUT NOCOPY NUMBER,                   -- 7.合計容積
--    on_sum_pallet_weight          OUT NOCOPY NUMBER,                   -- 8.合計パレット重量
--    id_standard_date              IN  DATE                             -- 9.基準日(適用日基準日)
--  )
--  IS
--    -- ===============================
--    -- 固定ローカル定数
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'calc_total_value';        --プログラム名
--    --
--    -- ===============================
--    -- ユーザー宣言部
--    -- ===============================
--    -- *** ローカル定数 ***
--    -- メッセージID
--    cv_xxwsh_no_data_found_err CONSTANT VARCHAR2(100) := 'APP-XXWSH-12551'; -- 対象データなしエラーメッセージ
--    cv_xxwsh_palette_steps_err CONSTANT VARCHAR2(100) := 'APP-XXWSH-12552'; -- パレット当り最大段数値ゼロエラーメッセージ
--    cv_xxwsh_get_prof_err      CONSTANT VARCHAR2(100) := 'APP-XXWSH-12553'; -- プロファイル取得エラーメッセージ
--    cv_xxwsh_get_deliv_qty_err CONSTANT VARCHAR2(100) := 'APP-XXWSH-12554'; -- 配数値ゼロエラーメッセージ
--    cv_xxwsh_indispensable_err CONSTANT VARCHAR2(100) := 'APP-XXWSH-12555'; -- 必須入力パラメータ未設定エラーメッセージ
--    cv_xxwsh_num_of_case_err   CONSTANT VARCHAR2(100) := 'APP-XXWSH-12556'; -- ケース入数値ゼロエラーメッセージ
--    cv_xxwsh_d_num_of_case_err CONSTANT VARCHAR2(100) := 'APP-XXWSH-12557'; -- ドリンクケース入数値ゼロエラーメッセージ
--    -- トークン
--    cv_tkn_item_code      CONSTANT VARCHAR2(100) := 'ITEM_CODE';
--    cv_tkn_prof_name      CONSTANT VARCHAR2(100) := 'PROF_NAME';
--    cv_tkn_in_parm        CONSTANT VARCHAR2(100) := 'IN_PARM';
--    -- トークンセット値
--    cv_item_code_char     CONSTANT VARCHAR2(100) := '品目コード';
--    cv_qty_char           CONSTANT VARCHAR2(100) := '数量';
--    cv_qty_standard_date  CONSTANT VARCHAR2(100) := '基準日';
--    -- プロファイル
--    cv_prof_mast_org_id   CONSTANT VARCHAR2(30)  := 'XXCMN_MASTER_ORG_ID'; -- XXCMN:マスタ組織
--    cv_prof_pallet_waight CONSTANT VARCHAR2(30)  := 'XXWSH_PALLET_WEIGHT'; -- XXWSH:パレット重量
---- 2008/11/12 H.Itou Add Start 統合テスト指摘597
--    cv_prof_p_weight_s_date CONSTANT VARCHAR2(50)  := 'XXWSH_PALLET_WEIGHT_START_DATE'; -- XXWSH:パレット重量加味開始日
---- 2008/11/12 H.Itou Add End
--    -- 商品区分
--    cv_prod_class_drink   CONSTANT VARCHAR2(1)   := '2';                   -- ドリンク
--    -- 品目区分
--    cv_item_class_product CONSTANT VARCHAR2(1)   := '5';                   -- 製品
--    -- 切り上げ用定数
--    cn_rounup_const_no    CONSTANT NUMBER        := 0.9;
--    -- 丸め桁数
--    cn_roundup_digits     CONSTANT NUMBER        := 0;
--    -- 単位換算(1) 立法センチメートル->立方メートル
--    cn_conv_cm3_to_m3     CONSTANT NUMBER        := 1000000;
--    -- 単位換算(2) グラム->キログラム
--    cn_conv_g_to_kg       CONSTANT NUMBER        := 1000;
---- Ver1.27 M.Hokkanji Start
--    cn_roundup_no         CONSTANT NUMBER        := 1;                    -- 切り上げ用数量
---- Ver1.27 M.Hokkanji End
----
--    -- *** ローカル変数 ***
--    -- エラー変数
--    lv_errmsg             VARCHAR2(1000);
--    lv_err_cd             VARCHAR2(30);
----
--    -- プロファイル変数
--    ln_mst_org_id         mtl_parameters.organization_id%TYPE;            -- マスタ組織ID
--    ln_pallet_waight      NUMBER;                                         -- パレット重量
---- 2008/11/12 H.Itou Add Start 統合テスト指摘597
--    ld_p_weight_s_date    DATE;                                           -- パレット重量加味開始日
---- 2008/11/12 H.Itou Add End
----
--    -- 品目マスタ項目
--    ln_weight             NUMBER;                                         -- 重量
--    ln_capacity           NUMBER;                                         -- 容積
--    ln_delivery_qty       NUMBER;                                         -- 配数
--    ln_max_palette_steps  NUMBER;                                         -- パレット当り最大段数
--    ln_num_of_cases       NUMBER;                                         -- ケース入数
--    lv_conv_unit          xxcmn_item_mst_v.conv_unit%TYPE;                -- 入出庫換算単位
--    lv_prod_class_code    xxcmn_item_categories5_v.prod_class_code%TYPE;  -- 商品区分
--    lv_item_class_code    xxcmn_item_categories5_v.item_class_code%TYPE;  -- 品目区分
----
--    ln_pallet_qty         NUMBER DEFAULT 0;                               -- パレット枚数
--    ln_pallet_sum_weight  NUMBER DEFAULT 0;                               -- 合計パレット重量
----
--    -- *** ローカル・カーソル ***
----
--    -- *** ローカル・レコード ***
----
--    -- ===============================
--    -- ユーザー定義例外
--    -- ===============================
----
--  BEGIN
----
--    -- ***********************************************
--    -- ***      共通関数処理ロジックの記述         ***
--    -- ***********************************************
----
--    /*************************************
--     *  プロファイル取得(B-1)            *
--     *************************************/
--    --
--    ln_mst_org_id    := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_mast_org_id ));   -- 品目マスタ組織ID
--    ln_pallet_waight := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_pallet_waight )); -- パレット重量
---- 2008/11/12 H.Itou Add Start 統合テスト指摘597
--    ld_p_weight_s_date := TO_DATE( FND_PROFILE.VALUE( cv_prof_p_weight_s_date ), gv_yyyymmdd );   -- パレット重量加味開始日
---- 2008/11/12 H.Itou Add End
--    --
--    -- エラー処理
--    -- 「XXCMN:マスタ組織」取得失敗
--    IF ( ln_mst_org_id    IS NULL ) THEN
--      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
--                                            cv_xxwsh_get_prof_err,
--                                            cv_tkn_prof_name,
--                                            cv_prof_mast_org_id);
--      lv_err_cd := cv_xxwsh_get_prof_err;
--      RAISE global_api_expt;
--    --
--    -- 「XXWSH:パレット重量」取得失敗
--    ELSIF ( ln_pallet_waight IS NULL ) THEN
--      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
--                                            cv_xxwsh_get_prof_err,
--                                            cv_tkn_prof_name,
--                                            cv_prof_pallet_waight);
--      lv_err_cd := cv_xxwsh_get_prof_err;
--      RAISE global_api_expt;
--    --
--    END IF;
---- 2008/11/12 H.Itou Add Start 統合テスト指摘597
--    -- 「XXWSH:パレット重量加味開始日」取得失敗
--    IF ( ld_p_weight_s_date IS NULL ) THEN
--      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
--                                            cv_xxwsh_get_prof_err,
--                                            cv_tkn_prof_name,
--                                            cv_prof_p_weight_s_date);
--      lv_err_cd := cv_xxwsh_get_prof_err;
--      RAISE global_api_expt;
--    END IF;
---- 2008/11/12 H.Itou Add End
--
----
--    /*************************************
--     *  必須入力パラメータチェック(B-2)  *
--     *************************************/
--    --
--    -- 品目コード
--    IF ( iv_item_no  IS NULL ) THEN
--      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
--                                            cv_xxwsh_indispensable_err,
--                                            cv_tkn_in_parm,
--                                            cv_item_code_char);
--      lv_err_cd := cv_xxwsh_indispensable_err;
--      RAISE global_api_expt;
--    --
--    -- 数量
--    ELSIF ( in_quantity IS NULL ) THEN
--      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
--                                            cv_xxwsh_indispensable_err,
--                                            cv_tkn_in_parm,
--                                            cv_qty_char);
--      lv_err_cd := cv_xxwsh_indispensable_err;
--      RAISE global_api_expt;
--    --
--    -- 基準日
--    ELSIF ( id_standard_date IS NULL ) THEN
--      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
--                                            cv_xxwsh_indispensable_err,
--                                            cv_tkn_in_parm,
--                                            cv_qty_standard_date);
--      lv_err_cd := cv_xxwsh_indispensable_err;
--      RAISE global_api_expt;
--    END IF;
----
--    /*************************************
--     *  品目マスタ抽出(B-3)              *
--     *************************************/
--    --
--    BEGIN
--      SELECT  to_number( ximv.unit ),               -- 重量
--              to_number( ximv.capacity ),           -- 容積
--              to_number( ximv.delivery_qty ),       -- 配数
--              to_number( ximv.max_palette_steps ),  -- パレット当り最大段数
--              to_number( ximv.num_of_cases ),       -- ケース入数
--              ximv.conv_unit,                       -- 入出庫換算単位
--              xicv.prod_class_code,                 -- 商品区分
--              xicv.item_class_code                  -- 品目区分
--      INTO    ln_weight,
--              ln_capacity,
--              ln_delivery_qty,
--              ln_max_palette_steps,
--              ln_num_of_cases,
--              lv_conv_unit,
--              lv_prod_class_code,
--              lv_item_class_code
--      FROM    xxcmn_item_mst2_v         ximv,      -- OPM品目情報VIEW2
--              xxcmn_item_categories5_v  xicv       -- OPM品目カテゴリ割当情報VIEW5
--      WHERE   ximv.item_no           =  iv_item_no
--        AND   xicv.item_id           =  ximv.item_id
--        AND   TRUNC(id_standard_date) BETWEEN ximv.start_date_active AND ximv.end_date_active
--      ;
--    EXCEPTION
--      WHEN  NO_DATA_FOUND THEN
--        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
--                                              cv_xxwsh_no_data_found_err,
--                                              cv_tkn_item_code,
--                                              iv_item_no);
--        lv_err_cd := cv_xxwsh_no_data_found_err;
--        RAISE global_api_expt;
--    END;
----
--     -- 業務例外チェック
--    -- ドリンクかつ製品の品目の場合
--    IF (  ( lv_prod_class_code = cv_prod_class_drink   )
--      AND ( lv_item_class_code = cv_item_class_product )) THEN
--    --
--    -- 配数が0またはNULLならエラー
--      IF ( NVL(ln_delivery_qty, 0) = 0 ) THEN
--        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
--                                              cv_xxwsh_get_deliv_qty_err,
--                                              cv_tkn_item_code,
--                                              iv_item_no);
--        lv_err_cd := cv_xxwsh_get_deliv_qty_err;
--        RAISE global_api_expt;
--    --
--    -- パレット当り最大段数が0またはNULLならエラー
--      ELSIF ( NVL(ln_max_palette_steps, 0) = 0 ) THEN
--        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
--                                              cv_xxwsh_palette_steps_err,
--                                              cv_tkn_item_code,
--                                              iv_item_no);
--        lv_err_cd := cv_xxwsh_palette_steps_err;
--        RAISE global_api_expt;
--    --
--    -- ケース入数が0またはNULLならエラー
--      ELSIF ( NVL(ln_num_of_cases, 0) = 0 ) THEN
--        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
--                                              cv_xxwsh_d_num_of_case_err,
--                                              cv_tkn_item_code,
--                                              iv_item_no);
--        lv_err_cd := cv_xxwsh_d_num_of_case_err;
--        RAISE global_api_expt;
--      END IF;
--    END IF;
--    --
--    -- 入出庫換算単位がNULL以外の場合、ケース入数が0またはNULLならエラー
--    IF (  ( lv_conv_unit IS NOT NULL )
--      AND ( NVL(ln_num_of_cases, 0) = 0 ) ) THEN
--        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
--                                              cv_xxwsh_num_of_case_err,
--                                              cv_tkn_item_code,
--                                              iv_item_no);
--        lv_err_cd := cv_xxwsh_num_of_case_err;
--        RAISE global_api_expt;
--    END IF;
----
--    /**********************************
--     *  合計パレット重量の算出(B-4)   *
--     **********************************/
--    --
--    -- ドリンク製品の場合のみ、数量分のパレット重量を算出する。
--    IF (  ( lv_prod_class_code = cv_prod_class_drink   )
--      AND ( lv_item_class_code = cv_item_class_product ) )
--    THEN
--      --「パレット枚数」の算出
--      ln_pallet_qty
--        := ( (  ( in_quantity   / ln_num_of_cases  ) / ln_delivery_qty  ) / ln_max_palette_steps);
--
---- Ver1.27 M.Hokkanji Start
--      -- 算出したパレット枚数から小数点を切り捨てたパレット枚数を引いた値が0より大きい場合パレット枚数に+1する
--      IF (ABS(ln_pallet_qty - TRUNC(ln_pallet_qty)) > 0) THEN
--        ln_pallet_qty := TRUNC(ln_pallet_qty) + cn_roundup_no;
--      END IF;
----      ln_pallet_qty
----        := TRUNC( ln_pallet_qty + cn_rounup_const_no , cn_roundup_digits );
---- Ver1.27 M.Hokkanji End
--      --
--      -- 「合計パレット重量」の算出
--      ln_pallet_sum_weight
--                    := ln_pallet_qty * ln_pallet_waight;
--    END IF;
--    --
----
--    /**********************************
--     *  合計値の算出(B-5)             *
--     **********************************/
--    --
--    -- 出力パラメータ「合計容積」「合計重量」
--    on_sum_capacity      := ( ln_capacity * in_quantity ) / cn_conv_cm3_to_m3;
--    on_sum_weight        := ( ln_weight   * in_quantity ) / cn_conv_g_to_kg;
--    -- 出力パラメータ「合計パレット重量」
---- 2008/11/12 H.Itou Add Start 統合テスト指摘597
--    -- 基準日がプロファイル：パレット重量加味開始日以降の場合、パレット重量は計算値を返す。
--    IF (TRUNC(id_standard_date) >= ld_p_weight_s_date) THEN
---- 2008/11/12 H.Itou Add End
--      on_sum_pallet_weight := ln_pallet_sum_weight;
---- 2008/11/12 H.Itou Add Start 統合テスト指摘597
--    -- 基準日がプロファイル：パレット重量加味開始日未満の場合、パレット重量は0を返す。
--    ELSE
--      on_sum_pallet_weight := 0;
--    END IF;
---- 2008/11/12 H.Itou Add End
--    --
--    -- ステータスコードセット
--    ov_retcode           := gv_status_normal;   -- リターンコード
--    ov_errmsg_code       := NULL;               -- エラーメッセージコード
--    ov_errmsg            := NULL;               -- エラーメッセージ
--    --
----
--    --==============================================================
--    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
--    --==============================================================
----
--  EXCEPTION
----
----#################################  固定例外処理部 START   ####################################
----
--    -- *** 共通関数例外ハンドラ ***
--    WHEN global_api_expt THEN
--      ov_errmsg      := lv_errmsg;
--      ov_errmsg_code := lv_err_cd;
--      ov_retcode     := gv_status_error;
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      ov_errmsg      := SQLERRM;
--      ov_errmsg_code := SQLCODE;
--      ov_retcode     := gv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errmsg      := SQLERRM;
--      ov_errmsg_code := SQLCODE;
--      ov_retcode     := gv_status_error;
----
----#####################################  固定部 END   ##########################################
----
--  END calc_total_value;
---- 2008/10/06 H.Itou Add End
-- 2009/03/19 H.Iida Del End
--
-- 2009/03/19 H.Iida Add Start 統合テスト指摘311
  /**********************************************************************************
   * Procedure Name   : calc_total_value
   * Description      : 積載効率チェック(合計値算出)
   ***********************************************************************************/
  PROCEDURE calc_total_value(
    iv_item_no                    IN  xxcmn_item_mst_v.item_no%TYPE,   -- 1.品目コード
    in_quantity                   IN  NUMBER,                          -- 2.数量
    ov_retcode                    OUT NOCOPY VARCHAR2,                 -- 3.リターンコード
    ov_errmsg_code                OUT NOCOPY VARCHAR2,                 -- 4.エラーメッセージコード
    ov_errmsg                     OUT NOCOPY VARCHAR2,                 -- 5.エラーメッセージ
    on_sum_weight                 OUT NOCOPY NUMBER,                   -- 6.合計重量
    on_sum_capacity               OUT NOCOPY NUMBER,                   -- 7.合計容積
    on_sum_pallet_weight          OUT NOCOPY NUMBER,                   -- 8.合計パレット重量
    id_standard_date              IN  DATE                             -- 9.基準日(適用日基準日)
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'calc_total_value';        -- プログラム名
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_mode_achievement  CONSTANT VARCHAR2(1) := '1';  -- 指示/実績区分 1:指示
--
    -- *** ローカル変数 ***
    lv_retcode           VARCHAR2(1);                  -- リターン・コード
    lv_errmsg_code       VARCHAR2(5000);               -- エラー・メッセージ・コード
    lv_errmsg            VARCHAR2(5000);               -- ユーザー・エラー・メッセージ
    ln_sum_weight        NUMBER;                       -- 合計重量
    ln_sum_capacity      NUMBER;                       -- 合計容積
    ln_sum_pallet_weight NUMBER;                       -- 合計パレット重量
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
--
    /**********************************************
     *  積載効率チェック(合計値算出)を指示で起動  *
     **********************************************/
    --
    xxwsh_common910_pkg.calc_total_value(
      iv_item_no           => iv_item_no,              -- パラメータ.品目コード
      in_quantity          => in_quantity,             -- パラメータ.数量
      ov_retcode           => lv_retcode,              -- リターンコード
      ov_errmsg_code       => lv_errmsg_code,          -- エラーメッセージコード
      ov_errmsg            => lv_errmsg,               -- エラーメッセージ
      on_sum_weight        => ln_sum_weight,           -- 合計重量
      on_sum_capacity      => ln_sum_capacity,         -- 合計容積
      on_sum_pallet_weight => ln_sum_pallet_weight,    -- 合計パレット重量
      id_standard_date     => id_standard_date,        -- パラメータ.基準日(適用日基準日)
      iv_mode              => cv_mode_achievement      -- 1:指示(固定)
    );
--
    /*************************
     *  OUTパラメータの設定  *
     *************************/
    ov_retcode           := lv_retcode;                -- リターンコード
    ov_errmsg_code       := lv_errmsg_code;            -- エラーメッセージコード
    ov_errmsg            := lv_errmsg;                 -- エラーメッセージ
    on_sum_weight        := ln_sum_weight;             -- 合計重量
    on_sum_capacity      := ln_sum_capacity;           -- 合計容積
    on_sum_pallet_weight := ln_sum_pallet_weight;      -- 合計パレット重量
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg      := SQLERRM;
      ov_errmsg_code := SQLCODE;
      ov_retcode     := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END calc_total_value;
-- 2009/03/19 H.Iida Add End
--
-- 2008/11/12 H.Itou Add Start 統合テスト指摘311 指示/実績区分を追加し、処理を分ける。
  /**********************************************************************************
   * Procedure Name   : calc_total_value
   * Description      : 積載効率チェック(合計値算出)
   ***********************************************************************************/
  PROCEDURE calc_total_value(
    iv_item_no                    IN  xxcmn_item_mst_v.item_no%TYPE,   -- 1.品目コード
    in_quantity                   IN  NUMBER,                          -- 2.数量
    ov_retcode                    OUT NOCOPY VARCHAR2,                 -- 3.リターンコード
    ov_errmsg_code                OUT NOCOPY VARCHAR2,                 -- 4.エラーメッセージコード
    ov_errmsg                     OUT NOCOPY VARCHAR2,                 -- 5.エラーメッセージ
    on_sum_weight                 OUT NOCOPY NUMBER,                   -- 6.合計重量
    on_sum_capacity               OUT NOCOPY NUMBER,                   -- 7.合計容積
    on_sum_pallet_weight          OUT NOCOPY NUMBER,                   -- 8.合計パレット重量
    id_standard_date              IN  DATE,                            -- 9.基準日(適用日基準日)
    iv_mode                       IN  VARCHAR2                         -- 10.指示/実績区分 1:指示 2:実績
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'calc_total_value';        --プログラム名
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- メッセージID
    cv_xxwsh_no_data_found_err CONSTANT VARCHAR2(100) := 'APP-XXWSH-12551'; -- 対象データなしエラーメッセージ
    cv_xxwsh_palette_steps_err CONSTANT VARCHAR2(100) := 'APP-XXWSH-12552'; -- パレット当り最大段数値ゼロエラーメッセージ
    cv_xxwsh_get_prof_err      CONSTANT VARCHAR2(100) := 'APP-XXWSH-12553'; -- プロファイル取得エラーメッセージ
    cv_xxwsh_get_deliv_qty_err CONSTANT VARCHAR2(100) := 'APP-XXWSH-12554'; -- 配数値ゼロエラーメッセージ
    cv_xxwsh_indispensable_err CONSTANT VARCHAR2(100) := 'APP-XXWSH-12555'; -- 必須入力パラメータ未設定エラーメッセージ
    cv_xxwsh_num_of_case_err   CONSTANT VARCHAR2(100) := 'APP-XXWSH-12556'; -- ケース入数値ゼロエラーメッセージ
    cv_xxwsh_d_num_of_case_err CONSTANT VARCHAR2(100) := 'APP-XXWSH-12557'; -- ドリンクケース入数値ゼロエラーメッセージ
    -- トークン
    cv_tkn_item_code      CONSTANT VARCHAR2(100) := 'ITEM_CODE';
    cv_tkn_prof_name      CONSTANT VARCHAR2(100) := 'PROF_NAME';
    cv_tkn_in_parm        CONSTANT VARCHAR2(100) := 'IN_PARM';
    -- トークンセット値
    cv_item_code_char     CONSTANT VARCHAR2(100) := '品目コード';
    cv_qty_char           CONSTANT VARCHAR2(100) := '数量';
    cv_qty_standard_date  CONSTANT VARCHAR2(100) := '基準日';
-- 2008/11/12 H.Itou Add Start 統合テスト指摘311
   cv_mode_char           CONSTANT VARCHAR2(100) := '指示/実績区分';
-- 2008/11/12 H.Itou Add End
    -- プロファイル
    cv_prof_mast_org_id   CONSTANT VARCHAR2(30)  := 'XXCMN_MASTER_ORG_ID'; -- XXCMN:マスタ組織
    cv_prof_pallet_waight CONSTANT VARCHAR2(30)  := 'XXWSH_PALLET_WEIGHT'; -- XXWSH:パレット重量
-- 2008/11/12 H.Itou Add Start 統合テスト指摘597
    cv_prof_p_weight_s_date CONSTANT VARCHAR2(50)  := 'XXWSH_PALLET_WEIGHT_START_DATE'; -- XXWSH:パレット重量加味開始日
-- 2008/11/12 H.Itou Add End
    -- 商品区分
    cv_prod_class_drink   CONSTANT VARCHAR2(1)   := '2';                   -- ドリンク
    -- 品目区分
    cv_item_class_product CONSTANT VARCHAR2(1)   := '5';                   -- 製品
    -- 切り上げ用定数
    cn_rounup_const_no    CONSTANT NUMBER        := 0.9;
    -- 丸め桁数
    cn_roundup_digits     CONSTANT NUMBER        := 0;
-- Ver1.27 M.Hokkanji Start
    cn_roundup_no         CONSTANT NUMBER        := 1;                    -- 切り上げ用数量
-- Ver1.27 M.Hokkanji End
    -- 単位換算(1) 立法センチメートル->立方メートル
    cn_conv_cm3_to_m3     CONSTANT NUMBER        := 1000000;
    -- 単位換算(2) グラム->キログラム
    cn_conv_g_to_kg       CONSTANT NUMBER        := 1000;
--
-- 2008/11/12 H.Itou Add Start 統合テスト指摘311
    -- INパラメータ.指示/実績区分
    cv_mode_plan          CONSTANT VARCHAR2(1)   := '1';    -- 指示
    cv_mode_result        CONSTANT VARCHAR2(1)   := '2';    -- 実績
-- 2008/11/12 H.Itou Add End
    -- *** ローカル変数 ***
    -- エラー変数
    lv_errmsg             VARCHAR2(1000);
    lv_err_cd             VARCHAR2(30);
--
    -- プロファイル変数
    ln_mst_org_id         mtl_parameters.organization_id%TYPE;            -- マスタ組織ID
    ln_pallet_waight      NUMBER;                                         -- パレット重量
-- 2008/11/12 H.Itou Add Start 統合テスト指摘597
    ld_p_weight_s_date    DATE;                                           -- パレット重量加味開始日
-- 2008/11/12 H.Itou Add End
--
    -- 品目マスタ項目
    ln_weight             NUMBER;                                         -- 重量
    ln_capacity           NUMBER;                                         -- 容積
    ln_delivery_qty       NUMBER;                                         -- 配数
    ln_max_palette_steps  NUMBER;                                         -- パレット当り最大段数
    ln_num_of_cases       NUMBER;                                         -- ケース入数
    lv_conv_unit          xxcmn_item_mst_v.conv_unit%TYPE;                -- 入出庫換算単位
    lv_prod_class_code    xxcmn_item_categories5_v.prod_class_code%TYPE;  -- 商品区分
    lv_item_class_code    xxcmn_item_categories5_v.item_class_code%TYPE;  -- 品目区分
--
    ln_pallet_qty         NUMBER DEFAULT 0;                               -- パレット枚数
    ln_pallet_sum_weight  NUMBER DEFAULT 0;                               -- 合計パレット重量
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
--
    /*************************************
     *  プロファイル取得(B-1)            *
     *************************************/
    --
    ln_mst_org_id    := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_mast_org_id ));   -- 品目マスタ組織ID
    ln_pallet_waight := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_pallet_waight )); -- パレット重量
-- 2008/11/12 H.Itou Add Start 統合テスト指摘597
    ld_p_weight_s_date := TO_DATE( FND_PROFILE.VALUE( cv_prof_p_weight_s_date ), gv_yyyymmdd );   -- パレット重量加味開始日
-- 2008/11/12 H.Itou Add End
    --
    -- エラー処理
    -- 「XXCMN:マスタ組織」取得失敗
    IF ( ln_mst_org_id    IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_get_prof_err,
                                            cv_tkn_prof_name,
                                            cv_prof_mast_org_id);
      lv_err_cd := cv_xxwsh_get_prof_err;
      RAISE global_api_expt;
    --
    -- 「XXWSH:パレット重量」取得失敗
    ELSIF ( ln_pallet_waight IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_get_prof_err,
                                            cv_tkn_prof_name,
                                            cv_prof_pallet_waight);
      lv_err_cd := cv_xxwsh_get_prof_err;
      RAISE global_api_expt;
    --
    END IF;
-- 2008/11/12 H.Itou Add Start 統合テスト指摘597
    -- 「XXWSH:パレット重量加味開始日」取得失敗
    IF ( ld_p_weight_s_date IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_get_prof_err,
                                            cv_tkn_prof_name,
                                            cv_prof_p_weight_s_date);
      lv_err_cd := cv_xxwsh_get_prof_err;
      RAISE global_api_expt;
    END IF;
-- 2008/11/12 H.Itou Add End

--
    /*************************************
     *  必須入力パラメータチェック(B-2)  *
     *************************************/
    --
    -- 品目コード
    IF ( iv_item_no  IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_indispensable_err,
                                            cv_tkn_in_parm,
                                            cv_item_code_char);
      lv_err_cd := cv_xxwsh_indispensable_err;
      RAISE global_api_expt;
    --
    -- 数量
    ELSIF ( in_quantity IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_indispensable_err,
                                            cv_tkn_in_parm,
                                            cv_qty_char);
      lv_err_cd := cv_xxwsh_indispensable_err;
      RAISE global_api_expt;
    --
    -- 基準日
    ELSIF ( id_standard_date IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_indispensable_err,
                                            cv_tkn_in_parm,
                                            cv_qty_standard_date);
      lv_err_cd := cv_xxwsh_indispensable_err;
      RAISE global_api_expt;
--
-- 2008/11/12 H.Itou Add Start 統合テスト指摘311
    -- 指示/実績区分
    ELSIF ( iv_mode IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_indispensable_err,
                                            cv_tkn_in_parm,
                                            cv_mode_char);
      lv_err_cd := cv_xxwsh_indispensable_err;
      RAISE global_api_expt;
-- 2008/11/12 H.Itou Add End
    END IF;
--
    /*************************************
     *  品目マスタ抽出(B-3)              *
     *************************************/
    --
    BEGIN
      SELECT  to_number( ximv.unit ),               -- 重量
              to_number( ximv.capacity ),           -- 容積
              to_number( ximv.delivery_qty ),       -- 配数
              to_number( ximv.max_palette_steps ),  -- パレット当り最大段数
              to_number( ximv.num_of_cases ),       -- ケース入数
              ximv.conv_unit,                       -- 入出庫換算単位
              xicv.prod_class_code,                 -- 商品区分
              xicv.item_class_code                  -- 品目区分
      INTO    ln_weight,
              ln_capacity,
              ln_delivery_qty,
              ln_max_palette_steps,
              ln_num_of_cases,
              lv_conv_unit,
              lv_prod_class_code,
              lv_item_class_code
      FROM    xxcmn_item_mst2_v         ximv,      -- OPM品目情報VIEW2
              xxcmn_item_categories5_v  xicv       -- OPM品目カテゴリ割当情報VIEW5
      WHERE   ximv.item_no           =  iv_item_no
        AND   xicv.item_id           =  ximv.item_id
        AND   TRUNC(id_standard_date) BETWEEN ximv.start_date_active AND ximv.end_date_active
      ;
    EXCEPTION
      WHEN  NO_DATA_FOUND THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                              cv_xxwsh_no_data_found_err,
                                              cv_tkn_item_code,
                                              iv_item_no);
        lv_err_cd := cv_xxwsh_no_data_found_err;
        RAISE global_api_expt;
    END;
--
     -- 業務例外チェック
    -- ドリンクかつ製品の品目の場合
    IF (  ( lv_prod_class_code = cv_prod_class_drink   )
      AND ( lv_item_class_code = cv_item_class_product )) THEN
    --
-- 2008/11/12 H.Itou Add Start 統合テスト指摘311
      -- 配数・段数チェックは指示/実績区分が1：指示の場合のみ。
      IF(iv_mode = cv_mode_plan) THEN
-- 2008/11/12 H.Itou Add End
        -- 配数が0またはNULLならエラー
        IF ( NVL(ln_delivery_qty, 0) = 0 ) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                                cv_xxwsh_get_deliv_qty_err,
                                                cv_tkn_item_code,
                                                iv_item_no);
          lv_err_cd := cv_xxwsh_get_deliv_qty_err;
          RAISE global_api_expt;
        --
        -- パレット当り最大段数が0またはNULLならエラー
        ELSIF ( NVL(ln_max_palette_steps, 0) = 0 ) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                                cv_xxwsh_palette_steps_err,
                                                cv_tkn_item_code,
                                                iv_item_no);
          lv_err_cd := cv_xxwsh_palette_steps_err;
          RAISE global_api_expt;
-- 2008/11/12 H.Itou Add Start 統合テスト指摘311
        END IF;
      END IF;
-- 2008/11/12 H.Itou Add End
      --
      -- ケース入数が0またはNULLならエラー
-- 2008/11/12 H.Itou Mod Start 統合テスト指摘311
--      ELSIF ( NVL(ln_num_of_cases, 0) = 0 ) THEN
      IF ( NVL(ln_num_of_cases, 0) = 0 ) THEN
-- 2008/11/12 H.Itou Mod End
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                              cv_xxwsh_d_num_of_case_err,
                                              cv_tkn_item_code,
                                              iv_item_no);
        lv_err_cd := cv_xxwsh_d_num_of_case_err;
        RAISE global_api_expt;
      END IF;
    END IF;
    --
    -- 入出庫換算単位がNULL以外の場合、ケース入数が0またはNULLならエラー
    IF (  ( lv_conv_unit IS NOT NULL )
      AND ( NVL(ln_num_of_cases, 0) = 0 ) ) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                              cv_xxwsh_num_of_case_err,
                                              cv_tkn_item_code,
                                              iv_item_no);
        lv_err_cd := cv_xxwsh_num_of_case_err;
        RAISE global_api_expt;
    END IF;
--
    /**********************************
     *  合計パレット重量の算出(B-4)   *
     **********************************/
    --
    -- ドリンク製品の場合のみ、数量分のパレット重量を算出する。
    IF (  ( lv_prod_class_code = cv_prod_class_drink   )
-- 2008/11/12 H.Itou Mod Start 統合テスト指摘311
--      AND ( lv_item_class_code = cv_item_class_product ) )
      AND ( lv_item_class_code = cv_item_class_product )
-- 2008/11/12 H.Itou Mod End
-- 2008/11/12 H.Itou Add Start 統合テスト指摘311 配数・段数が0かNULLでない場合のみ計算する。計算しない場合、合計パレット重量は0とする。
      AND ( NVL(ln_delivery_qty, 0)      <> 0 )
      AND ( NVL(ln_max_palette_steps, 0) <> 0 ) ) 
-- 2008/11/12 H.Itou Add End
    THEN
      --「パレット枚数」の算出
      ln_pallet_qty
        := ( (  ( in_quantity   / ln_num_of_cases  ) / ln_delivery_qty  ) / ln_max_palette_steps);
-- Ver1.27 M.Hokkanji Start
      -- 算出したパレット枚数から小数点を切り捨てたパレット枚数を引いた値が0より大きい場合パレット枚数に+1する
      IF (ABS(ln_pallet_qty - TRUNC(ln_pallet_qty)) > 0) THEN
        ln_pallet_qty := TRUNC(ln_pallet_qty) + cn_roundup_no;
      END IF;
--      ln_pallet_qty
--        := TRUNC( ln_pallet_qty + cn_rounup_const_no , cn_roundup_digits );
-- Ver1.27 M.Hokkanji End
      --
      -- 「合計パレット重量」の算出
      ln_pallet_sum_weight
                    := ln_pallet_qty * ln_pallet_waight;
    END IF;
    --
--
    /**********************************
     *  合計値の算出(B-5)             *
     **********************************/
    --
    -- 出力パラメータ「合計容積」「合計重量」
    on_sum_capacity      := ( ln_capacity * in_quantity ) / cn_conv_cm3_to_m3;
    on_sum_weight        := ( ln_weight   * in_quantity ) / cn_conv_g_to_kg;
    -- 出力パラメータ「合計パレット重量」
-- 2008/11/12 H.Itou Add Start 統合テスト指摘597
    -- 基準日がプロファイル：パレット重量加味開始日以降の場合、パレット重量は計算値を返す。
    IF (TRUNC(id_standard_date) >= ld_p_weight_s_date) THEN
-- 2008/11/12 H.Itou Add End
      on_sum_pallet_weight := ln_pallet_sum_weight;
-- 2008/11/12 H.Itou Add Start 統合テスト指摘597
    -- 基準日がプロファイル：パレット重量加味開始日未満の場合、パレット重量は0を返す。
    ELSE
      on_sum_pallet_weight := 0;
    END IF;
-- 2008/11/12 H.Itou Add End
    --
    -- ステータスコードセット
    ov_retcode           := gv_status_normal;   -- リターンコード
    ov_errmsg_code       := NULL;               -- エラーメッセージコード
    ov_errmsg            := NULL;               -- エラーメッセージ
    --
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg      := lv_errmsg;
      ov_errmsg_code := lv_err_cd;
      ov_retcode     := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg      := SQLERRM;
      ov_errmsg_code := SQLCODE;
      ov_retcode     := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg      := SQLERRM;
      ov_errmsg_code := SQLCODE;
      ov_retcode     := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END calc_total_value;
-- 2008/11/12 H.Itou Add End
  /**********************************************************************************
   * Procedure Name   : calc_load_efficiency
   * Description      : 積載効率チェック(積載効率算出)
   ***********************************************************************************/
  PROCEDURE calc_load_efficiency(
    in_sum_weight                 IN  NUMBER,                                              -- 1.合計重量
    in_sum_capacity               IN  NUMBER,                                              -- 2.合計容積
    iv_code_class1                IN  xxcmn_ship_methods.code_class1%TYPE,                 -- 3.コード区分１
    iv_entering_despatching_code1 IN  xxcmn_ship_methods.entering_despatching_code1%TYPE,  -- 4.入出庫場所コード１
    iv_code_class2                IN  xxcmn_ship_methods.code_class2%TYPE,                 -- 5.コード区分２
    iv_entering_despatching_code2 IN  xxcmn_ship_methods.entering_despatching_code2%TYPE,  -- 6.入出庫場所コード２
    iv_ship_method                IN  xxcmn_ship_methods.ship_method%TYPE,                 -- 7.出荷方法
    iv_prod_class                 IN  xxcmn_item_categories_v.segment1%TYPE,               -- 8.商品区分
    iv_auto_process_type          IN  VARCHAR2,                                            -- 9.自動配車対象区分
    id_standard_date              IN  DATE    DEFAULT SYSDATE,                      -- 10.基準日(適用日基準日)
    ov_retcode                    OUT NOCOPY VARCHAR2,                                     -- 11.リターンコード
    ov_errmsg_code                OUT NOCOPY VARCHAR2,                                     -- 12.エラーメッセージコード
    ov_errmsg                     OUT NOCOPY VARCHAR2,                                     -- 13.エラーメッセージ
    ov_loading_over_class         OUT NOCOPY VARCHAR2,                                     -- 14.積載オーバー区分
    ov_ship_methods               OUT NOCOPY xxcmn_ship_methods.ship_method%TYPE,          -- 15.出荷方法
    on_load_efficiency_weight     OUT NOCOPY NUMBER,                                       -- 16.重量積載効率
    on_load_efficiency_capacity   OUT NOCOPY NUMBER,                                       -- 17.容積積載効率
    ov_mixed_ship_method          OUT NOCOPY VARCHAR2                                      -- 18.混載配送区分
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'calc_load_efficiency'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- メッセージID
    cv_xxwsh_wt_cap_set_err    CONSTANT VARCHAR2(100) := 'APP-XXWSH-12601'; -- 積載重量容積なしエラーメッセージ
    cv_xxwsh_auto_type_err     CONSTANT VARCHAR2(100) := 'APP-XXWSH-12602'; -- 入力パラメータ「自動配車対象区分」不正
    cv_xxwsh_unconformity_err  CONSTANT VARCHAR2(100) := 'APP-XXWSH-12603'; -- 入力パラメータ不整合
    cv_xxwsh_in_prod_class_err CONSTANT VARCHAR2(100) := 'APP-XXWSH-12604'; -- 入力パラメータ「商品区分」不正
    cv_xxwsh_in_param_set_err  CONSTANT VARCHAR2(100) := 'APP-XXWSH-12605'; -- 入力パラメータ不正
    -- トークン
    cv_tkn_item_code               CONSTANT VARCHAR2(100) := 'ITEM_CODE';
    cv_tkn_prof_name               CONSTANT VARCHAR2(100) := 'PROF_NAME';
    cv_tkn_in_parm                 CONSTANT VARCHAR2(100) := 'IN_PARAM';
    -- トークンセット値
    cv_code_class1_char            CONSTANT VARCHAR2(100) := 'コード区分From';
    cv_entering_despatch_cd1_char  CONSTANT VARCHAR2(100) := '入出庫場所From';
    cv_code_class2_char            CONSTANT VARCHAR2(100) := 'コード区分To';
    cv_entering_despatch_cd2_char  CONSTANT VARCHAR2(100) := '入出庫場所To';
    cv_prod_class_char             CONSTANT VARCHAR2(100) := '商品区分';
--
    -- 商品区分
    cv_prod_class_leaf             CONSTANT VARCHAR2(1) := '1';  -- リーフ
    cv_prod_class_drink            CONSTANT VARCHAR2(1) := '2';  -- ドリンク
--
    -- 顧客区分
    cv_cust_class_base             CONSTANT VARCHAR2(1) := '1';  -- 拠点
    cv_cust_class_deliver          CONSTANT VARCHAR2(1) := '9';  -- 配送先
--
    -- 積載オーバー区分
    cv_not_loading_over            CONSTANT VARCHAR2(1) := '0';  -- 正常
    cv_loading_over                CONSTANT VARCHAR2(1) := '1';  -- 積載オーバー
--
    cv_all_4                       CONSTANT VARCHAR2(4) := 'ZZZZ';      -- 2008/07/14 変更要求対応#95
    cv_all_9                       CONSTANT VARCHAR2(9) := 'ZZZZZZZZZ'; -- 2008/07/14 変更要求対応#95
--
-- 2008/08/04 Add H.Itou Start
  -- コード区分
    cv_code_class_whse       CONSTANT VARCHAR2(10) := '4';  -- 配送先
    cv_code_class_ship       CONSTANT VARCHAR2(10) := '9';  -- 出荷
    cv_code_class_supply     CONSTANT VARCHAR2(10) := '11'; -- 支給
-- Ver1.26 M.Hokkanji Start
    cv_log_level            CONSTANT VARCHAR2(1)   := '6';                   -- ログレベル
    cv_colon                CONSTANT VARCHAR2(1)   := ':';                   -- コロン
-- Ver1.26 M.Hokkanji End
-- 2008/08/04 Add H.Itou End
-- 2008/08/04 H.Itou Del Start
--    -- 動的SQL文
--    -- メインSQL
--    cv_main_sql1                   CONSTANT VARCHAR2(32000)
--      :=    ' SELECT'
--         || '   xdlv.ship_method             AS ship_method_code,';
--    cv_main_sql2                   CONSTANT VARCHAR2(32000)
--      :=    '   xsmv.mixed_ship_method_code  AS mixed_ship_method_code  '
--         || ' FROM'
--         || '   xxcmn_delivery_lt2_v  xdlv,'
--         || '   xxwsh_ship_method2_v  xsmv'
--         || ' WHERE'
--         || '   xdlv.code_class1                = :iv_code_class1'
--         || '   AND'
--         || '   xdlv.entering_despatching_code1 = :iv_entering_despatching_code1'
--         || '   AND'
--         || '   xdlv.code_class2                = :iv_code_class2'
--         || '   AND'
--         || '   xdlv.entering_despatching_code2 = :iv_entering_despatching_code2'
--         || '   AND'
--         || '   xdlv.lt_start_date_active      <= trunc(:id_standard_date)'
--         || '   AND'
--         || '   xdlv.lt_end_date_active        >= trunc(:id_standard_date)'
--         || '   AND'
--         || '   xdlv.sm_start_date_active      <= trunc(:id_standard_date)'
--         || '   AND'
--         || '   xdlv.sm_end_date_active        >= trunc(:id_standard_date)'
--         || '   AND'
--         || '   (( xsmv.start_date_active      <= trunc(:id_standard_date))'
--         || '     OR'
--         || '    ( xsmv.start_date_active IS NULL ))'
--         || '   AND'
--         || '   (( xsmv.end_date_active        >= trunc(:id_standard_date))'
--         || '     OR'
--         || '    ( xsmv.end_date_active   IS NULL ))'
--         || '   AND'
--         || '   xdlv.ship_method           = NVL( :iv_ship_method, xdlv.ship_method )'
--         || '   AND'
--         || '   xsmv.ship_method_code      = xdlv.ship_method'
--         || '   AND'
--         || '   NVL( xsmv.auto_process_type, ''0'' )'
--         || '       = NVL( :iv_auto_process_type, NVL(xsmv.auto_process_type,''0'') )';
----         || '   AND';
--
--    -- 出荷方法を指定しなかった場合の追加条件
--    cv_main_sql3                   CONSTANT VARCHAR2(32000)
--      :=  ' AND'
--       || ' xsmv.mixed_class = ''0'' '
--       || ' AND';
----
--    -- OUTPUT_COLUMN
--    cv_column_w1                   CONSTANT VARCHAR2(32000)
--      := 'xdlv.drink_deadweight          AS deadweight,';
--    cv_column_w2                   CONSTANT VARCHAR2(32000)
--      := 'xdlv.leaf_deadweight           AS deadweight,';
--    cv_column_c1                   CONSTANT VARCHAR2(32000)
--      := 'xdlv.drink_loading_capacity    AS loading_capacity,';
--    cv_column_c2                   CONSTANT VARCHAR2(32000)
--      := 'xdlv.leaf_loading_capacity     AS loading_capacity,';
--    -- ORDER BY
--    cv_order_by1                   CONSTANT VARCHAR2(32000)
--      :=    '   xdlv.drink_deadweight > 0'
--         || ' ORDER BY'
--         || '   xdlv.drink_deadweight DESC';
--    cv_order_by2                   CONSTANT VARCHAR2(32000)
--      :=    '   xdlv.leaf_deadweight > 0'
--         || ' ORDER BY'
--         || '   xdlv.leaf_deadweight  DESC';
--    cv_order_by3                   CONSTANT VARCHAR2(32000)
--      :=    '   xdlv.drink_loading_capacity > 0'
--         || ' ORDER BY'
--         || '   xdlv.drink_loading_capacity DESC';
--    cv_order_by4                   CONSTANT VARCHAR2(32000)
--      :=    '   xdlv.leaf_loading_capacity > 0'
--         || ' ORDER BY'
--         || '   xdlv.leaf_loading_capacity  DESC';
-- 2008/08/04 H.Itou Del End
-- 2008/09/05 H.Itou Add Start PT 6-2_34 指摘#34対応
    -- =========================
    -- 積載効率取得SQL
    -- =========================
    cv_select                CONSTANT VARCHAR2(32000) :=
         '  SELECT /*+ use_nl(xdlv.xdl xdlv.xsm xsmv.flv) */           '
      || '         xdlv.ship_method             ship_method            ' -- 出荷方法
      || '        ,xsmv.mixed_ship_method_code  mixed_ship_method_code ' -- 混載配送区分
      ;
    cv_select_leaf_weight    CONSTANT VARCHAR2(32000) :=
         '        ,xdlv.leaf_deadweight         deadweight             ';-- リーフ積載重量
    cv_select_drink_weight   CONSTANT VARCHAR2(32000) :=
         '        ,xdlv.drink_deadweight        deadweight             ';-- ドリンク積載重量
    cv_select_leaf_capacity  CONSTANT VARCHAR2(32000) :=
         '        ,xdlv.leaf_loading_capacity   loading_capacity       ';-- リーフ積載容積
    cv_select_drink_capacity CONSTANT VARCHAR2(32000) :=
         '        ,xdlv.drink_loading_capacity  loading_capacity       ';-- ドリンク積載容積
    cv_select_sql_sort1      CONSTANT VARCHAR2(32000) :=
         '        ,1                            sql_sort               ';-- 優先① 入出庫場所（個別－個別）
    cv_select_sql_sort2      CONSTANT VARCHAR2(32000) :=
         '        ,2                            sql_sort               ';-- 優先② 入出庫場所（ZZZZ－個別）
    cv_select_sql_sort3      CONSTANT VARCHAR2(32000) :=
         '        ,3                            sql_sort               ';-- 優先③ 入出庫場所（個別－ZZZZ）
    cv_select_sql_sort4      CONSTANT VARCHAR2(32000) :=
         '        ,4                            sql_sort               ';-- 優先④ 入出庫場所（ZZZZ－ZZZZ）
    cv_from                  CONSTANT VARCHAR2(32000) := 
         '  FROM   xxcmn_delivery_lt2_v  xdlv                          ' -- 配送L/T情報VIEW2
      || '        ,xxwsh_ship_method2_v  xsmv                          ';-- 配送区分情報VIEW2
    cv_where                CONSTANT VARCHAR2(32000) := 
         '  WHERE  xsmv.ship_method_code                = xdlv.ship_method               ' -- 結合条件
      || '  AND    xdlv.code_class1                     = :lv_code_class1                ' -- コード区分１
      || '  AND    xdlv.code_class2                     = :lv_code_class2                ' -- コード区分２
      || '  AND    xdlv.lt_start_date_active           <= TRUNC(:ld_standard_date)       '
      || '  AND    xdlv.lt_end_date_active             >= TRUNC(:ld_standard_date)       '
      || '  AND    xdlv.sm_start_date_active           <= TRUNC(:ld_standard_date)       '
      || '  AND    xdlv.sm_end_date_active             >= TRUNC(:ld_standard_date)       '
      || '  AND (( xsmv.start_date_active              <= TRUNC(:ld_standard_date))      '
      || '    OR ( xsmv.start_date_active              IS NULL ))                        '
      || '  AND (( xsmv.end_date_active                >= TRUNC(:ld_standard_date))      '
      || '    OR ( xsmv.end_date_active                IS NULL ))                        '
      || '  AND    xdlv.ship_method                     = NVL(:lv_ship_method, xdlv.ship_method ) ' -- 出荷方法
      || '  AND    NVL( xsmv.auto_process_type, ''0'' ) = NVL(:lv_auto_process_type, NVL(xsmv.auto_process_type, ''0'')) '-- 自動配車対象区分
      || '  AND    xdlv.entering_despatching_code1      = :lv_entering_despatching_code1 ' -- 入出庫場所１
      || '  AND    xdlv.entering_despatching_code2      = :lv_entering_despatching_code2 ' -- 入出庫場所２
      ;
    cv_where_leaf_weight     CONSTANT VARCHAR2(32000) :=
         '  AND    xdlv.leaf_deadweight                 > 0                              '; -- リーフ積載重量＞0
    cv_where_drink_weight    CONSTANT VARCHAR2(32000) :=
         '  AND    xdlv.drink_deadweight                > 0                              '; -- ドリンク積載重量＞0
    cv_where_leaf_capacity   CONSTANT VARCHAR2(32000) :=
         '  AND    xdlv.leaf_loading_capacity           > 0                              '; -- リーフ積載容積＞0
    cv_where_drink_capacity  CONSTANT VARCHAR2(32000) :=
         '  AND    xdlv.drink_loading_capacity          > 0                              '; -- ドリンク積載容積＞0
    cv_where_mixed_class     CONSTANT VARCHAR2(32000) :=
         '  AND    xsmv.mixed_class                     = ''0''                          '; -- 混載区分='0'(混載なし)
    cv_order_by              CONSTANT VARCHAR2(32000) :=
         '  ORDER BY ship_method DESC ' -- 出荷方法         降順 
      || '          ,sql_sort         ' -- 入出庫場所優先順 昇順 
      ;
    cv_union_all             CONSTANT VARCHAR2(32000) := ' UNION ALL ';
-- 2008/09/05 H.Itou Add End
--
    -- *** ローカル変数 ***
    -- エラー変数
    lv_err_cd             VARCHAR2(30);
    -- 動的SQL格納用
    lv_sql                     VARCHAR2(32000);
    lv_column_w                VARCHAR2(32000);
    lv_column_c                VARCHAR2(32000);
    lv_order_by                VARCHAR2(32000);
-- 2008/09/05 H.Itou Add Start PT 6-2_34 指摘#34対応
    lv_select_deadweight       VARCHAR2(32000);  -- SELECT句 [動的項目]積載重量
    lv_select_loading_capacity VARCHAR2(32000);  -- SELECT句 [動的項目]積載容積
    lv_where_remove_zero       VARCHAR2(32000);  -- WHERE句  [動的項目]積載重量OR積載容積＞0
    lv_where_mixed_class       VARCHAR2(32000);  -- WHERE句  [動的項目]混載区分=0
-- 2008/09/05 H.Itou Add End
    --
    -- 関連データ格納用
    lv_base_code               VARCHAR2(4);                                       -- 拠点コード
    ln_load_efficiency         NUMBER;                                            -- 積載効率
    ln_ship_method             xxcmn_delivery_lt2_v.ship_method%TYPE;             -- 出荷方法
    ln_mixed_ship_method_code  xxwsh_ship_method2_v.mixed_ship_method_code%TYPE;  -- 混載配送区分
    lv_auto_process_type       xxwsh_ship_method2_v.auto_process_type%TYPE;       -- 自動配車対象区分
-- 2008/08/04 H.Itou Add Start
    ln_sum_weight                 NUMBER;                                              -- 合計重量
    ln_sum_capacity               NUMBER;                                              -- 合計容積
    lv_code_class1                xxcmn_ship_methods.code_class1%TYPE;                 -- コード区分１
    lv_code_class2                xxcmn_ship_methods.code_class2%TYPE;                 -- コード区分２
    lv_ship_method                xxcmn_ship_methods.ship_method%TYPE;                 -- 出荷方法
    lv_prod_class                 xxcmn_item_categories_v.segment1%TYPE;               -- 商品区分
    ld_standard_date              DATE;                                                -- 基準日(適用日基準日)
-- 2008/08/04 H.Itou Add End
-- 2008/09/05 H.Itou Add Start PT 6-2_34 指摘#34対応
    lv_all_z_dummy_code2          VARCHAR2(9);     -- 入出庫場所コード2のダミーコード
-- 2008/09/05 H.Itou Add End
--
    -- 退避用
    ln_load_efficiency_tmp     NUMBER;                                              -- 積載効率
    ln_ship_method_tmp           xxcmn_delivery_lt2_v.ship_method%TYPE;             -- 出荷方法
    ln_mixed_ship_method_cd_tmp  xxwsh_ship_method2_v.mixed_ship_method_code%TYPE;  -- 混載配送区分
    --
    lv_entering_despatching_code1  xxcmn_delivery_lt2_v.entering_despatching_code1%TYPE; -- 2008/07/14 変更要求対応#95
    lv_entering_despatching_code2  xxcmn_delivery_lt2_v.entering_despatching_code2%TYPE; -- 2008/07/14 変更要求対応#95
--
    -- *** ローカル・カーソル ***
-- 2008/09/05 H.Itou Del Start PT 6-2_34 指摘#34対応 動的SQLに変更
---- 2008/08/04 H.Itou Add Start
--    -- 積載効率取得カーソル
--    CURSOR lc_ref IS
--      SELECT subsql.ship_method              ship_method            -- 出荷方法
--            ,subsql.mixed_ship_method_code   mixed_ship_method_code -- 混載配送区分
--            ,subsql.deadweight               deadweight             -- 積載重量
--            ,subsql.loading_capacity         loading_capacity       -- 積載容積
--      FROM  ( SELECT xdlv.ship_method                ship_method            -- 出荷方法
--                    ,xsmv.mixed_ship_method_code     mixed_ship_method_code -- 混載配送区分
--                    ,CASE
--                      -- 商品区分 1:リーフの場合、リーフ重量を積載重量とする。
--                      WHEN (lv_prod_class = cv_prod_class_leaf) THEN
--                        xdlv.leaf_deadweight
--                      -- 商品区分 2:ドリンク の場合、ドリンク重量を積載重量とする。
--                      WHEN (lv_prod_class = cv_prod_class_drink) THEN
--                        xdlv.drink_deadweight
--                     END  deadweight  -- 積載重量
--                    ,CASE
--                      -- 商品区分 1:リーフの場合、リーフ容積を積載容積とする。
--                      WHEN (lv_prod_class = cv_prod_class_leaf) THEN
--                        xdlv.leaf_loading_capacity
--                      -- 商品区分 2:ドリンク の場合、ドリンク容積を積載容積とする。
--                      WHEN (lv_prod_class = cv_prod_class_drink) THEN
--                        xdlv.drink_loading_capacity
--                     END  loading_capacity  -- 積載容積
--                    ,CASE
--                       -- 優先① 入出庫場所（個別－個別）
--                       WHEN ((xdlv.entering_despatching_code1 = lv_entering_despatching_code1)
--                        AND  (xdlv.entering_despatching_code2 = lv_entering_despatching_code2)) THEN
--                          1
--                       -- 優先② 入出庫場所（ZZZZ－個別）
--                       WHEN ((xdlv.entering_despatching_code1 = cv_all_4)
--                         AND (xdlv.entering_despatching_code2 = lv_entering_despatching_code2)) THEN
--                          2
--                       -- 優先③ 入出庫場所（個別－ZZZZ）
--                       WHEN ((xdlv.entering_despatching_code1 = lv_entering_despatching_code1)
--                         AND ((((xdlv.code_class2 IN (cv_code_class_whse, cv_code_class_supply)) AND (xdlv.entering_despatching_code2 = cv_all_4)))
--                           OR (((xdlv.code_class2 = cv_code_class_ship) AND (xdlv.entering_despatching_code2 = cv_all_9))))) THEN
--                          3
--                       -- 優先④ 入出庫場所（ZZZZ－ZZZZ）
--                       WHEN ((xdlv.entering_despatching_code1 = cv_all_4)
--                         AND (((xdlv.code_class2 IN (cv_code_class_whse, cv_code_class_supply)) AND (xdlv.entering_despatching_code2 = cv_all_4))
--                           OR ((xdlv.code_class2 = cv_code_class_ship) AND (xdlv.entering_despatching_code2 = cv_all_9)))) THEN
--                          4
--                     END  sql_sort         -- 入出庫場所優先順
--              FROM   xxcmn_delivery_lt2_v  xdlv        -- 配送L/T情報VIEW2
--                    ,xxwsh_ship_method2_v  xsmv        -- 配送区分情報VIEW2
--              WHERE xsmv.ship_method_code      = xdlv.ship_method  -- 結合条件
--                AND xdlv.code_class1 = lv_code_class1  -- コード区分１
--                AND xdlv.code_class2 = lv_code_class2  -- コード区分２
--                AND xdlv.lt_start_date_active      <= TRUNC(ld_standard_date)
--                AND xdlv.lt_end_date_active        >= TRUNC(ld_standard_date)
--                AND xdlv.sm_start_date_active      <= TRUNC(ld_standard_date)
--                AND xdlv.sm_end_date_active        >= TRUNC(ld_standard_date)
--                AND (( xsmv.start_date_active      <= TRUNC(ld_standard_date))
--                  OR ( xsmv.start_date_active IS NULL ))
--                AND (( xsmv.end_date_active        >= TRUNC(ld_standard_date))
--                  OR ( xsmv.end_date_active   IS NULL ))
--                AND xdlv.ship_method           = NVL( lv_ship_method, xdlv.ship_method ) -- 出荷方法
--                AND NVL( xsmv.auto_process_type, '0' ) = NVL(lv_auto_process_type, NVL(xsmv.auto_process_type,'0')) -- 自動配車対象区分
--                -- 優先① 入出庫場所（個別－個別）
--                AND(((xdlv.entering_despatching_code1 = lv_entering_despatching_code1)
--                 AND (xdlv.entering_despatching_code2 = lv_entering_despatching_code2))
--                -- 優先② 入出庫場所（ZZZZ－個別）
--                  OR ((xdlv.entering_despatching_code1 = cv_all_4)
--                   AND (xdlv.entering_despatching_code2 = lv_entering_despatching_code2))
--                -- 優先③ 入出庫場所（個別－ZZZZ）
--                  OR (((xdlv.entering_despatching_code1 = lv_entering_despatching_code1))
--                   AND (((xdlv.code_class2 IN (cv_code_class_whse, cv_code_class_supply)) AND (xdlv.entering_despatching_code2 = cv_all_4))
--                     OR ((xdlv.code_class2 = cv_code_class_ship) AND (xdlv.entering_despatching_code2 = cv_all_9))))
--                -- 優先④ 入出庫場所（ZZZZ－ZZZZ）
--                  OR (((xdlv.entering_despatching_code1 = cv_all_4))
--                   AND (((xdlv.code_class2 IN (cv_code_class_whse, cv_code_class_supply)) AND (xdlv.entering_despatching_code2 = cv_all_4))
--                     OR ((xdlv.code_class2 = cv_code_class_ship) AND (xdlv.entering_despatching_code2 = cv_all_9)))))
--                -- 出荷方法に値なし かつ、商品区分 1:リーフ かつ 合計重量に値あり の場合、リーフ重量を条件に追加
--                AND (((lv_ship_method IS NULL) AND (lv_prod_class = cv_prod_class_leaf)  AND (ln_sum_weight IS NOT NULL)  AND (xdlv.leaf_deadweight > 0))
--                -- 出荷方法に値なし かつ、商品区分 1:リーフ かつ 合計重量に値なし の場合、リーフ容積を条件に追加
--                  OR ((lv_ship_method IS NULL) AND (lv_prod_class = cv_prod_class_leaf)  AND (ln_sum_weight IS NULL)      AND (xdlv.leaf_loading_capacity > 0))
--                -- 出荷方法に値なし かつ、商品区分 2:ドリンク かつ 合計重量に値あり の場合、ドリンク重量を条件に追加
--                  OR ((lv_ship_method IS NULL) AND (lv_prod_class = cv_prod_class_drink) AND (ln_sum_weight IS  NOT NULL) AND (xdlv.drink_deadweight > 0))
--                -- 出荷方法に値なし かつ、商品区分 2:ドリンク かつ 合計重量に値なし の場合、ドリンク容積を条件に追加
--                  OR ((lv_ship_method IS NULL) AND (lv_prod_class = cv_prod_class_drink) AND (ln_sum_weight IS NULL)      AND (xdlv.drink_loading_capacity > 0))
--                -- 出荷方法に値ありの場合は、積載重量・積載容積を条件としない。
--                  OR ((lv_ship_method IS NOT NULL)))
--              ) subsql
--      ORDER BY subsql.ship_method DESC  -- 出荷方法         降順
--              ,subsql.sql_sort          -- 入出庫場所優先順 昇順
--    ;
---- 2008/08/04 H.Itou Add End
-- 2008/09/05 H.Itou Del End
-- 2008/08/04 H.Itou Del Start
-- 2008/09/05 H.Itou Mod Start PT 6-2_34 指摘#34対応 動的SQLに変更のため、再度使用。
    TYPE ref_cursor   IS REF CURSOR ;           -- 1. 倉庫(個別コード)－配送先(個別コード)の検索チェック用カーソル
    lc_ref     ref_cursor ;
-- 2008/09/05 H.Itou Mod End
--    --
--    TYPE ref_cursor2  IS REF CURSOR ;           -- 1.でNOTFOUNDで、2.3.4.のいずれかでFOUNDした場合に使用するカーソル
--    lc_ref2    ref_cursor2 ;
----
--    -- 2008/07/14 変更要求対応#95 Start ------------------------
--    TYPE fnd_chk_cursor2   IS REF CURSOR ;      -- 2. 倉庫(ALL値)－配送先(個別コード)の検索チェック用カーソル
--    lc_fnd_chk2     fnd_chk_cursor2 ;
--    --
--    TYPE fnd_chk_cursor3   IS REF CURSOR ;      -- 3. 倉庫(個別コード)－配送先(ALL値)の検索チェック用カーソル
--    lc_fnd_chk3     fnd_chk_cursor3 ;
--    --
--    TYPE fnd_chk_cursor4   IS REF CURSOR ;      -- 4. 倉庫(ALL値)－配送先(ALL値)の検索チェック用カーソル
--    lc_fnd_chk4     fnd_chk_cursor4 ;
--    -- 2008/07/14 変更要求対応#95 End ---------------------------
-- 2008/08/04 H.Itou Del End
--
    -- *** ローカル・レコード ***
-- 2008/09/05 H.Itou Del Start PT 6-2_34 指摘#34対応 動的SQLに変更
---- 2008/08/04 H.Itou Add Start
--    lr_ref  lc_ref%ROWTYPE;  -- カーソル用レコード
---- 2008/08/04 H.Itou Add End
-- 2008/09/05 H.Itou Del End
--
-- 2008/08/04 H.Itou Del Start
-- 2008/09/05 H.Itou Mod Start PT 6-2_34 指摘#34対応 動的SQLに変更のため、再度使用。
    TYPE ret_value  IS RECORD
      (
        ship_method                xxcmn_delivery_lt2_v.ship_method%TYPE        -- 出荷方法
       ,mixed_ship_method_code     xxwsh_ship_method2_v.mixed_ship_method_code%TYPE -- 混載配送区分
       ,deadweight                 NUMBER                                       -- 積載重量
       ,loading_capacity           NUMBER                                       -- 積載容積
       ,sql_sort                   NUMBER                                       -- ソート順 -- 2008/08/05 H.Itou Add
      );
    lr_ref        ret_value ;
-- 2008/09/05 H.Itou Mod End
--    lr_ref2       ret_value ;
--    lr_fnd_chk2   ret_value ;      -- 2008/07/14 変更要求対応#95
--    lr_fnd_chk3   ret_value ;      -- 2008/07/14 変更要求対応#95
--    lr_fnd_chk4   ret_value ;      -- 2008/07/14 変更要求対応#95
-- 2008/08/04 H.Itou Del End
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    --
    /**********************************
     *  パラメータチェック(C-1)       *
     **********************************/
    -- 必須入力パラメータチェック
    -- コード区分From
    IF ( iv_code_class1  IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_in_param_set_err,
                                            cv_tkn_in_parm,
                                            cv_code_class1_char);
      lv_err_cd := cv_xxwsh_in_param_set_err;
      RAISE global_api_expt;
    -- 入出庫場所From
    ELSIF ( iv_entering_despatching_code1  IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_in_param_set_err,
                                            cv_tkn_in_parm,
                                            cv_entering_despatch_cd1_char);
      lv_err_cd := cv_xxwsh_in_param_set_err;
      RAISE global_api_expt;
    -- コード区分To
    ELSIF ( iv_code_class2  IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_in_param_set_err,
                                            cv_tkn_in_parm,
                                            cv_code_class2_char);
      lv_err_cd := cv_xxwsh_in_param_set_err;
      RAISE global_api_expt;
    -- 入出庫場所To
    ELSIF ( iv_entering_despatching_code2  IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_in_param_set_err,
                                            cv_tkn_in_parm,
                                            cv_entering_despatch_cd2_char);
      lv_err_cd := cv_xxwsh_in_param_set_err;
      RAISE global_api_expt;
    -- 商品区分
    ELSIF ( iv_prod_class  IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_in_param_set_err,
                                            cv_tkn_in_parm,
                                            cv_prod_class_char);
      lv_err_cd := cv_xxwsh_in_param_set_err;
      RAISE global_api_expt;
    --
    -- 「合計重量」と「合計容積」いずれか一方のみセット
    ELSIF (( ( in_sum_weight   IS NULL )
         AND ( in_sum_capacity IS NULL ) )
      OR (   ( in_sum_weight   IS NOT NULL )
         AND ( in_sum_capacity IS NOT NULL ) ) ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_unconformity_err);
      lv_err_cd := cv_xxwsh_unconformity_err;
      RAISE global_api_expt;
    --
    -- 「商品区分」に、１（リーフ）、２（ドリンク）以外がセットされていないか
    ELSIF ( iv_prod_class NOT IN ( cv_prod_class_leaf ,cv_prod_class_drink ) ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_in_prod_class_err);
      lv_err_cd := cv_xxwsh_in_prod_class_err;
      RAISE global_api_expt;
    --
    -- 入力パラメータ「出荷方法」がセットされていない場合、
    -- 入力パラメータ「自動配車対象区分」がセットされているか。
    ELSIF (( iv_ship_method       IS NULL  )
      AND  ( iv_auto_process_type IS NULL  ) ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_auto_type_err);
      lv_err_cd := cv_xxwsh_auto_type_err;
      RAISE global_api_expt;
    END IF;
    --
    -- 入力パラメータ「出荷方法」がセットされ、かつ
    -- 入力パラメータ「自動配車対象区分」がセットされている場合、抽出条件としない。
    IF   ( ( iv_ship_method       IS NOT NULL  )
      AND  ( iv_auto_process_type IS NOT NULL  ) ) THEN
      lv_auto_process_type := NULL;
    ELSE
      lv_auto_process_type := iv_auto_process_type;
    END IF;
--
--
    /**********************************
     *  積載効率算出(C-2)             *
     **********************************/
-- 2008/08/04 H.Itou Del Start 動的SQL中止のため削除
--    -- 動的SQLの出力項目とORDER BY句を決める
--    IF ( iv_prod_class = cv_prod_class_leaf ) THEN
--      IF ( in_sum_weight IS NOT NULL ) THEN
--        lv_order_by := cv_order_by2;          -- リーフ重量
--      ELSE
--        lv_order_by := cv_order_by4;          -- リーフ容積
--      END IF;
--      --
--      lv_column_w := cv_column_w2;            -- リーフ積載重量
--      lv_column_c := cv_column_c2;            -- リーフ積載容積
--    ELSE
--      IF ( in_sum_weight IS NOT NULL ) THEN
--        lv_order_by := cv_order_by1;          -- ドリンク重量
--      ELSE
--        lv_order_by := cv_order_by3;          -- ドリンク容積
--      END IF;
--      lv_column_w := cv_column_w1;            -- ドリンク積載重量
--      lv_column_c := cv_column_c1;            -- ドリンク積載容積
--    END IF;
--    --
--    -- 動的SQL本文を決める
--    -- 出荷方法がセットされていない場合
--    IF ( iv_ship_method IS NULL ) THEN
--      lv_sql :=   cv_main_sql1
--               || lv_column_w
--               || lv_column_c
--               || cv_main_sql2
--               || cv_main_sql3
--               || lv_order_by;
----
--    ELSE
--      lv_sql :=   cv_main_sql1
--               || lv_column_w
--               || lv_column_c
--               || cv_main_sql2;
----               || lv_order_by;
--    END IF;
--    --
--    -- SQLの実行
--    OPEN lc_ref FOR lv_sql
--      USING
--        iv_code_class1,                      -- コード区分From
--        iv_entering_despatching_code1,       -- 入出庫場所From
--        iv_code_class2,                      -- コード区分To
--        iv_entering_despatching_code2,       -- 入出庫場所To
--        id_standard_date,                    -- 適用日
--        id_standard_date,
--        id_standard_date,
--        id_standard_date,
--        id_standard_date,
--        id_standard_date,
--        iv_ship_method,                      -- 出荷方法
--        lv_auto_process_type;                -- 自動配車対象区分
-- 2008/08/04 H.Itou Del End
-- 2008/08/04 H.Itou Add Start
    -- ローカル変数にINパラメータをセット
-- 2008/08/06 H.Itou Mod Start 合計重量・合計容積･･･小数点第一位を切り上げて計算する。
--    ln_sum_weight                 := in_sum_weight;                  -- 合計重量
    ln_sum_weight                 := CEIL(TRUNC(in_sum_weight, 1));  -- 合計重量
--    ln_sum_capacity               := in_sum_capacity;                -- 合計容積
    ln_sum_capacity               := CEIL(TRUNC(in_sum_capacity, 1));-- 合計容積
-- 2008/08/06 H.Itou Mod End
    lv_code_class1                := iv_code_class1;                 -- コード区分１
    lv_entering_despatching_code1 := iv_entering_despatching_code1;  -- 入出庫場所コード１
    lv_code_class2                := iv_code_class2;                 -- コード区分２
    lv_entering_despatching_code2 := iv_entering_despatching_code2;  -- 入出庫場所コード２
-- 2008/10/15 H.Itou Mod Start 統合テスト指摘298
--    lv_ship_method                := iv_ship_method;                 -- 出荷方法
    -- 出荷方法を混載なしの出荷方法に変換
    lv_ship_method := xxwsh_common_pkg.convert_mixed_ship_method(
                        it_ship_method_code => iv_ship_method
                      );
-- 2008/10/15 H.Itou Mod End
    lv_prod_class                 := iv_prod_class;                  -- 商品区分
    ld_standard_date              := NVL(id_standard_date, SYSDATE); -- 基準日(適用日基準日)
-- 2008/09/05 H.Itou Add Start PT 6-2_34 指摘#34対応 動的SQLに変更
    -- コード区分２が「9：出荷」の場合
    IF (lv_code_class2 = cv_code_class_ship) THEN
      lv_all_z_dummy_code2 := cv_all_9; -- 入出庫場所コード2のダミーコードはZZZZZZZZZ
--
    -- コード区分２が「4：配送先」「11：支給」の場合
    ELSE
      lv_all_z_dummy_code2 := cv_all_4; -- 入出庫場所コード2のダミーコードはZZZZ
    END IF;
-- 2008/09/05 H.Itou Add End
--
-- 2008/09/05 H.Itou Add Start PT 6-2_34 指摘#34対応 動的SQLに変更
   -- 動的SQL生成
   -- SELECT句積載重量・積載容積の決定
   -- 商品区分が「1：リーフ」の場合
   IF (lv_prod_class = cv_prod_class_leaf) THEN
     lv_select_deadweight       := cv_select_leaf_weight;    -- SELECT句 [動的項目]積載重量→リーフ積載重量
     lv_select_loading_capacity := cv_select_leaf_capacity;  -- SELECT句 [動的項目]積載重量→リーフ積載容積
--
   -- 商品区分が「2：ドリンク」の場合
   ELSIF( lv_prod_class = cv_prod_class_drink) THEN 
     lv_select_deadweight       := cv_select_drink_weight;    -- SELECT句 [動的項目]積載重量→ドリンク積載重量
     lv_select_loading_capacity := cv_select_drink_capacity;  -- SELECT句 [動的項目]積載重量→ドリンク積載容積
   END IF;
--
   -- WHERE句 [動的項目]積載重量OR積載容積＞0,WHERE句 [動的項目]混載区分=0の決定
   -- 出荷方法に指定がある場合
   IF (lv_ship_method IS NOT NULL) THEN
     lv_where_remove_zero    := ' '; -- WHERE句 [動的項目]積載重量OR積載容積＞0→指定なし
     lv_where_mixed_class    := ' '; -- WHERE句 [動的項目]混載区分=0→指定なし
--
   -- 出荷方法に指定がない場合
   ELSE
     lv_where_mixed_class    := cv_where_mixed_class; -- WHERE句 [動的項目]混載区分=0→指定あり
--
     -- 商品区分「1：リーフ」かつ、重量に指定あり
     IF ((lv_prod_class = cv_prod_class_leaf)
     AND (ln_sum_weight IS NOT NULL)) THEN
       lv_where_remove_zero    := cv_where_leaf_weight;  -- WHERE句 [動的項目]積載重量OR積載容積＞0→リーフ積載重量
--
     -- 商品区分「1：リーフ」かつ、重量に指定なし
     ELSIF ((lv_prod_class = cv_prod_class_leaf)
     AND    (ln_sum_weight IS NULL)) THEN
       lv_where_remove_zero    := cv_where_leaf_capacity;  -- WHERE句 [動的項目]積載重量OR積載容積＞0→リーフ積載容積
--
     -- 商品区分「2：ドリンク」かつ、重量に指定あり
     ELSIF ((lv_prod_class = cv_prod_class_drink)
     AND    (ln_sum_weight IS NOT NULL)) THEN
       lv_where_remove_zero    := cv_where_drink_weight;  -- WHERE句 [動的項目]積載重量OR積載容積＞0→ドリンク積載重量
--
     -- 商品区分「2：ドリンク」かつ、重量に指定なし
     ELSIF ((lv_prod_class = cv_prod_class_drink)
     AND    (ln_sum_weight IS NULL)) THEN
       lv_where_remove_zero    := cv_where_drink_capacity;  -- WHERE句 [動的項目]積載重量OR積載容積＞0→ドリンク積載容積
     END IF;
   END IF;
--
   lv_sql := -- 優先① 入出庫場所（個別－個別）
             cv_select                   -- SELECT句   [不変項目]
          || lv_select_deadweight        -- SELECT句   [動的項目]積載重量
          || lv_select_loading_capacity  -- SELECT句   [動的項目]積載容積
          || cv_select_sql_sort1         -- SELECT句   [不変項目]ソート順=1
          || cv_from                     -- FROM句     [不変項目]
          || cv_where                    -- WHERE句    [不変項目]
          || lv_where_remove_zero        -- WHERE句    [動的項目]積載重量OR積載容積＞0
          || lv_where_mixed_class        -- WHERE句    [動的項目]混載区分=0
             -- 優先② 入出庫場所（ZZZZ－個別）
          || cv_union_all
          || cv_select                   -- SELECT句   [不変項目]
          || lv_select_deadweight        -- SELECT句   [動的項目]積載重量
          || lv_select_loading_capacity  -- SELECT句   [動的項目]積載容積
          || cv_select_sql_sort2         -- SELECT句   [不変項目]ソート順=2
          || cv_from                     -- FROM句     [不変項目]
          || cv_where                    -- WHERE句    [不変項目]
          || lv_where_remove_zero        -- WHERE句    [動的項目]積載重量OR積載容積＞0
          || lv_where_mixed_class        -- WHERE句    [動的項目]混載区分=0
             -- 優先③ 入出庫場所（個別－ZZZZ）
          || cv_union_all
          || cv_select                   -- SELECT句   [不変項目]
          || lv_select_deadweight        -- SELECT句   [動的項目]積載重量
          || lv_select_loading_capacity  -- SELECT句   [動的項目]積載容積
          || cv_select_sql_sort3         -- SELECT句   [不変項目]ソート順=3
          || cv_from                     -- FROM句     [不変項目]
          || cv_where                    -- WHERE句    [不変項目]
          || lv_where_remove_zero        -- WHERE句    [動的項目]積載重量OR積載容積＞0
          || lv_where_mixed_class        -- WHERE句    [動的項目]混載区分=0
             -- 優先④ 入出庫場所（ZZZZ－ZZZZ）
          || cv_union_all
          || cv_select                   -- SELECT句   [不変項目]
          || lv_select_deadweight        -- SELECT句   [動的項目]積載重量
          || lv_select_loading_capacity  -- SELECT句   [動的項目]積載容積
          || cv_select_sql_sort4         -- SELECT句   [不変項目]ソート順=4
          || cv_from                     -- FROM句     [不変項目]
          || cv_where                    -- WHERE句    [不変項目]
          || lv_where_remove_zero        -- WHERE句    [動的項目]積載重量OR積載容積＞0
          || lv_where_mixed_class        -- WHERE句    [動的項目]混載区分=0
          || cv_order_by                 -- ORDER BY句 [不変項目]
          ;
-- 2008/09/05 H.Itou Add End
-- 2008/09/05 H.Itou Del Start PT 6-2_34 指摘#34対応 動的SQLに変更
---- 2008/08/04 H.Itou Add Start
----    -- カーソルオープン
----    OPEN lc_ref;
---- 2008/08/04 H.Itou Add End
-- 2008/09/05 H.Itou Del End
-- 2008/09/05 H.Itou Add Start PT 6-2_34 指摘#34対応 動的SQLに変更
    OPEN  lc_ref FOR lv_sql
    USING -- 優先① 入出庫場所（個別－個別）
          lv_code_class1                 -- WHERE句 コード区分１        = INパラメータ.コード区分１
         ,lv_code_class2                 -- WHERE句 コード区分２        = INパラメータ.コード区分２
         ,ld_standard_date               -- WHERE句 配送LT適用開始日   <= INパラメータ.基準日
         ,ld_standard_date               -- WHERE句 配送LT適用終了日   >= INパラメータ.基準日
         ,ld_standard_date               -- WHERE句 出荷方法適用開始日 <= INパラメータ.基準日
         ,ld_standard_date               -- WHERE句 出荷方法適用終了日 >= INパラメータ.基準日
         ,ld_standard_date               -- WHERE句 有効開始日         <= INパラメータ.基準日
         ,ld_standard_date               -- WHERE句 有効終了日         >= INパラメータ.基準日
         ,lv_ship_method                 -- WHERE句 出荷方法            = INパラメータ.出荷方法
         ,lv_auto_process_type           -- WHERE句 自動配車対象区分    = INパラメータ.自動配車区分
         ,lv_entering_despatching_code1  -- WHERE句 入出庫場所１        = INパラメータ.入出庫場所１
         ,lv_entering_despatching_code2  -- WHERE句 入出庫場所２        = INパラメータ.入出庫場所２
          -- 優先② 入出庫場所（ZZZZ－個別）
         ,lv_code_class1                 -- WHERE句 コード区分１        = INパラメータ.コード区分１
         ,lv_code_class2                 -- WHERE句 コード区分２        = INパラメータ.コード区分２
         ,ld_standard_date               -- WHERE句 配送LT適用開始日   <= INパラメータ.基準日
         ,ld_standard_date               -- WHERE句 配送LT適用終了日   >= INパラメータ.基準日
         ,ld_standard_date               -- WHERE句 出荷方法適用開始日 <= INパラメータ.基準日
         ,ld_standard_date               -- WHERE句 出荷方法適用終了日 >= INパラメータ.基準日
         ,ld_standard_date               -- WHERE句 有効開始日         <= INパラメータ.基準日
         ,ld_standard_date               -- WHERE句 有効終了日         >= INパラメータ.基準日
         ,lv_ship_method                 -- WHERE句 出荷方法            = INパラメータ.出荷方法
         ,lv_auto_process_type           -- WHERE句 自動配車対象区分    = INパラメータ.自動配車区分
         ,cv_all_4                       -- WHERE句 入出庫場所１        = ダミー倉庫：ZZZZ
         ,lv_entering_despatching_code2  -- WHERE句 入出庫場所２        = INパラメータ.入出庫場所２
          -- 優先③ 入出庫場所（個別－ZZZZ）
         ,lv_code_class1                 -- WHERE句 コード区分１        = INパラメータ.コード区分１
         ,lv_code_class2                 -- WHERE句 コード区分２        = INパラメータ.コード区分２
         ,ld_standard_date               -- WHERE句 配送LT適用開始日   <= INパラメータ.基準日
         ,ld_standard_date               -- WHERE句 配送LT適用終了日   >= INパラメータ.基準日
         ,ld_standard_date               -- WHERE句 出荷方法適用開始日 <= INパラメータ.基準日
         ,ld_standard_date               -- WHERE句 出荷方法適用終了日 >= INパラメータ.基準日
         ,ld_standard_date               -- WHERE句 有効開始日         <= INパラメータ.基準日
         ,ld_standard_date               -- WHERE句 有効終了日         >= INパラメータ.基準日
         ,lv_ship_method                 -- WHERE句 出荷方法            = INパラメータ.出荷方法
         ,lv_auto_process_type           -- WHERE句 自動配車対象区分    = INパラメータ.自動配車区分
         ,lv_entering_despatching_code1  -- WHERE句 入出庫場所１        = INパラメータ.入出庫場所１
         ,lv_all_z_dummy_code2           -- WHERE句 入出庫場所２        = ダミー倉庫：ZZZZ OR ZZZZZZZZZ
          -- 優先④ 入出庫場所（ZZZZ－ZZZZ）
         ,lv_code_class1                 -- WHERE句 コード区分１        = INパラメータ.コード区分１
         ,lv_code_class2                 -- WHERE句 コード区分２        = INパラメータ.コード区分２
         ,ld_standard_date               -- WHERE句 配送LT適用開始日   <= INパラメータ.基準日
         ,ld_standard_date               -- WHERE句 配送LT適用終了日   >= INパラメータ.基準日
         ,ld_standard_date               -- WHERE句 出荷方法適用開始日 <= INパラメータ.基準日
         ,ld_standard_date               -- WHERE句 出荷方法適用終了日 >= INパラメータ.基準日
         ,ld_standard_date               -- WHERE句 有効開始日         <= INパラメータ.基準日
         ,ld_standard_date               -- WHERE句 有効終了日         >= INパラメータ.基準日
         ,lv_ship_method                 -- WHERE句 出荷方法            = INパラメータ.出荷方法
         ,lv_auto_process_type           -- WHERE句 自動配車対象区分    = INパラメータ.自動配車区分
         ,cv_all_4                       -- WHERE句 入出庫場所１        = ダミー倉庫：ZZZZ
         ,lv_all_z_dummy_code2           -- WHERE句 入出庫場所２        = ダミー倉庫：ZZZZ OR ZZZZZZZZZ
    ;
-- 2008/09/05 H.Itou Mod End
--
    /**********************************
     *  最適出荷方法の算出(C-3)       *
     **********************************/
    -- FETCH
    FETCH lc_ref INTO lr_ref;
--
    -- 検索できたか
    IF ( lc_ref%FOUND ) THEN
--
      -- 出荷方法がセットされていない場合は、ループする。
      IF ( iv_ship_method IS NULL ) THEN
        -- 検索できた場合
        << delv_lt_loop >>
        LOOP
-- 2008/08/04 H.Itou Add Start 同一出荷方法中、入出庫場所優先順が最優先のレコードで比較する。
          -- 出荷方法がブレイクした場合、積載効率を取得。
          IF  ((ln_ship_method_tmp <> lr_ref.ship_method)
            OR (ln_ship_method_tmp IS NULL)) THEN
-- 2008/08/04 H.Itou Add End
-- 2008/08/04 H.Itou Mod Start
            -- 積載効率算出
            IF ( in_sum_weight IS NOT NULL ) THEN
              ln_load_efficiency_tmp
-- 2008/08/06 H.Itou Mod Start 合計重量・合計容積･･･小数点第一位を切り上げて計算する。
--                 := ( in_sum_weight   / lr_ref.deadweight       ) * 100;
                 := ( ln_sum_weight   / lr_ref.deadweight       ) * 100;
-- 2008/08/06 H.Itou Mod End
            ELSE
              ln_load_efficiency_tmp
-- 2008/08/06 H.Itou Mod Start 合計重量・合計容積･･･小数点第一位を切り上げて計算する。
--                 := ( in_sum_capacity / lr_ref.loading_capacity ) * 100;
                 := ( ln_sum_capacity / lr_ref.loading_capacity ) * 100;
-- 2008/08/06 H.Itou Mod End
            END IF;
--
-- 2008/08/06 H.Itou Add Start 小数第三位を切り上げ
            ln_load_efficiency_tmp := comp_round_up(ln_load_efficiency_tmp, 2);
-- 2008/08/06 H.Itou Add End
            -- その他情報
            ln_ship_method_tmp          := lr_ref.ship_method;             -- 出荷方法
            ln_mixed_ship_method_cd_tmp := lr_ref.mixed_ship_method_code;  -- 混載配送区分
            -- 100%を超えた場合、ループ終了
            EXIT WHEN ( ln_load_efficiency_tmp > 100 );
-- 2008/08/04 H.Itou Mod End
-- 2008/08/04 H.Itou Add Start
          END IF;
-- 2008/08/04 H.Itou Add End
          -- 次レコード検索
          FETCH lc_ref INTO lr_ref;
          --
          -- データがなくなった場合、ループ終了
          EXIT WHEN ( lc_ref%NOTFOUND );
          --
          -- データ退避
          ln_load_efficiency         := ln_load_efficiency_tmp;
          --
          ln_ship_method             := ln_ship_method_tmp;           -- 出荷方法
          ln_mixed_ship_method_code  := ln_mixed_ship_method_cd_tmp;  -- 混載配送区分
          --
        END LOOP delv_lt_loop;
--
        -- 100%を超えてループ終了した場合は、その値をセットしない
        IF ( ln_load_efficiency_tmp <= 100 ) THEN
          ln_load_efficiency         := ln_load_efficiency_tmp;
          --
          ln_ship_method             := ln_ship_method_tmp;           -- 出荷方法
          ln_mixed_ship_method_code  := ln_mixed_ship_method_cd_tmp;  -- 混載配送区分
        END IF;
--
      -- 出荷方法がセットされてる場合は、1件目のデータが対象データなのでループしない。
      ELSE
        --
        -- 積載効率算出
        IF ( in_sum_weight IS NOT NULL ) THEN
          IF ( NVL(lr_ref.deadweight, 0) = 0 ) THEN
            ln_load_efficiency := 0;
          ELSE
            ln_load_efficiency
-- 2008/08/06 H.Itou Mod Start 合計重量・合計容積･･･小数点第一位を切り上げて計算する。
--               := ( in_sum_weight   / lr_ref.deadweight       ) * 100;
               := ( ln_sum_weight   / lr_ref.deadweight       ) * 100;
-- 2008/08/06 H.Itou Mod End
          END IF;
--
        ELSE
--
          IF ( NVL(lr_ref.loading_capacity, 0) = 0 ) THEN
            ln_load_efficiency := 0;
          ELSE
            ln_load_efficiency
-- 2008/08/06 H.Itou Mod Start 合計重量・合計容積･･･小数点第一位を切り上げて計算する。
--               := ( in_sum_capacity / lr_ref.loading_capacity ) * 100;
               := ( ln_sum_capacity / lr_ref.loading_capacity ) * 100;
-- 2008/08/06 H.Itou Mod End
          END IF;
--
        END IF;
        --
-- 2008/08/06 H.Itou Add Start 小数第三位を切り上げ
        ln_load_efficiency := comp_round_up(ln_load_efficiency, 2);
-- 2008/08/06 H.Itou Add End
        -- その他情報
        ln_ship_method             := lr_ref.ship_method;             -- 出荷方法
        ln_mixed_ship_method_code  := lr_ref.mixed_ship_method_code;  -- 混載配送区分
        --
      END IF;
    --
    ELSE
-- 2008/08/04 H.Itou Add Start
      -- 対象データなし
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_wt_cap_set_err);
-- Ver1.26 M.Hokkanji Start
      FND_LOG.STRING(cv_log_level, gv_pkg_name
                    || cv_colon
                    || cv_prg_name,
                       '合計重量：' || TO_CHAR(in_sum_weight)
                    || '、合計容積：' || TO_CHAR(in_sum_capacity)
                    || '、コード区分1：' || iv_code_class1
                    || '、入出庫場所コード１：' || iv_entering_despatching_code1
                    || '、コード区分２：' || iv_code_class2
                    || '、入出庫場所コード２：' || iv_entering_despatching_code2
                    || '、出荷方法：' || iv_ship_method
                    || '、商品区分：' || iv_prod_class
                    || '、自動配車対象区分：' || iv_auto_process_type
                    || '、依頼No：' || TO_CHAR(id_standard_date,'YYYY/MM/DD'));
-- Ver1.26 M.Hokkanji End
      lv_err_cd := cv_xxwsh_wt_cap_set_err;
      -- カーソルクローズ
      CLOSE lc_ref;
      --
      RAISE global_api_expt;
-- 2008/08/04 H.Itou Add End
-- 2008/08/04 H.Itou Del Start
--      -- 検索できなかった場合
--      -- コード区分2が「配送先」かチェック
--      IF ( iv_code_class2 = cv_cust_class_deliver ) THEN  -- コード区分2=「9:配送」の場合は以下2.3.4.で再検索する
--        --
--        -- 2008/07/14 変更要求対応#95 Add Start ----------------------------------------------
--        -- 1.で見つからなかったので、2. 倉庫(ALL値)－配送先(個別コード)で再検索
--        OPEN lc_fnd_chk2 FOR lv_sql
--          USING
--            iv_code_class1,                      -- コード区分From
--            cv_all_4,                            -- 入出庫場所From  (=ALL'Z'で検索)
--            iv_code_class2,                      -- コード区分To
--            iv_entering_despatching_code2,       -- 入出庫場所To
--            id_standard_date,
--            id_standard_date,
--            id_standard_date,
--            id_standard_date,
--            id_standard_date,
--            id_standard_date,
--            iv_ship_method,                      -- 出荷方法
--            lv_auto_process_type;                -- 自動配車対象区分
--        --
--        FETCH lc_fnd_chk2 INTO lr_fnd_chk2;
--        --
--        IF ( lc_fnd_chk2%NOTFOUND ) THEN         -- 2.で該当データなしの場合
--          CLOSE lc_fnd_chk2;                     -- カーソルクローズ
--          --
--          -- 2.で見つからなかったので、3. 倉庫(個別コード)－配送先(ALL値)で再検索
--          OPEN lc_fnd_chk3 FOR lv_sql
--            USING
--              iv_code_class1,                      -- コード区分From
--              iv_entering_despatching_code1,       -- 入出庫場所From
--              iv_code_class2,                      -- コード区分To
--              cv_all_9,                            -- 入出庫場所To  (=ALL'Z'で検索)
--              id_standard_date,
--              id_standard_date,
--              id_standard_date,
--              id_standard_date,
--              id_standard_date,
--              id_standard_date,
--              iv_ship_method,                      -- 出荷方法
--              lv_auto_process_type;                -- 自動配車対象区分
--          --
--          FETCH lc_fnd_chk3 INTO lr_fnd_chk3;
--          --
--          IF ( lc_fnd_chk3%NOTFOUND ) THEN         -- 3.で該当データなしの場合
--            CLOSE lc_fnd_chk3;                     -- カーソルクローズ
--            --
--            -- 3.で見つからなかったので、4. 倉庫(ALL値)－配送先(ALL値)で再検索
--            OPEN lc_fnd_chk4 FOR lv_sql
--              USING
--                iv_code_class1,                      -- コード区分From
--                cv_all_4,                            -- 入出庫場所From (=ALL'Z'で検索)
--                iv_code_class2,                      -- コード区分To
--                cv_all_9,                            -- 入出庫場所To   (=ALL'Z'で検索)
--                id_standard_date,
--                id_standard_date,
--                id_standard_date,
--                id_standard_date,
--                id_standard_date,
--                id_standard_date,
--                iv_ship_method,                      -- 出荷方法
--                lv_auto_process_type;                -- 自動配車対象区分
--            --
--            FETCH lc_fnd_chk4 INTO lr_fnd_chk4;
--            --
--            IF ( lc_fnd_chk4%NOTFOUND ) THEN         -- 4.で該当データなしの場合
--              CLOSE lc_fnd_chk4;                     -- カーソルクローズ
--              --1.から4.すべて該当データなので、対象データなしで処理する
--              lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,cv_xxwsh_wt_cap_set_err);
--              lv_err_cd := cv_xxwsh_wt_cap_set_err;
--              RAISE global_api_expt;
--            --
--            ELSE  -- 4.で該当データありの場合
--              CLOSE lc_fnd_chk4;                     -- カーソルクローズ
--              lv_entering_despatching_code1 := cv_all_4;  -- (=ALL'Z'で検索)
--              lv_entering_despatching_code2 := cv_all_9;  -- (=ALL'Z'で検索)
--            END IF;
--          --
--          ELSE  -- 3.で該当データありの場合
--              CLOSE lc_fnd_chk3;                     -- カーソルクローズ
--              lv_entering_despatching_code1 := iv_entering_despatching_code1;  -- 個別コードで検索
--              lv_entering_despatching_code2 := cv_all_9;                       -- (=ALL'Z'で検索)
--          END IF;
--        --
--        ELSE  -- 2.で該当データありの場合
--            CLOSE lc_fnd_chk2;                     -- カーソルクローズ
--            lv_entering_despatching_code1 := cv_all_4;                       -- (=ALL'Z'で検索)
--            lv_entering_despatching_code2 := iv_entering_despatching_code2;  -- 個別コードで検索
--        END IF;
--        -- 2008/07/14 変更要求対応#95 Add End ----------------------------------------------
--        --
--        -- 2008/07/14 変更要求対応#95 Del Start --------------------------------------------
--        ---- コード区分2を「拠点」で検索する
--        --BEGIN
--        --  SELECT  xcasv.base_code                                            -- 拠点コード
--        --  INTO    lv_base_code
--        --  FROM    xxcmn_cust_acct_sites2_v  xcasv                            -- 顧客サイト情報View2
--        --  WHERE   xcasv.ship_to_no         =  iv_entering_despatching_code2  -- 配送先番号
--        --    AND   xcasv.start_date_active <=  trunc(id_standard_date)        -- 適用日
--        --    AND   xcasv.end_date_active   >=  trunc(id_standard_date);
--        --EXCEPTION
--        --  WHEN  NO_DATA_FOUND  THEN
--        --    lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
--        --                                          cv_xxwsh_wt_cap_set_err);
--        --    lv_err_cd := cv_xxwsh_in_param_set_err;
--        --    -- カーソルクローズ
--        --    CLOSE lc_ref;
--        --    --
--        --    RAISE global_api_expt;
--        --  --
--        --  WHEN  OTHERS THEN
--        --    -- カーソルクローズ
--        --    CLOSE lc_ref;
--        --    --
--        --    RAISE global_api_others_expt;
--        --END;
--        -- 2008/07/14 変更要求対応#95 Del End -------------------------------------------
--        --
--        -- SQLの実行
--        OPEN lc_ref2 FOR lv_sql
--          USING
--            iv_code_class1,                      -- コード区分From
--            --iv_entering_despatching_code1,       -- 入出庫場所From   -- 2008/07/14 変更要求対応#95
--            lv_entering_despatching_code1,       -- 入出庫場所From     -- 2008/07/14 変更要求対応#95
--            --cv_cust_class_base,                  -- コード区分To(拠点)  -- 2008/07/17 変更要求対応#95のバグ対応
--            cv_cust_class_deliver,               -- コード区分To(配送先)  -- 2008/07/17 変更要求対応#95のバグ対応
--            --lv_base_code,                        -- 入出庫場所To(管轄拠点)  -- 2008/07/14 変更要求対応#95
--            lv_entering_despatching_code2,       -- 入出庫場所From            -- 2008/07/14 変更要求対応#95
--            id_standard_date,
--            id_standard_date,
--            id_standard_date,
--            id_standard_date,
--            id_standard_date,
--            id_standard_date,
--            iv_ship_method,                      -- 出荷方法
--            lv_auto_process_type;                -- 自動配車対象区分
----
--        -- FETCH
--        FETCH lc_ref2 INTO lr_ref2;
--        --
--        -- 検索できたか
--        IF ( lc_ref2%FOUND ) THEN
--        --
--          -- 出荷方法がセットされていない場合は、さらに検索する。
--          IF ( iv_ship_method IS NULL ) THEN
--            --
--            -- 検索できた場合
--            << delv_lt_loop2 >>
--            LOOP
--              -- 積載効率算出
--              IF ( in_sum_weight IS NOT NULL ) THEN
--                ln_load_efficiency_tmp
--                   := ( in_sum_weight   / lr_ref2.deadweight       ) * 100;
--              ELSE
--                ln_load_efficiency_tmp
--                   := ( in_sum_capacity / lr_ref2.loading_capacity ) * 100;
--              END IF;
--              --
--              -- その他情報
--              ln_ship_method_tmp           := lr_ref2.ship_method;             -- 出荷方法
--              ln_mixed_ship_method_cd_tmp  := lr_ref2.mixed_ship_method_code;  -- 混載配送区分
--              --
--              -- 100%を超えた場合、ループ終了
--              EXIT WHEN ( ln_load_efficiency_tmp > 100 );
--              --
--              -- 次レコード検索
--              FETCH lc_ref2 INTO lr_ref2;
--              --
--              -- データがなくなった場合、ループ終了
--              EXIT WHEN ( lc_ref2%NOTFOUND );
--              --
--              -- データ退避
--              ln_load_efficiency         := ln_load_efficiency_tmp;
--              --
--              ln_ship_method             := ln_ship_method_tmp;           -- 出荷方法
--              ln_mixed_ship_method_code  := ln_mixed_ship_method_cd_tmp;  -- 混載配送区分
--              --
--            END LOOP delv_lt_loop2;
--            --
--            -- 100%を超えてループ終了した場合は、その値をセットしない
--            IF ( ln_load_efficiency_tmp <= 100 ) THEN
--              ln_load_efficiency         := ln_load_efficiency_tmp;
--              --
--              ln_ship_method             := ln_ship_method_tmp;           -- 出荷方法
--              ln_mixed_ship_method_code  := ln_mixed_ship_method_cd_tmp;  -- 混載配送区分
--            END IF;
--          ELSE
--            --
--            -- 積載効率算出
--            --IF ( in_sum_weight IS NOT NULL ) THEN
--            --  ln_load_efficiency
--            --     := ( in_sum_weight   / lr_ref2.deadweight       ) * 100;
--            --ELSE
--            --  ln_load_efficiency
--            --     := ( in_sum_capacity / lr_ref2.loading_capacity ) * 100;
--            --END IF;
--            IF ( in_sum_weight IS NOT NULL ) THEN
----
--              IF ( NVL(lr_ref2.deadweight, 0) = 0 ) THEN
--                ln_load_efficiency := 0;
--              ELSE
--                ln_load_efficiency
--                   := ( in_sum_weight   / lr_ref2.deadweight       ) * 100;
--              END IF;
----
--            ELSE
----
--              IF ( NVL(lr_ref2.loading_capacity, 0) = 0 ) THEN
--                ln_load_efficiency := 0;
--              ELSE
--                ln_load_efficiency
--                   := ( in_sum_capacity / lr_ref2.loading_capacity ) * 100;
--              END IF;
----
--            END IF;
--            --
--            -- その他情報
--            ln_ship_method             := lr_ref2.ship_method;             -- 出荷方法
--            ln_mixed_ship_method_code  := lr_ref2.mixed_ship_method_code;  -- 混載配送区分
--            --
--          END IF;
--        ELSE
--          -- 対象データなし
--          lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
--                                                cv_xxwsh_wt_cap_set_err);
--          lv_err_cd := cv_xxwsh_wt_cap_set_err;
--          -- カーソルクローズ
--          CLOSE lc_ref;
--          --
--          RAISE global_api_expt;
--          --
--        END IF;
--        -- カーソルクローズ
--        CLOSE lc_ref2;
--      ELSE
--        -- 対象データなし
--        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
--                                              cv_xxwsh_wt_cap_set_err);
--        lv_err_cd := cv_xxwsh_wt_cap_set_err;
--        -- カーソルクローズ
--        CLOSE lc_ref;
--        --
--        RAISE global_api_expt;
--        --
--      END IF;
-- 2008/08/04 H.Itou Del End
    END IF;
    -- カーソルクローズ
    CLOSE lc_ref;
--
--
    /**********************************
     *  OUTパラメータセット(C-4)      *
     **********************************/
    -- ステータス
    ov_retcode                  := gv_status_normal;        -- リターンコード
    ov_errmsg_code              := NULL;                    -- エラーメッセージコード
    ov_errmsg                   := NULL;                    -- エラーメッセージ
    --
    -- 積載オーバー区分
    IF ( ln_load_efficiency <= 100 ) THEN
      ov_loading_over_class        := cv_not_loading_over;  -- 正常
    ELSE
      ov_loading_over_class        := cv_loading_over;      -- 積載オーバー
    END IF;
    --
    -- 出荷方法
    IF ( iv_ship_method IS NOT NULL ) THEN
      ov_ship_methods              := iv_ship_method;       -- 入力パラメータ
    ELSE
      ov_ship_methods              := ln_ship_method;       -- 出荷方法
    END IF;
    --
    -- 積載効率
    IF ( in_sum_weight IS NOT NULL ) THEN
      on_load_efficiency_weight    :=  ln_load_efficiency;
      on_load_efficiency_capacity  :=  NULL;
    ELSE
      on_load_efficiency_weight    :=  NULL;
      on_load_efficiency_capacity  :=  ln_load_efficiency;
    END IF;
    --
    -- 混載配送区分
-- 2008/10/15 H.Itou Add Start 統合テスト指摘298
    -- INパラメータ.出荷方法に指定ありかつ、混載配送区分の場合
    IF ((iv_ship_method IS NOT NULL)
    AND (iv_ship_method <> lv_ship_method)) THEN
      ov_mixed_ship_method           :=  NULL;
--
    -- 上記以外の場合
    ELSE
-- 2008/10/15 H.Itou Add End
      ov_mixed_ship_method           :=  ln_mixed_ship_method_code;
-- 2008/10/15 H.Itou Add Start 統合テスト指摘298
    END IF;
-- 2008/10/15 H.Itou Add End
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg      := lv_errmsg;
      ov_errmsg_code := lv_err_cd;
      ov_retcode     := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg      := SQLERRM;
      ov_errmsg_code := SQLCODE;
      ov_retcode     := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg      := SQLERRM;
      ov_errmsg_code := SQLCODE;
      ov_retcode     := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END calc_load_efficiency;
--
  /**********************************************************************************
   * Procedure Name   : check_lot_reversal
   * Description      : ロット逆転防止チェック
   ***********************************************************************************/
  PROCEDURE check_lot_reversal(
    iv_lot_biz_class              IN  VARCHAR2,                            -- 1.ロット逆転処理種別
    iv_item_no                    IN  xxcmn_item_mst_v.item_no%TYPE,       -- 2.品目コード
    iv_lot_no                     IN  ic_lots_mst.lot_no%TYPE,             -- 3.ロットNo
    iv_move_to_id                 IN  NUMBER,                              -- 4.配送先ID/入庫先ID
    iv_arrival_date               IN  DATE,                                -- 5.着日
    id_standard_date              IN  DATE  DEFAULT SYSDATE,               -- 6.基準日(適用日基準日)
    ov_retcode                    OUT NOCOPY VARCHAR2,                     -- 7.リターンコード
    ov_errmsg_code                OUT NOCOPY VARCHAR2,                     -- 8.エラーメッセージコード
    ov_errmsg                     OUT NOCOPY VARCHAR2,                     -- 9.エラーメッセージ
    on_result                     OUT NOCOPY NUMBER,                       -- 10.処理結果
    on_reversal_date              OUT NOCOPY DATE                          -- 11.逆転日付
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_lot_reversal'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- メッセージID
    cv_xxwsh_in_pram_set_err       CONSTANT VARCHAR2(100) := 'APP-XXWSH-12651'; -- 必須入力パラメータ未設定エラーメッセージ
    cv_xxwsh_in_pram_lot_err       CONSTANT VARCHAR2(100) := 'APP-XXWSH-12652'; -- 入力パラメータ「ロット逆転処理種別」セット内容エラー
    cv_xxwsh_in_pram_arr_err       CONSTANT VARCHAR2(100) := 'APP-XXWSH-12653'; -- 入力パラメータ未設定エラーメッセージ
    cv_xxwsh_in_no_lot_err         CONSTANT VARCHAR2(100) := 'APP-XXWSH-12654'; -- 対象ロットデータなしエラーメッセージ
    -- トークン
    cv_tkn_in_parm                 CONSTANT VARCHAR2(30)  := 'in_param';
    cv_tkn_lot_no                  CONSTANT VARCHAR2(30)  := 'lot_no';
    -- トークンセット値
    cv_ship_move_class_char        CONSTANT VARCHAR2(30)  := 'ロット逆転処理種別';
    cv_item_code_char              CONSTANT VARCHAR2(30)  := '品目コード';
    cv_lot_no_char                 CONSTANT VARCHAR2(30)  := 'ロットNo';
    cv_move_to_char                CONSTANT VARCHAR2(30)  := '配送先ID/入庫先ID';
    --
    -- ロット逆転処理種別
    cv_ship_plan                   CONSTANT VARCHAR2(1)   := '1';         -- 出荷指示
    cv_ship_result                 CONSTANT VARCHAR2(1)   := '2';         -- 出荷実績
    cv_move_plan                   CONSTANT VARCHAR2(1)   := '5';         -- 移動指示
    cv_move_result                 CONSTANT VARCHAR2(1)   := '6';         -- 移動実績
    --
    -- 出荷依頼ステータス
    cv_request_status_03           CONSTANT VARCHAR2(2)   := '03';        -- 締め済み
    cv_request_status_04           CONSTANT VARCHAR2(2)   := '04';        -- 出荷実績計上済
    -- 移動ステータス
    cv_move_status_03              CONSTANT VARCHAR2(2)   := '03';        -- 調整中
    cv_move_status_04              CONSTANT VARCHAR2(2)   := '04';        -- 出庫報告有
    cv_move_status_05              CONSTANT VARCHAR2(2)   := '05';        -- 入庫報告有
    cv_move_status_06              CONSTANT VARCHAR2(2)   := '06';        -- 入出庫報告有
    --
    -- 出荷支給区分
    cv_shipping_shikyu_class_01    CONSTANT VARCHAR2(1)   := '1';         -- 出荷依頼
    -- 文書タイプ
    cv_document_type_10            CONSTANT VARCHAR2(2)   := '10';        -- 出荷依頼
    cv_document_type_20            CONSTANT VARCHAR2(2)   := '20';        -- 移動
    -- レコードタイプ
    cv_record_type_01              CONSTANT VARCHAR2(2)   := '10';         -- 指示
    cv_record_type_02              CONSTANT VARCHAR2(2)   := '20';         -- 出庫実績
    cv_record_type_03              CONSTANT VARCHAR2(2)   := '30';         -- 入庫実績
    --
    cv_zero                        CONSTANT VARCHAR2(1)   := '0';         -- ゼロ値(VARCHAR2)
    cv_yes                         CONSTANT VARCHAR2(1)   := 'Y';         -- Y (YES_NO区分)
    cv_no                          CONSTANT VARCHAR2(1)   := 'N';         -- N (YES_NO区分)
    --
    ln_result_success              CONSTANT NUMBER        := 0;           -- 0 (正常)
    ln_result_error                CONSTANT NUMBER        := 1;           -- 1 (異常)
    --
    cv_mindate                     CONSTANT DATE
                                        := fnd_date.string_to_date('1900/01/01', gv_yyyymmdd);
                                                                          -- 最小日付
--
--
    -- *** ローカル変数 ***
    -- エラー変数
    lv_err_cd             VARCHAR2(30);
    --
-- 2016/02/18 D.Sugahara Mod Start 1.38
--    ld_max_manufact_date           ic_lots_mst.attribute1%TYPE;           -- 最大製造年月日
    ld_max_best_before_date        ic_lots_mst.attribute3%TYPE;           -- 最大賞味期限
-- 2016/02/18 D.Sugahara Mod End 1.38
-- 2009/10/15 H.Itou Mod Start 本番障害#1661
--    lv_parent_item_no              xxcmn_item_mst2_v.item_no%TYPE;        -- 親品目コード
    lv_parent_item_id              xxcmn_item_mst2_v.parent_item_id%TYPE; -- 親品目ID
-- 2009/10/15 H.Itou Mod End
    --
-- 2016/02/18 D.Sugahara Mod Start 1.38
--    ld_max_ship_manufact_date      DATE;                                  -- 出荷指示製造年月日
    ld_max_ship_best_before_date   DATE;                                  -- 出荷指示賞味期限
-- 2016/02/18 D.Sugahara Mod End 1.38
    ld_max_ship_arrival_date       xxwsh_order_headers_all.arrival_date%type;
                                                                          -- 最大着荷日(出荷)
-- 2016/02/18 D.Sugahara Mod Start 1.38
--    ld_max_rship_manufact_date     DATE;                                  -- 出荷実績製造年月日
--    --
--    ld_max_move_manufact_date      DATE;                                  -- 移動指示製造年月日
    ld_max_rship_best_before_date  DATE;                                  -- 出荷実績賞味期限
    --
    ld_max_move_best_before_date   DATE;                                  -- 移動指示賞味期限
-- 2016/02/18 D.Sugahara Mod End 1.38
    ld_max_move_arrival_date       xxinv_mov_req_instr_headers.actual_arrival_date%type;
                                                                          -- 最大着荷日(移動)
-- 2016/02/18 D.Sugahara Mod Start 1.38
--    ld_max_rmove_manufact_date     DATE;                                  -- 移動実績製造年月日
--    --
--    ld_max_onhand_manufact_date    DATE;                                  -- 手持製造年月日
--    --
--    ld_check_manufact_date         DATE;                                  -- チェック日付
    ld_max_rmove_best_before_date  DATE;                                  -- 移動実績賞味期限
    --
    ld_max_onhand_best_before_date DATE;                                  -- 手持賞味期限
    --
    ld_check_best_before_date      DATE;                                  -- チェック日付
-- 2016/02/18 D.Sugahara Mod End 1.38
    --
    ln_result                      NUMBER;                                -- 結果
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    --
    /**********************************
     *  パラメータチェック(D-1)       *
     **********************************/
    -- 必須入力パラメータをチェックします
    -- ロット逆転処理種別
    IF   ( iv_lot_biz_class IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_in_pram_set_err,
                                            cv_tkn_in_parm,
                                            cv_ship_move_class_char);
      lv_err_cd := cv_xxwsh_in_pram_set_err;
      RAISE global_api_expt;
    --
    -- 品目コード
    ELSIF( iv_item_no       IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_in_pram_set_err,
                                            cv_tkn_in_parm,
                                            cv_item_code_char);
      lv_err_cd := cv_xxwsh_in_pram_set_err;
      RAISE global_api_expt;
    --
    -- ロットNo
    ELSIF( iv_lot_no         IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_in_pram_set_err,
                                            cv_tkn_in_parm,
                                            cv_lot_no_char);
      lv_err_cd := cv_xxwsh_in_pram_set_err;
      RAISE global_api_expt;
    --
    -- 配送先ID/入庫先ID
    ELSIF( iv_move_to_id    IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_in_pram_set_err,
                                            cv_tkn_in_parm,
                                            cv_move_to_char);
      lv_err_cd := cv_xxwsh_in_pram_set_err;
      RAISE global_api_expt;
    END IF;
    --
    --
    -- 入力パラメータ「ロット逆転処理種別」の値チェック
    -- 値が1、2、5、6であるかチェック
    IF ( iv_lot_biz_class NOT IN ( cv_ship_plan,
                                   cv_ship_result,
                                   cv_move_plan,
                                   cv_move_result )) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_in_pram_lot_err
                                           );
      lv_err_cd := cv_xxwsh_in_pram_lot_err;
      RAISE global_api_expt;
    ELSE
    -- 値が1、5の場合、「着日」がセットされているかチェック
      IF  ( ( iv_lot_biz_class IN ( cv_ship_plan, cv_move_plan ))
        AND ( iv_arrival_date  IS NULL )) THEN
        --
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                              cv_xxwsh_in_pram_arr_err
                                             );
        lv_err_cd := cv_xxwsh_in_pram_arr_err;
        RAISE global_api_expt;
      END IF;
    END IF;
    --
    /**********************************
     *  賞味期限取得(D-2)           *
     **********************************/
    -- OPMロットマスタから当該ロットの賞味期限を取得
    BEGIN
-- 2016/02/18 D.Sugahara Mod Start 1.38
--      SELECT fnd_date.string_to_date( ilm.attribute1, gv_yyyymmdd )   -- 最大製造年月日
--      INTO   ld_max_manufact_date
      SELECT fnd_date.string_to_date( ilm.attribute3, gv_yyyymmdd )  ilm_attribute3 -- 最大賞味期限
      INTO   ld_max_best_before_date
-- 2016/02/18 D.Sugahara Mod End 1.38
      FROM   ic_lots_mst              ilm,                             -- OPMロットマスタ
             xxcmn_item_mst2_v        ximv                             -- OPM品目情報VIEW2
      WHERE  ximv.item_no             = iv_item_no                     -- 品目コード
        AND  ximv.start_date_active  <= trunc( id_standard_date )
        AND  ximv.end_date_active    >= trunc( id_standard_date )
        AND  ilm.item_id              = ximv.item_id
        AND  ilm.lot_no               = iv_lot_no;                     -- ロットNo
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- 取得エラー
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                              cv_xxwsh_in_no_lot_err,
                                              cv_tkn_lot_no,
                                              iv_lot_no);
        lv_err_cd := cv_xxwsh_in_no_lot_err;
      RAISE global_api_expt;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
    --
    --
    --
    /**********************************
     *  親品目取得(D-3)               *
     **********************************/
    -- OPM品目マスタから親品目コードを取得
    BEGIN
-- 2009/10/15 H.Itou Mod Start 本番障害#1661
--      SELECT ximv2.item_no                                             -- 品目コード(親品目)
--      INTO   lv_parent_item_no
--      FROM   xxcmn_item_mst2_v         ximv1,                          -- OPM品目情報VIEW2(子)
--             xxcmn_item_mst2_v         ximv2                           -- OPM品目情報VIEW2(親)
--      WHERE  ximv1.item_no             =  iv_item_no                   -- 品目コード
--        AND  ximv1.start_date_active  <=  trunc( id_standard_date )
--        AND  ximv1.end_date_active    >=  trunc( id_standard_date )
--        AND  ximv2.item_id             =  ximv1.parent_item_id         -- 親品目ID
--        AND  ximv2.start_date_active  <=  trunc( id_standard_date )
--        AND  ximv2.end_date_active    >=  trunc( id_standard_date );
      SELECT ximv.parent_item_id                                     -- 親品目ID
      INTO   lv_parent_item_id
      FROM   xxcmn_item_mst2_v         ximv                          -- OPM品目情報VIEW2
      WHERE  ximv.item_no             =  iv_item_no                  -- 品目コード
        AND  ximv.start_date_active  <=  trunc( id_standard_date )
        AND  ximv.end_date_active    >=  trunc( id_standard_date )
      ;
-- 2009/10/15 H.Itou Mod End
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      -- データなしは除外
        NULL;
      --
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
    --
    --
    /**********************************
    *  ロット逆転処理種別の判定       *
    **********************************/
    IF ( iv_lot_biz_class IN ( cv_ship_plan , cv_ship_result) ) THEN
    --
      /**********************************
       *  供給情報取得(出荷)(D-4)       *
       **********************************/
       -- 1. 出荷指示情報の取得
      IF ( iv_lot_biz_class = cv_ship_plan ) THEN
        BEGIN
-- 2016/02/18 D.Sugahara Mod Start 1.38
--          SELECT  MAX( fnd_date.string_to_date( ilm.attribute1, gv_yyyymmdd ))
--                                                                            -- 出荷指示製造年月日
--          INTO    ld_max_ship_manufact_date
          SELECT  MAX( fnd_date.string_to_date( ilm.attribute3, gv_yyyymmdd )) max_ilm_attribute3
                                                                            -- 出荷指示賞味期限
          INTO    ld_max_ship_best_before_date
-- 2016/02/18 D.Sugahara Mod End 1.38
          FROM    xxwsh_order_headers_all        xoha,                      -- 受注ヘッダアドオン
                  xxwsh_order_lines_all          xola,                      -- 受注明細アドオン
                  xxinv_mov_lot_details          xmld,                      -- 移動ロット詳細
                  xxwsh_oe_transaction_types2_v  xottv,                     -- 受注タイプ
                  ic_lots_mst                    ilm                        -- OPMロットマスタ
          WHERE   xoha.deliver_to_id             =  iv_move_to_id                -- 出荷先ID
            AND   NVL(xoha.latest_external_flag, cv_no)
                                                 =  cv_yes                       -- 最新フラグ
            AND   xoha.schedule_arrival_date    <=  iv_arrival_date              -- 着日
            AND   xoha.req_status                =  cv_request_status_03         -- 締め済み
            AND   xottv.transaction_type_id      =  xoha.order_type_id           -- 受注タイプID
            AND   xottv.shipping_shikyu_class    =  cv_shipping_shikyu_class_01  -- 出荷依頼
            AND   xottv.start_date_active       <=  trunc( id_standard_date )
            AND   ( (xottv.end_date_active      >=  trunc( id_standard_date ))
                  OR(xottv.end_date_active      IS  NULL ))
            AND   xola.order_header_id           =  xoha.order_header_id         -- 受注ヘッダID
-- 2008/11/04 H.Itou Mod Start T_S_573
--            AND   xola.shipping_item_code       IN  ( iv_item_no, lv_parent_item_no )
            AND   xola.shipping_item_code       IN                               -- 品目コード
                  -- 親品目と親品目に紐付く子品目(2階層まで)
-- 2016/02/18 D.Sugahara Mod Start 1.38
--                 (SELECT ximv.item_no
                 (SELECT ximv.item_no ximv_item_no
-- 2016/02/18 D.Sugahara Mod End 1.38
                  FROM   xxcmn_item_mst2_v ximv
                  WHERE  ximv.start_date_active <= TRUNC(id_standard_date)
                  AND    ximv.end_date_active   >= TRUNC(id_standard_date)
-- 2009/10/15 H.Itou Mod Start 本番障害#1661
--                  AND    LEVEL                  <= 2                 -- 子階層まで抽出
--                  START WITH ximv.item_no        = lv_parent_item_no -- 親品目から検索
--                  CONNECT BY NOCYCLE PRIOR ximv.item_id = ximv.parent_item_id
                  AND    ximv.parent_item_id     = lv_parent_item_id
-- 2009/10/15 H.Itou Mod End
                  )
-- 2008/11/04 H.Itou Mod End
            AND   NVL( xola.delete_flag,  cv_no )
                                                <>  cv_yes                       -- 削除フラグ'Y'以外
            AND   xmld.mov_line_id               =  xola.order_line_id           -- 受注明細ID
            AND   xmld.document_type_code        =  cv_document_type_10          -- 文書タイプ
            AND   xmld.record_type_code          =  cv_record_type_01            -- レコードタイプ
            AND   ilm.lot_id                     =  xmld.lot_id                  -- OPMロットID
            AND   ilm.item_id                    =  xmld.item_id                 -- OPM品目ID
            ;
        EXCEPTION
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
      END IF;
      --
      --
      -- 2-1. 入力パラメータに合致する最大の着荷日を取得
      BEGIN
-- 2008/09/11 v1.18 UPDATE START
/*
        SELECT  MAX( xoha.arrival_date )                                    -- 最大着荷日
        INTO    ld_max_ship_arrival_date
        FROM    xxwsh_order_headers_all        xoha,                        -- 受注ヘッダアドオン
                xxwsh_order_lines_all          xola,                        -- 受注明細アドオン
                xxwsh_oe_transaction_types2_v  xottv                        -- 受注タイプ
        WHERE   NVL ( xoha.result_deliver_to_id, xoha.deliver_to_id )
                                                 =  iv_move_to_id               -- 出荷先ID(実績)
          AND   NVL(xoha.latest_external_flag, cv_no)
                                                 =  cv_yes                      -- 最新フラグ=Y
          AND   xoha.req_status                  =  cv_request_status_04        -- 出荷実績計上済
          AND   xottv.transaction_type_id        =  xoha.order_type_id          -- 受注タイプID
          AND   xottv.shipping_shikyu_class      =  cv_shipping_shikyu_class_01 -- 出荷支給区分
          AND   xottv.start_date_active         <=  trunc( id_standard_date )
          AND   (( xottv.end_date_active        >=  trunc( id_standard_date ))
                OR(xottv.end_date_active        IS  NULL ))
          AND   xola.order_header_id             =  xoha.order_header_id        -- 受注ヘッダID
          AND   xola.shipping_item_code         IN  ( iv_item_no, lv_parent_item_no )  -- 出荷品目
          AND   NVL( xola.delete_flag, cv_no )  <>  cv_yes                      -- 削除フラグ'Y'以外
          AND   xola.shipped_quantity            >  0                           -- 出荷実績数量0以上
          ;
*/
-- 2016/02/18 D.Sugahara Mod Start 1.38
--        SELECT  MAX( arrival_date )                                    -- 最大着荷日
        SELECT  MAX( arrival_date )  max_arrival_date                         -- 最大着荷日
-- 2016/02/18 D.Sugahara Mod End 1.38
        INTO    ld_max_ship_arrival_date
        FROM
          (SELECT /*+ leading(xoha) index(xoha xxwsh_oh_n27) */
-- 2016/02/18 D.Sugahara Mod Start 1.38
--                  xoha.arrival_date
                  xoha.arrival_date  arrival_date
-- 2016/02/18 D.Sugahara Mod End 1.38
          FROM    xxwsh_order_headers_all        xoha,                        -- 受注ヘッダアドオン
                  xxwsh_order_lines_all          xola,                        -- 受注明細アドオン
                  xxwsh_oe_transaction_types2_v  xottv                        -- 受注タイプ
          WHERE   xoha.result_deliver_to_id        =  iv_move_to_id           -- 出荷先ID(実績)
            AND   NVL(xoha.latest_external_flag, cv_no)
                                                   =  cv_yes                      -- 最新フラグ=Y
            AND   xoha.req_status                  =  cv_request_status_04        -- 出荷実績計上済
            AND   xottv.transaction_type_id        =  xoha.order_type_id          -- 受注タイプID
            AND   xottv.shipping_shikyu_class      =  cv_shipping_shikyu_class_01 -- 出荷支給区分
            AND   xottv.start_date_active         <=  TRUNC( id_standard_date )
            AND   (( xottv.end_date_active        >=  TRUNC( id_standard_date ))
                  OR(xottv.end_date_active        IS  NULL ))
            AND   xola.order_header_id             =  xoha.order_header_id      -- 受注ヘッダID
-- 2008/11/04 H.Itou Mod Start T_S_573
--            AND   xola.shipping_item_code         IN  ( iv_item_no, lv_parent_item_no )  -- 出荷品目
            AND   xola.shipping_item_code       IN                               -- 品目コード
                  -- 親品目と親品目に紐付く子品目(2階層まで)
-- 2016/02/18 D.Sugahara Mod Start 1.38
--                 (SELECT ximv.item_no
                 (SELECT ximv.item_no  ximv_item_no
-- 2016/02/18 D.Sugahara Mod End 1.38
                  FROM   xxcmn_item_mst2_v ximv
                  WHERE  ximv.start_date_active <= TRUNC(id_standard_date)
                  AND    ximv.end_date_active   >= TRUNC(id_standard_date)
-- 2009/10/15 H.Itou Mod Start 本番障害#1661
--                  AND    LEVEL                  <= 2                 -- 子階層まで抽出
--                  START WITH ximv.item_no        = lv_parent_item_no -- 親品目から検索
--                  CONNECT BY NOCYCLE PRIOR ximv.item_id = ximv.parent_item_id
                  AND    ximv.parent_item_id     = lv_parent_item_id
-- 2009/10/15 H.Itou Mod End
                  )
-- 2008/11/04 H.Itou Mod End
            AND   NVL( xola.delete_flag, cv_no )  <>  cv_yes                    -- 削除フラグ'Y'以外
            AND   xola.shipped_quantity            >  0                         -- 出荷実績数量0以上
          UNION ALL
          SELECT  /*+ leading(xoha) index(xoha xxwsh_oh_n13) */
-- 2016/02/18 D.Sugahara Mod Start 1.38
--                  xoha.arrival_date
                  xoha.arrival_date  arrival_date
-- 2016/02/18 D.Sugahara Mod End 1.38
          FROM    xxwsh_order_headers_all        xoha,                        -- 受注ヘッダアドオン
                  xxwsh_order_lines_all          xola,                        -- 受注明細アドオン
                  xxwsh_oe_transaction_types2_v  xottv                        -- 受注タイプ
          WHERE   xoha.result_deliver_to_id       IS NULL
            AND   xoha.deliver_to_id               =  iv_move_to_id           -- 出荷先ID(実績)
            AND   NVL(xoha.latest_external_flag, cv_no)
                                                   =  cv_yes                      -- 最新フラグ=Y
            AND   xoha.req_status                  =  cv_request_status_04        -- 出荷実績計上済
            AND   xottv.transaction_type_id        =  xoha.order_type_id          -- 受注タイプID
            AND   xottv.shipping_shikyu_class      =  cv_shipping_shikyu_class_01 -- 出荷支給区分
            AND   xottv.start_date_active         <=  TRUNC( id_standard_date )
            AND   (( xottv.end_date_active        >=  TRUNC( id_standard_date ))
                  OR(xottv.end_date_active        IS  NULL ))
            AND   xola.order_header_id             =  xoha.order_header_id      -- 受注ヘッダID
-- 2008/11/04 H.Itou Mod Start T_S_573
--            AND   xola.shipping_item_code         IN  ( iv_item_no, lv_parent_item_no )  -- 出荷品目
            AND   xola.shipping_item_code       IN                               -- 出荷品目
                  -- 親品目と親品目に紐付く子品目(2階層まで)
-- 2016/02/18 D.Sugahara Mod Start 1.38
--                 (SELECT ximv.item_no
                 (SELECT ximv.item_no  ximv_item_no
-- 2016/02/18 D.Sugahara Mod End 1.38
                  FROM   xxcmn_item_mst2_v ximv
                  WHERE  ximv.start_date_active <= TRUNC(id_standard_date)
                  AND    ximv.end_date_active   >= TRUNC(id_standard_date)
-- 2009/10/15 H.Itou Mod Start 本番障害#1661
--                  AND    LEVEL                  <= 2                 -- 子階層まで抽出
--                  START WITH ximv.item_no        = lv_parent_item_no -- 親品目から検索
--                  CONNECT BY NOCYCLE PRIOR ximv.item_id = ximv.parent_item_id
                  AND    ximv.parent_item_id     = lv_parent_item_id
-- 2009/10/15 H.Itou Mod End
                  )
-- 2008/11/04 H.Itou Mod End
            AND   NVL( xola.delete_flag, cv_no )  <>  cv_yes                    -- 削除フラグ'Y'以外
            AND   xola.shipped_quantity            >  0)                        -- 出荷実績数量0以上
            ;
-- 2008/09/11 v1.18 UPDATE END
        EXCEPTION
          --
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
      END;
      --
      --
      -- 2-2. 上記で取得した最大着荷日に紐づくのロットの最大製造日を取得
      IF ( ld_max_ship_arrival_date IS NOT NULL ) THEN
        BEGIN
-- 2008/09/17 v1.19 UPDATE START
/*
          SELECT  MAX( fnd_date.string_to_date( ilm.attribute1, gv_yyyymmdd ) )
          INTO    ld_max_rship_manufact_date
          FROM    xxwsh_order_headers_all        xoha,                      -- 受注ヘッダアドオン
                  xxwsh_order_lines_all          xola,                      -- 受注明細アドオン
                  xxinv_mov_lot_details          xmld,                      -- 移動ロット詳細
                  xxwsh_oe_transaction_types2_v  xottv,                     -- 受注タイプ
                  ic_lots_mst                    ilm                        -- OPMロットマスタ
          WHERE   NVL ( xoha.result_deliver_to_id, xoha.deliver_to_id )
                                                   =  iv_move_to_id               -- 出荷先ID(実績)
-- 2008/09/08 v1.17 UPDATE START
--            AND   trunc( xoha.schedule_arrival_date )
--                                                   =  trunc( ld_max_ship_arrival_date ) -- 最大着荷日
            AND   xoha.schedule_arrival_date >= TRUNC( ld_max_ship_arrival_date )    -- 最大着荷日
            AND   xoha.schedule_arrival_date  < TRUNC( ld_max_ship_arrival_date + 1) -- 最大着荷日
-- 2008/09/08 v1.17 UPDATE END
            AND   NVL(xoha.latest_external_flag, cv_no)
                                                   =  cv_yes                      -- 最新フラグ=Y
            AND   xoha.req_status                  =  cv_request_status_04        -- 出荷実績計上済
            AND   xottv.transaction_type_id        =  xoha.order_type_id          -- 受注タイプID
            AND   xottv.shipping_shikyu_class      =  cv_shipping_shikyu_class_01 -- 出荷依頼
            AND   xottv.start_date_active         <=  trunc( id_standard_date )
            AND   (( xottv.end_date_active        >=  trunc( id_standard_date ))
                  OR(xottv.end_date_active        IS  NULL ))
            AND   xola.order_header_id             =  xoha.order_header_id        -- 受注ヘッダID
            AND   xola.shipping_item_code         IN  ( iv_item_no, lv_parent_item_no )  -- 品目コード
            AND   NVL( xola.delete_flag, cv_no )  <>  cv_yes                      -- 削除フラグ'Y'以外
            AND   xmld.mov_line_id                 =  xola.order_line_id          -- 受注明細ID
            AND   xmld.document_type_code          =  cv_document_type_10         -- 文書タイプ
            AND   xmld.record_type_code            =  cv_record_type_02           -- レコードタイプ
            AND   ilm.lot_id                       =  xmld.lot_id                 -- OPMロットID
            AND   ilm.item_id                      =  xmld.item_id                -- OPM品目ID
            ;
*/
-- 2016/02/18 D.Sugahara Mod Start 1.38
--          SELECT  MAX( fnd_date.string_to_date( attribute1, gv_yyyymmdd ) )
--          INTO    ld_max_rship_manufact_date
          SELECT  MAX( fnd_date.string_to_date( ilm_attribute3, gv_yyyymmdd ) )
          INTO    ld_max_rship_best_before_date
-- 2016/02/18 D.Sugahara Mod End 1.38
          FROM
            (SELECT /*+ leading(xoha xola) index(xoha xxwsh_oh_n27) */
-- 2016/02/18 D.Sugahara Mod Start 1.38
--                    ilm.attribute1
                    ilm.attribute3    ilm_attribute3
-- 2016/02/18 D.Sugahara Mod End 1.38
            FROM    xxwsh_order_headers_all        xoha,                      -- 受注ヘッダアドオン
                    xxwsh_order_lines_all          xola,                      -- 受注明細アドオン
                    xxinv_mov_lot_details          xmld,                      -- 移動ロット詳細
                    xxwsh_oe_transaction_types2_v  xottv,                     -- 受注タイプ
                    ic_lots_mst                    ilm                        -- OPMロットマスタ
            WHERE   xoha.result_deliver_to_id      =  iv_move_to_id           -- 出荷先ID(実績)
-- 2008/11/04 H.Itou Mod Start
--              AND   xoha.schedule_arrival_date    >= TRUNC( ld_max_ship_arrival_date ) -- 最大着荷日
--              AND   xoha.schedule_arrival_date   < TRUNC( ld_max_ship_arrival_date + 1)-- 最大着荷日
              AND   xoha.arrival_date    >= TRUNC( ld_max_ship_arrival_date )   -- 最大着荷日
              AND   xoha.arrival_date     < TRUNC( ld_max_ship_arrival_date + 1)-- 最大着荷日
-- 2008/11/04 H.Itou Mod End
              AND   NVL(xoha.latest_external_flag, cv_no) =  cv_yes           -- 最新フラグ=Y
              AND   xoha.req_status                =  cv_request_status_04    -- 出荷実績計上済
              AND   xottv.transaction_type_id      =  xoha.order_type_id      -- 受注タイプID
              AND   xottv.shipping_shikyu_class    =  cv_shipping_shikyu_class_01 -- 出荷依頼
              AND   xottv.start_date_active       <=  TRUNC( id_standard_date )
              AND   (( xottv.end_date_active      >=  TRUNC( id_standard_date ))
                    OR(xottv.end_date_active      IS  NULL ))
              AND   xola.order_header_id           =  xoha.order_header_id    -- 受注ヘッダID
-- 2008/11/04 H.Itou Mod Start T_S_573
--              AND   xola.shipping_item_code       IN ( iv_item_no, lv_parent_item_no ) -- 品目コード
              AND   xola.shipping_item_code       IN                               -- 品目コード
                    -- 親品目と親品目に紐付く子品目(2階層まで)
-- 2016/02/18 D.Sugahara Mod Start 1.38
--                   (SELECT ximv.item_no
                   (SELECT ximv.item_no ximv_item_no
-- 2016/02/18 D.Sugahara Mod End 1.38
                    FROM   xxcmn_item_mst2_v ximv
                    WHERE  ximv.start_date_active <= TRUNC(id_standard_date)
                    AND    ximv.end_date_active   >= TRUNC(id_standard_date)
-- 2009/10/15 H.Itou Mod Start 本番障害#1661
--                    AND    LEVEL                  <= 2                 -- 子階層まで抽出
--                    START WITH ximv.item_no        = lv_parent_item_no -- 親品目から検索
--                    CONNECT BY NOCYCLE PRIOR ximv.item_id = ximv.parent_item_id
                    AND    ximv.parent_item_id     = lv_parent_item_id
-- 2009/10/15 H.Itou Mod End
                    )
-- 2008/11/04 H.Itou Mod End
              AND   NVL( xola.delete_flag, cv_no ) <> cv_yes                  -- 削除フラグ'Y'以外
              AND   xmld.mov_line_id               =  xola.order_line_id      -- 受注明細ID
              AND   xmld.document_type_code        =  cv_document_type_10     -- 文書タイプ
              AND   xmld.record_type_code          =  cv_record_type_02       -- レコードタイプ
              AND   ilm.lot_id                     =  xmld.lot_id             -- OPMロットID
              AND   ilm.item_id                    =  xmld.item_id            -- OPM品目ID
-- 2009/01/22 H.Itou Add Start 本番#1000対応
              AND   xmld.actual_quantity           >  0                       -- 実績数量
-- 2009/01/22 H.Itou Add End
            UNION ALL
            SELECT  /*+ leading(xoha xola) index(xoha xxwsh_oh_n13) */
-- 2016/02/18 D.Sugahara Mod Start 1.38
--                    ilm.attribute1
                    ilm.attribute3    ilm_attribute3
-- 2016/02/18 D.Sugahara Mod End 1.38
            FROM    xxwsh_order_headers_all        xoha,                      -- 受注ヘッダアドオン
                    xxwsh_order_lines_all          xola,                      -- 受注明細アドオン
                    xxinv_mov_lot_details          xmld,                      -- 移動ロット詳細
                    xxwsh_oe_transaction_types2_v  xottv,                     -- 受注タイプ
                    ic_lots_mst                    ilm                        -- OPMロットマスタ
            WHERE   xoha.result_deliver_to_id     IS NULL
              AND   xoha.deliver_to_id             =  iv_move_to_id               -- 出荷先ID(実績)
              AND   xoha.schedule_arrival_date    >= TRUNC( ld_max_ship_arrival_date ) -- 最大着荷日
              AND   xoha.schedule_arrival_date   < TRUNC( ld_max_ship_arrival_date + 1)-- 最大着荷日
              AND   NVL(xoha.latest_external_flag, cv_no) =  cv_yes           -- 最新フラグ=Y
              AND   xoha.req_status                =  cv_request_status_04    -- 出荷実績計上済
              AND   xottv.transaction_type_id      =  xoha.order_type_id      -- 受注タイプID
              AND   xottv.shipping_shikyu_class    =  cv_shipping_shikyu_class_01 -- 出荷依頼
              AND   xottv.start_date_active       <=  trunc( id_standard_date )
              AND   (( xottv.end_date_active      >=  trunc( id_standard_date ))
                    OR(xottv.end_date_active      IS  NULL ))
              AND   xola.order_header_id           =  xoha.order_header_id    -- 受注ヘッダID
-- 2008/11/04 H.Itou Mod Start T_S_573
--              AND   xola.shipping_item_code       IN ( iv_item_no, lv_parent_item_no ) -- 品目コード
              AND   xola.shipping_item_code       IN                               -- 品目コード
                    -- 親品目と親品目に紐付く子品目(2階層まで)
-- 2016/02/18 D.Sugahara Mod Start 1.38
--                   (SELECT ximv.item_no
                   (SELECT ximv.item_no ximv_item_no
-- 2016/02/18 D.Sugahara Mod End 1.38
                    FROM   xxcmn_item_mst2_v ximv
                    WHERE  ximv.start_date_active <= TRUNC(id_standard_date)
                    AND    ximv.end_date_active   >= TRUNC(id_standard_date)
-- 2009/10/15 H.Itou Mod Start 本番障害#1661
--                    AND    LEVEL                  <= 2                 -- 子階層まで抽出
--                    START WITH ximv.item_no        = lv_parent_item_no -- 親品目から検索
--                    CONNECT BY NOCYCLE PRIOR ximv.item_id = ximv.parent_item_id
                    AND    ximv.parent_item_id     = lv_parent_item_id
-- 2009/10/15 H.Itou Mod End
                    )
-- 2008/11/04 H.Itou Mod End
              AND   NVL( xola.delete_flag, cv_no ) <>  cv_yes                 -- 削除フラグ'Y'以外
              AND   xmld.mov_line_id               =  xola.order_line_id      -- 受注明細ID
              AND   xmld.document_type_code        =  cv_document_type_10     -- 文書タイプ
              AND   xmld.record_type_code          =  cv_record_type_02       -- レコードタイプ
              AND   ilm.lot_id                     =  xmld.lot_id             -- OPMロットID
              AND   ilm.item_id                    =  xmld.item_id            -- OPM品目ID
-- 2009/01/22 H.Itou Add Start 本番#1000対応
              AND   xmld.actual_quantity           >  0)                      -- 実績数量
-- 2009/01/22 H.Itou Add End
              ;
-- 2008/09/17 v1.19 UPDATE END
          EXCEPTION
            WHEN OTHERS THEN
              RAISE global_api_others_expt;
        END;
      END IF;
      --
    --
    ELSE
      /**********************************
       *  供給情報取得(移動・在庫)(D-5) *
       **********************************/
      --
      -- 3.移動指示情報の取得
      IF ( iv_lot_biz_class = cv_move_plan ) THEN
        --
        BEGIN
-- 2016/02/18 D.Sugahara Mod Start 1.38
--          SELECT  MAX( fnd_date.string_to_date( ilm.attribute1, gv_yyyymmdd ) )
--                                                                -- 移動指示製造年月日
--          INTO    ld_max_move_manufact_date
          SELECT  MAX( fnd_date.string_to_date( ilm.attribute3, gv_yyyymmdd ) )  ilm_attribute3
                                                                -- 移動指示賞味期限
          INTO    ld_max_move_best_before_date
-- 2016/02/18 D.Sugahara Mod Start 1.38
          FROM    xxinv_mov_req_instr_headers    xmrih,         -- 移動依頼/指示ヘッダ（アドオン）
                  xxinv_mov_req_instr_lines      xmril,         -- 移動依頼/指示明細（アドオン）
                  xxinv_mov_lot_details          xmld,          -- 移動ロット詳細
                  ic_lots_mst                    ilm            -- OPMロットマスタ
          WHERE   xmrih.ship_to_locat_id    =  iv_move_to_id                   -- 入庫先ID
            AND   xmrih.comp_actual_flg     =  cv_no                           -- 実績計上済フラグ
            AND   xmrih.status             IN( cv_move_status_03,
                                               cv_move_status_04 )             -- ステータス
            AND   xmrih.schedule_arrival_date
                                           <=  iv_arrival_date                 -- 着日
            AND   xmril.mov_hdr_id          =  xmrih.mov_hdr_id                -- 移動ヘッダID
-- 2008/11/04 H.Itou Mod Start T_S_573
--            AND   xmril.item_code          IN( iv_item_no,
--                                               lv_parent_item_no )             -- 品目コード
            AND   xmril.item_code       IN                               -- 品目コード
                  -- 親品目と親品目に紐付く子品目(2階層まで)
-- 2016/02/18 D.Sugahara Mod Start 1.38
--                 (SELECT ximv.item_no
                 (SELECT ximv.item_no  ximv_item_no
-- 2016/02/18 D.Sugahara Mod Start 1.38
                  FROM   xxcmn_item_mst2_v ximv
                  WHERE  ximv.start_date_active <= TRUNC(id_standard_date)
                  AND    ximv.end_date_active   >= TRUNC(id_standard_date)
-- 2009/10/15 H.Itou Mod Start 本番障害#1661
--                  AND    LEVEL                  <= 2                 -- 子階層まで抽出
--                  START WITH ximv.item_no        = lv_parent_item_no -- 親品目から検索
--                  CONNECT BY NOCYCLE PRIOR ximv.item_id = ximv.parent_item_id
                  AND    ximv.parent_item_id     = lv_parent_item_id
-- 2009/10/15 H.Itou Mod End
                  )
-- 2008/11/04 H.Itou Mod End
            AND   xmril.delete_flg          =  cv_no                           -- 取消フラグ
            AND   xmld.mov_line_id          =  xmril.mov_line_id               -- 移動明細ID
            AND   xmld.document_type_code   =  cv_document_type_20             -- 文書タイプ
            AND   ((( xmrih.status  = cv_move_status_03 )                      -- レコードタイプ
                    AND ( xmld.record_type_code = cv_record_type_01 ))             -- 指示
                  OR(( xmrih.status = cv_move_status_04 )
                    AND ( xmld.record_type_code = cv_record_type_02 )))            -- 出庫実績
            AND   xmld.actual_quantity      >  0                               -- 実績数量
            AND   ilm.lot_id                =  xmld.lot_id                     -- OPMロットID
            AND   ilm.item_id               =  xmld.item_id                    -- OPM品目ID
            ;
        EXCEPTION
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
      END IF;
      --
      --
      -- 4. 手持数量情報の取得
      BEGIN
-- 2016/02/18 D.Sugahara Mod Start 1.38
--        SELECT  MAX( fnd_date.string_to_date( ilm.attribute1, gv_yyyymmdd ) )
--        INTO    ld_max_onhand_manufact_date
        SELECT  MAX( fnd_date.string_to_date( ilm.attribute3, gv_yyyymmdd ) ) ilm_attribute3
        INTO    ld_max_onhand_best_before_date
-- 2016/02/18 D.Sugahara Mod Start 1.38
        FROM    ic_loct_inv              ili,                      -- OPM手持数量
                ic_lots_mst              ilm,                      -- OPMロットマスタ
                xxcmn_item_mst2_v        ximv,                     -- OPM品目情報VIEW2
                xxcmn_item_locations_v   xilv                      -- OPM保管場所情報VIEW
-- 2008/11/04 H.Itou Mod Start T_S_573
--        WHERE   ximv.item_no  IN( iv_item_no, lv_parent_item_no )  -- 品目コード
        WHERE   ximv.item_no       IN                               -- 品目コード
                -- 親品目と親品目に紐付く子品目(2階層まで)
-- 2016/02/18 D.Sugahara Mod Start 1.38
--               (SELECT ximv1.item_no
               (SELECT ximv1.item_no  ximv1_item_no
-- 2016/02/18 D.Sugahara Mod End 1.38
                FROM   xxcmn_item_mst2_v ximv1
                WHERE  ximv1.start_date_active <= TRUNC(id_standard_date)
                AND    ximv1.end_date_active   >= TRUNC(id_standard_date)
-- 2009/10/15 H.Itou Mod Start 本番障害#1661
--                AND    LEVEL                  <= 2                 -- 子階層まで抽出
--                START WITH ximv.item_no        = lv_parent_item_no -- 親品目から検索
--                CONNECT BY NOCYCLE PRIOR ximv.item_id = ximv.parent_item_id
                AND    ximv1.parent_item_id     = lv_parent_item_id
-- 2009/10/15 H.Itou Mod End
                )
-- 2008/11/04 H.Itou Mod End
          AND   ximv.start_date_active    <= TRUNC(id_standard_date)
          AND   ximv.end_date_active      >= TRUNC(id_standard_date)
          AND   xilv.inventory_location_id = iv_move_to_id         -- 入庫先ID
          AND   ili.item_id                =  ximv.item_id         -- OPM品目ID
          AND   ili.location               =  xilv.segment1        -- 保管倉庫コード
          AND   ilm.lot_id                 =  ili.lot_id           -- ロットID
          AND   ilm.item_id                =  ili.item_id          -- OPM品目ID
          ;
      EXCEPTION
        WHEN  OTHERS THEN
          RAISE global_api_others_expt;
      END;
      --
      --
      -- 5. 移動実績情報の取得
      BEGIN
-- 2016/02/18 D.Sugahara Mod Start 1.38
--        SELECT  MAX( fnd_date.string_to_date( ilm.attribute1, gv_yyyymmdd ) )
--        INTO    ld_max_rmove_manufact_date
        SELECT  MAX( fnd_date.string_to_date( ilm.attribute3, gv_yyyymmdd ) )  ilm_attribute3
        INTO    ld_max_rmove_best_before_date
-- 2016/02/18 D.Sugahara Mod End 1.38
        FROM    xxinv_mov_req_instr_headers    xmrih,         -- 移動依頼/指示ヘッダ（アドオン）
                xxinv_mov_req_instr_lines      xmril,         -- 移動依頼/指示明細（アドオン）
                xxinv_mov_lot_details          xmld,          -- 移動ロット詳細
                ic_lots_mst                    ilm            -- OPMロットマスタ
        WHERE   xmrih.ship_to_locat_id    =  iv_move_to_id
          AND   xmrih.comp_actual_flg     =  cv_no                            -- 実績計上済フラグ
          AND   xmrih.status             IN( cv_move_status_05,
                                             cv_move_status_06 )              -- ステータス
          AND   xmril.mov_hdr_id          =  xmrih.mov_hdr_id                 -- 移動ヘッダID
-- 2008/11/04 H.Itou Mod Start T_S_573
--          AND   xmril.item_code          IN( iv_item_no, lv_parent_item_no )  -- 品目コード
          AND   xmril.item_code       IN                               -- 品目コード
                -- 親品目と親品目に紐付く子品目(2階層まで)
-- 2016/02/18 D.Sugahara Mod Start 1.38
               (SELECT ximv.item_no ximv_item_no 
-- 2016/02/18 D.Sugahara Mod End 1.38
                FROM   xxcmn_item_mst2_v ximv
                WHERE  ximv.start_date_active <= TRUNC(id_standard_date)
                AND    ximv.end_date_active   >= TRUNC(id_standard_date)
-- 2009/10/15 H.Itou Mod Start 本番障害#1661
--                AND    LEVEL                  <= 2                 -- 子階層まで抽出
--                START WITH ximv.item_no        = lv_parent_item_no -- 親品目から検索
--                CONNECT BY NOCYCLE PRIOR ximv.item_id = ximv.parent_item_id
                AND    ximv.parent_item_id     = lv_parent_item_id
-- 2009/10/15 H.Itou Mod End
                )
-- 2008/11/04 H.Itou Mod End
          AND   xmril.delete_flg          =  cv_no                            -- 取消フラグ
          AND   xmld.mov_line_id          =  xmril.mov_line_id                -- 移動明細ID
          AND   xmld.document_type_code   =  cv_document_type_20              -- 文書タイプ
          AND   xmld.record_type_code     =  cv_record_type_03                -- レコードタイプ
          AND   xmld.actual_quantity      >  0                                -- 実績数量
          AND   ilm.lot_id                =  xmld.lot_id                      -- OPMロットID
          AND   ilm.item_id               =  xmld.item_id                     -- OPM品目ID
          ;
      EXCEPTION
        WHEN  NO_DATA_FOUND THEN
          -- データなしは除外
          NULL;
          --
        WHEN  OTHERS THEN
          RAISE global_api_others_expt;
      END;
      --
    END IF;
    --
    /**********************************
     *  ロット逆転判定処理(D-6)       *
     **********************************/
    -- ロット逆転対象の日付を算出
    CASE iv_lot_biz_class
      -- ロット逆転処理種別が「1」の場合
      WHEN ( cv_ship_plan  ) THEN
-- 2016/02/18 D.Sugahara Mod Start 1.38
--        -- 「出荷指示製造年月日」「出荷実績製造年月日」のうち最大
--        ld_check_manufact_date
--                 := GREATEST( NVL(ld_max_ship_manufact_date,  cv_mindate),
--                              NVL(ld_max_rship_manufact_date, cv_mindate) );
        -- 「出荷指示賞味期限」「出荷実績賞味期限」のうち最大
        ld_check_best_before_date
                 := GREATEST( NVL(ld_max_ship_best_before_date,  cv_mindate),
                              NVL(ld_max_rship_best_before_date, cv_mindate) );
-- 2016/02/18 D.Sugahara Mod End 1.38
        --
        --
      -- ロット逆転処理種別が「2」の場合
      WHEN ( cv_ship_result ) THEN
-- 2016/02/18 D.Sugahara Mod Start 1.38
--        ld_check_manufact_date := ld_max_rship_manufact_date;
        ld_check_best_before_date := NVL(ld_max_rship_best_before_date, cv_mindate);
-- 2016/02/18 D.Sugahara Mod End 1.38
        --
        --
      -- ロット逆転処理種別が「5」の場合
      WHEN ( cv_move_plan   ) THEN
-- 2016/02/18 D.Sugahara Mod Start 1.38
--        -- 「移動指示製造年月日」「移動実績製造年月日」「手持製造年月日」のうち最大
--        ld_check_manufact_date
--                 := GREATEST( NVL(ld_max_move_manufact_date,   cv_mindate),
--                              NVL(ld_max_rmove_manufact_date,  cv_mindate),
--                              NVL(ld_max_onhand_manufact_date, cv_mindate) );
        -- 「移動指示賞味期限」「移動実績賞味期限」「手持賞味期限」のうち最大
        ld_check_best_before_date
                 := GREATEST( NVL(ld_max_move_best_before_date,   cv_mindate),
                              NVL(ld_max_rmove_best_before_date,  cv_mindate),
                              NVL(ld_max_onhand_best_before_date, cv_mindate) );
-- 2016/02/18 D.Sugahara Mod End 1.38
        --
        --
      -- ロット逆転処理種別が「6」の場合
      WHEN ( cv_move_result ) THEN
-- 2016/02/18 D.Sugahara Mod Start 1.38
--        -- 移動実績製造年月日」「手持製造年月日」のうち最大
--        ld_check_manufact_date
--                 := GREATEST( NVL(ld_max_rmove_manufact_date  ,cv_mindate),
--                              NVL(ld_max_onhand_manufact_date ,cv_mindate) );
        -- 移動実績賞味期限」「手持賞味期限」のうち最大
        ld_check_best_before_date
                 := GREATEST( NVL(ld_max_rmove_best_before_date  ,cv_mindate),
                              NVL(ld_max_onhand_best_before_date ,cv_mindate) );
-- 2016/02/18 D.Sugahara Mod End 1.38
    END CASE;
    --
-- 2016/02/18 D.Sugahara Mod Start 1.38
--    -- 「チェック日付」＞ 「最大製造年月日」ならば、ロット逆転
--    IF ( ( ld_check_manufact_date <= ld_max_manufact_date )
--      OR ( ld_check_manufact_date IS NULL                ) ) THEN
    -- 「チェック日付」＞ 「最大賞味期限」ならば、ロット逆転
    IF ( ( ld_check_best_before_date <= ld_max_best_before_date )
      OR ( ld_check_best_before_date IS NULL                ) ) THEN
-- 2016/02/18 D.Sugahara Mod End 1.38
      on_result         :=  ln_result_success;                     -- 処理結果
-- 2009/01/26 D.Nihei Mod Start 本番#936対応 正常の場合も逆転日付を返却するように修正
--      on_reversal_date  :=  NULL;                                  -- 逆転日付
-- 2016/02/18 D.Sugahara Mod Start 1.38
--      on_reversal_date  :=  ld_check_manufact_date;                -- 逆転日付
      on_reversal_date  :=  ld_check_best_before_date;                -- 逆転日付
-- 2016/02/18 D.Sugahara Mod End 1.38
-- 2009/01/26 D.Nihei Mod End
    ELSE
      on_result         :=  ln_result_error;                       -- 処理結果
-- 2016/02/18 D.Sugahara Mod Start 1.38
--      on_reversal_date  :=  ld_check_manufact_date;                -- 逆転日付
      on_reversal_date  :=  ld_check_best_before_date;                -- 逆転日付
-- 2016/02/18 D.Sugahara Mod End 1.38
    END IF;
      --
    /**********************************
     *  OUTパラメータセット(D-7)      *
     **********************************/
    --
    ov_retcode                  := gv_status_normal;   -- リターンコード
    ov_errmsg_code              := NULL;               -- エラーメッセージコード
    ov_errmsg                   := NULL;               -- エラーメッセージ
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg      := lv_errmsg;
      ov_errmsg_code := lv_err_cd;
      ov_retcode     := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg      := SQLERRM;
      ov_errmsg_code := SQLCODE;
      ov_retcode     := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg      := SQLERRM;
      ov_errmsg_code := SQLCODE;
      ov_retcode     := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END check_lot_reversal;
--
-- 2009/01/22 H.Itou Add Start 本番#1000対応 ロット逆転防止チェック(依頼No指定あり)を追加(自分自身を含めずにチェックする)
  /**********************************************************************************
   * Procedure Name   : check_lot_reversal2
   * Description      : ロット逆転防止チェック
   ***********************************************************************************/
  PROCEDURE check_lot_reversal2(
    iv_lot_biz_class              IN  VARCHAR2,                                -- 1.ロット逆転処理種別
    iv_item_no                    IN  xxcmn_item_mst_v.item_no%TYPE,           -- 2.品目コード
    iv_lot_no                     IN  ic_lots_mst.lot_no%TYPE,                 -- 3.ロットNo
    iv_move_to_id                 IN  NUMBER,                                  -- 4.配送先ID/入庫先ID
    iv_arrival_date               IN  DATE,                                    -- 5.着日
    id_standard_date              IN  DATE  DEFAULT SYSDATE,                   -- 6.基準日(適用日基準日)
    iv_request_no                 IN  xxwsh_order_headers_all.request_no%TYPE, -- 7.依頼No
    ov_retcode                    OUT NOCOPY VARCHAR2,                         -- 7.リターンコード
    ov_errmsg_code                OUT NOCOPY VARCHAR2,                         -- 8.エラーメッセージコード
    ov_errmsg                     OUT NOCOPY VARCHAR2,                         -- 9.エラーメッセージ
    on_result                     OUT NOCOPY NUMBER,                           -- 10.処理結果
    on_reversal_date              OUT NOCOPY DATE                              -- 11.逆転日付
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_lot_reversal2'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- メッセージID
    cv_xxwsh_in_pram_set_err       CONSTANT VARCHAR2(100) := 'APP-XXWSH-12651'; -- 必須入力パラメータ未設定エラーメッセージ
    cv_xxwsh_in_pram_lot_err       CONSTANT VARCHAR2(100) := 'APP-XXWSH-12652'; -- 入力パラメータ「ロット逆転処理種別」セット内容エラー
    cv_xxwsh_in_pram_arr_err       CONSTANT VARCHAR2(100) := 'APP-XXWSH-12653'; -- 入力パラメータ未設定エラーメッセージ
    cv_xxwsh_in_no_lot_err         CONSTANT VARCHAR2(100) := 'APP-XXWSH-12654'; -- 対象ロットデータなしエラーメッセージ
    -- トークン
    cv_tkn_in_parm                 CONSTANT VARCHAR2(30)  := 'in_param';
    cv_tkn_lot_no                  CONSTANT VARCHAR2(30)  := 'lot_no';
    -- トークンセット値
    cv_ship_move_class_char        CONSTANT VARCHAR2(30)  := 'ロット逆転処理種別';
    cv_item_code_char              CONSTANT VARCHAR2(30)  := '品目コード';
    cv_lot_no_char                 CONSTANT VARCHAR2(30)  := 'ロットNo';
    cv_move_to_char                CONSTANT VARCHAR2(30)  := '配送先ID/入庫先ID';
    cv_request_no_char             CONSTANT VARCHAR2(30)  := '依頼No/移動No';
    --
    -- ロット逆転処理種別
    cv_ship_plan                   CONSTANT VARCHAR2(1)   := '1';         -- 出荷指示
    cv_ship_result                 CONSTANT VARCHAR2(1)   := '2';         -- 出荷実績
    cv_move_plan                   CONSTANT VARCHAR2(1)   := '5';         -- 移動指示
    cv_move_result                 CONSTANT VARCHAR2(1)   := '6';         -- 移動実績
    --
    -- 出荷依頼ステータス
    cv_request_status_03           CONSTANT VARCHAR2(2)   := '03';        -- 締め済み
    cv_request_status_04           CONSTANT VARCHAR2(2)   := '04';        -- 出荷実績計上済
    -- 移動ステータス
    cv_move_status_03              CONSTANT VARCHAR2(2)   := '03';        -- 調整中
    cv_move_status_04              CONSTANT VARCHAR2(2)   := '04';        -- 出庫報告有
    cv_move_status_05              CONSTANT VARCHAR2(2)   := '05';        -- 入庫報告有
    cv_move_status_06              CONSTANT VARCHAR2(2)   := '06';        -- 入出庫報告有
    --
    -- 出荷支給区分
    cv_shipping_shikyu_class_01    CONSTANT VARCHAR2(1)   := '1';         -- 出荷依頼
    -- 文書タイプ
    cv_document_type_10            CONSTANT VARCHAR2(2)   := '10';        -- 出荷依頼
    cv_document_type_20            CONSTANT VARCHAR2(2)   := '20';        -- 移動
    -- レコードタイプ
    cv_record_type_01              CONSTANT VARCHAR2(2)   := '10';         -- 指示
    cv_record_type_02              CONSTANT VARCHAR2(2)   := '20';         -- 出庫実績
    cv_record_type_03              CONSTANT VARCHAR2(2)   := '30';         -- 入庫実績
    --
    cv_zero                        CONSTANT VARCHAR2(1)   := '0';         -- ゼロ値(VARCHAR2)
    cv_yes                         CONSTANT VARCHAR2(1)   := 'Y';         -- Y (YES_NO区分)
    cv_no                          CONSTANT VARCHAR2(1)   := 'N';         -- N (YES_NO区分)
    --
    ln_result_success              CONSTANT NUMBER        := 0;           -- 0 (正常)
    ln_result_error                CONSTANT NUMBER        := 1;           -- 1 (異常)
    --
    cv_mindate                     CONSTANT DATE
                                        := fnd_date.string_to_date('1900/01/01', gv_yyyymmdd);
                                                                          -- 最小日付
--
--
    -- *** ローカル変数 ***
    -- エラー変数
    lv_err_cd             VARCHAR2(30);
    --
-- 2016/02/18 D.Sugahara Mod Start 1.38
--    ld_max_manufact_date           ic_lots_mst.attribute1%TYPE;           -- 最大製造年月日
    ld_max_best_before_date        ic_lots_mst.attribute3%TYPE;           -- 最大賞味期限
-- 2016/02/18 D.Sugahara Mod End 1.38
-- 2009/10/15 H.Itou Mod Start 本番障害#1661
--    lv_parent_item_no              xxcmn_item_mst2_v.item_no%TYPE;        -- 親品目コード
    lv_parent_item_id              xxcmn_item_mst2_v.parent_item_id%TYPE; -- 親品目ID
-- 2009/10/15 H.Itou Mod End
    --
-- 2016/02/18 D.Sugahara Mod Start 1.38
--    ld_max_ship_manufact_date      DATE;                                  -- 出荷指示製造年月日
    ld_max_ship_best_before_date   DATE;                                  -- 出荷指示賞味期限
-- 2016/02/18 D.Sugahara Mod End 1.38
    ld_max_ship_arrival_date       xxwsh_order_headers_all.arrival_date%type;
                                                                          -- 最大着荷日(出荷)
-- 2016/02/18 D.Sugahara Mod Start 1.38
--    ld_max_rship_manufact_date     DATE;                                  -- 出荷実績製造年月日
--    --
--    ld_max_move_manufact_date      DATE;                                  -- 移動指示製造年月日
    ld_max_rship_best_before_date  DATE;                                  -- 出荷実績賞味期限
    --
    ld_max_move_best_before_date   DATE;                                  -- 移動指示賞味期限
-- 2016/02/18 D.Sugahara Mod End 1.38
    ld_max_move_arrival_date       xxinv_mov_req_instr_headers.actual_arrival_date%type;
                                                                          -- 最大着荷日(移動)
-- 2016/02/18 D.Sugahara Mod Start 1.38
--    ld_max_rmove_manufact_date     DATE;                                  -- 移動実績製造年月日
--    --
--    ld_max_onhand_manufact_date    DATE;                                  -- 手持製造年月日
--    --
--    ld_check_manufact_date         DATE;                                  -- チェック日付
    ld_max_rmove_best_before_date  DATE;                                  -- 移動実績賞味期限
    --
    ld_max_onhand_best_before_date DATE;                                  -- 手持賞味期限
    --
    ld_check_best_before_date      DATE;                                  -- チェック日付
-- 2016/02/18 D.Sugahara Mod End 1.38
    --
    ln_result                      NUMBER;                                -- 結果
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    --
    /**********************************
     *  パラメータチェック(D-1)       *
     **********************************/
    -- 必須入力パラメータをチェックします
    -- ロット逆転処理種別
    IF   ( iv_lot_biz_class IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_in_pram_set_err,
                                            cv_tkn_in_parm,
                                            cv_ship_move_class_char);
      lv_err_cd := cv_xxwsh_in_pram_set_err;
      RAISE global_api_expt;
    --
    -- 品目コード
    ELSIF( iv_item_no       IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_in_pram_set_err,
                                            cv_tkn_in_parm,
                                            cv_item_code_char);
      lv_err_cd := cv_xxwsh_in_pram_set_err;
      RAISE global_api_expt;
    --
    -- ロットNo
    ELSIF( iv_lot_no         IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_in_pram_set_err,
                                            cv_tkn_in_parm,
                                            cv_lot_no_char);
      lv_err_cd := cv_xxwsh_in_pram_set_err;
      RAISE global_api_expt;
    --
    -- 配送先ID/入庫先ID
    ELSIF( iv_move_to_id    IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_in_pram_set_err,
                                            cv_tkn_in_parm,
                                            cv_move_to_char);
      lv_err_cd := cv_xxwsh_in_pram_set_err;
      RAISE global_api_expt;
    --
    -- 依頼No
    ELSIF( iv_request_no    IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_in_pram_set_err,
                                            cv_tkn_in_parm,
                                            cv_request_no_char);
      lv_err_cd := cv_xxwsh_in_pram_set_err;
      RAISE global_api_expt;
    END IF;
    --
    --
    -- 入力パラメータ「ロット逆転処理種別」の値チェック
    -- 値が1、2、5、6であるかチェック
    IF ( iv_lot_biz_class NOT IN ( cv_ship_plan,
                                   cv_ship_result,
                                   cv_move_plan,
                                   cv_move_result )) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_in_pram_lot_err
                                           );
      lv_err_cd := cv_xxwsh_in_pram_lot_err;
      RAISE global_api_expt;
    ELSE
    -- 値が1、5の場合、「着日」がセットされているかチェック
      IF  ( ( iv_lot_biz_class IN ( cv_ship_plan, cv_move_plan ))
        AND ( iv_arrival_date  IS NULL )) THEN
        --
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                              cv_xxwsh_in_pram_arr_err
                                             );
        lv_err_cd := cv_xxwsh_in_pram_arr_err;
        RAISE global_api_expt;
      END IF;
    END IF;
    --
    /**********************************
     *  製造年月日取得(D-2)           *
     **********************************/
    -- OPMロットマスタから当該ロットの製造年月日を取得
    BEGIN
-- 2016/02/18 D.Sugahara Mod Start 1.38
--      SELECT fnd_date.string_to_date( ilm.attribute1, gv_yyyymmdd )   -- 最大製造年月日
--      INTO   ld_max_manufact_date
      SELECT fnd_date.string_to_date( ilm.attribute3, gv_yyyymmdd )  ilm_attribute3 -- 最大賞味期限
      INTO   ld_max_best_before_date
-- 2016/02/18 D.Sugahara Mod End 1.38
      FROM   ic_lots_mst              ilm,                             -- OPMロットマスタ
             xxcmn_item_mst2_v        ximv                             -- OPM品目情報VIEW2
      WHERE  ximv.item_no             = iv_item_no                     -- 品目コード
        AND  ximv.start_date_active  <= trunc( id_standard_date )
        AND  ximv.end_date_active    >= trunc( id_standard_date )
        AND  ilm.item_id              = ximv.item_id
        AND  ilm.lot_no               = iv_lot_no;                     -- ロットNo
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- 取得エラー
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                              cv_xxwsh_in_no_lot_err,
                                              cv_tkn_lot_no,
                                              iv_lot_no);
        lv_err_cd := cv_xxwsh_in_no_lot_err;
      RAISE global_api_expt;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
    --
    --
    --
    /**********************************
     *  親品目取得(D-3)               *
     **********************************/
    -- OPM品目マスタから親品目コードを取得
    BEGIN
-- 2009/10/15 H.Itou Mod Start 本番障害#1661
--      SELECT ximv2.item_no                                             -- 品目コード(親品目)
--      INTO   lv_parent_item_no
--      FROM   xxcmn_item_mst2_v         ximv1,                          -- OPM品目情報VIEW2(子)
--             xxcmn_item_mst2_v         ximv2                           -- OPM品目情報VIEW2(親)
--      WHERE  ximv1.item_no             =  iv_item_no                   -- 品目コード
--        AND  ximv1.start_date_active  <=  trunc( id_standard_date )
--        AND  ximv1.end_date_active    >=  trunc( id_standard_date )
--        AND  ximv2.item_id             =  ximv1.parent_item_id         -- 親品目ID
--        AND  ximv2.start_date_active  <=  trunc( id_standard_date )
--        AND  ximv2.end_date_active    >=  trunc( id_standard_date );
      SELECT ximv.parent_item_id                                     -- 親品目ID
      INTO   lv_parent_item_id
      FROM   xxcmn_item_mst2_v         ximv                          -- OPM品目情報VIEW2
      WHERE  ximv.item_no             =  iv_item_no                  -- 品目コード
        AND  ximv.start_date_active  <=  trunc( id_standard_date )
        AND  ximv.end_date_active    >=  trunc( id_standard_date )
      ;
-- 2009/10/15 H.Itou Mod End
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      -- データなしは除外
        NULL;
      --
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
    --
    --
    /**********************************
    *  ロット逆転処理種別の判定       *
    **********************************/
    IF ( iv_lot_biz_class IN ( cv_ship_plan , cv_ship_result) ) THEN
    --
      /**********************************
       *  供給情報取得(出荷)(D-4)       *
       **********************************/
       -- 1. 出荷指示情報の取得
      IF ( iv_lot_biz_class = cv_ship_plan ) THEN
        BEGIN
-- 2016/02/18 D.Sugahara Mod Start 1.38
--          SELECT  MAX( fnd_date.string_to_date( ilm.attribute1, gv_yyyymmdd ))
--                                                                            -- 出荷指示製造年月日
--          INTO    ld_max_ship_manufact_date
          SELECT  MAX( fnd_date.string_to_date( ilm.attribute3, gv_yyyymmdd )) max_ilm_attribute3
                                                                            -- 出荷指示賞味期限
          INTO    ld_max_ship_best_before_date
-- 2016/02/18 D.Sugahara Mod End 1.38
          FROM    xxwsh_order_headers_all        xoha,                      -- 受注ヘッダアドオン
                  xxwsh_order_lines_all          xola,                      -- 受注明細アドオン
                  xxinv_mov_lot_details          xmld,                      -- 移動ロット詳細
                  xxwsh_oe_transaction_types2_v  xottv,                     -- 受注タイプ
                  ic_lots_mst                    ilm                        -- OPMロットマスタ
          WHERE   xoha.deliver_to_id             =  iv_move_to_id                -- 出荷先ID
            AND   NVL(xoha.latest_external_flag, cv_no)
                                                 =  cv_yes                       -- 最新フラグ
            AND   xoha.schedule_arrival_date    <=  iv_arrival_date              -- 着日
            AND   xoha.req_status                =  cv_request_status_03         -- 締め済み
            AND   xoha.request_no               <>  iv_request_no                -- 自分自身の依頼Noは除く
            AND   xottv.transaction_type_id      =  xoha.order_type_id           -- 受注タイプID
            AND   xottv.shipping_shikyu_class    =  cv_shipping_shikyu_class_01  -- 出荷依頼
            AND   xottv.start_date_active       <=  trunc( id_standard_date )
            AND   ( (xottv.end_date_active      >=  trunc( id_standard_date ))
                  OR(xottv.end_date_active      IS  NULL ))
            AND   xola.order_header_id           =  xoha.order_header_id         -- 受注ヘッダID
            AND   xola.shipping_item_code       IN                               -- 品目コード
                  -- 親品目と親品目に紐付く子品目(2階層まで)
-- 2016/02/18 D.Sugahara Mod Start 1.38
--                 (SELECT ximv.item_no
                 (SELECT ximv.item_no ximv_item_no
-- 2016/02/18 D.Sugahara Mod End 1.38
                  FROM   xxcmn_item_mst2_v ximv
                  WHERE  ximv.start_date_active <= TRUNC(id_standard_date)
                  AND    ximv.end_date_active   >= TRUNC(id_standard_date)
-- 2009/10/15 H.Itou Mod Start 本番障害#1661
--                  AND    LEVEL                  <= 2                 -- 子階層まで抽出
--                  START WITH ximv.item_no        = lv_parent_item_no -- 親品目から検索
--                  CONNECT BY NOCYCLE PRIOR ximv.item_id = ximv.parent_item_id
                  AND    ximv.parent_item_id     = lv_parent_item_id
-- 2009/10/15 H.Itou Mod End
                  )
            AND   NVL( xola.delete_flag,  cv_no )
                                                <>  cv_yes                       -- 削除フラグ'Y'以外
            AND   xmld.mov_line_id               =  xola.order_line_id           -- 受注明細ID
            AND   xmld.document_type_code        =  cv_document_type_10          -- 文書タイプ
            AND   xmld.record_type_code          =  cv_record_type_01            -- レコードタイプ
            AND   ilm.lot_id                     =  xmld.lot_id                  -- OPMロットID
            AND   ilm.item_id                    =  xmld.item_id                 -- OPM品目ID
            ;
        EXCEPTION
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
      END IF;
      --
      --
      -- 2-1. 入力パラメータに合致する最大の着荷日を取得
      BEGIN
-- 2016/02/18 D.Sugahara Mod Start 1.38
--        SELECT  MAX( arrival_date )                                    -- 最大着荷日
        SELECT  MAX( arrival_date )  max_arrival_date                         -- 最大着荷日
-- 2016/02/18 D.Sugahara Mod End 1.38
        INTO    ld_max_ship_arrival_date
        FROM
          (SELECT /*+ leading(xoha) index(xoha xxwsh_oh_n27) */
-- 2016/02/18 D.Sugahara Mod Start 1.38
--                  xoha.arrival_date
                  xoha.arrival_date  arrival_date
-- 2016/02/18 D.Sugahara Mod End 1.38
          FROM    xxwsh_order_headers_all        xoha,                        -- 受注ヘッダアドオン
                  xxwsh_order_lines_all          xola,                        -- 受注明細アドオン
                  xxwsh_oe_transaction_types2_v  xottv                        -- 受注タイプ
          WHERE   xoha.result_deliver_to_id        =  iv_move_to_id           -- 出荷先ID(実績)
            AND   NVL(xoha.latest_external_flag, cv_no)
                                                   =  cv_yes                      -- 最新フラグ=Y
            AND   xoha.req_status                  =  cv_request_status_04        -- 出荷実績計上済
            AND   xoha.request_no                 <>  iv_request_no               -- 自分自身の依頼Noは除く
            AND   xottv.transaction_type_id        =  xoha.order_type_id          -- 受注タイプID
            AND   xottv.shipping_shikyu_class      =  cv_shipping_shikyu_class_01 -- 出荷支給区分
            AND   xottv.start_date_active         <=  TRUNC( id_standard_date )
            AND   (( xottv.end_date_active        >=  TRUNC( id_standard_date ))
                  OR(xottv.end_date_active        IS  NULL ))
            AND   xola.order_header_id             =  xoha.order_header_id      -- 受注ヘッダID
            AND   xola.shipping_item_code       IN                               -- 品目コード
                  -- 親品目と親品目に紐付く子品目(2階層まで)
-- 2016/02/18 D.Sugahara Mod Start 1.38
--                 (SELECT ximv.item_no
                 (SELECT ximv.item_no  ximv_item_no
-- 2016/02/18 D.Sugahara Mod End 1.38
                  FROM   xxcmn_item_mst2_v ximv
                  WHERE  ximv.start_date_active <= TRUNC(id_standard_date)
                  AND    ximv.end_date_active   >= TRUNC(id_standard_date)
-- 2009/10/15 H.Itou Mod Start 本番障害#1661
--                  AND    LEVEL                  <= 2                 -- 子階層まで抽出
--                  START WITH ximv.item_no        = lv_parent_item_no -- 親品目から検索
--                  CONNECT BY NOCYCLE PRIOR ximv.item_id = ximv.parent_item_id
                  AND    ximv.parent_item_id     = lv_parent_item_id
-- 2009/10/15 H.Itou Mod End
                  )
            AND   NVL( xola.delete_flag, cv_no )  <>  cv_yes                    -- 削除フラグ'Y'以外
            AND   xola.shipped_quantity            >  0                         -- 出荷実績数量0以上
          UNION ALL
          SELECT  /*+ leading(xoha) index(xoha xxwsh_oh_n13) */
-- 2016/02/18 D.Sugahara Mod Start 1.38
--                  xoha.arrival_date
                  xoha.arrival_date  arrival_date
-- 2016/02/18 D.Sugahara Mod End 1.38
          FROM    xxwsh_order_headers_all        xoha,                        -- 受注ヘッダアドオン
                  xxwsh_order_lines_all          xola,                        -- 受注明細アドオン
                  xxwsh_oe_transaction_types2_v  xottv                        -- 受注タイプ
          WHERE   xoha.result_deliver_to_id       IS NULL
            AND   xoha.deliver_to_id               =  iv_move_to_id           -- 出荷先ID(実績)
            AND   NVL(xoha.latest_external_flag, cv_no)
                                                   =  cv_yes                      -- 最新フラグ=Y
            AND   xoha.req_status                  =  cv_request_status_04        -- 出荷実績計上済
            AND   xoha.request_no                 <>  iv_request_no               -- 自分自身の依頼Noは除く
            AND   xottv.transaction_type_id        =  xoha.order_type_id          -- 受注タイプID
            AND   xottv.shipping_shikyu_class      =  cv_shipping_shikyu_class_01 -- 出荷支給区分
            AND   xottv.start_date_active         <=  TRUNC( id_standard_date )
            AND   (( xottv.end_date_active        >=  TRUNC( id_standard_date ))
                  OR(xottv.end_date_active        IS  NULL ))
            AND   xola.order_header_id             =  xoha.order_header_id      -- 受注ヘッダID
            AND   xola.shipping_item_code       IN                               -- 出荷品目
                  -- 親品目と親品目に紐付く子品目(2階層まで)
-- 2016/02/18 D.Sugahara Mod Start 1.38
--                 (SELECT ximv.item_no
                 (SELECT ximv.item_no  ximv_item_no
-- 2016/02/18 D.Sugahara Mod End 1.38
                  FROM   xxcmn_item_mst2_v ximv
                  WHERE  ximv.start_date_active <= TRUNC(id_standard_date)
                  AND    ximv.end_date_active   >= TRUNC(id_standard_date)
-- 2009/10/15 H.Itou Mod Start 本番障害#1661
--                  AND    LEVEL                  <= 2                 -- 子階層まで抽出
--                  START WITH ximv.item_no        = lv_parent_item_no -- 親品目から検索
--                  CONNECT BY NOCYCLE PRIOR ximv.item_id = ximv.parent_item_id
                  AND    ximv.parent_item_id     = lv_parent_item_id
-- 2009/10/15 H.Itou Mod End
                  )
            AND   NVL( xola.delete_flag, cv_no )  <>  cv_yes                    -- 削除フラグ'Y'以外
            AND   xola.shipped_quantity            >  0)                        -- 出荷実績数量0以上
            ;
        EXCEPTION
          --
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
      END;
      --
      --
      -- 2-2. 上記で取得した最大着荷日に紐づくのロットの最大製造日を取得
      IF ( ld_max_ship_arrival_date IS NOT NULL ) THEN
        BEGIN
-- 2016/02/18 D.Sugahara Mod Start 1.38
--          SELECT  MAX( fnd_date.string_to_date( attribute1, gv_yyyymmdd ) )
--          INTO    ld_max_rship_manufact_date
          SELECT  MAX( fnd_date.string_to_date( ilm_attribute3, gv_yyyymmdd ) )
          INTO    ld_max_rship_best_before_date
-- 2016/02/18 D.Sugahara Mod End 1.38
          FROM
            (SELECT /*+ leading(xoha xola) index(xoha xxwsh_oh_n27) */
-- 2016/02/18 D.Sugahara Mod Start 1.38
--                    ilm.attribute1
                    ilm.attribute3    ilm_attribute3
-- 2016/02/18 D.Sugahara Mod End 1.38
            FROM    xxwsh_order_headers_all        xoha,                      -- 受注ヘッダアドオン
                    xxwsh_order_lines_all          xola,                      -- 受注明細アドオン
                    xxinv_mov_lot_details          xmld,                      -- 移動ロット詳細
                    xxwsh_oe_transaction_types2_v  xottv,                     -- 受注タイプ
                    ic_lots_mst                    ilm                        -- OPMロットマスタ
            WHERE   xoha.result_deliver_to_id      =  iv_move_to_id           -- 出荷先ID(実績)
              AND   xoha.arrival_date    >= TRUNC( ld_max_ship_arrival_date )   -- 最大着荷日
              AND   xoha.arrival_date     < TRUNC( ld_max_ship_arrival_date + 1)-- 最大着荷日
              AND   NVL(xoha.latest_external_flag, cv_no) =  cv_yes           -- 最新フラグ=Y
              AND   xoha.req_status                =  cv_request_status_04    -- 出荷実績計上済
              AND   xoha.request_no               <>  iv_request_no           -- 自分自身の依頼Noは除く
              AND   xottv.transaction_type_id      =  xoha.order_type_id      -- 受注タイプID
              AND   xottv.shipping_shikyu_class    =  cv_shipping_shikyu_class_01 -- 出荷依頼
              AND   xottv.start_date_active       <=  TRUNC( id_standard_date )
              AND   (( xottv.end_date_active      >=  TRUNC( id_standard_date ))
                    OR(xottv.end_date_active      IS  NULL ))
              AND   xola.order_header_id           =  xoha.order_header_id    -- 受注ヘッダID
              AND   xola.shipping_item_code       IN                               -- 品目コード
                    -- 親品目と親品目に紐付く子品目(2階層まで)
-- 2016/02/18 D.Sugahara Mod Start 1.38
--                   (SELECT ximv.item_no
                   (SELECT ximv.item_no ximv_item_no
-- 2016/02/18 D.Sugahara Mod End 1.38
                    FROM   xxcmn_item_mst2_v ximv
                    WHERE  ximv.start_date_active <= TRUNC(id_standard_date)
                    AND    ximv.end_date_active   >= TRUNC(id_standard_date)
-- 2009/10/15 H.Itou Mod Start 本番障害#1661
--                    AND    LEVEL                  <= 2                 -- 子階層まで抽出
--                    START WITH ximv.item_no        = lv_parent_item_no -- 親品目から検索
--                    CONNECT BY NOCYCLE PRIOR ximv.item_id = ximv.parent_item_id
                    AND    ximv.parent_item_id     = lv_parent_item_id
-- 2009/10/15 H.Itou Mod End
                    )
              AND   NVL( xola.delete_flag, cv_no ) <> cv_yes                  -- 削除フラグ'Y'以外
              AND   xmld.mov_line_id               =  xola.order_line_id      -- 受注明細ID
              AND   xmld.document_type_code        =  cv_document_type_10     -- 文書タイプ
              AND   xmld.record_type_code          =  cv_record_type_02       -- レコードタイプ
              AND   ilm.lot_id                     =  xmld.lot_id             -- OPMロットID
              AND   ilm.item_id                    =  xmld.item_id            -- OPM品目ID
              AND   xmld.actual_quantity           >  0                       -- 実績数量
            UNION ALL
            SELECT  /*+ leading(xoha xola) index(xoha xxwsh_oh_n13) */
-- 2016/02/18 D.Sugahara Mod Start 1.38
--                    ilm.attribute1
                    ilm.attribute3    ilm_attribute3
-- 2016/02/18 D.Sugahara Mod End 1.38
            FROM    xxwsh_order_headers_all        xoha,                      -- 受注ヘッダアドオン
                    xxwsh_order_lines_all          xola,                      -- 受注明細アドオン
                    xxinv_mov_lot_details          xmld,                      -- 移動ロット詳細
                    xxwsh_oe_transaction_types2_v  xottv,                     -- 受注タイプ
                    ic_lots_mst                    ilm                        -- OPMロットマスタ
            WHERE   xoha.result_deliver_to_id     IS NULL
              AND   xoha.deliver_to_id             =  iv_move_to_id               -- 出荷先ID(実績)
              AND   xoha.schedule_arrival_date    >= TRUNC( ld_max_ship_arrival_date ) -- 最大着荷日
              AND   xoha.schedule_arrival_date   < TRUNC( ld_max_ship_arrival_date + 1)-- 最大着荷日
              AND   NVL(xoha.latest_external_flag, cv_no) =  cv_yes           -- 最新フラグ=Y
              AND   xoha.req_status                =  cv_request_status_04    -- 出荷実績計上済
              AND   xoha.request_no               <>  iv_request_no           -- 自分自身の依頼Noは除く
              AND   xottv.transaction_type_id      =  xoha.order_type_id      -- 受注タイプID
              AND   xottv.shipping_shikyu_class    =  cv_shipping_shikyu_class_01 -- 出荷依頼
              AND   xottv.start_date_active       <=  trunc( id_standard_date )
              AND   (( xottv.end_date_active      >=  trunc( id_standard_date ))
                    OR(xottv.end_date_active      IS  NULL ))
              AND   xola.order_header_id           =  xoha.order_header_id    -- 受注ヘッダID
              AND   xola.shipping_item_code       IN                               -- 品目コード
                    -- 親品目と親品目に紐付く子品目(2階層まで)
-- 2016/02/18 D.Sugahara Mod Start 1.38
--                   (SELECT ximv.item_no
                   (SELECT ximv.item_no ximv_item_no
-- 2016/02/18 D.Sugahara Mod End 1.38
                    FROM   xxcmn_item_mst2_v ximv
                    WHERE  ximv.start_date_active <= TRUNC(id_standard_date)
                    AND    ximv.end_date_active   >= TRUNC(id_standard_date)
-- 2009/10/15 H.Itou Mod Start 本番障害#1661
--                    AND    LEVEL                  <= 2                 -- 子階層まで抽出
--                    START WITH ximv.item_no        = lv_parent_item_no -- 親品目から検索
--                    CONNECT BY NOCYCLE PRIOR ximv.item_id = ximv.parent_item_id
                    AND    ximv.parent_item_id     = lv_parent_item_id
-- 2009/10/15 H.Itou Mod End
                    )
              AND   NVL( xola.delete_flag, cv_no ) <>  cv_yes                 -- 削除フラグ'Y'以外
              AND   xmld.mov_line_id               =  xola.order_line_id      -- 受注明細ID
              AND   xmld.document_type_code        =  cv_document_type_10     -- 文書タイプ
              AND   xmld.record_type_code          =  cv_record_type_02       -- レコードタイプ
              AND   ilm.lot_id                     =  xmld.lot_id             -- OPMロットID
              AND   ilm.item_id                    =  xmld.item_id            -- OPM品目ID
              AND   xmld.actual_quantity           >  0 )                     -- 実績数量
              ;
          EXCEPTION
            WHEN OTHERS THEN
              RAISE global_api_others_expt;
        END;
      END IF;
      --
    --
    ELSE
      /**********************************
       *  供給情報取得(移動・在庫)(D-5) *
       **********************************/
      --
      -- 3.移動指示情報の取得
      IF ( iv_lot_biz_class = cv_move_plan ) THEN
        --
        BEGIN
-- 2016/02/18 D.Sugahara Mod Start 1.38
--          SELECT  MAX( fnd_date.string_to_date( ilm.attribute1, gv_yyyymmdd ) )
--                                                                -- 移動指示製造年月日
--          INTO    ld_max_move_manufact_date
          SELECT  MAX( fnd_date.string_to_date( ilm.attribute3, gv_yyyymmdd ) )  ilm_attribute3
                                                                -- 移動指示賞味期限
          INTO    ld_max_move_best_before_date
-- 2016/02/18 D.Sugahara Mod Start 1.38
          FROM    xxinv_mov_req_instr_headers    xmrih,         -- 移動依頼/指示ヘッダ（アドオン）
                  xxinv_mov_req_instr_lines      xmril,         -- 移動依頼/指示明細（アドオン）
                  xxinv_mov_lot_details          xmld,          -- 移動ロット詳細
                  ic_lots_mst                    ilm            -- OPMロットマスタ
          WHERE   xmrih.ship_to_locat_id    =  iv_move_to_id             -- 入庫先ID
            AND   xmrih.comp_actual_flg     =  cv_no                     -- 実績計上済フラグ
            AND   xmrih.status             IN( cv_move_status_03,
                                               cv_move_status_04 )       -- ステータス
            AND   xmrih.mov_num            <>  iv_request_no             -- 自分自身の移動Noは除く
            AND   xmrih.schedule_arrival_date
                                           <=  iv_arrival_date           -- 着日
            AND   xmril.mov_hdr_id          =  xmrih.mov_hdr_id          -- 移動ヘッダID
            AND   xmril.item_code       IN                               -- 品目コード
                  -- 親品目と親品目に紐付く子品目(2階層まで)
-- 2016/02/18 D.Sugahara Mod Start 1.38
--                 (SELECT ximv.item_no
                 (SELECT ximv.item_no  ximv_item_no
-- 2016/02/18 D.Sugahara Mod Start 1.38
                  FROM   xxcmn_item_mst2_v ximv
                  WHERE  ximv.start_date_active <= TRUNC(id_standard_date)
                  AND    ximv.end_date_active   >= TRUNC(id_standard_date)
-- 2009/10/15 H.Itou Mod Start 本番障害#1661
--                  AND    LEVEL                  <= 2                 -- 子階層まで抽出
--                  START WITH ximv.item_no        = lv_parent_item_no -- 親品目から検索
--                  CONNECT BY NOCYCLE PRIOR ximv.item_id = ximv.parent_item_id
                  AND    ximv.parent_item_id     = lv_parent_item_id
-- 2009/10/15 H.Itou Mod End
                  )
            AND   xmril.delete_flg          =  cv_no                           -- 取消フラグ
            AND   xmld.mov_line_id          =  xmril.mov_line_id               -- 移動明細ID
            AND   xmld.document_type_code   =  cv_document_type_20             -- 文書タイプ
            AND   ((( xmrih.status  = cv_move_status_03 )                      -- レコードタイプ
                    AND ( xmld.record_type_code = cv_record_type_01 ))             -- 指示
                  OR(( xmrih.status = cv_move_status_04 )
                    AND ( xmld.record_type_code = cv_record_type_02 )))            -- 出庫実績
            AND   xmld.actual_quantity      >  0                               -- 実績数量
            AND   ilm.lot_id                =  xmld.lot_id                     -- OPMロットID
            AND   ilm.item_id               =  xmld.item_id                    -- OPM品目ID
            ;
        EXCEPTION
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
      END IF;
      --
      --
      -- 4. 手持数量情報の取得
      BEGIN
-- 2016/02/18 D.Sugahara Mod Start 1.38
--        SELECT  MAX( fnd_date.string_to_date( ilm.attribute1, gv_yyyymmdd ) )
--        INTO    ld_max_onhand_manufact_date
        SELECT  MAX( fnd_date.string_to_date( ilm.attribute3, gv_yyyymmdd ) ) ilm_attribute3
        INTO    ld_max_onhand_best_before_date
-- 2016/02/18 D.Sugahara Mod Start 1.38
        FROM    ic_loct_inv              ili,                      -- OPM手持数量
                ic_lots_mst              ilm,                      -- OPMロットマスタ
                xxcmn_item_mst2_v        ximv,                     -- OPM品目情報VIEW2
                xxcmn_item_locations_v   xilv                      -- OPM保管場所情報VIEW
        WHERE   ximv.item_no       IN                               -- 品目コード
                -- 親品目と親品目に紐付く子品目(2階層まで)
-- 2016/02/18 D.Sugahara Mod Start 1.38
--               (SELECT ximv1.item_no
               (SELECT ximv1.item_no  ximv1_item_no
-- 2016/02/18 D.Sugahara Mod End 1.38
                FROM   xxcmn_item_mst2_v ximv1
                WHERE  ximv1.start_date_active <= TRUNC(id_standard_date)
                AND    ximv1.end_date_active   >= TRUNC(id_standard_date)
-- 2009/10/15 H.Itou Mod Start 本番障害#1661
--                AND    LEVEL                  <= 2                 -- 子階層まで抽出
--                START WITH ximv.item_no        = lv_parent_item_no -- 親品目から検索
--                CONNECT BY NOCYCLE PRIOR ximv.item_id = ximv.parent_item_id
                AND    ximv1.parent_item_id     = lv_parent_item_id
-- 2009/10/15 H.Itou Mod End
                )
          AND   ximv.start_date_active    <= TRUNC(id_standard_date)
          AND   ximv.end_date_active      >= TRUNC(id_standard_date)
          AND   xilv.inventory_location_id = iv_move_to_id         -- 入庫先ID
          AND   ili.item_id                =  ximv.item_id         -- OPM品目ID
          AND   ili.location               =  xilv.segment1        -- 保管倉庫コード
          AND   ilm.lot_id                 =  ili.lot_id           -- ロットID
          AND   ilm.item_id                =  ili.item_id          -- OPM品目ID
          ;
      EXCEPTION
        WHEN  OTHERS THEN
          RAISE global_api_others_expt;
      END;
      --
      --
      -- 5. 移動実績情報の取得
      BEGIN
-- 2016/02/18 D.Sugahara Mod Start 1.38
--        SELECT  MAX( fnd_date.string_to_date( ilm.attribute1, gv_yyyymmdd ) )
--        INTO    ld_max_rmove_manufact_date
        SELECT  MAX( fnd_date.string_to_date( ilm.attribute3, gv_yyyymmdd ) )  ilm_attribute3
        INTO    ld_max_rmove_best_before_date
-- 2016/02/18 D.Sugahara Mod End 1.38
        FROM    xxinv_mov_req_instr_headers    xmrih,         -- 移動依頼/指示ヘッダ（アドオン）
                xxinv_mov_req_instr_lines      xmril,         -- 移動依頼/指示明細（アドオン）
                xxinv_mov_lot_details          xmld,          -- 移動ロット詳細
                ic_lots_mst                    ilm            -- OPMロットマスタ
        WHERE   xmrih.ship_to_locat_id    =  iv_move_to_id
          AND   xmrih.comp_actual_flg     =  cv_no                     -- 実績計上済フラグ
          AND   xmrih.status             IN( cv_move_status_05,
                                             cv_move_status_06 )       -- ステータス
          AND   xmrih.mov_num            <>  iv_request_no             -- 自分自身の移動Noは除く
          AND   xmril.mov_hdr_id          =  xmrih.mov_hdr_id          -- 移動ヘッダID
          AND   xmril.item_code       IN                               -- 品目コード
                -- 親品目と親品目に紐付く子品目(2階層まで)
-- 2016/02/18 D.Sugahara Mod Start 1.38
               (SELECT ximv.item_no ximv_item_no 
-- 2016/02/18 D.Sugahara Mod End 1.38
                FROM   xxcmn_item_mst2_v ximv
                WHERE  ximv.start_date_active <= TRUNC(id_standard_date)
                AND    ximv.end_date_active   >= TRUNC(id_standard_date)
-- 2009/10/15 H.Itou Mod Start 本番障害#1661
--                AND    LEVEL                  <= 2                 -- 子階層まで抽出
--                START WITH ximv.item_no        = lv_parent_item_no -- 親品目から検索
--                CONNECT BY NOCYCLE PRIOR ximv.item_id = ximv.parent_item_id
                AND    ximv.parent_item_id     = lv_parent_item_id
-- 2009/10/15 H.Itou Mod End
                )
          AND   xmril.delete_flg          =  cv_no                            -- 取消フラグ
          AND   xmld.mov_line_id          =  xmril.mov_line_id                -- 移動明細ID
          AND   xmld.document_type_code   =  cv_document_type_20              -- 文書タイプ
          AND   xmld.record_type_code     =  cv_record_type_03                -- レコードタイプ
          AND   xmld.actual_quantity      >  0                                -- 実績数量
          AND   ilm.lot_id                =  xmld.lot_id                      -- OPMロットID
          AND   ilm.item_id               =  xmld.item_id                     -- OPM品目ID
          ;
      EXCEPTION
        WHEN  NO_DATA_FOUND THEN
          -- データなしは除外
          NULL;
          --
        WHEN  OTHERS THEN
          RAISE global_api_others_expt;
      END;
      --
    END IF;
    --
    /**********************************
     *  ロット逆転判定処理(D-6)       *
     **********************************/
    -- ロット逆転対象の日付を算出
    CASE iv_lot_biz_class
      -- ロット逆転処理種別が「1」の場合
      WHEN ( cv_ship_plan  ) THEN
-- 2016/02/18 D.Sugahara Mod Start 1.38
--        -- 「出荷指示製造年月日」「出荷実績製造年月日」のうち最大
--        ld_check_manufact_date
--                 := GREATEST( NVL(ld_max_ship_manufact_date,  cv_mindate),
--                              NVL(ld_max_rship_manufact_date, cv_mindate) );
        -- 「出荷指示賞味期限」「出荷実績賞味期限」のうち最大
        ld_check_best_before_date
                 := GREATEST( NVL(ld_max_ship_best_before_date,  cv_mindate),
                              NVL(ld_max_rship_best_before_date, cv_mindate) );
-- 2016/02/18 D.Sugahara Mod End 1.38
        --
        --
      -- ロット逆転処理種別が「2」の場合
      WHEN ( cv_ship_result ) THEN
-- 2016/02/18 D.Sugahara Mod Start 1.38
--        ld_check_manufact_date := ld_max_rship_manufact_date;
        ld_check_best_before_date := ld_max_rship_best_before_date;
-- 2016/02/18 D.Sugahara Mod End 1.38
        --
        --
      -- ロット逆転処理種別が「5」の場合
      WHEN ( cv_move_plan   ) THEN
-- 2016/02/18 D.Sugahara Mod Start 1.38
--        -- 「移動指示製造年月日」「移動実績製造年月日」「手持製造年月日」のうち最大
--        ld_check_manufact_date
--                 := GREATEST( NVL(ld_max_move_manufact_date,   cv_mindate),
--                              NVL(ld_max_rmove_manufact_date,  cv_mindate),
--                              NVL(ld_max_onhand_manufact_date, cv_mindate) );
        -- 「移動指示賞味期限」「移動実績賞味期限」「手持賞味期限」のうち最大
        ld_check_best_before_date
                 := GREATEST( NVL(ld_max_move_best_before_date,   cv_mindate),
                              NVL(ld_max_rmove_best_before_date,  cv_mindate),
                              NVL(ld_max_onhand_best_before_date, cv_mindate) );
-- 2016/02/18 D.Sugahara Mod End 1.38
        --
        --
      -- ロット逆転処理種別が「6」の場合
      WHEN ( cv_move_result ) THEN
-- 2016/02/18 D.Sugahara Mod Start 1.38
--        -- 移動実績製造年月日」「手持製造年月日」のうち最大
--        ld_check_manufact_date
--                 := GREATEST( NVL(ld_max_rmove_manufact_date  ,cv_mindate),
--                              NVL(ld_max_onhand_manufact_date ,cv_mindate) );
        -- 移動実績賞味期限」「手持賞味期限」のうち最大
        ld_check_best_before_date
                 := GREATEST( NVL(ld_max_rmove_best_before_date  ,cv_mindate),
                              NVL(ld_max_onhand_best_before_date ,cv_mindate) );
-- 2016/02/18 D.Sugahara Mod End 1.38
    END CASE;
    --
-- 2016/02/18 D.Sugahara Mod Start 1.38
--    -- 「チェック日付」＞ 「最大製造年月日」ならば、ロット逆転
--    IF ( ( ld_check_manufact_date <= ld_max_manufact_date )
--      OR ( ld_check_manufact_date IS NULL                ) ) THEN
    -- 「チェック日付」＞ 「最大賞味期限」ならば、ロット逆転
    IF ( ( ld_check_best_before_date <= ld_max_best_before_date )
      OR ( ld_check_best_before_date IS NULL                ) ) THEN
-- 2016/02/18 D.Sugahara Mod End 1.38
      on_result         :=  ln_result_success;                     -- 処理結果
      on_reversal_date  :=  NULL;                                  -- 逆転日付
    ELSE
      on_result         :=  ln_result_error;                       -- 処理結果
-- 2016/02/18 D.Sugahara Mod Start 1.38
--      on_reversal_date  :=  ld_check_manufact_date;                -- 逆転日付
      on_reversal_date  :=  ld_check_best_before_date;                -- 逆転日付
-- 2016/02/18 D.Sugahara Mod End 1.38
    END IF;
      --
    /**********************************
     *  OUTパラメータセット(D-7)      *
     **********************************/
    --
    ov_retcode                  := gv_status_normal;   -- リターンコード
    ov_errmsg_code              := NULL;               -- エラーメッセージコード
    ov_errmsg                   := NULL;               -- エラーメッセージ
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg      := lv_errmsg;
      ov_errmsg_code := lv_err_cd;
      ov_retcode     := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg      := SQLERRM;
      ov_errmsg_code := SQLCODE;
      ov_retcode     := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg      := SQLERRM;
      ov_errmsg_code := SQLCODE;
      ov_retcode     := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END check_lot_reversal2;
--
-- 2009/01/22 H.Itou Add End
  /**********************************************************************************
   * Procedure Name   : check_fresh_condition
   * Description      : 鮮度条件チェック
   ***********************************************************************************/
  PROCEDURE check_fresh_condition(
    iv_move_to_id                 IN  NUMBER,                         -- 1.配送先ID
    iv_lot_id                     IN  ic_lots_mst.lot_id%TYPE,        -- 2.ロットId
    iv_arrival_date               IN  DATE,                           -- 3.着荷予定日
    id_standard_date              IN  DATE  DEFAULT SYSDATE,          -- 4.基準日(適用日基準日)
    ov_retcode                    OUT NOCOPY VARCHAR2,                -- 5.リターンコード
    ov_errmsg_code                OUT NOCOPY VARCHAR2,                -- 6.エラーメッセージコード
    ov_errmsg                     OUT NOCOPY VARCHAR2,                -- 7.エラーメッセージ
    on_result                     OUT NOCOPY NUMBER,                  -- 8.処理結果
    od_standard_date              OUT NOCOPY DATE                     -- 9.基準日付
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_fresh_condition'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- メッセージID
    cv_xxwsh_in_pram_set_err       CONSTANT VARCHAR2(100) := 'APP-XXWSH-12701'; -- 必須入力パラメータ未設定エラーメッセージ
    cv_xxwsh_lot_info_err          CONSTANT VARCHAR2(100) := 'APP-XXWSH-12702'; -- ロット情報なしエラーメッセージ
    cv_xxwsh_in_pram_base_val_err  CONSTANT VARCHAR2(100) := 'APP-XXWSH-12703'; -- 基準値ゼロエラーメッセージ
    cv_xxwsh_not_fresh_condition   CONSTANT VARCHAR2(100) := 'APP-XXWSH-12704'; -- 鮮度条件取得エラーメッセージ
    cv_xxwsh_fresh_condition_err   CONSTANT VARCHAR2(100) := 'APP-XXWSH-12705'; -- 鮮度条件不正エラーメッセージ
    cv_xxwsh_not_best_before_date  CONSTANT VARCHAR2(100) := 'APP-XXWSH-12706'; -- 賞味期限なしエラーメッセージ
    cv_xxwsh_not_manufact_date     CONSTANT VARCHAR2(100) := 'APP-XXWSH-12707'; -- 製造年月日なしエラーメッセージ
    cv_xxwsh_date_style_err        CONSTANT VARCHAR2(100) := 'APP-XXWSH-12708'; -- 日付書式エラーメッセージ
    -- トークン
    cv_tkn_in_parm                 CONSTANT VARCHAR2(30)  := 'in_param';
    cv_tkn_deliver_to_id           CONSTANT VARCHAR2(30)  := 'deliver_to_id';
    cv_tkn_lot_no                  CONSTANT VARCHAR2(30)  := 'lot_no';
    cv_tkn_lot_id                  CONSTANT VARCHAR2(30)  := 'lot_id';
    cv_flesh_code                  CONSTANT VARCHAR2(30)  := 'fresh_code';
    cv_style_name                  CONSTANT VARCHAR2(30)  := 'style_name';
    -- トークンセット値
    cv_move_to_id_char             CONSTANT VARCHAR2(30)  := '配送先ID';
    cv_lot_no_char                 CONSTANT VARCHAR2(30)  := 'ロットNo';
    cv_lot_id_char                 CONSTANT VARCHAR2(30)  := 'ロットId';
    cv_arrival_date_char           CONSTANT VARCHAR2(30)  := '着荷予定日';
    cv_freshness_class0_char       CONSTANT VARCHAR2(30)  := '一般';
    cv_freshness_class1_char       CONSTANT VARCHAR2(30)  := '賞味期限基準';
    cv_freshness_class2_char       CONSTANT VARCHAR2(30)  := '製造日基準';
    cv_manufact_date_char          CONSTANT VARCHAR2(30)  := '製造年月日';
    cv_limit_exp_date_char         CONSTANT VARCHAR2(30)  := '賞味期限';
    --
    -- クイックコードタイプ「鮮度条件」
    cv_lookup_fressness_condition  CONSTANT VARCHAR2(30)  := 'XXCMN_FRESHNESS_CONDITION';
    -- 鮮度条件区分
    lv_freshness_class0            CONSTANT VARCHAR2(1)   :=  '0';   -- 一般
    lv_freshness_class1            CONSTANT VARCHAR2(1)   :=  '1';   -- 賞味期限基準
    lv_freshness_class2            CONSTANT VARCHAR2(1)   :=  '2';   -- 製造日基準
    --
    -- 処理結果定数
    ln_result_success              CONSTANT NUMBER        := 0;      -- 0 (正常)
    ln_result_error                CONSTANT NUMBER        := 1;      -- 1 (異常)
--
    -- *** ローカル変数 ***
    -- エラー変数
    lv_err_cd                      VARCHAR2(30);
    -- 鮮度条件
    lv_freshness_class             VARCHAR2(2);                      -- 鮮度条件区分
    ln_freshness_base_value        NUMBER;                           -- 鮮度条件基準値
    ln_freshness_adjust_value      NUMBER;                           -- 鮮度条件調整値
    -- 賞味期間
    ld_manufact_date               DATE;                             -- 製造年月日
    ld_limit_expiration_date       DATE;                             -- 賞味期限
    ln_expiration_days             NUMBER;                           -- 賞味期間
    -- 賞味期間(一時格納用)
    lv_manufact_date_str           VARCHAR2(150);                    -- 製造年月日
    lv_limit_exp_date_str          VARCHAR2(150);                    -- 賞味期限
    --
    ln_base_days                   NUMBER;                           -- 基準期間(日)
    ld_freshness_base_date         DATE;                             -- 鮮度条件基準日
    lv_lot_no                      ic_lots_mst.lot_no%TYPE;          -- ロットNo
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    expiration_days_zero_expt      EXCEPTION;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    --
    /********************************************
     *  パラメータチェック(E-1)                 *
     ********************************************/
    -- 必須入力パラメータをチェックします
    -- 配送先ID
    IF   ( iv_move_to_id IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_in_pram_set_err,
                                            cv_tkn_in_parm,
                                            cv_move_to_id_char);
      lv_err_cd := cv_xxwsh_in_pram_set_err;
      RAISE global_api_expt;
    -- ロットId
    ELSIF( iv_lot_id         IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_in_pram_set_err,
                                            cv_tkn_in_parm,
                                            cv_lot_id_char);
      lv_err_cd := cv_xxwsh_in_pram_set_err;
      RAISE global_api_expt;
    -- 着荷予定日
    ELSIF( iv_arrival_date   IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_in_pram_set_err,
                                            cv_tkn_in_parm,
                                            cv_arrival_date_char);
      lv_err_cd := cv_xxwsh_in_pram_set_err;
      RAISE global_api_expt;
    END IF;
    --
    --
    /********************************************
     *  鮮度条件取得(E-2)                       *
     ********************************************/
    -- 鮮度条件および鮮度条件付随情報の取得
    BEGIN
      SELECT xlv.attribute1,
             TO_NUMBER( xlv.attribute2 ),
             TO_NUMBER( xlv.attribute3 )
      INTO   lv_freshness_class,
             ln_freshness_base_value,
             ln_freshness_adjust_value
      FROM   xxcmn_cust_acct_sites2_v  xcasv,              -- 顧客サイト情報VIEW2
             xxcmn_lookup_values2_v    xlv                 -- クイックコード情報VIEW2
      WHERE  xcasv.party_site_id       =  iv_move_to_id                 -- 配送先ID(パーティサイトID)
        AND  xcasv.start_date_active  <=  trunc( id_standard_date )
        AND  xcasv.end_date_active    >=  trunc( id_standard_date )
        AND  xlv.lookup_type           =  cv_lookup_fressness_condition
        AND  xlv.lookup_code           =  xcasv.freshness_condition
        AND  (( xlv.start_date_active  <=  trunc( id_standard_date ))
          OR  ( xlv.start_date_active  IS NULL  ))
        AND  (( xlv.end_date_active    >=  trunc( id_standard_date ))
          OR  ( xlv.end_date_active    IS NULL  ));
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                              cv_xxwsh_not_fresh_condition,
                                              cv_tkn_deliver_to_id,
                                              iv_move_to_id);
        lv_err_cd := cv_xxwsh_not_fresh_condition;
        RAISE global_api_expt;
      WHEN OTHERS        THEN
        RAISE global_api_expt;
    END;
    -- 鮮度条件区分が規定値以外またはNULLの場合
    IF ( lv_freshness_class NOT IN( lv_freshness_class0,
                                    lv_freshness_class1,
                                    lv_freshness_class2  ) OR
         lv_freshness_class IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_fresh_condition_err,
                                            cv_tkn_deliver_to_id,
                                            iv_move_to_id);
      lv_err_cd := cv_xxwsh_fresh_condition_err;
      RAISE global_api_expt;
    END IF;
    --
    -- 賞味期限基準かつ基準値が0またはNULL
    IF ( lv_freshness_class = lv_freshness_class1 ) THEN
      IF (( ln_freshness_base_value  = 0    )
        OR( ln_freshness_base_value IS NULL )) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                              cv_xxwsh_in_pram_base_val_err);
        lv_err_cd := cv_xxwsh_in_pram_base_val_err;
        RAISE global_api_others_expt;
      END IF;
    END IF;
    --
    /********************************************
     *  製造年月日、賞味期限取得 (E-3)          *
     ********************************************/
    -- 「ロットNo」に紐づく品目の賞味期間を取得
    BEGIN
      SELECT ilm.lot_no,                                           -- ロットNo
             ilm.attribute1,                                       -- 製造年月日
             ilm.attribute3,                                       -- 賞味期限
             ximv.expiration_day                                   -- 賞味期間
      INTO   lv_lot_no,
             lv_manufact_date_str,
             lv_limit_exp_date_str,
             ln_expiration_days
      FROM   ic_lots_mst       ilm,                                -- OPMロットマスタ
             xxcmn_item_mst2_v ximv                                -- OPM品目情報VIEW2
      WHERE  ilm.lot_id               =  iv_lot_id                 -- ロットId
        AND  ximv.item_id             =  ilm.item_id               -- 品目ID
        AND  ximv.start_date_active  <=  trunc( id_standard_date )
        AND  ximv.end_date_active    >=  trunc( id_standard_date );
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                              cv_xxwsh_lot_info_err,
                                              cv_tkn_lot_id,
                                              iv_lot_id);
        lv_err_cd := cv_xxwsh_lot_info_err;
        RAISE global_api_expt;
      WHEN OTHERS        THEN
        RAISE global_api_others_expt;
    END;
    --
    -- 文字型から日付型へ
    ld_manufact_date
             := fnd_date.string_to_date( lv_manufact_date_str,  gv_yyyymmdd ); -- 製造年月日
    ld_limit_expiration_date
             := fnd_date.string_to_date( lv_limit_exp_date_str, gv_yyyymmdd ); -- 賞味期限
    -- 書式エラー
    IF   (( ld_manufact_date         IS NULL     )
      AND ( lv_manufact_date_str     IS NOT NULL )) THEN
      --
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_date_style_err,
                                            cv_style_name,
                                            cv_manufact_date_char,
                                            cv_tkn_lot_no,
                                            lv_lot_no);
      lv_err_cd := cv_xxwsh_date_style_err;
      RAISE global_api_expt;
      --
    ELSIF(( ld_limit_expiration_date IS NULL     )
      AND ( lv_limit_exp_date_str    IS NOT NULL )) THEN
      --
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_date_style_err,
                                            cv_style_name,
                                            cv_limit_exp_date_char,
                                            cv_tkn_lot_no,
                                            lv_lot_no);
      lv_err_cd := cv_xxwsh_date_style_err;
      RAISE global_api_expt;
      --
    END IF;
    --
-- 2008/10/15 H.Itou Mod Start 統合テスト指摘379
--    -- 賞味期間＝ゼロの場合
--    IF ( ln_expiration_days = 0 ) THEN
    -- 賞味期間＝ゼロまたは、製造年月日と賞味期限が同じ場合
    IF (( ln_expiration_days = 0 )
    OR  ( ld_manufact_date   = ld_limit_expiration_date)) THEN
-- 2008/10/15 H.Itou Mod End
      RAISE expiration_days_zero_expt;
    END IF;
    --
    -- NULLチェック
    --「鮮度条件区分」が「1(賞味期限基準)」
    IF ( lv_freshness_class = lv_freshness_class1 ) THEN
      --
      -- 「賞味期限」がNULL
      IF ( lv_limit_exp_date_str  IS NULL ) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                              cv_xxwsh_not_best_before_date,
                                              cv_flesh_code,
                                              cv_freshness_class1_char,
                                              cv_tkn_lot_no,
                                              lv_lot_no);
        lv_err_cd := cv_xxwsh_not_best_before_date;
        RAISE global_api_expt;
      --
      -- 「製造日」がNULL
      ELSIF ( lv_manufact_date_str IS NULL ) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                              cv_xxwsh_not_manufact_date,
                                              cv_flesh_code,
                                              cv_freshness_class1_char,
                                              cv_tkn_lot_no,
                                              lv_lot_no);
        lv_err_cd := cv_xxwsh_not_manufact_date;
        RAISE global_api_expt;
      --
      END IF;
    --
    --「鮮度条件区分」が「2(製造日基準)」
    ELSIF ( lv_freshness_class = lv_freshness_class2 ) THEN
      -- 「製造日」がNULL
      IF (lv_manufact_date_str IS NULL ) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                              cv_xxwsh_not_manufact_date,
                                              cv_flesh_code,
                                              cv_freshness_class2_char,
                                              cv_tkn_lot_no,
                                              lv_lot_no);
        lv_err_cd := cv_xxwsh_not_fresh_condition;
        RAISE global_api_expt;
      END IF;
    --
    --「鮮度条件区分」が「0(一般)」
    ELSE
      -- 「賞味期限」がNULL
      IF ( lv_limit_exp_date_str  IS NULL ) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                              cv_xxwsh_not_best_before_date,
                                              cv_flesh_code,
                                              cv_freshness_class0_char,
                                              cv_tkn_lot_no,
                                              lv_lot_no);
        lv_err_cd := cv_xxwsh_not_best_before_date;
        RAISE global_api_expt;
      END IF;
      --
    END IF;
    --
    --
    /********************************************
     *  鮮度条件基準日の算出                    *
     ********************************************/
    -- 鮮度条件区分により処理を振り分けます
    --
    CASE lv_freshness_class
      /********************************************
       *  鮮度条件基準日の算出(賞味期限基準)(E-4) *
       ********************************************/
      WHEN lv_freshness_class1 THEN
        ln_base_days
            := TRUNC( ( ld_limit_expiration_date - ld_manufact_date ) / ln_freshness_base_value );
        ld_freshness_base_date
            := ld_manufact_date + ln_base_days + NVL( ln_freshness_adjust_value, 0);
      --
      /********************************************
       *  鮮度条件基準日の算出(製造日基準)(E-5)   *
       ********************************************/
      WHEN lv_freshness_class2 THEN
        ld_freshness_base_date
            := ld_manufact_date
             + NVL( ln_freshness_base_value  , 0 )
             + NVL( ln_freshness_adjust_value, 0 );
      --
      /********************************************
       *  鮮度条件基準日の算出(一般)(E-6)         *
       ********************************************/
      ELSE
        ld_freshness_base_date
            := ld_limit_expiration_date
             + NVL( ln_freshness_base_value  , 0 )
             + NVL( ln_freshness_adjust_value, 0 );
      --
    END CASE;
    --
    /********************************************
     *  OUTパラメータセット(E-7)                *
     ********************************************/
    --  「鮮度条件基準日」＜入力パラメータ「着荷予定日」：鮮度条件エラー
    IF ( ld_freshness_base_date >= iv_arrival_date ) THEN
      on_result           :=  ln_result_success;                    -- 処理結果
      od_standard_date    :=  NULL;                                 -- 基準日付
    ELSE
      on_result           :=  ln_result_error;                      -- 処理結果
      od_standard_date    :=  ld_freshness_base_date;               -- 基準日付
    END IF;
    --
     ov_retcode      := gv_status_normal;   -- リターンコード
     ov_errmsg_code  := NULL;               -- エラーメッセージコード
     ov_errmsg       := NULL;               -- エラーメッセージ
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    --
    WHEN expiration_days_zero_expt THEN
     on_result          :=  ln_result_success;  -- 処理結果
     od_standard_date   :=  NULL;               -- 基準日付
     ov_retcode         :=  gv_status_normal;   -- リターンコード
     ov_errmsg_code     :=  NULL;               -- エラーメッセージコード
     ov_errmsg          :=  NULL;               -- エラーメッセージ
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg      := lv_errmsg;
      ov_errmsg_code := lv_err_cd;
      ov_retcode     := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg      := SQLERRM;
      ov_errmsg_code := SQLCODE;
      ov_retcode     := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg      := SQLERRM;
      ov_errmsg_code := SQLCODE;
      ov_retcode     := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END check_fresh_condition;
--
-- 2009/01/23 H.Itou Add Start 本番#936対応
  /**********************************************************************************
   * Procedure Name   : get_fresh_pass_date
   * Description      : 鮮度条件合格製造日取得
   ***********************************************************************************/
  PROCEDURE get_fresh_pass_date(
    it_move_to_id                 IN  NUMBER                         -- 1.配送先
   ,it_item_no                    IN  xxcmn_item_mst_v.item_no%TYPE  -- 2.品目コード
   ,id_arrival_date               IN  DATE                           -- 3.着荷予定日
   ,id_standard_date              IN  DATE   DEFAULT SYSDATE         -- 4.基準日(適用日基準日)
   ,od_manufacture_date           OUT NOCOPY DATE                    -- 5.鮮度条件合格製造日
   ,ov_retcode                    OUT NOCOPY VARCHAR2                -- 6.リターンコード
   ,ov_errmsg                     OUT NOCOPY VARCHAR2                -- 8.エラーメッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_fresh_pass_date'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- メッセージID
    cv_xxwsh_in_pram_set_err       CONSTANT VARCHAR2(100) := 'APP-XXWSH-12701'; -- 必須入力パラメータ未設定エラーメッセージ
    cv_xxwsh_in_pram_base_val_err  CONSTANT VARCHAR2(100) := 'APP-XXWSH-12703'; -- 基準値ゼロエラーメッセージ
    cv_xxwsh_not_fresh_condition   CONSTANT VARCHAR2(100) := 'APP-XXWSH-12704'; -- 鮮度条件取得エラーメッセージ
    cv_xxwsh_fresh_condition_err   CONSTANT VARCHAR2(100) := 'APP-XXWSH-12705'; -- 鮮度条件不正エラーメッセージ
    cv_xxwsh_item_info_err         CONSTANT VARCHAR2(100) := 'APP-XXWSH-12709'; -- 品目情報なしエラーメッセージ
    -- トークン
    cv_tkn_in_parm                 CONSTANT VARCHAR2(30)  := 'IN_PARAM';
    cv_tkn_deliver_to_id           CONSTANT VARCHAR2(30)  := 'DELIVER_TO_ID';
    cv_tkn_item_no                 CONSTANT VARCHAR2(30)  := 'ITEM_NO';
    -- トークンセット値
    cv_move_to_id_char             CONSTANT VARCHAR2(30)  := '配送先ID';
    cv_item_no_char                CONSTANT VARCHAR2(30)  := '品目コード';
    cv_arrival_date_char           CONSTANT VARCHAR2(30)  := '着荷予定日';
    --
    -- クイックコードタイプ「鮮度条件」
    cv_lookup_fressness_condition  CONSTANT VARCHAR2(30)  := 'XXCMN_FRESHNESS_CONDITION';
    -- 鮮度条件区分
    cv_freshness_class0            CONSTANT VARCHAR2(1)   :=  '0';   -- 一般
    cv_freshness_class1            CONSTANT VARCHAR2(1)   :=  '1';   -- 賞味期限基準
    cv_freshness_class2            CONSTANT VARCHAR2(1)   :=  '2';   -- 製造日基準
--
    -- 戻り値
    cv_status_normal               CONSTANT VARCHAR2(1)   := '0'; -- 正常
    cv_status_warn                 CONSTANT VARCHAR2(1)   := '1'; -- 賞味期間0なので日付なし
    cv_status_error                CONSTANT VARCHAR2(1)   := '2'; -- 異常
--
    -- *** ローカル変数 ***
    -- 鮮度条件
    lv_freshness_class             VARCHAR2(2);                      -- 鮮度条件区分
    ln_freshness_base_value        NUMBER;                           -- 鮮度条件基準値
    ln_freshness_adjust_value      NUMBER;                           -- 鮮度条件調整値
    -- 賞味期間
    ld_manufact_date               DATE;                             -- 製造年月日
    ld_expiration_date             DATE;                             -- 賞味期限
    ln_expiration_days             NUMBER;                           -- 賞味期間
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    expiration_days_zero_expt      EXCEPTION; -- 賞味期間0
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    /********************************************
     *  パラメータチェック(E-1)                 *
     ********************************************/
    -- 必須入力パラメータをチェックします
    -- 配送先ID
    IF   ( it_move_to_id IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh
                                           ,cv_xxwsh_in_pram_set_err
                                           ,cv_tkn_in_parm
                                           ,cv_move_to_id_char);
      RAISE global_api_expt;
--
    -- 品目コード
    ELSIF( it_item_no   IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh
                                           ,cv_xxwsh_in_pram_set_err
                                           ,cv_tkn_in_parm
                                           ,cv_item_no_char);
      RAISE global_api_expt;
--
    -- 着荷予定日
    ELSIF( id_arrival_date   IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh
                                           ,cv_xxwsh_in_pram_set_err
                                           ,cv_tkn_in_parm
                                           ,cv_arrival_date_char);
      RAISE global_api_expt;
    END IF;
--
    /********************************************
     *  鮮度条件取得(E-2)                       *
     ********************************************/
    -- 鮮度条件および鮮度条件付随情報の取得
    BEGIN
      SELECT xlv.attribute1                        freshness_class
            ,NVL( TO_NUMBER( xlv.attribute2 ), 0 ) freshness_base_value
            ,NVL( TO_NUMBER( xlv.attribute3 ), 0 ) freshness_adjust_value
      INTO   lv_freshness_class                                  -- 鮮度条件区分
            ,ln_freshness_base_value                             -- 鮮度条件基準値
            ,ln_freshness_adjust_value                           -- 鮮度条件調整値
      FROM   xxcmn_cust_acct_sites2_v    xcasv                   -- 顧客サイト情報VIEW2
            ,xxcmn_lookup_values2_v      xlv                     -- クイックコード情報VIEW2(鮮度条件)
      WHERE  xlv.lookup_code           = xcasv.freshness_condition
      AND    xcasv.party_site_id       = it_move_to_id           -- 配送先ID(パーティサイトID)
      AND    xcasv.start_date_active  <= TRUNC( id_standard_date )
      AND    xcasv.end_date_active    >= TRUNC( id_standard_date )
      AND    xlv.lookup_type           = cv_lookup_fressness_condition
      AND ( (xlv.start_date_active    <= TRUNC( id_standard_date ) )
        OR  (xlv.start_date_active    IS NULL  ) )
      AND ( (xlv.end_date_active      >= TRUNC( id_standard_date ) )
        OR  (xlv.end_date_active      IS NULL  ) );
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh
                                             ,cv_xxwsh_not_fresh_condition
                                             ,cv_tkn_deliver_to_id
                                             ,it_move_to_id);
        RAISE global_api_expt;
    END;
--
    -- 鮮度条件区分が規定値以外またはNULLの場合
    IF ( ( lv_freshness_class NOT IN ( cv_freshness_class0, cv_freshness_class1, cv_freshness_class2 ) ) 
      OR ( lv_freshness_class IS NULL ) ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh
                                           ,cv_xxwsh_fresh_condition_err
                                           ,cv_tkn_deliver_to_id
                                           ,it_move_to_id);
      RAISE global_api_expt;
    END IF;
--
    -- 鮮度条件区分が1:賞味期限基準で、鮮度条件基準値が0またはNULL
    IF  ( ( lv_freshness_class = cv_freshness_class1 ) 
      AND ( ln_freshness_base_value = 0 ) )THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh
                                           ,cv_xxwsh_in_pram_base_val_err);
      RAISE global_api_expt;
    END IF;
--
    /********************************************
     *  賞味期間取得 (E-3)                      *
     ********************************************/
    -- 「品目コード」に紐づく品目の賞味期間を取得
    BEGIN
      SELECT ximv.expiration_day expiration_day   -- 賞味期間
      INTO   ln_expiration_days                   -- 賞味期間
      FROM   xxcmn_item_mst2_v ximv               -- OPM品目情報VIEW2
      WHERE  ximv.item_no            = it_item_no -- 品目コード
      AND    ximv.start_date_active <= TRUNC( id_standard_date )
      AND    ximv.end_date_active   >= TRUNC( id_standard_date );
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh
                                             ,cv_xxwsh_item_info_err
                                             ,cv_tkn_item_no
                                             ,it_item_no);
        RAISE global_api_expt;
    END;
--
    -- 賞味期間がNULLの場合
    IF  ( ( lv_freshness_class IN ( cv_freshness_class1, cv_freshness_class0 ) )
      AND ( ln_expiration_days IS NULL ) ) THEN
      lv_errmsg := '賞味期間に値がありません。';
      RAISE global_api_expt;
--
    -- 賞味期間が0の場合
    ELSIF ( ln_expiration_days = 0 ) THEN
      -- 賞味期間0終了
      RAISE expiration_days_zero_expt;
    END IF;
    --
    /**************************************
     *  製造日の算出(1:賞味期限基準)(E-4) *
     **************************************/
    IF   ( lv_freshness_class = cv_freshness_class1 ) THEN
      -- 製造日 = 着荷予定日 - (賞味期間 / 鮮度条件基準値) - 鮮度条件調整値
      ld_manufact_date := id_arrival_date - TRUNC( ln_expiration_days / ln_freshness_base_value ) - ln_freshness_adjust_value;
--
    /**************************************
     *  製造日の算出(2:製造日基準)(E-5)   *
     **************************************/
    ELSIF( lv_freshness_class = cv_freshness_class2 ) THEN
      -- 製造日 = 着荷予定日 - 鮮度条件基準値 - 鮮度条件調整値
      ld_manufact_date := id_arrival_date - ln_freshness_base_value - ln_freshness_adjust_value;
--
    /**************************************
     *  製造日の算出(0:一般)(E-6)         *
     **************************************/
    ELSE
      -- 賞味期限 = 着荷予定日 - 鮮度条件基準値 - 鮮度条件調整値
      ld_expiration_date := id_arrival_date - ln_freshness_base_value - ln_freshness_adjust_value;
      -- 製造日   = 賞味期限 - 賞味期間
      ld_manufact_date   := ld_expiration_date - ln_expiration_days;
      --
    END IF;
    --
    /********************************************
     *  OUTパラメータセット(E-7)                *
     ********************************************/
     od_manufacture_date := ld_manufact_date; -- 鮮度条件合格製造日
     ov_retcode          := cv_status_normal; -- リターンコード
     ov_errmsg           := NULL;             -- エラーメッセージ
--
  EXCEPTION
    -- *** 賞味期間0終了 ***
    WHEN expiration_days_zero_expt THEN
      od_manufacture_date := NULL;             -- 鮮度条件合格製造日
      ov_retcode          := cv_status_warn;   -- リターンコード
      ov_errmsg           := NULL;             -- エラーメッセージ
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_retcode     := cv_status_error; -- リターンコード
      ov_errmsg      := lv_errmsg;       -- エラーメッセージ
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_retcode     := cv_status_error; -- リターンコード
      ov_errmsg      := SQLERRM;         -- エラーメッセージ
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_retcode     := cv_status_error; -- リターンコード
      ov_errmsg      := SQLERRM;         -- エラーメッセージ
--
--#####################################  固定部 END   ##########################################
--
  END get_fresh_pass_date;
-- 2009/01/23 H.Itou Add End
  /**********************************************************************************
   * Procedure Name   : calc_lead_time
   * Description      : リードタイム算出
   ***********************************************************************************/
  PROCEDURE calc_lead_time(
    iv_code_class1                IN  xxcmn_ship_methods.code_class1%TYPE,                 -- 1.コード区分FROM
    iv_entering_despatching_code1 IN  xxcmn_ship_methods.entering_despatching_code1%TYPE,  -- 2.入出庫場所コードFROM
    iv_code_class2                IN  xxcmn_ship_methods.code_class2%TYPE,                 -- 3.コード区分TO
    iv_entering_despatching_code2 IN  xxcmn_ship_methods.entering_despatching_code2%TYPE,  -- 4.入出庫場所コードTO
    iv_prod_class                 IN  xxcmn_item_categories_v.segment1%TYPE,               -- 5.商品区分
    in_transaction_type_id        IN  xxwsh_oe_transaction_types_v.transaction_type_id%type, -- 6.出庫形態ID
    id_standard_date              IN  DATE  DEFAULT SYSDATE,                               -- 7.基準日(適用日基準日)
    ov_retcode                    OUT NOCOPY VARCHAR2,                                     -- 8.リターンコード
    ov_errmsg_code                OUT NOCOPY VARCHAR2,                                     -- 9.エラーメッセージコード
    ov_errmsg                     OUT NOCOPY VARCHAR2,                                     -- 10.エラーメッセージ
    on_lead_time                  OUT NOCOPY NUMBER,                                       -- 11.生産物流LT／引取変更LT
    on_delivery_lt                OUT NOCOPY NUMBER                                        -- 12.配送LT
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'calc_lead_time'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- メッセージID
    cv_xxwsh_in_prod_class_err     CONSTANT VARCHAR2(100) := 'APP-XXWSH-12751';  -- 入力パラメータ「商品区分」不正
    cv_xxwsh_in_param_set_err      CONSTANT VARCHAR2(100) := 'APP-XXWSH-12752';  -- 入力パラメータ不正
    cv_xxwsh_no_data_found_err     CONSTANT VARCHAR2(100) := 'APP-XXWSH-12753';  -- 対象データなしエラーメッセージ
    cv_xxwsh_get_prof_err          CONSTANT VARCHAR2(100) := 'APP-XXWSH-12754';  -- プロファイル取得エラーメッセージ
    -- トークン
    cv_tkn_prof_name               CONSTANT VARCHAR2(100) := 'PROF_NAME';
    cv_tkn_in_parm                 CONSTANT VARCHAR2(100) := 'IN_PARAM';
    cv_tkn_code_kbn_from           CONSTANT VARCHAR2(100) := 'CODE_KBN_FROM';
    cv_tkn_nsbash_from             CONSTANT VARCHAR2(100) := 'NSBASH_FROM';
    cv_tkn_code_kbn_to             CONSTANT VARCHAR2(100) := 'CODE_KBN_TO';
    cv_tkn_nsbash_to               CONSTANT VARCHAR2(100) := 'NSBASH_TO';
    cv_tkn_item_class              CONSTANT VARCHAR2(100) := 'ITEM_CLASS';
    -- トークンセット値
    cv_code_class1_char            CONSTANT VARCHAR2(100) := 'コード区分From';
    cv_entering_despatch_cd1_char  CONSTANT VARCHAR2(100) := '入出庫場所From';
    cv_code_class2_char            CONSTANT VARCHAR2(100) := 'コード区分To';
    cv_entering_despatch_cd2_char  CONSTANT VARCHAR2(100) := '入出庫場所To';
    cv_prod_class_char             CONSTANT VARCHAR2(100) := '商品区分';
    cv_qty_char                    CONSTANT VARCHAR2(100) := '数量';
--
    -- 商品区分
    cv_prod_class_leaf             CONSTANT VARCHAR2(1)   := '1';  -- リーフ
    cv_prod_class_drink            CONSTANT VARCHAR2(1)   := '2';  -- ドリンク
--
    -- 顧客区分
    cv_cust_class_base             CONSTANT VARCHAR2(1)   := '1';  -- 拠点
    cv_cust_class_deliver          CONSTANT VARCHAR2(1)   := '9';  -- 配送先
--
    -- プロファイル
    cv_prof_tran_type_plan         CONSTANT VARCHAR2(30)  := 'XXWSH_TRAN_TYPE_PLAN'; -- XXWSH:出庫形態_引取計画
--
    -- *** ローカル変数 ***
    -- エラー変数
    lv_err_cd                      VARCHAR2(30);
    --プロファイル値取得
    lv_tran_type_plan               fnd_profile_option_values.profile_option_value%TYPE;
    --
    ln_delivery_lead_time           xxcmn_delivery_lt2_v.delivery_lead_time%TYPE;
    ln_drink_lead_time_day          xxcmn_delivery_lt2_v.drink_lead_time_day%TYPE;
    ln_leaf_lead_time_day           xxcmn_delivery_lt2_v.leaf_lead_time_day%TYPE;
    ln_receipt_chg_lead_time_day    xxcmn_delivery_lt2_v.receipt_change_lead_time_day%TYPE;
    --
    ln_tran_cnt                    NUMBER;
    ln_no_data_flag                VARCHAR2(1) DEFAULT '0';
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    /*************************************
     *  プロファイル取得(F-1)            *
     *************************************/
    --
    -- XXWSH:出庫形態_引取計画
    lv_tran_type_plan    :=  fnd_profile.value( cv_prof_tran_type_plan );
    --
    -- エラー処理
    -- 「XXWSH:出庫形態_引取計画」取得失敗
    IF ( lv_tran_type_plan    IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_get_prof_err,
                                            cv_tkn_prof_name,
                                            cv_prof_tran_type_plan);
      lv_err_cd := cv_xxwsh_get_prof_err;
      RAISE global_api_expt;
    END IF;
    --
    /*************************************
     *  入力パラメータチェック(F-2)      *
     *************************************/
    -- コード区分From
    IF ( iv_code_class1  IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_in_param_set_err,
                                            cv_tkn_in_parm,
                                            cv_code_class1_char);
      lv_err_cd := cv_xxwsh_in_param_set_err;
      RAISE global_api_expt;
    -- 入出庫場所From
    ELSIF ( iv_entering_despatching_code1  IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_in_param_set_err,
                                            cv_tkn_in_parm,
                                            cv_entering_despatch_cd1_char);
      lv_err_cd := cv_xxwsh_in_param_set_err;
      RAISE global_api_expt;
    -- コード区分To
    ELSIF ( iv_code_class2  IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_in_param_set_err,
                                            cv_tkn_in_parm,
                                            cv_code_class2_char);
      lv_err_cd := cv_xxwsh_in_param_set_err;
      RAISE global_api_expt;
    -- 入出庫場所To
    ELSIF ( iv_entering_despatching_code2  IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_in_param_set_err,
                                            cv_tkn_in_parm,
                                            cv_entering_despatch_cd2_char);
      lv_err_cd := cv_xxwsh_in_param_set_err;
      RAISE global_api_expt;
    -- 商品区分
    ELSIF ( iv_prod_class  IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_in_param_set_err,
                                            cv_tkn_in_parm,
                                            cv_prod_class_char);
      lv_err_cd := cv_xxwsh_in_param_set_err;
      RAISE global_api_expt;
    --
    -- 「商品区分」に、１（リーフ）、２（ドリンク）以外がセットされていないか
    ELSIF ( iv_prod_class NOT IN ( cv_prod_class_leaf ,cv_prod_class_drink ) ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_in_prod_class_err);
      lv_err_cd := cv_xxwsh_in_prod_class_err;
      RAISE global_api_expt;
    --
    END IF;
    --
    /*************************************
     *  関連項目取得処理(F-3)            *
     *************************************/
     -- 入力パラメータ「出庫形態ID」から受注タイプが「引取変更」か否かをチェックします。
     BEGIN
       SELECT  COUNT(*)
       INTO    ln_tran_cnt
       FROM    xxwsh_oe_transaction_types2_v xottv
       WHERE   xottv.transaction_type_id   =  in_transaction_type_id
         AND   xottv.transaction_type_name =  lv_tran_type_plan
         AND   rownum = 1;
     EXCEPTION
       WHEN OTHERS THEN
         RAISE global_api_others_expt;
     END;
     --
    /*************************************
     *  配送L/Tアドオン情報抽出(F-4)     *
     *************************************/
     BEGIN
       SELECT  xdlv.delivery_lead_time,            -- 配送リードタイム
               xdlv.drink_lead_time_day,           -- ドリンク生産物流LT
               xdlv.leaf_lead_time_day,            -- リーフ生産物流LT
               xdlv.receipt_change_lead_time_day   -- 引取変更LT
       INTO    ln_delivery_lead_time,
               ln_drink_lead_time_day,
               ln_leaf_lead_time_day,
               ln_receipt_chg_lead_time_day
       FROM    xxcmn_delivery_lt2_v xdlv
       WHERE   xdlv.code_class1                 =  iv_code_class1                 -- コード区分From
         AND   xdlv.entering_despatching_code1  =  iv_entering_despatching_code1  -- 入出庫場所From
         AND   xdlv.code_class2                 =  iv_code_class2                 -- コード区分To
         AND   xdlv.entering_despatching_code2  =  iv_entering_despatching_code2  -- 入出庫場所To
         AND   xdlv.lt_start_date_active       <=  trunc( id_standard_date )
         AND   xdlv.lt_end_date_active         >=  trunc( id_standard_date )
       GROUP BY
         xdlv.delivery_lead_time,
         xdlv.drink_lead_time_day,
         xdlv.leaf_lead_time_day,
         xdlv.receipt_change_lead_time_day;
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
         --コード区分Toが「9」の場合
         IF ( iv_code_class2 = cv_cust_class_deliver ) THEN
           ln_no_data_flag := '1';
         ELSE
           lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                                 cv_xxwsh_no_data_found_err,
                                                 cv_tkn_code_kbn_from,
                                                 iv_code_class1,
                                                 cv_tkn_nsbash_from,
                                                 iv_entering_despatching_code1,
                                                 cv_tkn_code_kbn_to,
                                                 iv_code_class2,
                                                 cv_tkn_nsbash_to,
                                                 iv_entering_despatching_code2,
                                                 cv_tkn_item_class,
                                                 iv_prod_class );
           lv_err_cd := cv_xxwsh_no_data_found_err;
           RAISE global_api_expt;
         END IF;
       WHEN OTHERS THEN
         RAISE global_api_others_expt;
     END;
--
     IF ( ln_no_data_flag = '1' ) THEN
       BEGIN
         SELECT  xdlv.delivery_lead_time,            -- 配送リードタイム
                 xdlv.drink_lead_time_day,           -- ドリンク生産物流LT
                 xdlv.leaf_lead_time_day,            -- リーフ生産物流LT
                 xdlv.receipt_change_lead_time_day   -- 引取変更LT
         INTO    ln_delivery_lead_time,
                 ln_drink_lead_time_day,
                 ln_leaf_lead_time_day,
                 ln_receipt_chg_lead_time_day
         FROM    xxcmn_delivery_lt2_v     xdlv,
                 xxcmn_cust_acct_sites2_v xcasv
         WHERE   xcasv.ship_to_no                 =  iv_entering_despatching_code2
           AND   xdlv.code_class1                 =  iv_code_class1
           AND   xdlv.entering_despatching_code1  =  iv_entering_despatching_code1
           AND   xdlv.code_class2                 =  cv_cust_class_base
           AND   xdlv.entering_despatching_code2  =  xcasv.base_code
-- Ver1.33 Y.Kazama 本番障害#1398 Add Start
           AND   xcasv.party_site_status          = 'A'                            -- サイトステータス[A:有効]
-- Ver1.33 Y.Kazama 本番障害#1398 Add End
           AND   xdlv.lt_start_date_active       <=  trunc( id_standard_date )
           AND   xdlv.lt_end_date_active         >=  trunc( id_standard_date )
       GROUP BY
         xdlv.delivery_lead_time,
         xdlv.drink_lead_time_day,
         xdlv.leaf_lead_time_day,
         xdlv.receipt_change_lead_time_day;
       EXCEPTION
         WHEN NO_DATA_FOUND THEN
           lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                                 cv_xxwsh_no_data_found_err,
                                                 cv_tkn_code_kbn_from,
                                                 iv_code_class1,
                                                 cv_tkn_nsbash_from,
                                                 iv_entering_despatching_code1,
                                                 cv_tkn_code_kbn_to,
                                                 iv_code_class2,
                                                 cv_tkn_nsbash_to,
                                                 iv_entering_despatching_code2,
                                                 cv_tkn_item_class,
                                                 iv_prod_class );
           lv_err_cd := cv_xxwsh_no_data_found_err;
           RAISE global_api_expt;
         WHEN OTHERS THEN
           RAISE global_api_others_expt;
       END;
     END IF;
--
    /*************************************
     *  OUTパラメータセット(F-5)         *
     *************************************/
     -- ステータス部
     ov_retcode      := gv_status_normal;   -- リターンコード
     ov_errmsg_code  := NULL;               -- エラーメッセージコード
     ov_errmsg       := NULL;               -- エラーメッセージ
     --
     on_delivery_lt  := ln_delivery_lead_time; -- 配送リードタイム
     --
     IF ( ln_tran_cnt = 0 ) THEN
       IF ( iv_prod_class = cv_prod_class_leaf ) THEN
         on_lead_time  := ln_leaf_lead_time_day;
       ELSE
         on_lead_time  := ln_drink_lead_time_day;
       END IF;
     ELSE
       on_lead_time    := ln_receipt_chg_lead_time_day;
     END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg      := lv_errmsg;
      ov_errmsg_code := lv_err_cd;
      ov_retcode     := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg      := SQLERRM;
      ov_errmsg_code := SQLCODE;
      ov_retcode     := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg      := SQLERRM;
      ov_errmsg_code := SQLCODE;
      ov_retcode     := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END calc_lead_time;
--
  /**********************************************************************************
   * Procedure Name   : check_shipping_judgment
   * Description      : 出荷可否チェック
   ***********************************************************************************/
  PROCEDURE check_shipping_judgment(
    iv_check_class                IN  VARCHAR2,                                 -- 1.チェック方法区分
    iv_base_cd                    IN  VARCHAR2,                                 -- 2.拠点コード
    in_item_id                    IN  xxcmn_item_mst_v.inventory_item_id%TYPE,  -- 3.品目ID
    in_amount                     IN  NUMBER,                                   -- 4.数量
    id_date                       IN  DATE,                                     -- 5.対象日
    in_deliver_from_id            IN  NUMBER,                                   -- 6.出荷元ID
    iv_request_no                 IN  VARCHAR2,                                 -- 7.依頼No
    ov_retcode                    OUT NOCOPY VARCHAR2,                          -- 8.リターンコード
    ov_errmsg_code                OUT NOCOPY VARCHAR2,                          -- 9.エラーメッセージコード
    ov_errmsg                     OUT NOCOPY VARCHAR2,                          -- 10.エラーメッセージ
    on_result                     OUT NOCOPY NUMBER                             -- 11.処理結果
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_shipping_judgment'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- メッセージID
    cv_xxwsh_in_param_set_err      CONSTANT VARCHAR2(100) := 'APP-XXWSH-12801';  -- 必須入力パラメータ未設定エラーメッセージ
    cv_xxwsh_in_check_class_err    CONSTANT VARCHAR2(100) := 'APP-XXWSH-12802';  -- チェック方法区分値不正エラー
    cv_xxwsh_no_data_found_err     CONSTANT VARCHAR2(100) := 'APP-XXWSH-12803';  -- 対象フォーキャストデータなしエラーメッセージ
    -- トークン
    cv_tkn_in_parm                 CONSTANT VARCHAR2(100) := 'IN_PARAM';
    cv_tkn_item_id                 CONSTANT VARCHAR2(100) := 'ITEM_ID';
    cv_tkn_sc_ship_date            CONSTANT VARCHAR2(100) := 'SC_SHIP_DATE';
    -- トークンセット値
    cv_check_class_char            CONSTANT VARCHAR2(100) := 'チェック方法区分';
    cv_base_cd_char                CONSTANT VARCHAR2(100) := '拠点コード';
    cv_item_id_char                CONSTANT VARCHAR2(100) := '品目ID';
    cv_amount_char                 CONSTANT VARCHAR2(100) := '数量';
    cv_date_char                   CONSTANT VARCHAR2(100) := '対象日';
    cv_deliver_from_id_char        CONSTANT VARCHAR2(100) := '出荷元ID';
    --
    -- チェック方法区分
    cv_check_class_1               CONSTANT VARCHAR2(1)   := '1';   -- 引取計画
    cv_check_class_2               CONSTANT VARCHAR2(1)   := '2';   -- 出荷数制限(商品部)
    cv_check_class_3               CONSTANT VARCHAR2(1)   := '3';   -- 出荷数制限(物流部)
    cv_check_class_4               CONSTANT VARCHAR2(1)   := '4';   -- 計画商品引取計画
    --
    -- フォーキャスト分類
    cv_forecast_class_01           CONSTANT VARCHAR2(2)   := '01';   -- 引取計画
    cv_forecast_class_02           CONSTANT VARCHAR2(2)   := '02';   -- 計画商品
    cv_forecast_class_03           CONSTANT VARCHAR2(2)   := '03';   -- 出荷数制限A
    cv_forecast_class_04           CONSTANT VARCHAR2(2)   := '04';   -- 出荷数制限B
    --
    -- 出荷依頼ステータス
    cv_request_status_01           CONSTANT VARCHAR2(2)   := '01';        -- 入力中
    cv_request_status_02           CONSTANT VARCHAR2(2)   := '02';        -- 拠点確定
    cv_request_status_03           CONSTANT VARCHAR2(2)   := '03';        -- 締め済み
    cv_request_status_04           CONSTANT VARCHAR2(2)   := '04';        -- 出荷実績計上済
    cv_request_status_99           CONSTANT VARCHAR2(2)   := '99';        -- 取消
    --
    -- 出荷支給区分
    cv_shipping_shikyu_class_01    CONSTANT VARCHAR2(1)   := '1';         -- 出荷依頼
    --
    cv_yes                         CONSTANT VARCHAR2(1)   := 'Y';         -- Y (YES_NO区分)
    cv_no                          CONSTANT VARCHAR2(1)   := 'N';         -- N (YES_NO区分)
    --
    cv_order                       CONSTANT VARCHAR2(5)   := 'ORDER';         -- ORDER
    --
    --
    cv_format_yyyymm               CONSTANT VARCHAR2(6)   := 'YYYYMM';        -- 年月書式
    --cd_max_date                    CONSTANT DATE          := to_date('9999/12/31');  -- 最大年月
    --
    cn_status_success              CONSTANT NUMBER        := 0;
    cn_status_error                CONSTANT NUMBER        := 1;
    cn_status_ship_stop            CONSTANT NUMBER        := 2;
-- Ver1.26 M.Hokkanji Start
    cv_log_level            CONSTANT VARCHAR2(1)   := '6';                   -- ログレベル
    cv_colon                CONSTANT VARCHAR2(1)   := ':';                   -- コロン
-- Ver1.26 M.Hokkanji End
    --
--
    -- *** ローカル変数 ***
    -- エラー変数
    lv_err_cd                      VARCHAR2(2000);
    ln_sum_plan_qty                NUMBER;             -- 計画合計数量
    ln_sum_ship_qty                NUMBER;             -- 出荷合計数量
    ln_min_start_date              DATE;               -- 最大開始日
    ln_max_end_date                DATE;               -- 最大終了日
    --
    ln_forecast_cnt                NUMBER DEFAULT 0;   -- 取得フォーキャスト件数
    ln_item_cnt                    NUMBER DEFAULT 0;   -- OPM品目マスタ件数
-- Ver1.26 M.Hokkanji Start
    lv_err_kbn                     VARCHAR2(3);        -- エラー区分
-- Ver1.26 M.Hokkanji End
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- ******************************************************
    -- *  入力パラメータチェック(G-1)                       *
    -- ******************************************************
-- Ver1.26 M.Hokkanji Start
    lv_err_kbn := '000';
-- Ver1.26 M.Hokkanji End
    --
    -- チェック方法区分
    IF ( iv_check_class IS NULL )
      THEN
-- Ver1.26 M.Hokkanji Start
    lv_err_kbn := '001';
-- Ver1.26 M.Hokkanji End
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                              cv_xxwsh_in_param_set_err,
                                              cv_tkn_in_parm,
                                              cv_check_class_char);
        lv_err_cd := cv_xxwsh_in_param_set_err;
        RAISE global_api_expt;
    --
    -- 品目ID
    ELSIF ( in_item_id IS NULL )
      THEN
-- Ver1.26 M.Hokkanji Start
    lv_err_kbn := '002';
-- Ver1.26 M.Hokkanji End
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                              cv_xxwsh_in_param_set_err,
                                              cv_tkn_in_parm,
                                              cv_item_id_char);
        lv_err_cd := cv_xxwsh_in_param_set_err;
        RAISE global_api_expt;
    --
    -- 数量
    ELSIF ( in_amount IS NULL )
      THEN
-- Ver1.26 M.Hokkanji Start
    lv_err_kbn := '003';
-- Ver1.26 M.Hokkanji End
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                              cv_xxwsh_in_param_set_err,
                                              cv_tkn_in_parm,
                                              cv_amount_char);
        lv_err_cd := cv_xxwsh_in_param_set_err;
        RAISE global_api_expt;
    --
    -- 対象日
    ELSIF ( id_date IS NULL )
      THEN
-- Ver1.26 M.Hokkanji Start
    lv_err_kbn := '004';
-- Ver1.26 M.Hokkanji End
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                              cv_xxwsh_in_param_set_err,
                                              cv_tkn_in_parm,
                                              cv_date_char);
        lv_err_cd := cv_xxwsh_in_param_set_err;
        RAISE global_api_expt;
    --
    --
    -- 「チェック方法区分」が1,2,3,4以外
    ELSIF ( iv_check_class NOT IN ( cv_check_class_1,
                                 cv_check_class_2,
                                 cv_check_class_3,
                                 cv_check_class_4 ))
      THEN
-- Ver1.26 M.Hokkanji Start
    lv_err_kbn := '005';
-- Ver1.26 M.Hokkanji End
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                              cv_xxwsh_in_check_class_err);
        lv_err_cd := cv_xxwsh_in_check_class_err;
        RAISE global_api_expt;
    --
    -- 入力パラメータ「チェック方法区分」が「3」以外のとき入力パラメータ「拠点コード」が未設定
    ELSIF (( iv_check_class <> cv_check_class_3 ) AND ( iv_base_cd IS NULL ))
      THEN
-- Ver1.26 M.Hokkanji Start
    lv_err_kbn := '006';
-- Ver1.26 M.Hokkanji End
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                              cv_xxwsh_in_param_set_err,
                                              cv_tkn_in_parm,
                                              cv_base_cd_char);
        lv_err_cd := cv_xxwsh_in_param_set_err;
        RAISE global_api_expt;
    --
    -- 入力パラメータ「チェック方法区分」が「2」以外のとき入力パラメータ「出荷元ID」が未設定
    ELSIF (( iv_check_class <> cv_check_class_2 ) AND ( in_deliver_from_id IS NULL ))
      THEN
-- Ver1.26 M.Hokkanji Start
    lv_err_kbn := '007';
-- Ver1.26 M.Hokkanji End
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                              cv_xxwsh_in_param_set_err,
                                              cv_tkn_in_parm,
                                              cv_deliver_from_id_char);
        lv_err_cd := cv_xxwsh_in_param_set_err;
        RAISE global_api_expt;
    END IF;
--
-- Ver1.26 M.Hokkanji Start
    lv_err_kbn := '008';
-- Ver1.26 M.Hokkanji End
    -- ******************************************************
    -- *  チェック方法振り分け                              *
    -- ******************************************************
    CASE
      -- ******************************************************
      -- *  チェックケース① 引取計画チェック(G-2)            *
      -- ******************************************************
      WHEN ( iv_check_class = cv_check_class_1 ) THEN
        --
-- Ver1.26 M.Hokkanji Start
    lv_err_kbn := '009';
-- Ver1.26 M.Hokkanji End
        -- フォーキャスト抽出(引取計画の指定月の月間)
        BEGIN
          SELECT SUM( mfdt.original_forecast_quantity ),
                 COUNT(*)
          INTO   ln_sum_plan_qty,                                   -- 計画合計数量
                 ln_forecast_cnt                                    -- 取得件数
          FROM   mrp_forecast_designators  mfds,                    -- フォーキャスト名
                 mrp_forecast_dates        mfdt,                    -- フォーキャスト日付
                 xxcmn_item_locations2_v   xilv
          WHERE  xilv.inventory_location_id = in_deliver_from_id    -- 出荷元ID
            AND  mfds.attribute1            = cv_forecast_class_01  -- フォーキャスト分類(引取計画)
            AND  mfds.attribute2            = xilv.segment1         -- 保管倉庫コード
            AND  mfds.attribute3            = iv_base_cd            -- 拠点コード
            AND  mfdt.forecast_designator   = mfds.forecast_designator
            AND  mfdt.organization_id       = mfds.organization_id
            AND  mfdt.inventory_item_id     = in_item_id
            AND  to_char( mfdt.forecast_date , cv_format_yyyymm )
                                            = to_char( id_date , cv_format_yyyymm );
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
          --
          WHEN OTHERS THEN
            RAISE global_api_expt;
        END;
-- Ver1.26 M.Hokkanji Start
    lv_err_kbn := '008';
-- Ver1.26 M.Hokkanji End
        --
-- 2008/07/08_1.10_UPDATA_Start
--        IF ( ln_forecast_cnt = 0 ) THEN
--          lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
--                                                cv_xxwsh_no_data_found_err,
--                                                cv_tkn_item_id,
--                                                in_item_id,
--                                                cv_tkn_sc_ship_date,
--                                                TO_CHAR(id_date, 'YYYY/MM/DD'));
--          lv_err_cd := cv_xxwsh_no_data_found_err;
--          RAISE global_api_expt;
--        END IF;
--        --
-- 2008/07/08_1.10_UPDATA_End
        -- 出荷依頼の抽出
        BEGIN
-- 2008/08/22 H.Itou Mod Start PT 2-2_15 指摘20
--          SELECT
--            NVL(SUM( CASE
--                   -- ステータスが指示(01,02,03)の場合
--                   WHEN ( xoha.req_status IN ( cv_request_status_01,
--                                               cv_request_status_02,
--                                               cv_request_status_03  ))
--                     THEN
--                       (  xola.quantity )                  -- 明細.数量＋数量
--                   -- ステータスが実績(04)の場合
--                   WHEN ( xoha.req_status  =   cv_request_status_04 )
--                     THEN
--                       (  xola.shipped_quantity  )          -- 明細.出荷実績数量＋数量
--                 END ),0)  + in_amount
--          INTO   ln_sum_ship_qty
--          FROM   xxwsh_order_headers_all       xoha,                   -- 受注ヘッダアドオン
--                 xxwsh_order_lines_all         xola,                   -- 受注明細アドオン
--                 xxwsh_oe_transaction_types2_v xottv                   -- 受注タイプ情報View
--          WHERE  xoha.deliver_from_id            = in_deliver_from_id     -- 出荷元ID
--            AND  xoha.head_sales_branch          = iv_base_cd             -- 管轄拠点
--            AND  xoha.latest_external_flag       = cv_yes                 -- 最新フラグ
--            AND  xoha.req_status                <> cv_request_status_99   -- ステータス(取消以外)
--            AND  xottv.transaction_type_id       = xoha.order_type_id     -- 受注タイプID
--            AND  xottv.order_category_code       = cv_order               -- 受注カテゴリ
--            AND  xottv.shipping_shikyu_class     = cv_shipping_shikyu_class_01
--                                                                          -- 出荷支給区分
--                 -- 指示の場合「着荷予定日」と、実績の場合「着荷日」と比較
--            AND  ( ( ( xoha.req_status    IN ( cv_request_status_01,
--                                               cv_request_status_02,
--                                               cv_request_status_03  ))
--                    AND
--                     ( to_char(xoha.schedule_arrival_date, cv_format_yyyymm )
--                                                 = to_char( id_date , cv_format_yyyymm )))
--                 OR (( xoha.req_status     =   cv_request_status_04  )
--                    AND
--                     ( to_char(xoha.arrival_date, cv_format_yyyymm )
--                                                 = to_char( id_date , cv_format_yyyymm ))))
--            AND  xola.order_header_id            = xoha.order_header_id   -- 受注ヘッダID
--            AND  xola.shipping_inventory_item_id = in_item_id             -- 品目ID
--            AND  ((iv_request_no IS NULL) OR (xoha.request_no <> iv_request_no))  -- 依頼No
--            AND  NVL( xola.delete_flag, cv_no ) <> cv_yes;                -- 削除フラグ('Y'以外)
--
-- Ver1.26 M.Hokkanji Start
    lv_err_kbn := '009';
-- Ver1.26 M.Hokkanji End
          SELECT NVL(SUM(subsql.quantity),0)  + in_amount
          INTO   ln_sum_ship_qty
          FROM  (-- ステータスが入力中～締済の場合
                 SELECT xola.quantity                 quantity                            -- 明細.数量
                 FROM   xxwsh_order_headers_all       xoha,                               -- 受注ヘッダアドオン
                        xxwsh_order_lines_all         xola,                               -- 受注明細アドオン
                        xxwsh_oe_transaction_types2_v xottv                               -- 受注タイプ情報View
                 WHERE  xoha.deliver_from_id            = in_deliver_from_id              -- 出荷元ID
                 AND    xoha.head_sales_branch          = iv_base_cd                      -- 管轄拠点
                 AND    xoha.latest_external_flag       = cv_yes                          -- 最新フラグ
                 AND    xoha.req_status                <> cv_request_status_99            -- ステータス(取消以外)
                 AND    xottv.transaction_type_id       = xoha.order_type_id              -- 受注タイプID
                 AND    xottv.order_category_code       = cv_order                        -- 受注カテゴリ
                 AND    xottv.shipping_shikyu_class     = cv_shipping_shikyu_class_01     -- 出荷支給区分
                 AND    xoha.req_status              IN ( cv_request_status_01,           -- ステータス01:入力中
                                                          cv_request_status_02,           -- ステータス02:拠点確定
                                                          cv_request_status_03  )         -- ステータス03:締め済み
                 AND    TO_CHAR(xoha.schedule_arrival_date, cv_format_yyyymm )            -- 着荷予定日
                                                        = TO_CHAR( id_date , cv_format_yyyymm )
                 AND    xola.order_header_id            = xoha.order_header_id            -- 受注ヘッダID
                 AND    xola.shipping_inventory_item_id = in_item_id                      -- 品目ID
                 AND  ((iv_request_no                  IS NULL)                           -- 依頼No
                   OR  (xoha.request_no                <> iv_request_no))
                 AND    NVL( xola.delete_flag, cv_no ) <> cv_yes                          -- 削除フラグ('Y'以外)
                 -------------------------
                 UNION ALL
                 -------------------------
                 -- ステータスが出荷実績確定済の場合
                 SELECT xola.shipped_quantity         quantity                            -- 明細.出荷実績数量
                 FROM   xxwsh_order_headers_all       xoha,                               -- 受注ヘッダアドオン
                        xxwsh_order_lines_all         xola,                               -- 受注明細アドオン
                        xxwsh_oe_transaction_types2_v xottv                               -- 受注タイプ情報View
                 WHERE  xoha.deliver_from_id            = in_deliver_from_id              -- 出荷元ID
                 AND    xoha.head_sales_branch          = iv_base_cd                      -- 管轄拠点
                 AND    xoha.latest_external_flag       = cv_yes                          -- 最新フラグ
                 AND    xoha.req_status                <> cv_request_status_99            -- ステータス(取消以外)
                 AND    xottv.transaction_type_id       = xoha.order_type_id              -- 受注タイプID
                 AND    xottv.order_category_code       = cv_order                        -- 受注カテゴリ
                 AND    xottv.shipping_shikyu_class     = cv_shipping_shikyu_class_01     -- 出荷支給区分
                 AND    xoha.req_status                 = cv_request_status_04            -- ステータス04:出荷実績確定済
                 AND    TO_CHAR(xoha.arrival_date, cv_format_yyyymm )                     -- 着荷日
                                                        = TO_CHAR( id_date , cv_format_yyyymm )
                 AND    xola.order_header_id            = xoha.order_header_id            -- 受注ヘッダID
                 AND    xola.shipping_inventory_item_id = in_item_id                      -- 品目ID
                 AND  ((iv_request_no                  IS NULL)                           -- 依頼No
                   OR  (xoha.request_no                <> iv_request_no))
                 AND    NVL( xola.delete_flag, cv_no ) <> cv_yes                          -- 削除フラグ('Y'以外)
                ) subsql
          ;
-- 2008/08/22 H.Itou Mod End
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
          --
          WHEN OTHERS THEN
            RAISE global_api_expt;
        END;
-- Ver1.26 M.Hokkanji Start
    lv_err_kbn := '010';
-- Ver1.26 M.Hokkanji End
      -- ******************************************************
      -- *  チェックケース② 出荷数制限(商品部)チェック(G-3)  *
      -- ******************************************************
      WHEN ( iv_check_class = cv_check_class_2 ) THEN
        -- フォーキャスト抽出(引取計画の指定月の月間)
        BEGIN
-- Ver1.26 M.Hokkanji Start
    lv_err_kbn := '011';
-- Ver1.26 M.Hokkanji End
          SELECT SUM( mfdt.original_forecast_quantity ),
                 MIN( mfdt.forecast_date ),
                 MAX( mfdt.rate_end_date )
          INTO   ln_sum_plan_qty,                                   -- 計画合計数量
                 ln_min_start_date,                                 -- 最小の開始日
                 ln_max_end_date                                    -- 最大の終了日
          FROM   mrp_forecast_designators  mfds,                    -- フォーキャスト名
                 mrp_forecast_dates        mfdt                     -- フォーキャスト日付
          WHERE  mfds.attribute1            = cv_forecast_class_03  -- フォーキャスト分類(出荷数制限A)
            AND  mfds.attribute3            = iv_base_cd            -- 拠点コード
            AND  mfdt.forecast_designator   = mfds.forecast_designator   -- フォーキャスト名
            AND  mfdt.organization_id       = mfds.organization_id       -- 組織ＩＤ
            AND  mfdt.inventory_item_id     = in_item_id                 -- 品目ＩＤ
            AND  mfdt.forecast_date        <= trunc( id_date )           -- 開始日<=対象日
--            AND  ((   mfdt.rate_end_date   IS NULL )
--                  OR  mfdt.rate_end_date >= trunc( id_date ));           -- 終了日>=対象日
            AND  mfdt.rate_end_date        >= trunc( id_date );          -- 終了日>=対象日
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
          --
          WHEN OTHERS THEN
            RAISE global_api_expt;
        END;
        --
-- Ver1.26 M.Hokkanji Start
    lv_err_kbn := '012';
-- Ver1.26 M.Hokkanji End
        --
        -- 出荷依頼の抽出
        BEGIN
-- 2008/08/22 H.Itou Mod Start PT 2-2_15 指摘20
--          SELECT
--            NVL(SUM( CASE
--                   WHEN ( xoha.req_status IN ( cv_request_status_01,
--                                               cv_request_status_02,
--                                               cv_request_status_03  ))
--                     THEN
--                       (  xola.quantity )
--                   WHEN ( xoha.req_status  =   cv_request_status_04 )
--                     THEN
--                       (  xola.shipped_quantity )
--                 END ), 0) + in_amount
--          INTO   ln_sum_ship_qty
--          FROM   xxwsh_order_headers_all       xoha,
--                 xxwsh_order_lines_all         xola,
--                 xxwsh_oe_transaction_types2_v xottv
--          WHERE  xoha.head_sales_branch          = iv_base_cd                      -- 拠点コード
--            AND  xoha.latest_external_flag       = cv_yes                          -- 最新フラグ
--            AND  xoha.req_status                <> cv_request_status_99            -- ステータス取消以外
--            AND  xottv.transaction_type_id       = xoha.order_type_id              -- 受注タイプID
--            AND  xottv.order_category_code       = cv_order                        -- 受注カテゴリ
--            AND  xottv.shipping_shikyu_class     = cv_shipping_shikyu_class_01     -- 出荷支給区分
--                 -- 指示の場合「着荷予定日」と、実績の場合「着荷日」と比較
--            AND  ( ( ( xoha.req_status IN ( cv_request_status_01,
--                                            cv_request_status_02,
--                                            cv_request_status_03  ))
--                    AND
--                     (( xoha.schedule_arrival_date   >= trunc( ln_min_start_date ) )
--                     AND
--                      ( xoha.schedule_arrival_date   <= trunc( ln_max_end_date   ) ))
--                 )
--                 OR
--                 (( xoha.req_status = cv_request_status_04  )
--                   AND
--                   ((   xoha.arrival_date            >= trunc( ln_min_start_date ) )
--                   AND
--                    (   xoha.arrival_date            <= trunc( ln_max_end_date   ) ))
--                 ) )
--            AND  xola.order_header_id            = xoha.order_header_id            -- 受注ヘッダID
--            AND  xola.shipping_inventory_item_id = in_item_id                      -- 品目ID
--            AND  ((iv_request_no IS NULL) OR (xoha.request_no <> iv_request_no))   -- 依頼No
--            AND  NVL( xola.delete_flag, cv_no ) <> cv_yes;                         -- 削除フラグ
--
          SELECT NVL(SUM(subsql.quantity),0)  + in_amount
          INTO   ln_sum_ship_qty
          FROM  (-- ステータスが入力中～締済の場合
                 SELECT xola.quantity                 quantity                            -- 明細.数量
                 FROM   xxwsh_order_headers_all       xoha                                -- 受注ヘッダアドオン
                       ,xxwsh_order_lines_all         xola                                -- 受注明細アドオン
                       ,xxwsh_oe_transaction_types2_v xottv                               -- 受注タイプ情報VIEW
                 WHERE  xoha.head_sales_branch          = iv_base_cd                      -- 拠点コード
                 AND    xoha.latest_external_flag       = cv_yes                          -- 最新フラグ
                 AND    xoha.req_status                <> cv_request_status_99            -- ステータス取消以外
                 AND    xottv.transaction_type_id       = xoha.order_type_id              -- 受注タイプID
                 AND    xottv.order_category_code       = cv_order                        -- 受注カテゴリ
                 AND    xottv.shipping_shikyu_class     = cv_shipping_shikyu_class_01     -- 出荷支給区分
                 AND    xoha.req_status              IN ( cv_request_status_01,           -- ステータス01:入力中
                                                          cv_request_status_02,           -- ステータス02:拠点確定
                                                          cv_request_status_03  )         -- ステータス03:締め済み
                 AND    xoha.schedule_arrival_date     >= TRUNC( ln_min_start_date )      -- 着荷予定日
                 AND    xoha.schedule_arrival_date     <= TRUNC( ln_max_end_date   )      -- 着荷予定日
                 AND    xola.order_header_id            = xoha.order_header_id            -- 受注ヘッダID
                 AND    xola.shipping_inventory_item_id = in_item_id                      -- 品目ID
                 AND  ((iv_request_no                  IS NULL)                           -- 依頼No
                   OR  (xoha.request_no                <> iv_request_no))
                 AND    NVL( xola.delete_flag, cv_no ) <> cv_yes                          -- 削除フラグ
                 -------------------------
                 UNION ALL
                 -------------------------
                 -- ステータスが出荷実績確定済の場合
                 SELECT xola.shipped_quantity         quantity                            -- 明細.出荷実績数量
                 FROM   xxwsh_order_headers_all       xoha                                -- 受注ヘッダアドオン
                       ,xxwsh_order_lines_all         xola                                -- 受注明細アドオン
                       ,xxwsh_oe_transaction_types2_v xottv                               -- 受注タイプ情報VIEW
                 WHERE  xoha.head_sales_branch          = iv_base_cd                      -- 拠点コード
                 AND    xoha.latest_external_flag       = cv_yes                          -- 最新フラグ
                 AND    xoha.req_status                <> cv_request_status_99            -- ステータス取消以外
                 AND    xottv.transaction_type_id       = xoha.order_type_id              -- 受注タイプID
                 AND    xottv.order_category_code       = cv_order                        -- 受注カテゴリ
                 AND    xottv.shipping_shikyu_class     = cv_shipping_shikyu_class_01     -- 出荷支給区分
                 AND    xoha.req_status                 = cv_request_status_04            -- ステータス04:出荷実績計上済
                 AND    xoha.arrival_date              >= TRUNC( ln_min_start_date )      -- 着荷日
                 AND    xoha.arrival_date              <= TRUNC( ln_max_end_date   )      -- 着荷日
                 AND    xola.order_header_id            = xoha.order_header_id            -- 受注ヘッダID
                 AND    xola.shipping_inventory_item_id = in_item_id                      -- 品目ID
                 AND  ((iv_request_no                 IS NULL)                            -- 依頼No
                   OR  (xoha.request_no               <> iv_request_no))
                 AND    NVL( xola.delete_flag, cv_no ) <> cv_yes                          -- 削除フラグ
                ) subsql
          ;
-- 2008/08/22 H.Itou Mod End
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
          --
          WHEN OTHERS THEN
            RAISE global_api_expt;
        END;
-- Ver1.26 M.Hokkanji Start
    lv_err_kbn := '013';
-- Ver1.26 M.Hokkanji End
        --
      -- ******************************************************
      -- *  チェックケース③ 出荷数制限(物流部)チェック(G-4)  *
      -- ******************************************************
      WHEN ( iv_check_class = cv_check_class_3 ) THEN
        --(1) 出荷停止日チェック
        BEGIN
          -- 2008/07/30 内部変更要求#182 UPD START
          --SELECT  COUNT(*)
          --INTO    ln_item_cnt
          --FROM    xxcmn_item_mst2_v  ximv   -- OPM品目情報View2
          --WHERE   ximv.inventory_item_id   =  in_item_id
          --  AND   ximv.obsolete_date      <=  trunc( id_date )
          --  AND   ximv.start_date_active  <=  trunc( id_date )
          --  AND   ximv.end_date_active    >=  trunc( id_date );
          SELECT  COUNT(*)
          INTO    ln_item_cnt
          FROM    xxcmn_item_mst2_v  ximv   -- OPM品目情報View2
          WHERE   ximv.inventory_item_id   =  in_item_id
            AND   ximv.shipping_end_date  <=  trunc( id_date )
            AND   ximv.start_date_active  <=  trunc( id_date )
            AND   ximv.end_date_active    >=  trunc( id_date );
          -- 2008/07/30 内部変更要求#182 UPD END
        EXCEPTION
          WHEN OTHERS THEN
            RAISE global_api_expt;
        END;
        --
        -- 1件以上で出荷停止日エラー
        IF ( ln_item_cnt = 0 ) THEN
         -- フォーキャスト抽出(引取計画の指定月の月間)
          BEGIN
            SELECT SUM( mfdt.original_forecast_quantity ),
                   MIN( mfdt.forecast_date ),
                   MAX( mfdt.rate_end_date )
            INTO   ln_sum_plan_qty,                                   -- 計画合計数量
                   ln_min_start_date,                                 -- 最小の開始日
                   ln_max_end_date                                    -- 最大の終了日
            FROM   mrp_forecast_designators  mfds,                    -- フォーキャスト名
                   mrp_forecast_dates        mfdt,                    -- フォーキャスト日付
                   xxcmn_item_locations2_v   xilv
            WHERE  xilv.inventory_location_id = in_deliver_from_id    -- 出荷元ID
              AND  mfds.attribute1            = cv_forecast_class_04  -- フォーキャスト分類(出荷数制限B)
              AND  mfds.attribute2            = xilv.segment1         -- 保管倉庫コード
              AND  mfdt.forecast_designator   = mfds.forecast_designator   -- フォーキャスト名
              AND  mfdt.organization_id       = mfds.organization_id       -- 組織ＩＤ
              AND  mfdt.inventory_item_id     = in_item_id                 -- 品目ＩＤ
              AND  mfdt.forecast_date        <= trunc( id_date )           -- 開始日<=対象日
--              AND  ((   mfdt.rate_end_date   IS NULL )
--                    OR  mfdt.rate_end_date   >= trunc( id_date ));
              AND  mfdt.rate_end_date        >= trunc( id_date );          -- 終了日>=対象日
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              NULL;
            --
            WHEN OTHERS THEN
              RAISE global_api_expt;
          END;
          --
-- Ver1.26 M.Hokkanji Start
    lv_err_kbn := '014';
-- Ver1.26 M.Hokkanji End
          --
          -- 出荷依頼の抽出
          BEGIN
-- 2008/08/22 H.Itou Mod Start PT 2-2_15 指摘20
--            SELECT
--              NVL(SUM( CASE
--                     WHEN ( xoha.req_status IN ( cv_request_status_01,
--                                                 cv_request_status_02,
--                                                 cv_request_status_03  ))
--                       THEN
--                         (  xola.quantity         )
--                     WHEN ( xoha.req_status  =   cv_request_status_04 )
--                       THEN
--                         (  xola.shipped_quantity )
--                   END ),0)    + in_amount
--                   ,count(*)
--            INTO   ln_sum_ship_qty,ln_forecast_cnt
--            FROM   xxwsh_order_headers_all       xoha,
--                   xxwsh_order_lines_all         xola,
--                   xxwsh_oe_transaction_types2_v xottv
--            WHERE  xoha.deliver_from_id           = in_deliver_from_id            -- 出荷元
--              AND  xoha.latest_external_flag      = cv_yes                        -- 最新フラグ
--              AND  xoha.req_status               <> cv_request_status_99          -- ステータス取消以外
--              AND  xottv.transaction_type_id      = xoha.order_type_id            -- 受注タイプID
--              AND  xottv.order_category_code      = cv_order                      -- 受注カテゴリ
--              AND  xottv.shipping_shikyu_class    = cv_shipping_shikyu_class_01   -- 出荷支給区分
--                   -- 指示の場合「出荷予定日」と、実績の場合「出荷日」と比較
--              AND  ( ( ( xoha.req_status IN ( cv_request_status_01,
--                                              cv_request_status_02,
--                                              cv_request_status_03  ))
--                      AND
--                       (( xoha.schedule_ship_date   >= trunc( ln_min_start_date ) )
--                       AND
--                        ( xoha.schedule_ship_date   <= trunc( ln_max_end_date   ) ))
--                   )
--                   OR
--                   (( xoha.req_status = cv_request_status_04  )
--                     AND
--                     ((   xoha.shipped_date         >= trunc( ln_min_start_date ) )
--                     AND
--                      (   xoha.shipped_date         <= trunc( ln_max_end_date ) ))
--                   ) )
--              AND  xola.order_header_id            = xoha.order_header_id            -- 受注ヘッダID
--              AND  xola.shipping_inventory_item_id = in_item_id                      -- 品目ID
--              AND  ((iv_request_no IS NULL) OR (xoha.request_no <> iv_request_no))   -- 依頼No
--              AND  NVL( xola.delete_flag, cv_no ) <> cv_yes;                         -- 削除フラグ
--
            SELECT NVL(SUM(subsql.quantity),0)  + in_amount
                  ,COUNT(*)                                                                 -- フォーキャスト数
            INTO   ln_sum_ship_qty,ln_forecast_cnt
            FROM  (-- ステータスが入力中～締済の場合
                   SELECT xola.quantity                 quantity                            -- 明細.数量
                   FROM   xxwsh_order_headers_all       xoha                                -- 受注ヘッダアドオン
                         ,xxwsh_order_lines_all         xola                                -- 受注明細アドオン
                         ,xxwsh_oe_transaction_types2_v xottv                               -- 受注タイプ情報VIEW
                   WHERE  xoha.deliver_from_id            = in_deliver_from_id              -- 出荷元
                   AND    xoha.latest_external_flag       = cv_yes                          -- 最新フラグ
                   AND    xoha.req_status                <> cv_request_status_99            -- ステータス取消以外
                   AND    xottv.transaction_type_id       = xoha.order_type_id              -- 受注タイプID
                   AND    xottv.order_category_code       = cv_order                        -- 受注カテゴリ
                   AND    xottv.shipping_shikyu_class     = cv_shipping_shikyu_class_01     -- 出荷支給区分
                   AND    xoha.req_status              IN ( cv_request_status_01,           -- ステータス01:入力中
                                                            cv_request_status_02,           -- ステータス02:拠点確定
                                                            cv_request_status_03  )         -- ステータス03:締め済み
                   AND    xoha.schedule_ship_date        >= TRUNC( ln_min_start_date )      -- 出荷予定日
                   AND    xoha.schedule_ship_date        <= TRUNC( ln_max_end_date   )      -- 出荷予定日
                   AND    xola.order_header_id            = xoha.order_header_id            -- 受注ヘッダID
                   AND    xola.shipping_inventory_item_id = in_item_id                      -- 品目ID
                   AND  ((iv_request_no                  IS NULL)                           -- 依頼No
                     OR  (xoha.request_no                <> iv_request_no))
                   AND    NVL( xola.delete_flag, cv_no ) <> cv_yes                          -- 削除フラグ
                   -------------------------
                   UNION ALL
                   -------------------------
                   -- ステータスが出荷実績確定済の場合
                   SELECT xola.shipped_quantity         quantity                            -- 明細.出荷実績数量
                   FROM   xxwsh_order_headers_all       xoha                                -- 受注ヘッダアドオン
                         ,xxwsh_order_lines_all         xola                                -- 受注明細アドオン
                         ,xxwsh_oe_transaction_types2_v xottv                               -- 受注タイプ情報VIEW
                   WHERE  xoha.deliver_from_id            = in_deliver_from_id              -- 出荷元
                   AND    xoha.latest_external_flag       = cv_yes                          -- 最新フラグ
                   AND    xoha.req_status                <> cv_request_status_99            -- ステータス取消以外
                   AND    xottv.transaction_type_id       = xoha.order_type_id              -- 受注タイプID
                   AND    xottv.order_category_code       = cv_order                        -- 受注カテゴリ
                   AND    xottv.shipping_shikyu_class     = cv_shipping_shikyu_class_01     -- 出荷支給区分
                   AND    xoha.req_status                 = cv_request_status_04            -- ステータス04:出荷実績計上済
                   AND    xoha.shipped_date              >= TRUNC( ln_min_start_date )      -- 出荷日
                   AND    xoha.shipped_date              <= TRUNC( ln_max_end_date   )      -- 出荷日
                   AND    xola.order_header_id            = xoha.order_header_id            -- 受注ヘッダID
                   AND    xola.shipping_inventory_item_id = in_item_id                      -- 品目ID
                   AND  ((iv_request_no                  IS NULL)                           -- 依頼No
                     OR  (xoha.request_no                <> iv_request_no))
                   AND    NVL( xola.delete_flag, cv_no ) <> cv_yes                          -- 削除フラグ
                  ) subsql
            ;
-- 2008/08/22 H.Itou Mod End
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              NULL;
            --
            WHEN OTHERS THEN
              RAISE global_api_expt;
          END;
        END IF;
-- Ver1.26 M.Hokkanji Start
    lv_err_kbn := '015';
-- Ver1.26 M.Hokkanji End
       --
      -- ******************************************************
      -- *  チェックケース④ 計画商品引取計画チェック(G-5)    *
      -- ******************************************************
      WHEN ( iv_check_class = cv_check_class_4 ) THEN
        -- フォーキャスト抽出(引取計画の指定月の月間)
        BEGIN
          SELECT SUM( mfdt.original_forecast_quantity ),
                 MIN( mfdt.forecast_date ),
                 MAX( mfdt.rate_end_date ),
                 COUNT(*)
          INTO   ln_sum_plan_qty,                                   -- 計画合計数量
                 ln_min_start_date,                                 -- 最小の開始日
                 ln_max_end_date,                                   -- 最大の終了日
                 ln_forecast_cnt                                    -- 取得件数
          FROM   mrp_forecast_designators  mfds,                    -- フォーキャスト名
                 mrp_forecast_dates        mfdt,                    -- フォーキャスト日付
                 xxcmn_item_locations2_v   xilv
           WHERE  xilv.inventory_location_id  = in_deliver_from_id    -- 出荷元ID
             AND  mfds.attribute1             = cv_forecast_class_02  -- フォーキャスト分類(計画商品)
             AND  mfds.attribute2             = xilv.segment1         -- 保管倉庫コード
             AND  mfds.attribute3             = iv_base_cd            -- 拠点コード
             AND  mfdt.forecast_designator    = mfds.forecast_designator   -- フォーキャスト名
             AND  mfdt.organization_id        = mfds.organization_id       -- 組織ＩＤ
             AND  mfdt.inventory_item_id      = in_item_id                 -- 品目ＩＤ
             AND  mfdt.forecast_date         <= trunc( id_date )           -- 開始日<=対象日
--             AND  ((   mfdt.rate_end_date    IS NULL )
--                   OR  mfdt.rate_end_date  >= trunc( id_date ));           -- 終了日>=対象日
             AND  mfdt.rate_end_date         >= trunc( id_date );          -- 終了日>=対象日
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
          --
          WHEN OTHERS THEN
            RAISE global_api_expt;
        END;
        --
        IF ( ln_forecast_cnt = 0 ) THEN
-- Ver1.31 Y.Kazama Start Mod 本番障害#1243
          -- 取得件数が0件の場合はチェック対象外とする
         -- 正常
         on_result := cn_status_success;
         RETURN;
--          lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
--                                                cv_xxwsh_no_data_found_err,
--                                                cv_tkn_item_id,
--                                                in_item_id,
--                                                cv_tkn_sc_ship_date,
--                                                TO_CHAR(id_date,'YYYY/MM/DD'));
--          lv_err_cd := cv_xxwsh_no_data_found_err;
--          RAISE global_api_expt;
-- Ver1.31 Y.Kazama End   Mod 本番障害#1243
        END IF;
        --
-- Ver1.26 M.Hokkanji Start
    lv_err_kbn := '016';
-- Ver1.26 M.Hokkanji End
        --
        -- 出荷依頼の抽出
        BEGIN
-- 2008/08/22 H.Itou Mod Start PT 2-2_15 指摘20
--          SELECT
--            NVL(SUM( CASE
--                   WHEN ( xoha.req_status IN ( cv_request_status_01,
--                                               cv_request_status_02,
--                                               cv_request_status_03  ))
--                     THEN
--                       (  xola.quantity          )
--                   WHEN ( xoha.req_status  =   cv_request_status_04 )
--                     THEN
--                       (  xola.shipped_quantity  )
--                 END ),0)  + in_amount
--          INTO   ln_sum_ship_qty
--          FROM   xxwsh_order_headers_all       xoha,
--                 xxwsh_order_lines_all         xola,
--                 xxwsh_oe_transaction_types2_v xottv
--          WHERE  xoha.deliver_from_id           = in_deliver_from_id          -- 出荷元
--            AND  xoha.head_sales_branch         = iv_base_cd                  -- 拠点コード
--            AND  xoha.latest_external_flag      = cv_yes                      -- 最新フラグ
--            AND  xoha.req_status               <> cv_request_status_99        -- ステータス取消以外
--            AND  xottv.transaction_type_id      = xoha.order_type_id          -- 受注タイプID
--            AND  xottv.order_category_code      = cv_order                    -- 受注カテゴリ
--            AND  xottv.shipping_shikyu_class    = cv_shipping_shikyu_class_01 -- 出荷支給区分
--                 -- 指示の場合「出荷予定日」と、実績の場合「出荷日」と比較
--            AND  ( ( ( xoha.req_status IN ( cv_request_status_01,
--                                            cv_request_status_02,
--                                            cv_request_status_03  ))
--                   AND
--                    (( xoha.schedule_ship_date  >= trunc( ln_min_start_date ) )
--                   AND
--                     ( xoha.schedule_ship_date  <= trunc( ln_max_end_date ) ))
--                 )
--                 OR
--                 ( ( xoha.req_status = cv_request_status_04  )
--                   AND
--                   ((  xoha.shipped_date        >= trunc( ln_min_start_date ) )
--                   AND
--                    (  xoha.shipped_date        <= trunc( ln_max_end_date ) ))
--                 ) )
--            AND  xola.order_header_id            = xoha.order_header_id            -- 受注ヘッダID
--            AND  xola.shipping_inventory_item_id = in_item_id                      -- 品目ID
--            AND  ((iv_request_no IS NULL) OR (xoha.request_no <> iv_request_no))   -- 依頼No
--            AND  NVL( xola.delete_flag, cv_no ) <> cv_yes;                         -- 削除フラグ
--
          SELECT NVL(SUM(subsql.quantity),0)  + in_amount
          INTO   ln_sum_ship_qty
          FROM  (-- ステータスが入力中～締済の場合
                 SELECT xola.quantity                 quantity                            -- 明細.数量
                 FROM   xxwsh_order_headers_all       xoha                                -- 受注ヘッダアドオン
                       ,xxwsh_order_lines_all         xola                                -- 受注明細アドオン
                       ,xxwsh_oe_transaction_types2_v xottv                               -- 受注タイプ情報VIEW
                 WHERE  xoha.deliver_from_id            = in_deliver_from_id              -- 出荷元
                 AND    xoha.head_sales_branch          = iv_base_cd                      -- 拠点コード
                 AND    xoha.latest_external_flag       = cv_yes                          -- 最新フラグ
                 AND    xoha.req_status                <> cv_request_status_99            -- ステータス取消以外
                 AND    xottv.transaction_type_id       = xoha.order_type_id              -- 受注タイプID
                 AND    xottv.order_category_code       = cv_order                        -- 受注カテゴリ
                 AND    xottv.shipping_shikyu_class     = cv_shipping_shikyu_class_01     -- 出荷支給区分
                 AND    xoha.req_status              IN ( cv_request_status_01,            -- ステータス01:入力中
                                                          cv_request_status_02,            -- ステータス02:拠点確定
                                                          cv_request_status_03  )          -- ステータス03:締め済み
                 AND    xoha.schedule_ship_date        >= TRUNC( ln_min_start_date )
                 AND    xoha.schedule_ship_date        <= TRUNC( ln_max_end_date   )
                 AND    xola.order_header_id            = xoha.order_header_id            -- 受注ヘッダID
                 AND    xola.shipping_inventory_item_id = in_item_id                      -- 品目ID
                 AND  ((iv_request_no                  IS NULL)                           -- 依頼No
                   OR  (xoha.request_no                <> iv_request_no))
                 AND    NVL( xola.delete_flag, cv_no ) <> cv_yes                          -- 削除フラグ
                 -------------------------
                 UNION ALL
                 -------------------------
                 -- ステータスが出荷実績確定済の場合
                 SELECT xola.shipped_quantity         quantity                            -- 明細.出荷実績数量
                 FROM   xxwsh_order_headers_all       xoha                                -- 受注ヘッダアドオン
                       ,xxwsh_order_lines_all         xola                                -- 受注明細アドオン
                       ,xxwsh_oe_transaction_types2_v xottv                               -- 受注タイプ情報VIEW
                 WHERE  xoha.deliver_from_id            = in_deliver_from_id              -- 出荷元
                 AND    xoha.head_sales_branch          = iv_base_cd                      -- 拠点コード
                 AND    xoha.latest_external_flag       = cv_yes                          -- 最新フラグ
                 AND    xoha.req_status                <> cv_request_status_99            -- ステータス取消以外
                 AND    xottv.transaction_type_id       = xoha.order_type_id              -- 受注タイプID
                 AND    xottv.order_category_code       = cv_order                        -- 受注カテゴリ
                 AND    xottv.shipping_shikyu_class     = cv_shipping_shikyu_class_01     -- 出荷支給区分
                 AND    xoha.req_status                 = cv_request_status_04            -- ステータス04:出荷実績計上済
                 AND    xoha.shipped_date              >= TRUNC( ln_min_start_date )      -- 出荷日
                 AND    xoha.shipped_date              <= TRUNC( ln_max_end_date   )      -- 出荷日
                 AND    xola.order_header_id            = xoha.order_header_id            -- 受注ヘッダID
                 AND    xola.shipping_inventory_item_id = in_item_id                      -- 品目ID
                 AND  ((iv_request_no                  IS NULL)                           -- 依頼No
                   OR  (xoha.request_no                <> iv_request_no))
                 AND    NVL( xola.delete_flag, cv_no ) <> cv_yes                          -- 削除フラグ
                 ) subsql
          ;
-- 2008/08/22 H.Itou Mod End
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
          --
          WHEN OTHERS THEN
            RAISE global_api_expt;
        END;
        --
        --
    END CASE;
--
-- Ver1.26 M.Hokkanji Start
    lv_err_kbn := '017';
-- Ver1.26 M.Hokkanji End
    -- ******************************************************
    -- *  OUTパラメータセット(G-6)                          *
    -- ******************************************************
    -- ステータス部
    ov_retcode      := gv_status_normal;   -- リターンコード
    ov_errmsg_code  := NULL;               -- エラーメッセージコード
    ov_errmsg       := NULL;               -- エラーメッセージ
    --
    -- 計画合計数量＜出荷合計数量であれば、「処理結果」に「数量オーバーエラー」
    IF ( ln_item_cnt = 0 ) THEN
      IF ((ln_sum_plan_qty IS NULL) OR ( ln_sum_plan_qty >= ln_sum_ship_qty )) THEN
        -- 正常
        on_result      := cn_status_success;
      ELSE
        -- 数量オーバーエラー
        on_result      := cn_status_error;
      END IF;
    ELSE
      -- 出荷停止エラー
        on_result      := cn_status_ship_stop;
    END IF;
-- Ver1.26 M.Hokkanji Start
    lv_err_kbn := '018';
-- Ver1.26 M.Hokkanji End
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg      := lv_errmsg;
      ov_errmsg_code := lv_err_cd;
      ov_retcode     := gv_status_error;
-- Ver1.27 M.Hokkanji Start
-- ログメッセージ埋め込み
      FND_LOG.STRING(cv_log_level, gv_pkg_name
                    || cv_colon
                    || cv_prg_name,
                       'チェック方法：' || iv_check_class
                    || '、拠点コード：' || in_item_id
                    || '、INV品目コード：' || TO_CHAR(in_item_id)
                    || '、数量：' || TO_CHAR(in_amount)
                    || '、対象日付：' || TO_CHAR(id_date,'YYYY/MM/DD')
                    || '、出庫元ID：' || TO_CHAR(in_deliver_from_id)
                    || '、依頼No：' || iv_request_no
                    || '、エラー区分：' || lv_err_kbn
                    || '、エラー：' || SQLERRM);
-- Ver1.27 M.Hokkanji End
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg      := SQLERRM;
      ov_errmsg_code := SQLCODE;
      ov_retcode     := gv_status_error;
-- Ver1.27 M.Hokkanji Start
-- ログメッセージ埋め込み
      FND_LOG.STRING(cv_log_level, gv_pkg_name
                    || cv_colon
                    || cv_prg_name,
                       'チェック方法：' || iv_check_class
                    || '、拠点コード：' || in_item_id
                    || '、INV品目コード：' || TO_CHAR(in_item_id)
                    || '、数量：' || TO_CHAR(in_amount)
                    || '、対象日付：' || TO_CHAR(id_date,'YYYY/MM/DD')
                    || '、出庫元ID：' || TO_CHAR(in_deliver_from_id)
                    || '、依頼No：' || iv_request_no
                    || '、エラー区分：' || lv_err_kbn
                    || '、エラー：' || SQLERRM);
-- Ver1.27 M.Hokkanji End
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg      := SQLERRM;
      ov_errmsg_code := SQLCODE;
      ov_retcode     := gv_status_error;
-- Ver1.27 M.Hokkanji Start
-- ログメッセージ埋め込み
      FND_LOG.STRING(cv_log_level, gv_pkg_name
                    || cv_colon
                    || cv_prg_name,
                       'チェック方法：' || iv_check_class
                    || '、拠点コード：' || in_item_id
                    || '、INV品目コード：' || TO_CHAR(in_item_id)
                    || '、数量：' || TO_CHAR(in_amount)
                    || '、対象日付：' || TO_CHAR(id_date,'YYYY/MM/DD')
                    || '、出庫元ID：' || TO_CHAR(in_deliver_from_id)
                    || '、依頼No：' || iv_request_no
                    || '、エラー区分：' || lv_err_kbn
                    || '、エラー：' || SQLERRM);
-- Ver1.27 M.Hokkanji End
--
--#####################################  固定部 END   ##########################################
--
  END check_shipping_judgment;
--
END xxwsh_common910_pkg;
/
