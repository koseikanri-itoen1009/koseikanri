CREATE OR REPLACE PACKAGE BODY xxpo940004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXPO940004C(body)
 * Description      : �d���E�L���E�ړ���񒊏o����
 * MD.050           : ���Y��������                  T_MD050_BPO_940
 * MD.070           : �d���E�L���E�ړ���񒊏o����  T_MD070_BPO_94D
 * Version          : 1.5
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  replace_sep            ��������̃J���}�폜
 *  decimal_round_up       �����_�̎w��ʒu�ł̐؂�グ
 *  parameter_disp         �p�����[�^�̏o��
 *  parameter_check        �p�����[�^�`�F�b�N               (D-1)
 *  pha_sel_proc           ������񌟍�����                 (D-3)
 *  oha_sel_proc           �x����񌟍�����                 (D-4)
 *  mov_sel_proc           �ړ���񌟍�����                 (D-5)
 *  put_csv_data           CSV�t�@�C���ւ̃f�[�^�o��
 *  csv_file_proc          CSV�t�@�C���o��                  (D-6)
 *  workflow_start         ���[�N�t���[�ʒm����             (D-7)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/06/10    1.0   Oracle �R�� ��_ ����쐬
 *  2008/08/20    1.1   Oracle �R�� ��_ T_S_593,T_TE080_BPO_940 �w�E6,�w�E7,�w�E8,�w�E9�Ή�
 *  2008/09/02    1.2   Oracle �R�� ��_ T_S_626,T_TE080_BPO_940 �w�E10�Ή�
 *  2008/09/18    1.3   Oracle �勴 �F�Y T_S_460�Ή�
 *  2008/11/26    1.4   Oracle �g�c �Ď� �{��#113�Ή�
 *  2009/02/04    1.5   Oracle �g�c �Ď� �{��#15�Ή�
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
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'xxpo940004c'; -- �p�b�P�[�W��
  gv_app_name      CONSTANT VARCHAR2(5)   := 'XXPO';        -- �A�v���P�[�V�����Z�k��
  gv_com_name      CONSTANT VARCHAR2(5)   := 'XXCMN';       -- �A�v���P�[�V�����Z�k��
--
  -- �f�[�^���
  gv_data_class_pha CONSTANT VARCHAR2(3) := '520'; -- �������
  gv_data_class_oha CONSTANT VARCHAR2(3) := '530'; -- �x�����
  gv_data_class_mov CONSTANT VARCHAR2(3) := '540'; -- �ړ����
--
  gv_sec_class_home CONSTANT VARCHAR2(1) := '1';   -- �ɓ������[�U�[�^�C�v
  gv_sec_class_vend CONSTANT VARCHAR2(1) := '2';   -- ����惆�[�U�[�^�C�v
  gv_sec_class_extn CONSTANT VARCHAR2(1) := '3';   -- �O���q�Ƀ��[�U�[�^�C�v
  gv_sec_class_quay CONSTANT VARCHAR2(1) := '4';   -- ���m�u�����[�U�[�^�C�v
--
  gv_drop_ship_type_ship   CONSTANT VARCHAR2(1) := '2';         -- �o��
  gv_weight_class          CONSTANT VARCHAR2(1) := '1';         -- �d��
  gv_capacity_class        CONSTANT VARCHAR2(1) := '2';         -- �e��
  gv_lot_ctl_on            CONSTANT VARCHAR2(1) := '1';         -- ���b�g�Ǘ��i
  gv_document_type_code_20 CONSTANT VARCHAR2(2) := '20';        -- �ړ�
  gv_document_type_code_30 CONSTANT VARCHAR2(2) := '30';        -- �x���w��
  gv_record_type_code_10   CONSTANT VARCHAR2(2) := '10';        -- �w��
  gv_record_type_code_20   CONSTANT VARCHAR2(2) := '20';        -- �o�Ɏ���
  gv_record_type_code_30   CONSTANT VARCHAR2(2) := '30';        -- ���Ɏ���
  gv_shipping_shikyu_class CONSTANT VARCHAR2(1) := '2';         -- �x���˗�
  gv_rcv_pay_ctg_05        CONSTANT VARCHAR2(2) := '05';        -- �L���ԕi
  gv_rcv_pay_ctg_06        CONSTANT VARCHAR2(2) := '06';        -- �d���ԕi
  gv_flg_on                CONSTANT VARCHAR2(1) := '1';
  gv_status_on             CONSTANT VARCHAR2(1) := 'A';
  gv_enabled_flag_on       CONSTANT VARCHAR2(1) := 'Y';
  gv_external_flag_on      CONSTANT VARCHAR2(1) := 'Y';
  gv_ship_method           CONSTANT VARCHAR2(30) := 'XXCMN_SHIP_METHOD';
  gv_transaction_type_name CONSTANT VARCHAR2(30) := '�d���L��';
  gv_company_name          CONSTANT VARCHAR2(10) := 'ITOEN';
--
  -- �g�[�N��
  gv_tkn_number_94d_01    CONSTANT VARCHAR2(15) := 'APP-XXPO-10156';  -- �v���t�@�C���擾�G���[
  gv_tkn_number_94d_02    CONSTANT VARCHAR2(15) := 'APP-XXPO-10102';  -- �s�������Ұ�1
  gv_tkn_number_94d_03    CONSTANT VARCHAR2(15) := 'APP-XXPO-10104';  -- �s�������Ұ�3
  gv_tkn_number_94d_04    CONSTANT VARCHAR2(15) := 'APP-XXPO-10105';  -- �s�������Ұ�4
  gv_tkn_number_94d_05    CONSTANT VARCHAR2(15) := 'APP-XXPO-10026';  -- �f�[�^���擾���b�Z�[�W
  gv_tkn_number_94d_06    CONSTANT VARCHAR2(15) := 'APP-XXPO-10155';  -- �p�����[�^�G���[
  gv_tkn_number_94d_07    CONSTANT VARCHAR2(15) := 'APP-XXPO-30022';  -- �p�����[�^���
--
  gv_tkn_number_94d_50    CONSTANT VARCHAR2(15) := 'APP-XXCMN-10113';  -- �t�@�C���p�X�s���װ
  gv_tkn_number_94d_51    CONSTANT VARCHAR2(15) := 'APP-XXCMN-10114';  -- �t�@�C�����s���װ
  gv_tkn_number_94d_52    CONSTANT VARCHAR2(15) := 'APP-XXCMN-10115';  -- �t�@�C���A�N�Z�X�����װ
  gv_tkn_number_94d_53    CONSTANT VARCHAR2(15) := 'APP-XXCMN-10119';  -- �t�@�C���p�XNULL�װ
  gv_tkn_number_94d_54    CONSTANT VARCHAR2(15) := 'APP-XXCMN-10120';  -- �t�@�C����NULL�װ
  gv_tkn_number_94d_55    CONSTANT VARCHAR2(15) := 'APP-XXCMN-10117';  -- Workflow�N���װ
--
  gv_tkn_name             CONSTANT VARCHAR2(15) := 'NAME';
  gv_tkn_param_name       CONSTANT VARCHAR2(15) := 'PARAM_NAME';
  gv_tkn_param_value      CONSTANT VARCHAR2(15) := 'PARAM_VALUE';
  gv_tkn_error_param      CONSTANT VARCHAR2(15) := 'ERROR_PARAM';
  gv_tkn_error_value      CONSTANT VARCHAR2(15) := 'ERROR_VALUE';
  gv_tkn_param            CONSTANT VARCHAR2(15) := 'PARAM';
  gv_tkn_data             CONSTANT VARCHAR2(15) := 'DATA';
  gv_tkn_table            CONSTANT VARCHAR2(15) := 'TABLE';
--
  gv_status_null     CONSTANT VARCHAR2(2) := '00';
  gv_xxinv_status_01 CONSTANT VARCHAR2(2) := '01';   -- �˗���
  gv_xxinv_status_02 CONSTANT VARCHAR2(2) := '02';   -- �˗���
  gv_xxinv_status_03 CONSTANT VARCHAR2(2) := '03';   -- ������
  gv_xxinv_status_04 CONSTANT VARCHAR2(2) := '04';   -- �o�ɕ񍐗L
  gv_xxinv_status_05 CONSTANT VARCHAR2(2) := '05';   -- ���ɕ񍐗L
  gv_xxinv_status_06 CONSTANT VARCHAR2(2) := '06';   -- ���o�ɕ񍐗L
  gv_xxinv_status_07 CONSTANT VARCHAR2(2) := '99';   -- ���
/* 2008/07/28 Mod ��
  gv_xxpo_status_01  CONSTANT VARCHAR2(2) := '05';   -- ���͒�
  gv_xxpo_status_02  CONSTANT VARCHAR2(2) := '06';   -- ���͊���
  gv_xxpo_status_03  CONSTANT VARCHAR2(2) := '07';   -- ��̍�
  gv_xxpo_status_04  CONSTANT VARCHAR2(2) := '08';   -- �o�׎��ьv���
  gv_xxpo_status_05  CONSTANT VARCHAR2(2) := '99';   -- ���
2008/07/28 Mod �� */
  gv_xxpo_status_01  CONSTANT VARCHAR2(2) := '15';   -- �����쐬��
  gv_xxpo_status_02  CONSTANT VARCHAR2(2) := '20';   -- �����쐬��
  gv_xxpo_status_03  CONSTANT VARCHAR2(2) := '25';   -- �������
  gv_xxpo_status_04  CONSTANT VARCHAR2(2) := '30';   -- ���ʊm���
  gv_xxpo_status_05  CONSTANT VARCHAR2(2) := '35';   -- ���z�m���
  gv_xxpo_status_06  CONSTANT VARCHAR2(2) := '99';   -- ���
--
  gv_xxwsh_status_01 CONSTANT VARCHAR2(2) := '01';   -- ���͒�
  gv_xxwsh_status_02 CONSTANT VARCHAR2(2) := '02';   -- ���_�m��
  gv_xxwsh_status_03 CONSTANT VARCHAR2(2) := '03';   -- ���ߍς�
  gv_xxwsh_status_04 CONSTANT VARCHAR2(2) := '04';   -- �o�׎��ьv���
  gv_xxwsh_status_05 CONSTANT VARCHAR2(2) := '06';   -- ���͊���
  gv_xxwsh_status_06 CONSTANT VARCHAR2(2) := '07';   -- ��̍�
  gv_xxwsh_status_07 CONSTANT VARCHAR2(2) := '99';   -- ���
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ***************************************
  -- ***    �擾���i�[���R�[�h�^��`   ***
  -- ***************************************
--
  TYPE masters_rec IS RECORD(
    sel_tbl_id           NUMBER,       -- �e�[�u��ID
    company_name         VARCHAR2(5),  -- ��Ж�
    data_class           VARCHAR2(3),  -- �f�[�^���
    seq_no               NUMBER,       -- �`���p�}��
    ship_no              VARCHAR2(12), -- �z��No.
    request_no           VARCHAR2(12), -- �˗�No.
    relation_no          VARCHAR2(12), -- �֘ANo.
    base_request_no      VARCHAR2(12), -- �R�s�[��No.   2008/09/02 Add
    base_ship_no         VARCHAR2(12), -- ���z��No.
    vendor_code          VARCHAR2(4),  -- �����R�[�h
    vendor_name          VARCHAR2(60), -- ����於
    vendor_s_name        VARCHAR2(20), -- ����旪��
    mediation_code       VARCHAR2(4),  -- �����҃R�[�h
    mediation_name       VARCHAR2(60), -- �����Җ�
    mediation_s_name     VARCHAR2(20), -- �����җ���
    whse_code            VARCHAR2(4),  -- �q�ɃR�[�h
    whse_name            VARCHAR2(60), -- �q�ɖ�
    whse_s_name          VARCHAR2(20), -- �q�ɗ���
    vendor_site_code     VARCHAR2(9),  -- �z����R�[�h
    vendor_site_name     VARCHAR2(60), -- �z���於
    vendor_site_s_name   VARCHAR2(20), -- �z���旪��
    zip                  VARCHAR2(10), -- �X�֔ԍ�
    address              VARCHAR2(60), -- �Z��
    phone                VARCHAR2(15), -- �d�b�ԍ�
    carrier_code         VARCHAR2(4),  -- �^���Ǝ҃R�[�h
    carrier_name         VARCHAR2(60), -- �^���ƎҖ�
    carrier_s_name       VARCHAR2(20), -- �^���Ǝҗ���
    ship_date            DATE,         -- �o�ɓ�
    arrival_date         DATE,         -- ���ɓ�
    arrival_time_from    VARCHAR2(5),  -- ���׎���FROM
    arrival_time_to      VARCHAR2(5),  -- ���׎���TO
    method_code          VARCHAR2(2),  -- �z���敪
    div_a                VARCHAR2(1),  -- �敪�`
    div_b                VARCHAR2(1),  -- �敪�a
    div_c                VARCHAR2(1),  -- �敪�b
    instruction_dept     VARCHAR2(4),  -- �w�������R�[�h
    request_dept         VARCHAR2(4),  -- �˗������R�[�h
    status               VARCHAR2(2),  -- �X�e�[�^�X
    notif_status         VARCHAR2(2),  -- �ʒm�X�e�[�^�X
    div_d                VARCHAR2(30), -- �敪�c
    div_e                VARCHAR2(1),  -- �敪�d
    div_f                VARCHAR2(1),  -- �敪�e
    div_g                VARCHAR2(1),  -- �敪�f
    div_h                VARCHAR2(1),  -- �敪�g
    info_a               VARCHAR2(10), -- ���`
    info_b               VARCHAR2(7),  -- ���a
    info_c               VARCHAR2(60), -- ���b
    info_d               VARCHAR2(20), -- ���c
    info_e               VARCHAR2(10), -- ���d
    head_description     VARCHAR2(60), -- �E�v(�w�b�_)
    line_description     VARCHAR2(60), -- �E�v(����)
    line_num             VARCHAR2(3),  -- ����No.
    item_no              VARCHAR2(7),  -- �i�ڃR�[�h
    item_name            VARCHAR2(60), -- �i�ږ�
    item_s_name          VARCHAR2(20), -- �i�ڗ���
    futai_code           VARCHAR2(1),  -- �t��
    lot_no               VARCHAR2(10), -- ���b�gNo
    lot_date             DATE,         -- ������
    best_bfr_date        DATE,         -- �ܖ�����
    lot_sign             VARCHAR2(6),  -- �ŗL�L��
    request_qty          NUMBER,       -- �˗���
    instruct_qty         NUMBER,       -- �w����
    num_of_deliver       NUMBER,       -- �o�ɐ�
    ship_to_qty          NUMBER,       -- ���ɐ�
    fix_qty              NUMBER,       -- �m�萔
    item_um              VARCHAR2(3),  -- �P��
    weight_capacity      NUMBER,       -- �d�ʗe��
    frequent_qty         NUMBER,       -- ����
    frequent_factory     VARCHAR2(4),  -- �H��R�[�h
    div_i                VARCHAR2(1),  -- �敪�h
    div_j                VARCHAR2(1),  -- �敪�i
    div_k                VARCHAR2(1),  -- �敪�j
    designate_date       DATE,         -- ���t�w��
    info_f               VARCHAR2(4),  -- ���e
    info_g               VARCHAR2(2),  -- ���f
    info_h               VARCHAR2(10), -- ���g
    info_i               VARCHAR2(10), -- ���h
    info_j               VARCHAR2(10), -- ���i
-- 2008/07/31 Mod ��
/*
    info_k               VARCHAR2(10), -- ���j
    info_l               VARCHAR2(10), -- ���k
*/
    info_k               VARCHAR2(20), -- ���j
    info_l               VARCHAR2(20), -- ���k
-- 2008/07/31 Mod ��
    info_m               VARCHAR2(7),  -- ���l
    info_n               VARCHAR2(10), -- ���m
    info_o               VARCHAR2(2),  -- ���n
    info_p               VARCHAR2(2),  -- ���o
    info_q               VARCHAR2(2),  -- ���p
    amt_a                VARCHAR2(20), -- �����`
    amt_b                VARCHAR2(20), -- �����a
    amt_c                VARCHAR2(20), -- �����b
    amt_d                VARCHAR2(20), -- �����c
    amt_e                VARCHAR2(20), -- �����d
    amt_f                VARCHAR2(20), -- �����e
    amt_g                VARCHAR2(20), -- �����f
    amt_h                VARCHAR2(20), -- �����g
    amt_i                VARCHAR2(20), -- �����h
    amt_j                VARCHAR2(20), -- �����i
--
    description          VARCHAR2(60), -- �E�v(����)
    update_date_h        DATE,         -- �X�V����(�w�b�_)
    update_date_l        DATE,         -- �X�V����(����)
--
    v_seq_no             VARCHAR2(3),  -- �`���p�}��(������)
--
    v_ship_date          VARCHAR2(10), -- �o�ɓ�(������)YYYY/MM/DD
    v_arrival_date       VARCHAR2(10), -- ���ɓ�(������)YYYY/MM/DD
    v_lot_date           VARCHAR2(10), -- ������(������)YYYY/MM/DD
    v_best_bfr_date      VARCHAR2(10), -- �ܖ�����(������)YYYY/MM/DD
    v_designate_date     VARCHAR2(10), -- ���t�w��(������)YYYY/MM/DD
    v_update_date        VARCHAR2(19), -- �X�V����(������)YYYY/MM/DD HH:MI:SS
    v_update_date_h      VARCHAR2(19), -- �X�V����(������)YYYY/MM/DD HH:MI:SS
    v_update_date_l      VARCHAR2(19), -- �X�V����(������)YYYY/MM/DD HH:MI:SS
--
    exec_flg             NUMBER        -- �����t���O
  );
--
  -- �e�}�X�^�֔��f����f�[�^���i�[���錋���z��
  TYPE masters_tbl  IS TABLE OF masters_rec  INDEX BY PLS_INTEGER;
--
  -- ***************************************
  -- ***      �o�^�p���ڃe�[�u���^       ***
  -- ***************************************
--
  gt_master_tbl                masters_tbl;     -- �e�}�X�^�֓o�^����f�[�^
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_wf_ope_div               VARCHAR2(150); --  1.�����敪          (�K�{)
  gv_wf_class                 VARCHAR2(150); --  2.�Ώ�              (�K�{)
  gv_wf_notification          VARCHAR2(150); --  3.����              (�K�{)
  gv_data_class               VARCHAR2(20);  --  4.�f�[�^���        (�K�{)
  gv_ship_no_from             VARCHAR2(20);  --  5.�z��No.FROM       (�C��)
  gv_ship_no_to               VARCHAR2(20);  --  6.�z��No.TO         (�C��)
  gv_req_no_from              VARCHAR2(20);  --  7.�˗�No.FROM       (�C��)
  gv_req_no_to                VARCHAR2(20);  --  8.�˗�No.TO         (�C��)
  gv_vendor_code              VARCHAR2(20);  --  9.�����            (�C��)
  gv_mediation                VARCHAR2(20);  -- 10.������            (�C��)
  gv_location_code            VARCHAR2(20);  -- 11.�o�ɑq��          (�C��)
  gv_arvl_code                VARCHAR2(20);  -- 12.���ɑq��          (�C��)
  gv_vendor_site_code         VARCHAR2(20);  -- 13.�z����            (�C��)
  gv_carrier_code             VARCHAR2(20);  -- 14.�^���Ǝ�          (�C��)
  gv_ship_date_from           VARCHAR2(10);  -- 15.�[����/�o�ɓ�FROM (�K�{)
  gv_ship_date_to             VARCHAR2(10);  -- 16.�[����/�o�ɓ�TO   (�K�{)
  gv_arrival_date_from        VARCHAR2(10);  -- 17.���ɓ�FROM        (�C��)
  gv_arrival_date_to          VARCHAR2(10);  -- 18.���ɓ�TO          (�C��)
  gv_instruction_dept         VARCHAR2(20);  -- 19.�w������          (�C��)
  gv_item_no                  VARCHAR2(20);  -- 20.�i��              (�C��)
  gv_update_time_from         VARCHAR2(20);  -- 21.�X�V����FROM      (�C��)
  gv_update_time_to           VARCHAR2(20);  -- 22.�X�V����TO        (�C��)
  gv_prod_class               VARCHAR2(20);  -- 23.���i�敪          (�C��)
  gv_item_class               VARCHAR2(20);  -- 24.�i�ڋ敪          (�C��)
  gv_sec_class                VARCHAR2(20);  -- 25.�Z�L�����e�B�敪  (�K�{)
--
  gd_ship_date_from           DATE;          -- �[����/�o�ɓ�FROM
  gd_ship_date_to             DATE;          -- �[����/�o�ɓ�TO
  gd_arrival_date_from        DATE;          -- ���ɓ�FROM
  gd_arrival_date_to          DATE;          -- ���ɓ�TO
  gd_update_time_from         DATE;          -- �X�V����FROM
  gd_update_time_to           DATE;          -- �X�V����TO
--
  gv_sch_file_name            VARCHAR2(2000);          -- �Ώۃt�@�C����
--
  gn_user_id                  NUMBER;                  -- ���[�UID
  gd_sys_date                 DATE;                    -- �������t
  gn_person_id                fnd_user.employee_id%TYPE;
--
  gv_min_date                 VARCHAR2(10);            -- �ŏ����t
  gv_max_date                 VARCHAR2(10);            -- �ő���t
--
  gr_outbound_rec             xxcmn_common_pkg.outbound_rec; -- outbound�֘A�f�[�^
--
  /***********************************************************************************
   * Function Name    : replace_sep
   * Description      : ��������ɃJ���}�����݂���ꍇ�폜����
   ***********************************************************************************/
  FUNCTION replace_sep(
    iv_moji_str  IN VARCHAR2)
    RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'replace_sep'; --�v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    lv_sep_com    CONSTANT VARCHAR2(1) := ',';
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
    -- ***************************************
    -- ***      �������W�b�N�̋L�q         ***
    -- ***************************************
    IF (INSTR(iv_moji_str,lv_sep_com) <> 0) THEN
      RETURN REPLACE(iv_moji_str,lv_sep_com);
    ELSE
      RETURN iv_moji_str;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--#####################################  �Œ蕔 END   #############################################
--
  END replace_sep;
--
  /***********************************************************************************
   * Function Name    : decimal_round_up
   * Description      : �����_�̎w��ʒu�ł̐؂�グ���s��
   ***********************************************************************************/
  FUNCTION decimal_round_up(
    in_moji_num  IN NUMBER,
    in_pnt       IN NUMBER)
    RETURN NUMBER
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'decimal_round_up'; --�v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    ln_num        CONSTANT NUMBER := 0.5;
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
    -- ***************************************
    -- ***      �������W�b�N�̋L�q         ***
    -- ***************************************
--
    IF (in_moji_num IS NOT NULL) THEN
      -- �����_�ȉ�����
      IF (MOD(in_moji_num,FLOOR(in_moji_num)) > 0) THEN
        RETURN ROUND(in_moji_num+(ln_num / POWER(10,in_pnt)),in_pnt);
      ELSE
        RETURN in_moji_num;
      END IF;
    ELSE
      RETURN in_moji_num;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--#####################################  �Œ蕔 END   #############################################
--
  END decimal_round_up;
--
  /**********************************************************************************
   * Procedure Name   : parameter_disp
   * Description      : �p�����[�^�̏o��
   ***********************************************************************************/
  PROCEDURE parameter_disp(
    ov_errbuf               OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'parameter_disp';       -- �v���O������
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
    lv_wf_ope_div_n           CONSTANT VARCHAR2(100) := '�����敪          ';
    lv_wf_class_n             CONSTANT VARCHAR2(100) := '�Ώ�              ';
    lv_wf_notification_n      CONSTANT VARCHAR2(100) := '����              ';
    lv_data_class_n           CONSTANT VARCHAR2(100) := '�f�[�^���        ';
    lv_ship_no_from_n         CONSTANT VARCHAR2(100) := '�z��No FROM       ';
    lv_ship_no_to_n           CONSTANT VARCHAR2(100) := '�z��No TO         ';
    lv_req_no_from_n          CONSTANT VARCHAR2(100) := '�˗�No FROM       ';
    lv_req_no_to_n            CONSTANT VARCHAR2(100) := '�˗�No TO         ';
    lv_vendor_id_n            CONSTANT VARCHAR2(100) := '�����            ';
    lv_mediation_n            CONSTANT VARCHAR2(100) := '������            ';
    lv_location_code_n        CONSTANT VARCHAR2(100) := '�o�ɑq��          ';
    lv_arvl_code_n            CONSTANT VARCHAR2(100) := '���ɑq��          ';
    lv_vendor_site_id_n       CONSTANT VARCHAR2(100) := '�z����            ';
    lv_carrier_code_n         CONSTANT VARCHAR2(100) := '�^���Ǝ�          ';
    lv_ship_date_from_n       CONSTANT VARCHAR2(100) := '�[����/�o�ɓ�FROM ';
    lv_ship_date_to_n         CONSTANT VARCHAR2(100) := '�[����/�o�ɓ�TO   ';
    lv_arvl_date_from_n       CONSTANT VARCHAR2(100) := '���ɓ�FROM        ';
    lv_arvl_date_to_n         CONSTANT VARCHAR2(100) := '���ɓ�TO          ';
    lv_inst_dept_n            CONSTANT VARCHAR2(100) := '�w������          ';
    lv_item_no_n              CONSTANT VARCHAR2(100) := '�i��              ';
    lv_upd_time_from_n        CONSTANT VARCHAR2(100) := '�X�V����FROM      ';
    lv_upd_time_to_n          CONSTANT VARCHAR2(100) := '�X�V����TO        ';
    lv_prod_class_n           CONSTANT VARCHAR2(100) := '���i�敪          ';
    lv_item_class_n           CONSTANT VARCHAR2(100) := '�i�ڋ敪          ';
    lv_sec_class_n            CONSTANT VARCHAR2(100) := '�Z�L�����e�B�敪  ';
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
    -- �����敪
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_wf_ope_div_n,
                                          gv_tkn_data,
                                          gv_wf_ope_div);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- �Ώ�
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_wf_class_n,
                                          gv_tkn_data,
                                          gv_wf_class);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- ����
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_wf_notification_n,
                                          gv_tkn_data,
                                          gv_wf_notification);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- �f�[�^���
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_data_class_n,
                                          gv_tkn_data,
                                          gv_data_class);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- �z��No FROM
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_ship_no_from_n,
                                          gv_tkn_data,
                                          gv_ship_no_from);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- �z��No TO
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_ship_no_to_n,
                                          gv_tkn_data,
                                          gv_ship_no_to);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- �˗�No FROM
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_req_no_from_n,
                                          gv_tkn_data,
                                          gv_req_no_from);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- �˗�No TO
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_req_no_to_n,
                                          gv_tkn_data,
                                          gv_req_no_to);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- �����
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_vendor_id_n,
                                          gv_tkn_data,
                                          gv_vendor_code);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- ������
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_mediation_n,
                                          gv_tkn_data,
                                          gv_mediation);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- �o�ɑq��
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_location_code_n,
                                          gv_tkn_data,
                                          gv_location_code);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- ���ɑq��
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_arvl_code_n,
                                          gv_tkn_data,
                                          gv_arvl_code);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- �z����
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_vendor_site_id_n,
                                          gv_tkn_data,
                                          gv_vendor_site_code);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- �^���Ǝ�
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_carrier_code_n,
                                          gv_tkn_data,
                                          gv_carrier_code);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- �[����/�o�ɓ�FROM
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_ship_date_from_n,
                                          gv_tkn_data,
                                          gv_ship_date_from);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- �[����/�o�ɓ�TO
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_ship_date_to_n,
                                          gv_tkn_data,
                                          gv_ship_date_to);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- ���ɓ�FROM
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_arvl_date_from_n,
                                          gv_tkn_data,
                                          gv_arrival_date_from);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- ���ɓ�TO
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_arvl_date_to_n,
                                          gv_tkn_data,
                                          gv_arrival_date_to);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- �w������
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_inst_dept_n,
                                          gv_tkn_data,
                                          gv_instruction_dept);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- �i��
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_item_no_n,
                                          gv_tkn_data,
                                          gv_item_no);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- �X�V����FROM
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_upd_time_from_n,
                                          gv_tkn_data,
                                          gv_update_time_from);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- �X�V����TO
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_upd_time_to_n,
                                          gv_tkn_data,
                                          gv_update_time_to);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- ���i�敪
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_prod_class_n,
                                          gv_tkn_data,
                                          gv_prod_class);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- �i�ڋ敪
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_item_class_n,
                                          gv_tkn_data,
                                          gv_item_class);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- �Z�L�����e�B�敪
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_94d_07,
                                          gv_tkn_param,
                                          lv_sec_class_n,
                                          gv_tkn_data,
                                          gv_sec_class);
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
  END parameter_disp;
--
  /**********************************************************************************
   * Procedure Name   : parameter_check
   * Description      : �p�����[�^�`�F�b�N(D-1)
   ***********************************************************************************/
  PROCEDURE parameter_check(
    iv_wf_ope_div        IN            VARCHAR2,  --  1.�����敪          (�K�{)
    iv_wf_class          IN            VARCHAR2,  --  2.�Ώ�              (�K�{)
    iv_wf_notification   IN            VARCHAR2,  --  3.����              (�K�{)
    iv_data_class        IN            VARCHAR2,  --  4.�f�[�^���        (�K�{)
    iv_ship_no_from      IN            VARCHAR2,  --  5.�z��No.FROM       (�C��)
    iv_ship_no_to        IN            VARCHAR2,  --  6.�z��No.TO         (�C��)
    iv_req_no_from       IN            VARCHAR2,  --  7.�˗�No.FROM       (�C��)
    iv_req_no_to         IN            VARCHAR2,  --  8.�˗�No.TO         (�C��)
    iv_vendor_code       IN            VARCHAR2,  --  9.�����            (�C��)
    iv_mediation         IN            VARCHAR2,  -- 10.������            (�C��)
    iv_location_code     IN            VARCHAR2,  -- 11.�o�ɑq��          (�C��)
    iv_arvl_code         IN            VARCHAR2,  -- 12.���ɑq��          (�C��)
    iv_vendor_site_code  IN            VARCHAR2,  -- 13.�z����            (�C��)
    iv_carrier_code      IN            VARCHAR2,  -- 14.�^���Ǝ�          (�C��)
    iv_ship_date_from    IN            VARCHAR2,  -- 15.�[����/�o�ɓ�FROM (�K�{)
    iv_ship_date_to      IN            VARCHAR2,  -- 16.�[����/�o�ɓ�TO   (�K�{)
    iv_arrival_date_from IN            VARCHAR2,  -- 17.���ɓ�FROM        (�C��)
    iv_arrival_date_to   IN            VARCHAR2,  -- 18.���ɓ�TO          (�C��)
    iv_instruction_dept  IN            VARCHAR2,  -- 19.�w������          (�C��)
    iv_item_no           IN            VARCHAR2,  -- 20.�i��              (�C��)
    iv_update_time_from  IN            VARCHAR2,  -- 21.�X�V����FROM      (�C��)
    iv_update_time_to    IN            VARCHAR2,  -- 22.�X�V����TO        (�C��)
    iv_prod_class        IN            VARCHAR2,  -- 23.���i�敪          (�C��)
    iv_item_class        IN            VARCHAR2,  -- 24.�i�ڋ敪          (�C��)
    iv_sec_class         IN            VARCHAR2,  -- 25.�Z�L�����e�B�敪  (�K�{)
    ov_errbuf               OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_wf_ope_div_n           CONSTANT VARCHAR2(100) := '�����敪';
    lv_wf_class_n             CONSTANT VARCHAR2(100) := '�Ώ�';
    lv_wf_notification_n      CONSTANT VARCHAR2(100) := '����';
    lv_data_class_n           CONSTANT VARCHAR2(100) := '�f�[�^���';
    lv_ship_no_from_n         CONSTANT VARCHAR2(100) := '�z��No FROM';
    lv_ship_no_to_n           CONSTANT VARCHAR2(100) := '�z��No TO';
    lv_req_no_from_n          CONSTANT VARCHAR2(100) := '�˗�No FROM';
    lv_req_no_to_n            CONSTANT VARCHAR2(100) := '�˗�No TO';
    lv_vendor_id_n            CONSTANT VARCHAR2(100) := '�����';
    lv_mediation_n            CONSTANT VARCHAR2(100) := '������';
    lv_location_code_n        CONSTANT VARCHAR2(100) := '�o�ɑq��';
    lv_arvl_code_n            CONSTANT VARCHAR2(100) := '���ɑq��';
    lv_vendor_site_id_n       CONSTANT VARCHAR2(100) := '�z����';
    lv_carrier_code_n         CONSTANT VARCHAR2(100) := '�^���Ǝ�';
    lv_ship_date_from_n       CONSTANT VARCHAR2(100) := '�[����/�o�ɓ�FROM';
    lv_ship_date_to_n         CONSTANT VARCHAR2(100) := '�[����/�o�ɓ�TO';
    lv_arvl_date_from_n       CONSTANT VARCHAR2(100) := '���ɓ�FROM';
    lv_arvl_date_to_n         CONSTANT VARCHAR2(100) := '���ɓ�TO';
    lv_inst_dept_n            CONSTANT VARCHAR2(100) := '�w������';
    lv_item_no_n              CONSTANT VARCHAR2(100) := '�i��';
    lv_upd_time_from_n        CONSTANT VARCHAR2(100) := '�X�V����FROM';
    lv_upd_time_to_n          CONSTANT VARCHAR2(100) := '�X�V����TO';
    lv_prod_class_n           CONSTANT VARCHAR2(100) := '���i�敪';
    lv_item_class_n           CONSTANT VARCHAR2(100) := '�i�ڋ敪';
    lv_sec_class_n            CONSTANT VARCHAR2(100) := '�Z�L�����e�B�敪';
    lv_max_date_name          CONSTANT VARCHAR2(100) := 'MAX���t';
    lv_min_date_name          CONSTANT VARCHAR2(100) := 'MIN���t';
--
    lv_min_time               CONSTANT VARCHAR2(8)   := '00:00:00';
    lv_max_time               CONSTANT VARCHAR2(8)   := '23:59:59';
--
    -- *** ���[�J���ϐ� ***
    lv_update_time_from       VARCHAR2(20);
    lv_update_time_to         VARCHAR2(20);
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
    -- �K�{���ڃ`�F�b�N
    -- �����敪
    IF (iv_wf_ope_div IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_94d_02,
                                            gv_tkn_param_name,
                                            lv_wf_ope_div_n);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �Ώ�
    IF (iv_wf_class IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_94d_02,
                                            gv_tkn_param_name,
                                            lv_wf_class_n);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ����
    IF (iv_wf_notification IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_94d_02,
                                            gv_tkn_param_name,
                                            lv_wf_notification_n);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �f�[�^���
    IF (iv_data_class IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_94d_02,
                                            gv_tkn_param_name,
                                            lv_data_class_n);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �[����/�o�ɓ�FROM
    IF (iv_ship_date_from IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_94d_02,
                                            gv_tkn_param_name,
                                            lv_ship_date_from_n);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �[����/�o�ɓ�TO
    IF (iv_ship_date_to IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_94d_02,
                                            gv_tkn_param_name,
                                            lv_ship_date_to_n);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �Z�L�����e�B�敪
    IF (iv_sec_class IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_94d_02,
                                            gv_tkn_param_name,
                                            lv_sec_class_n);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �Ó����`�F�b�N
    -- �f�[�^���
    IF ((iv_data_class <> gv_data_class_mov)
     AND (iv_data_class <> gv_data_class_oha)
     AND (iv_data_class <> gv_data_class_pha)) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_94d_06,
                                            gv_tkn_error_param,
                                            lv_data_class_n,
                                            gv_tkn_error_value,
                                            iv_data_class);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �[����/�o�ɓ�
-- 2009/02/04 v1.5 N.Yoshida Mod Start
--    gd_ship_date_to := FND_DATE.STRING_TO_DATE(iv_ship_date_to,'YYYY/MM/DD');
    gd_ship_date_to := FND_DATE.STRING_TO_DATE(iv_ship_date_to,'YYYY/MM/DD HH24:MI:SS');
-- 2009/02/04 v1.5 N.Yoshida Mod End
    IF (gd_ship_date_to IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_94d_03,
                                            gv_tkn_param_value,
                                            iv_ship_date_to);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
-- 2009/02/04 v1.5 N.Yoshida Mod Start
--    gd_ship_date_from := FND_DATE.STRING_TO_DATE(iv_ship_date_from,'YYYY/MM/DD');
    gd_ship_date_from := FND_DATE.STRING_TO_DATE(iv_ship_date_from,'YYYY/MM/DD HH24:MI:SS');
-- 2009/02/04 v1.5 N.Yoshida Mod End
    IF (gd_ship_date_from IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_94d_03,
                                            gv_tkn_param_value,
                                            iv_ship_date_from);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF (gd_ship_date_from > gd_ship_date_to) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_94d_04);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ���ɓ�
    IF (iv_arrival_date_to IS NOT NULL) THEN
-- 2009/02/04 v1.5 N.Yoshida Mod Start
--      gd_arrival_date_to := FND_DATE.STRING_TO_DATE(iv_arrival_date_to,'YYYY/MM/DD');
      gd_arrival_date_to := FND_DATE.STRING_TO_DATE(iv_arrival_date_to,'YYYY/MM/DD HH24:MI:SS');
-- 2009/02/04 v1.5 N.Yoshida Mod End
      IF (gd_arrival_date_to IS NULL) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_94d_03,
                                              gv_tkn_param_value,
                                              iv_arrival_date_to);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
    IF (iv_arrival_date_from IS NOT NULL) THEN
-- 2009/02/04 v1.5 N.Yoshida Mod Start
--      gd_arrival_date_from := FND_DATE.STRING_TO_DATE(iv_arrival_date_from,'YYYY/MM/DD');
      gd_arrival_date_from := FND_DATE.STRING_TO_DATE(iv_arrival_date_from,'YYYY/MM/DD HH24:MI:SS');
-- 2009/02/04 v1.5 N.Yoshida Mod End
      IF (gd_arrival_date_from IS NULL) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_94d_03,
                                              gv_tkn_param_value,
                                              iv_arrival_date_from);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
    IF ((iv_arrival_date_from IS NOT NULL) AND (iv_arrival_date_to IS NOT NULL)) THEN
      IF (gd_arrival_date_from > gd_arrival_date_to) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_94d_04);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--
    IF ((iv_req_no_from IS NOT NULL) AND (iv_req_no_to IS NOT NULL)) THEN
      IF (iv_req_no_from > iv_req_no_to) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_94d_04);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- �X�V����
    IF (iv_update_time_from IS NOT NULL) THEN
      lv_update_time_from := iv_update_time_from;
      IF (LENGTH(lv_update_time_from) = 10) THEN
        lv_update_time_from := lv_update_time_from || ' ' || lv_min_time;
      END IF;
      gd_update_time_from := FND_DATE.STRING_TO_DATE(lv_update_time_from,'YYYY/MM/DD HH24:MI:SS');
      IF (gd_update_time_from IS NULL) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_94d_03,
                                              gv_tkn_param_value,
                                              iv_update_time_from);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
    IF (iv_update_time_to IS NOT NULL) THEN
      lv_update_time_to   := iv_update_time_to;
      IF (LENGTH(lv_update_time_to) = 10) THEN
        lv_update_time_to := lv_update_time_to || ' ' || lv_max_time;
      END IF;
      gd_update_time_to   := FND_DATE.STRING_TO_DATE(lv_update_time_to,'YYYY/MM/DD HH24:MI:SS');
      IF (gd_update_time_to IS NULL) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_94d_03,
                                              gv_tkn_param_value,
                                              iv_update_time_to);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
    IF ((iv_update_time_from IS NOT NULL) AND (iv_update_time_to IS NOT NULL)) THEN
      IF (gd_update_time_from > gd_update_time_to) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_94d_04);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--
    --�ő���t�擾
    gv_max_date := SUBSTR(FND_PROFILE.VALUE('XXCMN_MAX_DATE'),1,10);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_max_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_94d_01,
                                            gv_tkn_name,
                                            lv_max_date_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --�ŏ����t�擾
    gv_min_date := SUBSTR(FND_PROFILE.VALUE('XXCMN_MIN_DATE'),1,10);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_min_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_94d_01,
                                            gv_tkn_name,
                                            lv_min_date_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    gn_user_id             := FND_GLOBAL.USER_ID;
    gd_sys_date            := SYSDATE;
--
    SELECT employee_id
    INTO   gn_person_id
    FROM   fnd_user
    WHERE  user_id = gn_user_id
    AND    ROWNUM = 1;
--
    gv_wf_ope_div        := iv_wf_ope_div;
    gv_wf_class          := iv_wf_class;
    gv_wf_notification   := iv_wf_notification;
    gv_data_class        := iv_data_class;
    gv_ship_no_from      := iv_ship_no_from;
    gv_ship_no_to        := iv_ship_no_to;
    gv_req_no_from       := iv_req_no_from;
    gv_req_no_to         := iv_req_no_to;
    gv_vendor_code       := iv_vendor_code;
    gv_mediation         := iv_mediation;
    gv_location_code     := iv_location_code;
    gv_arvl_code         := iv_arvl_code;
    gv_vendor_site_code  := iv_vendor_site_code;
    gv_carrier_code      := iv_carrier_code;
-- 2009/02/04 v1.5 N.Yoshida Mod Start
--    gv_ship_date_from    := iv_ship_date_from;
--    gv_ship_date_to      := iv_ship_date_to;
--    gv_arrival_date_from := iv_arrival_date_from;
--    gv_arrival_date_to   := iv_arrival_date_to;
    gv_ship_date_from    := TO_CHAR(gd_ship_date_from, 'YYYY/MM/DD');
    gv_ship_date_to      := TO_CHAR(gd_ship_date_to, 'YYYY/MM/DD');
    gv_arrival_date_from := TO_CHAR(gd_arrival_date_from, 'YYYY/MM/DD');
    gv_arrival_date_to   := TO_CHAR(gd_arrival_date_to, 'YYYY/MM/DD');
-- 2009/02/04 v1.5 N.Yoshida Mod End
    gv_instruction_dept  := iv_instruction_dept;
    gv_item_no           := iv_item_no;
    gv_update_time_from  := iv_update_time_from;
    gv_update_time_to    := iv_update_time_to;
    gv_prod_class        := iv_prod_class;
    gv_item_class        := iv_item_class;
    gv_sec_class         := iv_sec_class;
--
    -- WF�Ɋ֘A��������擾
    xxcmn_common_pkg.get_outbound_info(
      gv_wf_ope_div,               -- �����敪
      gv_wf_class,                 -- �Ώ�
      gv_wf_notification,          -- ����
      gr_outbound_rec,             -- outbound�֘A�f�[�^
      lv_errbuf,
      lv_retcode,
      lv_errmsg
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- �p�����[�^�o��
    parameter_disp(
      lv_errbuf,
      lv_retcode,
      lv_errmsg
    );
--
    IF (lv_retcode = gv_status_error) THEN
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
  END parameter_check;
--
  /**********************************************************************************
   * Procedure Name   : pha_sel_proc
   * Description      : ������񌟍�����(D-3)
   ***********************************************************************************/
  PROCEDURE pha_sel_proc(
    ov_errbuf           OUT NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pha_sel_proc'; -- �v���O������
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
    mst_rec         masters_rec;
    ln_cnt          NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR mst_data_cur
    IS
/* 2008/09/02 Mod ��
      SELECT pha.po_header_id as sel_tbl_id                 -- �e�[�u��ID
2008/09/02 Mod �� */
      SELECT TO_CHAR(pha.po_header_id) || '1' as sel_tbl_id -- �e�[�u��ID
            ,gv_company_name as company_name                -- ��Ж�
            ,gv_data_class_pha as data_class                -- �f�[�^���
            ,NULL as ship_no                                -- �z��No.
            ,pha.segment1 as request_no                     -- �˗�No.
            ,pha.attribute9 as relation_no                  -- �֘ANo.
            ,NULL as base_request_no                        -- �R�s�[��No.    2008/09/02 Add
            ,NULL as base_ship_no                           -- ���z��No.
            ,xvv1.segment1 as vendor_code                   -- �����R�[�h
            ,xvv1.vendor_full_name as vendor_name           -- ����於
            ,xvv1.vendor_short_name as vendor_s_name        -- ����旪��
            ,xvv2.segment1 as mediation_code                -- �����҃R�[�h
            ,xvv2.vendor_full_name as mediation_name        -- �����Җ�
            ,xvv2.vendor_short_name as mediation_s_name     -- �����җ���
            ,pha.attribute5 as whse_code                    -- �q�ɃR�[�h
            ,xilv.description as whse_name                  -- �q�ɖ�
            ,xilv.short_name as whse_s_name                 -- �q�ɗ���
            ,DECODE(pha.attribute6,gv_drop_ship_type_ship,
                    pha.attribute7,
                    NULL) as vendor_site_code               -- �z����R�[�h
            ,DECODE(pha.attribute6,gv_drop_ship_type_ship,
                    xpsv.party_site_full_name,
                    NULL) as vendor_site_name               -- �z���於
            ,DECODE(pha.attribute6,gv_drop_ship_type_ship,
                    xpsv.party_site_short_name,
                    NULL) as vendor_site_s_name             -- �z���旪��
            ,DECODE(pha.attribute6,gv_drop_ship_type_ship,
                    xpsv.zip,
                    NULL) as zip                            -- �X�֔ԍ�
            ,DECODE(pha.attribute6,gv_drop_ship_type_ship,
                    xpsv.address_line1||xpsv.address_line2,
                    NULL) as address                        -- �Z��
            ,DECODE(pha.attribute6,gv_drop_ship_type_ship,
                    xpsv.phone,
                    NULL) as phone                          -- �d�b�ԍ�
            ,NULL as carrier_code                           -- �^���Ǝ҃R�[�h
            ,NULL as carrier_name                           -- �^���ƎҖ�
            ,NULL as carrier_s_name                         -- �^���Ǝҗ���
            ,pha.attribute4 as ship_date                    -- �o�ɓ�
            ,pha.attribute4 as arrival_date                 -- ���ɓ�
            ,NULL as arrival_time_from                      -- ���׎���FROM
            ,NULL as arrival_time_to                        -- ���׎���TO
            ,NULL as method_code                            -- �z���敪
            ,NULL as div_a                                  -- �敪�`(�^���敪)
            ,pha.attribute6 as div_b                        -- �敪�a(�����敪)
            ,NULL as div_c                                  -- �敪�b(�d�ʗe�ϋ敪)
            ,pha.attribute10 as instruction_dept            -- �w�������R�[�h
            ,xpha.requested_department_code as request_dept -- �˗������R�[�h
            ,pha.attribute1 as status                       -- �X�e�[�^�X
            ,NULL as notif_status                           -- �ʒm�X�e�[�^�X
            ,pha.attribute11 as div_d                       -- �敪�c(�����敪)
            ,pha.attribute2 as div_e                        -- �敪�d(�d���揳���v���敪)
            ,xpha.order_approved_flg as div_f               -- �敪�e(���������t���O)
            ,xpha.purchase_approved_flg as div_g            -- �敪�f(�d�������t���O)
            ,xprh.change_flag as div_h                      -- �敪�g(�ύX�t���O)
            ,NULL as info_a                                 -- ���`
            ,NULL as info_b                                 -- ���a
            ,NULL as info_c                                 -- ���b
            ,NULL as info_d                                 -- ���c
            ,NULL as info_e                                 -- ���d
            ,pha.attribute15 as head_description            -- �E�v(�w�b�_)
            ,pla.attribute15 as line_description            -- �E�v(����)
            ,pla.line_num                                   -- ����No.
            ,ximv.item_no                                   -- �i�ڃR�[�h
            ,ximv.item_name                                 -- �i�ږ�
            ,ximv.item_short_name as item_s_name            -- �i�ڗ���
            ,pla.attribute3 as futai_code                   -- �t��
            ,DECODE(ximv.lot_ctl,gv_lot_ctl_on,
                    pla.attribute1,
                    NULL) as lot_no                         -- ���b�gNo
            ,ilm.attribute1 as lot_date                     -- ������
            ,ilm.attribute3 as best_bfr_date                -- �ܖ�����
            ,ilm.attribute2 as lot_sign                     -- �ŗL�L��
            ,pla.attribute11 as request_qty                 -- �˗���
            ,pla.attribute11 as instruct_qty                -- �w����
            ,pla.attribute6 as num_of_deliver               -- �o�ɐ�
            ,pla.attribute7 as ship_to_qty                  -- ���ɐ�
            ,pla.attribute7 as fix_qty                      -- �m�萔
            ,pla.attribute10 as item_um                     -- �P��
            ,NULL as weight_capacity                        -- �d�ʗe��
            ,pla.attribute4 as frequent_qty                 -- ����
            ,pla.attribute2 as frequent_factory             -- �H��R�[�h
            ,pla.attribute13 as div_i                       -- �敪�h(���ʊm��t���O)
            ,pla.attribute14 as div_j                       -- �敪�i(���z�m��t���O)
            ,pla.cancel_flag as div_k                       -- �敪�j(����t���O)
            ,pla.attribute9 as designate_date               -- ���t�w��
            ,ilm.attribute11 as info_f                      -- ���e(�N�x)
            ,ilm.attribute12 as info_g                      -- ���f(�Y�n�R�[�h)
            ,ilm.attribute14 as info_h                      -- ���g(�q�P)
            ,ilm.attribute15 as info_i                      -- ���h(�q�Q)
            ,ilm.attribute19 as info_j                      -- ���i(�q�R)
            ,ilm.attribute20 as info_k                      -- ���j(�����H��)
            ,ilm.attribute21 as info_l                      -- ���k(�������b�g)
            ,plla.attribute10 as info_m                     -- ���l(���i�ڃR�[�h)
            ,plla.attribute11 as info_n                     -- ���m(�����b�g)
            ,ilm.attribute9 as info_o                       -- ���n(�d���`��)
            ,ilm.attribute10 as info_p                      -- ���o(�����敪)
            ,ilm.attribute13 as info_q                      -- ���p(�^�C�v)
            ,pla.unit_price as amt_a                        -- �����`(�P��)
            ,plla.attribute1 as amt_b                       -- �����a(������)
            ,plla.attribute2 as amt_c                       -- �����b(������P��)
            ,plla.attribute3 as amt_d                       -- �����c(���K�敪)
            ,plla.attribute4 as amt_e                       -- �����d(���K)
            ,plla.attribute5 as amt_f                       -- �����e(�a����K���z)
            ,plla.attribute6 as amt_g                       -- �����f(���ۋ��敪)
            ,plla.attribute7 as amt_h                       -- �����g(���ۋ�)
            ,plla.attribute8 as amt_i                       -- �����h(���ۋ��z)
            ,plla.attribute9 as amt_j                       -- �����i(��������z)
            ,pha.last_update_date as update_date_h          -- �ŏI�X�V��(�w�b�_)
            ,pla.last_update_date as update_date_l          -- �ŏI�X�V��(����)
      FROM   po_headers_all           pha  -- �����w�b�_
            ,po_lines_all             pla  -- ��������
            ,po_line_locations_all    plla -- �����[������
            ,xxpo_headers_all         xpha -- �����w�b�_(�A�h�I��)
            ,ic_lots_mst              ilm  -- OPM���b�g�}�X�^
            ,xxpo_requisition_headers xprh -- �����˗��w�b�_(�A�h�I��)
            ,xxcmn_item_mst2_v        ximv -- OPM�i�ڏ��VIEW2
            ,xxcmn_item_categories4_v xicv -- OPM�i�ڃJ�e�S���������VIEW4
            ,xxcmn_item_locations2_v  xilv -- OPM�ۊǏꏊ���VIEW2
            ,xxcmn_vendors2_v         xvv1 -- �d������VIEW2
            ,xxcmn_vendors2_v         xvv2 -- �d������VIEW2
            ,xxcmn_party_sites2_v     xpsv -- �p�[�e�B�T�C�g���VIEW2
      WHERE  pha.po_header_id      = pla.po_header_id
      AND    pla.po_line_id        = plla.po_line_id
      AND    pha.segment1          = xpha.po_header_number 
      AND    pha.segment1          = xprh.po_header_number(+)
      AND    pha.attribute5        = xilv.segment1
      AND    pla.item_id           = ximv.inventory_item_id
      AND    ximv.item_id          = xicv.item_id
      AND    pla.attribute1        = ilm.lot_no
      AND    ilm.item_id           = ximv.item_id
      AND    pha.vendor_id         = xvv1.vendor_id
      AND    pha.attribute3        = xvv2.vendor_id(+)
      AND    pha.attribute7        = xpsv.party_site_number(+)
-- �X�e�[�^�X
      -- 2008/07/30 Mod ��
/*
      AND    NVL(pha.attribute1,gv_status_null) IN (
                 gv_xxpo_status_02                    -- �����쐬��:20
                ,gv_xxpo_status_03                    -- �������:25
                ,gv_xxpo_status_04                    -- ���ʊm���:30
                ,gv_xxpo_status_05                    -- ���z�m���:35
                ,gv_xxpo_status_06                    -- ���:99
             )
*/
      AND    NVL(pha.attribute1,gv_status_null) >= gv_xxpo_status_02  -- �����쐬��:20�ȍ~
      -- 2008/07/30 Mod ��
-- �˗�No
      AND    ((gv_req_no_from IS NULL) OR (pha.segment1 >= gv_req_no_from))
      AND    ((gv_req_no_to IS NULL)   OR (pha.segment1 <= gv_req_no_to))
-- �����
      AND    ((gv_vendor_code IS NULL) OR (xvv1.segment1 = gv_vendor_code))
-- ������
      AND    ((gv_mediation IS NULL) OR (xvv2.segment1 = gv_mediation))
-- ���ɑq��
      AND    ((gv_arvl_code IS NULL) OR (pha.attribute5 = gv_arvl_code))
-- �[����(�K�{)
      AND    pha.attribute4 >= gv_ship_date_from
      AND    pha.attribute4 <= gv_ship_date_to
-- �w������
      AND    ((gv_instruction_dept IS NULL) OR (pha.attribute10 = gv_instruction_dept))
-- �i��
      AND    ((gv_item_no IS NULL) OR (ximv.item_no = gv_item_no))
-- �X�V����
      AND    ((gd_update_time_from IS NULL) OR (pha.last_update_date >= gd_update_time_from))
      AND    ((gd_update_time_to IS NULL)   OR (pha.last_update_date <= gd_update_time_to))
      AND    ((gd_update_time_from IS NULL) OR (pla.last_update_date >= gd_update_time_from))
      AND    ((gd_update_time_to IS NULL)   OR (pla.last_update_date <= gd_update_time_to))
-- ���i�敪
      AND    ((gv_prod_class IS NULL) OR (xicv.prod_class_code   = gv_prod_class))
-- �i�ڋ敪
      AND    ((gv_item_class IS NULL) OR (xicv.item_class_code   = gv_item_class))
-- OPM�i�ڏ��VIEW2
      AND     FND_DATE.STRING_TO_DATE(pha.attribute4,'YYYY/MM/DD') BETWEEN ximv.start_date_active
      AND     ximv.end_date_active
-- OPM�ۊǏꏊ���VIEW2
      AND     xilv.date_from <= FND_DATE.STRING_TO_DATE(pha.attribute4,'YYYY/MM/DD')
      AND     (xilv.date_to >= FND_DATE.STRING_TO_DATE(pha.attribute4,'YYYY/MM/DD')
       OR      xilv.date_to IS NULL)
      AND     xilv.disable_date IS NULL
-- �d������VIEW2
      AND     xvv1.inactive_date IS NULL
      AND     FND_DATE.STRING_TO_DATE(pha.attribute4,'YYYY/MM/DD') BETWEEN xvv1.start_date_active
      AND     xvv1.end_date_active
-- �d������VIEW2
      AND     xvv2.inactive_date IS NULL
      AND     FND_DATE.STRING_TO_DATE(pha.attribute4,'YYYY/MM/DD') 
      BETWEEN NVL(xvv2.start_date_active,FND_DATE.STRING_TO_DATE(gv_min_date,'YYYY/MM/DD'))
      AND     NVL(xvv2.end_date_active,FND_DATE.STRING_TO_DATE(gv_max_date,'YYYY/MM/DD'))
-- �p�[�e�B�T�C�g���VIEW2
      AND     NVL(xpsv.party_site_status,gv_status_on) = gv_status_on
      AND     NVL(xpsv.cust_acct_site_status,gv_status_on) = gv_status_on
      AND     NVL(xpsv.cust_site_uses_status,gv_status_on) = gv_status_on
      AND     FND_DATE.STRING_TO_DATE(pha.attribute4,'YYYY/MM/DD') 
      BETWEEN NVL(xpsv.start_date_active,FND_DATE.STRING_TO_DATE(gv_min_date,'YYYY/MM/DD'))
      AND     NVL(xpsv.end_date_active,FND_DATE.STRING_TO_DATE(gv_max_date,'YYYY/MM/DD'))
-- �Z�L�����e�B�敪
      AND    (
-- �ɓ������[�U�[�^�C�v
              (gv_sec_class = gv_sec_class_home)
-- ����惆�[�U�[�^�C�v
       OR     (gv_sec_class = gv_sec_class_vend
               AND    (xvv1.segment1 IN
                 (SELECT papf.attribute4           -- �����R�[�h(�d����R�[�h)
                  FROM   fnd_user           fu              -- ���[�U�[�}�X�^
                        ,per_all_people_f   papf            -- �]�ƈ��}�X�^
                  WHERE  fu.employee_id   = papf.person_id                   -- �]�ƈ�ID
                  AND    papf.effective_start_date <= TRUNC(gd_sys_date)     -- �K�p�J�n��
                  AND    papf.effective_end_date   >= TRUNC(gd_sys_date)     -- �K�p�I����
                  AND    fu.start_date             <= TRUNC(gd_sys_date)     -- �K�p�J�n��
                  AND  ((fu.end_date               IS NULL)                  -- �K�p�I����
                    OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                  AND    fu.user_id                 = gn_user_id)            -- ���[�U�[ID
                OR     xvv2.segment1 IN
                 (SELECT papf.attribute4           -- �����R�[�h(�d����R�[�h)
                  FROM   fnd_user           fu              -- ���[�U�[�}�X�^
                        ,per_all_people_f   papf            -- �]�ƈ��}�X�^
                  WHERE  fu.employee_id   = papf.person_id                   -- �]�ƈ�ID
                  AND    papf.effective_start_date <= TRUNC(gd_sys_date)     -- �K�p�J�n��
                  AND    papf.effective_end_date   >= TRUNC(gd_sys_date)     -- �K�p�I����
                  AND    fu.start_date             <= TRUNC(gd_sys_date)     -- �K�p�J�n��
                  AND  ((fu.end_date               IS NULL)                  -- �K�p�I����
                    OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                  AND    fu.user_id                 = gn_user_id))            -- ���[�U�[ID
              )
-- �O���q�Ƀ��[�U�[�^�C�v
       OR     (gv_sec_class = gv_sec_class_extn
               AND    pha.attribute5 IN
                 (SELECT xilv.segment1                -- �ۊǑq�ɃR�[�h
                  FROM   fnd_user               fu          -- ���[�U�[�}�X�^
                        ,per_all_people_f       papf        -- �]�ƈ��}�X�^
                        ,xxcmn_item_locations_v xilv        -- OPM�ۊǏꏊ���VIEW
                  WHERE  fu.employee_id             = papf.person_id         -- �]�ƈ�ID
                  AND    papf.effective_start_date <= TRUNC(gd_sys_date)     -- �K�p�J�n��
                  AND    papf.effective_end_date   >= TRUNC(gd_sys_date)     -- �K�p�I����
                  AND    fu.start_date             <= TRUNC(gd_sys_date)     -- �K�p�J�n��
                  AND  ((fu.end_date               IS NULL)                  -- �K�p�I����
                    OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                  AND    xilv.purchase_code         = papf.attribute4        -- �d����R�[�h
                  AND    fu.user_id                 = gn_user_id)            -- ���[�U�[ID
              )
-- ���m�u�����[�U�[�^�C�v
       OR     (gv_sec_class = gv_sec_class_quay
               AND    (
                       pha.attribute5 IN (
                          SELECT xilv.segment1                -- �ۊǑq�ɃR�[�h
                          FROM   fnd_user               fu          -- ���[�U�[�}�X�^
                                ,per_all_people_f       papf        -- �]�ƈ��}�X�^
                                ,xxcmn_item_locations_v xilv        -- OPM�ۊǏꏊ���VIEW
                          WHERE  fu.employee_id             = papf.person_id        -- �]�ƈ�ID
                          AND    papf.effective_start_date <= TRUNC(gd_sys_date)    -- �K�p�J�n��
                          AND    papf.effective_end_date   >= TRUNC(gd_sys_date)    -- �K�p�I����
                          AND    fu.start_date             <= TRUNC(gd_sys_date)    -- �K�p�J�n��
                          AND  ((fu.end_date               IS NULL)                 -- �K�p�I����
                            OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                          AND    xilv.purchase_code         = papf.attribute4       -- �d����R�[�h
                          AND    fu.user_id                 = gn_user_id            -- ���[�U�[ID
                          )
               OR      pha.attribute5 IN (
-- 2008/11/26 Mod ��
-- 2008/07/30 Mod ��
--                          SELECT xilv.frequent_whse           -- ��\�q��
--                          SELECT xilv.frequent_whse_code      -- ��Ǒq��
                          SELECT xilv2.segment1
-- 2008/07/30 Mod ��
                          FROM   fnd_user               fu          -- ���[�U�[�}�X�^
                                ,per_all_people_f       papf        -- �]�ƈ��}�X�^
                                ,xxcmn_item_locations_v xilv        -- OPM�ۊǏꏊ���VIEW
                                ,xxcmn_item_locations_v xilv2       -- OPM�ۊǏꏊ���VIEW
                          WHERE  fu.employee_id             = papf.person_id        -- �]�ƈ�ID
                          AND    papf.effective_start_date <= TRUNC(gd_sys_date)    -- �K�p�J�n��
                          AND    papf.effective_end_date   >= TRUNC(gd_sys_date)    -- �K�p�I����
                          AND    fu.start_date             <= TRUNC(gd_sys_date)    -- �K�p�J�n��
                          AND  ((fu.end_date               IS NULL)                 -- �K�p�I����
                            OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                          AND    xilv.purchase_code         = papf.attribute4       -- �d����R�[�h
                          AND    xilv.segment1              = xilv2.frequent_whse_code  -- ���q�ɂ̍i����
                          AND    fu.user_id                 = gn_user_id            -- ���[�U�[ID
                          )
-- 2008/11/26 Mod ��
                      )
              )
             )
-- 2008/09/02 Mod ��
/*
-- �\�[�g��
      ORDER BY pha.attribute4                                      -- ���ɓ�
              ,xvv1.segment1                                       -- �����R�[�h
              ,pha.attribute5                                      -- �q�ɃR�[�h
              ,DECODE(pha.attribute6,gv_drop_ship_type_ship,
                      pha.attribute7,NULL)                         -- �z����R�[�h
              ,pha.segment1                                        -- �˗�No.
              ,pla.line_num                                        -- ����No.
              ,ximv.item_no                                        -- �i�ڃR�[�h
              ,pla.attribute3                                      -- �t�уR�[�h
              ,DECODE(ximv.lot_ctl,gv_lot_ctl_on,
                      pla.attribute1,NULL)                         -- ���b�g
              ,ilm.attribute1                                      -- ������
              ,ilm.attribute3                                      -- �ܖ�����
              ,ilm.attribute2                                      -- �ŗL�L��
*/
      UNION ALL
      SELECT xrart.rcv_rtn_number || '2' as sel_tbl_id      -- �e�[�u��ID
            ,gv_company_name as company_name                -- ��Ж�
            ,gv_data_class_pha as data_class                -- �f�[�^���
            ,NULL as ship_no                                -- �z��No.
            ,xrart.supply_requested_number as request_no    -- �˗�No.
            ,xrart.source_document_number as relation_no    -- �֘ANo.
            ,NULL as base_request_no                        -- �R�s�[��No.
            ,NULL as base_ship_no                           -- ���z��No.
            ,xvv.segment1 as vendor_code                    -- �����R�[�h
            ,xvv.vendor_full_name as vendor_name            -- ����於
            ,xvv.vendor_short_name as vendor_s_name         -- ����旪��
            ,DECODE(xrart.assen_vendor_id,NULL,
                    NULL,
                    xvv.segment1) as mediation_code         -- �����҃R�[�h
            ,DECODE(xrart.assen_vendor_id,NULL,
                    NULL,
                    xvv.vendor_full_name) as mediation_name -- �����Җ�
            ,DECODE(xrart.assen_vendor_id,NULL,
                    NULL,
                    xvv.segment1) as mediation_s_name       -- �����җ���
            ,xrart.location_code as whse_code               -- �q�ɃR�[�h
            ,xilv.description as whse_name                  -- �q�ɖ�
            ,xilv.short_name as whse_s_name                 -- �q�ɗ���
            ,DECODE(xrart.drop_ship_type,gv_drop_ship_type_ship,
                    xrart.delivery_code,
                    NULL) as vendor_site_code               -- �z����R�[�h
            ,DECODE(xrart.drop_ship_type,gv_drop_ship_type_ship,
                    xpsv.party_site_full_name,
                    NULL) as vendor_site_name               -- �z���於
            ,DECODE(xrart.drop_ship_type,gv_drop_ship_type_ship,
                    xpsv.party_site_short_name,
                    NULL) as vendor_site_s_name             -- �z���旪��
            ,DECODE(xrart.drop_ship_type,gv_drop_ship_type_ship,
                    xpsv.zip,
                    NULL) as zip                            -- �X�֔ԍ�
            ,DECODE(xrart.drop_ship_type,gv_drop_ship_type_ship,
                    xpsv.address_line1||xpsv.address_line2,
                    NULL) as address                        -- �Z��
            ,DECODE(xrart.drop_ship_type,gv_drop_ship_type_ship,
                    xpsv.phone,
                    NULL) as phone                          -- �d�b�ԍ�
            ,NULL as carrier_code                           -- �^���Ǝ҃R�[�h
            ,NULL as carrier_name                           -- �^���ƎҖ�
            ,NULL as carrier_s_name                         -- �^���Ǝҗ���
            ,TO_CHAR(xrart.txns_date,'YYYY/MM/DD') as ship_date                   -- �o�ɓ�
            ,TO_CHAR(xrart.txns_date,'YYYY/MM/DD') as arrival_dat                 -- ���ɓ�
            ,NULL as arrival_time_from                      -- ���׎���FROM
            ,NULL as arrival_time_to                        -- ���׎���TO
            ,NULL as method_code                            -- �z���敪
            ,NULL as div_a                                  -- �敪�`
            ,xrart.drop_ship_type as div_b                  -- �敪�a
            ,NULL as div_c                                  -- �敪�b
            ,xrart.department_code as instruction_dept      -- �w�������R�[�h
            ,NULL as request_dept                           -- �˗������R�[�h
            ,NULL as status                                 -- �X�e�[�^�X
            ,NULL as notif_status                           -- �ʒm�X�e�[�^�X
            ,xrart.txns_type as div_d                       -- �敪�c
            ,NULL as div_e                                  -- �敪�d
            ,NULL as div_f                                  -- �敪�e
            ,NULL as div_g                                  -- �敪�f
            ,NULL as div_h                                  -- �敪�g
            ,NULL as info_a                                 -- ���`
            ,NULL as info_b                                 -- ���a
            ,NULL as info_c                                 -- ���b
            ,NULL as info_d                                 -- ���c
            ,NULL as info_e                                 -- ���d
            ,xrart.header_description as head_description   -- �E�v(�w�b�_)
            ,xrart.line_description as line_description     -- �E�v(����)
            ,xrart.rcv_rtn_line_number as line_num          -- ����No.
            ,ximv.item_no                                   -- �i�ڃR�[�h
            ,ximv.item_name                                 -- �i�ږ�
            ,ximv.item_short_name as item_s_name            -- �i�ڗ���
            ,xrart.futai_code                               -- �t��
            ,DECODE(ximv.lot_ctl,gv_lot_ctl_on, 
                    xrart.lot_number,
                    NULL) as lot_no                         -- ���b�gNo.
            ,ilm.attribute1 as lot_date                     -- ������
            ,ilm.attribute3 as best_bfr_date                -- �ܖ�����
            ,ilm.attribute2 as lot_sign                     -- �ŗL�L��
            ,TO_CHAR(xrart.rcv_rtn_quantity) as request_qty          -- �˗���
            ,TO_CHAR(xrart.rcv_rtn_quantity) as instruct_qty         -- �w����
            ,TO_CHAR(xrart.rcv_rtn_quantity) as num_of_deliver       -- �o�ɐ�
            ,TO_CHAR(xrart.rcv_rtn_quantity) as ship_to_qty          -- ���ɐ�
            ,TO_CHAR(xrart.rcv_rtn_quantity) as fix_qty              -- �m�萔
            ,xrart.rcv_rtn_uom as item_um                   -- �P��
            ,NULL as weight_capacity                        -- �d�ʗe��
            ,TO_CHAR(xrart.conversion_factor) as frequent_qty        -- ����
            ,xrart.factory_code as frequent_factory         -- �H��R�[�h
            ,NULL as div_i                                  -- �敪�h
            ,NULL as div_j                                  -- �敪�i
            ,NULL as div_k                                  -- �敪�j
            ,NULL as designate_date                         -- ���t�w��
            ,ilm.attribute11 as info_f                      -- ���e
            ,ilm.attribute12 as info_g                      -- ���f
            ,ilm.attribute14 as info_h                      -- ���g
            ,ilm.attribute15 as info_i                      -- ���h
            ,ilm.attribute19 as info_j                      -- ���i
            ,ilm.attribute20 as info_k                      -- ���j
            ,ilm.attribute21 as info_l                      -- ���k
            ,NULL as info_m                                 -- ���l
            ,NULL as info_n                                 -- ���m
            ,ilm.attribute9 as info_o                       -- ���n
            ,ilm.attribute10 as info_p                      -- ���o
            ,ilm.attribute13 as info_q                      -- ���p
            ,xrart.unit_price as amt_a                      -- �����`
            ,TO_CHAR(xrart.kobiki_rate) as amt_b                     -- �����a
            ,TO_CHAR(xrart.kobki_converted_unit_price) as amt_c      -- �����b
            ,xrart.kousen_type as amt_d                     -- �����c
            ,TO_CHAR(xrart.kousen_rate_or_unit_price) as amt_e       -- �����d
            ,TO_CHAR(xrart.kousen_price) as amt_f                    -- �����e
            ,xrart.fukakin_type as amt_g                    -- �����f
            ,TO_CHAR(xrart.fukakin_rate_or_unit_price) as amt_h      -- �����g
            ,TO_CHAR(xrart.fukakin_price) as amt_i                   -- �����h
            ,TO_CHAR(xrart.kobki_converted_price) as amt_j           -- �����i
            ,xrart.last_update_date as update_date_h        -- �ŏI�X�V��(�w�b�_)
            ,xrart.last_update_date as update_date_l        -- �ŏI�X�V��(����)
      FROM   xxpo_rcv_and_rtn_txns    xrart  -- ����ԕi����(�A�h�I��)
            ,xxcmn_vendors2_v         xvv    -- �d������VIEW
            ,xxcmn_item_locations2_v  xilv   -- OPM�ۊǏꏊ���VIEW
            ,xxcmn_party_sites2_v     xpsv   -- �p�[�e�B�T�C�g���VIEW
            ,xxcmn_item_mst2_v        ximv   -- OPM�i�ڏ��VIEW
            ,xxcmn_item_categories4_v xicv   -- OPM�i�ڃJ�e�S���������VIEW4
            ,ic_lots_mst              ilm    -- OPM���b�g�}�X�^
      WHERE  xrart.vendor_id       = xvv.vendor_id             -- �����ID
      AND    xrart.vendor_code     = xvv.segment1              -- �����R�[�h
      AND    xrart.assen_vendor_id = xvv.vendor_id(+)          -- �d����ID
      AND    xrart.location_code   = xilv.segment1             -- ���o�ɐ�R�[�h
      AND    xrart.delivery_code   = xpsv.ship_to_no(+)        -- �z����R�[�h
      AND    xrart.item_id         = ximv.item_id              -- �i��ID
      AND    xrart.lot_id          = ilm.lot_id                -- ���b�gID
      AND    xrart.item_id         = ilm.item_id               -- �i��ID
      AND    ximv.item_id          = xicv.item_id
-- �˗�No
      AND    ((gv_req_no_from IS NULL) OR (xrart.supply_requested_number >= gv_req_no_from))
      AND    ((gv_req_no_to IS NULL)   OR (xrart.supply_requested_number <= gv_req_no_to))
-- �����
      AND    ((gv_vendor_code IS NULL) OR (xvv.segment1 = gv_vendor_code))
-- ������
      AND    ((gv_mediation IS NULL) OR (xrart.assen_vendor_code = gv_mediation))
-- ���ɑq��
      AND    ((gv_arvl_code IS NULL) OR (xrart.location_code = gv_arvl_code))
-- �[����(�K�{)
      AND    xrart.txns_date >= FND_DATE.STRING_TO_DATE(gv_ship_date_from,'YYYY/MM/DD')
      AND    xrart.txns_date <= FND_DATE.STRING_TO_DATE(gv_ship_date_to,'YYYY/MM/DD')
-- �w������
      AND    ((gv_instruction_dept IS NULL) OR (xrart.department_code = gv_instruction_dept))
-- �i��
      AND    ((gv_item_no IS NULL) OR (xrart.item_code = gv_item_no))
-- �X�V����
      AND    ((gd_update_time_from IS NULL) OR (xrart.last_update_date >= gd_update_time_from))
      AND    ((gd_update_time_to IS NULL)   OR (xrart.last_update_date <= gd_update_time_to))
      AND    ((gd_update_time_from IS NULL) OR (xrart.last_update_date >= gd_update_time_from))
      AND    ((gd_update_time_to IS NULL)   OR (xrart.last_update_date <= gd_update_time_to))
-- ���i�敪
      AND    ((gv_prod_class IS NULL) OR (xicv.prod_class_code   = gv_prod_class))
-- �i�ڋ敪
      AND    ((gv_item_class IS NULL) OR (xicv.item_class_code   = gv_item_class))
-- OPM�i�ڏ��VIEW2
      AND     xrart.txns_date BETWEEN ximv.start_date_active AND ximv.end_date_active
-- OPM�ۊǏꏊ���VIEW2
      AND     xilv.date_from <= xrart.txns_date
      AND     (xilv.date_to >= xrart.txns_date OR xilv.date_to IS NULL)
      AND     xilv.disable_date IS NULL
-- �d������VIEW2
      AND     xvv.inactive_date IS NULL
      AND     xrart.txns_date 
      BETWEEN NVL(xvv.start_date_active,FND_DATE.STRING_TO_DATE(gv_min_date,'YYYY/MM/DD'))
      AND     NVL(xvv.end_date_active,FND_DATE.STRING_TO_DATE(gv_max_date,'YYYY/MM/DD'))
-- �p�[�e�B�T�C�g���VIEW2
      AND     NVL(xpsv.party_site_status,gv_status_on) = gv_status_on
      AND     NVL(xpsv.cust_acct_site_status,gv_status_on) = gv_status_on
      AND     NVL(xpsv.cust_site_uses_status,gv_status_on) = gv_status_on
      AND     xrart.txns_date 
      BETWEEN NVL(xpsv.start_date_active,FND_DATE.STRING_TO_DATE(gv_min_date,'YYYY/MM/DD'))
      AND     NVL(xpsv.end_date_active,FND_DATE.STRING_TO_DATE(gv_max_date,'YYYY/MM/DD'))
-- �Z�L�����e�B�敪
      AND    (
-- �ɓ������[�U�[�^�C�v
              (gv_sec_class = gv_sec_class_home)
-- ����惆�[�U�[�^�C�v
       OR     (gv_sec_class = gv_sec_class_vend
               AND    xvv.segment1 IN
                 (SELECT papf.attribute4           -- �����R�[�h(�d����R�[�h)
                  FROM   fnd_user           fu              -- ���[�U�[�}�X�^
                        ,per_all_people_f   papf            -- �]�ƈ��}�X�^
                  WHERE  fu.employee_id   = papf.person_id                   -- �]�ƈ�ID
                  AND    papf.effective_start_date <= TRUNC(gd_sys_date)     -- �K�p�J�n��
                  AND    papf.effective_end_date   >= TRUNC(gd_sys_date)     -- �K�p�I����
                  AND    fu.start_date             <= TRUNC(gd_sys_date)     -- �K�p�J�n��
                  AND  ((fu.end_date               IS NULL)                  -- �K�p�I����
                    OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                  AND    fu.user_id                 = gn_user_id)            -- ���[�U�[ID
              )
-- �O���q�Ƀ��[�U�[�^�C�v
       OR     (gv_sec_class = gv_sec_class_extn
               AND    xrart.location_code IN
                 (SELECT xilv.segment1                -- �ۊǑq�ɃR�[�h
                  FROM   fnd_user               fu          -- ���[�U�[�}�X�^
                        ,per_all_people_f       papf        -- �]�ƈ��}�X�^
                        ,xxcmn_item_locations_v xilv        -- OPM�ۊǏꏊ���VIEW
                  WHERE  fu.employee_id             = papf.person_id         -- �]�ƈ�ID
                  AND    papf.effective_start_date <= TRUNC(gd_sys_date)     -- �K�p�J�n��
                  AND    papf.effective_end_date   >= TRUNC(gd_sys_date)     -- �K�p�I����
                  AND    fu.start_date             <= TRUNC(gd_sys_date)     -- �K�p�J�n��
                  AND  ((fu.end_date               IS NULL)                  -- �K�p�I����
                    OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                  AND    xilv.purchase_code         = papf.attribute4        -- �d����R�[�h
                  AND    fu.user_id                 = gn_user_id)            -- ���[�U�[ID
              )
-- ���m�u�����[�U�[�^�C�v
       OR     (gv_sec_class = gv_sec_class_quay
               AND    (
                       xrart.location_code IN (
                          SELECT xilv.segment1                -- �ۊǑq�ɃR�[�h
                          FROM   fnd_user               fu          -- ���[�U�[�}�X�^
                                ,per_all_people_f       papf        -- �]�ƈ��}�X�^
                                ,xxcmn_item_locations_v xilv        -- OPM�ۊǏꏊ���VIEW
                          WHERE  fu.employee_id             = papf.person_id        -- �]�ƈ�ID
                          AND    papf.effective_start_date <= TRUNC(gd_sys_date)    -- �K�p�J�n��
                          AND    papf.effective_end_date   >= TRUNC(gd_sys_date)    -- �K�p�I����
                          AND    fu.start_date             <= TRUNC(gd_sys_date)    -- �K�p�J�n��
                          AND  ((fu.end_date               IS NULL)                 -- �K�p�I����
                            OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                          AND    xilv.purchase_code         = papf.attribute4       -- �d����R�[�h
                          AND    fu.user_id                 = gn_user_id            -- ���[�U�[ID
                          )
               OR      xrart.location_code IN (
-- 2008/11/26 Mod ��
--                          SELECT xilv.frequent_whse_code      -- ��Ǒq��
                          SELECT xilv2.segment1       -- ���m�u���q�q��
                          FROM   fnd_user               fu          -- ���[�U�[�}�X�^
                                ,per_all_people_f       papf        -- �]�ƈ��}�X�^
                                ,xxcmn_item_locations_v xilv        -- OPM�ۊǏꏊ���VIEW
                                ,xxcmn_item_locations_v xilv2       -- OPM�ۊǏꏊ���VIEW
                          WHERE  fu.employee_id             = papf.person_id        -- �]�ƈ�ID
                          AND    papf.effective_start_date <= TRUNC(gd_sys_date)    -- �K�p�J�n��
                          AND    papf.effective_end_date   >= TRUNC(gd_sys_date)    -- �K�p�I����
                          AND    fu.start_date             <= TRUNC(gd_sys_date)    -- �K�p�J�n��
                          AND  ((fu.end_date               IS NULL)                 -- �K�p�I����
                            OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                          AND    xilv.purchase_code         = papf.attribute4       -- �d����R�[�h
                          AND    xilv.segment1              = xilv2.frequent_whse_code   -- �q�q�ɂ̍i����
                          AND    fu.user_id                 = gn_user_id            -- ���[�U�[ID
                          )
-- 2008/11/26 Mod ��
                      )
              )
             )
-- �\�[�g��
      ORDER BY 27,                   -- ���ɓ�
               9,                    -- �����R�[�h
               15,                   -- �q�ɃR�[�h
               18,                   -- �z����R�[�h
               5,                    -- �˗�No.
               51,                   -- ����No.
               52,                   -- �i�ڃR�[�h
               55,                   -- �t�уR�[�h
               56,                   -- ���b�g
               57,                   -- ������
               58,                   -- �ܖ�����
               59                    -- �ŗL�L��
-- 2008/09/02 Mod ��
      ;
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    ln_cnt := 1;
--
    OPEN mst_data_cur;
--
    <<mst_data_loop>>
    LOOP
      FETCH mst_data_cur INTO lr_mst_data_rec;
      EXIT WHEN mst_data_cur%NOTFOUND;
--
      mst_rec.sel_tbl_id         := lr_mst_data_rec.sel_tbl_id;         -- �e�[�u��ID
      mst_rec.company_name       := lr_mst_data_rec.company_name;       -- ��Ж�
      mst_rec.data_class         := lr_mst_data_rec.data_class;         -- �f�[�^���
      mst_rec.ship_no            := lr_mst_data_rec.ship_no;            -- �z��No.
      mst_rec.request_no         := lr_mst_data_rec.request_no;         -- �˗�No.
      mst_rec.relation_no        := lr_mst_data_rec.relation_no;        -- �֘ANo.
      mst_rec.base_request_no    := lr_mst_data_rec.base_request_no;    -- �R�s�[��No.   2008/09/02 Add
      mst_rec.base_ship_no       := lr_mst_data_rec.base_ship_no;       -- ���z��No.
      mst_rec.vendor_code        := lr_mst_data_rec.vendor_code;        -- �����R�[�h
      mst_rec.vendor_name        := lr_mst_data_rec.vendor_name;        -- ����於
      mst_rec.vendor_s_name      := lr_mst_data_rec.vendor_s_name;      -- ����旪��
      mst_rec.mediation_code     := lr_mst_data_rec.mediation_code;     -- �����҃R�[�h
      mst_rec.mediation_name     := lr_mst_data_rec.mediation_name;     -- �����Җ�
      mst_rec.mediation_s_name   := lr_mst_data_rec.mediation_s_name;   -- �����җ���
      mst_rec.whse_code          := lr_mst_data_rec.whse_code;          -- �q�ɃR�[�h
      mst_rec.whse_name          := lr_mst_data_rec.whse_name;          -- �q�ɖ�
      mst_rec.whse_s_name        := lr_mst_data_rec.whse_s_name;        -- �q�ɗ���
      mst_rec.vendor_site_code   := lr_mst_data_rec.vendor_site_code;   -- �z����R�[�h
      mst_rec.vendor_site_name   := lr_mst_data_rec.vendor_site_name;   -- �z���於
      mst_rec.vendor_site_s_name := lr_mst_data_rec.vendor_site_s_name; -- �z���旪��
      mst_rec.zip                := lr_mst_data_rec.zip;                -- �X�֔ԍ�
      mst_rec.address            := lr_mst_data_rec.address;            -- �Z��
      mst_rec.phone              := lr_mst_data_rec.phone;              -- �d�b�ԍ�
      mst_rec.carrier_code       := lr_mst_data_rec.carrier_code;       -- �^���Ǝ҃R�[�h
      mst_rec.carrier_name       := lr_mst_data_rec.carrier_name;       -- �^���ƎҖ�
      mst_rec.carrier_s_name     := lr_mst_data_rec.carrier_s_name;     -- �^���Ǝҗ���
      mst_rec.v_ship_date        := lr_mst_data_rec.ship_date;          -- �o�ɓ�
      mst_rec.v_arrival_date     := lr_mst_data_rec.arrival_date;       -- ���ɓ�
      mst_rec.arrival_time_from  := lr_mst_data_rec.arrival_time_from;  -- ���׎���FROM
      mst_rec.arrival_time_to    := lr_mst_data_rec.arrival_time_to;    -- ���׎���TO
      mst_rec.method_code        := lr_mst_data_rec.method_code;        -- �z���敪
      mst_rec.div_a              := lr_mst_data_rec.div_a;              -- �敪�`
      mst_rec.div_b              := lr_mst_data_rec.div_b;              -- �敪�a
      mst_rec.div_c              := lr_mst_data_rec.div_c;              -- �敪�b
      mst_rec.instruction_dept   := lr_mst_data_rec.instruction_dept;   -- �w�������R�[�h
      mst_rec.request_dept       := lr_mst_data_rec.request_dept;       -- �˗������R�[�h
      mst_rec.status             := lr_mst_data_rec.status;             -- �X�e�[�^�X
      mst_rec.notif_status       := lr_mst_data_rec.notif_status;       -- �ʒm�X�e�[�^�X
      mst_rec.div_d              := lr_mst_data_rec.div_d;              -- �敪�c
      mst_rec.div_e              := lr_mst_data_rec.div_e;              -- �敪�d
      mst_rec.div_f              := lr_mst_data_rec.div_f;              -- �敪�e
      mst_rec.div_g              := lr_mst_data_rec.div_g;              -- �敪�f
      mst_rec.div_h              := lr_mst_data_rec.div_h;              -- �敪�g
      mst_rec.info_a             := lr_mst_data_rec.info_a;             -- ���`
      mst_rec.info_b             := lr_mst_data_rec.info_b;             -- ���a
      mst_rec.info_c             := lr_mst_data_rec.info_c;             -- ���b
      mst_rec.info_d             := lr_mst_data_rec.info_d;             -- ���c
      mst_rec.info_e             := lr_mst_data_rec.info_e;             -- ���d
      mst_rec.head_description   := lr_mst_data_rec.head_description;   -- �E�v(�w�b�_)
      mst_rec.line_description   := lr_mst_data_rec.line_description;   -- �E�v(����)
      mst_rec.line_num           := lr_mst_data_rec.line_num;           -- ����No.
      mst_rec.item_no            := lr_mst_data_rec.item_no;            -- �i�ڃR�[�h
      mst_rec.item_name          := lr_mst_data_rec.item_name;          -- �i�ږ�
      mst_rec.item_s_name        := lr_mst_data_rec.item_s_name;        -- �i�ڗ���
      mst_rec.futai_code         := lr_mst_data_rec.futai_code;         -- �t��
      mst_rec.lot_no             := lr_mst_data_rec.lot_no;             -- ���b�gNo
      mst_rec.v_lot_date         := lr_mst_data_rec.lot_date;           -- ������
      mst_rec.v_best_bfr_date    := lr_mst_data_rec.best_bfr_date;      -- �ܖ�����
      mst_rec.lot_sign           := SUBSTR(lr_mst_data_rec.lot_sign,1,6); -- �ŗL�L��
      mst_rec.request_qty        := TO_NUMBER(lr_mst_data_rec.request_qty);        -- �˗���
      mst_rec.instruct_qty       := TO_NUMBER(lr_mst_data_rec.instruct_qty);       -- �w����
      mst_rec.num_of_deliver     := TO_NUMBER(lr_mst_data_rec.num_of_deliver);     -- �o�ɐ�
      mst_rec.ship_to_qty        := TO_NUMBER(lr_mst_data_rec.ship_to_qty);        -- ���ɐ�
      mst_rec.fix_qty            := TO_NUMBER(lr_mst_data_rec.fix_qty);            -- �m�萔
      mst_rec.item_um            := SUBSTR(lr_mst_data_rec.item_um,1,3);  -- �P��
      mst_rec.weight_capacity    := TO_NUMBER(lr_mst_data_rec.weight_capacity);    -- �d�ʗe��
      mst_rec.frequent_qty       := TO_NUMBER(lr_mst_data_rec.frequent_qty);       -- ����
      mst_rec.frequent_factory   := SUBSTR(lr_mst_data_rec.frequent_factory,1,4); -- �H��R�[�h
      mst_rec.div_i              := SUBSTR(lr_mst_data_rec.div_i,1,1);  -- �敪�h
      mst_rec.div_j              := SUBSTR(lr_mst_data_rec.div_j,1,1);  -- �敪�i
      mst_rec.div_k              := lr_mst_data_rec.div_k;              -- �敪�j
      mst_rec.v_designate_date   := lr_mst_data_rec.designate_date;     -- ���t�w��
/* 2008/08/20 Mod ��
      mst_rec.amt_a              := lr_mst_data_rec.amt_a;              -- �����`
2008/08/20 Mod �� */
      mst_rec.update_date_h      := lr_mst_data_rec.update_date_h;      -- �ŏI�X�V��(�w�b�_)
      mst_rec.update_date_l      := lr_mst_data_rec.update_date_l;      -- �ŏI�X�V��(����)
--
      -- �ɓ������[�U�[�A����惆�[�U�[
      IF (gv_sec_class IN (gv_sec_class_home,gv_sec_class_vend)) THEN
        mst_rec.info_f             := SUBSTR(lr_mst_data_rec.info_f,1,4);  -- ���e
        mst_rec.info_g             := SUBSTR(lr_mst_data_rec.info_g,1,2);  -- ���f
        mst_rec.info_h             := SUBSTR(lr_mst_data_rec.info_h,1,10); -- ���g
        mst_rec.info_i             := SUBSTR(lr_mst_data_rec.info_i,1,10); -- ���h
        mst_rec.info_j             := SUBSTR(lr_mst_data_rec.info_j,1,10); -- ���i
        mst_rec.info_k             := SUBSTR(lr_mst_data_rec.info_k,1,10); -- ���j
        mst_rec.info_l             := SUBSTR(lr_mst_data_rec.info_l,1,10); -- ���k
        mst_rec.info_m             := SUBSTR(lr_mst_data_rec.info_m,1,7);  -- ���l
        mst_rec.info_n             := SUBSTR(lr_mst_data_rec.info_n,1,10); -- ���m
        mst_rec.info_o             := SUBSTR(lr_mst_data_rec.info_o,1,2);  -- ���n
        mst_rec.info_p             := SUBSTR(lr_mst_data_rec.info_p,1,2);  -- ���o
        mst_rec.info_q             := SUBSTR(lr_mst_data_rec.info_q,1,2);  -- ���p
        mst_rec.amt_a              := SUBSTR(lr_mst_data_rec.amt_a,1,20);  -- �����` 2008/08/20 Mod
        mst_rec.amt_b              := SUBSTR(lr_mst_data_rec.amt_b,1,20);  -- �����a
        mst_rec.amt_c              := SUBSTR(lr_mst_data_rec.amt_c,1,20);  -- �����b
        mst_rec.amt_d              := SUBSTR(lr_mst_data_rec.amt_d,1,20);  -- �����c
        mst_rec.amt_e              := SUBSTR(lr_mst_data_rec.amt_e,1,20);  -- �����d
        mst_rec.amt_f              := SUBSTR(lr_mst_data_rec.amt_f,1,20);  -- �����e
        mst_rec.amt_g              := SUBSTR(lr_mst_data_rec.amt_g,1,20);  -- �����f
        mst_rec.amt_h              := SUBSTR(lr_mst_data_rec.amt_h,1,20);  -- �����g
        mst_rec.amt_i              := SUBSTR(lr_mst_data_rec.amt_i,1,20);  -- �����h
        mst_rec.amt_j              := SUBSTR(lr_mst_data_rec.amt_j,1,20);  -- �����i
--
      ELSE
        mst_rec.info_f             := NULL;              -- ���e
        mst_rec.info_g             := NULL;              -- ���f
        mst_rec.info_h             := NULL;              -- ���g
        mst_rec.info_i             := NULL;              -- ���h
        mst_rec.info_j             := NULL;              -- ���i
        mst_rec.info_k             := NULL;              -- ���j
        mst_rec.info_l             := NULL;              -- ���k
        mst_rec.info_m             := NULL;              -- ���l
        mst_rec.info_n             := NULL;              -- ���m
        mst_rec.info_o             := NULL;              -- ���n
        mst_rec.info_p             := NULL;              -- ���o
        mst_rec.info_q             := NULL;              -- ���p
        mst_rec.amt_a              := NULL;              -- �����` 2008/08/20 Mod
        mst_rec.amt_b              := NULL;              -- �����a
        mst_rec.amt_c              := NULL;              -- �����b
        mst_rec.amt_d              := NULL;              -- �����c
        mst_rec.amt_e              := NULL;              -- �����d
        mst_rec.amt_f              := NULL;              -- �����e
        mst_rec.amt_g              := NULL;              -- �����f
        mst_rec.amt_h              := NULL;              -- �����g
        mst_rec.amt_i              := NULL;              -- �����h
        mst_rec.amt_j              := NULL;              -- �����i
      END IF;
--
      -- ���l�A���t�𕶎���ɕϊ�����
      mst_rec.v_update_date_h := TO_CHAR(mst_rec.update_date_h,'YYYY/MM/DD HH24:MI:SS');
      mst_rec.v_update_date_l := TO_CHAR(mst_rec.update_date_l,'YYYY/MM/DD HH24:MI:SS');
--
      gt_master_tbl(ln_cnt) := mst_rec;
      ln_cnt := ln_cnt + 1;
--
    END LOOP mst_data_loop;
--
    CLOSE mst_data_cur;
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
      -- �J�[�\�����J���Ă����
      IF (mst_data_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE mst_data_cur;
      END IF;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (mst_data_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE mst_data_cur;
      END IF;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (mst_data_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE mst_data_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END pha_sel_proc;
--
  /**********************************************************************************
   * Procedure Name   : oha_sel_proc
   * Description      : �x����񌟍�����(D-4)
   ***********************************************************************************/
  PROCEDURE oha_sel_proc(
    ov_errbuf           OUT NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'oha_sel_proc'; -- �v���O������
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
    mst_rec         masters_rec;
    ln_cnt          NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR mst_data_cur
    IS
      SELECT xoha.order_header_id as sel_tbl_id                -- �e�[�u��ID
            ,gv_company_name as company_name                   -- ��Ж�
            ,gv_data_class_oha as data_class                   -- �f�[�^���
            ,xoha.delivery_no as ship_no                       -- �z��No.
            ,xoha.request_no                                   -- �˗�No.
            ,DECODE(xotv.transaction_type_name,gv_transaction_type_name,
                    xoha.po_no,
                    NULL) as relation_no                       -- �֘ANo.
            ,xoha.base_request_no                              -- �R�s�[��No.    2008/09/02 Add
            ,xoha.prev_delivery_no as base_ship_no             -- ���z��No.
            ,xoha.vendor_code                                  -- �����R�[�h
            ,xvv.vendor_full_name as vendor_name               -- ����於
            ,xvv.vendor_short_name as vendor_s_name            -- ����旪��
            ,NULL as mediation_code                            -- �����҃R�[�h
            ,NULL as mediation_name                            -- �����Җ�
            ,NULL as mediation_s_name                          -- �����җ���
            ,xoha.deliver_from as whse_code                    -- �q�ɃR�[�h
            ,xilv.whse_name as whse_name                       -- �q�ɖ�
            ,xilv.short_name as whse_s_name                    -- �q�ɗ���
            ,xoha.vendor_site_code                             -- �z����R�[�h
            ,xvsv.vendor_site_name                             -- �z���於
            ,xvsv.vendor_site_short_name as vendor_site_s_name -- �z���旪��
            ,xvsv.zip                                          -- �X�֔ԍ�
            ,xvsv.address_line1||xvsv.address_line2 as address -- �Z��
            ,xvsv.phone                                        -- �d�b�ԍ�
            ,NVL(xoha.result_freight_carrier_code,
                 xoha.freight_carrier_code) as carrier_code    -- �^���Ǝ҃R�[�h
            ,xcv.party_name as carrier_name                    -- �^���ƎҖ�
            ,xcv.party_short_name as carrier_s_name            -- �^���Ǝҗ���
            ,NVL(xoha.shipped_date,
                 xoha.schedule_ship_date) as ship_date         -- �o�ɓ�(YYYY/MM/DD)
            ,NVL(xoha.arrival_date,
                 xoha.schedule_arrival_date) as arrival_date   -- ���ɓ�(YYYY/MM/DD)
            ,xoha.arrival_time_from                            -- ���׎���FROM
            ,xoha.arrival_time_to                              -- ���׎���TO
            ,NVL(xoha.result_shipping_method_code,
                 xoha.shipping_method_code) as method_code     -- �z���敪
            ,xoha.freight_charge_class as div_a                -- �敪�`
            ,xoha.takeback_class as div_b                      -- �敪�a
            ,xoha.weight_capacity_class as div_c               -- �敪�b
            ,xoha.instruction_dept                             -- �w�������R�[�h
            ,xoha.performance_management_dept as request_dept  -- �˗������R�[�h
            ,xoha.req_status as status                         -- �X�e�[�^�X
            ,xoha.notif_status                                 -- �ʒm�X�e�[�^�X
            ,xotv.transaction_type_name as div_d               -- �敪�c
            ,NULL as div_e                                     -- �敪�d
            ,NULL as div_f                                     -- �敪�e
            ,NULL as div_g                                     -- �敪�f
            ,xoha.new_modify_flg as div_h                      -- �敪�g
            ,xoha.designated_production_date as info_a         -- ���`(������)
            ,xoha.designated_item_code as info_b               -- ���a(�����i�ڃR�[�h)
            ,ximv2.item_name as info_c                         -- ���b(�����i�ږ�)
            ,ximv2.item_short_name as info_d                   -- ���c(�����i�ڗ���)
            ,xoha.designated_branch_no as info_e               -- ���d(�����ԍ�)
            ,xoha.shipping_instructions as head_description    -- �E�v(�w�b�_)
            ,xola.line_description                             -- �E�v(����)
            ,NULL as line_num                                  -- ����No.
            ,xola.shipping_item_code as item_no                -- �i�ڃR�[�h
            ,ximv1.item_name                                   -- �i�ږ�
            ,ximv1.item_short_name as item_s_name              -- �i�ڗ���
            ,xola.futai_code                                   -- �t��
            ,xmldv.lot_no                                      -- ���b�gNo
            ,xmldv.lot_date                                    -- ������
            ,xmldv.best_bfr_date                               -- �ܖ�����
            ,xmldv.lot_sign                                    -- �ŗL�L��
            ,xola.based_request_quantity as request_qty        -- �˗���
-- 2008/08/20 Mod ��
/*
            ,xmldv.instruct_qty                                -- �w����
            ,xmldv.num_of_deliver                              -- �o�ɐ�
            ,xmldv.ship_to_qty                                 -- ���ɐ�
            ,xmldv.fix_qty                                     -- �m�萔
*/
            ,DECODE(xmldv.lot_no,NULL,
                    xola.quantity,
                    xmldv.instruct_qty
                   ) as instruct_qty                           -- �w����
            ,DECODE(xmldv.lot_no,NULL,
                    xola.shipped_quantity,
                    xmldv.num_of_deliver
                   ) as num_of_deliver                         -- �o�ɐ�
            ,DECODE(xmldv.lot_no,NULL,
                    xola.ship_to_quantity,
                    xmldv.ship_to_qty
                   ) as ship_to_qty                            -- ���ɐ�
            ,DECODE(xmldv.lot_no,NULL,
                    xola.shipped_quantity,
                    xmldv.fix_qty
                   ) as fix_qty                                -- �m�萔
-- 2008/08/20 Mod ��
            ,xola.uom_code as item_um                          -- �P��
            ,DECODE(xoha.weight_capacity_class,
                    gv_weight_class,  xola.weight,
                    gv_capacity_class,xola.capacity,
                    NULL) as weight_capacity                   -- �d�ʗe��
            ,DECODE(ximv1.lot_ctl,gv_lot_ctl_on,
                    xmldv.frequent_qty,
                    NULL
                   ) as frequent_qty                           -- ����
            ,NULL as frequent_factory                          -- �H��R�[�h
            ,NULL as div_i                                     -- �敪�h
            ,NULL as div_j                                     -- �敪�i
-- 2008/08/20 Mod ��
/*
            ,NULL as div_k                                     -- �敪�j
*/
            ,xola.delete_flag as div_k                         -- �敪�j
-- 2008/08/20 Mod ��
            ,NULL as designate_date                            -- ���t�w��
            ,NULL as info_f                                    -- ���e
            ,NULL as info_g                                    -- ���f
            ,NULL as info_h                                    -- ���g
            ,NULL as info_i                                    -- ���h
            ,NULL as info_j                                    -- ���i
            ,NULL as info_k                                    -- ���j
            ,NULL as info_l                                    -- ���k
            ,NULL as info_m                                    -- ���l
            ,NULL as info_n                                    -- ���m
            ,NULL as info_o                                    -- ���n
            ,NULL as info_p                                    -- ���o
            ,NULL as info_q                                    -- ���p
            ,xola.unit_price as amt_a                          -- �����`
            ,NULL as amt_b                                     -- �����a
            ,NULL as amt_c                                     -- �����b
            ,NULL as amt_d                                     -- �����c
            ,NULL as amt_e                                     -- �����d
            ,NULL as amt_f                                     -- �����e
            ,NULL as amt_g                                     -- �����f
            ,NULL as amt_h                                     -- �����g
            ,NULL as amt_i                                     -- �����h
            ,NULL as amt_j                                     -- �����i
            ,xoha.last_update_date as update_date_h            -- �X�V����(�w�b�_)
            ,xola.last_update_date as update_date_l            -- �X�V����(����)
      FROM   xxwsh_order_headers_all       xoha   -- �󒍃w�b�_�A�h�I��
            ,xxwsh_order_lines_all         xola   -- �󒍖��׃A�h�I��
            ,(
              SELECT xmld.mov_line_id
                    ,xmld.lot_id
                    ,xmld.item_id
                    ,ilm.attribute1 as lot_date                        -- ������
                    ,ilm.attribute3 as best_bfr_date                   -- �ܖ�����
                    ,ilm.attribute2 as lot_sign                        -- �ŗL�L��
                    ,ilm.attribute6 as frequent_qty                    -- ����
                    ,DECODE(ximv.lot_ctl,gv_lot_ctl_on,
                            ilm.lot_no,
                            NULL) as lot_no                            -- ���b�gNo
-- 2008/08/20 Mod ��
/*
                    ,SUM(DECODE(xmld.document_type_code,gv_document_type_code_30,
                            DECODE(xmld.record_type_code,gv_record_type_code_10,
                                   xmld.actual_quantity
                                   ,0)
                           ,0)) as instruct_qty                         -- �w����
                    ,SUM(DECODE(xmld.document_type_code,gv_document_type_code_30,
                            DECODE(xmld.record_type_code,gv_record_type_code_20,
                                   xmld.actual_quantity
                                   ,0)
                           ,0)) as num_of_deliver                       -- �o�ɐ�
                    ,SUM(DECODE(xmld.document_type_code,gv_document_type_code_30,
                            DECODE(xmld.record_type_code,gv_record_type_code_30,
                                   xmld.actual_quantity
                                   ,0)
                           ,0)) as ship_to_qty                          -- ���ɐ�
                    ,SUM(DECODE(xmld.document_type_code,gv_document_type_code_30,
                            DECODE(xmld.record_type_code,gv_record_type_code_20,
                                   xmld.actual_quantity
                                   ,0)
                           ,0)) as fix_qty                              -- �m�萔
*/
                    ,SUM(DECODE(xmld.document_type_code,gv_document_type_code_30,
                            DECODE(xmld.record_type_code,gv_record_type_code_10,
                                   xmld.actual_quantity
                                   ,NULL)
                           ,NULL)) as instruct_qty                     -- �w����
                    ,SUM(DECODE(xmld.document_type_code,gv_document_type_code_30,
                            DECODE(xmld.record_type_code,gv_record_type_code_20,
                                   xmld.actual_quantity
                                   ,NULL)
                           ,NULL)) as num_of_deliver                   -- �o�ɐ�
                    ,SUM(DECODE(xmld.document_type_code,gv_document_type_code_30,
                            DECODE(xmld.record_type_code,gv_record_type_code_30,
                                   xmld.actual_quantity
                                   ,NULL)
                           ,NULL)) as ship_to_qty                      -- ���ɐ�
                    ,SUM(DECODE(xmld.document_type_code,gv_document_type_code_30,
                            DECODE(xmld.record_type_code,gv_record_type_code_20,
                                   xmld.actual_quantity
                                   ,NULL)
                           ,NULL)) as fix_qty                          -- �m�萔
-- 2008/08/20 Mod ��
              FROM   xxinv_mov_lot_details         xmld   -- �ړ����b�g�ڍ�(�A�h�I��)
                    ,ic_lots_mst                   ilm    -- OPM���b�g�}�X�^
                    ,xxcmn_item_mst2_v             ximv   -- OPM�i�ڏ��VIEW2
              WHERE  xmld.lot_id          = ilm.lot_id(+)
              AND    xmld.item_id         = ilm.item_id(+)
              AND    xmld.item_id         = ximv.item_id
              GROUP BY xmld.mov_line_id
                      ,xmld.lot_id
                      ,xmld.item_id
                      ,ilm.lot_id
                      ,ilm.item_id
                      ,ilm.attribute1
                      ,ilm.attribute3
                      ,ilm.attribute2
                      ,ilm.attribute6
                      ,DECODE(ximv.lot_ctl,gv_lot_ctl_on,
                              ilm.lot_no,
                              NULL)
             ) xmldv
            ,xxcmn_vendors2_v              xvv    -- �d������VIEW2
            ,xxcmn_vendor_sites2_v         xvsv   -- �d����T�C�g���VIEW2
            ,xxcmn_item_locations2_v       xilv   -- OPM�ۊǏꏊ���VIEW2
            ,xxcmn_item_mst2_v             ximv1  -- OPM�i�ڏ��VIEW2
            ,xxcmn_item_mst2_v             ximv2  -- OPM�i�ڏ��VIEW2
            ,xxcmn_item_categories4_v      xicv   -- OPM�i�ڃJ�e�S���������VIEW4
            ,xxcmn_carriers2_v             xcv    -- �^���Ǝҏ��VIEW2
            ,xxcmn_lookup_values2_v        xlvv   -- �N�C�b�N�R�[�h���VIEW2
            ,xxwsh_oe_transaction_types2_v xotv   -- �󒍃^�C�v���VIEW2
      WHERE xoha.order_header_id            = xola.order_header_id
      AND   xoha.order_type_id              = xotv.transaction_type_id
      AND   xotv.shipping_shikyu_class      = gv_shipping_shikyu_class
      AND   xotv.ship_sikyu_rcv_pay_ctg     IN (gv_rcv_pay_ctg_05             -- �L���ԕi:'05'
                                               ,gv_rcv_pay_ctg_06)            -- �d���ԕi:'06'
      AND   xola.order_line_id              = xmldv.mov_line_id(+)
      AND   xola.shipping_inventory_item_id = ximv1.inventory_item_id
      AND   xoha.designated_item_id         = ximv2.inventory_item_id(+)
      AND   xlvv.lookup_code(+)             = NVL(xoha.result_shipping_method_code,
                                                  xoha.shipping_method_code)
      AND   xlvv.lookup_type(+)             = gv_ship_method
      AND   xoha.deliver_from               = xilv.segment1
      AND   xoha.vendor_site_id             = xvsv.vendor_site_id
      AND   xcv.party_number(+)             = NVL(xoha.result_freight_carrier_code,
                                                  xoha.freight_carrier_code)
      AND   xoha.vendor_id                  = xvv.vendor_id
      AND   xicv.item_id                    = ximv1.item_id
      AND   xoha.latest_external_flag       = gv_external_flag_on             -- �ŐV�t���O:'Y'
-- �X�e�[�^�X
      -- 2008/07/30 Mod ��
/*
      AND    NVL(xoha.req_status,gv_status_null) IN (
              gv_xxwsh_status_05            -- ���͊���:06
             ,gv_xxwsh_status_06            -- ��̍�:07
             ,gv_xxwsh_status_07            -- ���:99
             )
*/
      AND    NVL(xoha.req_status,gv_status_null) >= gv_xxwsh_status_05     -- ���͊���:06�ȍ~
      -- 2008/07/30 Mod ��
-- �z��No
      AND   ((gv_ship_no_from IS NULL) OR (xoha.delivery_no >= gv_ship_no_from))
      AND   ((gv_ship_no_to IS NULL)   OR (xoha.delivery_no <= gv_ship_no_to))
-- �˗�No
      AND   ((gv_req_no_from IS NULL) OR (xoha.request_no >= gv_req_no_from))
      AND   ((gv_req_no_to IS NULL)   OR (xoha.request_no <= gv_req_no_to))
-- �����
      AND   ((gv_vendor_code IS NULL) OR (xoha.vendor_code = gv_vendor_code))
-- �o�ɑq��
      AND   ((gv_location_code IS NULL) OR (xoha.deliver_from = gv_location_code))
-- �z����
      AND   ((gv_vendor_site_code IS NULL) OR (xoha.vendor_site_code = gv_vendor_site_code))
-- �^���Ǝ�
      AND   ((gv_carrier_code IS NULL) OR (xoha.freight_carrier_code = gv_carrier_code))
-- �[����/�o�ɓ�(�K�{)
      AND    NVL(xoha.shipped_date,xoha.schedule_ship_date) >= gd_ship_date_from
      AND    NVL(xoha.shipped_date,xoha.schedule_ship_date) <= gd_ship_date_to
-- ���ɓ�
      AND   ((gd_arrival_date_from IS NULL)
       OR    (NVL(xoha.arrival_date,xoha.schedule_arrival_date) >= gd_arrival_date_from))
      AND   ((gd_arrival_date_to IS NULL)
       OR    (NVL(xoha.arrival_date,xoha.schedule_arrival_date) <= gd_arrival_date_to))
-- �w������
      AND   ((gv_instruction_dept IS NULL) OR (xoha.instruction_dept = gv_instruction_dept))
-- �i��
      AND   ((gv_item_no IS NULL) OR (ximv1.item_no = gv_item_no))
-- �X�V����
      AND   ((gd_update_time_from IS NULL) OR (xoha.last_update_date >= gd_update_time_from))
      AND   ((gd_update_time_to IS NULL)   OR (xoha.last_update_date <= gd_update_time_to))
      AND   ((gd_update_time_from IS NULL) OR (xola.last_update_date >= gd_update_time_from))
      AND   ((gd_update_time_to IS NULL)   OR (xola.last_update_date <= gd_update_time_to))
-- ���i�敪
      AND   ((gv_prod_class IS NULL) OR (xicv.prod_class_code       = gv_prod_class))
-- �i�ڋ敪
      AND   ((gv_item_class IS NULL) OR (xicv.item_class_code       = gv_item_class))
-- �󒍃^�C�v���VIEW2
      AND   TRUNC(NVL(xoha.shipped_date,xoha.schedule_ship_date)) BETWEEN xotv.start_date_active
      AND   NVL(xotv.end_date_active,FND_DATE.STRING_TO_DATE(gv_max_date,'YYYY/MM/DD'))
-- �N�C�b�N�R�[�h���VIEW2
      AND   (xlvv.lookup_code IS NULL
       OR   ((xlvv.start_date_active <= TRUNC(NVL(xoha.shipped_date,xoha.schedule_ship_date))
       OR      xlvv.start_date_active IS NULL)
      AND    (xlvv.end_date_active >= TRUNC(NVL(xoha.shipped_date,xoha.schedule_ship_date))
       OR      xlvv.end_date_active IS NULL)
      AND     xlvv.enabled_flag = gv_enabled_flag_on))
-- OPM�i�ڏ��VIEW(1)
      AND    TRUNC(NVL(xoha.shipped_date,xoha.schedule_ship_date)) BETWEEN ximv1.start_date_active
      AND    ximv1.end_date_active
-- OPM�i�ڏ��VIEW(2)
      AND    (ximv2.inventory_item_id IS NULL
       OR    (TRUNC(NVL(xoha.shipped_date,xoha.schedule_ship_date)) BETWEEN ximv2.start_date_active
      AND     ximv2.end_date_active))
-- �d������VIEW2
      AND    xvv.inactive_date IS NULL
      AND    TRUNC(NVL(xoha.shipped_date,xoha.schedule_ship_date)) BETWEEN xvv.start_date_active
      AND    xvv.end_date_active
-- OPM�ۊǏꏊ���VIEW2
      AND    xilv.date_from <= TRUNC(NVL(xoha.shipped_date,xoha.schedule_ship_date))
      AND    (xilv.date_to >= TRUNC(NVL(xoha.shipped_date,xoha.schedule_ship_date))
       OR     xilv.date_to IS NULL)
      AND    xilv.disable_date IS NULL
-- �d����T�C�g���VIEW2
      AND    xvsv.inactive_date IS NULL
      AND    TRUNC(NVL(xoha.shipped_date,xoha.schedule_ship_date)) BETWEEN xvsv.start_date_active
      AND    xvsv.end_date_active
-- �^���Ǝҏ��VIEW2
      AND    (xcv.party_number IS NULL
      OR      (TRUNC(NVL(xoha.shipped_date,xoha.schedule_ship_date)) BETWEEN xcv.start_date_active
      AND      xcv.end_date_active))
-- �Z�L�����e�B�敪
      AND    (
-- �ɓ������[�U�[�^�C�v
              (gv_sec_class = gv_sec_class_home)
-- ����惆�[�U�[�^�C�v
       OR     (gv_sec_class = gv_sec_class_vend
               AND    xoha.vendor_code IN
                 (SELECT papf.attribute4              -- �����R�[�h(�d����R�[�h)
                  FROM   fnd_user           fu              -- ���[�U�[�}�X�^
                        ,per_all_people_f   papf            -- �]�ƈ��}�X�^
                  WHERE  fu.employee_id   = papf.person_id                   -- �]�ƈ�ID
                  AND    papf.effective_start_date <= TRUNC(gd_sys_date)     -- �K�p�J�n��
                  AND    papf.effective_end_date   >= TRUNC(gd_sys_date)     -- �K�p�I����
                  AND    fu.start_date             <= TRUNC(gd_sys_date)     -- �K�p�J�n��
                  AND  ((fu.end_date               IS NULL)                  -- �K�p�I����
                    OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                  AND    fu.user_id                 = gn_user_id)            -- ���[�U�[ID
              )
-- �O���q�Ƀ��[�U�[�^�C�v
       OR     (gv_sec_class = gv_sec_class_extn
               AND    xoha.deliver_from IN
                 (SELECT xilv.segment1                -- �ۊǑq�ɃR�[�h
                  FROM   fnd_user               fu          -- ���[�U�[�}�X�^
                        ,per_all_people_f       papf        -- �]�ƈ��}�X�^
                        ,xxcmn_item_locations_v xilv        -- OPM�ۊǏꏊ���VIEW
                  WHERE  fu.employee_id             = papf.person_id         -- �]�ƈ�ID
                  AND    papf.effective_start_date <= TRUNC(gd_sys_date)     -- �K�p�J�n��
                  AND    papf.effective_end_date   >= TRUNC(gd_sys_date)     -- �K�p�I����
                  AND    fu.start_date             <= TRUNC(gd_sys_date)     -- �K�p�J�n��
                  AND  ((fu.end_date               IS NULL)                  -- �K�p�I����
                    OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                  AND    xilv.purchase_code         = papf.attribute4        -- �d����R�[�h
                  AND    fu.user_id                 = gn_user_id)            -- ���[�U�[ID
              )
-- ���m�u�����[�U�[�^�C�v
       OR     (gv_sec_class = gv_sec_class_quay
               AND    (
                       xoha.deliver_from IN (
                          SELECT xilv.segment1                -- �ۊǑq�ɃR�[�h
                          FROM   fnd_user               fu          -- ���[�U�[�}�X�^
                                ,per_all_people_f       papf        -- �]�ƈ��}�X�^
                                ,xxcmn_item_locations_v xilv        -- OPM�ۊǏꏊ���VIEW
                          WHERE  fu.employee_id             = papf.person_id        -- �]�ƈ�ID
                          AND    papf.effective_start_date <= TRUNC(gd_sys_date)    -- �K�p�J�n��
                          AND    papf.effective_end_date   >= TRUNC(gd_sys_date)    -- �K�p�I����
                          AND    fu.start_date             <= TRUNC(gd_sys_date)    -- �K�p�J�n��
                          AND  ((fu.end_date               IS NULL)                 -- �K�p�I����
                            OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                          AND    xilv.purchase_code         = papf.attribute4       -- �d����R�[�h
                          AND    fu.user_id                 = gn_user_id            -- ���[�U�[ID
                          )
               OR      xoha.deliver_from IN (
-- 2008/11/26 Mod ��
-- 2008/07/30 Mod ��
--                          SELECT xilv.frequent_whse           -- ��\�q��
--                          SELECT xilv.frequent_whse_code      -- ��Ǒq��
                          SELECT xilv2.segment1      -- ���m�u���q�q��
-- 2008/07/30 Mod ��
                          FROM   fnd_user               fu          -- ���[�U�[�}�X�^
                                ,per_all_people_f       papf        -- �]�ƈ��}�X�^
                                ,xxcmn_item_locations_v xilv        -- OPM�ۊǏꏊ���VIEW
                                ,xxcmn_item_locations_v xilv2       -- OPM�ۊǏꏊ���VIEW
                          WHERE  fu.employee_id             = papf.person_id        -- �]�ƈ�ID
                          AND    papf.effective_start_date <= TRUNC(gd_sys_date)    -- �K�p�J�n��
                          AND    papf.effective_end_date   >= TRUNC(gd_sys_date)    -- �K�p�I����
                          AND    fu.start_date             <= TRUNC(gd_sys_date)    -- �K�p�J�n��
                          AND  ((fu.end_date               IS NULL)                 -- �K�p�I����
                            OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                          AND    xilv.purchase_code         = papf.attribute4       -- �d����R�[�h
                          AND    xilv.segment1              = xilv2.frequent_whse_code  -- �q�q�ɂ̍i����
                          AND    fu.user_id                 = gn_user_id            -- ���[�U�[ID
                          )
-- 2008/11/26 Mod ��
                      )
              )
             )
-- �\�[�g��
      ORDER BY NVL(xoha.shipped_date,
                   xoha.schedule_ship_date)               -- �o�ɓ�
              ,NVL(xoha.arrival_date,
                   xoha.schedule_arrival_date)            -- ���ɓ�
              ,xoha.deliver_from                          -- �q�ɃR�[�h
              ,xoha.vendor_code                           -- �����R�[�h
              ,xoha.vendor_site_code                      -- �z����R�[�h
              ,xoha.delivery_no                           -- �z��No.
              ,xoha.request_no                            -- �˗�No.
              ,xoha.designated_branch_no                  -- �����}��
              ,xola.shipping_item_code                    -- �i�ڃR�[�h
              ,xola.futai_code                            -- �t�уR�[�h
              ,xmldv.lot_no                               -- ���b�gNo
              ,xmldv.lot_date                             -- ������
              ,xmldv.best_bfr_date                        -- �ܖ�����
              ,xmldv.lot_sign                             -- �ŗL�L��
      ;
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    ln_cnt := 1;
--
    OPEN mst_data_cur;
--
    <<mst_data_loop>>
    LOOP
      FETCH mst_data_cur INTO lr_mst_data_rec;
      EXIT WHEN mst_data_cur%NOTFOUND;
--
      mst_rec.sel_tbl_id         := lr_mst_data_rec.sel_tbl_id;         -- �e�[�u��ID
      mst_rec.company_name       := lr_mst_data_rec.company_name;       -- ��Ж�
      mst_rec.data_class         := lr_mst_data_rec.data_class;         -- �f�[�^���
      mst_rec.ship_no            := lr_mst_data_rec.ship_no;            -- �z��No.
      mst_rec.request_no         := lr_mst_data_rec.request_no;         -- �˗�No.
      mst_rec.relation_no        := lr_mst_data_rec.relation_no;        -- �֘ANo.
      mst_rec.base_request_no    := lr_mst_data_rec.base_request_no;    -- �R�s�[��No.   2008/09/02 Add
      mst_rec.base_ship_no       := lr_mst_data_rec.base_ship_no;       -- ���z��No.
      mst_rec.vendor_code        := lr_mst_data_rec.vendor_code;        -- �����R�[�h
      mst_rec.vendor_name        := lr_mst_data_rec.vendor_name;        -- ����於
      mst_rec.vendor_s_name      := lr_mst_data_rec.vendor_s_name;      -- ����旪��
      mst_rec.mediation_code     := lr_mst_data_rec.mediation_code;     -- �����҃R�[�h
      mst_rec.mediation_name     := lr_mst_data_rec.mediation_name;     -- �����Җ�
      mst_rec.mediation_s_name   := lr_mst_data_rec.mediation_s_name;   -- �����җ���
      mst_rec.whse_code          := lr_mst_data_rec.whse_code;          -- �q�ɃR�[�h
      mst_rec.whse_name          := lr_mst_data_rec.whse_name;          -- �q�ɖ�
      mst_rec.whse_s_name        := lr_mst_data_rec.whse_s_name;        -- �q�ɗ���
      mst_rec.vendor_site_code   := lr_mst_data_rec.vendor_site_code;   -- �z����R�[�h
      mst_rec.vendor_site_name   := lr_mst_data_rec.vendor_site_name;   -- �z���於
      mst_rec.vendor_site_s_name := lr_mst_data_rec.vendor_site_s_name; -- �z���旪��
      mst_rec.zip                := lr_mst_data_rec.zip;                -- �X�֔ԍ�
      mst_rec.address            := lr_mst_data_rec.address;            -- �Z��
      mst_rec.phone              := lr_mst_data_rec.phone;              -- �d�b�ԍ�
      mst_rec.carrier_code       := lr_mst_data_rec.carrier_code;       -- �^���Ǝ҃R�[�h
      mst_rec.carrier_name       := lr_mst_data_rec.carrier_name;       -- �^���ƎҖ�
      mst_rec.carrier_s_name     := lr_mst_data_rec.carrier_s_name;     -- �^���Ǝҗ���
      mst_rec.ship_date          := lr_mst_data_rec.ship_date;          -- �o�ɓ�
      mst_rec.arrival_date       := lr_mst_data_rec.arrival_date;       -- ���ɓ�
      mst_rec.arrival_time_from  := lr_mst_data_rec.arrival_time_from;  -- ���׎���FROM
      mst_rec.arrival_time_to    := lr_mst_data_rec.arrival_time_to;    -- ���׎���TO
      mst_rec.method_code        := lr_mst_data_rec.method_code;        -- �z���敪
      mst_rec.div_a              := lr_mst_data_rec.div_a;              -- �敪�`
      mst_rec.div_b              := lr_mst_data_rec.div_b;              -- �敪�a
      mst_rec.div_c              := lr_mst_data_rec.div_c;              -- �敪�b
      mst_rec.instruction_dept   := lr_mst_data_rec.instruction_dept;   -- �w�������R�[�h
      mst_rec.request_dept       := lr_mst_data_rec.request_dept;       -- �˗������R�[�h
      mst_rec.status             := lr_mst_data_rec.status;             -- �X�e�[�^�X
      mst_rec.notif_status       := lr_mst_data_rec.notif_status;       -- �ʒm�X�e�[�^�X
      mst_rec.div_d              := lr_mst_data_rec.div_d;              -- �敪�c
      mst_rec.div_e              := lr_mst_data_rec.div_e;              -- �敪�d
      mst_rec.div_f              := lr_mst_data_rec.div_f;              -- �敪�e
      mst_rec.div_g              := lr_mst_data_rec.div_g;              -- �敪�f
      mst_rec.div_h              := lr_mst_data_rec.div_h;              -- �敪�g
      mst_rec.info_a             := TO_CHAR(lr_mst_data_rec.info_a,'YYYY/MM/DD');  -- ���`
      mst_rec.info_b             := lr_mst_data_rec.info_b;             -- ���a
      mst_rec.info_c             := lr_mst_data_rec.info_c;             -- ���b
      mst_rec.info_d             := lr_mst_data_rec.info_d;             -- ���c
      mst_rec.info_e             := lr_mst_data_rec.info_e;             -- ���d
      mst_rec.head_description   := lr_mst_data_rec.head_description;   -- �E�v(�w�b�_)
      mst_rec.line_description   := lr_mst_data_rec.line_description;   -- �E�v(����)
      mst_rec.line_num           := lr_mst_data_rec.line_num;           -- ����No.
      mst_rec.item_no            := lr_mst_data_rec.item_no;            -- �i�ڃR�[�h
      mst_rec.item_name          := lr_mst_data_rec.item_name;          -- �i�ږ�
      mst_rec.item_s_name        := lr_mst_data_rec.item_s_name;        -- �i�ڗ���
      mst_rec.futai_code         := lr_mst_data_rec.futai_code;         -- �t��
      mst_rec.lot_no             := lr_mst_data_rec.lot_no;             -- ���b�gNo
      mst_rec.v_lot_date         := lr_mst_data_rec.lot_date;           -- ������
      mst_rec.v_best_bfr_date    := lr_mst_data_rec.best_bfr_date;      -- �ܖ�����
      mst_rec.lot_sign           := lr_mst_data_rec.lot_sign;           -- �ŗL�L��
      mst_rec.request_qty        := lr_mst_data_rec.request_qty;        -- �˗���
      mst_rec.instruct_qty       := lr_mst_data_rec.instruct_qty;       -- �w����
      mst_rec.num_of_deliver     := lr_mst_data_rec.num_of_deliver;     -- �o�ɐ�
      mst_rec.ship_to_qty        := lr_mst_data_rec.ship_to_qty;        -- ���ɐ�
      mst_rec.fix_qty            := lr_mst_data_rec.fix_qty;            -- �m�萔
      mst_rec.item_um            := lr_mst_data_rec.item_um;            -- �P��
      mst_rec.weight_capacity    := lr_mst_data_rec.weight_capacity;    -- �d�ʗe��
      mst_rec.frequent_qty       := TO_NUMBER(lr_mst_data_rec.frequent_qty); -- ����
      mst_rec.frequent_factory   := lr_mst_data_rec.frequent_factory;   -- �H��R�[�h
      mst_rec.div_i              := lr_mst_data_rec.div_i;              -- �敪�h
      mst_rec.div_j              := lr_mst_data_rec.div_j;              -- �敪�i
      mst_rec.div_k              := lr_mst_data_rec.div_k;              -- �敪�j
      mst_rec.v_designate_date   := lr_mst_data_rec.designate_date;     -- ���t�w��
-- 2008/08/20 Mod ��
/*
      mst_rec.amt_a              := TO_CHAR(lr_mst_data_rec.amt_a);     -- �����`
*/
      IF (gv_sec_class IN (gv_sec_class_home,gv_sec_class_vend)) THEN
        mst_rec.amt_a            := lr_mst_data_rec.amt_a;              -- �����`
--
      ELSE
        mst_rec.amt_a            := NULL;              -- �����`
      END IF;
-- 2008/08/20 Mod ��
      mst_rec.update_date_h      := lr_mst_data_rec.update_date_h;      -- �ŏI�X�V��(�w�b�_)
      mst_rec.update_date_l      := lr_mst_data_rec.update_date_l;      -- �ŏI�X�V��(����)
--
      -- ���l�A���t�𕶎���ɕϊ�����
      mst_rec.v_ship_date       := TO_CHAR(mst_rec.ship_date,'YYYY/MM/DD');
      mst_rec.v_arrival_date    := TO_CHAR(mst_rec.arrival_date,'YYYY/MM/DD');
      mst_rec.v_update_date_h   := TO_CHAR(mst_rec.update_date_h,'YYYY/MM/DD HH24:MI:SS');
      mst_rec.v_update_date_l   := TO_CHAR(mst_rec.update_date_l,'YYYY/MM/DD HH24:MI:SS');
--
      gt_master_tbl(ln_cnt) := mst_rec;
      ln_cnt := ln_cnt + 1;
--
    END LOOP mst_data_loop;
--
    CLOSE mst_data_cur;
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
      -- �J�[�\�����J���Ă����
      IF (mst_data_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE mst_data_cur;
      END IF;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (mst_data_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE mst_data_cur;
      END IF;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (mst_data_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE mst_data_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END oha_sel_proc;
--
  /**********************************************************************************
   * Procedure Name   : mov_sel_proc
   * Description      : �ړ���񌟍�����(D-5)
   ***********************************************************************************/
  PROCEDURE mov_sel_proc(
    ov_errbuf           OUT NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'mov_sel_proc'; -- �v���O������
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
    mst_rec         masters_rec;
    ln_cnt          NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR mst_data_cur
    IS
      SELECT xmrh.mov_hdr_id as sel_tbl_id                      -- �e�[�u��ID
            ,gv_company_name as company_name                    -- ��Ж�
            ,gv_data_class_mov as data_class                    -- �f�[�^���
            ,xmrh.delivery_no as ship_no                        -- �z��No.
            ,xmrh.mov_num as request_no                         -- �˗�No.
            ,NULL as relation_no                                -- �֘ANo.
            ,NULL as base_request_no                            -- �R�s�[��No.    2008/09/02 Add
            ,xmrh.prev_delivery_no as base_ship_no              -- ���z��No.
            ,NULL as vendor_code                                -- �����R�[�h
            ,NULL as vendor_name                                -- ����於
            ,NULL as vendor_s_name                              -- ����旪��
            ,NULL as mediation_code                             -- �����҃R�[�h
            ,NULL as mediation_name                             -- �����Җ�
            ,NULL as mediation_s_name                           -- �����җ���
            ,xmrh.shipped_locat_code as whse_code               -- �q�ɃR�[�h
            ,xilv1.description as whse_name                     -- �q�ɖ�
            ,xilv1.short_name as whse_s_name                    -- �q�ɗ���
            ,xmrh.ship_to_locat_code as vendor_site_code        -- �z����R�[�h
            ,xilv2.description as vendor_site_name              -- �z���於
            ,xilv2.short_name as vendor_site_s_name             -- �z���旪��
            ,xlv.zip                                            -- �X�֔ԍ�
            ,xlv.address_line1 as address                       -- �Z��
            ,xlv.phone                                          -- �d�b�ԍ�
            ,NVL(xmrh.freight_carrier_code,
                 xmrh.actual_freight_carrier_code) as carrier_code -- �^���Ǝ҃R�[�h
            ,xcv.party_name as carrier_name                     -- �^���ƎҖ�
            ,xcv.party_short_name as carrier_s_name             -- �^���Ǝҗ���
            ,NVL(xmrh.actual_ship_date,
                 xmrh.schedule_ship_date) as ship_date          -- �o�ɓ�(YYYY/MM/DD)
            ,NVL(xmrh.actual_arrival_date,
                 xmrh.schedule_arrival_date) as arrival_date    -- ���ɓ�(YYYY/MM/DD)
            ,xmrh.arrival_time_from                             -- ���׎���FROM
            ,xmrh.arrival_time_to                               -- ���׎���TO
            ,NVL(xmrh.actual_shipping_method_code,
                 xmrh.shipping_method_code) as method_code      -- �z���敪
            ,xmrh.freight_charge_class as div_a                 -- �敪�`(�^���敪)
            ,xmrh.no_cont_freight_class as div_b                -- �敪�a(�_��O�^���敪)
            ,xmrh.weight_capacity_class as div_c                -- �敪�b(�d�ʗe�ϋ敪)
            ,xmrh.instruction_post_code as instruction_dept     -- �w�������R�[�h
            ,NULL as request_dept                               -- �˗������R�[�h
            ,xmrh.status                                        -- �X�e�[�^�X
            ,xmrh.notif_status                                  -- �ʒm�X�e�[�^�X
            ,xmrh.mov_type as div_d                             -- �敪�c(�ړ��^�C�v)
            ,NULL as div_e                                      -- �敪�d
            ,NULL as div_f                                      -- �敪�e
            ,NULL as div_g                                      -- �敪�f
            ,xmrh.new_modify_flg as div_h                       -- �敪�g(�C���t���O)
            ,xmrh.pallet_sum_quantity as info_a                 -- ���`(�p���b�g�g�p����)
            ,xmrh.collected_pallet_qty as info_b                -- ���a(�p���b�g�������)
            ,NULL as info_c                                     -- ���b
            ,NULL as info_d                                     -- ���c
            ,NULL as info_e                                     -- ���d
            ,xmrh.description as head_description               -- �E�v(�w�b�_)
            ,NULL as line_description                           -- �E�v(����)
            ,xmrl.line_number as line_num                       -- ����No.
            ,xmrl.item_code as item_no                          -- �i�ڃR�[�h
            ,ximv.item_name                                     -- �i�ږ�
            ,ximv.item_short_name as item_s_name                -- �i�ڗ���
            ,NULL as futai_code                                 -- �t��
            ,xmldv.lot_no                                       -- ���b�gNo
            ,xmldv.lot_date                                     -- ������
            ,xmldv.best_bfr_date                                -- �ܖ�����
            ,xmldv.lot_sign                                     -- �ŗL�L��
            ,xmrl.request_qty                                   -- �˗���
-- 2008/08/20 Mod ��
/*
            ,xmldv.instruct_qty                                 -- �w����
            ,xmldv.num_of_deliver                               -- �o�ɐ�
            ,xmldv.ship_to_qty                                  -- ���ɐ�
            ,xmldv.fix_qty                                      -- �m�萔
*/
            ,DECODE(xmldv.lot_no,NULL,
                    xmrl.instruct_qty,
                    xmldv.instruct_qty
                   ) as instruct_qty                            -- �w����
            ,DECODE(xmldv.lot_no,NULL,
                    xmrl.shipped_quantity,
                    xmldv.num_of_deliver
                   ) as num_of_deliver                          -- �o�ɐ�
            ,DECODE(xmldv.lot_no,NULL,
                    xmrl.ship_to_quantity,
                    xmldv.ship_to_qty
                   ) as ship_to_qty                             -- ���ɐ�
            ,DECODE(xmldv.lot_no,NULL,
                    xmrl.shipped_quantity,
                    xmldv.fix_qty
                   ) as fix_qty                                 -- �m�萔
-- 2008/08/20 Mod ��
            ,xmrl.uom_code as item_um                           -- �P��
            ,DECODE(xmrh.weight_capacity_class,
                    gv_weight_class,xmrl.weight,
                    gv_capacity_class,xmrl.capacity,
                    NULL) as weight_capacity                    -- �d�ʗe��
            ,DECODE(ximv.lot_ctl,gv_lot_ctl_on,
                    xmldv.frequent_qty,
                    NULL) as frequent_qty                       -- ����
            ,NULL as frequent_factory                           -- �H��R�[�h
            ,NULL as div_i                                      -- �敪�h
            ,NULL as div_j                                      -- �敪�i
-- 2008/08/20 Mod ��
/*
            ,NULL as div_k                                      -- �敪�j
*/
-- 2008/08/20 Mod ��
            ,xmrl.delete_flg as div_k                           -- �敪�j
            ,xmrl.designated_production_date as designate_date  -- ���t�w��
            ,NULL as info_f                                     -- ���e(�N�x)
            ,NULL as info_g                                     -- ���f(�Y�n�R�[�h)
            ,NULL as info_h                                     -- ���g(�q�P)
            ,NULL as info_i                                     -- ���h(�q�Q)
            ,NULL as info_j                                     -- ���i(�q�R)
            ,NULL as info_k                                     -- ���j(�����H��)
            ,NULL as info_l                                     -- ���k(�������b�g)
            ,NULL as info_m                                     -- ���l(���i�ڃR�[�h)
            ,NULL as info_n                                     -- ���m(�����b�g)
            ,NULL as info_o                                     -- ���n(�d���`��)
            ,NULL as info_p                                     -- ���o(�����敪)
            ,NULL as info_q                                     -- ���p(�^�C�v)
            ,NULL as amt_a                                      -- �����`(�P��)
            ,NULL as amt_b                                      -- �����a(������)
            ,NULL as amt_c                                      -- �����b(������P��)
            ,NULL as amt_d                                      -- �����c(���K�敪)
            ,NULL as amt_e                                      -- �����d(���K)
            ,NULL as amt_f                                      -- �����e(�a����K�z)
            ,NULL as amt_g                                      -- �����f(���ۋ��敪)
            ,NULL as amt_h                                      -- �����g(���ۋ�)
            ,NULL as amt_i                                      -- �����h(���ۋ��z)
            ,NULL as amt_j                                      -- �����i(��������z)
            ,xmrh.last_update_date as update_date_h             -- �X�V����(�w�b�_)
            ,xmrl.last_update_date as update_date_l             -- �X�V����(����)
      FROM   xxinv_mov_req_instr_headers xmrh       -- �ړ��˗�/�w���w�b�_(�A�h�I��)
            ,xxinv_mov_req_instr_lines   xmrl       -- �ړ��˗�/�w������(�A�h�I��)
            ,xxcmn_item_locations2_v     xilv1      -- OPM�ۊǏꏊ���VIEW2
            ,xxcmn_item_locations2_v     xilv2      -- OPM�ۊǏꏊ���VIEW2
            ,xxcmn_item_mst2_v           ximv       -- OPM�i�ڏ��VIEW2
            ,xxcmn_item_categories4_v    xicv       -- OPM�i�ڃJ�e�S���������VIEW4
            ,xxcmn_locations2_v          xlv        -- ���Ə����VIEW2
            ,xxcmn_carriers2_v           xcv        -- �^���Ǝҏ��VIEW2
            ,xxcmn_lookup_values2_v      xlvv       -- �N�C�b�N�R�[�h���VIEW2
            ,(
              SELECT xmld.mov_line_id
                    ,ilm.lot_id
                    ,ilm.item_id
                    ,ilm.attribute1 as lot_date                         -- ������
                    ,ilm.attribute3 as best_bfr_date                    -- �ܖ�����
                    ,ilm.attribute2 as lot_sign                         -- �ŗL�L��
                    ,ilm.attribute6 as frequent_qty                     -- ����
                    ,DECODE(ximv2.lot_ctl,gv_lot_ctl_on,
                            ilm.lot_no,
                            NULL) as lot_no                             -- ���b�gNo
-- 2008/08/20 Mod ��
/*
                    ,SUM(DECODE(xmld.document_type_code,gv_document_type_code_20
                        ,DECODE(xmld.record_type_code,gv_record_type_code_10,
                                xmld.actual_quantity,0)
                        ,0)) as instruct_qty                             -- �w����
                    ,SUM(DECODE(xmld.document_type_code,gv_document_type_code_20
                        ,DECODE(xmld.record_type_code,gv_record_type_code_20,
                                xmld.actual_quantity,0)
                        ,0)) as num_of_deliver                           -- �o�ɐ�
                    ,SUM(DECODE(xmld.document_type_code,gv_document_type_code_20
                        ,DECODE(xmld.record_type_code,gv_record_type_code_30,
                                xmld.actual_quantity,0)
                        ,0)) as ship_to_qty                              -- ���ɐ�
                    ,SUM(DECODE(xmld.document_type_code,gv_document_type_code_20
                        ,DECODE(xmld.record_type_code,gv_record_type_code_20,
                                xmld.actual_quantity,0)
                        ,0)) as fix_qty                                  -- �m�萔
*/
                    ,SUM(DECODE(xmld.document_type_code,gv_document_type_code_20
                        ,DECODE(xmld.record_type_code,gv_record_type_code_10,
                                xmld.actual_quantity
                               ,NULL)
                        ,NULL)) as instruct_qty                          -- �w����
                    ,SUM(DECODE(xmld.document_type_code,gv_document_type_code_20
                        ,DECODE(xmld.record_type_code,gv_record_type_code_20,
                                xmld.actual_quantity
                               ,NULL)
                        ,NULL)) as num_of_deliver                        -- �o�ɐ�
                    ,SUM(DECODE(xmld.document_type_code,gv_document_type_code_20
                        ,DECODE(xmld.record_type_code,gv_record_type_code_30,
                                xmld.actual_quantity
                               ,NULL)
                        ,NULL)) as ship_to_qty                           -- ���ɐ�
                    ,SUM(DECODE(xmld.document_type_code,gv_document_type_code_20
                        ,DECODE(xmld.record_type_code,gv_record_type_code_20,
                                xmld.actual_quantity
                               ,NULL)
                        ,NULL)) as fix_qty                               -- �m�萔
-- 2008/08/20 Mod ��
              FROM   xxinv_mov_lot_details xmld     -- �ړ����b�g�ڍ�(�A�h�I��)
                    ,ic_lots_mst           ilm      -- OPM���b�g�}�X�^
                    ,xxcmn_item_mst2_v     ximv2    -- OPM�i�ڏ��VIEW2
              WHERE  xmld.lot_id     = ilm.lot_id(+)
              AND    xmld.item_id    = ilm.item_id(+)
              AND    xmld.item_id    = ximv2.item_id
              AND    ((gd_update_time_from IS NULL)
                 OR   (xmld.last_update_date >= gd_update_time_from))
              AND    ((gd_update_time_to IS NULL)
                 OR   (xmld.last_update_date <= gd_update_time_to))
              GROUP BY xmld.mov_line_id
                      ,ilm.lot_id
                      ,ilm.item_id
                      ,ilm.attribute1
                      ,ilm.attribute3
                      ,ilm.attribute2
                      ,ilm.attribute6
                      ,DECODE(ximv2.lot_ctl,gv_lot_ctl_on,
                              ilm.lot_no,
                              NULL)
             ) xmldv
      WHERE  xmrh.mov_hdr_id           = xmrl.mov_hdr_id
      AND    xmrl.item_id              = ximv.item_id
      AND    ximv.item_id              = xicv.item_id
      AND    xcv.party_number(+)       = NVL(xmrh.actual_freight_carrier_code,
                                             xmrh.freight_carrier_code)
      AND    xmrh.shipped_locat_code   = xilv1.segment1
      AND    xmrh.ship_to_locat_code   = xilv2.segment1
      AND    xilv2.location_id         = xlv.location_id
      AND    xmrl.mov_line_id          = xmldv.mov_line_id(+)
      AND    xlvv.lookup_code(+)       = NVL(xmrh.actual_shipping_method_code,
                                             xmrh.shipping_method_code)
      AND    xlvv.lookup_type(+)       = gv_ship_method
-- �X�e�[�^�X
      -- 2008/07/30 Mod ��
/*
      AND    NVL(xmrh.status,gv_status_null) IN (
              gv_xxinv_status_02                       -- �˗���:02
             ,gv_xxinv_status_03                       -- ������:03
             ,gv_xxinv_status_04                       -- �o�ɕ񍐗L:04
             ,gv_xxinv_status_05                       -- ���ɕ񍐗L:05
             ,gv_xxinv_status_06                       -- ���o�ɕ񍐗L:06
             ,gv_xxinv_status_07                       -- ���:99
      )
*/
      AND    NVL(xmrh.status,gv_status_null) >= gv_xxinv_status_02         -- �˗���:02�ȍ~
      -- 2008/07/30 Mod ��
-- �z��No
      AND   ((gv_ship_no_from IS NULL) OR (xmrh.delivery_no >= gv_ship_no_from))
      AND   ((gv_ship_no_to IS NULL)   OR (xmrh.delivery_no <= gv_ship_no_to))
-- �˗�No
      AND   ((gv_req_no_from IS NULL) OR (xmrh.mov_num >= gv_req_no_from))
      AND   ((gv_req_no_to IS NULL)   OR (xmrh.mov_num <= gv_req_no_to))
-- �o�ɑq��
      AND   ((gv_location_code IS NULL) OR (xmrh.shipped_locat_code = gv_location_code))
-- ���ɑq��
      AND   ((gv_arvl_code IS NULL) OR (xmrh.ship_to_locat_code = gv_arvl_code))
-- �^���Ǝ�
      AND   ((gv_carrier_code IS NULL)
       OR    (NVL(xmrh.freight_carrier_code,xmrh.actual_freight_carrier_code) = gv_carrier_code))
-- �[����/�o�ɓ�(�K�{)
      AND    NVL(xmrh.actual_ship_date,xmrh.schedule_ship_date) >= gd_ship_date_from
      AND    NVL(xmrh.actual_ship_date,xmrh.schedule_ship_date) <= gd_ship_date_to
-- ���ɓ�
      AND   ((gd_arrival_date_from IS NULL)
       OR    (NVL(xmrh.actual_arrival_date,xmrh.schedule_arrival_date) >= gd_arrival_date_from))
      AND   ((gd_arrival_date_to IS NULL)
       OR    (NVL(xmrh.actual_arrival_date,xmrh.schedule_arrival_date) <= gd_arrival_date_to))
-- �w������
      AND   ((gv_instruction_dept IS NULL) OR (xmrh.instruction_post_code = gv_instruction_dept))
-- �i��
      AND   ((gv_item_no IS NULL) OR (ximv.item_no = gv_item_no))
-- �X�V����
      AND   ((gd_update_time_from IS NULL) OR (xmrh.last_update_date >= gd_update_time_from))
      AND   ((gd_update_time_to IS NULL)   OR (xmrh.last_update_date <= gd_update_time_to))
      AND   ((gd_update_time_from IS NULL) OR (xmrl.last_update_date >= gd_update_time_from))
      AND   ((gd_update_time_to IS NULL)   OR (xmrl.last_update_date <= gd_update_time_to))
-- ���i�敪
      AND   ((gv_prod_class IS NULL) OR (xicv.prod_class_code         = gv_prod_class))
-- �i�ڋ敪
      AND   ((gv_item_class IS NULL) OR (xicv.item_class_code         = gv_item_class))
-- �N�C�b�N�R�[�h���VIEW2
      AND   (xlvv.lookup_code IS NULL
       OR    ((xlvv.start_date_active <= TRUNC(NVL(xmrh.actual_ship_date,xmrh.schedule_ship_date))
       OR    xlvv.start_date_active IS NULL)
      AND    (xlvv.end_date_active   >= TRUNC(NVL(xmrh.actual_ship_date,xmrh.schedule_ship_date))
       OR     xlvv.end_date_active IS NULL)
      AND    xlvv.enabled_flag = gv_enabled_flag_on))
-- OPM�i�ڏ��VIEW2
      AND    TRUNC(NVL(xmrh.actual_ship_date,xmrh.schedule_ship_date)) 
      BETWEEN ximv.start_date_active AND ximv.end_date_active
-- �^���Ǝҏ��VIEW2
      AND    (xcv.party_number IS NULL
       OR    (TRUNC(NVL(xmrh.actual_ship_date,xmrh.schedule_ship_date))
      BETWEEN xcv.start_date_active AND xcv.end_date_active))
-- OPM�ۊǏꏊ���VIEW2
      AND    xilv1.date_from <= TRUNC(NVL(xmrh.actual_ship_date,xmrh.schedule_ship_date))
      AND    (xilv1.date_to  >= TRUNC(NVL(xmrh.actual_ship_date,xmrh.schedule_ship_date))
       OR     xilv1.date_to IS NULL)
      AND    xilv1.disable_date IS NULL
-- OPM�ۊǏꏊ���VIEW2
      AND    xilv2.date_from <= TRUNC(NVL(xmrh.actual_ship_date,xmrh.schedule_ship_date))
      AND    (xilv2.date_to  >= TRUNC(NVL(xmrh.actual_ship_date,xmrh.schedule_ship_date))
       OR     xilv2.date_to IS NULL)
      AND    xilv2.disable_date IS NULL
-- ���Ə����VIEW2
      AND    xlv.inactive_date IS NULL
      AND    xlv.start_date_active <= TRUNC(NVL(xmrh.actual_ship_date,xmrh.schedule_ship_date))
      AND    xlv.end_date_active   >= TRUNC(NVL(xmrh.actual_ship_date,xmrh.schedule_ship_date))
-- �Z�L�����e�B�敪
      AND    (
-- �ɓ������[�U�[�^�C�v
              (gv_sec_class = gv_sec_class_home)
-- ����惆�[�U�[�^�C�v
       OR     (gv_sec_class = gv_sec_class_vend
               AND    xilv1.purchase_code IN
                 (SELECT papf.attribute4           -- �����R�[�h(�d����R�[�h)
                  FROM   fnd_user           fu              -- ���[�U�[�}�X�^
                        ,per_all_people_f   papf            -- �]�ƈ��}�X�^
                  WHERE  fu.employee_id             = papf.person_id         -- �]�ƈ�ID
                  AND    papf.effective_start_date <= TRUNC(gd_sys_date)     -- �K�p�J�n��
                  AND    papf.effective_end_date   >= TRUNC(gd_sys_date)     -- �K�p�I����
                  AND    fu.start_date             <= TRUNC(gd_sys_date)     -- �K�p�J�n��
                  AND  ((fu.end_date               IS NULL)                  -- �K�p�I����
                    OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                  AND    fu.user_id                 = gn_user_id)            -- ���[�U�[ID
              )
-- �O���q�Ƀ��[�U�[�^�C�v
       OR     (gv_sec_class = gv_sec_class_extn
               AND    ((xmrh.shipped_locat_code IN  -- �o�Ɍ��ۊǏꏊ
                 (SELECT xilv.segment1                -- �ۊǑq�ɃR�[�h
                  FROM   fnd_user               fu          -- ���[�U�[�}�X�^
                        ,per_all_people_f       papf        -- �]�ƈ��}�X�^
                        ,xxcmn_item_locations_v xilv        -- OPM�ۊǏꏊ���VIEW
                  WHERE  fu.employee_id             = papf.person_id         -- �]�ƈ�ID
                  AND    papf.effective_start_date <= TRUNC(gd_sys_date)     -- �K�p�J�n��
                  AND    papf.effective_end_date   >= TRUNC(gd_sys_date)     -- �K�p�I����
                  AND    fu.start_date             <= TRUNC(gd_sys_date)     -- �K�p�J�n��
                  AND  ((fu.end_date               IS NULL)                  -- �K�p�I����
                    OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                  AND    xilv.purchase_code         = papf.attribute4        -- �d����R�[�h
                  AND    fu.user_id                 = gn_user_id))           -- ���[�U�[ID
                OR    (xmrh.ship_to_locat_code IN  -- ���ɐ�ۊǏꏊ
                 (SELECT xilv.segment1                -- �ۊǑq�ɃR�[�h
                  FROM   fnd_user               fu          -- ���[�U�[�}�X�^
                        ,per_all_people_f       papf        -- �]�ƈ��}�X�^
                        ,xxcmn_item_locations_v xilv        -- OPM�ۊǏꏊ���VIEW
                  WHERE  fu.employee_id             = papf.person_id         -- �]�ƈ�ID
                  AND    papf.effective_start_date <= TRUNC(gd_sys_date)     -- �K�p�J�n��
                  AND    papf.effective_end_date   >= TRUNC(gd_sys_date)     -- �K�p�I����
                  AND    fu.start_date             <= TRUNC(gd_sys_date)     -- �K�p�J�n��
                  AND  ((fu.end_date               IS NULL)                  -- �K�p�I����
                    OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                  AND    xilv.purchase_code         = papf.attribute4        -- �d����R�[�h
                  AND    fu.user_id                 = gn_user_id)))          -- ���[�U�[ID
              )
-- ���m�u�����[�U�[�^�C�v
       OR     (gv_sec_class = gv_sec_class_quay
               AND    ((
                       xmrh.shipped_locat_code IN (
                          SELECT xilv.segment1                -- �ۊǑq�ɃR�[�h
                          FROM   fnd_user               fu          -- ���[�U�[�}�X�^
                                ,per_all_people_f       papf        -- �]�ƈ��}�X�^
                                ,xxcmn_item_locations_v xilv        -- OPM�ۊǏꏊ���VIEW
                          WHERE  fu.employee_id             = papf.person_id        -- �]�ƈ�ID
                          AND    papf.effective_start_date <= TRUNC(gd_sys_date)    -- �K�p�J�n��
                          AND    papf.effective_end_date   >= TRUNC(gd_sys_date)    -- �K�p�I����
                          AND    fu.start_date             <= TRUNC(gd_sys_date)    -- �K�p�J�n��
                          AND  ((fu.end_date               IS NULL)                 -- �K�p�I����
                            OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                          AND    xilv.purchase_code         = papf.attribute4       -- �d����R�[�h
                          AND    fu.user_id                 = gn_user_id            -- ���[�U�[ID
                          )
               OR      xmrh.shipped_locat_code IN (
-- 2008/11/26 Mod ��
-- 2008/07/30 Mod ��
--                          SELECT xilv.frequent_whse           -- ��\�q��
--                          SELECT xilv.frequent_whse_code      -- ��Ǒq��
                          SELECT xilv2.segment1      -- ���m�u���q�q��
-- 2008/07/30 Mod ��
                          FROM   fnd_user               fu          -- ���[�U�[�}�X�^
                                ,per_all_people_f       papf        -- �]�ƈ��}�X�^
                                ,xxcmn_item_locations_v xilv        -- OPM�ۊǏꏊ���VIEW
                                ,xxcmn_item_locations_v xilv2       -- OPM�ۊǏꏊ���VIEW
                          WHERE  fu.employee_id             = papf.person_id        -- �]�ƈ�ID
                          AND    papf.effective_start_date <= TRUNC(gd_sys_date)    -- �K�p�J�n��
                          AND    papf.effective_end_date   >= TRUNC(gd_sys_date)    -- �K�p�I����
                          AND    fu.start_date             <= TRUNC(gd_sys_date)    -- �K�p�J�n��
                          AND  ((fu.end_date               IS NULL)                 -- �K�p�I����
                            OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                          AND    xilv.purchase_code         = papf.attribute4       -- �d����R�[�h
                          AND    xilv.segment1              = xilv2.frequent_whse_code   -- �q�q�ɍi����
                          AND    fu.user_id                 = gn_user_id            -- ���[�U�[ID
                          )
                      )
                OR    (
                       xmrh.ship_to_locat_code IN (
                          SELECT xilv.segment1                -- �ۊǑq�ɃR�[�h
                          FROM   fnd_user               fu          -- ���[�U�[�}�X�^
                                ,per_all_people_f       papf        -- �]�ƈ��}�X�^
                                ,xxcmn_item_locations_v xilv        -- OPM�ۊǏꏊ���VIEW
                          WHERE  fu.employee_id             = papf.person_id        -- �]�ƈ�ID
                          AND    papf.effective_start_date <= TRUNC(gd_sys_date)    -- �K�p�J�n��
                          AND    papf.effective_end_date   >= TRUNC(gd_sys_date)    -- �K�p�I����
                          AND    fu.start_date             <= TRUNC(gd_sys_date)    -- �K�p�J�n��
                          AND  ((fu.end_date               IS NULL)                 -- �K�p�I����
                            OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                          AND    xilv.purchase_code         = papf.attribute4       -- �d����R�[�h
                          AND    fu.user_id                 = gn_user_id            -- ���[�U�[ID
                          )
               OR      xmrh.ship_to_locat_code IN (
-- 2008/07/30 Mod ��
--                          SELECT xilv.frequent_whse           -- ��\�q��
--                          SELECT xilv.frequent_whse_code      -- ��Ǒq��
                          SELECT xilv2.segment1      -- ���m�u���q�q��
-- 2008/07/30 Mod ��
                          FROM   fnd_user               fu          -- ���[�U�[�}�X�^
                                ,per_all_people_f       papf        -- �]�ƈ��}�X�^
                                ,xxcmn_item_locations_v xilv        -- OPM�ۊǏꏊ���VIEW
                                ,xxcmn_item_locations_v xilv2       -- OPM�ۊǏꏊ���VIEW
                          WHERE  fu.employee_id             = papf.person_id        -- �]�ƈ�ID
                          AND    papf.effective_start_date <= TRUNC(gd_sys_date)    -- �K�p�J�n��
                          AND    papf.effective_end_date   >= TRUNC(gd_sys_date)    -- �K�p�I����
                          AND    fu.start_date             <= TRUNC(gd_sys_date)    -- �K�p�J�n��
                          AND  ((fu.end_date               IS NULL)                 -- �K�p�I����
                            OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                          AND    xilv.purchase_code         = papf.attribute4       -- �d����R�[�h
                          AND    xilv.segment1              = xilv2.frequent_whse_code       -- �d����R�[�h
                          AND    fu.user_id                 = gn_user_id            -- ���[�U�[ID
                          )
-- 2008/11/26 Mod ��
                      ))
              )
             )
-- �\�[�g��
      ORDER BY NVL(xmrh.schedule_ship_date,
                   xmrh.actual_ship_date)                 -- �o�ɓ�
              ,NVL(xmrh.schedule_arrival_date,
                   xmrh.actual_arrival_date)              -- ���ɓ�
              ,xmrh.shipped_locat_code                    -- �q�ɃR�[�h
              ,xmrh.ship_to_locat_code                    -- �z����R�[�h
              ,xmrh.delivery_no                           -- �z��No.
              ,xmrh.mov_num                               -- �˗�No.
              ,xmrl.line_number                           -- ����No.
              ,xmrl.item_code                             -- �i�ڃR�[�h
              ,xmldv.lot_no                               -- ���b�gNo
              ,xmldv.lot_date                             -- ������
              ,xmldv.best_bfr_date                        -- �ܖ�����
              ,xmldv.lot_sign                             -- �ŗL�L��
      ;
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    ln_cnt := 1;
--
    OPEN mst_data_cur;
--
    <<mst_data_loop>>
    LOOP
      FETCH mst_data_cur INTO lr_mst_data_rec;
      EXIT WHEN mst_data_cur%NOTFOUND;
--
      mst_rec.sel_tbl_id         := lr_mst_data_rec.sel_tbl_id;         -- �e�[�u��ID
      mst_rec.company_name       := lr_mst_data_rec.company_name;       -- ��Ж�
      mst_rec.data_class         := lr_mst_data_rec.data_class;         -- �f�[�^���
      mst_rec.ship_no            := lr_mst_data_rec.ship_no;            -- �z��No.
      mst_rec.request_no         := lr_mst_data_rec.request_no;         -- �˗�No.
      mst_rec.relation_no        := lr_mst_data_rec.relation_no;        -- �֘ANo.
      mst_rec.base_request_no    := lr_mst_data_rec.base_request_no;    -- �R�s�[��No.   2008/09/02 Add
      mst_rec.base_ship_no       := lr_mst_data_rec.base_ship_no;       -- ���z��No.
      mst_rec.vendor_code        := lr_mst_data_rec.vendor_code;        -- �����R�[�h
      mst_rec.vendor_name        := lr_mst_data_rec.vendor_name;        -- ����於
      mst_rec.vendor_s_name      := lr_mst_data_rec.vendor_s_name;      -- ����旪��
      mst_rec.mediation_code     := lr_mst_data_rec.mediation_code;     -- �����҃R�[�h
      mst_rec.mediation_name     := lr_mst_data_rec.mediation_name;     -- �����Җ�
      mst_rec.mediation_s_name   := lr_mst_data_rec.mediation_s_name;   -- �����җ���
      mst_rec.whse_code          := lr_mst_data_rec.whse_code;          -- �q�ɃR�[�h
      mst_rec.whse_name          := lr_mst_data_rec.whse_name;          -- �q�ɖ�
      mst_rec.whse_s_name        := lr_mst_data_rec.whse_s_name;        -- �q�ɗ���
      mst_rec.vendor_site_code   := lr_mst_data_rec.vendor_site_code;   -- �z����R�[�h
      mst_rec.vendor_site_name   := lr_mst_data_rec.vendor_site_name;   -- �z���於
      mst_rec.vendor_site_s_name := lr_mst_data_rec.vendor_site_s_name; -- �z���旪��
      mst_rec.zip                := lr_mst_data_rec.zip;                -- �X�֔ԍ�
      mst_rec.address            := lr_mst_data_rec.address;            -- �Z��
      mst_rec.phone              := lr_mst_data_rec.phone;              -- �d�b�ԍ�
      mst_rec.carrier_code       := lr_mst_data_rec.carrier_code;       -- �^���Ǝ҃R�[�h
      mst_rec.carrier_name       := lr_mst_data_rec.carrier_name;       -- �^���ƎҖ�
      mst_rec.carrier_s_name     := lr_mst_data_rec.carrier_s_name;     -- �^���Ǝҗ���
      mst_rec.ship_date          := lr_mst_data_rec.ship_date;          -- �o�ɓ�
      mst_rec.arrival_date       := lr_mst_data_rec.arrival_date;       -- ���ɓ�
      mst_rec.arrival_time_from  := lr_mst_data_rec.arrival_time_from;  -- ���׎���FROM
      mst_rec.arrival_time_to    := lr_mst_data_rec.arrival_time_to;    -- ���׎���TO
      mst_rec.method_code        := lr_mst_data_rec.method_code;        -- �z���敪
      mst_rec.div_a              := lr_mst_data_rec.div_a;              -- �敪�`
      mst_rec.div_b              := lr_mst_data_rec.div_b;              -- �敪�a
      mst_rec.div_c              := lr_mst_data_rec.div_c;              -- �敪�b
      mst_rec.instruction_dept   := lr_mst_data_rec.instruction_dept;   -- �w�������R�[�h
      mst_rec.request_dept       := lr_mst_data_rec.request_dept;       -- �˗������R�[�h
      mst_rec.status             := lr_mst_data_rec.status;             -- �X�e�[�^�X
      mst_rec.notif_status       := lr_mst_data_rec.notif_status;       -- �ʒm�X�e�[�^�X
      mst_rec.div_d              := lr_mst_data_rec.div_d;              -- �敪�c
      mst_rec.div_e              := lr_mst_data_rec.div_e;              -- �敪�d
      mst_rec.div_f              := lr_mst_data_rec.div_f;              -- �敪�e
      mst_rec.div_g              := lr_mst_data_rec.div_g;              -- �敪�f
      mst_rec.div_h              := lr_mst_data_rec.div_h;              -- �敪�g
      mst_rec.info_a             := lr_mst_data_rec.info_a;             -- ���`
      mst_rec.info_b             := lr_mst_data_rec.info_b;             -- ���a
      mst_rec.info_c             := lr_mst_data_rec.info_c;             -- ���b
      mst_rec.info_d             := lr_mst_data_rec.info_d;             -- ���c
      mst_rec.info_e             := lr_mst_data_rec.info_e;             -- ���d
      mst_rec.head_description   := lr_mst_data_rec.head_description;   -- �E�v(�w�b�_)
      mst_rec.line_description   := lr_mst_data_rec.line_description;   -- �E�v(����)
      mst_rec.line_num           := lr_mst_data_rec.line_num;           -- ����No.
      mst_rec.item_no            := lr_mst_data_rec.item_no;            -- �i�ڃR�[�h
      mst_rec.item_name          := lr_mst_data_rec.item_name;          -- �i�ږ�
      mst_rec.item_s_name        := lr_mst_data_rec.item_s_name;        -- �i�ڗ���
      mst_rec.futai_code         := lr_mst_data_rec.futai_code;         -- �t��
      mst_rec.lot_no             := lr_mst_data_rec.lot_no;             -- ���b�gNo
      mst_rec.v_lot_date         := lr_mst_data_rec.lot_date;           -- ������
      mst_rec.v_best_bfr_date    := lr_mst_data_rec.best_bfr_date;      -- �ܖ�����
      mst_rec.lot_sign           := lr_mst_data_rec.lot_sign;           -- �ŗL�L��
      mst_rec.request_qty        := lr_mst_data_rec.request_qty;        -- �˗���
      mst_rec.instruct_qty       := lr_mst_data_rec.instruct_qty;       -- �w����
      mst_rec.num_of_deliver     := lr_mst_data_rec.num_of_deliver;     -- �o�ɐ�
      mst_rec.ship_to_qty        := lr_mst_data_rec.ship_to_qty;        -- ���ɐ�
      mst_rec.fix_qty            := lr_mst_data_rec.fix_qty;            -- �m�萔
      mst_rec.item_um            := lr_mst_data_rec.item_um;            -- �P��
      mst_rec.weight_capacity    := lr_mst_data_rec.weight_capacity;    -- �d�ʗe��
      mst_rec.frequent_qty       := TO_NUMBER(lr_mst_data_rec.frequent_qty);       -- ����
      mst_rec.frequent_factory   := lr_mst_data_rec.frequent_factory;   -- �H��R�[�h
      mst_rec.div_i              := lr_mst_data_rec.div_i;              -- �敪�h
      mst_rec.div_j              := lr_mst_data_rec.div_j;              -- �敪�i
      mst_rec.div_k              := lr_mst_data_rec.div_k;              -- �敪�j
-- 2008/08/20 Mod ��
/*
      mst_rec.v_designate_date   := lr_mst_data_rec.designate_date;     -- ���t�w��
*/
      mst_rec.designate_date     := lr_mst_data_rec.designate_date;     -- ���t�w��
-- 2008/08/20 Mod ��
      mst_rec.amt_a              := lr_mst_data_rec.amt_a;              -- �����`
      mst_rec.update_date_h      := lr_mst_data_rec.update_date_h;      -- �ŏI�X�V��(�w�b�_)
      mst_rec.update_date_l      := lr_mst_data_rec.update_date_l;      -- �ŏI�X�V��(����)
--
      -- ���l�A���t�𕶎���ɕϊ�����
      mst_rec.v_ship_date       := TO_CHAR(mst_rec.ship_date,'YYYY/MM/DD');
      mst_rec.v_arrival_date    := TO_CHAR(mst_rec.arrival_date,'YYYY/MM/DD');
      mst_rec.v_update_date_h   := TO_CHAR(mst_rec.update_date_h,'YYYY/MM/DD HH24:MI:SS');
      mst_rec.v_update_date_l   := TO_CHAR(mst_rec.update_date_l,'YYYY/MM/DD HH24:MI:SS');
      mst_rec.v_designate_date  := TO_CHAR(mst_rec.designate_date,'YYYY/MM/DD'); -- 2008/08/20 Add
--
      gt_master_tbl(ln_cnt) := mst_rec;
      ln_cnt := ln_cnt + 1;
--
    END LOOP mst_data_loop;
--
    CLOSE mst_data_cur;
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
      -- �J�[�\�����J���Ă����
      IF (mst_data_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE mst_data_cur;
      END IF;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (mst_data_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE mst_data_cur;
      END IF;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (mst_data_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE mst_data_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END mov_sel_proc;
--
  /**********************************************************************************
   * Procedure Name   : put_csv_data
   * Description      : CSV�t�@�C���ւ̃f�[�^�o��
   ***********************************************************************************/
  PROCEDURE put_csv_data(
    if_file_hand IN            UTL_FILE.FILE_TYPE,
    ir_mst_rec   IN            masters_rec,
    ov_errbuf       OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_csv_data'; -- �v���O������
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
    cv_sep_com      CONSTANT VARCHAR2(1)  := ',';
-- add start ver1.3
    cv_crlf         CONSTANT VARCHAR2(1)  := CHR(13); -- ���s�R�[�h
-- add end ver1.3
--
    -- *** ���[�J���ϐ� ***
    lv_data         VARCHAR2(5000);
    ln_num          NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
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
    -- �f�[�^�쐬
    lv_data := ir_mst_rec.company_name      || cv_sep_com ||                    -- ��Ж�
               ir_mst_rec.data_class        || cv_sep_com ||                    -- �f�[�^���
               ir_mst_rec.v_seq_no          || cv_sep_com ||                    -- �`���p�}��
               ir_mst_rec.ship_no           || cv_sep_com ||                    -- �z��No.
               ir_mst_rec.request_no        || cv_sep_com ||                    -- �˗�No.
               ir_mst_rec.relation_no       || cv_sep_com ||                    -- �֘ANo.
               ir_mst_rec.base_request_no   || cv_sep_com ||                    -- �R�s�[��No.   2008/09/02 Add
               ir_mst_rec.base_ship_no      || cv_sep_com ||                    -- ���z��No.
               ir_mst_rec.vendor_code       || cv_sep_com ||                    -- �����R�[�h
               replace_sep(ir_mst_rec.vendor_name       ) || cv_sep_com ||      -- ����於
               replace_sep(ir_mst_rec.vendor_s_name     ) || cv_sep_com ||      -- ����旪��
               ir_mst_rec.mediation_code    || cv_sep_com ||                    -- �����҃R�[�h
               replace_sep(ir_mst_rec.mediation_name    ) || cv_sep_com ||      -- �����Җ�
               replace_sep(ir_mst_rec.mediation_s_name  ) || cv_sep_com ||      -- �����җ���
               ir_mst_rec.whse_code         || cv_sep_com ||                    -- �q�ɃR�[�h
               replace_sep(ir_mst_rec.whse_name         ) || cv_sep_com ||      -- �q�ɖ�
               replace_sep(ir_mst_rec.whse_s_name       ) || cv_sep_com ||      -- �q�ɗ���
               ir_mst_rec.vendor_site_code  || cv_sep_com ||                    -- �z����R�[�h
               replace_sep(ir_mst_rec.vendor_site_name  ) || cv_sep_com ||      -- �z���於
               replace_sep(ir_mst_rec.vendor_site_s_name) || cv_sep_com ||      -- �z���旪��
               replace_sep(ir_mst_rec.zip               ) || cv_sep_com ||      -- �X�֔ԍ�
               replace_sep(ir_mst_rec.address           ) || cv_sep_com ||      -- �Z��
               replace_sep(ir_mst_rec.phone             ) || cv_sep_com ||      -- �d�b�ԍ�
               ir_mst_rec.carrier_code      || cv_sep_com ||                    -- �^���Ǝ҃R�[�h
               replace_sep(ir_mst_rec.carrier_name      ) || cv_sep_com ||      -- �^���ƎҖ�
               replace_sep(ir_mst_rec.carrier_s_name    ) || cv_sep_com ||      -- �^���Ǝҗ���
               ir_mst_rec.v_ship_date       || cv_sep_com ||                    -- �o�ɓ�
               ir_mst_rec.v_arrival_date    || cv_sep_com ||                    -- ���ɓ�
               ir_mst_rec.arrival_time_from || cv_sep_com ||                    -- ���׎���FROM
               ir_mst_rec.arrival_time_to   || cv_sep_com ||                    -- ���׎���TO
               ir_mst_rec.method_code       || cv_sep_com ||                    -- �z���敪
               ir_mst_rec.div_a             || cv_sep_com ||                    -- �敪�`
               ir_mst_rec.div_b             || cv_sep_com ||                    -- �敪�a
               ir_mst_rec.div_c             || cv_sep_com ||                    -- �敪�b
               ir_mst_rec.instruction_dept  || cv_sep_com ||                    -- �w�������R�[�h
               ir_mst_rec.request_dept      || cv_sep_com ||                    -- �˗������R�[�h
               ir_mst_rec.status            || cv_sep_com ||                    -- �X�e�[�^�X
               ir_mst_rec.notif_status      || cv_sep_com ||                    -- �ʒm�X�e�[�^�X
               replace_sep(ir_mst_rec.div_d             ) || cv_sep_com ||      -- �敪�c
               ir_mst_rec.div_e             || cv_sep_com ||                    -- �敪�d
               ir_mst_rec.div_f             || cv_sep_com ||                    -- �敪�e
               ir_mst_rec.div_g             || cv_sep_com ||                    -- �敪�f
               ir_mst_rec.div_h             || cv_sep_com ||                    -- �敪�g
               ir_mst_rec.info_a            || cv_sep_com ||                    -- ���`
               ir_mst_rec.info_b            || cv_sep_com ||                    -- ���a
               replace_sep(ir_mst_rec.info_c            ) || cv_sep_com ||      -- ���b
               replace_sep(ir_mst_rec.info_d            ) || cv_sep_com ||      -- ���c
               ir_mst_rec.info_e            || cv_sep_com ||                    -- ���d
               replace_sep(ir_mst_rec.description       ) || cv_sep_com ||      -- �E�v
               ir_mst_rec.line_num          || cv_sep_com ||                    -- ����No.
               ir_mst_rec.item_no           || cv_sep_com ||                    -- �i�ڃR�[�h
               replace_sep(ir_mst_rec.item_name         ) || cv_sep_com ||      -- �i�ږ�
               replace_sep(ir_mst_rec.item_s_name       ) || cv_sep_com ||      -- �i�ڗ���
               ir_mst_rec.futai_code        || cv_sep_com ||                    -- �t��
               ir_mst_rec.lot_no            || cv_sep_com ||                    -- ���b�g
               ir_mst_rec.v_lot_date        || cv_sep_com ||                    -- ������
               ir_mst_rec.v_best_bfr_date   || cv_sep_com ||                    -- �ܖ�����
               ir_mst_rec.lot_sign          || cv_sep_com ||                    -- �ŗL�L��
               decimal_round_up(ir_mst_rec.request_qty,3)     || cv_sep_com ||  -- �˗���
               decimal_round_up(ir_mst_rec.instruct_qty,3)    || cv_sep_com ||  -- �w����
               decimal_round_up(ir_mst_rec.num_of_deliver,3)  || cv_sep_com ||  -- �o�ɐ�
               decimal_round_up(ir_mst_rec.ship_to_qty,3)     || cv_sep_com ||  -- ���ɐ�
               decimal_round_up(ir_mst_rec.fix_qty,3)         || cv_sep_com ||  -- �m�萔
               ir_mst_rec.item_um           || cv_sep_com ||                    -- �P��
               decimal_round_up(ir_mst_rec.weight_capacity,0) || cv_sep_com ||  -- �d�ʗe��
               decimal_round_up(ir_mst_rec.frequent_qty,3)    || cv_sep_com ||  -- ����
               ir_mst_rec.frequent_factory  || cv_sep_com ||                    -- �H��R�[�h
               ir_mst_rec.div_i             || cv_sep_com ||                    -- �敪�h
               ir_mst_rec.div_j             || cv_sep_com ||                    -- �敪�i
               ir_mst_rec.div_k             || cv_sep_com ||                    -- �敪�j
               ir_mst_rec.v_designate_date  || cv_sep_com ||                    -- ���t�w��
               ir_mst_rec.info_f            || cv_sep_com ||                    -- ���e
               ir_mst_rec.info_g            || cv_sep_com ||                    -- ���f
               ir_mst_rec.info_h            || cv_sep_com ||                    -- ���g
               ir_mst_rec.info_i            || cv_sep_com ||                    -- ���h
               ir_mst_rec.info_j            || cv_sep_com ||                    -- ���i
               ir_mst_rec.info_k            || cv_sep_com ||                    -- ���j
               ir_mst_rec.info_l            || cv_sep_com ||                    -- ���k
               ir_mst_rec.info_m            || cv_sep_com ||                    -- ���l
               ir_mst_rec.info_n            || cv_sep_com ||                    -- ���m
               ir_mst_rec.info_o            || cv_sep_com ||                    -- ���n
               ir_mst_rec.info_p            || cv_sep_com ||                    -- ���o
               ir_mst_rec.info_q            || cv_sep_com ||                    -- ���p
               ir_mst_rec.amt_a             || cv_sep_com ||                    -- �����`
               ir_mst_rec.amt_b             || cv_sep_com ||                    -- �����a
               ir_mst_rec.amt_c             || cv_sep_com ||                    -- �����b
               ir_mst_rec.amt_d             || cv_sep_com ||                    -- �����c
               ir_mst_rec.amt_e             || cv_sep_com ||                    -- �����d
               ir_mst_rec.amt_f             || cv_sep_com ||                    -- �����e
               ir_mst_rec.amt_g             || cv_sep_com ||                    -- �����f
               ir_mst_rec.amt_h             || cv_sep_com ||                    -- �����g
               ir_mst_rec.amt_i             || cv_sep_com ||                    -- �����h
               ir_mst_rec.amt_j             || cv_sep_com ||                    -- �����i
-- mod start ver1.3
--               ir_mst_rec.v_update_date                                         -- �X�V����
               ir_mst_rec.v_update_date     || cv_crlf                          -- �X�V����
-- mod end ver1.3
               ;
--
    -- �f�[�^�o��
    UTL_FILE.PUT_LINE(if_file_hand,lv_data);
--
--    gn_normal_cnt := gn_normal_cnt + 1;            -- 2008/08/20 Del
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
  END put_csv_data;
--
  /***********************************************************************************
   * Procedure Name   : csv_file_proc
   * Description      : CSV�t�@�C���o��(D-6)
   ***********************************************************************************/
  PROCEDURE csv_file_proc(
    ov_errbuf           OUT NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'csv_file_proc';           -- �v���O������
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
    lv_head_seq       CONSTANT VARCHAR2(2)  := '10';
    lv_line_seq       CONSTANT VARCHAR2(2)  := '20';
--
    lv_joint_word     CONSTANT VARCHAR2(4)   := '_';
    lv_extend_word    CONSTANT VARCHAR2(4)   := '.csv';
--
    -- *** ���[�J���ϐ� ***
    mst_rec         masters_rec;
    k_mst_rec       masters_rec;
    lv_data         VARCHAR2(5000);
    lf_file_hand    UTL_FILE.FILE_TYPE;         -- �t�@�C���E�n���h���̐錾
--
    lb_retcd        BOOLEAN;
    ln_file_size    NUMBER;
    ln_block_size   NUMBER;
    ln_tbl_id       NUMBER;
    ln_len          NUMBER;
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
    -- �t�@�C���p�XNULL
    IF (gr_outbound_rec.directory IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_com_name,
                                            gv_tkn_number_94d_53);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �t�@�C����NULL
    IF (gr_outbound_rec.file_name IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_com_name,
                                            gv_tkn_number_94d_54);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    ln_len := LENGTH(gr_outbound_rec.file_name);
    -- �t�@�C�����̉��H(�t�@�C����-'.CSV'+'_'+''�f�[�^���'+'_'YYYYMMDDHH24MISS'+'.CSV')
    gv_sch_file_name := substr(gr_outbound_rec.file_name,1,ln_len-4)
                        || lv_joint_word
                        || gv_data_class
                        || lv_joint_word
                        || TO_CHAR(SYSDATE,'YYYYMMDDHH24MISS')
                        || lv_extend_word;
--
    -- �t�@�C�����݃`�F�b�N
    UTL_FILE.FGETATTR(gr_outbound_rec.directory,
                      gv_sch_file_name,
                      lb_retcd,
                      ln_file_size,
                      ln_block_size);
--
    -- �t�@�C������
    IF (lb_retcd) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_com_name,
                                            gv_tkn_number_94d_51);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    BEGIN
--
      -- �t�@�C���I�[�v��
      lf_file_hand := UTL_FILE.FOPEN(gr_outbound_rec.directory,
                                     gv_sch_file_name,
                                     'w');
--
      ln_tbl_id := NULL;
--
      <<file_put_loop>>
      FOR i IN gt_master_tbl.FIRST .. gt_master_tbl.LAST LOOP
        mst_rec := gt_master_tbl(i);
--
        IF ((ln_tbl_id IS NULL) OR (ln_tbl_id <> mst_rec.sel_tbl_id)) THEN
          mst_rec.v_seq_no := lv_head_seq;
          ln_tbl_id := mst_rec.sel_tbl_id;
        ELSE
          mst_rec.v_seq_no := lv_line_seq;
          ln_tbl_id := mst_rec.sel_tbl_id;
        END IF;
--
        -- �w�b�_���o��
        IF (mst_rec.v_seq_no = lv_head_seq) THEN
          k_mst_rec := mst_rec;
--
          mst_rec.line_num          := NULL; -- ����No.
          mst_rec.item_no           := NULL; -- �i�ڃR�[�h
          mst_rec.item_name         := NULL; -- �i�ږ�
          mst_rec.item_s_name       := NULL; -- �i�ڗ���
          mst_rec.futai_code        := NULL; -- �t��
          mst_rec.lot_no            := NULL; -- ���b�g
          mst_rec.lot_date          := NULL; -- ������
          mst_rec.best_bfr_date     := NULL; -- �ܖ�����
          mst_rec.lot_sign          := NULL; -- �ŗL�L��
          mst_rec.request_qty       := NULL; -- �˗���
          mst_rec.instruct_qty      := NULL; -- �w����
          mst_rec.num_of_deliver    := NULL; -- �o�ɐ�
          mst_rec.ship_to_qty       := NULL; -- ���ɐ�
          mst_rec.fix_qty           := NULL; -- �m�萔
          mst_rec.item_um           := NULL; -- �P��
          mst_rec.weight_capacity   := NULL; -- �d�ʗe��
          mst_rec.frequent_qty      := NULL; -- ����
          mst_rec.frequent_factory  := NULL; -- �H��R�[�h
          mst_rec.div_i             := NULL; -- �敪�h
          mst_rec.div_j             := NULL; -- �敪�i
          mst_rec.div_k             := NULL; -- �敪�j
          mst_rec.designate_date    := NULL; -- ���t�w��
          mst_rec.info_f            := NULL; -- ���e
          mst_rec.info_g            := NULL; -- ���f
          mst_rec.info_h            := NULL; -- ���g
          mst_rec.info_i            := NULL; -- ���h
          mst_rec.info_j            := NULL; -- ���i
          mst_rec.info_k            := NULL; -- ���j
          mst_rec.info_l            := NULL; -- ���k
          mst_rec.info_m            := NULL; -- ���l
          mst_rec.info_n            := NULL; -- ���m
          mst_rec.info_o            := NULL; -- ���n
          mst_rec.info_p            := NULL; -- ���o
          mst_rec.info_q            := NULL; -- ���p
          mst_rec.amt_a             := NULL; -- �����`
          mst_rec.amt_b             := NULL; -- �����a
          mst_rec.amt_c             := NULL; -- �����b
          mst_rec.amt_d             := NULL; -- �����c
          mst_rec.amt_e             := NULL; -- �����d
          mst_rec.amt_f             := NULL; -- �����e
          mst_rec.amt_g             := NULL; -- �����f
          mst_rec.amt_h             := NULL; -- �����g
          mst_rec.amt_i             := NULL; -- �����h
          mst_rec.amt_j             := NULL; -- �����i
--
          mst_rec.v_lot_date        := NULL; -- ������
          mst_rec.v_best_bfr_date   := NULL; -- �ܖ�����
          mst_rec.v_designate_date  := NULL; -- ���t�w��
--
          mst_rec.description   := mst_rec.head_description;
          mst_rec.v_update_date := mst_rec.v_update_date_h;
--
          -- �f�[�^�o��
          put_csv_data(lf_file_hand,
                       mst_rec,
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
          IF (lv_retcode <> gv_status_normal) THEN
            RAISE global_api_expt;
          END IF;
          mst_rec := k_mst_rec;
          mst_rec.v_seq_no := lv_line_seq;
        END IF;
--
        -- ���ו��o��
        IF (mst_rec.v_seq_no = lv_line_seq) THEN
          mst_rec.relation_no          := NULL; -- �֘ANo.
          mst_rec.base_request_no      := NULL; -- �R�s�[��No.   2008/09/02 Add
          mst_rec.base_ship_no         := NULL; -- ���z��No.
          mst_rec.vendor_code          := NULL; -- �����R�[�h
          mst_rec.vendor_name          := NULL; -- ����於
          mst_rec.vendor_s_name        := NULL; -- ����旪��
          mst_rec.mediation_code       := NULL; -- �����҃R�[�h
          mst_rec.mediation_name       := NULL; -- �����Җ�
          mst_rec.mediation_s_name     := NULL; -- �����җ���
          mst_rec.whse_code            := NULL; -- �q�ɃR�[�h
          mst_rec.whse_name            := NULL; -- �q�ɖ�
          mst_rec.whse_s_name          := NULL; -- �q�ɗ���
          mst_rec.vendor_site_code     := NULL; -- �z����R�[�h
          mst_rec.vendor_site_name     := NULL; -- �z���於
          mst_rec.vendor_site_s_name   := NULL; -- �z���旪��
          mst_rec.zip                  := NULL; -- �X�֔ԍ�
          mst_rec.address              := NULL; -- �Z��
          mst_rec.phone                := NULL; -- �d�b�ԍ�
          mst_rec.carrier_code         := NULL; -- �^���Ǝ҃R�[�h
          mst_rec.carrier_name         := NULL; -- �^���ƎҖ�
          mst_rec.carrier_s_name       := NULL; -- �^���Ǝҗ���
          mst_rec.ship_date            := NULL; -- �o�ɓ�
          mst_rec.arrival_date         := NULL; -- ���ɓ�
          mst_rec.arrival_time_from    := NULL; -- ���׎���FROM
          mst_rec.arrival_time_to      := NULL; -- ���׎���TO
          mst_rec.method_code          := NULL; -- �z���敪
          mst_rec.div_a                := NULL; -- �敪�`
          mst_rec.div_b                := NULL; -- �敪�a
          mst_rec.div_c                := NULL; -- �敪�b
          mst_rec.instruction_dept     := NULL; -- �w�������R�[�h
          mst_rec.request_dept         := NULL; -- �˗������R�[�h
          mst_rec.status               := NULL; -- �X�e�[�^�X
          mst_rec.notif_status         := NULL; -- �ʒm�X�e�[�^�X
          mst_rec.div_d                := NULL; -- �敪�c
          mst_rec.div_e                := NULL; -- �敪�d
          mst_rec.div_f                := NULL; -- �敪�e
          mst_rec.div_g                := NULL; -- �敪�f
          mst_rec.div_h                := NULL; -- �敪�g
          mst_rec.info_a               := NULL; -- ���`
          mst_rec.info_b               := NULL; -- ���a
          mst_rec.info_c               := NULL; -- ���b
          mst_rec.info_d               := NULL; -- ���c
          mst_rec.info_e               := NULL; -- ���d
--
          mst_rec.v_ship_date          := NULL; -- �o�ɓ�
          mst_rec.v_arrival_date       := NULL; -- ���ɓ�
--
          mst_rec.description   := mst_rec.line_description;
          mst_rec.v_update_date := mst_rec.v_update_date_l;
--
          -- �f�[�^�o��
          put_csv_data(lf_file_hand,
                       mst_rec,
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
          IF (lv_retcode <> gv_status_normal) THEN
            RAISE global_api_expt;
          END IF;
        END IF;
      END LOOP file_put_loop;
--
      -- �t�@�C���N���[�Y
      UTL_FILE.FCLOSE(lf_file_hand);
--
    EXCEPTION
      WHEN UTL_FILE.INVALID_PATH THEN       -- �t�@�C���p�X�s���G���[
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_com_name,
                                              gv_tkn_number_94d_50);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN UTL_FILE.INVALID_FILENAME THEN   -- �t�@�C�����s���G���[
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_com_name,
                                              gv_tkn_number_94d_51);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN UTL_FILE.ACCESS_DENIED OR        -- �t�@�C���A�N�Z�X�����G���[
           UTL_FILE.WRITE_ERROR THEN        -- �������݃G���[
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_com_name,
                                              gv_tkn_number_94d_52);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END csv_file_proc;
--
  /**********************************************************************************
   * Procedure Name   : workflow_start
   * Description      : ���[�N�t���[�ʒm����(D-7)
   ***********************************************************************************/
  PROCEDURE workflow_start(
    ov_errbuf             OUT NOCOPY VARCHAR2,          -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,          -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'workflow_start'; -- �v���O������
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
    lv_itemkey                VARCHAR2(30);
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
    gr_outbound_rec.file_name := gv_sch_file_name;
--
    --WF�^�C�v�ň�ӂƂȂ�WF�L�[���擾
    SELECT TO_CHAR(xxcmn_wf_key_s1.NEXTVAL)
    INTO   lv_itemkey
    FROM   DUAL;
--
    BEGIN
--
      --WF�v���Z�X���쐬
      WF_ENGINE.CREATEPROCESS(gr_outbound_rec.wf_name, lv_itemkey, gr_outbound_rec.wf_name);
--
      --WF�I�[�i�[��ݒ�
      WF_ENGINE.SETITEMOWNER(gr_outbound_rec.wf_name, lv_itemkey, gr_outbound_rec.wf_owner);
--
      --WF������ݒ�
      WF_ENGINE.SETITEMATTRTEXT(gr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'FILE_NAME',
                                  gr_outbound_rec.directory|| ',' ||gr_outbound_rec.file_name );
      -- �ʒm�惆�[�U�[01
      WF_ENGINE.SETITEMATTRTEXT(gr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD01',
                                  gr_outbound_rec.user_cd01);
      -- �ʒm�惆�[�U�[02
      WF_ENGINE.SETITEMATTRTEXT(gr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD02',
                                  gr_outbound_rec.user_cd02);
      -- �ʒm�惆�[�U�[03
      WF_ENGINE.SETITEMATTRTEXT(gr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD03',
                                  gr_outbound_rec.user_cd03);
      -- �ʒm�惆�[�U�[04
      WF_ENGINE.SETITEMATTRTEXT(gr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD04',
                                  gr_outbound_rec.user_cd04);
      -- �ʒm�惆�[�U�[05
      WF_ENGINE.SETITEMATTRTEXT(gr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD05',
                                  gr_outbound_rec.user_cd05);
      -- �ʒm�惆�[�U�[06
      WF_ENGINE.SETITEMATTRTEXT(gr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD06',
                                  gr_outbound_rec.user_cd06);
      -- �ʒm�惆�[�U�[07
      WF_ENGINE.SETITEMATTRTEXT(gr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD07',
                                  gr_outbound_rec.user_cd07);
      -- �ʒm�惆�[�U�[08
      WF_ENGINE.SETITEMATTRTEXT(gr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD08',
                                  gr_outbound_rec.user_cd08);
      -- �ʒm�惆�[�U�[09
      WF_ENGINE.SETITEMATTRTEXT(gr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD09',
                                  gr_outbound_rec.user_cd09);
      -- �ʒm�惆�[�U�[10
      WF_ENGINE.SETITEMATTRTEXT(gr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD10',
                                  gr_outbound_rec.user_cd10);
--
      WF_ENGINE.SETITEMATTRTEXT(gr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'FILE_DISP_NAME',
                                  gr_outbound_rec.file_display_name);
--
      --WF�v���Z�X���N��
      WF_ENGINE.STARTPROCESS(gr_outbound_rec.wf_name, lv_itemkey);
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_com_name,
                                              gv_tkn_number_94d_55);
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
  END workflow_start;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_wf_ope_div        IN            VARCHAR2,  --  1.�����敪          (�K�{)
    iv_wf_class          IN            VARCHAR2,  --  2.�Ώ�              (�K�{)
    iv_wf_notification   IN            VARCHAR2,  --  3.����              (�K�{)
    iv_data_class        IN            VARCHAR2,  --  4.�f�[�^���        (�K�{)
    iv_ship_no_from      IN            VARCHAR2,  --  5.�z��No.FROM       (�C��)
    iv_ship_no_to        IN            VARCHAR2,  --  6.�z��No.TO         (�C��)
    iv_req_no_from       IN            VARCHAR2,  --  7.�˗�No.FROM       (�C��)
    iv_req_no_to         IN            VARCHAR2,  --  8.�˗�No.TO         (�C��)
    iv_vendor_code       IN            VARCHAR2,  --  9.�����            (�C��)
    iv_mediation         IN            VARCHAR2,  -- 10.������            (�C��)
    iv_location_code     IN            VARCHAR2,  -- 11.�o�ɑq��          (�C��)
    iv_arvl_code         IN            VARCHAR2,  -- 12.���ɑq��          (�C��)
    iv_vendor_site_code  IN            VARCHAR2,  -- 13.�z����            (�C��)
    iv_carrier_code      IN            VARCHAR2,  -- 14.�^���Ǝ�          (�C��)
    iv_ship_date_from    IN            VARCHAR2,  -- 15.�[����/�o�ɓ�FROM (�K�{)
    iv_ship_date_to      IN            VARCHAR2,  -- 16.�[����/�o�ɓ�TO   (�K�{)
    iv_arrival_date_from IN            VARCHAR2,  -- 17.���ɓ�FROM        (�C��)
    iv_arrival_date_to   IN            VARCHAR2,  -- 18.���ɓ�TO          (�C��)
    iv_instruction_dept  IN            VARCHAR2,  -- 19.�w������          (�C��)
    iv_item_no           IN            VARCHAR2,  -- 20.�i��              (�C��)
    iv_update_time_from  IN            VARCHAR2,  -- 21.�X�V����FROM      (�C��)
    iv_update_time_to    IN            VARCHAR2,  -- 22.�X�V����TO        (�C��)
    iv_prod_class        IN            VARCHAR2,  -- 23.���i�敪          (�C��)
    iv_item_class        IN            VARCHAR2,  -- 24.�i�ڋ敪          (�C��)
    iv_sec_class         IN            VARCHAR2,  -- 25.�Z�L�����e�B�敪  (�K�{)
    ov_errbuf               OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_tbl_name_pha   CONSTANT VARCHAR2(200) := '�����w�b�_';
    lv_tbl_name_oha   CONSTANT VARCHAR2(200) := '�󒍃w�b�_�A�h�I��';
    lv_tbl_name_mov   CONSTANT VARCHAR2(200) := '�ړ��˗�/�w���w�b�_�A�h�I��';
--
    -- *** ���[�J���ϐ� ***
    lv_tbl_name     VARCHAR2(200);
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
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    --*********************************************
    --***   ���̓p�����[�^�`�F�b�N����(D-1)     ***
    --*********************************************
    parameter_check(
      iv_wf_ope_div,        --  1.�����敪
      iv_wf_class,          --  2.�Ώ�
      iv_wf_notification,   --  3.����
      iv_data_class,        --  4.�f�[�^���
      iv_ship_no_from,      --  5.�z��No.FROM
      iv_ship_no_to,        --  6.�z��No.TO
      iv_req_no_from,       --  7.�˗�No.FROM
      iv_req_no_to,         --  8.�˗�No.TO
      iv_vendor_code,       --  9.�����
      iv_mediation,         -- 10.������
      iv_location_code,     -- 11.�o�ɑq��
      iv_arvl_code,         -- 12.���ɑq��
      iv_vendor_site_code,  -- 13.�z����
      iv_carrier_code,      -- 14.�^���Ǝ�
      iv_ship_date_from,    -- 15.�[����/�o�ɓ�FROM
      iv_ship_date_to,      -- 16.�[����/�o�ɓ�TO
      iv_arrival_date_from, -- 17.���ɓ�FROM
      iv_arrival_date_to,   -- 18.���ɓ�TO
      iv_instruction_dept,  -- 19.�w������
      iv_item_no,           -- 20.�i��
      iv_update_time_from,  -- 21.�X�V����FROM
      iv_update_time_to,    -- 22.�X�V����TO
      iv_prod_class,        -- 23.���i�敪
      iv_item_class,        -- 24.�i�ڋ敪
      iv_sec_class,         -- 25.�Z�L�����e�B�敪
      lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �f�[�^��ʁF����
    IF (iv_data_class = gv_data_class_pha) THEN
--
      --*********************************************
      --***       �������擾����(D-4)           ***
      --*********************************************
      pha_sel_proc(
        lv_errbuf,       -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,      -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �f�[�^��ʁF�x��
    ELSIF (iv_data_class = gv_data_class_oha) THEN
--
      --*********************************************
      --***       �x�����擾����(D-4)           ***
      --*********************************************
      oha_sel_proc(
        lv_errbuf,       -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,      -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �f�[�^��ʁF�ړ�
    ELSIF (iv_data_class = gv_data_class_mov) THEN
--
      --*********************************************
      --***       �ړ����擾����(D-5)           ***
      --*********************************************
      mov_sel_proc(
        lv_errbuf,       -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,      -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    END IF;
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �f�[�^����
    IF (gt_master_tbl.COUNT > 0) THEN
      --*********************************************
      --***        CSV�t�@�C���o��(D-6)           ***
      --*********************************************
      csv_file_proc(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    -- �f�[�^�Ȃ�
    ELSE
--
      -- �������
      IF (gv_data_class = gv_data_class_pha) THEN
        lv_tbl_name := lv_tbl_name_pha;
--
      -- �x�����
      ELSIF (gv_data_class = gv_data_class_oha) THEN
        lv_tbl_name := lv_tbl_name_oha;
--
      -- �ړ����
      ELSE
        lv_tbl_name := lv_tbl_name_mov;
      END IF;
--
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_94d_05,
                                            gv_tkn_table,
                                            lv_tbl_name);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      lv_retcode := gv_status_warn;
    END IF;
--
    IF (lv_retcode = gv_status_normal) THEN
      --*********************************************
      --***       Workflow�ʒm����(D-7)           ***
      --*********************************************
      workflow_start(
        lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    ELSE
      ov_retcode := lv_retcode;
    END IF;
--
    gn_target_cnt := gt_master_tbl.COUNT;
--
    gn_normal_cnt := gn_target_cnt;           -- 2008/08/20 Add
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
    errbuf                  OUT NOCOPY VARCHAR2,  --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode                 OUT NOCOPY VARCHAR2,  --   ���^�[���E�R�[�h    --# �Œ� #
    iv_wf_ope_div        IN            VARCHAR2,  --  1.�����敪          (�K�{)
    iv_wf_class          IN            VARCHAR2,  --  2.�Ώ�              (�K�{)
    iv_wf_notification   IN            VARCHAR2,  --  3.����              (�K�{)
    iv_data_class        IN            VARCHAR2,  --  4.�f�[�^���        (�K�{)
    iv_ship_no_from      IN            VARCHAR2,  --  5.�z��No.FROM       (�C��)
    iv_ship_no_to        IN            VARCHAR2,  --  6.�z��No.TO         (�C��)
    iv_req_no_from       IN            VARCHAR2,  --  7.�˗�No.FROM       (�C��)
    iv_req_no_to         IN            VARCHAR2,  --  8.�˗�No.TO         (�C��)
    iv_vendor_code       IN            VARCHAR2,  --  9.�����            (�C��)
    iv_mediation         IN            VARCHAR2,  -- 10.������            (�C��)
    iv_location_code     IN            VARCHAR2,  -- 11.�o�ɑq��          (�C��)
    iv_arvl_code         IN            VARCHAR2,  -- 12.���ɑq��          (�C��)
    iv_vendor_site_code  IN            VARCHAR2,  -- 13.�z����            (�C��)
    iv_carrier_code      IN            VARCHAR2,  -- 14.�^���Ǝ�          (�C��)
    iv_ship_date_from    IN            VARCHAR2,  -- 15.�[����/�o�ɓ�FROM (�K�{)
    iv_ship_date_to      IN            VARCHAR2,  -- 16.�[����/�o�ɓ�TO   (�K�{)
    iv_arrival_date_from IN            VARCHAR2,  -- 17.���ɓ�FROM        (�C��)
    iv_arrival_date_to   IN            VARCHAR2,  -- 18.���ɓ�TO          (�C��)
    iv_instruction_dept  IN            VARCHAR2,  -- 19.�w������          (�C��)
    iv_item_no           IN            VARCHAR2,  -- 20.�i��              (�C��)
    iv_update_time_from  IN            VARCHAR2,  -- 21.�X�V����FROM      (�C��)
    iv_update_time_to    IN            VARCHAR2,  -- 22.�X�V����TO        (�C��)
    iv_prod_class        IN            VARCHAR2,  -- 23.���i�敪          (�C��)
    iv_item_class        IN            VARCHAR2,  -- 24.�i�ڋ敪          (�C��)
    iv_sec_class         IN            VARCHAR2   -- 25.�Z�L�����e�B�敪  (�K�{)
    )
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
      iv_wf_ope_div,        --  1.�����敪
      iv_wf_class,          --  2.�Ώ�
      iv_wf_notification,   --  3.����
      iv_data_class,        --  4.�f�[�^���
      iv_ship_no_from,      --  5.�z��No.FROM
      iv_ship_no_to,        --  6.�z��No.TO
      iv_req_no_from,       --  7.�˗�No.FROM
      iv_req_no_to,         --  8.�˗�No.TO
      iv_vendor_code,       --  9.�����
      iv_mediation,         -- 10.������
      iv_location_code,     -- 11.�o�ɑq��
      iv_arvl_code,         -- 12.���ɑq��
      iv_vendor_site_code,  -- 13.�z����
      iv_carrier_code,      -- 14.�^���Ǝ�
      iv_ship_date_from,    -- 15.�[����/�o�ɓ�FROM
      iv_ship_date_to,      -- 16.�[����/�o�ɓ�TO
      iv_arrival_date_from, -- 17.���ɓ�FROM
      iv_arrival_date_to,   -- 18.���ɓ�TO
      iv_instruction_dept,  -- 19.�w������
      iv_item_no,           -- 20.�i��
      iv_update_time_from,  -- 21.�X�V����FROM
      iv_update_time_to,    -- 22.�X�V����TO
      iv_prod_class,        -- 23.���i�敪
      iv_item_class,        -- 24.�i�ڋ敪
      iv_sec_class,         -- 25.�Z�L�����e�B�敪
      lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
END xxpo940004c;
/
