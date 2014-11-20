CREATE OR REPLACE PACKAGE BODY xxpo940005c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXPO940005C(body)
 * Description      : �x���˗��A�b�v���[�h����
 * MD.050           : �����I�����C��   T_MD050_BPO_940
 * MD.070           : �x���˗��A�b�v���[�h���� T_MD070_BPO_94E
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init_proc              �֘A�f�[�^�擾 (E-1)
 *  get_upload_data_proc   �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�擾 (E-2)
 *  check_proc             �Ó����`�F�b�N (E-3,4,5)
 *  set_data_proc          �o�^�f�[�^�ݒ�
 *  insert_header_proc     �w�b�_�o�^ (E-6)
 *  insert_details_proc    ���דo�^ (E-7)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/06/09    1.0   Oracle �Ŗ�       ����쐬
 *  2008/07/08    1.1   Oracle �R����_   I_S_192�Ή�
 *  2008/07/17    1.2   Oracle �Ŗ�       MD050�w�E����#13�Ή�
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
--
  check_lock_expt           EXCEPTION;     -- ���b�N�擾�G���[
  no_data_if_expt           EXCEPTION;     -- �Ώۃf�[�^�Ȃ�
--
  PRAGMA EXCEPTION_INIT(check_lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name       CONSTANT VARCHAR2(100) := 'xxpo940005c'; -- �p�b�P�[�W��
--
  gv_c_msg_kbn      CONSTANT VARCHAR2(5)   := 'XXINV';
  gv_c_msg_kbn_xxpo CONSTANT VARCHAR2(5)   := 'XXPO';
--
  -- ���b�Z�[�W�ԍ�
  -- �e�[�u�����b�N�G���[
  gv_c_msg_94e_001   CONSTANT VARCHAR2(15)  := 'APP-XXPO-10216';
  -- �f�[�^�擾�G���[
  gv_c_msg_94e_002   CONSTANT VARCHAR2(15)  := 'APP-XXPO-10217';
  -- �`���p�}�ԃG���[
  gv_c_msg_94e_003   CONSTANT VARCHAR2(15)  := 'APP-XXPO-10218';
  -- �t�H�[�}�b�g�`�F�b�N�G���[
  gv_c_msg_94e_004   CONSTANT VARCHAR2(15)  := 'APP-XXPO-10219';
  -- �v���t�@�C���擾�G���[
  gv_c_msg_94e_005   CONSTANT VARCHAR2(15)  := 'APP-XXPO-10220';
--
  -- �t�@�C����
  gv_c_msg_99e_101   CONSTANT VARCHAR2(15)  := 'APP-XXPO-10222';
  -- �A�b�v���[�h����
  gv_c_msg_99e_103   CONSTANT VARCHAR2(15)  := 'APP-XXPO-10223';
  -- �t�@�C���A�b�v���[�h����
  gv_c_msg_99e_104   CONSTANT VARCHAR2(15)  := 'APP-XXPO-10224';
  -- �t�H�[�}�b�g�p�^�[��
  gv_c_msg_99e_105   CONSTANT VARCHAR2(15)  := 'APP-XXPO-10225';
--
  -- �g�[�N��
  gv_c_tkn_ng_profile          CONSTANT VARCHAR2(10)   := 'NG_PROFILE';
  gv_c_tkn_table               CONSTANT VARCHAR2(15)   := 'TABLE';
  gv_c_tkn_item                CONSTANT VARCHAR2(15)   := 'ITEM';
  gv_c_tkn_value               CONSTANT VARCHAR2(15)   := 'VALUE';
  -- �v���t�@�C��
  gv_c_parge_term_002          CONSTANT VARCHAR2(20)   := 'XXPO_PURGE_TERM_002';
  gv_c_parge_term_name         CONSTANT VARCHAR2(36)   := '�p�[�W�Ώۊ���:�x���˗�';
  -- �N�C�b�N�R�[�h �^�C�v
  gv_c_lookup_type             CONSTANT VARCHAR2(17)  := 'XXINV_FILE_OBJECT';
  gv_c_format_type             CONSTANT VARCHAR2(20)  := '�t�H�[�}�b�g�p�^�[��';
  -- �Ώ�DB��
  gv_c_xxpo_mrp_file_ul_name  CONSTANT VARCHAR2(100)
                                                  := '�t�@�C���A�b�v���[�h�C���^�t�F�[�X�e�[�u��';
--
  -- *** �w�b�_���ږ� ***
  gv_c_file_id_name               CONSTANT VARCHAR2(24)   := 'FILE_ID';
  gv_c_corporation_name           CONSTANT VARCHAR2(24)   := '��Ж�';
  gv_c_data_class                 CONSTANT VARCHAR2(24)   := '�f�[�^���';
  gv_c_transfer_branch_no         CONSTANT VARCHAR2(24)   := '�`���p�}��';
  gv_c_trans_type                 CONSTANT VARCHAR2(24)   := '�����敪';
  gv_c_weight_capacity_class      CONSTANT VARCHAR2(24)   := '�d�ʗe�ϋ敪';
  gv_c_requested_department_code  CONSTANT VARCHAR2(24)   := '�˗������R�[�h';
  gv_c_instruction_post_code      CONSTANT VARCHAR2(24)   := '�w�������R�[�h';
  gv_c_vendor_code                CONSTANT VARCHAR2(24)   := '�����R�[�h';
  gv_c_ship_to_code               CONSTANT VARCHAR2(24)   := '�z����R�[�h';
  gv_c_shipped_locat_code         CONSTANT VARCHAR2(24)   := '�o�ɑq�ɃR�[�h';
  gv_c_freight_carrier_code       CONSTANT VARCHAR2(24)   := '�^���Ǝ҃R�[�h';
  gv_c_ship_date                  CONSTANT VARCHAR2(24)   := '�o�ɓ�';
  gv_c_arvl_date                  CONSTANT VARCHAR2(24)   := '���ɓ�';
  gv_c_freight_charge_class       CONSTANT VARCHAR2(24)   := '�^���敪';
  gv_c_takeback_class             CONSTANT VARCHAR2(24)   := '����敪';
  gv_c_arrival_time_from          CONSTANT VARCHAR2(24)   := '���׎���FROM';
  gv_c_arrival_time_to            CONSTANT VARCHAR2(24)   := '���׎���TO';
  gv_c_product_date               CONSTANT VARCHAR2(24)   := '������';
  gv_c_producted_item_code        CONSTANT VARCHAR2(24)   := '�����i�ڃR�[�h';
  gv_c_product_number             CONSTANT VARCHAR2(24)   := '�����ԍ�';
  gv_c_header_description         CONSTANT VARCHAR2(24)   := '�w�b�_�E�v';
  gv_c_update_date                CONSTANT VARCHAR2(24)   := '�X�V����';
--
  -- *** ���׍��ږ� ***
  gv_c_item_code                  CONSTANT VARCHAR2(24)   := '�i�ڃR�[�h';
  gv_c_futai_code                 CONSTANT VARCHAR2(24)   := '�t��';
  gv_c_request_qty                CONSTANT VARCHAR2(24)   := '�˗�����';
  gv_c_line_description           CONSTANT VARCHAR2(24)   := '���דE�v';
--
  -- *** �w�b�_���ڌ��� ***
  gn_c_corporation_name           CONSTANT NUMBER   := 5;   -- ��Ж�
  gn_c_data_class                 CONSTANT NUMBER   := 3;   -- �f�[�^���
  gn_c_transfer_branch_no         CONSTANT NUMBER   := 2;   -- �`���p�}��
  gn_c_weight_capacity_class      CONSTANT NUMBER   := 1;   -- �d�ʗe�ϋ敪
  gn_c_requested_department_code  CONSTANT NUMBER   := 4;   -- �˗������R�[�h
  gn_c_instruction_post_code      CONSTANT NUMBER   := 4;   -- �w�������R�[�h
  gn_c_vendor_code                CONSTANT NUMBER   := 4;   -- �����R�[�h
  gn_c_ship_to_code               CONSTANT NUMBER   := 4;   -- �z����R�[�h
  gn_c_shipped_locat_code         CONSTANT NUMBER   := 4;   -- �o�ɑq�ɃR�[�h
  gn_c_freight_carrier_code       CONSTANT NUMBER   := 4;   -- �^���Ǝ҃R�[�h
  gn_c_freight_charge_class       CONSTANT NUMBER   := 1;   -- �^���敪
  gn_c_takeback_class             CONSTANT NUMBER   := 1;   -- ����敪
  gn_c_arrival_time_from          CONSTANT NUMBER   := 4;   -- ���׎���FROM
  gn_c_arrival_time_to            CONSTANT NUMBER   := 4;   -- ���׎���TO
  gn_c_producted_item_code        CONSTANT NUMBER   := 7;   -- �����i�ڃR�[�h
  gn_c_product_number             CONSTANT NUMBER   := 10;  -- �����ԍ�
  gn_c_header_description         CONSTANT NUMBER   := 60;  -- �w�b�_�E�v
--
  -- *** ���׍��ڌ��� ***
  gn_c_item_code                  CONSTANT NUMBER   := 7;   -- �i�ڃR�[�h
  gn_c_futai_code                 CONSTANT NUMBER   := 1;   -- �t��
  gn_c_request_qty                CONSTANT NUMBER   := 12;  -- �˗�����
  gn_c_few_request_qty            CONSTANT NUMBER   := 3;   -- �˗�����(������)
  gn_c_line_description           CONSTANT NUMBER   := 20;  -- ���דE�v
--                                                                 
  -- *** �w�b�_���׋敪 ***
  gn_c_tranc_header             CONSTANT VARCHAR2(2)    := '10';  -- �w�b�_
  gn_c_tranc_details            CONSTANT VARCHAR2(2)    := '20';  -- ����
--
  gv_c_period                   CONSTANT VARCHAR2(1)    := '.';           -- �s���I�h
  gv_c_comma                    CONSTANT VARCHAR2(1)    := ',';           -- �J���}
  gv_c_space                    CONSTANT VARCHAR2(1)    := ' ';           -- �X�y�[�X
  gv_c_err_msg_space            CONSTANT VARCHAR2(6)    := '      ';      -- �X�y�[�X�i6byte�j
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- CSV���i�[���郌�R�[�h
  TYPE file_data_rec IS RECORD(
    corporation_name            VARCHAR2(32767), -- ��Ж�
    data_class                  VARCHAR2(32767), -- �f�[�^���
    transfer_branch_no          VARCHAR2(32767), -- �`���p�}��
    trans_type                  VARCHAR2(32767), -- �����敪
    weight_capacity_class       VARCHAR2(32767), -- �d�ʗe�ϋ敪
    requested_department_code   VARCHAR2(32767), -- �˗������R�[�h
    instruction_post_code       VARCHAR2(32767), -- �w�������R�[�h
    vendor_code                 VARCHAR2(32767), -- �����R�[�h
    ship_to_code                VARCHAR2(32767), -- �z����R�[�h
    shipped_locat_code          VARCHAR2(32767), -- �o�ɑq�ɃR�[�h
    freight_carrier_code        VARCHAR2(32767), -- �^���Ǝ҃R�[�h
    ship_date                   VARCHAR2(32767), -- �o�ɓ�
    arvl_date                   VARCHAR2(32767), -- ���ɓ�
    freight_charge_class        VARCHAR2(32767), -- �^���敪
    takeback_class              VARCHAR2(32767), -- ����敪
    arrival_time_from           VARCHAR2(32767), -- ���׎���FROM
    arrival_time_to             VARCHAR2(32767), -- ���׎���TO
    product_date                VARCHAR2(32767), -- ������
    producted_item_code         VARCHAR2(32767), -- �����i�ڃR�[�h
    product_number              VARCHAR2(32767), -- �����ԍ�
    header_description          VARCHAR2(32767), -- �w�b�_�E�v
    item_code                   VARCHAR2(32767), -- �i�ڃR�[�h
    futai_code                  VARCHAR2(32767), -- �t��
    request_qty                 VARCHAR2(32767), -- �˗�����
    line_description            VARCHAR2(32767), -- ���דE�v
    update_date                 VARCHAR2(32767), -- �X�V����
    line                        VARCHAR2(32767), -- �s���e�S�āi��������p�j
    err_message                 VARCHAR2(32767)  -- �G���[���b�Z�[�W�i��������p�j
  );
--
  -- CSV���i�[���錋���z��
  TYPE file_data_tbl IS TABLE OF file_data_rec INDEX BY BINARY_INTEGER;
  fdata_tbl file_data_tbl;
--
  -- �o�^�pPL/SQL�\�^�i�w�b�_�j
  -- �w�b�_ID
  TYPE  header_id_type                  IS TABLE OF  
      xxpo_supply_req_headers_if.supply_req_headers_if_id%TYPE  INDEX BY BINARY_INTEGER;
  -- ��Ж�
  TYPE  h_corporation_name_type         IS TABLE OF
      xxpo_supply_req_headers_if.corporation_name%TYPE                INDEX BY BINARY_INTEGER;
  -- �f�[�^���
  TYPE  h_data_class_type               IS TABLE OF
      xxpo_supply_req_headers_if.data_class%TYPE                INDEX BY BINARY_INTEGER;
  -- �`���p�}��
  TYPE  h_transfer_branch_no_type       IS TABLE OF
      xxpo_supply_req_headers_if.transfer_branch_no%TYPE        INDEX BY BINARY_INTEGER;
  -- �����敪
  TYPE  trans_type_type                 IS TABLE OF
      xxpo_supply_req_headers_if.trans_type%TYPE                INDEX BY BINARY_INTEGER;
  -- �d�ʗe�ϋ敪
  TYPE  weight_capacity_class_type      IS TABLE OF
      xxpo_supply_req_headers_if.weight_capacity_class%TYPE     INDEX BY BINARY_INTEGER;
  -- �˗������R�[�h
  TYPE  requested_department_code_type  IS TABLE OF
      xxpo_supply_req_headers_if.requested_department_code%TYPE INDEX BY BINARY_INTEGER;
  -- �w�������R�[�h
  TYPE  instruction_post_code_type      IS TABLE OF
      xxpo_supply_req_headers_if.instruction_post_code%TYPE     INDEX BY BINARY_INTEGER;
  -- �����R�[�h
  TYPE  vendor_code_type                IS TABLE OF
      xxpo_supply_req_headers_if.vendor_code%TYPE               INDEX BY BINARY_INTEGER;
  -- �z����R�[�h
  TYPE  ship_to_code_type               IS TABLE OF
      xxpo_supply_req_headers_if.ship_to_code%TYPE              INDEX BY BINARY_INTEGER;
  -- �o�ɑq�ɃR�[�h
  TYPE  shipped_locat_code_type         IS TABLE OF
      xxpo_supply_req_headers_if.shipped_locat_code%TYPE        INDEX BY BINARY_INTEGER;
  -- �^���Ǝ҃R�[�h
  TYPE  freight_carrier_code_type       IS TABLE OF
      xxpo_supply_req_headers_if.freight_carrier_code%TYPE      INDEX BY BINARY_INTEGER;
  -- �o�ɓ�
  TYPE  ship_date_type                  IS TABLE OF
      xxpo_supply_req_headers_if.ship_date%TYPE                 INDEX BY BINARY_INTEGER;
  -- ���ɓ�
  TYPE  arvl_date_type                  IS TABLE OF
      xxpo_supply_req_headers_if.arvl_date%TYPE                 INDEX BY BINARY_INTEGER;
  -- �^���敪
  TYPE  freight_charge_class_type       IS TABLE OF
      xxpo_supply_req_headers_if.freight_charge_class%TYPE      INDEX BY BINARY_INTEGER;
  -- ����敪
  TYPE  takeback_class_type             IS TABLE OF
      xxpo_supply_req_headers_if.takeback_class%TYPE            INDEX BY BINARY_INTEGER;
  -- ���׎���FROM
  TYPE  arrival_time_from_type          IS TABLE OF
      xxpo_supply_req_headers_if.arrival_time_from%TYPE         INDEX BY BINARY_INTEGER;
  -- ���׎���TO
  TYPE  arrival_time_to_type            IS TABLE OF
      xxpo_supply_req_headers_if.arrival_time_to%TYPE           INDEX BY BINARY_INTEGER;
  -- ������
  TYPE  product_date_type               IS TABLE OF
      xxpo_supply_req_headers_if.product_date%TYPE              INDEX BY BINARY_INTEGER;
  -- �����i�ڃR�[�h
  TYPE  producted_item_code_type        IS TABLE OF
      xxpo_supply_req_headers_if.producted_item_code%TYPE       INDEX BY BINARY_INTEGER;
  -- �����ԍ�
  TYPE  product_number_type             IS TABLE OF
      xxpo_supply_req_headers_if.product_number%TYPE            INDEX BY BINARY_INTEGER;
  -- �w�b�_�E�v
  TYPE  header_description_type         IS TABLE OF
      xxpo_supply_req_headers_if.header_description%TYPE        INDEX BY BINARY_INTEGER;
  -- �X�V����
  TYPE  h_update_date_type              IS TABLE OF
      xxpo_supply_req_headers_if.last_update_date%TYPE          INDEX BY BINARY_INTEGER;
--
  gt_header_id_tab                  header_id_type;
  gt_h_corporation_name_tab         h_corporation_name_type;
  gt_h_data_class_tab               h_data_class_type;
  gt_h_transfer_branch_no_tab       h_transfer_branch_no_type;
  gt_trans_type_tab                 trans_type_type;
  gt_weight_capacity_class_tab      weight_capacity_class_type;
  gt_requested_dep_code_tab         requested_department_code_type;
  gt_instruction_post_code_tab      instruction_post_code_type;
  gt_vendor_code_tab                vendor_code_type;
  gt_ship_to_code_tab               ship_to_code_type;
  gt_shipped_locat_code_tab         shipped_locat_code_type;
  gt_freight_carrier_code_tab       freight_carrier_code_type;
  gt_ship_date_tab                  ship_date_type;
  gt_arvl_date_tab                  arvl_date_type;
  gt_freight_charge_class_tab       freight_charge_class_type;
  gt_takeback_class_tab             takeback_class_type;
  gt_arrival_time_from_tab          arrival_time_from_type;
  gt_arrival_time_to_tab            arrival_time_to_type;
  gt_product_date_tab               product_date_type;
  gt_producted_item_code_tab        producted_item_code_type;
  gt_product_number_tab             product_number_type;
  gt_header_description_tab         header_description_type;
  gt_h_update_date_tab              h_update_date_type;
--
  -- �o�^�pPL/SQL�\�^�i���ׁj
  -- ����ID
  TYPE  line_id_type                    IS TABLE OF
      xxpo_supply_req_lines_if.supply_req_lines_if_id%TYPE    INDEX BY BINARY_INTEGER;
  -- ��Ж�
  TYPE  l_corporation_name_type         IS TABLE OF
      xxpo_supply_req_lines_if.corporation_name%TYPE          INDEX BY BINARY_INTEGER;
  -- �f�[�^���
  TYPE  l_data_class_type               IS TABLE OF
      xxpo_supply_req_lines_if.data_class%TYPE                INDEX BY BINARY_INTEGER;
  -- �`���p�}��
  TYPE  l_transfer_branch_no_type       IS TABLE OF
      xxpo_supply_req_lines_if.transfer_branch_no%TYPE        INDEX BY BINARY_INTEGER;
  -- �w�b�_ID
  TYPE  line_header_id_type             IS TABLE OF
      xxpo_supply_req_lines_if.supply_req_headers_if_id%TYPE  INDEX BY BINARY_INTEGER;
  -- ���הԍ�
  TYPE  line_number_type                IS TABLE OF
      xxpo_supply_req_lines_if.line_number%TYPE               INDEX BY BINARY_INTEGER;
  -- �i�ڃR�[�h
  TYPE  item_code_type                  IS TABLE OF
      xxpo_supply_req_lines_if.item_code%TYPE                 INDEX BY BINARY_INTEGER;
  -- �t��
  TYPE  futai_code_type                 IS TABLE OF
      xxpo_supply_req_lines_if.futai_code%TYPE                INDEX BY BINARY_INTEGER;
  -- �˗�����
  TYPE  request_qty_type                IS TABLE OF
      xxpo_supply_req_lines_if.request_qty%TYPE               INDEX BY BINARY_INTEGER;
  -- ���דE�v
  TYPE  line_description_type           IS TABLE OF
      xxpo_supply_req_lines_if.line_description%TYPE          INDEX BY BINARY_INTEGER;
  -- �X�V����
  TYPE  l_update_date_type              IS TABLE OF
      xxpo_supply_req_lines_if.last_update_date%TYPE          INDEX BY BINARY_INTEGER;
--
  gt_line_id_tab                    line_id_type;
  gt_l_corporation_name_tab         l_corporation_name_type;
  gt_l_data_class_tab               l_data_class_type;
  gt_l_transfer_branch_no_tab       l_transfer_branch_no_type;
  gt_line_header_id_tab             line_header_id_type;
  gt_line_number_tab                line_number_type;
  gt_item_code_tab                  item_code_type;
  gt_futai_code_tab                 futai_code_type;
  gt_request_qty_tab                request_qty_type;
  gt_line_description_tab           line_description_type;
  gt_l_update_date_tab              l_update_date_type;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_header_count           NUMBER;           -- �w�b�_�f�[�^����
  gn_line_count             NUMBER;           -- ���׃f�[�^����
--
  gd_sysdate                DATE;             -- �V�X�e�����t
  gn_user_id                NUMBER;           -- ���[�UID
  gn_login_id               NUMBER;           -- �ŏI�X�V���O�C��
  gn_conc_request_id        NUMBER;           -- �v��ID
  gn_prog_appl_id           NUMBER;           -- �ݶ��āE��۸��т̱��ع����ID
  gn_conc_program_id        NUMBER;           -- �R���J�����g�E�v���O����ID
--
  gn_xxpo_parge_term        NUMBER;                          -- �p�[�W�Ώۊ���
  gv_file_name              VARCHAR2(256);                   -- �t�@�C����
  gv_file_up_name           VARCHAR2(256);                   -- �t�@�C���A�b�v���[�h����
  gn_created_by             NUMBER(15);                      -- �쐬��
  gd_creation_date          DATE;                            -- �쐬��
  gv_check_proc_retcode     VARCHAR2(1);                     -- �Ó����`�F�b�N�X�e�[�^�X
--
   /**********************************************************************************
   * Procedure Name   : init_proc
   * Description      : �֘A�f�[�^�擾 (E-1)
   ***********************************************************************************/
  PROCEDURE init_proc(
    in_file_format  IN  VARCHAR2,     --  �t�H�[�}�b�g�p�^�[��
    ov_errbuf       OUT VARCHAR2,     --  �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2,     --  ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT VARCHAR2)     --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init_proc'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
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
    lv_parge_term       VARCHAR2(100);    -- �v���t�@�C���i�[�ꏊ
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
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �V�X�e�����t�擾
    gd_sysdate := SYSDATE;
    -- WHO�J�������擾
    gn_user_id          := FND_GLOBAL.USER_ID;              -- ���[�UID
    gn_login_id         := FND_GLOBAL.LOGIN_ID;             -- �ŏI�X�V���O�C��
    gn_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID;      -- �v��ID
    gn_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;         -- �ݶ��āE��۸��т̱��ع����ID
    gn_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID;      -- �R���J�����g�E�v���O����ID
--
    -- �v���t�@�C���u�p�[�W�Ώۊ��ԁv�擾
    lv_parge_term := FND_PROFILE.VALUE(gv_c_parge_term_002);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (lv_parge_term IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_xxpo,
                                            gv_c_msg_94e_005,
                                            gv_c_tkn_ng_profile,
                                            gv_c_parge_term_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �v���t�@�C���l�`�F�b�N
    BEGIN
      -- TO_NUMBER�ł��Ȃ���΃G���[
      gn_xxpo_parge_term := TO_NUMBER(lv_parge_term);
    EXCEPTION
      WHEN INVALID_NUMBER OR VALUE_ERROR THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_xxpo,
                                            gv_c_msg_94e_005,
                                            gv_c_tkn_ng_profile,
                                            gv_c_parge_term_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END;
--
    -- �t�@�C���A�b�v���[�h���̎擾
    BEGIN
      SELECT  xlvv.meaning
      INTO    gv_file_up_name
      FROM    xxcmn_lookup_values_v xlvv                -- �N�C�b�N�R�[�hVIEW
      WHERE   xlvv.lookup_type = gv_c_lookup_type       -- �^�C�v
      AND     xlvv.lookup_code = in_file_format         -- �R�[�h
      AND     ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN                             --*** �f�[�^�擾�G���[ ***
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_xxpo,
                                              gv_c_msg_94e_002,
                                              gv_c_tkn_item,
                                              gv_c_format_type,
                                              gv_c_tkn_value,
                                              in_file_format);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
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
  END init_proc;
--
  /**********************************************************************************
   * Procedure Name   : get_upload_data_proc
   * Description      : �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�擾 (E-2)
   ***********************************************************************************/
  PROCEDURE get_upload_data_proc(
    in_file_id    IN  NUMBER,       --   �t�@�C���h�c
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_upload_data_proc'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
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
    lv_line       VARCHAR2(32767);    -- ���s�R�[�h���̏��
    ln_col        NUMBER;             -- �J����
    lb_col        BOOLEAN  := TRUE;   -- �J�����쐬�p��
    ln_length     NUMBER;             -- �����ۊǗp
--
    lt_file_line_data   xxcmn_common3_pkg.g_file_data_tbl;  -- �s�e�[�u���i�[�̈�
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
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�擾
    -- �s���b�N����
    SELECT xmf.file_name,    -- �t�@�C����
           xmf.created_by,   -- �쐬��
           xmf.creation_date -- �쐬��
    INTO   gv_file_name,
           gn_created_by,
           gd_creation_date
    FROM   xxinv_mrp_file_ul_interface xmf
    WHERE  xmf.file_id = in_file_id
    FOR UPDATE OF xmf.file_id NOWAIT;
--
    -- **************************************************
    -- *** �t�@�C���A�b�v���[�h�C���^�[�t�F�[�X�f�[�^�擾
    -- **************************************************
    xxcmn_common3_pkg.blob_to_varchar2(
      in_file_id,         -- �t�@�C���h�c
      lt_file_line_data,  -- �ϊ���VARCHAR2�f�[�^
      lv_errbuf,          -- �G���[�E���b�Z�[�W             --# �Œ� #
      lv_retcode,         -- ���^�[�� �E�R�[�h              --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W   --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �^�C�g���s�̂݁A���́A2�s�ڂ����s�݂̂̏ꍇ
    IF (lt_file_line_data.LAST < 2) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_xxpo,
                                            gv_c_msg_94e_002,
                                            gv_c_tkn_item,
                                            gv_c_file_id_name,
                                            gv_c_tkn_value,
                                            in_file_id);
      lv_errbuf := lv_errmsg;
      RAISE no_data_if_expt;
    END IF;
--
    -- **************************************************
    -- *** �擾�����f�[�^���s���̃��[�v�i2�s�ڂ���j
    -- **************************************************
    <<line_loop>>
    FOR ln_index IN 2 .. lt_file_line_data.LAST LOOP
--
      -- �Ώی����J�E���g
      gn_target_cnt := gn_target_cnt + 1;
--
      -- �s���ɍ�Ɨ̈�Ɋi�[
      lv_line := lt_file_line_data(ln_index);
--
      -- 1�s�̓��e�� line �Ɋi�[
      fdata_tbl(gn_target_cnt).line := lv_line;
--
      -- �J�����ԍ�������
      ln_col := 0;    --�J����
      lb_col := TRUE; --�J�����쐬�p��
--
      -- **************************************************
      -- *** 1�s���J���}���ɕ���
      -- **************************************************
      <<comma_loop>>
      LOOP
        --lv_line�̒�����0�Ȃ�I��
        EXIT WHEN ((lb_col = FALSE) OR (lv_line IS NULL));
--
        -- �J�����ԍ����J�E���g
        ln_col := ln_col + 1;
--
        -- �J���}�̈ʒu���擾
        ln_length := instr(lv_line, gv_c_comma);
        -- �J���}���Ȃ�
        IF (ln_length = 0) THEN
          ln_length := LENGTH(lv_line);
          lb_col    := FALSE;
        -- �J���}������
        ELSE
          ln_length := ln_length -1;
          lb_col    := TRUE;
        END IF;
--
        -- CSV�`�������ڂ��ƂɃ��R�[�h�Ɋi�[
        IF (ln_col = 1) THEN
          fdata_tbl(gn_target_cnt).corporation_name           := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 2) THEN
          fdata_tbl(gn_target_cnt).data_class                 := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 3) THEN
          fdata_tbl(gn_target_cnt).transfer_branch_no         := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 4) THEN
          fdata_tbl(gn_target_cnt).trans_type                 := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 5) THEN
          fdata_tbl(gn_target_cnt).weight_capacity_class      := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 6) THEN
          fdata_tbl(gn_target_cnt).requested_department_code  := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 7) THEN
          fdata_tbl(gn_target_cnt).instruction_post_code      := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 8) THEN
          fdata_tbl(gn_target_cnt).vendor_code                := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 9) THEN
          fdata_tbl(gn_target_cnt).ship_to_code               := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 10) THEN
          fdata_tbl(gn_target_cnt).shipped_locat_code         := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 11) THEN
          fdata_tbl(gn_target_cnt).freight_carrier_code       := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 12) THEN
          fdata_tbl(gn_target_cnt).ship_date                  := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 13) THEN
          fdata_tbl(gn_target_cnt).arvl_date                  := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 14) THEN
          fdata_tbl(gn_target_cnt).freight_charge_class       := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 15) THEN
          fdata_tbl(gn_target_cnt).takeback_class             := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 16) THEN
          fdata_tbl(gn_target_cnt).arrival_time_from          := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 17) THEN
          fdata_tbl(gn_target_cnt).arrival_time_to            := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 18) THEN
          fdata_tbl(gn_target_cnt).product_date               := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 19) THEN
          fdata_tbl(gn_target_cnt).producted_item_code        := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 20) THEN
          fdata_tbl(gn_target_cnt).product_number             := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 21) THEN
          fdata_tbl(gn_target_cnt).header_description         := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 22) THEN
          fdata_tbl(gn_target_cnt).item_code                  := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 23) THEN
          fdata_tbl(gn_target_cnt).futai_code                 := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 24) THEN
          fdata_tbl(gn_target_cnt).request_qty                := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 25) THEN
          fdata_tbl(gn_target_cnt).line_description           := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 26) THEN
          fdata_tbl(gn_target_cnt).update_date                := SUBSTR(lv_line, 1, ln_length);
        END IF;
--
        -- str�͍���擾�����s�������i�J���}�͂̂������߁Aln_length + 2�j
        IF (lb_col = TRUE) THEN
          lv_line := SUBSTR(lv_line, ln_length + 2);
        ELSE
          lv_line := SUBSTR(lv_line, ln_length);
        END IF;
--
      END LOOP comma_loop;
    END LOOP line_loop;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN no_data_if_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_retcode := gv_status_warn;
--
    WHEN check_lock_expt THEN                           --*** ���b�N�擾�G���[ ***
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_xxpo,
                                            gv_c_msg_94e_001,
                                            gv_c_tkn_table,
                                            gv_c_xxpo_mrp_file_ul_name);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
    WHEN NO_DATA_FOUND THEN                             --*** �f�[�^�擾�G���[ ***
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_xxpo,
                                            gv_c_msg_94e_002,
                                            gv_c_tkn_item,
                                            gv_c_file_id_name,
                                            gv_c_tkn_value,
                                            in_file_id);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
--#################################  �Œ��O������ START   ####################################
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
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
  END get_upload_data_proc;
--
  /**********************************************************************************
   * Procedure Name   : check_proc
   * Description      : �Ó����`�F�b�N (E-3,4,5)
   ***********************************************************************************/
  PROCEDURE check_proc(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_proc'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
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
    lv_line_feed        VARCHAR2(1);                  -- ���s�R�[�h
--
    -- �����ڐ�
    ln_c_col         CONSTANT NUMBER      := 26;
--
    -- *** ���[�J���ϐ� ***
    lv_log_data                                      VARCHAR2(32767);  -- LOG�f�[�^���ޔ�p
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
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    -- ������
    gv_check_proc_retcode := gv_status_normal; -- �Ó����`�F�b�N�X�e�[�^�X
    lv_line_feed := CHR(10);                   -- ���s�R�[�h
--
    -- **************************************************
    -- *** �擾�������R�[�h���ɍ��ڃ`�F�b�N���s���B
    -- **************************************************
    <<check_loop>>
    FOR ln_index IN 1 .. fdata_tbl.LAST LOOP
--
      -- **************************************************
      -- *** ���ڐ��`�F�b�N
      -- **************************************************
      -- �i�s�S�̂̒����|�s����J���}�𔲂����������J���}�̐��j
      --    <> �i�����ȍ��ڐ��|�P�������ȃJ���}�̐��j
      IF ((NVL(LENGTH(fdata_tbl(ln_index).line) ,0)
           - NVL(LENGTH(REPLACE(fdata_tbl(ln_index).line,gv_c_comma,NULL)),0))
             <> (ln_c_col - 1)) THEN
        fdata_tbl(ln_index).err_message := gv_c_err_msg_space
                                           || gv_c_err_msg_space
                                           || xxcmn_common_pkg.get_msg(gv_c_msg_kbn_xxpo,
                                                                       gv_c_msg_94e_004)
                                           || lv_line_feed;
      ELSE
        -- **************************************************
        -- *** ���ڃ`�F�b�N�i�w�b�_�^���ׁj
        -- **************************************************
        -- �w�b�_�[�̏ꍇ
        IF (fdata_tbl(ln_index).transfer_branch_no = gn_c_tranc_header) THEN
          -- ==============================
          --  ��Ж�
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_corporation_name,
                                              fdata_tbl(ln_index).corporation_name,
                                              gn_c_corporation_name,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          --  �f�[�^���
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_data_class,
                                              fdata_tbl(ln_index).data_class,
                                              gn_c_data_class,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- �����敪
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_trans_type,
                                              fdata_tbl(ln_index).trans_type,
                                              NULL,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ng,
                                              xxcmn_common3_pkg.gv_attr_num,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- �d�ʗe�ϋ敪
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_weight_capacity_class,
                                              fdata_tbl(ln_index).weight_capacity_class,
                                              gn_c_weight_capacity_class,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ng,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- �˗������R�[�h
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_requested_department_code,
                                              fdata_tbl(ln_index).requested_department_code,
                                              gn_c_requested_department_code,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ng,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- �w�������R�[�h
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_instruction_post_code,
                                              fdata_tbl(ln_index).instruction_post_code,
                                              gn_c_instruction_post_code,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- �����R�[�h
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_vendor_code,
                                              fdata_tbl(ln_index).vendor_code,
                                              gn_c_vendor_code,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ng,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- �z����R�[�h
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_ship_to_code,
                                              fdata_tbl(ln_index).ship_to_code,
                                              gn_c_ship_to_code,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ng,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- �o�ɑq�ɃR�[�h
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_shipped_locat_code,
                                              fdata_tbl(ln_index).shipped_locat_code,
                                              gn_c_shipped_locat_code,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ng,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- �^���Ǝ҃R�[�h
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_freight_carrier_code,
                                              fdata_tbl(ln_index).freight_carrier_code,
                                              gn_c_freight_carrier_code,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ng,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- �o�ɓ�
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_ship_date,
                                              fdata_tbl(ln_index).ship_date,
                                              NULL,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ng,
                                              xxcmn_common3_pkg.gv_attr_dat,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- ���ɓ�
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_arvl_date,
                                              fdata_tbl(ln_index).arvl_date,
                                              NULL,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ng,
                                              xxcmn_common3_pkg.gv_attr_dat,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- �^���敪
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_freight_charge_class,
                                              fdata_tbl(ln_index).freight_charge_class,
                                              gn_c_freight_charge_class,
                                              NULL,
-- 2008/07/17 v1.6 Update Start
--                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_null_ng,
-- 2008/07/17 v1.6 Update End
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- ����敪
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_takeback_class,
                                              fdata_tbl(ln_index).takeback_class,
                                              gn_c_takeback_class,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- ���׎���FROM
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_arrival_time_from,
                                              fdata_tbl(ln_index).arrival_time_from,
                                              gn_c_arrival_time_from,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- ���׎���TO
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_arrival_time_to,
                                              fdata_tbl(ln_index).arrival_time_to,
                                              gn_c_arrival_time_to,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- ������
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_product_date,
                                              fdata_tbl(ln_index).product_date,
                                              NULL,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_dat,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- �����i�ڃR�[�h
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_producted_item_code,
                                              fdata_tbl(ln_index).producted_item_code,
                                              gn_c_producted_item_code,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- �����ԍ�
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_product_number,
                                              fdata_tbl(ln_index).product_number,
                                              gn_c_product_number,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- �w�b�_�E�v
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_header_description,
                                              fdata_tbl(ln_index).header_description,
                                              gn_c_header_description,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
        -- ���ׂ̏ꍇ
        ELSIF (fdata_tbl(ln_index).transfer_branch_no = gn_c_tranc_details) THEN
          -- ==============================
          --  ��Ж�
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_corporation_name,
                                              fdata_tbl(ln_index).corporation_name,
                                              gn_c_corporation_name,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          --  �f�[�^���
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_data_class,
                                              fdata_tbl(ln_index).data_class,
                                              gn_c_data_class,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- �i�ڃR�[�h
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_item_code,
                                              fdata_tbl(ln_index).item_code,
                                              gn_c_item_code,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ng,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- �t��
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_futai_code,
                                              fdata_tbl(ln_index).futai_code,
                                              gn_c_futai_code,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- �˗�����
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_request_qty,
                                              fdata_tbl(ln_index).request_qty,
                                              gn_c_request_qty,
                                              gn_c_few_request_qty,
                                              xxcmn_common3_pkg.gv_null_ng,
                                              xxcmn_common3_pkg.gv_attr_num,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- ���דE�v
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_line_description,
                                              fdata_tbl(ln_index).line_description,
                                              gn_c_line_description,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
        -- �`���p�}�Ԃ��s���ȏꍇ
        ELSE
          fdata_tbl(ln_index).err_message := gv_c_err_msg_space
                                             || gv_c_err_msg_space
                                             || xxcmn_common_pkg.get_msg(gv_c_msg_kbn_xxpo,
                                                                         gv_c_msg_94e_003)
                                             || lv_line_feed;
        END IF;
      END IF;
--
      -- **************************************************
      -- *** �G���[����
      -- **************************************************
      -- �`�F�b�N�G���[����̏ꍇ
      IF (fdata_tbl(ln_index).err_message IS NOT NULL) THEN
--
        -- **************************************************
        -- *** �f�[�^���o�͏����i�s�� + SPACE + �s�S�̂̃f�[�^�j
        -- **************************************************
        lv_log_data := NULL;
        lv_log_data := TO_CHAR(ln_index,'99999') || gv_c_space || fdata_tbl(ln_index).line;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_log_data);
--
        -- �G���[���b�Z�[�W���o��
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RTRIM(fdata_tbl(ln_index).err_message, lv_line_feed));
        -- �Ó����`�F�b�N�X�e�[�^�X
        gv_check_proc_retcode := gv_status_error;
        -- �G���[�����J�E���g
        gn_error_cnt := gn_error_cnt + 1;
--
      -- �`�F�b�N�G���[�Ȃ��̏ꍇ
      ELSE
        -- ���������J�E���g
        gn_normal_cnt := gn_normal_cnt + 1;
      END IF;
--
    END LOOP check_loop;
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
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
  END check_proc;
--
  /**********************************************************************************
   * Procedure Name   : set_data_proc
   * Description      : �o�^�f�[�^�ݒ�
   ***********************************************************************************/
  PROCEDURE set_data_proc(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_data_proc'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
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
    ln_header_id      NUMBER;   -- �w�b�_ID
    ln_line_id        NUMBER;   -- ����ID
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
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ����������
    gn_line_count     := 0;
    gn_header_count   := 0;
--
    -- ���[�J���ϐ�������
    ln_header_id      := NULL;
    ln_line_id        := NULL;
--
    -- **************************************************
    -- *** �o�^�pPL/SQL�\�ҏW�i2�s�ڂ���j
    -- **************************************************
    <<fdata_loop>>
    FOR ln_index IN 1 .. fdata_tbl.LAST LOOP
--
      -- �w�b�_�o�^
      IF (fdata_tbl(ln_index).transfer_branch_no = gn_c_tranc_header) THEN
--
        -- �w�b�_���� �C���N�������g
        gn_header_count  := gn_header_count + 1;
--
        -- �w�b�_ID�̔�
        SELECT xxpo_supply_req_headers_if_s1.NEXTVAL 
        INTO ln_header_id 
        FROM dual;
--
        -- �w�b�_���
        -- �w�b�_ID
        gt_header_id_tab(gn_header_count)
          := ln_header_id;
        -- ��Ж�
        gt_h_corporation_name_tab(gn_header_count)
          := fdata_tbl(ln_index).corporation_name;
        -- �f�[�^���
        gt_h_data_class_tab(gn_header_count)
          := fdata_tbl(ln_index).data_class;
        -- �`���p�}��
        gt_h_transfer_branch_no_tab(gn_header_count)
          := fdata_tbl(ln_index).transfer_branch_no;
        -- �����敪
        gt_trans_type_tab(gn_header_count)
          := fdata_tbl(ln_index).trans_type;
        -- �d�ʗe�ϋ敪
        gt_weight_capacity_class_tab(gn_header_count)
          := fdata_tbl(ln_index).weight_capacity_class;
        -- �˗������R�[�h
        gt_requested_dep_code_tab(gn_header_count)
          := fdata_tbl(ln_index).requested_department_code;
        -- �w�������R�[�h
        gt_instruction_post_code_tab(gn_header_count)
          := fdata_tbl(ln_index).instruction_post_code;
        -- �����R�[�h
        gt_vendor_code_tab(gn_header_count)
          := fdata_tbl(ln_index).vendor_code;
        -- �z����R�[�h
        gt_ship_to_code_tab(gn_header_count)
          := fdata_tbl(ln_index).ship_to_code;
        -- �o�ɑq�ɃR�[�h
        gt_shipped_locat_code_tab(gn_header_count)
          := fdata_tbl(ln_index).shipped_locat_code;
        -- �^���Ǝ҃R�[�h
        gt_freight_carrier_code_tab(gn_header_count)
          := fdata_tbl(ln_index).freight_carrier_code;
        -- �o�ɓ�
        gt_ship_date_tab(gn_header_count)
          := FND_DATE.STRING_TO_DATE(fdata_tbl(ln_index).ship_date, 'YYYY/MM/DD');
        -- ���ɓ�
        gt_arvl_date_tab(gn_header_count)
          := FND_DATE.STRING_TO_DATE(fdata_tbl(ln_index).arvl_date, 'YYYY/MM/DD');
        -- �^���敪
        gt_freight_charge_class_tab(gn_header_count)
          := fdata_tbl(ln_index).freight_charge_class;
        -- ����敪
        gt_takeback_class_tab(gn_header_count)
          := fdata_tbl(ln_index).takeback_class;
        -- ���׎���FROM
        gt_arrival_time_from_tab(gn_header_count)
          := fdata_tbl(ln_index).arrival_time_from;
        -- ���׎���TO
        gt_arrival_time_to_tab(gn_header_count)
          := fdata_tbl(ln_index).arrival_time_to;
        -- ������
        gt_product_date_tab(gn_header_count)
          := FND_DATE.STRING_TO_DATE(fdata_tbl(ln_index).product_date, 'YYYY/MM/DD');
        -- �����i�ڃR�[�h
        gt_producted_item_code_tab(gn_header_count)
          := fdata_tbl(ln_index).producted_item_code;
        -- �����ԍ�
        gt_product_number_tab(gn_header_count)
          := fdata_tbl(ln_index).product_number;
        -- �w�b�_�E�v
        gt_header_description_tab(gn_header_count)
          := fdata_tbl(ln_index).header_description;
        -- �X�V����
        gt_h_update_date_tab(gn_header_count)
          := FND_DATE.STRING_TO_DATE(fdata_tbl(ln_index).update_date, 'YYYY/MM/DD HH24:MI:SS');
--
      -- ���דo�^
      ELSIF (fdata_tbl(ln_index).transfer_branch_no = gn_c_tranc_details) THEN
--
        -- ���׌��� �C���N�������g
        gn_line_count   := gn_line_count + 1;
--
        -- �ŏ��̃��R�[�h�����ׂ̏ꍇ�A�w�b�_ID���̔�
        IF (ln_header_id IS NULL) THEN
          -- �w�b�_ID�̔�
          SELECT xxpo_supply_req_headers_if_s1.NEXTVAL 
          INTO ln_header_id 
          FROM dual;
        END IF;
--
        -- ����ID�̔�
        SELECT xxpo_supply_req_lines_if_s1.NEXTVAL
        INTO ln_line_id 
        FROM dual;
--
        -- ���׏��
        -- ����ID
        gt_line_id_tab(gn_line_count)
          := ln_line_id;
        -- �w�b�_ID
        gt_line_header_id_tab(gn_line_count)
          := ln_header_id;
        -- ��Ж�
        gt_l_corporation_name_tab(gn_line_count)
          := fdata_tbl(ln_index).corporation_name;
        -- �f�[�^���
        gt_l_data_class_tab(gn_line_count)
          := fdata_tbl(ln_index).data_class;
        -- �`���p�}��
        gt_l_transfer_branch_no_tab(gn_line_count)
          := fdata_tbl(ln_index).transfer_branch_no;
        -- �i�ڃR�[�h
        gt_item_code_tab(gn_line_count)
          := fdata_tbl(ln_index).item_code;
        -- �t��
        gt_futai_code_tab(gn_line_count)
          := fdata_tbl(ln_index).futai_code;
        -- �˗����ʗ�
        gt_request_qty_tab(gn_line_count)
          := TO_NUMBER(fdata_tbl(ln_index).request_qty);
        -- ���דE�v
        gt_line_description_tab(gn_line_count)
          := fdata_tbl(ln_index).line_description;
        -- �X�V����
        gt_l_update_date_tab(gn_line_count)
          := FND_DATE.STRING_TO_DATE(fdata_tbl(ln_index).update_date, 'YYYY/MM/DD HH24:MI:SS');
      END IF;
--
    END LOOP fdata_loop;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
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
  END set_data_proc;
--
  /**********************************************************************************
   * Procedure Name   : insert_header_proc
   * Description      : �w�b�_�o�^ (E-6)
   ***********************************************************************************/
  PROCEDURE insert_header_proc(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_header_proc'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
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
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- **************************************************
    -- *** �x���˗����C���^�t�F�[�X�i�A�h�I���j�o�^
    -- **************************************************
    FORALL item_cnt IN 1 .. gn_header_count
      INSERT INTO xxpo_supply_req_headers_if
      (   supply_req_headers_if_id                  -- �x���˗����C���^�t�F�[�X�w�b�_ID
        , corporation_name                          -- ��Ж�
        , data_class                                -- �f�[�^���
        , transfer_branch_no                        -- �`���p�}��
        , trans_type                                -- �����敪
        , weight_capacity_class                     -- �d�ʗe�ϋ敪
        , requested_department_code                 -- �˗������R�[�h
        , instruction_post_code                     -- �w�������R�[�h
        , vendor_code                               -- �����R�[�h
        , ship_to_code                              -- �z����R�[�h
        , shipped_locat_code                        -- �o�ɑq�ɃR�[�h
        , freight_carrier_code                      -- �^���Ǝ҃R�[�h
        , ship_date                                 -- �o�ɓ�
        , arvl_date                                 -- ���ɓ�
        , freight_charge_class                      -- �^���敪
        , takeback_class                            -- ����敪
        , arrival_time_from                         -- ���׎���FROM
        , arrival_time_to                           -- ���׎���TO
        , product_date                              -- ������
        , producted_item_code                       -- �����i�ڃR�[�h
        , product_number                            -- �����ԍ�
        , header_description                        -- �w�b�_�E�v
        , created_by                                -- �쐬��
        , creation_date                             -- �쐬��
        , last_updated_by                           -- �ŏI�X�V��
        , last_update_date                          -- �ŏI�X�V��
        , last_update_login                         -- �ŏI�X�V���O�C��
        , request_id                                -- �v��ID
        , program_application_id                    -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        , program_id                                -- �R���J�����g�E�v���O����ID
        , program_update_date                       -- �v���O�����X�V��
      ) VALUES (
          gt_header_id_tab(item_cnt)                -- �w�b�_ID
        , gt_l_corporation_name_tab(item_cnt)       -- ��Ж�
        , gt_h_data_class_tab(item_cnt)             -- �f�[�^���
        , gt_h_transfer_branch_no_tab(item_cnt)     -- �`���p�}��
        , gt_trans_type_tab(item_cnt)               -- �����敪
        , gt_weight_capacity_class_tab(item_cnt)    -- �d�ʗe�ϋ敪
        , gt_requested_dep_code_tab(item_cnt)       -- �˗������R�[�h
        , gt_instruction_post_code_tab(item_cnt)    -- �w�������R�[�h
        , gt_vendor_code_tab(item_cnt)              -- �����R�[�h
        , gt_shipped_locat_code_tab(item_cnt)       -- �z����R�[�h
        , gt_shipped_locat_code_tab(item_cnt)       -- �o�ɑq�ɃR�[�h
        , gt_freight_carrier_code_tab(item_cnt)     -- �^���Ǝ҃R�[�h
        , gt_ship_date_tab(item_cnt)                -- �o�ɓ�
        , gt_arvl_date_tab(item_cnt)                -- ���ɓ�
        , gt_freight_charge_class_tab(item_cnt)     -- �^���敪
        , gt_takeback_class_tab(item_cnt)           -- ����敪
        , gt_arrival_time_from_tab(item_cnt)        -- ���׎���FROM
        , gt_arrival_time_to_tab(item_cnt)          -- ���׎���TO
        , gt_product_date_tab(item_cnt)             -- ������
        , gt_producted_item_code_tab(item_cnt)      -- �����i�ڃR�[�h
        , gt_product_number_tab(item_cnt)           -- �����ԍ�
        , gt_header_description_tab(item_cnt)       -- �w�b�_�E�v
        , gn_user_id                                -- �쐬��
        , gd_sysdate                                -- �쐬��
        , gn_user_id                                -- �ŏI�X�V��
        , gd_sysdate                                -- �ŏI�X�V��
        , gn_login_id                               -- �ŏI�X�V���O�C��
        , gn_conc_request_id                        -- �v��ID
        , gn_prog_appl_id                           -- �ݶ��āE��۸��т̱��ع����ID
        , gn_conc_program_id                        -- �R���J�����g�E�v���O����ID
        , gd_sysdate                                -- �v���O�����ɂ��X�V��
      );
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
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
  END insert_header_proc;
--
  /**********************************************************************************
   * Procedure Name   : insert_details_proc
   * Description      : ���דo�^ (E-7)
   ***********************************************************************************/
  PROCEDURE insert_details_proc(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_details_proc'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
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
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- **************************************************
    -- *** �x���˗����C���^�t�F�[�X���ׁi�A�h�I���j�o�^
    -- **************************************************
    FORALL item_cnt IN 1 .. gn_line_count
      INSERT INTO xxpo_supply_req_lines_if
      (   supply_req_lines_if_id                    -- �x���˗����C���^�t�F�[�X����ID
        , corporation_name                          -- ��Ж�
        , data_class                                -- �f�[�^���
        , transfer_branch_no                        -- �`���p�}��
        , supply_req_headers_if_id                  -- �x���˗����C���^�t�F�[�X�w�b�_ID
        , line_number                               -- ���הԍ�
        , item_code                                 -- �i�ڃR�[�h
        , futai_code                                -- �t��
        , request_qty                               -- �˗�����
        , line_description                          -- ���דE�v
        , created_by                                -- �쐬��
        , creation_date                             -- �쐬��
        , last_updated_by                           -- �ŏI�X�V��
        , last_update_date                          -- �ŏI�X�V��
        , last_update_login                         -- �ŏI�X�V���O�C��
        , request_id                                -- �v��ID
        , program_application_id                    -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        , program_id                                -- �R���J�����g�E�v���O����ID
        , program_update_date                       -- �v���O�����X�V��
      ) VALUES (
          gt_line_id_tab(item_cnt)                  -- ����ID
        , gt_l_corporation_name_tab(item_cnt)       -- ��Ж�
        , gt_l_data_class_tab(item_cnt)             -- �f�[�^���
        , gt_l_transfer_branch_no_tab(item_cnt)     -- �`���p�}��
        , gt_line_header_id_tab(item_cnt)           -- �w�b�_ID
        , NULL                                      -- ���הԍ�
        , gt_item_code_tab(item_cnt)                -- �i�ڃR�[�h
        , gt_futai_code_tab(item_cnt)               -- �t��
        , gt_request_qty_tab(item_cnt)              -- �˗����ʗ�
        , gt_line_description_tab(item_cnt)         -- ���דE�v
        , gn_user_id                                -- �쐬��
        , gd_sysdate                                -- �쐬��
        , gn_user_id                                -- �ŏI�X�V��
        , gd_sysdate                                -- �ŏI�X�V��
        , gn_login_id                               -- �ŏI�X�V���O�C��
        , gn_conc_request_id                        -- �v��ID
        , gn_prog_appl_id                           -- �ݶ��āE��۸��т̱��ع����ID
        , gn_conc_program_id                        -- �R���J�����g�E�v���O����ID
        , gd_sysdate                                -- �v���O�����ɂ��X�V��
      );
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
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
  END insert_details_proc;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    in_file_id     IN  NUMBER,       --   �t�@�C���h�c
    in_file_format IN  VARCHAR2,     --   �t�H�[�}�b�g�p�^�[��
    ov_errbuf      OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--
    lv_out_rep VARCHAR2(1000);  -- ���|�[�g�o��
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
    -- �Ó����`�F�b�N�X�e�[�^�X ������
    gv_check_proc_retcode := gv_status_normal;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- �֘A�f�[�^�擾 (E-1)
    -- ===============================
    init_proc(
      in_file_format,    -- �t�H�[�}�b�g�p�^�[��
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�擾 (E-2,3)
    -- ===============================
    get_upload_data_proc(
      in_file_id,        -- �t�@�C���h�c
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
-- �������ʂɂ�����炸�������ʃ��|�[�g���o�͂���
--#################################  �A�b�v���[�h�Œ胁�b�Z�[�W START  #############################
    --�������ʃ��|�[�g�o�́i�㕔�j
    -- �t�@�C����
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_xxpo,
                                              gv_c_msg_99e_101,
                                              gv_c_tkn_value,
                                              gv_file_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    -- �A�b�v���[�h����
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_xxpo,
                                              gv_c_msg_99e_103,
                                              gv_c_tkn_value,
                                              TO_CHAR(gd_creation_date,'YYYY/MM/DD HH24:MI'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    -- �t�@�C���A�b�v���[�h����
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_xxpo,
                                              gv_c_msg_99e_104,
                                              gv_c_tkn_value,
                                              gv_file_up_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    -- �t�H�[�}�b�g�p�^�[��
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_xxpo,
                                              gv_c_msg_99e_105,
                                              gv_c_tkn_value,
                                              in_file_format);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
--
--#################################  �A�b�v���[�h�Œ胁�b�Z�[�W END   ###################################
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
--
    -- 2008/07/08 Add ��
    ELSIF (lv_retcode = gv_status_warn) THEN
      ov_retcode := lv_retcode;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      RETURN;
    -- 2008/07/08 Add ��
    END IF;
--
    -- ===============================
    -- �Ó����`�F�b�N (E-4,5)
    -- ===============================
    check_proc(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
--
    -- �Ó����`�F�b�N�ŃG���[���Ȃ������ꍇ
    ELSIF (gv_check_proc_retcode = gv_status_normal) THEN
--
      -- ===============================
      -- �o�^�f�[�^�Z�b�g
      -- ===============================
      set_data_proc(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- �w�b�_�o�^ (E-6)
      -- ===============================
      insert_header_proc(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- ���דo�^ (E-7)
      -- ===============================
      insert_details_proc(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    -- ===============================
    -- �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�폜 (E-8)
    -- ===============================
    xxcmn_common3_pkg.delete_fileup_proc(
      in_file_format,                 -- �t�H�[�}�b�g�p�^�[��
      gd_sysdate,                     -- �Ώۓ��t
      gn_xxpo_parge_term,             -- �p�[�W�Ώۊ���
      lv_errbuf,                      -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,                     -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      -- �폜�����G���[����RollBack������ׁA�Ó����`�F�b�N�X�e�[�^�X��������
      gv_check_proc_retcode := gv_status_normal;
      RAISE global_process_expt;
    END IF;
--
    -- �`�F�b�N�����G���[
    IF (gv_check_proc_retcode = gv_status_error) THEN
      -- �Œ�̃G���[���b�Z�[�W�̏o�͂����Ȃ��悤�ɂ���
      lv_errmsg := gv_c_space;
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
--
--#################################  �Œ��O������ START   ###################################
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
    errbuf         OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode        OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    in_file_id     IN  VARCHAR2,      --   �t�@�C��ID
    in_file_format IN  VARCHAR2       --   �t�H�[�}�b�g�p�^�[��
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
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
    --�N�����ԏo��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118',
                                           'TIME', TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
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
      TO_NUMBER(in_file_id),
      in_file_format, -- �t�H�[�}�b�g�p�^�[��
      lv_errbuf,      -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,     -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    IF (retcode = gv_status_error) AND (gv_check_proc_retcode = gv_status_normal) THEN
      ROLLBACK;
    ELSE
      COMMIT;
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
END xxpo940005c;
/
