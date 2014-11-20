CREATE OR REPLACE
PACKAGE BODY xxinv510001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXINV510001C(body)
 * Description      : 移動伝票
 * MD.050/070       : 移動実績 T_MD050_BPO_510
 *                  : 移動伝票 T_MD070_BPO_51A
 * Version          : 1.3
 *
 * Program List
 * ---------------------------- ----------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------
 *  convert_into_xml            データ変換処理ファンクション
 *  output_xml                  XMLデータ出力処理プロシージャ
 *  prc_create_zeroken_xml_data 取得件数０件時ＸＭＬデータ作成
 *  create_xml_head             XMLデータ作成処理プロシージャ(ヘッダ部)
 *  create_xml_line             XMLデータ作成処理プロシージャ(明細部)
 *  create_xml_sum              XMLデータ作成処理プロシージャ(合計部)
 *  create_xml                  XMLデータ作成処理プロシージャ
 *  submain                     メイン処理プロシージャ
 *  main                        コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ------------------ -------------------------------------------------
 *  Date          Ver.  Editor             Description
 * ------------- ----- ------------------ -------------------------------------------------
 *  2008/03/05    1.0   Yuki Komikado      初回作成
 *  2008/05/26    1.1   Kazuo Kumamoto     結合テスト障害対応
 *  2008/05/28    1.2   Yuko Kawano        結合テスト障害対応
 *  2008/05/29    1.3   Yuko Kawano        結合テスト障害対応
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
  -- =====================================================
  -- ユーザー定義例外
  -- =====================================================
  data_check_expt           EXCEPTION ;           -- データチェックエクセプション
  data_none_expt            EXCEPTION ;           -- データチェックエクセプション
  no_data_expt              EXCEPTION ;
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 入力パラメータ格納用レコード変数
  TYPE rec_param_data IS RECORD 
    (
      product_class       VARCHAR2(2)   -- 01.製品識別区分(製品メニュー:1 製品メニュー以外:2)
     ,prod_class_code     VARCHAR2(2)   -- 02.商品区分
     ,target_class        VARCHAR2(3)   -- 03.指示/実績区分
     ,move_no             VARCHAR2(12)  -- 04.移動番号
     ,move_instr_post_cd  VARCHAR2(4)   -- 05.移動指示部署
     ,ship                NUMBER        -- 06.出庫元
     ,arrival             NUMBER        -- 07.入庫先
     ,ship_date_from      DATE          -- 08.出庫日FROM
     ,ship_date_to        DATE          -- 09.出庫日TO
     ,delivery_no         VARCHAR2(12)  -- 10.配送No.
    ) ;
--
  -- ヘッダ部データ格納用レコード変数
  TYPE rec_head_data IS RECORD 
    (
      move_number    xxinv_mov_req_instr_headers.mov_num%TYPE              -- 01.移動番号
     ,base_id        xxinv_mov_req_instr_headers.shipped_locat_code%TYPE   -- 02.出庫元(コード)
     ,base_value     xxcmn_item_locations2_v.description%TYPE              -- 03.出庫元
     ,in_id          xxinv_mov_req_instr_headers.ship_to_locat_code%TYPE   -- 04.入庫先(コード)
     ,in_value       xxcmn_item_locations2_v.description%TYPE              -- 05.入庫先
     ,out_date       xxinv_mov_req_instr_headers.actual_ship_date%TYPE     -- 06.出庫日
     ,arrive_date    xxinv_mov_req_instr_headers.actual_arrival_date%TYPE  -- 07.着日
     ,fare_code      xxcmn_lookup_values2_v.meaning%TYPE                   -- 08.運賃区分
     ,deliver_code   xxcmn_lookup_values2_v.meaning%TYPE                   -- 09.運送区分
     ,arr_code       xxinv_mov_req_instr_headers.batch_no%TYPE             -- 10.手配No
     ,trader_code    xxinv_mov_req_instr_headers.freight_carrier_code%TYPE -- 11.運送業者(コード)
     ,trader_name    xxcmn_carriers2_v.party_name%TYPE                     -- 12.運送業者
     ,summary_value  xxinv_mov_req_instr_headers.description%TYPE          -- 13.摘要
    ) ;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  gr_param            rec_param_data ;      -- パラメータ
  gr_head_data        rec_head_data  ;      -- ヘッダ用グローバル変数
  gv_pkg_name         CONSTANT VARCHAR2(100) := 'XXINV510001C' ;  -- パッケージ名
  gv_report_id        CONSTANT VARCHAR2(12)  := 'XXINV510001T' ;  -- プログラム名帳票出力用
  gv_status_out       CONSTANT VARCHAR2(2)   := '04';             -- ステータス 04:「出庫報告有」
  gv_status_in_out    CONSTANT VARCHAR2(2)   := '06';             -- ステータス 06:「入出庫報告有」
  gv_status_irai      CONSTANT VARCHAR2(2)   := '02';             -- ステータス 02:「依頼済」
  gv_status_chosei    CONSTANT VARCHAR2(2)   := '03';             -- ステータス 02:「調整中」
  gv_delete_flg       CONSTANT VARCHAR2(2)   := 'N';              -- 取消フラグ N:「OFF」
  gv_docu_type_mov    CONSTANT VARCHAR2(2)   := '20';             -- 文書タイプ 20:「移動」
  gv_rec_type_act     CONSTANT VARCHAR2(2)   := '20';             -- レコードタイプ 「出庫実績」
  gv_rec_type_si      CONSTANT VARCHAR2(2)   := '10';             -- レコードタイプ 「指示」
  gv_lookup_ship      CONSTANT VARCHAR2(100) := 'XXCMN_SHIP_METHOD';    
                                                 -- クイックコード.タイプ 「XXCMN_SHIP_METHOD」
  gv_lookup_presence  CONSTANT VARCHAR2(100) := 'XXINV_PRESENCE_CLASS'; 
                                                 -- クイックコード.タイプ 「XXINV_PRESENCE_CLASS」
  gv_actual_kbn       CONSTANT VARCHAR2(2)   := '20';             -- 指示/実績区分 「実績」
  gv_indicate_kbn     CONSTANT VARCHAR2(2)   := '10';             -- 指示/実績区分 「指示」
  gv_item_kbn_drink   CONSTANT VARCHAR2(2)   := '2';              -- 商品区分 1：リーフ、2：ドリンク
  gv_product_class    CONSTANT VARCHAR2(2)   := '1';              
                                                 -- 製品識別区分 1：製品、2：製品以外
  gv_attribute6       CONSTANT VARCHAR2(2)   := '1';              
                                                 -- 配送区分区分 小口区分(DFF) 1：対象
  gv_seihin           CONSTANT VARCHAR2(2)   := '5';              -- 品目区分 製品
  gv_hanseihin        CONSTANT VARCHAR2(2)   := '4';              -- 品目区分 半製品
  gv_genryou          CONSTANT VARCHAR2(2)   := '1';              -- 品目区分 原料
  gv_shizai           CONSTANT VARCHAR2(2)   := '2';              -- 品目区分 資材
  gc_application_cmn  CONSTANT VARCHAR2(5)   := 'XXCMN' ;         -- アプリケーション（XXCMN）
  gc_date_fmt_ymd     CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD' ;    -- 年月日
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_dept_cd            VARCHAR2(10) ;                             -- 担当部署
  gv_dept_nm            VARCHAR2(14) ;                             -- 担当者
  gv_postal_code        xxcmn_locations_all.zip%TYPE ;             -- 郵便番号
  gv_address_value      xxcmn_locations_all.address_line1%TYPE ;   -- 住所
  gv_tel_value          xxcmn_locations_all.phone%TYPE ;           -- 電話番号
  gv_fax_value          xxcmn_locations_all.fax%TYPE ;             -- FAX番号
  gv_cat_value          xxcmn_locations_all.location_name%TYPE ;   -- 部署名称
--
  ------------------------------
  -- ＸＭＬ用
  ------------------------------
  gt_xml_data_table         XML_DATA ;                -- ＸＭＬデータタグ表
  gl_xml_idx                NUMBER ;                  -- ＸＭＬデータタグ表のインデックス
