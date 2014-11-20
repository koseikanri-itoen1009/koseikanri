CREATE OR REPLACE PACKAGE BODY APPS.xxcso_route_common_pkg  
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO_ROUTE_COMMON_PKG(body)
 * Description      : ROUTE関連共通関数
 * MD.050           : XXCSO_View・共通関数一覧
 * Version          : 1.0
 *
 * Program List
 * ----------------------  ----  ----  ------------------------------------------------------
 *  Name                   Type  Ret   Description
 * ----------------------  ----  ----  ------------------------------------------------------
 *  validate_route_no      F     B     ルートＮｏ妥当性チェック
 *  distribute_sales_plan  P     -     売上計画日別配分処理
 *  calc_visit_times       P     -     ルートＮｏ訪問回数算出処理
 *  validate_route_no_p    P     -     ルートＮｏ妥当性チェック(プロシージャ)
 *  isCustomerVendor       F     B     ＶＤ業態判定関数
 *  calc_visit_times_f     F     N     ルートＮｏ訪問回数算出処理(ファンクション)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/16    1.0   Kenji.Sai       新規作成
 *  2008/11/18    1.0   Kenji.Sai       売上計画日別配分処理作成
 *  2008/12/12    1.0   Kazuo.Satomura  ルートＮｏ訪問回数算出処理作成
 *  2008/12/16    1.0   Kenji.Sai       売上計画日別配分処理にパラメータチェック処理追加
 *  2008/12/17    1.0   Noriyuki.Yabuki ルートＮｏ妥当性チェック作成
 *  2009/01/09    1.0   Kazumoto.Tomio  ルートＮｏ妥当性チェック(プロシージャ)作成
 *  2009/01/20    1.0   T.Maruyama      ＶＤ業態判定関数追加
 *  2009/02/19    1.0   Mio.Maruyama    ルートＮｏ訪問回数算出処理(ファンクション)追加
 *  2009/02/27    1.0   Kazuo.Satomura  売上計画日別配分処理桁溢れ対応
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897対応
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
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'xxcso_route_common_pkg'; -- パッケージ名
  cb_true          CONSTANT BOOLEAN := TRUE;
  cb_false         CONSTANT BOOLEAN := FALSE;  
  cv_week_1        CONSTANT VARCHAR2(100) := '月曜日';
  cv_week_2        CONSTANT VARCHAR2(100) := '火曜日';
  cv_week_3        CONSTANT VARCHAR2(100) := '水曜日';
  cv_week_4        CONSTANT VARCHAR2(100) := '木曜日';
  cv_week_5        CONSTANT VARCHAR2(100) := '金曜日';
  cv_week_6        CONSTANT VARCHAR2(100) := '土曜日';
  cv_week_7        CONSTANT VARCHAR2(100) := '日曜日';
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
-- 
  /**********************************************************************************
   * Function Name    : validate_route_no                                                       
   * Description      : ルートＮｏ妥当性チェック
   ***********************************************************************************/
  FUNCTION validate_route_no(
    iv_route_number  IN  VARCHAR2,    -- ルートＮｏ
    ov_error_reason  OUT VARCHAR2     -- エラー理由
  ) RETURN BOOLEAN
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'validate_route_no';  -- プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_sales_appl_short_name  CONSTANT VARCHAR2(5)  := 'XXCSO';             -- アプリケーション短縮名
    cv_msg_number_01          CONSTANT VARCHAR2(20) := 'APP-XXCSO1-00432';  -- 半角数字チェックエラー
    cv_msg_number_02          CONSTANT VARCHAR2(20) := 'APP-XXCSO1-00433';  -- 桁数チェックエラー
    cv_msg_number_03          CONSTANT VARCHAR2(20) := 'APP-XXCSO1-00434';  -- ３桁目チェックエラー
    cv_msg_number_04          CONSTANT VARCHAR2(20) := 'APP-XXCSO1-00435';  -- ３,４桁目整合性チェックエラー
    cv_msg_number_05          CONSTANT VARCHAR2(20) := 'APP-XXCSO1-00436';  -- ５桁目チェックエラー
    cv_msg_number_06          CONSTANT VARCHAR2(20) := 'APP-XXCSO1-00437';  -- ６桁目チェックエラー
    cv_msg_number_07          CONSTANT VARCHAR2(20) := 'APP-XXCSO1-00438';  -- ６,７桁目整合性チェックエラー
    cv_msg_number_08          CONSTANT VARCHAR2(20) := 'APP-XXCSO1-00439';  -- ３,４桁目チェックエラー
    cv_msg_number_09          CONSTANT VARCHAR2(20) := 'APP-XXCSO1-00440';  -- ６,７桁目チェックエラー
    cv_msg_number_10          CONSTANT VARCHAR2(20) := 'APP-XXCSO1-00441';  -- ３,４桁目、６,７桁目チェックエラー
    cv_msg_number_11          CONSTANT VARCHAR2(20) := 'APP-XXCSO1-00442';  -- その他顧客チェックエラー
    cv_msg_number_12          CONSTANT VARCHAR2(20) := 'APP-XXCSO1-00443';  -- 週１回以上顧客チェックエラー
    cv_visit_type_month       CONSTANT VARCHAR2(2)  := '5-';       -- 訪問タイプ＝月単位
    cv_visit_type_season      CONSTANT VARCHAR2(2)  := '6-';       -- 訪問タイプ＝季節単位
    cv_visit_type_other       CONSTANT VARCHAR2(2)  := '9-';       -- 訪問タイプ＝その他
    cv_zero                   CONSTANT VARCHAR2(1)  := '0';        -- 固定値'0'
    cv_third_min              CONSTANT VARCHAR2(1)  := '1';        -- ３桁目のMIN値（週１回以下顧客）
    cv_third_forth_max        CONSTANT VARCHAR2(1)  := '5';        -- ３,４桁目のMAX値（週１回以下顧客）
    cv_sixth_min              CONSTANT VARCHAR2(1)  := '1';        -- ６桁目のMIN値（週１回以下顧客）
    cv_sixth_seventh_max      CONSTANT VARCHAR2(1)  := '7';        -- ６,７桁目のMAX値（週１回以下顧客）
    cv_season_min             CONSTANT VARCHAR2(2)  := '01';       -- ３,４桁目のMIN値（季節取引顧客）
    cv_season_max             CONSTANT VARCHAR2(2)  := '12';       -- ３,４桁目のMAX値（季節取引顧客）
    cv_search_val             CONSTANT VARCHAR2(3)  := '123';      -- 検索対象文字（週１回以上（曜日単位）顧客check用）
    cv_trans_val              CONSTANT VARCHAR2(3)  := '000';      -- 置換対象文字（週１回以上（曜日単位）顧客check用）
    cv_route_number_other     CONSTANT VARCHAR2(7)  := '9-00-00';  -- その他顧客の場合のルートＮｏ
    cv_route_number_day_chk   CONSTANT VARCHAR2(7)  := '0000000';  -- 週１回以上（曜日単位）顧客check用
--
    -- *** ローカル変数 ***
    lv_route_number           VARCHAR2(7);    -- ルートＮｏ退避用
    ln_route_number_length    NUMBER;         -- ルートＮｏの項目長
    lv_route_number_third     VARCHAR2(1);    -- ルートＮｏ３桁目格納用
    lv_route_number_fourth    VARCHAR2(1);    -- ルートＮｏ４桁目格納用
    lv_route_number_sixth     VARCHAR2(1);    -- ルートＮｏ６桁目格納用
    lv_route_number_seventh   VARCHAR2(1);    -- ルートＮｏ７桁目格納用
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
    -- 出力項目の初期化
    ov_error_reason := NULL;
