CREATE OR REPLACE PACKAGE BODY xxpo710001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2007. All rights reserved.
 *
 * Package Name     : xxpo710001c(body)
 * Description      : 生産物流（仕入）
 * MD.050/070       : 生産物流（仕入）Issue1.0  (T_MD050_BPO_710)
 *                    荒茶製造表                (T_MD070_BPO_71B)
 * Version          : 1.4
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  convert_into_xml          XMLデータ変換
 *  insert_xml_plsql_table    XMLデータ格納
 *  prc_initialize            前処理(B-2)
 *  prc_get_report_data       明細データ取得(B-3)
 *  prc_create_xml_data       ＸＭＬデータ作成(B-4)
 *  submain                   メイン処理プロシージャ
 *  main                      コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ------------------ -------------------------------------------------
 *  Date          Ver.  Editor             Description
 * ------------- ----- ------------------ -------------------------------------------------
 *  2007/12/28    1.0   Yasuhisa Yamamoto  新規作成
 *  2008/05/02    1.1   Yasuhisa Yamamoto  結合テスト障害対応(710_10)
 *  2008/05/19    1.2   Masayuki Ikeda     内部変更要求#62対応
 *  2008/05/20    1.3   Yohei    Takayama  結合テスト障害対応(710_11)
 *  2008/07/02    1.4   Satoshi Yunba      禁則文字「'」「"」「<」「>」「&」対応
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
  gv_pkg_name                  CONSTANT VARCHAR2(20)  := 'xxpo710001c' ;      -- パッケージ名
  gc_report_id                 CONSTANT VARCHAR2(12)  := 'XXPO710001T';       -- 帳票ID
  gc_report_title_kari         CONSTANT VARCHAR2(20)  := '（仮）荒茶製造表' ; -- 帳票タイトル（帳票種別：1）
  gc_report_title              CONSTANT VARCHAR2(20)  := '荒茶製造表' ;       -- 帳票タイトル（帳票種別：2）
  gc_report_type_1             CONSTANT VARCHAR2(1)   := '1' ;                -- 帳票種別（1：仮単価使用）
  gc_report_type_2             CONSTANT VARCHAR2(1)   := '2' ;                -- 帳票種別（2：正単価使用）
  gc_tag_type_tag              CONSTANT VARCHAR2(1)   := 'T' ;                -- 出力タグタイプ（T：タグ）
  gc_tag_type_data             CONSTANT VARCHAR2(1)   := 'D' ;                -- 出力タグタイプ（D：データ）
  gc_tag_value_type_char       CONSTANT VARCHAR2(1)   := 'C' ;                -- 出力タイプ（C：Char）
--
  ------------------------------
  -- クイックコード関連
  ------------------------------
  gc_final_unit_price_entered  CONSTANT VARCHAR2(1)   := 'Y' ;
--
  ------------------------------
  -- エラーメッセージ関連
  ------------------------------
  gc_application_cmn           CONSTANT VARCHAR2(5)   := 'XXCMN' ;            -- アプリケーション（XXCMN）
  gc_application_po            CONSTANT VARCHAR2(5)   := 'XXPO' ;             -- アプリケーション（XXPO）
  gc_xxpo_00036                CONSTANT VARCHAR2(14)  := 'APP-XXPO-00036' ;   -- 担当部署名未取得メッセージ
  gc_xxpo_00026                CONSTANT VARCHAR2(14)  := 'APP-XXPO-00026' ;   -- 担当者名未取得メッセージ
  gc_xxpo_00033                CONSTANT VARCHAR2(14)  := 'APP-XXPO-00033' ;   -- データ未取得メッセージ
  gc_xxcmn_10122               CONSTANT VARCHAR2(15)  := 'APP-XXCMN-10122' ;  -- 明細0件用メッセージ

  ------------------------------
  -- 項目編集関連
  ------------------------------
  gc_char_d_format             CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD' ;
  gc_char_dt_format            CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS' ;
  gc_max_date_d                CONSTANT VARCHAR2(10)  := '4712/12/31';
  gc_min_date_d                CONSTANT VARCHAR2(10)  := '1900/01/01';
  gc_max_date_dt               CONSTANT VARCHAR2(19)  := '4712/12/31 23:59:59';
  gc_min_date_dt               CONSTANT VARCHAR2(19)  := '1900/01/01 00:00:00';
-- S 2008/05/16 1.2 MOD BY M.Ikeda ------------------------------------------------------------ S --
  gc_max_date                  CONSTANT DATE  := FND_DATE.CANONICAL_TO_DATE( '4712/12/31' ) ;
  gc_min_date                  CONSTANT DATE  := FND_DATE.CANONICAL_TO_DATE( '1900/01/01' ) ;
-- E 2008/05/16 1.2 MOD BY M.Ikeda ------------------------------------------------------------ E --
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 入力パラメータ格納用レコード変数
  TYPE rec_param_data  IS RECORD 
    (
      iv_report_type      fnd_lookup_values.lookup_code%TYPE          --   01 : 帳票種別
     ,iv_creat_date_from  VARCHAR2(10)                                --   02 : 製造期間FROM
     ,iv_creat_date_to    VARCHAR2(10)                                --   03 : 製造期間TO
     ,iv_entry_num        xxpo_namaha_prod_txns.entry_number%TYPE     --   04 : 伝票NO
     ,iv_item_code        xxpo_namaha_prod_txns.aracha_item_code%TYPE --   05 : 仕上品目
     ,iv_department_code  xxpo_namaha_prod_txns.department_code%TYPE  --   06 : 入力部署
     ,iv_employee_number  per_all_people_f.employee_number%TYPE       --   07 : 入力担当者
     ,iv_input_date_from  VARCHAR2(19)                                --   08 : 入力期間FROM
     ,iv_input_date_to    VARCHAR2(19)                                --   09 : 入力期間TO
    ) ;
