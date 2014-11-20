CREATE OR REPLACE PACKAGE BODY xxwsh400009c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH400009C(body)
 * Description      : 出荷依頼確認表
 * MD.050           : 出荷依頼       T_MD050_BPO_401
 * MD.070           : 出荷依頼確認表 T_MD070_BPO_40J
 * Version          : 1.6
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  convert_into_xml       XMLデータ変換
 *  pro_get_cus_option     関連データ取得
 *  insert_xml_plsql_table XMLデータ格納
 *  prc_initialize         前処理(担当者情報抽出)
 *  prc_get_report_data    明細データ取得
 *  create_xml             XMLデータ作成
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/11    1.0   Masanobu Kimura  新規作成
 *  2008/06/10    1.1   石渡  賢和       ヘッダ「出力日付」の書式を変更
 *  2008/06/13    1.2   石渡  賢和       不具合対応
 *  2008/06/23    1.3   石渡  賢和       ST不具合対応#106
 *  2008/07/01    1.4   福田  直樹       ST不具合対応#331 商品区分は入力パラメータから取得
 *  2008/07/02    1.5   Satoshi Yunba    禁則文字「'」「"」「<」「>」「＆」対応
 *  2008/07/03    1.6   椎名  昭圭       ST不具合対応#344･357･406対応
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ###############################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
--################################  固定部 END   ###############################
--
--#####################  固定共通例外宣言部 START   ####################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt, -20000);
--
--###########################  固定部 END   ############################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
--
  -- 対象データなし例外
  data_not_found exception;
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name                  CONSTANT VARCHAR2(20) := 'XXWSH400009C';
                                        -- パッケージ名
  -- 帳票ID
  gc_report_id                 CONSTANT VARCHAR2(12) := 'XXWSH400009T';
                                        -- 帳票ID
  -- プロファイル
  gv_prf_wei_u                 CONSTANT VARCHAR2(50) := 'XXWSH_WEIGHT_UOM';
                                        -- XXWSH:出荷重量単位
  gv_prf_cap_u                 CONSTANT VARCHAR2(50) := 'XXWSH_CAPACITY_UOM';
                                        -- XXWSH:出荷容積単位
  gv_prf_prod_class_code       CONSTANT VARCHAR2(50) := 'XXCMN_ITEM_DIV_SECURITY';
                                        -- XXCMN:商品区分
  -- エラーコード
  gv_application_wsh           CONSTANT VARCHAR2(5)  := 'XXWSH';
                                        -- アプリケーション
  gv_application_cmn           CONSTANT VARCHAR2(5)  := 'XXCMN';
                                        -- アプリケーション
  gv_err_pro                   CONSTANT VARCHAR2(20) := 'APP-XXCMN-10002';
                                        -- プロファイル取得エラーメッセージ
  gv_err_nodata                CONSTANT VARCHAR2(20) := 'APP-XXCMN-10122';
                                        -- 出荷依頼確認情報対象データなしエラーメッセージ
  -- トークン
  gv_tkn_prof_name             CONSTANT VARCHAR2(10) := 'NG_PROFILE';
  -- トークン内メッセージ
  gv_tkn_msg_wei_u             CONSTANT VARCHAR2(20) := 'XXWSH:出荷重量単位';
  gv_tkn_msg_cap_u             CONSTANT VARCHAR2(20) := 'XXWSH:出荷容積単位';
  gv_tkn_msg_prod_class_code   CONSTANT VARCHAR2(20) := 'XXCMN:商品区分';
  -- タグタイプ
  gc_tag_type_data             CONSTANT VARCHAR2(1)  := 'D' ;
                                        -- 出力タグタイプ（D：データ）
  -- クイックコード
  gv_tr_status                 CONSTANT VARCHAR2(25) := 'XXWSH_TRANSACTION_STATUS';
                                        --ステータス
  gv_shipping_class            CONSTANT VARCHAR2(21) := 'XXWSH_SHIPPING_CLASS';
                                        --依頼区分
  gv_lg_confirm_req_class      CONSTANT VARCHAR2(27) := 'XXWSH_LG_CONFIRM_REQ_CLASS';
                                        --物流区分
  -- コード
  gv_order_category_code       CONSTANT VARCHAR2(5)  := 'ORDER';
  gv_shipping_shikyu_class     CONSTANT VARCHAR2(1)  := '1';
  gv_yes                       CONSTANT VARCHAR2(1)  := 'Y';
-- 2008/07/03 ST不具合対応#344 Start
  gv_cancel                    CONSTANT VARCHAR2(2)  := '99';
-- 2008/07/03 ST不具合対応#344 End
--
  ------------------------------
  -- 項目編集関連
  ------------------------------
  gc_char_d_format             CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';
  gc_char_d_format2            CONSTANT VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS';
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- 入力パラメータ格納用レコード変数
  TYPE rec_param_data  IS RECORD 
    (
      iv_head_sales_branch       VARCHAR2(4),       --   1.管轄拠点
      iv_input_sales_branch      VARCHAR2(4),       --   2.入力拠点
      iv_deliver_to              VARCHAR2(9),       --   3.配送先
      iv_deliver_from            VARCHAR2(4),       --   4.出荷元
      iv_ship_date_from          VARCHAR2(10),      --   5.出庫日From
      iv_ship_date_to            VARCHAR2(10),      --   6.出庫日To
      iv_arrival_date_from       VARCHAR2(10),      --   7.着日From
      iv_arrival_date_to         VARCHAR2(10),      --   8.着日To
      iv_order_type_id           VARCHAR2(20),      --   9.出庫形態
      iv_request_no              VARCHAR2(12),      --   10.依頼No.
      iv_req_status              VARCHAR2(20),      --   11.出荷依頼ステータス
      iv_confirm_request_class   VARCHAR2(20),      --   12.物流担当確認依頼区分
      iv_prod_class              VARCHAR2(20)       --   13.商品区分 2008/07/01 ST不具合対応#331
    ) ;
