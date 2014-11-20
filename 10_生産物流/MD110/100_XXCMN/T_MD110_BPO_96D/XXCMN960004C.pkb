CREATE OR REPLACE PACKAGE BODY XXCMN960004C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2012. All rights reserved.
 *
 * Package Name     : XXCMN960004C(body)
 * Description      : 受入（標準）バックアップ
 * MD.050           : T_MD050_BPO_96D_受入（標準）バックアップ
 * Version          : 1.00
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/10/26   1.00  Megumu.Kitajima   新規作成
 *  2013/02/21   1.00  D.Sugahara        結合障害IT_0019(構成管理までVersionはあげない）
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
  gn_arc_cnt_line           NUMBER;                                             -- バックアップ件数（受入明細（標準））
  gn_arc_cnt_trx            NUMBER;                                             -- バックアップ件数（受入取引（標準））
  gn_arc_cnt_header         NUMBER;                                             -- バックアップ件数（受入ヘッダ（標準））
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
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  local_process_expt        EXCEPTION;
  not_init_collection_expt  EXCEPTION;
  PRAGMA EXCEPTION_INIT(not_init_collection_expt, -6531);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCMN960004C';     -- パッケージ名
  cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCMN';            -- アドオン：マスタ・経理・共通領域
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  TYPE g_rcv_line_ttype    IS TABLE OF xxcmn_rcv_shipment_lines_arc%ROWTYPE INDEX BY BINARY_INTEGER;
  TYPE g_rcv_trx_ttype     IS TABLE OF xxcmn_rcv_transactions_arc%ROWTYPE   INDEX BY BINARY_INTEGER;
  TYPE g_rcv_header_ttype  IS TABLE OF xxcmn_rcv_shipment_headers_arc%ROWTYPE   INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_proc_date  IN  VARCHAR2,     --   1.処理日
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    cv_purge_def_code   CONSTANT VARCHAR2(30) := 'XXCMN960004';               -- パージ定義コード
    cv_purge_type             CONSTANT VARCHAR2(30) := '1';                   -- バックアップタイプ
    cv_purge_code             CONSTANT VARCHAR2(30) := '9601';                -- バックアップコード
    cv_date_format            CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';          -- 日付フォーマット
    cv_xxcmn_commit_range     CONSTANT VARCHAR2(30) := 'XXCMN_COMMIT_RANGE';  -- 分割コミット数
    cv_xxcmn_archive_range    CONSTANT VARCHAR2(30) := 'XXCMN_ARCHIVE_RANGE'; -- バックアップレンジ
    cv_mo_org_id              CONSTANT VARCHAR2(30) := 'ORG_ID';              -- MO：営業単位
    cv_shipping               CONSTANT VARCHAR2(2)  := '04';
    cv_sikyu                  CONSTANT VARCHAR2(2)  := '08';
    cv_return                 CONSTANT VARCHAR2(6)  := 'RETURN';
    cv_closed                 CONSTANT VARCHAR2(10) := 'CLOSED';             -- 受注ステータス(クローズ)
    cv_get_priod_msg          CONSTANT VARCHAR2(100):= 'APP-XXCMN-11012';    -- バックアップ期間の取得に失敗しました。
    cv_get_profile_msg        CONSTANT VARCHAR2(100):= 'APP-XXCMN-10002';    -- プロファイル[ ＆NG_PROFILE ]の取得に
                                                                             -- 失敗しました。
    cv_local_others_line_msg  CONSTANT VARCHAR2(100):= 'APP-XXCMN-11018';    -- バックアップ処理に失敗しました。
                                                                         --【受入（標準）】受入明細標準ID： ＆KEY
    cv_local_others_tran_msg  CONSTANT VARCHAR2(100):= 'APP-XXCMN-11032';    -- バックアップ処理に失敗しました。
                                                                         --【受入（標準）】受入取引標準ID： ＆KEY
    cv_local_others_hdr_msg   CONSTANT VARCHAR2(100):= 'APP-XXCMN-11033';    -- バックアップ処理に失敗しました。
                                                                         --【受入（標準）】受入ヘッダ標準ID： ＆KEY
    cv_token_key              CONSTANT VARCHAR2(10) := 'KEY';                -- 
    cv_token_profile          CONSTANT VARCHAR2(10) := 'NG_PROFILE';
--
    -- *** ローカル変数 ***
    ln_arc_cnt_line_yet       NUMBER DEFAULT 0;                                 -- 未コミットバックアップ件数（受入明細（標準））
    ln_arc_cnt_trx_yet        NUMBER DEFAULT 0;                                 -- 未コミットバックアップ件数（受入取引（標準））
    ln_arc_cnt_header_yet     NUMBER DEFAULT 0;                                 -- 未コミットバックアップ件数（受入ヘッダ（標準））
    ln_archive_period         NUMBER;                                           -- バックアップ期間
    ln_archive_range          NUMBER;                                           -- バックアップレンジ
    ld_standard_date          DATE;                                             -- 基準日
    ln_commit_range           NUMBER;                                           -- 分割コミット数
    lt_org_id                 oe_order_headers_all.org_id%TYPE;                 -- 営業単位ID
    lv_process_part           VARCHAR2(1000);                                   -- 処理部
    lt_shipment_header_id     rcv_shipment_headers.shipment_header_id%TYPE;     -- 受入ヘッダID
    lt_shipment_line_id       rcv_shipment_lines.shipment_line_id%TYPE;         -- 受入明細ID
    lt_transaction_id         rcv_transactions.transaction_id%TYPE;             -- 受入取引ID
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    /*
    -- 受入ヘッダ（標準）
    CURSOR バックアップ対象受入ヘッダ（標準）取得
      id_基準日  IN DATE
      in_バックアップレンジ IN NUMBER
      it_営業単位ＩＤ IN 受注ヘッダ（標準）．営業単位ＩＤ%TYPE
    IS
      SELECT 
             受入ヘッダ（標準）全カラム
      FROM 受注ヘッダ（アドオン）
           ,    受注タイプ（標準）
           ,    受注ヘッダ（標準）
           ,    受注明細（標準）
           ,    受入明細（標準）
           ,    受入ヘッダ（標準）
      WHERE 受注ヘッダ（アドオン）．ステータス IN ('04','08')
      AND 受注ヘッダ（アドオン）．着荷日 >= id_基準日 - in_バックアップレンジ
      AND 受注ヘッダ（アドオン）．着荷日 < id_基準日
      AND 受注タイプ（標準）．受注タイプID = 受注ヘッダ（アドオン）．受注タイプID
      AND 受注タイプ（標準）．受注カテゴリコード = 'RETURN'
      AND 受注ヘッダ（標準）．受注ヘッダID = 受注ヘッダ（アドオン）．受注ヘッダID
      AND 受注ヘッダ（標準）．営業単位ID = it_営業単位ID
      AND 受注明細（標準）．受注ヘッダID = 受注ヘッダ（標準）．受注ヘッダID
      AND 受入明細（標準）．受注ヘッダID = 受注明細（標準）．受注ヘッダID
      AND 受入明細（標準）．受注明細ID = 受注明細（標準）．受注明細ID
      AND 受入明細（標準）．受入ヘッダID = 受入ヘッダ（標準）．受入ヘッダID
      AND 受注ヘッダ（標準）．ステータス = クローズ
      AND NOT EXISTS (
               SELECT '1' FROM 受入ヘッダ（標準）バックアップ
               WHERE  受入ヘッダ（標準）バックアップ．受入ヘッダID = 受入ヘッダ（標準）．受入ヘッダID
               AND      ROWNUM = 1
             )
      GROUP BY
        受入ヘッダ（標準）全カラム
      ;
    */
    CURSOR archive_rcv_header_cur(
      id_standard_date           DATE
     ,in_archive_range           NUMBER
     ,it_org_id                  oe_order_headers_all.org_id%TYPE
    )
    IS
      SELECT /*+ USE_NL(xoha otta ooha oola rsl rsh)
              INDEX( xoha XXWSH_OH_N15 ooha OE_ORDER_HEADERS_U1 rsl PO_RSL_N2 oola OE_ORDER_LINES_U1 rsh RCV_SHIPMENT_HEADERS_U1 ) */
              rsh.shipment_header_id            AS shipment_header_id      
             ,rsh.last_update_date              AS last_update_date        
             ,rsh.last_updated_by               AS last_updated_by         
             ,rsh.creation_date                 AS creation_date           
             ,rsh.created_by                    AS created_by              
             ,rsh.last_update_login             AS last_update_login       
             ,rsh.receipt_source_code           AS receipt_source_code     
             ,rsh.vendor_id                     AS vendor_id               
             ,rsh.vendor_site_id                AS vendor_site_id          
             ,rsh.organization_id               AS organization_id         
             ,rsh.shipment_num                  AS shipment_num            
             ,rsh.receipt_num                   AS receipt_num             
             ,rsh.ship_to_location_id           AS ship_to_location_id     
             ,rsh.bill_of_lading                AS bill_of_lading          
             ,rsh.packing_slip                  AS packing_slip            
             ,rsh.shipped_date                  AS shipped_date            
             ,rsh.freight_carrier_code          AS freight_carrier_code    
             ,rsh.expected_receipt_date         AS expected_receipt_date   
             ,rsh.employee_id                   AS employee_id             
             ,rsh.num_of_containers             AS num_of_containers       
             ,rsh.waybill_airbill_num           AS waybill_airbill_num     
             ,rsh.comments                      AS comments                
             ,rsh.attribute_category            AS attribute_category      
             ,rsh.attribute1                    AS attribute1              
             ,rsh.attribute2                    AS attribute2              
             ,rsh.attribute3                    AS attribute3              
             ,rsh.attribute4                    AS attribute4              
             ,rsh.attribute5                    AS attribute5              
             ,rsh.attribute6                    AS attribute6              
             ,rsh.attribute7                    AS attribute7              
             ,rsh.attribute8                    AS attribute8              
             ,rsh.attribute9                    AS attribute9              
             ,rsh.attribute10                   AS attribute10             
             ,rsh.attribute11                   AS attribute11             
             ,rsh.attribute12                   AS attribute12             
             ,rsh.attribute13                   AS attribute13             
             ,rsh.attribute14                   AS attribute14             
             ,rsh.attribute15                   AS attribute15             
             ,rsh.ussgl_transaction_code        AS ussgl_transaction_code  
             ,rsh.government_context            AS government_context      
             ,rsh.request_id                    AS request_id              
             ,rsh.program_application_id        AS program_application_id  
             ,rsh.program_id                    AS program_id              
             ,rsh.program_update_date           AS program_update_date     
             ,rsh.asn_type                      AS asn_type                
             ,rsh.edi_control_num               AS edi_control_num         
             ,rsh.notice_creation_date          AS notice_creation_date    
             ,rsh.gross_weight                  AS gross_weight            
             ,rsh.gross_weight_uom_code         AS gross_weight_uom_code   
             ,rsh.net_weight                    AS net_weight              
             ,rsh.net_weight_uom_code           AS net_weight_uom_code     
             ,rsh.tar_weight                    AS tar_weight              
             ,rsh.tar_weight_uom_code           AS tar_weight_uom_code     
             ,rsh.packaging_code                AS packaging_code          
             ,rsh.carrier_method                AS carrier_method          
             ,rsh.carrier_equipment             AS carrier_equipment       
             ,rsh.carrier_equipment_num         AS carrier_equipment_num   
             ,rsh.carrier_equipment_alpha       AS carrier_equipment_alpha 
             ,rsh.special_handling_code         AS special_handling_code   
             ,rsh.hazard_code                   AS hazard_code             
             ,rsh.hazard_class                  AS hazard_class            
             ,rsh.hazard_description            AS hazard_description      
             ,rsh.freight_terms                 AS freight_terms           
             ,rsh.freight_bill_number           AS freight_bill_number     
             ,rsh.invoice_num                   AS invoice_num             
             ,rsh.invoice_date                  AS invoice_date            
             ,rsh.invoice_amount                AS invoice_amount          
             ,rsh.tax_name                      AS tax_name                
             ,rsh.tax_amount                    AS tax_amount              
             ,rsh.freight_amount                AS freight_amount          
             ,rsh.invoice_status_code           AS invoice_status_code     
             ,rsh.asn_status                    AS asn_status              
             ,rsh.currency_code                 AS currency_code           
             ,rsh.conversion_rate_type          AS conversion_rate_type    
             ,rsh.conversion_rate               AS conversion_rate         
             ,rsh.conversion_date               AS conversion_date         
             ,rsh.payment_terms_id              AS payment_terms_id        
             ,rsh.mrc_conversion_rate_type      AS mrc_conversion_rate_type
             ,rsh.mrc_conversion_date           AS mrc_conversion_date     
             ,rsh.mrc_conversion_rate           AS mrc_conversion_rate     
             ,rsh.ship_to_org_id                AS ship_to_org_id          
             ,rsh.customer_id                   AS customer_id             
             ,rsh.customer_site_id              AS customer_site_id        
             ,rsh.remit_to_site_id              AS remit_to_site_id        
      FROM    xxwsh_order_headers_all  xoha
             ,oe_transaction_types_all otta
             ,oe_order_headers_all     ooha
             ,oe_order_lines_all       oola
             ,rcv_shipment_lines       rsl
             ,rcv_shipment_headers     rsh
      WHERE   xoha.req_status          IN (cv_shipping, cv_sikyu)
      AND     xoha.arrival_date        >= id_standard_date - in_archive_range
      AND     xoha.arrival_date         < id_standard_date
      AND     otta.transaction_type_id  = xoha.order_type_id
      AND     otta.order_category_code  = cv_return
      AND     ooha.header_id            = xoha.header_id
      AND     ooha.org_id               = it_org_id
      AND     oola.header_id            = ooha.header_id
      AND     ooha.flow_status_code     = cv_closed
      AND     rsl.oe_order_header_id    = ooha.header_id
      AND     rsl.oe_order_line_id      = oola.line_id
      AND     rsl.shipment_header_id    = rsh.shipment_header_id
      AND     NOT EXISTS (
                SELECT  1
                FROM    xxcmn_rcv_shipment_headers_arc  xrsla
                WHERE   xrsla.shipment_header_id = rsh.shipment_header_id
                AND     ROWNUM                 = 1
              )
      GROUP BY
         rsh.shipment_header_id
        ,rsh.last_update_date
        ,rsh.last_updated_by
        ,rsh.creation_date
        ,rsh.created_by
        ,rsh.last_update_login
        ,rsh.receipt_source_code
        ,rsh.vendor_id
        ,rsh.vendor_site_id
        ,rsh.organization_id
        ,rsh.shipment_num
        ,rsh.receipt_num
        ,rsh.ship_to_location_id
        ,rsh.bill_of_lading
        ,rsh.packing_slip
        ,rsh.shipped_date
        ,rsh.freight_carrier_code
        ,rsh.expected_receipt_date
        ,rsh.employee_id
        ,rsh.num_of_containers
        ,rsh.waybill_airbill_num
        ,rsh.comments
        ,rsh.attribute_category
        ,rsh.attribute1
        ,rsh.attribute2
        ,rsh.attribute3
        ,rsh.attribute4
        ,rsh.attribute5
        ,rsh.attribute6
        ,rsh.attribute7
        ,rsh.attribute8
        ,rsh.attribute9
        ,rsh.attribute10
        ,rsh.attribute11
        ,rsh.attribute12
        ,rsh.attribute13
        ,rsh.attribute14
        ,rsh.attribute15
        ,rsh.ussgl_transaction_code
        ,rsh.government_context
        ,rsh.request_id
        ,rsh.program_application_id
        ,rsh.program_id
        ,rsh.program_update_date
        ,rsh.asn_type
        ,rsh.edi_control_num
        ,rsh.notice_creation_date
        ,rsh.gross_weight
        ,rsh.gross_weight_uom_code
        ,rsh.net_weight
        ,rsh.net_weight_uom_code
        ,rsh.tar_weight
        ,rsh.tar_weight_uom_code
        ,rsh.packaging_code
        ,rsh.carrier_method
        ,rsh.carrier_equipment
        ,rsh.carrier_equipment_num
        ,rsh.carrier_equipment_alpha
        ,rsh.special_handling_code
        ,rsh.hazard_code
        ,rsh.hazard_class
        ,rsh.hazard_description
        ,rsh.freight_terms
        ,rsh.freight_bill_number
        ,rsh.invoice_num
        ,rsh.invoice_date
        ,rsh.invoice_amount
        ,rsh.tax_name
        ,rsh.tax_amount
        ,rsh.freight_amount
        ,rsh.invoice_status_code
        ,rsh.asn_status
        ,rsh.currency_code
        ,rsh.conversion_rate_type
        ,rsh.conversion_rate
        ,rsh.conversion_date
        ,rsh.payment_terms_id
        ,rsh.mrc_conversion_rate_type
        ,rsh.mrc_conversion_date
        ,rsh.mrc_conversion_rate
        ,rsh.ship_to_org_id
        ,rsh.customer_id
        ,rsh.customer_site_id
        ,rsh.remit_to_site_id
    ;
    /*
    -- 受入明細（標準）
    CURSOR バックアップ対象受入明細（標準）取得
      it_受入ヘッダＩＤ IN 受入ヘッダ（標準）．受入ヘッダＩＤ%TYPE
    IS
      SELECT 
             受入明細（標準）全カラム
      FROM   受入明細（標準）
      WHERE  受入ヘッダ（標準）．受入ヘッダID = it_受入ヘッダID
      ;
    */
    CURSOR archive_rcv_line_cur(
      it_shipment_header_id        rcv_shipment_headers.shipment_header_id%TYPE
    )
    IS
      SELECT  /*+ INDEX(rsl RCV_SHIPMENT_LINES_U2 ) */
              rsl.shipment_line_id              AS shipment_line_id            
             ,rsl.last_update_date              AS last_update_date            
             ,rsl.last_updated_by               AS last_updated_by             
             ,rsl.creation_date                 AS creation_date               
             ,rsl.created_by                    AS created_by                  
             ,rsl.last_update_login             AS last_update_login           
             ,rsl.shipment_header_id            AS shipment_header_id          
             ,rsl.line_num                      AS line_num                    
             ,rsl.category_id                   AS category_id                 
             ,rsl.quantity_shipped              AS quantity_shipped            
             ,rsl.quantity_received             AS quantity_received           
             ,rsl.unit_of_measure               AS unit_of_measure             
             ,rsl.item_description              AS item_description            
             ,rsl.item_id                       AS item_id                     
             ,rsl.item_revision                 AS item_revision               
             ,rsl.vendor_item_num               AS vendor_item_num             
             ,rsl.vendor_lot_num                AS vendor_lot_num              
             ,rsl.uom_conversion_rate           AS uom_conversion_rate         
             ,rsl.shipment_line_status_code     AS shipment_line_status_code   
             ,rsl.source_document_code          AS source_document_code        
             ,rsl.po_header_id                  AS po_header_id                
             ,rsl.po_release_id                 AS po_release_id               
             ,rsl.po_line_id                    AS po_line_id                  
             ,rsl.po_line_location_id           AS po_line_location_id         
             ,rsl.po_distribution_id            AS po_distribution_id          
             ,rsl.requisition_line_id           AS requisition_line_id         
             ,rsl.req_distribution_id           AS req_distribution_id         
             ,rsl.routing_header_id             AS routing_header_id           
             ,rsl.packing_slip                  AS packing_slip                
             ,rsl.from_organization_id          AS from_organization_id        
             ,rsl.deliver_to_person_id          AS deliver_to_person_id        
             ,rsl.employee_id                   AS employee_id                 
             ,rsl.destination_type_code         AS destination_type_code       
             ,rsl.to_organization_id            AS to_organization_id          
             ,rsl.to_subinventory               AS to_subinventory             
             ,rsl.locator_id                    AS locator_id                  
             ,rsl.deliver_to_location_id        AS deliver_to_location_id      
             ,rsl.charge_account_id             AS charge_account_id           
             ,rsl.transportation_account_id     AS transportation_account_id   
             ,rsl.shipment_unit_price           AS shipment_unit_price         
             ,rsl.transfer_cost                 AS transfer_cost               
             ,rsl.transportation_cost           AS transportation_cost         
             ,rsl.comments                      AS comments                    
             ,rsl.attribute_category            AS attribute_category          
             ,rsl.attribute1                    AS attribute1                  
             ,rsl.attribute2                    AS attribute2                  
             ,rsl.attribute3                    AS attribute3                  
             ,rsl.attribute4                    AS attribute4                  
             ,rsl.attribute5                    AS attribute5                  
             ,rsl.attribute6                    AS attribute6                  
             ,rsl.attribute7                    AS attribute7                  
             ,rsl.attribute8                    AS attribute8                  
             ,rsl.attribute9                    AS attribute9                  
             ,rsl.attribute10                   AS attribute10                 
             ,rsl.attribute11                   AS attribute11                 
             ,rsl.attribute12                   AS attribute12                 
             ,rsl.attribute13                   AS attribute13                 
             ,rsl.attribute14                   AS attribute14                 
             ,rsl.attribute15                   AS attribute15                 
             ,rsl.reason_id                     AS reason_id                   
             ,rsl.ussgl_transaction_code        AS ussgl_transaction_code      
             ,rsl.government_context            AS government_context          
             ,rsl.request_id                    AS request_id                  
             ,rsl.program_application_id        AS program_application_id      
             ,rsl.program_id                    AS program_id                  
             ,rsl.program_update_date           AS program_update_date         
             ,rsl.destination_context           AS destination_context         
             ,rsl.primary_unit_of_measure       AS primary_unit_of_measure     
             ,rsl.excess_transport_reason       AS excess_transport_reason     
             ,rsl.excess_transport_responsible  AS excess_transport_responsible
             ,rsl.excess_transport_auth_num     AS excess_transport_auth_num   
             ,rsl.asn_line_flag                 AS asn_line_flag               
             ,rsl.original_asn_parent_line_id   AS original_asn_parent_line_id 
             ,rsl.original_asn_line_flag        AS original_asn_line_flag      
             ,rsl.vendor_cum_shipped_quantity   AS vendor_cum_shipped_quantity 
             ,rsl.notice_unit_price             AS notice_unit_price           
             ,rsl.tax_name                      AS tax_name                    
             ,rsl.tax_amount                    AS tax_amount                  
             ,rsl.invoice_status_code           AS invoice_status_code         
             ,rsl.cum_comparison_flag           AS cum_comparison_flag         
             ,rsl.container_num                 AS container_num               
             ,rsl.truck_num                     AS truck_num                   
             ,rsl.bar_code_label                AS bar_code_label              
             ,rsl.transfer_percentage           AS transfer_percentage         
             ,rsl.mrc_shipment_unit_price       AS mrc_shipment_unit_price     
             ,rsl.mrc_transfer_cost             AS mrc_transfer_cost           
             ,rsl.mrc_transportation_cost       AS mrc_transportation_cost     
             ,rsl.mrc_notice_unit_price         AS mrc_notice_unit_price       
             ,rsl.ship_to_location_id           AS ship_to_location_id         
             ,rsl.country_of_origin_code        AS country_of_origin_code      
             ,rsl.oe_order_header_id            AS oe_order_header_id          
             ,rsl.oe_order_line_id              AS oe_order_line_id            
             ,rsl.customer_item_num             AS customer_item_num           
             ,rsl.cost_group_id                 AS cost_group_id               
             ,rsl.secondary_quantity_shipped    AS secondary_quantity_shipped  
             ,rsl.secondary_quantity_received   AS secondary_quantity_received 
             ,rsl.secondary_unit_of_measure     AS secondary_unit_of_measure   
             ,rsl.qc_grade                      AS qc_grade                    
             ,rsl.mmt_transaction_id            AS mmt_transaction_id          
             ,rsl.asn_lpn_id                    AS asn_lpn_id                  
             ,rsl.amount                        AS amount                      
             ,rsl.amount_received               AS amount_received             
             ,rsl.job_id                        AS job_id                      
             ,rsl.timecard_id                   AS timecard_id                 
             ,rsl.timecard_ovn                  AS timecard_ovn                
      FROM    rcv_shipment_lines       rsl
      WHERE   rsl.shipment_header_id = it_shipment_header_id
    ;
    /*
    -- 受入取引（標準）
    CURSOR バックアップ対象受入取引（標準）取得
      it_受入明細ＩＤ IN 受入明細（標準）．受入明細ＩＤ%TYPE
    IS
      SELECT
             受入取引（標準）全カラム
      FROM 受入取引（標準）
      WHERE 受入取引（標準）．受入ヘッダＩＤ = it_受入ヘッダＩＤ
      ;
    */
    CURSOR archive_rcv_trx_cur(
      it_shipment_header_id        rcv_shipment_headers.shipment_header_id%TYPE
    )
    IS
      SELECT /*+ INDEX(rt RCV_TRANSACTIONS_N2 ) */
              rt.transaction_id                 AS transaction_id              
             ,rt.last_update_date               AS last_update_date            
             ,rt.last_updated_by                AS last_updated_by             
             ,rt.creation_date                  AS creation_date               
             ,rt.created_by                     AS created_by                  
             ,rt.last_update_login              AS last_update_login           
             ,rt.request_id                     AS request_id                  
             ,rt.program_application_id         AS program_application_id      
             ,rt.program_id                     AS program_id                  
             ,rt.program_update_date            AS program_update_date         
             ,rt.transaction_type               AS transaction_type            
             ,rt.transaction_date               AS transaction_date            
             ,rt.quantity                       AS quantity                    
             ,rt.unit_of_measure                AS unit_of_measure             
             ,rt.shipment_header_id             AS shipment_header_id          
             ,rt.shipment_line_id               AS shipment_line_id            
             ,rt.user_entered_flag              AS user_entered_flag           
             ,rt.interface_source_code          AS interface_source_code       
             ,rt.interface_source_line_id       AS interface_source_line_id    
             ,rt.inv_transaction_id             AS inv_transaction_id          
             ,rt.source_document_code           AS source_document_code        
             ,rt.destination_type_code          AS destination_type_code       
             ,rt.primary_quantity               AS primary_quantity            
             ,rt.primary_unit_of_measure        AS primary_unit_of_measure     
             ,rt.uom_code                       AS uom_code                    
             ,rt.employee_id                    AS employee_id                 
             ,rt.parent_transaction_id          AS parent_transaction_id       
             ,rt.po_header_id                   AS po_header_id                
             ,rt.po_release_id                  AS po_release_id               
             ,rt.po_line_id                     AS po_line_id                  
             ,rt.po_line_location_id            AS po_line_location_id         
             ,rt.po_distribution_id             AS po_distribution_id          
             ,rt.po_revision_num                AS po_revision_num             
             ,rt.requisition_line_id            AS requisition_line_id         
             ,rt.po_unit_price                  AS po_unit_price               
             ,rt.currency_code                  AS currency_code               
             ,rt.currency_conversion_type       AS currency_conversion_type    
             ,rt.currency_conversion_rate       AS currency_conversion_rate    
             ,rt.currency_conversion_date       AS currency_conversion_date    
             ,rt.routing_header_id              AS routing_header_id           
             ,rt.routing_step_id                AS routing_step_id             
             ,rt.deliver_to_person_id           AS deliver_to_person_id        
             ,rt.deliver_to_location_id         AS deliver_to_location_id      
             ,rt.vendor_id                      AS vendor_id                   
             ,rt.vendor_site_id                 AS vendor_site_id              
             ,rt.organization_id                AS organization_id             
             ,rt.subinventory                   AS subinventory                
             ,rt.locator_id                     AS locator_id                  
             ,rt.wip_entity_id                  AS wip_entity_id               
             ,rt.wip_line_id                    AS wip_line_id                 
             ,rt.wip_repetitive_schedule_id     AS wip_repetitive_schedule_id  
             ,rt.wip_operation_seq_num          AS wip_operation_seq_num       
             ,rt.wip_resource_seq_num           AS wip_resource_seq_num        
             ,rt.bom_resource_id                AS bom_resource_id             
             ,rt.location_id                    AS location_id                 
             ,rt.substitute_unordered_code      AS substitute_unordered_code   
             ,rt.receipt_exception_flag         AS receipt_exception_flag      
             ,rt.inspection_status_code         AS inspection_status_code      
             ,rt.accrual_status_code            AS accrual_status_code         
             ,rt.inspection_quality_code        AS inspection_quality_code     
             ,rt.vendor_lot_num                 AS vendor_lot_num              
             ,rt.rma_reference                  AS rma_reference               
             ,rt.comments                       AS comments                    
             ,rt.attribute_category             AS attribute_category          
             ,rt.attribute1                     AS attribute1                  
             ,rt.attribute2                     AS attribute2                  
             ,rt.attribute3                     AS attribute3                  
             ,rt.attribute4                     AS attribute4                  
             ,rt.attribute5                     AS attribute5                  
             ,rt.attribute6                     AS attribute6                  
             ,rt.attribute7                     AS attribute7                  
             ,rt.attribute8                     AS attribute8                  
             ,rt.attribute9                     AS attribute9                  
             ,rt.attribute10                    AS attribute10                 
             ,rt.attribute11                    AS attribute11                 
             ,rt.attribute12                    AS attribute12                 
             ,rt.attribute13                    AS attribute13                 
             ,rt.attribute14                    AS attribute14                 
             ,rt.attribute15                    AS attribute15                 
             ,rt.req_distribution_id            AS req_distribution_id         
             ,rt.department_code                AS department_code             
             ,rt.reason_id                      AS reason_id                   
             ,rt.destination_context            AS destination_context         
             ,rt.locator_attribute              AS locator_attribute           
             ,rt.child_inspection_flag          AS child_inspection_flag       
             ,rt.source_doc_unit_of_measure     AS source_doc_unit_of_measure  
             ,rt.source_doc_quantity            AS source_doc_quantity         
             ,rt.interface_transaction_id       AS interface_transaction_id    
             ,rt.group_id                       AS group_id                    
             ,rt.movement_id                    AS movement_id                 
             ,rt.invoice_id                     AS invoice_id                  
             ,rt.invoice_status_code            AS invoice_status_code         
             ,rt.qa_collection_id               AS qa_collection_id            
             ,rt.mrc_currency_conversion_type   AS mrc_currency_conversion_type
             ,rt.mrc_currency_conversion_date   AS mrc_currency_conversion_date
             ,rt.mrc_currency_conversion_rate   AS mrc_currency_conversion_rate
             ,rt.country_of_origin_code         AS country_of_origin_code      
             ,rt.mvt_stat_status                AS mvt_stat_status             
             ,rt.quantity_billed                AS quantity_billed             
             ,rt.match_flag                     AS match_flag                  
             ,rt.amount_billed                  AS amount_billed               
             ,rt.match_option                   AS match_option                
             ,rt.oe_order_header_id             AS oe_order_header_id          
             ,rt.oe_order_line_id               AS oe_order_line_id            
             ,rt.customer_id                    AS customer_id                 
             ,rt.customer_site_id               AS customer_site_id            
             ,rt.lpn_id                         AS lpn_id                      
             ,rt.transfer_lpn_id                AS transfer_lpn_id             
             ,rt.mobile_txn                     AS mobile_txn                  
             ,rt.secondary_quantity             AS secondary_quantity          
             ,rt.secondary_unit_of_measure      AS secondary_unit_of_measure   
             ,rt.qc_grade                       AS qc_grade                    
             ,rt.secondary_uom_code             AS secondary_uom_code          
             ,rt.pa_addition_flag               AS pa_addition_flag            
             ,rt.consigned_flag                 AS consigned_flag              
             ,rt.source_transaction_num         AS source_transaction_num      
             ,rt.from_subinventory              AS from_subinventory           
             ,rt.from_locator_id                AS from_locator_id             
             ,rt.amount                         AS amount                      
             ,rt.dropship_type_code             AS dropship_type_code          
             ,rt.lpn_group_id                   AS lpn_group_id                
             ,rt.job_id                         AS job_id                      
             ,rt.timecard_id                    AS timecard_id                 
             ,rt.timecard_ovn                   AS timecard_ovn                
             ,rt.project_id                     AS project_id                  
             ,rt.task_id                        AS task_id                     
      FROM    rcv_transactions  rt
      WHERE   rt.shipment_header_id = it_shipment_header_id
    ;
    -- <カーソル名>レコード型
    l_rcv_header_tbl         g_rcv_header_ttype;                                 -- 受入ヘッダ（標準）テーブル
    l_rcv_line_tbl           g_rcv_line_ttype;                                   -- 受入明細（標準）テーブル
    l_rcv_trx_tbl            g_rcv_trx_ttype;                                    -- 受入取引（標準）テーブル
--
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
    gn_arc_cnt_line   := 0;
    gn_arc_cnt_trx    := 0;
    gn_arc_cnt_header := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================================
    -- バックアップ期間取得
    -- ===============================================
    /*
    ln_バックアップ期間 := バックアップ期間取得共通関数（cv_バックアップタイプ,cv_バックアップコード）;
     */
    lv_process_part := 'バックアップ期間取得';
    ln_archive_period := xxcmn_common4_pkg.get_purge_period(cv_purge_type,cv_purge_code);
--
    IF ( ln_archive_period IS NULL ) THEN
--
      ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_get_priod_msg
                   );
      ov_retcode := cv_status_error;
      RAISE local_process_expt;