--
  -- 荒茶製造表データ格納用レコード変数
  TYPE rec_data_type_dtl  IS RECORD 
    (
     report_title           VARCHAR2(16)                                         -- 帳票タイトル
    ,entry_number           xxpo_namaha_prod_txns.entry_number%TYPE              -- 伝票No
    ,item_no                xxcmn_item_mst_v.item_no%TYPE                        -- 品目（コード）
    ,item_short_name        xxcmn_item_mst_v.item_short_name%TYPE                -- 品目（名）
    ,lot_no                 ic_lots_mst.lot_no%TYPE                              -- ロットNo
    ,creation_date          ic_lots_mst.attribute1%TYPE                          -- 製造日
    ,location_code          xxpo_namaha_prod_txns.location_code%TYPE             -- 入庫先コード
    ,description            xxpo_namaha_prod_txns.description%TYPE               -- 備考
    ,collect1_quantity      xxpo_namaha_prod_txns.collect1_quantity%TYPE         -- 集荷１：数量
    ,collect1_unit_price    xxpo_namaha_prod_txns.collect1_final_unit_price%TYPE -- 集荷１：単価
    ,collect2_quantity      xxpo_namaha_prod_txns.collect2_quantity%TYPE         -- 集荷２：数量
    ,collect2_unit_price    xxpo_namaha_prod_txns.collect2_final_unit_price%TYPE -- 集荷２：単価
    ,receive1_quantity      xxpo_namaha_prod_txns.receive1_quantity%TYPE         -- 受入１：数量
    ,receive1_unit_price    xxpo_namaha_prod_txns.receive1_final_unit_price%TYPE -- 受入１：単価
    ,receive2_quantity      xxpo_namaha_prod_txns.receive2_quantity%TYPE         -- 受入２：数量
    ,receive2_unit_price    xxpo_namaha_prod_txns.receive2_final_unit_price%TYPE -- 受入２：単価
    ,shipment_quantity      xxpo_namaha_prod_txns.shipment_quantity%TYPE         -- 出荷：数量
    ,shipment_unit_price    xxpo_namaha_prod_txns.shipment_final_unit_price%TYPE -- 出荷：単価
    ,byproduct1_item_code   xxcmn_item_mst_v.item_no%TYPE                        -- 副産物１：品目コード
    ,byproduct1_item_name   xxcmn_item_mst_v.item_short_name%TYPE                -- 副産物１：品目名
    ,byproduct1_lot_num     xxpo_namaha_prod_txns.byproduct1_lot_number%TYPE     -- 副産物１：ロットNo
    ,byproduct1_quantity    xxpo_namaha_prod_txns.byproduct1_quantity%TYPE       -- 副産物１：数量
    ,byproduct1_unit_price  NUMBER                                               -- 副産物１：単価
    ,byproduct2_item_code   xxcmn_item_mst_v.item_no%TYPE                        -- 副産物２：品目コード
    ,byproduct2_item_name   xxcmn_item_mst_v.item_short_name%TYPE                -- 副産物２：品目名
    ,byproduct2_lot_num     xxpo_namaha_prod_txns.byproduct2_lot_number%TYPE     -- 副産物２：ロットNo
    ,byproduct2_quantity    xxpo_namaha_prod_txns.byproduct2_quantity%TYPE       -- 副産物２：数量
    ,byproduct2_unit_price  NUMBER                                               -- 副産物２：単価
    ,byproduct3_item_code   xxcmn_item_mst_v.item_no%TYPE                        -- 副産物３：品目コード
    ,byproduct3_item_name   xxcmn_item_mst_v.item_short_name%TYPE                -- 副産物３：品目名
    ,byproduct3_lot_num     xxpo_namaha_prod_txns.byproduct3_lot_number%TYPE     -- 副産物３：ロットNo
    ,byproduct3_quantity    xxpo_namaha_prod_txns.byproduct3_quantity%TYPE       -- 副産物３：数量
    ,byproduct3_unit_price  NUMBER                                               -- 副産物３：単価
    ,aracha_quantity        xxpo_namaha_prod_txns.aracha_quantity%TYPE           -- 荒茶原料合計：数量
    ,processing_unit_price  xxpo_namaha_prod_txns.processing_unit_price%TYPE     -- 加工単価
    ,syanai_unit_price      NUMBER                                               -- 社内単価
    ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  ------------------------------
  -- ＸＭＬ用
  ------------------------------
  gd_exec_date              DATE ;               -- 実施日
  gv_department_code        VARCHAR2(10) ;       -- 担当部署
  gv_department_name        VARCHAR2(14) ;       -- 担当者
--
  gt_main_data              tab_data_type_dtl ;  -- 取得レコード表
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
   * Description      : 前処理(B-2)
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
-- 08/05/20 Y.Takayama DEL v1.3 Start
--    IF ( gv_department_code IS NULL ) THEN
--      lv_err_code := gc_xxpo_00036 ;
--      RAISE get_value_expt ;
--    END IF ;
-- 08/05/20 Y.Takayama DEL v1.3 End
--
    -- ====================================================
    -- 担当者取得
    -- ====================================================
    gv_department_name := SUBSTRB( xxcmn_common_pkg.get_user_name( FND_GLOBAL.USER_ID ), 1, 14 ) ;
-- 08/05/20 Y.Takayama DEL v1.3 Start
--    IF ( gv_department_name IS NULL ) THEN
--      lv_err_code := gc_xxpo_00026 ;
--      RAISE get_value_expt ;
--    END IF ;
-- 08/05/20 Y.Takayama DEL v1.3 End
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
   * Description      : 明細データ取得(B-3)
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
       ,in_entry_num        xxpo_namaha_prod_txns.entry_number%TYPE
       ,in_item_code        xxpo_namaha_prod_txns.aracha_item_code%TYPE
       ,in_department_code  xxpo_namaha_prod_txns.department_code%TYPE
       ,in_employee_number  per_all_people_f.employee_number%TYPE
       ,in_input_date_from  VARCHAR2
       ,in_input_date_to    VARCHAR2
      )
    IS
      SELECT CASE
              WHEN ( in_report_type = gc_report_type_1 ) THEN gc_report_title_kari
              WHEN ( in_report_type = gc_report_type_2 ) THEN gc_report_title
             END                           report_title          -- 帳票タイトル
            ,xnpt.entry_number          AS entry_number          -- 伝票No
            ,ximv.item_no               AS item_no               -- 品目（コード）
            ,ximv.item_short_name       AS item_short_name       -- 品目（名）
            ,ilm.lot_no                 AS lot_no                -- ロットNo
            ,ilm.attribute1             AS creation_date         -- 製造日
            ,xnpt.location_code         AS location_code         -- 入庫先コード
            ,xnpt.description           AS description           -- 備考
            ,xnpt.collect1_quantity     AS collect1_quantity     -- 集荷１：数量
            ,CASE
              WHEN ( in_report_type = gc_report_type_1 ) THEN xnpt.collect1_temp_unit_price
              WHEN ( in_report_type = gc_report_type_2 ) THEN xnpt.collect1_final_unit_price
             END                           collect1_unit_price   -- 集荷１：単価
            ,xnpt.collect2_quantity     AS collect2_quantity     -- 集荷２：数量
            ,CASE
              WHEN ( in_report_type = gc_report_type_1 ) THEN xnpt.collect2_temp_unit_price
              WHEN ( in_report_type = gc_report_type_2 ) THEN xnpt.collect2_final_unit_price
             END                           collect2_unit_price   -- 集荷２：単価
            ,xnpt.receive1_quantity     AS receive1_quantity     -- 受入１：数量
            ,CASE
              WHEN ( in_report_type = gc_report_type_1 ) THEN xnpt.receive1_temp_unit_price
              WHEN ( in_report_type = gc_report_type_2 ) THEN xnpt.receive1_final_unit_price
             END                           receive1_unit_price   -- 受入１：単価
            ,xnpt.receive2_quantity     AS receive2_quantity     -- 受入２：数量
            ,CASE
              WHEN ( in_report_type = gc_report_type_1 ) THEN xnpt.receive2_temp_unit_price
              WHEN ( in_report_type = gc_report_type_2 ) THEN xnpt.receive2_final_unit_price
             END                           receive2_unit_price   -- 受入２：単価
            ,xnpt.shipment_quantity     AS shipment_quantity     -- 出荷：数量
            ,CASE
              WHEN ( in_report_type = gc_report_type_1 ) THEN xnpt.shipment_temp_unit_price
              WHEN ( in_report_type = gc_report_type_2 ) THEN xnpt.shipment_final_unit_price
             END                           shipment_unit_price   -- 出荷：単価
            ,ximv_by1.item_no           AS byproduct1_item_code  -- 副産物１：品目コード
            ,ximv_by1.item_short_name   AS byproduct1_item_name  -- 副産物１：品目名
            ,xnpt.byproduct1_lot_number AS byproduct1_lot_num    -- 副産物１：ロットNo
            ,xnpt.byproduct1_quantity   AS byproduct1_quantity   -- 副産物１：数量
            ,ilm_by1.attribute7         AS byproduct1_unit_price -- 副産物１：単価
            ,ximv_by2.item_no           AS byproduct2_item_code  -- 副産物２：品目コード
            ,ximv_by2.item_short_name   AS byproduct2_item_name  -- 副産物２：品目名
            ,xnpt.byproduct2_lot_number AS byproduct2_lot_num    -- 副産物２：ロットNo
            ,xnpt.byproduct2_quantity   AS byproduct2_quantity   -- 副産物２：数量
            ,ilm_by2.attribute7         AS byproduct2_unit_price -- 副産物２：単価
            ,ximv_by3.item_no           AS byproduct3_item_code  -- 副産物３：品目コード
            ,ximv_by3.item_short_name   AS byproduct3_item_name  -- 副産物３：品目名
            ,xnpt.byproduct3_lot_number AS byproduct3_lot_num    -- 副産物３：ロットNo
            ,xnpt.byproduct3_quantity   AS byproduct3_quantity   -- 副産物３：数量
            ,ilm_by3.attribute7         AS byproduct3_unit_price -- 副産物３：単価
            ,xnpt.aracha_quantity       AS aracha_quantity       -- 荒茶原料合計：数量
            ,xnpt.processing_unit_price AS processing_unit_price -- 加工単価
            ,TO_NUMBER( NVL( ilm.attribute7, '0' ) )
                                        AS syanai_unit_price     -- 社内単価
      FROM   xxpo_namaha_prod_txns      xnpt                     -- 生葉実績（アドオン）
            ,ic_lots_mst                ilm                      -- OPMロットマスタ
            ,xxcmn_item_mst2_v          ximv                     -- OPM品目情報VIEW2
            ,ic_lots_mst                ilm_by1                  -- OPMロットマスタ（副産物１）
            ,xxcmn_item_mst2_v          ximv_by1                 -- OPM品目情報VIEW2（副産物１）
            ,ic_lots_mst                ilm_by2                  -- OPMロットマスタ（副産物２）
            ,xxcmn_item_mst2_v          ximv_by2                 -- OPM品目情報VIEW2（副産物２）
            ,ic_lots_mst                ilm_by3                  -- OPMロットマスタ（副産物３）
            ,xxcmn_item_mst2_v          ximv_by3                 -- OPM品目情報VIEW2（副産物３）
            ,fnd_user                   fu                       -- ユーザマスタ
            ,per_all_people_f           papf                     -- 従業員マスタ
      ---------------------------------------------------------------------------------------------
      -- 結合条件
      WHERE xnpt.aracha_item_id     = ilm.item_id
      AND   xnpt.aracha_lot_id      = ilm.lot_id
      AND   xnpt.aracha_item_id     = ximv.item_id