--
  /**********************************************************************************
   * Function Name    : convert_into_xml
   * Description      : XMLデータ変換処理ファンクション
   ***********************************************************************************/
  FUNCTION convert_into_xml(
    iv_name              IN        VARCHAR2,      -- タグネーム
    iv_value             IN        VARCHAR2,      -- タグデータ
    ic_type              IN        CHAR           -- タグタイプ
  )RETURN VARCHAR2
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
    -- プログラム名
    cv_prg_name    CONSTANT VARCHAR2(100) := 'convert_into_xml' ;
--
    -- =====================================================
    -- ユーザー宣言部
    -- =====================================================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_convert_data         VARCHAR2(32000) ;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
    --データの場合
    IF (ic_type = 'D') THEN
      lv_convert_data := '<'||iv_name||'>'||iv_value||'</'||iv_name||'>' ;
    ELSE
      lv_convert_data := '<'||iv_name||'>' ;
    END IF ;
--
    RETURN(lv_convert_data) ;
--
  END convert_into_xml ;
--
  /**********************************************************************************
   * Procedure Name   : output_xml
   * Description      : XMLデータ出力処理プロシージャ
   ***********************************************************************************/
  PROCEDURE output_xml(
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
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
    -- XMLヘッダ出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<?xml version="1.0" encoding="shift_jis" ?>') ;
--
    -- XMLデータ部出力
    <<xml_loop>>
    FOR i IN 1 .. gt_xml_data_table.COUNT LOOP
      lv_xml_string := convert_into_xml(
                         gt_xml_data_table(i).tag_name
                        ,gt_xml_data_table(i).tag_value
                        ,gt_xml_data_table(i).tag_type) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_xml_string) ;
    END LOOP xml_loop ;
--
    -- XMLデータ(Temp)削除
    gt_xml_data_table.DELETE ;
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
   * Procedure Name   : create_xml_head
   * Description      : XMLデータ作成処理プロシージャ(ヘッダ部)
   ***********************************************************************************/
  PROCEDURE create_xml_head (
    ov_errbuf            OUT       VARCHAR2,        -- エラー・メッセージ           --# 固定 #
    ov_retcode           OUT       VARCHAR2,        -- リターン・コード             --# 固定 #
    ov_errmsg            OUT       VARCHAR2)        -- ユーザー・エラー・メッセージ --# 固定 #
  IS
--
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'create_xml_head' ; -- プログラム名
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
--
    -- *** ローカル変数 ***
--
  BEGIN
--
    -- =====================================================
    -- ユーザーデータセット
    -- =====================================================
--
    -- データグループ名開始データセット   <g_denpyo>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'g_denpyo' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- データセット                     <report_id>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'report_id' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gv_report_id ;
--
    -- データセット                     <exec_date>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_date' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( SYSDATE, 'YYYY/MM/DD HH24:MI:SS' ) ;
--
    -- データセット   <address_value>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'address_value' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gv_address_value;
--
    -- データセット   <tel_value>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'tel_value' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gv_tel_value;
--
    -- データセット   <fax_value>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'fax_value' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gv_fax_value;
--
    -- データセット   <cat_id>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'cat_id' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gv_dept_cd;
--
    -- データセット   <cat_value>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'cat_value' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gv_cat_value;
--
    -- データセット                     <move_number>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'move_number' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gr_head_data.move_number ;
--
    -- データセット                     <base_id>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'base_id' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gr_head_data.base_id ;
--
    -- データセット   <base_value>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'base_value' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gr_head_data.base_value ;
--
    -- データセット   <in_id>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'in_id' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gr_head_data.in_id ;
--
    -- データセット   <in_value>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'in_value' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gr_head_data.in_value ;
--
    -- データセット   <out_date>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'out_date' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( gr_head_data.out_date, 'YYYY/MM/DD' ) ;
--
    -- データセット   <arrive_date>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'arrive_date' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( gr_head_data.arrive_date, 'YYYY/MM/DD' ) ;
--
    -- データセット   <fare_code>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'fare_code' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gr_head_data.fare_code ;
--
    -- データセット   <deliver_code>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'deliver_code' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gr_head_data.deliver_code ;
--
    -- データセット   <arr_code>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'arr_code' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gr_head_data.arr_code ;
--
    -- データセット   <trader_code>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'trader_code' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gr_head_data.trader_code ;
--
    -- データセット   <trader_name>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'trader_name' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gr_head_data.trader_name ;
--
    -- データセット   <summary_value>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'summary_value' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gr_head_data.summary_value;
--
    -- =====================================================
    -- 明細データセット
    -- =====================================================
    -- データグループ名開始タグセット   <lg_item_info>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
  EXCEPTION
    WHEN data_check_expt THEN
      ov_errmsg  := lv_errmsg ;                                           --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error ;                                     --# 任意 #
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
--#####################################  固定部 END   ##########################################
--
  END create_xml_head ;
--
  /**********************************************************************************
   * Procedure Name   : prc_create_zeroken_xml_data
   * Description      : 取得件数０件時ＸＭＬデータ作成
   ***********************************************************************************/
  PROCEDURE prc_create_zeroken_xml_data
    (
      ov_errbuf         OUT VARCHAR2          -- エラー・メッセージ            --# 固定 #
     ,ov_retcode        OUT VARCHAR2          -- リターン・コード              --# 固定 #
     ,ov_errmsg         OUT VARCHAR2          -- ユーザー・エラー・メッセージ  --# 固定 #
    )
  IS
--
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_create_zeroken_xml_data' ; -- プログラム名
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
--
  BEGIN
--
    -- =====================================================
    -- 項目データ抽出・出力処理
    -- =====================================================
    -- -----------------------------------------------------
    -- 明細Ｇ開始タグ出力
    -- -----------------------------------------------------
--
    -- ヘッダデータ出力
    create_xml_head(
     lv_errbuf              -- エラー・メッセージ           --# 固定 #
    ,lv_retcode             -- リターン・コード             --# 固定 #
    ,lv_errmsg) ;           -- ユーザー・エラー・メッセージ --# 固定 #
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    ------------------------------
    -- メッセージ出力タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'msg';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := xxcmn_common_pkg.get_msg( gc_application_cmn
                                                                        ,'APP-XXCMN-10122'  ) ;
--
    ------------------------------
    -- 明細ＬＧ終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_denpyo';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
  EXCEPTION
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
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
  END prc_create_zeroken_xml_data ;
--
  /**********************************************************************************
   * Procedure Name   : create_xml_line
   * Description      : XMLデータ作成処理プロシージャ(明細部)
   ***********************************************************************************/
  PROCEDURE create_xml_line (
    iv_article_code       IN       VARCHAR2,        -- 01:品目（コード）
    iv_article_name       IN       VARCHAR2,        -- 02:品目名称
    iv_lot_number         IN       VARCHAR2,        -- 03:ロットNo
    iv_make_date          IN       VARCHAR2,        -- 04:製造日
    iv_sign               IN       VARCHAR2,        -- 05:固有記号
    in_stock              IN       NUMBER,          -- 06:在庫入数
    in_amount             IN       NUMBER,          -- 07:数量
    iv_unit               IN       VARCHAR2,        -- 08:単位
    ov_errbuf            OUT       VARCHAR2,        -- エラー・メッセージ           --# 固定 #
    ov_retcode           OUT       VARCHAR2,        -- リターン・コード             --# 固定 #
    ov_errmsg            OUT       VARCHAR2)        -- ユーザー・エラー・メッセージ --# 固定 #
  IS
--
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'create_xml_line' ; -- プログラム名
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
--
    -- *** ローカル変数 ***
--
    gl_xml_idx           NUMBER      := 0 ;    -- XML出力ライン格納用
--
  BEGIN
--
    -- データグループ名開始タグセット   <g_item>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- データセット                     <article_code>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'article_code' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := iv_article_code ;
--
    -- データセット                     <article_name>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'article_name' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := iv_article_name ;
--
    -- データセット                     <lot_number>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lot_number' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := iv_lot_number ;
--
    -- データセット                     <make_date>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'make_date' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(TO_DATE(iv_make_date, 
                                                       gc_date_fmt_ymd), gc_date_fmt_ymd) ;
--
    -- データセット                     <sign>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'sign' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := iv_sign ;
--
    -- データセット                     <stock>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'stock' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := in_stock ;
--
    -- データセット                     <amount>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'amount' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := in_amount ;
--
    -- データセット                     <unit>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'unit' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := iv_unit ;