--
    END IF;
--
    -- ===============================================
    -- ＩＮパラメータの確認
    -- ===============================================
    /*
    iv_proc_dateがNULLの場合
--
      ld_基準日 := 処理日取得共通関数より取得した処理日 - ln_バックアップ期間;
--
    iv_proc_dateがNULLでないの場合
--
      ld_基準日 := TO_DATE(iv_proc_date) - ln_バックアップ期間;
     */
    lv_process_part := 'INパラメータの確認';
    IF ( iv_proc_date IS NULL ) THEN
--
--mod 2013/02/21 V1.00 D.Sugahara Start
--    ld_standard_date := xxccp_common_pkg2.get_process_date - ln_archive_period;
      ld_standard_date := xxcmn_common4_pkg.get_syori_date - ln_archive_period;
--mod 2013/02/21 V1.00 D.Sugahara Start
--
    ELSE
--
      ld_standard_date := TO_DATE(iv_proc_date, cv_date_format) - ln_archive_period;
--
    END IF;
--
    -- ===============================================
    -- プロファイル・オプション値取得
    -- ===============================================
    /*
    ln_分割コミット数 := TO_NUMBER(プロファイル・オプション取得(XXCMN:バックアップ分割コミット数));
    ln_バックアップレンジ := TO_NUMBER(プロファイル・オプション取得(XXCMN:バックアップレンジ));
    ln_営業単位ID = TO_NUMBER(プロファイル・オプション取得(MO:営業単位));
     */
    lv_process_part := 'プロファイル・オプション値取得（' || cv_xxcmn_commit_range || '）';
    ln_commit_range  := fnd_profile.value(cv_xxcmn_commit_range);
    IF ( ln_commit_range IS NULL ) THEN
      ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_get_profile_msg
                    ,iv_token_name1  => cv_token_profile
                    ,iv_token_value1 => cv_xxcmn_commit_range
                   );
      ov_retcode := cv_status_error;
      RAISE local_process_expt;
    END IF;
    --
    lv_process_part := 'プロファイル・オプション値取得（' || cv_xxcmn_archive_range || '）';
    ln_archive_range := fnd_profile.value(cv_xxcmn_archive_range);
    IF ( ln_archive_range IS NULL ) THEN
      ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_get_profile_msg
                    ,iv_token_name1  => cv_token_profile
                    ,iv_token_value1 => cv_xxcmn_archive_range
                   );
      ov_retcode := cv_status_error;
      RAISE local_process_expt;
    END IF;
    --
    lv_process_part := 'プロファイル・オプション値取得（' || cv_mo_org_id || '）';
    lt_org_id        := fnd_profile.value(cv_mo_org_id);
    IF ( lt_org_id IS NULL ) THEN
      ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_get_profile_msg
                    ,iv_token_name1  => cv_token_profile
                    ,iv_token_value1 => cv_mo_org_id
                   );
      ov_retcode := cv_status_error;
      RAISE local_process_expt;
    END IF;
