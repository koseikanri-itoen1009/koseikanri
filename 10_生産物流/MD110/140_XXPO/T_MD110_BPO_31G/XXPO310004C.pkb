CREATE OR REPLACE PACKAGE BODY xxpo310004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo310004c(body)
 * Description      : HHT������ьv��
 * MD.050           : �������            T_MD050_BPO_310
 * MD.070           : HHT������ьv��     T_MD070_BPO_31G
 * Version          : 1.5
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  keep_po_head_id        �����w�b�_ID�̕ێ�
 *  get_location           �q�ɁA�g�D�A��Ђ̎擾
 *  get_lot_mst            OPM���b�g�}�X�^�̎擾
 *  init_proc              �O����                                          (F-1)
 *  other_data_get         ������ɂ�菈���ΏۊO�ƂȂ������я��擾    (F-2)
 *  disp_other_data        ����ΏۊO���o��                              (F-3)
 *  master_data_get        �����Ώۂ̎�����擾                          (F-4)
 *  proper_check           �Ó����`�F�b�N                                  (F-5)
 *  insert_open_if         ����I�[�v��IF�ւ̎�����o�^                  (F-6)
 *  insert_rcv_and_rtn     ����ԕi����(�A�h�I��)�ւ̎�����o�^          (F-7)
 *  upd_po_lines           �������׍X�V                                    (F-8)
 *  upd_lot_mst            ���b�g�X�V                                      (F-9)
 *  insert_tran            �݌Ɏ���ɏo�ɏ��o�^                          (F-10)
 *  disp_report            ���������������o��                            (F-11)
 *  upd_status             �����X�e�[�^�X�X�V                              (F-12)
 *  commit_open_if         ����I�[�v��IF�ɓo�^�������e�̔��f              (F-13)
 *  del_rcv_txns_if        �������IF(�A�h�I��)�̑S�f�[�^�폜              (F-14)
 *  term_proc              �I������                                        (F-15)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/28    1.0   Oracle �R�� ��_ ����쐬
 *  2008/04/21    1.1   Oracle �R�� ��_ �ύX�v��No43�Ή�
 *  2008/05/21    1.2   Oracle �R�� ��_ �ύX�v��No109�Ή�
 *                                       �����e�X�g�s����O#300_3�Ή�
 *  2008/05/23    1.3   Oracle �R�� ��_ �����e�X�g�s����O�Ή�
 *  2008/06/26    1.4   Oracle �R�� ��_ �����e�X�g�s�No84,86�Ή�
 *  2008/07/09    1.5   Oracle �R����_  I_S_192�Ή�
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
  master_data_get_expt      EXCEPTION;     -- ������擾�G���[
  term_proc_expt            EXCEPTION;     -- �I�������G���[
--
  lock_expt                 EXCEPTION;     -- ���b�N�擾�G���[
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'xxpo310004c';   -- �p�b�P�[�W��
  gv_app_name      CONSTANT VARCHAR2(5)   := 'XXPO';          -- �A�v���P�[�V�����Z�k��
  gv_com_name      CONSTANT VARCHAR2(5)   := 'XXCMN';         -- �A�v���P�[�V�����Z�k��
--
  gv_tbl_name      CONSTANT VARCHAR2(100) := 'xxpo_rcv_txns_interface';
--
  -- �g�[�N��
  gv_tkn_api_name       CONSTANT VARCHAR2(20) := 'API_NAME';
  gv_tkn_count          CONSTANT VARCHAR2(20) := 'COUNT';
  gv_tkn_table          CONSTANT VARCHAR2(20) := 'TABLE';
  gv_tkn_h_no           CONSTANT VARCHAR2(20) := 'H_NO';
  gv_tkn_m_no           CONSTANT VARCHAR2(20) := 'M_NO';
  gv_tkn_date           CONSTANT VARCHAR2(20) := 'DATE';
  gv_tkn_name           CONSTANT VARCHAR2(20) := 'NAME';
  gv_tkn_item_no        CONSTANT VARCHAR2(20) := 'ITEM_NO';
  gv_tkn_value          CONSTANT VARCHAR2(20) := 'VALUE';
  gv_tkn_rcv_num        CONSTANT VARCHAR2(20) := 'RCV_NUM';
  gv_tkn_name_vendor    CONSTANT VARCHAR2(20) := 'VENDOR';
  gv_tkn_name_shipment  CONSTANT VARCHAR2(20) := 'SHIPMENT';
--
  gv_tkn_number_31g_01    CONSTANT VARCHAR2(15) := 'APP-XXPO-10027';
  gv_tkn_number_31g_02    CONSTANT VARCHAR2(15) := 'APP-XXPO-10053';
  gv_tkn_number_31g_03    CONSTANT VARCHAR2(15) := 'APP-XXPO-10054';
  gv_tkn_number_31g_04    CONSTANT VARCHAR2(15) := 'APP-XXPO-10055';
  gv_tkn_number_31g_05    CONSTANT VARCHAR2(15) := 'APP-XXPO-10057';
  gv_tkn_number_31g_06    CONSTANT VARCHAR2(15) := 'APP-XXPO-10058';
  gv_tkn_number_31g_07    CONSTANT VARCHAR2(15) := 'APP-XXPO-10059';
  gv_tkn_number_31g_08    CONSTANT VARCHAR2(15) := 'APP-XXPO-10060';
  gv_tkn_number_31g_09    CONSTANT VARCHAR2(15) := 'APP-XXPO-10076';
  gv_tkn_number_31g_10    CONSTANT VARCHAR2(15) := 'APP-XXPO-30026';
  gv_tkn_number_31g_11    CONSTANT VARCHAR2(15) := 'APP-XXPO-30027';
  gv_tkn_number_31g_12    CONSTANT VARCHAR2(15) := 'APP-XXPO-10022';
--
  gv_tkn_name_vendor_code   CONSTANT VARCHAR2(50) := '�����R�[�h';
  gv_tkn_name_location_code CONSTANT VARCHAR2(50) := '�[����R�[�h';
  gv_tkn_name_item_code     CONSTANT VARCHAR2(50) := '�i�ڃR�[�h';
  gv_tkn_name_lot_number    CONSTANT VARCHAR2(50) := '���b�gNo';
--
  gv_tbl_name_po_head       CONSTANT VARCHAR2(50) := '�����w�b�_';
  gv_tbl_name_po_line       CONSTANT VARCHAR2(50) := '��������';
  gv_tbl_name_lot_mast      CONSTANT VARCHAR2(50) := 'OPM���b�g�}�X�^';
--
  -- ����������
  gv_appl_name           CONSTANT VARCHAR2(50) := 'PO';
  gv_prg_name            CONSTANT VARCHAR2(50) := 'RVCTP';
  gv_exec_mode           CONSTANT VARCHAR2(50) := 'BATCH';
--
  gv_add_status_zmi      CONSTANT VARCHAR2(5)  := '20';              -- �����쐬��
  gv_add_status_rcv_on   CONSTANT VARCHAR2(5)  := '25';              -- �������
  gv_add_status_num_zmi  CONSTANT VARCHAR2(5)  := '30';              -- ���ʊm���
  gv_add_status_qty_zmi  CONSTANT VARCHAR2(5)  := '35';              -- ���z�m���
  gv_po_type_rev         CONSTANT VARCHAR2(1)  := '3';               -- �����݌�
  gv_prod_class_code     CONSTANT VARCHAR2(1)  := '2';               -- �h�����N
  gv_txns_type_po        CONSTANT VARCHAR2(1)  := '1';               -- ���
  gn_lot_ctl_on          CONSTANT NUMBER       := 1;                 -- ���b�g�Ǘ��i
  gv_flg_on              CONSTANT VARCHAR2(1)  := 'Y';
  gv_flg_off             CONSTANT VARCHAR2(1)  := 'N';
  gv_one_space           CONSTANT VARCHAR2(1)  := ' ';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ***************************************
  -- ***    �擾���i�[���R�[�h�^��`   ***
  -- ***************************************
