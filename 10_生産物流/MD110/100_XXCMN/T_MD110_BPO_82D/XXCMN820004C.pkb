CREATE OR REPLACE PACKAGE BODY xxcmn820004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn820004c(body)
 * Description      : 新旧差額計算表作成
 * MD.050/070       : 標準原価マスタDraft1C (T_MD050_BPO_820)
 *                    新旧差額計算表作成    (T_MD070_BPO_82D)
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  convert_into_xml       XMLデータ変換
 *  output_xml             XMLデータ出力
 *  prc_get_record         帳票出力情報取得
 *  prc_get_header_info    ヘッダ情報取得
 *  prc_create_xml         XMLデータ作成
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/01/18    1.0   Kazuo Kumamoto   新規作成
 *  2008/05/21    1.1   Masayuki Ikeda   結合テスト障害対応
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
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--###########################  固定部 END   ############################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name               CONSTANT VARCHAR2(12)  := 'xxcmn820004c'; -- パッケージ名
--
  gc_application_po         CONSTANT VARCHAR2(4)   := 'XXPO' ;           -- アプリケーション(XXPO)
  gc_application_cmn        CONSTANT VARCHAR2(5)   := 'XXCMN' ;          -- アプリケーション(XXCMN)
  gc_xxpo_00036             CONSTANT VARCHAR2(14)  := 'APP-XXPO-00036' ; -- 担当部署名未取得
  gc_xxpo_00026             CONSTANT VARCHAR2(14)  := 'APP-XXPO-00026' ; -- 担当者名未取得
  gc_xxpo_00033             CONSTANT VARCHAR2(14)  := 'APP-XXPO-00033' ; -- データ未取得
  gc_xxcmn_10122            CONSTANT VARCHAR2(15)  := 'APP-XXCMN-10122' ;-- 明細0件
  gv_msg_kbn                CONSTANT VARCHAR2(5)   := 'XXCMN' ;          -- パッケージ名
  gv_msg_num_10013          CONSTANT VARCHAR2(15)  := 'APP-XXCMN-10013' ;-- ケース入り数0エラー
  gv_ofcase_name            CONSTANT VARCHAR2(14)  := 'のケース入り数' ;
  gv_mst_name               CONSTANT VARCHAR2(100) := '品目カテゴリマスタ' ;
  gv_msg_num_10003          CONSTANT VARCHAR2(15)  := 'APP-XXCMN-10003' ;-- 前年度の世代取得エラー
  gv_prev_gene_err_name     CONSTANT VARCHAR2(36)  := 'フォーキャスト(前年度の最新世代取得)';
--
  gv_report_id              CONSTANT VARCHAR2(12)  := 'XXCMN820004T' ; -- プログラム名帳票出力用
  gc_description_prov       CONSTANT VARCHAR2(8) := '商品区分';
  gc_description_crowd      CONSTANT VARCHAR2(8) := '群コード';
  gc_lang                   CONSTANT VARCHAR2(2) := 'JA';
  gc_source_lang            CONSTANT VARCHAR2(2) := 'JA';
--
  gc_item_type              CONSTANT VARCHAR2(22) := 'XXPO_EXPENSE_ITEM_TYPE';
  gc_row_material_cost      CONSTANT VARCHAR2(10) := '1';--'原料費';
  gc_remake_cost            CONSTANT VARCHAR2(10) := '2';--'再製費';
  gc_material_cost          CONSTANT VARCHAR2(10) := '3';--'資材費';
  gc_wrapping_cost          CONSTANT VARCHAR2(10) := '4';--'包装費';
  gc_outside_cost           CONSTANT VARCHAR2(10) := '5';--'外注管理費';
  gc_store_cost             CONSTANT VARCHAR2(10) := '6';--'保管費';
  gc_other_cost             CONSTANT VARCHAR2(10) := '7';--'その他経費';
--
  gc_fc_type                CONSTANT VARCHAR2(13) := 'XXINV_FC_TYPE';
  gc_fc_description         CONSTANT VARCHAR2(8) := '販売計画';
--
  gc_price_type             CONSTANT VARCHAR2(1) := '2'; --1:仕入  2:標準
  gc_output_unit_code_quant CONSTANT VARCHAR2(1) := '0'; --0:本数  1:ケース
  gc_output_unit_code_case  CONSTANT VARCHAR2(1) := '1'; --0:本数  1:ケース
  gc_output_unit_name_quant CONSTANT VARCHAR2(4) := '本数';
  gc_output_unit_name_case  CONSTANT VARCHAR2(6) := 'ケース';
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 入力パラメータ格納用レコード変数
  TYPE rec_param_data  IS RECORD 
    (
      output_unit       VARCHAR2(6)     -- 出力単位
     ,fiscal_year       VARCHAR2(4)     -- 対象年度
     ,generation        VARCHAR2(2)     -- 世代
     ,prod_div          VARCHAR2(1)     -- 商品区分
     ,crowd_code_01     VARCHAR2(4)     -- 群コード１
     ,crowd_code_02     VARCHAR2(4)     -- 群コード２
     ,crowd_code_03     VARCHAR2(4)     -- 群コード３
     ,crowd_code_04     VARCHAR2(4)     -- 群コード３
     ,crowd_code_05     VARCHAR2(4)     -- 群コード３
    ) ;
--
  -- 取得レコード格納用レコード変数
  TYPE rec_data IS RECORD
    (
      prod_div                         mtl_categories_b.segment1%TYPE
     ,prod_div_name                    mtl_categories_tl.description%TYPE
     ,crowd_code                       mtl_categories_b.segment1%TYPE
     ,item_code                        xxpo_price_headers.item_code%TYPE
     ,item_name                        xxcmn_item_mst_b.item_name%TYPE
     ,in_case                          ic_item_mst_b.attribute11%TYPE
     ,forecast_quantity_new            mrp_forecast_dates.original_forecast_quantity%TYPE
     ,cost_price_new                   xxpo_price_lines.unit_price%TYPE
     ,row_material_cost_new            xxpo_price_lines.unit_price%TYPE
     ,remake_cost_new                  xxpo_price_lines.unit_price%TYPE
     ,material_cost_new                xxpo_price_lines.unit_price%TYPE
     ,wrapping_cost_new                xxpo_price_lines.unit_price%TYPE
     ,outside_cost_new                 xxpo_price_lines.unit_price%TYPE
     ,store_cost_new                   xxpo_price_lines.unit_price%TYPE
     ,other_cost_new                   xxpo_price_lines.unit_price%TYPE
     ,cost_price_old                   xxpo_price_lines.unit_price%TYPE
     ,row_material_cost_old            xxpo_price_lines.unit_price%TYPE
     ,remake_cost_old                  xxpo_price_lines.unit_price%TYPE
     ,material_cost_old                xxpo_price_lines.unit_price%TYPE
     ,wrapping_cost_old                xxpo_price_lines.unit_price%TYPE
     ,outside_cost_old                 xxpo_price_lines.unit_price%TYPE
     ,store_cost_old                   xxpo_price_lines.unit_price%TYPE
     ,other_cost_old                   xxpo_price_lines.unit_price%TYPE
    );
  TYPE tab_data IS TABLE OF rec_data INDEX BY BINARY_INTEGER ;
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_exec_date              DATE ;               -- 実施日
  gv_department_code        VARCHAR2(10) ;       -- 担当部署
  gv_department_name        VARCHAR2(14) ;       -- 担当者
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
    IF (ic_type = 'D') THEN
      lv_convert_data := '<'||iv_name||'>'||iv_value||'</'||iv_name||'>';
    ELSE
      lv_convert_data := '<'||iv_name||'>';
    END IF;