--
    -- ===============================================
    -- バックアップ対象受入ヘッダ（標準）取得
    -- ===============================================
    /*
    FOR lr_header_rec IN バックアップ対象受入ヘッダ（標準）取得（ld_基準日，ln_バックアップレンジ，ln_営業単位ID） LOOP
     */
    << archive_rcv_header_loop >>
    FOR lr_header_rec IN archive_rcv_header_cur(
                           ld_standard_date
                          ,ln_archive_range
                          ,lt_org_id
                         )
    LOOP
--
      -- ===============================================
      -- 分割コミット
      -- ===============================================
      /*
      NVL(ln_分割コミット数, 0) <> 0の場合
       */
      IF ( NVL(ln_commit_range, 0) <> 0 ) THEN
--
        /*
        ln_未コミットバックアップ件数（受入ヘッダ（標準）） > 0 かつ MOD(ln_未コミットバックアップ件数（受入ヘッダ（標準））, ln_分割コミット数) = 0の場合
         */
        IF (  (ln_arc_cnt_header_yet > 0)
          AND (MOD(ln_arc_cnt_header_yet, ln_commit_range) = 0)
           )
        THEN
--
          /*
          FORALL ln_idx IN 1..ln_未コミットバックアップ件数（受入ヘッダ（標準））
            INSERT INTO 受入ヘッダ（標準）バックアップ
            (
                全カラム
              , バックアップ登録日
              , バックアップ要求ID
            )
            VALUES
            (
                l_受入ヘッダ（標準）テーブル（ln_idx）全カラム
              , SYSDATE
              , 要求ID
            )
           */
          lv_process_part := '受入ヘッダ（標準）登録１';
          FORALL ln_idx IN 1..ln_arc_cnt_header_yet
            INSERT INTO xxcmn_rcv_shipment_headers_arc VALUES l_rcv_header_tbl(ln_idx);
