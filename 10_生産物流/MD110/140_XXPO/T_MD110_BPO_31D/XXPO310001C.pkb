CREATE OR REPLACE PACKAGE BODY xxpo310001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo310001c(body)
 * Description      : �d�����э쐬����
 * MD.050           : �������            T_MD050_BPO_310
 * MD.070           : �d�����э쐬        T_MD070_BPO_31D
 * Version          : 1.6
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  get_location           �q�ɁA�g�D�A��Ђ̎擾
 *  get_lot_mst            OPM���b�g�}�X�^�̎擾
 *  init_proc              �O����                                       (D-1)
 *  parameter_check        �p�����[�^�`�F�b�N                           (D-2)
 *  get_mast_data          �������擾                                 (D-3)
 *  insert_opif            ������ѓo�^����                             (D-4)
 *  upd_po_lines           �������׍X�V                                 (D-5)
 *  upd_lot_mst            ���b�g�}�X�^�X�V                             (D-6)
 *  insert_tran            �����o�Ɏ�����o�^                       (D-7)
 *  disp_report            ���������������o��                         (D-8)
 *  upd_po_headrs          �����X�e�[�^�X�X�V                           (D-9)
 *  commit_opif            ����I�[�v��IF�f�[�^���f                     (D-10)
 *  disp_count             ���������o��                                 (D-11)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/03/10    1.0   Oracle �R�� ��_ ����쐬
 *  2008/04/21    1.1   Oracle �R�� ��_ �ύX�v��No43�Ή�
 *  2008/04/30    1.2   Oracle �R�� ��_ �ύX�v��No69�Ή�
 *  2008/05/14    1.3   Oracle �R�� ��_ �ύX�v��No90�Ή�
 *  2008/05/21    1.4   Oracle �R�� ��_ �ύX�v��No109�Ή�
 *                                       �����e�X�g�s����O#300_3�Ή�
 *  2008/10/27    1.5   Oracle �g�� ���� �����ύXNo216�Ή�
 *  2008/12/04    1.6   Oracle �g�� ���� �{�ԏ�QNo420�Ή�
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
  lock_expt             EXCEPTION;              -- ���b�N�擾��O
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);          -- ���b�N�擾��O
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name         CONSTANT VARCHAR2(100) := 'xxpo310001c';       -- �p�b�P�[�W��
  gv_app_name         CONSTANT VARCHAR2(5)   := 'XXPO';              -- �A�v���P�[�V�����Z�k��
  gv_com_name         CONSTANT VARCHAR2(5)   := 'XXCMN';             -- �A�v���P�[�V�����Z�k��
--
  -- �g�[�N��
  gv_tkn_para_name       CONSTANT VARCHAR2(20) := 'PARAM_NAME';
  gv_tkn_po_num          CONSTANT VARCHAR2(20) := 'PO_NUM';
  gv_tkn_table           CONSTANT VARCHAR2(20) := 'TABLE';
  gv_tkn_table_name      CONSTANT VARCHAR2(20) := 'TABLE_NAME';
  gv_tkn_api_name        CONSTANT VARCHAR2(20) := 'API_NAME';
  gv_tkn_count           CONSTANT VARCHAR2(20) := 'COUNT';
  gv_tkn_m_no            CONSTANT VARCHAR2(20) := 'M_NO';
  gv_tkn_item_no         CONSTANT VARCHAR2(20) := 'ITEM_NO';
  gv_tkn_nonyu_date      CONSTANT VARCHAR2(20) := 'NONYU_DATE';
  gv_tkn_conc_id         CONSTANT VARCHAR2(20) := 'CONC_ID';
  gv_tkn_conc_name       CONSTANT VARCHAR2(20) := 'CONC_NAME';
--
  gv_tkn_number_31d_01   CONSTANT VARCHAR2(15) := 'APP-XXPO-10027'; -- ���b�N���s�G���[
  gv_tkn_number_31d_02   CONSTANT VARCHAR2(15) := 'APP-XXPO-10056'; -- �����������N���G���[2
  gv_tkn_number_31d_03   CONSTANT VARCHAR2(15) := 'APP-XXPO-10076'; -- �����݌ɏo�Ɏ��R�擾�G���[
  gv_tkn_number_31d_04   CONSTANT VARCHAR2(15) := 'APP-XXPO-10091'; -- �����̃X�e�[�^�X�G���[
  gv_tkn_number_31d_05   CONSTANT VARCHAR2(15) := 'APP-XXPO-10094'; -- �����ԍ������̓G���[
  gv_tkn_number_31d_06   CONSTANT VARCHAR2(15) := 'APP-XXPO-10107'; -- �s���Ȕ����ԍ�
  gv_tkn_number_31d_07   CONSTANT VARCHAR2(15) := 'APP-XXPO-30024'; -- ���э쐬�ϔ������
  gv_tkn_number_31d_08   CONSTANT VARCHAR2(15) := 'APP-XXPO-30027'; -- ��������
  gv_tkn_number_31d_09   CONSTANT VARCHAR2(15) := 'APP-XXPO-30039'; -- ���̓p�����[�^���5
--
  gv_tbl_name_po_head    CONSTANT VARCHAR2(50) := '�����w�b�_';
  gv_tbl_name_po_line    CONSTANT VARCHAR2(50) := '��������';
  gv_tbl_name_lot_mast   CONSTANT VARCHAR2(50) := 'OPM���b�g�}�X�^';
--
  -- ����������
  gv_appl_name           CONSTANT VARCHAR2(50) := 'PO';
  gv_prg_name            CONSTANT VARCHAR2(50) := 'RVCTP';
--
  gv_add_status_zmi      CONSTANT VARCHAR2(5)  := '20';              -- �����쐬��
  gv_add_status_num_zmi  CONSTANT VARCHAR2(5)  := '30';              -- ���ʊm���
  gv_po_type_rev         CONSTANT VARCHAR2(1)  := '3';               -- �����݌�
--
  gv_flg_on              CONSTANT VARCHAR2(1)  := 'Y';
  gn_lot_ctl_on          CONSTANT NUMBER       := 1;
--
  gv_prod_class_code     CONSTANT VARCHAR2(1)  := '2';               -- ���i�敪:�h�����N
  gv_item_class_code     CONSTANT VARCHAR2(1)  := '5';               -- �i�ڋ敪:���i
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ***************************************
  -- ***    �擾���i�[���R�[�h�^��`   ***
  -- ***************************************
--
  -- D-3:�������擾�Ώۃf�[�^
  TYPE masters_rec IS RECORD(
    h_segment1            po_headers_all.segment1%TYPE,                        -- �����ԍ�
    po_header_id          po_headers_all.po_header_id%TYPE,                    -- �����w�b�_ID
    h_attribute11         po_headers_all.attribute11%TYPE,                     -- �����敪
    vendor_id             po_headers_all.vendor_id%TYPE,                       -- �d����ID
    h_attribute4          po_headers_all.attribute4%TYPE,                      -- �[����
    h_attribute5          po_headers_all.attribute5%TYPE,                      -- �[����R�[�h
    h_attribute6          po_headers_all.attribute6%TYPE,                      -- �����敪
    h_attribute10         po_headers_all.attribute10%TYPE,                     -- �����R�[�h
    po_line_id            po_lines_all.po_line_id%TYPE,                        -- ��������ID
    line_num              po_lines_all.line_num%TYPE,                          -- ���הԍ�
    item_id               po_lines_all.item_id%TYPE,                           -- �i��ID
    lot_no                po_lines_all.attribute1%TYPE,                        -- ���b�gNO
    unit_price            po_lines_all.unit_price%TYPE,                        -- �P��
    quantity              po_lines_all.quantity%TYPE,                          -- ����
    unit_code             po_lines_all.unit_meas_lookup_code%TYPE,             -- �P��
    l_attribute4          po_lines_all.attribute4%TYPE,                        -- �݌ɓ���
    l_attribute10         po_lines_all.attribute10%TYPE,                       -- �����P��
    l_attribute11         po_lines_all.attribute11%TYPE,                       -- ��������
    lot_id                ic_lots_mst.lot_id%TYPE,                             -- ���b�gID
    attribute4            ic_lots_mst.attribute4%TYPE,                         -- �[����(����)
    attribute5            ic_lots_mst.attribute5%TYPE,                         -- �[����(�ŏI)
--
    item_no               xxcmn_item_mst_v.item_no%TYPE,                       -- �i�ڃR�[�h
--
    segment1              xxcmn_vendors_v.segment1%TYPE,                       -- �d����ԍ�
    vendor_stock_whse     xxcmn_vendor_sites_v.vendor_stock_whse%TYPE,         -- �����݌ɓ��ɐ�
--
    lot_ctl               xxcmn_item_mst_v.lot_ctl%TYPE,                       -- ���b�g
    item_idv              xxcmn_item_mst_v.item_id%TYPE,                       -- �i��ID
--
    prod_class_code       xxcmn_item_categories3_v.prod_class_code%TYPE,       -- ���i�敪
    item_class_code       xxcmn_item_categories3_v.prod_class_code%TYPE,       -- �i�ڋ敪
--
    from_whse_code        ic_tran_cmp.whse_code%TYPE,                          -- �q��
    co_code               ic_tran_cmp.co_code%TYPE,                            -- ���
    orgn_code             ic_tran_cmp.orgn_code%TYPE,                          -- �g�D
--
    organization_id       mtl_item_locations.organization_id%TYPE,
    subinventory_code     mtl_item_locations.subinventory_code%TYPE,
    inventory_location_id mtl_item_locations.inventory_location_id%TYPE,
--
    h_def4_date           DATE,                                                -- �[����
    def4_date             DATE,                                                -- �[����(����)
    def5_date             DATE,                                                -- �[����(�ŏI)
    def11_qty             NUMBER,                                              -- ��������
    def5_num              NUMBER,                                              -- �[����R�[�h
--
    exec_flg              NUMBER                                    -- �����t���O
  );
  -- �e�}�X�^�֔��f����f�[�^���i�[���錋���z��
  TYPE masters_tbl  IS TABLE OF masters_rec  INDEX BY PLS_INTEGER;
--
  -- ***************************************
  -- ***      �o�^�p���ڃe�[�u���^       ***
  -- ***************************************
--
  gt_master_tbl                masters_tbl;  -- �e�}�X�^�֓o�^����f�[�^
-- 2008/10/27 v1.5 T.Yoshimoto Add Start
  -- �������ԍ�
  TYPE reg_src_doc_num       IS TABLE OF xxpo_rcv_txns_interface.source_document_number   %TYPE INDEX BY BINARY_INTEGER;
  -- ���������הԍ�
  TYPE reg_src_doc_line_num  IS TABLE OF xxpo_rcv_txns_interface.source_document_line_num %TYPE INDEX BY BINARY_INTEGER;
  -- ����ԕi���הԍ�
  TYPE reg_rtn_line_num      IS TABLE OF xxpo_rcv_and_rtn_txns.rcv_rtn_line_number        %TYPE INDEX BY BINARY_INTEGER;
-- 2008/10/27 v1.5 T.Yoshimoto Add End
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_header_number            VARCHAR2(20);
  gv_inv_ship_rsn             VARCHAR2(100);              -- �����݌ɏo�Ɏ��R
  gn_group_id                 NUMBER;                     -- �O���[�vID
  gn_proc_flg                 NUMBER;
  gn_txns_id                  xxpo_rcv_and_rtn_txns.txns_id%TYPE;
  gv_defaultlot               VARCHAR2(100);              -- �f�t�H���g���b�g 2008/04/30 �ǉ�
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
-- 2008/10/27 v1.5 T.Yoshimoto Add Start
  -- ���ڃe�[�u���^��`
  gt_src_doc_num       reg_src_doc_num;       -- �������ԍ�
  gt_src_doc_line_num  reg_src_doc_line_num;  -- ���������הԍ�
  gt_rtn_line_num      reg_rtn_line_num;      -- ����ԕi���הԍ�
-- 2008/10/27 v1.5 T.Yoshimoto Add End
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���E�J�[�\��
  -- ===============================
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
   * Description      : �O����(D-1)
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
    l_setup_return_sts        BOOLEAN;
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
    -- �����݌ɏo�Ɏ��R
    gv_inv_ship_rsn := FND_PROFILE.VALUE('XXPO_CTPTY_INV_SHIP_RSN');
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_inv_ship_rsn IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name, 
                                            gv_tkn_number_31d_03);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �f�t�H���g���b�g 2008/04/30 �ǉ�
    gv_defaultlot := FND_PROFILE.VALUE('IC$DEFAULT_LOT');
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_defaultlot IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name, 
                                            gv_tkn_number_31d_03);
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
    -- GMI�nAPI�ďo�̃Z�b�g�A�b�v
    l_setup_return_sts  :=  GMIGUTL.SETUP(FND_GLOBAL.USER_NAME);
    IF NOT (l_setup_return_sts) THEN
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
  END init_proc;
--
  /**********************************************************************************
   * Procedure Name   : parameter_check
   * Description      : �p�����[�^�`�F�b�N(D-2)
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
    ln_cnt        NUMBER;
    lv_status     po_headers_all.attribute1%TYPE;
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
                                            gv_tkn_number_31d_05);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
--
    -- �����ԍ����͂���
    ELSE
--
      gv_header_number := iv_po_number;
--
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_31d_09,
                                            gv_tkn_po_num,
                                            iv_po_number);
--
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
--
    -- �����w�b�_�̑��݃`�F�b�N
    BEGIN
      SELECT pha.attribute1
      INTO   lv_status
      FROM   po_headers_all pha
      WHERE  pha.segment1   = gv_header_number
      AND    ROWNUM         = 1;
--
    EXCEPTION
--
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_31d_06);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- �X�e�[�^�X�̃`�F�b�N
    IF (lv_status <> gv_add_status_zmi) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_31d_04);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �O���[�vID�̎擾
    SELECT rcv_interface_groups_s.NEXTVAL
    INTO   gn_group_id
    FROM   DUAL;
--
-- 2008/05/14 �폜
--    gn_group_id := gn_group_id || TO_NUMBER(gv_header_number);
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
  /***********************************************************************************
   * Procedure Name   : get_mast_data
   * Description      : �������擾(D-3)
   ***********************************************************************************/
  PROCEDURE get_mast_data(
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_mast_data'; -- �v���O������
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
    ln_po_header_id   po_headers_all.po_header_id%TYPE;
    ln_po_line_id     po_lines_all.po_line_id%TYPE;
    ln_lot_id         ic_lots_mst.lot_id%TYPE;
    mst_rec           masters_rec;
    ln_cnt            NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR base_data_cur
    IS
      SELECT xxpo.h_segment1              -- �����ԍ�
            ,xxpo.po_header_id            -- �����w�b�_ID
            ,xxpo.h_attribute11           -- �����敪
            ,xxpo.vendor_id               -- �d����ID
            ,xxpo.h_attribute4            -- �[����
            ,xxpo.h_attribute5            -- �[����R�[�h
            ,xxpo.h_attribute6            -- �����敪
            ,xxpo.h_attribute10           -- �����R�[�h
            ,xxpo.po_line_id              -- ��������ID
            ,xxpo.line_num                -- ���הԍ�
            ,xxpo.item_id                 -- �i��ID
            ,xxpo.l_attribute1            -- ���b�gNO
            ,xxpo.unit_price              -- �P��
            ,xxpo.quantity                -- ����
            ,xxpo.unit_meas_lookup_code   -- �P��
            ,xxpo.l_attribute4            -- �݌ɓ���
            ,xxpo.l_attribute10           -- �����P��
            ,xxpo.l_attribute11           -- ��������
            ,ilm.lot_id                   -- ���b�gID
            ,ilm.attribute4               -- �[����(����)
            ,ilm.attribute5               -- �[����(�ŏI)
            ,xiv.item_no                  -- �i�ڃR�[�h
            ,xvv.segment1                 -- �d����ԍ�
            ,xsv.vendor_stock_whse        -- �����݌ɓ��ɐ�
            ,xiv.lot_ctl                  -- ���b�g
            ,xiv.item_id as item_idv      -- OPM�i��ID
            ,xcv.prod_class_code          -- ���i�敪
            ,xcv.item_class_code          -- �i�ڋ敪
      FROM  (SELECT pha.segment1 as h_segment1        -- �����ԍ�
                   ,pha.po_header_id                  -- �����w�b�_ID
                   ,pha.vendor_id                     -- �d����ID
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
             FROM   po_headers_all pha                -- �����w�b�_
                   ,po_lines_all pla                  -- ��������
             WHERE  pha.po_header_id = pla.po_header_id) xxpo
            ,xxcmn_item_mst_v xiv                      -- OPM�i�ڏ��VIEW
            ,ic_lots_mst ilm                           -- OPM���b�g�}�X�^
            ,xxcmn_vendors_v xvv                       -- �d������VIEW
            ,xxcmn_vendor_sites_v xsv                  -- �d����T�C�g���VIEW
            ,xxcmn_item_categories3_v xcv              -- OPM�i�ڃJ�e�S���������VIEW3
      WHERE xxpo.item_id      = xiv.inventory_item_id
      AND   NVL(xxpo.l_attribute1,gv_defaultlot) = ilm.lot_no              -- 2008/04/30 �C��
      AND   xiv.item_id       = ilm.item_id
      AND   xiv.item_id       = xcv.item_id
      AND   xxpo.vendor_id    = xvv.vendor_id
      AND   xxpo.vendor_id    = xsv.vendor_id(+)
      AND   xxpo.l_attribute2 = xsv.vendor_site_code(+)
      AND   xxpo.h_segment1   = gv_header_number
      ORDER BY xxpo.line_num;
--
    -- *** ���[�J���E���R�[�h ***
    lr_base_data_rec base_data_cur%ROWTYPE;
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
    ln_cnt          := 0;
    ln_po_header_id := NULL;
    ln_po_line_id   := NULL;
    ln_lot_id       := NULL;
--
    OPEN base_data_cur;
--
    <<base_data_loop>>
    LOOP
      FETCH base_data_cur INTO lr_base_data_rec;
      EXIT WHEN base_data_cur%NOTFOUND;
--
      mst_rec.h_segment1        := lr_base_data_rec.h_segment1;
      mst_rec.po_header_id      := lr_base_data_rec.po_header_id;
      mst_rec.h_attribute11     := lr_base_data_rec.h_attribute11;
      mst_rec.vendor_id         := lr_base_data_rec.vendor_id;
      mst_rec.h_attribute4      := lr_base_data_rec.h_attribute4;
      mst_rec.h_attribute5      := lr_base_data_rec.h_attribute5;
      mst_rec.h_attribute6      := lr_base_data_rec.h_attribute6;
      mst_rec.h_attribute10     := lr_base_data_rec.h_attribute10;
      mst_rec.po_line_id        := lr_base_data_rec.po_line_id;
      mst_rec.line_num          := lr_base_data_rec.line_num;
      mst_rec.item_id           := lr_base_data_rec.item_id;
      mst_rec.lot_no            := lr_base_data_rec.l_attribute1;
      mst_rec.unit_price        := lr_base_data_rec.unit_price;
      mst_rec.quantity          := lr_base_data_rec.quantity;
      mst_rec.unit_code         := lr_base_data_rec.unit_meas_lookup_code;
      mst_rec.l_attribute4      := lr_base_data_rec.l_attribute4;
      mst_rec.l_attribute10     := lr_base_data_rec.l_attribute10;
      mst_rec.l_attribute11     := lr_base_data_rec.l_attribute11;
      mst_rec.lot_id            := lr_base_data_rec.lot_id;
      mst_rec.attribute4        := lr_base_data_rec.attribute4;
      mst_rec.attribute5        := lr_base_data_rec.attribute5;
      mst_rec.item_no           := lr_base_data_rec.item_no;
      mst_rec.segment1          := lr_base_data_rec.segment1;
      mst_rec.vendor_stock_whse := lr_base_data_rec.vendor_stock_whse;
      mst_rec.lot_ctl           := lr_base_data_rec.lot_ctl;
      mst_rec.item_idv          := lr_base_data_rec.item_idv;
      mst_rec.prod_class_code   := lr_base_data_rec.prod_class_code;
      mst_rec.item_class_code   := lr_base_data_rec.item_class_code;
--
      mst_rec.h_def4_date       := 
                             FND_DATE.STRING_TO_DATE(lr_base_data_rec.h_attribute4,'YYYY/MM/DD');
      mst_rec.def4_date         := 
                             FND_DATE.STRING_TO_DATE(lr_base_data_rec.attribute4,'YYYY/MM/DD');
      mst_rec.def5_date         := 
                             FND_DATE.STRING_TO_DATE(lr_base_data_rec.attribute5,'YYYY/MM/DD');
      mst_rec.def11_qty         := TO_NUMBER(lr_base_data_rec.l_attribute11);
      mst_rec.def5_num          := TO_NUMBER(lr_base_data_rec.h_attribute5);
--
      IF ((ln_po_header_id IS NULL) OR (ln_po_header_id <> mst_rec.po_header_id)) THEN
--
        -- ���b�N����(�����w�b�_)
        BEGIN
          SELECT pha.po_header_id
          INTO   ln_po_header_id
          FROM   po_headers_all pha
          WHERE  pha.po_header_id = mst_rec.po_header_id
          FOR UPDATE OF pha.po_header_id NOWAIT;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
--
          WHEN lock_expt THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                                  gv_tkn_number_31d_01,
                                                  gv_tkn_table,
                                                  gv_tbl_name_po_head);
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
--
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
      END IF;
--
      IF ((ln_po_line_id IS NULL) OR (ln_po_line_id <> mst_rec.po_line_id)) THEN
--
        -- ���b�N����(��������)
        BEGIN
          SELECT pla.po_line_id
          INTO   ln_po_line_id
          FROM   po_lines_all pla
          WHERE  pla.po_line_id = mst_rec.po_line_id
          FOR UPDATE OF pla.po_line_id NOWAIT;
  --
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
  --
          WHEN lock_expt THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                                  gv_tkn_number_31d_01,
                                                  gv_tkn_table,
                                                  gv_tbl_name_po_line);
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
  --
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
      END IF;
--
      -- ���b�N����(OPM���b�g�}�X�^)
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
        WHEN NO_DATA_FOUND THEN
          NULL;
--
        WHEN lock_expt THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                                gv_tkn_number_31d_01,
                                                gv_tkn_table,
                                                gv_tbl_name_lot_mast);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
--
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
--
      BEGIN
        SELECT mil.organization_id
              ,mil.subinventory_code
              ,mil.inventory_location_id
        INTO   mst_rec.organization_id
              ,mst_rec.subinventory_code
              ,mst_rec.inventory_location_id
        FROM  mtl_item_locations mil
        WHERE mil.segment1 = mst_rec.h_attribute5;           -- �[����R�[�h
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
      gt_master_tbl(ln_cnt)  := mst_rec;
--
      ln_cnt := ln_cnt + 1;
--
    END LOOP base_data_loop;
--
    CLOSE base_data_cur;
--
    -- ���݂��Ȃ�
    IF (ln_cnt = 0) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_31d_06);
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
      IF (base_data_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE base_data_cur;
      END IF;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (base_data_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE base_data_cur;
      END IF;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (base_data_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE base_data_cur;
      END IF;
--
--#####################################  �Œ蕔 END   #############################################
--
  END get_mast_data;
--
  /***********************************************************************************
   * Procedure Name   : insert_opif
   * Description      : ������ѓo�^����(D-4)
   ***********************************************************************************/
  PROCEDURE insert_opif(
    ir_mst_rec      IN OUT NOCOPY masters_rec,  -- �Ώۃ��R�[�h
-- 2008/10/27 v1.5 T.Yoshimoto Add Start
    ir_rtn_line_num IN            xxpo_rcv_txns_interface.source_document_line_num%TYPE, -- ����ԕi���הԍ�
-- 2008/10/27 v1.5 T.Yoshimoto Add End
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_opif'; -- �v���O������
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
    ln_factor         xxpo_rcv_and_rtn_txns.conversion_factor%TYPE;
    ln_lot_id         xxpo_rcv_and_rtn_txns.lot_id%TYPE;
    lv_lot_no         xxpo_rcv_and_rtn_txns.lot_number%TYPE;
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
    -- ����ԕi����(�A�h�I��)�̎��ID
    SELECT xxpo_rcv_and_rtn_txns_s1.NEXTVAL
    INTO   gn_txns_id
    FROM   DUAL;
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
        ,ir_mst_rec.vendor_id                            -- vendor_id
        ,ir_mst_rec.h_def4_date                          -- expected_receipt_date
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
        ,'RECEIVE'                                       -- transaction_type
-- 2008/12/04 v1.6 T.Yoshimoto Mod Start �{��#420
        --,SYSDATE                                         -- transaction_date
        ,TO_DATE(ir_mst_rec.h_attribute4, 'YYYY/MM/DD')  -- transaction_date(�����w�b�_.�[����)
-- 2008/12/04 v1.6 T.Yoshimoto Mod End �{��#420
        ,'PENDING'                                       -- processing_status_code
        ,'BATCH'                                         -- processing_mode_code
        ,'PENDING'                                       -- transaction_status_code
        ,ir_mst_rec.quantity                             -- quantity
        ,ir_mst_rec.unit_code                            -- unit_of_measure
        ,ir_mst_rec.item_id                              -- item_id
        ,'DELIVER'                                       -- auto_transact_code
        ,'VENDOR'                                        -- receipt_source_code
        ,ir_mst_rec.organization_id                      -- to_organization_id
        ,'PO'                                            -- source_document_code
        ,ir_mst_rec.po_header_id                         -- po_header_id
        ,ir_mst_rec.po_line_id                           -- po_line_id
        ,ir_mst_rec.po_line_id                           -- po_line_location_id
        ,'INVENTORY'                                     -- destination_type_code
        ,ir_mst_rec.subinventory_code                    -- subinventory
        ,ir_mst_rec.inventory_location_id                -- locator_id
        ,ir_mst_rec.h_def4_date                          -- expected_receipt_date
        ,TO_CHAR(gn_txns_id)                             -- ship_line_attribute1
        ,rcv_headers_interface_s.CURRVAL                 -- header_interface_id
        ,gv_flg_on                                       -- validation_flag
    FROM DUAL;
--
    -- ���b�g�Ǘ��i
    IF (ir_mst_rec.lot_ctl = gn_lot_ctl_on) THEN
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
          ,ir_mst_rec.lot_no                             -- lot_number
          ,ABS(ir_mst_rec.quantity)                      -- transaction_quantity
          ,ABS(ir_mst_rec.quantity)                      -- primary_quantity
          ,'RCV'                                         -- product_code
          ,rcv_transactions_interface_s.CURRVAL          -- product_transaction_id
      FROM DUAL;
    END IF;
--
    ln_factor := 1;
--
    -- �u���i�敪�v���u�h�����N�v
    -- �u�i�ڋ敪�v���u���i�v
    IF ((ir_mst_rec.prod_class_code = gv_prod_class_code)
    AND (ir_mst_rec.item_class_code = gv_item_class_code)) THEN
--
      -- �u�����P�ʁv<>�u�P�ʁv
      IF (ir_mst_rec.unit_code <> ir_mst_rec.l_attribute10) THEN
        ln_factor := TO_NUMBER(ir_mst_rec.l_attribute4);
      END IF;
    END IF;
--
    -- ���b�g�Ǘ��i 2008/04/30 �ǉ�
    IF (ir_mst_rec.lot_ctl = gn_lot_ctl_on) THEN
      ln_lot_id := ir_mst_rec.lot_id;
      lv_lot_no := ir_mst_rec.lot_no;
    ELSE
      ln_lot_id := NULL;
      lv_lot_no := NULL;
    END IF;
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
        ,drop_ship_type
        ,vendor_id
        ,vendor_code
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
        ,'1'                                             -- txns_type
        ,ir_mst_rec.h_segment1                           -- rcv_rtn_number
-- 2008/10/27 v1.5 T.Yoshimoto Add Start
        --,ir_mst_rec.line_num                             -- rcv_rtn_line_number
        ,ir_rtn_line_num                                 -- rcv_rtn_line_number
-- 2008/10/27 v1.5 T.Yoshimoto Add End
        ,ir_mst_rec.h_segment1                           -- source_document_number
        ,ir_mst_rec.line_num                             -- source_document_line_num
        ,ir_mst_rec.h_attribute6                         -- drop_ship_type
        ,ir_mst_rec.vendor_id                            -- vendor_id
        ,ir_mst_rec.segment1                             -- vendor_code
        ,ir_mst_rec.h_attribute5                         -- location_code
        ,ir_mst_rec.h_def4_date                          -- txns_date
-- 2008/05/21 v1.4 Changed
--        ,ir_mst_rec.item_id                              -- item_id
        ,ir_mst_rec.item_idv                              -- item_idv
-- 2008/05/21 v1.4 Changed
        ,ir_mst_rec.item_no                              -- item_code
        ,ln_lot_id                                       -- lot_id
        ,lv_lot_no                                       -- lot_number
        ,ir_mst_rec.def11_qty                            -- rcv_rtn_quantity
        ,ir_mst_rec.l_attribute10                        -- rcv_rtn_uom
        ,ir_mst_rec.quantity                             -- quantity
        ,ir_mst_rec.unit_code                            -- uom
        ,ln_factor                                       -- conversion_factor
        ,ir_mst_rec.unit_price                           -- unit_price
        ,ir_mst_rec.h_attribute10                        -- department_code
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
    gn_proc_flg := 1;
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
  END insert_opif;
--
  /***********************************************************************************
   * Procedure Name   : upd_po_lines
   * Description      : �������׍X�V(D-5)
   ***********************************************************************************/
  PROCEDURE upd_po_lines(
    ir_mst_rec      IN OUT NOCOPY masters_rec,  -- �Ώۃ��R�[�h
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_po_lines'; -- �v���O������
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
      UPDATE po_lines_all
      SET    attribute7             = ir_mst_rec.l_attribute11             -- �������
            ,attribute13            = gv_flg_on                            -- ���ʊm��t���O
            ,last_update_date       = gd_last_update_date
            ,last_updated_by        = gn_last_update_by
            ,last_update_login      = gn_last_update_login
            ,request_id             = gn_request_id
            ,program_application_id = gn_program_application_id
            ,program_id             = gn_program_id
            ,program_update_date    = gd_program_update_date
      WHERE po_line_id = ir_mst_rec.po_line_id;
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
  END upd_po_lines;
--
  /***********************************************************************************
   * Procedure Name   : upd_lot_mst
   * Description      : ���b�g�}�X�^�X�V(D-6)
   ***********************************************************************************/
  PROCEDURE upd_lot_mst(
    ir_mst_rec      IN OUT NOCOPY masters_rec,  -- �Ώۃ��R�[�h
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_lot_mst'; -- �v���O������
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
    ln_flg            NUMBER;
    lv_return_status  VARCHAR2(1);
    ln_msg_count      NUMBER;
    lv_msg_data       VARCHAR2(2000);
    lr_lot_rec        ic_lots_mst%ROWTYPE;
    lr_lot_cpg_rec    ic_lots_cpg%ROWTYPE;
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
    -- �[����(����)��NULL
    -- �[����(����) > �[����
    IF ((lr_lot_rec.attribute4 IS NULL)
     OR (ir_mst_rec.def4_date > ir_mst_rec.h_def4_date)) THEN
      lr_lot_rec.attribute4 := ir_mst_rec.h_attribute4;                   -- �[����(����)
      ln_flg := 1;
    END IF;
--
    -- �[����(�ŏI)��NULL
    -- �[����(�ŏI) < �[����
    IF ((lr_lot_rec.attribute5 IS NULL)
     OR (ir_mst_rec.def5_date < ir_mst_rec.h_def4_date)) THEN
      lr_lot_rec.attribute5 := ir_mst_rec.h_attribute4;                   -- �[����(�ŏI)
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
  END upd_lot_mst;
--
  /***********************************************************************************
   * Procedure Name   : insert_tran
   * Description      : �����o�Ɏ�����o�^(D-7)
   ***********************************************************************************/
  PROCEDURE insert_tran(
    ir_mst_rec      IN OUT NOCOPY masters_rec,  -- �Ώۃ��R�[�h
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_tran'; -- �v���O������
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
    -- �����敪���u�����݌Ɂv�̂�
    IF (ir_mst_rec.h_attribute11 = gv_po_type_rev) THEN
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
      lr_qty_rec.item_no        := ir_mst_rec.item_no;             -- �i��NO
      lr_qty_rec.from_whse_code := ir_mst_rec.from_whse_code;      -- �q��
      lr_qty_rec.item_um        := ir_mst_rec.unit_code;           -- �P��
      lr_qty_rec.lot_no         := ir_mst_rec.lot_no;              -- ���b�gNO
      lr_qty_rec.from_location  := ir_mst_rec.vendor_stock_whse;   -- �o�Ɍ�
      lr_qty_rec.trans_qty      := ir_mst_rec.quantity * (-1);     -- ����
      lr_qty_rec.co_code        := ir_mst_rec.co_code;             -- ���
      lr_qty_rec.orgn_code      := ir_mst_rec.orgn_code;           -- �g�D
      lr_qty_rec.trans_date     := ir_mst_rec.h_def4_date;         -- �����
      lr_qty_rec.reason_code    := gv_inv_ship_rsn;                -- ���R�R�[�h
      lr_qty_rec.user_name      := gv_user_name;                   -- ���[�U��
      lr_qty_rec.attribute1     := TO_CHAR(gn_txns_id);            -- �����\�[�XID
--
      -- �݌Ƀg�����U�N�V�����̍쐬
      GMIPAPI.INVENTORY_POSTING(
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
  END insert_tran;
--
  /***********************************************************************************
   * Procedure Name   : disp_report
   * Description      : ������ѓo�^����(D-8)
   ***********************************************************************************/
  PROCEDURE disp_report(
    ir_mst_rec      IN OUT NOCOPY masters_rec,  -- �Ώۃ��R�[�h
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'disp_report'; -- �v���O������
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
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_31d_07,
                                          gv_tkn_m_no,
                                          ir_mst_rec.line_num,
                                          gv_tkn_item_no,
                                          ir_mst_rec.item_no,
                                          gv_tkn_nonyu_date,
                                          SUBSTR(ir_mst_rec.h_attribute4,1,10));
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
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
  END disp_report;
--
  /***********************************************************************************
   * Procedure Name   : upd_po_headrs
   * Description      : �����X�e�[�^�X�X�V(D-9)
   ***********************************************************************************/
  PROCEDURE upd_po_headrs(
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_po_headrs'; -- �v���O������
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
    mst_rec         masters_rec;
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
    mst_rec := gt_master_tbl(0);
--
    BEGIN
      UPDATE po_headers_all
      SET    attribute1             = gv_add_status_num_zmi                 -- �X�e�[�^�X
            ,last_update_date       = gd_last_update_date
            ,last_updated_by        = gn_last_update_by
            ,last_update_login      = gn_last_update_login
            ,request_id             = gn_request_id
            ,program_application_id = gn_program_application_id
            ,program_id             = gn_program_id
            ,program_update_date    = gd_program_update_date
      WHERE po_header_id = mst_rec.po_header_id;
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
  END upd_po_headrs;
--
  /***********************************************************************************
   * Procedure Name   : commit_opif
   * Description      : ����I�[�v��IF�f�[�^���f(D-10)
   ***********************************************************************************/
  PROCEDURE commit_opif(
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'commit_opif'; -- �v���O������
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
    lb_ret         NUMBER ;
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
    COMMIT;
--
    -- ����I�[�v��IF�o�^����
    IF (gn_proc_flg = 1) THEN
--
      -- �R���J�����g�̋N��
      lb_ret := FND_REQUEST.SUBMIT_REQUEST(
                    application  => gv_appl_name         -- �A�v���P�[�V�����Z�k��
                   ,program      => gv_prg_name          -- �v���O������
                   ,argument1    => 'BATCH'              -- �������[�h
                   ,argument2    => TO_CHAR(gn_group_id) -- �O���[�vID
                  );
--
      -- �G���[
      IF (lb_ret = 0) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_31d_02);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
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
  END commit_opif;
--
  /***********************************************************************************
   * Procedure Name   : disp_count
   * Description      : �������ʃ��|�[�g�o��(D-11)
   ***********************************************************************************/
  PROCEDURE disp_count(
    ov_errbuf           OUT NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'disp_count';           -- �v���O������
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
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_31d_08,
                                          gv_tkn_count,
                                          TO_CHAR(gt_master_tbl.COUNT));
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
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
  END disp_count;
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
    mst_rec         masters_rec;
-- 2008/10/27 v1.5 T.Yoshimoto Add Start
    ln_count      NUMBER;
    lv_doc_num    xxpo_rcv_and_rtn_txns.source_document_number%TYPE;
    ln_line_num   xxpo_rcv_and_rtn_txns.source_document_line_num%TYPE;
-- 2008/10/27 v1.5 T.Yoshimoto Add End
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
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    gn_proc_flg   := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ================================
    -- D-1.�O����
    -- ================================
    init_proc(
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ================================
    -- D-2.�p�����[�^�`�F�b�N
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
    -- D-3.�������擾
    -- ================================
    get_mast_data(
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
-- 2008/10/27 v1.5 T.Yoshimoto Add Start
    <<number_get_loop>>
    FOR i IN 0..gt_master_tbl.COUNT-1 LOOP
--
      mst_rec := gt_master_tbl(i);
--
      IF ((i = 0)
       OR (lv_doc_num <> mst_rec.h_segment1)
       OR (ln_line_num <> mst_rec.line_num)) THEN
--
        lv_doc_num  := mst_rec.h_segment1;
        ln_line_num := mst_rec.line_num;
--
        -- �����擾
        SELECT COUNT(xrrt.txns_id)
        INTO   ln_count
        FROM   xxpo_rcv_and_rtn_txns xrrt
        WHERE  xrrt.source_document_number   = mst_rec.h_segment1
        AND    xrrt.source_document_line_num = mst_rec.line_num
        AND    ROWNUM = 1;
      END IF;
--
      ln_count := ln_count + 1;
      gt_rtn_line_num(i) := ln_count;
    END LOOP number_get_loop;
-- 2008/10/27 v1.5 T.Yoshimoto Add End
--
    <<main_proc_loop>>
    FOR i IN 0..gt_master_tbl.COUNT-1 LOOP
      mst_rec := gt_master_tbl(i);
--
      -- ================================
      -- D-4.������ѓo�^����
      -- ================================
      insert_opif(
        mst_rec,            -- �Ώۃf�[�^
-- 2008/10/27 v1.5 T.Yoshimoto Add Start
        gt_rtn_line_num(i), -- ���������הԍ�
-- 2008/10/27 v1.5 T.Yoshimoto Add End
        lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ================================
      -- D-5.�������׍X�V
      -- ================================
      upd_po_lines(
        mst_rec,            -- �Ώۃf�[�^
        lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ���b�g�Ǘ��i�̂ݎ��s 2008/04/30 �C��
      IF (mst_rec.lot_ctl = gn_lot_ctl_on) THEN
--
        -- ================================
        -- D-6.���b�g�}�X�^�X�V
        -- ================================
        upd_lot_mst(
          mst_rec,            -- �Ώۃf�[�^
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
      -- D-7.�����o�Ɏ�����o�^
      -- ================================
      insert_tran(
        mst_rec,            -- �Ώۃf�[�^
        lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ================================
      -- D-8.���������������o��
      -- ================================
      disp_report(
        mst_rec,            -- �Ώۃf�[�^
        lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    END LOOP main_proc_loop;
--
    -- ================================
    -- D-9.�����X�e�[�^�X�X�V
    -- ================================
    upd_po_headrs(
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ================================
    -- D-10.����I�[�v��IF�̃f�[�^���f
    -- ================================
    commit_opif(
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ================================
    -- D-11.���������o��
    -- ================================
    disp_count(
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
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
    errbuf           OUT NOCOPY VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode          OUT NOCOPY VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_po_number  IN            VARCHAR2)         -- 1.�����ԍ�
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
    --��؂蕶���o��
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
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
/*
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00008','CNT',TO_CHAR(gn_target_cnt));
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
    --�X�L�b�v�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00011','CNT',TO_CHAR(gn_warn_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
*/
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
END xxpo310001c;
/
