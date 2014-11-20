CREATE OR REPLACE PACKAGE BODY XXCOS017A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS017A01C(spec)
 * Description      : 補填・実卸単価チェック情報集計
 * MD.050           : 補填・実卸単価チェック情報集計 MD050_COS_017_A01
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  results_total          補填・実卸単価チェック情報集計(A-2)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/03/17    1.0   T.Nakabayashi    新規作成
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
  --  ===============================
  --  ユーザー定義例外
  --  ===============================
  --  *** プロファイル取得例外ハンドラ ***
  global_get_profile_expt       EXCEPTION;
  --  *** ロックエラー例外ハンドラ ***
  global_data_lock_expt         EXCEPTION;
  --  *** 対象データ無しエラー例外ハンドラ ***
  global_no_data_warm_expt      EXCEPTION;
  --  *** データ登録エラー例外ハンドラ ***
  global_insert_data_expt       EXCEPTION;
  --  *** データ更新エラー例外ハンドラ ***
  global_update_data_expt       EXCEPTION;--
  --  *** データ削除エラー例外ハンドラ ***
  global_delete_data_expt       EXCEPTION;--
--
  --
  PRAGMA  EXCEPTION_INIT(global_data_lock_expt, -54);
  -- ===============================
  -- ユーザー定義プライベート定数
  -- ===============================
--  パッケージ名
  cv_pkg_name                   CONSTANT  VARCHAR2(100)                                   :=  'XXCOS017A01C';
--
  --＠共通関連
  --  コンカレント名
  cv_conc_name                  CONSTANT  VARCHAR2(100)                                   :=  'XXCOS017A01C';
--
  --＠アプリケーション短縮名
  --  販物短縮アプリ名
  ct_xxcos_appl_short_name      CONSTANT  fnd_application.application_short_name%TYPE     :=  'XXCOS';
--
  --＠販物メッセージ
  --  ロック取得エラーメッセージ
  ct_msg_lock_err               CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-00001';
  --  プロファイル取得エラー
  ct_msg_get_profile_err        CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-00004';
  --  データ登録エラー
  ct_msg_insert_data_err        CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-00010';
  --  データ更新エラー
  ct_msg_update_data_err        CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-00011';
  --  データ削除エラーメッセージ
  ct_msg_delete_data_err        CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-00012';
  --  API呼出エラーメッセージ
  ct_msg_call_api_err           CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-00017';
  --  明細0件用メッセージ
  ct_msg_nodata_err             CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-00003';
  --  ＳＶＦ起動ＡＰＩ
  ct_msg_svf_api                CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-00041';
  --  要求ＩＤ
  ct_msg_request                CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-00042';
--
  --＠機能固有メッセージ
  --  パラメータ出力
  ct_msg_parameter_note         CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-13701';
  --  品目コード・実卸単価必須指定エラー
  ct_msg_must_unit_and_price    CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-13702';
  --  実卸単価不正エラー
  ct_msg_invalid_unit_price     CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-13703';
  --  補填・卸単価チェック情報作成件数
  ct_msg_count_create           CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-13704';
  --  品目存在チェックエラー
  ct_msg_err_no_item_found      CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-13705';
--
  --＠クイックコード
  --  クイックコード（売上区分）
  ct_qct_sale_type
    CONSTANT  fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_SALE_CLASS';
  --  クイックコード（売上区分特定マスタ）
  ct_qct_sale_mst_type
    CONSTANT  fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_SALE_CLASS_MST_017_A01';
  ct_qcc_sale_mst_base_code
    CONSTANT  fnd_lookup_values.lookup_code%TYPE := 'XXCOS_017_A01_';
  --  クイックコード（非在庫品目マスタ）
  ct_qct_no_inv_item
    CONSTANT  fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_NO_INV_ITEM_CODE';
  --  クイックコード（出力ヘッダ）
  ct_qct_output_header
    CONSTANT  fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_OUTPUT_HEADER_017_A01';
