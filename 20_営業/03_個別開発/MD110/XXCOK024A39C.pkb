CREATE OR REPLACE PACKAGE BODY      XXCOK024A39C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024AxxC(body)
 * Description      : 入金時値引訂正の控除データ作成
 * MD.050           : 入金時値引訂正の控除データ作成 MD050_COK_024_A39
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  proc_init            初期処理(A-1)
 *
 *  upd_control_p        販売控除管理情報更新(A-4)
 *  submain              メイン処理プロシージャ
 *                          ・proc_init
 *                       入金時値引訂正情報の取得(A-2)
 *                       控除データ登録(A-3)
 *                       メイン処理プロシージャ
 *                       税コードチェック(A-4)
 *  main                 コンカレント実行ファイル登録プロシージャ
 *                          ・submain
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2021/06/22    1.0   K.Yoshikawa      main新規作成
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal               CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal;  -- 正常:0
  cv_status_warn                 CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;    -- 警告:1
  cv_status_error                CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;   -- 異常:2
  --WHOカラム
  cn_created_by                  CONSTANT NUMBER      := fnd_global.user_id;            -- CREATED_BY
  cd_creation_date               CONSTANT DATE        := SYSDATE;                       -- CREATION_DATE
  cn_last_updated_by             CONSTANT NUMBER      := fnd_global.user_id;            -- LAST_UPDATED_BY
  cd_last_update_date            CONSTANT DATE        := SYSDATE;                       -- LAST_UPDATE_DATE
  cn_last_update_login           CONSTANT NUMBER      := fnd_global.login_id;           -- LAST_UPDATE_LOGIN
  cn_request_id                  CONSTANT NUMBER      := fnd_global.conc_request_id;    -- REQUEST_ID
  cn_program_application_id      CONSTANT NUMBER      := fnd_global.prog_appl_id;       -- PROGRAM_APPLICATION_ID
  cn_program_id                  CONSTANT NUMBER      := fnd_global.conc_program_id;    -- PROGRAM_ID
  cd_program_update_date         CONSTANT DATE        := SYSDATE;                       -- PROGRAM_UPDATE_DATE
  cv_msg_part                    CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont                    CONSTANT VARCHAR2(3) := '.';
  cv_control_flag_u              CONSTANT VARCHAR2(1) := 'U';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg                     VARCHAR2(2000);
  gv_sep_msg                     VARCHAR2(2000);
  gv_exec_user                   VARCHAR2(100);
  gv_conc_name                   VARCHAR2(30);
  gv_conc_status                 VARCHAR2(30);
  gn_target_cnt                  NUMBER;                    -- 対象件数
  gn_normal_cnt                  NUMBER;                    -- 正常件数
  gn_rate_skip_cnt               NUMBER;                    -- 振替割合100%以外でスキップした件数
  gn_error_cnt                   NUMBER;                    -- エラー件数
  gn_warn_cnt                    NUMBER;                    -- スキップ件数
  gn_warn_tax_cnt                NUMBER;                    -- 税コード警告スキップ件数
--
--################################  固定部 END   ##################################
--
--##########################  固定共通例外宣言部 START  ###########################
--
  --*** 処理部共通例外 ***
  global_process_expt            EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt                EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt         EXCEPTION;
  global_check_lock_expt         EXCEPTION;                 -- ロック取得エラー
  --
  --*** ログのみ出力例外 ***
  global_api_expt_log            EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_check_lock_expt, -54);
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000);
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                    CONSTANT VARCHAR2(30)  := 'XXCOK024A39C';       -- パッケージ名
--
  cv_appl_name_xxcok             CONSTANT VARCHAR2(5)   := 'XXCOK';              -- アプリケーション短縮名
  -- メッセージ
  cv_msg_xxcok_00001             CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00001';   -- 対象データなし
  cv_msg_xxcok_00003             CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00003';   -- プロファイル取得エラー
--
--
  cv_msg_xxcok_10592             CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10592';   -- 前回処理ID取得エラー
  cv_msg_xxcok_10798             CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10798';   -- 入金時値引のデータ種類取得エラー
  cv_msg_xxcok_10799             CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10799';   -- 税コードチェックエラー
  cv_msg_xxcok_10800             CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10800';   -- 税コード取得エラー

  cv_msg_proc_date_err           CONSTANT  VARCHAR2(100):= 'APP-XXCOK1-00028';   -- 業務日付取得エラーメッセージ
  -- トークン
  cv_tkn_profile                 CONSTANT VARCHAR2(10)  := 'PROFILE';            -- トークン：プロファイル名
  cv_tkn_sqlerrm                 CONSTANT VARCHAR2(10)  := 'SQLERRM';            -- トークン：SQLエラー
  cv_tkn_file_name               CONSTANT VARCHAR2(10)  := 'FILE_NAME';          -- トークン：SQLエラー
--
  cv_date_fmt_ymd                CONSTANT VARCHAR2(10)  := 'RRRRMMDD';           -- YYYYMMDD
  cv_date_fmt_dt_ymdhms          CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_date_fmt_dt_ymdhms;
                                                                                 -- YYYYMMDDHH24MISS
--
  cv_item_code_dummy_NT          CONSTANT VARCHAR2(33)  := 'XXCOK1_ITEM_CODE_DUMMY_NT';  -- XXCOK:品目コード_ダミー値（入金時値引訂正）