--
    -- 入力パラメータが未入力の場合
    IF ( TRIM( iv_route_number ) IS NULL ) THEN
      RETURN cb_true;
      --
    END IF;
--
    -- ルートＮｏの項目長を取得
    ln_route_number_length := LENGTHB( iv_route_number );
    --
--
    -- ルートＮｏ（ハイフンは除く）の半角数字チェックでエラーの場合
    IF xxccp_common_pkg.chk_number( REPLACE( iv_route_number, '-' ) ) = cb_false THEN
      ov_error_reason := xxccp_common_pkg.get_msg(
                             iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                           , iv_name         => cv_msg_number_01          -- メッセージコード
                         );
      --
      RETURN cb_false;
    END IF;
    --
    -- ルートＮｏが７桁でない場合
    IF ln_route_number_length > 7
      OR ln_route_number_length < 7
    THEN
      ov_error_reason := xxccp_common_pkg.get_msg(
                             iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                           , iv_name         => cv_msg_number_02          -- メッセージコード
                         );
      --
      RETURN cb_false;
      --
    ELSE
      -- INパラメータをレコード変数に代入
      lv_route_number := iv_route_number;
      --
    END IF;
    --
--
    -- ルートＮｏの先頭２桁が'5-'の場合（週１回以下訪問の場合）
    IF ( SUBSTRB( lv_route_number, 1, 2 ) = cv_visit_type_month ) THEN
      -- ルートＮｏの３,４,６,７桁目を取得
      lv_route_number_third   := SUBSTRB( lv_route_number, 3, 1 );
      lv_route_number_fourth  := SUBSTRB( lv_route_number, 4, 1 );
      lv_route_number_sixth   := SUBSTRB( lv_route_number, 6, 1 );
      lv_route_number_seventh := SUBSTRB( lv_route_number, 7, 1 );
      --
      -- ルートＮｏの３桁目が1～5までの数字の場合
      IF lv_route_number_third >= cv_third_min
        AND lv_route_number_third <= cv_third_forth_max
      THEN
        NULL;
        --
      ELSE
        ov_error_reason := xxccp_common_pkg.get_msg(
                               iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                             , iv_name         => cv_msg_number_03          -- メッセージコード
                           );
        --
        RETURN cb_false;
        --
      END IF;
      --
      -- ルートＮｏの３・４桁目整合性チェック
      -- （ルートＮｏの４桁目が３桁目より大きく5以下の数字 または 0である場合）
      IF lv_route_number_fourth > lv_route_number_third
        AND lv_route_number_fourth <= cv_third_forth_max
          OR lv_route_number_fourth = cv_zero
      THEN
        NULL;
        --
      ELSE
        ov_error_reason := xxccp_common_pkg.get_msg(
                               iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                             , iv_name         => cv_msg_number_04          -- メッセージコード
                           );
        --
        RETURN cb_false;
        --
      END IF;
      --
      -- ルートＮｏの５桁目が'-'の場合
      IF SUBSTRB( lv_route_number, 5, 1 ) = '-' THEN
        NULL;
        --
      -- ルートＮｏの５桁目が'-'でない場合
      ELSE
        ov_error_reason := xxccp_common_pkg.get_msg(
                               iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                             , iv_name         => cv_msg_number_05          -- メッセージコード
                           );
        --
        RETURN cb_false;
        --
      END IF;
      --
      -- ルートＮｏの６桁目が1～7までの数字の場合
      IF lv_route_number_sixth >= cv_sixth_min
        AND lv_route_number_sixth <= cv_sixth_seventh_max
      THEN
        NULL;
        --
      ELSE
        ov_error_reason := xxccp_common_pkg.get_msg(
                               iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                             , iv_name         => cv_msg_number_06          -- メッセージコード
                           );
        --
        RETURN cb_false;
        --
      END IF;
      --
      --
      -- ルートＮｏの６・７桁目整合性チェック
      -- （ルートＮｏの７桁目が６桁目より大きく7以下の数字 または 0である場合）
      IF lv_route_number_seventh > lv_route_number_sixth
        AND lv_route_number_seventh <= cv_sixth_seventh_max
          OR lv_route_number_seventh = cv_zero
      THEN
        NULL;
        --
      ELSE
        ov_error_reason := xxccp_common_pkg.get_msg(
                               iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                             , iv_name         => cv_msg_number_07          -- メッセージコード
                           );
        --
        RETURN cb_false;
        --
      END IF;
      --
--
    -- ルートＮｏの先頭２桁が'6-'の場合（季節取引顧客の場合）
    ELSIF ( SUBSTRB( lv_route_number, 1, 2 ) = cv_visit_type_season ) THEN
      -- ルートＮｏの３,４桁目に'-'が含まれていないこと
      IF SUBSTRB( lv_route_number, 3, 1 ) = '-'
        OR SUBSTRB( lv_route_number, 4, 1) = '-'
      THEN
        ov_error_reason := xxccp_common_pkg.get_msg(
                               iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                             , iv_name         => cv_msg_number_08          -- メッセージコード
                           );
        --
        RETURN cb_false;
        --
      END IF;
      --
      -- ルートＮｏの３,４桁目が01～12であること
      IF SUBSTRB( lv_route_number, 3, 2 ) >= cv_season_min
        AND SUBSTRB( lv_route_number, 3, 2 ) <= cv_season_max
      THEN
        NULL;
        --
      ELSE
        ov_error_reason := xxccp_common_pkg.get_msg(
                               iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                             , iv_name         => cv_msg_number_08          -- メッセージコード
                           );
        --
        RETURN cb_false;
        --
      END IF;
      --
      -- ルートＮｏの５桁目が'-'の場合
      IF SUBSTRB( lv_route_number, 5, 1 ) = '-' THEN
        NULL;
        --
      -- ルートＮｏの５桁目が'-'でない場合
      ELSE
        ov_error_reason := xxccp_common_pkg.get_msg(
                               iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                             , iv_name         => cv_msg_number_05          -- メッセージコード
                           );
        --
        RETURN cb_false;
        --
      END IF;
      --
      -- ルートＮｏの６,７桁目に'-'が含まれていないこと
      IF SUBSTRB( lv_route_number, 6, 1 ) = '-'
        OR SUBSTRB( lv_route_number, 7, 1) = '-'
      THEN
        ov_error_reason := xxccp_common_pkg.get_msg(
                               iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                             , iv_name         => cv_msg_number_09          -- メッセージコード
                           );
        --
        RETURN cb_false;
        --
      END IF;
      --
      -- ルートＮｏの６,７桁目が01～12であること
      IF SUBSTRB( lv_route_number, 6, 2 ) >= cv_season_min
        AND SUBSTRB( lv_route_number, 6, 2 ) <= cv_season_max
      THEN
        NULL;
        --
      ELSE
        ov_error_reason := xxccp_common_pkg.get_msg(
                               iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                             , iv_name         => cv_msg_number_09          -- メッセージコード
                           );
        --
        RETURN cb_false;
        --
      END IF;
      --
      -- ルートＮｏの３,４桁目と６,７桁目が異なること（同じ場合はエラー）
      IF SUBSTRB( lv_route_number, 3, 2 ) = SUBSTRB( lv_route_number, 6, 2 ) THEN
        ov_error_reason := xxccp_common_pkg.get_msg(
                               iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                             , iv_name         => cv_msg_number_10          -- メッセージコード
                           );
        --
        RETURN cb_false;
        --
      END IF;
      --