--
    RETURN(lv_convert_data);
--
  END convert_into_xml;
--
  /**********************************************************************************
   * Procedure Name   : output_xml
   * Description      : XMLデータ出力処理プロシージャ
   ***********************************************************************************/
  PROCEDURE output_xml(
    iox_xml_data         IN OUT    NOCOPY XML_DATA, -- XMLデータ
    ov_errbuf            OUT       VARCHAR2,        -- エラー・メッセージ           --# 固定 #
    ov_retcode           OUT       VARCHAR2,        -- リターン・コード             --# 固定 #
    ov_errmsg            OUT       VARCHAR2)        -- ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000) ;  -- エラー・メッセージ
    lv_retcode VARCHAR2(1) ;     -- リターン・コード
    lv_errmsg  VARCHAR2(5000) ;  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'output_xml' ;  --  プログラム名
--
    -- =====================================================
    -- ユーザー宣言部
    -- =====================================================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_xml_string  VARCHAR2(32000) ;
--
  BEGIN
--
    -- XMLヘッダ出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<?xml version="1.0" encoding="shift_jis" ?>') ;
--
    -- XMLデータ部出力
    <<xml_loop>>
    FOR i IN 1 .. iox_xml_data.COUNT LOOP
      lv_xml_string := convert_into_xml(
                         iox_xml_data(i).tag_name
                        ,iox_xml_data(i).tag_value
                        ,iox_xml_data(i).tag_type) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_xml_string) ;
    END LOOP xml_loop ;
--
    -- XMLデータ(Temp)削除
    iox_xml_data.DELETE ;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
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
--
  END output_xml ;
