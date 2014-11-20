create or replace PACKAGE BODY XXCFR003A06C AS
/*************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 * 
 * Package Name    : XXCFR003A06C
 * Description     : 汎用店別請求データ作成
 * MD.050          : MD050_CFR_003_A06_汎用店別請求データ作成
 * MD.070          : MD050_CFR_003_A06_汎用店別請求データ作成
 * Version         : 1.1
 * 
 * Program List
 * --------------- ---- ----- --------------------------------------------
 *  Name           Type  Ret   Description
 * --------------- ---- ----- --------------------------------------------
 *  init            P         初期処理
 *  get_invoice     P         請求情報取得処理
 *  chk_bm          P         販手条件の取得
 *  get_bm          P         販売手数料・電気代の取得
 *  ins             P         ファイル出力処理
 *  put             P         ファイル出力処理
 *  end_proc        P         終了処理
 *  submain         P         汎用店別請求データ作成処理実行部
 *  main            P         コンカレント実行ファイル登録プロシージャ
 * 
 * Change Record
 * ------------- ----- ------------- -------------------------------------
 *  Date          Ver.  Editor        Description
 * ------------- ----- ------------- -------------------------------------
 *  2008-11-19    1.0  SCS 吉村 憲司  初回作成
 *  2009-02-20    1.1  SCS 大川 恵    [障害CFR_009] VD請求額更新不具合対応
 *  2009-04-13    1.2  SCS 萱原 伸哉  T1_0129 BM金額取得不可対応
 ************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  cv_status_normal   CONSTANT VARCHAR2(1) := '0';  -- 正常終了
  cv_status_warn     CONSTANT VARCHAR2(1) := '1';   --警告
  cv_status_error    CONSTANT VARCHAR2(1) := '2';   --エラー
  cv_msg_part        CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont        CONSTANT VARCHAR2(3) := '.';
  --
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFR003A06C';  -- パッケージ名
--
--##############################  固定部 END   ####################################
--
  --===============================================================
  -- グローバル定数
  --===============================================================
  cv_xxcfr_app_name  CONSTANT VARCHAR2(10) := 'XXCFR';  -- アドオン会計 AR のアプリケーション短縮名
  cv_xxccp_app_name  CONSTANT VARCHAR2(10) := 'XXCCP';  -- アドオン：共通・IF領域のアプリケーション短縮名
  --
  -- メッセージ番号
  ct_msg_cfr_00004  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00004';
  ct_msg_cfr_00010  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00010';
  ct_msg_cfr_00015  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00015';
  ct_msg_cfr_00016  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00016';
  ct_msg_cfr_00024  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00024';
  ct_msg_cfr_00037  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00037';
  ct_msg_cfr_00056  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00056';
  --
  ct_msg_ccp_90000  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCCP1-90000';
  ct_msg_ccp_90001  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCCP1-90001';
  ct_msg_ccp_90002  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCCP1-90002';
  ct_msg_ccp_90004  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCCP1-90004';
  ct_msg_ccp_90005  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCCP1-90005';
  ct_msg_ccp_90006  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCCP1-90006';
  --
  -- メッセージトークン
  cv_tkn_prof       CONSTANT VARCHAR2(30) := 'PROF_NAME';            -- プロファイル
  cv_tkn_get_data   CONSTANT VARCHAR2(30) := 'DATA';                 -- 取得対象データ
  cv_tkn_count      CONSTANT VARCHAR2(30) := 'COUNT';                -- 処理件数
  cv_tkn_tab_name   CONSTANT VARCHAR2(30) := 'TABLE';                -- テーブル名
  cv_func_name      CONSTANT VARCHAR2(30) := 'FUNC_NAME';            -- 共通関数名
  --
  -- プロファイルオプション
  ct_prof_name_set_of_bks_id  CONSTANT fnd_profile_options_tl.profile_option_name%TYPE := 'GL_SET_OF_BKS_ID';
  ct_prof_name_org_id         CONSTANT fnd_profile_options_tl.profile_option_name%TYPE := 'ORG_ID';
  --
  -- 参照タイプ
  ct_lookup_type_out          CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCFR1_003A06_BILL_DATA_SET';  -- 汎用請求出力用参照タイプ名
  ct_lookup_type_func_name    CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCFR1_ERR_MSG_TOKEN';         -- エラーメッセージ出力用参照タイプ名
  --
  -- 参照コード
  ct_lookup_code_func_name    CONSTANT fnd_lookup_values.lookup_code%TYPE := 'CFR000A00006';                 -- エラーメッセージ出力用参照タイプコード
  --
  -- 請求書全社出力権限判定関数INパラーメータ値
  cv_invoice_type             CONSTANT VARCHAR2(1) := 'G';  -- 請求書タイプ(G:汎用請求書)
  --
  -- 請求書全社出力権限判定関数戻り値
  cv_yes  CONSTANT VARCHAR2(1) := 'Y';  -- 全社出力権限あり
  cv_no   CONSTANT VARCHAR2(1) := 'N';  -- 全社出力権限なし
  --
  -- 請求書全社出力権限設定値
  cv_enable_all   CONSTANT VARCHAR2(1) := '1';  -- 全社出力権限あり
  cv_disable_all  CONSTANT VARCHAR2(1) := '0';  -- 全社出力権限なし
  --
  -- VD顧客区分
  cv_vd_cust_type CONSTANT VARCHAR2(1) := '1'; -- VD
  --
  -- 仕入先コード・ダミー値
  ct_sc_bm1       CONSTANT xxcok_cond_bm_support.supplier_code%TYPE := 'FLVDDMY1' ; -- BM1用
  ct_sc_bm2       CONSTANT xxcok_cond_bm_support.supplier_code%TYPE := 'FLVDDMY2' ; -- BM2用
  ct_sc_bm3       CONSTANT xxcok_cond_bm_support.supplier_code%TYPE := 'FLVDDMY3' ; -- BM3用
  --
  -- 計算条件
  ct_calc_type_10 CONSTANT xxcok_cond_bm_support.calc_type%TYPE := '10' ; -- 10.売価別条件
  ct_calc_type_20 CONSTANT xxcok_cond_bm_support.calc_type%TYPE := '20' ; -- 20.容器区分別条件
  ct_calc_type_30 CONSTANT xxcok_cond_bm_support.calc_type%TYPE := '30' ; -- 30.定率条件
  ct_calc_type_40 CONSTANT xxcok_cond_bm_support.calc_type%TYPE := '40' ; -- 40.定額条件
  ct_calc_type_50 CONSTANT xxcok_cond_bm_support.calc_type%TYPE := '50' ; -- 50.電気料
  --
  -- VD顧客区分値
  cv_is_vd        CONSTANT VARCHAR2(1) := '1';  -- VD顧客
  cv_is_not_vd    CONSTANT VARCHAR2(1) := '0';  -- VD顧客以外
  --
  -- 請求書出力形式
  cv_inv_prt_type CONSTANT VARCHAR2(1) := '2';  -- 汎用請求書
  --
  -- 一括請求書発行フラグ
  cv_cons_inv_flag CONSTANT VARCHAR2(1) := 'Y';  -- 有効
  --
  -- ソートキー項目NULL時の値
  cv_sort_null_value CONSTANT VARCHAR2(1) := '0';
  --===============================================================
  -- グローバル変数
  --===============================================================
  gt_gl_set_of_bks_id       gl_sets_of_books.set_of_books_id%TYPE;     -- プロファイル会計帳簿ID
  gt_org_id                 xxcfr_bill_customers_v.org_id%TYPE;        -- プロファイル組織ID
  gn_conc_request_id        NUMBER 
                              := FND_GLOBAL.CONC_REQUEST_ID;           -- 要求ID
  gt_user_dept_code         per_all_people_f.attribute28%TYPE;         -- ログインユーザ所属部門コード
  gv_enable_all             VARCHAR2(1) := '0';                        -- 全社参照権限
  gn_rec_count              PLS_INTEGER := 0;                          -- 請求書情報取得件数
  --
  gn_vd_billed              NUMBER;                                    -- VD請求額
  gn_bm1_rate               NUMBER;                                    -- BM1率
  gn_bm1_amt                NUMBER;                                    -- BM1額
  gn_bm1_all                NUMBER;                                    -- BM1手数料額
  gn_bm2_rate               NUMBER;                                    -- BM2率
  gn_bm2_amt                NUMBER;                                    -- BM2額
  gn_bm2_all                NUMBER;                                    -- BM2手数料額
  gn_bm3_rate               NUMBER;                                    -- BM3率
  gn_bm3_amt                NUMBER;                                    -- BM3額
  gn_bm3_all                NUMBER;                                    -- BM3手数料額
  gn_electric_amt           NUMBER;                                    -- 電気代
  --
  --===============================================================
  -- グローバルカーソル
  --===============================================================
  -- 請求書情報取得カーソル
  CURSOR get_invoice_cur(id_target_date DATE,
                         iv_ar_code1    VARCHAR2)
  IS
    SELECT ''                                               conc_request_id,          -- 要求ID
           ''                                               sort_num,                 -- 出力順
           xih.invoice_id                                   invoice_id,               -- 一括請求書ID
           xih.itoen_name                                   itoen_name,               -- 取引先名
           TO_CHAR(xih.inv_creation_date,'YYYY/MM/DD')      inv_creation_date,        -- 作成日
           xih.object_month                                 object_month,             -- 対象年月
           TO_CHAR(xih.object_date_from,'YYYY/MM/DD')       object_date_from,         -- 対象期間(自)
           TO_CHAR(xih.object_date_to,'YYYY/MM/DD')         object_date_to,           -- 対象期間(至)
           xih.vender_code                                  vender_code,              -- 取引先コード
           xih.bill_location_code                           bill_location_code,       -- 請求担当拠点コード
           xih.bill_location_name                           bill_location_name,       -- 請求担当拠点名
           xih.agent_tel_num                                agent_tel_num,            -- 請求担当拠点電話番号
           xih.credit_cust_code                             credit_cust_code,         -- 与信先顧客コード
           xih.credit_cust_name                             credit_cust_name,         -- 与信先顧客名
           xih.receipt_cust_code                            receipt_cust_code,        -- 入金先顧客コード
           xih.receipt_cust_name                            receipt_cust_name,        -- 入金先顧客名
           xih.payment_cust_code                            payment_cust_code,        -- 売掛コード１（請求書）
           xih.payment_cust_name                            payment_cust_name,        -- 売掛コード１（請求書）名称
           xih.bill_cust_code                               bill_cust_code,           -- 請求先顧客コード
           xih.bill_cust_name                               bill_cust_name,           -- 請求先顧客名
           xih.credit_receiv_code2                          credit_receiv_code2,      -- 売掛コード２（事業所）
           xih.credit_receiv_name2                          credit_receiv_name2,      -- 売掛コード２（事業所）名称
           xih.credit_receiv_code3                          credit_receiv_code3,      -- 売掛コード３（その他）
           xih.credit_receiv_name3                          credit_receiv_name3,      -- 売掛コード３（その他）名称
           NULL                                             sold_location_code,       -- 拠点コード
           NULL                                             sold_location_name,       -- 拠点名
           NULL                                             ship_cust_code,           -- 顧客コード
           NULL                                             ship_cust_name,           -- 顧客名
           xih.bill_shop_code                               bill_shop_code,           -- 請求先顧客店NO
           xih.bill_shop_name                               bill_shop_name,           -- 請求先顧客店名
           NULL                                             ship_shop_code,           -- 納品先顧客店NO
           NULL                                             ship_shop_name,           -- 納品先顧客店名
           NULL                                             vd_num,                   -- 自動販売機番号
           NULL                                             delivery_date,            -- 納品日
           NULL                                             slip_num,                 -- 伝票NO
           NULL                                             order_num,                -- オーダーNO
           NULL                                             column_num,               -- コラム
           NULL                                             item_code,                -- 商品コード
           NULL                                             jan_code,                 -- JANコード
           NULL                                             item_name,                -- 商品名
           NULL                                             vessel,                   -- 容器
           NULL                                             quantity,                 -- 数量
           NULL                                             unit_price,               -- 卸単価
           NULL                                             ship_amount,              -- 売価
           SUM(xil.sold_amount)                             sold_amount,              -- 金額
           SUM(CASE WHEN xil.sold_amount >= 0 THEN
                 xil.sold_amount
               ELSE
                 0
               END)                                         sold_amount_plus,         -- 金額（黒）
           SUM(CASE WHEN xil.sold_amount < 0 THEN
                 xil.sold_amount
               ELSE
                 0
               END)                                         sold_amount_minus,        -- 金額（赤）
           SUM((CASE WHEN xil.sold_amount >= 0 THEN
                  xil.sold_amount
                ELSE
                  0
                END)
               +
               (CASE WHEN xil.sold_amount < 0 THEN
                  xil.sold_amount
                ELSE
                  0
                END)
              )                                             sold_amount_total,        -- 金額（計）
           AVG(xih.inv_amount_includ_tax)                   inv_amount_includ_tax,    -- 税込請求金額
           AVG(xih.tax_amount_sum)                          tax_amount_sum,           -- うち消費税金額
           NULL                                             bm_unit_price1,           -- BM1単価
           NULL                                             bm_rate1,                 -- BM1率
           NULL                                             bm_price1,                -- BM1金額
           NULL                                             bm_unit_price2,           -- BM2単価
           NULL                                             bm_rate2,                 -- BM2率
           NULL                                             bm_price2,                -- BM2金額
           NULL                                             bm_unit_price3,           -- BM3単価
           NULL                                             bm_rate3,                 -- BM3率
           NULL                                             bm_price3,                -- BM3金額
           NULL                                             vd_amount_claimed,        -- VD請求額
           NULL                                             electric_charges,         -- 電気代
           NULL                                             slip_type,                -- 伝票区分
           NULL                                             classify_type             -- 分類区分
    FROM xxcfr_invoice_headers xih,
         xxcfr_invoice_lines   xil
    WHERE xih.invoice_id = xil.invoice_id
      AND EXISTS (SELECT 'X'
                  FROM xxcfr_bill_customers_v xbcv
                  WHERE xih.bill_cust_code = xbcv.bill_customer_code
                    AND ((cv_enable_all = gv_enable_all AND
                          xbcv.bill_base_code = xbcv.bill_base_code)
                         OR
                         (cv_disable_all = gv_enable_all AND
                          xbcv.bill_base_code = gt_user_dept_code))
                    AND xbcv.receiv_code1  = iv_ar_code1
                    AND xbcv.inv_prt_type  = cv_inv_prt_type
                    AND xbcv.cons_inv_flag = cv_cons_inv_flag
                    AND xbcv.org_id = gt_org_id
                 )
      AND xih.cutoff_date = id_target_date
      AND xih.set_of_books_id = gt_gl_set_of_bks_id
      AND xih.org_id = gt_org_id
      GROUP BY xih.invoice_id,
               xih.itoen_name,
               TO_CHAR(xih.inv_creation_date,'YYYY/MM/DD'),
               xih.object_month,
               TO_CHAR(xih.object_date_from,'YYYY/MM/DD'),
               TO_CHAR(xih.object_date_to,'YYYY/MM/DD'),
               xih.vender_code,
               xih.bill_location_code,
               xih.bill_location_name,
               xih.agent_tel_num,
               xih.credit_cust_code,
               xih.credit_cust_name,
               xih.receipt_cust_code,
               xih.receipt_cust_name,
               xih.payment_cust_code,
               xih.payment_cust_name,
               xih.bill_cust_code,
               xih.bill_cust_name,
               xih.credit_receiv_code2,
               xih.credit_receiv_name2,
               xih.credit_receiv_code3,
               xih.credit_receiv_name3,
               xih.bill_shop_code,
               xih.bill_shop_name
      ORDER BY NVL(xih.bill_shop_code,cv_sort_null_value),  -- 請求先顧客店NO
               xih.bill_cust_code;                          -- 請求先顧客コード
    --
  --===============================================================
  -- グローバルタイプ
  --===============================================================
  TYPE inv_tab_ttype      IS TABLE OF get_invoice_cur%ROWTYPE INDEX BY PLS_INTEGER;       -- 請求情報取得
  TYPE csv_outs_tab_ttype IS TABLE OF xxcfr_csv_outs_temp%ROWTYPE INDEX BY PLS_INTEGER;   -- ワークテーブル情報格納
  --
  g_inv_tab                inv_tab_ttype;                              -- 店別請求情報
  g_csv_outs_tab           csv_outs_tab_ttype;                         -- ワークテーブル書込情報
  --
  --===============================================================
  -- グローバル例外
  --===============================================================
  global_process_expt       EXCEPTION; -- 関数例外
  global_api_expt           EXCEPTION; -- 共通関数例外
  global_api_others_expt    EXCEPTION; -- 共通関数OTHERS例外
  PRAGMA EXCEPTION_INIT(global_api_others_expt, -20000);  -- 共通関数例外(ORA-20000)とglobal_api_others_exptをマッピング
  
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理
   ***********************************************************************************/
  PROCEDURE init(
    iv_target_date   IN  VARCHAR2,    -- 締日
    iv_ar_code1      IN  VARCHAR2,    -- 売掛コード１(請求書)
    ov_errbuf        OUT VARCHAR2,
    ov_retcode       OUT VARCHAR2,
    ov_errmsg        OUT VARCHAR2
  )
  IS
