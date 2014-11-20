CREATE OR REPLACE PACKAGE BODY XXCMN960003C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2012. All rights reserved.
 *
 * Package Name     : XXCMN960003C(body)
 * Description      : 受注（標準）バックアップ
 * MD.050           : T_MD050_BPO_96C_受注（標準）バックアップ
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
 *  2012/10/23   1.00  Megumu.Kitajima     新規作成
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
  gn_arc_cnt_header         NUMBER;                                           -- バックアップ件数（受注ヘッダ（標準））
  gn_arc_cnt_line           NUMBER;                                           -- バックアップ件数（受注明細（標準））
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
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCMN960003C';     -- パッケージ名
  cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCMN';            -- アドオン：マスタ・経理・共通領域
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  TYPE g_oe_order_header_ttype IS TABLE OF xxcmn_oe_order_headers_all_arc%ROWTYPE INDEX BY BINARY_INTEGER;
  TYPE g_oe_order_line_ttype   IS TABLE OF xxcmn_oe_order_lines_all_arc%ROWTYPE   INDEX BY BINARY_INTEGER;
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
    cv_purge_type             CONSTANT VARCHAR2(30) := '1';                   -- バックアップタイプ
    cv_purge_code             CONSTANT VARCHAR2(30) := '9601';                -- バックアップコード
    cv_date_format            CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';          -- 日付フォーマット
    cv_xxcmn_commit_range     CONSTANT VARCHAR2(30) := 'XXCMN_COMMIT_RANGE';  -- 分割コミット数
    cv_xxcmn_archive_range    CONSTANT VARCHAR2(30) := 'XXCMN_ARCHIVE_RANGE'; -- バックアップレンジ
    cv_mo_org_id              CONSTANT VARCHAR2(30) := 'ORG_ID';              -- MO：営業単位
    cv_shipping               CONSTANT VARCHAR2(2)  := '04';
    cv_sikyu                  CONSTANT VARCHAR2(2)  := '08';
    cv_closed                 CONSTANT VARCHAR2(10) := 'CLOSED';             -- 受注ステータス(クローズ)
    cv_get_priod_msg          CONSTANT VARCHAR2(100):= 'APP-XXCMN-11012';    -- バックアップ期間の取得に失敗しました。
    cv_get_profile_msg        CONSTANT VARCHAR2(100):= 'APP-XXCMN-10002';    -- プロファイル[ ＆NG_PROFILE ]の取得に
                                                                             -- 失敗しました。
    cv_local_others_hdr_msg   CONSTANT VARCHAR2(100):= 'APP-XXCMN-11013';    -- バックアップ処理に失敗しました。
                                                                         --【受注（標準）】受注ヘッダ標準ID： ＆KEY
    cv_local_others_line_msg  CONSTANT VARCHAR2(100):= 'APP-XXCMN-11031';    -- バックアップ処理に失敗しました。
                                                                         --【受注（標準）】受注明細標準ID： ＆KEY
    cv_token_key              CONSTANT VARCHAR2(10) := 'KEY';                --
    cv_token_profile          CONSTANT VARCHAR2(10) := 'NG_PROFILE';
