CREATE OR REPLACE PACKAGE BODY apps.xxcmn_common5_pkg
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2018. All rights reserved.
 *
 * Package Name           : xxcmn_common5_pkg(body)
 * Description            : 共通関数5
 * MD.070(CMD.050)        : T_MD050_BPO_000_共通関数5.xls
 * Version                : 1.4
 *
 * Program List
 *  -------------------- ---- ----- --------------------------------------------------
 *   Name                Type  Ret   Description
 *  -------------------- ---- ----- --------------------------------------------------
 *  get_use_by_date       F    DATE  賞味期限取得関数
 *  chek_lot_unit_price   F    NUM   月跨ぎのロット単価変更チェック
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2018/02/22    1.0   H.Sasaki        新規作成(E_本稼動_14859)
 *  2018/06/18    1.1   H.Sasaki        不具合対応(E_本稼動_15154)
 *  2019/07/25    1.2   E.Yazaki        不具合対応(E_本稼動_15550)
 *  2020/07/30    1.3   Y.Shoji         E_本稼動_16375対応
 *  2022/05/12    1.4   K.Tomie         E_本稼動_16375対応(障害対応)
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
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'xxcmn_common5_pkg'; -- パッケージ名
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  /**********************************************************************************
   * Function Name    : get_use_by_date
   * Description      : 賞味期限取得関数
   ***********************************************************************************/
  FUNCTION  get_use_by_date(
      id_producted_date     IN DATE       --  1.製造日
    , iv_expiration_type    IN VARCHAR2   --  2.表示区分
    , in_expiration_day     IN NUMBER     --  3.賞味期間
    , in_expiration_month   IN NUMBER     --  4.賞味期間(月)
  ) RETURN DATE
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_use_by_date'; -- プログラム名
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
    cv_type_10        CONSTANT VARCHAR2(2)  :=  '10';           --  表示区分：年月表示
    cv_type_20        CONSTANT VARCHAR2(2)  :=  '20';           --  表示区分：上・中・下旬表示
    cv_type_30        CONSTANT VARCHAR2(2)  :=  '30';           --  表示区分：同日
    cv_type_40        CONSTANT VARCHAR2(2)  :=  '40';           --  表示区分：同日 -1
    cv_date_middle    CONSTANT VARCHAR2(2)  :=  '11';           --  旬区分：下旬
    cv_date_late      CONSTANT VARCHAR2(2)  :=  '21';           --  旬区分：中旬
    cv_format_dd      CONSTANT VARCHAR2(2)  :=  'DD';           --  日付フォーマット：日
    cv_format_mm      CONSTANT VARCHAR2(2)  :=  'MM';           --  日付フォーマット：月
    cv_format_ym      CONSTANT VARCHAR2(7)  :=  'YYYY/MM';      --  日付フォーマット：年月
    cv_format_ymd     CONSTANT VARCHAR2(10) :=  'YYYY/MM/DD';   --  日付フォーマット：年月日
    cv_date_10        CONSTANT VARCHAR2(2)  :=  '10';           --  賞味期限固定日付：10日
    cv_date_20        CONSTANT VARCHAR2(2)  :=  '20';           --  賞味期限固定日付：20日
    cv_date_separate  CONSTANT VARCHAR2(1)  :=  '/';            --  日付用区切り文字
--
    -- *** ローカル変数 ***
    ld_use_by_date      DATE;       --  (戻り値)賞味期限
--  V1.2 2019/07/25 Modified START
    lv_use_by_date      VARCHAR2(10); --  賞味期限(製造日より、「賞味期間(月)」ヶ月後同日編集用)
--  V1.2 2019/07/25 Modified END
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--  V1.2 2019/07/25 Modified START
    -- 変数初期化
    lv_use_by_date := NULL;
