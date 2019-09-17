CREATE OR REPLACE PACKAGE BODY XXCFR003A18C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR003A18C(body)
 * Description      : �W���������ō�(�X�ܕʓ���)
 * MD.050           : MD050_CFR_003_A18_�W���������ō�(�X�ܕʓ���)
 * MD.070           : MD050_CFR_003_A18_�W���������ō�(�X�ܕʓ���)
 * Version          : 1.93
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   p ��������                                (A-1)
 *  get_profile_value      p �v���t�@�C���擾����                    (A-2)
 *  chk_inv_all_dept       P �S�Џo�͌����`�F�b�N����                (A-3)
 *  put_account_warning    p �ڋq�R�t���x���o��
 *  update_work_table      p ���[�N�e�[�u���f�[�^�X�V                (A-11)
 *  insert_work_table      p �Ώیڋq�擾����(A-4)�A���|�Ǘ���ڋq�擾����(A-5)�A���[�N�e�[�u���f�[�^�o�^(A-6))
 *  chk_account_data       p �������擾�`�F�b�N                    (A-7)
 *  start_svf_api          p SVF�N��                                 (A-8)
 *  delete_work_table      p ���[�N�e�[�u���f�[�^�폜                (A-9)
 *  exec_submit_req        p �X�ܕʖ��׏o�͗v�����s����              (A-13)
 *  func_wait_for_request  p �R���J�����g�I���ҋ@����                (A-14)
 *  submain                p ���C�������v���V�[�W��
 *  main                   p �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/09/25    1.00 SCS ���� �q��    ����쐬
 *  2009/11/11    1.10 SCS ���� �q��    ���ʉۑ�uI_E_664�v�Ή�
 *  2010/02/03    1.20 SCS ���� �q��    ��Q�uE_�{�ғ�_01503�v�Ή�
 *  2010/12/10    1.30 SCS �Γn ���a    ��Q�uE_�{�ғ�_05401�v�Ή�
 *  2011/01/17    1.40 SCS �A�� �^���l  ��Q�uE_�{�ғ�_00580�v�Ή�
 *  2011/03/10    1.50 SCS �Γn ���a    ��Q�uE_�{�ғ�_06753�v�Ή�
 *  2013/12/13    1.60 SCSK ���� �O��   ��Q�uE_�{�ғ�_11330�v�Ή�
 *  2014/03/27    1.70 SCSK �R�� �đ�   ��Q�uE_�{�ғ�_11617�v�Ή�
 *  2015/07/31    1.80 SCSK ���H ���O   ��Q�uE_�{�ғ�_12963�v�Ή�
 *  2016/03/31    1.90 SCSK ���H ���O   ��Q�uE_�{�ғ�_13511�v�Ή�
 *  2016/09/06    1.91 SCSK ���H ���O   ��Q�uE_�{�ғ�_13849�v�Ή�
 *  2018/10/25    1.92 SCSK �ޗ� �a�G   ��Q�uE_�{�ғ�_15307�v�Ή�
 *  2019/09/03    1.93 SCSK �K�q �x��   ��Q�uE_�{�ғ�_15472�v�Ή�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- �x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- �ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         -- CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    -- PROGRAM_UPDATE_DATE
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
  cv_msg_pnt                CONSTANT VARCHAR2(3) := ',';
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
  lock_expt             EXCEPTION;      -- ���b�N(�r�W�[)�G���[
  file_not_exists_expt  EXCEPTION;      -- �t�@�C�����݃G���[
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFR003A18C'; -- �p�b�P�[�W��
  cv_msg_kbn_cmn     CONSTANT VARCHAR2(5)   := 'XXCMN';
  cv_msg_kbn_ccp     CONSTANT VARCHAR2(5)   := 'XXCCP';
  cv_msg_kbn_cfr     CONSTANT VARCHAR2(5)   := 'XXCFR';
--
  -- ���b�Z�[�W�ԍ�
  cv_msg_003a18_001  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
  cv_msg_003a18_002  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
  cv_msg_003a18_003  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
  cv_msg_003a18_004  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
  cv_msg_003a18_005  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
  cv_msg_003a18_006  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
  cv_msg_003a18_007  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N���b�Z�[�W
  cv_msg_003a18_008  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90007'; -- �G���[�I���ꕔ�������b�Z�[�W
  cv_msg_003a18_009  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00056'; -- �V�X�e���G���[���b�Z�[�W
--
  cv_msg_003a18_010  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00004'; -- �v���t�@�C���擾�G���[���b�Z�[�W
  cv_msg_003a18_011  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00003'; -- ���b�N�G���[���b�Z�[�W
  cv_msg_003a18_012  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00007'; -- �f�[�^�폜�G���[���b�Z�[�W
  cv_msg_003a18_013  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00016'; -- �e�[�u���}���G���[
  cv_msg_003a18_014  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00023'; -- ���[�O�����b�Z�[�W
  cv_msg_003a18_015  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00011'; -- API�G���[���b�Z�[�W
  cv_msg_003a18_016  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00024'; -- ���[�O�����O���b�Z�[�W
  cv_msg_003a18_017  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00015'; -- �l�擾�G���[���b�Z�[�W
  cv_msg_003a18_018  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00038'; -- �U���������o�^���b�Z�[�W
  cv_msg_003a18_019  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00051'; -- �U���������o�^���
  cv_msg_003a18_020  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00052'; -- �U���������o�^�������b�Z�[�W
  cv_msg_003a18_021  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00010'; -- ���ʊ֐��G���[���b�Z�[�W
  cv_msg_003a18_022  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00079'; -- �������p�ڋq���݂Ȃ����b�Z�[�W
  cv_msg_003a18_023  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00080'; -- ���|�Ǘ���ڋq���݂Ȃ����b�Z�[�W
  cv_msg_003a18_024  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00082'; -- �����������p�ڋq���݂Ȃ����b�Z�[�W
  cv_msg_003a18_025  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00081'; -- �ڋq�R�[�h�����w�胁�b�Z�[�W
-- Add 2013.12.13 Ver1.60 Start
  cv_msg_003a18_026  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00017'; -- �e�[�u���X�V�G���[
-- Add 2013.12.13 Ver1.60 End
-- Add 2015.07.31 Ver1.80 Start
  cv_msg_003a18_027  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00153'; -- �������^�C�v��`�Ȃ��G���[���b�Z�[�W
  cv_msg_003a18_028  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00154'; -- �R���J�����g�N���G���[
  cv_msg_003a18_029  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00155'; -- �R���J�����g�ҋ@���Ԍo�߃G���[
  cv_msg_003a18_030  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00156'; -- �R���J�����g�ҋ@���탁�b�Z�[�W
  cv_msg_003a18_031  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00157'; -- �R���J�����g�ҋ@�x�����b�Z�[�W
  cv_msg_003a18_032  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00158'; -- �R���J�����g�ҋ@�G���[���b�Z�[�W
-- Add 2015.07.31 Ver1.80 End
--
-- �g�[�N��
  cv_tkn_prof        CONSTANT VARCHAR2(15) := 'PROF_NAME';        -- �v���t�@�C����
  cv_tkn_api         CONSTANT VARCHAR2(15) := 'API_NAME';         -- API��
  cv_tkn_table       CONSTANT VARCHAR2(15) := 'TABLE';            -- �e�[�u����
  cv_tkn_comment     CONSTANT VARCHAR2(15) := 'COMMENT';          -- �R�����g
  cv_tkn_get_data    CONSTANT VARCHAR2(30) := 'DATA';             -- �擾�Ώۃf�[�^
  cv_tkn_ac_code     CONSTANT VARCHAR2(30) := 'ACCOUNT_CODE';     -- �ڋq�R�[�h
  cv_tkn_ac_name     CONSTANT VARCHAR2(30) := 'ACCOUNT_NAME';     -- �ڋq��
  cv_tkn_lc_name     CONSTANT VARCHAR2(30) := 'KYOTEN_NAME';      -- ���_��
  cv_tkn_count       CONSTANT VARCHAR2(30) := 'COUNT';            -- �J�E���g��
  cv_tkn_func        CONSTANT VARCHAR2(15) := 'FUNC_NAME';        -- ���ʊ֐���
-- Add 2015.07.31 Ver1.80 Start
  cv_tkn_lookup_type CONSTANT VARCHAR2(15) := 'LOOKUP_TYPE';      -- �Q�ƃ^�C�v
  cv_tkn_lookup_code CONSTANT VARCHAR2(15) := 'LOOKUP_CODE';      -- �R�[�h
  cv_tkn_request_id  CONSTANT VARCHAR2(15) := 'REQUEST_ID';       -- ���N�G�X�gID
  cv_tkn_conc        CONSTANT VARCHAR2(15) := 'CONC_NAME';        -- �R���J�����g��
-- Add 2015.07.31 Ver1.80 End
--
  -- ���{�ꎫ��
  cv_dict_date       CONSTANT VARCHAR2(100) := 'CFR000A00003';    -- ���t�p�����[�^�ϊ��֐�
  cv_dict_svf        CONSTANT VARCHAR2(100) := 'CFR000A00004';    -- SVF�N��
--
  cv_dict_ymd4       CONSTANT VARCHAR2(100) := 'CFR000A00007';    -- YYYY"�N"MM"��"DD"��"
  cv_dict_ymd2       CONSTANT VARCHAR2(100) := 'CFR000A00008';    -- YY"�N"MM"��"DD"��"
  cv_dict_year       CONSTANT VARCHAR2(100) := 'CFR000A00009';    -- �N
  cv_dict_month      CONSTANT VARCHAR2(100) := 'CFR000A00010';    -- ��
  cv_dict_bank       CONSTANT VARCHAR2(100) := 'CFR000A00011';    -- ��s
  cv_dict_central    CONSTANT VARCHAR2(100) := 'CFR000A00015';    -- �{�X
  cv_dict_branch     CONSTANT VARCHAR2(100) := 'CFR000A00012';    -- �x�X
  cv_dict_account    CONSTANT VARCHAR2(100) := 'CFR000A00013';    -- ����
  cv_dict_current    CONSTANT VARCHAR2(100) := 'CFR000A00014';    -- ����
  cv_dict_zip_mark   CONSTANT VARCHAR2(100) := 'CFR000A00016';    -- ��
  cv_dict_bank_damy  CONSTANT VARCHAR2(100) := 'CFR000A00017';    -- ��s�_�~�[�R�[�h
  cv_dict_date_func  CONSTANT VARCHAR2(100) := 'CFR000A00002';    -- �c�Ɠ��t�擾�֐�
--
  --�v���t�@�C��
  cv_set_of_bks_id   CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_ID'; -- ��v����ID
  cv_org_id          CONSTANT VARCHAR2(30) := 'ORG_ID';           -- �g�DID
-- Add 2015.07.31 Ver1.80 Start
  cv_interval        CONSTANT VARCHAR2(30) := 'XXCFR1_INTERVAL';  -- XXCFR:�ҋ@�Ԋu
  cv_max_wait        CONSTANT VARCHAR2(30) := 'XXCFR1_MAX_WAIT';  -- XXCFR:�ő�ҋ@����
-- Add 2015.07.31 Ver1.80 End
--
  -- �g�pDB��
  cv_table           CONSTANT VARCHAR2(100) := 'XXCFR_REP_ST_INVOICE_INC_TAX_D';  -- ���[�N�e�[�u����
-- Add 2015.07.31 Ver1.80 Start
  cv_table_a_h       CONSTANT VARCHAR2(100) := 'XXCFR_REP_ST_INV_INC_TAX_A_H';    -- �W���������ō����[�������P��A���[�N�e�[�u���w�b�_��
  cv_table_a_l       CONSTANT VARCHAR2(100) := 'XXCFR_REP_ST_INV_INC_TAX_A_L';    -- �W���������ō����[�������P��A���[�N�e�[�u�����ז�
  cv_table_b_h       CONSTANT VARCHAR2(100) := 'XXCFR_REP_ST_INV_INC_TAX_B_H';    -- �W���������ō����[�������P��B���[�N�e�[�u���w�b�_��
  cv_table_b_l       CONSTANT VARCHAR2(100) := 'XXCFR_REP_ST_INV_INC_TAX_B_L';    -- �W���������ō����[�������P��B���[�N�e�[�u�����ז�
-- Add 2015.07.31 Ver1.80 End
-- Add 2016.03.31 Ver1.90 Start
  cv_table_c_h       CONSTANT VARCHAR2(100) := 'XXCFR_REP_ST_INV_INC_TAX_C_H';    -- �W���������ō����[�������P��C���[�N�e�[�u���w�b�_��
  cv_table_c_l       CONSTANT VARCHAR2(100) := 'XXCFR_REP_ST_INV_INC_TAX_C_L';    -- �W���������ō����[�������P��C���[�N�e�[�u�����ז�
-- Add 2016.03.31 Ver1.90 End
-- Ver.1.92 [��QE_�{�ғ�_15307] ADD START
  cv_table_d_h       CONSTANT VARCHAR2(100) := 'XXCFR_REP_ST_INV_D_H';            -- �W�����������[�������P��D���[�N�e�[�u���w�b�_��
  cv_table_d_l       CONSTANT VARCHAR2(100) := 'XXCFR_REP_ST_INV_INC_TAX_D_L';    -- �W���������ō����[�������P��D���[�N�e�[�u�����ז�
-- Ver.1.92 [��QE_�{�ғ�_15307] ADD END
--
  -- �������^�C�v
  cv_invoice_type    CONSTANT VARCHAR2(1)   := 'S';                        -- �eS�f(�W��������)
--
  -- �t�@�C���o��
  cv_file_type_out   CONSTANT VARCHAR2(10)  := 'OUTPUT';    -- ���b�Z�[�W�o��
  cv_file_type_log   CONSTANT VARCHAR2(10)  := 'LOG';       -- ���O�o��
--
  cv_enabled_yes     CONSTANT VARCHAR2(1)   := 'Y';         -- �L���t���O�i�x�j
--
  cv_status_yes      CONSTANT VARCHAR2(1)   := '1';         -- �L���X�e�[�^�X�i1�F�L���j
  cv_status_no       CONSTANT VARCHAR2(1)   := '0';         -- �L���X�e�[�^�X�i0�F�����j
--
-- Add 2015.07.31 Ver1.80 Start
  cv_taget_flag_0    CONSTANT VARCHAR2(1)   := '0';               -- ����0���t���O�i0�F�Ώیڋq�Ȃ��j
  cv_taget_flag_1    CONSTANT VARCHAR2(1)   := '1';               -- ����0���t���O�i1�F�Ώۃf�[�^�Ȃ��j
  cv_taget_flag_2    CONSTANT VARCHAR2(1)   := '2';               -- ����0���t���O�i2�F�Ώۃf�[�^����j
--
  -- �X�ܕʖ��ג��[ID
-- Ver.1.92 [��QE_�{�ғ�_15307] MOD START
--  cv_report_id_01    CONSTANT VARCHAR2(14)  := 'XXCFR003A2001C';  -- �������i14�ڋq���v_�X�ܕʈꗗ�j�ō�
--  cv_report_id_02    CONSTANT VARCHAR2(14)  := 'XXCFR003A2002C';  -- �X�ܕʖ��ׁi�X�ܕʉ��y�[�W�j�ō�
--  cv_report_id_03    CONSTANT VARCHAR2(14)  := 'XXCFR003A2003C';  -- ���������\�i14�ڋq���v�j�ō�
--  cv_report_id_04    CONSTANT VARCHAR2(14)  := 'XXCFR003A2004C';  -- �������i�X�ܕʉ��y�[�W�j�ō�
---- Add 2016.03.31 Ver1.90 Start
--  cv_report_id_09    CONSTANT VARCHAR2(14)  := 'XXCFR003A2009C';  -- �������i14�ڋq���v_�X�ܕʈꗗ�j�ō�
--  cv_report_id_10    CONSTANT VARCHAR2(14)  := 'XXCFR003A2010C';  -- �`�[�ʖ��אō�
---- Add 2016.03.31 Ver1.90 End
  cv_report_id_01    CONSTANT VARCHAR2(14)  := 'XXCFR003A2001C';  -- ������A�ō��w�b�_
  cv_report_id_02    CONSTANT VARCHAR2(14)  := 'XXCFR003A2002C';  -- ������A�ō�����
  cv_report_id_03    CONSTANT VARCHAR2(14)  := 'XXCFR003A2003C';  -- ������B�ō��w�b�_
  cv_report_id_04    CONSTANT VARCHAR2(14)  := 'XXCFR003A2004C';  -- ������B�ō�����
  cv_report_id_09    CONSTANT VARCHAR2(14)  := 'XXCFR003A2009C';  -- ������C�ō��w�b�_
  cv_report_id_10    CONSTANT VARCHAR2(14)  := 'XXCFR003A2010C';  -- ������C�ō�����
-- Ver.1.92 [��QE_�{�ғ�_15307] MOD END
-- Ver.1.92 [��QE_�{�ғ�_15307] ADD START
  cv_report_id_13    CONSTANT VARCHAR2(14)  := 'XXCFR003A2013C';  -- ������D�w�b�_
  cv_report_id_14    CONSTANT VARCHAR2(14)  := 'XXCFR003A2014C';  -- ������D�ō�����
-- Ver.1.92 [��QE_�{�ғ�_15307] ADD END
--
  -- �X�ܕʖ��ׂ̐������^�C�v
-- Ver.1.92 [��QE_�{�ғ�_15307] MOD START
--  cv_bill_type_01    CONSTANT VARCHAR2(2)   := '01';              -- �������i14�ڋq���v_�X�ܕʈꗗ�j�ō�
--  cv_bill_type_02    CONSTANT VARCHAR2(2)   := '02';              -- �X�ܕʖ��ׁi�X�ܕʉ��y�[�W�j�ō�
--  cv_bill_type_03    CONSTANT VARCHAR2(2)   := '03';              -- ���������\�i14�ڋq���v�j�ō�
--  cv_bill_type_04    CONSTANT VARCHAR2(2)   := '04';              -- �������i�X�ܕʉ��y�[�W�j�ō�
---- Add 2016.03.31 Ver1.90 Start
--  cv_bill_type_09    CONSTANT VARCHAR2(2)   := '09';              -- �������i14�ڋq���v_�X�ܕʈꗗ�j�ō�
--  cv_bill_type_10    CONSTANT VARCHAR2(2)   := '10';              -- �`�[�ʖ��אō�
---- Add 2016.03.31 Ver1.90 End
  cv_bill_type_01    CONSTANT VARCHAR2(2)   := '01';              -- ������A�ō��w�b�_
  cv_bill_type_02    CONSTANT VARCHAR2(2)   := '02';              -- ������A�ō�����
  cv_bill_type_03    CONSTANT VARCHAR2(2)   := '03';              -- ������B�ō��w�b�_
  cv_bill_type_04    CONSTANT VARCHAR2(2)   := '04';              -- ������B�ō�����
  cv_bill_type_09    CONSTANT VARCHAR2(2)   := '09';              -- ������C�ō��w�b�_
  cv_bill_type_10    CONSTANT VARCHAR2(2)   := '10';              -- ������C�ō�����
-- Ver.1.92 [��QE_�{�ғ�_15307] MOD END
-- Ver.1.92 [��QE_�{�ғ�_15307] ADD START
  cv_bill_type_13    CONSTANT VARCHAR2(2)   := '13';              -- ������D�w�b�_
  cv_bill_type_14    CONSTANT VARCHAR2(2)   := '14';              -- ������D�ō�����
-- Ver.1.92 [��QE_�{�ғ�_15307] ADD END
--
  -- �R���J�����gdev�X�e�[�^�X
  cv_dev_status_normal  CONSTANT VARCHAR2(6)  := 'NORMAL';  -- '����'
  cv_dev_status_warn    CONSTANT VARCHAR2(7)  := 'WARNING'; -- '�x��'
--
-- Add 2015.07.31 Ver1.80 End
  cv_format_date_ymd    CONSTANT VARCHAR2(8)  := 'YYYYMMDD';             -- ���t�t�H�[�}�b�g�i�N�����j
  cv_format_date_ymdhns CONSTANT VARCHAR2(16) := 'YYYYMMDDHH24MISS';     -- ���t�t�H�[�}�b�g�i�N���������b
  cv_format_date_ymds   CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';           -- ���t�t�H�[�}�b�g�i�N�����X���b�V���t�j
  cv_format_date_ymds2  CONSTANT VARCHAR2(8)  := 'YY/MM/DD';             -- ���t�t�H�[�}�b�g�i2���N�����X���b�V���t�j
--
  cd_max_date           CONSTANT DATE         := TO_DATE('9999/12/31',cv_format_date_ymds);
--
  -- �ڋq�敪
  cv_customer_class_code14 CONSTANT VARCHAR2(2) := '14';      -- �ڋq�敪14(���|�Ǘ���)
  cv_customer_class_code21 CONSTANT VARCHAR2(2) := '21';      -- �ڋq�敪21(�����������p)
  cv_customer_class_code20 CONSTANT VARCHAR2(2) := '20';      -- �ڋq�敪20(�������p)
  cv_customer_class_code10 CONSTANT VARCHAR2(2) := '10';      -- �ڋq�敪10(�ڋq)
--
  -- ����������P��
  cv_invoice_printing_unit_a1 CONSTANT VARCHAR2(2) := '9';    -- ����������P��:'A1'
  cv_invoice_printing_unit_a2 CONSTANT VARCHAR2(2) := '8';    -- ����������P��:'A2'
  cv_invoice_printing_unit_a3 CONSTANT VARCHAR2(2) := '6';    -- ����������P��:'A3'
  cv_invoice_printing_unit_a4 CONSTANT VARCHAR2(2) := '7';    -- ����������P��:'A4'
  cv_invoice_printing_unit_a5 CONSTANT VARCHAR2(2) := '5';    -- ����������P��:'A5'
  cv_invoice_printing_unit_a6 CONSTANT VARCHAR2(2) := '4';    -- ����������P��:'A6'
-- Add 2015.07.31 Ver1.80 Start
  cv_invoice_printing_unit_a7 CONSTANT VARCHAR2(2) := 'A';    -- ����������P��:'A7'
  cv_invoice_printing_unit_a8 CONSTANT VARCHAR2(2) := 'B';    -- ����������P��:'A8'
-- Add 2015.07.31 Ver1.80 End
-- Add 2016.03.31 Ver1.90 Start
  cv_invoice_printing_unit_a9 CONSTANT VARCHAR2(2) := 'C';    -- ����������P��:'A9'
-- Add 2016.03.31 Ver1.90 End
-- Ver.1.92 [��QE_�{�ғ�_15307] ADD START
  cv_invoice_printing_unit_a10  CONSTANT VARCHAR2(2) := 'D';  -- ����������P��:'A10'
-- Ver.1.92 [��QE_�{�ғ�_15307] ADD END
--
  -- �g�p�ړI
  cv_site_use_code_bill_to CONSTANT VARCHAR(10) := 'BILL_TO';  -- �g�p�ړI�F�u������v
-- Add 2010-02-03 Ver1.20 Start
  cv_site_use_stat_act     CONSTANT VARCHAR2(1) := 'A';        -- �g�p�ړI�X�e�[�^�X�F�L��
-- Add 2010-02-03 Ver1.20 End
--
  -- �ڋq�֘A�����ΏۃX�e�[�^�X
  cv_acct_relate_status    CONSTANT VARCHAR2(1) := 'A';
--
  -- �ڋq�֘A
  cv_acct_relate_type_bill CONSTANT VARCHAR2(1) := '1';     -- �����֘A
--
  -- AFF����l�Z�b�g��
  cv_ffv_set_name_dept CONSTANT VARCHAR2(100) := 'XX03_DEPARTMENT';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
-- Add 2015.07.31 Ver1.80 Start
  -- �X�ܕʖ��׏o�͗v��ID
  TYPE g_org_request_rtype IS RECORD(
    request_id                    fnd_concurrent_requests.request_id%TYPE
-- Ver.1.92 [��QE_�{�ғ�_15307] ADD START
   ,conc_name                     fnd_lookup_values_vl.attribute1%TYPE
-- Ver.1.92 [��QE_�{�ғ�_15307] ADD END
  );
  TYPE g_org_request_ttype IS TABLE OF g_org_request_rtype INDEX BY PLS_INTEGER;
  g_org_request  g_org_request_ttype;
--
-- Add 2015.07.31 Ver1.80 End
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  gd_target_date        DATE;                                      -- �p�����[�^�D�����i�f�[�^�^�ϊ��p�j
  gn_org_id             NUMBER;                                    -- �g�DID
  gn_set_of_bks_id      NUMBER;                                    -- ��v����ID
  gt_user_dept          per_all_people_f.attribute28%TYPE := NULL; -- ���O�C�����[�U��������
  gv_inv_all_flag       VARCHAR2(1) := '0';                        -- �S�Џo�͌�����������t���O
  gv_warning_flag       VARCHAR2(1) := cv_status_no;               -- �ڋq�R�t���x�����݃t���O
-- Add 2015.07.31 Ver1.80 Start
  gn_interval           NUMBER;                                    -- �ҋ@�Ԋu
  gn_max_wait           NUMBER;                                    -- �ő�ҋ@����
  gv_target_a_flag      VARCHAR2(1) := '0';                        -- ����0���t���OA
  gv_target_b_flag      VARCHAR2(1) := '0';                        -- ����0���t���OB
-- Add 2016.03.31 Ver1.90 Start
  gv_target_c_flag      VARCHAR2(1) := '0';                        -- ����0���t���OC
-- Add 2016.03.31 Ver1.90 End
-- Ver.1.92 [��QE_�{�ғ�_15307] ADD START
  gv_target_d_flag      VARCHAR2(1) := '0';                        -- ����0���t���OD
-- Ver.1.92 [��QE_�{�ғ�_15307] ADD END
  gn_target_cnt_a_h     NUMBER      := 0;                          -- ����P��A�w�b�_�[�̑Ώی���
  gn_target_cnt_a_l     NUMBER      := 0;                          -- ����P��A���ׂ̑Ώی���
  gn_target_cnt_b_h     NUMBER      := 0;                          -- ����P��B�w�b�_�[�̑Ώی���
  gn_target_cnt_b_l     NUMBER      := 0;                          -- ����P��B���ׂ̑Ώی���
-- Add 2016.03.31 Ver1.90 Start
  gn_target_cnt_c_h     NUMBER      := 0;                          -- ����P��C�w�b�_�[�̑Ώی���
  gn_target_cnt_c_l     NUMBER      := 0;                          -- ����P��C���ׂ̑Ώی���
-- Add 2016.03.31 Ver1.90 End
-- Ver.1.92 [��QE_�{�ғ�_15307] ADD START
  gn_target_cnt_d_h     NUMBER      := 0;                          -- ����P��D�w�b�_�[�̑Ώی���
  gn_target_cnt_d_l     NUMBER      := 0;                          -- ����P��D���ׂ̑Ώی���
-- Ver.1.92 [��QE_�{�ғ�_15307] ADD END
  gn_req_cnt            NUMBER;                                    -- �X�ܕʖ��׏o�͗v�����s��
-- Add 2015.07.31 Ver1.80 End
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_target_date         IN      VARCHAR2,         -- ����
    iv_customer_code14     IN      VARCHAR2,         -- ���|�Ǘ���ڋq
    iv_customer_code21     IN      VARCHAR2,         -- �����������p�ڋq
    iv_customer_code20     IN      VARCHAR2,         -- �������p�ڋq
    iv_customer_code10     IN      VARCHAR2,         -- �ڋq
-- Add 2010.12.10 Ver1.30 Start
    iv_bill_pub_cycle      IN      VARCHAR2,         -- ���������s�T�C�N��
-- Add 2010.12.10 Ver1.30 End
-- Add 2013.12.13 Ver1.60 Start
    iv_tax_output_type     IN      VARCHAR2,         -- �ŕʓ���o�͋敪
-- Add 2013.12.13 Ver1.60 End
-- Add 2014.03.27 Ver1.70 Start
    iv_bill_invoice_type   IN      VARCHAR2,         -- �������o�͌`��
-- Add 2014.03.27 Ver1.70 End
    ov_errbuf              OUT     VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode             OUT     VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg              OUT     VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- �v���O������
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
    -- *** ���[�J����O ***
    param_expt EXCEPTION;  -- �ڋq�R�[�h�����w���O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
   ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    --�R���J�����g�p�����[�^�o��
    --==============================================================
--
    -- �p�����[�^�D������DATE�^�ɕϊ�����
    gd_target_date := TRUNC(xxcfr_common_pkg.get_date_param_trans(iv_target_date));
--
    IF (gd_target_date IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_003a18_021 -- ���ʊ֐��G���[
                                                    ,cv_tkn_func       -- �g�[�N��'FUNC_NAME'
                                                    ,xxcfr_common_pkg.lookup_dictionary(cv_msg_kbn_cfr
                                                                                       ,cv_dict_date_func))
                                                    -- �c�Ɠ��t�擾�֐�
                          ,1
                          ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- ���O�o��
    xxcfr_common_pkg.put_log_param( iv_which        => cv_file_type_log             -- ���O�o��
                                   ,iv_conc_param1  => TO_CHAR(gd_target_date
                                                              ,cv_format_date_ymds) -- �R���J�����g�p�����[�^�P
                                   ,iv_conc_param2  => iv_customer_code10           -- �R���J�����g�p�����[�^�Q
                                   ,iv_conc_param3  => iv_customer_code20           -- �R���J�����g�p�����[�^�R
                                   ,iv_conc_param4  => iv_customer_code21           -- �R���J�����g�p�����[�^�S
                                   ,iv_conc_param5  => iv_customer_code14           -- �R���J�����g�p�����[�^�T
-- Add 2010.12.10 Ver1.30 Start
                                   ,iv_conc_param6  => iv_bill_pub_cycle            -- �R���J�����g�p�����[�^�U
-- Add 2010.12.10 Ver1.30 End
-- Add 2013.12.13 Ver1.60 Start
                                   ,iv_conc_param7  => iv_tax_output_type           -- �R���J�����g�p�����[�^�V
-- Add 2013.12.13 Ver1.60 End
-- Add 2014.03.27 Ver1.70 Start
                                   ,iv_conc_param8  => iv_bill_invoice_type         -- �R���J�����g�p�����[�^�W
-- Add 2014.03.27 Ver1.70 End
                                   ,ov_errbuf       => ov_errbuf                    -- �G���[�E���b�Z�[�W
                                   ,ov_retcode      => ov_retcode                   -- ���^�[���E�R�[�h
                                   ,ov_errmsg       => ov_errmsg);                  -- ���[�U�[�E�G���[�E���b�Z�[�W 
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    -- �p�����[�^�ڋq�R�[�h�̎w�萔�`�F�b�N �ڋq�R�[�h�͂P�̂ݎw�肵�Ă��邱�Ƃ��`�F�b�N
    IF (iv_customer_code14 IS NOT NULL) THEN
      IF (iv_customer_code21 IS NOT NULL)
      OR (iv_customer_code20 IS NOT NULL)
      OR (iv_customer_code10 IS NOT NULL)
      THEN
        RAISE param_expt;
      END IF;
    ELSIF (iv_customer_code21 IS NOT NULL) THEN
      IF (iv_customer_code20 IS NOT NULL)
      OR (iv_customer_code10 IS NOT NULL)
      THEN
        RAISE param_expt;
      END IF;
    ELSIF (iv_customer_code20 IS NOT NULL)
    AND   (iv_customer_code10 IS NOT NULL)
    THEN
      RAISE param_expt;
    END IF;
  EXCEPTION
    WHEN param_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfr
                                            ,iv_name         => cv_msg_003a18_025);
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_profile_value
   * Description      : �v���t�@�C���擾����(A-2)
   ***********************************************************************************/
  PROCEDURE get_profile_value(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile_value'; -- �v���O������
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
    -- �v���t�@�C�������v����ID�擾
    gn_set_of_bks_id      := FND_PROFILE.VALUE(cv_set_of_bks_id);
--
    -- �擾�G���[��
    IF (gn_set_of_bks_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_003a18_010 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_set_of_bks_id))
                                                     -- ��v����ID
                          ,1
                          ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- �v���t�@�C������g�DID�擾
    gn_org_id      := FND_PROFILE.VALUE(cv_org_id);
--
    -- �擾�G���[��
    IF (gn_org_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_003a18_010 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_org_id))
                                                     -- �g�DID
                          ,1
                          ,5000);
      RAISE global_api_expt;
    END IF;
-- Add 2015.07.31 Ver1.80 Start
--
    -- �v���t�@�C������ҋ@�Ԋu�擾
    gn_interval := TO_NUMBER(FND_PROFILE.VALUE(cv_interval));
--
    -- �擾�G���[��
    IF (gn_interval IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_003a18_010 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_interval))
                                                     -- �ҋ@�Ԋu
                          ,1
                          ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- �v���t�@�C������ő�ҋ@���Ԏ擾
    gn_max_wait := TO_NUMBER(FND_PROFILE.VALUE(cv_max_wait));
--
    -- �擾�G���[��
    IF (gn_max_wait IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_003a18_010 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_max_wait))
                                                     -- �ő�ҋ@����
                          ,1
                          ,5000);
      RAISE global_api_expt;
    END IF;
-- Add 2015.07.31 Ver1.80 End
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
  END get_profile_value;
--
  /**********************************************************************************
   * Procedure Name   : chk_inv_all_dept
   * Description      : �S�Џo�͌����`�F�b�N���� (A-3)
   ***********************************************************************************/
  PROCEDURE chk_inv_all_dept(
    ov_errbuf           OUT VARCHAR2,   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_inv_all_dept'; -- �v���O������
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
    cv_person_dff_name CONSTANT VARCHAR2(10)  := 'PER_PEOPLE';   -- �]�ƈ��}�X�^DFF��
    cv_peson_dff_att28 CONSTANT VARCHAR2(11)  := 'ATTRIBUTE28';  -- �]�ƈ��}�X�^DFF28(��������)�J������
--
    -- *** ���[�J���ϐ� ***
    lv_token_value fnd_descr_flex_col_usage_vl.end_user_column_name%TYPE; -- ��������擾�G���[���̃��b�Z�[�W�g�[�N���l
    lv_valid_flag  VARCHAR2(1) := 'N'; -- �L���t���O
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J����O ***
    get_user_dept_expt EXCEPTION;  -- ���[�U��������擾��O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���O�C�����[�U��������擾����
    gt_user_dept := xxcfr_common_pkg.get_user_dept(cn_created_by -- ���[�UID
                                                  ,SYSDATE);     -- �擾���t
--
    -- �擾�G���[��
    IF (gt_user_dept IS NULL) THEN
      RAISE get_user_dept_expt;
    END IF;
--
    -- �S�Џo�͌����������唻�菈��
      lv_valid_flag := xxcfr_common_pkg.chk_invoice_all_dept(gt_user_dept      -- ��������R�[�h
                                                            ,cv_invoice_type); -- �������^�C�v
      IF lv_valid_flag = cv_enabled_yes THEN
        gv_inv_all_flag := '1';
      END IF;
--
  EXCEPTION
--
    -- *** �������傪�擾�ł��Ȃ��ꍇ ***
    WHEN get_user_dept_expt THEN
      BEGIN
        SELECT ffcu.end_user_column_name
        INTO lv_token_value
        FROM fnd_descr_flex_col_usage_vl ffcu
        WHERE ffcu.descriptive_flexfield_name = cv_person_dff_name
        AND ffcu.application_column_name = cv_peson_dff_att28;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_003a18_017 -- �l�擾�G���[
                                                    ,cv_tkn_get_data   -- �g�[�N��'DATA'
                                                    ,lv_token_value)   -- '���O�C�����[�U��������'
                          ,1
                          ,5000);
      lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf
                           ,1
                           ,5000);
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
  END chk_inv_all_dept;
--
  /**********************************************************************************
   * Procedure Name   : put_account_warning
   * Description      : �ڋq�R�t���x���o��
   ***********************************************************************************/
  PROCEDURE put_account_warning(
    iv_customer_class_code  IN   VARCHAR2,            -- �ڋq�敪
    iv_customer_code        IN   VARCHAR2,            -- �ڋq�R�[�h
    ov_errbuf               OUT  VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT  VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT  VARCHAR2)            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_account_warning'; -- �v���O������
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
    lv_data_msg  VARCHAR2(5000);        -- ���O�o�̓��b�Z�[�W
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J����O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
    -- ���|�Ǘ���ڋq���݂Ȃ����b�Z�[�W�o��
    IF (iv_customer_class_code = cv_customer_class_code14) THEN
      lv_data_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cfr
                      ,iv_name         => cv_msg_003a18_023
                      ,iv_token_name1  => cv_tkn_ac_code
                      ,iv_token_value1 => iv_customer_code);
      fnd_file.put_line(
        which => FND_FILE.LOG
       ,buff  => lv_data_msg);
    -- �����������p�ڋq���݂Ȃ����b�Z�[�W�o��
    ELSIF (iv_customer_class_code = cv_customer_class_code21) THEN
      lv_data_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cfr
                      ,iv_name         => cv_msg_003a18_024
                      ,iv_token_name1  => cv_tkn_ac_code
                      ,iv_token_value1 => iv_customer_code);
      fnd_file.put_line(
        which => FND_FILE.LOG
       ,buff  => lv_data_msg);
    -- �������p�ڋq���݂Ȃ����b�Z�[�W�o��
    ELSIF (iv_customer_class_code = cv_customer_class_code20) THEN
      lv_data_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cfr
                      ,iv_name         => cv_msg_003a18_022
                      ,iv_token_name1  => cv_tkn_ac_code
                      ,iv_token_value1 => iv_customer_code);
      fnd_file.put_line(
        which => FND_FILE.LOG
       ,buff  => lv_data_msg);
    END IF;
--
    -- �ڋq�R�t���x�����݃t���O�𑶍݂���ɕύX����
    gv_warning_flag := cv_status_yes;
--
--###########################  �Œ蕔 END   ############################
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf
                           ,1
                           ,5000);
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
  END put_account_warning;
--
-- Add 2013.12.13 Ver1.60 Start
  /**********************************************************************************
   * Procedure Name   : update_work_table
   * Description      : ���[�N�e�[�u���f�[�^�X�V(A-11
   ***********************************************************************************/
  PROCEDURE update_work_table(
-- Add 2016.09.06 Ver1.91 Start
    iv_tax_output_type     IN VARCHAR2,   -- �ŕʓ���o�͋敪
-- Add 2016.09.06 Ver1.91 End
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_work_table'; -- �v���O������
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
    cn_no_tax          CONSTANT NUMBER := 0;
-- Add 2016.09.06 Ver1.91 Start
    cv_tax_op_type_yes CONSTANT VARCHAR2(1) := '2';            -- �ŕʓ���o�͂���
-- Add 2016.09.06 Ver1.91 End
--
    -- *** ���[�J���ϐ� ***
    lt_bill_cust_code  xxcfr_rep_st_invoice_inc_tax_d.bill_cust_code%TYPE;
    lt_location_code   xxcfr_rep_st_invoice_inc_tax_d.location_code%TYPE;
-- Add 2015.07.31 Ver1.80 Start
    lt_bill_cust_code2 xxcfr_rep_st_inv_inc_tax_a_l.bill_cust_code%TYPE;
    lt_location_code2  xxcfr_rep_st_inv_inc_tax_a_l.location_code%TYPE;
    lt_bill_cust_code3 xxcfr_rep_st_inv_inc_tax_a_l.bill_cust_code%TYPE;
    lt_location_code3  xxcfr_rep_st_inv_inc_tax_a_l.location_code%TYPE;
    lt_ship_cust_code3 xxcfr_rep_st_inv_inc_tax_a_l.ship_cust_code%TYPE;
    lt_bill_cust_code5 xxcfr_rep_st_inv_inc_tax_b_l.bill_cust_code%TYPE;
    lt_location_code5  xxcfr_rep_st_inv_inc_tax_b_l.location_code%TYPE;
    lt_bill_cust_code6 xxcfr_rep_st_inv_inc_tax_b_l.bill_cust_code%TYPE;
    lt_location_code6  xxcfr_rep_st_inv_inc_tax_b_l.location_code%TYPE;
    lt_ship_cust_code6 xxcfr_rep_st_inv_inc_tax_b_l.ship_cust_code%TYPE;
-- Add 2015.07.31 Ver1.80 End
-- Add 2016.03.31 Ver1.90 Start
    lt_bill_cust_code8 xxcfr_rep_st_inv_inc_tax_c_l.bill_cust_code%TYPE;
    lt_location_code8  xxcfr_rep_st_inv_inc_tax_c_l.location_code%TYPE;
-- Add 2016.03.31 Ver1.90 End
-- Ver.1.92 [��QE_�{�ғ�_15307] ADD START
    lt_bill_cust_code9 xxcfr_rep_st_inv_inc_tax_d_l.bill_cust_code%TYPE;
    lt_location_code9  xxcfr_rep_st_inv_inc_tax_d_l.location_code%TYPE;
    lt_ship_cust_code9 xxcfr_rep_st_inv_inc_tax_d_l.ship_cust_code%TYPE;
-- Ver.1.92 [��QE_�{�ғ�_15307] ADD END
    ln_cust_cnt        PLS_INTEGER;
    ln_int             PLS_INTEGER := 0;
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR update_work_cur
    IS
      SELECT xrsi.bill_cust_code      bill_cust_code      ,  --�ڋq�R�[�h
             xrsi.location_code       location_code       ,  --�S�����_�R�[�h
-- Modify 2019.09.03 Ver1.93 Start
--             xrsi.tax_rate            tax_rate            ,  --�ŗ�
             xrsi.category            category            ,  --���󕪗�(�ҏW�p)
-- Modify 2019.09.03 Ver1.93 End
             SUM( xrsi.slip_sum ) + SUM( xrsi.slip_tax_sum ) tax_rate_by_sum  --�ŗ��ʂ����グ���z
      FROM   xxcfr_rep_st_invoice_inc_tax_d  xrsi
      WHERE  xrsi.request_id  = cn_request_id
-- Modify 2019.09.03 Ver1.93 Start
--      AND    xrsi.tax_rate   <> cn_no_tax                    --��ېŁi�ŗ�0%)�ȊO
      AND    xrsi.category   IS NOT NULL                     --���󕪗�(�ҏW�p)
-- Modify 2019.09.03 Ver1.93 End
      GROUP BY
             xrsi.bill_cust_code, -- �ڋq�R�[�h
             xrsi.location_code,  -- �S�����_�R�[�h
-- Modify 2019.09.03 Ver1.93 Start
--             xrsi.tax_rate        -- ����ŗ�(�ҏW�p)
             xrsi.category        -- ���󕪗�(�ҏW�p)
-- Modify 2019.09.03 Ver1.93 End
      ORDER BY
             xrsi.bill_cust_code, -- �ڋq�R�[�h
             xrsi.location_code,  -- �S�����_�R�[�h
-- Modify 2019.09.03 Ver1.93 Start
--             xrsi.tax_rate        -- ����ŗ�(�ҏW�p) ���ŗ��̏��������ɐݒ�
             xrsi.category        -- ���󕪗�(�ҏW�p)
-- Modify 2019.09.03 Ver1.93 End
      ;
--
-- Add 2015.07.31 Ver1.80 Start
    CURSOR update_work_2_cur
    IS
      SELECT xrsial.bill_cust_code                               bill_cust_code ,  -- �ڋq�R�[�h
             xrsial.location_code                                location_code  ,  -- �S�����_�R�[�h
-- Modify 2019.09.03 Ver1.93 Start
--             xrsial.tax_rate                                     tax_rate       ,  -- ����ŗ�(�ҏW�p)
             xrsial.category                                     category       ,  -- ���󕪗�(�ҏW�p)
-- Modify 2019.09.03 Ver1.93 End
             SUM( xrsial.slip_sum ) + SUM( xrsial.slip_tax_sum ) tax_rate_by_sum   -- �ŕʂ����グ�z
      FROM   xxcfr_rep_st_inv_inc_tax_a_l  xrsial
      WHERE  xrsial.request_id  = cn_request_id
-- Modify 2019.09.03 Ver1.93 Start
--      AND    xrsial.tax_rate   <> cn_no_tax                    -- ��ېŁi�ŗ�0%)�ȊO
      AND    xrsial.category   IS NOT NULL                     --���󕪗�(�ҏW�p)
-- Modify 2019.09.03 Ver1.93 End
      GROUP BY
             xrsial.bill_cust_code, -- �ڋq�R�[�h
             xrsial.location_code,  -- �S�����_�R�[�h
-- Modify 2019.09.03 Ver1.93 Start
--             xrsial.tax_rate        -- ����ŗ�(�ҏW�p)
             xrsial.category        -- ���󕪗�(�ҏW�p)
-- Modify 2019.09.03 Ver1.93 End
      ORDER BY
             xrsial.bill_cust_code, -- �ڋq�R�[�h
             xrsial.location_code,  -- �S�����_�R�[�h
-- Modify 2019.09.03 Ver1.93 Start
--             xrsial.tax_rate        -- ����ŗ�(�ҏW�p) ���ŗ��̏��������ɐݒ�
             xrsial.category        -- ���󕪗�(�ҏW�p)
-- Modify 2019.09.03 Ver1.93 End
      ;
--
    CURSOR update_work_3_cur
    IS
      SELECT xrsial.bill_cust_code                               bill_cust_code ,  -- �ڋq�R�[�h
             xrsial.location_code                                location_code  ,  -- �S�����_�R�[�h
             xrsial.ship_cust_code                               ship_cust_code ,  -- �[�i��ڋq�R�[�h
-- Modify 2019.09.03 Ver1.93 Start
--             xrsial.tax_rate                                     tax_rate       ,  -- ����ŗ�(�ҏW�p)
             xrsial.category                                     category       ,  -- ���󕪗�(�ҏW�p)
-- Modify 2019.09.03 Ver1.93 End
             SUM( xrsial.slip_sum ) + SUM( xrsial.slip_tax_sum ) tax_rate_by_sum   -- �ŕʂ����グ�z
      FROM   xxcfr_rep_st_inv_inc_tax_a_l  xrsial
      WHERE  xrsial.request_id  = cn_request_id
-- Modify 2019.09.03 Ver1.93 Start
--      AND    xrsial.tax_rate   <> cn_no_tax                    -- ��ېŁi�ŗ�0%)�ȊO
      AND    xrsial.category   IS NOT NULL                     --���󕪗�(�ҏW�p)
-- Modify 2019.09.03 Ver1.93 End
      GROUP BY
             xrsial.bill_cust_code, -- �ڋq�R�[�h
             xrsial.location_code,  -- �S�����_�R�[�h
             xrsial.ship_cust_code, -- �[�i��ڋq�R�[�h
-- Modify 2019.09.03 Ver1.93 Start
--             xrsial.tax_rate        -- ����ŗ�(�ҏW�p)
             xrsial.category        -- ���󕪗�(�ҏW�p)
-- Modify 2019.09.03 Ver1.93 End
      ORDER BY
             xrsial.bill_cust_code, -- �ڋq�R�[�h
             xrsial.location_code,  -- �S�����_�R�[�h
             xrsial.ship_cust_code, -- �[�i��ڋq�R�[�h
-- Modify 2019.09.03 Ver1.93 Start
--             xrsial.tax_rate        -- ����ŗ�(�ҏW�p) ���ŗ��̏��������ɐݒ�
             xrsial.category        -- ���󕪗�(�ҏW�p)
-- Modify 2019.09.03 Ver1.93 End
      ;
--
    CURSOR update_work_4_cur
    IS
      SELECT xrsial.bill_cust_code                               bill_cust_code ,  -- �ڋq�R�[�h
             xrsial.location_code                                location_code  ,  -- �S�����_�R�[�h
             xrsial.ship_cust_code                               ship_cust_code ,  -- �[�i��ڋq�R�[�h
             SUM( xrsial.slip_sum ) + SUM( xrsial.slip_tax_sum ) store_sum         -- �ŕʂ����グ�z
      FROM   xxcfr_rep_st_inv_inc_tax_a_l  xrsial
      WHERE  xrsial.request_id  = cn_request_id
      GROUP BY
             xrsial.bill_cust_code, -- �ڋq�R�[�h
             xrsial.location_code,  -- �S�����_�R�[�h
             xrsial.ship_cust_code  -- �[�i��ڋq�R�[�h
      ORDER BY
             xrsial.bill_cust_code, -- �ڋq�R�[�h
             xrsial.location_code,  -- �S�����_�R�[�h
             xrsial.ship_cust_code  -- �[�i��ڋq�R�[�h
      ;
--
    CURSOR update_work_5_cur
    IS
      SELECT xrsibl.bill_cust_code                               bill_cust_code ,  -- �ڋq�R�[�h
             xrsibl.location_code                                location_code  ,  -- �S�����_�R�[�h
-- Modify 2019.09.03 Ver1.93 Start
--             xrsibl.tax_rate                                     tax_rate       ,  -- ����ŗ�(�ҏW�p)
             xrsibl.category                                     category       ,  -- ���󕪗�(�ҏW�p)
-- Modify 2019.09.03 Ver1.93 End
             SUM( xrsibl.slip_sum ) + SUM( xrsibl.slip_tax_sum ) tax_rate_by_sum   -- �ŕʂ����グ�z
      FROM   xxcfr_rep_st_inv_inc_tax_b_l  xrsibl
      WHERE  xrsibl.request_id  = cn_request_id
-- Modify 2019.09.03 Ver1.93 Start
--      AND    xrsibl.tax_rate   <> cn_no_tax                    -- ��ېŁi�ŗ�0%)�ȊO
      AND    xrsibl.category   IS NOT NULL                     --���󕪗�(�ҏW�p)
-- Modify 2019.09.03 Ver1.93 End
      GROUP BY
             xrsibl.bill_cust_code, -- �ڋq�R�[�h
             xrsibl.location_code,  -- �S�����_�R�[�h
-- Modify 2019.09.03 Ver1.93 Start
--             xrsibl.tax_rate        -- ����ŗ�(�ҏW�p)
             xrsibl.category        -- ���󕪗�(�ҏW�p)
-- Modify 2019.09.03 Ver1.93 End
      ORDER BY
             xrsibl.bill_cust_code, -- �ڋq�R�[�h
             xrsibl.location_code,  -- �S�����_�R�[�h
-- Modify 2019.09.03 Ver1.93 Start
--             xrsibl.tax_rate        -- ����ŗ�(�ҏW�p) ���ŗ��̏��������ɐݒ�
             xrsibl.category        -- ���󕪗�(�ҏW�p)
-- Modify 2019.09.03 Ver1.93 End
      ;
--
    CURSOR update_work_6_cur
    IS
      SELECT xrsibl.bill_cust_code                               bill_cust_code ,  -- �ڋq�R�[�h
             xrsibl.location_code                                location_code  ,  -- �S�����_�R�[�h
             xrsibl.ship_cust_code                               ship_cust_code ,  -- �[�i��ڋq�R�[�h
-- Modify 2019.09.03 Ver1.93 Start
--             xrsibl.tax_rate                                     tax_rate       ,  -- ����ŗ�(�ҏW�p)
             xrsibl.category                                     category       ,  -- ���󕪗�(�ҏW�p)
-- Modify 2019.09.03 Ver1.93 End
             SUM( xrsibl.slip_sum ) + SUM( xrsibl.slip_tax_sum ) tax_rate_by_sum   -- �ŕʂ����グ�z
      FROM   xxcfr_rep_st_inv_inc_tax_b_l  xrsibl
      WHERE  xrsibl.request_id  = cn_request_id
-- Modify 2019.09.03 Ver1.93 Start
--      AND    xrsibl.tax_rate   <> cn_no_tax                    -- ��ېŁi�ŗ�0%)�ȊO
      AND    xrsibl.category   IS NOT NULL                     --���󕪗�(�ҏW�p)
-- Modify 2019.09.03 Ver1.93 End
      GROUP BY
             xrsibl.bill_cust_code, -- �ڋq�R�[�h
             xrsibl.location_code,  -- �S�����_�R�[�h
             xrsibl.ship_cust_code, -- �[�i��ڋq�R�[�h
-- Modify 2019.09.03 Ver1.93 Start
--             xrsibl.tax_rate        -- ����ŗ�(�ҏW�p)
             xrsibl.category        -- ���󕪗�(�ҏW�p)
-- Modify 2019.09.03 Ver1.93 End
      ORDER BY
             xrsibl.bill_cust_code, -- �ڋq�R�[�h
             xrsibl.location_code,  -- �S�����_�R�[�h
             xrsibl.ship_cust_code, -- �[�i��ڋq�R�[�h
-- Modify 2019.09.03 Ver1.93 Start
--             xrsibl.tax_rate        -- ����ŗ�(�ҏW�p) ���ŗ��̏��������ɐݒ�
             xrsibl.category        -- ���󕪗�(�ҏW�p)
-- Modify 2019.09.03 Ver1.93 End
      ;
--
    CURSOR update_work_7_cur
    IS
      SELECT xrsibl.bill_cust_code                               bill_cust_code ,  -- �ڋq�R�[�h
             xrsibl.location_code                                location_code  ,  -- �S�����_�R�[�h
             xrsibl.ship_cust_code                               ship_cust_code ,  -- �[�i��ڋq�R�[�h
             SUM( xrsibl.slip_sum ) + SUM( xrsibl.slip_tax_sum ) store_sum         -- �ŕʂ����グ�z
      FROM   xxcfr_rep_st_inv_inc_tax_b_l  xrsibl
      WHERE  xrsibl.request_id  = cn_request_id
      GROUP BY
             xrsibl.bill_cust_code, -- �ڋq�R�[�h
             xrsibl.location_code,  -- �S�����_�R�[�h
             xrsibl.ship_cust_code  -- �[�i��ڋq�R�[�h
      ORDER BY
             xrsibl.bill_cust_code, -- �ڋq�R�[�h
             xrsibl.location_code,  -- �S�����_�R�[�h
             xrsibl.ship_cust_code  -- �[�i��ڋq�R�[�h
      ;
--
-- Add 2015.07.31 Ver1.80 End
-- Add 2016.03.31 Ver1.90 Start
    CURSOR update_work_8_cur
    IS
      SELECT xrsicl.bill_cust_code                               bill_cust_code ,  -- �ڋq�R�[�h
             xrsicl.location_code                                location_code  ,  -- �S�����_�R�[�h
-- Modify 2019.09.03 Ver1.93 Start
--             xrsicl.tax_rate                                     tax_rate       ,  -- ����ŗ�(�ҏW�p)
             xrsicl.category                                     category       ,  -- ���󕪗�(�ҏW�p)
-- Modify 2019.09.03 Ver1.93 End
             SUM( xrsicl.slip_sum ) + SUM( xrsicl.slip_tax_sum ) tax_rate_by_sum   -- �ŕʂ����グ�z
      FROM   xxcfr_rep_st_inv_inc_tax_c_l  xrsicl
      WHERE  xrsicl.request_id  = cn_request_id
-- Modify 2019.09.03 Ver1.93 Start
--      AND    xrsicl.tax_rate   <> cn_no_tax                    -- ��ېŁi�ŗ�0%)�ȊO
      AND    xrsicl.category   IS NOT NULL                     --���󕪗�(�ҏW�p)
-- Modify 2019.09.03 Ver1.93 End
      GROUP BY
             xrsicl.bill_cust_code, -- �ڋq�R�[�h
             xrsicl.location_code,  -- �S�����_�R�[�h
-- Modify 2019.09.03 Ver1.93 Start
--             xrsicl.tax_rate        -- ����ŗ�(�ҏW�p)
             xrsicl.category        --  ���󕪗�(�ҏW�p)
-- Modify 2019.09.03 Ver1.93 End
      ORDER BY
             xrsicl.bill_cust_code, -- �ڋq�R�[�h
             xrsicl.location_code,  -- �S�����_�R�[�h
-- Modify 2019.09.03 Ver1.93 Start
--             xrsicl.tax_rate        -- ����ŗ�(�ҏW�p) ���ŗ��̏��������ɐݒ�
             xrsicl.category        --  ���󕪗�(�ҏW�p)
-- Modify 2019.09.03 Ver1.93 End
      ;
--
-- Add 2016.03.31 Ver1.90 End
-- Ver.1.92 [��QE_�{�ғ�_15307] ADD START
    --�P��D���ׂ̐ŕʓ���X�V�p
    CURSOR update_work_9_cur
    IS
      SELECT xrsidl.bill_cust_code                               bill_cust_code ,  -- �ڋq�R�[�h
             xrsidl.location_code                                location_code  ,  -- �S�����_�R�[�h
             xrsidl.ship_cust_code                               ship_cust_code ,  -- �[�i��ڋq�R�[�h
-- Modify 2019.09.03 Ver1.93 Start
--             xrsidl.tax_rate                                     tax_rate       ,  -- ����ŗ�(�ҏW�p)
             xrsidl.category                                     category       ,  -- ���󕪗�(�ҏW�p)
-- Modify 2019.09.03 Ver1.93 End
             SUM( xrsidl.slip_sum ) + SUM( xrsidl.slip_tax_sum ) tax_rate_by_sum   -- �ŕʂ����グ�z
      FROM   xxcfr_rep_st_inv_inc_tax_d_l  xrsidl
      WHERE  xrsidl.request_id  = cn_request_id
-- Modify 2019.09.03 Ver1.93 Start
--      AND    xrsidl.tax_rate   <> cn_no_tax                    -- ��ېŁi�ŗ�0%)�ȊO
      AND    xrsidl.category   IS NOT NULL                     --���󕪗�(�ҏW�p)
-- Modify 2019.09.03 Ver1.93 End
      GROUP BY
             xrsidl.bill_cust_code, -- �ڋq�R�[�h
             xrsidl.location_code,  -- �S�����_�R�[�h
             xrsidl.ship_cust_code, -- �[�i��ڋq�R�[�h
-- Modify 2019.09.03 Ver1.93 Start
--             xrsidl.tax_rate        -- ����ŗ�(�ҏW�p)
             xrsidl.category        -- ���󕪗�(�ҏW�p)
-- Modify 2019.09.03 Ver1.93 End
      ORDER BY
             xrsidl.bill_cust_code, -- �ڋq�R�[�h
             xrsidl.location_code,  -- �S�����_�R�[�h
             xrsidl.ship_cust_code, -- �[�i��ڋq�R�[�h
-- Modify 2019.09.03 Ver1.93 Start
--             xrsidl.tax_rate        -- ����ŗ�(�ҏW�p) ���ŗ��̏��������ɐݒ�
             xrsidl.category        -- ���󕪗�(�ҏW�p)
-- Modify 2019.09.03 Ver1.93 End
      ;
--
    --�P��D���ׂ̓����������z�X�V�p
    CURSOR update_work_10_cur
    IS
      SELECT xrsidl.bill_cust_code                               bill_cust_code ,  -- �ڋq�R�[�h
             xrsidl.location_code                                location_code  ,  -- �S�����_�R�[�h
             xrsidl.ship_cust_code                               ship_cust_code ,  -- �[�i��ڋq�R�[�h
             SUM( xrsidl.slip_sum ) + SUM( xrsidl.slip_tax_sum ) store_sum         -- �ŕʂ����グ�z
      FROM   xxcfr_rep_st_inv_inc_tax_d_l  xrsidl
      WHERE  xrsidl.request_id  = cn_request_id
      GROUP BY
             xrsidl.bill_cust_code, -- �ڋq�R�[�h
             xrsidl.location_code,  -- �S�����_�R�[�h
             xrsidl.ship_cust_code  -- �[�i��ڋq�R�[�h
      ORDER BY
             xrsidl.bill_cust_code, -- �ڋq�R�[�h
             xrsidl.location_code,  -- �S�����_�R�[�h
             xrsidl.ship_cust_code  -- �[�i��ڋq�R�[�h
      ;
--
-- Ver.1.92 [��QE_�{�ғ�_15307] ADD END
    -- *** ���[�J���E���R�[�h ***
    update_work_rec  update_work_cur%ROWTYPE;
-- Add 2015.07.31 Ver1.80 Start
    update_work_2_rec  update_work_2_cur%ROWTYPE;
    update_work_3_rec  update_work_3_cur%ROWTYPE;
    update_work_4_rec  update_work_4_cur%ROWTYPE;
    update_work_5_rec  update_work_5_cur%ROWTYPE;
    update_work_6_rec  update_work_6_cur%ROWTYPE;
    update_work_7_rec  update_work_7_cur%ROWTYPE;
-- Add 2015.07.31 Ver1.80 End
-- Add 2016.03.31 Ver1.90 Start
    update_work_8_rec  update_work_8_cur%ROWTYPE;
-- Add 2016.03.31 Ver1.90 End
-- Ver.1.92 [��QE_�{�ғ�_15307] ADD START
    update_work_9_rec  update_work_9_cur%ROWTYPE;
    update_work_10_rec update_work_10_cur%ROWTYPE;
-- Ver.1.92 [��QE_�{�ғ�_15307] ADD END
--
    -- *** ���[�J���E�^�C�v ***
    TYPE l_bill_cust_code_ttype IS TABLE OF xxcfr_rep_st_invoice_inc_tax_d.bill_cust_code%TYPE  INDEX BY PLS_INTEGER;
    TYPE l_location_code_ttype  IS TABLE OF xxcfr_rep_st_invoice_inc_tax_d.location_code%TYPE   INDEX BY PLS_INTEGER;
-- Modify 2019.09.03 Ver1.93 Start
--    TYPE l_tax_rate_ttype       IS TABLE OF xxcfr_rep_st_invoice_inc_tax_d.tax_rate1%TYPE       INDEX BY PLS_INTEGER;
    TYPE l_category_ttype       IS TABLE OF xxcfr_rep_st_invoice_inc_tax_d.category1%TYPE       INDEX BY PLS_INTEGER;
-- Modify 2019.09.03 Ver1.93 End
    TYPE l_inc_tax_charge_ttype IS TABLE OF xxcfr_rep_st_invoice_inc_tax_d.inc_tax_charge1%TYPE INDEX BY PLS_INTEGER;
-- Add 2015.07.31 Ver1.80 Start
--
    TYPE l_bill_cust_code_2_ttype IS TABLE OF xxcfr_rep_st_inv_inc_tax_a_l.bill_cust_code%TYPE  INDEX BY PLS_INTEGER;
    TYPE l_location_code_2_ttype  IS TABLE OF xxcfr_rep_st_inv_inc_tax_a_l.location_code%TYPE   INDEX BY PLS_INTEGER;
-- Modify 2019.09.03 Ver1.93 Start
--    TYPE l_tax_rate_2_ttype       IS TABLE OF xxcfr_rep_st_inv_inc_tax_a_l.tax_rate1%TYPE       INDEX BY PLS_INTEGER;
    TYPE l_category_2_ttype       IS TABLE OF xxcfr_rep_st_inv_inc_tax_a_l.category1%TYPE       INDEX BY PLS_INTEGER;
-- Modify 2019.09.03 Ver1.93 End
    TYPE l_inc_tax_charge_2_ttype IS TABLE OF xxcfr_rep_st_inv_inc_tax_a_l.inc_tax_charge1%TYPE INDEX BY PLS_INTEGER;
--
    TYPE l_bill_cust_code_3_ttype IS TABLE OF xxcfr_rep_st_inv_inc_tax_a_l.bill_cust_code%TYPE  INDEX BY PLS_INTEGER;
    TYPE l_location_code_3_ttype  IS TABLE OF xxcfr_rep_st_inv_inc_tax_a_l.location_code%TYPE   INDEX BY PLS_INTEGER;
    TYPE l_ship_cust_code_3_ttype IS TABLE OF xxcfr_rep_st_inv_inc_tax_a_l.ship_cust_code%TYPE  INDEX BY PLS_INTEGER;
-- Modify 2019.09.03 Ver1.93 Start
--    TYPE l_tax_rate_3_ttype       IS TABLE OF xxcfr_rep_st_inv_inc_tax_a_l.tax_rate1%TYPE       INDEX BY PLS_INTEGER;
    TYPE l_category_3_ttype       IS TABLE OF xxcfr_rep_st_inv_inc_tax_a_l.category1%TYPE       INDEX BY PLS_INTEGER;
-- Modify 2019.09.03 Ver1.93 End
    TYPE l_inc_tax_charge_3_ttype IS TABLE OF xxcfr_rep_st_inv_inc_tax_a_l.inc_tax_charge1%TYPE INDEX BY PLS_INTEGER;
--
    TYPE l_bill_cust_code_4_ttype IS TABLE OF xxcfr_rep_st_inv_inc_tax_a_l.bill_cust_code%TYPE  INDEX BY PLS_INTEGER;
    TYPE l_location_code_4_ttype  IS TABLE OF xxcfr_rep_st_inv_inc_tax_a_l.location_code%TYPE   INDEX BY PLS_INTEGER;
    TYPE l_ship_cust_code_4_ttype IS TABLE OF xxcfr_rep_st_inv_inc_tax_a_l.ship_cust_code%TYPE  INDEX BY PLS_INTEGER;
    TYPE l_store_sum_4_ttype      IS TABLE OF xxcfr_rep_st_inv_inc_tax_a_l.store_sum%TYPE       INDEX BY PLS_INTEGER;
--
    TYPE l_bill_cust_code_5_ttype IS TABLE OF xxcfr_rep_st_inv_inc_tax_b_l.bill_cust_code%TYPE  INDEX BY PLS_INTEGER;
    TYPE l_location_code_5_ttype  IS TABLE OF xxcfr_rep_st_inv_inc_tax_b_l.location_code%TYPE   INDEX BY PLS_INTEGER;
-- Modify 2019.09.03 Ver1.93 Start
--    TYPE l_tax_rate_5_ttype       IS TABLE OF xxcfr_rep_st_inv_inc_tax_b_l.tax_rate1%TYPE       INDEX BY PLS_INTEGER;
    TYPE l_category_5_ttype       IS TABLE OF xxcfr_rep_st_inv_inc_tax_b_l.category1%TYPE       INDEX BY PLS_INTEGER;
-- Modify 2019.09.03 Ver1.93 End
    TYPE l_inc_tax_charge_5_ttype IS TABLE OF xxcfr_rep_st_inv_inc_tax_b_l.inc_tax_charge1%TYPE INDEX BY PLS_INTEGER;
--
    TYPE l_bill_cust_code_6_ttype IS TABLE OF xxcfr_rep_st_inv_inc_tax_b_l.bill_cust_code%TYPE  INDEX BY PLS_INTEGER;
    TYPE l_location_code_6_ttype  IS TABLE OF xxcfr_rep_st_inv_inc_tax_b_l.location_code%TYPE   INDEX BY PLS_INTEGER;
    TYPE l_ship_cust_code_6_ttype IS TABLE OF xxcfr_rep_st_inv_inc_tax_b_l.ship_cust_code%TYPE  INDEX BY PLS_INTEGER;
-- Modify 2019.09.03 Ver1.93 Start
--    TYPE l_tax_rate_6_ttype       IS TABLE OF xxcfr_rep_st_inv_inc_tax_b_l.tax_rate1%TYPE       INDEX BY PLS_INTEGER;
    TYPE l_category_6_ttype       IS TABLE OF xxcfr_rep_st_inv_inc_tax_b_l.category1%TYPE       INDEX BY PLS_INTEGER;
-- Modify 2019.09.03 Ver1.93 End
    TYPE l_inc_tax_charge_6_ttype IS TABLE OF xxcfr_rep_st_inv_inc_tax_b_l.inc_tax_charge1%TYPE INDEX BY PLS_INTEGER;
--
    TYPE l_bill_cust_code_7_ttype IS TABLE OF xxcfr_rep_st_inv_inc_tax_b_l.bill_cust_code%TYPE  INDEX BY PLS_INTEGER;
    TYPE l_location_code_7_ttype  IS TABLE OF xxcfr_rep_st_inv_inc_tax_b_l.location_code%TYPE   INDEX BY PLS_INTEGER;
    TYPE l_ship_cust_code_7_ttype IS TABLE OF xxcfr_rep_st_inv_inc_tax_b_l.ship_cust_code%TYPE  INDEX BY PLS_INTEGER;
    TYPE l_store_sum_7_ttype      IS TABLE OF xxcfr_rep_st_inv_inc_tax_b_l.store_sum%TYPE       INDEX BY PLS_INTEGER;
-- Add 2015.07.31 Ver1.80 End
-- Add 2016.03.31 Ver1.90 Start
--
    TYPE l_bill_cust_code_8_ttype IS TABLE OF xxcfr_rep_st_inv_inc_tax_c_l.bill_cust_code%TYPE  INDEX BY PLS_INTEGER;
    TYPE l_location_code_8_ttype  IS TABLE OF xxcfr_rep_st_inv_inc_tax_c_l.location_code%TYPE   INDEX BY PLS_INTEGER;
-- Modify 2019.09.03 Ver1.93 Start
--    TYPE l_tax_rate_8_ttype       IS TABLE OF xxcfr_rep_st_inv_inc_tax_c_l.tax_rate1%TYPE       INDEX BY PLS_INTEGER;
    TYPE l_category_8_ttype       IS TABLE OF xxcfr_rep_st_inv_inc_tax_c_l.category%TYPE        INDEX BY PLS_INTEGER;
-- Modify 2019.09.03 Ver1.93 End
    TYPE l_inc_tax_charge_8_ttype IS TABLE OF xxcfr_rep_st_inv_inc_tax_c_l.inc_tax_charge1%TYPE INDEX BY PLS_INTEGER;
-- Add 2016.03.31 Ver1.90 End
-- Ver.1.92 [��QE_�{�ғ�_15307] ADD START
--
    TYPE l_bill_cust_code_9_ttype IS TABLE OF xxcfr_rep_st_inv_inc_tax_d_l.bill_cust_code%TYPE  INDEX BY PLS_INTEGER;
    TYPE l_location_code_9_ttype  IS TABLE OF xxcfr_rep_st_inv_inc_tax_d_l.location_code%TYPE   INDEX BY PLS_INTEGER;
    TYPE l_ship_cust_code_9_ttype IS TABLE OF xxcfr_rep_st_inv_inc_tax_d_l.ship_cust_code%TYPE  INDEX BY PLS_INTEGER;
-- Modify 2019.09.03 Ver1.93 Start
--    TYPE l_tax_rate_9_ttype       IS TABLE OF xxcfr_rep_st_inv_inc_tax_d_l.tax_rate1%TYPE       INDEX BY PLS_INTEGER;
    TYPE l_category_9_ttype       IS TABLE OF xxcfr_rep_st_inv_inc_tax_d_l.category1%TYPE       INDEX BY PLS_INTEGER;
-- Modify 2019.09.03 Ver1.93 End
    TYPE l_inc_tax_charge_9_ttype IS TABLE OF xxcfr_rep_st_inv_inc_tax_d_l.inc_tax_charge1%TYPE INDEX BY PLS_INTEGER;
--
    TYPE l_bill_cust_code_10_ttype IS TABLE OF xxcfr_rep_st_inv_inc_tax_d_l.bill_cust_code%TYPE  INDEX BY PLS_INTEGER;
    TYPE l_location_code_10_ttype  IS TABLE OF xxcfr_rep_st_inv_inc_tax_d_l.location_code%TYPE   INDEX BY PLS_INTEGER;
    TYPE l_ship_cust_code_10_ttype IS TABLE OF xxcfr_rep_st_inv_inc_tax_d_l.ship_cust_code%TYPE  INDEX BY PLS_INTEGER;
    TYPE l_store_sum_10_ttype      IS TABLE OF xxcfr_rep_st_inv_inc_tax_d_l.store_sum%TYPE       INDEX BY PLS_INTEGER;
-- Ver.1.92 [��QE_�{�ғ�_15307] ADD END
--
    l_bill_cust_code_tab     l_bill_cust_code_ttype;  --�ڋq�R�[�h
    l_location_code_tab      l_location_code_ttype;   --�S�����_�R�[�h
-- Modify 2019.09.03 Ver1.93 Start
--    l_tax_rate1_tab          l_tax_rate_ttype;        --����ŗ��P
    l_category1_tab          l_category_ttype;        --���󕪗ނP
-- Modify 2019.09.03 Ver1.93 End
    l_inc_tax_charge1_tab    l_inc_tax_charge_ttype;  --���������グ�z�P
-- Modify 2019.09.03 Ver1.93 Start
--    l_tax_rate2_tab          l_tax_rate_ttype;        --����ŗ��Q
    l_category2_tab          l_category_ttype;        --���󕪗ނQ
-- Modify 2019.09.03 Ver1.93 End
    l_inc_tax_charge2_tab    l_inc_tax_charge_ttype;  --���������グ�z�Q
-- Add 2019.09.03 Ver1.93 Start
    l_category3_tab          l_category_ttype;        --���󕪗ނR
    l_inc_tax_charge3_tab    l_inc_tax_charge_ttype;  --���������グ�z�R
-- Add 2019.09.03 Ver1.93 End
--
-- Add 2015.07.31 Ver1.80 Start
    l_bill_cust_code_2_tab   l_bill_cust_code_2_ttype;  -- �ڋq�R�[�h
    l_location_code_2_tab    l_location_code_2_ttype;   -- �S�����_�R�[�h
-- Modify 2019.09.03 Ver1.93 Start
--    l_tax_rate1_2_tab        l_tax_rate_2_ttype;        -- ����ŗ��P
    l_category1_2_tab        l_category_2_ttype;        --���󕪗ނP
-- Modify 2019.09.03 Ver1.93 End
    l_inc_tax_charge1_2_tab  l_inc_tax_charge_2_ttype;  -- ���������グ�z�P
-- Modify 2019.09.03 Ver1.93 Start
--    l_tax_rate2_2_tab        l_tax_rate_2_ttype;        -- ����ŗ��Q
    l_category2_2_tab        l_category_2_ttype;        --���󕪗ނQ
-- Modify 2019.09.03 Ver1.93 End
    l_inc_tax_charge2_2_tab  l_inc_tax_charge_2_ttype;  -- ���������グ�z�Q
-- Add 2019.09.03 Ver1.93 Start
    l_category3_2_tab        l_category_2_ttype;        --���󕪗ނR
    l_inc_tax_charge3_2_tab  l_inc_tax_charge_2_ttype;  --���������グ�z�R
-- Add 2019.09.03 Ver1.93 End
--
    l_bill_cust_code_3_tab   l_bill_cust_code_3_ttype;  -- �ڋq�R�[�h
    l_location_code_3_tab    l_location_code_3_ttype;   -- �S�����_�R�[�h
    l_ship_cust_code_3_tab   l_ship_cust_code_3_ttype;  -- �[�i��ڋq�R�[�h
-- Modify 2019.09.03 Ver1.93 Start
--    l_tax_rate1_3_tab        l_tax_rate_3_ttype;        -- ����ŗ��P
    l_category1_3_tab        l_category_3_ttype;        --���󕪗ނP
-- Modify 2019.09.03 Ver1.93 End
    l_inc_tax_charge1_3_tab  l_inc_tax_charge_3_ttype;  -- ���������グ�z�P
-- Modify 2019.09.03 Ver1.93 Start
--    l_tax_rate2_3_tab        l_tax_rate_3_ttype;        -- ����ŗ��Q
    l_category2_3_tab        l_category_3_ttype;        --���󕪗ނQ
-- Modify 2019.09.03 Ver1.93 End
    l_inc_tax_charge2_3_tab  l_inc_tax_charge_3_ttype;  -- ���������グ�z�Q
-- Add 2019.09.03 Ver1.93 Start
    l_category3_3_tab        l_category_3_ttype;        --���󕪗ނR
    l_inc_tax_charge3_3_tab  l_inc_tax_charge_3_ttype;  --���������グ�z�R
-- Add 2019.09.03 Ver1.93 End
--
    l_bill_cust_code_4_tab   l_bill_cust_code_4_ttype;  -- �ڋq�R�[�h
    l_location_code_4_tab    l_location_code_4_ttype;   -- �S�����_�R�[�h
    l_ship_cust_code_4_tab   l_ship_cust_code_4_ttype;  -- �[�i��ڋq�R�[�h
    l_store_sum_4_tab        l_store_sum_4_ttype;       -- �ŕʂ����グ�z
--
    l_bill_cust_code_5_tab   l_bill_cust_code_5_ttype;  -- �ڋq�R�[�h
    l_location_code_5_tab    l_location_code_5_ttype;   -- �S�����_�R�[�h
-- Modify 2019.09.03 Ver1.93 Start
--    l_tax_rate1_5_tab        l_tax_rate_5_ttype;        -- ����ŗ��P
    l_category1_5_tab        l_category_5_ttype;        --���󕪗ނP
-- Modify 2019.09.03 Ver1.93 End
    l_inc_tax_charge1_5_tab  l_inc_tax_charge_5_ttype;  -- ���������グ�z�P
-- Modify 2019.09.03 Ver1.93 Start
--    l_tax_rate2_5_tab        l_tax_rate_5_ttype;        -- ����ŗ��Q
    l_category2_5_tab        l_category_5_ttype;        --���󕪗ނQ
-- Modify 2019.09.03 Ver1.93 End
    l_inc_tax_charge2_5_tab  l_inc_tax_charge_5_ttype;  -- ���������グ�z�Q
-- Add 2019.09.03 Ver1.93 Start
    l_category3_5_tab        l_category_5_ttype;        --���󕪗ނR
    l_inc_tax_charge3_5_tab  l_inc_tax_charge_5_ttype;  --���������グ�z�R
-- Add 2019.09.03 Ver1.93 End
--
    l_bill_cust_code_6_tab   l_bill_cust_code_6_ttype;  -- �ڋq�R�[�h
    l_location_code_6_tab    l_location_code_6_ttype;   -- �S�����_�R�[�h
    l_ship_cust_code_6_tab   l_ship_cust_code_6_ttype;  -- �[�i��ڋq�R�[�h
-- Modify 2019.09.03 Ver1.93 Start
--    l_tax_rate1_6_tab        l_tax_rate_6_ttype;        -- ����ŗ��P
    l_category1_6_tab        l_category_6_ttype;        --���󕪗ނP
-- Modify 2019.09.03 Ver1.93 End
    l_inc_tax_charge1_6_tab  l_inc_tax_charge_6_ttype;  -- ���������グ�z�P
-- Modify 2019.09.03 Ver1.93 Start
--    l_tax_rate2_6_tab        l_tax_rate_6_ttype;        -- ����ŗ��Q
    l_category2_6_tab        l_category_6_ttype;        --���󕪗ނQ
-- Modify 2019.09.03 Ver1.93 End
    l_inc_tax_charge2_6_tab  l_inc_tax_charge_6_ttype;  -- ���������グ�z�Q
-- Add 2019.09.03 Ver1.93 Start
    l_category3_6_tab        l_category_6_ttype;        --���󕪗ނR
    l_inc_tax_charge3_6_tab  l_inc_tax_charge_6_ttype;  --���������グ�z�R
-- Add 2019.09.03 Ver1.93 End
--
    l_bill_cust_code_7_tab   l_bill_cust_code_7_ttype;  -- �ڋq�R�[�h
    l_location_code_7_tab    l_location_code_7_ttype;   -- �S�����_�R�[�h
    l_ship_cust_code_7_tab   l_ship_cust_code_7_ttype;  -- �[�i��ڋq�R�[�h
    l_store_sum_7_tab        l_store_sum_7_ttype;       -- �ŕʂ����グ�z
-- Add 2015.07.31 Ver1.80 End
-- Add 2016.03.31 Ver1.90 Start
--
    l_bill_cust_code_8_tab   l_bill_cust_code_8_ttype;  -- �ڋq�R�[�h
    l_location_code_8_tab    l_location_code_8_ttype;   -- �S�����_�R�[�h
-- Modify 2019.09.03 Ver1.93 Start
--    l_tax_rate1_8_tab        l_tax_rate_8_ttype;        -- ����ŗ��P
    l_category1_8_tab        l_category_8_ttype;        --���󕪗ނP
-- Modify 2019.09.03 Ver1.93 End
    l_inc_tax_charge1_8_tab  l_inc_tax_charge_8_ttype;  -- ���������グ�z�P
-- Modify 2019.09.03 Ver1.93 Start
--    l_tax_rate2_8_tab        l_tax_rate_8_ttype;        -- ����ŗ��Q
    l_category2_8_tab        l_category_8_ttype;        --���󕪗ނQ
-- Modify 2019.09.03 Ver1.93 End
    l_inc_tax_charge2_8_tab  l_inc_tax_charge_8_ttype;  -- ���������グ�z�Q
-- Add 2019.09.03 Ver1.93 Start
    l_category3_8_tab        l_category_8_ttype;        --���󕪗ނR
    l_inc_tax_charge3_8_tab  l_inc_tax_charge_8_ttype;  --���������グ�z�R
-- Add 2019.09.03 Ver1.93 End
-- Add 2016.03.31 Ver1.90 End
-- Ver.1.92 [��QE_�{�ғ�_15307] ADD START
--
    l_bill_cust_code_9_tab   l_bill_cust_code_9_ttype;  -- �ڋq�R�[�h
    l_location_code_9_tab    l_location_code_9_ttype;   -- �S�����_�R�[�h
    l_ship_cust_code_9_tab   l_ship_cust_code_9_ttype;  -- �[�i��ڋq�R�[�h
-- Modify 2019.09.03 Ver1.93 Start
--    l_tax_rate1_9_tab        l_tax_rate_9_ttype;        -- ����ŗ��P
    l_category1_9_tab        l_category_9_ttype;        --���󕪗ނP
-- Modify 2019.09.03 Ver1.93 End
    l_inc_tax_charge1_9_tab  l_inc_tax_charge_9_ttype;  -- ���������グ�z�P
-- Modify 2019.09.03 Ver1.93 Start
--    l_tax_rate2_9_tab        l_tax_rate_9_ttype;        -- ����ŗ��Q
    l_category2_9_tab        l_category_9_ttype;        --���󕪗ނQ
-- Modify 2019.09.03 Ver1.93 End
    l_inc_tax_charge2_9_tab  l_inc_tax_charge_9_ttype;  -- ���������グ�z�Q
-- Add 2019.09.03 Ver1.93 Start
    l_category3_9_tab        l_category_9_ttype;        --���󕪗ނR
    l_inc_tax_charge3_9_tab  l_inc_tax_charge_9_ttype;  --���������グ�z�R
-- Add 2019.09.03 Ver1.93 End
--
    l_bill_cust_code_10_tab  l_bill_cust_code_10_ttype;  -- �ڋq�R�[�h
    l_location_code_10_tab   l_location_code_10_ttype;   -- �S�����_�R�[�h
    l_ship_cust_code_10_tab  l_ship_cust_code_10_ttype;  -- �[�i��ڋq�R�[�h
    l_store_sum_10_tab       l_store_sum_10_ttype;       -- �ŕʂ����グ�z
-- Ver.1.92 [��QE_�{�ғ�_15307] ADD END
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
-- Mod 2015.07.31 Ver1.80 Start
--    <<edit_loop>>
--    FOR update_work_rec IN update_work_cur LOOP
----
--      --����A���́A�ڋq�R�[�h�E�S�����_�R�[�h���u���[�N
--      IF (
--           ( lt_bill_cust_code IS NULL )
--           OR
--           ( lt_bill_cust_code <> update_work_rec.bill_cust_code )
--           OR
--           ( lt_location_code  <> update_work_rec.location_code )
--         )
--      THEN
--        --�������A�y�сA�P���R�[�h�ڂ̐ŕʍ��ڐݒ�
--        ln_cust_cnt                   := 1;                                   --�u���[�N�����R�[�h����������
--        ln_int                        := ln_int + 1;                          --�z��J�E���g�A�b�v
--        l_bill_cust_code_tab(ln_int)  := update_work_rec.bill_cust_code;      --�ڋq�R�[�h
--        l_location_code_tab(ln_int)   := update_work_rec.location_code;       --�S�����_�R�[�h
--        l_tax_rate1_tab(ln_int)       := update_work_rec.tax_rate;            --����ŗ�1
--        l_inc_tax_charge1_tab(ln_int) := update_work_rec.tax_rate_by_sum;     --���������グ�z�P
--        l_tax_rate2_tab(ln_int)       := NULL;                                --����ŗ��Q
--        l_inc_tax_charge2_tab(ln_int) := NULL;                                --���������グ�z�Q
--        lt_bill_cust_code             := update_work_rec.bill_cust_code;      --�u���[�N�R�[�h�ݒ�(�ڋq�R�[�h)
--        lt_location_code              := update_work_rec.location_code;       --�u���[�N�R�[�h�ݒ�(�S�����_�R�[�h)
--      ELSE
--        --����ڋq�E�S�����_��2���R�[�h�ڈȍ~(2���R�[�h�ȏ�͐ݒ肵�Ȃ�)
--        ln_cust_cnt := ln_cust_cnt + 1;  --�u���[�N�������J�E���g�A�b�v
--        --1�ڋq�ɂ��ő�Q�̐ŕʍ��ڂ�ݒ�
--        IF ( ln_cust_cnt = 2 ) THEN
--          --�Q���R�[�h��
--          l_tax_rate2_tab(ln_int)       := update_work_rec.tax_rate;          --����ŗ��Q
--          l_inc_tax_charge2_tab(ln_int) := update_work_rec.tax_rate_by_sum;   --���������グ�z�Q
--        END IF;
--      END IF;
----
--    END LOOP edit_loop;
----
--    --�ꊇ�X�V
--    BEGIN
--      <<update_loop>>
--      FORALL i IN l_bill_cust_code_tab.FIRST..l_bill_cust_code_tab.LAST
--        UPDATE  xxcfr_rep_st_invoice_inc_tax_d  xrsi
--        SET     xrsi.tax_rate1        = l_tax_rate1_tab(i)
--               ,xrsi.inc_tax_charge1  = l_inc_tax_charge1_tab(i)
--               ,xrsi.tax_rate2        = l_tax_rate2_tab(i)
--               ,xrsi.inc_tax_charge2  = l_inc_tax_charge2_tab(i)
--        WHERE   xrsi.bill_cust_code   = l_bill_cust_code_tab(i)
--        AND     xrsi.location_code    = l_location_code_tab(i)
--        AND     xrsi.request_id       = cn_request_id
--        ;
--    EXCEPTION
--      WHEN OTHERS THEN
--        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg( cv_msg_kbn_cfr       -- 'XXCFR'
--                                                       ,cv_msg_003a18_026    -- �e�[�u���X�V�G���[
--                                                       ,cv_tkn_table         -- �g�[�N��'TABLE'
--                                                       ,xxcfr_common_pkg.get_table_comment(cv_table))
--                                                      -- �W���������Ŕ����[���[�N�e�[�u��
--                             ,1
--                             ,5000);
--        lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
--        RAISE global_api_expt;
--    END;
-- Mod 2016.09.06 Ver1.91 Start
    -- �o�^�f�[�^�����݂���A���ŕʓ���o�͂���̏ꍇ
--    IF ( gn_target_cnt <> 0 ) THEN
    IF ( gn_target_cnt <> 0 AND iv_tax_output_type = cv_tax_op_type_yes ) THEN
-- Mod 2016.09.06 Ver1.91 End
      <<edit_loop>>
      FOR update_work_rec IN update_work_cur LOOP
--
        --����A���́A�ڋq�R�[�h�E�S�����_�R�[�h���u���[�N
        IF (
             ( lt_bill_cust_code IS NULL )
             OR
             ( lt_bill_cust_code <> update_work_rec.bill_cust_code )
             OR
             ( lt_location_code  <> update_work_rec.location_code )
           )
        THEN
          --�������A�y�сA�P���R�[�h�ڂ̐ŕʍ��ڐݒ�
          ln_cust_cnt                   := 1;                                   --�u���[�N�����R�[�h����������
          ln_int                        := ln_int + 1;                          --�z��J�E���g�A�b�v
          l_bill_cust_code_tab(ln_int)  := update_work_rec.bill_cust_code;      --�ڋq�R�[�h
          l_location_code_tab(ln_int)   := update_work_rec.location_code;       --�S�����_�R�[�h
-- Modify 2019.09.03 Ver1.93 Start
--          l_tax_rate1_tab(ln_int)       := update_work_rec.tax_rate;            --����ŗ�1
          l_category1_tab(ln_int)       := update_work_rec.category;            --���󕪗ނP
-- Modify 2019.09.03 Ver1.93 End
          l_inc_tax_charge1_tab(ln_int) := update_work_rec.tax_rate_by_sum;     --���������グ�z�P
-- Modify 2019.09.03 Ver1.93 Start
--          l_tax_rate2_tab(ln_int)       := NULL;                                --����ŗ��Q
          l_category2_tab(ln_int)       := NULL;                                --���󕪗ނQ
-- Modify 2019.09.03 Ver1.93 End
          l_inc_tax_charge2_tab(ln_int) := NULL;                                --���������グ�z�Q
-- Add 2019.09.03 Ver1.93 Start
          l_category3_tab(ln_int)       := NULL;                                --���󕪗ނR
          l_inc_tax_charge3_tab(ln_int) := NULL;                                --���������グ�z�R
-- Add 2019.09.03 Ver1.93 End
          lt_bill_cust_code             := update_work_rec.bill_cust_code;      --�u���[�N�R�[�h�ݒ�(�ڋq�R�[�h)
          lt_location_code              := update_work_rec.location_code;       --�u���[�N�R�[�h�ݒ�(�S�����_�R�[�h)
        ELSE
          --����ڋq�E�S�����_��2���R�[�h�ڈȍ~(3���R�[�h�ȏ�͐ݒ肵�Ȃ�)
          ln_cust_cnt := ln_cust_cnt + 1;  --�u���[�N�������J�E���g�A�b�v
          --1�ڋq�ɂ��ő�Q�̐ŕʍ��ڂ�ݒ�
          IF ( ln_cust_cnt = 2 ) THEN
            --�Q���R�[�h��
-- Modify 2019.09.03 Ver1.93 Start
--            l_tax_rate2_tab(ln_int)       := update_work_rec.tax_rate;          --����ŗ��Q
            l_category2_tab(ln_int)       := update_work_rec.category;          --���󕪗ނQ
-- Modify 2019.09.03 Ver1.93 End
            l_inc_tax_charge2_tab(ln_int) := update_work_rec.tax_rate_by_sum;   --���������グ�z�Q
-- Add 2019.09.03 Ver1.93 Start
          ELSIF ( ln_cust_cnt = 3 ) THEN
            --�R���R�[�h��
            l_category3_tab(ln_int)       := update_work_rec.category;          --���󕪗ނR
            l_inc_tax_charge3_tab(ln_int) := update_work_rec.tax_rate_by_sum;   --���������グ�z�R
-- Add 2019.09.03 Ver1.93 End
          END IF;
        END IF;
--
      END LOOP edit_loop;
--
      --�ꊇ�X�V
      BEGIN
        <<update_loop>>
        FORALL i IN l_bill_cust_code_tab.FIRST..l_bill_cust_code_tab.LAST
          UPDATE  xxcfr_rep_st_invoice_inc_tax_d  xrsi
-- Modify 2019.09.03 Ver1.93 Start
--          SET     xrsi.tax_rate1        = l_tax_rate1_tab(i)
--                 ,xrsi.inc_tax_charge1  = l_inc_tax_charge1_tab(i)
--                 ,xrsi.tax_rate2        = l_tax_rate2_tab(i)
--                 ,xrsi.inc_tax_charge2  = l_inc_tax_charge2_tab(i)
          SET     xrsi.category1        = l_category1_tab(i)
                 ,xrsi.inc_tax_charge1  = l_inc_tax_charge1_tab(i)
                 ,xrsi.category2        = l_category2_tab(i)
                 ,xrsi.inc_tax_charge2  = l_inc_tax_charge2_tab(i)
                 ,xrsi.category3        = l_category3_tab(i)
                 ,xrsi.inc_tax_charge3  = l_inc_tax_charge3_tab(i)
-- Modify 2019.09.03 Ver1.93 End
          WHERE   xrsi.bill_cust_code   = l_bill_cust_code_tab(i)
          AND     xrsi.location_code    = l_location_code_tab(i)
          AND     xrsi.request_id       = cn_request_id
          ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg( cv_msg_kbn_cfr       -- 'XXCFR'
                                                         ,cv_msg_003a18_026    -- �e�[�u���X�V�G���[
                                                         ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                         ,xxcfr_common_pkg.get_table_comment(cv_table))
                                                        -- �W���������ō����[���[�N�e�[�u��
                               ,1
                               ,5000);
          lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_api_expt;
      END;
    END IF;
-- Mod 2015.07.31 Ver1.80 End
--
-- Add 2015.07.31 Ver1.80 Start
    -- 2.�ŕʂ̏���Ŋz�A�y�сA���������グ�z���v�Z���W���������ō����[�������P��A���[�N�e�[�u���w�b�_���X�V
-- Mod 2016.09.06 Ver1.91 Start
    -- ����0���t���OA��2�ł���A���ŕʓ���o�͂���̏ꍇ
--    IF ( gv_target_a_flag = cv_taget_flag_2 ) THEN
    IF ( gv_target_a_flag = cv_taget_flag_2 AND iv_tax_output_type = cv_tax_op_type_yes ) THEN
-- Mod 2016.09.06 Ver1.91 End
      -- �ϐ��̏�����
      ln_cust_cnt := 0;
      ln_int      := 0;
--
      <<edit_loop2>>
      FOR update_work_2_rec IN update_work_2_cur LOOP
--
        --����A���́A�ڋq�R�[�h�E�S�����_�R�[�h���u���[�N
        IF (
             ( lt_bill_cust_code2 IS NULL )
             OR
             ( lt_bill_cust_code2 <> update_work_2_rec.bill_cust_code )
             OR
             ( lt_location_code2  <> update_work_2_rec.location_code )
           )
        THEN
          --�������A�y�сA�P���R�[�h�ڂ̐ŕʍ��ڐݒ�
          ln_cust_cnt                      := 1;                                     -- �u���[�N�����R�[�h����������
          ln_int                           := ln_int + 1;                            -- �z��J�E���g�A�b�v
          l_bill_cust_code_2_tab(ln_int)   := update_work_2_rec.bill_cust_code;      -- �ڋq�R�[�h
          l_location_code_2_tab(ln_int)    := update_work_2_rec.location_code;       -- �S�����_�R�[�h
-- Modify 2019.09.03 Ver1.93 Start
--          l_tax_rate1_2_tab(ln_int)        := update_work_2_rec.tax_rate;            -- ����ŗ�(�ҏW�p)
          l_category1_2_tab(ln_int)        := update_work_2_rec.category;            -- ���󕪗ނP
-- Modify 2019.09.03 Ver1.93 End
          l_inc_tax_charge1_2_tab(ln_int)  := update_work_2_rec.tax_rate_by_sum;     -- ���������グ�z�P
-- Modify 2019.09.03 Ver1.93 Start
--          l_tax_rate2_2_tab(ln_int)        := NULL;                                  -- ����ŗ��Q
          l_category2_2_tab(ln_int)        := NULL;                                  -- ���󕪗ނQ
-- Modify 2019.09.03 Ver1.93 End
          l_inc_tax_charge2_2_tab(ln_int)  := NULL;                                  -- ���������グ�z�Q
-- Add 2019.09.03 Ver1.93 Start
          l_category3_2_tab(ln_int)        := NULL;                                  -- ���󕪗ނR
          l_inc_tax_charge3_2_tab(ln_int)  := NULL;                                  -- ���������グ�z�R
-- Add 2019.09.03 Ver1.93 End
          lt_bill_cust_code2               := update_work_2_rec.bill_cust_code;      -- �u���[�N�R�[�h�ݒ�(�ڋq�R�[�h)
          lt_location_code2                := update_work_2_rec.location_code;       -- �u���[�N�R�[�h�ݒ�(�S�����_�R�[�h)
        ELSE
          --����ڋq�E�S�����_��2���R�[�h�ڈȍ~(3���R�[�h�ȏ�͐ݒ肵�Ȃ�)
-- Modify 2019.09.03 Ver1.93 End
          ln_cust_cnt := ln_cust_cnt + 1;  --�u���[�N�������J�E���g�A�b�v
          --1�ڋq�ɂ��ő�Q�̐ŕʍ��ڂ�ݒ�
          IF ( ln_cust_cnt = 2 ) THEN
            --�Q���R�[�h��
-- Modify 2019.09.03 Ver1.93 Start
--            l_tax_rate2_2_tab(ln_int)       := update_work_2_rec.tax_rate;            -- ����ŗ��Q
            l_category2_2_tab(ln_int)       := update_work_2_rec.category;            -- ���󕪗ނQ
-- Modify 2019.09.03 Ver1.93 End
            l_inc_tax_charge2_2_tab(ln_int) := update_work_2_rec.tax_rate_by_sum;     -- ���������グ�z�Q
-- Add 2019.09.03 Ver1.93 Start
          ELSIF ( ln_cust_cnt = 3 ) THEN
            --�R���R�[�h��
            l_category3_2_tab(ln_int)       := update_work_2_rec.category;            --���󕪗ނR
            l_inc_tax_charge3_2_tab(ln_int) := update_work_2_rec.tax_rate_by_sum;     --���������グ�z�R
-- Add 2019.09.03 Ver1.93 End
          END IF;
        END IF;
--
      END LOOP edit_loop2;
--
      --�ꊇ�X�V
      BEGIN
        <<update_loop2>>
        FORALL i IN l_bill_cust_code_2_tab.FIRST..l_bill_cust_code_2_tab.LAST
          UPDATE  xxcfr_rep_st_inv_inc_tax_a_h  xrsiah
-- Modify 2019.09.03 Ver1.93 Start
--          SET     xrsiah.tax_rate1        = l_tax_rate1_2_tab(i)        -- ����ŗ�1
--                 ,xrsiah.inc_tax_charge1  = l_inc_tax_charge1_2_tab(i)  -- ���������グ�z�P
--                 ,xrsiah.tax_rate2        = l_tax_rate2_2_tab(i)        -- ����ŗ��Q
--                 ,xrsiah.inc_tax_charge2  = l_inc_tax_charge2_2_tab(i)  -- ���������グ�z�Q
          SET     xrsiah.category1        = l_category1_2_tab(i)        -- ���󕪗ނP
                 ,xrsiah.inc_tax_charge1  = l_inc_tax_charge1_2_tab(i)  -- ���������グ�z�P
                 ,xrsiah.category2        = l_category2_2_tab(i)        -- ���󕪗ނQ
                 ,xrsiah.inc_tax_charge2  = l_inc_tax_charge2_2_tab(i)  -- ���������グ�z�Q
                 ,xrsiah.category3        = l_category3_2_tab(i)        -- ���󕪗ނR
                 ,xrsiah.inc_tax_charge3  = l_inc_tax_charge3_2_tab(i)  -- ���������グ�z�R
-- Modify 2019.09.03 Ver1.93 End
          WHERE   xrsiah.bill_cust_code   = l_bill_cust_code_2_tab(i)
          AND     xrsiah.location_code    = l_location_code_2_tab(i)
          AND     xrsiah.request_id       = cn_request_id
          ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg( cv_msg_kbn_cfr       -- 'XXCFR'
                                                         ,cv_msg_003a18_026    -- �e�[�u���X�V�G���[
                                                         ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                         ,xxcfr_common_pkg.get_table_comment(cv_table_a_h))
                                                        -- �W���������ō����[�������P��A���[�N�e�[�u���w�b�_�[
                               ,1
                               ,5000);
          lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_api_expt;
      END;
--
      -- 3.�ŕʂ̏���Ŋz�A�y�сA���������グ�z���v�Z���W���������ō����[�������P��A���[�N�e�[�u�����ׂ��X�V
      -- �ϐ��̏�����
      ln_cust_cnt := 0;
      ln_int      := 0;
--
      <<edit_loop3>>
      FOR update_work_3_rec IN update_work_3_cur LOOP
--
        --����A���́A�ڋq�R�[�h�E�S�����_�R�[�h�E�[�i��ڋq�R�[�h���u���[�N
        IF (
             ( lt_bill_cust_code3 IS NULL )
             OR
             ( lt_bill_cust_code3 <> update_work_3_rec.bill_cust_code )
             OR
             ( lt_location_code3  <> update_work_3_rec.location_code )
             OR
             ( lt_ship_cust_code3 <> update_work_3_rec.ship_cust_code )
           )
        THEN
          --�������A�y�сA�P���R�[�h�ڂ̐ŕʍ��ڐݒ�
          ln_cust_cnt                     := 1;                                     -- �u���[�N�����R�[�h����������
          ln_int                          := ln_int + 1;                            -- �z��J�E���g�A�b�v
          l_bill_cust_code_3_tab(ln_int)  := update_work_3_rec.bill_cust_code;      -- �ڋq�R�[�h
          l_location_code_3_tab(ln_int)   := update_work_3_rec.location_code;       -- �S�����_�R�[�h
          l_ship_cust_code_3_tab(ln_int)  := update_work_3_rec.ship_cust_code;      -- �[�i��ڋq�R�[�h
-- Modify 2019.09.03 Ver1.93 Start
--          l_tax_rate1_3_tab(ln_int)       := update_work_3_rec.tax_rate;            -- ����ŗ�(�ҏW�p)
          l_category1_3_tab(ln_int)       := update_work_3_rec.category;            -- ���󕪗ނP
-- Modify 2019.09.03 Ver1.93 End
          l_inc_tax_charge1_3_tab(ln_int) := update_work_3_rec.tax_rate_by_sum;     -- ���������グ�z�P
-- Modify 2019.09.03 Ver1.93 Start
--          l_tax_rate2_3_tab(ln_int)       := NULL;                                  -- ����ŗ��Q
          l_category2_3_tab(ln_int)       := NULL;                                  -- ���󕪗ނQ
-- Modify 2019.09.03 Ver1.93 End
          l_inc_tax_charge2_3_tab(ln_int) := NULL;                                  -- ���������グ�z�Q
-- Add 2019.09.03 Ver1.93 Start
          l_category3_3_tab(ln_int)       := NULL;                                  -- ���󕪗ނR
          l_inc_tax_charge3_3_tab(ln_int) := NULL;                                  -- ���������グ�z�R
-- Add 2019.09.03 Ver1.93 End
          lt_bill_cust_code3              := update_work_3_rec.bill_cust_code;      -- �u���[�N�R�[�h�ݒ�(�ڋq�R�[�h)
          lt_location_code3               := update_work_3_rec.location_code;       -- �u���[�N�R�[�h�ݒ�(�S�����_�R�[�h)
          lt_ship_cust_code3              := update_work_3_rec.ship_cust_code;      -- �u���[�N�R�[�h�ݒ�(�[�i��ڋq�R�[�h)
        ELSE
-- Modify 2019.09.03 Ver1.93 Start
--          --����ڋq�E�S�����_�E�[�i��ڋq�R�[�h��2���R�[�h�ڈȍ~(2���R�[�h�ȏ�͐ݒ肵�Ȃ�)
          --����ڋq�E�S�����_�E�[�i��ڋq�R�[�h��2���R�[�h�ڈȍ~(3���R�[�h�ȏ�͐ݒ肵�Ȃ�)
-- Modify 2019.09.03 Ver1.93 End
          ln_cust_cnt := ln_cust_cnt + 1;  --�u���[�N�������J�E���g�A�b�v
          --1�X�܂ɂ��ő�Q�̐ŕʍ��ڂ�ݒ�
          IF ( ln_cust_cnt = 2 ) THEN
            --�Q���R�[�h��
-- Modify 2019.09.03 Ver1.93 Start
--            l_tax_rate2_3_tab(ln_int)       := update_work_3_rec.tax_rate;            -- ����ŗ��Q
            l_category2_3_tab(ln_int)       := update_work_3_rec.category;            -- ���󕪗ނQ
-- Modify 2019.09.03 Ver1.93 End
            l_inc_tax_charge2_3_tab(ln_int) := update_work_3_rec.tax_rate_by_sum;     -- ���������グ�z�Q
-- Add 2019.09.03 Ver1.93 Start
          ELSIF ( ln_cust_cnt = 3 ) THEN
            --�R���R�[�h��
            l_category3_3_tab(ln_int)       := update_work_3_rec.category;            --���󕪗ނR
            l_inc_tax_charge3_3_tab(ln_int) := update_work_3_rec.tax_rate_by_sum;     --���������グ�z�R
-- Add 2019.09.03 Ver1.93 End
          END IF;
        END IF;
--
      END LOOP edit_loop3;
--
      --�ꊇ�X�V
      BEGIN
        <<update_loop3>>
        FORALL i IN l_bill_cust_code_3_tab.FIRST..l_bill_cust_code_3_tab.LAST
          UPDATE  xxcfr_rep_st_inv_inc_tax_a_l  xrsial
-- Modify 2019.09.03 Ver1.93 Start
--          SET     xrsial.tax_rate1        = l_tax_rate1_3_tab(i)        -- ����ŗ�1
--                 ,xrsial.inc_tax_charge1  = l_inc_tax_charge1_3_tab(i)  -- ���������グ�z�P
--                 ,xrsial.tax_rate2        = l_tax_rate2_3_tab(i)        -- ����ŗ��Q
--                 ,xrsial.inc_tax_charge2  = l_inc_tax_charge2_3_tab(i)  -- ���������グ�z�Q
          SET      xrsial.category1       = l_category1_3_tab(i)        -- ���󕪗ނP
                  ,xrsial.inc_tax_charge1 = l_inc_tax_charge1_3_tab(i)  -- ���������グ�z�P
                  ,xrsial.category2       = l_category2_3_tab(i)        -- ���󕪗ނQ
                  ,xrsial.inc_tax_charge2 = l_inc_tax_charge2_3_tab(i)  -- ���������グ�z�Q
                  ,xrsial.category3       = l_category3_3_tab(i)        -- ���󕪗ނQ
                  ,xrsial.inc_tax_charge3 = l_inc_tax_charge3_3_tab(i)  -- ���������グ�z�R
-- Modify 2019.09.03 Ver1.93 End
          WHERE   xrsial.bill_cust_code   = l_bill_cust_code_3_tab(i)
          AND     xrsial.location_code    = l_location_code_3_tab(i)
          AND     xrsial.ship_cust_code   = l_ship_cust_code_3_tab(i)
          AND     xrsial.request_id       = cn_request_id
          ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg( cv_msg_kbn_cfr       -- 'XXCFR'
                                                         ,cv_msg_003a18_026    -- �e�[�u���X�V�G���[
                                                         ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                         ,xxcfr_common_pkg.get_table_comment(cv_table_a_l))
                                                        -- �W���������ō����[�������P��A���[�N�e�[�u������
                               ,1
                               ,5000);
          lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_api_expt;
      END;
--
-- Add 2016.09.06 Ver1.91 Start
    END IF;
--
    -- -- ����0���t���OA��2�ł���ꍇ
    IF ( gv_target_a_flag = cv_taget_flag_2 ) THEN
-- Add 2016.09.06 Ver1.91 End
      -- 4.���������グ�z�Ə���Ŋz���v�Z���W���������ō����[�������P��A���[�N�e�[�u�����ׂ��X�V
      -- �ϐ��̏�����
      ln_int      := 0;
--
      <<edit_loop4>>
      FOR update_work_4_rec IN update_work_4_cur LOOP
        ln_int                          := ln_int + 1;                            -- �z��J�E���g�A�b�v
        l_bill_cust_code_4_tab(ln_int)  := update_work_4_rec.bill_cust_code;      -- �ڋq�R�[�h
        l_location_code_4_tab(ln_int)   := update_work_4_rec.location_code;       -- �S�����_�R�[�h
        l_ship_cust_code_4_tab(ln_int)  := update_work_4_rec.ship_cust_code;      -- �[�i��ڋq�R�[�h
        l_store_sum_4_tab(ln_int)       := update_work_4_rec.store_sum;           -- �����������z�i�ō��j
      END LOOP edit_loop4;
--
      --�ꊇ�X�V
      BEGIN
        <<update_loop4>>
        FORALL i IN l_bill_cust_code_4_tab.FIRST..l_bill_cust_code_4_tab.LAST
          UPDATE  xxcfr_rep_st_inv_inc_tax_a_l  xrsial
          SET     xrsial.store_sum        = l_store_sum_4_tab(i)        -- �����������z�i�ō��j
          WHERE   xrsial.bill_cust_code   = l_bill_cust_code_4_tab(i)
          AND     xrsial.location_code    = l_location_code_4_tab(i)
          AND     xrsial.ship_cust_code   = l_ship_cust_code_4_tab(i)
          AND     xrsial.request_id       = cn_request_id
          ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg( cv_msg_kbn_cfr       -- 'XXCFR'
                                                         ,cv_msg_003a18_026    -- �e�[�u���X�V�G���[
                                                         ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                         ,xxcfr_common_pkg.get_table_comment(cv_table_a_l))
                                                        -- �W���������ō����[�������P��A���[�N�e�[�u���w�b�_�[
                               ,1
                               ,5000);
          lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_api_expt;
      END;
    END IF;
--
-- Mod 2016.09.06 Ver1.91 Start
    -- ����0���t���OB��2�ł���A���ŕʓ���o�͂���̏ꍇ
--    IF ( gv_target_b_flag = cv_taget_flag_2 ) THEN
    IF ( gv_target_b_flag = cv_taget_flag_2 AND iv_tax_output_type = cv_tax_op_type_yes ) THEN
-- Mod 2016.09.06 Ver1.91 End
      -- 5.�ŕʂ̏���Ŋz�A�y�сA���������グ�z���v�Z���W���������ō����[�������P��B���[�N�e�[�u���w�b�_���X�V
      -- �ϐ��̏�����
      ln_cust_cnt := 0;
      ln_int      := 0;
--
      <<edit_loop5>>
      FOR update_work_5_rec IN update_work_5_cur LOOP
--
        --����A���́A�ڋq�R�[�h�E�S�����_�R�[�h���u���[�N
        IF (
             ( lt_bill_cust_code5 IS NULL )
             OR
             ( lt_bill_cust_code5 <> update_work_5_rec.bill_cust_code )
             OR
             ( lt_location_code5  <> update_work_5_rec.location_code )
           )
        THEN
          --�������A�y�сA�P���R�[�h�ڂ̐ŕʍ��ڐݒ�
          ln_cust_cnt                     := 1;                                     -- �u���[�N�����R�[�h����������
          ln_int                          := ln_int + 1;                            -- �z��J�E���g�A�b�v
          l_bill_cust_code_5_tab(ln_int)  := update_work_5_rec.bill_cust_code;      -- �ڋq�R�[�h
          l_location_code_5_tab(ln_int)   := update_work_5_rec.location_code;       -- �S�����_�R�[�h
-- Modify 2019.09.03 Ver1.93 Start
--          l_tax_rate1_5_tab(ln_int)       := update_work_5_rec.tax_rate;            -- ����ŗ�(�ҏW�p)
          l_category1_5_tab(ln_int)       := update_work_5_rec.category;            -- ���󕪗ނP
-- Modify 2019.09.03 Ver1.93 End
          l_inc_tax_charge1_5_tab(ln_int) := update_work_5_rec.tax_rate_by_sum;     -- ���������グ�z�P
-- Modify 2019.09.03 Ver1.93 Start
--          l_tax_rate2_5_tab(ln_int)       := NULL;                                  -- ����ŗ��Q
          l_category2_5_tab(ln_int)       := NULL;                                  -- ���󕪗ނQ
-- Modify 2019.09.03 Ver1.93 End
          l_inc_tax_charge2_5_tab(ln_int) := NULL;                                  -- ���������グ�z�Q
-- Add 2019.09.03 Ver1.93 Start
          l_category3_5_tab(ln_int)       := NULL;                                  -- ���󕪗ނR
          l_inc_tax_charge3_5_tab(ln_int) := NULL;                                  -- ���������グ�z�R
-- Add 2019.09.03 Ver1.93 End
          lt_bill_cust_code5              := update_work_5_rec.bill_cust_code;      -- �u���[�N�R�[�h�ݒ�(�ڋq�R�[�h)
          lt_location_code5               := update_work_5_rec.location_code;       -- �u���[�N�R�[�h�ݒ�(�S�����_�R�[�h)
        ELSE
          --����ڋq�E�S�����_��2���R�[�h�ڈȍ~(3���R�[�h�ȏ�͐ݒ肵�Ȃ�)
          ln_cust_cnt := ln_cust_cnt + 1;  --�u���[�N�������J�E���g�A�b�v
          --1�ڋq�ɂ��ő�Q�̐ŕʍ��ڂ�ݒ�
          IF ( ln_cust_cnt = 2 ) THEN
            --�Q���R�[�h��
-- Modify 2019.09.03 Ver1.93 Start
--            l_tax_rate2_5_tab(ln_int)       := update_work_5_rec.tax_rate;            -- ����ŗ��Q
            l_category2_5_tab(ln_int)       := update_work_5_rec.category;            -- ���󕪗ނQ
-- Modify 2019.09.03 Ver1.93 End
            l_inc_tax_charge2_5_tab(ln_int) := update_work_5_rec.tax_rate_by_sum;     -- ���������グ�z�Q
-- Add 2019.09.03 Ver1.93 Start
          ELSIF ( ln_cust_cnt = 3 ) THEN
            --�R���R�[�h��
            l_category3_5_tab(ln_int)       := update_work_5_rec.category;            --���󕪗ނR
            l_inc_tax_charge3_5_tab(ln_int) := update_work_5_rec.tax_rate_by_sum;     --���������グ�z�R
-- Add 2019.09.03 Ver1.93 End
          END IF;
        END IF;
--
      END LOOP edit_loop5;
--
      --�ꊇ�X�V
      BEGIN
        <<update_loop5>>
        FORALL i IN l_bill_cust_code_5_tab.FIRST..l_bill_cust_code_5_tab.LAST
          UPDATE  xxcfr_rep_st_inv_inc_tax_b_h  xrsibh
-- Modify 2019.09.03 Ver1.93 Start
--          SET     xrsibh.tax_rate1        = l_tax_rate1_5_tab(i)        -- ����ŗ�1
--                 ,xrsibh.inc_tax_charge1  = l_inc_tax_charge1_5_tab(i)  -- ���������グ�z�P
--                 ,xrsibh.tax_rate2        = l_tax_rate2_5_tab(i)        -- ����ŗ��Q
--                 ,xrsibh.inc_tax_charge2  = l_inc_tax_charge2_5_tab(i)  -- ���������グ�z�Q
          SET     xrsibh.category1        = l_category1_5_tab(i)        -- ���󕪗ނP
                 ,xrsibh.inc_tax_charge1  = l_inc_tax_charge1_5_tab(i)  -- ���������グ�z�P
                 ,xrsibh.category2        = l_category2_5_tab(i)        -- ���󕪗ނQ
                 ,xrsibh.inc_tax_charge2  = l_inc_tax_charge2_5_tab(i)  -- ���������グ�z�Q
                 ,xrsibh.category3        = l_category3_5_tab(i)        -- ���󕪗ނR
                 ,xrsibh.inc_tax_charge3  = l_inc_tax_charge3_5_tab(i)  -- ���������グ�z�R
-- Modify 2019.09.03 Ver1.93 End
          WHERE   xrsibh.bill_cust_code   = l_bill_cust_code_5_tab(i)
          AND     xrsibh.location_code    = l_location_code_5_tab(i)
          AND     xrsibh.request_id       = cn_request_id
          ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg( cv_msg_kbn_cfr       -- 'XXCFR'
                                                         ,cv_msg_003a18_026    -- �e�[�u���X�V�G���[
                                                         ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                         ,xxcfr_common_pkg.get_table_comment(cv_table_b_h))
                                                        -- �W���������ō����[�������P��B���[�N�e�[�u���w�b�_�[
                               ,1
                               ,5000);
          lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_api_expt;
      END;
--
      -- 6.�ŕʂ̏���Ŋz�A�y�сA���������グ�z���v�Z���W���������ō����[�������P��B���[�N�e�[�u�����ׂ��X�V
      -- �ϐ��̏�����
      ln_cust_cnt := 0;
      ln_int      := 0;
--
      <<edit_loop6>>
      FOR update_work_6_rec IN update_work_6_cur LOOP
--
        --����A���́A�ڋq�R�[�h�E�S�����_�R�[�h�E�[�i��ڋq�R�[�h���u���[�N
        IF (
             ( lt_bill_cust_code6 IS NULL )
             OR
             ( lt_bill_cust_code6 <> update_work_6_rec.bill_cust_code )
             OR
             ( lt_location_code6  <> update_work_6_rec.location_code )
             OR
             ( lt_ship_cust_code6 <> update_work_6_rec.ship_cust_code )
           )
        THEN
          --�������A�y�сA�P���R�[�h�ڂ̐ŕʍ��ڐݒ�
          ln_cust_cnt                     := 1;                                     -- �u���[�N�����R�[�h����������
          ln_int                          := ln_int + 1;                            -- �z��J�E���g�A�b�v
          l_bill_cust_code_6_tab(ln_int)  := update_work_6_rec.bill_cust_code;      -- �ڋq�R�[�h
          l_location_code_6_tab(ln_int)   := update_work_6_rec.location_code;       -- �S�����_�R�[�h
          l_ship_cust_code_6_tab(ln_int)  := update_work_6_rec.ship_cust_code;      -- �[�i��ڋq�R�[�h
-- Modify 2019.09.03 Ver1.93 Start
--          l_tax_rate1_6_tab(ln_int)       := update_work_6_rec.tax_rate;            -- ����ŗ�(�ҏW�p)
          l_category1_6_tab(ln_int)       := update_work_6_rec.category;            -- ���󕪗ނP
-- Modify 2019.09.03 Ver1.93 End
          l_inc_tax_charge1_6_tab(ln_int) := update_work_6_rec.tax_rate_by_sum;     -- ���������グ�z�P
-- Modify 2019.09.03 Ver1.93 Start
--          l_tax_rate2_6_tab(ln_int)       := NULL;                                  -- ����ŗ��Q
          l_category2_6_tab(ln_int)       := NULL;                                  -- ���󕪗ނQ
-- Modify 2019.09.03 Ver1.93 End
          l_inc_tax_charge2_6_tab(ln_int) := NULL;                                  -- ���������グ�z�Q
-- Add 2019.09.03 Ver1.93 Start
          l_category3_6_tab(ln_int)       := NULL;                                  -- ���󕪗ނR
          l_inc_tax_charge3_6_tab(ln_int) := NULL;                                  -- ���������グ�z�R
-- Add 2019.09.03 Ver1.93 End
          lt_bill_cust_code6              := update_work_6_rec.bill_cust_code;      -- �u���[�N�R�[�h�ݒ�(�ڋq�R�[�h)
          lt_location_code6               := update_work_6_rec.location_code;       -- �u���[�N�R�[�h�ݒ�(�S�����_�R�[�h)
          lt_ship_cust_code6              := update_work_6_rec.ship_cust_code;      -- �u���[�N�R�[�h�ݒ�(�[�i��ڋq�R�[�h)
        ELSE
          --����ڋq�E�S�����_�E�[�i��ڋq�R�[�h��2���R�[�h�ڈȍ~(3���R�[�h�ȏ�͐ݒ肵�Ȃ�)
          ln_cust_cnt := ln_cust_cnt + 1;  --�u���[�N�������J�E���g�A�b�v
          --1�X�܂ɂ��ő�Q�̐ŕʍ��ڂ�ݒ�
          IF ( ln_cust_cnt = 2 ) THEN
            --�Q���R�[�h��
-- Modify 2019.09.03 Ver1.93 Start
--            l_tax_rate2_6_tab(ln_int)       := update_work_6_rec.tax_rate;            -- ����ŗ��Q
            l_category2_6_tab(ln_int)       := update_work_6_rec.category;            -- ���󕪗ނQ
-- Modify 2019.09.03 Ver1.93 End
            l_inc_tax_charge2_6_tab(ln_int) := update_work_6_rec.tax_rate_by_sum;     -- ���������グ�z�Q
-- Add 2019.09.03 Ver1.93 Start
          ELSIF ( ln_cust_cnt = 3 ) THEN
            --�R���R�[�h��
            l_category3_6_tab(ln_int)       := update_work_6_rec.category;            --���󕪗ނR
            l_inc_tax_charge3_6_tab(ln_int) := update_work_6_rec.tax_rate_by_sum;     --���������グ�z�R
-- Add 2019.09.03 Ver1.93 End
          END IF;
        END IF;
--
      END LOOP edit_loop6;
--
      --�ꊇ�X�V
      BEGIN
        <<update_loop6>>
        FORALL i IN l_bill_cust_code_6_tab.FIRST..l_bill_cust_code_6_tab.LAST
          UPDATE  xxcfr_rep_st_inv_inc_tax_b_l  xrsibl
-- Modify 2019.09.03 Ver1.93 Start
--          SET     xrsibl.tax_rate1        = l_tax_rate1_6_tab(i)        -- ����ŗ�1
--                 ,xrsibl.inc_tax_charge1  = l_inc_tax_charge1_6_tab(i)  -- ���������グ�z�P
--                 ,xrsibl.tax_rate2        = l_tax_rate2_6_tab(i)        -- ����ŗ��Q
--                 ,xrsibl.inc_tax_charge2  = l_inc_tax_charge2_6_tab(i)  -- ���������グ�z�Q
          SET     xrsibl.category1        = l_category1_6_tab(i)        -- ���󕪗ނP
                 ,xrsibl.inc_tax_charge1  = l_inc_tax_charge1_6_tab(i)  -- ���������グ�z�P
                 ,xrsibl.category2        = l_category2_6_tab(i)        -- ���󕪗ނQ
                 ,xrsibl.inc_tax_charge2  = l_inc_tax_charge2_6_tab(i)  -- ���������グ�z�Q
                 ,xrsibl.category3        = l_category3_6_tab(i)        -- ���󕪗ނR
                 ,xrsibl.inc_tax_charge3  = l_inc_tax_charge3_6_tab(i)  -- ���������グ�z�R
-- Modify 2019.09.03 Ver1.93 End
          WHERE   xrsibl.bill_cust_code   = l_bill_cust_code_6_tab(i)
          AND     xrsibl.location_code    = l_location_code_6_tab(i)
          AND     xrsibl.ship_cust_code   = l_ship_cust_code_6_tab(i)
          AND     xrsibl.request_id       = cn_request_id
          ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg( cv_msg_kbn_cfr       -- 'XXCFR'
                                                         ,cv_msg_003a18_026    -- �e�[�u���X�V�G���[
                                                         ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                         ,xxcfr_common_pkg.get_table_comment(cv_table_b_l))
                                                        -- �W���������ō����[�������P��B���[�N�e�[�u������
                               ,1
                               ,5000);
          lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_api_expt;
      END;
--
-- Add 2016.09.06 Ver1.91 Start
    END IF;
--
    -- -- ����0���t���OB��2�ł���ꍇ
    IF ( gv_target_b_flag = cv_taget_flag_2 ) THEN
-- Add 2016.09.06 Ver1.91 End
      -- 7.���������グ�z�Ə���Ŋz���v�Z���W���������ō����[�������P��B���[�N�e�[�u�����ׂ��X�V
      -- �ϐ��̏�����
      ln_int      := 0;
--
      <<edit_loop7>>
      FOR update_work_7_rec IN update_work_7_cur LOOP
        ln_int                          := ln_int + 1;                            -- �z��J�E���g�A�b�v
        l_bill_cust_code_7_tab(ln_int)  := update_work_7_rec.bill_cust_code;      -- �ڋq�R�[�h
        l_location_code_7_tab(ln_int)   := update_work_7_rec.location_code;       -- �S�����_�R�[�h
        l_ship_cust_code_7_tab(ln_int)  := update_work_7_rec.ship_cust_code;      -- �[�i��ڋq�R�[�h
        l_store_sum_7_tab(ln_int)       := update_work_7_rec.store_sum;           -- �����������z�i�ō��j
      END LOOP edit_loop7;
--
      --�ꊇ�X�V
      BEGIN
        <<update_loop7>>
        FORALL i IN l_bill_cust_code_7_tab.FIRST..l_bill_cust_code_7_tab.LAST
          UPDATE  xxcfr_rep_st_inv_inc_tax_b_l  xrsibl
          SET     xrsibl.store_sum        = l_store_sum_7_tab(i)        -- �����������z�i�ō��j
          WHERE   xrsibl.bill_cust_code   = l_bill_cust_code_7_tab(i)
          AND     xrsibl.location_code    = l_location_code_7_tab(i)
          AND     xrsibl.ship_cust_code   = l_ship_cust_code_7_tab(i)
          AND     xrsibl.request_id       = cn_request_id
          ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg( cv_msg_kbn_cfr       -- 'XXCFR'
                                                         ,cv_msg_003a18_026    -- �e�[�u���X�V�G���[
                                                         ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                         ,xxcfr_common_pkg.get_table_comment(cv_table_b_l))
                                                        -- �W���������ō����[�������P��B���[�N�e�[�u������
                               ,1
                               ,5000);
          lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_api_expt;
      END;
    END IF;
--
-- Add 2016.03.31 Ver1.90 Start
    -- 8.�ŕʂ̏���Ŋz�A�y�сA���������グ�z���v�Z���A
    --   �W���������ō����[�������P��C���[�N�e�[�u���w�b�_��
    --   �W���������ō����[�������P��C���[�N�e�[�u�����ׂ��X�V
-- Mod 2016.09.06 Ver1.91 Start
    -- ����0���t���OC��2�ł���A���ŕʓ���o�͂���̏ꍇ
--    IF ( gv_target_c_flag = cv_taget_flag_2 ) THEN
    IF ( gv_target_c_flag = cv_taget_flag_2 AND iv_tax_output_type = cv_tax_op_type_yes ) THEN
-- Mod 2016.09.06 Ver1.91 End
      -- �ϐ��̏�����
      ln_cust_cnt := 0;
      ln_int      := 0;
--
      <<edit_loop8>>
      FOR update_work_8_rec IN update_work_8_cur LOOP
--
        --����A���́A�ڋq�R�[�h�E�S�����_�R�[�h���u���[�N
        IF (
             ( lt_bill_cust_code8 IS NULL )
             OR
             ( lt_bill_cust_code8 <> update_work_8_rec.bill_cust_code )
             OR
             ( lt_location_code8  <> update_work_8_rec.location_code )
           )
        THEN
          --�������A�y�сA�P���R�[�h�ڂ̐ŕʍ��ڐݒ�
          ln_cust_cnt                      := 1;                                     -- �u���[�N�����R�[�h����������
          ln_int                           := ln_int + 1;                            -- �z��J�E���g�A�b�v
          l_bill_cust_code_8_tab(ln_int)   := update_work_8_rec.bill_cust_code;      -- �ڋq�R�[�h
          l_location_code_8_tab(ln_int)    := update_work_8_rec.location_code;       -- �S�����_�R�[�h
-- Modify 2019.09.03 Ver1.93 Start
--          l_tax_rate1_8_tab(ln_int)        := update_work_8_rec.tax_rate;            -- ����ŗ�(�ҏW�p)
          l_category1_8_tab(ln_int)        := update_work_8_rec.category;            -- ���󕪗ނP
-- Modify 2019.09.03 Ver1.93 End
          l_inc_tax_charge1_8_tab(ln_int)  := update_work_8_rec.tax_rate_by_sum;     -- ���������グ�z�P
-- Modify 2019.09.03 Ver1.93 Start
--          l_tax_rate2_8_tab(ln_int)        := NULL;                                  -- ����ŗ��Q
          l_category2_8_tab(ln_int)        :=  NULL;                                 -- ���󕪗ނQ
-- Modify 2019.09.03 Ver1.93 End
          l_inc_tax_charge2_8_tab(ln_int)  := NULL;                                  -- ���������グ�z�Q
-- Add 2019.09.03 Ver1.93 Start
          l_category3_8_tab(ln_int)        := NULL;                                  -- ���󕪗ނR
          l_inc_tax_charge3_8_tab(ln_int)  := NULL;                                  -- ���������グ�z�R
-- Add 2019.09.03 Ver1.93 End
          lt_bill_cust_code8               := update_work_8_rec.bill_cust_code;      -- �u���[�N�R�[�h�ݒ�(�ڋq�R�[�h)
          lt_location_code8                := update_work_8_rec.location_code;       -- �u���[�N�R�[�h�ݒ�(�S�����_�R�[�h)
        ELSE
          --����ڋq�E�S�����_��2���R�[�h�ڈȍ~(3���R�[�h�ȏ�͐ݒ肵�Ȃ�)
          ln_cust_cnt := ln_cust_cnt + 1;  --�u���[�N�������J�E���g�A�b�v
          --1�ڋq�ɂ��ő�Q�̐ŕʍ��ڂ�ݒ�
          IF ( ln_cust_cnt = 2 ) THEN
            --�Q���R�[�h��
-- Modify 2019.09.03 Ver1.93 Start
--            l_tax_rate2_8_tab(ln_int)       := update_work_8_rec.tax_rate;            -- ����ŗ��Q
            l_category2_8_tab(ln_int)       := update_work_8_rec.category;           -- ���󕪗ނQ
-- Modify 2019.09.03 Ver1.93 End
            l_inc_tax_charge2_8_tab(ln_int) := update_work_8_rec.tax_rate_by_sum;    -- ���������グ�z�Q
-- Add 2019.09.03 Ver1.93 Start
          ELSIF ( ln_cust_cnt = 3 ) THEN
            --�R���R�[�h��
            l_category3_8_tab(ln_int)       := update_work_8_rec.category;           --���󕪗ނR
            l_inc_tax_charge3_8_tab(ln_int) := update_work_8_rec.tax_rate_by_sum;     --���������グ�z�R
-- Add 2019.09.03 Ver1.93 End
          END IF;
        END IF;
--
      END LOOP edit_loop8;
--
      -- �W���������ō����[�������P��C���[�N�e�[�u���w�b�_�̈ꊇ�X�V
      BEGIN
        <<update_loop8>>
        FORALL i IN l_bill_cust_code_8_tab.FIRST..l_bill_cust_code_8_tab.LAST
          UPDATE  xxcfr_rep_st_inv_inc_tax_c_h  xrsich
-- Modify 2019.09.03 Ver1.93 Start
--          SET     xrsich.tax_rate1        = l_tax_rate1_8_tab(i)        -- ����ŗ�1
--                 ,xrsich.inc_tax_charge1  = l_inc_tax_charge1_8_tab(i)  -- ���������グ�z�P
--                 ,xrsich.tax_rate2        = l_tax_rate2_8_tab(i)        -- ����ŗ��Q
--                 ,xrsich.inc_tax_charge2  = l_inc_tax_charge2_8_tab(i)  -- ���������グ�z�Q
          SET     xrsich.category1        = l_category1_8_tab(i)        -- ���󕪗ނP
                 ,xrsich.inc_tax_charge1  = l_inc_tax_charge1_8_tab(i)  -- ���������グ�z�P
                 ,xrsich.category2        = l_category2_8_tab(i)        -- ���󕪗ނQ
                 ,xrsich.inc_tax_charge2  = l_inc_tax_charge2_8_tab(i)  -- ���������グ�z�Q
                 ,xrsich.category3        = l_category3_8_tab(i)        -- ���󕪗ނR
                 ,xrsich.inc_tax_charge3  = l_inc_tax_charge3_8_tab(i)  -- ���������グ�z�R
-- Modify 2019.09.03 Ver1.93 END
          WHERE   xrsich.bill_cust_code   = l_bill_cust_code_8_tab(i)
          AND     xrsich.location_code    = l_location_code_8_tab(i)
          AND     xrsich.request_id       = cn_request_id
          ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg( cv_msg_kbn_cfr       -- 'XXCFR'
                                                         ,cv_msg_003a18_026    -- �e�[�u���X�V�G���[
                                                         ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                         ,xxcfr_common_pkg.get_table_comment(cv_table_c_h))
                                                        -- �W���������ō����[�������P��C���[�N�e�[�u���w�b�_
                               ,1
                               ,5000);
          lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_api_expt;
      END;
    END IF;
--
-- Add 2016.03.31 Ver1.90 End
-- Add 2015.07.31 Ver1.80 End
-- Ver.1.92 [��QE_�{�ғ�_15307] ADD START
    -- ����0���t���OD��2�ł���A���ŕʓ���o�͂���̏ꍇ
    IF ( gv_target_d_flag = cv_taget_flag_2 AND iv_tax_output_type = cv_tax_op_type_yes ) THEN
      -- 9.�ŕʂ̏���Ŋz�A�y�сA���������グ�z���v�Z���W���������ō����[�������P��D���[�N�e�[�u�����ׂ��X�V
      -- �ϐ��̏�����
      ln_cust_cnt := 0;
      ln_int      := 0;
--
      <<edit_loop9>>
      FOR update_work_9_rec IN update_work_9_cur LOOP
--
        --����A���́A�ڋq�R�[�h�E�S�����_�R�[�h�E�[�i��ڋq�R�[�h���u���[�N
        IF (
             ( lt_bill_cust_code9 IS NULL )
             OR
             ( lt_bill_cust_code9 <> update_work_9_rec.bill_cust_code )
             OR
             ( lt_location_code9  <> update_work_9_rec.location_code )
             OR
             ( lt_ship_cust_code9 <> update_work_9_rec.ship_cust_code )
           )
        THEN
          --�������A�y�сA�P���R�[�h�ڂ̐ŕʍ��ڐݒ�
          ln_cust_cnt                     := 1;                                     -- �u���[�N�����R�[�h����������
          ln_int                          := ln_int + 1;                            -- �z��J�E���g�A�b�v
          l_bill_cust_code_9_tab(ln_int)  := update_work_9_rec.bill_cust_code;      -- �ڋq�R�[�h
          l_location_code_9_tab(ln_int)   := update_work_9_rec.location_code;       -- �S�����_�R�[�h
          l_ship_cust_code_9_tab(ln_int)  := update_work_9_rec.ship_cust_code;      -- �[�i��ڋq�R�[�h
-- Modify 2019.09.03 Ver1.93 Start
--          l_tax_rate1_9_tab(ln_int)       := update_work_9_rec.tax_rate;            -- ����ŗ�(�ҏW�p)
          l_category1_9_tab(ln_int)       := update_work_9_rec.category;            -- ���󕪗ނP
-- Modify 2019.09.03 Ver1.93 End
          l_inc_tax_charge1_9_tab(ln_int) := update_work_9_rec.tax_rate_by_sum;     -- ���������グ�z�P
-- Modify 2019.09.03 Ver1.93 Start
--          l_tax_rate2_9_tab(ln_int)       := NULL;                                  -- ����ŗ��Q
          l_category2_9_tab(ln_int)       := NULL;                                  -- ���󕪗ނQ
-- Modify 2019.09.03 Ver1.93 End
          l_inc_tax_charge2_9_tab(ln_int) := NULL;                                  -- ���������グ�z�Q
-- Add 2019.09.03 Ver1.93 Start
          l_category3_9_tab(ln_int)       := NULL;                                  -- ���󕪗ނR
          l_inc_tax_charge3_9_tab(ln_int) := NULL;                                  -- ���������グ�z�R
-- Add 2019.09.03 Ver1.93 End
          lt_bill_cust_code9              := update_work_9_rec.bill_cust_code;      -- �u���[�N�R�[�h�ݒ�(�ڋq�R�[�h)
          lt_location_code9               := update_work_9_rec.location_code;       -- �u���[�N�R�[�h�ݒ�(�S�����_�R�[�h)
          lt_ship_cust_code9              := update_work_9_rec.ship_cust_code;      -- �u���[�N�R�[�h�ݒ�(�[�i��ڋq�R�[�h)
        ELSE
-- Modify 2019.09.03 Ver1.93 Start
--          --����ڋq�E�S�����_�E�[�i��ڋq�R�[�h��2���R�[�h�ڈȍ~(2���R�[�h�ȏ�͐ݒ肵�Ȃ�)
          --����ڋq�E�S�����_�E�[�i��ڋq�R�[�h��2���R�[�h�ڈȍ~(3���R�[�h�ȏ�͐ݒ肵�Ȃ�)
-- Modify 2019.09.03 Ver1.93 End
          ln_cust_cnt := ln_cust_cnt + 1;  --�u���[�N�������J�E���g�A�b�v
          --1�X�܂ɂ��ő�Q�̐ŕʍ��ڂ�ݒ�
          IF ( ln_cust_cnt = 2 ) THEN
            --�Q���R�[�h��
-- Modify 2019.09.03 Ver1.93 Start
--            l_tax_rate2_9_tab(ln_int)       := update_work_9_rec.tax_rate;            -- ����ŗ��Q
            l_category2_9_tab(ln_int)       := update_work_9_rec.category;            -- ���󕪗ނQ
-- Modify 2019.09.03 Ver1.93 End
            l_inc_tax_charge2_9_tab(ln_int) := update_work_9_rec.tax_rate_by_sum;     -- ���������グ�z�Q
-- Add 2019.09.03 Ver1.93 Start
          ELSIF ( ln_cust_cnt = 3 ) THEN
            --�R���R�[�h��
            l_category3_9_tab(ln_int)       := update_work_9_rec.category;            --���󕪗ނR
            l_inc_tax_charge3_9_tab(ln_int) := update_work_9_rec.tax_rate_by_sum;     --���������グ�z�R
-- Add 2019.09.03 Ver1.93 End
          END IF;
        END IF;
--
      END LOOP edit_loop9;
--
      --�ꊇ�X�V
      BEGIN
        <<update_loop9>>
        FORALL i IN l_bill_cust_code_9_tab.FIRST..l_bill_cust_code_9_tab.LAST
          UPDATE  xxcfr_rep_st_inv_inc_tax_d_l  xrsidl
-- Modify 2019.09.03 Ver1.93 Start
--          SET     xrsidl.tax_rate1        = l_tax_rate1_9_tab(i)        -- ����ŗ�1
--                 ,xrsidl.inc_tax_charge1  = l_inc_tax_charge1_9_tab(i)  -- ���������グ�z�P
--                 ,xrsidl.tax_rate2        = l_tax_rate2_9_tab(i)        -- ����ŗ��Q
--                 ,xrsidl.inc_tax_charge2  = l_inc_tax_charge2_9_tab(i)  -- ���������グ�z�Q
          SET     xrsidl.category1        = l_category1_9_tab(i)        -- ���󕪗ނP
                 ,xrsidl.inc_tax_charge1  = l_inc_tax_charge1_9_tab(i)  -- ���������グ�z�P
                 ,xrsidl.category2        = l_category2_9_tab(i)        -- ���󕪗ނQ
                 ,xrsidl.inc_tax_charge2  = l_inc_tax_charge2_9_tab(i)  -- ���������グ�z�Q
                 ,xrsidl.category3        = l_category3_9_tab(i)        -- ���󕪗ނR
                 ,xrsidl.inc_tax_charge3  = l_inc_tax_charge3_9_tab(i)  -- ���������グ�z�R
-- Modify 2019.09.03 Ver1.93 End
          WHERE   xrsidl.bill_cust_code   = l_bill_cust_code_9_tab(i)
          AND     xrsidl.location_code    = l_location_code_9_tab(i)
          AND     xrsidl.ship_cust_code   = l_ship_cust_code_9_tab(i)
          AND     xrsidl.request_id       = cn_request_id
          ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg( cv_msg_kbn_cfr       -- 'XXCFR'
                                                         ,cv_msg_003a18_026    -- �e�[�u���X�V�G���[
                                                         ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                         ,xxcfr_common_pkg.get_table_comment(cv_table_d_l))
                                                        -- �W���������ō����[�������P��D���[�N�e�[�u������
                               ,1
                               ,5000);
          lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_api_expt;
      END;
--
    END IF;
--
    -- -- ����0���t���OD��2�ł���ꍇ
    IF ( gv_target_d_flag = cv_taget_flag_2 ) THEN
      -- 10.���������グ�z�Ə���Ŋz���v�Z���W���������ō����[�������P��D���[�N�e�[�u�����ׂ��X�V
      -- �ϐ��̏�����
      ln_int      := 0;
--
      <<edit_loop10>>
      FOR update_work_10_rec IN update_work_10_cur LOOP
        ln_int                          := ln_int + 1;                            -- �z��J�E���g�A�b�v
        l_bill_cust_code_10_tab(ln_int)  := update_work_10_rec.bill_cust_code;    -- �ڋq�R�[�h
        l_location_code_10_tab(ln_int)   := update_work_10_rec.location_code;     -- �S�����_�R�[�h
        l_ship_cust_code_10_tab(ln_int)  := update_work_10_rec.ship_cust_code;    -- �[�i��ڋq�R�[�h
        l_store_sum_10_tab(ln_int)       := update_work_10_rec.store_sum;         -- �����������z�i�ō��j
      END LOOP edit_loop10;
--
      --�ꊇ�X�V
      BEGIN
        <<update_loop10>>
        FORALL i IN l_bill_cust_code_10_tab.FIRST..l_bill_cust_code_10_tab.LAST
          UPDATE  xxcfr_rep_st_inv_inc_tax_d_l  xrsidl
          SET     xrsidl.store_sum        = l_store_sum_10_tab(i)        -- �����������z�i�ō��j
          WHERE   xrsidl.bill_cust_code   = l_bill_cust_code_10_tab(i)
          AND     xrsidl.location_code    = l_location_code_10_tab(i)
          AND     xrsidl.ship_cust_code   = l_ship_cust_code_10_tab(i)
          AND     xrsidl.request_id       = cn_request_id
          ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg( cv_msg_kbn_cfr       -- 'XXCFR'
                                                         ,cv_msg_003a18_026    -- �e�[�u���X�V�G���[
                                                         ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                         ,xxcfr_common_pkg.get_table_comment(cv_table_d_l))
                                                        -- �W���������ō����[�������P��D���[�N�e�[�u������
                               ,1
                               ,5000);
          lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_api_expt;
      END;
    END IF;
--
-- Ver.1.92 [��QE_�{�ғ�_15307] ADD END
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
  END update_work_table;
--
-- Add 2013.12.13 Ver1.60 End
  /********************************************************************************************************
   * Procedure Name   : insert_work_table
   * Description      : �Ώیڋq�擾����(A-4)�A���|�Ǘ���ڋq�擾����(A-5)�A���[�N�e�[�u���f�[�^�o�^(A-6))
   ********************************************************************************************************/
  PROCEDURE insert_work_table(
    iv_target_date          IN   VARCHAR2,            -- ����
    iv_customer_code14      IN   VARCHAR2,         -- ���|�Ǘ���ڋq
    iv_customer_code21      IN   VARCHAR2,         -- �����������p�ڋq
    iv_customer_code20      IN   VARCHAR2,         -- �������p�ڋq
    iv_customer_code10      IN   VARCHAR2,         -- �ڋq
-- Add 2010.12.10 Ver1.30 Start
    iv_bill_pub_cycle       IN   VARCHAR2,         -- ���������s�T�C�N��
-- Add 2010.12.10 Ver1.30 End
-- Add 2013.12.13 Ver1.60 Start
    iv_tax_output_type      IN   VARCHAR2,         -- �ŕʓ���o�͋敪
-- Add 2013.12.13 Ver1.60 End
-- Add 2014.03.27 Ver1.70 Start
    iv_bill_invoice_type    IN   VARCHAR2,         -- �������o�͌`��
-- Add 2014.03.27 Ver1.70 End
    ov_errbuf               OUT  VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT  VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT  VARCHAR2)            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_work_table'; -- �v���O������
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
    -- ����ŋ敪
    cv_syohizei_kbn_inc2 CONSTANT VARCHAR2(1) := '2';                      -- ����(�`�[)
    cv_syohizei_kbn_inc3 CONSTANT VARCHAR2(1) := '3';                      -- ����(�P��)
    -- �������o�͋敪
    cv_inv_prt_type     CONSTANT VARCHAR2(1)  := '1';                       -- 1.�ɓ����W��
-- Add 2013.12.13 Ver1.60 Start
-- Del 2016.09.06 Ver1.91 Start
--    cv_tax_op_type_yes  CONSTANT VARCHAR2(1)  := '2';                       -- 2.�ŕʓ���o�͂���
-- Del 2016.09.06 Ver1.91 End
-- Add 2013.12.13 Ver1.60 End
-- Add 2014.03.27 Ver1.70 Start
    -- �Ǝ҈ϑ��t���O
    cv_os_flag_y        CONSTANT VARCHAR2(1)  := 'Y';                      -- Y.�Ǝ҈ϑ�
    -- �������o�͌`��
    cv_bill_invoice_type_os  CONSTANT VARCHAR2(1) := '4';                  -- 4.�Ǝ҈ϑ�
-- Add 2014.03.27 Ver1.70 End
-- Add 2019.09.03 Ver1.93 Start
    -- �Q�ƃ^�C�v
    cv_xxcfr_tax_category    CONSTANT VARCHAR2(20) := 'XXCFR1_TAX_CATEGORY';     -- �ŕ���
-- Add 2019.09.03 Ver1.93 End
--
    -- *** ���[�J���ϐ� ***
    -- �������`�p�ϐ�
    lv_format_date_jpymd4  VARCHAR2(25); -- YYYY"�N"MM"��"DD"��"
    lv_format_date_jpymd2  VARCHAR2(25); -- YY"�N"MM"��"DD"��"
    lv_format_date_year    VARCHAR2(10); -- �N
    lv_format_date_month   VARCHAR2(10); -- ��
    lv_format_date_bank    VARCHAR2(10); -- ��s
    lv_format_date_central VARCHAR2(10); -- �{�X
    lv_format_date_branch  VARCHAR2(10); -- �x�X
    lv_format_date_account VARCHAR2(10); -- ����
    lv_format_date_current VARCHAR2(10); -- ����
    lv_format_zip_mark     VARCHAR2(10); -- ��
    lv_format_bank_dummy   VARCHAR2(10); -- D%
--
    ln_target_cnt   NUMBER := 0;    -- �Ώی���
    ln_loop_cnt     NUMBER;         -- ���[�v�J�E���^
--
    lv_no_data_msg  VARCHAR2(5000); -- ���[�O�����b�Z�[�W
    lv_func_status  VARCHAR2(1);    -- SVF���[���ʊ֐�(0���o�̓��b�Z�[�W)�I���X�e�[�^�X
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �ڋq�擾�J�[�\���^�C�v
    TYPE cursor_rec_type IS RECORD(customer_id           xxcmm_cust_accounts.customer_id%TYPE,           -- �ڋq�敪10�ڋqID
                                   customer_code         xxcmm_cust_accounts.customer_code%TYPE,         -- �ڋq�敪10�ڋq�R�[�h
                                   invoice_printing_unit xxcmm_cust_accounts.invoice_printing_unit%TYPE, -- �ڋq�敪10����������P��
-- Add 2011.01.17 Ver1.40 Start
                                   store_code            xxcmm_cust_accounts.store_code%TYPE,            -- �ڋq�敪10�X�܃R�[�h
-- Add 2011.01.17 Ver1.40 End
                                   bill_base_code        xxcmm_cust_accounts.bill_base_code%TYPE);       -- �ڋq�敪10�������_�R�[�h
    TYPE cursor_ref_type IS REF CURSOR;
    get_all_account_cur cursor_ref_type;
    all_account_rec cursor_rec_type;
--
    -- �ڋq10�擾�J�[�\��������
    cv_get_all_account_cur   CONSTANT VARCHAR2(3000) := 
    'SELECT xxca.customer_id           AS customer_id, '||            -- �ڋqID
    '       xxca.customer_code         AS customer_code, '||          -- �ڋq�R�[�h
    '        xxca.invoice_printing_unit AS invoice_printing_unit, '|| -- ����������P��
-- Add 2011.01.17 Ver1.40 Start
    '       xxca.store_code             AS store_code, '||            -- �X�܃R�[�h
-- Add 2011.01.17 Ver1.40 End
    '        xxca.bill_base_code        AS bill_base_code '||         -- �������_�R�[�h
    ' FROM xxcmm_cust_accounts xxca, '||                                     -- �ڋq�ǉ����
    '      hz_cust_accounts    hzca '||                                      -- �ڋq�}�X�^
    ' WHERE xxca.invoice_printing_unit IN ('''||cv_invoice_printing_unit_a1||''','||
                                          ''''||cv_invoice_printing_unit_a2||''','||
                                          ''''||cv_invoice_printing_unit_a3||''','||
                                          ''''||cv_invoice_printing_unit_a4||''','||
                                          ''''||cv_invoice_printing_unit_a5||''','||
-- Mod 2015.07.31 Ver1.80 Start
--                                          ''''||cv_invoice_printing_unit_a6||''') '|| -- ����������P��
                                          ''''||cv_invoice_printing_unit_a6||''','||
                                          ''''||cv_invoice_printing_unit_a7||''','||
-- Mod 2016.03.31 Ver1.90 Start
--                                          ''''||cv_invoice_printing_unit_a8||''') '|| -- ����������P��
                                          ''''||cv_invoice_printing_unit_a8||''','||
-- Ver.1.92 [��QE_�{�ғ�_15307] MOD START
--                                          ''''||cv_invoice_printing_unit_a9||''') '|| -- ����������P��
                                          ''''||cv_invoice_printing_unit_a9||''','||
                                          ''''||cv_invoice_printing_unit_a10||''') '|| -- ����������P��
-- Ver.1.92 [��QE_�{�ғ�_15307] MOD END
-- Mod 2016.03.31 Ver1.90 End
-- Mod 2015.07.31 Ver1.80 End
    ' AND   hzca.customer_class_code = '''||cv_customer_class_code10||''' '||         -- �ڋq�敪:10
    ' AND   xxca.customer_id = hzca.cust_account_id ';
--
    -- �ڋq10�擾�J�[�\��������(���|�Ǘ���ڋq�w�莞)
    cv_get_14account_cur   CONSTANT VARCHAR2(3000) := 
    'SELECT xxca10.customer_id           AS customer_id, '||           -- �ڋqID
    '       xxca10.customer_code         AS customer_code, '||         -- �ڋq�R�[�h
    '       xxca10.invoice_printing_unit AS invoice_printing_unit, '|| -- ����������P��
-- Add 2011.01.17 Ver1.40 Start
    '       xxca10.store_code            AS store_code, '||            -- �X�܃R�[�h
-- Add 2011.01.17 Ver1.40 End
    '       xxca10.bill_base_code        AS bill_base_code '||         -- �������_�R�[�h
    'FROM xxcmm_cust_accounts xxca10, '||                                     -- �ڋq10�ڋq�ǉ����
    '     hz_cust_accounts    hzca10, '||                                     -- �ڋq10�ڋq�}�X�^
    '     hz_cust_acct_sites  hasa10, '||                                     -- �ڋq10�ڋq���ݒn
    '     hz_cust_site_uses   hsua10, '||                                     -- �ڋq10�ڋq�g�p�ړI
    '     hz_cust_accounts    hzca14, '||                                     -- �ڋq14�ڋq�}�X�^
    '     hz_cust_acct_relate hcar14, '||                                     -- �ڋq�֘A�}�X�^
    '     hz_cust_acct_sites  hasa14, '||                                     -- �ڋq14�ڋq���ݒn
    '     hz_cust_site_uses   hsua14 '||                                      -- �ڋq14�ڋq�g�p�ړI
-- Mod 2015.07.31 Ver1.80 Start
--    'WHERE xxca10.invoice_printing_unit = '''||cv_invoice_printing_unit_a1||''' '||    -- ����������P��
    'WHERE xxca10.invoice_printing_unit IN ('''||cv_invoice_printing_unit_a1||''','||
                                           ''''||cv_invoice_printing_unit_a7||''','||
-- Mod 2016.03.31 Ver1.90 Start
--                                           ''''||cv_invoice_printing_unit_a8||''')'||
                                           ''''||cv_invoice_printing_unit_a8||''','||
-- Ver.1.92 [��QE_�{�ғ�_15307] MOD START
--                                           ''''||cv_invoice_printing_unit_a9||''')'||
                                           ''''||cv_invoice_printing_unit_a9||''','||
                                           ''''||cv_invoice_printing_unit_a10||''')'||
-- Ver.1.92 [��QE_�{�ғ�_15307] MOD END
-- Mod 2016.03.31 Ver1.90 End
-- Mod 2015.07.31 Ver1.80 End
    'AND   hzca10.customer_class_code = '''||cv_customer_class_code10||''' '||         -- �ڋq�敪:10
    'AND   xxca10.customer_id = hzca10.cust_account_id '||
    'AND   hzca14.account_number = :iv_customer_code14 '||
    'AND   hzca14.cust_account_id = hcar14.cust_account_id '||
    'AND   hcar14.related_cust_account_id = hzca10.cust_account_id '||
    'AND   hzca14.customer_class_code = '''||cv_customer_class_code14||''' '||
    'AND   hcar14.status = '''||cv_acct_relate_status||''' '||
    'AND   hcar14.attribute1 = '''||cv_acct_relate_type_bill||''' '||
    'AND   hzca14.cust_account_id = hasa14.cust_account_id '||
    'AND   hasa14.cust_acct_site_id = hsua14.cust_acct_site_id '||
    'AND   hsua14.site_use_code = '''||cv_site_use_code_bill_to||''' '||
-- Add 2010-02-03 Ver1.20 Start
    'AND   hsua14.status = '''||cv_site_use_stat_act||''' '||
-- Add 2010-02-03 Ver1.20 End
    'AND   hzca10.cust_account_id = hasa10.cust_account_id '||
    'AND   hasa10.cust_acct_site_id = hsua10.cust_acct_site_id '||
-- Add 2010-02-03 Ver1.20 Start
    'AND   hsua10.status = '''||cv_site_use_stat_act||''' '||
-- Add 2010-02-03 Ver1.20 End
    'AND   hsua10.bill_to_site_use_id = hsua14.site_use_id ';
--
    -- �ڋq10�擾�J�[�\��������(�����������p�ڋq�w�莞)
    cv_get_21account_cur   CONSTANT VARCHAR2(3000) := 
    'SELECT xxca10.customer_id           AS customer_id, '||           -- �ڋqID
    '       xxca10.customer_code         AS customer_code, '||         -- �ڋq�R�[�h
    '       xxca10.invoice_printing_unit AS invoice_printing_unit, '|| -- ����������P��
-- Add 2011.01.17 Ver1.40 Start
    '       xxca10.store_code            AS store_code, '||            -- �X�܃R�[�h
-- Add 2011.01.17 Ver1.40 End
    '       xxca10.bill_base_code        AS bill_base_code '||         -- �������_�R�[�h
    'FROM xxcmm_cust_accounts xxca10, '||                                     -- �ڋq10�ڋq�ǉ����
    '     xxcmm_cust_accounts xxca20, '||                                     -- �ڋq20�ڋq�ǉ����
    '     xxcmm_cust_accounts xxca21, '||                                     -- �ڋq21�ڋq�ǉ����
    '     hz_cust_accounts    hzca10 '||                                      -- �ڋq10�ڋq�}�X�^
    'WHERE xxca10.invoice_printing_unit = '''||cv_invoice_printing_unit_a2||''' '||     -- ����������P��
    'AND   hzca10.customer_class_code = '''||cv_customer_class_code10||''' '||          -- �ڋq�敪:10
    'AND   xxca10.customer_id = hzca10.cust_account_id '||
    'AND   xxca10.invoice_code = xxca20.customer_code '||
    'AND   xxca20.enclose_invoice_code = xxca21.customer_code '||
    'AND   xxca21.customer_code = :iv_customer_code21 ';
--
    -- �ڋq10�擾�J�[�\��������(�������p�ڋq�w�莞)
    cv_get_20account_cur   CONSTANT VARCHAR2(3000) := 
    'SELECT xxca10.customer_id           AS customer_id, '||           -- �ڋqID
    '       xxca10.customer_code         AS customer_code, '||         -- �ڋq�R�[�h
    '       xxca10.invoice_printing_unit AS invoice_printing_unit, '|| -- ����������P��
-- Add 2011.01.17 Ver1.40 Start
    '       xxca10.store_code            AS store_code, '||            -- �X�܃R�[�h
-- Add 2011.01.17 Ver1.40 End
    '       xxca10.bill_base_code        AS bill_base_code '||         -- �������_�R�[�h
    'FROM xxcmm_cust_accounts xxca10, '||                                     -- �ڋq10�ڋq�ǉ����
    '     xxcmm_cust_accounts xxca20, '||                                     -- �ڋq20�ڋq�ǉ����
    '     hz_cust_accounts    hzca10 '||                                      -- �ڋq10�ڋq�}�X�^
-- Modify 2009-11-11 Ver1.10 Start
--    'WHERE xxca10.invoice_printing_unit IN ('''||cv_invoice_printing_unit_a3||''','||
--                                           ''''||cv_invoice_printing_unit_a4||''') '||   -- ����������P��
    'WHERE xxca10.invoice_printing_unit = '''||cv_invoice_printing_unit_a3||''' '||      -- ����������P��
-- Modify 2009-11-11 Ver1.10 End
    'AND   hzca10.customer_class_code = '''||cv_customer_class_code10||''' '||           -- �ڋq�敪:10
    'AND   xxca10.customer_id = hzca10.cust_account_id '||
    'AND   xxca10.invoice_code = xxca20.customer_code '||
    'AND   xxca20.customer_code = :iv_customer_code20 '||
-- Modify 2009-11-11 Ver1.10 Start
    'UNION ALL '||
    'SELECT xxca10.customer_id           AS customer_id, '||           -- �ڋqID
    '       xxca10.customer_code         AS customer_code, '||         -- �ڋq�R�[�h
    '       xxca10.invoice_printing_unit AS invoice_printing_unit, '|| -- ����������P��
-- Add 2011.01.17 Ver1.40 Start
    '       xxca10.store_code            AS store_code, '||            -- �X�܃R�[�h
-- Add 2011.01.17 Ver1.40 End
    '       xxca10.bill_base_code        AS bill_base_code '||         -- �������_�R�[�h
    'FROM xxcmm_cust_accounts xxca10, '||                                     -- �ڋq10�ڋq�ǉ����
    '     xxcmm_cust_accounts xxca20, '||                                     -- �ڋq20�ڋq�ǉ����
    '     xxcmm_cust_accounts xxca21, '||                                     -- �ڋq21�ڋq�ǉ����
    '     hz_cust_accounts    hzca10 '||                                      -- �ڋq10�ڋq�}�X�^
    'WHERE xxca10.invoice_printing_unit = '''||cv_invoice_printing_unit_a4||''' '||     -- ����������P��
    'AND   hzca10.customer_class_code = '''||cv_customer_class_code10||''' '||          -- �ڋq�敪:10
    'AND   xxca10.customer_id = hzca10.cust_account_id '||
    'AND   xxca10.invoice_code = xxca20.customer_code '||
    'AND   xxca20.enclose_invoice_code = xxca21.customer_code '||
    'AND EXISTS (SELECT ''X'' '||
    '            FROM xxcmm_cust_accounts xxca20_sub '||
    '            WHERE xxca20_sub.customer_code = :iv_customer_code20 '||
    '            AND   xxca20_sub.enclose_invoice_code = xxca21.customer_code) ';
-- Modify 2009-11-11 Ver1.10 End
--
    -- �ڋq10�擾�J�[�\��������(�ڋq�w�莞)
-- Modify 2009-11-11 Ver1.10 Start
    cv_get_10account_cur   CONSTANT VARCHAR2(5000) := 
--    'SELECT xxca.customer_id           AS customer_id, '||           -- �ڋqID
--    '       xxca.customer_code         AS customer_code, '||         -- �ڋq�R�[�h
--    '       xxca.invoice_printing_unit AS invoice_printing_unit, '|| -- ����������P��
--    '       xxca.bill_base_code        AS bill_base_code '||         -- �������_�R�[�h
--    'FROM xxcmm_cust_accounts xxca, '||                                     -- �ڋq�ǉ����
--    '     hz_cust_accounts    hzca '||                                      -- �ڋq�}�X�^
--    'WHERE xxca.invoice_printing_unit IN ('''||cv_invoice_printing_unit_a5||''','||
--                                         ''''||cv_invoice_printing_unit_a6||''') '||    -- ����������P��
--    'AND   hzca.customer_class_code = '''||cv_customer_class_code10||''' '||            -- �ڋq�敪:10
--    'AND   xxca.customer_id = hzca.cust_account_id '||
--    'AND   xxca.customer_code = :iv_customer_code10 ';
    'SELECT xxca10.customer_id           AS customer_id, '||           -- �ڋqID
    '       xxca10.customer_code         AS customer_code, '||         -- �ڋq�R�[�h
    '       xxca10.invoice_printing_unit AS invoice_printing_unit, '|| -- ����������P��
-- Add 2011.01.17 Ver1.40 Start
    '       xxca10.store_code            AS store_code, '||            -- �X�܃R�[�h
-- Add 2011.01.17 Ver1.40 End
    '       xxca10.bill_base_code        AS bill_base_code '||         -- �������_�R�[�h
    'FROM xxcmm_cust_accounts xxca10, '||                                     -- �ڋq10�ڋq�ǉ����
    '     hz_cust_accounts    hzca10, '||                                     -- �ڋq10�ڋq�}�X�^
    '     hz_cust_acct_sites  hasa10, '||                                     -- �ڋq10�ڋq���ݒn
    '     hz_cust_site_uses   hsua10, '||                                     -- �ڋq10�ڋq�g�p�ړI
    '     hz_cust_accounts    hzca14, '||                                     -- �ڋq14�ڋq�}�X�^
    '     hz_cust_acct_relate hcar14, '||                                     -- �ڋq�֘A�}�X�^
    '     hz_cust_acct_sites  hasa14, '||                                     -- �ڋq14�ڋq���ݒn
    '     hz_cust_site_uses   hsua14 '||                                      -- �ڋq14�ڋq�g�p�ړI
    'WHERE xxca10.invoice_printing_unit = '''||cv_invoice_printing_unit_a5||''' '||    -- ����������P��
    'AND   hzca10.customer_class_code = '''||cv_customer_class_code10||''' '||         -- �ڋq�敪:10
    'AND   xxca10.customer_id = hzca10.cust_account_id '||
    'AND   hzca14.cust_account_id = hcar14.cust_account_id '||
    'AND   hcar14.related_cust_account_id = hzca10.cust_account_id '||
    'AND   hzca14.customer_class_code = '''||cv_customer_class_code14||''' '||
    'AND   hcar14.status = '''||cv_acct_relate_status||''' '||
    'AND   hcar14.attribute1 = '''||cv_acct_relate_type_bill||''' '||
    'AND   hzca14.cust_account_id = hasa14.cust_account_id '||
    'AND   hasa14.cust_acct_site_id = hsua14.cust_acct_site_id '||
    'AND   hsua14.site_use_code = '''||cv_site_use_code_bill_to||''' '||
-- Add 2010-02-03 Ver1.20 Start
    'AND   hsua14.status = '''||cv_site_use_stat_act||''' '||
-- Add 2010-02-03 Ver1.20 End
    'AND   hzca10.cust_account_id = hasa10.cust_account_id '||
    'AND   hasa10.cust_acct_site_id = hsua10.cust_acct_site_id '||
-- Add 2010-02-03 Ver1.20 Start
    'AND   hsua10.status = '''||cv_site_use_stat_act||''' '||
-- Add 2010-02-03 Ver1.20 End
    'AND   hsua10.bill_to_site_use_id = hsua14.site_use_id '||
    'AND EXISTS (SELECT ''X'' '||
    '            FROM hz_cust_accounts          bill_hzca_1, '||             --�ڋq14�ڋq�}�X�^
    '                 hz_cust_accounts          ship_hzca_1, '||             --�ڋq10�ڋq�}�X�^
    '                 hz_cust_acct_sites        bill_hasa_1, '||             --�ڋq14�ڋq���ݒn
    '                 hz_cust_site_uses         bill_hsua_1, '||             --�ڋq14�ڋq�g�p�ړI
    '                 hz_cust_acct_relate       bill_hcar_1, '||             --�ڋq�֘A�}�X�^(�����֘A)
    '                 hz_cust_acct_sites        ship_hasa_1, '||             --�ڋq10�ڋq���ݒn
    '                 hz_cust_site_uses         ship_hsua_1 '||              --�ڋq10�ڋq�g�p�ړI
    '            WHERE ship_hzca_1.account_number = :iv_customer_code10 '||
    '            AND   bill_hzca_1.account_number = hzca14.account_number '||
    '            AND   bill_hzca_1.cust_account_id = bill_hcar_1.cust_account_id '||                   --�ڋq14�ڋq�}�X�^.�ڋqID = �ڋq�֘A�}�X�^.�ڋqID
    '            AND   bill_hcar_1.related_cust_account_id = ship_hzca_1.cust_account_id '||           --�ڋq�֘A�}�X�^.�֘A��ڋqID = �ڋq10�ڋq�}�X�^.�ڋqID
    '            AND   bill_hzca_1.customer_class_code = '''||cv_customer_class_code14||''' '||        --�ڋq14�ڋq�}�X�^.�ڋq�敪 = '14'(���|�Ǘ���ڋq)
    '            AND   bill_hcar_1.status = '''||cv_acct_relate_status||''' '||                        --�ڋq�֘A�}�X�^.�X�e�[�^�X = �eA�f
    '            AND   bill_hcar_1.attribute1 = '''||cv_acct_relate_type_bill||''' '||                 --�ڋq�֘A�}�X�^.�֘A���� = �e1�f (����)
    '            AND   bill_hzca_1.cust_account_id = bill_hasa_1.cust_account_id '||                   --�ڋq14�ڋq�}�X�^.�ڋqID = �ڋq14�ڋq���ݒn.�ڋqID
    '            AND   bill_hasa_1.cust_acct_site_id = bill_hsua_1.cust_acct_site_id '||               --�ڋq14�ڋq���ݒn.�ڋq���ݒnID = �ڋq14�ڋq�g�p�ړI.�ڋq���ݒnID
    '            AND   bill_hsua_1.site_use_code = '''||cv_site_use_code_bill_to||''' '||              --�ڋq14�ڋq�g�p�ړI.�g�p�ړI = 'BILL_TO'(������)
-- Add 2010-02-03 Ver1.20 Start
    '            AND   bill_hsua_1.status = '''||cv_site_use_stat_act||''' '||                         --�ڋq14�ڋq�g�p�ړI.�X�e�[�^�X = 'A'
-- Add 2010-02-03 Ver1.20 End
    '            AND   ship_hzca_1.cust_account_id = ship_hasa_1.cust_account_id '||                   --�ڋq10�ڋq�}�X�^.�ڋqID = �ڋq10�ڋq���ݒn.�ڋqID
    '            AND   ship_hasa_1.cust_acct_site_id = ship_hsua_1.cust_acct_site_id '||               --�ڋq10�ڋq���ݒn.�ڋq���ݒnID = �ڋq10�ڋq�g�p�ړI.�ڋq���ݒnID
-- Add 2010-02-03 Ver1.20 Start
    '            AND   ship_hsua_1.status = '''||cv_site_use_stat_act||''' '||                         --�ڋq14�ڋq�g�p�ړI.�X�e�[�^�X = 'A'
-- Add 2010-02-03 Ver1.20 End
    '            AND   ship_hsua_1.bill_to_site_use_id = bill_hsua_1.site_use_id) '||                  --�ڋq10�ڋq�g�p�ړI.�����掖�Ə�ID = �ڋq14�ڋq�g�p�ړI.�g�p�ړIID
    'UNION ALL '||
    'SELECT xxca10.customer_id           AS customer_id, '||           -- �ڋqID
    '       xxca10.customer_code         AS customer_code, '||         -- �ڋq�R�[�h
    '       xxca10.invoice_printing_unit AS invoice_printing_unit, '|| -- ����������P��
-- Add 2011.01.17 Ver1.40 Start
    '       xxca10.store_code            AS store_code, '||            -- �X�܃R�[�h
-- Add 2011.01.17 Ver1.40 End
    '       xxca10.bill_base_code        AS bill_base_code '||         -- �������_�R�[�h
    'FROM xxcmm_cust_accounts xxca10, '||                                     -- �ڋq10�ڋq�ǉ����
    '     xxcmm_cust_accounts xxca20, '||                                     -- �ڋq20�ڋq�ǉ����
    '     hz_cust_accounts    hzca10 '||                                      -- �ڋq10�ڋq�}�X�^
    'WHERE xxca10.invoice_printing_unit = '''||cv_invoice_printing_unit_a6||''' '||      -- ����������P��
    'AND   hzca10.customer_class_code = '''||cv_customer_class_code10||''' '||           -- �ڋq�敪:10
    'AND   xxca10.customer_id = hzca10.cust_account_id '||
    'AND   xxca10.invoice_code = xxca20.customer_code '||
    'AND   EXISTS (SELECT ''X'' '||
    '              FROM xxcmm_cust_accounts xxca10_sub '||
    '              WHERE xxca10_sub.customer_code = :iv_customer_code10 '||
    '              AND   xxca10_sub.invoice_code = xxca20.customer_code) ';
-- Modify 2009-11-11 Ver1.10 End
--
    -- �ڋq14�擾�J�[�\��
    CURSOR get_14account_cur(
      iv_customer_id IN NUMBER) -- �ڋq�敪10�̌ڋqID
    IS
     SELECT bill_hzca_1.cust_account_id         AS cash_account_id,         --�ڋq14ID
            bill_hzca_1.account_number          AS cash_account_number,     --�ڋq14�R�[�h
            bill_hzpa_1.party_name              AS cash_account_name,       --�ڋq14�ڋq��
            ship_hzca_1.cust_account_id         AS ship_account_id,         --�ڋq10�ڋqID        
            ship_hzca_1.account_number          AS ship_account_number,     --�ڋq10�ڋq�R�[�h 
            bill_hzad_1.bill_base_code          AS bill_base_code,          --�ڋq14�������_�R�[�h
            bill_hzlo_1.postal_code             AS bill_postal_code,        --�ڋq14�X�֔ԍ�            
            bill_hzlo_1.state                   AS bill_state,              --�ڋq14�s���{��            
            bill_hzlo_1.city                    AS bill_city,               --�ڋq14�s�E��              
            bill_hzlo_1.address1                AS bill_address1,           --�ڋq14�Z��1               
            bill_hzlo_1.address2                AS bill_address2,           --�ڋq14�Z��2
            bill_hzlo_1.address_lines_phonetic  AS phone_num,               --�ڋq14�d�b�ԍ�
            bill_hzad_1.tax_div                 AS bill_tax_div,            --�ڋq14����ŋ敪
            bill_hsua_1.attribute7              AS bill_invoice_type,       --�ڋq14�������o�͌`��      
            bill_hsua_1.payment_term_id         AS bill_payment_term_id,    --�ڋq14�x������
-- Add 2010.12.10 Ver1.30 Start
            bill_hsua_1.attribute8              AS bill_pub_cycle,          --�ڋq14���������s�T�C�N��
-- Add 2010.12.10 Ver1.30 End
            bill_hcp.cons_inv_flag              AS cons_inv_flag            --�ꊇ��������
     FROM hz_cust_accounts          bill_hzca_1,              --�ڋq14�ڋq�}�X�^
          hz_cust_accounts          ship_hzca_1,              --�ڋq10�ڋq�}�X�^
          xxcmm_cust_accounts       bill_hzad_1,              --�ڋq14�ڋq�ǉ����
          hz_cust_acct_sites        bill_hasa_1,              --�ڋq14�ڋq���ݒn
          hz_locations              bill_hzlo_1,              --�ڋq14�ڋq���Ə�
          hz_cust_site_uses         bill_hsua_1,              --�ڋq14�ڋq�g�p�ړI
          hz_cust_acct_relate       bill_hcar_1,              --�ڋq�֘A�}�X�^(�����֘A)
          hz_cust_acct_sites        ship_hasa_1,              --�ڋq10�ڋq���ݒn
          hz_cust_site_uses         ship_hsua_1,              --�ڋq10�ڋq�g�p�ړI
          hz_party_sites            bill_hzps_1,              --�ڋq14�p�[�e�B�T�C�g
          hz_parties                bill_hzpa_1,              --�ڋq14�p�[�e�B
          hz_customer_profiles      bill_hcp                  --�ڋq�v���t�@�C��
     WHERE ship_hzca_1.cust_account_id = iv_customer_id
     AND   bill_hzca_1.cust_account_id = bill_hcar_1.cust_account_id         --�ڋq14�ڋq�}�X�^.�ڋqID = �ڋq�֘A�}�X�^.�ڋqID
     AND   bill_hcar_1.related_cust_account_id = ship_hzca_1.cust_account_id --�ڋq�֘A�}�X�^.�֘A��ڋqID = �ڋq10�ڋq�}�X�^.�ڋqID
     AND   bill_hzca_1.customer_class_code = cv_customer_class_code14        --�ڋq14�ڋq�}�X�^.�ڋq�敪 = '14'(���|�Ǘ���ڋq)
     AND   bill_hcar_1.status = cv_acct_relate_status                        --�ڋq�֘A�}�X�^.�X�e�[�^�X = �eA�f
     AND   bill_hcar_1.attribute1 = cv_acct_relate_type_bill                 --�ڋq�֘A�}�X�^.�֘A���� = �e1�f (����)
     AND   bill_hzca_1.cust_account_id = bill_hzad_1.customer_id             --�ڋq14�ڋq�}�X�^.�ڋqID = �ڋq14�ڋq�ǉ����.�ڋqID
     AND   bill_hzca_1.cust_account_id = bill_hasa_1.cust_account_id         --�ڋq14�ڋq�}�X�^.�ڋqID = �ڋq14�ڋq���ݒn.�ڋqID
     AND   bill_hasa_1.cust_acct_site_id = bill_hsua_1.cust_acct_site_id     --�ڋq14�ڋq���ݒn.�ڋq���ݒnID = �ڋq14�ڋq�g�p�ړI.�ڋq���ݒnID
     AND   bill_hsua_1.site_use_code = cv_site_use_code_bill_to              --�ڋq14�ڋq�g�p�ړI.�g�p�ړI = 'BILL_TO'(������)
-- Add 2010-02-03 Ver1.20 Start
     AND   bill_hsua_1.status = cv_site_use_stat_act                         --�ڋq14�ڋq�g�p�ړI.�X�e�[�^�X = 'A'
-- Add 2010-02-03 Ver1.20 End
     AND   ship_hzca_1.cust_account_id = ship_hasa_1.cust_account_id         --�ڋq10�ڋq�}�X�^.�ڋqID = �ڋq10�ڋq���ݒn.�ڋqID
     AND   ship_hasa_1.cust_acct_site_id = ship_hsua_1.cust_acct_site_id     --�ڋq10�ڋq���ݒn.�ڋq���ݒnID = �ڋq10�ڋq�g�p�ړI.�ڋq���ݒnID
-- Add 2010-02-03 Ver1.20 Start
     AND   ship_hsua_1.status = cv_site_use_stat_act                         --�ڋq10�ڋq�g�p�ړI.�X�e�[�^�X = 'A'
-- Add 2010-02-03 Ver1.20 End
     AND   ship_hsua_1.bill_to_site_use_id = bill_hsua_1.site_use_id         --�ڋq10�ڋq�g�p�ړI.�����掖�Ə�ID = �ڋq14�ڋq�g�p�ړI.�g�p�ړIID
     AND   bill_hasa_1.party_site_id = bill_hzps_1.party_site_id             --�ڋq14�ڋq���ݒn.�p�[�e�B�T�C�gID = �ڋq14�p�[�e�B�T�C�g.�p�[�e�B�T�C�gID  
     AND   bill_hzps_1.location_id = bill_hzlo_1.location_id                 --�ڋq14�p�[�e�B�T�C�g.���Ə�ID = �ڋq14�ڋq���Ə�.���Ə�ID                  
     AND   bill_hzca_1.party_id = bill_hzpa_1.party_id                       --�ڋq14�ڋq�}�X�^.�p�[�e�BID = �ڋq14.�p�[�e�BID
     AND   bill_hsua_1.site_use_id = bill_hcp.site_use_id;                   --�ڋq14�ڋq�g�p�ړI.�g�p�ړIID = �ڋq�v���t�@�C��.�g�p�ړIID
--
    get_14account_rec get_14account_cur%ROWTYPE;
--
    -- �ڋq21�擾�J�[�\��
    CURSOR get_21account_cur(
      iv_customer_id IN NUMBER) -- �ڋq�敪10�̌ڋqID
    IS
     SELECT xxca21.customer_id                  AS bill_account_id,         --�ڋq21ID
            xxca21.customer_code                AS bill_account_number,     --�ڋq21�R�[�h
            hzpa21.party_name                   AS bill_account_name,       --�ڋq21�ڋq��
            xxca21.bill_base_code               AS bill_base_code21,        --�ڋq21�������_�R�[�h
            hzlo21.postal_code                  AS bill_postal_code,        --�ڋq21�X�֔ԍ�
            hzlo21.state                        AS bill_state,              --�ڋq21�s���{��
            hzlo21.city                         AS bill_city,               --�ڋq21�s�E��
            hzlo21.address1                     AS bill_address1,           --�ڋq21�Z��1
            hzlo21.address2                     AS bill_address2,           --�ڋq21�Z��2
            hzlo21.address_lines_phonetic       AS phone_num,               --�ڋq21�d�b�ԍ�
            xxca20.bill_base_code               AS bill_base_code20         --�ڋq20�������_�R�[�h
     FROM xxcmm_cust_accounts       xxca21,                   --�ڋq21�ڋq�ǉ����
          xxcmm_cust_accounts       xxca20,                   --�ڋq20�ڋq�ǉ����
          xxcmm_cust_accounts       xxca10,                   --�ڋq10�ڋq�ǉ����
          hz_cust_accounts          hzca20,                   --�ڋq20�ڋq�}�X�^
          hz_cust_accounts          hzca21,                   --�ڋq21�ڋq�}�X�^
          hz_parties                hzpa21,                   --�ڋq21�p�[�e�B
          hz_cust_acct_sites        hcas21,                   --�ڋq21�ڋq���ݒn
          hz_party_sites            hzps21,                   --�ڋq21�p�[�e�B�T�C�g
          hz_locations              hzlo21                    --�ڋq21�ڋq���Ə�
     WHERE xxca10.customer_id = iv_customer_id
     AND   xxca10.invoice_code = xxca20.customer_code                        --�ڋq10�ڋq�ǉ����.�������p�R�[�h = �ڋq20�ڋq�ǉ����.�ڋq�R�[�h
     AND   xxca20.enclose_invoice_code = xxca21.customer_code                --�ڋq20�ڋq�ǉ����.�����������p�R�[�h = �ڋq21�ڋq�ǉ����.�ڋq�R�[�h
     AND   hzca20.customer_class_code = cv_customer_class_code20             --�ڋq20�ڋq�}�X�^.�ڋq�敪 = '20'(�������p)
     AND   hzca20.cust_account_id = xxca20.customer_id                       --�ڋq20�ڋq�}�X�^.�ڋqID = �ڋq20�ڋq�ǉ����.�ڋq�R�[�h
     AND   hzca21.customer_class_code = cv_customer_class_code21             --�ڋq21�ڋq�}�X�^.�ڋq�敪 = '21'(�����������p)
     AND   hzca21.cust_account_id = xxca21.customer_id                       --�ڋq21�ڋq�}�X�^.�ڋqID = �ڋq21�ڋq�ǉ����.�ڋq�R�[�h
     AND   hzca21.party_id = hzpa21.party_id                                 --�ڋq21�ڋq�}�X�^.�p�[�e�BID = �ڋq21�p�[�e�B.�p�[�e�BID
     AND   hzca21.cust_account_id = hcas21.cust_account_id                   --�ڋq21�ڋq�}�X�^.�ڋqID = �ڋq21���ݒn.�ڋqID
     AND   hcas21.party_site_id = hzps21.party_site_id                       --�ڋq���ݒn21.�p�[�e�B�T�C�g = �ڋq21�p�[�e�B�T�C�g.�ڋq21�p�[�e�B�T�C�gID
     AND   hzps21.location_id = hzlo21.location_id;                          --�ڋq21�p�[�e�B�T�C�g.���Ə�ID = �ڋq21�ڋq���Ə�.���Ə�ID
--
    get_21account_rec get_21account_cur%ROWTYPE;
--
    -- �ڋq20�擾�J�[�\��
    CURSOR get_20account_cur(
      iv_customer_id IN NUMBER) -- �ڋq�敪10�̌ڋqID
    IS
     SELECT xxca20.customer_id                  AS bill_account_id,         --�ڋq20ID
            xxca20.customer_code                AS bill_account_number,     --�ڋq20�R�[�h
            hzpa20.party_name                   AS bill_account_name,       --�ڋq20�ڋq��
            xxca20.bill_base_code               AS bill_base_code,          --�ڋq20�������_�R�[�h
            hzlo20.postal_code                  AS bill_postal_code,        --�ڋq20�X�֔ԍ�
            hzlo20.state                        AS bill_state,              --�ڋq20�s���{��
            hzlo20.city                         AS bill_city,               --�ڋq20�s�E��
            hzlo20.address1                     AS bill_address1,           --�ڋq20�Z��1
            hzlo20.address2                     AS bill_address2,           --�ڋq20�Z��2
            hzlo20.address_lines_phonetic       AS phone_num                --�ڋq20�d�b�ԍ�
     FROM xxcmm_cust_accounts       xxca20,                   --�ڋq20�ڋq�ǉ����
          xxcmm_cust_accounts       xxca10,                   --�ڋq10�ڋq�ǉ����
          hz_cust_accounts          hzca20,                   --�ڋq20�ڋq�}�X�^
          hz_parties                hzpa20,                   --�ڋq20�p�[�e�B
          hz_cust_acct_sites        hcas20,                   --�ڋq20�ڋq���ݒn
          hz_party_sites            hzps20,                   --�ڋq20�p�[�e�B�T�C�g
          hz_locations              hzlo20                    --�ڋq20�ڋq���Ə�
     WHERE xxca10.customer_id = iv_customer_id
     AND   xxca10.invoice_code = xxca20.customer_code                        --�ڋq10�ڋq�ǉ����.�������p�R�[�h = �ڋq20�ڋq�ǉ����.�ڋq�R�[�h
     AND   hzca20.customer_class_code = cv_customer_class_code20             --�ڋq20�ڋq�}�X�^.�ڋq�敪 = '20'(�������p)
     AND   hzca20.cust_account_id = xxca20.customer_id                       --�ڋq20�ڋq�}�X�^.�ڋqID = �ڋq20�ڋq�ǉ����.�ڋq�R�[�h
     AND   hzca20.party_id = hzpa20.party_id                                 --�ڋq20�ڋq�}�X�^.�p�[�e�BID = �ڋq20�p�[�e�B.�p�[�e�BID
     AND   hzca20.cust_account_id = hcas20.cust_account_id                   --�ڋq20�ڋq�}�X�^.�ڋqID = �ڋq2-���ݒn.�ڋqID
     AND   hcas20.party_site_id = hzps20.party_site_id                       --�ڋq���ݒn20.�p�[�e�B�T�C�g = �ڋq20�p�[�e�B�T�C�g.�ڋq21�p�[�e�B�T�C�gID
     AND   hzps20.location_id = hzlo20.location_id;                          --�ڋq20�p�[�e�B�T�C�g.���Ə�ID = �ڋq20�ڋq���Ə�.���Ə�ID
--
    get_20account_rec get_20account_cur%ROWTYPE;
--
-- Add 2013.12.13 Ver1.60 Start
    -- *** ���[�J����O ***
    update_work_expt  EXCEPTION;
-- Add 2013.12.13 Ver1.60 End
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- ���{�ꕶ����擾
    -- ====================================================
    lv_format_date_jpymd4 := SUBSTRB(xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr  -- 'XXCFR'
                                                                        ,cv_dict_ymd4 )  -- YYYY"�N"MM"��"DD"��"
                                    ,1
                                    ,5000);
    lv_format_date_jpymd2 := SUBSTRB(xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr  -- 'XXCFR'
                                                                        ,cv_dict_ymd2 )  -- YY"�N"MM"��"DD"��"
                                    ,1
                                    ,5000);
    lv_format_date_year := SUBSTRB(xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr  -- 'XXCFR'
                                                                      ,cv_dict_year )  -- �N
                                  ,1
                                  ,5000);
    lv_format_date_month := SUBSTRB(xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr   -- 'XXCFR'
                                                                       ,cv_dict_month )  -- ��
                                   ,1
                                   ,5000);
    lv_format_date_bank := SUBSTRB(xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr  -- 'XXCFR'
                                                                      ,cv_dict_bank )  -- ��s
                                  ,1
                                  ,5000);
    lv_format_date_central := SUBSTRB(xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr    -- 'XXCFR'
                                                                        ,cv_dict_central )  -- �{�X
                                     ,1
                                     ,5000);
    lv_format_date_branch := SUBSTRB(xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr    -- 'XXCFR'
                                                                        ,cv_dict_branch )  -- �x�X
                                     ,1
                                     ,5000);
    lv_format_date_account := SUBSTRB(xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr    -- 'XXCFR'
                                                                         ,cv_dict_account ) -- ����
                                     ,1
                                     ,5000);
    lv_format_date_current := SUBSTRB(xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr    -- 'XXCFR'
                                                                         ,cv_dict_current ) -- ����
                                    ,1
                                    ,5000);
    lv_format_zip_mark := SUBSTRB(xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr     -- 'XXCFR'
                                                                     ,cv_dict_zip_mark ) -- ��
                                  ,1
                                  ,5000);
    lv_format_bank_dummy := SUBSTRB(xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr     -- 'XXCFR'
                                                                       ,cv_dict_bank_damy ) -- D
                                   ,1
                                   ,5000);
--
    -- ====================================================
    -- ���[�O�����b�Z�[�W�擾
    -- ====================================================
    lv_no_data_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr      -- 'XXCFR'
                                                       ,cv_msg_003a18_014 ) -- ���[�O�����b�Z�[�W
                              ,1
                              ,5000);
--
    -- ====================================================
    -- ���[�N�e�[�u���ւ̓o�^
    -- ====================================================
    BEGIN
--
      -- ���|�Ǘ���ڋq�w�莞
      IF (iv_customer_code14 IS NOT NULL) THEN
        OPEN get_all_account_cur FOR cv_get_14account_cur USING iv_customer_code14;
      -- �����������p�ڋq�w�莞
      ELSIF (iv_customer_code21 IS NOT NULL) THEN
        OPEN get_all_account_cur FOR cv_get_21account_cur USING iv_customer_code21;
      -- �������p�ڋq�w�莞
      ELSIF (iv_customer_code20 IS NOT NULL) THEN
-- Modify 2009-11-11 Ver1.10 Start
--        OPEN get_all_account_cur FOR cv_get_20account_cur USING iv_customer_code20;
        OPEN get_all_account_cur FOR cv_get_20account_cur USING iv_customer_code20,iv_customer_code20;
-- Modify 2009-11-11 Ver1.10 End
      -- �ڋq�w�莞
      ELSIF (iv_customer_code10 IS NOT NULL) THEN
-- Modify 2009-11-11 Ver1.10 Start
--        OPEN get_all_account_cur FOR cv_get_10account_cur USING iv_customer_code10;
        OPEN get_all_account_cur FOR cv_get_10account_cur USING iv_customer_code10,iv_customer_code10;
-- Modify 2009-11-11 Ver1.10 End
      -- �p�����[�^�w��Ȃ���
      ELSE
        OPEN get_all_account_cur FOR cv_get_all_account_cur;
      END IF;
--
      <<get_account10_loop>>
      LOOP 
        FETCH get_all_account_cur INTO all_account_rec;
        EXIT WHEN get_all_account_cur%NOTFOUND;
--
        -- ����������P�ʂ����󂠂�̃p�^�[���̂ݏ������s��
        IF all_account_rec.invoice_printing_unit IN (cv_invoice_printing_unit_a1,
                                                     cv_invoice_printing_unit_a2,
                                                     cv_invoice_printing_unit_a3,
                                                     cv_invoice_printing_unit_a4,
                                                     cv_invoice_printing_unit_a5,
-- Mod 2015.07.31 Ver1.80 Start
--                                                     cv_invoice_printing_unit_a6) THEN
                                                     cv_invoice_printing_unit_a6,
                                                     cv_invoice_printing_unit_a7,
-- Mod 2016.03.31 Ver1.90 Start
--                                                     cv_invoice_printing_unit_a8) THEN
                                                     cv_invoice_printing_unit_a8,
-- Ver.1.92 [��QE_�{�ғ�_15307] MOD START
--                                                     cv_invoice_printing_unit_a9) THEN
                                                     cv_invoice_printing_unit_a9,
                                                     cv_invoice_printing_unit_a10) THEN
-- Ver.1.92 [��QE_�{�ғ�_15307] MOD END
-- Mod 2016.03.31 Ver1.90 End
-- Mod 2015.07.31 Ver1.80 End
          -- �ڋq�敪14�̌ڋq�ɕR�Â��A�ڋq�敪14�̌ڋq���擾
          OPEN get_14account_cur(all_account_rec.customer_id);
          FETCH get_14account_cur INTO get_14account_rec;
--
          -- �R�Â��ڋq�敪14�̌ڋq�����݂��Ȃ��ꍇ
          IF get_14account_cur%NOTFOUND THEN
            -- �S�Џo�͌�������̏ꍇ�ƁA�Y���ڋq�̐������_�����O�C�����[�U�̏�������ƈ�v����ꍇ
            IF (all_account_rec.bill_base_code = gt_user_dept)
            OR (gv_inv_all_flag = cv_status_yes)
            THEN
              -- �ڋq�敪14���݂Ȃ����b�Z�[�W�o��
              put_account_warning(iv_customer_class_code => cv_customer_class_code14
                                 ,iv_customer_code       => all_account_rec.customer_code
                                 ,ov_errbuf              => lv_errbuf
                                 ,ov_retcode             => lv_retcode
                                 ,ov_errmsg              => lv_errmsg);
              IF (lv_retcode = cv_status_error) THEN
                --(�G���[����)
                RAISE global_process_expt;
              END IF;
            END IF;
--
          --����������P�� = 'A1'
          ELSIF (all_account_rec.invoice_printing_unit = cv_invoice_printing_unit_a1)
           AND  ((gv_inv_all_flag = cv_status_yes) OR 
                 ((gv_inv_all_flag = cv_status_no) AND  (get_14account_rec.bill_base_code = gt_user_dept)))  -- �������_ = ���O�C�����[�U�̋��_
           AND  (get_14account_rec.bill_tax_div IN (cv_syohizei_kbn_inc2,cv_syohizei_kbn_inc3))  -- ����ŋ敪 IN (����(�`�[),����(�P��))
-- Modify 2014.03.27 Ver1.70 Start
--           AND  (get_14account_rec.bill_invoice_type = cv_inv_prt_type) -- �������o�͌`�� = 1.�ɓ����W��
           AND  (get_14account_rec.bill_invoice_type = iv_bill_invoice_type) -- �������o�͌`�� = ���̓p�����[�^�u�������o�͌`���v
-- Modify 2014.03.27 Ver1.70 End
          AND  (get_14account_rec.cons_inv_flag = cv_enabled_yes) -- �ꊇ�������� = 'Y'(�L��)
-- Add 2010.12.10 Ver1.30 Start
           AND  (get_14account_rec.bill_pub_cycle = NVL(iv_bill_pub_cycle, get_14account_rec.bill_pub_cycle)) -- ���������s�T�C�N�� = ���̓p�����[�^�u���������s�T�C�N���v
-- Add 2010.12.10 Ver1.30 End
          THEN
            INSERT INTO xxcfr_rep_st_invoice_inc_tax_d(
              report_id               , -- ���[�h�c
              issue_date              , -- ���s��
              zip_code                , -- �X�֔ԍ�
              send_address1           , -- �Z���P
              send_address2           , -- �Z���Q
              send_address3           , -- �Z���R
              bill_cust_code          , -- �ڋq�R�[�h(�\�[�g���Q)
              bill_cust_name          , -- �ڋq��
              location_code           , -- �S�����_�R�[�h
              location_name           , -- �S�����_��
              phone_num               , -- �d�b�ԍ�
              target_date             , -- �Ώ۔N��
              payment_cust_code       , -- ������ڋq�R�[�h
              payment_cust_name       , -- ������ڋq��
              ar_concat_text          , -- ���|�Ǘ��R�[�h�A��������(�e���ڂ̊ԂɃX�y�[�X��}��)
              payment_due_date        , -- �����\���
              bank_account            , -- �U���������
              ship_cust_code          , -- ���[�i��ڋq�R�[�h
              ship_cust_name          , -- ���[�i��ڋq��
-- Add 2011.01.17 Ver1.40 Start
              store_code              , -- �X�܃R�[�h
              store_code_sort         , -- �X�܃R�[�h(�\�[�g�p)
              ship_account_number     , -- �[�i��ڋq�R�[�h(�\�[�g�p)
              invo_account_number     , -- �����p�ڋq�R�[�h(�\�[�g�p)
-- Add 2011.01.17 Ver1.40 End
              slip_date               , -- �`�[���t(�\�[�g���R)
              slip_num                , -- �`�[No(�\�[�g���S)
              slip_sum                , -- �`�[���z(�`�[�ԍ��P�ʂŏW�v�����l)
              slip_tax_sum            , -- �`�[�Ŋz(�`�[�ԍ��P�ʂŏW�v�����l)
-- Del 2019.09.03 Ver1.93 Start
-- Add 2013.12.13 Ver1.60 Start
--              tax_rate                , -- ����ŗ�(�ҏW�p)
-- Add 2013.12.13 Ver1.60 End
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
              description             , -- �E�v
              category                , -- ���󕪗�(�ҏW�p)
-- Add 2019.09.03 Ver1.93 End
-- Add 2014.03.27 Ver1.70 Start
              outsourcing_flag        , -- �Ǝ҈ϑ��t���O
-- Add 2014.03.27 Ver1.70 End
              data_empty_message      , -- 0�����b�Z�[�W
              created_by              , -- �쐬��
              creation_date           , -- �쐬��
              last_updated_by         , -- �ŏI�X�V��
              last_update_date        , -- �ŏI�X�V��
              last_update_login       , -- �ŏI�X�V���O�C��
              request_id              , -- �v��ID
              program_application_id  , -- �A�v���P�[�V����ID
              program_id              , -- �R���J�����g�E�v���O����ID
              program_update_date     ) -- �v���O�����X�V��
            SELECT cv_pkg_name                                                        report_id        , -- ���[�h�c
                   TO_CHAR(xih.inv_creation_date,lv_format_date_jpymd4)               issue_date       , -- ���s��
                   DECODE(get_14account_rec.bill_postal_code,
                          NULL,NULL,
                          lv_format_zip_mark||SUBSTR(get_14account_rec.bill_postal_code,1,3)||'-'||
                          SUBSTR(get_14account_rec.bill_postal_code,4,4))                 zip_code         , -- �X�֔ԍ�
                   get_14account_rec.bill_state||get_14account_rec.bill_city                  send_address1    , -- �Z���P
                   get_14account_rec.bill_address1                                        send_address2    , -- �Z���Q
                   get_14account_rec.bill_address2                                        send_address3    , -- �Z���R
                   get_14account_rec.cash_account_number                                  bill_cust_code   , -- �ڋq�R�[�h(�\�[�g���Q)
                   get_14account_rec.cash_account_name                                    bill_cust_name   , -- �ڋq��
                   get_14account_rec.bill_base_code                                       bill_base_code   , -- �S�����_�R�[�h
                   xffvv.description                                                  location_name    , -- �S�����_��
                   xxcfr_common_pkg.get_base_target_tel_num(get_14account_rec.cash_account_number)  phone_num        , -- �d�b�ԍ�
                   SUBSTR(xih.object_month,1,4)||lv_format_date_year||
                   SUBSTR(xih.object_month,5,2)||lv_format_date_month                 target_date      , -- �Ώ۔N��
                   get_14account_rec.cash_account_number                              payment_cust_code, -- ������ڋq�R�[�h
                   get_14account_rec.cash_account_name                                payment_cust_name, -- ������ڋq��
                   get_14account_rec.cash_account_number||' '||xih.term_name          ar_concat_text   , -- ���|�Ǘ��R�[�h�A��������
                   TO_CHAR(xih.payment_date, lv_format_date_jpymd2)                   payment_due_date , -- �����\���
                   CASE
                   WHEN account.bank_account_num IS NULL THEN
                     NULL
                   ELSE
                     DECODE(SUBSTR(account.bank_number,1,1),
                     lv_format_bank_dummy,NULL,                                       -- �_�~�[��s�̏ꍇ��NULL
                     CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
                       CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
                         account.bank_name
                       ELSE
                         account.bank_name ||lv_format_date_bank
                       END
                     ELSE
                      account.bank_name 
                     END||' '||                                                       -- ��s��
                     CASE WHEN INSTR(account.bank_branch_name
                                    ,lv_format_date_central)>0 THEN
                       account.bank_branch_name
                     ELSE
                       account.bank_branch_name||lv_format_date_branch 
                     END||' '||                                                       -- �x�X��
                     DECODE( account.bank_account_type,
                             1,lv_format_date_account,
                             2,lv_format_date_current,
                             account.bank_account_type) ||' '||                       -- �������
                     account.bank_account_num ||' '||                                 -- �����ԍ�
                     account.account_holder_name||' '||                               -- �������`�l
                     account.account_holder_name_alt)                                 -- �������`�l�J�i��
                   END                                                                account_data     , -- �U���������
                   xil.ship_cust_code                                                 ship_cust_code   , -- �[�i��ڋq�R�[�h
                   hzp.party_name                                                     ship_cust_name   , -- �[�i��ڋq��
-- Add 2011.01.17 Ver1.40 Start
                   LPAD(NVL(all_account_rec.store_code,'0'),10,'0')                   store_code         ,  -- �X�܃R�[�h
                   LPAD(NVL(all_account_rec.store_code,'0'),10,'0')                   store_code_sort    ,  -- �X�܃R�[�h(�\�[�g�p)
                   xil.ship_cust_code                                                 ship_account_number,  -- �[�i��ڋq�R�[�h(�\�[�g�p)
                   NULL                                                               invo_account_number,  -- �����p�ڋq�R�[�h(�\�[�g�p)
-- Add 2011.01.17 Ver1.40 End
                   TO_CHAR(DECODE(xil.acceptance_date,
                                  NULL,xil.delivery_date,
                                  xil.acceptance_date),
                           cv_format_date_ymds2)                                      slip_date        , -- �`�[���t(�\�[�g���R)
                   xil.slip_num                                                       slip_num         , -- �`�[No(�\�[�g���S)
                   SUM(xil.ship_amount)                                               slip_sum         , -- �`�[���z(�Ŕ��z)
                   SUM(xil.tax_amount)                                                tax_sum          , -- �`�[�Ŋz
-- Del 2019.09.03 Ver1.93 Start
-- Add 2013.12.13 Ver1.60 Start
--                   xil.tax_rate                                                       tax_rate         , -- ����ŗ�
-- Add 2013.12.13 Ver1.60 End
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
                   NVL(flvv.attribute1,' ')                                           description      , -- �E�v
                   flvv.attribute2                                                    category         , -- ��������(�ҏW�p)
-- Add 2019.09.03 Ver1.93 End
-- Add 2014.03.27 Ver1.70 Start
                   CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
                     cv_os_flag_y
                   ELSE
                     NULL
                   END                                                                outsourcing_flag , -- �Ǝ҈ϑ��t���O
-- Add 2014.03.27 Ver1.70 End
                   NULL                                                               data_empty_message,-- 0�����b�Z�[�W
                   cn_created_by                                                      created_by,             -- �쐬��
                   cd_creation_date                                                   creation_date,          -- �쐬��
                   cn_last_updated_by                                                 last_updated_by,        -- �ŏI�X�V��
                   cd_last_update_date                                                last_update_date,       -- �ŏI�X�V��
                   cn_last_update_login                                               last_update_login,      -- �ŏI�X�V���O�C��
                   cn_request_id                                                      request_id,             -- �v��ID
                   cn_program_application_id                                          program_application_id, -- �A�v���P�[�V����ID
                   cn_program_id                                                      program_id,
                                                                                      -- �R���J�����g�E�v���O����ID
                   cd_program_update_date                                             program_update_date     -- �v���O�����X�V��
            FROM xxcfr_invoice_headers          xih  , -- �����w�b�_
                 xxcfr_invoice_lines            xil  , -- ��������
                 hz_cust_accounts               hzca , -- �ڋq10�ڋq�}�X�^
                 hz_parties                     hzp  , -- �ڋq10�p�[�e�B�}�X�^
                 (SELECT all_account_rec.customer_code ship_cust_code,
                         rcrm.customer_id             customer_id,
                         abb.bank_number              bank_number,
                         abb.bank_name                bank_name,
                         abb.bank_branch_name         bank_branch_name,
                         abaa.bank_account_type       bank_account_type,
                         abaa.bank_account_num        bank_account_num,
                         abaa.account_holder_name     account_holder_name,
                         abaa.account_holder_name_alt account_holder_name_alt
                  FROM ra_cust_receipt_methods        rcrm , --�x�����@���
                       ar_receipt_method_accounts_all arma , --AR�x�����@����
                       ap_bank_accounts_all           abaa , --��s����
                       ap_bank_branches               abb    --��s�x�X
                  WHERE rcrm.primary_flag = cv_enabled_yes
                    AND get_14account_rec.cash_account_id = rcrm.customer_id
                    AND gd_target_date BETWEEN rcrm.start_date AND NVL(rcrm.end_date ,cd_max_date)
                    AND rcrm.site_use_id IS NOT NULL
                    AND rcrm.receipt_method_id = arma.receipt_method_id(+)
                    AND arma.bank_account_id = abaa.bank_account_id(+)
                    AND abaa.bank_branch_id = abb.bank_branch_id(+)
                    AND arma.org_id = gn_org_id
                    AND abaa.org_id = gn_org_id             ) account,    -- ��s�����r���[
                 (SELECT flex_value,
                         description
                  FROM   fnd_flex_values_vl ffv
                  WHERE  EXISTS
                         (SELECT  'X'
                          FROM    fnd_flex_value_sets
                          WHERE   flex_value_set_name = cv_ffv_set_name_dept
                          AND     flex_value_set_id   = ffv.flex_value_set_id)) xffvv
-- Add 2019.09.03 Ver1.93 Start
                ,fnd_lookup_values_vl           flvv    -- �Q�ƕ\
-- Add 2019.09.03 Ver1.93 End
            WHERE xih.invoice_id = xil.invoice_id                        -- �ꊇ������ID
              AND xil.cutoff_date = gd_target_date                       -- �p�����[�^�D����
              AND xil.ship_cust_code = account.ship_cust_code(+)         -- �O�������̂��߂̃_�~�[����
              AND xih.set_of_books_id = gn_set_of_bks_id
              AND xih.org_id = gn_org_id
              AND get_14account_rec.bill_base_code = xffvv.flex_value
              AND xil.ship_cust_code = all_account_rec.customer_code
              AND hzca.cust_account_id = all_account_rec.customer_id
              AND hzp.party_id = hzca.party_id
-- Add 2019.09.03 Ver1.93 Start
              AND flvv.lookup_type(+)  = cv_xxcfr_tax_category
              AND xil.tax_code         = flvv.lookup_code(+)
              AND flvv.enabled_flag(+) = cv_enabled_yes
-- Add 2019.09.03 Ver1.93 End
            GROUP BY cv_pkg_name,
                     xih.inv_creation_date,
                     DECODE(get_14account_rec.bill_postal_code,
                                 NULL,NULL,
                                 lv_format_zip_mark||SUBSTR(get_14account_rec.bill_postal_code,1,3)||'-'||
                                 SUBSTR(get_14account_rec.bill_postal_code,4,4)),
                     get_14account_rec.bill_state||get_14account_rec.bill_city,
                     get_14account_rec.bill_address1,
                     get_14account_rec.bill_address2,
                     get_14account_rec.cash_account_number,
                     get_14account_rec.cash_account_name,
                     xffvv.description,
                     xih.object_month,
                     get_14account_rec.cash_account_number||' '||xih.term_name,
                     xih.payment_date,
                     CASE
                     WHEN account.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(account.bank_number,1,1),
                       lv_format_bank_dummy,NULL,                                       -- �_�~�[��s�̏ꍇ��NULL
                       CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
                         CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
                           account.bank_name
                         ELSE
                           account.bank_name ||lv_format_date_bank
                         END
                       ELSE
                        account.bank_name 
                       END||' '||                                                       -- ��s��
                       CASE WHEN INSTR(account.bank_branch_name
                                      ,lv_format_date_central)>0 THEN
                         account.bank_branch_name
                       ELSE
                         account.bank_branch_name||lv_format_date_branch 
                       END||' '||                                                       -- �x�X��
                       DECODE( account.bank_account_type,
                               1,lv_format_date_account,
                               2,lv_format_date_current,
                               account.bank_account_type) ||' '||                       -- �������
                       account.bank_account_num ||' '||                                 -- �����ԍ�
                       account.account_holder_name||' '||                               -- �������`�l
                       account.account_holder_name_alt)                                 -- �������`�l�J�i��
                     END,
                     xil.ship_cust_code,
                     hzp.party_name,
                     TO_CHAR(DECODE(xil.acceptance_date,
                                    NULL,xil.delivery_date,
                                    xil.acceptance_date),
                     cv_format_date_ymds2),
-- Modify 2013.12.13 Ver1.60 Start
--                     xil.slip_num;
                     xil.slip_num,
-- Modify 2014.03.27 Ver1.70 Start
--                     xil.tax_rate
-- Del 2019.09.03 Ver1.93 Start
--                     xil.tax_rate,
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
                     flvv.attribute1,
                     flvv.attribute2,
-- Add 2019.09.03 Ver1.93 End
                     CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
                       cv_os_flag_y
                     ELSE
                       NULL
                     END
-- Modify 2014.03.27 Ver1.70 End
                     ;
-- Modify 2013.12.13 Ver1.60 End
--
            gn_target_cnt := gn_target_cnt + SQL%ROWCOUNT;
--
          --����������P�� = 'A2'
          ELSIF (all_account_rec.invoice_printing_unit = cv_invoice_printing_unit_a2)
           AND  (get_14account_rec.bill_tax_div IN (cv_syohizei_kbn_inc2,cv_syohizei_kbn_inc3))  -- ����ŋ敪 IN (����(�`�[),����(�P��))
-- Modify 2014.03.27 Ver1.70 Start
--           AND  (get_14account_rec.bill_invoice_type = cv_inv_prt_type) -- �������o�͌`�� = 1.�ɓ����W��
           AND  (get_14account_rec.bill_invoice_type = iv_bill_invoice_type) -- �������o�͌`�� = ���̓p�����[�^�u�������o�͌`���v
-- Modify 2014.03.27 Ver1.70 End
           AND  (get_14account_rec.cons_inv_flag = cv_enabled_yes) -- �ꊇ�������� = 'Y'(�L��)
-- Add 2010.12.10 Ver1.30 Start
           AND  (get_14account_rec.bill_pub_cycle = NVL(iv_bill_pub_cycle, get_14account_rec.bill_pub_cycle)) -- ���������s�T�C�N�� = ���̓p�����[�^�u���������s�T�C�N���v
-- Add 2010.12.10 Ver1.30 End
          THEN
            OPEN get_21account_cur(all_account_rec.customer_id);
            FETCH get_21account_cur INTO get_21account_rec;
--
            --�ڋq�敪21�̌ڋq�����݂��Ȃ��ꍇ
            IF get_21account_cur%NOTFOUND THEN
              -- �S�Џo�͌�������̏ꍇ�ƁA�Y���ڋq�̐������_�����O�C�����[�U�̏�������ƈ�v����ꍇ
              IF (all_account_rec.bill_base_code = gt_user_dept)
              OR (gv_inv_all_flag = cv_status_yes)
              THEN
                -- �ڋq�敪21���݂Ȃ����b�Z�[�W�o��
                put_account_warning(iv_customer_class_code => cv_customer_class_code21
                                   ,iv_customer_code       => all_account_rec.customer_code
                                   ,ov_errbuf              => lv_errbuf
                                   ,ov_retcode             => lv_retcode
                                   ,ov_errmsg              => lv_errmsg);
                IF (lv_retcode = cv_status_error) THEN
                  --(�G���[����)
                  RAISE global_process_expt;
                END IF;
              END IF;
            --
            -- �S�Џo�͌������� OR �����������p�ڋq�̐������_�����O�C�����[�U�̏�������̏ꍇ
            ELSIF ((gv_inv_all_flag = cv_status_yes) OR 
                  ((gv_inv_all_flag = cv_status_no) AND  (get_21account_rec.bill_base_code21 = gt_user_dept)))  -- �������_ = ���O�C�����[�U�̋��_
            THEN
              INSERT INTO xxcfr_rep_st_invoice_inc_tax_d(
                report_id               , -- ���[�h�c
                issue_date              , -- ���s��
                zip_code                , -- �X�֔ԍ�
                send_address1           , -- �Z���P
                send_address2           , -- �Z���Q
                send_address3           , -- �Z���R
                bill_cust_code          , -- �ڋq�R�[�h(�\�[�g���Q)
                bill_cust_name          , -- �ڋq��
                location_code           , -- �S�����_�R�[�h
                location_name           , -- �S�����_��
                phone_num               , -- �d�b�ԍ�
                target_date             , -- �Ώ۔N��
                payment_cust_code       , -- ������ڋq�R�[�h
                payment_cust_name       , -- ������ڋq��
                ar_concat_text          , -- ���|�Ǘ��R�[�h�A��������(�e���ڂ̊ԂɃX�y�[�X��}��)
                payment_due_date        , -- �����\���
                bank_account            , -- �U���������
                ship_cust_code          , -- ���[�i��ڋq�R�[�h
                ship_cust_name          , -- ���[�i��ڋq��
-- Add 2011.01.17 Ver1.40 Start
                store_code              , -- �X�܃R�[�h
                store_code_sort         , -- �X�܃R�[�h(�\�[�g�p)
                ship_account_number     , -- �[�i��ڋq�R�[�h(�\�[�g�p)
                invo_account_number     , -- �����p�ڋq�R�[�h(�\�[�g�p)
-- Add 2011.01.17 Ver1.40 End
                slip_date               , -- �`�[���t(�\�[�g���R)
                slip_num                , -- �`�[No(�\�[�g���S)
                slip_sum                , -- �`�[���z(�`�[�ԍ��P�ʂŏW�v�����l)
                slip_tax_sum            , -- �`�[�Ŋz(�`�[�ԍ��P�ʂŏW�v�����l)
-- Del 2019.09.03 Ver1.93 Start
-- Add 2013.12.13 Ver1.60 Start
--                tax_rate                , -- ����ŗ�(�ҏW�p)
-- Add 2013.12.13 Ver1.60 End
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
                description             , -- �E�v
                category                , -- ���󕪗�(�ҏW�p)
-- Add 2019.09.03 Ver1.93 End
-- Add 2014.03.27 Ver1.70 Start
                outsourcing_flag        , -- �Ǝ҈ϑ��t���O
-- Add 2014.03.27 Ver1.70 End
                data_empty_message      , -- 0�����b�Z�[�W
                created_by              , -- �쐬��
                creation_date           , -- �쐬��
                last_updated_by         , -- �ŏI�X�V��
                last_update_date        , -- �ŏI�X�V��
                last_update_login       , -- �ŏI�X�V���O�C��
                request_id              , -- �v��ID
                program_application_id  , -- �A�v���P�[�V����ID
                program_id              , -- �R���J�����g�E�v���O����ID
                program_update_date     ) -- �v���O�����X�V��
              SELECT cv_pkg_name                                                        report_id        , -- ���[�h�c
                     TO_CHAR(xih.inv_creation_date,lv_format_date_jpymd4)               issue_date       , -- ���s��
                     DECODE(get_21account_rec.bill_postal_code,
                            NULL,NULL,
                            lv_format_zip_mark||SUBSTR(get_21account_rec.bill_postal_code,1,3)||'-'||
                            SUBSTR(get_21account_rec.bill_postal_code,4,4))                 zip_code         , -- �X�֔ԍ�
                     get_21account_rec.bill_state||get_21account_rec.bill_city                  send_address1    , -- �Z���P
                     get_21account_rec.bill_address1                                        send_address2    , -- �Z���Q
                     get_21account_rec.bill_address2                                        send_address3    , -- �Z���R
                     get_21account_rec.bill_account_number                                  bill_cust_code   , -- �ڋq�R�[�h(�\�[�g���Q)
                     get_21account_rec.bill_account_name                                    bill_cust_name   , -- �ڋq��
                     get_21account_rec.bill_base_code21                                     bill_base_code   , -- �S�����_�R�[�h
                     xffvv.description                                                  location_name    , -- �S�����_��
                     xxcfr_common_pkg.get_base_target_tel_num(get_21account_rec.bill_account_number)   phone_num        , -- �d�b�ԍ�
                     SUBSTR(xih.object_month,1,4)||lv_format_date_year||
                     SUBSTR(xih.object_month,5,2)||lv_format_date_month                 target_date      , -- �Ώ۔N��
                     get_14account_rec.cash_account_number                              payment_cust_code, -- ������ڋq�R�[�h
                     get_14account_rec.cash_account_name                                payment_cust_name, -- ������ڋq��
                     get_21account_rec.bill_account_number||' '||xih.term_name          ar_concat_text   , -- ���|�Ǘ��R�[�h�A��������
                     TO_CHAR(xih.payment_date, lv_format_date_jpymd2)                   payment_due_date , -- �����\���
                     CASE
                     WHEN account.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(account.bank_number,1,1),
                       lv_format_bank_dummy,NULL,                                       -- �_�~�[��s�̏ꍇ��NULL
                       CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
                         CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
                           account.bank_name
                         ELSE
                           account.bank_name ||lv_format_date_bank
                         END
                       ELSE
                        account.bank_name 
                       END||' '||                                                       -- ��s��
                       CASE WHEN INSTR(account.bank_branch_name
                                      ,lv_format_date_central)>0 THEN
                         account.bank_branch_name
                       ELSE
                         account.bank_branch_name||lv_format_date_branch 
                       END||' '||                                                       -- �x�X��
                       DECODE( account.bank_account_type,
                               1,lv_format_date_account,
                               2,lv_format_date_current,
                               account.bank_account_type) ||' '||                       -- �������
                       account.bank_account_num ||' '||                                 -- �����ԍ�
                       account.account_holder_name||' '||                               -- �������`�l
                       account.account_holder_name_alt)                                 -- �������`�l�J�i��
                     END                                                                account_data     , -- �U���������
                     xxca.invoice_code                                                 ship_cust_code   , -- �[�i��ڋq�R�[�h
                     hzp.party_name                                                     ship_cust_name   , -- �[�i��ڋq��
-- Add 2011.01.17 Ver1.40 Start
                     NULL                                                               store_code         ,  -- �X�܃R�[�h
-- Modify 2011.03.10 Ver1.50 Start
--                    LPAD(NVL(all_account_rec.store_code,'0'),10,'0')                   store_code_sort    ,  -- �X�܃R�[�h(�\�[�g�p)
--                    all_account_rec.customer_code                                      ship_account_number,  -- �[�i��ڋq�R�[�h(�\�[�g�p)
                     NULL                                                               store_code_sort    ,  -- �X�܃R�[�h(�\�[�g�p)
                     NULL                                                               ship_account_number,  -- �[�i��ڋq�R�[�h(�\�[�g�p)
-- Modify 2011.03.10 Ver1.50 End
                     xxca.invoice_code                                                  invo_account_number,  -- �����p�ڋq�R�[�h(�\�[�g�p)
-- Add 2011.01.17 Ver1.40 End
                     TO_CHAR(DECODE(xil.acceptance_date,
                                    NULL,xil.delivery_date,
                                    xil.acceptance_date),
                             cv_format_date_ymds2)                                      slip_date        , -- �`�[���t(�\�[�g���R)
                     xil.slip_num                                                       slip_num         , -- �`�[No(�\�[�g���S)
                     SUM(xil.ship_amount)                                               slip_sum         , -- �`�[���z(�Ŕ��z)
                     SUM(xil.tax_amount)                                                tax_sum          , -- �`�[�Ŋz
-- Del 2019.09.03 Ver1.93 Start
-- Add 2013.12.13 Ver1.60 Start
--                     xil.tax_rate                                                       tax_rate         , -- ����ŗ�
-- Add 2013.12.13 Ver1.60 End
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
                     NVL(flvv.attribute1,' ')                                           description      , -- �E�v
                     flvv.attribute2                                                    category         , -- ��������(�ҏW�p)
-- Add 2019.09.03 Ver1.93 End
-- Add 2014.03.27 Ver1.70 Start
                     CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
                       cv_os_flag_y
                     ELSE
                       NULL
                     END                                                                outsourcing_flag , -- �Ǝ҈ϑ��t���O
-- Add 2014.03.27 Ver1.70 End
                     NULL                                                               data_empty_message,-- 0�����b�Z�[�W
                     cn_created_by                                                      created_by,             -- �쐬��
                     cd_creation_date                                                   creation_date,          -- �쐬��
                     cn_last_updated_by                                                 last_updated_by,        -- �ŏI�X�V��
                     cd_last_update_date                                                last_update_date,       -- �ŏI�X�V��
                     cn_last_update_login                                               last_update_login,      -- �ŏI�X�V���O�C��
                     cn_request_id                                                      request_id,             -- �v��ID
                     cn_program_application_id                                          program_application_id, -- �A�v���P�[�V����ID
                     cn_program_id                                                      program_id,
                                                                                        -- �R���J�����g�E�v���O����ID
                     cd_program_update_date                                             program_update_date     -- �v���O�����X�V��
              FROM xxcfr_invoice_headers          xih  , -- �����w�b�_
                   xxcfr_invoice_lines            xil  , -- ��������
                   hz_cust_accounts               hzca , -- �ڋq20�ڋq�}�X�^
                   hz_parties                     hzp  , -- �ڋq20�p�[�e�B�}�X�^
                   xxcmm_cust_accounts            xxca , -- �ڋq10�ǉ����
                   (SELECT all_account_rec.customer_code ship_cust_code,
                           rcrm.customer_id              customer_id,
                           abb.bank_number               bank_number,
                           abb.bank_name                 bank_name,
                           abb.bank_branch_name          bank_branch_name,
                           abaa.bank_account_type        bank_account_type,
                           abaa.bank_account_num         bank_account_num,
                           abaa.account_holder_name      account_holder_name,
                           abaa.account_holder_name_alt  account_holder_name_alt
                    FROM ra_cust_receipt_methods        rcrm , --�x�����@���
                         ar_receipt_method_accounts_all arma , --AR�x�����@����
                         ap_bank_accounts_all           abaa , --��s����
                         ap_bank_branches               abb    --��s�x�X
                    WHERE rcrm.primary_flag = cv_enabled_yes
                      AND get_14account_rec.cash_account_id = rcrm.customer_id
                      AND gd_target_date BETWEEN rcrm.start_date AND NVL(rcrm.end_date ,cd_max_date)
                      AND rcrm.site_use_id IS NOT NULL
                      AND rcrm.receipt_method_id = arma.receipt_method_id(+)
                      AND arma.bank_account_id = abaa.bank_account_id(+)
                      AND abaa.bank_branch_id = abb.bank_branch_id(+)
                      AND arma.org_id = gn_org_id
                      AND abaa.org_id = gn_org_id             ) account,    -- ��s�����r���[
                   (SELECT flex_value,
                           description
                    FROM   fnd_flex_values_vl ffv
                    WHERE  EXISTS
                           (SELECT  'X'
                            FROM    fnd_flex_value_sets
                            WHERE   flex_value_set_name = cv_ffv_set_name_dept
                            AND     flex_value_set_id   = ffv.flex_value_set_id)) xffvv
-- Add 2019.09.03 Ver1.93 Start
                  ,fnd_lookup_values_vl           flvv    -- �Q�ƕ\
-- Add 2019.09.03 Ver1.93 End
              WHERE xih.invoice_id = xil.invoice_id                        -- �ꊇ������ID
                AND xil.cutoff_date = gd_target_date                       -- �p�����[�^�D����
                AND xil.ship_cust_code = account.ship_cust_code(+)         -- �O�������̂��߂̃_�~�[����
                AND xih.set_of_books_id = gn_set_of_bks_id
                AND xih.org_id = gn_org_id
                AND get_21account_rec.bill_base_code21 = xffvv.flex_value
                AND xil.ship_cust_code = all_account_rec.customer_code
                AND xxca.customer_id = all_account_rec.customer_id
                AND hzca.account_number = xxca.invoice_code
                AND hzp.party_id = hzca.party_id
-- Add 2019.09.03 Ver1.93 Start
                AND flvv.lookup_type(+)  = cv_xxcfr_tax_category
                AND xil.tax_code         = flvv.lookup_code(+)
                AND flvv.enabled_flag(+) = cv_enabled_yes
-- Add 2019.09.03 Ver1.93 End
              GROUP BY cv_pkg_name,
                       xih.inv_creation_date,
                       DECODE(get_21account_rec.bill_postal_code,
                                   NULL,NULL,
                                   lv_format_zip_mark||SUBSTR(get_21account_rec.bill_postal_code,1,3)||'-'||
                                   SUBSTR(get_21account_rec.bill_postal_code,4,4)),
                       get_21account_rec.bill_state||get_21account_rec.bill_city,
                       get_21account_rec.bill_address1,
                       get_21account_rec.bill_address2,
                       get_21account_rec.bill_account_number,
                       get_21account_rec.bill_account_name,
                       xffvv.description,
                       xih.object_month,
                       get_14account_rec.cash_account_number,
                       get_14account_rec.cash_account_name,
                       get_21account_rec.bill_account_number||' '||xih.term_name,
                       xih.payment_date,
                       CASE
                       WHEN account.bank_account_num IS NULL THEN
                         NULL
                       ELSE
                         DECODE(SUBSTR(account.bank_number,1,1),
                         lv_format_bank_dummy,NULL,                                       -- �_�~�[��s�̏ꍇ��NULL
                         CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
                           CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
                             account.bank_name
                           ELSE
                             account.bank_name ||lv_format_date_bank
                           END
                         ELSE
                          account.bank_name 
                         END||' '||                                                       -- ��s��
                         CASE WHEN INSTR(account.bank_branch_name
                                        ,lv_format_date_central)>0 THEN
                           account.bank_branch_name
                         ELSE
                           account.bank_branch_name||lv_format_date_branch 
                         END||' '||                                                       -- �x�X��
                         DECODE( account.bank_account_type,
                                 1,lv_format_date_account,
                                 2,lv_format_date_current,
                                 account.bank_account_type) ||' '||                       -- �������
                         account.bank_account_num ||' '||                                 -- �����ԍ�
                         account.account_holder_name||' '||                               -- �������`�l
                         account.account_holder_name_alt)                                 -- �������`�l�J�i��
                       END,
                       xxca.invoice_code,
                       hzp.party_name,
                       TO_CHAR(DECODE(xil.acceptance_date,
                                      NULL,xil.delivery_date,
                                      xil.acceptance_date),
                       cv_format_date_ymds2),
-- Modify 2013.12.13 Ver1.60 Start
--                       xil.slip_num;
                       xil.slip_num,
-- Modify 2014.03.27 Ver1.70 Start
--                       xil.tax_rate
-- Del 2019.09.03 Ver1.93 Start
--                       xil.tax_rate,
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
                       flvv.attribute1,
                       flvv.attribute2,
-- Add 2019.09.03 Ver1.93 End
                       CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
                         cv_os_flag_y
                       ELSE
                         NULL
                       END
-- Modify 2014.03.27 Ver1.70 End
                       ;
-- Modify 2013.12.13 Ver1.60 End
--
              gn_target_cnt := gn_target_cnt + SQL%ROWCOUNT;
--
            ELSE
              NULL;
            END IF;
--
            CLOSE get_21account_cur;
--
          --����������P�� = 'A3'
          ELSIF (all_account_rec.invoice_printing_unit = cv_invoice_printing_unit_a3)
           AND  (get_14account_rec.bill_tax_div IN (cv_syohizei_kbn_inc2,cv_syohizei_kbn_inc3))  -- ����ŋ敪 IN (����(�`�[),����(�P��))
-- Modify 2014.03.27 Ver1.70 Start
--           AND  (get_14account_rec.bill_invoice_type = cv_inv_prt_type) -- �������o�͌`�� = 1.�ɓ����W��
           AND  (get_14account_rec.bill_invoice_type = iv_bill_invoice_type) -- �������o�͌`�� = ���̓p�����[�^�u�������o�͌`���v
-- Modify 2014.03.27 Ver1.70 End
           AND  (get_14account_rec.cons_inv_flag = cv_enabled_yes) -- �ꊇ�������� = 'Y'(�L��)
-- Add 2010.12.10 Ver1.30 Start
           AND  (get_14account_rec.bill_pub_cycle = NVL(iv_bill_pub_cycle, get_14account_rec.bill_pub_cycle)) -- ���������s�T�C�N�� = ���̓p�����[�^�u���������s�T�C�N���v
-- Add 2010.12.10 Ver1.30 End
          THEN
            OPEN get_20account_cur(all_account_rec.customer_id);
            FETCH get_20account_cur INTO get_20account_rec;
            --�ڋq�敪20�̌ڋq�����݂��Ȃ��ꍇ
            IF get_20account_cur%NOTFOUND THEN
              -- �S�Џo�͌�������̏ꍇ�ƁA�Y���ڋq�̐������_�����O�C�����[�U�̏�������ƈ�v����ꍇ
              IF (all_account_rec.bill_base_code = gt_user_dept)
              OR (gv_inv_all_flag = cv_status_yes)
              THEN
                -- �ڋq�敪20���݂Ȃ����b�Z�[�W�o��
                put_account_warning(iv_customer_class_code => cv_customer_class_code20
                                   ,iv_customer_code       => all_account_rec.customer_code
                                   ,ov_errbuf              => lv_errbuf
                                   ,ov_retcode             => lv_retcode
                                   ,ov_errmsg              => lv_errmsg);
                IF (lv_retcode = cv_status_error) THEN
                  --(�G���[����)
                  RAISE global_process_expt;
                END IF;
              END IF;
            ELSIF ((gv_inv_all_flag = cv_status_yes) OR 
                  ((gv_inv_all_flag = cv_status_no) AND  (get_20account_rec.bill_base_code = gt_user_dept)))  -- �������_ = ���O�C�����[�U�̋��_
            THEN
              INSERT INTO xxcfr_rep_st_invoice_inc_tax_d(
                report_id               , -- ���[�h�c
                issue_date              , -- ���s��
                zip_code                , -- �X�֔ԍ�
                send_address1           , -- �Z���P
                send_address2           , -- �Z���Q
                send_address3           , -- �Z���R
                bill_cust_code          , -- �ڋq�R�[�h(�\�[�g���Q)
                bill_cust_name          , -- �ڋq��
                location_code           , -- ���_�R�[�h
                location_name           , -- �S�����_��
                phone_num               , -- �d�b�ԍ�
                target_date             , -- �Ώ۔N��
                payment_cust_code       , -- ������ڋq�R�[�h
                payment_cust_name       , -- ������ڋq��
                ar_concat_text          , -- ���|�Ǘ��R�[�h�A��������(�e���ڂ̊ԂɃX�y�[�X��}��)
                payment_due_date        , -- �����\���
                bank_account            , -- �U���������
                ship_cust_code          , -- ���[�i��ڋq�R�[�h
                ship_cust_name          , -- ���[�i��ڋq��
-- Add 2011.01.17 Ver1.40 Start
                store_code              , -- �X�܃R�[�h
                store_code_sort         , -- �X�܃R�[�h(�\�[�g�p)
                ship_account_number     , -- �[�i��ڋq�R�[�h(�\�[�g�p)
                invo_account_number     , -- �����p�ڋq�R�[�h(�\�[�g�p)
-- Add 2011.01.17 Ver1.40 End
                slip_date               , -- �`�[���t(�\�[�g���R)
                slip_num                , -- �`�[No(�\�[�g���S)
                slip_sum                , -- �`�[���z(�`�[�ԍ��P�ʂŏW�v�����l)
                slip_tax_sum            , -- �`�[�Ŋz(�`�[�ԍ��P�ʂŏW�v�����l)
-- Del 2019.09.03 Ver1.93 Start
-- Add 2013.12.13 Ver1.60 Start
--                tax_rate                , -- ����ŗ�(�ҏW�p)
-- Add 2013.12.13 Ver1.60 End
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
                description             , -- �E�v
                category                , -- ���󕪗�(�ҏW�p)
-- Add 2019.09.03 Ver1.93 End
-- Add 2014.03.27 Ver1.70 Start
                outsourcing_flag        , -- �Ǝ҈ϑ��t���O
-- Add 2014.03.27 Ver1.70 End
                data_empty_message      , -- 0�����b�Z�[�W
                created_by              , -- �쐬��
                creation_date           , -- �쐬��
                last_updated_by         , -- �ŏI�X�V��
                last_update_date        , -- �ŏI�X�V��
                last_update_login       , -- �ŏI�X�V���O�C��
                request_id              , -- �v��ID
                program_application_id  , -- �A�v���P�[�V����ID
                program_id              , -- �R���J�����g�E�v���O����ID
                program_update_date     ) -- �v���O�����X�V��
              SELECT cv_pkg_name                                                        report_id        , -- ���[�h�c
                     TO_CHAR(xih.inv_creation_date,lv_format_date_jpymd4)               issue_date       , -- ���s��
                     DECODE(get_20account_rec.bill_postal_code,
                            NULL,NULL,
                            lv_format_zip_mark||SUBSTR(get_20account_rec.bill_postal_code,1,3)||'-'||
                            SUBSTR(get_20account_rec.bill_postal_code,4,4))                 zip_code         , -- �X�֔ԍ�
                     get_20account_rec.bill_state||get_20account_rec.bill_city                  send_address1    , -- �Z���P
                     get_20account_rec.bill_address1                                        send_address2    , -- �Z���Q
                     get_20account_rec.bill_address2                                        send_address3    , -- �Z���R
                     get_20account_rec.bill_account_number                                  bill_cust_code   , -- �ڋq�R�[�h(�\�[�g���Q)
                     get_20account_rec.bill_account_name                                    bill_cust_name   , -- �ڋq��
                     get_20account_rec.bill_base_code                                       bill_base_code   , -- �S�����_�R�[�h
                     xffvv.description                                                  location_name    , -- �S�����_��
                     xxcfr_common_pkg.get_base_target_tel_num(get_20account_rec.bill_account_number)   phone_num        , -- �d�b�ԍ�
                     SUBSTR(xih.object_month,1,4)||lv_format_date_year||
                     SUBSTR(xih.object_month,5,2)||lv_format_date_month                 target_date      , -- �Ώ۔N��
                     get_14account_rec.cash_account_number                              payment_cust_code, -- ������ڋq�R�[�h
                     get_14account_rec.cash_account_name                                payment_cust_name, -- ������ڋq��
                     get_20account_rec.bill_account_number||' '||xih.term_name          ar_concat_text   , -- ���|�Ǘ��R�[�h�A��������
                     TO_CHAR(xih.payment_date, lv_format_date_jpymd2)                   payment_due_date , -- �����\���
                     CASE
                     WHEN account.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(account.bank_number,1,1),
                       lv_format_bank_dummy,NULL,                                       -- �_�~�[��s�̏ꍇ��NULL
                       CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
                         CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
                           account.bank_name
                         ELSE
                           account.bank_name ||lv_format_date_bank
                         END
                       ELSE
                        account.bank_name 
                       END||' '||                                                       -- ��s��
                       CASE WHEN INSTR(account.bank_branch_name
                                      ,lv_format_date_central)>0 THEN
                         account.bank_branch_name
                       ELSE
                         account.bank_branch_name||lv_format_date_branch 
                       END||' '||                                                       -- �x�X��
                       DECODE( account.bank_account_type,
                               1,lv_format_date_account,
                               2,lv_format_date_current,
                               account.bank_account_type) ||' '||                       -- �������
                       account.bank_account_num ||' '||                                 -- �����ԍ�
                       account.account_holder_name||' '||                               -- �������`�l
                       account.account_holder_name_alt)                                 -- �������`�l�J�i��
                     END                                                                account_data     , -- �U���������
                     xil.ship_cust_code                                                 ship_cust_code   , -- �[�i��ڋq�R�[�h
                     hzp.party_name                                                     ship_cust_name   , -- �[�i��ڋq��
-- Add 2011.01.17 Ver1.40 Start
                     LPAD(NVL(all_account_rec.store_code,'0'),10,'0')                   store_code         ,  -- �X�܃R�[�h
                     LPAD(NVL(all_account_rec.store_code,'0'),10,'0')                   store_code_sort    ,  -- �X�܃R�[�h(�\�[�g�p)
                     xil.ship_cust_code                                                 ship_account_number,  -- �[�i��ڋq�R�[�h(�\�[�g�p)
                     NULL                                                               invo_account_number,  -- �����p�ڋq�R�[�h(�\�[�g�p)
-- Add 2011.01.17 Ver1.40 End
                     TO_CHAR(DECODE(xil.acceptance_date,
                                    NULL,xil.delivery_date,
                                    xil.acceptance_date),
                             cv_format_date_ymds2)                                      slip_date        , -- �`�[���t(�\�[�g���R)
                     xil.slip_num                                                       slip_num         , -- �`�[No(�\�[�g���S)
                     SUM(xil.ship_amount)                                               slip_sum         , -- �`�[���z(�Ŕ��z)
                     SUM(xil.tax_amount)                                                tax_sum          , -- �`�[�Ŋz
-- Del 2019.09.03 Ver1.93 Start
-- Add 2013.12.13 Ver1.60 Start
--                     xil.tax_rate                                                       tax_rate         , -- ����ŗ�
-- Add 2013.12.13 Ver1.60 End
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
                     NVL(flvv.attribute1,' ')                                           description      , -- �E�v
                     flvv.attribute2                                                    category         , -- ��������(�ҏW�p)
-- Add 2019.09.03 Ver1.93 End
-- Add 2014.03.27 Ver1.70 Start
                     CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
                       cv_os_flag_y
                     ELSE
                       NULL
                     END                                                                outsourcing_flag , -- �Ǝ҈ϑ��t���O
-- Add 2014.03.27 Ver1.70 End
                     NULL                                                               data_empty_message,-- 0�����b�Z�[�W
                     cn_created_by                                                      created_by,             -- �쐬��
                     cd_creation_date                                                   creation_date,          -- �쐬��
                     cn_last_updated_by                                                 last_updated_by,        -- �ŏI�X�V��
                     cd_last_update_date                                                last_update_date,       -- �ŏI�X�V��
                     cn_last_update_login                                               last_update_login,      -- �ŏI�X�V���O�C��
                     cn_request_id                                                      request_id,             -- �v��ID
                     cn_program_application_id                                          program_application_id, -- �A�v���P�[�V����ID
                     cn_program_id                                                      program_id,
                                                                                        -- �R���J�����g�E�v���O����ID
                     cd_program_update_date                                             program_update_date     -- �v���O�����X�V��
              FROM xxcfr_invoice_headers          xih  , -- �����w�b�_
                   xxcfr_invoice_lines            xil  , -- ��������
                   hz_cust_accounts               hzca , -- �ڋq10�ڋq�}�X�^
                   hz_parties                     hzp  , -- �ڋq10�p�[�e�B�}�X�^
                   (SELECT all_account_rec.customer_code ship_cust_code,
                           rcrm.customer_id             customer_id,
                           abb.bank_number              bank_number,
                           abb.bank_name                bank_name,
                           abb.bank_branch_name         bank_branch_name,
                           abaa.bank_account_type       bank_account_type,
                           abaa.bank_account_num        bank_account_num,
                           abaa.account_holder_name     account_holder_name,
                           abaa.account_holder_name_alt account_holder_name_alt
                    FROM ra_cust_receipt_methods        rcrm , --�x�����@���
                         ar_receipt_method_accounts_all arma , --AR�x�����@����
                         ap_bank_accounts_all           abaa , --��s����
                         ap_bank_branches               abb    --��s�x�X
                    WHERE rcrm.primary_flag = cv_enabled_yes
                      AND get_14account_rec.cash_account_id = rcrm.customer_id
                      AND gd_target_date BETWEEN rcrm.start_date AND NVL(rcrm.end_date ,cd_max_date)
                      AND rcrm.site_use_id IS NOT NULL
                      AND rcrm.receipt_method_id = arma.receipt_method_id(+)
                      AND arma.bank_account_id = abaa.bank_account_id(+)
                      AND abaa.bank_branch_id = abb.bank_branch_id(+)
                      AND arma.org_id = gn_org_id
                      AND abaa.org_id = gn_org_id             ) account,    -- ��s�����r���[
                   (SELECT flex_value,
                           description
                    FROM   fnd_flex_values_vl ffv
                    WHERE  EXISTS
                           (SELECT  'X'
                            FROM    fnd_flex_value_sets
                            WHERE   flex_value_set_name = cv_ffv_set_name_dept
                            AND     flex_value_set_id   = ffv.flex_value_set_id)) xffvv
-- Add 2019.09.03 Ver1.93 Start
                  ,fnd_lookup_values_vl           flvv    -- �Q�ƕ\
-- Add 2019.09.03 Ver1.93 End
              WHERE xih.invoice_id = xil.invoice_id                        -- �ꊇ������ID
                AND xil.cutoff_date = gd_target_date                       -- �p�����[�^�D����
                AND xil.ship_cust_code = account.ship_cust_code(+)         -- �O�������̂��߂̃_�~�[����
                AND xih.set_of_books_id = gn_set_of_bks_id
                AND xih.org_id = gn_org_id
                AND get_20account_rec.bill_base_code = xffvv.flex_value
                AND xil.ship_cust_code = all_account_rec.customer_code
                AND hzca.cust_account_id = all_account_rec.customer_id
                AND hzp.party_id = hzca.party_id
-- Add 2019.09.03 Ver1.93 Start
                AND flvv.lookup_type(+)  = cv_xxcfr_tax_category
                AND xil.tax_code         = flvv.lookup_code(+)
                AND flvv.enabled_flag(+) = cv_enabled_yes
-- Add 2019.09.03 Ver1.93 End
              GROUP BY cv_pkg_name,
                       xih.inv_creation_date,
                       DECODE(get_20account_rec.bill_postal_code,
                                   NULL,NULL,
                                   lv_format_zip_mark||SUBSTR(get_20account_rec.bill_postal_code,1,3)||'-'||
                                   SUBSTR(get_20account_rec.bill_postal_code,4,4)),
                       get_20account_rec.bill_state||get_20account_rec.bill_city,
                       get_20account_rec.bill_address1,
                       get_20account_rec.bill_address2,
                       get_20account_rec.bill_account_number,
                       get_20account_rec.bill_account_name,
                       xffvv.description,
                       xih.object_month,
                       get_14account_rec.cash_account_number,
                       get_14account_rec.cash_account_name,
                       get_20account_rec.bill_account_number||' '||xih.term_name,
                       xih.payment_date,
                       CASE
                       WHEN account.bank_account_num IS NULL THEN
                         NULL
                       ELSE
                         DECODE(SUBSTR(account.bank_number,1,1),
                         lv_format_bank_dummy,NULL,                                       -- �_�~�[��s�̏ꍇ��NULL
                         CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
                           CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
                             account.bank_name
                           ELSE
                             account.bank_name ||lv_format_date_bank
                           END
                         ELSE
                          account.bank_name 
                         END||' '||                                                       -- ��s��
                         CASE WHEN INSTR(account.bank_branch_name
                                        ,lv_format_date_central)>0 THEN
                           account.bank_branch_name
                         ELSE
                           account.bank_branch_name||lv_format_date_branch 
                         END||' '||                                                       -- �x�X��
                         DECODE( account.bank_account_type,
                                 1,lv_format_date_account,
                                 2,lv_format_date_current,
                                 account.bank_account_type) ||' '||                       -- �������
                         account.bank_account_num ||' '||                                 -- �����ԍ�
                         account.account_holder_name||' '||                               -- �������`�l
                         account.account_holder_name_alt)                                 -- �������`�l�J�i��
                       END,
                       xil.ship_cust_code,
                       hzp.party_name,
                       TO_CHAR(DECODE(xil.acceptance_date,
                                      NULL,xil.delivery_date,
                                      xil.acceptance_date),
                       cv_format_date_ymds2),
-- Modify 2013.12.13 Ver1.60 Start
--                       xil.slip_num;
                       xil.slip_num,
-- Modify 2014.03.27 Ver1.70 Start
--                     xil.tax_rate
-- Del 2019.09.03 Ver1.93 Start
--                     xil.tax_rate,
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
                     flvv.attribute1,
                     flvv.attribute2,
-- Add 2019.09.03 Ver1.93 End
                     CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
                       cv_os_flag_y
                     ELSE
                       NULL
                     END
-- Modify 2014.03.27 Ver1.70 End
                     ;
-- Modify 2013.12.13 Ver1.60 End
--
              gn_target_cnt := gn_target_cnt + SQL%ROWCOUNT;
--
            ELSE
              NULL;
            END IF;
--
            CLOSE get_20account_cur;
--
          --����������P�� = 'A4'
          ELSIF (all_account_rec.invoice_printing_unit = cv_invoice_printing_unit_a4)
           AND  (get_14account_rec.bill_tax_div IN (cv_syohizei_kbn_inc2,cv_syohizei_kbn_inc3))  -- ����ŋ敪 IN (����(�`�[),����(�P��))
-- Modify 2014.03.27 Ver1.70 Start
--           AND  (get_14account_rec.bill_invoice_type = cv_inv_prt_type) -- �������o�͌`�� = 1.�ɓ����W��
           AND  (get_14account_rec.bill_invoice_type = iv_bill_invoice_type) -- �������o�͌`�� = ���̓p�����[�^�u�������o�͌`���v
-- Modify 2014.03.27 Ver1.70 End
           AND  (get_14account_rec.cons_inv_flag = cv_enabled_yes) -- �ꊇ�������� = 'Y'(�L��)
-- Add 2010.12.10 Ver1.30 Start
           AND  (get_14account_rec.bill_pub_cycle = NVL(iv_bill_pub_cycle, get_14account_rec.bill_pub_cycle)) -- ���������s�T�C�N�� = ���̓p�����[�^�u���������s�T�C�N���v
-- Add 2010.12.10 Ver1.30 End
          THEN
            OPEN get_21account_cur(all_account_rec.customer_id);
            FETCH get_21account_cur INTO get_21account_rec;
            --�ڋq�敪21�̌ڋq�����݂��Ȃ��ꍇ
            IF get_21account_cur%NOTFOUND THEN
              -- �S�Џo�͌�������̏ꍇ�ƁA�Y���ڋq�̐������_�����O�C�����[�U�̏�������ƈ�v����ꍇ
              IF (all_account_rec.bill_base_code = gt_user_dept)
              OR (gv_inv_all_flag = cv_status_yes)
              THEN
                -- �ڋq�敪21���݂Ȃ����b�Z�[�W�o��
                put_account_warning(iv_customer_class_code => cv_customer_class_code21
                                   ,iv_customer_code       => all_account_rec.customer_code
                                   ,ov_errbuf              => lv_errbuf
                                   ,ov_retcode             => lv_retcode
                                   ,ov_errmsg              => lv_errmsg);
                IF (lv_retcode = cv_status_error) THEN
                  --(�G���[����)
                  RAISE global_process_expt;
                END IF;
              END IF;
            ELSIF ((gv_inv_all_flag = cv_status_yes) OR 
                  ((gv_inv_all_flag = cv_status_no) AND  (get_21account_rec.bill_base_code20 = gt_user_dept)))  -- �������_ = ���O�C�����[�U�̋��_
            THEN
              INSERT INTO xxcfr_rep_st_invoice_inc_tax_d(
                report_id               , -- ���[�h�c
                issue_date              , -- ���s��
                zip_code                , -- �X�֔ԍ�
                send_address1           , -- �Z���P
                send_address2           , -- �Z���Q
                send_address3           , -- �Z���R
                bill_cust_code          , -- �ڋq�R�[�h(�\�[�g���Q)
                bill_cust_name          , -- �ڋq��
                location_code           , -- �S�����_�R�[�h
                location_name           , -- �S�����_��
                phone_num               , -- �d�b�ԍ�
                target_date             , -- �Ώ۔N��
                payment_cust_code       , -- ������ڋq�R�[�h
                payment_cust_name       , -- ������ڋq��
                ar_concat_text          , -- ���|�Ǘ��R�[�h�A��������(�e���ڂ̊ԂɃX�y�[�X��}��)
                payment_due_date        , -- �����\���
                bank_account            , -- �U���������
                ship_cust_code          , -- ���[�i��ڋq�R�[�h
                ship_cust_name          , -- ���[�i��ڋq��
-- Add 2011.01.17 Ver1.40 Start
                store_code              , -- �X�܃R�[�h
                store_code_sort         , -- �X�܃R�[�h(�\�[�g�p)
                ship_account_number     , -- �[�i��ڋq�R�[�h(�\�[�g�p)
                invo_account_number     , -- �����p�ڋq�R�[�h(�\�[�g�p)
-- Add 2011.01.17 Ver1.40 End
                slip_date               , -- �`�[���t(�\�[�g���R)
                slip_num                , -- �`�[No(�\�[�g���S)
                slip_sum                , -- �`�[���z(�`�[�ԍ��P�ʂŏW�v�����l)
                slip_tax_sum            , -- �`�[�Ŋz(�`�[�ԍ��P�ʂŏW�v�����l)
-- Del 2019.09.03 Ver1.93 Start
-- Add 2013.12.13 Ver1.60 Start
--                tax_rate                , -- ����ŗ�(�ҏW�p)
-- Add 2013.12.13 Ver1.60 End
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
                description             , -- �E�v
                category                , -- ���󕪗�(�ҏW�p)
-- Add 2019.09.03 Ver1.93 End
-- Add 2014.03.27 Ver1.70 Start
                outsourcing_flag        , -- �Ǝ҈ϑ��t���O
-- Add 2014.03.27 Ver1.70 End
                data_empty_message      , -- 0�����b�Z�[�W
                created_by              , -- �쐬��
                creation_date           , -- �쐬��
                last_updated_by         , -- �ŏI�X�V��
                last_update_date        , -- �ŏI�X�V��
                last_update_login       , -- �ŏI�X�V���O�C��
                request_id              , -- �v��ID
                program_application_id  , -- �A�v���P�[�V����ID
                program_id              , -- �R���J�����g�E�v���O����ID
                program_update_date     ) -- �v���O�����X�V��
              SELECT cv_pkg_name                                                        report_id        , -- ���[�h�c
                     TO_CHAR(xih.inv_creation_date,lv_format_date_jpymd4)               issue_date       , -- ���s��
                     DECODE(get_21account_rec.bill_postal_code,
                            NULL,NULL,
                            lv_format_zip_mark||SUBSTR(get_21account_rec.bill_postal_code,1,3)||'-'||
                            SUBSTR(get_21account_rec.bill_postal_code,4,4))                 zip_code         , -- �X�֔ԍ�
                     get_21account_rec.bill_state||get_21account_rec.bill_city                  send_address1    , -- �Z���P
                     get_21account_rec.bill_address1                                        send_address2    , -- �Z���Q
                     get_21account_rec.bill_address2                                        send_address3    , -- �Z���R
                     get_21account_rec.bill_account_number                                  bill_cust_code   , -- �ڋq�R�[�h(�\�[�g���Q)
                     get_21account_rec.bill_account_name                                    bill_cust_name   , -- �ڋq��
                     get_21account_rec.bill_base_code20                                     bill_base_code   , -- �S�����_�R�[�h
                     xffvv.description                                                  location_name    , -- �S�����_��
                     xxcfr_common_pkg.get_base_target_tel_num(xxca.invoice_code)    phone_num        , -- �d�b�ԍ�
                     SUBSTR(xih.object_month,1,4)||lv_format_date_year||
                     SUBSTR(xih.object_month,5,2)||lv_format_date_month                 target_date      , -- �Ώ۔N��
                     get_14account_rec.cash_account_number                              payment_cust_code, -- ������ڋq�R�[�h
                     get_14account_rec.cash_account_name                                payment_cust_name, -- ������ڋq��
                     get_21account_rec.bill_account_number||' '||xih.term_name          ar_concat_text   , -- ���|�Ǘ��R�[�h�A��������
                     TO_CHAR(xih.payment_date, lv_format_date_jpymd2)                   payment_due_date , -- �����\���
                     CASE
                     WHEN account.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(account.bank_number,1,1),
                       lv_format_bank_dummy,NULL,                                       -- �_�~�[��s�̏ꍇ��NULL
                       CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
                         CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
                           account.bank_name
                         ELSE
                           account.bank_name ||lv_format_date_bank
                         END
                       ELSE
                        account.bank_name 
                       END||' '||                                                       -- ��s��
                       CASE WHEN INSTR(account.bank_branch_name
                                      ,lv_format_date_central)>0 THEN
                         account.bank_branch_name
                       ELSE
                         account.bank_branch_name||lv_format_date_branch 
                       END||' '||                                                       -- �x�X��
                       DECODE( account.bank_account_type,
                               1,lv_format_date_account,
                               2,lv_format_date_current,
                               account.bank_account_type) ||' '||                       -- �������
                       account.bank_account_num ||' '||                                 -- �����ԍ�
                       account.account_holder_name||' '||                               -- �������`�l
                       account.account_holder_name_alt)                                 -- �������`�l�J�i��
                     END                                                                account_data     , -- �U���������
                     xxca.invoice_code                                                 ship_cust_code   , -- �[�i��ڋq�R�[�h
                     hzp.party_name                                                     ship_cust_name   , -- �[�i��ڋq��
-- Add 2011.01.17 Ver1.40 Start
                     NULL                                                               store_code         ,  -- �X�܃R�[�h
-- Modify 2011.03.10 Ver1.50 Start
--                    LPAD(NVL(all_account_rec.store_code,'0'),10,'0')                   store_code_sort    ,  -- �X�܃R�[�h(�\�[�g�p)
--                    all_account_rec.customer_code                                      ship_account_number,  -- �[�i��ڋq�R�[�h(�\�[�g�p)
                     NULL                                                               store_code_sort    ,  -- �X�܃R�[�h(�\�[�g�p)
                     NULL                                                               ship_account_number,  -- �[�i��ڋq�R�[�h(�\�[�g�p)
-- Modify 2011.03.10 Ver1.50 End
                     xxca.invoice_code                                                  invo_account_number,  -- �����p�ڋq�R�[�h(�\�[�g�p)
-- Add 2011.01.17 Ver1.40 End
                     TO_CHAR(DECODE(xil.acceptance_date,
                                    NULL,xil.delivery_date,
                                    xil.acceptance_date),
                             cv_format_date_ymds2)                                      slip_date        , -- �`�[���t(�\�[�g���R)
                     xil.slip_num                                                       slip_num         , -- �`�[No(�\�[�g���S)
                     SUM(xil.ship_amount)                                               slip_sum         , -- �`�[���z(�Ŕ��z)
                     SUM(xil.tax_amount)                                                tax_sum          , -- �`�[�Ŋz
-- Del 2019.09.03 Ver1.93 Start
-- Add 2013.12.13 Ver1.60 Start
--                     xil.tax_rate                                                       tax_rate         , -- ����ŗ�
-- Add 2013.12.13 Ver1.60 End
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
                     NVL(flvv.attribute1,' ')                                           description      , -- �E�v
                     flvv.attribute2                                                    category         , -- ��������(�ҏW�p)
-- Add 2019.09.03 Ver1.93 End
-- Add 2014.03.27 Ver1.70 Start
                     CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
                       cv_os_flag_y
                     ELSE
                       NULL
                     END                                                                outsourcing_flag , -- �Ǝ҈ϑ��t���O
-- Add 2014.03.27 Ver1.70 End
                     NULL                                                               data_empty_message,-- 0�����b�Z�[�W
                     cn_created_by                                                      created_by,             -- �쐬��
                     cd_creation_date                                                   creation_date,          -- �쐬��
                     cn_last_updated_by                                                 last_updated_by,        -- �ŏI�X�V��
                     cd_last_update_date                                                last_update_date,       -- �ŏI�X�V��
                     cn_last_update_login                                               last_update_login,      -- �ŏI�X�V���O�C��
                     cn_request_id                                                      request_id,             -- �v��ID
                     cn_program_application_id                                          program_application_id, -- �A�v���P�[�V����ID
                     cn_program_id                                                      program_id,
                                                                                        -- �R���J�����g�E�v���O����ID
                     cd_program_update_date                                             program_update_date     -- �v���O�����X�V��
              FROM xxcfr_invoice_headers          xih  , -- �����w�b�_
                   xxcfr_invoice_lines            xil  , -- ��������
                   hz_cust_accounts               hzca , -- �ڋq20�ڋq�}�X�^
                   hz_parties                     hzp  , -- �ڋq20�p�[�e�B�}�X�^
                   xxcmm_cust_accounts            xxca , -- �ڋq10�ǉ����
                   (SELECT all_account_rec.customer_code ship_cust_code,
                           rcrm.customer_id             customer_id,
                           abb.bank_number              bank_number,
                           abb.bank_name                bank_name,
                           abb.bank_branch_name         bank_branch_name,
                           abaa.bank_account_type       bank_account_type,
                           abaa.bank_account_num        bank_account_num,
                           abaa.account_holder_name     account_holder_name,
                           abaa.account_holder_name_alt account_holder_name_alt
                    FROM ra_cust_receipt_methods        rcrm , --�x�����@���
                         ar_receipt_method_accounts_all arma , --AR�x�����@����
                         ap_bank_accounts_all           abaa , --��s����
                         ap_bank_branches               abb    --��s�x�X
                    WHERE rcrm.primary_flag = cv_enabled_yes
                      AND get_14account_rec.cash_account_id = rcrm.customer_id
                      AND gd_target_date BETWEEN rcrm.start_date AND NVL(rcrm.end_date ,cd_max_date)
                      AND rcrm.site_use_id IS NOT NULL
                      AND rcrm.receipt_method_id = arma.receipt_method_id(+)
                      AND arma.bank_account_id = abaa.bank_account_id(+)
                      AND abaa.bank_branch_id = abb.bank_branch_id(+)
                      AND arma.org_id = gn_org_id
                      AND abaa.org_id = gn_org_id             ) account,    -- ��s�����r���[
                   (SELECT flex_value,
                           description
                    FROM   fnd_flex_values_vl ffv
                    WHERE  EXISTS
                           (SELECT  'X'
                            FROM    fnd_flex_value_sets
                            WHERE   flex_value_set_name = cv_ffv_set_name_dept
                            AND     flex_value_set_id   = ffv.flex_value_set_id)) xffvv
-- Add 2019.09.03 Ver1.93 Start
                  ,fnd_lookup_values_vl           flvv   -- �Q�ƕ\
-- Add 2019.09.03 Ver1.93 End
              WHERE xih.invoice_id = xil.invoice_id                        -- �ꊇ������ID
                AND xil.cutoff_date = gd_target_date                       -- �p�����[�^�D����
                AND xil.ship_cust_code = account.ship_cust_code(+)         -- �O�������̂��߂̃_�~�[����
                AND xih.set_of_books_id = gn_set_of_bks_id
                AND xih.org_id = gn_org_id
                AND get_21account_rec.bill_base_code20 = xffvv.flex_value
                AND xil.ship_cust_code = all_account_rec.customer_code
                AND xxca.customer_id = all_account_rec.customer_id
                AND hzca.account_number = xxca.invoice_code
                AND hzp.party_id = hzca.party_id
-- Add 2019.09.03 Ver1.93 Start
                AND flvv.lookup_type(+)  = cv_xxcfr_tax_category
                AND xil.tax_code         = flvv.lookup_code(+)
                AND flvv.enabled_flag(+) = cv_enabled_yes
-- Add 2019.09.03 Ver1.93 End
              GROUP BY cv_pkg_name,
                       xih.inv_creation_date,
                       DECODE(get_21account_rec.bill_postal_code,
                                   NULL,NULL,
                                   lv_format_zip_mark||SUBSTR(get_21account_rec.bill_postal_code,1,3)||'-'||
                                   SUBSTR(get_21account_rec.bill_postal_code,4,4)),
                       get_21account_rec.bill_state||get_21account_rec.bill_city,
                       get_21account_rec.bill_address1,
                       get_21account_rec.bill_address2,
                       get_21account_rec.bill_account_number,
                       get_21account_rec.bill_account_name,
                       xffvv.description,
                       xih.object_month,
                       get_14account_rec.cash_account_number,
                       get_14account_rec.cash_account_name,
                       get_21account_rec.bill_account_number||' '||xih.term_name,
                       xih.payment_date,
                       CASE
                       WHEN account.bank_account_num IS NULL THEN
                         NULL
                       ELSE
                         DECODE(SUBSTR(account.bank_number,1,1),
                         lv_format_bank_dummy,NULL,                                       -- �_�~�[��s�̏ꍇ��NULL
                         CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
                           CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
                             account.bank_name
                           ELSE
                             account.bank_name ||lv_format_date_bank
                           END
                         ELSE
                          account.bank_name 
                         END||' '||                                                       -- ��s��
                         CASE WHEN INSTR(account.bank_branch_name
                                        ,lv_format_date_central)>0 THEN
                           account.bank_branch_name
                         ELSE
                           account.bank_branch_name||lv_format_date_branch 
                         END||' '||                                                       -- �x�X��
                         DECODE( account.bank_account_type,
                                 1,lv_format_date_account,
                                 2,lv_format_date_current,
                                 account.bank_account_type) ||' '||                       -- �������
                         account.bank_account_num ||' '||                                 -- �����ԍ�
                         account.account_holder_name||' '||                               -- �������`�l
                         account.account_holder_name_alt)                                 -- �������`�l�J�i��
                       END,
                       xxca.invoice_code,
                       hzp.party_name,
                       TO_CHAR(DECODE(xil.acceptance_date,
                                      NULL,xil.delivery_date,
                                      xil.acceptance_date),
                       cv_format_date_ymds2),
-- Modify 2013.12.13 Ver1.60 Start
--                       xil.slip_num;
                       xil.slip_num,
-- Modify 2014.03.27 Ver1.70 Start
--                       xil.tax_rate
-- Del 2019.09.03 Ver1.93 Start
--                       xil.tax_rate,
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
                       flvv.attribute1,
                       flvv.attribute2,
-- Add 2019.09.03 Ver1.93 End
                       CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
                         cv_os_flag_y
                       ELSE
                         NULL
                       END
-- Modify 2014.03.27 Ver1.70 End
                       ;
-- Modify 2013.12.13 Ver1.60 End
--
              gn_target_cnt := gn_target_cnt + SQL%ROWCOUNT;
--
            ELSE
              NULL;
            END IF;
--
            CLOSE get_21account_cur;
--
          --����������P�� = 'A5'
          ELSIF (all_account_rec.invoice_printing_unit = cv_invoice_printing_unit_a5)
           AND  ((gv_inv_all_flag = cv_status_yes) OR 
                 ((gv_inv_all_flag = cv_status_no) AND  (all_account_rec.bill_base_code = gt_user_dept)))  -- �������_ = ���O�C�����[�U�̋��_
           AND  (get_14account_rec.bill_tax_div IN (cv_syohizei_kbn_inc2,cv_syohizei_kbn_inc3))  -- ����ŋ敪 IN (����(�`�[),����(�P��))
-- Modify 2014.03.27 Ver1.70 Start
--           AND  (get_14account_rec.bill_invoice_type = cv_inv_prt_type) -- �������o�͌`�� = 1.�ɓ����W��
           AND  (get_14account_rec.bill_invoice_type = iv_bill_invoice_type) -- �������o�͌`�� = ���̓p�����[�^�u�������o�͌`���v
-- Modify 2014.03.27 Ver1.70 End
           AND  (get_14account_rec.cons_inv_flag = cv_enabled_yes) -- �ꊇ�������� = 'Y'(�L��)
-- Add 2010.12.10 Ver1.30 Start
           AND  (get_14account_rec.bill_pub_cycle = NVL(iv_bill_pub_cycle, get_14account_rec.bill_pub_cycle)) -- ���������s�T�C�N�� = ���̓p�����[�^�u���������s�T�C�N���v
-- Add 2010.12.10 Ver1.30 End
          THEN
            INSERT INTO xxcfr_rep_st_invoice_inc_tax_d(
              report_id               , -- ���[�h�c
              issue_date              , -- ���s��
              zip_code                , -- �X�֔ԍ�
              send_address1           , -- �Z���P
              send_address2           , -- �Z���Q
              send_address3           , -- �Z���R
              bill_cust_code          , -- �ڋq�R�[�h(�\�[�g���Q)
              bill_cust_name          , -- �ڋq��
              location_code           , -- �S�����_�R�[�h
              location_name           , -- �S�����_��
              phone_num               , -- �d�b�ԍ�
              target_date             , -- �Ώ۔N��
              payment_cust_code       , -- ������ڋq�R�[�h
              payment_cust_name       , -- ������ڋq��
              ar_concat_text          , -- ���|�Ǘ��R�[�h�A��������(�e���ڂ̊ԂɃX�y�[�X��}��)
              payment_due_date        , -- �����\���
              bank_account            , -- �U���������
              ship_cust_code          , -- ���[�i��ڋq�R�[�h
              ship_cust_name          , -- ���[�i��ڋq��
-- Add 2011.01.17 Ver1.40 Start
              store_code              , -- �X�܃R�[�h
              store_code_sort         , -- �X�܃R�[�h(�\�[�g�p)
              ship_account_number     , -- �[�i��ڋq�R�[�h(�\�[�g�p)
              invo_account_number     , -- �����p�ڋq�R�[�h(�\�[�g�p)
-- Add 2011.01.17 Ver1.40 End
              slip_date               , -- �`�[���t(�\�[�g���R)
              slip_num                , -- �`�[No(�\�[�g���S)
              slip_sum                , -- �`�[���z(�`�[�ԍ��P�ʂŏW�v�����l)
              slip_tax_sum            , -- �`�[�Ŋz(�`�[�ԍ��P�ʂŏW�v�����l)
-- Del 2019.09.03 Ver1.93 Start
-- Add 2013.12.13 Ver1.60 Start
--              tax_rate                , -- ����ŗ�(�ҏW�p)
-- Add 2013.12.13 Ver1.60 End
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
              description             , -- �E�v
              category                , -- ���󕪗�(�ҏW�p)
-- Add 2019.09.03 Ver1.93 End
-- Add 2014.03.27 Ver1.70 Start
              outsourcing_flag        , -- �Ǝ҈ϑ��t���O
-- Add 2014.03.27 Ver1.70 End
              data_empty_message      , -- 0�����b�Z�[�W
              created_by              , -- �쐬��
              creation_date           , -- �쐬��
              last_updated_by         , -- �ŏI�X�V��
              last_update_date        , -- �ŏI�X�V��
              last_update_login       , -- �ŏI�X�V���O�C��
              request_id              , -- �v��ID
              program_application_id  , -- �A�v���P�[�V����ID
              program_id              , -- �R���J�����g�E�v���O����ID
              program_update_date     ) -- �v���O�����X�V��
            SELECT cv_pkg_name                                                        report_id        , -- ���[�h�c
                   TO_CHAR(xih.inv_creation_date,lv_format_date_jpymd4)               issue_date       , -- ���s��
                   DECODE(get_14account_rec.bill_postal_code,
                          NULL,NULL,
                          lv_format_zip_mark||SUBSTR(get_14account_rec.bill_postal_code,1,3)||'-'||
                          SUBSTR(get_14account_rec.bill_postal_code,4,4))                 zip_code         , -- �X�֔ԍ�
                   get_14account_rec.bill_state||get_14account_rec.bill_city                  send_address1    , -- �Z���P
                   get_14account_rec.bill_address1                                        send_address2    , -- �Z���Q
                   get_14account_rec.bill_address2                                        send_address3    , -- �Z���R
                   get_14account_rec.cash_account_number                                  bill_cust_code   , -- �ڋq�R�[�h(�\�[�g���Q)
                   get_14account_rec.cash_account_name                                    bill_cust_name   , -- �ڋq��
                   all_account_rec.bill_base_code                                         bill_base_code   , -- �S�����_�R�[�h
                   xffvv.description                                                  location_name    , -- �S�����_��
                   xxcfr_common_pkg.get_base_target_tel_num(xil.ship_cust_code)  phone_num             , -- �d�b�ԍ�
                   SUBSTR(xih.object_month,1,4)||lv_format_date_year||
                   SUBSTR(xih.object_month,5,2)||lv_format_date_month                 target_date      , -- �Ώ۔N��
                   get_14account_rec.cash_account_number                              payment_cust_code, -- ������ڋq�R�[�h
                   get_14account_rec.cash_account_name                                payment_cust_name, -- ������ڋq��
                   get_14account_rec.cash_account_number||' '||xih.term_name          ar_concat_text   , -- ���|�Ǘ��R�[�h�A��������
                   TO_CHAR(xih.payment_date, lv_format_date_jpymd2)                   payment_due_date , -- �����\���
                   CASE
                   WHEN account.bank_account_num IS NULL THEN
                     NULL
                   ELSE
                     DECODE(SUBSTR(account.bank_number,1,1),
                     lv_format_bank_dummy,NULL,                                       -- �_�~�[��s�̏ꍇ��NULL
                     CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
                       CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
                         account.bank_name
                       ELSE
                         account.bank_name ||lv_format_date_bank
                       END
                     ELSE
                      account.bank_name 
                     END||' '||                                                       -- ��s��
                     CASE WHEN INSTR(account.bank_branch_name
                                    ,lv_format_date_central)>0 THEN
                       account.bank_branch_name
                     ELSE
                       account.bank_branch_name||lv_format_date_branch 
                     END||' '||                                                       -- �x�X��
                     DECODE( account.bank_account_type,
                             1,lv_format_date_account,
                             2,lv_format_date_current,
                             account.bank_account_type) ||' '||                       -- �������
                     account.bank_account_num ||' '||                                 -- �����ԍ�
                     account.account_holder_name||' '||                               -- �������`�l
                     account.account_holder_name_alt)                                 -- �������`�l�J�i��
                   END                                                                account_data     , -- �U���������
                   xil.ship_cust_code                                                 ship_cust_code   , -- �[�i��ڋq�R�[�h
                   hzp.party_name                                                     ship_cust_name   , -- �[�i��ڋq��
-- Add 2011.01.17 Ver1.40 Start
                   LPAD(NVL(all_account_rec.store_code,'0'),10,'0')                   store_code         ,  -- �X�܃R�[�h
                   LPAD(NVL(all_account_rec.store_code,'0'),10,'0')                   store_code_sort    ,  -- �X�܃R�[�h(�\�[�g�p)
                   xil.ship_cust_code                                                 ship_account_number,  -- �[�i��ڋq�R�[�h(�\�[�g�p)
                   NULL                                                               invo_account_number,  -- �����p�ڋq�R�[�h(�\�[�g�p)
-- Add 2011.01.17 Ver1.40 End
                   TO_CHAR(DECODE(xil.acceptance_date,
                                  NULL,xil.delivery_date,
                                  xil.acceptance_date),
                           cv_format_date_ymds2)                                      slip_date        , -- �`�[���t(�\�[�g���R)
                   xil.slip_num                                                       slip_num         , -- �`�[No(�\�[�g���S)
                   SUM(xil.ship_amount)                                               slip_sum         , -- �`�[���z(�Ŕ��z)
                   SUM(xil.tax_amount)                                                tax_sum          , -- �`�[�Ŋz
-- Del 2019.09.03 Ver1.93 Start
-- Add 2013.12.13 Ver1.60 Start
--                   xil.tax_rate                                                       tax_rate         , -- ����ŗ�
-- Add 2013.12.13 Ver1.60 End
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
                   NVL(flvv.attribute1,' ')                                            description      , -- �E�v
                   flvv.attribute2                                                    category         , -- ��������(�ҏW�p)
-- Add 2019.09.03 Ver1.93 End
-- Add 2014.03.27 Ver1.70 Start
                   CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
                     cv_os_flag_y
                   ELSE
                     NULL
                   END                                                                outsourcing_flag , -- �Ǝ҈ϑ��t���O
-- Add 2014.03.27 Ver1.70 End
                   NULL                                                               data_empty_message,-- 0�����b�Z�[�W
                   cn_created_by                                                      created_by,             -- �쐬��
                   cd_creation_date                                                   creation_date,          -- �쐬��
                   cn_last_updated_by                                                 last_updated_by,        -- �ŏI�X�V��
                   cd_last_update_date                                                last_update_date,       -- �ŏI�X�V��
                   cn_last_update_login                                               last_update_login,      -- �ŏI�X�V���O�C��
                   cn_request_id                                                      request_id,             -- �v��ID
                   cn_program_application_id                                          program_application_id, -- �A�v���P�[�V����ID
                   cn_program_id                                                      program_id,
                                                                                      -- �R���J�����g�E�v���O����ID
                   cd_program_update_date                                             program_update_date     -- �v���O�����X�V��
            FROM xxcfr_invoice_headers          xih  , -- �����w�b�_
                 xxcfr_invoice_lines            xil  , -- ��������
                 hz_cust_accounts               hzca , -- �ڋq10�ڋq�}�X�^
                 hz_parties                     hzp  , -- �ڋq10�p�[�e�B�}�X�^
                 (SELECT all_account_rec.customer_code ship_cust_code,
                         rcrm.customer_id             customer_id,
                         abb.bank_number              bank_number,
                         abb.bank_name                bank_name,
                         abb.bank_branch_name         bank_branch_name,
                         abaa.bank_account_type       bank_account_type,
                         abaa.bank_account_num        bank_account_num,
                         abaa.account_holder_name     account_holder_name,
                         abaa.account_holder_name_alt account_holder_name_alt
                  FROM ra_cust_receipt_methods        rcrm , --�x�����@���
                       ar_receipt_method_accounts_all arma , --AR�x�����@����
                       ap_bank_accounts_all           abaa , --��s����
                       ap_bank_branches               abb    --��s�x�X
                  WHERE rcrm.primary_flag = cv_enabled_yes
                    AND get_14account_rec.cash_account_id = rcrm.customer_id
                    AND gd_target_date BETWEEN rcrm.start_date AND NVL(rcrm.end_date ,cd_max_date)
                    AND rcrm.site_use_id IS NOT NULL
                    AND rcrm.receipt_method_id = arma.receipt_method_id(+)
                    AND arma.bank_account_id = abaa.bank_account_id(+)
                    AND abaa.bank_branch_id = abb.bank_branch_id(+)
                    AND arma.org_id = gn_org_id
                    AND abaa.org_id = gn_org_id             ) account,    -- ��s�����r���[
                 (SELECT flex_value,
                         description
                  FROM   fnd_flex_values_vl ffv
                  WHERE  EXISTS
                         (SELECT  'X'
                          FROM    fnd_flex_value_sets
                          WHERE   flex_value_set_name = cv_ffv_set_name_dept
                          AND     flex_value_set_id   = ffv.flex_value_set_id)) xffvv
-- Add 2019.09.03 Ver1.93 Start
                ,fnd_lookup_values_vl           flvv    -- �Q�ƕ\
-- Add 2019.09.03 Ver1.93 End
            WHERE xih.invoice_id = xil.invoice_id                        -- �ꊇ������ID
              AND xil.cutoff_date = gd_target_date                       -- �p�����[�^�D����
              AND xil.ship_cust_code = account.ship_cust_code(+)         -- �O�������̂��߂̃_�~�[����
              AND xih.set_of_books_id = gn_set_of_bks_id
              AND xih.org_id = gn_org_id
              AND all_account_rec.bill_base_code = xffvv.flex_value
              AND xil.ship_cust_code = all_account_rec.customer_code
              AND hzca.cust_account_id = all_account_rec.customer_id
              AND hzp.party_id = hzca.party_id
-- Add 2019.09.03 Ver1.93 Start
              AND flvv.lookup_type(+)  = cv_xxcfr_tax_category
              AND xil.tax_code         = flvv.lookup_code(+)
              AND flvv.enabled_flag(+) = cv_enabled_yes
-- Add 2019.09.03 Ver1.93 End
            GROUP BY cv_pkg_name,
                     xih.inv_creation_date,
                     DECODE(get_14account_rec.bill_postal_code,
                                 NULL,NULL,
                                 lv_format_zip_mark||SUBSTR(get_14account_rec.bill_postal_code,1,3)||'-'||
                                 SUBSTR(get_14account_rec.bill_postal_code,4,4)),
                     get_14account_rec.bill_state||get_14account_rec.bill_city,
                     get_14account_rec.bill_address1,
                     get_14account_rec.bill_address2,
                     get_14account_rec.cash_account_number,
                     get_14account_rec.cash_account_name,
                     xffvv.description,
                     xih.object_month,
                     get_14account_rec.cash_account_number||' '||xih.term_name,
                     xih.payment_date,
                     CASE
                     WHEN account.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(account.bank_number,1,1),
                       lv_format_bank_dummy,NULL,                                       -- �_�~�[��s�̏ꍇ��NULL
                       CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
                         CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
                           account.bank_name
                         ELSE
                           account.bank_name ||lv_format_date_bank
                         END
                       ELSE
                        account.bank_name 
                       END||' '||                                                       -- ��s��
                       CASE WHEN INSTR(account.bank_branch_name
                                      ,lv_format_date_central)>0 THEN
                         account.bank_branch_name
                       ELSE
                         account.bank_branch_name||lv_format_date_branch 
                       END||' '||                                                       -- �x�X��
                       DECODE( account.bank_account_type,
                               1,lv_format_date_account,
                               2,lv_format_date_current,
                               account.bank_account_type) ||' '||                       -- �������
                       account.bank_account_num ||' '||                                 -- �����ԍ�
                       account.account_holder_name||' '||                               -- �������`�l
                       account.account_holder_name_alt)                                 -- �������`�l�J�i��
                     END,
                     xil.ship_cust_code,
                     hzp.party_name,
                     TO_CHAR(DECODE(xil.acceptance_date,
                                    NULL,xil.delivery_date,
                                    xil.acceptance_date),
                     cv_format_date_ymds2),
-- Modify 2013.12.13 Ver1.60 Start
--                     xil.slip_num;
                     xil.slip_num,
-- Modify 2014.03.27 Ver1.70 Start
--                     xil.tax_rate
-- Del 2019.09.03 Ver1.93 Start
--                     xil.tax_rate,
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
                     flvv.attribute1,
                     flvv.attribute2,
-- Add 2019.09.03 Ver1.93 End
                     CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
                       cv_os_flag_y
                     ELSE
                       NULL
                     END
-- Modify 2014.03.27 Ver1.70 End
                     ;
-- Modify 2013.12.13 Ver1.60 End
--
            gn_target_cnt := gn_target_cnt + SQL%ROWCOUNT;
--
          --����������P�� = 'A6'
          ELSIF (all_account_rec.invoice_printing_unit = cv_invoice_printing_unit_a6)
           AND  (get_14account_rec.bill_tax_div IN (cv_syohizei_kbn_inc2,cv_syohizei_kbn_inc3))  -- ����ŋ敪 IN (����(�`�[),����(�P��))
-- Modify 2014.03.27 Ver1.70 Start
--           AND  (get_14account_rec.bill_invoice_type = cv_inv_prt_type) -- �������o�͌`�� = 1.�ɓ����W��
           AND  (get_14account_rec.bill_invoice_type = iv_bill_invoice_type) -- �������o�͌`�� = ���̓p�����[�^�u�������o�͌`���v
-- Modify 2014.03.27 Ver1.70 End
           AND  (get_14account_rec.cons_inv_flag = cv_enabled_yes) -- �ꊇ�������� = 'Y'(�L��)
-- Add 2010.12.10 Ver1.30 Start
           AND  (get_14account_rec.bill_pub_cycle = NVL(iv_bill_pub_cycle, get_14account_rec.bill_pub_cycle)) -- ���������s�T�C�N�� = ���̓p�����[�^�u���������s�T�C�N���v
-- Add 2010.12.10 Ver1.30 End
          THEN
            OPEN get_20account_cur(all_account_rec.customer_id);
            FETCH get_20account_cur INTO get_20account_rec;
            --�ڋq�敪20�̌ڋq�����݂��Ȃ��ꍇ
            IF get_20account_cur%NOTFOUND THEN
              -- �S�Џo�͌�������̏ꍇ�ƁA�Y���ڋq�̐������_�����O�C�����[�U�̏�������ƈ�v����ꍇ
              IF (all_account_rec.bill_base_code = gt_user_dept)
              OR (gv_inv_all_flag = cv_status_yes)
              THEN
                -- �ڋq�敪20���݂Ȃ����b�Z�[�W�o��
                put_account_warning(iv_customer_class_code => cv_customer_class_code20
                                   ,iv_customer_code       => all_account_rec.customer_code
                                   ,ov_errbuf              => lv_errbuf
                                   ,ov_retcode             => lv_retcode
                                   ,ov_errmsg              => lv_errmsg);
                IF (lv_retcode = cv_status_error) THEN
                  --(�G���[����)
                  RAISE global_process_expt;
                END IF;
              END IF;
            ELSIF ((gv_inv_all_flag = cv_status_yes) OR 
                  ((gv_inv_all_flag = cv_status_no) AND  (all_account_rec.bill_base_code = gt_user_dept)))  -- �������_ = ���O�C�����[�U�̋��_
            THEN
              INSERT INTO xxcfr_rep_st_invoice_inc_tax_d(
                report_id               , -- ���[�h�c
                issue_date              , -- ���s��
                zip_code                , -- �X�֔ԍ�
                send_address1           , -- �Z���P
                send_address2           , -- �Z���Q
                send_address3           , -- �Z���R
                bill_cust_code          , -- �ڋq�R�[�h(�\�[�g���Q)
                bill_cust_name          , -- �ڋq��
                location_code           , -- �S�����_�R�[�h
                location_name           , -- �S�����_��
                phone_num               , -- �d�b�ԍ�
                target_date             , -- �Ώ۔N��
                payment_cust_code       , -- ������ڋq�R�[�h
                payment_cust_name       , -- ������ڋq��
                ar_concat_text          , -- ���|�Ǘ��R�[�h�A��������(�e���ڂ̊ԂɃX�y�[�X��}��)
                payment_due_date        , -- �����\���
                bank_account            , -- �U���������
                ship_cust_code          , -- ���[�i��ڋq�R�[�h
                ship_cust_name          , -- ���[�i��ڋq��
-- Add 2011.01.17 Ver1.40 Start
                store_code              , -- �X�܃R�[�h
                store_code_sort         , -- �X�܃R�[�h(�\�[�g�p)
                ship_account_number     , -- �[�i��ڋq�R�[�h(�\�[�g�p)
                invo_account_number     , -- �����p�ڋq�R�[�h(�\�[�g�p)
-- Add 2011.01.17 Ver1.40 End
                slip_date               , -- �`�[���t(�\�[�g���R)
                slip_num                , -- �`�[No(�\�[�g���S)
                slip_sum                , -- �`�[���z(�`�[�ԍ��P�ʂŏW�v�����l)
                slip_tax_sum            , -- �`�[�Ŋz(�`�[�ԍ��P�ʂŏW�v�����l)
-- Del 2019.09.03 Ver1.93 Start
-- Add 2013.12.13 Ver1.60 Start
--                tax_rate                , -- ����ŗ�(�ҏW�p)
-- Add 2013.12.13 Ver1.60 End
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
                description             , -- �E�v
                category                , -- ���󕪗�(�ҏW�p)
-- Add 2019.09.03 Ver1.93 End
-- Add 2014.03.27 Ver1.70 Start
                outsourcing_flag        , -- �Ǝ҈ϑ��t���O
-- Add 2014.03.27 Ver1.70 End
                data_empty_message      , -- 0�����b�Z�[�W
                created_by              , -- �쐬��
                creation_date           , -- �쐬��
                last_updated_by         , -- �ŏI�X�V��
                last_update_date        , -- �ŏI�X�V��
                last_update_login       , -- �ŏI�X�V���O�C��
                request_id              , -- �v��ID
                program_application_id  , -- �A�v���P�[�V����ID
                program_id              , -- �R���J�����g�E�v���O����ID
                program_update_date     ) -- �v���O�����X�V��
              SELECT cv_pkg_name                                                        report_id        , -- ���[�h�c
                     TO_CHAR(xih.inv_creation_date,lv_format_date_jpymd4)               issue_date       , -- ���s��
                     DECODE(get_20account_rec.bill_postal_code,
                            NULL,NULL,
                            lv_format_zip_mark||SUBSTR(get_20account_rec.bill_postal_code,1,3)||'-'||
                            SUBSTR(get_20account_rec.bill_postal_code,4,4))                 zip_code         , -- �X�֔ԍ�
                     get_20account_rec.bill_state||get_20account_rec.bill_city                  send_address1    , -- �Z���P
                     get_20account_rec.bill_address1                                        send_address2    , -- �Z���Q
                     get_20account_rec.bill_address2                                        send_address3    , -- �Z���R
                     get_20account_rec.bill_account_number                                  bill_cust_code   , -- �ڋq�R�[�h(�\�[�g���Q)
                     get_20account_rec.bill_account_name                                    bill_cust_name   , -- �ڋq��
                     all_account_rec.bill_base_code                                         bill_base_code   , -- �S�����_�R�[�h
                     xffvv.description                                                  location_name    , -- �S�����_��
                     xxcfr_common_pkg.get_base_target_tel_num(xil.ship_cust_code)   phone_num        , -- �d�b�ԍ�
                     SUBSTR(xih.object_month,1,4)||lv_format_date_year||
                     SUBSTR(xih.object_month,5,2)||lv_format_date_month                 target_date      , -- �Ώ۔N��
                     get_14account_rec.cash_account_number                              payment_cust_code, -- ������ڋq�R�[�h
                     get_14account_rec.cash_account_name                                payment_cust_name, -- ������ڋq��
                     get_20account_rec.bill_account_number||' '||xih.term_name          ar_concat_text   , -- ���|�Ǘ��R�[�h�A��������
                     TO_CHAR(xih.payment_date, lv_format_date_jpymd2)                   payment_due_date , -- �����\���
                     CASE
                     WHEN account.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(account.bank_number,1,1),
                       lv_format_bank_dummy,NULL,                                       -- �_�~�[��s�̏ꍇ��NULL
                       CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
                         CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
                           account.bank_name
                         ELSE
                           account.bank_name ||lv_format_date_bank
                         END
                       ELSE
                        account.bank_name 
                       END||' '||                                                       -- ��s��
                       CASE WHEN INSTR(account.bank_branch_name
                                      ,lv_format_date_central)>0 THEN
                         account.bank_branch_name
                       ELSE
                         account.bank_branch_name||lv_format_date_branch 
                       END||' '||                                                       -- �x�X��
                       DECODE( account.bank_account_type,
                               1,lv_format_date_account,
                               2,lv_format_date_current,
                               account.bank_account_type) ||' '||                       -- �������
                       account.bank_account_num ||' '||                                 -- �����ԍ�
                       account.account_holder_name||' '||                               -- �������`�l
                       account.account_holder_name_alt)                                 -- �������`�l�J�i��
                     END                                                                account_data     , -- �U���������
                     xil.ship_cust_code                                                 ship_cust_code   , -- �[�i��ڋq�R�[�h
                     hzp.party_name                                                     ship_cust_name   , -- �[�i��ڋq��
-- Add 2011.01.17 Ver1.40 Start
                     LPAD(NVL(all_account_rec.store_code,'0'),10,'0')                   store_code         ,  -- �X�܃R�[�h
                     LPAD(NVL(all_account_rec.store_code,'0'),10,'0')                   store_code_sort    ,  -- �X�܃R�[�h(�\�[�g�p)
                     xil.ship_cust_code                                                 ship_account_number,  -- �[�i��ڋq�R�[�h(�\�[�g�p)
                     NULL                                                               invo_account_number,  -- �����p�ڋq�R�[�h(�\�[�g�p)
-- Add 2011.01.17 Ver1.40 End
                     TO_CHAR(DECODE(xil.acceptance_date,
                                    NULL,xil.delivery_date,
                                    xil.acceptance_date),
                             cv_format_date_ymds2)                                      slip_date        , -- �`�[���t(�\�[�g���R)
                     xil.slip_num                                                       slip_num         , -- �`�[No(�\�[�g���S)
                     SUM(xil.ship_amount)                                               slip_sum         , -- �`�[���z(�Ŕ��z)
                     SUM(xil.tax_amount)                                                tax_sum          , -- �`�[�Ŋz
-- Del 2019.09.03 Ver1.93 Start
-- Add 2013.12.13 Ver1.60 Start
--                     xil.tax_rate                                                       tax_rate         , -- ����ŗ�
-- Add 2013.12.13 Ver1.60 End
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
                     NVL(flvv.attribute1,' ')                                           description      , -- �E�v
                     flvv.attribute2                                                    category         , -- ��������(�ҏW�p)
-- Add 2019.09.03 Ver1.93 End
-- Add 2014.03.27 Ver1.70 Start
                     CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
                       cv_os_flag_y
                     ELSE
                       NULL
                     END                                                                outsourcing_flag , -- �Ǝ҈ϑ��t���O
-- Add 2014.03.27 Ver1.70 End
                     NULL                                                               data_empty_message,-- 0�����b�Z�[�W
                     cn_created_by                                                      created_by,             -- �쐬��
                     cd_creation_date                                                   creation_date,          -- �쐬��
                     cn_last_updated_by                                                 last_updated_by,        -- �ŏI�X�V��
                     cd_last_update_date                                                last_update_date,       -- �ŏI�X�V��
                     cn_last_update_login                                               last_update_login,      -- �ŏI�X�V���O�C��
                     cn_request_id                                                      request_id,             -- �v��ID
                     cn_program_application_id                                          program_application_id, -- �A�v���P�[�V����ID
                     cn_program_id                                                      program_id,
                                                                                        -- �R���J�����g�E�v���O����ID
                     cd_program_update_date                                             program_update_date     -- �v���O�����X�V��
              FROM xxcfr_invoice_headers          xih  , -- �����w�b�_
                   xxcfr_invoice_lines            xil  , -- ��������
                   hz_cust_accounts               hzca , -- �ڋq10�ڋq�}�X�^
                   hz_parties                     hzp  , -- �ڋq10�p�[�e�B�}�X�^
                   (SELECT all_account_rec.customer_code ship_cust_code,
                           rcrm.customer_id             customer_id,
                           abb.bank_number              bank_number,
                           abb.bank_name                bank_name,
                           abb.bank_branch_name         bank_branch_name,
                           abaa.bank_account_type       bank_account_type,
                           abaa.bank_account_num        bank_account_num,
                           abaa.account_holder_name     account_holder_name,
                           abaa.account_holder_name_alt account_holder_name_alt
                    FROM ra_cust_receipt_methods        rcrm , --�x�����@���
                         ar_receipt_method_accounts_all arma , --AR�x�����@����
                         ap_bank_accounts_all           abaa , --��s����
                         ap_bank_branches               abb    --��s�x�X
                    WHERE rcrm.primary_flag = cv_enabled_yes
                      AND get_14account_rec.cash_account_id = rcrm.customer_id
                      AND gd_target_date BETWEEN rcrm.start_date AND NVL(rcrm.end_date ,cd_max_date)
                      AND rcrm.site_use_id IS NOT NULL
                      AND rcrm.receipt_method_id = arma.receipt_method_id(+)
                      AND arma.bank_account_id = abaa.bank_account_id(+)
                      AND abaa.bank_branch_id = abb.bank_branch_id(+)
                      AND arma.org_id = gn_org_id
                      AND abaa.org_id = gn_org_id             ) account,    -- ��s�����r���[
                   (SELECT flex_value,
                           description
                    FROM   fnd_flex_values_vl ffv
                    WHERE  EXISTS
                           (SELECT  'X'
                            FROM    fnd_flex_value_sets
                            WHERE   flex_value_set_name = cv_ffv_set_name_dept
                            AND     flex_value_set_id   = ffv.flex_value_set_id)) xffvv
-- Add 2019.09.03 Ver1.93 Start
                  ,fnd_lookup_values_vl           flvv    -- �Q�ƕ\
-- Add 2019.09.03 Ver1.93 End
              WHERE xih.invoice_id = xil.invoice_id                        -- �ꊇ������ID
                AND xil.cutoff_date = gd_target_date                       -- �p�����[�^�D����
                AND xil.ship_cust_code = account.ship_cust_code(+)         -- �O�������̂��߂̃_�~�[����
                AND xih.set_of_books_id = gn_set_of_bks_id
                AND xih.org_id = gn_org_id
                AND all_account_rec.bill_base_code = xffvv.flex_value
                AND xil.ship_cust_code = all_account_rec.customer_code
                AND hzca.cust_account_id = all_account_rec.customer_id
                AND hzp.party_id = hzca.party_id
-- Add 2019.09.03 Ver1.93 Start
                AND flvv.lookup_type(+)  = cv_xxcfr_tax_category
                AND xil.tax_code         = flvv.lookup_code(+)
                AND flvv.enabled_flag(+) = cv_enabled_yes
-- Add 2019.09.03 Ver1.93 End
              GROUP BY cv_pkg_name,
                       xih.inv_creation_date,
                       DECODE(get_20account_rec.bill_postal_code,
                                   NULL,NULL,
                                   lv_format_zip_mark||SUBSTR(get_20account_rec.bill_postal_code,1,3)||'-'||
                                   SUBSTR(get_20account_rec.bill_postal_code,4,4)),
                       get_20account_rec.bill_state||get_20account_rec.bill_city,
                       get_20account_rec.bill_address1,
                       get_20account_rec.bill_address2,
                       get_20account_rec.bill_account_number,
                       get_20account_rec.bill_account_name,
                       xffvv.description,
                       xih.object_month,
                       get_14account_rec.cash_account_number,
                       get_14account_rec.cash_account_name,
                       get_20account_rec.bill_account_number||' '||xih.term_name,
                       xih.payment_date,
                       CASE
                       WHEN account.bank_account_num IS NULL THEN
                         NULL
                       ELSE
                         DECODE(SUBSTR(account.bank_number,1,1),
                         lv_format_bank_dummy,NULL,                                       -- �_�~�[��s�̏ꍇ��NULL
                         CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
                           CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
                             account.bank_name
                           ELSE
                             account.bank_name ||lv_format_date_bank
                           END
                         ELSE
                          account.bank_name 
                         END||' '||                                                       -- ��s��
                         CASE WHEN INSTR(account.bank_branch_name
                                        ,lv_format_date_central)>0 THEN
                           account.bank_branch_name
                         ELSE
                           account.bank_branch_name||lv_format_date_branch 
                         END||' '||                                                       -- �x�X��
                         DECODE( account.bank_account_type,
                                 1,lv_format_date_account,
                                 2,lv_format_date_current,
                                 account.bank_account_type) ||' '||                       -- �������
                         account.bank_account_num ||' '||                                 -- �����ԍ�
                         account.account_holder_name||' '||                               -- �������`�l
                         account.account_holder_name_alt)                                 -- �������`�l�J�i��
                       END,
                       xil.ship_cust_code,
                       hzp.party_name,
                       TO_CHAR(DECODE(xil.acceptance_date,
                                      NULL,xil.delivery_date,
                                      xil.acceptance_date),
                       cv_format_date_ymds2),
-- Modify 2013.12.13 Ver1.60 Start
--                       xil.slip_num;
                       xil.slip_num,
-- Modify 2014.03.27 Ver1.70 Start
--                       xil.tax_rate
-- Del 2019.09.03 Ver1.93 Start
--                       xil.tax_rate,
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
                       flvv.attribute1,
                       flvv.attribute2,
-- Add 2019.09.03 Ver1.93 End
                       CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
                         cv_os_flag_y
                       ELSE
                         NULL
                       END
-- Modify 2014.03.27 Ver1.70 End
                       ;
-- Modify 2013.12.13 Ver1.60 End
--
              gn_target_cnt := gn_target_cnt + SQL%ROWCOUNT;
--
            ELSE
              NULL;
            END IF;
--
            CLOSE get_20account_cur;
--
-- Add 2015.07.31 Ver1.80 Start
          --����������P�� = 'A7'
          ELSIF (all_account_rec.invoice_printing_unit = cv_invoice_printing_unit_a7)
           AND  ((gv_inv_all_flag = cv_status_yes) OR 
                 ((gv_inv_all_flag = cv_status_no) AND  (get_14account_rec.bill_base_code = gt_user_dept)))   -- �������_ = ���O�C�����[�U�̋��_
           AND  (get_14account_rec.bill_tax_div IN (cv_syohizei_kbn_inc2,cv_syohizei_kbn_inc3))               -- ����ŋ敪 IN (����(�`�[),����(�P��))
           AND  (get_14account_rec.bill_invoice_type = iv_bill_invoice_type)                                  -- �������o�͌`�� = ���̓p�����[�^�u�������o�͌`���v
           AND  (get_14account_rec.cons_inv_flag = cv_enabled_yes)                                             -- �ꊇ�������� = 'Y'(�L��)
           AND  (get_14account_rec.bill_pub_cycle = NVL(iv_bill_pub_cycle, get_14account_rec.bill_pub_cycle)) -- ���������s�T�C�N�� = ���̓p�����[�^�u���������s�T�C�N���v
          THEN
            BEGIN
            -- ����P�ʁFA�̌ڋq����
            gv_target_a_flag := cv_taget_flag_1;
--
            INSERT INTO xxcfr_rep_st_inv_inc_tax_a_l(
              report_id               , -- ���[�h�c
              issue_date              , -- ���s���t
              zip_code                , -- �X�֔ԍ�
              send_address1           , -- �Z���P
              send_address2           , -- �Z���Q
              send_address3           , -- �Z���R
              bill_cust_code          , -- �ڋq�R�[�h(�\�[�g���Q)
              bill_cust_name          , -- �ڋq��
              location_code           , -- �S�����_�R�[�h
              location_name           , -- �S�����_��
              phone_num               , -- �d�b�ԍ�
              target_date             , -- �Ώ۔N��
              payment_cust_code       , -- ���|�Ǘ��R�[�h
              payment_cust_name       , -- ���|�Ǘ��ڋq��
              ar_concat_text          , -- ���|�Ǘ��R�[�h�A��������(�e���ڂ̊ԂɃX�y�[�X��}��)
              payment_due_date        , -- �����\���
              bank_account            , -- �U���������
              ship_cust_code          , -- �[�i��ڋq�R�[�h
              ship_cust_name          , -- �[�i��ڋq��
              store_code              , -- �X�܃R�[�h
              store_code_sort         , -- �X�܃R�[�h(�\�[�g�p)
              ship_account_number     , -- �[�i��ڋq�R�[�h(�\�[�g�p)
              slip_date               , -- �`�[���t(�\�[�g���R)
              slip_num                , -- �`�[No(�\�[�g���S)
              slip_sum                , -- �`�[���z(�`�[�ԍ��P�ʂŏW�v�����l)
              slip_tax_sum            , -- �`�[�Ŋz(�`�[�ԍ��P�ʂŏW�v�����l)
-- Del 2019.09.03 Ver1.93 Start
--              tax_rate                , -- ����ŗ�(�ҏW�p)
-- Del 2019.09.03 Ver1.93 Start
-- Add 2019.09.03 Ver1.93 Start
              description             , -- �E�v
              category                , -- ���󕪗�(�ҏW�p)
-- Add 2019.09.03 Ver1.93 End
              outsourcing_flag        , -- �Ǝ҈ϑ��t���O
              created_by              , -- �쐬��
              creation_date           , -- �쐬��
              last_updated_by         , -- �ŏI�X�V��
              last_update_date        , -- �ŏI�X�V��
              last_update_login       , -- �ŏI�X�V���O�C��
              request_id              , -- �v��ID
              program_application_id  , -- �A�v���P�[�V����ID
              program_id              , -- �R���J�����g�E�v���O����ID
              program_update_date     ) -- �v���O�����X�V��
            SELECT cv_report_id_02                                                        report_id             , -- ���[�h�c
                   TO_CHAR(xih.inv_creation_date,lv_format_date_jpymd4)                   issue_date            , -- ���s��
                   DECODE(get_14account_rec.bill_postal_code,
                          NULL,NULL,
                          lv_format_zip_mark||SUBSTR(get_14account_rec.bill_postal_code,1,3)||'-'||
                          SUBSTR(get_14account_rec.bill_postal_code,4,4))                 zip_code              , -- �X�֔ԍ�
                   get_14account_rec.bill_state||get_14account_rec.bill_city              send_address1         , -- �Z���P
                   get_14account_rec.bill_address1                                        send_address2         , -- �Z���Q
                   get_14account_rec.bill_address2                                        send_address3         , -- �Z���R
                   get_14account_rec.cash_account_number                                  bill_cust_code        , -- �ڋq�R�[�h(�\�[�g���Q)
                   get_14account_rec.cash_account_name                                    bill_cust_name        , -- �ڋq��
                   get_14account_rec.bill_base_code                                       bill_base_code        , -- �S�����_�R�[�h
                   xffvv.description                                                      location_name         , -- �S�����_��
                   xxcfr_common_pkg.get_base_target_tel_num(get_14account_rec.cash_account_number)  phone_num   , -- �d�b�ԍ�
                   SUBSTR(xih.object_month,1,4)||lv_format_date_year||
                   SUBSTR(xih.object_month,5,2)||lv_format_date_month                     target_date           , -- �Ώ۔N��
                   get_14account_rec.cash_account_number                                  payment_cust_code     , -- ������ڋq�R�[�h
                   get_14account_rec.cash_account_name                                    payment_cust_name     , -- ������ڋq��
                   get_14account_rec.cash_account_number||' '||xih.term_name              ar_concat_text        , -- ���|�Ǘ��R�[�h�A��������
                   TO_CHAR(xih.payment_date, lv_format_date_jpymd2)                       payment_due_date      , -- �����\���
                   CASE
                   WHEN account.bank_account_num IS NULL THEN
                     NULL
                   ELSE
                     DECODE(SUBSTR(account.bank_number,1,1),
                     lv_format_bank_dummy,NULL,                                       -- �_�~�[��s�̏ꍇ��NULL
                     CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
                       CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
                         account.bank_name
                       ELSE
                         account.bank_name ||lv_format_date_bank
                       END
                     ELSE
                      account.bank_name 
                     END||' '||                                                       -- ��s��
                     CASE WHEN INSTR(account.bank_branch_name
                                    ,lv_format_date_central)>0 THEN
                       account.bank_branch_name
                     ELSE
                       account.bank_branch_name||lv_format_date_branch 
                     END||' '||                                                       -- �x�X��
                     DECODE( account.bank_account_type,
                             1,lv_format_date_account,
                             2,lv_format_date_current,
                             account.bank_account_type) ||' '||                       -- �������
                     account.bank_account_num ||' '||                                 -- �����ԍ�
                     account.account_holder_name||' '||                               -- �������`�l
                     account.account_holder_name_alt)                                 -- �������`�l�J�i��
                   END                                                                    account_data          , -- �U���������
                   xil.ship_cust_code                                                     ship_cust_code        , -- �[�i��ڋq�R�[�h
                   hzp.party_name                                                         ship_cust_name        , -- �[�i��ڋq��
                   LPAD(NVL(all_account_rec.store_code,'0'),10,'0')                       store_code            , -- �X�܃R�[�h
                   LPAD(NVL(all_account_rec.store_code,'0'),10,'0')                       store_code_sort       , -- �X�܃R�[�h(�\�[�g�p)
                   xil.ship_cust_code                                                     ship_account_number   , -- �[�i��ڋq�R�[�h(�\�[�g�p)
                   TO_CHAR(DECODE(xil.acceptance_date,
                                  NULL,xil.delivery_date,
                                  xil.acceptance_date),
                           cv_format_date_ymds2)                                          slip_date             , -- �`�[���t(�\�[�g���R)
                   xil.slip_num                                                           slip_num              , -- �`�[No(�\�[�g���S)
                   SUM(xil.ship_amount)                                                   slip_sum              , -- �`�[���z(�Ŕ��z)
                   SUM(xil.tax_amount)                                                    tax_sum               , -- �`�[�Ŋz
-- Del 2019.09.03 Ver1.93 Start
--                   xil.tax_rate                                                           tax_rate              , -- ����ŗ�
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
                   NVL(flvv.attribute1,' ')                                               description      , -- �E�v
                   flvv.attribute2                                                        category         , -- ��������(�ҏW�p)
-- Add 2019.09.03 Ver1.93 End
                   CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
                     cv_os_flag_y
                   ELSE
                     NULL
                   END                                                                    outsourcing_flag      , -- �Ǝ҈ϑ��t���O
                   cn_created_by                                                          created_by            , -- �쐬��
                   cd_creation_date                                                       creation_date         , -- �쐬��
                   cn_last_updated_by                                                     last_updated_by       , -- �ŏI�X�V��
                   cd_last_update_date                                                    last_update_date      , -- �ŏI�X�V��
                   cn_last_update_login                                                   last_update_login     , -- �ŏI�X�V���O�C��
                   cn_request_id                                                          request_id            , -- �v��ID
                   cn_program_application_id                                              program_application_id, -- �A�v���P�[�V����ID
                   cn_program_id                                                          program_id            , -- �R���J�����g�E�v���O����ID
                   cd_program_update_date                                                 program_update_date     -- �v���O�����X�V��
            FROM xxcfr_invoice_headers          xih  , -- �����w�b�_
                 xxcfr_invoice_lines            xil  , -- ��������
                 hz_cust_accounts               hzca , -- �ڋq10�ڋq�}�X�^
                 hz_parties                     hzp  , -- �ڋq10�p�[�e�B�}�X�^
                 (SELECT all_account_rec.customer_code ship_cust_code,
                         rcrm.customer_id             customer_id,
                         abb.bank_number              bank_number,
                         abb.bank_name                bank_name,
                         abb.bank_branch_name         bank_branch_name,
                         abaa.bank_account_type       bank_account_type,
                         abaa.bank_account_num        bank_account_num,
                         abaa.account_holder_name     account_holder_name,
                         abaa.account_holder_name_alt account_holder_name_alt
                  FROM ra_cust_receipt_methods        rcrm , --�x�����@���
                       ar_receipt_method_accounts_all arma , --AR�x�����@����
                       ap_bank_accounts_all           abaa , --��s����
                       ap_bank_branches               abb    --��s�x�X
                  WHERE rcrm.primary_flag = cv_enabled_yes
                    AND get_14account_rec.cash_account_id = rcrm.customer_id
                    AND gd_target_date BETWEEN rcrm.start_date AND NVL(rcrm.end_date ,cd_max_date)
                    AND rcrm.site_use_id IS NOT NULL
                    AND rcrm.receipt_method_id = arma.receipt_method_id(+)
                    AND arma.bank_account_id = abaa.bank_account_id(+)
                    AND abaa.bank_branch_id = abb.bank_branch_id(+)
                    AND arma.org_id = gn_org_id
                    AND abaa.org_id = gn_org_id             ) account,    -- ��s�����r���[
                 (SELECT ffv.flex_value   flex_value,
                         ffv.description  description
                  FROM   fnd_flex_values_vl ffv
                  WHERE  EXISTS
                         (SELECT  'X'
                          FROM    fnd_flex_value_sets ffvs
                          WHERE   ffvs.flex_value_set_name = cv_ffv_set_name_dept
                          AND     ffvs.flex_value_set_id   = ffv.flex_value_set_id)) xffvv
-- Add 2019.09.03 Ver1.93 Start
                ,fnd_lookup_values_vl           flvv    -- �Q�ƕ\
-- Add 2019.09.03 Ver1.93 End
            WHERE xih.invoice_id = xil.invoice_id                                       -- �ꊇ������ID
              AND xil.cutoff_date = gd_target_date                                      -- �p�����[�^�D����
              AND xil.ship_cust_code = account.ship_cust_code(+)                        -- �O�������̂��߂̃_�~�[����
              AND xih.set_of_books_id = gn_set_of_bks_id
              AND xih.org_id = gn_org_id
              AND get_14account_rec.bill_base_code = xffvv.flex_value
              AND xil.ship_cust_code = all_account_rec.customer_code
              AND hzca.cust_account_id = all_account_rec.customer_id
              AND hzp.party_id = hzca.party_id
-- Add 2019.09.03 Ver1.93 Start
              AND flvv.lookup_type(+)  = cv_xxcfr_tax_category
              AND xil.tax_code         = flvv.lookup_code(+)
              AND flvv.enabled_flag(+) = cv_enabled_yes
-- Add 2019.09.03 Ver1.93 End
            GROUP BY cv_pkg_name,
                     xih.inv_creation_date,
                     DECODE(get_14account_rec.bill_postal_code,
                                 NULL,NULL,
                                 lv_format_zip_mark||SUBSTR(get_14account_rec.bill_postal_code,1,3)||'-'||
                                 SUBSTR(get_14account_rec.bill_postal_code,4,4)),
                     get_14account_rec.bill_state||get_14account_rec.bill_city,
                     get_14account_rec.bill_address1,
                     get_14account_rec.bill_address2,
                     get_14account_rec.cash_account_number,
                     get_14account_rec.cash_account_name,
                     xffvv.description,
                     xih.object_month,
                     get_14account_rec.cash_account_number||' '||xih.term_name,
                     xih.payment_date,
                     CASE
                     WHEN account.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(account.bank_number,1,1),
                       lv_format_bank_dummy,NULL,                                       -- �_�~�[��s�̏ꍇ��NULL
                       CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
                         CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
                           account.bank_name
                         ELSE
                           account.bank_name ||lv_format_date_bank
                         END
                       ELSE
                        account.bank_name 
                       END||' '||                                                       -- ��s��
                       CASE WHEN INSTR(account.bank_branch_name
                                      ,lv_format_date_central)>0 THEN
                         account.bank_branch_name
                       ELSE
                         account.bank_branch_name||lv_format_date_branch 
                       END||' '||                                                       -- �x�X��
                       DECODE( account.bank_account_type,
                               1,lv_format_date_account,
                               2,lv_format_date_current,
                               account.bank_account_type) ||' '||                       -- �������
                       account.bank_account_num ||' '||                                 -- �����ԍ�
                       account.account_holder_name||' '||                               -- �������`�l
                       account.account_holder_name_alt)                                 -- �������`�l�J�i��
                     END,
                     xil.ship_cust_code,
                     hzp.party_name,
                     TO_CHAR(DECODE(xil.acceptance_date,
                                    NULL,xil.delivery_date,
                                    xil.acceptance_date),
                     cv_format_date_ymds2),
                     xil.slip_num,
-- Del 2019.09.03 Ver1.93 Start
--                     xil.tax_rate,
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
                     flvv.attribute1,
                     flvv.attribute2,
-- Add 2019.09.03 Ver1.93 End
                     CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
                       cv_os_flag_y
                     ELSE
                       NULL
                     END
                     ;
--
            EXCEPTION
              WHEN OTHERS THEN  -- �o�^���G���[
                lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                               ,cv_msg_003a18_013    -- �e�[�u���o�^�G���[
                                                               ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                               ,xxcfr_common_pkg.get_table_comment(cv_table_a_l))
                                                              -- �W���������ō����[�������P��A���[�N�e�[�u������
                                     ,1
                                     ,5000);
                lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
                RAISE global_api_expt;
            END;
--
            gn_target_cnt_a_l := gn_target_cnt_a_l + SQL%ROWCOUNT;
--
          --����������P�� = 'A8'
          ELSIF (all_account_rec.invoice_printing_unit = cv_invoice_printing_unit_a8)
           AND  ((gv_inv_all_flag = cv_status_yes) OR 
                 ((gv_inv_all_flag = cv_status_no) AND  (get_14account_rec.bill_base_code = gt_user_dept)))   -- �������_ = ���O�C�����[�U�̋��_
           AND  (get_14account_rec.bill_tax_div IN (cv_syohizei_kbn_inc2,cv_syohizei_kbn_inc3))               -- ����ŋ敪 IN (����(�`�[),����(�P��))
           AND  (get_14account_rec.bill_invoice_type = iv_bill_invoice_type)                                  -- �������o�͌`�� = ���̓p�����[�^�u�������o�͌`���v
           AND  (get_14account_rec.cons_inv_flag = cv_enabled_yes)                                            -- �ꊇ�������� = 'Y'(�L��)
           AND  (get_14account_rec.bill_pub_cycle = NVL(iv_bill_pub_cycle, get_14account_rec.bill_pub_cycle)) -- ���������s�T�C�N�� = ���̓p�����[�^�u���������s�T�C�N���v
          THEN
            BEGIN
            -- ����P�ʁFB�̌ڋq����
            gv_target_b_flag := cv_taget_flag_1;
--
            INSERT INTO xxcfr_rep_st_inv_inc_tax_b_l(
              report_id               , -- ���[�h�c
              issue_date              , -- ���s���t
              zip_code                , -- �X�֔ԍ�
              send_address1           , -- �Z���P
              send_address2           , -- �Z���Q
              send_address3           , -- �Z���R
              bill_cust_code          , -- �ڋq�R�[�h(�\�[�g���Q)
              bill_cust_name          , -- �ڋq��
              location_code           , -- �S�����_�R�[�h
              location_name           , -- �S�����_��
              phone_num               , -- �d�b�ԍ�
              target_date             , -- �Ώ۔N��
              payment_cust_code       , -- ���|�Ǘ��ڋq�R�[�h
              payment_cust_name       , -- ���|�Ǘ��ڋq��
              ar_concat_text          , -- ���|�Ǘ��R�[�h�A��������(�e���ڂ̊ԂɃX�y�[�X��}��)
              payment_due_date        , -- �����\���
              bank_account            , -- �U���������
              ship_cust_code          , -- �[�i��ڋq�R�[�h
              ship_cust_name          , -- �[�i��ڋq��
              store_code              , -- �X�܃R�[�h
              store_code_sort         , -- �X�܃R�[�h(�\�[�g�p)
              ship_account_number     , -- �[�i��ڋq�R�[�h(�\�[�g�p)
              slip_date               , -- �`�[���t(�\�[�g���R)
              slip_num                , -- �`�[No(�\�[�g���S)
              slip_sum                , -- �`�[���z(�`�[�ԍ��P�ʂŏW�v�����l)
              slip_tax_sum            , -- �`�[�Ŋz(�`�[�ԍ��P�ʂŏW�v�����l)
-- Del 2019.09.03 Ver1.93 Start
--              tax_rate                , -- ����ŗ�(�ҏW�p)
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
              description             , -- �E�v
              category                , -- ���󕪗�(�ҏW�p)
-- Add 2019.09.03 Ver1.93 End
              outsourcing_flag        , -- �Ǝ҈ϑ��t���O
              created_by              , -- �쐬��
              creation_date           , -- �쐬��
              last_updated_by         , -- �ŏI�X�V��
              last_update_date        , -- �ŏI�X�V��
              last_update_login       , -- �ŏI�X�V���O�C��
              request_id              , -- �v��ID
              program_application_id  , -- �A�v���P�[�V����ID
              program_id              , -- �R���J�����g�E�v���O����ID
              program_update_date     ) -- �v���O�����X�V��
            SELECT cv_report_id_04                                                        report_id             , -- ���[�h�c
                   TO_CHAR(xih.inv_creation_date,lv_format_date_jpymd4)                   issue_date            , -- ���s��
                   DECODE(get_14account_rec.bill_postal_code,
                          NULL,NULL,
                          lv_format_zip_mark||SUBSTR(get_14account_rec.bill_postal_code,1,3)||'-'||
                          SUBSTR(get_14account_rec.bill_postal_code,4,4))                 zip_code              , -- �X�֔ԍ�
                   get_14account_rec.bill_state||get_14account_rec.bill_city              send_address1         , -- �Z���P
                   get_14account_rec.bill_address1                                        send_address2         , -- �Z���Q
                   get_14account_rec.bill_address2                                        send_address3         , -- �Z���R
                   get_14account_rec.cash_account_number                                  bill_cust_code        , -- �ڋq�R�[�h(�\�[�g���Q)
                   get_14account_rec.cash_account_name                                    bill_cust_name        , -- �ڋq��
                   get_14account_rec.bill_base_code                                       bill_base_code        , -- �S�����_�R�[�h
                   xffvv.description                                                      location_name         , -- �S�����_��
                   xxcfr_common_pkg.get_base_target_tel_num(get_14account_rec.cash_account_number)  phone_num   , -- �d�b�ԍ�
                   SUBSTR(xih.object_month,1,4)||lv_format_date_year||
                   SUBSTR(xih.object_month,5,2)||lv_format_date_month                     target_date           , -- �Ώ۔N��
                   get_14account_rec.cash_account_number                                  payment_cust_code     , -- ������ڋq�R�[�h
                   get_14account_rec.cash_account_name                                    payment_cust_name     , -- ������ڋq��
                   get_14account_rec.cash_account_number||' '||xih.term_name              ar_concat_text        , -- ���|�Ǘ��R�[�h�A��������
                   TO_CHAR(xih.payment_date, lv_format_date_jpymd2)                       payment_due_date      , -- �����\���
                   CASE
                   WHEN account.bank_account_num IS NULL THEN
                     NULL
                   ELSE
                     DECODE(SUBSTR(account.bank_number,1,1),
                     lv_format_bank_dummy,NULL,                                       -- �_�~�[��s�̏ꍇ��NULL
                     CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
                       CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
                         account.bank_name
                       ELSE
                         account.bank_name ||lv_format_date_bank
                       END
                     ELSE
                      account.bank_name 
                     END||' '||                                                       -- ��s��
                     CASE WHEN INSTR(account.bank_branch_name
                                    ,lv_format_date_central)>0 THEN
                       account.bank_branch_name
                     ELSE
                       account.bank_branch_name||lv_format_date_branch 
                     END||' '||                                                       -- �x�X��
                     DECODE( account.bank_account_type,
                             1,lv_format_date_account,
                             2,lv_format_date_current,
                             account.bank_account_type) ||' '||                       -- �������
                     account.bank_account_num ||' '||                                 -- �����ԍ�
                     account.account_holder_name||' '||                               -- �������`�l
                     account.account_holder_name_alt)                                 -- �������`�l�J�i��
                   END                                                                    account_data          , -- �U���������
                   xil.ship_cust_code                                                     ship_cust_code        , -- �[�i��ڋq�R�[�h
                   hzp.party_name                                                         ship_cust_name        , -- �[�i��ڋq��
                   LPAD(NVL(all_account_rec.store_code,'0'),10,'0')                       store_code            , -- �X�܃R�[�h
                   LPAD(NVL(all_account_rec.store_code,'0'),10,'0')                       store_code_sort       , -- �X�܃R�[�h(�\�[�g�p)
                   xil.ship_cust_code                                                     ship_account_number   , -- �[�i��ڋq�R�[�h(�\�[�g�p)
                   TO_CHAR(DECODE(xil.acceptance_date,
                                  NULL,xil.delivery_date,
                                  xil.acceptance_date),
                           cv_format_date_ymds2)                                          slip_date             , -- �`�[���t(�\�[�g���R)
                   xil.slip_num                                                           slip_num              , -- �`�[No(�\�[�g���S)
                   SUM(xil.ship_amount)                                                   slip_sum              , -- �`�[���z(�Ŕ��z)
                   SUM(xil.tax_amount)                                                    tax_sum               , -- �`�[�Ŋz
-- Del 2019.09.03 Ver1.93 Start
--                   xil.tax_rate                                                           tax_rate              , -- ����ŗ�
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
                   NVL(flvv.attribute1,' ')                                              description           , -- �E�v
                   flvv.attribute2                                                        category              , -- ��������(�ҏW�p)
-- Add 2019.09.03 Ver1.93 End
                   CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
                     cv_os_flag_y
                   ELSE
                     NULL
                   END                                                                    outsourcing_flag      , -- �Ǝ҈ϑ��t���O
                   cn_created_by                                                          created_by            , -- �쐬��
                   cd_creation_date                                                       creation_date         , -- �쐬��
                   cn_last_updated_by                                                     last_updated_by       , -- �ŏI�X�V��
                   cd_last_update_date                                                    last_update_date      , -- �ŏI�X�V��
                   cn_last_update_login                                                   last_update_login     , -- �ŏI�X�V���O�C��
                   cn_request_id                                                          request_id            , -- �v��ID
                   cn_program_application_id                                              program_application_id, -- �A�v���P�[�V����ID
                   cn_program_id                                                          program_id            , -- �R���J�����g�E�v���O����ID
                   cd_program_update_date                                                 program_update_date     -- �v���O�����X�V��
            FROM xxcfr_invoice_headers          xih  , -- �����w�b�_
                 xxcfr_invoice_lines            xil  , -- ��������
                 hz_cust_accounts               hzca , -- �ڋq10�ڋq�}�X�^
                 hz_parties                     hzp  , -- �ڋq10�p�[�e�B�}�X�^
                 (SELECT all_account_rec.customer_code ship_cust_code,
                         rcrm.customer_id             customer_id,
                         abb.bank_number              bank_number,
                         abb.bank_name                bank_name,
                         abb.bank_branch_name         bank_branch_name,
                         abaa.bank_account_type       bank_account_type,
                         abaa.bank_account_num        bank_account_num,
                         abaa.account_holder_name     account_holder_name,
                         abaa.account_holder_name_alt account_holder_name_alt
                  FROM ra_cust_receipt_methods        rcrm , --�x�����@���
                       ar_receipt_method_accounts_all arma , --AR�x�����@����
                       ap_bank_accounts_all           abaa , --��s����
                       ap_bank_branches               abb    --��s�x�X
                  WHERE rcrm.primary_flag = cv_enabled_yes
                    AND get_14account_rec.cash_account_id = rcrm.customer_id
                    AND gd_target_date BETWEEN rcrm.start_date AND NVL(rcrm.end_date ,cd_max_date)
                    AND rcrm.site_use_id IS NOT NULL
                    AND rcrm.receipt_method_id = arma.receipt_method_id(+)
                    AND arma.bank_account_id = abaa.bank_account_id(+)
                    AND abaa.bank_branch_id = abb.bank_branch_id(+)
                    AND arma.org_id = gn_org_id
                    AND abaa.org_id = gn_org_id             ) account,    -- ��s�����r���[
                 (SELECT ffv.flex_value   flex_value,
                         ffv.description  description
                  FROM   fnd_flex_values_vl ffv
                  WHERE  EXISTS
                         (SELECT  'X'
                          FROM    fnd_flex_value_sets ffvs
                          WHERE   ffvs.flex_value_set_name = cv_ffv_set_name_dept
                          AND     ffvs.flex_value_set_id   = ffv.flex_value_set_id)) xffvv
-- Add 2019.09.03 Ver1.93 Start
                ,fnd_lookup_values_vl           flvv    -- �Q�ƕ\
-- Add 2019.09.03 Ver1.93 End
            WHERE xih.invoice_id = xil.invoice_id                                       -- �ꊇ������ID
              AND xil.cutoff_date = gd_target_date                                      -- �p�����[�^�D����
              AND xil.ship_cust_code = account.ship_cust_code(+)                        -- �O�������̂��߂̃_�~�[����
              AND xih.set_of_books_id = gn_set_of_bks_id
              AND xih.org_id = gn_org_id
              AND get_14account_rec.bill_base_code = xffvv.flex_value
              AND xil.ship_cust_code = all_account_rec.customer_code
              AND hzca.cust_account_id = all_account_rec.customer_id
              AND hzp.party_id = hzca.party_id
-- Add 2019.09.03 Ver1.93 Start
              AND flvv.lookup_type(+)  = cv_xxcfr_tax_category
              AND xil.tax_code         = flvv.lookup_code(+)
              AND flvv.enabled_flag(+) = cv_enabled_yes
-- Add 2019.09.03 Ver1.93 End
            GROUP BY cv_pkg_name,
                     xih.inv_creation_date,
                     DECODE(get_14account_rec.bill_postal_code,
                                 NULL,NULL,
                                 lv_format_zip_mark||SUBSTR(get_14account_rec.bill_postal_code,1,3)||'-'||
                                 SUBSTR(get_14account_rec.bill_postal_code,4,4)),
                     get_14account_rec.bill_state||get_14account_rec.bill_city,
                     get_14account_rec.bill_address1,
                     get_14account_rec.bill_address2,
                     get_14account_rec.cash_account_number,
                     get_14account_rec.cash_account_name,
                     xffvv.description,
                     xih.object_month,
                     get_14account_rec.cash_account_number||' '||xih.term_name,
                     xih.payment_date,
                     CASE
                     WHEN account.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(account.bank_number,1,1),
                       lv_format_bank_dummy,NULL,                                       -- �_�~�[��s�̏ꍇ��NULL
                       CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
                         CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
                           account.bank_name
                         ELSE
                           account.bank_name ||lv_format_date_bank
                         END
                       ELSE
                        account.bank_name 
                       END||' '||                                                       -- ��s��
                       CASE WHEN INSTR(account.bank_branch_name
                                      ,lv_format_date_central)>0 THEN
                         account.bank_branch_name
                       ELSE
                         account.bank_branch_name||lv_format_date_branch 
                       END||' '||                                                       -- �x�X��
                       DECODE( account.bank_account_type,
                               1,lv_format_date_account,
                               2,lv_format_date_current,
                               account.bank_account_type) ||' '||                       -- �������
                       account.bank_account_num ||' '||                                 -- �����ԍ�
                       account.account_holder_name||' '||                               -- �������`�l
                       account.account_holder_name_alt)                                 -- �������`�l�J�i��
                     END,
                     xil.ship_cust_code,
                     hzp.party_name,
                     TO_CHAR(DECODE(xil.acceptance_date,
                                    NULL,xil.delivery_date,
                                    xil.acceptance_date),
                     cv_format_date_ymds2),
                     xil.slip_num,
-- Del 2019.09.03 Ver1.93 Start
--                     xil.tax_rate,
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
                     flvv.attribute1,
                     flvv.attribute2,
-- Add 2019.09.03 Ver1.93 End
                     CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
                       cv_os_flag_y
                     ELSE
                       NULL
                     END
                     ;
--
            EXCEPTION
              WHEN OTHERS THEN  -- �o�^���G���[
                lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                               ,cv_msg_003a18_013    -- �e�[�u���o�^�G���[
                                                               ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                               ,xxcfr_common_pkg.get_table_comment(cv_table_b_l))
                                                              -- �W���������ō����[�������P��B���[�N�e�[�u������
                                     ,1
                                     ,5000);
                lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
                RAISE global_api_expt;
            END;
--
            gn_target_cnt_b_l := gn_target_cnt_b_l + SQL%ROWCOUNT;
--
-- Add 2015.07.31 Ver1.80 End
-- Add 2016.03.31 Ver1.90 Start
          --����������P�� = 'A9'
          ELSIF (all_account_rec.invoice_printing_unit = cv_invoice_printing_unit_a9)
           AND  ((gv_inv_all_flag = cv_status_yes) OR 
                 ((gv_inv_all_flag = cv_status_no) AND  (get_14account_rec.bill_base_code = gt_user_dept)))   -- �������_ = ���O�C�����[�U�̋��_
           AND  (get_14account_rec.bill_tax_div IN (cv_syohizei_kbn_inc2,cv_syohizei_kbn_inc3))               -- ����ŋ敪 IN (����(�`�[),����(�P��))
           AND  (get_14account_rec.bill_invoice_type = iv_bill_invoice_type)                                  -- �������o�͌`�� = ���̓p�����[�^�u�������o�͌`���v
           AND  (get_14account_rec.cons_inv_flag = cv_enabled_yes)                                             -- �ꊇ�������� = 'Y'(�L��)
           AND  (get_14account_rec.bill_pub_cycle = NVL(iv_bill_pub_cycle, get_14account_rec.bill_pub_cycle)) -- ���������s�T�C�N�� = ���̓p�����[�^�u���������s�T�C�N���v
          THEN
            BEGIN
            -- ����P�ʁFC�̌ڋq����
            gv_target_c_flag := cv_taget_flag_1;
--
            INSERT INTO xxcfr_rep_st_inv_inc_tax_c_l(
              report_id               , -- ���[�h�c
              issue_date              , -- ���s���t
              zip_code                , -- �X�֔ԍ�
              send_address1           , -- �Z���P
              send_address2           , -- �Z���Q
              send_address3           , -- �Z���R
              bill_cust_code          , -- �ڋq�R�[�h(�\�[�g���Q)
              bill_cust_name          , -- �ڋq��
              location_code           , -- �S�����_�R�[�h
              location_name           , -- �S�����_��
              phone_num               , -- �d�b�ԍ�
              target_date             , -- �Ώ۔N��
              payment_cust_code       , -- ���|�Ǘ��R�[�h
              payment_cust_name       , -- ���|�Ǘ��ڋq��
              ar_concat_text          , -- ���|�Ǘ��R�[�h�A��������(�e���ڂ̊ԂɃX�y�[�X��}��)
              payment_due_date        , -- �����\���
              bank_account            , -- �U���������
              ship_cust_code          , -- �[�i��ڋq�R�[�h
              ship_cust_name          , -- �[�i��ڋq��
              store_code              , -- �X�܃R�[�h
              store_code_sort         , -- �X�܃R�[�h(�\�[�g�p)
              ship_account_number     , -- �[�i��ڋq�R�[�h(�\�[�g�p)
              slip_date               , -- �`�[���t(�\�[�g���R)
              slip_num                , -- �`�[No(�\�[�g���S)
              slip_sum                , -- �`�[���z(�`�[�ԍ��P�ʂŏW�v�����l)
              slip_tax_sum            , -- �`�[�Ŋz(�`�[�ԍ��P�ʂŏW�v�����l)
-- Del 2019.09.03 Ver1.93 Start
--              tax_rate                , -- ����ŗ�(�ҏW�p)
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
              description             , -- �E�v
              category                , -- ���󕪗�(�ҏW�p)
-- Add 2019.09.03 Ver1.93 End
              outsourcing_flag        , -- �Ǝ҈ϑ��t���O
              created_by              , -- �쐬��
              creation_date           , -- �쐬��
              last_updated_by         , -- �ŏI�X�V��
              last_update_date        , -- �ŏI�X�V��
              last_update_login       , -- �ŏI�X�V���O�C��
              request_id              , -- �v��ID
              program_application_id  , -- �A�v���P�[�V����ID
              program_id              , -- �R���J�����g�E�v���O����ID
              program_update_date     ) -- �v���O�����X�V��
            SELECT cv_report_id_10                                                        report_id             , -- ���[�h�c
                   TO_CHAR(xih.inv_creation_date,lv_format_date_jpymd4)                   issue_date            , -- ���s��
                   DECODE(get_14account_rec.bill_postal_code,
                          NULL,NULL,
                          lv_format_zip_mark||SUBSTR(get_14account_rec.bill_postal_code,1,3)||'-'||
                          SUBSTR(get_14account_rec.bill_postal_code,4,4))                 zip_code              , -- �X�֔ԍ�
                   get_14account_rec.bill_state||get_14account_rec.bill_city              send_address1         , -- �Z���P
                   get_14account_rec.bill_address1                                        send_address2         , -- �Z���Q
                   get_14account_rec.bill_address2                                        send_address3         , -- �Z���R
                   get_14account_rec.cash_account_number                                  bill_cust_code        , -- �ڋq�R�[�h(�\�[�g���Q)
                   get_14account_rec.cash_account_name                                    bill_cust_name        , -- �ڋq��
                   get_14account_rec.bill_base_code                                       bill_base_code        , -- �S�����_�R�[�h
                   xffvv.description                                                      location_name         , -- �S�����_��
                   xxcfr_common_pkg.get_base_target_tel_num(get_14account_rec.cash_account_number)  phone_num   , -- �d�b�ԍ�
                   SUBSTR(xih.object_month,1,4)||lv_format_date_year||
                   SUBSTR(xih.object_month,5,2)||lv_format_date_month                     target_date           , -- �Ώ۔N��
                   get_14account_rec.cash_account_number                                  payment_cust_code     , -- ������ڋq�R�[�h
                   get_14account_rec.cash_account_name                                    payment_cust_name     , -- ������ڋq��
                   get_14account_rec.cash_account_number||' '||xih.term_name              ar_concat_text        , -- ���|�Ǘ��R�[�h�A��������
                   TO_CHAR(xih.payment_date, lv_format_date_jpymd2)                       payment_due_date      , -- �����\���
                   CASE
                   WHEN account.bank_account_num IS NULL THEN
                     NULL
                   ELSE
                     DECODE(SUBSTR(account.bank_number,1,1),
                     lv_format_bank_dummy,NULL,                                       -- �_�~�[��s�̏ꍇ��NULL
                     CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
                       CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
                         account.bank_name
                       ELSE
                         account.bank_name ||lv_format_date_bank
                       END
                     ELSE
                      account.bank_name 
                     END||' '||                                                       -- ��s��
                     CASE WHEN INSTR(account.bank_branch_name
                                    ,lv_format_date_central)>0 THEN
                       account.bank_branch_name
                     ELSE
                       account.bank_branch_name||lv_format_date_branch 
                     END||' '||                                                       -- �x�X��
                     DECODE( account.bank_account_type,
                             1,lv_format_date_account,
                             2,lv_format_date_current,
                             account.bank_account_type) ||' '||                       -- �������
                     account.bank_account_num ||' '||                                 -- �����ԍ�
                     account.account_holder_name||' '||                               -- �������`�l
                     account.account_holder_name_alt)                                 -- �������`�l�J�i��
                   END                                                                    account_data          , -- �U���������
                   xil.ship_cust_code                                                     ship_cust_code        , -- �[�i��ڋq�R�[�h
                   hzp.party_name                                                         ship_cust_name        , -- �[�i��ڋq��
                   LPAD(NVL(all_account_rec.store_code,'0'),10,'0')                       store_code            , -- �X�܃R�[�h
                   LPAD(NVL(all_account_rec.store_code,'0'),10,'0')                       store_code_sort       , -- �X�܃R�[�h(�\�[�g�p)
                   xil.ship_cust_code                                                     ship_account_number   , -- �[�i��ڋq�R�[�h(�\�[�g�p)
                   TO_CHAR(DECODE(xil.acceptance_date,
                                  NULL,xil.delivery_date,
                                  xil.acceptance_date),
                           cv_format_date_ymds2)                                          slip_date             , -- �`�[���t(�\�[�g���R)
                   xil.slip_num                                                           slip_num              , -- �`�[No(�\�[�g���S)
                   SUM(xil.ship_amount)                                                   slip_sum              , -- �`�[���z(�Ŕ��z)
                   SUM(xil.tax_amount)                                                    tax_sum               , -- �`�[�Ŋz
-- Del 2019.09.03 Ver1.93 Start
--                   xil.tax_rate                                                           tax_rate              , -- ����ŗ�
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
                   NVL(flvv.attribute1,' ')                                               description           , -- �E�v
                   flvv.attribute2                                                        category              , -- ��������(�ҏW�p)
-- Add 2019.09.03 Ver1.93 End
                   CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
                     cv_os_flag_y
                   ELSE
                     NULL
                   END                                                                    outsourcing_flag      , -- �Ǝ҈ϑ��t���O
                   cn_created_by                                                          created_by            , -- �쐬��
                   cd_creation_date                                                       creation_date         , -- �쐬��
                   cn_last_updated_by                                                     last_updated_by       , -- �ŏI�X�V��
                   cd_last_update_date                                                    last_update_date      , -- �ŏI�X�V��
                   cn_last_update_login                                                   last_update_login     , -- �ŏI�X�V���O�C��
                   cn_request_id                                                          request_id            , -- �v��ID
                   cn_program_application_id                                              program_application_id, -- �A�v���P�[�V����ID
                   cn_program_id                                                          program_id            , -- �R���J�����g�E�v���O����ID
                   cd_program_update_date                                                 program_update_date     -- �v���O�����X�V��
            FROM xxcfr_invoice_headers          xih  , -- �����w�b�_
                 xxcfr_invoice_lines            xil  , -- ��������
                 hz_cust_accounts               hzca , -- �ڋq10�ڋq�}�X�^
                 hz_parties                     hzp  , -- �ڋq10�p�[�e�B�}�X�^
                 (SELECT all_account_rec.customer_code ship_cust_code,
                         rcrm.customer_id             customer_id,
                         abb.bank_number              bank_number,
                         abb.bank_name                bank_name,
                         abb.bank_branch_name         bank_branch_name,
                         abaa.bank_account_type       bank_account_type,
                         abaa.bank_account_num        bank_account_num,
                         abaa.account_holder_name     account_holder_name,
                         abaa.account_holder_name_alt account_holder_name_alt
                  FROM ra_cust_receipt_methods        rcrm , --�x�����@���
                       ar_receipt_method_accounts_all arma , --AR�x�����@����
                       ap_bank_accounts_all           abaa , --��s����
                       ap_bank_branches               abb    --��s�x�X
                  WHERE rcrm.primary_flag = cv_enabled_yes
                    AND get_14account_rec.cash_account_id = rcrm.customer_id
                    AND gd_target_date BETWEEN rcrm.start_date AND NVL(rcrm.end_date ,cd_max_date)
                    AND rcrm.site_use_id IS NOT NULL
                    AND rcrm.receipt_method_id = arma.receipt_method_id(+)
                    AND arma.bank_account_id = abaa.bank_account_id(+)
                    AND abaa.bank_branch_id = abb.bank_branch_id(+)
                    AND arma.org_id = gn_org_id
                    AND abaa.org_id = gn_org_id             ) account,    -- ��s�����r���[
                 (SELECT ffv.flex_value   flex_value,
                         ffv.description  description
                  FROM   fnd_flex_values_vl ffv
                  WHERE  EXISTS
                         (SELECT  'X'
                          FROM    fnd_flex_value_sets ffvs
                          WHERE   ffvs.flex_value_set_name = cv_ffv_set_name_dept
                          AND     ffvs.flex_value_set_id   = ffv.flex_value_set_id)) xffvv
-- Add 2019.09.03 Ver1.93 Start
                ,fnd_lookup_values_vl           flvv    -- �Q�ƕ\
-- Add 2019.09.03 Ver1.93 End
            WHERE xih.invoice_id = xil.invoice_id                                       -- �ꊇ������ID
              AND xil.cutoff_date = gd_target_date                                      -- �p�����[�^�D����
              AND xil.ship_cust_code = account.ship_cust_code(+)                        -- �O�������̂��߂̃_�~�[����
              AND xih.set_of_books_id = gn_set_of_bks_id
              AND xih.org_id = gn_org_id
              AND get_14account_rec.bill_base_code = xffvv.flex_value
              AND xil.ship_cust_code = all_account_rec.customer_code
              AND hzca.cust_account_id = all_account_rec.customer_id
              AND hzp.party_id = hzca.party_id
-- Add 2019.09.03 Ver1.93 Start
              AND flvv.lookup_type(+)  = cv_xxcfr_tax_category
              AND xil.tax_code         = flvv.lookup_code(+)
              AND flvv.enabled_flag(+) = cv_enabled_yes
-- Add 2019.09.03 Ver1.93 End
            GROUP BY cv_pkg_name,
                     xih.inv_creation_date,
                     DECODE(get_14account_rec.bill_postal_code,
                                 NULL,NULL,
                                 lv_format_zip_mark||SUBSTR(get_14account_rec.bill_postal_code,1,3)||'-'||
                                 SUBSTR(get_14account_rec.bill_postal_code,4,4)),
                     get_14account_rec.bill_state||get_14account_rec.bill_city,
                     get_14account_rec.bill_address1,
                     get_14account_rec.bill_address2,
                     get_14account_rec.cash_account_number,
                     get_14account_rec.cash_account_name,
                     xffvv.description,
                     xih.object_month,
                     get_14account_rec.cash_account_number||' '||xih.term_name,
                     xih.payment_date,
                     CASE
                     WHEN account.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(account.bank_number,1,1),
                       lv_format_bank_dummy,NULL,                                       -- �_�~�[��s�̏ꍇ��NULL
                       CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
                         CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
                           account.bank_name
                         ELSE
                           account.bank_name ||lv_format_date_bank
                         END
                       ELSE
                        account.bank_name 
                       END||' '||                                                       -- ��s��
                       CASE WHEN INSTR(account.bank_branch_name
                                      ,lv_format_date_central)>0 THEN
                         account.bank_branch_name
                       ELSE
                         account.bank_branch_name||lv_format_date_branch 
                       END||' '||                                                       -- �x�X��
                       DECODE( account.bank_account_type,
                               1,lv_format_date_account,
                               2,lv_format_date_current,
                               account.bank_account_type) ||' '||                       -- �������
                       account.bank_account_num ||' '||                                 -- �����ԍ�
                       account.account_holder_name||' '||                               -- �������`�l
                       account.account_holder_name_alt)                                 -- �������`�l�J�i��
                     END,
                     xil.ship_cust_code,
                     hzp.party_name,
                     TO_CHAR(DECODE(xil.acceptance_date,
                                    NULL,xil.delivery_date,
                                    xil.acceptance_date),
                     cv_format_date_ymds2),
                     xil.slip_num,
-- Del 2019.09.03 Ver1.93 Start
--                     xil.tax_rate,
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
                     flvv.attribute1,
                     flvv.attribute2,
-- Add 2019.09.03 Ver1.93 End
                     CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
                       cv_os_flag_y
                     ELSE
                       NULL
                     END
                     ;
--
            EXCEPTION
              WHEN OTHERS THEN  -- �o�^���G���[
                lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                               ,cv_msg_003a18_013    -- �e�[�u���o�^�G���[
                                                               ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                               ,xxcfr_common_pkg.get_table_comment(cv_table_c_l))
                                                              -- �W���������ō����[�������P��C���[�N�e�[�u������
                                     ,1
                                     ,5000);
                lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
                RAISE global_api_expt;
            END;
--
            gn_target_cnt_c_l := gn_target_cnt_c_l + SQL%ROWCOUNT;
--
-- Add 2016.03.31 Ver1.90 End
-- Ver.1.92 [��QE_�{�ғ�_15307] ADD START
          --����������P�� = 'A10'
          ELSIF (all_account_rec.invoice_printing_unit = cv_invoice_printing_unit_a10)
           AND  ((gv_inv_all_flag = cv_status_yes) OR 
                 ((gv_inv_all_flag = cv_status_no) AND  (get_14account_rec.bill_base_code = gt_user_dept)))   -- �������_ = ���O�C�����[�U�̋��_
           AND  (get_14account_rec.bill_tax_div IN (cv_syohizei_kbn_inc2,cv_syohizei_kbn_inc3))               -- ����ŋ敪 IN (����(�`�[),����(�P��))
           AND  (get_14account_rec.bill_invoice_type = iv_bill_invoice_type)                                  -- �������o�͌`�� = ���̓p�����[�^�u�������o�͌`���v
           AND  (get_14account_rec.cons_inv_flag = cv_enabled_yes)                                            -- �ꊇ�������� = 'Y'(�L��)
           AND  (get_14account_rec.bill_pub_cycle = NVL(iv_bill_pub_cycle, get_14account_rec.bill_pub_cycle)) -- ���������s�T�C�N�� = ���̓p�����[�^�u���������s�T�C�N���v
          THEN
--
            BEGIN
            -- ����P�ʁFD�̌ڋq����
            gv_target_d_flag := cv_taget_flag_1;
--
            INSERT INTO xxcfr_rep_st_inv_inc_tax_d_l(
              report_id               , -- ���[�h�c
              issue_date              , -- ���s���t
              zip_code                , -- �X�֔ԍ�
              send_address1           , -- �Z���P
              send_address2           , -- �Z���Q
              send_address3           , -- �Z���R
              bill_cust_code          , -- �ڋq�R�[�h(�\�[�g���Q)
              bill_cust_name          , -- �ڋq��
              location_code           , -- �S�����_�R�[�h
              location_name           , -- �S�����_��
              phone_num               , -- �d�b�ԍ�
              target_date             , -- �Ώ۔N��
              payment_cust_code       , -- ���|�Ǘ��ڋq�R�[�h
              payment_cust_name       , -- ���|�Ǘ��ڋq��
              ar_concat_text          , -- ���|�Ǘ��R�[�h�A��������(�e���ڂ̊ԂɃX�y�[�X��}��)
              payment_due_date        , -- �����\���
              bank_account            , -- �U���������
              ship_cust_code          , -- �[�i��ڋq�R�[�h
              ship_cust_name          , -- �[�i��ڋq��
              store_code              , -- �X�܃R�[�h
              store_code_sort         , -- �X�܃R�[�h(�\�[�g�p)
              ship_account_number     , -- �[�i��ڋq�R�[�h(�\�[�g�p)
              slip_date               , -- �`�[���t(�\�[�g���R)
              slip_num                , -- �`�[No(�\�[�g���S)
              slip_sum                , -- �`�[���z(�`�[�ԍ��P�ʂŏW�v�����l)
              slip_tax_sum            , -- �`�[�Ŋz(�`�[�ԍ��P�ʂŏW�v�����l)
-- Del 2019.09.03 Ver1.93 Start
--              tax_rate                , -- ����ŗ�(�ҏW�p)
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
              description             , -- �E�v
              category                , -- ���󕪗�(�ҏW�p)
-- Add 2019.09.03 Ver1.93 End
              outsourcing_flag        , -- �Ǝ҈ϑ��t���O
              created_by              , -- �쐬��
              creation_date           , -- �쐬��
              last_updated_by         , -- �ŏI�X�V��
              last_update_date        , -- �ŏI�X�V��
              last_update_login       , -- �ŏI�X�V���O�C��
              request_id              , -- �v��ID
              program_application_id  , -- �A�v���P�[�V����ID
              program_id              , -- �R���J�����g�E�v���O����ID
              program_update_date     ) -- �v���O�����X�V��
            SELECT cv_report_id_14                                                        report_id             , -- ���[�h�c
                   TO_CHAR(xih.inv_creation_date,lv_format_date_jpymd4)                   issue_date            , -- ���s��
                   DECODE(get_14account_rec.bill_postal_code,
                          NULL,NULL,
                          lv_format_zip_mark||SUBSTR(get_14account_rec.bill_postal_code,1,3)||'-'||
                          SUBSTR(get_14account_rec.bill_postal_code,4,4))                 zip_code              , -- �X�֔ԍ�
                   get_14account_rec.bill_state||get_14account_rec.bill_city              send_address1         , -- �Z���P
                   get_14account_rec.bill_address1                                        send_address2         , -- �Z���Q
                   get_14account_rec.bill_address2                                        send_address3         , -- �Z���R
                   get_14account_rec.cash_account_number                                  bill_cust_code        , -- �ڋq�R�[�h(�\�[�g���Q)
                   get_14account_rec.cash_account_name                                    bill_cust_name        , -- �ڋq��
                   get_14account_rec.bill_base_code                                       bill_base_code        , -- �S�����_�R�[�h
                   xffvv.description                                                      location_name         , -- �S�����_��
                   xxcfr_common_pkg.get_base_target_tel_num(get_14account_rec.cash_account_number)  phone_num   , -- �d�b�ԍ�
                   SUBSTR(xih.object_month,1,4)||lv_format_date_year||
                   SUBSTR(xih.object_month,5,2)||lv_format_date_month                     target_date           , -- �Ώ۔N��
                   get_14account_rec.cash_account_number                                  payment_cust_code     , -- ������ڋq�R�[�h
                   get_14account_rec.cash_account_name                                    payment_cust_name     , -- ������ڋq��
                   get_14account_rec.cash_account_number||' '||xih.term_name              ar_concat_text        , -- ���|�Ǘ��R�[�h�A��������
                   TO_CHAR(xih.payment_date, lv_format_date_jpymd2)                       payment_due_date      , -- �����\���
                   CASE
                   WHEN account.bank_account_num IS NULL THEN
                     NULL
                   ELSE
                     DECODE(SUBSTR(account.bank_number,1,1),
                     lv_format_bank_dummy,NULL,                                       -- �_�~�[��s�̏ꍇ��NULL
                     CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
                       CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
                         account.bank_name
                       ELSE
                         account.bank_name ||lv_format_date_bank
                       END
                     ELSE
                      account.bank_name 
                     END||' '||                                                       -- ��s��
                     CASE WHEN INSTR(account.bank_branch_name
                                    ,lv_format_date_central)>0 THEN
                       account.bank_branch_name
                     ELSE
                       account.bank_branch_name||lv_format_date_branch 
                     END||' '||                                                       -- �x�X��
                     DECODE( account.bank_account_type,
                             1,lv_format_date_account,
                             2,lv_format_date_current,
                             account.bank_account_type) ||' '||                       -- �������
                     account.bank_account_num ||' '||                                 -- �����ԍ�
                     account.account_holder_name||' '||                               -- �������`�l
                     account.account_holder_name_alt)                                 -- �������`�l�J�i��
                   END                                                                    account_data          , -- �U���������
                   xil.ship_cust_code                                                     ship_cust_code        , -- �[�i��ڋq�R�[�h
                   hzp.party_name                                                         ship_cust_name        , -- �[�i��ڋq��
                   LPAD(NVL(all_account_rec.store_code,'0'),10,'0')                       store_code            , -- �X�܃R�[�h
                   LPAD(NVL(all_account_rec.store_code,'0'),10,'0')                       store_code_sort       , -- �X�܃R�[�h(�\�[�g�p)
                   xil.ship_cust_code                                                     ship_account_number   , -- �[�i��ڋq�R�[�h(�\�[�g�p)
                   TO_CHAR(DECODE(xil.acceptance_date,
                                  NULL,xil.delivery_date,
                                  xil.acceptance_date),
                           cv_format_date_ymds2)                                          slip_date             , -- �`�[���t(�\�[�g���R)
                   xil.slip_num                                                           slip_num              , -- �`�[No(�\�[�g���S)
                   SUM(xil.ship_amount)                                                   slip_sum              , -- �`�[���z(�Ŕ��z)
                   SUM(xil.tax_amount)                                                    tax_sum               , -- �`�[�Ŋz
-- Del 2019.09.03 Ver1.93 Start
--                   xil.tax_rate                                                           tax_rate              , -- ����ŗ�
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
                   NVL(flvv.attribute1,' ')                                               description           , -- �E�v
                   flvv.attribute2                                                        category              , -- ��������(�ҏW�p)
-- Add 2019.09.03 Ver1.93 End
                   CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
                     cv_os_flag_y
                   ELSE
                     NULL
                   END                                                                    outsourcing_flag      , -- �Ǝ҈ϑ��t���O
                   cn_created_by                                                          created_by            , -- �쐬��
                   cd_creation_date                                                       creation_date         , -- �쐬��
                   cn_last_updated_by                                                     last_updated_by       , -- �ŏI�X�V��
                   cd_last_update_date                                                    last_update_date      , -- �ŏI�X�V��
                   cn_last_update_login                                                   last_update_login     , -- �ŏI�X�V���O�C��
                   cn_request_id                                                          request_id            , -- �v��ID
                   cn_program_application_id                                              program_application_id, -- �A�v���P�[�V����ID
                   cn_program_id                                                          program_id            , -- �R���J�����g�E�v���O����ID
                   cd_program_update_date                                                 program_update_date     -- �v���O�����X�V��
            FROM xxcfr_invoice_headers          xih  , -- �����w�b�_
                 xxcfr_invoice_lines            xil  , -- ��������
                 hz_cust_accounts               hzca , -- �ڋq10�ڋq�}�X�^
                 hz_parties                     hzp  , -- �ڋq10�p�[�e�B�}�X�^
                 (SELECT all_account_rec.customer_code ship_cust_code,
                         rcrm.customer_id             customer_id,
                         abb.bank_number              bank_number,
                         abb.bank_name                bank_name,
                         abb.bank_branch_name         bank_branch_name,
                         abaa.bank_account_type       bank_account_type,
                         abaa.bank_account_num        bank_account_num,
                         abaa.account_holder_name     account_holder_name,
                         abaa.account_holder_name_alt account_holder_name_alt
                  FROM ra_cust_receipt_methods        rcrm , --�x�����@���
                       ar_receipt_method_accounts_all arma , --AR�x�����@����
                       ap_bank_accounts_all           abaa , --��s����
                       ap_bank_branches               abb    --��s�x�X
                  WHERE rcrm.primary_flag = cv_enabled_yes
                    AND get_14account_rec.cash_account_id = rcrm.customer_id
                    AND gd_target_date BETWEEN rcrm.start_date AND NVL(rcrm.end_date ,cd_max_date)
                    AND rcrm.site_use_id IS NOT NULL
                    AND rcrm.receipt_method_id = arma.receipt_method_id(+)
                    AND arma.bank_account_id = abaa.bank_account_id(+)
                    AND abaa.bank_branch_id = abb.bank_branch_id(+)
                    AND arma.org_id = gn_org_id
                    AND abaa.org_id = gn_org_id             ) account,    -- ��s�����r���[
                 (SELECT ffv.flex_value   flex_value,
                         ffv.description  description
                  FROM   fnd_flex_values_vl ffv
                  WHERE  EXISTS
                         (SELECT  'X'
                          FROM    fnd_flex_value_sets ffvs
                          WHERE   ffvs.flex_value_set_name = cv_ffv_set_name_dept
                          AND     ffvs.flex_value_set_id   = ffv.flex_value_set_id)) xffvv
-- Add 2019.09.03 Ver1.93 Start
                ,fnd_lookup_values_vl           flvv    -- �Q�ƕ\
-- Add 2019.09.03 Ver1.93 End
            WHERE xih.invoice_id = xil.invoice_id                                       -- �ꊇ������ID
              AND xil.cutoff_date = gd_target_date                                      -- �p�����[�^�D����
              AND xil.ship_cust_code = account.ship_cust_code(+)                        -- �O�������̂��߂̃_�~�[����
              AND xih.set_of_books_id = gn_set_of_bks_id
              AND xih.org_id = gn_org_id
              AND get_14account_rec.bill_base_code = xffvv.flex_value
              AND xil.ship_cust_code = all_account_rec.customer_code
              AND hzca.cust_account_id = all_account_rec.customer_id
              AND hzp.party_id = hzca.party_id
-- Add 2019.09.03 Ver1.93 Start
              AND flvv.lookup_type(+)  = cv_xxcfr_tax_category
              AND xil.tax_code         = flvv.lookup_code(+)
              AND flvv.enabled_flag(+) = cv_enabled_yes
-- Add 2019.09.03 Ver1.93 End
            GROUP BY cv_pkg_name,
                     xih.inv_creation_date,
                     DECODE(get_14account_rec.bill_postal_code,
                                 NULL,NULL,
                                 lv_format_zip_mark||SUBSTR(get_14account_rec.bill_postal_code,1,3)||'-'||
                                 SUBSTR(get_14account_rec.bill_postal_code,4,4)),
                     get_14account_rec.bill_state||get_14account_rec.bill_city,
                     get_14account_rec.bill_address1,
                     get_14account_rec.bill_address2,
                     get_14account_rec.cash_account_number,
                     get_14account_rec.cash_account_name,
                     xffvv.description,
                     xih.object_month,
                     get_14account_rec.cash_account_number||' '||xih.term_name,
                     xih.payment_date,
                     CASE
                     WHEN account.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(account.bank_number,1,1),
                       lv_format_bank_dummy,NULL,                                       -- �_�~�[��s�̏ꍇ��NULL
                       CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
                         CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
                           account.bank_name
                         ELSE
                           account.bank_name ||lv_format_date_bank
                         END
                       ELSE
                        account.bank_name 
                       END||' '||                                                       -- ��s��
                       CASE WHEN INSTR(account.bank_branch_name
                                      ,lv_format_date_central)>0 THEN
                         account.bank_branch_name
                       ELSE
                         account.bank_branch_name||lv_format_date_branch 
                       END||' '||                                                       -- �x�X��
                       DECODE( account.bank_account_type,
                               1,lv_format_date_account,
                               2,lv_format_date_current,
                               account.bank_account_type) ||' '||                       -- �������
                       account.bank_account_num ||' '||                                 -- �����ԍ�
                       account.account_holder_name||' '||                               -- �������`�l
                       account.account_holder_name_alt)                                 -- �������`�l�J�i��
                     END,
                     xil.ship_cust_code,
                     hzp.party_name,
                     TO_CHAR(DECODE(xil.acceptance_date,
                                    NULL,xil.delivery_date,
                                    xil.acceptance_date),
                     cv_format_date_ymds2),
                     xil.slip_num,
-- Del 2019.09.03 Ver1.93 Start
--                     xil.tax_rate,
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
                     flvv.attribute1,
                     flvv.attribute2,
-- Add 2019.09.03 Ver1.93 End
                     CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
                       cv_os_flag_y
                     ELSE
                       NULL
                     END
                     ;
--
            EXCEPTION
              WHEN OTHERS THEN  -- �o�^���G���[
                lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                               ,cv_msg_003a18_013    -- �e�[�u���o�^�G���[
                                                               ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                               ,xxcfr_common_pkg.get_table_comment(cv_table_d_l))
                                                              -- �W���������ō����[�������P��D���[�N�e�[�u������
                                     ,1
                                     ,5000);
                lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
                RAISE global_api_expt;
            END;
--
            gn_target_cnt_d_l := gn_target_cnt_d_l + SQL%ROWCOUNT;
--
-- Ver.1.92 [��QE_�{�ғ�_15307] ADD END
          ELSE
            NULL;
          END IF;
--
          CLOSE get_14account_cur;
--
        END IF;
      END LOOP get_account10_loop;
--
      -- �o�^�f�[�^���P�������݂��Ȃ��ꍇ�A�O�����b�Z�[�W���R�[�h�ǉ�
      IF ( gn_target_cnt = 0 ) THEN
--
        INSERT INTO xxcfr_rep_st_invoice_inc_tax_d (
          data_empty_message           , -- 0�����b�Z�[�W
-- Modify 2014.03.27 Ver1.70 Start
          outsourcing_flag             , -- �Ǝ҈ϑ��t���O
-- Modify 2014.03.27 Ver1.70 End
          created_by                   , -- �쐬��
          creation_date                , -- �쐬��
          last_updated_by              , -- �ŏI�X�V��
          last_update_date             , -- �ŏI�X�V��
          last_update_login            , -- �ŏI�X�V���O�C��
          request_id                   , -- �v��ID
          program_application_id       , -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          program_id                   , -- �R���J�����g�E�v���O����ID
          program_update_date          ) -- �v���O�����X�V��
        VALUES (
          lv_no_data_msg               , -- 0�����b�Z�[�W
-- Modify 2014.03.27 Ver1.70 Start
          CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
            cv_os_flag_y
          ELSE
            NULL
          END                          , -- �Ǝ҈ϑ��t���O
-- Modify 2014.03.27 Ver1.70 End
          cn_created_by                , -- �쐬��
          cd_creation_date             , -- �쐬��
          cn_last_updated_by           , -- �ŏI�X�V��
          cd_last_update_date          , -- �ŏI�X�V��
          cn_last_update_login         , -- �ŏI�X�V���O�C��
          cn_request_id                , -- �v��ID
          cn_program_application_id    , -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          cn_program_id                , -- �R���J�����g�E�v���O����ID
          cd_program_update_date       );-- �v���O�����X�V��
--
        -- �x���I��
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                       ,cv_msg_003a18_016 )  -- �Ώۃf�[�^0���x��
                             ,1
                             ,5000);
        ov_errmsg  := lv_errmsg;
--
        ov_retcode := cv_status_warn;
--
-- Add 2015.07.31 Ver1.80 Start
      END IF;
--
      -- ����P��A���ׂ̑Ώی�����0�ȊO�̏ꍇ
      IF ( gn_target_cnt_a_l <> 0 ) THEN
        -- ����0���t���O�i2�F�Ώۃf�[�^����j
        gv_target_a_flag := cv_taget_flag_2;
        -- �W���������ō����[�������P��A���[�N�e�[�u���w�b�_�̓o�^
        INSERT INTO xxcfr_rep_st_inv_inc_tax_a_h(
           report_id                -- ���[ID
          ,issue_date               -- ���s���t
          ,zip_code                 -- �X�֔ԍ�
          ,send_address1            -- �Z���P
          ,send_address2            -- �Z���Q
          ,send_address3            -- �Z���R
          ,bill_cust_code           -- �ڋq�R�[�h
          ,bill_cust_name           -- �ڋq��
          ,location_code            -- �S�����_�R�[�h
          ,location_name            -- �S�����_��
          ,phone_num                -- �d�b�ԍ�
          ,target_date              -- �Ώ۔N��
          ,payment_cust_code        -- ���|�Ǘ��R�[�h
          ,payment_cust_name        -- ���|�Ǘ��ڋq��
          ,ar_concat_text           -- ���|�Ǘ��R�[�h�A��������
          ,payment_due_date         -- �����\���
          ,bank_account             -- �U������
          ,ship_cust_code           -- �[�i��ڋq�R�[�h
          ,ship_cust_name           -- �[�i��ڋq��
          ,store_code               -- �X�܃R�[�h
          ,store_code_sort          -- �X�܃R�[�h�i�\�[�g�p�j
          ,ship_account_number      -- �[�i��ڋq�R�[�h�i�\�[�g�p�j
          ,outsourcing_flag         -- �Ǝ҈ϑ��t���O
          ,store_charge_sum         -- �X�܋��z
          ,store_tax_sum            -- �X�ܐŊz
          ,created_by               -- �쐬��
          ,creation_date            -- �쐬��
          ,last_updated_by          -- �ŏI�X�V��
          ,last_update_date         -- �ŏI�X�V��
          ,last_update_login        -- �ŏI�X�V���O�C��
          ,request_id               -- �v��ID
          ,program_application_id   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          ,program_id               -- �R���J�����g�E�v���O����ID
          ,program_update_date      -- �v���O�����X�V��
        )
        SELECT cv_report_id_01             -- ���[ID
              ,xrsal.issue_date            -- ���s���t
              ,xrsal.zip_code              -- �X�֔ԍ�
              ,xrsal.send_address1         -- �Z���P
              ,xrsal.send_address2         -- �Z���Q
              ,xrsal.send_address3         -- �Z���R
              ,xrsal.bill_cust_code        -- �ڋq�R�[�h
              ,xrsal.bill_cust_name        -- �ڋq��
              ,xrsal.location_code         -- �S�����_�R�[�h
              ,xrsal.location_name         -- �S�����_��
              ,xrsal.phone_num             -- �d�b�ԍ�
              ,xrsal.target_date           -- �Ώ۔N��
              ,xrsal.payment_cust_code     -- ���|�Ǘ��R�[�h
              ,xrsal.payment_cust_name     -- ���|�Ǘ��ڋq��
              ,xrsal.ar_concat_text        -- ���|�Ǘ��R�[�h�A��������
              ,xrsal.payment_due_date      -- �����\���
              ,xrsal.bank_account          -- �U������
              ,xrsal.ship_cust_code        -- �[�i��ڋq�R�[�h
              ,xrsal.ship_cust_name        -- �[�i��ڋq��
              ,xrsal.store_code            -- �X�܃R�[�h
              ,xrsal.store_code_sort       -- �X�܃R�[�h�i�\�[�g�p�j
              ,xrsal.ship_account_number   -- �[�i��ڋq�R�[�h�i�\�[�g�p�j
              ,xrsal.outsourcing_flag      -- �Ǝ҈ϑ��t���O
              ,SUM(xrsal.slip_sum)         -- �X�܋��z
              ,SUM(xrsal.slip_tax_sum)     -- �X�ܐŊz
              ,cn_created_by               -- �쐬��
              ,cd_creation_date            -- �쐬��
              ,cn_last_updated_by          -- �ŏI�X�V��
              ,cd_last_update_date         -- �ŏI�X�V��
              ,cn_last_update_login        -- �ŏI�X�V���O�C��
              ,cn_request_id               -- �v��ID
              ,cn_program_application_id   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
              ,cn_program_id               -- �R���J�����g�E�v���O����ID
              ,cd_program_update_date      -- �v���O�����X�V��
        FROM   xxcfr_rep_st_inv_inc_tax_a_l  xrsal
        WHERE  xrsal.request_id = cn_request_id
        GROUP BY cv_report_id_01             -- ���[ID
                ,xrsal.issue_date            -- ���s���t
                ,xrsal.zip_code              -- �X�֔ԍ�
                ,xrsal.send_address1         -- �Z���P
                ,xrsal.send_address2         -- �Z���Q
                ,xrsal.send_address3         -- �Z���R
                ,xrsal.bill_cust_code        -- �ڋq�R�[�h
                ,xrsal.bill_cust_name        -- �ڋq��
                ,xrsal.location_code         -- �S�����_�R�[�h
                ,xrsal.location_name         -- �S�����_��
                ,xrsal.phone_num             -- �d�b�ԍ�
                ,xrsal.target_date           -- �Ώ۔N��
                ,xrsal.payment_cust_code     -- ���|�Ǘ��R�[�h
                ,xrsal.payment_cust_name     -- ���|�Ǘ��ڋq��
                ,xrsal.ar_concat_text        -- ���|�Ǘ��R�[�h�A��������
                ,xrsal.payment_due_date      -- �����\���
                ,xrsal.bank_account          -- �U������
                ,xrsal.ship_cust_code        -- �[�i��ڋq�R�[�h
                ,xrsal.ship_cust_name        -- �[�i��ڋq��
                ,xrsal.store_code            -- �X�܃R�[�h
                ,xrsal.store_code_sort       -- �X�܃R�[�h�i�\�[�g�p�j
                ,xrsal.ship_account_number   -- �[�i��ڋq�R�[�h�i�\�[�g�p�j
                ,xrsal.outsourcing_flag      -- �Ǝ҈ϑ��t���O
                ,cn_created_by               -- �쐬��
                ,cd_creation_date            -- �쐬��
                ,cn_last_updated_by          -- �ŏI�X�V��
                ,cd_last_update_date         -- �ŏI�X�V��
                ,cn_last_update_login        -- �ŏI�X�V���O�C��
                ,cn_request_id               -- �v��ID
                ,cn_program_application_id   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                ,cn_program_id               -- �R���J�����g�E�v���O����ID
                ,cd_program_update_date      -- �v���O�����X�V��
        ;
--
        gn_target_cnt_a_h := SQL%ROWCOUNT;
--
      -- ����P�ʁFA�̌ڋq����A���Ώۃf�[�^���Ȃ��ꍇ
      ELSIF ( gv_target_a_flag = cv_taget_flag_1 ) THEN
        -- ���[�O�����b�Z�[�W��W���������ō����[�������P��A���[�N�e�[�u���w�b�_�ɓo�^
        INSERT INTO xxcfr_rep_st_inv_inc_tax_a_h (
          data_empty_message           , -- 0�����b�Z�[�W
          outsourcing_flag             , -- �Ǝ҈ϑ��t���O
          created_by                   , -- �쐬��
          creation_date                , -- �쐬��
          last_updated_by              , -- �ŏI�X�V��
          last_update_date             , -- �ŏI�X�V��
          last_update_login            , -- �ŏI�X�V���O�C��
          request_id                   , -- �v��ID
          program_application_id       , -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          program_id                   , -- �R���J�����g�E�v���O����ID
          program_update_date          ) -- �v���O�����X�V��
        VALUES (
          lv_no_data_msg               , -- 0�����b�Z�[�W
          CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
            cv_os_flag_y
          ELSE
            NULL
          END                          , -- �Ǝ҈ϑ��t���O
          cn_created_by                , -- �쐬��
          cd_creation_date             , -- �쐬��
          cn_last_updated_by           , -- �ŏI�X�V��
          cd_last_update_date          , -- �ŏI�X�V��
          cn_last_update_login         , -- �ŏI�X�V���O�C��
          cn_request_id                , -- �v��ID
          cn_program_application_id    , -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          cn_program_id                , -- �R���J�����g�E�v���O����ID
          cd_program_update_date       );-- �v���O�����X�V��
      END IF;
--
      IF ( gn_target_cnt_b_l <> 0 ) THEN
        -- ����0���t���O�i2�F�Ώۃf�[�^����j
        gv_target_b_flag := cv_taget_flag_2;
--
        -- �W���������ō����[�������P��B���[�N�e�[�u���w�b�_�̓o�^
        INSERT INTO xxcfr_rep_st_inv_inc_tax_b_h(
           report_id                -- ���[ID
          ,issue_date               -- ���s���t
          ,zip_code                 -- �X�֔ԍ�
          ,send_address1            -- �Z���P
          ,send_address2            -- �Z���Q
          ,send_address3            -- �Z���R
          ,bill_cust_code           -- �ڋq�R�[�h
          ,bill_cust_name           -- �ڋq��
          ,location_code            -- �S�����_�R�[�h
          ,location_name            -- �S�����_��
          ,phone_num                -- �d�b�ԍ�
          ,target_date              -- �Ώ۔N��
          ,payment_cust_code        -- ���|�Ǘ��R�[�h
          ,payment_cust_name        -- ���|�Ǘ��ڋq��
          ,ar_concat_text           -- ���|�Ǘ��R�[�h�A��������
          ,payment_due_date         -- �����\���
          ,bank_account             -- �U������
          ,outsourcing_flag         -- �Ǝ҈ϑ��t���O
          ,total_charge             -- �������z
          ,created_by               -- �쐬��
          ,creation_date            -- �쐬��
          ,last_updated_by          -- �ŏI�X�V��
          ,last_update_date         -- �ŏI�X�V��
          ,last_update_login        -- �ŏI�X�V���O�C��
          ,request_id               -- �v��ID
          ,program_application_id   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          ,program_id               -- �R���J�����g�E�v���O����ID
          ,program_update_date      -- �v���O�����X�V��
        )
        SELECT cv_report_id_03                                   -- ���[ID
              ,xrsbl.issue_date                                  -- ���s���t
              ,xrsbl.zip_code                                    -- �X�֔ԍ�
              ,xrsbl.send_address1                               -- �Z���P
              ,xrsbl.send_address2                               -- �Z���Q
              ,xrsbl.send_address3                               -- �Z���R
              ,xrsbl.bill_cust_code                              -- �ڋq�R�[�h
              ,xrsbl.bill_cust_name                              -- �ڋq��
              ,xrsbl.location_code                               -- �S�����_�R�[�h
              ,xrsbl.location_name                               -- �S�����_��
              ,xrsbl.phone_num                                   -- �d�b�ԍ�
              ,xrsbl.target_date                                 -- �Ώ۔N��
              ,xrsbl.payment_cust_code                           -- ���|�Ǘ��R�[�h
              ,xrsbl.payment_cust_name                           -- ���|�Ǘ��ڋq��
              ,xrsbl.ar_concat_text                              -- ���|�Ǘ��R�[�h�A��������
              ,xrsbl.payment_due_date                            -- �����\���
              ,xrsbl.bank_account                                -- �U������
              ,xrsbl.outsourcing_flag                            -- �Ǝ҈ϑ��t���O
              ,SUM(xrsbl.slip_sum) + SUM(xrsbl.slip_tax_sum)     -- �X�܋��z + �X�ܐŊz
              ,cn_created_by                                     -- �쐬��
              ,cd_creation_date                                  -- �쐬��
              ,cn_last_updated_by                                -- �ŏI�X�V��
              ,cd_last_update_date                               -- �ŏI�X�V��
              ,cn_last_update_login                              -- �ŏI�X�V���O�C��
              ,cn_request_id                                     -- �v��ID
              ,cn_program_application_id                         -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
              ,cn_program_id                                     -- �R���J�����g�E�v���O����ID
              ,cd_program_update_date                            -- �v���O�����X�V��
        FROM   xxcfr_rep_st_inv_inc_tax_b_l  xrsbl
        WHERE  xrsbl.request_id = cn_request_id
        GROUP BY cv_report_id_03             -- ���[ID
                ,xrsbl.issue_date            -- ���s���t
                ,xrsbl.zip_code              -- �X�֔ԍ�
                ,xrsbl.send_address1         -- �Z���P
                ,xrsbl.send_address2         -- �Z���Q
                ,xrsbl.send_address3         -- �Z���R
                ,xrsbl.bill_cust_code        -- �ڋq�R�[�h
                ,xrsbl.bill_cust_name        -- �ڋq��
                ,xrsbl.location_code         -- �S�����_�R�[�h
                ,xrsbl.location_name         -- �S�����_��
                ,xrsbl.phone_num             -- �d�b�ԍ�
                ,xrsbl.target_date           -- �Ώ۔N��
                ,xrsbl.payment_cust_code     -- ���|�Ǘ��R�[�h
                ,xrsbl.payment_cust_name     -- ���|�Ǘ��ڋq��
                ,xrsbl.ar_concat_text        -- ���|�Ǘ��R�[�h�A��������
                ,xrsbl.payment_due_date      -- �����\���
                ,xrsbl.bank_account          -- �U������
                ,xrsbl.outsourcing_flag      -- �Ǝ҈ϑ��t���O
                ,cn_created_by               -- �쐬��
                ,cd_creation_date            -- �쐬��
                ,cn_last_updated_by          -- �ŏI�X�V��
                ,cd_last_update_date         -- �ŏI�X�V��
                ,cn_last_update_login        -- �ŏI�X�V���O�C��
                ,cn_request_id               -- �v��ID
                ,cn_program_application_id   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                ,cn_program_id               -- �R���J�����g�E�v���O����ID
                ,cd_program_update_date      -- �v���O�����X�V��
        ;
--
        gn_target_cnt_b_h := SQL%ROWCOUNT;
--
      -- ����P�ʁFB�̌ڋq����A���Ώۃf�[�^���Ȃ��ꍇ
      ELSIF ( gv_target_b_flag = cv_taget_flag_1 ) THEN
        -- ���[�O�����b�Z�[�W��W���������ō����[�������P��B���[�N�e�[�u���w�b�_�ɓo�^
        INSERT INTO xxcfr_rep_st_inv_inc_tax_b_h (
          data_empty_message           , -- 0�����b�Z�[�W
          outsourcing_flag             , -- �Ǝ҈ϑ��t���O
          created_by                   , -- �쐬��
          creation_date                , -- �쐬��
          last_updated_by              , -- �ŏI�X�V��
          last_update_date             , -- �ŏI�X�V��
          last_update_login            , -- �ŏI�X�V���O�C��
          request_id                   , -- �v��ID
          program_application_id       , -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          program_id                   , -- �R���J�����g�E�v���O����ID
          program_update_date          ) -- �v���O�����X�V��
        VALUES (
          lv_no_data_msg               , -- 0�����b�Z�[�W
          CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
            cv_os_flag_y
          ELSE
            NULL
          END                          , -- �Ǝ҈ϑ��t���O
          cn_created_by                , -- �쐬��
          cd_creation_date             , -- �쐬��
          cn_last_updated_by           , -- �ŏI�X�V��
          cd_last_update_date          , -- �ŏI�X�V��
          cn_last_update_login         , -- �ŏI�X�V���O�C��
          cn_request_id                , -- �v��ID
          cn_program_application_id    , -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          cn_program_id                , -- �R���J�����g�E�v���O����ID
          cd_program_update_date       );-- �v���O�����X�V��
--
      END IF;
--
-- Add 2015.07.31 Ver1.80 End
-- Add 2016.03.31 Ver1.90 Start
      -- ����P��C���ׂ̑Ώی�����0�ȊO�̏ꍇ
      IF ( gn_target_cnt_c_l <> 0 ) THEN
        -- ����0���t���O�i2�F�Ώۃf�[�^����j
        gv_target_c_flag := cv_taget_flag_2;
        -- �W���������ō����[�������P��C���[�N�e�[�u���w�b�_�̓o�^
        INSERT INTO xxcfr_rep_st_inv_inc_tax_c_h(
           report_id                -- ���[ID
          ,issue_date               -- ���s���t
          ,zip_code                 -- �X�֔ԍ�
          ,send_address1            -- �Z���P
          ,send_address2            -- �Z���Q
          ,send_address3            -- �Z���R
          ,bill_cust_code           -- �ڋq�R�[�h
          ,bill_cust_name           -- �ڋq��
          ,location_code            -- �S�����_�R�[�h
          ,location_name            -- �S�����_��
          ,phone_num                -- �d�b�ԍ�
          ,target_date              -- �Ώ۔N��
          ,payment_cust_code        -- ���|�Ǘ��R�[�h
          ,payment_cust_name        -- ���|�Ǘ��ڋq��
          ,ar_concat_text           -- ���|�Ǘ��R�[�h�A��������
          ,payment_due_date         -- �����\���
          ,bank_account             -- �U������
          ,ship_cust_code           -- �[�i��ڋq�R�[�h
          ,ship_cust_name           -- �[�i��ڋq��
          ,store_code               -- �X�܃R�[�h
          ,store_code_sort          -- �X�܃R�[�h�i�\�[�g�p�j
          ,ship_account_number      -- �[�i��ڋq�R�[�h�i�\�[�g�p�j
          ,outsourcing_flag         -- �Ǝ҈ϑ��t���O
          ,store_charge_sum         -- �X�܋��z
          ,store_tax_sum            -- �X�ܐŊz
          ,created_by               -- �쐬��
          ,creation_date            -- �쐬��
          ,last_updated_by          -- �ŏI�X�V��
          ,last_update_date         -- �ŏI�X�V��
          ,last_update_login        -- �ŏI�X�V���O�C��
          ,request_id               -- �v��ID
          ,program_application_id   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          ,program_id               -- �R���J�����g�E�v���O����ID
          ,program_update_date      -- �v���O�����X�V��
        )
        SELECT cv_report_id_09             -- ���[ID
              ,xrscl.issue_date            -- ���s���t
              ,xrscl.zip_code              -- �X�֔ԍ�
              ,xrscl.send_address1         -- �Z���P
              ,xrscl.send_address2         -- �Z���Q
              ,xrscl.send_address3         -- �Z���R
              ,xrscl.bill_cust_code        -- �ڋq�R�[�h
              ,xrscl.bill_cust_name        -- �ڋq��
              ,xrscl.location_code         -- �S�����_�R�[�h
              ,xrscl.location_name         -- �S�����_��
              ,xrscl.phone_num             -- �d�b�ԍ�
              ,xrscl.target_date           -- �Ώ۔N��
              ,xrscl.payment_cust_code     -- ���|�Ǘ��R�[�h
              ,xrscl.payment_cust_name     -- ���|�Ǘ��ڋq��
              ,xrscl.ar_concat_text        -- ���|�Ǘ��R�[�h�A��������
              ,xrscl.payment_due_date      -- �����\���
              ,xrscl.bank_account          -- �U������
              ,xrscl.ship_cust_code        -- �[�i��ڋq�R�[�h
              ,xrscl.ship_cust_name        -- �[�i��ڋq��
              ,xrscl.store_code            -- �X�܃R�[�h
              ,xrscl.store_code_sort       -- �X�܃R�[�h�i�\�[�g�p�j
              ,xrscl.ship_account_number   -- �[�i��ڋq�R�[�h�i�\�[�g�p�j
              ,xrscl.outsourcing_flag      -- �Ǝ҈ϑ��t���O
              ,SUM(xrscl.slip_sum)         -- �X�܋��z
              ,SUM(xrscl.slip_tax_sum)     -- �X�ܐŊz
              ,cn_created_by               -- �쐬��
              ,cd_creation_date            -- �쐬��
              ,cn_last_updated_by          -- �ŏI�X�V��
              ,cd_last_update_date         -- �ŏI�X�V��
              ,cn_last_update_login        -- �ŏI�X�V���O�C��
              ,cn_request_id               -- �v��ID
              ,cn_program_application_id   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
              ,cn_program_id               -- �R���J�����g�E�v���O����ID
              ,cd_program_update_date      -- �v���O�����X�V��
        FROM   xxcfr_rep_st_inv_inc_tax_c_l  xrscl
        WHERE  xrscl.request_id = cn_request_id
        GROUP BY cv_report_id_09             -- ���[ID
                ,xrscl.issue_date            -- ���s���t
                ,xrscl.zip_code              -- �X�֔ԍ�
                ,xrscl.send_address1         -- �Z���P
                ,xrscl.send_address2         -- �Z���Q
                ,xrscl.send_address3         -- �Z���R
                ,xrscl.bill_cust_code        -- �ڋq�R�[�h
                ,xrscl.bill_cust_name        -- �ڋq��
                ,xrscl.location_code         -- �S�����_�R�[�h
                ,xrscl.location_name         -- �S�����_��
                ,xrscl.phone_num             -- �d�b�ԍ�
                ,xrscl.target_date           -- �Ώ۔N��
                ,xrscl.payment_cust_code     -- ���|�Ǘ��R�[�h
                ,xrscl.payment_cust_name     -- ���|�Ǘ��ڋq��
                ,xrscl.ar_concat_text        -- ���|�Ǘ��R�[�h�A��������
                ,xrscl.payment_due_date      -- �����\���
                ,xrscl.bank_account          -- �U������
                ,xrscl.ship_cust_code        -- �[�i��ڋq�R�[�h
                ,xrscl.ship_cust_name        -- �[�i��ڋq��
                ,xrscl.store_code            -- �X�܃R�[�h
                ,xrscl.store_code_sort       -- �X�܃R�[�h�i�\�[�g�p�j
                ,xrscl.ship_account_number   -- �[�i��ڋq�R�[�h�i�\�[�g�p�j
                ,xrscl.outsourcing_flag      -- �Ǝ҈ϑ��t���O
                ,cn_created_by               -- �쐬��
                ,cd_creation_date            -- �쐬��
                ,cn_last_updated_by          -- �ŏI�X�V��
                ,cd_last_update_date         -- �ŏI�X�V��
                ,cn_last_update_login        -- �ŏI�X�V���O�C��
                ,cn_request_id               -- �v��ID
                ,cn_program_application_id   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                ,cn_program_id               -- �R���J�����g�E�v���O����ID
                ,cd_program_update_date      -- �v���O�����X�V��
        ;
--
        gn_target_cnt_c_h := SQL%ROWCOUNT;
--
      -- ����P�ʁFC�̌ڋq����A���Ώۃf�[�^���Ȃ��ꍇ
      ELSIF ( gv_target_c_flag = cv_taget_flag_1 ) THEN
        -- ���[�O�����b�Z�[�W��W���������ō����[�������P��C���[�N�e�[�u���w�b�_�ɓo�^
        INSERT INTO xxcfr_rep_st_inv_inc_tax_c_h (
          data_empty_message           , -- 0�����b�Z�[�W
          outsourcing_flag             , -- �Ǝ҈ϑ��t���O
          created_by                   , -- �쐬��
          creation_date                , -- �쐬��
          last_updated_by              , -- �ŏI�X�V��
          last_update_date             , -- �ŏI�X�V��
          last_update_login            , -- �ŏI�X�V���O�C��
          request_id                   , -- �v��ID
          program_application_id       , -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          program_id                   , -- �R���J�����g�E�v���O����ID
          program_update_date          ) -- �v���O�����X�V��
        VALUES (
          lv_no_data_msg               , -- 0�����b�Z�[�W
          CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
            cv_os_flag_y
          ELSE
            NULL
          END                          , -- �Ǝ҈ϑ��t���O
          cn_created_by                , -- �쐬��
          cd_creation_date             , -- �쐬��
          cn_last_updated_by           , -- �ŏI�X�V��
          cd_last_update_date          , -- �ŏI�X�V��
          cn_last_update_login         , -- �ŏI�X�V���O�C��
          cn_request_id                , -- �v��ID
          cn_program_application_id    , -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          cn_program_id                , -- �R���J�����g�E�v���O����ID
          cd_program_update_date       );-- �v���O�����X�V��
      END IF;
--
-- Add 2016.03.31 Ver1.90 End
-- Ver.1.92 [��QE_�{�ғ�_15307] ADD START
      -- ����P��D���ׂ̑Ώی�����0�ȊO�̏ꍇ
      IF ( gn_target_cnt_d_l <> 0 ) THEN
        -- ����0���t���O�i2�F�Ώۃf�[�^����j
        gv_target_d_flag := cv_taget_flag_2;
--
        -- �W�����������[�������P��D���[�N�e�[�u���w�b�_�̓o�^
        INSERT INTO xxcfr_rep_st_inv_d_h(
           report_id                -- ���[ID
          ,issue_date               -- ���s���t
          ,zip_code                 -- �X�֔ԍ�
          ,send_address1            -- �Z���P
          ,send_address2            -- �Z���Q
          ,send_address3            -- �Z���R
          ,bill_cust_code           -- �ڋq�R�[�h
          ,bill_cust_name           -- �ڋq��
          ,location_code            -- �S�����_�R�[�h
          ,location_name            -- �S�����_��
          ,phone_num                -- �d�b�ԍ�
          ,payment_cust_code        -- ���|�Ǘ��R�[�h
          ,payment_cust_name        -- ���|�Ǘ��ڋq��
          ,bank_account             -- �U���������
          ,outsourcing_flag         -- �Ǝ҈ϑ��t���O
          ,created_by               -- �쐬��
          ,creation_date            -- �쐬��
          ,last_updated_by          -- �ŏI�X�V��
          ,last_update_date         -- �ŏI�X�V��
          ,last_update_login        -- �ŏI�X�V���O�C��
          ,request_id               -- �v��ID
          ,program_application_id   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          ,program_id               -- �R���J�����g�E�v���O����ID
          ,program_update_date      -- �v���O�����X�V��
        )
        SELECT cv_report_id_13                                   -- ���[ID
              ,xrsdl.issue_date                                  -- ���s���t
              ,xrsdl.zip_code                                    -- �X�֔ԍ�
              ,xrsdl.send_address1                               -- �Z���P
              ,xrsdl.send_address2                               -- �Z���Q
              ,xrsdl.send_address3                               -- �Z���R
              ,xrsdl.bill_cust_code                              -- �ڋq�R�[�h
              ,xrsdl.bill_cust_name                              -- �ڋq��
              ,xrsdl.location_code                               -- �S�����_�R�[�h
              ,xrsdl.location_name                               -- �S�����_��
              ,xrsdl.phone_num                                   -- �d�b�ԍ�
              ,xrsdl.payment_cust_code                           -- ���|�Ǘ��R�[�h
              ,xrsdl.payment_cust_name                           -- ���|�Ǘ��ڋq��
              ,xrsdl.bank_account                                -- �U���������
              ,xrsdl.outsourcing_flag                            -- �Ǝ҈ϑ��t���O
              ,cn_created_by                                     -- �쐬��
              ,cd_creation_date                                  -- �쐬��
              ,cn_last_updated_by                                -- �ŏI�X�V��
              ,cd_last_update_date                               -- �ŏI�X�V��
              ,cn_last_update_login                              -- �ŏI�X�V���O�C��
              ,cn_request_id                                     -- �v��ID
              ,cn_program_application_id                         -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
              ,cn_program_id                                     -- �R���J�����g�E�v���O����ID
              ,cd_program_update_date                            -- �v���O�����X�V��
        FROM   xxcfr_rep_st_inv_inc_tax_d_l  xrsdl
        WHERE  xrsdl.request_id = cn_request_id
        GROUP BY cv_report_id_13             -- ���[ID
                ,xrsdl.issue_date            -- ���s���t
                ,xrsdl.zip_code              -- �X�֔ԍ�
                ,xrsdl.send_address1         -- �Z���P
                ,xrsdl.send_address2         -- �Z���Q
                ,xrsdl.send_address3         -- �Z���R
                ,xrsdl.bill_cust_code        -- �ڋq�R�[�h
                ,xrsdl.bill_cust_name        -- �ڋq��
                ,xrsdl.location_code         -- �S�����_�R�[�h
                ,xrsdl.location_name         -- �S�����_��
                ,xrsdl.phone_num             -- �d�b�ԍ�
                ,xrsdl.payment_cust_code     -- ���|�Ǘ��R�[�h
                ,xrsdl.payment_cust_name     -- ���|�Ǘ��ڋq��
                ,xrsdl.bank_account          -- �U���������
                ,xrsdl.outsourcing_flag      -- �Ǝ҈ϑ��t���O
                ,cn_created_by               -- �쐬��
                ,cd_creation_date            -- �쐬��
                ,cn_last_updated_by          -- �ŏI�X�V��
                ,cd_last_update_date         -- �ŏI�X�V��
                ,cn_last_update_login        -- �ŏI�X�V���O�C��
                ,cn_request_id               -- �v��ID
                ,cn_program_application_id   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                ,cn_program_id               -- �R���J�����g�E�v���O����ID
                ,cd_program_update_date      -- �v���O�����X�V��
        ;
--
        gn_target_cnt_d_h := SQL%ROWCOUNT;
--
      -- ����P�ʁFD�̌ڋq����A���Ώۃf�[�^���Ȃ��ꍇ
      ELSIF ( gv_target_d_flag = cv_taget_flag_1 ) THEN
        -- ���[�O�����b�Z�[�W��W�����������[�������P��D���[�N�e�[�u���w�b�_�ɓo�^
        INSERT INTO xxcfr_rep_st_inv_d_h (
          data_empty_message           , -- 0�����b�Z�[�W
          outsourcing_flag             , -- �Ǝ҈ϑ��t���O
          created_by                   , -- �쐬��
          creation_date                , -- �쐬��
          last_updated_by              , -- �ŏI�X�V��
          last_update_date             , -- �ŏI�X�V��
          last_update_login            , -- �ŏI�X�V���O�C��
          request_id                   , -- �v��ID
          program_application_id       , -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          program_id                   , -- �R���J�����g�E�v���O����ID
          program_update_date          ) -- �v���O�����X�V��
        VALUES (
          lv_no_data_msg               , -- 0�����b�Z�[�W
          CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
            cv_os_flag_y
          ELSE
            NULL
          END                          , -- �Ǝ҈ϑ��t���O
          cn_created_by                , -- �쐬��
          cd_creation_date             , -- �쐬��
          cn_last_updated_by           , -- �ŏI�X�V��
          cd_last_update_date          , -- �ŏI�X�V��
          cn_last_update_login         , -- �ŏI�X�V���O�C��
          cn_request_id                , -- �v��ID
          cn_program_application_id    , -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          cn_program_id                , -- �R���J�����g�E�v���O����ID
          cd_program_update_date       );-- �v���O�����X�V��
--
      END IF;
-- Ver.1.92 [��QE_�{�ғ�_15307] ADD END
-- Add 2013.12.13 Ver1.60 Start
-- Mod 2015.07.31 Ver1.80 Start
--      ELSE
      IF ( ( gn_target_cnt <> 0 )
        OR ( gv_target_a_flag = cv_taget_flag_2 )
-- Mod 2016.03.31 Ver1.90 Start
--        OR ( gv_target_b_flag = cv_taget_flag_2 ) ) THEN
        OR ( gv_target_b_flag = cv_taget_flag_2 )
-- Ver.1.92 [��QE_�{�ғ�_15307] MOD START
--        OR ( gv_target_c_flag = cv_taget_flag_2 ) ) THEN
        OR ( gv_target_c_flag = cv_taget_flag_2 )
        OR ( gv_target_d_flag = cv_taget_flag_2 ) ) THEN
-- Ver.1.92 [��QE_�{�ғ�_15307] MOD END
-- Mod 2016.03.31 Ver1.90 End
-- Mod 2015.07.31 Ver1.80 End
-- Mod 2016.09.06 Ver1.91 Start
--        --�ŕʓ���o�͂���̏ꍇ�A�ŕʂ̋��z��ҏW����
--        IF ( iv_tax_output_type = cv_tax_op_type_yes ) THEN
--          -- =====================================================
--          --  ���[�N�e�[�u���f�[�^�X�V  (A-11)
--          -- =====================================================
--          update_work_table(
--             lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
--            ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
--            ,lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--          );
--          IF (lv_retcode = cv_status_error) THEN
--            --(�G���[����)
--            RAISE update_work_expt;
--          END IF;
--        END IF;
        -- =====================================================
        --  ���[�N�e�[�u���f�[�^�X�V  (A-11)
        -- =====================================================
        update_work_table(
           iv_tax_output_type    -- �ŕʓ���o�͋敪
          ,lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
          ,lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode = cv_status_error) THEN
          --(�G���[����)
          RAISE update_work_expt;
        END IF;
-- Mod 2016.09.06 Ver1.91 End
-- Add 2013.12.13 Ver1.60 End
      END IF;
--
    EXCEPTION
-- Ver.1.92 [��QE_�{�ғ�_15307] ADD START
      WHEN global_api_expt THEN
        RAISE global_api_expt;
-- Ver.1.92 [��QE_�{�ғ�_15307] ADD END
-- Add 2013.12.13 Ver1.60 Start
      --���[�N�X�V��O
      WHEN update_work_expt THEN
        RAISE global_api_expt;
-- Add 2013.12.13 Ver1.60 End
      WHEN OTHERS THEN  -- �o�^���G���[
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                       ,cv_msg_003a18_013    -- �e�[�u���o�^�G���[
                                                       ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                       ,xxcfr_common_pkg.get_table_comment(cv_table))
                                                      -- �W���������Ŕ����[���[�N�e�[�u��
                             ,1
                             ,5000);
        lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
        RAISE global_api_expt;
    END;
--
    -- ���������̐ݒ�
    gn_normal_cnt := gn_target_cnt;
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
  END insert_work_table;
--
  /**********************************************************************************
   * Procedure Name   : chk_account_data
   * Description      : �������擾�`�F�b�N (A-7)
   ***********************************************************************************/
  PROCEDURE chk_account_data(
    ov_errbuf               OUT  VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT  VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT  VARCHAR2)            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_account_data'; -- �v���O������
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
    ln_target_cnt    NUMBER;         -- �Ώی���
    ln_loop_cnt      NUMBER;         -- ���[�v�J�E���^
    lv_warn_msg      VARCHAR2(5000);
    lv_bill_data_msg VARCHAR2(5000);
    lv_warn_bill_num VARCHAR2(5000);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- ���o
    CURSOR sel_no_account_data_cur
    IS
      SELECT xrsi.payment_cust_code  lv_payment_cust_code ,
             xrsi.payment_cust_name  lv_payment_cust_name ,
             xrsi.location_name      lv_location_name
      FROM xxcfr_rep_st_invoice_inc_tax_d  xrsi
      WHERE xrsi.request_id  = cn_request_id  -- �v��ID
-- Mod 2015.07.31 Ver1.80 Start
--        AND bank_account IS NULL
        AND xrsi.bank_account       IS NULL           -- �U������
        AND xrsi.data_empty_message IS NULL           -- 0�����b�Z�[�W
-- Mod 2015.07.31 Ver1.80 End
      GROUP BY xrsi.payment_cust_code ,
               xrsi.payment_cust_name,
               xrsi.location_name
-- Add 2015.07.31 Ver1.80 Start
      UNION ALL
      SELECT xrsia.payment_cust_code  lv_payment_cust_code ,
             xrsia.payment_cust_name  lv_payment_cust_name ,
             xrsia.location_name      lv_location_name
      FROM xxcfr_rep_st_inv_inc_tax_a_h  xrsia
      WHERE xrsia.request_id         = cn_request_id  -- �v��ID
        AND xrsia.bank_account       IS NULL          -- �U������
        AND xrsia.data_empty_message IS NULL          -- 0�����b�Z�[�W
      GROUP BY xrsia.payment_cust_code ,
               xrsia.payment_cust_name,
               xrsia.location_name
      UNION ALL
      SELECT xrsib.payment_cust_code  lv_payment_cust_code ,
             xrsib.payment_cust_name  lv_payment_cust_name ,
             xrsib.location_name      lv_location_name
      FROM xxcfr_rep_st_inv_inc_tax_b_h  xrsib
      WHERE xrsib.request_id         = cn_request_id  -- �v��ID
        AND xrsib.bank_account       IS NULL          -- �U������
        AND xrsib.data_empty_message IS NULL          -- 0�����b�Z�[�W
      GROUP BY xrsib.payment_cust_code ,
               xrsib.payment_cust_name,
               xrsib.location_name
-- Add 2015.07.31 Ver1.80 End
-- Add 2016.03.31 Ver1.90 Start
      UNION ALL
      SELECT xrsic.payment_cust_code  lv_payment_cust_code ,
             xrsic.payment_cust_name  lv_payment_cust_name ,
             xrsic.location_name      lv_location_name
      FROM xxcfr_rep_st_inv_inc_tax_c_h  xrsic
      WHERE xrsic.request_id         = cn_request_id  -- �v��ID
        AND xrsic.bank_account       IS NULL          -- �U������
        AND xrsic.data_empty_message IS NULL          -- 0�����b�Z�[�W
      GROUP BY xrsic.payment_cust_code ,
               xrsic.payment_cust_name,
               xrsic.location_name
-- Add 2016.03.31 Ver1.90 End
-- Ver.1.92 [��QE_�{�ғ�_15307] ADD START
      UNION ALL
      SELECT xrsid.payment_cust_code  lv_payment_cust_code ,
             xrsid.payment_cust_name  lv_payment_cust_name ,
             xrsid.location_name      lv_location_name
      FROM xxcfr_rep_st_inv_d_h  xrsid
      WHERE xrsid.request_id         = cn_request_id  -- �v��ID
        AND xrsid.bank_account       IS NULL          -- �U������
        AND xrsid.data_empty_message IS NULL          -- 0�����b�Z�[�W
      GROUP BY xrsid.payment_cust_code ,
               xrsid.payment_cust_name,
               xrsid.location_name
-- Ver.1.92 [��QE_�{�ғ�_15307] ADD END
-- Mod 2015.07.31 Ver1.80 Start
--      ORDER BY xrsi.payment_cust_code ASC;
      ORDER BY lv_payment_cust_code ASC;
-- Mod 2015.07.31 Ver1.80 End
--
    TYPE g_sel_no_account_data_ttype IS TABLE OF sel_no_account_data_cur%ROWTYPE INDEX BY PLS_INTEGER;
    lt_sel_no_account_tab    g_sel_no_account_data_ttype;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���������s�Ώۃf�[�^�����݂���ꍇ�ȉ��̏��������s
-- Mod 2015.07.31 Ver1.80 Start
--    IF ( gn_target_cnt > 0 ) THEN
    IF ( ( gn_target_cnt > 0 ) 
      OR ( gn_target_cnt_a_h > 0 )
-- Mod 2016.03.31 Ver1.90 Start
--      OR ( gn_target_cnt_b_h > 0 ) ) THEN
      OR ( gn_target_cnt_b_h > 0 )
-- Ver.1.92 [��QE_�{�ғ�_15307] MOD START
--      OR ( gn_target_cnt_c_h > 0 ) ) THEN
      OR ( gn_target_cnt_c_h > 0 )
      OR ( gn_target_cnt_d_h > 0 ) ) THEN
-- Ver.1.92 [��QE_�{�ғ�_15307] MOD END
-- Mod 2016.03.31 Ver1.90 End
-- Mod 2015.07.31 Ver1.80 End
--
      -- �J�[�\���I�[�v��
      OPEN sel_no_account_data_cur;
--
      -- �f�[�^�̈ꊇ�擾
      FETCH sel_no_account_data_cur BULK COLLECT INTO lt_sel_no_account_tab;
--
      -- ���������̃Z�b�g
      ln_target_cnt := lt_sel_no_account_tab.COUNT;
--
      -- �J�[�\���N���[�Y
      CLOSE sel_no_account_data_cur;
--
      -- �Ώۃf�[�^�����݂���ꍇ���O�ɏo�͂���
      IF (ln_target_cnt > 0) THEN
--
        -- �U���������o�^���b�Z�[�W�o��
        lv_warn_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cfr
                        ,iv_name         => cv_msg_003a18_018);
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => lv_warn_msg
        );
        -- �ڋq�R�[�h�E�ڋq�����b�Z�[�W�o��
        BEGIN
          <<data_loop>>
          FOR ln_loop_cnt IN 1..ln_target_cnt LOOP
            lv_bill_data_msg := xxccp_common_pkg.get_msg(
                                   iv_application  => cv_msg_kbn_cfr
                                  ,iv_name         => cv_msg_003a18_019
                                  ,iv_token_name1  => cv_tkn_ac_code
                                  ,iv_token_value1 => lt_sel_no_account_tab(ln_loop_cnt).lv_payment_cust_code
                                  ,iv_token_name2  => cv_tkn_ac_name
                                  ,iv_token_value2 => lt_sel_no_account_tab(ln_loop_cnt).lv_payment_cust_name);
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => lv_bill_data_msg --�G���[���b�Z�[�W
            );
          END LOOP data_loop;
        END;
        -- �ڋq�R�[�h�̌��������b�Z�[�W�o��
        lv_warn_bill_num := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cfr
                        ,iv_name         => cv_msg_003a18_020
                        ,iv_token_name1  => cv_tkn_count
                        ,iv_token_value1 => TO_CHAR(ln_target_cnt)
                       );
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => lv_warn_bill_num
        );
--
        --�P�s���s
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => '' --���[�U�[�E�G���[���b�Z�[�W
        );
--
        -- �x���I��
        ov_retcode := cv_status_warn;
--
      END IF;
    END IF;
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
  END chk_account_data;
--
  /**********************************************************************************
   * Procedure Name   : start_svf_api
   * Description      : SVF�N�� (A-8)
   ***********************************************************************************/
  PROCEDURE start_svf_api(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'start_svf_api'; -- �v���O������
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
    cv_svf_form_name  CONSTANT  VARCHAR2(20) := 'XXCFR003A18S.xml';  -- �t�H�[���l���t�@�C����
    cv_svf_query_name CONSTANT  VARCHAR2(20) := 'XXCFR003A18S.vrq';  -- �N�G���[�l���t�@�C����
    cv_output_mode    CONSTANT  VARCHAR2(1)   := '1';                -- �o�͋敪(=1�FPDF�o�́j
    cv_extension_pdf  CONSTANT  VARCHAR2(4)  := '.pdf';              -- �g���q�ipdf�j
--
    -- *** ���[�J���ϐ� ***
    lv_no_data_msg     VARCHAR2(5000);  -- ���[�O�����b�Z�[�W
    lv_svf_file_name   VARCHAR2(100);
    lv_file_id         VARCHAR2(30)  := NULL;
    lv_conc_name       VARCHAR2(30)  := NULL;
    lv_user_name       VARCHAR2(240) := NULL;
    lv_resp_name       VARCHAR2(240) := NULL;
    lv_svf_errmsg      VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =====================================================
    --  SVF�N�� (A-4)
    -- =====================================================
--
    -- �t�@�C�����̐ݒ�
    lv_svf_file_name := cv_pkg_name
                     || TO_CHAR ( cd_creation_date, cv_format_date_ymd )
                     || TO_CHAR ( cn_request_id )
                     || cv_extension_pdf;
--
    -- �R���J�����g���̐ݒ�
      lv_conc_name := cv_pkg_name;
--
    -- �t�@�C��ID�̐ݒ�
      lv_file_id := cv_pkg_name;
--
    xxccp_svfcommon_pkg.submit_svf_request(
       ov_errbuf       => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_svf_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ,iv_conc_name    => lv_conc_name          -- �R���J�����g��
      ,iv_file_name    => lv_svf_file_name      -- �o�̓t�@�C����
      ,iv_file_id      => lv_file_id            -- ���[ID
      ,iv_output_mode  => cv_output_mode        -- �o�͋敪(=1�FPDF�o�́j
      ,iv_frm_file     => cv_svf_form_name      -- �t�H�[���l���t�@�C����
      ,iv_vrq_file     => cv_svf_query_name     -- �N�G���[�l���t�@�C����
      ,iv_org_id       => gn_org_id             -- ORG_ID
      ,iv_user_name    => lv_user_name          -- ���O�C���E���[�U��
      ,iv_resp_name    => lv_resp_name          -- ���O�C���E���[�U�̐E�Ӗ�
      ,iv_doc_name     => NULL                  -- ������
      ,iv_printer_name => NULL                  -- �v�����^��
      ,iv_request_id   => cn_request_id         -- �v��ID
      ,iv_nodata_msg   => NULL                  -- �f�[�^�Ȃ����b�Z�[�W
    );
--
    -- SVF�N��API�̌Ăяo���̓G���[��
    IF (lv_retcode = cv_status_error) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                     ,cv_msg_003a18_015    -- API�G���[
                                                     ,cv_tkn_api           -- �g�[�N��'API_NAME'
                                                     ,xxcfr_common_pkg.lookup_dictionary(
                                                        cv_msg_kbn_cfr
                                                       ,cv_dict_svf 
                                                      )  -- SVF�N��
                                                    )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg ||cv_msg_part|| lv_errbuf ||cv_msg_part|| lv_svf_errmsg;
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
  END start_svf_api;
--
  /**********************************************************************************
   * Procedure Name   : delete_work_table
   * Description      : ���[�N�e�[�u���f�[�^�폜 (A-9)
   ***********************************************************************************/
  PROCEDURE delete_work_table(
    ov_errbuf               OUT  VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT  VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT  VARCHAR2)            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_work_table'; -- �v���O������
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
    ln_target_cnt   NUMBER;         -- �Ώی���
    ln_loop_cnt     NUMBER;         -- ���[�v�J�E���^
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- ���o
    CURSOR del_rep_st_inv_ex_cur
    IS
      SELECT xrsi.rowid        ln_rowid
      FROM xxcfr_rep_st_invoice_inc_tax_d xrsi -- �W���������Ŕ����[���[�N�e�[�u��
      WHERE xrsi.request_id = cn_request_id  -- �v��ID
      FOR UPDATE NOWAIT;
--
    TYPE g_del_rep_st_inv_ex_ttype IS TABLE OF ROWID INDEX BY PLS_INTEGER;
    lt_del_rep_st_inv_ex_data    g_del_rep_st_inv_ex_ttype;
--
-- Add 2015.07.31 Ver1.80 Start
    -- �W���������ō����[�������P��A���[�N�e�[�u���w�b�_���o
    CURSOR del_rep_st_inv_inc_a_h_cur
    IS
      SELECT xrsiah.rowid        ln_rowid
      FROM xxcfr_rep_st_inv_inc_tax_a_h xrsiah  -- �W���������ō����[�������P��A���[�N�e�[�u���w�b�_
      WHERE xrsiah.request_id = cn_request_id  -- �v��ID
      FOR UPDATE NOWAIT;
--
    TYPE g_del_rep_st_inv_inc_a_h_ttype IS TABLE OF ROWID INDEX BY PLS_INTEGER;
    lt_del_rep_st_inv_inc_a_h_data    g_del_rep_st_inv_inc_a_h_ttype;
--
    -- �W���������ō����[�������P��A���[�N�e�[�u�����ג��o
    CURSOR del_rep_st_inv_inc_a_l_cur
    IS
      SELECT xrsial.rowid        ln_rowid
      FROM xxcfr_rep_st_inv_inc_tax_a_l xrsial  -- �W���������ō����[�������P��A���[�N�e�[�u������
      WHERE xrsial.request_id = cn_request_id  -- �v��ID
      FOR UPDATE NOWAIT;
--
    TYPE g_del_rep_st_inv_inc_a_l_ttype IS TABLE OF ROWID INDEX BY PLS_INTEGER;
    lt_del_rep_st_inv_inc_a_l_data    g_del_rep_st_inv_inc_a_l_ttype;
--
    -- �W���������ō����[�������P��B���[�N�e�[�u���w�b�_���o
    CURSOR del_rep_st_inv_inc_b_h_cur
    IS
      SELECT xrsibh.rowid        ln_rowid
      FROM xxcfr_rep_st_inv_inc_tax_b_h xrsibh  -- �W���������ō����[�������P��B���[�N�e�[�u���w�b�_
      WHERE xrsibh.request_id = cn_request_id  -- �v��ID
      FOR UPDATE NOWAIT;
--
    TYPE g_del_rep_st_inv_inc_b_h_ttype IS TABLE OF ROWID INDEX BY PLS_INTEGER;
    lt_del_rep_st_inv_inc_b_h_data    g_del_rep_st_inv_inc_b_h_ttype;
--
    -- �W���������ō����[�������P��B���[�N�e�[�u�����ג��o
    CURSOR del_rep_st_inv_inc_b_l_cur
    IS
      SELECT xrsibl.rowid        ln_rowid
      FROM xxcfr_rep_st_inv_inc_tax_b_l xrsibl  -- �W���������ō����[�������P��B���[�N�e�[�u������
      WHERE xrsibl.request_id = cn_request_id  -- �v��ID
      FOR UPDATE NOWAIT;
--
    TYPE g_del_rep_st_inv_inc_b_l_ttype IS TABLE OF ROWID INDEX BY PLS_INTEGER;
    lt_del_rep_st_inv_inc_b_l_data    g_del_rep_st_inv_inc_b_l_ttype;
--
-- Add 2015.07.31 Ver1.80 End
-- Add 2016.03.31 Ver1.90 Start
    -- �W���������ō����[�������P��C���[�N�e�[�u���w�b�_���o
    CURSOR del_rep_st_inv_inc_c_h_cur
    IS
      SELECT xrsich.rowid        ln_rowid
      FROM xxcfr_rep_st_inv_inc_tax_c_h xrsich  -- �W���������ō����[�������P��C���[�N�e�[�u���w�b�_
      WHERE xrsich.request_id = cn_request_id  -- �v��ID
      FOR UPDATE NOWAIT;
--
    TYPE g_del_rep_st_inv_inc_c_h_ttype IS TABLE OF ROWID INDEX BY PLS_INTEGER;
    lt_del_rep_st_inv_inc_c_h_data    g_del_rep_st_inv_inc_c_h_ttype;
--
    -- �W���������ō����[�������P��C���[�N�e�[�u�����ג��o
    CURSOR del_rep_st_inv_inc_c_l_cur
    IS
      SELECT xrsicl.rowid        ln_rowid
      FROM xxcfr_rep_st_inv_inc_tax_c_l xrsicl  -- �W���������ō����[�������P��C���[�N�e�[�u������
      WHERE xrsicl.request_id = cn_request_id  -- �v��ID
      FOR UPDATE NOWAIT;
--
    TYPE g_del_rep_st_inv_inc_c_l_ttype IS TABLE OF ROWID INDEX BY PLS_INTEGER;
    lt_del_rep_st_inv_inc_c_l_data    g_del_rep_st_inv_inc_c_l_ttype;
--
-- Add 2016.03.31 Ver1.90 End
-- Ver.1.92 [��QE_�{�ғ�_15307] ADD START
    -- �W�����������[�������P��D���[�N�e�[�u���w�b�_���o
    CURSOR del_rep_st_inv_d_h_cur
    IS
      SELECT xrsidh.rowid        ln_rowid
      FROM xxcfr_rep_st_inv_d_h xrsidh  -- �W�����������[�������P��D���[�N�e�[�u���w�b�_
      WHERE xrsidh.request_id = cn_request_id  -- �v��ID
      FOR UPDATE NOWAIT;
--
    TYPE g_del_rep_st_inv_d_h_ttype IS TABLE OF ROWID INDEX BY PLS_INTEGER;
    lt_del_rep_st_inv_d_h_data        g_del_rep_st_inv_d_h_ttype;
--
    -- �W���������ō����[�������P��D���[�N�e�[�u�����ג��o
    CURSOR del_rep_st_inv_inc_d_l_cur
    IS
      SELECT xrsidl.rowid        ln_rowid
      FROM xxcfr_rep_st_inv_inc_tax_d_l xrsidl  -- �W���������ō����[�������P��D���[�N�e�[�u������
      WHERE xrsidl.request_id = cn_request_id  -- �v��ID
      FOR UPDATE NOWAIT;
--
    TYPE g_del_rep_st_inv_inc_d_l_ttype IS TABLE OF ROWID INDEX BY PLS_INTEGER;
    lt_del_rep_st_inv_inc_d_l_data    g_del_rep_st_inv_inc_d_l_ttype;
--
-- Ver.1.92 [��QE_�{�ғ�_15307] ADD END
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
-- Mod 2015.07.31 Ver1.80 Start
--    -- �J�[�\���I�[�v��
--    OPEN del_rep_st_inv_ex_cur;
----
--    -- �f�[�^�̈ꊇ�擾
--    FETCH del_rep_st_inv_ex_cur BULK COLLECT INTO lt_del_rep_st_inv_ex_data;
----
--    -- ���������̃Z�b�g
--    ln_target_cnt := lt_del_rep_st_inv_ex_data.COUNT;
----
--    -- �J�[�\���N���[�Y
--    CLOSE del_rep_st_inv_ex_cur;
----
--    -- �Ώۃf�[�^�����݂���ꍇ���R�[�h���폜����
--    IF (ln_target_cnt > 0) THEN
--      BEGIN
--        <<data_loop>>
--        FORALL ln_loop_cnt IN 1..ln_target_cnt
--          DELETE FROM xxcfr_rep_st_invoice_inc_tax_d
--          WHERE ROWID = lt_del_rep_st_inv_ex_data(ln_loop_cnt);
----
--        -- �R�~�b�g���s
--        COMMIT;
----
--      EXCEPTION
--        WHEN OTHERS THEN
--          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
--                                                        ,cv_msg_003a18_012 -- �f�[�^�폜�G���[
--                                                        ,cv_tkn_table         -- �g�[�N��'TABLE'
--                                                        ,xxcfr_common_pkg.get_table_comment(cv_table))
--                                                        -- �W���������Ŕ����[���[�N�e�[�u��
--                              ,1
--                              ,5000);
--          lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
--          RAISE global_api_expt;
--      END;
----
--    END IF;
--  EXCEPTION
--    WHEN lock_expt THEN  -- �e�[�u�����b�N�ł��Ȃ�����
--      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
--                                                     ,cv_msg_003a18_011    -- �e�[�u�����b�N�G���[
--                                                     ,cv_tkn_table         -- �g�[�N��'TABLE'
--                                                     ,xxcfr_common_pkg.get_table_comment(cv_table))
--                                                    -- �W���������Ŕ����[���[�N�e�[�u��
--                           ,1
--                           ,5000);
--      lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
    -- �@�W���������ō����[���[�N�e�[�u���폜����
    BEGIN
      -- �J�[�\���I�[�v��
      OPEN del_rep_st_inv_ex_cur;
--
      -- �f�[�^�̈ꊇ�擾
      FETCH del_rep_st_inv_ex_cur BULK COLLECT INTO lt_del_rep_st_inv_ex_data;
--
      -- ���������̃Z�b�g
      ln_target_cnt := lt_del_rep_st_inv_ex_data.COUNT;
--
      -- �J�[�\���N���[�Y
      CLOSE del_rep_st_inv_ex_cur;
--
      -- �Ώۃf�[�^�����݂���ꍇ���R�[�h���폜����
      IF (ln_target_cnt > 0) THEN
        BEGIN
          <<data_loop>>
          FORALL ln_loop_cnt IN 1..ln_target_cnt
            DELETE FROM xxcfr_rep_st_invoice_inc_tax_d rep
            WHERE rep.rowid = lt_del_rep_st_inv_ex_data(ln_loop_cnt);
--
          -- �R�~�b�g���s
          COMMIT;
--
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                          ,cv_msg_003a18_012 -- �f�[�^�폜�G���[
                                                          ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                          ,xxcfr_common_pkg.get_table_comment(cv_table))
                                                          -- �W���������ō����[���[�N�e�[�u��
                                ,1
                                ,5000);
            lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
            RAISE global_api_expt;
        END;
--
      END IF;
--
    EXCEPTION
      WHEN lock_expt THEN  -- �e�[�u�����b�N�ł��Ȃ�����
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                       ,cv_msg_003a18_011    -- �e�[�u�����b�N�G���[
                                                       ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                       ,xxcfr_common_pkg.get_table_comment(cv_table))
                                                      -- �W���������ō����[���[�N�e�[�u��
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
    END;
--
    -- �A�W���������ō����[�������P��A���[�N�e�[�u���w�b�_�폜����
    BEGIN
      -- �J�[�\���I�[�v��
      OPEN del_rep_st_inv_inc_a_h_cur;
--
      -- �f�[�^�̈ꊇ�擾
      FETCH del_rep_st_inv_inc_a_h_cur BULK COLLECT INTO lt_del_rep_st_inv_inc_a_h_data;
--
      -- ���������̃Z�b�g
      ln_target_cnt := lt_del_rep_st_inv_inc_a_h_data.COUNT;
--
      -- �J�[�\���N���[�Y
      CLOSE del_rep_st_inv_inc_a_h_cur;
--
      -- �Ώۃf�[�^�����݂���ꍇ���R�[�h���폜����
      IF (ln_target_cnt > 0) THEN
        BEGIN
          <<data_loop>>
          FORALL ln_loop_cnt IN 1..ln_target_cnt
            DELETE FROM xxcfr_rep_st_inv_inc_tax_a_h rep
            WHERE rep.rowid = lt_del_rep_st_inv_inc_a_h_data(ln_loop_cnt);
--
          -- �R�~�b�g���s
          COMMIT;
--
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr       -- 'XXCFR'
                                                          ,cv_msg_003a18_012    -- �f�[�^�폜�G���[
                                                          ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                          ,xxcfr_common_pkg.get_table_comment(cv_table_a_h))
                                                          -- �W���������ō����[�������P��A���[�N�e�[�u���w�b�_
                                ,1
                                ,5000);
            lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
            RAISE global_api_expt;
        END;
--
      END IF;
--
    EXCEPTION
      WHEN lock_expt THEN  -- �e�[�u�����b�N�ł��Ȃ�����
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                       ,cv_msg_003a18_011    -- �e�[�u�����b�N�G���[
                                                       ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                       ,xxcfr_common_pkg.get_table_comment(cv_table_a_h))
                                                      -- �W���������ō����[�������P��A���[�N�e�[�u���w�b�_
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
    END;
--
    -- �B�W���������ō����[�������P��A���[�N�e�[�u�����׍폜����
    BEGIN
      -- �J�[�\���I�[�v��
      OPEN del_rep_st_inv_inc_a_l_cur;
--
      -- �f�[�^�̈ꊇ�擾
      FETCH del_rep_st_inv_inc_a_l_cur BULK COLLECT INTO lt_del_rep_st_inv_inc_a_l_data;
--
      -- ���������̃Z�b�g
      ln_target_cnt := lt_del_rep_st_inv_inc_a_l_data.COUNT;
--
      -- �J�[�\���N���[�Y
      CLOSE del_rep_st_inv_inc_a_l_cur;
--
      -- �Ώۃf�[�^�����݂���ꍇ���R�[�h���폜����
      IF (ln_target_cnt > 0) THEN
        BEGIN
          <<data_loop>>
          FORALL ln_loop_cnt IN 1..ln_target_cnt
            DELETE FROM xxcfr_rep_st_inv_inc_tax_a_l rep
            WHERE rep.rowid = lt_del_rep_st_inv_inc_a_l_data(ln_loop_cnt);
--
          -- �R�~�b�g���s
          COMMIT;
--
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr       -- 'XXCFR'
                                                          ,cv_msg_003a18_012    -- �f�[�^�폜�G���[
                                                          ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                          ,xxcfr_common_pkg.get_table_comment(cv_table_a_l))
                                                          -- �W���������ō����[�������P��A���[�N�e�[�u������
                                ,1
                                ,5000);
            lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
            RAISE global_api_expt;
        END;
--
      END IF;
--
    EXCEPTION
      WHEN lock_expt THEN  -- �e�[�u�����b�N�ł��Ȃ�����
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                       ,cv_msg_003a18_011    -- �e�[�u�����b�N�G���[
                                                       ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                       ,xxcfr_common_pkg.get_table_comment(cv_table_a_l))
                                                      -- �W���������ō����[�������P��A���[�N�e�[�u������
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
    END;
--
    -- �C�W���������ō����[�������P��B���[�N�e�[�u���w�b�_�폜����
    BEGIN
      -- �J�[�\���I�[�v��
      OPEN del_rep_st_inv_inc_b_h_cur;
--
      -- �f�[�^�̈ꊇ�擾
      FETCH del_rep_st_inv_inc_b_h_cur BULK COLLECT INTO lt_del_rep_st_inv_inc_b_h_data;
--
      -- ���������̃Z�b�g
      ln_target_cnt := lt_del_rep_st_inv_inc_b_h_data.COUNT;
--
      -- �J�[�\���N���[�Y
      CLOSE del_rep_st_inv_inc_b_h_cur;
--
      -- �Ώۃf�[�^�����݂���ꍇ���R�[�h���폜����
      IF (ln_target_cnt > 0) THEN
        BEGIN
          <<data_loop>>
          FORALL ln_loop_cnt IN 1..ln_target_cnt
            DELETE FROM xxcfr_rep_st_inv_inc_tax_b_h rep
            WHERE rep.rowid = lt_del_rep_st_inv_inc_b_h_data(ln_loop_cnt);
--
          -- �R�~�b�g���s
          COMMIT;
--
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr       -- 'XXCFR'
                                                          ,cv_msg_003a18_012    -- �f�[�^�폜�G���[
                                                          ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                          ,xxcfr_common_pkg.get_table_comment(cv_table_b_h))
                                                          -- �W���������ō����[�������P��B���[�N�e�[�u���w�b�_
                                ,1
                                ,5000);
            lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
            RAISE global_api_expt;
        END;
--
      END IF;
--
    EXCEPTION
      WHEN lock_expt THEN  -- �e�[�u�����b�N�ł��Ȃ�����
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                       ,cv_msg_003a18_011    -- �e�[�u�����b�N�G���[
                                                       ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                       ,xxcfr_common_pkg.get_table_comment(cv_table_b_h))
                                                      -- �W���������ō����[�������P��B���[�N�e�[�u���w�b�_
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
    END;
--
    -- �D�W���������ō����[�������P��B���[�N�e�[�u�����׍폜����
    BEGIN
      -- �J�[�\���I�[�v��
      OPEN del_rep_st_inv_inc_b_l_cur;
--
      -- �f�[�^�̈ꊇ�擾
      FETCH del_rep_st_inv_inc_b_l_cur BULK COLLECT INTO lt_del_rep_st_inv_inc_b_l_data;
--
      -- ���������̃Z�b�g
      ln_target_cnt := lt_del_rep_st_inv_inc_b_l_data.COUNT;
--
      -- �J�[�\���N���[�Y
      CLOSE del_rep_st_inv_inc_b_l_cur;
--
      -- �Ώۃf�[�^�����݂���ꍇ���R�[�h���폜����
      IF (ln_target_cnt > 0) THEN
        BEGIN
          <<data_loop>>
          FORALL ln_loop_cnt IN 1..ln_target_cnt
            DELETE FROM xxcfr_rep_st_inv_inc_tax_b_l rep
            WHERE rep.rowid = lt_del_rep_st_inv_inc_b_l_data(ln_loop_cnt);
--
          -- �R�~�b�g���s
          COMMIT;
--
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                          ,cv_msg_003a18_012 -- �f�[�^�폜�G���[
                                                          ,cv_tkn_table      -- �g�[�N��'TABLE'
                                                          ,xxcfr_common_pkg.get_table_comment(cv_table_b_l))
                                                          -- �W���������ō����[�������P��B���[�N�e�[�u������
                                ,1
                                ,5000);
            lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
            RAISE global_api_expt;
        END;
--
      END IF;
--
    EXCEPTION
      WHEN lock_expt THEN  -- �e�[�u�����b�N�ł��Ȃ�����
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                       ,cv_msg_003a18_011    -- �e�[�u�����b�N�G���[
                                                       ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                       ,xxcfr_common_pkg.get_table_comment(cv_table_b_l))
                                                      -- �W���������ō����[�������P��B���[�N�e�[�u������
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
    END;
--
-- Add 2016.03.31 Ver1.90 Start
    -- �E�W���������ō����[�������P��C���[�N�e�[�u���w�b�_�폜����
    BEGIN
      -- �J�[�\���I�[�v��
      OPEN del_rep_st_inv_inc_c_h_cur;
--
      -- �f�[�^�̈ꊇ�擾
      FETCH del_rep_st_inv_inc_c_h_cur BULK COLLECT INTO lt_del_rep_st_inv_inc_c_h_data;
--
      -- ���������̃Z�b�g
      ln_target_cnt := lt_del_rep_st_inv_inc_c_h_data.COUNT;
--
      -- �J�[�\���N���[�Y
      CLOSE del_rep_st_inv_inc_c_h_cur;
--
      -- �Ώۃf�[�^�����݂���ꍇ���R�[�h���폜����
      IF (ln_target_cnt > 0) THEN
        BEGIN
          <<data_loop>>
          FORALL ln_loop_cnt IN 1..ln_target_cnt
            DELETE FROM xxcfr_rep_st_inv_inc_tax_c_h rep
            WHERE rep.rowid = lt_del_rep_st_inv_inc_c_h_data(ln_loop_cnt);
--
          -- �R�~�b�g���s
          COMMIT;
--
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr       -- 'XXCFR'
                                                          ,cv_msg_003a18_012    -- �f�[�^�폜�G���[
                                                          ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                          ,xxcfr_common_pkg.get_table_comment(cv_table_c_h))
                                                          -- �W���������ō����[�������P��C���[�N�e�[�u���w�b�_
                                ,1
                                ,5000);
            lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
            RAISE global_api_expt;
        END;
--
      END IF;
--
    EXCEPTION
      WHEN lock_expt THEN  -- �e�[�u�����b�N�ł��Ȃ�����
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                       ,cv_msg_003a18_011    -- �e�[�u�����b�N�G���[
                                                       ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                       ,xxcfr_common_pkg.get_table_comment(cv_table_c_h))
                                                      -- �W���������ō����[�������P��C���[�N�e�[�u���w�b�_
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
    END;
--
    -- �F�W���������ō����[�������P��C���[�N�e�[�u�����׍폜����
    BEGIN
      -- �J�[�\���I�[�v��
      OPEN del_rep_st_inv_inc_c_l_cur;
--
      -- �f�[�^�̈ꊇ�擾
      FETCH del_rep_st_inv_inc_c_l_cur BULK COLLECT INTO lt_del_rep_st_inv_inc_c_l_data;
--
      -- ���������̃Z�b�g
      ln_target_cnt := lt_del_rep_st_inv_inc_c_l_data.COUNT;
--
      -- �J�[�\���N���[�Y
      CLOSE del_rep_st_inv_inc_c_l_cur;
--
      -- �Ώۃf�[�^�����݂���ꍇ���R�[�h���폜����
      IF (ln_target_cnt > 0) THEN
        BEGIN
          <<data_loop>>
          FORALL ln_loop_cnt IN 1..ln_target_cnt
            DELETE FROM xxcfr_rep_st_inv_inc_tax_c_l rep
            WHERE rep.rowid = lt_del_rep_st_inv_inc_c_l_data(ln_loop_cnt);
--
          -- �R�~�b�g���s
          COMMIT;
--
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                          ,cv_msg_003a18_012 -- �f�[�^�폜�G���[
                                                          ,cv_tkn_table      -- �g�[�N��'TABLE'
                                                          ,xxcfr_common_pkg.get_table_comment(cv_table_c_l))
                                                          -- �W���������ō����[�������P��C���[�N�e�[�u������
                                ,1
                                ,5000);
            lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
            RAISE global_api_expt;
        END;
--
      END IF;
--
    EXCEPTION
      WHEN lock_expt THEN  -- �e�[�u�����b�N�ł��Ȃ�����
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                       ,cv_msg_003a18_011    -- �e�[�u�����b�N�G���[
                                                       ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                       ,xxcfr_common_pkg.get_table_comment(cv_table_c_l))
                                                      -- �W���������ō����[�������P��C���[�N�e�[�u������
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
    END;
--
-- Add 2016.03.31 Ver1.90 End
-- Ver.1.92 [��QE_�{�ғ�_15307] ADD START
    -- �G�W�����������[�������P��D���[�N�e�[�u���w�b�_�폜����
    BEGIN
      -- �J�[�\���I�[�v��
      OPEN del_rep_st_inv_d_h_cur;
--
      -- �f�[�^�̈ꊇ�擾
      FETCH del_rep_st_inv_d_h_cur BULK COLLECT INTO lt_del_rep_st_inv_d_h_data;
--
      -- ���������̃Z�b�g
      ln_target_cnt := lt_del_rep_st_inv_d_h_data.COUNT;
--
      -- �J�[�\���N���[�Y
      CLOSE del_rep_st_inv_d_h_cur;
--
      -- �Ώۃf�[�^�����݂���ꍇ���R�[�h���폜����
      IF (ln_target_cnt > 0) THEN
        BEGIN
          <<data_loop>>
          FORALL ln_loop_cnt IN 1..ln_target_cnt
            DELETE FROM xxcfr_rep_st_inv_d_h rep
            WHERE rep.rowid = lt_del_rep_st_inv_d_h_data(ln_loop_cnt);
--
          -- �R�~�b�g���s
          COMMIT;
--
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr       -- 'XXCFR'
                                                          ,cv_msg_003a18_012    -- �f�[�^�폜�G���[
                                                          ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                          ,xxcfr_common_pkg.get_table_comment(cv_table_d_h))
                                                          -- �W�����������[�������P��D���[�N�e�[�u���w�b�_
                                ,1
                                ,5000);
            lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
            RAISE global_api_expt;
        END;
--
      END IF;
--
    EXCEPTION
      WHEN lock_expt THEN  -- �e�[�u�����b�N�ł��Ȃ�����
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                       ,cv_msg_003a18_011    -- �e�[�u�����b�N�G���[
                                                       ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                       ,xxcfr_common_pkg.get_table_comment(cv_table_d_h))
                                                      -- �W�����������[�������P��D���[�N�e�[�u���w�b�_
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
    END;
--
    -- �H�W���������ō����[�������P��D���[�N�e�[�u�����׍폜����
    BEGIN
      -- �J�[�\���I�[�v��
      OPEN del_rep_st_inv_inc_d_l_cur;
--
      -- �f�[�^�̈ꊇ�擾
      FETCH del_rep_st_inv_inc_d_l_cur BULK COLLECT INTO lt_del_rep_st_inv_inc_d_l_data;
--
      -- ���������̃Z�b�g
      ln_target_cnt := lt_del_rep_st_inv_inc_d_l_data.COUNT;
--
      -- �J�[�\���N���[�Y
      CLOSE del_rep_st_inv_inc_d_l_cur;
--
      -- �Ώۃf�[�^�����݂���ꍇ���R�[�h���폜����
      IF (ln_target_cnt > 0) THEN
        BEGIN
          <<data_loop>>
          FORALL ln_loop_cnt IN 1..ln_target_cnt
            DELETE FROM xxcfr_rep_st_inv_inc_tax_d_l rep
            WHERE rep.rowid = lt_del_rep_st_inv_inc_d_l_data(ln_loop_cnt);
--
          -- �R�~�b�g���s
          COMMIT;
--
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                          ,cv_msg_003a18_012 -- �f�[�^�폜�G���[
                                                          ,cv_tkn_table      -- �g�[�N��'TABLE'
                                                          ,xxcfr_common_pkg.get_table_comment(cv_table_d_l))
                                                          -- �W���������ō����[�������P��D���[�N�e�[�u������
                                ,1
                                ,5000);
            lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
            RAISE global_api_expt;
        END;
--
      END IF;
--
    EXCEPTION
      WHEN lock_expt THEN  -- �e�[�u�����b�N�ł��Ȃ�����
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                       ,cv_msg_003a18_011    -- �e�[�u�����b�N�G���[
                                                       ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                       ,xxcfr_common_pkg.get_table_comment(cv_table_d_l))
                                                      -- �W���������ō����[�������P��D���[�N�e�[�u������
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
    END;
--
-- Ver.1.92 [��QE_�{�ғ�_15307] ADD END
  EXCEPTION
-- Mod 2015.07.31 Ver1.80 End
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
  END delete_work_table;
--
-- Add 2015.07.31 Ver1.80 Start
--
  /**********************************************************************************
   * Procedure Name   : exec_submit_req
   * Description      : �X�ܕʖ��׏o�͗v�����s����(A-13)
   ***********************************************************************************/
  PROCEDURE exec_submit_req(
    iv_bill_type          IN  VARCHAR2, -- �������^�C�v
    in_req_cnt            IN  NUMBER,   -- �v�����s��
    in_target_cnt         IN  NUMBER,   -- �Ώی���
    ov_errbuf             OUT VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'exec_submit_req'; -- �v���O������
--
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_conc_name        CONSTANT VARCHAR2(20) := '�X�ܕʖ��׏o��';       -- �G���[���b�Z�[�W�g�[�N��
    -- �Q�ƃ^�C�v
    cv_xxcfr_bill_type  CONSTANT VARCHAR2(20) := 'XXCFR1_BILL_TYPE';     -- �������^�C�v
-- Del 2016.03.31 Ver1.90 Start
--    -- �o���o�̓R���J�����g��
--    cv_xxcfr003a20      CONSTANT VARCHAR2(20) := 'XXCFR003A20C';         -- �X�ܕʖ��׏o��
-- Del 2016.03.31 Ver1.90 End
    -- ���[�敪
    cv_report_type      CONSTANT VARCHAR2(20) := '1';                    -- PDF
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_conc_name  VARCHAR2(100);
-- Add 2016.03.31 Ver1.90 Start
    lv_conc_short_name VARCHAR2(100);
-- Add 2016.03.31 Ver1.90 End
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- �X�ܕʖ��׏o�͂̃R���J�����g���̂Ɏg�p���镶�����擾
    --==============================================================
    BEGIN
      SELECT flvv.description AS conc_name
-- Add 2016.03.31 Ver1.90 Start
            ,flvv.attribute1  AS conc_short_name
-- Add 2016.03.31 Ver1.90 End
      INTO   lv_conc_name
-- Add 2016.03.31 Ver1.90 Start
            ,lv_conc_short_name
-- Add 2016.03.31 Ver1.90 End
      FROM   fnd_lookup_values_vl flvv
      WHERE  flvv.lookup_type  = cv_xxcfr_bill_type
      AND    flvv.lookup_code  = iv_bill_type
      AND    flvv.enabled_flag = cv_enabled_yes
      AND    TRUNC(NVL(flvv.start_date_active, SYSDATE)) <= TRUNC(SYSDATE)
      AND    TRUNC(NVL(flvv.end_date_active,   SYSDATE)) >= TRUNC(SYSDATE)
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg   := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cfr         -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_msg_003a18_027      -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_lookup_type     -- �g�[�N���R�[�h1
                         , iv_token_value1 => cv_xxcfr_bill_type     -- �g�[�N���l1
                         , iv_token_name2  => cv_tkn_lookup_code     -- �g�[�N���R�[�h2
                         , iv_token_value2 => iv_bill_type           -- �g�[�N���l2
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==============================================================
    -- �R���J�����g���s
    --==============================================================
-- Ver.1.92 [��QE_�{�ғ�_15307] ADD START
    g_org_request(in_req_cnt).conc_name := lv_conc_name;
-- Ver.1.92 [��QE_�{�ғ�_15307] ADD END
    g_org_request(in_req_cnt).request_id := fnd_request.submit_request(
                                               application => cv_msg_kbn_cfr         -- �A�v���P�[�V�����Z�k��
-- Mod 2016.03.31 Ver1.90 Start
--                                              ,program     => cv_xxcfr003a20         -- �R���J�����g�v���O������
                                              ,program     => lv_conc_short_name     -- �R���J�����g�v���O������
-- Mod 2016.03.31 Ver1.90 Start
                                              ,description => lv_conc_name           -- �E�v
                                              ,start_time  => NULL                   -- �J�n����
                                              ,sub_request => FALSE                  -- �T�u�v��
                                              ,argument1   => cv_report_type         -- ���[�敪
                                              ,argument2   => iv_bill_type           -- �������^�C�v
                                              ,argument3   => TO_CHAR(cn_request_id) -- ���s���v��ID
                                              ,argument4   => TO_CHAR(in_target_cnt) -- �Ώی���
                      );
    -- ����ȊO�̏ꍇ
    IF ( g_org_request(in_req_cnt).request_id = 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cfr                                -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_msg_003a18_028                             -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_conc                                   -- �g�[�N���R�[�h�P
                     , iv_token_value1 => cv_conc_name                                  -- �X�ܕʖ��׏o��
                   );
      lv_errbuf := lv_errmsg;
      -- ���O�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000)
      );
      --�P�s���s
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
      -- �e�R���J�����g�p���^�[���R�[�h
      ov_retcode := cv_status_error;
    END IF;
--
    -- �R�~�b�g���s
    COMMIT;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END exec_submit_req;
--
  /**********************************************************************************
   * Procedure Name   : func_wait_for_request
   * Description      : �R���J�����g�I���ҋ@����(A-14)
   ***********************************************************************************/
  PROCEDURE func_wait_for_request(
    ig_org_request_id           IN  g_org_request_ttype,   -- �v��ID
    ov_errbuf                   OUT VARCHAR2,              -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                  OUT VARCHAR2,              -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                   OUT VARCHAR2)              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'func_wait_for_request'; -- �v���O������
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_conc_name  CONSTANT VARCHAR2(14)   := '�X�ܕʖ��׏o��';        -- �G���[���b�Z�[�W�g�[�N��
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
    -- *** ���[�J���ϐ� ***
    lb_wait_request           BOOLEAN        DEFAULT TRUE;
    lv_phase                  VARCHAR2(50)   DEFAULT NULL;
    lv_status                 VARCHAR2(50)   DEFAULT NULL;
    lv_dev_phase              VARCHAR2(50)   DEFAULT NULL;
    lv_dev_status             VARCHAR2(50)   DEFAULT NULL;
    lv_message                VARCHAR2(5000) DEFAULT NULL;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    <<wait_req>>
    FOR i IN ig_org_request_id.FIRST..ig_org_request_id.LAST LOOP
      -- ����ɔ��s�ł������̂̂�
      IF ( ig_org_request_id(i).request_id <> 0 ) THEN
        --==============================================================
        -- �R���J�����g�v���ҋ@
        --==============================================================
        lb_wait_request := fnd_concurrent.wait_for_request(
                              request_id => ig_org_request_id(i).request_id -- �v��ID
                             ,interval   => gn_interval                     -- �R���J�����g�Ď��Ԋu
                             ,max_wait   => gn_max_wait                     -- �R���J�����g�Ď��ő厞��
                             ,phase      => lv_phase                        -- �v���t�F�[�Y
                             ,status     => lv_status                       -- �v���X�e�[�^�X
                             ,dev_phase  => lv_dev_phase                    -- �v���t�F�[�Y�R�[�h
                             ,dev_status => lv_dev_status                   -- �v���X�e�[�^�X�R�[�h
                             ,message    => lv_message                      -- �������b�Z�[�W
                           );
        -- �߂�l��FALSE�̏ꍇ
        IF ( lb_wait_request = FALSE ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_cfr
                         ,iv_name         => cv_msg_003a18_029
                         ,iv_token_name1  => cv_tkn_conc
-- Ver.1.92 [��QE_�{�ғ�_15307] MOD START
--                         ,iv_token_value1 => cv_conc_name
                         ,iv_token_value1 => ig_org_request_id(i).conc_name
-- Ver.1.92 [��QE_�{�ғ�_15307] MOD END
                         ,iv_token_name2  => cv_tkn_request_id
                         ,iv_token_value2 => TO_CHAR(ig_org_request_id(i).request_id)
                       );
          lv_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
          -- �e�R���J�����g�p���^�[���R�[�h
          ov_retcode := cv_status_error;
        ELSE
          -- ����I�����b�Z�[�W�o��
          IF ( lv_dev_status = cv_dev_status_normal ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cfr
                           ,iv_name         => cv_msg_003a18_030
                           ,iv_token_name1  => cv_tkn_conc
-- Ver.1.92 [��QE_�{�ғ�_15307] MOD START
--                           ,iv_token_value1 => cv_conc_name
                           ,iv_token_value1 => ig_org_request_id(i).conc_name
-- Ver.1.92 [��QE_�{�ғ�_15307] MOD END
                           ,iv_token_name2  => cv_tkn_request_id
                           ,iv_token_value2 => TO_CHAR(ig_org_request_id(i).request_id)
                         );
            lv_errbuf := lv_errmsg;
          -- �x���I�����b�Z�[�W�o��
          ELSIF ( lv_dev_status = cv_dev_status_warn ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cfr
                           ,iv_name         => cv_msg_003a18_031
                           ,iv_token_name1  => cv_tkn_conc
-- Ver.1.92 [��QE_�{�ғ�_15307] MOD START
--                           ,iv_token_value1 => cv_conc_name
                           ,iv_token_value1 => ig_org_request_id(i).conc_name
-- Ver.1.92 [��QE_�{�ғ�_15307] MOD END
                           ,iv_token_name2  => cv_tkn_request_id
                           ,iv_token_value2 => TO_CHAR(ig_org_request_id(i).request_id)
                         );
            lv_errbuf := lv_errmsg;
            ov_retcode := cv_status_warn;
          -- �G���[�I�����b�Z�[�W�o��
          ELSE
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cfr
                           , iv_name         => cv_msg_003a18_032
                           , iv_token_name1  => cv_tkn_conc
-- Ver.1.92 [��QE_�{�ғ�_15307] MOD START
--                           , iv_token_value1 => cv_conc_name
                           ,iv_token_value1 => ig_org_request_id(i).conc_name
-- Ver.1.92 [��QE_�{�ғ�_15307] MOD END
                           , iv_token_name2  => cv_tkn_request_id
                           , iv_token_value2 => TO_CHAR(ig_org_request_id(i).request_id)
                         );
            lv_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
            -- �e�R���J�����g�p���^�[���R�[�h
            ov_retcode := cv_status_error;
          END IF;
        END IF;
        -- ���O�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errbuf
        );
        --�P�s���s
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => ''
        );
      END IF;
    END LOOP wait_req;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END func_wait_for_request;
-- Add 2015.07.31 Ver1.80 End
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_target_date         IN      VARCHAR2,         -- ����
    iv_customer_code14     IN      VARCHAR2,         -- ���|�Ǘ���ڋq
    iv_customer_code21     IN      VARCHAR2,         -- �����������p�ڋq
    iv_customer_code20     IN      VARCHAR2,         -- �������p�ڋq
    iv_customer_code10     IN      VARCHAR2,         -- �ڋq
-- Add 2010.12.10 Ver1.30 Start
    iv_bill_pub_cycle      IN      VARCHAR2,         -- ���������s�T�C�N��
-- Add 2010.12.10 Ver1.30 End
-- Add 2013.12.13 Ver1.60 Start
    iv_tax_output_type     IN      VARCHAR2,         -- �ŕʓ���o�͋敪
-- Add 2013.12.13 Ver1.60 End
-- Add 2014.03.27 Ver1.70 Start
    iv_bill_invoice_type   IN      VARCHAR2,         -- �������o�͌`��
-- Add 2014.03.27 Ver1.70 End
    ov_errbuf              OUT     VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode             OUT     VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg              OUT     VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_errbuf_svf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode_svf VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg_svf  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
-- Add 2015.07.31 Ver1.80 Start
    gn_req_cnt    := 0;
-- Add 2015.07.31 Ver1.80 End
--
    -- =====================================================
    --  ��������(A-1)
    -- =====================================================
    init(
       iv_target_date         -- ����
      ,iv_customer_code14     -- ���|�Ǘ���ڋq
      ,iv_customer_code21     -- �����������p�ڋq
      ,iv_customer_code20     -- �������p�ڋq
      ,iv_customer_code10     -- �ڋq
-- Add 2010.12.10 Ver1.30 Start
      ,iv_bill_pub_cycle      -- ���������s�T�C�N��
-- Add 2010.12.10 Ver1.30 End
-- Add 2013.12.13 Ver1.60 Start
      ,iv_tax_output_type     -- �ŕʓ���o�͋敪
-- Add 2013.12.13 Ver1.60 End
-- Add 2014.03.27 Ver1.70 Start
      ,iv_bill_invoice_type   -- �������o�͌`��
-- Add 2014.03.27 Ver1.70 End
      ,lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �v���t�@�C���擾����(A-2)
    -- =====================================================
    get_profile_value(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �S�Џo�͌����`�F�b�N����(A-3)
    -- =====================================================
    chk_inv_all_dept(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- ======================================================================================
    --  �Ώیڋq�擾����(A-4)�A���|�Ǘ���ڋq�擾����(A-5)�A���[�N�e�[�u���f�[�^�o�^(A-6))
    -- ======================================================================================
    insert_work_table(
       iv_target_date         -- ����
      ,iv_customer_code14     -- ���|�Ǘ���ڋq
      ,iv_customer_code21     -- �����������p�ڋq
      ,iv_customer_code20     -- �������p�ڋq
      ,iv_customer_code10     -- �ڋq
-- Add 2010.12.10 Ver1.30 Start
      ,iv_bill_pub_cycle      -- ���������s�T�C�N��
-- Add 2010.12.10 Ver1.30 End
-- Add 2013.12.13 Ver1.60 Start
      ,iv_tax_output_type     -- �ŕʓ���o�͋敪
-- Add 2013.12.13 Ver1.60 End
-- Add 2014.03.27 Ver1.70 Start
      ,iv_bill_invoice_type   -- �������o�͌`��
-- Add 2014.03.27 Ver1.70 End
      ,lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF  (lv_retcode = cv_status_warn) THEN
      ov_retcode := cv_status_warn;
      ov_errmsg  := lv_errmsg;
    ELSIF (gv_warning_flag = cv_status_yes) THEN  -- �ڋq�R�t���x�����ݎ�
      ov_retcode := cv_status_warn;
    END IF;
--
    -- =====================================================
    --  �������擾�`�F�b�N (A-7)
    -- =====================================================
    chk_account_data(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    ELSIF  (lv_retcode = cv_status_warn) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
    -- =====================================================
    --  SVF�N�� (A-8)
    -- =====================================================
    start_svf_api(
       lv_errbuf_svf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode_svf            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg_svf);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
-- Add 2015.07.31 Ver1.80 Start
    -- =====================================================
    --  �X�ܕʖ��׏o�͗v�����s���� (A-13)
    -- =====================================================
    -- ����0���t���OA��1�̏ꍇ
    IF ( gv_target_a_flag = cv_taget_flag_1 ) THEN
      gn_req_cnt := gn_req_cnt + 1;
      -- �������^�C�v�F05�̗v�����s
      exec_submit_req(
         cv_bill_type_01           -- �������^�C�v
        ,gn_req_cnt                -- �v�����s��
        ,gn_target_cnt_a_h         -- �Ώی���
        ,lv_errbuf_svf             -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode_svf            -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg_svf);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    -- ����0���t���OA��2�̏ꍇ
    ELSIF ( gv_target_a_flag =  cv_taget_flag_2 ) THEN
      gn_req_cnt := gn_req_cnt + 1;
      -- �������^�C�v�F01�̗v�����s
      exec_submit_req(
         cv_bill_type_01           -- �������^�C�v
        ,gn_req_cnt                -- �v�����s��
        ,gn_target_cnt_a_h         -- �Ώی���
        ,lv_errbuf_svf             -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode_svf            -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg_svf);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      gn_req_cnt := gn_req_cnt + 1;
      -- �������^�C�v�F02�̗v�����s
      exec_submit_req(
         cv_bill_type_02           -- �������^�C�v
        ,gn_req_cnt                -- �v�����s��
        ,gn_target_cnt_a_l         -- �Ώی���
        ,lv_errbuf_svf             -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode_svf            -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg_svf);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    END IF;
--
    -- ����0���t���OB��1�̏ꍇ
    IF ( gv_target_b_flag = cv_taget_flag_1 ) THEN
      gn_req_cnt := gn_req_cnt + 1;
      -- �������^�C�v�F03�̗v�����s
      exec_submit_req(
         cv_bill_type_03           -- �������^�C�v
        ,gn_req_cnt                -- �v�����s��
        ,gn_target_cnt_b_h         -- �Ώی���
        ,lv_errbuf_svf             -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode_svf            -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg_svf);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    -- ����0���t���OB��2�̏ꍇ
    ELSIF ( gv_target_b_flag =  cv_taget_flag_2 ) THEN
      gn_req_cnt := gn_req_cnt + 1;
      -- �������^�C�v�F03�̗v�����s
      exec_submit_req(
         cv_bill_type_03           -- �������^�C�v
        ,gn_req_cnt                -- �v�����s��
        ,gn_target_cnt_b_h         -- �Ώی���
        ,lv_errbuf_svf             -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode_svf            -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg_svf);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      gn_req_cnt := gn_req_cnt + 1;
      -- �������^�C�v�F04�̗v�����s
      exec_submit_req(
         cv_bill_type_04           -- �������^�C�v
        ,gn_req_cnt                -- �v�����s��
        ,gn_target_cnt_b_l         -- �Ώی���
        ,lv_errbuf_svf             -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode_svf            -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg_svf);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    END IF;
--
-- Add 2016.03.31 Ver1.90 Start
    -- ����0���t���OC��1�̏ꍇ
    IF ( gv_target_c_flag = cv_taget_flag_1 ) THEN
      gn_req_cnt := gn_req_cnt + 1;
      -- �������^�C�v�F09�̗v�����s
      exec_submit_req(
         cv_bill_type_09           -- �������^�C�v
        ,gn_req_cnt                -- �v�����s��
        ,gn_target_cnt_c_h         -- �Ώی���
        ,lv_errbuf_svf             -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode_svf            -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg_svf);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    -- ����0���t���OC��2�̏ꍇ
    ELSIF ( gv_target_c_flag =  cv_taget_flag_2 ) THEN
      gn_req_cnt := gn_req_cnt + 1;
      -- �������^�C�v�F09�̗v�����s
      exec_submit_req(
         cv_bill_type_09           -- �������^�C�v
        ,gn_req_cnt                -- �v�����s��
        ,gn_target_cnt_c_h         -- �Ώی���
        ,lv_errbuf_svf             -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode_svf            -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg_svf);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      gn_req_cnt := gn_req_cnt + 1;
      -- �������^�C�v�F10�̗v�����s
      exec_submit_req(
         cv_bill_type_10           -- �������^�C�v
        ,gn_req_cnt                -- �v�����s��
        ,gn_target_cnt_c_l         -- �Ώی���
        ,lv_errbuf_svf             -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode_svf            -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg_svf);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    END IF;
--
-- Add 2016.03.31 Ver1.90 End
-- Ver.1.92 [��QE_�{�ғ�_15307] ADD START
    -- ����0���t���OD��1�̏ꍇ
    IF ( gv_target_d_flag = cv_taget_flag_1 ) THEN
      gn_req_cnt := gn_req_cnt + 1;
      -- �������^�C�v�F13�̗v�����s
      exec_submit_req(
         cv_bill_type_13           -- �������^�C�v
        ,gn_req_cnt                -- �v�����s��
        ,gn_target_cnt_d_h         -- �Ώی���
        ,lv_errbuf_svf             -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode_svf            -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg_svf);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    -- ����0���t���OD��2�̏ꍇ
    ELSIF ( gv_target_d_flag =  cv_taget_flag_2 ) THEN
      gn_req_cnt := gn_req_cnt + 1;
      -- �������^�C�v�F13�̗v�����s
      exec_submit_req(
         cv_bill_type_13           -- �������^�C�v
        ,gn_req_cnt                -- �v�����s��
        ,gn_target_cnt_d_h         -- �Ώی���
        ,lv_errbuf_svf             -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode_svf            -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg_svf);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      gn_req_cnt := gn_req_cnt + 1;
      -- �������^�C�v�F14�̗v�����s
      exec_submit_req(
         cv_bill_type_14           -- �������^�C�v
        ,gn_req_cnt                -- �v�����s��
        ,gn_target_cnt_d_l         -- �Ώی���
        ,lv_errbuf_svf             -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode_svf            -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg_svf);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    END IF;
--
-- Ver.1.92 [��QE_�{�ғ�_15307] ADD END
    -- =====================================================
    --  �R���J�����g�I���ҋ@����(A-14)
    -- =====================================================
    IF (  ( g_org_request.COUNT <> 0 )
      AND ( lv_retcode_svf <> cv_status_error ) ) THEN
      --���s�����X�ܕʖ��׏o�͂�ҋ@����
      func_wait_for_request(
         ig_org_request_id    => g_org_request
        ,ov_errbuf            => lv_errbuf_svf
        ,ov_retcode           => lv_retcode_svf
        ,ov_errmsg            => lv_errmsg_svf
      );
    END IF;
--
-- Add 2015.07.31 Ver1.80 End
    -- =====================================================
    --  ���[�N�e�[�u���f�[�^�폜 (A-9)
    -- =====================================================
    delete_work_table(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  SVF�N��API�G���[�`�F�b�N (A-8)
    -- =====================================================
    IF (lv_retcode_svf = cv_status_error) THEN
      --(�G���[����)
      lv_errmsg := lv_errmsg_svf;
      lv_errbuf := lv_errbuf_svf;
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
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf                 OUT     VARCHAR2,         -- �G���[�E���b�Z�[�W  #�Œ�#
    retcode                OUT     VARCHAR2,         -- �G���[�R�[�h        #�Œ�#
    iv_target_date         IN      VARCHAR2,         -- ����
    iv_customer_code10     IN      VARCHAR2,         -- �ڋq
    iv_customer_code20     IN      VARCHAR2,         -- �������p�ڋq
    iv_customer_code21     IN      VARCHAR2,         -- �����������p�ڋq
    iv_customer_code14     IN      VARCHAR2          -- ���|�Ǘ���ڋq
-- Add 2010.12.10 Ver1.30 Start
   ,iv_bill_pub_cycle      IN      VARCHAR2          -- ���������s�T�C�N��
-- Add 2010.12.10 Ver1.30 End
-- Add 2013.12.13 Ver1.60 Start
   ,iv_tax_output_type     IN      VARCHAR2          -- �ŕʓ���o�͋敪
-- Add 2013.12.13 Ver1.60 End
-- Add 2014.03.27 Ver1.70 Start
   ,iv_bill_invoice_type   IN      VARCHAR2          -- �������o�͌`��
-- Add 2014.03.27 Ver1.70 End
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
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf       VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code VARCHAR2(100);   --���b�Z�[�W�R�[�h
--
    lv_errbuf2      VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_file_type_log
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
       iv_target_date     => iv_target_date -- ����
      ,iv_customer_code14 => iv_customer_code14     -- ���|�Ǘ���ڋq
      ,iv_customer_code21 => iv_customer_code21     -- �����������p�ڋq
      ,iv_customer_code20 => iv_customer_code20     -- �������p�ڋq
      ,iv_customer_code10 => iv_customer_code10     -- �ڋq
-- Add 2010.12.10 Ver1.30 Start
      ,iv_bill_pub_cycle  => iv_bill_pub_cycle      -- ���������s�T�C�N��
-- Add 2010.12.10 Ver1.30 End
-- Add 2013.12.13 Ver1.60 Start
      ,iv_tax_output_type => iv_tax_output_type     -- �ŕʓ���o�͋敪
-- Add 2013.12.13 Ver1.60 End
-- Add 2014.03.27 Ver1.70 Start
      ,iv_bill_invoice_type => iv_bill_invoice_type -- �������o�͌`��
-- Add 2014.03.27 Ver1.70 End
      ,ov_errbuf          => lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode         => lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg          => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[�������A�e�����͈ȉ��ɓ��ꂵ�ďo�͂���
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
--
--###########################  �Œ蕔 START   #####################################################
--
    --����łȂ��ꍇ�A�G���[�o��
    IF (lv_retcode <> cv_status_normal) THEN
      -- ���b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
    END IF;
--
    --�G���[�̏ꍇ�A�V�X�e���G���[���b�Z�[�W�o��
    IF (lv_retcode = cv_status_error) THEN
      -- �V�X�e���G���[���b�Z�[�W�o��
      lv_errbuf2 := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cfr
                      ,iv_name         => cv_msg_003a18_009
                     );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf2 --�G���[���b�Z�[�W
      );
      -- �G���[�o�b�t�@�̃��b�Z�[�W�A��
      lv_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      -- ���b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --���[�U�[�E�G���[���b�Z�[�W
      );
        --�P�s���s
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '' --���[�U�[�E�G���[���b�Z�[�W
    );
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
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�P�s���s
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '' --���[�U�[�E�G���[���b�Z�[�W
    );
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
    fnd_file.put_line(
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
END XXCFR003A18C;
/