--
    -- *** ローカル変数 ***
    ln_arc_cnt_header_yet     NUMBER DEFAULT 0;                     -- 未コミットバックアップ件数（受注ヘッダ（標準））
    ln_arc_cnt_line_yet       NUMBER DEFAULT 0;                     -- 未コミットバックアップ件数（受注明細（標準））
    ln_archive_period         NUMBER;                               -- バックアップ期間
    ln_archive_range          NUMBER;                               -- バックアップレンジ
    ld_standard_date          DATE;                                 -- 基準日
    ln_commit_range           NUMBER;                               -- 分割コミット数
    lt_org_id                 oe_order_headers_all.org_id%TYPE;     -- 営業単位ID
    lv_process_part           VARCHAR2(1000);                       -- 処理部
    lt_header_id              oe_order_headers_all.header_id%TYPE;  -- ヘッダーID
    lt_line_id                oe_order_lines_all.line_id%TYPE;      -- ラインID
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    /*
    -- 受注ヘッダ（標準）
    CURSOR バックアップ対象受注ヘッダ（標準）取得
      id_基準日  IN DATE
      in_バックアップレンジ IN NUMBER
      it_営業単位ID IN 受注ヘッダ（標準）．営業単位ID
    IS
      SELECT 
             受注ヘッダ（標準）全カラム
      FROM 受注ヘッダ（アドオン）
           ,    受注ヘッダ（標準）
      WHERE 受注ヘッダ（アドオン）．ステータス IN ('04','08')
      AND 受注ヘッダ（アドオン）．着荷日 >= id_基準日 - in_バックアップレンジ
      AND 受注ヘッダ（アドオン）．着荷日 < id_基準日
      AND 受注ヘッダ（標準）．受注ヘッダID = 受注ヘッダ（アドオン）．受注ヘッダID
      AND 受注ヘッダ（標準）．営業単位ID = it_営業単位ID
      AND 受注ヘッダ（標準）．ステータス = クローズ
      AND NOT EXISTS (
               SELECT 1
               FROM 受注ヘッダ（標準）バックアップ
               WHERE 受注ヘッダ（標準）バックアップ．受注ヘッダID = 受注ヘッダ（標準）．受注ヘッダID
               AND ROWNUM = 1
             )
      UNION ALL
      SELECT 
             受注ヘッダ（標準）全カラム
      FROM 受注ヘッダ（アドオン）
           ,    受注ヘッダ（標準）
      WHERE 受注ヘッダ（アドオン）．ステータス NOT IN ('04','08')
      AND 受注ヘッダ（アドオン）．着荷予定日 >= id_基準日 - in_バックアップレンジ
      AND 受注ヘッダ（アドオン）．着荷予定日 < id_基準日
      AND 受注ヘッダ（標準）．受注ヘッダID = 受注ヘッダ（アドオン）．受注ヘッダID
      AND 受注ヘッダ（標準）．営業単位ID = it_営業単位ID
      AND 受注ヘッダ（標準）．ステータス = クローズ
      AND NOT EXISTS (
               SELECT 1
               FROM 受注ヘッダ（標準）バックアップ
               WHERE 受注ヘッダ（標準）バックアップ．受注ヘッダID = 受注ヘッダ（標準）．受注ヘッダID
               AND ROWNUM = 1
             )
     */
    CURSOR archive_order_header_cur(
      id_standard_date           DATE
     ,in_archive_range           NUMBER
     ,it_org_id                  oe_order_headers_all.org_id%TYPE
    )
    IS
      SELECT  /*+ LEADING(xoha) USE_NL(xoha ooha) INDEX(xoha XXWSH_OH_N15 ooha OE_ORDER_HEADERS_U1) */
              ooha.header_id                      AS header_id                      
             ,ooha.org_id                         AS org_id                         
             ,ooha.order_type_id                  AS order_type_id                  
             ,ooha.order_number                   AS order_number                   
             ,ooha.version_number                 AS version_number                 
             ,ooha.expiration_date                AS expiration_date                
             ,ooha.order_source_id                AS order_source_id                
             ,ooha.source_document_type_id        AS source_document_type_id        
             ,ooha.orig_sys_document_ref          AS orig_sys_document_ref          
             ,ooha.source_document_id             AS source_document_id             
             ,ooha.ordered_date                   AS ordered_date                   
             ,ooha.request_date                   AS request_date                   
             ,ooha.pricing_date                   AS pricing_date                   
             ,ooha.shipment_priority_code         AS shipment_priority_code         
             ,ooha.demand_class_code              AS demand_class_code              
             ,ooha.price_list_id                  AS price_list_id                  
             ,ooha.tax_exempt_flag                AS tax_exempt_flag                
             ,ooha.tax_exempt_number              AS tax_exempt_number              
             ,ooha.tax_exempt_reason_code         AS tax_exempt_reason_code         
             ,ooha.conversion_rate                AS conversion_rate                
             ,ooha.conversion_type_code           AS conversion_type_code           
             ,ooha.conversion_rate_date           AS conversion_rate_date           
             ,ooha.partial_shipments_allowed      AS partial_shipments_allowed      
             ,ooha.ship_tolerance_above           AS ship_tolerance_above           
             ,ooha.ship_tolerance_below           AS ship_tolerance_below           
             ,ooha.transactional_curr_code        AS transactional_curr_code        
             ,ooha.agreement_id                   AS agreement_id                   
             ,ooha.tax_point_code                 AS tax_point_code                 
             ,ooha.cust_po_number                 AS cust_po_number                 
             ,ooha.invoicing_rule_id              AS invoicing_rule_id              
             ,ooha.accounting_rule_id             AS accounting_rule_id             
             ,ooha.payment_term_id                AS payment_term_id                
             ,ooha.shipping_method_code           AS shipping_method_code           
             ,ooha.freight_carrier_code           AS freight_carrier_code           
             ,ooha.fob_point_code                 AS fob_point_code                 
             ,ooha.freight_terms_code             AS freight_terms_code             
             ,ooha.sold_from_org_id               AS sold_from_org_id               
             ,ooha.sold_to_org_id                 AS sold_to_org_id                 
             ,ooha.ship_from_org_id               AS ship_from_org_id               
             ,ooha.ship_to_org_id                 AS ship_to_org_id                 
             ,ooha.invoice_to_org_id              AS invoice_to_org_id              
             ,ooha.deliver_to_org_id              AS deliver_to_org_id              
             ,ooha.sold_to_contact_id             AS sold_to_contact_id             
             ,ooha.ship_to_contact_id             AS ship_to_contact_id             
             ,ooha.invoice_to_contact_id          AS invoice_to_contact_id          
             ,ooha.deliver_to_contact_id          AS deliver_to_contact_id          
             ,ooha.creation_date                  AS creation_date                  
             ,ooha.created_by                     AS created_by                     
             ,ooha.last_updated_by                AS last_updated_by                
             ,ooha.last_update_date               AS last_update_date               
             ,ooha.last_update_login              AS last_update_login              
             ,ooha.program_application_id         AS program_application_id         
             ,ooha.program_id                     AS program_id                     
             ,ooha.program_update_date            AS program_update_date            
             ,ooha.request_id                     AS request_id                     
             ,ooha.context                        AS context                        
             ,ooha.attribute1                     AS attribute1                     
             ,ooha.attribute2                     AS attribute2                     
             ,ooha.attribute3                     AS attribute3                     
             ,ooha.attribute4                     AS attribute4                     
             ,ooha.attribute5                     AS attribute5                     
             ,ooha.attribute6                     AS attribute6                     
             ,ooha.attribute7                     AS attribute7                     
             ,ooha.attribute8                     AS attribute8                     
             ,ooha.attribute9                     AS attribute9                     
             ,ooha.attribute10                    AS attribute10                    
             ,ooha.attribute11                    AS attribute11                    
             ,ooha.attribute12                    AS attribute12                    
             ,ooha.attribute13                    AS attribute13                    
             ,ooha.attribute14                    AS attribute14                    
             ,ooha.attribute15                    AS attribute15                    
             ,ooha.global_attribute_category      AS global_attribute_category      
             ,ooha.global_attribute1              AS global_attribute1              
             ,ooha.global_attribute2              AS global_attribute2              
             ,ooha.global_attribute3              AS global_attribute3              
             ,ooha.global_attribute4              AS global_attribute4              
             ,ooha.global_attribute5              AS global_attribute5              
             ,ooha.global_attribute6              AS global_attribute6              
             ,ooha.global_attribute7              AS global_attribute7              
             ,ooha.global_attribute8              AS global_attribute8              
             ,ooha.global_attribute9              AS global_attribute9              
             ,ooha.global_attribute10             AS global_attribute10             
             ,ooha.global_attribute11             AS global_attribute11             
             ,ooha.global_attribute12             AS global_attribute12             
             ,ooha.global_attribute13             AS global_attribute13             
             ,ooha.global_attribute14             AS global_attribute14             
             ,ooha.global_attribute15             AS global_attribute15             
             ,ooha.global_attribute16             AS global_attribute16             
             ,ooha.global_attribute17             AS global_attribute17             
             ,ooha.global_attribute18             AS global_attribute18             
             ,ooha.global_attribute19             AS global_attribute19             
             ,ooha.global_attribute20             AS global_attribute20             
             ,ooha.cancelled_flag                 AS cancelled_flag                 
             ,ooha.open_flag                      AS open_flag                      
             ,ooha.booked_flag                    AS booked_flag                    
             ,ooha.salesrep_id                    AS salesrep_id                    
             ,ooha.return_reason_code             AS return_reason_code             
             ,ooha.order_date_type_code           AS order_date_type_code           
             ,ooha.earliest_schedule_limit        AS earliest_schedule_limit        
             ,ooha.latest_schedule_limit          AS latest_schedule_limit          
             ,ooha.payment_type_code              AS payment_type_code              
             ,ooha.payment_amount                 AS payment_amount                 
             ,ooha.check_number                   AS check_number                   
             ,ooha.credit_card_code               AS credit_card_code               
             ,ooha.credit_card_holder_name        AS credit_card_holder_name        
             ,ooha.credit_card_number             AS credit_card_number             
             ,ooha.credit_card_expiration_date    AS credit_card_expiration_date    
             ,ooha.credit_card_approval_code      AS credit_card_approval_code      
             ,ooha.sales_channel_code             AS sales_channel_code             
             ,ooha.first_ack_code                 AS first_ack_code                 
             ,ooha.first_ack_date                 AS first_ack_date                 
             ,ooha.last_ack_code                  AS last_ack_code                  
             ,ooha.last_ack_date                  AS last_ack_date                  
             ,ooha.order_category_code            AS order_category_code            
             ,ooha.change_sequence                AS change_sequence                
             ,ooha.drop_ship_flag                 AS drop_ship_flag                 
             ,ooha.customer_payment_term_id       AS customer_payment_term_id       
             ,ooha.shipping_instructions          AS shipping_instructions          
             ,ooha.packing_instructions           AS packing_instructions           
             ,ooha.tp_context                     AS tp_context                     
             ,ooha.tp_attribute1                  AS tp_attribute1                  
             ,ooha.tp_attribute2                  AS tp_attribute2                  
             ,ooha.tp_attribute3                  AS tp_attribute3                  
             ,ooha.tp_attribute4                  AS tp_attribute4                  
             ,ooha.tp_attribute5                  AS tp_attribute5                  
             ,ooha.tp_attribute6                  AS tp_attribute6                  
             ,ooha.tp_attribute7                  AS tp_attribute7                  
             ,ooha.tp_attribute8                  AS tp_attribute8                  
             ,ooha.tp_attribute9                  AS tp_attribute9                  
             ,ooha.tp_attribute10                 AS tp_attribute10                 
             ,ooha.tp_attribute11                 AS tp_attribute11                 
             ,ooha.tp_attribute12                 AS tp_attribute12                 
             ,ooha.tp_attribute13                 AS tp_attribute13                 
             ,ooha.tp_attribute14                 AS tp_attribute14                 
             ,ooha.tp_attribute15                 AS tp_attribute15                 
             ,ooha.flow_status_code               AS flow_status_code               
             ,ooha.marketing_source_code_id       AS marketing_source_code_id       
             ,ooha.credit_card_approval_date      AS credit_card_approval_date      
             ,ooha.upgraded_flag                  AS upgraded_flag                  
             ,ooha.customer_preference_set_code   AS customer_preference_set_code   
             ,ooha.booked_date                    AS booked_date                    
             ,ooha.lock_control                   AS lock_control                   
             ,ooha.price_request_code             AS price_request_code             
             ,ooha.batch_id                       AS batch_id                       
             ,ooha.xml_message_id                 AS xml_message_id                 
             ,ooha.accounting_rule_duration       AS accounting_rule_duration       
             ,ooha.attribute16                    AS attribute16                    
             ,ooha.attribute17                    AS attribute17                    
             ,ooha.attribute18                    AS attribute18                    
             ,ooha.attribute19                    AS attribute19                    
             ,ooha.attribute20                    AS attribute20                    
             ,ooha.blanket_number                 AS blanket_number                 
             ,ooha.sales_document_type_code       AS sales_document_type_code       
             ,ooha.sold_to_phone_id               AS sold_to_phone_id               
             ,ooha.fulfillment_set_name           AS fulfillment_set_name           
             ,ooha.line_set_name                  AS line_set_name                  
             ,ooha.default_fulfillment_set        AS default_fulfillment_set        
             ,ooha.transaction_phase_code         AS transaction_phase_code         
             ,ooha.sales_document_name            AS sales_document_name            
             ,ooha.quote_number                   AS quote_number                   
             ,ooha.quote_date                     AS quote_date                     
             ,ooha.user_status_code               AS user_status_code               
             ,ooha.draft_submitted_flag           AS draft_submitted_flag           
             ,ooha.source_document_version_number AS source_document_version_number 
             ,ooha.sold_to_site_use_id            AS sold_to_site_use_id            
             ,ooha.supplier_signature             AS supplier_signature             
             ,ooha.supplier_signature_date        AS supplier_signature_date        
             ,ooha.customer_signature             AS customer_signature             
             ,ooha.customer_signature_date        AS customer_signature_date        
             ,ooha.minisite_id                    AS minisite_id                    
             ,ooha.end_customer_id                AS end_customer_id                
             ,ooha.end_customer_contact_id        AS end_customer_contact_id        
             ,ooha.end_customer_site_use_id       AS end_customer_site_use_id       
             ,ooha.ib_owner                       AS ib_owner                       
             ,ooha.ib_current_location            AS ib_current_location            
             ,ooha.ib_installed_at_location       AS ib_installed_at_location       
             ,ooha.order_firmed_date              AS order_firmed_date              
      FROM    oe_order_headers_all     ooha
             ,xxwsh_order_headers_all  xoha
      WHERE   ooha.org_id         = it_org_id
      AND     ooha.header_id      = xoha.header_id
      AND     ooha.flow_status_code = cv_closed
      AND     xoha.arrival_date  >= id_standard_date - in_archive_range
      AND     xoha.arrival_date   < id_standard_date
      AND     xoha.req_status    IN (cv_shipping, cv_sikyu)
      AND     NOT EXISTS (
                SELECT  1
                FROM    xxcmn_oe_order_headers_all_arc  xoohaa
                WHERE   xoohaa.header_id = ooha.header_id
                AND     ROWNUM           = 1
              );
    /*
    -- 受注明細（標準）
    CURSOR バックアップ対象受注明細（標準）取得
      it_受注ヘッダＩＤ IN 受注ヘッダ（標準）．受注ヘッダＩＤ%TYPE
    IS
      SELECT
             受注明細（標準）全カラム
      FROM 受注明細（標準）
      WHERE 受注明細（標準）．受注ヘッダＩＤ = it_受注ヘッダＩＤ
     */
    CURSOR archive_order_line_cur(
      it_header_id               oe_order_headers_all.header_id%TYPE
    )
    IS
      SELECT  /*+ INDEX(oola OE_ORDER_LINES_N1) */
              oola.line_id                          AS line_id                       
             ,oola.org_id                           AS org_id                        
             ,oola.header_id                        AS header_id                     
             ,oola.line_type_id                     AS line_type_id                  
             ,oola.line_number                      AS line_number                   
             ,oola.ordered_item                     AS ordered_item                  
             ,oola.request_date                     AS request_date                  
             ,oola.promise_date                     AS promise_date                  
             ,oola.schedule_ship_date               AS schedule_ship_date            
             ,oola.order_quantity_uom               AS order_quantity_uom            
             ,oola.pricing_quantity                 AS pricing_quantity              
             ,oola.pricing_quantity_uom             AS pricing_quantity_uom          
             ,oola.cancelled_quantity               AS cancelled_quantity            
             ,oola.shipped_quantity                 AS shipped_quantity              
             ,oola.ordered_quantity                 AS ordered_quantity              
             ,oola.fulfilled_quantity               AS fulfilled_quantity            
             ,oola.shipping_quantity                AS shipping_quantity             
             ,oola.shipping_quantity_uom            AS shipping_quantity_uom         
             ,oola.delivery_lead_time               AS delivery_lead_time            
             ,oola.tax_exempt_flag                  AS tax_exempt_flag               
             ,oola.tax_exempt_number                AS tax_exempt_number             
             ,oola.tax_exempt_reason_code           AS tax_exempt_reason_code        
             ,oola.ship_from_org_id                 AS ship_from_org_id              
             ,oola.ship_to_org_id                   AS ship_to_org_id                
             ,oola.invoice_to_org_id                AS invoice_to_org_id             
             ,oola.deliver_to_org_id                AS deliver_to_org_id             
             ,oola.ship_to_contact_id               AS ship_to_contact_id            
             ,oola.deliver_to_contact_id            AS deliver_to_contact_id         
             ,oola.invoice_to_contact_id            AS invoice_to_contact_id         
             ,oola.intmed_ship_to_org_id            AS intmed_ship_to_org_id         
             ,oola.intmed_ship_to_contact_id        AS intmed_ship_to_contact_id     
             ,oola.sold_from_org_id                 AS sold_from_org_id              
             ,oola.sold_to_org_id                   AS sold_to_org_id                
             ,oola.cust_po_number                   AS cust_po_number                
             ,oola.ship_tolerance_above             AS ship_tolerance_above          
             ,oola.ship_tolerance_below             AS ship_tolerance_below          
             ,oola.demand_bucket_type_code          AS demand_bucket_type_code       
             ,oola.veh_cus_item_cum_key_id          AS veh_cus_item_cum_key_id       
             ,oola.rla_schedule_type_code           AS rla_schedule_type_code        
             ,oola.customer_dock_code               AS customer_dock_code            
             ,oola.customer_job                     AS customer_job                  
             ,oola.customer_production_line         AS customer_production_line      
             ,oola.cust_model_serial_number         AS cust_model_serial_number      
             ,oola.project_id                       AS project_id                    
             ,oola.task_id                          AS task_id                       
             ,oola.inventory_item_id                AS inventory_item_id             
             ,oola.tax_date                         AS tax_date                      
             ,oola.tax_code                         AS tax_code                      
             ,oola.tax_rate                         AS tax_rate                      
             ,oola.invoice_interface_status_code    AS invoice_interface_status_code 
             ,oola.demand_class_code                AS demand_class_code             
             ,oola.price_list_id                    AS price_list_id                 
             ,oola.pricing_date                     AS pricing_date                  
             ,oola.shipment_number                  AS shipment_number               
             ,oola.agreement_id                     AS agreement_id                  
             ,oola.shipment_priority_code           AS shipment_priority_code        
             ,oola.shipping_method_code             AS shipping_method_code          
             ,oola.freight_carrier_code             AS freight_carrier_code          
             ,oola.freight_terms_code               AS freight_terms_code            
             ,oola.fob_point_code                   AS fob_point_code                
             ,oola.tax_point_code                   AS tax_point_code                
             ,oola.payment_term_id                  AS payment_term_id               
             ,oola.invoicing_rule_id                AS invoicing_rule_id             
             ,oola.accounting_rule_id               AS accounting_rule_id            
             ,oola.source_document_type_id          AS source_document_type_id       
             ,oola.orig_sys_document_ref            AS orig_sys_document_ref         
             ,oola.source_document_id               AS source_document_id            
             ,oola.orig_sys_line_ref                AS orig_sys_line_ref             
             ,oola.source_document_line_id          AS source_document_line_id       
             ,oola.reference_line_id                AS reference_line_id             
             ,oola.reference_type                   AS reference_type                
             ,oola.reference_header_id              AS reference_header_id           
             ,oola.item_revision                    AS item_revision                 
             ,oola.unit_selling_price               AS unit_selling_price            
             ,oola.unit_list_price                  AS unit_list_price               
             ,oola.tax_value                        AS tax_value                     
             ,oola.context                          AS context                       
             ,oola.attribute1                       AS attribute1                    
             ,oola.attribute2                       AS attribute2                    
             ,oola.attribute3                       AS attribute3                    
             ,oola.attribute4                       AS attribute4                    
             ,oola.attribute5                       AS attribute5                    
             ,oola.attribute6                       AS attribute6                    
             ,oola.attribute7                       AS attribute7                    
             ,oola.attribute8                       AS attribute8                    
             ,oola.attribute9                       AS attribute9                    
             ,oola.attribute10                      AS attribute10                   
             ,oola.attribute11                      AS attribute11                   
             ,oola.attribute12                      AS attribute12                   
             ,oola.attribute13                      AS attribute13                   
             ,oola.attribute14                      AS attribute14                   
             ,oola.attribute15                      AS attribute15                   
             ,oola.global_attribute_category        AS global_attribute_category     
             ,oola.global_attribute1                AS global_attribute1             
             ,oola.global_attribute2                AS global_attribute2             
             ,oola.global_attribute3                AS global_attribute3             
             ,oola.global_attribute4                AS global_attribute4             
             ,oola.global_attribute5                AS global_attribute5             
             ,oola.global_attribute6                AS global_attribute6             
             ,oola.global_attribute7                AS global_attribute7             
             ,oola.global_attribute8                AS global_attribute8             
             ,oola.global_attribute9                AS global_attribute9             
             ,oola.global_attribute10               AS global_attribute10            
             ,oola.global_attribute11               AS global_attribute11            
             ,oola.global_attribute12               AS global_attribute12            
             ,oola.global_attribute13               AS global_attribute13            
             ,oola.global_attribute14               AS global_attribute14            
             ,oola.global_attribute15               AS global_attribute15            
             ,oola.global_attribute16               AS global_attribute16            
             ,oola.global_attribute17               AS global_attribute17            
             ,oola.global_attribute18               AS global_attribute18            
             ,oola.global_attribute19               AS global_attribute19            
             ,oola.global_attribute20               AS global_attribute20            
             ,oola.pricing_context                  AS pricing_context               
             ,oola.pricing_attribute1               AS pricing_attribute1            
             ,oola.pricing_attribute2               AS pricing_attribute2            
             ,oola.pricing_attribute3               AS pricing_attribute3            
             ,oola.pricing_attribute4               AS pricing_attribute4            
             ,oola.pricing_attribute5               AS pricing_attribute5            
             ,oola.pricing_attribute6               AS pricing_attribute6            
             ,oola.pricing_attribute7               AS pricing_attribute7            
             ,oola.pricing_attribute8               AS pricing_attribute8            
             ,oola.pricing_attribute9               AS pricing_attribute9            
             ,oola.pricing_attribute10              AS pricing_attribute10           
             ,oola.industry_context                 AS industry_context              
             ,oola.industry_attribute1              AS industry_attribute1           
             ,oola.industry_attribute2              AS industry_attribute2           
             ,oola.industry_attribute3              AS industry_attribute3           
             ,oola.industry_attribute4              AS industry_attribute4           
             ,oola.industry_attribute5              AS industry_attribute5           
             ,oola.industry_attribute6              AS industry_attribute6           
             ,oola.industry_attribute7              AS industry_attribute7           
             ,oola.industry_attribute8              AS industry_attribute8           
             ,oola.industry_attribute9              AS industry_attribute9           
             ,oola.industry_attribute10             AS industry_attribute10          
             ,oola.industry_attribute11             AS industry_attribute11          
             ,oola.industry_attribute13             AS industry_attribute13          
             ,oola.industry_attribute12             AS industry_attribute12          
             ,oola.industry_attribute14             AS industry_attribute14          
             ,oola.industry_attribute15             AS industry_attribute15          
             ,oola.industry_attribute16             AS industry_attribute16          
             ,oola.industry_attribute17             AS industry_attribute17          
             ,oola.industry_attribute18             AS industry_attribute18          
             ,oola.industry_attribute19             AS industry_attribute19          
             ,oola.industry_attribute20             AS industry_attribute20          
             ,oola.industry_attribute21             AS industry_attribute21          
             ,oola.industry_attribute22             AS industry_attribute22          
             ,oola.industry_attribute23             AS industry_attribute23          
             ,oola.industry_attribute24             AS industry_attribute24          
             ,oola.industry_attribute25             AS industry_attribute25          
             ,oola.industry_attribute26             AS industry_attribute26          
             ,oola.industry_attribute27             AS industry_attribute27          
             ,oola.industry_attribute28             AS industry_attribute28          
             ,oola.industry_attribute29             AS industry_attribute29          
             ,oola.industry_attribute30             AS industry_attribute30          
             ,oola.creation_date                    AS creation_date                 
             ,oola.created_by                       AS created_by                    
             ,oola.last_update_date                 AS last_update_date              
             ,oola.last_updated_by                  AS last_updated_by               
             ,oola.last_update_login                AS last_update_login             
             ,oola.program_application_id           AS program_application_id        
             ,oola.program_id                       AS program_id                    
             ,oola.program_update_date              AS program_update_date           
             ,oola.request_id                       AS request_id                    
             ,oola.top_model_line_id                AS top_model_line_id             
             ,oola.link_to_line_id                  AS link_to_line_id               
             ,oola.component_sequence_id            AS component_sequence_id         
             ,oola.component_code                   AS component_code                
             ,oola.config_display_sequence          AS config_display_sequence       
             ,oola.sort_order                       AS sort_order                    
             ,oola.item_type_code                   AS item_type_code                
             ,oola.option_number                    AS option_number                 
             ,oola.option_flag                      AS option_flag                   
             ,oola.dep_plan_required_flag           AS dep_plan_required_flag        
             ,oola.visible_demand_flag              AS visible_demand_flag           
             ,oola.line_category_code               AS line_category_code            
             ,oola.actual_shipment_date             AS actual_shipment_date          
             ,oola.customer_trx_line_id             AS customer_trx_line_id          
             ,oola.return_context                   AS return_context                
             ,oola.return_attribute1                AS return_attribute1             
             ,oola.return_attribute2                AS return_attribute2             
             ,oola.return_attribute3                AS return_attribute3             
             ,oola.return_attribute4                AS return_attribute4             
             ,oola.return_attribute5                AS return_attribute5             
             ,oola.return_attribute6                AS return_attribute6             
             ,oola.return_attribute7                AS return_attribute7             
             ,oola.return_attribute8                AS return_attribute8             
             ,oola.return_attribute9                AS return_attribute9             
             ,oola.return_attribute10               AS return_attribute10            
             ,oola.return_attribute11               AS return_attribute11            
             ,oola.return_attribute12               AS return_attribute12            
             ,oola.return_attribute13               AS return_attribute13            
             ,oola.return_attribute14               AS return_attribute14            
             ,oola.return_attribute15               AS return_attribute15            
             ,oola.actual_arrival_date              AS actual_arrival_date           
             ,oola.ato_line_id                      AS ato_line_id                   
             ,oola.auto_selected_quantity           AS auto_selected_quantity        
             ,oola.component_number                 AS component_number              
             ,oola.earliest_acceptable_date         AS earliest_acceptable_date      
             ,oola.explosion_date                   AS explosion_date                
             ,oola.latest_acceptable_date           AS latest_acceptable_date        
             ,oola.model_group_number               AS model_group_number            
             ,oola.schedule_arrival_date            AS schedule_arrival_date         
             ,oola.ship_model_complete_flag         AS ship_model_complete_flag      
             ,oola.schedule_status_code             AS schedule_status_code          
             ,oola.source_type_code                 AS source_type_code              
             ,oola.cancelled_flag                   AS cancelled_flag                
             ,oola.open_flag                        AS open_flag                     
             ,oola.booked_flag                      AS booked_flag                   
             ,oola.salesrep_id                      AS salesrep_id                   
             ,oola.return_reason_code               AS return_reason_code            
             ,oola.arrival_set_id                   AS arrival_set_id                
             ,oola.ship_set_id                      AS ship_set_id                   
             ,oola.split_from_line_id               AS split_from_line_id            
             ,oola.cust_production_seq_num          AS cust_production_seq_num       
             ,oola.authorized_to_ship_flag          AS authorized_to_ship_flag       
             ,oola.over_ship_reason_code            AS over_ship_reason_code         
             ,oola.over_ship_resolved_flag          AS over_ship_resolved_flag       
             ,oola.ordered_item_id                  AS ordered_item_id               
             ,oola.item_identifier_type             AS item_identifier_type          
             ,oola.configuration_id                 AS configuration_id              
             ,oola.commitment_id                    AS commitment_id                 
             ,oola.shipping_interfaced_flag         AS shipping_interfaced_flag      
             ,oola.credit_invoice_line_id           AS credit_invoice_line_id        
             ,oola.first_ack_code                   AS first_ack_code                
             ,oola.first_ack_date                   AS first_ack_date                
             ,oola.last_ack_code                    AS last_ack_code                 
             ,oola.last_ack_date                    AS last_ack_date                 
             ,oola.planning_priority                AS planning_priority             
             ,oola.order_source_id                  AS order_source_id               
             ,oola.orig_sys_shipment_ref            AS orig_sys_shipment_ref         
             ,oola.change_sequence                  AS change_sequence               
             ,oola.drop_ship_flag                   AS drop_ship_flag                
             ,oola.customer_line_number             AS customer_line_number          
             ,oola.customer_shipment_number         AS customer_shipment_number      
             ,oola.customer_item_net_price          AS customer_item_net_price       
             ,oola.customer_payment_term_id         AS customer_payment_term_id      
             ,oola.fulfilled_flag                   AS fulfilled_flag                
             ,oola.end_item_unit_number             AS end_item_unit_number          
             ,oola.config_header_id                 AS config_header_id              
             ,oola.config_rev_nbr                   AS config_rev_nbr                
             ,oola.mfg_component_sequence_id        AS mfg_component_sequence_id     
             ,oola.shipping_instructions            AS shipping_instructions         
             ,oola.packing_instructions             AS packing_instructions          
             ,oola.invoiced_quantity                AS invoiced_quantity             
             ,oola.reference_customer_trx_line_id   AS reference_customer_trx_line_id
             ,oola.split_by                         AS split_by                      
             ,oola.line_set_id                      AS line_set_id                   
             ,oola.service_txn_reason_code          AS service_txn_reason_code       
             ,oola.service_txn_comments             AS service_txn_comments          
             ,oola.service_duration                 AS service_duration              
             ,oola.service_start_date               AS service_start_date            
             ,oola.service_end_date                 AS service_end_date              
             ,oola.service_coterminate_flag         AS service_coterminate_flag      
             ,oola.unit_list_percent                AS unit_list_percent             
             ,oola.unit_selling_percent             AS unit_selling_percent          
             ,oola.unit_percent_base_price          AS unit_percent_base_price       
             ,oola.service_number                   AS service_number                
             ,oola.service_period                   AS service_period                
             ,oola.shippable_flag                   AS shippable_flag                
             ,oola.model_remnant_flag               AS model_remnant_flag            
             ,oola.re_source_flag                   AS re_source_flag                
             ,oola.flow_status_code                 AS flow_status_code              
             ,oola.tp_context                       AS tp_context                    
             ,oola.tp_attribute1                    AS tp_attribute1                 
             ,oola.tp_attribute2                    AS tp_attribute2                 
             ,oola.tp_attribute3                    AS tp_attribute3                 
             ,oola.tp_attribute4                    AS tp_attribute4                 
             ,oola.tp_attribute5                    AS tp_attribute5                 
             ,oola.tp_attribute6                    AS tp_attribute6                 
             ,oola.tp_attribute7                    AS tp_attribute7                 
             ,oola.tp_attribute8                    AS tp_attribute8                 
             ,oola.tp_attribute9                    AS tp_attribute9                 
             ,oola.tp_attribute10                   AS tp_attribute10                
             ,oola.tp_attribute11                   AS tp_attribute11                
             ,oola.tp_attribute12                   AS tp_attribute12                
             ,oola.tp_attribute13                   AS tp_attribute13                
             ,oola.tp_attribute14                   AS tp_attribute14                
             ,oola.tp_attribute15                   AS tp_attribute15                
             ,oola.fulfillment_method_code          AS fulfillment_method_code       
             ,oola.marketing_source_code_id         AS marketing_source_code_id      
             ,oola.service_reference_type_code      AS service_reference_type_code   
             ,oola.service_reference_line_id        AS service_reference_line_id     
             ,oola.service_reference_system_id      AS service_reference_system_id   
             ,oola.calculate_price_flag             AS calculate_price_flag          
             ,oola.upgraded_flag                    AS upgraded_flag                 
             ,oola.revenue_amount                   AS revenue_amount                
             ,oola.fulfillment_date                 AS fulfillment_date              
             ,oola.preferred_grade                  AS preferred_grade               
             ,oola.ordered_quantity2                AS ordered_quantity2             
             ,oola.ordered_quantity_uom2            AS ordered_quantity_uom2         
             ,oola.shipping_quantity2               AS shipping_quantity2            
             ,oola.cancelled_quantity2              AS cancelled_quantity2           
             ,oola.shipped_quantity2                AS shipped_quantity2             
             ,oola.shipping_quantity_uom2           AS shipping_quantity_uom2        
             ,oola.fulfilled_quantity2              AS fulfilled_quantity2           
             ,oola.mfg_lead_time                    AS mfg_lead_time                 
             ,oola.lock_control                     AS lock_control                  
             ,oola.subinventory                     AS subinventory                  
             ,oola.unit_list_price_per_pqty         AS unit_list_price_per_pqty      
             ,oola.unit_selling_price_per_pqty      AS unit_selling_price_per_pqty   
             ,oola.price_request_code               AS price_request_code            
             ,oola.original_inventory_item_id       AS original_inventory_item_id    
             ,oola.original_ordered_item_id         AS original_ordered_item_id      
             ,oola.original_ordered_item            AS original_ordered_item         
             ,oola.original_item_identifier_type    AS original_item_identifier_type 
             ,oola.item_substitution_type_code      AS item_substitution_type_code   
             ,oola.override_atp_date_code           AS override_atp_date_code        
             ,oola.late_demand_penalty_factor       AS late_demand_penalty_factor    
             ,oola.accounting_rule_duration         AS accounting_rule_duration      
             ,oola.attribute16                      AS attribute16                   
             ,oola.attribute17                      AS attribute17                   
             ,oola.attribute18                      AS attribute18                   
             ,oola.attribute19                      AS attribute19                   
             ,oola.attribute20                      AS attribute20                   
             ,oola.user_item_description            AS user_item_description         
             ,oola.unit_cost                        AS unit_cost                     
             ,oola.item_relationship_type           AS item_relationship_type        
             ,oola.blanket_line_number              AS blanket_line_number           
             ,oola.blanket_number                   AS blanket_number                
             ,oola.blanket_version_number           AS blanket_version_number        
             ,oola.sales_document_type_code         AS sales_document_type_code      
             ,oola.firm_demand_flag                 AS firm_demand_flag              
             ,oola.earliest_ship_date               AS earliest_ship_date            
             ,oola.transaction_phase_code           AS transaction_phase_code        
             ,oola.source_document_version_number   AS source_document_version_number
             ,oola.payment_type_code                AS payment_type_code             
             ,oola.minisite_id                      AS minisite_id                   
             ,oola.end_customer_id                  AS end_customer_id               
             ,oola.end_customer_contact_id          AS end_customer_contact_id       
             ,oola.end_customer_site_use_id         AS end_customer_site_use_id      
             ,oola.ib_owner                         AS ib_owner                      
             ,oola.ib_current_location              AS ib_current_location           
             ,oola.ib_installed_at_location         AS ib_installed_at_location      
             ,oola.retrobill_request_id             AS retrobill_request_id          
             ,oola.original_list_price              AS original_list_price           
             ,oola.service_credit_eligible_code     AS service_credit_eligible_code  
             ,oola.order_firmed_date                AS order_firmed_date             
             ,oola.actual_fulfillment_date          AS actual_fulfillment_date       
             ,oola.charge_periodicity_code          AS charge_periodicity_code       
      FROM    oe_order_lines_all  oola
      WHERE   oola.header_id = it_header_id
    ;
    -- <カーソル名>レコード型
    l_order_header_tbl       g_oe_order_header_ttype;                            -- 受注ヘッダ（標準）テーブル
    l_order_line_tbl         g_oe_order_line_ttype;                              -- 受注明細（標準）テーブル
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
    gn_arc_cnt_header := 0;
    gn_arc_cnt_line   := 0;
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
      ld_基準日 := 処理日取得共通関数から取得した処理日 - ln_バックアップ期間;
