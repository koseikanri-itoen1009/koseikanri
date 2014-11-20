CREATE OR REPLACE PACKAGE BODY xxwsh620008c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh620008c(body)
 * Description      : 積込指示書
 * MD.050           : 引当/配車(帳票) T_MD050_BPO_621
 * MD.070           : 積込指示書 T_MD070_BPO_62J
 * Version          : 1.5
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  prcsub_set_xml_data       タグ情報設定処理
 *  prcsub_set_xml_data       タグ情報設定処理(開始・終了タグ用)
 *  convert_into_xml          ＸＭＬタグに変換する。
 *  insert_xml_plsql_table    XMLデータ格納
 *  prc_initialize            プロファイル値取得、担当者情報抽出(H-1,H-2)
 *  prc_get_report_data       明細データ取得(H-3)
 *  prc_create_xml_data       ＸＭＬデータ作成(H-4)
 *  submain                   メイン処理プロシージャ
 *  main                      コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ------------------ -------------------------------------------------
 *  Date          Ver.  Editor             Description
 * ------------- ----- ------------------ -------------------------------------------------
 *  2008/03/25    1.0   Yoshitomo Kawasaki 新規作成
 *  2008/06/23    1.1   Yoshikatsu Shindou 配送区分情報VIEWのリレーションを外部結合に変更
 *                                         小口区分がNULLの時の処理を追加
 *  2008/07/03    1.2   Jun Nakada         ST不具合対応No412 重量容積の小数第一位切り上げ
 *  2008/07/07    1.3   Akiyoshi Shiina    変更要求対応#92
 *                                         禁則文字「'」「"」「<」「>」「＆」対応
 *  2008/07/15    1.4   Masayoshi Uehara   入数の小数部を切り捨てて、整数で表示
 *  2008/10/27    1.5   Yuko Kawano        統合指摘#133、課題#32,#62、内部変更#183対応
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_status_normal             CONSTANT VARCHAR2(1)   := '0' ;
  gv_status_warn               CONSTANT VARCHAR2(1)   := '1' ;
  gv_status_error              CONSTANT VARCHAR2(1)   := '2' ;
  gv_msg_part                  CONSTANT VARCHAR2(3)   := ' : ' ;
  gv_msg_cont                  CONSTANT VARCHAR2(3)   := '.';
--
--################################  固定部 END   ###############################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
--################################  固定部 END   ###############################
--
  -- ======================================================
  -- ユーザー宣言部
  -- ======================================================
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name                   CONSTANT VARCHAR2(20) :=  'xxwsh620008c';       -- パッケージ名
  gc_report_id                  CONSTANT VARCHAR2(12) :=  'XXWSH620008T';       -- 帳票ID
  gc_tag_type_tag               CONSTANT VARCHAR2(1)  :=  'T' ;     -- 出力タグタイプ（T：タグ）
  gc_tag_type_data              CONSTANT VARCHAR2(1)  :=  'D' ;     -- 出力タグタイプ（D：データ）
--
  ------------------------------
  -- クイックコード関連
  ------------------------------
  gc_quick_code_gyoumushubetsu  CONSTANT VARCHAR2(23) :=  'XXWSH_SHIPPING_BIZ_TYPE' ;
--
  ------------------------------
  -- エラーメッセージ関連
  ------------------------------
  gc_application_cmn            CONSTANT VARCHAR2(5)  :=  'XXCMN' ;   -- アプリケーション（XXCMN）
  gc_application_wsh            CONSTANT VARCHAR2(5)  :=  'XXWSH' ;   -- アプリケーション(XXWSH)
  -- 明細0件用メッセージ
  gc_xxcmn_10122                CONSTANT VARCHAR2(15) :=  'APP-XXCMN-10122' ;
  -- プロファイル取得エラー
  gc_msg_id_not_get_prof        CONSTANT VARCHAR2(15) :=  'APP-XXWSH-12301' ;
--
  ------------------------------
  -- 項目編集関連
  ------------------------------
  gc_char_d_format              CONSTANT VARCHAR2(10) :=  'YYYY/MM/DD' ;
  gc_char_dt_format             CONSTANT VARCHAR2(21) :=  'YYYY/MM/DD HH24:MI:SS' ;
  gc_tag_p_format               CONSTANT VARCHAR2(9)  :=  '99990.900' ;
  gc_tag_b_format               CONSTANT VARCHAR2(10) :=  '9999990.90' ;
  lc_date_jikanshitei_format    CONSTANT VARCHAR2(6)  :=  'HH24MI' ;
--
  ------------------------------
  -- プロファイル関連
  ------------------------------
  gc_prof_name_weight           CONSTANT VARCHAR2(20) :=  'XXWSH_WEIGHT_UOM' ;    -- 出荷重量単位
  gc_prof_name_capacity         CONSTANT VARCHAR2(20) :=  'XXWSH_CAPACITY_UOM' ;  -- 出荷容積単位
  --メッセージ-トークン名
  gc_msg_tkn_nm_prof            CONSTANT VARCHAR2(10) :=  'PROF_NAME' ;           -- プロファイル名
  --メッセージ-トークン値
  gc_msg_tkn_val_prof_wei       CONSTANT VARCHAR2(20) :=  'XXWSH:出荷重量単位' ;
  gc_msg_tkn_val_prof_cap       CONSTANT VARCHAR2(20) :=  'XXWSH:出荷容積単位' ;
--
  gc_msg_shizisyo               CONSTANT VARCHAR2(6)  :=  '指示書' ;
  -- 帳票出力名をセット
  gc_out_char_title_shukko      CONSTANT VARCHAR2(4)  :=  '出庫' ;
  gc_out_char_title_idou        CONSTANT VARCHAR2(4)  :=  '移動' ;
--
  -- 出荷(CODE)
  gc_code_shukka                CONSTANT VARCHAR2(1)  :=  '1' ;
--
  gc_tehai_label                CONSTANT VARCHAR2(8)  :=  '手配No：' ;            -- 手配№
--
-- 2008/10/27 Y.Kawano Add Start
  gc_class_y                    CONSTANT VARCHAR2(1)  :=  'Y';  -- 区分値'Y'
-- 2008/10/27 Y.Kawano Add End
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 入力パラメータ格納用レコード変数
  TYPE rec_param_data  IS RECORD 
    (
      -- 01 : 業務種別
       iv_business_type       VARCHAR2(1)
      -- 02:ブロック１
      ,iv_block_1             xxcmn_item_locations2_v.distribution_block%TYPE
      -- 03:ブロック２
      ,iv_block_2             xxcmn_item_locations2_v.distribution_block%TYPE
      -- 04:ブロック３
      ,iv_block_3             xxcmn_item_locations2_v.distribution_block%TYPE
      -- 05:出庫元
      ,iv_delivery_origin     xxwsh_order_headers_all.deliver_from%TYPE
      -- 06:出庫日
      ,iv_delivery_day        xxwsh_order_headers_all.schedule_ship_date%TYPE
      -- 07:配送№
      ,iv_delivery_no         xxwsh_order_headers_all.delivery_no%TYPE
      -- 08:出庫形態
      ,iv_delivery_form       xxwsh_oe_transaction_types_v.transaction_type_id%TYPE
      -- 09 : 管轄拠点
      ,iv_jurisdiction_base   xxwsh_order_headers_all.head_sales_branch%TYPE
      -- 10 : 配送先/入庫先
      ,iv_addre_delivery_dest xxwsh_order_headers_all.deliver_to%TYPE
      -- 11 : 依頼№/移動№
      ,iv_request_movement_no xxwsh_order_headers_all.request_no%TYPE
      -- 12 : 商品区分
      ,iv_commodity_div       xxcmn_item_categories4_v.prod_class_code%TYPE
    ) ;
