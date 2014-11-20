CREATE OR REPLACE PACKAGE BODY xxpo320001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo320001c(body)
 * Description      : �����d���E�o�׎��э쐬����
 * MD.050           : �d����o�׎���         T_MD050_BPO_320
 * MD.070           : �����d���E�o�׎��э쐬 T_MD070_BPO_32B
 * Version          : 1.15
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  ins_rcv_transactions   �������I�[�v��IF�̍쐬
 *  get_open_rcv_if        ����I�[�v��IF�̎�������f�[�^�擾
 *  get_open_deli_if       ����I�[�v��IF�̔��������f�[�^�擾
 *  mod_open_rcv_if        ����I�[�v��IF�̎�������p�f�[�^�̍쐬
 *  mod_open_deli_if       ����I�[�v��IF�̔��������p�f�[�^�̍쐬
 *  proc_xxpo_rcv_ins      ����ԕi����(�A�h�I��)�̍쐬����
 *  proc_rcv_if            ����I�[�v���C���^�t�F�[�X�̍쐬����
 *  set_req_status         �o�׈˗�/�x���˗��X�e�[�^�X�̐ݒ�
 *  check_quantity         �d����o�א��ʂ̃`�F�b�N
 *  parameter_check        �p�����[�^�`�F�b�N                           (B-2)
 *  get_rcv_data           ������э쐬�Ώۃf�[�^�擾                   (B-3)
 *  keep_rcv_data          ������я��ێ�                             (B-4)
 *  set_rcv_data           ������я��o�^                             (B-5)
 *  check_deli_pat         �o�׎��э쐬�p�^�[������                     (B-6)
 *  get_new_data           �o�׎��э쐬�Ώۃf�[�^�擾(�V�K�o�^�p)       (B-7)
 *  keep_new_data          �o�׎��я��ێ�(�V�K�o�^�p)                 (B-8)
 *  ins_xxpo_data          �󒍃A�h�I����� �X�V(�V�K�o�^�p)            (B-9)
 *  upd_xxpo_data          �󒍃w�b�_�A�h�I����� �X�V
 *                          (�ŐV�f�[�^������O�f�[�^�ɕύX)            (B-10)
 *  mod_xxpo_data          �󒍃A�h�I����� �o�^(�����f�[�^�o�^)        (B-11)
 *  get_mod_data           �o�׎��ѐ��ʍX�V�p�f�[�^�擾(�����p)         (B-12)
 *  keep_mod_data          �o�׎��я��ێ�(�����p)                     (B-13)
 *  upd_quantity_data      �o�׎��ѐ��� �X�V(�����p)                    (B-14)
 *  proc_rcv_exec          �����������N��                             (B-15)
 *  proc_deli_exec         �o�׈˗�/�o�׎��э쐬�����N��                (B-16)
 *  disp_report            �������ʏ��o��                             (B-17)
 *  create_mov_lot         �ړ����b�g�ڍ׍쐬(�V�K�o�^�p)               (B-18)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/02/18    1.0   Oracle �R�� ��_ ����쐬
 *  2008/04/16    1.1   Oracle �R�� ��_ �ύX�v��No.58 �Ή�
 *  2008/05/14    1.2   Oracle �R�� ��_ �ύX�v��No.90 �Ή�
 *  2008/05/14    1.3   Oracle �R�� ��_ �ύX�v��No.77 �Ή�
 *  2008/05/22    1.4   Oracle �R�� ��_ �ύX�v��No109�Ή�
 *                                       �����e�X�g�s����O#300_3�Ή�
 *  2008/05/24    1.5   Oracle ���R �m�� �����e�X�g�s����O##320_3,320_4�Ή�
 *  2008/05/26    1.6   Oracle �R�� ��_ �ύX�v��No120�Ή�
 *  2008/06/11    1.7   Oracle �R�� ��_ �s����O#440_63�Ή�
 *  2008/10/24    1.8   Oracle �g�� ���� �����ύXNo174�Ή�
 *  2008/12/04    1.9   Oracle �g�� ���� �{�ԏ�QNo420�Ή�
 *  2008/12/06    1.10  Oracle �ɓ� �ЂƂ� �{�ԏ�QNo528�Ή�
 *  2008/12/15    1.11  Oracle �k���� ���v �{�ԏ�QNo648�Ή�
 *  2008/12/19    1.12  Oracle ��r ��� �{�ԏ�QNo648�đΉ�
 *  2008/12/30    1.13  Oracle �g�� ���� �W��-��޵ݎ�����ّΉ�
 *  2009/01/08    1.14  Oracle �g�� ���� ������הԍ��̔ԕs���Ή�
 *  2009/01/13    1.15  Oracle �g�� ���� ������הԍ��̔ԕs���Ή�
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_dot       CONSTANT VARCHAR2(3) := '.';
  gv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
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
  keep_new_data_expt    EXCEPTION;              -- �o�׎��я��ێ��G���[
  keep_mod_data_expt    EXCEPTION;              -- �o�׎��я��ێ�(����)�G���[
  lock_expt             EXCEPTION;              -- ���b�N�擾��O
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);          -- ���b�N�擾��O
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  -- ���b�Z�[�W�p�萔
  gv_pkg_name         CONSTANT VARCHAR2(15) := 'xxpo320001c';       -- �p�b�P�[�W��
  gv_app_name         CONSTANT VARCHAR2(5)  := 'XXPO';              -- �A�v���P�[�V�����Z�k��
--
  -- �g�[�N��
  gv_tkn_para_name       CONSTANT VARCHAR2(20) := 'PARAM_NAME';
  gv_tkn_po_num          CONSTANT VARCHAR2(20) := 'PO_NUM';
  gv_tkn_conc_id         CONSTANT VARCHAR2(20) := 'CONC_ID';
  gv_tkn_conc_name       CONSTANT VARCHAR2(20) := 'CONC_NAME';
  gv_tkn_count_1         CONSTANT VARCHAR2(20) := 'COUNT_1';
  gv_tkn_count_2         CONSTANT VARCHAR2(20) := 'COUNT_2';
  gv_tkn_item_cd         CONSTANT VARCHAR2(20) := 'ITEM_CD';
  gv_tkn_request_num     CONSTANT VARCHAR2(20) := 'REQUEST_NUM';
  gv_tkn_table_num       CONSTANT VARCHAR2(20) := 'TABLE_NAME';
  gv_tkn_target_count_1  CONSTANT VARCHAR2(20) := 'TARGET_COUNT_1';
  gv_tkn_target_count_2  CONSTANT VARCHAR2(20) := 'TARGET_COUNT_2';
--
  -- ���[�U�[�萔
  gn_mode_oth            CONSTANT NUMBER       := 0;
  gn_mode_ins            CONSTANT NUMBER       := 1;
  gn_mode_upd            CONSTANT NUMBER       := 2;
  gn_lot_ctl_on          CONSTANT NUMBER       := 1;
  gv_flg_on              CONSTANT VARCHAR2(1)  := 'Y';
  gv_flg_off             CONSTANT VARCHAR2(1)  := 'N';
  gv_req_status_rect     CONSTANT VARCHAR2(2)  := '07';                     -- ��̍�
  gv_req_status_appr     CONSTANT VARCHAR2(2)  := '08';                     -- �o�׎��ьv���
  gv_txns_type           CONSTANT VARCHAR2(30) := '1';
  gv_trans_type_receive  CONSTANT VARCHAR2(20) := 'RECEIVE';
  gv_trans_type_correct  CONSTANT VARCHAR2(20) := 'CORRECT';
  gv_dest_type_receive   CONSTANT VARCHAR2(20) := 'RECEIVING';
  gv_trans_type_deliver  CONSTANT VARCHAR2(20) := 'DELIVER';
  gv_dest_type_inv       CONSTANT VARCHAR2(20) := 'INVENTORY';
--
  -- �v���Z�b�g
  gv_request_set_name    CONSTANT VARCHAR2(50) := 'XXPO320001Q';
  gv_request_name        CONSTANT VARCHAR2(50) := '�����d���E�o�׎��э쐬���� �v���Z�b�g';
--
  -- ����������
  gv_rcv_app             CONSTANT VARCHAR2(50) := 'PO';
  gv_rcv_stage           CONSTANT VARCHAR2(50) := 'STAGE10';
  gv_rcv_app_name        CONSTANT VARCHAR2(50) := 'RVCTP';
--
  -- �o�׈˗�/�o�׎��э쐬����
  gv_deli_app            CONSTANT VARCHAR2(50) := 'XXWSH';
  gv_deli_stage          CONSTANT VARCHAR2(50) := 'STAGE20';
  gv_deli_app_name       CONSTANT VARCHAR2(50) := 'XXWSH420001C';
--
  gv_document_type       CONSTANT VARCHAR2(2)  := '30';    -- �x���w��
  gv_record_type         CONSTANT VARCHAR2(2)  := '20';    -- �o�Ɏ���
  gv_indicate            CONSTANT VARCHAR2(2)  := '10';    -- �w��
  gv_qty_fixed_type      CONSTANT VARCHAR2(2)  := '30';    -- ���ʊm���
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ***************************************
  -- ***    �擾���i�[���R�[�h�^��`   ***
  -- ***************************************
--
  -- B-3:������э쐬�Ώۃf�[�^
  TYPE masters_rec IS RECORD(
    po_header_number      po_headers_all.segment1%TYPE,                        -- �����ԍ�
    po_header_id          po_headers_all.po_header_id%TYPE,                    -- �����w�b�_ID
    vendor_id             po_headers_all.vendor_id%TYPE,                       -- �d����ID
    pha_def5              po_headers_all.attribute5%TYPE,                      -- �[����R�[�h
    attribute9            po_headers_all.attribute9%TYPE,                      -- �˗��ԍ�
    attribute4            po_headers_all.attribute4%TYPE,                      -- �[����
    h_attribute10         po_headers_all.attribute10%TYPE,                     -- �����R�[�h
    h_attribute3          po_headers_all.attribute3%TYPE,                      -- ������ID
    po_line_id            po_lines_all.po_line_id%TYPE,                        -- ��������ID
    line_num              po_lines_all.line_num%TYPE,                          -- ���הԍ�
    item_id               po_lines_all.item_id%TYPE,                           -- �i��ID
    lot_no                po_lines_all.attribute1%TYPE,                        -- ���b�gNO
    pla_def5              po_lines_all.attribute5%TYPE,                        -- �d����o�ד�
    attribute6            po_lines_all.attribute6%TYPE,                        -- �d����o�א���
    unit_code             po_lines_all.unit_meas_lookup_code%TYPE,             -- �P��
    attribute10           po_lines_all.attribute10%TYPE,                       -- �����P��
    -- 2008/05/24 UPD START Y.Takayama
    --pla_qty               po_lines_all.quantity%TYPE,                          -- ����
    pla_qty               po_lines_all.attribute4%TYPE,                        -- ����
    -- 2008/05/24 UPD END   Y.Takayama
    attribute7            po_lines_all.attribute7%TYPE,                        -- �������
    source_doc_number     xxpo_rcv_and_rtn_txns.source_document_number%TYPE,   -- �������ԍ�
    source_doc_line_num   xxpo_rcv_and_rtn_txns.source_document_line_num%TYPE, -- ���������הԍ�
    xrt_qty               xxpo_rcv_and_rtn_txns.quantity%TYPE,                 -- ����
    rcv_rtn_quantity      xxpo_rcv_and_rtn_txns.rcv_rtn_quantity%TYPE,         -- ����ԕi����
    conversion_factor     xxpo_rcv_and_rtn_txns.conversion_factor%TYPE,        -- ���Z����
    inv_location_id       xxcmn_item_locations_v.inventory_location_id%TYPE,   -- �ۊǏꏊID
    segment1              xxcmn_vendors_v.segment1%TYPE,                       -- �d����ԍ�
    item_no               xxcmn_item_mst_v.item_no%TYPE,                       -- �i�ڃR�[�h
    lot_id                ic_lots_mst.lot_id%TYPE,                             -- ���b�gID
    attribute1            rcv_shipment_lines.attribute1%TYPE,                  -- ���ID
    drop_ship_type        po_headers_all.attribute6%TYPE,                      -- �����敪
    unit_price            po_lines_all.attribute8%TYPE,                        -- �P��
    lot_ctl               xxcmn_item_mst_v.lot_ctl%TYPE,                       -- ���b�g
    expire_date           ic_lots_mst.expire_date%TYPE,                        -- ���b�g������
    item_idv              xxcmn_item_mst_v.item_id%TYPE,                       -- �i��ID
--
    category_id           rcv_shipment_lines.category_id%TYPE,
    unit_of_measure       rcv_transactions.unit_of_measure%TYPE,
    item_description      rcv_shipment_lines.item_description%TYPE,
    uom_code              rcv_transactions.uom_code%TYPE,
    shipment_header_id    rcv_shipment_lines.shipment_header_id%TYPE,
    shipment_line_id      rcv_shipment_lines.shipment_line_id%TYPE,
    primary_unit_of       rcv_transactions.primary_unit_of_measure%TYPE,
    vendor_site_id        rcv_transactions.vendor_site_id%TYPE,
    organization_id       rcv_transactions.organization_id%TYPE,
    subinventory          rcv_transactions.subinventory%TYPE,
    routing_header_id     rcv_shipment_lines.routing_header_id%TYPE,
    po_line_location_id   rcv_shipment_lines.po_line_location_id%TYPE,
    po_unit_price         rcv_transactions.po_unit_price%TYPE,
    currency_code         rcv_transactions.currency_code%TYPE,
    currency_conv_rate    rcv_transactions.currency_conversion_rate%TYPE,
    po_distribution_id    rcv_shipment_lines.po_distribution_id%TYPE,
    locator_id            rcv_transactions.locator_id%TYPE,
    transaction_id        rcv_transactions.transaction_id%TYPE,
--
    trans_type            rcv_transactions_interface.transaction_type%TYPE,    -- ����^�C�v
    conv_factor           xxpo_rcv_and_rtn_txns.conversion_factor%TYPE,        -- ���Z����
    assen_vendor_id       xxpo_rcv_and_rtn_txns.assen_vendor_id%TYPE,          -- ������ID
    assen_vendor_code     xxpo_rcv_and_rtn_txns.assen_vendor_code%TYPE,        -- �����҃R�[�h
    rcv_qty               NUMBER,                                   -- �������
    rcv_cov_qty           NUMBER,                                   -- ������ʍ���
    def_date4             DATE,
    def_date5             DATE,
    def_qty6              NUMBER,
    def_qty7              NUMBER,
--
    exec_flg              NUMBER                                    -- �����t���O
  );
--
  -- ����I�[�v���C���^�t�F�[�X�p
  TYPE mst_b_5_rec IS RECORD(
    category_id               rcv_shipment_lines.category_id%TYPE,
    unit_of_measure           rcv_shipment_lines.unit_of_measure%TYPE,
    item_description          rcv_shipment_lines.item_description%TYPE,
    uom_code                  rcv_transactions.uom_code%TYPE,
    shipment_header_id        rcv_shipment_lines.shipment_header_id%TYPE,
    shipment_line_id          rcv_shipment_lines.shipment_line_id%TYPE,
    primary_unit_of_measure   rcv_transactions.primary_unit_of_measure%TYPE,
    vendor_site_id            rcv_transactions.vendor_site_id%TYPE,
    organization_id           rcv_transactions.organization_id%TYPE,
    subinventory              rcv_transactions.subinventory%TYPE,
    routing_header_id         rcv_shipment_lines.routing_header_id%TYPE,
    transaction_id            rcv_transactions.transaction_id%TYPE,
    po_line_location_id       rcv_shipment_lines.po_line_location_id%TYPE,
    po_unit_price             rcv_transactions.po_unit_price%TYPE,
    currency_code             rcv_transactions.currency_code%TYPE,
    currency_conversion_rate  rcv_transactions.currency_conversion_rate%TYPE,
    po_distribution_id        rcv_shipment_lines.po_distribution_id%TYPE,
    locator_id                rcv_transactions.locator_id%TYPE
  );
--
  -- �o�׎��э쐬�Ώۃf�[�^
  TYPE mst_b_6_rec IS RECORD(
    po_header_id          po_headers_all.po_header_id%TYPE,
    order_header_id       xxwsh_order_headers_all.order_header_id%TYPE,
    req_status            xxwsh_order_headers_all.req_status%TYPE,
    actual_confirm_class  xxwsh_order_headers_all.actual_confirm_class%TYPE
  );
--
  -- �o�׎��э쐬�Ώۃf�[�^(�V�K�o�^�p)
  TYPE mst_b_7_rec IS RECORD(
    attribute6                   po_lines_all.attribute6%TYPE,
    attribute4                   po_headers_all.attribute4%TYPE,
    req_status                   xxwsh_order_headers_all.req_status%TYPE,
    actual_confirm_class         xxwsh_order_headers_all.actual_confirm_class%TYPE,
    career_id                    xxwsh_order_headers_all.career_id%TYPE,
    freight_carrier_code         xxwsh_order_headers_all.freight_carrier_code%TYPE,
    result_freight_carrier_id    xxwsh_order_headers_all.result_freight_carrier_id%TYPE,
    result_freight_carrier_code  xxwsh_order_headers_all.result_freight_carrier_code%TYPE,
    shipping_method_code         xxwsh_order_headers_all.shipping_method_code%TYPE,
    result_shipping_method_code  xxwsh_order_headers_all.result_shipping_method_code%TYPE,
    shipped_quantity             xxwsh_order_lines_all.shipped_quantity%TYPE,
    order_line_id                xxwsh_order_lines_all.order_line_id%TYPE,
    request_no                   xxwsh_order_lines_all.request_no%TYPE,
    item_no                      xxcmn_item_mst_v.item_no%TYPE,
--
    def_qty6                     NUMBER,
    def_date4                    DATE
  );
--
  -- �o�׎��э쐬�Ώۃf�[�^(�����p)
  TYPE mst_b_12_rec IS RECORD(
    attribute6                   po_lines_all.attribute6%TYPE,
    shipped_quantity             xxwsh_order_lines_all.shipped_quantity%TYPE,
    order_line_id                xxwsh_order_lines_all.order_line_id%TYPE,
    request_no                   xxwsh_order_lines_all.request_no%TYPE,
    item_no                      xxcmn_item_mst_v.item_no%TYPE,
    item_id                      po_lines_all.item_id%TYPE,
--
    def_qty6                     NUMBER
  );
--
  -- �e�}�X�^�֔��f����f�[�^���i�[���錋���z��
  TYPE masters_tbl  IS TABLE OF masters_rec  INDEX BY PLS_INTEGER;
  TYPE mst_b_5_tbl  IS TABLE OF mst_b_5_rec  INDEX BY PLS_INTEGER;
  TYPE mst_b_6_tbl  IS TABLE OF mst_b_6_rec  INDEX BY PLS_INTEGER;
  TYPE mst_b_7_tbl  IS TABLE OF mst_b_7_rec  INDEX BY PLS_INTEGER;
  TYPE mst_b_12_tbl IS TABLE OF mst_b_12_rec INDEX BY PLS_INTEGER;
--
  -- ***************************************
  -- ***      �o�^�p���ڃe�[�u���^       ***
  -- ***************************************
--
  gt_b_03_mast                masters_tbl;  -- �e�}�X�^�֓o�^����f�[�^
  gt_b_05_mast                mst_b_5_tbl;  -- �e�}�X�^�֓o�^����f�[�^
  gt_b_06_mast                mst_b_6_tbl;  -- �e�}�X�^�֓o�^����f�[�^
  gt_b_07_mast                mst_b_7_tbl;  -- �e�}�X�^�֓o�^����f�[�^
  gt_b_12_mast                mst_b_12_tbl; -- �e�}�X�^�֓o�^����f�[�^
  -- ***************************************
  -- ***      ���ڊi�[�e�[�u���^��`     ***
  -- ***************************************
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  gv_header_number            VARCHAR2(20);
  gn_person_id                fnd_user.employee_id%TYPE;
  gn_group_id                 NUMBER;                     -- �O���[�vID
  gn_group_id2                NUMBER;                     -- �O���[�vID
  gv_request_no               VARCHAR2(12);               -- �˗�NO
  gn_txns_id                  xxpo_rcv_and_rtn_txns.txns_id%TYPE;
  gv_defaultlot               VARCHAR2(100);              -- �f�t�H���g���b�g
--
  -- �萔
  gn_created_by               NUMBER;                     -- �쐬��
  gd_creation_date            DATE;                       -- �쐬��
  gd_last_update_date         DATE;                       -- �ŏI�X�V��
  gn_last_update_by           NUMBER;                     -- �ŏI�X�V��
  gn_last_update_login        NUMBER;                     -- �ŏI�X�V���O�C��
  gn_request_id               NUMBER;                     -- �v��ID
  gn_program_application_id   NUMBER;                     -- �v���O�����A�v���P�[�V����ID
  gn_program_id               NUMBER;                     -- �v���O����ID
  gd_program_update_date      DATE;                       -- �v���O�����X�V��
--
  gn_b_3_cnt                  NUMBER;
  gn_b_5_cnt                  NUMBER;
  gn_b_7_cnt                  NUMBER;
  gn_b_9_cnt                  NUMBER;
--
  gn_b_15_flg                 NUMBER;
  gn_b_16_flg                 NUMBER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
  CURSOR gc_lock_xrt_cur
  IS
    SELECT xrt.txns_id
    FROM   xxpo_rcv_and_rtn_txns xrt
    WHERE  xrt.source_document_number = gv_header_number
    FOR UPDATE OF xrt.txns_id NOWAIT;
--
  /***********************************************************************************
   * Procedure Name   : check_quantity
   * Description      : �d����o�א��ʂ̃`�F�b�N
   ***********************************************************************************/
  PROCEDURE check_quantity(
    or_retcd           OUT NOCOPY BOOLEAN,      -- �`�F�b�N����
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_quantity'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_cnt              NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    or_retcd := TRUE;
--
    SELECT COUNT(pha.po_header_id)
    INTO   ln_cnt
    FROM   po_headers_all pha,                            -- �����w�b�_
           po_lines_all  pla                              -- ��������
    WHERE  pha.po_header_id = pla.po_header_id
    AND    pha.segment1     = gv_header_number
    AND    pla.attribute6 IS NULL                         -- �d����o�א��ʂ��ݒ肳��Ă��Ȃ�
    AND    ROWNUM           = 1;
--
    IF (ln_cnt > 0) THEN
      or_retcd := FALSE;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END check_quantity;
--
  /***********************************************************************************
   * Procedure Name   : set_req_status
   * Description      : �o�׈˗�/�x���˗��X�e�[�^�X�̐ݒ�
   ***********************************************************************************/
  PROCEDURE set_req_status(
    ir_masters_rec  IN OUT NOCOPY mst_b_6_rec,  -- B-6:�o�׎��э쐬�p�^�[��
    ov_status          OUT NOCOPY VARCHAR2,     -- ���ʃX�e�[�^�X
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_req_status'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_cnt              NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    ov_status := gv_req_status_appr;                    -- �o�׎��ьv���
--
    SELECT  COUNT(pha.po_header_id)
    INTO    ln_cnt
    FROM    po_headers_all pha               -- �����w�b�_
           ,po_lines_all pla                 -- ��������
    WHERE   pha.po_header_id = pla.po_header_id
    AND     pha.po_header_id = ir_masters_rec.po_header_id
    AND     pla.attribute6 IS NULL
    AND     ROWNUM = 1;
--
    IF (ln_cnt > 0) THEN
      ov_status := gv_req_status_rect;                    -- ��̍�
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END set_req_status;
--
  /***********************************************************************************
   * Procedure Name   : ins_rcv_transactions
   * Description      : �������I�[�v��IF�̍쐬
   ***********************************************************************************/
  PROCEDURE ins_rcv_transactions(
    ir_masters_rec  IN OUT NOCOPY masters_rec,
    ir_mst_rec      IN OUT NOCOPY mst_b_5_rec,
    in_group_id     IN            NUMBER,
-- 2008/12/30 v1.13 T.Yoshimoto Add Start
    ln_dest_type    IN            NUMBER,       -- ���(0), ����(1)
-- 2008/12/30 v1.13 T.Yoshimoto Add End
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_rcv_transactions'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_use_mtl_lot   rcv_transactions_interface.use_mtl_lot%TYPE;
    lv_dest_code     rcv_transactions_interface.destination_type_code%TYPE;
    lv_dest_text     rcv_transactions_interface.destination_context%TYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    ln_use_mtl_lot := 1;
--
    -- ���b�g�Ǘ��i
    IF (ir_masters_rec.lot_ctl = gn_lot_ctl_on) THEN
      ln_use_mtl_lot := 2;
    END IF;
--
-- 2008/12/30 v1.13 T.Yoshimoto Add Start
    -- �������
--    IF (ir_masters_rec.rcv_cov_qty > 0) THEN
    IF (ln_dest_type = 0) THEN
-- 2008/12/30 v1.13 T.Yoshimoto Add End
      lv_dest_code := gv_dest_type_receive;
      lv_dest_text := gv_dest_type_receive;
--
    -- ��������
    ELSE
      lv_dest_code := gv_dest_type_inv;
      lv_dest_text := gv_dest_type_inv;
    END IF;
--
    -- �������I�[�v��IF�̍쐬
    INSERT INTO rcv_transactions_interface
    (
         interface_transaction_id
        ,group_id
        ,last_update_date
        ,last_updated_by
        ,creation_date
        ,created_by
        ,last_update_login
        ,transaction_type
        ,transaction_date
        ,processing_status_code
        ,processing_mode_code
        ,transaction_status_code
        ,category_id
        ,quantity
        ,unit_of_measure
        ,item_id
        ,item_description
        ,uom_code
        ,employee_id
        ,shipment_header_id
        ,shipment_line_id
        ,primary_quantity
        ,primary_unit_of_measure
        ,receipt_source_code
        ,vendor_id
        ,vendor_site_id
        ,from_organization_id
        ,from_subinventory
        ,to_organization_id
        ,routing_header_id
        ,routing_step_id
        ,source_document_code
        ,parent_transaction_id
        ,po_header_id
        ,po_line_id
        ,po_line_location_id
        ,po_unit_price
        ,currency_code
        ,currency_conversion_rate
        ,po_distribution_id
        ,inspection_status_code
        ,destination_type_code
        ,locator_id
        ,destination_context
        ,use_mtl_lot
        ,use_mtl_serial
        ,from_locator_id
    )
    SELECT 
         rcv_transactions_interface_s.NEXTVAL              -- interface_transaction_id
        ,in_group_id                                       -- group_id
        ,gd_last_update_date                               -- last_update_date
        ,gn_last_update_by                                 -- last_updated_by
        ,gd_creation_date                                  -- creation_date
        ,gn_created_by                                     -- created_by
        ,gn_last_update_login                              -- last_update_login
        ,gv_trans_type_correct                             -- transaction_type
-- 2008/12/04 v1.9 T.Yoshimoto Mod Start �{�ԏ�Q#420
        --,SYSDATE                                           -- transaction_date
        ,TO_DATE(ir_masters_rec.pla_def5, 'YYYY/MM/DD')    -- transaction_date(�d����o�ד�)
-- 2008/12/04 v1.9 T.Yoshimoto Mod End �{�ԏ�Q#420
        ,'PENDING'                                         -- processing_status_code
        ,'BATCH'                                           -- processing_mode_code
        ,'PENDING'                                         -- transaction_status_code
        ,ir_mst_rec.category_id                            -- category_id
        ,ir_masters_rec.rcv_cov_qty                        -- quantity
        ,ir_mst_rec.unit_of_measure                        -- unit_of_measure
        ,ir_masters_rec.item_id                            -- item_id
        ,ir_mst_rec.item_description                       -- item_description
        ,ir_mst_rec.uom_code                               -- uom_code
        ,gn_person_id                                      -- employee_id
        ,ir_mst_rec.shipment_header_id                     -- shipment_header_id
        ,ir_mst_rec.shipment_line_id                       -- shipment_line_id
        -- 2008/05/24 UPD START Y.Takayama
        --,ir_masters_rec.def_qty7                           -- primary_quantity
        ,ir_masters_rec.rcv_cov_qty                        -- primary_quantity
        -- 2008/05/24 UPD END   Y.Takayama
        ,ir_mst_rec.primary_unit_of_measure                -- primary_unit_of_measure
        ,'VENDOR'                                          -- receipt_source_code
        ,ir_masters_rec.vendor_id                          -- vendor_id
        ,ir_mst_rec.vendor_site_id                         -- vendor_site_id
        ,ir_mst_rec.organization_id                        -- from_organization_id
        ,ir_mst_rec.subinventory                           -- from_subinventory
        ,ir_mst_rec.organization_id                        -- to_organization_id
        ,ir_mst_rec.routing_header_id                      -- routing_header_id
        ,1                                                 -- routing_step_id
        ,'PO'                                              -- source_document_code
        ,ir_mst_rec.transaction_id                         -- parent_transaction_id
        ,ir_masters_rec.po_header_id                       -- po_header_id
        ,ir_masters_rec.po_line_id                         -- po_line_id
        ,ir_mst_rec.po_line_location_id                    -- po_line_location_id
        ,ir_mst_rec.po_unit_price                          -- po_unit_price
        ,ir_mst_rec.currency_code                          -- currency_code
        ,ir_mst_rec.currency_conversion_rate               -- currency_conversion_rate
        ,ir_mst_rec.po_distribution_id                     -- po_distribution_id
        ,'NOT INSPECTED'                                   -- inspection_status_code
        ,lv_dest_code                                      -- destination_type_code
        ,ir_mst_rec.locator_id                             -- locator_id
        ,lv_dest_text                                      -- destination_context
        ,ln_use_mtl_lot                                    -- use_mtl_lot
        ,1                                                 -- use_mtl_serial
        ,ir_mst_rec.locator_id                             -- from_locator_id
    FROM DUAL;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END ins_rcv_transactions;
--
  /***********************************************************************************
   * Procedure Name   : get_open_deli_if
   * Description      : ����I�[�v��IF�̔��������p�f�[�^�̎擾
   ***********************************************************************************/
  PROCEDURE get_open_deli_if(
    ir_masters_rec  IN OUT NOCOPY masters_rec,
    ir_mst_rec      IN OUT NOCOPY mst_b_5_rec,
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_open_deli_if'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    SELECT rsl.category_id
          ,rsl.unit_of_measure
          ,rsl.item_description
          ,rt.uom_code
          ,rsl.shipment_header_id
          ,rsl.shipment_line_id
          ,rt.primary_unit_of_measure
          ,rt.vendor_site_id
          ,rt.organization_id
          ,rt.subinventory
          ,rsl.routing_header_id
          ,rt.transaction_id
          ,rsl.po_line_location_id
          ,rt.po_unit_price
          ,rt.currency_code
          ,rt.currency_conversion_rate
          ,rsl.po_distribution_id
          ,rt.locator_id
    INTO   ir_mst_rec.category_id
          ,ir_mst_rec.unit_of_measure
          ,ir_mst_rec.item_description
          ,ir_mst_rec.uom_code
          ,ir_mst_rec.shipment_header_id
          ,ir_mst_rec.shipment_line_id
          ,ir_mst_rec.primary_unit_of_measure
          ,ir_mst_rec.vendor_site_id
          ,ir_mst_rec.organization_id
          ,ir_mst_rec.subinventory
          ,ir_mst_rec.routing_header_id
          ,ir_mst_rec.transaction_id
          ,ir_mst_rec.po_line_location_id
          ,ir_mst_rec.po_unit_price
          ,ir_mst_rec.currency_code
          ,ir_mst_rec.currency_conversion_rate
          ,ir_mst_rec.po_distribution_id
          ,ir_mst_rec.locator_id
    FROM   rcv_shipment_lines rsl,
           rcv_transactions   rt
    WHERE  rt.transaction_type      = gv_trans_type_deliver
    AND    rt.destination_type_code = gv_dest_type_inv
    AND    rt.destination_context   = gv_dest_type_inv
    AND    rt.shipment_line_id      = rsl.shipment_line_id
    AND    rt.parent_transaction_id in
    (
     SELECT transaction_id 
     FROM   rcv_transactions
     WHERE  parent_transaction_id = -1
     AND    po_header_id          = ir_masters_rec.po_header_id
     AND    po_line_id            = ir_masters_rec.po_line_id
    );
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END get_open_deli_if;
--
  /***********************************************************************************
   * Procedure Name   : get_open_rcv_if
   * Description      : ����I�[�v��IF�̎�������p�f�[�^�̎擾
   ***********************************************************************************/
  PROCEDURE get_open_rcv_if(
    ir_masters_rec  IN OUT NOCOPY masters_rec,
    ir_mst_rec      IN OUT NOCOPY mst_b_5_rec,
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_open_rcv_if'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    SELECT rsl.category_id
          ,rsl.unit_of_measure
          ,rsl.item_description
          ,rt.uom_code
          ,rsl.shipment_header_id
          ,rsl.shipment_line_id
          ,rt.primary_unit_of_measure
          ,rt.vendor_site_id
          ,rt.organization_id
          ,rt.subinventory
          ,rsl.routing_header_id
          ,rt.transaction_id
          ,rsl.po_line_location_id
          ,rt.po_unit_price
          ,rt.currency_code
          ,rt.currency_conversion_rate
          ,rsl.po_distribution_id
          ,rt.locator_id
    INTO   ir_mst_rec.category_id
          ,ir_mst_rec.unit_of_measure
          ,ir_mst_rec.item_description
          ,ir_mst_rec.uom_code
          ,ir_mst_rec.shipment_header_id
          ,ir_mst_rec.shipment_line_id
          ,ir_mst_rec.primary_unit_of_measure
          ,ir_mst_rec.vendor_site_id
          ,ir_mst_rec.organization_id
          ,ir_mst_rec.subinventory
          ,ir_mst_rec.routing_header_id
          ,ir_mst_rec.transaction_id
          ,ir_mst_rec.po_line_location_id
          ,ir_mst_rec.po_unit_price
          ,ir_mst_rec.currency_code
          ,ir_mst_rec.currency_conversion_rate
          ,ir_mst_rec.po_distribution_id
          ,ir_mst_rec.locator_id
    FROM   rcv_shipment_lines rsl,
           rcv_transactions rt
    WHERE  rt.parent_transaction_id = -1
    AND    rt.transaction_type      = gv_trans_type_receive
    AND    rt.destination_type_code = gv_dest_type_receive
    AND    rt.destination_context   = gv_dest_type_receive
    AND    rt.shipment_line_id      = rsl.shipment_line_id
    AND    rt.po_header_id          = ir_masters_rec.po_header_id
    AND    rt.po_line_id            = ir_masters_rec.po_line_id;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END get_open_rcv_if;
--
  /***********************************************************************************
   * Procedure Name   : mod_open_rcv_if
   * Description      : ����I�[�v��IF�̎�������p�f�[�^�̍쐬
   ***********************************************************************************/
  PROCEDURE mod_open_rcv_if(
    ir_masters_rec  IN OUT NOCOPY masters_rec,
    in_group_id     IN            NUMBER,
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'mod_open_rcv_if'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lr_mst_rec       mst_b_5_rec;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ��������Ώۃf�[�^�擾
    get_open_rcv_if(
      ir_masters_rec,
      lr_mst_rec,
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- �������I�[�v��IF�̍쐬
    ins_rcv_transactions(
      ir_masters_rec,
      lr_mst_rec,
      in_group_id,
-- 2008/12/30 v1.13 T.Yoshimoto Add Start
      0,                  -- ���(0), ����(1)
-- 2008/12/30 v1.13 T.Yoshimoto Add End
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END mod_open_rcv_if;
--
  /***********************************************************************************
   * Procedure Name   : mod_open_deli_if
   * Description      : ����I�[�v��IF�̔��������p�f�[�^�̍쐬
   ***********************************************************************************/
  PROCEDURE mod_open_deli_if(
    ir_masters_rec  IN OUT NOCOPY masters_rec,
    in_group_id     IN            NUMBER,
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'mod_open_deli_if'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lr_mst_rec       mst_b_5_rec;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ���������Ώۃf�[�^�擾
    get_open_deli_if(
      ir_masters_rec,
      lr_mst_rec,
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- �������I�[�v��IF�̍쐬
    ins_rcv_transactions(
      ir_masters_rec,
      lr_mst_rec,
      in_group_id,
-- 2008/12/30 v1.13 T.Yoshimoto Add Start
      1,                  -- ���(0), ����(1)
-- 2008/12/30 v1.13 T.Yoshimoto Add End
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ���b�g�Ǘ��i
    IF (ir_masters_rec.lot_ctl = gn_lot_ctl_on) THEN
--
      -- ������b�g�I�[�v��IF�̍쐬
      INSERT INTO rcv_lots_interface
      (
           interface_transaction_id
          ,last_update_date
          ,last_updated_by
          ,creation_date
          ,created_by
          ,last_update_login
          ,lot_num
          ,quantity
          ,transaction_date
          ,expiration_date
          ,primary_quantity
          ,item_id
          ,shipment_line_id
      )
      SELECT
           rcv_transactions_interface_s.CURRVAL   -- interface_transaction_id
          ,gd_last_update_date                    -- last_update_date
          ,gn_last_update_by                      -- last_updated_by
          ,gd_creation_date                       -- creation_date
          ,gn_created_by                          -- created_by
          ,gn_last_update_login                   -- last_update_login
          ,ir_masters_rec.lot_no                  -- lot_num
          ,ABS(ir_masters_rec.rcv_cov_qty)        -- quantity
          ,SYSDATE                                -- transaction_date
          ,ir_masters_rec.expire_date             -- expiration_date
          -- 2008/05/24 UPD START Y.Takayama
          --,ABS(ir_masters_rec.def_qty7)           -- primary_quantity
          ,ABS(ir_masters_rec.rcv_cov_qty)          -- primary_quantity
          -- 2008/05/24 UPD END   Y.Takayama
          ,ir_masters_rec.item_id                 -- item_id
          ,lr_mst_rec.shipment_line_id            -- shipment_line_id
      FROM DUAL;
--
      -- INV���b�g����I�[�v��IF�̍쐬
      INSERT INTO mtl_transaction_lots_interface
      (
           transaction_interface_id
          ,source_code
          ,last_update_date
          ,last_updated_by
          ,creation_date
          ,created_by
          ,last_update_login
          ,lot_number
          ,lot_expiration_date
          ,transaction_quantity
          ,primary_quantity
          ,process_flag
          ,product_code
          ,product_transaction_id
      )
      SELECT
           mtl_material_transactions_s.NEXTVAL    -- transaction_interface_id
          ,'RCV'                                  -- source_code
          ,gd_last_update_date                    -- last_update_date
          ,gn_last_update_by                      -- last_updated_by
          ,gd_creation_date                       -- creation_date
          ,gn_created_by                          -- created_by
          ,gn_last_update_login                   -- last_update_login
          ,ir_masters_rec.lot_no                  -- lot_number
          ,ir_masters_rec.expire_date             -- lot_expiration_date
          ,ABS(ir_masters_rec.rcv_cov_qty)        -- transaction_quantity
          -- 2008/05/24 UPD START Y.Takayama
          --,ABS(ir_masters_rec.def_qty7)         -- primary_quantity
          ,ABS(ir_masters_rec.rcv_cov_qty)        -- primary_quantity
          -- 2008/05/24 UPD START Y.Takayama
          ,'1'                                    -- process_flag
          ,'RCV'                                  -- product_code
          ,rcv_transactions_interface_s.CURRVAL   -- product_transaction_id
      FROM DUAL;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END mod_open_deli_if;
--
  /***********************************************************************************
   * Procedure Name   : proc_xxpo_rcv_ins
   * Description      : ����ԕi����(�A�h�I��)�̍쐬����
   ***********************************************************************************/
  PROCEDURE proc_xxpo_rcv_ins(
    ir_masters_rec  IN OUT NOCOPY masters_rec,
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_xxpo_rcv_ins'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_segment1                po_vendors.segment1%TYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �����R�[�h�̎擾
    BEGIN
      SELECT pv.segment1
      INTO   lv_segment1
      FROM   po_vendors pv
      WHERE  pv.vendor_id = ir_masters_rec.vendor_id
      AND    ROWNUM = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_segment1 := NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- ����ԕi����(�A�h�I��)�̍쐬
    INSERT INTO xxpo_rcv_and_rtn_txns
    (
         txns_id
        ,txns_type
        ,rcv_rtn_number
        ,rcv_rtn_line_number
        ,source_document_number
        ,source_document_line_num
        ,supply_requested_number
        ,drop_ship_type
        ,vendor_id
        ,vendor_code
        ,assen_vendor_id
        ,assen_vendor_code
        ,location_id
        ,location_code
        ,txns_date
        ,item_id
        ,item_code
        ,lot_id
        ,lot_number
        ,rcv_rtn_quantity
        ,rcv_rtn_uom
        ,quantity
        ,uom
        ,conversion_factor
        ,unit_price
        ,department_code
        ,created_by
        ,creation_date
        ,last_updated_by
        ,last_update_date
        ,last_update_login
        ,request_id
        ,program_application_id
        ,program_id
        ,program_update_date
    )
    SELECT
         gn_txns_id                                      -- txns_id
        ,gv_txns_type                                    -- txns_type
        ,ir_masters_rec.po_header_number                 -- rcv_rtn_number
-- 2009/01/13 v1.15 T.Yoshimoto Mod Start
        --,ir_masters_rec.line_num                         -- rcv_rtn_line_number
        ,'1'                                             -- rcv_rtn_line_number
-- 2009/01/13 v1.15 T.Yoshimoto Mod End
        ,ir_masters_rec.po_header_number                 -- source_document_number
-- 2009/01/13 v1.15 T.Yoshimoto Mod Start
-- 2009/01/08 v1.14 T.Yoshimoto Mod Start
        ,ir_masters_rec.line_num                         -- source_document_line_num
        --,'1'                                             -- source_document_line_num
-- 2009/01/08 v1.14 T.Yoshimoto Mod End
-- 2009/01/13 v1.15 T.Yoshimoto Mod End
        ,ir_masters_rec.attribute9                       -- supply_requested_number
        ,ir_masters_rec.drop_ship_type                   -- drop_ship_type
        ,ir_masters_rec.vendor_id                        -- vendor_id
        ,lv_segment1                                     -- vendor_code
        ,ir_masters_rec.assen_vendor_id                  -- assen_vendor_id
        ,ir_masters_rec.assen_vendor_code                -- assen_vendor_code
        ,ir_masters_rec.inv_location_id                  -- location_id
        ,ir_masters_rec.pha_def5                         -- location_code
        ,ir_masters_rec.def_date5                        -- txns_date
        ,ir_masters_rec.item_idv                         -- item_id
        ,ir_masters_rec.item_no                          -- item_code
        ,ir_masters_rec.lot_id                           -- lot_id
        ,ir_masters_rec.lot_no                           -- lot_number
        ,ir_masters_rec.def_qty6                         -- rcv_rtn_quantity
        ,ir_masters_rec.attribute10                      -- rcv_rtn_uom
        ,ir_masters_rec.rcv_qty                          -- quantity
        ,ir_masters_rec.unit_code                        -- uom
        ,ir_masters_rec.conv_factor                      -- conversion_factor
        ,ir_masters_rec.unit_price                       -- unit_price
        ,ir_masters_rec.h_attribute10                    -- department_code
        ,gn_created_by                                   -- created_by
        ,gd_creation_date                                -- creation_date
        ,gn_last_update_by                               -- last_updated_by
        ,gd_last_update_date                             -- last_update_date
        ,gn_last_update_login                            -- last_update_login
        ,gn_request_id                                   -- request_id
        ,gn_program_application_id                       -- program_application_id
        ,gn_program_id                                   -- program_id
        ,gd_program_update_date                          -- program_update_date
    FROM DUAL;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END proc_xxpo_rcv_ins;
--
  /***********************************************************************************
   * Procedure Name   : create_mov_lot
   * Description      : �ړ����b�g�ڍ׍쐬(�V�K�o�^�p)(B-18)
   ***********************************************************************************/
  PROCEDURE create_mov_lot(
    ir_mst_b_7_rec  IN OUT NOCOPY mst_b_7_rec,  -- B-7:�o�׎��э쐬�Ώۃf�[�^�擾
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_mov_lot'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lr_mov_lot    xxinv_mov_lot_details%ROWTYPE;
    ln_flg        NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- 1.���ѓ��̍X�V
    BEGIN
      UPDATE xxinv_mov_lot_details
      SET    actual_date            = ir_mst_b_7_rec.def_date4
            ,last_updated_by        = gn_last_update_by
            ,last_update_date       = gd_last_update_date
            ,last_update_login      = gn_last_update_login
            ,request_id             = gn_request_id
            ,program_application_id = gn_program_application_id
            ,program_id             = gn_program_id
            ,program_update_date    = gd_program_update_date
      WHERE  mov_line_id        = ir_mst_b_7_rec.order_line_id
      AND    document_type_code = gv_document_type           -- �x���w��
      AND    record_type_code   = gv_record_type;            -- �o�Ɏ���
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- 2.�ړ����b�g�ڍ�(�A�h�I��)����o�ɏ��̎擾
    ln_flg := 1;
    BEGIN
      SELECT xmld.mov_lot_dtl_id                          -- ���b�g�ڍ�ID
            ,xmld.actual_quantity                         -- ���ѐ���
      INTO   lr_mov_lot.mov_lot_dtl_id
            ,lr_mov_lot.actual_quantity
      FROM   xxinv_mov_lot_details xmld
      WHERE  xmld.mov_line_id        = ir_mst_b_7_rec.order_line_id
      AND    xmld.document_type_code = gv_document_type           -- �x���w��
      AND    xmld.record_type_code   = gv_record_type;            -- �o�Ɏ���
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_flg := 0;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- 3.�o�ɏ�񂪑��݂���ꍇ�A�o�ɏ����X�V
    IF (ln_flg = 1) THEN
--
      BEGIN
        UPDATE xxinv_mov_lot_details
        SET    actual_quantity        = ir_mst_b_7_rec.def_qty6   -- ���ѐ���
              ,last_updated_by        = gn_last_update_by
              ,last_update_date       = gd_last_update_date
              ,last_update_login      = gn_last_update_login
              ,request_id             = gn_request_id
              ,program_application_id = gn_program_application_id
              ,program_id             = gn_program_id
              ,program_update_date    = gd_program_update_date
        WHERE mov_lot_dtl_id = lr_mov_lot.mov_lot_dtl_id
        AND   actual_quantity <> ir_mst_b_7_rec.def_qty6;        -- �d����o�א��� <> ���ѐ���
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
--
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
--
    -- 4.�o�ɏ�񂪑��݂��Ȃ��ꍇ�A�o�ɏ����쐬
    ELSE
--
      INSERT INTO xxinv_mov_lot_details
      (
         mov_lot_dtl_id                                  -- ���b�g�ڍ�ID
        ,mov_line_id                                     -- ����ID
        ,document_type_code                              -- �����^�C�v
        ,record_type_code                                -- ���R�[�h�^�C�v
        ,item_id                                         -- OPM�i��ID
        ,item_code                                       -- �i��
        ,lot_id                                          -- ���b�gID
        ,lot_no                                          -- ���b�gNo
        ,actual_date                                     -- ���ѓ�
        ,actual_quantity                                 -- ���ѐ���
        ,created_by
        ,creation_date
        ,last_updated_by
        ,last_update_date
        ,last_update_login
        ,request_id
        ,program_application_id
        ,program_id
        ,program_update_date
      )
      SELECT xxinv_mov_lot_s1.NEXTVAL                        -- mov_lot_dtl_id
            ,mov_line_id                                     -- ����ID
            ,document_type_code                              -- �����^�C�v
            ,gv_record_type                                  -- ���R�[�h�^�C�v
            ,item_id                                         -- OPM�i��ID
            ,item_code                                       -- �i��
            ,lot_id                                          -- ���b�gID
            ,lot_no                                          -- ���b�gNo
            ,ir_mst_b_7_rec.def_date4                        -- ���ѓ�
            ,ir_mst_b_7_rec.def_qty6                         -- ���ѐ���
            ,gn_created_by                                   -- created_by
            ,gd_creation_date                                -- creation_date
            ,gn_last_update_by                               -- last_updated_by
            ,gd_last_update_date                             -- last_update_date
            ,gn_last_update_login                            -- last_update_login
            ,gn_request_id                                   -- request_id
            ,gn_program_application_id                       -- program_application_id
            ,gn_program_id                                   -- program_id
            ,gd_program_update_date                          -- program_update_date
      FROM   xxinv_mov_lot_details
      WHERE  mov_line_id        = ir_mst_b_7_rec.order_line_id
      AND    document_type_code = gv_document_type           -- �x���w��
      AND    record_type_code   = gv_indicate;               -- �w��
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END create_mov_lot;
--
  /***********************************************************************************
   * Procedure Name   : proc_rcv_exec
   * Description      : �����������N��(B-15)
   ***********************************************************************************/
  PROCEDURE proc_rcv_exec(
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_rcv_exec'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lb_ret        BOOLEAN;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �v���Z�b�g�̐ݒ�
    lb_ret := FND_SUBMIT.SUBMIT_PROGRAM(gv_rcv_app,
                                        gv_rcv_app_name,
                                        gv_rcv_stage,
                                        'BATCH',TO_CHAR(gn_group_id));
--
    IF (NOT lb_ret) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            'APP-XXPO-10024',
                                            gv_tkn_conc_name,
                                            gv_request_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    gn_b_15_flg := 1;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END proc_rcv_exec;
--
  /***********************************************************************************
   * Procedure Name   : proc_deli_exec
   * Description      : �o�׈˗�/�o�׎��э쐬�����N��(B-16)
   ***********************************************************************************/
  PROCEDURE proc_deli_exec(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_deli_exec'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lb_ret        BOOLEAN;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �˗�NO�̏o��
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          'APP-XXPO-30023',
                                          gv_tkn_request_num,
                                          gv_request_no);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
-- Ver1.11 M.Hokkanji Start
    -- �v���Z�b�g�̐ݒ�
--    lb_ret := FND_SUBMIT.SUBMIT_PROGRAM(gv_deli_app,
--                                        gv_deli_app_name,
--                                        gv_deli_stage,
--                                        NULL,NULL,gv_request_no);
--
--    IF (NOT lb_ret) THEN
--      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
--                                            'APP-XXPO-10024',
--                                            gv_tkn_conc_name,
--                                            gv_request_name);
 --     lv_errbuf := lv_errmsg;
 --     RAISE global_api_expt;
--    END IF;
--
--    gn_b_16_flg := 1;
-- Ver1.11 M.Hokkanji End
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END proc_deli_exec;
--
  /***********************************************************************************
   * Procedure Name   : proc_rcv_if
   * Description      : ����I�[�v���C���^�t�F�[�X�̍쐬����
   ***********************************************************************************/
  PROCEDURE proc_rcv_if(
    ir_masters_rec  IN OUT NOCOPY masters_rec,
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_rcv_if'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lr_mst_rec       mst_b_5_rec;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ���ڎ��
    IF (ir_masters_rec.trans_type = gv_trans_type_receive) THEN
--
      -- ����w�b�_�I�[�v��IF�̍쐬
      INSERT INTO rcv_headers_interface
      (
           header_interface_id
          ,group_id
          ,processing_status_code
          ,receipt_source_code
          ,transaction_type
          ,last_update_date
          ,last_updated_by
          ,last_update_login
          ,creation_date
          ,created_by
          ,vendor_id
          ,expected_receipt_date
          ,validation_flag
      )
      SELECT 
           rcv_headers_interface_s.NEXTVAL                 -- header_interface_id
          ,gn_group_id                                     -- group_id
          ,'PENDING'                                       -- processing_status_code
          ,'VENDOR'                                        -- receipt_source_code
          ,'NEW'                                           -- transaction_type
          ,gd_last_update_date                             -- last_update_date
          ,gn_last_update_by                               -- last_updated_by
          ,gn_last_update_login                            -- last_update_login
          ,gd_creation_date                                -- creation_date
          ,gn_created_by                                   -- created_by
          ,ir_masters_rec.vendor_id                        -- vendor_id
          ,ir_masters_rec.def_date4                        -- expected_receipt_date
          ,gv_flg_on                                       -- validation_flag
      FROM DUAL;
--
      -- �������I�[�v��IF�̍쐬
      INSERT INTO rcv_transactions_interface
      (
           interface_transaction_id
          ,group_id
          ,last_update_date
          ,last_updated_by
          ,creation_date
          ,created_by
          ,last_update_login
          ,transaction_type
          ,transaction_date
          ,processing_status_code
          ,processing_mode_code
          ,transaction_status_code
          ,quantity
          ,unit_of_measure
          ,item_id
          ,auto_transact_code
          ,receipt_source_code
          ,to_organization_id
          ,source_document_code
          ,po_header_id
          ,po_line_id
          ,po_line_location_id
          ,destination_type_code
          ,subinventory
          ,locator_id
          ,expected_receipt_date
          ,ship_line_attribute1
          ,header_interface_id
          ,validation_flag
      )
      SELECT
           rcv_transactions_interface_s.NEXTVAL            -- interface_transaction_id
          ,gn_group_id                                     -- group_id
          ,gd_last_update_date                             -- last_update_date
          ,gn_last_update_by                               -- last_updated_by
          ,gd_creation_date                                -- creation_date
          ,gn_created_by                                   -- created_by
          ,gn_last_update_login                            -- last_update_login
          ,ir_masters_rec.trans_type                       -- transaction_type
          ,ir_masters_rec.def_date4                        -- transaction_date
          ,'PENDING'                                       -- processing_status_code
          ,'BATCH'                                         -- processing_mode_code
          ,'PENDING'                                       -- transaction_status_code
          -- 2008/05/24 UPD START Y.Takayama
          --,ir_masters_rec.def_qty7                       -- quantity
          ,ir_masters_rec.rcv_cov_qty                      -- quantity
          -- 2008/05/24 UPD END   Y.Takayama
          ,ir_masters_rec.unit_code                        -- unit_of_measure
          ,ir_masters_rec.item_id                          -- item_id
          ,'DELIVER'                                       -- auto_transact_code
          ,'VENDOR'                                        -- receipt_source_code
          ,ir_masters_rec.organization_id                  -- to_organization_id
          ,'PO'                                            -- source_document_code
          ,ir_masters_rec.po_header_id                     -- po_header_id
          ,ir_masters_rec.po_line_id                       -- po_line_id
          ,ir_masters_rec.po_line_id                       -- po_line_location_id
          ,'INVENTORY'                                     -- destination_type_code
          ,ir_masters_rec.subinventory                     -- subinventory
          ,ir_masters_rec.locator_id                       -- locator_id
          ,ir_masters_rec.def_date4                        -- expected_receipt_date
          ,TO_CHAR(gn_txns_id)                             -- ship_line_attribute1
          ,rcv_headers_interface_s.CURRVAL                 -- header_interface_id
          ,gv_flg_on                                       -- validation_flag
      FROM DUAL;
--
      -- ���b�g�Ǘ��i�̏ꍇ
      IF (ir_masters_rec.lot_ctl = gn_lot_ctl_on) THEN
--
        -- INV���b�g����I�[�v��IF�̍쐬
        INSERT INTO mtl_transaction_lots_interface
        (
             transaction_interface_id
            ,last_update_date
            ,last_updated_by
            ,creation_date
            ,created_by
            ,last_update_login
            ,lot_number
            ,transaction_quantity
            ,primary_quantity
            ,product_code
            ,product_transaction_id
        )
        SELECT
             mtl_material_transactions_s.NEXTVAL           -- transaction_interface_id
            ,gd_last_update_date                           -- last_update_date
            ,gn_last_update_by                             -- last_updated_by
            ,gd_creation_date                              -- creation_date
            ,gn_created_by                                 -- created_by
            ,gn_last_update_login                          -- last_update_login
            ,ir_masters_rec.lot_no                         -- lot_number
            -- 2008/05/24 UPD START Y.Takayama
            --,ABS(ir_masters_rec.def_qty7)                -- transaction_quantity
            --,ABS(ir_masters_rec.def_qty7)                -- primary_quantity
            ,ABS(ir_masters_rec.rcv_cov_qty)               -- transaction_quantity
            ,ABS(ir_masters_rec.rcv_cov_qty)               -- primary_quantity
            -- 2008/05/24 UPD END   Y.Takayama
            ,'RCV'                                         -- product_code
            ,rcv_transactions_interface_s.CURRVAL          -- product_transaction_id
        FROM DUAL;
      END IF;
--
    -- ����
    ELSIF (ir_masters_rec.trans_type = gv_trans_type_correct) THEN
--
      IF (ir_masters_rec.rcv_cov_qty > 0) THEN
--
        SELECT rcv_interface_groups_s.NEXTVAL
        INTO   gn_group_id2
        FROM   DUAL;
--
        -- �������
        mod_open_rcv_if(
          ir_masters_rec,
          gn_group_id2,
          lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        SELECT rcv_interface_groups_s.NEXTVAL
        INTO   gn_group_id
        FROM   DUAL;
--
        -- ��������
        mod_open_deli_if(
          ir_masters_rec,
          gn_group_id,
          lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
      ELSE
--
        SELECT rcv_interface_groups_s.NEXTVAL
        INTO   gn_group_id2
        FROM   DUAL;
--
        -- ��������
        mod_open_deli_if(
          ir_masters_rec,
          gn_group_id2,
          lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        SELECT rcv_interface_groups_s.NEXTVAL
        INTO   gn_group_id
        FROM   DUAL;
--
        -- �������
        mod_open_rcv_if(
          ir_masters_rec,
          gn_group_id,
          lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
      END IF;
    END IF;
--
    gn_b_5_cnt := gn_b_5_cnt + 1;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END proc_rcv_if;
--
  /***********************************************************************************
   * Procedure Name   : upd_xxpo_data
   * Description      : �󒍃w�b�_�A�h�I����� �X�V(B-10)
   *                    (�ŐV�f�[�^������O�f�[�^�ɕύX)
   ***********************************************************************************/
  PROCEDURE upd_xxpo_data(
    ir_masters_rec  IN OUT NOCOPY mst_b_6_rec,  -- B-6:�o�׎��э쐬�p�^�[��
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_xxpo_data'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_order_header_id                xxwsh_order_headers_all.order_header_id%TYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �󒍃w�b�_�A�h�I���̃��b�N
    BEGIN
      SELECT xha.order_header_id
      INTO   ln_order_header_id
      FROM   xxwsh_order_headers_all xha
      WHERE  xha.order_header_id = ir_masters_rec.order_header_id
      FOR UPDATE OF xha.order_header_id NOWAIT;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
--
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              'APP-XXPO-10138');
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- �󒍃w�b�_�A�h�I���̍X�V
    BEGIN
      UPDATE xxwsh_order_headers_all
      SET    latest_external_flag   = gv_flg_off
            ,last_updated_by        = gn_last_update_by
            ,last_update_date       = gd_last_update_date
            ,last_update_login      = gn_last_update_login
            ,request_id             = gn_request_id
            ,program_application_id = gn_program_application_id
            ,program_id             = gn_program_id
            ,program_update_date    = gd_program_update_date
      WHERE  order_header_id        = ir_masters_rec.order_header_id;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END upd_xxpo_data;
--
  /***********************************************************************************
   * Procedure Name   : mod_xxpo_data
   * Description      : �󒍃A�h�I����� �o�^(�����f�[�^�o�^)(B-11)
   ***********************************************************************************/
  PROCEDURE mod_xxpo_data(
    ir_masters_rec  IN OUT NOCOPY mst_b_6_rec,  -- B-6:�o�׎��э쐬�p�^�[��
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'mod_xxpo_data'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR xx_line_cur
    IS
      SELECT order_line_id
      FROM   xxwsh_order_lines_all
      WHERE  order_header_id = ir_masters_rec.order_header_id;
--
    -- *** ���[�J���E���R�[�h ***
    lr_xx_line_rec xx_line_cur%ROWTYPE;
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �󒍃w�b�_�A�h�I���̍쐬
    INSERT INTO xxwsh_order_headers_all
    (
           order_header_id
          ,order_type_id
          ,organization_id
          ,header_id
          ,latest_external_flag
          ,ordered_date
          ,customer_id
          ,customer_code
          ,deliver_to_id
          ,deliver_to
          ,shipping_instructions
          ,career_id
          ,freight_carrier_code
          ,shipping_method_code
          ,cust_po_number
          ,price_list_id
          ,request_no
-- 2008/12/19 D.Nihei Add Start
          ,base_request_no
-- 2008/12/19 D.Nihei Add End
          ,req_status
          ,delivery_no
          ,prev_delivery_no
          ,schedule_ship_date
          ,schedule_arrival_date
          ,mixed_no
          ,collected_pallet_qty
          ,confirm_request_class
          ,freight_charge_class
          ,shikyu_instruction_class
          ,shikyu_inst_rcv_class
          ,amount_fix_class
          ,takeback_class
          ,deliver_from_id
          ,deliver_from
          ,head_sales_branch
          ,po_no
          ,prod_class
          ,item_class
          ,no_cont_freight_class
          ,arrival_time_from
          ,arrival_time_to
          ,designated_item_id
          ,designated_item_code
          ,designated_production_date
          ,designated_branch_no
          ,slip_number
          ,sum_quantity
          ,small_quantity
          ,label_quantity
          ,loading_efficiency_weight
          ,loading_efficiency_capacity
          ,based_weight
          ,based_capacity
          ,sum_weight
          ,sum_capacity
          ,mixed_ratio
          ,pallet_sum_quantity
          ,real_pallet_quantity
          ,sum_pallet_weight
          ,order_source_ref
          ,result_freight_carrier_id
          ,result_freight_carrier_code
          ,result_shipping_method_code
          ,result_deliver_to_id
          ,result_deliver_to
          ,shipped_date
          ,arrival_date
          ,weight_capacity_class
          ,actual_confirm_class
          ,notif_status
          ,prev_notif_status
          ,notif_date
          ,new_modify_flg
          ,process_status
          ,performance_management_dept
          ,instruction_dept
          ,transfer_location_id
          ,transfer_location_code
          ,mixed_sign
          ,screen_update_date
          ,screen_update_by
          ,tightening_date
          ,vendor_id
          ,vendor_code
          ,vendor_site_id
          ,vendor_site_code
          ,registered_sequence
          ,tightening_program_id
          ,corrected_tighten_class
          ,created_by
          ,creation_date
          ,last_updated_by
          ,last_update_date
          ,last_update_login
          ,request_id
          ,program_application_id
          ,program_id
          ,program_update_date
    )
    SELECT xxwsh_order_headers_all_s1.NEXTVAL         -- order_header_id
          ,order_type_id                              -- order_type_id
          ,organization_id                            -- organization_id
--          ,header_id                                  -- header_id
          ,NULL                                       -- header_id(2008/04/16 �C��)
          ,gv_flg_on                                  -- latest_external_flag
          ,ordered_date                               -- ordered_date
          ,customer_id                                -- customer_id
          ,customer_code                              -- customer_code
          ,deliver_to_id                              -- deliver_to_id
          ,deliver_to                                 -- deliver_to
          ,shipping_instructions                      -- shipping_instructions
          ,career_id                                  -- career_id
          ,freight_carrier_code                       -- freight_carrier_code
          ,shipping_method_code                       -- shipping_method_code
          ,cust_po_number                             -- cust_po_number
          ,price_list_id                              -- price_list_id
          ,request_no                                 -- request_no
-- 2008/12/19 D.Nihei Add Start
          ,base_request_no                            -- base_request_no
-- 2008/12/19 D.Nihei Add End
          ,ir_masters_rec.req_status                  -- req_status
          ,delivery_no                                -- delivery_no
          ,prev_delivery_no                           -- prev_delivery_no
          ,schedule_ship_date                         -- schedule_ship_date
          ,schedule_arrival_date                      -- schedule_arrival_date
          ,mixed_no                                   -- mixed_no
          ,collected_pallet_qty                       -- collected_pallet_qty
          ,confirm_request_class                      -- confirm_request_class
          ,freight_charge_class                       -- freight_charge_class
          ,shikyu_instruction_class                   -- shikyu_instruction_class
          ,shikyu_inst_rcv_class                      -- shikyu_inst_rcv_class
          ,amount_fix_class                           -- amount_fix_class
          ,takeback_class                             -- takeback_class
          ,deliver_from_id                            -- deliver_from_id
          ,deliver_from                               -- deliver_from
          ,head_sales_branch                          -- head_sales_branch
          ,po_no                                      -- po_no
          ,prod_class                                 -- prod_class
          ,item_class                                 -- item_class
          ,no_cont_freight_class                      -- no_cont_freight_class
          ,arrival_time_from                          -- arrival_time_from
          ,arrival_time_to                            -- arrival_time_to
          ,designated_item_id                         -- designated_item_id
          ,designated_item_code                       -- designated_item_code
          ,designated_production_date                 -- designated_production_date
          ,designated_branch_no                       -- designated_branch_no
          ,slip_number                                -- slip_number
          ,sum_quantity                               -- sum_quantity
          ,small_quantity                             -- small_quantity
          ,label_quantity                             -- label_quantity
          ,loading_efficiency_weight                  -- loading_efficiency_weight
          ,loading_efficiency_capacity                -- loading_efficiency_capacity
          ,based_weight                               -- based_weight
          ,based_capacity                             -- based_capacity
          ,sum_weight                                 -- sum_weight
          ,sum_capacity                               -- sum_capacity
          ,mixed_ratio                                -- mixed_ratio
          ,pallet_sum_quantity                        -- pallet_sum_quantity
          ,real_pallet_quantity                       -- real_pallet_quantity
          ,sum_pallet_weight                          -- sum_pallet_weight
          ,order_source_ref                           -- order_source_ref
          ,result_freight_carrier_id                  -- result_freight_carrier_id
          ,result_freight_carrier_code                -- result_freight_carrier_code
          ,result_shipping_method_code                -- result_shipping_method_code
          ,result_deliver_to_id                       -- result_deliver_to_id
          ,result_deliver_to                          -- result_deliver_to
          ,shipped_date                               -- shipped_date
          ,arrival_date                               -- arrival_date
          ,weight_capacity_class                      -- weight_capacity_class
          ,gv_flg_off                                 -- actual_confirm_class
          ,notif_status                               -- notif_status
          ,prev_notif_status                          -- prev_notif_status
          ,notif_date                                 -- notif_date
          ,new_modify_flg                             -- new_modify_flg
          ,process_status                             -- process_status
          ,performance_management_dept                -- performance_management_dept
          ,instruction_dept                           -- instruction_dept
          ,transfer_location_id                       -- transfer_location_id
          ,transfer_location_code                     -- transfer_location_code
          ,mixed_sign                                 -- mixed_sign
          ,screen_update_date                         -- screen_update_date
          ,screen_update_by                           -- screen_update_by
          ,tightening_date                            -- tightening_date
          ,vendor_id                                  -- vendor_id
          ,vendor_code                                -- vendor_code
          ,vendor_site_id                             -- vendor_site_id
          ,vendor_site_code                           -- vendor_site_code
          ,registered_sequence                        -- registered_sequence
          ,tightening_program_id                      -- tightening_program_id
          ,corrected_tighten_class                    -- corrected_tighten_class
          ,gn_created_by                              -- created_by
          ,gd_creation_date                           -- creation_date
          ,gn_last_update_by                          -- last_updated_by
          ,gd_last_update_date                        -- last_update_date
          ,gn_last_update_login                       -- last_update_login
          ,gn_request_id                              -- request_id
          ,gn_program_application_id                  -- program_application_id
          ,gn_program_id                              -- program_id
          ,gd_program_update_date                     -- program_update_date
    FROM   xxwsh_order_headers_all
    WHERE  order_header_id      = ir_masters_rec.order_header_id
    AND    latest_external_flag = gv_flg_off;
--
    OPEN xx_line_cur;
--
    <<xx_line_loop>>
    LOOP
      FETCH xx_line_cur INTO lr_xx_line_rec;
      EXIT WHEN xx_line_cur%NOTFOUND;
--
      -- �󒍖��׃A�h�I���̍쐬
      INSERT INTO xxwsh_order_lines_all
      (
             order_line_id
            ,order_header_id
            ,order_line_number
            ,header_id
            ,line_id
            ,request_no
            ,shipping_inventory_item_id
            ,shipping_item_code
            ,quantity
            ,uom_code
            ,unit_price
            ,shipped_quantity
            ,designated_production_date
            ,based_request_quantity
            ,request_item_id
            ,request_item_code
            ,ship_to_quantity
            ,futai_code
            ,designated_date
            ,move_number
            ,po_number
            ,cust_po_number
            ,pallet_quantity
            ,layer_quantity
            ,case_quantity
            ,weight
            ,capacity
            ,pallet_qty
            ,pallet_weight
            ,reserved_quantity
            ,automanual_reserve_class
            ,delete_flag
            ,warning_class
            ,warning_date
            ,line_description
            ,rm_if_flg
            ,shipping_request_if_flg
            ,shipping_result_if_flg
            ,created_by
            ,creation_date
            ,last_updated_by
            ,last_update_date
            ,last_update_login
            ,request_id
            ,program_application_id
            ,program_id
            ,program_update_date
      )
      SELECT xxwsh_order_lines_all_s1.NEXTVAL           -- order_line_id
            ,xxwsh_order_headers_all_s1.CURRVAL         -- order_header_id
            ,order_line_number                          -- order_line_number
  --          ,header_id                                  -- header_id
  --          ,line_id                                    -- line_id
            ,NULL                                       -- header_id(2008/04/16 �C��)
            ,NULL                                       -- line_id(2008/04/16 �C��)
            ,request_no                                 -- request_no
            ,shipping_inventory_item_id                 -- shipping_inventory_item_id
            ,shipping_item_code                         -- shipping_item_code
            ,quantity                                   -- quantity
            ,uom_code                                   -- uom_code
            ,unit_price                                 -- unit_price
            ,shipped_quantity                           -- shipped_quantity
            ,designated_production_date                 -- designated_production_date
            ,based_request_quantity                     -- based_request_quantity
            ,request_item_id                            -- request_item_id
            ,request_item_code                          -- request_item_code
            ,ship_to_quantity                           -- ship_to_quantity
            ,futai_code                                 -- futai_code
            ,designated_date                            -- designated_date
            ,move_number                                -- move_number
            ,po_number                                  -- po_number
            ,cust_po_number                             -- cust_po_number
            ,pallet_quantity                            -- pallet_quantity
            ,layer_quantity                             -- layer_quantity
            ,case_quantity                              -- case_quantity
            ,weight                                     -- weight
            ,capacity                                   -- capacity
            ,pallet_qty                                 -- pallet_qty
            ,pallet_weight                              -- pallet_weight
            ,reserved_quantity                          -- reserved_quantity
            ,automanual_reserve_class                   -- automanual_reserve_class
            ,delete_flag                                -- delete_flag
            ,warning_class                              -- warning_class
            ,warning_date                               -- warning_date
            ,line_description                           -- line_description
            ,rm_if_flg                                  -- rm_if_flg
            ,shipping_request_if_flg                    -- shipping_request_if_flg
            ,shipping_result_if_flg                     -- shipping_result_if_flg
            ,gn_created_by                              -- created_by
            ,gd_creation_date                           -- creation_date
            ,gn_last_update_by                          -- last_updated_by
            ,gd_last_update_date                        -- last_update_date
            ,gn_last_update_login                       -- last_update_login
            ,gn_request_id                              -- request_id
            ,gn_program_application_id                  -- program_application_id
            ,gn_program_id                              -- program_id
            ,gd_program_update_date                     -- program_update_date
      FROM   xxwsh_order_lines_all
      WHERE  order_line_id   = lr_xx_line_rec.order_line_id;
--
      -- �ړ����b�g�ڍ�(�A�h�I��)�̍쐬
      INSERT INTO xxinv_mov_lot_details
      (
         mov_lot_dtl_id                                  -- ���b�g�ڍ�ID
        ,mov_line_id                                     -- ����ID
        ,document_type_code                              -- �����^�C�v
        ,record_type_code                                -- ���R�[�h�^�C�v
        ,item_id                                         -- OPM�i��ID
        ,item_code                                       -- �i��
        ,lot_id                                          -- ���b�gID
        ,lot_no                                          -- ���b�gNo
        ,actual_date                                     -- ���ѓ�
        ,actual_quantity                                 -- ���ѐ���
-- 2008/12/19 D.Nihei Add Start
        ,before_actual_quantity                          -- �����O����
-- 2008/12/19 D.Nihei Add End
        ,automanual_reserve_class                        -- �����蓮�����敪
        ,created_by
        ,creation_date
        ,last_updated_by
        ,last_update_date
        ,last_update_login
        ,request_id
        ,program_application_id
        ,program_id
        ,program_update_date
      )
      SELECT xxinv_mov_lot_s1.NEXTVAL                        -- mov_lot_dtl_id
            ,xxwsh_order_lines_all_s1.CURRVAL                -- mov_line_id
            ,xmld.document_type_code                         -- document_type_code
            ,xmld.record_type_code                           -- record_type_code
            ,xmld.item_id                                    -- item_id
            ,xmld.item_code                                  -- item_code
            ,xmld.lot_id                                     -- lot_id
            ,xmld.lot_no                                     -- lot_no
            ,xmld.actual_date                                -- actual_date
            ,xmld.actual_quantity                            -- actual_quantity
-- 2008/12/19 D.Nihei Add Start
            ,xmld.actual_quantity                            -- actual_quantity
-- 2008/12/19 D.Nihei Add End
            ,xmld.automanual_reserve_class                   -- automanual_reserve_class
            ,gn_created_by                                   -- created_by
            ,gd_creation_date                                -- creation_date
            ,gn_last_update_by                               -- last_updated_by
            ,gd_last_update_date                             -- last_update_date
            ,gn_last_update_login                            -- last_update_login
            ,gn_request_id                                   -- request_id
            ,gn_program_application_id                       -- program_application_id
            ,gn_program_id                                   -- program_id
            ,gd_program_update_date                          -- program_update_date
      FROM  xxinv_mov_lot_details xmld
      WHERE xmld.mov_line_id = lr_xx_line_rec.order_line_id
      AND   xmld.document_type_code = gv_document_type;             -- �x���w��
--
    END LOOP xx_line_loop;
--
    CLOSE xx_line_cur;
--
    gn_b_9_cnt := gn_b_9_cnt + 1;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\�����J���Ă����
      IF (xx_line_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE xx_line_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\�����J���Ă����
      IF (xx_line_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE xx_line_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\�����J���Ă����
      IF (xx_line_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE xx_line_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END mod_xxpo_data;
--
  /***********************************************************************************
   * Procedure Name   : upd_quantity_data
   * Description      : �o�׎��ѐ��� �X�V(�����p)(B-14)
   ***********************************************************************************/
  PROCEDURE upd_quantity_data(
    ir_masters_rec  IN OUT NOCOPY mst_b_12_rec, -- B-12:�o�׎��ѐ��ʍX�V�p
    ir_mst_b_6_rec  IN OUT NOCOPY mst_b_6_rec,  -- B-6:�o�׎��э쐬�p�^�[��
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_quantity_data'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �󒍖��׃A�h�I���̍X�V
    BEGIN
      UPDATE xxwsh_order_lines_all
      SET    shipped_quantity       = ir_masters_rec.def_qty6        -- �o�׎��ѐ���
            ,last_update_date       = gd_last_update_date
            ,last_updated_by        = gn_last_update_by
            ,last_update_login      = gn_last_update_login
            ,request_id             = gn_request_id
            ,program_application_id = gn_program_application_id
            ,program_id             = gn_program_id
            ,program_update_date    = gd_program_update_date
      WHERE  order_line_id = ir_masters_rec.order_line_id;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- �ړ����b�g�ڍ�(�A�h�I��)�̍X�V
    BEGIN
      UPDATE xxinv_mov_lot_details
      SET    actual_quantity        = ir_masters_rec.def_qty6        -- ���ѐ���
            ,last_update_date       = gd_last_update_date
            ,last_updated_by        = gn_last_update_by
            ,last_update_login      = gn_last_update_login
            ,request_id             = gn_request_id
            ,program_application_id = gn_program_application_id
            ,program_id             = gn_program_id
            ,program_update_date    = gd_program_update_date
      WHERE  mov_line_id        = ir_masters_rec.order_line_id
      AND    document_type_code = gv_document_type            -- �x���w��
      AND    record_type_code   = gv_record_type;             -- �o�Ɏ���
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END upd_quantity_data;
--
  /***********************************************************************************
   * Procedure Name   : keep_mod_data
   * Description      : �o�׎��я��ێ�(�����p)(�����p)(B-13)
   ***********************************************************************************/
  PROCEDURE keep_mod_data(
    ir_masters_rec  IN OUT NOCOPY mst_b_12_rec, -- B-12:�o�׎��ѐ��ʍX�V�p
    ir_mst_b_6_rec  IN OUT NOCOPY mst_b_6_rec,  -- B-6:�o�׎��э쐬�p�^�[��
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'keep_mod_data'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �󒍖��׃A�h�I���f�[�^�Ȃ�
    IF (ir_masters_rec.order_line_id IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            'APP-XXPO-10050',
                                            gv_tkn_request_num,
                                            gv_request_no,
                                            gv_tkn_item_cd,
                                            NVL(ir_masters_rec.item_no,ir_masters_rec.item_id));
      RAISE keep_mod_data_expt;
    END IF;
--
    -- ================================
    -- B-14.�o�׎��ѐ��� �X�V(�����p)
    -- ================================
    upd_quantity_data(
      ir_masters_rec,
      ir_mst_b_6_rec,
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN keep_mod_data_expt THEN
      ov_retcode := gv_status_warn;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END keep_mod_data;
--
  /***********************************************************************************
   * Procedure Name   : get_mod_data
   * Description      : �o�׎��ѐ��ʍX�V�p�f�[�^�擾(�����p)(B-12)
   ***********************************************************************************/
  PROCEDURE get_mod_data(
    ir_masters_rec  IN OUT NOCOPY mst_b_6_rec,  -- B-6:�o�׎��э쐬�p�^�[��
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_mod_data'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lr_mst_rec           mst_b_12_rec;
    ln_order_line_id     xxwsh_order_lines_all.order_line_id%TYPE;
    ln_mov_lot_dtl_id    xxinv_mov_lot_details.mov_lot_dtl_id%TYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR xpo_line_cur
    IS
      SELECT  paa.attribute6                   -- �d����o�א���
             ,xoa.shipped_quantity             -- �o�׎��ѐ���
             ,xoa.order_line_id                -- �󒍖��׃A�h�I��ID
             ,xoa.request_no                   -- �˗�NO
             ,xiv.item_no                      -- �i�ڃR�[�h
             ,paa.item_id                      -- �i��ID
      FROM   xxcmn_item_mst_v xiv              -- OPM�i�ڏ��VIEW
             ,(SELECT  xha.po_no                        -- ����NO
                      ,xla.request_no                   -- �˗�NO
                      ,xla.shipping_inventory_item_id   -- �o�וi��ID
                      ,xla.shipped_quantity             -- �o�׎��ѐ���
                      ,xla.order_line_id                -- �󒍖��׃A�h�I��ID
               FROM    xxwsh_order_headers_all xha      -- �󒍃w�b�_�A�h�I��
                      ,xxwsh_order_lines_all xla        -- �󒍖��׃A�h�I��
               WHERE  xha.order_header_id = xla.order_header_id
               AND    NVL(xha.latest_external_flag,gv_flg_off) = gv_flg_on   -- �ŐV�t���O(ON)
               AND    NVL(xha.actual_confirm_class,gv_flg_off) = gv_flg_off  -- ���ьv��ϋ敪(OFF)
               AND    NVL(xla.delete_flag,gv_flg_off) = gv_flg_off) xoa      -- ����t���O(OFF)
             ,(SELECT  pha.po_header_id
                      ,pla.attribute6
                      ,pha.segment1
                      ,pla.item_id
                      ,pha.attribute9
               FROM    po_headers_all pha               -- �����w�b�_
                      ,po_lines_all pla                 -- ��������
               WHERE  pha.po_header_id = pla.po_header_id
               AND    pha.po_header_id = ir_masters_rec.po_header_id) paa
      WHERE  paa.segment1   = xoa.po_no(+)
      AND    paa.attribute9 = xoa.request_no(+)
      AND    paa.item_id    = xoa.shipping_inventory_item_id(+)
      AND    paa.item_id    = xiv.inventory_item_id;
--
    -- *** ���[�J���E���R�[�h ***
    lr_xpo_line_rec xpo_line_cur%ROWTYPE;
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    OPEN xpo_line_cur;
--
    <<xpo_line_loop>>
    LOOP
      FETCH xpo_line_cur INTO lr_xpo_line_rec;
      EXIT WHEN xpo_line_cur%NOTFOUND;
--
      lr_mst_rec.attribute6       := lr_xpo_line_rec.attribute6;
      lr_mst_rec.shipped_quantity := lr_xpo_line_rec.shipped_quantity;
      lr_mst_rec.order_line_id    := lr_xpo_line_rec.order_line_id;
      lr_mst_rec.request_no       := lr_xpo_line_rec.request_no;
      lr_mst_rec.item_no          := lr_xpo_line_rec.item_no;
      lr_mst_rec.item_id          := lr_xpo_line_rec.item_id;
--
      lr_mst_rec.def_qty6         := TO_NUMBER(lr_xpo_line_rec.attribute6);
--
        -- �󒍖��׃A�h�I���̃��b�N
      BEGIN
        SELECT xla.order_line_id
        INTO   ln_order_line_id
        FROM   xxwsh_order_lines_all xla
        WHERE  xla.order_line_id = lr_xpo_line_rec.order_line_id
        FOR UPDATE OF xla.order_line_id NOWAIT;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
--
        WHEN lock_expt THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                                'APP-XXPO-10138');
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
--
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
--
      -- �ړ����b�g�ڍ�(�A�h�I��)�̃��b�N
      BEGIN
        SELECT xmld.mov_lot_dtl_id
        INTO   ln_mov_lot_dtl_id
        FROM   xxinv_mov_lot_details xmld
        WHERE  xmld.mov_line_id        = lr_xpo_line_rec.order_line_id
        AND    xmld.document_type_code = gv_document_type        -- �x���w��
        AND    xmld.record_type_code   = gv_record_type          -- �o�׎���
        FOR UPDATE OF xmld.mov_lot_dtl_id NOWAIT;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
--
        WHEN lock_expt THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                                'APP-XXPO-10138');
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
--
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
--
      -- ================================
      -- B-13.�o�׎��я��ێ�(�����p)
      -- ================================
      keep_mod_data(
        lr_mst_rec,
        ir_masters_rec,
        lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
--
      ELSIF (lv_retcode = gv_status_warn) THEN
        ov_retcode := lv_retcode;
      END IF;
--
    END LOOP xpo_line_loop;
--
    CLOSE xpo_line_cur;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (xpo_line_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE xpo_line_cur;
      END IF;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (xpo_line_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE xpo_line_cur;
      END IF;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (xpo_line_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE xpo_line_cur;
      END IF;
--
--#####################################  �Œ蕔 END   #############################################
--
  END get_mod_data;
--
  /***********************************************************************************
   * Procedure Name   : ins_xxpo_data
   * Description      : �󒍃A�h�I����� �X�V(�V�K�o�^�p)(B-9)
   ***********************************************************************************/
  PROCEDURE ins_xxpo_data(
    ir_mst_b_7_rec  IN OUT NOCOPY mst_b_7_rec,  -- B-7:�o�׎��э쐬�Ώۃf�[�^�擾
    ir_mst_b_6_rec  IN OUT NOCOPY mst_b_6_rec,  -- B-6:�o�׎��э쐬�p�^�[��
    lv_status       IN            VARCHAR2,
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_xxpo_data'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_req_status      xxwsh_order_headers_all.req_status%TYPE;
    ln_carrier_id      xxwsh_order_headers_all.result_freight_carrier_id%TYPE;
    lv_carrier_code    xxwsh_order_headers_all.result_freight_carrier_code%TYPE;
    lv_method_code     xxwsh_order_headers_all.result_shipping_method_code%TYPE;
    ld_shipped_date    xxwsh_order_headers_all.shipped_date%TYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �d����o�א���<>�o�׎��ѐ���
    IF ((ir_mst_b_7_rec.def_qty6 <> ir_mst_b_7_rec.shipped_quantity)
     OR ((ir_mst_b_7_rec.def_qty6 IS NULL) AND (ir_mst_b_7_rec.shipped_quantity IS NOT NULL))
     OR ((ir_mst_b_7_rec.def_qty6 IS NOT NULL) AND (ir_mst_b_7_rec.shipped_quantity IS NULL))) THEN
--
      -- �o�׈˗�/�x���˗��X�e�[�^�X
     lv_req_status := lv_status;
--
      -- �^���Ǝ�_����ID
      IF (ir_mst_b_7_rec.result_freight_carrier_id IS NULL) THEN
        ln_carrier_id := ir_mst_b_7_rec.career_id;
      ELSE
        ln_carrier_id := ir_mst_b_7_rec.result_freight_carrier_id;
      END IF;
--
      -- �^���Ǝ�_����
      IF (ir_mst_b_7_rec.result_freight_carrier_code IS NULL) THEN
        lv_carrier_code := ir_mst_b_7_rec.freight_carrier_code;
      ELSE
        lv_carrier_code := ir_mst_b_7_rec.result_freight_carrier_code;
      END IF;
--
      -- �z���敪_����
      IF (ir_mst_b_7_rec.result_shipping_method_code IS NULL) THEN
        lv_method_code := ir_mst_b_7_rec.shipping_method_code;
      ELSE
        lv_method_code := ir_mst_b_7_rec.result_shipping_method_code;
      END IF;
--
      ld_shipped_date := ir_mst_b_7_rec.def_date4;
--
      -- �󒍃w�b�_�A�h�I���̍X�V
      BEGIN
        UPDATE xxwsh_order_headers_all
        SET    req_status                  = lv_req_status         -- �o�׈˗�/�x���˗��X�e�[�^�X
              ,actual_confirm_class        = gv_flg_off            -- ���ьv��ϋ敪
              ,shipped_date                = ld_shipped_date       -- �o�ד�
              ,result_freight_carrier_id   = ln_carrier_id         -- �^���Ǝ�_����ID
              ,result_freight_carrier_code = lv_carrier_code       -- �^���Ǝ�_����
              ,result_shipping_method_code = lv_method_code        -- �z���敪_����
              ,last_updated_by             = gn_last_update_by
              ,last_update_date            = gd_last_update_date
              ,last_update_login           = gn_last_update_login
              ,request_id                  = gn_request_id
              ,program_application_id      = gn_program_application_id
              ,program_id                  = gn_program_id
              ,program_update_date         = gd_program_update_date
        WHERE  order_header_id = ir_mst_b_6_rec.order_header_id;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
--
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
--
      -- �󒍖��׃A�h�I���̍X�V
      BEGIN
        UPDATE xxwsh_order_lines_all
        SET    shipped_quantity            = ir_mst_b_7_rec.def_qty6   -- �o�׎��ѐ���
              ,last_updated_by             = gn_last_update_by
              ,last_update_date            = gd_last_update_date
              ,last_update_login           = gn_last_update_login
              ,request_id                  = gn_request_id
              ,program_application_id      = gn_program_application_id
              ,program_id                  = gn_program_id
              ,program_update_date         = gd_program_update_date
        WHERE  order_line_id = ir_mst_b_7_rec.order_line_id;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
--
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
--
      -- �ړ����b�g�ڍ�(�A�h�I��)�̍X�V
      BEGIN
        UPDATE xxinv_mov_lot_details
        SET    actual_quantity             = ir_mst_b_7_rec.def_qty6   -- ���ѐ���
              ,last_updated_by             = gn_last_update_by
              ,last_update_date            = gd_last_update_date
              ,last_update_login           = gn_last_update_login
              ,request_id                  = gn_request_id
              ,program_application_id      = gn_program_application_id
              ,program_id                  = gn_program_id
              ,program_update_date         = gd_program_update_date
        WHERE  mov_line_id        = ir_mst_b_7_rec.order_line_id
        AND    document_type_code = gv_document_type           -- �x���w��
        AND    record_type_code   = gv_record_type;            -- �o�Ɏ���
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
--
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
--
      gn_b_9_cnt := gn_b_9_cnt + 1;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END ins_xxpo_data;
--
  /***********************************************************************************
   * Procedure Name   : keep_new_data
   * Description      : �o�׎��я��ێ�(�V�K�o�^�p)(B-8)
   ***********************************************************************************/
  PROCEDURE keep_new_data(
    ir_masters_rec  IN OUT NOCOPY mst_b_7_rec,  -- B-7:�o�׎��э쐬�Ώۃf�[�^�擾
    ir_mst_b_6_rec  IN OUT NOCOPY mst_b_6_rec,  -- B-6:�o�׎��э쐬�p�^�[��
    iv_status       IN            VARCHAR2,
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'keep_new_data'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �󒍖��׃A�h�I���f�[�^�Ȃ�
    IF (ir_masters_rec.order_line_id IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            'APP-XXPO-10050',
                                            gv_tkn_request_num,
                                            gv_request_no,
                                            gv_tkn_item_cd,
                                            ir_masters_rec.item_no);
      RAISE keep_new_data_expt;
    END IF;
--
    -- ================================
    -- B-9.�󒍃A�h�I����� �X�V(�V�K�o�^�p)
    -- ================================
    ins_xxpo_data(
      ir_masters_rec,
      ir_mst_b_6_rec,
      iv_status,
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ================================
    -- B-18.�ړ����b�g�ڍ׍쐬(�V�K�o�^�p)
    -- ================================
    create_mov_lot(
      ir_masters_rec,
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN keep_new_data_expt THEN
      ov_retcode := gv_status_warn;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END keep_new_data;
--
  /***********************************************************************************
   * Procedure Name   : get_new_data
   * Description      : �o�׎��э쐬�Ώۃf�[�^�擾(�V�K�o�^�p)(B-7)
   ***********************************************************************************/
  PROCEDURE get_new_data(
    ir_masters_rec  IN OUT NOCOPY mst_b_6_rec,  -- B-6:�o�׎��э쐬�p�^�[��
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_new_data'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_cnt              NUMBER;
    lr_mst_rec          mst_b_7_rec;
    ln_order_header_id  xxwsh_order_headers_all.order_header_id%TYPE;
    ln_order_line_id    xxwsh_order_lines_all.order_line_id%TYPE;
    ln_wk_header_id     xxwsh_order_headers_all.order_header_id%TYPE;
    ln_wk_line_id       xxwsh_order_lines_all.order_line_id%TYPE;
    lv_status           xxwsh_order_headers_all.req_status%TYPE;
    ln_mov_lot_dtl_id   xxinv_mov_lot_details.mov_lot_dtl_id%TYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR po_line_cur
    IS
      SELECT  paa.attribute6                   -- �d����o�א���
             ,paa.attribute4                   -- �[����
             ,xoa.req_status                   -- �o�׈˗�/�x���w���X�e�[�^�X
             ,xoa.actual_confirm_class         -- ���ьv��ϋ敪
             ,xoa.career_id                    -- �^���Ǝ�ID
             ,xoa.freight_carrier_code         -- �^���Ǝ�
             ,xoa.result_freight_carrier_id    -- �^���Ǝ�_����ID
             ,xoa.result_freight_carrier_code  -- �^���Ǝ�_����
             ,xoa.shipping_method_code         -- �z���敪
             ,xoa.result_shipping_method_code  -- �z���敪_����
             ,xoa.shipped_quantity             -- �o�׎��ѐ���
             ,xoa.order_line_id                -- �󒍖��׃A�h�I��ID
             ,xoa.request_no                   -- �˗�NO
             ,xiv.item_no                      -- �i�ڃR�[�h
      FROM    xxcmn_item_mst_v xiv             -- OPM�i�ڏ��VIEW
             ,(SELECT  pla.attribute6
                      ,pha.attribute4
                      ,pha.po_header_id
                      ,pha.segment1
                      ,pha.attribute9
                      ,pla.item_id
               FROM    po_headers_all pha               -- �����w�b�_
                      ,po_lines_all pla                 -- ��������
               WHERE   pha.po_header_id = pla.po_header_id
               AND     pha.po_header_id = ir_masters_rec.po_header_id) paa
             ,(SELECT  xha.po_no                        -- ����NO
                      ,xha.req_status                   -- �o�׈˗�/�x���w���X�e�[�^�X
                      ,xha.actual_confirm_class         -- ���ьv��ϋ敪
                      ,xha.career_id                    -- �^���Ǝ�ID
                      ,xha.freight_carrier_code         -- �^���Ǝ�
                      ,xha.result_freight_carrier_id    -- �^���Ǝ�_����ID
                      ,xha.result_freight_carrier_code  -- �^���Ǝ�_����
                      ,xha.shipping_method_code         -- �z���敪
                      ,xha.result_shipping_method_code  -- �z���敪_����
                      ,xla.shipped_quantity             -- �o�׎��ѐ���
                      ,xla.order_line_id                -- �󒍖��׃A�h�I��ID
                      ,xla.request_no                   -- �˗�NO
                      ,xla.shipping_inventory_item_id   -- �o�וi��ID
               FROM    xxwsh_order_headers_all xha      -- �󒍃w�b�_�A�h�I��
                      ,xxwsh_order_lines_all xla        -- �󒍖��׃A�h�I��
               WHERE  xha.order_header_id = xla.order_header_id
               AND    xha.order_header_id = ir_masters_rec.order_header_id
               AND    NVL(xla.delete_flag,gv_flg_off) = gv_flg_off) xoa
      WHERE  paa.segment1   = xoa.po_no(+)
      AND    paa.attribute9 = xoa.request_no(+)
      AND    paa.item_id    = xoa.shipping_inventory_item_id(+)
      AND    paa.item_id    = xiv.inventory_item_id;
--
    -- *** ���[�J���E���R�[�h ***
    lr_po_line_rec po_line_cur%ROWTYPE;
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �o�׈˗�/�x���˗��X�e�[�^�X�ݒ�
    set_req_status(
      ir_masters_rec,
      lv_status,
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    OPEN po_line_cur;
--
    <<po_line_loop>>
    LOOP
      FETCH po_line_cur INTO lr_po_line_rec;
      EXIT WHEN po_line_cur%NOTFOUND;
--
      lr_mst_rec.attribute6                  := lr_po_line_rec.attribute6;
      lr_mst_rec.attribute4                  := lr_po_line_rec.attribute4;
      lr_mst_rec.req_status                  := lr_po_line_rec.req_status;
      lr_mst_rec.actual_confirm_class        := lr_po_line_rec.actual_confirm_class;
      lr_mst_rec.career_id                   := lr_po_line_rec.career_id;
      lr_mst_rec.freight_carrier_code        := lr_po_line_rec.freight_carrier_code;
      lr_mst_rec.result_freight_carrier_id   := lr_po_line_rec.result_freight_carrier_id;
      lr_mst_rec.result_freight_carrier_code := lr_po_line_rec.result_freight_carrier_code;
      lr_mst_rec.shipping_method_code        := lr_po_line_rec.shipping_method_code;
      lr_mst_rec.result_shipping_method_code := lr_po_line_rec.result_shipping_method_code;
      lr_mst_rec.shipped_quantity            := lr_po_line_rec.shipped_quantity;
      lr_mst_rec.order_line_id               := lr_po_line_rec.order_line_id;
      lr_mst_rec.request_no                  := lr_po_line_rec.request_no;
      lr_mst_rec.item_no                     := lr_po_line_rec.item_no;
--
      lr_mst_rec.def_qty6  := TO_NUMBER(lr_po_line_rec.attribute6);
      lr_mst_rec.def_date4 := FND_DATE.STRING_TO_DATE(lr_po_line_rec.attribute4,'YYYY/MM/DD');
--
      ln_order_header_id := ir_masters_rec.order_header_id;
      ln_order_line_id   := lr_mst_rec.order_line_id;
--
      IF (ln_order_header_id IS NOT NULL) THEN
        -- �󒍃w�b�_�A�h�I���̃��b�N
        BEGIN
          SELECT xha.order_header_id
          INTO   ln_wk_header_id
          FROM   xxwsh_order_headers_all xha
          WHERE  xha.order_header_id = ln_order_header_id
          FOR UPDATE OF xha.order_header_id NOWAIT;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
--
          WHEN lock_expt THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                                  'APP-XXPO-10138');
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
--
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
      END IF;
--
      IF ((ln_order_header_id IS NOT NULL) AND (ln_order_line_id IS NOT NULL)) THEN
        -- �󒍖��׃A�h�I���̃��b�N
        BEGIN
          SELECT xla.order_line_id
          INTO   ln_wk_line_id
          FROM   xxwsh_order_lines_all xla
          WHERE  xla.order_header_id = ln_order_header_id
          AND    xla.order_line_id   = ln_order_line_id
          FOR UPDATE OF xla.order_line_id NOWAIT;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
--
          WHEN lock_expt THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                                  'APP-XXPO-10138');
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
--
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
      END IF;
--
      IF (ln_order_line_id IS NOT NULL) THEN
        -- �ړ����b�g�ڍ�(�A�h�I��)�̃��b�N
        BEGIN
          SELECT xmld.mov_lot_dtl_id
          INTO   ln_mov_lot_dtl_id
          FROM   xxinv_mov_lot_details xmld
          WHERE  xmld.mov_line_id        = ln_order_line_id
          AND    xmld.document_type_code = gv_document_type      -- �x���w��
          AND    xmld.record_type_code   = gv_record_type        -- �o�Ɏ���
          FOR UPDATE OF xmld.mov_lot_dtl_id NOWAIT;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
--
          WHEN lock_expt THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                                  'APP-XXPO-10138');
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
--
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
      END IF;
--
      -- ================================
      -- B-8.�o�׎��я��ێ�(�V�K�o�^�p)
      -- ================================
      keep_new_data(
        lr_mst_rec,
        ir_masters_rec,
        lv_status,
        lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
--
      ELSIF (lv_retcode = gv_status_warn) THEN
        ov_retcode := lv_retcode;
      END IF;
--
      gn_b_7_cnt := gn_b_7_cnt + 1;
--
    END LOOP po_line_loop;
--
    CLOSE po_line_cur;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (po_line_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE po_line_cur;
      END IF;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (po_line_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE po_line_cur;
      END IF;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (po_line_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE po_line_cur;
      END IF;
--
--#####################################  �Œ蕔 END   #############################################
--
  END get_new_data;
--
  /***********************************************************************************
   * Procedure Name   : check_deli_pat
   * Description      : �o�׎��э쐬�p�^�[������(B-6)
   ***********************************************************************************/
  PROCEDURE check_deli_pat(
    ov_errbuf     OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_deli_pat'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_cnt            NUMBER;
    lr_mst_rec        mst_b_6_rec;
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR po_head_cur
    IS
     SELECT pha.po_header_id                          -- �����w�b�_ID
           ,xha.order_header_id                       -- �󒍃w�b�_�A�h�I��ID
           ,xha.req_status                            -- �o�׈˗��^�x���w���X�e�[�^�X
           ,xha.actual_confirm_class                  -- ���ьv��ϋ敪
     FROM   po_headers_all pha                        -- �����w�b�_
           ,(SELECT xoh.po_no
                   ,xoh.request_no
                   ,xoh.order_header_id
                   ,xoh.req_status
                   ,xoh.actual_confirm_class
             FROM   xxwsh_order_headers_all xoh       -- �󒍃w�b�_�A�h�I��
             WHERE  xoh.latest_external_flag = gv_flg_on       -- ON
             AND   (xoh.req_status = gv_req_status_rect        -- ��̍�
             OR     xoh.req_status = gv_req_status_appr)) xha  -- �o�׎��ьv���
     WHERE  pha.segment1   = xha.po_no(+)
     AND    pha.attribute9 = xha.request_no(+)
     AND    pha.segment1   = gv_header_number;
--
    -- *** ���[�J���E���R�[�h ***
    lr_po_head_rec po_head_cur%ROWTYPE;
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    ln_cnt := 0;
--
    OPEN po_head_cur;
--
    <<po_head_loop>>
    LOOP
      FETCH po_head_cur INTO lr_po_head_rec;
      EXIT WHEN po_head_cur%NOTFOUND;
--
      lr_mst_rec.po_header_id         := lr_po_head_rec.po_header_id;
      lr_mst_rec.order_header_id      := lr_po_head_rec.order_header_id;
      lr_mst_rec.req_status           := lr_po_head_rec.req_status;
      lr_mst_rec.actual_confirm_class := lr_po_head_rec.actual_confirm_class;
--
      -- ��̍�
      IF (lr_mst_rec.req_status = gv_req_status_rect) THEN
--
        -- ================================
        -- B-7.�o�׎��э쐬�Ώۃf�[�^�擾(�V�K�o�^�p)
        -- ================================
        get_new_data(
          lr_mst_rec,
          lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
--
        ELSIF (lv_retcode = gv_status_warn) THEN
          ov_retcode := lv_retcode;
        END IF;
--
-- 2008/10/24 v1.18 T.Yoshimoto Mod Start
      -- �o�׎��ьv���
      --ELSIF (lr_mst_rec.req_status = gv_req_status_appr) THEN
--
      -- �o�׎��ьv��ς݊��A���ьv��ϋ敪��'Y'�̏ꍇ
      ELSIF ( (lr_mst_rec.req_status = gv_req_status_appr)
        AND (lr_mst_rec.actual_confirm_class = gv_flg_on) ) THEN
-- 2008/10/24 v1.18 T.Yoshimoto Mod End
--
        -- ================================
        -- B-10.�󒍃w�b�_�A�h�I����� �X�V
        -- ================================
        upd_xxpo_data(
          lr_mst_rec,
          lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        -- ================================
        -- B-11.�󒍃A�h�I����� �X�V(�����f�[�^�o�^�p)
        -- ================================
        mod_xxpo_data(
          lr_mst_rec,
          lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        -- ================================
        -- B-12.�o�׎��ѐ��ʍX�V�p�f�[�^�擾(�����p)
        -- ================================
        get_mod_data(
          lr_mst_rec,
          lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
--
        ELSIF (lv_retcode = gv_status_warn) THEN
          ov_retcode := lv_retcode;
        END IF;
--
-- 2008/10/24 v1.18 T.Yoshimoto Add Start
      -- �o�׎��ьv��ς݊��A���ьv��ϋ敪��'Y'�ȊO�̏ꍇ
      ELSIF ( (lr_mst_rec.req_status = gv_req_status_appr)
        AND (lr_mst_rec.actual_confirm_class <> gv_flg_on) ) THEN
--
        -- ================================
        -- B-7.�o�׎��э쐬�Ώۃf�[�^�擾(�V�K�o�^�p)
        -- ================================
        get_new_data(
          lr_mst_rec,
          lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
--
        ELSIF (lv_retcode = gv_status_warn) THEN
          ov_retcode := lv_retcode;
        END IF;
-- 2008/10/24 v1.18 T.Yoshimoto Add Start
--
      -- ���̑�
      ELSE
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              'APP-XXPO-10066',
                                              gv_tkn_table_num,
                                              '�����w�b�_�A�h�I��',
                                              gv_tkn_po_num,
                                              gv_header_number);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      ln_cnt := ln_cnt + 1;
--
    END LOOP po_head_loop;
--
    CLOSE po_head_cur;
--
    IF (ln_cnt = 0) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            'APP-XXPO-10066',
                                            gv_tkn_table_num,
                                            '�����w�b�_',
                                            gv_tkn_po_num,
                                            gv_header_number);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (po_head_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE po_head_cur;
      END IF;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (po_head_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE po_head_cur;
      END IF;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (po_head_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE po_head_cur;
      END IF;
--
--#####################################  �Œ蕔 END   #############################################
--
  END check_deli_pat;
--
  /***********************************************************************************
   * Procedure Name   : disp_report
   * Description      : �������ʃ��|�[�g�o��(B-17)
   ***********************************************************************************/
  PROCEDURE disp_report(
    ov_errbuf           OUT NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'disp_report';           -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_dspbuf               VARCHAR2(5000);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_sep_msg);
--
    -- ������э쐬�Ώی����o�̓��b�Z�[�W
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          'APP-XXPO-30025',
                                          gv_tkn_target_count_1,
                                          gn_b_3_cnt,
                                          gv_tkn_target_count_2,
                                          gn_b_7_cnt);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_errmsg);
--
    -- �����������b�Z�[�W
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          'APP-XXPO-30028',
                                          gv_tkn_count_1,
                                          gn_b_5_cnt,
                                          gv_tkn_count_2,
                                          gn_b_9_cnt);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_errmsg);
--
    -- �������ʃ��|�[�g�̏o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_dspbuf);
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END disp_report;
--
  /***********************************************************************************
   * Procedure Name   : set_rcv_data
   * Description      : ������я��o�^(B-5)
   ***********************************************************************************/
  PROCEDURE set_rcv_data(
    ov_errbuf     OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_rcv_data'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lr_mst_rec       masters_rec;
    ln_flg           NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    ln_flg := 0;
--
    <<set_data_loop>>
    FOR i IN 0..gn_b_3_cnt-1 LOOP
      lr_mst_rec := gt_b_03_mast(i);
--
      -- �ΏۊO�ȊO
      IF (lr_mst_rec.exec_flg <> gn_mode_oth) THEN
--
        -- �o�^
        IF (lr_mst_rec.exec_flg = gn_mode_ins) THEN
          lr_mst_rec.trans_type := gv_trans_type_receive;
--
        -- �X�V
        ELSIF (lr_mst_rec.exec_flg = gn_mode_upd) THEN
          IF (lr_mst_rec.attribute1 IS NULL) THEN
            lr_mst_rec.trans_type := gv_trans_type_receive;
          ELSE
            lr_mst_rec.trans_type := gv_trans_type_correct;
          END IF;
        END IF;
--
        IF (ln_flg = 0) THEN
--
          -- ���ڎ��
          IF (lr_mst_rec.trans_type = gv_trans_type_receive) THEN
--
            SELECT rcv_interface_groups_s.NEXTVAL
            INTO   gn_group_id
            FROM   DUAL;
--
          -- ����
          ELSIF (lr_mst_rec.trans_type = gv_trans_type_correct) THEN
--
              SELECT rcv_interface_groups_s.NEXTVAL
              INTO   gn_group_id2
              FROM   DUAL;
--
              SELECT rcv_interface_groups_s.NEXTVAL
              INTO   gn_group_id
              FROM   DUAL;
          END IF;
          ln_flg := 1;
        END IF;
--
        -- �V�K�o�^
        IF (lr_mst_rec.exec_flg = gn_mode_ins) THEN
          -- ����ԕi����(�A�h�I��)�̎��ID
          SELECT xxpo_rcv_and_rtn_txns_s1.NEXTVAL
          INTO   gn_txns_id
          FROM   DUAL;
        END IF;
--
        -- �d����o�א���
-- 2008/12/30 v1.13 T.Yoshimoto Mod Start
        --IF (lr_mst_rec.def_qty6 > 0) THEN
        -- ������d����o�׎��т�0���傫���A���́A�����̏ꍇOIF�֏�������
        IF (((lr_mst_rec.trans_type = gv_trans_type_receive) AND (lr_mst_rec.def_qty6 > 0))
          OR (lr_mst_rec.trans_type = gv_trans_type_correct)) THEN
-- 2008/12/30 v1.13 T.Yoshimoto Mod End
--
          -- ����I�[�v���C���^�t�F�[�X�̍쐬
          proc_rcv_if(
            lr_mst_rec,
            lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
        END IF;
--
        -- ���Z�����̐ݒ�
        IF (lr_mst_rec.attribute10 = 'CS') THEN
          -- 2008/05/24 UPD START Y.Takayama
          --lr_mst_rec.conv_factor := lr_mst_rec.pla_qty;
          lr_mst_rec.conv_factor := TO_NUMBER(lr_mst_rec.pla_qty);
          -- 2008/05/24 UPD END   Y.Takayama
        ELSE
          lr_mst_rec.conv_factor := 1;
        END IF;
--
        -- �V�K�o�^
        IF (lr_mst_rec.exec_flg = gn_mode_ins) THEN
--
          -- ����ԕi����(�A�h�I��)�̍쐬
          proc_xxpo_rcv_ins(
            lr_mst_rec,
            lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
--
        -- ����
        ELSIF (lr_mst_rec.exec_flg = gn_mode_upd) THEN
--
          -- ����ԕi����(�A�h�I��)�̍X�V
          BEGIN
            UPDATE xxpo_rcv_and_rtn_txns
            SET    rcv_rtn_quantity       = lr_mst_rec.def_qty6         -- ����ԕi����
                  ,quantity               = lr_mst_rec.rcv_qty          -- ����
                  ,conversion_factor      = lr_mst_rec.conv_factor      -- ���Z����
                  ,last_updated_by        = gn_last_update_by
                  ,last_update_date       = gd_last_update_date
                  ,last_update_login      = gn_last_update_login
                  ,request_id             = gn_request_id
                  ,program_application_id = gn_program_application_id
                  ,program_id             = gn_program_id
                  ,program_update_date    = gd_program_update_date
            WHERE  source_document_number   = lr_mst_rec.source_doc_number
            AND    source_document_line_num = lr_mst_rec.source_doc_line_num;
--
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              NULL;
--
            WHEN OTHERS THEN
              RAISE global_api_others_expt;
          END;
        END IF;
--
        -- �������ׂ̍X�V
        BEGIN
          UPDATE po_lines_all
          SET    attribute7             = lr_mst_rec.attribute6     -- �������
                ,last_update_date       = gd_last_update_date
                ,last_updated_by        = gn_last_update_by
                ,last_update_login      = gn_last_update_login
                ,request_id             = gn_request_id
                ,program_application_id = gn_program_application_id
                ,program_id             = gn_program_id
                ,program_update_date    = gd_program_update_date
          WHERE  po_line_id   = lr_mst_rec.po_line_id
          AND    po_header_id = lr_mst_rec.po_header_id;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
--
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
      END IF;
--
    END LOOP set_data_loop;
--
    BEGIN
--
      -- �������׍X�V
      UPDATE po_lines_all
      SET    attribute13            = gv_flg_on                     -- ���ʊm��t���O:'Y'
            ,last_update_date       = gd_last_update_date
            ,last_updated_by        = gn_last_update_by
            ,last_update_login      = gn_last_update_login
            ,request_id             = gn_request_id
            ,program_application_id = gn_program_application_id
            ,program_id             = gn_program_id
            ,program_update_date    = gd_program_update_date
      WHERE  po_header_id IN (
        SELECT po_header_id
        FROM   po_headers_all
        WHERE  segment1 = gv_header_number
      );
--
      -- �����w�b�_�X�V
      UPDATE po_headers_all
      SET    attribute1             = gv_qty_fixed_type             -- �X�e�[�^�X:���ʊm���('30')
            ,last_update_date       = gd_last_update_date
            ,last_updated_by        = gn_last_update_by
            ,last_update_login      = gn_last_update_login
            ,request_id             = gn_request_id
            ,program_application_id = gn_program_application_id
            ,program_id             = gn_program_id
            ,program_update_date    = gd_program_update_date
      WHERE  segment1 = gv_header_number;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END set_rcv_data;
--
  /***********************************************************************************
   * Procedure Name   : keep_rcv_data
   * Description      : ������я��ێ�(B-4)
   ***********************************************************************************/
  PROCEDURE keep_rcv_data(
    ov_errbuf     OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'keep_rcv_data'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    <<keep_data_loop>>
    FOR i IN 0..gn_b_3_cnt-1 LOOP
--
      -- �o�^�f�[�^
      IF (gt_b_03_mast(i).rcv_rtn_quantity IS NULL) THEN
        gt_b_03_mast(i).exec_flg := gn_mode_ins;
--
      -- �X�V�f�[�^
      ELSE
        -- �d����o�׎��ѐ���<>����ԕi����
        IF ((gt_b_03_mast(i).attribute6 IS NOT NULL)
        AND (gt_b_03_mast(i).rcv_rtn_quantity <> gt_b_03_mast(i).def_qty6)) THEN
          gt_b_03_mast(i).exec_flg := gn_mode_upd;
        ELSE
          gt_b_03_mast(i).exec_flg := gn_mode_oth;
        END IF;
      END IF;
--
      -- �P��<>�����P��
      IF ((gt_b_03_mast(i).unit_code <> gt_b_03_mast(i).attribute10)
      AND (gt_b_03_mast(i).attribute10 = 'CS')) THEN
        -- 2008/05/24 UPD START Y.Takayama
        --gt_b_03_mast(i).rcv_qty := gt_b_03_mast(i).def_qty6 * gt_b_03_mast(i).pla_qty;
        gt_b_03_mast(i).rcv_qty := gt_b_03_mast(i).def_qty6 * TO_NUMBER(gt_b_03_mast(i).pla_qty);
        -- 2008/05/24 UPD END   Y.Takayama
      ELSE
        gt_b_03_mast(i).rcv_qty := gt_b_03_mast(i).def_qty6;
      END IF;
--
      -- ������ʍ���
      -- �v�Z����������� - ����ԕi����(�A�h�I��)�̐���
      -- 2008/05/24 UPD START Y.Takayama
      --gt_b_03_mast(i).rcv_cov_qty := gt_b_03_mast(i).rcv_qty - gt_b_03_mast(i).xrt_qty;
      gt_b_03_mast(i).rcv_cov_qty := gt_b_03_mast(i).rcv_qty - NVL(gt_b_03_mast(i).xrt_qty, 0);
      -- 2008/05/24 UPD END   Y.Takayama
--
    END LOOP keep_data_loop;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END keep_rcv_data;
--
  /***********************************************************************************
   * Procedure Name   : get_rcv_data
   * Description      : ������э쐬�Ώۃf�[�^�擾(B-3)
   ***********************************************************************************/
  PROCEDURE get_rcv_data(
    ov_errbuf     OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_rcv_data'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    mst_rec           masters_rec;
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR po_data_cur
    IS
      SELECT xxpo.segment1 as po_header_number         -- �����ԍ�
            ,xxpo.po_header_id                         -- �����w�b�_ID
            ,xxpo.vendor_id                            -- �d����ID
            ,xxpo.h_attribute5                         -- �[����R�[�h
            ,xxpo.h_attribute9                         -- �˗��ԍ�
            ,xxpo.h_attribute4                         -- �[����
            ,xxpo.h_attribute6                         -- �����敪
            ,xxpo.h_attribute10                        -- �����R�[�h
            ,xxpo.h_attribute3                         -- ������ID
            ,xxpo.po_line_id                           -- ��������ID
            ,xxpo.line_num                             -- ���הԍ�
            ,xxpo.item_id                              -- �i��ID
            ,xxpo.l_attribute1 as lot_no               -- ���b�gNO
            ,xxpo.l_attribute5                         -- �d����o�ד�
            ,xxpo.l_attribute6                         -- �d����o�א���
            ,xxpo.l_attribute8                         -- �P��
            ,xxpo.unit_meas_lookup_code                -- �P��
            ,xxpo.l_attribute10                        -- �����P��
            -- 2008/05/24 UPD START Y.Takayama
            --,xxpo.quantity as pla_qty                  -- ����
            ,xxpo.l_attribute4 as pla_qty                  -- ����
            -- 2008/05/24 UPD START Y.Takayama
            ,xxpo.l_attribute7                         -- �������
            ,xilv.inventory_location_id                -- �ۊǏꏊID
            ,xvv.segment1                              -- �d����ԍ�
            ,xiv.item_no                               -- �i�ڃR�[�h
            ,ilm.lot_id                                -- ���b�gID
            ,xrt.source_document_number                -- �������ԍ�
            ,xrt.source_document_line_num              -- ���������הԍ�
            ,xrt.quantity as xrt_qty                   -- ����
            ,xrt.rcv_rtn_quantity                      -- ����ԕi����
            ,xrt.conversion_factor                     -- ���Z����
            ,rsl.attribute1                            -- ���ID
            ,xiv.lot_ctl                               -- ���b�g
            ,xiv.item_id as item_idv                   -- �i��ID
            ,ilm.expire_date                           -- ���b�g������
      FROM   xxcmn_item_locations_v xilv               -- OPM�ۊǏꏊ���VIEW
            ,xxcmn_vendors_v xvv                       -- �d������VIEW
            ,xxcmn_item_mst_v xiv                      -- OPM�i�ڏ��VIEW
            ,ic_lots_mst ilm                           -- OPM���b�g�}�X�^
            ,xxpo_rcv_and_rtn_txns xrt                 -- ����ԕi����(�A�h�I��)
            ,rcv_shipment_lines rsl                    -- �������
            ,(SELECT pha.po_header_id
                    ,pha.attribute3 as h_attribute3    -- ������ID
                    ,pha.attribute4 as h_attribute4    -- �[����
                    ,pha.attribute5 as h_attribute5    -- �[����R�[�h
                    ,pha.attribute6 as h_attribute6    -- �����敪
                    ,pha.attribute9 as h_attribute9    -- �˗��ԍ�
                    ,pha.attribute10 as h_attribute10  -- �����R�[�h
                    ,pha.vendor_id
                    ,pha.segment1
                    ,pla.po_line_id
                    ,pla.item_id
                    ,pla.line_num
                    ,pla.attribute1 as l_attribute1    -- ���b�g�ԍ�
                    -- 2008/05/24 ADD START Y.Takayama
                    ,pla.attribute4 as l_attribute4    -- �݌ɓ���
                    -- 2008/05/24 ADD END   Y.Takayama
                    ,pla.attribute5 as l_attribute5    -- �d����o�ד�
                    ,pla.attribute6 as l_attribute6    -- �d����o�א���
                    ,pla.attribute7 as l_attribute7    -- �������
                    ,pla.attribute8 as l_attribute8    -- �d���艿
                    ,pla.attribute10 as l_attribute10  -- �����P��
                    ,pla.unit_meas_lookup_code
                    ,pla.quantity
-- 2008/12/06 H.Itou Add Start
                    ,pla.cancel_flag                   -- �폜�t���O
-- 2008/12/06 H.Itou Add End
              FROM  po_headers_all pha,                -- �����w�b�_
                    po_lines_all  pla                  -- ��������
              WHERE pha.po_header_id = pla.po_header_id) xxpo
      WHERE xxpo.h_attribute5 = xilv.segment1
      AND   xxpo.vendor_id    = xvv.vendor_id
      AND   xxpo.item_id      = xiv.inventory_item_id
      AND   NVL(xxpo.l_attribute1,gv_defaultlot) = ilm.lot_no
      AND   xiv.item_id       = ilm.item_id
      AND   xxpo.segment1     = xrt.source_document_number(+)
      AND   xxpo.line_num     = xrt.source_document_line_num(+)
      AND   TO_CHAR(xrt.txns_id) = rsl.attribute1(+)
-- 2008/12/06 H.Itou Add Start
      AND   NVL(xxpo.cancel_flag, 'N') = 'N'            -- �폜�ς݂̖��ׂ͑ΏۊO
-- 2008/12/06 H.Itou Add End
      AND   xxpo.segment1     = gv_header_number;
--
    -- *** ���[�J���E���R�[�h ***
    lr_po_data_rec po_data_cur%ROWTYPE;
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    OPEN po_data_cur;
--
    <<po_data_loop>>
    LOOP
      FETCH po_data_cur INTO lr_po_data_rec;
      EXIT WHEN po_data_cur%NOTFOUND;
--
      mst_rec.po_header_number    := lr_po_data_rec.po_header_number;
      mst_rec.po_header_id        := lr_po_data_rec.po_header_id;
      mst_rec.vendor_id           := lr_po_data_rec.vendor_id;
      mst_rec.pha_def5            := lr_po_data_rec.h_attribute5;
      mst_rec.attribute9          := lr_po_data_rec.h_attribute9;
      mst_rec.attribute4          := lr_po_data_rec.h_attribute4;
      mst_rec.h_attribute10       := lr_po_data_rec.h_attribute10;
      mst_rec.po_line_id          := lr_po_data_rec.po_line_id;
      mst_rec.line_num            := lr_po_data_rec.line_num;
      mst_rec.item_id             := lr_po_data_rec.item_id;
      mst_rec.lot_no              := lr_po_data_rec.lot_no;
      mst_rec.pla_def5            := lr_po_data_rec.l_attribute5;
      mst_rec.attribute6          := lr_po_data_rec.l_attribute6;
      mst_rec.unit_code           := lr_po_data_rec.unit_meas_lookup_code;
      mst_rec.attribute10         := lr_po_data_rec.l_attribute10;
      mst_rec.pla_qty             := lr_po_data_rec.pla_qty;
      mst_rec.attribute7          := lr_po_data_rec.l_attribute7;
      mst_rec.source_doc_number   := lr_po_data_rec.source_document_number;
      mst_rec.source_doc_line_num := lr_po_data_rec.source_document_line_num;
      mst_rec.xrt_qty             := lr_po_data_rec.xrt_qty;
      mst_rec.rcv_rtn_quantity    := lr_po_data_rec.rcv_rtn_quantity;
      mst_rec.conversion_factor   := lr_po_data_rec.conversion_factor;
      mst_rec.inv_location_id     := lr_po_data_rec.inventory_location_id;
      mst_rec.segment1            := lr_po_data_rec.segment1;
      mst_rec.item_no             := lr_po_data_rec.item_no;
      mst_rec.lot_id              := lr_po_data_rec.lot_id;
      mst_rec.attribute1          := lr_po_data_rec.attribute1;
      mst_rec.drop_ship_type      := lr_po_data_rec.h_attribute6;
      mst_rec.unit_price          := lr_po_data_rec.l_attribute8;
      mst_rec.lot_ctl             := lr_po_data_rec.lot_ctl;
      mst_rec.expire_date         := lr_po_data_rec.expire_date;
      mst_rec.item_idv            := lr_po_data_rec.item_idv;
      mst_rec.h_attribute3        := lr_po_data_rec.h_attribute3;
--
      mst_rec.def_date4 := FND_DATE.STRING_TO_DATE(lr_po_data_rec.h_attribute4,'YYYY/MM/DD');
      mst_rec.def_date5 := FND_DATE.STRING_TO_DATE(lr_po_data_rec.l_attribute5,'YYYY/MM/DD');
      mst_rec.def_qty6  := TO_NUMBER(lr_po_data_rec.l_attribute6);
      mst_rec.def_qty7  := TO_NUMBER(lr_po_data_rec.l_attribute7);
--
      BEGIN
        SELECT mil.organization_id
              ,mil.subinventory_code
              ,mil.inventory_location_id
        INTO   mst_rec.organization_id
              ,mst_rec.subinventory
              ,mst_rec.locator_id
        FROM  mtl_item_locations mil
        WHERE mil.segment1 = mst_rec.pha_def5;           -- �[����R�[�h
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          mst_rec.organization_id := NULL;
          mst_rec.subinventory    := NULL;
          mst_rec.locator_id      := NULL;
--
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
--
      IF (mst_rec.h_attribute3 IS NOT NULL) THEN
        mst_rec.assen_vendor_id := TO_NUMBER(mst_rec.h_attribute3);
--
        -- �d����}�X�^�̌���
        BEGIN
          SELECT pv.segment1
          INTO   mst_rec.assen_vendor_code
          FROM   xxcmn_vendors2_v pv
          WHERE  pv.vendor_id = mst_rec.assen_vendor_id
          AND    pv.start_date_active <= TRUNC(mst_rec.def_date4)       -- �[����
          AND    pv.end_date_active >= TRUNC(mst_rec.def_date4)         -- �[����
          AND    ROWNUM       = 1;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            mst_rec.assen_vendor_id   := NULL;
            mst_rec.assen_vendor_code := NULL;
--
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
--
      ELSE
        mst_rec.assen_vendor_id   := NULL;
        mst_rec.assen_vendor_code := NULL;
      END IF;
--
      gt_b_03_mast(gn_b_3_cnt) := mst_rec;
--
      gn_b_3_cnt := gn_b_3_cnt + 1;
--
    END LOOP po_data_loop;
--
    CLOSE po_data_cur;
--
    -- �f�[�^�����݂��Ȃ�
    IF (gn_b_3_cnt < 1) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            'APP-XXPO-10066',
                                            gv_tkn_table_num,
                                            '��������',
                                            gv_tkn_po_num,
                                            gv_header_number);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ����ԕi����(�A�h�I��)�̃��b�N
    BEGIN
      OPEN gc_lock_xrt_cur;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
--
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              'APP-XXPO-10138');
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN OTHERS THEN
        RAISE global_api_expt;
    END;
--
    -- �O���[�vID�̎擾
    SELECT rcv_interface_groups_s.NEXTVAL
    INTO   gn_group_id
    FROM   DUAL;
--
-- 2008/05/14 �폜
--    gn_group_id := gn_group_id || TO_NUMBER(gv_header_number);
--
    -- �˗��ԍ��̎擾
    SELECT pha.attribute9
    INTO   gv_request_no
    FROM   po_headers_all pha
    WHERE  pha.segment1 = gv_header_number
    AND    ROWNUM = 1;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (po_data_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE po_data_cur;
      END IF;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (po_data_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE po_data_cur;
      END IF;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (po_data_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE po_data_cur;
      END IF;
--
--#####################################  �Œ蕔 END   #############################################
--
  END get_rcv_data;
--
  /**********************************************************************************
   * Procedure Name   : parameter_check
   * Description      : �p�����[�^�`�F�b�N(B-2)
   ***********************************************************************************/
  PROCEDURE parameter_check(
    iv_po_number        IN         VARCHAR2,         -- �����ԍ�
    ov_errbuf           OUT NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'parameter_check';       -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf   VARCHAR2(5000);   -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1);      -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000);   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--
    -- �����ԍ���NULL
    IF (iv_po_number IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            'APP-XXPO-10102',
                                            gv_tkn_para_name,
                                            '�����ԍ�');
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
--
    -- �����ԍ����͂���
    ELSE
--
      gv_header_number := iv_po_number;
--
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            'APP-XXPO-30039',
                                            gv_tkn_po_num,
                                            iv_po_number);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
--
    -- �f�t�H���g���b�g
    gv_defaultlot := FND_PROFILE.VALUE('IC$DEFAULT_LOT');
--
    -- WHO�J�����̎擾
    gn_created_by             := FND_GLOBAL.USER_ID;           -- �쐬��
    gd_creation_date          := SYSDATE;                      -- �쐬��
    gn_last_update_by         := FND_GLOBAL.USER_ID;           -- �ŏI�X�V��
    gd_last_update_date       := SYSDATE;                      -- �ŏI�X�V��
    gn_last_update_login      := FND_GLOBAL.LOGIN_ID;          -- �ŏI�X�V���O�C��
    gn_request_id             := FND_GLOBAL.CONC_REQUEST_ID;   -- �v��ID
    gn_program_application_id := FND_GLOBAL.PROG_APPL_ID;      -- �v���O�����A�v���P�[�V����ID
    gn_program_id             := FND_GLOBAL.CONC_PROGRAM_ID;   -- �v���O����ID
    gd_program_update_date    := SYSDATE;                      -- �v���O�����X�V��
--    gn_person_id              := FND_GLOBAL.USER_ID;
--
    -- 2008/04/16 �C��
    BEGIN
      SELECT employee_id
      INTO   gn_person_id
      FROM   fnd_user
      WHERE  user_id = gn_created_by
      AND    ROWNUM = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        gn_person_id := NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END parameter_check;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_po_number    IN            VARCHAR2,       -- �����ԍ�
    ov_errbuf          OUT NOCOPY VARCHAR2,       -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,       -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'submain';               -- �v���O������
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
--
    -- *** ���[�J���ϐ� ***
    ln_req_id     NUMBER;
    lb_ret        BOOLEAN;
    lb_qty_ret    BOOLEAN;
    ln_ret        NUMBER;
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    gn_b_3_cnt    := 0;
    gn_b_5_cnt    := 0;
    gn_b_7_cnt    := 0;
    gn_b_9_cnt    := 0;
    gn_b_15_flg   := 0;
    gn_b_16_flg   := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
    -- ================================
    -- B-2.�p�����[�^�`�F�b�N
    -- ================================
    parameter_check(
      iv_po_number,       -- �����ԍ�
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ================================
    -- B-3.������э쐬�Ώۃf�[�^�擾
    -- ================================
    get_rcv_data(
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ================================
    -- B-4.������я��ێ�
    -- ================================
    keep_rcv_data(
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �d����o�א��ʂ̃`�F�b�N
    check_quantity(
      lb_qty_ret,
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �d����o�א��ʂ��S���ׂɐݒ肠��
    IF (lb_qty_ret) THEN
      -- ================================
      -- B-5.������я��o�^
      -- ================================
      set_rcv_data(
        lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ================================
    -- B-6.�o�׎��э쐬�p�^�[������
    -- ================================
    check_deli_pat(
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
--
    ELSIF (lv_retcode = gv_status_warn) THEN
      ov_retcode := lv_retcode;
    END IF;
--
    -- �J�[�\�����J���Ă����
    IF (gc_lock_xrt_cur%ISOPEN) THEN
      -- �J�[�\���̃N���[�Y
      CLOSE gc_lock_xrt_cur;
    END IF;
--
    COMMIT;
--
    -- �ُ�I���ȊO
    IF (lv_retcode <> gv_status_error) THEN
--
      IF ((gn_b_5_cnt > 0) OR (gn_b_9_cnt > 0)) THEN
--
        IF ((gn_b_5_cnt > 0) AND (gn_group_id2 IS NOT NULL)) THEN
--
          -- ����������
          ln_ret := FND_REQUEST.SUBMIT_REQUEST(
                        application  => gv_rcv_app              -- �A�v���P�[�V�����Z�k��
                       ,program      => gv_rcv_app_name         -- �v���O������
                       ,argument1    => 'BATCH'                 -- �������[�h
                       ,argument2    => TO_CHAR(gn_group_id2)   -- �O���[�vID
                      );
--
          IF (ln_ret = 0) THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                                  'APP-XXPO-10056');
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
          END IF;
        END IF;
--
        -- �v���Z�b�g�̏���
        lb_ret := FND_SUBMIT.SET_REQUEST_SET(gv_app_name, gv_request_set_name);
--
        IF (NOT lb_ret) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                                'APP-XXPO-10024',
                                                gv_tkn_conc_name,
                                                gv_request_name);
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
        END IF;
      END IF;
--
      -- ����I�[�v��IF�Ƀf�[�^�o�^����
      -- �󒍃w�b�_�A�h�I���̓o�^�E�X�V����
      IF ((gn_b_5_cnt > 0) OR (gn_b_9_cnt > 0)) THEN
--
        -- ================================
        -- B-15.�����������N��
        -- ================================
        proc_rcv_exec(
          lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        -- ================================
        -- B-16.�o�׈˗�/�o�׎��э쐬�����N��
        -- ================================
        proc_deli_exec(
          lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
      END IF;
--
      -- �v���Z�b�g�ɐݒ肠��
      IF ((gn_b_15_flg = 1) OR (gn_b_16_flg = 1)) THEN
--
        -- �v���Z�b�g�̔��s
        ln_req_id := FND_SUBMIT.SUBMIT_SET(null,FALSE);
--
        -- �������s
        IF (ln_req_id = 0) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                                'APP-XXPO-10024',
                                                gv_tkn_conc_name,
                                                gv_request_name);
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
        END IF;
--
        -- �v��ID�̕\��
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              'APP-XXPO-30021',
                                              gv_tkn_conc_name,
                                              gv_request_name,
                                              gv_tkn_conc_id,
                                              ln_req_id);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      END IF;
--
      -- ================================
      -- B-17.�������ʏ��o��
      -- ================================
      disp_report(
        lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
--##########################################
--##### ���̑��������K�v�Ȃ�A�ǉ����� #####
--##########################################
--
--#################################  �Œ��O������ START   ###################################
--
  EXCEPTION
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (gc_lock_xrt_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_lock_xrt_cur;
      END IF;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (gc_lock_xrt_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_lock_xrt_cur;
      END IF;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (gc_lock_xrt_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_lock_xrt_cur;
      END IF;
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
    errbuf           OUT NOCOPY VARCHAR2,           -- �G���[�E���b�Z�[�W           --# �Œ� #
    retcode          OUT NOCOPY VARCHAR2,           -- ���^�[���E�R�[�h             --# �Œ� #
    iv_po_number  IN            VARCHAR2)           -- 1.�����ԍ�
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'main';                  -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �Œ�o�͗p�ϐ��Z�b�g
    -- ======================
    --���s���[�U���擾
    gv_exec_user := fnd_global.user_name;
--
    --���s�R���J�����g���擾
    SELECT fcp.concurrent_program_name
    INTO   gv_conc_name
    FROM   fnd_concurrent_programs fcp
    WHERE  fcp.application_id        = fnd_global.prog_appl_id
    AND    fcp.concurrent_program_id = fnd_global.conc_program_id
    AND    ROWNUM                    = 1;
--
    -- ======================
    -- �Œ�o��
    -- ======================
    --���s���[�U���o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00001','USER',gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���s�R���J�����g���o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00002','CONC',gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�N�����ԏo��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118','TIME',
                                           TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --��؂蕶���o��
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo��(���ۂ̏�����submain�ōs��)
    -- ===============================================
    submain(
      iv_po_number,                                -- 1.�����ԍ�
      lv_errbuf,   -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,  -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF (lv_retcode = gv_status_error) THEN
      IF (lv_errmsg IS NULL) THEN
        --��^���b�Z�[�W�E�Z�b�g
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10030');
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
    -- ==================================
    -- ���^�[���E�R�[�h�̃Z�b�g�A�I������
    -- ==================================
--
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00008','CNT',TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�G���[�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00010','CNT',TO_CHAR(gn_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�o��
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = userenv('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type, 
                                                                      flv.view_application_id)
    AND    flv.lookup_type         = 'CP_STATUS_CODE'
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            gv_status_normal,gv_sts_cd_normal,
                                            gv_status_warn,gv_sts_cd_warn,
                                            gv_sts_cd_error)
    AND    ROWNUM                  = 1;
--
    --�����X�e�[�^�X�o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00012','STATUS',gv_conc_status);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
--
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = gv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxpo320001c;
/
