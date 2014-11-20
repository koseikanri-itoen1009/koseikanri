CREATE OR REPLACE PACKAGE BODY xxpo440001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo440001c(spec)
 * Description      : 有償出庫指示書
 * MD.050/070       : 有償支給帳票Issue1.0(T_MD050_BPO_444)
 *                    有償支給帳票Issue1.0(T_MD070_BPO_44I)
 * Version          : 1.7
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 コンカレント実行ファイル登録プロシージャ
 *
 *  prc_create_out_data         PROCEDURE : ＸＭＬデータ出力処理
 *  prc_create_sql              PROCEDURE : データ抽出処理
 *  prc_create_xml_data_user    PROCEDURE : タグ出力 - ユーザー情報
 *  prc_create_xml_data         PROCEDURE : ＸＭＬデータ編集
 *  convert_into_xml            FUNCTION  : ＸＭＬタグに変換する。
 *  submain                     PROCEDURE : メイン処理プロシージャ
 *  main                        PROCEDURE : コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/03/19    1.0   Oracle井澤直也   新規作成
 *  2008/05/16    1.1   Oracle藤井良平   結合テスト不具合（機能ID：440、不具合ID：5）
 *                                       結合テスト不具合（機能ID：440、不具合ID：6）
 *                                       結合テスト不具合（機能ID：440、不具合ID：7）
 *                                       結合テスト不具合（機能ID：440、不具合ID：8）
 *  2008/05/19    1.2   Oracle藤井良平   結合テスト不具合（機能ID：440、不具合ID：9）
 *                                       結合テスト不具合（機能ID：440、不具合ID：10）
 *                                       結合テスト不具合（機能ID：440、不具合ID：11）
 *                                       結合テスト不具合（機能ID：440、不具合ID：12）
 *                                       結合テスト不具合（機能ID：440、不具合ID：13）
 *  2008/05/21    1.3   Oracle田畑祐亮   結合テスト不具合（機能ID：440、不具合ID：19）
 *  2008/06/19    1.4   Oracle熊本和郎   結合テスト不具合
 *                                         1.レビュー指摘事項No.11：適用日管理を行う。
 *                                         2.レビュー指摘事項No.13：取引先名、配送先名の
 *                                           折り返しをコンカレント側で行う。
 *  2008/06/23    1.5   Oracle山本恭久   変更要求対応No.42、91
 *                                       内部変更要求対応No.160
 *  2008/09/19    1.6   Oracle山根一浩   T_S_439対応
 *  2008/10/22    1.7   Oracle大橋孝郎   指摘361対応
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
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  check_create_xml_expt        EXCEPTION;     -- ＸＭＬデータ編集での例外
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
  gc_pkg_name               CONSTANT VARCHAR2(20) := 'xxpo440001c' ;     -- パッケージ名
  gc_report_id              CONSTANT VARCHAR2(20) := 'XXPO440001T' ;     -- 帳票ID
  gc_application            CONSTANT VARCHAR2(5)  := 'XXCMN' ;           -- アプリケーション
  gc_po_application         CONSTANT VARCHAR2(4)  := 'XXPO'  ;           -- XXPOアプリケーション
  gc_err_code_no_data       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10122';  -- データ０件メッセージ
  gc_err_code_no_prof       CONSTANT VARCHAR2(15) := 'APP-XXPO-10005' ;  -- プロファイル取得エラー
  gc_err_code_sikyuno_data  CONSTANT VARCHAR2(15) := 'APP-XXPO-10026';   -- APP-XXPO-10026
--
--
  ------------------------------
  -- プロファイル名
  ------------------------------
  gc_prof_org_id          CONSTANT VARCHAR2(20) := 'ORG_ID' ;   -- 営業単位
  gn_prof_org_id          oe_transaction_types_all.org_id%TYPE ;
--
  ------------------------------
  -- 参照タイプ
  ------------------------------
  -- 配送区分
  gc_lookup_ship_method_code  CONSTANT VARCHAR2(40) := 'XXCMN_SHIP_METHOD' ;
  -- 引取区分
  gc_lookup_takeback_class    CONSTANT VARCHAR2(40) := 'XXWSH_TAKEBACK_CLASS' ;
  -- 運賃区分
-- Ver1.1 Changed 2008/05/16
--  gc_xxwsh_freight_class      CONSTANT VARCHAR2(40) := 'XXWSH_FREIGHT_CLASS';
  gc_xxwsh_freight_class      CONSTANT VARCHAR2(40) := 'XXCMN_INCLUDE_EXCLUDE';
-- Ver1.1 Changed 2008/05/16
  -- 着荷時間
  gc_xxwsh_arrival_time       CONSTANT VARCHAR2(40) := 'XXWSH_ARRIVAL_TIME';
  ------------------------------
  -- 参照コード
  ------------------------------
  -- パラメータ：使用目的
  gc_use_purpose_irai     CONSTANT VARCHAR2(1) := '1' ;    -- 依頼
  gc_use_purpose_shij     CONSTANT VARCHAR2(1) := '2' ;    -- 指示
  gc_use_purpose_henpin   CONSTANT VARCHAR2(1) := '3' ;    -- 返品
  -- パラメータ：有償セキュリティ区分
  gc_security_div_i       CONSTANT VARCHAR2(1) := '1' ;    -- 伊藤園
  gc_security_div_d       CONSTANT VARCHAR2(1) := '2' ;    -- 取引先
  gc_security_div_l       CONSTANT VARCHAR2(1) := '3' ;    -- 出庫倉庫(東洋埠頭)
  gc_security_div_lt      CONSTANT VARCHAR2(1) := '4' ;    -- 出庫倉庫(東洋埠頭以外)
  -- 受注カテゴリ：出荷支給区分
  gc_sp_class_ship        CONSTANT VARCHAR2(1) := '1' ;    -- 出荷依頼
  gc_sp_class_prov        CONSTANT VARCHAR2(1) := '2' ;    -- 支給依頼
  gc_sp_class_move        CONSTANT VARCHAR2(1) := '3' ;    -- 移動
  -- 受注ヘッダアドオン：最新フラグ
  gc_yn_div_y             CONSTANT VARCHAR2(1) := 'Y' ;    -- YES
  -- 受注ヘッダ明細：削除フラグ
  gc_yn_div_n             CONSTANT VARCHAR2(1) := 'N' ;    -- NO
  -- 受注ヘッダアドオン：ステータス
  gc_req_status_s_inp     CONSTANT VARCHAR2(2) := '05' ;   -- 入力中
  gc_req_status_s_cmpa    CONSTANT VARCHAR2(2) := '06' ;   -- 入力完了
  gc_req_status_s_cmpb    CONSTANT VARCHAR2(2) := '07' ;   -- 受領済
  gc_req_status_s_cmpc    CONSTANT VARCHAR2(2) := '08' ;   -- 出荷実績計上済
  gc_req_status_p_ccl     CONSTANT VARCHAR2(2) := '99' ;   -- 取消
  -- 受注ヘッダアドオン：通知ステータス
  gc_notif_status_ok      CONSTANT VARCHAR2(2) := '40' ;   -- 確定通知済
  -- 受注タイプ：出荷支給区分
  gc_shipping_provide_s   CONSTANT VARCHAR2(2) := '05'  ;   -- 有償出荷
  gc_shipping_provide_h   CONSTANT VARCHAR2(2) := '06'  ;   -- 有償返品
  -- 移動ロット詳細アドオン：文書タイプ
  gc_doc_type_move        CONSTANT VARCHAR2(2) := '20' ;   -- 移動
  gc_doc_type_prov        CONSTANT VARCHAR2(2) := '30' ;   -- 支給指示
  gc_doc_type_prod        CONSTANT VARCHAR2(2) := '40' ;   -- 生産指示
  -- 移動ロット詳細アドオン：レコードタイプ
  gc_rec_type_inst        CONSTANT VARCHAR2(2) := '10' ;   -- 指示
  gc_rec_type_stck        CONSTANT VARCHAR2(2) := '20' ;   -- 出庫実績
  gc_rec_type_dlvr        CONSTANT VARCHAR2(2) := '30' ;   -- 入庫実績
  -- ＯＰＭ品目マスタ：ロット管理区分
  gc_lot_ctl_y            CONSTANT VARCHAR2(1) := '1' ;    -- ロット管理あり
  gc_lot_ctl_n            CONSTANT VARCHAR2(1) := '0' ;    -- ロット管理なし
  -- 帳票タイトル
  gc_report_name_irai     CONSTANT VARCHAR2(14) := '有償出庫依頼書' ;
  gc_report_name_shij     CONSTANT VARCHAR2(14) := '有償出庫指示書' ;
  gc_report_name_henpin   CONSTANT VARCHAR2(14) := '有償返品指示書' ;