--
    -- データグループ名終了タグセット   </g_item>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
  EXCEPTION
    WHEN data_check_expt THEN
      ov_errmsg  := lv_errmsg ;                                           --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error ;                                     --# 任意 #
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
--#####################################  固定部 END   ##########################################
--
  END create_xml_line ;
--
  /**********************************************************************************
   * Procedure Name   : create_xml_sum
   * Description      : XMLデータ作成処理プロシージャ(合計部)
   ***********************************************************************************/
  PROCEDURE create_xml_sum (
    in_amount_sum         IN    NUMBER,          -- 01.合計数量
    in_volume_sum         IN    NUMBER,          -- 02.合計体積
    in_weight_sum         IN    NUMBER,          -- 03.合計重量
    ov_errbuf            OUT    VARCHAR2,        -- エラー・メッセージ           --# 固定 #
    ov_retcode           OUT    VARCHAR2,        -- リターン・コード             --# 固定 #
    ov_errmsg            OUT    VARCHAR2)        -- ユーザー・エラー・メッセージ --# 固定 #
  IS
--
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'create_xml_sum' ; -- プログラム名
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
--
    -- *** ローカル変数 ***
--
    gl_xml_idx           NUMBER      := 0 ;    -- XML出力ライン格納用
--
  BEGIN
  -- =====================================================
  -- データセット
  -- =====================================================
--
    -- データグループ名終了タグセット   </lg_item_info>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
  -- データセット                     <amount_sum>
  gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
  gt_xml_data_table(gl_xml_idx).tag_name  := 'amount_sum' ;
  gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
  gt_xml_data_table(gl_xml_idx).tag_value := in_amount_sum;
--
  -- データセット                     <volume_sum>
  gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
  gt_xml_data_table(gl_xml_idx).tag_name  := 'volume_sum' ;
  gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
  gt_xml_data_table(gl_xml_idx).tag_value := in_volume_sum;
--
  -- データセット                     <weight_sum>
  gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
  gt_xml_data_table(gl_xml_idx).tag_name  := 'weight_sum' ;
  gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
  gt_xml_data_table(gl_xml_idx).tag_value := in_weight_sum;
--
    -- データグループ名終了タグセット   </g_denpyo>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_denpyo' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
  EXCEPTION
    WHEN data_check_expt THEN
      ov_errmsg  := lv_errmsg ;                                           --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error ;                                     --# 任意 #
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
--#####################################  固定部 END   ##########################################
--
  END create_xml_sum ;
--
  /**********************************************************************************
   * Procedure Name   : create_xml
   * Description      : XMLデータ作成処理プロシージャ
   ***********************************************************************************/
  PROCEDURE create_xml (
    on_xml_data_count    OUT       NUMBER,
    ov_errbuf            OUT       VARCHAR2,        -- エラー・メッセージ           --# 固定 #
    ov_retcode           OUT       VARCHAR2,        -- リターン・コード             --# 固定 #
    ov_errmsg            OUT       VARCHAR2)        -- ユーザー・エラー・メッセージ --# 固定 #
  IS
--
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'create_xml' ; -- プログラム名
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
--
    -- *** ローカル変数 ***
    lv_summary_value VARCHAR2(60);
    ln_stock         NUMBER;
    ln_amount_sum    NUMBER;
    ln_volume_sum    NUMBER;
    ln_weight_sum    NUMBER;
    xml_data_count   NUMBER;
    lv_move_number   xxinv_mov_req_instr_headers.mov_num%TYPE;  -- 移動番号
--
    -- ==================================================
    -- カーソル宣言
    -- ==================================================
    -- 実績
    CURSOR get_actual_cur
     (
      cur_mov_num                 VARCHAR2
     ,cur_instruction_post_code   VARCHAR2
     ,cur_shipped_locat_id        NUMBER
     ,cur_ship_to_locat_id        NUMBER
     ,cur_delivery_no             VARCHAR2
     ,cur_product_flg             VARCHAR2
     ,cur_item_class              VARCHAR2
     ,cur_actual_ship_dt_from     DATE
     ,cur_actual_ship_dt_to       DATE
     )
    IS
    SELECT xmrih.mov_num                      AS mov_num                      -- 01:移動番号
          ,xmrih.shipped_locat_code           AS shipped_locat_code           -- 02:出庫元保管場所
          ,xil2v1.description                 AS description1                 -- 03:摘要
          ,xmrih.ship_to_locat_code           AS ship_to_locat_code           -- 04:入庫先保管場所
          ,xil2v2.description                 AS description2                 -- 05:摘要
          ,xmrih.actual_ship_date             AS actual_ship_date             -- 06:出庫実績日
          ,xmrih.actual_arrival_date          AS actual_arrival_date          -- 07:入庫実績日
          ,xlv2v2.meaning                     AS freight_charge_class         -- 08:運賃区分
          ,xmrih.actual_freight_carrier_code  AS actual_freight_carrier_code  -- 09:運送業者_実績
          ,xc2v.party_name                    AS party_name                   -- 10:正式名
          ,xmrih.actual_shipping_method_code  AS actual_shipping_method_code  -- 11:配送区分_実績
          ,xlv2v1.meaning                     AS meaning                      -- 12:内容
          ,xmrih.description                  AS description3                 -- 13:摘要
          ,xmril.item_code                    AS item_code                    -- 14:品目
          ,xim2v.item_short_name              AS item_short_name              -- 15:略称
          ,xmld.lot_no                        AS lot_no                       -- 16:ロットNO
          ,ilm.attribute1                     AS attribute1                   -- 17:DFF1
          ,ilm.attribute2                     AS attribute2                   -- 18:DFF2
          ,xim2v.num_of_cases                 AS num_of_cases                 -- 19:ケース入数
          ,xim2v.frequent_qty                 AS frequent_qty                 -- 20:代表入数
          ,ilm.attribute6                     AS attribute6                   -- 21:在庫入数
          ,xmld.actual_quantity               AS actual_quantity              -- 22:実績数量
          ,xim2v.item_um                      AS uom_code                     -- 23:単位
          ,xmrih.sum_capacity                 AS sum_capacity                 -- 24:積載容積合計
          ,xmrih.sum_weight                   AS sum_weight                   -- 25:積載重量合計
          ,xic4v.item_class_code              AS segment1                     -- 26:セグメント1
          ,xmrih.batch_no                     AS batch_no                     -- 27:手配No
          ,xmrih.sum_pallet_weight            AS sum_pallet_weight            -- 28:合計パレット重量
          ,xlv2v1.attribute6                  AS koguchi                      -- 29:小口区分
    FROM   xxinv_mov_req_instr_headers xmrih     -- 移動依頼/指示ヘッダ(アドオン)
          ,xxinv_mov_req_instr_lines   xmril     -- 移動依頼/指示明細(アドオン)
          ,xxinv_mov_lot_details       xmld      -- 移動ロット詳細(アドオン)
          ,ic_lots_mst                 ilm       -- OPMロットマスタ
          ,xxcmn_item_categories4_v    xic4v     -- OPM品目カテゴリ割当情報VIEW4
          ,xxcmn_item_mst2_v           xim2v     -- OPM品目マスタ
          ,xxcmn_carriers2_v           xc2v      -- 運送業者情報VIEW2(パーティサイトアドオン)
          ,xxcmn_item_locations2_v     xil2v1    -- OPM保管場所情報VIEW
          ,xxcmn_item_locations2_v     xil2v2    -- OPM保管場所情報VIEW
          ,xxcmn_lookup_values2_v      xlv2v1    -- クイックコード情報VIEW2
          ,xxcmn_lookup_values2_v      xlv2v2    -- クイックコード情報VIEW2
    WHERE 
    ------------------------------------------------------------------------
    -- 03:OPM保管場所マスタ.摘要条件
          xmrih.shipped_locat_id  = xil2v1.inventory_location_id
    AND   xil2v1.date_from        <= xmrih.actual_ship_date
    AND ( xil2v1.date_to IS NULL 
          OR
          xil2v1.date_to >= xmrih.actual_ship_date
        )
    -- 05:OPM保管場所マスタ.摘要条件
    AND   xmrih.ship_to_locat_id  = xil2v2.inventory_location_id
    AND   TRUNC( xil2v2.date_from ) <= TRUNC( xmrih.actual_ship_date )
    AND ( TRUNC( xil2v2.date_to ) IS NULL 
          OR
          TRUNC( xil2v2.date_to ) >= TRUNC( xmrih.actual_ship_date )
        )
    -- 10:パーティサイトアドオン.正式名条件