--
    -- ルートＮｏの先頭２桁が'9-'の場合（その他顧客の場合）
    ELSIF ( SUBSTRB( lv_route_number, 1, 2 ) = cv_visit_type_other ) THEN
      -- '9-00-00'であること
      IF lv_route_number = cv_route_number_other THEN
        NULL;
        --
      ELSE
        ov_error_reason := xxccp_common_pkg.get_msg(
                               iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                             , iv_name         => cv_msg_number_11          -- メッセージコード
                           );
        --
        RETURN cb_false;
        --
      END IF;
--
    -- ルートＮｏの先頭２桁が'5-','6-','9-'以外の場合
    ELSE
      -- 全ての桁が0～3の数字であること
      IF TRANSLATE( lv_route_number, cv_search_val, cv_trans_val ) = cv_route_number_day_chk THEN
        NULL;
        --
      ELSE
        ov_error_reason := xxccp_common_pkg.get_msg(
                               iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                             , iv_name         => cv_msg_number_12          -- メッセージコード
                           );
        --
        RETURN cb_false;
        --
      END IF;
      --
    END IF;
--
   -- 戻り値
    RETURN cb_true;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_error_reason := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      RETURN cb_false;
--
--#####################################  固定部 END   ##########################################
--
  END validate_route_no;
--
--
  /**********************************************************************************
   * Procedure Name   : distribute_sales_plan                                                       
   * Description      : 売上計画日別配分処理
   ***********************************************************************************/
  PROCEDURE distribute_sales_plan(
    iv_year_month                  IN VARCHAR2,                                            -- 年月（書式：YYYYMM）
    it_sales_plan_amt              IN xxcso_in_sales_plan_month.sales_plan_amt%TYPE,       -- 月間売上計画金額
    it_route_number                IN xxcso_in_route_no.route_no%TYPE,                     -- ルートＮｏ 
    on_day_on_month                OUT NUMBER,                                             -- 当該月の日数
    on_visit_daytimes              OUT NUMBER,                                             -- 当該月の訪問日数
    ot_sales_plan_day_amt_1        OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 1日目日別売上計画金額
    ot_sales_plan_day_amt_2        OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 2日目日別売上計画金額
    ot_sales_plan_day_amt_3        OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 3日目日別売上計画金額
    ot_sales_plan_day_amt_4        OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 4日目日別売上計画金額
    ot_sales_plan_day_amt_5        OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 5日目日別売上計画金額
    ot_sales_plan_day_amt_6        OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 6日目日別売上計画金額
    ot_sales_plan_day_amt_7        OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 7日目日別売上計画金額
    ot_sales_plan_day_amt_8        OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 8日目日別売上計画金額
    ot_sales_plan_day_amt_9        OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 9日目日別売上計画金額
    ot_sales_plan_day_amt_10       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 10日目日別売上計画金額
    ot_sales_plan_day_amt_11       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 11日目日別売上計画金額
    ot_sales_plan_day_amt_12       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 12日目日別売上計画金額
    ot_sales_plan_day_amt_13       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 13日目日別売上計画金額
    ot_sales_plan_day_amt_14       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 14日目日別売上計画金額
    ot_sales_plan_day_amt_15       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 15日目日別売上計画金額
    ot_sales_plan_day_amt_16       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 16日目日別売上計画金額
    ot_sales_plan_day_amt_17       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 17日目日別売上計画金額
    ot_sales_plan_day_amt_18       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 18日目日別売上計画金額
    ot_sales_plan_day_amt_19       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 19日目日別売上計画金額
    ot_sales_plan_day_amt_20       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 20日目日別売上計画金額
    ot_sales_plan_day_amt_21       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 21日目日別売上計画金額
    ot_sales_plan_day_amt_22       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 22日目日別売上計画金額
    ot_sales_plan_day_amt_23       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 23日目日別売上計画金額
    ot_sales_plan_day_amt_24       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 24日目日別売上計画金額
    ot_sales_plan_day_amt_25       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 25日目日別売上計画金額
    ot_sales_plan_day_amt_26       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 26日目日別売上計画金額
    ot_sales_plan_day_amt_27       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 27日目日別売上計画金額
    ot_sales_plan_day_amt_28       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 28日目日別売上計画金額
    ot_sales_plan_day_amt_29       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 29日目日別売上計画金額
    ot_sales_plan_day_amt_30       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 30日目日別売上計画金額
    ot_sales_plan_day_amt_31       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 31日目日別売上計画金額
    ov_errbuf                      OUT NOCOPY VARCHAR2,  -- エラー・メッセージ            --# 固定 #
    ov_retcode                     OUT NOCOPY VARCHAR2,  -- リターン・コード              --# 固定 #
    ov_errmsg                      OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'distribute_sales_plan'; -- プログラム名
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
    cv_sales_appl_short_name   CONSTANT VARCHAR2(5)  := 'XXCSO';            -- アプリケーション短縮名
    cv_tkn_number_01           CONSTANT VARCHAR2(20) := 'APP-XXCSO1-00325'; -- パラメータ必須エラー
    cv_tkn_number_02           CONSTANT VARCHAR2(20) := 'APP-XXCSO1-00252'; -- パラメータ妥当性チェックエラーメッセージ
    cv_tkn_number_03           CONSTANT VARCHAR2(20) := 'APP-XXCSO1-00547'; -- 按分処理桁数オーバ
    cv_tkn_parm_name           CONSTANT VARCHAR2(20) := 'PARAM_NAME';       -- パラメータ
    cv_tkn_item                CONSTANT VARCHAR2(20) := 'ITEM';             -- アイテム
    cv_tkn_val_ym_name         CONSTANT VARCHAR2(20) := '年月';             -- パラメータ名:年月
    cv_tkn_val_amt_name        CONSTANT VARCHAR2(20) := '月間売上計画金額'; -- パラメータ名:月別売上計画金額
    cv_tkn_val_route_name      CONSTANT VARCHAR2(20) := 'ルートＮｏ';       -- パラメータ名:ルートNo
    cv_visit_type_0            CONSTANT VARCHAR2(1)  := '0';                -- 訪問タイプ＝週1回以上(0)
    cv_visit_type_1            CONSTANT VARCHAR2(1)  := '1';                -- 訪問タイプ＝週1回以上(1)
    cv_visit_type_2            CONSTANT VARCHAR2(1)  := '2';                -- 訪問タイプ＝週1回以上(2)
    cv_visit_type_3            CONSTANT VARCHAR2(1)  := '3';                -- 訪問タイプ＝週1回以上(3)
    cv_visit_type_5            CONSTANT VARCHAR2(1)  := '5';                -- 訪問タイプ＝週2回以下(5)
    cv_visit_type_6            CONSTANT VARCHAR2(1)  := '6';                -- 訪問タイプ＝季節単位(6)
    cv_visit_type_9            CONSTANT VARCHAR2(1)  := '9';                -- 訪問タイプ＝その他(9)    
--
    -- *** テーブル型定義 ***
    -- 月別売上計画ワークテーブル＆関連情報抽出データ
    TYPE l_sales_plan_day_rtype IS RECORD(
      sales_plan_day_amt      xxcso_in_sales_plan_month.sales_plan_amt%TYPE,     -- 売上計画金額
      houmon_flg              number                                             -- 訪問フラグ
    );    
    TYPE l_sales_plan_day_ttype IS TABLE OF l_sales_plan_day_rtype INDEX BY PLS_INTEGER;
-- １ヶ月以内で指定訪問曜日に該当する日にちを格納するデータ
    TYPE l_day_one_week_ttype IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;               -- １週間以内の日にち
    TYPE l_all_day_week_ttype IS TABLE OF l_day_one_week_ttype INDEX BY BINARY_INTEGER; -- 各週ごとに日にちを格納
--
    -- *** ローカル変数 ***
--
    lv_year_month                  VARCHAR2(6);                                   -- 年月（書式：YYYYMM）
    lt_sales_plan_amt              xxcso_in_sales_plan_month.sales_plan_amt%TYPE; -- 月額売上金額
    lt_route_number                xxcso_in_route_no.route_no%TYPE; -- ルートＮｏ 
    l_sales_plan_day_on_month_tbl  l_sales_plan_day_ttype;          -- 実際の月の日にち分の日別売上計画データ
    ln_day_on_month                NUMBER;                          -- 該当月の日数
    ln_cnt_houmon_day              NUMBER;                          -- 該当月の訪問日数
    ln_sales_plan_day              NUMBER;                          -- 訪問日数
    ln_loop_cnt                    NUMBER;                          -- ループ用変数
    ln_cnt_first_houmon            NUMBER;                          -- 最初訪問日を判断する訪問日カウント変数
    lt_sales_plan_day_amt          xxcso_account_sales_plans.sales_plan_day_amt%TYPE;
-- ルートNoに配分された訪問日の日別売上計画金額
    lv_day_for_houmon              VARCHAR2(100);                   -- 訪問日に該当する曜日リスト
    l_week_day_tab                 g_day_of_week_ttype;             -- 月曜日0日曜日を格納するテーブル型変数
    lv_day_on_week                 VARCHAR2(20);                    -- 該当日にちの曜日 
    ln_houmon_week1                NUMBER;                          -- 週１回以下訪問時の、１回目の週
    ln_houmon_week2                NUMBER;                          -- 週１回以下訪問時の、２回目の週
    ln_week_cnt                    NUMBER;                          -- 週カウント用
    lv_day_for_yymm01              VARCHAR2(20);                    -- 月初めの曜日  
    l_all_day_week_tab             l_all_day_week_ttype;            -- 各週ごとに日にちを2次元で格納する変数
    ln_day_week2                   NUMBER;                          -- 2週目の月曜日に該当する日にち
    ln_day_houmon_number1          NUMBER;                          -- 週2回以下訪問時、ルールNo6番目数字
    ln_day_houmon_number2          NUMBER;                          -- 週2回以下訪問時、ルールNo7番目数字  
    ln_i                           NUMBER;                          -- ループ用
    ln_j                           NUMBER;                          -- ループ用
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
    -- パラメータチェック 
    -- 入力パラメータ:年月が未入力の場合
    IF iv_year_month IS NULL THEN
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_01         -- メッセージコード
                     ,iv_token_name1  => cv_tkn_parm_name         -- トークンコード1
                     ,iv_token_value1 => cv_tkn_val_ym_name       -- トークン値1
                  );
      lv_retcode := cv_status_error;
      RAISE global_api_others_expt;
    -- 入力パラメータ:月別売上計画金額が未入力の場合
    ELSIF it_sales_plan_amt IS NULL THEN
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_01         -- メッセージコード
                     ,iv_token_name1  => cv_tkn_parm_name         -- トークンコード1
                     ,iv_token_value1 => cv_tkn_val_amt_name      -- トークン値1
                  );
      lv_retcode := cv_status_error;
      RAISE global_api_others_expt;
    -- 入力パラメータ:ルートNoが未入力の場合
    ELSIF it_route_number IS NULL THEN
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_01         -- メッセージコード
                     ,iv_token_name1  => cv_tkn_parm_name         -- トークンコード1
                     ,iv_token_value1 => cv_tkn_val_route_name    -- トークン値1
                  );
      lv_retcode := cv_status_error;
      RAISE global_api_others_expt;
    END IF; 
