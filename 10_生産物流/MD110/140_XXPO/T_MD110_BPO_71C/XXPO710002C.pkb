CREATE OR REPLACE PACKAGE BODY xxpo710002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo710002c(body)
 * Description      : 生産物流（仕入）
 * MD.050/070       : 生産物流（仕入）Issue1.0  (T_MD050_BPO_710)
 *                    荒茶製造表累計            (T_MD070_BPO_71C)
 * Version          : 1.2
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  convert_into_xml          XMLデータ変換
 *  insert_xml_plsql_table    XMLデータ格納
 *  prc_initialize            前処理(C-2)
 *  prc_get_report_data       明細データ取得(C-3)
 *  prc_create_xml_data       ＸＭＬデータ作成(C-4)
 *  submain                   メイン処理プロシージャ
 *  main                      コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ------------------ -------------------------------------------------
 *  Date          Ver.  Editor             Description
 * ------------- ----- ------------------ -------------------------------------------------
 *  2008/01/22    1.0   Yasuhisa Yamamoto  新規作成
 *  2008/05/20    1.1   Yohei    Takayama  結合テスト対応(710_11)
 *  2008/07/02    1.2   Satoshi Yunba      禁則文字「'」「"」「<」「>」「&」対応
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
  gv_pkg_name                  CONSTANT VARCHAR2(20)  := 'xxpo710002c' ;          -- パッケージ名
  gc_report_id                 CONSTANT VARCHAR2(12)  := 'XXPO710002T';           -- 帳票ID
  gc_report_title_kari         CONSTANT VARCHAR2(20)  := '（仮）荒茶製造表累計' ; -- 帳票タイトル（帳票種別：3）
  gc_report_title              CONSTANT VARCHAR2(14)  := '荒茶製造表累計' ;       -- 帳票タイトル（帳票種別：4）
  gc_report_type_3             CONSTANT VARCHAR2(1)   := '3' ;                    -- 帳票種別（3：仮単価使用）
  gc_report_type_4             CONSTANT VARCHAR2(1)   := '4' ;                    -- 帳票種別（4：正単価使用）
  gc_tag_type_tag              CONSTANT VARCHAR2(1)   := 'T' ;                    -- 出力タグタイプ（T：タグ）
  gc_tag_type_data             CONSTANT VARCHAR2(1)   := 'D' ;                    -- 出力タグタイプ（D：データ）
  gc_tag_value_type_char       CONSTANT VARCHAR2(1)   := 'C' ;                    -- 出力タイプ（C：Char）
  gc_item_class_siage          CONSTANT VARCHAR2(4)   := '仕上' ;                 -- 区分（仕上）
  gc_item_class_fuku           CONSTANT VARCHAR2(6)   := '副産物' ;               -- 区分（副産物）
  gc_bypro_default_num         CONSTANT NUMBER        := 0 ;                      -- 副産物未表示データ初期値
  gc_out_year                  CONSTANT VARCHAR2(2)   := '年' ;                   -- 期間出力用（年）
  gc_out_month                 CONSTANT VARCHAR2(2)   := '月' ;                   -- 期間出力用（月）
  gc_out_day                   CONSTANT VARCHAR2(2)   := '日' ;                   -- 期間出力用（日）
  gc_out_part                  CONSTANT VARCHAR2(2)   := '‐' ;                   -- 期間出力用（‐）
--
  ------------------------------
  -- クイックコード関連
  ------------------------------
  gc_final_unit_price_entered  CONSTANT VARCHAR2(1)   := 'Y' ;
--
  ------------------------------
  -- エラーメッセージ関連
  ------------------------------
  gc_application_cmn           CONSTANT VARCHAR2(5)   := 'XXCMN' ;                -- アプリケーション（XXCMN）
  gc_application_po            CONSTANT VARCHAR2(5)   := 'XXPO' ;                 -- アプリケーション（XXPO）
  gc_xxpo_00036                CONSTANT VARCHAR2(14)  := 'APP-XXPO-00036' ;       -- 担当部署名未取得メッセージ
  gc_xxpo_00026                CONSTANT VARCHAR2(14)  := 'APP-XXPO-00026' ;       -- 担当者名未取得メッセージ
  gc_xxcmn_10122               CONSTANT VARCHAR2(15)  := 'APP-XXCMN-10122' ;      -- 明細0件用メッセージ
--
  ------------------------------
  -- 項目編集関連
  ------------------------------
  gc_char_d_format             CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD' ;
  gc_char_dt_format            CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS' ;
  gc_max_date_d                CONSTANT VARCHAR2(10)  := '4712/12/31';
  gc_min_date_d                CONSTANT VARCHAR2(10)  := '1900/01/01';
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 入力パラメータ格納用レコード変数
  TYPE rec_param_data  IS RECORD 
    (
      iv_report_type           fnd_lookup_values.lookup_code%TYPE                 --   01 : 帳票種別
     ,iv_creat_date_from       VARCHAR2(10)                                       --   02 : 製造期間FROM
     ,iv_creat_date_to         VARCHAR2(10)                                       --   03 : 製造期間TO
    ) ;
--
  -- 荒茶製造表データ格納用レコード変数
  TYPE rec_data_type_dtl  IS RECORD 
    (
     location_code             mtl_item_locations.segment1%TYPE                   -- 入庫倉庫コード
    ,location_name             mtl_item_locations.description%TYPE                -- 入庫倉庫名
    ,item_class                VARCHAR2(6)                                        -- 区分
    ,item_code                 xxpo_namaha_prod_txns.aracha_item_code%TYPE        -- 品名（コード）
    ,item_name                 xxcmn_item_mst_b.item_short_name%TYPE              -- 品名（名）
    ,quantity                  xxpo_namaha_prod_txns.aracha_quantity%TYPE         -- 数量
    ,stock_amount              NUMBER                                             -- 在庫金額
    ,aracha_amount             NUMBER                                             -- 原料金額
    ,collect_quantity          xxpo_namaha_prod_txns.collect1_quantity%TYPE       -- 集荷数量
    ,collect_amount            NUMBER                                             -- 集荷金額
    ,receive_quantity          xxpo_namaha_prod_txns.receive1_quantity%TYPE       -- 受入数量
    ,receive_amount            NUMBER                                             -- 受入金額
    ,shipment_quantity         xxpo_namaha_prod_txns.shipment_quantity%TYPE       -- 出荷数量
    ,shipment_amount           NUMBER                                             -- 出荷金額
    ,nahama_total_quantity     xxpo_namaha_prod_txns.aracha_quantity%TYPE         -- 生葉合計数量
    ,namaha_total_amount       NUMBER                                             -- 生葉合計金額
    ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  ------------------------------
  -- ＸＭＬ用
  ------------------------------
  gd_exec_date                 DATE ;                                             -- 実施日
  gd_max_date                  DATE ;                                             -- 最大日チェック用
  gv_department_code           VARCHAR2(10) ;                                     -- 担当部署
  gv_department_name           VARCHAR2(14) ;                                     -- 担当者
--
  gt_main_data                 tab_data_type_dtl ;                                -- 取得レコード表
--
--#####################  固定共通例外宣言部 START   ####################
--
  --*** 処理部共通例外 ***
  global_process_expt          EXCEPTION ;
  --*** 共通関数例外 ***
  global_api_expt              EXCEPTION ;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt       EXCEPTION ;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000) ;
