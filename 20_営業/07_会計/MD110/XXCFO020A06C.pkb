CREATE OR REPLACE PACKAGE BODY  APPS.XXCFO020A06C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2014. All rights reserved.
 *
 * Package Name     : XXCFO020A06C (spec)
 * Description      : 相良会計仕訳科目マッピング共通機能
 * MD.050           : 相良会計仕訳科目マッピング共通機能 (MD050_CFO_020A06)
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 相良会計仕訳科目マッピング共通機能
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014/09/26    1.0   T.Kobori         新規作成
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- 異常:2
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCFO020A06C';              -- パッケージ名
--
  -- アプリケーション短縮名
  cv_appl_name_xxccp          CONSTANT VARCHAR2(10)  := 'XXCCP';                     -- XXCCP
  cv_appl_name_xxcfo          CONSTANT VARCHAR2(10)  := 'XXCFO';                     -- XXCFO
--
  /**********************************************************************************
   * Procedure Name   : get_siwake_account_title
   * Description      : 相良会計仕訳科目マッピング共通機能
   ***********************************************************************************/
  PROCEDURE get_siwake_account_title(
    ov_retcode                OUT    VARCHAR2      -- リターンコード
   ,ov_errbuf                 OUT    VARCHAR2      -- エラーメッセージ
   ,ov_errmsg                 OUT    VARCHAR2      -- ユーザー・エラーメッセージ
   ,ov_company_code           OUT    VARCHAR2      -- 1.会社
   ,ov_department_code        OUT    VARCHAR2      -- 2.部門
   ,ov_account_title          OUT    VARCHAR2      -- 3.勘定科目
   ,ov_account_subsidiary     OUT    VARCHAR2      -- 4.補助科目
   ,ov_description            OUT    VARCHAR2      -- 5.摘要
   ,iv_report                 IN     VARCHAR2      -- 6.帳票
   ,iv_class_code             IN     VARCHAR2      -- 7.品目区分
   ,iv_prod_class             IN     VARCHAR2      -- 8.商品区分
   ,iv_reason_code            IN     VARCHAR2      -- 9.事由コード
   ,iv_ptn_siwake             IN     VARCHAR2      -- 10.仕訳パターン
   ,iv_line_no                IN     VARCHAR2      -- 11.行番号
   ,iv_gloif_dr_cr            IN     VARCHAR2      -- 12.借方・貸方
   ,iv_warehouse_code         IN     VARCHAR2      -- 13.倉庫コード
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_siwake_account_title'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_enabled_flag_enabled        CONSTANT VARCHAR2(1)   := 'Y';                           -- 参照タイプの有効フラグ「有効」
    cv_department                  CONSTANT VARCHAR2(100) := 'DEPARTMENT%';                 -- 参照タイプ(動的部門導出表)の抽出条件
    cv_others                      CONSTANT VARCHAR2(100) := 'OTHERS';                      -- 参照タイプ(動的部門導出表)の抽出条件
    -- メッセージID
    cv_msg_cfo_00001               CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00001';         --プロファイル名取得エラーメッセージ
    cv_msg_cfo_10049               CONSTANT VARCHAR2(100) := 'APP-XXCFO1-10049';         -- 対象データなしエラー
    cv_msg_cfo_10050               CONSTANT VARCHAR2(100) := 'APP-XXCFO1-10050';         -- 対象データ複数ありエラー
    cv_msg_cfo_10051               CONSTANT VARCHAR2(100) := 'APP-XXCFO1-10051';         -- 動的部門導出表対象データ複数ありエラー
    -- トークン
    cv_tkn_report                  CONSTANT VARCHAR2(100) := 'REPORT';
    cv_tkn_hinmoku                 CONSTANT VARCHAR2(100) := 'HINMOKU';
    cv_tkn_shohin                  CONSTANT VARCHAR2(100) := 'SHOHIN';
    cv_tkn_jiyuu                   CONSTANT VARCHAR2(100) := 'JIYUU';
    cv_tkn_siwake                  CONSTANT VARCHAR2(100) := 'SIWAKE';
    cv_tkn_gyou                    CONSTANT VARCHAR2(100) := 'GYOU';
    cv_tkn_taishaku                CONSTANT VARCHAR2(100) := 'TAISHAKU';
    cv_tkn_souko                   CONSTANT VARCHAR2(100) := 'SOUKO';
    cv_tkn_doutekibumon            CONSTANT VARCHAR2(100) := 'DOUTEKIBUMON';
    cv_tkn_attribute1              CONSTANT VARCHAR2(100) := 'ATTRIBUTE1';
    cv_tkn_attribute2_1            CONSTANT VARCHAR2(100) := 'ATTRIBUTE2_1';
    cv_tkn_attribute2_2            CONSTANT VARCHAR2(100) := 'ATTRIBUTE2_2';
    cv_tkn_prof_name               CONSTANT VARCHAR2(100) := 'PROF_NAME';
    -- プロファイル
    cv_prof_je_ptn_invoice         CONSTANT VARCHAR2(30)  := 'XXCFO1_JE_PTN_INVOICE';    -- XXCFO: 仕訳パターン表
    cv_prof_je_dy_department       CONSTANT VARCHAR2(30)  := 'XXCFO1_JE_DY_DEPARTMENT';  -- XXCFO: 動的部門抽出表
    cv_prof_je_ptn_rec_pay         CONSTANT VARCHAR2(30)  := 'XXCFO1_JE_PTN_REC_PAY';    -- XXCFO: 仕訳パターン_受払残高表
    cv_prof_je_ptn_rec_pay2        CONSTANT VARCHAR2(30)  := 'XXCFO1_JE_PTN_REC_PAY2';   -- XXCFO: 仕訳パターン_受払残高表2
    cv_prof_je_ptn_purchasing      CONSTANT VARCHAR2(30)  := 'XXCFO1_JE_PTN_PURCHASING'; -- XXCFO: 仕訳パターン_仕入実績表
    cv_prof_je_ptn_shipment        CONSTANT VARCHAR2(30)  := 'XXCFO1_JE_PTN_SHIPMENT';   -- XXCFO: 仕訳パターン_出荷実績表
    --
    --プロファイル値取得
    lv_je_ptn_invoice              fnd_profile_option_values.profile_option_value%TYPE;
    lv_je_dy_department            fnd_profile_option_values.profile_option_value%TYPE;
    lv_je_ptn_rec_pay              fnd_profile_option_values.profile_option_value%TYPE;
    lv_je_ptn_rec_pay2             fnd_profile_option_values.profile_option_value%TYPE;
    lv_je_ptn_purchasing           fnd_profile_option_values.profile_option_value%TYPE;
    lv_je_ptn_shipment             fnd_profile_option_values.profile_option_value%TYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    /*************************************
     *  プロファイル取得(A-1)            *
     *************************************/
    --
    -- XXCFO: 仕訳パターン表
    lv_je_ptn_invoice    :=  fnd_profile.value( cv_prof_je_ptn_invoice );
    --
    -- エラー処理
    -- 「XXCFO: 仕訳パターン表」取得失敗
    IF ( lv_je_ptn_invoice    IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(cv_appl_name_xxccp,
                                            cv_msg_cfo_00001,
                                            cv_tkn_prof_name,
                                            cv_prof_je_ptn_invoice);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- XXCFO: 動的部門抽出
    lv_je_dy_department    :=  fnd_profile.value( cv_prof_je_dy_department );
    --
    -- エラー処理
    -- 「XXCFO: 動的部門抽出」取得失敗
    IF ( lv_je_dy_department    IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(cv_appl_name_xxccp,
                                            cv_msg_cfo_00001,
                                            cv_tkn_prof_name,
                                            cv_prof_je_dy_department);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- XXCFO: 仕訳パターン_受払残高表
    lv_je_ptn_rec_pay    :=  fnd_profile.value( cv_prof_je_ptn_rec_pay );
    --
    -- エラー処理
    -- 「XXCFO: 仕訳パターン_受払残高表」取得失敗
    IF ( lv_je_ptn_rec_pay    IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(cv_appl_name_xxccp,
                                            cv_msg_cfo_00001,
                                            cv_tkn_prof_name,
                                            cv_prof_je_ptn_rec_pay);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- XXCFO: 仕訳パターン_受払残高表2
    lv_je_ptn_rec_pay2    :=  fnd_profile.value( cv_prof_je_ptn_rec_pay2 );
    --
    -- エラー処理
    -- 「XXCFO: 仕訳パターン_受払残高表2」取得失敗
    IF ( lv_je_ptn_rec_pay2    IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(cv_appl_name_xxccp,
                                            cv_msg_cfo_00001,
                                            cv_tkn_prof_name,
                                            cv_prof_je_ptn_rec_pay2);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- XXCFO: 仕訳パターン_仕入実績表
    lv_je_ptn_purchasing    :=  fnd_profile.value( cv_prof_je_ptn_purchasing );
    --
    -- エラー処理
    -- 「XXCFO: 仕訳パターン_仕入実績表」取得失敗
    IF ( lv_je_ptn_purchasing    IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(cv_appl_name_xxccp,
                                            cv_msg_cfo_00001,
                                            cv_tkn_prof_name,
                                            cv_prof_je_ptn_purchasing);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- XXCFO: 仕訳パターン_出荷実績表
    lv_je_ptn_shipment    :=  fnd_profile.value( cv_prof_je_ptn_shipment );
    --
    -- エラー処理
    -- 「XXCFO: 仕訳パターン_出荷実績表」取得失敗
    IF ( lv_je_ptn_shipment    IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(cv_appl_name_xxccp,
                                            cv_msg_cfo_00001,
                                            cv_tkn_prof_name,
                                            cv_prof_je_ptn_shipment);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
--
    /*************************************
     *  仕訳パターン表からの抽出 (A-2)   *
     *************************************/
    --
    BEGIN
        --仕訳パターン表取得SQL
        SELECT flvv.attribute8,         -- 会社
               flvv.attribute9,         -- 部門
               flvv.attribute10,        -- 勘定科目
               flvv.attribute11,        -- 補助科目
               flvv.attribute12         -- 摘要
        INTO   ov_company_code,
               ov_department_code,
               ov_account_title,
               ov_account_subsidiary,
               ov_description
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type  = lv_je_ptn_invoice        --仕訳パターン表
          AND    flvv.attribute1   = iv_report                --帳票
          AND    flvv.attribute2   = iv_class_code            --品目区分
--
          AND ((iv_report = lv_je_ptn_rec_pay                 --帳票：受払残高表1
              AND    flvv.attribute3   = iv_prod_class        --商品区分
              AND    flvv.attribute5   = iv_ptn_siwake        --仕訳パターン
              AND    flvv.attribute7   = iv_gloif_dr_cr       --借方・貸方
              )
          OR  (iv_report = lv_je_ptn_rec_pay2                 --帳票：受払残高表2
              AND    flvv.attribute3   = iv_prod_class        --商品区分
              AND    flvv.attribute4   = iv_reason_code       --事由
              AND    flvv.attribute5   = iv_ptn_siwake        --仕訳パターン
              AND    flvv.attribute7   = iv_gloif_dr_cr       --借方・貸方
              )
          OR  ((iv_report = lv_je_ptn_purchasing              --仕入実績表または出荷実績表
              OR iv_report = lv_je_ptn_shipment)
              AND    flvv.attribute5   = iv_ptn_siwake        --仕訳パターン
              AND    flvv.attribute6   = iv_line_no           --行番号
              ))
--
          AND    TRUNC( SYSDATE ) BETWEEN TRUNC( NVL( flvv.start_date_active, SYSDATE ) )
                                  AND     TRUNC( NVL( flvv.end_date_active, SYSDATE ) )
          AND    flvv.enabled_flag = cv_enabled_flag_enabled
        ;
--
    EXCEPTION
      WHEN  NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(cv_appl_name_xxcfo,
                                              cv_msg_cfo_10049,
                                              cv_tkn_report,
                                              iv_report,
                                              cv_tkn_hinmoku,
                                              iv_class_code,
                                              cv_tkn_shohin,
                                              iv_prod_class,
                                              cv_tkn_jiyuu,
                                              iv_reason_code,
                                              cv_tkn_siwake,
                                              iv_ptn_siwake,
                                              cv_tkn_gyou,
                                              iv_line_no,
                                              cv_tkn_taishaku,
                                              iv_gloif_dr_cr,
                                              cv_tkn_souko,
                                              iv_warehouse_code);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      WHEN  TOO_MANY_ROWS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(cv_appl_name_xxcfo,
                                              cv_msg_cfo_10050,
                                              cv_tkn_report,
                                              iv_report,
                                              cv_tkn_hinmoku,
                                              iv_class_code,
                                              cv_tkn_shohin,
                                              iv_prod_class,
                                              cv_tkn_jiyuu,
                                              iv_reason_code,
                                              cv_tkn_siwake,
                                              iv_ptn_siwake,
                                              cv_tkn_gyou,
                                              iv_line_no,
                                              cv_tkn_taishaku,
                                              iv_gloif_dr_cr,
                                              cv_tkn_souko,
                                              iv_warehouse_code);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      WHEN  OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    /*****************************************
     *  動的部門導出表からの部門の抽出 (A-3) *
     *****************************************/
    --仕訳パターン表から抽出した部門が「DEPARTMENT」の文字列と前方一致する場合
    IF ov_department_code LIKE cv_department THEN
        BEGIN
            --動的部門導出表取得SQL
            SELECT flvv.attribute3              -- 部門
            INTO   ov_department_code
            FROM   fnd_lookup_values_vl flvv
            WHERE  flvv.lookup_type  = lv_je_dy_department        --動的部門導出表
              AND    flvv.attribute1   = ov_department_code         --部門
              AND    flvv.attribute2   = iv_warehouse_code          --倉庫コード
              AND    TRUNC( SYSDATE ) BETWEEN TRUNC( NVL( flvv.start_date_active, SYSDATE ) )
                                      AND     TRUNC( NVL( flvv.end_date_active, SYSDATE ) )
              AND    flvv.enabled_flag = cv_enabled_flag_enabled
            ;
        EXCEPTION
          WHEN  NO_DATA_FOUND THEN
            --1回目の条件で部門が抽出できない場合「OTHERS」の文字列で再検索を行う
            BEGIN
                --動的部門導出表取得SQL
                SELECT flvv.attribute3          -- 部門
                INTO   ov_department_code
                FROM   fnd_lookup_values_vl flvv
                WHERE  flvv.lookup_type  = lv_je_dy_department    --動的部門導出表
                  AND    flvv.attribute1   = ov_department_code     --部門
                  AND    flvv.attribute2   = cv_others              --その他
                  AND    TRUNC( SYSDATE ) BETWEEN TRUNC( NVL( flvv.start_date_active, SYSDATE ) )
                                          AND     TRUNC( NVL( flvv.end_date_active, SYSDATE ) )
                  AND    flvv.enabled_flag = cv_enabled_flag_enabled
                ;
            EXCEPTION
              WHEN  NO_DATA_FOUND THEN
                ov_department_code := NULL;
              WHEN  TOO_MANY_ROWS THEN
                lv_errmsg := xxccp_common_pkg.get_msg(cv_appl_name_xxcfo,
                                                      cv_msg_cfo_10051,
                                                      cv_tkn_doutekibumon,
                                                      lv_je_dy_department,
                                                      cv_tkn_attribute1,
                                                      ov_department_code,
                                                      cv_tkn_attribute2_1,
                                                      NULL,
                                                      cv_tkn_attribute2_2,
                                                      cv_others);
                lv_errbuf := lv_errmsg;
                RAISE global_api_expt;
              WHEN  OTHERS THEN
                RAISE global_api_others_expt;
            END;
          WHEN  TOO_MANY_ROWS THEN
            lv_errmsg := xxccp_common_pkg.get_msg(cv_appl_name_xxcfo,
                                                  cv_msg_cfo_10051,
                                                  cv_tkn_doutekibumon,
                                                  lv_je_dy_department,
                                                  cv_tkn_attribute1,
                                                  ov_department_code,
                                                  cv_tkn_attribute2_1,
                                                  iv_warehouse_code,
                                                  cv_tkn_attribute2_2,
                                                  NULL);
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          WHEN  OTHERS THEN
            RAISE global_api_others_expt;
        END;
    END IF;
--
    /*****************************************
     *  OUTパラメータセット            (A-4) *
     *****************************************/
    --
    ov_retcode                  := cv_status_normal;   -- リターンコード
    ov_errbuf                   := NULL;               -- エラーメッセージ
    ov_errmsg                   := NULL;               -- ユーザー・エラーメッセージ
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_siwake_account_title;
--
END XXCFO020A06C;
/