--
    iv_proc_dateがNULLでないの場合
--
      ld_基準日 := TO_DATE(iv_proc_date) - ln_バックアップ期間;
     */
    lv_process_part := 'INパラメータの確認';
    IF ( iv_proc_date IS NULL ) THEN
--
      ld_standard_date := xxcmn_common4_pkg.get_syori_date - ln_archive_period;
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
    --
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
    -- バックアップ対象受注ヘッダ（標準）取得
    -- ===============================================
    /*
    FOR lr_header_rec IN バックアップ対象受注ヘッダ（標準）取得（ld_基準日，ln_バックアップレンジ，ln_営業単位ID） LOOP
     */
    << archive_order_header_loop >>
    FOR lr_header_rec IN archive_order_header_cur(
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
        ln_未コミットバックアップ件数（受注ヘッダ（標準）） > 0
        かつ MOD(ln_未コミットバックアップ件数（受注ヘッダ（標準））, ln_分割コミット数) = 0の場合
         */
        IF (  (ln_arc_cnt_header_yet > 0)
          AND (MOD(ln_arc_cnt_header_yet, ln_commit_range) = 0)
           )
        THEN
--
          /*
          FORALL ln_idx IN 1..ln_未コミットバックアップ件数（受注ヘッダ（標準））
            INSERT INTO 受注ヘッダ（標準）バックアップ
            (
                全カラム
              , バックアップ登録日
              , バックアップ要求ID
            )
            VALUES
            (
                l_受注ヘッダ（標準）テーブル（ln_idx）全カラム
              , SYSDATE
              , 要求ID
            )
           */
          lv_process_part := '受注ヘッダ（標準）登録１';
          FORALL ln_idx IN 1..ln_arc_cnt_header_yet
            INSERT INTO xxcmn_oe_order_headers_all_arc VALUES l_order_header_tbl(ln_idx);
--
          /*
          l_受注ヘッダ（標準）テーブル．DELETE;
           */
          l_order_header_tbl.DELETE;
--
          /*
          FORALL ln_idx IN 1..ln_未コミットバックアップ件数（受注明細（標準））
            INSERT INTO 受注明細（標準）バックアップ
            (
                全カラム
              , バックアップ登録日
              , バックアップ要求ID
            )
            VALUES
            (
                受注明細（標準）テーブル（ln_idx）全カラム
              , SYSDATE
              , 要求ID
            )
           */
          lv_process_part := '受注明細（標準）登録１';
          FORALL ln_idx IN 1..ln_arc_cnt_line_yet
            INSERT INTO xxcmn_oe_order_lines_all_arc VALUES l_order_line_tbl(ln_idx);
--
          /*
          l_受注明細（標準）テーブル．DELETE;
           */
          l_order_line_tbl.DELETE;
--
          /*
          gn_バックアップ件数（受注ヘッダ（標準）） := gn_バックアップ件数（受注ヘッダ（標準））
            + ln_未コミットバックアップ件数（受注ヘッダ（標準））;
          ln_未コミットバックアップ件数（受注ヘッダ（標準）） := 0;
          */
          gn_arc_cnt_header     := gn_arc_cnt_header + ln_arc_cnt_header_yet;
          ln_arc_cnt_header_yet := 0;
--
          /*
          gn_バックアップ件数（受注明細（標準）） := gn_バックアップ件数（受注明細（標準））
            + ln_未コミットバックアップ件数（受注明細（標準））;
          ln_未コミットバックアップ件数（受注明細（標準）） := 0;
          */
          gn_arc_cnt_line     := gn_arc_cnt_line + ln_arc_cnt_line_yet;
          ln_arc_cnt_line_yet := 0;
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
      ln_対象受注ヘッダID := lr_header_rec．受注ヘッダID;
       */
      lt_header_id := lr_header_rec.header_id;
--
      -- ===============================================
      -- バックアップ対象受注明細（標準）取得
      -- ===============================================
      /*
      FOR lr_line_rec IN バックアップ対象受注明細（標準）取得（lr_header_rec．受注ヘッダID） LOOP
       */
      << archive_order_line_loop >>
      FOR lr_line_rec IN archive_order_line_cur(
                         lr_header_rec.header_id
                         )
      LOOP
--
        /*
        ln_未コミットバックアップ件数（受注明細（標準）） := ln_未コミットバックアップ件数（受注明細（標準）） + 1;
        l_受注明細（標準）テーブル（ln_未コミットバックアップ件数（受注明細（標準）） := lr_line_rec;
         */
        ln_arc_cnt_line_yet := ln_arc_cnt_line_yet + 1;
        l_order_line_tbl(ln_arc_cnt_line_yet).line_id                        :=lr_line_rec.line_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).org_id                         :=lr_line_rec.org_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).header_id                      :=lr_line_rec.header_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).line_type_id                   :=lr_line_rec.line_type_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).line_number                    :=lr_line_rec.line_number;
        l_order_line_tbl(ln_arc_cnt_line_yet).ordered_item                   :=lr_line_rec.ordered_item;
        l_order_line_tbl(ln_arc_cnt_line_yet).request_date                   :=lr_line_rec.request_date;
        l_order_line_tbl(ln_arc_cnt_line_yet).promise_date                   :=lr_line_rec.promise_date;
        l_order_line_tbl(ln_arc_cnt_line_yet).schedule_ship_date             :=lr_line_rec.schedule_ship_date;
        l_order_line_tbl(ln_arc_cnt_line_yet).order_quantity_uom             :=lr_line_rec.order_quantity_uom;
        l_order_line_tbl(ln_arc_cnt_line_yet).pricing_quantity               :=lr_line_rec.pricing_quantity;
        l_order_line_tbl(ln_arc_cnt_line_yet).pricing_quantity_uom           :=lr_line_rec.pricing_quantity_uom;
        l_order_line_tbl(ln_arc_cnt_line_yet).cancelled_quantity             :=lr_line_rec.cancelled_quantity;
        l_order_line_tbl(ln_arc_cnt_line_yet).shipped_quantity               :=lr_line_rec.shipped_quantity;
        l_order_line_tbl(ln_arc_cnt_line_yet).ordered_quantity               :=lr_line_rec.ordered_quantity;
        l_order_line_tbl(ln_arc_cnt_line_yet).fulfilled_quantity             :=lr_line_rec.fulfilled_quantity;
        l_order_line_tbl(ln_arc_cnt_line_yet).shipping_quantity              :=lr_line_rec.shipping_quantity;
        l_order_line_tbl(ln_arc_cnt_line_yet).shipping_quantity_uom          :=lr_line_rec.shipping_quantity_uom;
        l_order_line_tbl(ln_arc_cnt_line_yet).delivery_lead_time             :=lr_line_rec.delivery_lead_time;
        l_order_line_tbl(ln_arc_cnt_line_yet).tax_exempt_flag                :=lr_line_rec.tax_exempt_flag;
        l_order_line_tbl(ln_arc_cnt_line_yet).tax_exempt_number              :=lr_line_rec.tax_exempt_number;
        l_order_line_tbl(ln_arc_cnt_line_yet).tax_exempt_reason_code         :=lr_line_rec.tax_exempt_reason_code;
        l_order_line_tbl(ln_arc_cnt_line_yet).ship_from_org_id               :=lr_line_rec.ship_from_org_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).ship_to_org_id                 :=lr_line_rec.ship_to_org_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).invoice_to_org_id              :=lr_line_rec.invoice_to_org_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).deliver_to_org_id              :=lr_line_rec.deliver_to_org_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).ship_to_contact_id             :=lr_line_rec.ship_to_contact_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).deliver_to_contact_id          :=lr_line_rec.deliver_to_contact_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).invoice_to_contact_id          :=lr_line_rec.invoice_to_contact_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).intmed_ship_to_org_id          :=lr_line_rec.intmed_ship_to_org_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).intmed_ship_to_contact_id      :=lr_line_rec.intmed_ship_to_contact_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).sold_from_org_id               :=lr_line_rec.sold_from_org_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).sold_to_org_id                 :=lr_line_rec.sold_to_org_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).cust_po_number                 :=lr_line_rec.cust_po_number;
        l_order_line_tbl(ln_arc_cnt_line_yet).ship_tolerance_above           :=lr_line_rec.ship_tolerance_above;
        l_order_line_tbl(ln_arc_cnt_line_yet).ship_tolerance_below           :=lr_line_rec.ship_tolerance_below;
        l_order_line_tbl(ln_arc_cnt_line_yet).demand_bucket_type_code        :=lr_line_rec.demand_bucket_type_code;
        l_order_line_tbl(ln_arc_cnt_line_yet).veh_cus_item_cum_key_id        :=lr_line_rec.veh_cus_item_cum_key_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).rla_schedule_type_code         :=lr_line_rec.rla_schedule_type_code;
        l_order_line_tbl(ln_arc_cnt_line_yet).customer_dock_code             :=lr_line_rec.customer_dock_code;
        l_order_line_tbl(ln_arc_cnt_line_yet).customer_job                   :=lr_line_rec.customer_job;
        l_order_line_tbl(ln_arc_cnt_line_yet).customer_production_line       :=lr_line_rec.customer_production_line;
        l_order_line_tbl(ln_arc_cnt_line_yet).cust_model_serial_number       :=lr_line_rec.cust_model_serial_number;
        l_order_line_tbl(ln_arc_cnt_line_yet).project_id                     :=lr_line_rec.project_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).task_id                        :=lr_line_rec.task_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).inventory_item_id              :=lr_line_rec.inventory_item_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).tax_date                       :=lr_line_rec.tax_date;
        l_order_line_tbl(ln_arc_cnt_line_yet).tax_code                       :=lr_line_rec.tax_code;
        l_order_line_tbl(ln_arc_cnt_line_yet).tax_rate                       :=lr_line_rec.tax_rate;
        l_order_line_tbl(ln_arc_cnt_line_yet).invoice_interface_status_code
                                                                           :=lr_line_rec.invoice_interface_status_code;
        l_order_line_tbl(ln_arc_cnt_line_yet).demand_class_code              :=lr_line_rec.demand_class_code;
        l_order_line_tbl(ln_arc_cnt_line_yet).price_list_id                  :=lr_line_rec.price_list_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).pricing_date                   :=lr_line_rec.pricing_date;
        l_order_line_tbl(ln_arc_cnt_line_yet).shipment_number                :=lr_line_rec.shipment_number;
        l_order_line_tbl(ln_arc_cnt_line_yet).agreement_id                   :=lr_line_rec.agreement_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).shipment_priority_code         :=lr_line_rec.shipment_priority_code;
        l_order_line_tbl(ln_arc_cnt_line_yet).shipping_method_code           :=lr_line_rec.shipping_method_code;
        l_order_line_tbl(ln_arc_cnt_line_yet).freight_carrier_code           :=lr_line_rec.freight_carrier_code;
        l_order_line_tbl(ln_arc_cnt_line_yet).freight_terms_code             :=lr_line_rec.freight_terms_code;
        l_order_line_tbl(ln_arc_cnt_line_yet).fob_point_code                 :=lr_line_rec.fob_point_code;
        l_order_line_tbl(ln_arc_cnt_line_yet).tax_point_code                 :=lr_line_rec.tax_point_code;
        l_order_line_tbl(ln_arc_cnt_line_yet).payment_term_id                :=lr_line_rec.payment_term_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).invoicing_rule_id              :=lr_line_rec.invoicing_rule_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).accounting_rule_id             :=lr_line_rec.accounting_rule_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).source_document_type_id        :=lr_line_rec.source_document_type_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).orig_sys_document_ref          :=lr_line_rec.orig_sys_document_ref;
        l_order_line_tbl(ln_arc_cnt_line_yet).source_document_id             :=lr_line_rec.source_document_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).orig_sys_line_ref              :=lr_line_rec.orig_sys_line_ref;
        l_order_line_tbl(ln_arc_cnt_line_yet).source_document_line_id        :=lr_line_rec.source_document_line_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).reference_line_id              :=lr_line_rec.reference_line_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).reference_type                 :=lr_line_rec.reference_type;
        l_order_line_tbl(ln_arc_cnt_line_yet).reference_header_id            :=lr_line_rec.reference_header_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).item_revision                  :=lr_line_rec.item_revision;
        l_order_line_tbl(ln_arc_cnt_line_yet).unit_selling_price             :=lr_line_rec.unit_selling_price;
        l_order_line_tbl(ln_arc_cnt_line_yet).unit_list_price                :=lr_line_rec.unit_list_price;
        l_order_line_tbl(ln_arc_cnt_line_yet).tax_value                      :=lr_line_rec.tax_value;
        l_order_line_tbl(ln_arc_cnt_line_yet).context                        :=lr_line_rec.context;
        l_order_line_tbl(ln_arc_cnt_line_yet).attribute1                     :=lr_line_rec.attribute1;
        l_order_line_tbl(ln_arc_cnt_line_yet).attribute2                     :=lr_line_rec.attribute2;
        l_order_line_tbl(ln_arc_cnt_line_yet).attribute3                     :=lr_line_rec.attribute3;
        l_order_line_tbl(ln_arc_cnt_line_yet).attribute4                     :=lr_line_rec.attribute4;
        l_order_line_tbl(ln_arc_cnt_line_yet).attribute5                     :=lr_line_rec.attribute5;
        l_order_line_tbl(ln_arc_cnt_line_yet).attribute6                     :=lr_line_rec.attribute6;
        l_order_line_tbl(ln_arc_cnt_line_yet).attribute7                     :=lr_line_rec.attribute7;
        l_order_line_tbl(ln_arc_cnt_line_yet).attribute8                     :=lr_line_rec.attribute8;
        l_order_line_tbl(ln_arc_cnt_line_yet).attribute9                     :=lr_line_rec.attribute9;
        l_order_line_tbl(ln_arc_cnt_line_yet).attribute10                    :=lr_line_rec.attribute10;
        l_order_line_tbl(ln_arc_cnt_line_yet).attribute11                    :=lr_line_rec.attribute11;
        l_order_line_tbl(ln_arc_cnt_line_yet).attribute12                    :=lr_line_rec.attribute12;
        l_order_line_tbl(ln_arc_cnt_line_yet).attribute13                    :=lr_line_rec.attribute13;
        l_order_line_tbl(ln_arc_cnt_line_yet).attribute14                    :=lr_line_rec.attribute14;
        l_order_line_tbl(ln_arc_cnt_line_yet).attribute15                    :=lr_line_rec.attribute15;
        l_order_line_tbl(ln_arc_cnt_line_yet).global_attribute_category      :=lr_line_rec.global_attribute_category;
        l_order_line_tbl(ln_arc_cnt_line_yet).global_attribute1              :=lr_line_rec.global_attribute1;
        l_order_line_tbl(ln_arc_cnt_line_yet).global_attribute2              :=lr_line_rec.global_attribute2;
        l_order_line_tbl(ln_arc_cnt_line_yet).global_attribute3              :=lr_line_rec.global_attribute3;
        l_order_line_tbl(ln_arc_cnt_line_yet).global_attribute4              :=lr_line_rec.global_attribute4;
        l_order_line_tbl(ln_arc_cnt_line_yet).global_attribute5              :=lr_line_rec.global_attribute5;
        l_order_line_tbl(ln_arc_cnt_line_yet).global_attribute6              :=lr_line_rec.global_attribute6;
        l_order_line_tbl(ln_arc_cnt_line_yet).global_attribute7              :=lr_line_rec.global_attribute7;
        l_order_line_tbl(ln_arc_cnt_line_yet).global_attribute8              :=lr_line_rec.global_attribute8;
        l_order_line_tbl(ln_arc_cnt_line_yet).global_attribute9              :=lr_line_rec.global_attribute9;
        l_order_line_tbl(ln_arc_cnt_line_yet).global_attribute10             :=lr_line_rec.global_attribute10;
        l_order_line_tbl(ln_arc_cnt_line_yet).global_attribute11             :=lr_line_rec.global_attribute11;
        l_order_line_tbl(ln_arc_cnt_line_yet).global_attribute12             :=lr_line_rec.global_attribute12;
        l_order_line_tbl(ln_arc_cnt_line_yet).global_attribute13             :=lr_line_rec.global_attribute13;
        l_order_line_tbl(ln_arc_cnt_line_yet).global_attribute14             :=lr_line_rec.global_attribute14;
        l_order_line_tbl(ln_arc_cnt_line_yet).global_attribute15             :=lr_line_rec.global_attribute15;
        l_order_line_tbl(ln_arc_cnt_line_yet).global_attribute16             :=lr_line_rec.global_attribute16;
        l_order_line_tbl(ln_arc_cnt_line_yet).global_attribute17             :=lr_line_rec.global_attribute17;
        l_order_line_tbl(ln_arc_cnt_line_yet).global_attribute18             :=lr_line_rec.global_attribute18;
        l_order_line_tbl(ln_arc_cnt_line_yet).global_attribute19             :=lr_line_rec.global_attribute19;
        l_order_line_tbl(ln_arc_cnt_line_yet).global_attribute20             :=lr_line_rec.global_attribute20;
        l_order_line_tbl(ln_arc_cnt_line_yet).pricing_context                :=lr_line_rec.pricing_context;
        l_order_line_tbl(ln_arc_cnt_line_yet).pricing_attribute1             :=lr_line_rec.pricing_attribute1;
        l_order_line_tbl(ln_arc_cnt_line_yet).pricing_attribute2             :=lr_line_rec.pricing_attribute2;
        l_order_line_tbl(ln_arc_cnt_line_yet).pricing_attribute3             :=lr_line_rec.pricing_attribute3;
        l_order_line_tbl(ln_arc_cnt_line_yet).pricing_attribute4             :=lr_line_rec.pricing_attribute4;
        l_order_line_tbl(ln_arc_cnt_line_yet).pricing_attribute5             :=lr_line_rec.pricing_attribute5;
        l_order_line_tbl(ln_arc_cnt_line_yet).pricing_attribute6             :=lr_line_rec.pricing_attribute6;
        l_order_line_tbl(ln_arc_cnt_line_yet).pricing_attribute7             :=lr_line_rec.pricing_attribute7;
        l_order_line_tbl(ln_arc_cnt_line_yet).pricing_attribute8             :=lr_line_rec.pricing_attribute8;
        l_order_line_tbl(ln_arc_cnt_line_yet).pricing_attribute9             :=lr_line_rec.pricing_attribute9;
        l_order_line_tbl(ln_arc_cnt_line_yet).pricing_attribute10            :=lr_line_rec.pricing_attribute10;
        l_order_line_tbl(ln_arc_cnt_line_yet).industry_context               :=lr_line_rec.industry_context;
        l_order_line_tbl(ln_arc_cnt_line_yet).industry_attribute1            :=lr_line_rec.industry_attribute1;
        l_order_line_tbl(ln_arc_cnt_line_yet).industry_attribute2            :=lr_line_rec.industry_attribute2;
        l_order_line_tbl(ln_arc_cnt_line_yet).industry_attribute3            :=lr_line_rec.industry_attribute3;
        l_order_line_tbl(ln_arc_cnt_line_yet).industry_attribute4            :=lr_line_rec.industry_attribute4;
        l_order_line_tbl(ln_arc_cnt_line_yet).industry_attribute5            :=lr_line_rec.industry_attribute5;
        l_order_line_tbl(ln_arc_cnt_line_yet).industry_attribute6            :=lr_line_rec.industry_attribute6;
        l_order_line_tbl(ln_arc_cnt_line_yet).industry_attribute7            :=lr_line_rec.industry_attribute7;
        l_order_line_tbl(ln_arc_cnt_line_yet).industry_attribute8            :=lr_line_rec.industry_attribute8;
        l_order_line_tbl(ln_arc_cnt_line_yet).industry_attribute9            :=lr_line_rec.industry_attribute9;
        l_order_line_tbl(ln_arc_cnt_line_yet).industry_attribute10           :=lr_line_rec.industry_attribute10;
        l_order_line_tbl(ln_arc_cnt_line_yet).industry_attribute11           :=lr_line_rec.industry_attribute11;
        l_order_line_tbl(ln_arc_cnt_line_yet).industry_attribute13           :=lr_line_rec.industry_attribute13;
        l_order_line_tbl(ln_arc_cnt_line_yet).industry_attribute12           :=lr_line_rec.industry_attribute12;
        l_order_line_tbl(ln_arc_cnt_line_yet).industry_attribute14           :=lr_line_rec.industry_attribute14;
        l_order_line_tbl(ln_arc_cnt_line_yet).industry_attribute15           :=lr_line_rec.industry_attribute15;
        l_order_line_tbl(ln_arc_cnt_line_yet).industry_attribute16           :=lr_line_rec.industry_attribute16;
        l_order_line_tbl(ln_arc_cnt_line_yet).industry_attribute17           :=lr_line_rec.industry_attribute17;
        l_order_line_tbl(ln_arc_cnt_line_yet).industry_attribute18           :=lr_line_rec.industry_attribute18;
        l_order_line_tbl(ln_arc_cnt_line_yet).industry_attribute19           :=lr_line_rec.industry_attribute19;
        l_order_line_tbl(ln_arc_cnt_line_yet).industry_attribute20           :=lr_line_rec.industry_attribute20;
        l_order_line_tbl(ln_arc_cnt_line_yet).industry_attribute21           :=lr_line_rec.industry_attribute21;
        l_order_line_tbl(ln_arc_cnt_line_yet).industry_attribute22           :=lr_line_rec.industry_attribute22;
        l_order_line_tbl(ln_arc_cnt_line_yet).industry_attribute23           :=lr_line_rec.industry_attribute23;
        l_order_line_tbl(ln_arc_cnt_line_yet).industry_attribute24           :=lr_line_rec.industry_attribute24;
        l_order_line_tbl(ln_arc_cnt_line_yet).industry_attribute25           :=lr_line_rec.industry_attribute25;
        l_order_line_tbl(ln_arc_cnt_line_yet).industry_attribute26           :=lr_line_rec.industry_attribute26;
        l_order_line_tbl(ln_arc_cnt_line_yet).industry_attribute27           :=lr_line_rec.industry_attribute27;
        l_order_line_tbl(ln_arc_cnt_line_yet).industry_attribute28           :=lr_line_rec.industry_attribute28;
        l_order_line_tbl(ln_arc_cnt_line_yet).industry_attribute29           :=lr_line_rec.industry_attribute29;
        l_order_line_tbl(ln_arc_cnt_line_yet).industry_attribute30           :=lr_line_rec.industry_attribute30;
        l_order_line_tbl(ln_arc_cnt_line_yet).creation_date                  :=lr_line_rec.creation_date;
        l_order_line_tbl(ln_arc_cnt_line_yet).created_by                     :=lr_line_rec.created_by;
        l_order_line_tbl(ln_arc_cnt_line_yet).last_update_date               :=lr_line_rec.last_update_date;
        l_order_line_tbl(ln_arc_cnt_line_yet).last_updated_by                :=lr_line_rec.last_updated_by;
        l_order_line_tbl(ln_arc_cnt_line_yet).last_update_login              :=lr_line_rec.last_update_login;
        l_order_line_tbl(ln_arc_cnt_line_yet).program_application_id         :=lr_line_rec.program_application_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).program_id                     :=lr_line_rec.program_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).program_update_date            :=lr_line_rec.program_update_date;
        l_order_line_tbl(ln_arc_cnt_line_yet).request_id                     :=lr_line_rec.request_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).top_model_line_id              :=lr_line_rec.top_model_line_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).link_to_line_id                :=lr_line_rec.link_to_line_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).component_sequence_id          :=lr_line_rec.component_sequence_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).component_code                 :=lr_line_rec.component_code;
        l_order_line_tbl(ln_arc_cnt_line_yet).config_display_sequence        :=lr_line_rec.config_display_sequence;
        l_order_line_tbl(ln_arc_cnt_line_yet).sort_order                     :=lr_line_rec.sort_order;
        l_order_line_tbl(ln_arc_cnt_line_yet).item_type_code                 :=lr_line_rec.item_type_code;
        l_order_line_tbl(ln_arc_cnt_line_yet).option_number                  :=lr_line_rec.option_number;
        l_order_line_tbl(ln_arc_cnt_line_yet).option_flag                    :=lr_line_rec.option_flag;
        l_order_line_tbl(ln_arc_cnt_line_yet).dep_plan_required_flag         :=lr_line_rec.dep_plan_required_flag;
        l_order_line_tbl(ln_arc_cnt_line_yet).visible_demand_flag            :=lr_line_rec.visible_demand_flag;
        l_order_line_tbl(ln_arc_cnt_line_yet).line_category_code             :=lr_line_rec.line_category_code;
        l_order_line_tbl(ln_arc_cnt_line_yet).actual_shipment_date           :=lr_line_rec.actual_shipment_date;
        l_order_line_tbl(ln_arc_cnt_line_yet).customer_trx_line_id           :=lr_line_rec.customer_trx_line_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).return_context                 :=lr_line_rec.return_context;
        l_order_line_tbl(ln_arc_cnt_line_yet).return_attribute1              :=lr_line_rec.return_attribute1;
        l_order_line_tbl(ln_arc_cnt_line_yet).return_attribute2              :=lr_line_rec.return_attribute2;
        l_order_line_tbl(ln_arc_cnt_line_yet).return_attribute3              :=lr_line_rec.return_attribute3;
        l_order_line_tbl(ln_arc_cnt_line_yet).return_attribute4              :=lr_line_rec.return_attribute4;
        l_order_line_tbl(ln_arc_cnt_line_yet).return_attribute5              :=lr_line_rec.return_attribute5;
        l_order_line_tbl(ln_arc_cnt_line_yet).return_attribute6              :=lr_line_rec.return_attribute6;
        l_order_line_tbl(ln_arc_cnt_line_yet).return_attribute7              :=lr_line_rec.return_attribute7;
        l_order_line_tbl(ln_arc_cnt_line_yet).return_attribute8              :=lr_line_rec.return_attribute8;
        l_order_line_tbl(ln_arc_cnt_line_yet).return_attribute9              :=lr_line_rec.return_attribute9;
        l_order_line_tbl(ln_arc_cnt_line_yet).return_attribute10             :=lr_line_rec.return_attribute10;
        l_order_line_tbl(ln_arc_cnt_line_yet).return_attribute11             :=lr_line_rec.return_attribute11;
        l_order_line_tbl(ln_arc_cnt_line_yet).return_attribute12             :=lr_line_rec.return_attribute12;
        l_order_line_tbl(ln_arc_cnt_line_yet).return_attribute13             :=lr_line_rec.return_attribute13;
        l_order_line_tbl(ln_arc_cnt_line_yet).return_attribute14             :=lr_line_rec.return_attribute14;
        l_order_line_tbl(ln_arc_cnt_line_yet).return_attribute15             :=lr_line_rec.return_attribute15;
        l_order_line_tbl(ln_arc_cnt_line_yet).actual_arrival_date            :=lr_line_rec.actual_arrival_date;
        l_order_line_tbl(ln_arc_cnt_line_yet).ato_line_id                    :=lr_line_rec.ato_line_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).auto_selected_quantity         :=lr_line_rec.auto_selected_quantity;
        l_order_line_tbl(ln_arc_cnt_line_yet).component_number               :=lr_line_rec.component_number;
        l_order_line_tbl(ln_arc_cnt_line_yet).earliest_acceptable_date       :=lr_line_rec.earliest_acceptable_date;
        l_order_line_tbl(ln_arc_cnt_line_yet).explosion_date                 :=lr_line_rec.explosion_date;
        l_order_line_tbl(ln_arc_cnt_line_yet).latest_acceptable_date         :=lr_line_rec.latest_acceptable_date;
        l_order_line_tbl(ln_arc_cnt_line_yet).model_group_number             :=lr_line_rec.model_group_number;
        l_order_line_tbl(ln_arc_cnt_line_yet).schedule_arrival_date          :=lr_line_rec.schedule_arrival_date;
        l_order_line_tbl(ln_arc_cnt_line_yet).ship_model_complete_flag       :=lr_line_rec.ship_model_complete_flag;
        l_order_line_tbl(ln_arc_cnt_line_yet).schedule_status_code           :=lr_line_rec.schedule_status_code;
        l_order_line_tbl(ln_arc_cnt_line_yet).source_type_code               :=lr_line_rec.source_type_code;
        l_order_line_tbl(ln_arc_cnt_line_yet).cancelled_flag                 :=lr_line_rec.cancelled_flag;
        l_order_line_tbl(ln_arc_cnt_line_yet).open_flag                      :=lr_line_rec.open_flag;
        l_order_line_tbl(ln_arc_cnt_line_yet).booked_flag                    :=lr_line_rec.booked_flag;
        l_order_line_tbl(ln_arc_cnt_line_yet).salesrep_id                    :=lr_line_rec.salesrep_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).return_reason_code             :=lr_line_rec.return_reason_code;
        l_order_line_tbl(ln_arc_cnt_line_yet).arrival_set_id                 :=lr_line_rec.arrival_set_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).ship_set_id                    :=lr_line_rec.ship_set_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).split_from_line_id             :=lr_line_rec.split_from_line_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).cust_production_seq_num        :=lr_line_rec.cust_production_seq_num;
        l_order_line_tbl(ln_arc_cnt_line_yet).authorized_to_ship_flag        :=lr_line_rec.authorized_to_ship_flag;
        l_order_line_tbl(ln_arc_cnt_line_yet).over_ship_reason_code          :=lr_line_rec.over_ship_reason_code;
        l_order_line_tbl(ln_arc_cnt_line_yet).over_ship_resolved_flag        :=lr_line_rec.over_ship_resolved_flag;
        l_order_line_tbl(ln_arc_cnt_line_yet).ordered_item_id                :=lr_line_rec.ordered_item_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).item_identifier_type           :=lr_line_rec.item_identifier_type;
        l_order_line_tbl(ln_arc_cnt_line_yet).configuration_id               :=lr_line_rec.configuration_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).commitment_id                  :=lr_line_rec.commitment_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).shipping_interfaced_flag       :=lr_line_rec.shipping_interfaced_flag;
        l_order_line_tbl(ln_arc_cnt_line_yet).credit_invoice_line_id         :=lr_line_rec.credit_invoice_line_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).first_ack_code                 :=lr_line_rec.first_ack_code;
        l_order_line_tbl(ln_arc_cnt_line_yet).first_ack_date                 :=lr_line_rec.first_ack_date;
        l_order_line_tbl(ln_arc_cnt_line_yet).last_ack_code                  :=lr_line_rec.last_ack_code;
        l_order_line_tbl(ln_arc_cnt_line_yet).last_ack_date                  :=lr_line_rec.last_ack_date;
        l_order_line_tbl(ln_arc_cnt_line_yet).planning_priority              :=lr_line_rec.planning_priority;
        l_order_line_tbl(ln_arc_cnt_line_yet).order_source_id                :=lr_line_rec.order_source_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).orig_sys_shipment_ref          :=lr_line_rec.orig_sys_shipment_ref;
        l_order_line_tbl(ln_arc_cnt_line_yet).change_sequence                :=lr_line_rec.change_sequence;
        l_order_line_tbl(ln_arc_cnt_line_yet).drop_ship_flag                 :=lr_line_rec.drop_ship_flag;
        l_order_line_tbl(ln_arc_cnt_line_yet).customer_line_number           :=lr_line_rec.customer_line_number;
        l_order_line_tbl(ln_arc_cnt_line_yet).customer_shipment_number       :=lr_line_rec.customer_shipment_number;
        l_order_line_tbl(ln_arc_cnt_line_yet).customer_item_net_price        :=lr_line_rec.customer_item_net_price;
        l_order_line_tbl(ln_arc_cnt_line_yet).customer_payment_term_id       :=lr_line_rec.customer_payment_term_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).fulfilled_flag                 :=lr_line_rec.fulfilled_flag;
        l_order_line_tbl(ln_arc_cnt_line_yet).end_item_unit_number           :=lr_line_rec.end_item_unit_number;
        l_order_line_tbl(ln_arc_cnt_line_yet).config_header_id               :=lr_line_rec.config_header_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).config_rev_nbr                 :=lr_line_rec.config_rev_nbr;
        l_order_line_tbl(ln_arc_cnt_line_yet).mfg_component_sequence_id      :=lr_line_rec.mfg_component_sequence_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).shipping_instructions          :=lr_line_rec.shipping_instructions;
        l_order_line_tbl(ln_arc_cnt_line_yet).packing_instructions           :=lr_line_rec.packing_instructions;
        l_order_line_tbl(ln_arc_cnt_line_yet).invoiced_quantity              :=lr_line_rec.invoiced_quantity;
        l_order_line_tbl(ln_arc_cnt_line_yet).reference_customer_trx_line_id
                                                                          :=lr_line_rec.reference_customer_trx_line_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).split_by                       :=lr_line_rec.split_by;
        l_order_line_tbl(ln_arc_cnt_line_yet).line_set_id                    :=lr_line_rec.line_set_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).service_txn_reason_code        :=lr_line_rec.service_txn_reason_code;
        l_order_line_tbl(ln_arc_cnt_line_yet).service_txn_comments           :=lr_line_rec.service_txn_comments;
        l_order_line_tbl(ln_arc_cnt_line_yet).service_duration               :=lr_line_rec.service_duration;
        l_order_line_tbl(ln_arc_cnt_line_yet).service_start_date             :=lr_line_rec.service_start_date;
        l_order_line_tbl(ln_arc_cnt_line_yet).service_end_date               :=lr_line_rec.service_end_date;
        l_order_line_tbl(ln_arc_cnt_line_yet).service_coterminate_flag       :=lr_line_rec.service_coterminate_flag;
        l_order_line_tbl(ln_arc_cnt_line_yet).unit_list_percent              :=lr_line_rec.unit_list_percent;
        l_order_line_tbl(ln_arc_cnt_line_yet).unit_selling_percent           :=lr_line_rec.unit_selling_percent;
        l_order_line_tbl(ln_arc_cnt_line_yet).unit_percent_base_price        :=lr_line_rec.unit_percent_base_price;
        l_order_line_tbl(ln_arc_cnt_line_yet).service_number                 :=lr_line_rec.service_number;
        l_order_line_tbl(ln_arc_cnt_line_yet).service_period                 :=lr_line_rec.service_period;
        l_order_line_tbl(ln_arc_cnt_line_yet).shippable_flag                 :=lr_line_rec.shippable_flag;
        l_order_line_tbl(ln_arc_cnt_line_yet).model_remnant_flag             :=lr_line_rec.model_remnant_flag;
        l_order_line_tbl(ln_arc_cnt_line_yet).re_source_flag                 :=lr_line_rec.re_source_flag;
        l_order_line_tbl(ln_arc_cnt_line_yet).flow_status_code               :=lr_line_rec.flow_status_code;
        l_order_line_tbl(ln_arc_cnt_line_yet).tp_context                     :=lr_line_rec.tp_context;
        l_order_line_tbl(ln_arc_cnt_line_yet).tp_attribute1                  :=lr_line_rec.tp_attribute1;
        l_order_line_tbl(ln_arc_cnt_line_yet).tp_attribute2                  :=lr_line_rec.tp_attribute2;
        l_order_line_tbl(ln_arc_cnt_line_yet).tp_attribute3                  :=lr_line_rec.tp_attribute3;
        l_order_line_tbl(ln_arc_cnt_line_yet).tp_attribute4                  :=lr_line_rec.tp_attribute4;
        l_order_line_tbl(ln_arc_cnt_line_yet).tp_attribute5                  :=lr_line_rec.tp_attribute5;
        l_order_line_tbl(ln_arc_cnt_line_yet).tp_attribute6                  :=lr_line_rec.tp_attribute6;
        l_order_line_tbl(ln_arc_cnt_line_yet).tp_attribute7                  :=lr_line_rec.tp_attribute7;
        l_order_line_tbl(ln_arc_cnt_line_yet).tp_attribute8                  :=lr_line_rec.tp_attribute8;
        l_order_line_tbl(ln_arc_cnt_line_yet).tp_attribute9                  :=lr_line_rec.tp_attribute9;
        l_order_line_tbl(ln_arc_cnt_line_yet).tp_attribute10                 :=lr_line_rec.tp_attribute10;
        l_order_line_tbl(ln_arc_cnt_line_yet).tp_attribute11                 :=lr_line_rec.tp_attribute11;
        l_order_line_tbl(ln_arc_cnt_line_yet).tp_attribute12                 :=lr_line_rec.tp_attribute12;
        l_order_line_tbl(ln_arc_cnt_line_yet).tp_attribute13                 :=lr_line_rec.tp_attribute13;
        l_order_line_tbl(ln_arc_cnt_line_yet).tp_attribute14                 :=lr_line_rec.tp_attribute14;
        l_order_line_tbl(ln_arc_cnt_line_yet).tp_attribute15                 :=lr_line_rec.tp_attribute15;
        l_order_line_tbl(ln_arc_cnt_line_yet).fulfillment_method_code        :=lr_line_rec.fulfillment_method_code;
        l_order_line_tbl(ln_arc_cnt_line_yet).marketing_source_code_id       :=lr_line_rec.marketing_source_code_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).service_reference_type_code
                                                                             :=lr_line_rec.service_reference_type_code;
        l_order_line_tbl(ln_arc_cnt_line_yet).service_reference_line_id       :=lr_line_rec.service_reference_line_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).service_reference_system_id
                                                                             :=lr_line_rec.service_reference_system_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).calculate_price_flag           :=lr_line_rec.calculate_price_flag;
        l_order_line_tbl(ln_arc_cnt_line_yet).upgraded_flag                  :=lr_line_rec.upgraded_flag;
        l_order_line_tbl(ln_arc_cnt_line_yet).revenue_amount                 :=lr_line_rec.revenue_amount;
        l_order_line_tbl(ln_arc_cnt_line_yet).fulfillment_date               :=lr_line_rec.fulfillment_date;
        l_order_line_tbl(ln_arc_cnt_line_yet).preferred_grade                :=lr_line_rec.preferred_grade;
        l_order_line_tbl(ln_arc_cnt_line_yet).ordered_quantity2              :=lr_line_rec.ordered_quantity2;
        l_order_line_tbl(ln_arc_cnt_line_yet).ordered_quantity_uom2          :=lr_line_rec.ordered_quantity_uom2;
        l_order_line_tbl(ln_arc_cnt_line_yet).shipping_quantity2             :=lr_line_rec.shipping_quantity2;
        l_order_line_tbl(ln_arc_cnt_line_yet).cancelled_quantity2            :=lr_line_rec.cancelled_quantity2;
        l_order_line_tbl(ln_arc_cnt_line_yet).shipped_quantity2              :=lr_line_rec.shipped_quantity2;
        l_order_line_tbl(ln_arc_cnt_line_yet).shipping_quantity_uom2         :=lr_line_rec.shipping_quantity_uom2;
        l_order_line_tbl(ln_arc_cnt_line_yet).fulfilled_quantity2            :=lr_line_rec.fulfilled_quantity2;
        l_order_line_tbl(ln_arc_cnt_line_yet).mfg_lead_time                  :=lr_line_rec.mfg_lead_time;
        l_order_line_tbl(ln_arc_cnt_line_yet).lock_control                   :=lr_line_rec.lock_control;
        l_order_line_tbl(ln_arc_cnt_line_yet).subinventory                   :=lr_line_rec.subinventory;
        l_order_line_tbl(ln_arc_cnt_line_yet).unit_list_price_per_pqty       :=lr_line_rec.unit_list_price_per_pqty;
        l_order_line_tbl(ln_arc_cnt_line_yet).unit_selling_price_per_pqty
                                                                            :=lr_line_rec.unit_selling_price_per_pqty;
        l_order_line_tbl(ln_arc_cnt_line_yet).price_request_code             :=lr_line_rec.price_request_code;
        l_order_line_tbl(ln_arc_cnt_line_yet).original_inventory_item_id
                                                                              :=lr_line_rec.original_inventory_item_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).original_ordered_item_id       :=lr_line_rec.original_ordered_item_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).original_ordered_item          :=lr_line_rec.original_ordered_item;
        l_order_line_tbl(ln_arc_cnt_line_yet).original_item_identifier_type
                                                                           :=lr_line_rec.original_item_identifier_type;
        l_order_line_tbl(ln_arc_cnt_line_yet).item_substitution_type_code
                                                                             :=lr_line_rec.item_substitution_type_code;
        l_order_line_tbl(ln_arc_cnt_line_yet).override_atp_date_code         :=lr_line_rec.override_atp_date_code;
        l_order_line_tbl(ln_arc_cnt_line_yet).late_demand_penalty_factor
                                                                              :=lr_line_rec.late_demand_penalty_factor;
        l_order_line_tbl(ln_arc_cnt_line_yet).accounting_rule_duration       :=lr_line_rec.accounting_rule_duration;
        l_order_line_tbl(ln_arc_cnt_line_yet).attribute16                    :=lr_line_rec.attribute16;
        l_order_line_tbl(ln_arc_cnt_line_yet).attribute17                    :=lr_line_rec.attribute17;
        l_order_line_tbl(ln_arc_cnt_line_yet).attribute18                    :=lr_line_rec.attribute18;
        l_order_line_tbl(ln_arc_cnt_line_yet).attribute19                    :=lr_line_rec.attribute19;
        l_order_line_tbl(ln_arc_cnt_line_yet).attribute20                    :=lr_line_rec.attribute20;
        l_order_line_tbl(ln_arc_cnt_line_yet).user_item_description          :=lr_line_rec.user_item_description;
        l_order_line_tbl(ln_arc_cnt_line_yet).unit_cost                      :=lr_line_rec.unit_cost;
        l_order_line_tbl(ln_arc_cnt_line_yet).item_relationship_type         :=lr_line_rec.item_relationship_type;
        l_order_line_tbl(ln_arc_cnt_line_yet).blanket_line_number            :=lr_line_rec.blanket_line_number;
        l_order_line_tbl(ln_arc_cnt_line_yet).blanket_number                 :=lr_line_rec.blanket_number;
        l_order_line_tbl(ln_arc_cnt_line_yet).blanket_version_number         :=lr_line_rec.blanket_version_number;
        l_order_line_tbl(ln_arc_cnt_line_yet).sales_document_type_code       :=lr_line_rec.sales_document_type_code;
        l_order_line_tbl(ln_arc_cnt_line_yet).firm_demand_flag               :=lr_line_rec.firm_demand_flag;
        l_order_line_tbl(ln_arc_cnt_line_yet).earliest_ship_date             :=lr_line_rec.earliest_ship_date;
        l_order_line_tbl(ln_arc_cnt_line_yet).transaction_phase_code         :=lr_line_rec.transaction_phase_code;
        l_order_line_tbl(ln_arc_cnt_line_yet).source_document_version_number
                                                                          :=lr_line_rec.source_document_version_number;
        l_order_line_tbl(ln_arc_cnt_line_yet).payment_type_code              :=lr_line_rec.payment_type_code;
        l_order_line_tbl(ln_arc_cnt_line_yet).minisite_id                    :=lr_line_rec.minisite_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).end_customer_id                :=lr_line_rec.end_customer_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).end_customer_contact_id        :=lr_line_rec.end_customer_contact_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).end_customer_site_use_id       :=lr_line_rec.end_customer_site_use_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).ib_owner                       :=lr_line_rec.ib_owner;
        l_order_line_tbl(ln_arc_cnt_line_yet).ib_current_location            :=lr_line_rec.ib_current_location;
        l_order_line_tbl(ln_arc_cnt_line_yet).ib_installed_at_location       :=lr_line_rec.ib_installed_at_location;
        l_order_line_tbl(ln_arc_cnt_line_yet).retrobill_request_id           :=lr_line_rec.retrobill_request_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).original_list_price            :=lr_line_rec.original_list_price;
        l_order_line_tbl(ln_arc_cnt_line_yet).service_credit_eligible_code
                                                                            :=lr_line_rec.service_credit_eligible_code;
        l_order_line_tbl(ln_arc_cnt_line_yet).order_firmed_date              :=lr_line_rec.order_firmed_date;
        l_order_line_tbl(ln_arc_cnt_line_yet).actual_fulfillment_date        :=lr_line_rec.actual_fulfillment_date;
        l_order_line_tbl(ln_arc_cnt_line_yet).charge_periodicity_code        :=lr_line_rec.charge_periodicity_code;
        l_order_line_tbl(ln_arc_cnt_line_yet).archive_date                   :=SYSDATE;
        l_order_line_tbl(ln_arc_cnt_line_yet).archive_request_id             :=cn_request_id;
