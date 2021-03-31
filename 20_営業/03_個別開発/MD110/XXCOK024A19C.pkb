CREATE OR REPLACE PACKAGE BODY XXCOK024A19C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A19C_pkg(body)
 * Description      : 営業システム構築プロジェクト
 * MD.050           : アドオン：控除データ差額金額調整 MD050_COK_024_A19
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  cre_num_recon_diff_ap  控除No別差額データ作成(A-2)
 *  cre_item_recon_diff_wp 商品別繰越データ作成(A-3)
 *  cre_num_recon_diff_wp  控除No別繰越データ作成(A-4)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2020/03/12    1.0   Y.Koh            新規作成
 *
 *****************************************************************************************/
--
  -- ==============================
  -- グローバル定数
  -- ==============================
  -- ステータス・コード
  cv_status_normal            CONSTANT VARCHAR2(1)          := xxccp_common_pkg.set_status_normal;  -- 正常:0
  cv_status_warn              CONSTANT VARCHAR2(1)          := xxccp_common_pkg.set_status_warn;    -- 警告:1
  cv_status_error             CONSTANT VARCHAR2(1)          := xxccp_common_pkg.set_status_error;   -- 異常:2
  -- WHOカラム
  cn_user_id                  CONSTANT NUMBER               := fnd_global.user_id;                  -- USER_ID
  cn_login_id                 CONSTANT NUMBER               := fnd_global.login_id;                 -- LOGIN_ID
  cn_conc_request_id          CONSTANT NUMBER               := fnd_global.conc_request_id;          -- CONC_REQUEST_ID
  cn_prog_appl_id             CONSTANT NUMBER               := fnd_global.prog_appl_id;             -- PROG_APPL_ID
  cn_conc_program_id          CONSTANT NUMBER               := fnd_global.conc_program_id;          -- CONC_PROGRAM_ID
  -- パッケージ名
  cv_pkg_name                 CONSTANT VARCHAR2(100)        := 'XXCOK024A19C';                      -- パッケージ名
  -- アプリケーション短縮名
  cv_appli_xxcok_name         CONSTANT VARCHAR2(15)         := 'XXCOK';                             -- アプリケーション短縮名
  -- メッセージ
  cv_msg_cok_00028            CONSTANT VARCHAR2(50)         := 'APP-XXCOK1-00028';                  -- 業務処理日付取得エラーメッセージ
  cv_msg_cok_00001            CONSTANT VARCHAR2(50)         := 'APP-XXCOK1-00001';                  -- 対象なしメッセージ
  cv_msg_cok_10632            CONSTANT VARCHAR2(50)         := 'APP-XXCOK1-10632';                  -- ロック取得エラーメッセージ
  cv_msg_cok_10744            CONSTANT VARCHAR2(50)         := 'APP-XXCOK1-10744';                  -- 残高繰越用データ種類取得エラー
  -- 参照タイプ
  cv_lookup_data_type         CONSTANT VARCHAR2(50)         := 'XXCOK1_DEDUCTION_DATA_TYPE';        -- 控除データ種類
  -- 区分 / フラグ
  cv_div_ap                   CONSTANT VARCHAR2(2)          := 'AP';                                -- 連携先(AP支払)
  cv_div_wp                   CONSTANT VARCHAR2(2)          := 'WP';                                -- 連携先(AP問屋支払)
  cv_flag_d                   CONSTANT VARCHAR2(1)          := 'D';                                 -- 作成元区分(差額調整)
  cv_flag_o                   CONSTANT VARCHAR2(1)          := 'O';                                 -- 作成元区分(繰越調整) / GL連携フラグ(対象外)
  cv_flag_y                   CONSTANT VARCHAR2(1)          := 'Y';                                 -- 対象フラグ(対象)
  cv_flag_n                   CONSTANT VARCHAR2(1)          := 'N';                                 -- ステータス(新規) / 取消フラグ(未取消)
  -- 記号
  cv_msg_cont                 CONSTANT VARCHAR2(1)          := '.';
  cv_msg_part                 CONSTANT VARCHAR2(3)          := ' : ';
  -- ==============================
  -- グローバル変数
  -- ==============================
  gd_process_month            xxcok_deduction_recon_head.gl_date%TYPE;          -- 業務処理月
  gv_recon_slip_num           xxcok_deduction_recon_head.recon_slip_num%TYPE;   -- 支払伝票番号
  gd_gl_date                  xxcok_deduction_recon_head.gl_date%TYPE;          -- GL記帳日
  gd_gl_month                 xxcok_deduction_recon_head.gl_date%TYPE;          -- GL記帳月
  gd_target_date_end          xxcok_deduction_recon_head.target_date_end%TYPE;  -- 対象期間(TO)
  gv_interface_div            xxcok_deduction_recon_head.interface_div%TYPE;    -- 連携先
  gv_data_type_030            xxcok_sales_deduction.data_type%TYPE;             -- 残高繰越用のデータ種類
  g_xxcok_sales_deduction_rec xxcok_sales_deduction%ROWTYPE;                    -- 販売控除情報
  -- ==============================
  -- グローバル例外
  -- ==============================
  -- *** 処理部共通例外 ***
  global_process_expt         EXCEPTION;
  -- *** 共通関数例外 ***
  global_api_expt             EXCEPTION;
  -- *** 共通関数OTHERS例外 ***
  global_api_others_expt      EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_api_others_expt , -20000 );
  -- *** ロック取得エラー例外 ***
  global_lock_failure_expt    EXCEPTION;
  PRAGMA EXCEPTION_INIT(global_lock_failure_expt, -54);
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf  OUT VARCHAR2                                 -- エラー・メッセージ
  , ov_retcode OUT VARCHAR2                                 -- リターン・コード
  , ov_errmsg  OUT VARCHAR2                                 -- ユーザー・エラー・メッセージ 
  )
  IS
--
    -- ==============================
    -- ローカル定数
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'init';                           -- プログラム名
    -- ==============================
    -- ローカル変数
    -- ==============================
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- リターン・コード
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ユーザー・エラー・メッセージ
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- ============================================================
    -- 業務処理月の取得
    -- ============================================================
    gd_process_month  :=  TRUNC(xxccp_common_pkg2.get_process_date, 'MM');

    IF  gd_process_month  IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_msg_cok_00028
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ============================================================
    -- 控除消込ヘッダー情報の連携先の取得
    -- ============================================================
    BEGIN
--
      SELECT  xdrh.gl_date                    gl_date         , -- GL記帳日
              TRUNC(xdrh.gl_date, 'MM')       gl_month        , -- GL記帳月
              LAST_DAY(xdrh.target_date_end)  target_date_end , -- 対象期間(TO)
              xdrh.interface_div              interface_div     -- 連携先
      INTO    gd_gl_date        ,
              gd_gl_month       ,
              gd_target_date_end,
              gv_interface_div
      FROM    xxcok_deduction_recon_head  xdrh
      WHERE   xdrh.recon_slip_num = gv_recon_slip_num;
--
    EXCEPTION
      WHEN  OTHERS THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        cv_appli_xxcok_name
                      , cv_msg_cok_00001
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ============================================================
    -- 残高繰越用のデータ種類の取得
    -- ============================================================
    IF  gv_interface_div  = cv_div_wp THEN
      BEGIN
--
        SELECT  dtyp.lookup_code        lookup_code         -- データ種類
        INTO    gv_data_type_030
        FROM    fnd_lookup_values       dtyp
        WHERE   dtyp.lookup_type            =   cv_lookup_data_type
        AND     dtyp.language               =   'JA'
        AND     dtyp.enabled_flag           =   cv_flag_y
        AND     dtyp.attribute9             =   cv_flag_y ;
--
      EXCEPTION
        WHEN  OTHERS THEN
          lv_errmsg :=  xxccp_common_pkg.get_msg(
                          cv_appli_xxcok_name
                        , cv_msg_cok_10744
                        );
          lv_errbuf :=  lv_errmsg;
          RAISE global_process_expt;
      END;
    END IF;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数例外ハンドラ ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END init;