--
  -- データ格納用レコード変数
  TYPE rec_data_type_dtl  IS RECORD 
    (
     request_no                  xxwsh_order_headers_all.request_no%TYPE
                                                    -- 依頼No
     ,customer_code              xxwsh_order_headers_all.customer_code%TYPE
                                                    -- 顧客コード
     ,party_short_name           xxcmn_cust_accounts2_v.party_short_name%TYPE
                                                    -- 顧客
     --,address                    xxcmn_cust_acct_sites2_v.address_line1%TYPE
     ,address                     VARCHAR2(60)
                                                    -- 配送先住所
     ,address_line1              xxwsh_order_headers_all.head_sales_branch%TYPE
                                                    -- 管轄拠点コード
     ,address_line_name          xxcmn_cust_accounts2_v.party_short_name%TYPE
                                                    -- 管轄拠点
     ,deliver_to                 xxwsh_order_headers_all.deliver_to%TYPE
                                                    -- 配送先コード
     ,party_site_full_name       xxcmn_cust_acct_sites2_v.party_site_full_name%TYPE
                                                    -- 配送先
     ,mixed_no                   xxwsh_order_headers_all.mixed_no%TYPE
                                                    -- 混載元No
     ,cust_po_number             xxwsh_order_headers_all.cust_po_number%TYPE
                                                    -- 顧客発注番号
     ,schedule_ship_date         xxwsh_order_headers_all.schedule_ship_date%TYPE
                                                    -- 出庫日
     ,schedule_arrival_date      xxwsh_order_headers_all.schedule_arrival_date%TYPE
                                                    -- 着日
     ,arrival_time_from          xxwsh_order_headers_all.arrival_time_from%TYPE
                                                    -- 時間指定（from）
     ,arrival_time_to            xxwsh_order_headers_all.arrival_time_to%TYPE
                                                    -- 時間指定（to）
     ,order_type_id              xxwsh_oe_transaction_types2_v.transaction_type_name%TYPE
                                                    -- 出庫形態
     ,meaning1                   xxcmn_lookup_values_v.meaning%TYPE
                                                    -- 依頼区分
     ,ship_method_meaning        xxwsh_ship_method2_v.ship_method_meaning%TYPE
                                                    -- 配送区分
     ,collected_pallet_qty       xxwsh_order_headers_all.collected_pallet_qty%TYPE
                                                    -- パレット回収枚数
     ,meaning2                   xxcmn_lookup_values_v.meaning%TYPE
                                                    -- ステータス
     ,meaning3                   xxcmn_lookup_values_v.meaning%TYPE
                                                    -- 物流区分
     ,shipping_instructions      xxwsh_order_headers_all.shipping_instructions%TYPE
                                                    -- 摘要
     ,deliver_from               xxwsh_order_headers_all.deliver_from%TYPE
                                                    -- 出荷元コード
     ,description                xxcmn_item_locations_v.description%TYPE
                                                    -- 出荷元
     ,request_item_code          xxwsh_order_lines_all.request_item_code%TYPE
                                                    -- 品目コード
     ,item_short_name            xxcmn_item_mst_v.item_short_name%TYPE
                                                    -- 品目
     ,pallet_quantity            xxwsh_order_lines_all.pallet_quantity%TYPE
                                                    -- パレット枚数
     ,layer_quantity             xxwsh_order_lines_all.layer_quantity%TYPE
                                                    -- パレット段数
     ,case_quantity              xxwsh_order_lines_all.case_quantity%TYPE
                                                    -- ケース数
     ,quantity                   xxwsh_order_lines_all.quantity%TYPE
                                                    -- 総数
     ,item_um                    xxcmn_item_mst_v.item_um%TYPE
                                                    -- 総数（単位）
     ,num_of_cases               xxcmn_item_mst_v.num_of_cases%TYPE
                                                    -- 入数
     ,weight                     xxwsh_order_lines_all.weight%TYPE
                                                    -- 合計重量/合計容積
     ,weight_capacity_class      xxcmn_item_mst_v.weight_capacity_class%TYPE
                                                    -- 合計重量/合計容積（単位）
     ,pallet_sum_quantity        xxwsh_order_headers_all.pallet_sum_quantity%TYPE
                                                    -- ﾊﾟﾚｯﾄ合計枚数
     ,sum_weight                 xxwsh_order_headers_all.sum_weight%TYPE
                                                    -- 総重量/総容積
     ,sum_weight_capacity_class  VARCHAR2(10)
                                                    -- 総重量/総容積（単位）
     ,loading_efficiency_weight  xxwsh_order_headers_all.loading_efficiency_weight%TYPE
                                                    -- 積載率
    ) ;

  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  ------------------------------
  -- ＸＭＬ用
  ------------------------------
  gv_department_code           VARCHAR2(10);      -- 担当部署
  gv_department_name           VARCHAR2(14);      -- 担当者
--
  gv_name_wei_u                VARCHAR2(20);      -- 出荷重量単位
  gv_name_cap_u                VARCHAR2(20);      -- 出荷容積単位
  gv_name_prod_class_code      VARCHAR2(20);      -- 商品区分
--
  /**********************************************************************************
   * Function Name    : convert_into_xml
   * Description      : XMLデータ変換
   ***********************************************************************************/
  FUNCTION convert_into_xml(
    iv_name  IN VARCHAR2,
    iv_value IN VARCHAR2,
    ic_type  IN CHAR
  ) RETURN VARCHAR2
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'convert_into_xml'; -- プログラム名
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
  --
    -- *** ローカル変数 ***
    lv_convert_data VARCHAR2(2000);
  --
    -- *** ローカル・カーソル ***
    --
    -- *** ローカル・レコード ***
--
  BEGIN
--
    --データの場合
    IF (ic_type = gc_tag_type_data) THEN
      lv_convert_data := '<'||iv_name||'><![CDATA['||iv_value||']]></'||iv_name||'>';
    ELSE
      lv_convert_data := '<'||iv_name||'>';
    END IF;
--
    RETURN(lv_convert_data);
--
  END convert_into_xml;
--
  /**********************************************************************************
   * Procedure Name   : pro_get_cus_option
   * Description      : 関連データ取得
   ***********************************************************************************/
  PROCEDURE pro_get_cus_option
    (
      ov_errbuf     OUT VARCHAR2     -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2     -- リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_get_cus_option'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
--
    ------------------------------------------
    -- プロファイルから出荷重量単位取得
    ------------------------------------------
    gv_name_wei_u := SUBSTRB(FND_PROFILE.VALUE(gv_prf_wei_u), 1, 2);
    -- 取得エラー時
    IF (gv_name_wei_u IS NULL) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( gv_application_wsh  -- 'XXWSH'
                                                     ,gv_err_pro          -- プロファイル取得エラー
                                                     ,gv_tkn_prof_name    -- トークン
                                                     ,gv_tkn_msg_wei_u    -- メッセージ
                                                    )
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
--
    ------------------------------------------
    -- プロファイルから出荷容積単位取得
    ------------------------------------------
    gv_name_cap_u := SUBSTRB(FND_PROFILE.VALUE(gv_prf_cap_u), 1, 2);
    -- 取得エラー時
    IF (gv_name_cap_u IS NULL) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( gv_application_wsh  -- 'XXWSH'
                                                     ,gv_err_pro          -- プロファイル取得エラー
                                                     ,gv_tkn_prof_name    -- トークン
                                                     ,gv_tkn_msg_cap_u    -- メッセージ
                                                    )
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
--
    ------------------------------------------
    -- プロファイルから商品区分取得
    ------------------------------------------
    --商品区分はプロファイルからではなく入力パラメータから取得する
    -- 2008/07/01 ST不具合対応#331
    --
    --gv_name_prod_class_code := SUBSTRB(FND_PROFILE.VALUE(gv_prf_prod_class_code), 1, 2);
    ---- 取得エラー時
    --IF (gv_name_prod_class_code IS NULL) THEN
    --  lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( gv_application_cmn  -- 'XXCMN'
    --                                                 ,gv_err_pro          -- プロファイル取得エラー
    --                                                 ,gv_tkn_prof_name    -- トークン
    --                                                 ,gv_tkn_msg_prod_class_code     -- メッセージ
    --                                                )
    --                                                ,1
    --                                                ,5000);
    --  RAISE global_api_expt;
    --END IF;
    --
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END pro_get_cus_option;
--
  /**********************************************************************************
   * Procedure Name   : insert_xml_plsql_table
   * Description      : XMLデータ格納
   ***********************************************************************************/
  PROCEDURE insert_xml_plsql_table(
    iox_xml_data      IN OUT NOCOPY XML_DATA,
    iv_tag_name       IN     VARCHAR2,
    iv_tag_value      IN     VARCHAR2,
    ic_tag_type       IN     CHAR,
    ic_tag_value_type IN     CHAR
  )
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_xml_plsql_table'; -- プログラム名
  --
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
    ln_count NUMBER;
  --
    -- *** ローカル・カーソル ***
  --
    -- *** ローカル・レコード ***
  --
  BEGIN