--
  cv_company_code                CONSTANT VARCHAR2(3)   := '001';                -- 会社コード
  cv_status_new                  CONSTANT VARCHAR2(1)   := 'N';                  -- ステータス N 新規
  cv_source_category_u           CONSTANT VARCHAR2(1)   := 'U';                  -- 作成元区分 U アップロード
  cv_data_type_lookup            CONSTANT VARCHAR2(30)  := 'XXCOK1_DEDUCTION_DATA_TYPE'; -- データ種類 参照タイプ
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_proc_date                   DATE;                                          -- 業務日付
  gv_item_code_dummy_NT          VARCHAR2(7);                                   -- ダミー品目コード（入金時値引訂正）
  gn_target_trx_line_id_st_1     NUMBER;                                        -- AR取引明細ID (自)
  gn_target_trx_line_id_ed_1     NUMBER;                                        -- AR取引明細ID (至)
  gv_data_type                   VARCHAR2(30);                                  -- 入金時値引データ種類
  gv_segment3                    VARCHAR2(25);                                  -- 入金時値引負債科目
  gv_segment4                    VARCHAR2(25);                                  -- 入金時値引負債科目補助
  gd_record_date                 DATE;                                          -- 計上日
  gn_org_id                      NUMBER;                                        -- 営業単位
  /**********************************************************************************
   * Procedure Name   : proc_init
   * Description      : 初期処理プロシージャ(A-1)
   ***********************************************************************************/
  PROCEDURE proc_init(
    ov_errbuf      OUT    VARCHAR2         --   エラー・メッセージ           --# 固定 #
   ,ov_retcode     OUT    VARCHAR2         --   リターン・コード             --# 固定 #
   ,ov_errmsg      OUT    VARCHAR2         --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'proc_init';          -- プログラム名
--
    -- ===============================
    -- 固定ローカル変数
    -- ===============================
    lv_errbuf                 VARCHAR2(5000);                                 -- エラー・メッセージ
    lv_retcode                VARCHAR2(1);                                    -- リターン・コード
    lv_errmsg                 VARCHAR2(5000);                                 -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_step                   VARCHAR2(100);                                  -- ステップ
    lv_message_token          VARCHAR2(100);                                  -- 連携日付
    --
    -- *** ユーザー定義例外 ***
    profile_expt              EXCEPTION;                                      -- プロファイル取得例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 業務日付の取得
    lv_step := 'A-1.1';
    lv_message_token := '業務日付の取得';
    gd_proc_date := xxccp_common_pkg2.get_process_date;
    IF ( gd_proc_date IS NULL ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_appl_name_xxcok,
        iv_name               =>  cv_msg_proc_date_err
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt_log;
    END IF;
--
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT
                     ,buff   => '業務日付:'||gd_proc_date
                      );
--
    -- 前月末日を取得
    gd_record_date := last_day(add_months(trunc(gd_proc_date,'month'),-1));
--
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT
                     ,buff   => '前月末日:'||gd_record_date
                      );
--
    -- プロファイル取得
    lv_step := 'A-1.2';
    lv_message_token := 'ダミー品目コード（入金時値引訂正）の取得';
--
    -- ダミー品目コードの取得
    gv_item_code_dummy_NT := FND_PROFILE.VALUE( cv_item_code_dummy_NT );
    -- 取得エラー時
    IF ( gv_item_code_dummy_NT IS NULL ) THEN
      lv_message_token := cv_item_code_dummy_NT;
      RAISE profile_expt;
    END IF;
--
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT
                     ,buff   => 'ダミー品目コード:'||gv_item_code_dummy_NT
                      );
--
    -- 入金時値引のデータ種類、科目、補助取得
    lv_step := 'A-1.4';
    lv_message_token := '入金時値引のデータ種類、科目、補助取得';
-- 
    BEGIN
--
      SELECT fvl.lookup_code
            ,fvl.attribute6
            ,fvl.attribute7
      INTO   gv_data_type
            ,gv_segment3
            ,gv_segment4
      FROM apps.fnd_lookup_values_vl fvl
      WHERE fvl.lookup_type = cv_data_type_lookup
      AND fvl.lookup_code = ( SELECT min(fvl.lookup_code)
                              FROM apps.fnd_lookup_values_vl fvl
                              WHERE fvl.lookup_type = cv_data_type_lookup
                              AND fvl.ENABLED_FLAG      =  'Y'
                              AND nvl(fvl.START_DATE_ACTIVE,to_date('19900101','RRRRMMDD')) <= gd_record_date
                              AND nvl(fvl.END_DATE_ACTIVE,to_date('29900101','RRRRMMDD'))   >= gd_record_date
                              AND attribute10       =  'Y' );
--
    EXCEPTION
      WHEN  OTHERS THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        cv_appl_name_xxcok
                      , cv_msg_xxcok_10798
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
    
    IF (gv_data_type is null or
        gv_segment3  is null or
        gv_segment4  is null) THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        cv_appl_name_xxcok
                      , cv_msg_xxcok_10798
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END IF;
--
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT
                     ,buff   => '入金時値引のデータ種類、科目、補助:'||gv_data_type||','||gv_segment3||','||gv_segment4
                      );
--
    -- 営業単位
    lv_step := 'A-1.5';
    gn_org_id := FND_PROFILE.VALUE( 'ORG_ID' );
    IF gn_org_id IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appl_name_xxcok
                     ,cv_msg_xxcok_00003
                     ,cv_tkn_profile
                     ,'ORG_ID'
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT
                     ,buff   => '営業単位:'||gn_org_id
                      );