--
  /**********************************************************************************
   * Procedure Name   : cre_num_recon_diff_ap
   * Description      : 控除No別差額データ作成(A-2)
   ***********************************************************************************/
  PROCEDURE cre_num_recon_diff_ap(
    ov_errbuf  OUT VARCHAR2                                 -- エラー・メッセージ
  , ov_retcode OUT VARCHAR2                                 -- リターン・コード
  , ov_errmsg  OUT VARCHAR2                                 -- ユーザー・エラー・メッセージ 
  )
  IS
--
    -- ==============================
    -- ローカル定数
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'cre_num_recon_diff_ap';          -- プログラム名
    -- ==============================
    -- ローカル変数
    -- ==============================
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- リターン・コード
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ユーザー・エラー・メッセージ
--
    ln_difference_amt_rest              xxcok_deduction_num_recon.difference_amt%TYPE;              -- 調整差額(税抜)_残額
    ln_difference_tax_rest              xxcok_deduction_num_recon.difference_tax%TYPE;              -- 調整差額(消費税)_残額
    --===============================
    -- ローカルカーソル
    --===============================
--
    CURSOR xxcok_sales_deduction_u_cur
    IS
      SELECT  xsd.sales_deduction_id    sales_deduction_id  , -- 販売控除ID
              xsd.base_code_to          base_code_to        , -- 振替先拠点
              xsd.source_category       source_category     , -- 作成元区分
              xca.sale_base_code        sale_base_code      , -- 売上拠点コード
              xca.past_sale_base_code   past_sale_base_code , -- 前月売上拠点コード
              xdnr.payment_tax_code     payment_tax_code      -- 消込時税コード
      FROM    xxcok_deduction_num_recon xdnr                , -- 控除No別消込情報
              xxcmm_cust_accounts       xca                 , -- 顧客追加情報
              xxcok_sales_deduction     xsd                   -- 販売控除情報
      WHERE   xsd.recon_slip_num          =   gv_recon_slip_num
      AND     xca.customer_code(+)        =   xsd.customer_code_to
      AND     xdnr.recon_slip_num         =   gv_recon_slip_num
      AND     xdnr.condition_no           =   xsd.condition_no
      AND     xdnr.tax_code               =   xsd.tax_code
      FOR UPDATE OF xsd.recon_tax_code  NOWAIT;
--
    CURSOR xxcok_deduction_num_recon_cur
    IS
      SELECT  xdnr.condition_no         condition_no        , -- 控除番号
              xdnr.tax_code             tax_code            , -- 消費税コード
              xdnr.payment_tax_code     payment_tax_code    , -- 支払時税コード
              xdnr.deduction_amt        denominator         , -- 按分_分母
              xdnr.difference_amt * -1  difference_amt      , -- 調整差額(税抜)
              xdnr.difference_tax * -1  difference_tax        -- 調整差額(消費税)
      FROM    xxcok_deduction_num_recon xdnr                  -- 控除No別消込情報
      WHERE   xdnr.recon_slip_num       =   gv_recon_slip_num
      AND     xdnr.target_flag          =   cv_flag_y
      AND   ( xdnr.difference_amt       !=  0 OR
              xdnr.difference_tax       !=  0 )
      ORDER BY  xdnr.deduction_line_num ;
--
    CURSOR xxcok_sales_deduction_s_cur(
      p_condition_no  VARCHAR2                                                  -- 控除番号
    , p_tax_code      VARCHAR2                                                  -- 消費税コード
    )
    IS
      SELECT  xsd.customer_code_to      customer_code_to      , -- 振替先顧客コード
              xsd.deduction_chain_code  deduction_chain_code  , -- 控除用チェーンコード
              xsd.corp_code             corp_code             , -- 企業コード
              xsd.condition_id          condition_id          , -- 控除条件ID
              xsd.data_type             data_type             , -- データ種類
              xsd.item_code             item_code             , -- 品目コード
              xsd.recon_base_code       recon_base_code       , -- 消込時計上拠点
              SUM(xsd.deduction_amount) numerator               -- 按分_分子
      FROM    xxcok_sales_deduction     xsd                     -- 販売控除情報
      WHERE   xsd.recon_slip_num  = gv_recon_slip_num
      AND     xsd.condition_no    = p_condition_no
      AND     xsd.tax_code        = p_tax_code
      GROUP BY  xsd.customer_code_to    ,
                xsd.deduction_chain_code,
                xsd.corp_code           ,
                xsd.condition_id        ,
                xsd.data_type           ,
                xsd.item_code           ,
                xsd.recon_base_code
      ORDER BY  xsd.customer_code_to,
                xsd.item_code       ;
--
    TYPE xxcok_sales_deduction_s_ttype  IS TABLE OF xxcok_sales_deduction_s_cur%ROWTYPE;
    xxcok_sales_deduction_s_tab         xxcok_sales_deduction_s_ttype;
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- ============================================================
    -- 消込時税コード、消込時計上拠点の更新
    -- ============================================================
    FOR xxcok_sales_deduction_u_rec IN  xxcok_sales_deduction_u_cur LOOP
      UPDATE  xxcok_sales_deduction
      SET     recon_tax_code          = xxcok_sales_deduction_u_rec.payment_tax_code,
              recon_base_code         = CASE  WHEN  xxcok_sales_deduction_u_rec.source_category IN  ('F', 'U') THEN
                                                xxcok_sales_deduction_u_rec.base_code_to
                                              WHEN  gd_gl_month < gd_process_month                            THEN
                                                xxcok_sales_deduction_u_rec.past_sale_base_code
                                              ELSE
                                                xxcok_sales_deduction_u_rec.sale_base_code
                                        END,
              last_updated_by         = cn_user_id            ,
              last_update_date        = SYSDATE               ,
              last_update_login       = cn_login_id           ,
              request_id              = cn_conc_request_id    ,
              program_application_id  = cn_prog_appl_id       ,
              program_id              = cn_conc_program_id    ,
              program_update_date     = SYSDATE
      WHERE   SALES_DEDUCTION_ID  = xxcok_sales_deduction_u_rec.SALES_DEDUCTION_ID;
    END LOOP;
--
    -- ============================================================
    -- 差額調整データ作成
    -- ============================================================
    FOR xxcok_deduction_num_recon_rec IN  xxcok_deduction_num_recon_cur LOOP
--
      ln_difference_amt_rest  :=  xxcok_deduction_num_recon_rec.difference_amt;
      ln_difference_tax_rest  :=  xxcok_deduction_num_recon_rec.difference_tax;
--
      OPEN  xxcok_sales_deduction_s_cur(xxcok_deduction_num_recon_rec.condition_no, xxcok_deduction_num_recon_rec.tax_code);
      FETCH xxcok_sales_deduction_s_cur BULK COLLECT INTO xxcok_sales_deduction_s_tab;
      CLOSE xxcok_sales_deduction_s_cur;
--
      FOR i IN 1..xxcok_sales_deduction_s_tab.COUNT LOOP
        IF i = xxcok_sales_deduction_s_tab.COUNT THEN
          g_xxcok_sales_deduction_rec.deduction_amount      :=  ln_difference_amt_rest;
          g_xxcok_sales_deduction_rec.deduction_tax_amount  :=  ln_difference_tax_rest;
        ELSIF xxcok_deduction_num_recon_rec.denominator = 0 THEN
          g_xxcok_sales_deduction_rec.deduction_amount      :=  0;
          g_xxcok_sales_deduction_rec.deduction_tax_amount  :=  0;
        ELSE
          g_xxcok_sales_deduction_rec.deduction_amount      :=  ROUND(  xxcok_deduction_num_recon_rec.difference_amt
                                                                      * xxcok_sales_deduction_s_tab(i).numerator
                                                                      / xxcok_deduction_num_recon_rec.denominator     );
          g_xxcok_sales_deduction_rec.deduction_tax_amount  :=  ROUND(  xxcok_deduction_num_recon_rec.difference_tax
                                                                      * xxcok_sales_deduction_s_tab(i).numerator
                                                                      / xxcok_deduction_num_recon_rec.denominator     );
        END IF;