--mod start 1.1
--    AND   xmrih.career_id         = xc2v.party_id
--    AND   TRUNC( xc2v.start_date_active ) <= TRUNC( xmrih.actual_ship_date )
--2008.05.29 modify start
--    AND   xmrih.career_id         = xc2v.party_id(+)
    AND   xmrih.actual_career_id    = xc2v.party_id(+)
--2008.05.29 modify start
    AND   TRUNC( xc2v.start_date_active(+) ) <= TRUNC( xmrih.actual_ship_date )
--mod end 1.1
    AND ( TRUNC( xc2v.end_date_active ) IS NULL
          OR
          TRUNC( xc2v.end_date_active )   >= TRUNC( xmrih.actual_ship_date )
        )
    ------------------------------------------------------------------------
    -- 12:クイックコード.内容条件
--mod start 1.1
--    AND   xlv2v1.lookup_code = xmrih.actual_shipping_method_code
--    AND   xlv2v1.lookup_type = gv_lookup_ship                -- クイックコード「XXCMN_SHIP_METHOD」
    AND   xlv2v1.lookup_code(+) = xmrih.actual_shipping_method_code
    AND   xlv2v1.lookup_type(+) = gv_lookup_ship                -- クイックコード「XXCMN_SHIP_METHOD」
--mod end 1.1
    AND ( TRUNC( xlv2v1.start_date_active ) IS NULL 
          OR
          TRUNC( xlv2v1.start_date_active ) <= TRUNC( xmrih.actual_ship_date )
        )                          
    AND ( TRUNC( xlv2v1.end_date_active ) IS NULL 
          OR
          TRUNC( xlv2v1.end_date_active ) >= TRUNC( xmrih.actual_ship_date )
        )                          
    -------------------------------------------------------------------------
    -- 08:クイックコード.有無区分
--mod start 1.1
--    AND   xlv2v2.lookup_code = xmrih.freight_charge_class
--    AND   xlv2v2.lookup_type = gv_lookup_presence
    AND   xlv2v2.lookup_code(+) = xmrih.freight_charge_class
    AND   xlv2v2.lookup_type(+) = gv_lookup_presence
--mod end 1.1
                                                           -- クイックコード「XXINV_PRESENCE_CLASS」
    AND ( TRUNC( xlv2v2.start_date_active ) IS NULL 
          OR
          TRUNC( xlv2v2.start_date_active ) <= TRUNC( xmrih.actual_ship_date )
        )                          
    AND ( TRUNC( xlv2v2.end_date_active ) IS NULL 
          OR
          TRUNC( xlv2v2.end_date_active ) >= TRUNC( xmrih.actual_ship_date )
        )                          
    -------------------------------------------------------------------------
    -- 絞込み条件
    --入力パラメータ：移動番号が入力済の場合
    AND   (( cur_mov_num IS NULL ) OR ( cur_mov_num = xmrih.mov_num ))
    --入力パラメータ：移動指示部署が入力済の場合
    AND   (( cur_instruction_post_code IS NULL ) 
             OR
           ( cur_instruction_post_code = xmrih.instruction_post_code )
          )
    --入力パラメータ：出庫元が入力済の場合
    AND   (( cur_shipped_locat_id IS NULL ) OR ( cur_shipped_locat_id = xmrih.shipped_locat_id ))
    --入力パラメータ：入庫先が入力済の場合
    AND   (( cur_ship_to_locat_id IS NULL ) OR ( cur_ship_to_locat_id = xmrih.ship_to_locat_id ))
    AND   (TRUNC( xmrih.actual_ship_date ) >= TRUNC( cur_actual_ship_dt_from )
           AND 
           TRUNC( xmrih.actual_ship_date ) <= TRUNC( cur_actual_ship_dt_to ))
    --入力パラメータ：配送№が入力済の場合
    AND   (( cur_delivery_no IS NULL ) OR ( cur_delivery_no = xmrih.delivery_no ))
    AND   xmrih.status                IN (gv_status_out, gv_status_in_out)
                                                         -- 04:「出庫報告有」OR 06:「入出庫報告有」
    AND   xmrih.product_flg           = cur_product_flg
    AND   xmrih.item_class            = cur_item_class
    AND   xmrih.mov_hdr_id            = xmril.mov_hdr_id
    AND   xmril.delete_flg            = gv_delete_flg               -- N:「OFF」
    AND   xmril.mov_line_id           = xmld.mov_line_id
    AND   xmld.document_type_code     = gv_docu_type_mov            -- 20:「移動」
    AND   xmld.record_type_code       = gv_rec_type_act             -- 「出庫実績」
    AND   xmld.lot_id                 = ilm.lot_id
    AND   xmril.item_id               = ilm.item_id
    AND   xmril.item_id               = xic4v.item_id
    AND   xmril.item_id               = xim2v.item_id
    AND   ( TRUNC( xim2v.start_date_active ) IS NULL
            OR
            TRUNC( xim2v.start_date_active ) <= TRUNC( xmrih.actual_ship_date )
          )
    AND   ( TRUNC( xim2v.end_date_active ) IS NULL
            OR 
            TRUNC( xim2v.end_date_active ) >= TRUNC( xmrih.actual_ship_date )
          )
    ORDER BY 
       xmrih.mov_num
      ,xmril.item_code
      ,(CASE 
          WHEN xic4v.item_class_code = gv_seihin THEN
            ilm.attribute1
          ELSE NULL
        END )
      ,(CASE 
          WHEN xic4v.item_class_code = gv_seihin THEN
            ilm.attribute2
          ELSE NULL
        END )
      ,(CASE 
          WHEN xic4v.item_class_code <> gv_seihin THEN
            ilm.lot_no
          ELSE NULL
        END )
    ;
--
    --指示
    CURSOR get_indicate_cur
    (
      cur_mov_num                 VARCHAR2
     ,cur_instruction_post_code   VARCHAR2
     ,cur_shipped_locat_id        NUMBER
     ,cur_ship_to_locat_id        NUMBER
     ,cur_delivery_no             VARCHAR2
     ,cur_product_flg             VARCHAR2
     ,cur_item_class              VARCHAR2
     ,cur_schedule_ship_dt_from   DATE
     ,cur_schedule_ship_dt_to     DATE
    )
    IS
    SELECT xmrih.mov_num                      AS  mov_num               -- 01:移動番号
          ,xmrih.shipped_locat_code           AS  shipped_locat_code    -- 02:出庫元保管場所
          ,xil2v1.description                 AS  description1          -- 03:摘要
          ,xmrih.ship_to_locat_code           AS  ship_to_locat_code    -- 04:入庫先保管場所
          ,xil2v2.description                 AS  description2          -- 05:摘要
--2008.05.28 modify start
--          ,xmrih.actual_ship_date             AS  schedule_ship_date    -- 06:出庫予定日
--          ,xmrih.actual_arrival_date          AS  schedule_arrival_date -- 07:入庫予定日
          ,xmrih.schedule_ship_date           AS  schedule_ship_date    -- 06:出庫予定日
          ,xmrih.schedule_arrival_date        AS  schedule_arrival_date -- 07:入庫予定日
