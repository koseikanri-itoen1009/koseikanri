CREATE OR REPLACE PACKAGE BODY xxinv990003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxinv990003(body)
 * Description      : �o�׈˗��̃A�b�v���[�h
 * MD.050           : �t�@�C���A�b�v���[�h   T_MD050_BPO_990
 * MD.070           : �o�׈˗��̃A�b�v���[�h T_MD070_BPO_99D
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init_proc              �֘A�f�[�^�擾 (D-1)
 *  get_upload_data_proc   �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�擾 (D-2)
 *  check_proc             �Ó����`�F�b�N (D-3,4,5)
 *  set_data_proc          �o�^�f�[�^�ݒ�
 *  insert_header_proc     �w�b�_�o�^ (D-6)
 *  insert_details_proc    ���דo�^ (D-7)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/02/15    1.0   Oracle �㓡       ����쐬
 *  2008/04/03    1.0   Oracle �Ŗ�       �����ύX�v��#11
 *  2008/04/18    1.1   Oracle �R�� ��_  �ύX�v��No63�Ή�
 *  2008/05/07    1.2   Oracle �͖�       �����ύX�v��No82�Ή�
 *  2008/07/08    1.3   Oracle �R�� ��_  I_S_192�Ή�
 *  2009/12/15    1.4   SCS�k����         �{�ғ���Q#493�Ή�(�b��)
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
  gv_pkg_name       CONSTANT VARCHAR2(100) := 'xxinv990003'; -- �p�b�P�[�W��
--
  gv_c_msg_kbn   CONSTANT VARCHAR2(5)   := 'XXINV';
--
  -- ���b�Z�[�W�ԍ�
  gv_c_msg_99d_001   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10025'; -- �v���t�@�C���擾�G���[
  gv_c_msg_99d_002   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10032'; -- ���b�N�G���[
  gv_c_msg_99d_003   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10008'; -- �Ώۃf�[�^�Ȃ�
  gv_c_msg_99d_004   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10026'; -- �w�b�_���׋敪�G���[
  gv_c_msg_99d_005   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10024'; -- �t�H�[�}�b�g�`�F�b�N�G���[���b�Z�[�W
--
  gv_c_msg_99d_101   CONSTANT VARCHAR2(15)  := 'APP-XXINV-00001'; -- �t�@�C����
  gv_c_msg_99d_103   CONSTANT VARCHAR2(15)  := 'APP-XXINV-00003'; -- �A�b�v���[�h����
  gv_c_msg_99d_104   CONSTANT VARCHAR2(15)  := 'APP-XXINV-00004'; -- �t�@�C���A�b�v���[�h����
-- Ver1.4 SCSHOKKANJI �{�ғ���Q#493�Ή�(�b��) START
  gv_tkn_num_40f_06    CONSTANT VARCHAR2(15) := 'APP-XXWSH-11256';  -- �˗�No�R���o�[�g�G���[
-- Ver1.4 SCSHOKKANJI �{�ғ���Q#493�Ή�(�b��) END
--
  -- �g�[�N��
  gv_c_tkn_ng_profile          CONSTANT VARCHAR2(10)   := 'NAME';
  gv_c_tkn_table               CONSTANT VARCHAR2(15)   := 'TABLE';
  gv_c_tkn_item                CONSTANT VARCHAR2(15)   := 'ITEM';
  gv_c_tkn_value               CONSTANT VARCHAR2(15)   := 'VALUE';
  -- �v���t�@�C��
  gv_c_parge_term_003          CONSTANT VARCHAR2(20)   := 'XXINV_PURGE_TERM_003';
  gv_c_parge_term_name         CONSTANT VARCHAR2(36)   := '�p�[�W�Ώۊ���:�o�׈˗�';
  -- �N�C�b�N�R�[�h �^�C�v
  gv_c_lookup_type             CONSTANT VARCHAR2(17)  := 'XXINV_FILE_OBJECT';
  gv_c_format_type             CONSTANT VARCHAR2(20)  := '�t�H�[�}�b�g�p�^�[��';
  -- �Ώ�DB��
  gv_c_xxinv_mrp_file_ul_name  CONSTANT VARCHAR2(100)
                                            := '�t�@�C���A�b�v���[�h�C���^�t�F�[�X�e�[�u��';
--
  -- *** �w�b�_���ږ� ***
  gv_c_file_id_name             CONSTANT VARCHAR2(24)   := 'FILE_ID';
  gv_c_ordered_class            CONSTANT VARCHAR2(24)   := '�˗��敪';
  gv_c_party_site_code          CONSTANT VARCHAR2(24)   := '�z����';
  gv_c_shipping_instructions    CONSTANT VARCHAR2(24)   := '�E�v';
  gv_c_cust_po_number           CONSTANT VARCHAR2(24)   := 'PO#�i���̂P�j';
  gv_c_order_source_ref         CONSTANT VARCHAR2(24)   := '�˗��`�[No';
  gv_c_ship_date                CONSTANT VARCHAR2(24)   := '������';
  gv_c_arrival_date             CONSTANT VARCHAR2(24)   := '����';
  gv_c_location_code            CONSTANT VARCHAR2(24)   := '�o�׌�';
  gv_c_input_sales_branch       CONSTANT VARCHAR2(24)   := '���͋��_';
  gv_c_head_sales_branch        CONSTANT VARCHAR2(24)   := '�Ǌ����_';
  gv_c_arrival_time_from        CONSTANT VARCHAR2(24)   := '���׎���';
  -- *** ���׍��ږ� ***
  gv_c_orderd_item_code         CONSTANT VARCHAR2(24)   := '�i���R�[�h';
  gv_c_orderd_quantity          CONSTANT VARCHAR2(24)   := '�{��';
--
  -- *** �w�b�_���ڌ��� ***
  gn_c_ordered_class_l          CONSTANT NUMBER         := 1;   -- �˗��敪
  gn_c_party_site_code_l        CONSTANT NUMBER         := 9;   -- �z����
  gn_c_shipping_instructions_l  CONSTANT NUMBER         := 40;  -- �E�v
  gn_c_cust_po_number_l         CONSTANT NUMBER         := 9;   -- PO#�i����1�j
  gn_c_order_source_ref_l       CONSTANT NUMBER         := 9;   -- �˗��`�[NO
  gn_c_location_code_l          CONSTANT NUMBER         := 4;   -- �o�׌�
  gn_c_input_sales_branch_l     CONSTANT NUMBER         := 4;   -- ���͋��_
  gn_c_head_sales_branch_l      CONSTANT NUMBER         := 4;   -- �Ǌ����_
  gn_c_arrival_time_from_l      CONSTANT NUMBER         := 4;   -- ���׎���
  -- *** ���׍��ڌ��� ***
--2008.05.07 Y.Kawano modify start
--  gn_c_orderd_item_code_l       CONSTANT NUMBER         := 5;   -- �i���R�[�h
  gn_c_orderd_item_code_l       CONSTANT NUMBER         := 7;   -- �i���R�[�h
--2008.05.07 Y.Kawano modify end
  gn_c_orderd_quantity_l        CONSTANT NUMBER         := 11;  -- �{��
  gn_c_orderd_quantity_d        CONSTANT NUMBER         := 3;   -- �{���i�����_�ȉ��j
--
  -- *** �w�b�_���׋敪 ***
  gn_c_tranc_header             CONSTANT VARCHAR2(2)    := '01';  -- �w�b�_
  gn_c_tranc_details            CONSTANT VARCHAR2(2)    := '02';  -- ����
  -- �f�[�^�敪
  gv_c_data_type_wsh            CONSTANT VARCHAR2(2)    := '10';  -- �o�׈˗�
--
  gv_c_period                   CONSTANT VARCHAR2(1)    := '.';      -- �s���I�h
  gv_c_comma                    CONSTANT VARCHAR2(1)    := ',';      -- �J���}
  gv_c_space                    CONSTANT VARCHAR2(1)    := ' ';      -- �X�y�[�X
  gv_c_err_msg_space            CONSTANT VARCHAR2(6)    := '      '; -- �X�y�[�X�i6byte�j
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- CSV���i�[���郌�R�[�h
  TYPE file_data_rec IS RECORD(
    tranc_header_class            VARCHAR2(32767), -- �w�b�_���׋敪
    ordered_class                 VARCHAR2(32767), -- �˗��敪
    party_site_code               VARCHAR2(32767), -- �z����
    shipping_instructions         VARCHAR2(32767), -- �E�v
    cust_po_number                VARCHAR2(32767), -- PO#�i���̂P�j
    order_source_ref              VARCHAR2(32767), -- �˗��`�[NO
    schedule_ship_date            VARCHAR2(32767), -- ������
    schedule_arrival_date         VARCHAR2(32767), -- ����
    location_code                 VARCHAR2(32767), -- �o�׌�
    input_sales_branch            VARCHAR2(32767), -- ���͋��_
    head_sales_branch             VARCHAR2(32767), -- �Ǌ����_
    arrival_time_from             VARCHAR2(32767), -- ���׎���
    orderd_item_code              VARCHAR2(32767), -- �i���R�[�h
    orderd_quantity               VARCHAR2(32767), -- �{��
    line                          VARCHAR2(32767), -- �s���e�S�āi��������p�j
    err_message                   VARCHAR2(32767)  -- �G���[���b�Z�[�W�i��������p�j
  );
--
  -- CSV���i�[���錋���z��
  TYPE file_data_tbl IS TABLE OF file_data_rec INDEX BY BINARY_INTEGER;
  fdata_tbl file_data_tbl;
--
  -- �o�^�pPL/SQL�\�^�i�w�b�_�j
  TYPE header_id_type              IS TABLE OF  
      xxwsh_shipping_headers_if.header_id%TYPE             INDEX BY BINARY_INTEGER;  -- �w�b�_ID
  TYPE ordered_class_type          IS TABLE OF 
      xxwsh_shipping_headers_if.ordered_class%TYPE         INDEX BY BINARY_INTEGER;  -- �˗��敪
  TYPE party_site_code_type        IS TABLE OF 
      xxwsh_shipping_headers_if.party_site_code%TYPE       INDEX BY BINARY_INTEGER;  -- �o�א�
  TYPE shipping_instructions_type  IS TABLE OF 
      xxwsh_shipping_headers_if.shipping_instructions%TYPE INDEX BY BINARY_INTEGER;  -- �o�׎w��
  TYPE cust_po_number_type         IS TABLE OF 
      xxwsh_shipping_headers_if.cust_po_number%TYPE        INDEX BY BINARY_INTEGER;  -- �ڋq����
  TYPE order_source_ref_type       IS TABLE OF 
      xxwsh_shipping_headers_if.order_source_ref%TYPE      INDEX BY BINARY_INTEGER;  -- �󒍃\�[�X�Q��
  TYPE schedule_ship_date_type     IS TABLE OF 
      xxwsh_shipping_headers_if.schedule_ship_date%TYPE    INDEX BY BINARY_INTEGER;  -- �o�ח\���
  TYPE schedule_arrival_date_type  IS TABLE OF 
      xxwsh_shipping_headers_if.schedule_arrival_date%TYPE INDEX BY BINARY_INTEGER;  -- ���ח\���
  TYPE location_code_type          IS TABLE OF 
      xxwsh_shipping_headers_if.location_code%TYPE         INDEX BY BINARY_INTEGER;  -- �o�׌�
  TYPE input_sales_branch_type     IS TABLE OF 
      xxwsh_shipping_headers_if.input_sales_branch%TYPE    INDEX BY BINARY_INTEGER;  -- ���͋��_
  TYPE head_sales_branch_type      IS TABLE OF 
      xxwsh_shipping_headers_if.head_sales_branch%TYPE     INDEX BY BINARY_INTEGER;  -- �Ǌ����_
  TYPE arrival_time_from_type      IS TABLE OF 
      xxwsh_shipping_headers_if.arrival_time_from%TYPE     INDEX BY BINARY_INTEGER;  -- ���׎���From
--
  gt_header_id_tab              header_id_type;             -- �w�b�_ID
  gt_ordered_class_tab          ordered_class_type;         -- �˗��敪
  gt_party_site_code_tab        party_site_code_type;       -- �o�א�
  gt_shipping_instructions_tab  shipping_instructions_type; -- �o�׎w��
  gt_cust_po_number_tab         cust_po_number_type;        -- �ڋq����
  gt_order_source_ref_tab       order_source_ref_type;      -- �󒍃\�[�X�Q��
  gt_schedule_ship_date_tab     schedule_ship_date_type;    -- �o�ח\���
  gt_schedule_arrival_date_tab  schedule_arrival_date_type; -- ���ח\���
  gt_location_code_tab          location_code_type;         -- �o�׌�
  gt_input_sales_branch_tab     input_sales_branch_type;    -- ���͋��_
  gt_head_sales_branch_tab      head_sales_branch_type;     -- �Ǌ����_
  gt_arrival_time_from_tab      arrival_time_from_type;     -- ���׎���From
--
  -- �o�^�pPL/SQL�\�^�i���ׁj
  TYPE line_header_id_type              IS TABLE OF
      xxwsh_shipping_lines_if.header_id%TYPE                  INDEX BY BINARY_INTEGER;  -- ����ID
  TYPE line_id_type                     IS TABLE OF
      xxwsh_shipping_lines_if.line_id%TYPE                    INDEX BY BINARY_INTEGER;  -- �w�b�_ID
  TYPE orderd_item_code_type            IS TABLE OF
      xxwsh_shipping_lines_if.orderd_item_code%TYPE           INDEX BY BINARY_INTEGER;  -- �󒍕i��
  TYPE orderd_quantity_type             IS TABLE OF
      xxwsh_shipping_lines_if.orderd_quantity%TYPE            INDEX BY BINARY_INTEGER;  -- ����
--
  gt_line_header_id_tab                 line_header_id_type;              -- ����ID
  gt_line_id_tab                        line_id_type;                     -- �w�b�_ID
  gt_orderd_item_code_tab               orderd_item_code_type;            -- �󒍕i��
  gt_orderd_quantity_tab                orderd_quantity_type;             -- ����
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
  gn_xxinv_parge_term       NUMBER;           -- �p�[�W�Ώۊ���
  gv_file_name              VARCHAR2(256);    -- �t�@�C����
  gv_file_up_name           VARCHAR2(256);    -- �t�@�C���A�b�v���[�h����
  gn_created_by             NUMBER(15);       -- �쐬��
  gd_creation_date          DATE;             -- �쐬��
  gv_check_proc_retcode     VARCHAR2(1);      -- �Ó����`�F�b�N�X�e�[�^�X
--
   /**********************************************************************************
   * Procedure Name   : init_proc
   * Description      : �֘A�f�[�^�擾 (D-1)
   ***********************************************************************************/
  PROCEDURE init_proc(
    in_file_format  IN  VARCHAR2,     -- �t�H�[�}�b�g�p�^�[��
    ov_errbuf       OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    gn_user_id          := FND_GLOBAL.USER_ID;         -- ���[�UID
    gn_login_id         := FND_GLOBAL.LOGIN_ID;        -- �ŏI�X�V���O�C��
    gn_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID; -- �v��ID
    gn_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;    -- �ݶ��āE��۸��т̱��ع����ID
    gn_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID; -- �R���J�����g�E�v���O����ID
--
    -- �v���t�@�C���u�p�[�W�Ώۊ��ԁv�擾
    lv_parge_term := FND_PROFILE.VALUE(gv_c_parge_term_003);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (lv_parge_term IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                            gv_c_msg_99d_001,
                                            gv_c_tkn_ng_profile,
                                            gv_c_parge_term_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �v���t�@�C���l�`�F�b�N
    BEGIN
      -- TO_NUMBER�ł��Ȃ���΃G���[
      gn_xxinv_parge_term := TO_NUMBER(lv_parge_term);
    EXCEPTION
      WHEN INVALID_NUMBER OR VALUE_ERROR THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                            gv_c_msg_99d_001,
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
      AND     ROWNUM           = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN                             --*** �f�[�^�擾�G���[ ***
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                              gv_c_msg_99d_003,
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
   * Description      : �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�擾 (D-2)
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
      lv_retcode,         -- ���^�[���E�R�[�h               --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W   --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �^�C�g���s�̂݁A���́A2�s�ڂ����s�݂̂̏ꍇ
    IF (lt_file_line_data.LAST < 2) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                            gv_c_msg_99d_003,
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
        ln_length := INSTR(lv_line, gv_c_comma);
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
          fdata_tbl(gn_target_cnt).tranc_header_class        := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 2) THEN
          fdata_tbl(gn_target_cnt).ordered_class             := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 3) THEN
          fdata_tbl(gn_target_cnt).party_site_code           := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 4) THEN
          fdata_tbl(gn_target_cnt).shipping_instructions     := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 5) THEN
          fdata_tbl(gn_target_cnt).cust_po_number            := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 6) THEN
          fdata_tbl(gn_target_cnt).order_source_ref          := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 7) THEN
          fdata_tbl(gn_target_cnt).schedule_ship_date        := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 8) THEN
          fdata_tbl(gn_target_cnt).schedule_arrival_date     := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 9) THEN
          fdata_tbl(gn_target_cnt).location_code             := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 10) THEN
          fdata_tbl(gn_target_cnt).input_sales_branch        := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 11) THEN
          fdata_tbl(gn_target_cnt).head_sales_branch         := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 12) THEN
          fdata_tbl(gn_target_cnt).arrival_time_from         := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 13) THEN
          fdata_tbl(gn_target_cnt).orderd_item_code          := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 14) THEN
          fdata_tbl(gn_target_cnt).orderd_quantity           := SUBSTR(lv_line, 1, ln_length);
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
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                            gv_c_msg_99d_002,
                                            gv_c_tkn_table,
                                            gv_c_xxinv_mrp_file_ul_name);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
    WHEN NO_DATA_FOUND THEN                             --*** �f�[�^�擾�G���[ ***
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                            gv_c_msg_99d_003,
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
   * Description      : �Ó����`�F�b�N (D-3,4,5)
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
    ln_c_col         CONSTANT NUMBER      := 14;
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
      --       <> �i�����ȍ��ڐ��|�P�������ȃJ���}�̐��j
      IF ((NVL(LENGTH(fdata_tbl(ln_index).line) ,0) 
          - NVL(LENGTH(REPLACE(fdata_tbl(ln_index).line,gv_c_comma,NULL)),0)) <> (ln_c_col - 1)) 
      THEN
--
        fdata_tbl(ln_index).err_message := gv_c_err_msg_space
                                           || gv_c_err_msg_space
                                           || xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                                                       gv_c_msg_99d_005)
                                           || lv_line_feed;
      ELSE
        -- **************************************************
        -- *** ���ڃ`�F�b�N�i�w�b�_�^���ׁj
        -- **************************************************
        -- �w�b�_�[�̏ꍇ
        IF (fdata_tbl(ln_index).tranc_header_class = gn_c_tranc_header) THEN
          -- ==============================
          --  �˗��敪
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_ordered_class,
                                              fdata_tbl(ln_index).ordered_class,
                                              gn_c_ordered_class_l,
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
          -- �z����
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_party_site_code,
                                              fdata_tbl(ln_index).party_site_code,
                                              gn_c_party_site_code_l,
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
          -- �E�v
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_shipping_instructions,
                                              fdata_tbl(ln_index).shipping_instructions,
                                              gn_c_shipping_instructions_l,
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
          -- PO#�i���̂P�j
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_cust_po_number,
                                              fdata_tbl(ln_index).cust_po_number,
                                              gn_c_cust_po_number_l,
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
          -- �˗��`�[NO
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_order_source_ref,
                                              fdata_tbl(ln_index).order_source_ref,
                                              gn_c_order_source_ref_l,
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
          -- ������
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_ship_date,
                                              fdata_tbl(ln_index).schedule_ship_date,
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
          -- ����
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_arrival_date,
                                              fdata_tbl(ln_index).schedule_arrival_date,
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
          -- �o�׌�
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_location_code,
                                              fdata_tbl(ln_index).location_code,
                                              gn_c_location_code_l,
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
          -- ���͋��_
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_input_sales_branch,
                                              fdata_tbl(ln_index).input_sales_branch,
                                              gn_c_input_sales_branch_l,
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
          -- �Ǌ����_
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_head_sales_branch,
                                              fdata_tbl(ln_index).head_sales_branch,
                                              gn_c_head_sales_branch_l,
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
          -- ���׎���
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_arrival_time_from,
                                              fdata_tbl(ln_index).arrival_time_from,
                                              gn_c_arrival_time_from_l,
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
        ELSIF (fdata_tbl(ln_index).tranc_header_class = gn_c_tranc_details) THEN
          -- ==============================
          -- �i���R�[�h
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_orderd_item_code,
                                              fdata_tbl(ln_index).orderd_item_code,
                                              gn_c_orderd_item_code_l,
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
          -- �{��
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_orderd_quantity,
                                              fdata_tbl(ln_index).orderd_quantity,
                                              gn_c_orderd_quantity_l,
                                              gn_c_orderd_quantity_d,
                                              xxcmn_common3_pkg.gv_null_ok,
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
        -- �w�b�_���׋敪���s���ȏꍇ
        ELSE
          fdata_tbl(ln_index).err_message := gv_c_err_msg_space
                                             || gv_c_err_msg_space
                                             || xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                                                         gv_c_msg_99d_004)
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
-- Ver1.4 SCSHOKKANJI �{�ғ���Q#493�Ή�(�b��) START
     cv_1             CONSTANT VARCHAR2(1) := '1';      --'1'���_�����InBound�p
     cn_status_normal CONSTANT NUMBER      := 0;        -- ���ʊ֐�����I��
     cv_app_name      CONSTANT VARCHAR2(5) := 'XXWSH';  -- �A�v���P�[�V�����Z�k��
     cv_cort          CONSTANT VARCHAR2(1) := ':';      -- �Ȃ�����
-- Ver1.4 SCSHOKKANJI �{�ғ���Q#493�Ή�(�b��) END
--
    -- *** ���[�J���ϐ� ***
    ln_header_id      NUMBER;   -- �w�b�_ID
    ln_line_id        NUMBER;   -- ����ID
-- Ver1.4 SCSHOKKANJI �{�ғ���Q#493�Ή�(�b��) START
    ln_result           NUMBER;
    lv_order_source_ref xxwsh_shipping_headers_if.order_source_ref%TYPE;  -- �󒍃\�[�X�Q��
-- Ver1.4 SCSHOKKANJI �{�ғ���Q#493�Ή�(�b��) END
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
      IF (fdata_tbl(ln_index).tranc_header_class = gn_c_tranc_header) THEN
--
        -- �w�b�_���� �C���N�������g
        gn_header_count  := gn_header_count + 1;
--
        -- �w�b�_ID�̔�
        SELECT xxwsh_shipping_headers_if_s1.NEXTVAL 
        INTO ln_header_id 
        FROM dual;
--
        -- �w�b�_���
        gt_header_id_tab(gn_header_count)             := ln_header_id;                              -- �w�b�_ID
        gt_ordered_class_tab(gn_header_count)         := fdata_tbl(ln_index).ordered_class;         -- �˗��敪
        gt_party_site_code_tab(gn_header_count)       := fdata_tbl(ln_index).party_site_code;       -- �o�א�
        gt_shipping_instructions_tab(gn_header_count) := fdata_tbl(ln_index).shipping_instructions; -- �o�׎w��
        gt_cust_po_number_tab(gn_header_count)        := fdata_tbl(ln_index).cust_po_number;        -- �ڋq����
-- Ver1.4 SCSHOKKANJI �{�ғ���Q#493�Ή�(�b��) START
        lv_order_source_ref := NULL;
        ---------------------------------------------------------------------------
        -- ���ʊ֐��u�˗�No�R���o�[�g�֐��v�ɂāA9���̈˗�No��12���˗�No�֕ϊ�
        ---------------------------------------------------------------------------
        ln_result := xxwsh_common_pkg.convert_request_number(
                       cv_1                          -- in  '1'���_�����InBound�p
                      ,fdata_tbl(ln_index).order_source_ref    -- in  �󒍃\�[�X�Q�� �ύX�O�˗�No
                      ,lv_order_source_ref           -- out �ύX��
                     );
        IF (ln_result <> cn_status_normal) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(cv_app_name,gv_tkn_num_40f_06)
                    || gv_c_order_source_ref
                    || cv_cort
                    || fdata_tbl(ln_index).order_source_ref;
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
        gt_order_source_ref_tab(gn_header_count)      := lv_order_source_ref;
        --gt_order_source_ref_tab(gn_header_count)      := fdata_tbl(ln_index).order_source_ref;      -- �󒍃\�[�X�Q��
-- Ver1.4 SCSHOKKANJI �{�ғ���Q#493�Ή�(�b��) END
        gt_schedule_ship_date_tab(gn_header_count)    
                 := FND_DATE.STRING_TO_DATE(fdata_tbl(ln_index).schedule_ship_date, 'RR/MM/DD');    -- �o�ח\���
        gt_schedule_arrival_date_tab(gn_header_count) 
                 := FND_DATE.STRING_TO_DATE(fdata_tbl(ln_index).schedule_arrival_date, 'RR/MM/DD'); -- ���ח\���
        gt_location_code_tab(gn_header_count)         := fdata_tbl(ln_index).location_code;         -- �o�׌�
        gt_input_sales_branch_tab(gn_header_count)    := fdata_tbl(ln_index).input_sales_branch;    -- ���͋��_
        gt_head_sales_branch_tab(gn_header_count)     := fdata_tbl(ln_index).head_sales_branch;     -- �Ǌ����_
        gt_arrival_time_from_tab(gn_header_count)     := fdata_tbl(ln_index).arrival_time_from;     -- ���׎���From
--
      -- ���דo�^
      ELSIF (fdata_tbl(ln_index).tranc_header_class = gn_c_tranc_details) THEN
--
        -- ���׌��� �C���N�������g
        gn_line_count   := gn_line_count + 1;
--
        -- �ŏ��̃��R�[�h�����ׂ̏ꍇ�A�w�b�_ID���̔�
        IF (ln_header_id IS NULL) THEN
          -- �w�b�_ID�̔�
          SELECT xxwsh_shipping_headers_if_s1.NEXTVAL 
          INTO ln_header_id 
          FROM dual;
        END IF;
--
        -- ����ID�̔�
        SELECT xxwsh_shipping_lines_if_s1.NEXTVAL
        INTO ln_line_id 
        FROM dual;
--
        -- ���׏��
        gt_line_id_tab(gn_line_count)            := ln_line_id;                                     -- ����ID
        gt_line_header_id_tab(gn_line_count)     := ln_header_id;                                   -- �w�b�_ID
        gt_orderd_item_code_tab(gn_line_count)   := fdata_tbl(ln_index).orderd_item_code;           -- �󒍕i��
        gt_orderd_quantity_tab(gn_line_count)    := TO_NUMBER(fdata_tbl(ln_index).orderd_quantity); -- ����
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
   * Description      : �w�b�_�o�^ (D-6)
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
    -- *** �o�׈˗��C���^�t�F�[�X�w�b�_�i�A�h�I���j�o�^
    -- **************************************************
    FORALL item_cnt IN 1 .. gn_header_count
      INSERT INTO xxwsh_shipping_headers_if
      (   header_id                                 -- �w�b�_ID
        , order_type                                -- �󒍃^�C�v
        , ordered_date                              -- �󒍓�
        , party_site_code                           -- �o�א�
        , shipping_instructions                     -- �o�׎w��
        , cust_po_number                            -- �ڋq����
        , order_source_ref                          -- �󒍃\�[�X�Q��
        , schedule_ship_date                        -- �o�ח\���
        , schedule_arrival_date                     -- ���ח\���
        , used_pallet_qty                           -- �p���b�g�g�p����
        , collected_pallet_qty                      -- �p���b�g�������
        , location_code                             -- �o�׌�
        , input_sales_branch                        -- ���͋��_
        , head_sales_branch                         -- �Ǌ����_
        , arrival_time_from                         -- ���׎���From
        , arrival_time_to                           -- ���׎���To
        , data_type                                 -- �f�[�^�^�C�v
        , freight_carrier_code                      -- �^���Ǝ�
        , shipping_method_code                      -- �z���敪
        , delivery_no                               -- �z��No
        , shipped_date                              -- �o�ד�
        , arrival_date                              -- ���ד�
        , eos_data_type                             -- EOS�f�[�^���
        , tranceration_number                       -- �`���p�}��
        , ship_to_location                          -- ���ɑq��
        , rm_class                                  -- �q�֕ԕi�敪
        , ordered_class                             -- �˗��敪
        , report_post_code                          -- �񍐕���
        , line_number                               -- ����ԍ�
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
        , NULL                                      -- �󒍃^�C�v
        , NULL                                      -- �󒍓�
        , gt_party_site_code_tab(item_cnt)          -- �o�א�
        , gt_shipping_instructions_tab(item_cnt)    -- �o�׎w��
        , gt_cust_po_number_tab(item_cnt)           -- �ڋq����
        , gt_order_source_ref_tab(item_cnt)         -- �󒍃\�[�X�Q��
        , gt_schedule_ship_date_tab(item_cnt)       -- �o�ח\���
        , gt_schedule_arrival_date_tab(item_cnt)    -- ���ח\���
        , NULL                                      -- �p���b�g�g�p����
        , NULL                                      -- �p���b�g�������
        , gt_location_code_tab(item_cnt)            -- �o�׌�
        , gt_input_sales_branch_tab(item_cnt)       -- ���͋��_
        , gt_head_sales_branch_tab(item_cnt)        -- �Ǌ����_
        , gt_arrival_time_from_tab(item_cnt)        -- ���׎���From
        , NULL                                      -- ���׎���To
        , gv_c_data_type_wsh                        -- �f�[�^�^�C�v
        , NULL                                      -- �^���Ǝ�
        , NULL                                      -- �z���敪
        , NULL                                      -- �z��No
        , NULL                                      -- �o�ד�
        , NULL                                      -- ���ד�
        , NULL                                      -- EOS�f�[�^���
        , NULL                                      -- �`���p�}��
        , NULL                                      -- ���ɑq��
        , NULL                                      -- �q�֕ԕi�敪
        , gt_ordered_class_tab(item_cnt)            -- �˗��敪
        , NULL                                      -- �񍐕���
        , NULL                                      -- ����ԍ�
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
   * Description      : ���דo�^ (D-7)
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
    -- *** �o�׈˗��C���^�t�F�[�X���ׁi�A�h�I���j�o�^
    -- **************************************************
    FORALL item_cnt IN 1 .. gn_line_count
      INSERT INTO xxwsh_shipping_lines_if
      (   line_id                                   -- ����ID
        , header_id                                 -- �w�b�_ID
        , line_number                               -- ���הԍ�
        , orderd_item_code                          -- �󒍕i��
        , case_quantity                             -- �P�[�X��
        , orderd_quantity                           -- ����
        , shiped_quantity                           -- �o�׎��ѐ���
        , designated_production_date                -- ������(�C���^�t�F�[�X�p)
        , original_character                        -- �ŗL�L��(�C���^�t�F�[�X�p)
        , use_by_date                               -- �ܖ�����(�C���^�t�F�[�X�p)
        , detailed_quantity                         -- ���󐔗�(�C���^�t�F�[�X�p)
        , ship_to_quantity                          -- ���Ɏ��ѐ���
        , reserved_status                           -- �ۗ��X�e�[�^�X
        , lot_no                                    -- ���b�gNo
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
        , gt_line_header_id_tab(item_cnt)           -- �w�b�_ID
        , NULL                                      -- ���הԍ�
        , gt_orderd_item_code_tab(item_cnt)         -- �󒍕i��
        , NULL                                      -- �P�[�X��
        , gt_orderd_quantity_tab(item_cnt)          -- ����
        , NULL                                      -- �o�׎��ѐ���
        , NULL                                      -- ������(�C���^�t�F�[�X�p)
        , NULL                                      -- �ŗL�L��(�C���^�t�F�[�X�p)
        , NULL                                      -- �ܖ�����(�C���^�t�F�[�X�p)
        , NULL                                      -- ���󐔗�(�C���^�t�F�[�X�p)
        , NULL                                      -- ���Ɏ��ѐ���
        , NULL                                      -- �ۗ��X�e�[�^�X
        , NULL                                      -- ���b�gNo
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
    -- �֘A�f�[�^�擾 (D-1)
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
    -- �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�擾 (D-2)
    -- ===============================
    get_upload_data_proc(
      in_file_id,        -- �t�@�C���h�c
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--#################################  �A�b�v���[�h�Œ胁�b�Z�[�W START  ###################################
    --�������ʃ��|�[�g�o�́i�㕔�j
    -- �t�@�C����
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                              gv_c_msg_99d_101,
                                              gv_c_tkn_value,
                                              gv_file_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    -- �A�b�v���[�h����
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                              gv_c_msg_99d_103,
                                              gv_c_tkn_value,
                                              TO_CHAR(gd_creation_date,'YYYY/MM/DD HH24:MI'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    -- �t�@�C���A�b�v���[�h����
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                              gv_c_msg_99d_104,
                                              gv_c_tkn_value,
                                              gv_file_up_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
--
--#################################  �A�b�v���[�h�Œ胁�b�Z�[�W END   ###################################
--
    -- �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�擾���ʂ𔻒�
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
--
    -- ===============================
    -- �Ó����`�F�b�N (D-3,4,5)
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
      -- �w�b�_�o�^ (D-6)
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
      -- ���דo�^ (D-7)
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
    -- �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�폜 (D-8)
    -- ===============================
    xxcmn_common3_pkg.delete_fileup_proc(
      in_file_format,                 -- �t�H�[�}�b�g�p�^�[��
      gd_sysdate,                     -- �Ώۓ��t
      gn_xxinv_parge_term,            -- �p�[�W�Ώۊ���
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
    in_file_id     IN  VARCHAR2,      --   �t�@�C���h�c 2008/04/18 �ύX
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
      TO_NUMBER(in_file_id),     -- �t�@�C���h�c 2008/04/18 �ύX
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
END xxinv990003c;
/
