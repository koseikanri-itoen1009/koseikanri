CREATE OR REPLACE PACKAGE BODY XXCCP009A14C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCCP009A14C(body)
 * Description      : 請求先顧客情報CSV出力
 * MD.070           : 請求先顧客情報CSV出力 (MD070_IPO_CCP_009_A14)
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2015/03/26     1.0  SCSK H.Wajima   [E_本稼動_12936]新規作成
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
  cv_pkg_name        CONSTANT VARCHAR2(100)   := 'XXCCP009A14C'; -- パッケージ名
  cv_appl_short_name CONSTANT VARCHAR2(10)    := 'XXCCP';        -- アドオン：共通・IF領域
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
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf       OUT VARCHAR2,                               --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,                               --   リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2)                               --   ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'submain';           -- プログラム名
    cv_msg_no_parameter     CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90008';  -- パラメータなし
    cv_org_id               CONSTANT VARCHAR2(6)   := 'ORG_ID';            -- 営業単位ID
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
    ln_org_id               NUMBER;    -- ログインユーザの営業単位ID
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 請求先顧客ビュー情報取得
    CURSOR get_hz_cust_accounts_cur( in_org_id NUMBER )
      IS
        SELECT  NVL(chcar.cust_account_id,bcus.cust_account_id)    pay_customer_id,      -- 入金先顧客ID
                NVL(chca.account_number,bcus.customer_code)        pay_customer_number,  -- 入金先顧客コード
                NVL(chp.party_name,bcus.customer_name)             pay_customer_name,    -- 入金先顧客名
                bcus.cust_account_id                               cust_account_id,      -- 請求先顧客ID
                bcus.customer_code                                 bill_customer_code,   -- 請求先顧客コード
                bcus.customer_name                                 bill_customer_name    -- 請求先顧客名
        FROM    apps.hz_cust_acct_relate_all     chcar,     -- 顧客関連（入金先-請求先）
                apps.hz_cust_accounts            chca,      -- 顧客（入金先）
                apps.hz_parties                  chp,       -- パーティ（入金先）
                xxcmm.xxcmm_cust_accounts        cxca,      -- 顧客アドオン（入金先）
                (SELECT  lookup_code              receiv_code1,              -- 売掛コード1（請求先）
                         meaning                  receiv_code1_name          -- 売掛コード1（請求先）名
                 FROM    apps.fnd_lookup_values_vl
                 WHERE   lookup_type        =  'XXCMM_INVOICE_GRP_CODE'      -- 売掛コード1登録 参照タイプ
                 AND     enabled_flag       =  'Y'
                 AND     NVL(start_date_active,TO_DATE('19000101','YYYYMMDD'))  <= SYSDATE
                 AND     NVL(end_date_active,TO_DATE('22001231','YYYYMMDD'))    >= SYSDATE ) xigc, -- 売掛コード１
                (SELECT  flex_value,
                         description
                 FROM    apps.fnd_flex_values_vl ffv
                 WHERE   EXISTS
                         (SELECT  'X'
                          FROM    applsys.fnd_flex_value_sets
                          WHERE   flex_value_set_name = 'XX03_DEPARTMENT'
                          AND     flex_value_set_id   = ffv.flex_value_set_id)) cffvv,  --値セット値（所属部門）
                (
                 --請求先
                 SELECT  xhca.cust_account_id,        -- 請求先顧客ID
                         xhcp.cust_account_profile_id,
                         xhcas.cust_acct_site_id,
                         xhcsu.site_use_id,
                         xhca.party_id,
                         xhp.party_number,
                         xhcsu.attribute4          receiv_code1,             -- 売掛コード1（請求先）
                         xhca.account_number       customer_code,            -- 請求先顧客コード
                         xhp.party_name            customer_name,            -- 請求先顧客名
                         xhca.status               status,                   -- 顧客ステータス
                         xhca.customer_type        customer_type,            -- 顧客タイプ
                         xhca.customer_class_code  customer_class_code,      -- 顧客区分
                         xxca.bill_base_code       bill_base_code,           -- 請求拠点コード
                         xffvv.description         bill_base_name,           -- 請求拠点名
                         xxca.store_code           store_code,               -- 店舗コード
                         xxca.tax_div              tax_div,                  -- 消費税区分
                         xhcsu.tax_rounding_rule   tax_rounding_rule,        -- 税金－端数処理
                         xhcsu.attribute7          inv_prt_type,             -- 請求書出力形式
                         xhcp.cons_inv_flag        cons_inv_flag,            -- 一括請求書発行区分
                         xhcas.org_id              org_id                    -- 組織ID
                 FROM    apps.hz_cust_accounts        xhca,                       -- 顧客アカウント（請求先）
                         apps.hz_parties              xhp,                        -- パーティ（請求先）
                         apps.hz_cust_acct_sites_all  xhcas,                      -- 顧客サイト（請求先）
                         apps.hz_cust_site_uses_all   xhcsu,                      -- 顧客使用目的（請求先）
                         apps.hz_customer_profiles    xhcp,                       -- 顧客プロファイル（請求先）
                         xxcmm.xxcmm_cust_accounts    xxca,                       -- 顧客アドオン（請求先）
                         (SELECT flex_value,
                                 description
                          FROM   apps.fnd_flex_values_vl ffv
                          WHERE  EXISTS
                                 (SELECT  'X'
                                  FROM    applsys.fnd_flex_value_sets
                                  WHERE   flex_value_set_name = 'XX03_DEPARTMENT'
                                  AND     flex_value_set_id   = ffv.flex_value_set_id)) xffvv  -- 値セット値（所属部門）
                 WHERE   xhcas.org_id = in_org_id
                 AND     xhcsu.org_id = in_org_id
                 AND     xhca.party_id            = xhp.party_id
                 AND     xhca.customer_class_code = '14'
                 AND     xhca.cust_account_id     = xhcas.cust_account_id
                 AND     xhcas.bill_to_flag       IS NOT NULL
                 AND     xhcas.cust_acct_site_id  = xhcsu.cust_acct_site_id
                 AND     xhcsu.site_use_code      = 'BILL_TO'                 --使用目的
                 AND     xhcsu.primary_flag       = 'Y'
                 AND     xhcsu.status             = 'A'                       --ステータス
                 AND     xhca.cust_account_id     = xhcp.cust_account_id
                 AND     xhcsu.site_use_id       = xhcp.site_use_id
                 AND     xhca.cust_account_id     = xxca.customer_id(+)
                 AND     xxca.bill_base_code      = xffvv.flex_value(+)
                 AND     EXISTS
                         (SELECT   'X'
                          FROM     apps.hz_cust_acct_relate_all     hcar
                          WHERE    hcar.org_id = in_org_id
                          AND      hcar.attribute1  = '1'
                          AND      hcar.status      = 'A'
                          AND      hcar.cust_account_id = xhca.cust_account_id
                          )
                 AND     NOT EXISTS
                         (SELECT   'X'
                          FROM     apps.hz_cust_acct_relate_all  hcar
                          WHERE    hcar.org_id                   = in_org_id
                          AND      hcar.attribute1               = '1'
                          AND      hcar.status                   = 'A'
                          AND      hcar.customer_reciprocal_flag = 'Y'
                          AND      hcar.cust_account_id          = xhca.cust_account_id
                          )
               UNION ALL
                 -- 納品先 AND 請求先
                 SELECT  yhca.cust_account_id,                               -- 請求先顧客ID
                         yhcp.cust_account_profile_id,
                         yhcas.cust_acct_site_id,
                         yhcsu.site_use_id,
                         yhca.party_id,
                         yhp.party_number,
                         yhcsu.attribute4          receiv_code1,             -- 売掛コード1（請求先）
                         yhca.account_number       customer_code,            -- 請求先顧客コード
                         yhp.party_name            customer_name,            -- 請求先顧客名称
                         yhca.status               status,                   -- 顧客ステータス
                         yhca.customer_type        customer_type,            -- 顧客タイプ
                         yhca.customer_class_code  customer_class_code,      -- 顧客区分
                         yxca.bill_base_code       bill_base_code,           -- 請求拠点コード
                         yffvv.description         bill_base_name,           -- 請求拠点名
                         yxca.store_code           store_code,               -- 店舗コード
                         yxca.tax_div              tax_div,                  -- 消費税区分
                         yhcsu.tax_rounding_rule   tax_rounding_rule,        -- 税金－端数処理
                         yhcsu.attribute7          inv_prt_type,             -- 請求書出力形式
                         yhcp.cons_inv_flag        cons_inv_flag,            -- 一括請求書発行区分
                         yhcas.org_id              org_id                    -- 組織ID
                 FROM    apps.hz_cust_accounts        yhca,                    -- 顧客アカウント（請求先）
                         apps.hz_parties              yhp,                     -- パーティ（請求先）
                         apps.hz_cust_acct_sites_all  yhcas,                   -- 顧客サイト（請求先）
                         apps.hz_cust_site_uses_all   yhcsu,                   -- 顧客使用目的（請求先）
                         apps.hz_customer_profiles    yhcp,                    -- 顧客プロファイル（請求先）
                         xxcmm.xxcmm_cust_accounts     yxca,                   -- 顧客アドオン（請求先）
                         (SELECT  flex_value,
                                 description
                          FROM   apps.fnd_flex_values_vl ffv
                          WHERE  EXISTS
                                 (SELECT   'X'
                                  FROM     applsys.fnd_flex_value_sets
                                  WHERE    flex_value_set_name = 'XX03_DEPARTMENT'
                                  AND      flex_value_set_id = ffv.flex_value_set_id)) yffvv  -- 値セット値（所属部門）
                 WHERE   yhcas.org_id = in_org_id
                 AND     yhcsu.org_id = in_org_id
                 AND     yhca.party_id            = yhp.party_id
                 AND     yhca.customer_class_code = '10'
                 AND     yhca.cust_account_id     = yhcas.cust_account_id
                 AND     yhcas.bill_to_flag       IS NOT NULL
                 AND     yhcas.cust_acct_site_id  = yhcsu.cust_acct_site_id
                 AND     yhcsu.site_use_code      = 'BILL_TO'                 --使用目的
                 AND     yhcsu.primary_flag       = 'Y'
                 AND     yhcsu.status             = 'A'                       --ステータス
                 AND     yhca.cust_account_id     = yhcp.cust_account_id
                 AND     yhcsu.site_use_id        = yhcp.site_use_id
                 AND     yhca.cust_account_id     = yxca.customer_id(+)
                 AND     yxca.bill_base_code      = yffvv.flex_value(+)
                 AND     NOT EXISTS
                         (SELECT   'X'
                          FROM     apps.hz_cust_acct_relate_all     hcar
                          WHERE    hcar.org_id = in_org_id
                          AND      hcar.attribute1  = '1'
                          AND      hcar.status      = 'A'
                          AND      hcar.related_cust_account_id = yhca.cust_account_id
                         )
                ) bcus
        WHERE   chcar.related_cust_account_id(+) = bcus.cust_account_id
        AND     chcar.org_id(+)                  = bcus.org_id
        AND     chcar.cust_account_id            = chca.cust_account_id(+)
        AND     chca.party_id                    = chp.party_id(+)
        AND     chca.cust_account_id             = cxca.customer_id(+)
        AND     cxca.receiv_base_code            = cffvv.flex_value(+)
        AND     chcar.status(+)                  = 'A'
        AND     bcus.receiv_code1                = xigc.receiv_code1(+)
    ;
    -- レコード型
    get_hz_cust_accounts_rec  get_hz_cust_accounts_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- ===============================
    -- init部
    -- ===============================
    --==============================================================
    -- 「コンカレント入力パラメータなし」メッセージを出力
    --==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(iv_application  => cv_appl_short_name
                                          ,iv_name         => cv_msg_no_parameter
                                          );
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => gv_out_msg
                     );
    -- 空行出力
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => NULL
                     );