--
--#######################  固定ローカル定数宣言部 START   #######################
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init';  -- プログラム名
--
--##############################  固定部 END   ##################################
--
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_log             CONSTANT VARCHAR2(10)  := 'LOG';          -- パラメータ出力関数 ログ出力時のiv_which値
    cv_output          CONSTANT VARCHAR2(10)  := 'OUTPUT';       -- パラメータ出力関数 レポート出力時のiv_which値
    cv_person_dff_name CONSTANT VARCHAR2(10)  := 'PER_PEOPLE';   -- 従業員マスタDFF名
    cv_peson_dff_att28 CONSTANT VARCHAR2(11)  := 'ATTRIBUTE28';  -- 従業員マスタDFF28(所属部署)カラム名
    
--
--#######################  固定ローカル変数宣言部 START   #######################
--
    lv_retcode VARCHAR2(1);    -- 共通関数リターンコード
    lv_errbuf  VARCHAR2(5000); -- 共通関数エラーバッファ
    lv_errmsg  VARCHAR2(5000); -- 共通関数エラーメッセージ
    --
    lv_enabled_flag VARCHAR2(1); 
--
--##############################  固定部 END   ##################################
--
    -- ===============================
    -- ローカル定数
    -- ===============================
    lv_token_value fnd_descr_flex_col_usage_vl.end_user_column_name%TYPE; --所属部門取得エラー時のメッセージトークン値
    
    -- ===============================
    -- ローカル例外
    -- ===============================
    get_user_dept_expt EXCEPTION;  -- ユーザ所属部門取得例外
    
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --
    -- コンカレントパラメータログ出力
    xxcfr_common_pkg.put_log_param(iv_which => cv_log,
                                   iv_conc_param1 => iv_target_date,
                                   iv_conc_param2 => iv_ar_code1,
                                   ov_errbuf => lv_errbuf,
                                   ov_retcode => lv_retcode,
                                   ov_errmsg => lv_errmsg
                                  );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
    --
    -- プロファイル会計帳簿取得
    gt_gl_set_of_bks_id := TO_NUMBER(FND_PROFILE.VALUE(ct_prof_name_set_of_bks_id));
    --
    -- 取得できない場合はエラー
    IF (gt_gl_set_of_bks_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_xxcfr_app_name -- 'XXCFR'
                                                    ,ct_msg_cfr_00004  -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(ct_prof_name_set_of_bks_id))
                                                       -- 会計帳簿ID
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
    --
    -- プロファイル営業単位取得
    gt_org_id := TO_NUMBER(FND_PROFILE.VALUE(ct_prof_name_org_id));
    --
    -- 取得できない場合はエラー
    IF (gt_org_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_xxcfr_app_name -- 'XXCFR'
                                                    ,ct_msg_cfr_00004  -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(ct_prof_name_org_id))
                                                       -- 組織ID
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
    --
    -- 所属部門コード取得
    gt_user_dept_code := xxcfr_common_pkg.get_user_dept(in_user_id  => FND_GLOBAL.USER_ID,
                                                        id_get_date => SYSDATE
                                                       );
    IF (gt_user_dept_code IS NULL) THEN
      RAISE get_user_dept_expt;
    END IF;
    --
  EXCEPTION
    -- *** 共通関数エラー発生時 ***
    WHEN global_api_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      ov_errmsg := lv_errmsg;
    -- *** 所属部門が取得できない場合 ***
    WHEN get_user_dept_expt THEN
      BEGIN
        SELECT ffcu.end_user_column_name
        INTO lv_token_value
        FROM fnd_descr_flex_col_usage_vl ffcu
        WHERE ffcu.descriptive_flexfield_name = cv_person_dff_name
          AND ffcu.application_column_name = cv_peson_dff_att28;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application => cv_xxcfr_app_name,
                                            iv_name => ct_msg_cfr_00015,
                                            iv_token_name1 => cv_tkn_get_data,
                                            iv_token_value1 => lv_token_value);
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
      ov_errmsg := lv_errmsg;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
    WHEN OTHERS THEN
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
  END init;
  --
  /**********************************************************************************
   * Procedure Name   : chk_bm
   * Description      : 販手条件の取得(A-4)
   ***********************************************************************************/
  PROCEDURE chk_bm(
    id_target_date    IN  DATE,        -- 締日
    in_invoice_id     IN  NUMBER,
    iv_account_number IN VARCHAR2,
    iv_account_name   IN VARCHAR2,
    ov_get_bm_flag    OUT VARCHAR2,    -- BM金額取得フラグ
    ov_get_bm_price   OUT VARCHAR2,    -- 率額取得フラグ
    ov_errbuf         OUT VARCHAR2,
    ov_retcode        OUT VARCHAR2,
    ov_errmsg         OUT VARCHAR2
  )
  IS
