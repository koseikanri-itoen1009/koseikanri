CREATE OR REPLACE PACKAGE BODY XXCOK008A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK008A06C(body)
 * Description      : 営業システム構築プロジェクト
 * MD.050           : アドオン：売上実績振替情報の作成（振替割合） 販売物流 MD050_COK_008_A06
 * Version          : 1.5
 *
 * Program List
 * --------------------------- ----------------------------------------------------------
 *  Name                        Description
 * --------------------------- ----------------------------------------------------------
 *  upd_detail_no               明細番号更新(A-14)
 *  upd_slip_no                 伝票番号更新(A-13)
 *  get_slip_detail_target      伝票番号明細番号更新対象抽出(A-12)
 *  ins_sales_exp               売上実績振替レコード追加(A-10)
 *  adj_data                    算出データの調整(A-9)
 *  chk_data                    算出データの整合性チェック(A-8)
 *  chk_covered                 売上担当設定の確認(A-7)
 *  get_offset_exp              売上実績振替元相殺データ抽出(A-11)
 *  get_sales_exp               販売実績情報テーブル抽出(A-6)
 *  get_sales_exp_sum           販売実績情報テーブル集計抽出(A-5)
 *  upd_correction_flg          振戻フラグ更新(A-4)
 *  ins_correction              売上実績振替情報振戻データ作成(A-3)
 *  get_period                  処理対象会計期間取得(A-2)
 *  init                        初期処理(A-1)
 *  submain                     メイン処理プロシージャ
 *  main                        コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/25    1.0   M.Hiruta         新規作成
 *  2009/02/18    1.1   T.OSADA          [障害COK_042]振戻データ作成時の情報系I/Fフラグ、仕訳作成フラグ修正
 *  2009/04/02    1.2   M.Hiruta         [障害T1_0089]振替元と先が同じ顧客である場合も、集計処理を行うよう修正
 *                                       [障害T1_0103]担当拠点、担当営業員が変更された場合の情報が
 *                                                    正確に取得できるよう修正
 *                                       [障害T1_0115]販売実績テーブル抽出時の絞込み条件において、
 *                                                    「検収日」を「納品日」に修正
 *                                       [障害T1_0190]基準単位換算失敗時にエラー終了するよう修正
 *                                       [障害T1_0196]販売実績テーブル抽出時の絞込み条件において、
 *                                                    1.A-5集計条件「納品日」の精度を"年月"までに修正
 *                                                    2.A-6、A-11集計条件「売上計上日」でA-5で取得した「納品日」の
 *                                                      の年月を参照するよう修正
 *  2009/04/27    1.3   M.Hiruta         [障害T1_0715]振替元となるデータのうち数量が1のデータにおいて、
 *                                                    1.振替割合が偏っている場合、振替割合の大きいデータへ
 *                                                      金額を寄せるよう修正
 *                                                    2.振替割合が均等である場合、顧客コードの若いレコードへ
 *                                                      金額を寄せるよう修正
 *  2009/06/04    1.4   M.Hiruta         [障害T1_1325]振戻データ作成処理で作成されるデータの日付を、
 *                                                    振戻対象データの日付に基づいて取得するよう変更
 *                                                    1.振戻データが先月データである場合⇒先月末日付
 *                                                    2.振戻データが当月データである場合⇒業務処理日付
 *  2009/07/03    1.5   M.Hiruta         [障害0000422]振戻データ作成処理で作成される業務登録日付を、
 *                                                    業務処理日付へ変更
 *
 *****************************************************************************************/
  -- ===============================
  -- グローバル定数
  -- ===============================
  -- ステータス
  cv_status_normal          CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn            CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error           CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_error;  -- 異常:2
  -- WHOカラム
  cn_created_by             CONSTANT NUMBER       := FND_GLOBAL.USER_ID;         -- CREATED_BY
  cn_last_updated_by        CONSTANT NUMBER       := FND_GLOBAL.USER_ID;         -- LAST_UPDATED_BY
  cn_last_update_login      CONSTANT NUMBER       := FND_GLOBAL.LOGIN_ID;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER       := FND_GLOBAL.CONC_REQUEST_ID; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER       := FND_GLOBAL.PROG_APPL_ID;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER       := FND_GLOBAL.CONC_PROGRAM_ID; -- PROGRAM_ID
  cv_msg_part               CONSTANT VARCHAR2(3)  := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(1)  := '.';
  -- アプリケーション短縮名
  cv_appli_short_name_xxcok CONSTANT VARCHAR2(5)  := 'XXCOK'; -- 個別_アプリケーション短縮名
  cv_appli_short_name_xxccp CONSTANT VARCHAR2(5)  := 'XXCCP'; -- 共通_アプリケーション短縮名
  cv_appli_short_name_ar    CONSTANT VARCHAR2(2)  := 'AR';    -- 売掛_アプリケーション短縮名
  -- パッケージ名
  cv_pkg_name               CONSTANT VARCHAR2(12) := 'XXCOK008A06C'; -- パッケージ名
  -- メッセージ
  cv_token_name1            CONSTANT VARCHAR2(5)  := 'COUNT';            -- 処理件数のトークン名
  cv_target_count_msg       CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
  cv_normal_count_msg       CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
  cv_err_count_msg          CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
  cv_skip_count_msg         CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
  cv_normal_msg             CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
  cv_warn_msg               CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
  cv_err_msg                CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90006'; -- エラー終了一部処理メッセージ
  cv_msg_xxcok1_00023       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00023'; -- A-1メッセージ
  cv_msg_xxcok1_10036       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10036'; -- A-1メッセージ
  cv_msg_xxcok1_00008       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00008'; -- A-1メッセージ
  cv_msg_xxcok1_00028       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00028'; -- A-1メッセージ
  cv_msg_xxcok1_00042       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00042'; -- A-2メッセージ
  cv_msg_xxcok1_10033       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10033'; -- A-3メッセージ
  cv_msg_xxcok1_10012       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10012'; -- A-4 A-12メッセージ
  cv_msg_xxcok1_10035       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10035'; -- A-4 A-12メッセージ
-- Start 2009/04/02 Ver_1.2 T1_0190 M.Hiruta
  cv_msg_xxcok1_10452       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10452'; -- A-6 A-11メッセージ
-- End   2009/04/02 Ver_1.2 T1_0190 M.Hiruta
  cv_msg_xxcok1_00045       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00045'; -- A-7メッセージ
  cv_msg_xxcok1_10034       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10034'; -- A-10メッセージ
  -- トークン名
  cv_info_class             CONSTANT VARCHAR2(10) := 'INFO_CLASS';     -- 情報種別
  cv_proc_date              CONSTANT VARCHAR2(9)  := 'PROC_DATE';      -- システム日付の年月
  cv_customer_code          CONSTANT VARCHAR2(13) := 'CUSTOMER_CODE';  -- 顧客コード
  cv_customer_name          CONSTANT VARCHAR2(13) := 'CUSTOMER_NAME';  -- 顧客名
  cv_tanto_loc_code         CONSTANT VARCHAR2(14) := 'TANTO_LOC_CODE'; -- 売上拠点コード
  cv_tanto_code             CONSTANT VARCHAR2(10) := 'TANTO_CODE';     -- 担当営業員
  cv_sales_date             CONSTANT VARCHAR2(10) := 'SALES_DATE';     -- 売上計上日
  cv_location_code          CONSTANT VARCHAR2(13) := 'LOCATION_CODE';  -- 拠点コード
  cv_item_code              CONSTANT VARCHAR2(9)  := 'ITEM_CODE';      -- 品目コード
-- Start 2009/04/02 Ver_1.2 T1_0190 M.Hiruta
  cv_dlv_uom_code           CONSTANT VARCHAR2(12) := 'DLV_UOM_CODE';   -- 単位
-- End   2009/04/02 Ver_1.2 T1_0190 M.Hiruta
  -- データ用固定値
  cv_correction_off_flg     CONSTANT VARCHAR2(1)  := '0';  -- 振戻オフ
  cv_correction_on_flg      CONSTANT VARCHAR2(1)  := '1';  -- 振戻オン
  cv_report_news_flg        CONSTANT VARCHAR2(1)  := '0';  -- 速報
  cv_report_decision_flg    CONSTANT VARCHAR2(1)  := '1';  -- 確定
  cv_info_if_flag           CONSTANT VARCHAR2(1)  := '0';  -- 情報系I/Fフラグ
  cv_gl_if_flag             CONSTANT VARCHAR2(1)  := '0';  -- 仕訳作成フラグ
  cv_invoice_class_01       CONSTANT VARCHAR2(1)  := '1';  -- 納品伝票区分:納品
  cv_invoice_class_02       CONSTANT VARCHAR2(1)  := '2';  -- 納品伝票区分:返品
  cv_invoice_class_03       CONSTANT VARCHAR2(1)  := '3';  -- 納品伝票区分:納品訂正
  cv_invoice_class_04       CONSTANT VARCHAR2(1)  := '4';  -- 納品伝票区分:返品訂正
  cv_transfer_div           CONSTANT VARCHAR2(1)  := '1';  -- 振替対象
  cv_cust_class_customer    CONSTANT VARCHAR2(2)  := '10'; -- 顧客区分:顧客
  cv_duns_number_c          CONSTANT VARCHAR2(2)  := '40'; -- 顧客ステータス:顧客
  cv_invalid_1_flg          CONSTANT VARCHAR2(1)  := '1';  -- 無効
  cv_invalid_0_flg          CONSTANT VARCHAR2(1)  := '0';  -- 有効
  cv_selling_trns_type      CONSTANT VARCHAR2(1)  := '0';          -- 実績振替区分
  cv_selling_type           CONSTANT VARCHAR2(1)  := '1';          -- 売上区分:通常
  cv_selling_return_type    CONSTANT VARCHAR2(1)  := '1';          -- 売上返品区分:納品
  cv_dlv_from_type          CONSTANT VARCHAR2(1)  := '6';          -- 納品形態区分:実績振替
  cv_article_code           CONSTANT VARCHAR2(10) := '0000000000'; -- 物件コード
  cv_card_selling_type      CONSTANT VARCHAR2(1)  := '0';          -- カード売り区分:現金
  cv_h_c                    CONSTANT VARCHAR2(1)  := '1';          -- H＆C:COLD
  cv_column_no              CONSTANT VARCHAR2(2)  := '00';         -- コラムNo
  cv_detail_num_j           CONSTANT VARCHAR2(1)  := 'J';          -- 明細番号接頭文字
  cv_sequence_s02_size      CONSTANT VARCHAR2(10) := 'FM00000000'; -- シーケンス変換後の桁数
  -- ===============================
  -- グローバル変数
  -- ===============================
  gn_target_cnt        NUMBER      DEFAULT 0;     -- 対象件数     A-6でカウント
  gn_normal_cnt        NUMBER      DEFAULT 0;     -- 正常件数     A-10でカウント
  gn_error_cnt         NUMBER      DEFAULT 0;     -- エラー件数   submainでカウント
  gn_skip_cnt          NUMBER      DEFAULT 0;     -- スキップ件数 A-6でカウント
  gv_info_class        VARCHAR2(1) DEFAULT NULL;  -- 情報種別
  gn_set_of_books_id   NUMBER      DEFAULT NULL;  -- 会計帳簿ID
  gd_process_date      DATE        DEFAULT NULL;  -- 業務日付
  gv_past_month        VARCHAR2(6) DEFAULT NULL;  -- 先月の日付
  gv_current_month     VARCHAR2(6) DEFAULT NULL;  -- 当月の日付
  -- ===============================
  -- グローバル例外
  -- ===============================
  -- 処理部共通例外
  global_process_expt    EXCEPTION;
  -- 共通関数例外
  global_api_expt        EXCEPTION;
  -- 共通関数OTHERS例外
  global_api_others_expt EXCEPTION;
  -- ロックエラー
  lock_expt              EXCEPTION;
  -- ===============================
  -- プラグマ
  -- ===============================
  -- 共通関数OTHERS例外
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
  PRAGMA EXCEPTION_INIT(lock_expt,-54);
--
  /**********************************************************************************
   * Procedure Name   : upd_detail_no
   * Description      : 明細番号更新(A-14)
   ***********************************************************************************/
  PROCEDURE upd_detail_no(
    ov_errbuf    OUT VARCHAR2
  , ov_retcode   OUT VARCHAR2
  , ov_errmsg    OUT VARCHAR2
  , iv_slip_no   IN  VARCHAR2
  )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(13) := 'upd_detail_no';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf           VARCHAR2(5000) DEFAULT NULL;
    lv_retcode          VARCHAR2(1)    DEFAULT NULL;
    lv_errmsg           VARCHAR2(5000) DEFAULT NULL;
--
  BEGIN
    -- 処理ステータスの初期化
    ov_retcode := cv_status_normal;
--
    -- ===============================
    -- 売上実績振替情報テーブル更新（更新に失敗して場合は例外処理へ遷移）
    -- 明細番号
    -- DENSE_RANK関数では、「納品単価を昇順にソートした順番」を取得する。
    -- ===============================
    UPDATE xxcok_selling_trns_info xsti
    SET    xsti.detail_no = (
             SELECT detail_no
             FROM   (
                    SELECT DENSE_RANK() OVER(ORDER BY xsti2.delivery_unit_price) detail_no
                         , xsti2.selling_trns_info_id
                    FROM   xxcok_selling_trns_info xsti2
                    WHERE  xsti2.slip_no    = iv_slip_no 
                    AND    xsti2.detail_no IS NULL
                    ) xsti3
             WHERE xsti.selling_trns_info_id = xsti3.selling_trns_info_id)
         , xsti.last_update_date    = SYSDATE
         , xsti.program_update_date = SYSDATE
    WHERE  xsti.slip_no    = iv_slip_no
    AND    xsti.detail_no IS NULL;
--
  EXCEPTION
    -- データ更新エラー
    WHEN OTHERS THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      cv_appli_short_name_xxcok
                    , cv_msg_xxcok1_10035
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
  END upd_detail_no;
--
  /**********************************************************************************
   * Procedure Name   : upd_slip_no
   * Description      : 伝票番号更新(A-13)
   ***********************************************************************************/
  PROCEDURE upd_slip_no(
    ov_errbuf    OUT VARCHAR2
  , ov_retcode   OUT VARCHAR2
  , ov_errmsg    OUT VARCHAR2
  , iv_base_code IN  VARCHAR2
  , iv_cust_code IN  VARCHAR2
  , iv_item_code IN  VARCHAR2
  , iv_slip_no   IN  VARCHAR2
  )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(11) := 'upd_slip_no';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf           VARCHAR2(5000) DEFAULT NULL;
    lv_retcode          VARCHAR2(1)    DEFAULT NULL;
    lv_errmsg           VARCHAR2(5000) DEFAULT NULL;
--
  BEGIN
    -- 処理ステータスの初期化
    ov_retcode := cv_status_normal;