--
  EXCEPTION
    -- *** 任意で例外処理を記述する ****
    -- カーソルのクローズをここに記述する
    --*** プロファイル取得エラー ***
    WHEN profile_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok            -- アプリケーション短縮名：XXCOK
                     ,iv_name         => cv_msg_xxcok_00003            -- メッセージ：APP-XXCOK1-00003 プロファイル取得エラー
                     ,iv_token_name1  => cv_tkn_profile                -- トークン：PROFILE
                     ,iv_token_value1 => lv_message_token              -- プロファイル名
                     );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf    := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      ov_retcode   := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf      OUT    VARCHAR2         --   エラー・メッセージ            --# 固定 #
   ,ov_retcode     OUT    VARCHAR2         --   リターン・コード              --# 固定 #
   ,ov_errmsg      OUT    VARCHAR2         --   ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'submain';            -- プログラム名
    -- ===============================
    -- 固定ローカル変数
    -- ===============================
    lv_errbuf                 VARCHAR2(5000);                                 -- エラー・メッセージ
    lv_retcode                VARCHAR2(1);                                    -- リターン・コード
    lv_errmsg                 VARCHAR2(5000);                                 -- ユーザー・エラー・メッセージ
    lv_step                   VARCHAR2(100);                                  -- ステップ
    lb_retcode                BOOLEAN             DEFAULT NULL;               -- メッセージ出力関数の戻り値
     --###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザーローカル変数
    -- ===============================
    lv_sqlerrm                VARCHAR2(5000);                                 -- SQLERRM退避
    lv_message_token          VARCHAR2(100);                                  -- 連携日付
    lv_item_code              VARCHAR2(7);                                    -- 品目コード
    lv_trx_number             VARCHAR2(20);                                   -- AR取引番号
    ln_trx_line_cnt           NUMBER :=  0;                                   -- AR取引明細分割数
    ln_rec_amount_div_rem     NUMBER :=  0;                                   -- 売上金額残
    ln_tax_amount_div_rem     NUMBER :=  0;                                   -- 税金金額残
    ln_line_number            NUMBER :=  0;                                   -- AR取引明細番号
    ln_rec_amount_div         NUMBER :=  0;                                   -- 売上金額
    ln_tax_amount_div         NUMBER :=  0;                                   -- 税金金額
    lv_conv_tax_code          VARCHAR2(50);                                   -- 変換後税コード
    lv_conv_tax_rate          NUMBER  :=  0;                                  -- 変換後税率
    lv_skip_flag              VARCHAR2(1);                                    -- スキップフラグ
    ln_from_customer          VARCHAR2(9);                                    -- 振替元顧客
    ln_to_customer            VARCHAR2(9);                                    -- 振替先顧客
    ln_from_base              VARCHAR2(4);                                    -- 振替元拠点
    ln_to_base                VARCHAR2(4);                                    -- 振替先拠点
    lv_out_msg                VARCHAR2(1000)      DEFAULT NULL;               -- メッセージ出力変数
