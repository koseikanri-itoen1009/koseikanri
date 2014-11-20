CREATE OR REPLACE PACKAGE BODY APPS.XXCCP120A01C
AS
/*****************************************************************************************
 *
 * Package Name     : XXCCP120A01C(spec)
 * Description      : 受入取引OIF自動リカバリ
 * Version          : 1.00
 *
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/07/31    1.00  SCSK 小野塚香織 新規作成
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
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
  resource_busy_expt        EXCEPTION; -- ロック取得エラー
  error_proc_expt           EXCEPTION; -- エラー終了
  warning_skip_expt         EXCEPTION; -- 警告スキップ
  PRAGMA EXCEPTION_INIT( resource_busy_expt, -54 );
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  -- アプリケーション短縮名
  cv_appl_short_name_xxccp  CONSTANT VARCHAR2(10) := 'XXCCP';
  -- パッケージ名
  cv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCCP120A01C'; -- パッケージ名
  -- メッセージコード
  cv_msg_ccp_10022          CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10022'; -- 起動対象コンカレントの起動失敗エラー
  cv_msg_ccp_10023          CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10023'; -- コンカレント取得失敗エラー
  cv_msg_ccp_10026          CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10026'; -- コンカレント異常終了
  cv_msg_ccp_10028          CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10028'; -- コンカレントエラー終了
  cv_msg_ccp_10030          CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10030'; -- コンカレント警告終了
  cv_msg_ccp_10032          CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10032'; -- プロファイル取得エラー
--
  -- 参照タイプ名
  cv_lookup_type_01         CONSTANT VARCHAR2(30)  := 'XXCCP1_ERR_GMI_IC_LOCT_INV'; -- OIFエラーメッセージ
  -- 有効フラグ
  cv_flg_y                  CONSTANT VARCHAR2(1)   := 'Y';     -- 有効
  -- 日付フォーマット
  cv_format_dd              CONSTANT VARCHAR2(2)   := 'DD';
  -- データ抽出条件値
  cv_error                  CONSTANT VARCHAR2(5)   := 'ERROR'; -- エラー
  -- データ更新値
  cv_status_code            CONSTANT VARCHAR2(7)   := 'PENDING';
  -- トークンコード
  cv_tkn_req_id             CONSTANT VARCHAR2(20)  := 'REQ_ID';
  cv_tkn_phase              CONSTANT VARCHAR2(20)  := 'PHASE';
  cv_tkn_status             CONSTANT VARCHAR2(20)  := 'STATUS';
  cv_tkn_count              CONSTANT VARCHAR2(20)  := 'COUNT';
  cv_tkn_profile_name       CONSTANT VARCHAR2(20)  := 'PROFILE_NAME';
  -- プロファイル名
  cv_profile_watch_time     CONSTANT VARCHAR2(30)  := 'XXCCP1_DYNAM_CONC_WATCH_TIME'; -- 監視間隔
  -- 更新対象テーブル名称
  cv_upd_head_tbl_name      CONSTANT VARCHAR2(30)  := '受入取引ヘッダOIF';
  cv_upd_trn_tbl_name       CONSTANT VARCHAR2(30)  := '受入取引OIF';
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_process_date           DATE   DEFAULT NULL;       -- 業務処理日付
  gn_head_upd_cnt           NUMBER DEFAULT 0;          -- 受入取引ヘッダOIF更新件数
  gn_trn_upd_cnt            NUMBER DEFAULT 0;          -- 受入取引OIF更新件数
--
  --==================================================
  -- グローバルカーソル
  --==================================================
  -- 受入取引OIF情報(ステータスがエラーのデータを抽出)
  CURSOR g_rcv_trn_if_cur
  IS
    SELECT  rti.interface_transaction_id
           ,rti.group_id
           ,rti.header_interface_id
    FROM   rcv_transactions_interface rti
    WHERE  rti.transaction_status_code = cv_error
    ORDER BY rti.group_id
  ;
  --
  TYPE g_rcv_trn_if_ttype IS TABLE OF g_rcv_trn_if_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  g_rcv_trn_if_tab g_rcv_trn_if_ttype;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
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
    --コンカレント定数
    cv_application           CONSTANT VARCHAR2(5)   := 'PO';            -- Application
    cv_program               CONSTANT VARCHAR2(12)  := 'RVCTP';         -- Program
    cv_description           CONSTANT VARCHAR2(9)   := NULL;            -- Description
    cv_start_time            CONSTANT VARCHAR2(10)  := NULL;            -- Start_time
    cb_sub_request           CONSTANT BOOLEAN       := FALSE;           -- Sub_request
    -- コンカレント終了ステータス
    cv_con_status_complete   CONSTANT VARCHAR2(20)  := 'COMPLETE';      -- ステータス（完了）
    cv_con_status_normal     CONSTANT VARCHAR2(10)  := 'NORMAL';        -- ステータス（正常）
    cv_con_status_error      CONSTANT VARCHAR2(10)  := 'ERROR';         -- ステータス（異常）
    cv_con_status_warning    CONSTANT VARCHAR2(10)  := 'WARNING';       -- ステータス（警告）
--                                                                      
    -- *** ローカル変数 ***
    lv_outmsg                VARCHAR2(5000) DEFAULT NULL;               -- 出力用メッセージ
    ln_oiferr_trn_id         po_interface_errors.interface_transaction_id%TYPE;
    lb_wait_result           BOOLEAN;                   -- コンカレント待機成否
    lv_phase                 VARCHAR2(50)   DEFAULT NULL;
    lv_status                VARCHAR2(50)   DEFAULT NULL;
    lv_dev_phase             VARCHAR2(50)   DEFAULT NULL;
    lv_dev_status            VARCHAR2(50)   DEFAULT NULL;
    lv_message               VARCHAR2(5000) DEFAULT NULL;
    lv_watch_time            VARCHAR2(255)  DEFAULT NULL;
    ln_request_id            NUMBER;
    ln_head_upd_cnt          NUMBER         DEFAULT 0;
    ln_trn_upd_cnt           NUMBER         DEFAULT 0;
--
    -- ===============================================
    -- ローカル例外処理
    -- ===============================================
    submit_err_expt          EXCEPTION;
    submit_warn_expt         EXCEPTION;
    get_err_profile_expt     EXCEPTION;
    err_update_expt          EXCEPTION;
--
    -- ===============================================
    -- ロック取得用カーソル
    -- ===============================================
    -- 受入取引ヘッダOIF
    CURSOR l_head_upd_cur(
             in_head_int_id IN NUMBER
            ,in_group_id    IN NUMBER)
    IS
      SELECT rhi.header_interface_id
            ,rhi.group_id
            ,rhi.edi_control_num
            ,rhi.processing_status_code
            ,rhi.receipt_source_code
            ,rhi.asn_type
            ,rhi.transaction_type
            ,rhi.auto_transact_code
            ,rhi.test_flag
            ,rhi.last_update_date
            ,rhi.last_updated_by
            ,rhi.last_update_login
            ,rhi.creation_date
            ,rhi.created_by
            ,rhi.notice_creation_date
            ,rhi.shipment_num
            ,rhi.receipt_num
            ,rhi.receipt_header_id
            ,rhi.vendor_name
            ,rhi.vendor_num
            ,rhi.vendor_id
            ,rhi.vendor_site_code
            ,rhi.vendor_site_id
            ,rhi.from_organization_code
            ,rhi.from_organization_id
            ,rhi.ship_to_organization_code
            ,rhi.ship_to_organization_id
            ,rhi.location_code
            ,rhi.location_id
            ,rhi.bill_of_lading
            ,rhi.packing_slip
            ,rhi.shipped_date
            ,rhi.freight_carrier_code
            ,rhi.expected_receipt_date
            ,rhi.receiver_id
            ,rhi.num_of_containers
            ,rhi.waybill_airbill_num
            ,rhi.comments
            ,rhi.gross_weight
            ,rhi.gross_weight_uom_code
            ,rhi.net_weight
            ,rhi.net_weight_uom_code
            ,rhi.tar_weight
            ,rhi.tar_weight_uom_code
            ,rhi.packaging_code
            ,rhi.carrier_method
            ,rhi.carrier_equipment
            ,rhi.special_handling_code
            ,rhi.hazard_code
            ,rhi.hazard_class
            ,rhi.hazard_description
            ,rhi.freight_terms
            ,rhi.freight_bill_number
            ,rhi.invoice_num
            ,rhi.invoice_date
            ,rhi.total_invoice_amount
            ,rhi.tax_name
            ,rhi.tax_amount
            ,rhi.freight_amount
            ,rhi.currency_code
            ,rhi.conversion_rate_type
            ,rhi.conversion_rate
            ,rhi.conversion_rate_date
            ,rhi.payment_terms_name
            ,rhi.payment_terms_id
            ,rhi.attribute_category
            ,rhi.attribute1
            ,rhi.attribute2
            ,rhi.attribute3
            ,rhi.attribute4
            ,rhi.attribute5
            ,rhi.employee_name
            ,rhi.employee_id
            ,rhi.invoice_status_code
            ,rhi.validation_flag
            ,rhi.processing_request_id
            ,rhi.customer_account_number
            ,rhi.customer_id
            ,rhi.customer_site_id
            ,rhi.customer_party_name
            ,rhi.remit_to_site_id
      FROM   rcv_headers_interface rhi
      WHERE  rhi.header_interface_id = in_head_int_id
      AND    rhi.group_id            = in_group_id
      FOR UPDATE OF rhi.header_interface_id NOWAIT;
    TYPE l_head_upd_ttype IS TABLE OF l_head_upd_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    l_head_upd_tab l_head_upd_ttype;
--
    -- 受入取引OIF
    CURSOR l_trn_upd_cur(
             in_int_trn_id IN NUMBER
            ,in_group_id   IN NUMBER)
    IS
      SELECT rti.interface_transaction_id
            ,rti.group_id
            ,rti.last_update_date
            ,rti.last_updated_by
            ,rti.creation_date
            ,rti.created_by
            ,rti.last_update_login
            ,rti.request_id
            ,rti.program_application_id
            ,rti.program_id
            ,rti.program_update_date
            ,rti.transaction_type
            ,rti.transaction_date
            ,rti.processing_status_code
            ,rti.processing_mode_code
            ,rti.processing_request_id
            ,rti.transaction_status_code
            ,rti.category_id
            ,rti.quantity
            ,rti.unit_of_measure
            ,rti.interface_source_code
            ,rti.interface_source_line_id
            ,rti.inv_transaction_id
            ,rti.item_id
            ,rti.item_description
            ,rti.item_revision
            ,rti.uom_code
            ,rti.employee_id
            ,rti.auto_transact_code
            ,rti.shipment_header_id
            ,rti.shipment_line_id
            ,rti.ship_to_location_id
            ,rti.primary_quantity
            ,rti.primary_unit_of_measure
            ,rti.receipt_source_code
            ,rti.vendor_id
            ,rti.vendor_site_id
            ,rti.from_organization_id
            ,rti.from_subinventory
            ,rti.to_organization_id
            ,rti.intransit_owning_org_id
            ,rti.routing_header_id
            ,rti.routing_step_id
            ,rti.source_document_code
            ,rti.parent_transaction_id
            ,rti.po_header_id
            ,rti.po_revision_num
            ,rti.po_release_id
            ,rti.po_line_id
            ,rti.po_line_location_id
            ,rti.po_unit_price
            ,rti.currency_code
            ,rti.currency_conversion_type
            ,rti.currency_conversion_rate
            ,rti.currency_conversion_date
            ,rti.po_distribution_id
            ,rti.requisition_line_id
            ,rti.req_distribution_id
            ,rti.charge_account_id
            ,rti.substitute_unordered_code
            ,rti.receipt_exception_flag
            ,rti.accrual_status_code
            ,rti.inspection_status_code
            ,rti.inspection_quality_code
            ,rti.destination_type_code
            ,rti.deliver_to_person_id
            ,rti.location_id
            ,rti.deliver_to_location_id
            ,rti.subinventory
            ,rti.locator_id
            ,rti.wip_entity_id
            ,rti.expected_receipt_date
            ,rti.actual_cost
            ,rti.transfer_cost
            ,rti.transportation_cost
            ,rti.transportation_account_id
            ,rti.num_of_containers
            ,rti.waybill_airbill_num
            ,rti.vendor_item_num
            ,rti.vendor_lot_num
            ,rti.rma_reference
            ,rti.comments
            ,rti.ship_line_attribute1
            ,rti.header_interface_id
            ,rti.order_transaction_id
            ,rti.customer_account_number
            ,rti.customer_party_name
            ,rti.oe_order_line_num
            ,rti.oe_order_num
            ,rti.parent_interface_txn_id
            ,rti.customer_item_id
            ,rti.amount
            ,rti.job_id
            ,rti.timecard_id
            ,rti.timecard_ovn
            ,rti.erecord_id
            ,rti.project_id
            ,rti.task_id
            ,rti.asn_attach_id
      FROM   rcv_transactions_interface rti
      WHERE  rti.interface_transaction_id = in_int_trn_id
      AND    rti.group_id                 = in_group_id
      FOR UPDATE OF rti.interface_transaction_id NOWAIT;
    TYPE l_trn_upd_ttype IS TABLE OF l_trn_upd_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    l_trn_upd_tab l_trn_upd_ttype;
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
--
    --==================================================
    -- 業務処理日付取得
    --==================================================
    gd_process_date := TRUNC( xxccp_common_pkg2.get_process_date );
--
    --==================================================
    -- 動的パラメータコンカレントステータス監視間隔の取得
    --==================================================
    lv_watch_time := FND_PROFILE.VALUE(cv_profile_watch_time);
--
    --コンカレントステータス監視間隔出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => 'コンカレントステータス監視間隔  ：  ' || lv_watch_time
    );
    IF ( lv_watch_time IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name_xxccp
                    ,iv_name         => cv_msg_ccp_10032
                    ,iv_token_name1  => cv_tkn_profile_name
                    ,iv_token_value1 => cv_profile_watch_time
                   );
      lv_errbuf := lv_errmsg;
      RAISE get_err_profile_expt;
    END IF;
--
    -- ===============================================
    -- 受入取引OIF情報抽出処理
    -- ===============================================
    -- 受入取引OIF情報取得カーソル
    OPEN g_rcv_trn_if_cur;
    FETCH g_rcv_trn_if_cur BULK COLLECT INTO g_rcv_trn_if_tab;
    CLOSE g_rcv_trn_if_cur;
    
    <<main_loop>>
    FOR i IN 1 .. g_rcv_trn_if_tab.COUNT LOOP
      -- 一時退避用更新件数の初期化
      ln_head_upd_cnt := 0;
      ln_trn_upd_cnt  := 0;
      --
      -- ===============================================
      -- OIFエラー情報抽出処理
      -- ===============================================
      BEGIN
        SELECT  pie.interface_transaction_id
        INTO    ln_oiferr_trn_id
        FROM    po_interface_errors  pie
        WHERE   pie.interface_transaction_id = g_rcv_trn_if_tab( i ).interface_transaction_id
        AND     EXISTS(SELECT 'X'
                       FROM   fnd_lookup_values_vl flvv
                       WHERE  flvv.lookup_type  = cv_lookup_type_01
                       AND    flvv.description  = pie.error_message 
                       AND    flvv.enabled_flag = cv_flg_y
                       AND    gd_process_date BETWEEN NVL( flvv.start_date_active, gd_process_date )
                                                  AND NVL( flvv.end_date_active  , gd_process_date )
                      )
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          ln_oiferr_trn_id := NULL;
      END;
--
      IF ( ln_oiferr_trn_id IS NOT NULL ) THEN
        -- 更新対象が存在する場合、終了ステータスを「警告」とする
        ov_retcode := cv_status_warn;
        -- ===============================================
        -- 更新処理
        -- ===============================================
        -- 更新対象データロック
        -- 受入取引ヘッダOIF
        OPEN  l_head_upd_cur(
                g_rcv_trn_if_tab( i ).header_interface_id
               ,g_rcv_trn_if_tab( i ).group_id
              );
        -- 更新前の値を出力する為、対象データを取得
        FETCH l_head_upd_cur BULK COLLECT INTO l_head_upd_tab;
        CLOSE l_head_upd_cur;
--
        -- 受入取引OIF
        OPEN  l_trn_upd_cur(
                g_rcv_trn_if_tab( i ).interface_transaction_id
               ,g_rcv_trn_if_tab( i ).group_id
              );
        -- 更新前の値を出力する為、対象データを取得
        FETCH l_trn_upd_cur BULK COLLECT INTO l_trn_upd_tab;
        CLOSE l_trn_upd_cur;
--
        IF ( g_rcv_trn_if_tab( i ).header_interface_id IS NOT NULL ) THEN
          -- ===============================================
          -- 受入取引ヘッダOIF更新処理
          -- ===============================================
          -- 更新前データ出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => '"更新前 ( 受入取引ヘッダOIF )"'
          );
          --更新対象項目名称及びキー情報出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => '"header_interface_id","group_id","edi_control_num","processing_status_code","receipt_source_code",' ||
                       '"asn_type","transaction_type","auto_transact_code","test_flag","last_update_date","last_updated_by",' ||
                       '"last_update_login","creation_date","created_by","notice_creation_date","shipment_num","receipt_num",' ||
                       '"receipt_header_id","vendor_name","vendor_num","vendor_id","vendor_site_code","vendor_site_id",' ||
                       '"from_organization_code","from_organization_id","ship_to_organization_code","ship_to_organization_id",' ||
                       '"location_code","location_id","bill_of_lading","packing_slip","shipped_date","freight_carrier_code",' ||
                       '"expected_receipt_date","receiver_id","num_of_containers","waybill_airbill_num","comments","gross_weight",' ||
                       '"gross_weight_uom_code","net_weight","net_weight_uom_code","tar_weight","tar_weight_uom_code",' ||
                       '"packaging_code","carrier_method","carrier_equipment","special_handling_code","hazard_code","hazard_class",' ||
                       '"hazard_description","freight_terms","freight_bill_number","invoice_num","invoice_date",' ||
                       '"total_invoice_amount","tax_name","tax_amount","freight_amount","currency_code","conversion_rate_type",' ||
                       '"conversion_rate","conversion_rate_date","payment_terms_name","payment_terms_id","attribute_category",' ||
                       '"attribute1","attribute2","attribute3","attribute4","attribute5","employee_name","employee_id",' ||
                       '"invoice_status_code","validation_flag","processing_request_id","customer_account_number","customer_id",' ||
                       '"customer_site_id","customer_party_name","remit_to_site_id"'
          );
          --更新項目値及びキー情報出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => '"'|| l_head_upd_tab(1).header_interface_id        || '","' ||
                             l_head_upd_tab(1).group_id                   || '","' ||
                             l_head_upd_tab(1).edi_control_num            || '","' ||
                             l_head_upd_tab(1).processing_status_code     || '","' ||
                             l_head_upd_tab(1).receipt_source_code        || '","' ||
                             l_head_upd_tab(1).asn_type                   || '","' ||
                             l_head_upd_tab(1).transaction_type           || '","' ||
                             l_head_upd_tab(1).auto_transact_code         || '","' ||
                             l_head_upd_tab(1).test_flag                  || '","' ||
                             l_head_upd_tab(1).last_update_date           || '","' ||
                             l_head_upd_tab(1).last_updated_by            || '","' ||
                             l_head_upd_tab(1).last_update_login          || '","' ||
                             l_head_upd_tab(1).creation_date              || '","' ||
                             l_head_upd_tab(1).created_by                 || '","' ||
                             l_head_upd_tab(1).notice_creation_date       || '","' ||
                             l_head_upd_tab(1).shipment_num               || '","' ||
                             l_head_upd_tab(1).receipt_num                || '","' ||
                             l_head_upd_tab(1).receipt_header_id          || '","' ||
                             l_head_upd_tab(1).vendor_name                || '","' ||
                             l_head_upd_tab(1).vendor_num                 || '","' ||
                             l_head_upd_tab(1).vendor_id                  || '","' ||
                             l_head_upd_tab(1).vendor_site_code           || '","' ||
                             l_head_upd_tab(1).vendor_site_id             || '","' ||
                             l_head_upd_tab(1).from_organization_code     || '","' ||
                             l_head_upd_tab(1).from_organization_id       || '","' ||
                             l_head_upd_tab(1).ship_to_organization_code  || '","' ||
                             l_head_upd_tab(1).ship_to_organization_id    || '","' ||
                             l_head_upd_tab(1).location_code              || '","' ||
                             l_head_upd_tab(1).location_id                || '","' ||
                             l_head_upd_tab(1).bill_of_lading             || '","' ||
                             l_head_upd_tab(1).packing_slip               || '","' ||
                             l_head_upd_tab(1).shipped_date               || '","' ||
                             l_head_upd_tab(1).freight_carrier_code       || '","' ||
                             l_head_upd_tab(1).expected_receipt_date      || '","' ||
                             l_head_upd_tab(1).receiver_id                || '","' ||
                             l_head_upd_tab(1).num_of_containers          || '","' ||
                             l_head_upd_tab(1).waybill_airbill_num        || '","' ||
                             l_head_upd_tab(1).comments                   || '","' ||
                             l_head_upd_tab(1).gross_weight               || '","' ||
                             l_head_upd_tab(1).gross_weight_uom_code      || '","' ||
                             l_head_upd_tab(1).net_weight                 || '","' ||
                             l_head_upd_tab(1).net_weight_uom_code        || '","' ||
                             l_head_upd_tab(1).tar_weight                 || '","' ||
                             l_head_upd_tab(1).tar_weight_uom_code        || '","' ||
                             l_head_upd_tab(1).packaging_code             || '","' ||
                             l_head_upd_tab(1).carrier_method             || '","' ||
                             l_head_upd_tab(1).carrier_equipment          || '","' ||
                             l_head_upd_tab(1).special_handling_code      || '","' ||
                             l_head_upd_tab(1).hazard_code                || '","' ||
                             l_head_upd_tab(1).hazard_class               || '","' ||
                             l_head_upd_tab(1).hazard_description         || '","' ||
                             l_head_upd_tab(1).freight_terms              || '","' ||
                             l_head_upd_tab(1).freight_bill_number        || '","' ||
                             l_head_upd_tab(1).invoice_num                || '","' ||
                             l_head_upd_tab(1).invoice_date               || '","' ||
                             l_head_upd_tab(1).total_invoice_amount       || '","' ||
                             l_head_upd_tab(1).tax_name                   || '","' ||
                             l_head_upd_tab(1).tax_amount                 || '","' ||
                             l_head_upd_tab(1).freight_amount             || '","' ||
                             l_head_upd_tab(1).currency_code              || '","' ||
                             l_head_upd_tab(1).conversion_rate_type       || '","' ||
                             l_head_upd_tab(1).conversion_rate            || '","' ||
                             l_head_upd_tab(1).conversion_rate_date       || '","' ||
                             l_head_upd_tab(1).payment_terms_name         || '","' ||
                             l_head_upd_tab(1).payment_terms_id           || '","' ||
                             l_head_upd_tab(1).attribute_category         || '","' ||
                             l_head_upd_tab(1).attribute1                 || '","' ||
                             l_head_upd_tab(1).attribute2                 || '","' ||
                             l_head_upd_tab(1).attribute3                 || '","' ||
                             l_head_upd_tab(1).attribute4                 || '","' ||
                             l_head_upd_tab(1).attribute5                 || '","' ||
                             l_head_upd_tab(1).employee_name              || '","' ||
                             l_head_upd_tab(1).employee_id                || '","' ||
                             l_head_upd_tab(1).invoice_status_code        || '","' ||
                             l_head_upd_tab(1).validation_flag            || '","' ||
                             l_head_upd_tab(1).processing_request_id      || '","' ||
                             l_head_upd_tab(1).customer_account_number    || '","' ||
                             l_head_upd_tab(1).customer_id                || '","' ||
                             l_head_upd_tab(1).customer_site_id           || '","' ||
                             l_head_upd_tab(1).customer_party_name        || '","' ||
                             l_head_upd_tab(1).remit_to_site_id           || '"'
          );
--
          BEGIN
            UPDATE rcv_headers_interface
            SET    processing_status_code   = cv_status_code
                 , receipt_header_id        = NULL
                 , validation_flag          = cv_flg_y
                 , last_updated_by          = cn_last_updated_by            -- ログインユーザーID
                 , last_update_date         = cd_last_update_date           -- システム日付
                 , last_update_login        = cn_last_update_login          -- ログインID
            WHERE  header_interface_id      = g_rcv_trn_if_tab( i ).header_interface_id
            AND    group_id                 = g_rcv_trn_if_tab( i ).group_id
            ;
            -- 更新件数カウント(退避用変数)
            ln_head_upd_cnt := ln_head_upd_cnt + 1;
--
          EXCEPTION
            -- *** データ更新エラー ***
            WHEN OTHERS THEN
              ov_errmsg  := '更新処理に失敗しました。(受入取引ヘッダOIF)';
              ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
              RAISE err_update_expt;
          END;
--
          -- 更新後データ出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => '"更新後 ( 受入取引ヘッダOIF )"'
          );
          --更新対象項目名称及びキー情報出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => '"header_interface_id","group_id","edi_control_num","processing_status_code","receipt_source_code",' ||
                       '"asn_type","transaction_type","auto_transact_code","test_flag","last_update_date","last_updated_by",' ||
                       '"last_update_login","creation_date","created_by","notice_creation_date","shipment_num","receipt_num",' ||
                       '"receipt_header_id","vendor_name","vendor_num","vendor_id","vendor_site_code","vendor_site_id",' ||
                       '"from_organization_code","from_organization_id","ship_to_organization_code","ship_to_organization_id",' ||
                       '"location_code","location_id","bill_of_lading","packing_slip","shipped_date","freight_carrier_code",' ||
                       '"expected_receipt_date","receiver_id","num_of_containers","waybill_airbill_num","comments","gross_weight",' ||
                       '"gross_weight_uom_code","net_weight","net_weight_uom_code","tar_weight","tar_weight_uom_code",' ||
                       '"packaging_code","carrier_method","carrier_equipment","special_handling_code","hazard_code","hazard_class",' ||
                       '"hazard_description","freight_terms","freight_bill_number","invoice_num","invoice_date",' ||
                       '"total_invoice_amount","tax_name","tax_amount","freight_amount","currency_code","conversion_rate_type",' ||
                       '"conversion_rate","conversion_rate_date","payment_terms_name","payment_terms_id","attribute_category",' ||
                       '"attribute1","attribute2","attribute3","attribute4","attribute5","employee_name","employee_id",' ||
                       '"invoice_status_code","validation_flag","processing_request_id","customer_account_number","customer_id",' ||
                       '"customer_site_id","customer_party_name","remit_to_site_id"'
          );
          --更新項目値及びキー情報出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => '"'|| l_head_upd_tab(1).header_interface_id        || '","' ||
                             l_head_upd_tab(1).group_id                   || '","' ||
                             l_head_upd_tab(1).edi_control_num            || '","' ||
                             cv_status_code                               || '","' || -- 処理ステータス
                             l_head_upd_tab(1).receipt_source_code        || '","' ||
                             l_head_upd_tab(1).asn_type                   || '","' ||
                             l_head_upd_tab(1).transaction_type           || '","' ||
                             l_head_upd_tab(1).auto_transact_code         || '","' ||
                             l_head_upd_tab(1).test_flag                  || '","' ||
                             l_head_upd_tab(1).last_update_date           || '","' ||
                             l_head_upd_tab(1).last_updated_by            || '","' ||
                             l_head_upd_tab(1).last_update_login          || '","' ||
                             l_head_upd_tab(1).creation_date              || '","' ||
                             l_head_upd_tab(1).created_by                 || '","' ||
                             l_head_upd_tab(1).notice_creation_date       || '","' ||
                             l_head_upd_tab(1).shipment_num               || '","' ||
                             l_head_upd_tab(1).receipt_num                || '","' ||
                             NULL                                         || '","' || -- 受取ヘッダID
                             l_head_upd_tab(1).vendor_name                || '","' ||
                             l_head_upd_tab(1).vendor_num                 || '","' ||
                             l_head_upd_tab(1).vendor_id                  || '","' ||
                             l_head_upd_tab(1).vendor_site_code           || '","' ||
                             l_head_upd_tab(1).vendor_site_id             || '","' ||
                             l_head_upd_tab(1).from_organization_code     || '","' ||
                             l_head_upd_tab(1).from_organization_id       || '","' ||
                             l_head_upd_tab(1).ship_to_organization_code  || '","' ||
                             l_head_upd_tab(1).ship_to_organization_id    || '","' ||
                             l_head_upd_tab(1).location_code              || '","' ||
                             l_head_upd_tab(1).location_id                || '","' ||
                             l_head_upd_tab(1).bill_of_lading             || '","' ||
                             l_head_upd_tab(1).packing_slip               || '","' ||
                             l_head_upd_tab(1).shipped_date               || '","' ||
                             l_head_upd_tab(1).freight_carrier_code       || '","' ||
                             l_head_upd_tab(1).expected_receipt_date      || '","' ||
                             l_head_upd_tab(1).receiver_id                || '","' ||
                             l_head_upd_tab(1).num_of_containers          || '","' ||
                             l_head_upd_tab(1).waybill_airbill_num        || '","' ||
                             l_head_upd_tab(1).comments                   || '","' ||
                             l_head_upd_tab(1).gross_weight               || '","' ||
                             l_head_upd_tab(1).gross_weight_uom_code      || '","' ||
                             l_head_upd_tab(1).net_weight                 || '","' ||
                             l_head_upd_tab(1).net_weight_uom_code        || '","' ||
                             l_head_upd_tab(1).tar_weight                 || '","' ||
                             l_head_upd_tab(1).tar_weight_uom_code        || '","' ||
                             l_head_upd_tab(1).packaging_code             || '","' ||
                             l_head_upd_tab(1).carrier_method             || '","' ||
                             l_head_upd_tab(1).carrier_equipment          || '","' ||
                             l_head_upd_tab(1).special_handling_code      || '","' ||
                             l_head_upd_tab(1).hazard_code                || '","' ||
                             l_head_upd_tab(1).hazard_class               || '","' ||
                             l_head_upd_tab(1).hazard_description         || '","' ||
                             l_head_upd_tab(1).freight_terms              || '","' ||
                             l_head_upd_tab(1).freight_bill_number        || '","' ||
                             l_head_upd_tab(1).invoice_num                || '","' ||
                             l_head_upd_tab(1).invoice_date               || '","' ||
                             l_head_upd_tab(1).total_invoice_amount       || '","' ||
                             l_head_upd_tab(1).tax_name                   || '","' ||
                             l_head_upd_tab(1).tax_amount                 || '","' ||
                             l_head_upd_tab(1).freight_amount             || '","' ||
                             l_head_upd_tab(1).currency_code              || '","' ||
                             l_head_upd_tab(1).conversion_rate_type       || '","' ||
                             l_head_upd_tab(1).conversion_rate            || '","' ||
                             l_head_upd_tab(1).conversion_rate_date       || '","' ||
                             l_head_upd_tab(1).payment_terms_name         || '","' ||
                             l_head_upd_tab(1).payment_terms_id           || '","' ||
                             l_head_upd_tab(1).attribute_category         || '","' ||
                             l_head_upd_tab(1).attribute1                 || '","' ||
                             l_head_upd_tab(1).attribute2                 || '","' ||
                             l_head_upd_tab(1).attribute3                 || '","' ||
                             l_head_upd_tab(1).attribute4                 || '","' ||
                             l_head_upd_tab(1).attribute5                 || '","' ||
                             l_head_upd_tab(1).employee_name              || '","' ||
                             l_head_upd_tab(1).employee_id                || '","' ||
                             l_head_upd_tab(1).invoice_status_code        || '","' ||
                             cv_flg_y                                     || '","' || -- 有効フラグ
                             l_head_upd_tab(1).processing_request_id      || '","' ||
                             l_head_upd_tab(1).customer_account_number    || '","' ||
                             l_head_upd_tab(1).customer_id                || '","' ||
                             l_head_upd_tab(1).customer_site_id           || '","' ||
                             l_head_upd_tab(1).customer_party_name        || '","' ||
                             l_head_upd_tab(1).remit_to_site_id           || '"'
          );
        END IF;
--
        IF ( l_trn_upd_tab.COUNT <= 1 ) THEN
          -- ===============================================
          -- 受入取引OIF更新処理
          -- ===============================================
          -- 更新前データ出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => '"更新前 ( 受入取引OIF )"'
          );
          --更新対象項目名称及びキー情報出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => '"interface_transaction_id","group_id","last_update_date","last_updated_by","creation_date","created_by",' ||
                       '"last_update_login","request_id","program_application_id","program_id","program_update_date","transaction_type",' ||
                       '"transaction_date","processing_status_code","processing_mode_code","processing_request_id",' ||
                       '"transaction_status_code","category_id","quantity","unit_of_measure","interface_source_code",' ||
                       '"interface_source_line_id","inv_transaction_id","item_id","item_description","item_revision","uom_code",' ||
                       '"employee_id","auto_transact_code","shipment_header_id","shipment_line_id","ship_to_location_id",' ||
                       '"primary_quantity","primary_unit_of_measure","receipt_source_code","vendor_id","vendor_site_id",' ||
                       '"from_organization_id","from_subinventory","to_organization_id","intransit_owning_org_id","routing_header_id",' ||
                       '"routing_step_id","source_document_code","parent_transaction_id","po_header_id","po_revision_num",' ||
                       '"po_release_id","po_line_id","po_line_location_id","po_unit_price","currency_code","currency_conversion_type",' ||
                       '"currency_conversion_rate","currency_conversion_date","po_distribution_id","requisition_line_id",' ||
                       '"req_distribution_id","charge_account_id","substitute_unordered_code","receipt_exception_flag",' ||
                       '"accrual_status_code","inspection_status_code","inspection_quality_code","destination_type_code",' ||
                       '"deliver_to_person_id","location_id","deliver_to_location_id","subinventory","locator_id","wip_entity_id",' ||
                       '"expected_receipt_date","actual_cost","transfer_cost","transportation_cost","transportation_account_id",' ||
                       '"num_of_containers","waybill_airbill_num","vendor_item_num","vendor_lot_num","rma_reference","comments",' ||
                       '"ship_line_attribute1","header_interface_id","order_transaction_id","customer_account_number",' ||
                       '"customer_party_name","oe_order_line_num","oe_order_num","parent_interface_txn_id","customer_item_id",' ||
                       '"amount","job_id","timecard_id","timecard_ovn","erecord_id","project_id","task_id","asn_attach_id"'
          );
          --更新項目値及びキー情報出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => '"'|| l_trn_upd_tab(1).interface_transaction_id   || '","' ||
                             l_trn_upd_tab(1).group_id                   || '","' ||
                             l_trn_upd_tab(1).last_update_date           || '","' ||
                             l_trn_upd_tab(1).last_updated_by            || '","' ||
                             l_trn_upd_tab(1).creation_date              || '","' ||
                             l_trn_upd_tab(1).created_by                 || '","' ||
                             l_trn_upd_tab(1).last_update_login          || '","' ||
                             l_trn_upd_tab(1).request_id                 || '","' ||
                             l_trn_upd_tab(1).program_application_id     || '","' ||
                             l_trn_upd_tab(1).program_id                 || '","' ||
                             l_trn_upd_tab(1).program_update_date        || '","' ||
                             l_trn_upd_tab(1).transaction_type           || '","' ||
                             l_trn_upd_tab(1).transaction_date           || '","' ||
                             l_trn_upd_tab(1).processing_status_code     || '","' ||
                             l_trn_upd_tab(1).processing_mode_code       || '","' ||
                             l_trn_upd_tab(1).processing_request_id      || '","' ||
                             l_trn_upd_tab(1).transaction_status_code    || '","' ||
                             l_trn_upd_tab(1).category_id                || '","' ||
                             l_trn_upd_tab(1).quantity                   || '","' ||
                             l_trn_upd_tab(1).unit_of_measure            || '","' ||
                             l_trn_upd_tab(1).interface_source_code      || '","' ||
                             l_trn_upd_tab(1).interface_source_line_id   || '","' ||
                             l_trn_upd_tab(1).inv_transaction_id         || '","' ||
                             l_trn_upd_tab(1).item_id                    || '","' ||
                             l_trn_upd_tab(1).item_description           || '","' ||
                             l_trn_upd_tab(1).item_revision              || '","' ||
                             l_trn_upd_tab(1).uom_code                   || '","' ||
                             l_trn_upd_tab(1).employee_id                || '","' ||
                             l_trn_upd_tab(1).auto_transact_code         || '","' ||
                             l_trn_upd_tab(1).shipment_header_id         || '","' ||
                             l_trn_upd_tab(1).shipment_line_id           || '","' ||
                             l_trn_upd_tab(1).ship_to_location_id        || '","' ||
                             l_trn_upd_tab(1).primary_quantity           || '","' ||
                             l_trn_upd_tab(1).primary_unit_of_measure    || '","' ||
                             l_trn_upd_tab(1).receipt_source_code        || '","' ||
                             l_trn_upd_tab(1).vendor_id                  || '","' ||
                             l_trn_upd_tab(1).vendor_site_id             || '","' ||
                             l_trn_upd_tab(1).from_organization_id       || '","' ||
                             l_trn_upd_tab(1).from_subinventory          || '","' ||
                             l_trn_upd_tab(1).to_organization_id         || '","' ||
                             l_trn_upd_tab(1).intransit_owning_org_id    || '","' ||
                             l_trn_upd_tab(1).routing_header_id          || '","' ||
                             l_trn_upd_tab(1).routing_step_id            || '","' ||
                             l_trn_upd_tab(1).source_document_code       || '","' ||
                             l_trn_upd_tab(1).parent_transaction_id      || '","' ||
                             l_trn_upd_tab(1).po_header_id               || '","' ||
                             l_trn_upd_tab(1).po_revision_num            || '","' ||
                             l_trn_upd_tab(1).po_release_id              || '","' ||
                             l_trn_upd_tab(1).po_line_id                 || '","' ||
                             l_trn_upd_tab(1).po_line_location_id        || '","' ||
                             l_trn_upd_tab(1).po_unit_price              || '","' ||
                             l_trn_upd_tab(1).currency_code              || '","' ||
                             l_trn_upd_tab(1).currency_conversion_type   || '","' ||
                             l_trn_upd_tab(1).currency_conversion_rate   || '","' ||
                             l_trn_upd_tab(1).currency_conversion_date   || '","' ||
                             l_trn_upd_tab(1).po_distribution_id         || '","' ||
                             l_trn_upd_tab(1).requisition_line_id        || '","' ||
                             l_trn_upd_tab(1).req_distribution_id        || '","' ||
                             l_trn_upd_tab(1).charge_account_id          || '","' ||
                             l_trn_upd_tab(1).substitute_unordered_code  || '","' ||
                             l_trn_upd_tab(1).receipt_exception_flag     || '","' ||
                             l_trn_upd_tab(1).accrual_status_code        || '","' ||
                             l_trn_upd_tab(1).inspection_status_code     || '","' ||
                             l_trn_upd_tab(1).inspection_quality_code    || '","' ||
                             l_trn_upd_tab(1).destination_type_code      || '","' ||
                             l_trn_upd_tab(1).deliver_to_person_id       || '","' ||
                             l_trn_upd_tab(1).location_id                || '","' ||
                             l_trn_upd_tab(1).deliver_to_location_id     || '","' ||
                             l_trn_upd_tab(1).subinventory               || '","' ||
                             l_trn_upd_tab(1).locator_id                 || '","' ||
                             l_trn_upd_tab(1).wip_entity_id              || '","' ||
                             l_trn_upd_tab(1).expected_receipt_date      || '","' ||
                             l_trn_upd_tab(1).actual_cost                || '","' ||
                             l_trn_upd_tab(1).transfer_cost              || '","' ||
                             l_trn_upd_tab(1).transportation_cost        || '","' ||
                             l_trn_upd_tab(1).transportation_account_id  || '","' ||
                             l_trn_upd_tab(1).num_of_containers          || '","' ||
                             l_trn_upd_tab(1).waybill_airbill_num        || '","' ||
                             l_trn_upd_tab(1).vendor_item_num            || '","' ||
                             l_trn_upd_tab(1).vendor_lot_num             || '","' ||
                             l_trn_upd_tab(1).rma_reference              || '","' ||
                             l_trn_upd_tab(1).comments                   || '","' ||
                             l_trn_upd_tab(1).ship_line_attribute1       || '","' ||
                             l_trn_upd_tab(1).header_interface_id        || '","' ||
                             l_trn_upd_tab(1).order_transaction_id       || '","' ||
                             l_trn_upd_tab(1).customer_account_number    || '","' ||
                             l_trn_upd_tab(1).customer_party_name        || '","' ||
                             l_trn_upd_tab(1).oe_order_line_num          || '","' ||
                             l_trn_upd_tab(1).oe_order_num               || '","' ||
                             l_trn_upd_tab(1).parent_interface_txn_id    || '","' ||
                             l_trn_upd_tab(1).customer_item_id           || '","' ||
                             l_trn_upd_tab(1).amount                     || '","' ||
                             l_trn_upd_tab(1).job_id                     || '","' ||
                             l_trn_upd_tab(1).timecard_id                || '","' ||
                             l_trn_upd_tab(1).timecard_ovn               || '","' ||
                             l_trn_upd_tab(1).erecord_id                 || '","' ||
                             l_trn_upd_tab(1).project_id                 || '","' ||
                             l_trn_upd_tab(1).task_id                    || '","' ||
                             l_trn_upd_tab(1).asn_attach_id              || '"'
          );
--
          BEGIN
            UPDATE rcv_transactions_interface rti
            SET    rti.processing_status_code   = cv_status_code
                 , rti.transaction_status_code  = cv_status_code
                 , rti.shipment_header_id       = NULL
                 , rti.last_updated_by          = cn_last_updated_by            -- ログインユーザーID
                 , rti.last_update_date         = cd_last_update_date           -- システム日付
                 , rti.last_update_login        = cn_last_update_login          -- ログインID
                 , rti.request_id               = cn_request_id                 -- コンカレント要求ID
                 , rti.program_application_id   = cn_program_application_id     -- プログラム・アプリケーションID
                 , rti.program_id               = cn_program_id                 -- コンカレント・プログラムID
                 , rti.program_update_date      = cd_program_update_date        -- システム日付
            WHERE  rti.interface_transaction_id = g_rcv_trn_if_tab( i ).interface_transaction_id
            AND    rti.group_id                 = g_rcv_trn_if_tab( i ).group_id
            ;
            -- 更新件数カウント(退避用変数)
            ln_trn_upd_cnt := ln_trn_upd_cnt + 1;
--
          EXCEPTION
            -- *** データ更新エラー ***
            WHEN OTHERS THEN
              ov_errmsg  := '更新処理に失敗しました。(受入取引OIF)';
              ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
              RAISE err_update_expt;
          END;
--
          -- 更新後データ出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => '"更新後 ( 受入取引OIF )"'
          );
          --更新対象項目名称及びキー情報出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => '"interface_transaction_id","group_id","last_update_date","last_updated_by","creation_date","created_by",' ||
                       '"last_update_login","request_id","program_application_id","program_id","program_update_date","transaction_type",' ||
                       '"transaction_date","processing_status_code","processing_mode_code","processing_request_id",' ||
                       '"transaction_status_code","category_id","quantity","unit_of_measure","interface_source_code",' ||
                       '"interface_source_line_id","inv_transaction_id","item_id","item_description","item_revision","uom_code",' ||
                       '"employee_id","auto_transact_code","shipment_header_id","shipment_line_id","ship_to_location_id",' ||
                       '"primary_quantity","primary_unit_of_measure","receipt_source_code","vendor_id","vendor_site_id",' ||
                       '"from_organization_id","from_subinventory","to_organization_id","intransit_owning_org_id","routing_header_id",' ||
                       '"routing_step_id","source_document_code","parent_transaction_id","po_header_id","po_revision_num",' ||
                       '"po_release_id","po_line_id","po_line_location_id","po_unit_price","currency_code","currency_conversion_type",' ||
                       '"currency_conversion_rate","currency_conversion_date","po_distribution_id","requisition_line_id",' ||
                       '"req_distribution_id","charge_account_id","substitute_unordered_code","receipt_exception_flag",' ||
                       '"accrual_status_code","inspection_status_code","inspection_quality_code","destination_type_code",' ||
                       '"deliver_to_person_id","location_id","deliver_to_location_id","subinventory","locator_id","wip_entity_id",' ||
                       '"expected_receipt_date","actual_cost","transfer_cost","transportation_cost","transportation_account_id",' ||
                       '"num_of_containers","waybill_airbill_num","vendor_item_num","vendor_lot_num","rma_reference","comments",' ||
                       '"ship_line_attribute1","header_interface_id","order_transaction_id","customer_account_number",' ||
                       '"customer_party_name","oe_order_line_num","oe_order_num","parent_interface_txn_id","customer_item_id",' ||
                       '"amount","job_id","timecard_id","timecard_ovn","erecord_id","project_id","task_id","asn_attach_id"'
          );
          --更新項目値及びキー情報出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => '"'|| l_trn_upd_tab(1).interface_transaction_id   || '","' ||
                             l_trn_upd_tab(1).group_id                   || '","' ||
                             l_trn_upd_tab(1).last_update_date           || '","' ||
                             l_trn_upd_tab(1).last_updated_by            || '","' ||
                             l_trn_upd_tab(1).creation_date              || '","' ||
                             l_trn_upd_tab(1).created_by                 || '","' ||
                             l_trn_upd_tab(1).last_update_login          || '","' ||
                             l_trn_upd_tab(1).request_id                 || '","' ||
                             l_trn_upd_tab(1).program_application_id     || '","' ||
                             l_trn_upd_tab(1).program_id                 || '","' ||
                             l_trn_upd_tab(1).program_update_date        || '","' ||
                             l_trn_upd_tab(1).transaction_type           || '","' ||
                             l_trn_upd_tab(1).transaction_date           || '","' ||
                             cv_status_code                              || '","' || -- 処理ステータス
                             l_trn_upd_tab(1).processing_mode_code       || '","' ||
                             l_trn_upd_tab(1).processing_request_id      || '","' ||
                             cv_status_code                              || '","' || -- 取引ステータスコード
                             l_trn_upd_tab(1).category_id                || '","' ||
                             l_trn_upd_tab(1).quantity                   || '","' ||
                             l_trn_upd_tab(1).unit_of_measure            || '","' ||
                             l_trn_upd_tab(1).interface_source_code      || '","' ||
                             l_trn_upd_tab(1).interface_source_line_id   || '","' ||
                             l_trn_upd_tab(1).inv_transaction_id         || '","' ||
                             l_trn_upd_tab(1).item_id                    || '","' ||
                             l_trn_upd_tab(1).item_description           || '","' ||
                             l_trn_upd_tab(1).item_revision              || '","' ||
                             l_trn_upd_tab(1).uom_code                   || '","' ||
                             l_trn_upd_tab(1).employee_id                || '","' ||
                             l_trn_upd_tab(1).auto_transact_code         || '","' ||
                             NULL                                        || '","' || -- 出荷ヘッダID
                             l_trn_upd_tab(1).shipment_line_id           || '","' ||
                             l_trn_upd_tab(1).ship_to_location_id        || '","' ||
                             l_trn_upd_tab(1).primary_quantity           || '","' ||
                             l_trn_upd_tab(1).primary_unit_of_measure    || '","' ||
                             l_trn_upd_tab(1).receipt_source_code        || '","' ||
                             l_trn_upd_tab(1).vendor_id                  || '","' ||
                             l_trn_upd_tab(1).vendor_site_id             || '","' ||
                             l_trn_upd_tab(1).from_organization_id       || '","' ||
                             l_trn_upd_tab(1).from_subinventory          || '","' ||
                             l_trn_upd_tab(1).to_organization_id         || '","' ||
                             l_trn_upd_tab(1).intransit_owning_org_id    || '","' ||
                             l_trn_upd_tab(1).routing_header_id          || '","' ||
                             l_trn_upd_tab(1).routing_step_id            || '","' ||
                             l_trn_upd_tab(1).source_document_code       || '","' ||
                             l_trn_upd_tab(1).parent_transaction_id      || '","' ||
                             l_trn_upd_tab(1).po_header_id               || '","' ||
                             l_trn_upd_tab(1).po_revision_num            || '","' ||
                             l_trn_upd_tab(1).po_release_id              || '","' ||
                             l_trn_upd_tab(1).po_line_id                 || '","' ||
                             l_trn_upd_tab(1).po_line_location_id        || '","' ||
                             l_trn_upd_tab(1).po_unit_price              || '","' ||
                             l_trn_upd_tab(1).currency_code              || '","' ||
                             l_trn_upd_tab(1).currency_conversion_type   || '","' ||
                             l_trn_upd_tab(1).currency_conversion_rate   || '","' ||
                             l_trn_upd_tab(1).currency_conversion_date   || '","' ||
                             l_trn_upd_tab(1).po_distribution_id         || '","' ||
                             l_trn_upd_tab(1).requisition_line_id        || '","' ||
                             l_trn_upd_tab(1).req_distribution_id        || '","' ||
                             l_trn_upd_tab(1).charge_account_id          || '","' ||
                             l_trn_upd_tab(1).substitute_unordered_code  || '","' ||
                             l_trn_upd_tab(1).receipt_exception_flag     || '","' ||
                             l_trn_upd_tab(1).accrual_status_code        || '","' ||
                             l_trn_upd_tab(1).inspection_status_code     || '","' ||
                             l_trn_upd_tab(1).inspection_quality_code    || '","' ||
                             l_trn_upd_tab(1).destination_type_code      || '","' ||
                             l_trn_upd_tab(1).deliver_to_person_id       || '","' ||
                             l_trn_upd_tab(1).location_id                || '","' ||
                             l_trn_upd_tab(1).deliver_to_location_id     || '","' ||
                             l_trn_upd_tab(1).subinventory               || '","' ||
                             l_trn_upd_tab(1).locator_id                 || '","' ||
                             l_trn_upd_tab(1).wip_entity_id              || '","' ||
                             l_trn_upd_tab(1).expected_receipt_date      || '","' ||
                             l_trn_upd_tab(1).actual_cost                || '","' ||
                             l_trn_upd_tab(1).transfer_cost              || '","' ||
                             l_trn_upd_tab(1).transportation_cost        || '","' ||
                             l_trn_upd_tab(1).transportation_account_id  || '","' ||
                             l_trn_upd_tab(1).num_of_containers          || '","' ||
                             l_trn_upd_tab(1).waybill_airbill_num        || '","' ||
                             l_trn_upd_tab(1).vendor_item_num            || '","' ||
                             l_trn_upd_tab(1).vendor_lot_num             || '","' ||
                             l_trn_upd_tab(1).rma_reference              || '","' ||
                             l_trn_upd_tab(1).comments                   || '","' ||
                             l_trn_upd_tab(1).ship_line_attribute1       || '","' ||
                             l_trn_upd_tab(1).header_interface_id        || '","' ||
                             l_trn_upd_tab(1).order_transaction_id       || '","' ||
                             l_trn_upd_tab(1).customer_account_number    || '","' ||
                             l_trn_upd_tab(1).customer_party_name        || '","' ||
                             l_trn_upd_tab(1).oe_order_line_num          || '","' ||
                             l_trn_upd_tab(1).oe_order_num               || '","' ||
                             l_trn_upd_tab(1).parent_interface_txn_id    || '","' ||
                             l_trn_upd_tab(1).customer_item_id           || '","' ||
                             l_trn_upd_tab(1).amount                     || '","' ||
                             l_trn_upd_tab(1).job_id                     || '","' ||
                             l_trn_upd_tab(1).timecard_id                || '","' ||
                             l_trn_upd_tab(1).timecard_ovn               || '","' ||
                             l_trn_upd_tab(1).erecord_id                 || '","' ||
                             l_trn_upd_tab(1).project_id                 || '","' ||
                             l_trn_upd_tab(1).task_id                    || '","' ||
                             l_trn_upd_tab(1).asn_attach_id              || '"'
          );
        END IF;
--
        -- コミット
        COMMIT;
        -- 更新件数確定
        gn_head_upd_cnt := gn_head_upd_cnt + ln_head_upd_cnt;
        gn_trn_upd_cnt  := gn_trn_upd_cnt + ln_trn_upd_cnt;
        --
        IF ( i = g_rcv_trn_if_tab.LAST )
          OR ( g_rcv_trn_if_tab( i ).group_id <> g_rcv_trn_if_tab( i + 1 ).group_id ) THEN
          --グループIDの切替りまたは、最終行の場合にコンカレントを起動する
          -- ===============================================
          -- 受入取引処理起動
          -- ===============================================
          ln_request_id := fnd_request.submit_request(
                             application  => cv_application,
                             program      => cv_program,
                             description  => cv_description,
                             start_time   => cv_start_time,
                             sub_request  => cb_sub_request,
                             argument1    => 'BATCH',
                             argument2    => g_rcv_trn_if_tab( i ).group_id -- グループID
                           );
          IF ( ln_request_id = 0 ) THEN
            -- 起動対象コンカレントの起動失敗エラー
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name_xxccp,
                           iv_name         => cv_msg_ccp_10022
                         );
            lv_errbuf := lv_errmsg;
            RAISE submit_err_expt;
          ELSE
            --コンカレント起動のためコミット
            COMMIT;
            -- 対象件数カウント
            gn_target_cnt := gn_target_cnt + 1;
          END IF;
--
          --コンカレントの終了待機
          lb_wait_result := fnd_concurrent.wait_for_request(
                              request_id   => ln_request_id,
                              interval     => TO_NUMBER(lv_watch_time),
                              max_wait     => NULL,
                              phase        => lv_phase,
                              status       => lv_status,
                              dev_phase    => lv_dev_phase,
                              dev_status   => lv_dev_status,
                              message      => lv_message
                            );
          IF ( ( lb_wait_result = FALSE ) 
            OR ( lv_dev_status = cv_con_status_error ) )
          THEN
            -- コンカレントステータス取得失敗エラー
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name_xxccp,
                           iv_name         => cv_msg_ccp_10023,
                           iv_token_name1  => cv_tkn_req_id,
                           iv_token_value1 => TO_CHAR( ln_request_id )
                         );
            lv_errbuf := lv_errmsg;
            RAISE submit_err_expt;
          ELSIF ( lv_dev_phase <> cv_con_status_complete )
            THEN
              -- コンカレントステータス異常終了エラー
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name_xxccp,
                             iv_name         => cv_msg_ccp_10026,
                             iv_token_name1  => cv_tkn_req_id,
                             iv_token_value1 => TO_CHAR( ln_request_id ),
                             iv_token_name2  => cv_tkn_phase,
                             iv_token_value2 => lv_dev_phase,
                             iv_token_name3  => cv_tkn_status,
                             iv_token_value3 => lv_dev_status
                           );
--
              -- エラー件数カウント
              gn_error_cnt := gn_error_cnt + 1;
              lv_errbuf := lv_errmsg;
              RAISE submit_err_expt;
--
          ELSE
            IF ( lv_dev_status = cv_con_status_error ) THEN
              -- コンカレントエラー終了
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name_xxccp,
                             iv_name         => cv_msg_ccp_10028,
                             iv_token_name1  => cv_tkn_req_id,
                             iv_token_value1 => TO_CHAR( ln_request_id ),
                             iv_token_name2  => cv_tkn_phase,
                             iv_token_value2 => lv_dev_phase,
                             iv_token_name3  => cv_tkn_status,
                             iv_token_value3 => lv_dev_status
                           );
--
              -- エラー件数カウント
              gn_error_cnt := gn_error_cnt + 1;
              lv_errbuf := lv_errmsg;
              RAISE submit_err_expt;
--
            ELSIF ( lv_dev_status = cv_con_status_warning ) THEN
              -- コンカレント警告終了エラー
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name_xxccp,
                             iv_name         => cv_msg_ccp_10030,
                             iv_token_name1  => cv_tkn_req_id,
                             iv_token_value1 => TO_CHAR( ln_request_id ),
                             iv_token_name2  => cv_tkn_phase,
                             iv_token_value2 => lv_dev_phase,
                             iv_token_name3  => cv_tkn_status,
                             iv_token_value3 => lv_dev_status
                           );
              -- 警告件数カウント
              gn_warn_cnt := gn_warn_cnt + 1;
              lv_errbuf := lv_errmsg;
              RAISE submit_warn_expt;
--
            ELSIF ( lv_dev_status = cv_con_status_normal ) THEN
              -- 正常件数カウント
              gn_normal_cnt := gn_normal_cnt + 1;
--
            ELSE
              -- コンカレント異常終了エラー
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name_xxccp,
                             iv_name         => cv_msg_ccp_10026,
                             iv_token_name1  => cv_tkn_req_id,
                             iv_token_value1 => TO_CHAR( ln_request_id ),
                             iv_token_name2  => cv_tkn_phase,
                             iv_token_value2 => lv_dev_phase,
                             iv_token_name3  => cv_tkn_status,
                             iv_token_value3 => lv_dev_status
                           );
              -- エラー件数カウント
              gn_error_cnt := gn_error_cnt + 1;
              lv_errbuf := lv_errmsg;
              RAISE submit_err_expt;
            END IF;
          END IF;
        END IF;
      END IF;
    END LOOP main_loop;
--
--
  EXCEPTION
    -- *** 更新処理例外ハンドラ ***
    WHEN err_update_expt THEN
      ov_retcode := cv_status_error;
--
    -- *** プロファイル取得例外ハンドラ ***
    WHEN get_err_profile_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** コンカレント起動処理例外ハンドラ ***
    WHEN submit_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    WHEN submit_warn_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
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
    retcode       OUT VARCHAR2       --   リターン・コード    --# 固定 #
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
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
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
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       iv_which   => 'LOG'
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --更新件数出力(受入取引ヘッダOIF)
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '更新件数  ：  ' || gn_head_upd_cnt || '件  ( ' || cv_upd_head_tbl_name || ' )'
    );
    --
    --更新件数出力(受入取引OIF)
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '更新件数  ：  ' || gn_trn_upd_cnt || '件  ( ' || cv_upd_trn_tbl_name || ' )'
    );
    --
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_normal_msg
                     );
    ELSIF(lv_retcode = cv_status_warn) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_warn_msg
                     );
    ELSIF(lv_retcode = cv_status_error) THEN
      gv_out_msg := '処理がエラー終了しました。';
    END IF;
    --
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
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
END XXCCP120A01C;
/