--
  --＠固定値
  --  検索用（match any）
  cv_match_any                  CONSTANT  VARCHAR2(1) := '%';
  ct_max_unit_price             CONSTANT  xxcos_sales_exp_lines.standard_unit_price%TYPE := 99999999999.99;
  cv_tab                        CONSTANT  VARCHAR2(1) := CHR(9);
--
  --＠Yes/No
  cv_yes                        CONSTANT  VARCHAR2(1) := 'Y';
  cv_no                         CONSTANT  VARCHAR2(1) := 'N';
--
  --＠パラメータ日付指定書式
  cv_fmt_date_default           CONSTANT  VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS';
  cv_fmt_time_default           CONSTANT  VARCHAR2(7) := 'HH24:MI';
  cv_fmt_date                   CONSTANT  VARCHAR2(8) := 'YYYYMMDD';
  cv_fmt_date_profile           CONSTANT  VARCHAR2(10) := 'YYYY/MM/DD';
  cv_fmt_years_in               CONSTANT  VARCHAR2(7) := 'YYYY/MM';
  cv_fmt_years                  CONSTANT  VARCHAR2(6) := 'YYYYMM';
--
  --＠トークン
  --  集計対象年月
  cv_tkn_para_years_for_total   CONSTANT  VARCHAR2(020) := 'PARAM1';
  --  処理区分
  cv_tkn_para_processing_class  CONSTANT  VARCHAR2(020) := 'PARAM2';
  -- 品目コード
  cv_tkn_para_item_code         CONSTANT  VARCHAR2(020) := 'PARAM3';
  --  実卸単価
  cv_tkn_para_unit_price        CONSTANT  VARCHAR2(020) := 'PARAM4';
  --  作成件数
  cv_tkn_create_count           CONSTANT  VARCHAR2(020) := 'CREATE_COUNT';
  -- 品目コード
  cv_tkn_item_code              CONSTANT  VARCHAR2(020) := 'ITEM_CODE';
--
  --＠パラメータ識別用
  --  「1：補填」
  cv_para_amends                CONSTANT  VARCHAR2(1) := '1';
  --  「2：実卸単価チェック情報集計」
  cv_para_unit_price_check      CONSTANT  VARCHAR2(1) := '2';
--
  --  ===============================
  --  ユーザー定義プライベート型
  --  ===============================
--
  --  ===============================
  --  ユーザー定義プライベート変数
  --  ===============================
  --＠共通データ格納用
  --  共通データ．抽出年月月初(date型)
  gt_common_first_date                    xxcos_sales_exp_headers.delivery_date%TYPE;
  --  共通データ．抽出年月月末(date型)
  gt_common_last_date                     xxcos_sales_exp_headers.delivery_date%TYPE;
  --  共通データ．参照コード
  gt_common_lookup_code                   fnd_lookup_values.lookup_code%TYPE;
  --  共通データ．品目コード
  gt_common_item_no                       ic_item_mst_b.item_no%TYPE;
  --  共通データ．卸単価
  gt_common_wholesale_unit_price          xxcos_sales_exp_lines.standard_unit_price%TYPE;
  --  ===============================
  --  ユーザー定義プライベート・カーソル
  --  ===============================
  --  出力ヘッダ情報
  CURSOR  header_cur
  IS
    SELECT
            xlhe.description              AS  description
    FROM    xxcos_lookup_values_v     xlhe
    WHERE   xlhe.lookup_type          =       ct_qct_output_header
    ORDER BY
            xlhe.lookup_code
    ;