--
--#######################  固定ローカル定数宣言部 START   #######################
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_bm';  -- プログラム名
--
--##############################  固定部 END   ##################################
--
    -- ===============================
    -- ローカル定数
    -- ===============================
    --
    --===============================================================
    -- ローカルカーソル
    --===============================================================
    -- 販手条件取得カーソル
    CURSOR chk_bm_cur
    IS
      SELECT DISTINCT
             xmbc.calc_type             calc_type,                -- 計算条件
             xmbc.bm1_pct               bm1_pct,                  -- BM1率
             xmbc.bm1_amt               bm1_amt                   -- BM1単価
      FROM   xxcok_mst_bm_contract xmbc
      WHERE  EXISTS(SELECT  'X'
                    FROM    xxcfr_invoice_lines xil
                    WHERE   xil.invoice_id     = in_invoice_id
                    AND     xil.vd_cust_type   = cv_vd_cust_type
                    AND     xil.ship_cust_code = xmbc.cust_code)
      AND    NVL(xmbc.start_date_active,TO_DATE('19000101','YYYYMMDD')) <= id_target_date
      AND    NVL(xmbc.end_date_active,TO_DATE('22001231','YYYYMMDD'))   >= id_target_date
      AND    calc_type  NOT IN (ct_calc_type_20,ct_calc_type_50) ;
    --
    chk_bm_rec   chk_bm_cur%ROWTYPE;