--
    -- ===============================
    -- 売上実績振替情報テーブル更新（更新に失敗して場合は例外処理へ遷移）
    -- 伝票番号
    -- ===============================
    UPDATE xxcok_selling_trns_info xsti
    SET    xsti.slip_no    = iv_slip_no
    WHERE  xsti.base_code  = iv_base_code
    AND    xsti.cust_code  = iv_cust_code
    AND    xsti.item_code  = iv_item_code
    AND    xsti.slip_no   IS NULL
    AND    xsti.detail_no IS NULL;
--
  EXCEPTION
    -- データ更新エラー
    WHEN OTHERS THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      cv_appli_short_name_xxcok
                    , cv_msg_xxcok1_10035
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
  END upd_slip_no;
--
  /**********************************************************************************
   * Procedure Name   : get_slip_detail_target
   * Description      : 伝票番号明細番号更新対象抽出(A-12)
   ***********************************************************************************/
  PROCEDURE get_slip_detail_target(
    ov_errbuf  OUT VARCHAR2
  , ov_retcode OUT VARCHAR2
  , ov_errmsg  OUT VARCHAR2
  )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(22) := 'get_slip_detail_target';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL;
    lv_retcode  VARCHAR2(1)    DEFAULT NULL;
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL;
    lv_slip_no  VARCHAR2(9)    DEFAULT NULL;
    -- ===============================
    -- ローカルカーソル
    -- ===============================
    -- ロック取得用
    CURSOR upd_lock_cur
    IS
      SELECT xsti.base_code       AS base_code
           , xsti.cust_code       AS cust_code
           , xsti.item_code       AS item_code
      FROM   xxcok_selling_trns_info xsti
      WHERE  xsti.slip_no   IS NULL
      AND    xsti.detail_no IS NULL
      FOR UPDATE NOWAIT;
--
    -- 伝票番号更新カーソル
    CURSOR upd_slip_detail_cur
    IS
      SELECT xsti.base_code       AS base_code
           , xsti.cust_code       AS cust_code
           , xsti.item_code       AS item_code
      FROM   xxcok_selling_trns_info xsti
      WHERE  xsti.slip_no   IS NULL
      AND    xsti.detail_no IS NULL
      GROUP BY
             xsti.base_code
           , xsti.cust_code
           , xsti.item_code
      ORDER BY
             xsti.base_code
           , xsti.cust_code
           , xsti.item_code;
--
    -- カーソル型レコード
    upd_slip_detail_rec upd_slip_detail_cur%ROWTYPE;
--
    -- ===============================
    -- ローカル例外
    -- ===============================
    update_error_expt EXCEPTION; -- 売上実績振替情報テーブルアップデートエラー
--
  BEGIN
    -- 処理ステータスの初期化
    ov_retcode := cv_status_normal;
--
    -- ===============================
    -- 売上実績振替情報テーブルのロック取得
    -- ===============================
    OPEN  upd_lock_cur;
    CLOSE upd_lock_cur;
--
    -- ===============================
    -- 売上実績振替情報テーブル更新更新対象抽出
    -- ===============================
    OPEN  upd_slip_detail_cur;
    LOOP
      FETCH upd_slip_detail_cur INTO upd_slip_detail_rec;
      EXIT WHEN upd_slip_detail_cur%NOTFOUND;
--
        -- 伝票番号取得
        SELECT cv_detail_num_j || TO_CHAR(xxcok_selling_trns_info_s02.NEXTVAL,cv_sequence_s02_size)
        INTO   lv_slip_no
        FROM   DUAL;
--
        -- =============================================================
        -- A-13.伝票番号更新
        -- =============================================================
        upd_slip_no(
          ov_errbuf    => lv_errbuf
        , ov_retcode   => lv_retcode
        , ov_errmsg    => lv_errmsg
        , iv_base_code => upd_slip_detail_rec.base_code  -- 拠点コード
        , iv_cust_code => upd_slip_detail_rec.cust_code  -- 顧客コード
        , iv_item_code => upd_slip_detail_rec.item_code  -- 品目コード
        , iv_slip_no   => lv_slip_no                     -- 伝票番号
        );
--
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        -- =============================================================
        -- A-14.明細番号更新
        -- =============================================================
        upd_detail_no(
          ov_errbuf  => lv_errbuf
        , ov_retcode => lv_retcode
        , ov_errmsg  => lv_errmsg
        , iv_slip_no => lv_slip_no  -- 伝票番号
        );
--
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
    END LOOP;
--
  EXCEPTION
    -- ロックエラー
    WHEN lock_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      cv_appli_short_name_xxcok
                    , cv_msg_xxcok1_10012
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    -- 処理部共通例外ハンドラ
    WHEN global_process_expt THEN
      -- 処理ステータスをエラーとしてA-12を終了する。
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- カーソルのクローズ
      IF ( upd_slip_detail_cur%ISOPEN ) THEN
        CLOSE upd_slip_detail_cur;
      END IF;
--
    -- OTHERS例外ハンドラ
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- カーソルのクローズ
      IF ( upd_slip_detail_cur%ISOPEN ) THEN
        CLOSE upd_slip_detail_cur;
      END IF;
  END get_slip_detail_target;
--
  /**********************************************************************************
   * Procedure Name   : ins_sales_exp
   * Description      : 売上実績振替レコード追加(A-10)
   ***********************************************************************************/
  PROCEDURE ins_sales_exp(
    ov_errbuf              OUT VARCHAR2
  , ov_retcode             OUT VARCHAR2
  , ov_errmsg              OUT VARCHAR2
  , iv_delivery_date        IN VARCHAR2  -- 売上計上日
  , iv_to_base_code         IN VARCHAR2  -- 拠点コード
  , iv_to_cust_code         IN VARCHAR2  -- 顧客コード
  , iv_to_staff_code        IN VARCHAR2  -- 担当営業コード
  , iv_cust_gyotai_sho      IN VARCHAR2  -- 顧客業態区分
  , iv_demand_to_cust_code  IN VARCHAR2  -- 請求先顧客コード
  , iv_item_code            IN VARCHAR2  -- 品目コード
  , in_dlv_qty              IN NUMBER    -- 数量
  , iv_dlv_uom_code         IN VARCHAR2  -- 単位
  , in_dlv_unit_price       IN NUMBER    -- 納品単価
  , in_sale_amount          IN NUMBER    -- 売上金額
  , in_pure_amount          IN NUMBER    -- 売上金額（税抜き）
  , in_business_cost        IN NUMBER    -- 営業原価
  , iv_tax_code             IN VARCHAR2  -- 消費税コード
  , in_tax_rate             IN NUMBER    -- 消費税率
  , iv_from_base_code       IN VARCHAR2  -- 売上振替元拠点コード
  )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(13) := 'ins_sales_exp';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf               VARCHAR2(5000) DEFAULT NULL;
    lv_retcode              VARCHAR2(1)    DEFAULT NULL;
    lv_errmsg               VARCHAR2(5000) DEFAULT NULL;
    -- パラメータ以外の必要値用
    ld_selling_date         DATE           DEFAULT NULL; -- 売上計上日
    lv_info_class           VARCHAR2(1)    DEFAULT NULL; -- 速報確定フラグ
--
  BEGIN
    -- 処理ステータスの初期化
    ov_retcode := cv_status_normal;
--
    -- ===============================
    -- パラメータ以外の必要値を取得
    -- ===============================
    -- 売上計上日
    -- 速報確定フラグ
    IF ( iv_delivery_date = gv_current_month ) THEN
      ld_selling_date := gd_process_date;
      lv_info_class   := cv_report_news_flg;
    ELSIF ( gv_info_class   = cv_report_decision_flg AND
            iv_delivery_date = gv_past_month )
    THEN
      ld_selling_date := LAST_DAY(ADD_MONTHS(gd_process_date,-1));
      lv_info_class   := cv_report_decision_flg;
    ELSE
      ld_selling_date := LAST_DAY(ADD_MONTHS(gd_process_date,-1));
      lv_info_class   := cv_report_news_flg;
    END IF;
--
    -- ===============================
    -- 1.売上実績振替情報テーブルへのレコード追加処理
    -- ===============================
      INSERT INTO xxcok_selling_trns_info (
                    selling_trns_info_id  -- 売上実績振替情報ID
                  , selling_trns_type     -- 実績振替区分
                  , slip_no               -- 伝票番号
                  , detail_no             -- 明細番号
                  , selling_date          -- 売上計上日
                  , selling_type          -- 売上区分
                  , selling_return_type   -- 売上返品区分
                  , delivery_slip_type    -- 納品伝票区分
                  , base_code             -- 拠点コード
                  , cust_code             -- 顧客コード
                  , selling_emp_code      -- 担当営業コード
                  , cust_state_type       -- 顧客業態区分
                  , delivery_form_type    -- 納品形態区分
                  , article_code          -- 物件コード
                  , card_selling_type     -- カード売り区分
                  , checking_date         -- 検収日
                  , demand_to_cust_code   -- 請求先顧客コード
                  , h_c                   -- Ｈ＆Ｃ
                  , column_no             -- コラムNo.
                  , item_code             -- 品目コード
                  , qty                   -- 数量
                  , unit_type             -- 単位
                  , delivery_unit_price   -- 納品単価
                  , selling_amt           -- 売上金額
                  , selling_amt_no_tax    -- 売上金額（税抜き）
                  , trading_cost          -- 営業原価
                  , selling_cost_amt      -- 売上原価金額
                  , tax_code              -- 消費税コード
                  , tax_rate              -- 消費税率
                  , delivery_base_code    -- 納品拠点コード
                  , registration_date     -- 登録業務日付
                  , correction_flag       -- 振戻フラグ
                  , report_decision_flag  -- 速報確定フラグ
                  , info_interface_flag   -- 情報系I/Fフラグ
                  , gl_interface_flag     -- 仕訳作成フラグ
                  , org_slip_number       -- 元伝票番号
                  , created_by
                  , creation_date
                  , last_updated_by
                  , last_update_date
                  , last_update_login
                  , request_id
                  , program_application_id
                  , program_id
                  , program_update_date
                  ) VALUES (
                    xxcok_selling_trns_info_s01.NEXTVAL -- selling_trns_info_id
                  , cv_selling_trns_type                -- selling_trns_type
                  , NULL                                -- slip_no
                  , NULL                                -- detail_no
                  , ld_selling_date                     -- selling_date
                  , cv_selling_type                     -- selling_type
                  , cv_selling_return_type              -- selling_return_type
                  , cv_invoice_class_01                 -- delivery_slip_type
                  , iv_to_base_code                     -- base_code
                  , iv_to_cust_code                     -- cust_code
                  , iv_to_staff_code                    -- selling_emp_code
                  , iv_cust_gyotai_sho                  -- cust_state_type
                  , cv_dlv_from_type                    -- delivery_form_type
                  , cv_article_code                     -- article_code
                  , cv_card_selling_type                -- card_selling_type
                  , NULL                                -- checking_date
                  , iv_demand_to_cust_code              -- demand_to_cust_code
                  , cv_h_c                              -- h_c
                  , cv_column_no                        -- column_no
                  , iv_item_code                        -- item_code
                  , in_dlv_qty                          -- qty
                  , iv_dlv_uom_code                     -- unit_type
                  , in_dlv_unit_price                   -- delivery_unit_price
                  , in_sale_amount                      -- selling_amt
                  , in_pure_amount                      -- selling_amt_no_tax
                  , in_business_cost                    -- trading_cost
                  , NULL                                -- selling_cost_amt
                  , iv_tax_code                         -- tax_code
                  , in_tax_rate                         -- tax_rate
                  , iv_from_base_code                   -- delivery_base_code
                  , gd_process_date                     -- registration_date
                  , cv_correction_off_flg               -- correction_flag
                  , lv_info_class                       -- report_decision_flag
                  , cv_info_if_flag                     -- info_interface_flag
                  , cv_gl_if_flag                       -- gl_interface_flag
                  , NULL                                -- org_slip_number
                  , cn_created_by
                  , SYSDATE
                  , cn_last_updated_by
                  , SYSDATE
                  , cn_last_update_login
                  , cn_request_id
                  , cn_program_application_id
                  , cn_program_id
                  , SYSDATE
                  );
--
  EXCEPTION
    -- OTHERS例外ハンドラ（インサートエラー）
    WHEN OTHERS THEN
      -- エラーメッセージ取得
      lv_errmsg    := xxccp_common_pkg.get_msg(
                        cv_appli_short_name_xxcok
                      , cv_msg_xxcok1_10034
                      , cv_sales_date
                      , TO_CHAR( ld_selling_date , 'YYYY/MM/DD' )  -- 売上計上日
                      , cv_location_code
                      , iv_to_base_code                            -- 拠点コード
                      , cv_customer_code
                      , iv_to_cust_code                            -- 顧客コード
                      , cv_item_code
                      , iv_item_code                               -- 品目コード
                      );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
  END ins_sales_exp;
--
  /**********************************************************************************
   * Procedure Name   : adj_data
   * Description      : 算出データの調整(A-9)
   ***********************************************************************************/
  PROCEDURE adj_data(
    ov_errbuf               OUT VARCHAR2
  , ov_retcode              OUT VARCHAR2
  , ov_errmsg               OUT VARCHAR2
  , in_dlv_qty_from          IN NUMBER   -- 売上振替元数量
  , in_sale_amount_from      IN NUMBER   -- 売上振替元売上金額
  , in_pure_amount_from      IN NUMBER   -- 売上振替元売上金額（税抜き）
  , in_business_cost_from    IN NUMBER   -- 売上振替元営業原価
  , in_dlv_qty_to            IN NUMBER   -- 売上振替先数量
  , in_sale_amount_to        IN NUMBER   -- 売上振替先売上金額
  , in_pure_amount_to        IN NUMBER   -- 売上振替先売上金額（税抜き）
  , in_business_cost_to      IN NUMBER   -- 売上振替先営業原価
  , iv_from_base_code        IN VARCHAR2 -- 売上振替元拠点コード
  , iv_from_cust_code        IN VARCHAR2 -- 売上振替元顧客コード
  , iv_to_base_code          IN VARCHAR2 -- 売上振替先拠点コード
  , iv_to_cust_code          IN VARCHAR2 -- 売上振替先顧客コード
  , in_dlv_qty_detail        IN NUMBER   -- 詳細足し込み_数量
  , in_sale_amount_detail    IN NUMBER   -- 詳細足し込み_売上金額
  , in_pure_amount_detail    IN NUMBER   -- 詳細足し込み_売上金額（税抜き）
  , in_business_cost_detail  IN NUMBER   -- 詳細足し込み_営業原価
  , ib_adj_flg               IN BOOLEAN  -- A-8_調整フラグ
  , on_dlv_qty              OUT NUMBER   -- 調整後_数量
  , on_sale_amount          OUT NUMBER   -- 調整後_売上金額
  , on_pure_amount          OUT NUMBER   -- 調整後_売上金額（税抜き）
  , on_business_cost        OUT NUMBER   -- 調整後_営業原価
  , on_dlv_unit_price       OUT NUMBER   -- 納品単価
  )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(8) := 'adj_data';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf               VARCHAR2(5000) DEFAULT NULL;
    lv_retcode              VARCHAR2(1)    DEFAULT NULL;
    lv_errmsg               VARCHAR2(5000) DEFAULT NULL;
    -- 単価計算用
    ln_unit_qty             NUMBER         DEFAULT NULL; -- 計算用_数量
    ln_unit_amt             NUMBER         DEFAULT NULL; -- 計算用_売上金額
    -- 計算結果格納用（アウトパラメータ）
    ln_dlv_qty              NUMBER         DEFAULT NULL; -- 調整後_数量
    ln_sale_amount          NUMBER         DEFAULT NULL; -- 調整後_売上金額
    ln_pure_amount          NUMBER         DEFAULT NULL; -- 調整後_売上金額（税抜き）
    ln_business_cost        NUMBER         DEFAULT NULL; -- 調整後_営業原価
    ln_dlv_unit_price       NUMBER         DEFAULT NULL; -- 単価