--
  --  販売実績情報
  CURSOR  sales_cur     (
                        icp_first_date          DATE,
                        icp_last_date           DATE,
                        icp_item_no             VARCHAR2,
                        icp_unit_price          NUMBER,
                        icp_017a01_lookup_code  VARCHAR2
                        )
  IS
    SELECT
            saeh.sales_base_code          AS  base_code,
            base.account_name             AS  base_name,
            saeh.ship_to_customer_code    AS  party_num,
            hzca.account_name             AS  party_name,
            sael.item_code                AS  item_code,
            ximb.item_short_name          AS  item_name,
            SUM(
                CASE  xlsa.attribute5
                  WHEN  cv_no             THEN  sael.standard_qty
                                          ELSE  0
                END
                )                         AS  sale_qty,
            SUM(sael.pure_amount)         AS  pure_amount,
            DECODE(
                  SUM(
                      CASE  xlsa.attribute5
                        WHEN  cv_no             THEN  sael.standard_qty
                                                ELSE  0
                      END
                      )
                  , 0,  0
                     ,  ROUND(SUM(sael.pure_amount) 
                            / SUM(
                                  CASE  xlsa.attribute5
                                    WHEN  cv_no             THEN  sael.standard_qty
                                                            ELSE  0
                                  END
                                  )
                              , 2))             AS  wholesale_unit_price,
            SUM(
                CASE  xlsa.attribute5
                  WHEN  cv_yes            THEN  sael.standard_qty
                                          ELSE  0
                END
                )                         AS  support_qty,
            DECODE(SUM(sael.standard_qty), 0,  0
                  ,ROUND(SUM(sael.pure_amount) / SUM(sael.standard_qty), 2))
                                          AS  real_wholesale_unit_price
    FROM    xxcos_sales_exp_headers   saeh,
            xxcos_sales_exp_lines     sael,
            hz_cust_accounts          hzca,
            hz_cust_accounts          base,
            ic_item_mst_b             iimb,
            xxcmn_item_mst_b          ximb,
            xxcos_lookup_values_v     xlsa,
            xxcos_lookup_values_v     xltk
    WHERE   saeh.delivery_date        BETWEEN icp_first_date
                                      AND     icp_last_date
    AND     sael.sales_exp_header_id  =       saeh.sales_exp_header_id
    AND     hzca.account_number       =       saeh.ship_to_customer_code
    AND     base.account_number       =       saeh.sales_base_code
    AND     sael.item_code            LIKE    icp_item_no
    AND     iimb.item_no              =       sael.item_code
    AND     ximb.item_id              =       iimb.item_id
    AND     icp_last_date             BETWEEN ximb.start_date_active
                                      AND     NVL(ximb.end_date_active, icp_last_date)
    AND     xlsa.lookup_type          =       ct_qct_sale_type
    AND     xlsa.lookup_code          =       sael.sales_class
    AND     icp_last_date             BETWEEN NVL(xlsa.start_date_active, icp_last_date)
                                      AND     NVL(xlsa.end_date_active,   icp_last_date)
    AND     xltk.lookup_type          =       ct_qct_sale_mst_type
    AND     xltk.lookup_code          LIKE    icp_017a01_lookup_code
    AND     xltk.meaning              =       sael.sales_class
    AND     icp_last_date             BETWEEN NVL(xltk.start_date_active, icp_last_date)
                                      AND     NVL(xltk.end_date_active,   icp_last_date)
    AND NOT EXISTS  (
                    SELECT  xlni.ROWID
                    FROM    xxcos_lookup_values_v     xlni
                    WHERE   xlni.lookup_type          =       ct_qct_no_inv_item
                    AND     xlni.lookup_code          =       sael.item_code
                    AND     icp_last_date             BETWEEN NVL(xlni.start_date_active, icp_last_date)
                                                      AND     NVL(xlni.end_date_active,   icp_last_date)
                    AND     ROWNUM                    =       1
                    )
    GROUP BY
            saeh.sales_base_code,
            base.account_name,
            saeh.ship_to_customer_code,
            hzca.account_name,
            sael.item_code,
            ximb.item_short_name
    HAVING  DECODE(SUM(sael.standard_qty), 0,  0
                  ,ROUND(SUM(sael.pure_amount) / SUM(sael.standard_qty), 2))  < icp_unit_price
    ORDER BY
            saeh.sales_base_code,
            saeh.ship_to_customer_code,
            sael.item_code
    ;