--
--#######################  固定ローカル変数宣言部 START   #######################
--
    lv_retcode VARCHAR2(1);    -- 共通関数リターンコード
    lv_errbuf  VARCHAR2(5000); -- 共通関数エラーバッファ
    lv_errmsg  VARCHAR2(5000); -- 共通関数エラーメッセージ
--
--##############################  固定部 END   ##################################
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_cnt      NUMBER := 0 ;        -- レコード件数カウント
    lv_msg_out  VARCHAR2(1) := 'N';  -- 複数単価取得メッセージ出力判定
    --
    -- ===============================
    -- ローカル例外
    -- ===============================
    get_user_dept_expt EXCEPTION;  -- ユーザ所属部門取得例外
    --
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode      := cv_status_normal;
    ov_get_bm_flag  := 'N';
    ov_get_bm_price := 'Y';
--
--###########################  固定部 END   ############################
--
    --
    <<chk_bm_loop>>
    FOR chk_bm_rec IN chk_bm_cur
      LOOP
        ov_get_bm_price := 'Y';   -- 率額取得フラグを'Y'
        ln_cnt := ln_cnt + 1;     -- カウントをインクリメント
        --
        -- 1件でもデータが取得できた場合はBM金額取得フラグを'Y'にする
        IF (ov_get_bm_flag = 'N') THEN
          ov_get_bm_flag := 'Y';
        END IF ;
        --
        -- 2件目以降で率額取得フラグが'Y'の場合、率額取得フラグを'N'に設定
        IF ((ln_cnt > 1) AND (ov_get_bm_price = 'Y')) THEN
          ov_get_bm_price := 'N';
          --
          -- 複数単価取得メッセージが未出力の場合は、出力
          IF ( lv_msg_out = 'N') THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,
                              xxccp_common_pkg.get_msg(iv_application  => cv_xxcfr_app_name,
                                                       iv_name         => ct_msg_cfr_00037,
                                                       iv_token_name1  => 'ACCOUNT_NUMBER',
                                                       iv_token_value1 => iv_account_number,
                                                       iv_token_name2  => 'ACCOUNT_NAME',
                                                       iv_token_value2 => iv_account_name
                                                      ));
            lv_msg_out := 'Y';      -- メッセージを出力済みに変更
          END IF;
        END IF;
        --
      --
      END LOOP chk_bm_loop;
    --
  EXCEPTION
    WHEN OTHERS THEN
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
  END chk_bm;
  --
  /**********************************************************************************
   * Procedure Name   : get_bm
   * Description      : 販売手数料・電気代の取得(A-5)
   ***********************************************************************************/
  PROCEDURE get_bm(
    id_target_date   IN  DATE,        -- 締日
    in_num           IN  NUMBER,      -- レコード特定
    in_invoice_id    IN  NUMBER,      -- 一括請求書ID
    iv_get_bm_price  IN  VARCHAR2,    -- 率額取得判定
    ov_errbuf        OUT VARCHAR2,
    ov_retcode       OUT VARCHAR2,
    ov_errmsg        OUT VARCHAR2
  )
  IS
--
--#######################  固定ローカル定数宣言部 START   #######################
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_bm';  -- プログラム名
--
--##############################  固定部 END   ##################################
--
    -- ===============================
    -- ローカル定数
    -- ===============================
    --
    --===============================================================
    -- ローカルカーソル
    --===============================================================