--
    ln_count := iox_xml_data.COUNT + 1 ;
    iox_xml_data( ln_count ).TAG_NAME  := iv_tag_name;
--
    IF (ic_tag_value_type = 'P') THEN
      iox_xml_data( ln_count ).TAG_VALUE := TO_CHAR(TO_NUMBER(iv_tag_value), '99990.900');
    ELSIF (ic_tag_value_type = 'B') THEN
      iox_xml_data( ln_count ).TAG_VALUE := TO_CHAR(TO_NUMBER(iv_tag_value), '9999990.90');
    ELSE
      iox_xml_data( ln_count ).TAG_VALUE := iv_tag_value;
    END IF;
    iox_xml_data( ln_count ).TAG_TYPE  := ic_tag_type;
--
  END insert_xml_plsql_table;
--
  /**********************************************************************************
   * Procedure Name   : prc_initialize
   * Description      : 前処理(担当者情報抽出)
   ***********************************************************************************/
  PROCEDURE prc_initialize
    (
      ir_param      IN     rec_param_data   -- 01.入力パラメータ群
     ,ov_errbuf     OUT    VARCHAR2         --    エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT    VARCHAR2         --    リターン・コード             --# 固定 #
     ,ov_errmsg     OUT    VARCHAR2         --    ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_initialize' ; -- プログラム名
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
    -- *** ローカル変数 ***
    ln_data_cnt     NUMBER := 0 ;   -- データ件数取得用
    lv_err_code     VARCHAR2(100) ; -- エラーコード格納用
--
    -- *** ローカル・例外処理 ***
--
  BEGIN
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ====================================================
    -- 担当部署取得
    -- ====================================================
    gv_department_code := SUBSTRB( xxcmn_common_pkg.get_user_dept( FND_GLOBAL.USER_ID ), 1, 10 ) ;
--
    -- ====================================================
    -- 担当者取得
    -- ====================================================
    gv_department_name := SUBSTRB( xxcmn_common_pkg.get_user_name( FND_GLOBAL.USER_ID ), 1, 14 ) ;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_initialize ;
--
  /**********************************************************************************
   * Procedure Name   : prc_get_report_data
   * Description      : 明細データ取得
   ***********************************************************************************/
  PROCEDURE prc_get_report_data
    (
      ir_param      IN  rec_param_data            -- 01.入力パラメータ群
     ,ot_data_rec   OUT NOCOPY tab_data_type_dtl  -- 02.取得レコード群
     ,ov_errbuf     OUT VARCHAR2                  --    エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2                  --    リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2                  --    ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_report_data'; -- プログラム名
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
    -- *** ローカル・定数 ***
--
    -- *** ローカル・カーソル ***
    CURSOR cur_main_data
      (
        iv_head_sales_branch         VARCHAR2,      --   1.管轄拠点
        iv_input_sales_branch        VARCHAR2,      --   2.入力拠点
        iv_deliver_to                VARCHAR2,      --   3.配送先
        iv_deliver_from              VARCHAR2,      --   4.出荷元
        iv_ship_date_from            VARCHAR2,      --   5.出庫日From
        iv_ship_date_to              VARCHAR2,      --   6.出庫日To
        iv_arrival_date_from         VARCHAR2,      --   7.着日From
        iv_arrival_date_to           VARCHAR2,      --   8.着日To
        iv_order_type_id             VARCHAR2,      --   9.出庫形態
        iv_request_no                VARCHAR2,      --   10.依頼No.
        iv_req_status                VARCHAR2,      --   11.出荷依頼ステータス
        iv_confirm_request_class     VARCHAR2,      --   12.物流担当確認依頼区分
        iv_prod_class                VARCHAR2       --   13.商品区分  2008/07/01 ST不具合対応#331
      )
    IS
      SELECT xoha.request_no                                            -- 依頼no
            ,xoha.customer_code                                         -- 顧客コード
            ,xca2v.party_short_name                                     -- 顧客
            ,xcas2v.address_line1 || xcas2v.address_line2               -- 配送先住所
            ,xoha.head_sales_branch                                     -- 管轄拠点コード
            ,xca2v2.party_short_name                                    -- 管轄拠点
            ,xoha.deliver_to                                            -- 配送先コード
            ,xcas2v.party_site_full_name                                -- 配送先
            ,xoha.mixed_no                                              -- 混載元no
            ,xoha.cust_po_number                                        -- 顧客発注番号
            ,xoha.schedule_ship_date                                    -- 出庫日
            ,xoha.schedule_arrival_date                                 -- 着日
            ,xoha.arrival_time_from                                     -- 時間指定（from）
            ,xoha.arrival_time_to                                       -- 時間指定（to）
            ,xott2v.transaction_type_name                               -- 出庫形態
            ,xlv2v.meaning                                              -- 依頼区分
            ,xsm2v.ship_method_meaning                                  -- 配送区分
            ,xoha.collected_pallet_qty                                  -- パレット回収枚数
            ,xlv2v2.meaning                                             -- ステータス
            ,xlv2v3.meaning                                             -- 物流区分
            ,xoha.shipping_instructions                                 -- 摘要
            ,xoha.deliver_from                                          -- 出荷元コード
            ,xil2v.description                                          -- 出荷元
            ,xola.request_item_code                                     -- 品目コード
            ,xim2v.item_short_name                                      -- 品目
            ,xola.pallet_quantity                                       -- パレット枚数
            ,xola.layer_quantity                                        -- パレット段数
            ,xola.case_quantity                                         -- ケース数
            ,CASE
              WHEN xim2v.conv_unit IS NULL THEN xola.quantity
              ELSE xola.quantity / CASE
                                    WHEN xim2v.num_of_cases IS NULL THEN '1'
                                    WHEN xim2v.num_of_cases = '0'   THEN '1'
                                    ELSE                                 xim2v.num_of_cases
                                   END
             END                                                        -- 総数
            ,CASE
              WHEN xim2v.conv_unit IS NULL THEN xim2v.item_um
              ELSE                              xim2v.conv_unit
             END                                                        -- 総数（単位）
            ,NVL(xim2v.num_of_cases, '-')                               -- 入数
            ,CASE 
              WHEN xsm2v.small_amount_class = '1' THEN
                              CASE 
                                WHEN xoha.weight_capacity_class = '1' THEN xola.weight
                                WHEN xoha.weight_capacity_class = '2' THEN xola.capacity
                              END 
              WHEN xsm2v.small_amount_class = '0' THEN
                              CASE 
                                WHEN xoha.weight_capacity_class = '1'
                                 THEN xola.pallet_weight + xola.weight
                                WHEN xoha.weight_capacity_class = '2'
                                 THEN xola.pallet_weight + xola.capacity
                              END
             END                                                        -- 合計重量/合計容積
            ,CASE 
              WHEN xim2v.weight_capacity_class = '1' THEN gv_name_wei_u
              WHEN xim2v.weight_capacity_class = '2' THEN gv_name_cap_u
             END                                                        -- 合計重量/合計容積(単位)
            ,xoha.pallet_sum_quantity                                   -- ﾊﾟﾚｯﾄ合計枚数
            ,CASE 
              WHEN xsm2v.small_amount_class = '1' THEN
                              CASE 
                                WHEN xoha.weight_capacity_class = '1' THEN xoha.sum_weight
                                WHEN xoha.weight_capacity_class = '2' THEN xoha.sum_capacity
                              END 
              WHEN xsm2v.small_amount_class = '0' THEN
                              CASE 
                                WHEN xoha.weight_capacity_class = '1'
                                 THEN xola.pallet_weight + xoha.sum_weight
                                WHEN xoha.weight_capacity_class = '2'
                                 THEN xola.pallet_weight + xoha.sum_capacity
                              END
             END                                                        -- 総重量/総容積
            ,CASE 
              WHEN xoha.weight_capacity_class = '1' THEN gv_name_wei_u
              WHEN xoha.weight_capacity_class = '2' THEN gv_name_cap_u
             END                                                        -- 総重量/総容積（単位）
            ,CASE 
              WHEN xoha.weight_capacity_class = '1' THEN xoha.loading_efficiency_weight
              WHEN xoha.weight_capacity_class = '2' THEN xoha.loading_efficiency_capacity
             END                                                        -- 積載率
       FROM xxwsh_order_headers_all       xoha                        -- 受注ヘッダアドオン
          ,xxwsh_order_lines_all          xola                        -- 受注明細アドオン
          ,xxcmn_cust_acct_sites2_v       xcas2v                      -- 顧客サイト情報VIEW2
          ,xxcmn_cust_accounts2_v         xca2v                       -- 顧客情報VIEW2(顧客情報)
          ,xxcmn_cust_accounts2_v         xca2v2                      -- 顧客情報VIEW2(管轄拠点)
          ,xxcmn_item_mst2_v              xim2v                       -- OPM品目アドオンマスタ
-- 2008/07/04 ST不具合対応#406 Start
--          ,xxcmn_item_categories4_v       xic4v                       -- 品目カテゴリマスタ
-- 2008/07/04 ST不具合対応#406 End
          ,xxcmn_lookup_values2_v         xlv2v                       -- クイックコード(依頼区分)
          ,xxcmn_lookup_values2_v         xlv2v2                      -- クイックコード(ステータス)
          ,xxcmn_lookup_values2_v         xlv2v3                      -- クイックコード(物流区分)
          ,xxcmn_item_locations2_v        xil2v                       -- OPM保管場所マスタ
          ,xxwsh_oe_transaction_types2_v  xott2v                      -- 受注タイプ
          ,xxwsh_ship_method2_v           xsm2v                       -- 配送区分情報VIEW2
      WHERE xott2v.order_category_code       = gv_order_category_code
                                       -- 受注タイプ.受注カテゴリ＝「受注」
        AND xott2v.shipping_shikyu_class     = gv_shipping_shikyu_class
                                       -- 受注タイプ.出荷支給区分＝「出荷依頼」
        AND xott2v.transaction_type_id       = xoha.order_type_id
                                       -- 受注タイプ.受注タイプID＝受注ヘッダアドオン.受注タイプID
        AND xoha.head_sales_branch           = NVL(iv_head_sales_branch, xoha.head_sales_branch)
                                       -- 受注ヘッダアドオン.管轄拠点＝パラメータ.管轄拠点
        AND xoha.input_sales_branch          = iv_input_sales_branch
                                       -- 受注ヘッダアドオン.入力拠点＝パラメータ.入力拠点
        AND xoha.deliver_to                  = NVL(iv_deliver_to, xoha.deliver_to)
                                       -- 受注ヘッダアドオン.出荷先＝パラメータ.配送先かつ
        AND xoha.deliver_from                = NVL(iv_deliver_from, xoha.deliver_from)
                                       -- 受注ヘッダアドオン.出荷元保管場所＝パラメータ.出荷元
        AND xoha.schedule_ship_date          >= 
            NVL(FND_DATE.STRING_TO_DATE(iv_ship_date_from,gc_char_d_format),
                                                                          xoha.schedule_ship_date)
                                       -- 受注ヘッダアドオン.出荷予定日≧パラメータ.出庫日From
        AND xoha.schedule_ship_date          <= 
            NVL(FND_DATE.STRING_TO_DATE(iv_ship_date_to,gc_char_d_format),
                                                                          xoha.schedule_ship_date)
                                       -- 受注ヘッダアドオン.出荷予定日≦パラメータ.出庫日To
        AND xoha.schedule_arrival_date       >= 
        NVL(FND_DATE.STRING_TO_DATE(iv_arrival_date_from,gc_char_d_format),
                                                                       xoha.schedule_arrival_date)
                                       -- 受注ヘッダアドオン.着荷予定日≧パラメータ.着日From
        AND xoha.schedule_arrival_date       <= 
        NVL(FND_DATE.STRING_TO_DATE(iv_arrival_date_to,gc_char_d_format),
                                                                       xoha.schedule_arrival_date)
                                       -- 受注ヘッダアドオン.着荷予定日≦パラメータ.着日To
        AND xoha.order_type_id               = NVL(iv_order_type_id, xoha.order_type_id)
                                       -- 受注ヘッダアドオン.受注タイプID＝パラメータ.出庫形態                                                                       
        AND xoha.request_no                  = NVL(iv_request_no, xoha.request_no)
                                       -- 受注ヘッダアドオン.依頼No＝パラメータ.依頼No
        AND xoha.req_status                  = xlv2v2.lookup_code
                                -- 受注ヘッダアドオン.ステータス＝クイックコード(ステータス).コード
        AND xlv2v2.lookup_type               = gv_tr_status
                                       -- クイックコード(ステータス).タイプ＝‘出荷依頼ステータス’
        AND xoha.req_status                  = NVL(iv_req_status, xoha.req_status)
                                -- 受注ヘッダアドオン.ステータス＝パラメータ.出荷依頼ステータス
        AND xoha.latest_external_flag        = gv_yes
                                       -- 受注ヘッダアドオン.最新フラグ＝‘Y’
        AND xoha.confirm_request_class       = 
            NVL(iv_confirm_request_class, xoha.confirm_request_class)
                      -- 受注ヘッダアドオン.物流担当確認依頼区分＝パラメータ.物流担当確認依頼区分
        AND xoha.confirm_request_class       = xlv2v3.lookup_code
                      -- 受注ヘッダアドオン.物流担当確認依頼区分＝クイックコード(物流区分).コード
        AND xlv2v3.lookup_type               = gv_lg_confirm_req_class
                      -- クイックコード(物流区分).タイプ＝物流区分
        AND xoha.deliver_from_id             = xil2v.inventory_location_id
                                       -- 受注ヘッダアドオン.出荷元ID＝OPM保管場所マスタ.保管棚ID
        AND xoha.deliver_to_id               = xcas2v.party_site_id
                      -- 受注ヘッダアドオン.出荷先ID＝顧客サイト情報VIEW2.パーティサイトID
        AND xcas2v.start_date_active         <= 
            NVL(FND_DATE.STRING_TO_DATE(iv_ship_date_from,gc_char_d_format),
                                                                          xoha.schedule_ship_date)
                                       -- 顧客サイト情報VIEW2.適用開始日≦パラメータ.出庫日From
        AND (xcas2v.end_date_active          >= 
            NVL(FND_DATE.STRING_TO_DATE(iv_ship_date_from,gc_char_d_format),
                                                                          xoha.schedule_ship_date)
                                       -- 顧客サイト情報VIEW2.適用終了日≧パラメータ.出庫日From
            OR xcas2v.end_date_active        IS NULL)
                                       -- 顧客サイト情報VIEW2.適用終了日 = NULL
        AND xoha.head_sales_branch           = xca2v2.party_number
                      -- 受注ヘッダアドオン.管轄拠点＝顧客情報VIEW2(管轄拠点).組織番号
        AND xca2v2.start_date_active         <= 
            NVL(FND_DATE.STRING_TO_DATE(iv_ship_date_from,gc_char_d_format),
                                                                          xoha.schedule_ship_date)
                                       -- 顧客情報VIEW2(管轄拠点).適用開始日≦パラメータ.出庫日From
        AND (xca2v2.end_date_active          >= 
            NVL(FND_DATE.STRING_TO_DATE(iv_ship_date_from,gc_char_d_format),
                                                                          xoha.schedule_ship_date)
                                       -- 顧客情報VIEW2(管轄拠点).適用終了日≧パラメータ.出庫日From
            OR xca2v2.end_date_active        IS NULL)
                                       -- 顧客情報VIEW2(管轄拠点).適用終了日 = NULL
        AND xoha.customer_id                 = xca2v.party_id
                      -- 受注ヘッダアドオン.顧客ID＝顧客情報VIEW2(顧客情報).パーティID
        AND xca2v.start_date_active          <= 
            NVL(FND_DATE.STRING_TO_DATE(iv_ship_date_from,gc_char_d_format),
                                                                          xoha.schedule_ship_date)
                                       -- 顧客情報VIEW2(顧客情報).適用開始日≦パラメータ.出庫日From
        AND (xca2v.end_date_active           >= 
            NVL(FND_DATE.STRING_TO_DATE(iv_ship_date_from,gc_char_d_format),
                                                                          xoha.schedule_ship_date)
                                       -- 顧客情報VIEW2(顧客情報).適用終了日≧パラメータ.出庫日From
            OR xca2v.end_date_active         IS NULL)
                                       -- 顧客情報VIEW2(顧客情報).適用終了日 = NULL
        AND xoha.order_header_id             = xola.order_header_id
            -- 受注ヘッダアドオン.受注ヘッダアドオンID＝受注明細アドオン.受注ヘッダアドオンID
        AND xola.request_item_code           = xim2v.item_no
                                       -- 受注明細アドオン.依頼品目＝OPM品目マスタ.品目コード
-- 2008/07/04 ST不具合対応#406 Start
--        AND xim2v.item_id                    = xic4v.item_id
                                       -- OPM品目マスタ.品目ID＝OPM品目カテゴリマスタ.品目ID
        --AND xic4v.prod_class_code            = gv_name_prod_class_code  -- 2008/07/01 ST不具合対応#331
--        AND xic4v.prod_class_code            = iv_prod_class              -- 2008/07/01 ST不具合対応#331
        AND xoha.prod_class                  = iv_prod_class
                       -- 受注ヘッダアドオン.商品区分＝プロファイル（商品区分）:1=リーフ,2=ドリンク
-- 2008/07/04 ST不具合対応#406 End
            -- 品目カテゴリマスタ. 商品区分＝プロファイル（商品区分）:1=リーフ,2=ドリンク
        AND xim2v.start_date_active          <= 
            NVL(FND_DATE.STRING_TO_DATE(iv_ship_date_from,gc_char_d_format),
                                                                          xoha.schedule_ship_date)
                                       -- OPM品目アドオンマスタ.適用開始日≦パラメータ.出庫日From
        AND (xim2v.end_date_active           >= 
            NVL(FND_DATE.STRING_TO_DATE(iv_ship_date_from,gc_char_d_format),
                                                                          xoha.schedule_ship_date)
                                       -- OPM品目アドオンマスタ.適用終了日≧パラメータ.出庫日From
            OR xim2v.end_date_active         IS NULL)
                                       -- OPM品目アドオンマスタ.適用終了日 = NULL
        AND xlv2v.lookup_type                = gv_shipping_class
                                       -- クイックコード(依頼区分).タイプ＝出荷区分
        AND xlv2v.attribute5                 = xott2v.transaction_type_name
                      -- クイックコード(依頼区分)．DFF5(受注タイプ)＝受注タイプ.受注タイプ
-- 2008/07/04 ST不具合対応#406 Start
--        AND xlv2v.attribute4(+)              = xca2v.customer_class_code
--            -- クイックコード(依頼区分).顧客区分(DFF)(+) ＝顧客情報VIEW2(顧客情報)．顧客区分
        AND NVL(xlv2v.attribute4, xca2v.customer_class_code) = xca2v.customer_class_code
            -- クイックコード(依頼区分).顧客区分(DFF)＝顧客情報VIEW2(顧客情報)．顧客区分
-- 2008/07/04 SST不具合対応#406 End
        AND xoha.shipping_method_code        = xsm2v.ship_method_code
                      -- 受注ヘッダアドオン.配送区分=配送区分情報VIEW.配送区分コード
-- 2008/07/03 ST不具合対応#357 Start
        AND xoha.req_status                  <> gv_cancel
                                       -- 受注ヘッダアドオン.ステータス <> 取消
-- 2008/07/03 ST不具合対応#357 End
-- 2008/07/03 ST不具合対応#344 Start
--      ORDER BY xoha.request_no         -- 依頼no
--               ,xola.order_line_number -- 明細番号
      ORDER BY xca2v2.party_short_name -- 管轄拠点
               ,xoha.request_no        -- 依頼no
-- 2008/07/03 ST不具合対応#344 End
               ,xola.order_line_number -- 明細番号
    ;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ====================================================
    -- データ抽出
    -- ====================================================
    -- カーソルオープン
    OPEN cur_main_data
      (
        ir_param.iv_head_sales_branch         -- 管轄拠点
       ,ir_param.iv_input_sales_branch        -- 入力拠点
       ,ir_param.iv_deliver_to                -- 配送先
       ,ir_param.iv_deliver_from              -- 出荷元
       ,ir_param.iv_ship_date_from            -- 出庫日From
       ,ir_param.iv_ship_date_to              -- 出庫日To
       ,ir_param.iv_arrival_date_from         -- 着日From
       ,ir_param.iv_arrival_date_to           -- 着日To
       ,ir_param.iv_order_type_id             -- 出庫形態
       ,ir_param.iv_request_no                -- 依頼No.
       ,ir_param.iv_req_status                -- 出荷依頼ステータス
       ,ir_param.iv_confirm_request_class     -- 物流担当確認依頼区分
       ,ir_param.iv_prod_class                -- 商品区分  2008/07/01 ST不具合対応#331
      ) ;
    -- バルクフェッチ
    FETCH cur_main_data BULK COLLECT INTO ot_data_rec ;
    IF ( ot_data_rec.COUNT=0 ) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( gv_application_cmn      -- 'XXCMN'
                                                     ,gv_err_nodata
                                                    )
                                                    ,1
                                                    ,5000);
      RAISE data_not_found;
    END IF;
    -- カーソルクローズ
    CLOSE cur_main_data ;
--
  EXCEPTION
      -- *** 出荷依頼確認表情報対象データなし 警告***
    WHEN data_not_found THEN
      IF cur_main_data%ISOPEN THEN
        CLOSE cur_main_data ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_retcode := gv_status_warn;
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF cur_main_data%ISOPEN THEN
        CLOSE cur_main_data ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF cur_main_data%ISOPEN THEN
        CLOSE cur_main_data ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF cur_main_data%ISOPEN THEN
        CLOSE cur_main_data ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_get_report_data ;
--
  /**********************************************************************************
   * Procedure Name   : create_xml
   * Description      : XMLデータ作成
   ***********************************************************************************/
  PROCEDURE create_xml (
    iox_xml_data IN OUT     NOCOPY XML_DATA,
    ir_param     IN         rec_param_data, -- 01.レコード  ：パラメータ
    ov_errbuf    OUT        VARCHAR2,       -- エラー・メッセージ           --# 固定 #
    ov_retcode   OUT        VARCHAR2,       -- リターン・コード             --# 固定 #
    ov_errmsg    OUT        VARCHAR2)       -- ユーザー・エラー・メッセージ --# 固定 #
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_xml'; -- プログラム名
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
    lv_convert_data         VARCHAR2(2000);
    -- システム日付
    ld_now_date             DATE DEFAULT SYSDATE;
    -- 前回依頼No.
    pre_req_no              xxwsh_order_headers_all.request_no%TYPE DEFAULT '*';
-- 2008/07/03 ST不具合対応#344 Start
    -- 前回管轄拠点
    pre_add_l_name          xxcmn_cust_accounts2_v.party_short_name%TYPE DEFAULT '*';
-- 2008/07/03 ST不具合対応#344 End
    -- 取得レコード表  
    lt_main_data            tab_data_type_dtl ;
--
    -- *** ローカル・カーソル ***
--
-- *** ローカル・例外処理 ***
--
  BEGIN
--
    -- =====================================================
    -- 項目データ抽出処理
    -- =====================================================
    prc_get_report_data
      (
        ir_param      => ir_param       -- 01.入力パラメータ群
       ,ot_data_rec   => lt_main_data   -- 02.取得レコード群
       ,ov_errbuf     => lv_errbuf      --    エラー・メッセージ           --# 固定 #
       ,ov_retcode    => lv_retcode     --    リターン・コード             --# 固定 #
       ,ov_errmsg     => lv_errmsg      --    ユーザー・エラー・メッセージ --# 固定 #
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_api_expt ;
--
    -- 取得データが０件の場合
    ELSIF ( lt_main_data.COUNT = 0 ) THEN
      --データグループ名開始タグセット
      insert_xml_plsql_table(iox_xml_data, 'g_irai', NULL, 'T', 'C');
      --データセット（ヘッダ）
      insert_xml_plsql_table(iox_xml_data, 'msg', 
             xxcmn_common_pkg.get_msg( gv_application_cmn, gv_err_nodata ), 'D', 'C');
      --データグループ名終了タグセット
      insert_xml_plsql_table(iox_xml_data, '/g_irai', NULL, 'T', 'C');
--
      lv_retcode := gv_status_warn;
--
    -- *** ローカル・レコード ***
--
    ELSE
--
      <<lg_irai_info>>
      FOR get_user_rec IN 1..lt_main_data.COUNT LOOP
--
        IF ( pre_req_no <> lt_main_data(get_user_rec).request_no ) THEN
--
          IF ( get_user_rec <> 1 ) THEN
            --データグループ名終了タグセット
            insert_xml_plsql_table(iox_xml_data, '/lg_mei', NULL, 'T', 'C');
--
            --データセット(計)
            insert_xml_plsql_table(iox_xml_data, 'sum_palette', 
                                    lt_main_data(get_user_rec -1).pallet_sum_quantity,'D','C');
            insert_xml_plsql_table(iox_xml_data, 'sum_weight', 
                                    lt_main_data(get_user_rec -1).sum_weight, 'D', 'C');
            insert_xml_plsql_table(iox_xml_data, 'unit_sum2', 
                                    lt_main_data(get_user_rec -1).sum_weight_capacity_class, 'D', 'C');
            insert_xml_plsql_table(iox_xml_data, 'carry_rate', 
                                    lt_main_data(get_user_rec -1).loading_efficiency_weight, 'D', 'C');
--
            --データグループ名終了タグセット
            insert_xml_plsql_table(iox_xml_data, '/g_irai',NULL,'T','C');
-- 2008/07/03 ST不具合対応#344 Start
            IF ( pre_add_l_name <> lt_main_data(get_user_rec).address_line_name ) THEN
              --データグループ名終了タグセット
              insert_xml_plsql_table(iox_xml_data, '/lg_irai_info',NULL,'T','C');
--
              --データグループ名開始タグセット
              insert_xml_plsql_table(iox_xml_data, 'lg_irai_info', NULL, 'T', 'C');
--
            END IF;
-- 2008/07/03 ST不具合対応#344 End
          END IF;
--
          --データグループ名開始タグセット
          insert_xml_plsql_table(iox_xml_data, 'g_irai', NULL, 'T', 'C');
--
          --データセット（ヘッダ）
          insert_xml_plsql_table(iox_xml_data, 'tyohyo_id', gc_report_id, 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'exec_time', 
                                       TO_CHAR(ld_now_date, gc_char_d_format2), 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'post' ,gv_department_code, 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'name', gv_department_name, 'D', 'C');
--
          --データセット(左)
          insert_xml_plsql_table(iox_xml_data, 'req_no', 
                                  lt_main_data(get_user_rec).request_no, 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'client_code', 
                                  lt_main_data(get_user_rec).customer_code, 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'client_name', 
                                  lt_main_data(get_user_rec).party_short_name, 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'delivery_address', 
                                  lt_main_data(get_user_rec).address, 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'control_code', 
                                  lt_main_data(get_user_rec).address_line1, 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'control_name', 
                                  lt_main_data(get_user_rec).address_line_name, 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'delivery_code', 
                                  lt_main_data(get_user_rec).deliver_to, 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'delivery_name', 
                                  lt_main_data(get_user_rec).party_site_full_name, 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'mix_no', 
                                  lt_main_data(get_user_rec).mixed_no, 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'order_no', 
                                  lt_main_data(get_user_rec).cust_po_number, 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'ship_day', 
             TO_CHAR(lt_main_data(get_user_rec).schedule_ship_date, gc_char_d_format), 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'arrive_day', 
             TO_CHAR(lt_main_data(get_user_rec).schedule_arrival_date,
                                                                    gc_char_d_format), 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'from_time', 
                                  lt_main_data(get_user_rec).arrival_time_from, 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'to_time', 
                                  lt_main_data(get_user_rec).arrival_time_to, 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'ship_form', 
                                  lt_main_data(get_user_rec).order_type_id, 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'req_division', 
                                  lt_main_data(get_user_rec).meaning1, 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'delivery_division', 
                                  lt_main_data(get_user_rec).ship_method_meaning, 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'collect_palette', 
                                  lt_main_data(get_user_rec).collected_pallet_qty, 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'status', 
                                  lt_main_data(get_user_rec).meaning2, 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'pd_division', 
                                  lt_main_data(get_user_rec).meaning3, 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'abstract', 
                                  lt_main_data(get_user_rec).shipping_instructions, 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'shipment_code', 
                                  lt_main_data(get_user_rec).deliver_from, 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'shipment_name', 
                                  lt_main_data(get_user_rec).description, 'D', 'C');
          --データグループ名開始タグセット
          insert_xml_plsql_table(iox_xml_data, 'lg_mei', NULL, 'T', 'C');
--
          pre_req_no      := lt_main_data(get_user_rec).request_no;
-- 2008/07/03 ST不具合対応#344 Start
          pre_add_l_name      := lt_main_data(get_user_rec).address_line_name;
-- 2008/07/03 ST不具合対応#344 End
--
        END IF;
--
        --データグループ名開始タグセット
        insert_xml_plsql_table(iox_xml_data, 'g_mei' , NULL, 'T', 'C');
        --データセット(右)
        insert_xml_plsql_table(iox_xml_data, 'list_code', 
                                lt_main_data(get_user_rec).request_item_code, 'D', 'C');
        insert_xml_plsql_table(iox_xml_data, 'list_name', 
                                lt_main_data(get_user_rec).item_short_name, 'D', 'C');
        insert_xml_plsql_table(iox_xml_data, 'num_palette', 
                                lt_main_data(get_user_rec).pallet_quantity, 'D', 'C');
        insert_xml_plsql_table(iox_xml_data, 'steps_palette', 
                                lt_main_data(get_user_rec).layer_quantity, 'D', 'C');
        insert_xml_plsql_table(iox_xml_data, 'num_case', 
                                lt_main_data(get_user_rec).case_quantity, 'D', 'C');
        insert_xml_plsql_table(iox_xml_data, 'sum', 
                                lt_main_data(get_user_rec).quantity, 'D', 'C');
        insert_xml_plsql_table(iox_xml_data, 'unit_sum1', 
                                lt_main_data(get_user_rec).item_um, 'D', 'C');
        insert_xml_plsql_table(iox_xml_data, 'in_num', 
                                lt_main_data(get_user_rec).num_of_cases, 'D', 'C');
        insert_xml_plsql_table(iox_xml_data, 'total_weight', 
-- 2008/07/03 ST不具合対応#344 Start
--                                lt_main_data(get_user_rec).weight, 'D', 'C');
                                CEIL(TRUNC(lt_main_data(get_user_rec).weight, 1)), 'D', 'C');
-- 2008/07/03 ST不具合対応#344 End
        insert_xml_plsql_table(iox_xml_data, 'unit_total', 
                                lt_main_data(get_user_rec).weight_capacity_class, 'D', 'C');
--
        --データグループ名終了タグセット
        insert_xml_plsql_table(iox_xml_data, '/g_mei', NULL, 'T', 'C');
--
      END LOOP lg_irai_info;
--
      --データグループ名終了タグセット
      insert_xml_plsql_table(iox_xml_data, '/lg_mei', NULL, 'T', 'C');
--
      --データセット(計)
      insert_xml_plsql_table(iox_xml_data, 'sum_palette', 
                              lt_main_data(lt_main_data.COUNT).pallet_sum_quantity,'D','C');
      insert_xml_plsql_table(iox_xml_data, 'sum_weight', 
-- 2008/07/03 ST不具合対応#344 Start
--                              lt_main_data(lt_main_data.COUNT).sum_weight, 'D', 'C');
                             CEIL(TRUNC(lt_main_data(lt_main_data.COUNT).sum_weight, 1)), 'D', 'C');