--
          /*
          l_受入ヘッダ（標準）テーブル．DELETE;
           */
          l_rcv_header_tbl.DELETE;
--
          /*
          FORALL ln_idx IN 1..ln_未コミットバックアップ件数（受入明細（標準））
            INSERT INTO 受入明細（標準）バックアップ
            (
                全カラム
              , バックアップ登録日
              , バックアップ要求ID
            )
            VALUES
            (
                l_受入明細（標準）テーブル（ln_idx）全カラム
              , SYSDATE
              , 要求ID
            )
           */
          lv_process_part := '受入明細（標準）登録１';
          FORALL ln_idx IN 1..ln_arc_cnt_line_yet
            INSERT INTO xxcmn_rcv_shipment_lines_arc VALUES l_rcv_line_tbl(ln_idx);
--
          /*
          l_受入明細（標準）テーブル．DELETE;
           */
          l_rcv_line_tbl.DELETE;
--
          /*
          FORALL ln_idx IN 1..ln_未コミットバックアップ件数（受入取引（標準））
            INSERT INTO 受入取引（標準）バックアップ
            (
                全カラム
              , バックアップ登録日
              , バックアップ要求ID
            )
            VALUES
            (
                l_受入取引（標準）テーブル（ln_idx）全カラム
              , SYSDATE
              , 要求ID
            )
           */
          lv_process_part := '受入取引（標準）登録１';
          FORALL ln_idx IN 1..ln_arc_cnt_trx_yet
            INSERT INTO xxcmn_rcv_transactions_arc VALUES l_rcv_trx_tbl(ln_idx);