--2008.05.28 modify end
          ,xlv2v2.meaning                     AS  freight_charge_class  -- 08:運賃区分
          ,xmrih.freight_carrier_code         AS  freight_carrier_code  -- 09:運送業者
          ,xc2v.party_name                    AS  party_name            -- 10:正式名
          ,xmrih.shipping_method_code         AS  shipping_method_code  -- 11:配送区分
          ,xlv2v1.meaning                     AS  meaning               -- 12:内容
          ,xmrih.description                  AS  description3          -- 13:摘要
          ,xmril.item_code                    AS  item_code             -- 14:品目
          ,xim2v.item_short_name              AS  item_short_name       -- 15:略称
          ,ilm.lot_no                         AS  lot_no                -- 16:ロットNO
          ,ilm.attribute1                     AS  attribute1            -- 17:DFF1
          ,ilm.attribute2                     AS  attribute2            -- 18:DFF2
          ,xim2v.num_of_cases                 AS  num_of_cases          -- 19:ケース入数
          ,xim2v.frequent_qty                 AS  frequent_qty          -- 20:代表入数
          ,ilm.attribute6                     AS  attribute6            -- 21:在庫入数
          ,xmld.actual_quantity               AS  actual_quantity       -- 22:実績数量
          ,xim2v.item_um                      AS  uom_code              -- 23:単位
          ,xmrih.sum_capacity                 AS  sum_capacity          -- 24:積載容積合計
          ,xmrih.sum_weight                   AS  sum_weight            -- 25:積載重量合計
          ,xic4v.item_class_code              AS  segment1              -- 26:セグメント1
          ,xmrih.batch_no                     AS  batch_no              -- 27:手配No
          ,xmrih.sum_pallet_weight            AS  sum_pallet_weight     -- 28:合計パレット重量
          ,xlv2v1.attribute6                  AS  koguchi               -- 29:小口区分
    FROM   xxinv_mov_req_instr_headers xmrih     -- 移動依頼/指示ヘッダ(アドオン)
          ,xxinv_mov_req_instr_lines   xmril     -- 移動依頼/指示明細(アドオン)
          ,xxinv_mov_lot_details       xmld      -- 移動ロット詳細(アドオン)
          ,ic_lots_mst                 ilm       -- OPMロットマスタ
          ,xxcmn_item_categories4_v    xic4v     -- OPM品目カテゴリ割当情報VIEW4
          ,xxcmn_item_mst2_v           xim2v     -- OPM品目マスタ
          ,xxcmn_carriers2_v           xc2v      -- 運送業者情報VIEW2(パーティサイトアドオン)
          ,xxcmn_item_locations2_v     xil2v1    -- OPM保管場所情報VIEW
          ,xxcmn_item_locations2_v     xil2v2    -- OPM保管場所情報VIEW
          ,xxcmn_lookup_values2_v      xlv2v1    -- クイックコード情報VIEW2
          ,xxcmn_lookup_values2_v      xlv2v2    -- クイックコード情報VIEW2
    WHERE 
    ------------------------------------------------------------------------
    -- 03:OPM保管場所マスタ.摘要条件
          xmrih.shipped_locat_id  = xil2v1.inventory_location_id
    AND   xil2v1.date_from        <= xmrih.schedule_ship_date
    AND ( xil2v1.date_to IS NULL 
          OR
          xil2v1.date_to >= xmrih.schedule_ship_date
        )
    -- 05:OPM保管場所マスタ.摘要条件
    AND   xmrih.ship_to_locat_id  = xil2v2.inventory_location_id
    AND   xil2v2.date_from        <= xmrih.schedule_ship_date
    AND ( xil2v2.date_to IS NULL 
          OR
          xil2v2.date_to >= xmrih.schedule_ship_date
        )
    -- 10:パーティサイトアドオン.正式名条件
--mod start 1.1
--    AND   xmrih.career_id         = xc2v.party_id
--    AND   TRUNC( xc2v.start_date_active ) <= TRUNC( xmrih.schedule_ship_date )
    AND   xmrih.career_id         = xc2v.party_id(+)
    AND   TRUNC( xc2v.start_date_active(+) ) <= TRUNC( xmrih.schedule_ship_date )
--mod end 1.1
    AND ( TRUNC( xc2v.end_date_active ) IS NULL
          OR
          TRUNC( xc2v.end_date_active )   >= TRUNC( xmrih.schedule_ship_date )
        )
    ------------------------------------------------------------------------
    -- 12:クイックコード.内容条件
--mod start 1.1
--    AND   xlv2v1.lookup_code = xmrih.shipping_method_code
--    AND   xlv2v1.lookup_type = gv_lookup_ship                 -- クイックコード「XXCMN_SHIP_METHOD」
    AND   xlv2v1.lookup_code(+) = xmrih.shipping_method_code
    AND   xlv2v1.lookup_type(+) = gv_lookup_ship                 -- クイックコード「XXCMN_SHIP_METHOD」
--mod end 1.1
    AND ( xlv2v1.start_date_active IS NULL 
          OR
          xlv2v1.start_date_active <= xmrih.schedule_ship_date
        )                          
    AND ( xlv2v1.end_date_active IS NULL 
          OR
          xlv2v1.end_date_active >= xmrih.schedule_ship_date
        )                          
    ------------------------------------------------------------------------
    -- 08:クイックコード.有無区分
--mod start 1.1
--    AND   xlv2v2.lookup_code = xmrih.freight_charge_class
--    AND   xlv2v2.lookup_type = gv_lookup_presence                   
    AND   xlv2v2.lookup_code(+) = xmrih.freight_charge_class
    AND   xlv2v2.lookup_type(+) = gv_lookup_presence                   
--mod end 1.1
                                                           -- クイックコード「XXINV_PRESENCE_CLASS」
    AND ( xlv2v2.start_date_active IS NULL 
          OR
          xlv2v2.start_date_active <= xmrih.schedule_ship_date
        )                          
    AND ( xlv2v2.end_date_active IS NULL 
          OR
          xlv2v2.end_date_active >= xmrih.schedule_ship_date
        )                          
    -------------------------------------------------------------------------
    -- 絞込み条件
    --入力パラメータ：移動番号が入力済の場合
    AND   (( cur_mov_num IS NULL ) OR ( cur_mov_num = xmrih.mov_num ))
    --入力パラメータ：移動指示部署が入力済の場合
    AND   (( cur_instruction_post_code IS NULL )
             OR
           ( cur_instruction_post_code = xmrih.instruction_post_code ))
    --入力パラメータ：出庫元が入力済の場合
    AND   (( cur_shipped_locat_id IS NULL ) OR ( cur_shipped_locat_id = xmrih.shipped_locat_id ))
    --入力パラメータ：入庫先が入力済の場合
    AND   (( cur_ship_to_locat_id IS NULL ) OR ( cur_ship_to_locat_id = xmrih.ship_to_locat_id ))
    AND   ( xmrih.schedule_ship_date     >= TRUNC( cur_schedule_ship_dt_from )
            AND 
            xmrih.schedule_ship_date <= TRUNC( cur_schedule_ship_dt_to ) )
    --入力パラメータ：配送№が入力済の場合
    AND   (( cur_delivery_no IS NULL ) OR ( cur_delivery_no = xmrih.delivery_no ))
    AND   xmrih.status                IN (gv_status_irai, gv_status_chosei, gv_status_out)
                                                -- 02:「依頼済」OR 03:「調整中」OR 04:「入庫報告有」
    AND   xmrih.product_flg           = cur_product_flg
    AND   xmrih.item_class            = cur_item_class
    AND   xmrih.mov_hdr_id            = xmril.mov_hdr_id
    AND   xmril.delete_flg            = gv_delete_flg               -- N:「OFF」
    AND   xmril.mov_line_id           = xmld.mov_line_id
    AND   xmld.document_type_code     = gv_docu_type_mov            -- 20:「移動」
    AND   xmld.record_type_code       = gv_rec_type_si              -- 「指示」
    AND   xmld.lot_id                 = ilm.lot_id
    AND   xmril.item_id               = ilm.item_id
    AND   xmril.item_id               = xic4v.item_id
    AND   xmril.item_id               = xim2v.item_id
    AND   ( TRUNC( xim2v.start_date_active ) IS NULL
            OR
            TRUNC( xim2v.start_date_active ) <= TRUNC( xmrih.schedule_ship_date )
          )
    AND   ( TRUNC( xim2v.end_date_active ) IS NULL
            OR 
            TRUNC( xim2v.end_date_active ) >= TRUNC( xmrih.schedule_ship_date )
          )
    ORDER BY 
       xmrih.mov_num
      ,xmril.item_code
      ,(CASE 
          WHEN xic4v.item_class_code = gv_seihin THEN
            ilm.attribute1
          ELSE NULL
        END )
      ,(CASE 
          WHEN xic4v.item_class_code = gv_seihin THEN
            ilm.attribute2
          ELSE NULL
        END )
      ,(CASE 
          WHEN xic4v.item_class_code <> gv_seihin THEN
            ilm.lot_no
          ELSE NULL
        END )
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
    -- 変数の初期化
    gr_head_data.move_number        := NULL ;  -- 移動番号
    gr_head_data.base_id            := NULL ;  -- 出庫元(コード)
    gr_head_data.base_value         := NULL ;  -- 出庫元
    gr_head_data.in_id              := NULL ;  -- 入庫先(コード)
    gr_head_data.in_value           := NULL ;  -- 入庫先
    gr_head_data.out_date           := NULL ;  -- 出庫日
    gr_head_data.arrive_date        := NULL ;  -- 着日
    gr_head_data.fare_code          := NULL ;  -- 運賃区分
    gr_head_data.deliver_code       := NULL ;  -- 運送区分
    gr_head_data.arr_code           := NULL ;  -- 手配No
    gr_head_data.trader_code        := NULL ;  -- 運送業者(コード)
    gr_head_data.trader_name        := NULL ;  -- 運送業者
    xml_data_count                  := 0 ;     -- 取得データ件数
    lv_move_number                  := NULL ;  -- 移動番号