-- 2008/07/03 ST不具合対応#344 End
      insert_xml_plsql_table(iox_xml_data, 'unit_sum2', 
                              lt_main_data(lt_main_data.COUNT).sum_weight_capacity_class, 'D', 'C');
      insert_xml_plsql_table(iox_xml_data, 'carry_rate', 
                              lt_main_data(lt_main_data.COUNT).loading_efficiency_weight, 'D', 'C');
--
      --データグループ名終了タグセット
      insert_xml_plsql_table(iox_xml_data, '/g_irai',NULL,'T','C');
--
    END IF ;
   -- ==================================================
   -- 終了ステータス設定
   -- ==================================================
    ov_retcode := lv_retcode;
--  
  EXCEPTION
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--####################################  固定部 END   ##########################################
--
  END create_xml;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_head_sales_branch       IN  VARCHAR2,      --   1.管轄拠点
    iv_input_sales_branch      IN  VARCHAR2,      --   2.入力拠点
    iv_deliver_to              IN  VARCHAR2,      --   3.配送先
    iv_deliver_from            IN  VARCHAR2,      --   4.出荷元
    iv_ship_date_from          IN  VARCHAR2,      --   5.出庫日From
    iv_ship_date_to            IN  VARCHAR2,      --   6.出庫日To
    iv_arrival_date_from       IN  VARCHAR2,      --   7.着日From
    iv_arrival_date_to         IN  VARCHAR2,      --   8.着日To
    iv_order_type_id           IN  VARCHAR2,      --   9.出庫形態
    iv_request_no              IN  VARCHAR2,      --   10.依頼No.
    iv_req_status              IN  VARCHAR2,      --   11.出荷依頼ステータス
    iv_confirm_request_class   IN  VARCHAR2,      --   12.物流担当確認依頼区分
    iv_prod_class              IN  VARCHAR2,      --   13.商品区分  2008/07/01 ST不具合対応#331
    ov_errbuf                  OUT VARCHAR2,      --   エラー・メッセージ           --# 固定 #
    ov_retcode                 OUT VARCHAR2,      --   リターン・コード             --# 固定 #
    ov_errmsg                  OUT VARCHAR2)      --   ユーザー・エラー・メッセージ --# 固定 #
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
    lr_param_rec     rec_param_data ;          -- パラメータ受渡し用
