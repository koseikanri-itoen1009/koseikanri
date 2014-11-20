CREATE OR REPLACE PACKAGE BODY xxwsh920004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2007. All rights reserved.
 *
 * Package Name     : xxwsh920004c(body)
 * Description      : 出荷購入依頼一覧
 * MD.050/070       : 生産物流共通（出荷・移動仮引当）Issue1.0 (T_MD050_BPO_921)
 *                    生産物流共通（出荷・移動仮引当）Issue1.0 (T_MD070_BPO_92F)
 * Version          : 1.3
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  convert_into_xml          XMLデータ変換
 *  insert_xml_plsql_table    XMLデータ格納
 *  prc_initialize            前処理(D-1)
 *  prc_get_report_data       明細データ取得(D-2)
 *  prc_create_xml_data       ＸＭＬデータ作成(D-3)
 *  submain                   メイン処理プロシージャ
 *  main                      コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ------------------ -------------------------------------------------
 *  Date          Ver.  Editor             Description
 * ------------- ----- ------------------ -------------------------------------------------
 *  2008/03/25    1.0   Yoshitomo Kawasaki 新規作成
 *  2008/06/11    1.1   Kazuo Kumamoto     内部変更要求#131対応
 *  2008/07/08    1.2   Satoshi Yunba      禁則文字対応
 *  2008/11/19    1.3   Takao Ohashi       指摘623,663,665対応
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
  -- パッケージ名
  gv_pkg_name                  CONSTANT VARCHAR2(20)  := 'xxwsh920004c';
  -- 帳票ID
  gc_report_id                 CONSTANT VARCHAR2(12)  := 'XXWSH920004T';
  -- 出力タグタイプ（T：タグ）
  gc_tag_type_tag              CONSTANT VARCHAR2(1)   := 'T' ;
  -- 出力タグタイプ（D：データ）
  gc_tag_type_data             CONSTANT VARCHAR2(1)   := 'D' ;
  -- 出力タイプ（C：Char）
  gc_tag_value_type_char       CONSTANT VARCHAR2(1)   := 'C' ;
--
  ------------------------------
  -- クイックコード関連
  ------------------------------
  gc_final_unit_price_entered  CONSTANT VARCHAR2(1)   := 'Y' ;
  gc_lookup_cd_conreq          CONSTANT VARCHAR2(30)  := 'XXPO_AUTHORIZATION_STATUS' ;
--
  ------------------------------
  -- エラーメッセージ関連
  ------------------------------
  -- アプリケーション（XXCMN）
  gc_application_cmn           CONSTANT VARCHAR2(5)   := 'XXCMN' ;
  -- アプリケーション（XXPO）
  gc_application_po            CONSTANT VARCHAR2(5)   := 'XXPO' ;
  -- 担当部署名未取得メッセージ
  gc_xxpo_00036                CONSTANT VARCHAR2(14)  := 'APP-XXPO-00036' ;
  -- 担当者名未取得メッセージ
  gc_xxpo_00026                CONSTANT VARCHAR2(14)  := 'APP-XXPO-00026' ;
  -- データ未取得メッセージ
  gc_xxpo_00033                CONSTANT VARCHAR2(14)  := 'APP-XXPO-00033' ;
  -- 明細0件用メッセージ
  gc_xxcmn_10122               CONSTANT VARCHAR2(15)  := 'APP-XXCMN-10122' ;
  -- 日付妥当性エラーメッセージ
  gc_xxwip_10016               CONSTANT VARCHAR2(15)  := 'APP-XXWIP-10016' ;
  -- 発注ステータス
  gc_order_status_req_making   CONSTANT VARCHAR2(2)   := '10' ;  -- 依頼作成済
  gc_order_status_ordered      CONSTANT VARCHAR2(2)   := '15' ;  -- 発注済
  -- 出荷依頼ステータス
  gc_ship_status_delete        CONSTANT VARCHAR2(2)   := '99' ;  -- 取消
  -- 移動ステータス
  gc_mov_status_delete         CONSTANT VARCHAR2(2)   := '99' ;  -- 取消
  -- 取消フラグ
  gc_cancelled_flg             CONSTANT VARCHAR2(1)   := 'Y'  ;  -- 取消フラグ
  -- 削除フラグ
  gc_delete_flag               CONSTANT VARCHAR2(1)   := 'Y'  ;  -- 削除フラグ
  -- 削除(移動)フラグ
  gc_delete_mov_flag           CONSTANT VARCHAR2(1)   := 'Y'  ;  -- 削除(移動)フラグ
  -- 最新フラグ
  gc_new_flg                   CONSTANT VARCHAR2(1)   := 'Y'  ;  -- 最新フラグ
  -- 出荷支給区分
  gc_ship_pro_kbn_i            CONSTANT VARCHAR2(1)   := '1'  ;  -- 出荷依頼
  ------------------------------
  -- 項目編集関連
  ------------------------------
  -- 年月日フォーマット
  gc_char_d_format             CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD' ;
  gc_char_dt_format            CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS' ;
  gc_date_fmt_ymd_ja           CONSTANT VARCHAR2(20)  := 'YYYY"年"MM"月"DD"日' ;   -- 時分
  gc_max_date_d                CONSTANT VARCHAR2(10)  := '4712/12/31';
  gc_min_date_d                CONSTANT VARCHAR2(10)  := '1900/01/01';
  gc_max_date_dt               CONSTANT VARCHAR2(19)  := '4712/12/31 23:59:59';
  gc_min_date_dt               CONSTANT VARCHAR2(19)  := '1900/01/01 00:00:00';
  -- 数値フォーマット
  gc_num_5                   CONSTANT  VARCHAR2(10) := '99990.900' ;      -- 5,3
  gc_num_7                   CONSTANT  VARCHAR2(15) := '9999990.90' ;     -- 7,2
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 入力パラメータ格納用レコード変数
  TYPE rec_param_data  IS RECORD 
    (
       iv_delivery_dest     VARCHAR2(30)    -- 01:納入先
      ,iv_delivery_form     VARCHAR2(240)   -- 02:出庫形態
      ,iv_delivery_date     DATE            -- 03:納期
      ,iv_delivery_day_from DATE            -- 04:出庫日From
      ,iv_delivery_day_to   DATE            -- 05:出庫日To
    ) ;