--
          /*
          l_受入取引（標準）テーブル．DELETE;
           */
          l_rcv_trx_tbl.DELETE;
--
          /*
          ln_バックアップ件数（受入ヘッダ（標準）） := ln_バックアップ件数（受入ヘッダ（標準）） + ln_未コミットバックアップ件数（受入ヘッダ（標準））;
          ln_未コミットバックアップ件数（受入ヘッダ（標準）） := 0;
          */
          gn_arc_cnt_header     := gn_arc_cnt_header + ln_arc_cnt_header_yet;
          ln_arc_cnt_header_yet := 0;
--
          /*
          ln_バックアップ件数（受入明細（標準）） := ln_バックアップ件数（受入明細（標準）） + ln_未コミットバックアップ件数（受入明細（標準））;
          ln_未コミットバックアップ件数（受入明細（標準）） := 0;
          */
          gn_arc_cnt_line     := gn_arc_cnt_line + ln_arc_cnt_line_yet;
          ln_arc_cnt_line_yet := 0;
--
          /*
          ln_バックアップ件数（受入取引（標準）） := ln_バックアップ件数（受入取引（標準）） + ln_未コミットバックアップ件数（受入取引（標準））;
          ln_未コミットバックアップ件数（受入取引（標準）） := 0;
          */
          gn_arc_cnt_trx        := gn_arc_cnt_trx + ln_arc_cnt_trx_yet;
          ln_arc_cnt_trx_yet    := 0;
--
          /*
          COMMIT;
           */
          COMMIT;
--
        END IF;
--
      END IF;
--
      /*
      lt_対象受入ヘッダID := lr_header_rec．受入ヘッダID;
       */
      lt_shipment_header_id := lr_header_rec.shipment_header_id;
--
      -- ===============================================
      -- バックアップ対象受入明細（標準）取得
      -- ===============================================
      /*
      FOR lr_line_rec IN バックアップ対象受入明細（標準）取得（lr_header_rec．受入ヘッダID） LOOP
       */
      << archive_rcv_line_loop >>
      FOR lr_line_rec IN archive_rcv_line_cur(
                           lr_header_rec.shipment_header_id
                         )
      LOOP
        /*
        ln_未コミットバックアップ件数（受入明細（標準）） := ln_未コミットバックアップ件数（受入明細（標準）） + 1;
        l_受入明細（標準）テーブル（ln_未コミットバックアップ件数（受入明細（標準）） := lr_line_rec;
         */
        ln_arc_cnt_line_yet := ln_arc_cnt_line_yet + 1;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).shipment_line_id             :=lr_line_rec.shipment_line_id;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).last_update_date             :=lr_line_rec.last_update_date;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).last_updated_by              :=lr_line_rec.last_updated_by;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).creation_date                :=lr_line_rec.creation_date;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).created_by                   :=lr_line_rec.created_by;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).last_update_login            :=lr_line_rec.last_update_login;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).shipment_header_id           :=lr_line_rec.shipment_header_id;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).line_num                     :=lr_line_rec.line_num;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).category_id                  :=lr_line_rec.category_id;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).quantity_shipped             :=lr_line_rec.quantity_shipped;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).quantity_received            :=lr_line_rec.quantity_received;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).unit_of_measure              :=lr_line_rec.unit_of_measure;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).item_description             :=lr_line_rec.item_description;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).item_id                      :=lr_line_rec.item_id;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).item_revision                :=lr_line_rec.item_revision;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).vendor_item_num              :=lr_line_rec.vendor_item_num;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).vendor_lot_num               :=lr_line_rec.vendor_lot_num;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).uom_conversion_rate          :=lr_line_rec.uom_conversion_rate;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).shipment_line_status_code    :=lr_line_rec.shipment_line_status_code;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).source_document_code         :=lr_line_rec.source_document_code;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).po_header_id                 :=lr_line_rec.po_header_id;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).po_release_id                :=lr_line_rec.po_release_id;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).po_line_id                   :=lr_line_rec.po_line_id;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).po_line_location_id          :=lr_line_rec.po_line_location_id;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).po_distribution_id           :=lr_line_rec.po_distribution_id;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).requisition_line_id          :=lr_line_rec.requisition_line_id;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).req_distribution_id          :=lr_line_rec.req_distribution_id;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).routing_header_id            :=lr_line_rec.routing_header_id;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).packing_slip                 :=lr_line_rec.packing_slip;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).from_organization_id         :=lr_line_rec.from_organization_id;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).deliver_to_person_id         :=lr_line_rec.deliver_to_person_id;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).employee_id                  :=lr_line_rec.employee_id;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).destination_type_code        :=lr_line_rec.destination_type_code;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).to_organization_id           :=lr_line_rec.to_organization_id;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).to_subinventory              :=lr_line_rec.to_subinventory;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).locator_id                   :=lr_line_rec.locator_id;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).deliver_to_location_id       :=lr_line_rec.deliver_to_location_id;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).charge_account_id            :=lr_line_rec.charge_account_id;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).transportation_account_id    :=lr_line_rec.transportation_account_id;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).shipment_unit_price          :=lr_line_rec.shipment_unit_price;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).transfer_cost                :=lr_line_rec.transfer_cost;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).transportation_cost          :=lr_line_rec.transportation_cost;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).comments                     :=lr_line_rec.comments;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).attribute_category           :=lr_line_rec.attribute_category;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).attribute1                   :=lr_line_rec.attribute1;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).attribute2                   :=lr_line_rec.attribute2;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).attribute3                   :=lr_line_rec.attribute3;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).attribute4                   :=lr_line_rec.attribute4;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).attribute5                   :=lr_line_rec.attribute5;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).attribute6                   :=lr_line_rec.attribute6;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).attribute7                   :=lr_line_rec.attribute7;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).attribute8                   :=lr_line_rec.attribute8;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).attribute9                   :=lr_line_rec.attribute9;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).attribute10                  :=lr_line_rec.attribute10;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).attribute11                  :=lr_line_rec.attribute11;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).attribute12                  :=lr_line_rec.attribute12;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).attribute13                  :=lr_line_rec.attribute13;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).attribute14                  :=lr_line_rec.attribute14;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).attribute15                  :=lr_line_rec.attribute15;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).reason_id                    :=lr_line_rec.reason_id;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).ussgl_transaction_code       :=lr_line_rec.ussgl_transaction_code;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).government_context           :=lr_line_rec.government_context;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).request_id                   :=lr_line_rec.request_id;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).program_application_id       :=lr_line_rec.program_application_id;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).program_id                   :=lr_line_rec.program_id;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).program_update_date          :=lr_line_rec.program_update_date;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).destination_context          :=lr_line_rec.destination_context;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).primary_unit_of_measure      :=lr_line_rec.primary_unit_of_measure;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).excess_transport_reason      :=lr_line_rec.excess_transport_reason;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).excess_transport_responsible :=lr_line_rec.excess_transport_responsible;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).excess_transport_auth_num    :=lr_line_rec.excess_transport_auth_num;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).asn_line_flag                :=lr_line_rec.asn_line_flag;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).original_asn_parent_line_id  :=lr_line_rec.original_asn_parent_line_id;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).original_asn_line_flag       :=lr_line_rec.original_asn_line_flag;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).vendor_cum_shipped_quantity  :=lr_line_rec.vendor_cum_shipped_quantity;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).notice_unit_price            :=lr_line_rec.notice_unit_price;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).tax_name                     :=lr_line_rec.tax_name;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).tax_amount                   :=lr_line_rec.tax_amount;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).invoice_status_code          :=lr_line_rec.invoice_status_code;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).cum_comparison_flag          :=lr_line_rec.cum_comparison_flag;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).container_num                :=lr_line_rec.container_num;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).truck_num                    :=lr_line_rec.truck_num;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).bar_code_label               :=lr_line_rec.bar_code_label;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).transfer_percentage          :=lr_line_rec.transfer_percentage;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).mrc_shipment_unit_price      :=lr_line_rec.mrc_shipment_unit_price;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).mrc_transfer_cost            :=lr_line_rec.mrc_transfer_cost;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).mrc_transportation_cost      :=lr_line_rec.mrc_transportation_cost;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).mrc_notice_unit_price        :=lr_line_rec.mrc_notice_unit_price;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).ship_to_location_id          :=lr_line_rec.ship_to_location_id;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).country_of_origin_code       :=lr_line_rec.country_of_origin_code;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).oe_order_header_id           :=lr_line_rec.oe_order_header_id;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).oe_order_line_id             :=lr_line_rec.oe_order_line_id;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).customer_item_num            :=lr_line_rec.customer_item_num;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).cost_group_id                :=lr_line_rec.cost_group_id;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).secondary_quantity_shipped   :=lr_line_rec.secondary_quantity_shipped;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).secondary_quantity_received  :=lr_line_rec.secondary_quantity_received;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).secondary_unit_of_measure    :=lr_line_rec.secondary_unit_of_measure;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).qc_grade                     :=lr_line_rec.qc_grade;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).mmt_transaction_id           :=lr_line_rec.mmt_transaction_id;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).asn_lpn_id                   :=lr_line_rec.asn_lpn_id;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).amount                       :=lr_line_rec.amount;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).amount_received              :=lr_line_rec.amount_received;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).job_id                       :=lr_line_rec.job_id;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).timecard_id                  :=lr_line_rec.timecard_id;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).timecard_ovn                 :=lr_line_rec.timecard_ovn;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).archive_date                 :=sysdate;
        l_rcv_line_tbl(ln_arc_cnt_line_yet).archive_request_id           :=cn_request_id;