--
    -- 入金時値引訂正情報カーソル
    --lv_step := 'A-2.1';
    CURSOR customer_trx_line_cur
    IS
    SELECT     trxl.trx_number                           trx_number,                                                    -- 納品伝票no（ar取引番号）
               trxl.trx_date                             trx_date,                                                      -- 納品日（売上日）（取引日）
               trxl.customer_trx_id                      customer_trx_id,                                               -- 取引ID
               trxl.ship_to_customer_id                  ship_to_customer_id,                                           -- 納品先顧客ID
               trxl.ship_to_customer_code                ship_to_customer_code,                                         -- 納品先顧客コード 
               trxl.customer_trx_line_id                 customer_trx_line_id,                                          -- 明細ID            
               trxl.line_number                          line_number,                                                   -- 明細番号
               trxl.item_code                            item_code,                                                     -- 商品コード
               trxl.rec_amount                           rec_amount,                                                    -- 売上金額
               trxl.tax_amount                           tax_amount,                                                    -- 税金金額
               trxl.comp_code                            comp_code,                                                     -- 会社コード(aff1)
               trxl.dept_code                            dept_code,                                                     -- 売上拠点コード(aff2)
               trxl.kamoku                               kamoku,                                                        -- 科目
               trxl.hojyo                                hojyo,                                                         -- 補助科目
               trxl.gl_date                              gl_date,                                                       -- GL記帳日
               trxl.trx_type_name                        trx_type_name,                                                 -- 取引タイプ名
               trxl.vat_tax_id                           vat_tax_id,                                                    -- 税コード
               trxl.ship_to_past_sale_base_code          ship_to_past_sale_base_code,                                   -- 納品先顧客前月売上拠点
               xsri2.selling_trns_rate_info_id           selling_trns_rate_info_id,                                     -- 振替割合ID
               xsri2.selling_from_base_code              selling_from_base_cod,                                         -- 振替元拠点
               xsri2.selling_from_cust_code              selling_from_cust_code,                                        -- 振替元顧客
               xsri2.from_cust_past_sale_base_code       from_cust_past_sale_base_code,                                 -- 振替元顧客前月売上拠点
               xsri2.selling_to_cust_code                selling_to_cust_code,                                          -- 振替先顧客
               xsri2.to_cust_past_sale_base_code         to_cust_past_sale_base_code,                                   -- 振替先顧客前月売上拠点
               xsri2.selling_trns_rate                   selling_trns_rate,                                             -- 振替割合
               xsri2.invalid_flag                        invalid_flag,                                                  -- 有効フラグ
               round(trxl.rec_amount * nvl(xsri2.selling_trns_rate,100) /100)
                                                         rec_amount_div,                                                -- 売上金額按分
               round(trxl.tax_amount * nvl(xsri2.selling_trns_rate,100) /100)
                                                         tax_amount_div,                                                -- 税金金額按分
               count(1) over(partition by  trxl.customer_trx_line_id)
                                                         cnt_trx_line,                                                  -- 明細按分件数
               sum(xsri2.selling_trns_rate) over(partition by  trxl.customer_trx_line_id)
                                                         sum_trns_rate                                                  -- 振替割合合計
    FROM
              (SELECT rcta.trx_number               trx_number,                                                         -- 納品伝票no（ar取引番号）
                      rcta.trx_date                 trx_date,                                                           -- 納品日（売上日）（取引日）
                      rcta.customer_trx_id          customer_trx_id,                                                    -- 取引id
                      rcta.ship_to_customer_id      ship_to_customer_id,                                                -- 納品先顧客id
                      hca.account_number            ship_to_customer_code,                                              -- 納品先顧客コード 
                      rctla.customer_trx_line_id    customer_trx_line_id,                                               -- 明細id            
                      rctla.line_number             line_number,                                                        -- 明細番号
                      rctta.attribute3              item_code,                                                          -- 商品コード
                      rctla.revenue_amount          rec_amount,                                                         -- 売上金額
                      rctla_t.extended_amount       tax_amount,                                                         -- 税金金額
                      gcc.segment1                  comp_code,                                                          -- 会社コード(aff1)
                      gcc.segment2                  dept_code,                                                          -- 売上拠点コード(aff2)
                      gcc.segment3                  kamoku,                                                             -- 科目
                      gcc.segment4                  hojyo,                                                              -- 補助科目
                      rctlgda.gl_date               gl_date,                                                            -- gl記帳日
                      rctta.name                    trx_type_name,                                                      -- 取引タイプ名
                      rctla.vat_tax_id              vat_tax_id,                                                         -- 税コード
                      xca.past_sale_base_code       ship_to_past_sale_base_code                                         -- 納品先顧客前月売上拠点
              FROM    apps.ra_customer_trx_all              rcta,                                                       -- 取引ヘッダ
                      apps.ra_cust_trx_types_all            rctta,                                                      -- 取引タイプ
                      apps.ra_customer_trx_lines_all        rctla,                                                      -- 取引明細（本体）
                      apps.ra_customer_trx_lines_all        rctla_t,                                                    -- 取引明細（税額）
                      apps.ra_cust_trx_line_gl_dist_all     rctlgda,                                                    -- 取引配分
                      apps.gl_code_combinations             gcc,                                                        -- 勘定科目組合せマスタ
                      apps.hz_cust_accounts                 hca,                                                        -- 顧客マスタ
                      apps.xxcmm_cust_accounts              xca                                                         -- 顧客追加情報
              WHERE   rcta.cust_trx_type_id           =  rctta.cust_trx_type_id
              AND     rctla.line_type                 =  'LINE'
              AND     rctlgda.gl_date                 >= trunc (gd_record_date,'month')                                 -- 前月1日
              AND     rctlgda.gl_date                 <= gd_record_date                                                 -- 前月末日
              AND     rcta.customer_trx_id            =  rctla.customer_trx_id
              AND     rctla.customer_trx_line_id      =  rctla_t.link_to_cust_trx_line_id(+)
              AND     rctla.customer_trx_line_id      =  rctlgda.customer_trx_line_id
              AND     rctlgda.code_combination_id     =  gcc.code_combination_id 
              AND     hca.cust_account_id             =  rcta.ship_to_customer_id
              AND     xca.customer_code               =  hca.account_number
              AND     gcc.segment3                    =  gv_segment3 --'41507'
              AND     gcc.segment4                    =  gv_segment4 --'02252'
              AND     rctta.name                      in (SELECT fvl.meaning
                                                          FROM   apps.fnd_lookup_values_vl fvl
                                                          WHERE  fvl.lookup_type = 'XXCOK1_TRX_TYPE_DISC'
                                                          AND    fvl.ENABLED_FLAG      =  'Y'
                                                          AND    nvl(fvl.START_DATE_ACTIVE,to_date('19900101','RRRRMMDD')) <= gd_record_date
                                                          AND    nvl(fvl.END_DATE_ACTIVE,to_date('29900101','RRRRMMDD'))   >= gd_record_date 
                                                          )                                                               -- 入金時値引訂正','取消 入金時値引
              AND     rcta.customer_trx_id            not in (
                                                           SELECT  customer_trx_id
                                                           FROM    apps.ra_customer_trx_lines_all ractal_2
                                                                  ,apps.ar_vat_tax_all     avta_2      
                                                           WHERE   avta_2.vat_tax_id       = ractal_2.vat_tax_id
                                                           AND     avta_2.attribute4       is null
                                                           AND     ractal_2.customer_trx_id = rcta.customer_trx_id
                                                           )                                                            -- '9910','9908'以外の税コードが含まれる場合取引ヘッダー単位で除外
              ) trxl,
              (SELECT xsri.selling_trns_rate_info_id    selling_trns_rate_info_id,                                      -- 納品先顧客前月売上拠点
                      xsri.selling_from_base_code       selling_from_base_code,                                         -- 振替割合ID
                      xsri.selling_from_cust_code       selling_from_cust_code,                                         -- 振替元拠点
                      xca1.past_sale_base_code          from_cust_past_sale_base_code,                                  -- 振替元顧客
                      xsri.selling_to_cust_code         selling_to_cust_code,                                           -- 振替元顧客前月売上拠点
                      xca2.past_sale_base_code          to_cust_past_sale_base_code,                                    -- 振替先顧客
                      xsri.selling_trns_rate            selling_trns_rate,                                              -- 振替先顧客前月売上拠点
                      xsri.invalid_flag                 invalid_flag                                                    -- 振替割合
              FROM apps.xxcok_selling_rate_info         xsri                                                            -- 有効フラグ
                  ,apps.xxcmm_cust_accounts             xca1
                  ,apps.xxcmm_cust_accounts             xca2
              where 1=1
              AND  xsri.selling_from_cust_code   = xca1.customer_code(+)
              AND  xsri.selling_to_cust_code     = xca2.customer_code(+)
              AND  xsri.invalid_flag             = '0' --cv_invalid_flag_valid
              AND  xca1.selling_transfer_div     = '1'
              AND  exists ( SELECT /*+ leading( xsfi,xsti ) */
                            'x'
                            FROM apps.xxcok_selling_from_info    xsfi
                               , apps.xxcok_selling_to_info      xsti
                            WHERE xsfi.selling_from_base_code     = xsri.selling_from_base_code
                            AND xsfi.selling_from_cust_code     = xsri.selling_from_cust_code
                            AND xsfi.selling_from_info_id       = xsti.selling_from_info_id
                            AND xsti.selling_to_cust_code       = xsri.selling_to_cust_code
                            AND xsti.start_month               <= to_char(gd_record_date,'RRRRMM')  --部門入力を計上した月
                            AND xsti.invalid_flag               = 0 --cv_invalid_flag_valid
                            AND rownum                          = 1
                        )
              ) xsri2
    WHERE 1=1
    AND   trxl.ship_to_customer_code = xsri2.selling_from_cust_code(+)
    AND   trxl.ship_to_past_sale_base_code = xsri2.selling_from_base_code(+)
    ORDER BY trxl.trx_number
         ,trxl.line_number
         ,selling_trns_rate_info_id;