--
        IF  g_xxcok_sales_deduction_rec.deduction_amount  !=  0 OR  g_xxcok_sales_deduction_rec.deduction_tax_amount  !=0 THEN
          g_xxcok_sales_deduction_rec.sales_deduction_id      :=  xxcok_sales_deduction_s01.NEXTVAL                   ;   -- 販売控除ID
          g_xxcok_sales_deduction_rec.base_code_from          :=  xxcok_sales_deduction_s_tab(i).recon_base_code      ;   -- 振替元拠点
          g_xxcok_sales_deduction_rec.base_code_to            :=  xxcok_sales_deduction_s_tab(i).recon_base_code      ;   -- 振替先拠点
          g_xxcok_sales_deduction_rec.customer_code_from      :=  xxcok_sales_deduction_s_tab(i).customer_code_to     ;   -- 振替元顧客コード
          g_xxcok_sales_deduction_rec.customer_code_to        :=  xxcok_sales_deduction_s_tab(i).customer_code_to     ;   -- 振替先顧客コード
          g_xxcok_sales_deduction_rec.deduction_chain_code    :=  xxcok_sales_deduction_s_tab(i).deduction_chain_code ;   -- 控除用チェーンコード
          g_xxcok_sales_deduction_rec.corp_code               :=  xxcok_sales_deduction_s_tab(i).corp_code            ;   -- 企業コード
          g_xxcok_sales_deduction_rec.record_date             :=  gd_target_date_end                                  ;   -- 計上日
          g_xxcok_sales_deduction_rec.source_category         :=  cv_flag_d                                           ;   -- 作成元区分
          g_xxcok_sales_deduction_rec.source_line_id          :=  NULL                                                ;   -- 作成元明細ID
          g_xxcok_sales_deduction_rec.condition_id            :=  xxcok_sales_deduction_s_tab(i).condition_id         ;   -- 控除条件ID
          g_xxcok_sales_deduction_rec.condition_no            :=  xxcok_deduction_num_recon_rec.condition_no          ;   -- 控除番号
          g_xxcok_sales_deduction_rec.condition_line_id       :=  NULL                                                ;   -- 控除詳細ID
          g_xxcok_sales_deduction_rec.data_type               :=  xxcok_sales_deduction_s_tab(i).data_type            ;   -- データ種類
          g_xxcok_sales_deduction_rec.status                  :=  cv_flag_n                                           ;   -- ステータス
          g_xxcok_sales_deduction_rec.item_code               :=  xxcok_sales_deduction_s_tab(i).item_code            ;   -- 品目コード
          g_xxcok_sales_deduction_rec.sales_uom_code          :=  NULL                                                ;   -- 販売単位
          g_xxcok_sales_deduction_rec.sales_unit_price        :=  NULL                                                ;   -- 販売単価
          g_xxcok_sales_deduction_rec.sales_quantity          :=  NULL                                                ;   -- 販売数量
          g_xxcok_sales_deduction_rec.sale_pure_amount        :=  NULL                                                ;   -- 売上本体金額
          g_xxcok_sales_deduction_rec.sale_tax_amount         :=  NULL                                                ;   -- 売上消費税額
          g_xxcok_sales_deduction_rec.deduction_uom_code      :=  NULL                                                ;   -- 控除単位
          g_xxcok_sales_deduction_rec.deduction_unit_price    :=  NULL                                                ;   -- 控除単価
          g_xxcok_sales_deduction_rec.deduction_quantity      :=  NULL                                                ;   -- 控除数量
--        g_xxcok_sales_deduction_rec.deduction_amount        :=  (上記で算出済)                                      ;   -- 控除額
          g_xxcok_sales_deduction_rec.tax_code                :=  xxcok_deduction_num_recon_rec.tax_code              ;   -- 税コード
          g_xxcok_sales_deduction_rec.tax_rate                :=  NULL                                                ;   -- 税率
          g_xxcok_sales_deduction_rec.recon_tax_code          :=  xxcok_deduction_num_recon_rec.payment_tax_code      ;   -- 消込時税コード
          g_xxcok_sales_deduction_rec.recon_tax_rate          :=  NULL                                                ;   -- 消込時税率
--        g_xxcok_sales_deduction_rec.deduction_tax_amount    :=  (上記で算出済)                                      ;   -- 控除税額
          g_xxcok_sales_deduction_rec.remarks                 :=  NULL                                                ;   -- 備考
          g_xxcok_sales_deduction_rec.application_no          :=  NULL                                                ;   -- 申請書No.
          g_xxcok_sales_deduction_rec.gl_if_flag              :=  cv_flag_o                                           ;   -- GL連携フラグ
          g_xxcok_sales_deduction_rec.gl_base_code            :=  NULL                                                ;   -- GL計上拠点
          g_xxcok_sales_deduction_rec.gl_date                 :=  NULL                                                ;   -- GL記帳日
          g_xxcok_sales_deduction_rec.recovery_date           :=  NULL                                                ;   -- リカバリー日付
          g_xxcok_sales_deduction_rec.cancel_flag             :=  cv_flag_n                                           ;   -- 取消フラグ
          g_xxcok_sales_deduction_rec.cancel_base_code        :=  NULL                                                ;   -- 取消時計上拠点
          g_xxcok_sales_deduction_rec.cancel_gl_date          :=  NULL                                                ;   -- 取消GL記帳日
          g_xxcok_sales_deduction_rec.cancel_user             :=  NULL                                                ;   -- 取消実施ユーザ
          g_xxcok_sales_deduction_rec.recon_base_code         :=  xxcok_sales_deduction_s_tab(i).recon_base_code      ;   -- 消込時計上拠点
          g_xxcok_sales_deduction_rec.recon_slip_num          :=  gv_recon_slip_num                                   ;   -- 支払伝票番号
          g_xxcok_sales_deduction_rec.carry_payment_slip_num  :=  gv_recon_slip_num                                   ;   -- 繰越時支払伝票番号
          g_xxcok_sales_deduction_rec.report_decision_flag    :=  NULL                                                ;   -- 速報確定フラグ
          g_xxcok_sales_deduction_rec.gl_interface_id         :=  NULL                                                ;   -- GL連携ID
          g_xxcok_sales_deduction_rec.cancel_gl_interface_id  :=  NULL                                                ;   -- 取消GL連携ID
          g_xxcok_sales_deduction_rec.created_by              :=  cn_user_id                                          ;   -- 作成者
          g_xxcok_sales_deduction_rec.creation_date           :=  SYSDATE                                             ;   -- 作成日
          g_xxcok_sales_deduction_rec.last_updated_by         :=  cn_user_id                                          ;   -- 最終更新者
          g_xxcok_sales_deduction_rec.last_update_date        :=  SYSDATE                                             ;   -- 最終更新日
          g_xxcok_sales_deduction_rec.last_update_login       :=  cn_login_id                                         ;   -- 最終更新ログイン
          g_xxcok_sales_deduction_rec.request_id              :=  cn_conc_request_id                                  ;   -- 要求ID
          g_xxcok_sales_deduction_rec.program_application_id  :=  cn_prog_appl_id                                     ;   -- コンカレント・プログラム・アプリケーションID
          g_xxcok_sales_deduction_rec.program_id              :=  cn_conc_program_id                                  ;   -- コンカレント・プログラムID
          g_xxcok_sales_deduction_rec.program_update_date     :=  SYSDATE                                             ;   -- プログラム更新日
--
          INSERT  INTO  xxcok_sales_deduction VALUES  g_xxcok_sales_deduction_rec;
--
          ln_difference_amt_rest  :=  ln_difference_amt_rest  - g_xxcok_sales_deduction_rec.DEDUCTION_AMOUNT    ;
          ln_difference_tax_rest  :=  ln_difference_tax_rest  - g_xxcok_sales_deduction_rec.DEDUCTION_TAX_AMOUNT;
        END IF;
--
      END LOOP;
--
    END LOOP;