--
  /**********************************************************************************
   * Procedure Name   : prc_get_record
   * Description      : 帳票出力情報取得
   ***********************************************************************************/
  PROCEDURE prc_get_record
    (
      ir_param_rec     IN  rec_param_data    --
     ,ot_data_rec      OUT tab_data          -- 
     ,ov_errbuf        OUT VARCHAR2          -- エラー・メッセージ           --# 固定 #
     ,ov_retcode       OUT VARCHAR2          -- リターン・コード             --# 固定 #
     ,ov_errmsg        OUT VARCHAR2          -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_record'; -- プログラム名
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
    lv_prev_year       mrp_forecast_designators.attribute6%TYPE;
    lv_prev_gene       mrp_forecast_designators.attribute5%TYPE;
--
    data_check_expt    EXCEPTION ;             -- データチェックエクセプション
--
    CURSOR cur_main_data
      (
        civ_current_year VARCHAR2
       ,civ_current_gene VARCHAR2
       ,civ_prev_year VARCHAR2
       ,civ_prev_gene VARCHAR2
       ,civ_prod_div VARCHAR2
       ,civ_crowd_code_01 VARCHAR2
       ,civ_crowd_code_02 VARCHAR2
       ,civ_crowd_code_03 VARCHAR2
       ,civ_crowd_code_04 VARCHAR2
       ,civ_crowd_code_05 VARCHAR2
      )
    IS
      SELECT
        m.prod_div                            AS prod_div --商品区分
       ,m.prod_div_name                       AS prod_div_name --商品区分名
       ,m.crowd_code                          AS crowd_code --群コード
       ,np.item_code                          AS item_code --品目コード
       ,ximb.item_name                        AS item_name --品目名
       ,NVL(iimb.attribute11,'0')             AS in_case --ケース入り数
       ,np.forecast_quantity_new              AS forecast_quantity_new --数量
       ,np.cost_price_new                     AS cost_price_new --新.標準原価
       ,np.row_material_cost_new              AS row_material_cost_new --新.原料費
       ,np.remake_cost_new                    AS remake_cost_new --新.再製費
       ,np.material_cost_new                  AS material_cost_new --新.資材費
       ,np.wrapping_cost_new                  AS wrapping_cost_new --新.包装費
       ,np.outside_cost_new                   AS outside_cost_new --新.外注管理費
       ,np.store_cost_new                     AS store_cost_new --新.保管費
       ,np.other_cost_new                     AS other_cost_new --新.その他経費
       ,NVL(op.cost_price_old,0)              AS cost_price_old --旧.標準原価
       ,NVL(op.row_material_cost_old,0)       AS row_material_cost_old --旧.原料費
       ,NVL(op.remake_cost_old,0)             AS remake_cost_old --旧.再製費
       ,NVL(op.material_cost_old,0)           AS material_cost_old --旧.資材費
       ,NVL(op.wrapping_cost_old,0)           AS wrapping_cost_old --旧.包装費
       ,NVL(op.outside_cost_old,0)            AS outside_cost_old --旧.外注管理費
       ,NVL(op.store_cost_old,0)              AS store_cost_old --旧.保管費
       ,NVL(op.other_cost_old,0)              AS other_cost_old --旧.その他経費
      FROM (
        SELECT
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--          mfdate.original_forecast_quantity   AS forecast_quantity_new
--         ,mfdate.forecast_date                AS forecast_date
          SUM( mfdate.original_forecast_quantity) AS forecast_quantity_new
         ,MIN(mfdate.forecast_date)               AS forecast_date
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
         ,xph.item_id                         AS item_id
         ,xph.item_code                       AS item_code
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--         ,SUM(xpl.quantity * xpl.unit_price)  AS cost_price_new
         ,SUM(mfdate.original_forecast_quantity * xpl.unit_price)  AS cost_price_new
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
         ,SUM(CASE WHEN flv_item.attribute2 = gc_row_material_cost
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--                     THEN xpl.quantity * xpl.unit_price
                     THEN mfdate.original_forecast_quantity * xpl.unit_price
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
                     ELSE 0
                   END) AS row_material_cost_new
         ,SUM(CASE WHEN flv_item.attribute2 = gc_remake_cost
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--                     THEN xpl.quantity * xpl.unit_price
                     THEN mfdate.original_forecast_quantity * xpl.unit_price
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
                     ELSE 0
                   END) AS remake_cost_new
         ,SUM(CASE WHEN flv_item.attribute2 = gc_material_cost
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--                     THEN xpl.quantity * xpl.unit_price
                     THEN mfdate.original_forecast_quantity * xpl.unit_price
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
                     ELSE 0
                   END) AS material_cost_new
         ,SUM(CASE WHEN flv_item.attribute2 = gc_wrapping_cost
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--                     THEN xpl.quantity * xpl.unit_price
                     THEN mfdate.original_forecast_quantity * xpl.unit_price
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
                     ELSE 0
                   END) AS wrapping_cost_new
         ,SUM(CASE WHEN flv_item.attribute2 = gc_outside_cost
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--                     THEN xpl.quantity * xpl.unit_price
                     THEN mfdate.original_forecast_quantity * xpl.unit_price
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
                     ELSE 0
                   END) AS outside_cost_new
         ,SUM(CASE WHEN flv_item.attribute2 = gc_store_cost
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--                     THEN xpl.quantity * xpl.unit_price
                     THEN mfdate.original_forecast_quantity * xpl.unit_price
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
                     ELSE 0
                   END) AS store_cost_new
         ,SUM(CASE WHEN flv_item.attribute2 = gc_other_cost
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--                     THEN xpl.quantity * xpl.unit_price
                     THEN mfdate.original_forecast_quantity * xpl.unit_price
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
                     ELSE 0
                   END) AS other_cost_new
        FROM
          mrp_forecast_designators              mfdesi    --フォーキャスト名
         ,xxcmn_lookup_values2_v                flv_fc    --クイックコード
         ,mrp_forecast_dates                    mfdate    --フォーキャスト日付
         ,mtl_system_items_b                    msib      --品目マスタ
         ,xxpo_price_headers                    xph       --仕入・標準単価ヘッダ
         ,xxpo_price_lines                      xpl       --仕入・標準単価明細
         ,xxcmn_lookup_values2_v                flv_item  --クイックコード
        WHERE flv_fc.lookup_type = gc_fc_type
        AND flv_fc.description = gc_fc_description
        AND mfdesi.attribute1 = flv_fc.lookup_code
        AND mfdate.forecast_date
          BETWEEN flv_fc.start_date_active AND NVL(flv_fc.end_date_active,mfdate.forecast_date)
        AND mfdesi.forecast_designator = mfdate.forecast_designator
        AND mfdesi.organization_id = mfdate.organization_id
        AND mfdate.inventory_item_id = msib.inventory_item_id
        AND mfdate.organization_id = msib.organization_id
        AND xph.price_header_id = xpl.price_header_id
        AND xph.price_type = gc_price_type
        AND mfdate.forecast_date
          BETWEEN xph.start_date_active AND NVL(xph.end_date_active,mfdate.forecast_date)
        AND mfdesi.disable_date IS NULL
        AND mfdesi.attribute6 = civ_current_year --新.年度
        AND mfdesi.attribute5 = civ_current_gene --新.世代
        AND msib.segment1 = xph.item_code
        AND flv_item.lookup_type = gc_item_type
        AND flv_item.attribute1 = xpl.expense_item_type
        AND mfdate.forecast_date
          BETWEEN flv_item.start_date_active AND NVL(flv_item.end_date_active,mfdate.forecast_date)
        GROUP BY 
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--          mfdate.original_forecast_quantity
--         ,mfdate.forecast_date
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
          xph.item_id
         ,xph.item_code
      ) np
     ,(
        SELECT
          xph.item_id                         AS item_id
         ,xph.item_code                       AS item_code
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--         ,SUM(xpl.quantity * xpl.unit_price)  AS cost_price_old
         ,SUM(mfdate.original_forecast_quantity * xpl.unit_price)  AS cost_price_old
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
         ,SUM(CASE WHEN flv_item.attribute2 = gc_row_material_cost
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--                     THEN xpl.quantity * xpl.unit_price
                     THEN mfdate.original_forecast_quantity * xpl.unit_price
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
                     ELSE 0
                   END) AS row_material_cost_old
         ,SUM(CASE WHEN flv_item.attribute2 = gc_remake_cost
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--                     THEN xpl.quantity * xpl.unit_price
                     THEN mfdate.original_forecast_quantity * xpl.unit_price
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
                     ELSE 0
                   END) AS remake_cost_old
         ,SUM(CASE WHEN flv_item.attribute2 = gc_material_cost
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--                     THEN xpl.quantity * xpl.unit_price
                     THEN mfdate.original_forecast_quantity * xpl.unit_price
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
                     ELSE 0
                   END) AS material_cost_old
         ,SUM(CASE WHEN flv_item.attribute2 = gc_wrapping_cost
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--                     THEN xpl.quantity * xpl.unit_price
                     THEN mfdate.original_forecast_quantity * xpl.unit_price
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
                     ELSE 0
                   END) AS wrapping_cost_old
         ,SUM(CASE WHEN flv_item.attribute2 = gc_outside_cost
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--                     THEN xpl.quantity * xpl.unit_price
                     THEN mfdate.original_forecast_quantity * xpl.unit_price
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
                     ELSE 0
                   END) AS outside_cost_old
         ,SUM(CASE WHEN flv_item.attribute2 = gc_store_cost
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--                     THEN xpl.quantity * xpl.unit_price
                     THEN mfdate.original_forecast_quantity * xpl.unit_price
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
                     ELSE 0
                   END) AS store_cost_old
         ,SUM(CASE WHEN flv_item.attribute2 = gc_other_cost
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--                     THEN xpl.quantity * xpl.unit_price
                     THEN mfdate.original_forecast_quantity * xpl.unit_price
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
                     ELSE 0
                   END) AS other_cost_old
        FROM
          mrp_forecast_designators              mfdesi  --フォーキャスト名
         ,xxcmn_lookup_values2_v                flv_fc     --クイックコード
         ,mrp_forecast_dates                    mfdate  --フォーキャスト日付
         ,mtl_system_items_b                    msib    --品目マスタ
         ,xxpo_price_headers                    xph     --仕入・標準単価ヘッダ
         ,xxpo_price_lines                      xpl
         ,xxcmn_lookup_values2_v                flv_item
        WHERE flv_fc.lookup_type = gc_fc_type
        AND flv_fc.description = gc_fc_description
        AND mfdesi.attribute1 = flv_fc.lookup_code
        AND mfdate.forecast_date
          BETWEEN flv_fc.start_date_active AND NVL(flv_fc.end_date_active,mfdate.forecast_date)
        AND mfdesi.forecast_designator = mfdate.forecast_designator
        AND mfdesi.organization_id = mfdate.organization_id
        AND mfdate.inventory_item_id = msib.inventory_item_id
        AND mfdate.organization_id = msib.organization_id
        AND xph.price_header_id = xpl.price_header_id
        AND xph.price_type = gc_price_type
        AND mfdate.forecast_date
          BETWEEN xph.start_date_active AND NVL(xph.end_date_active,mfdate.forecast_date)
        AND mfdesi.disable_date IS NULL
        AND mfdesi.attribute6 = civ_prev_year --新.年度
        AND mfdesi.attribute5 = civ_prev_gene --新.世代
        AND msib.segment1 = xph.item_code
        AND flv_item.lookup_type = gc_item_type
        AND flv_item.attribute1 = xpl.expense_item_type
        AND mfdate.forecast_date
          BETWEEN flv_item.start_date_active AND NVL(flv_item.end_date_active,mfdate.forecast_date)
        GROUP BY 
          mfdate.original_forecast_quantity
         ,xph.item_id
         ,xph.item_code
      ) op
     ,(
        SELECT
          MAX(CASE WHEN mcst.description = gc_description_prov THEN mcb.segment1 ELSE NULL END)
          AS prod_div --商品区分
         ,MAX(CASE WHEN mcst.description = gc_description_prov THEN mct.description ELSE NULL END)
          AS prod_div_name --商品区分名
         ,MAX(CASE WHEN mcst.description = gc_description_crowd THEN mcb.segment1 ELSE NULL END)
          AS crowd_code --群コード
         ,gic.item_id           AS item_id --品目ID
        FROM
          mtl_category_sets_tl     mcst  --品目カテゴリセット日本語
         ,mtl_category_sets_b      mcsb  --品目カテゴリセット
         ,mtl_categories_b         mcb   --品目カテゴリマスタ
         ,mtl_categories_tl        mct   --品目カテゴリマスタ日本語
         ,gmi_item_categories      gic   --OPM品目カテゴリ割当
        WHERE mcst.description IN( gc_description_prov,gc_description_crowd)
        AND mcst.language = gc_lang
        AND mcst.source_lang = gc_source_lang
        AND mcst.category_set_id = mcsb.category_set_id
        AND mcsb.structure_id = mcb.structure_id
        AND mcb.category_id = mct.category_id
        AND mct.language = gc_lang
        AND mct.source_lang = gc_source_lang
        AND mcsb.category_set_id = gic.category_set_id
        AND mcb.category_id = gic.category_id
        GROUP BY gic.item_id
      ) m
     ,ic_item_mst_b            iimb  --OPM品目マスタ
     ,xxcmn_item_mst_b         ximb  --OPM品目アドオンマスタ
    WHERE np.item_id = op.item_id(+)
    AND np.item_id = m.item_id
    AND np.item_id = iimb.item_id
    AND np.item_id = ximb.item_id
    AND np.forecast_date
      BETWEEN ximb.start_date_active AND NVL(ximb.end_date_active,np.forecast_date)
    --絞込み(商品区分)
    AND (civ_prod_div IS NOT NULL AND m.prod_div = civ_prod_div
    OR   civ_prod_div IS NULL)
    --絞込み(群コード)
    AND (civ_crowd_code_01 IS NULL AND civ_crowd_code_02 IS NULL AND civ_crowd_code_03 IS NULL 
    AND  civ_crowd_code_04 IS NULL AND civ_crowd_code_05 IS NULL
    OR   civ_crowd_code_01 IS NOT NULL AND m.crowd_code LIKE civ_crowd_code_01 || '%'
    OR   civ_crowd_code_02 IS NOT NULL AND m.crowd_code LIKE civ_crowd_code_02 || '%'
    OR   civ_crowd_code_03 IS NOT NULL AND m.crowd_code LIKE civ_crowd_code_03 || '%'
    OR   civ_crowd_code_04 IS NOT NULL AND m.crowd_code LIKE civ_crowd_code_04 || '%'
    OR   civ_crowd_code_05 IS NOT NULL AND m.crowd_code LIKE civ_crowd_code_05 || '%')
    ORDER BY m.prod_div,m.crowd_code,TO_NUMBER(np.item_code)
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
    -- 前年度の最新世代取得
    -- ====================================================
    lv_prev_year := TO_CHAR(TO_NUMBER(ir_param_rec.fiscal_year) - 1);
--
    BEGIN
      SELECT NVL(MAX(mfdesi.attribute5),'0')
      INTO lv_prev_gene
       FROM
         mrp_forecast_designators  mfdesi
        ,xxcmn_lookup_values2_v    flv
        ,mrp_forecast_dates        mfdate
        ,mtl_system_items_b        msib
      WHERE flv.lookup_type = gc_fc_type
      AND flv.description = gc_fc_description
      AND mfdesi.attribute1 = flv.lookup_code
      AND mfdate.forecast_date
        BETWEEN flv.start_date_active AND NVL(flv.end_date_active,mfdate.forecast_date)
      AND mfdesi.forecast_designator = mfdate.forecast_designator
      AND mfdesi.organization_id = mfdate.organization_id
      AND mfdate.inventory_item_id = msib.inventory_item_id
      AND mfdate.organization_id = msib.organization_id
      AND mfdesi.attribute6 = lv_prev_year
      AND mfdesi.disable_date IS NULL
      ;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg  := xxcmn_common_pkg.get_msg(gv_msg_kbn   , gv_msg_num_10003
                                              ,'TABLE' , gv_prev_gene_err_name
                                              ,'KEY', lv_prev_year );
        RAISE data_check_expt ;
    END;
    -- ====================================================
    -- データ抽出
    -- ====================================================
    -- カーソルオープン
    OPEN cur_main_data
      (
        ir_param_rec.fiscal_year
       ,ir_param_rec.generation
       ,lv_prev_year
       ,lv_prev_gene
       ,ir_param_rec.prod_div
       ,ir_param_rec.crowd_code_01
       ,ir_param_rec.crowd_code_02
       ,ir_param_rec.crowd_code_03
       ,ir_param_rec.crowd_code_04
       ,ir_param_rec.crowd_code_05
      );
--
    --バルクフェッチ
    FETCH cur_main_data BULK COLLECT INTO ot_data_rec;
    --クローズ
    CLOSE cur_main_data;
--
  EXCEPTION
--
    WHEN data_check_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error ;
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
  END prc_get_record;
--
  /**********************************************************************************
   * Procedure Name   : prc_get_header_info
   * Description      : ヘッダ情報取得
   ***********************************************************************************/
  PROCEDURE prc_get_header_info
    (
      ov_errbuf        OUT VARCHAR2          -- エラー・メッセージ           --# 固定 #
     ,ov_retcode       OUT VARCHAR2          -- リターン・コード             --# 固定 #
     ,ov_errmsg        OUT VARCHAR2          -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_header_info'; -- プログラム名
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
--
    -- *** ローカル・変数 ***
    lv_err_code     VARCHAR2(100) ; -- エラーコード格納用
--
    -- *** ローカル・例外処理 ***
--
  BEGIN
    -- ====================================================
    -- 実施日取得
    -- ====================================================
    gd_exec_date := SYSDATE;
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
  END prc_get_header_info;
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml
   * Description      : XMLデータ作成
   ***********************************************************************************/
  PROCEDURE prc_create_xml
   (
    ir_param_rec       IN  rec_param_data
   ,iox_xml_data       IN OUT  NOCOPY XML_DATA -- 1.XMLデータ
   ,ov_errbuf          OUT VARCHAR2     --    エラー・メッセージ           --# 固定 #
   ,ov_retcode         OUT VARCHAR2     --    リターン・コード             --# 固定 #
   ,ov_errmsg          OUT VARCHAR2     --    ユーザー・エラー・メッセージ --# 固定 #
   )
  IS
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml'; -- プログラム名
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
    lt_data_rec              tab_data;
    ln_idx                   NUMBER := 0;
    lv_prod_div              VARCHAR2(2) ;         -- 商品区分取得用
    lv_prod_div_name         VARCHAR2(20) ;        -- 商品区分名
    lv_crd_code_big          VARCHAR2(4);
    lv_crd_code_middle       VARCHAR2(4);
    lv_crd_code_small        VARCHAR2(4);
    lv_crd_code_detail       VARCHAR2(4);
    lv_crowd_code_current    VARCHAR2(4);
    lv_prod_div_current      VARCHAR2(1);
    ln_quant                 NUMBER;
    lv_output_unit_name      VARCHAR2(6);
--
    -- *** ローカル・例外処理 ***
    no_data_expt                 EXCEPTION ;             -- 取得レコードなし
    data_check_expt              EXCEPTION ;             -- データチェックエクセプション
--
  BEGIN
    -- =====================================================
    -- ヘッダー情報取得
    -- =====================================================
    prc_get_header_info
      (
        ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
    -- =====================================================
    -- 明細情報取得
    -- =====================================================
    prc_get_record
      (
        ir_param_rec      => ir_param_rec       -- 入力パラメータ群
       ,ot_data_rec       => lt_data_rec        -- 取得レコード
       ,ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    ELSIF lt_data_rec.COUNT = 0 THEN
      RAISE no_data_expt;
    END IF ;
--
    -- =====================================================
    -- XML作成
    -- =====================================================
    -- データグループ名開始タグセット   <root>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'root' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    -- データグループ名開始タグセット   <user_info>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'user_info' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    -- データセット                     <report_id>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'report_id' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := gv_report_id ;
--
    -- データセット                     <exec_date>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'exec_date' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := TO_CHAR( gd_exec_date, 'YYYY/MM/DD HH24:MI:SS' ) ;
--
    -- データセット                     <exec_user_dept>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'exec_user_dept' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := gv_department_code;
--
    -- データセット                     <exec_user_name>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'exec_user_name' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := gv_department_name;
--
    -- データグループ名終了タグセット   </user_info>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := '/user_info' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    -- =====================================================
    -- パラメータデータセット
    -- =====================================================
    -- データグループ名開始タグセット   <param_info>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_info' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    -- データセット                     <param_01>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_01' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_param_rec.fiscal_year ;
--
    -- データセット                     <param_02>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_02' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_param_rec.prod_div ;
--
    -- データセット                     <param_03>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_03' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_param_rec.generation ;
--
    -- データセット                     <param_04>
    IF (ir_param_rec.output_unit = gc_output_unit_code_quant ) THEN
      lv_output_unit_name := gc_output_unit_name_quant;
    ELSIF (ir_param_rec.output_unit = gc_output_unit_code_case) THEN
      lv_output_unit_name := gc_output_unit_name_case;
    END IF;
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_04' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := lv_output_unit_name ;
--
    -- データグループ名終了タグセット   </param_info>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := '/param_info' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    -- =====================================================
    -- 明細データタグセット
    -- =====================================================
    -- データグループ名開始タグセット   <data_info>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'data_info' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    -- =====================================================
    -- 項目データ抽出・出力処理
    -- =====================================================
    -- 商品区分リストタグセット   <lg_prod>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'lg_prod' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    <<main_data_loop>>
    FOR i IN 1..lt_data_rec.COUNT LOOP
--
      --処理中レコードの群コード
      lv_crowd_code_current := lt_data_rec(i).crowd_code ;
      lv_prod_div_current := lt_data_rec(i).prod_div;
--
      -- ===================================================
      -- データ部初期タグ、データセット
      -- ===================================================
      IF (i = 1) THEN
--
        -- 商品区分代入
        lv_prod_div    := lv_prod_div_current;
        -- 大群コード代入
        lv_crd_code_big := SUBSTR(lv_crowd_code_current,1,1) ;
        -- 中群コード代入
        lv_crd_code_middle := SUBSTR(lv_crowd_code_current,1,2) ;
        -- 小群コード03代入
        lv_crd_code_small := SUBSTR(lv_crowd_code_current,1,3) ;
        -- 細群コード代入
        lv_crd_code_detail := lv_crowd_code_current ;
--
        -- ==================================================
        -- データセット
        -- ==================================================
        -- データグループ名開始タグセット         <g_prod>
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'g_prod' ;
        iox_xml_data(ln_idx).tag_type  := 'T' ;
--
        -- データセット  商品区分                 <prod_div>
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'prod_div' ;
        iox_xml_data(ln_idx).tag_type  := 'D' ;
        iox_xml_data(ln_idx).tag_value := lv_prod_div ;
--
        -- データセット  商品区分名               <prod_div_name>
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'prod_div_name' ;
        iox_xml_data(ln_idx).tag_type  := 'D' ;
        iox_xml_data(ln_idx).tag_value := lt_data_rec(i).prod_div_name ;
--
        -- タグセット    大群コードリスト              <lg_crd_big>
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'lg_crd_big' ;
        iox_xml_data(ln_idx).tag_type  := 'T' ;
--
        -- タグセット  大群コードグループ                 <g_crd_big>
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'g_crd_big' ;
        iox_xml_data(ln_idx).tag_type  := 'T' ;
--
        -- データセット  大群コード                 <crd_code_big>
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'crd_code_big' ;
        iox_xml_data(ln_idx).tag_type  := 'D' ;
        iox_xml_data(ln_idx).tag_value := lv_crd_code_big ;

        -- タグセット    中群コードリスト     <lg_crd_middle>
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'lg_crd_middle' ;
        iox_xml_data(ln_idx).tag_type  := 'T' ;
--
        -- タグセット  中群コードグループ                 <g_crd_middle>
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'g_crd_middle' ;
        iox_xml_data(ln_idx).tag_type  := 'T' ;
--
        -- データセット  中群コード                 <crd_code_middle>
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'crd_code_middle' ;
        iox_xml_data(ln_idx).tag_type  := 'D' ;
        iox_xml_data(ln_idx).tag_value := lv_crd_code_middle ;

        -- タグセット    小群コードリスト     <lg_crd_small>
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'lg_crd_small' ;
        iox_xml_data(ln_idx).tag_type  := 'T' ;
--
      -- タグセット  小群コードグループ                   <g_crd_small>
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'g_crd_small' ;
        iox_xml_data(ln_idx).tag_type  := 'T' ;
--
        -- データセット  小群コード                 <crd_code_small>
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'crd_code_small' ;
        iox_xml_data(ln_idx).tag_type  := 'D' ;
        iox_xml_data(ln_idx).tag_value := lv_crd_code_small ;
--
        -- タグセット     細群コードリスト    <lg_crd_detail>
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'lg_crd_detail' ;
        iox_xml_data(ln_idx).tag_type  := 'T' ;
--
      -- タグセット  細群コード                   <g_crd_detail>
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'g_crd_detail' ;
        iox_xml_data(ln_idx).tag_type  := 'T' ;
--
      -- データセット  細群コード                   <crd_code_detail>
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'crd_code_detail' ;
        iox_xml_data(ln_idx).tag_type  := 'D' ;
        iox_xml_data(ln_idx).tag_value := lv_crd_code_detail ;
--
      END IF;
--
      -- ===========================================================
      -- 前回細群コードと異なる場合、細群コードタグ、データセット
      -- ===========================================================
      IF (lv_crd_code_detail != lv_crowd_code_current) THEN
        --細群コードを代入
        lv_crd_code_detail := lv_crowd_code_current;
--
        -- 終了タグセット         </g_crd_detail>
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := '/g_crd_detail' ;
        iox_xml_data(ln_idx).tag_type  := 'T' ;
--
        -- ===========================================================
        -- 前回小群コードと異なる場合、小群コードタグ、データセット
        -- ===========================================================
        IF (lv_crd_code_small != SUBSTRB(lv_crowd_code_current,1,3)) THEN
          --小群コードを代入
          lv_crd_code_small := SUBSTRB(lv_crowd_code_current,1,3);
--
          -- 終了タグセット         </lg_crd_detail>
          ln_idx := iox_xml_data.COUNT + 1 ;
          iox_xml_data(ln_idx).tag_name  := '/lg_crd_detail' ;
          iox_xml_data(ln_idx).tag_type  := 'T' ;
--
          -- 終了タグセット       </g_crd_small>
          ln_idx := iox_xml_data.COUNT + 1 ;
          iox_xml_data(ln_idx).tag_name  := '/g_crd_small' ;
          iox_xml_data(ln_idx).tag_type  := 'T' ;
--
          -- ===========================================================
          -- 前回中群コードと異なる場合、中群コードタグ、データセット
          -- ===========================================================
          IF (lv_crd_code_middle != SUBSTRB(lv_crowd_code_current,1,2)) THEN
            --中群コードを代入
            lv_crd_code_middle := SUBSTRB(lv_crowd_code_current,1,2);
--
            -- 終了タグセット       </lg_crd_small>
            ln_idx := iox_xml_data.COUNT + 1 ;
            iox_xml_data(ln_idx).tag_name  := '/lg_crd_small' ;
            iox_xml_data(ln_idx).tag_type  := 'T' ;
--
            -- 終了タグセット     </g_crd_middle>
            ln_idx := iox_xml_data.COUNT + 1 ;
            iox_xml_data(ln_idx).tag_name  := '/g_crd_middle' ;
            iox_xml_data(ln_idx).tag_type  := 'T' ;
--
            -- ===========================================================
            -- 前回大群コードと異なる場合、大群コードタグ、データセット
            -- ===========================================================
            IF (lv_crd_code_big != SUBSTRB(lv_crowd_code_current,1,1)) THEN
              --大群コードを代入
              lv_crd_code_big := SUBSTRB(lv_crowd_code_current,1,1);
--
              -- 終了タグセット     </lg_crd_middle>
              ln_idx := iox_xml_data.COUNT + 1 ;
              iox_xml_data(ln_idx).tag_name  := '/lg_crd_middle' ;
              iox_xml_data(ln_idx).tag_type  := 'T' ;
--
              -- 終了タグセット   </g_crd_big>
              ln_idx := iox_xml_data.COUNT + 1 ;
              iox_xml_data(ln_idx).tag_name  := '/g_crd_big' ;
              iox_xml_data(ln_idx).tag_type  := 'T' ;
--
              -- ===========================================================
              -- 前回商品区分と異なる場合、商品区分タグ、データセット
              -- ===========================================================
              IF (lv_prod_div != lv_prod_div_current) THEN
                --商品区分を代入
                lv_prod_div := lv_prod_div_current;
--
                -- 終了タグセット   </lg_crd_big>
                ln_idx := iox_xml_data.COUNT + 1 ;
                iox_xml_data(ln_idx).tag_name  := '/lg_crd_big' ;
                iox_xml_data(ln_idx).tag_type  := 'T' ;
--
                -- データグループ名終了タグセット </g_prod>
                ln_idx := iox_xml_data.COUNT + 1 ;
                iox_xml_data(ln_idx).tag_name  := '/g_prod' ;
                iox_xml_data(ln_idx).tag_type  := 'T' ;
--
                -- データグループ名開始タグセット <g_prod>
                ln_idx := iox_xml_data.COUNT + 1 ;
                iox_xml_data(ln_idx).tag_name  := 'g_prod' ;
                iox_xml_data(ln_idx).tag_type  := 'T' ;
--
                -- データセット  商品区分           <prod_div>
                ln_idx := iox_xml_data.COUNT + 1 ;
                iox_xml_data(ln_idx).tag_name  := 'prod_div' ;
                iox_xml_data(ln_idx).tag_type  := 'D' ;
                iox_xml_data(ln_idx).tag_value := lv_prod_div ;
--
                -- データセット  商品区分名               <prod_div_name>
                ln_idx := iox_xml_data.COUNT + 1 ;
                iox_xml_data(ln_idx).tag_name  := 'prod_div_name' ;
                iox_xml_data(ln_idx).tag_type  := 'D' ;
                iox_xml_data(ln_idx).tag_value := lt_data_rec(i).prod_div_name ;
--
                -- 開始タグセット   <lg_crd_big>
                ln_idx := iox_xml_data.COUNT + 1 ;
                iox_xml_data(ln_idx).tag_name  := 'lg_crd_big' ;
                iox_xml_data(ln_idx).tag_type  := 'T' ;
--
              END IF;
--
              -- 開始タグセット   <g_crd_big>
              ln_idx := iox_xml_data.COUNT + 1 ;
              iox_xml_data(ln_idx).tag_name  := 'g_crd_big' ;
              iox_xml_data(ln_idx).tag_type  := 'T' ;
--
              -- データセット  群コード             <crd_code_big>
              ln_idx := iox_xml_data.COUNT + 1 ;
              iox_xml_data(ln_idx).tag_name  := 'crd_code_big' ;
              iox_xml_data(ln_idx).tag_type  := 'D' ;
              iox_xml_data(ln_idx).tag_value := lv_crd_code_big ;
--
            -- データグループ名開始タグセット      <lg_crd_middle>
            ln_idx := iox_xml_data.COUNT + 1 ;
            iox_xml_data(ln_idx).tag_name  := 'lg_crd_middle' ;
            iox_xml_data(ln_idx).tag_type  := 'T' ;
--
            END IF;
--
            -- データグループ名開始タグセット      <g_crd_middle>
            ln_idx := iox_xml_data.COUNT + 1 ;
            iox_xml_data(ln_idx).tag_name  := 'g_crd_middle' ;
            iox_xml_data(ln_idx).tag_type  := 'T' ;
--
            -- データセット  群コード               <gun_02>
            ln_idx := iox_xml_data.COUNT + 1 ;
            iox_xml_data(ln_idx).tag_name  := 'crd_code_middle' ;
            iox_xml_data(ln_idx).tag_type  := 'D' ;
            iox_xml_data(ln_idx).tag_value := lv_crd_code_middle ;
--
            -- データグループ名開始タグセット       <lg_crd_small>
            ln_idx := iox_xml_data.COUNT + 1 ;
            iox_xml_data(ln_idx).tag_name  := 'lg_crd_small' ;
            iox_xml_data(ln_idx).tag_type  := 'T' ;
--
          END IF;
--
--
          -- データグループ名開始タグセット       <g_crd_small>
          ln_idx := iox_xml_data.COUNT + 1 ;
          iox_xml_data(ln_idx).tag_name  := 'g_crd_small' ;
          iox_xml_data(ln_idx).tag_type  := 'T' ;
--
          -- データセット  群コード                 <crd_code_small>
          ln_idx := iox_xml_data.COUNT + 1 ;
          iox_xml_data(ln_idx).tag_name  := 'crd_code_small' ;
          iox_xml_data(ln_idx).tag_type  := 'D' ;
          iox_xml_data(ln_idx).tag_value := lv_crd_code_small ;
--
          -- 開始タグセット         <lg_crd_detail>
          ln_idx := iox_xml_data.COUNT + 1 ;
          iox_xml_data(ln_idx).tag_name  := 'lg_crd_detail' ;
          iox_xml_data(ln_idx).tag_type  := 'T' ;
--
        END IF;
--
        -- 開始タグセット         <g_crd_detail>
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'g_crd_detail' ;
        iox_xml_data(ln_idx).tag_type  := 'T' ;
--
        -- データセット  群コード                   <crd_code_detail>
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'crd_code_detail' ;
        iox_xml_data(ln_idx).tag_type  := 'D' ;
        iox_xml_data(ln_idx).tag_value := lv_crd_code_detail ;
--
      END IF;
--
      -- 開始タグセット           <g_item>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'g_item' ;
      iox_xml_data(ln_idx).tag_type  := 'T' ;
--
      -- データセット  群コード                   <crd_code>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'crd_code' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lv_crd_code_detail ;
--
      -- データセット  品目コード                 <item_code>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'item_code' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).item_code ;
--
      -- データセット  品目名称                   <item_name>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'item_name' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).item_name ;
--
      IF (ir_param_rec.output_unit = gc_output_unit_code_case) THEN 
        -- データセット  数量                       <quantity>
        IF (TO_NUMBER(lt_data_rec(i).in_case) = 0) THEN
          lv_errmsg  := xxcmn_common_pkg.get_msg(gv_msg_kbn   , gv_msg_num_10013
                                                ,'ITEM' , lt_data_rec(i).item_code || gv_ofcase_name
                                                );
          RAISE data_check_expt ;
        END IF;
--
        ln_quant := CEIL( TRUNC( 
                            lt_data_rec(i).forecast_quantity_new 
                            / TO_NUMBER( lt_data_rec(i).in_case )
                            , 1 )
                        ) ;
      ELSE 
        ln_quant := lt_data_rec(i).forecast_quantity_new ;
      END IF ;
--
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'quantity' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := ln_quant ;
--
      -- データセット  新.標準原価                 <n_cost_price>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'n_cost_price' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).cost_price_new ;
--
      -- データセット  新.原料費                 <n_row_material_cost>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'n_row_material_cost' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).row_material_cost_new ;