--
    -- ====================================================
    -- 担当者情報取得
    -- ====================================================
    -- 担当部署
    gv_dept_cd := SUBSTRB(xxcmn_common_pkg.get_user_dept_code(FND_GLOBAL.USER_ID, NULL), 1, 10) ;
    -- 担当者
    gv_dept_nm := SUBSTRB(xxcmn_common_pkg.get_user_name(FND_GLOBAL.USER_ID), 1, 14) ;
--
    -- =====================================================
    -- 部署情報取得関数呼び出し
    -- =====================================================
    xxcmn_common_pkg.get_dept_info
      (
        gv_dept_cd
       ,NULL
       ,gv_postal_code
       ,gv_address_value
       ,gv_tel_value
       ,gv_fax_value
       ,gv_cat_value
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg
      );
--
    -- =====================================================
    -- ヘッダータグデータセット
    -- =====================================================
    -- データグループ名開始タグセット   <root>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'root' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- データグループ名開始タグセット   <data_info>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'data_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- データグループ名開始タグセット   <lg_denpyo_info>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_denpyo_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ====================================================
    -- データ抽出
    -- ====================================================
    IF ( gr_param.target_class = gv_actual_kbn ) THEN
      -- ====================================================
      -- カーソルオープン
      -- ====================================================
      <<get_actual_cur_loop>>
      FOR rec_get_actual_cur IN get_actual_cur
        (
           gr_param.move_no
          ,gr_param.move_instr_post_cd
          ,gr_param.ship
          ,gr_param.arrival
          ,gr_param.delivery_no
          ,gr_param.product_class
          ,gr_param.prod_class_code
          ,gr_param.ship_date_from
          ,gr_param.ship_date_to
        )
      LOOP
        -- ===================================================
        -- 出力情報取得
        -- ===================================================
        gr_head_data.move_number   := rec_get_actual_cur.mov_num ;                     -- 移動番号
        gr_head_data.base_id       := rec_get_actual_cur.shipped_locat_code ;
                                                                                 -- 出庫元(コード)
        gr_head_data.base_value    := rec_get_actual_cur.description1 ;                -- 出庫元
        gr_head_data.in_id         := rec_get_actual_cur.ship_to_locat_code ;
                                                                                 -- 入庫先(コード)
        gr_head_data.in_value      := rec_get_actual_cur.description2 ;                -- 入庫先
        gr_head_data.out_date      := rec_get_actual_cur.actual_ship_date ;            -- 出庫日
        gr_head_data.arrive_date   := rec_get_actual_cur.actual_arrival_date ;         -- 着日
        gr_head_data.fare_code     := rec_get_actual_cur.freight_charge_class ;        -- 運賃区分
        gr_head_data.deliver_code  := rec_get_actual_cur.meaning ;                     -- 配送区分
        gr_head_data.arr_code      := rec_get_actual_cur.batch_no ;                    -- 手配No
        gr_head_data.trader_code   := rec_get_actual_cur.actual_freight_carrier_code ; 
                                                                                 -- 運送業者(コード)
        gr_head_data.trader_name   := rec_get_actual_cur.party_name ;                  -- 運送業者
        gr_head_data.summary_value := rec_get_actual_cur.description3 ;                -- 摘要
--
        -- ===================================================
        -- XMLデータ作成（合計部）
        -- ===================================================
        IF ( lv_move_number IS NOT NULL
             AND
             NVL( lv_move_number, '0' ) <> gr_head_data.move_number ) THEN
          create_xml_sum
            (
              ln_amount_sum                        -- 01.合計数量
             ,ln_volume_sum                        -- 02.合計体積
             ,ln_weight_sum                        -- 03.合計重量
             ,lv_errbuf                            -- エラー・メッセージ           --# 固定 #
             ,lv_retcode                           -- リターン・コード             --# 固定 #
             ,lv_errmsg) ;                         -- ユーザー・エラー・メッセージ --# 固定 #
--
          -- 合計用変数の初期化
          ln_weight_sum := 0 ;
          ln_amount_sum := 0 ;
          ln_volume_sum := 0 ;
        END IF;
--
        -- ===================================================
        -- XMLデータ作成（ヘッダ部）
        -- ===================================================
        IF ( NVL( lv_move_number, '0' ) <> gr_head_data.move_number ) THEN
          create_xml_head(
           lv_errbuf              -- エラー・メッセージ           --# 固定 #
          ,lv_retcode             -- リターン・コード             --# 固定 #
          ,lv_errmsg) ;           -- ユーザー・エラー・メッセージ --# 固定 #
        END IF;
--
        -- ===================================================
        -- 在庫入数加工処理
        -- ===================================================
        -- 変数の初期化
        ln_stock := 0;
        IF ( rec_get_actual_cur.segment1 = gv_seihin ) THEN
          ln_stock := rec_get_actual_cur.num_of_cases ;
        ELSIF ( rec_get_actual_cur.segment1 = gv_hanseihin 
                OR rec_get_actual_cur.segment1 = gv_genryou ) THEN
          IF ( rec_get_actual_cur.attribute6 IS NULL ) THEN
            ln_stock := rec_get_actual_cur.frequent_qty ;
          ELSE
            ln_stock := rec_get_actual_cur.attribute6 ;
          END IF ;
        ELSIF ( rec_get_actual_cur.segment1 = gv_shizai ) THEN
          ln_stock := rec_get_actual_cur.frequent_qty ;
        END IF;
--
        -- ===================================================
        -- XMLデータ作成（明細部）
        -- ===================================================
        create_xml_line(
           rec_get_actual_cur.item_code        -- 01:品目（コード）
          ,rec_get_actual_cur.item_short_name  -- 02:品目名称
          ,rec_get_actual_cur.lot_no           -- 03:ロットNo
          ,rec_get_actual_cur.attribute1       -- 04:製造日
          ,rec_get_actual_cur.attribute2       -- 05:固有記号
          ,ln_stock                            -- 06:在庫入数
          ,rec_get_actual_cur.actual_quantity  -- 07:数量
          ,rec_get_actual_cur.uom_code         -- 08:単位
          ,lv_errbuf                           -- エラー・メッセージ           --# 固定 #
          ,lv_retcode                          -- リターン・コード             --# 固定 #
          ,lv_errmsg) ;                        -- ユーザー・エラー・メッセージ --# 固定 #
--
        -- ===================================================
        -- 合計部の合計重量の算出
        -- ===================================================
--2008.05.29 modify start
--        IF ( gr_param.prod_class_code = gv_item_kbn_drink 
--             AND gr_param.product_class = gv_product_class
--             AND rec_get_actual_cur.koguchi = gv_attribute6 ) THEN
--          -- パラメータの商品区分がドリンク かつ 製品識別区分が製品 かつ
--          -- 配送区分の小口区分が「対象」の場合
--          ln_weight_sum := NVL( ln_weight_sum, 0 ) + NVL( rec_get_actual_cur.sum_weight, 0 ) ;
--        ELSE
--          ln_weight_sum := NVL( ln_weight_sum, 0 ) + 
--                              ( NVL( rec_get_actual_cur.sum_weight, 0 ) +
--                                NVL( rec_get_actual_cur.sum_pallet_weight, 0 ) );
--        END IF;
        --
        IF ( NVL( lv_move_number, '0' ) <> gr_head_data.move_number ) THEN
          IF ( gr_param.prod_class_code = gv_item_kbn_drink 
               AND gr_param.product_class = gv_product_class
               AND rec_get_actual_cur.koguchi = gv_attribute6 ) THEN
          -- パラメータの商品区分がドリンク かつ 製品識別区分が製品 かつ
          -- 配送区分の小口区分が「対象」の場合
            ln_weight_sum      := NVL( rec_get_actual_cur.sum_weight, 0 ) ;
          ELSE
            ln_weight_sum      := NVL( rec_get_actual_cur.sum_weight, 0 ) + 
                                     NVL( rec_get_actual_cur.sum_pallet_weight, 0 ) ;
          END IF;
        END IF;