--
  BEGIN
    -- 処理ステータスの初期化
    ov_retcode := cv_status_normal;
--
    -- ===============================
    -- 1.調整値の算出と加算
    -- ===============================
    IF ( iv_from_base_code = iv_to_base_code AND
         iv_from_cust_code = iv_to_cust_code AND
         ib_adj_flg        = TRUE )
    THEN
      -- パターン1
      ln_dlv_qty       := ( in_dlv_qty_detail + ( in_dlv_qty_from - in_dlv_qty_to )
                          - in_dlv_qty_from );
      ln_sale_amount   := ( in_sale_amount_detail + ( in_sale_amount_from - in_sale_amount_to )
                          - in_sale_amount_from );
      ln_pure_amount   := ( in_pure_amount_detail + ( in_pure_amount_from - in_pure_amount_to )
                          - in_pure_amount_from );
      ln_business_cost := ( in_business_cost_detail + ( in_business_cost_from - in_business_cost_to )
                          - in_business_cost_from );
--
      -- 単価計算用数値
      ln_unit_qty := ( in_dlv_qty_detail + ( in_dlv_qty_from - in_dlv_qty_to ));
      ln_unit_amt := ( in_sale_amount_detail + ( in_sale_amount_from - in_sale_amount_to ));
--
-- Start 2009/04/27 Ver_1.3 T1_0715 M.Hiruta
    -- 振替元の数量が1で割合により振替後の数量が0となるレコードの金額調整
    ELSIF ( iv_from_base_code = iv_to_base_code AND
            iv_from_cust_code = iv_to_cust_code AND
            in_dlv_qty_detail = 0               AND
            ib_adj_flg        = FALSE )
    THEN
      --  パターン5
      ln_dlv_qty       := ( in_dlv_qty_from * -1 );
      ln_sale_amount   := ( in_sale_amount_from * -1 );
      ln_pure_amount   := ( in_pure_amount_from * -1 );
      ln_business_cost := ( in_business_cost_from * -1 );
--
      -- 単価計算用数値
      ln_unit_qty := ln_dlv_qty;
      ln_unit_amt := ln_sale_amount;
-- End   2009/04/27 Ver_1.3 T1_0715 M.Hiruta
--
    ELSIF ( iv_from_base_code = iv_to_base_code AND
            iv_from_cust_code = iv_to_cust_code AND
            ib_adj_flg        = FALSE )
    THEN
      --  パターン2
      ln_dlv_qty       := ( in_dlv_qty_detail - in_dlv_qty_from );
      ln_sale_amount   := ( in_sale_amount_detail - in_sale_amount_from );
      ln_pure_amount   := ( in_pure_amount_detail - in_pure_amount_from );
      ln_business_cost := ( in_business_cost_detail - in_business_cost_from );
--
      -- 単価計算用数値
      ln_unit_qty := in_dlv_qty_detail;
      ln_unit_amt := in_sale_amount_detail;
--
-- Start 2009/04/27 Ver_1.3 T1_0715 M.Hiruta
    -- 振替先の数量が0で割合により振替後の数量が1となるレコードの金額調整
    ELSIF ( iv_from_cust_code <> iv_to_cust_code   AND
            in_dlv_qty_detail  = 0                 AND
            ib_adj_flg         = TRUE )
    THEN
      --  パターン6
      ln_dlv_qty       := in_dlv_qty_from;
      ln_sale_amount   := in_sale_amount_from;
      ln_pure_amount   := in_pure_amount_from;
      ln_business_cost := in_business_cost_from;
--
      -- 単価計算用数値
      ln_unit_qty := ln_dlv_qty;
      ln_unit_amt := ln_sale_amount;
-- End   2009/04/27 Ver_1.3 T1_0715 M.Hiruta
--
    ELSIF ( iv_from_cust_code <> iv_to_cust_code AND
            ib_adj_flg         = TRUE )
    THEN
      --  パターン3
      ln_dlv_qty       := ( in_dlv_qty_detail + ( in_dlv_qty_from - in_dlv_qty_to ));
      ln_sale_amount   := ( in_sale_amount_detail + ( in_sale_amount_from - in_sale_amount_to ));
      ln_pure_amount   := ( in_pure_amount_detail + ( in_pure_amount_from - in_pure_amount_to ));
      ln_business_cost := ( in_business_cost_detail + ( in_business_cost_from - in_business_cost_to ));
--
      -- 単価計算用数値
      ln_unit_qty := ln_dlv_qty;
      ln_unit_amt := ln_sale_amount;
--
-- Start 2009/04/27 Ver_1.3 T1_0715 M.Hiruta
    -- 振替元の数量が1で割合が偏っているレコードの金額調整
    ELSIF ( iv_from_cust_code <> iv_to_cust_code   AND
            in_dlv_qty_from    = in_dlv_qty_detail AND
            ib_adj_flg         = FALSE )
    THEN
      --  パターン7
      ln_dlv_qty       := in_dlv_qty_from;
      ln_sale_amount   := in_sale_amount_from;
      ln_pure_amount   := in_pure_amount_from;
      ln_business_cost := in_business_cost_from;
--
      -- 単価計算用数値
      ln_unit_qty := ln_dlv_qty;
      ln_unit_amt := ln_sale_amount;
-- End   2009/04/27 Ver_1.3 T1_0715 M.Hiruta
--
    ELSIF ( iv_from_cust_code <> iv_to_cust_code AND
            ib_adj_flg         = FALSE )
    THEN
      --  パターン4
      ln_dlv_qty       := in_dlv_qty_detail;
      ln_sale_amount   := in_sale_amount_detail;
      ln_pure_amount   := in_pure_amount_detail;
      ln_business_cost := in_business_cost_detail;
--
      -- 単価計算用数値
      ln_unit_qty := ln_dlv_qty;
      ln_unit_amt := ln_sale_amount;
    END IF;
--
    -- ===============================
    -- 2.納品単価算出
    -- ===============================
    -- 算出した数量が0ならば単価をNULLとし、売上実績振替レコード追加をスキップします
-- Start 2009/04/27 Ver_1.3 T1_0715 M.Hiruta
--    IF ( ln_unit_qty <> 0 ) THEN
    IF ( ln_unit_qty <> 0 AND ln_dlv_qty <> 0 ) THEN
-- End   2009/04/27 Ver_1.3 T1_0715 M.Hiruta
      ln_dlv_unit_price := ROUND( ln_unit_amt / ln_unit_qty , 1);
    END IF;
--
    -- ===============================
    -- 3.値をパラメータへ格納
    -- ===============================
    on_dlv_qty        := ln_dlv_qty;        -- 調整後_数量
    on_sale_amount    := ln_sale_amount;    -- 調整後_売上金額
    on_pure_amount    := ln_pure_amount;    -- 調整後_売上金額（税抜き）
    on_business_cost  := ln_business_cost;  -- 調整後_営業原価
    on_dlv_unit_price := ln_dlv_unit_price; -- 単価
--
  EXCEPTION
    -- OTHERS例外ハンドラ
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
  END adj_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_data
   * Description      : 算出データの整合性チェック(A-8)
   ***********************************************************************************/
  PROCEDURE chk_data(
    ov_errbuf             OUT VARCHAR2
  , ov_retcode            OUT VARCHAR2
  , ov_errmsg             OUT VARCHAR2
  , in_dlv_qty_from        IN NUMBER   -- 売上振替元数量
  , in_sale_amount_from    IN NUMBER   -- 売上振替元売上金額
  , in_pure_amount_from    IN NUMBER   -- 売上振替元売上金額（税抜き）
  , in_business_cost_from  IN NUMBER   -- 売上振替元営業原価
  , in_dlv_qty_to          IN NUMBER   -- 売上振替先数量
  , in_sale_amount_to      IN NUMBER   -- 売上振替先売上金額
  , in_pure_amount_to      IN NUMBER   -- 売上振替先売上金額（税抜き）
  , in_business_cost_to    IN NUMBER   -- 売上振替先営業原価
  , ob_adj_flg            OUT BOOLEAN  -- 調整フラグ
  )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(8) := 'chk_data';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL;
    lv_retcode  VARCHAR2(1)    DEFAULT NULL;
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL;
    lb_adj_flg   BOOLEAN       DEFAULT FALSE; -- 調整フラグ(Y：調整要 N：調整不要)
--
  BEGIN
    -- 処理ステータスの初期化
    ov_retcode := cv_status_normal;
--
    -- ===============================
    -- 1.算出データの整合性チェック
    -- ===============================
    -- 1つでも値が等しくない場合、調整フラグを立てる
    -- 納品数量
    IF ( in_dlv_qty_from <> in_dlv_qty_to )             THEN
      lb_adj_flg := TRUE;
    END IF;
--
    -- 売上金額
    IF ( in_sale_amount_from <> in_sale_amount_to )     THEN
      lb_adj_flg := TRUE;
    END IF;
--
    -- 売上金額（税抜き）
    IF ( in_pure_amount_from <> in_pure_amount_to )     THEN
      lb_adj_flg := TRUE;
    END IF;
--
    -- 営業原価
    IF ( in_business_cost_from <> in_business_cost_to ) THEN
      lb_adj_flg := TRUE;
    END IF;
--
    -- 比較結果をパラメータに格納
    ob_adj_flg := lb_adj_flg;
--
  EXCEPTION
    -- OTHERS例外ハンドラ
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
  END chk_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_covered
   * Description      : 売上担当設定の確認(A-7)
   ***********************************************************************************/
  PROCEDURE chk_covered(
    ov_errbuf        OUT VARCHAR2
  , ov_retcode       OUT VARCHAR2
  , ov_errmsg        OUT VARCHAR2
  , iv_to_cust_code   IN VARCHAR2  -- 顧客コード
  , iv_to_cust_name   IN VARCHAR2  -- 顧客名称
-- Start 2009/04/02 Ver_1.2 T1_0103 M.Hiruta
  , iv_delivery_date  IN VARCHAR2  -- 売上計上日（納品日）
-- End   2009/04/02 Ver_1.2 T1_0103 M.Hiruta
  , ov_to_staff_code OUT VARCHAR2  -- 担当営業コード
  )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(11) := 'chk_covered';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf        VARCHAR2(5000) DEFAULT NULL;
    lv_retcode       VARCHAR2(1)    DEFAULT NULL;
    lv_errmsg        VARCHAR2(5000) DEFAULT NULL;
    lv_out_msg       VARCHAR2(1000) DEFAULT NULL;  -- メッセージ出力変数
    lb_msg_return    BOOLEAN        DEFAULT TRUE;  -- メッセージ関数戻り値用
-- Start 2009/04/02 Ver_1.2 T1_0103 M.Hiruta
    ld_coverd_period DATE           DEFAULT NULL;  -- 担当営業員取得用日付データ
-- End   2009/04/02 Ver_1.2 T1_0103 M.Hiruta
    -- エラーメッセージ用変数
    lv_to_base_code  VARCHAR2(10)   DEFAULT NULL;  -- 売上拠点コード
    lv_to_staff_code VARCHAR2(10)   DEFAULT NULL;  -- 担当営業コード
--
  BEGIN
    -- 処理ステータスの初期化
    ov_retcode := cv_status_normal;
    -- ===============================
    -- 1.売上拠点コード取得
    -- ===============================
    BEGIN
-- Start 2009/04/02 Ver_1.2 T1_0103 M.Hiruta
--      SELECT xca.sale_base_code AS selling_to_base_code
      SELECT (
             CASE ( iv_delivery_date )
                 WHEN ( TO_CHAR( gd_process_date , 'YYYYMM' ) ) THEN
                     xca.sale_base_code
                 ELSE
                     xca.past_sale_base_code
             END
             ) AS selling_to_base_code
-- End   2009/04/02 Ver_1.2 T1_0103 M.Hiruta
      INTO   lv_to_base_code
      FROM   hz_cust_accounts    hca
           , xxcmm_cust_accounts xca
      WHERE  hca.cust_account_id = xca.customer_id
      AND    hca.account_number  = iv_to_cust_code;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
--
    -- ===============================
    -- 2.担当営業員コード取得
    -- ===============================
-- Start 2009/04/02 Ver_1.2 T1_0103 M.Hiruta
    -- 担当営業員取得用の日付取得
    IF ( iv_delivery_date = TO_CHAR( gd_process_date ) ) THEN
        ld_coverd_period := gd_process_date;
    ELSE
        ld_coverd_period := LAST_DAY( TO_DATE( iv_delivery_date , 'YYYYMM' ) );
    END IF;
--
    -- 担当営業員取得共通関数
    lv_to_staff_code := xxcok_common_pkg.get_sales_staff_code_f(
                          iv_to_cust_code
--                        , gd_process_date
                        , ld_coverd_period
-- End   2009/04/02 Ver_1.2 T1_0103 M.Hiruta
                        );
--
    -- 値をパラメータに格納
    ov_to_staff_code := lv_to_staff_code;
--
    -- ===============================
    -- 3.設定内容の確認
    -- ===============================
    IF ( lv_to_base_code IS NULL OR lv_to_staff_code IS NULL ) THEN
      -- 警告処理
      -- 警告メッセージ出力
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_short_name_xxcok
                    , cv_msg_xxcok1_00045
                    , cv_customer_code
                    , iv_to_cust_code   -- 顧客コード
                    , cv_customer_name
                    , iv_to_cust_name   -- 顧客名称
                    , cv_tanto_loc_code
                    , lv_to_base_code   -- 売上拠点コード
                    , cv_tanto_code
                    , lv_to_staff_code  -- 担当営業コード
                    );
--
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         FND_FILE.OUTPUT
                       , lv_out_msg
                       , 0
                       );
--
      -- セーブポイントまでデータをロールバック
      ROLLBACK TO sales_exp_save;
--
      -- ステータスに警告フラグをセット
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
    -- 共通関数OTHERS例外ハンドラ
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
    -- OTHERS例外ハンドラ
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
  END chk_covered;
