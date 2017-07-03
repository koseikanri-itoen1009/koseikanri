CREATE OR REPLACE PACKAGE BODY APPS.XXCSO006A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO006A02C(body)
 * Description      : EBS(�t�@�C���A�b�v���[�hI/F)�Ɏ捞�܂ꂽ�K����уf�[�^���^�X�N�Ɏ捞�݂܂��B
 *                    
 * MD.050           : MD050_CSO_006_A02_�K����уf�[�^�i�[
 *                    
 * Version          : 1.10
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  init                        ��������                                        (A-1)
 *  get_profile_info            �v���t�@�C���l�擾                              (A-2)
 *  get_visit_data              �K����уf�[�^���o����                          (A-3)
 *  get_inupd_data              �o�^�iA-8�j�A�X�V�iA-9�j�����ŕK�v�ȃf�[�^�擾  (A-4)
 *  data_proper_check           �f�[�^�Ó����`�F�b�N                            (A-5)
 *  chk_mst_is_exists           �}�X�^���݃`�F�b�N                              (A-6)
 *  get_visit_same_data         ����K����уf�[�^���o                          (A-7)
 *  insert_visit_data           �K����уf�[�^�o�^                              (A-8)
 *  update_visit_data           �K����уf�[�^�X�V                              (A-9)
 *  delete_if_data              �t�@�C���f�[�^�폜����                          (A-11)
 *  submain                     ���C�������v���V�[�W��(
 *                                �Z�[�u�|�C���g�ݒ�                            (A-10)
 *                              )
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��(
 *                                �I������                                      (A-12)
 *                              )
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-12-01    1.0   Kichi.Cho        �V�K�쐬
 *  2009-03-16    1.1   Kazuo.Satomura   �d�l�ύX�Ή�(��QID62)
 *                                       �E�ڋq�Z�L�����e�B�v���Ή�
 *  2009-05-01    1.3   Tomoko.Mori      T1_0897�Ή�
 *  2009-05-14    1.4   Kazuo.Satomura   T1_0931�Ή�
 *  2009-05-28    1.5   Kazuo.Satomura   T1_0137�Ή�
 *  2009-07-16    1.6   Kazuo.Satomura   0000070�Ή�
 *  2009-09-08    1.7   Daisuke.Abe      0001312�Ή�
 *  2010-02-15    1.8   T.Maruyama       E_�{�ғ�_01130�Ή�
 *  2017-04-13    1.9   K.Kiriu          E_�{�ғ�_14025�Ή�
 *  2017-06-09    1.10  N.Watanabe       E_�{�ғ�_14266�Ή�
 *****************************************************************************************/
-- 
-- #######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal       CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn         CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error        CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
--
  cv_msg_part            CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont            CONSTANT VARCHAR2(3) := '.';
--
-- #######################  �Œ�O���[�o���萔�錾�� END   #########################
--
-- #######################  �Œ�O���[�o���ϐ��錾�� START #########################
--
  gv_out_msg             VARCHAR2(2000);
  gn_target_cnt          NUMBER;                    -- �Ώی���
  gn_normal_cnt          NUMBER;                    -- ���팏��
  gn_error_cnt           NUMBER;                    -- �G���[����
--
-- #######################  �Œ�O���[�o���ϐ��錾�� END   #########################
--
-- #######################  �Œ苤�ʗ�O�錾�� START       #########################
--
  --*** ���������ʗ�O ***
  global_process_expt    EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt        EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
-- #######################  �Œ苤�ʗ�O�錾�� END         #########################
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO006A02C';      -- �p�b�P�[�W��
  cv_app_name            CONSTANT VARCHAR2(5)   := 'XXCSO';             -- �A�v���P�[�V�����Z�k��
--
  cv_comma               CONSTANT VARCHAR2(1)   := ',';
  cv_active_status       CONSTANT VARCHAR2(1)   := 'A';                 -- �A�N�e�B�u
  cv_enabled_flag        CONSTANT VARCHAR2(1)   := 'Y';                 -- �L��
  /* 2017.04.13 K.Kiriu E_�{�ғ�_14025�Ή� START */
  cd_sysdate             CONSTANT DATE          := SYSDATE;             -- �V�X�e�����t
  /* 2017.04.13 K.Kiriu E_�{�ғ�_14025�Ή� END   */
--
  -- CSV�t�@�C���̍��ڏ���
  cn_employee_number     CONSTANT NUMBER        := 2;                   -- �Ј��R�[�h
  cn_account_number      CONSTANT NUMBER        := 3;                   -- �ڋq�R�[�h
  cn_visit_ymd           CONSTANT NUMBER        := 5;                   -- �K���
  cn_visit_time          CONSTANT NUMBER        := 6;                   -- �J�n����
-- Ver1.10 ADD Start
  cn_visit_end_time      CONSTANT NUMBER        := 7;                   -- �I������
-- Ver1.10 ADD End
-- Ver1.10 MOD Start
--  cn_description         CONSTANT NUMBER        := 7;                   -- �ڍד��e
  cn_description         CONSTANT NUMBER        := 8;                   -- �ڍד��e
-- Ver1.10 MOD End
-- Ver1.10 ADD Start
  cn_active_time1         CONSTANT NUMBER       := 29;                  -- ��������1
  cn_active_time2         CONSTANT NUMBER       := 30;                  -- ��������2
  cn_active_time3         CONSTANT NUMBER       := 31;                  -- ��������3
  cn_active_time4         CONSTANT NUMBER       := 32;                  -- ��������4
  cn_active_time5         CONSTANT NUMBER       := 33;                  -- ��������5
  cn_active_time6         CONSTANT NUMBER       := 34;                  -- ��������6
  cn_active_time7         CONSTANT NUMBER       := 35;                  -- ��������7
  cn_active_time8         CONSTANT NUMBER       := 36;                  -- ��������8
  cn_active_time9         CONSTANT NUMBER       := 37;                  -- ��������9
  cn_active_time10        CONSTANT NUMBER       := 38;                  -- ��������10
  cn_active_time11        CONSTANT NUMBER       := 39;                  -- ��������11
  cn_active_time12        CONSTANT NUMBER       := 40;                  -- ��������12
  cn_active_time13        CONSTANT NUMBER       := 41;                  -- ��������13
  cn_active_time14        CONSTANT NUMBER       := 42;                  -- ��������14
  cn_active_time15        CONSTANT NUMBER       := 43;                  -- ��������15
  cn_active_time16        CONSTANT NUMBER       := 44;                  -- ��������16
  cn_active_time17        CONSTANT NUMBER       := 45;                  -- ��������17
  cn_active_time18        CONSTANT NUMBER       := 46;                  -- ��������18
  cn_active_time19        CONSTANT NUMBER       := 47;                  -- ��������19
  cn_active_time20        CONSTANT NUMBER       := 48;                  -- ��������20
-- Ver1.10 ADD End
  -- CSV�t�@�C���̖K��敪
  cn_visit_dff_0         CONSTANT NUMBER        := 0;                   -- �敪�Ȃ�
  -- CSV�t�@�C���̍��ږ���
  cv_employee_number_nm  CONSTANT VARCHAR2(100) := '�Ј��R�[�h';        -- �Ј��R�[�h
  cv_account_number_nm   CONSTANT VARCHAR2(100) := '�ڋq�R�[�h';        -- �ڋq�R�[�h
  cv_visit_nm            CONSTANT VARCHAR2(100) := '�K�����';          -- �K�����
-- Ver1.10 DEL Start
--  cv_visit_dff1_nm       CONSTANT VARCHAR2(100) := '�g�̊���';          -- �g�̊���
--  cv_visit_dff2_nm       CONSTANT VARCHAR2(100) := '�̑��t�H���[';      -- �̑��t�H���[
--  cv_visit_dff3_nm       CONSTANT VARCHAR2(100) := '�X������';          -- �X������
--  cv_visit_dff4_nm       CONSTANT VARCHAR2(100) := '�N���[���Ή�';      -- �N���[���Ή�
--  cv_visit_dff5_nm       CONSTANT VARCHAR2(100) := '�����x��';        -- �����x��
--  cv_visit_dff6_nm       CONSTANT VARCHAR2(100) := '�����`�F�b�N�i�����j';   -- �����`�F�b�N�i�����j
--  cv_visit_dff7_nm       CONSTANT VARCHAR2(100) := '�����`�F�b�N�i��؁j';   -- �����`�F�b�N�i��؁j
--  cv_visit_dff8_nm       CONSTANT VARCHAR2(100) := '�����`�F�b�N�i���̑��j'; -- �����`�F�b�N�i���̑��j
--  cv_visit_dff9_nm       CONSTANT VARCHAR2(100) := '�����`�F�b�N�i���[�t�j'; -- �����`�F�b�N�i���[�t�j
--  cv_visit_dff10_nm      CONSTANT VARCHAR2(100) := '�����`�F�b�N�i�`���h�j'; -- �����`�F�b�N�i�`���h�j
-- Ver1.10 DEL End
-- Ver1.10 ADD Start
  cv_visit_end_nm        CONSTANT VARCHAR2(100) := '�K��I������';      -- �K��I������
-- Ver1.10 ADD End
--
  -- ���b�Z�[�W�R�[�h
  cv_tkn_number_01       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00175';  -- �v���t�@�C���擾�G���[
  cv_tkn_number_02       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00024';  -- �f�[�^���o�G���[
    -- �f�[�^���o�G���[�i�t�@�C���A�b�v���[�hI/F�e�[�u���j
  cv_tkn_number_03       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00025';
  cv_tkn_number_04       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00026';  -- �p�����[�^NULL�G���[
  cv_tkn_number_05       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00027';  -- �K����уf�[�^�t�H�[�}�b�g�`�F�b�N�G���[
  cv_tkn_number_06       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00028';  -- NUMBER�^�`�F�b�N�G���[
  cv_tkn_number_07       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00029';  -- ���t�����G���[
  cv_tkn_number_08       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00030';  -- �T�C�Y�`�F�b�N�G���[
  cv_tkn_number_09       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00031';  -- �}�X�^�`�F�b�N�G���[
  cv_tkn_number_10       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00117';  -- �K��������ߓ����߂��Ă���G���[
  cv_tkn_number_11       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00118';  -- �f�[�^�o�^�A�X�V�A�폜�G���[
    -- �f�[�^�폜�G���[�i�t�@�C���A�b�v���[�hI/F�e�[�u���j
  cv_tkn_number_12       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00033';
  cv_tkn_number_13       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00034';  -- ���b�N�G���[
    -- ���b�N�G���[���b�Z�[�W(�t�@�C���A�b�v���[�hI/F�e�[�u��) 
  cv_tkn_number_14       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00035';
    -- �}�X�^�`�F�b�N�i�ڋq�}�X�^�j�_�~�[�ڋq�R�[�h�Z�b�g
  cv_tkn_number_15       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00036';
  cv_tkn_number_16       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00274';  -- �A�b�v���[�h�t�@�C�����̒��o�G���[
    -- �R���J�����g���̓p�����[�^
  cv_tkn_number_17       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00271';  -- �p�����[�^�t�@�C��ID
  cv_tkn_number_18       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00275';  -- �p�����[�^�t�H�[�}�b�g�p�^�[��
  cv_tkn_number_19       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00276';  -- �t�@�C���A�b�v���[�h����
  cv_tkn_number_20       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00152';  -- CSV�t�@�C������
  /* 2009.07.16 K.Satomura 0000070�Ή� START */
  cv_tkn_number_21       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00578';  -- �^�X�N���݃G���[
  /* 2009.07.16 K.Satomura 0000070�Ή� END */
-- Ver1.10 ADD Start
  cv_tkn_number_22       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00840';  -- ���Ԍ`���`�F�b�N�G���[���b�Z�[�W
  cv_tkn_number_23       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00841';  -- �K��I�������`�F�b�N�G���[���b�Z�[�W
-- Ver1.10 ADD End
--
  -- �g�[�N���R�[�h
  cv_tkn_err_msg         CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_file_id         CONSTANT VARCHAR2(20) := 'FILE_ID';
  cv_tkn_fmt_ptn         CONSTANT VARCHAR2(20) := 'FORMAT_PATTERN';
  cv_tkn_file_upload_nm  CONSTANT VARCHAR2(20) := 'UPLOAD_FILE_NAME';
  cv_tkn_tbl             CONSTANT VARCHAR2(20) := 'TABLE';  
  cv_tkn_process         CONSTANT VARCHAR2(20) := 'PROCESS';
  cv_tkn_item            CONSTANT VARCHAR2(20) := 'ITEM';
  cv_tkn_prof_nm         CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_base_val        CONSTANT VARCHAR2(20) := 'BASE_VALUE';
  cv_tkn_csv_file_nm     CONSTANT VARCHAR2(20) := 'CSV_FILE_NAME';
-- Ver1.10 ADD Start
  cv_tkn_emp_code        CONSTANT VARCHAR2(20)  := 'EMP_CODE';
  cv_tkn_cust_code       CONSTANT VARCHAR2(20)  := 'CUST_CODE';
  cv_tkn_visit_date      CONSTANT VARCHAR2(20)  := 'VISIT_DATE';
  cv_tkn_visit_time      CONSTANT VARCHAR2(20)  := 'VISIT_TIME';
  cv_tkn_visit_time_end  CONSTANT VARCHAR2(20)  := 'VISIT_TIME_END';
-- Ver1.10 ADD End
--
  -- DEBUG_LOG�p���b�Z�[�W
  cv_debug_msg1           CONSTANT VARCHAR2(200) := '<< �v���t�@�C���l�擾 >>';
  cv_debug_msg2           CONSTANT VARCHAR2(200) := '�_�~�[�ڋq�R�[�h = ';
  cv_debug_msg3           CONSTANT VARCHAR2(200) := '�K����уf�[�^�𒊏o���܂����B';
  cv_debug_msg4           CONSTANT VARCHAR2(200) := '<< �K�v�ȃf�[�^�擾 >>';
  cv_debug_msg5           CONSTANT VARCHAR2(200) := '�K��敪�R�[�h�𒊏o���܂����B';
  cv_debug_msg6           CONSTANT VARCHAR2(200) := '�p�[�e�BID = ';
  cv_debug_msg7           CONSTANT VARCHAR2(200) := '�p�[�e�B���� = ';
  cv_debug_msg8           CONSTANT VARCHAR2(200) := '�ڋq�X�e�[�^�X = ';
  cv_debug_msg15          CONSTANT VARCHAR2(200) := '�t�@�C���f�[�^�폜���܂����B';
  cv_debug_msg16          CONSTANT VARCHAR2(200) := '<< �K����уf�[�^���o >>';
  cv_debug_msg19          CONSTANT VARCHAR2(200) := '<< �t�@�C���f�[�^�폜 >>';
  cv_debug_msg22          CONSTANT VARCHAR2(200) := '���[���o�b�N���܂����B';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �s�P�ʃf�[�^���i�[����z��
  TYPE g_col_data_ttype IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;
  /* 2009.05.14 K.Satomura T1_0931�Ή� START */
  TYPE g_dff_cd_array IS VARRAY(10) OF fnd_lookup_values_vl.lookup_code%TYPE;
  /* 2009.05.14 K.Satomura T1_0931�Ή� END */
  -- �K����уf�[�^���֘A��񒊏o�f�[�^
  TYPE g_visit_data_rtype IS RECORD(
    employee_number      per_people_f.employee_number%TYPE,        -- �Ј��R�[�h
    account_number       hz_cust_accounts.account_number%TYPE,     -- �ڋq�R�[�h
    visit_date           DATE,                                     -- �K�����
    description          jtf_tasks_tl.description%TYPE,            -- �ڍד��e
    /* 2009.05.14 K.Satomura T1_0931�Ή� START */
    --dff1_cd              fnd_lookup_values_vl.lookup_code%TYPE,    -- �g�̊���
    --dff2_cd              fnd_lookup_values_vl.lookup_code%TYPE,    -- �̑��t�H���[
    --dff3_cd              fnd_lookup_values_vl.lookup_code%TYPE,    -- �X������
    --dff4_cd              fnd_lookup_values_vl.lookup_code%TYPE,    -- �N���[���Ή�
    --dff5_cd              fnd_lookup_values_vl.lookup_code%TYPE,    -- �����x��
    --dff6_cd              fnd_lookup_values_vl.lookup_code%TYPE,    -- �����`�F�b�N�i�����j
    --dff7_cd              fnd_lookup_values_vl.lookup_code%TYPE,    -- �����`�F�b�N�i��؁j
    --dff8_cd              fnd_lookup_values_vl.lookup_code%TYPE,    -- �����`�F�b�N�i���̑��j
    --dff9_cd              fnd_lookup_values_vl.lookup_code%TYPE,    -- �����`�F�b�N�i���[�t�j
    --dff10_cd             fnd_lookup_values_vl.lookup_code%TYPE,    -- �����`�F�b�N�i�`���h�j
    dff_cd_table         g_dff_cd_array,                           -- �K��敪�p�z��
    /* 2009.05.14 K.Satomura T1_0931�Ή� END */
    resource_id          jtf_rs_resource_extns.resource_id%TYPE,   -- ���\�[�XID
    party_id             hz_parties.party_id%TYPE,                 -- �p�[�e�BID
    party_name           hz_parties.party_name%TYPE,               -- �p�[�e�B����
    customer_status      hz_parties.duns_number_c%TYPE             -- �ڋq�X�e�[�^�X
  );
  -- CSV�t�@�C�����ڂ̏���(�K��敪)
  TYPE g_csv_order_rtype IS RECORD(
    dff1_num             NUMBER,                                   -- �����敪1�i���ԁj
    dff1_cd              fnd_lookup_values_vl.lookup_code%TYPE,    -- �����敪1�i�R�[�h�j
-- Ver1.10 ADD Start
    dff1_name            fnd_lookup_values_vl.meaning%TYPE,        -- �����敪1�i���e�j
-- Ver1.10 ADD End
    dff2_num             NUMBER,                                   -- �����敪2�i���ԁj
    dff2_cd              fnd_lookup_values_vl.lookup_code%TYPE,    -- �����敪2�i�R�[�h�j
-- Ver1.10 ADD Start
    dff2_name            fnd_lookup_values_vl.meaning%TYPE,        -- �����敪2�i���e�j
-- Ver1.10 ADD End
    dff3_num             NUMBER,                                   -- �����敪3�i���ԁj
    dff3_cd              fnd_lookup_values_vl.lookup_code%TYPE,    -- �����敪3�i�R�[�h�j
-- Ver1.10 ADD Start
    dff3_name            fnd_lookup_values_vl.meaning%TYPE,        -- �����敪3�i���e�j
-- Ver1.10 ADD End
    dff4_num             NUMBER,                                   -- �����敪4�i���ԁj
    dff4_cd              fnd_lookup_values_vl.lookup_code%TYPE,    -- �����敪4�i�R�[�h�j
-- Ver1.10 ADD Start
    dff4_name            fnd_lookup_values_vl.meaning%TYPE,        -- �����敪4�i���e�j
-- Ver1.10 ADD End
    dff5_num             NUMBER,                                   -- �����敪5�i���ԁj
    dff5_cd              fnd_lookup_values_vl.lookup_code%TYPE,    -- �����敪5�i�R�[�h�j
-- Ver1.10 ADD Start
    dff5_name            fnd_lookup_values_vl.meaning%TYPE,        -- �����敪5�i���e�j
-- Ver1.10 ADD End
    dff6_num             NUMBER,                                   -- �����敪6�i���ԁj
    dff6_cd              fnd_lookup_values_vl.lookup_code%TYPE,    -- �����敪6�i�R�[�h�j
-- Ver1.10 ADD Start
    dff6_name            fnd_lookup_values_vl.meaning%TYPE,        -- �����敪6�i���e�j
-- Ver1.10 ADD End
    dff7_num             NUMBER,                                   -- �����敪7�i���ԁj
    dff7_cd              fnd_lookup_values_vl.lookup_code%TYPE,    -- �����敪7�i�R�[�h�j
-- Ver1.10 ADD Start
    dff7_name            fnd_lookup_values_vl.meaning%TYPE,        -- �����敪7�i���e�j
-- Ver1.10 ADD End
    dff8_num             NUMBER,                                   -- �����敪8�i���ԁj
    dff8_cd              fnd_lookup_values_vl.lookup_code%TYPE,    -- �����敪8�i�R�[�h�j
-- Ver1.10 ADD Start
    dff8_name            fnd_lookup_values_vl.meaning%TYPE,        -- �����敪8�i���e�j
-- Ver1.10 ADD End
    dff9_num             NUMBER,                                   -- �����敪9�i���ԁj
    dff9_cd              fnd_lookup_values_vl.lookup_code%TYPE,    -- �����敪9�i�R�[�h�j
-- Ver1.10 ADD Start
    dff9_name            fnd_lookup_values_vl.meaning%TYPE,        -- �����敪9�i���e�j
-- Ver1.10 ADD End
    dff10_num            NUMBER,                                   -- �����敪10�i���ԁj
    dff10_cd             fnd_lookup_values_vl.lookup_code%TYPE,    -- �����敪10�i�R�[�h�j
-- Ver1.10 ADD Start
    dff10_name           fnd_lookup_values_vl.meaning%TYPE,        -- �����敪10�i���e�j
-- Ver1.10 ADD End
-- Ver1.10 ADD Start
    dff11_num            NUMBER,                                   -- �����敪11�i���ԁj
    dff11_cd             fnd_lookup_values_vl.lookup_code%TYPE,    -- �����敪11�i�R�[�h�j
    dff11_name           fnd_lookup_values_vl.meaning%TYPE,        -- �����敪11�i���e�j
    dff12_num            NUMBER,                                   -- �����敪12�i���ԁj
    dff12_cd             fnd_lookup_values_vl.lookup_code%TYPE,    -- �����敪12�i�R�[�h�j
    dff12_name           fnd_lookup_values_vl.meaning%TYPE,        -- �����敪12�i���e�j
    dff13_num            NUMBER,                                   -- �����敪13�i���ԁj
    dff13_cd             fnd_lookup_values_vl.lookup_code%TYPE,    -- �����敪13�i�R�[�h�j
    dff13_name           fnd_lookup_values_vl.meaning%TYPE,        -- �����敪13�i���e�j
    dff14_num            NUMBER,                                   -- �����敪14�i���ԁj
    dff14_cd             fnd_lookup_values_vl.lookup_code%TYPE,    -- �����敪14�i�R�[�h�j
    dff14_name           fnd_lookup_values_vl.meaning%TYPE,        -- �����敪14�i���e�j
    dff15_num            NUMBER,                                   -- �����敪15�i���ԁj
    dff15_cd             fnd_lookup_values_vl.lookup_code%TYPE,    -- �����敪15�i�R�[�h�j
    dff15_name           fnd_lookup_values_vl.meaning%TYPE,        -- �����敪15�i���e�j
    dff16_num            NUMBER,                                   -- �����敪16�i���ԁj
    dff16_cd             fnd_lookup_values_vl.lookup_code%TYPE,    -- �����敪16�i�R�[�h�j
    dff16_name           fnd_lookup_values_vl.meaning%TYPE,        -- �����敪16�i���e�j
    dff17_num            NUMBER,                                   -- �����敪17�i���ԁj
    dff17_cd             fnd_lookup_values_vl.lookup_code%TYPE,    -- �����敪17�i�R�[�h�j
    dff17_name           fnd_lookup_values_vl.meaning%TYPE,        -- �����敪17�i���e�j
    dff18_num            NUMBER,                                   -- �����敪18�i���ԁj
    dff18_cd             fnd_lookup_values_vl.lookup_code%TYPE,    -- �����敪18�i�R�[�h�j
    dff18_name           fnd_lookup_values_vl.meaning%TYPE,        -- �����敪18�i���e�j
    dff19_num            NUMBER,                                   -- �����敪19�i���ԁj
    dff19_cd             fnd_lookup_values_vl.lookup_code%TYPE,    -- �����敪19�i�R�[�h�j
    dff19_name           fnd_lookup_values_vl.meaning%TYPE,        -- �����敪19�i���e�j
    dff20_num            NUMBER,                                   -- �����敪20�i���ԁj
    dff20_cd             fnd_lookup_values_vl.lookup_code%TYPE,    -- �����敪20�i�R�[�h�j
    dff20_name           fnd_lookup_values_vl.meaning%TYPE         -- �����敪20�i���e�j
-- Ver1.10 ADD End
  );
  -- *** ���[�U�[��`�O���[�o����O ***
  global_skip_error_expt EXCEPTION;
  global_lock_expt       EXCEPTION;                                -- ���b�N��O
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  g_file_data_tab        xxccp_common_pkg2.g_file_data_tbl;
  g_visit_data_rec       g_visit_data_rtype;                       -- �K����уf�[�^���R�[�h
  g_csv_order_rec        g_csv_order_rtype;                        -- CSV�t�@�C�����ڂ̏���(�K��敪)
--
  gt_file_id             xxccp_mrp_file_ul_interface.file_id%TYPE; -- �t�@�C��ID
  gv_fmt_ptn             VARCHAR2(20);                             -- �t�H�[�}�b�g�p�^�[��
  gt_party_id            hz_parties.party_id%TYPE;                 -- �p�[�e�BID
  gt_party_name          hz_parties.party_name%TYPE;               -- �p�[�e�B����
  gt_customer_status     hz_parties.duns_number_c%TYPE;            -- �ڋq�X�e�[�^�X
  gb_task_inup_rollback_flag     BOOLEAN := FALSE;                 -- TRUE : ���[���o�b�N
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : �������� (A-1)
   ***********************************************************************************/
--
  PROCEDURE init(
     ov_errbuf           OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W            -- # �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h              -- # �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'init';     -- �v���O������
--
-- #####################  �Œ胍�[�J���ϐ��錾�� START     #########################
--
    lv_errbuf            VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode           VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg            VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
-- #####################  �Œ胍�[�J���ϐ��錾�� END       #########################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- �t�@�C���A�b�v���[�h����(�Q�ƃ^�C�v�e�[�u��)
    cv_file_upload_lookup_type     CONSTANT VARCHAR2(100) := 'XXCCP1_FILE_UPLOAD_OBJ';
    cv_visit_data_lookup_code      CONSTANT VARCHAR2(30)  := '620';
    -- *** ���[�J���ϐ� ***
    lv_file_upload_nm              VARCHAR2(30);    -- �t�@�C���A�b�v���[�h����
    -- ���b�Z�[�W�o�͗p
    lv_msg                         VARCHAR2(5000);
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���̓p�����[�^���b�Z�[�W�o��
    -- �t�@�C��ID���b�Z�[�W
    lv_msg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                ,iv_name         => cv_tkn_number_17         -- ���b�Z�[�W�R�[�h
                ,iv_token_name1  => cv_tkn_file_id           -- �g�[�N���R�[�h1
                ,iv_token_value1 => TO_CHAR(gt_file_id)      -- �g�[�N���l1
              );
--
    -- �t�@�C��ID���b�Z�[�W�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => '' || CHR(10) || lv_msg
    );
    -- �t�@�C��ID���O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '' || CHR(10) || lv_msg
    );
--
    -- �t�H�[�}�b�g�p�^�[�����b�Z�[�W
    lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                   ,iv_name         => cv_tkn_number_18         -- ���b�Z�[�W�R�[�h
                   ,iv_token_name1  => cv_tkn_fmt_ptn           -- �g�[�N���R�[�h1
                   ,iv_token_value1 => gv_fmt_ptn               -- �g�[�N���l1
                 );
--
    -- �t�H�[�}�b�g�p�^�[�����b�Z�[�W�o��
    fnd_file.put_line(
      which  => FND_FILE.OUTPUT,
      buff   => lv_msg || CHR(10)
    );
--
    -- ���̓p�����[�^�t�@�C��ID��NULL�`�F�b�N
    IF gt_file_id IS NULL THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_04         -- ���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �t�@�C���A�b�v���[�h���̒��o
    BEGIN
--
      -- �Q�ƃ^�C�v�e�[�u������t�@�C���A�b�v���[�h���̒��o
      SELECT lvvl.meaning                                         -- ���e
      INTO   lv_file_upload_nm
      FROM   fnd_lookup_values_vl lvvl                            -- �Q�ƃ^�C�v�e�[�u��
      WHERE  lvvl.lookup_type = cv_file_upload_lookup_type
        AND TRUNC(SYSDATE) BETWEEN TRUNC(lvvl.start_date_active)
              AND TRUNC(NVL(lvvl.end_date_active, SYSDATE))
        AND lvvl.enabled_flag = cv_enabled_flag
        AND lvvl.lookup_code = cv_visit_data_lookup_code;
--    
      -- �t�@�C���A�b�v���[�h���̃��b�Z�[�W
      lv_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_19         -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_file_upload_nm    -- �g�[�N���R�[�h1
                    ,iv_token_value1 => lv_file_upload_nm        -- �g�[�N���l1
                   );
--
      -- �t�@�C���A�b�v���[�h���̃��b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_msg || CHR(10)
      );
      -- ���O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_msg || CHR(10)
      );
--
    EXCEPTION
      -- �t�@�C���A�b�v���[�h���̒��o�Ɏ��s�����ꍇ�̌㏈��
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_16           -- ���b�Z�[�W�R�[�h
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
    -- *** ������O�n���h�� ***
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_profile_info
   * Description      : �v���t�@�C���l�擾 (A-2)
   ***********************************************************************************/
--
  PROCEDURE get_profile_info(
     ov_dummy_acc_num    OUT NOCOPY VARCHAR2  -- �_�~�[�ڋq�R�[�h              -- # �Œ� #
    ,ov_errbuf           OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            -- # �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              -- # �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100) := 'get_profile_info';  -- �v���O������
--
-- #######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf            VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode           VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg            VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
-- ###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- �v���t�@�C���� (XXCSO: �K����уf�[�^�i�[�p�_�~�[�ڋq�R�[�h)
    cv_prfnm_dummy_acc_num      CONSTANT VARCHAR2(30)   := 'XXCSO1_VISIT_DMMY_CUST_CD';
--
    -- *** ���[�J���ϐ� ***
    lv_dummy_acc_num            VARCHAR2(30);                           -- �_�~�[�ڋq�R�[�h
--
  BEGIN
--
-- ##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
-- ###########################  �Œ蕔 END   ############################
--
    -- =======================
    -- �v���t�@�C���l�擾���� 
    -- =======================
    FND_PROFILE.GET(
       cv_prfnm_dummy_acc_num
      ,lv_dummy_acc_num
    ); -- �_�~�[�ڋq�R�[�h
--
    -- �v���t�@�C���l�擾�Ɏ��s�����ꍇ
    IF (lv_dummy_acc_num IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_01             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_prof_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_prfnm_dummy_acc_num       -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �擾�����v���t�@�C���l��OUT�p�����[�^�ɐݒ�
    ov_dummy_acc_num := lv_dummy_acc_num;
--
      -- ���O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg1 || CHR(10) || cv_debug_msg2 || lv_dummy_acc_num || CHR(10)
    );
--
  EXCEPTION
--
-- #################################  �Œ��O������ START   ####################################
--
    -- *** ������O�n���h�� ***
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
-- #####################################  �Œ蕔 END   ##########################################
--
  END get_profile_info;
--
  /**********************************************************************************
   * Procedure Name   : get_visit_data
   * Description      : �K����уf�[�^���o���� (A-3)
   ***********************************************************************************/
--
  PROCEDURE get_visit_data(
     ov_errbuf            OUT NOCOPY VARCHAR2             -- �G���[�E���b�Z�[�W            -- # �Œ� #
    ,ov_retcode           OUT NOCOPY VARCHAR2             -- ���^�[���E�R�[�h              -- # �Œ� #
    ,ov_errmsg            OUT NOCOPY VARCHAR2             -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'get_visit_data';     -- �v���O������
--
-- #####################  �Œ胍�[�J���ϐ��錾�� START     #########################
--
    lv_errbuf            VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode           VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg            VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
-- #####################  �Œ胍�[�J���ϐ��錾�� END       #########################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_if_table_nm       CONSTANT VARCHAR2(100)  := '�t�@�C���A�b�v���[�hI/F�e�[�u��';
    -- *** ���[�J���ϐ� ***
    lt_file_name         xxccp_mrp_file_ul_interface.file_name%TYPE;          -- �t�@�C����
    lt_file_content_type xxccp_mrp_file_ul_interface.file_content_type%TYPE;  -- �t�@�C���敪
    lt_file_data         xxccp_mrp_file_ul_interface.file_data%TYPE;             -- �t�@�C���f�[�^
    lt_file_format       xxccp_mrp_file_ul_interface.file_format%TYPE;        -- �t�@�C���t�H�[�}�b�g
    -- ���b�Z�[�W�o�͗p
    lv_msg               VARCHAR2(5000);
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    BEGIN
--
      -- �t�@�C���f�[�^���o
      SELECT xmfui.file_name file_name                                        -- �t�@�C����
            ,xmfui.file_content_type file_content_type
            ,xmfui.file_data file_date                                        -- �t�@�C���f�[�^
            ,xmfui.file_format file_format
      INTO   lt_file_name
            ,lt_file_content_type
            ,lt_file_data
            ,lt_file_format
      FROM   xxccp_mrp_file_ul_interface xmfui
      WHERE  xmfui.file_id = gt_file_id
      FOR UPDATE NOWAIT;
--
    EXCEPTION
      -- ���b�N���s�����ꍇ�̗�O
      WHEN global_lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                        -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_14                   -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl                         -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_if_table_nm                     -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_file_id                     -- �g�[�N���R�[�h2
                       ,iv_token_value2 => TO_CHAR(gt_file_id)                -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE global_process_expt;
      -- ���o�Ɏ��s�����ꍇ�̗�O
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                        -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_03                   -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl                         -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_if_table_nm                     -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_file_id                     -- �g�[�N���R�[�h2
                       ,iv_token_value2 => TO_CHAR(gt_file_id)                -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_err_msg                     -- �g�[�N���R�[�h2
                       ,iv_token_value3 => SQLERRM                            -- �g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- BLOB�f�[�^�ϊ��֐��ɂ��s�P�ʃf�[�^�𒊏o
    xxccp_common_pkg2.blob_to_varchar2(
       in_file_id   => gt_file_id         -- �t�@�C��ID
      ,ov_file_data => g_file_data_tab    -- �t�@�C���f�[�^
      ,ov_errbuf    => lv_errbuf          -- �G���[�E���b�Z�[�W            -- # �Œ� #
      ,ov_retcode   => lv_retcode         -- ���^�[���E�R�[�h              -- # �Œ� #
      ,ov_errmsg    => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                        -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_03                   -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_tbl                         -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_if_table_nm                     -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_file_id                     -- �g�[�N���R�[�h2
                     ,iv_token_value2 => TO_CHAR(gt_file_id)                -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_err_msg                     -- �g�[�N���R�[�h2
                     ,iv_token_value3 => lv_errbuf                          -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- CSV�t�@�C�������b�Z�[�W
    lv_msg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                ,iv_name         => cv_tkn_number_20         -- ���b�Z�[�W�R�[�h
                ,iv_token_name1  => cv_tkn_csv_file_nm       -- �g�[�N���R�[�h1
                ,iv_token_value1 => lt_file_name             -- �g�[�N���l1
              );
    -- CSV�t�@�C�������b�Z�[�W�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg || CHR(10)
    );
    -- CSV�t�@�C�������O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_msg || CHR(10)
    );
    -- �f�[�^���o���O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg16 || CHR(10) || cv_debug_msg3 || CHR(10)
    );
--
  EXCEPTION
    -- *** ������O�n���h�� ***
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
  END get_visit_data;
--
  /**********************************************************************************
   * Procedure Name   : get_inupd_data
   * Description      : �o�^�iA-8�j�A�X�V�iA-9�j�����ŕK�v�ȃf�[�^�擾 (A-4)
   ***********************************************************************************/
--
  PROCEDURE get_inupd_data(
     iv_dummy_acc_num    IN         VARCHAR2  -- �_�~�[�ڋq�R�[�h
    ,ov_errbuf           OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            -- # �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              -- # �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100) := 'get_inupd_data';  -- �v���O������
--
-- #######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf            VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode           VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg            VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
-- ###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
-- Ver1.10 DEL Start
--    cv_activity_lookup_type     CONSTANT VARCHAR2(100) := 'XXCSO1_VISIT_ACTIVITY_NUMBER';
-- Ver1.10 DEL End
    cv_kubun_lookup_type        CONSTANT VARCHAR2(100) := 'XXCSO_ASN_HOUMON_KUBUN';
    cv_account_table_vl_nm      CONSTANT VARCHAR2(100) := '�ڋq�}�X�^�r���[';
    cv_lookup_table_nm          CONSTANT VARCHAR2(100) := '�Q�ƃ^�C�v�e�[�u��';
-- Ver1.10 ADD Start
    cn_act_start_point          CONSTANT NUMBER        := 8;      --�����敪�̊J�n�ʒu�܂ŉ��Z���邽�߂̒萔
-- Ver1.10 ADD End
--
    -- *** ���[�J���E�J�[�\�� *** 
    CURSOR l_houmon_kubun_cur
    IS
-- Ver1.10 MOD Start
--      SELECT xvan.lookup_code num                                     -- ����
--            ,xahk.lookup_code code                                    -- �K��敪�R�[�h
--            ,xvan.meaning meaning                                     -- ���e
--      FROM   fnd_lookup_values_vl xvan
--            ,fnd_lookup_values_vl xahk
--      WHERE  xvan.lookup_type = cv_activity_lookup_type
--        AND  TRUNC(SYSDATE) BETWEEN TRUNC(xvan.start_date_active)
--               AND TRUNC(NVL(xvan.end_date_active, SYSDATE))
--        AND  xvan.enabled_flag = cv_enabled_flag
--        AND  xahk.lookup_type = cv_kubun_lookup_type
--        AND  TRUNC(SYSDATE) BETWEEN TRUNC(xahk.start_date_active)
--               AND TRUNC(NVL(xahk.end_date_active, SYSDATE))
--        AND  xahk.enabled_flag = cv_enabled_flag
--        AND  xvan.meaning = xahk.meaning;
      SELECT flvv.attribute4  num
            ,flvv.lookup_code code
            ,flvv.meaning     name
      FROM   fnd_lookup_values_vl flvv
      WHERE  flvv.lookup_type = cv_kubun_lookup_type
      AND    TRUNC(cd_sysdate) BETWEEN TRUNC(flvv.start_date_active)
               AND TRUNC(NVL(flvv.end_date_active, cd_sysdate))
      AND    flvv.enabled_flag = cv_enabled_flag
      AND    flvv.attribute4 IS NOT NULL;
-- Ver1.10 MOD End
--
    -- *** ���[�J���E���R�[�h *** 
    l_houmon_kubun_rec l_houmon_kubun_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- *** 1. �Q�ƃ^�C�v�e�[�u������K��敪�R�[�h�̎擾 *** --
    BEGIN
--
      -- �J�[�\���I�[�v��
      OPEN l_houmon_kubun_cur;
--
      <<houmon_kubun_loop>>
      LOOP
        FETCH l_houmon_kubun_cur INTO l_houmon_kubun_rec;
--
        EXIT WHEN l_houmon_kubun_cur%NOTFOUND
          OR l_houmon_kubun_cur%ROWCOUNT = 0;
--
        -- �K��敪
-- Ver1.10 MOD Start
--        IF (l_houmon_kubun_rec.meaning = cv_visit_dff1_nm) THEN
        IF (l_houmon_kubun_rec.num = 1) THEN
        -- �K��敪1
--          g_csv_order_rec.dff1_num := l_houmon_kubun_rec.num;
          g_csv_order_rec.dff1_num  := TO_NUMBER(l_houmon_kubun_rec.num) + cn_act_start_point;
-- Ver1.10 MOD End
          g_csv_order_rec.dff1_cd   := l_houmon_kubun_rec.code;
-- Ver1.10 ADD Start
          g_csv_order_rec.dff1_name := l_houmon_kubun_rec.name;
-- Ver1.10 ADD End
-- Ver1.10 MOD Start
--        ELSIF (l_houmon_kubun_rec.meaning = cv_visit_dff2_nm) THEN
        ELSIF (l_houmon_kubun_rec.num = 2) THEN
        -- �K��敪2
--          g_csv_order_rec.dff2_num := l_houmon_kubun_rec.num;
          g_csv_order_rec.dff2_num  := TO_NUMBER(l_houmon_kubun_rec.num) + cn_act_start_point;
-- Ver1.10 MOD End
          g_csv_order_rec.dff2_cd   := l_houmon_kubun_rec.code;
-- Ver1.10 ADD Start
          g_csv_order_rec.dff2_name := l_houmon_kubun_rec.name;
-- Ver1.10 ADD End
-- Ver1.10 MOD Start
--        ELSIF (l_houmon_kubun_rec.meaning = cv_visit_dff3_nm) THEN
        ELSIF (l_houmon_kubun_rec.num = 3) THEN
        -- �K��敪3
--          g_csv_order_rec.dff3_num := l_houmon_kubun_rec.num;
          g_csv_order_rec.dff3_num  := TO_NUMBER(l_houmon_kubun_rec.num) + cn_act_start_point;
-- Ver1.10 MOD End
          g_csv_order_rec.dff3_cd   := l_houmon_kubun_rec.code;
-- Ver1.10 ADD Start
          g_csv_order_rec.dff3_name := l_houmon_kubun_rec.name;
-- Ver1.10 ADD End
-- Ver1.10 MOD Start
--        ELSIF (l_houmon_kubun_rec.meaning = cv_visit_dff4_nm) THEN
        ELSIF (l_houmon_kubun_rec.num = 4) THEN
        -- �K��敪4
--          g_csv_order_rec.dff4_num := l_houmon_kubun_rec.num;
          g_csv_order_rec.dff4_num  := TO_NUMBER(l_houmon_kubun_rec.num) + cn_act_start_point;
-- Ver1.10 MOD End
          g_csv_order_rec.dff4_cd   := l_houmon_kubun_rec.code;
-- Ver1.10 ADD Start
          g_csv_order_rec.dff4_name := l_houmon_kubun_rec.name;
-- Ver1.10 ADD End
-- Ver1.10 MOD Start
--        ELSIF (l_houmon_kubun_rec.meaning = cv_visit_dff5_nm) THEN
        ELSIF (l_houmon_kubun_rec.num = 5) THEN
        -- �K��敪5
--          g_csv_order_rec.dff5_num := l_houmon_kubun_rec.num;
          g_csv_order_rec.dff5_num  := TO_NUMBER(l_houmon_kubun_rec.num) + cn_act_start_point;
-- Ver1.10 MOD End
          g_csv_order_rec.dff5_cd   := l_houmon_kubun_rec.code;
-- Ver1.10 ADD Start
          g_csv_order_rec.dff5_name := l_houmon_kubun_rec.name;
-- Ver1.10 ADD End
-- Ver1.10 MOD Start
--        ELSIF (l_houmon_kubun_rec.meaning = cv_visit_dff6_nm) THEN
        ELSIF (l_houmon_kubun_rec.num = 6) THEN
        -- �K��敪6
--          g_csv_order_rec.dff6_num := l_houmon_kubun_rec.num;
          g_csv_order_rec.dff6_num  := TO_NUMBER(l_houmon_kubun_rec.num) + cn_act_start_point;
-- Ver1.10 MOD End
          g_csv_order_rec.dff6_cd   := l_houmon_kubun_rec.code;
-- Ver1.10 ADD Start
          g_csv_order_rec.dff6_name := l_houmon_kubun_rec.name;
-- Ver1.10 ADD End
-- Ver1.10 MOD Start
--        ELSIF (l_houmon_kubun_rec.meaning = cv_visit_dff7_nm) THEN
        ELSIF (l_houmon_kubun_rec.num = 7) THEN
        -- �K��敪7
--          g_csv_order_rec.dff7_num := l_houmon_kubun_rec.num;
          g_csv_order_rec.dff7_num  := TO_NUMBER(l_houmon_kubun_rec.num) + cn_act_start_point;
-- Ver1.10 MOD End
          g_csv_order_rec.dff7_cd   := l_houmon_kubun_rec.code;
-- Ver1.10 ADD Start
          g_csv_order_rec.dff7_name := l_houmon_kubun_rec.name;
-- Ver1.10 ADD End
-- Ver1.10 MOD Start
--        ELSIF (l_houmon_kubun_rec.meaning = cv_visit_dff8_nm) THEN
        ELSIF (l_houmon_kubun_rec.num = 8) THEN
        -- �K��敪8
--          g_csv_order_rec.dff8_num := l_houmon_kubun_rec.num;
          g_csv_order_rec.dff8_num  := TO_NUMBER(l_houmon_kubun_rec.num) + cn_act_start_point;
-- Ver1.10 MOD End
          g_csv_order_rec.dff8_cd   := l_houmon_kubun_rec.code;
-- Ver1.10 ADD Start
          g_csv_order_rec.dff8_name := l_houmon_kubun_rec.name;
-- Ver1.10 ADD End
-- Ver1.10 MOD Start
--        ELSIF (l_houmon_kubun_rec.meaning = cv_visit_dff9_nm) THEN
        ELSIF (l_houmon_kubun_rec.num = 9) THEN
        -- �K��敪9
--          g_csv_order_rec.dff9_num := l_houmon_kubun_rec.num;
          g_csv_order_rec.dff9_num  := TO_NUMBER(l_houmon_kubun_rec.num) + cn_act_start_point;
-- Ver1.10 MOD End
          g_csv_order_rec.dff9_cd   := l_houmon_kubun_rec.code;
-- Ver1.10 ADD Start
          g_csv_order_rec.dff9_name := l_houmon_kubun_rec.name;
-- Ver1.10 ADD End
-- Ver1.10 MOD Start
--        ELSIF (l_houmon_kubun_rec.meaning = cv_visit_dff10_nm) THEN
        ELSIF (l_houmon_kubun_rec.num = 10) THEN
        -- �K��敪10
--          g_csv_order_rec.dff10_num := l_houmon_kubun_rec.num;
          g_csv_order_rec.dff10_num  := TO_NUMBER(l_houmon_kubun_rec.num) + cn_act_start_point;
-- Ver1.10 MOD End
          g_csv_order_rec.dff10_cd   := l_houmon_kubun_rec.code;
-- Ver1.10 ADD Start
          g_csv_order_rec.dff10_name := l_houmon_kubun_rec.name;
        ELSIF (l_houmon_kubun_rec.num = 11) THEN
        -- �K��敪11
          g_csv_order_rec.dff11_num  := TO_NUMBER(l_houmon_kubun_rec.num) + cn_act_start_point;
          g_csv_order_rec.dff11_cd   := l_houmon_kubun_rec.code;
          g_csv_order_rec.dff11_name := l_houmon_kubun_rec.name;
        ELSIF (l_houmon_kubun_rec.num = 12) THEN
        -- �K��敪12
          g_csv_order_rec.dff12_num  := TO_NUMBER(l_houmon_kubun_rec.num) + cn_act_start_point;
          g_csv_order_rec.dff12_cd   := l_houmon_kubun_rec.code;
          g_csv_order_rec.dff12_name := l_houmon_kubun_rec.name;
        ELSIF (l_houmon_kubun_rec.num = 13) THEN
        -- �K��敪13
          g_csv_order_rec.dff13_num  := TO_NUMBER(l_houmon_kubun_rec.num) + cn_act_start_point;
          g_csv_order_rec.dff13_cd   := l_houmon_kubun_rec.code;
          g_csv_order_rec.dff13_name := l_houmon_kubun_rec.name;
        ELSIF (l_houmon_kubun_rec.num = 14) THEN
        -- �K��敪14
          g_csv_order_rec.dff14_num  := TO_NUMBER(l_houmon_kubun_rec.num) + cn_act_start_point;
          g_csv_order_rec.dff14_cd   := l_houmon_kubun_rec.code;
          g_csv_order_rec.dff14_name := l_houmon_kubun_rec.name;
        ELSIF (l_houmon_kubun_rec.num = 15) THEN
        -- �K��敪15
          g_csv_order_rec.dff15_num  := TO_NUMBER(l_houmon_kubun_rec.num) + cn_act_start_point;
          g_csv_order_rec.dff15_cd   := l_houmon_kubun_rec.code;
          g_csv_order_rec.dff15_name := l_houmon_kubun_rec.name;
        ELSIF (l_houmon_kubun_rec.num = 16) THEN
        -- �K��敪16
          g_csv_order_rec.dff16_num  := TO_NUMBER(l_houmon_kubun_rec.num) + cn_act_start_point;
          g_csv_order_rec.dff16_cd   := l_houmon_kubun_rec.code;
          g_csv_order_rec.dff16_name := l_houmon_kubun_rec.name;
        ELSIF (l_houmon_kubun_rec.num = 17) THEN
        -- �K��敪17
          g_csv_order_rec.dff17_num  := TO_NUMBER(l_houmon_kubun_rec.num) + cn_act_start_point;
          g_csv_order_rec.dff17_cd   := l_houmon_kubun_rec.code;
          g_csv_order_rec.dff17_name := l_houmon_kubun_rec.name;
        ELSIF (l_houmon_kubun_rec.num = 18) THEN
        -- �K��敪18
          g_csv_order_rec.dff18_num  := TO_NUMBER(l_houmon_kubun_rec.num) + cn_act_start_point;
          g_csv_order_rec.dff18_cd   := l_houmon_kubun_rec.code;
          g_csv_order_rec.dff18_name := l_houmon_kubun_rec.name;
        ELSIF (l_houmon_kubun_rec.num = 19) THEN
        -- �K��敪19
          g_csv_order_rec.dff19_num  := TO_NUMBER(l_houmon_kubun_rec.num) + cn_act_start_point;
          g_csv_order_rec.dff19_cd   := l_houmon_kubun_rec.code;
          g_csv_order_rec.dff19_name := l_houmon_kubun_rec.name;
        ELSIF (l_houmon_kubun_rec.num = 20) THEN
        -- �K��敪20
          g_csv_order_rec.dff20_num  := TO_NUMBER(l_houmon_kubun_rec.num) + cn_act_start_point;
          g_csv_order_rec.dff20_cd   := l_houmon_kubun_rec.code;
          g_csv_order_rec.dff20_name := l_houmon_kubun_rec.name;
        END IF;
-- Ver1.10 ADD End
--
      END LOOP houmon_kubun_loop;
--
      -- ������0���̏ꍇ
      IF (l_houmon_kubun_cur%ROWCOUNT = 0) THEN
        RAISE NO_DATA_FOUND;
      END IF;
      -- �J�[�\���E�N���[�Y
      CLOSE l_houmon_kubun_cur;
--
      -- ���O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg4 || CHR(10) || cv_debug_msg5
      );
--
    EXCEPTION
      -- ���o�Ɏ��s�����ꍇ�̌㏈��
      WHEN OTHERS THEN
        -- �J�[�\���E�N���[�Y
        IF (l_houmon_kubun_cur%ISOPEN) THEN
          CLOSE l_houmon_kubun_cur;
        END IF;
--
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_02             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl                   -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_lookup_table_nm           -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_err_msg               -- �g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM                      -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- *** 2. �_�~�[�ڋq�R�[�h�Ńp�[�e�BID�A�p�[�e�B���̂ƌڋq�X�e�[�^�X�̎擾 *** --
    BEGIN
--
      SELECT xcav.party_id                                              -- �p�[�e�BID
            ,xcav.party_name                                            -- �p�[�e�B����
            ,xcav.customer_status                                       -- �ڋq�X�e�[�^�X
      INTO   gt_party_id
            ,gt_party_name
            ,gt_customer_status
      FROM   xxcso_cust_accounts_v xcav
      WHERE  xcav.account_number = iv_dummy_acc_num
        AND xcav.account_status = cv_active_status
        AND xcav.party_status = cv_active_status;
--
        -- ���O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg6 || gt_party_id || '�A' ||
                     cv_debug_msg7 || gt_party_name || '�A' ||
                     cv_debug_msg8 || gt_customer_status || CHR(10)
        );
--
    EXCEPTION
      -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_02             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl                   -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_account_table_vl_nm       -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_err_msg               -- �g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM                      -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
    -- *** ������O�n���h�� ***
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
  END get_inupd_data;
--
  /**********************************************************************************
   * Procedure Name   : data_proper_check
   * Description      : �Ó����`�F�b�N (A-5)
   ***********************************************************************************/
--
  PROCEDURE data_proper_check(
     iv_base_value       IN  VARCHAR2                -- ���Y�s�f�[�^
    ,ov_errbuf           OUT NOCOPY VARCHAR2         -- �G���[�E���b�Z�[�W           -- # �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2         -- ���^�[���E�R�[�h             -- # �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'data_proper_check';       -- �v���O������
--
-- #####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf   VARCHAR2(5000);   -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1);      -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000);   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
-- ###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
-- Ver1.10 MOD Start
--    cn_format_col_cnt       CONSTANT NUMBER        := 26;                   -- ���ڐ�
    cn_format_col_cnt       CONSTANT NUMBER        := 48;                   -- ���ڐ�
-- Ver1.10 MOD End
    cn_employee_number_len  CONSTANT NUMBER        := 5;                    -- �Ј��R�[�h�o�C�g��
    cn_account_number_len   CONSTANT NUMBER        := 9;                    -- �ڋq�R�[�h�o�C�g��
    cn_activity_kubun_len   CONSTANT NUMBER        := 1;                    -- �������e�o�C�g��
    cn_description_cut_len  CONSTANT NUMBER        := 2000;                 -- �ڍד��e�͈�
    cv_visit_date_fmt       CONSTANT VARCHAR2(100) := 'YYYY/MM/DD HH24:MI'; -- DATE�^
-- Ver1.10 ADD Start
    cv_format_minute        CONSTANT VARCHAR2(100) := 'HH24:MI';            -- DATE�^�i�����j
    cv_act_time1            CONSTANT VARCHAR2(100) := '��������1';          -- ��������1
    cv_act_time2            CONSTANT VARCHAR2(100) := '��������2';          -- ��������2
    cv_act_time3            CONSTANT VARCHAR2(100) := '��������3';          -- ��������3
    cv_act_time4            CONSTANT VARCHAR2(100) := '��������4';          -- ��������4
    cv_act_time5            CONSTANT VARCHAR2(100) := '��������5';          -- ��������5
    cv_act_time6            CONSTANT VARCHAR2(100) := '��������6';          -- ��������6
    cv_act_time7            CONSTANT VARCHAR2(100) := '��������7';          -- ��������7
    cv_act_time8            CONSTANT VARCHAR2(100) := '��������8';          -- ��������8
    cv_act_time9            CONSTANT VARCHAR2(100) := '��������9';          -- ��������9
    cv_act_time10           CONSTANT VARCHAR2(100) := '��������10';         -- ��������10
    cv_act_time11           CONSTANT VARCHAR2(100) := '��������11';         -- ��������11
    cv_act_time12           CONSTANT VARCHAR2(100) := '��������12';         -- ��������12
    cv_act_time13           CONSTANT VARCHAR2(100) := '��������13';         -- ��������13
    cv_act_time14           CONSTANT VARCHAR2(100) := '��������14';         -- ��������14
    cv_act_time15           CONSTANT VARCHAR2(100) := '��������15';         -- ��������15
    cv_act_time16           CONSTANT VARCHAR2(100) := '��������16';         -- ��������16
    cv_act_time17           CONSTANT VARCHAR2(100) := '��������17';         -- ��������17
    cv_act_time18           CONSTANT VARCHAR2(100) := '��������18';         -- ��������18
    cv_act_time19           CONSTANT VARCHAR2(100) := '��������19';         -- ��������19
    cv_act_time20           CONSTANT VARCHAR2(100) := '��������20';         -- ��������20
-- Ver1.10 ADD End
--
    -- *** ���[�J���ϐ� ***
    l_col_data_tab            g_col_data_ttype;      -- �����㍀�ڃf�[�^���i�[����z��
    lv_item_nm                VARCHAR2(100);         -- �Y�����ږ�
    lv_visit_date             VARCHAR2(100);         -- �K�����
    lb_return                 BOOLEAN;               -- ���^�[���X�e�[�^�X
    /* 2009.05.14 K.Satomura T1_0931�Ή� START */
    ln_array_count            NUMBER;
    /* 2009.05.14 K.Satomura T1_0931�Ή� END */
--
    lv_tmp                    VARCHAR2(2000);
    ln_pos                    NUMBER;
    ln_cnt                    NUMBER := 1;
    lb_format_flag            BOOLEAN := TRUE;
--
-- Ver1.10 ADD Start
    FUNCTION activite_time_check(
       iv_active_time IN VARCHAR2  -- ��������
    ) RETURN BOOLEAN
    IS
    --
    cn_active_time_len CONSTANT NUMBER := 4; -- �������Ԍ���
    lb_return_status            BOOLEAN;     -- ���^�[���X�e�[�^�X
    ln_active_time              NUMBER;      -- ��������
    --
    BEGIN
      --NUMBER�^���`�F�b�N
      lb_return_status :=xxccp_common_pkg.chk_number(iv_active_time);
      IF (lb_return_status = TRUE) THEN
        --�������`�F�b�N
        ln_active_time := TO_NUMBER(iv_active_time);
        IF (ln_active_time = TRUNC(ln_active_time)) THEN
          --0�ȏォ�`�F�b�N
          IF (ln_active_time >= 0) THEN
            --4���ȓ����`�F�b�N
            IF (LENGTH(ln_active_time) <= cn_active_time_len) THEN
              RETURN TRUE;
            ELSE
              RETURN FALSE;
            END IF;
          ELSE
            RETURN FALSE;
          END IF;
        ELSE
          RETURN FALSE;
        END IF;
      ELSE
        RETURN FALSE;
      END IF;
    END;
-- Ver1.10 ADD End
  BEGIN
--
-- ##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
-- ###########################  �Œ蕔 END   ############################
--
    -- ���ڐ����擾
    IF (iv_base_value IS NULL) THEN
      lb_format_flag := FALSE;
    END IF;
--
    IF lb_format_flag THEN
      lv_tmp := iv_base_value;
      LOOP
        ln_pos := INSTR(lv_tmp, cv_comma);
        IF ((ln_pos IS NULL) OR (ln_pos = 0)) THEN
          EXIT;
        ELSE
          ln_cnt := ln_cnt + 1;
          lv_tmp := SUBSTR(lv_tmp, ln_pos + 1);
          ln_pos := 0;
        END IF;
      END LOOP;
    END IF;
--
    -- 1.���ڐ��`�F�b�N
    IF ((lb_format_flag = FALSE) OR (ln_cnt <> cn_format_col_cnt)) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_05             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_base_val              -- �g�[�N���R�[�h1
                       ,iv_token_value1 => iv_base_value                -- �g�[�N���l1
                     );
        lv_errbuf  := lv_errmsg;
        RAISE global_skip_error_expt;
--
    -- 2.�f�[�^�^�i���p�����^���t�j�̃`�F�b�N�A�T�C�Y�`�F�b�N
    ELSE
--
     -- ���ʊ֐��ɂ���ĕ����������ڃf�[�^�e�[�u���̎擾
     FOR i IN 1..cn_format_col_cnt LOOP
       l_col_data_tab(i) := REPLACE(xxccp_common_pkg.char_delim_partition(iv_base_value, cv_comma, i), '"');
     END LOOP;
--
      lb_return  := TRUE;
      lv_item_nm := '';
--
      -- 1). NUMBER�^�`�F�b�N
-- Ver1.10 ADD Start
      IF (g_csv_order_rec.dff1_num IS NOT NULL) THEN
-- Ver1.10 ADD End
        IF (xxccp_common_pkg.chk_number(l_col_data_tab(g_csv_order_rec.dff1_num)) = FALSE) THEN
        -- �����敪1
          lb_return  := FALSE;
-- Ver1.10 MOD Start
--        lv_item_nm := cv_visit_dff1_nm;
          lv_item_nm := g_csv_order_rec.dff1_name;
-- Ver1.10 MOD End
-- Ver1.10 ADD Start
        END IF;
      END IF;
      IF (g_csv_order_rec.dff2_num IS NOT NULL) THEN
-- Ver1.10 ADD End
        IF (xxccp_common_pkg.chk_number(l_col_data_tab(g_csv_order_rec.dff2_num)) = FALSE) THEN
        -- �����敪2
          lb_return  := FALSE;
-- Ver1.10 MOD Start
--        lv_item_nm := cv_visit_dff2_nm;
          lv_item_nm := g_csv_order_rec.dff2_name;
-- Ver1.10 MOD End
-- Ver1.10 ADD Start
        END IF;
      END IF;
      IF (g_csv_order_rec.dff3_num IS NOT NULL) THEN
-- Ver1.10 ADD End
        IF (xxccp_common_pkg.chk_number(l_col_data_tab(g_csv_order_rec.dff3_num)) = FALSE) THEN
        -- �����敪3
          lb_return  := FALSE;
-- Ver1.10 MOD Start
--        lv_item_nm := cv_visit_dff3_nm;
          lv_item_nm := g_csv_order_rec.dff3_name;
-- Ver1.10 MOD End
-- Ver1.10 ADD Start
        END IF;
      END IF;
      IF (g_csv_order_rec.dff4_num IS NOT NULL) THEN
-- Ver1.10 ADD End
        IF (xxccp_common_pkg.chk_number(l_col_data_tab(g_csv_order_rec.dff4_num)) = FALSE) THEN
        -- �����敪4
          lb_return  := FALSE;
-- Ver1.10 MOD Start
--        lv_item_nm := cv_visit_dff4_nm;
          lv_item_nm := g_csv_order_rec.dff4_name;
-- Ver1.10 MOD End
-- Ver1.10 ADD Start
        END IF;
      END IF;
      IF (g_csv_order_rec.dff5_num IS NOT NULL) THEN
-- Ver1.10 ADD End
        IF (xxccp_common_pkg.chk_number(l_col_data_tab(g_csv_order_rec.dff5_num)) = FALSE) THEN
        -- �����敪5
          lb_return  := FALSE;
-- Ver1.10 MOD Start
--        lv_item_nm := cv_visit_dff5_nm;
          lv_item_nm := g_csv_order_rec.dff5_name;
-- Ver1.10 MOD End
-- Ver1.10 ADD Start
        END IF;
      END IF;
      IF (g_csv_order_rec.dff6_num IS NOT NULL) THEN
-- Ver1.10 ADD End
        IF (xxccp_common_pkg.chk_number(l_col_data_tab(g_csv_order_rec.dff6_num)) = FALSE) THEN
        -- �����敪6
          lb_return  := FALSE;
-- Ver1.10 MOD Start
--        lv_item_nm := cv_visit_dff6_nm;
          lv_item_nm := g_csv_order_rec.dff6_name;
-- Ver1.10 MOD End
-- Ver1.10 ADD Start
        END IF;
      END IF;
      IF (g_csv_order_rec.dff7_num IS NOT NULL) THEN
-- Ver1.10 ADD End
        IF (xxccp_common_pkg.chk_number(l_col_data_tab(g_csv_order_rec.dff7_num)) = FALSE) THEN
        -- �����敪7
          lb_return  := FALSE;
-- Ver1.10 MOD Start
--        lv_item_nm := cv_visit_dff7_nm;
          lv_item_nm := g_csv_order_rec.dff7_name;
-- Ver1.10 MOD End
-- Ver1.10 ADD Start
        END IF;
      END IF;
      IF (g_csv_order_rec.dff8_num IS NOT NULL) THEN
-- Ver1.10 ADD End
        IF (xxccp_common_pkg.chk_number(l_col_data_tab(g_csv_order_rec.dff8_num)) = FALSE) THEN
        -- �����敪8
          lb_return  := FALSE;
-- Ver1.10 MOD Start
--        lv_item_nm := cv_visit_dff8_nm;
          lv_item_nm := g_csv_order_rec.dff8_name;
-- Ver1.10 MOD End
-- Ver1.10 ADD Start
        END IF;
      END IF;
      IF (g_csv_order_rec.dff9_num IS NOT NULL) THEN
-- Ver1.10 ADD End
        IF (xxccp_common_pkg.chk_number(l_col_data_tab(g_csv_order_rec.dff9_num)) = FALSE) THEN
        -- �����敪9
          lb_return  := FALSE;
-- Ver1.10 MOD Start
--        lv_item_nm := cv_visit_dff9_nm;
          lv_item_nm := g_csv_order_rec.dff9_name;
-- Ver1.10 MOD End
-- Ver1.10 ADD Start
        END IF;
      END IF;
      IF (g_csv_order_rec.dff10_num IS NOT NULL) THEN
-- Ver1.10 ADD End
        IF (xxccp_common_pkg.chk_number(l_col_data_tab(g_csv_order_rec.dff10_num)) = FALSE) THEN
        -- �����敪10
          lb_return  := FALSE;
-- Ver1.10 MOD Start
--        lv_item_nm := cv_visit_dff10_nm;
          lv_item_nm := g_csv_order_rec.dff10_name;
-- Ver1.10 MOD End
-- Ver1.10 ADD Start
        END IF;
      END IF;
      IF (g_csv_order_rec.dff11_num IS NOT NULL) THEN
        IF (xxccp_common_pkg.chk_number(l_col_data_tab(g_csv_order_rec.dff11_num)) = FALSE) THEN
        -- �����敪11
          lb_return  := FALSE;
          lv_item_nm := g_csv_order_rec.dff11_name;
        END IF;
      END IF;
      IF (g_csv_order_rec.dff12_num IS NOT NULL) THEN
        IF (xxccp_common_pkg.chk_number(l_col_data_tab(g_csv_order_rec.dff12_num)) = FALSE) THEN
        -- �����敪12
          lb_return  := FALSE;
          lv_item_nm := g_csv_order_rec.dff12_name;
        END IF;
      END IF;
      IF (g_csv_order_rec.dff13_num IS NOT NULL) THEN
        IF (xxccp_common_pkg.chk_number(l_col_data_tab(g_csv_order_rec.dff13_num)) = FALSE) THEN
        -- �����敪13
          lb_return  := FALSE;
          lv_item_nm := g_csv_order_rec.dff13_name;
        END IF;
      END IF;
      IF (g_csv_order_rec.dff14_num IS NOT NULL) THEN
        IF (xxccp_common_pkg.chk_number(l_col_data_tab(g_csv_order_rec.dff14_num)) = FALSE) THEN
        -- �����敪14
          lb_return  := FALSE;
          lv_item_nm := g_csv_order_rec.dff14_name;
        END IF;
      END IF;
      IF (g_csv_order_rec.dff15_num IS NOT NULL) THEN
        IF (xxccp_common_pkg.chk_number(l_col_data_tab(g_csv_order_rec.dff15_num)) = FALSE) THEN
        -- �����敪15
          lb_return  := FALSE;
          lv_item_nm := g_csv_order_rec.dff15_name;
        END IF;
      END IF;
      IF (g_csv_order_rec.dff16_num IS NOT NULL) THEN
        IF (xxccp_common_pkg.chk_number(l_col_data_tab(g_csv_order_rec.dff16_num)) = FALSE) THEN
        -- �����敪16
          lb_return  := FALSE;
          lv_item_nm := g_csv_order_rec.dff16_name;
        END IF;
      END IF;
      IF (g_csv_order_rec.dff17_num IS NOT NULL) THEN
        IF (xxccp_common_pkg.chk_number(l_col_data_tab(g_csv_order_rec.dff17_num)) = FALSE) THEN
        -- �����敪17
          lb_return  := FALSE;
          lv_item_nm := g_csv_order_rec.dff17_name;
        END IF;
      END IF;
      IF (g_csv_order_rec.dff18_num IS NOT NULL) THEN
        IF (xxccp_common_pkg.chk_number(l_col_data_tab(g_csv_order_rec.dff18_num)) = FALSE) THEN
        -- �����敪18
          lb_return  := FALSE;
          lv_item_nm := g_csv_order_rec.dff18_name;
        END IF;
      END IF;
      IF (g_csv_order_rec.dff19_num IS NOT NULL) THEN
        IF (xxccp_common_pkg.chk_number(l_col_data_tab(g_csv_order_rec.dff19_num)) = FALSE) THEN
        -- �����敪19
          lb_return  := FALSE;
          lv_item_nm := g_csv_order_rec.dff19_name;
        END IF;
      END IF;
      IF (g_csv_order_rec.dff20_num IS NOT NULL) THEN
        IF (xxccp_common_pkg.chk_number(l_col_data_tab(g_csv_order_rec.dff20_num)) = FALSE) THEN
        -- �����敪20
          lb_return  := FALSE;
          lv_item_nm := g_csv_order_rec.dff20_name;
-- Ver1.10 ADD End
        END IF;
      END IF;
--
      IF (lb_return = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_06             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_item                  -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_item_nm                   -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_base_val              -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_base_value                -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
      END IF;
--
      -- 2). ���t�����`�F�b�N
      -- �K�����
       /* 2010.02.15 T.Maruyama E_�{�ғ�_01130�Ή� START */
      --lv_visit_date := l_col_data_tab(cn_visit_ymd) || ' ' || l_col_data_tab(cn_visit_time);
      lv_visit_date := REPLACE(l_col_data_tab(cn_visit_ymd), '-', '/') || ' ' || l_col_data_tab(cn_visit_time);
       /* 2010.02.15 T.Maruyama E_�{�ғ�_01130�Ή� END */
      lb_return := xxcso_util_common_pkg.check_date(lv_visit_date, cv_visit_date_fmt);
      IF (lb_return = FALSE) THEN
        lv_item_nm := cv_visit_nm;
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_07             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_item                  -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_item_nm                   -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_base_val              -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_base_value                -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
      END IF;
-- Ver1.10 ADD Start
      IF (l_col_data_tab(cn_visit_end_time) IS NOT NULL) THEN
        --�K��I������
        lb_return := xxcso_util_common_pkg.check_date(l_col_data_tab(cn_visit_end_time), cv_format_minute);
        IF (lb_return = FALSE) THEN
          lv_item_nm := cv_visit_end_nm;
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                                                     -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_23                                                -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_item                  -- �g�[�N���R�[�h1
                         ,iv_token_value1 => lv_item_nm                   -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_base_val              -- �g�[�N���R�[�h2
                         ,iv_token_value2 => iv_base_value                -- �g�[�N���l2
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_skip_error_expt;
        END IF;
      END IF;
-- Ver1.10 ADD End
--
      -- 3). �T�C�Y�`�F�b�N
      IF ((l_col_data_tab(cn_employee_number) IS NULL)
          OR (LENGTHB(l_col_data_tab(cn_employee_number)) <> cn_employee_number_len)) THEN
        -- �Ј��R�[�h
        lb_return  := FALSE;
        lv_item_nm := cv_employee_number_nm;
      ELSIF (LENGTHB(l_col_data_tab(cn_account_number)) <> cn_account_number_len) THEN
        -- �ڋq�R�[�h(NULL �\)
        lb_return  := FALSE;
        lv_item_nm := cv_account_number_nm;
-- Ver1.10 DEL Start
--      ELSIF ((l_col_data_tab(g_csv_order_rec.dff1_num) IS NULL)
--             OR (LENGTHB(l_col_data_tab(g_csv_order_rec.dff1_num)) <> cn_activity_kubun_len)) THEN
--        -- �g�̊���
--        lb_return  := FALSE;
--        lv_item_nm := cv_visit_dff1_nm;
--      ELSIF ((l_col_data_tab(g_csv_order_rec.dff2_num) IS NULL)
--             OR (LENGTHB(l_col_data_tab(g_csv_order_rec.dff2_num)) <> cn_activity_kubun_len)) THEN
--        -- �̑��t�H���[
--        lb_return  := FALSE;
--        lv_item_nm := cv_visit_dff2_nm;
--      ELSIF ((l_col_data_tab(g_csv_order_rec.dff3_num) IS NULL)
--             OR (LENGTHB(l_col_data_tab(g_csv_order_rec.dff3_num)) <> cn_activity_kubun_len)) THEN
--        -- �X������
--        lb_return  := FALSE;
--        lv_item_nm := cv_visit_dff3_nm;
--      ELSIF ((l_col_data_tab(g_csv_order_rec.dff4_num) IS NULL)
--             OR (LENGTHB(l_col_data_tab(g_csv_order_rec.dff4_num)) <> cn_activity_kubun_len)) THEN
--        -- �N���[���Ή�
--        lb_return  := FALSE;
--        lv_item_nm := cv_visit_dff4_nm;
--      ELSIF ((l_col_data_tab(g_csv_order_rec.dff5_num) IS NULL)
--             OR (LENGTHB(l_col_data_tab(g_csv_order_rec.dff5_num)) <> cn_activity_kubun_len)) THEN
--        -- �����x��
--        lb_return  := FALSE;
--        lv_item_nm := cv_visit_dff5_nm;
--      ELSIF ((l_col_data_tab(g_csv_order_rec.dff6_num) IS NULL)
--             OR (LENGTHB(l_col_data_tab(g_csv_order_rec.dff6_num)) <> cn_activity_kubun_len)) THEN
--        -- �����`�F�b�N�i�����j
--        lb_return  := FALSE;
--        lv_item_nm := cv_visit_dff6_nm;
--      ELSIF ((l_col_data_tab(g_csv_order_rec.dff7_num) IS NULL)
--             OR (LENGTHB(l_col_data_tab(g_csv_order_rec.dff7_num)) <> cn_activity_kubun_len)) THEN
--        -- �����`�F�b�N�i��؁j
--        lb_return  := FALSE;
--        lv_item_nm := cv_visit_dff7_nm;
--      ELSIF ((l_col_data_tab(g_csv_order_rec.dff8_num) IS NULL)
--             OR (LENGTHB(l_col_data_tab(g_csv_order_rec.dff8_num)) <> cn_activity_kubun_len)) THEN
--        -- �����`�F�b�N�i���̑��j
--        lb_return  := FALSE;
--        lv_item_nm := cv_visit_dff8_nm;
--      ELSIF ((l_col_data_tab(g_csv_order_rec.dff9_num) IS NULL)
--             OR (LENGTHB(l_col_data_tab(g_csv_order_rec.dff9_num)) <> cn_activity_kubun_len)) THEN
--        -- �����`�F�b�N�i���[�t�j
--        lb_return  := FALSE;
--        lv_item_nm := cv_visit_dff9_nm;
--      ELSIF ((l_col_data_tab(g_csv_order_rec.dff10_num) IS NULL)
--             OR (LENGTHB(l_col_data_tab(g_csv_order_rec.dff10_num)) <> cn_activity_kubun_len)) THEN
--        -- �����`�F�b�N�i�`���h�j
--        lb_return  := FALSE;
--        lv_item_nm := cv_visit_dff10_nm;
-- Ver1.10 DEL End
      END IF;
 -- Ver1.10 ADD Start
      -- �����敪1
      IF (g_csv_order_rec.dff1_num IS NOT NULL) THEN
        IF (l_col_data_tab(g_csv_order_rec.dff1_num) IS NULL) THEN
          lb_return  := FALSE;
          lv_item_nm := g_csv_order_rec.dff1_name;
        ELSIF (l_col_data_tab(g_csv_order_rec.dff1_num) IS NOT NULL) THEN
          IF (LENGTHB(l_col_data_tab(g_csv_order_rec.dff1_num)) <> cn_activity_kubun_len) THEN
            lb_return  := FALSE;
            lv_item_nm := g_csv_order_rec.dff1_name;
          END IF;
        END IF;
      END IF;
      -- �����敪2
      IF (g_csv_order_rec.dff2_num IS NOT NULL) THEN
        IF (l_col_data_tab(g_csv_order_rec.dff2_num) IS NULL) THEN
          lb_return  := FALSE;
          lv_item_nm := g_csv_order_rec.dff2_name;
        ELSIF (l_col_data_tab(g_csv_order_rec.dff2_num) IS NOT NULL) THEN
          IF (LENGTHB(l_col_data_tab(g_csv_order_rec.dff2_num)) <> cn_activity_kubun_len) THEN
            lb_return  := FALSE;
            lv_item_nm := g_csv_order_rec.dff2_name;
          END IF;
        END IF;
      END IF;
      -- �����敪3
      IF (g_csv_order_rec.dff3_num IS NOT NULL) THEN
        IF (l_col_data_tab(g_csv_order_rec.dff3_num) IS NULL) THEN
          lb_return  := FALSE;
          lv_item_nm := g_csv_order_rec.dff3_name;
        ELSIF (l_col_data_tab(g_csv_order_rec.dff3_num) IS NOT NULL) THEN
          IF (LENGTHB(l_col_data_tab(g_csv_order_rec.dff3_num)) <> cn_activity_kubun_len) THEN
            lb_return  := FALSE;
            lv_item_nm := g_csv_order_rec.dff3_name;
          END IF;
        END IF;
      END IF;
      -- �����敪4
      IF (g_csv_order_rec.dff4_num IS NOT NULL) THEN
        IF (l_col_data_tab(g_csv_order_rec.dff4_num) IS NULL) THEN
          lb_return  := FALSE;
          lv_item_nm := g_csv_order_rec.dff4_name;
        ELSIF (l_col_data_tab(g_csv_order_rec.dff4_num) IS NOT NULL) THEN
          IF (LENGTHB(l_col_data_tab(g_csv_order_rec.dff4_num)) <> cn_activity_kubun_len) THEN
            lb_return  := FALSE;
            lv_item_nm := g_csv_order_rec.dff4_name;
          END IF;
        END IF;
      END IF;
      -- �����敪5
      IF (g_csv_order_rec.dff5_num IS NOT NULL) THEN
        IF (l_col_data_tab(g_csv_order_rec.dff5_num) IS NULL) THEN
          lb_return  := FALSE;
          lv_item_nm := g_csv_order_rec.dff5_name;
        ELSIF (l_col_data_tab(g_csv_order_rec.dff5_num) IS NOT NULL) THEN
          IF (LENGTHB(l_col_data_tab(g_csv_order_rec.dff5_num)) <> cn_activity_kubun_len) THEN
            lb_return  := FALSE;
            lv_item_nm := g_csv_order_rec.dff5_name;
          END IF;
        END IF;
      END IF;
      -- �����敪6
      IF (g_csv_order_rec.dff6_num IS NOT NULL) THEN
        IF (l_col_data_tab(g_csv_order_rec.dff6_num) IS NULL) THEN
          lb_return  := FALSE;
          lv_item_nm := g_csv_order_rec.dff6_name;
        ELSIF (l_col_data_tab(g_csv_order_rec.dff6_num) IS NOT NULL) THEN
          IF (LENGTHB(l_col_data_tab(g_csv_order_rec.dff6_num)) <> cn_activity_kubun_len) THEN
            lb_return  := FALSE;
            lv_item_nm := g_csv_order_rec.dff6_name;
          END IF;
        END IF;
      END IF;
      -- �����敪7
      IF (g_csv_order_rec.dff7_num IS NOT NULL) THEN
        IF (l_col_data_tab(g_csv_order_rec.dff7_num) IS NULL) THEN
          lb_return  := FALSE;
          lv_item_nm := g_csv_order_rec.dff7_name;
        ELSIF (l_col_data_tab(g_csv_order_rec.dff7_num) IS NOT NULL) THEN
          IF (LENGTHB(l_col_data_tab(g_csv_order_rec.dff7_num)) <> cn_activity_kubun_len) THEN
            lb_return  := FALSE;
            lv_item_nm := g_csv_order_rec.dff7_name;
          END IF;
        END IF;
      END IF;
      -- �����敪8
      IF (g_csv_order_rec.dff8_num IS NOT NULL) THEN
        IF (l_col_data_tab(g_csv_order_rec.dff8_num) IS NULL) THEN
          lb_return  := FALSE;
          lv_item_nm := g_csv_order_rec.dff8_name;
        ELSIF (l_col_data_tab(g_csv_order_rec.dff8_num) IS NOT NULL) THEN
          IF (LENGTHB(l_col_data_tab(g_csv_order_rec.dff8_num)) <> cn_activity_kubun_len) THEN
            lb_return  := FALSE;
            lv_item_nm := g_csv_order_rec.dff8_name;
          END IF;
        END IF;
      END IF;
      -- �����敪9
      IF (g_csv_order_rec.dff9_num IS NOT NULL) THEN
        IF (l_col_data_tab(g_csv_order_rec.dff9_num) IS NULL) THEN
          lb_return  := FALSE;
          lv_item_nm := g_csv_order_rec.dff9_name;
        ELSIF (l_col_data_tab(g_csv_order_rec.dff9_num) IS NOT NULL) THEN
          IF (LENGTHB(l_col_data_tab(g_csv_order_rec.dff9_num)) <> cn_activity_kubun_len) THEN
            lb_return  := FALSE;
            lv_item_nm := g_csv_order_rec.dff9_name;
          END IF;
        END IF;
      END IF;
      -- �����敪10
      IF (g_csv_order_rec.dff10_num IS NOT NULL) THEN
        IF (l_col_data_tab(g_csv_order_rec.dff10_num) IS NULL) THEN
          lb_return  := FALSE;
          lv_item_nm := g_csv_order_rec.dff10_name;
        ELSIF (l_col_data_tab(g_csv_order_rec.dff10_num) IS NOT NULL) THEN
          IF (LENGTHB(l_col_data_tab(g_csv_order_rec.dff10_num)) <> cn_activity_kubun_len) THEN
            lb_return  := FALSE;
            lv_item_nm := g_csv_order_rec.dff10_name;
          END IF;
        END IF;
      END IF;
      -- �����敪11
      IF (g_csv_order_rec.dff11_num IS NOT NULL) THEN
        IF (l_col_data_tab(g_csv_order_rec.dff11_num) IS NULL) THEN
          lb_return  := FALSE;
          lv_item_nm := g_csv_order_rec.dff11_name;
        ELSIF (l_col_data_tab(g_csv_order_rec.dff11_num) IS NOT NULL) THEN
          IF (LENGTHB(l_col_data_tab(g_csv_order_rec.dff11_num)) <> cn_activity_kubun_len) THEN
            lb_return  := FALSE;
            lv_item_nm := g_csv_order_rec.dff11_name;
          END IF;
        END IF;
      END IF;
      -- �����敪12
      IF (g_csv_order_rec.dff12_num IS NOT NULL) THEN
        IF (l_col_data_tab(g_csv_order_rec.dff12_num) IS NULL) THEN
          lb_return  := FALSE;
          lv_item_nm := g_csv_order_rec.dff12_name;
        ELSIF (l_col_data_tab(g_csv_order_rec.dff12_num) IS NOT NULL) THEN
          IF (LENGTHB(l_col_data_tab(g_csv_order_rec.dff12_num)) <> cn_activity_kubun_len) THEN
            lb_return  := FALSE;
            lv_item_nm := g_csv_order_rec.dff12_name;
          END IF;
        END IF;
      END IF;
      -- �����敪13
      IF (g_csv_order_rec.dff13_num IS NOT NULL) THEN
        IF (l_col_data_tab(g_csv_order_rec.dff13_num) IS NULL) THEN
          lb_return  := FALSE;
          lv_item_nm := g_csv_order_rec.dff13_name;
        ELSIF (l_col_data_tab(g_csv_order_rec.dff13_num) IS NOT NULL) THEN
          IF (LENGTHB(l_col_data_tab(g_csv_order_rec.dff13_num)) <> cn_activity_kubun_len) THEN
            lb_return  := FALSE;
            lv_item_nm := g_csv_order_rec.dff13_name;
          END IF;
        END IF;
      END IF;
        -- �����敪14
      IF (g_csv_order_rec.dff14_num IS NOT NULL) THEN
        IF (l_col_data_tab(g_csv_order_rec.dff14_num) IS NULL) THEN
          lb_return  := FALSE;
          lv_item_nm := g_csv_order_rec.dff14_name;
        ELSIF (l_col_data_tab(g_csv_order_rec.dff14_num) IS NOT NULL) THEN
          IF (LENGTHB(l_col_data_tab(g_csv_order_rec.dff14_num)) <> cn_activity_kubun_len) THEN
            lb_return  := FALSE;
            lv_item_nm := g_csv_order_rec.dff14_name;
          END IF;
        END IF;
      END IF;
      -- �����敪15
      IF (g_csv_order_rec.dff15_num IS NOT NULL) THEN
        IF (l_col_data_tab(g_csv_order_rec.dff15_num) IS NULL) THEN
          lb_return  := FALSE;
          lv_item_nm := g_csv_order_rec.dff15_name;
        ELSIF (l_col_data_tab(g_csv_order_rec.dff15_num) IS NOT NULL) THEN
          IF (LENGTHB(l_col_data_tab(g_csv_order_rec.dff15_num)) <> cn_activity_kubun_len) THEN
            lb_return  := FALSE;
            lv_item_nm := g_csv_order_rec.dff15_name;
          END IF;
        END IF;
      END IF;
      -- �����敪16
      IF (g_csv_order_rec.dff16_num IS NOT NULL) THEN
        IF (l_col_data_tab(g_csv_order_rec.dff16_num) IS NULL) THEN
          lb_return  := FALSE;
          lv_item_nm := g_csv_order_rec.dff16_name;
        ELSIF (l_col_data_tab(g_csv_order_rec.dff16_num) IS NOT NULL) THEN
          IF (LENGTHB(l_col_data_tab(g_csv_order_rec.dff16_num)) <> cn_activity_kubun_len) THEN
            lb_return  := FALSE;
            lv_item_nm := g_csv_order_rec.dff16_name;
          END IF;
        END IF;
      END IF;
      -- �����敪17
      IF (g_csv_order_rec.dff17_num IS NOT NULL) THEN
        IF (l_col_data_tab(g_csv_order_rec.dff17_num) IS NULL) THEN
          lb_return  := FALSE;
          lv_item_nm := g_csv_order_rec.dff17_name;
        ELSIF (l_col_data_tab(g_csv_order_rec.dff17_num) IS NOT NULL) THEN
          IF (LENGTHB(l_col_data_tab(g_csv_order_rec.dff17_num)) <> cn_activity_kubun_len) THEN
            lb_return  := FALSE;
            lv_item_nm := g_csv_order_rec.dff17_name;
          END IF;
        END IF;
      END IF;
      -- �����敪18
      IF (g_csv_order_rec.dff18_num IS NOT NULL) THEN
        IF (l_col_data_tab(g_csv_order_rec.dff18_num) IS NULL) THEN
          lb_return  := FALSE;
          lv_item_nm := g_csv_order_rec.dff18_name;
        ELSIF (l_col_data_tab(g_csv_order_rec.dff18_num) IS NOT NULL) THEN
          IF (LENGTHB(l_col_data_tab(g_csv_order_rec.dff18_num)) <> cn_activity_kubun_len) THEN
            lb_return  := FALSE;
            lv_item_nm := g_csv_order_rec.dff18_name;
          END IF;
        END IF;
      END IF;
      -- �����敪19
      IF (g_csv_order_rec.dff19_num IS NOT NULL) THEN
        IF (l_col_data_tab(g_csv_order_rec.dff19_num) IS NULL) THEN
          lb_return  := FALSE;
          lv_item_nm := g_csv_order_rec.dff19_name;
        ELSIF (l_col_data_tab(g_csv_order_rec.dff19_num) IS NOT NULL) THEN
          IF (LENGTHB(l_col_data_tab(g_csv_order_rec.dff19_num)) <> cn_activity_kubun_len) THEN
            lb_return  := FALSE;
            lv_item_nm := g_csv_order_rec.dff19_name;
          END IF;
        END IF;
      END IF;
      -- �����敪20
      IF (g_csv_order_rec.dff20_num IS NOT NULL) THEN
        IF (l_col_data_tab(g_csv_order_rec.dff20_num) IS NULL) THEN
          lb_return  := FALSE;
          lv_item_nm := g_csv_order_rec.dff20_name;
        ELSIF (l_col_data_tab(g_csv_order_rec.dff20_num) IS NOT NULL) THEN
          IF (LENGTHB(l_col_data_tab(g_csv_order_rec.dff20_num)) <> cn_activity_kubun_len) THEN
            lb_return  := FALSE;
            lv_item_nm := g_csv_order_rec.dff20_name;
          END IF;
        END IF;
-- Ver1.10 ADD End
      END IF;
--
      IF (lb_return = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_08             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_item                  -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_item_nm                   -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_base_val              -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_base_value                -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
      END IF;
-- Ver1.10 ADD Start
      -- ��������1
      IF (l_col_data_tab(cn_active_time1) IS NOT NULL) THEN
        lb_return := activite_time_check(l_col_data_tab(cn_active_time1));
        IF (lb_return = FALSE) THEN
          lv_item_nm := cv_act_time1||'('||g_csv_order_rec.dff1_name||')';
          lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_tkn_number_22             -- ���b�Z�[�W�R�[�h
                 ,iv_token_name1  => cv_tkn_item                  -- �g�[�N���R�[�h1
                 ,iv_token_value1 => lv_item_nm                   -- �g�[�N���l1
                 ,iv_token_name2  => cv_tkn_base_val              -- �g�[�N���R�[�h2
                 ,iv_token_value2 => iv_base_value                -- �g�[�N���l2
               );
          lv_errbuf := lv_errmsg;
          RAISE global_skip_error_expt;
        END IF;
      END IF;
      -- ��������2
      IF (l_col_data_tab(cn_active_time2) IS NOT NULL) THEN
        lb_return := activite_time_check(l_col_data_tab(cn_active_time2));
        IF (lb_return = FALSE) THEN
          lv_item_nm := cv_act_time2||'('||g_csv_order_rec.dff2_name||')';
          lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_tkn_number_22             -- ���b�Z�[�W�R�[�h
                 ,iv_token_name1  => cv_tkn_item                  -- �g�[�N���R�[�h1
                 ,iv_token_value1 => lv_item_nm                   -- �g�[�N���l1
                 ,iv_token_name2  => cv_tkn_base_val              -- �g�[�N���R�[�h2
                 ,iv_token_value2 => iv_base_value                -- �g�[�N���l2
               );
          lv_errbuf := lv_errmsg;
          RAISE global_skip_error_expt;
        END IF;
      END IF;
      -- ��������3
      IF (l_col_data_tab(cn_active_time3) IS NOT NULL) THEN
        lb_return := activite_time_check(l_col_data_tab(cn_active_time3));
        IF (lb_return = FALSE) THEN
          lv_item_nm := cv_act_time3||'('||g_csv_order_rec.dff3_name||')';
          lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_tkn_number_22             -- ���b�Z�[�W�R�[�h
                 ,iv_token_name1  => cv_tkn_item                  -- �g�[�N���R�[�h1
                 ,iv_token_value1 => lv_item_nm                   -- �g�[�N���l1
                 ,iv_token_name2  => cv_tkn_base_val              -- �g�[�N���R�[�h2
                 ,iv_token_value2 => iv_base_value                -- �g�[�N���l2
               );
          lv_errbuf := lv_errmsg;
          RAISE global_skip_error_expt;
        END IF;
      END IF;
      -- ��������4
      IF (l_col_data_tab(cn_active_time4) IS NOT NULL) THEN
         lb_return := activite_time_check(l_col_data_tab(cn_active_time4));
         IF (lb_return = FALSE) THEN
           lv_item_nm := cv_act_time4||'('||g_csv_order_rec.dff4_name||')';
           lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_tkn_number_22             -- ���b�Z�[�W�R�[�h
                 ,iv_token_name1  => cv_tkn_item                  -- �g�[�N���R�[�h1
                 ,iv_token_value1 => lv_item_nm                   -- �g�[�N���l1
                 ,iv_token_name2  => cv_tkn_base_val              -- �g�[�N���R�[�h2
                 ,iv_token_value2 => iv_base_value                -- �g�[�N���l2
                );
           lv_errbuf := lv_errmsg;
           RAISE global_skip_error_expt;
         END IF;
      END IF;
      -- ��������5
      IF (l_col_data_tab(cn_active_time5) IS NOT NULL) THEN
        lb_return := activite_time_check(l_col_data_tab(cn_active_time5));
        IF (lb_return = FALSE) THEN
          lv_item_nm := cv_act_time5||'('||g_csv_order_rec.dff5_name||')';
          lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_tkn_number_22             -- ���b�Z�[�W�R�[�h
                 ,iv_token_name1  => cv_tkn_item                  -- �g�[�N���R�[�h1
                 ,iv_token_value1 => lv_item_nm                   -- �g�[�N���l1
                 ,iv_token_name2  => cv_tkn_base_val              -- �g�[�N���R�[�h2
                 ,iv_token_value2 => iv_base_value                -- �g�[�N���l2
               );
          lv_errbuf := lv_errmsg;
          RAISE global_skip_error_expt;
        END IF;
      END IF;
      -- ��������6
      IF (l_col_data_tab(cn_active_time6) IS NOT NULL) THEN
        lb_return := activite_time_check(l_col_data_tab(cn_active_time6));
        IF (lb_return = FALSE) THEN
          lv_item_nm := cv_act_time6||'('||g_csv_order_rec.dff6_name||')';
          lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_tkn_number_22             -- ���b�Z�[�W�R�[�h
                 ,iv_token_name1  => cv_tkn_item                  -- �g�[�N���R�[�h1
                 ,iv_token_value1 => lv_item_nm                   -- �g�[�N���l1
                 ,iv_token_name2  => cv_tkn_base_val              -- �g�[�N���R�[�h2
                 ,iv_token_value2 => iv_base_value                -- �g�[�N���l2
               );
          lv_errbuf := lv_errmsg;
          RAISE global_skip_error_expt;
        END IF;
      END IF;
      -- ��������7
      IF (l_col_data_tab(cn_active_time7) IS NOT NULL) THEN
        lb_return := activite_time_check(l_col_data_tab(cn_active_time7));
        IF (lb_return = FALSE) THEN
          lv_item_nm := cv_act_time7||'('||g_csv_order_rec.dff7_name||')';
          lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_tkn_number_22             -- ���b�Z�[�W�R�[�h
                 ,iv_token_name1  => cv_tkn_item                  -- �g�[�N���R�[�h1
                 ,iv_token_value1 => lv_item_nm                   -- �g�[�N���l1
                 ,iv_token_name2  => cv_tkn_base_val              -- �g�[�N���R�[�h2
                 ,iv_token_value2 => iv_base_value                -- �g�[�N���l2
               );
          lv_errbuf := lv_errmsg;
          RAISE global_skip_error_expt;
        END IF;
      END IF;
      -- ��������8
      IF (l_col_data_tab(cn_active_time8) IS NOT NULL) THEN
        lb_return := activite_time_check(l_col_data_tab(cn_active_time8));
        IF (lb_return = FALSE) THEN
          lv_item_nm := cv_act_time8||'('||g_csv_order_rec.dff8_name||')';
          lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_tkn_number_22             -- ���b�Z�[�W�R�[�h
                 ,iv_token_name1  => cv_tkn_item                  -- �g�[�N���R�[�h1
                 ,iv_token_value1 => lv_item_nm                   -- �g�[�N���l1
                 ,iv_token_name2  => cv_tkn_base_val              -- �g�[�N���R�[�h2
                 ,iv_token_value2 => iv_base_value                -- �g�[�N���l2
               );
          lv_errbuf := lv_errmsg;
          RAISE global_skip_error_expt;
        END IF;
      END IF;
      -- ��������9
      IF (l_col_data_tab(cn_active_time9) IS NOT NULL) THEN
        lb_return := activite_time_check(l_col_data_tab(cn_active_time9));
        IF (lb_return = FALSE) THEN
          lv_item_nm := cv_act_time9||'('||g_csv_order_rec.dff9_name||')';
          lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_tkn_number_22             -- ���b�Z�[�W�R�[�h
                 ,iv_token_name1  => cv_tkn_item                  -- �g�[�N���R�[�h1
                 ,iv_token_value1 => lv_item_nm                   -- �g�[�N���l1
                 ,iv_token_name2  => cv_tkn_base_val              -- �g�[�N���R�[�h2
                 ,iv_token_value2 => iv_base_value                -- �g�[�N���l2
               );
          lv_errbuf := lv_errmsg;
          RAISE global_skip_error_expt;
        END IF;
      END IF;
      -- ��������10
      IF (l_col_data_tab(cn_active_time10) IS NOT NULL) THEN
        lb_return := activite_time_check(l_col_data_tab(cn_active_time10));
        IF (lb_return = FALSE) THEN
          lv_item_nm := cv_act_time10||'('||g_csv_order_rec.dff10_name||')';
          lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_tkn_number_22             -- ���b�Z�[�W�R�[�h
                 ,iv_token_name1  => cv_tkn_item                  -- �g�[�N���R�[�h1
                 ,iv_token_value1 => lv_item_nm                   -- �g�[�N���l1
                 ,iv_token_name2  => cv_tkn_base_val              -- �g�[�N���R�[�h2
                 ,iv_token_value2 => iv_base_value                -- �g�[�N���l2
               );
          lv_errbuf := lv_errmsg;
          RAISE global_skip_error_expt;
        END IF;
      END IF;
      -- ��������11
      IF (l_col_data_tab(cn_active_time11) IS NOT NULL) THEN
        lb_return := activite_time_check(l_col_data_tab(cn_active_time11));
        IF (lb_return = FALSE) THEN
          lv_item_nm := cv_act_time11||'('||g_csv_order_rec.dff11_name||')';
          lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_tkn_number_22             -- ���b�Z�[�W�R�[�h
                 ,iv_token_name1  => cv_tkn_item                  -- �g�[�N���R�[�h1
                 ,iv_token_value1 => lv_item_nm                   -- �g�[�N���l1
                 ,iv_token_name2  => cv_tkn_base_val              -- �g�[�N���R�[�h2
                 ,iv_token_value2 => iv_base_value                -- �g�[�N���l2
               );
          lv_errbuf := lv_errmsg;
          RAISE global_skip_error_expt;
        END IF;
      END IF;
      -- ��������12
      IF (l_col_data_tab(cn_active_time12) IS NOT NULL) THEN
        lb_return := activite_time_check(l_col_data_tab(cn_active_time12));
        IF (lb_return = FALSE) THEN
          lv_item_nm := cv_act_time12||'('||g_csv_order_rec.dff12_name||')';
          lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_tkn_number_22             -- ���b�Z�[�W�R�[�h
                 ,iv_token_name1  => cv_tkn_item                  -- �g�[�N���R�[�h1
                 ,iv_token_value1 => lv_item_nm                   -- �g�[�N���l1
                 ,iv_token_name2  => cv_tkn_base_val              -- �g�[�N���R�[�h2
                 ,iv_token_value2 => iv_base_value                -- �g�[�N���l2
               );
          lv_errbuf := lv_errmsg;
          RAISE global_skip_error_expt;
        END IF;
      END IF;
      -- ��������13
      IF (l_col_data_tab(cn_active_time13) IS NOT NULL) THEN
        lb_return := activite_time_check(l_col_data_tab(cn_active_time13));
        IF (lb_return = FALSE) THEN
          lv_item_nm := cv_act_time13||'('||g_csv_order_rec.dff13_name||')';
          lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_tkn_number_22             -- ���b�Z�[�W�R�[�h
                 ,iv_token_name1  => cv_tkn_item                  -- �g�[�N���R�[�h1
                 ,iv_token_value1 => lv_item_nm                   -- �g�[�N���l1
                 ,iv_token_name2  => cv_tkn_base_val              -- �g�[�N���R�[�h2
                 ,iv_token_value2 => iv_base_value                -- �g�[�N���l2
               );
          lv_errbuf := lv_errmsg;
          RAISE global_skip_error_expt;
        END IF;
      END IF;
      -- ��������14
      IF (l_col_data_tab(cn_active_time14) IS NOT NULL) THEN
        lb_return := activite_time_check(l_col_data_tab(cn_active_time14));
        IF (lb_return = FALSE) THEN
          lv_item_nm := cv_act_time14||'('||g_csv_order_rec.dff14_name||')';
          lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_tkn_number_22             -- ���b�Z�[�W�R�[�h
                 ,iv_token_name1  => cv_tkn_item                  -- �g�[�N���R�[�h1
                 ,iv_token_value1 => lv_item_nm                   -- �g�[�N���l1
                 ,iv_token_name2  => cv_tkn_base_val              -- �g�[�N���R�[�h2
                 ,iv_token_value2 => iv_base_value                -- �g�[�N���l2
               );
          lv_errbuf := lv_errmsg;
          RAISE global_skip_error_expt;
        END IF;
      END IF;
      -- ��������15
      IF (l_col_data_tab(cn_active_time15) IS NOT NULL) THEN
        lb_return := activite_time_check(l_col_data_tab(cn_active_time15));
        IF (lb_return = FALSE) THEN
          lv_item_nm := cv_act_time15||'('||g_csv_order_rec.dff15_name||')';
          lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_tkn_number_22             -- ���b�Z�[�W�R�[�h
                 ,iv_token_name1  => cv_tkn_item                  -- �g�[�N���R�[�h1
                 ,iv_token_value1 => lv_item_nm                   -- �g�[�N���l1
                 ,iv_token_name2  => cv_tkn_base_val              -- �g�[�N���R�[�h2
                 ,iv_token_value2 => iv_base_value                -- �g�[�N���l2
               );
          lv_errbuf := lv_errmsg;
          RAISE global_skip_error_expt;
        END IF;
      END IF;
      -- ��������16
      IF (l_col_data_tab(cn_active_time16) IS NOT NULL) THEN
        lb_return := activite_time_check(l_col_data_tab(cn_active_time16));
        IF (lb_return = FALSE) THEN
          lv_item_nm := cv_act_time16||'('||g_csv_order_rec.dff16_name||')';
          lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_tkn_number_22             -- ���b�Z�[�W�R�[�h
                 ,iv_token_name1  => cv_tkn_item                  -- �g�[�N���R�[�h1
                 ,iv_token_value1 => lv_item_nm                   -- �g�[�N���l1
                 ,iv_token_name2  => cv_tkn_base_val              -- �g�[�N���R�[�h2
                 ,iv_token_value2 => iv_base_value                -- �g�[�N���l2
               );
          lv_errbuf := lv_errmsg;
          RAISE global_skip_error_expt;
        END IF;
      END IF;
      -- ��������17
      IF (l_col_data_tab(cn_active_time17) IS NOT NULL) THEN
        lb_return := activite_time_check(l_col_data_tab(cn_active_time17));
        IF (lb_return = FALSE) THEN
          lv_item_nm := cv_act_time17||'('||g_csv_order_rec.dff17_name||')';
          lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_tkn_number_22             -- ���b�Z�[�W�R�[�h
                 ,iv_token_name1  => cv_tkn_item                  -- �g�[�N���R�[�h1
                 ,iv_token_value1 => lv_item_nm                   -- �g�[�N���l1
                 ,iv_token_name2  => cv_tkn_base_val              -- �g�[�N���R�[�h2
                 ,iv_token_value2 => iv_base_value                -- �g�[�N���l2
               );
          lv_errbuf := lv_errmsg;
          RAISE global_skip_error_expt;
        END IF;
      END IF;
      -- ��������18
      IF (l_col_data_tab(cn_active_time18) IS NOT NULL) THEN
        lb_return := activite_time_check(l_col_data_tab(cn_active_time18));
        IF (lb_return = FALSE) THEN
          lv_item_nm := cv_act_time18||'('||g_csv_order_rec.dff18_name||')';
          lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_tkn_number_22             -- ���b�Z�[�W�R�[�h
                 ,iv_token_name1  => cv_tkn_item                  -- �g�[�N���R�[�h1
                 ,iv_token_value1 => lv_item_nm                   -- �g�[�N���l1
                 ,iv_token_name2  => cv_tkn_base_val              -- �g�[�N���R�[�h2
                 ,iv_token_value2 => iv_base_value                -- �g�[�N���l2
               );
          lv_errbuf := lv_errmsg;
          RAISE global_skip_error_expt;
        END IF;
      END IF;
      -- ��������19
      IF (l_col_data_tab(cn_active_time19) IS NOT NULL) THEN
        lb_return := activite_time_check(l_col_data_tab(cn_active_time19));
        IF (lb_return = FALSE) THEN
          lv_item_nm := cv_act_time19||'('||g_csv_order_rec.dff19_name||')';
          lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_tkn_number_22             -- ���b�Z�[�W�R�[�h
                 ,iv_token_name1  => cv_tkn_item                  -- �g�[�N���R�[�h1
                 ,iv_token_value1 => lv_item_nm                   -- �g�[�N���l1
                 ,iv_token_name2  => cv_tkn_base_val              -- �g�[�N���R�[�h2
                 ,iv_token_value2 => iv_base_value                -- �g�[�N���l2
               );
          lv_errbuf := lv_errmsg;
          RAISE global_skip_error_expt;
        END IF;
      END IF;
      -- ��������20
      IF (l_col_data_tab(cn_active_time20) IS NOT NULL) THEN
        lb_return := activite_time_check(l_col_data_tab(cn_active_time20));
        IF (lb_return = FALSE) THEN
          lv_item_nm := cv_act_time20||'('||g_csv_order_rec.dff20_name||')';
          lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_tkn_number_22             -- ���b�Z�[�W�R�[�h
                 ,iv_token_name1  => cv_tkn_item                  -- �g�[�N���R�[�h1
                 ,iv_token_value1 => lv_item_nm                   -- �g�[�N���l1
                 ,iv_token_name2  => cv_tkn_base_val              -- �g�[�N���R�[�h2
                 ,iv_token_value2 => iv_base_value                -- �g�[�N���l2
               );
          lv_errbuf := lv_errmsg;
          RAISE global_skip_error_expt;
        END IF;
      END IF;
-- Ver1.10 ADD End
    END IF;
--
    -- �s�P�ʃf�[�^�����R�[�h�ɃZ�b�g
    g_visit_data_rec.employee_number := l_col_data_tab(cn_employee_number);             -- �Ј��R�[�h
    g_visit_data_rec.account_number  := l_col_data_tab(cn_account_number);              -- �ڋq�R�[�h
    g_visit_data_rec.visit_date      := TO_DATE(lv_visit_date, cv_visit_date_fmt);      -- �K�����
    g_visit_data_rec.description  := SUBSTRB(l_col_data_tab(cn_description), 1, cn_description_cut_len); -- �ڍד��e
    /* 2009.05.14 K.Satomura T1_0931�Ή� START */
    -- �g�̊���
    --IF (TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff1_num)) <> cn_visit_dff_0) THEN
    --  g_visit_data_rec.dff1_cd := g_csv_order_rec.dff1_cd;
    --END IF;
    ---- �̑��t�H���[
    --IF (TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff2_num)) <> cn_visit_dff_0) THEN
    --  g_visit_data_rec.dff2_cd := g_csv_order_rec.dff2_cd;
    --END IF;
    ---- �X������
    --IF (TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff3_num)) <> cn_visit_dff_0) THEN
    --  g_visit_data_rec.dff3_cd := g_csv_order_rec.dff3_cd;
    --END IF;
    ---- �N���[���Ή�
    --IF (TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff4_num)) <> cn_visit_dff_0) THEN
    --  g_visit_data_rec.dff4_cd := g_csv_order_rec.dff4_cd;
    --END IF;
    ---- �����x��
    --IF (TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff5_num)) <> cn_visit_dff_0) THEN
    --  g_visit_data_rec.dff5_cd := g_csv_order_rec.dff5_cd;
    --END IF;
    ---- �����`�F�b�N�i�����j
    --IF (TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff6_num)) <> cn_visit_dff_0) THEN
    --  g_visit_data_rec.dff6_cd := g_csv_order_rec.dff6_cd;
    --END IF;
    ---- �����`�F�b�N�i��؁j
    --IF (TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff7_num)) <> cn_visit_dff_0) THEN
    --  g_visit_data_rec.dff7_cd := g_csv_order_rec.dff7_cd;
    --END IF;
    ---- �����`�F�b�N�i���̑��j
    --IF (TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff8_num)) <> cn_visit_dff_0) THEN
    --  g_visit_data_rec.dff8_cd := g_csv_order_rec.dff8_cd;
    --END IF;
    ---- �����`�F�b�N�i���[�t�j
    --IF (TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff9_num)) <> cn_visit_dff_0) THEN
    --  g_visit_data_rec.dff9_cd := g_csv_order_rec.dff9_cd;
    --END IF;
    ---- �����`�F�b�N�i�`���h�j
    --IF (TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff10_num)) <> cn_visit_dff_0) THEN
    --  g_visit_data_rec.dff10_cd := g_csv_order_rec.dff10_cd;
    --END IF;
    ln_array_count := 1;
    g_visit_data_rec.dff_cd_table := g_dff_cd_array();
    g_visit_data_rec.dff_cd_table.EXTEND(10);
    --
-- Ver1.10 ADD Start
    --�K��敪1���ݒ肳��Ă���ꍇ
    IF (g_csv_order_rec.dff1_num IS NOT NULL) THEN
-- Ver1.10 ADD End
      --�����L��̏ꍇ
      IF (TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff1_num)) <> cn_visit_dff_0) THEN
        g_visit_data_rec.dff_cd_table(ln_array_count) := g_csv_order_rec.dff1_cd;
        ln_array_count                                := ln_array_count + 1;
        --
      END IF;
      --
-- Ver1.10 ADD Start
    END IF;
    --�K��敪2���ݒ肳��Ă���ꍇ
    IF (g_csv_order_rec.dff2_num IS NOT NULL) THEN
-- Ver1.10 ADD End
      --�����L��̏ꍇ
      IF (TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff2_num)) <> cn_visit_dff_0) THEN
        g_visit_data_rec.dff_cd_table(ln_array_count) := g_csv_order_rec.dff2_cd;
        ln_array_count                                := ln_array_count + 1;
        --
      END IF;
      --
-- Ver1.10 ADD Start
    END IF;
    --�K��敪3���ݒ肳��Ă���ꍇ
    IF (g_csv_order_rec.dff3_num IS NOT NULL) THEN
-- Ver1.10 ADD End
      --�����L��̏ꍇ
      IF (TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff3_num)) <> cn_visit_dff_0) THEN
        g_visit_data_rec.dff_cd_table(ln_array_count) := g_csv_order_rec.dff3_cd;
        ln_array_count                                := ln_array_count + 1;
        --
      END IF;
      --
-- Ver1.10 ADD Start
    END IF;
    --�K��敪4���ݒ肳��Ă���ꍇ
    IF (g_csv_order_rec.dff4_num IS NOT NULL) THEN
-- Ver1.10 ADD End
      --�����L��̏ꍇ
      IF (TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff4_num)) <> cn_visit_dff_0) THEN
        g_visit_data_rec.dff_cd_table(ln_array_count) := g_csv_order_rec.dff4_cd;
        ln_array_count                                := ln_array_count + 1;
        --
      END IF;
      --
-- Ver1.10 ADD Start
    END IF;
    --�K��敪5���ݒ肳��Ă���ꍇ
    IF (g_csv_order_rec.dff5_num IS NOT NULL) THEN
-- Ver1.10 ADD End
      --�����L��̏ꍇ
      IF (TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff5_num)) <> cn_visit_dff_0) THEN
        g_visit_data_rec.dff_cd_table(ln_array_count) := g_csv_order_rec.dff5_cd;
        ln_array_count                                := ln_array_count + 1;
        --
      END IF;
      --
-- Ver1.10 ADD Start
    END IF;
    --�K��敪6���ݒ肳��Ă���ꍇ
    IF (g_csv_order_rec.dff6_num IS NOT NULL) THEN
-- Ver1.10 ADD End
      --�����L��̏ꍇ
      IF (TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff6_num)) <> cn_visit_dff_0) THEN
        g_visit_data_rec.dff_cd_table(ln_array_count) := g_csv_order_rec.dff6_cd;
        ln_array_count                                := ln_array_count + 1;
        --
      END IF;
      --
-- Ver1.10 ADD Start
    END IF;
    --�K��敪7���ݒ肳��Ă���ꍇ
    IF (g_csv_order_rec.dff7_num IS NOT NULL) THEN
-- Ver1.10 ADD End
      --�����L��̏ꍇ
      IF (TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff7_num)) <> cn_visit_dff_0) THEN
        g_visit_data_rec.dff_cd_table(ln_array_count) := g_csv_order_rec.dff7_cd;
        ln_array_count                                := ln_array_count + 1;
        --
      END IF;
      --
-- Ver1.10 ADD Start
    END IF;
    --�K��敪8���ݒ肳��Ă���ꍇ
    IF (g_csv_order_rec.dff8_num IS NOT NULL) THEN
-- Ver1.10 ADD End
      --�����L��̏ꍇ
      IF (TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff8_num)) <> cn_visit_dff_0) THEN
        g_visit_data_rec.dff_cd_table(ln_array_count) := g_csv_order_rec.dff8_cd;
        ln_array_count                                := ln_array_count + 1;
        --
      END IF;
      --
-- Ver1.10 ADD Start
    END IF;
    --�K��敪9���ݒ肳��Ă���ꍇ
    IF (g_csv_order_rec.dff9_num IS NOT NULL) THEN
-- Ver1.10 ADD End
      --�����L��̏ꍇ
      IF (TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff9_num)) <> cn_visit_dff_0) THEN
        g_visit_data_rec.dff_cd_table(ln_array_count) := g_csv_order_rec.dff9_cd;
        ln_array_count                                := ln_array_count + 1;
        --
      END IF;
      --
-- Ver1.10 ADD Start
    END IF;
    --�K��敪10���ݒ肳��Ă���ꍇ
    IF (g_csv_order_rec.dff10_num IS NOT NULL) THEN
-- Ver1.10 ADD End
      --�����L��̏ꍇ
      IF (TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff10_num)) <> cn_visit_dff_0) THEN
        g_visit_data_rec.dff_cd_table(ln_array_count) := g_csv_order_rec.dff10_cd;
        ln_array_count                                := ln_array_count + 1;
        --
      END IF;
      --
-- Ver1.10 ADD Start
    END IF;
    --
    --�K��敪11���ݒ肳��Ă���ꍇ
    IF (g_csv_order_rec.dff11_num IS NOT NULL) THEN
      --�����L��̏ꍇ
      IF (ln_array_count <= 10 AND TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff11_num)) <> cn_visit_dff_0) THEN
        g_visit_data_rec.dff_cd_table(ln_array_count) := g_csv_order_rec.dff11_cd;
        ln_array_count                                := ln_array_count + 1;
        --
      END IF;
      --
    END IF;
    --�K��敪12���ݒ肳��Ă���ꍇ
    IF (g_csv_order_rec.dff12_num IS NOT NULL) THEN
      --�����L��̏ꍇ
      IF (ln_array_count <= 10 AND TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff12_num)) <> cn_visit_dff_0) THEN
        g_visit_data_rec.dff_cd_table(ln_array_count) := g_csv_order_rec.dff12_cd;
        ln_array_count                                := ln_array_count + 1;
        --
      END IF;
      --
    END IF;
    --�K��敪13���ݒ肳��Ă���ꍇ
    IF (g_csv_order_rec.dff13_num IS NOT NULL) THEN
      --�����L��̏ꍇ
      IF (ln_array_count <= 10 AND TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff13_num)) <> cn_visit_dff_0) THEN
        g_visit_data_rec.dff_cd_table(ln_array_count) := g_csv_order_rec.dff13_cd;
        ln_array_count                                := ln_array_count + 1;
        --
      END IF;
      --
    END IF;
    --�K��敪14���ݒ肳��Ă���ꍇ
    IF (g_csv_order_rec.dff14_num IS NOT NULL) THEN
      --�����L��̏ꍇ
      IF (ln_array_count <= 10 AND TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff14_num)) <> cn_visit_dff_0) THEN
        g_visit_data_rec.dff_cd_table(ln_array_count) := g_csv_order_rec.dff14_cd;
        ln_array_count                                := ln_array_count + 1;
        --
      END IF;
      --
    END IF;
    --�K��敪15���ݒ肳��Ă���ꍇ
    IF (g_csv_order_rec.dff15_num IS NOT NULL) THEN
      --�����L��̏ꍇ
      IF (ln_array_count <= 10 AND TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff15_num)) <> cn_visit_dff_0) THEN
        g_visit_data_rec.dff_cd_table(ln_array_count) := g_csv_order_rec.dff15_cd;
        ln_array_count                                := ln_array_count + 1;
        --
      END IF;
      --
    END IF;
    --�K��敪16���ݒ肳��Ă���ꍇ
    IF (g_csv_order_rec.dff16_num IS NOT NULL) THEN
      --�����L��̏ꍇ
      IF (ln_array_count <= 10 AND TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff16_num)) <> cn_visit_dff_0) THEN
        g_visit_data_rec.dff_cd_table(ln_array_count) := g_csv_order_rec.dff16_cd;
        ln_array_count                                := ln_array_count + 1;
        --
      END IF;
      --
    END IF;
    --�K��敪17���ݒ肳��Ă���ꍇ
    IF (g_csv_order_rec.dff17_num IS NOT NULL) THEN
      --�����L��̏ꍇ
      IF (ln_array_count <= 10 AND TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff17_num)) <> cn_visit_dff_0) THEN
        g_visit_data_rec.dff_cd_table(ln_array_count) := g_csv_order_rec.dff17_cd;
        ln_array_count                                := ln_array_count + 1;
        --
      END IF;
      --
    END IF;
    --�K��敪18���ݒ肳��Ă���ꍇ
    IF (g_csv_order_rec.dff18_num IS NOT NULL) THEN
      --�����L��̏ꍇ
      IF (ln_array_count <= 10 AND TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff18_num)) <> cn_visit_dff_0) THEN
        g_visit_data_rec.dff_cd_table(ln_array_count) := g_csv_order_rec.dff18_cd;
        ln_array_count                                := ln_array_count + 1;
        --
      END IF;
      --
    END IF;
    --�K��敪19���ݒ肳��Ă���ꍇ
    IF (g_csv_order_rec.dff19_num IS NOT NULL) THEN
      --�����L��̏ꍇ
      IF (ln_array_count <= 10 AND TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff19_num)) <> cn_visit_dff_0) THEN
        g_visit_data_rec.dff_cd_table(ln_array_count) := g_csv_order_rec.dff19_cd;
        ln_array_count                                := ln_array_count + 1;
        --
      END IF;
      --
    END IF;
    --�K��敪20���ݒ肳��Ă���ꍇ
    IF (g_csv_order_rec.dff20_num IS NOT NULL) THEN
      --�����L��̏ꍇ
      IF (ln_array_count <= 10 AND TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff20_num)) <> cn_visit_dff_0) THEN
        g_visit_data_rec.dff_cd_table(ln_array_count) := g_csv_order_rec.dff20_cd;
        ln_array_count                                := ln_array_count + 1;
        --
      END IF;
    END IF;
      --
-- Ver1.10 ADD End
    /* 2009.05.14 K.Satomura T1_0931�Ή� END */
--
  EXCEPTION
    -- *** �X�L�b�v��O�n���h�� ***
    WHEN global_skip_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END data_proper_check;
--
  /**********************************************************************************
   * Procedure Name   : chk_mst_is_exists
   * Description      : �}�X�^���݃`�F�b�N (A-6)
   ***********************************************************************************/
--
  PROCEDURE chk_mst_is_exists(
     iv_base_value       IN  VARCHAR2         -- ���Y�s�f�[�^
    ,ov_errbuf           OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            -- # �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              -- # �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100) := 'chk_mst_is_exists';  -- �v���O������
--
-- #######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf            VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode           VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg            VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
-- ###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_get_process                CONSTANT VARCHAR2(100) := '���o';
    cv_resource_table_vl_nm       CONSTANT VARCHAR2(100) := '���\�[�X�}�X�^�r���[';
    cv_account_table_vl_nm        CONSTANT VARCHAR2(100) := '�ڋq�}�X�^�r���[';
    cv_employee_number_nm         CONSTANT VARCHAR2(100) := '�Ј��R�[�h';
    cv_account_number_nm          CONSTANT VARCHAR2(100) := '�ڋq�R�[�h';
    cv_false                      CONSTANT VARCHAR2(100) := 'FALSE';
    cv_cust_class_code_cust       CONSTANT xxcso_cust_accounts_v.customer_class_code%TYPE := '10'; -- �ڋq�敪���ڋq
    cv_cust_class_code_cyclic     CONSTANT xxcso_cust_accounts_v.customer_class_code%TYPE := '15'; -- �ڋq�敪������
    cv_cust_class_code_tonya      CONSTANT xxcso_cust_accounts_v.customer_class_code%TYPE := '16'; -- �ڋq�敪���≮������
    cv_cust_status_mc_candidate   CONSTANT xxcso_cust_accounts_v.customer_status%TYPE     := '10'; -- �ڋq�X�e�[�^�X���l�b���
    cv_cust_status_mc             CONSTANT xxcso_cust_accounts_v.customer_status%TYPE     := '20'; -- �ڋq�X�e�[�^�X���l�b
    cv_cust_status_sp_decision    CONSTANT xxcso_cust_accounts_v.customer_status%TYPE     := '25'; -- �ڋq�X�e�[�^�X���r�o���ٍ�
    cv_cust_status_approved       CONSTANT xxcso_cust_accounts_v.customer_status%TYPE     := '30'; -- �ڋq�X�e�[�^�X�����F��
    cv_cust_status_customer       CONSTANT xxcso_cust_accounts_v.customer_status%TYPE     := '40'; -- �ڋq�X�e�[�^�X���ڋq
    cv_cust_status_break          CONSTANT xxcso_cust_accounts_v.customer_status%TYPE     := '50'; -- �ڋq�X�e�[�^�X���x�~
    cv_cust_status_abort_approved CONSTANT xxcso_cust_accounts_v.customer_status%TYPE     := '90'; -- �ڋq�X�e�[�^�X�����~���ٍ�
    cv_cust_status_not_applicable CONSTANT xxcso_cust_accounts_v.customer_status%TYPE     := '99'; -- �ڋq�X�e�[�^�X���ΏۊO
    -- *** ���[�J���ϐ� ***
    lv_gl_period_statuses     VARCHAR2(100); -- �u�K������v�ɊY������Ώۂ̉�v���Ԃ��N���[�Y
    ld_visite_date            DATE;          -- �K�����
    -- ���b�Z�[�W�o�͗p
    lv_msg                         VARCHAR2(5000);
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- *** 1. �Ј��R�[�h�̃}�X�^���݃`�F�b�N *** --
--
    ld_visite_date := TRUNC(g_visit_data_rec.visit_date);
--
    BEGIN
      -- *** ���\�[�X�}�X�^�r���[���烊�\�[�XID�𒊏o *** --
      SELECT xrv.resource_id resource_id                                -- ���\�[�XID
      INTO   g_visit_data_rec.resource_id
      FROM   xxcso_resources_v xrv
      WHERE  xrv.employee_number = g_visit_data_rec.employee_number
        AND ld_visite_date
          BETWEEN TRUNC(xrv.employee_start_date) AND TRUNC(NVL(xrv.employee_end_date, ld_visite_date))
        AND ld_visite_date
          BETWEEN TRUNC(xrv.resource_start_date) AND TRUNC(NVL(xrv.resource_end_date, ld_visite_date))
        AND ld_visite_date
          BETWEEN TRUNC(xrv.assign_start_date) AND TRUNC(NVL(xrv.assign_end_date, ld_visite_date))
        AND ld_visite_date
          BETWEEN TRUNC(xrv.start_date) AND TRUNC(NVL(xrv.end_date, ld_visite_date));
--
    EXCEPTION
      -- ���o������0���̏ꍇ
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_09             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl                   -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_resource_table_vl_nm      -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_item                  -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_employee_number_nm        -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_base_val              -- �g�[�N���R�[�h3
                       ,iv_token_value3 => iv_base_value                -- �g�[�N���l3
                     );
          lv_errbuf := lv_errmsg;
          RAISE global_skip_error_expt;
      -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_11             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl                   -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_resource_table_vl_nm      -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_base_val              -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_base_value                -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_process               -- �g�[�N���R�[�h3
                       ,iv_token_value3 => cv_get_process               -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_err_msg               -- �g�[�N���R�[�h4
                       ,iv_token_value4 => SQLERRM                      -- �g�[�N���l4
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
    END;
--
     -- *** 2. �ڋq�R�[�h�̃}�X�^���݃`�F�b�N *** --
    BEGIN
--
      -- *** 1. �p�[�e�BID�A�p�[�e�B���̂ƌڋq�X�e�[�^�X�𒊏o *** --
      SELECT xcav.party_id                                              -- �p�[�e�BID
            ,xcav.party_name                                            -- �p�[�e�B����
            ,xcav.customer_status                                       -- �ڋq�X�e�[�^�X
      INTO   g_visit_data_rec.party_id
            ,g_visit_data_rec.party_name
            ,g_visit_data_rec.customer_status
      FROM   xxcso_cust_accounts_v xcav
      WHERE  xcav.account_number = g_visit_data_rec.account_number
      AND    ((
                 /* 2009.05.28 K.Satomura T1_0137�Ή� START */
                 --xcav.customer_class_code = cv_cust_class_code_cust
                 NVL(xcav.customer_class_code, cv_cust_class_code_cust) = cv_cust_class_code_cust
                 /* 2009.05.28 K.Satomura T1_0137�Ή� START */
             AND xcav.customer_status IN (cv_cust_status_mc_candidate, cv_cust_status_mc, cv_cust_status_sp_decision,
                                          cv_cust_status_approved, cv_cust_status_customer, cv_cust_status_break)
             )
      OR     (
                 xcav.customer_class_code IN (cv_cust_class_code_cyclic, cv_cust_class_code_tonya)
             AND xcav.customer_status IN (cv_cust_status_abort_approved, cv_cust_status_not_applicable)
             ))
      ;
--
    EXCEPTION
      -- ���o������0���̏ꍇ
      WHEN NO_DATA_FOUND THEN
--
        /* 2009.07.16 K.Satomura 0000070�Ή� START */
        -- �_�~�[�ڋq�R�[�h����擾�����p�[�e�BID�A�p�[�e�B���̂ƌڋq�X�e�[�^�X���Z�b�g
        --g_visit_data_rec.party_id := gt_party_id;
        --g_visit_data_rec.party_name := gt_party_name;
        --g_visit_data_rec.customer_status := gt_customer_status;
--
        --lv_msg := xxccp_common_pkg.get_msg(
        --                iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
        --               ,iv_name         => cv_tkn_number_15             -- ���b�Z�[�W�R�[�h
        --               ,iv_token_name1  => cv_tkn_tbl                   -- �g�[�N���R�[�h1
        --               ,iv_token_value1 => cv_account_table_vl_nm       -- �g�[�N���l1
        --               ,iv_token_name2  => cv_tkn_item                  -- �g�[�N���R�[�h2
        --               ,iv_token_value2 => cv_account_number_nm         -- �g�[�N���l2
        --               ,iv_token_name3  => cv_tkn_base_val              -- �g�[�N���R�[�h3
        --               ,iv_token_value3 => iv_base_value                -- �g�[�N���l3
        --             );
        --lv_errbuf := lv_msg;
--
        -- ���b�Z�[�W���o��
        --fnd_file.put_line(
        --   which  => FND_FILE.OUTPUT
        --  ,buff   => lv_msg
        --);
--
        -- ���O�o��
        --fnd_file.put_line(
        --   which  => FND_FILE.LOG
        --  ,buff   => lv_errbuf 
        --);
--
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name            -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_09       -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_item            -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_account_number_nm   -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_tbl             -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_account_table_vl_nm -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_base_val        -- �g�[�N���R�[�h3
                       ,iv_token_value3 => iv_base_value          -- �g�[�N���l3
                     );
        --
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
        --
        /* 2009.07.16 K.Satomura 0000070�Ή� END */
      -- ���o�Ɏ��s�����ꍇ�̌㏈��
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_11             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl                   -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_account_table_vl_nm       -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_base_val              -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_base_value                -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_process               -- �g�[�N���R�[�h3
                       ,iv_token_value3 => cv_get_process               -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_err_msg               -- �g�[�N���R�[�h4
                       ,iv_token_value4 => SQLERRM                      -- �g�[�N���l4
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
    END;
--
    -- *** 3. �u�K������v�ɊY������Ώۂ̉�v���Ԃ��N���[�Y����Ă��邩���`�F�b�N *** --
    -- ��v���ԃ`�F�b�N�֐����g�p
      lv_gl_period_statuses := xxcso_util_common_pkg.check_ar_gl_period_status(g_visit_data_rec.visit_date);
--
    -- �`�F�b�N�֐��̃��^�[���l��'FALSE'(�N���[�Y����Ă���)�̏ꍇ
    IF lv_gl_period_statuses = cv_false THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_10             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_base_val              -- �g�[�N���R�[�h1
                     ,iv_token_value1 => iv_base_value                -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_skip_error_expt;
    END IF;
--
  EXCEPTION
    -- *** �X�L�b�v��O�n���h�� ***
    WHEN global_skip_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
     -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END chk_mst_is_exists;
--
  /**********************************************************************************
   * Procedure Name   : get_visit_same_data
   * Description      : ����K����уf�[�^���o (A-7)
   ***********************************************************************************/
--
  PROCEDURE get_visit_same_data(
     on_task_id               OUT NOCOPY NUMBER               -- �^�X�N�h�c
    ,on_obj_ver_num           OUT NOCOPY NUMBER               -- �I�u�W�F�N�g�o�[�W�����ԍ�
    ,on_task_count            OUT NOCOPY NUMBER               -- ���o����
    ,iv_base_value            IN  VARCHAR2                    -- ���Y�s�f�[�^
    ,ov_errbuf                OUT NOCOPY VARCHAR2             -- �G���[�E���b�Z�[�W            -- # �Œ� #
    ,ov_retcode               OUT NOCOPY VARCHAR2             -- ���^�[���E�R�[�h              -- # �Œ� #
    ,ov_errmsg                OUT NOCOPY VARCHAR2             -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'get_visit_same_data';     -- �v���O������
--
-- #####################  �Œ胍�[�J���ϐ��錾�� START     #########################
--
    lv_errbuf            VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode           VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg            VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
-- #####################  �Œ胍�[�J���ϐ��錾�� END       #########################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_get_process       CONSTANT VARCHAR2(100) := '���o';
    cv_task_table_nm     CONSTANT VARCHAR2(100) := '�^�X�N�e�[�u��';
    cv_code_employee     CONSTANT VARCHAR2(100) := 'RS_EMPLOYEE';
    cv_code_party        CONSTANT VARCHAR2(100) := 'PARTY';
    cv_deleted_flag_n    CONSTANT VARCHAR2(100) := 'N';
    /* 2009.07.16 K.Satomura 0000070�Ή� START */
    cv_task_close        CONSTANT VARCHAR2(100) := 'XXCSO1_TASK_STATUS_CLOSED_ID';
    cv_visit_date_fmt1   CONSTANT VARCHAR2(100) := 'YYYY/MM/DD HH24:MI';
    cv_visit_date_fmt2   CONSTANT VARCHAR2(100) := 'YYYY/MM/DD HH24:MI:SS';
    cd_sysdate           CONSTANT DATE          := TO_DATE(TO_CHAR(SYSDATE, cv_visit_date_fmt1), cv_visit_date_fmt2);
    /* 2009.07.16 K.Satomura 0000070�Ή� END */
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR l_task_cur
    IS
      SELECT task.task_id task_id                                               -- �^�X�NID
            ,task.object_version_number obj_ver_num                             -- �I�u�W�F�N�g�o�[�W�����ԍ�
      FROM   jtf_tasks_b task
      WHERE  task.owner_id = g_visit_data_rec.resource_id
        AND  task.owner_type_code = cv_code_employee
        AND  task.source_object_id = g_visit_data_rec.party_id
        AND  task.source_object_type_code = cv_code_party
        AND  task.actual_end_date = g_visit_data_rec.visit_date
        AND  task.deleted_flag = cv_deleted_flag_n
      ORDER BY task.last_update_date DESC
      FOR UPDATE NOWAIT;
    -- *** ���[�J���E���R�[�h *** 
    l_task_rec l_task_cur%ROWTYPE;
--
    /* 2009.07.16 K.Satomura 0000070�Ή� START */
    CURSOR l_task_cur2
    IS
      SELECT task.task_id task_id                   -- �^�X�NID
            ,task.object_version_number obj_ver_num -- �I�u�W�F�N�g�o�[�W�����ԍ�
      FROM   jtf_tasks_b task
      WHERE  task.owner_id                = g_visit_data_rec.resource_id
      AND    task.owner_type_code         = cv_code_employee
      AND    task.source_object_id        = g_visit_data_rec.party_id
      AND    task.source_object_type_code = cv_code_party
      AND    task.actual_end_date         = g_visit_data_rec.visit_date
      AND    task.deleted_flag            = cv_deleted_flag_n
      AND    task.task_status_id          = TO_NUMBER(fnd_profile.value(cv_task_close))
      ORDER BY task.last_update_date DESC
      FOR UPDATE NOWAIT;
    /* 2009.07.16 K.Satomura 0000070�Ή� END */
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- *** 1. �^�X�N�e�[�u������^�X�NID�ƃI�u�W�F�N�g�o�[�W�����ԍ����擾 *** --
    BEGIN
--
      -- ���o����
      on_task_count := 0;
      -- �J�[�\���I�[�v��
      /* 2009.07.16 K.Satomura 0000070�Ή� START */
      IF (g_visit_data_rec.visit_date > cd_sysdate) THEN
        -- �K��������������t�̏ꍇ
      /* 2009.07.16 K.Satomura 0000070�Ή� END */
        OPEN l_task_cur;
      /* 2009.07.16 K.Satomura 0000070�Ή� START */
      ELSE
        -- �K����������ݓ������܂މߋ����t�̏ꍇ
        OPEN l_task_cur2;
        --
      END IF;
      /* 2009.07.16 K.Satomura 0000070�Ή� END */
--
      <<task_id_loop>>
      LOOP
        /* 2009.07.16 K.Satomura 0000070�Ή� START */
        IF (g_visit_data_rec.visit_date > cd_sysdate) THEN
        /* 2009.07.16 K.Satomura 0000070�Ή� END */
          FETCH l_task_cur INTO l_task_rec;
        /* 2009.07.16 K.Satomura 0000070�Ή� START */
        ELSE
          FETCH l_task_cur2 INTO l_task_rec;
          --
        END IF;
        /* 2009.07.16 K.Satomura 0000070�Ή� END */
--
        /* 2009.07.16 K.Satomura 0000070�Ή� START */
        IF (g_visit_data_rec.visit_date > cd_sysdate) THEN
        /* 2009.07.16 K.Satomura 0000070�Ή� END */
          EXIT WHEN l_task_cur%NOTFOUND OR l_task_cur%ROWCOUNT = 0;
        /* 2009.07.16 K.Satomura 0000070�Ή� START */
        ELSE
          EXIT WHEN l_task_cur2%NOTFOUND OR l_task_cur2%ROWCOUNT = 0;
          --
        END IF;
        /* 2009.07.16 K.Satomura 0000070�Ή� END */
--
        -- ���o����
        /* 2009.07.16 K.Satomura 0000070�Ή� START */
        IF (g_visit_data_rec.visit_date > cd_sysdate) THEN
        /* 2009.07.16 K.Satomura 0000070�Ή� END */
          on_task_count := l_task_cur%ROWCOUNT;
        /* 2009.07.16 K.Satomura 0000070�Ή� START */
        ELSE
          on_task_count := l_task_cur2%ROWCOUNT;
          --
        END IF;
        /* 2009.07.16 K.Satomura 0000070�Ή� END */
        -- �^�X�NID
        on_task_id    := l_task_rec.task_id;
        -- �I�u�W�F�N�g�o�[�W�����ԍ�
        on_obj_ver_num := l_task_rec.obj_ver_num;
--
        EXIT;
      END LOOP task_id_loop;
--
      -- �J�[�\���E�N���[�Y
      /* 2009.07.16 K.Satomura 0000070�Ή� START */
      IF (g_visit_data_rec.visit_date > cd_sysdate) THEN
      /* 2009.07.16 K.Satomura 0000070�Ή� END */
        CLOSE l_task_cur;
      /* 2009.07.16 K.Satomura 0000070�Ή� START */
      ELSE
        CLOSE l_task_cur2;
        --
      END IF;
      /* 2009.07.16 K.Satomura 0000070�Ή� END */
--
    EXCEPTION
      -- ���b�N���s�����ꍇ�̗�O
      WHEN global_lock_expt THEN
        -- �J�[�\���E�N���[�Y
        IF (l_task_cur%ISOPEN) THEN
          CLOSE l_task_cur;
        END IF;
        /* 2009.07.16 K.Satomura 0000070�Ή� START */
        IF (l_task_cur2%ISOPEN) THEN
          CLOSE l_task_cur2;
        END IF;
        /* 2009.07.16 K.Satomura 0000070�Ή� END */
--
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                        -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_13                   -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl                         -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_task_table_nm                   -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_base_val                    -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_base_value                      -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE global_skip_error_expt;
      -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        -- �J�[�\���E�N���[�Y
        IF (l_task_cur%ISOPEN) THEN
          CLOSE l_task_cur;
        END IF;
        /* 2009.07.16 K.Satomura 0000070�Ή� START */
        IF (l_task_cur2%ISOPEN) THEN
          CLOSE l_task_cur2;
        END IF;
        /* 2009.07.16 K.Satomura 0000070�Ή� END */
--
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_11             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl                   -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_task_table_nm             -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_base_val              -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_base_value                -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_process               -- �g�[�N���R�[�h3
                       ,iv_token_value3 => cv_get_process               -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_err_msg               -- �g�[�N���R�[�h4
                       ,iv_token_value4 => SQLERRM                      -- �g�[�N���l4
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
    END;
--
    /* 2009.07.16 K.Satomura 0000070�Ή� START */
    IF ((g_visit_data_rec.visit_date <= cd_sysdate)
      AND on_task_count > 0)
    THEN
      -- �K����������݂��܂މߋ����t�Ń^�X�N�����݂����ꍇ�̓X�L�b�v�B
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name      -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_21 -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_base_val  -- �g�[�N���R�[�h1
                     ,iv_token_value1 => iv_base_value    -- �g�[�N���l1
                   );
      --
      lv_errbuf := lv_errmsg;
      RAISE global_skip_error_expt;
      --
    END IF;
    /* 2009.07.16 K.Satomura 0000070�Ή� END */
  EXCEPTION
    -- *** �X�L�b�v��O�n���h�� ***
    WHEN global_skip_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END get_visit_same_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_visit_data
   * Description      : �K����уf�[�^�o�^ (A-8)
   ***********************************************************************************/
--
  PROCEDURE insert_visit_data(
     iv_base_value        IN  VARCHAR2                    -- ���Y�s�f�[�^
    ,ov_errbuf            OUT NOCOPY VARCHAR2             -- �G���[�E���b�Z�[�W            -- # �Œ� #
    ,ov_retcode           OUT NOCOPY VARCHAR2             -- ���^�[���E�R�[�h              -- # �Œ� #
    ,ov_errmsg            OUT NOCOPY VARCHAR2             -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'insert_visit_data';     -- �v���O������
--
-- #####################  �Œ胍�[�J���ϐ��錾�� START     #########################
--
    lv_errbuf            VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode           VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg            VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
-- #####################  �Œ胍�[�J���ϐ��錾�� END       #########################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_insert_process    CONSTANT VARCHAR2(100) := '�o�^';
    cv_task_table_nm     CONSTANT VARCHAR2(100) := '�^�X�N�e�[�u��';
    /* 2009.07.16 K.Satomura 0000070�Ή� START */
    ct_task_status_open  CONSTANT VARCHAR2(100) := 'XXCSO1_TASK_STATUS_OPEN_ID'; 
    cv_visit_date_fmt1   CONSTANT VARCHAR2(100) := 'YYYY/MM/DD HH24:MI';
    cv_visit_date_fmt2   CONSTANT VARCHAR2(100) := 'YYYY/MM/DD HH24:MI:SS';
    /* 2009.07.16 K.Satomura 0000070�Ή� END */
    -- *** ���[�J���ϐ� ***
    ln_task_id         NUMBER;            -- �^�X�NID
    /* 2009.07.16 K.Satomura 0000070�Ή� START */
    lt_task_status_id  jtf_task_statuses_b.task_status_id%TYPE; -- �^�X�N�X�e�[�^�X�h�c
    /* 2009.07.16 K.Satomura 0000070�Ή� END */
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =======================
    -- �K����уf�[�^�o�^ 
    -- =======================
    /* 2009.07.16 K.Satomura 0000070�Ή� START */
    IF (g_visit_data_rec.visit_date > TO_DATE(TO_CHAR(SYSDATE, cv_visit_date_fmt1), cv_visit_date_fmt2)) THEN
      -- �K������������̏ꍇ�́A�^�X�N�X�e�[�^�X�̓I�[�v���œo�^����B
      lt_task_status_id := TO_NUMBER(fnd_profile.value(ct_task_status_open));
      --
    ELSE
      lt_task_status_id := NULL;
      --
    END IF;
    --
    /* 2009.07.16 K.Satomura 0000070�Ή� END */
    xxcso_task_common_pkg.create_task(
       g_visit_data_rec.resource_id        -- ���\�[�XID
      ,g_visit_data_rec.party_id           -- �p�[�e�BID
      ,g_visit_data_rec.party_name         -- �p�[�e�B����
      /* 2017.04.13 K.Kiriu E_�{�ғ�_14025�Ή� START */
      ,cd_sysdate                          -- �f�[�^���͓���
      /* 2017.04.13 K.Kiriu E_�{�ғ�_14025�Ή� END   */
      ,g_visit_data_rec.visit_date         -- �K�����
      ,g_visit_data_rec.description        -- �ڍד��e
      /* 2009.07.16 K.Satomura 0000070�Ή� START */
      ,lt_task_status_id                   -- �^�X�N�X�e�[�^�X�h�c
      /* 2009.07.16 K.Satomura 0000070�Ή� END */
      /* 2009.05.14 K.Satomura T1_0931�Ή� START */
      --,g_visit_data_rec.dff1_cd            -- �g�̊���
      --,g_visit_data_rec.dff2_cd            -- �̑��t�H���[
      --,g_visit_data_rec.dff3_cd            -- �X������
      --,g_visit_data_rec.dff4_cd            -- �N���[���Ή�
      --,g_visit_data_rec.dff5_cd            -- �����x��
      --,g_visit_data_rec.dff6_cd            -- �����`�F�b�N�i�����j
      --,g_visit_data_rec.dff7_cd            -- �����`�F�b�N�i��؁j
      --,g_visit_data_rec.dff8_cd            -- �����`�F�b�N�i���̑��j
      --,g_visit_data_rec.dff9_cd            -- �����`�F�b�N�i���[�t�j
      --,g_visit_data_rec.dff10_cd           -- �����`�F�b�N�i�`���h�j
-- Ver1.10 MOD Start comment update only
      ,g_visit_data_rec.dff_cd_table(1)      -- �����敪1
      ,g_visit_data_rec.dff_cd_table(2)      -- �����敪2
      ,g_visit_data_rec.dff_cd_table(3)      -- �����敪3
      ,g_visit_data_rec.dff_cd_table(4)      -- �����敪4
      ,g_visit_data_rec.dff_cd_table(5)      -- �����敪5
      ,g_visit_data_rec.dff_cd_table(6)      -- �����敪6
      ,g_visit_data_rec.dff_cd_table(7)      -- �����敪7
      ,g_visit_data_rec.dff_cd_table(8)      -- �����敪8
      ,g_visit_data_rec.dff_cd_table(9)      -- �����敪9
      ,g_visit_data_rec.dff_cd_table(10)     -- �����敪10
-- Ver1.10 MOD End comment update only
      /* 2009.05.14 K.Satomura T1_0931�Ή� END */
      ,'0'
      ,'2'
      ,NULL
      /* 2009.09.08 D.Abe 0001312�Ή� START */
      --,gt_customer_status
      ,g_visit_data_rec.customer_status
      /* 2009.09.08 D.Abe 0001312�Ή� END */
      ,ln_task_id
      ,lv_errbuf
      ,lv_retcode
      ,lv_errmsg
    );
    -- ����ł͂Ȃ��ꍇ
    IF (lv_retcode <> cv_status_normal) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_11             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_tbl                   -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_task_table_nm             -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_base_val              -- �g�[�N���R�[�h2
                     ,iv_token_value2 => iv_base_value                -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_process               -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_insert_process            -- �g�[�N���l3
                     ,iv_token_name4  => cv_tkn_err_msg               -- �g�[�N���R�[�h4
                     ,iv_token_value4 => lv_errmsg                    -- �g�[�N���l4
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_skip_error_expt;
    END IF;
--
  EXCEPTION
    -- *** �X�L�b�v��O�n���h�� ***
    WHEN global_skip_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END insert_visit_data;
--
  /**********************************************************************************
   * Procedure Name   : update_visit_data
   * Description      : �K����уf�[�^�X�V (A-9)
   ***********************************************************************************/
--
  PROCEDURE update_visit_data(
     in_task_id           IN  NUMBER                      -- �^�X�N�h�c
    ,in_obj_ver_num       IN  NUMBER                      -- �I�u�W�F�N�g�o�[�W�����ԍ�
    ,iv_base_value        IN  VARCHAR2                    -- ���Y�s�f�[�^
    ,ov_errbuf            OUT NOCOPY VARCHAR2             -- �G���[�E���b�Z�[�W            -- # �Œ� #
    ,ov_retcode           OUT NOCOPY VARCHAR2             -- ���^�[���E�R�[�h              -- # �Œ� #
    ,ov_errmsg            OUT NOCOPY VARCHAR2             -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'update_visit_data';     -- �v���O������
--
-- #####################  �Œ胍�[�J���ϐ��錾�� START     #########################
--
    lv_errbuf            VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode           VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg            VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
-- #####################  �Œ胍�[�J���ϐ��錾�� END       #########################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_update_process    CONSTANT VARCHAR2(100) := '�X�V';
    cv_task_table_nm     CONSTANT VARCHAR2(100) := '�^�X�N�e�[�u��';
    /* 2009.07.16 K.Satomura 0000070�Ή� START */
    ct_task_status_open  CONSTANT VARCHAR2(100) := 'XXCSO1_TASK_STATUS_OPEN_ID'; 
    cv_visit_date_fmt1   CONSTANT VARCHAR2(100) := 'YYYY/MM/DD HH24:MI';
    cv_visit_date_fmt2   CONSTANT VARCHAR2(100) := 'YYYY/MM/DD HH24:MI:SS';
    /* 2009.07.16 K.Satomura 0000070�Ή� END */
    --
    -- *** ���[�J���ϐ� ***
    /* 2009.07.16 K.Satomura 0000070�Ή� START */
    lt_task_status_id jtf_task_statuses_b.task_status_id%TYPE; -- �^�X�N�X�e�[�^�X�h�c
    /* 2009.07.16 K.Satomura 0000070�Ή� END */
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    /* 2009.07.16 K.Satomura 0000070�Ή� START */
    IF (g_visit_data_rec.visit_date > TO_DATE(TO_CHAR(SYSDATE, cv_visit_date_fmt1), cv_visit_date_fmt2)) THEN
      -- �K������������̏ꍇ�́A�^�X�N�X�e�[�^�X�̓I�[�v���œo�^����B
      lt_task_status_id := TO_NUMBER(fnd_profile.value(ct_task_status_open));
      --
    ELSE
      lt_task_status_id := NULL;
      --
    END IF;
    --
    /* 2009.07.16 K.Satomura 0000070�Ή� END */
    -- =======================
    -- �K����уf�[�^�X�V 
    -- =======================
    xxcso_task_common_pkg.update_task(
       in_task_id                         -- �^�X�NID
      ,g_visit_data_rec.resource_id       -- ���\�[�XID
      ,g_visit_data_rec.party_id          -- �p�[�e�BID
      ,g_visit_data_rec.party_name        -- �p�[�e�B����
      ,g_visit_data_rec.visit_date        -- �K�����
      ,g_visit_data_rec.description       -- �ڍד��e
      ,in_obj_ver_num
      /* 2009.07.16 K.Satomura 0000070�Ή� START */
      ,lt_task_status_id                   -- �^�X�N�X�e�[�^�X�h�c
      /* 2009.07.16 K.Satomura 0000070�Ή� END */
      /* 2009.05.14 K.Satomura T1_0931�Ή� START */
      --,g_visit_data_rec.dff1_cd            -- �g�̊���
      --,g_visit_data_rec.dff2_cd            -- �̑��t�H���[
      --,g_visit_data_rec.dff3_cd            -- �X������
      --,g_visit_data_rec.dff4_cd            -- �N���[���Ή�
      --,g_visit_data_rec.dff5_cd            -- �����x��
      --,g_visit_data_rec.dff6_cd            -- �����`�F�b�N�i�����j
      --,g_visit_data_rec.dff7_cd            -- �����`�F�b�N�i��؁j
      --,g_visit_data_rec.dff8_cd            -- �����`�F�b�N�i���̑��j
      --,g_visit_data_rec.dff9_cd            -- �����`�F�b�N�i���[�t�j
      --,g_visit_data_rec.dff10_cd           -- �����`�F�b�N�i�`���h�j
-- Ver1.10 MOD Start comment update only
      ,g_visit_data_rec.dff_cd_table(1)      -- �����敪1
      ,g_visit_data_rec.dff_cd_table(2)      -- �����敪2
      ,g_visit_data_rec.dff_cd_table(3)      -- �����敪3
      ,g_visit_data_rec.dff_cd_table(4)      -- �����敪4
      ,g_visit_data_rec.dff_cd_table(5)      -- �����敪5
      ,g_visit_data_rec.dff_cd_table(6)      -- �����敪6
      ,g_visit_data_rec.dff_cd_table(7)      -- �����敪7
      ,g_visit_data_rec.dff_cd_table(8)      -- �����敪8
      ,g_visit_data_rec.dff_cd_table(9)      -- �����敪9
      ,g_visit_data_rec.dff_cd_table(10)     -- �����敪10
-- Ver1.10 MOD End comment update only
      /* 2009.05.14 K.Satomura T1_0931�Ή� END */
      ,'0'
      ,'2'
      ,NULL
/* 2009.09.08 D.Abe 0001312�Ή� START */
      --,gt_customer_status
      ,g_visit_data_rec.customer_status
/* 2009.09.08 D.Abe 0001312�Ή� END */
      ,lv_errbuf
      ,lv_retcode
      ,lv_errmsg
    );
    -- ����ł͂Ȃ��ꍇ
    IF (lv_retcode <> cv_status_normal) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_11             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_tbl                   -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_task_table_nm             -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_base_val              -- �g�[�N���R�[�h2
                     ,iv_token_value2 => iv_base_value                -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_process               -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_update_process            -- �g�[�N���l3
                     ,iv_token_name4  => cv_tkn_err_msg               -- �g�[�N���R�[�h4
                     ,iv_token_value4 => lv_errmsg                    -- �g�[�N���l4
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_skip_error_expt;
    END IF;
--
  EXCEPTION
    -- *** �X�L�b�v��O�n���h�� ***
    WHEN global_skip_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END update_visit_data;
--
  /**********************************************************************************
   * Procedure Name   : delete_if_data
   * Description      : �t�@�C���f�[�^�폜���� (A-11)
   ***********************************************************************************/
--
  PROCEDURE delete_if_data(
     ov_errbuf            OUT NOCOPY VARCHAR2             -- �G���[�E���b�Z�[�W            -- # �Œ� #
    ,ov_retcode           OUT NOCOPY VARCHAR2             -- ���^�[���E�R�[�h              -- # �Œ� #
    ,ov_errmsg            OUT NOCOPY VARCHAR2             -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'delete_if_data';     -- �v���O������
--
-- #####################  �Œ胍�[�J���ϐ��錾�� START     #########################
--
    lv_errbuf            VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode           VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg            VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
-- #####################  �Œ胍�[�J���ϐ��錾�� END       #########################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_if_table_nm       CONSTANT VARCHAR2(100)  := '�t�@�C���A�b�v���[�hI/F�e�[�u��';
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    BEGIN
--
      -- �t�@�C���f�[�^�폜
      DELETE FROM   xxccp_mrp_file_ul_interface xmfui
      WHERE  xmfui.file_id = gt_file_id;
--
      -- ���O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '' || CHR(10) || cv_debug_msg19 || CHR(10) || cv_debug_msg15 || CHR(10)
      );
--
    EXCEPTION
      -- �폜�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                        -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_12                   -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl                         -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_if_table_nm                     -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_file_id                     -- �g�[�N���R�[�h2
                       ,iv_token_value2 => TO_CHAR(gt_file_id)                -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_err_msg                     -- �g�[�N���R�[�h2
                       ,iv_token_value3 => SQLERRM                            -- �g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;                                                    -- # �C�� #
    END;
--
  EXCEPTION
    -- *** ������O�n���h�� ***
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
  END delete_if_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   ***********************************************************************************/
--
  PROCEDURE submain(
     ov_errbuf           OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W            -- # �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h              -- # �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'submain';     -- �v���O������
--
-- #####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf      VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode     VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_sub_retcode VARCHAR2(1);     -- �T�[�u���^�[���E�R�[�h
    lv_errmsg      VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
-- ###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cn_visit_data_start     CONSTANT NUMBER := 3;   -- 3���ڂ�����ۂ̖K����уf�[�^
--
    -- *** ���[�J���ϐ� ***
    lv_base_value           VARCHAR2(5000);         -- ���Y�s�f�[�^
    lv_dummy_acc_num        VARCHAR2(30);           -- �_�~�[�ڋq�R�[�h
    ln_task_id              NUMBER;                 -- �^�X�N�h�c
    ln_obj_ver_num          NUMBER;                 -- �I�u�W�F�N�g�o�[�W�����ԍ�
    ln_task_count           NUMBER;                 -- ���o����
--
    -- *** ���[�J����O ***
--
  BEGIN
--
-- ##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
-- ###########################  �Œ蕔 END   ############################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
    -- ================================
    -- A-1.�������� 
    -- ================================
    init(
       ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W            -- # �Œ� #
      ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h              -- # �Œ� #
      ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-2.�v���t�@�C���l�擾 
    -- ========================================
    get_profile_info(
       ov_dummy_acc_num => lv_dummy_acc_num -- �_�~�[�ڋq�R�[�h
      ,ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W            -- # �Œ� #
      ,ov_retcode       => lv_retcode       -- ���^�[���E�R�[�h              -- # �Œ� #
      ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-3.�K����уf�[�^���o���� 
    -- ========================================
    get_visit_data(
       ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W            -- # �Œ� #
      ,ov_retcode       => lv_retcode       -- ���^�[���E�R�[�h              -- # �Œ� #
      ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- A-3�Œ��o�����t�@�C���f�[�^�T�C�Y��4���ȏ�̏ꍇ
    IF (g_file_data_tab.COUNT >= (cn_visit_data_start + 1)) THEN
      -- ==================================================
      -- A-4.�o�^�iA-8�j�A�X�V�iA-9�j�����ŕK�v�ȃf�[�^�擾 
      -- ==================================================
      get_inupd_data(
         iv_dummy_acc_num => lv_dummy_acc_num -- �_�~�[�ڋq�R�[�h
        ,ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W            -- # �Œ� #
        ,ov_retcode       => lv_retcode       -- ���^�[���E�R�[�h              -- # �Œ� #
        ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- �t�@�C���f�[�^���[�v(�Ō�̍s�͍��v�̂��߁u�Ō�̍s-1�v�܂�)
      <<get_visit_data_loop>>
      FOR i IN cn_visit_data_start..(g_file_data_tab.COUNT - 1) LOOP
--
        BEGIN
--
          -- ���R�[�h�N���A
          g_visit_data_rec := NULL;
--
          -- �Ώی����J�E���g
          gn_target_cnt := gn_target_cnt + 1;
--
          lv_base_value := g_file_data_tab(i);
--
          -- =================================================
          -- A-5.�f�[�^�Ó����`�F�b�N (���R�[�h�Ƀf�[�^�Z�b�g)
          -- =================================================
          data_proper_check(
             iv_base_value    => lv_base_value    -- ���Y�s�f�[�^
            ,ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W            -- # �Œ� #
            ,ov_retcode       => lv_sub_retcode   -- ���^�[���E�R�[�h              -- # �Œ� #
            ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
          );
          IF (lv_sub_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          ELSIF (lv_sub_retcode = cv_status_warn) THEN
            RAISE global_skip_error_expt;
          END IF;
--
          -- =============================
          -- A-6.�}�X�^���݃`�F�b�N 
          -- =============================
          chk_mst_is_exists(
             iv_base_value    => lv_base_value    -- ���Y�s�f�[�^
            ,ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W            -- # �Œ� #
            ,ov_retcode       => lv_sub_retcode   -- ���^�[���E�R�[�h              -- # �Œ� #
            ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
          );
          IF (lv_sub_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          ELSIF (lv_sub_retcode = cv_status_warn) THEN
            RAISE global_skip_error_expt;
          END IF;
--
          -- =============================
          -- A-7.����K����уf�[�^���o 
          -- =============================
          -- ���o�������N���A
          ln_task_count := 0;
--
          get_visit_same_data(
             on_task_id       => ln_task_id       -- �^�X�N�h�c
            ,on_obj_ver_num   => ln_obj_ver_num   -- �I�u�W�F�N�g�o�[�W�����ԍ�
            ,on_task_count    => ln_task_count    -- ���o����
            ,iv_base_value    => lv_base_value    -- ���Y�s�f�[�^
            ,ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W            -- # �Œ� #
            ,ov_retcode       => lv_sub_retcode   -- ���^�[���E�R�[�h              -- # �Œ� #
            ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
          );
          IF (lv_sub_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          ELSIF (lv_sub_retcode = cv_status_warn) THEN
            RAISE global_skip_error_expt;
          END IF;
--
          -- A-10.SAVEPOINT���s
          SAVEPOINT visit;
--
          IF (ln_task_count = 0) THEN
            -- =============================
            -- A-8.�K����уf�[�^�o�^ 
            -- =============================
            insert_visit_data(
               iv_base_value    => lv_base_value    -- ���Y�s�f�[�^
              ,ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W            -- # �Œ� #
              ,ov_retcode       => lv_sub_retcode   -- ���^�[���E�R�[�h              -- # �Œ� #
              ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
            );
            IF (lv_sub_retcode = cv_status_error) THEN
              gb_task_inup_rollback_flag := TRUE;
              RAISE global_process_expt;
            ELSIF (lv_sub_retcode = cv_status_warn) THEN
              gb_task_inup_rollback_flag := TRUE;
              RAISE global_skip_error_expt;
            END IF;
          ELSE
            -- =============================
            -- A-9.�K����уf�[�^�X�V 
            -- =============================
            update_visit_data(
               in_task_id       => ln_task_id       -- �^�X�N�h�c
              ,in_obj_ver_num   => ln_obj_ver_num   -- �I�u�W�F�N�g�o�[�W�����ԍ�
              ,iv_base_value    => lv_base_value    -- ���Y�s�f�[�^
              ,ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W            -- # �Œ� #
              ,ov_retcode       => lv_sub_retcode   -- ���^�[���E�R�[�h              -- # �Œ� #
              ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
            );
            IF (lv_sub_retcode = cv_status_error) THEN
              gb_task_inup_rollback_flag := TRUE;
              RAISE global_process_expt;
            ELSIF (lv_sub_retcode = cv_status_warn) THEN
              gb_task_inup_rollback_flag := TRUE;
              RAISE global_skip_error_expt;
            END IF;
          END IF;
          -- ���������J�E���g
          gn_normal_cnt := gn_normal_cnt + 1;
--
        EXCEPTION
          -- *** �X�L�b�v��O�n���h�� ***
          WHEN global_skip_error_expt THEN
            gn_error_cnt := gn_error_cnt + 1;       -- �G���[�����J�E���g
            lv_retcode := cv_status_warn;
--
            -- ���b�Z�[�W�o��
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg                  -- ���[�U�[�E�G���[���b�Z�[�W
            );
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => cv_pkg_name||cv_msg_cont||
                         cv_prg_name||cv_msg_part||
                         lv_errbuf                  -- �G���[���b�Z�[�W
            );
--
            -- ���[���o�b�N
            IF gb_task_inup_rollback_flag = TRUE THEN
              ROLLBACK TO SAVEPOINT visit;          -- ROLLBACK
              gb_task_inup_rollback_flag := FALSE;
              -- ���O�o��
              fnd_file.put_line(
                 which  => FND_FILE.LOG
                ,buff   => CHR(10) ||cv_debug_msg22|| CHR(10)
              );
            END IF;
--        
          -- *** �X�L�b�v��OOTHERS�n���h�� ***
          WHEN OTHERS THEN
            gn_error_cnt := gn_error_cnt + 1;       -- �G���[�����J�E���g
            lv_retcode := cv_status_warn;
--
            -- ���O�o��
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => cv_pkg_name||cv_msg_cont||
                         cv_prg_name||cv_msg_part||
                         lv_errbuf                  -- �G���[���b�Z�[�W
            );
--
            -- ���[���o�b�N
            IF gb_task_inup_rollback_flag = TRUE THEN
              ROLLBACK TO SAVEPOINT visit;          -- ROLLBACK
              gb_task_inup_rollback_flag := FALSE;
              -- ���O�o��
              fnd_file.put_line(
                 which  => FND_FILE.LOG
                ,buff   => CHR(10) ||cv_debug_msg22|| CHR(10)
              );
            END IF;
--
          END;
      END LOOP get_visit_data_loop;
--
      ov_retcode := lv_retcode;                -- ���^�[���E�R�[�h
    END IF;
--
    -- =============================
    -- A-11.�t�@�C���f�[�^�폜���� 
    -- =============================
    delete_if_data(
       ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W            -- # �Œ� #
      ,ov_retcode       => lv_retcode       -- ���^�[���E�R�[�h              -- # �Œ� #
      ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
-- #################################  �Œ��O������ START   ####################################
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
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
     errbuf        OUT NOCOPY VARCHAR2          -- �G���[�E���b�Z�[�W  -- # �Œ� #
    ,retcode       OUT NOCOPY VARCHAR2          -- ���^�[���E�R�[�h    -- # �Œ� #
    ,in_file_id    IN         NUMBER            -- �t�@�C��ID
    ,iv_fmt_ptn    IN         VARCHAR2          -- �t�H�[�}�b�g�p�^�[��
  )    
--
-- ###########################  �Œ蕔 START   ###########################
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
-- ###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
-- ###########################  �Œ蕔 END   #############################
--
    -- *** ���̓p�����[�^���Z�b�g
    gt_file_id := in_file_id;
    gv_fmt_ptn := iv_fmt_ptn;
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       ov_errbuf   => lv_errbuf          -- �G���[�E���b�Z�[�W            -- # �Œ� #
      ,ov_retcode  => lv_retcode         -- ���^�[���E�R�[�h              -- # �Œ� #
      ,ov_errmsg   => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
       --�G���[�o��
       fnd_file.put_line(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg                  -- ���[�U�[�E�G���[���b�Z�[�W
       );
       fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf    -- �G���[���b�Z�[�W
       );
    END IF;
--
    -- =======================
    -- A-12.�I������ 
    -- =======================
    -- ��s�̏o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''               -- ��s
    );
    -- �Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- ���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- �G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- �I�����b�Z�[�W
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
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- �X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    -- �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
END XXCSO006A02C;
/