--2008.05.29 modify end
--
        -- ===================================================
        -- 合計部の合計数量の算出
        -- ===================================================
        ln_amount_sum := NVL( rec_get_actual_cur.actual_quantity, 0 ) + NVL( ln_amount_sum, 0 ) ;
        -- ===================================================
        -- 合計部の合計体積の算出
        -- ===================================================
--2008.05.29 modify start
--        ln_volume_sum := NVL( rec_get_actual_cur.sum_capacity, 0 ) + NVL( ln_volume_sum, 0 ) ;
        ln_volume_sum := NVL( ln_volume_sum, 0 ) ;
--2008.05.29 modify end
--
        -- データ件数カウント
        xml_data_count := xml_data_count + 1;
        -- 移動番号
        lv_move_number := gr_head_data.move_number ;
      END LOOP get_actual_cur_loop;
--
      -- ===================================================
      -- XMLデータ作成（合計部）
      -- ===================================================
      IF ( xml_data_count <> 0 ) THEN
        create_xml_sum
          (
            ln_amount_sum                        -- 01.合計数量
           ,ln_volume_sum                        -- 02.合計体積
           ,ln_weight_sum                        -- 03.合計重量
           ,lv_errbuf                            -- エラー・メッセージ           --# 固定 #
           ,lv_retcode                           -- リターン・コード             --# 固定 #
           ,lv_errmsg) ;                         -- ユーザー・エラー・メッセージ --# 固定 #
      END IF;
--
    ELSIF ( gr_param.target_class = gv_indicate_kbn ) THEN
      <<get_indicate_cur_loop>>
      FOR rec_get_indicate IN get_indicate_cur
        (
           gr_param.move_no
          ,gr_param.move_instr_post_cd
          ,gr_param.ship
          ,gr_param.arrival
          ,gr_param.delivery_no
          ,gr_param.product_class
          ,gr_param.prod_class_code
          ,gr_param.ship_date_from
          ,gr_param.ship_date_to
        )
      LOOP
        -- ===================================================
        -- 出力情報取得
        -- ===================================================
        gr_head_data.move_number        := rec_get_indicate.mov_num ;               -- 移動番号
        gr_head_data.base_id            := rec_get_indicate.shipped_locat_code ;    
                                                                                 -- 出庫元(コード)
        gr_head_data.base_value         := rec_get_indicate.description1 ;          -- 出庫元
        gr_head_data.in_id              := rec_get_indicate.ship_to_locat_code ;    
                                                                                 -- 入庫先(コード)
        gr_head_data.in_value           := rec_get_indicate.description2 ;          -- 入庫先
        gr_head_data.out_date           := rec_get_indicate.schedule_ship_date ;    -- 出庫日
        gr_head_data.arrive_date        := rec_get_indicate.schedule_arrival_date ; -- 着日
        gr_head_data.fare_code          := rec_get_indicate.freight_charge_class ;  -- 運賃区分
        gr_head_data.deliver_code       := rec_get_indicate.meaning ;               -- 配送区分
        gr_head_data.arr_code           := rec_get_indicate.batch_no ;              -- 手配No
        gr_head_data.trader_code        := rec_get_indicate.freight_carrier_code ;  
                                                                                 -- 運送業者(コード)
        gr_head_data.trader_name        := rec_get_indicate.party_name ;            -- 運送業者
        gr_head_data.summary_value      := rec_get_indicate.description3 ;          -- 摘要
--
        -- ===================================================
        -- XMLデータ作成（合計部）
        -- ===================================================
        IF ( lv_move_number IS NOT NULL
             AND
             NVL( lv_move_number, '0' ) <> gr_head_data.move_number ) THEN
          create_xml_sum(
           ln_amount_sum                        -- 01.合計数量
          ,ln_volume_sum                        -- 02.合計体積
          ,ln_weight_sum                        -- 03.合計重量
          ,lv_errbuf                            -- エラー・メッセージ           --# 固定 #
          ,lv_retcode                           -- リターン・コード             --# 固定 #
          ,lv_errmsg) ;                         -- ユーザー・エラー・メッセージ --# 固定 #
--
          -- 合計用変数の初期化
          ln_weight_sum := 0 ;
          ln_amount_sum := 0 ;
          ln_volume_sum := 0 ;
        END IF;
--
        -- ===================================================
        -- XMLデータ作成（ヘッダ部）
        -- ===================================================
        IF ( NVL( lv_move_number, '0' ) <> gr_head_data.move_number ) THEN
          create_xml_head(
           lv_errbuf              -- エラー・メッセージ           --# 固定 #
          ,lv_retcode             -- リターン・コード             --# 固定 #
          ,lv_errmsg) ;           -- ユーザー・エラー・メッセージ --# 固定 #
        END IF;
--
        -- ===================================================
        -- 在庫入数加工処理
        -- ===================================================
        -- 変数の初期化
        ln_stock := 0;
        IF ( rec_get_indicate.segment1 = gv_seihin ) THEN
          ln_stock := rec_get_indicate.num_of_cases ;
        ELSIF ( rec_get_indicate.segment1 = gv_hanseihin 
                OR rec_get_indicate.segment1 = gv_genryou ) THEN
          IF ( rec_get_indicate.attribute6 IS NULL ) THEN
            ln_stock := rec_get_indicate.frequent_qty ;
          ELSE
            ln_stock := rec_get_indicate.attribute6 ;
          END IF ;
        ELSIF ( rec_get_indicate.segment1 = gv_shizai ) THEN
          ln_stock := rec_get_indicate.frequent_qty ;
        END IF;
--
        -- ===================================================
        -- XMLデータ作成（明細部）
        -- ===================================================
        create_xml_line(
           rec_get_indicate.item_code        -- 01:品目（コード）
          ,rec_get_indicate.item_short_name  -- 02:品目名称
          ,rec_get_indicate.lot_no           -- 03:ロットNo
          ,rec_get_indicate.attribute1       -- 04:製造日
          ,rec_get_indicate.attribute2       -- 05:固有記号
          ,ln_stock                          -- 06:在庫入数
          ,rec_get_indicate.actual_quantity  -- 07:数量
          ,rec_get_indicate.uom_code         -- 08:単位
          ,lv_errbuf                         -- エラー・メッセージ           --# 固定 #
          ,lv_retcode                        -- リターン・コード             --# 固定 #
          ,lv_errmsg) ;                      -- ユーザー・エラー・メッセージ --# 固定 #
        -- ===================================================
        -- 合計部の合計重量の算出
        -- ===================================================
--2008.05.29 modify start
--        IF ( gr_param.prod_class_code = gv_item_kbn_drink 
--             AND gr_param.product_class = gv_product_class
--             AND rec_get_indicate.koguchi = gv_attribute6 ) THEN
--          -- パラメータの商品区分がドリンク かつ 製品識別区分が製品 かつ
--          -- 配送区分の小口区分が「対象」の場合
--          ln_weight_sum      := NVL( ln_weight_sum, 0 ) + NVL( rec_get_indicate.sum_weight, 0 ) ;
--        ELSE
--          ln_weight_sum      := NVL( ln_weight_sum, 0 ) + 
--                                   ( NVL( rec_get_indicate.sum_weight, 0 ) + 
--                                     NVL( rec_get_indicate.sum_pallet_weight, 0 ) ) ;
--        END IF;
        --
        IF ( NVL( lv_move_number, '0' ) <> gr_head_data.move_number ) THEN
          IF ( gr_param.prod_class_code = gv_item_kbn_drink 
               AND gr_param.product_class = gv_product_class
               AND rec_get_indicate.koguchi = gv_attribute6 ) THEN
          -- パラメータの商品区分がドリンク かつ 製品識別区分が製品 かつ
          -- 配送区分の小口区分が「対象」の場合
            ln_weight_sum      := NVL( rec_get_indicate.sum_weight, 0 ) ;
          ELSE
            ln_weight_sum      := NVL( rec_get_indicate.sum_weight, 0 ) + 
                                     NVL( rec_get_indicate.sum_pallet_weight, 0 ) ;
          END IF;
        END IF;