--
  EXCEPTION
    -- *** ロック取得エラー例外 ***
    WHEN  global_lock_failure_expt THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_msg_cok_10632
                    );
      lv_errbuf :=  lv_errmsg;
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 処理部共通例外ハンドラ ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数例外ハンドラ ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END cre_num_recon_diff_ap;
--
  /**********************************************************************************
   * Procedure Name   : cre_item_recon_diff_wp
   * Description      : 商品別繰越データ作成(A-3)
   ***********************************************************************************/
  PROCEDURE cre_item_recon_diff_wp(
    ov_errbuf  OUT VARCHAR2                                 -- エラー・メッセージ
  , ov_retcode OUT VARCHAR2                                 -- リターン・コード
  , ov_errmsg  OUT VARCHAR2                                 -- ユーザー・エラー・メッセージ
  )
  IS
--
    -- ==============================
    -- ローカル定数
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'cre_item_recon_diff_wp';         -- プログラム名
    -- ==============================
    -- ローカル変数
    -- ==============================
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- リターン・コード
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ユーザー・エラー・メッセージ
    --===============================
    -- ローカルカーソル
    --===============================
--
    CURSOR xxcok_sales_deduction_u_cur
    IS
      SELECT  xsd.sales_deduction_id                                          , -- 販売控除ID
              xsd.base_code_to                                                , -- 振替先拠点
              xsd.source_category                                             , -- 作成元区分
              xca.sale_base_code                                              , -- 売上拠点コード
              xca.past_sale_base_code                                         , -- 前月売上拠点コード
              xdir.tax_code                                                     -- 消込時税コード
      FROM    xxcok_deduction_item_recon  xdir                                , -- 控除No別消込情報
              xxcmm_cust_accounts         xca                                 , -- 顧客追加情報
              fnd_lookup_values           dtyp                                , -- データ種類
              xxcok_sales_deduction       xsd                                   -- 販売控除情報
      WHERE   xsd.recon_slip_num          =   gv_recon_slip_num
      AND     dtyp.lookup_type            =   cv_lookup_data_type
      AND     dtyp.lookup_code            =   xsd.data_type
      AND     dtyp.language               =   'JA'
      AND     dtyp.enabled_flag           =   cv_flag_y
      AND     dtyp.attribute2             IN  ('030', '040')
      AND     xca.customer_code(+)        =   xsd.customer_code_to
      AND     xdir.recon_slip_num         =   gv_recon_slip_num
      AND     xdir.deduction_chain_code   IN  (xca.intro_chain_code2, xsd.deduction_chain_code)
      AND     xdir.item_code              =   xsd.item_code
      FOR UPDATE OF xsd.recon_tax_code  NOWAIT;
--
    CURSOR xxcok_deduction_item_recon_cur
    IS
      SELECT  xdir.deduction_chain_code   deduction_chain_code  , -- 控除用チェーンコード
              xdir.item_code              item_code             , -- 品目コード
              xdir.tax_code               tax_code              , -- 消費税コード
              xdir.deduction_030          deduction             , -- 控除額(通常)
              xdir.difference_amt * -1    difference_amt        , -- 調整差額(税抜)
              xdir.difference_tax * -1    difference_tax          -- 調整差額(消費税)
      FROM    xxcok_deduction_item_recon  xdir                    -- 控除No別消込情報
      WHERE   xdir.recon_slip_num       =   gv_recon_slip_num
      AND   ( xdir.difference_amt       !=  0 OR
              xdir.difference_tax       !=  0 )
      ORDER BY  xdir.deduction_chain_code ,
                xdir.item_code            ;
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- ============================================================
    -- 消込時税コード、消込時計上拠点の更新
    -- ============================================================
    FOR xxcok_sales_deduction_u_rec IN  xxcok_sales_deduction_u_cur LOOP
      UPDATE  xxcok_sales_deduction
      SET     recon_tax_code          = xxcok_sales_deduction_u_rec.tax_code,
              recon_base_code         = CASE  WHEN  xxcok_sales_deduction_u_rec.source_category IN  ('F', 'U') THEN
                                                xxcok_sales_deduction_u_rec.base_code_to
                                              WHEN  gd_gl_month < gd_process_month                            THEN
                                                xxcok_sales_deduction_u_rec.past_sale_base_code
                                              ELSE
                                                xxcok_sales_deduction_u_rec.sale_base_code
                                        END,
              last_updated_by         = cn_user_id            ,
              last_update_date        = SYSDATE               ,
              last_update_login       = cn_login_id           ,
              request_id              = cn_conc_request_id    ,
              program_application_id  = cn_prog_appl_id       ,
              program_id              = cn_conc_program_id    ,
              program_update_date     = SYSDATE
      WHERE   SALES_DEDUCTION_ID  = xxcok_sales_deduction_u_rec.SALES_DEDUCTION_ID;
    END LOOP;
--
    -- ============================================================
    -- 残高繰越データ作成
    -- ============================================================
    FOR xxcok_deduction_item_recon_rec IN  xxcok_deduction_item_recon_cur LOOP
--
      g_xxcok_sales_deduction_rec.sales_deduction_id      :=  xxcok_sales_deduction_s01.NEXTVAL                   ;   -- 販売控除ID
      g_xxcok_sales_deduction_rec.base_code_from          :=  '-'                                                 ;   -- 振替元拠点
      g_xxcok_sales_deduction_rec.base_code_to            :=  '-'                                                 ;   -- 振替先拠点
      g_xxcok_sales_deduction_rec.customer_code_from      :=  NULL                                                ;   -- 振替元顧客コード
      g_xxcok_sales_deduction_rec.customer_code_to        :=  NULL                                                ;   -- 振替先顧客コード
      g_xxcok_sales_deduction_rec.deduction_chain_code    :=  xxcok_deduction_item_recon_rec.deduction_chain_code ;   -- 控除用チェーンコード
      g_xxcok_sales_deduction_rec.corp_code               :=  NULL                                                ;   -- 企業コード
      g_xxcok_sales_deduction_rec.record_date             :=  gd_target_date_end                                  ;   -- 計上日
      g_xxcok_sales_deduction_rec.source_category         :=  cv_flag_o                                           ;   -- 作成元区分
      g_xxcok_sales_deduction_rec.source_line_id          :=  NULL                                                ;   -- 作成元明細ID
      g_xxcok_sales_deduction_rec.condition_id            :=  NULL                                                ;   -- 控除条件ID
      g_xxcok_sales_deduction_rec.condition_no            :=  NULL                                                ;   -- 控除番号
      g_xxcok_sales_deduction_rec.condition_line_id       :=  NULL                                                ;   -- 控除詳細ID
      g_xxcok_sales_deduction_rec.data_type               :=  gv_data_type_030                                    ;   -- データ種類
      g_xxcok_sales_deduction_rec.status                  :=  cv_flag_n                                           ;   -- ステータス
      g_xxcok_sales_deduction_rec.item_code               :=  xxcok_deduction_item_recon_rec.item_code            ;   -- 品目コード
      g_xxcok_sales_deduction_rec.sales_uom_code          :=  NULL                                                ;   -- 販売単位
      g_xxcok_sales_deduction_rec.sales_unit_price        :=  NULL                                                ;   -- 販売単価
      g_xxcok_sales_deduction_rec.sales_quantity          :=  NULL                                                ;   -- 販売数量
      g_xxcok_sales_deduction_rec.sale_pure_amount        :=  NULL                                                ;   -- 売上本体金額
      g_xxcok_sales_deduction_rec.sale_tax_amount         :=  NULL                                                ;   -- 売上消費税額
      g_xxcok_sales_deduction_rec.deduction_uom_code      :=  NULL                                                ;   -- 控除単位
      g_xxcok_sales_deduction_rec.deduction_unit_price    :=  NULL                                                ;   -- 控除単価
      g_xxcok_sales_deduction_rec.deduction_quantity      :=  NULL                                                ;   -- 控除数量
      g_xxcok_sales_deduction_rec.deduction_amount        :=  xxcok_deduction_item_recon_rec.difference_amt       ;   -- 控除額
      g_xxcok_sales_deduction_rec.tax_code                :=  xxcok_deduction_item_recon_rec.tax_code             ;   -- 税コード
      g_xxcok_sales_deduction_rec.tax_rate                :=  NULL                                                ;   -- 税率
      g_xxcok_sales_deduction_rec.recon_tax_code          :=  xxcok_deduction_item_recon_rec.tax_code             ;   -- 消込時税コード
      g_xxcok_sales_deduction_rec.recon_tax_rate          :=  NULL                                                ;   -- 消込時税率
      g_xxcok_sales_deduction_rec.deduction_tax_amount    :=  xxcok_deduction_item_recon_rec.difference_tax       ;   -- 控除税額
      g_xxcok_sales_deduction_rec.remarks                 :=  NULL                                                ;   -- 備考
      g_xxcok_sales_deduction_rec.application_no          :=  NULL                                                ;   -- 申請書No.
      g_xxcok_sales_deduction_rec.gl_if_flag              :=  cv_flag_o                                           ;   -- GL連携フラグ
      g_xxcok_sales_deduction_rec.gl_base_code            :=  NULL                                                ;   -- GL計上拠点
      g_xxcok_sales_deduction_rec.gl_date                 :=  NULL                                                ;   -- GL記帳日
      g_xxcok_sales_deduction_rec.recovery_date           :=  NULL                                                ;   -- リカバリー日付
      g_xxcok_sales_deduction_rec.cancel_flag             :=  cv_flag_n                                           ;   -- 取消フラグ
      g_xxcok_sales_deduction_rec.cancel_base_code        :=  NULL                                                ;   -- 取消時計上拠点
      g_xxcok_sales_deduction_rec.cancel_gl_date          :=  NULL                                                ;   -- 取消GL記帳日
      g_xxcok_sales_deduction_rec.cancel_user             :=  NULL                                                ;   -- 取消実施ユーザ
      g_xxcok_sales_deduction_rec.recon_base_code         :=  NULL                                                ;   -- 消込時計上拠点
      g_xxcok_sales_deduction_rec.recon_slip_num          :=  gv_recon_slip_num                                   ;   -- 支払伝票番号
      g_xxcok_sales_deduction_rec.carry_payment_slip_num  :=  gv_recon_slip_num                                   ;   -- 繰越時支払伝票番号
      g_xxcok_sales_deduction_rec.report_decision_flag    :=  NULL                                                ;   -- 速報確定フラグ
      g_xxcok_sales_deduction_rec.gl_interface_id         :=  NULL                                                ;   -- GL連携ID
      g_xxcok_sales_deduction_rec.cancel_gl_interface_id  :=  NULL                                                ;   -- 取消GL連携ID
      g_xxcok_sales_deduction_rec.created_by              :=  cn_user_id                                          ;   -- 作成者
      g_xxcok_sales_deduction_rec.creation_date           :=  SYSDATE                                             ;   -- 作成日
      g_xxcok_sales_deduction_rec.last_updated_by         :=  cn_user_id                                          ;   -- 最終更新者
      g_xxcok_sales_deduction_rec.last_update_date        :=  SYSDATE                                             ;   -- 最終更新日
      g_xxcok_sales_deduction_rec.last_update_login       :=  cn_login_id                                         ;   -- 最終更新ログイン
      g_xxcok_sales_deduction_rec.request_id              :=  cn_conc_request_id                                  ;   -- 要求ID
      g_xxcok_sales_deduction_rec.program_application_id  :=  cn_prog_appl_id                                     ;   -- コンカレント・プログラム・アプリケーションID
      g_xxcok_sales_deduction_rec.program_id              :=  cn_conc_program_id                                  ;   -- コンカレント・プログラムID
      g_xxcok_sales_deduction_rec.program_update_date     :=  SYSDATE                                             ;   -- プログラム更新日