--

      END LOOP archive_order_line_loop;
--
      /*
      ln_未コミットバックアップ件数（受注ヘッダ（標準）） := ln_未コミットバックアップ件数（受注ヘッダ（標準）） + 1;
      l_受注ヘッダ（標準）テーブル（ln_未コミットバックアップ件数（受注ヘッダ（標準）） := lr_header_rec;
       */
      ln_arc_cnt_header_yet := ln_arc_cnt_header_yet + 1;
      l_order_header_tbl(ln_arc_cnt_header_yet).header_id                  :=lr_header_rec.header_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).org_id                     :=lr_header_rec.org_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).order_type_id              :=lr_header_rec.order_type_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).order_number               :=lr_header_rec.order_number;
      l_order_header_tbl(ln_arc_cnt_header_yet).version_number             :=lr_header_rec.version_number;
      l_order_header_tbl(ln_arc_cnt_header_yet).expiration_date            :=lr_header_rec.expiration_date;
      l_order_header_tbl(ln_arc_cnt_header_yet).order_source_id            :=lr_header_rec.order_source_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).source_document_type_id    :=lr_header_rec.source_document_type_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).orig_sys_document_ref      :=lr_header_rec.orig_sys_document_ref;
      l_order_header_tbl(ln_arc_cnt_header_yet).source_document_id         :=lr_header_rec.source_document_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).ordered_date               :=lr_header_rec.ordered_date;
      l_order_header_tbl(ln_arc_cnt_header_yet).request_date               :=lr_header_rec.request_date;
      l_order_header_tbl(ln_arc_cnt_header_yet).pricing_date               :=lr_header_rec.pricing_date;
      l_order_header_tbl(ln_arc_cnt_header_yet).shipment_priority_code     :=lr_header_rec.shipment_priority_code;
      l_order_header_tbl(ln_arc_cnt_header_yet).demand_class_code          :=lr_header_rec.demand_class_code;
      l_order_header_tbl(ln_arc_cnt_header_yet).price_list_id              :=lr_header_rec.price_list_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).tax_exempt_flag            :=lr_header_rec.tax_exempt_flag;
      l_order_header_tbl(ln_arc_cnt_header_yet).tax_exempt_number          :=lr_header_rec.tax_exempt_number;
      l_order_header_tbl(ln_arc_cnt_header_yet).tax_exempt_reason_code     :=lr_header_rec.tax_exempt_reason_code;
      l_order_header_tbl(ln_arc_cnt_header_yet).conversion_rate            :=lr_header_rec.conversion_rate;
      l_order_header_tbl(ln_arc_cnt_header_yet).conversion_type_code       :=lr_header_rec.conversion_type_code;
      l_order_header_tbl(ln_arc_cnt_header_yet).conversion_rate_date       :=lr_header_rec.conversion_rate_date;
      l_order_header_tbl(ln_arc_cnt_header_yet).partial_shipments_allowed  :=lr_header_rec.partial_shipments_allowed;
      l_order_header_tbl(ln_arc_cnt_header_yet).ship_tolerance_above       :=lr_header_rec.ship_tolerance_above;
      l_order_header_tbl(ln_arc_cnt_header_yet).ship_tolerance_below       :=lr_header_rec.ship_tolerance_below;
      l_order_header_tbl(ln_arc_cnt_header_yet).transactional_curr_code    :=lr_header_rec.transactional_curr_code;
      l_order_header_tbl(ln_arc_cnt_header_yet).agreement_id               :=lr_header_rec.agreement_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).tax_point_code             :=lr_header_rec.tax_point_code;
      l_order_header_tbl(ln_arc_cnt_header_yet).cust_po_number             :=lr_header_rec.cust_po_number;
      l_order_header_tbl(ln_arc_cnt_header_yet).invoicing_rule_id          :=lr_header_rec.invoicing_rule_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).accounting_rule_id         :=lr_header_rec.accounting_rule_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).payment_term_id            :=lr_header_rec.payment_term_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).shipping_method_code       :=lr_header_rec.shipping_method_code;
      l_order_header_tbl(ln_arc_cnt_header_yet).freight_carrier_code       :=lr_header_rec.freight_carrier_code;
      l_order_header_tbl(ln_arc_cnt_header_yet).fob_point_code             :=lr_header_rec.fob_point_code;
      l_order_header_tbl(ln_arc_cnt_header_yet).freight_terms_code         :=lr_header_rec.freight_terms_code;
      l_order_header_tbl(ln_arc_cnt_header_yet).sold_from_org_id           :=lr_header_rec.sold_from_org_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).sold_to_org_id             :=lr_header_rec.sold_to_org_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).ship_from_org_id           :=lr_header_rec.ship_from_org_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).ship_to_org_id             :=lr_header_rec.ship_to_org_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).invoice_to_org_id          :=lr_header_rec.invoice_to_org_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).deliver_to_org_id          :=lr_header_rec.deliver_to_org_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).sold_to_contact_id         :=lr_header_rec.sold_to_contact_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).ship_to_contact_id         :=lr_header_rec.ship_to_contact_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).invoice_to_contact_id      :=lr_header_rec.invoice_to_contact_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).deliver_to_contact_id      :=lr_header_rec.deliver_to_contact_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).creation_date              :=lr_header_rec.creation_date;
      l_order_header_tbl(ln_arc_cnt_header_yet).created_by                 :=lr_header_rec.created_by;
      l_order_header_tbl(ln_arc_cnt_header_yet).last_updated_by            :=lr_header_rec.last_updated_by;
      l_order_header_tbl(ln_arc_cnt_header_yet).last_update_date           :=lr_header_rec.last_update_date;
      l_order_header_tbl(ln_arc_cnt_header_yet).last_update_login          :=lr_header_rec.last_update_login;
      l_order_header_tbl(ln_arc_cnt_header_yet).program_application_id     :=lr_header_rec.program_application_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).program_id                 :=lr_header_rec.program_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).program_update_date        :=lr_header_rec.program_update_date;
      l_order_header_tbl(ln_arc_cnt_header_yet).request_id                 :=lr_header_rec.request_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).context                    :=lr_header_rec.context;
      l_order_header_tbl(ln_arc_cnt_header_yet).attribute1                 :=lr_header_rec.attribute1;
      l_order_header_tbl(ln_arc_cnt_header_yet).attribute2                 :=lr_header_rec.attribute2;
      l_order_header_tbl(ln_arc_cnt_header_yet).attribute3                 :=lr_header_rec.attribute3;
      l_order_header_tbl(ln_arc_cnt_header_yet).attribute4                 :=lr_header_rec.attribute4;
      l_order_header_tbl(ln_arc_cnt_header_yet).attribute5                 :=lr_header_rec.attribute5;
      l_order_header_tbl(ln_arc_cnt_header_yet).attribute6                 :=lr_header_rec.attribute6;
      l_order_header_tbl(ln_arc_cnt_header_yet).attribute7                 :=lr_header_rec.attribute7;
      l_order_header_tbl(ln_arc_cnt_header_yet).attribute8                 :=lr_header_rec.attribute8;
      l_order_header_tbl(ln_arc_cnt_header_yet).attribute9                 :=lr_header_rec.attribute9;
      l_order_header_tbl(ln_arc_cnt_header_yet).attribute10                :=lr_header_rec.attribute10;
      l_order_header_tbl(ln_arc_cnt_header_yet).attribute11                :=lr_header_rec.attribute11;
      l_order_header_tbl(ln_arc_cnt_header_yet).attribute12                :=lr_header_rec.attribute12;
      l_order_header_tbl(ln_arc_cnt_header_yet).attribute13                :=lr_header_rec.attribute13;
      l_order_header_tbl(ln_arc_cnt_header_yet).attribute14                :=lr_header_rec.attribute14;
      l_order_header_tbl(ln_arc_cnt_header_yet).attribute15                :=lr_header_rec.attribute15;
      l_order_header_tbl(ln_arc_cnt_header_yet).global_attribute_category  :=lr_header_rec.global_attribute_category;
      l_order_header_tbl(ln_arc_cnt_header_yet).global_attribute1          :=lr_header_rec.global_attribute1;
      l_order_header_tbl(ln_arc_cnt_header_yet).global_attribute2          :=lr_header_rec.global_attribute2;
      l_order_header_tbl(ln_arc_cnt_header_yet).global_attribute3          :=lr_header_rec.global_attribute3;
      l_order_header_tbl(ln_arc_cnt_header_yet).global_attribute4          :=lr_header_rec.global_attribute4;
      l_order_header_tbl(ln_arc_cnt_header_yet).global_attribute5          :=lr_header_rec.global_attribute5;
      l_order_header_tbl(ln_arc_cnt_header_yet).global_attribute6          :=lr_header_rec.global_attribute6;
      l_order_header_tbl(ln_arc_cnt_header_yet).global_attribute7          :=lr_header_rec.global_attribute7;
      l_order_header_tbl(ln_arc_cnt_header_yet).global_attribute8          :=lr_header_rec.global_attribute8;
      l_order_header_tbl(ln_arc_cnt_header_yet).global_attribute9          :=lr_header_rec.global_attribute9;
      l_order_header_tbl(ln_arc_cnt_header_yet).global_attribute10         :=lr_header_rec.global_attribute10;
      l_order_header_tbl(ln_arc_cnt_header_yet).global_attribute11         :=lr_header_rec.global_attribute11;
      l_order_header_tbl(ln_arc_cnt_header_yet).global_attribute12         :=lr_header_rec.global_attribute12;
      l_order_header_tbl(ln_arc_cnt_header_yet).global_attribute13         :=lr_header_rec.global_attribute13;
      l_order_header_tbl(ln_arc_cnt_header_yet).global_attribute14         :=lr_header_rec.global_attribute14;
      l_order_header_tbl(ln_arc_cnt_header_yet).global_attribute15         :=lr_header_rec.global_attribute15;
      l_order_header_tbl(ln_arc_cnt_header_yet).global_attribute16         :=lr_header_rec.global_attribute16;
      l_order_header_tbl(ln_arc_cnt_header_yet).global_attribute17         :=lr_header_rec.global_attribute17;
      l_order_header_tbl(ln_arc_cnt_header_yet).global_attribute18         :=lr_header_rec.global_attribute18;
      l_order_header_tbl(ln_arc_cnt_header_yet).global_attribute19         :=lr_header_rec.global_attribute19;
      l_order_header_tbl(ln_arc_cnt_header_yet).global_attribute20         :=lr_header_rec.global_attribute20;
      l_order_header_tbl(ln_arc_cnt_header_yet).cancelled_flag             :=lr_header_rec.cancelled_flag;
      l_order_header_tbl(ln_arc_cnt_header_yet).open_flag                  :=lr_header_rec.open_flag;
      l_order_header_tbl(ln_arc_cnt_header_yet).booked_flag                :=lr_header_rec.booked_flag;
      l_order_header_tbl(ln_arc_cnt_header_yet).salesrep_id                :=lr_header_rec.salesrep_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).return_reason_code         :=lr_header_rec.return_reason_code;
      l_order_header_tbl(ln_arc_cnt_header_yet).order_date_type_code       :=lr_header_rec.order_date_type_code;
      l_order_header_tbl(ln_arc_cnt_header_yet).earliest_schedule_limit    :=lr_header_rec.earliest_schedule_limit;
      l_order_header_tbl(ln_arc_cnt_header_yet).latest_schedule_limit      :=lr_header_rec.latest_schedule_limit;
      l_order_header_tbl(ln_arc_cnt_header_yet).payment_type_code          :=lr_header_rec.payment_type_code;
      l_order_header_tbl(ln_arc_cnt_header_yet).payment_amount             :=lr_header_rec.payment_amount;
      l_order_header_tbl(ln_arc_cnt_header_yet).check_number               :=lr_header_rec.check_number;
      l_order_header_tbl(ln_arc_cnt_header_yet).credit_card_code           :=lr_header_rec.credit_card_code;
      l_order_header_tbl(ln_arc_cnt_header_yet).credit_card_holder_name    :=lr_header_rec.credit_card_holder_name;
      l_order_header_tbl(ln_arc_cnt_header_yet).credit_card_number         :=lr_header_rec.credit_card_number;
      l_order_header_tbl(ln_arc_cnt_header_yet).credit_card_expiration_date
                                                                           :=lr_header_rec.credit_card_expiration_date;
      l_order_header_tbl(ln_arc_cnt_header_yet).credit_card_approval_code  :=lr_header_rec.credit_card_approval_code;
      l_order_header_tbl(ln_arc_cnt_header_yet).sales_channel_code         :=lr_header_rec.sales_channel_code;
      l_order_header_tbl(ln_arc_cnt_header_yet).first_ack_code             :=lr_header_rec.first_ack_code;
      l_order_header_tbl(ln_arc_cnt_header_yet).first_ack_date             :=lr_header_rec.first_ack_date;
      l_order_header_tbl(ln_arc_cnt_header_yet).last_ack_code              :=lr_header_rec.last_ack_code;
      l_order_header_tbl(ln_arc_cnt_header_yet).last_ack_date              :=lr_header_rec.last_ack_date;
      l_order_header_tbl(ln_arc_cnt_header_yet).order_category_code        :=lr_header_rec.order_category_code;
      l_order_header_tbl(ln_arc_cnt_header_yet).change_sequence            :=lr_header_rec.change_sequence;
      l_order_header_tbl(ln_arc_cnt_header_yet).drop_ship_flag             :=lr_header_rec.drop_ship_flag;
      l_order_header_tbl(ln_arc_cnt_header_yet).customer_payment_term_id   :=lr_header_rec.customer_payment_term_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).shipping_instructions      :=lr_header_rec.shipping_instructions;
      l_order_header_tbl(ln_arc_cnt_header_yet).packing_instructions       :=lr_header_rec.packing_instructions;
      l_order_header_tbl(ln_arc_cnt_header_yet).tp_context                 :=lr_header_rec.tp_context;
      l_order_header_tbl(ln_arc_cnt_header_yet).tp_attribute1              :=lr_header_rec.tp_attribute1;
      l_order_header_tbl(ln_arc_cnt_header_yet).tp_attribute2              :=lr_header_rec.tp_attribute2;
      l_order_header_tbl(ln_arc_cnt_header_yet).tp_attribute3              :=lr_header_rec.tp_attribute3;
      l_order_header_tbl(ln_arc_cnt_header_yet).tp_attribute4              :=lr_header_rec.tp_attribute4;
      l_order_header_tbl(ln_arc_cnt_header_yet).tp_attribute5              :=lr_header_rec.tp_attribute5;
      l_order_header_tbl(ln_arc_cnt_header_yet).tp_attribute6              :=lr_header_rec.tp_attribute6;
      l_order_header_tbl(ln_arc_cnt_header_yet).tp_attribute7              :=lr_header_rec.tp_attribute7;
      l_order_header_tbl(ln_arc_cnt_header_yet).tp_attribute8              :=lr_header_rec.tp_attribute8;
      l_order_header_tbl(ln_arc_cnt_header_yet).tp_attribute9              :=lr_header_rec.tp_attribute9;
      l_order_header_tbl(ln_arc_cnt_header_yet).tp_attribute10             :=lr_header_rec.tp_attribute10;
      l_order_header_tbl(ln_arc_cnt_header_yet).tp_attribute11             :=lr_header_rec.tp_attribute11;
      l_order_header_tbl(ln_arc_cnt_header_yet).tp_attribute12             :=lr_header_rec.tp_attribute12;
      l_order_header_tbl(ln_arc_cnt_header_yet).tp_attribute13             :=lr_header_rec.tp_attribute13;
      l_order_header_tbl(ln_arc_cnt_header_yet).tp_attribute14             :=lr_header_rec.tp_attribute14;
      l_order_header_tbl(ln_arc_cnt_header_yet).tp_attribute15             :=lr_header_rec.tp_attribute15;
      l_order_header_tbl(ln_arc_cnt_header_yet).flow_status_code           :=lr_header_rec.flow_status_code;
      l_order_header_tbl(ln_arc_cnt_header_yet).marketing_source_code_id   :=lr_header_rec.marketing_source_code_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).credit_card_approval_date  :=lr_header_rec.credit_card_approval_date;
      l_order_header_tbl(ln_arc_cnt_header_yet).upgraded_flag              :=lr_header_rec.upgraded_flag;
      l_order_header_tbl(ln_arc_cnt_header_yet).customer_preference_set_code
                                                                          :=lr_header_rec.customer_preference_set_code;
      l_order_header_tbl(ln_arc_cnt_header_yet).booked_date                :=lr_header_rec.booked_date;
      l_order_header_tbl(ln_arc_cnt_header_yet).lock_control               :=lr_header_rec.lock_control;
      l_order_header_tbl(ln_arc_cnt_header_yet).price_request_code         :=lr_header_rec.price_request_code;
      l_order_header_tbl(ln_arc_cnt_header_yet).batch_id                   :=lr_header_rec.batch_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).xml_message_id             :=lr_header_rec.xml_message_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).accounting_rule_duration   :=lr_header_rec.accounting_rule_duration;
      l_order_header_tbl(ln_arc_cnt_header_yet).attribute16                :=lr_header_rec.attribute16;
      l_order_header_tbl(ln_arc_cnt_header_yet).attribute17                :=lr_header_rec.attribute17;
      l_order_header_tbl(ln_arc_cnt_header_yet).attribute18                :=lr_header_rec.attribute18;
      l_order_header_tbl(ln_arc_cnt_header_yet).attribute19                :=lr_header_rec.attribute19;
      l_order_header_tbl(ln_arc_cnt_header_yet).attribute20                :=lr_header_rec.attribute20;
      l_order_header_tbl(ln_arc_cnt_header_yet).blanket_number             :=lr_header_rec.blanket_number;
      l_order_header_tbl(ln_arc_cnt_header_yet).sales_document_type_code   :=lr_header_rec.sales_document_type_code;
      l_order_header_tbl(ln_arc_cnt_header_yet).sold_to_phone_id           :=lr_header_rec.sold_to_phone_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).fulfillment_set_name       :=lr_header_rec.fulfillment_set_name;
      l_order_header_tbl(ln_arc_cnt_header_yet).line_set_name              :=lr_header_rec.line_set_name;
      l_order_header_tbl(ln_arc_cnt_header_yet).default_fulfillment_set    :=lr_header_rec.default_fulfillment_set;
      l_order_header_tbl(ln_arc_cnt_header_yet).transaction_phase_code     :=lr_header_rec.transaction_phase_code;
      l_order_header_tbl(ln_arc_cnt_header_yet).sales_document_name        :=lr_header_rec.sales_document_name;
      l_order_header_tbl(ln_arc_cnt_header_yet).quote_number               :=lr_header_rec.quote_number;
      l_order_header_tbl(ln_arc_cnt_header_yet).quote_date                 :=lr_header_rec.quote_date;
      l_order_header_tbl(ln_arc_cnt_header_yet).user_status_code           :=lr_header_rec.user_status_code;
      l_order_header_tbl(ln_arc_cnt_header_yet).draft_submitted_flag       :=lr_header_rec.draft_submitted_flag;
      l_order_header_tbl(ln_arc_cnt_header_yet).source_document_version_number
                                                                      :=lr_header_rec.source_document_version_number;
      l_order_header_tbl(ln_arc_cnt_header_yet).sold_to_site_use_id        :=lr_header_rec.sold_to_site_use_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).supplier_signature         :=lr_header_rec.supplier_signature;
      l_order_header_tbl(ln_arc_cnt_header_yet).supplier_signature_date    :=lr_header_rec.supplier_signature_date;
      l_order_header_tbl(ln_arc_cnt_header_yet).customer_signature         :=lr_header_rec.customer_signature;
      l_order_header_tbl(ln_arc_cnt_header_yet).customer_signature_date    :=lr_header_rec.customer_signature_date;
      l_order_header_tbl(ln_arc_cnt_header_yet).minisite_id                :=lr_header_rec.minisite_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).end_customer_id            :=lr_header_rec.end_customer_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).end_customer_contact_id    :=lr_header_rec.end_customer_contact_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).end_customer_site_use_id   :=lr_header_rec.end_customer_site_use_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).ib_owner                   :=lr_header_rec.ib_owner;
      l_order_header_tbl(ln_arc_cnt_header_yet).ib_current_location        :=lr_header_rec.ib_current_location;
      l_order_header_tbl(ln_arc_cnt_header_yet).ib_installed_at_location   :=lr_header_rec.ib_installed_at_location;
      l_order_header_tbl(ln_arc_cnt_header_yet).order_firmed_date          :=lr_header_rec.order_firmed_date;
      l_order_header_tbl(ln_arc_cnt_header_yet).archive_date               :=SYSDATE;
      l_order_header_tbl(ln_arc_cnt_header_yet).archive_request_id         :=cn_request_id;
