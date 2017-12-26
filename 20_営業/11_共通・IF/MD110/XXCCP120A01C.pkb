CREATE OR REPLACE PACKAGE BODY APPS.XXCCP120A01C
AS
/*****************************************************************************************
 *
 * Package Name     : XXCCP120A01C(body)
 * Description      : ������OIF�������J�o��
 * Version          : 1.04
 *
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/07/31    1.00  SCSK ����ˍ��D  �V�K�쐬
 *  2016/09/12    1.01  SCSK S.Yamashita E_�{�ғ�_13803�Ή�
 *  2016/10/26    1.02  SCSK S.Yamashita E_�{�ғ�_13920�Ή�
 *  2017/04/18    1.03  SCSK S.Niki      E_�{�ғ�_14157�Ή�
 *  2017/12/07    1.04  SCSK K.Nara      E_�{�ғ�_14304,14604�Ή�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
  --WHO�J����
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
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
  gn_warn_cnt      NUMBER;                    -- �X�L�b�v����
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  resource_busy_expt        EXCEPTION; -- ���b�N�擾�G���[
  error_proc_expt           EXCEPTION; -- �G���[�I��
  warning_skip_expt         EXCEPTION; -- �x���X�L�b�v
  PRAGMA EXCEPTION_INIT( resource_busy_expt, -54 );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  -- �A�v���P�[�V�����Z�k��
  cv_appl_short_name_xxccp  CONSTANT VARCHAR2(10) := 'XXCCP';
  -- �p�b�P�[�W��
  cv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCCP120A01C'; -- �p�b�P�[�W��
  -- ���b�Z�[�W�R�[�h
  cv_msg_ccp_10022          CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10022'; -- �N���ΏۃR���J�����g�̋N�����s�G���[
  cv_msg_ccp_10023          CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10023'; -- �R���J�����g�擾���s�G���[
  cv_msg_ccp_10026          CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10026'; -- �R���J�����g�ُ�I��
  cv_msg_ccp_10028          CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10028'; -- �R���J�����g�G���[�I��
  cv_msg_ccp_10030          CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10030'; -- �R���J�����g�x���I��
  cv_msg_ccp_10032          CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10032'; -- �v���t�@�C���擾�G���[
--
  -- �Q�ƃ^�C�v��
  cv_lookup_type_01         CONSTANT VARCHAR2(30)  := 'XXCCP1_ERR_GMI_IC_LOCT_INV'; -- OIF�G���[���b�Z�[�W
  -- �L���t���O
  cv_flg_y                  CONSTANT VARCHAR2(1)   := 'Y';     -- �L��
  -- ���t�t�H�[�}�b�g
  cv_format_dd              CONSTANT VARCHAR2(2)   := 'DD';
  -- �f�[�^���o�����l
  cv_error                  CONSTANT VARCHAR2(5)   := 'ERROR'; -- �G���[
  -- �f�[�^�X�V�l
  cv_status_code            CONSTANT VARCHAR2(7)   := 'PENDING';
  -- �g�[�N���R�[�h
  cv_tkn_req_id             CONSTANT VARCHAR2(20)  := 'REQ_ID';
  cv_tkn_phase              CONSTANT VARCHAR2(20)  := 'PHASE';
  cv_tkn_status             CONSTANT VARCHAR2(20)  := 'STATUS';
  cv_tkn_count              CONSTANT VARCHAR2(20)  := 'COUNT';
  cv_tkn_profile_name       CONSTANT VARCHAR2(20)  := 'PROFILE_NAME';
  -- �v���t�@�C����
  cv_profile_watch_time     CONSTANT VARCHAR2(30)  := 'XXCCP1_DYNAM_CONC_WATCH_TIME'; -- �Ď��Ԋu
  -- �X�V�Ώۃe�[�u������
  cv_upd_head_tbl_name      CONSTANT VARCHAR2(30)  := '�������w�b�_OIF';
  cv_upd_trn_tbl_name       CONSTANT VARCHAR2(30)  := '������OIF';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_process_date           DATE   DEFAULT NULL;       -- �Ɩ��������t
  gn_head_upd_cnt           NUMBER DEFAULT 0;          -- �������w�b�_OIF�X�V����
  gn_trn_upd_cnt            NUMBER DEFAULT 0;          -- ������OIF�X�V����
--
  --==================================================
  -- �O���[�o���J�[�\��
  --==================================================
  -- ������OIF���(�X�e�[�^�X���G���[�̃f�[�^�𒊏o)
  CURSOR g_rcv_trn_if_cur
  IS
    SELECT  rti.interface_transaction_id
           ,rti.group_id
           ,rti.header_interface_id
-- Ver1.01 S.Yamashita ADD start
           ,rti.transaction_type AS transaction_type
-- Ver1.01 S.Yamashita ADD end
    FROM   rcv_transactions_interface rti
    WHERE  rti.transaction_status_code = cv_error
-- Ver1.01 S.Yamashita ADD start
    OR     rti.processing_status_code = cv_error
-- Ver1.01 S.Yamashita ADD end
    ORDER BY rti.group_id
  ;
  --
  TYPE g_rcv_trn_if_ttype IS TABLE OF g_rcv_trn_if_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  g_rcv_trn_if_tab g_rcv_trn_if_ttype;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    --�R���J�����g�萔
    cv_application           CONSTANT VARCHAR2(5)   := 'PO';            -- Application
    cv_program               CONSTANT VARCHAR2(12)  := 'RVCTP';         -- Program
    cv_description           CONSTANT VARCHAR2(9)   := NULL;            -- Description
    cv_start_time            CONSTANT VARCHAR2(10)  := NULL;            -- Start_time
    cb_sub_request           CONSTANT BOOLEAN       := FALSE;           -- Sub_request
    -- �R���J�����g�I���X�e�[�^�X
    cv_con_status_complete   CONSTANT VARCHAR2(20)  := 'COMPLETE';      -- �X�e�[�^�X�i�����j
    cv_con_status_normal     CONSTANT VARCHAR2(10)  := 'NORMAL';        -- �X�e�[�^�X�i����j
    cv_con_status_error      CONSTANT VARCHAR2(10)  := 'ERROR';         -- �X�e�[�^�X�i�ُ�j
    cv_con_status_warning    CONSTANT VARCHAR2(10)  := 'WARNING';       -- �X�e�[�^�X�i�x���j
-- Ver1.01 S.Yamashita ADD start
    cv_date_format           CONSTANT VARCHAR2(30)  := 'YYYY/MM/DD HH24:MI:SS'; -- ���t�t�H�[�}�b�g
-- Ver1.01 S.Yamashita ADD end
--                                                                      
    -- *** ���[�J���ϐ� ***
    lv_outmsg                VARCHAR2(5000) DEFAULT NULL;               -- �o�͗p���b�Z�[�W
    ln_oiferr_trn_id         po_interface_errors.interface_transaction_id%TYPE;
    lb_wait_result           BOOLEAN;                   -- �R���J�����g�ҋ@����
    lv_phase                 VARCHAR2(50)   DEFAULT NULL;
    lv_status                VARCHAR2(50)   DEFAULT NULL;
    lv_dev_phase             VARCHAR2(50)   DEFAULT NULL;
    lv_dev_status            VARCHAR2(50)   DEFAULT NULL;
    lv_message               VARCHAR2(5000) DEFAULT NULL;
    lv_watch_time            VARCHAR2(255)  DEFAULT NULL;
    ln_request_id            NUMBER;
    ln_head_upd_cnt          NUMBER         DEFAULT 0;
    ln_trn_upd_cnt           NUMBER         DEFAULT 0;
-- Ver1.01 S.Yamashita ADD start
    ln_shipment_header_id    NUMBER         DEFAULT 0;
-- Ver1.01 S.Yamashita ADD end
-- Ver1.02 S.Yamashita ADD start
  TYPE lr_error_massage_rec IS RECORD
    (
      po_number              po_headers_all.segment1%TYPE    -- ����No
     ,po_line_number         po_lines_all.line_num%TYPE      -- ��������No
     ,group_id               rcv_transactions_interface.group_id%TYPE    -- �O���[�vID
     ,error_message          po_interface_errors.error_message%TYPE      -- �G���[���b�Z�[�W
    );
  TYPE lt_error_massage_ttype IS TABLE OF lr_error_massage_rec INDEX BY BINARY_INTEGER;
  lt_error_massage_tab        lt_error_massage_ttype;
-- Ver1.02 S.Yamashita ADD end
--
    -- ===============================================
    -- ���[�J����O����
    -- ===============================================
    submit_err_expt          EXCEPTION;
    submit_warn_expt         EXCEPTION;
    get_err_profile_expt     EXCEPTION;
    err_update_expt          EXCEPTION;
--
    -- ===============================================
    -- ���b�N�擾�p�J�[�\��
    -- ===============================================
    -- �������w�b�_OIF
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
    -- ������OIF
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
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --==================================================
    -- �Ɩ��������t�擾
    --==================================================
    gd_process_date := TRUNC( xxccp_common_pkg2.get_process_date );
--
    --==================================================
    -- ���I�p�����[�^�R���J�����g�X�e�[�^�X�Ď��Ԋu�̎擾
    --==================================================
    lv_watch_time := FND_PROFILE.VALUE(cv_profile_watch_time);
--
    --�R���J�����g�X�e�[�^�X�Ď��Ԋu�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '�R���J�����g�X�e�[�^�X�Ď��Ԋu  �F  ' || lv_watch_time
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
    -- ������OIF��񒊏o����
    -- ===============================================
    -- ������OIF���擾�J�[�\��
    OPEN g_rcv_trn_if_cur;
    FETCH g_rcv_trn_if_cur BULK COLLECT INTO g_rcv_trn_if_tab;
    CLOSE g_rcv_trn_if_cur;
    
    <<main_loop>>
    FOR i IN 1 .. g_rcv_trn_if_tab.COUNT LOOP
      -- �ꎞ�ޔ�p�X�V�����̏�����
      ln_head_upd_cnt := 0;
      ln_trn_upd_cnt  := 0;
      --
      -- ===============================================
      -- OIF�G���[��񒊏o����
      -- ===============================================
      BEGIN
        SELECT  pie.interface_transaction_id
        INTO    ln_oiferr_trn_id
        FROM    po_interface_errors  pie
-- Ver1.03 MOD start
--        WHERE   pie.interface_transaction_id = g_rcv_trn_if_tab( i ).interface_transaction_id
        WHERE   (pie.batch_id = g_rcv_trn_if_tab( i ).group_id OR pie.interface_transaction_id = g_rcv_trn_if_tab( i ).interface_transaction_id)
-- Ver1.03 MOD end
        AND     EXISTS(SELECT 'X'
                       FROM   fnd_lookup_values_vl flvv
                       WHERE  flvv.lookup_type  = cv_lookup_type_01
-- Ver1.01 S.Yamashita MOD start
--                       AND    flvv.description  = pie.error_message 
                       AND    pie.error_message LIKE flvv.description
-- Ver1.01 S.Yamashita MOD end
                       AND    flvv.enabled_flag = cv_flg_y
                       AND    gd_process_date BETWEEN NVL( flvv.start_date_active, gd_process_date )
                                                  AND NVL( flvv.end_date_active  , gd_process_date )
                      )
-- Ver1.04 K.Nara ADD start
        AND     ROWNUM = 1
-- Ver1.04 K.Nara ADD end
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          ln_oiferr_trn_id := NULL;
      END;
--
      IF ( ln_oiferr_trn_id IS NOT NULL ) THEN
        -- �X�V�Ώۂ����݂���ꍇ�A�I���X�e�[�^�X���u�x���v�Ƃ���
        ov_retcode := cv_status_warn;
        -- ===============================================
        -- �X�V����
        -- ===============================================
        -- �X�V�Ώۃf�[�^���b�N
        -- �������w�b�_OIF
        OPEN  l_head_upd_cur(
                g_rcv_trn_if_tab( i ).header_interface_id
               ,g_rcv_trn_if_tab( i ).group_id
              );
        -- �X�V�O�̒l���o�͂���ׁA�Ώۃf�[�^���擾
        FETCH l_head_upd_cur BULK COLLECT INTO l_head_upd_tab;
        CLOSE l_head_upd_cur;
--
        -- ������OIF
        OPEN  l_trn_upd_cur(
                g_rcv_trn_if_tab( i ).interface_transaction_id
               ,g_rcv_trn_if_tab( i ).group_id
              );
        -- �X�V�O�̒l���o�͂���ׁA�Ώۃf�[�^���擾
        FETCH l_trn_upd_cur BULK COLLECT INTO l_trn_upd_tab;
        CLOSE l_trn_upd_cur;
--
        IF ( g_rcv_trn_if_tab( i ).header_interface_id IS NOT NULL ) THEN
          -- ===============================================
          -- �������w�b�_OIF�X�V����
          -- ===============================================
          -- �X�V�O�f�[�^�o��
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => '"�X�V�O ( �������w�b�_OIF )"'
          );
          --�X�V�Ώۍ��ږ��̋y�уL�[���o��
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
          --�X�V���ڒl�y�уL�[���o��
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
-- Ver1.01 S.Yamashita MOD start
--                             l_head_upd_tab(1).last_update_date           || '","' ||
                             TO_CHAR(l_head_upd_tab(1).last_update_date,cv_date_format)           || '","' ||
-- Ver1.01 S.Yamashita MOD end
                             l_head_upd_tab(1).last_updated_by            || '","' ||
                             l_head_upd_tab(1).last_update_login          || '","' ||
-- Ver1.01 S.Yamashita MOD start
--                             l_head_upd_tab(1).creation_date              || '","' ||
                             TO_CHAR(l_head_upd_tab(1).creation_date,cv_date_format)              || '","' ||
-- Ver1.01 S.Yamashita MOD end
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
                 , last_updated_by          = cn_last_updated_by            -- ���O�C�����[�U�[ID
                 , last_update_date         = cd_last_update_date           -- �V�X�e�����t
                 , last_update_login        = cn_last_update_login          -- ���O�C��ID
            WHERE  header_interface_id      = g_rcv_trn_if_tab( i ).header_interface_id
            AND    group_id                 = g_rcv_trn_if_tab( i ).group_id
            ;
            -- �X�V�����J�E���g(�ޔ�p�ϐ�)
            ln_head_upd_cnt := ln_head_upd_cnt + 1;
--
          EXCEPTION
            -- *** �f�[�^�X�V�G���[ ***
            WHEN OTHERS THEN
              ov_errmsg  := '�X�V�����Ɏ��s���܂����B(�������w�b�_OIF)';
              ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
              RAISE err_update_expt;
          END;
--
          -- �X�V��f�[�^�o��
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => '"�X�V�� ( �������w�b�_OIF )"'
          );
          --�X�V�Ώۍ��ږ��̋y�уL�[���o��
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
          --�X�V���ڒl�y�уL�[���o��
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => '"'|| l_head_upd_tab(1).header_interface_id        || '","' ||
                             l_head_upd_tab(1).group_id                   || '","' ||
                             l_head_upd_tab(1).edi_control_num            || '","' ||
                             cv_status_code                               || '","' || -- �����X�e�[�^�X
                             l_head_upd_tab(1).receipt_source_code        || '","' ||
                             l_head_upd_tab(1).asn_type                   || '","' ||
                             l_head_upd_tab(1).transaction_type           || '","' ||
                             l_head_upd_tab(1).auto_transact_code         || '","' ||
                             l_head_upd_tab(1).test_flag                  || '","' ||
-- Ver1.01 S.Yamashita MOD start
--                             l_head_upd_tab(1).last_update_date           || '","' ||
--                             l_head_upd_tab(1).last_updated_by            || '","' ||
--                             l_head_upd_tab(1).last_update_login          || '","' ||
--                             l_head_upd_tab(1).creation_date              || '","' ||
                             TO_CHAR(cd_last_update_date,cv_date_format)  || '","' ||
                             cn_last_updated_by            || '","' ||
                             cn_last_update_login          || '","' ||
                             TO_CHAR(l_trn_upd_tab(1).creation_date,cv_date_format)       || '","' ||
-- Ver1.01 S.Yamashita MOD end
                             l_head_upd_tab(1).created_by                 || '","' ||
                             l_head_upd_tab(1).notice_creation_date       || '","' ||
                             l_head_upd_tab(1).shipment_num               || '","' ||
                             l_head_upd_tab(1).receipt_num                || '","' ||
                             NULL                                         || '","' || -- ���w�b�_ID
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
                             cv_flg_y                                     || '","' || -- �L���t���O
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
          -- ������OIF�X�V����
          -- ===============================================
          -- �X�V�O�f�[�^�o��
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => '"�X�V�O ( ������OIF )"'
          );
          --�X�V�Ώۍ��ږ��̋y�уL�[���o��
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
          --�X�V���ڒl�y�уL�[���o��
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => '"'|| l_trn_upd_tab(1).interface_transaction_id   || '","' ||
                             l_trn_upd_tab(1).group_id                   || '","' ||
-- Ver1.01 S.Yamashita MOD start
--                             l_trn_upd_tab(1).last_update_date           || '","' ||
                             TO_CHAR(l_trn_upd_tab(1).last_update_date,cv_date_format)    || '","' ||
-- Ver1.01 S.Yamashita MOD end
                             l_trn_upd_tab(1).last_updated_by            || '","' ||
-- Ver1.01 S.Yamashita MOD start
--                             l_trn_upd_tab(1).creation_date              || '","' ||
                             TO_CHAR(l_trn_upd_tab(1).creation_date,cv_date_format)       || '","' ||
-- Ver1.01 S.Yamashita MOD end
                             l_trn_upd_tab(1).created_by                 || '","' ||
                             l_trn_upd_tab(1).last_update_login          || '","' ||
                             l_trn_upd_tab(1).request_id                 || '","' ||
                             l_trn_upd_tab(1).program_application_id     || '","' ||
                             l_trn_upd_tab(1).program_id                 || '","' ||
-- Ver1.01 S.Yamashita MOD start
--                             l_trn_upd_tab(1).program_update_date        || '","' ||
                             TO_CHAR(l_trn_upd_tab(1).program_update_date,cv_date_format) || '","' ||
-- Ver1.01 S.Yamashita MOD end
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
-- Ver1.01 S.Yamashita ADD start
            -- ��������̏ꍇ
            IF ( g_rcv_trn_if_tab( i ).transaction_type = 'CORRECT' ) THEN
              UPDATE rcv_transactions_interface rti
              SET    rti.processing_status_code   = cv_status_code                -- �����X�e�[�^�X
                   , rti.transaction_status_code  = cv_status_code                -- ����X�e�[�^�X
                   , rti.last_updated_by          = cn_last_updated_by            -- ���O�C�����[�U�[ID
                   , rti.last_update_date         = cd_last_update_date           -- �V�X�e�����t
                   , rti.last_update_login        = cn_last_update_login          -- ���O�C��ID
                   , rti.request_id               = cn_request_id                 -- �R���J�����g�v��ID
                   , rti.program_application_id   = cn_program_application_id     -- �v���O�����E�A�v���P�[�V����ID
                   , rti.program_id               = cn_program_id                 -- �R���J�����g�E�v���O����ID
                   , rti.program_update_date      = cd_program_update_date        -- �V�X�e�����t
              WHERE  rti.interface_transaction_id = g_rcv_trn_if_tab( i ).interface_transaction_id
              AND    rti.group_id                 = g_rcv_trn_if_tab( i ).group_id
              ;
--
              -- ���O�o�͗p
              ln_shipment_header_id := l_trn_upd_tab(1).shipment_header_id;
--
            -- �����ȊO�̏ꍇ
            ELSE
-- Ver1.01 S.Yamashita ADD end
              UPDATE rcv_transactions_interface rti
              SET    rti.processing_status_code   = cv_status_code
                   , rti.transaction_status_code  = cv_status_code
                   , rti.shipment_header_id       = NULL
                   , rti.last_updated_by          = cn_last_updated_by            -- ���O�C�����[�U�[ID
                   , rti.last_update_date         = cd_last_update_date           -- �V�X�e�����t
                   , rti.last_update_login        = cn_last_update_login          -- ���O�C��ID
                   , rti.request_id               = cn_request_id                 -- �R���J�����g�v��ID
                   , rti.program_application_id   = cn_program_application_id     -- �v���O�����E�A�v���P�[�V����ID
                   , rti.program_id               = cn_program_id                 -- �R���J�����g�E�v���O����ID
                   , rti.program_update_date      = cd_program_update_date        -- �V�X�e�����t
              WHERE  rti.interface_transaction_id = g_rcv_trn_if_tab( i ).interface_transaction_id
              AND    rti.group_id                 = g_rcv_trn_if_tab( i ).group_id
              ;
-- Ver1.01 S.Yamashita ADD start
              -- ���O�o�͗p
              ln_shipment_header_id := NULL;
            END IF;
-- Ver1.01 S.Yamashita ADD end
            -- �X�V�����J�E���g(�ޔ�p�ϐ�)
            ln_trn_upd_cnt := ln_trn_upd_cnt + 1;
--
          EXCEPTION
            -- *** �f�[�^�X�V�G���[ ***
            WHEN OTHERS THEN
              ov_errmsg  := '�X�V�����Ɏ��s���܂����B(������OIF)';
              ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
              RAISE err_update_expt;
          END;
--
          -- �X�V��f�[�^�o��
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => '"�X�V�� ( ������OIF )"'
          );
          --�X�V�Ώۍ��ږ��̋y�уL�[���o��
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
          --�X�V���ڒl�y�уL�[���o��
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => '"'|| l_trn_upd_tab(1).interface_transaction_id   || '","' ||
                             l_trn_upd_tab(1).group_id                   || '","' ||
-- Ver1.01 S.Yamashita MOD start
--                             l_trn_upd_tab(1).last_update_date           || '","' ||
--                             l_trn_upd_tab(1).last_updated_by            || '","' ||
--                             l_trn_upd_tab(1).creation_date              || '","' ||
--                             l_trn_upd_tab(1).created_by                 || '","' ||
--                             l_trn_upd_tab(1).last_update_login          || '","' ||
--                             l_trn_upd_tab(1).request_id                 || '","' ||
--                             l_trn_upd_tab(1).program_application_id     || '","' ||
--                             l_trn_upd_tab(1).program_id                 || '","' ||
--                             l_trn_upd_tab(1).program_update_date        || '","' ||
                             TO_CHAR(cd_last_update_date,cv_date_format)     || '","' ||
                             cn_last_updated_by                              || '","' ||
                             TO_CHAR(l_trn_upd_tab(1).creation_date,cv_date_format) || '","' ||
                             l_trn_upd_tab(1).created_by                     || '","' ||
                             cn_last_update_login                            || '","' ||
                             cn_request_id                                   || '","' ||
                             cn_program_application_id                       || '","' ||
                             cn_program_id                                   || '","' ||
                             TO_CHAR(cd_program_update_date,cv_date_format)  || '","' ||
-- Ver1.01 S.Yamashita MOD end
                             l_trn_upd_tab(1).transaction_type           || '","' ||
                             l_trn_upd_tab(1).transaction_date           || '","' ||
                             cv_status_code                              || '","' || -- �����X�e�[�^�X
                             l_trn_upd_tab(1).processing_mode_code       || '","' ||
                             l_trn_upd_tab(1).processing_request_id      || '","' ||
                             cv_status_code                              || '","' || -- ����X�e�[�^�X�R�[�h
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
-- Ver1.01 S.Yamashita MOD start
--                             NULL                                        || '","' || -- �o�׃w�b�_ID
                             ln_shipment_header_id                       || '","' || -- �o�׃w�b�_ID
-- Ver1.01 S.Yamashita MOD end
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
        -- �R�~�b�g
        COMMIT;
        -- �X�V�����m��
        gn_head_upd_cnt := gn_head_upd_cnt + ln_head_upd_cnt;
        gn_trn_upd_cnt  := gn_trn_upd_cnt + ln_trn_upd_cnt;
        --
        IF ( i = g_rcv_trn_if_tab.LAST )
          OR ( g_rcv_trn_if_tab( i ).group_id <> g_rcv_trn_if_tab( i + 1 ).group_id ) THEN
          --�O���[�vID�̐ؑւ�܂��́A�ŏI�s�̏ꍇ�ɃR���J�����g���N������
          -- ===============================================
          -- �����������N��
          -- ===============================================
          ln_request_id := fnd_request.submit_request(
                             application  => cv_application,
                             program      => cv_program,
                             description  => cv_description,
                             start_time   => cv_start_time,
                             sub_request  => cb_sub_request,
                             argument1    => 'BATCH',
                             argument2    => g_rcv_trn_if_tab( i ).group_id -- �O���[�vID
                           );
          IF ( ln_request_id = 0 ) THEN
            -- �N���ΏۃR���J�����g�̋N�����s�G���[
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name_xxccp,
                           iv_name         => cv_msg_ccp_10022
                         );
            lv_errbuf := lv_errmsg;
            RAISE submit_err_expt;
          ELSE
            --�R���J�����g�N���̂��߃R�~�b�g
            COMMIT;
            -- �Ώی����J�E���g
            gn_target_cnt := gn_target_cnt + 1;
          END IF;
--
          --�R���J�����g�̏I���ҋ@
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
            -- �R���J�����g�X�e�[�^�X�擾���s�G���[
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
              -- �R���J�����g�X�e�[�^�X�ُ�I���G���[
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
              -- �G���[�����J�E���g
              gn_error_cnt := gn_error_cnt + 1;
              lv_errbuf := lv_errmsg;
              RAISE submit_err_expt;
--
          ELSE
            IF ( lv_dev_status = cv_con_status_error ) THEN
              -- �R���J�����g�G���[�I��
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
              -- �G���[�����J�E���g
              gn_error_cnt := gn_error_cnt + 1;
              lv_errbuf := lv_errmsg;
              RAISE submit_err_expt;
--
            ELSIF ( lv_dev_status = cv_con_status_warning ) THEN
              -- �R���J�����g�x���I���G���[
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
              -- �x�������J�E���g
              gn_warn_cnt := gn_warn_cnt + 1;
              lv_errbuf := lv_errmsg;
              RAISE submit_warn_expt;
--
            ELSIF ( lv_dev_status = cv_con_status_normal ) THEN
              -- ���팏���J�E���g
              gn_normal_cnt := gn_normal_cnt + 1;
--
            ELSE
              -- �R���J�����g�ُ�I���G���[
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
              -- �G���[�����J�E���g
              gn_error_cnt := gn_error_cnt + 1;
              lv_errbuf := lv_errmsg;
              RAISE submit_err_expt;
            END IF;
          END IF;
        END IF;
      END IF;
    END LOOP main_loop;
--
-- Ver1.02 S.Yamashita ADD start
    -- ������OIF�c���R�[�h�`�F�b�N
    SELECT v.segment1         AS po_number       -- ����No
          ,v.line_num         AS po_line_number  -- ��������No
          ,v.group_id         AS group_id        -- �O���[�vID
          ,v.error_message    AS error_message   -- IF�G���[���e
    BULK COLLECT INTO  lt_error_massage_tab
-- Ver1.04 K.Nara MOD start
--    FROM (SELECT pha.segment1                AS segment1
    FROM (SELECT /*+ FULL(rti) */
                 pha.segment1                AS segment1