--
  -- 出荷購入依頼一覧取得レコード変数
  TYPE rec_data_type_dtl  IS RECORD 
    (
      -- 納入先(コード)
       location_code          xxpo_requisition_headers.location_code%TYPE
      -- 納入先(名称)
      ,description            xxcmn_item_locations2_v.description%TYPE
      -- 出庫形態
      ,transaction_type_name  xxwsh_oe_transaction_types2_v.transaction_type_name%TYPE
      -- 発注no
      ,po_header_number       xxpo_requisition_headers.po_header_number%TYPE
      -- ステータス
      ,meaning                xxcmn_lookup_values2_v.meaning%TYPE
      -- 取引先(コード)
      ,segment1               xxcmn_vendors2_v.segment1%TYPE
      -- 取引先(名称)
      ,vendor_short_name      xxcmn_vendors2_v.vendor_short_name%TYPE
      -- 納期
      ,promised_date          xxpo_requisition_headers.promised_date%TYPE
      -- 品目(コード)
      ,item_no                xxcmn_item_mst2_v.item_no%TYPE
      -- 品目(名称)
      ,item_desc1             xxcmn_item_mst2_v.item_desc1%TYPE
      -- 発注依頼数量
      ,requested_quantity     xxpo_requisition_lines.requested_quantity%TYPE
      -- 単位
      ,item_um                xxcmn_item_mst2_v.item_um%TYPE
      -- 日付指定
      ,requested_date         xxpo_requisition_lines.requested_date%TYPE
      -- 依頼no/移動no
      ,request_move_no             xxwsh_order_headers_all.request_no%TYPE
      -- 出庫日
      ,schedule_ship_date    xxwsh_order_headers_all.schedule_ship_date%TYPE
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
    iox_xml_data      IN OUT NOCOPY xml_data,
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
      iox_xml_data(i).TAG_VALUE := TO_CHAR(TO_NUMBER(iv_tag_value),gc_num_5);
    ELSIF (ic_tag_value_type = 'B') THEN
      iox_xml_data(i).TAG_VALUE := TO_CHAR(TO_NUMBER(iv_tag_value),gc_num_7);
    ELSE
      iox_xml_data(i).TAG_VALUE := iv_tag_value;
    END IF;
    iox_xml_data(i).TAG_TYPE  := ic_tag_type;
--
  END insert_xml_plsql_table;
--
  /**********************************************************************************
   * Procedure Name   : prc_initialize
   * Description      : 担当者情報抽出(D-1)
   ***********************************************************************************/
  PROCEDURE prc_initialize
    (
      ir_param      IN     rec_param_data   -- 01.入力パラメータ群
     ,ov_errbuf     OUT    VARCHAR2         -- エラー・メッセージ           --# 固定 #
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
--del start 1.1
--    IF ( gv_department_code IS NULL ) THEN
--      lv_err_code := gc_xxpo_00036 ;
--      RAISE get_value_expt ;
--    END IF ;
--del end 1.1
--
    -- ====================================================
    -- 担当者取得
    -- ====================================================
    gv_department_name := SUBSTRB( xxcmn_common_pkg.get_user_name( FND_GLOBAL.USER_ID ), 1, 14 ) ;
--del start 1.1
--    IF ( gv_department_name IS NULL ) THEN
--      lv_err_code := gc_xxpo_00026 ;
--      RAISE get_value_expt ;
--    END IF ;
--del end 1.1
--
  EXCEPTION
    --*** 値取得エラー例外 ***
    WHEN get_value_expt THEN
      -- メッセージセット
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_po
                                            ,lv_err_code    ) ;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB( gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg
                             , 1, 5000 ) ;
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
   * Description      : 明細データ取得(D-2)
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
    SELECT         location_code              AS location_code
                  ,description                AS description
                  ,transaction_type_name      AS transaction_type_name
                  ,po_header_number           AS po_header_number
                  ,meaning                    AS meaning
                  ,segment1                   AS segment1
                  ,vendor_short_name          AS vendor_short_name
                  ,promised_date              AS promised_date
                  ,item_no                    AS item_no
                  ,item_desc1                 AS item_desc1
                  ,requested_quantity         AS requested_quantity
                  ,item_um                    AS item_um
                  ,requested_date             AS requested_date
                  ,request_move_no            AS request_move_no
                  ,schedule_ship_date         AS schedule_ship_date
--
    BULK COLLECT INTO ot_data_rec
--
    FROM
      ------------------------------------------------------------------------
      -- 出荷情報
      ------------------------------------------------------------------------
      (
        SELECT     xrh.location_code            AS location_code            -- 納入先(コード)
                  ,xil2v.description            AS description              -- 納入先(名称)
                  ,xott2v.transaction_type_name AS transaction_type_name    -- 出庫形態
                  ,xrh.po_header_number         AS po_header_number         -- 発注no
                  ,xlv2v.meaning                AS meaning                  -- ステータス
                  ,xv2v.segment1                AS segment1                 -- 取引先(コード)
                  ,xv2v.vendor_short_name       AS vendor_short_name        -- 取引先(名称)
                  ,xrh.promised_date            AS promised_date            -- 納期
                  ,xim2v.item_no                AS item_no                  -- 品目(コード)
                  ,xim2v.item_desc1             AS item_desc1               -- 品目(名称)
                  ,xrl.requested_quantity       AS requested_quantity       -- 発注依頼数量
                  ,xim2v.item_um                AS item_um                  -- 単位
                  ,xrl.requested_date           AS requested_date           -- 日付指定
                  ,xoha.request_no              AS request_move_no          -- 依頼no
                  ,xoha.schedule_ship_date      AS schedule_ship_date       -- 出庫日
--
        FROM       xxpo_requisition_headers       xrh     -- 発注依頼ヘッダ(アドオン)
                  ,xxpo_requisition_lines         xrl     -- 発注依頼明細(アドオン)
                  ,xxwsh_order_headers_all        xoha    -- 受注ヘッダアドオン
                  ,xxwsh_order_lines_all          xola    -- 受注明細アドオン
                  ,xxcmn_vendors2_v               xv2v    -- 仕入先情報view2
                  ,xxcmn_item_locations2_v        xil2v   -- OPM保管場所情報VIEW2
                  ,xxcmn_item_mst2_v              xim2v   -- OPM品目情報VIEW2
                  ,xxwsh_oe_transaction_types2_v  xott2v  -- 受注タイプ情報VIEW2
                  ,xxcmn_lookup_values2_v         xlv2v   -- クイックコード情報VIEW2(伝票区分)
--
        WHERE
                  -------------------------------------------------------------------------------
                  -- 発注依頼ヘッダアドオン
                  -------------------------------------------------------------------------------
                  (
                    xrh.status                 =   gc_order_status_req_making    -- 依頼作成済
                  OR
                    xrh.status                 =   gc_order_status_ordered       -- 発注済
                  )
        AND       (
                    ir_param.iv_delivery_dest  IS NULL
                  OR
                    xrh.location_code          =   ir_param.iv_delivery_dest
                  )
        AND       (
                    ir_param.iv_delivery_date  IS NULL
                  OR
                    xrh.promised_date          =   ir_param.iv_delivery_date
                  )
                  -------------------------------------------------------------------------------
                  -- 発注依頼明細アドオン
                  -------------------------------------------------------------------------------
        AND       xrh.requisition_header_id    =   xrl.requisition_header_id
        AND       xrl.cancelled_flg            <>  gc_cancelled_flg
                  -------------------------------------------------------------------------------
                  -- 受注明細アドオン
                  -------------------------------------------------------------------------------
        AND       xrh.po_header_number         =   xola.po_number
        AND       xrl.item_code                =   xola.shipping_item_code
        AND       xola.delete_flag             <>  gc_delete_flag
                  -------------------------------------------------------------------------------
                  -- 受注ヘッダアドオン
                  -------------------------------------------------------------------------------
        AND       xola.order_header_id         =   xoha.order_header_id
        AND       xoha.latest_external_flag    =   gc_new_flg
        AND       xoha.req_status              <>  gc_ship_status_delete
        AND       xoha.schedule_ship_date     >=  ir_param.iv_delivery_day_from
        AND       (
                    ir_param.iv_delivery_day_to       IS NULL
                  OR
                    xoha.schedule_ship_date   <= ir_param.iv_delivery_day_to
                  )
                  -------------------------------------------------------------------------------
                  -- 受注タイプ
                  -------------------------------------------------------------------------------
        AND       xoha.order_type_id           =   xott2v.transaction_type_id
        AND       xott2v.shipping_shikyu_class =  gc_ship_pro_kbn_i     -- 出荷依頼
        AND       xott2v.transaction_type_id
                    = NVL(ir_param.iv_delivery_form, xott2v.transaction_type_id)
                  -------------------------------------------------------------------------------
                  -- OPM保管場所情報VIEW
                  -------------------------------------------------------------------------------
        AND       xrh.location_code            =   xil2v.segment1
                  -------------------------------------------------------------------------------
                  -- 仕入先情報VIEW
                  -------------------------------------------------------------------------------
        AND       xrh.vendor_id                =  xv2v.vendor_id
        AND       xv2v.start_date_active      <= ir_param.iv_delivery_day_from
        AND       xv2v.end_date_active        >= ir_param.iv_delivery_day_from
                  -------------------------------------------------------------------------------
                  -- OPM品目情報VIEW
                  -------------------------------------------------------------------------------
        AND       xrl.item_id                  =  xim2v.item_id
        AND       xim2v.start_date_active     <= ir_param.iv_delivery_day_from
        AND       xim2v.end_date_active       >= ir_param.iv_delivery_day_from
                  -------------------------------------------------------------------------------
                  -- クイックコード（発注依頼ステータス）
                  -------------------------------------------------------------------------------
        AND       xrh.status                   =   xlv2v.lookup_code
        AND       xlv2v.lookup_type            =   gc_lookup_cd_conreq
--
        UNION ALL
--
        ------------------------------------------------------------------------
        -- 移動情報
        ------------------------------------------------------------------------
        SELECT     xrh.location_code            AS location_code            -- 納入先(コード)
                  ,xil2v.description            AS description              -- 納入先(名称)
                  ,NULL                         AS transaction_type_name    -- 出庫形態
                  ,xrh.po_header_number         AS po_header_number         -- 発注no
                  ,xlv2v.meaning                AS meaning                  -- ステータス
                  ,xv2v.segment1                AS segment1                 -- 取引先(コード)
                  ,xv2v.vendor_short_name       AS vendor_short_name        -- 取引先(名称)
                  ,xrh.promised_date            AS promised_date            -- 納期
                  ,xim2v.item_no                AS item_no                  -- 品目(コード)
                  ,xim2v.item_desc1             AS item_desc1               -- 品目(名称)
                  ,xrl.requested_quantity       AS requested_quantity       -- 発注依頼数量
                  ,xim2v.item_um                AS item_um                  -- 単位
                  ,xrl.requested_date           AS requested_date           -- 日付指定
                  ,xmrih.mov_num                AS request_move_no          -- 移動no
                  ,xmrih.schedule_ship_date     AS schedule_ship_date       -- 出庫日
--
        FROM       xxpo_requisition_headers       xrh     -- 発注依頼ヘッダ(アドオン)
                  ,xxpo_requisition_lines         xrl     -- 発注依頼明細(アドオン)
                  ,xxinv_mov_req_instr_headers    xmrih   -- 移動依頼/指示ヘッダ(アドオン)
                  ,xxinv_mov_req_instr_lines      xmril   -- 移動依頼/指示明細(アドオン)
                  ,xxcmn_vendors2_v               xv2v    -- 仕入先情報view2
                  ,xxcmn_item_locations2_v        xil2v   -- opm保管場所情報view2
                  ,xxcmn_item_mst2_v              xim2v   -- opm品目情報view2
                  ,xxcmn_lookup_values2_v         xlv2v   -- クイックコード情報VIEW2(伝票区分)
--
        WHERE
                  -------------------------------------------------------------------------------
                  -- 発注依頼ヘッダアドオン
                  -------------------------------------------------------------------------------
                  (
                    xrh.status                 =   gc_order_status_req_making    -- 依頼作成済
                  OR
                    xrh.status                 =   gc_order_status_ordered       -- 発注済
                  )
        AND       (
                    ir_param.iv_delivery_dest  IS NULL
                  OR
                    xrh.location_code          =   ir_param.iv_delivery_dest
                  )
        AND       (
                    ir_param.iv_delivery_date  IS NULL
                  OR
                    xrh.promised_date          =   ir_param.iv_delivery_date
                  )
                  -------------------------------------------------------------------------------
                  -- 発注依頼明細アドオン
                  -------------------------------------------------------------------------------
        AND       xrh.requisition_header_id    =   xrl.requisition_header_id
        AND       xrl.cancelled_flg            <>  gc_cancelled_flg
                  -------------------------------------------------------------------------------
                  -- 移動依頼/指示明細アドオン
                  -------------------------------------------------------------------------------
        AND       xrh.po_header_number         =   xmril.po_num
        AND       xrl.item_code                =   xmril.item_code
        AND       xmril.delete_flg             <>  gc_delete_mov_flag
                  -------------------------------------------------------------------------------
                  -- 移動依頼/指示ヘッダアドオン
                  -------------------------------------------------------------------------------
        AND       xmril.mov_hdr_id             =  xmrih.mov_hdr_id
        AND       xmrih.status                 <>  gc_mov_status_delete
        AND       xmrih.schedule_ship_date    >=  ir_param.iv_delivery_day_from
        AND       (
                    ir_param.iv_delivery_day_to        IS NULL
                  OR
                    xmrih.schedule_ship_date  <=  ir_param.iv_delivery_day_to
                  )
                  -------------------------------------------------------------------------------
                  -- OPM保管場所情報VIEW
                  -------------------------------------------------------------------------------
        AND       xrh.location_code            =   xil2v.segment1
                  -------------------------------------------------------------------------------
                  -- 仕入先情報VIEW
                  -------------------------------------------------------------------------------
        AND       xrh.vendor_id                =  xv2v.vendor_id
        AND       xv2v.start_date_active      <= ir_param.iv_delivery_day_from
        AND       xv2v.end_date_active        >= ir_param.iv_delivery_day_from
                  -------------------------------------------------------------------------------
                  -- OPM品目情報VIEW
                  -------------------------------------------------------------------------------
        AND       xrl.item_id                  =  xim2v.item_id
        AND       xim2v.start_date_active     <= ir_param.iv_delivery_day_from
        AND       xim2v.end_date_active       >= ir_param.iv_delivery_day_from
                  -------------------------------------------------------------------------------
                  -- クイックコード（発注依頼ステータス）
                  -------------------------------------------------------------------------------
        AND       xrh.status                   =   xlv2v.lookup_code
        AND       xlv2v.lookup_type            =   gc_lookup_cd_conreq
      )
      ------------------------------------------------------------------------
      ORDER BY   transaction_type_name          -- 出庫形態
                ,location_code                  -- 納入先(コード)
                ,promised_date                  -- 納期
                ,po_header_number               -- 発注no
                ,item_no                        -- 品目(コード)
                ,schedule_ship_date             -- 出庫日
                ,request_move_no                -- 依頼no/移動no
                ;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf
                          , 1, 5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM||
                    ' A:'||ir_param.iv_delivery_day_to||
                    ' B:'||ir_param.iv_delivery_day_from||
                    ' C:'||ir_param.iv_delivery_day_to;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_get_report_data ;
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : ＸＭＬデータ作成(D-3)
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data
    (
      iox_xml_data      IN OUT  NOCOPY XML_DATA 
     ,ir_param          IN      rec_param_data  -- 01.レコード  ：パラメータ
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
--
    -- 入庫倉庫取得用
    lv_location_name        xxcmn_item_locations2_v.description%TYPE ; -- 入庫倉庫
--
    -- 納入先(ｺｰﾄﾞ)
    lv_location_code          xxpo_requisition_headers.location_code%TYPE;
    -- 出庫形態
    lv_transaction_type_name  xxwsh_oe_transaction_types2_v.transaction_type_name%TYPE;
    -- 発注no
    lv_po_header_number       xxpo_requisition_headers.po_header_number%TYPE;
    -- ステータス
    lv_meaning                xxcmn_lookup_values2_v.meaning%TYPE;
    -- 取引先(ｺｰﾄﾞ)
    lv_segment1               xxcmn_vendors2_v.segment1%TYPE;
    -- 取引先(名称)
    lv_vendor_short_name      xxcmn_vendors2_v.vendor_short_name%TYPE;
    -- 納期
    lv_promised_date          xxpo_requisition_headers.promised_date%TYPE;
    -- 品目(ｺｰﾄﾞ)
    lv_item_no                xxcmn_item_mst2_v.item_no%TYPE;
--
    -- *** ローカル・例外処理 ***
    no_data_expt                 EXCEPTION ;             -- 取得レコードなし
--
  BEGIN
--
    -- =====================================================
    -- 明細情報取得(D-2)
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
    lv_location_code          :=  NULL;
    lv_transaction_type_name  :=  NULL;
    lv_po_header_number       :=  NULL;
    lv_meaning                :=  NULL;
    lv_segment1               :=  NULL;
    lv_vendor_short_name      :=  NULL;
    lv_promised_date          :=  NULL;
    lv_item_no                :=  NULL;
--
    -- -----------------------------------------------------
    -- データＧ開始タグ出力
    -- -----------------------------------------------------
    insert_xml_plsql_table( iox_xml_data
                           ,'root'
                           ,NULL
                           ,gc_tag_type_tag
                           ,gc_tag_value_type_char);
    insert_xml_plsql_table( iox_xml_data
                           ,'data_info'
                           ,NULL
                           ,gc_tag_type_tag
                           ,gc_tag_value_type_char);
    -- -----------------------------------------------------
    -- 伝票Ｇ開始タグ出力
    -- -----------------------------------------------------
    insert_xml_plsql_table( iox_xml_data
                           ,'lg_denpyo_info'
                           ,NULL
                           ,gc_tag_type_tag
                           ,gc_tag_value_type_char);
--
    -- =====================================================
    -- 項目データ抽出・出力処理
    -- =====================================================
    <<main_data_loop>>
    FOR i IN 1..gt_main_data.COUNT LOOP
--
      -- ブレイクキーのチェック
      IF  ( lv_location_code          IS NULL ) 
      AND ( lv_transaction_type_name  IS NULL ) 
      AND ( lv_po_header_number       IS NULL ) 
      AND ( lv_meaning                IS NULL ) 
      AND ( lv_segment1               IS NULL ) 
      AND ( lv_vendor_short_name      IS NULL ) 
      AND ( lv_promised_date          IS NULL ) 
      AND ( lv_item_no                IS NULL ) THEN
--
        -- 変数を更新する。
        lv_location_code          :=  gt_main_data(i).location_code;
        lv_transaction_type_name  :=  gt_main_data(i).transaction_type_name;
        lv_po_header_number       :=  gt_main_data(i).po_header_number;
        lv_meaning                :=  gt_main_data(i).meaning;
        lv_segment1               :=  gt_main_data(i).segment1;
        lv_vendor_short_name      :=  gt_main_data(i).vendor_short_name;
        lv_promised_date          :=  gt_main_data(i).promised_date;
        lv_item_no                :=  gt_main_data(i).item_no;
--
        -- 初回出力は全てのタグを出力する。
        -- -----------------------------------------------------
        -- 明細Ｇ開始タグ出力
        -- -----------------------------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'g_denpyo'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char);
--
        -- -----------------------------------------------------
        -- 明細Ｇデータタグ出力
        -- -----------------------------------------------------
        -- 帳票ID
        insert_xml_plsql_table( iox_xml_data
                               ,'tyohyo_id'
                               ,gc_report_id
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- 出力日付
        insert_xml_plsql_table( iox_xml_data
                               ,'shuturyoku_hiduke'
                               ,TO_CHAR(gd_exec_date, gc_char_dt_format)
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- 担当（部署）
        insert_xml_plsql_table( iox_xml_data
                               ,'tantou_busho'
                               ,gv_department_code
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- 担当（氏名）
        insert_xml_plsql_table( iox_xml_data
                               ,'tantou_name'
                               ,gv_department_name
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- 出庫日From
        insert_xml_plsql_table( iox_xml_data
                               ,'syukkobi_from'
                               ,TO_CHAR(ir_param.iv_delivery_day_from, gc_date_fmt_ymd_ja)
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- 出庫日To
        insert_xml_plsql_table( iox_xml_data
                               ,'syukkobi_to'
                               ,TO_CHAR(ir_param.iv_delivery_day_to, gc_date_fmt_ymd_ja)
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char);
        -- 納入先(コード)
        insert_xml_plsql_table( iox_xml_data
                               ,'nounyu_saki_code'
                               ,gt_main_data(i).location_code
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- 納入先(名称)
        insert_xml_plsql_table( iox_xml_data
                               ,'nounyu_saki_name'
                               ,gt_main_data(i).description
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- 出庫形態
        insert_xml_plsql_table( iox_xml_data
                               ,'syukko_keitai'
                               ,gt_main_data(i).transaction_type_name
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
--
        ------------------------------
        -- 明細ＬＧ開始タグ
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'lg_shukko'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
        ------------------------------
        -- 明細(親)Ｇ開始タグ
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'g_shukko_header'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
        -- -----------------------------------------------------
        -- 明細(親)Ｇデータタグ出力
        -- -----------------------------------------------------
        -- 発注no
        insert_xml_plsql_table( iox_xml_data
                               ,'hattyu_no'
                               ,gt_main_data(i).po_header_number
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- ステータス
        insert_xml_plsql_table( iox_xml_data
                               ,'status'
                               ,gt_main_data(i).meaning
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- 取引先(コード)
        insert_xml_plsql_table( iox_xml_data
                               ,'torihikisaki_code'
                               ,gt_main_data(i).segment1
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- 取引先(名称)
        insert_xml_plsql_table( iox_xml_data
                               ,'torihikisaki_name'
                               ,gt_main_data(i).vendor_short_name
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- 納期
        insert_xml_plsql_table( iox_xml_data
                               ,'nouki'
                               ,TO_CHAR(gt_main_data(i).promised_date, gc_char_d_format)
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
--
        ------------------------------
        -- 明細(子)Ｇ開始タグ
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'g_shukko_detail'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
        -- 品目(コード)
        insert_xml_plsql_table( iox_xml_data
                               ,'hinmoku_code'
                               ,gt_main_data(i).item_no
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- 品目(名称)
        insert_xml_plsql_table( iox_xml_data
                               ,'hinmoku_name'
                               ,gt_main_data(i).item_desc1
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- 発注依頼数量
        insert_xml_plsql_table( iox_xml_data
                               ,'hattyuuirai_suryo'
                               ,gt_main_data(i).requested_quantity
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- 単位
        insert_xml_plsql_table( iox_xml_data
                               ,'unit'
                               ,gt_main_data(i).item_um
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- 日付指定
        insert_xml_plsql_table( iox_xml_data
                               ,'hiduke_shitei'
                               ,TO_CHAR(gt_main_data(i).requested_date, gc_char_d_format)
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
--
        ------------------------------
        -- 明細(孫)Ｇ開始タグ
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'g_shukko_detail2'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
        -- 依頼NO/移動NO
        insert_xml_plsql_table( iox_xml_data
                               ,'irai_idou_no'
                               ,gt_main_data(i).request_move_no
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- 出庫日
        insert_xml_plsql_table( iox_xml_data
                               ,'syukkobi'
                               ,TO_CHAR(gt_main_data(i).schedule_ship_date, gc_char_d_format)
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
--
        ------------------------------
        -- 明細(孫)Ｇ終了タグ
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'/g_shukko_detail2'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
      -- ヘッダー部の改ページ条件が変更になったら改ページを行う。
      ELSIF ( lv_location_code          <>  gt_main_data(i).location_code         )
-- mod start ver1.3
--        OR  ( lv_transaction_type_name  <>  gt_main_data(i).transaction_type_name ) THEN
        OR  ( lv_transaction_type_name  <>  gt_main_data(i).transaction_type_name )
        OR  ( lv_transaction_type_name IS NULL  AND  gt_main_data(i).transaction_type_name IS NOT NULL)
        OR  ( lv_transaction_type_name IS NOT NULL  AND  gt_main_data(i).transaction_type_name IS NULL) THEN
-- mod end ver1.3
--
        -- 変数を更新する。
        lv_location_code          :=  gt_main_data(i).location_code;
        lv_transaction_type_name  :=  gt_main_data(i).transaction_type_name;
        lv_po_header_number       :=  gt_main_data(i).po_header_number;
        lv_meaning                :=  gt_main_data(i).meaning;
        lv_segment1               :=  gt_main_data(i).segment1;
        lv_vendor_short_name      :=  gt_main_data(i).vendor_short_name;
        lv_promised_date          :=  gt_main_data(i).promised_date;
        lv_item_no                :=  gt_main_data(i).item_no;
--
        ------------------------------
        -- 明細(子)Ｇ終了タグ
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'/g_shukko_detail'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
--
        ------------------------------
        -- 明細(親)Ｇ終了タグ
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'/g_shukko_header'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
--
        ------------------------------
        -- 明細ＬＧ終了タグ
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'/lg_shukko'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
--
        -- -----------------------------------------------------
        -- 明細Ｇ終了タグ出力
        -- -----------------------------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'/g_denpyo'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
--
        -- -----------------------------------------------------
        -- 明細Ｇ開始タグ出力
        -- -----------------------------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'g_denpyo'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char);
--
        -- -----------------------------------------------------
        -- 明細Ｇデータタグ出力
        -- -----------------------------------------------------
        -- 帳票ID
        insert_xml_plsql_table( iox_xml_data
                               ,'tyohyo_id'
                               ,gc_report_id
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- 出力日付
        insert_xml_plsql_table( iox_xml_data
                               ,'shuturyoku_hiduke'
                               ,TO_CHAR(gd_exec_date, gc_char_dt_format)
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- 担当（部署）
        insert_xml_plsql_table( iox_xml_data
                               ,'tantou_busho'
                               ,gv_department_code
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- 担当（氏名）
        insert_xml_plsql_table( iox_xml_data
                               ,'tantou_name'
                               ,gv_department_name
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- 出庫日From
        insert_xml_plsql_table( iox_xml_data
                               ,'syukkobi_from'
                               ,TO_CHAR(ir_param.iv_delivery_day_from, gc_date_fmt_ymd_ja)
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- 出庫日To
        insert_xml_plsql_table( iox_xml_data
                               ,'syukkobi_to'
                               ,TO_CHAR(ir_param.iv_delivery_day_to, gc_date_fmt_ymd_ja)
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char);
        -- 納入先(コード)
        insert_xml_plsql_table( iox_xml_data
                               ,'nounyu_saki_code'
                               ,gt_main_data(i).location_code
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- 納入先(名称)
        insert_xml_plsql_table( iox_xml_data
                               ,'nounyu_saki_name'
                               ,gt_main_data(i).description
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- 出庫形態
        insert_xml_plsql_table( iox_xml_data
                               ,'syukko_keitai'
                               ,gt_main_data(i).transaction_type_name
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
--
        ------------------------------
        -- 明細ＬＧ開始タグ
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'lg_shukko'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
        ------------------------------
        -- 明細(親)Ｇ開始タグ
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'g_shukko_header'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
        -- -----------------------------------------------------
        -- 明細(親)Ｇデータタグ出力
        -- -----------------------------------------------------
        -- 発注no
        insert_xml_plsql_table( iox_xml_data
                               ,'hattyu_no'
                               ,gt_main_data(i).po_header_number
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- ステータス
        insert_xml_plsql_table( iox_xml_data
                               ,'status'
                               ,gt_main_data(i).meaning
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- 取引先(コード)
        insert_xml_plsql_table( iox_xml_data
                               ,'torihikisaki_code'
                               ,gt_main_data(i).segment1
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- 取引先(名称)
        insert_xml_plsql_table( iox_xml_data
                               ,'torihikisaki_name'
                               ,gt_main_data(i).vendor_short_name
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- 納期
        insert_xml_plsql_table( iox_xml_data
                               ,'nouki'
                               ,TO_CHAR(gt_main_data(i).promised_date, gc_char_d_format)
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
--
        ------------------------------
        -- 明細(子)Ｇ開始タグ
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'g_shukko_detail'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
        -- 品目(コード)
        insert_xml_plsql_table( iox_xml_data
                               ,'hinmoku_code'
                               ,gt_main_data(i).item_no
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- 品目(名称)
        insert_xml_plsql_table( iox_xml_data
                               ,'hinmoku_name'
                               ,gt_main_data(i).item_desc1
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- 発注依頼数量
        insert_xml_plsql_table( iox_xml_data
                               ,'hattyuuirai_suryo'
                               ,gt_main_data(i).requested_quantity
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- 単位
        insert_xml_plsql_table( iox_xml_data
                               ,'unit'
                               ,gt_main_data(i).item_um
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- 日付指定
        insert_xml_plsql_table( iox_xml_data
                               ,'hiduke_shitei'
                               ,TO_CHAR(gt_main_data(i).requested_date, gc_char_d_format)
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
--
        ------------------------------
        -- 明細(孫)Ｇ開始タグ
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'g_shukko_detail2'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
        -- 依頼NO/移動NO
        insert_xml_plsql_table( iox_xml_data
                               ,'irai_idou_no'
                               ,gt_main_data(i).request_move_no
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- 出庫日(依頼no)
        insert_xml_plsql_table( iox_xml_data
                               ,'syukkobi'
                               ,TO_CHAR(gt_main_data(i).schedule_ship_date, gc_char_d_format)
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
--
        ------------------------------
        -- 明細(孫)Ｇ終了タグ
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'/g_shukko_detail2'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
      -- 親のブレイクキーいずれかが変更になった場合、親と子と孫を出力する。
      ELSIF ( lv_location_code          =   gt_main_data(i).location_code         )
-- mod start ver1.3
--        AND ( lv_transaction_type_name  =   gt_main_data(i).transaction_type_name )
        AND (( lv_transaction_type_name  =   gt_main_data(i).transaction_type_name )
          OR (lv_transaction_type_name IS NULL AND gt_main_data(i).transaction_type_name IS NULL))
-- mod end ver1.3
        AND ( lv_po_header_number       <>  gt_main_data(i).po_header_number      )
        OR  ( lv_meaning                <>  gt_main_data(i).meaning               )
        OR  ( lv_segment1               <>  gt_main_data(i).segment1              )
        OR  ( lv_vendor_short_name      <>  gt_main_data(i).vendor_short_name     )
        OR  ( lv_promised_date          <>  gt_main_data(i).promised_date         ) THEN
--
        -- 変数を更新する。
        lv_po_header_number     :=  gt_main_data(i).po_header_number;
        lv_meaning              :=  gt_main_data(i).meaning;
        lv_segment1             :=  gt_main_data(i).segment1;
        lv_vendor_short_name    :=  gt_main_data(i).vendor_short_name;
        lv_promised_date        :=  gt_main_data(i).promised_date;
        lv_item_no              :=  gt_main_data(i).item_no;
--
        ------------------------------
        -- 明細(子)Ｇ終了タグ
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'/g_shukko_detail'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
--
        ------------------------------
        -- 明細(親)Ｇ終了タグ
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'/g_shukko_header'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
--
        ------------------------------
        -- 明細(親)Ｇ開始タグ
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'g_shukko_header'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
        -- -----------------------------------------------------
        -- 明細(親)Ｇデータタグ出力
        -- -----------------------------------------------------
        -- 発注no
        insert_xml_plsql_table( iox_xml_data
                               ,'hattyu_no'
                               ,gt_main_data(i).po_header_number
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- ステータス
        insert_xml_plsql_table( iox_xml_data
                               ,'status'
                               ,gt_main_data(i).meaning
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- 取引先(コード)
        insert_xml_plsql_table( iox_xml_data
                               ,'torihikisaki_code'
                               ,gt_main_data(i).segment1
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- 取引先(名称)
        insert_xml_plsql_table( iox_xml_data
                               ,'torihikisaki_name'
                               ,gt_main_data(i).vendor_short_name
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- 納期
        insert_xml_plsql_table( iox_xml_data
                               ,'nouki'
                               ,TO_CHAR(gt_main_data(i).promised_date, gc_char_d_format)
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
--
        ------------------------------
        -- 明細(子)Ｇ開始タグ
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'g_shukko_detail'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
        -- 品目(コード)
        insert_xml_plsql_table( iox_xml_data
                               ,'hinmoku_code'
                               ,gt_main_data(i).item_no
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- 品目(名称)
        insert_xml_plsql_table( iox_xml_data
                               ,'hinmoku_name'
                               ,gt_main_data(i).item_desc1
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- 発注依頼数量
        insert_xml_plsql_table( iox_xml_data
                               ,'hattyuuirai_suryo'
                               ,gt_main_data(i).requested_quantity
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- 単位
        insert_xml_plsql_table( iox_xml_data
                               ,'unit'
                               ,gt_main_data(i).item_um
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- 日付指定
        insert_xml_plsql_table( iox_xml_data
                               ,'hiduke_shitei'
                               ,TO_CHAR(gt_main_data(i).requested_date, gc_char_d_format)
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
--
        ------------------------------
        -- 明細(孫)Ｇ開始タグ
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'g_shukko_detail2'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
        -- 依頼NO/移動NO
        insert_xml_plsql_table( iox_xml_data
                               ,'irai_idou_no'
                               ,gt_main_data(i).request_move_no
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- 出庫日(依頼no)
        insert_xml_plsql_table( iox_xml_data
                               ,'syukkobi'
                               ,TO_CHAR(gt_main_data(i).schedule_ship_date, gc_char_d_format)
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
--
        ------------------------------
        -- 明細(孫)Ｇ終了タグ
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'/g_shukko_detail2'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
      -- 子のブレイクキーが変更になった場合、子と孫を出力する。
      ELSIF ( lv_location_code          =   gt_main_data(i).location_code         )
-- mod start ver1.3
--        AND ( lv_transaction_type_name  =   gt_main_data(i).transaction_type_name )
        AND (( lv_transaction_type_name  =   gt_main_data(i).transaction_type_name )
          OR (lv_transaction_type_name IS NULL AND gt_main_data(i).transaction_type_name IS NULL))
-- mod end ver1.3
        AND ( lv_po_header_number       =   gt_main_data(i).po_header_number      )
        AND ( lv_meaning                =   gt_main_data(i).meaning               )
        AND ( lv_segment1               =   gt_main_data(i).segment1              )
        AND ( lv_vendor_short_name      =   gt_main_data(i).vendor_short_name     )
        AND ( lv_promised_date          =   gt_main_data(i).promised_date         )
        AND ( lv_item_no                <>  gt_main_data(i).item_no               ) THEN
--
        -- 変数を更新する。
        lv_item_no              :=  gt_main_data(i).item_no;
--
        ------------------------------
        -- 明細(子)Ｇ終了タグ
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'/g_shukko_detail'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
--
        ------------------------------
        -- 明細(子)Ｇ開始タグ
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'g_shukko_detail'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
        -- 品目(コード)
        insert_xml_plsql_table( iox_xml_data
                               ,'hinmoku_code'
                               ,gt_main_data(i).item_no
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- 品目(名称)
        insert_xml_plsql_table( iox_xml_data
                               ,'hinmoku_name'
                               ,gt_main_data(i).item_desc1
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- 発注依頼数量
        insert_xml_plsql_table( iox_xml_data
                               ,'hattyuuirai_suryo'
                               ,gt_main_data(i).requested_quantity
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- 単位
        insert_xml_plsql_table( iox_xml_data
                               ,'unit'
                               ,gt_main_data(i).item_um
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- 日付指定
        insert_xml_plsql_table( iox_xml_data
                               ,'hiduke_shitei'
                               ,TO_CHAR(gt_main_data(i).requested_date, gc_char_d_format)
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
--
        ------------------------------
        -- 明細(孫)Ｇ開始タグ
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'g_shukko_detail2'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
        -- 依頼NO/移動NO
        insert_xml_plsql_table( iox_xml_data
                               ,'irai_idou_no'
                               ,gt_main_data(i).request_move_no
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- 出庫日(依頼no)
        insert_xml_plsql_table( iox_xml_data
                               ,'syukkobi'
                               ,TO_CHAR(gt_main_data(i).schedule_ship_date, gc_char_d_format)
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
--
        ------------------------------
        -- 明細(孫)Ｇ終了タグ
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'/g_shukko_detail2'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
      -- 何もブレイクキーに変更が無かった場合、孫を出力する。
      ELSIF ( lv_location_code          =   gt_main_data(i).location_code         )
-- mod start ver1.3
--        AND ( lv_transaction_type_name  =   gt_main_data(i).transaction_type_name )
        AND (( lv_transaction_type_name  =   gt_main_data(i).transaction_type_name )
          OR (lv_transaction_type_name IS NULL AND gt_main_data(i).transaction_type_name IS NULL))
-- mod end ver1.3
        AND ( lv_po_header_number       =   gt_main_data(i).po_header_number      )
        AND ( lv_meaning                =   gt_main_data(i).meaning               )
        AND ( lv_segment1               =   gt_main_data(i).segment1              )
        AND ( lv_vendor_short_name      =   gt_main_data(i).vendor_short_name     )
        AND ( lv_promised_date          =   gt_main_data(i).promised_date         )
        AND ( lv_item_no                =   gt_main_data(i).item_no               ) THEN
--
        ------------------------------
        -- 明細(孫)Ｇ開始タグ
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'g_shukko_detail2'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
        -- 依頼NO/移動NO
        insert_xml_plsql_table( iox_xml_data
                               ,'irai_idou_no'
                               ,gt_main_data(i).request_move_no
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- 出庫日(依頼no)
        insert_xml_plsql_table( iox_xml_data
                               ,'syukkobi'
                               ,TO_CHAR(gt_main_data(i).schedule_ship_date, gc_char_d_format)
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
--
        ------------------------------
        -- 明細(孫)Ｇ終了タグ
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'/g_shukko_detail2'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
--
      END IF ;
--
    END LOOP main_data_loop ;
--
    ------------------------------
    -- 明細(子)Ｇ終了タグ
    ------------------------------
    insert_xml_plsql_table( iox_xml_data
                           ,'/g_shukko_detail'
                           ,NULL
                           ,gc_tag_type_tag
                           ,gc_tag_value_type_char) ;
--
--
    ------------------------------
    -- 明細(親)Ｇ終了タグ
    ------------------------------
    insert_xml_plsql_table( iox_xml_data
                           ,'/g_shukko_header'
                           ,NULL
                           ,gc_tag_type_tag
                           ,gc_tag_value_type_char) ;
--
--
    ------------------------------
    -- 明細ＬＧ終了タグ
    ------------------------------
    insert_xml_plsql_table( iox_xml_data
                           ,'/lg_shukko'
                           ,NULL
                           ,gc_tag_type_tag
                           ,gc_tag_value_type_char) ;
--
--
    -- -----------------------------------------------------
    -- 明細Ｇ終了タグ出力
    -- -----------------------------------------------------
    insert_xml_plsql_table( iox_xml_data
                           ,'/g_denpyo'
                           ,NULL
                           ,gc_tag_type_tag
                           ,gc_tag_value_type_char) ;
--
    -- =====================================================
    -- 終了処理
    -- =====================================================
    ------------------------------
    -- 伝票Ｇ終了タグ
    ------------------------------
    insert_xml_plsql_table( iox_xml_data
                           ,'/lg_denpyo_info'
                           ,NULL
                           ,gc_tag_type_tag
                           ,gc_tag_value_type_char) ;
    ------------------------------
    -- データＧ終了タグ
    ------------------------------
    insert_xml_plsql_table( iox_xml_data
                           ,'/data_info'
                           ,NULL
                           ,gc_tag_type_tag
                           ,gc_tag_value_type_char) ;
    insert_xml_plsql_table( iox_xml_data
                           ,'/root'
                           ,NULL
                           ,gc_tag_type_tag
                           ,gc_tag_value_type_char) ;
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
      ov_errbuf  := lv_errbuf;
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
   * Procedure Name   : prc_check_param_data
   * Description      : パラメータチェック処理
   ***********************************************************************************/
  PROCEDURE prc_check_param_data
    (
       iv_delivery_date       IN  VARCHAR2      -- 03 : 納期
      ,iv_delivery_day_from   IN  VARCHAR2      -- 04 : 出庫日From
      ,iv_delivery_day_to     IN  VARCHAR2      -- 05 : 出庫日To
      ,ov_delivery_date       OUT DATE          -- 03 : 納期
      ,ov_delivery_day_from   OUT DATE          -- 04 : 出庫日From
      ,ov_delivery_day_to     OUT DATE          -- 05 : 出庫日To
      ,ov_errbuf              OUT VARCHAR2      -- エラー・メッセージ           --# 固定 #
      ,ov_retcode             OUT VARCHAR2      -- リターン・コード             --# 固定 #
      ,ov_errmsg              OUT VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name           CONSTANT  VARCHAR2(100) := 'prc_check_param_data'; -- プログラム名
--
    gc_application_cmn    CONSTANT  VARCHAR2(5)   := 'XXCMN' ;      -- アプリケーション（XXCMN）
    gc_application_wip    CONSTANT  VARCHAR2(5)   := 'XXWIP' ;      -- アプリケーション（XXWIP）
    gv_tkn_item           CONSTANT  VARCHAR2(100) := 'ITEM';        -- トークン：ITEM
    gv_tkn_value          CONSTANT  VARCHAR2(100) := 'VALUE';       -- トークン：VALUE
    gv_delivery_day_from  CONSTANT  VARCHAR2(20)  := '出庫日From';  -- 生産予定日（FROM）
    gv_delivery_day_to    CONSTANT  VARCHAR2(20)  := '出庫日To';    -- 生産予定日（TO）
    gv_tkn_param1         CONSTANT  VARCHAR2(100) := 'PARAM1';      -- トークン：PARAM1
    gv_tkn_param2         CONSTANT  VARCHAR2(100) := 'PARAM2';      -- トークン：PARAM2
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
    -- 共通関数戻り値：数値型
    ln_ret_num              NUMBER ;
--
    -- *** ローカル・例外処理 ***
    parameter_check_expt      EXCEPTION ;     -- パラメータチェック例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 日付変換
    IF ( iv_delivery_date IS NOT NULL ) THEN
      ov_delivery_date := FND_DATE.STRING_TO_DATE(SUBSTR(iv_delivery_date, 1, 10)
                                                , gc_char_d_format);
    END IF;
--
    IF ( iv_delivery_day_from IS NOT NULL ) THEN
      ov_delivery_day_from := FND_DATE.STRING_TO_DATE(SUBSTR(iv_delivery_day_from, 1, 10)
                                                    , gc_char_d_format);
    END IF;
--
    IF ( iv_delivery_day_to IS NOT NULL ) THEN
      ov_delivery_day_to := FND_DATE.STRING_TO_DATE(SUBSTR(iv_delivery_day_to, 1, 10)
                                                  , gc_char_d_format);
    END IF;
--
    -- ====================================================
    -- 妥当性チェック
    -- ====================================================
    IF ( iv_delivery_day_to IS NOT NULL ) THEN
      IF (ov_delivery_day_from > ov_delivery_day_to) THEN
        -- メッセージセット
        lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wip
                                              ,gc_xxwip_10016
                                              ,gv_tkn_param1
                                              ,TO_CHAR(ov_delivery_day_from, gc_char_d_format)
                                              ,gv_tkn_param2
                                              ,TO_CHAR(ov_delivery_day_to, gc_char_d_format)) ;
        RAISE parameter_check_expt ;
      END IF;
    END IF;
--
  EXCEPTION
    --*** パラメータチェック例外 ***
    WHEN parameter_check_expt THEN
--
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
  END prc_check_param_data ;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain
    (
       iv_delivery_dest     IN    VARCHAR2          -- 01 : 納入先
      ,iv_delivery_form     IN    VARCHAR2          -- 02 : 出庫形態
      ,iv_delivery_date     IN    VARCHAR2          -- 03 : 納期
      ,iv_delivery_day_from IN    VARCHAR2          -- 04 : 出庫日From
      ,iv_delivery_day_to   IN    VARCHAR2          -- 05 : 出庫日To
      ,ov_errbuf            OUT   VARCHAR2          -- エラー・メッセージ           --# 固定 #
      ,ov_retcode           OUT   VARCHAR2          -- リターン・コード             --# 固定 #
      ,ov_errmsg            OUT   VARCHAR2          -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- 日付変換
    lv_delivery_date      VARCHAR2(10);                 -- 納期
    lv_delivery_day_from  VARCHAR2(10);                 -- 出庫日From
    lv_delivery_day_to    VARCHAR2(10);                 -- 出庫日To
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
    lv_delivery_dest_name xxcmn_item_locations2_v.description%TYPE ;
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
    gd_exec_date                      :=  SYSDATE ;  -- 実施日
    -- =====================================================
    -- パラメータチェック
    -- =====================================================
    prc_check_param_data
      (
        iv_delivery_date      =>  iv_delivery_date      -- 納期
       ,iv_delivery_day_from  =>  iv_delivery_day_from  -- 出庫日From
       ,iv_delivery_day_to    =>  iv_delivery_day_to    -- 出庫日To
       ,ov_delivery_date      =>  lv_delivery_date      -- 納期
       ,ov_delivery_day_from  =>  lv_delivery_day_from  -- 出庫日From
       ,ov_delivery_day_to    =>  lv_delivery_day_to    -- 出庫日To
       ,ov_errbuf             =>  lv_errbuf             -- エラー・メッセージ           --# 固定 #
       ,ov_retcode            =>  lv_retcode            -- リターン・コード             --# 固定 #
       ,ov_errmsg             =>  lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
      ) ;
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- パラメータ格納
    lr_param_rec.iv_delivery_dest     :=  iv_delivery_dest ;                -- 01 : 納入先
    lr_param_rec.iv_delivery_form     :=  iv_delivery_form ;                -- 02 : 出庫形態
    lr_param_rec.iv_delivery_date     :=  lv_delivery_date ;                -- 03 : 納期
    lr_param_rec.iv_delivery_day_from :=  lv_delivery_day_from ;            -- 04 : 出庫日From
    lr_param_rec.iv_delivery_day_to   :=  lv_delivery_day_to ;              -- 05 : 出庫日To
--
    -- =====================================================
    -- 前処理(D-1)
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
    -- データ出力(D-3)
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
    -- ＸＭＬ出力(D-3)
    -- ==================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
--
    -- --------------------------------------------------
    -- 抽出データが０件の場合
    -- --------------------------------------------------
    IF  ( lv_errmsg IS NOT NULL )
    AND ( lv_retcode = gv_status_warn ) THEN
--
      -- 出庫形態の取引タイプを取得する。
      BEGIN
        SELECT  xott2v.transaction_type_name   AS transaction_type_name  -- 出庫形態
        INTO    lr_param_rec.iv_delivery_form
        FROM    xxwsh_oe_transaction_types2_v  xott2v                     -- 受注タイプ情報view2
        WHERE   xott2v.transaction_type_id = iv_delivery_form;
      EXCEPTION
        WHEN  OTHERS  THEN
          NULL;
      END;
--
      -- 納入先名称を取得する。
      BEGIN
        SELECT  xil2v.description           AS description    -- 納入先(名称)
        INTO    lv_delivery_dest_name
        FROM    xxcmn_item_locations2_v     xil2v             -- opm保管場所情報view2
        WHERE   xil2v.segment1          =   lr_param_rec.iv_delivery_dest;
      EXCEPTION
        WHEN  OTHERS  THEN
          NULL;
      END;
--
      -- ０件メッセージ出力
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  <data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <lg_denpyo_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      <g_denpyo>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <tyohyo_id>' 
        || gc_report_id 
        || '</tyohyo_id>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <shuturyoku_hiduke>' 
        || TO_CHAR(gd_exec_date, gc_char_dt_format) 
        || '</shuturyoku_hiduke>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <tantou_busho>' 
        || gv_department_code 
        || '</tantou_busho>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <tantou_name>' 
        || gv_department_name 
        || '</tantou_name>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <syukkobi_from>' 
        || TO_CHAR(lr_param_rec.iv_delivery_day_from, gc_date_fmt_ymd_ja) 
        || '</syukkobi_from>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <syukkobi_to>' 
        || TO_CHAR(lr_param_rec.iv_delivery_day_to, gc_date_fmt_ymd_ja) 
        || '</syukkobi_to>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <nounyu_saki_code>' 
        || lr_param_rec.iv_delivery_dest 
        || '</nounyu_saki_code>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <nounyu_saki_name>' 
        || lv_delivery_dest_name 
        || '</nounyu_saki_name>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <syukko_keitai>' 
        || lr_param_rec.iv_delivery_form 
        || '</syukko_keitai>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <lg_shukko>' ) ;
        FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          <msg>' 
        || lv_errmsg 
      || '</msg>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        </lg_shukko>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      </g_denpyo>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    </lg_denpyo_info>' ) ;
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
      ov_errbuf  := lv_errbuf ;
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
       errbuf                 OUT   VARCHAR2          -- エラーメッセージ
      ,retcode                OUT   VARCHAR2          -- エラーコード
      ,iv_delivery_dest       IN    VARCHAR2          -- 01 : 納入先
      ,iv_delivery_form       IN    VARCHAR2          -- 02 : 出庫形態
      ,iv_delivery_date       IN    VARCHAR2          -- 03 : 納期
      ,iv_delivery_day_from   IN    VARCHAR2          -- 04 : 出庫日From
      ,iv_delivery_day_to     IN    VARCHAR2          -- 05 : 出庫日To
    )
--
--###########################  固定部 START   ###########################
--
  IS
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
        iv_delivery_dest      => iv_delivery_dest     -- 01 : 納入先
       ,iv_delivery_form      => iv_delivery_form     -- 02 : 出庫形態
       ,iv_delivery_date      => iv_delivery_date     -- 03 : 納期
       ,iv_delivery_day_from  => iv_delivery_day_from -- 04 : 出庫日From
       ,iv_delivery_day_to    => iv_delivery_day_to   -- 05 : 出庫日To
       ,ov_errbuf             => lv_errbuf            -- エラー・メッセージ           --# 固定 #
       ,ov_retcode            => lv_retcode           -- リターン・コード             --# 固定 #
       ,ov_errmsg             => lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
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
END xxwsh920004c;
/