--
      INSERT  INTO  xxcok_sales_deduction VALUES  g_xxcok_sales_deduction_rec;
--
    END LOOP;
--
  EXCEPTION
    -- *** ロック取得エラー例外 ***
    WHEN  global_lock_failure_expt THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_msg_cok_10632
                    );
      lv_errbuf :=  lv_errmsg;
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 処理部共通例外ハンドラ ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数例外ハンドラ ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END cre_item_recon_diff_wp;
--
  /**********************************************************************************
   * Procedure Name   : cre_num_recon_diff_wp
   * Description      : 控除No別繰越データ作成(A-4)
   ***********************************************************************************/
  PROCEDURE cre_num_recon_diff_wp(
    ov_errbuf  OUT VARCHAR2                                 -- エラー・メッセージ
  , ov_retcode OUT VARCHAR2                                 -- リターン・コード
  , ov_errmsg  OUT VARCHAR2                                 -- ユーザー・エラー・メッセージ
  )
  IS
--
    -- ==============================
    -- ローカル定数
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'cre_num_recon_diff_wp';          -- プログラム名
    -- ==============================
    -- ローカル変数
    -- ==============================
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- リターン・コード
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ユーザー・エラー・メッセージ
--
    ln_difference_amt_rest              xxcok_deduction_num_recon.difference_amt%TYPE;              -- 調整差額(税抜)_残額
    ln_difference_tax_rest              xxcok_deduction_num_recon.difference_tax%TYPE;              -- 調整差額(消費税)_残額
    --===============================
    -- ローカルカーソル
    --===============================
--
    CURSOR xxcok_sales_deduction_u_cur
    IS
      SELECT  xsd.sales_deduction_id    sales_deduction_id  , -- 販売控除ID
              xsd.base_code_to          base_code_to        , -- 振替先拠点
              xsd.source_category       source_category     , -- 作成元区分
              xca.sale_base_code        sale_base_code      , -- 売上拠点コード
              xca.past_sale_base_code   past_sale_base_code , -- 前月売上拠点コード
              xdnr.payment_tax_code     payment_tax_code      -- 消込時税コード
      FROM    xxcok_deduction_num_recon xdnr                , -- 控除No別消込情報
              xxcmm_cust_accounts       xca                 , -- 顧客追加情報
              xxcok_sales_deduction     xsd                   -- 販売控除情報
      WHERE   xsd.recon_slip_num          =   gv_recon_slip_num
      AND     xca.customer_code(+)        =   xsd.customer_code_to
      AND     xdnr.recon_slip_num         =   gv_recon_slip_num
      AND     xdnr.deduction_chain_code   IN  (xca.intro_chain_code2, xsd.deduction_chain_code)
      AND     xdnr.condition_no           =   xsd.condition_no
      AND     xdnr.tax_code               =   xsd.tax_code
      FOR UPDATE OF xsd.recon_tax_code  NOWAIT;
--
    CURSOR xxcok_deduction_num_recon_cur(
      p_carryover_pay_off_flg VARCHAR2                            -- 繰越額全額精算フラグ
    )
    IS
      SELECT  xdnr.deduction_chain_code   deduction_chain_code  , -- 控除用チェーンコード
              xdnr.data_type              data_type             , -- データ種類
              xdnr.condition_no           condition_no          , -- 控除番号
              xdnr.tax_code               tax_code              , -- 消費税コード
              xdnr.payment_tax_code       payment_tax_code      , -- 支払時税コード
              xdnr.deduction_amt          denominator           , -- 按分_分母
              xdnr.difference_amt * -1    difference_amt        , -- 調整差額(税抜)
              xdnr.difference_tax * -1    difference_tax          -- 調整差額(消費税)
      FROM    xxcok_deduction_num_recon   xdnr                    -- 控除No別消込情報
      WHERE   xdnr.recon_slip_num         =   gv_recon_slip_num
      AND     xdnr.target_flag            =   cv_flag_y
      AND     xdnr.carryover_pay_off_flg  =   p_carryover_pay_off_flg
      AND   ( xdnr.difference_amt         !=  0 OR
              xdnr.difference_tax         !=  0 )
      ORDER BY  xdnr.recon_line_num     ,
                xdnr.deduction_line_num ;