-- S 2008/05/16 1.2 MOD BY M.Ikeda ------------------------------------------------------------ S --
--      AND   ilm.attribute1          BETWEEN TO_CHAR( ximv.start_date_active , gc_char_d_format)
--                                    AND     NVL( TO_CHAR( ximv.end_date_active, gc_char_d_format), gc_max_date_d )
      AND   FND_DATE.CANONICAL_TO_DATE( ilm.attribute1 )
              BETWEEN ximv.start_date_active AND NVL( ximv.end_date_active, gc_max_date )
-- E 2008/05/16 1.2 MOD BY M.Ikeda ------------------------------------------------------------ E --
      AND   xnpt.byproduct1_item_id = ilm_by1.item_id(+)
      AND   xnpt.byproduct1_lot_id  = ilm_by1.lot_id(+)
      AND   xnpt.byproduct1_item_id = ximv_by1.item_id(+)
      AND   (  ilm_by1.attribute1   IS NULL
            OR ilm_by1.attribute1   BETWEEN TO_CHAR( ximv_by1.start_date_active , gc_char_d_format)
                                    AND NVL( TO_CHAR( ximv_by1.end_date_active, gc_char_d_format), gc_max_date_d) )
      AND   xnpt.byproduct2_item_id = ilm_by2.item_id(+)
      AND   xnpt.byproduct2_lot_id  = ilm_by2.lot_id(+)
      AND   xnpt.byproduct2_item_id = ximv_by2.item_id(+)
      AND   (  ilm_by2.attribute1   IS NULL
            OR ilm_by2.attribute1   BETWEEN TO_CHAR( ximv_by2.start_date_active , gc_char_d_format)
                                    AND NVL( TO_CHAR( ximv_by2.end_date_active, gc_char_d_format), gc_max_date_d) )
      AND   xnpt.byproduct3_item_id = ilm_by3.item_id(+)
      AND   xnpt.byproduct3_lot_id  = ilm_by3.lot_id(+)
      AND   xnpt.byproduct3_item_id = ximv_by3.item_id(+)
      AND   (  ilm_by3.attribute1   IS NULL
            OR ilm_by3.attribute1   BETWEEN TO_CHAR( ximv_by3.start_date_active , gc_char_d_format)
                                    AND NVL( TO_CHAR( ximv_by3.end_date_active, gc_char_d_format), gc_max_date_d) )
      AND   xnpt.created_by         = fu.user_id
      AND   fu.employee_id          = papf.person_id
      ---------------------------------------------------------------------------------------------
      -- 抽出条件
      AND   (
              (   in_report_type                    = gc_report_type_2                -- 帳票種別：2のとき
              AND xnpt.final_unit_price_entered_flg = gc_final_unit_price_entered )   -- 正単価入力完了フラグ＝'Y'
            OR
              ( in_report_type    = gc_report_type_1 )                                -- 帳票種別：1のとき
            )