--
--#######################  固定ローカル変数宣言部 START   #######################
--
    lv_retcode VARCHAR2(1);    -- 共通関数リターンコード
    lv_errbuf  VARCHAR2(5000); -- 共通関数エラーバッファ
    lv_errmsg  VARCHAR2(5000); -- 共通関数エラーメッセージ
--
--##############################  固定部 END   ##################################
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_cnt   NUMBER := 0 ; -- レコード件数カウント
    --
    -- ===============================
    -- ローカル例外
    -- ===============================
    get_user_dept_expt EXCEPTION;  -- ユーザ所属部門取得例外
    --
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode      := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- BM率・額・金額・電気代の取得
    --
    SELECT   AVG(
               DECODE(xcbs.supplier_code,ct_sc_bm1,xcbs.rebate_rate
                      ,NULL)
             ) bm1_rate,
             AVG(
               DECODE(xcbs.supplier_code,ct_sc_bm1,xcbs.rebate_amt
                      ,NULL)
             ) bm1_amt,
             SUM(
-- Modify 2009.04.12 Ver1.2 Start
--               DECODE(xcbs.supplier_code,ct_sc_bm1,xcbs.cond_bm_amt_tax
               DECODE(xcbs.supplier_code,ct_sc_bm1,xcbs.csh_rcpt_discount_amt
-- Modify 2009.04.12 Ver1.2 End               
                      ,NULL)
             ) bm1_all,
             AVG(
               DECODE(xcbs.supplier_code,ct_sc_bm2,xcbs.rebate_rate
                      ,NULL)
             ) bm2_rate,
             AVG(
               DECODE(xcbs.supplier_code,ct_sc_bm2,xcbs.rebate_amt
                      ,NULL)
             ) bm2_amt,
             SUM(
-- Modify 2009.04.12 Ver1.2 Start
--               DECODE(xcbs.supplier_code,ct_sc_bm2,xcbs.cond_bm_amt_tax
               DECODE(xcbs.supplier_code,ct_sc_bm2,xcbs.csh_rcpt_discount_amt
-- Modify 2009.04.12 Ver1.2 End
                      ,NULL)
             ) bm2_all,
             AVG(
               DECODE(xcbs.supplier_code,ct_sc_bm3,xcbs.rebate_rate
                      ,NULL)
             ) bm3_rate,
             AVG(
               DECODE(xcbs.supplier_code,ct_sc_bm3,xcbs.rebate_amt
                      ,NULL)
             ) bm3_amt,
             SUM(
-- Modify 2009.04.12 Ver1.2 Start
--               DECODE(xcbs.supplier_code,ct_sc_bm3,xcbs.cond_bm_amt_tax
               DECODE(xcbs.supplier_code,ct_sc_bm3,xcbs.csh_rcpt_discount_amt
-- Modify 2009.04.12 Ver1.2 End
                      ,NULL)
             ) bm3_all,
             SUM(electric_amt_tax)        electric_amt
    INTO     g_inv_tab(in_num).bm_rate1,
             g_inv_tab(in_num).bm_unit_price1,
             g_inv_tab(in_num).bm_price1,
             g_inv_tab(in_num).bm_rate2,
             g_inv_tab(in_num).bm_unit_price2,
             g_inv_tab(in_num).bm_price2,
             g_inv_tab(in_num).bm_rate3,
             g_inv_tab(in_num).bm_unit_price3,
             g_inv_tab(in_num).bm_price3,
             g_inv_tab(in_num).electric_charges
    FROM     xxcok_cond_bm_support xcbs
    WHERE EXISTS(SELECT  'X'
                 FROM    xxcfr_invoice_lines xil
                 WHERE   xil.invoice_id     = in_invoice_id
                 AND     xil.vd_cust_type   = cv_vd_cust_type
                 AND     xil.ship_cust_code = xcbs.delivery_cust_code
                 )
    AND   closing_date = id_target_date
    AND   calc_type    IN (ct_calc_type_10,
                           ct_calc_type_30,
                           ct_calc_type_40,
                           ct_calc_type_50);
    --
    IF (iv_get_bm_price = 'N') THEN
      g_inv_tab(in_num).bm_rate1       := NULL;
      g_inv_tab(in_num).bm_unit_price1 := NULL;
      g_inv_tab(in_num).bm_rate2       := NULL;
      g_inv_tab(in_num).bm_unit_price2 := NULL;
      g_inv_tab(in_num).bm_rate3       := NULL;
      g_inv_tab(in_num).bm_unit_price3 := NULL;
    END IF;
    --
  EXCEPTION
    WHEN OTHERS THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_xxcfr_app_name,
                                            iv_name         => ct_msg_cfr_00016,
                                            iv_token_name1  => cv_tkn_tab_name,
                                            iv_token_value1 => xxcfr_common_pkg.get_table_comment('XXCFR_CSV_OUTS_TEMP')
                                           );
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
  END get_bm;
  --
  /**********************************************************************************
   * Procedure Name   : get_invoice
   * Description      : 請求情報取得処理(A-3)
   ***********************************************************************************/
  PROCEDURE get_invoice(
    id_target_date   IN  DATE,        -- 締日
    iv_ar_code1      IN  VARCHAR2,    -- 売掛コード１(請求書)
    ov_errbuf        OUT VARCHAR2,
    ov_retcode       OUT VARCHAR2,
    ov_errmsg        OUT VARCHAR2
  )
  IS
--
--#######################  固定ローカル定数宣言部 START   #######################
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_invoice';  -- プログラム名
--
--##############################  固定部 END   ##################################
--
    --===============================================================
    -- ローカル定数
    --===============================================================
--
--#######################  固定ローカル変数宣言部 START   #######################
--
    lv_retcode VARCHAR2(1);    -- 共通関数リターンコード
    lv_errbuf  VARCHAR2(5000); -- 共通関数エラーバッファ
    lv_errmsg  VARCHAR2(5000); -- 共通関数エラーメッセージ
--
--##############################  固定部 END   ##################################
--
    
    --===============================================================
    -- ローカル変数
    --===============================================================
    lv_get_bm_flag     VARCHAR2(1);   -- BM取得判別
    lv_get_bm_price    VARCHAR2(1);   -- 率額取得判別
    --
    --===============================================================
    -- ローカルカーソル
    --===============================================================
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 処理件数初期化
    gn_rec_count := 0;
    --
    OPEN get_invoice_cur(id_target_date,iv_ar_code1);
    --
      -- コレクション変数に代入
      FETCH get_invoice_cur BULK COLLECT INTO g_inv_tab;
      --
      -- データ件数取得
      --
      gn_rec_count := g_inv_tab.COUNT;
      --
    CLOSE get_invoice_cur;
    --
    -- 
    <<invoice_loop>>
    FOR i IN 1..gn_rec_count LOOP
    --
      -- 値代入
      g_inv_tab(i).conc_request_id := gn_conc_request_id;    -- 要求ID
      g_inv_tab(i).sort_num        := i;                     -- ソート順
      --
      --
    --===============================================================
    -- A-4．販手条件の取得
    --===============================================================
        chk_bm(id_target_date    => id_target_date,              -- 締日
               in_invoice_id     => g_inv_tab(i).invoice_id,     -- 一括請求書ID
               iv_account_number => g_inv_tab(i).bill_cust_code, -- 請求先顧客コード
               iv_account_name   => g_inv_tab(i).bill_cust_name, -- 請求先顧客名
               ov_get_bm_flag    => lv_get_bm_flag,              -- BM取得フラグ
               ov_get_bm_price   => lv_get_bm_price,             -- 率額取得フラグ
               ov_errbuf         => lv_errbuf,
               ov_retcode        => lv_retcode,
               ov_errmsg         => lv_errmsg);
      --
      IF (lv_get_bm_flag = 'Y') THEN  -- BM取得フラグが'Y'
      --
    --===============================================================
    -- A-5．販売手数料・電気代の取得
    --===============================================================
        get_bm(id_target_date   => id_target_date,            -- 締日
               in_num           => i,                         -- レコード特定
               in_invoice_id    => g_inv_tab(i).invoice_id,   -- 一括請求書ID
               iv_get_bm_price  => lv_get_bm_price,           -- 率額取得判定
               ov_errbuf        => lv_errbuf,
               ov_retcode       => lv_retcode,
               ov_errmsg        => lv_errmsg
              );
        --
    --===============================================================
    -- A-6．VD請求金額の算出 
    --===============================================================
      g_inv_tab(i).vd_amount_claimed :=
        g_inv_tab(i).inv_amount_includ_tax - NVL(g_inv_tab(i).bm_price1,0);
--
      END IF;
      --
      --
      -- ワークテーブル書込変数へ代入
      --
      g_csv_outs_tab(i).request_id  := g_inv_tab(i).conc_request_id;
      g_csv_outs_tab(i).seq         := g_inv_tab(i).sort_num;
      g_csv_outs_tab(i).col1        := g_inv_tab(i).itoen_name;
      g_csv_outs_tab(i).col2        := g_inv_tab(i).inv_creation_date;
      g_csv_outs_tab(i).col3        := g_inv_tab(i).object_month;
      g_csv_outs_tab(i).col4        := g_inv_tab(i).object_date_from;
      g_csv_outs_tab(i).col5        := g_inv_tab(i).object_date_to;
      g_csv_outs_tab(i).col6        := g_inv_tab(i).vender_code;
      g_csv_outs_tab(i).col7        := g_inv_tab(i).bill_location_code;
      g_csv_outs_tab(i).col8        := g_inv_tab(i).bill_location_name;
      g_csv_outs_tab(i).col9        := g_inv_tab(i).agent_tel_num;
      g_csv_outs_tab(i).col10       := g_inv_tab(i).credit_cust_code;
      g_csv_outs_tab(i).col11       := g_inv_tab(i).credit_cust_name;
      g_csv_outs_tab(i).col12       := g_inv_tab(i).receipt_cust_code;
      g_csv_outs_tab(i).col13       := g_inv_tab(i).receipt_cust_name;
      g_csv_outs_tab(i).col14       := g_inv_tab(i).payment_cust_code;
      g_csv_outs_tab(i).col15       := g_inv_tab(i).payment_cust_name;
      g_csv_outs_tab(i).col16       := g_inv_tab(i).bill_cust_code;
      g_csv_outs_tab(i).col17       := g_inv_tab(i).bill_cust_name;
      g_csv_outs_tab(i).col18       := g_inv_tab(i).credit_receiv_code2;
      g_csv_outs_tab(i).col19       := g_inv_tab(i).credit_receiv_name2;
      g_csv_outs_tab(i).col20       := g_inv_tab(i).credit_receiv_code3;
      g_csv_outs_tab(i).col21       := g_inv_tab(i).credit_receiv_name3;
      g_csv_outs_tab(i).col22       := g_inv_tab(i).sold_location_code;
      g_csv_outs_tab(i).col23       := g_inv_tab(i).sold_location_name;
      g_csv_outs_tab(i).col24       := g_inv_tab(i).ship_cust_code;
      g_csv_outs_tab(i).col25       := g_inv_tab(i).ship_cust_name;
      g_csv_outs_tab(i).col26       := g_inv_tab(i).bill_shop_code;
      g_csv_outs_tab(i).col27       := g_inv_tab(i).bill_shop_name;
      g_csv_outs_tab(i).col28       := g_inv_tab(i).ship_shop_code;
      g_csv_outs_tab(i).col29       := g_inv_tab(i).ship_shop_name;
      g_csv_outs_tab(i).col30       := g_inv_tab(i).vd_num;
      g_csv_outs_tab(i).col31       := g_inv_tab(i).delivery_date;
      g_csv_outs_tab(i).col32       := g_inv_tab(i).slip_num;
      g_csv_outs_tab(i).col33       := g_inv_tab(i).order_num;
      g_csv_outs_tab(i).col34       := g_inv_tab(i).column_num;
      g_csv_outs_tab(i).col35       := g_inv_tab(i).item_code;
      g_csv_outs_tab(i).col36       := g_inv_tab(i).jan_code;
      g_csv_outs_tab(i).col37       := g_inv_tab(i).item_name;
      g_csv_outs_tab(i).col38       := g_inv_tab(i).vessel;
      g_csv_outs_tab(i).col39       := g_inv_tab(i).quantity;
      g_csv_outs_tab(i).col40       := g_inv_tab(i).unit_price;
      g_csv_outs_tab(i).col41       := g_inv_tab(i).ship_amount;
      g_csv_outs_tab(i).col42       := g_inv_tab(i).sold_amount;
      g_csv_outs_tab(i).col43       := g_inv_tab(i).sold_amount_plus;
      g_csv_outs_tab(i).col44       := g_inv_tab(i).sold_amount_minus;
      g_csv_outs_tab(i).col45       := g_inv_tab(i).sold_amount_total;
      g_csv_outs_tab(i).col46       := g_inv_tab(i).inv_amount_includ_tax;
      g_csv_outs_tab(i).col47       := g_inv_tab(i).tax_amount_sum;
      g_csv_outs_tab(i).col48       := g_inv_tab(i).bm_unit_price1;
      g_csv_outs_tab(i).col49       := g_inv_tab(i).bm_rate1;
      g_csv_outs_tab(i).col50       := g_inv_tab(i).bm_price1;
      g_csv_outs_tab(i).col51       := g_inv_tab(i).bm_unit_price2;
      g_csv_outs_tab(i).col52       := g_inv_tab(i).bm_rate2;
      g_csv_outs_tab(i).col53       := g_inv_tab(i).bm_price2;
      g_csv_outs_tab(i).col54       := g_inv_tab(i).bm_unit_price3;
      g_csv_outs_tab(i).col55       := g_inv_tab(i).bm_rate3;
      g_csv_outs_tab(i).col56       := g_inv_tab(i).bm_price3;
      g_csv_outs_tab(i).col57       := g_inv_tab(i).vd_amount_claimed;
      g_csv_outs_tab(i).col58       := g_inv_tab(i).electric_charges;
      g_csv_outs_tab(i).col59       := g_inv_tab(i).slip_type;
      g_csv_outs_tab(i).col60       := g_inv_tab(i).classify_type;
      --
    END LOOP invoice_loop;
    --
  EXCEPTION
    WHEN OTHERS THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application => cv_xxcfr_app_name,
                                            iv_name => ct_msg_cfr_00016,
                                            iv_token_name1 => cv_tkn_tab_name,
                                            iv_token_value1 => xxcfr_common_pkg.get_table_comment('XXCFR_CSV_OUTS_TEMP')
                                           );
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := lv_errmsg;
  END get_invoice;
  /**********************************************************************************
   * Procedure Name   : ins
   * Description      : ワークテーブル追加処理(A-7)
   ***********************************************************************************/
  PROCEDURE ins(
    ov_errbuf        OUT VARCHAR2,
    ov_retcode       OUT VARCHAR2,
    ov_errmsg        OUT VARCHAR2
  )
  IS
--
--#######################  固定ローカル定数宣言部 START   #######################
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins';  -- プログラム名
--
--##############################  固定部 END   ##################################
--
--#######################  固定ローカル変数宣言部 START   #######################
--
    lv_errmsg  VARCHAR2(5000); -- 共通関数エラーメッセージ
--
--##############################  固定部 END   ##################################
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
  --
    FORALL i IN 1..gn_rec_count
    --
      INSERT INTO xxcfr_csv_outs_temp VALUES g_csv_outs_tab(i);
      --
  EXCEPTION
    WHEN OTHERS THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_xxcfr_app_name,
                                            iv_name         => ct_msg_cfr_00016,
                                            iv_token_name1  => cv_tkn_tab_name,
                                            iv_token_value1 => xxcfr_common_pkg.get_table_comment('XXCFR_CSV_OUTS_TEMP')
                                           );
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
      --
  END ins;
  --
  /**********************************************************************************
   * Procedure Name   : put
   * Description      : ファイル出力処理(A-8)
   ***********************************************************************************/
  PROCEDURE put(
    ov_errbuf        OUT VARCHAR2,
    ov_retcode       OUT VARCHAR2,
    ov_errmsg        OUT VARCHAR2
  )
  IS