--
  /**********************************************************************************
   * Procedure Name   : get_offset_exp
   * Description      : 売上実績振替元相殺データ抽出(A-11)
   ***********************************************************************************/
  PROCEDURE get_offset_exp(
    ov_errbuf                 OUT VARCHAR2
  , ov_retcode                OUT VARCHAR2
  , ov_errmsg                 OUT VARCHAR2
-- Start 2009/04/02 Ver_1.2 T1_0115 M.Hiruta
--  , iv_inspect_date            IN VARCHAR2  -- 売上計上日（検収日）
  , iv_delivery_date           IN VARCHAR2  -- 売上計上日（納品日）
-- End   2009/04/02 Ver_1.2 T1_0115 M.Hiruta
  , iv_selling_from_base_code  IN VARCHAR2  -- 売上振替元拠点コード
  , iv_selling_from_cust_code  IN VARCHAR2  -- 売上振替元顧客コード
  , iv_bill_account_number     IN VARCHAR2  -- 請求先顧客コード
  , iv_item_code               IN VARCHAR2  -- 品目コード
  )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(14) := 'get_offset_exp';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000) DEFAULT NULL;
    lv_retcode         VARCHAR2(1)    DEFAULT NULL;
    lv_errmsg          VARCHAR2(5000) DEFAULT NULL;
    ln_counter         NUMBER         DEFAULT 0;    -- 成功件数、警告件数用カウンター
    ln_dlv_unit_price  NUMBER         DEFAULT 0;    -- 納品単価
    lv_to_staff_code   VARCHAR2(10)   DEFAULT NULL; -- 担当営業コード
    lv_to_cust_code    VARCHAR2(10)   DEFAULT NULL; -- A-7用売上振替先顧客コード
    lv_to_cust_name    VARCHAR2(30)   DEFAULT NULL; -- A-7用売上振替先顧客名称
-- Start 2009/04/02 Ver_1.2 T1_0190 M.Hiruta
    ln_converted_qty   NUMBER         DEFAULT NULL; -- 基準数量取得成否チェック用
-- End   2009/04/02 Ver_1.2 T1_0190 M.Hiruta
    -- ===============================
    -- ローカルカーソル
    -- ===============================
    -- 相殺対象データ
    CURSOR offset_exp_cur
    IS
-- Start 2009/04/02 Ver_1.2 T1_0089 M.Hiruta
--      SELECT xseh.inspect_date                          AS inspect_date            -- 売上計上日（検収日）
      SELECT TO_CHAR(xseh.delivery_date , 'YYYYMM' )     AS delivery_date            -- 売上計上日（納品日）
--           , xsel.sales_class                           AS sales_class             -- 売上区分
--           , xseh.dlv_invoice_number                    AS dlv_invoice_number      -- 納品伝票区分
-- End   2009/04/02 Ver_1.2 T1_0089 M.Hiruta
           , xseh.sales_base_code                       AS selling_from_base_code  -- 売上振替元拠点コード
           , xseh.ship_to_customer_code                 AS selling_from_cust_code  -- 売上振替元顧客コード
           , hp.party_name                              AS selling_from_cust_name  -- 売上振替元顧客名称
           , xseh.cust_gyotai_sho                       AS cust_gyotai_sho         -- 顧客業態区分
           , xsel.item_code                             AS item_code               -- 品目コード
-- Start 2009/04/02 Ver_1.2 T1_0089 M.Hiruta
--           , ( xsel.dlv_qty * -1 )                      AS dlv_qty                 -- 数量(相殺)
--           , ( xsel.sale_amount * -1 )                  AS sale_amount             -- 売上金額(相殺)
--           , ( xsel.pure_amount * -1 )                  AS pure_amount             -- 売上金額（税抜き）(相殺)
           , SUM( xsel.dlv_qty * -1 )                   AS dlv_qty                 -- 数量(相殺)
           , SUM( xsel.sale_amount * -1 )               AS sale_amount             -- 売上金額(相殺)
           , SUM( xsel.pure_amount * -1 )               AS pure_amount             -- 売上金額（税抜き）(相殺)
-- End   2009/04/02 Ver_1.2 T1_0089 M.Hiruta
           , xseh.tax_code                              AS tax_code                -- 消費税コード
           , xseh.tax_rate                              AS tax_rate                -- 消費税率
           , xsel.dlv_uom_code                          AS dlv_uom_code            -- 単位
-- Start 2009/04/02 Ver_1.2 T1_0089 M.Hiruta
--           , ( xsel.business_cost * xxcok_common_pkg.get_uom_conversion_qty_f(     -- 基準単位換算共通関数
--                                      xsel.item_code                               -- 品目コード
--                                    , xsel.dlv_uom_code                            -- 単位
--                                    , xsel.dlv_qty                                 -- 数量
--                                    ) * -1 )            AS business_cost           -- 営業原価(相殺)
           , ROUND(xsel.sale_amount / xsel.dlv_qty , 1) AS unit_price                -- 単価（デバッグ用）
           , SUM( xsel.business_cost * xxcok_common_pkg.get_uom_conversion_qty_f(  -- 基準単位換算共通関数
                                         xsel.item_code                            -- 品目コード
                                       , xsel.dlv_uom_code                         -- 単位
                                       , xsel.dlv_qty                              -- 数量
                                       ) * -1 )         AS business_cost           -- 営業原価(相殺)
-- End   2009/04/02 Ver_1.2 T1_0089 M.Hiruta
      FROM   xxcos_sales_exp_lines   xsel
           , xxcos_sales_exp_headers xseh
           , hz_cust_accounts        hca  -- 顧客マスタ
           , hz_parties              hp
           , xxcmm_cust_accounts     xca
      WHERE  xsel.sales_exp_header_id     = xseh.sales_exp_header_id
      AND    hca.party_id                 = hp.party_id
      AND    hca.cust_account_id          = xca.customer_id
      AND    xseh.ship_to_customer_code   = hca.account_number
      AND    xca.selling_transfer_div     = cv_transfer_div
      AND    xca.chain_store_code        IS NULL
      AND    hca.customer_class_code      = cv_cust_class_customer
      AND    hp.duns_number_c             = cv_duns_number_c
      AND    xseh.dlv_invoice_class      IN ( cv_invoice_class_01
                                            , cv_invoice_class_02
                                            , cv_invoice_class_03
                                            , cv_invoice_class_04
                                            )
      AND    xsel.business_cost          IS NOT NULL
-- Start 2009/04/02 Ver_1.2 T1_0196 M.Hiruta
--      AND    TO_CHAR(xseh.inspect_date , 'YYYYMM' ) IN ( gv_current_month , gv_past_month )
      AND    TO_CHAR(xseh.delivery_date , 'YYYYMM' ) = iv_delivery_date
-- End   2009/04/02 Ver_1.2 T1_0196 M.Hiruta
      AND    xseh.sales_base_code         = iv_selling_from_base_code
      AND    xseh.ship_to_customer_code   = iv_selling_from_cust_code
      AND    xsel.item_code               = iv_item_code
-- Start 2009/04/02 Ver_1.2 T1_0089 M.Hiruta
      GROUP BY
             TO_CHAR(xseh.delivery_date , 'YYYYMM' )
           , xseh.sales_base_code
           , xseh.ship_to_customer_code
           , hp.party_name
           , xseh.cust_gyotai_sho
           , xsel.item_code
           , xseh.tax_code
           , xseh.tax_rate
           , xsel.dlv_uom_code
           , ROUND(xsel.sale_amount / xsel.dlv_qty , 1);
-- End   2009/04/02 Ver_1.2 T1_0089 M.Hiruta
--
    -- カーソル型レコード
    l_offset_exp_rec offset_exp_cur%ROWTYPE;
--
    -- ===============================
    -- ローカル例外
    -- ===============================
    warn_expt    EXCEPTION; -- A-7警告処理用例外
-- Start 2009/04/02 Ver_1.2 T1_0190 M.Hiruta
    convert_expt EXCEPTION; -- 基準数量取得エラー
-- End   2009/04/02 Ver_1.2 T1_0190 M.Hiruta
--
  BEGIN
    -- 処理ステータスの初期化
    ov_retcode := cv_status_normal;
--
    -- ===============================
    -- 1.販売実績情報テーブル抽出
    -- ===============================
    OPEN offset_exp_cur;
    LOOP
      FETCH offset_exp_cur INTO l_offset_exp_rec;
      EXIT WHEN offset_exp_cur%NOTFOUND;
-- Start 2009/04/02 Ver_1.2 T1_0190 M.Hiruta
        -- ===============================
        -- 基準数量取得成否判定
        -- ===============================
        -- 基準単位換算共通関数コール
        ln_converted_qty := xxcok_common_pkg.get_uom_conversion_qty_f(
                              l_offset_exp_rec.item_code                -- 品目コード
                            , l_offset_exp_rec.dlv_uom_code             -- 単位
                            , l_offset_exp_rec.dlv_qty                  -- 数量
                            );
--
        -- 基準単位換算共通関数の戻り値がNULLである場合エラー処理へ遷移
        IF ( ln_converted_qty IS NULL ) THEN
          RAISE convert_expt;
        END IF;
-- End   2009/04/02 Ver_1.2 T1_0190 M.Hiruta
--
        -- 処理対象件数カウントアップ
        gn_target_cnt := gn_target_cnt +1;
--
        -- =============================================================
        -- A-7.売上担当設定の確認
        -- =============================================================
        -- ループ中、一度だけ実行する
        IF ( lv_to_cust_code IS NULL )
        THEN
          lv_to_cust_code := l_offset_exp_rec.selling_from_cust_code;
          lv_to_cust_name := l_offset_exp_rec.selling_from_cust_name;
          -- A-7
          chk_covered(
            ov_errbuf        => lv_errbuf
          , ov_retcode       => lv_retcode
          , ov_errmsg        => lv_errmsg
          , iv_to_cust_code  => lv_to_cust_code                -- 顧客コード
          , iv_to_cust_name  => lv_to_cust_name                -- 顧客名称
-- Start 2009/04/02 Ver_1.2 T1_0103 M.Hiruta
          , iv_delivery_date => l_offset_exp_rec.delivery_date -- 売上計上日（納品日）
-- End   2009/04/02 Ver_1.2 T1_0103 M.Hiruta
          , ov_to_staff_code => lv_to_staff_code               -- 担当営業コード
          );
        END IF;
--
        -- 売上拠点コードか営業担当員が存在しなかった場合（警告処理）
        IF ( lv_retcode = cv_status_warn )    THEN
          -- スキップ件数カウントアップ
          gn_skip_cnt := gn_skip_cnt + ln_counter + 1;
          RAISE warn_expt;
        -- エラー処理
        ELSIF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        -- =============================================================
        -- A-10.売上実績振替レコード追加
        -- =============================================================
        -- 納品単価を算出する（数量/売上金額）
        ln_dlv_unit_price := ROUND(l_offset_exp_rec.sale_amount / l_offset_exp_rec.dlv_qty , 1);
--
        -- A-10
        ins_sales_exp(
          ov_errbuf               => lv_errbuf
        , ov_retcode              => lv_retcode
        , ov_errmsg               => lv_errmsg
-- Start 2009/04/02 Ver_1.2 T1_0089 M.Hiruta
--        , iv_inspect_date         => iv_inspect_date                         -- 売上計上日
        , iv_delivery_date        => l_offset_exp_rec.delivery_date          -- 売上計上日
-- End   2009/04/02 Ver_1.2 T1_0089 M.Hiruta
        , iv_to_base_code         => l_offset_exp_rec.selling_from_base_code -- 拠点コード
        , iv_to_cust_code         => l_offset_exp_rec.selling_from_cust_code -- 顧客コード
        , iv_to_staff_code        => lv_to_staff_code                        -- 担当営業コード
        , iv_cust_gyotai_sho      => l_offset_exp_rec.cust_gyotai_sho        -- 業態小分類
        , iv_demand_to_cust_code  => iv_bill_account_number                  -- 請求先顧客コード
        , iv_item_code            => l_offset_exp_rec.item_code              -- 品目コード
        , in_dlv_qty              => l_offset_exp_rec.dlv_qty                -- 数量（相殺）
        , iv_dlv_uom_code         => l_offset_exp_rec.dlv_uom_code           -- 単位
        , in_dlv_unit_price       => ln_dlv_unit_price                       -- 納品単価
        , in_sale_amount          => l_offset_exp_rec.sale_amount            -- 売上金額（相殺）
        , in_pure_amount          => l_offset_exp_rec.pure_amount            -- 売上金額（税抜き）（相殺）
        , in_business_cost        => l_offset_exp_rec.business_cost          -- 営業原価（相殺）
        , iv_tax_code             => l_offset_exp_rec.tax_code               -- 消費税コード
        , in_tax_rate             => l_offset_exp_rec.tax_rate               -- 消費税率
        , iv_from_base_code       => l_offset_exp_rec.selling_from_base_code -- 売上振替元拠点コード
        );
--
        -- A-10でエラーが起きた場合の処理
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        -- 処理成功件数カウントアップ
        ln_counter := ln_counter + 1;
--
    END LOOP;
--
    -- 処理成功件数格納
    gn_normal_cnt := gn_normal_cnt + ln_counter;
--
  EXCEPTION
    -- A-7警告処理
    WHEN warn_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_warn;
      -- カーソルのクローズ
      IF ( offset_exp_cur%ISOPEN ) THEN
        CLOSE offset_exp_cur;
      END IF;
--
-- Start 2009/04/02 Ver_1.2 T1_0190 M.Hiruta
    -- 基準数量取得エラー
    WHEN convert_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      cv_appli_short_name_xxcok
                    , cv_msg_xxcok1_10452
                    , cv_item_code
                    , l_offset_exp_rec.item_code
                    , cv_dlv_uom_code
                    , l_offset_exp_rec.dlv_uom_code
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--  -- 共通関数OTHERS例外ハンドラ
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
-- End   2009/04/02 Ver_1.2 T1_0190 M.Hiruta
--
    -- 機能内プロシージャエラー例外ハンドラ
    WHEN global_process_expt THEN
      -- 処理ステータスをエラーとしてA-11を終了する。
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- カーソルのクローズ
      IF ( offset_exp_cur%ISOPEN ) THEN
        CLOSE offset_exp_cur;
      END IF;
--
    -- OTHERS例外ハンドラ
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- カーソルのクローズ
      IF ( offset_exp_cur%ISOPEN ) THEN
        CLOSE offset_exp_cur;
      END IF;
  END get_offset_exp;