--
    TYPE customer_trx_line_ttype IS TABLE OF customer_trx_line_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    lt_customer_trx_line_tab       customer_trx_line_ttype;               -- 入金時値引訂正データ
--
    -- 税コードチェックカーソル
    --lv_step := 'A-2.2';
    CURSOR tax_check_cur
    IS
--
              SELECT  rcta.trx_number
                     ,rctla.line_number
              FROM    apps.ra_customer_trx_all              rcta,                                                       -- 取引ヘッダ
                      apps.ra_cust_trx_types_all            rctta,                                                      -- 取引タイプ
                      apps.ra_customer_trx_lines_all        rctla,                                                      -- 取引明細（本体）
                      apps.ra_customer_trx_lines_all        rctla_t,                                                    -- 取引明細（税額）
                      apps.ra_cust_trx_line_gl_dist_all     rctlgda,                                                    -- 取引配分
                      apps.gl_code_combinations             gcc,                                                        -- 勘定科目組合せマスタ
                      apps.hz_cust_accounts                 hca,                                                        -- 顧客マスタ
                      apps.xxcmm_cust_accounts              xca                                                         -- 顧客追加情報
              WHERE   rcta.cust_trx_type_id           =  rctta.cust_trx_type_id
              AND     rctla.line_type                 =  'LINE'
              AND     rctlgda.gl_date                 >= trunc (gd_record_date,'month')                                 -- 前月1日
              AND     rctlgda.gl_date                 <= gd_record_date                                                 -- 前月末日
              AND     rcta.customer_trx_id            =  rctla.customer_trx_id
              AND     rctla.customer_trx_line_id      =  rctla_t.link_to_cust_trx_line_id(+)
              AND     rctla.customer_trx_line_id      =  rctlgda.customer_trx_line_id
              AND     rctlgda.code_combination_id     =  gcc.code_combination_id 
              AND     hca.cust_account_id             =  rcta.ship_to_customer_id
              AND     xca.customer_code               =  hca.account_number
              AND     gcc.segment3                    =  gv_segment3 --'41507'
              AND     gcc.segment4                    =  gv_segment4 --'02252'
              AND     rctta.name                      in (SELECT fvl.meaning
                                                          FROM   apps.fnd_lookup_values_vl fvl
                                                          WHERE  fvl.lookup_type = 'XXCOK1_TRX_TYPE_DISC'
                                                          AND    fvl.ENABLED_FLAG      =  'Y'
                                                          AND    nvl(fvl.START_DATE_ACTIVE,to_date('19900101','RRRRMMDD')) <= gd_record_date
                                                          AND    nvl(fvl.END_DATE_ACTIVE,to_date('29900101','RRRRMMDD'))   >= gd_record_date 
                                                          )                                                               -- 入金時値引訂正','取消 入金時値引
              AND     rcta.customer_trx_id            in (
                                                           SELECT  customer_trx_id
                                                           FROM    apps.ra_customer_trx_lines_all ractal_2
                                                                  ,apps.ar_vat_tax_all     avta_2      
                                                           WHERE   avta_2.vat_tax_id       = ractal_2.vat_tax_id
                                                           AND     avta_2.attribute4       is null
                                                           AND    ractal_2.customer_trx_id = rcta.customer_trx_id
                                                           )
              ORDER BY rcta.trx_number
                      ,rctla.line_number;
--
    TYPE tax_check_ttype IS TABLE OF tax_check_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    lt_tax_check_tab       tax_check_ttype;    -- 税コード不正データ
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    subproc_expt              EXCEPTION;       -- サブプログラムエラー
    file_open_expt            EXCEPTION;       -- ファイルオープンエラー
    file_output_expt          EXCEPTION;       -- ファイル書き込みエラー
    file_close_expt           EXCEPTION;       -- ファイルクローズエラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- グローバル変数の初期化
    gn_target_cnt     := 0;
    gn_rate_skip_cnt  := 0;
    gn_normal_cnt     := 0;
    gn_error_cnt      := 0;
    gn_warn_cnt       := 0;
    gn_warn_tax_cnt   := 0;