--
--###########################  固定部 END   ############################
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
    IF (ic_type = gc_tag_type_data) THEN
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
   * Procedure Name   : insert_xml_plsql_table
   * Description      : XMLデータ格納
   ***********************************************************************************/
  PROCEDURE insert_xml_plsql_table(
    iox_xml_data      IN OUT NOCOPY XML_DATA,
    iv_tag_name       IN     VARCHAR2,
    iv_tag_value      IN     VARCHAR2,
    ic_tag_type       IN     CHAR,
    ic_tag_value_type IN     CHAR)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    i NUMBER;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
    i:= iox_xml_data.COUNT + 1 ;
    iox_xml_data(i).TAG_NAME  := iv_tag_name;
--
    IF (ic_tag_value_type = 'P') THEN
      iox_xml_data(i).TAG_VALUE := TO_CHAR(TO_NUMBER(iv_tag_value),'99990.900');
    ELSIF (ic_tag_value_type = 'B') THEN
      iox_xml_data(i).TAG_VALUE := TO_CHAR(TO_NUMBER(iv_tag_value),'9999990.90');
    ELSE
      iox_xml_data(i).TAG_VALUE := iv_tag_value;
    END IF;
    iox_xml_data(i).TAG_TYPE  := ic_tag_type;
--
  END insert_xml_plsql_table;