--
      END LOOP archive_rcv_line_loop;
--
      -- ===============================================
      -- バックアップ対象受入取引（標準）取得
      -- ===============================================
      /*
      FOR lr_trx_rec IN バックアップ対象受入取引（標準）取得（lr_header_rec．受入ヘッダID） LOOP
       */
      << archive_rcv_trx_loop >>
      FOR lr_trx_rec IN archive_rcv_trx_cur(
                           lr_header_rec.shipment_header_id
                         )
      LOOP
--
        /*
        ln_未コミットバックアップ件数（受入取引（標準）） := ln_未コミットバックアップ件数（受入取引（標準）） + 1;
        l_受入取引（標準）テーブル（ln_未コミットバックアップ件数（受入取引（標準）） := lr_trx_rec;
        */
        ln_arc_cnt_trx_yet := ln_arc_cnt_trx_yet + 1;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).transaction_id                  :=lr_trx_rec.transaction_id;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).last_update_date                :=lr_trx_rec.last_update_date;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).last_updated_by                 :=lr_trx_rec.last_updated_by;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).creation_date                   :=lr_trx_rec.creation_date;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).created_by                      :=lr_trx_rec.created_by;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).last_update_login               :=lr_trx_rec.last_update_login;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).request_id                      :=lr_trx_rec.request_id;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).program_application_id          :=lr_trx_rec.program_application_id;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).program_id                      :=lr_trx_rec.program_id;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).program_update_date             :=lr_trx_rec.program_update_date;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).transaction_type                :=lr_trx_rec.transaction_type;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).transaction_date                :=lr_trx_rec.transaction_date;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).quantity                        :=lr_trx_rec.quantity;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).unit_of_measure                 :=lr_trx_rec.unit_of_measure;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).shipment_header_id              :=lr_trx_rec.shipment_header_id;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).shipment_line_id                :=lr_trx_rec.shipment_line_id;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).user_entered_flag               :=lr_trx_rec.user_entered_flag;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).interface_source_code           :=lr_trx_rec.interface_source_code;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).interface_source_line_id        :=lr_trx_rec.interface_source_line_id;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).inv_transaction_id              :=lr_trx_rec.inv_transaction_id;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).source_document_code            :=lr_trx_rec.source_document_code;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).destination_type_code           :=lr_trx_rec.destination_type_code;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).primary_quantity                :=lr_trx_rec.primary_quantity;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).primary_unit_of_measure         :=lr_trx_rec.primary_unit_of_measure;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).uom_code                        :=lr_trx_rec.uom_code;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).employee_id                     :=lr_trx_rec.employee_id;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).parent_transaction_id           :=lr_trx_rec.parent_transaction_id;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).po_header_id                    :=lr_trx_rec.po_header_id;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).po_release_id                   :=lr_trx_rec.po_release_id;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).po_line_id                      :=lr_trx_rec.po_line_id;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).po_line_location_id             :=lr_trx_rec.po_line_location_id;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).po_distribution_id              :=lr_trx_rec.po_distribution_id;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).po_revision_num                 :=lr_trx_rec.po_revision_num;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).requisition_line_id             :=lr_trx_rec.requisition_line_id;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).po_unit_price                   :=lr_trx_rec.po_unit_price;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).currency_code                   :=lr_trx_rec.currency_code;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).currency_conversion_type        :=lr_trx_rec.currency_conversion_type;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).currency_conversion_rate        :=lr_trx_rec.currency_conversion_rate;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).currency_conversion_date        :=lr_trx_rec.currency_conversion_date;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).routing_header_id               :=lr_trx_rec.routing_header_id;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).routing_step_id                 :=lr_trx_rec.routing_step_id;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).deliver_to_person_id            :=lr_trx_rec.deliver_to_person_id;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).deliver_to_location_id          :=lr_trx_rec.deliver_to_location_id;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).vendor_id                       :=lr_trx_rec.vendor_id;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).vendor_site_id                  :=lr_trx_rec.vendor_site_id;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).organization_id                 :=lr_trx_rec.organization_id;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).subinventory                    :=lr_trx_rec.subinventory;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).locator_id                      :=lr_trx_rec.locator_id;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).wip_entity_id                   :=lr_trx_rec.wip_entity_id;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).wip_line_id                     :=lr_trx_rec.wip_line_id;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).wip_repetitive_schedule_id      :=lr_trx_rec.wip_repetitive_schedule_id;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).wip_operation_seq_num           :=lr_trx_rec.wip_operation_seq_num;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).wip_resource_seq_num            :=lr_trx_rec.wip_resource_seq_num;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).bom_resource_id                 :=lr_trx_rec.bom_resource_id;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).location_id                     :=lr_trx_rec.location_id;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).substitute_unordered_code       :=lr_trx_rec.substitute_unordered_code;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).receipt_exception_flag          :=lr_trx_rec.receipt_exception_flag;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).inspection_status_code          :=lr_trx_rec.inspection_status_code;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).accrual_status_code             :=lr_trx_rec.accrual_status_code;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).inspection_quality_code         :=lr_trx_rec.inspection_quality_code;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).vendor_lot_num                  :=lr_trx_rec.vendor_lot_num;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).rma_reference                   :=lr_trx_rec.rma_reference;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).comments                        :=lr_trx_rec.comments;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).attribute_category              :=lr_trx_rec.attribute_category;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).attribute1                      :=lr_trx_rec.attribute1;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).attribute2                      :=lr_trx_rec.attribute2;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).attribute3                      :=lr_trx_rec.attribute3;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).attribute4                      :=lr_trx_rec.attribute4;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).attribute5                      :=lr_trx_rec.attribute5;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).attribute6                      :=lr_trx_rec.attribute6;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).attribute7                      :=lr_trx_rec.attribute7;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).attribute8                      :=lr_trx_rec.attribute8;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).attribute9                      :=lr_trx_rec.attribute9;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).attribute10                     :=lr_trx_rec.attribute10;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).attribute11                     :=lr_trx_rec.attribute11;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).attribute12                     :=lr_trx_rec.attribute12;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).attribute13                     :=lr_trx_rec.attribute13;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).attribute14                     :=lr_trx_rec.attribute14;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).attribute15                     :=lr_trx_rec.attribute15;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).req_distribution_id             :=lr_trx_rec.req_distribution_id;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).department_code                 :=lr_trx_rec.department_code;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).reason_id                       :=lr_trx_rec.reason_id;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).destination_context             :=lr_trx_rec.destination_context;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).locator_attribute               :=lr_trx_rec.locator_attribute;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).child_inspection_flag           :=lr_trx_rec.child_inspection_flag;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).source_doc_unit_of_measure      :=lr_trx_rec.source_doc_unit_of_measure;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).source_doc_quantity             :=lr_trx_rec.source_doc_quantity;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).interface_transaction_id        :=lr_trx_rec.interface_transaction_id;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).group_id                        :=lr_trx_rec.group_id;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).movement_id                     :=lr_trx_rec.movement_id;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).invoice_id                      :=lr_trx_rec.invoice_id;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).invoice_status_code             :=lr_trx_rec.invoice_status_code;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).qa_collection_id                :=lr_trx_rec.qa_collection_id;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).mrc_currency_conversion_type    :=lr_trx_rec.mrc_currency_conversion_type;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).mrc_currency_conversion_date    :=lr_trx_rec.mrc_currency_conversion_date;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).mrc_currency_conversion_rate    :=lr_trx_rec.mrc_currency_conversion_rate;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).country_of_origin_code          :=lr_trx_rec.country_of_origin_code;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).mvt_stat_status                 :=lr_trx_rec.mvt_stat_status;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).quantity_billed                 :=lr_trx_rec.quantity_billed;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).match_flag                      :=lr_trx_rec.match_flag;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).amount_billed                   :=lr_trx_rec.amount_billed;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).match_option                    :=lr_trx_rec.match_option;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).oe_order_header_id              :=lr_trx_rec.oe_order_header_id;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).oe_order_line_id                :=lr_trx_rec.oe_order_line_id;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).customer_id                     :=lr_trx_rec.customer_id;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).customer_site_id                :=lr_trx_rec.customer_site_id;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).lpn_id                          :=lr_trx_rec.lpn_id;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).transfer_lpn_id                 :=lr_trx_rec.transfer_lpn_id;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).mobile_txn                      :=lr_trx_rec.mobile_txn;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).secondary_quantity              :=lr_trx_rec.secondary_quantity;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).secondary_unit_of_measure       :=lr_trx_rec.secondary_unit_of_measure;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).qc_grade                        :=lr_trx_rec.qc_grade;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).secondary_uom_code              :=lr_trx_rec.secondary_uom_code;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).pa_addition_flag                :=lr_trx_rec.pa_addition_flag;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).consigned_flag                  :=lr_trx_rec.consigned_flag;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).source_transaction_num          :=lr_trx_rec.source_transaction_num;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).from_subinventory               :=lr_trx_rec.from_subinventory;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).from_locator_id                 :=lr_trx_rec.from_locator_id;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).amount                          :=lr_trx_rec.amount;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).dropship_type_code              :=lr_trx_rec.dropship_type_code;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).lpn_group_id                    :=lr_trx_rec.lpn_group_id;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).job_id                          :=lr_trx_rec.job_id;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).timecard_id                     :=lr_trx_rec.timecard_id;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).timecard_ovn                    :=lr_trx_rec.timecard_ovn;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).project_id                      :=lr_trx_rec.project_id;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).task_id                         :=lr_trx_rec.task_id;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).archive_date                    :=sysdate;
        l_rcv_trx_tbl(ln_arc_cnt_trx_yet).archive_request_id              :=cn_request_id;