--
  /**********************************************************************************
   * Procedure Name   : get_sales_exp
   * Description      : 販売実績情報テーブル抽出(A-6)
   ***********************************************************************************/
  PROCEDURE get_sales_exp(
    ov_errbuf                 OUT VARCHAR2
  , ov_retcode                OUT VARCHAR2
  , ov_errmsg                 OUT VARCHAR2
  , iv_delivery_date           IN VARCHAR2  -- 売上計上日
  , iv_selling_from_base_code  IN VARCHAR2  -- 売上振替元拠点コード
  , iv_selling_from_cust_code  IN VARCHAR2  -- 売上振替元顧客コード
  , iv_bill_account_number     IN VARCHAR2  -- 請求先顧客コード
  , iv_item_code               IN VARCHAR2  -- 品目コード
  , in_dlv_qty_from            IN NUMBER    -- 売上振替元数量
  , in_sale_amount_from        IN NUMBER    -- 売上振替元売上金額
  , in_pure_amount_from        IN NUMBER    -- 売上振替元売上金額（税抜き）
  , in_business_cost_from      IN NUMBER    -- 売上振替元営業原価
  , in_dlv_qty_to              IN NUMBER    -- 売上振替先数量
  , in_sale_amount_to          IN NUMBER    -- 売上振替先売上金額
  , in_pure_amount_to          IN NUMBER    -- 売上振替先売上金額（税抜き）
  , in_business_cost_to        IN NUMBER    -- 売上振替先営業原価
  )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(13) := 'get_sales_exp';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000) DEFAULT NULL;
    lv_retcode         VARCHAR2(1)    DEFAULT NULL;
    lv_errmsg          VARCHAR2(5000) DEFAULT NULL;
    ln_counter         NUMBER         DEFAULT 0;    -- 成功件数、警告件数用カウンター
    lv_to_staff_code   VARCHAR2(10)   DEFAULT NULL; -- 担当営業コード
    lv_to_cust_code    VARCHAR2(10)   DEFAULT NULL; -- A-7用売上振替先顧客コード
    lv_to_cust_name    VARCHAR2(30)   DEFAULT NULL; -- A-7用売上振替先顧客名称
    lb_proc_start_flg  BOOLEAN        DEFAULT TRUE; -- A-8用処理実行判定フラグ(Y：実行要 N：実行不要)
    lb_data_adj_flg    BOOLEAN        DEFAULT TRUE; -- A-8用調整フラグ(Y：調整要 N：調整不要)
    ln_dlv_qty         NUMBER         DEFAULT 0;    -- A-9_調整後数量
    ln_sale_amount     NUMBER         DEFAULT 0;    -- A-9_調整後売上金額
    ln_pure_amount     NUMBER         DEFAULT 0;    -- A-9_調整後売上金額（税抜）
    ln_business_cost   NUMBER         DEFAULT 0;    -- A-9_調整後営業原価
    ln_dlv_unit_price  NUMBER         DEFAULT 0;    -- A-9_納品単価
-- Start 2009/04/02 Ver_1.2 T1_0190 M.Hiruta
    ln_converted_qty   NUMBER         DEFAULT NULL; -- 基準数量取得成否チェック用
-- End   2009/04/02 Ver_1.2 T1_0190 M.Hiruta
    -- ===============================
    -- ローカルカーソル
    -- ===============================
    -- 販売実績情報
    CURSOR sales_exp_cur
    IS
-- Start 2009/04/02 Ver_1.2 T1_0115 M.Hiruta
--      SELECT TO_CHAR(xseh.inspect_date , 'YYYYMM' )  AS inspect_date           -- 売上計上日（検収日）
      SELECT TO_CHAR(xseh.delivery_date , 'YYYYMM' ) AS delivery_date          -- 売上計上日（納品日）
-- End   2009/04/02 Ver_1.2 T1_0115 M.Hiruta
           , xseh.sales_base_code                    AS selling_from_base_code -- 売上振替元拠点コード
           , xseh.ship_to_customer_code              AS selling_from_cust_code -- 売上振替元顧客コード
-- Start 2009/04/02 Ver_1.2 T1_0103 M.Hiruta
--           , xca.sale_base_code                      AS selling_to_base_code   -- 売上振替先拠点コード
           , (
             CASE ( TO_CHAR( xseh.delivery_date , 'YYYYMM' ) )
                 WHEN ( TO_CHAR( gd_process_date , 'YYYYMM' ) ) THEN
                     xca.sale_base_code
                 ELSE
                     xca.past_sale_base_code
             END
             )                                       AS selling_to_base_code   -- 売上振替先拠点コード
-- End   2009/04/02 Ver_1.2 T1_0103 M.Hiruta
           , hca.account_number                      AS selling_to_cust_code   -- 売上振替先顧客コード
           , hp.party_name                           AS selling_to_cust_name   -- 売上振替先顧客名称
           , xseh.cust_gyotai_sho                    AS cust_gyotai_sho        -- 顧客業態区分
           , xsel.item_code                          AS item_code              -- 品目コード
           , xseh.tax_code                           AS tax_code               -- 消費税コード
           , xseh.tax_rate                           AS tax_rate               -- 消費税率
           , xsel.dlv_uom_code                       AS dlv_uom_code           -- 単位
           , ROUND(SUM(xsel.dlv_qty) * ( xsri.selling_trns_rate / 100 ))      AS dlv_qty     -- 数量
           , ROUND(SUM(xsel.sale_amount) * ( xsri.selling_trns_rate / 100 ))  AS sale_amount -- 売上金額
           , ROUND(SUM(xsel.pure_amount) * ( xsri.selling_trns_rate / 100 ))  AS pure_amount -- 売上金額（税抜き）
           , ROUND((SUM(xsel.business_cost * xxcok_common_pkg.get_uom_conversion_qty_f(      -- 基準単位換算共通関数
                                               xsel.item_code                                -- 品目コード
                                             , xsel.dlv_uom_code                             -- 単位
                                             , xsel.dlv_qty                                  -- 数量
                                             )) * ( xsri.selling_trns_rate / 100 ))) AS business_cost -- 営業原価
           , ROUND(xsel.sale_amount / xsel.dlv_qty , 1)                       AS unit_price  -- 単価（デバッグ用）
           , ABS(ROUND(SUM(xsel.dlv_qty) * ( xsri.selling_trns_rate / 100 ))) AS abs_dlv_qty -- 納品数量（絶対値）
      FROM   xxcos_sales_exp_lines   xsel
           , xxcos_sales_exp_headers xseh
           , xxcok_selling_rate_info xsri
           , xxcok_selling_to_info   xsti
           , xxcok_selling_from_info xsfi
           , hz_cust_accounts        hca  -- 顧客マスタ
           , hz_parties              hp
           , xxcmm_cust_accounts     xca
      WHERE  xsel.sales_exp_header_id     = xseh.sales_exp_header_id
      AND    hca.party_id                 = hp.party_id
      AND    hca.cust_account_id          = xca.customer_id
      AND    xsti.selling_to_cust_code    = hca.account_number
      AND    xsti.selling_from_info_id    = xsfi.selling_from_info_id
      AND    xsri.selling_from_base_code  = xsfi.selling_from_base_code
      AND    xsri.selling_from_cust_code  = xsfi.selling_from_cust_code
      AND    xsri.selling_to_cust_code    = xsti.selling_to_cust_code
      AND    xsri.selling_from_base_code  = xseh.sales_base_code
      AND    xsri.selling_from_cust_code  = xseh.ship_to_customer_code
      AND    xsti.start_month            <= gv_current_month
      AND    xca.selling_transfer_div     = cv_transfer_div
      AND    xca.chain_store_code        IS NULL
      AND    hca.customer_class_code      = cv_cust_class_customer
      AND    hp.duns_number_c             = cv_duns_number_c
      AND    xseh.dlv_invoice_class      IN ( cv_invoice_class_01
                                            , cv_invoice_class_02
                                            , cv_invoice_class_03
                                            , cv_invoice_class_04
                                            )
      AND    xsel.business_cost          IS NOT NULL
-- Start 2009/04/02 Ver_1.2 T1_0196 M.Hiruta
--      AND    TO_CHAR(xseh.inspect_date , 'YYYYMM' ) IN ( gv_current_month , gv_past_month )
      AND    TO_CHAR(xseh.delivery_date , 'YYYYMM' ) = iv_delivery_date
-- End   2009/04/02 Ver_1.2 T1_0196 M.Hiruta
      AND    xsri.invalid_flag            = cv_invalid_0_flg
      AND    xsti.invalid_flag            = cv_invalid_0_flg
      AND    xseh.sales_base_code         = iv_selling_from_base_code
      AND    xseh.ship_to_customer_code   = iv_selling_from_cust_code
      AND    xsel.item_code               = iv_item_code
      GROUP BY
-- Start 2009/04/02 Ver_1.2 T1_0115 M.Hiruta
--             TO_CHAR(xseh.inspect_date , 'YYYYMM' )     -- 売上計上日（検収日）
             TO_CHAR(xseh.delivery_date , 'YYYYMM' )    -- 売上計上日（納品日）
-- End   2009/04/02 Ver_1.2 T1_0115 M.Hiruta
           , xseh.sales_base_code                       -- 売上振替元拠点コード
           , xseh.ship_to_customer_code                 -- 売上振替元顧客コード
-- Start 2009/04/02 Ver_1.2 T1_0103 M.Hiruta
--           , xca.sale_base_code                         -- 売上振替先拠点コード
           , (
             CASE ( TO_CHAR( xseh.delivery_date , 'YYYYMM' ) )
                 WHEN ( TO_CHAR( gd_process_date , 'YYYYMM' ) ) THEN
                     xca.sale_base_code
                 ELSE
                     xca.past_sale_base_code
             END
             )                                          -- 売上振替先拠点コード
-- End   2009/04/02 Ver_1.2 T1_0103 M.Hiruta
           , hca.account_number                         -- 売上振替先顧客コード
           , hp.party_name                              -- 売上振替先顧客名称
           , xseh.cust_gyotai_sho                       -- 顧客業態区分
           , xsel.item_code                             -- 品目コード
           , xseh.tax_code                              -- 消費税コード
           , xseh.tax_rate                              -- 消費税率
           , xsel.dlv_uom_code                          -- 単位
           , ROUND(xsel.sale_amount / xsel.dlv_qty , 1) -- 単価
           , xsri.selling_trns_rate                     -- 売上振替割合
      ORDER BY
             ABS(ROUND(SUM(xsel.dlv_qty) * ( xsri.selling_trns_rate / 100 ))) DESC
-- Start 2009/04/27 Ver_1.3 T1_0715 M.Hiruta
           , hca.account_number ASC;
-- End   2009/04/27 Ver_1.3 T1_0715 M.Hiruta
--
    -- カーソル型レコード
    l_sales_exp_rec sales_exp_cur%ROWTYPE;
--
    -- ===============================
    -- ローカル例外
    -- ===============================
    warn_expt    EXCEPTION; -- A-7警告処理用例外
-- Start 2009/04/02 Ver_1.2 T1_0190 M.Hiruta
    convert_expt EXCEPTION; -- 基準数量取得エラー
-- End   2009/04/02 Ver_1.2 T1_0190 M.Hiruta
--
  BEGIN
    -- 処理ステータスの初期化
    ov_retcode := cv_status_normal;
--
    -- ===============================
    -- 1.販売実績情報テーブル抽出
    -- ===============================
    OPEN sales_exp_cur;
    LOOP
      FETCH sales_exp_cur INTO l_sales_exp_rec;
      EXIT WHEN sales_exp_cur%NOTFOUND;
-- Start 2009/04/02 Ver_1.2 T1_0190 M.Hiruta
        -- ===============================
        -- 基準数量取得成否判定
        -- ===============================
        -- 基準単位換算共通関数コール
        ln_converted_qty := xxcok_common_pkg.get_uom_conversion_qty_f(
                              l_sales_exp_rec.item_code                -- 品目コード
                            , l_sales_exp_rec.dlv_uom_code             -- 単位
                            , l_sales_exp_rec.dlv_qty                  -- 数量
                            );
--
        -- 基準単位換算共通関数の戻り値がNULLである場合エラー処理へ遷移
        IF ( ln_converted_qty IS NULL ) THEN
          RAISE convert_expt;
        END IF;
-- End   2009/04/02 Ver_1.2 T1_0190 M.Hiruta
--
        -- 処理対象件数カウントアップ
        gn_target_cnt := gn_target_cnt +1;
--
        -- =============================================================
        -- A-7.売上担当設定の確認
        -- =============================================================
        -- 売上振替先顧客コードを保持し、処理対象であるか判別する
        -- ※通過時の売上振替先顧客コードが前回通過時の売上振替先顧客コードと等しい場合は
        --   A-7の処理を行わない。
        IF ( lv_to_cust_code <> l_sales_exp_rec.selling_to_cust_code OR
             lv_to_cust_code IS NULL )
        THEN
          lv_to_cust_code := l_sales_exp_rec.selling_to_cust_code;
          lv_to_cust_name := l_sales_exp_rec.selling_to_cust_name;
          -- A-7
          chk_covered(
            ov_errbuf        => lv_errbuf
          , ov_retcode       => lv_retcode
          , ov_errmsg        => lv_errmsg
          , iv_to_cust_code  => lv_to_cust_code               -- 顧客コード
          , iv_to_cust_name  => lv_to_cust_name               -- 顧客名称
-- Start 2009/04/02 Ver_1.2 T1_0103 M.Hiruta
          , iv_delivery_date => l_sales_exp_rec.delivery_date -- 売上計上日（納品日）
-- End   2009/04/02 Ver_1.2 T1_0103 M.Hiruta
          , ov_to_staff_code => lv_to_staff_code              -- 担当営業コード
          );
        END IF;
--
        -- 売上拠点コードか営業担当員が存在しなかった場合（警告処理）
        IF ( lv_retcode = cv_status_warn )    THEN
          -- スキップ件数カウントアップ
          gn_skip_cnt := gn_skip_cnt + ln_counter + 1;
          RAISE warn_expt;
        -- エラー処理
        ELSIF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        -- =============================================================
        -- A-8.算出データの整合性チェック
        -- =============================================================
        -- A-6が呼び出されて最初のレコードのみA-8の処理を実行する。
        IF ( lb_proc_start_flg = TRUE ) THEN
          -- A-8
          chk_data(
            ov_errbuf             => lv_errbuf
          , ov_retcode            => lv_retcode
          , ov_errmsg             => lv_errmsg
          , in_dlv_qty_from       => in_dlv_qty_from        -- 売上振替元数量
          , in_sale_amount_from   => in_sale_amount_from    -- 売上振替元売上金額
          , in_pure_amount_from   => in_pure_amount_from    -- 売上振替元売上金額（税抜き）
          , in_business_cost_from => in_business_cost_from  -- 売上振替元営業原価
          , in_dlv_qty_to         => in_dlv_qty_to          -- 売上振替先数量
          , in_sale_amount_to     => in_sale_amount_to      -- 売上振替先売上金額
          , in_pure_amount_to     => in_pure_amount_to      -- 売上振替先売上金額（税抜き）
          , in_business_cost_to   => in_business_cost_to    -- 売上振替先営業原価
          , ob_adj_flg            => lb_data_adj_flg        -- 調整フラグ(Y：調整要 N：調整不要)
          );
--
          -- A-8でエラーが起きた場合の処理
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
          -- 以降のループ処理ではA-8を実行しないように実行フラグを変更する
          lb_proc_start_flg := FALSE;
        ELSIF ( lb_proc_start_flg = FALSE ) THEN
          -- A-8を実行しなかった場合、調整フラグに「調整不要」を設定する
          lb_data_adj_flg := FALSE;
        END IF;