-- S 2008/05/16 1.2 MOD BY M.Ikeda ------------------------------------------------------------ S --
--      AND   ilm.attribute1 BETWEEN NVL( in_creat_date_from, gc_min_date_d )  -- パラメータの製造日で
--                           AND     NVL( in_creat_date_to  , gc_max_date_d )  -- 有効なデータ
      AND   FND_DATE.CANONICAL_TO_DATE( ilm.attribute1 )
              BETWEEN NVL( FND_DATE.CANONICAL_TO_DATE( in_creat_date_from ), gc_min_date )  -- パラメータの製造日で
              AND     NVL( FND_DATE.CANONICAL_TO_DATE( in_creat_date_to   ), gc_max_date )  -- 有効なデータ
-- E 2008/05/16 1.2 MOD BY M.Ikeda ------------------------------------------------------------ E --
      AND   xnpt.aracha_quantity    > 0                               -- 数量0は取消しされたデータの為、除外
      AND   (  in_entry_num         IS NULL                           -- 伝票No＝指定の伝票No
            OR xnpt.entry_number    = in_entry_num )                  -- 
      AND   (  in_item_code         IS NULL                           -- 荒茶品目コード＝指定の仕上品目
            OR xnpt.aracha_item_code = in_item_code )                 -- 
      AND   (  in_department_code   IS NULL                           -- 部署コード＝指定の入力部署
            OR xnpt.department_code = in_department_code )            -- 
      AND   (  in_employee_number   IS NULL                           -- 従業員番号＝指定の入力担当者
            OR papf.employee_number = in_employee_number )            -- 
      AND   xnpt.creation_date
              BETWEEN FND_DATE.CANONICAL_TO_DATE( in_input_date_from ) -- パラメータの入力期間で
              AND     NVL( FND_DATE.CANONICAL_TO_DATE( in_input_date_to ), gc_max_date ) -- 有効なデータ
      ORDER BY TO_NUMBER( xnpt.entry_number )    -- 伝票No
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
       ,ir_param.iv_entry_num           -- 伝票NO
       ,ir_param.iv_item_code           -- 仕上品目
       ,ir_param.iv_department_code     -- 入力部署
       ,ir_param.iv_employee_number     -- 入力担当者
       ,ir_param.iv_input_date_from     -- 入力期間FROM
       ,ir_param.iv_input_date_to       -- 入力期間TO
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
   * Description      : ＸＭＬデータ作成(B-4)
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
    -- 金額計算用
    ln_collect1_amount           NUMBER := 0 ;           -- 集荷１：金額
    ln_collect2_amount           NUMBER := 0 ;           -- 集荷２：金額
    ln_receive1_amount           NUMBER := 0 ;           -- 受入１：金額
    ln_receive2_amount           NUMBER := 0 ;           -- 受入２：金額
    ln_shipment_amount           NUMBER := 0 ;           -- 出荷：金額
    ln_total_quantity            NUMBER := 0 ;           -- 生葉合計：数量
    ln_total_amount              NUMBER := 0 ;           -- 生葉合計：金額
    ln_byproduct1_amount         NUMBER := 0 ;           -- 副産物１：金額
    ln_byproduct2_amount         NUMBER := 0 ;           -- 副産物２：金額
    ln_byproduct3_amount         NUMBER := 0 ;           -- 副産物３：金額
    ln_byproduct_total_quantity  NUMBER := 0 ;           -- 副産物合計：数量
    ln_byproduct_total_amount    NUMBER := 0 ;           -- 副産物合計：金額
    ln_aracha_unit_price         NUMBER := 0 ;           -- 荒茶原料合計：単価
    ln_aracha_amount             NUMBER := 0 ;           -- 荒茶原料合計：金額
    ln_budomari                  NUMBER := 0 ;           -- 歩留
    ln_amount                    NUMBER := 0 ;           -- 社内振替（荒茶）：金額
    ln_receive_total_quantity    NUMBER := 0 ;           -- 受入合計：数量
    ln_receive_total_amount      NUMBER := 0 ;           -- 受入合計：金額
-- 08/05/02 Y.Yamamoto ADD v1.1 Start
    ln_syanai_unit_price         NUMBER := 0 ;           -- 社内単価
-- 08/05/02 Y.Yamamoto ADD v1.1 End
--
    -- 入庫倉庫取得用
    lv_location_name             xxcmn_item_locations_v.description%TYPE ; -- 入庫倉庫