-- Ver1.04 K.Nara MOD end
                ,pla.line_num                AS line_num
                ,CASE 
                  WHEN (cicv.item_class_code = '5' AND cicv.prod_class_code = '2' AND cimv.conv_unit = 'CS' ) THEN TO_NUMBER(pla.attribute11) * TO_NUMBER(pla.attribute4)
                  ELSE TO_NUMBER(pla.attribute11)
                 END                         AS attribute11_conv
                ,pla.quantity                AS quantity
                ,CASE
                  WHEN (cicv.item_class_code = '5' AND cicv.prod_class_code = '2' AND cimv.conv_unit = 'CS' ) THEN TO_NUMBER(pla.attribute7) * TO_NUMBER(pla.attribute4)
                  ELSE TO_NUMBER(pla.attribute7)
                 END                         AS attribute7_conv
                ,plla.quantity_received      AS sum_rt_qty
                ,rti.group_id                AS group_id
                ,pie.error_message           AS error_message
          FROM   po_headers_all           pha
                ,po_lines_all             pla
                ,po_line_locations_all    plla
                ,xxcmn_item_mst_v         cimv
                ,xxcmn_item_categories3_v cicv
                ,xxcmn_item_locations_v   cilv
                ,rcv_transactions_interface rti
                ,po_interface_errors pie
          WHERE pha.po_header_id         = pla.po_header_id
          AND   pha.po_header_id         = plla.po_header_id
          AND   pla.po_line_id           = plla.po_line_id
          AND   pla.cancel_flag          = 'N'
          AND   cimv.inventory_item_id   = pla.item_id
          AND   cimv.item_id             = cicv.item_id
          AND   pha.attribute5           = cilv.segment1
          AND   pha.attribute1          IN ('25','30','35')
          AND   TO_DATE(pha.attribute4,'YYYY/MM/DD') >= ADD_MONTHS(TO_DATE(xxcmn_common_pkg.get_opminv_close_period,'YYYYMM'),1) -- �Ώ۔N��(�ŐV�N���[�Y���̗���1��)
          AND   pha.po_header_id         = rti.po_header_id
-- Ver1.04 K.Nara ADD start
          AND   ( rti.transaction_status_code = cv_error
            OR    rti.processing_status_code  = cv_error )
-- Ver1.04 K.Nara ADD end
          AND   rti.group_id             = pie.batch_id
          AND   rti.creation_date        < cd_creation_date  -- �쐬��
          ) v
    WHERE ((NVL(v.attribute7_conv,0) <> v.sum_rt_qty)
       OR (v.attribute11_conv <> v.quantity)
       OR (v.attribute7_conv > 0
        AND v.sum_rt_qty    = 0)
       )
    ORDER BY v.segment1
            ,v.line_num
    ;