--
  ------------------------------
  -- その他
  ------------------------------
  gc_max_date_char        CONSTANT VARCHAR2(10) := '9999/12/31' ;
--
  -- ==================================================
  -- ユーザー定義グローバル型
  -- ==================================================
  -- 入力パラメータ格納用レコード変数
  TYPE rec_param_data  IS RECORD
    (
      use_purpose         VARCHAR2(1)    -- 01 : 使用目的
     ,request_no          VARCHAR2(12)   -- 02 : 依頼No
     ,exec_user_dept      VARCHAR2(4)    -- 03 : 担当部署
     ,update_exec_user    VARCHAR2(15)   -- 04 : 更新担当
-- Ver1.2 Changed 2008/05/19
--     ,update_date_from    VARCHAR2(10)   -- 05 : 更新日付From
--     ,update_date_to      VARCHAR2(10)   -- 06 : 更新日付To
     ,update_date_from    VARCHAR2(20)   -- 05 : 更新日付From
     ,update_date_to      VARCHAR2(20)   -- 06 : 更新日付To
-- Ver1.2 Changed 2008/05/19
     ,vendor              VARCHAR2(4)    -- 07 : 取引先
     ,deliver_to          VARCHAR2(4)    -- 08 : 配送先
     ,shipped_locat_code  VARCHAR2(4)    -- 09 : 出庫倉庫
     ,shipped_date_from   VARCHAR2(10)   -- 10 : 出庫日From
     ,shipped_date_to     VARCHAR2(10)   -- 11 : 出庫日To
     ,prod_class          VARCHAR2(1)    -- 12 : 商品区分
     ,item_class          VARCHAR2(1)    -- 13 : 品目区分
     ,security_class      VARCHAR2(1)    -- 14 : 有償セキュリティ区分
    ) ;
--
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gr_param                   rec_param_data ;   -- パラメータ
  gn_data_cnt                NUMBER DEFAULT 0 ; -- 処理データカウンタ
--
  gt_xml_data_table          XML_DATA ;         -- ＸＭＬデータタグ表
  gl_xml_idx                 NUMBER DEFAULT 0 ; -- ＸＭＬデータタグ表のインデックス
--
  gn_user_id                 fnd_user.user_id%TYPE DEFAULT FND_GLOBAL.USER_ID ;   -- ログインユーザーＩＤ
  gv_report_name             VARCHAR2(14)  ;   -- 帳票タイトル
--
  gn_created_by              NUMBER ;          -- 作成者
  gn_last_updated_by         NUMBER ;          -- 最終更新者
  gn_last_update_login       NUMBER ;          -- 最終更新ログイン
  gn_request_id              NUMBER ;          -- 要求ID
  gn_program_application_id  NUMBER ;          -- コンカレント・プログラム・アプリケーションID
  gn_program_id              NUMBER ;          -- コンカレント・プログラムID
  gv_sql                     VARCHAR2(32000) ; -- データ取得用ＳＱＬ
-- add start 1.7
  gn_type_id                 oe_transaction_types_all.transaction_type_id%TYPE; -- 取引タイプID
