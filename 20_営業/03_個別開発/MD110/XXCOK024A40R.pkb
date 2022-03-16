CREATE OR REPLACE PACKAGE BODY XXCOK024A40R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK024A40R(body)
 * Description      : 問屋未収単価チェックリスト
 * MD.050           : MD050_COK_024_A40_問屋未収単価チェックリスト.doc
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  del_wholesale_pay      ワークテーブルデータ削除(A-6)
 *  start_svf              SVF起動(A-5)
 *  ins_wholesale_pay      ワークテーブルデータ登録(A-4)
 *  get_target_data        対象データ取得(A-2)・控除マスタ情報取得(A-3)
 *  init                   初期処理(A-1)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2022/01/28    1.0   K.Yoshikawa     新規作成
 *
 *****************************************************************************************/
  -- ===============================================
  -- グローバル定数
  -- ===============================================
  -- パッケージ名
  cv_pkg_name                CONSTANT VARCHAR2(20)  := 'XXCOK024A40R';
  -- アプリケーション短縮名
  cv_xxcok_appl_short_name   CONSTANT VARCHAR2(10)  := 'XXCOK';
  cv_xxccp_appl_short_name   CONSTANT VARCHAR2(10)  := 'XXCCP';
  -- ステータス・コード
  cv_status_normal           CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_normal;  -- 正常:0
  cv_status_warn             CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_warn;    -- 警告:1
  cv_status_error            CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_error;   -- 異常:2
  -- WHOカラム
  cn_created_by              CONSTANT NUMBER        := fnd_global.user_id;          -- CREATED_BY
  cn_last_updated_by         CONSTANT NUMBER        := fnd_global.user_id;          -- LAST_UPDATED_BY
  cn_last_update_login       CONSTANT NUMBER        := fnd_global.login_id;         -- LAST_UPDATE_LOGIN
  cn_request_id              CONSTANT NUMBER        := fnd_global.conc_request_id;  -- REQUEST_ID
  cn_program_application_id  CONSTANT NUMBER        := fnd_global.prog_appl_id;     -- PROGRAM_APPLICATION_ID
  cn_program_id              CONSTANT NUMBER        := fnd_global.conc_program_id;  -- PROGRAM_ID
  -- メッセージコード
  cv_msg_code_00001          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00001';          -- 対象データなしメッセージ
  cv_msg_code_00003          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00003';          -- プロファイル取得エラー
  cv_msg_code_00013          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00013';          -- 在庫組織ID取得エラー
  cv_msg_code_00015          CONSTANT VARCHAR2(25)  := 'APP-XXCOK1-00015';          -- クイックコード取得エラーメッセージ
  cv_msg_code_00028          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00028';          -- 業務処理日付取得エラー
  cv_msg_code_00040          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00040';          -- SVF起動APIエラー
  cv_msg_code_10829          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10829';          -- 支払年月日(入力パラメータ)
  cv_msg_code_10830          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10830';          -- 計上年月日(入力パラメータ)
  cv_msg_code_10831          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10831';          -- 拠点コード(入力パラメータ)
  cv_msg_code_10832          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10832';          -- 仕入先コード(入力パラメータ)
  cv_msg_code_10833          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10833';          -- 請求書番号(入力パラメータ)
  cv_msg_code_10834          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10834';          -- 控除用チェーンコード(入力パラメータ)
  cv_msg_code_10043          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10043';          -- データ削除エラー
  cv_msg_code_10827          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10827';          -- ロック取得エラー
  cv_msg_code_90000          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90000';          -- 対象件数
  cv_msg_code_90001          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90001';          -- 成功件数
  cv_msg_code_90002          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90002';          -- エラー件数
  cv_msg_code_90004          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90004';          -- 正常終了
  cv_msg_code_90006          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90006';          -- エラー終了全ロールバック
  cv_msg_code_10566          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10566';          -- 消費税履歴重複エラー
  -- トークン
  cv_token_pay_date          CONSTANT VARCHAR2(15)  := 'PAY_DATE';
  cv_token_target_date       CONSTANT VARCHAR2(15)  := 'TARGET_DATE';
  cv_token_base_code         CONSTANT VARCHAR2(15)  := 'BASE_CODE';
  cv_token_supplier_code     CONSTANT VARCHAR2(15)  := 'SUPPLIER_CODE';
  cv_token_bill_no           CONSTANT VARCHAR2(15)  := 'BILL_NO';
  cv_token_chain_code        CONSTANT VARCHAR2(15)  := 'CHAIN_CODE';
  cv_token_profile           CONSTANT VARCHAR2(15)  := 'PROFILE';
  cv_token_org_code          CONSTANT VARCHAR2(15)  := 'ORG_CODE';
  cv_token_request_id        CONSTANT VARCHAR2(15)  := 'REQUEST_ID';
  cv_token_count             CONSTANT VARCHAR2(15)  := 'COUNT';
  cv_token_lookup_value_set  CONSTANT VARCHAR2(25)  := 'LOOKUP_VALUE_SET';
  -- プロファイル
  cv_prof_org_code_sales     CONSTANT VARCHAR2(25)  := 'XXCOK1_ORG_CODE_SALES';     -- 在庫組織コード_営業組織
  cv_prof_org_id             CONSTANT VARCHAR2(25)  := 'ORG_ID';                    -- 営業単位ID
  -- セパレータ
  cv_msg_part                CONSTANT VARCHAR2(3)   := ' : ';
  cv_msg_cont                CONSTANT VARCHAR2(3)   := '.';
  -- 数値
  cn_number_0                CONSTANT NUMBER        := 0;
  cn_number_1                CONSTANT NUMBER        := 1;
  -- 出力区分
  cv_which                   CONSTANT VARCHAR2(3)   := 'LOG';                       -- 出力区分
  -- タイプ
  cv_lookup_tax_code_his     CONSTANT VARCHAR2(25)  := 'XXCFO1_TAX_CODE_HISTORIES';
  cv_lookup_tax_pay_check    CONSTANT VARCHAR2(30)  := 'XXCOK1_WHOLESALE_PAY_CHECK';
  -- SVF起動パラメータ
  cv_file_id                 CONSTANT VARCHAR2(20)  := 'XXCOK024A40R';              -- 帳票ID
  cv_output_mode             CONSTANT VARCHAR2(1)   := '1';                         -- 出力区分(PDF出力)
  cv_extension               CONSTANT VARCHAR2(10)  := '.pdf';                      -- 出力ファイル名拡張子(PDF出力)
  cv_frm_file                CONSTANT VARCHAR2(20)  := 'XXCOK024A40S.xml';          -- フォーム様式ファイル名
  cv_vrq_file                CONSTANT VARCHAR2(20)  := 'XXCOK024A40S.vrq';          -- クエリー様式ファイル名
  -- ===============================================
  -- グローバル変数
  -- ===============================================
  gn_target_cnt                NUMBER        DEFAULT 0;                             -- 対象件数
  gn_normal_cnt                NUMBER        DEFAULT 0;                             -- 正常件数
  gn_error_cnt                 NUMBER        DEFAULT 0;                             -- エラー件数
  gv_org_code_sales            VARCHAR2(50)  DEFAULT NULL;                          -- プロファイル値(在庫組織コード_営業組織)
  gn_org_id_sales              NUMBER        DEFAULT NULL;                          -- 在庫組織ID
  gn_org_id                    NUMBER        DEFAULT NULL;                          -- 営業単位ID
  gd_process_date              DATE          DEFAULT NULL;                          -- 業務処理日付
  gv_no_data_msg               VARCHAR2(30)  DEFAULT NULL;                          -- 対象データなしメッセージ
  gn_demand_en_3               NUMBER        DEFAULT NULL;                          -- 請求(円)
  gn_shop_pay_en_3             NUMBER        DEFAULT NULL;                          -- 店納(円)
  gn_accrued_en_3              NUMBER        DEFAULT NULL;                          -- 未収計３(円)
  gn_normal_shop_pay_en_4_1    NUMBER        DEFAULT NULL;                          -- 通常店納(円)_1
  gn_normal_shop_pay_en_4_2    NUMBER        DEFAULT NULL;                          -- 通常店納(円)_2
  gn_normal_shop_pay_en_4_3    NUMBER        DEFAULT NULL;                          -- 通常店納(円)_3
  gn_normal_shop_pay_en_4_4    NUMBER        DEFAULT NULL;                          -- 通常店納(円)_4
  gn_normal_shop_pay_en_4_5    NUMBER        DEFAULT NULL;                          -- 通常店納(円)_5
  gn_normal_shop_pay_en_4_6    NUMBER        DEFAULT NULL;                          -- 通常店納(円)_6
  gn_just_shop_pay_en_4_1      NUMBER        DEFAULT NULL;                          -- 今回店納(円)_1
  gn_just_shop_pay_en_4_2      NUMBER        DEFAULT NULL;                          -- 今回店納(円)_2
  gn_just_shop_pay_en_4_3      NUMBER        DEFAULT NULL;                          -- 今回店納(円)_3
  gn_just_shop_pay_en_4_4      NUMBER        DEFAULT NULL;                          -- 今回店納(円)_4
  gn_just_shop_pay_en_4_5      NUMBER        DEFAULT NULL;                          -- 今回店納(円)_5
  gn_just_shop_pay_en_4_6      NUMBER        DEFAULT NULL;                          -- 今回店納(円)_6
  gn_just_condition_en_4_1     NUMBER        DEFAULT NULL;                          -- 今回条件(円)_1
  gn_just_condition_en_4_2     NUMBER        DEFAULT NULL;                          -- 今回条件(円)_2
  gn_just_condition_en_4_3     NUMBER        DEFAULT NULL;                          -- 今回条件(円)_3
  gn_just_condition_en_4_4     NUMBER        DEFAULT NULL;                          -- 今回条件(円)_4
  gn_just_condition_en_4_5     NUMBER        DEFAULT NULL;                          -- 今回条件(円)_5
  gn_just_condition_en_4_6     NUMBER        DEFAULT NULL;                          -- 今回条件(円)_6
  gn_accrued_en_4_1            NUMBER        DEFAULT NULL;                          -- 未収計４(円)_1
  gn_dedu_est_kbn_1            NUMBER        DEFAULT NULL;                          -- 未収計４(円)_1_控除見積区分
  gn_accrued_en_4_2            NUMBER        DEFAULT NULL;                          -- 未収計４(円)_2
  gn_dedu_est_kbn_2            NUMBER        DEFAULT NULL;                          -- 未収計４(円)_2_控除見積区分
  gn_accrued_en_4_3            NUMBER        DEFAULT NULL;                          -- 未収計４(円)_3
  gn_dedu_est_kbn_3            NUMBER        DEFAULT NULL;                          -- 未収計４(円)_3_控除見積区分
  gn_accrued_en_4_4            NUMBER        DEFAULT NULL;                          -- 未収計４(円)_4
  gn_dedu_est_kbn_4            NUMBER        DEFAULT NULL;                          -- 未収計４(円)_4_控除見積区分
  gn_accrued_en_4_5            NUMBER        DEFAULT NULL;                          -- 未収計４(円)_5
  gn_dedu_est_kbn_5            NUMBER        DEFAULT NULL;                          -- 未収計４(円)_5_控除見積区分
  gn_accrued_en_4_6            NUMBER        DEFAULT NULL;                          -- 未収計４(円)_6
  gn_dedu_est_kbn_6            NUMBER        DEFAULT NULL;                          -- 未収計４(円)_6_控除見積区分
  -- ===============================================
  -- グローバルカーソル
  -- ===============================================
  CURSOR g_target_cur(
    iv_payment_date          IN VARCHAR2  -- 支払年月日
  , iv_selling_date          IN VARCHAR2  -- 売上対象年月日
  , iv_base_code             IN VARCHAR2  -- 拠点コード
  , iv_wholesale_vendor_code IN VARCHAR2  -- 仕入先コード
  , iv_bill_no               IN VARCHAR2  -- 請求書番号
  , iv_chain_code            IN VARCHAR2  -- 控除用チェーンコード
  )
  IS
    SELECT  /*+ INDEX(pvsa PO_VENDOR_SITES_U2)*/
            xwbl.wholesale_bill_detail_id                        wholesale_bill_detail_id    --問屋請求書明細ID
           ,xwbh.expect_payment_date                             payment_date                --支払年月日
           ,xwbl.bill_no                                         bill_no                     --請求書no.
           ,xwbh.base_code                                       base_code                   --拠点コード
           ,( SELECT SUBSTRB(xbav.base_name,1,20)                             -- 拠点名称
              FROM   apps.xxcok_base_all_v xbav                               -- 拠点ビュー
              WHERE  xbav.base_code = xwbh.base_code                          -- 拠点コード
             )                                                   base_name                   --拠点名称
           ,xwbh.cust_code                                       cust_code                   --顧客コード
           ,SUBSTRB(hp.party_name,1,100)                         cust_name                   --顧客名称
           ,xwbl.sales_outlets_code                              deduction_chain_code        --控除用チェーンコード
           ,SUBSTRB(flv.meaning,1,80)                            deduction_chain_name        --控除用チェーン名
           ,xwbl.selling_date                                    selling_date                --売上年月日
           ,xwbl.item_code                                       item_code                   --品目コード
           ,SUBSTRB(item.item_short_name,1,100)                  item_name                   --品目名称
           ,xwbl.demand_qty                                      demand_qty                  --請求数量
           ,xwbl.demand_unit_price                               demand_unit_price           --請求単価
           ,xwbl.difference_amt                                  difference_amt              --端数調整
           ,xwbl.demand_amt                                      demand_amt                  --請求金額
           ,xwbl.demand_unit_type                                demand_unit_type            --単位
           ,xwbl.expansion_sales_type                            expansion_sales_type        --拡売区分
           ,xwbh.supplier_code                                   supplier_code               --仕入先コード
           ,SUBSTRB(pv.vendor_name,1,100)                        supplier_name               --仕入先名称
           ,SUBSTRB(bank.bank_name,1,60)                         bank_name                   --銀行名
           ,SUBSTRB(bank.bank_branch_name,1,60)                  bank_branch_name            --支店名
           ,bank.bank_account_type                               bank_account_type           --口座種別
           ,bank.bank_account_num                                bank_account_num            --口座番号
           ,(SELECT xrtrv.tax_rate
             FROM   apps.xxcos_reduced_tax_rate_v xrtrv
             WHERE  xrtrv.item_code(+)     = xwbl.item_code
             AND    xwbl.selling_date     >= xrtrv.start_date(+)
             AND    xwbl.selling_date     <= NVL(xrtrv.end_date(+), xwbl.selling_date)
             AND    xwbl.selling_date     >= xrtrv.start_date_histories(+)
             AND    xwbl.selling_date     <= NVL(xrtrv.end_date_histories(+), xwbl.selling_date)
            )                                                    tax_rate                    --税率
    FROM    apps.xxcok_wholesale_bill_head xwbh
           ,apps.xxcok_wholesale_bill_line xwbl
           ,apps.hz_cust_accounts          hca
           ,apps.hz_parties                hp
           ,apps.xxcmm_cust_accounts       xca
           ,( SELECT iimb.item_no                  AS item_code               -- 品目コード
                   , ximb.item_short_name          AS item_short_name         -- 品名・略名
              FROM   apps.ic_item_mst_b         iimb                          -- OPM品目マスタ
                   , apps.xxcmn_item_mst_b      ximb                          -- OPM品目アドオンマスタ
              WHERE  iimb.item_id          = ximb.item_id
              AND    gd_process_date BETWEEN ximb.start_date_active
                                         AND NVL ( ximb.end_date_active , gd_process_date )               --A-1で取得した業務日付
            ) item
           ,( SELECT abau.vendor_id        AS vendor_id                       -- 内部仕入先ID
                   , abau.vendor_site_id   AS vendor_site_id                  -- 内部仕入先サイトID
                   , abb.bank_name         AS bank_name                       -- 銀行名
                   , abb.bank_branch_name  AS bank_branch_name                -- 銀行支店名
                   , hl.meaning            AS bank_account_type               -- 口座種別
                   , abaa.bank_account_num AS bank_account_num                -- 口座番号
              FROM   apps.ap_bank_branches              abb                   -- 銀行支店情報
                   , apps.ap_bank_accounts_all          abaa                  -- 銀行口座情報
                   , apps.ap_bank_account_uses_all      abau                  -- 銀行口座使用情報
                   , apps.hr_lookups                    hl                    -- クイックコード
              WHERE  abau.external_bank_account_id = abaa.bank_account_id
              AND    abaa.bank_branch_id           = abb.bank_branch_id
              AND    abaa.org_id                   = gn_org_id 
              AND    abaa.bank_account_type        = hl.lookup_code(+)
              AND    hl.lookup_type(+)             = 'XXCSO1_KOZA_TYPE'
              AND    abau.primary_flag             = 'Y'
              AND    abau.org_id                   = gn_org_id 
              AND    ( abau.start_date            <= gd_process_date OR abau.start_date IS NULL )         --A-1で取得した業務日付
              AND    ( abau.end_date              >= gd_process_date OR abau.end_date   IS NULL )
             ) bank
           ,apps.fnd_lookup_values              flv
           ,apps.po_vendors                     pv
           ,apps.po_vendor_sites_all            pvsa
    WHERE   xwbh.wholesale_bill_header_id  = xwbl.wholesale_bill_header_id
    AND     (   xwbl.status               is NULL
             OR xwbl.status               <> 'D' )
    AND     xwbh.expect_payment_date       = to_date(iv_payment_date,'yyyy/mm/dd')                        --パラメータ必須
    AND     xwbl.selling_date              = nvl(to_date(iv_selling_date,'yyyy/mm/dd'),xwbl.selling_date) --パラメータ任意
    AND     xwbh.base_code                 = nvl(iv_base_code,xwbh.base_code)                             --パラメータ任意
    AND     xwbh.supplier_code             = nvl(iv_wholesale_vendor_code,xwbh.supplier_code)             --パラメータ任意
    AND     xwbl.bill_no                   = nvl(iv_bill_no,xwbl.bill_no)                                 --パラメータ任意
    AND     xwbl.sales_outlets_code        = nvl(iv_chain_code,xwbl.sales_outlets_code)                   --パラメータ任意
    AND     hca.account_number             = xwbh.cust_code
    AND     hca.cust_account_id            = xca.customer_id
    AND     hca.party_id                   = hp.party_id
    AND     item.item_code(+)              = xwbl.item_code
    AND     pv.segment1                    = xwbh.supplier_code
    AND     pv.vendor_id                   = pvsa.vendor_id
    AND     pvsa.vendor_id                 = bank.vendor_id(+)
    AND     pvsa.vendor_site_id            = bank.vendor_site_id(+)
    AND     pvsa.org_id                    = gn_org_id 
    AND     ( pvsa.inactive_date > gd_process_date OR pvsa.inactive_date IS NULL )                        --A-1で取得した業務日付
    AND     flv.LOOKUP_TYPE                = 'XXCMM_CHAIN_CODE' 
    AND     flv.LANGUAGE                   = 'JA' 
    AND     flv.lookup_code                = xwbl.sales_outlets_code
    AND     flv.enabled_flag               = 'Y'
    AND     gd_process_date BETWEEN nvl(flv.start_date_active, gd_process_date)                           --A-1で取得した業務日付
                                  AND     nvl(flv.end_date_active, gd_process_date)
    ORDER BY
     xwbh.expect_payment_date
    ,xwbl.selling_date
    ,xwbh.cust_code
    ,xwbh.supplier_code
    ,xwbl.bill_no
    ,xwbl.sales_outlets_code
    ,xwbh.cust_code
    ,xwbl.wholesale_bill_detail_id;
  TYPE g_target_ttype IS TABLE OF g_target_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  g_target_tab g_target_ttype;