--
    -- ===============================================
    -- proc_initの呼び出し（初期処理はproc_initで行う）
    -- ===============================================
    proc_init(
       ov_errbuf      => lv_errbuf       -- エラー・メッセージ           --# 固定 #
      ,ov_retcode     => lv_retcode      -- リターン・コード             --# 固定 #
      ,ov_errmsg      => lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE subproc_expt;
    END IF;
--
    -----------------------------------
    -- A-2.入金時値引訂正情報の取得
    -----------------------------------
    lv_step := 'A-2';
--
    OPEN  customer_trx_line_cur;
    FETCH customer_trx_line_cur BULK COLLECT INTO lt_customer_trx_line_tab;
    CLOSE customer_trx_line_cur;
    -- 処理件数カウント
    gn_target_cnt := lt_customer_trx_line_tab.COUNT;
--
    -----------------------------------------------
    -- A-3.控除データ登録
    -----------------------------------------------
    lv_step := 'A-3';
--
      <<out_trx_line_loop>>
      FOR i IN 1..lt_customer_trx_line_tab.COUNT LOOP
--
         lv_errmsg := '取引番号：' || lt_customer_trx_line_tab( i ).trx_number || '明細番号：' || lt_customer_trx_line_tab( i ).line_number;
         lv_errbuf :=  lv_errmsg;
--
         lv_skip_flag := 'N';
--
         --明細がブレークしたら件数と残額をリセット
         IF lv_trx_number || ln_line_number <> lt_customer_trx_line_tab( i ).trx_number || lt_customer_trx_line_tab( i ).line_number THEN
            ln_trx_line_cnt       := 1;
            ln_rec_amount_div_rem := lt_customer_trx_line_tab( i ).rec_amount;
            ln_tax_amount_div_rem := lt_customer_trx_line_tab( i ).tax_amount;
         ELSE
            ln_trx_line_cnt       := ln_trx_line_cnt + 1;
         END IF;
--
         --AR取引明細毎の最終分割レコードの場合は、端数調整のため明細金額から出力済み金額の差額を控除金額としてINSERT
         IF ln_trx_line_cnt = lt_customer_trx_line_tab( i ). cnt_trx_line  THEN
            ln_rec_amount_div     := ln_rec_amount_div_rem;
            ln_tax_amount_div     := ln_tax_amount_div_rem;
--
            ln_from_customer      :=lt_customer_trx_line_tab( i ).ship_to_customer_code;
            ln_to_customer        :=nvl(lt_customer_trx_line_tab( i ).selling_to_cust_code, lt_customer_trx_line_tab( i ).ship_to_customer_code);
            ln_from_base          :=nvl(lt_customer_trx_line_tab( i ).to_cust_past_sale_base_code, lt_customer_trx_line_tab( i ).ship_to_past_sale_base_code);
            ln_to_base            :=nvl(lt_customer_trx_line_tab( i ).to_cust_past_sale_base_code, lt_customer_trx_line_tab( i ).ship_to_past_sale_base_code);
--
            --振替割合が100%でない場合は振替元で控除データを作成
            IF lt_customer_trx_line_tab( i ).sum_trns_rate <> 100 THEN
               ln_rec_amount_div  := lt_customer_trx_line_tab( i ).rec_amount;
               ln_tax_amount_div  := lt_customer_trx_line_tab( i ).tax_amount;
--
               ln_from_customer   :=lt_customer_trx_line_tab( i ).ship_to_customer_code;
               ln_to_customer     :=lt_customer_trx_line_tab( i ).ship_to_customer_code;
               ln_from_base       :=lt_customer_trx_line_tab( i ).ship_to_past_sale_base_code;
               ln_to_base         :=lt_customer_trx_line_tab( i ).ship_to_past_sale_base_code;
--
            END IF;
         ELSE
            ln_rec_amount_div     := lt_customer_trx_line_tab( i ).rec_amount_div;
            ln_tax_amount_div     := lt_customer_trx_line_tab( i ).tax_amount_div;
--
            ln_from_customer      :=lt_customer_trx_line_tab( i ).ship_to_customer_code;
            ln_to_customer        :=nvl(lt_customer_trx_line_tab( i ).selling_to_cust_code, lt_customer_trx_line_tab( i ).ship_to_customer_code);
            ln_from_base          :=nvl(lt_customer_trx_line_tab( i ).to_cust_past_sale_base_code, lt_customer_trx_line_tab( i ).ship_to_past_sale_base_code);
            ln_to_base            :=nvl(lt_customer_trx_line_tab( i ).to_cust_past_sale_base_code, lt_customer_trx_line_tab( i ).ship_to_past_sale_base_code);
--
            --振替割合が100%でない場合は最終行以外はスキップ
            IF lt_customer_trx_line_tab( i ).sum_trns_rate <> 100 THEN
               lv_skip_flag := 'Y';
               gn_rate_skip_cnt := gn_rate_skip_cnt + 1;
            END IF;
         END IF;
--
         IF lv_skip_flag = 'N' THEN
             --税コード変換
            lv_step := 'A-3.1a';
            BEGIN
--
              SELECT   avta.attribute4
                      ,avta2.tax_rate
              INTO     lv_conv_tax_code
                      ,lv_conv_tax_rate
              FROM     ar_vat_tax_all avta
                      ,ar_vat_tax_all avta2
              WHERE    avta2.tax_code     =  avta.attribute4
              AND      avta.org_id        =  gn_org_id
              AND      nvl(avta.start_date,to_date('19900101','RRRRMMDD'))    <= gd_record_date
              AND      nvl(avta.end_date,to_date('29990101','RRRRMMDD'))      >= gd_record_date
              AND      avta.enabled_flag  =  'Y'
              AND      avta.vat_tax_id    =  lt_customer_trx_line_tab( i ).vat_tax_id
              AND      avta2.org_id       =  gn_org_id
              AND      nvl(avta2.start_date,to_date('19900101','RRRRMMDD'))   <= gd_record_date
              AND      nvl(avta2.end_date,to_date('29990101','RRRRMMDD'))     >= gd_record_date
              AND      avta2.enabled_flag =  'Y';
              --
            EXCEPTION
              WHEN  OTHERS THEN
                       lv_errmsg :=  xxccp_common_pkg.get_msg(
                                     cv_appl_name_xxcok
                                   , cv_msg_xxcok_10800
                                   );
                       lv_errbuf :=  lv_errmsg;
                       RAISE global_process_expt;
            END;
--
          -- 控除データINSERT
          lv_step := 'A-3.1b';
            INSERT INTO xxcok_sales_deduction(sales_deduction_id                                           --販売控除ID
                                             ,base_code_from                                               --振替元拠点
                                             ,base_code_to                                                 --振替先拠点
                                             ,customer_code_from                                           --振替元顧客コード
                                             ,customer_code_to                                             --振替先顧客コード
                                             ,deduction_chain_code                                         --控除用チェーンコード
                                             ,corp_code                                                    --企業コード
                                             ,record_date                                                  --計上日
                                             ,source_category                                              --作成元区分
                                             ,source_line_id                                               --作成元明細ID
                                             ,condition_id                                                 --控除条件ID
                                             ,condition_no                                                 --控除番号
                                             ,condition_line_id                                            --控除詳細ID
                                             ,data_type                                                    --データ種類
                                             ,status                                                       --ステータス
                                             ,item_code                                                    --品目コード
                                             ,sales_uom_code                                               --販売単位
                                             ,sales_unit_price                                             --販売単価
                                             ,sales_quantity                                               --販売数量
                                             ,sale_pure_amount                                             --売上本体金額
                                             ,sale_tax_amount                                              --売上消費税額
                                             ,deduction_uom_code                                           --控除単位
                                             ,deduction_unit_price                                         --控除単価
                                             ,deduction_quantity                                           --控除数量
                                             ,deduction_amount                                             --控除額
                                             ,compensation                                                 --補填
                                             ,margin                                                       --問屋マージン
                                             ,sales_promotion_expenses                                     --拡売
                                             ,margin_reduction                                             --問屋マージン減額
                                             ,tax_code                                                     --税コード
                                             ,tax_rate                                                     --税率
                                             ,recon_tax_code                                               --消込時税コード
                                             ,recon_tax_rate                                               --消込時税率
                                             ,deduction_tax_amount                                         --控除税額
                                             ,remarks                                                      --備考
                                             ,application_no                                               --申請書No.
                                             ,gl_if_flag                                                   --GL連携フラグ
                                             ,gl_base_code                                                 --GL計上拠点
                                             ,gl_date                                                      --GL記帳日
                                             ,recovery_date                                                --リカバリデータ追加時日付
                                             ,recovery_add_request_id                                      --リカバリデータ追加時要求ID
                                             ,recovery_del_date                                            --リカバリデータ削除時日付
                                             ,recovery_del_request_id                                      --リカバリデータ削除時要求ID
                                             ,cancel_flag                                                  --取消フラグ
                                             ,cancel_base_code                                             --取消時計上拠点
                                             ,cancel_gl_date                                               --取消GL記帳日
                                             ,cancel_user                                                  --取消実施ユーザ
                                             ,recon_base_code                                              --消込時計上拠点
                                             ,recon_slip_num                                               --支払伝票番号
                                             ,carry_payment_slip_num                                       --繰越時支払伝票番号
                                             ,report_decision_flag                                         --速報確定フラグ
                                             ,gl_interface_id                                              --GL連携ID
                                             ,cancel_gl_interface_id                                       --取消GL連携ID
                                             ,created_by                                                   --作成者
                                             ,creation_date                                                --作成日
                                             ,last_updated_by                                              --最終更新者
                                             ,last_update_date                                             --最終更新日
                                             ,last_update_login                                            --最終更新ログイン
                                             ,request_id                                                   --要求ID
                                             ,program_application_id                                       --コンカレント・プログラム・アプリケーションID
                                             ,program_id                                                   --コンカレント・プログラムID
                                             ,program_update_date                                          --プログラム更新日
                                             )
            VALUES                           (
                                              xxcok_sales_deduction_s01.nextval                            --販売控除ID
                                             ,ln_from_base                                                 --振替元拠点
                                             ,ln_to_base                                                   --振替先拠点
                                             ,ln_from_customer                                             --振替元顧客コード
                                             ,ln_to_customer                                               --振替先顧客コード
                                             ,null                                                         --控除用チェーンコード
                                             ,null                                                         --企業コード
                                             ,gd_record_date                                               --計上日
                                             ,cv_source_category_u                                         --作成元区分
                                             ,null                                                         --作成元明細ID
                                             ,null                                                         --控除条件ID
                                             ,lt_customer_trx_line_tab( i ).trx_number                     --控除番号
                                             ,null                                                         --控除詳細ID
                                             ,gv_data_type                                                 --データ種類
                                             ,cv_status_new                                                --ステータス
                                             ,gv_item_code_dummy_NT                                        --品目コード
                                             ,null                                                         --販売単位
                                             ,null                                                         --販売単価
                                             ,null                                                         --販売数量
                                             ,null                                                         --売上本体金額
                                             ,null                                                         --売上消費税額
                                             ,null                                                         --控除単位
                                             ,null                                                         --控除単価
                                             ,null                                                         --控除数量
                                             ,ln_rec_amount_div * -1                                       --控除額
                                             ,null                                                         --補填
                                             ,null                                                         --問屋マージン
                                             ,null                                                         --拡売
                                             ,null                                                         --問屋マージン減額
                                             ,lv_conv_tax_code                                             --税コード 
                                             ,lv_conv_tax_rate                                             --税率
                                             ,null                                                         --消込時税コード
                                             ,null                                                         --消込時税率
                                             ,ln_tax_amount_div * -1                                       --控除税額
                                             ,CASE WHEN lt_customer_trx_line_tab( i ).selling_trns_rate is not null
                                                   THEN lt_customer_trx_line_tab( i ).ship_to_past_sale_base_code
                                                   ELSE null
                                                   END                                                     --備考
                                             ,null                                                         --申請書No.
                                             ,'N'                                                          --GL連携フラグ
                                             ,null                                                         --GL計上拠点
                                             ,null                                                         --GL記帳日
                                             ,null                                                         --リカバリデータ追加時日付
                                             ,null                                                         --リカバリデータ追加時要求ID
                                             ,null                                                         --リカバリデータ削除時日付
                                             ,null                                                         --リカバリデータ削除時要求ID
                                             ,'N'                                                          --取消フラグ
                                             ,null                                                         --取消時計上拠点
                                             ,null                                                         --取消GL記帳日
                                             ,null                                                         --取消実施ユーザ
                                             ,null                                                         --消込時計上拠点
                                             ,lt_customer_trx_line_tab( i ).trx_number                     --支払伝票番号
                                             ,lt_customer_trx_line_tab( i ).trx_number                     --繰越時支払伝票番号
                                             ,null                                                         --速報確定フラグ
                                             ,null                                                         --GL連携ID
                                             ,null                                                         --取消GL連携ID
                                             ,cn_created_by                                                --作成者
                                             ,cd_creation_date                                             --作成日
                                             ,cn_last_updated_by                                           --最終更新者
                                             ,cd_last_update_date                                          --最終更新日
                                             ,cn_last_update_login                                         --最終更新ログイン
                                             ,cn_request_id                                                --要求ID
                                             ,cn_program_application_id                                    --コンカレント・プログラム・アプリケーションID
                                             ,cn_program_id                                                --コンカレント・プログラムID
                                             ,cd_program_update_date                                       --プログラム更新日
                                             );
            -- 成功件数
            gn_normal_cnt := gn_normal_cnt + 1;
--
         END IF;
--
        --ブレークキー保持
        lv_trx_number         := lt_customer_trx_line_tab( i ).trx_number;
        ln_line_number        := lt_customer_trx_line_tab( i ).line_number;
--
        --明細毎の分割後の残額を保持
        ln_rec_amount_div_rem := ln_rec_amount_div_rem - lt_customer_trx_line_tab( i ).rec_amount_div;
        ln_tax_amount_div_rem := ln_tax_amount_div_rem - lt_customer_trx_line_tab( i ).tax_amount_div;
--
      END LOOP out_trx_line_loop;
--
      lv_step := 'A-4';
--
      OPEN  tax_check_cur;
      FETCH tax_check_cur BULK COLLECT INTO lt_tax_check_tab;
      CLOSE tax_check_cur;
      -- 処理件数カウント
      gn_warn_tax_cnt := lt_tax_check_tab.COUNT;
--
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                                 cv_appl_name_xxcok
                               , cv_msg_xxcok_10799
                               );