--
    CURSOR xxcok_sales_deduction_s_cur(
      p_chain_code    VARCHAR2                                  -- 控除用チェーンコード
    , p_condition_no  VARCHAR2                                  -- 控除番号
    , p_tax_code      VARCHAR2                                  -- 消費税コード
    )
    IS
      SELECT  xsd.customer_code_to      customer_code_to      , -- 振替先顧客コード
              xsd.deduction_chain_code  deduction_chain_code  , -- 控除用チェーンコード
              xsd.corp_code             corp_code             , -- 企業コード
              xsd.condition_id          condition_id          , -- 控除条件ID
              xsd.data_type             data_type             , -- データ種類
              xsd.item_code             item_code             , -- 品目コード
              xsd.recon_base_code       recon_base_code       , -- 消込時計上拠点
              SUM(xsd.deduction_amount) numerator               -- 按分_分子
      FROM    xxcmm_cust_accounts       xca                   , -- 顧客追加情報
              xxcok_sales_deduction     xsd                     -- 販売控除情報
      WHERE   xsd.recon_slip_num          = gv_recon_slip_num
      AND     xsd.condition_no            = p_condition_no
      AND     xsd.tax_code                = p_tax_code
      AND     xca.customer_code(+)        =   xsd.customer_code_to
      AND     p_chain_code                IN  (xca.intro_chain_code2, xsd.deduction_chain_code)
      GROUP BY  xsd.customer_code_to    ,
                xsd.deduction_chain_code,
                xsd.corp_code           ,
                xsd.condition_id        ,
                xsd.data_type           ,
                xsd.item_code           ,
                xsd.recon_base_code     
      ORDER BY  xsd.customer_code_to,
                xsd.item_code       ;
--
    TYPE xxcok_sales_deduction_s_ttype  IS TABLE OF xxcok_sales_deduction_s_cur%ROWTYPE;
    xxcok_sales_deduction_s_tab         xxcok_sales_deduction_s_ttype;
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- ============================================================
    -- 消込時税コード、消込時計上拠点の更新
    -- ============================================================
    FOR xxcok_sales_deduction_u_rec IN  xxcok_sales_deduction_u_cur LOOP
      UPDATE  xxcok_sales_deduction
      SET     recon_tax_code          = xxcok_sales_deduction_u_rec.payment_tax_code,
              recon_base_code         = CASE  WHEN  xxcok_sales_deduction_u_rec.source_category IN  ('F', 'U') THEN
                                                xxcok_sales_deduction_u_rec.base_code_to
                                              WHEN  gd_gl_month < gd_process_month                            THEN
                                                xxcok_sales_deduction_u_rec.past_sale_base_code
                                              ELSE
                                                xxcok_sales_deduction_u_rec.sale_base_code
                                        END,
              last_updated_by         = cn_user_id            ,
              last_update_date        = SYSDATE               ,
              last_update_login       = cn_login_id           ,
              request_id              = cn_conc_request_id    ,
              program_application_id  = cn_prog_appl_id       ,
              program_id              = cn_conc_program_id    ,
              program_update_date     = SYSDATE
      WHERE   SALES_DEDUCTION_ID  = xxcok_sales_deduction_u_rec.SALES_DEDUCTION_ID;
    END LOOP;
--
    -- ============================================================
    -- 残高繰越データ作成
    -- ============================================================
    FOR xxcok_deduction_num_recon_rec IN  xxcok_deduction_num_recon_cur(cv_flag_n) LOOP
--
      g_xxcok_sales_deduction_rec.sales_deduction_id      :=  xxcok_sales_deduction_s01.NEXTVAL                   ;   -- 販売控除ID
      g_xxcok_sales_deduction_rec.base_code_from          :=  '-'                                                 ;   -- 振替元拠点
      g_xxcok_sales_deduction_rec.base_code_to            :=  '-'                                                 ;   -- 振替先拠点
      g_xxcok_sales_deduction_rec.customer_code_from      :=  NULL                                                ;   -- 振替元顧客コード
      g_xxcok_sales_deduction_rec.customer_code_to        :=  NULL                                                ;   -- 振替先顧客コード
      g_xxcok_sales_deduction_rec.deduction_chain_code    :=  xxcok_deduction_num_recon_rec.deduction_chain_code  ;   -- 控除用チェーンコード
      g_xxcok_sales_deduction_rec.corp_code               :=  NULL                                                ;   -- 企業コード
      g_xxcok_sales_deduction_rec.record_date             :=  gd_target_date_end                                  ;   -- 計上日
      g_xxcok_sales_deduction_rec.source_category         :=  cv_flag_o                                           ;   -- 作成元区分
      g_xxcok_sales_deduction_rec.source_line_id          :=  NULL                                                ;   -- 作成元明細ID
      g_xxcok_sales_deduction_rec.condition_id            :=  NULL                                                ;   -- 控除条件ID
      g_xxcok_sales_deduction_rec.condition_no            :=  xxcok_deduction_num_recon_rec.condition_no          ;   -- 控除番号
      g_xxcok_sales_deduction_rec.condition_line_id       :=  NULL                                                ;   -- 控除詳細ID
      g_xxcok_sales_deduction_rec.data_type               :=  xxcok_deduction_num_recon_rec.data_type             ;   -- データ種類
      g_xxcok_sales_deduction_rec.status                  :=  cv_flag_n                                           ;   -- ステータス
      g_xxcok_sales_deduction_rec.item_code               :=  NULL                                                ;   -- 品目コード
      g_xxcok_sales_deduction_rec.sales_uom_code          :=  NULL                                                ;   -- 販売単位
      g_xxcok_sales_deduction_rec.sales_unit_price        :=  NULL                                                ;   -- 販売単価
      g_xxcok_sales_deduction_rec.sales_quantity          :=  NULL                                                ;   -- 販売数量
      g_xxcok_sales_deduction_rec.sale_pure_amount        :=  NULL                                                ;   -- 売上本体金額
      g_xxcok_sales_deduction_rec.sale_tax_amount         :=  NULL                                                ;   -- 売上消費税額
      g_xxcok_sales_deduction_rec.deduction_uom_code      :=  NULL                                                ;   -- 控除単位
      g_xxcok_sales_deduction_rec.deduction_unit_price    :=  NULL                                                ;   -- 控除単価
      g_xxcok_sales_deduction_rec.deduction_quantity      :=  NULL                                                ;   -- 控除数量
      g_xxcok_sales_deduction_rec.deduction_amount        :=  xxcok_deduction_num_recon_rec.difference_amt        ;   -- 控除額
      g_xxcok_sales_deduction_rec.tax_code                :=  xxcok_deduction_num_recon_rec.tax_code              ;   -- 税コード
      g_xxcok_sales_deduction_rec.tax_rate                :=  NULL                                                ;   -- 税率
      g_xxcok_sales_deduction_rec.recon_tax_code          :=  xxcok_deduction_num_recon_rec.payment_tax_code      ;   -- 消込時税コード
      g_xxcok_sales_deduction_rec.recon_tax_rate          :=  NULL                                                ;   -- 消込時税率
      g_xxcok_sales_deduction_rec.deduction_tax_amount    :=  xxcok_deduction_num_recon_rec.difference_tax        ;   -- 控除税額
      g_xxcok_sales_deduction_rec.remarks                 :=  NULL                                                ;   -- 備考
      g_xxcok_sales_deduction_rec.application_no          :=  NULL                                                ;   -- 申請書No.
      g_xxcok_sales_deduction_rec.gl_if_flag              :=  cv_flag_o                                           ;   -- GL連携フラグ
      g_xxcok_sales_deduction_rec.gl_base_code            :=  NULL                                                ;   -- GL計上拠点
      g_xxcok_sales_deduction_rec.gl_date                 :=  NULL                                                ;   -- GL記帳日
      g_xxcok_sales_deduction_rec.recovery_date           :=  NULL                                                ;   -- リカバリー日付
      g_xxcok_sales_deduction_rec.cancel_flag             :=  cv_flag_n                                           ;   -- 取消フラグ
      g_xxcok_sales_deduction_rec.cancel_base_code        :=  NULL                                                ;   -- 取消時計上拠点
      g_xxcok_sales_deduction_rec.cancel_gl_date          :=  NULL                                                ;   -- 取消GL記帳日
      g_xxcok_sales_deduction_rec.cancel_user             :=  NULL                                                ;   -- 取消実施ユーザ
      g_xxcok_sales_deduction_rec.recon_base_code         :=  NULL                                                ;   -- 消込時計上拠点
      g_xxcok_sales_deduction_rec.recon_slip_num          :=  gv_recon_slip_num                                   ;   -- 支払伝票番号
      g_xxcok_sales_deduction_rec.carry_payment_slip_num  :=  gv_recon_slip_num                                   ;   -- 繰越時支払伝票番号
      g_xxcok_sales_deduction_rec.report_decision_flag    :=  NULL                                                ;   -- 速報確定フラグ
      g_xxcok_sales_deduction_rec.gl_interface_id         :=  NULL                                                ;   -- GL連携ID
      g_xxcok_sales_deduction_rec.cancel_gl_interface_id  :=  NULL                                                ;   -- 取消GL連携ID
      g_xxcok_sales_deduction_rec.created_by              :=  cn_user_id                                          ;   -- 作成者
      g_xxcok_sales_deduction_rec.creation_date           :=  SYSDATE                                             ;   -- 作成日
      g_xxcok_sales_deduction_rec.last_updated_by         :=  cn_user_id                                          ;   -- 最終更新者
      g_xxcok_sales_deduction_rec.last_update_date        :=  SYSDATE                                             ;   -- 最終更新日
      g_xxcok_sales_deduction_rec.last_update_login       :=  cn_login_id                                         ;   -- 最終更新ログイン
      g_xxcok_sales_deduction_rec.request_id              :=  cn_conc_request_id                                  ;   -- 要求ID
      g_xxcok_sales_deduction_rec.program_application_id  :=  cn_prog_appl_id                                     ;   -- コンカレント・プログラム・アプリケーションID
      g_xxcok_sales_deduction_rec.program_id              :=  cn_conc_program_id                                  ;   -- コンカレント・プログラムID
      g_xxcok_sales_deduction_rec.program_update_date     :=  SYSDATE                                             ;   -- プログラム更新日