--
    xml_data_table   XML_DATA;
    lv_xml_string    VARCHAR2(32000);
    ln_retcode       NUMBER;
--
    -- *** ローカル変数 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- =====================================================
    -- 初期処理
    -- =====================================================
    -- パラメータ格納
    lr_param_rec.iv_head_sales_branch     := iv_head_sales_branch;      -- 1.管轄拠点
    lr_param_rec.iv_input_sales_branch    := iv_input_sales_branch;     -- 2.入力拠点
    lr_param_rec.iv_deliver_to            := iv_deliver_to;             -- 3.配送先
    lr_param_rec.iv_deliver_from          := iv_deliver_from;           -- 4.出荷元
    lr_param_rec.iv_ship_date_from        := iv_ship_date_from;         -- 5.出庫日From
    lr_param_rec.iv_ship_date_to          := iv_ship_date_to;           -- 6.出庫日To
    lr_param_rec.iv_arrival_date_from     := iv_arrival_date_from;      -- 7.着日From
    lr_param_rec.iv_arrival_date_to       := iv_arrival_date_to;        -- 8.着日To
    lr_param_rec.iv_order_type_id         := iv_order_type_id;          -- 9.出庫形態
    lr_param_rec.iv_request_no            := iv_request_no;             -- 10.依頼No.
    lr_param_rec.iv_req_status            := iv_req_status;             -- 11.出荷依頼ステータス
    lr_param_rec.iv_confirm_request_class := iv_confirm_request_class;  -- 12.物流担当確認依頼区分
    lr_param_rec.iv_prod_class            := iv_prod_class;             -- 13.商品区分  2008/07/01 ST不具合対応#331