--
    -- INパラメータをレコード変数に代入
    lv_year_month         := iv_year_month;              -- 年月（書式：YYYYMM）
    lt_sales_plan_amt     := it_sales_plan_amt;          -- 月間売上計画金額
    lt_route_number       := it_route_number;            -- ルートＮｏ 
--
    -- **DEBUG**
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '年月:'             || lv_year_month              || CHR(10) ||
                 '月別売上計画金額:' || TO_CHAR(lt_sales_plan_amt) || CHR(10) ||
                 'ルートNo:'         || TO_CHAR(lt_route_number)   || CHR(10)
    );
    -- **DEBUG**
    -- ルートNo妥当性チェック
    IF SUBSTR(it_route_number,1,1) NOT IN (cv_visit_type_0,
                                           cv_visit_type_1,
                                           cv_visit_type_2,
                                           cv_visit_type_3,
                                           cv_visit_type_5,
                                           cv_visit_type_6,
                                           cv_visit_type_9) 
         OR LENGTHB(it_route_number) <> 7 THEN
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_02         -- メッセージコード
                     ,iv_token_name1  => cv_tkn_item              -- トークンコード1
                     ,iv_token_value1 => cv_tkn_val_route_name    -- トークン値1
                  );
      lv_retcode := cv_status_error;
      RAISE global_api_others_expt;
    END IF; 
--  
    -- 曜日を変数にセット
    l_week_day_tab(1)     := cv_week_1;                  -- '月曜日'
    l_week_day_tab(2)     := cv_week_2;                  -- '火曜日'
    l_week_day_tab(3)     := cv_week_3;                  -- '水曜日'
    l_week_day_tab(4)     := cv_week_4;                  -- '木曜日'
    l_week_day_tab(5)     := cv_week_5;                  -- '金曜日'
    l_week_day_tab(6)     := cv_week_6;                  -- '土曜日'
    l_week_day_tab(7)     := cv_week_7;                  -- '日曜日'
    -- 訪問日数の初期化
    ln_cnt_houmon_day     := 0;
    -- 最初訪問日を判断する変数の初期化
    ln_cnt_first_houmon   := 0;
--
    -- 該当月の日数を取得
    ln_day_on_month := TO_NUMBER(TO_CHAR(LAST_DAY(TO_DATE(lv_year_month||'01', 'YYYYMMDD')),'DD')); 
--
    -- 訪問曜日リスト初期化
    lv_day_for_houmon := '';
--  
    -- ===============================================
    -- 1.週１回以上訪問の場合
    -- ===============================================
    IF SUBSTR(lt_route_number,1,1)   = cv_visit_type_0
      OR SUBSTR(lt_route_number,1,1) = cv_visit_type_1
      OR SUBSTR(lt_route_number,1,1) = cv_visit_type_2
      OR SUBSTR(lt_route_number,1,1) = cv_visit_type_3 THEN
--
      -- ルートNOにより、訪問曜日リストを作成
      <<create_houmon_day_week>>
      FOR ln_loop_cnt IN 1..7 LOOP
        IF (SUBSTR(lt_route_number,ln_loop_cnt,1)  = cv_visit_type_1
          OR SUBSTR(lt_route_number,ln_loop_cnt,1) = cv_visit_type_2
          OR SUBSTR(lt_route_number,ln_loop_cnt,1) = cv_visit_type_3) THEN
          lv_day_for_houmon := lv_day_for_houmon||l_week_day_tab(ln_loop_cnt);
        END IF;
      END LOOP create_houmon_day_week;
