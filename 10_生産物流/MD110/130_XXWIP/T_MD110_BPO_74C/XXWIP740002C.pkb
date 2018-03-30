CREATE OR REPLACE PACKAGE BODY xxwip740002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWIP740004(body)
 * Description      : 請求書
 * MD.050/070       : 請求書(T_MD050_BPO_740)
 *                    請求書(T_MD070_BPO_74C)
 * Version          : 1.2
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  prc_chk_param               PROCEDURE : パラメータチェック (C-1)
 *  prc_get_data                PROCEDURE : データ取得 (C-2)
 *  prc_create_xml_data         PROCEDURE : ＸＭＬデータ編集 (C-3)
 *  convert_into_xml            FUNCTION  : ＸＭＬタグに変換する。
 *  submain                     PROCEDURE : メイン処理プロシージャ
 *  main                        PROCEDURE : コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/25    1.0   Yusuke Tabata   新規作成
 *  2008/07/02    1.1   Satoshi Yunba   禁則文字対応
 *  2018/03/30    1.2   Sasaki Hiroyuki E_本稼動_14942対応
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0' ;
  gv_status_warn   CONSTANT VARCHAR2(1) := '1' ;
  gv_status_error  CONSTANT VARCHAR2(1) := '2' ;
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ' ;
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ###############################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
--################################  固定部 END   ###############################
--
  -- ===============================================================================================
  -- ユーザー宣言部
  -- ===============================================================================================
  -- ==================================================
  -- グローバル定数
  -- ==================================================
  gc_pkg_name             CONSTANT VARCHAR2(20) := 'xxwip740004C' ;         -- パッケージ名
  gc_report_id            CONSTANT VARCHAR2(20) := 'xxwip740004T' ;         -- 帳票ID
  gc_application          CONSTANT VARCHAR2(5)  := 'XXCMN' ;                -- アプリケーション
  gc_application_wip      CONSTANT VARCHAR2(5)  := 'XXWIP' ;                -- アプリケーション
  gc_err_code_no_data     CONSTANT VARCHAR2(15) := 'APP-XXCMN-10122' ;      -- データ０件メッセージ
  gc_err_code_date_false  CONSTANT VARCHAR2(15) := 'APP-XXCMN-10012' ;      -- 日付不正エラーメッセージ
  gc_err_code_future_date CONSTANT VARCHAR2(15) := 'APP-XXWIP-10020' ;      -- 未来月エラー
  gc_msg_item             CONSTANT VARCHAR2(4)  := 'ITEM' ;
  gc_msg_value            CONSTANT VARCHAR2(5)  := 'VALUE';
  gc_column_billing_date  CONSTANT VARCHAR2(8) := '請求年月';
--
  -- 年月日マスク
  gc_date_mask_s          CONSTANT VARCHAR2(7)  := 'YYYY/MM' ;
  gc_date_mask            CONSTANT VARCHAR2(10) := 'YYYY/MM/DD' ;
  -- 年月日(JA)マスク
  gc_date_mask_ja         CONSTANT VARCHAR2(30) := 'YYYY"年"MM"月"DD"日"' ;
  -- 年月日(JA)マスク空白有
  gc_date_mask_ja_l       CONSTANT VARCHAR2(40) := 'YYYY"  年  "MM"  月  "DD"  日"';
  -- 出力
  gc_tag_type_t           CONSTANT VARCHAR2(1)  := 'T' ;
  gc_tag_type_d           CONSTANT VARCHAR2(1)  := 'D' ;
--  2018/03/30 V1.2 Added START
  cv_prf_xxwip_740002c_bank   CONSTANT VARCHAR2(30) :=  'XXWIP_740002C_BANK';             --  XXWIP:請求書用銀行情報
--  2018/03/30 V1.2 Added END
--
  -- ==================================================
  -- ユーザー定義グローバル型
  -- ==================================================