--
    -- *** ローカル・例外処理 ***
    no_data_expt                 EXCEPTION ;             -- 取得レコードなし
--
  BEGIN
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
    -- 伝票Ｇ開始タグ出力
    -- -----------------------------------------------------
    insert_xml_plsql_table(iox_xml_data, 'lg_entry_info', NULL, gc_tag_type_tag, gc_tag_value_type_char);
--
    -- =====================================================
    -- 項目データ抽出・出力処理
    -- =====================================================
    <<main_data_loop>>
    FOR i IN 1..gt_main_data.COUNT LOOP
      -- -----------------------------------------------------
      -- 入庫倉庫の取得
      -- -----------------------------------------------------
      BEGIN
        SELECT SUBSTRB( xilv.description, 1, 20 )
        INTO   lv_location_name
        FROM   xxcmn_item_locations2_v xilv
        WHERE  xilv.segment1 = gt_main_data(i).location_code
        AND    gt_main_data(i).creation_date BETWEEN TO_CHAR( xilv.date_from , gc_char_d_format)
                                             AND     NVL( TO_CHAR( xilv.date_to, gc_char_d_format), gc_max_date_d)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_location_name := NULL ;
      END ;
      -- -----------------------------------------------------
      -- 計算項目の算出
      -- -----------------------------------------------------
      -- 個別計算項目
-- 08/05/02 Y.Yamamoto Update v1.1 Start 計算に使用する各項目について、NVLをかけるように修正する。
      ln_collect1_amount          := ROUND( NVL( gt_main_data(i).collect1_quantity, 0 ) 
                                            * NVL( gt_main_data(i).collect1_unit_price, 0 ) ) ;
      ln_collect2_amount          := ROUND( NVL( gt_main_data(i).collect2_quantity, 0 ) 
                                            * NVL( gt_main_data(i).collect2_unit_price, 0 ) ) ;
      ln_receive1_amount          := ROUND( NVL( gt_main_data(i).receive1_quantity, 0 ) 
                                            * NVL( gt_main_data(i).receive1_unit_price, 0 ) ) ;
      ln_receive2_amount          := ROUND( NVL( gt_main_data(i).receive2_quantity, 0 ) 
                                            * NVL( gt_main_data(i).receive2_unit_price, 0 ) ) ;
      ln_shipment_amount          := ROUND( NVL( gt_main_data(i).shipment_quantity, 0 ) 
                                            * NVL( gt_main_data(i).shipment_unit_price, 0 ) ) ;
--
      ln_total_quantity           := ( NVL( gt_main_data(i).collect1_quantity, 0 ) 
                                       + NVL( gt_main_data(i).collect2_quantity, 0 ) ) 
                                    + ( NVL( gt_main_data(i).receive1_quantity, 0 ) 
                                        + NVL( gt_main_data(i).receive2_quantity, 0 ) ) 
                                    -   NVL( gt_main_data(i).shipment_quantity, 0 ) ;
--
      ln_total_amount             := ( ln_collect1_amount + ln_collect2_amount ) 
                                     + ( ln_receive1_amount + ln_receive2_amount ) 
                                     -   ln_shipment_amount ;
--
      ln_byproduct1_amount        := ROUND( NVL( gt_main_data(i).byproduct1_quantity, 0 ) 
                                            * NVL( gt_main_data(i).byproduct1_unit_price, 0 ) ) ;
      ln_byproduct2_amount        := ROUND( NVL( gt_main_data(i).byproduct2_quantity, 0 ) 
                                            * NVL( gt_main_data(i).byproduct2_unit_price, 0 ) ) ;
      ln_byproduct3_amount        := ROUND( NVL( gt_main_data(i).byproduct3_quantity, 0 ) 
                                            * NVL( gt_main_data(i).byproduct3_unit_price, 0 ) ) ;
--
      ln_byproduct_total_quantity := NVL( gt_main_data(i).byproduct1_quantity, 0 ) 
                                     + NVL( gt_main_data(i).byproduct2_quantity, 0 ) 
                                     + NVL( gt_main_data(i).byproduct3_quantity, 0 ) ;
      ln_byproduct_total_amount   := ln_byproduct1_amount + ln_byproduct2_amount + ln_byproduct3_amount ;
--
      ln_aracha_amount            := ln_total_amount - ln_byproduct_total_amount ;
      ln_aracha_unit_price        := ROUND( ln_aracha_amount  / NVL( gt_main_data(i).aracha_quantity, 0 ), 2 ) ;
      ln_budomari                 := ROUND( ln_total_quantity / NVL( gt_main_data(i).aracha_quantity, 0 ), 2 ) ;
-- 08/05/02 Y.Yamamoto ADD v1.1 Start
      ln_syanai_unit_price        := ln_aracha_unit_price + NVL( gt_main_data(i).processing_unit_price, 0 ) ;
-- 08/05/02 Y.Yamamoto ADD v1.1 End
-- 08/05/02 Y.Yamamoto Update v1.1 Start
--      ln_amount                   := ROUND( gt_main_data(i).aracha_quantity
--                                            * ( gt_main_data(i).processing_unit_price + ln_aracha_unit_price ) ) ;
      ln_amount                   := ROUND( NVL( gt_main_data(i).aracha_quantity, 0 ) * ln_syanai_unit_price ) ;
-- 08/05/02 Y.Yamamoto Update v1.1 End
      ln_receive_total_quantity   := NVL( gt_main_data(i).aracha_quantity, 0 ) + ln_byproduct_total_quantity ;
      ln_receive_total_amount     := ln_amount + ln_byproduct_total_amount ;