--
  --  ===============================
  --  ユーザー定義プライベート型
  --  ===============================
  --  販売実績実績情報 テーブルタイプ
  TYPE  g_sales_ttype             IS  TABLE OF  sales_cur%ROWTYPE              INDEX BY  PLS_INTEGER;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_years_for_total            IN      VARCHAR2,         --  1.集計対象年月
    iv_processing_class           IN      VARCHAR2,         --  2.処理区分
    iv_item_code                  IN      VARCHAR2,         --  3.品目コード
    iv_real_wholesale_unit_price  IN      VARCHAR2,         --  4.実卸単価
    ov_errbuf                     OUT     VARCHAR2,         --  エラー・メッセージ           --# 固定 #
    ov_retcode                    OUT     VARCHAR2,         --  リターン・コード             --# 固定 #
    ov_errmsg                     OUT     VARCHAR2)         --  ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- プログラム名
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
    -- *** ローカル変数 ***
    --パラメータ出力用
    lv_para_msg                 VARCHAR2(5000);
--
    --品目マスタ存在チェック用
    lt_item_no                  ic_item_mst_b.item_no%TYPE;
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
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
    --==================================
    -- 1.入力パラメータ出力
    --==================================
    lv_para_msg     :=  xxccp_common_pkg.get_msg(
      iv_application   =>  ct_xxcos_appl_short_name,
      iv_name          =>  ct_msg_parameter_note,
      iv_token_name1   =>  cv_tkn_para_years_for_total,
      iv_token_value1  =>  iv_years_for_total,
      iv_token_name2   =>  cv_tkn_para_processing_class,
      iv_token_value2  =>  iv_processing_class,
      iv_token_name3   =>  cv_tkn_para_item_code,
      iv_token_value3  =>  iv_item_code,
      iv_token_name4   =>  cv_tkn_para_unit_price,
      iv_token_value4  =>  iv_real_wholesale_unit_price
      );
--
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.LOG
      ,buff   =>  lv_para_msg
    );
--
    --  1行空白
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.LOG
      ,buff   =>  NULL
    );
--
    --==================================
    -- 2.基準日付取得
    --==================================
    gt_common_first_date  :=  TO_DATE(iv_years_for_total, cv_fmt_years_in);
    gt_common_last_date   :=  LAST_DAY(gt_common_first_date);
    gt_common_lookup_code :=  ct_qcc_sale_mst_base_code
                          ||  iv_processing_class
                          ||  cv_match_any;
--
    IF  ( iv_processing_class = cv_para_unit_price_check  ) THEN
      --  基準日付取得(「2：実卸単価チェック情報集計」の場合)
      gt_common_item_no   :=  iv_item_code;
--
      BEGIN
        gt_common_wholesale_unit_price    :=  ROUND(TO_NUMBER(iv_real_wholesale_unit_price), 2);
      EXCEPTION
        -- *** OTHERS例外ハンドラ ***
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
            iv_application        =>  ct_xxcos_appl_short_name,
            iv_name               =>  ct_msg_invalid_unit_price
            );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    ELSE
      --  基準日付取得(「2：実卸単価チェック情報集計」以外の場合)
      gt_common_item_no               :=  cv_match_any;
      gt_common_wholesale_unit_price  :=  ct_max_unit_price;
    END IF;
--
    --==================================
    -- 3.入力パラメータチェック
    --==================================
    IF  ( iv_processing_class             =   cv_para_unit_price_check  ) THEN
      --  出力区分が「2：実卸単価チェック情報集計」の時、品目・実卸単価に指定が無い場合はエラー
      IF  (   iv_item_code                  IS  NULL 
          OR  iv_real_wholesale_unit_price  IS  NULL  ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application        =>  ct_xxcos_appl_short_name,
          iv_name               =>  ct_msg_must_unit_and_price
          );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