--
  -- F-2:�������擾�ΏۊO�f�[�^
  TYPE other_rec IS RECORD(
    src_doc_num        xxpo_rcv_txns_interface.source_document_number%TYPE,   -- �������ԍ�
    src_doc_line_num   xxpo_rcv_txns_interface.source_document_line_num%TYPE, -- ���������הԍ�
    item_code          xxpo_rcv_txns_interface.item_code%TYPE,                -- �i�ڃR�[�h
    rcv_date           xxpo_rcv_txns_interface.rcv_date%TYPE,                 -- �����
    txns_id            xxpo_rcv_txns_interface.txns_id%TYPE,                  -- ���ID
--
    exec_flg            NUMBER                                    -- �����t���O
  );
--
  -- F-4:�������擾�Ώۃf�[�^
  TYPE masters_rec IS RECORD(
    txns_id            xxpo_rcv_txns_interface.txns_id%TYPE,                  -- ���ID
    src_doc_num        xxpo_rcv_txns_interface.source_document_number%TYPE,   -- �������ԍ�
    vendor_code        xxpo_rcv_txns_interface.vendor_code%TYPE,              -- �����R�[�h
    vendor_name        xxpo_rcv_txns_interface.vendor_name%TYPE,              -- ����於
    promised_date      xxpo_rcv_txns_interface.promised_date%TYPE,            -- �[����
    location_code      xxpo_rcv_txns_interface.location_code%TYPE,            -- �[����R�[�h
    location_name      xxpo_rcv_txns_interface.location_name%TYPE,            -- �[���於
    src_doc_line_num   xxpo_rcv_txns_interface.source_document_line_num%TYPE, -- ���������הԍ�
    item_code          xxpo_rcv_txns_interface.item_code%TYPE,                -- �i�ڃR�[�h
    item_name          xxpo_rcv_txns_interface.item_name%TYPE,                -- �i�ږ���
    lot_number         xxpo_rcv_txns_interface.lot_number%TYPE,               -- ���b�gNo
    producted_date     xxpo_rcv_txns_interface.producted_date%TYPE,           -- ������
    koyu_code          xxpo_rcv_txns_interface.koyu_code%TYPE,                -- �ŗL�L��
    quantity           xxpo_rcv_txns_interface.quantity%TYPE,                 -- �w������
    rcv_quantity_uom   xxpo_rcv_txns_interface.rcv_quantity_uom%TYPE,         -- �P�ʃR�[�h
    po_description     xxpo_rcv_txns_interface.po_line_description%TYPE,      -- ���דE�v
    rcv_date           xxpo_rcv_txns_interface.rcv_date%TYPE,                 -- �����
    rcv_quantity       xxpo_rcv_txns_interface.rcv_quantity%TYPE,             -- �������
    rcv_description    xxpo_rcv_txns_interface.rcv_line_description%TYPE,     -- ������דE�v
    po_header_id       po_headers_all.po_header_id%TYPE,                      -- �����w�b�_ID
    segment1           po_headers_all.segment1%TYPE,                          -- �����ԍ�
    attribute6         po_headers_all.attribute6%TYPE,                        -- �����敪
    attribute11        po_headers_all.attribute11%TYPE,                       -- �����敪
    vendor_id          po_headers_all.vendor_id%TYPE,                         -- �����ID
    delivery_code      po_headers_all.attribute5%TYPE,                        -- �[����R�[�h
    department_code    po_headers_all.attribute10%TYPE,                       -- �����R�[�h
    po_line_id         po_lines_all.po_line_id%TYPE,                          -- ��������ID
    line_num           po_lines_all.line_num%TYPE,                            -- ���הԍ�
    item_id            po_lines_all.item_id%TYPE,                             -- �i��ID
    unit_price         po_lines_all.unit_price%TYPE,                          -- �P��
    lot_no             po_lines_all.attribute1%TYPE,                          -- ���b�gNo
    unit_code          po_lines_all.unit_meas_lookup_code%TYPE,               -- �P��
    attribute10        po_lines_all.attribute10%TYPE,                         -- �����P��
    lot_id             ic_lots_mst.lot_id%TYPE,                               -- ���b�gID
    attribute4         ic_lots_mst.attribute4%TYPE,                           -- �[����(����)
    attribute5         ic_lots_mst.attribute5%TYPE,                           -- �[����(�ŏI)
    item_idv           ic_lots_mst.item_id%TYPE,                              -- �i��ID
    opm_item_id        xxcmn_item_mst_v.item_id%TYPE,                         -- OPM�i��ID
    num_of_cases       xxcmn_item_mst_v.num_of_cases%TYPE,                    -- �P�[�X����
    vendor_stock_whse  xxcmn_vendor_sites_v.vendor_stock_whse%TYPE,           -- �����݌ɓ��ɐ�
    prod_class_code    xxcmn_item_categories3_v.prod_class_code%TYPE,         -- ���i�敪
--
    lot_ctl            xxcmn_item_mst_v.lot_ctl%TYPE,                         -- ���b�g
    item_no            xxcmn_item_mst_v.item_no%TYPE,                         -- �i�ڃR�[�h
--
    vendor_no          xxcmn_vendors_v.segment1%TYPE,                         -- �d����ԍ�
--
    from_whse_code     ic_tran_cmp.whse_code%TYPE,                            -- �q��
    co_code            ic_tran_cmp.co_code%TYPE,                              -- ���
    orgn_code          ic_tran_cmp.orgn_code%TYPE,                            -- �g�D
--
    organization_id       mtl_item_locations.organization_id%TYPE,
    subinventory_code     mtl_item_locations.subinventory_code%TYPE,
    inventory_location_id mtl_item_locations.inventory_location_id%TYPE,
--
    def4_date          DATE,                                                  -- �[����(����)
    def5_date          DATE,                                                  -- �[����(�ŏI)
--
    check_result       VARCHAR(1),                               -- �Ó����`�F�b�N����
--
    exec_flg           NUMBER                                    -- �����t���O
  );
--
  -- �e�}�X�^�֔��f����f�[�^���i�[���錋���z��
  TYPE other_tbl    IS TABLE OF other_rec    INDEX BY PLS_INTEGER;
  TYPE masters_tbl  IS TABLE OF masters_rec  INDEX BY PLS_INTEGER;
--
  -- ***************************************
  -- ***      �o�^�p���ڃe�[�u���^       ***
  -- ***************************************
--
  -- ���ID
  TYPE reg_txns_id           IS TABLE OF xxpo_rcv_txns_interface.txns_id                  %TYPE INDEX BY BINARY_INTEGER;
  -- �������ԍ�
  TYPE reg_src_doc_num       IS TABLE OF xxpo_rcv_txns_interface.source_document_number   %TYPE INDEX BY BINARY_INTEGER;
  -- �����R�[�h
  TYPE reg_vendor_code       IS TABLE OF xxpo_rcv_txns_interface.vendor_code              %TYPE INDEX BY BINARY_INTEGER;
  -- �[����
  TYPE reg_promised_date     IS TABLE OF xxpo_rcv_txns_interface.promised_date            %TYPE INDEX BY BINARY_INTEGER;
  -- �[����R�[�h
  TYPE reg_location_code     IS TABLE OF xxpo_rcv_txns_interface.location_code            %TYPE INDEX BY BINARY_INTEGER;
  -- ���������הԍ�
  TYPE reg_src_doc_line_num  IS TABLE OF xxpo_rcv_txns_interface.source_document_line_num %TYPE INDEX BY BINARY_INTEGER;
  -- �i�ڃR�[�h
  TYPE reg_item_code         IS TABLE OF xxpo_rcv_txns_interface.item_code                %TYPE INDEX BY BINARY_INTEGER;
  -- ���b�gNo
  TYPE reg_lot_number        IS TABLE OF xxpo_rcv_txns_interface.lot_number               %TYPE INDEX BY BINARY_INTEGER;
  -- �P�ʃR�[�h
  TYPE reg_rcv_quantity_uom  IS TABLE OF xxpo_rcv_txns_interface.rcv_quantity_uom         %TYPE INDEX BY BINARY_INTEGER;
  -- ���דE�v
  TYPE reg_po_description    IS TABLE OF xxpo_rcv_txns_interface.po_line_description      %TYPE INDEX BY BINARY_INTEGER;
  -- �����
  TYPE reg_rcv_date          IS TABLE OF xxpo_rcv_txns_interface.rcv_date                 %TYPE INDEX BY BINARY_INTEGER;
  -- �������
  TYPE reg_rcv_quantity      IS TABLE OF xxpo_rcv_txns_interface.rcv_quantity             %TYPE INDEX BY BINARY_INTEGER;
  -- �����w�b�_ID
  TYPE reg_po_header_id      IS TABLE OF po_headers_all.po_header_id                      %TYPE INDEX BY BINARY_INTEGER;
  -- �����敪
  TYPE reg_attribute6        IS TABLE OF po_headers_all.attribute6                        %TYPE INDEX BY BINARY_INTEGER;
  -- �����ID
  TYPE reg_vendor_id         IS TABLE OF po_headers_all.vendor_id                         %TYPE INDEX BY BINARY_INTEGER;
  -- ��������ID
  TYPE reg_po_line_id        IS TABLE OF po_lines_all.po_line_id                          %TYPE INDEX BY BINARY_INTEGER;
  -- ���הԍ�
  TYPE reg_line_num          IS TABLE OF po_lines_all.line_num                            %TYPE INDEX BY BINARY_INTEGER;
  -- �i��ID
  TYPE reg_item_id           IS TABLE OF po_lines_all.item_id                             %TYPE INDEX BY BINARY_INTEGER;
  -- �P��
  TYPE reg_unit_price        IS TABLE OF po_lines_all.unit_price                          %TYPE INDEX BY BINARY_INTEGER;
  -- ���b�gNo
  TYPE reg_lot_no            IS TABLE OF po_lines_all.attribute1                          %TYPE INDEX BY BINARY_INTEGER;
  -- �P��
  TYPE reg_unit_code         IS TABLE OF po_lines_all.unit_meas_lookup_code               %TYPE INDEX BY BINARY_INTEGER;
  -- �����P��
  TYPE reg_attribute10       IS TABLE OF po_lines_all.attribute10                         %TYPE INDEX BY BINARY_INTEGER;
  -- ���b�gID
  TYPE reg_lot_id            IS TABLE OF ic_lots_mst.lot_id                               %TYPE INDEX BY BINARY_INTEGER;
  -- ����
  TYPE reg_rtn_quantity      IS TABLE OF xxpo_rcv_and_rtn_txns.quantity                   %TYPE INDEX BY BINARY_INTEGER;
  -- ���Z����
  TYPE reg_conversion_factor IS TABLE OF xxpo_rcv_and_rtn_txns.conversion_factor          %TYPE INDEX BY BINARY_INTEGER;
  -- �����R�[�h
  TYPE reg_department_code   IS TABLE OF xxpo_rcv_and_rtn_txns.department_code            %TYPE INDEX BY BINARY_INTEGER;
  -- HEADER_INTERFACE_ID
  TYPE reg_head_if_id        IS TABLE OF rcv_headers_interface.header_interface_id                  %TYPE INDEX BY BINARY_INTEGER;
  -- INTERFACE_TRANSACTION_ID
  TYPE reg_if_tran_id        IS TABLE OF rcv_transactions_interface.interface_transaction_id        %TYPE INDEX BY BINARY_INTEGER;
  -- TRANSACTION_INTERFACE_ID
  TYPE reg_tran_if_id        IS TABLE OF mtl_transaction_lots_interface.transaction_interface_id    %TYPE INDEX BY BINARY_INTEGER;
  -- TRANSACTION_QUANTITY
  TYPE reg_trans_qty         IS TABLE OF mtl_transaction_lots_interface.transaction_quantity                  %TYPE INDEX BY BINARY_INTEGER;
  -- PRODUCT_TRANSACTION_ID
  TYPE reg_trans_id          IS TABLE OF mtl_transaction_lots_interface.product_transaction_id                  %TYPE INDEX BY BINARY_INTEGER;
  -- TO_ORGANIZATION_ID
  TYPE reg_organization_id   IS TABLE OF rcv_transactions_interface.to_organization_id              %TYPE INDEX BY BINARY_INTEGER;
  -- SUBINVENTORY
  TYPE reg_subinventory      IS TABLE OF rcv_transactions_interface.subinventory                    %TYPE INDEX BY BINARY_INTEGER;
  -- LOCATOR_ID
  TYPE reg_locator_id        IS TABLE OF rcv_transactions_interface.locator_id                      %TYPE INDEX BY BINARY_INTEGER;
-- 2008/05/21 v1.2 Add
  TYPE reg_opm_item_id       IS TABLE OF xxpo_rcv_and_rtn_txns.item_id                              %TYPE INDEX BY BINARY_INTEGER;
-- 2008/05/21 v1.2 Add
-- 2008/06/26 v1.4 Add
  -- ����ԕi���הԍ�
  TYPE reg_rtn_line_num      IS TABLE OF xxpo_rcv_and_rtn_txns.rcv_rtn_line_number                  %TYPE INDEX BY BINARY_INTEGER;
-- 2008/06/26 v1.4 Add
--
  -- ***************************************
  -- ***      ���ڊi�[�e�[�u���^��`     ***
  -- ***************************************
--
  gt_other_tbl                 other_tbl;    -- �e�}�X�^�֓o�^����f�[�^
  gt_master_tbl                masters_tbl;  -- �e�}�X�^�֓o�^����f�[�^
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_inv_ship_rsn             VARCHAR2(100);              -- �����݌ɏo�Ɏ��R
  gv_close_date               VARCHAR2(6);                -- CLOSE�N����
  gn_group_id                 rcv_headers_interface.group_id%TYPE;              -- �O���[�vID
  gn_proc_flg                 NUMBER;
  gn_org_txns_cnt             NUMBER;
  gn_proper_error             NUMBER;
  gn_lot_count                NUMBER;
  gn_head_count               NUMBER;
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
  gv_user_name                fnd_user.user_name%TYPE;    -- ���[�U��
--
  -- ���ڃe�[�u���^��`
  gt_org_txns_id       reg_txns_id;           -- ���ID(�폜�p)
  gt_txns_id           reg_txns_id;           -- ���ID
  gt_src_doc_num       reg_src_doc_num;       -- �������ԍ�
  gt_vendor_code       reg_vendor_code;       -- �����R�[�h
  gt_promised_date     reg_promised_date;     -- �[����
  gt_location_code     reg_location_code;     -- �[����R�[�h
  gt_src_doc_line_num  reg_src_doc_line_num;  -- ���������הԍ�
  gt_item_code         reg_item_code;         -- �i�ڃR�[�h
  gt_lot_number        reg_lot_number;        -- ���b�gNo
  gt_rcv_quantity_uom  reg_rcv_quantity_uom;  -- �P�ʃR�[�h
  gt_po_description    reg_po_description;    -- ���דE�v
  gt_rcv_date          reg_rcv_date;          -- �����
  gt_rcv_quantity      reg_rcv_quantity;      -- �������
  gt_po_header_id      reg_po_header_id;      -- �����w�b�_ID
  gt_attribute6        reg_attribute6;        -- �����敪
  gt_vendor_id         reg_vendor_id;         -- �����ID
  gt_po_line_id        reg_po_line_id;        -- ��������ID
  gt_line_num          reg_line_num;          -- ���הԍ�
  gt_item_id           reg_item_id;           -- �i��ID
  gt_unit_price        reg_unit_price;        -- �P��
  gt_lot_no            reg_lot_no;            -- ���b�gNo
  gt_unit_code         reg_unit_code;         -- �P��
  gt_attribute10       reg_attribute10;       -- �����P��
  gt_lot_id            reg_lot_id;            -- ���b�gID
  gt_rtn_quantity      reg_rtn_quantity;      -- ����
  gt_conversion_factor reg_conversion_factor; -- ���Z����
  gt_department_code   reg_department_code;   -- �����R�[�h
--
  gt_head_if_id        reg_head_if_id;        -- HEADER_INTERFACE_ID
  gt_if_tran_id        reg_if_tran_id;        -- INTERFACE_TRANSACTION_ID
  gt_tran_if_id        reg_tran_if_id;        -- TRANSACTION_INTERFACE_ID
  gt_calc_quantity     reg_rcv_quantity;      -- �v�Z����
  gt_trans_qty         reg_trans_qty;         -- TRANSACTION_QUANTITY
  gt_trans_id          reg_trans_id;          -- PRODUCT_TRANSACTION_ID
  gt_trans_lot         reg_lot_number;        -- ���b�gNo
--
  gt_keep_header_id    reg_po_header_id;      -- �����w�b�_ID
--
  gt_organization_id   reg_organization_id;   -- TO_ORGANIZATION_ID
  gt_subinventory      reg_subinventory;      -- SUBINVENTORY
  gt_locator_id        reg_locator_id;        -- LOCATOR_ID
--
-- 2008/05/21 v1.2 Add
  gt_opm_item_id       reg_opm_item_id;        -- OPM�i��ID
-- 2008/05/21 v1.2 Add
-- 2008/06/26 v1.4 Add
  gt_rtn_line_num      reg_rtn_line_num;       -- ����ԕi���הԍ�
-- 2008/06/26 v1.4 Add
--
  /**********************************************************************************
   * Procedure Name   : keep_po_head_id
   * Description      : �����w�b�_ID���d�������ɕێ�����
   ***********************************************************************************/
  PROCEDURE keep_po_head_id(
    in_head_id      IN            po_headers_all.po_header_id%TYPE,
    ov_errbuf          OUT NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'keep_po_head_id';       -- �v���O������
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
    ln_qty         NUMBER;
    ln_flg         NUMBER;
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
    -- ���͂���
    IF (in_head_id IS NOT NULL) THEN
--
      IF (gn_head_count = 0) THEN
        gt_keep_header_id(gn_head_count) := in_head_id;
        gn_head_count := gn_head_count + 1;
--
      ELSE
        ln_flg := 0;
--
        <<check_loop>>
        FOR i IN 0..gn_head_count-1 LOOP
--
          -- �����l�����݂���
          IF (gt_keep_header_id(i) = in_head_id) THEN
            ln_flg := 1;
            EXIT check_loop;
          END IF;
--
        END LOOP check_loop;
--
        -- �����l�����݂��Ȃ�
        IF (ln_flg = 0) THEN
          gt_keep_header_id(gn_head_count) := in_head_id;
          gn_head_count := gn_head_count + 1;
        END IF;
      END IF;
    END IF;
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
  END keep_po_head_id;
--
  /***********************************************************************************
   * Procedure Name   : get_location
   * Description      : �q�ɁA�g�D�A��Ђ̎擾
   ***********************************************************************************/
  PROCEDURE get_location(
    ir_mst_rec      IN OUT NOCOPY masters_rec,  -- �Ώۃ��R�[�h
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_location'; -- �v���O������
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
    SELECT xilv.whse_code                         -- �q��
          ,xilv.orgn_code                         -- �g�D
          ,som.co_code                            -- ���
    INTO   ir_mst_rec.from_whse_code
          ,ir_mst_rec.orgn_code
          ,ir_mst_rec.co_code
    FROM   xxcmn_item_locations_v xilv            -- OPM�ۊǏꏊ���VIEW
          ,sy_orgn_mst_b som                      -- OPM�v�����g�}�X�^
    WHERE  xilv.orgn_code = som.orgn_code
    AND    xilv.segment1  = ir_mst_rec.vendor_stock_whse
    AND    ROWNUM         = 1;
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
  END get_location;
--
  /***********************************************************************************
   * Procedure Name   : get_lot_mst
   * Description      : OPM���b�g�}�X�^�̎擾
   ***********************************************************************************/
  PROCEDURE get_lot_mst(
    ir_mst_rec      IN OUT NOCOPY masters_rec,  -- �Ώۃ��R�[�h
    ir_lot_rec         OUT NOCOPY ic_lots_mst%ROWTYPE,
    ir_lot_cpg_rec     OUT NOCOPY ic_lots_cpg%ROWTYPE,
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lot_mst'; -- �v���O������
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
    BEGIN
      SELECT ilm.item_id
            ,ilm.lot_id
            ,ilm.lot_no
            ,ilm.sublot_no
            ,ilm.lot_desc
            ,ilm.qc_grade
            ,ilm.expaction_code
            ,ilm.expaction_date
            ,ilm.lot_created
            ,ilm.expire_date
            ,ilm.retest_date
            ,ilm.strength
            ,ilm.inactive_ind
            ,ilm.origination_type
            ,ilm.shipvend_id
            ,ilm.vendor_lot_no
            ,ilm.creation_date
            ,ilm.last_update_date
            ,ilm.created_by
            ,ilm.last_updated_by
            ,ilm.trans_cnt
            ,ilm.delete_mark
            ,ilm.text_code
            ,ilm.last_update_login
            ,ilm.program_application_id
            ,ilm.program_id
            ,ilm.program_update_date
            ,ilm.request_id
            ,ilm.attribute1
            ,ilm.attribute2
            ,ilm.attribute3
            ,ilm.attribute4
            ,ilm.attribute5
            ,ilm.attribute6
            ,ilm.attribute7
            ,ilm.attribute8
            ,ilm.attribute9
            ,ilm.attribute10
            ,ilm.attribute11
            ,ilm.attribute12
            ,ilm.attribute13
            ,ilm.attribute14
            ,ilm.attribute15
            ,ilm.attribute16
            ,ilm.attribute17
            ,ilm.attribute18
            ,ilm.attribute19
            ,ilm.attribute20
            ,ilm.attribute21
            ,ilm.attribute22
            ,ilm.attribute23
            ,ilm.attribute24
            ,ilm.attribute25
            ,ilm.attribute26
            ,ilm.attribute27
            ,ilm.attribute28
            ,ilm.attribute29
            ,ilm.attribute30
            ,ilm.attribute_category
            ,ilm.odm_lot_number
      INTO   ir_lot_rec.item_id
            ,ir_lot_rec.lot_id
            ,ir_lot_rec.lot_no
            ,ir_lot_rec.sublot_no
            ,ir_lot_rec.lot_desc
            ,ir_lot_rec.qc_grade
            ,ir_lot_rec.expaction_code
            ,ir_lot_rec.expaction_date
            ,ir_lot_rec.lot_created
            ,ir_lot_rec.expire_date
            ,ir_lot_rec.retest_date
            ,ir_lot_rec.strength
            ,ir_lot_rec.inactive_ind
            ,ir_lot_rec.origination_type
            ,ir_lot_rec.shipvend_id
            ,ir_lot_rec.vendor_lot_no
            ,ir_lot_rec.creation_date
            ,ir_lot_rec.last_update_date
            ,ir_lot_rec.created_by
            ,ir_lot_rec.last_updated_by
            ,ir_lot_rec.trans_cnt
            ,ir_lot_rec.delete_mark
            ,ir_lot_rec.text_code
            ,ir_lot_rec.last_update_login
            ,ir_lot_rec.program_application_id
            ,ir_lot_rec.program_id
            ,ir_lot_rec.program_update_date
            ,ir_lot_rec.request_id
            ,ir_lot_rec.attribute1
            ,ir_lot_rec.attribute2
            ,ir_lot_rec.attribute3
            ,ir_lot_rec.attribute4
            ,ir_lot_rec.attribute5
            ,ir_lot_rec.attribute6
            ,ir_lot_rec.attribute7
            ,ir_lot_rec.attribute8
            ,ir_lot_rec.attribute9
            ,ir_lot_rec.attribute10
            ,ir_lot_rec.attribute11
            ,ir_lot_rec.attribute12
            ,ir_lot_rec.attribute13
            ,ir_lot_rec.attribute14
            ,ir_lot_rec.attribute15
            ,ir_lot_rec.attribute16
            ,ir_lot_rec.attribute17
            ,ir_lot_rec.attribute18
            ,ir_lot_rec.attribute19
            ,ir_lot_rec.attribute20
            ,ir_lot_rec.attribute21
            ,ir_lot_rec.attribute22
            ,ir_lot_rec.attribute23
            ,ir_lot_rec.attribute24
            ,ir_lot_rec.attribute25
            ,ir_lot_rec.attribute26
            ,ir_lot_rec.attribute27
            ,ir_lot_rec.attribute28
            ,ir_lot_rec.attribute29
            ,ir_lot_rec.attribute30
            ,ir_lot_rec.attribute_category
            ,ir_lot_rec.odm_lot_number
      FROM   ic_lots_mst ilm
      WHERE  ilm.lot_id        = ir_mst_rec.lot_id
      AND    ilm.item_id       = ir_mst_rec.item_idv
      AND    ROWNUM            = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_31g_12);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    BEGIN
      SELECT ilc.item_id
            ,ilc.lot_id
            ,ilc.ic_matr_date
            ,ilc.ic_hold_date
            ,ilc.created_by
            ,ilc.creation_date
            ,ilc.last_update_date
            ,ilc.last_updated_by
            ,ilc.last_update_login
      INTO   ir_lot_cpg_rec.item_id
            ,ir_lot_cpg_rec.lot_id
            ,ir_lot_cpg_rec.ic_matr_date
            ,ir_lot_cpg_rec.ic_hold_date
            ,ir_lot_cpg_rec.created_by
            ,ir_lot_cpg_rec.creation_date
            ,ir_lot_cpg_rec.last_update_date
            ,ir_lot_cpg_rec.last_updated_by
            ,ir_lot_cpg_rec.last_update_login
      FROM   ic_lots_cpg ilc
      WHERE  ilc.lot_id  = ir_lot_rec.lot_id
      AND    ilc.item_id = ir_lot_rec.item_id
      AND    ROWNUM      = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_31g_12);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
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
  END get_lot_mst;
--
  /**********************************************************************************
   * Procedure Name   : init_proc
   * Description      : �O����(F-1)
   ***********************************************************************************/
  PROCEDURE init_proc(
    ov_errbuf           OUT NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'init_proc';       -- �v���O������
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
    lb_retcd  BOOLEAN;
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
    -- ������уC���^�[�t�F�[�X(�A�h�I��)�̃��b�N
    lb_retcd := xxcmn_common_pkg.get_tbl_lock(gv_app_name, gv_tbl_name);
--
    IF (NOT lb_retcd) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_31g_02);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �����݌ɏo�Ɏ��R
    gv_inv_ship_rsn := FND_PROFILE.VALUE('XXPO_CTPTY_INV_SHIP_RSN');
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_inv_ship_rsn IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_31g_09);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
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
--
    gv_user_name              := FND_GLOBAL.USER_NAME;         -- ���[�U��
--
    gv_close_date             := xxcmn_common_pkg.get_opminv_close_period;  -- CLOSE�N����
--
    -- GMI�nAPI�ďo�̃Z�b�g�A�b�v
    lb_retcd  :=  GMIGUTL.SETUP(FND_GLOBAL.USER_NAME);
    IF NOT (lb_retcd) THEN
      RAISE global_api_expt;
    END IF;
--
    -- �O���[�vID�擾
    SELECT rcv_interface_groups_s.NEXTVAL
    INTO   gn_group_id
    FROM   DUAL;
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
  END init_proc;
--
  /**********************************************************************************
   * Procedure Name   : other_data_get
   * Description      : �����ΏۊO������я��擾(F-2)
   ***********************************************************************************/
  PROCEDURE other_data_get(
    ov_errbuf           OUT NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'other_data_get';       -- �v���O������
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
    oth_rec           other_rec;
    ln_cnt            NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR other_data_cur
    IS
      SELECT  xrti.source_document_number
             ,xrti.source_document_line_num
             ,xrti.item_code
             ,xrti.rcv_date
             ,xrti.txns_id
      FROM    xxpo_rcv_txns_interface xrti
      WHERE  TO_CHAR(xrti.rcv_date,'YYYYMM') <= gv_close_date;
--
    -- *** ���[�J���E���R�[�h ***
    lr_other_data_rec other_data_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    ln_cnt := 0;
--
    OPEN other_data_cur;
--
    <<other_data_loop>>
    LOOP
      FETCH other_data_cur INTO lr_other_data_rec;
      EXIT WHEN other_data_cur%NOTFOUND;
--
      oth_rec.src_doc_num      := lr_other_data_rec.source_document_number;
      oth_rec.src_doc_line_num := lr_other_data_rec.source_document_line_num;
      oth_rec.item_code        := lr_other_data_rec.item_code;
      oth_rec.rcv_date         := lr_other_data_rec.rcv_date;
      oth_rec.txns_id          := lr_other_data_rec.txns_id;
--
      gt_other_tbl(ln_cnt)     := oth_rec;
--
      ln_cnt := ln_cnt + 1;
--
      gt_org_txns_id(gn_org_txns_cnt) := oth_rec.txns_id;
      gn_org_txns_cnt := gn_org_txns_cnt + 1;
--
    END LOOP other_data_loop;
--
    CLOSE other_data_cur;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\�����J���Ă����
      IF (other_data_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE other_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\�����J���Ă����
      IF (other_data_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE other_data_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\�����J���Ă����
      IF (other_data_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE other_data_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END other_data_get;
--
  /**********************************************************************************
   * Procedure Name   : disp_other_data
   * Description      : ����ΏۊO���o��(F-3)
   ***********************************************************************************/
  PROCEDURE disp_other_data(
    ov_errbuf           OUT NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'disp_other_data';       -- �v���O������
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
    oth_rec           other_rec;
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
    <<other_disp_loop>>
    FOR i IN 0..gt_other_tbl.COUNT-1 LOOP
      oth_rec := gt_other_tbl(i);
--
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_31g_08,
                                            gv_tkn_h_no,
                                            oth_rec.src_doc_num,
                                            gv_tkn_m_no,
                                            oth_rec.src_doc_line_num,
                                            gv_tkn_date,
                                            TO_CHAR(oth_rec.rcv_date,'YYYY/MM/DD'),
                                            gv_tkn_item_no,
                                            oth_rec.item_code
                                            );
--
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END LOOP other_disp_loop;
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
  END disp_other_data;
--
  /**********************************************************************************
   * Procedure Name   : master_data_get
   * Description      : �����Ώۂ̎�����擾(F-4)
   ***********************************************************************************/
  PROCEDURE master_data_get(
    ov_errbuf           OUT NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'master_data_get';       -- �v���O������
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
    ln_po_header_id   po_headers_all.po_header_id%TYPE;
    ln_po_line_id     po_lines_all.po_line_id%TYPE;
    ln_lot_id         ic_lots_mst.lot_id%TYPE;
--
    mst_rec           masters_rec;
    ln_cnt            NUMBER;
    ln_num            NUMBER;
    ln_qty            NUMBER;
--
    lv_tbl_name       VARCHAR2(100);
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR mst_data_cur
    IS
      SELECT xrti.txns_id                  -- ���ID
            ,xrti.source_document_number   -- �������ԍ�
            ,xrti.vendor_code              -- �����R�[�h
            ,xrti.vendor_name              -- ����於
            ,xrti.promised_date            -- �[����
            ,xrti.location_code            -- �[����R�[�h
            ,xrti.location_name            -- �[���於
            ,xrti.source_document_line_num -- ���������הԍ�
            ,xrti.item_code                -- �i�ڃR�[�h
            ,xrti.item_name                -- �i�ږ���
            ,xrti.lot_number               -- ���b�gNo
            ,xrti.producted_date           -- ������
            ,xrti.koyu_code                -- �ŗL�L��
            ,xrti.quantity                 -- �w������
            ,xrti.po_line_description      -- ���דE�v
            ,xrti.rcv_date                 -- �����
            ,xrti.rcv_quantity             -- �������
            ,xrti.rcv_quantity_uom         -- �P�ʃR�[�h
            ,xrti.rcv_line_description     -- ������דE�v
            ,xxpo.po_header_id             -- �����w�b�_ID
            ,xxpo.h_segment1               -- �����ԍ�
            ,xxpo.h_attribute11            -- �����敪
            ,xxpo.vendor_id                -- �����ID
            ,xxpo.h_attribute5             -- �[����R�[�h
            ,xxpo.h_attribute6             -- �����敪
            ,xxpo.h_attribute10            -- �����R�[�h
            ,xxpo.po_line_id               -- ��������ID
            ,xxpo.line_num                 -- ���הԍ�
            ,xxpo.item_id                  -- �i��ID
            ,xxpo.unit_price               -- �P��
            ,xxpo.l_attribute1             -- ���b�gNo
            ,xxpo.unit_meas_lookup_code    -- �P��
            ,xxpo.l_attribute10            -- �����P��
            ,xivv.lot_id                   -- ���b�gID
            ,xivv.attribute4               -- �[����(����)
            ,xivv.attribute5               -- �[����(�ŏI)
            ,xivv.opm_item_id              -- OPM�i��ID
            ,xivv.num_of_cases             -- �P�[�X����
            ,xivv.lot_ctl                  -- ���b�g
            ,xivv.item_no                  -- �i�ڃR�[�h
            ,xivv.item_idv                 -- �i��ID
            ,xsv.vendor_stock_whse         -- �����݌ɓ��ɐ�
            ,xicv.prod_class_code          -- ���i�敪
            ,xvv.segment1                  -- �d����ԍ�
      FROM   xxpo_rcv_txns_interface xrti                 -- �������IF(�A�h�I��)
            ,xxcmn_vendors_v xvv                          -- �d������VIEW
            ,xxcmn_vendor_sites_v xsv                     -- �d����T�C�g���VIEW
            ,xxcmn_item_categories3_v xicv                -- OPM�i�ڃJ�e�S���������VIEW3
            ,(SELECT pha.segment1 as h_segment1        -- �����ԍ�
                    ,pha.po_header_id                  -- �����w�b�_ID
                    ,pha.vendor_id                     -- �d����ID
                    ,pha.attribute1  as h_attribute1   -- �X�e�[�^�X
                    ,pha.attribute4  as h_attribute4   -- �[����
                    ,pha.attribute5  as h_attribute5   -- �[����R�[�h
                    ,pha.attribute6  as h_attribute6   -- �����敪
                    ,pha.attribute10 as h_attribute10  -- �����R�[�h
                    ,pha.attribute11 as h_attribute11  -- �����敪
                    ,pla.po_line_id                    -- ��������ID
                    ,pla.line_num                      -- ���הԍ�
                    ,pla.item_id                       -- �i��ID
                    ,pla.unit_price                    -- �P��
                    ,pla.quantity                      -- ����
                    ,pla.unit_meas_lookup_code         -- �P��
                    ,pla.attribute1  as l_attribute1   -- ���b�gNO
                    ,pla.attribute2  as l_attribute2   -- �H��R�[�h
                    ,pla.attribute4  as l_attribute4   -- �݌ɓ���
                    ,pla.attribute7  as l_attribute7   -- �������
                    ,pla.attribute10 as l_attribute10  -- �����P��
                    ,pla.attribute11 as l_attribute11  -- ��������
             FROM    po_headers_all pha                   -- �����w�b�_
                    ,po_lines_all pla                     -- ��������
             WHERE   pha.po_header_id = pla.po_header_id
             AND     pha.attribute1 >= gv_add_status_zmi             -- �����쐬��:20
             AND     pha.attribute1 < gv_add_status_qty_zmi) xxpo    -- ���z�m���:35
            ,(SELECT xiv.item_no                       -- �i�ڃR�[�h
                    ,xiv.num_of_cases                  -- �P�[�X����
                    ,xiv.lot_ctl                       -- ���b�g
                    ,xiv.item_id as opm_item_id        -- OPM�i��ID
                    ,ilm.lot_no                        -- ���b�gNo
                    ,ilm.lot_id                        -- ���b�gID
                    ,ilm.item_id as item_idv           -- �i��ID
                    ,ilm.attribute4                    -- �[����(����)
                    ,ilm.attribute5                    -- �[����(�ŏI)
              FROM   xxcmn_item_mst_v xiv                 -- OPM�i�ڏ��VIEW
                    ,ic_lots_mst ilm                      -- OPM���b�g�}�X�^
              WHERE xiv.item_id = ilm.item_id(+)) xivv
      WHERE  xrti.source_document_number   = xxpo.h_segment1(+)
      AND    xrti.source_document_line_num = xxpo.line_num(+)
      AND    xrti.vendor_code              = xvv.segment1(+)
      AND    xrti.item_code                = xivv.item_no(+)
      AND    xrti.lot_number               = xivv.lot_no(+)
      AND    xivv.opm_item_id              = xicv.item_id(+)
      AND    xxpo.vendor_id                = xsv.vendor_id(+)
      AND    xxpo.l_attribute2             = xsv.vendor_site_code(+)
      AND    TO_CHAR(xrti.rcv_date,'YYYYMM') > gv_close_date
      ORDER BY xrti.source_document_number,xrti.source_document_line_num;
--
    -- *** ���[�J���E���R�[�h ***
    lr_mst_data_rec mst_data_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    ln_cnt := 0;
--
    OPEN mst_data_cur;
--
    <<mst_data_loop>>
    LOOP
      FETCH mst_data_cur INTO lr_mst_data_rec;
      EXIT WHEN mst_data_cur%NOTFOUND;
--
      -- ���Ԃ̎擾
      SELECT xxpo_rcv_and_rtn_txns_s1.NEXTVAL
      INTO   ln_num
      FROM   DUAL;
--
      mst_rec.txns_id            := ln_num;
      mst_rec.src_doc_num        := lr_mst_data_rec.source_document_number;
      mst_rec.vendor_code        := lr_mst_data_rec.vendor_code;
      mst_rec.vendor_name        := lr_mst_data_rec.vendor_name;
      mst_rec.promised_date      := lr_mst_data_rec.promised_date;
      mst_rec.location_code      := lr_mst_data_rec.location_code;
      mst_rec.location_name      := lr_mst_data_rec.location_name;
      mst_rec.src_doc_line_num   := lr_mst_data_rec.source_document_line_num;
      mst_rec.item_code          := lr_mst_data_rec.item_code;
      mst_rec.item_name          := lr_mst_data_rec.item_name;
      mst_rec.lot_number         := lr_mst_data_rec.lot_number;
      mst_rec.producted_date     := lr_mst_data_rec.producted_date;
      mst_rec.koyu_code          := lr_mst_data_rec.koyu_code;
      mst_rec.quantity           := lr_mst_data_rec.quantity;
      mst_rec.rcv_quantity_uom   := lr_mst_data_rec.rcv_quantity_uom;
      mst_rec.po_description     := lr_mst_data_rec.po_line_description;
      mst_rec.rcv_date           := lr_mst_data_rec.rcv_date;
      mst_rec.rcv_quantity       := lr_mst_data_rec.rcv_quantity;
      mst_rec.rcv_description    := lr_mst_data_rec.rcv_line_description;
      mst_rec.po_header_id       := lr_mst_data_rec.po_header_id;
      mst_rec.segment1           := lr_mst_data_rec.h_segment1;
      mst_rec.attribute6         := lr_mst_data_rec.h_attribute6;
      mst_rec.attribute11        := lr_mst_data_rec.h_attribute11;
      mst_rec.department_code    := lr_mst_data_rec.h_attribute10;
      mst_rec.vendor_id          := lr_mst_data_rec.vendor_id;
      mst_rec.delivery_code      := lr_mst_data_rec.h_attribute5;
      mst_rec.po_line_id         := lr_mst_data_rec.po_line_id;
      mst_rec.line_num           := lr_mst_data_rec.line_num;
      mst_rec.item_id            := lr_mst_data_rec.item_id;
      mst_rec.unit_price         := lr_mst_data_rec.unit_price;
      mst_rec.lot_no             := lr_mst_data_rec.l_attribute1;
      mst_rec.unit_code          := lr_mst_data_rec.unit_meas_lookup_code;
      mst_rec.attribute10        := lr_mst_data_rec.l_attribute10;
      mst_rec.lot_id             := lr_mst_data_rec.lot_id;
      mst_rec.attribute4         := lr_mst_data_rec.attribute4;
      mst_rec.attribute5         := lr_mst_data_rec.attribute5;
      mst_rec.opm_item_id        := lr_mst_data_rec.opm_item_id;
      mst_rec.num_of_cases       := lr_mst_data_rec.num_of_cases;
      mst_rec.lot_ctl            := lr_mst_data_rec.lot_ctl;
      mst_rec.item_no            := lr_mst_data_rec.item_no;
      mst_rec.item_idv           := lr_mst_data_rec.item_idv;
      mst_rec.vendor_stock_whse  := lr_mst_data_rec.vendor_stock_whse;
      mst_rec.prod_class_code    := lr_mst_data_rec.prod_class_code;
      mst_rec.vendor_no          := lr_mst_data_rec.segment1;
--
      mst_rec.def4_date          := FND_DATE.STRING_TO_DATE(mst_rec.attribute4,'YYYY/MM/DD');
      mst_rec.def5_date          := FND_DATE.STRING_TO_DATE(mst_rec.attribute5,'YYYY/MM/DD');
--
      -- ���ڂ̐ݒ�
      gt_txns_id(ln_cnt)           := mst_rec.txns_id;
      gt_src_doc_num(ln_cnt)       := mst_rec.src_doc_num;
      gt_vendor_code(ln_cnt)       := mst_rec.vendor_code;
      gt_promised_date(ln_cnt)     := mst_rec.promised_date;
      gt_location_code(ln_cnt)     := mst_rec.location_code;
      gt_src_doc_line_num(ln_cnt)  := mst_rec.src_doc_line_num;
      gt_item_code(ln_cnt)         := mst_rec.item_code;
      gt_lot_number(ln_cnt)        := mst_rec.lot_number;
-- 2008/05/23 v1.3 Changed
--      gt_rcv_quantity_uom(ln_cnt)  := mst_rec.rcv_quantity_uom;
      gt_rcv_quantity_uom(ln_cnt)  := mst_rec.unit_code;
-- 2008/05/23 v1.3 Changed
      gt_po_description(ln_cnt)    := mst_rec.po_description;
      gt_rcv_date(ln_cnt)          := mst_rec.rcv_date;
      gt_rcv_quantity(ln_cnt)      := mst_rec.rcv_quantity;
      gt_po_header_id(ln_cnt)      := mst_rec.po_header_id;
      gt_attribute6(ln_cnt)        := mst_rec.attribute6;
      gt_vendor_id(ln_cnt)         := mst_rec.vendor_id;
      gt_po_line_id(ln_cnt)        := mst_rec.po_line_id;
      gt_line_num(ln_cnt)          := mst_rec.line_num;
      gt_item_id(ln_cnt)           := mst_rec.item_id;
      gt_unit_price(ln_cnt)        := mst_rec.unit_price;
      gt_lot_no(ln_cnt)            := mst_rec.lot_no;
      gt_unit_code(ln_cnt)         := mst_rec.unit_code;
      gt_attribute10(ln_cnt)       := mst_rec.attribute10;
      gt_lot_id(ln_cnt)            := mst_rec.lot_id;
      gt_department_code(ln_cnt)   := mst_rec.department_code;
-- 2008/05/21 v1.2 Add
      gt_opm_item_id(ln_cnt)       := mst_rec.item_idv;
-- 2008/05/21 v1.2 Add
--
      -- �����w�b�_�ێ�
      keep_po_head_id(
        mst_rec.po_header_id,
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      gt_conversion_factor(ln_cnt) := 1;
      ln_qty := mst_rec.rcv_quantity;
--
      -- �h�����N���i(���o�Ɋ��Z�P�ʂ���) �̏ꍇ
      IF ((mst_rec.prod_class_code = gv_prod_class_code) 
       AND (mst_rec.unit_code <> mst_rec.attribute10)) THEN
        ln_qty := ln_qty * NVL(mst_rec.num_of_cases,1);
        gt_conversion_factor(ln_cnt) := NVL(mst_rec.num_of_cases,1);
      END IF;
      gt_calc_quantity(ln_cnt) := ln_qty;
      gt_rtn_quantity(ln_cnt) := ln_qty;
--
      IF (mst_rec.delivery_code IS NOT NULL) THEN
        BEGIN
          SELECT mil.organization_id
                ,mil.subinventory_code
                ,mil.inventory_location_id
          INTO   mst_rec.organization_id
                ,mst_rec.subinventory_code
                ,mst_rec.inventory_location_id
          FROM  mtl_item_locations mil
          WHERE mil.segment1 = mst_rec.delivery_code;           -- �[����R�[�h
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            mst_rec.organization_id       := NULL;
            mst_rec.subinventory_code     := NULL;
            mst_rec.inventory_location_id := NULL;
--
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
--
      ELSE
        mst_rec.organization_id       := NULL;
        mst_rec.subinventory_code     := NULL;
        mst_rec.inventory_location_id := NULL;
      END IF;
--
      gt_master_tbl(ln_cnt) := mst_rec;
--
      -- �����w�b�_�̃��b�N
      IF (mst_rec.po_header_id IS NOT NULL) THEN
--
        BEGIN
          SELECT pha.po_header_id
          INTO   ln_po_header_id
          FROM   po_headers_all pha
          WHERE  pha.po_header_id = mst_rec.po_header_id
          FOR UPDATE OF pha.po_header_id NOWAIT;
--
        EXCEPTION
          WHEN lock_expt THEN
            lv_tbl_name := gv_tbl_name_po_head;
            RAISE master_data_get_expt;
--
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
      END IF;
--
      -- �������ׂ̃��b�N
      IF (mst_rec.po_line_id IS NOT NULL) THEN
--
        BEGIN
          SELECT pla.po_line_id
          INTO   ln_po_line_id
          FROM   po_lines_all pla
          WHERE  pla.po_line_id = mst_rec.po_line_id
          FOR UPDATE OF pla.po_line_id NOWAIT;
--
        EXCEPTION
          WHEN lock_expt THEN
            lv_tbl_name := gv_tbl_name_po_line;
            RAISE master_data_get_expt;
--
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
      END IF;
--
      -- OPM���b�g�}�X�^�̃��b�N
      IF ((mst_rec.lot_id IS NOT NULL)
        AND (mst_rec.lot_no IS NOT NULL)
        AND (mst_rec.item_idv IS NOT NULL)) THEN
--
        BEGIN
          SELECT ilm.lot_id
          INTO   ln_lot_id
          FROM   ic_lots_mst ilm
          WHERE  ilm.item_id = mst_rec.item_idv
          AND    ilm.lot_id  = mst_rec.lot_id
          AND    ilm.lot_no  = mst_rec.lot_no
          FOR UPDATE OF ilm.lot_id NOWAIT;
--
        EXCEPTION
          WHEN lock_expt THEN
            lv_tbl_name := gv_tbl_name_lot_mast;
            RAISE master_data_get_expt;
--
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
      END IF;
--
      SELECT rcv_headers_interface_s.NEXTVAL
      INTO   ln_num
      FROM   DUAL;
      gt_head_if_id(ln_cnt) := ln_num;
--
      SELECT rcv_transactions_interface_s.NEXTVAL
      INTO   ln_num
      FROM   DUAL;
      gt_if_tran_id(ln_cnt) := ln_num;
--
      -- ���b�g�Ǘ��i
      IF (mst_rec.lot_ctl = gn_lot_ctl_on) THEN
        gt_trans_id(gn_lot_count)  := gt_if_tran_id(ln_cnt);
        gt_trans_qty(gn_lot_count) := ABS(gt_calc_quantity(ln_cnt));
        gt_trans_lot(gn_lot_count) := gt_lot_number(ln_cnt);
        gn_lot_count := gn_lot_count + 1;
      END IF;
--
      gt_organization_id(ln_cnt) := mst_rec.organization_id;
      gt_subinventory(ln_cnt)    := mst_rec.subinventory_code;
      gt_locator_id(ln_cnt)      := mst_rec.inventory_location_id;
--
      ln_cnt := ln_cnt + 1;
--
      gt_org_txns_id(gn_org_txns_cnt) := lr_mst_data_rec.txns_id;
      gn_org_txns_cnt := gn_org_txns_cnt + 1;
--
    END LOOP mst_data_loop;
--
    CLOSE mst_data_cur;
--
  EXCEPTION
    WHEN master_data_get_expt THEN
      -- �J�[�\�����J���Ă����
      IF (mst_data_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE mst_data_cur;
      END IF;
      ov_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_31g_01,
                                            gv_tkn_table,
                                            lv_tbl_name);
--
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||ov_errmsg,1,5000);
      ov_retcode := gv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\�����J���Ă����
      IF (mst_data_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE mst_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\�����J���Ă����
      IF (mst_data_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE mst_data_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\�����J���Ă����
      IF (mst_data_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE mst_data_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END master_data_get;
--
  /**********************************************************************************
   * Procedure Name   : proper_check
   * Description      : �Ó����`�F�b�N(F-5)
   ***********************************************************************************/
  PROCEDURE proper_check(
    ov_errbuf           OUT NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'proper_check';       -- �v���O������
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
    lr_mst_rec        masters_rec;
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
    <<chk_loop>>
    FOR i IN 0..gt_master_tbl.COUNT-1 LOOP
--
      lv_retcode := gv_status_normal;
      lr_mst_rec := gt_master_tbl(i);
--
      -- ������уC���^�t�F�[�X(�A�h�I��)�̌������ԍ��A���������הԍ������Ƃɔ��������擾�ł���
      IF (lr_mst_rec.po_header_id IS NULL) THEN
--
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_31g_05,
                                              gv_tkn_h_no,
                                              lr_mst_rec.src_doc_num,
                                              gv_tkn_m_no,
                                              lr_mst_rec.src_doc_line_num,
                                              gv_tkn_date,
                                              TO_CHAR(lr_mst_rec.rcv_date,'YYYY/MM/DD'),
                                              gv_tkn_item_no,
                                              lr_mst_rec.item_code);
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        lv_retcode := gv_status_warn;
        ov_retcode := gv_status_warn;
      END IF;
--
      -- ������уC���^�t�F�[�X(�A�h�I��)�̎����R�[�h���Y�������̎����Ɠ��ꂩ�B
      IF ((lv_retcode = gv_status_normal)
        AND (lr_mst_rec.vendor_code <> NVL(lr_mst_rec.vendor_no,gv_one_space))) THEN
--
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_31g_06,
                                              gv_tkn_h_no,
                                              lr_mst_rec.src_doc_num,
                                              gv_tkn_m_no,
                                              lr_mst_rec.src_doc_line_num,
                                              gv_tkn_name,
                                              gv_tkn_name_vendor_code,
                                              gv_tkn_value,
                                              lr_mst_rec.vendor_code);
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        lv_retcode := gv_status_warn;
        ov_retcode := gv_status_warn;
      END IF;
--
      -- ������уC���^�t�F�[�X(�A�h�I��)�̔[����R�[�h���Y�������̔[����Ɠ��ꂩ�B
      IF ((lv_retcode = gv_status_normal)
        AND (lr_mst_rec.location_code <> NVL(lr_mst_rec.delivery_code,gv_one_space))) THEN
--
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_31g_06,
                                              gv_tkn_h_no,
                                              lr_mst_rec.src_doc_num,
                                              gv_tkn_m_no,
                                              lr_mst_rec.src_doc_line_num,
                                              gv_tkn_name,
                                              gv_tkn_name_location_code,
                                              gv_tkn_value,
                                              lr_mst_rec.location_code);
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        lv_retcode := gv_status_warn;
        ov_retcode := gv_status_warn;
      END IF;
--
      -- ������уC���^�t�F�[�X(�A�h�I��)�̃��b�gNo���Y�������̃��b�gNo�Ɠ��ꂩ�B
      IF ((lv_retcode = gv_status_normal)
        AND (NVL(lr_mst_rec.lot_number,gv_one_space) <> NVL(lr_mst_rec.lot_no,gv_one_space))) THEN
--
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_31g_06,
                                              gv_tkn_h_no,
                                              lr_mst_rec.src_doc_num,
                                              gv_tkn_m_no,
                                              lr_mst_rec.src_doc_line_num,
                                              gv_tkn_name,
                                              gv_tkn_name_lot_number,
                                              gv_tkn_value,
                                              lr_mst_rec.lot_number);
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        lv_retcode := gv_status_warn;
        ov_retcode := gv_status_warn;
      END IF;
--
      -- ������уC���^�t�F�[�X(�A�h�I��)�̕i�ڃR�[�h���Y�������̕i�ڂƓ��ꂩ�B
      IF ((lv_retcode = gv_status_normal)
        AND (lr_mst_rec.item_code <> NVL(lr_mst_rec.item_no,gv_one_space))) THEN
--
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_31g_06,
                                              gv_tkn_h_no,
                                              lr_mst_rec.src_doc_num,
                                              gv_tkn_m_no,
                                              lr_mst_rec.src_doc_line_num,
                                              gv_tkn_name,
                                              gv_tkn_name_item_code,
                                              gv_tkn_value,
                                              lr_mst_rec.item_code);
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        lv_retcode := gv_status_warn;
        ov_retcode := gv_status_warn;
      END IF;
--
      -- ������� �������ł��邱�ƁB
      IF ((lv_retcode = gv_status_normal) AND (lr_mst_rec.rcv_quantity < 0)) THEN
--
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_31g_07,
                                              gv_tkn_h_no,
                                              lr_mst_rec.src_doc_num,
                                              gv_tkn_m_no,
                                              lr_mst_rec.src_doc_line_num,
                                              gv_tkn_rcv_num,
                                              TO_CHAR(lr_mst_rec.rcv_quantity));
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        lv_retcode := gv_status_warn;
        ov_retcode := gv_status_warn;
      END IF;
--
    END LOOP chk_loop;
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
  END proper_check;
--
  /**********************************************************************************
   * Procedure Name   : insert_open_if
   * Description      : ����I�[�v��IF�ւ̎�����o�^(F-6)
   ***********************************************************************************/
  PROCEDURE insert_open_if(
    ov_errbuf          OUT NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'insert_open_if';       -- �v���O������
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
    ln_qty         NUMBER;
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
    -- ***************************************
    -- ***   ����w�b�_�I�[�v��IF�ꊇ�o�^  ***
    -- ***************************************
    FORALL itp_cnt IN 0 .. gt_master_tbl.COUNT-1
      INSERT INTO rcv_headers_interface
      ( header_interface_id
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
      VALUES
      ( gt_head_if_id(itp_cnt)                      -- header_interface_id
       ,gn_group_id                                 -- group_id
       ,'PENDING'                                   -- processing_status_code
       ,'VENDOR'                                    -- receipt_source_code
       ,'NEW'                                       -- transaction_type
       ,gd_last_update_date                         -- last_update_date
       ,gn_last_update_by                           -- last_updated_by
       ,gn_last_update_login                        -- last_update_login
       ,gd_creation_date                            -- creation_date
       ,gn_created_by                               -- created_by
       ,gt_vendor_id(itp_cnt)                       -- vendor_id
       ,gt_promised_date(itp_cnt)                   -- expected_receipt_date
       ,'Y'                                         -- validation_flag
      );
--
    -- *************************************************
    -- ***   ����g�����U�N�V�����I�[�v��IF�ꊇ�o�^  ***
    -- *************************************************
    FORALL itp_cnt IN 0 .. gt_master_tbl.COUNT-1
      INSERT INTO rcv_transactions_interface
      ( interface_transaction_id
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
      VALUES
      ( gt_if_tran_id(itp_cnt)                      -- interface_transaction_id
       ,gn_group_id                                 -- group_id
       ,gd_last_update_date                         -- last_update_date
       ,gn_last_update_by                           -- last_updated_by
       ,gd_creation_date                            -- creation_date
       ,gn_created_by                               -- created_by
       ,gn_last_update_login                        -- last_update_login
       ,'RECEIVE'                                   -- transaction_type
       ,gt_rcv_date(itp_cnt)                        -- transaction_date
       ,'PENDING'                                   -- processing_status_code
       ,'BATCH'                                     -- processing_mode_code
       ,'PENDING'                                   -- transaction_status_code
       ,gt_calc_quantity(itp_cnt)                   -- quantity
       ,gt_rcv_quantity_uom(itp_cnt)                -- unit_of_measure
       ,gt_item_id(itp_cnt)                         -- item_id
       ,'DELIVER'                                   -- auto_transact_code
       ,'VENDOR'                                    -- receipt_source_code
       ,gt_organization_id(itp_cnt)                 -- to_organization_id
       ,'PO'                                        -- source_document_code
       ,gt_po_header_id(itp_cnt)                    -- po_header_id
       ,gt_po_line_id(itp_cnt)                      -- po_line_id
       ,gt_po_line_id(itp_cnt)                      -- po_line_location_id
       ,'INVENTORY'                                 -- destination_type_code
       ,gt_subinventory(itp_cnt)                    -- subinventory
       ,gt_locator_id(itp_cnt)                      -- locator_id
       ,gt_promised_date(itp_cnt)                   -- expected_receipt_date
       ,gt_txns_id(itp_cnt)                         -- ship_line_attribute1
       ,gt_head_if_id(itp_cnt)                      -- header_interface_id
       ,'Y'                                         -- validation_flag
      );
--
    -- ***************************************
    -- ***   ����w�b�_�I�[�v��IF�ꊇ�o�^  ***
    -- ***************************************
    FORALL itp_cnt IN 0 .. gn_lot_count-1
      INSERT INTO mtl_transaction_lots_interface
      ( transaction_interface_id
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
      VALUES
      ( mtl_material_transactions_s.NEXTVAL         -- transaction_interface_id
       ,gd_last_update_date                         -- last_update_date
       ,gn_last_update_by                           -- last_updated_by
       ,gd_creation_date                            -- creation_date
       ,gn_created_by                               -- created_by
       ,gn_last_update_login                        -- last_update_login
       ,gt_trans_lot(itp_cnt)                       -- lot_number
       ,gt_trans_qty(itp_cnt)                       -- transaction_quantity
       ,gt_trans_qty(itp_cnt)                       -- primary_quantity
       ,'RCV'                                       -- product_code
       ,gt_trans_id(itp_cnt)                        -- product_transaction_id
      );
--
    gn_proc_flg := 1;
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
  END insert_open_if;
--
  /**********************************************************************************
   * Procedure Name   : insert_rcv_and_rtn
   * Description      : ����ԕi����(�A�h�I��)�ւ̎�����o�^(F-7)
   ***********************************************************************************/
  PROCEDURE insert_rcv_and_rtn(
    ov_errbuf           OUT NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'insert_rcv_and_rtn';       -- �v���O������
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
    ln_count      NUMBER;
    lv_doc_num    xxpo_rcv_and_rtn_txns.source_document_number%TYPE;
    ln_line_num   xxpo_rcv_and_rtn_txns.source_document_line_num%TYPE;
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
-- 2008/06/26 v1.4 Add
    <<number_get_loop>>
    FOR i IN 0..gt_master_tbl.COUNT-1 LOOP
--
      IF ((i = 0)
       OR (lv_doc_num <> gt_src_doc_num(i))
       OR (ln_line_num <> gt_src_doc_line_num(i))) THEN
--
        lv_doc_num  := gt_src_doc_num(i);
        ln_line_num := gt_src_doc_line_num(i);
--
        -- �����擾
        SELECT COUNT(xrrt.txns_id)
        INTO   ln_count
        FROM   xxpo_rcv_and_rtn_txns xrrt
        WHERE  xrrt.source_document_number   = lv_doc_num
        AND    xrrt.source_document_line_num = ln_line_num
        AND    ROWNUM = 1;
      END IF;
--
      ln_count := ln_count + 1;
      gt_rtn_line_num(i) := ln_count;
    END LOOP number_get_loop;
-- 2008/06/26 v1.4 Add
--
    -- ***************************************
    -- ***  ����ԕi����(�A�h�I��)�ꊇ�o�^ ***
    -- ***************************************
    FORALL itp_cnt IN 0 .. gt_master_tbl.COUNT-1
      INSERT INTO xxpo_rcv_and_rtn_txns
        ( txns_id
         ,rcv_rtn_number
         ,rcv_rtn_line_number
         ,txns_type
         ,source_document_number
         ,source_document_line_num
         ,drop_ship_type
         ,vendor_id
         ,vendor_code
         ,location_code
         ,txns_date
         ,item_id
         ,item_code
         ,lot_id
         ,lot_number
         ,quantity
         ,uom
         ,rcv_rtn_quantity
         ,rcv_rtn_uom
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
      VALUES
      (   gt_txns_id(itp_cnt)               -- txns_id
         ,gt_src_doc_num(itp_cnt)           -- rcv_rtn_number
-- 2008/06/26 v1.4 Add
--         ,gt_src_doc_line_num(itp_cnt)      -- rcv_rtn_line_number
         ,gt_rtn_line_num(itp_cnt)          -- rcv_rtn_line_number
-- 2008/06/26 v1.4 Add
         ,gv_txns_type_po                   -- txns_type
         ,gt_src_doc_num(itp_cnt)           -- source_document_number
         ,gt_src_doc_line_num(itp_cnt)      -- source_document_line_num
         ,gt_attribute6(itp_cnt)            -- drop_ship_type
         ,gt_vendor_id(itp_cnt)             -- vendor_id
         ,gt_vendor_code(itp_cnt)           -- vendor_code
         ,gt_location_code(itp_cnt)         -- location_code
         ,gt_rcv_date(itp_cnt)              -- txns_date
-- 2008/05/21 v1.2 Add
--         ,gt_item_id(itp_cnt)               -- item_id
         ,gt_opm_item_id(itp_cnt)            -- opm_item_id
-- 2008/05/21 v1.2 Add
         ,gt_item_code(itp_cnt)             -- item_code
         ,gt_lot_id(itp_cnt)                -- lot_id
         ,gt_lot_no(itp_cnt)                -- lot_number
         ,gt_rtn_quantity(itp_cnt)          -- quantity
         ,gt_unit_code(itp_cnt)             -- uom
         ,gt_rcv_quantity(itp_cnt)          -- rcv_rtn_quantity
         ,gt_attribute10(itp_cnt)           -- rcv_rtn_uom
         ,gt_conversion_factor(itp_cnt)     -- conversion_factor
         ,gt_unit_price(itp_cnt)            -- unit_price
         ,gt_department_code(itp_cnt)       -- department_code
         ,gn_created_by                     -- created_by
         ,gd_creation_date                  -- creation_date
         ,gn_last_update_by                 -- last_updated_by
         ,gd_last_update_date               -- last_update_date
         ,gn_last_update_login              -- last_update_login
         ,gn_request_id                     -- request_id
         ,gn_program_application_id         -- program_application_id
         ,gn_program_id                     -- program_id
         ,gd_program_update_date            -- program_update_date
      );
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
  END insert_rcv_and_rtn;
--
  /**********************************************************************************
   * Procedure Name   : upd_po_lines
   * Description      : �������׍X�V(F-8)
   ***********************************************************************************/
  PROCEDURE upd_po_lines(
    ov_errbuf           OUT NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'upd_po_lines';       -- �v���O������
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
    -- ***************************************
    -- ***         �������׈ꊇ�X�V        ***
    -- ***************************************
    FORALL item_cnt IN 0 .. gt_master_tbl.COUNT-1
      UPDATE po_lines_all
-- 2008/06/26 v1.4 Add
--      SET  attribute7             = TO_CHAR(gt_rcv_quantity(item_cnt))
-- 2008/06/26 v1.4 Add
      SET  attribute7         = TO_CHAR(TO_NUMBER(NVL(attribute7,'0'))+gt_rcv_quantity(item_cnt))
          ,attribute13            = gv_flg_on
          ,last_updated_by        = gn_last_update_by
          ,last_update_date       = gd_last_update_date
          ,last_update_login      = gn_last_update_login
          ,request_id             = gn_request_id
          ,program_application_id = gn_program_application_id
          ,program_id             = gn_program_id
          ,program_update_date    = gd_program_update_date
      WHERE po_line_id = gt_po_line_id(item_cnt);
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
  END upd_po_lines;
--
  /**********************************************************************************
   * Procedure Name   : upd_lot_mst
   * Description      : ���b�g�X�V(F-9)
   ***********************************************************************************/
  PROCEDURE upd_lot_mst(
    ir_mst_rec      IN OUT NOCOPY masters_rec,      -- �Ώۃ��R�[�h
    ov_errbuf          OUT NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'upd_lot_mst';       -- �v���O������
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
    ln_flg            NUMBER;
    lv_return_status  VARCHAR2(1);
    ln_msg_count      NUMBER;
    lv_msg_data       VARCHAR2(2000);
    lr_lot_rec        ic_lots_mst%ROWTYPE;
    lr_lot_cpg_rec    ic_lots_cpg%ROWTYPE;
    ld_def4_date      DATE;                   -- �[����(����)
    ld_def5_date      DATE;                   -- �[����(�ŏI)
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
    ln_flg := 0;
--
    -- OPM���b�g�}�X�^�̎擾
    get_lot_mst(
      ir_mst_rec,
      lr_lot_rec,
      lr_lot_cpg_rec,
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    ld_def4_date := FND_DATE.STRING_TO_DATE(lr_lot_rec.attribute4,'YYYY/MM/DD');
    ld_def5_date := FND_DATE.STRING_TO_DATE(lr_lot_rec.attribute5,'YYYY/MM/DD');
--
    -- �[����(����)��NULL �܂��� �[����(����) > �����
    IF ((lr_lot_rec.attribute4 IS NULL) OR (ld_def4_date > ir_mst_rec.rcv_date)) THEN
      lr_lot_rec.attribute4 := TO_CHAR(ir_mst_rec.rcv_date,'YYYY/MM/DD');
      ln_flg := 1;
    END IF;
--
    -- �[����(�ŏI)��NULL �܂��� �[����(�ŏI) < �����
    IF ((lr_lot_rec.attribute5 IS NULL) OR (ld_def5_date < ir_mst_rec.rcv_date)) THEN
      lr_lot_rec.attribute5 := TO_CHAR(ir_mst_rec.rcv_date,'YYYY/MM/DD');
      ln_flg := 1;
    END IF;
--
    -- �X�V����
    IF (ln_flg = 1) THEN
--
      -- WHO�J�����ݒ�
      lr_lot_rec.last_update_date       := gd_last_update_date;
      lr_lot_rec.last_updated_by        := gn_last_update_by;
      lr_lot_rec.last_update_login      := gn_last_update_login;
      lr_lot_rec.program_application_id := gn_program_application_id;
      lr_lot_rec.program_id             := gn_program_id;
      lr_lot_rec.program_update_date    := gd_program_update_date;
      lr_lot_rec.request_id             := gn_request_id;
--
      lr_lot_cpg_rec.last_update_date   := gd_last_update_date;
      lr_lot_cpg_rec.last_updated_by    := gn_last_update_by;
      lr_lot_cpg_rec.last_update_login  := gn_last_update_login;
--
      -- ���b�g�}�X�^�̍X�V
      GMI_LOTUPDATE_PUB.UPDATE_LOT(
         P_API_VERSION      => 1.0
        ,P_INIT_MSG_LIST    => FND_API.G_FALSE
        ,P_COMMIT           => FND_API.G_FALSE
        ,P_VALIDATION_LEVEL => FND_API.G_VALID_LEVEL_FULL
        ,X_RETURN_STATUS    => lv_return_status
        ,X_MSG_COUNT        => ln_msg_count
        ,X_MSG_DATA         => lv_msg_data
        ,P_LOT_REC          => lr_lot_rec
        ,P_LOT_CPG_REC      => lr_lot_cpg_rec
        );
--
      IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
--
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_com_name,
                                              'APP-XXCMN-10018',
                                              gv_tkn_api_name,
                                              'GMI_LOTUPDATE_PUB.UPDATE_LOT');
--
        FND_MSG_PUB.GET( P_MSG_INDEX     => 1,
                         P_ENCODED       => FND_API.G_FALSE,
                         P_DATA          => lv_msg_data,
                         P_MSG_INDEX_OUT => ln_msg_count );
--
        lv_errbuf := lv_msg_data;
        RAISE global_api_expt;
      END IF;
    END IF;
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
  END upd_lot_mst;
--
  /**********************************************************************************
   * Procedure Name   : insert_tran
   * Description      : �݌Ɏ���ɏo�ɏ��o�^(F-10)
   ***********************************************************************************/
  PROCEDURE insert_tran(
    ir_mst_rec      IN OUT NOCOPY masters_rec,      -- �Ώۃ��R�[�h
    ov_errbuf          OUT NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'insert_tran';       -- �v���O������
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
    ln_num              NUMBER;
    lv_return_status    VARCHAR2(1);
    ln_msg_count        NUMBER;
    lv_msg_data         VARCHAR2(2000);
--
    lr_qty_rec          GMIGAPI.qty_rec_typ;
    lr_ic_jrnl_mst_row  ic_jrnl_mst%ROWTYPE;
    lr_ic_adjs_jnl_row1 ic_adjs_jnl%ROWTYPE;
    lr_ic_adjs_jnl_row2 ic_adjs_jnl%ROWTYPE;
--
    ln_qty              NUMBER;
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
    -- �q�ɁA��ЁA�g�D�̎擾
    get_location(
      ir_mst_rec,
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    lr_qty_rec.trans_type     := 2;                              -- ����^�C�v(2:��������)
    lr_qty_rec.reason_code    := gv_inv_ship_rsn;                -- ���R�R�[�h
    lr_qty_rec.trans_date     := ir_mst_rec.promised_date;       -- �����
    lr_qty_rec.from_location  := ir_mst_rec.vendor_stock_whse;   -- �o�Ɍ�
    lr_qty_rec.item_no        := ir_mst_rec.item_code;           -- �i��NO
    lr_qty_rec.lot_no         := ir_mst_rec.lot_no;              -- ���b�gNO
    lr_qty_rec.item_um        := ir_mst_rec.unit_code;           -- �P��
    lr_qty_rec.user_name      := gv_user_name;                   -- ���[�U��
--
    lr_qty_rec.from_whse_code := ir_mst_rec.from_whse_code;      -- �q��
    lr_qty_rec.co_code        := ir_mst_rec.co_code;             -- ���
    lr_qty_rec.orgn_code      := ir_mst_rec.orgn_code;           -- �g�D
--
    ln_qty := ir_mst_rec.rcv_quantity;
--
    -- �h�����N���i(���o�Ɋ��Z�P�ʂ���) �̏ꍇ
    IF ((ir_mst_rec.prod_class_code = gv_prod_class_code)
     AND (ir_mst_rec.unit_code <> ir_mst_rec.attribute10)) THEN
      ln_qty := ln_qty * NVL(ir_mst_rec.num_of_cases,1);
    END IF;
--
    lr_qty_rec.trans_qty := ln_qty * (-1);
--
    -- �݌Ƀg�����U�N�V�����̍쐬
    GMIPAPI.Inventory_Posting(
       P_API_VERSION       => 3.0
      ,P_INIT_MSG_LIST     => FND_API.G_FALSE
      ,P_COMMIT            => FND_API.G_FALSE
      ,P_VALIDATION_LEVEL  => FND_API.G_VALID_LEVEL_FULL
      ,P_QTY_REC           => lr_qty_rec
      ,X_IC_JRNL_MST_ROW   => lr_ic_jrnl_mst_row
      ,X_IC_ADJS_JNL_ROW1  => lr_ic_adjs_jnl_row1
      ,X_IC_ADJS_JNL_ROW2  => lr_ic_adjs_jnl_row2
      ,X_RETURN_STATUS     => lv_return_status
      ,X_MSG_COUNT         => ln_msg_count
      ,X_MSG_DATA          => lv_msg_data
      );
--
    IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
--
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_com_name,
                                            'APP-XXCMN-10018',
                                            gv_tkn_api_name,
                                            'GMIPAPI.INVENTORY_POSTING');
--
      lv_msg_data := lv_errmsg;
--
      xxcmn_common_pkg.put_api_log(
                    lv_errbuf,
                    lv_retcode,
                    lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      lv_errmsg := lv_msg_data;
      lv_errbuf := lv_msg_data;
      RAISE global_api_expt;
    END IF;
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
  END insert_tran;
--
  /**********************************************************************************
   * Procedure Name   : disp_report
   * Description      : ���������������o��(F-11)
   ***********************************************************************************/
  PROCEDURE disp_report(
    ir_mst_rec      IN OUT NOCOPY masters_rec,      -- �Ώۃ��R�[�h
    ov_errbuf          OUT NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'disp_report';       -- �v���O������
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
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_31g_10,
                                          gv_tkn_h_no,
                                          ir_mst_rec.src_doc_num,
                                          gv_tkn_m_no,
                                          ir_mst_rec.src_doc_line_num,
                                          gv_tkn_name_vendor,
                                          ir_mst_rec.vendor_code,
                                          gv_tkn_name_shipment,
                                          ir_mst_rec.location_code);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
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
  END disp_report;
--
  /**********************************************************************************
   * Procedure Name   : upd_status
   * Description      : �����X�e�[�^�X�X�V(F-12)
   ***********************************************************************************/
  PROCEDURE upd_status(
    ov_errbuf           OUT NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'upd_status';       -- �v���O������
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
    lr_mst_rec          masters_rec;
    lt_po_header_id     reg_po_header_id;
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
    -- �����w�b�_�̃X�e�[�^�X�F�u�����쐬�ρv�ˁu�������v�ɍX�V
    FORALL item_cnt IN 0 .. gn_head_count-1
      UPDATE po_headers_all
      SET    attribute1             = gv_add_status_rcv_on
            ,last_update_date       = gd_last_update_date
            ,last_updated_by        = gn_last_update_by
            ,last_update_login      = gn_last_update_login
            ,request_id             = gn_request_id
            ,program_application_id = gn_program_application_id
            ,program_id             = gn_program_id
            ,program_update_date    = gd_program_update_date
      WHERE  po_header_id = gt_keep_header_id(item_cnt)
      AND    attribute1   = gv_add_status_zmi;
--
    -- �S�Ă̔������ׂ̐��ʊm��t���O���uY�v�ƂȂ����ꍇ�ɂ́A
    -- ���݂̔����w�b�_�̃X�e�[�^�X���u���ʊm��ρv�����ł���΁u���ʊm��ρv�ɍX�V
    FORALL item_cnt IN 0 .. gn_head_count-1
      UPDATE po_headers_all pha
      SET    pha.attribute1         = gv_add_status_num_zmi
            ,last_update_date       = gd_last_update_date
            ,last_updated_by        = gn_last_update_by
            ,last_update_login      = gn_last_update_login
            ,request_id             = gn_request_id
            ,program_application_id = gn_program_application_id
            ,program_id             = gn_program_id
            ,program_update_date    = gd_program_update_date
      WHERE  pha.po_header_id = gt_keep_header_id(item_cnt)
      AND    NOT EXISTS (
        SELECT pla.po_header_id
        FROM   po_lines_all pla
        WHERE  NVL(pla.attribute13,gv_flg_off) <> gv_flg_on
        AND    pla.po_header_id = pha.po_header_id
      )
      AND    pha.attribute1 < gv_add_status_num_zmi;
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
  END upd_status;
--
  /**********************************************************************************
   * Procedure Name   : commit_open_if
   * Description      : ����I�[�v��IF�ɓo�^�������e�̔��f(F-13)
   ***********************************************************************************/
  PROCEDURE commit_open_if(
    ov_errbuf           OUT NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'commit_open_if';       -- �v���O������
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
    lb_ret         NUMBER;
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
    COMMIT;
--
    -- ����I�[�v��IF�o�^����
    IF (gn_proc_flg = 1) THEN
--
      -- �R���J�����g�̋N��
      lb_ret := FND_REQUEST.SUBMIT_REQUEST(
                    application  => gv_appl_name           -- �A�v���P�[�V�����Z�k��
                   ,program      => gv_prg_name            -- �v���O������
                   ,argument1    => gv_exec_mode           -- �������[�h
                   ,argument2    => TO_CHAR(gn_group_id)   -- �O���[�vID
                  );
--
      -- �G���[
      IF (lb_ret = 0) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_31g_04);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
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
  END commit_open_if;
--
  /**********************************************************************************
   * Procedure Name   : del_rcv_txns_if
   * Description      : ������уC���^�[�t�F�[�X(�A�h�I��)�̍폜(F-14)
   ***********************************************************************************/
  PROCEDURE del_rcv_txns_if(
    ov_errbuf           OUT NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'del_rcv_txns_if';       -- �v���O������
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
    -- ***************************************
    -- ***       �������IF�ꊇ�폜        ***
    -- ***************************************
    FORALL del_cnt IN 0 .. gn_org_txns_cnt-1
      DELETE
      FROM xxpo_rcv_txns_interface
      WHERE txns_id = gt_org_txns_id(del_cnt);
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
  END del_rcv_txns_if;
--
  /**********************************************************************************
   * Procedure Name   : term_proc
   * Description      : �I������(F-15)
   ***********************************************************************************/
  PROCEDURE term_proc(
    ov_errbuf           OUT NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'term_proc';       -- �v���O������
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
    -- �Ó����`�F�b�N�G���[����
    IF (gn_proper_error = 1) THEN
--
      COMMIT;
--
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_31g_03);
      lv_errbuf := lv_errmsg;
      RAISE term_proc_expt;
    END IF;
--
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_31g_11,
                                          gv_tkn_count,
                                          gt_master_tbl.COUNT);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
  EXCEPTION
    WHEN term_proc_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := gv_status_error;
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
  END term_proc;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--
    -- *** ���[�J���ϐ� ***
    mst_rec           masters_rec;
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
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    gn_proc_flg   := 0;
--
    gn_proper_error := 0;
    gn_org_txns_cnt := 0;
    gn_lot_count    := 0;
    gn_head_count   := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ================================
    -- F-1.�O����
    -- ================================
    init_proc(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ================================
    -- F-2.�����ΏۊO������я��擾
    -- ================================
    other_data_get(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ================================
    -- F-3.����ΏۊO���o��
    -- ================================
    IF (gt_other_tbl.COUNT > 0) THEN
      disp_other_data(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ================================
    -- F-4.�����Ώێ�����擾
    -- ================================
    master_data_get(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �������P���ȏ�
    IF (gt_master_tbl.COUNT > 0) THEN
--
      -- ================================
      -- F-5.�Ó����`�F�b�N
      -- ================================
      proper_check(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- �Ó����`�F�b�N�G���[�Ȃ�
      IF (lv_retcode = gv_status_normal) THEN
--
        -- ================================
        -- F-6.����I�[�v��IF�ւ̎�����o�^
        -- ================================
        insert_open_if(
          lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ================================
        -- F-7.����ԕi����(�A�h�I��)�ւ̎�����o�^
        -- ================================
        insert_rcv_and_rtn(
          lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ================================
        -- F-8.�������׍X�V
        -- ================================
        upd_po_lines(
          lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        <<api_loop>>
        FOR i IN 0..gt_master_tbl.COUNT-1 LOOP
--
          mst_rec := gt_master_tbl(i);
--
          -- ================================
          -- F-9.���b�g�X�V
          -- ================================
          upd_lot_mst(
            mst_rec,
            lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ����i�ڂ��u�����݌Ɂv
          IF (mst_rec.attribute11 = gv_po_type_rev) THEN
            -- ================================
            -- F-10.�݌Ɏ���ɏo�ɏ��o�^
            -- ================================
            insert_tran(
              mst_rec,
              lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
              lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
              lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_process_expt;
            END IF;
          END IF;
--
          -- ================================
          -- F-11.���������������o��
          -- ================================
          disp_report(
            mst_rec,
            lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
        END LOOP api_loop;
--
        -- ================================
        -- F-12.�����X�e�[�^�X�X�V
        -- ================================
        upd_status(
          lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ================================
        -- F-13.����I�[�v��IF�ɓo�^�������e�̔��f
        -- ================================
        commit_open_if(
          lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
      ELSE
        gn_proper_error := 1;
      END IF;
--
      -- ================================
      -- F-14.�������IF(�A�h�I��)�̑S�f�[�^�폜
      -- ================================
      del_rcv_txns_if(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    -- 2008/07/09 Add ��
    ELSE
      lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN',
                                            'APP-XXCMN-10036');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      ov_retcode := gv_status_warn;
      RETURN;
    -- 2008/07/09 Add ��
    END IF;
--
    -- ================================
    -- F-15.�I������
    -- ================================
    term_proc(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
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
    errbuf        OUT NOCOPY VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT NOCOPY VARCHAR2)      --   ���^�[���E�R�[�h    --# �Œ� #
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
--
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
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --��؂蕶���擾
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
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
END xxpo310004c;
/