--2008.05.29 modify end
        -- ===================================================
        -- 合計部の合計数量の算出
        -- ===================================================
        ln_amount_sum := NVL( rec_get_indicate.actual_quantity, 0 ) + NVL( ln_amount_sum, 0 ) ;
        -- ===================================================
        -- 合計部の合計体積の算出
        -- ===================================================
--2008.05.29 modify start
--        ln_volume_sum := NVL( rec_get_indicate.sum_capacity, 0 ) + NVL( ln_volume_sum, 0 ) ;
        ln_volume_sum := NVL( ln_volume_sum, 0 ) ;
--2008.05.29 modify end
        -- データ件数カウント
        xml_data_count := xml_data_count + 1;
        -- 移動番号
        lv_move_number := gr_head_data.move_number;
      END LOOP get_indicate_cur_loop ;
      -- ===================================================
      -- XMLデータ作成（合計部）
      -- ===================================================
      IF ( xml_data_count <> 0 ) THEN
        create_xml_sum(
         ln_amount_sum                        -- 01.合計数量
        ,ln_volume_sum                        -- 02.合計体積
        ,ln_weight_sum                        -- 03.合計重量
        ,lv_errbuf                            -- エラー・メッセージ           --# 固定 #
        ,lv_retcode                           -- リターン・コード             --# 固定 #
        ,lv_errmsg) ;                         -- ユーザー・エラー・メッセージ --# 固定 #
      END IF;
    END IF ;
--
    IF ( xml_data_count = 0 ) THEN
      -- =====================================================
      -- 取得データ０件時XMLデータ作成処理
      -- =====================================================
      prc_create_zeroken_xml_data
        (
          lv_errbuf         -- エラー・メッセージ            --# 固定 #
         ,lv_retcode        -- リターン・コード              --# 固定 #
         ,lv_errmsg         -- ユーザー・エラー・メッセージ  --# 固定 #
        );
--
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_process_expt ;
      END IF ;
    -- データ件数セット
    on_xml_data_count := xml_data_count ;
--
    END IF;
--
    -- =====================================================
    -- 終了タグセット
    -- =====================================================
    -- データグループ名終了タグセット   </lg_denpyo_info>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_denpyo_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- データグループ名終了タグセット   </data_info>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/data_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- データグループ名終了タグセット   </root>
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/root' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
  EXCEPTION
      --*** 値取得エラー例外 ***
    WHEN data_check_expt THEN
      ov_errmsg  := lv_errmsg ;                                           --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error ;                                     --# 任意 #
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
--#####################################  固定部 END   ##########################################
--
  END create_xml ;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
     iv_product_class      IN     VARCHAR2       --   01.製品識別区分
    ,iv_prod_class_code    IN     VARCHAR2       --   02.商品区分
    ,iv_target_class       IN     VARCHAR2       --   03.指示/実績区分
    ,iv_move_no            IN     VARCHAR2       --   04.移動番号
    ,iv_move_instr_post_cd IN     VARCHAR2       --   05.移動指示部署
    ,iv_ship               IN     VARCHAR2       --   06.出庫元
    ,iv_arrival            IN     VARCHAR2       --   07.入庫先
    ,iv_ship_date_from     IN     VARCHAR2       --   08.出庫日FROM
    ,iv_ship_date_to       IN     VARCHAR2       --   09.出庫日TO
    ,iv_delivery_no        IN     VARCHAR2       --   10.配送No.
    ,ov_errbuf            OUT     VARCHAR2       --   エラー・メッセージ           --# 固定 #
    ,ov_retcode           OUT     VARCHAR2       --   リターン・コード             --# 固定 #
    ,ov_errmsg            OUT     VARCHAR2)      --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- ======================================================
    -- ユーザー宣言部
    -- ======================================================
    -- *** ローカル定数 ***
    lr_param_rec            rec_param_data ;               -- パラメータ受渡し用
    xml_data_table          XML_DATA ;
    ln_retcode              NUMBER ;
    ln_xml_data_count       NUMBER ;
--
    -- *** ローカル変数 ***
--
  BEGIN
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- =====================================================
    -- パラメータ格納処理
    -- =====================================================
    gr_param.product_class      := iv_product_class ;          -- 01.製品識別区分
    gr_param.prod_class_code    := iv_prod_class_code ;        -- 02.商品区分
    gr_param.target_class       := iv_target_class ;           -- 03.指示/実績区分
    gr_param.move_no            := iv_move_no ;                -- 04.移動番号
    gr_param.move_instr_post_cd := iv_move_instr_post_cd ;     -- 05.移動指示部署
    gr_param.ship               := TO_NUMBER( iv_ship ) ;      -- 06.出庫元
    gr_param.arrival            := TO_NUMBER( iv_arrival ) ;   -- 07.入庫先
    gr_param.ship_date_from     := FND_DATE.STRING_TO_DATE(iv_ship_date_from, gc_date_fmt_ymd) ;
                                                               -- 08.出庫日FROM
    gr_param.ship_date_to       := FND_DATE.STRING_TO_DATE(iv_ship_date_to, gc_date_fmt_ymd) ;
                                                               -- 09.出庫日TO
    gr_param.delivery_no        := iv_delivery_no ;            -- 10.配送No.
--
    -- ====================================================
    -- XMLデータ(Temp)作成
    -- ====================================================
    create_xml(
       ln_xml_data_count      -- 取得データ件数
      ,lv_errbuf              -- エラー・メッセージ           --# 固定 #
      ,lv_retcode             -- リターン・コード             --# 固定 #
      ,lv_errmsg) ;           -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- エラーハンドリング
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    IF (lv_retcode = gv_status_normal AND ln_xml_data_count = 0) THEN
      lv_retcode := gv_status_warn;
    END IF;
--
    -- ==================================================
    -- 終了ステータス設定
    -- ==================================================
    ov_retcode := lv_retcode ;
    ov_errmsg  := lv_errmsg ;
    ov_errbuf  := lv_errbuf ;
--
    -- =====================================================
    -- XMLデータ出力処理
    -- =====================================================
    output_xml(
        ov_errbuf         =>   lv_errbuf          -- エラー・メッセージ            --# 固定 #
       ,ov_retcode        =>   lv_retcode         -- リターン・コード              --# 固定 #
       ,ov_errmsg         =>   lv_errmsg          -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (ov_retcode = gv_status_error) THEN   -- リターンコード＝「エラー」
      RAISE global_process_expt ;
--
    ELSIF (    (ov_retcode = gv_status_normal)
           AND (ln_xml_data_count = 0)) THEN  -- リターンコード＝「正常」かつ件数が0件
      ov_retcode := gv_status_warn;
--
    END IF;
--
  EXCEPTION
      -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
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
  END submain ;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main (
    errbuf                OUT VARCHAR2,         --   エラー・メッセージ  --# 固定 #
    retcode               OUT VARCHAR2,         --   リターン・コード    --# 固定 #
    iv_product_class      IN  VARCHAR2,         --   01.製品識別区分
    iv_prod_class_code    IN  VARCHAR2,         --   02.商品区分
    iv_target_class       IN  VARCHAR2,         --   03.指示/実績区分
    iv_move_no            IN  VARCHAR2,         --   04.移動番号
    iv_move_instr_post_cd IN  VARCHAR2,         --   05.移動指示部署
    iv_ship               IN  VARCHAR2,         --   06.出庫元
    iv_arrival            IN  VARCHAR2,         --   07.入庫先
    iv_ship_date_from     IN  VARCHAR2,         --   08.出庫日FROM
    iv_ship_date_to       IN  VARCHAR2,         --   09.出庫日TO
    iv_delivery_no        IN  VARCHAR2)         --   10.配送No.
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
    -- ======================================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ======================================================
    submain(
      iv_product_class,      --   01.製品識別区分
      iv_prod_class_code,    --   02.商品区分
      iv_target_class,       --   03.指示/実績区分
      iv_move_no,            --   04.移動番号
      iv_move_instr_post_cd, --   05.移動指示部署
      iv_ship,               --   06.出庫元
      iv_arrival,            --   07.入庫先
      iv_ship_date_from,     --   08.出庫日FROM
      iv_ship_date_to,       --   09.出庫日TO
      iv_delivery_no,        --   10.配送No.
      lv_errbuf,             --   エラー・メッセージ           --# 固定 #
      lv_retcode,            --   リターン・コード             --# 固定 #
      lv_errmsg) ;           --   ユーザー・エラー・メッセージ --# 固定 #
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
END xxinv510001c ;
/