--
    -- =====================================================
    --  関連データ取得
    -- =====================================================
    pro_get_cus_option
      (
        ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    -- 前処理(担当者情報抽出)
    -- =====================================================
    prc_initialize
      (
        ir_param          => lr_param_rec       -- 入力パラメータ群
       ,ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ===============================================
    -- XMLデータ(Temp)作成
    -- ===============================================
    
    create_xml(
      xml_data_table
      ,ir_param          => lr_param_rec       -- 入力パラメータレコード
      ,ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
      ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    -- ==================================================
    -- ＸＭＬ出力(C-4)
    -- ==================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  <data_info>' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <lg_irai_info>' ) ;

--
    -- --------------------------------------------------
    -- 帳票データが出力できた場合
    -- --------------------------------------------------
    --XMLデータ部出力
    <<xml_loop>>
    FOR i IN 1 .. xml_data_table.COUNT LOOP
      -- 編集したデータをタグに変換
      lv_xml_string := convert_into_xml
                        (
                          iv_name   => xml_data_table(i).tag_name    -- タグネーム
                         ,iv_value  => xml_data_table(i).tag_value   -- タグデータ
                         ,ic_type   => xml_data_table(i).tag_type    -- タグタイプ
                        ) ;
      -- ＸＭＬタグ出力
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, lv_xml_string ) ;
    END LOOP xml_loop ;
    
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    </lg_irai_info>' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  </data_info>' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
    -- ==================================================
    -- 終了ステータス設定
    -- ==================================================
    ov_retcode := lv_retcode ;
    ov_errmsg  := lv_errmsg ;
    ov_errbuf  := lv_errbuf ;

--
  EXCEPTION
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--####################################  固定部 END   ##########################################
--
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf                     OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode                    OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_head_sales_branch       IN  VARCHAR2,      --   1.管轄拠点
    iv_input_sales_branch      IN  VARCHAR2,      --   2.入力拠点
    iv_deliver_to              IN  VARCHAR2,      --   3.配送先
    iv_deliver_from            IN  VARCHAR2,      --   4.出荷元
    iv_ship_date_from          IN  VARCHAR2,      --   5.出庫日From
    iv_ship_date_to            IN  VARCHAR2,      --   6.出庫日To
    iv_arrival_date_from       IN  VARCHAR2,      --   7.着日From
    iv_arrival_date_to         IN  VARCHAR2,      --   8.着日To
    iv_order_type_id           IN  VARCHAR2,      --   9.出庫形態
    iv_request_no              IN  VARCHAR2,      --   10.依頼No.
    iv_req_status              IN  VARCHAR2,      --   11.出荷依頼ステータス
    iv_confirm_request_class   IN  VARCHAR2,      --   12.物流担当確認依頼区分
    iv_prod_class              IN  VARCHAR2       --   13.商品区分 2008/07/01 ST不具合対応#331
  )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'XXWSH400009c.main';  -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
  BEGIN
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      iv_head_sales_branch     => iv_head_sales_branch,     --   1.管轄拠点
      iv_input_sales_branch    => iv_input_sales_branch,    --   2.入力拠点
      iv_deliver_to            => iv_deliver_to,            --   3.配送先
      iv_deliver_from          => iv_deliver_from,          --   4.出荷元
      iv_ship_date_from        => iv_ship_date_from,        --   5.出庫日From
      iv_ship_date_to          => iv_ship_date_to,          --   6.出庫日To
      iv_arrival_date_from     => iv_arrival_date_from,     --   7.着日From
      iv_arrival_date_to       => iv_arrival_date_to,       --   8.着日To
      iv_order_type_id         => iv_order_type_id,         --   9.出庫形態
      iv_request_no            => iv_request_no,            --   10.依頼No.
      iv_req_status            => iv_req_status,            --   11.出荷依頼ステータス
      iv_confirm_request_class => iv_confirm_request_class, --   12.物流担当確認依頼区分
      iv_prod_class            => iv_prod_class,            --   13.商品区分 2008/07/01 ST不具合対応#331
      ov_errbuf                => lv_errbuf,      --   エラー・メッセージ           --# 固定 #
      ov_retcode               => lv_retcode,     --   リターン・コード             --# 固定 #
      ov_errmsg                => lv_errmsg);     --   ユーザー・エラー・メッセージ --# 固定 #
--
--###########################  固定部 START   #####################################################
--
    -- ======================
    -- エラー・メッセージ出力
    -- ======================
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
    retcode := lv_retcode;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END xxwsh400009c;
/
