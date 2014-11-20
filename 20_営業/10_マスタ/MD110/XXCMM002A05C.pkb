CREATE OR REPLACE PACKAGE BODY XXCMM002A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM002A05C(body)
 * Description      : �d����}�X�^�f�[�^�A�g
 * MD.050           : �d����}�X�^�f�[�^�A�g MD050_CMM_002_A05
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ���������v���V�[�W��(A-1)
 *  get_u_people_data      �V�K�o�^�ȊO�̎Ј��f�[�^�擾�v���V�[�W��(A-2)
 *  update_output_csv      CSV�t�@�C���o��(�X�V)�v���V�[�W��(A-6)
 *  get_i_people_data      �V�K�o�^�̎Ј��f�[�^�擾�v���V�[�W��(A-7)
 *  add_output_csv         CSV�t�@�C���o��(�V�K�o�^)�v���V�[�W��(A-9)
 *  delete_table           �d����]�ƈ���񒆊�I/F�e�[�u���f�[�^�폜�v���V�[�W��(A-10)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/20    1.0   SCS ���� �M�q    ����쐬
 *  2009/03/03    1.1   SCS �g�� ����    �V�K�A�g���A�d����T�C�g��ATTRIBUTE_CATEGORY��
 *                                       ORG_ID��ݒ肷��悤�C��
 *  2009/04/21    1.2   SCS �g�� ����    ��QT1_0255, T1_0388, T1_0438 �Ή�
 *  2009/04/24          SCS �g�� ����    �d����o�^�ς݁A�T�C�g�u��Ёv���o�^���̑Ή�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg                VARCHAR2(2000);
  gn_target_cnt             NUMBER;                    -- �Ώی���
  gn_normal_cnt             NUMBER;                    -- ���팏��
  gn_error_cnt              NUMBER;                    -- �G���[����
  gn_warn_cnt               NUMBER;                    -- �X�L�b�v����
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
  lock_expt                 EXCEPTION;        -- ���b�N(�r�W�[)�G���[
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCMM002A05C';                    -- �p�b�P�[�W��
  -- �v���t�@�C��
  cv_filepath               CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_OUT_DIR';           -- �A�g�pCSV�t�@�C���o�͐�
  cv_filename               CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_OUT_FILE';          -- �A�g�pCSV�t�@�C����
  cv_cal_code               CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_SYS_CAL_CODE';      -- �V�X�e���ғ����J�����_�R�[�h�l
  cv_jyugyoin_kbn_s         CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_JYUGYOIN_KBN_S';    -- �]�ƈ��敪�̐��Ј��l
  cv_jyugyoin_kbn_d         CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_JYUGYOIN_KBN_D';    -- �]�ƈ��敪�̃_�~�[�l
  cv_vendor_type            CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_VENDOR_TYPE';       -- �d����^�C�v
  cv_country                CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_COUNTRY';           -- ���L��
  cv_accts_pay_ccid         CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_ACCTS_PAY_CCID';    -- ������Ȗ�ID
  cv_prepay_ccid            CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_PREPAY_CCID';       -- �O���^����������Ȗ�ID
  cv_group_type_nm          CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_GROUP_TYPE_NM';     -- �x���O���[�v�^�C�v��
  cv_pay_bumon_cd           CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_PAY_BUMON_CD';      -- �{�Б��U���x������R�[�h
  cv_pay_bumon_nm           CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_PAY_BUMON_NM';      -- �{�Б��U���x�����喼��
  cv_pay_method_nm          CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_PAY_METHOD_NM';     -- �{�Б��U���x�����@����
  cv_pay_bank               CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_PAY_BANK';          -- �{�Б��U���x��������s�x�X
  cv_koguti_genkin_nm       CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_KOGUTI_GENKIN_NM';  -- ���������x�����@����
  cv_pay_type_nm            CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_PAY_TYPE_NM';       -- �x����ޖ���
  cv_terms_id               CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_TERMS_ID';          -- �x������
-- Ver1.2  2009/04/21  Add  ��Q�FT1_0438�Ή�  ��s�萔�����S�҂�ǉ��u����(I)�v
  cv_bank_charge_bearer     CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_BANK_CHARGE';       -- ��s�萔�����S��
-- End Ver1.2
  cv_bank_number            CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_BANK_NUMBER';       -- �����_�~�[��s�x�X�R�[�h
  cv_bank_num               CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_BANK_NUM';          -- �����_�~�[��s�R�[�h
  cv_bank_nm                CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_BANK_NM';           -- �����_�~�[��s����
  cv_shiten_nm              CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_SHITEN_NM';         -- �����_�~�[��s�x�X����
  cv_account_num            CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_ACCOUNT_NUM';       -- �����_�~�[�����ԍ�
  cv_currency_cd            CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_CURRENCY_CD';       -- �ʉ݃R�[�h
  cv_account_type           CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_ACCOUNT_TYPE';      -- �����_�~�[�������
  cv_holder_nm              CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_HOLDER_NM';         -- �����_�~�[�������`�l��
  cv_holder_alt_nm          CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_HOLDER_ALT_NM';     -- �����_�~�[�������`�l�J�i��
  cv_address_nm1            CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_ADDRESS1_NM';       -- ���ݒn1
  cv_address_nm2            CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_ADDRESS2_NM';       -- ���ݒn2
  -- �g�[�N��
  cv_tkn_profile            CONSTANT VARCHAR2(10)  := 'NG_PROFILE';                      -- �v���t�@�C����
  cv_tkn_filepath_nm        CONSTANT VARCHAR2(20)  := 'CSV�t�@�C���o�͐�';
  cv_tkn_filename_nm        CONSTANT VARCHAR2(20)  := 'CSV�t�@�C����';
  cv_tkn_cal_code           CONSTANT VARCHAR2(30)  := '�V�X�e���ғ����J�����_�R�[�h�l';
  cv_tkn_jyugoin_kbn_s_nm   CONSTANT VARCHAR2(20)  := '�]�ƈ��敪�̐��Ј��l';
  cv_tkn_jyugoin_kbn_d_nm   CONSTANT VARCHAR2(20)  := '�]�ƈ��敪�̃_�~�[�l';
  cv_tkn_vendor_type_nm     CONSTANT VARCHAR2(20)  := '�d����^�C�v';
  cv_tkn_country_nm         CONSTANT VARCHAR2(10)  := '���L��';
  cv_tkn_accts_pay_ccid_nm  CONSTANT VARCHAR2(20)  := '������Ȗ�ID';
  cv_tkn_prepay_ccid_nm     CONSTANT VARCHAR2(22)  := '�O���^����������Ȗ�ID';
  cv_tkn_group_type_nm      CONSTANT VARCHAR2(20)  := '�x���O���[�v�^�C�v��';
  cv_tkn_pay_bumon_cd_nm    CONSTANT VARCHAR2(24)  := '�{�Б��U���x������R�[�h';
  cv_tkn_pay_bumon_nm       CONSTANT VARCHAR2(22)  := '�{�Б��U���x�����喼��';
  cv_tkn_pay_method_nm      CONSTANT VARCHAR2(22)  := '�{�Б��U���x�����@����';
  cv_tkn_pay_bank_nm        CONSTANT VARCHAR2(26)  := '�{�Б��U���x��������s�x�X';
  cv_tkn_koguti_genkin_nm   CONSTANT VARCHAR2(20)  := '���������x�����@����';
  cv_tkn_pay_type_nm        CONSTANT VARCHAR2(20)  := '�x����ޖ���';
  cv_tkn_terms_id_nm        CONSTANT VARCHAR2(10)  := '�x������';
-- Ver1.2  2009/04/21  Add  ��Q�FT1_0438�Ή�  ��s�萔�����S�҂�ǉ�
  cv_tkn_bank_charge        CONSTANT VARCHAR2(30)  := '��s�萔�����S��';
-- End Ver1.2
  cv_tkn_bank_number_nm     CONSTANT VARCHAR2(24)  := '�����_�~�[��s�x�X�R�[�h';
  cv_tkn_bank_num_nm        CONSTANT VARCHAR2(20)  := '�����_�~�[��s�R�[�h';
  cv_tkn_bank_nm            CONSTANT VARCHAR2(20)  := '�����_�~�[��s����';
  cv_tkn_shiten_nm          CONSTANT VARCHAR2(22)  := '�����_�~�[��s�x�X����';
  cv_tkn_account_num_nm     CONSTANT VARCHAR2(20)  := '�����_�~�[�����ԍ�';
  cv_tkn_currency_cd_nm     CONSTANT VARCHAR2(10)  := '�ʉ݃R�[�h';
  cv_tkn_account_type_nm    CONSTANT VARCHAR2(20)  := '�����_�~�[�������';
  cv_tkn_holder_nm          CONSTANT VARCHAR2(22)  := '�����_�~�[�������`�l��';
  cv_tkn_holder_alt_nm      CONSTANT VARCHAR2(26)  := '�����_�~�[�������`�l�J�i��';
  cv_tkn_address_nm1        CONSTANT VARCHAR2(10)  := '���ݒn1';
  cv_tkn_address_nm2        CONSTANT VARCHAR2(10)  := '���ݒn2';
  cv_tkn_word               CONSTANT VARCHAR2(10)  := 'NG_WORD';                    -- ���ږ�
  cv_tkn_word1              CONSTANT VARCHAR2(20)  := '�Ј��ԍ�';
  cv_tkn_word2              CONSTANT VARCHAR2(10)  := '�A���� : ';
  cv_tkn_word3              CONSTANT VARCHAR2(23)  := '�A�x���O���[�v�R�[�h : ';
  cv_tkn_data               CONSTANT VARCHAR2(10)  := 'NG_DATA';                    -- �f�[�^
  cv_tkn_filename           CONSTANT VARCHAR2(10)  := 'FILE_NAME';                  -- �t�@�C����
  cv_tkn_table              CONSTANT VARCHAR2(10)  := 'NG_TABLE';                   -- �e�[�u��
  cv_tkn_length             CONSTANT VARCHAR2(10)  := 'NG_LENGTH';                  -- ������
  cv_tkn_table_nm           CONSTANT VARCHAR2(31)  := '�d����]�ƈ���񒆊�I/F�e�[�u��';
  -- ���b�Z�[�W�敪
  cv_msg_kbn_cmm            CONSTANT VARCHAR2(5)   := 'XXCMM';
  cv_msg_kbn_ccp            CONSTANT VARCHAR2(5)   := 'XXCCP';
  -- ���b�Z�[�W
  cv_msg_90008              CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90008';           -- �R���J�����g���̓p�����[�^�Ȃ�
  cv_msg_00002              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00002';           -- �v���t�@�C���擾�G���[
  cv_msg_05102              CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-05102';           -- �t�@�C�����o�̓��b�Z�[�W
  cv_msg_00214              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00214';           -- �����������G���[
  cv_msg_00003              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00003';           -- �t�@�C���p�X�s���G���[
  cv_msg_00018              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00018';           -- �Ɩ����t�擾�G���[
  cv_msg_00036              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00036';           -- ���̃V�X�e���ғ����擾�G���[
  cv_msg_00008              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00008';           -- ���b�N�擾NG���b�Z�[�W
  cv_msg_00208              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00208';           -- �Ζ��n���_�R�[�h(�V)�����̓G���[
  cv_msg_00211              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00211';           -- �ȑO�̎x���O���[�v�擾�G���[
  cv_msg_00215              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00215';           -- �x���O���[�v�R�[�h�����������G���[
  cv_msg_00212              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00212';           -- �d����}�X�^�f�[�^�擾�G���[
  cv_msg_00213              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00213';           -- �d����T�C�g�}�X�^�f�[�^�擾�G���[
  cv_msg_00209              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00209';           -- �]�ƈ��ԍ��d�����b�Z�[�W
  cv_msg_00007              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00007';           -- �t�@�C���A�N�Z�X�����G���[
  cv_msg_00009              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00009';           -- CSV�f�[�^�o�̓G���[
  cv_msg_00012              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00012';           -- �f�[�^�폜�G���[
  -- �Œ�l(�ݒ�l)
  cv_insert_flg             CONSTANT VARCHAR2(1)   := 'I';                          -- �ǉ��X�V�t���O(�V�K)
  cv_update_flg             CONSTANT VARCHAR2(1)   := 'U';                          -- �ǉ��X�V�t���O(�X�V)
  cv_status_flg             CONSTANT VARCHAR2(1)   := '0';                          -- �X�e�[�^�X�t���O
  cv_address_length         CONSTANT NUMBER(2)     := 35;                           -- �v���t�@�C��(���ݒn1�A2)�̕�����
  cv_pay_group_length       CONSTANT NUMBER(2)     := 25;                           -- �x���O���[�v�R�[�h�̕�����
  cv_9000                   CONSTANT VARCHAR2(4)   := '9000';                       -- CSV�o�͎��Ɏg�p���镶����
--
-- Ver1.1 2009/03/03 Mod  �R���e�L�X�g��ORG_ID��ݒ�
  -- ORG_ID
  gn_org_id                 CONSTANT NUMBER        := FND_GLOBAL.ORG_ID;
-- End
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
-- Ver1.2  2009/04/21  Add  ��Q�FT1_0255�AT1_0388�Ή�
  cv_site_code_comp         po_vendor_sites.vendor_site_code%TYPE := '���';
-- End Ver1.2
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_filepath               VARCHAR2(255);        -- �A�g�pCSV�t�@�C���o�͐�
  gv_filename               VARCHAR2(255);        -- �A�g�pCSV�t�@�C����
  gv_jyugyoin_kbn_s         VARCHAR2(10);         -- �]�ƈ��敪�̐��Ј��l
  gv_jyugyoin_kbn_d         VARCHAR2(10);         -- �]�ƈ��敪�̃_�~�[�l
  gv_cal_code               VARCHAR2(30);         -- �V�X�e���ғ����J�����_�R�[�h�l
  gv_vendor_type            VARCHAR2(50);         -- �d����^�C�v
  gv_country                VARCHAR2(50);         -- ���L��
  gv_accts_pay_ccid         VARCHAR2(50);         -- ������Ȗ�ID
  gv_prepay_ccid            VARCHAR2(50);         -- �O���^����������Ȗ�ID
  gv_group_type_nm          VARCHAR2(50);         -- �x���O���[�v�^�C�v��
  gv_pay_bumon_cd           VARCHAR2(50);         -- �{�Б��U���x������R�[�h
  gv_pay_bumon_nm           VARCHAR2(50);         -- �{�Б��U���x�����喼��
  gv_pay_method_nm          VARCHAR2(50);         -- �{�Б��U���x�����@����
  gv_pay_bank               VARCHAR2(50);         -- �{�Б��U���x��������s�x�X
  gv_koguti_genkin_nm       VARCHAR2(50);         -- ���������x�����@����
  gv_pay_type_nm            VARCHAR2(50);         -- �x����ޖ���
  gv_terms_id               VARCHAR2(50);         -- �x������
  gv_bank_number            VARCHAR2(50);         -- �����_�~�[��s�x�X�R�[�h
  gv_bank_num               VARCHAR2(50);         -- �����_�~�[��s�R�[�h
  gv_bank_nm                VARCHAR2(80);         -- �����_�~�[��s����
  gv_shiten_nm              VARCHAR2(80);         -- �����_�~�[��s�x�X����
  gv_account_num            VARCHAR2(50);         -- �����_�~�[�����ԍ�
  gv_currency_cd            VARCHAR2(30);         -- �ʉ݃R�[�h
  gv_account_type           VARCHAR2(50);         -- �����_�~�[�������
  gv_holder_nm              VARCHAR2(240);        -- �����_�~�[�������`�l��
  gv_holder_alt_nm          VARCHAR2(150);        -- �����_�~�[�������`�l�J�i��
  gv_address_nm1            VARCHAR2(240);        -- ���ݒn1
  gv_address_nm2            VARCHAR2(240);        -- ���ݒn2
  gd_process_date           DATE;                 -- �Ɩ����t
  gd_select_next_date       DATE;                 -- �擾���̃V�X�e���ғ���
  gf_file_hand              UTL_FILE.FILE_TYPE;   -- �t�@�C���E�n���h���̐錾
  gn_target_add_cnt         NUMBER;               -- �V�K�o�^�̑Ώی���
  gn_target_update_cnt      NUMBER;               -- �V�K�o�^�ȊO�̑Ώی���
  gv_warn_flg               VARCHAR2(1);          -- �x���t���O
  -- �o�͍���
  gn_v_interface_id         NUMBER(15);           -- �d����C���^�[�t�F�[�XID
  gv_v_vendor_name          VARCHAR2(80);         -- �d����d���於
  gv_v_segment1             VARCHAR2(30);         -- �d����d����ԍ�
  gn_v_employee_id          NUMBER(22);           -- �d����]�ƈ�ID
  gv_v_vendor_type          VARCHAR2(30);         -- �d����d����^�C�v
  gn_v_terms_id             NUMBER(22);           -- �d����x������
  gv_v_pay_group            VARCHAR2(25);         -- �d����x���O���[�v�R�[�h
  gn_v_invoice_amount_limit NUMBER(22);           -- �d���搿�����x�z
  gn_v_accts_pay_ccid       NUMBER(22);           -- �d���敉����Ȗ�ID
  gn_v_prepay_ccid          NUMBER(22);           -- �d����O���^����������Ȗ�ID
  gd_v_end_date_active      DATE;                 -- �d���斳����
  gv_v_sb_flag              VARCHAR2(1);          -- �d���撆���@�l�t���O
  gv_v_rr_flag              VARCHAR2(1);          -- �d��������m�F�t���O
  gv_v_attribute_category   VARCHAR2(30);         -- �d����\���J�e�S��
  gv_v_attribute1           VARCHAR2(150);        -- �d����\��1
  gv_v_attribute2           VARCHAR2(150);        -- �d����\��2
  gv_v_attribute3           VARCHAR2(150);        -- �d����\��3
  gv_v_attribute4           VARCHAR2(150);        -- �d����\��4
  gv_v_attribute5           VARCHAR2(150);        -- �d����\��5
  gv_v_attribute6           VARCHAR2(150);        -- �d����\��6
  gv_v_attribute7           VARCHAR2(150);        -- �d����\��7
  gv_v_attribute8           VARCHAR2(150);        -- �d����\��8
  gv_v_attribute9           VARCHAR2(150);        -- �d����\��9
  gv_v_attribute10          VARCHAR2(150);        -- �d����\��10
  gv_v_attribute11          VARCHAR2(150);        -- �d����\��11
  gv_v_attribute12          VARCHAR2(150);        -- �d����\��12
  gv_v_attribute13          VARCHAR2(150);        -- �d����\��13
  gv_v_attribute14          VARCHAR2(150);        -- �d����\��14
  gv_v_attribute15          VARCHAR2(150);        -- �d����\��15
  gv_v_allow_awt_flag       VARCHAR2(1);          -- �d���挹�򒥎��Ŏg�p�t���O
  gv_v_vendor_name_alt      VARCHAR2(320);        -- �d����d����J�i����
  gv_v_ap_tax_rounding_rule VARCHAR2(1);          -- �d���搿���Ŏ����v�Z�[�������K
  gv_v_atc_flag             VARCHAR2(1);          -- �d���搿���Ŏ����v�Z�v�Z���x��
  gv_v_atc_override         VARCHAR2(1);          -- �d���搿���Ŏ����v�Z�㏑���̋�
  gv_v_bank_charge_bearer   VARCHAR2(1);          -- �d�����s�萔�����S��
  gn_s_vendor_site_id       NUMBER(22);           -- �d����T�C�g�d����T�C�gID
  gv_s_vendor_site_code     VARCHAR2(15);         -- �d����T�C�g�d����T�C�g��
  gv_s_address_line1        VARCHAR2(35);         -- �d����T�C�g���ݒn1
  gv_s_address_line2        VARCHAR2(35);         -- �d����T�C�g���ݒn2
  gv_s_address_line3        VARCHAR2(35);         -- �d����T�C�g���ݒn3
  gv_s_city                 VARCHAR2(25);         -- �d����T�C�g�Z���E�S�s��
  gv_s_state                VARCHAR2(25);         -- �d����T�C�g�Z���E�s���{��
  gv_s_zip                  VARCHAR2(20);         -- �d����T�C�g�Z���E�X�֔ԍ�
  gv_s_province             VARCHAR2(25);         -- �d����T�C�g�Z���E�B
  gv_s_country              VARCHAR2(25);         -- �d����T�C�g��
  gv_s_area_code            VARCHAR2(10);         -- �d����T�C�g�s�O�ǔ�
  gv_s_phone                VARCHAR2(15);         -- �d����T�C�g�d�b�ԍ�
  gv_s_fax                  VARCHAR2(15);         -- �d����T�C�gFAX
  gv_s_fax_area_code        VARCHAR2(10);         -- �d����T�C�gFAX�s�O�ǔ�
  gv_s_payment_method       VARCHAR2(25);         -- �d����T�C�g�x�����@
  gv_s_bank_account_name    VARCHAR2(80);         -- �d����T�C�g��������
  gv_s_bank_account_num     VARCHAR2(30);         -- �d����T�C�g�����ԍ�
  gv_s_bank_num             VARCHAR2(25);         -- �d����T�C�g��s�R�[�h
  gv_s_bank_account_type    VARCHAR2(25);         -- �d����T�C�g�a�����
  gv_s_vat_code             VARCHAR2(20);         -- �d����T�C�g�������ŋ��R�[�h
  gn_s_distribution_set_id  NUMBER(22);           -- �d����T�C�g�z���Z�b�gID
  gn_s_accts_pay_ccid       NUMBER(22);           -- �d����T�C�g������Ȗ�ID
  gn_s_prepay_ccid          NUMBER(22);           -- �d����T�C�g�O���^�����������
  gn_s_terms_id             NUMBER(22);           -- �d����T�C�g�x������
  gn_s_invoice_amount_limit NUMBER(22);           -- �d����T�C�g�������x�z
  gv_s_attribute_category   VARCHAR2(30);         -- �d����T�C�g�\���J�e�S��
  gv_s_attribute1           VARCHAR2(150);        -- �d����T�C�g�\��1
  gv_s_attribute2           VARCHAR2(150);        -- �d����T�C�g�\��2
  gv_s_attribute3           VARCHAR2(150);        -- �d����T�C�g�\��3
  gv_s_attribute4           VARCHAR2(150);        -- �d����T�C�g�\��4
  gv_s_attribute5           VARCHAR2(150);        -- �d����T�C�g�\��5
  gv_s_attribute6           VARCHAR2(150);        -- �d����T�C�g�\��6
  gv_s_attribute7           VARCHAR2(150);        -- �d����T�C�g�\��7
  gv_s_attribute8           VARCHAR2(150);        -- �d����T�C�g�\��8
  gv_s_attribute9           VARCHAR2(150);        -- �d����T�C�g�\��9
  gv_s_attribute10          VARCHAR2(150);        -- �d����T�C�g�\��10
  gv_s_attribute11          VARCHAR2(150);        -- �d����T�C�g�\��11
  gv_s_attribute12          VARCHAR2(150);        -- �d����T�C�g�\��12
  gv_s_attribute13          VARCHAR2(150);        -- �d����T�C�g�\��13
  gv_s_attribute14          VARCHAR2(150);        -- �d����T�C�g�\��14
  gv_s_attribute15          VARCHAR2(150);        -- �d����T�C�g�\��15
  gv_s_bank_number          VARCHAR2(30);         -- �d����T�C�g��s�x�X�R�[�h
  gv_s_address_line4        VARCHAR2(35);         -- �d����T�C�g���ݒn4
  gv_s_county               VARCHAR2(25);         -- �d����T�C�g�S
  gv_s_allow_awt_flag       VARCHAR2(1);          -- �d����T�C�g���򒥎��Ŏg�p�t��
  gn_s_awt_group_id         NUMBER(15);           -- �d����T�C�g���򒥎��ŃO���[�v
  gv_s_vendor_site_code_alt VARCHAR2(320);        -- �d����T�C�g�d����T�C�g���i�J
  gv_s_address_lines_alt    VARCHAR2(560);        -- �d����T�C�g�Z���J�i
  gv_s_ap_tax_rounding_rule VARCHAR2(1);          -- �d����T�C�g�����Ŏ����v�Z�[��
  gv_s_atc_flag             VARCHAR2(1);          -- �d����T�C�g�����Ŏ����v�Z�v�Z
  gv_s_atc_override         VARCHAR2(1);          -- �d����T�C�g�����Ŏ����v�Z�㏑
  gv_s_bank_charge_bearer   VARCHAR2(1);          -- �d����T�C�g��s�萔�����S��
  gv_s_bank_branch_type     VARCHAR2(25);         -- �d����T�C�g��s�x�X�^�C�v
  gv_s_cdm_flag             VARCHAR2(25);         -- �d����T�C�gRTS�������f�r�b
  gv_s_sn_method            VARCHAR2(25);         -- �d����T�C�g�d����ʒm���@
  gv_s_email_address        VARCHAR2(2000);       -- �d����T�C�gE���[���A�h���X
  gv_s_pps_flag             VARCHAR2(1);          -- �d����T�C�g��x���T�C�g�t���O
  gv_s_ps_flag              VARCHAR2(1);          -- �d����T�C�g�w���t���O
-- Ver1.2  2009/04/21  Add  ��Q�FT1_0438�Ή�  ��s�萔�����S�҂�ǉ�
  gv_s_bank_charge_new      VARCHAR2(1);          -- �d����T�C�g��s�萔�����S��(�V�K�o�^�p)
-- End Ver1.2
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
  CURSOR get_u_people_data_cur
  IS
    SELECT   p.person_id AS person_id,                              -- �]�ƈ�ID
             p.employee_number AS employee_number,                  -- �]�ƈ��ԍ�
             p.per_information18 AS per_information18,              -- ����(��)
             p.per_information19 AS per_information19,              -- ����(��)
             t.actual_termination_date AS actual_termination_date,  -- �ސE�N����
             a.ass_attribute3 AS ass_attribute3,                    -- ����R�[�h
             s.vendor_id AS vendor_id                               -- �d����ID
-- Ver1.2  2009/04/21  Add  ��Q�FT1_0388�Ή�  �]�ƈ��d����T�C�g�Ή�
            ,pvs.vendor_site_id
-- End Ver1.2
    FROM     per_periods_of_service t,
             per_all_assignments_f a,
-- Ver1.2  2009/04/21  Add  ��Q�FT1_0388�Ή�  �]�ƈ��d����T�C�g�Ή�
             po_vendor_sites  pvs,
-- End Ver1.2
             po_vendors s,
             per_all_people_f p,
             (SELECT   pp.person_id AS person_id,
                       MAX(pp.effective_start_date) as effective_start_date
              FROM     per_all_people_f pp
              WHERE    pp.current_emp_or_apl_flag = 'Y'
              GROUP BY pp.person_id) pp
    WHERE    pp.person_id = p.person_id
    AND      pp.effective_start_date = p.effective_start_date
    AND      (p.attribute3 = gv_jyugyoin_kbn_s OR p.attribute3 = gv_jyugyoin_kbn_d)
    AND      p.person_id = a.person_id
    AND      p.effective_start_date = a.effective_start_date
    AND      p.person_id = s.employee_id
-- Ver1.2  2009/04/21  Add  ��Q�FT1_0388�Ή�  �]�ƈ��d����T�C�g�Ή�
    AND      s.vendor_id = pvs.vendor_id
    AND      pvs.vendor_site_code = cv_site_code_comp
-- End Ver1.2
    AND      a.period_of_service_id = t.period_of_service_id
    ORDER BY p.employee_number
  ;
  TYPE g_u_people_data_ttype IS TABLE OF get_u_people_data_cur%ROWTYPE INDEX BY PLS_INTEGER;
  gt_u_people_data            g_u_people_data_ttype;
  --
  -- �d���掩�͓̂o�^�ς݂����A�T�C�g�Ɂu��Ёv�����݂��Ȃ����̂��V�K�Ƃ��Ē��o����i2009/04/24�j
  CURSOR get_i_people_data_cur
  IS
    SELECT   p.person_id AS person_id,                              -- �]�ƈ�ID
             p.employee_number AS employee_number,                  -- �]�ƈ��ԍ�
             p.per_information18 AS per_information18,              -- ����(��)
             p.per_information19 AS per_information19,              -- ����(��)
             a.ass_attribute3 AS ass_attribute3                     -- ����R�[�h
-- Ver1.2  2009/04/24  Add  �d����o�^�ς݁A�T�C�g�u��Ёv���o�^�Ή�
            ,s.vendor_id AS vendor_id                               -- �d����ID
-- End Ver1.2
    FROM     po_vendors s,
             per_periods_of_service t,
             per_all_assignments_f a,
             per_all_people_f p,
             (SELECT   pp.person_id AS person_id,
                       MAX(pp.effective_start_date) as effective_start_date
              FROM     per_all_people_f pp
              WHERE    pp.current_emp_or_apl_flag = 'Y'
              GROUP BY pp.person_id) pp
    WHERE    pp.person_id = p.person_id
    AND      pp.effective_start_date = p.effective_start_date
    AND      (p.attribute3 = gv_jyugyoin_kbn_s OR p.attribute3 = gv_jyugyoin_kbn_d)
    AND      p.person_id = a.person_id
    AND      p.effective_start_date = a.effective_start_date
    AND      a.period_of_service_id = t.period_of_service_id
    AND      (t.actual_termination_date IS NULL OR t.actual_termination_date >= gd_process_date)
    AND      p.person_id = s.employee_id(+)
-- 2009/04/21  Mod  ��Q�FT1_0388�Ή�  �]�ƈ��d����T�C�g�Ή�
--    AND      s.employee_id IS NULL
    AND      NOT EXISTS ( SELECT   'x'
                          FROM     po_vendor_sites  pvs
                          WHERE    s.vendor_id = pvs.vendor_id
                          AND      pvs.vendor_site_code = cv_site_code_comp )
-- End Ver1.2
    ORDER BY p.employee_number
  ;
  TYPE g_i_people_data_ttype IS TABLE OF get_i_people_data_cur%ROWTYPE INDEX BY PLS_INTEGER;
  gt_i_people_data            g_i_people_data_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ���������v���V�[�W��(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init';                  -- �v���O������
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
    -- �t�@�C���I�[�v�����[�h
    cv_open_mode_w          CONSTANT VARCHAR2(10)  := 'w';           -- �㏑��
--
    -- *** ���[�J���ϐ� ***
    lb_fexists              BOOLEAN;              -- �t�@�C�������݂��邩�ǂ���
    ln_file_size            NUMBER;               -- �t�@�C���̒���
    ln_block_size           NUMBER;               -- �t�@�C���V�X�e���̃u���b�N�T�C�Y
    lv_tkn_nm               VARCHAR2(31);         -- �g�[�N��
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR get_vendors_interface_cur IS
      SELECT   vendors_interface_id
      FROM     xx03_vendors_interface
-- Ver1.2  2009/04/21  Add  ��Q�FT1_0255�Ή�  ��v�ƃo�b�e�B���O���Ȃ��悤������ǉ�
      WHERE    vndr_vendor_type_lkup_code = gv_vendor_type
-- End Ver1.2
      FOR UPDATE NOWAIT;
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ============================================================
    --  �Œ�o��(���̓p�����[�^��)
    -- ============================================================
    lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp             -- 'XXCCP'
                    ,iv_name         => cv_msg_90008               -- �R���J�����g���̓p�����[�^�Ȃ�
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- ============================================================
    --  �v���t�@�C���̎擾
    -- ============================================================
    gv_filepath := fnd_profile.value(cv_filepath);
    IF (gv_filepath IS NULL) THEN
      lv_tkn_nm := cv_tkn_filepath_nm;
      RAISE global_process_expt;
    END IF;
    gv_filename := fnd_profile.value(cv_filename);
    IF (gv_filename IS NULL) THEN
      lv_tkn_nm := cv_tkn_filename_nm;
      RAISE global_process_expt;
    END IF;
    gv_cal_code := fnd_profile.value(cv_cal_code);
    IF (gv_cal_code IS NULL) THEN
      lv_tkn_nm := cv_tkn_cal_code;
      RAISE global_process_expt;
    END IF;
    gv_vendor_type := fnd_profile.value(cv_vendor_type);
    IF (gv_vendor_type IS NULL) THEN
      lv_tkn_nm := cv_tkn_vendor_type_nm;
      RAISE global_process_expt;
    END IF;
    gv_country := fnd_profile.value(cv_country);
    IF (gv_country IS NULL) THEN
      lv_tkn_nm := cv_tkn_country_nm;
      RAISE global_process_expt;
    END IF;
-- Ver1.2  2009/04/21  Del  ��Q�FT1_0438�Ή�  ��v�I�v�V��������擾����悤�ύX�i���E�O�����j
--    gv_accts_pay_ccid := fnd_profile.value(cv_accts_pay_ccid);
--    IF (gv_accts_pay_ccid IS NULL) THEN
--      lv_tkn_nm := cv_tkn_accts_pay_ccid_nm;
--      RAISE global_process_expt;
--    END IF;
--    gv_prepay_ccid := fnd_profile.value(cv_prepay_ccid);
--    IF (gv_prepay_ccid IS NULL) THEN
--      lv_tkn_nm := cv_tkn_prepay_ccid_nm;
--      RAISE global_process_expt;
--    END IF;
-- End Ver1.2
    gv_group_type_nm := fnd_profile.value(cv_group_type_nm);
    IF (gv_group_type_nm IS NULL) THEN
      lv_tkn_nm := cv_tkn_group_type_nm;
      RAISE global_process_expt;
    END IF;
    gv_pay_bumon_cd := fnd_profile.value(cv_pay_bumon_cd);
    IF (gv_pay_bumon_cd IS NULL) THEN
      lv_tkn_nm := cv_tkn_pay_bumon_cd_nm;
      RAISE global_process_expt;
    END IF;
    gv_pay_bumon_nm := fnd_profile.value(cv_pay_bumon_nm);
    IF (gv_pay_bumon_nm IS NULL) THEN
      lv_tkn_nm := cv_tkn_pay_bumon_nm;
      RAISE global_process_expt;
    END IF;
    gv_pay_method_nm := fnd_profile.value(cv_pay_method_nm);
    IF (gv_pay_method_nm IS NULL) THEN
      lv_tkn_nm := cv_tkn_pay_method_nm;
      RAISE global_process_expt;
    END IF;
    gv_pay_bank := fnd_profile.value(cv_pay_bank);
    IF (gv_pay_bank IS NULL) THEN
      lv_tkn_nm := cv_tkn_pay_bank_nm;
      RAISE global_process_expt;
    END IF;
    gv_koguti_genkin_nm := fnd_profile.value(cv_koguti_genkin_nm);
    IF (gv_koguti_genkin_nm IS NULL) THEN
      lv_tkn_nm := cv_tkn_koguti_genkin_nm;
      RAISE global_process_expt;
    END IF;
    gv_pay_type_nm := fnd_profile.value(cv_pay_type_nm);
    IF (gv_pay_type_nm IS NULL) THEN
      lv_tkn_nm := cv_tkn_pay_type_nm;
      RAISE global_process_expt;
    END IF;
    gv_terms_id := fnd_profile.value(cv_terms_id);
    IF (gv_terms_id IS NULL) THEN
      lv_tkn_nm := cv_tkn_terms_id_nm;
      RAISE global_process_expt;
    END IF;
-- Ver1.2  2009/04/21  Add  ��Q�FT1_0438�Ή�  ��s�萔�����S�҂�ǉ��u����(I)�v
    gv_s_bank_charge_new := fnd_profile.value(cv_bank_charge_bearer);
    IF (gv_s_bank_charge_new IS NULL) THEN
      lv_tkn_nm := cv_tkn_bank_charge;
      RAISE global_process_expt;
    END IF;
-- End Ver1.2
    gv_bank_number := fnd_profile.value(cv_bank_number);
    IF (gv_bank_number IS NULL) THEN
      lv_tkn_nm := cv_tkn_bank_number_nm;
      RAISE global_process_expt;
    END IF;
    gv_bank_num := fnd_profile.value(cv_bank_num);
    IF (gv_bank_num IS NULL) THEN
      lv_tkn_nm := cv_tkn_bank_num_nm;
      RAISE global_process_expt;
    END IF;
    gv_bank_nm := fnd_profile.value(cv_bank_nm);
    IF (gv_bank_nm IS NULL) THEN
      lv_tkn_nm := cv_tkn_bank_nm;
      RAISE global_process_expt;
    END IF;
    gv_shiten_nm := fnd_profile.value(cv_shiten_nm);
    IF (gv_shiten_nm IS NULL) THEN
      lv_tkn_nm := cv_tkn_shiten_nm;
      RAISE global_process_expt;
    END IF;
    gv_account_num := fnd_profile.value(cv_account_num);
    IF (gv_account_num IS NULL) THEN
      lv_tkn_nm := cv_tkn_account_num_nm;
      RAISE global_process_expt;
    END IF;
    gv_currency_cd := fnd_profile.value(cv_currency_cd);
    IF (gv_currency_cd IS NULL) THEN
      lv_tkn_nm := cv_tkn_currency_cd_nm;
      RAISE global_process_expt;
    END IF;
    gv_account_type := fnd_profile.value(cv_account_type);
    IF (gv_account_type IS NULL) THEN
      lv_tkn_nm := cv_tkn_account_type_nm;
      RAISE global_process_expt;
    END IF;
    gv_holder_nm := fnd_profile.value(cv_holder_nm);
    IF (gv_holder_nm IS NULL) THEN
      lv_tkn_nm := cv_tkn_holder_nm;
      RAISE global_process_expt;
    END IF;
    gv_holder_alt_nm := fnd_profile.value(cv_holder_alt_nm);
    IF (gv_holder_alt_nm IS NULL) THEN
      lv_tkn_nm := cv_tkn_holder_alt_nm;
      RAISE global_process_expt;
    END IF;
    gv_address_nm1 := fnd_profile.value(cv_address_nm1);
    IF (gv_address_nm1 IS NULL) THEN
      lv_tkn_nm := cv_tkn_address_nm1;
      RAISE global_process_expt;
    END IF;
    gv_address_nm2 := fnd_profile.value(cv_address_nm2);
    IF (gv_address_nm2 IS NULL) THEN
      lv_tkn_nm := cv_tkn_address_nm2;
      RAISE global_process_expt;
    END IF;
    gv_jyugyoin_kbn_s := fnd_profile.value(cv_jyugyoin_kbn_s);
    IF (gv_jyugyoin_kbn_s IS NULL) THEN
      lv_tkn_nm := cv_tkn_jyugoin_kbn_s_nm;
      RAISE global_process_expt;
    END IF;
    gv_jyugyoin_kbn_d := fnd_profile.value(cv_jyugyoin_kbn_d);
    IF (gv_jyugyoin_kbn_d IS NULL) THEN
      lv_tkn_nm := cv_tkn_jyugoin_kbn_d_nm;
      RAISE global_process_expt;
    END IF;
    --
-- Ver1.2  2009/04/21  Del  ��Q�FT1_0438�Ή�  ��v�I�v�V��������擾����悤�ύX�i���E�O�����j
    -- ============================================================
    --  ��v�I�v�V�����̎擾
    -- ============================================================
    SELECT   TO_CHAR( accts_pay_code_combination_id )   -- ������
            ,TO_CHAR( prepay_code_combination_id )      -- �O����
    INTO     gv_accts_pay_ccid
            ,gv_prepay_ccid
    FROM     financials_system_parameters;    -- ��v�I�v�V����
-- End Ver1.2
    --
    -- ============================================================
    --  �Œ�o��(I/F�t�@�C������)
    -- ============================================================
    lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp             -- 'XXCCP'
                    ,iv_name         => cv_msg_05102               -- �t�@�C�����o�̓��b�Z�[�W
                    ,iv_token_name1  => cv_tkn_filename            -- �g�[�N��(FILE_NAME)
                    ,iv_token_value1 => gv_filename                -- �t�@�C����
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- ============================================================
    --  �v���t�@�C��:���ݒn1�A2�̕������`�F�b�N
    -- ============================================================
    IF (LENGTHB(gv_address_nm1) > cv_address_length) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm           -- 'XXCMM'
                      ,iv_name         => cv_msg_00214             -- �����������G���[
                      ,iv_token_name1  => cv_tkn_profile           -- �g�[�N��(NG_PROFILE)
                      ,iv_token_value1 => cv_tkn_address_nm1       -- �v���t�@�C����(���ݒn1)
                      ,iv_token_name2  => cv_tkn_length            -- �g�[�N��(NG_LENGTH)
                      ,iv_token_value2 => cv_address_length        -- ���ݒn1�̍ő啶����
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    IF (LENGTHB(gv_address_nm2) > cv_address_length) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm           -- 'XXCMM'
                      ,iv_name         => cv_msg_00214             -- �����������G���[
                      ,iv_token_name1  => cv_tkn_profile           -- �g�[�N��(NG_PROFILE)
                      ,iv_token_value1 => cv_tkn_address_nm2       -- �v���t�@�C����(���ݒn2)
                      ,iv_token_name2  => cv_tkn_length            -- �g�[�N��(NG_LENGTH)
                      ,iv_token_value2 => cv_address_length        -- ���ݒn2�̍ő啶����
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- =========================================================
    --  �t�@�C���I�[�v��
    -- =========================================================
    BEGIN
      gf_file_hand := UTL_FILE.FOPEN(gv_filepath
                                    ,gv_filename
                                    ,cv_open_mode_w);
    EXCEPTION
      WHEN UTL_FILE.INVALID_PATH THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                        ,iv_name         => cv_msg_00003           -- �t�@�C���p�X�s���G���[
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- =========================================================
    --  �Ɩ����t�A�擾���̃V�X�e���ғ����̎擾
    -- =========================================================
    -- �Ɩ����t�̎擾
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm           -- 'XXCMM'
                      ,iv_name         => cv_msg_00018             -- �Ɩ��������t�擾�G���[
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- �擾���̃V�X�e���ғ������擾
    gd_select_next_date := xxccp_common_pkg2.get_working_day(gd_process_date,1,gv_cal_code);
    IF (gd_select_next_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm           -- 'XXCMM'
                      ,iv_name         => cv_msg_00036             -- ���̃V�X�e���ғ����擾�G���[
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- =========================================================
    --  �d����]�ƈ���񒆊�I/F�e�[�u�����b�N
    -- =========================================================
    BEGIN
      OPEN get_vendors_interface_cur;
      CLOSE get_vendors_interface_cur;
    EXCEPTION
      -- �e�[�u�����b�N�G���[
      WHEN lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                        ,iv_name         => cv_msg_00008           -- ���b�N�擾NG���b�Z�[�W
                        ,iv_token_name1  => cv_tkn_table           -- �g�[�N��(NG_TABLE)
                        ,iv_token_value1 => cv_tkn_table_nm        -- �e�[�u����(�d����]�ƈ���񒆊�I/F�e�[�u��)
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_process_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm           -- 'XXCMM'
                      ,iv_name         => cv_msg_00002             -- �v���t�@�C���擾�G���[
                      ,iv_token_name1  => cv_tkn_profile           -- �g�[�N��(NG_PROFILE)
                      ,iv_token_value1 => lv_tkn_nm                -- �g�[�N����
                     );
      lv_errbuf := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_u_people_data
   * Description      : �V�K�o�^�ȊO�̎Ј��f�[�^�擾�v���V�[�W��(A-2)
   ***********************************************************************************/
  PROCEDURE get_u_people_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_u_people_data';       -- �v���O������
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
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
   -- �J�[�\���I�[�v��
    OPEN get_u_people_data_cur;
--
    -- �f�[�^�̈ꊇ�擾
    FETCH get_u_people_data_cur BULK COLLECT INTO gt_u_people_data;
--
    -- �V�K�o�^�ȊO�̑Ώی������Z�b�g
    gn_target_update_cnt := gt_u_people_data.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE get_u_people_data_cur;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
--#####################################  �Œ蕔 END   ##########################################
--
  END get_u_people_data;
--
  /**********************************************************************************
   * Procedure Name   : update_output_csv
   * Description      : CSV�t�@�C���o��(�X�V)�v���V�[�W��(A-6)
   ***********************************************************************************/
  PROCEDURE update_output_csv(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_output_csv';     -- �v���O������
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
    cv_delimiter        CONSTANT VARCHAR2(1)  := ',';                -- CSV��؂蕶��
    cv_enclosed         CONSTANT VARCHAR2(2)  := '"';                -- �P��͂ݕ���
    cv_t                CONSTANT VARCHAR2(1)  := 'T';                -- �ސE�����Ј�
    cv_i                CONSTANT VARCHAR2(1)  := 'I';                -- �ٓ������Ј�
    cv_o                CONSTANT VARCHAR2(1)  := 'O';                -- �ٓ����ސE�����Ȃ������Ј�
--
    -- *** ���[�J���ϐ� ***
    ln_loop_cnt         NUMBER;                   -- ���[�v�J�E���^
    lv_csv_text         VARCHAR2(32000);          -- �o�͂P�s��������ϐ�
    lv_old_pay_group    VARCHAR2(25);             -- �ȑO�̎x���O���[�v�R�[�h
    lv_new_pay_group    VARCHAR2(50);             -- ���݂̎x���O���[�v�R�[�h
    lv_ret_flg          VARCHAR2(1);              -- ���݂̎x���O���[�v�R�[�h�擾�����p�t���O
    lv_pay_flg          VARCHAR2(1);              -- �x���\����t���O
    lv_kbn              VARCHAR2(1);              -- �����敪(T:�ސE�����Ј�/I:�ٓ������Ј�/O:�ٓ����ސE�����Ȃ������Ј�)
    ld_end_date_active  DATE;                     -- ������
    lv_employee_number  VARCHAR2(22);             -- �]�ƈ��ԍ��d���`�F�b�N�p
    ln_o_cnt            NUMBER;                   -- �ٓ����ސE�����Ȃ������Ј��̌���(�Ώی����Ɋ܂܂Ȃ�)
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    -- ������
    ln_o_cnt := 0;
    --
    <<u_out_loop>>
    FOR ln_loop_cnt IN gt_u_people_data.FIRST..gt_u_people_data.LAST LOOP
-- Ver1.2  2009/04/21  Add  ��Q�FT1_0388�Ή�
      gn_s_vendor_site_id := gt_u_people_data(ln_loop_cnt).vendor_site_id;
-- End Ver1.2
      --========================================
      -- �]�ƈ��ԍ��d���`�F�b�N(A-3-1)
      --========================================
      -- �]�ƈ��ԍ����d�����Ă���ꍇ�A�x�����b�Z�[�W��\��
      IF (lv_employee_number = gt_u_people_data(ln_loop_cnt).employee_number) THEN
        -- �x���t���O�ɃI�����Z�b�g
        gv_warn_flg := '1';
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm                                  -- 'XXCMM'
                        ,iv_name         => cv_msg_00209                                    -- �]�ƈ��ԍ��d�����b�Z�[�W
                        ,iv_token_name1  => cv_tkn_word                                     -- �g�[�N��(NG_WORD)
                        ,iv_token_value1 => cv_tkn_word1                                    -- NG_WORD
                        ,iv_token_name2  => cv_tkn_data                                     -- �g�[�N��(NG_DATA)
                        ,iv_token_value2 => gt_u_people_data(ln_loop_cnt).employee_number   -- NG_WORD��DATA
                                              || cv_tkn_word2
                                              || gt_u_people_data(ln_loop_cnt).per_information18
                                              || '�@'
                                              || gt_u_people_data(ln_loop_cnt).per_information19
                       );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
      END IF;
      --========================================
      -- ����R�[�h�`�F�b�N(A-3-2)
      --========================================
      IF (gt_u_people_data(ln_loop_cnt).ass_attribute3 IS NULL) THEN
        -- �x���t���O�ɃI�����Z�b�g
        gv_warn_flg := '1';
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm                                  -- 'XXCMM'
                        ,iv_name         => cv_msg_00208                                    -- �Ζ��n���_�R�[�h(�V)�����̓G���[
                        ,iv_token_name1  => cv_tkn_word                                     -- �g�[�N��(NG_WORD)
                        ,iv_token_value1 => cv_tkn_word1                                    -- NG_WORD
                        ,iv_token_name2  => cv_tkn_data                                     -- �g�[�N��(NG_DATA)
                        ,iv_token_value2 => gt_u_people_data(ln_loop_cnt).employee_number   -- NG_WORD��DATA
                       );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
        -- �X�L�b�v�������J�E���g
        gn_warn_cnt := gn_warn_cnt + 1;
      ELSE
        --========================================
        -- �ȑO�̎x���O���[�v�擾(A-3-3)
        --========================================
        BEGIN
-- Ver1.2  2009/04/21  Mod  ��Q�FT1_0388�Ή�  �c�Ƃn�t�́u��Ёv�̂ݎ擾����悤�C��
--          SELECT   pay_group_lookup_code,         -- �ȑO�̎x���O���[�v
--                   vendor_site_id                 -- �d����T�C�gID
--          INTO     lv_old_pay_group,
--                   gn_s_vendor_site_id
--          FROM     po_vendor_sites_all
--          WHERE    vendor_id = gt_u_people_data(ln_loop_cnt).vendor_id;
          --
          SELECT   pay_group_lookup_code         -- �ȑO�̎x���O���[�v
          INTO     lv_old_pay_group
          FROM     po_vendor_sites
          WHERE    vendor_site_id = gn_s_vendor_site_id;
-- End Ver1.2
          --
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cmm                                -- 'XXCMM'
                            ,iv_name         => cv_msg_00211                                  -- �ȑO�̎x���O���[�v�擾�G���[
                            ,iv_token_name1  => cv_tkn_word                                   -- �g�[�N��(NG_WORD)
                            ,iv_token_value1 => cv_tkn_word1                                  -- NG_WORD
                            ,iv_token_name2  => cv_tkn_data                                   -- �g�[�N��(NG_DATA)
                            ,iv_token_value2 => gt_u_people_data(ln_loop_cnt).employee_number -- NG_WORD��DATA
                           );
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
        --========================================
        -- ���݂̎x���O���[�v�擾(A-3-4)
        --========================================
        BEGIN
          SELECT   '1'
          INTO     lv_ret_flg
          FROM     fnd_lookup_values_vl
          WHERE    lookup_type = gv_group_type_nm
          AND      attribute2 = gt_u_people_data(ln_loop_cnt).ass_attribute3
          AND      ROWNUM = 1;
          IF (gt_u_people_data(ln_loop_cnt).ass_attribute3 = gv_pay_bumon_cd) THEN
            lv_new_pay_group := gv_pay_bumon_nm || '-' || gv_pay_method_nm || '/' || gv_pay_bank|| '/' || gv_pay_type_nm;
            -- �x���\����t���O�ɂȂ����Z�b�g
            lv_pay_flg := 'N';
          ELSE
            lv_new_pay_group := gt_u_people_data(ln_loop_cnt).ass_attribute3 || '-' || gv_koguti_genkin_nm || '/' || gv_pay_type_nm;
            -- �x���\����t���O�ɂ�����Z�b�g
            lv_pay_flg := 'Y';
          END IF;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lv_new_pay_group := gv_pay_bumon_nm || '-' || gv_pay_method_nm || '/' || gv_pay_bank|| '/' || gv_pay_type_nm;
            -- �x���\����t���O�ɂȂ����Z�b�g
            lv_pay_flg := 'N';
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
        IF (LENGTHB(lv_new_pay_group) > cv_pay_group_length) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cmm                                -- 'XXCMM'
                          ,iv_name         => cv_msg_00215                                  -- �x���O���[�v�R�[�h�����������G���[
                          ,iv_token_name1  => cv_tkn_length                                 -- �g�[�N��(NG_LENGTH)
                          ,iv_token_value1 => cv_pay_group_length                           -- �x���O���[�v�R�[�h�̍ő啶����
                          ,iv_token_name2  => cv_tkn_word                                   -- �g�[�N��(NG_WORD)
                          ,iv_token_value2 => cv_tkn_word1                                  -- NG_WORD
                          ,iv_token_name3  => cv_tkn_data                                   -- �g�[�N��(NG_DATA)
                          ,iv_token_value3 => gt_u_people_data(ln_loop_cnt).employee_number -- NG_WORD��DATA
                                                || cv_tkn_word3
                                                || lv_new_pay_group
                         );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
        --========================================
        -- �X�V�Ώۃf�[�^�`�F�b�N(A-3-5)
        --========================================
        IF ((gd_process_date <= gt_u_people_data(ln_loop_cnt).actual_termination_date)
          AND (gt_u_people_data(ln_loop_cnt).actual_termination_date < gd_select_next_date))
        THEN
          -- �ސE�����Ј�
          lv_kbn := cv_t;
        ELSIF ((lv_old_pay_group = lv_new_pay_group)
          OR (lv_pay_flg = 'N' AND SUBSTRB(lv_old_pay_group,1,INSTRB(lv_old_pay_group,'-')-1) = gv_pay_bumon_nm))
        THEN
          -- �ٓ����ސE�����Ȃ������Ј�
          lv_kbn := cv_o;
        ELSE
          -- �ٓ������Ј�
          lv_kbn := cv_i;
        END IF;
        --
        IF (lv_kbn = cv_o) THEN
          -- �ٓ����ސE�����Ȃ������Ј��̌������J�E���g
          ln_o_cnt := ln_o_cnt + 1;
        ELSE
          --========================================
          -- �d����}�X�^�f�[�^�擾(A-4)
          --========================================
          BEGIN
            SELECT   SUBSTRB(vendor_name,1,80),                     -- �d����d���於
                     segment1,                                      -- �d����d����ԍ�
                     SUBSTRB(employee_id,1,22),                     -- �d����]�ƈ�ID
                     vendor_type_lookup_code,                       -- �d����d����^�C�v
                     SUBSTRB(terms_id,1,22),                        -- �d����x������
                     pay_group_lookup_code,                         -- �d����x���O���[�v�R�[�h
                     SUBSTRB(invoice_amount_limit,1,22),            -- �d���搿�����x�z
                     SUBSTRB(accts_pay_code_combination_id,1,22),   -- �d���敉����Ȗ�ID
                     SUBSTRB(prepay_code_combination_id,1,22),      -- �d����O���^����������Ȗ�ID
                     end_date_active,                               -- �d���斳����
                     small_business_flag,                           -- �d���撆���@�l�t���O
                     receipt_required_flag,                         -- �d��������m�F�t���O
                     attribute_category,                            -- �d����\���J�e�S��
                     attribute1,                                    -- �d����\��1
                     attribute2,                                    -- �d����\��2
                     attribute3,                                    -- �d����\��3
                     attribute4,                                    -- �d����\��4
                     attribute5,                                    -- �d����\��5
                     attribute6,                                    -- �d����\��6
                     attribute7,                                    -- �d����\��7
                     attribute8,                                    -- �d����\��8
                     attribute9,                                    -- �d����\��9
                     attribute10,                                   -- �d����\��10
                     attribute11,                                   -- �d����\��11
                     attribute12,                                   -- �d����\��12
                     attribute13,                                   -- �d����\��13
                     attribute14,                                   -- �d����\��14
                     attribute15,                                   -- �d����\��15
                     allow_awt_flag,                                -- �d���挹�򒥎��Ŏg�p�t���O
                     vendor_name_alt,                               -- �d����d����J�i����
                     ap_tax_rounding_rule,                          -- �d���搿���Ŏ����v�Z�[�������K
                     auto_tax_calc_flag,                            -- �d���搿���Ŏ����v�Z�v�Z���x��
                     auto_tax_calc_override,                        -- �d���搿���Ŏ����v�Z�㏑���̋�
                     bank_charge_bearer                             -- �d�����s�萔�����S��
            INTO     gv_v_vendor_name,
                     gv_v_segment1,
                     gn_v_employee_id,
                     gv_v_vendor_type,
                     gn_v_terms_id,
                     gv_v_pay_group,
                     gn_v_invoice_amount_limit,
                     gn_v_accts_pay_ccid,
                     gn_v_prepay_ccid,
                     ld_end_date_active,
                     gv_v_sb_flag,
                     gv_v_rr_flag,
                     gv_v_attribute_category,
                     gv_v_attribute1,
                     gv_v_attribute2,
                     gv_v_attribute3,
                     gv_v_attribute4,
                     gv_v_attribute5,
                     gv_v_attribute6,
                     gv_v_attribute7,
                     gv_v_attribute8,
                     gv_v_attribute9,
                     gv_v_attribute10,
                     gv_v_attribute11,
                     gv_v_attribute12,
                     gv_v_attribute13,
                     gv_v_attribute14,
                     gv_v_attribute15,
                     gv_v_allow_awt_flag,
                     gv_v_vendor_name_alt,
                     gv_v_ap_tax_rounding_rule,
                     gv_v_atc_flag,
                     gv_v_atc_override,
                     gv_v_bank_charge_bearer
            FROM     po_vendors
            WHERE    vendor_id = gt_u_people_data(ln_loop_cnt).vendor_id;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cmm                                -- 'XXCMM'
                              ,iv_name         => cv_msg_00212                                  -- �d����}�X�^�f�[�^�擾�G���[
                              ,iv_token_name1  => cv_tkn_word                                   -- �g�[�N��(NG_WORD)
                              ,iv_token_value1 => cv_tkn_word1                                  -- NG_WORD
                              ,iv_token_name2  => cv_tkn_data                                   -- �g�[�N��(NG_DATA)
                              ,iv_token_value2 => gt_u_people_data(ln_loop_cnt).employee_number -- NG_WORD��DATA
                             );
              lv_errbuf := lv_errmsg;
              RAISE global_api_expt;
            WHEN OTHERS THEN
              RAISE global_api_others_expt;
          END;
          IF (lv_kbn = cv_i) THEN
            --========================================
            -- �d����T�C�g�}�X�^�f�[�^�擾(A-5)
            --========================================
            BEGIN
              SELECT   vendor_site_code,                            -- �d����T�C�g�d����T�C�g��
                       SUBSTRB(address_line1,1,35),                 -- �d����T�C�g���ݒn1
                       SUBSTRB(address_line2,1,35),                 -- �d����T�C�g���ݒn2
                       SUBSTRB(address_line3,1,35),                 -- �d����T�C�g���ݒn3
                       city,                                        -- �d����T�C�g�Z���E�S�s��
                       SUBSTRB(state,1,25),                         -- �d����T�C�g�Z���E�s���{��
                       zip,                                         -- �d����T�C�g�Z���E�X�֔ԍ�
                       SUBSTRB(province,1,25),                      -- �d����T�C�g�Z���E�B
                       country,                                     -- �d����T�C�g��
                       area_code,                                   -- �d����T�C�g�s�O�ǔ�
                       phone,                                       -- �d����T�C�g�d�b�ԍ�
                       fax,                                         -- �d����T�C�gFAX
                       fax_area_code,                               -- �d����T�C�gFAX�s�O�ǔ�
                       payment_method_lookup_code,                  -- �d����T�C�g�x�����@
                       bank_account_name,                           -- �d����T�C�g��������
                       bank_account_num,                            -- �d����T�C�g�����ԍ�
                       bank_num,                                    -- �d����T�C�g��s�R�[�h
                       bank_account_type,                           -- �d����T�C�g�a�����
                       vat_code,                                    -- �d����T�C�g�������ŋ��R�[�h
                       SUBSTRB(distribution_set_id,1,22),           -- �d����T�C�g�z���Z�b�gID
                       SUBSTRB(accts_pay_code_combination_id,1,22), -- �d����T�C�g������Ȗ�ID
                       SUBSTRB(prepay_code_combination_id,1,22),    -- �d����T�C�g�O���^�����������
                       SUBSTRB(terms_id,1,22),                      -- �d����T�C�g�x������
                       SUBSTRB(invoice_amount_limit,1,22),          -- �d����T�C�g�������x�z
                       attribute_category,                          -- �d����T�C�g�\���J�e�S��
                       attribute1,                                  -- �d����T�C�g�\��1
                       attribute2,                                  -- �d����T�C�g�\��2
                       attribute3,                                  -- �d����T�C�g�\��3
                       attribute4,                                  -- �d����T�C�g�\��4
                       attribute5,                                  -- �d����T�C�g�\��5
                       attribute6,                                  -- �d����T�C�g�\��6
                       attribute7,                                  -- �d����T�C�g�\��7
                       attribute8,                                  -- �d����T�C�g�\��8
                       attribute9,                                  -- �d����T�C�g�\��9
                       attribute10,                                 -- �d����T�C�g�\��10
                       attribute11,                                 -- �d����T�C�g�\��11
                       attribute12,                                 -- �d����T�C�g�\��12
                       attribute13,                                 -- �d����T�C�g�\��13
                       attribute14,                                 -- �d����T�C�g�\��14
                       attribute15,                                 -- �d����T�C�g�\��15
                       bank_number,                                 -- �d����T�C�g��s�x�X�R�[�h
                       SUBSTRB(address_line4,1,35),                 -- �d����T�C�g���ݒn4
                       SUBSTRB(county,1,25),                        -- �d����T�C�g�S
                       allow_awt_flag,                              -- �d����T�C�g���򒥎��Ŏg�p�t��
                       awt_group_id,                                -- �d����T�C�g���򒥎��ŃO���[�v
                       vendor_site_code_alt,                        -- �d����T�C�g�d����T�C�g���i�J
                       address_lines_alt,                           -- �d����T�C�g�Z���J�i
                       ap_tax_rounding_rule,                        -- �d����T�C�g�����Ŏ����v�Z�[��
                       auto_tax_calc_flag,                          -- �d����T�C�g�����Ŏ����v�Z�v�Z
                       auto_tax_calc_override,                      -- �d����T�C�g�����Ŏ����v�Z�㏑
                       bank_charge_bearer,                          -- �d����T�C�g��s�萔�����S��
                       bank_branch_type,                            -- �d����T�C�g��s�x�X�^�C�v
                       create_debit_memo_flag,                      -- �d����T�C�gRTS�������f�r�b
                       supplier_notif_method,                       -- �d����T�C�g�d����ʒm���@
                       email_address,                               -- �d����T�C�gE���[���A�h���X
                       primary_pay_site_flag,                       -- �d����T�C�g��x���T�C�g�t���O
                       purchasing_site_flag                         -- �d����T�C�g�w���t���O
              INTO     gv_s_vendor_site_code,
                       gv_s_address_line1,
                       gv_s_address_line2,
                       gv_s_address_line3,
                       gv_s_city,
                       gv_s_state,
                       gv_s_zip,
                       gv_s_province,
                       gv_s_country,
                       gv_s_area_code,
                       gv_s_phone,
                       gv_s_fax,
                       gv_s_fax_area_code,
                       gv_s_payment_method,
                       gv_s_bank_account_name,
                       gv_s_bank_account_num,
                       gv_s_bank_num,
                       gv_s_bank_account_type,
                       gv_s_vat_code,
                       gn_s_distribution_set_id,
                       gn_s_accts_pay_ccid,
                       gn_s_prepay_ccid,
                       gn_s_terms_id,
                       gn_s_invoice_amount_limit,
                       gv_s_attribute_category,
                       gv_s_attribute1,
                       gv_s_attribute2,
                       gv_s_attribute3,
                       gv_s_attribute4,
                       gv_s_attribute5,
                       gv_s_attribute6,
                       gv_s_attribute7,
                       gv_s_attribute8,
                       gv_s_attribute9,
                       gv_s_attribute10,
                       gv_s_attribute11,
                       gv_s_attribute12,
                       gv_s_attribute13,
                       gv_s_attribute14,
                       gv_s_attribute15,
                       gv_s_bank_number,
                       gv_s_address_line4,
                       gv_s_county,
                       gv_s_allow_awt_flag,
                       gn_s_awt_group_id,
                       gv_s_vendor_site_code_alt,
                       gv_s_address_lines_alt,
                       gv_s_ap_tax_rounding_rule,
                       gv_s_atc_flag,
                       gv_s_atc_override,
                       gv_s_bank_charge_bearer,
                       gv_s_bank_branch_type,
                       gv_s_cdm_flag,
                       gv_s_sn_method,
                       gv_s_email_address,
                       gv_s_pps_flag,
                       gv_s_ps_flag
              FROM     po_vendor_sites_all
              WHERE    vendor_site_id = gn_s_vendor_site_id;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_cmm                                -- 'XXCMM'
                                ,iv_name         => cv_msg_00213                                  -- �d����T�C�g�}�X�^�f�[�^�擾�G���[
                                ,iv_token_name1  => cv_tkn_word                                   -- �g�[�N��(NG_WORD)
                                ,iv_token_value1 => cv_tkn_word1                                  -- NG_WORD
                                ,iv_token_name2  => cv_tkn_data                                   -- �g�[�N��(NG_DATA)
                                ,iv_token_value2 => gt_u_people_data(ln_loop_cnt).employee_number -- NG_WORD��DATA
                               );
                lv_errbuf := lv_errmsg;
                RAISE global_api_expt;
              WHEN OTHERS THEN
                RAISE global_api_others_expt;
            END;
            -- �ٓ��̏ꍇ�A�������ɖ��������Z�b�g
            gd_v_end_date_active := ld_end_date_active;
          ELSIF (lv_kbn = cv_t) THEN
            -- �ސE�̏ꍇ�A�������ɑސE�N�����̎��̓����Z�b�g
            gd_v_end_date_active := xxccp_common_pkg2.get_working_day(
                                        gt_u_people_data(ln_loop_cnt).actual_termination_date
                                       ,1
                                       ,gv_cal_code
                                      );
            IF (gd_v_end_date_active IS NULL) THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cmm           -- 'XXCMM'
                              ,iv_name         => cv_msg_00036             -- ���̃V�X�e���ғ����擾�G���[
                             );
              lv_errbuf := lv_errmsg;
              RAISE global_api_expt;
            END IF;
          END IF;
          --
-- Ver1.2  2009/04/21  Add  ��Q�FT1_0255�Ή�  �V�[�P���X���擾������ǉ�
          SELECT   xxcso_xx03_vendors_if_s01.NEXTVAL
          INTO     gn_v_interface_id
          FROM     dual;
-- End Ver1.2
          --
          --========================================
          -- CSV�t�@�C���o��(A-6)
          --========================================
          lv_csv_text := gn_v_interface_id || cv_delimiter                                  -- �d����C���^�[�t�F�[�XID(�A��)
            || cv_enclosed || cv_update_flg || cv_enclosed || cv_delimiter                  -- �ǉ��X�V�t���O
            || SUBSTRB(gt_u_people_data(ln_loop_cnt).vendor_id,1,22) || cv_delimiter        -- �d����d����ID
            || cv_enclosed || gv_v_vendor_name || cv_enclosed || cv_delimiter               -- �d����d���於
            || cv_enclosed || gv_v_segment1 || cv_enclosed || cv_delimiter                  -- �d����d����ԍ�
            || gn_v_employee_id || cv_delimiter                                             -- �d����]�ƈ�ID
            || cv_enclosed || gv_v_vendor_type || cv_enclosed || cv_delimiter               -- �d����d����^�C�v
            || gn_v_terms_id || cv_delimiter                                                -- �d����x������
            || cv_enclosed || gv_v_pay_group || cv_enclosed || cv_delimiter                 -- �d����x���O���[�v�R�[�h
            || gn_v_invoice_amount_limit || cv_delimiter                                    -- �d���搿�����x�z
            || gn_v_accts_pay_ccid || cv_delimiter                                          -- �d���敉����Ȗ�ID
            || gn_v_prepay_ccid || cv_delimiter                                             -- �d����O���^����������Ȗ�ID
            || TO_CHAR(gd_v_end_date_active,'YYYYMMDD') || cv_delimiter                     -- �d���斳����
            || cv_enclosed || gv_v_sb_flag || cv_enclosed || cv_delimiter                   -- �d���撆���@�l�t���O
            || cv_enclosed || gv_v_rr_flag || cv_enclosed || cv_delimiter                   -- �d��������m�F�t���O
            || cv_enclosed || gv_v_attribute_category || cv_enclosed || cv_delimiter        -- �d����\���J�e�S��
            || cv_enclosed || gv_v_attribute1 || cv_enclosed || cv_delimiter                -- �d����\��1
            || cv_enclosed || gv_v_attribute2 || cv_enclosed || cv_delimiter                -- �d����\��2
            || cv_enclosed || gv_v_attribute3 || cv_enclosed || cv_delimiter                -- �d����\��3
            || cv_enclosed || gv_v_attribute4 || cv_enclosed || cv_delimiter                -- �d����\��4
            || cv_enclosed || gv_v_attribute5 || cv_enclosed || cv_delimiter                -- �d����\��5
            || cv_enclosed || gv_v_attribute6 || cv_enclosed || cv_delimiter                -- �d����\��6
            || cv_enclosed || gv_v_attribute7 || cv_enclosed || cv_delimiter                -- �d����\��7
            || cv_enclosed || gv_v_attribute8 || cv_enclosed || cv_delimiter                -- �d����\��8
            || cv_enclosed || gv_v_attribute9 || cv_enclosed || cv_delimiter                -- �d����\��9
            || cv_enclosed || gv_v_attribute10 || cv_enclosed || cv_delimiter               -- �d����\��10
            || cv_enclosed || gv_v_attribute11 || cv_enclosed || cv_delimiter               -- �d����\��11
            || cv_enclosed || gv_v_attribute12 || cv_enclosed || cv_delimiter               -- �d����\��12
            || cv_enclosed || gv_v_attribute13 || cv_enclosed || cv_delimiter               -- �d����\��13
            || cv_enclosed || gv_v_attribute14 || cv_enclosed || cv_delimiter               -- �d����\��14
            || cv_enclosed || gv_v_attribute15 || cv_enclosed || cv_delimiter               -- �d����\��15
            || cv_enclosed || gv_v_allow_awt_flag || cv_enclosed || cv_delimiter            -- �d���挹�򒥎��Ŏg�p�t���O
            || cv_enclosed || gv_v_vendor_name_alt || cv_enclosed || cv_delimiter           -- �d����d����J�i����
            || cv_enclosed || gv_v_ap_tax_rounding_rule || cv_enclosed || cv_delimiter      -- �d���搿���Ŏ����v�Z�[�������K
            || cv_enclosed || gv_v_atc_flag || cv_enclosed || cv_delimiter                  -- �d���搿���Ŏ����v�Z�v�Z���x��
            || cv_enclosed || gv_v_atc_override || cv_enclosed || cv_delimiter              -- �d���搿���Ŏ����v�Z�㏑���̋�
            || cv_enclosed || gv_v_bank_charge_bearer || cv_enclosed || cv_delimiter        -- �d�����s�萔�����S��
          ;
          IF (lv_kbn = cv_i) THEN
            -- �ٓ��̏ꍇ�A�d����T�C�g�}�X�^�f�[�^���Z�b�g
            lv_csv_text := lv_csv_text || SUBSTRB(gn_s_vendor_site_id,1,22) || cv_delimiter -- �d����T�C�g�d����T�C�gID
              || cv_enclosed || gv_s_vendor_site_code || cv_enclosed || cv_delimiter        -- �d����T�C�g�d����T�C�g��
              || cv_enclosed || gv_s_address_line1 || cv_enclosed || cv_delimiter           -- �d����T�C�g���ݒn1
              || cv_enclosed || gv_s_address_line2 || cv_enclosed || cv_delimiter           -- �d����T�C�g���ݒn2
              || cv_enclosed || gv_s_address_line3 || cv_enclosed || cv_delimiter           -- �d����T�C�g���ݒn3
              || cv_enclosed || gv_s_city || cv_enclosed || cv_delimiter                    -- �d����T�C�g�Z���E�S�s��
              || cv_enclosed || gv_s_state || cv_enclosed || cv_delimiter                   -- �d����T�C�g�Z���E�s���{��
              || cv_enclosed || gv_s_zip || cv_enclosed || cv_delimiter                     -- �d����T�C�g�Z���E�X�֔ԍ�
              || cv_enclosed || gv_s_province || cv_enclosed || cv_delimiter                -- �d����T�C�g�Z���E�B
              || cv_enclosed || gv_s_country || cv_enclosed || cv_delimiter                 -- �d����T�C�g��
              || cv_enclosed || gv_s_area_code || cv_enclosed || cv_delimiter               -- �d����T�C�g�s�O�ǔ�
              || cv_enclosed || gv_s_phone || cv_enclosed || cv_delimiter                   -- �d����T�C�g�d�b�ԍ�
              || cv_enclosed || gv_s_fax || cv_enclosed || cv_delimiter                     -- �d����T�C�gFAX
              || cv_enclosed || gv_s_fax_area_code || cv_enclosed || cv_delimiter           -- �d����T�C�gFAX�s�O�ǔ�
              || cv_enclosed || gv_s_payment_method || cv_enclosed || cv_delimiter          -- �d����T�C�g�x�����@
              || cv_enclosed || gv_s_bank_account_name || cv_enclosed || cv_delimiter       -- �d����T�C�g��������
              || cv_enclosed || gv_s_bank_account_num || cv_enclosed || cv_delimiter        -- �d����T�C�g�����ԍ�
              || cv_enclosed || gv_s_bank_num || cv_enclosed || cv_delimiter                -- �d����T�C�g��s�R�[�h
              || cv_enclosed || gv_s_bank_account_type || cv_enclosed || cv_delimiter       -- �d����T�C�g�a�����
              || cv_enclosed || gv_s_vat_code || cv_enclosed || cv_delimiter                -- �d����T�C�g�������ŋ��R�[�h
              || gn_s_distribution_set_id || cv_delimiter                                   -- �d����T�C�g�z���Z�b�gID
              || gn_s_accts_pay_ccid || cv_delimiter                                        -- �d����T�C�g������Ȗ�ID
              || gn_s_prepay_ccid || cv_delimiter                                           -- �d����T�C�g�O���^�����������
              || cv_enclosed || lv_new_pay_group || cv_enclosed || cv_delimiter             -- �d����T�C�g�x���O���[�v�R�[�h
              || gn_s_terms_id || cv_delimiter                                              -- �d����T�C�g�x������
              || gn_s_invoice_amount_limit || cv_delimiter                                  -- �d����T�C�g�������x�z
              || cv_enclosed || gv_s_attribute_category || cv_enclosed || cv_delimiter      -- �d����T�C�g�\���J�e�S��
              || cv_enclosed || gv_s_attribute1 || cv_enclosed || cv_delimiter              -- �d����T�C�g�\��1
              || cv_enclosed || gv_s_attribute2 || cv_enclosed || cv_delimiter              -- �d����T�C�g�\��2
              || cv_enclosed || gv_s_attribute3 || cv_enclosed || cv_delimiter              -- �d����T�C�g�\��3
              || cv_enclosed || gv_s_attribute4 || cv_enclosed || cv_delimiter              -- �d����T�C�g�\��4
              || cv_enclosed || gt_u_people_data(ln_loop_cnt).ass_attribute3                -- �d����T�C�g�\��5
              || cv_enclosed || cv_delimiter
              || cv_enclosed || gv_s_attribute6 || cv_enclosed || cv_delimiter              -- �d����T�C�g�\��6
              || cv_enclosed || gv_s_attribute7 || cv_enclosed || cv_delimiter              -- �d����T�C�g�\��7
              || cv_enclosed || gv_s_attribute8 || cv_enclosed || cv_delimiter              -- �d����T�C�g�\��8
              || cv_enclosed || gv_s_attribute9 || cv_enclosed || cv_delimiter              -- �d����T�C�g�\��9
              || cv_enclosed || gv_s_attribute10 || cv_enclosed || cv_delimiter             -- �d����T�C�g�\��10
              || cv_enclosed || gv_s_attribute11 || cv_enclosed || cv_delimiter             -- �d����T�C�g�\��11
              || cv_enclosed || gv_s_attribute12 || cv_enclosed || cv_delimiter             -- �d����T�C�g�\��12
              || cv_enclosed || gv_s_attribute13 || cv_enclosed || cv_delimiter             -- �d����T�C�g�\��13
              || cv_enclosed || gv_s_attribute14 || cv_enclosed || cv_delimiter             -- �d����T�C�g�\��14
              || cv_enclosed || gv_s_attribute15 || cv_enclosed || cv_delimiter             -- �d����T�C�g�\��15
              || cv_enclosed || gv_s_bank_number || cv_enclosed || cv_delimiter             -- �d����T�C�g��s�x�X�R�[�h
              || cv_enclosed || gv_s_address_line4 || cv_enclosed || cv_delimiter           -- �d����T�C�g���ݒn4
              || cv_enclosed || gv_s_county || cv_enclosed || cv_delimiter                  -- �d����T�C�g�S
              || cv_enclosed || gv_s_allow_awt_flag || cv_enclosed || cv_delimiter          -- �d����T�C�g���򒥎��Ŏg�p�t��
              || gn_s_awt_group_id || cv_delimiter                                          -- �d����T�C�g���򒥎��ŃO���[�v
              || cv_enclosed || gv_s_vendor_site_code_alt || cv_enclosed || cv_delimiter    -- �d����T�C�g�d����T�C�g���i�J
              || cv_enclosed || gv_s_address_lines_alt || cv_enclosed || cv_delimiter       -- �d����T�C�g�Z���J�i
              || cv_enclosed || gv_s_ap_tax_rounding_rule || cv_enclosed || cv_delimiter    -- �d����T�C�g�����Ŏ����v�Z�[��
              || cv_enclosed || gv_s_atc_flag || cv_enclosed || cv_delimiter                -- �d����T�C�g�����Ŏ����v�Z�v�Z
              || cv_enclosed || gv_s_atc_override || cv_enclosed || cv_delimiter            -- �d����T�C�g�����Ŏ����v�Z�㏑
              || cv_enclosed || gv_s_bank_charge_bearer || cv_enclosed || cv_delimiter      -- �d����T�C�g��s�萔�����S��
              || cv_enclosed || gv_s_bank_branch_type || cv_enclosed || cv_delimiter        -- �d����T�C�g��s�x�X�^�C�v
              || cv_enclosed || gv_s_cdm_flag || cv_enclosed || cv_delimiter                -- �d����T�C�gRTS�������f�r�b
              || cv_enclosed || gv_s_sn_method || cv_enclosed || cv_delimiter               -- �d����T�C�g�d����ʒm���@
              || cv_enclosed || gv_s_email_address || cv_enclosed || cv_delimiter           -- �d����T�C�gE���[���A�h���X
              || cv_enclosed || gv_s_pps_flag || cv_enclosed || cv_delimiter                -- �d����T�C�g��x���T�C�g�t���O
              || cv_enclosed || gv_s_ps_flag || cv_enclosed || cv_delimiter                 -- �d����T�C�g�w���t���O
              || cv_enclosed || gv_bank_number || cv_enclosed || cv_delimiter               -- ��s������s�x�X�R�[�h
              || cv_enclosed || gv_bank_num || cv_enclosed || cv_delimiter                  -- ��s������s�R�[�h
              || cv_enclosed || gv_bank_nm || '/' || gv_shiten_nm                           -- ��s������������
              || cv_enclosed || cv_delimiter
              || cv_enclosed || gv_account_num || cv_enclosed || cv_delimiter               -- ��s���������ԍ�
              || cv_enclosed || gv_currency_cd || cv_enclosed || cv_delimiter               -- ��s�����ʉ݃R�[�h
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s�����E�v
              || NULL || cv_delimiter                                                       -- ��s�������a������Ȗ�ID
              || cv_enclosed || gv_account_type || cv_enclosed || cv_delimiter              -- ��s�����a�����
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s�����\���J�e�S��
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s�����\��1
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s�����\��2
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s�����\��3
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s�����\��4
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s�����\��5
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s�����\��6
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s�����\��7
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s�����\��8
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s�����\��9
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s�����\��10
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s�����\��11
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s�����\��12
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s�����\��13
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s�����\��14
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s�����\��15
              || NULL || cv_delimiter                                                       -- ��s�����������ϊ���Ȗ�ID
              || NULL || cv_delimiter                                                       -- ��s������s�萔������Ȗ�ID
              || NULL || cv_delimiter                                                       -- ��s������s�G���[����Ȗ�ID
              || cv_enclosed || gv_holder_nm || cv_enclosed || cv_delimiter                 -- ��s�����������`�l��
              || cv_enclosed || gv_holder_alt_nm || cv_enclosed || cv_delimiter             -- ��s�����������`�l��(�J�i)
              || TO_CHAR(gd_process_date,'YYYYMMDD') || cv_delimiter                        -- ��s���������J�n��
              || NULL || cv_delimiter                                                       -- ��s���������I����
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s���������\���J�e�S��
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s���������\��1
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s���������\��2
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s���������\��3
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s���������\��4
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s���������\��5
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s���������\��6
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s���������\��7
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s���������\��8
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s���������\��9
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s���������\��10
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s���������\��11
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s���������\��12
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s���������\��13
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s���������\��14
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s���������\��15
              || cv_enclosed || cv_status_flg || cv_enclosed                                -- �X�e�[�^�X�t���O
            ;
          ELSIF (lv_kbn = cv_t) THEN
            -- �ސE�̏ꍇ�ANULL���Z�b�g
            lv_csv_text := lv_csv_text || NULL || cv_delimiter                              -- �d����T�C�g�d����T�C�gID
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�g�d����T�C�g��
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�g���ݒn1
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�g���ݒn2
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�g���ݒn3
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�g�Z���E�S�s��
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�g�Z���E�s���{��
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�g�Z���E�X�֔ԍ�
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�g�Z���E�B
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�g��
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�g�s�O�ǔ�
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�g�d�b�ԍ�
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�gFAX
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�gFAX�s�O�ǔ�
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�g�x�����@
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�g��������
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�g�����ԍ�
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�g��s�R�[�h
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�g�a�����
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�g�������ŋ��R�[�h
              || NULL || cv_delimiter                                                       -- �d����T�C�g�z���Z�b�gID
              || NULL || cv_delimiter                                                       -- �d����T�C�g������Ȗ�ID
              || NULL || cv_delimiter                                                       -- �d����T�C�g�O���^�����������
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�g�x���O���[�v�R�[�h
              || NULL || cv_delimiter                                                       -- �d����T�C�g�x������
              || NULL || cv_delimiter                                                       -- �d����T�C�g�������x�z
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�g�\���J�e�S��
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�g�\��1
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�g�\��2
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�g�\��3
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�g�\��4
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�g�\��5
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�g�\��6
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�g�\��7
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�g�\��8
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�g�\��9
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�g�\��10
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�g�\��11
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�g�\��12
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�g�\��13
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�g�\��14
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�g�\��15
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�g��s�x�X�R�[�h
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�g���ݒn4
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�g�S
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�g���򒥎��Ŏg�p�t��
              || NULL || cv_delimiter                                                       -- �d����T�C�g���򒥎��ŃO���[�v
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�g�d����T�C�g���i�J
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�g�Z���J�i
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�g�����Ŏ����v�Z�[��
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�g�����Ŏ����v�Z�v�Z
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�g�����Ŏ����v�Z�㏑
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�g��s�萔�����S��
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�g��s�x�X�^�C�v
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�gRTS�������f�r�b
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�g�d����ʒm���@
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�gE���[���A�h���X
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�g��x���T�C�g�t���O
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- �d����T�C�g�w���t���O
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s������s�x�X�R�[�h
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s������s�R�[�h
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s������������
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s���������ԍ�
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s�����ʉ݃R�[�h
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s�����E�v
              || NULL || cv_delimiter                                                       -- ��s�������a������Ȗ�ID
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s�����a�����
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s�����\���J�e�S��
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s�����\��1
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s�����\��2
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s�����\��3
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s�����\��4
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s�����\��5
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s�����\��6
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s�����\��7
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s�����\��8
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s�����\��9
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s�����\��10
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s�����\��11
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s�����\��12
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s�����\��13
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s�����\��14
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s�����\��15
              || NULL || cv_delimiter                                                       -- ��s�����������ϊ���Ȗ�ID
              || NULL || cv_delimiter                                                       -- ��s������s�萔������Ȗ�ID
              || NULL || cv_delimiter                                                       -- ��s������s�G���[����Ȗ�ID
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s�����������`�l��
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s�����������`�l��(�J�i)
              || NULL || cv_delimiter                                                       -- ��s���������J�n��
              || NULL || cv_delimiter                                                       -- ��s���������I����
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s���������\���J�e�S��
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s���������\��1
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s���������\��2
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s���������\��3
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s���������\��4
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s���������\��5
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s���������\��6
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s���������\��7
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s���������\��8
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s���������\��9
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s���������\��10
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s���������\��11
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s���������\��12
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s���������\��13
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s���������\��14
              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- ��s���������\��15
              || cv_enclosed || cv_status_flg || cv_enclosed                                -- �X�e�[�^�X�t���O
            ;
          END IF;
          BEGIN
            -- �t�@�C����������
            UTL_FILE.PUT_LINE(gf_file_hand,lv_csv_text);
          EXCEPTION
            -- �t�@�C���A�N�Z�X�����G���[
            WHEN UTL_FILE.INVALID_OPERATION THEN
              lv_errmsg := xxcmn_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cmm                                 -- 'XXCMM'
                              ,iv_name         => cv_msg_00007                                   -- �t�@�C���A�N�Z�X�����G���[
                             );
              lv_errbuf := lv_errmsg;
              RAISE global_api_expt;
            --
            -- CSV�f�[�^�o�̓G���[
            WHEN UTL_FILE.WRITE_ERROR THEN
              lv_errmsg := xxcmn_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cmm                                 -- 'XXCMM'
                              ,iv_name         => cv_msg_00009                                   -- CSV�f�[�^�o�̓G���[
                              ,iv_token_name1  => cv_tkn_word                                    -- �g�[�N��(NG_WORD)
                              ,iv_token_value1 => cv_tkn_word1                                   -- NG_WORD
                              ,iv_token_name2  => cv_tkn_data                                    -- �g�[�N��(NG_DATA)
                              ,iv_token_value2 => gt_u_people_data(ln_loop_cnt).employee_number  -- NG_WORD��DATA
                             );
              lv_errbuf := lv_errmsg;
              RAISE global_api_expt;
            WHEN OTHERS THEN
              RAISE global_api_others_expt;
          END;
          gn_normal_cnt := gn_normal_cnt + 1;
-- Ver1.2  2009/04/21  Del  ��Q�FT1_0255�Ή�  �V�[�P���X���擾���邽�ߍ폜
--          gn_v_interface_id := gn_v_interface_id + 1;
-- End Ver1.2
        END IF;
      END IF;
      lv_employee_number := gt_u_people_data(ln_loop_cnt).employee_number;
    END LOOP u_out_loop;
    -- �Ώی����̎擾
    gn_target_cnt := gn_target_update_cnt - ln_o_cnt;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
--#####################################  �Œ蕔 END   ##########################################
--
  END update_output_csv;
--
  /**********************************************************************************
   * Procedure Name   : get_i_people_data
   * Description      : �V�K�o�^�̎Ј��f�[�^�擾�v���V�[�W��(A-7)
   ***********************************************************************************/
  PROCEDURE get_i_people_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_i_people_data';       -- �v���O������
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
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
   -- �J�[�\���I�[�v��
    OPEN get_i_people_data_cur;
--
    -- �f�[�^�̈ꊇ�擾
    FETCH get_i_people_data_cur BULK COLLECT INTO gt_i_people_data;
--
    -- �V�K�o�^�ȊO�̑Ώی������Z�b�g
    gn_target_add_cnt := gt_i_people_data.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE get_i_people_data_cur;
--
    -- �Ώی����̎擾
    gn_target_cnt := gn_target_cnt + gn_target_add_cnt;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
--#####################################  �Œ蕔 END   ##########################################
--
  END get_i_people_data;
--
  /**********************************************************************************
   * Procedure Name   : add_output_csv
   * Description      : CSV�t�@�C���o��(�V�K�o�^)�v���V�[�W��(A-9)
   ***********************************************************************************/
  PROCEDURE add_output_csv(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'add_output_csv';     -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf           VARCHAR2(5000);           -- �G���[�E���b�Z�[�W
    lv_retcode          VARCHAR2(1);              -- ���^�[���E�R�[�h
    lv_errmsg           VARCHAR2(5000);           -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_delimiter        CONSTANT VARCHAR2(1)  := ',';                -- CSV��؂蕶��
    cv_enclosed         CONSTANT VARCHAR2(2)  := '"';                -- �P��͂ݕ���
--
    -- *** ���[�J���ϐ� ***
    ln_loop_cnt         NUMBER;                   -- ���[�v�J�E���^
    lv_csv_text         VARCHAR2(32000);          -- �o�͂P�s��������ϐ�
    lv_pay_group        VARCHAR2(50);             -- �x���O���[�v�R�[�h
    lv_ret_flg          VARCHAR2(1);              -- �x���O���[�v�R�[�h�擾�����p�t���O
    lv_employee_number  VARCHAR2(22);             -- �]�ƈ��ԍ��d���`�F�b�N�p
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
    <<i_out_loop>>
    FOR ln_loop_cnt IN gt_i_people_data.FIRST..gt_i_people_data.LAST LOOP
      --========================================
      -- �]�ƈ��ԍ��d���`�F�b�N(A-8-1)
      --========================================
      -- �]�ƈ��ԍ����d�����Ă���ꍇ�A�x�����b�Z�[�W��\��
      IF (lv_employee_number = gt_i_people_data(ln_loop_cnt).employee_number) THEN
        -- �x���t���O�ɃI�����Z�b�g
        gv_warn_flg := '1';
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm                                  -- 'XXCMM'
                        ,iv_name         => cv_msg_00209                                    -- �]�ƈ��ԍ��d�����b�Z�[�W
                        ,iv_token_name1  => cv_tkn_word                                     -- �g�[�N��(NG_WORD)
                        ,iv_token_value1 => cv_tkn_word1                                    -- NG_WORD
                        ,iv_token_name2  => cv_tkn_data                                     -- �g�[�N��(NG_DATA)
                        ,iv_token_value2 => gt_i_people_data(ln_loop_cnt).employee_number   -- NG_WORD��DATA
                                              || cv_tkn_word2
                                              || gt_i_people_data(ln_loop_cnt).per_information18
                                              || '�@'
                                              || gt_i_people_data(ln_loop_cnt).per_information19
                       );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
      END IF;
      --========================================
      -- ����R�[�h�`�F�b�N(A-8-2)
      --========================================
      IF (gt_i_people_data(ln_loop_cnt).ass_attribute3 IS NULL) THEN
        -- �x���t���O�ɃI�����Z�b�g
        gv_warn_flg := '1';
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm                                  -- 'XXCMM'
                        ,iv_name         => cv_msg_00208                                    -- �Ζ��n���_�R�[�h(�V)�����̓G���[
                        ,iv_token_name1  => cv_tkn_word                                     -- �g�[�N��(NG_WORD)
                        ,iv_token_value1 => cv_tkn_word1                                    -- NG_WORD
                        ,iv_token_name2  => cv_tkn_data                                     -- �g�[�N��(NG_DATA)
                        ,iv_token_value2 => gt_i_people_data(ln_loop_cnt).employee_number   -- NG_WORD��DATA
                       );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
        -- �X�L�b�v�������J�E���g
        gn_warn_cnt := gn_warn_cnt + 1;
      ELSE
        --========================================
        -- �x���O���[�v�擾(A-8-3)
        --========================================
        BEGIN
          SELECT   '1'
          INTO     lv_ret_flg
          FROM     fnd_lookup_values_vl
          WHERE    lookup_type = gv_group_type_nm
          AND      attribute2 = gt_i_people_data(ln_loop_cnt).ass_attribute3
          AND      ROWNUM = 1;
          IF (gt_i_people_data(ln_loop_cnt).ass_attribute3 = gv_pay_bumon_cd) THEN
            lv_pay_group := gv_pay_bumon_nm || '-' || gv_pay_method_nm || '/' || gv_pay_bank|| '/' || gv_pay_type_nm;
          ELSE
            lv_pay_group := gt_i_people_data(ln_loop_cnt).ass_attribute3 || '-' || gv_koguti_genkin_nm || '/' || gv_pay_type_nm;
          END IF;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lv_pay_group := gv_pay_bumon_nm || '-' || gv_pay_method_nm || '/' || gv_pay_bank|| '/' || gv_pay_type_nm;
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
        IF (LENGTHB(lv_pay_group) > cv_pay_group_length) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cmm                                -- 'XXCMM'
                          ,iv_name         => cv_msg_00215                                  -- �x���O���[�v�R�[�h�����������G���[
                          ,iv_token_name1  => cv_tkn_length                                 -- �g�[�N��(NG_LENGTH)
                          ,iv_token_value1 => cv_pay_group_length                           -- �x���O���[�v�R�[�h�̍ő啶����
                          ,iv_token_name2  => cv_tkn_word                                   -- �g�[�N��(NG_WORD)
                          ,iv_token_value2 => cv_tkn_word1                                  -- NG_WORD
                          ,iv_token_name3  => cv_tkn_data                                   -- �g�[�N��(NG_DATA)
                          ,iv_token_value3 => gt_i_people_data(ln_loop_cnt).employee_number -- NG_WORD��DATA
                                                || cv_tkn_word3
                                                || lv_pay_group
                         );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
        --
-- Ver1.2  2009/04/21  Add  ��Q�FT1_0255�Ή�  �V�[�P���X���擾������ǉ�
        SELECT   xxcso_xx03_vendors_if_s01.NEXTVAL
        INTO     gn_v_interface_id
        FROM     dual;
-- End Ver1.2
        --
        --========================================
        -- CSV�t�@�C���o��(A-9)
        --========================================
        lv_csv_text := gn_v_interface_id || cv_delimiter                                    -- �d����C���^�[�t�F�[�XID(�A��)
          || cv_enclosed || cv_insert_flg || cv_enclosed || cv_delimiter                    -- �ǉ��X�V�t���O
-- Ver1.2  2009/04/24  Add  �d����o�^�ς݁A�T�C�g�u��Ёv���o�^�Ή�
--          || NULL || cv_delimiter                                                           -- �d����d����ID
          || gt_i_people_data(ln_loop_cnt).vendor_id || cv_delimiter                        -- �d����d����ID
-- End Ver1.2
          || cv_enclosed || SUBSTRB(gt_i_people_data(ln_loop_cnt).per_information18         -- �d����d���於
          || gt_i_people_data(ln_loop_cnt).per_information19 || '�^'
          || TO_MULTI_BYTE(gt_i_people_data(ln_loop_cnt).employee_number),1,80)
          || cv_enclosed || cv_delimiter
          || cv_enclosed || SUBSTRB(cv_9000                                                 -- �d����d����ԍ�
          || gt_i_people_data(ln_loop_cnt).employee_number,1,30)
          || cv_enclosed || cv_delimiter
          || SUBSTRB(gt_i_people_data(ln_loop_cnt).person_id,1,22) || cv_delimiter          -- �d����]�ƈ�ID
          || cv_enclosed || gv_vendor_type || cv_enclosed || cv_delimiter                   -- �d����d����^�C�v
          || NULL || cv_delimiter                                                           -- �d����x������
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����x���O���[�v�R�[�h
          || NULL || cv_delimiter                                                           -- �d���搿�����x�z
          || NULL || cv_delimiter                                                           -- �d���敉����Ȗ�ID
          || NULL || cv_delimiter                                                           -- �d����O���^����������Ȗ�ID
          || NULL || cv_delimiter                                                           -- �d���斳����
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d���撆���@�l�t���O
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d��������m�F�t���O
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����\���J�e�S��
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����\��1
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����\��2
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����\��3
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����\��4
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����\��5
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����\��6
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����\��7
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����\��8
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����\��9
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����\��10
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����\��11
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����\��12
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����\��13
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����\��14
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����\��15
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d���挹�򒥎��Ŏg�p�t���O
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����d����J�i����
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d���搿���Ŏ����v�Z�[�������K
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d���搿���Ŏ����v�Z�v�Z���x��
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d���搿���Ŏ����v�Z�㏑���̋�
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d�����s�萔�����S��
          || NULL || cv_delimiter                                                           -- �d����T�C�g�d����T�C�gID

-- Ver1.2  2009/04/21  Mod  ��Q�FT1_0438�Ή�  �T�C�g�R�[�h���u��Ёv�ɏC��
--          || cv_enclosed || SUBSTRB(cv_9000                                                 -- �d����T�C�g�d����T�C�g��
--          || gt_i_people_data(ln_loop_cnt).employee_number,1,15)
--          || cv_enclosed || cv_delimiter
          || cv_enclosed || cv_site_code_comp || cv_enclosed || cv_delimiter                -- �d����T�C�g�d����T�C�g��
-- End Ver1.2
          || cv_enclosed || gv_address_nm1 || cv_enclosed || cv_delimiter                   -- �d����T�C�g���ݒn1
          || cv_enclosed || gv_address_nm2 || cv_enclosed || cv_delimiter                   -- �d����T�C�g���ݒn2
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����T�C�g���ݒn3
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����T�C�g�Z���E�S�s��
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����T�C�g�Z���E�s���{��
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����T�C�g�Z���E�X�֔ԍ�
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����T�C�g�Z���E�B
          || cv_enclosed || gv_country || cv_enclosed || cv_delimiter                       -- �d����T�C�g��
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����T�C�g�s�O�ǔ�
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����T�C�g�d�b�ԍ�
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����T�C�gFAX
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����T�C�gFAX�s�O�ǔ�
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����T�C�g�x�����@
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����T�C�g��������
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����T�C�g�����ԍ�
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����T�C�g��s�R�[�h
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����T�C�g�a�����
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����T�C�g�������ŋ��R�[�h
          || NULL || cv_delimiter                                                           -- �d����T�C�g�z���Z�b�gID
          || gv_accts_pay_ccid || cv_delimiter                                              -- �d����T�C�g������Ȗ�ID
          || gv_prepay_ccid || cv_delimiter                                                 -- �d����T�C�g�O���^�����������
          || cv_enclosed || lv_pay_group || cv_enclosed || cv_delimiter                     -- �d����T�C�g�x���O���[�v�R�[�h
          || gv_terms_id || cv_delimiter                                                    -- �d����T�C�g�x������
          || NULL || cv_delimiter                                                           -- �d����T�C�g�������x�z
-- Ver1.1 2009/03/03 Mod  �d����T�C�g��ATTRIBUTE_CATEGORY��ORG_ID��ݒ�
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����T�C�g�\���J�e�S��
          || cv_enclosed || gn_org_id || cv_enclosed || cv_delimiter                        -- �d����T�C�g�\���J�e�S��
-- End
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����T�C�g�\��1
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����T�C�g�\��2
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����T�C�g�\��3
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����T�C�g�\��4
          || cv_enclosed || gt_i_people_data(ln_loop_cnt).ass_attribute3                    -- �d����T�C�g�\��5
          || cv_enclosed || cv_delimiter
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����T�C�g�\��6
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����T�C�g�\��7
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����T�C�g�\��8
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����T�C�g�\��9
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����T�C�g�\��10
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����T�C�g�\��11
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����T�C�g�\��12
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����T�C�g�\��13
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����T�C�g�\��14
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����T�C�g�\��15
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����T�C�g��s�x�X�R�[�h
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����T�C�g���ݒn4
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����T�C�g�S
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����T�C�g���򒥎��Ŏg�p�t��
          || NULL || cv_delimiter                                                           -- �d����T�C�g���򒥎��ŃO���[�v
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����T�C�g�d����T�C�g���i�J
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����T�C�g�Z���J�i
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����T�C�g�����Ŏ����v�Z�[��
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����T�C�g�����Ŏ����v�Z�v�Z
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����T�C�g�����Ŏ����v�Z�㏑
-- Ver1.2  2009/04/21  Add  ��Q�FT1_0438�Ή�  ��s�萔�����S�҂�ǉ�
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����T�C�g��s�萔�����S��
          || cv_enclosed || gv_s_bank_charge_new || cv_enclosed || cv_delimiter             -- �d����T�C�g��s�萔�����S��
-- End Ver1.2
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����T�C�g��s�x�X�^�C�v
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����T�C�gRTS�������f�r�b
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����T�C�g�d����ʒm���@
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����T�C�gE���[���A�h���X
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����T�C�g��x���T�C�g�t���O
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �d����T�C�g�w���t���O
          || cv_enclosed || gv_bank_number || cv_enclosed || cv_delimiter                   -- ��s������s�x�X�R�[�h
          || cv_enclosed || gv_bank_num || cv_enclosed || cv_delimiter                      -- ��s������s�R�[�h
          || cv_enclosed || SUBSTRB(gv_bank_nm || '/' || gv_shiten_nm,1,80)                 -- ��s������������
          || cv_enclosed || cv_delimiter
          || cv_enclosed || gv_account_num || cv_enclosed || cv_delimiter                   -- ��s���������ԍ�
          || cv_enclosed || gv_currency_cd || cv_enclosed || cv_delimiter                   -- ��s�����ʉ݃R�[�h
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- ��s�����E�v
          || NULL || cv_delimiter                                                           -- ��s�������a������Ȗ�ID
          || cv_enclosed || gv_account_type || cv_enclosed || cv_delimiter                  -- ��s�����a�����
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- ��s�����\���J�e�S��
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- ��s�����\��1
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- ��s�����\��2
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- ��s�����\��3
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- ��s�����\��4
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- ��s�����\��5
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- ��s�����\��6
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- ��s�����\��7
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- ��s�����\��8
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- ��s�����\��9
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- ��s�����\��10
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- ��s�����\��11
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- ��s�����\��12
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- ��s�����\��13
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- ��s�����\��14
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- ��s�����\��15
          || NULL || cv_delimiter                                                           -- ��s�����������ϊ���Ȗ�ID
          || NULL || cv_delimiter                                                           -- ��s������s�萔������Ȗ�ID
          || NULL || cv_delimiter                                                           -- ��s������s�G���[����Ȗ�ID
          || cv_enclosed || gv_holder_nm || cv_enclosed || cv_delimiter                     -- ��s�����������`�l��
          || cv_enclosed || gv_holder_alt_nm || cv_enclosed || cv_delimiter                 -- ��s�����������`�l��(�J�i)
          || TO_CHAR(gd_process_date,'YYYYMMDD') || cv_delimiter                            -- ��s���������J�n��
          || NULL || cv_delimiter                                                           -- ��s���������I����
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- ��s���������\���J�e�S��
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- ��s���������\��1
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- ��s���������\��2
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- ��s���������\��3
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- ��s���������\��4
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- ��s���������\��5
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- ��s���������\��6
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- ��s���������\��7
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- ��s���������\��8
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- ��s���������\��9
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- ��s���������\��10
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- ��s���������\��11
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- ��s���������\��12
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- ��s���������\��13
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- ��s���������\��14
          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- ��s���������\��15
          || cv_enclosed || cv_status_flg || cv_enclosed                                    -- �X�e�[�^�X�t���O
        ;
        BEGIN
          -- �t�@�C����������
          UTL_FILE.PUT_LINE(gf_file_hand,lv_csv_text);
        EXCEPTION
          -- �t�@�C���A�N�Z�X�����G���[
          WHEN UTL_FILE.INVALID_OPERATION THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cmm                                 -- 'XXCMM'
                            ,iv_name         => cv_msg_00007                                   -- �t�@�C���A�N�Z�X�����G���[
                           );
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          --
          -- CSV�f�[�^�o�̓G���[
          WHEN UTL_FILE.WRITE_ERROR THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cmm                                 -- 'XXCMM'
                            ,iv_name         => cv_msg_00009                                   -- CSV�f�[�^�o�̓G���[
                            ,iv_token_name1  => cv_tkn_word                                    -- �g�[�N��(NG_WORD)
                            ,iv_token_value1 => cv_tkn_word1                                   -- NG_WORD
                            ,iv_token_name2  => cv_tkn_data                                    -- �g�[�N��(NG_DATA)
                            ,iv_token_value2 => gt_i_people_data(ln_loop_cnt).employee_number  -- NG_WORD��DATA
                           );
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
        gn_normal_cnt := gn_normal_cnt + 1;
-- Ver1.2  2009/04/21  Del  ��Q�FT1_0255�Ή�  �V�[�P���X���擾���邽�ߍ폜
--        gn_v_interface_id := gn_v_interface_id + 1;
-- End Ver1.2
      END IF;
      lv_employee_number := gt_i_people_data(ln_loop_cnt).employee_number;
    END LOOP i_out_loop;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
--#####################################  �Œ蕔 END   ##########################################
--
  END add_output_csv;
--
  /**********************************************************************************
   * Procedure Name   : delete_table
   * Description      : �d����]�ƈ���񒆊�I/F�e�[�u���f�[�^�폜�v���V�[�W��(A-10)
   ***********************************************************************************/
  PROCEDURE delete_table(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_table';       -- �v���O������
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
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    BEGIN
-- Ver1.2  2009/04/21  Mod  ��Q�FT1_0255�Ή�  ��v�ƃo�b�e�B���O���Ȃ��悤������ǉ�
--      DELETE FROM xx03_vendors_interface;
      DELETE FROM xx03_vendors_interface
      WHERE  vndr_vendor_type_lkup_code = gv_vendor_type;
-- End Ver1.2
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm           -- 'XXCMM'
                        ,iv_name         => cv_msg_00012             -- �f�[�^�폜�G���[
                        ,iv_token_name1  => cv_tkn_table             -- �g�[�N��(NG_TABLE)
                        ,iv_token_value1 => cv_tkn_table_nm          -- �e�[�u����(�d����]�ƈ���񒆊�I/F�e�[�u��)
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
--#####################################  �Œ蕔 END   ##########################################
--
  END delete_table;
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain';                -- �v���O������
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
    gn_warn_cnt   := 0;
    gn_error_cnt  := 0;
    gv_warn_flg   := '0';
-- Ver1.2  2009/04/21  Del  ��Q�FT1_0255�Ή�  �V�[�P���X���擾���邽�ߍ폜
--    -- �C���^�[�t�F�[�XID
--    gn_v_interface_id := 1;
-- End Ver1.2
    --
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
    --
    -- =============================================================
    --  ���������v���V�[�W��(A-1)
    -- =============================================================
    init(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- =============================================================
    --  �V�K�o�^�ȊO�̎Ј��f�[�^�擾�v���V�[�W��(A-2)
    -- =============================================================
    get_u_people_data(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- =============================================================
    --  CSV�t�@�C���o��(�X�V)�v���V�[�W��(A-6)
    -- =============================================================
    IF (gn_target_update_cnt > 0) THEN
      update_output_csv(
         lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
    --
    -- =============================================================
    --  �V�K�o�^�̎Ј��f�[�^�擾�v���V�[�W��(A-7)
    -- =============================================================
    get_i_people_data(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- =============================================================
    --  CSV�t�@�C���o��(�V�K�o�^)�v���V�[�W��(A-9)
    -- =============================================================
    IF (gn_target_add_cnt > 0) THEN
      add_output_csv(
         lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
    --
    -- =============================================================
    --  �d����]�ƈ���񒆊�I/F�e�[�u���f�[�^�폜�v���V�[�W��(A-10)
    -- =============================================================
    delete_table(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================================
    --  �I�������v���V�[�W��(A-11)
    -- =====================================================
    -- CSV�t�@�C�����N���[�Y����
    UTL_FILE.FCLOSE(gf_file_hand);
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
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
   * Description      : �R���J�����g���s�v���V�[�W��
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
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
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
       ov_retcode => lv_retcode
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
      lv_errbuf   -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      --�G���[�o��
      IF (gv_warn_flg = '1') THEN
        -- ��s�}��(�x�����b�Z�[�W�ƃG���[���b�Z�[�W�̊�)
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => ''
        );
        -- ��s�}��(�x�����b�Z�[�W�ƃG���[���b�Z�[�W�̊�)
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => ''
        );
      END IF;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      -- ��s�}��(�G���[���b�Z�[�W�ƌ����̊�)
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff => lv_errbuf --�G���[���b�Z�[�W
      );
      -- �G���[�������A�e�����͈ȉ��ɓ��ꂵ�ďo�͂���
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_warn_cnt   := 0;
      gn_error_cnt  := 1;
    ELSE
      IF (gv_warn_flg = '1') THEN
        --�x���̏ꍇ�A���^�[���E�R�[�h�Ɍx�����Z�b�g����
        lv_retcode := cv_status_warn;
        -- ��s�}��(�x�����b�Z�[�W�ƌ����̊�)
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => ''
        );
      END IF;
    END IF;
    --
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
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
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --CSV�t�@�C�����N���[�Y����Ă��Ȃ������ꍇ�A�N���[�Y����
    IF (UTL_FILE.IS_OPEN(gf_file_hand)) THEN
      UTL_FILE.FCLOSE(gf_file_hand);
    END IF;
    --
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    ELSE
      COMMIT;
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
END XXCMM002A05C;
/