--
      INSERT  INTO  xxcok_sales_deduction VALUES  g_xxcok_sales_deduction_rec;
--
    END LOOP;
--
    -- ============================================================
    -- 差額調整データ作成
    -- ============================================================
    FOR xxcok_deduction_num_recon_rec IN  xxcok_deduction_num_recon_cur(cv_flag_y) LOOP
--
      ln_difference_amt_rest  :=  xxcok_deduction_num_recon_rec.difference_amt;
      ln_difference_tax_rest  :=  xxcok_deduction_num_recon_rec.difference_tax;
--
      OPEN  xxcok_sales_deduction_s_cur(xxcok_deduction_num_recon_rec.deduction_chain_code, xxcok_deduction_num_recon_rec.condition_no, xxcok_deduction_num_recon_rec.tax_code);
      FETCH xxcok_sales_deduction_s_cur BULK COLLECT INTO xxcok_sales_deduction_s_tab;
      CLOSE xxcok_sales_deduction_s_cur;
--
      FOR i IN 1..xxcok_sales_deduction_s_tab.COUNT LOOP
        IF i = xxcok_sales_deduction_s_tab.COUNT THEN
          g_xxcok_sales_deduction_rec.deduction_amount      :=  ln_difference_amt_rest;
          g_xxcok_sales_deduction_rec.deduction_tax_amount  :=  ln_difference_tax_rest;
        ELSIF xxcok_deduction_num_recon_rec.denominator = 0 THEN
          g_xxcok_sales_deduction_rec.deduction_amount      :=  0;
          g_xxcok_sales_deduction_rec.deduction_tax_amount  :=  0;
        ELSE
          g_xxcok_sales_deduction_rec.deduction_amount      :=  ROUND(  xxcok_deduction_num_recon_rec.difference_amt
                                                                      * xxcok_sales_deduction_s_tab(i).numerator
                                                                      / xxcok_deduction_num_recon_rec.denominator     );
          g_xxcok_sales_deduction_rec.deduction_tax_amount  :=  ROUND(  xxcok_deduction_num_recon_rec.difference_tax
                                                                      * xxcok_sales_deduction_s_tab(i).numerator
                                                                      / xxcok_deduction_num_recon_rec.denominator     );
        END IF;
--
        IF  g_xxcok_sales_deduction_rec.deduction_amount  !=  0 OR  g_xxcok_sales_deduction_rec.deduction_tax_amount  !=0 THEN
          g_xxcok_sales_deduction_rec.sales_deduction_id      :=  xxcok_sales_deduction_s01.NEXTVAL                   ;   -- 販売控除ID
          g_xxcok_sales_deduction_rec.base_code_from          :=  xxcok_sales_deduction_s_tab(i).recon_base_code      ;   -- 振替元拠点
          g_xxcok_sales_deduction_rec.base_code_to            :=  xxcok_sales_deduction_s_tab(i).recon_base_code      ;   -- 振替先拠点
          g_xxcok_sales_deduction_rec.customer_code_from      :=  xxcok_sales_deduction_s_tab(i).customer_code_to     ;   -- 振替元顧客コード
          g_xxcok_sales_deduction_rec.customer_code_to        :=  xxcok_sales_deduction_s_tab(i).customer_code_to     ;   -- 振替先顧客コード
          g_xxcok_sales_deduction_rec.deduction_chain_code    :=  xxcok_sales_deduction_s_tab(i).deduction_chain_code ;   -- 控除用チェーンコード
          g_xxcok_sales_deduction_rec.corp_code               :=  xxcok_sales_deduction_s_tab(i).corp_code            ;   -- 企業コード
          g_xxcok_sales_deduction_rec.record_date             :=  gd_target_date_end                                  ;   -- 計上日
          g_xxcok_sales_deduction_rec.source_category         :=  cv_flag_d                                           ;   -- 作成元区分
          g_xxcok_sales_deduction_rec.source_line_id          :=  NULL                                                ;   -- 作成元明細ID
          g_xxcok_sales_deduction_rec.condition_id            :=  xxcok_sales_deduction_s_tab(i).condition_id         ;   -- 控除条件ID
          g_xxcok_sales_deduction_rec.condition_no            :=  xxcok_deduction_num_recon_rec.condition_no          ;   -- 控除番号
          g_xxcok_sales_deduction_rec.condition_line_id       :=  NULL                                                ;   -- 控除詳細ID
          g_xxcok_sales_deduction_rec.data_type               :=  xxcok_sales_deduction_s_tab(i).data_type            ;   -- データ種類
          g_xxcok_sales_deduction_rec.status                  :=  cv_flag_n                                           ;   -- ステータス
          g_xxcok_sales_deduction_rec.item_code               :=  xxcok_sales_deduction_s_tab(i).item_code            ;   -- 品目コード
          g_xxcok_sales_deduction_rec.sales_uom_code          :=  NULL                                                ;   -- 販売単位
          g_xxcok_sales_deduction_rec.sales_unit_price        :=  NULL                                                ;   -- 販売単価
          g_xxcok_sales_deduction_rec.sales_quantity          :=  NULL                                                ;   -- 販売数量
          g_xxcok_sales_deduction_rec.sale_pure_amount        :=  NULL                                                ;   -- 売上本体金額
          g_xxcok_sales_deduction_rec.sale_tax_amount         :=  NULL                                                ;   -- 売上消費税額
          g_xxcok_sales_deduction_rec.deduction_uom_code      :=  NULL                                                ;   -- 控除単位
          g_xxcok_sales_deduction_rec.deduction_unit_price    :=  NULL                                                ;   -- 控除単価
          g_xxcok_sales_deduction_rec.deduction_quantity      :=  NULL                                                ;   -- 控除数量
--        g_xxcok_sales_deduction_rec.deduction_amount        :=  (上記で算出済)                                      ;   -- 控除額
          g_xxcok_sales_deduction_rec.tax_code                :=  xxcok_deduction_num_recon_rec.tax_code              ;   -- 税コード
          g_xxcok_sales_deduction_rec.tax_rate                :=  NULL                                                ;   -- 税率
          g_xxcok_sales_deduction_rec.recon_tax_code          :=  xxcok_deduction_num_recon_rec.payment_tax_code      ;   -- 消込時税コード
          g_xxcok_sales_deduction_rec.recon_tax_rate          :=  NULL                                                ;   -- 消込時税率