--
    -- �c���R�[�h�����݂���ꍇ�̓��[�v
    IF ( lt_error_massage_tab.COUNT > 0 ) THEN
      << check_loop >>
      FOR i IN 1 .. lt_error_massage_tab.COUNT LOOP
        -- �G���[���e�o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
         ,buff   => '�������J�o���ΏۊO�̃G���[���������Ă��܂��B����No:' || lt_error_massage_tab(i).po_number
                                                                          || ' ��������No�F' || lt_error_massage_tab(i).po_line_number
                                                                          || ' �O���[�vID�F' || lt_error_massage_tab(i).group_id
                                                                          || ' �G���[���b�Z�[�W�F' || lt_error_massage_tab(i).error_message
        );
        -- �X�e�[�^�X���G���[�ɐݒ�
        ov_retcode := cv_status_error;
      END LOOP check_loop;
--
      -- �G���[�����ݒ�
      gn_error_cnt := lt_error_massage_tab.COUNT;
--
    END IF;
-- Ver1.02 S.Yamashita ADD end
--
  EXCEPTION
    -- *** �X�V������O�n���h�� ***
    WHEN err_update_expt THEN
      ov_retcode := cv_status_error;
--
    -- *** �v���t�@�C���擾��O�n���h�� ***
    WHEN get_err_profile_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** �R���J�����g�N��������O�n���h�� ***
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
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2       --   ���^�[���E�R�[�h    --# �Œ� #
  )
--
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- �v���O������
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
    --
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
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
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --�X�V�����o��(�������w�b�_OIF)
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '�X�V����  �F  ' || gn_head_upd_cnt || '��  ( ' || cv_upd_head_tbl_name || ' )'
    );
    --
    --�X�V�����o��(������OIF)
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '�X�V����  �F  ' || gn_trn_upd_cnt || '��  ( ' || cv_upd_trn_tbl_name || ' )'
    );
    --
    --�Ώی����o��
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
    --���������o��
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
    --�G���[�����o��
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
    --�X�L�b�v�����o��
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
    --�I�����b�Z�[�W
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
      gv_out_msg := '�������G���[�I�����܂����B';
    END IF;
    --
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCCP120A01C;
/