--
  /**********************************************************************************
   * Procedure Name   : prc_initialize
   * Description      : 前処理(C-2)
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
    get_value_expt  EXCEPTION ;     -- 値取得エラー
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
-- 08/05/20 Y.Takayama DEL v1.1 Start
--    IF ( gv_department_code IS NULL ) THEN
--      lv_err_code := gc_xxpo_00036 ;
--      RAISE get_value_expt ;
--    END IF ;
-- 08/05/20 Y.Takayama DEL v1.1 End
--
    -- ====================================================
    -- 担当者取得
    -- ====================================================
    gv_department_name := SUBSTRB( xxcmn_common_pkg.get_user_name( FND_GLOBAL.USER_ID ), 1, 14 ) ;
-- 08/05/20 Y.Takayama DEL v1.1 Start
--    IF ( gv_department_name IS NULL ) THEN
--      lv_err_code := gc_xxpo_00026 ;
--      RAISE get_value_expt ;
--    END IF ;
-- 08/05/20 Y.Takayama DEL v1.1 End
--
  EXCEPTION
    --*** 値取得エラー例外 ***
    WHEN get_value_expt THEN
      -- メッセージセット
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_po
                                            ,lv_err_code    ) ;
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
   * Description      : 明細データ取得(C-3)
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
        in_report_type      fnd_lookup_values.lookup_code%TYPE
       ,in_creat_date_from  VARCHAR2
       ,in_creat_date_to    VARCHAR2
      )
    IS
      SELECT cmd.location_code                                                      -- 入庫先
            ,cmd.location_name                                                      -- 入庫先名
            ,cmd.item_class                                                         -- 区分
            ,cmd.item_code                                                          -- 品目
            ,cmd.item_name                                                          -- 品名
            ,cmd.quantity                                                           -- 数量
            ,cmd.stock_amount                                                       -- 在庫金額
            ,cmd.aracha_amount                                                      -- 原料金額
            ,cmd.collect_quantity                                                   -- 集荷数量
            ,cmd.collect_amount                                                     -- 集荷金額
            ,cmd.receive_quantity                                                   -- 受入数量
            ,cmd.receive_amount                                                     -- 受入金額
            ,cmd.shipment_quantity                                                  -- 出荷数量
            ,cmd.shipment_amount                                                    -- 出荷金額
            ,cmd.nahama_total_quantity                                              -- 生葉合計数量
            ,cmd.namaha_total_amount                                                -- 生葉合計金額
      FROM
        (
          -- *** 仕上品目情報のデータ取得 ***
          SELECT xilv.segment1                            AS location_code          -- 入庫先
                ,xilv.description                         AS location_name          -- 入庫先名
                ,gc_item_class_siage                      AS item_class             -- 区分（仕上）固定
                ,xnpt.aracha_item_code                    AS item_code              -- 品目
                ,ximv.item_short_name                     AS item_name              -- 品名
                ,SUM( NVL( xnpt.aracha_quantity, 0 ) )    AS quantity               -- 数量
                ,SUM( ROUND( NVL( xnpt.aracha_quantity, 0 ) * TO_NUMBER( NVL( ilm.attribute7, '0') ) ) )
                                                          AS stock_amount           -- 在庫金額
                ,CASE
                  WHEN ( in_report_type = gc_report_type_3 ) THEN                   -- 仮単価で算出
                     SUM(  ROUND( NVL( xnpt.collect1_temp_unit_price, 0) * NVL( xnpt.collect1_quantity, 0) )
                         + ROUND( NVL( xnpt.collect2_temp_unit_price, 0) * NVL( xnpt.collect2_quantity, 0) )
                         + ROUND( NVL( xnpt.receive1_temp_unit_price, 0) * NVL( xnpt.receive1_quantity, 0) )
                         + ROUND( NVL( xnpt.receive2_temp_unit_price, 0) * NVL( xnpt.receive2_quantity, 0) )
                         - ROUND( NVL( xnpt.shipment_temp_unit_price, 0) * NVL( xnpt.shipment_quantity, 0) ) )
                   - SUM(  ROUND( NVL( xnpt.byproduct1_quantity, 0) * TO_NUMBER( NVL( ilm_by1.attribute7, '0') ) )
                         + ROUND( NVL( xnpt.byproduct2_quantity, 0) * TO_NUMBER( NVL( ilm_by2.attribute7, '0') ) )
                         + ROUND( NVL( xnpt.byproduct3_quantity, 0) * TO_NUMBER( NVL( ilm_by3.attribute7, '0') ) ) )
                  WHEN ( in_report_type = gc_report_type_4 ) THEN                   -- 正単価で算出
                     SUM(  ROUND( NVL( xnpt.collect1_final_unit_price, 0) * NVL( xnpt.collect1_quantity, 0) )
                         + ROUND( NVL( xnpt.collect2_final_unit_price, 0) * NVL( xnpt.collect2_quantity, 0) )
                         + ROUND( NVL( xnpt.receive1_final_unit_price, 0) * NVL( xnpt.receive1_quantity, 0) )
                         + ROUND( NVL( xnpt.receive2_final_unit_price, 0) * NVL( xnpt.receive2_quantity, 0) )
                         - ROUND( NVL( xnpt.shipment_final_unit_price, 0) * NVL( xnpt.shipment_quantity, 0) ) )
                   - SUM(  ROUND( NVL( xnpt.byproduct1_quantity, 0) * TO_NUMBER( NVL( ilm_by1.attribute7, '0') ) )
                         + ROUND( NVL( xnpt.byproduct2_quantity, 0) * TO_NUMBER( NVL( ilm_by2.attribute7, '0') ) )
                         + ROUND( NVL( xnpt.byproduct3_quantity, 0) * TO_NUMBER( NVL( ilm_by3.attribute7, '0') ) ) )
                 END                                         aracha_amount          -- 原料金額
                ,SUM( NVL( xnpt.collect1_quantity, 0) + NVL( xnpt.collect2_quantity, 0) )
                                                          AS collect_quantity       -- 集荷数量
                ,CASE
                  WHEN ( in_report_type = gc_report_type_3 ) THEN                   -- 仮単価で算出
                     SUM(  ROUND( NVL( xnpt.collect1_temp_unit_price, 0) * NVL( xnpt.collect1_quantity, 0) )
                         + ROUND( NVL( xnpt.collect2_temp_unit_price, 0) * NVL( xnpt.collect2_quantity, 0) ) )
                  WHEN ( in_report_type = gc_report_type_4 ) THEN                   -- 正単価で算出
                     SUM(  ROUND( NVL( xnpt.collect1_final_unit_price, 0) * NVL( xnpt.collect1_quantity, 0) )
                         + ROUND( NVL( xnpt.collect2_final_unit_price, 0) * NVL( xnpt.collect2_quantity, 0) ) )
                 END                                         collect_amount         -- 集荷金額
                ,SUM( NVL( xnpt.receive1_quantity, 0) + NVL( xnpt.receive2_quantity, 0) )
                                                          AS receive_quantity       -- 受入数量
                ,CASE
                  WHEN ( in_report_type = gc_report_type_3 ) THEN                   -- 仮単価で算出
                     SUM(  ROUND( NVL( xnpt.receive1_temp_unit_price, 0) * NVL( xnpt.receive1_quantity, 0) )
                         + ROUND( NVL( xnpt.receive2_temp_unit_price, 0) * NVL( xnpt.receive2_quantity, 0) ) )
                  WHEN ( in_report_type = gc_report_type_4 ) THEN                   -- 正単価で算出
                     SUM(  ROUND( NVL( xnpt.receive1_final_unit_price, 0) * NVL( xnpt.receive1_quantity, 0) )
                         + ROUND( NVL( xnpt.receive2_final_unit_price, 0) * NVL( xnpt.receive2_quantity, 0) ) )
                 END                                         receive_amount         -- 受入金額
                ,SUM( NVL( xnpt.shipment_quantity, 0) )   AS shipment_quantity      -- 出荷数量
                ,CASE
                  WHEN ( in_report_type = gc_report_type_3 ) THEN                   -- 仮単価で算出
                     SUM( ROUND( NVL( xnpt.shipment_temp_unit_price, 0) * NVL( xnpt.shipment_quantity, 0) ) )
                  WHEN ( in_report_type = gc_report_type_4 ) THEN                   -- 正単価で算出
                     SUM( ROUND( NVL( xnpt.shipment_final_unit_price, 0) * NVL( xnpt.shipment_quantity, 0) ) )
                 END                                         shipment_amount        -- 出荷金額
                ,SUM(  NVL( xnpt.collect1_quantity, 0) + NVL( xnpt.collect2_quantity, 0)
                     + NVL( xnpt.receive1_quantity, 0) + NVL( xnpt.receive2_quantity, 0)
                     - NVL( xnpt.shipment_quantity, 0) )  AS nahama_total_quantity  -- 生葉合計数量
                ,CASE
                  WHEN ( in_report_type = gc_report_type_3 ) THEN                   -- 仮単価で算出
                     SUM(  ROUND( NVL( xnpt.collect1_temp_unit_price, 0) * NVL( xnpt.collect1_quantity, 0) )
                         + ROUND( NVL( xnpt.collect2_temp_unit_price, 0) * NVL( xnpt.collect2_quantity, 0) )
                         + ROUND( NVL( xnpt.receive1_temp_unit_price, 0) * NVL( xnpt.receive1_quantity, 0) )
                         + ROUND( NVL( xnpt.receive2_temp_unit_price, 0) * NVL( xnpt.receive2_quantity, 0) )
                         - ROUND( NVL( xnpt.shipment_temp_unit_price, 0) * NVL( xnpt.shipment_quantity, 0) ) )
                  WHEN ( in_report_type = gc_report_type_4 ) THEN                   -- 正単価で算出
                     SUM(  ROUND( NVL( xnpt.collect1_final_unit_price, 0) * NVL( xnpt.collect1_quantity, 0) )
                         + ROUND( NVL( xnpt.collect2_final_unit_price, 0) * NVL( xnpt.collect2_quantity, 0) )
                         + ROUND( NVL( xnpt.receive1_final_unit_price, 0) * NVL( xnpt.receive1_quantity, 0) )
                         + ROUND( NVL( xnpt.receive2_final_unit_price, 0) * NVL( xnpt.receive2_quantity, 0) )
                         - ROUND( NVL( xnpt.shipment_final_unit_price, 0) * NVL( xnpt.shipment_quantity, 0) ) )
                 END                                         namaha_total_amount    -- 生葉合計金額
          FROM   xxpo_namaha_prod_txns    xnpt                                      -- 生葉実績（アドオン）
                ,ic_lots_mst              ilm                                       -- OPMロットマスタ
                ,xxcmn_item_mst2_v        ximv                                      -- OPM品目情報VIEW2
                ,ic_lots_mst              ilm_by1                                   -- OPMロットマスタ（副産物１）
                ,ic_lots_mst              ilm_by2                                   -- OPMロットマスタ（副産物２）
                ,ic_lots_mst              ilm_by3                                   -- OPMロットマスタ（副産物３）
                ,xxcmn_item_locations2_v  xilv                                      -- OPM保管場所情報VIEW2
          ---------------------------------------------------------------------------------------------
          -- 結合条件
          WHERE xnpt.aracha_item_id     = ilm.item_id
          AND   xnpt.aracha_lot_id      = ilm.lot_id
          AND   xnpt.aracha_item_id     = ximv.item_id
          AND   FND_DATE.STRING_TO_DATE( ilm.attribute1, gc_char_d_format ) BETWEEN ximv.start_date_active
                                                                   AND NVL( ximv.end_date_active, gd_max_date )
          AND   xnpt.byproduct1_item_id = ilm_by1.item_id(+)
          AND   xnpt.byproduct1_lot_id  = ilm_by1.lot_id(+)
          AND   xnpt.byproduct2_item_id = ilm_by2.item_id(+)
          AND   xnpt.byproduct2_lot_id  = ilm_by2.lot_id(+)
          AND   xnpt.byproduct3_item_id = ilm_by3.item_id(+)
          AND   xnpt.byproduct3_lot_id  = ilm_by3.lot_id(+)
          AND   xnpt.location_id        = xilv.inventory_location_id
          AND   FND_DATE.STRING_TO_DATE( ilm.attribute1, gc_char_d_format ) BETWEEN xilv.date_from
                                                                   AND NVL( xilv.date_to, gd_max_date )
          ---------------------------------------------------------------------------------------------
          -- 抽出条件
          AND   ((    in_report_type    = gc_report_type_4                          -- 帳票種別：4のとき
                  AND xnpt.final_unit_price_entered_flg
                                        = gc_final_unit_price_entered )             -- 正単価入力完了フラグ＝'Y'
                 OR ( in_report_type    = gc_report_type_3 ))                       -- 帳票種別：3のとき
          AND   ilm.attribute1   BETWEEN  in_creat_date_from                        -- パラメータの製造日で
                                 AND NVL( in_creat_date_to, gc_max_date_d )         -- 有効なデータ
          AND   xnpt.aracha_quantity    > 0                                         -- 数量0は取消データの為、除外
          GROUP BY xilv.segment1                                                    -- 入庫先
                  ,xilv.description                                                 -- 入庫先名
                  ,xnpt.aracha_item_code                                            -- 品目
                  ,ximv.item_short_name                                             -- 品名
        UNION ALL
          -- *** 副産物品目情報のデータ取得 ***
          SELECT byproduct.location_code                  AS location_code          -- 入庫先
                ,byproduct.location_name                  AS location_name          -- 入庫先名
                ,gc_item_class_fuku                       AS item_class             -- 区分（副産物）固定
                ,byproduct.item_code                      AS item_code              -- 品目
                ,byproduct.item_name                      AS item_name              -- 品名
                ,SUM( byproduct.quantity )                AS quantity               -- 数量
                ,SUM( byproduct.amount )                  AS stock_amount           -- 在庫金額
                ,gc_bypro_default_num                     AS aracha_amount          -- 原料金額
                ,gc_bypro_default_num                     AS collect_quantity       -- 集荷数量
                ,gc_bypro_default_num                     AS collect_amount         -- 集荷金額
                ,gc_bypro_default_num                     AS receive_quantity       -- 受入数量
                ,gc_bypro_default_num                     AS receive_amount         -- 受入金額
                ,gc_bypro_default_num                     AS shipment_quantity      -- 出荷数量
                ,gc_bypro_default_num                     AS shipment_amount        -- 出荷金額
                ,gc_bypro_default_num                     AS nahama_total_quantity  -- 生葉合計数量
                ,gc_bypro_default_num                     AS namaha_total_amount    -- 生葉合計金額
          FROM (
                 -- *** 副産物１情報 ***
                 SELECT xilv.segment1                     AS location_code          -- 入庫先
                       ,xilv.description                  AS location_name          -- 入庫先名
                       ,xnpt.byproduct1_item_code         AS item_code              -- 副産物１品目コード
                       ,ximv.item_short_name              AS item_name              -- 品名
                       ,NVL( xnpt.byproduct1_quantity, 0) AS quantity               -- 副産物１数量
                       ,ROUND( NVL( xnpt.byproduct1_quantity, 0) * TO_NUMBER( NVL( ilm.attribute7, '0' ) ) ) 
                                                          AS amount                 -- 副産物１金額
                 FROM   xxpo_namaha_prod_txns     xnpt                              -- 生葉実績（アドオン）
                       ,ic_lots_mst               ilm                               -- OPMロットマスタ
                       ,xxcmn_item_mst2_v         ximv                              -- OPM品目情報VIEW2
                       ,xxcmn_item_locations2_v   xilv                              -- OPM保管場所情報VIEW2
                 ---------------------------------------------------------------------------------------------
                 -- 結合条件
                 WHERE xnpt.byproduct1_item_id  = ilm.item_id
                 AND   xnpt.byproduct1_lot_id   = ilm.lot_id
                 AND   xnpt.byproduct1_item_id  = ximv.item_id
                 AND   FND_DATE.STRING_TO_DATE( ilm.attribute1, gc_char_d_format ) BETWEEN ximv.start_date_active
                                                                     AND NVL( ximv.end_date_active, gd_max_date )
                 AND   xnpt.location_id         = xilv.inventory_location_id
                 AND   FND_DATE.STRING_TO_DATE( ilm.attribute1, gc_char_d_format ) BETWEEN xilv.date_from
                                                                     AND NVL( xilv.date_to, gd_max_date )
                 ---------------------------------------------------------------------------------------------
                 -- 抽出条件
                 AND   ((    in_report_type     = gc_report_type_4                  -- 帳票種別：4のとき
                         AND xnpt.final_unit_price_entered_flg
                                                = gc_final_unit_price_entered )     -- 正単価入力完了フラグ＝'Y'
                        OR ( in_report_type     = gc_report_type_3 ))               -- 帳票種別：3のとき
                 AND   ilm.attribute1    BETWEEN  in_creat_date_from                -- パラメータの製造日で
                                         AND NVL( in_creat_date_to, gc_max_date_d ) -- 有効なデータ
                 AND   xnpt.aracha_quantity     > 0                                 -- 数量0は取消データの為、除外
                 AND   xnpt.byproduct1_quantity > 0                                 -- 数量0は取消データの為、除外
               UNION ALL
               -- *** 副産物２情報 ***
                 SELECT xilv.segment1                     AS location_code          -- 入庫先
                       ,xilv.description                  AS location_name          -- 入庫先名
                       ,xnpt.byproduct2_item_code         AS item_code              -- 副産物２品目コード
                       ,ximv.item_short_name              AS item_name              -- 品名
                       ,NVL( xnpt.byproduct2_quantity, 0) AS quantity               -- 副産物２数量
                       ,ROUND( NVL( xnpt.byproduct2_quantity, 0) * TO_NUMBER( NVL( ilm.attribute7, '0' ) ) ) 
                                                          AS amount                 -- 副産物２金額
                 FROM   xxpo_namaha_prod_txns     xnpt                              -- 生葉実績（アドオン）
                       ,ic_lots_mst               ilm                               -- OPMロットマスタ
                       ,xxcmn_item_mst2_v         ximv                              -- OPM品目情報VIEW2
                       ,xxcmn_item_locations2_v   xilv                              -- OPM保管場所情報VIEW2
                 ---------------------------------------------------------------------------------------------
                 -- 結合条件
                 WHERE xnpt.byproduct2_item_id  = ilm.item_id
                 AND   xnpt.byproduct2_lot_id   = ilm.lot_id
                 AND   xnpt.byproduct2_item_id  = ximv.item_id
                 AND   FND_DATE.STRING_TO_DATE( ilm.attribute1, gc_char_d_format ) BETWEEN ximv.start_date_active
                                                                     AND NVL( ximv.end_date_active, gd_max_date )
                 AND   xnpt.location_id         = xilv.inventory_location_id
                 AND   FND_DATE.STRING_TO_DATE( ilm.attribute1, gc_char_d_format ) BETWEEN xilv.date_from
                                                                     AND NVL( xilv.date_to, gd_max_date )
                 ---------------------------------------------------------------------------------------------
                 -- 抽出条件
                 AND   ((    in_report_type     = gc_report_type_4                  -- 帳票種別：4のとき
                         AND xnpt.final_unit_price_entered_flg
                                                = gc_final_unit_price_entered )     -- 正単価入力完了フラグ＝'Y'
                        OR ( in_report_type     = gc_report_type_3 ))               -- 帳票種別：3のとき
                 AND   ilm.attribute1    BETWEEN  in_creat_date_from                -- パラメータの製造日で
                                         AND NVL( in_creat_date_to, gc_max_date_d ) -- 有効なデータ
                 AND   xnpt.aracha_quantity     > 0                                 -- 数量0は取消データの為、除外
                 AND   xnpt.byproduct2_quantity > 0                                 -- 数量0は取消データの為、除外
               UNION ALL
               -- *** 副産物３情報 ***
                 SELECT xilv.segment1                     AS location_code          -- 入庫先
                       ,xilv.description                  AS location_name          -- 入庫先名
                       ,xnpt.byproduct3_item_code         AS item_code              -- 副産物３品目コード
                       ,ximv.item_short_name              AS item_name              -- 品名
                       ,NVL( xnpt.byproduct3_quantity, 0) AS quantity               -- 副産物３数量
                       ,ROUND( NVL( xnpt.byproduct3_quantity, 0) * TO_NUMBER( NVL( ilm.attribute7, '0' ) ) ) 
                                                          AS amount                 -- 副産物３金額
                 FROM   xxpo_namaha_prod_txns     xnpt                              -- 生葉実績（アドオン）
                       ,ic_lots_mst               ilm                               -- OPMロットマスタ
                       ,xxcmn_item_mst2_v         ximv                              -- OPM品目情報VIEW2
                       ,xxcmn_item_locations2_v   xilv                              -- OPM保管場所情報VIEW2
                 ---------------------------------------------------------------------------------------------
                 -- 結合条件
                 WHERE xnpt.byproduct3_item_id  = ilm.item_id
                 AND   xnpt.byproduct3_lot_id   = ilm.lot_id
                 AND   xnpt.byproduct3_item_id  = ximv.item_id
                 AND   FND_DATE.STRING_TO_DATE( ilm.attribute1, gc_char_d_format ) BETWEEN ximv.start_date_active
                                                                     AND NVL( ximv.end_date_active, gd_max_date )
                 AND   xnpt.location_id         = xilv.inventory_location_id
                 AND   FND_DATE.STRING_TO_DATE( ilm.attribute1, gc_char_d_format ) BETWEEN xilv.date_from
                                                                     AND NVL( xilv.date_to, gd_max_date )
                 ---------------------------------------------------------------------------------------------
                 -- 抽出条件
                 AND   ((    in_report_type     = gc_report_type_4                  -- 帳票種別：4のとき
                         AND xnpt.final_unit_price_entered_flg
                                                = gc_final_unit_price_entered )     -- 正単価入力完了フラグ＝'Y'
                        OR ( in_report_type     = gc_report_type_3 ))               -- 帳票種別：3のとき
                 AND   ilm.attribute1    BETWEEN  in_creat_date_from                -- パラメータの製造日で
                                         AND NVL( in_creat_date_to, gc_max_date_d ) -- 有効なデータ
                 AND   xnpt.aracha_quantity     > 0                                 -- 数量0は取消データの為、除外
                 AND   xnpt.byproduct3_quantity > 0                                 -- 数量0は取消データの為、除外
               )  byproduct
          GROUP BY byproduct.location_code                                          -- 入庫先
                  ,byproduct.location_name                                          -- 入庫先名
                  ,byproduct.item_code                                              -- 品目
                  ,byproduct.item_name                                              -- 品名
        ) cmd
      ORDER BY cmd.location_code                                                    -- 入庫先
              ,cmd.item_class                                                       -- 区分
              ,to_number( cmd.item_code )                                           -- 品目
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
        ir_param.iv_report_type         -- 帳票種別
       ,ir_param.iv_creat_date_from     -- 製造期間FROM
       ,ir_param.iv_creat_date_to       -- 製造期間TO
      ) ;
    -- バルクフェッチ
    FETCH cur_main_data BULK COLLECT INTO ot_data_rec ;
    -- カーソルクローズ
    CLOSE cur_main_data ;
--
  EXCEPTION
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
   * Procedure Name   : prc_create_xml_data
   * Description      : ＸＭＬデータ作成(C-4)
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data
    (
      iox_xml_data IN OUT NOCOPY XML_DATA
     ,ir_param          IN  rec_param_data    -- 01.レコード  ：パラメータ
     ,ov_errbuf         OUT VARCHAR2          --    エラー・メッセージ           --# 固定 #
     ,ov_retcode        OUT VARCHAR2          --    リターン・コード             --# 固定 #
     ,ov_errmsg         OUT VARCHAR2          --    ユーザー・エラー・メッセージ --# 固定 #
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
    -- キーブレイク判断用
    lc_break_init  VARCHAR2(5)  := '*****';
--
    -- *** ローカル変数 ***
    -- キーブレイク判断用
    lv_loc_code    mtl_item_locations.segment1%TYPE; -- 入庫倉庫コード
    lv_item_class  VARCHAR2(6);                      -- 区分
    -- 期間の出力編集用
    lv_date_fromto VARCHAR2(30);
--
    -- *** ローカル・例外処理 ***
    no_data_expt   EXCEPTION ;   -- 取得レコードなし
--
  BEGIN
--
    -- =====================================================
    -- ブレイクキー初期化
    -- =====================================================
    lv_loc_code   := lc_break_init;
    lv_item_class := lc_break_init;
--
    -- =====================================================
    -- 項目データ抽出処理
    -- =====================================================
    prc_get_report_data
      (
        ir_param      => ir_param       -- 01.入力パラメータ群
       ,ot_data_rec   => gt_main_data   -- 02.取得レコード群
       ,ov_errbuf     => lv_errbuf      --    エラー・メッセージ           --# 固定 #
       ,ov_retcode    => lv_retcode     --    リターン・コード             --# 固定 #
       ,ov_errmsg     => lv_errmsg      --    ユーザー・エラー・メッセージ --# 固定 #
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
    -- -----------------------------------------------------
    -- データＧ開始タグ出力
    -- -----------------------------------------------------
    insert_xml_plsql_table(iox_xml_data, 'root',      NULL, gc_tag_type_tag, gc_tag_value_type_char);
    insert_xml_plsql_table(iox_xml_data, 'data_info', NULL, gc_tag_type_tag, gc_tag_value_type_char);
    -- -----------------------------------------------------
    -- 倉庫Ｇ開始タグ出力
    -- -----------------------------------------------------
    insert_xml_plsql_table(iox_xml_data, 'lg_itemlocation_info', NULL, gc_tag_type_tag, gc_tag_value_type_char);
    insert_xml_plsql_table(iox_xml_data, 'g_itemloc',            NULL, gc_tag_type_tag, gc_tag_value_type_char);
--
    -- -----------------------------------------------------
    -- 帳票Ｇデータタグ出力
    -- -----------------------------------------------------
    insert_xml_plsql_table(iox_xml_data, 'report_info', NULL, gc_tag_type_tag, gc_tag_value_type_char);
    -- 帳票タイトル
    IF ( ir_param.iv_report_type = gc_report_type_3 ) THEN
      -- 帳票種別：3のとき
      insert_xml_plsql_table(iox_xml_data, 'report_title', gc_report_title_kari, 
                                                             gc_tag_type_data, gc_tag_value_type_char);
    ELSIF ( ir_param.iv_report_type = gc_report_type_4 ) THEN
      -- 帳票種別：4のとき
      insert_xml_plsql_table(iox_xml_data, 'report_title', gc_report_title, 
                                                             gc_tag_type_data, gc_tag_value_type_char);
    ELSE
      -- 帳票種別：3、4以外のとき
      insert_xml_plsql_table(iox_xml_data, 'report_title', NULL, 
                                                             gc_tag_type_data, gc_tag_value_type_char);
    END IF;
    -- 帳票ＩＤ
    insert_xml_plsql_table(iox_xml_data, 'report_id', gc_report_id, 
                                                        gc_tag_type_data, gc_tag_value_type_char);
    -- 実施日
    insert_xml_plsql_table(iox_xml_data, 'exec_date', TO_CHAR( gd_exec_date, gc_char_dt_format ), 
                                                        gc_tag_type_data, gc_tag_value_type_char);
    -- 期間
    -- 期間の編集
    lv_date_fromto := SUBSTRB( ir_param.iv_creat_date_from, 1, 4) || gc_out_year  ||
                      SUBSTRB( ir_param.iv_creat_date_from, 6, 2) || gc_out_month ||
                      SUBSTRB( ir_param.iv_creat_date_from, 9, 2) || gc_out_day   || gc_out_part;
    IF ( ir_param.iv_creat_date_to IS NOT NULL ) THEN
      lv_date_fromto := lv_date_fromto ||
                        SUBSTRB( ir_param.iv_creat_date_to, 1, 4) || gc_out_year  ||
                        SUBSTRB( ir_param.iv_creat_date_to, 6, 2) || gc_out_month ||
                        SUBSTRB( ir_param.iv_creat_date_to, 9, 2) || gc_out_day;
    END IF;
    insert_xml_plsql_table(iox_xml_data, 'date_fromto', lv_date_fromto, 
                                                        gc_tag_type_data, gc_tag_value_type_char);
    -- 担当部署
    insert_xml_plsql_table(iox_xml_data, 'department_code', gv_department_code, 
                                                        gc_tag_type_data, gc_tag_value_type_char);
    -- 担当者
    insert_xml_plsql_table(iox_xml_data, 'department_name', gv_department_name, 
                                                        gc_tag_type_data, gc_tag_value_type_char);
--
    -- -----------------------------------------------------
    -- 帳票Ｇデータ終了タグ
    -- -----------------------------------------------------
    insert_xml_plsql_table(iox_xml_data, '/report_info', NULL, gc_tag_type_tag, gc_tag_value_type_char);
--
    -- =====================================================
    -- 項目データ抽出・出力処理
    -- =====================================================
    <<main_data_loop>>
    FOR i IN 1..gt_main_data.COUNT LOOP
      -- =====================================================
      -- 入庫倉庫ブレイク
      -- =====================================================
      -- 入庫倉庫が切り替わったとき
      IF ( gt_main_data(i).location_code <> lv_loc_code ) THEN
        -- -----------------------------------------------------
        -- 入庫倉庫明細Ｇ終了タグ出力
        -- -----------------------------------------------------
        -- 最初のレコードのときは出力しない
        IF ( lv_loc_code <> lc_break_init ) THEN
          -- -----------------------------------------------------
          -- 区分明細Ｇ終了タグ出力
          -- -----------------------------------------------------
          insert_xml_plsql_table(iox_xml_data, '/g_il_dtl', NULL, gc_tag_type_tag, gc_tag_value_type_char);
          -- -----------------------------------------------------
          -- 入庫倉庫明細Ｇ終了タグ出力
          -- -----------------------------------------------------
          insert_xml_plsql_table(iox_xml_data, '/g_itemloc_dtl', NULL, gc_tag_type_tag, gc_tag_value_type_char);
        END IF;
        -- -----------------------------------------------------
        -- 入庫倉庫明細Ｇ開始タグ出力
        -- -----------------------------------------------------
        insert_xml_plsql_table(iox_xml_data, 'g_itemloc_dtl', NULL, gc_tag_type_tag, gc_tag_value_type_char);
        -- -----------------------------------------------------
        -- 入庫倉庫明細Ｇデータタグ出力
        -- -----------------------------------------------------
        -- 入庫倉庫コード
        insert_xml_plsql_table(iox_xml_data, 'location_code', SUBSTRB( gt_main_data(i).location_code, 1, 4 ),
                                                            gc_tag_type_data, gc_tag_value_type_char);
        -- 入庫倉庫先名
        insert_xml_plsql_table(iox_xml_data, 'location_name', SUBSTRB( gt_main_data(i).location_name, 1, 20 ),
                                                            gc_tag_type_data, gc_tag_value_type_char);
        -- -----------------------------------------------------
        -- 区分明細Ｇ開始タグ出力
        -- -----------------------------------------------------
        insert_xml_plsql_table(iox_xml_data, 'g_il_dtl', NULL, gc_tag_type_tag, gc_tag_value_type_char);
        -- -----------------------------------------------------
        -- 入庫倉庫ブレイクキー更新
        -- -----------------------------------------------------
        lv_loc_code := gt_main_data(i).location_code;
        -- -----------------------------------------------------
        -- 区分ブレイクキー更新
        -- -----------------------------------------------------
        lv_item_class := gt_main_data(i).item_class;
      END IF;
--
      -- =====================================================
      -- 区分ブレイク
      -- =====================================================
      -- 区分が切り替わったとき
      IF ( gt_main_data(i).item_class <> lv_item_class ) THEN
        -- -----------------------------------------------------
        -- 区分明細Ｇ終了タグ出力
        -- -----------------------------------------------------
        insert_xml_plsql_table(iox_xml_data, '/g_il_dtl', NULL, gc_tag_type_tag, gc_tag_value_type_char);
        -- -----------------------------------------------------
        -- 区分明細Ｇ開始タグ出力
        -- -----------------------------------------------------
        insert_xml_plsql_table(iox_xml_data, 'g_il_dtl', NULL, gc_tag_type_tag, gc_tag_value_type_char);
        -- -----------------------------------------------------
        -- 区分ブレイクキー更新
        -- -----------------------------------------------------
        lv_item_class := gt_main_data(i).item_class;
      END IF;
--
      -- -----------------------------------------------------
      -- 区分明細Ｇ開始タグ出力
      -- -----------------------------------------------------
      insert_xml_plsql_table(iox_xml_data, 'g_ic_dtl', NULL, gc_tag_type_tag, gc_tag_value_type_char);
      -- -----------------------------------------------------
      -- 区分明細Ｇデータタグ出力
      -- -----------------------------------------------------
      -- 区分
      insert_xml_plsql_table(iox_xml_data, 'item_class', gt_main_data(i).item_class, 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- 品目（コード）
      insert_xml_plsql_table(iox_xml_data, 'item_code', SUBSTRB( TO_CHAR( gt_main_data(i).item_code ), 1, 7 ),
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- 品目（名）
      insert_xml_plsql_table(iox_xml_data, 'item_name', gt_main_data(i).item_name, 
                                                          gc_tag_type_data, gc_tag_value_type_char);
--
      -- 数量
      insert_xml_plsql_table(iox_xml_data, 'quantity', TO_CHAR( gt_main_data(i).quantity ),
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- 在庫金額
      insert_xml_plsql_table(iox_xml_data, 'stock_amount', TO_CHAR( gt_main_data(i).stock_amount ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- 原料金額
      insert_xml_plsql_table(iox_xml_data, 'aracha_amount', TO_CHAR( gt_main_data(i).aracha_amount ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
--
      -- 集荷数量
      insert_xml_plsql_table(iox_xml_data, 'collect_quantity', TO_CHAR( gt_main_data(i).collect_quantity ),
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- 集荷金額
      insert_xml_plsql_table(iox_xml_data, 'collect_amount', TO_CHAR( gt_main_data(i).collect_amount ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
--
      -- 受入数量
      insert_xml_plsql_table(iox_xml_data, 'receive_quantity', TO_CHAR( gt_main_data(i).receive_quantity ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- 受入金額
      insert_xml_plsql_table(iox_xml_data, 'receive_amount', TO_CHAR( gt_main_data(i).receive_amount ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
--
      -- 出荷数量
      insert_xml_plsql_table(iox_xml_data, 'shipment_quantity', TO_CHAR( gt_main_data(i).shipment_quantity ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- 出荷金額
      insert_xml_plsql_table(iox_xml_data, 'shipment_amount', TO_CHAR( gt_main_data(i).shipment_amount ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
--
      -- 生葉合計数量
      insert_xml_plsql_table(iox_xml_data, 'nahama_total_quantity', TO_CHAR( gt_main_data(i).nahama_total_quantity),
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- 生葉合計金額
      insert_xml_plsql_table(iox_xml_data, 'namaha_total_amount', TO_CHAR( gt_main_data(i).namaha_total_amount ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- -----------------------------------------------------
      -- 区分明細Ｇ終了タグ出力
      -- -----------------------------------------------------
      insert_xml_plsql_table(iox_xml_data, '/g_ic_dtl', NULL, gc_tag_type_tag, gc_tag_value_type_char);
--
    END LOOP main_data_loop ;
--
    -- =====================================================
    -- 終了処理
    -- =====================================================
    -- -----------------------------------------------------
    -- 区分明細Ｇ終了タグ出力
    -- -----------------------------------------------------
    insert_xml_plsql_table(iox_xml_data, '/g_il_dtl', NULL, gc_tag_type_tag, gc_tag_value_type_char);
    -- -----------------------------------------------------
    -- 入庫倉庫明細Ｇ終了タグ出力
    -- -----------------------------------------------------
    insert_xml_plsql_table(iox_xml_data, '/g_itemloc_dtl', NULL, gc_tag_type_tag, gc_tag_value_type_char);
    -- -----------------------------------------------------
    -- 倉庫Ｇ終了タグ出力
    -- -----------------------------------------------------
    insert_xml_plsql_table(iox_xml_data, '/g_itemloc',            NULL, gc_tag_type_tag, gc_tag_value_type_char);
    insert_xml_plsql_table(iox_xml_data, '/lg_itemlocation_info', NULL, gc_tag_type_tag, gc_tag_value_type_char);
    -- -----------------------------------------------------
    -- データＧ終了タグ
    -- -----------------------------------------------------
    insert_xml_plsql_table(iox_xml_data, '/data_info', NULL, gc_tag_type_tag, gc_tag_value_type_char);
    insert_xml_plsql_table(iox_xml_data, '/root', NULL, gc_tag_type_tag, gc_tag_value_type_char);
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
  PROCEDURE submain
    (
      iv_report_type        IN     VARCHAR2         --   01 : 帳票種別
     ,iv_creat_date_from    IN     VARCHAR2         --   02 : 製造期間FROM
     ,iv_creat_date_to      IN     VARCHAR2         --   03 : 製造期間TO
     ,ov_errbuf            OUT     VARCHAR2         -- エラー・メッセージ           --# 固定 #
     ,ov_retcode           OUT     VARCHAR2         -- リターン・コード             --# 固定 #
     ,ov_errmsg            OUT     VARCHAR2         -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ======================================================
    -- 固定ローカル定数
    -- ======================================================
    cv_prg_name CONSTANT VARCHAR2(100) := 'submain' ; -- プログラム名
    -- ======================================================
    -- ローカル変数
    -- ======================================================
    lv_errbuf   VARCHAR2(5000) ;                      --   エラー・メッセージ
    lv_retcode  VARCHAR2(1) ;                         --   リターン・コード
    lv_errmsg   VARCHAR2(5000) ;                      --   ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ======================================================
    -- ユーザー宣言部
    -- ======================================================
    -- *** ローカル変数 ***
    lr_param_rec     rec_param_data ;          -- パラメータ受渡し用
--
    xml_data_table   XML_DATA;
    lv_xml_string    VARCHAR2(32000) ;
    ln_retcode       NUMBER ;
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
    gd_exec_date                    := SYSDATE ;               -- 実施日
    -- パラメータ格納
    lr_param_rec.iv_report_type     := iv_report_type ;        -- 帳票種別
    lr_param_rec.iv_creat_date_from := iv_creat_date_from ;    -- 製造期間FROM
    lr_param_rec.iv_creat_date_to   := iv_creat_date_to ;      -- 製造期間TO
    -- 最大日付設定
    gd_max_date                     := FND_DATE.STRING_TO_DATE( gc_max_date_d, gc_char_d_format );
--
    -- =====================================================
    -- 前処理(C-2)
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
    -- =====================================================
    -- 帳票データ出力(C-3,4)
    -- =====================================================
    prc_create_xml_data
      (
        xml_data_table
       ,ir_param          => lr_param_rec       -- 入力パラメータレコード
       ,ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ==================================================
    -- ＸＭＬ出力(C-4)
    -- ==================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
    -- --------------------------------------------------
    -- 抽出データが０件の場合
    -- --------------------------------------------------
    IF  ( lv_errmsg IS NOT NULL )
    AND ( lv_retcode = gv_status_warn ) THEN
      -- ０件メッセージ出力
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  <data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <lg_itemlocation_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      <g_itemloc>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <report_title>' || gc_report_title || '</report_title>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <g_itemloc_dtl>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          <msg>'        || lv_errmsg       || '</msg>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        </g_itemloc_dtl>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      </g_itemloc>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    </lg_itemlocation_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  </data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
    -- --------------------------------------------------
    -- 帳票データが出力できた場合
    -- --------------------------------------------------
    ELSE
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
--
    END IF ;
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
  PROCEDURE main
    (
      errbuf                OUT    VARCHAR2         -- エラーメッセージ
     ,retcode               OUT    VARCHAR2         -- エラーコード
     ,iv_report_type        IN     VARCHAR2         -- 01 : 帳票種別
     ,iv_creat_date_from    IN     VARCHAR2         -- 02 : 製造期間FROM
     ,iv_creat_date_to      IN     VARCHAR2         -- 03 : 製造期間TO
    )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ======================================================
    -- 固定ローカル定数
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'main' ; -- プログラム名
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
        iv_report_type     => iv_report_type      -- 01 : 帳票種別
       ,iv_creat_date_from => iv_creat_date_from  -- 02 : 製造期間FROM
       ,iv_creat_date_to   => iv_creat_date_to    -- 03 : 製造期間TO
       ,ov_errbuf          => lv_errbuf           -- エラー・メッセージ           --# 固定 #
       ,ov_retcode         => lv_retcode          -- リターン・コード             --# 固定 #
       ,ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
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
END xxpo710002c ;
/