--
    END LOOP archive_order_header_loop;
--
    /*
    FORALL ln_idx IN 1..ln_未コミットバックアップ件数（受注ヘッダ（標準））
      INSERT INTO 受注ヘッダ（標準）バックアップ
      (
           全カラム
        , バックアップ登録日
        , バックアップ要求ID
      )
      VALUES
      (
          l_受注ヘッダ（標準）テーブル（ln_idx）全カラム
        , SYSDATE
        , 要求ID
      )
     */
    lv_process_part := '受注ヘッダ（標準）登録２';
    FORALL ln_idx IN 1..ln_arc_cnt_header_yet
      INSERT INTO xxcmn_oe_order_headers_all_arc VALUES l_order_header_tbl(ln_idx);
--
    /*
    l_受注ヘッダ（標準）テーブル．DELETE;
     */
    l_order_header_tbl.DELETE;
--
    /*
    FORALL ln_idx IN 1..ln_未コミットバックアップ件数（受注明細（標準））
      INSERT INTO 受注明細（標準）バックアップ
      (
          全カラム
        , バックアップ登録日
        , バックアップ要求ID
      )
      VALUES
      (
          受注明細（標準）テーブル（ln_idx）全カラム
        , SYSDATE
        , 要求ID
      )
     */
    lv_process_part := '受注明細（標準）登録２';
    FORALL ln_idx IN 1..ln_arc_cnt_line_yet
      INSERT INTO xxcmn_oe_order_lines_all_arc VALUES l_order_line_tbl(ln_idx);