--
  -- 入力パラメータ格納用レコード変数
  TYPE rec_param_data  IS RECORD
    (
       billing_code   VARCHAR2(15)  -- 01 : 請求先
      ,billing_date   VARCHAR2(6)   -- 02 : 請求年月
    ) ;
--
  -- 抽出データ格納用レコード変数
  TYPE rec_data_type_dtl IS RECORD
    (
       post_no                  xxwip_billing_mst.post_no%TYPE                  -- 郵便番号
      ,address                  xxwip_billing_mst.address%TYPE                  -- 住所
      ,billing_name             xxwip_billing_mst.billing_name%TYPE             -- 請求先名
      ,billing_date             xxwip_billing_mst.billing_date%TYPE             -- 請求年月
      ,last_month_charge_amount xxwip_billing_mst.last_month_charge_amount%TYPE -- 前月請求額
      ,amount_receipt_money     xxwip_billing_mst.amount_receipt_money%TYPE     -- 今回入金金額
      ,amount_adjustment        xxwip_billing_mst.amount_adjustment%TYPE        -- 調整額
      ,balance_carried_forward  xxwip_billing_mst.balance_carried_forward%TYPE  -- 繰越額
      ,charged_amount           xxwip_billing_mst.charged_amount%TYPE           -- 今回請求金額
      ,charged_amount_total     xxwip_billing_mst.charged_amount_total%TYPE     -- 請求金額合計
      ,month_sales              xxwip_billing_mst.month_sales%TYPE              -- 今月売上額
      ,consumption_tax          xxwip_billing_mst.consumption_tax%TYPE          -- 消費税
      ,congestion_charge        xxwip_billing_mst.congestion_charge%TYPE        -- 通行料等
      ,condition_setting_date   xxwip_billing_mst.condition_setting_date%TYPE   -- 支払条件設定日
    ) ;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gr_param              rec_param_data ;      -- パラメータ
  gr_dtl_data           rec_data_type_dtl ;   -- 抽出データ
  gn_data_cnt           NUMBER DEFAULT 0 ;    -- 処理データカウンタ
--
  gt_xml_data_table     XML_DATA ;            -- ＸＭＬデータタグ表
  gl_xml_idx            NUMBER  := 0 ;        -- ＸＭＬデータタグ表のインデックス