--
        -- =============================================================
        -- A-9.算出データの調整
        -- =============================================================
        adj_data(
          ov_errbuf               => lv_errbuf
        , ov_retcode              => lv_retcode
        , ov_errmsg               => lv_errmsg
        , in_dlv_qty_from         => in_dlv_qty_from                        -- 売上振替元数量
        , in_sale_amount_from     => in_sale_amount_from                    -- 売上振替元売上金額
        , in_pure_amount_from     => in_pure_amount_from                    -- 売上振替元売上金額（税抜き）
        , in_business_cost_from   => in_business_cost_from                  -- 売上振替元営業原価
        , in_dlv_qty_to           => in_dlv_qty_to                          -- 売上振替先数量
        , in_sale_amount_to       => in_sale_amount_to                      -- 売上振替先売上金額
        , in_pure_amount_to       => in_pure_amount_to                      -- 売上振替先売上金額（税抜き）
        , in_business_cost_to     => in_business_cost_to                    -- 売上振替先営業原価
        , iv_from_base_code       => l_sales_exp_rec.selling_from_base_code -- 売上振替元拠点コード
        , iv_from_cust_code       => l_sales_exp_rec.selling_from_cust_code -- 売上振替元顧客コード
        , iv_to_base_code         => l_sales_exp_rec.selling_to_base_code   -- 売上振替先拠点コード
        , iv_to_cust_code         => l_sales_exp_rec.selling_to_cust_code   -- 売上振替先顧客コード
        , in_dlv_qty_detail       => l_sales_exp_rec.dlv_qty                -- 詳細足し込み_数量
        , in_sale_amount_detail   => l_sales_exp_rec.sale_amount            -- 詳細足し込み_売上金額
        , in_pure_amount_detail   => l_sales_exp_rec.pure_amount            -- 詳細足し込み_売上金額（税抜き）
        , in_business_cost_detail => l_sales_exp_rec.business_cost          -- 詳細足し込み_営業原価
        , ib_adj_flg              => lb_data_adj_flg                        -- A-8_調整フラグ
        , on_dlv_qty              => ln_dlv_qty                             -- 調整後_数量
        , on_sale_amount          => ln_sale_amount                         -- 調整後_売上金額
        , on_pure_amount          => ln_pure_amount                         -- 調整後_売上金額（税抜き）
        , on_business_cost        => ln_business_cost                       -- 調整後_営業原価
        , on_dlv_unit_price       => ln_dlv_unit_price                      -- 納品単価
        );
--
        -- A-9でエラーが起きた場合の処理
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        -- =============================================================
        -- A-10.売上実績振替レコード追加
        -- =============================================================
        -- 算出データの調整で取得した単価に数値がある場合、レコードの追加処理を実行します。
        -- 数値がない場合、レコードの追加処理はしません。
        IF ( ln_dlv_unit_price IS NOT NULL ) THEN
          ins_sales_exp(
            ov_errbuf               => lv_errbuf
          , ov_retcode              => lv_retcode
          , ov_errmsg               => lv_errmsg
          , iv_delivery_date        => iv_delivery_date                       -- 売上計上日
          , iv_to_base_code         => l_sales_exp_rec.selling_to_base_code   -- 拠点コード
          , iv_to_cust_code         => l_sales_exp_rec.selling_to_cust_code   -- 顧客コード
          , iv_to_staff_code        => lv_to_staff_code                       -- 担当営業コード
          , iv_cust_gyotai_sho      => l_sales_exp_rec.cust_gyotai_sho        -- 業態小分類
          , iv_demand_to_cust_code  => iv_bill_account_number                 -- 請求先顧客コード
          , iv_item_code            => l_sales_exp_rec.item_code              -- 品目コード
          , in_dlv_qty              => ln_dlv_qty                             -- 数量
          , iv_dlv_uom_code         => l_sales_exp_rec.dlv_uom_code           -- 単位
          , in_dlv_unit_price       => ln_dlv_unit_price                      -- 納品単価
          , in_sale_amount          => ln_sale_amount                         -- 売上金額
          , in_pure_amount          => ln_pure_amount                         -- 売上金額（税抜き）
          , in_business_cost        => ln_business_cost                       -- 営業原価
          , iv_tax_code             => l_sales_exp_rec.tax_code               -- 消費税コード
          , in_tax_rate             => l_sales_exp_rec.tax_rate               -- 消費税率
          , iv_from_base_code       => l_sales_exp_rec.selling_from_base_code -- 売上振替元拠点コード
          );
        END IF;
--
        -- A-10でエラーが起きた場合の処理
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        -- 処理成功件数カウントアップ
        ln_counter := ln_counter + 1;
--
    END LOOP;
--
    -- 処理成功件数格納
    gn_normal_cnt := gn_normal_cnt + ln_counter;
--
  EXCEPTION
    -- A-7警告処理
    WHEN warn_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_warn;
      -- カーソルのクローズ
      IF ( sales_exp_cur%ISOPEN ) THEN
        CLOSE sales_exp_cur;
      END IF;
--
-- Start 2009/04/02 Ver_1.2 T1_0190 M.Hiruta
    -- 基準数量取得エラー
    WHEN convert_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      cv_appli_short_name_xxcok
                    , cv_msg_xxcok1_10452
                    , cv_item_code
                    , l_sales_exp_rec.item_code
                    , cv_dlv_uom_code
                    , l_sales_exp_rec.dlv_uom_code
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--  -- 共通関数OTHERS例外ハンドラ
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
-- End   2009/04/02 Ver_1.2 T1_0190 M.Hiruta
--
    -- 機能内プロシージャエラー例外ハンドラ
    WHEN global_process_expt THEN
      -- 処理ステータスをエラーとしてA-6を終了する。
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- カーソルのクローズ
      IF ( sales_exp_cur%ISOPEN ) THEN
        CLOSE sales_exp_cur;
      END IF;
--
    -- OTHERS例外ハンドラ
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- カーソルのクローズ
      IF ( sales_exp_cur%ISOPEN ) THEN
        CLOSE sales_exp_cur;
      END IF;
  END get_sales_exp;
--
  /**********************************************************************************
   * Procedure Name   : get_sales_exp_sum
   * Description      : 販売実績情報テーブル集計抽出(A-5)
   ***********************************************************************************/
  PROCEDURE get_sales_exp_sum(
    ov_errbuf  OUT VARCHAR2
  , ov_retcode OUT VARCHAR2
  , ov_errmsg  OUT VARCHAR2
  )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(17) := 'get_sales_exp_sum';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf              VARCHAR2(5000) DEFAULT NULL;
    lv_retcode             VARCHAR2(1)    DEFAULT NULL;
    lv_errmsg              VARCHAR2(5000) DEFAULT NULL;
    lv_slip_no             VARCHAR2(9)    DEFAULT NULL;  -- 伝票番号
    lv_sequence_s02        VARCHAR2(8)    DEFAULT NULL;  -- シーケンス格納用
    lv_bill_account_number VARCHAR2(9)    DEFAULT NULL;  -- 請求先顧客コード
    ln_offset_chk          NUMBER         DEFAULT NULL;  -- A-11実行確認用
    -- ===============================
    -- ローカルカーソル
    -- ===============================
    -- 販売実績情報（集計）
    CURSOR sales_exp_sum_cur
    IS
-- Start 2009/04/02 Ver_1.2 T1_0115 M.Hiruta
--      SELECT in_A.inspect_date                 AS inspect_date            -- 売上計上日（検収日）
      SELECT in_A.delivery_date                AS delivery_date           -- 売上計上日（納品日）
-- End   2009/04/02 Ver_1.2 T1_0115 M.Hiruta
           , in_A.selling_from_base_code       AS selling_from_base_code  -- 売上振替元拠点コード
           , in_A.selling_from_cust_code       AS selling_from_cust_code  -- 売上振替元顧客コード
           , in_A.item_code                    AS item_code               -- 品目コード
           , in_A.dlv_qty_from                 AS dlv_qty_from            -- 売上振替元数量
           , in_A.sale_amount_from             AS sale_amount_from        -- 売上振替元売上金額
           , in_A.pure_amount_from             AS pure_amount_from        -- 売上振替元売上金額（税抜き）
           , in_A.business_cost_from           AS business_cost_from      -- 売上振替元営業原価
           , SUM(ROUND(in_A.dlv_qty_to))       AS dlv_qty_to              -- 売上振替先数量
           , SUM(ROUND(in_A.sale_amount_to))   AS sale_amount_to          -- 売上振替先売上金額
           , SUM(ROUND(in_A.pure_amount_to))   AS pure_amount_to          -- 売上振替先売上金額（税抜き）
           , SUM(ROUND(in_A.business_cost_to)) AS business_cost_to        -- 売上振替先営業原価
      FROM   (-- インラインビューA_START
-- Start 2009/04/02 Ver_1.2 T1_0115 M.Hiruta
--             SELECT in_B.inspect_date                                       AS inspect_date
             SELECT in_B.delivery_date                                      AS delivery_date
-- End   2009/04/02 Ver_1.2 T1_0115 M.Hiruta
                  , in_B.sales_base_code                                    AS selling_from_base_code
                  , in_B.ship_to_customer_code                              AS selling_from_cust_code
                  , in_B.item_code                                          AS item_code
                  , in_B.dlv_qty                                            AS dlv_qty_from
                  , in_B.sale_amount                                        AS sale_amount_from
                  , in_B.pure_amount                                        AS pure_amount_from
                  , in_B.business_cost                                      AS business_cost_from
                  , (in_B.dlv_qty * ( xsri.selling_trns_rate / 100 ))       AS dlv_qty_to
                  , (in_B.sale_amount * ( xsri.selling_trns_rate / 100 ))   AS sale_amount_to
                  , (in_B.pure_amount * ( xsri.selling_trns_rate / 100 ))   AS pure_amount_to
                  , (in_B.business_cost * ( xsri.selling_trns_rate / 100 )) AS business_cost_to
             FROM   xxcok_selling_rate_info xsri     -- 売上振替割合情報テーブル
                  , hz_cust_accounts        hca_from -- 売上振替元情報用顧客マスタ
                  , hz_parties              hp_from
                  , xxcmm_cust_accounts     xca_from
                  , hz_cust_accounts        hca_to   -- 売上振替先情報用顧客マスタ
                  , hz_parties              hp_to
                  , xxcmm_cust_accounts     xca_to
                  , xxcok_selling_from_info xsfi
                  , xxcok_selling_to_info   xsti
                  , (-- インラインビューB_START
-- Start 2009/04/02 Ver_1.2 T1_0115 M.Hiruta
--                    SELECT TO_CHAR(xseh.inspect_date , 'YYYYMM')  AS inspect_date              -- 売上計上日の年月
                    SELECT TO_CHAR(xseh.delivery_date , 'YYYYMM') AS delivery_date             -- 売上計上日の年月
-- End   2009/04/02 Ver_1.2 T1_0115 M.Hiruta
                         , xseh.sales_base_code                   AS sales_base_code           -- 売上拠点コード
                         , xseh.ship_to_customer_code             AS ship_to_customer_code     -- 顧客【納品先】
                         , xsel.item_code                         AS item_code                 -- 品目コード
                         , SUM(xsel.dlv_qty)                      AS dlv_qty                   -- 納品数量
                         , SUM(xsel.sale_amount)                  AS sale_amount               -- 売上金額
                         , SUM(xsel.pure_amount)                  AS pure_amount               -- 売上金額（税抜き）
                         , SUM(xsel.business_cost * xxcok_common_pkg.get_uom_conversion_qty_f( -- 基準単位換算共通関数
                                                      xsel.item_code                           -- 品目コード
                                                    , xsel.dlv_uom_code                        -- 単位
                                                    , xsel.dlv_qty                             -- 数量
                                                    )) AS business_cost                        -- 営業原価
                    FROM   xxcos_sales_exp_lines   xsel
                         , xxcos_sales_exp_headers xseh
                    WHERE  xsel.sales_exp_header_id  = xseh.sales_exp_header_id
                    AND    xsel.business_cost       IS NOT NULL
                    AND    xseh.dlv_invoice_class   IN ( cv_invoice_class_01
                                                       , cv_invoice_class_02
                                                       , cv_invoice_class_03
                                                       , cv_invoice_class_04
                                                       )
-- Start 2009/04/02 Ver_1.2 T1_0115 M.Hiruta
--                    AND    TO_CHAR(xseh.inspect_date , 'YYYYMM') IN ( gv_current_month , gv_past_month )
                    AND    TO_CHAR(xseh.delivery_date , 'YYYYMM') IN ( gv_current_month , gv_past_month )
-- End   2009/04/02 Ver_1.2 T1_0115 M.Hiruta
                    GROUP BY
-- Start 2009/04/02 Ver_1.2 T1_0196 M.Hiruta
--                           xseh.inspect_date
                           TO_CHAR(xseh.delivery_date , 'YYYYMM')
-- End   2009/04/02 Ver_1.2 T1_0196 M.Hiruta
                         , xseh.sales_base_code
                         , xseh.ship_to_customer_code
                         , xsel.item_code
                    ) in_B
                    -- インラインビューB_END
             WHERE  hca_from.party_id             = hp_from.party_id
             AND    hca_from.cust_account_id      = xca_from.customer_id
             AND    hca_to.party_id               = hp_to.party_id
             AND    hca_to.cust_account_id        = xca_to.customer_id
             AND    xsti.selling_to_cust_code     = hca_to.account_number
             AND    xsfi.selling_from_cust_code   = hca_from.account_number
             AND    xsti.selling_from_info_id     = xsfi.selling_from_info_id
             AND    xsri.selling_from_base_code   = xsfi.selling_from_base_code
             AND    xsri.selling_from_cust_code   = xsfi.selling_from_cust_code
             AND    xsri.selling_to_cust_code     = xsti.selling_to_cust_code
             AND    xsri.selling_from_base_code   = in_B.sales_base_code
             AND    xsri.selling_from_cust_code   = in_B.ship_to_customer_code
             AND    xsri.invalid_flag             = cv_invalid_0_flg
             AND    xca_to.selling_transfer_div   = cv_transfer_div
             AND    xca_to.chain_store_code      IS NULL
             AND    hca_to.customer_class_code    = cv_cust_class_customer
             AND    hp_to.duns_number_c           = cv_duns_number_c
             AND    xca_from.selling_transfer_div = cv_transfer_div
             AND    xca_from.chain_store_code    IS NULL
             AND    hca_from.customer_class_code  = cv_cust_class_customer
             AND    hp_from.duns_number_c         = cv_duns_number_c
             AND    xsti.invalid_flag             = cv_invalid_0_flg
             AND    xsti.start_month             <= gv_current_month
             ) in_A
             -- インラインビューA_END
      GROUP BY
-- Start 2009/04/02 Ver_1.2 T1_0115 M.Hiruta
--             in_A.inspect_date
             in_A.delivery_date
-- End   2009/04/02 Ver_1.2 T1_0115 M.Hiruta
           , in_A.selling_from_base_code
           , in_A.selling_from_cust_code
           , in_A.item_code
           , in_A.dlv_qty_from
           , in_A.sale_amount_from
           , in_A.pure_amount_from
           , in_A.business_cost_from;
--
    -- カーソル型レコード
    l_sales_exp_sum_rec sales_exp_sum_cur%ROWTYPE;