--
      -- 訪問日数の計算
      <<get_sales_day_loop>>
      FOR ln_loop_cnt IN 1..ln_day_on_month LOOP
        -- 該当日にちの曜日取得
        lv_day_on_week := TO_CHAR(TO_DATE(lv_year_month||LPAD(TO_CHAR(ln_loop_cnt), 2, '0'), 'YYYYMMDD'), 'Day');
        -- 訪問日に該当する日別売上計画データの訪問フラグの初期化（0をセット)
        l_sales_plan_day_on_month_tbl(ln_loop_cnt).houmon_flg := 0; 
        -- 訪問日に該当する日数を計算
        IF (INSTR(lv_day_for_houmon, lv_day_on_week) >= 1) THEN
          ln_cnt_houmon_day := ln_cnt_houmon_day + 1;
          -- 訪問日に該当する日別売上計画データの訪問フラグに'1'をセット
          l_sales_plan_day_on_month_tbl(ln_loop_cnt).houmon_flg := 1; 
        END IF;
      END LOOP get_sales_day_loop;
    END IF;
--    
    -- ===============================================
    -- 2.週2回以下訪問の場合
    -- ===============================================
    -- 先頭文字のチェック
    IF SUBSTR(lt_route_number,1,1)   = cv_visit_type_5 THEN
      -- 週＊曜日の２次元配列の日にち初期化
      FOR ln_i in 1..6 LOOP        -- 週
        FOR ln_j in 1..7 LOOP      -- 曜日
          l_all_day_week_tab(ln_i)(ln_j) := 0;
        END LOOP;
      END LOOP;    
      -- 該当年月の１日目の曜日を取得
      lv_day_for_yymm01 := TO_CHAR(TO_DATE(lv_year_month||'01', 'YYYYMMDD'), 'Day');
      -- １日目の曜日により、配列に１週目の日にちをセット
      ln_week_cnt := 1;
      <<get_day_week1>>
      FOR ln_i in 1..7 LOOP  
        -- １日目のの曜日チェック    
        IF lv_day_for_yymm01 = l_week_day_tab(ln_i) THEN
          -- 1週目の日にちをセット
          <<set_day_fir_week>>
          FOR ln_j in ln_i..7 LOOP
            l_sales_plan_day_on_month_tbl(ln_j-ln_i+1).houmon_flg := 0;
            l_all_day_week_tab(1)(ln_j)                           := ln_j - ln_i + 1;
          END LOOP set_day_fir_week;
          -- 2週目月曜日に該当する日にちセット後ループを抜ける
          ln_day_week2 := l_all_day_week_tab(1)(7) + 1;
          EXIT;
        END IF;
      END LOOP get_day_week1;
      -- 2週目以降の日にちセット
      ln_loop_cnt := ln_day_week2;
      <<get_day_week2>>
      LOOP
        ln_week_cnt := ln_week_cnt + 1;    -- 週カウント
        -- 2週目以降の日にちをセット
        <<set_day_after_week>>
        FOR ln_j in 1..7 LOOP
            l_sales_plan_day_on_month_tbl(ln_loop_cnt).houmon_flg := 0;
            IF ln_loop_cnt <= ln_day_on_month THEN
               l_all_day_week_tab(ln_week_cnt)(ln_j)   := ln_loop_cnt;
               ln_loop_cnt                             := ln_loop_cnt + 1; 
            END IF;                                       
        END LOOP set_day_after_week;
        IF ln_loop_cnt > ln_day_on_month THEN 
          EXIT;
        END IF;
      END LOOP get_day_week2;
--
      -- ルートNOにより、訪問曜日リストを作成
      -- ルートNoの３番目数字により訪問週を取得
      ln_houmon_week1 := TO_NUMBER(SUBSTR(lt_route_number,3,1));
      -- ルートNoの４番目数字により訪問週を取得
      ln_houmon_week2 := TO_NUMBER(SUBSTR(lt_route_number,4,1));
      -- ルートNoの６番目数字により、訪問曜日を取得
      ln_day_houmon_number1 := TO_NUMBER(SUBSTR(lt_route_number,6,1));
      -- ルートNoの７番目数字により、訪問曜日を取得
      ln_day_houmon_number2 := TO_NUMBER(SUBSTR(lt_route_number,7,1));
--
      -- 訪問日数初期化
      ln_cnt_houmon_day := 0;
      -- 週ごとにセットした日にちデータが有効データである場合
      -- 1週目訪問が存在する場合のの訪問日セット
      IF ln_houmon_week1 > 0 THEN
        -- ルートNoの６番目に０より大きい数字がセットされている場合
        IF ln_day_houmon_number1 > 0 THEN
          IF l_all_day_week_tab(ln_houmon_week1)(ln_day_houmon_number1) >= 1 THEN
            ln_cnt_houmon_day := ln_cnt_houmon_day + 1;  -- 訪問日数カウント
            -- 該当する日にちに訪問フラグをセット
            l_sales_plan_day_on_month_tbl(l_all_day_week_tab(ln_houmon_week1)(ln_day_houmon_number1)).houmon_flg := 1; 
          END IF;
        END IF;
        -- ルートNoの７番目に０より大きい数字がセットされている場合
        IF ln_day_houmon_number2 > 0 THEN
          IF l_all_day_week_tab(ln_houmon_week1)(ln_day_houmon_number2) >= 1 THEN
            ln_cnt_houmon_day := ln_cnt_houmon_day + 1;  -- 訪問日数カウント
            -- 該当する日にちに訪問フラグをセット
            l_sales_plan_day_on_month_tbl(l_all_day_week_tab(ln_houmon_week1)(ln_day_houmon_number2)).houmon_flg := 1; 
          END IF;
        END IF;
      END IF;
      -- 2週目訪問が存在する場合の訪問日セット
      IF ln_houmon_week2 > 0 THEN
        -- ルートNoの６番目に０より大きい数字がセットされている場合
        IF ln_day_houmon_number1 > 0 THEN
          IF l_all_day_week_tab(ln_houmon_week2)(ln_day_houmon_number1) >= 1 THEN
            ln_cnt_houmon_day := ln_cnt_houmon_day + 1;  -- 訪問日数カウント
            -- 該当する日にちに訪問フラグをセット
            l_sales_plan_day_on_month_tbl(l_all_day_week_tab(ln_houmon_week2)(ln_day_houmon_number1)).houmon_flg := 1; 
          END IF;
        END IF;
        -- ルートNoの７番目に０より大きい数字がセットされている場合
        IF ln_day_houmon_number2 > 0 THEN
          IF l_all_day_week_tab(ln_houmon_week2)(ln_day_houmon_number2) >= 1 THEN
            ln_cnt_houmon_day := ln_cnt_houmon_day + 1;  -- 訪問日数カウント
            -- 該当する日にちに訪問フラグをセット
            l_sales_plan_day_on_month_tbl(l_all_day_week_tab(ln_houmon_week2)(ln_day_houmon_number2)).houmon_flg := 1; 
          END IF;
        END IF;
      END IF;
    END IF; 
--
    -- 週１回以上、１回以下訪問の場合のみ（区分が0,1,2,3,5）、按分処理を行う
    IF SUBSTR(lt_route_number,1,1)   = cv_visit_type_0
      OR SUBSTR(lt_route_number,1,1) = cv_visit_type_1
      OR SUBSTR(lt_route_number,1,1) = cv_visit_type_2
      OR SUBSTR(lt_route_number,1,1) = cv_visit_type_3 
      OR SUBSTR(lt_route_number,1,1) = cv_visit_type_5 THEN