--        g_xxcok_sales_deduction_rec.deduction_tax_amount    :=  (上記で算出済)                                      ;   -- 控除税額
          g_xxcok_sales_deduction_rec.remarks                 :=  NULL                                                ;   -- 備考
          g_xxcok_sales_deduction_rec.application_no          :=  NULL                                                ;   -- 申請書No.
          g_xxcok_sales_deduction_rec.gl_if_flag              :=  cv_flag_o                                           ;   -- GL連携フラグ
          g_xxcok_sales_deduction_rec.gl_base_code            :=  NULL                                                ;   -- GL計上拠点
          g_xxcok_sales_deduction_rec.gl_date                 :=  NULL                                                ;   -- GL記帳日
          g_xxcok_sales_deduction_rec.recovery_date           :=  NULL                                                ;   -- リカバリー日付
          g_xxcok_sales_deduction_rec.cancel_flag             :=  cv_flag_n                                           ;   -- 取消フラグ
          g_xxcok_sales_deduction_rec.cancel_base_code        :=  NULL                                                ;   -- 取消時計上拠点
          g_xxcok_sales_deduction_rec.cancel_gl_date          :=  NULL                                                ;   -- 取消GL記帳日
          g_xxcok_sales_deduction_rec.cancel_user             :=  NULL                                                ;   -- 取消実施ユーザ
          g_xxcok_sales_deduction_rec.recon_base_code         :=  xxcok_sales_deduction_s_tab(i).recon_base_code      ;   -- 消込時計上拠点
          g_xxcok_sales_deduction_rec.recon_slip_num          :=  gv_recon_slip_num                                   ;   -- 支払伝票番号
          g_xxcok_sales_deduction_rec.carry_payment_slip_num  :=  gv_recon_slip_num                                   ;   -- 繰越時支払伝票番号
          g_xxcok_sales_deduction_rec.report_decision_flag    :=  NULL                                                ;   -- 速報確定フラグ
          g_xxcok_sales_deduction_rec.gl_interface_id         :=  NULL                                                ;   -- GL連携ID
          g_xxcok_sales_deduction_rec.cancel_gl_interface_id  :=  NULL                                                ;   -- 取消GL連携ID
          g_xxcok_sales_deduction_rec.created_by              :=  cn_user_id                                          ;   -- 作成者
          g_xxcok_sales_deduction_rec.creation_date           :=  SYSDATE                                             ;   -- 作成日
          g_xxcok_sales_deduction_rec.last_updated_by         :=  cn_user_id                                          ;   -- 最終更新者
          g_xxcok_sales_deduction_rec.last_update_date        :=  SYSDATE                                             ;   -- 最終更新日
          g_xxcok_sales_deduction_rec.last_update_login       :=  cn_login_id                                         ;   -- 最終更新ログイン
          g_xxcok_sales_deduction_rec.request_id              :=  cn_conc_request_id                                  ;   -- 要求ID
          g_xxcok_sales_deduction_rec.program_application_id  :=  cn_prog_appl_id                                     ;   -- コンカレント・プログラム・アプリケーションID
          g_xxcok_sales_deduction_rec.program_id              :=  cn_conc_program_id                                  ;   -- コンカレント・プログラムID
          g_xxcok_sales_deduction_rec.program_update_date     :=  SYSDATE                                             ;   -- プログラム更新日
--
          INSERT  INTO  xxcok_sales_deduction VALUES  g_xxcok_sales_deduction_rec;
--
          ln_difference_amt_rest  :=  ln_difference_amt_rest  - g_xxcok_sales_deduction_rec.DEDUCTION_AMOUNT    ;
          ln_difference_tax_rest  :=  ln_difference_tax_rest  - g_xxcok_sales_deduction_rec.DEDUCTION_TAX_AMOUNT;
        END IF;
--
      END LOOP;
--
    END LOOP;
--
  EXCEPTION
    -- *** ロック取得エラー例外 ***
    WHEN  global_lock_failure_expt THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_msg_cok_10632
                    );
      lv_errbuf :=  lv_errmsg;
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 処理部共通例外ハンドラ ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数例外ハンドラ ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END cre_num_recon_diff_wp;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf  OUT VARCHAR2                                 -- エラー・メッセージ
  , ov_retcode OUT VARCHAR2                                 -- リターン・コード
  , ov_errmsg  OUT VARCHAR2                                 -- ユーザー・エラー・メッセージ
  )
  IS
--
    -- ==============================
    -- ローカル定数
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'submain';    -- プログラム名
    -- ==============================
    -- ローカル変数
    -- ==============================
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- リターン・コード
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ユーザー・エラー・メッセージ
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- =============================================================
    -- 初期処理(A-1)の呼び出し
    -- =============================================================
    init(
      ov_errbuf   =>  lv_errbuf                             -- エラー・メッセージ
    , ov_retcode  =>  lv_retcode                            -- リターン・コード
    , ov_errmsg   =>  lv_errmsg                             -- ユーザー・エラー・メッセージ
    );
    IF  lv_retcode  = cv_status_error THEN
      RAISE global_process_expt;
    END IF;
--
    IF  gv_interface_div  = cv_div_ap THEN
      -- ============================================================
      -- 控除No別差額データ作成(A-2)の呼び出し
      -- ============================================================
      cre_num_recon_diff_ap(
        ov_errbuf   =>  lv_errbuf                             -- エラー・メッセージ
      , ov_retcode  =>  lv_retcode                            -- リターン・コード
      , ov_errmsg   =>  lv_errmsg                             -- ユーザー・エラー・メッセージ
      );
      IF  lv_retcode  = cv_status_warn  THEN
        ov_retcode  :=  cv_status_warn;
      ELSIF lv_retcode  = cv_status_error THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    IF  gv_interface_div  = cv_div_wp THEN
      -- ============================================================
      -- 商品別繰越データ作成(A-3)の呼び出し
      -- ============================================================
      cre_item_recon_diff_wp(
        ov_errbuf   =>  lv_errbuf                             -- エラー・メッセージ
      , ov_retcode  =>  lv_retcode                            -- リターン・コード
      , ov_errmsg   =>  lv_errmsg                             -- ユーザー・エラー・メッセージ
      );
      IF  lv_retcode  = cv_status_warn  THEN
        ov_retcode  :=  cv_status_warn;
      ELSIF lv_retcode  = cv_status_error THEN
        RAISE global_process_expt;
      END IF;
--
      -- ============================================================
      -- 控除No別繰越データ作成(A-4)の呼び出し
      -- ============================================================
      cre_num_recon_diff_wp(
        ov_errbuf   =>  lv_errbuf                             -- エラー・メッセージ
      , ov_retcode  =>  lv_retcode                            -- リターン・コード
      , ov_errmsg   =>  lv_errmsg                             -- ユーザー・エラー・メッセージ
      );
      IF  lv_retcode  = cv_status_error THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
--    COMMIT;                           -- コミットは呼び元で行なう。
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数例外ハンドラ ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
  PROCEDURE main(
    ov_errbuf                           OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                          OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                           OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  , iv_recon_slip_num                   IN  VARCHAR2        -- 支払伝票番号
  )
  IS
--
    -- ==============================
    -- ローカル定数
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'main';       -- プログラム名
    -- ==============================
    -- ローカル変数
    -- ==============================
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- リターン・コード
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ユーザー・エラー・メッセージ
--
  BEGIN
--
    gv_recon_slip_num :=  iv_recon_slip_num;                -- 支払伝票番号
    ov_retcode        :=  cv_status_normal;
--
    -- ============================================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ============================================================
    submain(
      ov_errbuf         =>  lv_errbuf                       -- エラー・メッセージ
    , ov_retcode        =>  lv_retcode                      -- リターン・コード
    , ov_errmsg         =>  lv_errmsg                       -- ユーザー・エラー・メッセージ
    );
--
    ov_errbuf   :=  lv_errbuf;
    ov_retcode  :=  lv_retcode;
    ov_errmsg   :=  lv_errmsg;
--
    -- 終了ステータスがエラーの場合はROLLBACKする
    IF  ov_retcode  = cv_status_error THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN  global_api_expt THEN
      ROLLBACK;
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN  global_api_others_expt THEN
      ROLLBACK;
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** OTHERS例外ハンドラ ***
    WHEN  OTHERS THEN
      ROLLBACK;
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
  END main;
END XXCOK024A19C;
/
