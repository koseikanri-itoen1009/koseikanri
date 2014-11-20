CREATE OR REPLACE PACKAGE BODY xxcmn560001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn560001c(body)
 * Description      : �g���[�T�r���e�B
 * MD.050           : �g���[�T�r���e�B T_MD050_BPO_560
 * MD.070           : �g���[�T�r���e�B(56A) T_MD070_BPO_56A
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  get_item_id            �i��ID�擾
 *  get_lot_id             ���b�gID�擾
 *  parameter_check        �p�����[�^�`�F�b�N                       (A-1)
 *  del_lot_trace          �o�^�Ώۃe�[�u���폜                     (A-2)
 *  get_lots_data          ���b�g�n���f�[�^���o                     (A-3/A-5/A-7/A-9/A-11)
 *  put_lots_data_no1      ���b�g�n���f�[�^�i�[                     (A-4/A-6/A-8/A-10/A-12)
 *  insert_lots_data       ���b�g�n���f�[�^�ꊇ�o�^                 (A-13)
 *  disp_report            �������ʃ��|�[�g�o��
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/01/08    1.0   ORACLE �⍲�q��  main�V�K�쐬
 *  2008/05/27    1.1   Masayuki Ikeda   �s��C��
 *  2008/07/02    1.2   ORACLE �ۉ�����  �z�Q�Ɩh�~�Ƀo�b�`ID��ǉ�
 *
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
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
  required_expt          EXCEPTION;               -- �K�{�`�F�b�N��O
  not_exist_expt         EXCEPTION;               -- ���݃`�F�b�N��O
  validate_expt          EXCEPTION;               -- �Ó����`�F�b�N��O
  lock_expt              EXCEPTION;               -- ���b�N�擾��O
  profile_expt           EXCEPTION;               -- �v���t�@�C���擾��O
  no_data_expt           EXCEPTION;               -- �Ώۃf�[�^�擾�Ȃ���O
  PRAGMA EXCEPTION_INIT(lock_expt, -54);          -- ���b�N�擾��O
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  -- ���b�Z�[�W�p�萔
  gv_pkg_name         CONSTANT VARCHAR2(15) := 'xxcmn560001c';      -- �p�b�P�[�W��
  gv_app_name         CONSTANT VARCHAR2(5)  := 'XXCMN';             -- �A�v���P�[�V�����Z�k��
  gv_tkn_name_01      CONSTANT VARCHAR2(50) := '�i�ڃR�[�h';        -- �p�����[�^�F�i�ڃR�[�h
  gv_tkn_name_02      CONSTANT VARCHAR2(50) := '���b�gNo';          -- �p�����[�^�F���b�gNo
  gv_tkn_name_03      CONSTANT VARCHAR2(50) := '�o�͐���';          -- �p�����[�^�F�o�͐���
  gv_tkn_name_04      CONSTANT VARCHAR2(50) := 'XXCMN_KEEP_PERIOD'; -- �v���t�@�C��  �F�ۑ�����
  gv_tkn_name_05      CONSTANT VARCHAR2(50) := '�ۑ�����';          -- �v���t�@�C�����F�ۑ�����
  gv_tkn_name_06      CONSTANT VARCHAR2(50) := 'ORG_ID';            -- �v���t�@�C��  �F�g�DID
  gv_tkn_name_07      CONSTANT VARCHAR2(50) := '�g�DID';            -- �v���t�@�C�����F�g�DID
  gv_tkn_name_08      CONSTANT VARCHAR2(50) := 'OPM�i�ڃ}�X�^';     -- �e�[�u����
  gv_tkn_name_09      CONSTANT VARCHAR2(50) := 'OPM���b�g�}�X�^';   -- �e�[�u����
--
  -- ���b�Z�[�W
  gv_msg_xxcmn10002   CONSTANT VARCHAR2(15) := 'APP-XXCMN-10002';   -- �v���t�@�C���擾�G���[
  gv_msg_xxcmn10019   CONSTANT VARCHAR2(15) := 'APP-XXCMN-10019';   -- ���b�N�擾�G���[
  gv_msg_xxcmn10033   CONSTANT VARCHAR2(15) := 'APP-XXCMN-10033';   -- �p�����[�^�G���[�F�K�{
  gv_msg_xxcmn10034   CONSTANT VARCHAR2(15) := 'APP-XXCMN-10034';   -- �p�����[�^�G���[�F���݂P
  gv_msg_xxcmn10035   CONSTANT VARCHAR2(15) := 'APP-XXCMN-10035';   -- �p�����[�^�G���[�F���͒l
--
  -- �g�[�N��
  gv_tkn_para_name    CONSTANT VARCHAR2(10) := 'PARAM_NAME';        -- �g�[�N���F�p�����[�^��
  gv_tkn_table_name   CONSTANT VARCHAR2(10) := 'TABLE_NAME';        -- �g�[�N���F�e�[�u����
  gv_tkn_para_value   CONSTANT VARCHAR2(11) := 'PARAM_VALUE';       -- �g�[�N���F�p�����[�^�l
  gv_tkn_profile      CONSTANT VARCHAR2(10) := 'NG_PROFILE';        -- �g�[�N���F�v���t�@�C����
  gv_tkn_table        CONSTANT VARCHAR2(10) := 'TABLE';             -- �g�[�N���F�e�[�u����
--
  -- ���[�U�[�萔
  gv_trace            CONSTANT VARCHAR2(1)  := '1';                 -- �o�͐���F���b�g�g���[�X
  gv_trace_back       CONSTANT VARCHAR2(1)  := '2';                 -- �o�͐���F���b�g�g���[�X�o�b�N
  gv_rcv_tran_type    CONSTANT VARCHAR2(10) := 'RECEIVE';           -- �������^�C�v
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ***************************************
  -- ***    �擾���i�[���R�[�h�^��`   ***
  -- ***************************************
--
  -- �݌Ƀg�����U�N�V�������Y���R�[�h
  TYPE mst_itp_rec IS RECORD(
    -- ���b�g��{���
    p_item_id           ic_tran_pnd.item_id%TYPE,                         -- �e�i��ID
    p_lot_id            ic_tran_pnd.lot_id%TYPE,                          -- �e���b�gID
    p_batch_id          gme_material_details.batch_id%TYPE,               -- �e�o�b�`ID
    p_item_no           ic_item_mst_b.item_no%TYPE,                       -- �e�i�ڃR�[�h
    p_item_name         xxcmn_item_mst_b.item_name%TYPE,                  -- �e�i�ږ���
    p_lot_no            ic_lots_mst.lot_no%TYPE,                          -- �e���b�gNo
    p_whse_code         ic_tran_pnd.whse_code%TYPE,                       -- �q�ɃR�[�h
    c_item_id           ic_tran_pnd.item_id%TYPE,                         -- �q�i��ID
    c_lot_id            ic_tran_pnd.lot_id%TYPE,                          -- �q���b�gID
    c_batch_id          gme_material_details.batch_id%TYPE,               -- �q�o�b�`ID
    c_item_no           ic_item_mst_b.item_no%TYPE,                       -- �q�i�ڃR�[�h
    c_item_name         xxcmn_item_mst_b.item_name%TYPE,                  -- �q�i�ږ���
    c_lot_no            ic_lots_mst.lot_no%TYPE,                          -- �q���b�gNo
    -- OPM���b�g���
    lot_date            ic_lots_mst.attribute1%TYPE,                      -- �����N����
    lot_sign            ic_lots_mst.attribute2%TYPE,                      -- �ŗL�L��
    best_bfr_date       ic_lots_mst.attribute3%TYPE,                      -- �ܖ�����
    dlv_date_first      ic_lots_mst.attribute4%TYPE,                      -- �[����(����)
    dlv_date_last       ic_lots_mst.attribute5%TYPE,                      -- �[����(�ŏI)
    stock_ins_amount    ic_lots_mst.attribute6%TYPE,                      -- �݌ɓ���
    tea_period_dev      ic_lots_mst.attribute10%TYPE,                     -- �����敪
    product_year        ic_lots_mst.attribute11%TYPE,                     -- �N�x
    product_home        ic_lots_mst.attribute12%TYPE,                     -- �Y�n
    product_type        ic_lots_mst.attribute13%TYPE,                     -- �^�C�v
    product_ranc_1      ic_lots_mst.attribute14%TYPE,                     -- �����N�P
    product_ranc_2      ic_lots_mst.attribute15%TYPE,                     -- �����N�Q
    product_slip_dev    ic_lots_mst.attribute16%TYPE,                     -- ���Y�`�[�敪
    description         ic_lots_mst.attribute18%TYPE,                     -- �E�v
    inspect_req         ic_lots_mst.attribute22%TYPE,                     -- �����˗�No
    -- ���Y�n���
    batch_num           gme_batch_header.batch_no%TYPE,                   -- �����o�b�`No
    batch_date          gme_material_details.attribute17%TYPE,            -- ������
    line_num            gmd_routings_b.routing_no%TYPE,                   -- ���C���ԍ�
    -- �����n���
    turn_date           gme_material_details.attribute11%TYPE,            -- ������
    turn_batch_num      gme_batch_header.batch_no%TYPE                    -- �����o�b�`No
  );
--
  -- ������擾
  TYPE mst_rcv_rec IS RECORD(
    p_item_id           ic_tran_pnd.item_id%TYPE,                         -- �e�i��ID
    p_lot_id            ic_tran_pnd.lot_id%TYPE,                          -- �e���b�gID
    p_item_no           ic_item_mst_b.item_no%TYPE,                       -- �e�i�ڃR�[�h
    p_item_name         xxcmn_item_mst_b.item_name%TYPE,                  -- �e�i�ږ���
    p_lot_no            ic_lots_mst.lot_no%TYPE,                          -- �e���b�gNo
    whse_code           ic_tran_pnd.whse_code%TYPE,                       -- �q�ɃR�[�h
    receipt_date        rcv_transactions.transaction_date%TYPE,           -- �����
    receipt_num         rcv_shipment_headers.receipt_num%TYPE,            -- ����ԍ�
    order_num           po_headers_all.segment1%TYPE,                     -- �����ԍ�
    supp_name           xxcmn_vendors.vendor_name%TYPE,                   -- �d���於
    supp_code           po_vendors.segment1%TYPE,                         -- �d����R�[�h
    trader_name         xxcmn_vendors.vendor_name%TYPE,                   -- �����Ǝ�
    -- OPM���b�g���
    lot_date            ic_lots_mst.attribute1%TYPE,                      -- �����N����
    lot_sign            ic_lots_mst.attribute2%TYPE,                      -- �ŗL�L��
    best_bfr_date       ic_lots_mst.attribute3%TYPE,                      -- �ܖ�����
    dlv_date_first      ic_lots_mst.attribute4%TYPE,                      -- �[����(����)
    dlv_date_last       ic_lots_mst.attribute5%TYPE,                      -- �[����(�ŏI)
    stock_ins_amount    ic_lots_mst.attribute6%TYPE,                      -- �݌ɓ���
    tea_period_dev      ic_lots_mst.attribute10%TYPE,                     -- �����敪
    product_year        ic_lots_mst.attribute11%TYPE,                     -- �N�x
    product_home        ic_lots_mst.attribute12%TYPE,                     -- �Y�n
    product_type        ic_lots_mst.attribute13%TYPE,                     -- �^�C�v
    product_ranc_1      ic_lots_mst.attribute14%TYPE,                     -- �����N�P
    product_ranc_2      ic_lots_mst.attribute15%TYPE,                     -- �����N�Q
    product_slip_dev    ic_lots_mst.attribute16%TYPE,                     -- ���Y�`�[�敪
    description         ic_lots_mst.attribute18%TYPE,                     -- �E�v
    inspect_req         ic_lots_mst.attribute22%TYPE                      -- �����˗�No
  );
--
  -- ���b�g�g���[�X�폜�p���R�[�h
  TYPE mst_del_lot_rec IS RECORD(
    division            xxcmn_lot_trace.division%TYPE,                    -- �敪
    level_num           xxcmn_lot_trace.level_num%TYPE,                   -- ���x���ԍ�
    item_code           xxcmn_lot_trace.item_code%TYPE,                   -- �e�i�ڃR�[�h
    lot_num             xxcmn_lot_trace.lot_num%TYPE,                     -- �e���b�gNo
    request_id          xxcmn_lot_trace.request_id%TYPE                   -- �v��ID
  );
--
  -- ***************************************
  -- ***      �o�^�p���ڃe�[�u���^       ***
  -- ***************************************
  -- �o�^�p
  -- �敪
  TYPE reg_division               IS TABLE OF  xxcmn_lot_trace.division               %TYPE INDEX BY BINARY_INTEGER;
  -- ���x���ԍ�
  TYPE reg_level_num              IS TABLE OF  xxcmn_lot_trace.level_num              %TYPE INDEX BY BINARY_INTEGER;
  -- �e�i��ID
  TYPE reg_item_id                IS TABLE OF  ic_tran_pnd.item_id                    %TYPE INDEX BY BINARY_INTEGER;
  -- �e�i�ڃR�[�h
  TYPE reg_item_code              IS TABLE OF  ic_item_mst_b.item_no                  %TYPE INDEX BY BINARY_INTEGER;
  -- �e�i�ږ���
  TYPE reg_item_name              IS TABLE OF  xxcmn_item_mst_b.item_name             %TYPE INDEX BY BINARY_INTEGER;
  -- �e���b�gID
  TYPE reg_lot_id                 IS TABLE OF  ic_lots_mst.lot_id                     %TYPE INDEX BY BINARY_INTEGER;
  -- �e���b�gNo
  TYPE reg_lot_num                IS TABLE OF  ic_lots_mst.lot_no                     %TYPE INDEX BY BINARY_INTEGER;
  -- �q�i��ID
  TYPE reg_trace_item_id          IS TABLE OF  ic_item_mst_b.item_id                  %TYPE INDEX BY BINARY_INTEGER;
  -- �q�i�ڃR�[�h
  TYPE reg_trace_item_code        IS TABLE OF  ic_item_mst_b.item_no                  %TYPE INDEX BY BINARY_INTEGER;
  -- �q�i�ږ���
  TYPE reg_trace_item_name        IS TABLE OF  xxcmn_item_mst_b.item_name             %TYPE INDEX BY BINARY_INTEGER;
  -- �q���b�gID
  TYPE reg_trace_lot_id           IS TABLE OF  ic_lots_mst.lot_id                     %TYPE INDEX BY BINARY_INTEGER;
  -- �q���b�gNo
  TYPE reg_trace_lot_num          IS TABLE OF  ic_lots_mst.lot_no                     %TYPE INDEX BY BINARY_INTEGER;
  -- �����o�b�`No
  TYPE reg_batch_num              IS TABLE OF  gme_batch_header.batch_no              %TYPE INDEX BY BINARY_INTEGER;
  -- ������
  TYPE reg_batch_date             IS TABLE OF  gme_material_details.attribute17       %TYPE INDEX BY BINARY_INTEGER;
  -- �q�ɃR�[�h
  TYPE reg_whse_code              IS TABLE OF  ic_tran_pnd.whse_code                  %TYPE INDEX BY BINARY_INTEGER;
  -- ���C���ԍ�
  TYPE reg_line_num               IS TABLE OF  gmd_routings_b.routing_no              %TYPE INDEX BY BINARY_INTEGER;
  -- ���Y��
  TYPE reg_turn_date              IS TABLE OF  gme_material_details.attribute11       %TYPE INDEX BY BINARY_INTEGER;
  -- �����o�b�`No
  TYPE reg_turn_batch_num         IS TABLE OF  gme_batch_header.batch_no              %TYPE INDEX BY BINARY_INTEGER;
  -- �����
  TYPE reg_receipt_date           IS TABLE OF  rcv_transactions.transaction_date      %TYPE INDEX BY BINARY_INTEGER;
  -- ����ԍ�
  TYPE reg_receipt_num            IS TABLE OF  rcv_shipment_headers.receipt_num       %TYPE INDEX BY BINARY_INTEGER;
  -- �����ԍ�
  TYPE reg_order_num              IS TABLE OF  po_headers_all.segment1                %TYPE INDEX BY BINARY_INTEGER;
  -- �d���於
  TYPE reg_supp_name              IS TABLE OF  xxcmn_vendors.vendor_name              %TYPE INDEX BY BINARY_INTEGER;
  -- �d����R�[�h
  TYPE reg_supp_code              IS TABLE OF  po_vendors.segment1                    %TYPE INDEX BY BINARY_INTEGER;
  -- �����Ǝ�
  TYPE reg_trader_name            IS TABLE OF  xxcmn_vendors.vendor_name              %TYPE INDEX BY BINARY_INTEGER;
  -- �����N����
  TYPE reg_lot_date               IS TABLE OF  ic_lots_mst.attribute1                 %TYPE INDEX BY BINARY_INTEGER;
  -- �ŗL�L��
  TYPE reg_lot_sign               IS TABLE OF  ic_lots_mst.attribute2                 %TYPE INDEX BY BINARY_INTEGER;
  -- �ܖ�����
  TYPE reg_best_bfr_date          IS TABLE OF  ic_lots_mst.attribute3                 %TYPE INDEX BY BINARY_INTEGER;
  -- �[����(����)
  TYPE reg_dlv_date_first         IS TABLE OF  ic_lots_mst.attribute4                 %TYPE INDEX BY BINARY_INTEGER;
  -- �[����(�ŏI)
  TYPE reg_dlv_date_last          IS TABLE OF  ic_lots_mst.attribute5                 %TYPE INDEX BY BINARY_INTEGER;
  -- �݌ɓ���
  TYPE reg_stock_ins_amount       IS TABLE OF  ic_lots_mst.attribute6                 %TYPE INDEX BY BINARY_INTEGER;
  -- �����敪
  TYPE reg_tea_period_dev         IS TABLE OF  ic_lots_mst.attribute10                %TYPE INDEX BY BINARY_INTEGER;
  -- �N�x
  TYPE reg_product_year           IS TABLE OF  ic_lots_mst.attribute11                %TYPE INDEX BY BINARY_INTEGER;
  -- �Y�n
  TYPE reg_product_home           IS TABLE OF  ic_lots_mst.attribute12                %TYPE INDEX BY BINARY_INTEGER;
  -- �^�C�v
  TYPE reg_product_type           IS TABLE OF  ic_lots_mst.attribute13                %TYPE INDEX BY BINARY_INTEGER;
  -- �����N�P
  TYPE reg_product_ranc_1         IS TABLE OF  ic_lots_mst.attribute14                %TYPE INDEX BY BINARY_INTEGER;
  -- �����N�Q
  TYPE reg_product_ranc_2         IS TABLE OF  ic_lots_mst.attribute15                %TYPE INDEX BY BINARY_INTEGER;
  -- ���Y�`�[�敪
  TYPE reg_product_slip_dev       IS TABLE OF  ic_lots_mst.attribute16                %TYPE INDEX BY BINARY_INTEGER;
  -- �E�v
  TYPE reg_description            IS TABLE OF  ic_lots_mst.attribute18                %TYPE INDEX BY BINARY_INTEGER;
  -- �����˗�No
  TYPE reg_inspect_req            IS TABLE OF  ic_lots_mst.attribute22                %TYPE INDEX BY BINARY_INTEGER;
  -- �쐬��
  TYPE reg_created_by             IS TABLE OF  xxcmn_lot_trace.created_by             %TYPE INDEX BY BINARY_INTEGER;
  -- �쐬��
  TYPE reg_creation_date          IS TABLE OF  xxcmn_lot_trace.creation_date          %TYPE INDEX BY BINARY_INTEGER;
  -- �ŏI�X�V��
  TYPE reg_last_updated_by        IS TABLE OF  xxcmn_lot_trace.last_updated_by        %TYPE INDEX BY BINARY_INTEGER;
  -- �ŏI�X�V��
  TYPE reg_last_update_date       IS TABLE OF  xxcmn_lot_trace.last_update_date       %TYPE INDEX BY BINARY_INTEGER;
  -- �ŏI�X�V���O�C��
  TYPE reg_last_update_login      IS TABLE OF  xxcmn_lot_trace.last_update_login      %TYPE INDEX BY BINARY_INTEGER;
  -- �v��ID
  TYPE reg_request_id             IS TABLE OF  xxcmn_lot_trace.request_id             %TYPE INDEX BY BINARY_INTEGER;
  -- �v���O����ID
  TYPE reg_program_id             IS TABLE OF  xxcmn_lot_trace.program_id             %TYPE INDEX BY BINARY_INTEGER;
  -- �v���O�����A�v���P�[�V����ID
  TYPE reg_program_application_id IS TABLE OF xxcmn_lot_trace.program_application_id  %TYPE INDEX BY BINARY_INTEGER;
  -- �v���O�����X�V��
  TYPE reg_program_update_date    IS TABLE OF xxcmn_lot_trace.program_update_date     %TYPE INDEX BY BINARY_INTEGER;
--
  -- �폜�p
  -- �敪
  TYPE del_division               IS TABLE OF  xxcmn_lot_trace.division               %TYPE INDEX BY BINARY_INTEGER;
  -- ���x���ԍ�
  TYPE del_level_num              IS TABLE OF  xxcmn_lot_trace.level_num              %TYPE INDEX BY BINARY_INTEGER;
  -- �e�i�ڃR�[�h
  TYPE del_item_code              IS TABLE OF  xxcmn_lot_trace.item_code              %TYPE INDEX BY BINARY_INTEGER;
  -- �e���b�gNo
  TYPE del_lot_num                IS TABLE OF  xxcmn_lot_trace.lot_num                %TYPE INDEX BY BINARY_INTEGER;
  -- �v��ID
  TYPE del_request_id             IS TABLE OF  xxcmn_lot_trace.request_id             %TYPE INDEX BY BINARY_INTEGER;
--
  -- �p�����[�^���(�g���[�X���L�[����)
  gv_item_id            ic_item_mst_b.item_id%TYPE;                       -- �i��ID
  gv_lot_id             ic_lots_mst.lot_id%TYPE;                          -- ���b�gID
--
  -- ***************************************
  -- ***      ���ڊi�[�e�[�u���^��`     ***
  -- ***************************************
--
  -- ���b�g�g���[�X�A�h�I���i�[�p�e�[�u���^��`
  -- ���Y��񃌃R�[�h
  TYPE mst_itp_tbl        IS TABLE OF mst_itp_rec       INDEX BY PLS_INTEGER;
  -- �����񃌃R�[�h
  TYPE mst_rcv_tbl        IS TABLE OF mst_rcv_rec       INDEX BY PLS_INTEGER;
  -- ���b�g�g���[�X�A�h�I���폜�p���R�[�h
  TYPE mst_del_lot_tbl    IS TABLE OF mst_del_lot_rec   INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �萔
  gn_keep_period              NUMBER;                     -- �v���t�@�C���F�ۑ�����
  gn_org_id                   NUMBER;                     -- �v���t�@�C���F�g�DID
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
  -- �e�[�u���^�O���[�o���ϐ�
  gt_itp_tbl                  mst_itp_tbl;                -- ���Y���
  gt_itp01_tbl                mst_itp_tbl;                -- ���Y�����K�w
  gt_itp02_tbl                mst_itp_tbl;                -- ���Y�����K�w
  gt_itp03_tbl                mst_itp_tbl;                -- ���Y����O�K�w
  gt_itp04_tbl                mst_itp_tbl;                -- ���Y����l�K�w
  gt_itp05_tbl                mst_itp_tbl;                -- ���Y����܊K�w
  gt_rcv_tbl                  mst_rcv_tbl;                -- ������
  gt_rcv01_tbl                mst_rcv_tbl;                -- ��������K�w
  gt_rcv02_tbl                mst_rcv_tbl;                -- ��������K�w
  gt_rcv03_tbl                mst_rcv_tbl;                -- �������O�K�w
  gt_rcv04_tbl                mst_rcv_tbl;                -- �������l�K�w
  gt_rcv05_tbl                mst_rcv_tbl;                -- �������܊K�w
  gt_del_lot_tbl              mst_del_lot_tbl;            -- ���b�g�g���[�X�폜�p���R�[�h
--
  -- ���ڃe�[�u���^��`
  gt_division                 reg_division;               -- �敪
  gt_level_num                reg_level_num;              -- ���x���ԍ�
  gt_item_id                  reg_item_id;                -- �e�i��ID
  gt_item_code                reg_item_code;              -- �e�i�ڃR�[�h
  gt_item_name                reg_item_name;              -- �e�i�ږ���
  gt_lot_id                   reg_lot_id;                 -- �e���b�gID
  gt_lot_num                  reg_lot_num;                -- �e���b�gNo
  gt_trace_item_id            reg_trace_item_id;          -- �q�i��ID
  gt_trace_item_code          reg_trace_item_code;        -- �q�i�ڃR�[�h
  gt_trace_item_name          reg_trace_item_name;        -- �q�i�ږ���
  gt_trace_lot_id             reg_trace_lot_id;           -- �q���b�gID
  gt_trace_lot_num            reg_trace_lot_num;          -- �q���b�gNo
  gt_batch_num                reg_batch_num;              -- �����o�b�`No
  gt_batch_date               reg_batch_date;             -- ������
  gt_whse_code                reg_whse_code;              -- �q�ɃR�[�h
  gt_line_num                 reg_line_num;               -- ���C���ԍ�
  gt_turn_date                reg_turn_date;              -- ���Y��
  gt_turn_batch_num           reg_turn_batch_num;         -- �����o�b�`No
  gt_receipt_date             reg_receipt_date;           -- �����
  gt_receipt_num              reg_receipt_num;            -- ����ԍ�
  gt_order_num                reg_order_num;              -- �����ԍ�
  gt_supp_name                reg_supp_name;              -- �d���於
  gt_supp_code                reg_supp_code;              -- �d����R�[�h
  gt_trader_name              reg_trader_name;            -- �����Ǝ�
  gt_lot_date                 reg_lot_date;               -- �����N����
  gt_lot_sign                 reg_lot_sign;               -- �ŗL�L��
  gt_best_bfr_date            reg_best_bfr_date;          -- �ܖ�����
  gt_dlv_date_first           reg_dlv_date_first;         -- �[����(����)
  gt_dlv_date_last            reg_dlv_date_last;          -- �[����(�ŏI)
  gt_stock_ins_amount         reg_stock_ins_amount;       -- �݌ɓ���
  gt_tea_period_dev           reg_tea_period_dev;         -- �����敪
  gt_product_year             reg_product_year;           -- �N�x
  gt_product_home             reg_product_home;           -- �Y�n
  gt_product_type             reg_product_type;           -- �^�C�v
  gt_product_ranc_1           reg_product_ranc_1;         -- �����N�P
  gt_product_ranc_2           reg_product_ranc_2;         -- �����N�Q
  gt_product_slip_dev         reg_product_slip_dev;       -- ���Y�`�[�敪
  gt_description              reg_description;            -- �E�v
  gt_inspect_req              reg_inspect_req;            -- �����˗�No
  gt_created_by               reg_created_by;             -- �쐬��
  gt_creation_date            reg_creation_date;          -- �쐬��
  gt_last_updated_by          reg_last_updated_by;        -- �ŏI�X�V��
  gt_last_update_date         reg_last_update_date;       -- �ŏI�X�V��
  gt_last_update_login        reg_last_update_login;      -- �ŏI�X�V���O�C��
  gt_request_id               reg_request_id;             -- �v��ID
  gt_program_id               reg_program_id;             -- �v���O����ID
  gt_program_application_id   reg_program_application_id; -- �v���O�����A�v���P�[�V����ID
  gt_program_update_date      reg_program_update_date;    -- �v���O�����X�V��
--
  /**********************************************************************************
   * Procedure Name   : get_item_id
   * Description      : �i��ID�擾
   ***********************************************************************************/
  PROCEDURE get_item_id(
    iv_item_code        IN     VARCHAR,                 -- ���̓p�����[�^(�i�ڃR�[�h)
    ov_errbuf           OUT    NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT    NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT    NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'get_item_id';           -- �v���O������
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
    lv_item_code            VARCHAR2(15)            := iv_item_code;            -- �i�ڃR�[�h
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
    -- ***            �i��ID�擾           ***
    -- ***************************************
    SELECT iimb.item_id
    INTO gv_item_id
    FROM ic_item_mst_b iimb
    WHERE iimb.item_no         = lv_item_code;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                             --*** ���݃`�F�b�N��O ***
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_app_name,        -- �A�v���P�[�V�����Z�k���FXXCMN ����
                            gv_msg_xxcmn10034,  -- ���b�Z�[�W�FAPP-XXCMN-10034 �p�����[�^�G���[�F���݂P
                            gv_tkn_para_name,   -- �g�[�N���F�p�����[�^��
                            gv_tkn_name_01,     -- �g�[�N���F�i�ڃR�[�h
                            gv_tkn_table_name,  -- �g�[�N���F�e�[�u����
                            gv_tkn_name_08      -- �g�[�N���FOPM�i�ڃ}�X�^
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      ov_errmsg := lv_errmsg;                                                   --# �C�� #
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_item_id;
--
  /**********************************************************************************
   * Procedure Name   : get_lot_id
   * Description      : ���b�gID�擾
   ***********************************************************************************/
  PROCEDURE get_lot_id(
    iv_lot_no           IN     VARCHAR,                 -- ���̓p�����[�^(���b�gNo)
    ov_errbuf           OUT    NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT    NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT    NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'get_lot_id';            -- �v���O������
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
    lv_lot_no               VARCHAR2(15)            := iv_lot_no;               -- ���b�gNo
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
    -- ***           ���b�gNo�擾          ***
    -- ***************************************
    SELECT ilm.lot_id
    INTO gv_lot_id
    FROM ic_lots_mst ilm
    WHERE ilm.lot_no        = lv_lot_no
    AND   ilm.item_id       = gv_item_id;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                             --*** ���݃`�F�b�N��O ***
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_app_name,        -- �A�v���P�[�V�����Z�k���FXXCMN ����
                            gv_msg_xxcmn10034,  -- ���b�Z�[�W�FAPP-XXCMN-10034 �p�����[�^�G���[�F���݂P
                            gv_tkn_para_name,   -- �g�[�N���F�p�����[�^��
                            gv_tkn_name_02,     -- �g�[�N���F���b�gNo
                            gv_tkn_table_name,  -- �g�[�N���F�e�[�u����
                            gv_tkn_name_09      -- �g�[�N���FOPM�i�ڃ}�X�^
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      ov_errmsg := lv_errmsg;                                                   --# �C�� #
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_lot_id;
--
  /**********************************************************************************
   * Procedure Name   : parameter_check
   * Description      : �p�����[�^�`�F�b�N(A-1)
   ***********************************************************************************/
  PROCEDURE parameter_check(
    iv_item_code        IN     VARCHAR2,                -- �i�ڃR�[�h
    iv_lot_no           IN     VARCHAR2,                -- ���b�gNo
    iv_out_control      IN     VARCHAR2,                -- �o�͐���
    ov_errbuf           OUT    NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT    NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT    NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    cv_item_code            CONSTANT VARCHAR2(20)   := '�i�ڃR�[�h';            -- �p�����[�^���F�i�ڃR�[�h
    cv_lot_no               CONSTANT VARCHAR2(20)   := '���b�gNo';              -- �p�����[�^���F���b�gNo
    cv_out_control          CONSTANT VARCHAR2(20)   := '�o�͐���';              -- �p�����[�^���F�o�͐���
--
    -- *** ���[�J���ϐ� ***
    lv_item_code            VARCHAR2(10)            := iv_item_code;            -- �i�ڃR�[�h
    lv_lot_no               VARCHAR2(10)            := iv_lot_no;               -- ���b�gNo
    lv_out_control          VARCHAR2(10)            := iv_out_control;          -- �o�͐���
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
    -- ***     �K�{�`�F�b�N(�i�ڃR�[�h)    ***
    -- ***************************************
    -- 
    IF (lv_item_code IS NULL) THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_app_name,        -- �A�v���P�[�V�����Z�k���FXXCMN ����
                            gv_msg_xxcmn10033,  -- ���b�Z�[�W�FAPP-XXCMN-10033 �p�����[�^�G���[�F�K�{
                            gv_tkn_para_name,   -- �g�[�N���F�p�����[�^��
                            gv_tkn_name_01      -- �p�����[�^�F�i�ڃR�[�h
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE required_expt;
    END IF;
--
    -- ***************************************
    -- ***      �K�{�`�F�b�N(���b�gNo)     ***
    -- ***************************************
    -- 
    IF (lv_lot_no IS NULL) THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_app_name,        -- �A�v���P�[�V�����Z�k���FXXCMN ����
                            gv_msg_xxcmn10033,  -- ���b�Z�[�W�FAPP-XXCMN-10033 �p�����[�^�G���[�F�K�{
                            gv_tkn_para_name,   -- �g�[�N���F�p�����[�^��
                            gv_tkn_name_02      -- �p�����[�^�F���b�gNo
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE required_expt;
    END IF;
--
    -- ***************************************
    -- ***      �K�{�`�F�b�N(�o�͐���)     ***
    -- ***************************************
    -- 
    IF (lv_out_control IS NULL) THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_app_name,        -- �A�v���P�[�V�����Z�k���FXXCMN ����
                            gv_msg_xxcmn10033,  -- ���b�Z�[�W�FAPP-XXCMN-10033 �p�����[�^�G���[�F�K�{
                            gv_tkn_para_name,   -- �g�[�N���F�p�����[�^��
                            gv_tkn_name_03      -- �p�����[�^�F�o�͐���
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE required_expt;
    END IF;
--
    -- ***************************************
    -- ***           ���݃`�F�b�N          ***
    -- ***************************************
    -- �i�ڃR�[�h�̑��݃`�F�b�N
    get_item_id(
      lv_item_code,       -- ���̓p�����[�^(�i�ڃR�[�h)
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE not_exist_expt;
    END IF;
--
    -- ���b�gNo�̑��݃`�F�b�N
    get_lot_id(
      lv_lot_no,          -- ���̓p�����[�^(���b�gNo)
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE not_exist_expt;
    END IF;
--
    -- ***************************************
    -- ***          �Ó����`�F�b�N         ***
    -- ***************************************
    -- �o�͐���̑Ó����`�F�b�N
    IF ( (lv_out_control <> gv_trace) AND (lv_out_control <> gv_trace_back) ) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_app_name,        -- �A�v���P�[�V�����Z�k���FXXCMN ����
                            gv_msg_xxcmn10035,  -- ���b�Z�[�W�FAPP-XXCMN-10035 �p�����[�^�G���[�F���͒l
                            gv_tkn_para_name,   -- �g�[�N���F�p�����[�^��
                            gv_tkn_name_03,     -- �g�[�N���F�o�͐���
                            gv_tkn_para_value,  -- �g�[�N���F�e�[�u����
                            lv_out_control      -- �p�����[�^�F�o�͐���
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE validate_expt;
    END IF;
--
    -- ***************************************
    -- ***         �v���t�@�C���擾        ***
    -- ***************************************
    -- �v���t�@�C���F�ۑ����Ԃ̎擾
    gn_keep_period := TO_NUMBER( FND_PROFILE.VALUE(gv_tkn_name_04) );
    -- �擾�G���[��
    IF (gn_keep_period IS NULL) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_app_name,        -- �A�v���P�[�V�����Z�k���FXXCMN ����
                            gv_msg_xxcmn10002,  -- ���b�Z�[�W�FAPP-XXCMN-10002 �v���t�@�C���擾�G���[
                            gv_tkn_profile,     -- �g�[�N���FNG_PROFILE
                            gv_tkn_name_05      -- �ۑ�����
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE profile_expt;
    END IF;
--
    -- �v���t�@�C���F�g�DID�̎擾
    gn_org_id := TO_NUMBER( FND_PROFILE.VALUE(gv_tkn_name_06) );
    -- �擾�G���[��
    IF (gn_org_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_app_name,        -- �A�v���P�[�V�����Z�k���FXXCMN ����
                            gv_msg_xxcmn10002,  -- ���b�Z�[�W�FAPP-XXCMN-10002 �v���t�@�C���擾�G���[
                            gv_tkn_profile,     -- �g�[�N���FNG_PROFILE
                            gv_tkn_name_07      -- �g�DID
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE profile_expt;
    END IF;
--
    -- WHO�J�����̎擾
    gn_created_by             :=  FND_GLOBAL.USER_ID;
    gd_creation_date          :=  SYSDATE;
    gn_last_update_by         :=  FND_GLOBAL.USER_ID;
    gd_last_update_date       :=  SYSDATE;
    gn_last_update_login      :=  FND_GLOBAL.LOGIN_ID;
    gn_request_id             :=  FND_GLOBAL.CONC_REQUEST_ID;
    gn_program_application_id :=  FND_GLOBAL.PROG_APPL_ID;
    gn_program_id             :=  FND_GLOBAL.CONC_PROGRAM_ID;
    gd_program_update_date    :=  SYSDATE;
--
  EXCEPTION
    WHEN required_expt THEN                             --*** �p�����[�^��O ***
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
--
    WHEN not_exist_expt THEN                            --*** �p�����[�^��O ***
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
--
    WHEN validate_expt THEN                             --*** �p�����[�^��O ***
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
--
    WHEN profile_expt THEN                              --*** �v���t�@�C���擾�G���[ ***
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END parameter_check;
--
  /**********************************************************************************
   * Procedure Name   : del_lot_trace
   * Description      : �o�^�Ώۃe�[�u���폜(A-2)
   ***********************************************************************************/
  PROCEDURE del_lot_trace(
    ov_errbuf           OUT    NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT    NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT    NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'del_lot_trace';         -- �v���O������
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
    cv_tbl_name             CONSTANT VARCHAR2(50)   := '���b�g�g���[�X';        -- �e�[�u����
--
    -- *** ���[�J���ϐ� ***
    ln_del_cont             NUMBER;                         -- �폜�Ώۃ��R�[�h����
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    lt_division             del_division;                   -- �敪
    lt_level_num            del_level_num;                  -- ���x���ԍ�
    lt_item_code            del_item_code;                  -- �i�ڃR�[�h
    lt_lot_num              del_lot_num;                    -- ���b�g�ԍ�
    lt_request_id           del_request_id;                 -- �v��ID
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
    -- ***   ���b�g�g���[�X�A�h�I���폜    ***
    -- ***************************************
    -- ���b�g�g���[�X�A�h�I�����擾(�폜�Ώۃ��R�[�h)
    SELECT xlt.division,                                                -- �敪
           xlt.level_num,                                               -- ���x���ԍ�
           xlt.item_code,                                               -- �e�i�ڃR�[�h
           xlt.lot_num,                                                 -- �e���b�gNo
           xlt.request_id                                               -- �v��ID
    BULK COLLECT INTO gt_del_lot_tbl
    FROM xxcmn_lot_trace xlt
    WHERE xlt.creation_date <= (TRUNC(SYSDATE) - gn_keep_period)
    FOR UPDATE NOWAIT;
--
    -- �Ώۃ��R�[�h�폜
    IF ( gt_del_lot_tbl IS NOT NULL ) THEN
      -- ���[�v�����ɂāA�o���N�擾�����f�[�^�����ڒP�ʂ̃e�[�u���^�ֈڍs
      -- ���ڒP�ʂ̃e�[�u���^���g�p���āA�Ώۃ��R�[�h���폜����
      << del_loop >>
      FOR col_cnt IN 1 .. gt_del_lot_tbl.COUNT LOOP
        lt_division(col_cnt)    := gt_del_lot_tbl(col_cnt).division;
        lt_level_num(col_cnt)   := gt_del_lot_tbl(col_cnt).level_num;
        lt_item_code(col_cnt)   := gt_del_lot_tbl(col_cnt).item_code;
        lt_lot_num(col_cnt)     := gt_del_lot_tbl(col_cnt).lot_num;
        lt_request_id(col_cnt)  := gt_del_lot_tbl(col_cnt).request_id;
      END LOOP;
--
      FORALL del_cnt IN 1 .. lt_division.COUNT
        -- ���b�g�g���[�X�ꊇ�폜
        DELETE
        FROM xxcmn_lot_trace xlt
        WHERE division   = lt_division(del_cnt)
        AND   level_num  = lt_level_num(del_cnt)
        AND   item_code  = lt_item_code(del_cnt)
        AND   lot_num    = lt_lot_num(del_cnt)
        AND   request_id = lt_request_id(del_cnt);
--
    END IF;
--
  EXCEPTION
    WHEN lock_expt THEN                                 --*** ���b�N�擾��O ***
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_app_name,        -- �A�v���P�[�V�����Z�k���FXXCMN ����
                            gv_msg_xxcmn10019,  -- ���b�Z�[�W�FAPP-XXCMN-10019 ���b�N�G���[
                            gv_tkn_table,       -- �g�[�N��TABLE
                            cv_tbl_name         -- �e�[�u�����F���b�g�g���[�X
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      ov_errmsg := lv_errmsg;                                                   --# �C�� #
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END del_lot_trace;
--
  /**********************************************************************************
   * Procedure Name   : get_lots_data
   * Description      : ���b�g�n���f�[�^���o(A-3/A-5/A-7/A-9/A-11)
   ***********************************************************************************/
  PROCEDURE get_lots_data(
    iv_item_id          IN     VARCHAR2,                -- �i��ID
    iv_lot_id           IN     VARCHAR2,                -- ���b�gID
    iv_batch_id         IN     VARCHAR2,                -- �o�b�`ID
    iv_out_control      IN     VARCHAR2,                -- �o�͐���
    in_level_num        IN     NUMBER,                  -- �K�w
    ot_itp_tbl          OUT    NOCOPY mst_itp_tbl,      -- ���Y���
    ot_rcv_tbl          OUT    NOCOPY mst_rcv_tbl,      -- ������
    ov_errbuf           OUT    NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT    NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT    NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'get_lots_data';         -- �v���O������
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
    cv_doc_type             CONSTANT VARCHAR2(4)    := 'PROD';                  -- �����^�C�v
    cv_comp_ind             CONSTANT VARCHAR2(1)    := '1';                     -- �����C���W�P�[�^�F����
    cv_line_type_01         CONSTANT VARCHAR2(2)    := '1';                     -- �����i
    cv_line_type_02         CONSTANT VARCHAR2(2)    := '2';                     -- ���Y��
    cv_line_type_03         CONSTANT VARCHAR2(2)    := '-1';                    -- �����i
    cv_batch_status         CONSTANT VARCHAR2(2)    := '-1';                    -- ���
    cv_out_trace            CONSTANT VARCHAR2(1)    := '1';                     -- ���b�g�g���[�X(������)
    cv_out_back             CONSTANT VARCHAR2(1)    := '2';                     -- �g���[�X�o�b�N(���i��)
    cv_sql_dot              CONSTANT VARCHAR2(1)    := ',';                     -- �J���}
    cv_sql_l_block          CONSTANT VARCHAR2(1)    := '(';                     -- �J�b�R'('
    cv_sql_r_block          CONSTANT VARCHAR2(1)    := ')';                     -- �J�b�R')'
    -- *** ���[�J���ϐ� ***
    lv_sql_select_01        VARCHAR2(5000);                                     -- ���Y�nSELECT��(����)
    lv_sql_select_02        VARCHAR2(1000);                                     -- ���Y�nSELECT��(�g���[�X)
    lv_sql_select_03        VARCHAR2(1000);                                     -- ���Y�nSELECT��(�g���[�X�o�b�N)
    lv_sql_from             VARCHAR2(1000);                                     -- ���Y�nFROM��(����)
    lv_sql_01               VARCHAR2(6000);                                     -- ���⍇��(�e�i�ڃ��b�g�g���[�X)
    lv_sql_02               VARCHAR2(6000);                                     -- ���⍇��(�q�i�ڃ��b�g�g���[�X)
    lv_sql_03               VARCHAR2(6000);                                     -- ���⍇��(�e�i�ڃg���[�X�o�b�N)
    lv_sql_04               VARCHAR2(6000);                                     -- ���⍇��(�q�i�ڃg���[�X�o�b�N)
    lv_sql_par              VARCHAR2(100);                                      -- �ʖ�(�e)�pSQL
    lv_sql_chi              VARCHAR2(100);                                      -- �ʖ�(�q)�pSQL
    lv_sql_where_01         VARCHAR2(3000);                                     -- ���Y�nWHERE��(����)
    lv_sql_where_02         VARCHAR2(3000);                                     -- ���Y�nWHERE��(����)
--
    lv_sql_sel              VARCHAR2(8000);
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
    -- ***      ���b�g�n���f�[�^���o       ***
    -- ***************************************
    -- ���Y�n���擾SQL�̍쐬
--
    -- SELECT��(����)��`
    lv_sql_select_01 := 'SELECT pp.item_id      p_item_id '
                     ||       ',pp.lot_id       p_lot_id '
                     ||       ',pp.batch_id     p_batch_id '
                     ||       ',pp.item_no      p_item_no '
                     ||       ',pp.item_name    p_item_name '
                     ||       ',pp.lot_no       p_lot_no '
                     ||       ',pp.whse_code    p_whse_code '
                     ||       ',cp.item_id      c_item_id '
                     ||       ',cp.lot_id       c_lot_id '
                     ||       ',cp.batch_id     c_batch_id '
                     ||       ',cp.item_no      c_item_no '
                     ||       ',cp.item_name    c_item_name '
                     ||       ',cp.lot_no       c_lot_no '
                     ||       ',ilm.attribute1  l_lot_date '
                     ||       ',ilm.attribute2  l_lot_sign '
                     ||       ',ilm.attribute3  l_best_bfr_date '
                     ||       ',ilm.attribute4  l_dlv_date_first '
                     ||       ',ilm.attribute5  l_dlv_date_last '
                     ||       ',ilm.attribute6  l_stock_ins_amount '
                     ||       ',ilm.attribute10 l_tea_period_dev '
                     ||       ',ilm.attribute11 l_product_year '
                     ||       ',ilm.attribute12 l_product_home '
                     ||       ',ilm.attribute13 l_product_type '
                     ||       ',ilm.attribute14 l_product_ranc_1 '
                     ||       ',ilm.attribute15 l_product_ranc_2 '
                     ||       ',ilm.attribute16 l_product_slip_dev '
                     ||       ',ilm.attribute18 l_description '
                     ||       ',ilm.attribute22 l_inspect_req ';
--
    -- SELECT��(���b�g�g���[�X)��`
    lv_sql_select_02 := ',pp.batch_no       l_batch_num '
                     || ',pp.attribute17    l_batch_date '
                     || ',pp.routing_no     l_line_num '
                     || ',pp.attribute11    l_turn_date '
                     || ',pp.turn_batch_no  l_turn_batch_num ';
--
    -- FROM���`
    lv_sql_from := 'FROM ic_lots_mst ilm, ';
--
    -- ���⍇��(�e�i�ڃ��b�g�g���[�X)��`
    lv_sql_01 := 'SELECT itp.item_id '
              ||       ',itp.lot_id '
              ||       ',SUM( itp.trans_qty ) '
              ||       ',gbh.batch_id '
              ||       ',ximv.item_no '
              ||       ',ximv.item_name '
              ||       ',ilm.lot_no '
              ||       ',itp.whse_code '
              ||       ',gbh.batch_no batch_no'
              ||       ',gmd.attribute17 '
              ||       ',grb.routing_no '
              ||       ',bc.batch_no  turn_batch_no'
              ||       ',bc.attribute11 '
              || 'FROM  ic_tran_pnd          itp '
              ||      ',ic_lots_mst          ilm '
              ||      ',xxcmn_item_mst2_v    ximv'
              ||      ',gme_material_details gmd '
              ||      ',gme_batch_header     gbh '
              ||      ',gmd_routings_b       grb '
              ||      ',( SELECT itp.item_id '
              ||               ',itp.lot_id '
              ||               ',gbh.batch_id '
              ||               ',gbh.batch_no '
              ||               ',gmd.attribute11 '
              ||         'FROM ic_tran_pnd          itp '
              ||             ',gme_material_details gmd '
              ||             ',gme_batch_header     gbh '
              ||         'WHERE itp.doc_type      = :para_doc_type '
              ||         'AND   itp.completed_ind = :para_comp_ind '
              ||         'AND   itp.line_type    IN (:para_line_type_03) '
              ||         'AND   itp.doc_line      = gmd.line_no '
              ||         'AND   itp.doc_id        = gmd.batch_id '
              ||         'AND   itp.item_id       = gmd.item_id '
              ||         'AND   gmd.batch_id      = gbh.batch_id '
              ||         'GROUP BY itp.item_id '
              ||                 ',itp.lot_id '
              ||                 ',gbh.batch_id '
              ||                 ',gbh.batch_no '
              ||                 ',gmd.attribute11 '
              ||       ') bc '
              || 'WHERE  itp.doc_type            = :para_doc_type '
              || 'AND    itp.completed_ind       = :para_comp_ind '
              || 'AND    itp.line_type           IN (:para_line_type_01,:para_line_type_02) '
              || 'AND    itp.doc_line            = gmd.line_no '
              || 'AND    itp.doc_id              = gmd.batch_id '
              || 'AND    itp.item_id             = gmd.item_id '
              || 'AND    gmd.batch_id            = gbh.batch_id '
              || 'AND    gbh.formula_id          IS NOT NULL '
              || 'AND    itp.item_id             = ximv.item_id '
              || 'AND    itp.item_id             = ilm.item_id '
              || 'AND    itp.lot_id              = ilm.lot_id '
-- S 2008/05/27 1.1 ADD BY M.Ikeda ------------------------------------------------------------ S --
              || 'AND    ilm.lot_id             <> 0'
-- E 2008/05/27 1.1 ADD BY M.Ikeda ------------------------------------------------------------ E --
              || 'AND    itp.item_id             = bc.item_id(+) '
              || 'AND    itp.lot_id              = bc.lot_id(+) '
-- S 2008/05/27 1.1 DEL BY M.Ikeda ------------------------------------------------------------ S --
--              || 'AND    gbh.batch_id           <> bc.batch_id '
-- E 2008/05/27 1.1 DEL BY M.Ikeda ------------------------------------------------------------ E --
              || 'AND    gbh.routing_id          = grb.routing_id '
              || 'AND    ximv.start_date_active <= trunc(itp.last_update_date) '
              || 'AND    ximv.end_date_active   >= trunc(itp.last_update_date) '
              || 'AND    (( gbh.batch_status    <> :para_batch_status ) '
              || 'OR      ( gbh.attribute4      <> :para_batch_status )) '
              || 'GROUP BY itp.item_id '
              ||         ',itp.lot_id '
              ||         ',gbh.batch_id '
              ||         ',ximv.item_no '
              ||         ',ximv.item_name '
              ||         ',ilm.lot_no '
              ||         ',itp.whse_code '
              ||         ',gbh.batch_no '
              ||         ',gmd.attribute17 '
              ||         ',grb.routing_no '
              ||         ',bc.batch_no '
              ||         ',bc.attribute11 '
              || 'HAVING   SUM( itp.trans_qty ) <> 0 '
              || 'ORDER BY itp.item_id '
              ||         ',itp.lot_id ';
--
    -- ���⍇��(�q�i�ڃ��b�g�g���[�X)��`
    lv_sql_02 := 'SELECT itp.item_id '
              ||       ',itp.lot_id '
              ||       ',SUM( itp.trans_qty ) '
              ||       ',gbh.batch_id '
              ||       ',ximv.item_no '
              ||       ',ximv.item_name '
              ||       ',ilm.lot_no '
              || 'FROM   ic_tran_pnd          itp '
              ||       ',ic_lots_mst          ilm '
              ||       ',xxcmn_item_mst2_v    ximv'
              ||       ',gme_material_details gmd '
              ||       ',gme_batch_header     gbh '
              || 'WHERE  itp.doc_type            = :para_doc_type '
              || 'AND    itp.completed_ind       = :para_comp_ind '
              || 'AND    itp.line_type           IN (:para_line_type_03) '
              || 'AND    itp.doc_line            = gmd.line_no '
              || 'AND    itp.doc_id              = gmd.batch_id '
              || 'AND    itp.item_id             = gmd.item_id '
              || 'AND    gmd.batch_id            = gbh.batch_id '
              || 'AND    itp.item_id             = ximv.item_id '
              || 'AND    itp.item_id             = ilm.item_id '
              || 'AND    itp.lot_id              = ilm.lot_id '
-- S 2008/05/27 1.1 ADD BY M.Ikeda ------------------------------------------------------------ S --
              || 'AND    ilm.lot_id             <> 0'
-- E 2008/05/27 1.1 ADD BY M.Ikeda ------------------------------------------------------------ E --
              || 'AND    ximv.start_date_active <= trunc(itp.last_update_date) '
              || 'AND    ximv.end_date_active   >= trunc(itp.last_update_date) '
              || 'AND    (( gbh.batch_status    <> :para_batch_status ) '
              || 'OR      ( gbh.attribute4      <> :para_batch_status )) '
              || 'GROUP BY itp.item_id '
              ||         ',itp.lot_id '
              ||         ',gbh.batch_id '
              ||         ',ximv.item_no '
              ||         ',ximv.item_name '
              ||         ',ilm.lot_no '
              || 'HAVING   SUM( itp.trans_qty ) <> 0 '
              || 'ORDER BY itp.item_id '
              ||         ',itp.lot_id ';
--
    -- ���⍇��(�e�i�ڃg���[�X�o�b�N)��`
    lv_sql_03 := 'SELECT itp.item_id '
              ||       ',itp.lot_id '
              ||       ',SUM( itp.trans_qty ) '
              ||       ',gbh.batch_id '
              ||       ',ximv.item_no '
              ||       ',ximv.item_name '
              ||       ',ilm.lot_no '
              ||       ',itp.whse_code '
              ||       ',bp.batch_no  batch_no'
              ||       ',bp.attribute17 '
              ||       ',grb.routing_no '
              ||       ',gbh.batch_no turn_batch_no'
              ||       ',gmd.attribute11 '
              || 'FROM  ic_tran_pnd          itp '
              ||      ',ic_lots_mst          ilm '
              ||      ',xxcmn_item_mst2_v    ximv'
              ||      ',gme_material_details gmd '
              ||      ',gme_batch_header     gbh '
              ||      ',gmd_routings_b       grb '
              ||      ',( SELECT itp.item_id '
              ||               ',itp.lot_id '
              ||               ',gbh.batch_id '
              ||               ',gbh.batch_no '
              ||               ',gmd.attribute17 '
              ||         'FROM ic_tran_pnd          itp '
              ||             ',gme_material_details gmd '
              ||             ',gme_batch_header     gbh '
              ||         'WHERE itp.doc_type      = :para_doc_type '
              ||         'AND   itp.completed_ind = :para_comp_ind '
              ||         'AND   itp.line_type    IN (:para_line_type_01,:para_line_type_02) '
              ||         'AND   itp.doc_line      = gmd.line_no '
              ||         'AND   itp.doc_id        = gmd.batch_id '
              ||         'AND   itp.item_id       = gmd.item_id '
              ||         'AND   gmd.batch_id      = gbh.batch_id '
              ||         'GROUP BY itp.item_id '
              ||                 ',itp.lot_id '
              ||                 ',gbh.batch_id '
              ||                 ',gbh.batch_no '
              ||                 ',gmd.attribute17 '
              ||       ') bp '
              || 'WHERE  itp.doc_type            = :para_doc_type '
              || 'AND    itp.completed_ind       = :para_comp_ind '
              || 'AND    itp.line_type           IN (:para_line_type_03) '
              || 'AND    itp.doc_line            = gmd.line_no '
              || 'AND    itp.doc_id              = gmd.batch_id '
              || 'AND    itp.item_id             = gmd.item_id '
              || 'AND    gmd.batch_id            = gbh.batch_id '
              || 'AND    itp.item_id             = ximv.item_id '
              || 'AND    itp.item_id             = ilm.item_id '
              || 'AND    itp.lot_id              = ilm.lot_id '
-- S 2008/05/27 1.1 ADD BY M.Ikeda ------------------------------------------------------------ S --
              || 'AND    ilm.lot_id             <> 0'
-- E 2008/05/27 1.1 ADD BY M.Ikeda ------------------------------------------------------------ E --
              || 'AND    itp.item_id             = bp.item_id(+) '
              || 'AND    itp.lot_id              = bp.lot_id(+) '
              || 'AND    gbh.routing_id          = grb.routing_id '
              || 'AND    ximv.start_date_active <= trunc(itp.last_update_date) '
              || 'AND    ximv.end_date_active   >= trunc(itp.last_update_date) '
              || 'AND    (( gbh.batch_status    <> :para_batch_status ) '
              || 'OR      ( gbh.attribute4      <> :para_batch_status )) '
              || 'GROUP BY itp.item_id '
              ||         ',itp.lot_id '
              ||         ',gbh.batch_id '
              ||         ',ximv.item_no '
              ||         ',ximv.item_name '
              ||         ',ilm.lot_no '
              ||         ',itp.whse_code '
              ||         ',bp.batch_no '
              ||         ',bp.attribute17 '
              ||         ',grb.routing_no '
              ||         ',gbh.batch_no '
              ||         ',gmd.attribute11 '
              || 'HAVING   SUM( itp.trans_qty ) <> 0 '
              || 'ORDER BY itp.item_id '
              ||         ',itp.lot_id ';
--
    -- ���⍇��(�q�i�ڃg���[�X�o�b�N)��`
    lv_sql_04 := 'SELECT itp.item_id '
              ||       ',itp.lot_id '
              ||       ',SUM( itp.trans_qty ) '
              ||       ',gbh.batch_id '
              ||       ',ximv.item_no '
              ||       ',ximv.item_name '
              ||       ',ilm.lot_no '
              || 'FROM   ic_tran_pnd          itp '
              ||       ',ic_lots_mst          ilm '
              ||       ',xxcmn_item_mst2_v    ximv'
              ||       ',gme_material_details gmd '
              ||       ',gme_batch_header     gbh '
              || 'WHERE  itp.doc_type            = :para_doc_type '
              || 'AND    itp.completed_ind       = :para_comp_ind '
              || 'AND    itp.line_type           IN (:para_line_type_01,:para_line_type_02) '
              || 'AND    itp.doc_line            = gmd.line_no '
              || 'AND    itp.doc_id              = gmd.batch_id '
              || 'AND    itp.item_id             = gmd.item_id '
              || 'AND    gmd.batch_id            = gbh.batch_id '
              || 'AND    gbh.formula_id          IS NOT NULL '
              || 'AND    itp.item_id             = ximv.item_id '
              || 'AND    itp.item_id             = ilm.item_id '
              || 'AND    itp.lot_id              = ilm.lot_id '
-- S 2008/05/27 1.1 ADD BY M.Ikeda ------------------------------------------------------------ S --
              || 'AND    ilm.lot_id             <> 0'
-- E 2008/05/27 1.1 ADD BY M.Ikeda ------------------------------------------------------------ E --
              || 'AND    ximv.start_date_active <= trunc(itp.last_update_date) '
              || 'AND    ximv.end_date_active   >= trunc(itp.last_update_date) '
              || 'AND    (( gbh.batch_status    <> :para_batch_status ) '
              || 'OR      ( gbh.attribute4      <> :para_batch_status )) '
              || 'GROUP BY itp.item_id '
              ||         ',itp.lot_id '
              ||         ',gbh.batch_id '
              ||         ',ximv.item_no '
              ||         ',ximv.item_name '
              ||         ',ilm.lot_no '
              || 'HAVING   SUM( itp.trans_qty ) <> 0 '
              || 'ORDER BY itp.item_id '
              ||         ',itp.lot_id ';
--
    -- �ʖ�(�e)
    lv_sql_par  := ' pp ';
--
    -- �ʖ�(�q)
    lv_sql_chi  := ' cp ';
--
    -- WHERE��(��`)��`
    lv_sql_where_01 := 'WHERE pp.batch_id    = cp.batch_id(+) '
                    || 'AND   pp.lot_id     <> cp.lot_id(+) '
                    || 'AND   pp.lot_id      = ilm.lot_id '
                    || 'AND   pp.item_id     = ilm.item_id '
                    || 'AND   cp.item_id     IS NOT NULL '
                    || 'AND   pp.item_id     = :para_item_id '
                    || 'AND   pp.lot_id      = :para_lot_id ';
--
    IF ( iv_batch_id IS NOT NULL ) THEN
      lv_sql_where_01 := lv_sql_where_01 
                    || 'AND   pp.batch_id    > ' || iv_batch_id || ' ';
    END IF;
--
    -- WHERE��(��`)��`
    lv_sql_where_02 := 'WHERE pp.batch_id    = cp.batch_id(+) '
                    || 'AND   pp.lot_id     <> cp.lot_id(+) '
                    || 'AND   pp.lot_id      = ilm.lot_id '
                    || 'AND   pp.item_id     = ilm.item_id '
                    || 'AND   cp.item_id     IS NOT NULL '
                    || 'AND   pp.item_id     = :para_item_id '
                    || 'AND   pp.lot_id      = :para_lot_id ';
--
    IF ( iv_batch_id IS NOT NULL ) THEN
      lv_sql_where_02 := lv_sql_where_02 
                    || 'AND   pp.batch_id    < ' || iv_batch_id || ' ';
    END IF;
--
    -- �o�͐���(1�F���b�g�g���[�X)
    IF ( iv_out_control = cv_out_trace ) THEN
--
      lv_sql_sel := '';
      lv_sql_sel := lv_sql_sel || lv_sql_select_01 || lv_sql_select_02 || lv_sql_from || cv_sql_l_block;
      lv_sql_sel := lv_sql_sel || lv_sql_01        || cv_sql_r_block   || lv_sql_par  || cv_sql_dot || cv_sql_l_block;
      lv_sql_sel := lv_sql_sel || lv_sql_02        || cv_sql_r_block   || lv_sql_chi  || lv_sql_where_01;
--
      EXECUTE IMMEDIATE lv_sql_sel BULK COLLECT INTO ot_itp_tbl USING cv_doc_type
                                                                     ,cv_comp_ind
                                                                     ,cv_line_type_03
                                                                     ,cv_doc_type
                                                                     ,cv_comp_ind
                                                                     ,cv_line_type_01
                                                                     ,cv_line_type_02
                                                                     ,cv_batch_status
                                                                     ,cv_batch_status
                                                                     ,cv_doc_type
                                                                     ,cv_comp_ind
                                                                     ,cv_line_type_03
                                                                     ,cv_batch_status
                                                                     ,cv_batch_status
                                                                     ,iv_item_id
                                                                     ,iv_lot_id;
--
    -- �o�͐���(2�F���b�g�g���[�X�o�b�N)
    ELSIF ( iv_out_control = cv_out_back ) THEN
--
      lv_sql_sel := '';
      lv_sql_sel := lv_sql_sel || lv_sql_select_01 || lv_sql_select_02 || lv_sql_from || cv_sql_l_block;
      lv_sql_sel := lv_sql_sel || lv_sql_03        || cv_sql_r_block   || lv_sql_par  || cv_sql_dot || cv_sql_l_block;
      lv_sql_sel := lv_sql_sel || lv_sql_04        || cv_sql_r_block   || lv_sql_chi  || lv_sql_where_02;
--
      EXECUTE IMMEDIATE lv_sql_sel BULK COLLECT INTO ot_itp_tbl USING cv_doc_type
                                                                     ,cv_comp_ind
                                                                     ,cv_line_type_01
                                                                     ,cv_line_type_02
                                                                     ,cv_doc_type
                                                                     ,cv_comp_ind
                                                                     ,cv_line_type_03
                                                                     ,cv_batch_status
                                                                     ,cv_batch_status
                                                                     ,cv_doc_type
                                                                     ,cv_comp_ind
                                                                     ,cv_line_type_01
                                                                     ,cv_line_type_02
                                                                     ,cv_batch_status
                                                                     ,cv_batch_status
                                                                     ,iv_item_id
                                                                     ,iv_lot_id;
--
    END IF;
--
    -- ���Y�n���̎擾�`�F�b�N
    -- �q�i�ڏ��̍݌ɏ�񂪑��݂��Ȃ��ꍇ�A��������擾
    SELECT itp.item_id
          ,ilm.lot_id
          ,ximv.item_no
          ,ximv.item_name
          ,ilm.lot_no
          ,itp.whse_code
          ,rct.transaction_date
          ,rsh.receipt_num
          ,pha.segment1
          ,ven1.supp_name
          ,ven1.segment1
          ,ven2.trader_name
          ,ilm.attribute1
          ,ilm.attribute2
          ,ilm.attribute3
          ,ilm.attribute4
          ,ilm.attribute5
          ,ilm.attribute6
          ,ilm.attribute10
          ,ilm.attribute11
          ,ilm.attribute12
          ,ilm.attribute13
          ,ilm.attribute14
          ,ilm.attribute15
          ,ilm.attribute16
          ,ilm.attribute18
          ,ilm.attribute22
    BULK COLLECT INTO ot_rcv_tbl
    FROM   ic_tran_pnd          itp
          ,xxcmn_item_mst2_v    ximv
          ,ic_lots_mst          ilm
          ,rcv_shipment_headers rsh
          ,rcv_shipment_lines   rsl
          ,rcv_transactions     rct
          ,po_headers_all       pha
          ,( SELECT xpv1.segment1
                   ,xpv1.vendor_name supp_name
                   ,xpv1.vendor_id   supp_id
             FROM   po_headers_all   pha
                   ,xxcmn_vendors2_v xpv1
             WHERE  pha.vendor_id    = xpv1.vendor_id
             GROUP BY xpv1.segment1
                     ,xpv1.vendor_name
                     ,xpv1.vendor_id
           ) ven1
          ,( SELECT xpv2.vendor_name trader_name
                   ,xpv2.vendor_id   trader_id
             FROM   po_headers_all   pha
                   ,xxcmn_vendors2_v xpv2
             WHERE  pha.attribute3   = xpv2.vendor_id
             GROUP BY xpv2.vendor_name
                     ,xpv2.vendor_id
           ) ven2
    WHERE itp.item_id             = iv_item_id
    AND   itp.lot_id              = iv_lot_id
    AND   itp.item_id             = ximv.item_id
    AND   itp.item_id             = ilm.item_id
    AND   itp.lot_id              = ilm.lot_id
-- S 2008/05/27 1.1 ADD BY M.Ikeda ------------------------------------------------------------ S --
    AND   ilm.lot_id             <> 0
-- E 2008/05/27 1.1 ADD BY M.Ikeda ------------------------------------------------------------ E --
    AND   itp.doc_line            = rsl.line_num
    AND   itp.doc_id              = rsl.shipment_header_id
    AND   rsl.shipment_header_id  = rct.shipment_header_id
    AND   rsl.shipment_line_id    = rct.shipment_line_id
    AND   rsl.shipment_header_id  = rsh.shipment_header_id
    AND   rct.transaction_type    = gv_rcv_tran_type
    AND   rsl.po_header_id        = pha.po_header_id
    AND   ximv.start_date_active <= trunc(itp.last_update_date)
    AND   ximv.end_date_active   >= trunc(itp.last_update_date)
    AND   pha.vendor_id           = ven1.supp_id(+)
    AND   pha.attribute3          = ven2.trader_id(+)
    AND   pha.org_id              = gn_org_id;
--
    IF ( (ot_itp_tbl.COUNT = 0) AND (ot_rcv_tbl.COUNT = 0) ) THEN
      RAISE NO_DATA_FOUND;
    END IF;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ov_retcode := gv_status_warn;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_lots_data;
--
  /**********************************************************************************
   * Procedure Name   : put_lots_data
   * Description      : ���b�g�n���f�[�^�i�[(A-4/A-6/A-8/A-10/A-12)
   ***********************************************************************************/
  PROCEDURE put_lots_data(
    in_total_cnt        IN OUT NOCOPY NUMBER,           -- ��������
    in_cnt              IN     NUMBER,                  -- ���[�v�J�E���g
    iv_out_control      IN     VARCHAR2,                -- �o�͐���
    in_level_num        IN     NUMBER,                  -- �K�w
    it_itp_tbl          IN     mst_itp_tbl,             -- ���Y���
    it_rcv_tbl          IN     mst_rcv_tbl,             -- ������
    ov_errbuf           OUT    NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT    NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT    NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'put_lots_data';         -- �v���O������
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
    ln_rcv_cnt              NUMBER                  := 0;                       -- ��������J�E���g
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
    -- ***      ���b�g�n���f�[�^�i�[       ***
    -- ***************************************
    -- ���������̃J�E���g�A�b�v
    in_total_cnt := in_total_cnt + 1;
    -- �敪
    gt_division(in_total_cnt) := iv_out_control;
    -- ���x���ԍ�
    gt_level_num(in_total_cnt) := in_level_num;
--
    -- ���Y�n���̊i�[
    IF ((it_itp_tbl.COUNT > 0) AND (it_itp_tbl.COUNT >= in_cnt)) THEN
      gt_item_code(in_total_cnt)        := NVL(it_itp_tbl(in_cnt).p_item_no,'');
      gt_item_name(in_total_cnt)        := NVL(it_itp_tbl(in_cnt).p_item_name,'');
      gt_lot_num(in_total_cnt)          := NVL(it_itp_tbl(in_cnt).p_lot_no,'');
      gt_trace_item_code(in_total_cnt)  := NVL(it_itp_tbl(in_cnt).c_item_no,'');
      gt_trace_item_name(in_total_cnt)  := NVL(it_itp_tbl(in_cnt).c_item_name,'');
      gt_trace_lot_num(in_total_cnt)    := NVL(it_itp_tbl(in_cnt).c_lot_no,'');
      gt_batch_num(in_total_cnt)        := NVL(it_itp_tbl(in_cnt).batch_num,'');
      gt_batch_date(in_total_cnt)       := NVL(it_itp_tbl(in_cnt).batch_date,'');
      gt_whse_code(in_total_cnt)        := NVL(it_itp_tbl(in_cnt).p_whse_code,'');
      gt_line_num(in_total_cnt)         := NVL(it_itp_tbl(in_cnt).line_num,'');
      gt_turn_date(in_total_cnt)        := NVL(it_itp_tbl(in_cnt).turn_date,'');
      gt_turn_batch_num(in_total_cnt)   := NVL(it_itp_tbl(in_cnt).turn_batch_num,'');
      gt_receipt_date(in_total_cnt)     := '';
      gt_receipt_num(in_total_cnt)      := '';
      gt_order_num(in_total_cnt)        := '';
      gt_supp_name(in_total_cnt)        := '';
      gt_supp_code(in_total_cnt)        := '';
      gt_trader_name(in_total_cnt)      := '';
      gt_lot_date(in_total_cnt)         := NVL(it_itp_tbl(in_cnt).lot_date,'');
      gt_lot_sign(in_total_cnt)         := NVL(it_itp_tbl(in_cnt).lot_sign,'');
      gt_best_bfr_date(in_total_cnt)    := NVL(it_itp_tbl(in_cnt).best_bfr_date,'');
      gt_dlv_date_first(in_total_cnt)   := NVL(it_itp_tbl(in_cnt).dlv_date_first,'');
      gt_dlv_date_last(in_total_cnt)    := NVL(it_itp_tbl(in_cnt).dlv_date_last,'');
      gt_stock_ins_amount(in_total_cnt) := NVL(it_itp_tbl(in_cnt).stock_ins_amount,'');
      gt_tea_period_dev(in_total_cnt)   := NVL(it_itp_tbl(in_cnt).tea_period_dev,'');
      gt_product_year(in_total_cnt)     := NVL(it_itp_tbl(in_cnt).product_year,'');
      gt_product_home(in_total_cnt)     := NVL(it_itp_tbl(in_cnt).product_home,'');
      gt_product_type(in_total_cnt)     := NVL(it_itp_tbl(in_cnt).product_type,'');
      gt_product_ranc_1(in_total_cnt)   := NVL(it_itp_tbl(in_cnt).product_ranc_1,'');
      gt_product_ranc_2(in_total_cnt)   := NVL(it_itp_tbl(in_cnt).product_ranc_2,'');
      gt_product_slip_dev(in_total_cnt) := NVL(it_itp_tbl(in_cnt).product_slip_dev,'');
      gt_description(in_total_cnt)      := NVL(it_itp_tbl(in_cnt).description,'');
      gt_inspect_req(in_total_cnt)      := NVL(it_itp_tbl(in_cnt).inspect_req,'');

      -- WHO�J�����̊i�[
      gt_created_by(in_total_cnt)             := gn_created_by;
      gt_creation_date(in_total_cnt)          := gd_creation_date;
      gt_last_updated_by(in_total_cnt)        := gn_last_update_by;
      gt_last_update_date(in_total_cnt)       := gd_last_update_date;
      gt_last_update_login(in_total_cnt)      := gn_last_update_login;
      gt_request_id(in_total_cnt)             := gn_request_id;
      gt_program_id(in_total_cnt)             := gn_program_id;
      gt_program_application_id(in_total_cnt) := gn_program_application_id;
      gt_program_update_date(in_total_cnt)    := gd_program_update_date;
--
    ELSIF (it_rcv_tbl.COUNT > 0) THEN
      -- �����������
      ln_rcv_cnt := in_cnt - it_itp_tbl.COUNT;
--
      -- ����n���̊i�[
      gt_item_code(in_total_cnt)        := NVL(it_rcv_tbl(ln_rcv_cnt).p_item_no,'');
      gt_item_name(in_total_cnt)        := NVL(it_rcv_tbl(ln_rcv_cnt).p_item_name,'');
      gt_lot_num(in_total_cnt)          := NVL(it_rcv_tbl(ln_rcv_cnt).p_lot_no,'');
      gt_trace_item_code(in_total_cnt)  := '';
      gt_trace_item_name(in_total_cnt)  := '';
      gt_trace_lot_num(in_total_cnt)    := '';
      gt_batch_num(in_total_cnt)        := '';
      gt_batch_date(in_total_cnt)       := '';
      gt_whse_code(in_total_cnt)        := NVL(it_rcv_tbl(ln_rcv_cnt).whse_code,'');
      gt_line_num(in_total_cnt)         := '';
      gt_turn_date(in_total_cnt)        := '';
      gt_turn_batch_num(in_total_cnt)   := '';
      gt_receipt_date(in_total_cnt)     := NVL(it_rcv_tbl(ln_rcv_cnt).receipt_date,'');
      gt_receipt_num(in_total_cnt)      := NVL(it_rcv_tbl(ln_rcv_cnt).receipt_num,'');
      gt_order_num(in_total_cnt)        := NVL(it_rcv_tbl(ln_rcv_cnt).order_num,'');
      gt_supp_name(in_total_cnt)        := NVL(it_rcv_tbl(ln_rcv_cnt).supp_name,'');
      gt_supp_code(in_total_cnt)        := NVL(it_rcv_tbl(ln_rcv_cnt).supp_code,'');
      gt_trader_name(in_total_cnt)      := NVL(it_rcv_tbl(ln_rcv_cnt).trader_name,'');
      gt_lot_date(in_total_cnt)         := NVL(it_rcv_tbl(ln_rcv_cnt).lot_date,'');
      gt_lot_sign(in_total_cnt)         := NVL(it_rcv_tbl(ln_rcv_cnt).lot_sign,'');
      gt_best_bfr_date(in_total_cnt)    := NVL(it_rcv_tbl(ln_rcv_cnt).best_bfr_date,'');
      gt_dlv_date_first(in_total_cnt)   := NVL(it_rcv_tbl(ln_rcv_cnt).dlv_date_first,'');
      gt_dlv_date_last(in_total_cnt)    := NVL(it_rcv_tbl(ln_rcv_cnt).dlv_date_last,'');
      gt_stock_ins_amount(in_total_cnt) := NVL(it_rcv_tbl(ln_rcv_cnt).stock_ins_amount,'');
      gt_tea_period_dev(in_total_cnt)   := NVL(it_rcv_tbl(ln_rcv_cnt).tea_period_dev,'');
      gt_product_year(in_total_cnt)     := NVL(it_rcv_tbl(ln_rcv_cnt).product_year,'');
      gt_product_home(in_total_cnt)     := NVL(it_rcv_tbl(ln_rcv_cnt).product_home,'');
      gt_product_type(in_total_cnt)     := NVL(it_rcv_tbl(ln_rcv_cnt).product_type,'');
      gt_product_ranc_1(in_total_cnt)   := NVL(it_rcv_tbl(ln_rcv_cnt).product_ranc_1,'');
      gt_product_ranc_2(in_total_cnt)   := NVL(it_rcv_tbl(ln_rcv_cnt).product_ranc_2,'');
      gt_product_slip_dev(in_total_cnt) := NVL(it_rcv_tbl(ln_rcv_cnt).product_slip_dev,'');
      gt_description(in_total_cnt)      := NVL(it_rcv_tbl(ln_rcv_cnt).description,'');
      gt_inspect_req(in_total_cnt)      := NVL(it_rcv_tbl(ln_rcv_cnt).inspect_req,'');
--
      -- WHO�J�����̊i�[
      gt_created_by(in_total_cnt)             := gn_created_by;
      gt_creation_date(in_total_cnt)          := gd_creation_date;
      gt_last_updated_by(in_total_cnt)        := gn_last_update_by;
      gt_last_update_date(in_total_cnt)       := gd_last_update_date;
      gt_last_update_login(in_total_cnt)      := gn_last_update_login;
      gt_request_id(in_total_cnt)             := gn_request_id;
      gt_program_id(in_total_cnt)             := gn_program_id;
      gt_program_application_id(in_total_cnt) := gn_program_application_id;
      gt_program_update_date(in_total_cnt)    := gd_program_update_date;
--
    END IF;
--
--#################################  �Œ��O������ START   ####################################
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END put_lots_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_lots_data
   * Description      : ���b�g�n���f�[�^�ꊇ�o�^(A-13)
   ***********************************************************************************/
  PROCEDURE insert_lots_data(
    ov_errbuf           OUT    NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT    NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT    NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'insert_lots_data';      -- �v���O������
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
    -- ***        �i�ڃ}�X�^�ꊇ�X�V       ***
    -- ***************************************
      FORALL itp_cnt IN 1 .. gt_division.COUNT
        -- ���b�g�g���[�X�A�h�I���ꊇ�o�^
        INSERT INTO xxcmn_lot_trace
          ( division
           ,level_num
           ,item_code
           ,item_name
           ,lot_num
           ,trace_item_code
           ,trace_item_name
           ,trace_lot_num
           ,batch_num
           ,batch_date
           ,whse_code
           ,line_num
           ,turn_date
           ,turn_batch_num
           ,receipt_date
           ,receipt_num
           ,order_num
           ,supp_name
           ,supp_code
           ,trader_name
           ,lot_date
           ,lot_sign
           ,best_bfr_date
           ,dlv_date_first
           ,dlv_date_last
           ,stock_ins_amount
           ,tea_period_dev
           ,product_year
           ,product_home
           ,product_type
           ,product_ranc_1
           ,product_ranc_2
           ,product_slip_dev
           ,description
           ,inspect_req
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
        (
          gt_division(itp_cnt)
         ,gt_level_num(itp_cnt)
         ,gt_item_code(itp_cnt)
         ,gt_item_name(itp_cnt)
         ,gt_lot_num(itp_cnt)
         ,gt_trace_item_code(itp_cnt)
         ,gt_trace_item_name(itp_cnt)
         ,gt_trace_lot_num(itp_cnt)
         ,gt_batch_num(itp_cnt)
         ,FND_DATE.STRING_TO_DATE(gt_batch_date(itp_cnt),'YYYY/MM/DD')
         ,gt_whse_code(itp_cnt)
         ,gt_line_num(itp_cnt)
         ,FND_DATE.STRING_TO_DATE(gt_turn_date(itp_cnt),'YYYY/MM/DD')
         ,gt_turn_batch_num(itp_cnt)
         ,gt_receipt_date(itp_cnt)
         ,gt_receipt_num(itp_cnt)
         ,gt_order_num(itp_cnt)
         ,gt_supp_name(itp_cnt)
         ,gt_supp_code(itp_cnt)
         ,gt_trader_name(itp_cnt)
         ,FND_DATE.STRING_TO_DATE(gt_lot_date(itp_cnt),'YYYY/MM/DD')
         ,gt_lot_sign(itp_cnt)
         ,FND_DATE.STRING_TO_DATE(gt_best_bfr_date(itp_cnt),'YYYY/MM/DD')
         ,FND_DATE.STRING_TO_DATE(gt_dlv_date_first(itp_cnt),'YYYY/MM/DD')
         ,FND_DATE.STRING_TO_DATE(gt_dlv_date_last(itp_cnt),'YYYY/MM/DD')
         ,gt_stock_ins_amount(itp_cnt)
         ,gt_tea_period_dev(itp_cnt)
         ,gt_product_year(itp_cnt)
         ,gt_product_home(itp_cnt)
         ,gt_product_type(itp_cnt)
         ,gt_product_ranc_1(itp_cnt)
         ,gt_product_ranc_2(itp_cnt)
         ,gt_product_slip_dev(itp_cnt)
         ,gt_description(itp_cnt)
         ,gt_inspect_req(itp_cnt)
         ,gt_created_by(itp_cnt)
         ,gt_creation_date(itp_cnt)
         ,gt_last_updated_by(itp_cnt)
         ,gt_last_update_date(itp_cnt)
         ,gt_last_update_login(itp_cnt)
         ,gt_request_id(itp_cnt)
         ,gt_program_id(itp_cnt)
         ,gt_program_application_id(itp_cnt)
         ,gt_program_update_date(itp_cnt)
        );
--
--#################################  �Œ��O������ START   ####################################
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END insert_lots_data;
--
  /***********************************************************************************
   * Procedure Name   : disp_report
   * Description      : �������ʃ��|�[�g�o��
   ***********************************************************************************/
  PROCEDURE disp_report(
    ov_errbuf           OUT    NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT    NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT    NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_dspbuf               VARCHAR2(5000);                                     -- �G���[�E���b�Z�[�W
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
    -- �������ʃ��|�[�g�̏o��
    <<disp_report_loop>>
    FOR report_cnt IN 1 .. gt_division.COUNT
    LOOP
--
      --���̓f�[�^�_���v�o��
      -- �i�ڊ֘A���
      lv_dspbuf := '';
      lv_dspbuf := gt_division(report_cnt)                                || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_level_num(report_cnt)                  || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_item_code(report_cnt)                  || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_item_name(report_cnt)                  || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_lot_num(report_cnt)                    || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_trace_item_code(report_cnt)            || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_trace_item_name(report_cnt)            || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_trace_lot_num(report_cnt)              || gv_msg_pnt;
--
      -- ���Y�n���
      lv_dspbuf := lv_dspbuf || gt_batch_num(report_cnt)  || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_batch_date(report_cnt) || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_whse_code(report_cnt)  || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_line_num(report_cnt)   || gv_msg_pnt;
--
      -- ����n���
      lv_dspbuf := lv_dspbuf || gt_turn_date(report_cnt)      || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_turn_batch_num(report_cnt) || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || TO_CHAR(gt_receipt_date(report_cnt),'YYYY/MM/DD')   || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_receipt_num(report_cnt)    || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_order_num(report_cnt)      || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_supp_name(report_cnt)      || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_supp_code(report_cnt)      || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_trader_name(report_cnt)    || gv_msg_pnt;
--
      -- OPM���b�g���
      lv_dspbuf := lv_dspbuf || gt_lot_date(report_cnt)         || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_lot_sign(report_cnt)         || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_best_bfr_date(report_cnt)    || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || TO_CHAR(FND_DATE.STRING_TO_DATE(gt_dlv_date_first(report_cnt),'YYYY/MM/DD'),'YYYY/MM/DD')   || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || TO_CHAR(FND_DATE.STRING_TO_DATE(gt_dlv_date_last(report_cnt),'YYYY/MM/DD'),'YYYY/MM/DD')    || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_stock_ins_amount(report_cnt) || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_tea_period_dev(report_cnt)   || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_product_year(report_cnt)     || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_product_home(report_cnt)     || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_product_type(report_cnt)     || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_product_ranc_1(report_cnt)   || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_product_ranc_2(report_cnt)   || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_product_slip_dev(report_cnt) || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_description(report_cnt)      || gv_msg_pnt;
      lv_dspbuf := lv_dspbuf || gt_inspect_req(report_cnt)      || gv_msg_pnt;
--
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_dspbuf);
--
    END LOOP disp_report_loop;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END disp_report;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_item_code        IN     VARCHAR2,                -- �i�ڃR�[�h
    iv_lot_no           IN     VARCHAR2,                -- ���b�gNo
    iv_out_control      IN     VARCHAR2,                -- �o�͐���
    ov_errbuf           OUT    VARCHAR2,                -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT    VARCHAR2,                -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT    VARCHAR2)                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    cv_item_code            CONSTANT VARCHAR2(20)   := '�i�ڃR�[�h';            -- �p�����[�^���F�i�ڃR�[�h
    cv_lot_no               CONSTANT VARCHAR2(20)   := '���b�gNo';              -- �p�����[�^���F���b�gNo
    cv_out_control          CONSTANT VARCHAR2(20)   := '�o�͐���';              -- �p�����[�^���F�o�͐���
--
    -- *** ���[�J���ϐ� ***
    -- �p�����[�^���
    lv_item_code            VARCHAR2(30)            := iv_item_code;            -- �i�ڃR�[�h
    lv_lot_no               VARCHAR2(30)            := iv_lot_no;               -- ���b�gNo
    lv_out_control          VARCHAR2(30)            := iv_out_control;          -- �o�͐���
--
    -- ���[�v�J�E���g(�K�w)
    ln_cnt_01               NUMBER                  := 0;                       -- ���K�w�J�E���g
    ln_cnt_02               NUMBER                  := 0;                       -- ���K�w�J�E���g
    ln_cnt_03               NUMBER                  := 0;                       -- ��O�K�w�J�E���g
    ln_cnt_04               NUMBER                  := 0;                       -- ��l�K�w�J�E���g
    ln_cnt_05               NUMBER                  := 0;                       -- ��܊K�w�J�E���g
    ln_total_01             NUMBER                  := 0;                       -- ��������
    ln_loop_cnt_01          NUMBER                  := 0;                       -- ���[�v(���K�w)
    ln_loop_cnt_02          NUMBER                  := 0;                       -- ���[�v(���K�w)
    ln_loop_cnt_03          NUMBER                  := 0;                       -- ���[�v(��O�K�w)
    ln_loop_cnt_04          NUMBER                  := 0;                       -- ���[�v(��l�K�w)
    ln_loop_cnt_05          NUMBER                  := 0;                       -- ���[�v(��܊K�w)
--
    -- �K�w���̃p�����[�^
    lv_item_id_01           VARCHAR2(30);                                       -- �i��ID(���K�w)
    lv_item_id_02           VARCHAR2(30);                                       -- �i��ID(���K�w)
    lv_item_id_03           VARCHAR2(30);                                       -- �i��ID(��O�K�w)
    lv_item_id_04           VARCHAR2(30);                                       -- �i��ID(��l�K�w)
    lv_item_id_05           VARCHAR2(30);                                       -- �i��ID(��܊K�w)
    lv_lot_id_01            VARCHAR2(30);                                       -- ���b�gID(���K�w)
    lv_lot_id_02            VARCHAR2(30);                                       -- ���b�gID(���K�w)
    lv_lot_id_03            VARCHAR2(30);                                       -- ���b�gID(��O�K�w)
    lv_lot_id_04            VARCHAR2(30);                                       -- ���b�gID(��l�K�w)
    lv_lot_id_05            VARCHAR2(30);                                       -- ���b�gID(��܊K�w)
    lv_batch_id_02          VARCHAR2(30);                                       -- �o�b�`ID(���K�w)
    lv_batch_id_03          VARCHAR2(30);                                       -- �o�b�`ID(��O�K�w)
    lv_batch_id_04          VARCHAR2(30);                                       -- �o�b�`ID(��l�K�w)
    lv_batch_id_05          VARCHAR2(30);                                       -- �o�b�`ID(��܊K�w)
    lv_level_num_01         NUMBER                  := 1;                       -- �K�w(���K�w)
    lv_level_num_02         NUMBER                  := 2;                       -- �K�w(���K�w)
    lv_level_num_03         NUMBER                  := 3;                       -- �K�w(��O�K�w)
    lv_level_num_04         NUMBER                  := 4;                       -- �K�w(��l�K�w)
    lv_level_num_05         NUMBER                  := 5;                       -- �K�w(��܊K�w)
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

    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ================================
    -- A-1.�p�����[�^�`�F�b�N
    -- ================================
    parameter_check(
      lv_item_code,       -- �i�ڃR�[�h
      lv_lot_no,          -- ���b�gNo
      lv_out_control,     -- �o�͐���
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ================================
    -- A-2.�o�^�Ώۃe�[�u���폜
    -- ================================
    del_lot_trace(
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ================================
    -- A-3.���K�w���b�g�n���f�[�^���o
    -- ================================
--
    -- �����ݒ�
    lv_item_id_01 := gv_item_id;
    lv_lot_id_01  := gv_lot_id;
--
    get_lots_data(
      lv_item_id_01,      -- �i��ID
      lv_lot_id_01,       -- ���b�gID
      NULL,               -- �o�b�`ID
      lv_out_control,     -- �o�͐���
      lv_level_num_01,    -- �K�w
      gt_itp01_tbl,       -- ���Y���(���K�w)
      gt_rcv01_tbl,       -- ������(���K�w)
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �擾�������P���ȏ㑶�݂���ꍇ�̂݁A�Ȍ�̏��������{
    IF (lv_retcode = gv_status_normal) THEN
--
      -- ��������
      ln_loop_cnt_01 := gt_itp01_tbl.COUNT + gt_rcv01_tbl.COUNT;
--
      << lot_trace_loop_01 >>
      FOR ln_cnt_01 IN 1..ln_loop_cnt_01 LOOP
        -- ================================
        -- A-4.���K�w���b�g�n���f�[�^�i�[
        -- ================================
        -- ���[�v�J�E���g(���K�w��)
        put_lots_data(
          ln_total_01,        -- ��������
          ln_cnt_01,          -- ���[�v�J�E���g(���K�w)
          lv_out_control,     -- �o�͐���
          lv_level_num_01,    -- �K�w
          gt_itp01_tbl,       -- ���Y���(���K�w)
          gt_rcv01_tbl,       -- ������(���K�w)
          lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ���K�w�̎q�i�ڂ�e�i�ڂ֒u����
        IF ((gt_itp01_tbl.COUNT > 0) AND (gt_itp01_tbl.COUNT >= ln_cnt_01)) THEN
          IF (gt_itp01_tbl(ln_cnt_01).c_item_no IS NOT NULL) THEN
            lv_item_id_02  := gt_itp01_tbl(ln_cnt_01).c_item_id;
            lv_lot_id_02   := gt_itp01_tbl(ln_cnt_01).c_lot_id;
            lv_batch_id_02 := gt_itp01_tbl(ln_cnt_01).p_batch_id;
--
            -- ================================
            -- A-5.���K�w���b�g�n���f�[�^���o
            -- ================================
            get_lots_data(
              lv_item_id_02,      -- �i��ID
              lv_lot_id_02,       -- ���b�gID
              lv_batch_id_02,     -- �o�b�`ID
              lv_out_control,     -- �o�͐���
              lv_level_num_02,    -- �K�w
              gt_itp02_tbl,       -- ���Y���(���K�w)
              gt_rcv02_tbl,       -- ������(���K�w)
              lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
              lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
              lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--
            -- ��������
            ln_loop_cnt_02 := gt_itp02_tbl.COUNT + gt_rcv02_tbl.COUNT;
--
            << lot_trace_loop_02 >>
            FOR ln_cnt_02 IN 1..ln_loop_cnt_02 LOOP
              -- ================================
              -- A-6.���K�w���b�g�n���f�[�^�i�[
              -- ================================
              -- ���[�v�J�E���g(���K�w��)
              put_lots_data(
                ln_total_01,        -- ��������
                ln_cnt_02,          -- ���[�v�J�E���g(���K�w)
                lv_out_control,     -- �o�͐���
                lv_level_num_02,    -- �K�w
                gt_itp02_tbl,       -- ���Y���(���K�w)
                gt_rcv02_tbl,       -- ������(���K�w)
                lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
                lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
                lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
              IF (lv_retcode = gv_status_error) THEN
                RAISE global_process_expt;
              END IF;
--
              -- ���K�w�̎q�i�ڂ�e�i�ڂ֒u����
              IF ((gt_itp02_tbl.COUNT > 0) AND (gt_itp02_tbl.COUNT >= ln_cnt_02)) THEN
                IF (gt_itp02_tbl(ln_cnt_02).c_item_no IS NOT NULL) THEN
                  lv_item_id_03  := gt_itp02_tbl(ln_cnt_02).c_item_id;
                  lv_lot_id_03   := gt_itp02_tbl(ln_cnt_02).c_lot_id;
                  lv_batch_id_03 := gt_itp02_tbl(ln_cnt_02).p_batch_id;
--
                  -- ================================
                  -- A-7.��O�K�w���b�g�n���f�[�^���o
                  -- ================================
                  get_lots_data(
                    lv_item_id_03,      -- �i��ID
                    lv_lot_id_03,       -- ���b�gID
                    lv_batch_id_03,     -- �o�b�`ID
                    lv_out_control,     -- �o�͐���
                    lv_level_num_03,    -- �K�w
                    gt_itp03_tbl,       -- ���Y���(��O�K�w)
                    gt_rcv03_tbl,       -- ������(��O�K�w)
                    lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
                    lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
                    lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_process_expt;
                  END IF;
--
                  -- ��������
                  ln_loop_cnt_03 := gt_itp03_tbl.COUNT + gt_rcv03_tbl.COUNT;
--
                  << lot_trace_loop_03 >>
                  FOR ln_cnt_03 IN 1..ln_loop_cnt_03 LOOP
                    -- ================================
                    -- A-8.��O�K�w���b�g�n���f�[�^�i�[
                    -- ================================
                    -- ���[�v�J�E���g(��O�K�w��)
                    put_lots_data(
                      ln_total_01,        -- ��������
                      ln_cnt_03,          -- ���[�v�J�E���g(��O�K�w)
                      lv_out_control,     -- �o�͐���
                      lv_level_num_03,    -- �K�w
                      gt_itp03_tbl,       -- ���Y���(��O�K�w)
                      gt_rcv03_tbl,       -- ������(��O�K�w)
                      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
                      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
                      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
                    IF (lv_retcode = gv_status_error) THEN
                      RAISE global_process_expt;
                    END IF;
--
                    -- ��O�K�w�̎q�i�ڂ�e�i�ڂ֒u����
                    IF ((gt_itp03_tbl.COUNT > 0) AND (gt_itp03_tbl.COUNT >= ln_cnt_03)) THEN
                      IF (gt_itp03_tbl(ln_cnt_03).c_item_no IS NOT NULL) THEN
                        lv_item_id_04  := gt_itp03_tbl(ln_cnt_03).c_item_id;
                        lv_lot_id_04   := gt_itp03_tbl(ln_cnt_03).c_lot_id;
                        lv_batch_id_04 := gt_itp03_tbl(ln_cnt_03).p_batch_id;
--
                        -- ================================
                        -- A-9.��l�K�w���b�g�n���f�[�^���o
                        -- ================================
                        get_lots_data(
                          lv_item_id_04,      -- �i��ID
                          lv_lot_id_04,       -- ���b�gID
                          lv_batch_id_04,     -- �o�b�`ID
                          lv_out_control,     -- �o�͐���
                          lv_level_num_04,    -- �K�w
                          gt_itp04_tbl,       -- ���Y���(��l�K�w)
                          gt_rcv04_tbl,       -- ������(��l�K�w)
                          lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
                          lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
                          lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
                        IF (lv_retcode = gv_status_error) THEN
                          RAISE global_process_expt;
                        END IF;
--
                        -- ��������
                        ln_loop_cnt_04 := gt_itp04_tbl.COUNT + gt_rcv04_tbl.COUNT;
--
                        << lot_trace_loop_04 >>
                        FOR ln_cnt_04 IN 1..ln_loop_cnt_04 LOOP
                          -- =================================
                          -- A-10.��l�K�w���b�g�n���f�[�^�i�[
                          -- =================================
                          -- ���[�v�J�E���g(��l�K�w��)
                          put_lots_data(
                            ln_total_01,        -- ��������
                            ln_cnt_04,          -- ���[�v�J�E���g(��l�K�w)
                            lv_out_control,     -- �o�͐���
                            lv_level_num_04,    -- �K�w
                            gt_itp04_tbl,       -- ���Y���(��l�K�w)
                            gt_rcv04_tbl,       -- ������(��l�K�w)
                            lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
                            lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
                            lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
                          IF (lv_retcode = gv_status_error) THEN
                            RAISE global_process_expt;
                          END IF;
--
                          -- ��l�K�w�̎q�i�ڂ�e�i�ڂ֒u����
                          IF ((gt_itp04_tbl.COUNT > 0) AND (gt_itp04_tbl.COUNT >= ln_cnt_04)) THEN
                            IF (gt_itp04_tbl(ln_cnt_04).c_item_no IS NOT NULL) THEN
                              lv_item_id_05  := gt_itp04_tbl(ln_cnt_04).c_item_id;
                              lv_lot_id_05   := gt_itp04_tbl(ln_cnt_04).c_lot_id;
                              lv_batch_id_05 := gt_itp04_tbl(ln_cnt_04).p_batch_id;
--
                              -- =================================
                              -- A-11.��܊K�w���b�g�n���f�[�^���o
                              -- =================================
                              get_lots_data(
                                lv_item_id_05,      -- �i��ID
                                lv_lot_id_05,       -- ���b�gID
                                lv_batch_id_05,     -- �o�b�`ID
                                lv_out_control,     -- �o�͐���
                                lv_level_num_05,    -- �K�w
                                gt_itp05_tbl,       -- ���Y���(��܊K�w)
                                gt_rcv05_tbl,       -- ������(��܊K�w)
                                lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
                                lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
                                lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
                              IF (lv_retcode = gv_status_error) THEN
                                RAISE global_process_expt;
                              END IF;
--
                              -- ��������
                              ln_loop_cnt_05 := gt_itp05_tbl.COUNT + gt_rcv05_tbl.COUNT;
--
                              << lot_trace_loop_05 >>
                              FOR ln_cnt_05 IN 1..ln_loop_cnt_05 LOOP
                                -- =================================
                                -- A-12.��܊K�w���b�g�n���f�[�^�i�[
                                -- =================================
                                -- ���[�v�J�E���g(��܊K�w��)
                                put_lots_data(
                                  ln_total_01,        -- ��������
                                  ln_cnt_05,          -- ���[�v�J�E���g(��܊K�w)
                                  lv_out_control,     -- �o�͐���
                                  lv_level_num_05,    -- �K�w
                                  gt_itp05_tbl,       -- ���Y���(��܊K�w)
                                  gt_rcv05_tbl,       -- ������(��܊K�w)
                                  lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
                                  lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
                                  lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
                                IF (lv_retcode = gv_status_error) THEN
                                  RAISE global_process_expt;
                                END IF;
--
                              END LOOP lot_trace_loop_05;
                            END IF;                   -- ��܊K�w�e�q�i�ڒu����
                          END IF;                     -- ��܊K�w�����`�F�b�N�I��
                        END LOOP lot_trace_loop_04;
                      END IF;                         -- ��l�K�w�e�q�i�ڒu����
                    END IF;                           -- ��l�K�w�����`�F�b�N�I��
                  END LOOP lot_trace_loop_03;
                END IF;                               -- ��O�K�w�e�q�i�ڒu����
              END IF;                                 -- ��O�K�w�����`�F�b�N�I��
            END LOOP lot_trace_loop_02;
          END IF;                                     -- ���K�w�e�q�i�ڒu����
        END IF;                                       -- ���K�w�����`�F�b�N�I��
      END LOOP lot_trace_loop_01;
      -- ================================
      -- A-13.���b�g�n���f�[�^�ꊇ�o�^
      -- ================================
      insert_lots_data(
        lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    END IF;
    -- ��������
    gn_normal_cnt := ln_total_01;
--
    -- ����I�������擾
    IF ((gn_normal_cnt > 0) AND (lv_retcode = gv_status_normal)) THEN
      -- ���O�o�͏���
      disp_report(lv_errbuf,
                  lv_retcode,
                  lv_errmsg);
    END IF;
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
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
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
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
    errbuf              OUT    VARCHAR2,                -- �G���[�E���b�Z�[�W           --# �Œ� #
    retcode             OUT    VARCHAR2,                -- ���^�[���E�R�[�h             --# �Œ� #
    iv_item_code        IN     VARCHAR2,                -- �i�ڃR�[�h
    iv_lot_no           IN     VARCHAR2,                -- ���b�gNo
    iv_out_control      IN     VARCHAR2)                -- �o�͐���
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
    --��؂蕶���o��
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      iv_item_code,                                -- 1.�i�ڃR�[�h
      iv_lot_no,                                   -- 2.���b�gNo
      iv_out_control,                              -- 3.�o�͐���
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
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = gv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxcmn560001c;
/