--
      --  出力区分が「2：実卸単価チェック情報集計」の時、品目がマスタに無い場合はエラー
      BEGIN
        SELECT  iimb.item_no
        INTO    lt_item_no
        FROM    ic_item_mst_b             iimb,
                xxcmn_item_mst_b          ximb
        WHERE   iimb.item_no              =       gt_common_item_no
        AND     ximb.item_id              =       iimb.item_id
        AND     gt_common_last_date       BETWEEN ximb.start_date_active
                                          AND     NVL(ximb.end_date_active, gt_common_last_date)
        ;
      EXCEPTION
        -- *** OTHERS例外ハンドラ ***
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
            iv_application        =>  ct_xxcos_appl_short_name,
            iv_name               =>  ct_msg_err_no_item_found,
            iv_token_name1        =>  cv_tkn_item_code,
            iv_token_value1       =>  gt_common_item_no
            );
          lv_errbuf := SQLERRM;
          RAISE global_process_expt;
      END;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
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
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : summary_sales_results
   * Description      : 補填・実卸単価チェック情報集計 (A-2)
   ***********************************************************************************/
  PROCEDURE summary_sales_results(
    ov_errbuf             OUT     VARCHAR2,         --   エラー・メッセージ                  --# 固定 #
    ov_retcode            OUT     VARCHAR2,         --   リターン・コード                    --# 固定 #
    ov_errmsg             OUT     VARCHAR2)         --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'summary_sales_results'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    -- *** ローカル変数 ***
--
    -- 納品実績情報 テーブル型
    l_sales_tab                           g_sales_ttype;
--
    -- 出力内容編集
    lv_output                             VARCHAR2(5000);
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
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
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
    --  ===============================
    --  A-2.1 ヘッダ出力
    --  ===============================
    --  ヘッダ編集
    FOR l_header_rec  IN  header_cur
    LOOP
      IF  ( header_cur%ROWCOUNT = 1 ) THEN
        lv_output :=  l_header_rec.description;
      ELSE
        lv_output :=  lv_output
                  ||  cv_tab
                  ||  l_header_rec.description;
      END IF;
    END LOOP;
--
    --  ヘッダ出力
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.OUTPUT
      ,buff   =>  lv_output
    );
--
    --  ===============================
    --  A-2.2 補填・実卸単価チェック情報集計
    --  ===============================
    --  カーソルオープン
    OPEN  sales_cur (
                    gt_common_first_date,
                    gt_common_last_date,
                    gt_common_item_no,
                    gt_common_wholesale_unit_price,
                    gt_common_lookup_code
                    );
--
    -- レコード読み込み
    FETCH sales_cur BULK COLLECT  INTO  l_sales_tab;
--
    -- 対象件数取得
    gn_target_cnt   :=  l_sales_tab.COUNT;
--
    -- カーソルクローズ
    CLOSE sales_cur;
--
--
    --  0件の場合登録処理をスキップ
    IF  ( l_sales_tab.COUNT <>  0 ) THEN
--
      <<sales_data_create>>
      FOR lp_idx IN l_sales_tab.FIRST..l_sales_tab.LAST LOOP
        lv_output :=  l_sales_tab(lp_idx).base_code
                  ||  cv_tab
                  ||  l_sales_tab(lp_idx).base_name
                  ||  cv_tab
                  ||  l_sales_tab(lp_idx).party_num
                  ||  cv_tab
                  ||  l_sales_tab(lp_idx).party_name
                  ||  cv_tab
                  ||  l_sales_tab(lp_idx).item_code
                  ||  cv_tab
                  ||  l_sales_tab(lp_idx).item_name
                  ||  cv_tab
                  ||  l_sales_tab(lp_idx).sale_qty
                  ||  cv_tab
                  ||  l_sales_tab(lp_idx).pure_amount
                  ||  cv_tab
                  ||  l_sales_tab(lp_idx).wholesale_unit_price
                  ||  cv_tab
                  ||  l_sales_tab(lp_idx).support_qty
                  ||  cv_tab
                  ||  l_sales_tab(lp_idx).real_wholesale_unit_price
        ;
--
          FND_FILE.PUT_LINE(
             which  =>  FND_FILE.OUTPUT
            ,buff   =>  lv_output
          );
      END LOOP  sales_data_create;
--
    --  0件の場合登録処理をスキップ
    END IF;
--
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
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
--#####################################  固定部 END   ##########################################
--
  END summary_sales_results;