--
      <<out_tax_check_loop>>
      FOR i IN 1..lt_tax_check_tab.COUNT LOOP
--
        FND_FILE.PUT_LINE(
                          which  => FND_FILE.OUTPUT
                         ,buff   => lv_errmsg || ' 取引番号：' || lt_tax_check_tab( i ).trx_number || ' 明細番号：' || lt_tax_check_tab( i ).line_number
                          );
--
      END LOOP out_trx_line_loop;
--
      IF gn_warn_tax_cnt > 0 THEN
          ov_retcode := cv_status_warn;
      END IF;
--
      COMMIT;
--
  EXCEPTION
    -- *** 任意で例外処理を記述する ****
    -- *** サブプログラム例外ハンドラ ****
    WHEN subproc_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- エラー件数出力
      gn_error_cnt := gn_target_cnt;
      ov_errbuf    := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode   := cv_status_error;
--
--####################################  固定部 END   ###################s#######################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
  --
  PROCEDURE main(
    errbuf         OUT    VARCHAR2         --   エラーメッセージ #固定#
   ,retcode        OUT    VARCHAR2         --   エラーコード     #固定#
  )
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'main';               -- プログラム名
    cv_log                    CONSTANT VARCHAR2(100) := 'LOG';                -- ログ
    cv_output                 CONSTANT VARCHAR2(100) := 'OUTPUT';             -- アウトプット
    cv_app_name_xxccp         CONSTANT VARCHAR2(100) := 'XXCCP';              -- アプリケーション短縮名
    cv_target_cnt_msg         CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';   -- 対象件数メッセージ
    cv_success_cnt_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';   -- 成功件数メッセージ
    cv_msg_ccp_90003          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90003';   -- スキップ件数メッセージ
    cv_error_cnt_msg          CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';   -- エラー件数メッセージ
    cv_normal_msg             CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';   -- 正常終了メッセージ
    cv_warn_msg               CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005';   -- 警告終了メッセージ
    cv_error_msg              CONSTANT VARCHAR2(100) := 'APP-XXCCP1-10008';   -- エラー終了メッセージ
    cv_token_name1            CONSTANT VARCHAR2(100) := 'COUNT';              -- 処理件数
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf                 VARCHAR2(5000);                                 -- エラー・メッセージ
    lv_retcode                VARCHAR2(1);                                    -- リターン・コード
    lv_errmsg                 VARCHAR2(5000);                                 -- ユーザー・エラー・メッセージ
    lv_step                   VARCHAR2(10);                                   -- ステップ
    lv_message_code           VARCHAR2(100);                                  -- メッセージコード