--
--#######################  固定ローカル定数宣言部 START   #######################
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put';  -- プログラム名
--
--##############################  固定部 END   ##################################
    --===============================================================
    -- ローカル定数
    --===============================================================
    --===============================================================
    -- ローカル変数
    --===============================================================
    lv_func_name fnd_lookup_values.description%TYPE;  -- 汎用請求出力処理共通関数名
    
--
--#######################  固定ローカル変数宣言部 START   #######################
--
    lv_retcode VARCHAR2(1);    -- 共通関数リターンコード
    lv_errbuf  VARCHAR2(5000); -- 共通関数エラーバッファ
    lv_errmsg  VARCHAR2(5000); -- 共通関数エラーメッセージ
--
--##############################  固定部 END   ##################################
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- OUTファイル出力処理実行
    xxcfr_common_pkg.csv_out(in_request_id  => FND_GLOBAL.CONC_REQUEST_ID,
                             iv_lookup_type => ct_lookup_type_out,
                             in_rec_cnt     => gn_rec_count,
                             ov_retcode     => lv_retcode,
                             ov_errbuf      => lv_errbuf,
                             ov_errmsg      => lv_errmsg
                            );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
    
  EXCEPTION
    -- *** 共通関数エラー発生時 ***
    WHEN global_api_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      ov_errmsg := lv_errmsg;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      BEGIN
        SELECT flvv.description description
        INTO lv_func_name
        FROM fnd_lookup_values_vl flvv
        WHERE flvv.lookup_type = ct_lookup_type_func_name
          AND flvv.lookup_code = ct_lookup_code_func_name
          AND flvv.enabled_flag = cv_yes
          AND SYSDATE BETWEEN flvv.start_date_active AND flvv.end_date_active;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application => cv_xxcfr_app_name,
                                            iv_name => ct_msg_cfr_00010,
                                            iv_token_name1 => cv_func_name,
                                            iv_token_value1 => lv_func_name);
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := lv_errmsg;
    WHEN OTHERS THEN
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
  END put;
  
  /**********************************************************************************
   * Procedure Name   : end_proc
   * Description      : 終了処理プロシージャ(A-9)
   ***********************************************************************************/
  PROCEDURE end_proc(
    iv_retcode          IN  VARCHAR2,  -- 処理ステータス
    ov_errbuf           OUT VARCHAR2,
    ov_retcode          OUT VARCHAR2,
    ov_errmsg           OUT VARCHAR2
  )
  IS