--
      -- データセット  新.再製費                 <n_remake_cost>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'n_remake_cost' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).remake_cost_new ;
--
      -- データセット  新.資材費                 <n_material_cost>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'n_material_cost' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).material_cost_new ;
--
      -- データセット  新.包装費                 <n_wrapping_cost>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'n_wrapping_cost' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).wrapping_cost_new ;
--
      -- データセット  新.外注管理費                 <n_outside_cost>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'n_outside_cost' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).outside_cost_new ;
--
      -- データセット  新.保管費                 <n_store_cost>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'n_store_cost' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).store_cost_new ;
--
      -- データセット  新.その他経費                 <n_other_cost>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'n_other_cost' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).other_cost_new ;
--
      -- データセット  旧.標準原価                 <o_cost_price>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'o_cost_price' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).cost_price_old ;
--
      -- データセット  旧.原料費                 <o_row_material_cost>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'o_row_material_cost' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).row_material_cost_old ;
--
      -- データセット  旧.再製費                 <o_remake_cost>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'o_remake_cost' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).remake_cost_old ;
--
      -- データセット  旧.資材費                 <o_material_cost>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'o_material_cost' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).material_cost_old ;
--
      -- データセット  旧.包装費                 <o_wrapping_cost>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'o_wrapping_cost' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).wrapping_cost_old ;