--
--
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_output
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       ov_errbuf      => lv_errbuf       -- エラー・メッセージ           --# 固定 #
      ,ov_retcode     => lv_retcode      -- リターン・コード             --# 固定 #
      ,ov_errmsg      => lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      --エラー出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザーエラーメッセージ
      );
--
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
   -- 対象なしの場合
   IF gn_target_cnt = 0 THEN
      lv_errmsg  :=  xxccp_common_pkg.get_msg(
                         cv_appl_name_xxcok
                       , cv_msg_xxcok_00001
                       );
      --エラー出力
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg --0件メッセージ
       );
--
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
         ,buff   => lv_errmsg --0件メッセージ
       );
   END IF;
--
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_target_cnt_msg
                    ,iv_token_name1  => cv_token_name1
                    ,iv_token_value1 => TO_CHAR( gn_target_cnt + gn_warn_tax_cnt - gn_rate_skip_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_success_cnt_msg
                    ,iv_token_name1  => cv_token_name1
                    ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_msg_ccp_90003
                    ,iv_token_name1  => cv_token_name1
                    ,iv_token_value1 => TO_CHAR( gn_warn_tax_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_error_cnt_msg
                    ,iv_token_name1  => cv_token_name1
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --終了メッセージ
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCOK024A39C;
/