--
--#######################  固定ローカル定数宣言部 START   #######################
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'end_proc';  -- プログラム名
--
--##############################  固定部 END   ##################################
--
--
--#######################  固定ローカル変数宣言部 START   #######################
--
    lv_retcode VARCHAR2(1);    -- 共通関数リターンコード
    lv_errbuf  VARCHAR2(5000); -- 共通関数エラーバッファ
    lv_errmsg  VARCHAR2(5000); -- 共通関数エラーメッセージ
--
--##############################  固定部 END   ##################################
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    FND_FILE.PUT_LINE(FND_FILE.LOG,'');
    
    -- 対象データ0件警告メッセージ出力
    IF (iv_retcode = cv_status_warn) THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,
                            xxccp_common_pkg.get_msg(iv_application => cv_xxcfr_app_name,
                                                     iv_name => ct_msg_cfr_00024
                                                    )
                           );
    END IF;
    
    -- 件数出力
    -- 正常または警告終了の場合
    IF ((iv_retcode = cv_status_normal) OR (iv_retcode = cv_status_warn)) THEN
      -- 対象件数出力
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                        xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                 iv_name => ct_msg_ccp_90000,
                                                 iv_token_name1 => cv_tkn_count,
                                                 iv_token_value1 => gn_rec_count
                                                )
                       );
      
      -- 成功件数出力
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                        xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                 iv_name => ct_msg_ccp_90001,
                                                 iv_token_name1 => cv_tkn_count,
                                                 iv_token_value1 => gn_rec_count
                                                )
                       );
      
      -- エラー件数出力
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                        xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                 iv_name => ct_msg_ccp_90002,
                                                 iv_token_name1 => cv_tkn_count,
                                                 iv_token_value1 => 0
                                                )
                       );
    -- エラー終了の場合
    ELSIF (iv_retcode = cv_status_error) THEN
      -- 対象件数出力
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                        xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                 iv_name => ct_msg_ccp_90000,
                                                 iv_token_name1 => cv_tkn_count,
                                                 iv_token_value1 => 0
                                                )
                       );
      
      -- 成功件数出力
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                        xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                 iv_name => ct_msg_ccp_90001,
                                                 iv_token_name1 => cv_tkn_count,
                                                 iv_token_value1 => 0
                                                )
                       );
      
      -- エラー件数出力
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                        xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                 iv_name => ct_msg_ccp_90002,
                                                 iv_token_name1 => cv_tkn_count,
                                                 iv_token_value1 => 1
                                                )
                       );
      -- エラーが存在しない場合
    END IF;
    
    -- 終了メッセージ出力
    -- エラーが存在する場合
    IF (iv_retcode = cv_status_error) THEN
      -- エラー終了メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                        xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                 iv_name => ct_msg_ccp_90006
                                                )
                       );
    -- 対象データ0件の場合(警告終了)
    ELSIF (iv_retcode = cv_status_warn) THEN
      -- 警告終了メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                        xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                 iv_name => ct_msg_ccp_90005
                                                )
                       );
    -- 正常終了の場合
    ELSE
      -- 正常終了メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                        xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                 iv_name => ct_msg_ccp_90004
                                                )
                       );
    END IF;
    
  EXCEPTION
    WHEN OTHERS THEN
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
  END end_proc;
  
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : 汎用店別請求データ作成処理実行部
   ***********************************************************************************/
  PROCEDURE submain(
    iv_target_date   IN  VARCHAR2,    -- 締日
    iv_ar_code1      IN  VARCHAR2,    -- 売掛コード１(請求書)
    ov_errbuf        OUT VARCHAR2,
    ov_retcode       OUT VARCHAR2,
    ov_errmsg        OUT VARCHAR2
  )
  IS