--
    /*
    l_受注明細（標準）テーブル．DELETE;
     */
    l_order_line_tbl.DELETE;
--
    /*
    gn_バックアップ件数（受注ヘッダ（標準）） := gn_バックアップ件数（受注ヘッダ（標準））
       + ln_未コミットバックアップ件数（受注ヘッダ（標準））;
    ln_未コミットバックアップ件数（受注ヘッダ（標準）） := 0;
    */
    gn_arc_cnt_header     := gn_arc_cnt_header + ln_arc_cnt_header_yet;
    ln_arc_cnt_header_yet := 0;
--
    /*
    gn_バックアップ件数（受注明細（標準）） := gn_バックアップ件数（受注明細（標準））
      + ln_未コミットバックアップ件数（受注明細（標準））;
    ln_未コミットバックアップ件数（受注明細（標準）） := 0;
    */
    gn_arc_cnt_line     := gn_arc_cnt_line + ln_arc_cnt_line_yet;
    ln_arc_cnt_line_yet := 0;
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
          IF ( l_order_header_tbl.COUNT > 0 ) THEN
            lt_header_id := l_order_header_tbl(SQL%BULK_EXCEPTIONS(1).ERROR_INDEX).header_id;
            ov_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name
                          ,iv_name         => cv_local_others_hdr_msg
                          ,iv_token_name1  => cv_token_key
                          ,iv_token_value1 => TO_CHAR(lt_header_id)
                         );
--
          ELSIF ( l_order_line_tbl.COUNT > 0 ) THEN
            lt_line_id := l_order_line_tbl(SQL%BULK_EXCEPTIONS(1).ERROR_INDEX).line_id;
            ov_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name
                          ,iv_name         => cv_local_others_line_msg
                          ,iv_token_name1  => cv_token_key
                          ,iv_token_value1 => TO_CHAR(lt_line_id)
                         );
          END IF;
        END IF;
      EXCEPTION
        WHEN not_init_collection_expt THEN
          NULL;
      END;
--
      IF ( (ov_errmsg IS NULL) AND (lt_header_id IS NOT NULL) ) THEN
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_local_others_hdr_msg
                      ,iv_token_name1  => cv_token_key
                      ,iv_token_value1 => TO_CHAR(lt_header_id)
                     );
--
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
    cv_tblname_head    CONSTANT VARCHAR2(100) := '受注ヘッダ(標準)';
    cv_tblname_line    CONSTANT VARCHAR2(100) := '受注明細(標準)';
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
    --バックアップ件数(受注ヘッダ(標準))出力
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
    --バックアップ件数(受注明細(標準))出力
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
END XXCMN960003C;
/