-- add end 1.7
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
   * Procedure Name   : prc_create_xml_data_user
   * Description      : ユーザー情報タグ出力
   ************************************************************************************************/
  PROCEDURE prc_create_xml_data_user
    (
      ov_errbuf             OUT VARCHAR2          --    エラー・メッセージ           --# 固定 #
     ,ov_retcode            OUT VARCHAR2          --    リターン・コード             --# 固定 #
     ,ov_errmsg             OUT VARCHAR2          --    ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ==================================================
    -- 固定ローカル定数
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_xml_data_user' ; -- プログラム名
--
--##### 固定ローカル変数宣言部 START #################################
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--##### 固定ローカル変数宣言部 END   #################################
--
  BEGIN
--
--##### 固定ステータス初期化部 START #################################
    ov_retcode := gv_status_normal;
--##### 固定ステータス初期化部 END   #################################
--
    -- ====================================================
    -- 開始タグ
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'user_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ====================================================
    -- データタグ
    -- ====================================================
    -- 帳票ＩＤ
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'report_id' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gc_report_id ;
--
    -- 実行日
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_date' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( SYSDATE, 'YYYY/MM/DD HH24:MI:SS' ) ;
--
    -- ====================================================
    -- 終了タグ
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/user_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
  EXCEPTION
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
  END prc_create_xml_data_user ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_out_data
   * Description      : ＸＭＬデータ出力処理
   ************************************************************************************************/
  PROCEDURE prc_create_out_data
    (
      ov_errbuf     OUT    VARCHAR2             -- エラー・メッセージ
     ,ov_retcode    OUT    VARCHAR2             -- リターン・コード
     ,ov_errmsg     OUT    VARCHAR2             -- ユーザー・エラー・メッセージ
    )
  IS
    -- ==================================================
    -- 定  数  宣  言
    -- ==================================================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'prc_create_out_data' ; -- プログラム名
    cv_order          CONSTANT VARCHAR2(6)   := 'RETURN';               -- 受注カテゴリ
--2008/09/19 Add ↓
    cn_type_id        CONSTANT NUMBER        := 1029;                   -- 受注タイプID(訂正)
--2008/09/19 Add ↑
--
    -- ==================================================
    -- カ  ー  ソ  ル  宣  言
    -- ==================================================
    -- ==================================================
    -- 変  数  宣  言
    -- ==================================================
    lv_sql                  VARCHAR2(32000) ;
    -- ブレイク判断用
    lv_tmp_request_no       VARCHAR2(12) DEFAULT '*' ;
    -- 配送区分格納用
    lv_ship_method_code     VARCHAR2(2)  ;
    lv_ship_method_name     VARCHAR2(14) ;
    -- 運賃区分格納用
    lv_freight_charge_code  VARCHAR2(1)  ;
    lv_freight_charge_class VARCHAR2(20) ;
    -- 引取区分
    lv_takeback_code        VARCHAR2(1) ;
    lv_takeback_class       VARCHAR2(10) ;
    -- 着荷時間
    lv_arrival_time_from    VARCHAR2(5);
    lv_arrival_time_to      VARCHAR2(5);
    -- 部署格納用
    lv_dept                 VARCHAR2(4) ;
    -- 郵便番号
    lv_dept_postal_code     VARCHAR2(8) ;
    -- 住所
    lv_dept_address         VARCHAR2(30);
    -- 電話番号
    lv_dept_tel_num         VARCHAR2(15);
    -- FAX番号
    lv_dept_fax_num         VARCHAR2(15);
     -- 部署正式名
    lv_dept_formal_name     VARCHAR2(30);
    -- 総数編集用
    ln_quantity             NUMBER DEFAULT 0;
    -- テーブル名
    lv_tablename            VARCHAR2(20);
--
    -- ==================================================
    -- Ｒｅｆカーソル宣言
    -- ==================================================
    TYPE ref_cursor IS REF CURSOR ;       -- REF_CURSOR用
    TYPE ret_value  IS RECORD
      (
        request_no                  xxwsh_order_headers_all.request_no%TYPE
       ,vendor_code                 xxcmn_vendors2_v.segment1%TYPE
       ,vendor_name                 xxcmn_vendors2_v.vendor_full_name%TYPE
       ,deliver_to_code             xxcmn_vendor_sites2_v.vendor_site_code%TYPE
       ,deliver_to_name             xxcmn_vendor_sites2_v.vendor_site_name%TYPE
       ,zip                         xxcmn_vendors2_v.zip%TYPE
       ,address1                    xxcmn_vendors2_v.address_line1%TYPE
       ,address2                    xxcmn_vendors2_v.address_line2%TYPE
       ,shipped_locat_code          xxcmn_item_locations2_v.segment1%TYPE
       ,shipped_locat_name          xxcmn_item_locations2_v.description%TYPE
       ,ship_date                   xxwsh_order_headers_all.schedule_ship_date%TYPE
       ,arrival_date                xxwsh_order_headers_all.schedule_arrival_date%TYPE
       ,takeback_class              xxwsh_order_headers_all.takeback_class%TYPE
       ,arrival_time_from           xxwsh_order_headers_all.arrival_time_from%TYPE
       ,arrival_time_to             xxwsh_order_headers_all.arrival_time_to%TYPE
       ,freight_charge_class        xxwsh_order_headers_all.freight_charge_class%TYPE
       ,party_number                xxcmn_parties2_v.party_number%TYPE
       ,party_short_name            xxcmn_parties2_v.party_short_name%TYPE
       ,shipping_method_code        xxwsh_order_headers_all.shipping_method_code%TYPE
       ,delivery_no                 xxwsh_order_headers_all.delivery_no%TYPE
       ,po_no                       xxwsh_order_headers_all.po_no%TYPE
-- 2008/06/23 v1.5 Y.Yamamoto ADD Start
       ,base_request_no             xxwsh_order_headers_all.base_request_no%TYPE
       ,complusion_output_code      xxcmn_carriers2_v.complusion_output_code%TYPE
-- 2008/06/23 v1.5 Y.Yamamoto ADD End
       ,shipping_instructions       xxwsh_order_headers_all.shipping_instructions%TYPE
       ,performance_management_dept xxwsh_order_headers_all.performance_management_dept%TYPE
       ,instruction_dept            xxwsh_order_headers_all.instruction_dept%TYPE
       ,item_no                     xxcmn_item_mst2_v.item_no%TYPE
       ,item_short_name             xxcmn_item_mst2_v.item_short_name%TYPE
       ,futai_code                  xxwsh_order_lines_all.futai_code%TYPE
       ,shipping_provide            oe_transaction_types_all.attribute11%TYPE
       ,lot_ctl                     xxcmn_item_mst2_v.lot_ctl%TYPE
       ,order_category_code         oe_transaction_types_all.order_category_code%TYPE
       ,uom_code                    xxwsh_order_lines_all.uom_code%TYPE
       ,quantity                    xxwsh_order_lines_all.based_request_quantity%TYPE
       ,lot_no                      ic_lots_mst.lot_no%TYPE
       ,product_date                ic_lots_mst.attribute1%TYPE
       ,use_by_date                 ic_lots_mst.attribute3%TYPE
       ,original_char               ic_lots_mst.attribute2%TYPE
--2008/09/19 Add ↓
       ,order_type_id               xxwsh_order_headers_all.order_type_id%TYPE
--2008/09/19 Add ↑
      ) ;
    lc_ref    ref_cursor ;
    lr_ref    ret_value ;
--
--##### 固定ローカル変数宣言部 START #################################
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--##### 固定ローカル変数宣言部 END   #################################
--
  BEGIN
--
--##### 固定ステータス初期化部 START #################################
    ov_retcode := gv_status_normal;
--##### 固定ステータス初期化部 END   #################################
--
-- ====================================================
    -- カーソルオープン
    -- ====================================================
    OPEN lc_ref FOR gv_sql ;
    -- ====================================================
    -- リストグループ開始タグ（依頼No）
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_locat' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
--
      -- ----------------------------------------------------
      -- 明細カーソルオープン
      -- ----------------------------------------------------
    <<main_data_loop>>
    LOOP
--
      FETCH lc_ref INTO lr_ref ;
      EXIT WHEN lc_ref%NOTFOUND ;
--
      gn_data_cnt := gn_data_cnt + 1 ;
--
      -- ====================================================
      -- パラメータ名称取得ＳＱＬ
      -- ====================================================
      --着荷時間FROM
-- Ver1.1 Add 2008/05/16
      IF lr_ref.arrival_time_from IS NOT NULL THEN
        lv_tablename := '着荷時間FROM';
-- Ver1.1 Add 2008/05/16
        SELECT xlv.meaning
        INTO   lv_arrival_time_from           -- 着荷時間FROM
        FROM   xxcmn_lookup_values_v   xlv    -- クイックコード情報VIEW
        WHERE xlv.lookup_type = gc_xxwsh_arrival_time
        AND   xlv.lookup_code = lr_ref.arrival_time_from
        ;
-- Ver1.1 Add 2008/05/16
      END IF;
-- Ver1.1 Add 2008/05/16
      
      --着荷時間To
-- Ver1.1 Add 2008/05/16
      IF lr_ref.arrival_time_to IS NOT NULL THEN
        lv_tablename := '着荷時間To';
-- Ver1.1 Add 2008/05/16
        SELECT xlv.meaning
        INTO   lv_arrival_time_to             -- 着荷時間FROM
        FROM   xxcmn_lookup_values_v   xlv    -- クイックコード情報VIEW
        WHERE xlv.lookup_type = gc_xxwsh_arrival_time
        AND   xlv.lookup_code = lr_ref.arrival_time_to
        ;
-- Ver1.1 Add 2008/05/16
      END IF;
-- Ver1.1 Add 2008/05/16
      
      --配送区分名称
-- Ver1.1 Add 2008/05/16
      IF lr_ref.shipping_method_code IS NOT NULL THEN
        lv_tablename := '配送区分名称';
-- Ver1.1 Add 2008/05/16
        SELECT xlv.lookup_code
              ,xlv.meaning
        INTO   lv_ship_method_code            -- 配送区分
              ,lv_ship_method_name            -- 配送区分名称
        FROM   xxcmn_lookup_values_v   xlv    -- クイックコード情報VIEW
        WHERE xlv.lookup_type = gc_lookup_ship_method_code
        AND   xlv.lookup_code = lr_ref.shipping_method_code
        ;
-- Ver1.1 Add 2008/05/16
      END IF;
-- Ver1.1 Add 2008/05/16
--
      --引取区分名称
-- Ver1.1 Add 2008/05/16
      IF lr_ref.takeback_class IS NOT NULL THEN
        lv_tablename := '引取区分名称';
-- Ver1.1 Add 2008/05/16
        SELECT xlv.lookup_code
              ,xlv.meaning
        INTO   lv_takeback_code               -- 引取区分
              ,lv_takeback_class              -- 引取区分名称
        FROM xxcmn_lookup_values_v   xlv      -- クイックコード情報VIEW
        WHERE xlv.lookup_type = gc_lookup_takeback_class
        AND   xlv.lookup_code = lr_ref.takeback_class
        ;
-- Ver1.1 Add 2008/05/16
      END IF;
-- Ver1.1 Add 2008/05/16
--
      --運賃区分
      SELECT xlv.lookup_code
            ,xlv.meaning
      INTO   lv_freight_charge_code         -- 運賃区分
            ,lv_freight_charge_class        -- 運賃区分名称
      FROM xxcmn_lookup_values_v   xlv      -- クイックコード情報VIEW
      WHERE xlv.lookup_type = gc_xxwsh_freight_class
      AND   xlv.lookup_code = lr_ref.freight_charge_class
      ;
--
--
      -- 使用目的が２：指示
      IF( gr_param.use_purpose = gc_use_purpose_shij)THEN
        lv_dept := lr_ref.instruction_dept;--指示部署
      ELSE
        lv_dept := lr_ref.performance_management_dept;--成績管理部署
     END IF;
--
      --部署情報取得
      xxcmn_common_pkg.get_dept_info(
                     iv_dept_cd          => lv_dept                      -- 部署コード
                    ,id_appl_date        => FND_DATE.CANONICAL_TO_DATE(gr_param.shipped_date_from)   -- 出庫日
                    ,ov_postal_code      => lv_dept_postal_code          -- 郵便番号
                    ,ov_address          => lv_dept_address              -- 住所
                    ,ov_tel_num          => lv_dept_tel_num              -- 電話番号
                    ,ov_fax_num          => lv_dept_fax_num              -- FAX番号
                    ,ov_dept_formal_name => lv_dept_formal_name          -- 部署正式名
                    ,ov_errbuf           => lv_errbuf                    -- エラー・メッセージ
                    ,ov_retcode          => lv_retcode                   -- リターン・コード
                    ,ov_errmsg           => lv_errmsg                    -- ユーザー・エラー・メッセージ
                    );
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt ;
      END IF ;
--
      -- ====================================================
      -- 依頼NOブレイク
      -- ====================================================
      IF ( lr_ref.request_no <>lv_tmp_request_no  ) THEN
        -- ----------------------------------------------------
        -- グループ終了タグ出力
        -- ----------------------------------------------------
        -- 初回レコードの場合は表示しない
        IF ( lv_tmp_request_no <> '*' ) THEN
          -- リストグループ終了タグ（品目）
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_ship' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- リストグループ終了タグ（品目）
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_ship' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- グループ終了タグ（依頼No）
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_request' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
--
        -- ----------------------------------------------------
        -- グループ開始タグ出力
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_request' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- 依頼Ｎｏ
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'request_no' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.request_no ;
--
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_ship' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;

        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_ship' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- ----------------------------------------------------
        -- データタグ出力
        -- ----------------------------------------------------
        -- 取引先
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'vendor_code';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.vendor_code;
        -- 取引先名称
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'vendor_name';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.4.2
--        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.vendor_name;
        IF (length(substrb(lr_ref.vendor_name,40,2)) = 1) THEN
          gt_xml_data_table(gl_xml_idx).tag_value := substrb(lr_ref.vendor_name,1,39) || substrb(lr_ref.vendor_name,40,2);
        ELSE
          gt_xml_data_table(gl_xml_idx).tag_value := substrb(lr_ref.vendor_name,1,40);
        END IF;
--mod end 1.4.2
--add start 1.4.2
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'vendor_name2';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        IF (length(substrb(lr_ref.vendor_name,40,2)) = 1) THEN
          gt_xml_data_table(gl_xml_idx).tag_value := substrb(lr_ref.vendor_name,42,20);
        ELSE
          gt_xml_data_table(gl_xml_idx).tag_value := substrb(lr_ref.vendor_name,41,20);
        END IF;
--add end 1.4.2
        -- 配送先
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'deliver_to_code';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.deliver_to_code;
        -- 配送先名称
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'deliver_to';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.4.2
--        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.deliver_to_name;
        IF (length(substrb(lr_ref.deliver_to_name,40,2)) = 1) THEN
          gt_xml_data_table(gl_xml_idx).tag_value := substrb(lr_ref.deliver_to_name,1,39) || substrb(lr_ref.deliver_to_name,40,2);
        ELSE
          gt_xml_data_table(gl_xml_idx).tag_value := substrb(lr_ref.deliver_to_name,1,40);
        END IF;
--mod end 1.4.2
--add start 1.4.2
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'deliver_to2';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        IF (length(substrb(lr_ref.deliver_to_name,40,2)) = 1) THEN
          gt_xml_data_table(gl_xml_idx).tag_value := substrb(lr_ref.deliver_to_name,42,20);
        ELSE
          gt_xml_data_table(gl_xml_idx).tag_value := substrb(lr_ref.deliver_to_name,41,20);
        END IF;
--add end 1.4.2
        -- 住所1
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'deliver_to_address1';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.address1;
        -- 住所2
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'deliver_to_address2';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.address2;
        -- 出庫倉庫コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'shipped_locat_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.shipped_locat_code;
        -- 出庫倉庫名称
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'shipped_locat_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.shipped_locat_name;
        -- 出庫日
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(lr_ref.ship_date,'YYYY/MM/DD') ;
        -- 入庫日
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'arvl_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(lr_ref.arrival_date,'YYYY/MM/DD') ;
        -- 引取区分
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'takeback_class';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lv_takeback_code;
        -- 引取区分名称
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'takeback_class_name';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lv_takeback_class;
        -- 着荷時間From
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'arrival_time_from' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lv_arrival_time_from;
        -- 着荷時間To
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'arrival_time_to';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lv_arrival_time_to;
        -- 運賃区分
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'freight_charge_class';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lv_freight_charge_code;
        -- 運賃区分名称
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'freight_charge_class_name';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lv_freight_charge_class;
-- 2008/06/23 v1.5 Y.Yamamoto Update Start
      -- 運賃区分もしくは、強制出力区分が「対象」のときに、運送会社情報を出力する。
      IF  (lr_ref.freight_charge_class   = '1')      -- 運賃区分が対象
       OR (lr_ref.complusion_output_code = '1') THEN -- 強制出力区分が対象
        -- 運送会社コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'freight_carrier_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.party_number;
        -- 運送会社名称
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'freight_carrier_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.party_short_name;
      END IF;
-- 2008/06/23 v1.5 Y.Yamamoto Update End
        -- 配送区分コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'shipping_method_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lv_ship_method_code ;
        -- 配送区分名称
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'shipping_method_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lv_ship_method_name ;
        -- 配送Ｎｏ
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'delivery_no' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.delivery_no ;
        -- 発注Ｎｏ
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'po_no';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.po_no;
-- 2008/06/23 v1.5 Y.Yamamoto ADD Start
        -- 元依頼Ｎｏ
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'base_request_no';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.base_request_no;
-- 2008/06/23 v1.5 Y.Yamamoto ADD End
        -- 摘要
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'shipping_instructions';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.shipping_instructions;
--
        -- 郵便番号
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'postcode';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.zip;
        -- 送付元住所
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'address';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := lv_dept_address;
        -- 電話番号
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'tel_no';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := lv_dept_tel_num;
        -- FAX番号
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'fax_no';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := lv_dept_fax_num;
        -- 部署正式名
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
-- Ver1.2 Changed 2008/05/19
--        gt_xml_data_table(gl_xml_idx).tag_name  := 'lv_dept_formal_name';
        gt_xml_data_table(gl_xml_idx).tag_name  := 'dept';
-- Ver1.2 Changed 2008/05/19
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := lv_dept_formal_name;
--
        -- ----------------------------------------------------
        -- ブレイク判断用項目の退避
        -- ----------------------------------------------------
        lv_tmp_request_no := lr_ref.request_no ;
--
      END IF ;
--
      -- ====================================================
      -- 明細情報出力
      -- ====================================================
--
      -- ----------------------------------------------------
      -- 総数の編集
      -- ----------------------------------------------------
-- mod start 1.7
--2008/09/19 Mod ↓
/*
      --受注タイプが返品の場合
      IF (lr_ref.order_category_code = cv_order) THEN
*/
      --受注タイプIDが訂正の場合
--      IF (lr_ref.order_type_id = cn_type_id) THEN
      IF (lr_ref.order_type_id = gn_type_id) THEN
--2008/09/19 Mod ↑
-- mod end 1.7
        ln_quantity      := ABS(lr_ref.quantity) * -1;
      ELSE
        ln_quantity      := ABS(lr_ref.quantity);
      END IF;
      -- ----------------------------------------------------
      -- グループ開始タグ（明細）
      -- ----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
      -- ----------------------------------------------------
      -- データタグ出力
      -- ----------------------------------------------------
--
      -- 品目コード
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'item_code' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.item_no;
      -- 品目名称
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'item_name' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.item_short_name;
      -- 付帯コード
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'futai_code' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.futai_code;
      -- ----------------------------------------------------
      -- ロット情報の編集
      -- ----------------------------------------------------
      -- パラメータ使用目的が依頼の場合
      IF (gr_param.use_purpose = gc_use_purpose_irai) THEN
          -- ロットＮｏ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lot_no' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := NULL;
          -- 製造日
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'product_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := NULL;
          -- 賞味期限
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'use_by_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := NULL;
          -- 固有記号
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'original_char' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := NULL;
      -- ロット管理品外
      ELSIF (lr_ref.lot_ctl = gc_lot_ctl_n ) THEN
          -- ロットＮｏ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lot_no' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := NULL;
          -- 製造日
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'product_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := NULL;
          -- 賞味期限
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'use_by_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := NULL;
          -- 固有記号
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'original_char' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := NULL;
      ELSE
        -- ロットＮｏ
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lot_no' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.lot_no;
        -- 製造日
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'product_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.product_date;
        -- 賞味期限
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'use_by_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.use_by_date;
        -- 固有記号
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'original_char' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.original_char;
      END IF;
--      
      -- 総数
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'orderd_quantity' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := ln_quantity;
      -- 単位
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'item_um' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.uom_code;
--
      -- ----------------------------------------------------
      -- グループ終了タグ（明細）
      -- ----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
--
    END LOOP main_data_loop ;
--
    -- ====================================================
    -- グループ終了タグ出力
    -- ====================================================
    -- リストグループ終了タグ
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_ship' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- リストグループ終了タグ（出庫）
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_ship' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- グループ終了タグ（依頼No）
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_request' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ====================================================
    -- リストグループ終了タグ（依頼）
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_locat' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ====================================================
    -- カーソルクローズ
    -- ====================================================
    CLOSE lc_ref ;
    -- ====================================================
    -- アウトパラメータセット
    -- ====================================================
    ov_errbuf  := lv_errbuf ;     --    エラー・メッセージ           --# 固定 #
    ov_retcode := lv_retcode ;    --    リターン・コード             --# 固定 #
    ov_errmsg  := lv_errmsg ;     --    ユーザー・エラー・メッセージ --# 固定 #
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                             --*** 存在チェック例外 ***
      -- エラーメッセージ取得
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gc_po_application,         -- アプリケーション短縮名：XXPO
                            gc_err_code_sikyuno_data,  -- メッセージ：APP-XXPO-10026 APP-XXPO-10026
                            'TABLE',   -- トークン：テーブル名
                            lv_tablename
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      ov_errmsg := lv_errmsg;                                                   --# 任意 #
      ov_errbuf := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
--##### 固定例外処理部 START #######################################################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF ( lc_ref%ISOPEN ) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( lc_ref%ISOPEN ) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( lc_ref%ISOPEN ) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### 固定例外処理部 END   #######################################################################
  END prc_create_out_data ;
--
--
  /************************************************************************************************
   * Procedure Name   : prc_create_sql
   * Description      : データ抽出処理
   ************************************************************************************************/
  PROCEDURE prc_create_sql
    (
      ov_errbuf     OUT    VARCHAR2         --    エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT    VARCHAR2         --    リターン・コード             --# 固定 #
     ,ov_errmsg     OUT    VARCHAR2         --    ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ==================================================
    -- 固定ローカル定数
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_sql' ; -- プログラム名
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
    lv_select     VARCHAR2(32000) ;
    lv_from       VARCHAR2(32000) ;
    lv_where      VARCHAR2(32000) ;
    lv_where_1    VARCHAR2(32000) ;
    lv_order_by   VARCHAR2(32000) ;
--
  BEGIN
--
--##### 固定ステータス初期化部 START #################################
    ov_retcode := gv_status_normal;
--##### 固定ステータス初期化部 END   #################################
--
    -- ====================================================
    -- ＳＥＬＥＣＴ句生成
    -- ====================================================
    lv_select := ' SELECT'
      ||' xoha.request_no                  AS request_no'                  --依頼No
      ||',xvv.segment1                     AS vendor_code'                 --取引先コード
      ||',xvv.vendor_full_name             AS vendor_name'                 --取引先名称
      ||',xvsv.vendor_site_code            AS deliver_to_code'             --配送先コード
      ||',xvsv.vendor_site_name            AS deliver_to_name'             --配送先名称
      ||',xvsv.zip                         AS zip'                         --郵便番号
      ||',xvsv.address_line1               AS address1'                    --住所1
      ||',xvsv.address_line2               AS address2'                    --住所2
-- Ver1.2 Changed 2008/05/19
--      ||',xssv.segment1                    AS shipped_locat_code'          --出庫倉庫コード
      ||',xilv.segment1                    AS shipped_locat_code'          --出庫倉庫コード
-- Ver1.2 Changed 2008/05/19
      ||',xilv.description                 AS shipped_locat_name'          --出庫倉庫
      ||',xoha.schedule_ship_date          AS ship_date'                   --出庫日
      ||',xoha.schedule_arrival_date       AS arrival_date'                --入庫日
      ||',xoha.takeback_class              AS takeback_class'              --引取区分
      ||',xoha.arrival_time_from           AS arrival_time_from'           --着荷時間From
      ||',xoha.arrival_time_to             AS arrival_time_to'             --着荷時間To
      ||',xoha.freight_charge_class        AS freight_charge_class'        --運賃区分
      ||',xxcv.party_number                AS party_number'                --運送会社
      ||',xxcv.party_short_name            AS party_short_name'            --運送会社名称
      ||',xoha.shipping_method_code        AS shipping_method_code'        --配送区分
      ||',xoha.delivery_no                 AS delivery_no'                 --配送No
      ||',xoha.po_no                       AS po_no'                       --発注No
-- 2008/06/23 v1.5 Y.Yamamoto ADD Start
      ||',xoha.base_request_no             AS base_request_no'             --元依頼No
      ||',xxcv.complusion_output_code      AS complusion_output_code'      --強制出力区分
-- 2008/06/23 v1.5 Y.Yamamoto ADD End
      ||',xoha.shipping_instructions       AS shipping_instructions'       --摘要
      ||',xoha.performance_management_dept AS performance_management_dept' --成績管理部署
      ||',xoha.instruction_dept            AS instruction_dept'            --指示部署
      ||',ximv.item_no                     AS item_no'                     --品目コード
      ||',ximv.item_short_name             AS item_short_name'             --品目名称
      ||',xola.futai_code                  AS futai_code'                  --付帯コード
      ||',otta.attribute11                 AS shipping_provide'            --出荷支給受払カテゴリ
      ||',ximv.lot_ctl                     AS lot_ctl'                     --ロット管理区分
      ||',otta.order_category_code         AS order_category_code'         --受注カテゴリ
      ||',xola.uom_code                    AS uom_code'                    --単位
       ;
    -- パラメータ使用目的が１：依頼
    IF (gr_param.use_purpose = gc_use_purpose_irai) THEN
      lv_select := lv_select
        ||',xola.based_request_quantity    AS quantity'                    --拠点依頼数量
        ||',0                              AS lot_no'                      --ロット番号
        ||',''1900/01/01''                 AS product_date'                --製造日
        ||',''1900/01/01''                 AS use_by_date'                 --賞味期限
        ||',''A''                          AS original_char'               --固有記号
        ;
    -- パラメータ使用目的が２：指示または、３：返品
    ELSIF ((gr_param.use_purpose = gc_use_purpose_shij)
      OR   (gr_param.use_purpose = gc_use_purpose_henpin))
    THEN
        lv_select := lv_select
          || ',xmld.actual_quantity       AS quantity'                     --実績数量
          ||',ilm.lot_no                  AS lot_no'                       --ロット番号
          ||',ilm.attribute1              AS product_date'                 --製造日
          ||',ilm.attribute3              AS use_by_date'                  --賞味期限
          ||',ilm.attribute2              AS original_char'                --固有記号
          ;
    END IF;
--2008/09/19 Add ↓
    lv_select := lv_select
      ||',xoha.order_type_id              AS order_type_id';               -- 受注タイプID
--2008/09/19 Add ↑
--
    -- ====================================================
    -- ＦＲＯＭ句生成
    -- ====================================================
    lv_from   := ' FROM'
      ||' oe_transaction_types_all   otta '-- 受注タイプ
      ||',xxwsh_order_headers_all    xoha '-- 受注ヘッダアドオン
      ||',xxwsh_order_lines_all      xola '-- 受注明細アドオン
      ||',xxcmn_vendor_sites2_v      xvsv '-- 仕入先サイトView
      ||',xxcmn_item_mst2_v          ximv '-- OPM品目情報View
      ||',xxcmn_item_categories4_v   xicv '-- OPM品目カテゴリ割当View
      ||',xxcmn_vendors2_v           xvv  '-- 仕入先情報view
      ||',xxcmn_item_locations2_v    xilv '-- OPM保管場所情報view
      ||',xxcmn_carriers2_v          xxcv '-- 運送業者情報view
      ||',xxpo_security_supply_v     xssv '-- 有償支給セキュリティVIEW
      ;
    -- パラメータ使用目的が１：依頼以外
    IF (gr_param.use_purpose <> gc_use_purpose_irai) THEN
      lv_from := lv_from
        || ',xxinv_mov_lot_details   xmld '-- 移動ロット詳細
        || ',ic_lots_mst             ilm  '-- OPMロットマスタ
        ;
    END IF;
--
    -- ====================================================
    -- ＷＨＥＲＥ句生成
    -- ====================================================
    lv_where := 'WHERE'
      ||'      xoha.order_type_id            = otta.transaction_type_id'            -- 受注タイプ
      ||' AND  otta.org_id                   = '''|| gn_prof_org_id   ||''''        -- 営業単位
      ||' AND  otta.attribute1               = '''|| gc_sp_class_prov ||''''        -- 出荷支給区分
      ||' AND  xoha.latest_external_flag     = '''|| gc_yn_div_y      ||''''        -- 最新フラグ
      ||' AND  xoha.vendor_id                = xvv.vendor_id'                       -- 仕入先ID
--add start 1.4.1
      --適用日管理(仕入先情報view)
      ||' AND FND_DATE.CANONICAL_TO_DATE('''||gr_param.shipped_date_from ||''')'-- パラメータ.出庫日From
      ||'   BETWEEN xvv.start_date_active'                                          -- 適用開始日
      ||'   AND NVL(xvv.end_date_active,'                                           -- 適用終了日
      ||'     FND_DATE.CANONICAL_TO_DATE('''||gr_param.shipped_date_from ||''')'
      ||'   )'
--add end 1.4.1
      ||' AND  xoha.vendor_site_id           = xvsv.vendor_site_id'                 -- 仕入先サイトID
--add start 1.4.1
      --適用日管理(仕入先サイトview)
      ||' AND FND_DATE.CANONICAL_TO_DATE('''||gr_param.shipped_date_from ||''')'-- パラメータ.出庫日From
      ||'   BETWEEN xvsv.start_date_active'                                         -- 適用開始日
      ||'   AND NVL(xvsv.end_date_active,'                                          -- 適用終了日
      ||'     FND_DATE.CANONICAL_TO_DATE('''||gr_param.shipped_date_from ||''')'
      ||'   )'
--add end 1.4.1
-- Ver1.1 Changed 2008/05/16
--      ||' AND  xoha.deliver_to_id            = xilv.inventory_location_id'          -- 保管場所ID
--      ||' AND  xoha.career_id                = xxcv.party_id'                       -- パーティID
      ||' AND  xoha.deliver_from_id          = xilv.inventory_location_id'          -- 保管場所ID
      ||' AND  xoha.career_id                = xxcv.party_id(+) '                       -- パーティID
-- Ver1.1 Changed 2008/05/16
--add start 1.4.1
      --適用日管理(OPM保管場所情報view)
      ||' AND FND_DATE.CANONICAL_TO_DATE('''||gr_param.shipped_date_from ||''')'-- パラメータ.出庫日From
      ||'   BETWEEN xilv.date_from'                                                 -- 適用開始日
      ||'   AND NVL(xilv.date_to,'                                                  -- 適用終了日
      ||'     FND_DATE.CANONICAL_TO_DATE('''||gr_param.shipped_date_from ||''')'
      ||'   )'
      --適用日管理(運送業者情報view)
      ||' AND FND_DATE.CANONICAL_TO_DATE('''||gr_param.shipped_date_from ||''')'-- パラメータ.出庫日From
      ||'   BETWEEN xxcv.start_date_active(+)'                                         -- 適用開始日
      ||'   AND NVL(xxcv.end_date_active(+),'                                          -- 適用終了日
      ||'      FND_DATE.CANONICAL_TO_DATE('''||gr_param.shipped_date_from ||''')'
      ||'   )'
--add end 1.4.1
      ||' AND  xoha.request_no
                 = NVL('''|| gr_param.request_no||''',xoha.request_no)'             -- パラメータ依頼No
      ||' AND  xoha.instruction_dept
                 = NVL('''|| gr_param.exec_user_dept ||''',xoha.instruction_dept)'  -- パラメータ担当部署
      ||' AND  xoha.last_updated_by
                 = NVL('''|| gr_param.update_exec_user||''',xoha.last_updated_by)'  -- パラメータ更新者
      ||' AND  xoha.last_update_date'                                               -- 最終更新日
      ||' BETWEEN FND_DATE.CANONICAL_TO_DATE('''||gr_param.update_date_from ||''')' -- パラメータ更新日時FROM
      ||'     AND FND_DATE.CANONICAL_TO_DATE('''||gr_param.update_date_to   ||''')' -- パラメータ更新日時To
      ||' AND  xoha.vendor_code = NVL('''|| gr_param.vendor||''',xoha.vendor_code)' -- パラメータ取引先
      ||' AND  xoha.vendor_site_code
                  = NVL('''|| gr_param.deliver_to||''',xoha.vendor_site_code)'      -- パラメータ配送先
      ||' AND  xoha.deliver_from     
                  =NVL( '''|| gr_param.shipped_locat_code ||''',xoha.deliver_from)' -- パラメータ出庫倉庫
      ||' AND  xoha.schedule_ship_date'                                             -- 出荷予定日
      ||' BETWEEN FND_DATE.CANONICAL_TO_DATE('''||gr_param.shipped_date_from ||''')'-- パラメータ出庫日From
      ||'     AND FND_DATE.CANONICAL_TO_DATE('''||gr_param.shipped_date_to   ||''')'-- パラメータ出庫日To
      ||' AND  xoha.order_header_id          = xola.order_header_id'               -- 受注ヘッダアドオンID
      ||' AND  xola.delete_flag              = '''|| gc_yn_div_n ||''''            -- 削除フラグ
      ||' AND  xola.shipping_item_code       = ximv.item_no'                       -- OPM品目マスタ結合
      ||' AND  ximv.item_id                  = xicv.item_id'                       -- 品目ID
--add start 1.4.1
      --適用日管理(OPM品目情報View)
      ||' AND FND_DATE.CANONICAL_TO_DATE('''||gr_param.shipped_date_from ||''')'-- パラメータ.出庫日From
      ||'   BETWEEN ximv.start_date_active'                                         -- 適用開始日
      ||'   AND NVL(ximv.end_date_active,'                                          -- 適用終了日
      ||'     FND_DATE.CANONICAL_TO_DATE('''||gr_param.shipped_date_from ||''')'
      ||'   )'
--add end 1.4.1
      ||' AND  xicv.prod_class_code
                  = NVL('''|| gr_param.prod_class||''', xicv.prod_class_code )'    -- パラメータ条件．商品区分
      ||' AND  xicv.item_class_code
                  = NVL('''|| gr_param.item_class||''', xicv.item_class_code )'    -- パラメータ条件．品目区分
      ||' AND  xssv.user_id                ='''|| gn_user_id ||''''                -- ログインユーザID セキュリティVIEW
      ||' AND  xssv.security_class         ='''|| gr_param.security_class||''''    -- パラメータセキュリティ区分
      ||' AND  xoha.vendor_code       = NVL(xssv.vendor_code,xoha.vendor_code)'    -- 取引先
      ||' AND  xoha.vendor_site_code
                           = NVL(xssv.vendor_site_code,xoha.vendor_site_code)'     -- 取引先サイト
      ||' AND  xoha.deliver_from            = NVL(xssv.segment1,xoha.deliver_from)'-- 出庫倉庫コード
      ;
    -- パラメータ使用目的が２：指示
    IF (gr_param.use_purpose = gc_use_purpose_shij) THEN
      lv_where := lv_where
        ||' AND xola.order_line_id = xmld.mov_line_id'                 -- 移動ロット詳細
        ||' AND xmld.document_type_code ='''|| gc_doc_type_prov ||'''' -- 文書タイプ 支給指示
        ||' AND xmld.record_type_code   ='''|| gc_rec_type_inst ||'''' -- レコードタイプ 指示
        ||' AND xmld.lot_id             = ilm.lot_id'                  -- ロットID
-- Ver1.1 Add 2008/05/16
        ||' AND xmld.item_id             = ilm.item_id'                  -- 品目ID
-- Ver1.1 Add 2008/05/16
        ;
    -- パラメータ使用目的が３：返品
    ELSIF (gr_param.use_purpose = gc_use_purpose_henpin) THEN
      lv_where := lv_where
        ||' AND xola.order_line_id      = xmld.mov_line_id '               -- 移動ロット詳細
        ||' AND xmld.document_type_code ='''|| gc_doc_type_prov ||''''     -- 文書タイプ 支給指示
        ||' AND xmld.record_type_code   ='''|| gc_rec_type_stck ||''''     -- レコードタイプ 出庫実績
        ||' AND xmld.lot_id             = ilm.lot_id '                     -- ロットID
-- Ver1.1 Add 2008/05/16
        ||' AND xmld.item_id             = ilm.item_id'                  -- 品目ID
-- Ver1.1 Add 2008/05/16
        ||' AND xoha.req_status         ='''|| gc_req_status_s_cmpc  ||''''-- ステータス　出荷実績計上済
        ||' AND otta.attribute11        ='''|| gc_shipping_provide_h ||''''-- 出荷支給受払カテゴリ
        ;
    END IF;
--
-- Ver1.3 Mod 2008/05/20
/**
    --パラメータ使用目的が1:依頼、2：指示
    IF ((gr_param.use_purpose = gc_use_purpose_irai)
      OR(gr_param.use_purpose = gc_use_purpose_shij))
    THEN
      lv_where := lv_where
        || ' AND xoha.req_status'                               -- 受注ステータス
        || ' BETWEEN '''|| gc_req_status_s_cmpb ||''''          -- 受領済
        || '     AND '''|| gc_req_status_p_ccl  ||''''          -- 取消
        || ' AND otta.attribute11 = '''|| gc_shipping_provide_s ||''''-- 出荷支給受払カテゴリ
        ;
    END
**/
    --パラメータ使用目的が1:依頼
    IF (gr_param.use_purpose = gc_use_purpose_irai) THEN
      lv_where := lv_where
        || ' AND xoha.req_status'                               -- 受注ステータス
        || ' BETWEEN '''|| gc_req_status_s_cmpa ||''''          -- 入力完了済
        || '     AND '''|| gc_req_status_p_ccl  ||''''          -- 取消
        || ' AND otta.attribute11 = '''|| gc_shipping_provide_s ||''''-- 出荷支給受払カテゴリ
        ;
    --パラメータ使用目的が1:依頼、2：指示
    ELSIF (gr_param.use_purpose = gc_use_purpose_shij) THEN
      lv_where := lv_where
        || ' AND xoha.req_status'                               -- 受注ステータス
        || ' BETWEEN '''|| gc_req_status_s_cmpb ||''''          -- 受領済
        || '     AND '''|| gc_req_status_p_ccl  ||''''          -- 取消
        || ' AND otta.attribute11 = '''|| gc_shipping_provide_s ||''''-- 出荷支給受払カテゴリ
        ;
    END IF;
-- Ver1.3 Mod 2008/05/20
--
    --使用目的が2：指示
    IF( gr_param.use_purpose = gc_use_purpose_shij)THEN
      --有償セキュリティ区分が「１：伊藤園、３：出庫倉庫(東洋埠頭)」
      IF(( gr_param.security_class = gc_security_div_i)
        OR(gr_param.security_class = gc_security_div_l))
      THEN
        lv_where := lv_where
          || ' AND xola.quantity = xola.reserved_quantity'
          ;
      --有償セキュリティ区分が「２：取引先(有償先)、４：出庫倉庫(東洋埠頭以外)」
      ELSIF(( gr_param.security_class = gc_security_div_d)
        OR  ( gr_param.security_class = gc_security_div_lt))
      THEN
        lv_where := lv_where
          || ' AND xoha.notif_status ='''|| gc_notif_status_ok||'''' -- 通知ステータス　40：確定通知済
          ;
      END IF;
    END IF;
--
--
    -- ====================================================
    -- ORDER BY句生成
    -- ====================================================
    lv_order_by := ' ORDER BY'
      || ' xoha.request_no'
      || ',xvv.segment1'
      || ',xvsv.vendor_site_code'
      || ',xilv.segment1'
      || ',xoha.schedule_ship_date'
      || ',xola.order_line_number'
    ;
--
    gv_sql := lv_select || lv_from || lv_where || lv_order_by;
--
  EXCEPTION
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
  END prc_create_sql ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : ＸＭＬデータ編集
   ************************************************************************************************/
  PROCEDURE prc_create_xml_data
    (
      ov_errbuf     OUT    VARCHAR2         --    エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT    VARCHAR2         --    リターン・コード             --# 固定 #
     ,ov_errmsg     OUT    VARCHAR2         --    ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ==================================================
    -- 定  数  宣  言
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data' ; -- プログラム名
--
--##### 固定ローカル変数宣言部 START #################################
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--##### 固定ローカル変数宣言部 END   #################################
--
  BEGIN
--
--##### 固定ステータス初期化部 START #################################
    ov_retcode := gv_status_normal;
--##### 固定ステータス初期化部 END   #################################
--
--
    -- ====================================================
    -- ＸＭＬデータ出力処理
    -- ====================================================
    prc_create_out_data
      (
        ov_errbuf     => lv_errbuf
       ,ov_retcode    => lv_retcode
       ,ov_errmsg     => lv_errmsg
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE check_create_xml_expt ;
    END IF ;
--
    -- ====================================================
    -- アウトパラメータセット
    -- ====================================================
    ov_errbuf  := lv_errbuf ;     --    エラー・メッセージ           --# 固定 #
    ov_retcode := lv_retcode ;    --    リターン・コード             --# 固定 #
    ov_errmsg  := lv_errmsg ;     --    ユーザー・エラー・メッセージ --# 固定 #
--
  EXCEPTION
    -- ＸＭＬデータ編集の例外
    WHEN check_create_xml_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
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
    IF ( ic_type = 'D' ) THEN
-- Ver1.5 Mod 2008/07/11
--      lv_convert_data := '<'||iv_name||'>'||iv_value||'</'||iv_name||'>' ;
      lv_convert_data := '<'||iv_name||'><![CDATA['||iv_value||']]></'||iv_name||'>' ;
-- Ver1.5 Mod 2008/07/11
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
      iv_use_purpose        IN     VARCHAR2         -- 01 : 使用目的
     ,iv_request_no         IN     VARCHAR2         -- 02 : 依頼No
     ,iv_exec_user_dept     IN     VARCHAR2         -- 03 : 担当部署
     ,iv_update_exec_user   IN     VARCHAR2         -- 04 : 更新担当
     ,iv_update_date_from   IN     VARCHAR2         -- 05 : 更新日付From
     ,iv_update_date_to     IN     VARCHAR2         -- 06 : 更新日付To
     ,iv_vendor             IN     VARCHAR2         -- 07 : 取引先
     ,iv_deliver_to         IN     VARCHAR2         -- 08 : 配送先
     ,iv_shipped_locat_code IN     VARCHAR2         -- 09 : 出庫倉庫
     ,iv_shipped_date_from  IN     VARCHAR2         -- 10 : 出庫日From
     ,iv_shipped_date_to    IN     VARCHAR2         -- 11 : 出庫日To
     ,iv_prod_class         IN     VARCHAR2         -- 12 : 商品区分
     ,iv_item_class         IN     VARCHAR2         -- 13 : 品目区分
     ,iv_security_class     IN     VARCHAR2         -- 14 : 有償セキュリティ区分
     ,ov_errbuf             OUT    VARCHAR2         -- エラー・メッセージ           --# 固定 #
     ,ov_retcode            OUT    VARCHAR2         -- リターン・コード             --# 固定 #
     ,ov_errmsg             OUT    VARCHAR2         -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- *** ローカル変数 ***
    lv_xml_string           VARCHAR2(32000) ;
    ln_retcode              NUMBER ;
    lv_err_code             VARCHAR2(15);
--
    get_parm_value_expt     EXCEPTION ;     --パラメータ値取得エラー
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
    gr_param.use_purpose         := iv_use_purpose;              -- 01 : 使用目的
    gr_param.request_no          := iv_request_no;               -- 02 : 依頼No
    gr_param.exec_user_dept      := iv_exec_user_dept;           -- 03 : 担当部署
    gr_param.update_exec_user    := iv_update_exec_user;         -- 04 : 更新担当
-- Ver1.2 Changed 2008/05/19
--    gr_param.update_date_from    := SUBSTR(iv_update_date_from ,1 ,10); -- 05 : 更新日付From
--    gr_param.update_date_to      := SUBSTR(iv_update_date_to ,1 ,10);   -- 06 : 更新日付To
    gr_param.update_date_from    := NVL(iv_update_date_from
                                      , FND_PROFILE.VALUE( 'XXCMN_MIN_DATE' ) || ' 00:00:00');  -- 05 : 更新日付From
    gr_param.update_date_to      := NVL(iv_update_date_to
                                      , FND_PROFILE.VALUE( 'XXCMN_MAX_DATE' ) || ' 23:59:59');  -- 06 : 更新日付To
-- Ver1.2 Changed 2008/05/19
    gr_param.vendor              := iv_vendor;                   -- 07 : 取引先
    gr_param.deliver_to          := iv_deliver_to;               -- 08 : 配送先
    gr_param.shipped_locat_code  := iv_shipped_locat_code;       -- 09 : 出庫倉庫
-- Ver1.2 Changed 2008/05/19
--    gr_param.shipped_date_from   := SUBSTR(iv_shipped_date_from , 1 ,10); -- 10 : 出庫日From
--    gr_param.shipped_date_to     := SUBSTR(iv_shipped_date_to , 1,10);    -- 11 : 出庫日To
    gr_param.shipped_date_from   := SUBSTR(NVL(iv_shipped_date_from , FND_PROFILE.VALUE( 'XXCMN_MIN_DATE' ))
                                           , 1 ,10); -- 10 : 出庫日From
    gr_param.shipped_date_to     := SUBSTR(NVL(iv_shipped_date_to , FND_PROFILE.VALUE( 'XXCMN_MIN_DATE' ))
                                           , 1,10);    -- 11 : 出庫日To
-- Ver1.2 Changed 2008/05/19
    gr_param.prod_class          := iv_prod_class;               -- 12 : 商品区分
    gr_param.item_class          := iv_item_class;               -- 13 : 品目区分
    gr_param.security_class      := iv_security_class;           -- 14 : 有償セキュリティ区分
--
    -- -----------------------------------------------------
    -- ログイン情報退避（ＷＨＯカラム用）
    -- -----------------------------------------------------
    gn_created_by             := FND_GLOBAL.USER_ID ;           -- 作成者
    gn_last_updated_by        := FND_GLOBAL.USER_ID ;           -- 最終更新者
    gn_last_update_login      := FND_GLOBAL.LOGIN_ID ;          -- 最終更新ログイン
    gn_request_id             := FND_GLOBAL.CONC_REQUEST_ID ;   -- 要求ID
    gn_program_application_id := FND_GLOBAL.PROG_APPL_ID ;      -- ＣＰ・アプリケーションID
    gn_program_id             := FND_GLOBAL.CONC_PROGRAM_ID ;   -- コンカレント・プログラムID
--
-- add start 1.7
    -- -----------------------------------------------------
    -- 返品訂正情報設定
    -- -----------------------------------------------------
    SELECT xottv.transaction_type_id
    INTO   gn_type_id
    FROM   xxwsh_oe_transaction_types_v xottv
    WHERE  xottv.shipping_shikyu_class = '2'
    AND    xottv.ship_sikyu_rcv_pay_ctg = '06'
    AND    xottv.order_category_code = 'ORDER';
-- add end 1.7
--
    -- -----------------------------------------------------
    -- 帳票タイトル設定
    -- -----------------------------------------------------
    -- 依頼の場合
    IF ( gr_param.use_purpose = gc_use_purpose_irai ) THEN
      gv_report_name := gc_report_name_irai ;  --有償出庫依頼書
    -- 指示の場合
    ELSIF( gr_param.use_purpose = gc_use_purpose_shij ) THEN
      gv_report_name := gc_report_name_shij ;  --有償出庫指示書
    ELSE
      gv_report_name := gc_report_name_henpin ;--有償返品指示書
    END IF ;
--
    -- -----------------------------------------------------
    -- 営業単位取得
    -- -----------------------------------------------------
    gn_prof_org_id := FND_PROFILE.VALUE( gc_prof_org_id ) ;
    IF ( gn_prof_org_id IS NULL ) THEN
      lv_err_code := gc_err_code_no_prof ;
      RAISE get_parm_value_expt ;
    END IF ;
--
    -- =====================================================
    -- データ取得ＳＱＬ生成
    -- =====================================================
    prc_create_sql
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
    -- ログインユーザー情報出力
    -- =====================================================
    prc_create_xml_data_user
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
    -- 帳票タイトル
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'report_name' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gv_report_name ;
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
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    <lg_locat>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      <g_request>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        <lg_ship>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '          <g_ship>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        <msg>' || lv_errmsg || '</msg>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '          </g_ship>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        </lg_ship>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      </g_request>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    </lg_locat>' ) ;
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
        -- 編集したデータをタグに変換
      FOR i IN 1 .. gt_xml_data_table.COUNT LOOP
        -- 編集したデータをタグに変換
        lv_xml_string := convert_into_xml
                          (
                            iv_name   => gt_xml_data_table(i).tag_name  -- タグネーム
                           ,iv_value  => gt_xml_data_table(i).tag_value -- タグデータ
                           ,ic_type   => gt_xml_data_table(i).tag_type  -- タグタイプ
                          ) ;
        -- ＸＭＬタグ出力
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_xml_string) ;
      END LOOP xml_data_table ;
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
--
  EXCEPTION
    --*** 値取得エラー例外 ***
    WHEN get_parm_value_expt THEN
      -- メッセージセット
      lv_errmsg := xxcmn_common_pkg.get_msg
                    ( iv_application    => gc_po_application
                     ,iv_name           => lv_err_code
                    ) ;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
--
--#################################  固定例外処理部 START   ###################################
--
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
      -- ==================================================
      -- 中間テーブルロールバック
      -- ==================================================
      ROLLBACK ;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
      -- ==================================================
      -- 中間テーブルロールバック
      -- ==================================================
      ROLLBACK ;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
      -- ==================================================
      -- 中間テーブルロールバック
      -- ==================================================
      ROLLBACK ;
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
      errbuf                OUT     VARCHAR2   -- エラーメッセージ
     ,retcode               OUT     VARCHAR2   -- エラーコード
     ,iv_use_purpose         IN     VARCHAR2   -- 01 : 使用目的
     ,iv_request_no          IN     VARCHAR2   -- 02 : 依頼No
     ,iv_exec_user_dept      IN     VARCHAR2   -- 03 : 担当部署
     ,iv_update_exec_user    IN     VARCHAR2   -- 04 : 更新担当
     ,iv_update_date_from    IN     VARCHAR2   -- 05 : 更新日付From
     ,iv_update_date_to      IN     VARCHAR2   -- 06 : 更新日付To
     ,iv_vendor              IN     VARCHAR2   -- 07 : 取引先
     ,iv_deliver_to          IN     VARCHAR2   -- 08 : 配送先
     ,iv_shipped_locat_code  IN     VARCHAR2   -- 09 : 出庫倉庫
     ,iv_shipped_date_from   IN     VARCHAR2   -- 10 : 出庫日From
     ,iv_shipped_date_to     IN     VARCHAR2   -- 11 : 出庫日To
     ,iv_prod_class          IN     VARCHAR2   -- 12 : 商品区分
     ,iv_item_class          IN     VARCHAR2   -- 13 : 品目区分
     ,iv_security_class      IN     VARCHAR2   -- 14 : 有償セキュリティ区分
    )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ======================================================
    -- 固定ローカル定数
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'main' ;  -- プログラム名
    -- ======================================================
    -- ローカル変数
    -- ======================================================
    lv_errbuf               VARCHAR2(5000) ;   --   エラー・メッセージ
    lv_retcode              VARCHAR2(1) ;      --   リターン・コード
    lv_errmsg               VARCHAR2(5000) ;   --   ユーザー・エラー・メッセージ
--
    get_parm_value_expt     EXCEPTION ;        --   パラメータ値取得エラー
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
        iv_use_purpose        => iv_use_purpose                            -- 01 : 使用目的
       ,iv_request_no         => iv_request_no                             -- 02 : 依頼No
       ,iv_exec_user_dept     => iv_exec_user_dept                         -- 03 : 担当部署
       ,iv_update_exec_user   => iv_update_exec_user                       -- 04 : 更新担当
       ,iv_update_date_from   => iv_update_date_from                       -- 05 : 更新日付From
       ,iv_update_date_to     => iv_update_date_to                         -- 06 : 更新日付To
       ,iv_vendor             => iv_vendor                                 -- 07 : 取引先
       ,iv_deliver_to         => iv_deliver_to                             -- 08 : 配送先
       ,iv_shipped_locat_code => iv_shipped_locat_code                     -- 09 : 出庫倉庫
       ,iv_shipped_date_from  => iv_shipped_date_from                      -- 10 : 出庫日From
       ,iv_shipped_date_to    => NVL(iv_shipped_date_to, gc_max_date_char) -- 11 : 出庫日To
       ,iv_prod_class         => iv_prod_class                             -- 12 : 商品区分
       ,iv_item_class         => iv_item_class                             -- 13 : 品目区分
       ,iv_security_class     => iv_security_class                         -- 14 : 有償セキュリティ区分
       ,ov_errbuf             => lv_errbuf                                 -- エラー・メッセージ
       ,ov_retcode            => lv_retcode                                -- リターン・コード
       ,ov_errmsg             => lv_errmsg                                 -- ユーザー・エラー・メッセージ
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
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
  END main ;
--
--###########################  固定部 END   #######################################################
--
END xxpo440001c ;
/