--
--#######################  固定ローカル定数宣言部 START   #######################
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain';  -- プログラム名
--
--##############################  固定部 END   ##################################
--
    -- ===============================
    -- ローカル定数
    -- ===============================
--
--#######################  固定ローカル変数宣言部 START   #######################
--
    lv_retcode VARCHAR2(1);    -- 共通関数リターンコード
    lv_errbuf  VARCHAR2(5000); -- 共通関数エラーバッファ
    lv_errmsg  VARCHAR2(5000); -- 共通関数エラーメッセージ
--
--##############################  固定部 END   ##################################
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --===============================================================
    -- A-1．初期処理
    --===============================================================
    init(iv_target_date,
         iv_ar_code1,
         lv_errbuf,
         lv_retcode,
         lv_errmsg
        );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    --
    --===============================================================
    -- A-2．出力セキュリティ判定
    --===============================================================
    gv_enable_all := xxcfr_common_pkg.chk_invoice_all_dept(iv_user_dept_code => gt_user_dept_code,
                                                           iv_invoice_type => cv_invoice_type
                                                          );
    IF (gv_enable_all = cv_yes) THEN
      gv_enable_all := cv_enable_all;
    ELSE
      gv_enable_all := cv_disable_all;
    END IF;
    --
    --===============================================================
    -- A-3．請求情報取得処理
    --===============================================================
    get_invoice(xxcfr_common_pkg.get_date_param_trans(iv_target_date),
                iv_ar_code1,
                lv_errbuf,
                lv_retcode,
                lv_errmsg
               );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    --
    --===============================================================
    -- A-7．ワークテーブル追加処理
    --===============================================================
    ins(lv_errbuf,
        lv_retcode,
        lv_errmsg
       );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    --
    --===============================================================
    -- A-8．ファイル出力処理
    --===============================================================
    put(lv_errbuf,
        lv_retcode,
        lv_errmsg
       );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    
    -- 処理件数0の場合警告終了
    IF (gn_rec_count = 0) THEN
      ov_retcode := cv_status_warn;
    END IF;
    
  EXCEPTION
    -- *** サブプログラムエラー発生時 ***
    WHEN global_process_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      ov_errmsg := lv_errmsg;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
    WHEN OTHERS THEN
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
  END submain;
  
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   ***********************************************************************************/
  PROCEDURE main(
    errbuf           OUT VARCHAR2,
    retcode          OUT VARCHAR2,
    iv_target_date   IN  VARCHAR2,    -- 締日
    iv_ar_code1      IN  VARCHAR2     -- 売掛コード１(請求書)
  ) IS
    
--
--#######################  固定ローカル定数宣言部 START   #######################
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
--
--##############################  固定部 END   ##################################
--
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_put_log_which CONSTANT VARCHAR2(10) := 'LOG';  -- ログヘッダ出力関数iv_whichパラメータ
--
--#######################  固定ローカル変数宣言部 START   #######################
--
    lv_retcode VARCHAR2(1);    -- 共通関数リターンコード
    lv_errbuf  VARCHAR2(5000); -- 共通関数エラーバッファ
    lv_errmsg  VARCHAR2(5000); -- 共通関数エラーメッセージ
--
--##############################  固定部 END   ##################################
--
    
  BEGIN
    
    xxccp_common_pkg.put_log_header(iv_which => cv_put_log_which,
                                    ov_retcode => lv_retcode,
                                    ov_errbuf => lv_errbuf,
                                    ov_errmsg => lv_errmsg
                                   );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
    
    submain(iv_target_date,
            iv_ar_code1,
            lv_errbuf,
            lv_retcode,
            lv_errmsg
           );
    
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'');
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcfr_app_name
                     ,iv_name         => ct_msg_cfr_00056
                   )
      );      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    
    -- ステータスをセット
    retcode := lv_retcode;
    
    --===============================================================
    -- A-9．終了処理
    --===============================================================
    end_proc(retcode,
             lv_errbuf,
             lv_retcode,
             lv_errmsg
            );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    
   -- 終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
        ROLLBACK;
    END IF;
    
  EXCEPTION
    -- *** 共通関数エラー発生時 ***
    WHEN global_api_expt THEN
      ROLLBACK;
      errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf;
      retcode := cv_status_error;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
    -- *** サブプログラムエラー発生時 ***
    WHEN global_process_expt THEN
      ROLLBACK;
      errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf;
      retcode := cv_status_error;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ROLLBACK;
      errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
    WHEN OTHERS THEN
      ROLLBACK;
      errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
  
END  XXCFR003A06C;
/