--
      -- 訪問日数が０の場合、エラー 
      IF ln_cnt_houmon_day = 0 THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_02         -- メッセージコード
                       ,iv_token_name1  => cv_tkn_item              -- トークンコード1
                       ,iv_token_value1 => cv_tkn_val_route_name    -- トークン値1
                    );
        lv_retcode := cv_status_error;
        RAISE global_api_others_expt;
      END IF;
--
      -- ルートNoにより配分された訪問日の日別売上計画金額の計算
      BEGIN
        lt_sales_plan_day_amt := TRUNC(lt_sales_plan_amt/ln_cnt_houmon_day);
      EXCEPTION
        WHEN VALUE_ERROR THEN
          -- 桁溢れが発生した場合
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_03         -- メッセージコード
                      );
          ov_errbuf  := cv_pkg_name || cv_msg_cont ||cv_prg_name || cv_msg_part || lv_errbuf;
          ov_retcode := cv_status_error;
          ov_errmsg  := lv_errbuf;
          RETURN;
      END;
--
      -- 訪問フラグがセットされている訪問日について売上計画金額をセット
      <<distribute_sales_loop>>
      FOR ln_loop_cnt IN 1..ln_day_on_month LOOP
        -- 該当日が訪問日の場合、日別売上計画金額をセット
        IF (l_sales_plan_day_on_month_tbl(ln_loop_cnt).houmon_flg = 1) THEN
          -- 訪問日数のカウント
          ln_cnt_first_houmon := ln_cnt_first_houmon + 1;
          -- 日別売上金額のセット
          l_sales_plan_day_on_month_tbl(ln_loop_cnt).sales_plan_day_amt := lt_sales_plan_day_amt;
          -- 最初訪問日の日別売上金額の調整
          IF ln_cnt_first_houmon = '1' THEN
             l_sales_plan_day_on_month_tbl(ln_loop_cnt).sales_plan_day_amt := 
               lt_sales_plan_amt - lt_sales_plan_day_amt*(ln_cnt_houmon_day-1);
          END IF;
        END IF;
      END LOOP distribute_sales_loop;
    END IF;
--
    -- ===============================================
    -- 3.季節取引顧客の場合、またはその他
    -- ===============================================
    IF (SUBSTR(lt_route_number,1,1)       = cv_visit_type_6
         OR SUBSTR(lt_route_number,1,1)   = cv_visit_type_9) THEN
      -- 訪問フラグの初期化
      <<distribute_sales_loop>>
      FOR ln_loop_cnt IN 1..ln_day_on_month LOOP
        l_sales_plan_day_on_month_tbl(ln_loop_cnt).houmon_flg := 0;
      END LOOP distribute_sales_loop;
      -- 訪問日数に１をセット
      ln_cnt_houmon_day := 1;
      -- 最終日に訪問フラグセット、月別売上計画データをセット
      l_sales_plan_day_on_month_tbl(ln_day_on_month).houmon_flg         := 1;
     l_sales_plan_day_on_month_tbl(ln_day_on_month).sales_plan_day_amt := lt_sales_plan_amt;
    END IF;
--   
    -- 当該月の日数をOUTパラメータにセット
    on_day_on_month          := ln_day_on_month;    
    on_visit_daytimes        := ln_cnt_houmon_day;
--
    -- 日別売上計画金額をOUTパラメータにセット
    ot_sales_plan_day_amt_1  := l_sales_plan_day_on_month_tbl(1).sales_plan_day_amt;
    ot_sales_plan_day_amt_2  := l_sales_plan_day_on_month_tbl(2).sales_plan_day_amt;
    ot_sales_plan_day_amt_3  := l_sales_plan_day_on_month_tbl(3).sales_plan_day_amt;
    ot_sales_plan_day_amt_4  := l_sales_plan_day_on_month_tbl(4).sales_plan_day_amt;
    ot_sales_plan_day_amt_5  := l_sales_plan_day_on_month_tbl(5).sales_plan_day_amt;
    ot_sales_plan_day_amt_6  := l_sales_plan_day_on_month_tbl(6).sales_plan_day_amt;
    ot_sales_plan_day_amt_7  := l_sales_plan_day_on_month_tbl(7).sales_plan_day_amt;
    ot_sales_plan_day_amt_8  := l_sales_plan_day_on_month_tbl(8).sales_plan_day_amt;
    ot_sales_plan_day_amt_9  := l_sales_plan_day_on_month_tbl(9).sales_plan_day_amt;
    ot_sales_plan_day_amt_10 := l_sales_plan_day_on_month_tbl(10).sales_plan_day_amt;
    ot_sales_plan_day_amt_11 := l_sales_plan_day_on_month_tbl(11).sales_plan_day_amt;
    ot_sales_plan_day_amt_12 := l_sales_plan_day_on_month_tbl(12).sales_plan_day_amt;
    ot_sales_plan_day_amt_13 := l_sales_plan_day_on_month_tbl(13).sales_plan_day_amt;
    ot_sales_plan_day_amt_14 := l_sales_plan_day_on_month_tbl(14).sales_plan_day_amt;
    ot_sales_plan_day_amt_15 := l_sales_plan_day_on_month_tbl(15).sales_plan_day_amt;
    ot_sales_plan_day_amt_16 := l_sales_plan_day_on_month_tbl(16).sales_plan_day_amt;
    ot_sales_plan_day_amt_17 := l_sales_plan_day_on_month_tbl(17).sales_plan_day_amt;
    ot_sales_plan_day_amt_18 := l_sales_plan_day_on_month_tbl(18).sales_plan_day_amt;
    ot_sales_plan_day_amt_19 := l_sales_plan_day_on_month_tbl(19).sales_plan_day_amt;
    ot_sales_plan_day_amt_20 := l_sales_plan_day_on_month_tbl(20).sales_plan_day_amt;
    ot_sales_plan_day_amt_21 := l_sales_plan_day_on_month_tbl(21).sales_plan_day_amt;
    ot_sales_plan_day_amt_22 := l_sales_plan_day_on_month_tbl(22).sales_plan_day_amt;
    ot_sales_plan_day_amt_23 := l_sales_plan_day_on_month_tbl(23).sales_plan_day_amt;
    ot_sales_plan_day_amt_24 := l_sales_plan_day_on_month_tbl(24).sales_plan_day_amt;
    ot_sales_plan_day_amt_25 := l_sales_plan_day_on_month_tbl(25).sales_plan_day_amt;
    ot_sales_plan_day_amt_26 := l_sales_plan_day_on_month_tbl(26).sales_plan_day_amt;
    ot_sales_plan_day_amt_27 := l_sales_plan_day_on_month_tbl(27).sales_plan_day_amt;
    ot_sales_plan_day_amt_28 := l_sales_plan_day_on_month_tbl(28).sales_plan_day_amt;
    -- 当該月の日数により、２９日～３１日までのデータセット処理を行う
    IF ln_day_on_month > 28 THEN
      ot_sales_plan_day_amt_29 := l_sales_plan_day_on_month_tbl(29).sales_plan_day_amt;
    END IF;
    IF ln_day_on_month > 29 THEN
      ot_sales_plan_day_amt_30 := l_sales_plan_day_on_month_tbl(30).sales_plan_day_amt;
    END IF;
    IF ln_day_on_month > 30 THEN
      ot_sales_plan_day_amt_31 := l_sales_plan_day_on_month_tbl(31).sales_plan_day_amt;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
      ov_errmsg  := lv_errbuf;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END distribute_sales_plan;