--
  -- 積込指示書取得レコード変数(出荷、移動共通)
  TYPE rec_data_type_dtl  IS RECORD 
    (
      -- 業務種別
       gyoumu_shubetsu        VARCHAR2(4)
      -- 配送No
      ,delivery_no            xxwsh_order_headers_all.delivery_no%TYPE
      -- 出庫元(コード)
      ,deliver_from           xxwsh_order_headers_all.deliver_from%TYPE
      -- 出庫元(名称)
      ,description            xxcmn_item_locations2_v.description%TYPE
      -- 運送業者(コード)
      ,freight_carrier_code   xxwsh_order_headers_all.freight_carrier_code%TYPE
      -- 運送業者(名称)
      ,party_short_name1      xxcmn_carriers2_v.party_short_name%TYPE
      -- 依頼No／移動No
      ,request_no             xxwsh_order_headers_all.request_no%TYPE
      -- 出庫形態
      ,transaction_type_name  xxwsh_oe_transaction_types_v.transaction_type_name%TYPE
      -- 配送先／入庫先(コード)
      ,deliver_to             xxwsh_order_headers_all.deliver_to%TYPE
      -- 配送先／入庫先(名称)
      ,party_site_name        xxcmn_cust_acct_sites2_v.party_site_name%TYPE
      -- 配送区分(コード)
      ,shipping_method_code   xxwsh_order_headers_all.shipping_method_code%TYPE
      -- 配送区分(名称)
      ,ship_method_meaning    xxwsh_ship_method2_v.ship_method_meaning%TYPE
      -- 管轄拠点(コード)
      ,head_sales_branch      xxwsh_order_headers_all.head_sales_branch%TYPE
      -- 管轄拠点(名称)
      ,party_name             xxcmn_cust_accounts2_v.party_name%TYPE
      -- 出庫日
      ,schedule_ship_date     xxwsh_order_headers_all.schedule_ship_date%TYPE
      -- 着日
      ,schedule_arrival_date  xxwsh_order_headers_all.schedule_arrival_date%TYPE
      -- 時間指定From
      ,arrival_time_from      xxwsh_order_headers_all.arrival_time_from%TYPE
      -- 時間指定To
      ,arrival_time_to        xxwsh_order_headers_all.arrival_time_to%TYPE
      -- 摘要
      ,shipping_instructions  xxwsh_order_headers_all.shipping_instructions%TYPE
      -- 手配No
      ,batch_no               xxinv_mov_req_instr_headers.batch_no%TYPE
      -- 品目(コード)
      ,shipping_item_code     xxwsh_order_lines_all.shipping_item_code%TYPE
      -- 品目(名称)
      ,item_short_name        xxcmn_item_mst2_v.item_short_name%TYPE
      -- ロットNo
      ,lot_no                 xxinv_mov_lot_details.lot_no%TYPE
      -- 製造日
      ,attribute1             ic_lots_mst.attribute1%TYPE
      -- 賞味期限
      ,attribute3             ic_lots_mst.attribute3%TYPE
      -- 固有記号
      ,attribute2             ic_lots_mst.attribute2%TYPE
      -- 入数
      ,qty                    xxcmn_item_mst2_v.num_of_cases%TYPE
      -- 合計数(明細単位)
      ,sum_quantity           xxwsh_order_lines_all.quantity%TYPE
      -- 合計数_単位(明細単位)
      ,sum_item_um            xxcmn_item_mst2_v.item_um%TYPE
      -- 合計重量(明細単位)
      ,sum_weight_mei         xxwsh_order_headers_all.sum_weight%TYPE
      -- 合計容積(明細単位)
      ,sum_capacity_mei       xxwsh_order_headers_all.sum_capacity%TYPE
      -- 依頼重量(依頼合計単位)
      ,sum_weight_irai        xxwsh_order_headers_all.sum_weight%TYPE
      -- 依頼容積(依頼合計単位)
      ,sum_capacity_irai      xxwsh_order_headers_all.sum_capacity%TYPE
-- 2008/07/07 A.Shiina v1.3 ADD Start
      -- 運賃区分
      ,freight_charge_code    xxwsh_order_headers_all.freight_charge_class%TYPE
      -- 強制出力区分
      ,complusion_output_kbn  xxcmn_carriers2_v.complusion_output_code%TYPE
-- 2008/07/07 A.Shiina v1.3 ADD End
    ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  ------------------------------
  -- ＸＭＬ用
  ------------------------------
  gd_exec_date              DATE ;                -- 実施日
  gv_department_code        VARCHAR2(10) ;        -- 担当部署
  gv_department_name        VARCHAR2(14) ;        -- 担当者
--
  gt_main_data              tab_data_type_dtl ;   -- 取得レコード表
  gt_xml_data_table         XML_DATA ;            -- XMLデータ
--
  --単位
  gv_uom_weight             VARCHAR2(3);
  gv_uom_capacity           VARCHAR2(3);
--
  gv_out_char_title         VARCHAR2(4);
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
  /**********************************************************************************
   * Procedure Name   : prcsub_set_xml_data
   * Description      : タグ情報設定処理
   ***********************************************************************************/
  PROCEDURE prcsub_set_xml_data(
     ivsub_tag_name       IN  VARCHAR2                 -- タグ名
    ,ivsub_tag_value      IN  VARCHAR2                 -- データ
    ,ivsub_tag_type       IN  VARCHAR2  DEFAULT NULL   -- データ
  )
  IS
    ln_data_index  NUMBER ;    -- XMLデータを設定するインデックス
  BEGIN
    ln_data_index := gt_xml_data_table.COUNT + 1 ;
--
    gt_xml_data_table(ln_data_index).tag_name := ivsub_tag_name ;
--
    IF ((ivsub_tag_value IS NULL) AND (ivsub_tag_type = gc_tag_type_tag)) THEN
      -- タグ出力
      gt_xml_data_table(ln_data_index).tag_type := gc_tag_type_tag;
    ELSE
      -- データ出力
      gt_xml_data_table(ln_data_index).tag_type := gc_tag_type_data;
      gt_xml_data_table(ln_data_index).tag_value := ivsub_tag_value;
    END IF;
  END prcsub_set_xml_data ;
--
  /**********************************************************************************
   * Procedure Name   : prcsub_set_xml_data
   * Description      : タグ情報設定処理(開始・終了タグ用)
   ***********************************************************************************/
  PROCEDURE prcsub_set_xml_data(
     ivsub_tag_name       IN  VARCHAR2  -- タグ名
  )
  IS
  BEGIN
    prcsub_set_xml_data(ivsub_tag_name, NULL, gc_tag_type_tag);
  END prcsub_set_xml_data ;
--
  /**********************************************************************************
   * Function Name    : convert_into_xml
   * Description      : ＸＭＬタグに変換する。
   ***********************************************************************************/
  FUNCTION convert_into_xml(
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
    IF (ic_type = gc_tag_type_data) THEN
      lv_convert_data := '<'||iv_name||'><![CDATA['||iv_value||']]></'||iv_name||'>' ;
    ELSE
      lv_convert_data := '<'||iv_name||'>' ;
    END IF ;
--
    RETURN(lv_convert_data) ;
--
  END convert_into_xml ;
--
  /**********************************************************************************
   * Procedure Name   : insert_xml_plsql_table
   * Description      : XMLデータ格納
   ***********************************************************************************/
  PROCEDURE insert_xml_plsql_table(
     iv_tag_name       IN     VARCHAR2
    ,iv_tag_value      IN     VARCHAR2
    ,ic_tag_type       IN     CHAR
    ,ic_tag_value_type IN     CHAR                     --   ユーザー・エラー・メッセージ --# 固定 #
    ,iox_xml_data      IN OUT NOCOPY xml_data
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
    lv_count  NUMBER;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
    lv_count                            := iox_xml_data.COUNT + 1 ;
    iox_xml_data(lv_count).TAG_NAME     := iv_tag_name ;
--
    IF ( ic_tag_value_type = 'P' ) THEN
      iox_xml_data(lv_count).TAG_VALUE  := TO_CHAR(TO_NUMBER(iv_tag_value), gc_tag_p_format) ;
    ELSIF (ic_tag_value_type = 'B') THEN
      iox_xml_data(lv_count).TAG_VALUE  := TO_CHAR(TO_NUMBER(iv_tag_value), gc_tag_b_format) ;
    ELSE
      iox_xml_data(lv_count).TAG_VALUE  := iv_tag_value ;
    END IF;
    iox_xml_data(lv_count).TAG_TYPE     := ic_tag_type ;
--
  END insert_xml_plsql_table ;
--
  /**********************************************************************************
   * Procedure Name   : prc_initialize
   * Description      : プロファイル値取得、担当者情報抽出(H-1,H-2)
   ***********************************************************************************/
  PROCEDURE prc_initialize
    (
      ov_errbuf     OUT    VARCHAR2         -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT    VARCHAR2         -- リターン・コード             --# 固定 #
     ,ov_errmsg     OUT    VARCHAR2         -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_initialize' ; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf   VARCHAR2(5000) ;  -- エラー・メッセージ
    lv_retcode  VARCHAR2(1) ;     -- リターン・コード
    lv_errmsg   VARCHAR2(5000) ;  -- ユーザー・エラー・メッセージ
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
    get_prof_expt   EXCEPTION ;     -- プロファイル取得例外ハンドラ
--
  BEGIN
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ====================================================
    -- プロファイル取得(H-1)
    -- ====================================================
    -- ====================================================
    -- 出荷重量単位取得
    -- ====================================================
    gv_uom_weight := FND_PROFILE.VALUE(gc_prof_name_weight) ;
    IF (gv_uom_weight IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh
                                            ,gc_msg_id_not_get_prof
                                            ,gc_msg_tkn_nm_prof
                                            ,gc_msg_tkn_val_prof_wei
                                           ) ;
      RAISE get_prof_expt ;
    END IF ;
--
    -- ====================================================
    -- 出荷容積単位取得
    -- ====================================================
    gv_uom_capacity := FND_PROFILE.VALUE(gc_prof_name_capacity) ;
    IF (gv_uom_capacity IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh
                                            ,gc_msg_id_not_get_prof
                                            ,gc_msg_tkn_nm_prof
                                            ,gc_msg_tkn_val_prof_cap
                                           ) ;
      RAISE get_prof_expt ;
    END IF ;
--
    -- ====================================================
    -- 担当者情報抽出(H-2)
    -- ====================================================
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
    --*** プロファイル取得例外ハンドラ ***
    WHEN get_prof_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
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
   * Description      : 明細データ取得(H-3)
   ***********************************************************************************/
  PROCEDURE prc_get_report_data(
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
    lc_code_seihin                  CONSTANT VARCHAR2(1)  :=  '5' ;         -- 製品
    lc_code_genryou                 CONSTANT VARCHAR2(1)  :=  '1' ;         -- 原料
    lc_code_hanseihin               CONSTANT VARCHAR2(1)  :=  '4' ;         -- 半製品
    lc_item_cd_shizai               CONSTANT  VARCHAR2(1) :=  '2' ;          -- 資材
    lc_small_amount_enabled         CONSTANT VARCHAR2(1)  :=  '1' ;         -- 小口区分が対象
    lc_small_amount_disabled        CONSTANT VARCHAR2(1)  :=  '0' ;         -- 小口区分が対象外
    lc_employee_division_inside     CONSTANT VARCHAR2(1)  :=  '1' ;         -- 従業員区分(1:内部)
    lc_employee_division_outside    CONSTANT VARCHAR2(1)  :=  '2' ;         -- 従業員区分(2:外部)
    lc_fixa_notif_end               CONSTANT VARCHAR2(2)  :=  '40' ;        -- 確定通知済
    lc_record_type_shizi            CONSTANT VARCHAR2(2)  :=  '10' ;        -- レコードタイプ(指示)
    lc_doc_type_shukka_irai         CONSTANT VARCHAR2(2)  :=  '10' ;        -- 文章タイプ(出荷依頼)
    lc_doc_type_idou                CONSTANT VARCHAR2(2)  :=  '20' ;        -- 文章タイプ(移動)
    lc_category_return              CONSTANT VARCHAR2(6)  :=  'RETURN' ;    -- 返品(受注のみ)
    lc_status_shimezumi             CONSTANT VARCHAR2(2)  :=  '03' ;        -- 締め済み
    lc_status_torikeshi             CONSTANT VARCHAR2(2)  :=  '99' ;        -- 取消
    lc_status_irai_zumi             CONSTANT VARCHAR2(2)  :=  '02' ;        -- 依頼済
    lc_mov_type_sekisou_nashi       CONSTANT VARCHAR2(1)  :=  '2' ;         -- 積送無し
    lc_shikyu_cls_shukka_irai       CONSTANT VARCHAR2(1)  :=  '1' ;         -- 出荷依頼
    lc_delete_flag                  CONSTANT VARCHAR2(1)  :=  'Y' ;         -- 削除フラグ
    -- クイックコード情報VIEW(出庫/配送区分)
    lc_quick_code_shu_haisou_kbn    CONSTANT VARCHAR2(27) :=  'XXWSH_620F_SHIP_DELIV_CLASS' ;
--
    -- *** ローカル・カーソル ***
    ------------------------------------------------------------------------
    -- 出荷の場合
    ------------------------------------------------------------------------
    CURSOR cur_main_data1
      (
         in_block_1               VARCHAR2
        ,in_block_2               VARCHAR2
        ,in_block_3               VARCHAR2
        ,in_delivery_origin       VARCHAR2
        ,in_delivery_day          VARCHAR2
        ,in_delivery_no           VARCHAR2
        ,in_delivery_form         VARCHAR2
        ,in_jurisdiction_base     VARCHAR2
        ,in_addre_delivery_dest   VARCHAR2
        ,in_request_movement_no   VARCHAR2
        ,in_commodity_div         VARCHAR2
      )
    IS
      SELECT
                 '出荷'                           AS gyoumu_shubetsu        -- 業務種別
                ,xoha.delivery_no                 AS delivery_no            -- 配送No
                ,xoha.deliver_from                AS deliver_from           -- 出庫元(コード)
                ,xil2v.description                AS description            -- 出庫元(名称)
                ,xoha.freight_carrier_code        AS freight_carrier_code   -- 運送業者(コード)
                ,xc2v.party_short_name            AS party_short_name1      -- 運送業者(名称)
                ,xoha.request_no                  AS request_no             -- 依頼No／移動No
                ,xott2v.transaction_type_name     AS transaction_type_name  -- 出庫形態
                ,xoha.deliver_to                  AS deliver_to             -- 配送先／入庫先(ｺｰﾄﾞ)
                ,xcas2v.party_site_full_name      AS party_site_full_name   -- 配送先／入庫先(名称)
                ,xoha.shipping_method_code        AS shipping_method_code   -- 配送区分(コード)
                ,xsm2v.ship_method_meaning        AS ship_method_meaning    -- 配送区分(名称)
                ,xoha.head_sales_branch           AS head_sales_branch      -- 管轄拠点(コード)
                ,xca2v.party_name                 AS party_name             -- 管轄拠点(名称)
                ,xoha.schedule_ship_date          AS schedule_ship_date     -- 出庫日
                ,xoha.schedule_arrival_date       AS schedule_arrival_date  -- 着日
                ,xoha.arrival_time_from           AS arrival_time_from      -- 時間指定From
                ,xoha.arrival_time_to             AS arrival_time_to        -- 時間指定To
                ,xoha.shipping_instructions       AS shipping_instructions  -- 摘要
                ,''                               AS tehai_no               -- 手配No
                ,xola.shipping_item_code          AS shipping_item_code     -- 品目(コード)
                ,xim2v1.item_short_name           AS item_short_name        -- 品目(名称)
                ,xmldt.lot_no                     AS lot_no                 -- ロットNo
                ,ilm.attribute1                   AS attribute1             -- 製造日
                ,ilm.attribute3                   AS attribute3             -- 賞味期限
                ,ilm.attribute2                   AS attribute2             -- 固有記号
                ,CASE
                  -- 製品の場合
-- 2008/10/27 Y.Kawano Mod Start #183
--                  WHEN ((xic4v1.item_class_code = lc_code_seihin) 
                  WHEN ((xic5v1.item_class_code = lc_code_seihin) 
-- 2008/10/27 Y.Kawano Mod End #183
                         AND 
                        (ilm.attribute6 IS NOT NULL)) THEN 
                          xim2v1.num_of_cases
                  -- その他の品目の場合
-- 2008/10/27 Y.Kawano Mod Start #183
--                  WHEN (((xic4v1.item_class_code = lc_code_genryou) 
--                          OR  
--                          (xic4v1.item_class_code = lc_code_hanseihin))
                  WHEN (((xic5v1.item_class_code = lc_code_genryou) 
                          OR  
                          (xic5v1.item_class_code = lc_code_hanseihin))
-- 2008/10/27 Y.Kawano Mod End #183
                        AND 
                        (ilm.attribute6 IS NOT NULL)) THEN 
                         TO_CHAR(TRUNC(ilm.attribute6))
                  -- 在庫入数が設定されていない,資材他,ロット管理していない場合
                  WHEN ( ilm.attribute6 IS NULL ) THEN TO_CHAR(TRUNC(xim2v1.frequent_qty))
                END                               AS qty            -- 入数
                ,CASE
                  WHEN  xmldt.mov_line_id IS NULL THEN
                    CASE
                      WHEN  xim2v1.conv_unit IS NOT NULL
-- 2008/10/27 Y.Kawano Mod Start #183
--                      AND   xic4v1.item_class_code  = lc_code_seihin  THEN
                      AND   xic5v1.item_class_code  = lc_code_seihin  THEN
-- 2008/10/27 Y.Kawano Mod End   #183
                        xola.quantity / TO_NUMBER(
                                                CASE WHEN xim2v1.num_of_cases > 0
                                                        THEN xim2v1.num_of_cases
                                                     ELSE TO_CHAR(1)
                                                END)
                      ELSE
                        xola.quantity
                    END
                  ELSE
                    CASE
                      WHEN  xim2v1.conv_unit IS NOT NULL 
-- 2008/10/27 Y.Kawano Mod Start #183
--                      AND   xic4v1.item_class_code  = lc_code_seihin  THEN
                      AND   xic5v1.item_class_code  = lc_code_seihin  THEN
-- 2008/10/27 Y.Kawano Mod End   #183
                        xmldt.actual_quantity / TO_NUMBER(
                                                        CASE WHEN xim2v1.num_of_cases > 0
                                                                THEN xim2v1.num_of_cases
                                                             ELSE TO_CHAR(1)
                                                        END)
                      ELSE
                        xmldt.actual_quantity
                    END
                END                               AS sum_quantity   -- 合計数(明細単位)
                ,CASE
                  WHEN  xim2v1.conv_unit IS NOT NULL 
-- 2008/10/27 Y.Kawano Mod Start #32,#183
--                  AND   xic4v1.item_class_code  = lc_code_seihin  THEN
                  AND   xic5v1.item_class_code  = lc_code_seihin
                  AND   xim2v1.num_of_cases > '0'  THEN
-- 2008/10/27 Y.Kawano Mod End   #32,#183
                    xim2v1.conv_unit
                  ELSE
                    xim2v1.item_um
                END                               AS sum_item_um    -- 合計数_単位(明細単位)
                ,CASE
                  WHEN  xsm2v.small_amount_class    = lc_small_amount_enabled THEN
                    xoha.sum_weight
                  WHEN  xsm2v.small_amount_class    = lc_small_amount_disabled THEN    -- 6/23 追加
                    xoha.sum_weight + xoha.sum_pallet_weight
                  ELSE
                    NULL
                END                               AS sum_weight     -- 合計重量(明細単位)
                ,CASE
                  WHEN  xsm2v.small_amount_class    = lc_small_amount_enabled THEN
                    xoha.sum_capacity
                  WHEN  xsm2v.small_amount_class    = lc_small_amount_disabled THEN    -- 6/23 追加
                    xoha.sum_capacity + xoha.sum_pallet_weight
                  ELSE
                    NULL
                END                               AS sum_capacity   -- 合計容積(明細単位)
                ,CASE
                  WHEN  xsm2v.small_amount_class    = lc_small_amount_enabled THEN
                    xoha.sum_weight
                  WHEN  xsm2v.small_amount_class    = lc_small_amount_disabled THEN    -- 6/23 追加
                    xoha.sum_weight + xoha.sum_pallet_weight
                  ELSE
                    NULL
                END                               AS sum_weight     -- 依頼重量(依頼合計単位)
                ,CASE
                  WHEN  xsm2v.small_amount_class    = lc_small_amount_enabled THEN   
                    xoha.sum_capacity
                  WHEN  xsm2v.small_amount_class    = lc_small_amount_disabled THEN    -- 6/23 追加
                    xoha.sum_capacity + xoha.sum_pallet_weight
                  ELSE
                    NULL
                END                               AS sum_capacity   -- 依頼容積(依頼合計単位)
-- 2008/07/07 A.Shiina v1.3 ADD Start
                ,xoha.freight_charge_class        AS freight_charge_code    -- 運賃区分
                ,xc2v.complusion_output_code      AS complusion_output_kbn  -- 強制出力区分
-- 2008/07/07 A.Shiina v1.3 ADD End
--
      FROM
                 xxwsh_order_headers_all          xoha              -- 受注ヘッダアドオン
                ,xxwsh_order_lines_all            xola              -- 受注明細アドオン
                ,xxwsh_oe_transaction_types2_v    xott2v            -- 受注タイプ情報VIEW
                ,xxcmn_item_locations2_v          xil2v             -- OPM保管場所情報VIEW2
                ,xxcmn_cust_acct_sites2_v         xcas2v            -- 顧客サイト情報VIEW2
                ,xxcmn_cust_accounts2_v           xca2v             -- 顧客情報VIEW2
                ,xxcmn_carriers2_v                xc2v              -- 運送業者情報VIEW2
                ,xxinv_mov_lot_details            xmldt             -- 移動ロット詳細(アドオン)
                ,ic_lots_mst                      ilm               -- OPMロットマスタ
                ,xxcmn_item_mst2_v                xim2v1            -- OPM品目情報VIEW2
-- 2008/10/27 Y.Kawano Mod Start
--                ,xxcmn_item_categories4_v         xic4v1  -- OPM品目カテゴリ割当情報VIEW4
                ,xxcmn_item_categories5_v         xic5v1  -- OPM品目カテゴリ割当情報VIEW5
-- 2008/10/27 Y.Kawano Mod End
                ,xxwsh_ship_method2_v             xsm2v             -- 配送区分情報VIEW2
                ,fnd_user                         fu                -- ユーザーマスタ
                ,per_all_people_f                 papf              -- 従業員テーブル
--
      -------------------------------------------------------------------------------
      -- 受注ヘッダアドオン
      -------------------------------------------------------------------------------
      WHERE
      -------------------------------------------------------------------------------
      -- 出庫形態
                xoha.order_type_id                =   xott2v.transaction_type_id
      AND       xott2v.shipping_shikyu_class      =   lc_shikyu_cls_shukka_irai -- 出荷依頼
      AND       xott2v.order_category_code        <>  lc_category_return        -- 返品(受注のみ)
      -------------------------------------------------------------------------------
      AND       xoha.req_status                   >=  lc_status_shimezumi       -- 締め済み以上
      AND       xoha.req_status                   <>  lc_status_torikeshi       -- 取消を含まない
-- 2008/10/27 Y.Kawano Add Start #62
      AND       xoha.schedule_ship_date           IS NOT NULL            -- 指示なし実績対象外
-- 2008/10/27 Y.Kawano Add End   #62
      -------------------------------------------------------------------------------
      -- 出庫元情報
      -------------------------------------------------------------------------------
      AND (
            (xil2v.distribution_block = in_block_1)
          OR
            (xil2v.distribution_block = in_block_2)
          OR
            (xil2v.distribution_block = in_block_3)
          OR
            (xoha.deliver_from        = in_delivery_origin)
          OR
            (
              (in_block_1 IS NULL) AND (in_block_2 IS NULL) 
              AND (in_block_3 IS NULL) AND (in_delivery_origin IS NULL)
            )
      )
      AND       (in_delivery_day IS NULL
        OR        xoha.schedule_ship_date         =   in_delivery_day)      -- 出庫日は必須
      AND       (in_delivery_no IS NULL
        OR        xoha.delivery_no                =   in_delivery_no)
      AND       (in_delivery_form IS NULL
        OR        xott2v.transaction_type_id       =  in_delivery_form)
      AND       (in_jurisdiction_base IS NULL
        OR        xoha.head_sales_branch          =   in_jurisdiction_base)
      AND       (in_addre_delivery_dest IS NULL
        OR        xoha.deliver_to                 =   in_addre_delivery_dest)
      AND       (in_request_movement_no IS NULL
        OR        xoha.request_no                 =   in_request_movement_no)
      -------------------------------------------------------------------------------
      -- 運送業者(名称)
      AND       xoha.career_id                    =   xc2v.party_id(+)
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- 配送先／入庫先(名称)
      AND       xoha.deliver_to_id                =   xcas2v.party_site_id
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- 管轄拠点(名称)
      AND       xoha.head_sales_branch            =   xca2v.party_number
      -------------------------------------------------------------------------------
      AND       xoha.latest_external_flag         =   'Y'
      AND       fu.user_id                        =   FND_GLOBAL.USER_ID
      AND       papf.person_id                    =   fu.employee_id
      AND       (
      -------------------------------------------------------------------------------
      -- 内部倉庫の場合
      -------------------------------------------------------------------------------
                  (
                    papf.attribute3               =   lc_employee_division_inside
                  OR
                    papf.attribute3            IS  NULL
                  )
      -------------------------------------------------------------------------------
      -- 外部倉庫の場合
      -------------------------------------------------------------------------------
                OR
                  (
                    (
                      -- attribute3(従業員区分) １：内部、２：外部
                      papf.attribute3             =   lc_employee_division_outside
                    )
                  AND
                    (
                      -- 確定通知済
                      xoha.notif_status           =   lc_fixa_notif_end
                    )
                  )
                )
      -------------------------------------------------------------------------------
      -- 受注明細アドオン
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- 品目(コード)
      AND       xoha.order_header_id              =   xola.order_header_id
      AND       xola.delete_flag                  <>  lc_delete_flag
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- OPM品目マスタ
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- 品目(名称)
      AND       xola.shipping_inventory_item_id   =   xim2v1.inventory_item_id
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- 入数
      -- 合計数(明細単位)
      -- 合計数_単位(明細単位)
-- 2008/10/27 Y.Kawano Mod Start #183
--      AND       xim2v1.item_id                    =   xic4v1.item_id
      AND       xim2v1.item_id                    =   xic5v1.item_id
-- 2008/10/27 Y.Kawano Mod End   #183
      AND       (in_commodity_div IS NULL
-- 2008/10/27 Y.Kawano Mod Start #183
--        OR        xic4v1.prod_class_code          =   in_commodity_div)
        OR        xic5v1.prod_class_code          =   in_commodity_div)
-- 2008/10/27 Y.Kawano Mod End   #183
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- OPM保管場所マスタ
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- 出庫元(名称)
      AND       xoha.deliver_from_id              =   xil2v.inventory_location_id
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- 移動ロット詳細(アドオン)
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- ロットNo
      AND       xola.order_line_id                =   xmldt.mov_line_id(+)
      AND       xmldt.document_type_code(+)       =   lc_doc_type_shukka_irai -- 出荷依頼
      AND       xmldt.record_type_code(+)         =   lc_record_type_shizi    -- 指示
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- 製造日
      -- 賞味期限
      -- 固有記号
      AND       xmldt.lot_id                      =   ilm.lot_id(+)
      AND       xmldt.item_id                     =   ilm.item_id(+)
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- アドオンマスタ適用日
      -------------------------------------------------------------------------------
      AND       xcas2v.start_date_active          <=  xoha.schedule_ship_date
      AND       ((xcas2v.end_date_active IS NULL)
        OR        (xcas2v.end_date_active         >=  xoha.schedule_ship_date))
--
      AND       xca2v.start_date_active           <=  xoha.schedule_ship_date
      AND       ((xca2v.end_date_active IS NULL)
        OR        (xca2v.end_date_active          >=  xoha.schedule_ship_date))
--
      AND       ((xc2v.start_date_active IS NULL)
        OR        (xc2v.start_date_active         <=  xoha.schedule_ship_date))
      AND       ((xc2v.end_date_active IS NULL)
        OR        (xc2v.end_date_active           >=  xoha.schedule_ship_date))
--
      AND       xim2v1.start_date_active          <=  xoha.schedule_ship_date
      AND       ((xim2v1.end_date_active IS NULL)
        OR        (xim2v1.end_date_active         >=  xoha.schedule_ship_date))
      -------------------------------------------------------------------------------
      -- 配送区分情報VIEW2
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- 配送区分(名称)
      AND       xoha.shipping_method_code         =   xsm2v.ship_method_code(+)  -- 6/23 外部結合追加
      -------------------------------------------------------------------------------
--
      ORDER BY
                 deliver_from         ASC
                ,schedule_ship_date   ASC
                ,delivery_no          ASC
                ,request_no           ASC
                ,shipping_item_code   ASC
                ,lot_no               ASC ;
--
    ------------------------------------------------------------------------
    -- 移動の場合
    ------------------------------------------------------------------------
    CURSOR cur_main_data2
      (
         in_block_1               VARCHAR2
        ,in_block_2               VARCHAR2
        ,in_block_3               VARCHAR2
        ,in_delivery_origin       VARCHAR2
        ,in_delivery_day          VARCHAR2
        ,in_delivery_no           VARCHAR2
        ,in_addre_delivery_dest   VARCHAR2
        ,in_request_movement_no   VARCHAR2
        ,in_commodity_div         VARCHAR2
      )
    IS
      SELECT
                 '移動'                           AS gyoumu_shubetsu        -- 業務種別
                ,xmrih.delivery_no                AS delivery_no            -- 配送No
                ,xmrih.shipped_locat_code         AS shipped_locat_code     -- 出庫元(コード)
                ,xil2v1.description               AS description1           -- 出庫元(名称)
                ,xmrih.freight_carrier_code       AS freight_carrier_code   -- 運送業者(コード)
                ,xc2v.party_short_name            AS party_short_name       -- 運送業者(名称)
                ,xmrih.mov_num                    AS mov_num                -- 依頼No／移動No
                ,''                               AS shukkokeitai           -- 出庫形態
                ,xmrih.ship_to_locat_code         AS ship_to_locat_code     -- 配送先／入庫先(ｺｰﾄﾞ)
                ,xil2v2.description               AS description2           -- 配送先／入庫先(名称)
                ,xmrih.shipping_method_code       AS shipping_method_code   -- 配送区分(コード)
                ,xsm2v.ship_method_meaning        AS ship_method_meaning    -- 配送区分(名称)
                ,''                               AS kankatsu_kyoten_code   -- 管轄拠点(コード)
                ,''                               AS kankatsu_kyoten_name   -- 管轄拠点(名称)
                ,xmrih.schedule_ship_date         AS schedule_ship_date     -- 出庫日
                ,xmrih.schedule_arrival_date      AS schedule_arrival_date  -- 着日
                ,xmrih.arrival_time_from          AS arrival_time_from      -- 時間指定From
                ,xmrih.arrival_time_to            AS arrival_time_to        -- 時間指定To
                ,xmrih.description                AS desc_name              -- 摘要
                ,xmrih.batch_no                   AS batch_no               -- 手配No
                ,xmril.item_code                  AS item_code              -- 品目(コード)
                ,xim2v1.item_short_name           AS item_short_name        -- 品目(名称)
                ,xmldt.lot_no                     AS lot_no                 -- ロットNo
                ,ilm.attribute1                   AS attribute1             -- 製造日
                ,ilm.attribute3                   AS attribute3             -- 賞味期限
                ,ilm.attribute2                   AS attribute2             -- 固有記号
                ,CASE
                  -- 製品の場合
-- 2008/10/27 Y.Kawano Mod Start #183
--                  WHEN ((xic4v1.item_class_code = lc_code_seihin) 
                  WHEN ((xic5v1.item_class_code = lc_code_seihin) 
-- 2008/10/27 Y.Kawano Mod End   #183
                        AND 
                        (ilm.attribute6 IS NOT NULL)) THEN xim2v1.num_of_cases
                  -- その他の品目の場合
-- 2008/10/27 Y.Kawano Mod Start #183
--                  WHEN (((xic4v1.item_class_code = lc_code_genryou) 
--                          OR  
--                         (xic4v1.item_class_code = lc_code_hanseihin))
                  WHEN (((xic5v1.item_class_code = lc_code_genryou) 
                          OR  
                         (xic5v1.item_class_code = lc_code_hanseihin))
-- 2008/10/27 Y.Kawano Mod End   #183
                        AND (ilm.attribute6 IS NOT NULL)) THEN TO_CHAR(TRUNC(ilm.attribute6))
                  -- 在庫入数が設定されていない,資材他,ロット管理していない場合
                  WHEN ( ilm.attribute6 IS NULL ) THEN TO_CHAR(TRUNC(xim2v1.frequent_qty))
                END                               AS qty            -- 入数
                ,CASE
                  WHEN  xmldt.mov_line_id IS NULL THEN
                    CASE
                      WHEN  xim2v1.conv_unit IS NOT NULL 
-- 2008/10/27 Y.Kawano Mod Start #183
--                      AND   xic4v1.item_class_code  = lc_code_seihin THEN
                      AND   xic5v1.item_class_code  = lc_code_seihin THEN
-- 2008/10/27 Y.Kawano Mod End   #183
                        xmril.instruct_qty / TO_NUMBER(
                                                      CASE WHEN xim2v1.num_of_cases > 0
                                                              THEN  xim2v1.num_of_cases
                                                           ELSE TO_CHAR(1)
                                                      END)
                      ELSE
                        xmril.instruct_qty
                    END
                  ELSE
                    CASE
                      WHEN  xim2v1.conv_unit IS NOT NULL 
-- 2008/10/27 Y.Kawano Mod Start #183
--                      AND   xic4v1.item_class_code  = lc_code_seihin THEN
                      AND   xic5v1.item_class_code  = lc_code_seihin THEN
-- 2008/10/27 Y.Kawano Mod End   #183
                        xmldt.actual_quantity / TO_NUMBER(
                                                        CASE  WHEN  xim2v1.num_of_cases > 0
                                                                THEN  xim2v1.num_of_cases
                                                              ELSE  TO_CHAR(1)
                                                        END)
                      ELSE
                        xmldt.actual_quantity
                    END
                END                               AS sum_quantity   -- 合計数(明細単位)
                ,CASE
                  WHEN  xim2v1.conv_unit IS NOT NULL 
-- 2008/10/27 Y.Kawano Mod Start #32,#183
--                  AND   xic4v1.item_class_code  = lc_code_seihin THEN
                  AND   xic5v1.item_class_code  = lc_code_seihin
                  AND   xim2v1.num_of_cases > '0'  THEN
-- 2008/10/27 Y.Kawano Mod End   #32,#183
                    xim2v1.conv_unit
                  ELSE
                    xim2v1.item_um
                END                               AS sum_item_um    -- 合計数_単位(明細単位)
                ,CASE
                  WHEN  xsm2v.small_amount_class    = lc_small_amount_enabled THEN
                    xmrih.sum_weight
                  WHEN  xsm2v.small_amount_class    = lc_small_amount_disabled THEN    -- 6/23 追加
                    xmrih.sum_weight + xmrih.sum_pallet_weight
                  ELSE
                    NULL
                END                               AS sum_weight     -- 合計重量(明細単位)
                ,CASE
                  WHEN  xsm2v.small_amount_class    = lc_small_amount_enabled THEN
                    xmrih.sum_capacity
                  WHEN  xsm2v.small_amount_class    = lc_small_amount_disabled THEN    -- 6/23 追加
                    xmrih.sum_capacity + xmrih.sum_pallet_weight
                  ELSE
                    NULL
                END                               AS sum_capacity   -- 合計容積(明細単位)
                ,CASE
                  WHEN  xsm2v.small_amount_class    = lc_small_amount_enabled THEN
                    xmrih.sum_weight
                  WHEN  xsm2v.small_amount_class    = lc_small_amount_disabled THEN    -- 6/23 追加
                    xmrih.sum_weight + xmrih.sum_pallet_weight
                  ELSE
                    NULL
                END                               AS sum_weight     -- 依頼重量(依頼合計単位)
                ,CASE
                  WHEN  xsm2v.small_amount_class    = lc_small_amount_enabled THEN
                    xmrih.sum_capacity
                  WHEN  xsm2v.small_amount_class    = lc_small_amount_disabled THEN    -- 6/23 追加
                    xmrih.sum_capacity + xmrih.sum_pallet_weight
                  ELSE
                    NULL
                END                               AS sum_capacity   -- 依頼容積(依頼合計単位)
-- 2008/07/07 A.Shiina v1.3 ADD Start
                ,xmrih.freight_charge_class       AS freight_charge_code    -- 運賃区分
                ,xc2v.complusion_output_code      AS complusion_output_kbn  -- 強制出力区分
-- 2008/07/07 A.Shiina v1.3 ADD End
--
      FROM
                 xxinv_mov_req_instr_headers      xmrih   -- 移動依頼/指示ヘッダ(アドオン)
                ,xxinv_mov_req_instr_lines        xmril   -- 移動依頼/指示明細(アドオン)
                ,xxcmn_item_locations2_v          xil2v1  -- OPM保管場所情報VIEW2(FROM)
                ,xxcmn_item_locations2_v          xil2v2  -- OPM保管場所情報VIEW2(TO)
                ,xxcmn_carriers2_v                xc2v    -- 運送業者情報VIEW2
                ,xxinv_mov_lot_details            xmldt   -- 移動ロット詳細(アドオン)
                ,ic_lots_mst                      ilm     -- OPMロットマスタ
                ,xxcmn_item_mst2_v                xim2v1  -- OPM品目情報VIEW2
-- 2008/10/27 Y.Kawano Mod Start
--                ,xxcmn_item_categories4_v         xic4v1  -- OPM品目カテゴリ割当情報VIEW4
                ,xxcmn_item_categories5_v         xic5v1  -- OPM品目カテゴリ割当情報VIEW5
-- 2008/10/27 Y.Kawano Mod End
                ,xxwsh_ship_method2_v             xsm2v   -- 配送区分情報VIEW2
                ,fnd_user                         fu      -- ユーザーマスタ
                ,xxpo_per_all_people_f2_v         papf    -- 従業員情報VIEW2
--
      -------------------------------------------------------------------------------
      -- 移動依頼/指示ヘッダ(アドオン)
      -------------------------------------------------------------------------------
      WHERE
                xmrih.mov_type                    <> lc_mov_type_sekisou_nashi  -- 積送無し
      AND       xmrih.status                      >= lc_status_irai_zumi        -- 依頼済以上
      AND       xmrih.status                      <> lc_status_torikeshi        -- 取消を含まない
-- 2008/10/27 Y.Kawano Add Start #62
      AND     ((xmrih.no_instr_actual_class       IS NULL)
       OR      (xmrih.no_instr_actual_class       <>  gc_class_y)) -- 指示なし実績は対象外
-- 2008/10/27 Y.Kawano Add End   #62
      -------------------------------------------------------------------------------
      -- 出庫元情報(From)
      -------------------------------------------------------------------------------
      AND (
            (xil2v1.distribution_block  = in_block_1)
          OR
            (xil2v1.distribution_block  = in_block_2)
          OR
            (xil2v1.distribution_block  = in_block_3)
          OR
            (xmrih.shipped_locat_code   = in_delivery_origin)
          OR
            (
              (in_block_1 IS NULL) AND (in_block_2 IS NULL) 
              AND (in_block_3 IS NULL) AND (in_delivery_origin IS NULL)
            )
      )
      AND       (xmrih.schedule_ship_date IS NULL
        OR        xmrih.schedule_ship_date        =   in_delivery_day)      -- 出庫日は必須
      AND       (in_delivery_no IS NULL
        OR        xmrih.delivery_no               =   in_delivery_no)
      AND       (in_addre_delivery_dest IS NULL
        OR        xmrih.ship_to_locat_code         =   in_addre_delivery_dest)
      AND       (in_request_movement_no IS NULL
        OR        xmrih.mov_num                   =   in_request_movement_no)
      -------------------------------------------------------------------------------
      -- 運送業者(名称)
      AND       xmrih.career_id                   =   xc2v.party_id(+)
      -------------------------------------------------------------------------------
      AND       fu.user_id                        =   FND_GLOBAL.USER_ID
      AND       papf.person_id                    =   fu.employee_id
      AND       (
      -------------------------------------------------------------------------------
      -- 内部倉庫の場合
      -------------------------------------------------------------------------------
                  (
                    papf.attribute3               =   lc_employee_division_inside
                  OR
                    papf.attribute3            IS  NULL
                  )
      -------------------------------------------------------------------------------
      -- 外部倉庫の場合
      -------------------------------------------------------------------------------
                OR
                  (
                    (
                      -- attribute3(従業員区分) １：内部、２：外部
                      papf.attribute3             =   lc_employee_division_outside
                    )
                  AND
                    (
                      -- 確定通知済
                      xmrih.notif_status          =   lc_fixa_notif_end
                    )
                  )
                )
      -------------------------------------------------------------------------------
      -- 移動依頼/指示ヘッダ(アドオン)
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- 品目(コード)
      AND       xmrih.mov_hdr_id                  =   xmril.mov_hdr_id
      AND       xmril.delete_flg                  <>  lc_delete_flag
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- OPM品目マスタ
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- 品目(名称)
      -- 入数
      -- 合計数_単位(明細単位)
      AND       xmril.item_id                     =   xim2v1.item_id
-- 2008/10/27 Y.Kawano Mod Start #183
--      AND       xim2v1.item_id                    =   xic4v1.item_id
      AND       xim2v1.item_id                    =   xic5v1.item_id
-- 2008/10/27 Y.Kawano Mod End   #183
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- 商品区分
      AND       (in_commodity_div IS NULL
-- 2008/10/27 Y.Kawano Mod Start #183
--        OR        xic4v1.prod_class_code          =   in_commodity_div)
        OR        xic5v1.prod_class_code          =   in_commodity_div)
-- 2008/10/27 Y.Kawano Mod End   #183
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- OPM保管場所マスタ(From)
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- 出庫元(名称)
      AND       xmrih.shipped_locat_id            =   xil2v1.inventory_location_id
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- OPM保管場所マスタ(To)
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- 配送先／入庫先(名称)
      AND       xmrih.ship_to_locat_id            =   xil2v2.inventory_location_id
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- OPMロットマスタ
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- ロットNo
      -- 合計数(明細単位)
      AND       xmril.mov_line_id                 =   xmldt.mov_line_id(+)
      AND       xmldt.document_type_code(+)       =   lc_doc_type_idou      -- 移動
      AND       xmldt.record_type_code(+)         =   lc_record_type_shizi  -- 指示
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- 製造日
      -- 賞味期限
      -- 固有記号
      AND       xmldt.lot_id                      =   ilm.lot_id(+)
      AND       xmldt.item_id                     =   ilm.item_id(+)
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- アドオンマスタ適用日
      -------------------------------------------------------------------------------
      AND       ((xc2v.start_date_active IS NULL)
        OR        (xc2v.start_date_active         <=  xmrih.schedule_ship_date))
      AND       ((xc2v.end_date_active IS NULL)
        OR        (xc2v.end_date_active           >=  xmrih.schedule_ship_date))
--
      AND       xim2v1.start_date_active          <=  xmrih.schedule_ship_date
      AND       ((xim2v1.end_date_active IS NULL)
        OR        (xim2v1.end_date_active         >=  xmrih.schedule_ship_date))
      -------------------------------------------------------------------------------
      -- 配送区分情報VIEW2
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- 配送区分(名称)
      AND       xmrih.shipping_method_code        =   xsm2v.ship_method_code(+)  -- 6/23 外部結合追加
      -------------------------------------------------------------------------------
--
      ORDER BY
                 shipped_locat_code   ASC
                ,schedule_ship_date   ASC
                ,delivery_no          ASC
                ,mov_num              ASC
                ,item_code            ASC
                ,lot_no               ASC ;
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
    IF ( ir_param.iv_business_type = gc_code_shukka ) THEN
      -- カーソルオープン
      OPEN cur_main_data1
        (
           ir_param.iv_block_1
          ,ir_param.iv_block_2
          ,ir_param.iv_block_3
          ,ir_param.iv_delivery_origin
          ,ir_param.iv_delivery_day
          ,ir_param.iv_delivery_no
          ,ir_param.iv_delivery_form
          ,ir_param.iv_jurisdiction_base
          ,ir_param.iv_addre_delivery_dest
          ,ir_param.iv_request_movement_no
          ,ir_param.iv_commodity_div
        ) ;
      -- バルクフェッチ
      FETCH cur_main_data1 BULK COLLECT INTO ot_data_rec ;
      -- カーソルクローズ
      CLOSE cur_main_data1 ;
      -- 帳票出力名をセット
      gv_out_char_title :=  gc_out_char_title_shukko;
    ELSE
      -- カーソルオープン
      OPEN cur_main_data2
        (
           ir_param.iv_block_1
          ,ir_param.iv_block_2
          ,ir_param.iv_block_3
          ,ir_param.iv_delivery_origin
          ,ir_param.iv_delivery_day
          ,ir_param.iv_delivery_no
          ,ir_param.iv_addre_delivery_dest
          ,ir_param.iv_request_movement_no
          ,ir_param.iv_commodity_div
        ) ;
      -- バルクフェッチ
      FETCH cur_main_data2 BULK COLLECT INTO ot_data_rec ;
      -- カーソルクローズ
      CLOSE cur_main_data2 ;
      -- 帳票出力名をセット
      gv_out_char_title :=  gc_out_char_title_idou;
    END IF ;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF ( cur_main_data1%ISOPEN ) THEN
        CLOSE cur_main_data1 ;
      END IF ;
      IF ( cur_main_data2%ISOPEN ) THEN
        CLOSE cur_main_data2 ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( cur_main_data1%ISOPEN ) THEN
        CLOSE cur_main_data1 ;
      END IF ;
      IF ( cur_main_data2%ISOPEN ) THEN
        CLOSE cur_main_data2 ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( cur_main_data1%ISOPEN ) THEN
        CLOSE cur_main_data1 ;
      END IF ;
      IF ( cur_main_data2%ISOPEN ) THEN
        CLOSE cur_main_data2 ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_get_report_data ;
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : ＸＭＬデータ作成(H-4)
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data(
      ir_param          IN      rec_param_data  -- 01.レコード  ：パラメータ
     ,iox_xml_data      IN OUT  NOCOPY XML_DATA 
     ,ov_errbuf         OUT     VARCHAR2        -- エラー・メッセージ           --# 固定 #
     ,ov_retcode        OUT     VARCHAR2        -- リターン・コード             --# 固定 #
     ,ov_errmsg         OUT     VARCHAR2        -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- *** ローカル定数 ***
    -- 金額計算用
    lv_juuryou_amount       NUMBER      := 0 ;                        -- 【依頼重量】
    lv_youseki_amount       NUMBER      := 0 ;                        -- 【依頼容積】
--
    -- ブレイクキー
    lv_request_no           xxwsh_order_headers_all.request_no%TYPE ; -- 依頼No／移動No
    lv_header_disp_flg      BOOLEAN ;
    lv_detail_end_disp_flg  BOOLEAN ;
    lv_party_site_name1     VARCHAR2(31);
    lv_party_site_name2     VARCHAR2(30);
--
    -- *** ローカル・例外処理 ***
    no_data_expt            EXCEPTION ;                               -- 取得レコードなし
--
  BEGIN
--
    -- =====================================================
    -- 変数初期設定
    -- =====================================================
    gt_xml_data_table.DELETE ;
--
    -- =====================================================
    -- 明細データ取得(H-3)
    -- =====================================================
    prc_get_report_data
      (
        ir_param      => ir_param       -- 01.入力パラメータ群
       ,ot_data_rec   => gt_main_data   -- 02.取得レコード群
       ,ov_errbuf     => lv_errbuf      -- エラー・メッセージ           --# 固定 #
       ,ov_retcode    => lv_retcode     -- リターン・コード             --# 固定 #
       ,ov_errmsg     => lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_api_expt ;
--
    -- 取得データが０件の場合
    ELSIF ( gt_main_data.COUNT = 0 ) THEN
      RAISE no_data_expt ;
--
    END IF ;
--
    -- =====================================================
    -- 項目データ抽出・出力処理
    -- =====================================================
--
    -- ブレイクキーの初期化
    IF ( gt_main_data.COUNT > 0 ) THEN
      lv_request_no         :=  gt_main_data(1).request_no ;
    ELSE
      lv_request_no         :=  NULL ;
    END IF ;
    lv_header_disp_flg      :=  TRUE ;
    lv_detail_end_disp_flg  :=  TRUE ;
--
    -- -----------------------------------------------------
    -- データＧ開始タグ出力
    -- -----------------------------------------------------
    prcsub_set_xml_data('root') ;
    prcsub_set_xml_data('data_info') ;
--
    -- -----------------------------------------------------
    -- 伝票Ｇ開始タグ出力
    -- -----------------------------------------------------
    prcsub_set_xml_data('lg_denpyo_info') ;
--
    -- =====================================================
    -- 項目データ抽出・出力処理
    -- =====================================================
    <<main_data_loop>>
    FOR i IN 1..gt_main_data.COUNT LOOP
--
      -- ヘッダー出力フラグ
      IF ( lv_header_disp_flg = TRUE ) THEN
--
        -- -----------------------------------------------------
        -- ヘッダーＧ開始タグ出力
        -- -----------------------------------------------------
        prcsub_set_xml_data('g_denpyo') ;
--
        -- 帳票タイトル
        prcsub_set_xml_data('title', gv_out_char_title || gc_msg_shizisyo) ;
        -- 帳票ID
        prcsub_set_xml_data('tyohyo_id', gc_report_id) ;
        -- 出力日付
        prcsub_set_xml_data('shuturyoku_hiduke', TO_CHAR(gd_exec_date, gc_char_dt_format)) ;
        -- 担当（部署）
        prcsub_set_xml_data('tantou_busho', gv_department_code) ;
        -- 担当（氏名）
        prcsub_set_xml_data('tantou_name', gv_department_name) ;
--
        -- 配送先/入庫先（名称）二行出力判定
        IF ( LENGTH(SUBSTRB(gt_main_data(i).party_site_name, 29, 2)) = 1 ) THEN
          lv_party_site_name1 := substrb(gt_main_data(i).party_site_name, 1, 30) ;
          lv_party_site_name2 := substrb(gt_main_data(i).party_site_name, 31) ;
        ELSE
          IF (length(substrb(gt_main_data(i).party_site_name, 30, 2)) = 1 ) then
            lv_party_site_name1 := substrb(gt_main_data(i).party_site_name, 1, 31) ;
            lv_party_site_name2 := substrb(gt_main_data(i).party_site_name, 32) ;
          ELSE
            lv_party_site_name1 := substrb(gt_main_data(i).party_site_name, 1, 30) ;
            lv_party_site_name2 := substrb(gt_main_data(i).party_site_name, 31) ;
          END IF;
        END IF;
        --
        -- 業務種別 
        prcsub_set_xml_data('gyoumu_shubetsu', gt_main_data(i).gyoumu_shubetsu) ;
        -- 配送No.
        prcsub_set_xml_data('haisou_no', gt_main_data(i).delivery_no) ;
        -- 出庫元（コード） 
        prcsub_set_xml_data('shukko_saki_code', gt_main_data(i).deliver_from) ;
        -- 出庫元（名称） 
        prcsub_set_xml_data('shukko_saki_name', gt_main_data(i).description) ;
-- 2008/07/03 A.Shiina v1.3 Update Start
       IF  ((gt_main_data(i).freight_charge_code  = '1')
        OR (gt_main_data(i).complusion_output_kbn = '1')) THEN
        -- 運送業者（コード） 
        prcsub_set_xml_data('unsou_gyousha_code', gt_main_data(i).freight_carrier_code) ;
        -- 運送業者（名称） 
        prcsub_set_xml_data('unsou_gyousha_name', gt_main_data(i).party_short_name1) ;
       END IF;
-- 2008/07/03 A.Shiina v1.3 Update End
        -- 依頼No/移動No
        prcsub_set_xml_data('irai_idou_no', gt_main_data(i).request_no) ;
        -- 出庫形態 
        prcsub_set_xml_data('shukko_keitai'
                          , gt_main_data(i).transaction_type_name
                          , gc_tag_type_data) ;
        -- 配送先/入庫先（コード） 
        prcsub_set_xml_data('haisou_shukko_saki_code', gt_main_data(i).deliver_to) ;
        -- 配送先/入庫先（名称１） 
        prcsub_set_xml_data('haisou_shukko_saki_name1', lv_party_site_name1) ;
        -- 配送先/入庫先（名称２）
        prcsub_set_xml_data('haisou_shukko_saki_name2', lv_party_site_name2) ;
        -- 配送区分（コード） 
        prcsub_set_xml_data('haisou_kubun_code', gt_main_data(i).shipping_method_code) ;
        -- 配送区分（名称） 
        prcsub_set_xml_data('haisou_kubun_name', gt_main_data(i).ship_method_meaning) ;
        -- 管轄拠点（コード） 
        prcsub_set_xml_data('kankatsu_kyoten_code'
                           , gt_main_data(i).head_sales_branch
                           , gc_tag_type_data) ;
        -- 管轄拠点（名称） 
        prcsub_set_xml_data('kankatsu_kyoten_name', gt_main_data(i).party_name, gc_tag_type_data) ;
        -- 出庫日 
        prcsub_set_xml_data('shukkobi', TO_CHAR(gt_main_data(i).schedule_ship_date
                                              , gc_char_d_format)) ;
        -- 着日 
        prcsub_set_xml_data('tyakubi', TO_CHAR(gt_main_data(i).schedule_arrival_date
                                             , gc_char_d_format)) ;
        -- 時間指定（From） 
        prcsub_set_xml_data('jikan_shitei_from', TO_CHAR(TO_DATE(gt_main_data(i).arrival_time_from
                                                               , lc_date_jikanshitei_format)
                                                       , lc_date_jikanshitei_format)) ;
        -- 時間指定（To） 
        prcsub_set_xml_data('jikan_shitei_to', TO_CHAR(TO_DATE(gt_main_data(i).arrival_time_to
                                                             , lc_date_jikanshitei_format)
                                                     , lc_date_jikanshitei_format)) ;
--
        -- 手配No（ラベル、値）※移動時のみ帳票に出力される。
        IF ( ir_param.iv_business_type <> gc_code_shukka ) THEN
          -- 手配No（ラベル）※移動時のみ『手配No』が入る 
          prcsub_set_xml_data('tehai_no_label', gc_tehai_label, gc_tag_type_data) ;
          -- 手配No（値）※移動時のみ値が入る 
          prcsub_set_xml_data('tehai_no_value', gt_main_data(i).batch_no, gc_tag_type_data) ;
        END IF ;
--
        -- 摘要 
        prcsub_set_xml_data('tekiyou', gt_main_data(i).shipping_instructions) ;
--
        -- -----------------------------------------------------
        -- 明細ＬＧ開始タグ出力
        -- -----------------------------------------------------
        prcsub_set_xml_data('lg_denpyo_detail') ;
--
      END IF ;
--
      -- -----------------------------------------------------
      -- 明細Ｇ開始タグ出力
      -- -----------------------------------------------------
      prcsub_set_xml_data('g_denpyo_detail') ;
--
      prcsub_set_xml_data('hinmoku_code', gt_main_data(i).shipping_item_code) ; -- 品目（コード）
      prcsub_set_xml_data('hinmoku_name', gt_main_data(i).item_short_name) ;    -- 品目（名称）
      prcsub_set_xml_data('rotto_no', gt_main_data(i).lot_no) ;                 -- ロットNo
      prcsub_set_xml_data('seizoubi', TO_CHAR(TO_DATE(gt_main_data(i).attribute1
                                                    , gc_char_d_format)
                                            , gc_char_d_format)) ;              -- 製造日
      prcsub_set_xml_data('shoumikigen', TO_CHAR(TO_DATE(gt_main_data(i).attribute3
                                                       , gc_char_d_format)
                                               , gc_char_d_format)) ;           -- 賞味期限
      prcsub_set_xml_data('koyuukigou', gt_main_data(i).attribute2) ;           -- 固有記号
      prcsub_set_xml_data('iri_suu', gt_main_data(i).qty) ;                     -- 入数
      prcsub_set_xml_data('goukei_suu', gt_main_data(i).sum_quantity) ;         -- 合計数
      prcsub_set_xml_data('goukei_suu_unit', gt_main_data(i).sum_item_um) ;     -- 合計数（単位）
--
      -- -----------------------------------------------------
      -- 明細Ｇ終了タグ出力
      -- -----------------------------------------------------
      prcsub_set_xml_data('/g_denpyo_detail') ;
--
      -- ブレイクキーのチェックと、最終明細行のチェック
      IF ( i < gt_main_data.COUNT ) THEN
--
        IF ( lv_request_no <> gt_main_data(i + 1).request_no ) THEN
          -- ブレイクキーの更新
          lv_request_no           := gt_main_data(i + 1).request_no ;
          -- ヘッダーを出力する。
          lv_header_disp_flg      := TRUE ;
          -- 明細最終行を出力する。
          lv_detail_end_disp_flg  := TRUE ;
        ELSE
          -- ヘッダーを出力しない。
          lv_header_disp_flg      := FALSE ;
          -- 明細最終行を出力しない。
          lv_detail_end_disp_flg  := FALSE ;
        END IF ;
--
      ELSE
          -- ヘッダーを出力する。
          lv_header_disp_flg      := TRUE ;
          -- 明細最終行を出力する。
          lv_detail_end_disp_flg  := TRUE ;
      END IF ;
--
      -- 明細最終行出力フラグ
      IF ( lv_detail_end_disp_flg = TRUE ) THEN
--
-- 2008/07/03 MOD START NAKADA ST不具合対応No412 重量容積の小数第一位切り上げ
        -- 【依頼重量】
        prcsub_set_xml_data('irai_juuryou', CEIL(TRUNC(gt_main_data(i).sum_weight_irai,1))) ;
-- 2008/07/03 MOD END   NAKADA
--
        -- 【依頼重量】（単位）
        prcsub_set_xml_data('irai_juuryou_unit', gv_uom_weight) ;
--
-- 2008/07/03 MOD START NAKADA ST不具合対応No412 重量容積の小数第一位切り上げ
        -- 【依頼容積】
        prcsub_set_xml_data('irai_youseki', CEIL(TRUNC(gt_main_data(i).sum_capacity_irai,1))) ;
-- 2008/07/03 MOD END   NAKADA
--
        -- 【依頼容積】（単位）
        prcsub_set_xml_data('irai_youseki_unit', gv_uom_capacity) ;
--
        -- -----------------------------------------------------
        -- 明細ＬＧ終了タグ出力
        -- -----------------------------------------------------
        prcsub_set_xml_data('/lg_denpyo_detail') ;
        -- -----------------------------------------------------
        -- ヘッダーＧ終了タグ出力
        -- -----------------------------------------------------
        prcsub_set_xml_data('/g_denpyo') ;
--
      END IF ;
--
    END LOOP main_data_loop ;
--
    -- =====================================================
    -- 終了処理
    -- =====================================================
    -- -----------------------------------------------------
    -- 伝票Ｇ終了タグ出力
    -- -----------------------------------------------------
    prcsub_set_xml_data('/lg_denpyo_info') ;
--
    -- -----------------------------------------------------
    -- データＧ終了タグ出力
    -- -----------------------------------------------------
    prcsub_set_xml_data('/data_info') ;
    prcsub_set_xml_data('/root') ;
--
  EXCEPTION
    -- *** 取得データ０件 ***
    WHEN no_data_expt THEN
      ov_retcode := gv_status_warn ;
      ov_errmsg  := xxcmn_common_pkg.get_msg( gc_application_cmn
                                             ,gc_xxcmn_10122 ) ;
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
  END prc_create_xml_data ;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
       iv_business_type       IN    VARCHAR2      -- 01 : 業務種別
      ,iv_block_1             IN    VARCHAR2      -- 02 : ブロック１
      ,iv_block_2             IN    VARCHAR2      -- 03 : ブロック２
      ,iv_block_3             IN    VARCHAR2      -- 04 : ブロック３
      ,iv_delivery_origin     IN    VARCHAR2      -- 05 : 出庫元
      ,iv_delivery_day        IN    VARCHAR2      -- 06 : 出庫日
      ,iv_delivery_no         IN    VARCHAR2      -- 07 : 配送№
      ,iv_delivery_form       IN    VARCHAR2      -- 08 : 出庫形態
      ,iv_jurisdiction_base   IN    VARCHAR2      -- 09 : 管轄拠点
      ,iv_addre_delivery_dest IN    VARCHAR2      -- 10 : 配送先/入庫先
      ,iv_request_movement_no IN    VARCHAR2      -- 11 : 依頼№/移動№
      ,iv_commodity_div       IN    VARCHAR2      -- 12 : 商品区分
      ,ov_errbuf              OUT   VARCHAR2      -- エラー・メッセージ           --# 固定 #
      ,ov_retcode             OUT   VARCHAR2      -- リターン・コード             --# 固定 #
      ,ov_errmsg              OUT   VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ======================================================
    -- 固定ローカル定数
    -- ======================================================
    cv_prg_name CONSTANT  VARCHAR2(100) := 'submain' ;  -- プログラム名
    -- ======================================================
    -- ローカル変数
    -- ======================================================
    lv_errbuf   VARCHAR2(5000) ;                        -- エラー・メッセージ
    lv_retcode  VARCHAR2(1) ;                           -- リターン・コード
    lv_errmsg   VARCHAR2(5000) ;                        -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ======================================================
    -- ユーザー宣言部
    -- ======================================================
    -- *** ローカル変数 ***
    lr_param_rec          rec_param_data ;          -- パラメータ受渡し用
--
    xml_data_table        XML_DATA;
    lv_xml_string         VARCHAR2(32000) ;
    ln_retcode            NUMBER ;
--
    lv_business_name      VARCHAR2(4);              -- 出荷業務種別
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
    -- 帳票出力値格納
    gd_exec_date                      :=  SYSDATE ;               -- 実施日
--
    -- =====================================================
    -- プロファイル値取得、担当者情報抽出(H-1,H-2)
    -- =====================================================
    prc_initialize
      (
        ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_process_expt ;
    END IF ;
--
    lr_param_rec.iv_business_type       :=  iv_business_type;       -- 01 : 業務種別
    lr_param_rec.iv_block_1             :=  iv_block_1;             -- 02 : ブロック１
    lr_param_rec.iv_block_2             :=  iv_block_2;             -- 03 : ブロック２
    lr_param_rec.iv_block_3             :=  iv_block_3;             -- 04 : ブロック３
    lr_param_rec.iv_delivery_origin     :=  iv_delivery_origin;     -- 05 : 出庫元
    -- 06 : 出庫日
    lr_param_rec.iv_delivery_day        :=  FND_DATE.CANONICAL_TO_DATE( iv_delivery_day );
    lr_param_rec.iv_delivery_no         :=  iv_delivery_no;         -- 07 : 配送№
    lr_param_rec.iv_delivery_form       :=  iv_delivery_form;       -- 08 : 出庫形態
    lr_param_rec.iv_jurisdiction_base   :=  iv_jurisdiction_base;   -- 09 : 管轄拠点
    lr_param_rec.iv_addre_delivery_dest :=  iv_addre_delivery_dest; -- 10 : 配送先/入庫先
    lr_param_rec.iv_request_movement_no :=  iv_request_movement_no; -- 11 : 依頼№/移動№
    lr_param_rec.iv_commodity_div       :=  iv_commodity_div;       -- 12 : 商品区分
--
    -- =====================================================
    -- データ出力(H-4)
    -- =====================================================
    prc_create_xml_data
      (
        iox_xml_data      => xml_data_table
       ,ir_param          => lr_param_rec       -- 入力パラメータレコード
       ,ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ==================================================
    -- ＸＭＬ出力(H-4)
    -- ==================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
--
    -- --------------------------------------------------
    -- 抽出データが０件の場合
    -- --------------------------------------------------
    IF ( ( lv_errmsg IS NOT NULL ) AND ( lv_retcode = gv_status_warn ) ) THEN
--
      -- 業務種別取得SQL
      BEGIN
        SELECT
          xlv1v1.meaning                AS meaning            -- 業務種別
        INTO
          lv_business_name
        FROM
          xxcmn_lookup_values_v         xlv1v1                -- クイックコード情報VIEW
        WHERE
          lr_param_rec.iv_business_type =   xlv1v1.lookup_code
        AND
          xlv1v1.lookup_type            =   gc_quick_code_gyoumushubetsu ;
      EXCEPTION
        WHEN  OTHERS  THEN
          lv_business_name  :=  '' ;
      END ;
--
      -- ０件メッセージ出力
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<lg_denpyo_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<g_denpyo>' ) ;
--
      -- 帳票タイトル
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<title>' || gv_out_char_title || gc_msg_shizisyo ||
                                          '</title>' ) ;
      -- 帳票ID
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<tyohyo_id>' || gc_report_id ||
                                          '</tyohyo_id>' ) ;
      -- 出力日付
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<shuturyoku_hiduke>' 
        || TO_CHAR(gd_exec_date, gc_char_dt_format)
        || '</shuturyoku_hiduke>' ) ;
      -- 担当（部署）
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<tantou_busho>' || gv_department_code ||
                                          '</tantou_busho>' ) ;
      -- 担当（氏名）
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<tantou_name>' || gv_department_name ||
                                          '</tantou_name>' ) ;
--
      -- 手配No（ラベル、値）※移動時のみ帳票に出力される。
      IF ( lr_param_rec.iv_business_type <> gc_code_shukka ) THEN
        -- 手配No（ラベル）※移動時のみ『手配No』が入る 
        FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<tehai_no_label>' || gc_tehai_label ||
                                            '</tehai_no_label>') ;
      END IF ;
--
      -- 業務種別 
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<gyoumu_shubetsu>' || lv_business_name || 
                                          '</gyoumu_shubetsu>' ) ;
--
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<msg>' || lv_errmsg || 
                                          '</msg>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</g_denpyo>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</lg_denpyo_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
    -- --------------------------------------------------
    -- 帳票データが出力できた場合
    -- --------------------------------------------------
    ELSE
      --XMLデータ部出力
      <<xml_loop>>
      FOR i IN 1 .. gt_xml_data_table.COUNT LOOP
        -- 編集したデータをタグに変換
        lv_xml_string := convert_into_xml
                          (
                            iv_name   => gt_xml_data_table(i).tag_name    -- タグネーム
                           ,iv_value  => gt_xml_data_table(i).tag_value   -- タグデータ
                           ,ic_type   => gt_xml_data_table(i).tag_type    -- タグタイプ
                          ) ;
        -- ＸＭＬタグ出力
        FND_FILE.PUT_LINE( FND_FILE.OUTPUT, lv_xml_string ) ;
      END LOOP xml_loop ;
--
    END IF ;
--
    --XMLデータ削除
    gt_xml_data_table.DELETE ;
--
    -- ==================================================
    -- 終了ステータス設定
    -- ==================================================
    ov_retcode := lv_retcode ;
    ov_errmsg  := lv_errmsg ;
    ov_errbuf  := lv_errbuf ;
--
  EXCEPTION
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
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
  PROCEDURE main(
       errbuf                   OUT   VARCHAR2          -- エラーメッセージ
      ,retcode                  OUT   VARCHAR2          -- エラーコード
      ,iv_business_type         IN    VARCHAR2          -- 01 : 業務種別
      ,iv_block_1               IN    VARCHAR2          -- 02 : ブロック１
      ,iv_block_2               IN    VARCHAR2          -- 03 : ブロック２
      ,iv_block_3               IN    VARCHAR2          -- 04 : ブロック３
      ,iv_delivery_origin       IN    VARCHAR2          -- 05 : 出庫元
      ,iv_delivery_day          IN    VARCHAR2          -- 06 : 出庫日
      ,iv_delivery_no           IN    VARCHAR2          -- 07 : 配送№
      ,iv_delivery_form         IN    VARCHAR2          -- 08 : 出庫形態
      ,iv_jurisdiction_base     IN    VARCHAR2          -- 09 : 管轄拠点
      ,iv_addre_delivery_dest   IN    VARCHAR2          -- 10 : 配送先/入庫先
      ,iv_request_movement_no   IN    VARCHAR2          -- 11 : 依頼№/移動№
      ,iv_commodity_div         IN    VARCHAR2          -- 12 : 商品区分
  )
  IS
--
--###########################  固定部 START   ###########################
--
    -- ======================================================
    -- 固定ローカル定数
    -- ======================================================
    cv_prg_name   CONSTANT  VARCHAR2(100)   := 'main' ; -- プログラム名
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
        iv_business_type        => iv_business_type         -- 01 : 業務種別
       ,iv_block_1              => iv_block_1               -- 02 : ブロック１
       ,iv_block_2              => iv_block_2               -- 03 : ブロック２
       ,iv_block_3              => iv_block_3               -- 04 : ブロック３
       ,iv_delivery_origin      => iv_delivery_origin       -- 05 : 出庫元
       ,iv_delivery_day         => iv_delivery_day          -- 06 : 出庫日
       ,iv_delivery_no          => iv_delivery_no           -- 07 : 配送№
       ,iv_delivery_form        => iv_delivery_form         -- 08 : 出庫形態
       ,iv_jurisdiction_base    => iv_jurisdiction_base     -- 09 : 管轄拠点
       ,iv_addre_delivery_dest  => iv_addre_delivery_dest   -- 10 : 配送先/入庫先
       ,iv_request_movement_no  => iv_request_movement_no   -- 11 : 依頼№/移動№
       ,iv_commodity_div        => iv_commodity_div         -- 12 : 商品区分
       ,ov_errbuf               => lv_errbuf            -- エラー・メッセージ           --# 固定 #
       ,ov_retcode              => lv_retcode           -- リターン・コード             --# 固定 #
       ,ov_errmsg               => lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
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
    END IF ;
--
    --ステータスセット
    retcode := lv_retcode ;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
  END main ;
--
--###########################  固定部 END   #######################################################
--
END xxwsh620008c;
/