--
--#####################  固定共通例外宣言部 START   ####################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION ;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION ;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION ;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000) ;
--
--###########################  固定部 END   ############################
--
  /************************************************************************************************
   * Procedure Name   : prc_chk_param
   * Description      : パラメータチェック(C-1)
   ************************************************************************************************/
  PROCEDURE prc_chk_param
    (
      ov_errbuf             OUT VARCHAR2          --    エラー・メッセージ           --# 固定 #
     ,ov_retcode            OUT VARCHAR2          --    リターン・コード             --# 固定 #
     ,ov_errmsg             OUT VARCHAR2          --    ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ==================================================
    -- 固定ローカル定数
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_chk_param' ; -- プログラム名
--
--##### 固定ローカル変数宣言部 START #################################
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--##### 固定ローカル変数宣言部 END   #################################
--
    -- ==================================================
    -- 変数宣言
    -- ==================================================
    ln_cnt          NUMBER DEFAULT 0    ;
    ld_billing_date DATE   DEFAULT NULL ;
        -- *** ローカル・例外処理 ***
    date_false_expt      EXCEPTION ;     -- 日付不正エラー
    future_date_expt     EXCEPTION ;     -- 未来月チェックエラー
  BEGIN
--
--##### 固定ステータス初期化部 START #################################
    ov_retcode := gv_status_normal;
--##### 固定ステータス初期化部 END   #################################
--
    ld_billing_date := FND_DATE.STRING_TO_DATE(gr_param.billing_date,gc_date_mask_s);
    -- 日付妥当性チェック
    IF (ld_billing_date IS NULL) THEN
      RAISE date_false_expt;
    -- 未来月チェック
    ELSIF (LAST_DAY(SYSDATE) < ld_billing_date) THEN
      RAISE future_date_expt;
    END IF ;
--
  EXCEPTION
    WHEN date_false_expt THEN
      ov_errmsg  := xxcmn_common_pkg.get_msg( gc_application
                                             ,gc_err_code_date_false
                                             ,gc_msg_item
                                             ,gc_column_billing_date
                                             ,gc_msg_value
                                             ,gr_param.billing_date) ;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    WHEN future_date_expt THEN
      ov_errmsg  := xxcmn_common_pkg.get_msg( gc_application_wip
                                             ,gc_err_code_future_date
                                             ,gc_msg_item
                                             ,gc_column_billing_date
                                             ,gc_msg_value
                                             ,gr_param.billing_date) ;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
--##### 固定例外処理部 START #######################################################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### 固定例外処理部 END   #######################################################################
  END prc_chk_param ;
--
  /************************************************************************************************
   * Procedure Name   : prc_get_data(C-2)
   * Description      : データ取得
   ************************************************************************************************/
  PROCEDURE prc_get_data
    (
      ov_errbuf             OUT VARCHAR2          --    エラー・メッセージ           --# 固定 #
     ,ov_retcode            OUT VARCHAR2          --    リターン・コード             --# 固定 #
     ,ov_errmsg             OUT VARCHAR2          --    ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ==================================================
    -- 固定ローカル定数
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_data' ; -- プログラム名
--
--##### 固定ローカル変数宣言部 START #################################
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--##### 固定ローカル変数宣言部 END   #################################
--
    -- ==================================================
    -- 変数宣言
    -- ==================================================
    lr_get_data   rec_data_type_dtl;
    -- *** ローカル・例外処理 ***
    dtldata_notfound_expt      EXCEPTION ;     -- 対象データ0件例外
--
  BEGIN
--
--##### 固定ステータス初期化部 START #################################
    ov_retcode := gv_status_normal;
--##### 固定ステータス初期化部 END   #################################
--
    -- データ取得対象の存在チェック
    SELECT
    COUNT(xbm.billing_mst_id)
    INTO gn_data_cnt
    FROM
    xxwip_billing_mst xbm
    WHERE
        xbm.billing_code = gr_param.billing_code
    AND xbm.billing_date = gr_param.billing_date
    ;
--
    IF (gn_data_cnt <> 0) THEN
      SELECT
       xbm.post_no                  -- 郵便番号
      ,xbm.address                  -- 住所
      ,xbm.billing_name             -- 請求先名
      ,xbm.billing_date             -- 請求年月
      ,xbm.last_month_charge_amount -- 前月請求額
      ,xbm.amount_receipt_money     -- 今回入金金額
      ,xbm.amount_adjustment        -- 調整額
      ,xbm.balance_carried_forward  -- 繰越額
      ,xbm.charged_amount           -- 今回請求金額
      ,xbm.charged_amount_total     -- 請求金額合計
      ,xbm.month_sales              -- 今月売上額
      ,xbm.consumption_tax          -- 消費税
      ,xbm.congestion_charge        -- 通行料等
      ,xbm.condition_setting_date   -- 支払条件設定日
      INTO
       gr_dtl_data.post_no                  -- 郵便番号
      ,gr_dtl_data.address                  -- 住所
      ,gr_dtl_data.billing_name             -- 請求先名
      ,gr_dtl_data.billing_date             -- 請求年月
      ,gr_dtl_data.last_month_charge_amount -- 前月請求額
      ,gr_dtl_data.amount_receipt_money     -- 今回入金金額
      ,gr_dtl_data.amount_adjustment        -- 調整額
      ,gr_dtl_data.balance_carried_forward  -- 繰越額
      ,gr_dtl_data.charged_amount           -- 今回請求金額
      ,gr_dtl_data.charged_amount_total     -- 請求金額合計
      ,gr_dtl_data.month_sales              -- 今月売上額
      ,gr_dtl_data.consumption_tax          -- 消費税
      ,gr_dtl_data.congestion_charge        -- 通行料等
      ,gr_dtl_data.condition_setting_date   -- 支払条件設定日
      FROM
      xxwip_billing_mst xbm             --請求先アドオンマスタ
      WHERE
          xbm.billing_code = gr_param.billing_code
      AND xbm.billing_date = gr_param.billing_date
      ;
    END IF;
--
  EXCEPTION
--
    -- *** 対象データ0件例外ハンドラ ***
    WHEN dtldata_notfound_expt THEN
      ov_retcode := gv_status_warn ;
--##### 固定例外処理部 START #######################################################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### 固定例外処理部 END   #######################################################################
  END prc_get_data ;
--
   /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : ＸＭＬデータ作成(C-3)
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data
    (
      ov_errbuf         OUT NOCOPY VARCHAR2         -- エラー・メッセージ
     ,ov_retcode        OUT NOCOPY VARCHAR2         -- リターン・コード
     ,ov_errmsg         OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ
    )
  IS
--
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_create_xml_data' ; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000) ;  -- エラー・メッセージ
    lv_retcode VARCHAR2(1) ;     -- リターン・コード
    lv_errmsg  VARCHAR2(5000) ;  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- =====================================================
    -- ユーザー宣言部
    -- =====================================================
    -- *** ローカル変数 ***
    lv_addrress_01     VARCHAR2(30) DEFAULT NULL ;
    lv_addrress_02     VARCHAR2(31) DEFAULT NULL ;
    lv_billing_name_01 VARCHAR2(30) DEFAULT NULL ;
    lv_billing_name_02 VARCHAR2(31) DEFAULT NULL ;
    ld_billing_date    DATE         DEFAULT NULL ;
--
  BEGIN
--
    -- ---------------------------------
    -- 初期処理
    -- ---------------------------------
    -- 住所を30Byteで分割
    lv_addrress_01     := SUBSTRB(gr_dtl_data.address,1,30) ;
    lv_addrress_02     := SUBSTR(gr_dtl_data.address,LENGTH(lv_addrress_01)+1,60);
    -- 請求先名を30Byteで分割
    lv_billing_name_01 := SUBSTRB(gr_dtl_data.billing_name,1,30) ;
    lv_billing_name_02 := SUBSTR(gr_dtl_data.billing_name,LENGTH(lv_billing_name_01)+1,60) ;
    -- 請求日から請求開始日へ置換
    ld_billing_date    := FND_DATE.STRING_TO_DATE(gr_param.billing_date,'YYYY/MM') ;
--
    -- 発行年月日
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_date';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value
      := TO_CHAR(SYSDATE,gc_date_mask_ja_l);
    -- 請求先郵便番号
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'post_no';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gr_dtl_data.post_no;
    -- 請求先住所１
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'address_01';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := lv_addrress_01;
    -- 請求先住所２
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'address_02';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := lv_addrress_02;
    -- 請求先名１
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'billing_name_01';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := lv_billing_name_01;
    -- 請求先名２
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'billing_name_02';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := lv_billing_name_02;
    -- 締切年月日
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'billing_date';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value
      := TO_CHAR(LAST_DAY(ld_billing_date),gc_date_mask_ja_l);
    -- 前月請求残高
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'last_month_charge_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gr_dtl_data.last_month_charge_amount;
    -- 今回入金額
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'amount_receipt_money';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gr_dtl_data.amount_receipt_money;
    -- 調整額
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'amount_adjustment';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gr_dtl_data.amount_adjustment;
    -- 繰越額
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'balance_carried_forward';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gr_dtl_data.balance_carried_forward;
    -- 今回請求額
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'charged_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gr_dtl_data.charged_amount;
    -- 合計請求額
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'charged_amount_total';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gr_dtl_data.charged_amount_total;
    -- 請求年月日FROM
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'billing_date_from';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value
      := TO_CHAR(ld_billing_date,gc_date_mask_ja);
    -- 請求年月日TO
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'billing_date_to';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value
      := TO_CHAR(LAST_DAY(ld_billing_date),gc_date_mask_ja);
    -- 今月売上額
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'month_sales';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gr_dtl_data.month_sales;
    -- 消費税額
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'consumption_tax';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gr_dtl_data.consumption_tax;
    -- 通行料等
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'congestion_charge';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gr_dtl_data.congestion_charge;
--  2018/03/30 V1.2 Added START
    -- 銀行情報
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'bank_name';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value
      := fnd_profile.value( cv_prf_xxwip_740002c_bank );
--  2018/03/30 V1.2 Added END
    -- 振込年月日
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'condition_setting_date';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value
      := TO_CHAR(gr_dtl_data.condition_setting_date,gc_date_mask_ja);
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_create_xml_data ;
--
  /**********************************************************************************
   * Function Name    : convert_into_xml
   * Description      : ＸＭＬタグに変換する。
   ***********************************************************************************/
  FUNCTION convert_into_xml
    (
      iv_name              IN        VARCHAR2   --   タグネーム
     ,iv_value             IN        VARCHAR2   --   タグデータ
     ,ic_type              IN        CHAR       --   タグタイプ
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'convert_into_xml' ;   -- プログラム名
--
    -- =====================================================
    -- ユーザー宣言部
    -- =====================================================
    -- *** ローカル変数 ***
    lv_convert_data         VARCHAR2(2000) ;
--
  BEGIN
--
    --データの場合
    IF ( ic_type = 'D' ) THEN
      lv_convert_data := '<'||iv_name||'><![CDATA['||iv_value||']]></'||iv_name||'>';
    ELSE
      lv_convert_data := '<'||iv_name||'>' ;
    END IF ;
--
    RETURN(lv_convert_data) ;
--
  END convert_into_xml ;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain
    (
      iv_billing_code        IN   VARCHAR2  -- 01 : 請求先コード
     ,iv_billing_date        IN   VARCHAR2  -- 02 : 請求年月
     ,ov_errbuf              OUT  VARCHAR2  -- エラー・メッセージ           --# 固定 #
     ,ov_retcode             OUT  VARCHAR2  -- リターン・コード             --# 固定 #
     ,ov_errmsg              OUT  VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ======================================================
    -- 固定ローカル定数
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'submain' ; -- プログラム名
    -- ======================================================
    -- ローカル変数
    -- ======================================================
    lv_errbuf  VARCHAR2(5000) ;                   --   エラー・メッセージ
    lv_retcode VARCHAR2(1) ;                      --   リターン・コード
    lv_errmsg  VARCHAR2(5000) ;                   --   ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ======================================================
    -- ユーザー宣言部
    -- ======================================================
    lv_xml_string           VARCHAR2(32000) ;
    lv_err_code             VARCHAR2(10) ;
    ln_retcode              VARCHAR2(1) ;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal ;
--
--###########################  固定部 END   ############################
--
    -- =====================================================
    -- 初期処理
    -- =====================================================
    -- -----------------------------------------------------
    -- パラメータ格納
    -- -----------------------------------------------------
    gr_param.billing_code := iv_billing_code ;   -- 01 : 請求先コード
    gr_param.billing_date := iv_billing_date ;   -- 02 : 請求年月
--
    -- =====================================================
    -- パラメータチェック
    -- =====================================================
    prc_chk_param
      (
        ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- データ取得
    -- =====================================================
    prc_get_data
      (
        ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- ＸＭＬファイルデータ編集
    -- =====================================================
    -- --------------------------------------------------
    -- リストグループ開始タグ
    -- --------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'data_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- --------------------------------------------------
    -- ＸＭＬデータ編集処理を呼び出す。
    -- --------------------------------------------------
    prc_create_xml_data
      (
        ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- --------------------------------------------------
    -- リストグループ終了タグ
    -- --------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/data_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ==================================================
    -- 帳票出力
    -- ==================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
--
    -- --------------------------------------------------
    -- 抽出データが０件の場合
    -- --------------------------------------------------
    IF ( gn_data_cnt = 0 ) THEN
--
      -- --------------------------------------------------
      -- ０件メッセージの取得
      -- --------------------------------------------------
      ov_retcode := gv_status_warn ;
      lv_errmsg  := xxcmn_common_pkg.get_msg( gc_application
                                             ,gc_err_code_no_data ) ;
--
      -- --------------------------------------------------
      -- メッセージの設定
      -- --------------------------------------------------
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  <data_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    <msg>' || lv_errmsg || '</msg>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  </data_info>' ) ;
--
    -- --------------------------------------------------
    -- 帳票データが出力できた場合
    -- --------------------------------------------------
    ELSE
      -- --------------------------------------------------
      -- ＸＭＬ出力
      -- --------------------------------------------------
      -- ＸＭＬデータ部出力
      <<xml_data_table>>
      FOR i IN 1 .. gt_xml_data_table.COUNT LOOP
        -- 編集したデータをタグに変換
        lv_xml_string := convert_into_xml
                          (
                            iv_name   => gt_xml_data_table(i).tag_name  -- タグネーム
                           ,iv_value  => gt_xml_data_table(i).tag_value  -- タグデータ
                           ,ic_type   => gt_xml_data_table(i).tag_type  -- タグタイプ
                          ) ;
        -- ＸＭＬタグ出力
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_xml_string) ;
      END LOOP xml_data_table ;
--
    END IF ;
--
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
    -- ==================================================
    -- 終了ステータス設定
    -- ==================================================
    ov_errmsg  := lv_errmsg ;
    ov_errbuf  := lv_errbuf ;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
--
--####################################  固定部 END   ##########################################
  END submain ;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main
    (
      errbuf              OUT    VARCHAR2   -- エラーメッセージ
     ,retcode             OUT    VARCHAR2   -- エラーコード
     ,iv_billing_code     IN     VARCHAR2   -- 01 : 請求先コード
     ,iv_billing_date     IN     VARCHAR2   -- 02 : 請求年月
    )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ======================================================
    -- 固定ローカル定数
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'xxwip740002c.main' ;  -- プログラム名
    -- ======================================================
    -- ローカル変数
    -- ======================================================
    lv_errbuf               VARCHAR2(5000) ;      --   エラー・メッセージ
    lv_retcode              VARCHAR2(1) ;         --   リターン・コード
    lv_errmsg               VARCHAR2(5000) ;      --   ユーザー・エラー・メッセージ
--
  BEGIN
--
--###########################  固定部 END   #############################
--
    -- ======================================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ======================================================
    submain
      (
        iv_billing_code        -- 01 : 請求先コード
       ,iv_billing_date        -- 02 : 請求年月
       ,lv_errbuf             -- エラー・メッセージ
       ,lv_retcode             -- リターン・コード
       ,lv_errmsg              -- ユーザー・エラー・メッセージ
     ) ;
--
--###########################  固定部 START   #####################################################
--
    -- ======================================================
    -- エラー・メッセージ出力
    -- ======================================================
    IF ( lv_retcode = gv_status_error ) THEN
      errbuf := lv_errmsg ;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf) ;
--
    ELSIF ( lv_retcode = gv_status_warn ) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf) ;
--
    END IF ;
--
    --ステータスセット
    retcode := lv_retcode ;
--
  EXCEPTION
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
--
  END main ;
--
--###########################  固定部 END   #######################################################
--
END xxwip740002c ;
/