--  V1.2 2019/07/25 Modified END
--
    IF ( in_expiration_month IS NULL OR iv_expiration_type IS NULL ) THEN
      --  表示区分、賞味期間(月）がNULL
      --  製造日より、「賞味期間」日後を賞味期限とする
      ld_use_by_date  :=  TRUNC( id_producted_date + in_expiration_day );
      RETURN  ld_use_by_date;
    END IF;
--
    IF ( iv_expiration_type = cv_type_10 ) THEN
      --  表示区分：年月表示
--  V1.1 2018/06/18 Modified START
--      --  製造日より、「賞味期間(月)」ヶ月後の月末日を賞味期限とする
--      ld_use_by_date  :=  TRUNC( LAST_DAY( ADD_MONTHS( id_producted_date, in_expiration_month ) ) );
      --  製造日を含め、製造日から「賞味期間(月)」ヶ月後の月末日を賞味期限とする
      ld_use_by_date  :=  TRUNC( LAST_DAY( ADD_MONTHS( id_producted_date, in_expiration_month - 1 ) ) );
--  V1.1 2018/06/18 Modified END
    ELSIF ( iv_expiration_type = cv_type_20 ) THEN
      -- 表示区分：上・中・下旬表示
      IF( TO_CHAR( id_producted_date, cv_format_dd ) >= cv_date_late ) THEN
        --  製造日が21日〜末日
        --  製造日より、「賞味期間(月)」ヶ月後の20日を賞味期限とする
        ld_use_by_date  :=  TRUNC( TO_DATE( TO_CHAR( ADD_MONTHS( id_producted_date, in_expiration_month ), cv_format_ym ) || cv_date_separate || cv_date_20, cv_format_ymd ) );
      ELSIF ( TO_CHAR( id_producted_date, cv_format_dd ) >= cv_date_middle ) THEN
        --  製造日が11日〜20日
        --  製造日より、「賞味期間(月)」ヶ月後の10日を賞味期限とする
        ld_use_by_date  :=  TRUNC( TO_DATE( TO_CHAR( ADD_MONTHS( id_producted_date, in_expiration_month ), cv_format_ym ) || cv_date_separate || cv_date_10, cv_format_ymd ) );
      ELSE
        --  製造日が1日〜10日
        --  製造日より、「賞味期間(月)」ヶ月後の前月月末日を賞味期限とする
        ld_use_by_date  :=  TRUNC( ADD_MONTHS( id_producted_date, in_expiration_month ), cv_format_mm ) -1;
      END IF;
    ELSIF ( iv_expiration_type = cv_type_30 ) THEN
      --  表示区分：同日
      --  製造日より、「賞味期間(月)」ヶ月後の同日を賞味期限とする
      --  ただし、同日が存在しない場合月末日を取得
--  V1.2 2019/07/25 Modified START
--      --  月末日の場合の同日とは、日付によらず月末日を指す(4/30と同日なのは5/30ではなく5/31(4月月末日の同日は5月月末日))
--      ld_use_by_date  :=  TRUNC( ADD_MONTHS( id_producted_date, in_expiration_month ) );
      lv_use_by_date  :=  TO_CHAR( ADD_MONTHS( id_producted_date, in_expiration_month ), 'YYYY/MM' ) || TO_CHAR( id_producted_date, '/DD' );
      BEGIN
        ld_use_by_date  :=  TO_DATE( lv_use_by_date, 'YYYY/MM/DD' );
      EXCEPTION
        WHEN OTHERS THEN
          --  日付型変換に失敗した場合（存在しない日付の場合）、製造日より「賞味期間(月)」ヶ月後の月末日を賞味期限とする
          ld_use_by_date  :=  ADD_MONTHS( id_producted_date, in_expiration_month );
      END;
--  V1.2 2019/07/25 Modified END
      --
    ELSIF ( iv_expiration_type = cv_type_40 ) THEN
      --  表示区分：同日 -1
      --  製造日より、「賞味期間(月)」ヶ月後の同日の前日を賞味期限とする
      --  ただし、同日が存在しない場合月末日を取得
--  V1.2 2019/07/25 Modified START
--      --  月末日の場合の同日とは、日付によらず月末日を指す(4/30と同日なのは5/30ではなく5/31(4月月末日の同日は5月月末日))
--      ld_use_by_date  :=  TRUNC( ADD_MONTHS( id_producted_date, in_expiration_month ) ) - 1;
      lv_use_by_date  :=  TO_CHAR( ADD_MONTHS( id_producted_date, in_expiration_month ), 'YYYY/MM' ) || TO_CHAR( id_producted_date, '/DD' );
      BEGIN
        ld_use_by_date  :=  TO_DATE( lv_use_by_date, 'YYYY/MM/DD' );
      EXCEPTION
        WHEN OTHERS THEN
          --  日付型変換に失敗した場合（存在しない日付の場合）、製造日より「賞味期間(月)」ヶ月後の月末日を賞味期限とする
          ld_use_by_date  :=  ADD_MONTHS( id_producted_date, in_expiration_month );
      END;
      --  -1日
      ld_use_by_date  :=  ld_use_by_date - 1;
--  V1.2 2019/07/25 Modified END
    ELSE
      --  上記以外
      --  製造日より、「賞味期間」日後を賞味期限とする
      ld_use_by_date  :=  TRUNC( id_producted_date + in_expiration_day );
    END IF;
--
    RETURN  ld_use_by_date;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
      RETURN  NULL;
--
  END get_use_by_date;
--
-- Ver_1.3 E_本稼動_16375 ADD Start
  /**********************************************************************************
   * Function Name    : chek_lot_unit_price
   * Description      : 月跨ぎのロット単価変更チェック
   ***********************************************************************************/
  FUNCTION  chek_lot_unit_price(
      id_base_date          IN DATE       --  1.基準日
    , in_lot_id             IN NUMBER     --  2.ロットID
    , iv_unit_price         IN VARCHAR2   --  3.単価
  ) RETURN NUMBER
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chek_lot_unit_price'; -- プログラム名
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
    cv_date_format_YM      CONSTANT VARCHAR2(7)  :=  'YYYY-MM';                      -- 日付形式：YYYY-MM
    cv_date_format_MM      CONSTANT VARCHAR2(2)  :=  'MM';                           -- 日付形式：MM
    cv_flag_y              CONSTANT VARCHAR2(1)  :=  'Y';                            -- フラグ：Y
    cv_pro_sales_books_id  CONSTANT VARCHAR2(27) :=  'XXCMN_SALES_SET_OF_BOOKS_ID';  -- プロファイル：XXCMN:営業会計帳簿ID
--
    -- *** ローカル変数 ***
    ld_start_date       DATE;          -- 基準日の前月の初日
    ld_end_date         DATE;          -- 基準日の月の初日
    lv_period_name      VARCHAR2(7);   -- 会計期間
    ln_count_gl         NUMBER;        -- 前月仕訳作成有無
    ln_count_trn        NUMBER;        -- 前月単価違いトランザクション有無
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    -- 基準日の月の初日を取得
    ld_end_date   := TRUNC(id_base_date ,cv_date_format_MM);
    -- 基準日の前月の初日を取得
    ld_start_date := ADD_MONTHS(ld_end_date ,-1);
    -- 基準日の前月の会計期間を取得
    lv_period_name := TO_CHAR(ld_start_date ,cv_date_format_YM);
--
    -- 相良会計自動仕訳作成有無チェック
    SELECT COUNT(0) count
    INTO   ln_count_gl
    FROM   xxcfo_mfg_if_control  xmif                   -- 連携管理テーブル
    WHERE  xmif.period_name     = lv_period_name                           -- 会計期間
    AND    xmif.gl_process_flag = cv_flag_y                                -- 処理フラグ
    AND    xmif.set_of_books_id = fnd_profile.value(cv_pro_sales_books_id) -- 会計帳簿ID
    ;
--
    -- 仕訳未作成の場合
    IF ( ln_count_gl = 0 ) THEN
      -- 保留在庫トランザクションの単価違いチェック
      SELECT COUNT(0) count
      INTO   ln_count_trn
      FROM   ic_tran_pnd  itp  -- 保留在庫トランザクション
            ,ic_lots_mst  ilm  -- ロットマスタ
      WHERE  itp.trans_date >= ld_start_date  -- 取引日From
      AND    itp.trans_date <  ld_end_date    -- 取引日To
      AND    itp.lot_id     =  in_lot_id      -- ロットID
      AND    itp.lot_id     =  ilm.lot_id
      AND    ilm.attribute7 <> iv_unit_price  -- 単価違い
-- Ver1.4 add start
      AND    ilm.attribute7 <> 0              -- 単価が0円の場合はチェックしない
-- Ver1.4 add end
      ;
--
      -- 単価違いが存在しない場合
      IF ( ln_count_trn = 0 ) THEN
        -- 完了在庫トランザクションの単価違いチェック
        SELECT COUNT(0) count
        INTO   ln_count_trn
        FROM   ic_tran_cmp  itc  -- 完了在庫トランザクション
              ,ic_lots_mst  ilm  -- ロットマスタ
        WHERE  itc.trans_date >= ld_start_date  -- 取引日From
        AND    itc.trans_date <  ld_end_date    -- 取引日To
        AND    itc.lot_id     =  in_lot_id      -- ロットID
        AND    itc.lot_id     =  ilm.lot_id
        AND    ilm.attribute7 <> iv_unit_price  -- 単価違い
-- Ver1.4 add start
        AND    ilm.attribute7   <> 0              -- 単価が0円の場合はチェックしない
-- Ver1.4 add end
        ;
      END IF;
--
      -- 単価違いが存在する場合
      IF ( ln_count_trn > 0 ) THEN
        -- エラーあり
        RETURN 1;
      END IF;
--
    END IF;
--
    -- エラーなし
    RETURN 0;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
      RETURN  NULL;
--
  END chek_lot_unit_price;
--
-- Ver_1.3 E_本稼動_16375 ADD End
END xxcmn_common5_pkg;
/