--
  CURSOR lookup_stamp_cur
  IS
    SELECT flv.lookup_code   AS lookup_code
         , flv.meaning       AS meaning
         , flv.description   AS description
         , flv.tag           AS tag
    FROM   fnd_lookup_values flv
    WHERE  flv.lookup_type  = cv_lookup_tax_pay_check
    AND    gd_process_date BETWEEN NVL( flv.start_date_active, gd_process_date )
                               AND NVL( flv.end_date_active, gd_process_date )
    AND    flv.language     = USERENV('LANG')
    AND    flv.enabled_flag = 'Y'
    ORDER BY flv.lookup_code
  ;
  lookup_stamp_rec   lookup_stamp_cur%ROWTYPE;
  TYPE g_lookup_stamp_ttype IS TABLE OF lookup_stamp_cur%ROWTYPE INDEX BY VARCHAR2(1);
  g_lookup_stamp_tab g_lookup_stamp_ttype;
--
  -- ===============================================
  -- 共通例外
  -- ===============================================
  --*** ロックエラー ***
  global_lock_fail          EXCEPTION;
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_lock_fail, -54);
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
  /**********************************************************************************
   * Procedure Name   : del_wholesale_pay
   * Description      : ワークテーブルデータ削除(A-6)
   ***********************************************************************************/
  PROCEDURE del_wholesale_pay(
    ov_errbuf        OUT VARCHAR2  -- エラー・メッセージ
  , ov_retcode       OUT VARCHAR2  -- リターン・コード
  , ov_errmsg        OUT VARCHAR2  -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name      CONSTANT VARCHAR2(20) := 'del_wholesale_pay';  -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode  VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    lb_retcode  BOOLEAN        DEFAULT TRUE;              -- メッセージ出力関数戻り値
    -- ===============================================
    -- ローカルカーソル
    -- ===============================================
    CURSOR wholesale_pay_cur
    IS
      SELECT 'X'
      FROM   xxcok_wholesale_pay_check_list  xrwp
      WHERE  xrwp.request_id = cn_request_id
      FOR UPDATE OF xrwp.wholesale_bill_detail_id NOWAIT;
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- 問屋未収単価チェックリストワークテーブルロック取得
    -- ===============================================
    OPEN  wholesale_pay_cur;
    CLOSE wholesale_pay_cur;
    -- ===============================================
    -- 問屋未収単価チェックリストワークテーブルデータ削除
    -- ===============================================
    BEGIN
      DELETE FROM xxcok_wholesale_pay_check_list  xrwp
      WHERE  xrwp.request_id = cn_request_id;
      -- ===============================================
      -- 成功件数取得
      -- ===============================================
      gn_normal_cnt := SQL%ROWCOUNT;
    EXCEPTION
      -- *** 削除処理エラー ***
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_appl_short_name
                      , iv_name         => cv_msg_code_10043
                      , iv_token_name1  => cv_token_request_id
                      , iv_token_value1 => cn_request_id
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG
                      , iv_message  => lv_errmsg
                      , in_new_line => cn_number_0
                      );
        ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
        ov_retcode := cv_status_error;
    END;
  EXCEPTION
    --*** ロックエラー ***
    WHEN global_lock_fail THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_10827
                    , iv_token_name1  => cv_token_request_id
                    , iv_token_value1 => cn_request_id
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END del_wholesale_pay;
  /**********************************************************************************
   * Procedure Name   : start_svf
   * Description      : SVF起動(A-5)
   ***********************************************************************************/
  PROCEDURE start_svf(
    ov_errbuf        OUT VARCHAR2  -- エラー・メッセージ
  , ov_retcode       OUT VARCHAR2  -- リターン・コード
  , ov_errmsg        OUT VARCHAR2  -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name      CONSTANT VARCHAR2(10) := 'start_svf'; -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf    VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode   VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg    VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    lv_outmsg    VARCHAR2(5000) DEFAULT NULL;              -- 出力用メッセージ
    lb_retcode   BOOLEAN        DEFAULT TRUE;              -- メッセージ出力関数戻り値
    lv_date      VARCHAR2(8)    DEFAULT NULL;              -- 出力ファイル名用日付
    lv_file_name VARCHAR2(100)  DEFAULT NULL;              -- 出力ファイル名
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- システム日付型変換
    -- ===============================================
    lv_date := TO_CHAR( SYSDATE, 'YYYYMMDD' );
    -- ===============================================
    -- 出力ファイル名(帳票ID + YYYYMMDD + 要求ID)
    -- ===============================================
    lv_file_name := cv_file_id || lv_date || TO_CHAR( cn_request_id ) || cv_extension;
    -- ===============================================
    -- SVFコンカレント起動
    -- ===============================================
    xxccp_svfcommon_pkg.submit_svf_request(
        ov_errbuf        => lv_errbuf                  -- エラーバッファ
      , ov_retcode       => lv_retcode                 -- リターンコード
      , ov_errmsg        => lv_errmsg                  -- エラーメッセージ
      , iv_conc_name     => cv_pkg_name                -- コンカレント名
      , iv_file_name     => lv_file_name               -- 出力ファイル名
      , iv_file_id       => cv_file_id                 -- 帳票ID
      , iv_output_mode   => cv_output_mode             -- 出力区分
      , iv_frm_file      => cv_frm_file                -- フォーム様式ファイル名
      , iv_vrq_file      => cv_vrq_file                -- クエリー様式ファイル名
      , iv_org_id        => TO_CHAR( gn_org_id_sales ) -- ORG_ID
      , iv_user_name     => fnd_global.user_name       -- ログイン・ユーザ名
      , iv_resp_name     => fnd_global.resp_name       -- ログイン・ユーザ職責名
      , iv_doc_name      => NULL                       -- 文書名
      , iv_printer_name  => NULL                       -- プリンタ名
      , iv_request_id    => TO_CHAR( cn_request_id )   -- 要求ID
      , iv_nodata_msg    => NULL                       -- データなしメッセージ
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00040
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_outmsg
                    , in_new_line => cn_number_0
                    );
      RAISE global_api_expt;
    END IF;
  EXCEPTION
    -- *** 共通関数例外 ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END start_svf;
  /**********************************************************************************
   * Procedure Name   : ins_wholesale_pay
   * Description      : ワークテーブルデータ登録(A-4)
   ***********************************************************************************/
  PROCEDURE ins_wholesale_pay(
    ov_errbuf                    OUT VARCHAR2  -- エラー・メッセージ
  , ov_retcode                   OUT VARCHAR2  -- リターン・コード
  , ov_errmsg                    OUT VARCHAR2  -- ユーザー・エラー・メッセージ
  , iv_payment_date              IN VARCHAR2   -- 支払年月日
  , iv_selling_date              IN VARCHAR2   -- 売上対象年月日
  , iv_base_code                 IN VARCHAR2   -- 拠点コード
  , iv_wholesale_vendor_code     IN VARCHAR2   -- 仕入先コード
  , iv_bill_no                   IN VARCHAR2   -- 請求書番号
  , iv_chain_code                IN VARCHAR2   -- 控除用チェーンコード
  , in_i                         IN NUMBER     -- LOOPカウンタ
  , iv_no_condition              IN VARCHAR2   -- 控除マスタなし
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name      CONSTANT VARCHAR2(20) := 'ins_wholesale_pay';     -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf                VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode               VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg                VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    lv_tax                   VARCHAR2(2)    DEFAULT NULL;              -- 税記号
    lv_stamp                 VARCHAR2(2)    DEFAULT NULL;              -- 印記号
    ln_normal_shop_pay_en_4  NUMBER         DEFAULT NULL;              -- 通常店納
    ln_just_shop_pay_en_4    NUMBER         DEFAULT NULL;              -- 特売店納
    ln_net_selling_price     NUMBER         DEFAULT NULL;              -- NET価格
    ln_accrued_en_3          NUMBER         DEFAULT NULL;              -- 通常
    ln_accrued_en_3_c        VARCHAR2(2)    DEFAULT NULL;              -- 通常_チェック
    ln_accrued_en_4_1        NUMBER         DEFAULT NULL;              -- 拡売1
    ln_accrued_en_4_1_c      VARCHAR2(2)    DEFAULT NULL;              -- 拡売1_チェック
    ln_accrued_en_4_2        NUMBER         DEFAULT NULL;              -- 拡売2
    ln_accrued_en_4_2_c      VARCHAR2(2)    DEFAULT NULL;              -- 拡売2_チェック
    ln_accrued_en_4_3        NUMBER         DEFAULT NULL;              -- 拡売3
    ln_accrued_en_4_3_c      VARCHAR2(2)    DEFAULT NULL;              -- 拡売3_チェック
    ln_accrued_en_4_4        NUMBER         DEFAULT NULL;              -- 拡売4
    ln_accrued_en_4_4_c      VARCHAR2(2)    DEFAULT NULL;              -- 拡売4_チェック
    ln_accrued_en_4_5        NUMBER         DEFAULT NULL;              -- 拡売5
    ln_accrued_en_4_5_c      VARCHAR2(2)    DEFAULT NULL;              -- 拡売5_チェック
    ln_accrued_en_4_6        NUMBER         DEFAULT NULL;              -- 拡売6
    ln_accrued_en_4_6_c      VARCHAR2(2)    DEFAULT NULL;              -- 拡売6_チェック
    ln_dedu_est_kbn_1        NUMBER         DEFAULT NULL;              -- 拡売1_控除見積区分_
    ln_dedu_est_kbn_2        NUMBER         DEFAULT NULL;              -- 拡売2_控除見積区分_
    ln_dedu_est_kbn_3        NUMBER         DEFAULT NULL;              -- 拡売3_控除見積区分_
    ln_dedu_est_kbn_4        NUMBER         DEFAULT NULL;              -- 拡売4_控除見積区分_
    ln_dedu_est_kbn_5        NUMBER         DEFAULT NULL;              -- 拡売5_控除見積区分_
    ln_dedu_est_kbn_6        NUMBER         DEFAULT NULL;              -- 拡売6_控除見積区分_
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- 登録対象項目計算
    -- ===============================================
    IF ( gn_target_cnt <> 0 ) THEN
      -- ===============================================
      -- 税(印)
      -- 税率10%の場合、税に印を設定する。
      -- ===============================================
      IF ( g_target_tab( in_i ).tax_rate = g_lookup_stamp_tab( '2' ).tag  ) THEN
        lv_tax := g_lookup_stamp_tab( '2' ).meaning;
      END IF;
      -- ===============================================
      -- 単価チェック
      -- 請求単価と控除マスタ単価を比較
      -- ===============================================
      IF
      --①通常単価と一致
         g_target_tab( in_i ).demand_unit_price - gn_accrued_en_3 = 0 THEN
           lv_stamp                := NULL;
           ln_normal_shop_pay_en_4 := gn_shop_pay_en_3;
           ln_just_shop_pay_en_4   := NULL;
           ln_net_selling_price    := gn_demand_en_3 - gn_accrued_en_3;
           ln_accrued_en_3         := gn_accrued_en_3;
           ln_accrued_en_3_c       := g_lookup_stamp_tab( '3' ).meaning;
           ln_accrued_en_4_1       := gn_accrued_en_4_1;
           ln_accrued_en_4_1_c     := NULL;
           ln_accrued_en_4_2       := gn_accrued_en_4_2;
           ln_accrued_en_4_2_c     := NULL;
           ln_accrued_en_4_3       := gn_accrued_en_4_3;
           ln_accrued_en_4_3_c     := NULL;
           ln_accrued_en_4_4       := gn_accrued_en_4_4;
           ln_accrued_en_4_4_c     := NULL;
           ln_accrued_en_4_5       := gn_accrued_en_4_5;
           ln_accrued_en_4_5_c     := NULL;
           ln_accrued_en_4_6       := gn_accrued_en_4_6;
           ln_accrued_en_4_6_c     := NULL;
      ELSIF
      --②通常単価と拡売単価1と一致
         g_target_tab( in_i ).demand_unit_price - gn_accrued_en_3 - gn_accrued_en_4_1 = 0 THEN
           lv_stamp                := NULL;
           ln_normal_shop_pay_en_4 := gn_normal_shop_pay_en_4_1;
           ln_just_shop_pay_en_4   := gn_just_shop_pay_en_4_1;
           ln_net_selling_price    := gn_demand_en_3 - gn_accrued_en_3 - gn_accrued_en_4_1;
           ln_accrued_en_3         := gn_accrued_en_3;
           ln_accrued_en_3_c       := g_lookup_stamp_tab( '3' ).meaning;
           ln_accrued_en_4_1       := gn_accrued_en_4_1;
           IF gn_dedu_est_kbn_1 = 0 THEN
              ln_accrued_en_4_1_c     := g_lookup_stamp_tab( '3' ).meaning;
           ELSIF gn_dedu_est_kbn_1 = 1 THEN
              ln_accrued_en_4_1_c     := g_lookup_stamp_tab( '4' ).meaning;
           ELSE NULL;
           END IF;
           ln_accrued_en_4_2       := gn_accrued_en_4_2;
           ln_accrued_en_4_2_c     := NULL;
           ln_accrued_en_4_3       := gn_accrued_en_4_3;
           ln_accrued_en_4_3_c     := NULL;
           ln_accrued_en_4_4       := gn_accrued_en_4_4;
           ln_accrued_en_4_4_c     := NULL;
           ln_accrued_en_4_5       := gn_accrued_en_4_5;
           ln_accrued_en_4_5_c     := NULL;
           ln_accrued_en_4_6       := gn_accrued_en_4_6;
           ln_accrued_en_4_6_c     := NULL;
      ELSIF
      --③通常単価と拡売単価2と一致
         g_target_tab( in_i ).demand_unit_price - gn_accrued_en_3 - gn_accrued_en_4_2 = 0 THEN
           lv_stamp                := NULL;
           ln_normal_shop_pay_en_4 := gn_normal_shop_pay_en_4_2;
           ln_just_shop_pay_en_4   := gn_just_shop_pay_en_4_2;
           ln_net_selling_price    := gn_demand_en_3 - gn_accrued_en_3 - gn_accrued_en_4_2;
           ln_accrued_en_3         := gn_accrued_en_3;
           ln_accrued_en_3_c       := g_lookup_stamp_tab( '3' ).meaning;
           ln_accrued_en_4_1       := gn_accrued_en_4_1;
           ln_accrued_en_4_1_c     := NULL;
           ln_accrued_en_4_2       := gn_accrued_en_4_2;
           IF gn_dedu_est_kbn_2 = 0 THEN
              ln_accrued_en_4_2_c     := g_lookup_stamp_tab( '3' ).meaning;
           ELSIF gn_dedu_est_kbn_2 = 1 THEN
              ln_accrued_en_4_2_c     := g_lookup_stamp_tab( '4' ).meaning;
           ELSE NULL;
           END IF;
           ln_accrued_en_4_3       := gn_accrued_en_4_3;
           ln_accrued_en_4_3_c     := NULL;
           ln_accrued_en_4_4       := gn_accrued_en_4_4;
           ln_accrued_en_4_4_c     := NULL;
           ln_accrued_en_4_5       := gn_accrued_en_4_5;
           ln_accrued_en_4_5_c     := NULL;
           ln_accrued_en_4_6       := gn_accrued_en_4_6;
           ln_accrued_en_4_6_c     := NULL;
      ELSIF
      --④通常単価と拡売単価3と一致
         g_target_tab( in_i ).demand_unit_price - gn_accrued_en_3 - gn_accrued_en_4_3 = 0 THEN
           lv_stamp                := NULL;
           ln_normal_shop_pay_en_4 := gn_normal_shop_pay_en_4_3;
           ln_just_shop_pay_en_4   := gn_just_shop_pay_en_4_3;
           ln_net_selling_price    := gn_demand_en_3 - gn_accrued_en_3 - gn_accrued_en_4_3;
           ln_accrued_en_3         := gn_accrued_en_3;
           ln_accrued_en_3_c       := g_lookup_stamp_tab( '3' ).meaning;
           ln_accrued_en_4_1       := gn_accrued_en_4_1;
           ln_accrued_en_4_1_c     := NULL;
           ln_accrued_en_4_2       := gn_accrued_en_4_2;
           ln_accrued_en_4_2_c     := NULL;
           ln_accrued_en_4_3       := gn_accrued_en_4_3;
           IF gn_dedu_est_kbn_3 = 0 THEN
              ln_accrued_en_4_3_c     := g_lookup_stamp_tab( '3' ).meaning;
           ELSIF gn_dedu_est_kbn_3 = 1 THEN
              ln_accrued_en_4_3_c     := g_lookup_stamp_tab( '4' ).meaning;
           ELSE NULL;
           END IF;
           ln_accrued_en_4_4       := gn_accrued_en_4_4;
           ln_accrued_en_4_4_c     := NULL;
           ln_accrued_en_4_5       := gn_accrued_en_4_5;
           ln_accrued_en_4_5_c     := NULL;
           ln_accrued_en_4_6       := gn_accrued_en_4_6;
           ln_accrued_en_4_6_c     := NULL;
      ELSIF
      --⑤通常単価と拡売単価4と一致
         g_target_tab( in_i ).demand_unit_price - gn_accrued_en_3 - gn_accrued_en_4_4 = 0 THEN
           lv_stamp                := NULL;
           ln_normal_shop_pay_en_4 := gn_normal_shop_pay_en_4_4;
           ln_just_shop_pay_en_4   := gn_just_shop_pay_en_4_4;
           ln_net_selling_price    := gn_demand_en_3 - gn_accrued_en_3 - gn_accrued_en_4_4;
           ln_accrued_en_3         := gn_accrued_en_3;
           ln_accrued_en_3_c       := g_lookup_stamp_tab( '3' ).meaning;
           ln_accrued_en_4_1       := gn_accrued_en_4_1;
           ln_accrued_en_4_1_c     := NULL;
           ln_accrued_en_4_2       := gn_accrued_en_4_2;
           ln_accrued_en_4_2_c     := NULL;
           ln_accrued_en_4_3       := gn_accrued_en_4_3;
           ln_accrued_en_4_3_c     := NULL;
           ln_accrued_en_4_4       := gn_accrued_en_4_4;
           IF gn_dedu_est_kbn_4 = 0 THEN
              ln_accrued_en_4_4_c     := g_lookup_stamp_tab( '3' ).meaning;
           ELSIF gn_dedu_est_kbn_4 = 1 THEN
              ln_accrued_en_4_4_c     := g_lookup_stamp_tab( '4' ).meaning;
           ELSE NULL;
           END IF;
           ln_accrued_en_4_5       := gn_accrued_en_4_5;
           ln_accrued_en_4_5_c     := NULL;
           ln_accrued_en_4_6       := gn_accrued_en_4_6;
           ln_accrued_en_4_6_c     := NULL;
      ELSIF
      --⑥通常単価と拡売単価5と一致
         g_target_tab( in_i ).demand_unit_price - gn_accrued_en_3 - gn_accrued_en_4_5 = 0 THEN
           lv_stamp                := NULL;
           ln_normal_shop_pay_en_4 := gn_normal_shop_pay_en_4_5;
           ln_just_shop_pay_en_4   := gn_just_shop_pay_en_4_5;
           ln_net_selling_price    := gn_demand_en_3 - gn_accrued_en_3 - gn_accrued_en_4_5;
           ln_accrued_en_3         := gn_accrued_en_3;
           ln_accrued_en_3_c       := g_lookup_stamp_tab( '3' ).meaning;
           ln_accrued_en_4_1       := gn_accrued_en_4_1;
           ln_accrued_en_4_1_c     := NULL;
           ln_accrued_en_4_2       := gn_accrued_en_4_2;
           ln_accrued_en_4_2_c     := NULL;
           ln_accrued_en_4_3       := gn_accrued_en_4_3;
           ln_accrued_en_4_3_c     := NULL;
           ln_accrued_en_4_4       := gn_accrued_en_4_4;
           ln_accrued_en_4_4_c     := NULL;
           ln_accrued_en_4_5       := gn_accrued_en_4_5;
           IF gn_dedu_est_kbn_5 = 0 THEN
              ln_accrued_en_4_5_c     := g_lookup_stamp_tab( '3' ).meaning;
           ELSIF gn_dedu_est_kbn_5 = 1 THEN
              ln_accrued_en_4_5_c     := g_lookup_stamp_tab( '4' ).meaning;
           ELSE NULL;
           END IF;
           ln_accrued_en_4_6       := gn_accrued_en_4_6;
           ln_accrued_en_4_6_c     := NULL;
      ELSIF
      --⑦通常単価と拡売単価6と一致
         g_target_tab( in_i ).demand_unit_price - gn_accrued_en_3 - gn_accrued_en_4_6 = 0 THEN
           lv_stamp                := NULL;
           ln_normal_shop_pay_en_4 := gn_normal_shop_pay_en_4_6;
           ln_just_shop_pay_en_4   := gn_just_shop_pay_en_4_6;
           ln_net_selling_price    := gn_demand_en_3 - gn_accrued_en_3 - gn_accrued_en_4_6;
           ln_accrued_en_3         := gn_accrued_en_3;
           ln_accrued_en_3_c       := g_lookup_stamp_tab( '3' ).meaning;
           ln_accrued_en_4_1       := gn_accrued_en_4_1;
           ln_accrued_en_4_1_c     := NULL;
           ln_accrued_en_4_2       := gn_accrued_en_4_2;
           ln_accrued_en_4_2_c     := NULL;
           ln_accrued_en_4_3       := gn_accrued_en_4_3;
           ln_accrued_en_4_3_c     := NULL;
           ln_accrued_en_4_4       := gn_accrued_en_4_4;
           ln_accrued_en_4_4_c     := NULL;
           ln_accrued_en_4_5       := gn_accrued_en_4_5;
           ln_accrued_en_4_5_C     := NULL;
           ln_accrued_en_4_6       := gn_accrued_en_4_6;
           IF gn_dedu_est_kbn_6 = 0 THEN
              ln_accrued_en_4_6_c     := g_lookup_stamp_tab( '3' ).meaning;
           ELSIF gn_dedu_est_kbn_6 = 1 THEN
              ln_accrued_en_4_6_c     := g_lookup_stamp_tab( '4' ).meaning;
           ELSE NULL;
           END IF;
      ELSIF
      --⑧拡売単価1と一致
         g_target_tab( in_i ).demand_unit_price - gn_accrued_en_4_1 = 0 THEN
           lv_stamp                := NULL;
           ln_normal_shop_pay_en_4 := gn_normal_shop_pay_en_4_1;
           ln_just_shop_pay_en_4   := gn_just_shop_pay_en_4_1;
           ln_net_selling_price    := gn_demand_en_3 - gn_accrued_en_3 - gn_accrued_en_4_1;
           ln_accrued_en_3         := gn_accrued_en_3;
           ln_accrued_en_3_c       := NULL;
           ln_accrued_en_4_1       := gn_accrued_en_4_1;
           IF gn_dedu_est_kbn_1 = 0 THEN
              ln_accrued_en_4_1_c     := g_lookup_stamp_tab( '3' ).meaning;
           ELSIF gn_dedu_est_kbn_1 = 1 THEN
              ln_accrued_en_4_1_c     := g_lookup_stamp_tab( '4' ).meaning;
           ELSE NULL;
           END IF;
           ln_accrued_en_4_2       := gn_accrued_en_4_2;
           ln_accrued_en_4_2_c     := NULL;
           ln_accrued_en_4_3       := gn_accrued_en_4_3;
           ln_accrued_en_4_3_c     := NULL;
           ln_accrued_en_4_4       := gn_accrued_en_4_4;
           ln_accrued_en_4_4_c     := NULL;
           ln_accrued_en_4_5       := gn_accrued_en_4_5;
           ln_accrued_en_4_5_c     := NULL;
           ln_accrued_en_4_6       := gn_accrued_en_4_6;
           ln_accrued_en_4_6_c     := NULL;
      ELSIF
      --⑨拡売単価2と一致
         g_target_tab( in_i ).demand_unit_price - gn_accrued_en_4_2 = 0 THEN
           lv_stamp                := NULL;
           ln_normal_shop_pay_en_4 := gn_normal_shop_pay_en_4_2;
           ln_just_shop_pay_en_4   := gn_just_shop_pay_en_4_2;
           ln_net_selling_price    := gn_demand_en_3 - gn_accrued_en_3 - gn_accrued_en_4_2;
           ln_accrued_en_3         := gn_accrued_en_3;
           ln_accrued_en_3_c       := NULL;
           ln_accrued_en_4_1       := gn_accrued_en_4_1;
           ln_accrued_en_4_1_c     := NULL;
           ln_accrued_en_4_2       := gn_accrued_en_4_2;
           IF gn_dedu_est_kbn_2 = 0 THEN
              ln_accrued_en_4_2_c     := g_lookup_stamp_tab( '3' ).meaning;
           ELSIF gn_dedu_est_kbn_2 = 1 THEN
              ln_accrued_en_4_2_c     := g_lookup_stamp_tab( '4' ).meaning;
           ELSE NULL;
           END IF;
           ln_accrued_en_4_3       := gn_accrued_en_4_3;
           ln_accrued_en_4_3_c     := NULL;
           ln_accrued_en_4_4       := gn_accrued_en_4_4;
           ln_accrued_en_4_4_c     := NULL;
           ln_accrued_en_4_5       := gn_accrued_en_4_5;
           ln_accrued_en_4_5_c     := NULL;
           ln_accrued_en_4_6       := gn_accrued_en_4_6;
           ln_accrued_en_4_6_c     := NULL;
      ELSIF
      --⑩拡売単価3と一致
         g_target_tab( in_i ).demand_unit_price - gn_accrued_en_4_3 = 0 THEN
           lv_stamp                := NULL;
           ln_normal_shop_pay_en_4 := gn_normal_shop_pay_en_4_3;
           ln_just_shop_pay_en_4   := gn_just_shop_pay_en_4_3;
           ln_net_selling_price    := gn_demand_en_3 - gn_accrued_en_3 - gn_accrued_en_4_3;
           ln_accrued_en_3         := gn_accrued_en_3;
           ln_accrued_en_3_c       := NULL;
           ln_accrued_en_4_1       := gn_accrued_en_4_1;
           ln_accrued_en_4_1_c     := NULL;
           ln_accrued_en_4_2       := gn_accrued_en_4_2;
           ln_accrued_en_4_2_c     := NULL;
           ln_accrued_en_4_3       := gn_accrued_en_4_3;
           IF gn_dedu_est_kbn_3 = 0 THEN
              ln_accrued_en_4_3_c     := g_lookup_stamp_tab( '3' ).meaning;
           ELSIF gn_dedu_est_kbn_3 = 1 THEN
              ln_accrued_en_4_3_c     := g_lookup_stamp_tab( '4' ).meaning;
           ELSE NULL;
           END IF;
           ln_accrued_en_4_4       := gn_accrued_en_4_4;
           ln_accrued_en_4_4_c     := NULL;
           ln_accrued_en_4_5       := gn_accrued_en_4_5;
           ln_accrued_en_4_5_c     := NULL;
           ln_accrued_en_4_6       := gn_accrued_en_4_6;
           ln_accrued_en_4_6_c     := NULL;
      ELSIF
      --⑪拡売単価4と一致
         g_target_tab( in_i ).demand_unit_price - gn_accrued_en_4_4 = 0 THEN
           lv_stamp                := NULL;
           ln_normal_shop_pay_en_4 := gn_normal_shop_pay_en_4_4;
           ln_just_shop_pay_en_4   := gn_just_shop_pay_en_4_4;
           ln_net_selling_price    := gn_demand_en_3 - gn_accrued_en_3 - gn_accrued_en_4_4;
           ln_accrued_en_3         := gn_accrued_en_3;
           ln_accrued_en_3_c       := NULL;
           ln_accrued_en_4_1       := gn_accrued_en_4_1;
           ln_accrued_en_4_1_c     := NULL;
           ln_accrued_en_4_2       := gn_accrued_en_4_2;
           ln_accrued_en_4_2_c     := NULL;
           ln_accrued_en_4_3       := gn_accrued_en_4_3;
           ln_accrued_en_4_3_c     := NULL;
           ln_accrued_en_4_4       := gn_accrued_en_4_4;
           IF gn_dedu_est_kbn_4 = 0 THEN
              ln_accrued_en_4_4_c     := g_lookup_stamp_tab( '3' ).meaning;
           ELSIF gn_dedu_est_kbn_4 = 1 THEN
              ln_accrued_en_4_4_c     := g_lookup_stamp_tab( '4' ).meaning;
           ELSE NULL;
           END IF;
           ln_accrued_en_4_5       := gn_accrued_en_4_5;
           ln_accrued_en_4_5_c     := NULL;
           ln_accrued_en_4_6       := gn_accrued_en_4_6;
           ln_accrued_en_4_6_c     := NULL;
      ELSIF
      --⑫拡売単価5と一致
         g_target_tab( in_i ).demand_unit_price - gn_accrued_en_4_5 = 0 THEN
           lv_stamp                := NULL;
           ln_normal_shop_pay_en_4 := gn_normal_shop_pay_en_4_5;
           ln_just_shop_pay_en_4   := gn_just_shop_pay_en_4_5;
           ln_net_selling_price    := gn_demand_en_3 - gn_accrued_en_3 - gn_accrued_en_4_5;
           ln_accrued_en_3         := gn_accrued_en_3;
           ln_accrued_en_3_c       := NULL;
           ln_accrued_en_4_1       := gn_accrued_en_4_1;
           ln_accrued_en_4_1_c     := NULL;
           ln_accrued_en_4_2       := gn_accrued_en_4_2;
           ln_accrued_en_4_2_c     := NULL;
           ln_accrued_en_4_3       := gn_accrued_en_4_3;
           ln_accrued_en_4_3_c     := NULL;
           ln_accrued_en_4_4       := gn_accrued_en_4_4;
           ln_accrued_en_4_4_c     := NULL;
           ln_accrued_en_4_5       := gn_accrued_en_4_5;
           IF gn_dedu_est_kbn_5 = 0 THEN
              ln_accrued_en_4_5_c     := g_lookup_stamp_tab( '3' ).meaning;
           ELSIF gn_dedu_est_kbn_5 = 1 THEN
              ln_accrued_en_4_5_c     := g_lookup_stamp_tab( '4' ).meaning;
           ELSE NULL;
           END IF;
           ln_accrued_en_4_6       := gn_accrued_en_4_6;
           ln_accrued_en_4_6_c     := NULL;
      ELSIF
      --⑬拡売単価6と一致
         g_target_tab( in_i ).demand_unit_price - gn_accrued_en_4_6 = 0 THEN
           lv_stamp                := NULL;
           ln_normal_shop_pay_en_4 := gn_normal_shop_pay_en_4_6;
           ln_just_shop_pay_en_4   := gn_just_shop_pay_en_4_6;
           ln_net_selling_price    := gn_demand_en_3 - gn_accrued_en_3 - gn_accrued_en_4_6;
           ln_accrued_en_3         := gn_accrued_en_3;
           ln_accrued_en_3_c       := NULL;
           ln_accrued_en_4_1       := gn_accrued_en_4_1;
           ln_accrued_en_4_1_c     := NULL;
           ln_accrued_en_4_2       := gn_accrued_en_4_2;
           ln_accrued_en_4_2_c     := NULL;
           ln_accrued_en_4_3       := gn_accrued_en_4_3;
           ln_accrued_en_4_3_c     := NULL;
           ln_accrued_en_4_4       := gn_accrued_en_4_4;
           ln_accrued_en_4_4_c     := NULL;
           ln_accrued_en_4_5       := gn_accrued_en_4_5;
           ln_accrued_en_4_5_c     := NULL;
           ln_accrued_en_4_6       := gn_accrued_en_4_6;
           IF gn_dedu_est_kbn_6 = 0 THEN
              ln_accrued_en_4_6_c     := g_lookup_stamp_tab( '3' ).meaning;
           ELSIF gn_dedu_est_kbn_6 = 1 THEN
              ln_accrued_en_4_6_c     := g_lookup_stamp_tab( '4' ).meaning;
           ELSE NULL;
           END IF;
      ELSE
           lv_stamp                := g_lookup_stamp_tab( '1' ).meaning;
           ln_normal_shop_pay_en_4 := gn_shop_pay_en_3;
           ln_just_shop_pay_en_4   := NULL;
           ln_net_selling_price    := gn_demand_en_3 - gn_accrued_en_3;
           ln_accrued_en_3         := gn_accrued_en_3;
           ln_accrued_en_3_c       := NULL;
           ln_accrued_en_4_1       := gn_accrued_en_4_1;
           ln_accrued_en_4_1_c     := NULL;
           ln_accrued_en_4_2       := gn_accrued_en_4_2;
           ln_accrued_en_4_2_c     := NULL;
           ln_accrued_en_4_3       := gn_accrued_en_4_3;
           ln_accrued_en_4_3_c     := NULL;
           ln_accrued_en_4_4       := gn_accrued_en_4_4;
           ln_accrued_en_4_4_c     := NULL;
           ln_accrued_en_4_5       := gn_accrued_en_4_5;
           ln_accrued_en_4_5_c     := NULL;
           ln_accrued_en_4_6       := gn_accrued_en_4_6;
           ln_accrued_en_4_6_c     := NULL;
      END IF;
      IF iv_no_condition = 'Y' THEN
           lv_stamp                := g_lookup_stamp_tab( '1' ).meaning;
           ln_normal_shop_pay_en_4 := NULL;
           ln_just_shop_pay_en_4   := NULL;
           ln_net_selling_price    := NULL;
           ln_accrued_en_3         := NULL;
           ln_accrued_en_3_c       := NULL;
           ln_accrued_en_4_1       := NULL;
           ln_accrued_en_4_1_c     := NULL;
           ln_accrued_en_4_2       := NULL;
           ln_accrued_en_4_2_c     := NULL;
           ln_accrued_en_4_3       := NULL;
           ln_accrued_en_4_3_c     := NULL;
           ln_accrued_en_4_4       := NULL;
           ln_accrued_en_4_4_c     := NULL;
           ln_accrued_en_4_5       := NULL;
           ln_accrued_en_4_5_c     := NULL;
           ln_accrued_en_4_6       := NULL;
           ln_accrued_en_4_6_c     := NULL;
      END IF;
      -- ===============================================
      -- ワークテーブルデータ登録
      -- ===============================================
      INSERT INTO xxcok_wholesale_pay_check_list(
        wholesale_bill_detail_id                       -- 問屋請求書明細ID
      , p_payment_date                                 -- 支払年月日(入力パラメータ)
      , p_selling_date                                 -- 売上対象年月日(入力パラメータ)
      , p_base_code                                    -- 拠点コード(入力パラメータ)
      , p_vendor_code                                  -- 仕入先コード(入力パラメータ)
      , p_bill_no                                      -- 請求書番号(入力パラメータ)
      , p_deduction_chain_code                         -- 控除用チェーン(入力パラメータ)
      , symbol1                                        -- ヘッダ用記号１
      , symbol1_description                            -- ヘッダ用記号１摘要
      , symbol2                                        -- ヘッダ用記号２
      , symbol2_description                            -- ヘッダ用記号２摘要
      , symbol2_tag                                    -- ヘッダ用記号２タグ
      , symbol3                                        -- ヘッダ用記号３
      , symbol3_description                            -- ヘッダ用記号３摘要
      , symbol4                                        -- ヘッダ用記号４
      , symbol4_description                            -- ヘッダ用記号４摘要
      , payment_date                                   -- 支払年月日
      , bill_no                                        -- 請求書No.
      , base_code                                      -- 拠点コード
      , base_name                                      -- 拠点名
      , cust_code                                      -- 顧客コード
      , cust_name                                      -- 顧客名称
      , deduction_chain_code                           -- 控除用チェーンコード
      , deduction_chain_name                           -- 控除用チェーン名
      , selling_date                                   -- 売上対象年月日
      , item_code                                      -- 品目コード
      , item_name                                      -- 品目名称
      , expansion_sales_type                           -- 拡売区分
      , demand_qty                                     -- 請求数量
      , demand_unit_price                              -- 請求単価
      , difference_amt                                 -- 端数調整
      , demand_amt                                     -- 請求金額
      , unit_type                                      -- 請求単位
      , supplier_code                                  -- 仕入先コード
      , supplier_name                                  -- 仕入先名
      , bank_name                                      -- 銀行名
      , bank_branch_name                               -- 支店名
      , bank_acct_type                                 -- 口座種別
      , bank_acct_no                                   -- 口座番号
      , tax_rate                                       -- 税率
      , tax                                            -- 税
      , stamp                                          -- 印
      , demand_en_3                                    -- 建値
      , shop_pay_en_3                                  -- 店納(円)
      , normal_shop_pay_en_4                           -- 通常店納
      , just_shop_pay_en_4                             -- 特売店納
      , net_selling_price                              -- NET価格
      , accrued_en_3                                   -- 通常
      , accrued_en_3_c                                 -- 通常_チェック
      , accrued_en_4_1                                 -- 拡売1
      , accrued_en_4_1_c                               -- 拡売1_チェック
      , accrued_en_4_2                                 -- 拡売2
      , accrued_en_4_2_c                               -- 拡売2_チェック
      , accrued_en_4_3                                 -- 拡売3
      , accrued_en_4_3_c                               -- 拡売3_チェック
      , accrued_en_4_4                                 -- 拡売4
      , accrued_en_4_4_c                               -- 拡売4_チェック
      , accrued_en_4_5                                 -- 拡売5
      , accrued_en_4_5_c                               -- 拡売5_チェック
      , accrued_en_4_6                                 -- 拡売6
      , accrued_en_4_6_c                               -- 拡売6_チェック
      , no_data_message                                -- 0件メッセージ
      , created_by                                     -- 作成者
      , creation_date                                  -- 作成日
      , last_updated_by                                -- 最終更新者
      , last_update_date                               -- 最終更新日
      , last_update_login                              -- 最終更新ログイン
      , request_id                                     -- 要求ID
      , program_application_id                         -- コンカレント・プログラム・アプリケーションID
      , program_id                                     -- コンカレント・プログラムID
      , program_update_date                            -- プログラム更新日
      ) VALUES (
        g_target_tab( in_i ).wholesale_bill_detail_id  -- 問屋請求書明細ID
      , iv_payment_date                                -- 支払年月日(入力パラメータ)
      , iv_selling_date                                -- 売上対象年月(入力パラメータ)
      , iv_base_code                                   -- 拠点コード(入力パラメータ)
      , iv_wholesale_vendor_code                       -- 仕入先コード(入力パラメータ)
      , iv_bill_no                                     -- 請求書番号(入力パラメータ)
      , iv_chain_code                                  -- 控除用チェーン(入力パラメータ)
      , g_lookup_stamp_tab( '1' ).meaning              -- ヘッダ用記号１
      , g_lookup_stamp_tab( '1' ).description          -- ヘッダ用記号１摘要
      , g_lookup_stamp_tab( '2' ).meaning              -- ヘッダ用記号２
      , g_lookup_stamp_tab( '2' ).description          -- ヘッダ用記号２摘要
      , g_lookup_stamp_tab( '2' ).tag                  -- ヘッダ用記号２タグ
      , g_lookup_stamp_tab( '3' ).meaning              -- ヘッダ用記号３
      , g_lookup_stamp_tab( '3' ).description          -- ヘッダ用記号３摘要
      , g_lookup_stamp_tab( '4' ).meaning              -- ヘッダ用記号４
      , g_lookup_stamp_tab( '4' ).description          -- ヘッダ用記号４摘要
      , to_char(g_target_tab( in_i ).payment_date,'YYYY/MM/DD')
                                                       -- 支払年月日
      , g_target_tab( in_i ).bill_no                   -- 請求書No.
      , g_target_tab( in_i ).base_code                 -- 拠点コード
      , g_target_tab( in_i ).base_name                 -- 拠点名
      , g_target_tab( in_i ).cust_code                 -- 顧客コード
      , g_target_tab( in_i ).cust_name                 -- 顧客名称
      , g_target_tab( in_i ).deduction_chain_code      -- 控除用チェーンコード
      , g_target_tab( in_i ).deduction_chain_name      -- 控除用チェーン名
      , to_char(g_target_tab( in_i ).selling_date,'YYYY/MM/DD')
                                                       -- 売上対象年月
      , g_target_tab( in_i ).item_code                 -- 品目コード
      , g_target_tab( in_i ).item_name                 -- 品目名称
      , g_target_tab( in_i ).expansion_sales_type      -- 拡売区分
      , g_target_tab( in_i ).demand_qty                -- 請求数量
      , g_target_tab( in_i ).demand_unit_price         -- 請求単価
      , g_target_tab( in_i ).difference_amt            -- 端数調整
      , g_target_tab( in_i ).demand_amt                -- 請求金額
      , g_target_tab( in_i ).demand_unit_type          -- 請求単位
      , g_target_tab( in_i ).supplier_code             -- 仕入先コード
      , g_target_tab( in_i ).supplier_name             -- 仕入先名
      , g_target_tab( in_i ).bank_name                 -- 銀行名
      , g_target_tab( in_i ).bank_branch_name          -- 支店名
      , g_target_tab( in_i ).bank_account_type         -- 口座種別
      , g_target_tab( in_i ).bank_account_num          -- 口座番号
      , g_target_tab( in_i ).tax_rate                  -- 税率
      , lv_tax                                         -- 税
      , lv_stamp                                       -- 印
      , gn_demand_en_3                                 -- 建値
      , gn_shop_pay_en_3                               -- 店納(円)
      , ln_normal_shop_pay_en_4                        -- 通常店納
      , ln_just_shop_pay_en_4                          -- 特売店納
      , ln_net_selling_price                           -- NET価格
      , ln_accrued_en_3                                -- 通常
      , ln_accrued_en_3_c                              -- 通常_チェック
      , ln_accrued_en_4_1                              -- 拡売1
      , ln_accrued_en_4_1_c                            -- 拡売1_チェック
      , ln_accrued_en_4_2                              -- 拡売2
      , ln_accrued_en_4_2_c                            -- 拡売2_チェック
      , ln_accrued_en_4_3                              -- 拡売3
      , ln_accrued_en_4_3_c                            -- 拡売3_チェック
      , ln_accrued_en_4_4                              -- 拡売4
      , ln_accrued_en_4_4_c                            -- 拡売4_チェック
      , ln_accrued_en_4_5                              -- 拡売5
      , ln_accrued_en_4_5_c                            -- 拡売5_チェック
      , ln_accrued_en_4_6                              -- 拡売6
      , ln_accrued_en_4_6_c                           -- 拡売6_チェック
      , NULL                                           -- 0件メッセージ
      , cn_created_by                                  -- 作成者
      , SYSDATE                                        -- 作成日
      , cn_last_updated_by                             -- 最終更新者
      , SYSDATE                                        -- 最終更新日
      , cn_last_update_login                           -- 最終更新ログイン
      , cn_request_id                                  -- 要求ID
      , cn_program_application_id                      -- コンカレント・プログラム・アプリケーションID
      , cn_program_id                                  -- コンカレント・プログラムID
      , SYSDATE                                        -- プログラム更新日
      );
    ELSE
      -- ===============================================
      -- 対象件数0件時ワークテーブルデータ登録
      -- ===============================================
      INSERT INTO xxcok_wholesale_pay_check_list(
        p_payment_date                                 -- 支払年月日(入力パラメータ)
      , p_selling_date                                 -- 売上対象年月日(入力パラメータ)
      , p_base_code                                    -- 拠点コード(入力パラメータ)
      , p_vendor_code                                  -- 仕入先コード(入力パラメータ)
      , p_bill_no                                      -- 請求書番号(入力パラメータ)
      , p_deduction_chain_code                         -- 控除用チェーン(入力パラメータ)
       , no_data_message                               -- 0件メッセージ
      , created_by                                     -- 作成者
      , creation_date                                  -- 作成日
      , last_updated_by                                -- 最終更新者
      , last_update_date                               -- 最終更新日
      , last_update_login                              -- 最終更新ログイン
      , request_id                                     -- 要求ID
      , program_application_id                         -- コンカレント・プログラム・アプリケーションID
      , program_id                                     -- コンカレント・プログラムID
      , program_update_date                            -- プログラム更新日
      ) VALUES (
        iv_payment_date                                -- 支払年月日(入力パラメータ)
      , iv_selling_date                                -- 売上対象年月(入力パラメータ)
      , iv_base_code                                   -- 拠点コード(入力パラメータ)
      , iv_wholesale_vendor_code                       -- 仕入先コード(入力パラメータ)
      , iv_bill_no                                     -- 請求書番号(入力パラメータ)
      , iv_chain_code                                  -- 控除用チェーン(入力パラメータ)
      , gv_no_data_msg                                 -- 0件メッセージ
      , cn_created_by                                  -- 作成者
      , SYSDATE                                        -- 作成日
      , cn_last_updated_by                             -- 最終更新者
      , SYSDATE                                        -- 最終更新日
      , cn_last_update_login                           -- 最終更新ログイン
      , cn_request_id                                  -- 要求ID
      , cn_program_application_id                      -- コンカレント・プログラム・アプリケーションID
      , cn_program_id                                  -- コンカレント・プログラムID
      , SYSDATE                                        -- プログラム更新日
      );
    END IF;
  EXCEPTION
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END ins_wholesale_pay;
--
  /**********************************************************************************
   * Procedure Name   : get_target_data
   * Description      : 対象データ取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_target_data(
    ov_errbuf                OUT VARCHAR2  -- エラー・メッセージ
  , ov_retcode               OUT VARCHAR2  -- リターン・コード
  , ov_errmsg                OUT VARCHAR2  -- ユーザー・エラー・メッセージ
  , iv_payment_date          IN  VARCHAR2  -- 支払年月日
  , iv_selling_date          IN  VARCHAR2  -- 売上対象年月日
  , iv_base_code             IN  VARCHAR2  -- 拠点コード
  , iv_wholesale_vendor_code IN  VARCHAR2  -- 仕入先コード
  , iv_bill_no               IN  VARCHAR2  -- 請求書番号
  , iv_chain_code            IN  VARCHAR2  -- 控除用チェーンコード
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name  CONSTANT VARCHAR2(20) := 'get_target_data';  -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf         VARCHAR2(5000)  DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode        VARCHAR2(1)     DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg         VARCHAR2(5000)  DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    lv_outmsg         VARCHAR2(5000)  DEFAULT NULL;              -- 出力用メッセージ
    lv_no_condition   VARCHAR2(1)     DEFAULT NULL;              -- 控除マスタなし
    lb_retcode        BOOLEAN         DEFAULT TRUE;              -- メッセージ出力関数戻り値
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- カーソル
    -- ===============================================
    OPEN  g_target_cur(
      iv_payment_date          -- 支払年月日
    , iv_selling_date          -- 売上対象年月日
    , iv_base_code             -- 拠点コード
    , iv_wholesale_vendor_code -- 仕入先コード
    , iv_bill_no               -- 請求書番号
    , iv_chain_code            -- 控除用チェーンコード
    );
    FETCH g_target_cur BULK COLLECT INTO g_target_tab;
    CLOSE g_target_cur;
    -- ===============================================
    -- 対象件数取得
    -- ===============================================
    gn_target_cnt := g_target_tab.COUNT;
    IF ( gn_target_cnt = 0 ) THEN
      -- ===============================================
      -- 対象データなしメッセージ取得
      -- ===============================================
      gv_no_data_msg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_00001
                        );
      -- ===============================================
      -- ワークテーブルデータ登録(A-4)
      -- ===============================================
      ins_wholesale_pay(
          ov_errbuf                =>  lv_errbuf                -- エラーバッファ
        , ov_retcode               =>  lv_retcode               -- リターンコード
        , ov_errmsg                =>  lv_errmsg                -- エラーメッセージ
        , iv_payment_date          =>  iv_payment_date          -- 支払年月日
        , iv_selling_date          =>  iv_selling_date          -- 売上対象年月日
        , iv_base_code             =>  iv_base_code             -- 拠点コード
        , iv_wholesale_vendor_code =>  iv_wholesale_vendor_code -- 仕入先コード
        , iv_bill_no               =>  iv_bill_no               -- 請求書番号
        , iv_chain_code            =>  iv_chain_code            -- 控除用チェーンコード
        , in_i                     =>  cn_number_0              -- LOOPカウンタ
        , iv_no_condition          =>  lv_no_condition          -- 控除マスタなし
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    ELSE
      <<main_loop>>
      FOR i IN g_target_tab.FIRST .. g_target_tab.LAST LOOP
        -- ===============================================
        -- 控除マスタ情報取得(A-3)
        -- ===============================================
        BEGIN
          SELECT   SUM(ch1.demand_en_3)                                                                                     demand_en_3                 --請求(円)
                  ,SUM(ch1.shop_pay_en_3)                                                                                   shop_pay_en_3               --店納(円)
                  ,SUM(ch1.accrued_en_3)                                                                                    accrued_en_3                --未収計３(円)
                  ,SUM(ch1.normal_shop_pay_en_4_1)                                                                          normal_shop_pay_en_4_1      --通常店納(円)_1
                  ,SUM(ch1.normal_shop_pay_en_4_2)                                                                          normal_shop_pay_en_4_2      --通常店納(円)_2
                  ,SUM(ch1.normal_shop_pay_en_4_3)                                                                          normal_shop_pay_en_4_3      --通常店納(円)_3
                  ,SUM(ch1.normal_shop_pay_en_4_4)                                                                          normal_shop_pay_en_4_4      --通常店納(円)_4
                  ,SUM(ch1.normal_shop_pay_en_4_5)                                                                          normal_shop_pay_en_4_5      --通常店納(円)_5
                  ,SUM(ch1.normal_shop_pay_en_4_6)                                                                          normal_shop_pay_en_4_6      --通常店納(円)_6
                  ,SUM(ch1.just_shop_pay_en_4_1)                                                                            just_shop_pay_en_4_1        --今回店納(円)_1
                  ,SUM(ch1.just_shop_pay_en_4_2)                                                                            just_shop_pay_en_4_2        --今回店納(円)_2
                  ,SUM(ch1.just_shop_pay_en_4_3)                                                                            just_shop_pay_en_4_3        --今回店納(円)_3
                  ,SUM(ch1.just_shop_pay_en_4_4)                                                                            just_shop_pay_en_4_4        --今回店納(円)_4
                  ,SUM(ch1.just_shop_pay_en_4_5)                                                                            just_shop_pay_en_4_5        --今回店納(円)_5
                  ,SUM(ch1.just_shop_pay_en_4_6)                                                                            just_shop_pay_en_4_6        --今回店納(円)_6
                  ,SUM(ch1.just_condition_en_4_1)                                                                           just_condition_en_4_1       --今回条件(円)_1
                  ,SUM(ch1.just_condition_en_4_2)                                                                           just_condition_en_4_2       --今回条件(円)_2
                  ,SUM(ch1.just_condition_en_4_3)                                                                           just_condition_en_4_3       --今回条件(円)_3
                  ,SUM(ch1.just_condition_en_4_4)                                                                           just_condition_en_4_4       --今回条件(円)_4
                  ,SUM(ch1.just_condition_en_4_5)                                                                           just_condition_en_4_5       --今回条件(円)_5
                  ,SUM(ch1.just_condition_en_4_6)                                                                           just_condition_en_4_6       --今回条件(円)_6
                  ,SUM(ch1.accrued_en_4_1)                                                                                  accrued_en_4_1              --未収計４(円)_1
                  ,SUM(ch1.dedu_est_kbn_1)                                                                                  dedu_est_kbn_1              --未収計４(円)_1_控除見積区分
                  ,SUM(ch1.accrued_en_4_2)                                                                                  accrued_en_4_2              --未収計４(円)_2
                  ,SUM(ch1.dedu_est_kbn_2)                                                                                  dedu_est_kbn_2              --未収計４(円)_2_控除見積区分
                  ,SUM(ch1.accrued_en_4_3)                                                                                  accrued_en_4_3              --未収計４(円)_3
                  ,SUM(ch1.dedu_est_kbn_3)                                                                                  dedu_est_kbn_3              --未収計４(円)_3_控除見積区分
                  ,SUM(ch1.accrued_en_4_4)                                                                                  accrued_en_4_4              --未収計４(円)_4
                  ,SUM(ch1.dedu_est_kbn_4)                                                                                  dedu_est_kbn_4              --未収計４(円)_4_控除見積区分
                  ,SUM(ch1.accrued_en_4_5)                                                                                  accrued_en_4_5              --未収計４(円)_5
                  ,SUM(ch1.dedu_est_kbn_5)                                                                                  dedu_est_kbn_5              --未収計４(円)_5_控除見積区分
                  ,SUM(ch1.accrued_en_4_6)                                                                                  accrued_en_4_6              --未収計４(円)_6
                  ,SUM(ch1.dedu_est_kbn_6)                                                                                  dedu_est_kbn_6              --未収計４(円)_6_控除見積区分
          INTO
                   gn_demand_en_3
                  ,gn_shop_pay_en_3
                  ,gn_accrued_en_3
                  ,gn_normal_shop_pay_en_4_1
                  ,gn_normal_shop_pay_en_4_2
                  ,gn_normal_shop_pay_en_4_3
                  ,gn_normal_shop_pay_en_4_4
                  ,gn_normal_shop_pay_en_4_5
                  ,gn_normal_shop_pay_en_4_6
                  ,gn_just_shop_pay_en_4_1
                  ,gn_just_shop_pay_en_4_2
                  ,gn_just_shop_pay_en_4_3
                  ,gn_just_shop_pay_en_4_4
                  ,gn_just_shop_pay_en_4_5
                  ,gn_just_shop_pay_en_4_6
                  ,gn_just_condition_en_4_1
                  ,gn_just_condition_en_4_2
                  ,gn_just_condition_en_4_3
                  ,gn_just_condition_en_4_4
                  ,gn_just_condition_en_4_5
                  ,gn_just_condition_en_4_6
                  ,gn_accrued_en_4_1
                  ,gn_dedu_est_kbn_1
                  ,gn_accrued_en_4_2
                  ,gn_dedu_est_kbn_2
                  ,gn_accrued_en_4_3
                  ,gn_dedu_est_kbn_3
                  ,gn_accrued_en_4_4
                  ,gn_dedu_est_kbn_4
                  ,gn_accrued_en_4_5
                  ,gn_dedu_est_kbn_5
                  ,gn_accrued_en_4_6
                  ,gn_dedu_est_kbn_6
          FROM
                  (SELECT  ROW_NUMBER() OVER(PARTITION BY ch2.dedu_type ORDER BY ch2.accrued_en_4 desc)                     rownumber                   --拡売単価順序
                          ,ch2.dedu_type                                                                                    dedu_type                   --控除タイプ
                          ,CASE ch2.dedu_type
                             WHEN '030' THEN ch2.demand_en_3
                             ELSE            NULL
                           END                                                                                              demand_en_3                 --請求(円)
                          ,CASE ch2.dedu_type
                             WHEN '030' THEN ch2.shop_pay_en_3
                             ELSE            NULL
                           END                                                                                              shop_pay_en_3               --店納(円)
                          ,CASE ch2.dedu_type
                             WHEN '030' THEN ch2.accrued_en_3
                             ELSE            NULL
                           END                                                                                              accrued_en_3                --未収計３(円)
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0401' THEN ch2.normal_shop_pay_en_4
                            ELSE             NULL
                           END                                                                                              normal_shop_pay_en_4_1      --通常店納(円)_1
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0402' THEN ch2.normal_shop_pay_en_4
                            ELSE             NULL
                           END                                                                                              normal_shop_pay_en_4_2      --通常店納(円)_2
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0403' THEN ch2.normal_shop_pay_en_4
                            ELSE             NULL
                           END                                                                                              normal_shop_pay_en_4_3      --通常店納(円)_3
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0404' THEN ch2.normal_shop_pay_en_4
                            ELSE             NULL
                           END                                                                                              normal_shop_pay_en_4_4      --通常店納(円)_4
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0405' THEN ch2.normal_shop_pay_en_4
                            ELSE             NULL
                           END                                                                                              normal_shop_pay_en_4_5      --通常店納(円)_5
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0406' THEN ch2.normal_shop_pay_en_4
                            ELSE             NULL
                           END                                                                                              normal_shop_pay_en_4_6      --通常店納(円)_6
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0401' THEN ch2.just_shop_pay_en_4
                            ELSE             NULL
                           END                                                                                              just_shop_pay_en_4_1        --今回店納(円)_1
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0402' THEN ch2.just_shop_pay_en_4
                            ELSE             NULL
                           END                                                                                              just_shop_pay_en_4_2        --今回店納(円)_2
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0403' THEN ch2.just_shop_pay_en_4
                            ELSE             NULL
                           END                                                                                              just_shop_pay_en_4_3        --今回店納(円)_3
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0404' THEN ch2.just_shop_pay_en_4
                            ELSE             NULL
                           END                                                                                              just_shop_pay_en_4_4        --今回店納(円)_4
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0405' THEN ch2.just_shop_pay_en_4
                            ELSE             NULL
                           END                                                                                              just_shop_pay_en_4_5        --今回店納(円)_5
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0406' THEN ch2.just_shop_pay_en_4
                            ELSE             NULL
                           END                                                                                              just_shop_pay_en_4_6        --今回店納(円)_6
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0401' THEN ch2.just_condition_en_4
                            ELSE             NULL
                           END                                                                                              just_condition_en_4_1       --今回条件(円)_1
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0402' THEN ch2.just_condition_en_4
                            ELSE             NULL
                           END                                                                                              just_condition_en_4_2       --今回条件(円)_2
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0403' THEN ch2.just_condition_en_4
                            ELSE             NULL
                           END                                                                                              just_condition_en_4_3       --今回条件(円)_3
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0404' THEN ch2.just_condition_en_4
                            ELSE             NULL
                           END                                                                                              just_condition_en_4_4       --今回条件(円)_4
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0405' THEN ch2.just_condition_en_4
                            ELSE             NULL
                           END                                                                                              just_condition_en_4_5       --今回条件(円)_5
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0406' THEN ch2.just_condition_en_4
                            ELSE             NULL
                           END                                                                                              just_condition_en_4_6       --今回条件(円)_6
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0401' THEN ch2.accrued_en_4
                            ELSE             NULL
                           END                                                                                              accrued_en_4_1              --未収計４(円)_1
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0401' THEN ch2.dedu_est_kbn
                            ELSE             NULL
                           END                                                                                              dedu_est_kbn_1              --控除見積区分_1
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0402' THEN ch2.accrued_en_4
                            ELSE             NULL
                           END                                                                                              accrued_en_4_2              --未収計４(円)_2
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0402' THEN ch2.dedu_est_kbn
                            ELSE             NULL
                           END                                                                                              dedu_est_kbn_2              --控除見積区分_2
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0403' THEN ch2.accrued_en_4
                            ELSE             NULL
                           END                                                                                              accrued_en_4_3              --未収計４(円)_3
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0403' THEN ch2.dedu_est_kbn
                            ELSE             NULL
                           END                                                                                              dedu_est_kbn_3              --控除見積区分_3
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0404' THEN ch2.accrued_en_4
                            ELSE             NULL
                           END                                                                                              accrued_en_4_4              --未収計４(円)_4
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0404' THEN ch2.dedu_est_kbn
                            ELSE             NULL
                           END                                                                                              dedu_est_kbn_4              --控除見積区分_4
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0405' THEN ch2.accrued_en_4
                            ELSE             NULL
                           END                                                                                              accrued_en_4_5              --未収計４(円)_5
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0405' THEN ch2.dedu_est_kbn
                            ELSE             NULL
                           END                                                                                              dedu_est_kbn_5              --控除見積区分_5
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0406' THEN ch2.accrued_en_4
                            ELSE             NULL
                           END                                                                                              accrued_en_4_6              --未収計４(円)_6
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0406' THEN ch2.dedu_est_kbn
                            ELSE             NULL
                           END                                                                                              dedu_est_kbn_6              --控除見積区分_6
                   FROM 
                                  (SELECT /*+ INDEX(xch XXCOK_CONDITION_HEADER_N07)*/
                                          xch.condition_id                                                                  condition_id                --控除条件ID
                                         ,xch.condition_no                                                                  condition_no                --控除番号
                                         ,xch.enabled_flag_h                                                                enabled_flag_h              --ヘッダ有効フラグ
                                         ,xch.corp_code                                                                     corp_code                   --企業コード
                                         ,xch.deduction_chain_code                                                          deduction_chain_code        --控除用チェーンコード
                                         ,xch.customer_code                                                                 customer_code               --顧客コード
                                         ,xch.data_type                                                                     data_type                   --データ種類
                                         ,xch.start_date_active                                                             start_date_active           --開始日
                                         ,xch.end_date_active                                                               end_date_active             --終了日
                                         ,xcl.condition_line_id                                                             condition_line_id           --控除詳細ID
                                         ,xcl.enabled_flag_l                                                                enabled_flag_l              --明細有効フラグ
                                         ,xcl.item_code                                                                     item_code                   --品目コード
                                         ,xcl.demand_en_3                                                                   demand_en_3                 --請求(円)
                                         ,xcl.shop_pay_en_3                                                                 shop_pay_en_3               --店納(円)
                                         ,xcl.compensation_en_3                                                             compensation_en_3           --補填(円)
                                         ,xcl.wholesale_margin_en_3                                                         wholesale_margin_en_3       --問屋マージン(円)
                                         ,xcl.wholesale_margin_per_3                                                        wholesale_margin_per_3      --問屋マージン(％)
                                         ,xcl.accrued_en_3                                                                  accrued_en_3                --未収計３(円)
                                         ,xcl.normal_shop_pay_en_4                                                          normal_shop_pay_en_4        --通常店納(円)
                                         ,xcl.just_shop_pay_en_4                                                            just_shop_pay_en_4          --今回店納(円)
                                         ,xcl.just_condition_en_4                                                           just_condition_en_4         --今回条件(円)
                                         ,xcl.wholesale_adj_margin_en_4                                                     wholesale_adj_margin_en_4   --問屋マージン修正(円)
                                         ,xcl.wholesale_adj_margin_per_4                                                    wholesale_adj_margin_per_4  --問屋マージン修正(％)
                                         ,xcl.accrued_en_4                                                                  accrued_en_4                --未収計４(円)
                                         ,flv.attribute2                                                                    dedu_type                   --控除タイプ
                                         ,xca.intro_chain_code2                                                             intro_chain_code2           --控除用チェーンコード（顧客指定）
                                         ,0                                                                                 dedu_est_kbn                --控除見積区分
                                   FROM   apps.xxcok_condition_header xch
                                         ,apps.xxcok_condition_lines xcl
                                         ,apps.fnd_lookup_values flv
                                         ,apps.xxcmm_cust_accounts xca
                                   WHERE  xch.condition_id          = xcl.condition_id
                                   AND    xch.start_date_active     <= g_target_tab( i ).selling_date
                                   AND    xch.end_date_active       >= ADD_MONTHS(g_target_tab( i ).selling_date,-1) + 1
                                   AND    xch.enabled_flag_h        = 'Y'
                                   AND    xcl.item_code             = g_target_tab( i ).item_code                                                       --A-2で取得した「品目コード」
                                   AND    xcl.enabled_flag_l        = 'Y'
                                   AND    flv.lookup_type           = 'XXCOK1_DEDUCTION_DATA_TYPE'
                                   AND    flv.language              = 'JA'
                                   AND    flv.lookup_code           = xch.data_type
                                   AND    flv.enabled_flag          = 'Y'
                                   AND    gd_process_date BETWEEn nvl(flv.start_date_active, gd_process_date)
                                                                             AND     nvl(flv.end_date_active, gd_process_date)                          -- A-1で取得した業務日付
                                   AND    flv.attribute2           IN ('030','040')
                                   AND    xca.customer_code(+)      = xch.customer_code
                                   AND    xch.deduction_chain_code || xca.intro_chain_code2 = g_target_tab( i ).deduction_chain_code                    --A-2で取得した控除用チェーンコード
                                   UNION ALL
                                   SELECT /*+ INDEX(xch XXCOK_CONDITION_HEADER_EST_N07)*/
                                          xch.condition_id                                                                  condition_id                --控除条件ID
                                         ,xch.condition_no                                                                  condition_no                --控除番号
                                         ,xch.enabled_flag_h                                                                enabled_flag_h              --ヘッダ有効フラグ
                                         ,xch.corp_code                                                                     corp_code                   --企業コード
                                         ,xch.deduction_chain_code                                                          deduction_chain_code        --控除用チェーンコード
                                         ,xch.customer_code                                                                 customer_code               --顧客コード
                                         ,xch.data_type                                                                     data_type                   --データ種類
                                         ,xch.start_date_active                                                             start_date_active           --開始日
                                         ,xch.end_date_active                                                               end_date_active             --終了日
                                         ,xcl.condition_line_id                                                             condition_line_id           --控除詳細ID
                                         ,xcl.enabled_flag_l                                                                enabled_flag_l              --明細有効フラグ
                                         ,xcl.item_code                                                                     item_code                   --品目コード
                                         ,xcl.demand_en_3                                                                   demand_en_3                 --請求(円)
                                         ,xcl.shop_pay_en_3                                                                 shop_pay_en_3               --店納(円)
                                         ,xcl.compensation_en_3                                                             compensation_en_3           --補填(円)
                                         ,xcl.wholesale_margin_en_3                                                         wholesale_margin_en_3       --問屋マージン(円)
                                         ,xcl.wholesale_margin_per_3                                                        wholesale_margin_per_3      --問屋マージン(％)
                                         ,xcl.accrued_en_3                                                                  accrued_en_3                --未収計３(円)
                                         ,xcl.normal_shop_pay_en_4                                                          normal_shop_pay_en_4        --通常店納(円)
                                         ,xcl.just_shop_pay_en_4                                                            just_shop_pay_en_4          --今回店納(円)
                                         ,xcl.just_condition_en_4                                                           just_condition_en_4         --今回条件(円)
                                         ,xcl.wholesale_adj_margin_en_4                                                     wholesale_adj_margin_en_4   --問屋マージン修正(円)
                                         ,xcl.wholesale_adj_margin_per_4                                                    wholesale_adj_margin_per_4  --問屋マージン修正(％)
                                         ,xcl.accrued_en_4                                                                  accrued_en_4                --未収計４(円)
                                         ,flv.attribute2                                                                    dedu_type                   --控除タイプ
                                         ,xca.intro_chain_code2                                                             intro_chain_code2           --控除用チェーンコード（顧客指定）
                                         ,1                                                                                 dedu_est_kbn                --控除見積区分
                                   FROM   apps.xxcok_condition_header_est xch
                                         ,apps.xxcok_condition_lines_est xcl
                                         ,apps.fnd_lookup_values flv
                                         ,apps.xxcmm_cust_accounts xca
                                   WHERE  xch.condition_id          = xcl.condition_id
                                   AND    xch.start_date_active     <= g_target_tab( i ).selling_date
                                   AND    xch.end_date_active       >= ADD_MONTHS(g_target_tab( i ).selling_date,-1) + 1
                                   AND    xch.enabled_flag_h        = 'Y'
                                   AND    xcl.item_code             = g_target_tab( i ).item_code                                                       --A-2で取得した「品目コード」
                                   AND    xcl.enabled_flag_l        = 'Y'
                                   AND    flv.lookup_type           = 'XXCOK1_DEDUCTION_DATA_TYPE_EST'
                                   AND    flv.language              = 'JA'
                                   AND    flv.lookup_code           = xch.data_type
                                   AND    flv.enabled_flag          = 'Y'
                                   AND    gd_process_date BETWEEN nvl(flv.start_date_active, gd_process_date)
                                                                             AND     nvl(flv.end_date_active, gd_process_date)                          -- A-1で取得した業務日付
                                   AND    flv.attribute2           IN ('030','040')
                                   AND    xca.customer_code(+)      = xch.customer_code
                                   AND    xch.deduction_chain_code || xca.intro_chain_code2 = g_target_tab( i ).deduction_chain_code                    --A-2で取得した控除用チェーンコード
                                  )ch2
                  )ch1  ;
            lv_no_condition := 'N';
        EXCEPTION
          WHEN no_data_found THEN
            lv_no_condition := 'Y';
        END;