--
  BEGIN
    -- 処理ステータスの初期化
    ov_retcode := cv_status_normal;
--
    -- ===============================
    -- 1.販売実績情報テーブル集計抽出
    -- ===============================
    OPEN sales_exp_sum_cur;
    LOOP
      FETCH sales_exp_sum_cur INTO l_sales_exp_sum_rec;
      EXIT WHEN sales_exp_sum_cur%NOTFOUND;
        -- セーブポイント設定
        SAVEPOINT sales_exp_save;
--
        -- 請求先顧客コード取得
        lv_bill_account_number := xxcok_common_pkg.get_bill_to_cust_code_f(
                                    l_sales_exp_sum_rec.selling_from_cust_code
                                  );
--
        -- =============================================================
        -- A-6 販売実績情報テーブル抽出
        -- =============================================================
        get_sales_exp(
          ov_errbuf                 => lv_errbuf
        , ov_retcode                => lv_retcode
        , ov_errmsg                 => lv_errmsg
-- Start 2009/04/02 Ver_1.2 T1_0115 M.Hiruta
--        , iv_inspect_date           => l_sales_exp_sum_rec.inspect_date           -- 売上計上日
        , iv_delivery_date          => l_sales_exp_sum_rec.delivery_date          -- 売上計上日
-- End   2009/04/02 Ver_1.2 T1_0115 M.Hiruta
        , iv_selling_from_base_code => l_sales_exp_sum_rec.selling_from_base_code -- 売上振替元拠点コード
        , iv_selling_from_cust_code => l_sales_exp_sum_rec.selling_from_cust_code -- 売上振替元顧客コード
        , iv_bill_account_number    => lv_bill_account_number                     -- 請求先顧客コード
        , iv_item_code              => l_sales_exp_sum_rec.item_code              -- 品目コード
        , in_dlv_qty_from           => l_sales_exp_sum_rec.dlv_qty_from           -- 売上振替元数量
        , in_sale_amount_from       => l_sales_exp_sum_rec.sale_amount_from       -- 売上振替元売上金額
        , in_pure_amount_from       => l_sales_exp_sum_rec.pure_amount_from       -- 売上振替元売上金額（税抜き）
        , in_business_cost_from     => l_sales_exp_sum_rec.business_cost_from     -- 売上振替元営業原価
        , in_dlv_qty_to             => l_sales_exp_sum_rec.dlv_qty_to             -- 売上振替先数量
        , in_sale_amount_to         => l_sales_exp_sum_rec.sale_amount_to         -- 売上振替先売上金額
        , in_pure_amount_to         => l_sales_exp_sum_rec.pure_amount_to         -- 売上振替先売上金額（税抜き）
        , in_business_cost_to       => l_sales_exp_sum_rec.business_cost_to       -- 売上振替先営業原価
        );
--
        -- A-6の処理ステータスが警告の場合、A-5の処理ステータスに警告をセットする。
        IF ( lv_retcode = cv_status_warn ) THEN
          ov_retcode := cv_status_warn;
--
        -- A-6の処理ステータスがエラーの場合、例外処理へ遷移する。
        ELSIF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        -- =============================================================
        -- A-11 売上実績振替元相殺データ抽出
        -- =============================================================
        -- 相殺対象であるか確認するため、振替元と振替先が同じ顧客の振替割合が存在するかどうかを
        -- チェックします。
        BEGIN
          ln_offset_chk := NULL;
--
          SELECT ROWNUM
          INTO   ln_offset_chk
          FROM   xxcok_selling_rate_info xsri
          WHERE  xsri.selling_from_base_code  = l_sales_exp_sum_rec.selling_from_base_code -- 売上振替元拠点コード
          AND    xsri.selling_from_cust_code  = l_sales_exp_sum_rec.selling_from_cust_code -- 売上振替元顧客コード
          AND    xsri.selling_to_cust_code    = l_sales_exp_sum_rec.selling_from_cust_code -- 売上振替元顧客コード
          AND    xsri.invalid_flag            = cv_invalid_0_flg
          AND    ROWNUM = 1;
        EXCEPTION
          WHEN OTHERS THEN
            NULL;
        END;
--
        -- チェックした結果、振替割合が存在しない場合、売上実績振替元相殺データ抽出を実行する。
        IF ( ln_offset_chk IS NULL ) THEN
          --A-11
          get_offset_exp(
            ov_errbuf                 => lv_errbuf
          , ov_retcode                => lv_retcode
          , ov_errmsg                 => lv_errmsg
-- Start 2009/04/02 Ver_1.2 T1_0115 M.Hiruta
--          , iv_inspect_date           => l_sales_exp_sum_rec.inspect_date           -- 売上計上日
          , iv_delivery_date          => l_sales_exp_sum_rec.delivery_date          -- 売上計上日
-- End   2009/04/02 Ver_1.2 T1_0115 M.Hiruta
          , iv_selling_from_base_code => l_sales_exp_sum_rec.selling_from_base_code -- 売上振替元拠点コード
          , iv_selling_from_cust_code => l_sales_exp_sum_rec.selling_from_cust_code -- 売上振替元顧客コード
          , iv_bill_account_number    => lv_bill_account_number                     -- 請求先顧客コード
          , iv_item_code              => l_sales_exp_sum_rec.item_code              -- 品目コード
          );
--
          -- A-11の処理ステータスが警告の場合、A-5の処理ステータスに警告をセットする。
          IF ( lv_retcode = cv_status_warn ) THEN
            ov_retcode := cv_status_warn;
--
          -- A-11の処理ステータスがエラーの場合、例外処理へ遷移する。
          ELSIF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
--
        -- =============================================================
        -- A-12 伝票番号明細番号更新対象抽出
        -- =============================================================
        get_slip_detail_target(
          ov_errbuf  => lv_errbuf
        , ov_retcode => lv_retcode
        , ov_errmsg  => lv_errmsg
        );
--
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
    END LOOP;
--
  EXCEPTION
    -- 呼び出したモジュールでエラーが起こった場合
    WHEN global_process_expt THEN
      -- 処理ステータスをエラーとしてA-5を終了する。
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- カーソルのクローズ
      IF ( sales_exp_sum_cur%ISOPEN ) THEN
        CLOSE sales_exp_sum_cur;
      END IF;
--
    -- 共通関数OTHERS例外ハンドラ
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- カーソルのクローズ
      IF ( sales_exp_sum_cur%ISOPEN ) THEN
        CLOSE sales_exp_sum_cur;
      END IF;
--
    -- OTHERS例外ハンドラ
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- カーソルのクローズ
      IF ( sales_exp_sum_cur%ISOPEN ) THEN
        CLOSE sales_exp_sum_cur;
      END IF;
  END get_sales_exp_sum;
--
  /**********************************************************************************
   * Procedure Name   : upd_correction_flg
   * Description      : 振戻フラグ更新(A-4)
   ***********************************************************************************/
  PROCEDURE upd_correction_flg(
    ov_errbuf  OUT VARCHAR2
  , ov_retcode OUT VARCHAR2
  , ov_errmsg  OUT VARCHAR2
  )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(18) := 'upd_correction_flg';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf           VARCHAR2(5000) DEFAULT NULL;
    lv_retcode          VARCHAR2(1)    DEFAULT NULL;
    lv_errmsg           VARCHAR2(5000) DEFAULT NULL;
    -- ===============================
    -- ローカルカーソル
    -- ===============================
    -- ロック取得用
    CURSOR update_lock_cur
    IS
      SELECT 'X'
      FROM   xxcok_selling_trns_info xsti
      WHERE  xsti.correction_flag                   = cv_correction_off_flg -- 振戻オフ
      AND    xsti.report_decision_flag              = cv_report_news_flg    -- 速報
      AND    TO_CHAR(xsti.selling_date , 'YYYYMM') IN ( gv_current_month , gv_past_month )
      FOR UPDATE NOWAIT;
    -- ===============================
    -- ローカル例外
    -- ===============================
    update_error_expt EXCEPTION; -- 売上実績振替情報テーブルアップデートエラー
--
  BEGIN
    -- 処理ステータスの初期化
    ov_retcode := cv_status_normal;
--
    -- ===============================
    -- 1.売上実績振替情報テーブル更新対象データのロック取得（ロックの取得に失敗した場合は例外処理へ遷移）
    -- ===============================
    OPEN  update_lock_cur;
    CLOSE update_lock_cur;
--
    -- ===============================
    -- 2.売上実績振替情報テーブル更新（更新に失敗した場合は例外処理へ遷移）
    -- ===============================
    BEGIN
      UPDATE xxcok_selling_trns_info xsti
      SET
          xsti.correction_flag        = cv_correction_on_flg -- 振戻フラグ:オン
        , xsti.last_updated_by        = cn_last_updated_by
        , xsti.last_update_date       = SYSDATE
        , xsti.last_update_login      = cn_last_update_login
        , xsti.request_id             = cn_request_id
        , xsti.program_application_id = cn_program_application_id
        , xsti.program_id             = cn_program_id
        , xsti.program_update_date    = SYSDATE
      WHERE xsti.correction_flag      = cv_correction_off_flg
      AND   xsti.report_decision_flag = cv_report_news_flg
      AND   TO_CHAR(xsti.selling_date , 'YYYYMM') IN ( gv_current_month , gv_past_month );
    EXCEPTION
      WHEN OTHERS THEN
        lv_retcode := cv_status_error;
    END;
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE update_error_expt;
    END IF;
--
  EXCEPTION
    -- ロックエラー
    WHEN lock_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      cv_appli_short_name_xxcok
                    , cv_msg_xxcok1_10012
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    -- データ更新エラー
    WHEN update_error_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      cv_appli_short_name_xxcok
                    , cv_msg_xxcok1_10035
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    -- OTHERS例外ハンドラ
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
  END upd_correction_flg;
--
  /**********************************************************************************
   * Procedure Name   : ins_correction
   * Description      : 売上実績振替情報振戻データ作成(A-3)
   ***********************************************************************************/
  PROCEDURE ins_correction(
    ov_errbuf  OUT VARCHAR2
  , ov_retcode OUT VARCHAR2
  , ov_errmsg  OUT VARCHAR2
  )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(14) := 'ins_correction';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf           VARCHAR2(5000) DEFAULT NULL;
    lv_retcode          VARCHAR2(1)    DEFAULT NULL;
    lv_errmsg           VARCHAR2(5000) DEFAULT NULL;
--
  BEGIN
    -- 処理ステータスの初期化
    ov_retcode := cv_status_normal;
--
    -- ===============================
    -- 1.売上実績振替以上報テーブルへ振戻データを作成（データ作成エラー時は例外処理へ遷移）
    -- ===============================
    INSERT INTO xxcok_selling_trns_info (
                  selling_trns_info_id  -- 売上実績振替情報ID
                , selling_trns_type     -- 実績振替区分
                , slip_no               -- 伝票番号
                , detail_no             -- 明細番号
                , selling_date          -- 売上計上日
                , selling_type          -- 売上区分
                , selling_return_type   -- 売上返品区分
                , delivery_slip_type    -- 納品伝票区分
                , base_code             -- 拠点コード
                , cust_code             -- 顧客コード
                , selling_emp_code      -- 担当営業コード
                , cust_state_type       -- 顧客業態区分
                , delivery_form_type    -- 納品形態区分
                , article_code          -- 物件コード
                , card_selling_type     -- カード売り区分
                , checking_date         -- 検収日
                , demand_to_cust_code   -- 請求先顧客コード
                , h_c                   -- Ｈ＆Ｃ
                , column_no             -- コラムNo.
                , item_code             -- 品目コード
                , qty                   -- 数量
                , unit_type             -- 単位
                , delivery_unit_price   -- 納品単価
                , selling_amt           -- 売上金額
                , selling_amt_no_tax    -- 売上金額（税抜き）
                , trading_cost          -- 営業原価
                , selling_cost_amt      -- 売上原価金額
                , tax_code              -- 消費税コード
                , tax_rate              -- 消費税率
                , delivery_base_code    -- 納品拠点コード
                , registration_date     -- 登録業務日付
                , correction_flag       -- 振戻フラグ
                , report_decision_flag  -- 速報確定フラグ
                , info_interface_flag   -- 情報系I/Fフラグ
                , gl_interface_flag     -- 仕訳作成フラグ
                , org_slip_number       -- 元伝票番号
                , created_by
                , creation_date
                , last_updated_by
                , last_update_date
                , last_update_login
                , request_id
                , program_application_id
                , program_id
                , program_update_date
                )
                SELECT
                  xxcok_selling_trns_info_s01.NEXTVAL -- selling_trns_info_id
                , xsti.selling_trns_type              -- selling_trns_type
                , xsti.slip_no                        -- slip_no
                , xsti.detail_no                      -- detail_no
-- Start 2009/06/04 Ver_1.4 T1_1325 M.Hiruta
--                , xsti.selling_date                   -- selling_date
                , (
                  CASE
                    WHEN xsti.selling_date BETWEEN TO_DATE( gv_past_month , 'YYYYMM' )
                                               AND LAST_DAY( TO_DATE( gv_past_month , 'YYYYMM' ) )THEN
                      LAST_DAY(ADD_MONTHS(gd_process_date,-1))
                    WHEN  xsti.selling_date BETWEEN TO_DATE( gv_current_month , 'YYYYMM' )
                                               AND LAST_DAY( TO_DATE( gv_current_month , 'YYYYMM' ) )THEN
                      gd_process_date
                  END
                  )
-- End   2009/06/04 Ver_1.4 T1_1325 M.Hiruta
                , xsti.selling_type                   -- selling_type
                , selling_return_type                 -- selling_return_type
                , xsti.delivery_slip_type             -- delivery_slip_type
                , xsti.base_code                      -- base_code
                , xsti.cust_code                      -- cust_code
                , xsti.selling_emp_code               -- selling_emp_code
                , xsti.cust_state_type                -- cust_state_type
                , xsti.delivery_form_type             -- delivery_form_type
                , xsti.article_code                   -- article_code
                , xsti.card_selling_type              -- card_selling_type
                , xsti.checking_date                  -- checking_date
                , xsti.demand_to_cust_code            -- demand_to_cust_code
                , xsti.h_c                            -- h_c
                , xsti.column_no                      -- column_no
                , xsti.item_code                      -- item_code
                , xsti.qty                            -- qty
                , xsti.unit_type                      -- unit_type
                , xsti.delivery_unit_price            -- delivery_unit_price
                , ( xsti.selling_amt * -1 )           -- selling_amt
                , ( xsti.selling_amt_no_tax * -1 )    -- selling_amt_no_tax
                , ( xsti.trading_cost * -1 )          -- trading_cost
                , xsti.selling_cost_amt               -- selling_cost_amt
                , xsti.tax_code                       -- tax_code
                , xsti.tax_rate                       -- tax_rate
                , xsti.delivery_base_code             -- delivery_base_code
-- Start 2009/07/03 Ver_1.5 0000422 M.Hiruta REPAIR
--                , xsti.registration_date              -- registration_date
                , gd_process_date                     -- registration_date