--
      -- データセット  旧.外注管理費                 <o_outside_cost>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'o_outside_cost' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).outside_cost_old ;
--
      -- データセット  旧.保管費                 <o_store_cost>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'o_store_cost' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).store_cost_old ;
--
      -- データセット  旧.その他経費                 <o_other_cost>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'o_other_cost' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).other_cost_old ;
--
      -- データセット  差.標準原価               <d_cost_price>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'd_cost_price' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).cost_price_new
                                        - lt_data_rec(i).cost_price_old ;
--
      -- データセット  差.原料費               <d_row_material_cost>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'd_row_material_cost' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).row_material_cost_new
                                        - lt_data_rec(i).row_material_cost_old ;
--
      -- データセット  差.再製費               <d_remake_cost>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'd_remake_cost' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).remake_cost_new
                                        - lt_data_rec(i).remake_cost_old ;
--
      -- データセット  差.資材費               <d_material_cost>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'd_material_cost' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).material_cost_new
                                        - lt_data_rec(i).material_cost_old ;
--
      -- データセット  差.包装費               <d_wrapping_cost>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'd_wrapping_cost' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).wrapping_cost_new
                                        - lt_data_rec(i).wrapping_cost_old ;
--
      -- データセット  差.外注管理費               <d_outside_cost>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'd_outside_cost' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).outside_cost_new
                                        - lt_data_rec(i).outside_cost_old ;