--
      END LOOP archive_rcv_trx_loop;
--
      /*
      ln_未コミットバックアップ件数（受入ヘッダ（標準）） := ln_未コミットバックアップ件数（受入ヘッダ（標準）） + 1;
      l_受入ヘッダ（標準）テーブル（ln_未コミットバックアップ件数（受入ヘッダ（標準）） := lr_header_rec;
       */
      ln_arc_cnt_header_yet := ln_arc_cnt_header_yet + 1;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).shipment_header_id       :=lr_header_rec.shipment_header_id;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).last_update_date         :=lr_header_rec.last_update_date;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).last_updated_by          :=lr_header_rec.last_updated_by;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).creation_date            :=lr_header_rec.creation_date;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).created_by               :=lr_header_rec.created_by;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).last_update_login        :=lr_header_rec.last_update_login;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).receipt_source_code      :=lr_header_rec.receipt_source_code;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).vendor_id                :=lr_header_rec.vendor_id;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).vendor_site_id           :=lr_header_rec.vendor_site_id;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).organization_id          :=lr_header_rec.organization_id;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).shipment_num             :=lr_header_rec.shipment_num;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).receipt_num              :=lr_header_rec.receipt_num;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).ship_to_location_id      :=lr_header_rec.ship_to_location_id;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).bill_of_lading           :=lr_header_rec.bill_of_lading;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).packing_slip             :=lr_header_rec.packing_slip;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).shipped_date             :=lr_header_rec.shipped_date;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).freight_carrier_code     :=lr_header_rec.freight_carrier_code;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).expected_receipt_date    :=lr_header_rec.expected_receipt_date;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).employee_id              :=lr_header_rec.employee_id;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).num_of_containers        :=lr_header_rec.num_of_containers;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).waybill_airbill_num      :=lr_header_rec.waybill_airbill_num;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).comments                 :=lr_header_rec.comments;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).attribute_category       :=lr_header_rec.attribute_category;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).attribute1               :=lr_header_rec.attribute1;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).attribute2               :=lr_header_rec.attribute2;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).attribute3               :=lr_header_rec.attribute3;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).attribute4               :=lr_header_rec.attribute4;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).attribute5               :=lr_header_rec.attribute5;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).attribute6               :=lr_header_rec.attribute6;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).attribute7               :=lr_header_rec.attribute7;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).attribute8               :=lr_header_rec.attribute8;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).attribute9               :=lr_header_rec.attribute9;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).attribute10              :=lr_header_rec.attribute10;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).attribute11              :=lr_header_rec.attribute11;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).attribute12              :=lr_header_rec.attribute12;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).attribute13              :=lr_header_rec.attribute13;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).attribute14              :=lr_header_rec.attribute14;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).attribute15              :=lr_header_rec.attribute15;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).ussgl_transaction_code   :=lr_header_rec.ussgl_transaction_code;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).government_context       :=lr_header_rec.government_context;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).request_id               :=lr_header_rec.request_id;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).program_application_id   :=lr_header_rec.program_application_id;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).program_id               :=lr_header_rec.program_id;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).program_update_date      :=lr_header_rec.program_update_date;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).asn_type                 :=lr_header_rec.asn_type;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).edi_control_num          :=lr_header_rec.edi_control_num;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).notice_creation_date     :=lr_header_rec.notice_creation_date;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).gross_weight             :=lr_header_rec.gross_weight;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).gross_weight_uom_code    :=lr_header_rec.gross_weight_uom_code;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).net_weight               :=lr_header_rec.net_weight;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).net_weight_uom_code      :=lr_header_rec.net_weight_uom_code;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).tar_weight               :=lr_header_rec.tar_weight;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).tar_weight_uom_code      :=lr_header_rec.tar_weight_uom_code;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).packaging_code           :=lr_header_rec.packaging_code;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).carrier_method           :=lr_header_rec.carrier_method;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).carrier_equipment        :=lr_header_rec.carrier_equipment;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).carrier_equipment_num    :=lr_header_rec.carrier_equipment_num;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).carrier_equipment_alpha  :=lr_header_rec.carrier_equipment_alpha;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).special_handling_code    :=lr_header_rec.special_handling_code;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).hazard_code              :=lr_header_rec.hazard_code;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).hazard_class             :=lr_header_rec.hazard_class;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).hazard_description       :=lr_header_rec.hazard_description;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).freight_terms            :=lr_header_rec.freight_terms;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).freight_bill_number      :=lr_header_rec.freight_bill_number;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).invoice_num              :=lr_header_rec.invoice_num;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).invoice_date             :=lr_header_rec.invoice_date;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).invoice_amount           :=lr_header_rec.invoice_amount;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).tax_name                 :=lr_header_rec.tax_name;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).tax_amount               :=lr_header_rec.tax_amount;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).freight_amount           :=lr_header_rec.freight_amount;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).invoice_status_code      :=lr_header_rec.invoice_status_code;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).asn_status               :=lr_header_rec.asn_status;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).currency_code            :=lr_header_rec.currency_code;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).conversion_rate_type     :=lr_header_rec.conversion_rate_type;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).conversion_rate          :=lr_header_rec.conversion_rate;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).conversion_date          :=lr_header_rec.conversion_date;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).payment_terms_id         :=lr_header_rec.payment_terms_id;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).mrc_conversion_rate_type :=lr_header_rec.mrc_conversion_rate_type;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).mrc_conversion_date      :=lr_header_rec.mrc_conversion_date;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).mrc_conversion_rate      :=lr_header_rec.mrc_conversion_rate;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).ship_to_org_id           :=lr_header_rec.ship_to_org_id;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).customer_id              :=lr_header_rec.customer_id;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).customer_site_id         :=lr_header_rec.customer_site_id;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).remit_to_site_id         :=lr_header_rec.remit_to_site_id;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).archive_date             :=sysdate;
      l_rcv_header_tbl(ln_arc_cnt_header_yet).archive_request_id       :=cn_request_id;