--
  /**********************************************************************************
   * Procedure Name   : end_process
   * Description      : 終了処理(A-3)
   ***********************************************************************************/
  PROCEDURE end_process(
    ov_errbuf         OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'end_process'; -- プログラム名
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
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
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
    --==================================
    -- 1.処理件数メッセージ編集  （補填・卸単価チェック情報）
    --==================================
    lv_errmsg := xxccp_common_pkg.get_msg(
      iv_application => ct_xxcos_appl_short_name,
      iv_name        => ct_msg_count_create,
      iv_token_name1 => cv_tkn_create_count,
      iv_token_value1=> gn_target_cnt
      );
    --  処理件数メッセージ出力
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.LOG
      ,buff   =>  lv_errmsg
    );
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END end_process;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_years_for_total            IN      VARCHAR2,         --  1.集計対象年月
    iv_processing_class           IN      VARCHAR2,         --  2.処理区分
    iv_item_code                  IN      VARCHAR2,         --  3.品目コード
    iv_real_wholesale_unit_price  IN      VARCHAR2,         --  4.実卸単価
    ov_errbuf                     OUT     VARCHAR2,         --   エラー・メッセージ           --# 固定 #
    ov_retcode                    OUT     VARCHAR2,         --   リターン・コード             --# 固定 #
    ov_errmsg                     OUT     VARCHAR2)         --   ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
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
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    --  ===============================
    --  <処理部、ループ部名> (処理結果によって後続処理を制御する場合)
    --  ===============================
    init(
      iv_years_for_total
      ,iv_processing_class
      ,iv_item_code
      ,iv_real_wholesale_unit_price
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF  ( lv_retcode = cv_status_error  ) THEN
      --  (エラー処理)
      RAISE global_process_expt;
    END IF;
--
    --  ===============================
    --  補填・実卸単価チェック情報集計(A-2)
    --  ===============================
   summary_sales_results(
      lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF  ( lv_retcode = cv_status_error  ) THEN
      --(エラー処理)
--
      --  カーソルクローズ
      IF  ( sales_cur%ISOPEN ) THEN
        CLOSE sales_cur;
      END IF;
--
      RAISE global_process_expt;
    END IF;
--
    --  ===============================
    --  終了処理(A-3)
    --  ===============================
    end_process(
      lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF  ( lv_retcode = cv_status_error  ) THEN
      --  (エラー処理)
      RAISE global_process_expt;
    END IF;
--
    --  本機能は対象件数＝正常件数とする
    gn_normal_cnt :=  gn_target_cnt;
--
    --明細０件時の警告終了制御
    IF ( gn_target_cnt = 0 ) THEN
      ov_retcode := cv_status_warn;
      --  対象データなし
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                                            iv_application          => ct_xxcos_appl_short_name,
                                            iv_name                 => ct_msg_nodata_err
                                            );
      --  空行出力
      FND_FILE.PUT_LINE(
         which  =>  FND_FILE.LOG
        ,buff   =>  NULL
      );
      --  対象データなしメッセージ出力
      FND_FILE.PUT_LINE(
         which  =>  FND_FILE.LOG
        ,buff   =>  lv_errmsg
      );
    END IF;
--
  EXCEPTION
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
    errbuf                        OUT     VARCHAR2,         --  エラーメッセージ #固定#
    retcode                       OUT     VARCHAR2,         --  エラーコード     #固定#
    iv_years_for_total            IN      VARCHAR2,         --  1.集計対象年月
    iv_processing_class           IN      VARCHAR2,         --  2.処理区分
    iv_item_code                  IN      VARCHAR2,         --  3.品目コード
    iv_real_wholesale_unit_price  IN      VARCHAR2          --  4.実卸単価
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
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
--    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-91003'; -- エラー終了
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- コンカレントヘッダメッセージ出力先：出力
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- コンカレントヘッダメッセージ出力先：ログ(帳票のみ)
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
/*
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log_header_log
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
*/
--###########################  固定部 END   #############################
--
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log_header_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      iv_years_for_total
      ,iv_processing_class
      ,iv_item_code
      ,iv_real_wholesale_unit_price
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
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
END XXCOS017A01C;
/