--
      -- データセット  差.保管費               <d_store_cost>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'd_store_cost' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).store_cost_new
                                        - lt_data_rec(i).store_cost_old ;
--
      -- データセット  差.その他経費               <d_other_cost>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'd_other_cost' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).other_cost_new
                                        - lt_data_rec(i).other_cost_old ;
--
      -- 終了タグセット           </g_item>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := '/g_item' ;
      iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    END LOOP main_data_loop;
--
    -- 商品区分リストタグセット   </g_crd_detail>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := '/g_crd_detail' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    -- 商品区分リストタグセット   </lg_crd_detail>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := '/lg_crd_detail' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    -- 商品区分リストタグセット   </g_crd_small>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := '/g_crd_small' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    -- 商品区分リストタグセット   </lg_crd_small>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := '/lg_crd_small' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    -- 商品区分リストタグセット   </g_crd_middle>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := '/g_crd_middle' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    -- 商品区分リストタグセット   </lg_crd_middle>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := '/lg_crd_middle' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    -- 商品区分リストタグセット   </g_crd_big>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := '/g_crd_big' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    -- 商品区分リストタグセット   </lg_crd_big>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := '/lg_crd_big' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    -- 商品区分リストタグセット   </g_prod>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := '/g_prod' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    -- 商品区分リストタグセット   </lg_prod>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := '/lg_prod' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    -- データグループ名開始タグセット   </data_info>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := '/data_info' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    -- データグループ名開始タグセット   </root>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := '/root' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
  EXCEPTION
    -- *** 取得データ０件 ***
    WHEN no_data_expt THEN
      ov_retcode := gv_status_warn ;
      ov_errmsg  := xxcmn_common_pkg.get_msg( gc_application_cmn
                                             ,gc_xxcmn_10122 ) ;