--
    END LOOP archive_rcv_header_loop;
--
    /*
    FORALL ln_idx IN 1..ln_未コミットバックアップ件数（受入ヘッダ（標準））
      INSERT INTO 受入ヘッダ（標準）バックアップ
      (
           全カラム
        , バックアップ登録日
        , バックアップ要求ID
      )
      VALUES
      (
          lt_受入ヘッダ（標準）テーブル（ln_idx）全カラム
        , SYSDATE
        , 要求ID
      )
     */
    lv_process_part := '受入ヘッダ（標準）登録２';
    FORALL ln_idx IN 1..ln_arc_cnt_header_yet
      INSERT INTO xxcmn_rcv_shipment_headers_arc VALUES l_rcv_header_tbl(ln_idx);
--
    /*
    l_受入ヘッダ（標準）テーブル．DELETE;
     */
    l_rcv_header_tbl.DELETE;
--
    /*
    FORALL ln_idx IN 1..ln_未コミットバックアップ件数（受入明細（標準））
      INSERT INTO 受入明細（標準）バックアップ
      (
          全カラム
        , バックアップ登録日
        , バックアップ要求ID
      )
      VALUES
      (
          l_受入明細（標準）テーブル（ln_idx）全カラム
        , SYSDATE
        , 要求ID
      )
     */
    lv_process_part := '受入明細（標準）登録２';
    FORALL ln_idx IN 1..ln_arc_cnt_line_yet
      INSERT INTO xxcmn_rcv_shipment_lines_arc VALUES l_rcv_line_tbl(ln_idx);
--
    /*
    l_受入明細（標準）テーブル．DELETE;
     */
    l_rcv_line_tbl.DELETE;
--
    /*
    FORALL ln_idx IN 1..ln_未コミットバックアップ件数（受入取引（標準））
      INSERT INTO 受入取引（標準）バックアップ
      (
          全カラム
        , バックアップ登録日
        , バックアップ要求ID
      )
      VALUES
      (
          l_受入取引（標準）テーブル（ln_idx）全カラム
        , SYSDATE
        , 要求ID
      )
    ;
    */
    lv_process_part := '受入取引（標準）登録２';
    FORALL ln_idx IN 1..ln_arc_cnt_trx_yet
      INSERT INTO xxcmn_rcv_transactions_arc VALUES l_rcv_trx_tbl(ln_idx);
--
    /*
    l_受入ヘッダ（標準）テーブル．DELETE;
    */
    l_rcv_trx_tbl.DELETE;
--
    /*
    ln_バックアップ件数（受入ヘッダ（標準）） := ln_バックアップ件数（受入ヘッダ（標準）） + ln_未コミットバックアップ件数（受入ヘッダ（標準））;
    ln_未コミットバックアップ件数（受入ヘッダ（標準）） := 0;
    */
    gn_arc_cnt_header     := gn_arc_cnt_header + ln_arc_cnt_header_yet;
    ln_arc_cnt_header_yet := 0;
--
    /*
    ln_バックアップ件数（受入明細（標準）） := ln_バックアップ件数（受入明細（標準）） + ln_未コミットバックアップ件数（受入明細（標準））;
    ln_未コミットバックアップ件数（受入明細（標準）） := 0;
    */
    gn_arc_cnt_line       := gn_arc_cnt_line + ln_arc_cnt_line_yet;
    ln_arc_cnt_line_yet   := 0;
--
    /*
    ln_バックアップ件数（受入取引（標準）） := ln_バックアップ件数（受入取引（標準）） + ln_未コミットバックアップ件数（受入取引（標準））;
    ln_未コミットバックアップ件数（受入取引（標準）） := 0;
    */
    gn_arc_cnt_trx        := gn_arc_cnt_trx + ln_arc_cnt_trx_yet;
    ln_arc_cnt_trx_yet    := 0;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
    WHEN local_process_expt THEN
      NULL;
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
      BEGIN
        IF ( SQL%BULK_EXCEPTIONS.COUNT > 0 ) THEN
--  
          IF ( l_rcv_header_tbl.COUNT > 0 ) THEN
            lt_shipment_header_id := l_rcv_header_tbl(SQL%BULK_EXCEPTIONS(1).ERROR_INDEX).shipment_header_id;
            ov_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name
                          ,iv_name         => cv_local_others_hdr_msg
                          ,iv_token_name1  => cv_token_key
                          ,iv_token_value1 => TO_CHAR(lt_shipment_header_id)
                         );
          ELSIF ( l_rcv_line_tbl.COUNT > 0 ) THEN
            lt_shipment_line_id := l_rcv_line_tbl(SQL%BULK_EXCEPTIONS(1).ERROR_INDEX).shipment_line_id;
            ov_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name
                          ,iv_name         => cv_local_others_line_msg
                          ,iv_token_name1  => cv_token_key
                          ,iv_token_value1 => TO_CHAR(lt_shipment_line_id)
                         );
          ELSIF ( l_rcv_trx_tbl.COUNT > 0 ) THEN
            lt_transaction_id := l_rcv_trx_tbl(SQL%BULK_EXCEPTIONS(1).ERROR_INDEX).transaction_id;
            ov_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name
                          ,iv_name         => cv_local_others_tran_msg
                          ,iv_token_name1  => cv_token_key
                          ,iv_token_value1 => TO_CHAR(lt_transaction_id)
                         );
          END IF;
        END IF;
      EXCEPTION
        WHEN not_init_collection_expt THEN
          NULL;
      END;
--
      IF ( (ov_errmsg IS NULL) AND (lt_shipment_header_id IS NOT NULL) ) THEN
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_local_others_hdr_msg
                      ,iv_token_name1  => cv_token_key
                      ,iv_token_value1 => TO_CHAR(lt_shipment_header_id)
                     );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_process_part||cv_msg_part||SQLERRM;
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
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_proc_date  IN  VARCHAR2       --   1.処理日
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
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCMN-00010';  -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'CNT';              -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
--
    cv_par_token       CONSTANT VARCHAR2(10)  := 'PAR';              -- 処理日メッセージ用トークン名
    cv_proc_date_msg   CONSTANT VARCHAR2(100) := 'APP-XXCMN-11014';  -- 処理日： ＆PAR
    cv_normal_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCMN-11009';  -- 正常件数メッセージ
    --TBL_NAME SHORI 件数： CNT 件
    cv_end_msg         CONSTANT VARCHAR2(100) := 'APP-XXCMN-11040';          --処理内容出力
    cv_token_tblname   CONSTANT VARCHAR2(10)  := 'TBL_NAME';
    cv_tblname_head    CONSTANT VARCHAR2(100) := '受入ヘッダ(標準)';
    cv_tblname_line    CONSTANT VARCHAR2(100) := '受入明細(標準)';
    cv_tblname_trx     CONSTANT VARCHAR2(100) := '受入取引(標準)';
    cv_token_shori     CONSTANT VARCHAR2(10)  := 'SHORI';
    cv_shori           CONSTANT VARCHAR2(50)  := 'バックアップ';
--
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
    --処理日出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_proc_date_msg
                    ,iv_token_name1  => cv_par_token
                    ,iv_token_value1 => iv_proc_date
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_proc_date -- 1.処理日
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー時対応
    IF ( lv_retcode = cv_status_error ) THEN
      gn_error_cnt := 1;
    END IF;
--
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --バックアップ件数(受入ヘッダ(標準))出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_end_msg
                    ,iv_token_name1  => cv_token_tblname
                    ,iv_token_value1 => cv_tblname_head
                    ,iv_token_name2  => cv_token_shori
                    ,iv_token_value2 => cv_shori
                    ,iv_token_name3  => cv_cnt_token
                    ,iv_token_value3 => TO_CHAR(gn_arc_cnt_header)
                    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --バックアップ件数(受入明細(標準))出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_end_msg
                    ,iv_token_name1  => cv_token_tblname
                    ,iv_token_value1 => cv_tblname_line
                    ,iv_token_name2  => cv_token_shori
                    ,iv_token_value2 => cv_shori
                    ,iv_token_name3  => cv_cnt_token
                    ,iv_token_value3 => TO_CHAR(gn_arc_cnt_line)
                    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --バックアップ件数(受入取引(標準))出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_end_msg
                    ,iv_token_name1  => cv_token_tblname
                    ,iv_token_value1 => cv_tblname_trx
                    ,iv_token_name2  => cv_token_shori
                    ,iv_token_value2 => cv_shori
                    ,iv_token_name3  => cv_cnt_token
                    ,iv_token_value3 => TO_CHAR(gn_arc_cnt_trx)
                    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --正常件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_normal_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_arc_cnt_header)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
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
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
--
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
END XXCMN960004C;
/