-- End   2009/07/03 Ver_1.5 0000422 M.Hiruta REPAIR
                , cv_correction_on_flg                -- correction_flag
                , xsti.report_decision_flag           -- report_decision_flag
                , cv_info_if_flag                     -- info_interface_flag
                , cv_gl_if_flag                       -- gl_interface_flag
                , xsti.org_slip_number                -- org_slip_number
                , cn_created_by
                , SYSDATE
                , cn_last_updated_by
                , SYSDATE
                , cn_last_update_login
                , cn_request_id
                , cn_program_application_id
                , cn_program_id
                , SYSDATE
                FROM  xxcok_selling_trns_info xsti
                WHERE xsti.correction_flag        = cv_correction_off_flg
                AND   xsti.report_decision_flag   = cv_report_news_flg
                AND   TO_CHAR(xsti.selling_date , 'YYYYMM') IN ( gv_current_month , gv_past_month );
--
  EXCEPTION
    -- OTHERS例外ハンドラ（インサートエラー）
    WHEN OTHERS THEN
      -- エラーメッセージ取得
      lv_errmsg    := xxccp_common_pkg.get_msg(
                        cv_appli_short_name_xxcok
                      , cv_msg_xxcok1_10033
                      );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
  END ins_correction;
--
  /**********************************************************************************
   * Procedure Name   : get_period
   * Description      : 処理対象会計期間取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_period(
    ov_errbuf  OUT VARCHAR2
  , ov_retcode OUT VARCHAR2
  , ov_errmsg  OUT VARCHAR2
  )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(10) := 'get_period';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf           VARCHAR2(5000) DEFAULT NULL;
    lv_retcode          VARCHAR2(1)    DEFAULT NULL;
    lv_errmsg           VARCHAR2(5000) DEFAULT NULL;
    lb_check_period_flg BOOLEAN        DEFAULT TRUE;  -- 会計期間オープン/未オープンチェックフラグ
    lv_proc_date        VARCHAR2(10)   DEFAULT NULL;  -- 業務日付の年月
    ld_past_month       DATE           DEFAULT NULL;  -- 先月の日付
    -- ===============================
    -- ローカル例外
    -- ===============================
    chk_period_open_expt  EXCEPTION; -- 会計期間未オープンエラー
--
  BEGIN
    -- 処理ステータスの初期化
    ov_retcode := cv_status_normal;
--
    -- ===============================
    -- 1.当月会計期間の状態チェック（会計期間が未オープンである場合は例外処理へ遷移）
    -- ===============================
    lb_check_period_flg := xxcok_common_pkg.check_acctg_period_f(
                             in_set_of_books_id        => gn_set_of_books_id
                           , id_proc_date              => gd_process_date
                           , iv_application_short_name => cv_appli_short_name_ar
                           );
--
    IF ( lb_check_period_flg = TRUE ) THEN
      -- 当月会計期間がオープン状態である場合は当月日付をグローバル変数へ格納
      gv_current_month := TO_CHAR(gd_process_date , 'YYYYMM');
    ELSE
      -- エラーメッセージのトークン用にシステム日付の年月を取得する
      lv_proc_date := TO_CHAR(gd_process_date,'YYYY/MM');
      RAISE chk_period_open_expt;
    END IF;
--
    -- ===============================
    -- 2.先月会計期間の状態チェック
    -- ===============================
    -- バッチ実行日の先月の日付を取得
    -- ADD_MONTHS パラメータ1の月にパラメータ2の月を足します
    -- TRUNC      パラメータ1の値（日付型）をパラメータ2で指定した単位以下を切捨てます
    -- 以下で取得できるのは、日にちが1日の先月会計期間です
    ld_past_month := TRUNC(ADD_MONTHS(gd_process_date,-1),'MONTH');
    lb_check_period_flg := xxcok_common_pkg.check_acctg_period_f(
                             in_set_of_books_id        => gn_set_of_books_id
                           , id_proc_date              => ld_past_month
                           , iv_application_short_name => cv_appli_short_name_ar
                           );
--
    -- 先月会計期間がオープン状態である場合は先月日付をグローバル変数へ格納
    IF ( lb_check_period_flg = TRUE ) THEN
      gv_past_month := TO_CHAR(ld_past_month , 'YYYYMM');
    END IF;
--
  EXCEPTION
    -- 会計期間未オープンエラー
    WHEN chk_period_open_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      cv_appli_short_name_xxcok
                    , cv_msg_xxcok1_00042
                    , cv_proc_date
                    , lv_proc_date
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    -- 共通関数OTHERS例外ハンドラ
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
    -- OTHERS例外ハンドラ
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
  END get_period;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf  OUT VARCHAR2
  , ov_retcode OUT VARCHAR2
  , ov_errmsg  OUT VARCHAR2
  )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(4) := 'init';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf     VARCHAR2(5000) DEFAULT NULL;
    lv_retcode    VARCHAR2(1)    DEFAULT NULL;
    lv_errmsg     VARCHAR2(5000) DEFAULT NULL;
    lv_out_msg    VARCHAR2(1000) DEFAULT NULL;  -- メッセージ出力変数
    lb_msg_return BOOLEAN        DEFAULT TRUE;  -- メッセージ関数戻り値用
    -- 会計帳簿情報取得の際に受取る不要な引数の受取り用
    lv_sobn_dummy VARCHAR2(50); -- 会計帳簿名
    ln_cai_dummy  NUMBER;       -- 勘定体系ID
    lv_psn_dummy  VARCHAR2(50); -- カレンダ名
    ln_asc_dummy  NUMBER;       -- AFFセグメント定義数
    lv_cc_dummy   VARCHAR2(10); -- 機能通貨コード
    -- ===============================
    -- ローカル例外
    -- ===============================
    chk_parameter_expt    EXCEPTION; -- パラメータチェックエラー
    get_process_date_expt EXCEPTION; -- 業務日付取得エラー
--
  BEGIN
    -- 処理ステータスの初期化
    ov_retcode := cv_status_normal;
--
    -- ===============================
    -- 1.コンカレント入力パラメータのメッセージ出力
    -- ===============================
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_short_name_xxcok
                  , cv_msg_xxcok1_00023
                  , cv_info_class
                  , gv_info_class
                  );
--
    lb_msg_return := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                     , lv_out_msg
                     , 1
                     );
--
    -- ===============================
    -- 2.情報種別の値を確認（想定した値で無い場合は例外処理へ遷移）
    -- ===============================
    IF ( gv_info_class NOT IN ( cv_report_news_flg , cv_report_decision_flg ) ) THEN
      RAISE chk_parameter_expt;
    END IF;
--
    -- ===============================
    -- 3.会計帳簿ID取得
    -- ===============================
    xxcok_common_pkg.get_set_of_books_info_p(
      ov_errbuf            => lv_errbuf
    , ov_retcode           => lv_retcode
    , ov_errmsg            => lv_errmsg
    , on_set_of_books_id   => gn_set_of_books_id -- 会計帳簿ID
    , ov_set_of_books_name => lv_sobn_dummy      -- 不要
    , on_chart_acct_id     => ln_cai_dummy       -- 不要
    , ov_period_set_name   => lv_psn_dummy       -- 不要
    , on_aff_segment_cnt   => ln_asc_dummy       -- 不要
    , ov_currency_code     => lv_cc_dummy        -- 不要
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      -- 会計帳簿ID取得エラーメッセージ出力
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_short_name_xxcok
                    , cv_msg_xxcok1_00008
                    );
--
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         FND_FILE.OUTPUT
                       , lv_out_msg
                       , 0
                       );
--
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 4.業務日付取得
    -- ===============================
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    IF ( gd_process_date IS NULL ) THEN
      RAISE get_process_date_expt;
    END IF;
--
  EXCEPTION
    -- パラメータチェックエラー
    WHEN chk_parameter_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_appli_short_name_xxcok
                   , cv_msg_xxcok1_10036
                   , cv_info_class
                   , gv_info_class  -- 情報種別
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    -- 共通関数例外ハンドラ(会計帳簿ID取得エラー)
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- 業務日付取得エラー
    WHEN get_process_date_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_appli_short_name_xxcok
                   , cv_msg_xxcok1_00028
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    -- 共通関数OTHERS例外ハンドラ
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
    -- OTHERS例外ハンドラ
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf  OUT VARCHAR2
  , ov_retcode OUT VARCHAR2
  , ov_errmsg  OUT VARCHAR2
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(7) := 'submain';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL;
    lv_retcode  VARCHAR2(1)    DEFAULT NULL;
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL;
--
  BEGIN
    -- パラメータ初期化
    ov_retcode := cv_status_normal;
--
    -- =============================================================
    -- A-1 初期処理 (リターンコードがエラーの場合はバッチ処理をエラー終了します)
    -- =============================================================
    init(
      ov_errbuf  => lv_errbuf
    , ov_retcode => lv_retcode
    , ov_errmsg  => lv_errmsg
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =============================================================
    -- A-2 処理対象会計期間取得 (リターンコードがエラーの場合はバッチ処理をエラー終了します)
    -- =============================================================
    get_period(
      ov_errbuf  => lv_errbuf
    , ov_retcode => lv_retcode
    , ov_errmsg  => lv_errmsg
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =============================================================
    -- A-3 売上実績振替情報振戻データ作成 (リターンコードがエラーの場合はバッチ処理をエラー終了します)
    -- =============================================================
    ins_correction(
      ov_errbuf  => lv_errbuf
    , ov_retcode => lv_retcode
    , ov_errmsg  => lv_errmsg
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =============================================================
    -- A-4 振戻フラグ更新 (リターンコードがエラーの場合はバッチ処理をエラー終了します)
    -- =============================================================
    upd_correction_flg(
      ov_errbuf  => lv_errbuf
    , ov_retcode => lv_retcode
    , ov_errmsg  => lv_errmsg
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =============================================================
    -- A-5 販売実績情報テーブル集計抽出 (リターンコードがエラーの場合はバッチ処理をエラー終了します)
    -- =============================================================
    get_sales_exp_sum(
      ov_errbuf  => lv_errbuf
    , ov_retcode => lv_retcode
    , ov_errmsg  => lv_errmsg
    );
--
    IF ( lv_retcode = cv_status_error )   THEN
      RAISE global_process_expt;
--
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      ov_retcode := lv_retcode;
    END IF;
--
  EXCEPTION
    -- 処理部共通例外ハンドラ
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- OTHERS例外ハンドラ
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
  PROCEDURE main(
    errbuf        OUT VARCHAR2
  , retcode       OUT VARCHAR2
  , iv_info_class  IN VARCHAR2
  )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(4)  := 'main';             -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;  -- エラーメッセージ
    lv_retcode      VARCHAR2(1)    DEFAULT NULL;  -- リターンコード
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;  -- ユーザーエラーメッセージ
    lv_out_msg      VARCHAR2(1000) DEFAULT NULL;  -- メッセージ変数
    lv_message_code VARCHAR2(100)  DEFAULT NULL;  -- メッセージコード
    lb_msg_return   BOOLEAN        DEFAULT TRUE;
--
  BEGIN
    -- パラメータをグローバル変数へ格納
    gv_info_class := iv_info_class; -- 情報種別
--
    -- ===============================
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    -- ===============================
    xxccp_common_pkg.put_log_header(
      ov_retcode => lv_retcode
    , ov_errbuf  => lv_errbuf
    , ov_errmsg  => lv_errmsg
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         FND_FILE.OUTPUT
                       , lv_errmsg
                       , 1
                       );
      RAISE global_api_expt;
    END IF;
--
    -- ==============================================================
    -- submainの呼び出し
    -- ==============================================================
    submain(
      ov_errbuf  => lv_errbuf
    , ov_retcode => lv_retcode
    , ov_errmsg  => lv_errmsg
    );
--
    -- ===============================
    -- エラー出力
    -- ===============================
    -- リターンコードがエラーである場合はエラーメッセージを出力する
    IF ( lv_retcode = cv_status_error ) THEN
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         FND_FILE.OUTPUT
                       , lv_errmsg
                       , 1
                       );
--
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         FND_FILE.LOG
                       , lv_errbuf
                       , 0
                       );
    END IF;
--
    -- ===============================
    -- 警告処理時空行出力
    -- ===============================
    -- リターンコードが警告である場合は空行を出力する
    IF ( lv_retcode = cv_status_warn ) THEN
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         FND_FILE.OUTPUT
                       , NULL
                       , 1
                       );
    END IF;
--
    -- ===============================
    -- 対象件数出力
    -- ===============================
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_short_name_xxccp
                  , cv_target_count_msg
                  , cv_token_name1
                  , TO_CHAR( gn_target_cnt )
                  );
--
    lb_msg_return := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                     , lv_out_msg
                     , 0
                     );
--
    -- ===============================
    -- 成功件数出力
    -- ===============================
    IF ( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := 0;
    END IF;
--
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_short_name_xxccp
                  , cv_normal_count_msg
                  , cv_token_name1
                  , TO_CHAR( gn_normal_cnt )
                  );
--
    lb_msg_return := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                     , lv_out_msg
                     , 0
                     );
--
    -- ===============================
    -- エラー件数出力
    -- ===============================
    IF ( lv_retcode = cv_status_error ) THEN
      gn_error_cnt  := 1;
    END IF;
--
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_short_name_xxccp
                  , cv_err_count_msg
                  , cv_token_name1
                  , TO_CHAR( gn_error_cnt )
                  );
--
    lb_msg_return := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                     , lv_out_msg
                     , 0
                     );
--
    -- ===============================
    -- スキップ件数出力
    -- ===============================
    IF ( lv_retcode = cv_status_error ) THEN
      gn_skip_cnt := 0;
    END IF;
--
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_short_name_xxccp
                  , cv_skip_count_msg
                  , cv_token_name1
                  , TO_CHAR( gn_skip_cnt )
                  );
--
    lb_msg_return := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                     , lv_out_msg
                     , 1
                     );
--
    -- ===============================
    -- 終了メッセージ
    -- ===============================
    IF ( lv_retcode = cv_status_normal )   THEN
      lv_message_code := cv_normal_msg;
      retcode         := cv_status_normal;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_err_msg;
      retcode         := cv_status_error;
    ELSIF ( lv_retcode = cv_status_warn )  THEN
      lv_message_code := cv_warn_msg;
      retcode         := cv_status_warn;
    END IF;
--
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_short_name_xxccp
                  , lv_message_code
                  );
--
    lb_msg_return := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                     , lv_out_msg
                     , 0
                     );
--
    -- 終了ステータスがエラーの場合はROLLBACKする
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- 共通関数例外ハンドラ
    WHEN global_api_expt THEN
      ROLLBACK;
      errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      retcode := cv_status_error;
--
    -- 共通関数OTHERS例外ハンドラ
    WHEN global_api_others_expt THEN
      ROLLBACK;
      errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      retcode := cv_status_error;
--
    -- OTHERS例外ハンドラ
    WHEN OTHERS THEN
      ROLLBACK;
      errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      retcode := cv_status_error;
  END main;
END XXCOK008A06C;
/