--
  /**********************************************************************************
   * Procedure Name   : calc_visit_times
   * Description      : ルートＮｏ訪問回数算出処理
   ***********************************************************************************/
  PROCEDURE calc_visit_times(
     it_route_number IN         xxcso_in_route_no.route_no%TYPE -- ルートＮｏ
    ,on_times        OUT NOCOPY NUMBER                          -- 訪問回数
    ,ov_errbuf       OUT NOCOPY VARCHAR2                        -- エラー・メッセージ            --# 固定 #
    ,ov_retcode      OUT NOCOPY VARCHAR2                        -- リターン・コード              --# 固定 #
    ,ov_errmsg       OUT NOCOPY VARCHAR2                        -- ユーザー・エラー・メッセージ  --# 固定 #
  ) IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'calc_visit_times'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000); -- エラー・メッセージ
    lv_retcode VARCHAR2(1);    -- リターン・コード
    lv_errmsg  VARCHAR2(5000); -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_sales_appl_short_name CONSTANT VARCHAR2(5)  := 'XXCSO';            -- アプリケーション短縮名
    cv_tkn_number_01         CONSTANT VARCHAR2(20) := 'APP-XXCSO1-00325'; -- パラメータ必須エラー
    cv_tkn_number_02         CONSTANT VARCHAR2(20) := 'APP-XXCSO1-00252'; -- パラメータ妥当性チェックエラーメッセージ
    cv_tkn_parm_name         CONSTANT VARCHAR2(20) := 'PARAM_NAME';       -- パラメータ
    cv_tkn_item              CONSTANT VARCHAR2(20) := 'ITEM';             -- アイテム
    cv_tkn_value_parm_name   CONSTANT VARCHAR2(20) := 'ルートＮｏ';       -- パラメータ名
    cv_tkn_value_item        CONSTANT VARCHAR2(20) := 'ルートＮｏ';       -- アイテム名
    cv_visit_type_week1      CONSTANT VARCHAR2(1)  := '0';                -- 訪問タイプ＝週単位
    cv_visit_type_week2      CONSTANT VARCHAR2(1)  := '3';                -- 訪問タイプ＝週単位
    cv_visit_type_month      CONSTANT VARCHAR2(2)  := '5-';               -- 訪問タイプ＝月単位
    cv_visit_type_season     CONSTANT VARCHAR2(2)  := '6-';               -- 訪問タイプ＝季節単位
    cv_visit_type_other      CONSTANT VARCHAR2(2)  := '9-';               -- 訪問タイプ＝その他
    cn_multiplication_no     CONSTANT NUMBER       := 4;                  -- 週単位の場合の乗算値
    cn_visit_day_unit_from   CONSTANT NUMBER       := 6;                  -- 月単位の場合の曜日開始桁数
    cn_visit_day_unit_to     CONSTANT NUMBER       := 7;                  -- 月単位の場合の曜日終了桁数
    cn_visit_week_unit_from  CONSTANT NUMBER       := 3;                  -- 月単位の場合の週開始桁数
    cn_visit_week_unit_to    CONSTANT NUMBER       := 4;                  -- 月単位の場合の週終了桁数
    cn_visit_count_other     CONSTANT NUMBER       := 1;                  -- その他の場合の固定訪問回数
    --
    cv_zero CONSTANT VARCHAR2(1) := '0';
    cn_one  CONSTANT NUMBER      := 1;
    --
    -- *** ローカル変数 ***
    lt_route_number        xxcso_in_route_no.route_no%TYPE; -- ルートＮｏ退避用
    ln_route_number_length NUMBER;                          -- ルートＮｏの項目長
    ln_route_number_work   NUMBER;                          -- ルート回数加算のワーク領域
    ln_route_number_week   NUMBER;                          -- 月単位の場合の週訪問回数ワーク領域
    ln_route_number_month  NUMBER;                          -- 月単位の場合の月訪問回数ワーク領域
    ln_loop_count          NUMBER;                          -- ループ用変数
    ln_visit_count         NUMBER;                          -- 訪問回数
    --
    -- *** ローカル・カーソル ***
    --
    -- *** ローカル・レコード ***
    --
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    lv_errbuf  := NULL;
    lv_retcode := cv_status_normal;
    lv_errmsg  := NULL;
--
--###########################  固定部 END   ############################
--
    -- 各変数の初期化
    ln_route_number_length := 0; -- ルートＮｏの項目長
    ln_route_number_work   := 0; -- ルート回数加算のワーク領域
    ln_route_number_week   := 0; -- 月単位の場合の週訪問回数ワーク領域
    ln_route_number_month  := 0; -- 月単位の場合の月訪問回数ワーク領域
    ln_visit_count         := 0; -- 訪問回数
    --
    IF (TRIM(it_route_number) IS NULL) THEN
      -- 入力パラメータが未入力の場合
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_01         -- メッセージコード
                     ,iv_token_name1  => cv_tkn_parm_name         -- トークンコード1
                     ,iv_token_value1 => cv_tkn_value_parm_name   -- トークン値1
                  );
      --
      lv_retcode := cv_status_error;
      --
    ELSE
      -- INパラメータをレコード変数に代入
      lt_route_number := it_route_number;
      --
      -- ルートＮｏの項目長を取得
      ln_route_number_length := LENGTHB(lt_route_number);
      --
      IF (SUBSTRB(lt_route_number, 1, 1) BETWEEN cv_visit_type_week1
        AND cv_visit_type_week2)
      THEN
        -- ルートNOの先頭1桁が'0'～'3'の場合
        ln_loop_count := 1;
        --
        <<route_number_loop1>>
        LOOP
          IF (ln_loop_count > ln_route_number_length) THEN
            -- ループ回数がルートＮｏの項目長を超えたらループを抜ける
            EXIT;
            --
          END IF;
          --
          -- 各桁の訪問回数を加算
          ln_route_number_work := ln_route_number_work + TO_NUMBER(SUBSTRB(lt_route_number, ln_loop_count, 1));
          --
          -- ループカウンタをカウントアップ
          ln_loop_count := ln_loop_count + 1;
          --
        END LOOP route_number_loop1;
        --
        -- 加算した訪問回数を乗算
        ln_visit_count := ln_route_number_work * cn_multiplication_no;
        --
      ELSIF (SUBSTRB(lt_route_number, 1, 2) = cv_visit_type_month) THEN
        -- ルートNOの先頭2桁が'5-'の場合
        ln_loop_count := 1;
        --
        <<route_number_loop2>>
        LOOP
          IF (ln_loop_count > ln_route_number_length) THEN
            -- ループ回数がルートＮｏの項目長を超えたらループを抜ける
            EXIT;
            --
          END IF;
          --
          -- 一週間の訪問日数を算出
          IF (ln_loop_count BETWEEN cn_visit_day_unit_from
            AND cn_visit_day_unit_to)
          THEN
            -- ルートＮｏの桁数が曜日単位の訪問を表す桁数の場合
            IF (SUBSTRB(lt_route_number, ln_loop_count, 1) <> cv_zero) THEN
              -- ルートＮｏが0以外の場合(1:月曜、2:火曜、3:水曜、4:木曜、5:金曜、6:土曜、7:日曜)
              ln_route_number_week := ln_route_number_week + cn_one;
              --
            END IF;
            --
          END IF;
          --
          -- 一ヶ月の訪問日数を算出
          IF (ln_loop_count BETWEEN cn_visit_week_unit_from
            AND cn_visit_week_unit_to)
          THEN
            -- ルートＮｏの桁数が一週間単位の訪問を表す桁数の場合
            IF (SUBSTRB(lt_route_number, ln_loop_count, 1) <> cv_zero) THEN
              -- ルートＮｏが0以外の場合(1:第一週、2:第二週、3:第三週、4:第四週、5:第五週)
              ln_route_number_month := ln_route_number_month + cn_one;
              --
            END IF;
            --
          END IF;
          --
          -- ループカウンタをカウントアップ
          ln_loop_count := ln_loop_count + 1;
          --
        END LOOP route_number_loop2;
        --
        -- 訪問回数一週間の訪問日数*一ヶ月の訪問週数を算出
        ln_visit_count := ln_route_number_week * ln_route_number_month;
        --
      ELSIF (SUBSTRB(lt_route_number, 1, 2) IN (cv_visit_type_season, cv_visit_type_other)) THEN
        -- ルートNOの先頭1桁が'6-'又は'9-'の場合
        ln_visit_count := cn_visit_count_other;
        --
      ELSE
        -- 上記以外の場合
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_02         -- メッセージコード
                       ,iv_token_name1  => cv_tkn_item              -- トークンコード1
                       ,iv_token_value1 => cv_tkn_value_item        -- トークン値1
                    );
        --
        lv_retcode := cv_status_error;
        --
      END IF;
      --
    END IF;
    --
    on_times   := ln_visit_count;
    ov_errbuf  := lv_errbuf;
    ov_retcode := lv_retcode;
    ov_errmsg  := lv_errbuf;
    --
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      on_times   := ln_visit_count;
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := lv_errbuf;
--
--#####################################  固定部 END   ##########################################
--
  END calc_visit_times;