--
    --==============================================================
    -- ログインユーザの営業単位ID取得
    --==============================================================
    ln_org_id := FND_PROFILE.VALUE(cv_org_id);
--
    -- ===============================
    -- 処理部
    -- ===============================
--
    -- 項目名出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => '"入金先顧客ID","入金先顧客コード","入金先顧客名","請求先顧客ID","請求先顧客コード","請求先顧客名"'
    );
    -- データ部出力(CSV)
    FOR get_hz_cust_accounts_rec IN get_hz_cust_accounts_cur(ln_org_id)
     LOOP
       --件数セット
       gn_target_cnt := gn_target_cnt + 1;
       --変更する項目及びキー情報を出力
       FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => '"'|| get_hz_cust_accounts_rec.pay_customer_id     || '","'
                       || get_hz_cust_accounts_rec.pay_customer_number || '","'
                       || get_hz_cust_accounts_rec.pay_customer_name   || '","'
                       || get_hz_cust_accounts_rec.cust_account_id     || '","'
                       || get_hz_cust_accounts_rec.bill_customer_code  || '","'
                       || get_hz_cust_accounts_rec.bill_customer_name  || '"'
       );
    END LOOP;
--
    -- 成功件数＝対象件数
    gn_normal_cnt  := gn_target_cnt;
    -- 対象件数=0であれば警告
    IF (gn_target_cnt = 0) THEN
      gn_warn_cnt    := 1;
      ov_retcode     := cv_status_warn;
    END IF;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
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
    errbuf          OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode         OUT VARCHAR2       --   リターン・コード    --# 固定 #
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
       iv_which   => 'LOG'
      ,ov_retcode => lv_retcode
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
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
      gn_error_cnt := 1;
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --対象件数出力
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
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
END XXCCP009A14C;
/