--
    WHEN data_check_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error ;
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
  END prc_create_xml;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_fiscal_year      IN  VARCHAR2     --    01.年度
   ,iv_generation       IN  VARCHAR2     --    02.世代
   ,iv_prod_div         IN  VARCHAR2     --    03.商品区分
   ,iv_crowd_code_01    IN  VARCHAR2     --    04.群コード1
   ,iv_crowd_code_02    IN  VARCHAR2     --    05.群コード2
   ,iv_crowd_code_03    IN  VARCHAR2     --    06.群コード3
   ,iv_crowd_code_04    IN  VARCHAR2     --    07.群コード4
   ,iv_crowd_code_05    IN  VARCHAR2     --    08.群コード5
   ,iv_output_unit      IN  VARCHAR2     --    09.出力単位
   ,ov_errbuf           OUT VARCHAR2     --    エラー・メッセージ           --# 固定 #
   ,ov_retcode          OUT VARCHAR2     --    リターン・コード             --# 固定 #
   ,ov_errmsg           OUT VARCHAR2     --    ユーザー・エラー・メッセージ --# 固定 #
   )
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
    xml_data_table   XML_DATA;
    lv_xml_string    VARCHAR2(32000);
    ln_retcode       NUMBER;
--
    -- *** ローカル変数 ***
    lr_param_rec            rec_param_data ;          -- パラメータ受渡し用
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================================
    -- 初期処理
    -- ===============================================
    lr_param_rec.output_unit    := iv_output_unit ;     -- 出力単位
    lr_param_rec.fiscal_year    := iv_fiscal_year ;     -- 対象年度
    lr_param_rec.generation     := iv_generation ;      -- 世代
    lr_param_rec.prod_div       := iv_prod_div ;        -- 商品区分
    lr_param_rec.crowd_code_01  := iv_crowd_code_01 ;   -- 群コード１
    lr_param_rec.crowd_code_02  := iv_crowd_code_02 ;   -- 群コード２
    lr_param_rec.crowd_code_03  := iv_crowd_code_03 ;   -- 群コード３
    lr_param_rec.crowd_code_04  := iv_crowd_code_04 ;   -- 群コード４
    lr_param_rec.crowd_code_05  := iv_crowd_code_05 ;   -- 群コード５