--
        -- ===============================================
        -- ワークテーブルデータ登録(A-4)
        -- ===============================================
        ins_wholesale_pay(
          ov_errbuf                =>  lv_errbuf                -- エラーバッファ
        , ov_retcode               =>  lv_retcode               -- リターンコード
        , ov_errmsg                =>  lv_errmsg                -- エラーメッセージ
        , iv_payment_date          =>  iv_payment_date          -- 支払年月日
        , iv_selling_date          =>  iv_selling_date          -- 売上対象年月日
        , iv_base_code             =>  iv_base_code             -- 拠点コード
        , iv_wholesale_vendor_code =>  iv_wholesale_vendor_code -- 仕入先コード
        , iv_bill_no               =>  iv_bill_no               -- 請求書番号
        , iv_chain_code            =>  iv_chain_code            -- 控除用チェーンコード
        , in_i                     =>  i                        -- LOOPカウンタ
        , iv_no_condition          =>  lv_no_condition          -- 控除マスタなし
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      END LOOP main_loop;
    END IF;
  EXCEPTION
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数例外 ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END get_target_data;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf                OUT VARCHAR2  -- エラー・メッセージ
  , ov_retcode               OUT VARCHAR2  -- リターン・コード
  , ov_errmsg                OUT VARCHAR2  -- ユーザー・エラー・メッセージ
  , iv_payment_date          IN  VARCHAR2  -- 支払年月日
  , iv_selling_date          IN  VARCHAR2  -- 売上対象年月日
  , iv_base_code             IN  VARCHAR2  -- 拠点コード
  , iv_wholesale_vendor_code IN  VARCHAR2  -- 仕入先コード
  , iv_bill_no               IN  VARCHAR2  -- 請求書番号
  , iv_chain_code            IN  VARCHAR2  -- 控除用チェーンコード
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name      CONSTANT VARCHAR2(10) := 'init';     -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode  VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    lv_outmsg   VARCHAR2(5000) DEFAULT NULL;              -- 出力用メッセージ
    ld_chk_date DATE           DEFAULT NULL;              -- チェック用変数
    lb_retcode  BOOLEAN        DEFAULT TRUE;              -- メッセージ出力関数戻り値
    ln_cnt      NUMBER;                                   -- 重複件数カウンタ
    -- ===============================================
    -- ローカル例外
    -- ===============================================
    --*** 初期処理エラー ***
    init_fail_expt             EXCEPTION;
    dup_tax_rate_expt          EXCEPTION;
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- プログラム入力項目を出力
    -- ===============================================
    -- 支払年月日
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_short_name
                  , iv_name         => cv_msg_code_10829
                  , iv_token_name1  => cv_token_pay_date
                  , iv_token_value1 => iv_payment_date
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG
                  , iv_message  => lv_outmsg
                  , in_new_line => cn_number_0
                  );
    -- 売上対象年月日
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_short_name
                  , iv_name         => cv_msg_code_10830
                  , iv_token_name1  => cv_token_target_date
                  , iv_token_value1 => iv_selling_date
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG
                  , iv_message  => lv_outmsg
                  , in_new_line => cn_number_0
                  );
    -- 拠点コード
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_short_name
                  , iv_name         => cv_msg_code_10831
                  , iv_token_name1  => cv_token_base_code
                  , iv_token_value1 => iv_base_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG
                  , iv_message  => lv_outmsg
                  , in_new_line => cn_number_0
                  );
    -- 仕入先コード
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_short_name
                  , iv_name         => cv_msg_code_10832
                  , iv_token_name1  => cv_token_supplier_code
                  , iv_token_value1 => iv_wholesale_vendor_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG
                  , iv_message  => lv_outmsg
                  , in_new_line => cn_number_0
                  );
    -- 請求書番号
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_short_name
                  , iv_name         => cv_msg_code_10833
                  , iv_token_name1  => cv_token_bill_no
                  , iv_token_value1 => iv_bill_no
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG
                  , iv_message  => lv_outmsg
                  , in_new_line => cn_number_0
                  );
    -- 控除用チェーンコード
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_short_name
                  , iv_name         => cv_msg_code_10834
                  , iv_token_name1  => cv_token_chain_code
                  , iv_token_value1 => iv_chain_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG
                  , iv_message  => lv_outmsg
                  , in_new_line => cn_number_0
                  );
    -- ===============================================
    -- プロファイル取得(在庫組織コード_営業組織)
    -- ===============================================
    gv_org_code_sales := FND_PROFILE.VALUE( cv_prof_org_code_sales );
    IF ( gv_org_code_sales IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile
                    , iv_token_value1 => cv_prof_org_code_sales
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- プロファイル取得(営業単位ID)
    -- ===============================================
    gn_org_id := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_org_id ) );
    IF ( gn_org_id IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile
                    , iv_token_value1 => cv_prof_org_id
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- 在庫組織ID取得
    -- ===============================================
    gn_org_id_sales := xxcoi_common_pkg.get_organization_id( gv_org_code_sales );
    IF ( gn_org_id_sales IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00013
                    , iv_token_name1  => cv_token_org_code
                    , iv_token_value1 => gv_org_code_sales
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- 業務処理日付取得
    -- ===============================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00028
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- クイックコード取得(問屋未収単価チェックリスト記号)
    -- ===============================================
    <<lookup_stamp_loop>>
    FOR lookup_stamp_rec IN lookup_stamp_cur LOOP
      g_lookup_stamp_tab( lookup_stamp_rec.lookup_code ).meaning     := lookup_stamp_rec.meaning;
      g_lookup_stamp_tab( lookup_stamp_rec.lookup_code ).description := lookup_stamp_rec.description;
      g_lookup_stamp_tab( lookup_stamp_rec.lookup_code ).tag         := lookup_stamp_rec.tag;
    END LOOP lookup_stamp_loop;
    IF ( g_lookup_stamp_tab.COUNT = 0 ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00015
                    , iv_token_name1  => cv_token_lookup_value_set
                    , iv_token_value1 => cv_lookup_tax_pay_check
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- 税率履歴の重複チェック
    -- ===============================================
    SELECT COUNT(1) AS cnt
    INTO   ln_cnt
    FROM   fnd_lookup_values  v1
          ,fnd_lookup_values  v2
    WHERE  v1.lookup_type             = cv_lookup_tax_code_his
    AND    v2.lookup_type             = cv_lookup_tax_code_his
    AND    v1.enabled_flag            = 'Y'
    AND    v2.enabled_flag            = 'Y'
    AND    ( ( v1.start_date_active  >= v2.start_date_active
    AND        v1.start_date_active  <= v2.end_date_active )
      OR     ( v1.end_date_active    >= v2.start_date_active
    AND        v1.end_date_active    <= v2.end_date_active ) )
    AND    v1.tag                     = v2.tag
    AND    v1.lookup_code            <> v2.lookup_code
    ;
    -- 重複データが1件でもあればエラー
    IF ( ln_cnt > 0 ) THEN
      RAISE dup_tax_rate_expt;
    END IF;
  EXCEPTION
    -- *** 初期処理エラー ***
    WHEN init_fail_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
      IF ( lookup_stamp_cur%ISOPEN ) THEN
        CLOSE lookup_stamp_cur;
      END IF;
    WHEN dup_tax_rate_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_10566
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
      IF ( lookup_stamp_cur%ISOPEN ) THEN
        CLOSE lookup_stamp_cur;
      END IF;
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf                OUT VARCHAR2  -- エラー・メッセージ
  , ov_retcode               OUT VARCHAR2  -- リターン・コード
  , ov_errmsg                OUT VARCHAR2  -- ユーザー・エラー・メッセージ
  , iv_payment_date          IN  VARCHAR2  -- 支払年月日
  , iv_selling_date          IN  VARCHAR2  -- 売上対象年月日
  , iv_base_code             IN  VARCHAR2  -- 拠点コード
  , iv_wholesale_vendor_code IN  VARCHAR2  -- 仕入先コード
  , iv_bill_no               IN  VARCHAR2  -- 請求書番号
  , iv_chain_code            IN  VARCHAR2  -- 控除用チェーンコード
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name   CONSTANT VARCHAR2(10) := 'submain';    -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- 初期処理(A-1)
    -- ===============================================
    init(
      ov_errbuf                => lv_errbuf                -- エラー・メッセージ
    , ov_retcode               => lv_retcode               -- リターン・コード
    , ov_errmsg                => lv_errmsg                -- ユーザー・エラー・メッセージ
    , iv_payment_date          => iv_payment_date          -- 支払年月日
    , iv_selling_date          => iv_selling_date          -- 売上対象年月日
    , iv_base_code             => iv_base_code             -- 拠点コード
    , iv_wholesale_vendor_code => iv_wholesale_vendor_code -- 仕入先コード
    , iv_bill_no               => iv_bill_no               -- 請求書番号
    , iv_chain_code            => iv_chain_code            -- 控除用チェーンコード
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- ===============================================
    -- 対象データ取得(A-2)・控除マスタ情報取得(A-3)・ワークテーブルデータ登録(A-4)
    -- ===============================================
    get_target_data(
      ov_errbuf                => lv_errbuf                -- エラー・メッセージ
    , ov_retcode               => lv_retcode               -- リターン・コード
    , ov_errmsg                => lv_errmsg                -- ユーザー・エラー・メッセージ
    , iv_payment_date          => iv_payment_date          -- 支払年月日
    , iv_selling_date          => iv_selling_date          -- 売上対象年月日
    , iv_base_code             => iv_base_code             -- 拠点コード
    , iv_wholesale_vendor_code => iv_wholesale_vendor_code -- 仕入先コード
    , iv_bill_no               => iv_bill_no               -- 請求書番号
    , iv_chain_code            => iv_chain_code            -- 控除用チェーンコード
  );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- ===============================================
    -- ワークテーブルデータ確定
    -- ===============================================
    COMMIT;
    -- ===============================================
    -- SVF起動(A-5)
    -- ===============================================
    start_svf(
      ov_errbuf   => lv_errbuf   -- エラー・メッセージ
    , ov_retcode  => lv_retcode  -- リターン・コード
    , ov_errmsg   => lv_errmsg   -- ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- ===============================================
    -- ワークテーブルデータ削除(A-6)
    -- ===============================================
    del_wholesale_pay(
      ov_errbuf   => lv_errbuf   -- エラー・メッセージ
    , ov_retcode  => lv_retcode  -- リターン・コード
    , ov_errmsg   => lv_errmsg   -- ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
  EXCEPTION
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
  PROCEDURE main(
    errbuf                   OUT VARCHAR2  -- エラー・メッセージ
  , retcode                  OUT VARCHAR2  -- リターン・コード
  , iv_payment_date          IN  VARCHAR2  -- 支払年月日
  , iv_selling_date          IN  VARCHAR2  -- 売上対象年月
  , iv_base_code             IN  VARCHAR2  -- 拠点コード
  , iv_wholesale_vendor_code IN  VARCHAR2  -- 仕入先コード
  , iv_bill_no               IN  VARCHAR2  -- 請求書番号
  , iv_chain_code            IN  VARCHAR2  -- 控除用チェーンコード
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name        CONSTANT VARCHAR2(10) := 'main';        -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf        VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode       VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg        VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    lv_outmsg        VARCHAR2(5000) DEFAULT NULL;              -- 出力用メッセージ
    lv_message_code  VARCHAR2(100)  DEFAULT NULL;              -- 終了メッセージコード
    lb_retcode       BOOLEAN        DEFAULT TRUE;              -- メッセージ出力関数戻り値
--
  BEGIN
    -- ===============================================
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    -- ===============================================
    xxccp_common_pkg.put_log_header(
      ov_retcode => lv_retcode
    , ov_errbuf  => lv_errbuf
    , ov_errmsg  => lv_errmsg
    , iv_which   => cv_which
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      ov_errbuf                => lv_errbuf                -- エラー・メッセージ
    , ov_retcode               => lv_retcode               -- リターン・コード
    , ov_errmsg                => lv_errmsg                -- ユーザー・エラー・メッセージ
    , iv_payment_date          => iv_payment_date          -- 支払年月日
    , iv_selling_date          => iv_selling_date          -- 売上対象年月
    , iv_base_code             => iv_base_code             -- 拠点コード
    , iv_wholesale_vendor_code => iv_wholesale_vendor_code -- 仕入先コード
    , iv_bill_no               => iv_bill_no               -- 請求書番号
    , iv_chain_code            => iv_chain_code            -- 控除用チェーンコード
    );
    -- ===============================================
    -- エラー出力
    -- ===============================================
    IF ( lv_retcode = cv_status_error ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG   -- 出力区分
                    , iv_message  => lv_errmsg      -- メッセージ
                    , in_new_line => cn_number_0    -- 改行
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errbuf
                    , in_new_line => cn_number_1
                    );
    END IF;
    -- ===============================================
    -- 対象件数出力
    -- ===============================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_appl_short_name
                  , iv_name         => cv_msg_code_90000
                  , iv_token_name1  => cv_token_count
                  , iv_token_value1 => TO_CHAR( gn_target_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG
                  , iv_message  => lv_outmsg
                  , in_new_line => cn_number_0
                  );
    -- ===============================================
    -- 成功件数出力(エラー発生の場合、成功件数:0件 エラー件数:1件  対象件数0件の場合、成功件数:0件)
    -- ===============================================
    IF ( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := cn_number_0;
      gn_error_cnt  := cn_number_1;
    ELSE
      IF ( gn_target_cnt = cn_number_0 ) THEN
        gn_normal_cnt := cn_number_0;
      END IF;
    END IF;
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_appl_short_name
                  , iv_name         => cv_msg_code_90001
                  , iv_token_name1  => cv_token_count
                  , iv_token_value1 => TO_CHAR( gn_normal_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG
                  , iv_message  => lv_outmsg
                  , in_new_line => cn_number_0
                  );
    -- ===============================================
    -- エラー件数出力
    -- ===============================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_appl_short_name
                  , iv_name         => cv_msg_code_90002
                  , iv_token_name1  => cv_token_count
                  , iv_token_value1 => TO_CHAR( gn_error_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG
                  , iv_message  => lv_outmsg
                  , in_new_line => cn_number_1
                  );
    -- ===============================================
    -- 処理終了メッセージ出力
    -- ===============================================
    IF ( lv_retcode    = cv_status_normal ) THEN
      lv_message_code := cv_msg_code_90004;
    ELSE
      lv_message_code := cv_msg_code_90006;
    END IF;
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_appl_short_name
                  , iv_name         => lv_message_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG
                  , iv_message  => lv_outmsg
                  , in_new_line => cn_number_0
                  );
    -- ===============================================
    -- ステータスセット
    -- ===============================================
    retcode := lv_retcode;
    -- ===============================================
    -- 終了ステータスエラー時、ロールバック
    -- ===============================================
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
  EXCEPTION
    -- *** 共通関数例外 ***
    WHEN global_api_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
END XXCOK024A40R;
/