--
--
   /**********************************************************************************
   * Function Name    : validate_route_no_p
   * Description      : ルートＮｏ妥当性チェック(プロシージャ)作成
   ***********************************************************************************/
  PROCEDURE validate_route_no_p(
     iv_route_number  IN  VARCHAR2            -- ルートＮｏ
    ,ov_retcode       OUT NOCOPY VARCHAR2     -- リターン・コード  --# 固定 #
    ,ov_error_reason  OUT VARCHAR2            -- エラー理由
  ) IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'validate_route_no_p';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lb_return_value              BOOLEAN;    --ルートＮｏ妥当性チェックRETURN値格納
--
  BEGIN
--
    lb_return_value := xxcso_route_common_pkg.validate_route_no(iv_route_number, ov_error_reason);
--
    IF ( lb_return_value ) THEN
--
      ov_retcode := '0';
--
    ELSE
--
      ov_retcode := '2';
--
    END IF;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt('xxcso_route_common_pkg', cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END validate_route_no_p;
--
  /**********************************************************************************
   * Function Name    : isCustomerVendor
   * Description      : ＶＤ業態判定関数
   ***********************************************************************************/
  FUNCTION isCustomerVendor(
     iv_cust_gyoutai  IN  VARCHAR2            -- 業態（小分類）
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'isCustomerVendor';
    cv_lookup_type_dai           CONSTANT VARCHAR2(100)   := 'XXCMM_CUST_GYOTAI_DAI';
    cv_lookup_type_chu           CONSTANT VARCHAR2(100)   := 'XXCMM_CUST_GYOTAI_CHU';
    cv_lookup_type_syo           CONSTANT VARCHAR2(100)   := 'XXCMM_CUST_GYOTAI_SHO';
    cv_profile_option            CONSTANT VARCHAR2(100)   := 'XXCSO1_VD_GYOUTAI_CD_DAI';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lt_gyoutai_cd_dai            fnd_lookup_values_vl.lookup_code%type;
    lb_return_value              VARCHAR2(10);
    lv_process_date              DATE := xxccp_common_pkg2.get_process_date;
--
  BEGIN
--
    BEGIN
      --業態（小分類）から業態（大分類）を取得
      SELECT dai.lookup_code gyoutai_dai_cd
      INTO   lt_gyoutai_cd_dai
      FROM   fnd_lookup_values_vl dai
      ,      fnd_lookup_values_vl chu
      ,      fnd_lookup_values_vl syo
      WHERE  syo.lookup_type = cv_lookup_type_syo
      AND    chu.lookup_type = cv_lookup_type_chu
      AND    dai.lookup_type = cv_lookup_type_dai
      AND    syo.lookup_code = iv_cust_gyoutai    --パラメータ.業態（小分類）
      AND    chu.lookup_code = syo.attribute1
      AND    dai.lookup_code = chu.attribute1
      AND    syo.enabled_flag   = 'Y'
      AND    chu.enabled_flag   = 'Y'
      AND    dai.enabled_flag   = 'Y'
      AND    NVL(dai.start_date_active, TRUNC(lv_process_date)) <= TRUNC(lv_process_date)
      AND    NVL(dai.end_date_active,   TRUNC(lv_process_date)) >= TRUNC(lv_process_date)
      AND    NVL(chu.start_date_active, TRUNC(lv_process_date)) <= TRUNC(lv_process_date)
      AND    NVL(chu.end_date_active,   TRUNC(lv_process_date)) >= TRUNC(lv_process_date)
      AND    NVL(syo.start_date_active, TRUNC(lv_process_date)) <= TRUNC(lv_process_date)
      AND    NVL(syo.end_date_active,   TRUNC(lv_process_date)) >= TRUNC(lv_process_date)
      ;
--
      IF ( lt_gyoutai_cd_dai = FND_PROFILE.VALUE(cv_profile_option) ) THEN
        --業態（大分類）がＶＤの場合
        lb_return_value := 'TRUE';
      ELSE
        --業態（大分類）がＶＤ以外の場合
        lb_return_value := 'FALSE';
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN
        --大分類が取得できない場合（ＭＣ顧客の場合など）
        lb_return_value := 'FALSE';
    END;
--
    RETURN lb_return_value;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt('xxcso_route_common_pkg', cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END isCustomerVendor;
--
  /**********************************************************************************
   * Function Name    : calc_visit_times_f
   * Description      : 訪問回数算出処理(ファンクション)
   ***********************************************************************************/
  FUNCTION calc_visit_times_f(
     it_route_number IN         xxcso_in_route_no.route_no%TYPE -- ルートＮｏ
  ) RETURN NUMBER
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name      CONSTANT VARCHAR2(100) := 'calc_visit_times_f';
    cn_err_vit_times CONSTANT NUMBER        := -1;
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_times     NUMBER;          -- 戻り値：訪問回数格納
    lv_errbuf    VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode   VARCHAR2(1);     -- リターン・コード
    lv_errmsg    VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
  BEGIN
--
    -- 訪問回数算出
    xxcso_route_common_pkg.calc_visit_times(
      it_route_number => it_route_number
     ,on_times        => ln_times
     ,ov_errbuf       => lv_errbuf
     ,ov_retcode      => lv_retcode
     ,ov_errmsg       => lv_errmsg
      );
--
    IF (lv_retcode <> cv_status_normal) THEN
      ln_times := cn_err_vit_times;
    END IF;
    
    RETURN ln_times;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt('xxcso_route_common_pkg', cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END calc_visit_times_f;
--
END xxcso_route_common_pkg;
/