--
-- 08/05/02 Y.Yamamoto Update v1.1 End
      -- -----------------------------------------------------
      -- 明細Ｇ開始タグ出力
      -- -----------------------------------------------------
      insert_xml_plsql_table(iox_xml_data, 'g_entry', NULL, gc_tag_type_tag, gc_tag_value_type_char);
      -- -----------------------------------------------------
      -- 明細Ｇデータタグ出力
      -- -----------------------------------------------------
      -- 帳票タイトル
      insert_xml_plsql_table(iox_xml_data, 'report_title', gt_main_data(i).report_title, 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- 帳票ＩＤ
      insert_xml_plsql_table(iox_xml_data, 'report_id', gc_report_id, 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- 伝票No
      insert_xml_plsql_table(iox_xml_data, 'entry_num', gt_main_data(i).entry_number, 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- 実施日
      insert_xml_plsql_table(iox_xml_data, 'exec_date', TO_CHAR( gd_exec_date, gc_char_dt_format ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
--
      -- 品目（コード）
      insert_xml_plsql_table(iox_xml_data, 'item_code', SUBSTRB( TO_CHAR( gt_main_data(i).item_no ), 1, 7 ),
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- 品目（名）
      insert_xml_plsql_table(iox_xml_data, 'item_name', gt_main_data(i).item_short_name, 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- ロットNo
      insert_xml_plsql_table(iox_xml_data, 'lot_num', SUBSTRB( gt_main_data(i).lot_no, 1, 10 ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- 担当部署
      insert_xml_plsql_table(iox_xml_data, 'department_code', gv_department_code, 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- 担当者
      insert_xml_plsql_table(iox_xml_data, 'department_name', gv_department_name, 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- 製造日
      insert_xml_plsql_table(iox_xml_data, 'creation_date', SUBSTRB( gt_main_data(i).creation_date, 1, 10 ),
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- 入庫倉庫
      insert_xml_plsql_table(iox_xml_data, 'location_name', lv_location_name, 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- 備考
      insert_xml_plsql_table(iox_xml_data, 'description', SUBSTRB( gt_main_data(i).description, 1, 50 ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
--
      ------------------------------
      -- 明細ＬＧ開始タグ
      ------------------------------
      insert_xml_plsql_table(iox_xml_data, 'g_entry_dtl', NULL, gc_tag_type_tag, gc_tag_value_type_char);
--
      -- -----------------------------------------------------
      -- 明細ＬＧデータタグ出力
      -- -----------------------------------------------------
      -- 集荷１：数量
      insert_xml_plsql_table(iox_xml_data, 'collect1_quantity', TO_CHAR( gt_main_data(i).collect1_quantity ),
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- 集荷１：単価
      insert_xml_plsql_table(iox_xml_data, 'collect1_unit_price', TO_CHAR( gt_main_data(i).collect1_unit_price ),
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- 集荷１：金額
-- 08/05/02 Y.Yamamoto ADD v1.1 Start
      IF ( ln_collect1_amount = 0 ) THEN
        ln_collect1_amount := NULL;
      END IF;
-- 08/05/02 Y.Yamamoto ADD v1.1 End
      insert_xml_plsql_table(iox_xml_data, 'collect1_amount', TO_CHAR( ln_collect1_amount ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
--
      -- 集荷２：数量
      insert_xml_plsql_table(iox_xml_data, 'collect2_quantity', TO_CHAR( gt_main_data(i).collect2_quantity ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- 集荷２：単価
      insert_xml_plsql_table(iox_xml_data, 'collect2_unit_price', TO_CHAR( gt_main_data(i).collect2_unit_price ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- 集荷２：金額
-- 08/05/02 Y.Yamamoto ADD v1.1 Start
      IF ( ln_collect2_amount = 0 ) THEN
        ln_collect2_amount := NULL;
      END IF;
-- 08/05/02 Y.Yamamoto ADD v1.1 End
      insert_xml_plsql_table(iox_xml_data, 'collect2_amount', TO_CHAR( ln_collect2_amount ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
--
      -- 受入１：数量
      insert_xml_plsql_table(iox_xml_data, 'receive1_quantity', TO_CHAR( gt_main_data(i).receive1_quantity ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- 受入１：単価
      insert_xml_plsql_table(iox_xml_data, 'receive1_unit_price', TO_CHAR( gt_main_data(i).receive1_unit_price ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- 受入１：金額
-- 08/05/02 Y.Yamamoto ADD v1.1 Start
      IF ( ln_receive1_amount = 0 ) THEN
        ln_receive1_amount := NULL;
      END IF;
-- 08/05/02 Y.Yamamoto ADD v1.1 End
      insert_xml_plsql_table(iox_xml_data, 'receive1_amount', TO_CHAR( ln_receive1_amount ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
--
      -- 受入２：数量
      insert_xml_plsql_table(iox_xml_data, 'receive2_quantity', TO_CHAR( gt_main_data(i).receive2_quantity ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- 受入２：単価
      insert_xml_plsql_table(iox_xml_data, 'receive2_unit_price', TO_CHAR( gt_main_data(i).receive2_unit_price ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- 受入２：金額
-- 08/05/02 Y.Yamamoto ADD v1.1 Start
      IF ( ln_receive2_amount = 0 ) THEN
        ln_receive2_amount := NULL;
      END IF;
-- 08/05/02 Y.Yamamoto ADD v1.1 End
      insert_xml_plsql_table(iox_xml_data, 'receive2_amount', TO_CHAR( ln_receive2_amount ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
--
      -- 出荷：数量
      insert_xml_plsql_table(iox_xml_data, 'shipment_quantity', TO_CHAR( gt_main_data(i).shipment_quantity ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- 出荷：単価
      insert_xml_plsql_table(iox_xml_data, 'shipment_unit_price', TO_CHAR( gt_main_data(i).shipment_unit_price ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- 出荷：金額
-- 08/05/02 Y.Yamamoto ADD v1.1 Start
      IF ( ln_shipment_amount = 0 ) THEN
        ln_shipment_amount := NULL;
      END IF;
-- 08/05/02 Y.Yamamoto ADD v1.1 End
      insert_xml_plsql_table(iox_xml_data, 'shipment_amount', TO_CHAR( ln_shipment_amount ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
--
      -- 生葉合計：数量
-- 08/05/02 Y.Yamamoto ADD v1.1 Start
      IF ( ln_total_quantity = 0 ) THEN
        ln_total_quantity := NULL;
      END IF;
-- 08/05/02 Y.Yamamoto ADD v1.1 End
      insert_xml_plsql_table(iox_xml_data, 'total_quantity', TO_CHAR( ln_total_quantity ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- 生葉合計：金額
-- 08/05/02 Y.Yamamoto ADD v1.1 Start
      IF ( ln_total_amount = 0 ) THEN
        ln_total_amount := NULL;
      END IF;
-- 08/05/02 Y.Yamamoto ADD v1.1 End
      insert_xml_plsql_table(iox_xml_data, 'total_amount', TO_CHAR( ln_total_amount ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
--
      -- 副産物１：品目（コード）
      insert_xml_plsql_table(iox_xml_data, 'byproduct1_item_code', 
                                                          SUBSTRB( gt_main_data(i).byproduct1_item_code, 1, 7 ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- 副産物１：品目（名）
      insert_xml_plsql_table(iox_xml_data, 'byproduct1_item_name', gt_main_data(i).byproduct1_item_name, 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- 副産物１：ロットNo
      insert_xml_plsql_table(iox_xml_data, 'byproduct1_lot_num', 
                                                          SUBSTRB( gt_main_data(i).byproduct1_lot_num, 1, 10 ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- 副産物１：数量
      insert_xml_plsql_table(iox_xml_data, 'byproduct1_quantity', TO_CHAR( gt_main_data(i).byproduct1_quantity ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- 副産物１：単価
      insert_xml_plsql_table(iox_xml_data, 'byproduct1_unit_price', 
                                                          TO_CHAR( gt_main_data(i).byproduct1_unit_price ),
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- 副産物１：金額
-- 08/05/02 Y.Yamamoto ADD v1.1 Start
      IF ( ln_byproduct1_amount = 0 ) THEN
        ln_byproduct1_amount := NULL;
      END IF;
-- 08/05/02 Y.Yamamoto ADD v1.1 End
      insert_xml_plsql_table(iox_xml_data, 'byproduct1_amount', TO_CHAR( ln_byproduct1_amount ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
--
      -- 副産物２：品目（コード）
      insert_xml_plsql_table(iox_xml_data, 'byproduct2_item_code', 
                                                          SUBSTRB( gt_main_data(i).byproduct2_item_code, 1, 7 ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- 副産物２：品目（名）
      insert_xml_plsql_table(iox_xml_data, 'byproduct2_item_name', gt_main_data(i).byproduct2_item_name, 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- 副産物２：ロットNo
      insert_xml_plsql_table(iox_xml_data, 'byproduct2_lot_num', 
                                                          SUBSTRB( gt_main_data(i).byproduct2_lot_num, 1, 10 ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- 副産物２：数量
      insert_xml_plsql_table(iox_xml_data, 'byproduct2_quantity', TO_CHAR( gt_main_data(i).byproduct2_quantity ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- 副産物２：単価
      insert_xml_plsql_table(iox_xml_data, 'byproduct2_unit_price', 
                                                          TO_CHAR( gt_main_data(i).byproduct2_unit_price ),
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- 副産物２：金額
-- 08/05/02 Y.Yamamoto ADD v1.1 Start
      IF ( ln_byproduct2_amount = 0 ) THEN
        ln_byproduct2_amount := NULL;
      END IF;
-- 08/05/02 Y.Yamamoto ADD v1.1 End
      insert_xml_plsql_table(iox_xml_data, 'byproduct2_amount', TO_CHAR( ln_byproduct2_amount ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
--
      -- 副産物３：品目（コード）
      insert_xml_plsql_table(iox_xml_data, 'byproduct3_item_code', 
                                                          SUBSTRB( gt_main_data(i).byproduct3_item_code, 1, 7 ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- 副産物３：品目（名）
      insert_xml_plsql_table(iox_xml_data, 'byproduct3_item_name', gt_main_data(i).byproduct3_item_name, 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- 副産物３：ロットNo
      insert_xml_plsql_table(iox_xml_data, 'byproduct3_lot_num', 
                                                          SUBSTRB( gt_main_data(i).byproduct3_lot_num, 1, 10 ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- 副産物３：数量
      insert_xml_plsql_table(iox_xml_data, 'byproduct3_quantity', TO_CHAR( gt_main_data(i).byproduct3_quantity ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- 副産物３：単価
      insert_xml_plsql_table(iox_xml_data, 'byproduct3_unit_price', 
                                                          TO_CHAR( gt_main_data(i).byproduct3_unit_price ),
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- 副産物３：金額
-- 08/05/02 Y.Yamamoto ADD v1.1 Start
      IF ( ln_byproduct3_amount = 0 ) THEN
        ln_byproduct3_amount := NULL;
      END IF;
-- 08/05/02 Y.Yamamoto ADD v1.1 End
      insert_xml_plsql_table(iox_xml_data, 'byproduct3_amount', TO_CHAR( ln_byproduct3_amount ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
--
      -- 副産物合計：数量
-- 08/05/02 Y.Yamamoto ADD v1.1 Start
      IF ( ln_byproduct_total_quantity = 0 ) THEN
        ln_byproduct_total_quantity := NULL;
      END IF;
-- 08/05/02 Y.Yamamoto ADD v1.1 End
      insert_xml_plsql_table(iox_xml_data, 'byproduct_total_quantity', TO_CHAR( ln_byproduct_total_quantity ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- 副産物合計：金額
-- 08/05/02 Y.Yamamoto ADD v1.1 Start
      IF ( ln_byproduct_total_amount = 0 ) THEN
        ln_byproduct_total_amount := NULL;
      END IF;
-- 08/05/02 Y.Yamamoto ADD v1.1 End
      insert_xml_plsql_table(iox_xml_data, 'byproduct_total_amount', TO_CHAR( ln_byproduct_total_amount ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
--
      -- 荒茶原料合計：数量
      insert_xml_plsql_table(iox_xml_data, 'aracha_quantity', TO_CHAR( gt_main_data(i).aracha_quantity ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- 荒茶原料合計：単価
-- 08/05/02 Y.Yamamoto ADD v1.1 Start
      IF ( ln_aracha_unit_price = 0 ) THEN
        ln_aracha_unit_price := NULL;
      END IF;
-- 08/05/02 Y.Yamamoto ADD v1.1 End
      insert_xml_plsql_table(iox_xml_data, 'aracha_unit_price', TO_CHAR( ln_aracha_unit_price ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- 荒茶原料合計：金額
-- 08/05/02 Y.Yamamoto ADD v1.1 Start
      IF ( ln_aracha_amount = 0 ) THEN
        ln_aracha_amount := NULL;
      END IF;
-- 08/05/02 Y.Yamamoto ADD v1.1 End
      insert_xml_plsql_table(iox_xml_data, 'aracha_amount', TO_CHAR( ln_aracha_amount ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- 歩留
-- 08/05/02 Y.Yamamoto ADD v1.1 Start
      IF ( ln_budomari = 0 ) THEN
        ln_budomari := NULL;
      END IF;
-- 08/05/02 Y.Yamamoto ADD v1.1 End
      insert_xml_plsql_table(iox_xml_data, 'budomari', TO_CHAR( ln_budomari ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
--
      ------------------------------
      -- 明細ＬＧ終了タグ
      ------------------------------
      insert_xml_plsql_table(iox_xml_data, '/g_entry_dtl', NULL, gc_tag_type_tag, gc_tag_value_type_char);
--
      -- 社内振替金額（荒茶）：加工単価
      insert_xml_plsql_table(iox_xml_data, 'processing_unit_price', 
                                                          TO_CHAR( gt_main_data(i).processing_unit_price ),
                                                          gc_tag_type_data, gc_tag_value_type_char);
-- 08/05/02 Y.Yamamoto Update v1.1 Start
      -- 社内振替金額（荒茶）：社内単価
--      insert_xml_plsql_table(iox_xml_data, 'syanai_unit_price', TO_CHAR( gt_main_data(i).syanai_unit_price ), 
--                                                          gc_tag_type_data, gc_tag_value_type_char);
      IF ( ln_syanai_unit_price = 0 ) THEN
        ln_syanai_unit_price := NULL;
      END IF;
      insert_xml_plsql_table(iox_xml_data, 'syanai_unit_price', TO_CHAR( ln_syanai_unit_price ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
-- 08/05/02 Y.Yamamoto Update v1.1 End
      -- 社内振替金額（荒茶）：金額
-- 08/05/02 Y.Yamamoto ADD v1.1 Start
      IF ( ln_amount = 0 ) THEN
        ln_amount := NULL;
      END IF;
-- 08/05/02 Y.Yamamoto ADD v1.1 End
      insert_xml_plsql_table(iox_xml_data, 'amount', TO_CHAR( ln_amount ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
--
      -- 受入合計：数量
-- 08/05/02 Y.Yamamoto ADD v1.1 Start
      IF ( ln_receive_total_quantity = 0 ) THEN
        ln_receive_total_quantity := NULL;
      END IF;
-- 08/05/02 Y.Yamamoto ADD v1.1 End
      insert_xml_plsql_table(iox_xml_data, 'receive_total_quantity', TO_CHAR( ln_receive_total_quantity ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- 受入合計：金額
-- 08/05/02 Y.Yamamoto ADD v1.1 Start
      IF ( ln_receive_total_amount = 0 ) THEN
        ln_receive_total_amount := NULL;
      END IF;
-- 08/05/02 Y.Yamamoto ADD v1.1 End
      insert_xml_plsql_table(iox_xml_data, 'receive_total_amount', TO_CHAR( ln_receive_total_amount ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- -----------------------------------------------------
      -- 明細Ｇ終了タグ出力
      -- -----------------------------------------------------
      insert_xml_plsql_table(iox_xml_data, '/g_entry', NULL, gc_tag_type_tag, gc_tag_value_type_char);
--
    END LOOP main_data_loop ;
--
    -- =====================================================
    -- 終了処理
    -- =====================================================
    ------------------------------
    -- 伝票Ｇ終了タグ
    ------------------------------
    insert_xml_plsql_table(iox_xml_data, '/lg_entry_info', NULL, gc_tag_type_tag, gc_tag_value_type_char);
    ------------------------------
    -- データＧ終了タグ
    ------------------------------
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
     ,iv_entry_num          IN     VARCHAR2         --   04 : 伝票NO
     ,iv_item_code          IN     VARCHAR2         --   05 : 仕上品目
     ,iv_department_code    IN     VARCHAR2         --   06 : 入力部署
     ,iv_employee_number    IN     VARCHAR2         --   07 : 入力担当者
     ,iv_input_date_from    IN     VARCHAR2         --   08 : 入力期間FROM
     ,iv_input_date_to      IN     VARCHAR2         --   09 : 入力期間TO
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
    lr_param_rec.iv_entry_num       := iv_entry_num ;          -- 伝票NO
    lr_param_rec.iv_item_code       := iv_item_code ;          -- 仕上品目
    lr_param_rec.iv_department_code := iv_department_code ;    -- 入力部署
    lr_param_rec.iv_employee_number := iv_employee_number ;    -- 入力担当者
    lr_param_rec.iv_input_date_from := iv_input_date_from ;    -- 入力期間FROM
    lr_param_rec.iv_input_date_to   := iv_input_date_to ;      -- 入力期間TO
--
    -- =====================================================
    -- 前処理(B-2)
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
    -- 帳票データ出力(B-3,4)
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
    -- ＸＭＬ出力(B-4)
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
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <lg_entry_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      <g_entry>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <report_title>' || gc_report_title || '</report_title>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <msg>'          || lv_errmsg       || '</msg>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      </g_entry>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    </lg_entry_info>' ) ;
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
     ,iv_entry_num          IN     VARCHAR2         -- 04 : 伝票NO
     ,iv_item_code          IN     VARCHAR2         -- 05 : 仕上品目
     ,iv_department_code    IN     VARCHAR2         -- 06 : 入力部署
     ,iv_employee_number    IN     VARCHAR2         -- 07 : 入力担当者
     ,iv_input_date_from    IN     VARCHAR2         -- 08 : 入力期間FROM
     ,iv_input_date_to      IN     VARCHAR2         -- 09 : 入力期間TO
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
       ,iv_entry_num       => iv_entry_num        -- 04 : 伝票NO
       ,iv_item_code       => iv_item_code        -- 05 : 仕上品目
       ,iv_department_code => iv_department_code  -- 06 : 入力部署
       ,iv_employee_number => iv_employee_number  -- 07 : 入力担当者
       ,iv_input_date_from => iv_input_date_from  -- 08 : 入力期間FROM
       ,iv_input_date_to   => iv_input_date_to    -- 09 : 入力期間TO
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
END xxpo710001c ;
/