--
    -- ===============================================
    -- 帳票コンカレント実行
    -- ===============================================
    prc_create_xml
      (
        ir_param_rec      => lr_param_rec       -- 入力パラメータ群
       ,iox_xml_data      => xml_data_table
       ,ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ==================================================
    -- XML出力
    -- ==================================================
    IF (lv_retcode = gv_status_warn) THEN
      --0件XML作成
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis"?>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  <data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <lg_prod>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      <g_prod>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <lg_crd_big>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          <g_crd_big>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            <lg_crd_middle>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '              <g_crd_middle>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                <lg_crd_small>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                  <g_crd_small>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                    <lg_crd_detail>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                      <g_crd_detail>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                        <msg>***　データはありません　***</msg>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                      </g_crd_detail>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                    </lg_crd_detail>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                  </g_crd_small>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                </lg_crd_small>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '              </g_crd_middle>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            </lg_crd_middle>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          </g_crd_big>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        </lg_crd_big>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      </g_prod>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    </lg_prod>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  </data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
    ELSE
      output_xml(
        iox_xml_data   => xml_data_table,  -- XMLデータ
        ov_errbuf      => lv_errbuf,       -- エラー・メッセージ           --# 固定 #
        ov_retcode     => lv_retcode,      -- リターン・コード             --# 固定 #
        ov_errmsg      => lv_errmsg
        ) ;
      -- エラーハンドリング
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt ;
      END IF ;
--
    END IF;
--
    -- ======================================================
    -- エラー・メッセージセット
    -- ======================================================
    IF (lv_retcode = gv_status_warn) THEN
      -- 警告処理
      ov_retcode := lv_retcode ;
      ov_errmsg  := lv_errmsg ;
    END IF ;
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
  PROCEDURE main
    (
      errbuf                OUT    VARCHAR2         --   エラーメッセージ
     ,retcode               OUT    VARCHAR2         --   エラーコード
     ,iv_fiscal_year        IN     VARCHAR2         --   01 : 対象年度
     ,iv_generation         IN     VARCHAR2         --   02 : 世代
     ,iv_prod_div           IN     VARCHAR2         --   03 : 商品区分
     ,iv_output_unit        IN     VARCHAR2         --   04 : 出力単位
     ,iv_crowd_code_01      IN     VARCHAR2         --   05 : 群コード1
     ,iv_crowd_code_02      IN     VARCHAR2         --   06 : 群コード2
     ,iv_crowd_code_03      IN     VARCHAR2         --   07 : 群コード3
     ,iv_crowd_code_04      IN     VARCHAR2         --   08 : 群コード4
     ,iv_crowd_code_05      IN     VARCHAR2         --   09 : 群コード5
    )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
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
    submain
      (
        iv_fiscal_year    => iv_fiscal_year           -- 01 : 年度
       ,iv_generation     => iv_generation            -- 02 : 世代
       ,iv_prod_div       => iv_prod_div              -- 03 : 商品区分
       ,iv_crowd_code_01  => iv_crowd_code_01         -- 04 : 群コード1
       ,iv_crowd_code_02  => iv_crowd_code_02         -- 05 : 群コード2
       ,iv_crowd_code_03  => iv_crowd_code_03         -- 06 : 群コード3
       ,iv_crowd_code_04  => iv_crowd_code_04         -- 07 : 群コード4
       ,iv_crowd_code_05  => iv_crowd_code_05         -- 08 : 群コード5
       ,iv_output_unit    => iv_output_unit           -- 09 : 出力単位
       ,ov_errbuf         => lv_errbuf                -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode               -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg                -- ユーザー・エラー・メッセージ --# 固定 #
     ) ;
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
END xxcmn820004c;
/

