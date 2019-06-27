CREATE OR REPLACE PACKAGE BODY APPS.XXCOS014A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS014A02C (body)
 * Description      : �[�i���p�f�[�^�쐬(EDI)
 * MD.050           : �[�i���p�f�[�^�쐬(EDI) MD050_COS_014_A02
 * Version          : 1.22
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-0)
 *  proc_init              ��������(A-1)
 *  proc_out_header_record �w�b�_���R�[�h�쐬����(A-2)
 *  proc_get_data          �f�[�^�擾����(A-3)
 *  proc_out_csv_header    CSV�w�b�_���R�[�h�쐬����(A-4)
 *  proc_out_data_record   �f�[�^���R�[�h�쐬����(A-5)
 *  proc_out_footer_record �t�b�^���R�[�h�쐬����(A-6)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/04    1.0   K.Kumamoto       �V�K�쐬
 *  2009/02/12    1.1   T.Nakamura       [��QCOS_061] ���b�Z�[�W�o�́A���O�o�͂ւ̏o�͓��e�̒ǉ��E�C��
 *  2009/02/13    1.2   T.Nakamura       [��QCOS_065] ���O�o�̓v���V�[�W��out_line�̖�����
 *  2009/02/16    1.3   T.Nakamura       [��QCOS_079] �v���t�@�C���ǉ��A�J�[�\��cur_data_record�̉��C��
 *  2009/02/17    1.4   T.Nakamura       [��QCOS_094] CSV�o�͍��ڂ̏C��
 *  2009/02/19    1.5   T.Nakamura       [��QCOS_109] ���O�o�͂ɃG���[���b�Z�[�W���o�͓�
 *  2009/02/20    1.6   T.Nakamura       [��QCOS_110] �t�b�^���R�[�h�쐬�������s���̃G���[�n���h�����O��ǉ�
 *  2009/04/01    1.7   T.Kitajima       [T1_0026] �C���p���ɒ��[�l���`�F�[���X�R�[�h�ǉ�
 *                                                 �������̃C���p��.�`�F�[���X�R�[�h��
 *                                                 �C���p��.���[�l���`�F�[���X�R�[�h�֕ύX
 *  2009/04/02    1.8   T.Kitajima       [T1_0114] �[�i���_���擾���@�ύX
 *  2009/04/27    1.9   K.Kiriu          [T1_0112] �P�ʍ��ړ��e�s���Ή�
 *  2009/06/11    1.10  K.Kiriu          [T1_1352] �[�i��(�󒍏��)�o�͏�Q�Ή�
 *  2009/06/18    1.10  N.Maeda          [T1_1158] �Ώۃf�[�^���o�����ύX
 *  2009/07/03    1.10  M.Sano           [T1_1158] �Ώۃf�[�^���o�����ύX(���r���[�w�E�C��)
 *  2009/08/12    1.11  N.Maeda          [0000441] PT�Ή�
 *  2009/08/13    1.11  N.Maeda          [0000441] ���r���[�w�E�Ή�
 *  2009/09/08    1.12  M.Sano           [0001211] �Ŋ֘A���ڎ擾����C��
 *  2009/09/15    1.12  M.Sano           [0001211] ���r���[�w�E�Ή�
 *  2010/01/04    1.13  M.Sano           [E_�{�ғ�_00738] �󒍘A�g�σt���O�uS(�ΏۊO)�v�ǉ��ɔ����C��
 *  2010/01/06    1.14  N.Maeda          [E_�{�ғ�_00552] ����於(����)�̃X�y�[�X�폜
 *  2010/03/10    1.15  T.Nakano         [E_�{�ғ�_01695] EDI�捞���̕ύX
 *  2010/04/20    1.16  H.Sasaki         [E_�{�ғ�_01900] �������z�̎擾����ύX
 *                                       [E_�{�ғ�_02042] ���i���̎擾����ύX
 *  2010/06/11    1.17  S.Miyakoshi      [E_�{�ғ�_03075] ���_�I��Ή�
 *  2010/10/15    1.18  K.Kiriu          [E_�{�ғ�_04783] �n��R�[�h�A�n�於(����)�A�n��R�[�h(�J�i)�o�͕ύX�Ή�
 *  2011/10/06    1.19  A.Shirakawa      [E_�{�ғ�_07906] EDI�̗���BMS�Ή�
 *  2018/03/07    1.20  H.Sasaki         [E_�{�ғ�_14882] �폜���ׂ�\������
 *  2018/07/27    1.21  K.Kiriu          [E_�{�ғ�_15193]���~���ٍϏ����ǉ��Ή�
 *  2019/06/25    1.22  N.Miyamoto       [E_�{�ғ�_15472]�y���ŗ��Ή�
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  ct_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  ct_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
  resource_busy_expt      EXCEPTION;     --���b�N�G���[
  PRAGMA EXCEPTION_INIT(resource_busy_expt, -54);
  update_expt             EXCEPTION;     --�X�V�G���[
  sale_class_expt         EXCEPTION;     --����敪�`�F�b�N�G���[
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                     CONSTANT VARCHAR2(100) := 'XXCOS014A02C'; -- �p�b�P�[�W��
--
  cv_apl_name                     CONSTANT VARCHAR2(100) := 'XXCOS'; --�A�v���P�[�V������
--
  --�v���t�@�C��
  ct_prf_if_header                CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCCP1_IF_HEADER';                    --XXCCP:�w�b�_���R�[�h���ʎq
  ct_prf_if_data                  CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCCP1_IF_DATA';                      --XXCCP:�f�[�^���R�[�h���ʎq
  ct_prf_if_footer                CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCCP1_IF_FOOTER';                    --XXCCP:�t�b�^���R�[�h���ʎq
  ct_prf_rep_outbound_dir         CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_REP_OUTBOUND_DIR_OM';          --XXCOS:���[OUTBOUND�o�̓f�B���N�g��(EBS�󒍊Ǘ�)
  ct_prf_company_name             CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_COMPANY_NAME';                 --XXCOS:��Ж�
  ct_prf_company_name_kana        CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_COMPANY_NAME_KANA';            --XXCOS:��Ж��J�i
  ct_prf_utl_max_linesize         CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_UTL_MAX_LINESIZE';             --XXCOS:UTL_MAX�s�T�C�Y
  ct_prf_organization_code        CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOI1_ORGANIZATION_CODE';            --XXCOI:�݌ɑg�D�R�[�h
  ct_prf_case_uom_code            CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_CASE_UOM_CODE';                --XXCOS:�P�[�X�P�ʃR�[�h
  ct_prf_bowl_uom_code            CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_BALL_UOM_CODE';                --XXCOS:�{�[���P�ʃR�[�h
  ct_prf_base_manager_code        CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_BASE_MANAGER_CODE';            --XXCOS:�x�X���R�[�h
  ct_prf_cmn_rep_chain_code       CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_CMN_REP_CHAIN_CODE';           --XXCOS:���ʒ��[�l���p�`�F�[���X�R�[�h
  ct_prf_set_of_books_id          CONSTANT fnd_profile_options.profile_option_name%TYPE := 'GL_SET_OF_BKS_ID';                    --GL��v����ID
-- 2009/02/16 T.Nakamura Ver.1.3 add start
  ct_prf_org_id                   CONSTANT fnd_profile_options.profile_option_name%TYPE := 'ORG_ID';                              --ORG_ID
-- 2009/02/16 T.Nakamura Ver.1.3 add end
-- ************ 2009/08/12 N.Maeda 1.11 ADD START ***************** --
  ct_item_div_h                   CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_ITEM_DIV_H';
-- ************ 2009/08/12 N.Maeda 1.11 ADD  END  ***************** --
  --
  --���b�Z�[�W
  ct_msg_if_header                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00094';                    --XXCCP:�w�b�_���R�[�h���ʎq
  ct_msg_if_data                  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00095';                    --XXCCP:�f�[�^���R�[�h���ʎq
  ct_msg_if_footer                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00096';                    --XXCCP:�t�b�^���R�[�h���ʎq
  ct_msg_rep_outbound_dir         CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00097';                    --XXCOS:���[OUTBOUND�o�̓f�B���N�g��
  ct_msg_company_name             CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00058';                    --XXCOS:��Ж�
  ct_msg_company_name_kana        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00098';                    --XXCOS:��Ж��J�i
  ct_msg_utl_max_linesize         CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00099';                    --XXCOS:UTL_MAX�s�T�C�Y
  ct_msg_organization_code        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00048';                    --XXCOI:�݌ɑg�D�R�[�h
  ct_msg_case_uom_code            CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00057';                    --XXCOS:�P�[�X�P�ʃR�[�h
  ct_msg_bowl_uom_code            CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00059';                    --XXCOS:�{�[���P�ʃR�[�h
  ct_msg_base_manager_code        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00100';                    --XXCOS:�x�X���R�[�h
  ct_msg_cmn_rep_chain_code       CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00101';                    --XXCOS:���ʒ��[�l���p�`�F�[���X�R�[�h
  ct_msg_prf                      CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00004';                    --�v���t�@�C���擾�G���[
  ct_msg_org_id                   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00063';                    --���b�Z�[�W�p������.�݌ɑg�DID
  ct_msg_cust_master              CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00049';                    --���b�Z�[�W�p������.�ڋq�}�X�^
  ct_msg_item_master              CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00050';                    --���b�Z�[�W�p������.�i�ڃ}�X�^
/* 2009/06/11 Ver1.10 Mod Start */
--  ct_msg_oe_header                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00069';                    --���b�Z�[�W�p������.�󒍃w�b�_���e�[�u��
  ct_msg_edi_header               CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00114';                    --���b�Z�[�W�p������.EDI���w�b�_�e�[�u��
/* 2009/06/11 Ver1.10 Mod End   */
  ct_msg_get_err                  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00064';                    --�擾�G���[
  ct_msg_master_notfound          CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00065';                    --�}�X�^���o�^
  ct_msg_input_parameters1        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-12951';                    --�p�����[�^�o�̓��b�Z�[�W1
  ct_msg_input_parameters2        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-12952';                    --�p�����[�^�o�̓��b�Z�[�W2
  ct_msg_fopen_err                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00009';                    --�t�@�C���I�[�v���G���[���b�Z�[�W
  ct_msg_resource_busy_err        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00001';                    --���b�N�G���[���b�Z�[�W
/* 2009/06/11 Ver1.10 Mod Start */
--  ct_msg_sale_class_mixed         CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00034';                    --����敪���݃G���[���b�Z�[�W
  ct_msg_sale_class_mixed         CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-12953';                    --����敪���݃G���[���b�Z�[�W
/* 2009/06/11 Ver1.10 Mod End   */
  ct_msg_sale_class_err           CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00111';                    --����敪�G���[
  ct_msg_header_type              CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00122';                    --���b�Z�[�W�p������.�ʏ��
  ct_msg_line_type                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00121';                    --���b�Z�[�W�p������.�ʏ�o��
  ct_msg_set_of_books_id          CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00060';                    --���b�Z�[�W�p������.GL��v����ID
  ct_msg_nodata                   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00003';                    --�Ώۃf�[�^�Ȃ����b�Z�[�W
  ct_msg_file_name                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00130';                    --�t�@�C�����o�̓��b�Z�[�W
  ct_msg_update_err               CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00011';                    --�f�[�^�X�V�G���[���b�Z�[�W
  ct_msg_invoice_number           CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00131';                    --���b�Z�[�W�p������.�`�[�ԍ�
  ct_msg_order_source             CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00158';                    --���b�Z�[�W�p������.EDI��
-- 2009/02/16 T.Nakamura Ver.1.3 add start
  ct_msg_mo_org_id                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00047';                    --���b�Z�[�W�p������.MO:�c�ƒP��
-- 2009/02/16 T.Nakamura Ver.1.3 add end
-- ************ 2009/08/12 N.Maeda 1.11 ADD START ***************** --
  cv_msg_category_err             CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12954';     --�J�e�S���Z�b�gID�擾�G���[���b�Z�[�W
  cv_msg_item_div_h               CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12955';     --�{�Џ��i�敪
-- ************ 2009/08/12 N.Maeda 1.11 ADD  END  ***************** --
--
  --�g�[�N��
  cv_tkn_data                     CONSTANT VARCHAR2(4) := 'DATA';                                 --�f�[�^
  cv_tkn_table                    CONSTANT VARCHAR2(5) := 'TABLE';                                --�e�[�u��
  cv_tkn_prm1                     CONSTANT VARCHAR2(6) := 'PARAM1';                               --���̓p�����[�^1
  cv_tkn_prm2                     CONSTANT VARCHAR2(6) := 'PARAM2';                               --���̓p�����[�^2
  cv_tkn_prm3                     CONSTANT VARCHAR2(6) := 'PARAM3';                               --���̓p�����[�^3
  cv_tkn_prm4                     CONSTANT VARCHAR2(6) := 'PARAM4';                               --���̓p�����[�^4
  cv_tkn_prm5                     CONSTANT VARCHAR2(6) := 'PARAM5';                               --���̓p�����[�^5
  cv_tkn_prm6                     CONSTANT VARCHAR2(6) := 'PARAM6';                               --���̓p�����[�^6
  cv_tkn_prm7                     CONSTANT VARCHAR2(6) := 'PARAM7';                               --���̓p�����[�^7
  cv_tkn_prm8                     CONSTANT VARCHAR2(6) := 'PARAM8';                               --���̓p�����[�^8
  cv_tkn_prm9                     CONSTANT VARCHAR2(6) := 'PARAM9';                               --���̓p�����[�^9
  cv_tkn_prm10                    CONSTANT VARCHAR2(7) := 'PARAM10';                              --���̓p�����[�^10
  cv_tkn_prm11                    CONSTANT VARCHAR2(7) := 'PARAM11';                              --���̓p�����[�^11
  cv_tkn_prm12                    CONSTANT VARCHAR2(7) := 'PARAM12';                              --���̓p�����[�^12
  cv_tkn_prm13                    CONSTANT VARCHAR2(7) := 'PARAM13';                              --���̓p�����[�^13
  cv_tkn_prm14                    CONSTANT VARCHAR2(7) := 'PARAM14';                              --���̓p�����[�^14
  cv_tkn_prm15                    CONSTANT VARCHAR2(7) := 'PARAM15';                              --���̓p�����[�^15
  cv_tkn_prm16                    CONSTANT VARCHAR2(7) := 'PARAM16';                              --���̓p�����[�^16
  cv_tkn_prm17                    CONSTANT VARCHAR2(7) := 'PARAM17';                              --���̓p�����[�^17
--******************************************* 2009/04/01 1.7 T.Kitajima ADD START *************************************
  cv_tkn_prm18                    CONSTANT VARCHAR2(7) := 'PARAM18';                              --���̓p�����[�^18
--******************************************* 2009/04/01 1.7 T.Kitajima END START *************************************
  cv_tkn_filename                 CONSTANT VARCHAR2(100) := 'FILE_NAME';                          --�t�@�C����
  cv_tkn_prf                      CONSTANT VARCHAR2(7)  := 'PROFILE';                             --�v���t�@�C��
  cv_tkn_order_no                 CONSTANT VARCHAR2(8) := 'ORDER_NO';                             --�`�[�ԍ�
/* 2009/06/11 Ver1.10 Add Start */
  cv_tkn_chain_code               CONSTANT VARCHAR2(10) := 'CHAIN_CODE';                          --�`�F�[���X�R�[�h
  cv_tkn_store_code               CONSTANT VARCHAR2(10) := 'STORE_CODE';                          --�X�܃R�[�h
/* 2009/06/11 Ver1.10 Add End   */
  cv_tkn_key                      CONSTANT VARCHAR2(8) := 'KEY_DATA';                             --�L�[���
--
  --�Q�ƃ^�C�v
  ct_qc_sale_class                CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_SALE_CLASS';                   --�Q�ƃ^�C�v.����敪
/* 2009/09/15 Ver1.12 Add Start */
  --�Q�ƃ^�C�v
  ct_qc_consumption_tax_class     CONSTANT fnd_lookup_values.lookup_type%TYPE :=  'XXCOS1_CONSUMPTION_TAX_CLASS';       --�Q�ƃ^�C�v.HHT����ŋ敪
/* 2009/09/15 Ver1.12 Add End   */
--
  --���̑�
  cv_utl_file_mode                CONSTANT VARCHAR2(1)   := 'w';                                  --UTL_FILE.�I�[�v�����[�h
  cv_date_fmt                     CONSTANT VARCHAR2(8)  := 'YYYYMMDD';                            --���t����
  cv_time_fmt                     CONSTANT VARCHAR2(8)  := 'HH24MISS';                            --��������
  cv_cancel                       CONSTANT VARCHAR2(9)  := 'CANCELLED';                           --�X�e�[�^�X.���
  cv_cust_class_base              CONSTANT VARCHAR2(1)  := '1';                                   --�ڋq�敪.���_
  cv_cust_class_chain             CONSTANT VARCHAR2(2)  := '18';                                  --�ڋq�敪.�`�F�[���X
  cv_cust_class_chain_store       CONSTANT VARCHAR2(2)  := '10';                                  --�ڋq�敪.�X��
  cv_cust_class_uesama            CONSTANT VARCHAR2(2)  := '12';                                  --�ڋq�敪.��l
  cv_space                        CONSTANT VARCHAR2(2)  := '�@';                                  --�S�p�X�y�[�X
-- ************ 2009/08/12 N.Maeda 1.11 ADD START ***************** --
  ct_user_lang                    CONSTANT mtl_category_sets_tl.language%TYPE := userenv('LANG'); --LANG
-- ************ 2009/08/12 N.Maeda 1.11 ADD  END  ***************** --
/* 2009/09/15 Ver1.12 Add Start */
  cv_enabled_flag                 CONSTANT VARCHAR2(1) := 'Y';                                    --�L���t���O.�L��
  cv_order_forward_flag_y         CONSTANT VARCHAR2(1) := 'Y';                                    --�󒍘A�g�σt���O.�L��
  cv_order_forward_flag_n         CONSTANT VARCHAR2(1) := 'N';                                    --�󒍘A�g�σt���O.����
/* 2010/01/04 Ver1.13 Add Start */
  cv_order_forward_flag_s         CONSTANT VARCHAR2(1) := 'S';                                    --�󒍘A�g�σt���O.�ΏۊO
/* 2010/01/04 Ver1.13 Add End   */
  cv_select_block_1               CONSTANT VARCHAR2(1) := '1';                                    --�ϊ���ڋq�R�[�h��NULL�ȊO��EDI�w�b�_�f�[�^
  cv_select_block_2               CONSTANT VARCHAR2(1) := '2';                                    --�ϊ���ڋq�R�[�h��NULL��EDI�w�b�_
/* 2009/09/15 Ver1.12 Add End   */
-- Ver1.21 Add Start
  -- �ڋq�X�e�[�^�X
  cv_cust_stop_div                CONSTANT VARCHAR2(2)  := '90';                                  --���~���ٍ�
-- Ver1.21 Add End
-- 2019/06/25 V1.22 N.Miyamoto ADD START
  cv_attribute_y                  CONSTANT VARCHAR2(1)  := 'Y';                                   -- DFF�l'Y'
  cv_out_tax                      CONSTANT VARCHAR(10)  := '1';                                   -- �O��
  cv_ins_slip_tax                 CONSTANT VARCHAR(10)  := '2';                                   -- ����(�`�[�ې�)
  cv_ins_bid_tax                  CONSTANT VARCHAR(10)  := '3';                                   -- ����(�P������)
  cv_non_tax                      CONSTANT VARCHAR(10)  := '4';                                   -- ��ې�
  cv_tkn_down                     CONSTANT VARCHAR2(20) := 'DOWN';                                -- �؎̂�
  cv_tkn_up                       CONSTANT VARCHAR2(20) := 'UP';                                  -- �؏グ
  cv_tkn_nearest                  CONSTANT VARCHAR2(20) := 'NEAREST';                             -- �l�̌ܓ�
-- 2019/06/25 V1.22 N.Miyamoto ADD END
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  --���̓p�����[�^�i�[���R�[�h
  TYPE g_input_rtype IS RECORD (
    user_id                  NUMBER                                              --���[�UID
   ,chain_code               xxcmm_cust_accounts.edi_chain_code%TYPE             --EDI�`�F�[���X�R�[�h
   ,chain_name               hz_parties.party_name%TYPE                          --EDI�`�F�[���X��
   ,store_code               xxcmm_cust_accounts.store_code%TYPE                 --EDI�`�F�[���X�X�܃R�[�h
   ,base_code                xxcmm_cust_accounts.delivery_base_code%TYPE         --�[�i���_�R�[�h
   ,base_name                hz_parties.party_name%TYPE                          --�[�i���_��
   ,file_name                VARCHAR2(100)                                       --IF�t�@�C����
   ,data_type_code           xxcos_report_forms_register.data_type_code%TYPE      --�f�[�^��R�[�h
   ,ebs_business_series_code VARCHAR2(100)                                       --EBS�Ɩ��n��R�[�h
   ,info_div                 xxcos_report_forms_register.info_class%TYPE          --���敪
   ,report_code              xxcos_report_forms_register.report_code%TYPE         --���[�R�[�h
   ,report_name              xxcos_report_forms_register.report_name%TYPE         --���[�l��
   ,shop_delivery_date_from  VARCHAR2(100)                                       --�X�ܔ[�i��(FROM)
   ,shop_delivery_date_to    VARCHAR2(100)                                       --�X�ܔ[�i��(TO)
   ,edi_input_date           VARCHAR2(100)                                       --EDI�����
   ,publish_div              VARCHAR2(100)                                       --�[�i�����s�敪
   ,publish_flag_seq         xxcos_report_forms_register.publish_flag_seq%TYPE    --�[�i�����s�t���O����
--******************************************* 2009/04/01 1.7 T.Kitajima ADD START *************************************
   ,ssm_store_code           VARCHAR2(100)           --���[�l���`�F�[���X�R�[�h
--******************************************* 2009/04/01 1.7 T.Kitajima END START *************************************
  );
--
  --�v���t�@�C���l�i�[���R�[�h
  TYPE g_prf_rtype IS RECORD (
    if_header                fnd_profile_option_values.profile_option_value%TYPE --�w�b�_���R�[�h���ʎq
   ,if_data                  fnd_profile_option_values.profile_option_value%TYPE --�f�[�^���R�[�h���ʎq
   ,if_footer                fnd_profile_option_values.profile_option_value%TYPE --�t�b�^���R�[�h���ʎq
   ,rep_outbound_dir         fnd_profile_option_values.profile_option_value%TYPE --�o�̓f�B���N�g��
   ,company_name             fnd_profile_option_values.profile_option_value%TYPE --��Ж�
   ,company_name_kana        fnd_profile_option_values.profile_option_value%TYPE --��Ж��J�i
   ,utl_max_linesize         fnd_profile_option_values.profile_option_value%TYPE --UTL_FILE�ő�s�T�C�Y
   ,organization_code        fnd_profile_option_values.profile_option_value%TYPE --�݌ɑg�D�R�[�h
   ,case_uom_code            fnd_profile_option_values.profile_option_value%TYPE --�P�[�X�P�ʃR�[�h
   ,bowl_uom_code            fnd_profile_option_values.profile_option_value%TYPE --�{�[���P�ʃR�[�h
   ,base_manager_code        fnd_profile_option_values.profile_option_value%TYPE --�x�X���R�[�h
   ,cmn_rep_chain_code       fnd_profile_option_values.profile_option_value%TYPE --���ʒ��[�l���p�`�F�[���X�R�[�h
   ,set_of_books_id          fnd_profile_option_values.profile_option_value%TYPE --GL��v����ID
-- 2009/02/16 T.Nakamura Ver.1.3 add start
   ,org_id                   fnd_profile_option_values.profile_option_value%TYPE --ORG_ID
-- 2009/02/16 T.Nakamura Ver.1.3 add end
  );
  --�[�i���_���i�[���R�[�h
  TYPE g_base_rtype IS RECORD (
    base_name                hz_parties.party_name%TYPE                          --���_��
   ,base_name_kana           hz_parties.organization_name_phonetic%TYPE          --���_���J�i
   ,state                    hz_locations.state%TYPE                             --�s���{��
   ,city                     hz_locations.city%TYPE                              --�s�E��
   ,address1                 hz_locations.address1%TYPE                          --�Z���P
   ,address2                 hz_locations.address2%TYPE                          --�Z���Q
   ,phone_number             hz_locations.address_lines_phonetic%TYPE            --�d�b�ԍ�
   ,customer_code            xxcmm_cust_accounts.torihikisaki_code%TYPE          --�����R�[�h
   ,manager_name_kana        VARCHAR2(300)                                       --�����S����
   ,notfound_flag            varchar2(1)                                         --���_�o�^�t���O
  );
  --EDI�`�F�[���X���i�[���R�[�h
  TYPE g_chain_rtype IS RECORD (
    chain_name               hz_parties.party_name%TYPE                          --EDI�`�F�[���X��
   ,chain_name_kana          hz_parties.organization_name_phonetic%TYPE          --EDI�`�F�[���X���J�i
  );
  --���b�Z�[�W���i�[���R�[�h
  TYPE g_msg_rtype IS RECORD (
    customer_notfound        fnd_new_messages.message_text%TYPE
   ,item_notfound            fnd_new_messages.message_text%TYPE
   ,header_type              fnd_new_messages.message_text%TYPE
   ,line_type                fnd_new_messages.message_text%TYPE
   ,order_source             fnd_new_messages.message_text%TYPE
  );
  --���̑����i�[���R�[�h
  TYPE g_other_rtype IS RECORD (
    proc_date                VARCHAR2(8)                                         --������
   ,proc_time                VARCHAR2(6)                                         --��������
   ,organization_id          NUMBER                                              --�݌ɑg�DID
   ,csv_header               VARCHAR2(32767)                                     --CSV�w�b�_
   ,process_date             DATE                                                --�Ɩ����t
-- ************ 2009/08/12 N.Maeda 1.11 ADD START ***************** --
   ,category_set_id          mtl_category_sets_tl.category_set_id%TYPE          --�J�e�S���Z�b�gID
-- ************ 2009/08/12 N.Maeda 1.11 ADD  END  ***************** --
  );
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gf_file_handle             UTL_FILE.FILE_TYPE;                                 --�t�@�C���n���h��
  g_input_rec                g_input_rtype;                                      --���̓p�����[�^���
  g_prf_rec                  g_prf_rtype;                                        --�v���t�@�C�����
  g_base_rec                 g_base_rtype;                                       --�[�i���_���
  g_chain_rec                g_chain_rtype;                                      --EDI�`�F�[���X���
  g_msg_rec                  g_msg_rtype;                                        --���b�Z�[�W���
  g_other_rec                g_other_rtype;                                      --���̑����
  g_record_layout_tab        xxcos_common2_pkg.g_record_layout_ttype;            --���C�A�E�g��`���
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_siege                   CONSTANT VARCHAR2(1) := CHR(34);                    --�_�u���N�H�[�e�[�V����
  cv_delimiter               CONSTANT VARCHAR2(1) := CHR(44);                    --�J���}
  cv_file_format             CONSTANT VARCHAR2(1) := xxcos_common2_pkg.gv_file_type_variable; --�ϒ�
  cv_layout_class            CONSTANT VARCHAR2(1) := xxcos_common2_pkg.gv_layout_class_order; --�󒍌n
  cv_publish                 CONSTANT VARCHAR2(1) := 'Y';                        --���s��
  cv_found                   CONSTANT VARCHAR2(1) := '0';                        --�o�^
  cv_notfound                CONSTANT VARCHAR2(1) := '1';                        --���o�^
  /**********************************************************************************
   * Procedure Name   : out_line
   * Description      : ���O�o��
   ***********************************************************************************/
  PROCEDURE out_line(which NUMBER DEFAULT FND_FILE.LOG,buff VARCHAR2)
  IS
    lv_debug boolean := false;
    lv_output boolean := false;
  BEGIN
-- 2009/02/13 T.Nakamura Ver.1.2 mod start
--    IF (lv_output) THEN
--      IF (lv_debug) THEN
--        dbms_output.put_line(buff);
--      ELSE
--        FND_FILE.PUT_LINE(
--           which  => which
--          ,buff   => buff
--        );
--      END IF;
--    END IF;
    NULL;
-- 2009/02/13 T.Nakamura Ver.1.2 mod end
  END out_line;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ���ʏ�������(A-0)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
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
--
  BEGIN
    out_line(buff => cv_prg_name || ' start');
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
-- 2009/02/12 T.Nakamura Ver.1.1 add start
    --�󔒍s�̏o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
-- 2009/02/12 T.Nakamura Ver.1.1 add end
    --==============================================================
    -- �R���J�����g�v���O�������͍��ڂ̏o��
    --==============================================================
    --���̓p�����[�^1�`10�̏o��
    gv_out_msg := xxccp_common_pkg.get_msg(cv_apl_name,ct_msg_input_parameters1
                                          ,cv_tkn_prm1 , g_input_rec.file_name
--******************************************* 2009/04/01 1.7 T.Kitajima ADD START *************************************
--                                          ,cv_tkn_prm2 , g_input_rec.chain_code
                                          ,cv_tkn_prm2, g_input_rec.ssm_store_code  --��ʑ��Œ��[�l���ƃ`�F�[���X���t�Ȃ���
--******************************************* 2009/04/01 1.7 T.Kitajima ADD  END  *************************************
                                          ,cv_tkn_prm3 , g_input_rec.report_code
                                          ,cv_tkn_prm4 , g_input_rec.user_id
                                          ,cv_tkn_prm5 , g_input_rec.chain_name
                                          ,cv_tkn_prm6 , g_input_rec.store_code
                                          ,cv_tkn_prm7 , g_input_rec.base_code
                                          ,cv_tkn_prm8 , g_input_rec.base_name
                                          ,cv_tkn_prm9 , g_input_rec.data_type_code
                                          ,cv_tkn_prm10, g_input_rec.ebs_business_series_code
                                          );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
-- 2009/02/12 T.Nakamura Ver.1.1 add start
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
-- 2009/02/12 T.Nakamura Ver.1.1 add end
--
    --���̓p�����[�^1�`17�̏o��
    gv_out_msg := xxccp_common_pkg.get_msg(cv_apl_name,ct_msg_input_parameters2
                                          ,cv_tkn_prm11, g_input_rec.info_div
                                          ,cv_tkn_prm12, g_input_rec.report_name
                                          ,cv_tkn_prm13, g_input_rec.shop_delivery_date_from
                                          ,cv_tkn_prm14, g_input_rec.shop_delivery_date_to
                                          ,cv_tkn_prm15, g_input_rec.edi_input_date
                                          ,cv_tkn_prm16, g_input_rec.publish_div
                                          ,cv_tkn_prm17, g_input_rec.publish_flag_seq
--******************************************* 2009/04/01 1.7 T.Kitajima ADD START *************************************
                                          ,cv_tkn_prm18, g_input_rec.chain_code   --��ʑ��Œ��[�l���ƃ`�F�[���X���t�Ȃ���
--******************************************* 2009/04/01 1.7 T.Kitajima ADD  END  *************************************
                                          );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
-- 2009/02/12 T.Nakamura Ver.1.1 add start
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
-- 2009/02/12 T.Nakamura Ver.1.1 add end
--
    --�󔒍s�̏o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
-- 2009/02/19 T.Nakamura Ver.1.5 add start
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
-- 2009/02/19 T.Nakamura Ver.1.5 add end
--
    --==============================================================
    -- �o�̓t�@�C�����̏o��
    --==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                    cv_apl_name
                   ,ct_msg_file_name
                   ,cv_tkn_filename
                   ,g_input_rec.file_name
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�󔒍s�̏o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      out_line(buff => cv_prg_name || ct_msg_part || sqlerrm);
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : proc_init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE proc_init(
    ov_errbuf     OUT VARCHAR2        --    �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2        --    ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2        --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
   )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_init'; -- �v���O������
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
    lb_error                                 BOOLEAN;                                               --�G���[�L��t���O
    lt_tkn                                   fnd_new_messages.message_text%TYPE;                    --���b�Z�[�W�p������
-- 2009/02/19 T.Nakamura Ver.1.5 add start
    lv_errbuf_all                            VARCHAR2(32767);                                       --���O�o�̓��b�Z�[�W�i�[�ϐ�
-- 2009/02/19 T.Nakamura Ver.1.5 add end
--
-- ************ 2009/08/13 N.Maeda 1.11 ADD START ***************** --
    lt_item_div_h                           fnd_profile_option_values.profile_option_value%TYPE;
-- ************ 2009/08/13 N.Maeda 1.11 ADD  END  ***************** --
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    l_prf_rec g_prf_rtype;
    l_other_rec g_other_rtype;
    l_record_layout_tab xxcos_common2_pkg.g_record_layout_ttype;
--
--
  BEGIN
    out_line(buff => cv_prg_name || ' start');
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --�G���[�t���O������
    lb_error := FALSE;
-- 2009/02/19 T.Nakamura Ver.1.5 add start
    lv_errbuf_all := NULL;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
--
    --==============================================================
    -- �v���t�@�C���̎擾(XXCCP:�w�b�_���R�[�h���ʎq)
    --==============================================================
    l_prf_rec.if_header := FND_PROFILE.VALUE(ct_prf_if_header);
    IF (l_prf_rec.if_header IS NULL) THEN
      lb_error := TRUE;
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_if_header);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_prf
                    ,cv_tkn_prf
                    ,lt_tkn
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
-- 2009/02/19 T.Nakamura Ver.1.5 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
    END IF;
--
    --==============================================================
    -- �v���t�@�C���̎擾(XXCCP:�f�[�^���R�[�h���ʎq)
    --==============================================================
    l_prf_rec.if_data := FND_PROFILE.VALUE(ct_prf_if_data);
    IF (l_prf_rec.if_data IS NULL) THEN
      lb_error := TRUE;
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_if_data);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_prf
                    ,cv_tkn_prf
                    ,lt_tkn
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
-- 2009/02/19 T.Nakamura Ver.1.5 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
    END IF;
--
    --==============================================================
    -- �v���t�@�C���̎擾(XXCCP:�t�b�^���R�[�h���ʎq)
    --==============================================================
    l_prf_rec.if_footer := FND_PROFILE.VALUE(ct_prf_if_footer);
    IF (l_prf_rec.if_footer IS NULL) THEN
      lb_error := TRUE;
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_if_footer);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_prf
                    ,cv_tkn_prf
                    ,lt_tkn
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
-- 2009/02/19 T.Nakamura Ver.1.5 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
    END IF;
--
    --==============================================================
    -- �v���t�@�C���̎擾(XXCOS:���[OUTBOUND�o�̓f�B���N�g��)
    --==============================================================
    l_prf_rec.rep_outbound_dir := FND_PROFILE.VALUE(ct_prf_rep_outbound_dir);
    IF (l_prf_rec.rep_outbound_dir IS NULL) THEN
      lb_error := TRUE;
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_rep_outbound_dir);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_prf
                    ,cv_tkn_prf
                    ,lt_tkn
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
-- 2009/02/19 T.Nakamura Ver.1.5 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
    END IF;
--
    --==============================================================
    -- �v���t�@�C���̎擾(XXCOS:��Ж�)
    --==============================================================
    l_prf_rec.company_name := FND_PROFILE.VALUE(ct_prf_company_name);
    IF (l_prf_rec.company_name IS NULL) THEN
      lb_error := TRUE;
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_company_name);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_prf
                    ,cv_tkn_prf
                    ,lt_tkn
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
-- 2009/02/19 T.Nakamura Ver.1.5 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
    END IF;
--
    --==============================================================
    -- �v���t�@�C���̎擾(XXCOS:��Ж��J�i)
    --==============================================================
    l_prf_rec.company_name_kana := FND_PROFILE.VALUE(ct_prf_company_name_kana);
    IF (l_prf_rec.company_name_kana IS NULL) THEN
      lb_error := TRUE;
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_company_name_kana);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_prf
                    ,cv_tkn_prf
                    ,lt_tkn
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
-- 2009/02/19 T.Nakamura Ver.1.5 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
    END IF;
--
    --==============================================================
    -- �v���t�@�C���̎擾(XXCOS:UTL_MAX�s�T�C�Y)
    --==============================================================
    l_prf_rec.utl_max_linesize := FND_PROFILE.VALUE(ct_prf_utl_max_linesize);
    IF (l_prf_rec.utl_max_linesize IS NULL) THEN
      lb_error := TRUE;
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_utl_max_linesize);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_prf
                    ,cv_tkn_prf
                    ,lt_tkn
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
-- 2009/02/19 T.Nakamura Ver.1.5 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
    END IF;
--
    --==============================================================
    -- �v���t�@�C���̎擾(XXCOI:�݌ɑg�D�R�[�h)
    --==============================================================
    l_prf_rec.organization_code := FND_PROFILE.VALUE(ct_prf_organization_code);
    IF (l_prf_rec.organization_code IS NULL) THEN
      lb_error := TRUE;
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_organization_code);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_prf
                    ,cv_tkn_prf
                    ,lt_tkn
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
-- 2009/02/19 T.Nakamura Ver.1.5 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
    END IF;
--
    --==============================================================
    -- �v���t�@�C���̎擾(XXCOS:�P�[�X�P�ʃR�[�h)
    --==============================================================
    l_prf_rec.case_uom_code := FND_PROFILE.VALUE(ct_prf_case_uom_code);
    IF (l_prf_rec.case_uom_code IS NULL) THEN
      lb_error := TRUE;
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_case_uom_code);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_prf
                    ,cv_tkn_prf
                    ,lt_tkn
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
-- 2009/02/19 T.Nakamura Ver.1.5 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
    END IF;
--
    --==============================================================
    -- �v���t�@�C���̎擾(XXCOS:�{�[���P�ʃR�[�h)
    --==============================================================
    l_prf_rec.bowl_uom_code := FND_PROFILE.VALUE(ct_prf_bowl_uom_code);
    IF (l_prf_rec.bowl_uom_code IS NULL) THEN
      lb_error := TRUE;
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_bowl_uom_code);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_prf
                    ,cv_tkn_prf
                    ,lt_tkn
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
-- 2009/02/19 T.Nakamura Ver.1.5 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
    END IF;
--
    --==============================================================
    -- �v���t�@�C���̎擾(XXCOS:�x�X���R�[�h)
    --==============================================================
    l_prf_rec.base_manager_code := FND_PROFILE.VALUE(ct_prf_base_manager_code);
    IF (l_prf_rec.base_manager_code IS NULL) THEN
      lb_error := TRUE;
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_base_manager_code);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_prf
                    ,cv_tkn_prf
                    ,lt_tkn
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
-- 2009/02/19 T.Nakamura Ver.1.5 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
    END IF;
--
    --==============================================================
    -- �v���t�@�C���̎擾(XXCOS:���ʒ��[�l���p�`�F�[���X�R�[�h)
    --==============================================================
    l_prf_rec.cmn_rep_chain_code := FND_PROFILE.VALUE(ct_prf_cmn_rep_chain_code);
    IF (l_prf_rec.cmn_rep_chain_code IS NULL) THEN
      lb_error := TRUE;
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_cmn_rep_chain_code);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_prf
                    ,cv_tkn_prf
                    ,lt_tkn
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
-- 2009/02/19 T.Nakamura Ver.1.5 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
    END IF;
--
    --==============================================================
    -- �v���t�@�C���̎擾(GL��v����ID)
    --==============================================================
    l_prf_rec.set_of_books_id := FND_PROFILE.VALUE(ct_prf_set_of_books_id);
    IF (l_prf_rec.set_of_books_id IS NULL) THEN
      lb_error := TRUE;
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_set_of_books_id);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_prf
                    ,cv_tkn_prf
                    ,lt_tkn
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
-- 2009/02/19 T.Nakamura Ver.1.5 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
    END IF;
    --==============================================================
    -- �������t�A���������̎擾
    --==============================================================
    l_other_rec.proc_date := TO_CHAR(SYSDATE, cv_date_fmt);
    l_other_rec.proc_time := TO_CHAR(SYSDATE, cv_time_fmt);
    l_other_rec.process_date := TRUNC(xxccp_common_pkg2.get_process_date);
--
    --==============================================================
    -- �݌ɑg�DID�̎擾
    --==============================================================
    IF (l_prf_rec.organization_code IS NOT NULL) THEN
      l_other_rec.organization_id := xxcoi_common_pkg.get_organization_id(l_prf_rec.organization_code);
      IF (l_other_rec.organization_id IS NULL) THEN
        lb_error := TRUE;
        lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_org_id);
        lv_errmsg := xxccp_common_pkg.get_msg(
                       cv_apl_name
                      ,ct_msg_get_err
                      ,cv_tkn_data
                      ,lt_tkn
                     );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
-- 2009/02/19 T.Nakamura Ver.1.5 add start
        lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
      END IF;
    END IF;
--
-- 2009/02/16 T.Nakamura Ver.1.3 add start
    --==============================================================
    -- �v���t�@�C���̎擾(MO:�c�ƒP��)
    --==============================================================
    l_prf_rec.org_id := FND_PROFILE.VALUE(ct_prf_org_id);
    IF (l_prf_rec.org_id IS NULL) THEN
      lb_error := TRUE;
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_mo_org_id);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_prf
                    ,cv_tkn_prf
                    ,lt_tkn
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
-- 2009/02/19 T.Nakamura Ver.1.5 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
    END IF;
--
-- 2009/02/16 T.Nakamura Ver.1.3 add end
    --==============================================================
    --���C�A�E�g��`���̎擾
    --==============================================================
    xxcos_common2_pkg.get_layout_info(
      cv_file_format                              --�t�@�C���`��
     ,cv_layout_class                             --���C�A�E�g�敪
     ,l_record_layout_tab                         --���C�A�E�g��`���
     ,l_other_rec.csv_header                      --CSV�w�b�_
     ,lv_errbuf                                   --�G���[���b�Z�[�W
     ,lv_retcode                                  --���^�[���R�[�h
     ,lv_errmsg                                   --���[�U�E�G���[���b�Z�[�W
    );
    IF (lv_retcode != cv_status_normal) THEN
      lb_error := TRUE;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
-- 2009/02/19 T.Nakamura Ver.1.5 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
    END IF;
--
    IF (lb_error) THEN
      lv_errmsg := NULL;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�̎擾
    --==============================================================
    --�ڋq�}�X�^���o�^���b�Z�[�W�擾
    lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_cust_master);
    g_msg_rec.customer_notfound := xxccp_common_pkg.get_msg(
                                     cv_apl_name
                                    ,ct_msg_master_notfound
                                    ,cv_tkn_table
                                    ,lt_tkn
                                   );
--
    --�i�ڃ}�X�^���o�^���b�Z�[�W�擾
    lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_item_master);
    g_msg_rec.item_notfound := xxccp_common_pkg.get_msg(
                                     cv_apl_name
                                    ,ct_msg_master_notfound
                                    ,cv_tkn_table
                                    ,lt_tkn
                                   );
--
-- ************ 2009/08/13 N.Maeda 1.11 ADD START ***************** --
    -- =============================================================
    -- �v���t�@�C���uXXCOS:�{�Џ��i�敪�v�擾
    -- =============================================================
    lt_item_div_h := FND_PROFILE.VALUE(ct_item_div_h);
--
    IF ( lt_item_div_h IS NULL ) THEN
        lb_error := TRUE;
        lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, cv_msg_item_div_h);
        lv_errmsg := xxccp_common_pkg.get_msg(
                       cv_apl_name
                      ,ct_msg_prf
                      ,cv_tkn_prf
                      ,lt_tkn
                     );
        lv_errbuf_all := lv_errmsg;
        RAISE global_api_expt;
-- ************ 2009/08/13 N.Maeda 1.11 ADD  END  ***************** --
--
-- ************ 2009/08/12 N.Maeda 1.11 ADD START ***************** --
    ELSE
    -- =============================================================
    -- �J�e�S���Z�b�gID�擾
    -- =============================================================
      BEGIN
-- ************ 2009/08/13 N.Maeda 1.11 MOD START ***************** --
        SELECT  mcst.category_set_id
        INTO    l_other_rec.category_set_id
        FROM    mtl_category_sets_tl   mcst
        WHERE   mcst.category_set_name = lt_item_div_h
        AND     mcst.language          = ct_user_lang;
--      SELECT  mcst.category_set_id
--      INTO    l_other_rec.category_set_id
--      FROM    mtl_category_sets_tl   mcst
--      WHERE   mcst.category_set_name = FND_PROFILE.VALUE(ct_item_div_h)
--      AND     mcst.language          = ct_user_lang;
-- ************ 2009/08/13 N.Maeda 1.11 MOD  END  ***************** --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg  :=  xxccp_common_pkg.get_msg(
                           iv_application  =>  cv_apl_name,
                           iv_name         =>  cv_msg_category_err
                           );
          lv_errbuf_all := lv_errmsg;
          RAISE global_api_expt;
      END;
    END IF;
-- ************ 2009/08/12 N.Maeda 1.11 ADD  END  ***************** --
    --==============================================================
    --�O���[�o���ϐ��̃Z�b�g
    --==============================================================
    g_prf_rec := l_prf_rec;
    g_other_rec := l_other_rec;
    g_record_layout_tab := l_record_layout_tab;
--
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 mod start
--      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf,1,5000);
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf_all,1,5000);
-- 2009/02/19 T.Nakamura Ver.1.5 mod end
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_init;
--
  /**********************************************************************************
   * Procedure Name   : proc_out_header_record
   * Description      : �w�b�_���R�[�h�쐬����(A-2)
   ***********************************************************************************/
  PROCEDURE proc_out_header_record(
    ov_errbuf     OUT VARCHAR2      --    �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2      --    ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2      --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_out_header_record'; -- �v���O������
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
    lv_if_header VARCHAR2(32767);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
    out_line(buff => cv_prg_name || ' start');
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--

    --==============================================================
    -- �t�@�C���I�[�v��
    --==============================================================
    BEGIN
      gf_file_handle := UTL_FILE.FOPEN(
                          g_prf_rec.rep_outbound_dir
                         ,g_input_rec.file_name
                         ,cv_utl_file_mode
                         ,g_prf_rec.utl_max_linesize
                        );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       cv_apl_name
                      ,ct_msg_fopen_err
                      ,cv_tkn_filename
                      ,g_input_rec.file_name
                     );
        lv_errbuf := SQLERRM;
        RAISE global_api_expt;
    END;
--
    --==============================================================
    -- �w�b�_���R�[�h�ݒ�l�擾
    --==============================================================
    xxccp_ifcommon_pkg.add_chohyo_header_footer(
      g_prf_rec.if_header                         --�t�^�敪
     ,g_input_rec.ebs_business_series_code        --�h�e���Ɩ��n��R�[�h
     ,g_input_rec.base_code                       --���_�R�[�h
     ,g_input_rec.base_name                       --���_����
--******************************************* 2009/04/01 1.7 T.Kitajima MOD START *************************************
--     ,g_input_rec.chain_code                      --�`�F�[���X�R�[�h
     ,g_input_rec.ssm_store_code                    --���[�l���`�F�[���X�R�[�h
--******************************************* 2009/04/01 1.7 T.Kitajima MOD  END  *************************************
     ,g_input_rec.chain_name                      --�`�F�[���X����
     ,g_input_rec.data_type_code                  --�f�[�^��R�[�h
     ,g_input_rec.report_code                     --���[�R�[�h
     ,g_input_rec.report_name                     --���[�\����
     ,g_record_layout_tab.COUNT                   --���ڐ�
     ,NULL                                        --�f�[�^����
     ,lv_retcode                                  --���^�[���R�[�h
     ,lv_if_header                                --�o�͒l
     ,lv_errbuf                                   --�G���[���b�Z�[�W
     ,lv_errmsg                                   --���[�U�[�E�G���[���b�Z�[�W
    );
    IF (lv_retcode = cv_status_error) THEN
-- 2009/02/19 T.Nakamura Ver.1.5 add start
      lv_errbuf := lv_errbuf || ct_msg_part || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- �w�b�_���R�[�h�o��
    --==============================================================
    UTL_FILE.PUT_LINE(gf_file_handle,lv_if_header);
--
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_out_header_record;
--
  /**********************************************************************************
   * Procedure Name   : proc_out_csv_header
   * Description      : CSV�w�b�_���R�[�h�쐬����(A-4)
   ***********************************************************************************/
  PROCEDURE proc_out_csv_header(
    ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
   )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_out_csv_header'; -- �v���O������
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
   lv_csv_header VARCHAR2(32767);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
    out_line(buff => cv_prg_name || ' start');
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --CSV�w�b�_���R�[�h�̐擪�Ƀf�[�^���R�[�h���ʎq��t��
    lv_csv_header := cv_siege || g_prf_rec.if_data || cv_siege || cv_delimiter ||
                     g_other_rec.csv_header;
--
    --CSV�w�b�_���R�[�h�̏o��
    UTL_FILE.PUT_LINE(gf_file_handle, g_other_rec.csv_header);
--
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_out_csv_header;
--
  /**********************************************************************************
   * Procedure Name   : proc_out_data_record
   * Description      : �f�[�^���R�[�h�쐬����(A-5)
   ***********************************************************************************/
  PROCEDURE proc_out_data_record(
    it_header_id  IN  oe_order_headers_all.header_id%TYPE
   ,i_data_tab    IN  xxcos_common2_pkg.g_layout_ttype
   ,ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_out_data_record'; -- �v���O������
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
    lv_data_record VARCHAR2(32767);
    lv_table_name  all_tables.table_name%TYPE;
    lv_key_info VARCHAR2(100);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
    out_line(buff => cv_prg_name || ' start');
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    --�f�[�^���R�[�h�ҏW
    --==============================================================
    xxcos_common2_pkg.makeup_data_record(
      i_data_tab                --�o�̓f�[�^���
     ,cv_file_format            --�t�@�C���`��
     ,g_record_layout_tab       --���C�A�E�g��`���
     ,g_prf_rec.if_data         --�f�[�^���R�[�h���ʎq
     ,lv_data_record            --�f�[�^���R�[�h
     ,lv_errbuf                 --�G���[���b�Z�[�W
     ,lv_retcode                --���^�[���R�[�h
     ,lv_errmsg                 --���[�U�E�G���[���b�Z�[�W
    );
-- 2009/02/20 T.Nakamura Ver.1.6 add start
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
-- 2009/02/20 T.Nakamura Ver.1.6 add end
--
    --==============================================================
    --�f�[�^���R�[�h�o��
    --==============================================================
    UTL_FILE.PUT_LINE(gf_file_handle,lv_data_record);
--
    --==============================================================
    --���R�[�h�����C���N�������g
    --==============================================================
    gn_target_cnt := gn_target_cnt + 1;
    gn_normal_cnt := gn_normal_cnt + 1;
--
    --==============================================================
    --�[�i�����s�t���O�X�V
    --==============================================================
    BEGIN
--****************************** 2009/04/01 1.7 T.Kitajima MOD START ******************************--
--      IF (g_input_rec.report_code = g_prf_rec.cmn_rep_chain_code) THEN
      IF (g_input_rec.chain_code = g_prf_rec.cmn_rep_chain_code) THEN
--****************************** 2009/04/01 1.7 T.Kitajima MOD START ******************************--
        --���ʒ��[�l���̏ꍇ
/* 2009/06/11 Ver1.10 Mod Start */
--        UPDATE oe_order_headers_all ooha
--        SET ooha.global_attribute1 = xxcos_common2_pkg.get_deliv_slip_flag_area(
--                                      g_input_rec.publish_flag_seq
--                                      ,ooha.global_attribute1
--                                      ,cv_publish
--                                     )
--        WHERE ooha.header_id = it_header_id
        UPDATE xxcos_edi_headers xeh
        SET    xeh.deliv_slip_flag_area_cmn = xxcos_common2_pkg.get_deliv_slip_flag_area(
                                                g_input_rec.publish_flag_seq
                                               ,xeh.deliv_slip_flag_area_cmn
                                               ,cv_publish
                                              )
        WHERE  xeh.edi_header_info_id = it_header_id
/* 2009/06/11 Ver1.10 Mod End   */
        ;
      ELSE
        --�`�F�[���X�ŗL�l���̏ꍇ
/* 2009/06/11 Ver1.10 Mod Start */
--        UPDATE oe_order_headers_all ooha
--        SET ooha.global_attribute2 = xxcos_common2_pkg.get_deliv_slip_flag_area(
--                                      g_input_rec.publish_flag_seq
--                                      ,ooha.global_attribute2
--                                      ,cv_publish
--                                     )
--        WHERE ooha.header_id = it_header_id
        UPDATE xxcos_edi_headers xeh
        SET    xeh.deliv_slip_flag_area_chain = xxcos_common2_pkg.get_deliv_slip_flag_area(
                                                g_input_rec.publish_flag_seq
                                               ,xeh.deliv_slip_flag_area_chain
                                               ,cv_publish
                                              )
        WHERE  xeh.edi_header_info_id = it_header_id
/* 2009/06/11 Ver1.10 Mod End   */
        ;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := SQLERRM;
        RAISE update_expt;
    END;
--
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
    WHEN update_expt THEN
      lv_table_name := xxccp_common_pkg.get_msg(
                         iv_application   => cv_apl_name
/* 2009/06/11 Ver1.10 Mod Start */
--                        ,iv_name          => ct_msg_oe_header
                        ,iv_name          => ct_msg_edi_header
/* 2009/06/11 Ver1.10 Mod End   */
                       );
      --�L�[���ҏW
      xxcos_common_pkg.makeup_key_info(
        ov_errbuf      => lv_errbuf                --�G���[�E���b�Z�[�W
       ,ov_retcode     => lv_retcode               --���^�[���E�R�[�h
       ,ov_errmsg      => lv_errmsg                --���[�U�[�E�G���[�E���b�Z�[�W
       ,ov_key_info    => lv_key_info              --�L�[���
       ,iv_item_name1  => ct_msg_invoice_number
       ,iv_data_value1 => i_data_tab('invoice_number')
      );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_update_err
                    ,cv_tkn_table
                    ,lv_table_name
                    ,cv_tkn_key
                    ,lv_key_info
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_out_data_record;
--
  /**********************************************************************************
   * Procedure Name   : proc_out_footer_record
   * Description      : �t�b�^���R�[�h�쐬����(A-6)
   ***********************************************************************************/
  PROCEDURE proc_out_footer_record(
    ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_out_footer_record'; -- �v���O������
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
    lv_footer_record VARCHAR2(32767);
    ln_rec_cnt       NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
    out_line(buff => cv_prg_name || ' start');
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    IF gn_target_cnt > 0 THEN
      ln_rec_cnt := gn_target_cnt + 1;
    ELSE
      ln_rec_cnt := 0;
    END IF;
    --==============================================================
    --�t�b�^���R�[�h�擾
    --==============================================================
    xxccp_ifcommon_pkg.add_chohyo_header_footer(
      g_prf_rec.if_footer         --�t�^�敪
     ,NULL                        --IF���Ɩ��n��R�[�h
     ,NULL                        --���_�R�[�h
     ,NULL                        --���_����
     ,NULL                        --�`�F�[���X�R�[�h
     ,NULL                        --�`�F�[���X����
     ,NULL                        --�f�[�^��R�[�h
     ,NULL                        --���[�R�[�h
     ,NULL                        --���[�\����
     ,NULL                        --���ڐ�
     ,ln_rec_cnt                  --���R�[�h����
     ,lv_retcode                  --���^�[���R�[�h
     ,lv_footer_record            --�o�͒l
-- 2009/02/20 T.Nakamura Ver.1.6 mod start
--     ,ov_errbuf                   --�G���[���b�Z�[�W
--     ,ov_errmsg                   --���[�U�E�G���[���b�Z�[�W
     ,lv_errbuf
     ,lv_errmsg
-- 2009/02/20 T.Nakamura Ver.1.6 mod end
    );
-- 2009/02/20 T.Nakamura Ver.1.6 add start
    IF (lv_retcode = cv_status_error) THEN
      lv_errbuf := lv_errbuf || ct_msg_part || lv_errmsg;
      RAISE global_api_expt;
    END IF;
-- 2009/02/20 T.Nakamura Ver.1.6 add end
--
    --==============================================================
    --�t�b�^���R�[�h�o��
    --==============================================================
    UTL_FILE.PUT_LINE(gf_file_handle, lv_footer_record);
--
    --==============================================================
    --�t�@�C���N���[�Y
    --==============================================================
    UTL_FILE.FCLOSE(gf_file_handle);
--
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_out_footer_record;
--
  /**********************************************************************************
   * Procedure Name   : proc_get_data
   * Description      : �f�[�^�擾����(A-3)
   ***********************************************************************************/
  PROCEDURE proc_get_data(
    ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_get_data'; -- �v���O������
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
/* 2009/06/11 Ver1.10 Mod Start */
--    lt_header_id            oe_order_headers_all.header_id%TYPE;   --�w�b�_ID
    lt_header_id            xxcos_edi_headers.edi_header_info_id%TYPE; --EDI�w�b�_���ID
/* 2009/06/11 Ver1.10 Mod End   */
    lt_tkn                  fnd_new_messages.message_text%TYPE;    --���b�Z�[�W�p������
    lt_bargain_class        fnd_lookup_values.attribute8%TYPE;     --��ԓ����敪
    lt_last_bargain_class   fnd_lookup_values.attribute8%TYPE;     --�O���ԓ����敪
/* 2009/06/11 Ver1.10 Mod Start */
--    lt_last_invoice_number  xxcos_edi_headers.invoice_number%TYPE; --�O��`�[�ԍ�
    lt_last_header_id       xxcos_edi_headers.edi_header_info_id%TYPE; --�O��w�b�_ID
/* 2009/06/11 Ver1.10 Mod End   */
    lt_outbound_flag        fnd_lookup_values.attribute10%TYPE;    --OUTBOUND��
    lb_error                BOOLEAN;
    lb_mix_error_order      BOOLEAN;
    lb_out_flag_error_order BOOLEAN;
-- 2009/02/19 T.Nakamura Ver.1.5 add start
    lv_errbuf_all                      VARCHAR2(32767);            --���O�o�̓��b�Z�[�W�i�[�ϐ�
-- 2009/02/19 T.Nakamura Ver.1.5 add end
    lv_data                 VARCHAR2(1);
-- 2019/06/25 V1.22 N.Miyamoto ADD START
    lt_conv_customer_code   xxcos_edi_headers.conv_customer_code%TYPE;
    lt_bill_tax_round_rule  xxcos_cust_hierarchy_v.bill_tax_round_rule%TYPE;
    ln_order_cost_amt       NUMBER;
    ln_tax_rate             NUMBER;
    ln_general_add_item10   NUMBER;
-- 2019/06/25 V1.22 N.Miyamoto ADD END
--
--******************************************* 2009/06/18 1.11 N.Maeda MOD START ************************************************--
    -- *** ���[�J���E�J�[�\�� ***
--    CURSOR cur_data_record(i_input_rec    g_input_rtype
--                          ,i_prf_rec      g_prf_rtype
--                          ,i_base_rec     g_base_rtype
--                          ,i_chain_rec    g_chain_rtype
--                          ,i_msg_rec      g_msg_rtype
--                          ,i_other_rec    g_other_rtype
--    )
--    IS
--/* 2009/06/11 Ver1.10 Mod Start */
----      SELECT TO_CHAR(ooha.header_id)                                            header_id                     --�w�b�_ID(�X�V�L�[)
----            ,xlvv.attribute8                                                    bargain_class                 --��ԓ����敪
----            ,xlvv.attribute10                                                   outbound_flag                 --OUTBOUND��
--      SELECT xeh.edi_header_info_id                                             header_id                     --�w�b�_ID(�X�V�L�[)
--            ,ixe.bargain_class                                                  bargain_class                 --��ԓ����敪
--            ,ixe.outbound_flag                                                  outbound_flag                 --OUTBOUND��
--/* 2009/06/11 Ver1.10 Mod End   */
--            ------------------------------------------------�w�b�_���------------------------------------------------
--            ,xeh.medium_class                                                   medium_class                  --�}�̋敪
--            ,xeh.data_type_code                                                 data_type_code                --�f�[�^��R�[�h
--            ,xeh.file_no                                                        file_no                       --�t�@�C���m��
--            ,xeh.info_class                                                     info_class                    --���敪
--            ,i_other_rec.proc_date                                              process_date                  --������
--            ,i_other_rec.proc_time                                              process_time                  --��������
----******************************************* 2009/04/02 1.8 T.Kitajima MOD START *************************************
----            ,i_input_rec.base_code                                              base_code                     --���_�i����j�R�[�h
----            ,i_base_rec.base_name                                               base_name                     --���_���i�������j
----            ,i_base_rec.base_name_kana                                          base_name_alt                 --���_���i�J�i�j
--            ,cdm.account_number                                                 base_code                     --���_�i����j�R�[�h
--            ,DECODE( cdm.account_number
--                    ,NULL,g_msg_rec.customer_notfound
--                    ,cdm.base_name)                                             base_name                     --���_���i�������j
--            ,cdm.base_name_kana                                                 base_name_alt                 --���_���i�J�i�j
----******************************************* 2009/04/02 1.8 T.Kitajima MOD  END  *************************************
--            ,xeh.edi_chain_code                                                 edi_chain_code                --�d�c�h�`�F�[���X�R�[�h
--            ,i_chain_rec.chain_name                                             edi_chain_name                --�d�c�h�`�F�[���X���i�����j
--            ,i_chain_rec.chain_name_kana                                        edi_chain_name_alt            --�d�c�h�`�F�[���X���i�J�i�j
--            ,xeh.chain_code                                                     chain_code                    --�`�F�[���X�R�[�h
--            ,xeh.chain_name                                                     chain_name                    --�`�F�[���X���i�����j
--            ,xeh.chain_name_alt                                                 chain_name_alt                --�`�F�[���X���i�J�i�j
--            ,i_input_rec.report_code                                            report_code                   --���[�R�[�h
--            ,i_input_rec.report_name                                            report_name                   --���[�\����
--            ,hca.account_number                                                 customer_code                 --�ڋq�R�[�h
--            ,hp.party_name                                                      customer_name                 --�ڋq���i�����j
--            ,hp.organization_name_phonetic                                      customer_name_alt             --�ڋq���i�J�i�j
--            ,xeh.company_code                                                   company_code                  --�ЃR�[�h
--            ,xeh.company_name                                                   company_name                  --�Ж��i�����j
--            ,xeh.company_name_alt                                               company_name_alt              --�Ж��i�J�i�j
--            ,xeh.shop_code                                                      shop_code                     --�X�R�[�h
--            ,NVL(xeh.shop_name,NVL(xca.cust_store_name
--                                  ,i_msg_rec.customer_notfound))                shop_name                     --�X���i�����j
--            ,NVL(xeh.shop_name_alt,hp.organization_name_phonetic)               shop_name_alt                 --�X���i�J�i�j
--            ,NVL(xeh.delivery_center_code,xca.deli_center_code)                 delivery_center_code          --�[���Z���^�[�R�[�h
--            ,NVL(delivery_center_name,xca.deli_center_name)                     delivery_center_name          --�[���Z���^�[���i�����j
--            ,xeh.delivery_center_name_alt                                       delivery_center_name_alt      --�[���Z���^�[���i�J�i�j
--            ,TO_CHAR(xeh.order_date,cv_date_fmt)                                order_date                    --������
--            ,TO_CHAR(xeh.center_delivery_date,cv_date_fmt)                      center_delivery_date          --�Z���^�[�[�i��
--            ,TO_CHAR(xeh.result_delivery_date,cv_date_fmt)                      result_delivery_date          --���[�i��
--            ,TO_CHAR(xeh.shop_delivery_date,cv_date_fmt)                        shop_delivery_date            --�X�ܔ[�i��
--            ,TO_CHAR(xeh.data_creation_date_edi_data,cv_date_fmt)               data_creation_date_edi_data   --�f�[�^�쐬���i�d�c�h�f�[�^���j
--            ,xeh.data_creation_time_edi_data                                    data_creation_time_edi_data   --�f�[�^�쐬�����i�d�c�h�f�[�^���j
--            ,xeh.invoice_class                                                  invoice_class                 --�`�[�敪
--            ,xeh.small_classification_code                                      small_classification_code     --�����ރR�[�h
--            ,xeh.small_classification_name                                      small_classification_name     --�����ޖ�
--            ,xeh.middle_classification_code                                     middle_classification_code    --�����ރR�[�h
--            ,xeh.middle_classification_name                                     middle_classification_name    --�����ޖ�
--            ,xeh.big_classification_code                                        big_classification_code       --�啪�ރR�[�h
--            ,xeh.big_classification_name                                        big_classification_name       --�啪�ޖ�
--            ,xeh.other_party_department_code                                    other_party_department_code   --����敔��R�[�h
--            ,xeh.other_party_order_number                                       other_party_order_number      --����攭���ԍ�
--            ,xeh.check_digit_class                                              check_digit_class             --�`�F�b�N�f�W�b�g�L���敪
--            ,xeh.invoice_number                                                 invoice_number                --�`�[�ԍ�
--            ,xeh.check_digit                                                    check_digit                   --�`�F�b�N�f�W�b�g
--            ,TO_CHAR(xeh.close_date, cv_date_fmt)                               close_date                    --����
--/* 2009/06/11 Ver1.10 Mod Start */
----            ,ooha.order_number                                                  order_no_ebs                  --�󒍂m���i�d�a�r�j
--            ,ixe.order_number                                                   order_no_ebs                  --�󒍂m���i�d�a�r�j
--/* 2009/06/11 Ver1.10 Mod End   */
--            ,xeh.ar_sale_class                                                  ar_sale_class                 --�����敪
--            ,xeh.delivery_classe                                                delivery_classe               --�z���敪
--            ,xeh.opportunity_no                                                 opportunity_no                --�ւm��
----******************************************* 2009/04/02 1.8 T.Kitajima MOD START *************************************
----            ,NVL(xeh.contact_to, i_base_rec.phone_number)                       contact_to                    --�A����
--            ,NVL(xeh.contact_to, cdm.phone_number)                              contact_to                    --�A����
----******************************************* 2009/04/02 1.8 T.Kitajima MOD  END  *************************************
--            ,xeh.route_sales                                                    route_sales                   --���[�g�Z�[���X
--            ,xeh.corporate_code                                                 corporate_code                --�@�l�R�[�h
--            ,xeh.maker_name                                                     maker_name                    --���[�J�[��
--            ,xeh.area_code                                                      area_code                     --�n��R�[�h
--            ,NVL2(xeh.area_code,xca.edi_district_name,NULL)                     area_name                     --�n�於�i�����j
--            ,NVL2(xeh.area_code,xca.edi_district_kana,NULL)                     area_name_alt                 --�n�於�i�J�i�j
--            ,NVL(xeh.vendor_code,xca.torihikisaki_code)                         vendor_code                   --�����R�[�h
----******************************************* 2009/04/02 1.8 T.Kitajima MOD START *************************************
----            ,DECODE(i_base_rec.notfound_flag
----                   ,cv_notfound,i_base_rec.base_name
----                   ,cv_found,i_prf_rec.company_name || cv_space ||  i_base_rec.base_name)    vendor_name
----            ,CASE
----               WHEN xeh.vendor_name1_alt IS NULL
----                AND xeh.vendor_name2_alt IS NULL THEN
----                 i_prf_rec.company_name_kana
----               ELSE
----                 xeh.vendor_name1_alt
----             END                                                                vendor_name1_alt              --����於�P�i�J�i�j
----            ,CASE
----               WHEN xeh.vendor_name1_alt IS NULL
----                AND xeh.vendor_name2_alt IS NULL THEN
----                 i_base_rec.base_name_kana
----               ELSE
----                 xeh.vendor_name2_alt
----             END                                                                vendor_name2_alt              --����於�Q�i�J�i�j
----            ,i_base_rec.phone_number                                            vendor_tel                    --�����s�d�k
----            ,NVL(xeh.vendor_charge, i_base_rec.manager_name_kana)               vendor_charge                 --�����S����
----            ,i_base_rec.state ||
----             i_base_rec.city ||
----             i_base_rec.address1 ||
----             i_base_rec.address2                                                vendor_address                --�����Z���i�����j
--            ,DECODE(cdm.account_number
--                   ,NULL,g_msg_rec.customer_notfound
--                   ,i_prf_rec.company_name || cv_space ||  cdm.base_name)    vendor_name
--            ,CASE
--               WHEN xeh.vendor_name1_alt IS NULL
--                AND xeh.vendor_name2_alt IS NULL THEN
--                 i_prf_rec.company_name_kana
--               ELSE
--                 xeh.vendor_name1_alt
--             END                                                                vendor_name1_alt              --����於�P�i�J�i�j
--            ,CASE
--               WHEN xeh.vendor_name1_alt IS NULL
--                AND xeh.vendor_name2_alt IS NULL THEN
--                 cdm.base_name_kana
--               ELSE
--                 xeh.vendor_name2_alt
--             END                                                                vendor_name2_alt              --����於�Q�i�J�i�j
--            ,cdm.phone_number                                                   vendor_tel                    --�����s�d�k
--            ,NVL(xeh.vendor_charge, i_base_rec.manager_name_kana)               vendor_charge                 --�����S����
--            ,cdm.state    ||
--             cdm.city     ||
--             cdm.address1 ||
--             cdm.address2                                                       vendor_address                --�����Z���i�����j
----******************************************* 2009/04/02 1.8 T.Kitajima MOD  END  *************************************
--            ,xeh.deliver_to_code_itouen                                         deliver_to_code_itouen        --�͂���R�[�h�i�ɓ����j
--            ,xeh.deliver_to_code_chain                                          deliver_to_code_chain         --�͂���R�[�h�i�`�F�[���X�j
--            ,xeh.deliver_to                                                     deliver_to                    --�͂���i�����j
--            ,xeh.deliver_to1_alt                                                deliver_to1_alt               --�͂���P�i�J�i�j
--            ,xeh.deliver_to2_alt                                                deliver_to2_alt               --�͂���Q�i�J�i�j
--            ,xeh.deliver_to_address                                             deliver_to_address            --�͂���Z���i�����j
--            ,xeh.deliver_to_address_alt                                         deliver_to_address_alt        --�͂���Z���i�J�i�j
--            ,xeh.deliver_to_tel                                                 deliver_to_tel                --�͂���s�d�k
--            ,xeh.balance_accounts_code                                          balance_accounts_code         --������R�[�h
--            ,xeh.balance_accounts_company_code                                  balance_accounts_company_code --������ЃR�[�h
--            ,xeh.balance_accounts_shop_code                                     balance_accounts_shop_code    --������X�R�[�h
--            ,xeh.balance_accounts_name                                          balance_accounts_name         --�����於�i�����j
--            ,xeh.balance_accounts_name_alt                                      balance_accounts_name_alt     --�����於�i�J�i�j
--            ,xeh.balance_accounts_address                                       balance_accounts_address      --������Z���i�����j
--            ,xeh.balance_accounts_address_alt                                   balance_accounts_address_alt  --������Z���i�J�i�j
--            ,xeh.balance_accounts_tel                                           balance_accounts_tel          --������s�d�k
--            ,TO_CHAR(xeh.order_possible_date, cv_date_fmt)                      order_possible_date           --�󒍉\��
--            ,TO_CHAR(xeh.permission_possible_date, cv_date_fmt)                 permission_possible_date      --���e�\��
--            ,TO_CHAR(xeh.forward_month, cv_date_fmt)                            forward_month                 --����N����
--            ,TO_CHAR(xeh.payment_settlement_date, cv_date_fmt)                  payment_settlement_date       --�x�����ϓ�
--            ,TO_CHAR(xeh.handbill_start_date_active, cv_date_fmt)               handbill_start_date_active    --�`���V�J�n��
--            ,TO_CHAR(xeh.billing_due_date, cv_date_fmt)                         billing_due_date              --��������
--            ,xeh.shipping_time                                                  shipping_time                 --�o�׎���
--            ,xeh.delivery_schedule_time                                         delivery_schedule_time        --�[�i�\�莞��
--            ,xeh.order_time                                                     order_time                    --��������
--            ,TO_CHAR(xeh.general_date_item1, cv_date_fmt)                       general_date_item1            --�ėp���t���ڂP
--            ,TO_CHAR(xeh.general_date_item2, cv_date_fmt)                       general_date_item2            --�ėp���t���ڂQ
--            ,TO_CHAR(xeh.general_date_item3, cv_date_fmt)                       general_date_item3            --�ėp���t���ڂR
--            ,TO_CHAR(xeh.general_date_item4, cv_date_fmt)                       general_date_item4            --�ėp���t���ڂS
--            ,TO_CHAR(xeh.general_date_item5, cv_date_fmt)                       general_date_item5            --�ėp���t���ڂT
--            ,xeh.arrival_shipping_class                                         arrival_shipping_class        --���o�׋敪
--            ,xeh.vendor_class                                                   vendor_class                  --�����敪
--            ,xeh.invoice_detailed_class                                         invoice_detailed_class        --�`�[����敪
--            ,xeh.unit_price_use_class                                           unit_price_use_class          --�P���g�p�敪
--            ,xeh.sub_distribution_center_code                                   sub_distribution_center_code  --�T�u�����Z���^�[�R�[�h
--            ,xeh.sub_distribution_center_name                                   sub_distribution_center_name  --�T�u�����Z���^�[�R�[�h��
--            ,xeh.center_delivery_method                                         center_delivery_method        --�Z���^�[�[�i���@
--            ,xeh.center_use_class                                               center_use_class              --�Z���^�[���p�敪
--            ,xeh.center_whse_class                                              center_whse_class             --�Z���^�[�q�ɋ敪
--            ,xeh.center_area_class                                              center_area_class             --�Z���^�[�n��敪
--            ,xeh.center_arrival_class                                           center_arrival_class          --�Z���^�[���׋敪
--            ,xeh.depot_class                                                    depot_class                   --�f�|�敪
--            ,xeh.tcdc_class                                                     tcdc_class                    --�s�b�c�b�敪
--            ,xeh.upc_flag                                                       upc_flag                      --�t�o�b�t���O
--            ,xeh.simultaneously_class                                           simultaneously_class          --��ċ敪
--            ,xeh.business_id                                                    business_id                   --�Ɩ��h�c
--            ,xeh.whse_directly_class                                            whse_directly_class           --�q���敪
--            ,xeh.premium_rebate_class                                           premium_rebate_class          --���ڎ��
--            ,xeh.item_type                                                      item_type                     --�i�i���ߋ敪
--            ,xeh.cloth_house_food_class                                         cloth_house_food_class        --�߉ƐH�敪
--            ,xeh.mix_class                                                      mix_class                     --���݋敪
--            ,xeh.stk_class                                                      stk_class                     --�݌ɋ敪
--            ,xeh.last_modify_site_class                                         last_modify_site_class        --�ŏI�C���ꏊ�敪
--            ,xeh.report_class                                                   report_class                  --���[�敪
--            ,xeh.addition_plan_class                                            addition_plan_class           --�ǉ��E�v��敪
--            ,xeh.registration_class                                             registration_class            --�o�^�敪
--            ,xeh.specific_class                                                 specific_class                --����敪
--            ,xeh.dealings_class                                                 dealings_class                --����敪
--            ,xeh.order_class                                                    order_class                   --�����敪
--            ,xeh.sum_line_class                                                 sum_line_class                --�W�v���׋敪
--            ,xeh.shipping_guidance_class                                        shipping_guidance_class       --�o�׈ē��ȊO�敪
--            ,xeh.shipping_class                                                 shipping_class                --�o�׋敪
--            ,xeh.product_code_use_class                                         product_code_use_class        --���i�R�[�h�g�p�敪
--            ,xeh.cargo_item_class                                               cargo_item_class              --�ϑ��i�敪
--            ,xeh.ta_class                                                       ta_class                      --�s�^�`�敪
--            ,xeh.plan_code                                                      plan_code                     --���R�[�h
--            ,xeh.category_code                                                  category_code                 --�J�e�S���[�R�[�h
--            ,xeh.category_class                                                 category_class                --�J�e�S���[�敪
--            ,xeh.carrier_means                                                  carrier_means                 --�^����i
--            ,xeh.counter_code                                                   counter_code                  --����R�[�h
--            ,xeh.move_sign                                                      move_sign                     --�ړ��T�C��
--            ,xeh.eos_handwriting_class                                          eos_handwriting_class         --�d�n�r�E�菑�敪
--            ,xeh.delivery_to_section_code                                       delivery_to_section_code      --�[�i��ۃR�[�h
--            ,xeh.invoice_detailed                                               invoice_detailed              --�`�[����
--            ,xeh.attach_qty                                                     attach_qty                    --�Y�t��
--            ,xeh.other_party_floor                                              other_party_floor             --�t���A
--            ,xeh.text_no                                                        text_no                       --�s�d�w�s�m��
--            ,xeh.in_store_code                                                  in_store_code                 --�C���X�g�A�R�[�h
--            ,xeh.tag_data                                                       tag_data                      --�^�O
--            ,xeh.competition_code                                               competition_code              --����
--            ,xeh.billing_chair                                                  billing_chair                 --��������
--            ,xeh.chain_store_code                                               chain_store_code              --�`�F�[���X�g�A�[�R�[�h
--            ,xeh.chain_store_short_name                                         chain_store_short_name        --�`�F�[���X�g�A�[�R�[�h��������
--            ,xeh.direct_delivery_rcpt_fee                                       direct_delivery_rcpt_fee      --���z���^���旿
--            ,xeh.bill_info                                                      bill_info                     --��`���
--            ,xeh.description                                                    description                   --�E�v
--            ,xeh.interior_code                                                  interior_code                 --�����R�[�h
--            ,xeh.order_info_delivery_category                                   order_info_delivery_category  --�������@�[�i�J�e�S���[
--            ,xeh.purchase_type                                                  purchase_type                 --�d���`��
--            ,xeh.delivery_to_name_alt                                           delivery_to_name_alt          --�[�i�ꏊ���i�J�i�j
--            ,xeh.shop_opened_site                                               shop_opened_site              --�X�o�ꏊ
--            ,xeh.counter_name                                                   counter_name                  --���ꖼ
--            ,xeh.extension_number                                               extension_number              --�����ԍ�
--            ,xeh.charge_name                                                    charge_name                   --�S���Җ�
--            ,xeh.price_tag                                                      price_tag                     --�l�D
--            ,xeh.tax_type                                                       tax_type                      --�Ŏ�
--            ,xeh.consumption_tax_class                                          consumption_tax_class         --����ŋ敪
--            ,xeh.brand_class                                                    brand_class                   --�a�q
--            ,xeh.id_code                                                        id_code                       --�h�c�R�[�h
--            ,xeh.department_code                                                department_code               --�S�ݓX�R�[�h
--            ,xeh.department_name                                                department_name               --�S�ݓX��
--            ,xeh.item_type_number                                               item_type_number              --�i�ʔԍ�
--            ,xeh.description_department                                         description_department        --�E�v�i�S�ݓX�j
--            ,xeh.price_tag_method                                               price_tag_method              --�l�D���@
--            ,xeh.reason_column                                                  reason_column                 --���R��
--            ,xeh.a_column_header                                                a_column_header               --�`���w�b�_
--            ,xeh.d_column_header                                                d_column_header               --�c���w�b�_
--            ,xeh.brand_code                                                     brand_code                    --�u�����h�R�[�h
--            ,xeh.line_code                                                      line_code                     --���C���R�[�h
--            ,xeh.class_code                                                     class_code                    --�N���X�R�[�h
--            ,xeh.a1_column                                                      a1_column                     --�`�|�P��
--            ,xeh.b1_column                                                      b1_column                     --�a�|�P��
--            ,xeh.c1_column                                                      c1_column                     --�b�|�P��
--            ,xeh.d1_column                                                      d1_column                     --�c�|�P��
--            ,xeh.e1_column                                                      e1_column                     --�d�|�P��
--            ,xeh.a2_column                                                      a2_column                     --�`�|�Q��
--            ,xeh.b2_column                                                      b2_column                     --�a�|�Q��
--            ,xeh.c2_column                                                      c2_column                     --�b�|�Q��
--            ,xeh.d2_column                                                      d2_column                     --�c�|�Q��
--            ,xeh.e2_column                                                      e2_column                     --�d�|�Q��
--            ,xeh.a3_column                                                      a3_column                     --�`�|�R��
--            ,xeh.b3_column                                                      b3_column                     --�a�|�R��
--            ,xeh.c3_column                                                      c3_column                     --�b�|�R��
--            ,xeh.d3_column                                                      d3_column                     --�c�|�R��
--            ,xeh.e3_column                                                      e3_column                     --�d�|�R��
--            ,xeh.f1_column                                                      f1_column                     --�e�|�P��
--            ,xeh.g1_column                                                      g1_column                     --�f�|�P��
--            ,xeh.h1_column                                                      h1_column                     --�g�|�P��
--            ,xeh.i1_column                                                      i1_column                     --�h�|�P��
--            ,xeh.j1_column                                                      j1_column                     --�i�|�P��
--            ,xeh.k1_column                                                      k1_column                     --�j�|�P��
--            ,xeh.l1_column                                                      l1_column                     --�k�|�P��
--            ,xeh.f2_column                                                      f2_column                     --�e�|�Q��
--            ,xeh.g2_column                                                      g2_column                     --�f�|�Q��
--            ,xeh.h2_column                                                      h2_column                     --�g�|�Q��
--            ,xeh.i2_column                                                      i2_column                     --�h�|�Q��
--            ,xeh.j2_column                                                      j2_column                     --�i�|�Q��
--            ,xeh.k2_column                                                      k2_column                     --�j�|�Q��
--            ,xeh.l2_column                                                      l2_column                     --�k�|�Q��
--            ,xeh.f3_column                                                      f3_column                     --�e�|�R��
--            ,xeh.g3_column                                                      g3_column                     --�f�|�R��
--            ,xeh.h3_column                                                      h3_column                     --�g�|�R��
--            ,xeh.i3_column                                                      i3_column                     --�h�|�R��
--            ,xeh.j3_column                                                      j3_column                     --�i�|�R��
--            ,xeh.k3_column                                                      k3_column                     --�j�|�R��
--            ,xeh.l3_column                                                      l3_column                     --�k�|�R��
--            ,xeh.chain_peculiar_area_header                                     chain_peculiar_area_header    --�`�F�[���X�ŗL�G���A�i�w�b�_�[�j
--            ,xeh.order_connection_number                                        order_connection_number       --�󒍊֘A�ԍ��i���j
--            ------------------------------------------------���׏��------------------------------------------------
--            ,TO_CHAR(xel.line_no)                                               line_no                       --�s�m��
--            ,xel.stockout_class                                                 stockout_class                --���i�敪
--            ,xel.stockout_reason                                                stockout_reason               --���i���R
--            ,xel.item_code                                                      item_code                     --���i�R�[�h�i�ɓ����j
--            ,xel.product_code1                                                  product_code1                 --���i�R�[�h�P
--            ,xel.product_code2                                                  product_code2                 --���i�R�[�h�Q
--            ,CASE
---- 2009/02/17 T.Nakamura Ver.1.4 add start
----               WHEN xel.uom_code = i_prf_rec.case_uom_code THEN
--               WHEN xel.line_uom = i_prf_rec.case_uom_code THEN
---- 2009/02/17 T.Nakamura Ver.1.4 add end
--                   xsib.case_jan_code
--               ELSE
--                 iimb.attribute21
--             END                                                                jan_code                      --�i�`�m�R�[�h
--            ,NVL(xel.itf_code, iimb.attribute22)                                itf_code                      --�h�s�e�R�[�h
--            ,xel.extension_itf_code                                             extension_itf_code            --�����h�s�e�R�[�h
--            ,xel.case_product_code                                              case_product_code             --�P�[�X���i�R�[�h
--            ,xel.ball_product_code                                              ball_product_code             --�{�[�����i�R�[�h
--            ,xel.product_code_item_type                                         product_code_item_type        --���i�R�[�h�i��
--            ,xhpc.item_div_h_code                                               prod_class                    --���i�敪
--            ,NVL(ximb.item_name,i_msg_rec.item_notfound)                        product_name                  --���i���i�����j
--            ,xel.product_name1_alt                                              product_name1_alt             --���i���P�i�J�i�j
--            ,xel.product_name2_alt                                              product_name2_alt             --���i���Q�i�J�i�j
--            ,xel.item_standard1                                                 item_standard1                --�K�i�P
--            ,xel.item_standard2                                                 item_standard2                --�K�i�Q
--            ,TO_CHAR(xel.qty_in_case)                                           qty_in_case                   --����
--            ,iimb.attribute11                                                   num_of_cases                  --�P�[�X����
--            ,TO_CHAR(NVL(xel.num_of_ball,xsib.bowl_inc_num))                    num_of_ball                   --�{�[������
--            ,xel.item_color                                                     item_color                    --�F
--            ,xel.item_size                                                      item_size                     --�T�C�Y
--            ,TO_CHAR(xel.expiration_date,cv_date_fmt)                           expiration_date               --�ܖ�������
--            ,TO_CHAR(xel.product_date,cv_date_fmt)                              product_date                  --������
--            ,TO_CHAR(xel.order_uom_qty)                                         order_uom_qty                 --�����P�ʐ�
--            ,TO_CHAR(xel.shipping_uom_qty)                                      shipping_uom_qty              --�o�גP�ʐ�
--            ,TO_CHAR(xel.packing_uom_qty)                                       packing_uom_qty               --����P�ʐ�
--            ,xel.deal_code                                                      deal_code                     --����
--            ,xel.deal_class                                                     deal_class                    --�����敪
--            ,xel.collation_code                                                 collation_code                --�ƍ�
---- 2009/04/27 K.Kiriu Ver.1.9 Mod start
---- 2009/02/17 T.Nakamura Ver.1.4 add start
--            ,xel.uom_code                                                       uom_code                      --�P��
----            ,xel.line_uom                                                       uom_code                      --�P��
---- 2009/02/17 T.Nakamura Ver.1.4 add end
---- 2009/04/27 K.Kiriu Ver.1.9 Mod end
--            ,xel.unit_price_class                                               unit_price_class              --�P���敪
--            ,xel.parent_packing_number                                          parent_packing_number         --�e����ԍ�
--            ,xel.packing_number                                                 packing_number                --����ԍ�
--            ,xel.product_group_code                                             product_group_code            --���i�Q�R�[�h
--            ,xel.case_dismantle_flag                                            case_dismantle_flag           --�P�[�X��̕s�t���O
--            ,xel.case_class                                                     case_class                    --�P�[�X�敪
--            ,TO_CHAR(xel.indv_order_qty)                                        indv_order_qty                --�������ʁi�o���j
--            ,TO_CHAR(xel.case_order_qty)                                        case_order_qty                --�������ʁi�P�[�X�j
--            ,TO_CHAR(xel.ball_order_qty)                                        ball_order_qty                --�������ʁi�{�[���j
--            ,TO_CHAR(xel.sum_order_qty)                                         sum_order_qty                 --�������ʁi���v�A�o���j
--            ,TO_CHAR(xel.indv_shipping_qty)                                     indv_shipping_qty             --�o�א��ʁi�o���j
--            ,TO_CHAR(xel.case_shipping_qty)                                     case_shipping_qty             --�o�א��ʁi�P�[�X�j
--            ,TO_CHAR(xel.ball_shipping_qty)                                     ball_shipping_qty             --�o�א��ʁi�{�[���j
--            ,TO_CHAR(xel.pallet_shipping_qty)                                   pallet_shipping_qty           --�o�א��ʁi�p���b�g�j
--            ,TO_CHAR(xel.sum_shipping_qty)                                      sum_shipping_qty              --�o�א��ʁi���v�A�o���j
--            ,TO_CHAR(xel.indv_stockout_qty)                                     indv_stockout_qty             --���i���ʁi�o���j
--            ,TO_CHAR(xel.case_stockout_qty)                                     case_stockout_qty             --���i���ʁi�P�[�X�j
--            ,TO_CHAR(xel.ball_stockout_qty)                                     ball_stockout_qty             --���i���ʁi�{�[���j
--            ,TO_CHAR(xel.sum_stockout_qty)                                      sum_stockout_qty              --���i���ʁi���v�A�o���j
--            ,TO_CHAR(xel.case_qty)                                              case_qty                      --�P�[�X����
--            ,TO_CHAR(xel.fold_container_indv_qty)                               fold_container_indv_qty       --�I���R���i�o���j����
--            ,TO_CHAR(xel.order_unit_price)                                      order_unit_price              --���P���i�����j
--            ,TO_CHAR(xel.shipping_unit_price)                                   shipping_unit_price           --���P���i�o�ׁj
--            ,TO_CHAR(xel.order_cost_amt)                                        order_cost_amt                --�������z�i�����j
--            ,TO_CHAR(xel.shipping_cost_amt)                                     shipping_cost_amt             --�������z�i�o�ׁj
--            ,TO_CHAR(xel.stockout_cost_amt)                                     stockout_cost_amt             --�������z�i���i�j
--            ,TO_CHAR(xel.selling_price)                                         selling_price                 --���P��
--            ,TO_CHAR(xel.order_price_amt)                                       order_price_amt               --�������z�i�����j
--            ,TO_CHAR(xel.shipping_price_amt)                                    shipping_price_amt            --�������z�i�o�ׁj
--            ,TO_CHAR(xel.stockout_price_amt)                                    stockout_price_amt            --�������z�i���i�j
--            ,TO_CHAR(xel.a_column_department)                                   a_column_department           --�`���i�S�ݓX�j
--            ,TO_CHAR(xel.d_column_department)                                   d_column_department           --�c���i�S�ݓX�j
--            ,TO_CHAR(xel.standard_info_depth)                                   standard_info_depth           --�K�i���E���s��
--            ,TO_CHAR(xel.standard_info_height)                                  standard_info_height          --�K�i���E����
--            ,TO_CHAR(xel.standard_info_width)                                   standard_info_width           --�K�i���E��
--            ,TO_CHAR(xel.standard_info_weight)                                  standard_info_weight          --�K�i���E�d��
--            ,xel.general_succeeded_item1                                        general_succeeded_item1       --�ėp���p�����ڂP
--            ,xel.general_succeeded_item2                                        general_succeeded_item2       --�ėp���p�����ڂQ
--            ,xel.general_succeeded_item3                                        general_succeeded_item3       --�ėp���p�����ڂR
--            ,xel.general_succeeded_item4                                        general_succeeded_item4       --�ėp���p�����ڂS
--            ,xel.general_succeeded_item5                                        general_succeeded_item5       --�ėp���p�����ڂT
--            ,xel.general_succeeded_item6                                        general_succeeded_item6       --�ėp���p�����ڂU
--            ,xel.general_succeeded_item7                                        general_succeeded_item7       --�ėp���p�����ڂV
--            ,xel.general_succeeded_item8                                        general_succeeded_item8       --�ėp���p�����ڂW
--            ,xel.general_succeeded_item9                                        general_succeeded_item9       --�ėp���p�����ڂX
--            ,xel.general_succeeded_item10                                       general_succeeded_item10      --�ėp���p�����ڂP�O
--            ,TO_CHAR(avtab.tax_rate)                                            general_add_item1             --�ėp�t�����ڂP(�ŗ�)
----******************************************* 2009/04/02 1.8 T.Kitajima MOD START  *************************************
----            ,SUBSTRB(i_base_rec.phone_number, 1, 10)                            general_add_item2             --�ėp�t�����ڂQ
----            ,SUBSTRB(i_base_rec.phone_number, 11, 10)                           general_add_item3             --�ėp�t�����ڂR
--            ,SUBSTRB(cdm.phone_number, 1, 10)                            general_add_item2             --�ėp�t�����ڂQ
--            ,SUBSTRB(cdm.phone_number, 11, 10)                           general_add_item3             --�ėp�t�����ڂR
----******************************************* 2009/04/02 1.8 T.Kitajima MOD  END  *************************************
--            ,xel.general_add_item4                                              general_add_item4             --�ėp�t�����ڂS
--            ,xel.general_add_item5                                              general_add_item5             --�ėp�t�����ڂT
--            ,xel.general_add_item6                                              general_add_item6             --�ėp�t�����ڂU
--            ,xel.general_add_item7                                              general_add_item7             --�ėp�t�����ڂV
--            ,xel.general_add_item8                                              general_add_item8             --�ėp�t�����ڂW
--            ,xel.general_add_item9                                              general_add_item9             --�ėp�t�����ڂX
--            ,xel.general_add_item10                                             general_add_item10            --�ėp�t�����ڂP�O
--            ,xel.chain_peculiar_area_line                                       chain_peculiar_area_line      --�`�F�[���X�ŗL�G���A�i���ׁj
--            ------------------------------------------------�t�b�^���------------------------------------------------
--            ,TO_CHAR(xeh.invoice_indv_order_qty)                                invoice_indv_order_qty        --�i�`�[�v�j�������ʁi�o���j
--            ,TO_CHAR(xeh.invoice_case_order_qty)                                invoice_case_order_qty        --�i�`�[�v�j�������ʁi�P�[�X�j
--            ,TO_CHAR(xeh.invoice_ball_order_qty)                                invoice_ball_order_qty        --�i�`�[�v�j�������ʁi�{�[���j
--            ,TO_CHAR(xeh.invoice_sum_order_qty)                                 invoice_sum_order_qty         --�i�`�[�v�j�������ʁi���v�A�o���j
--            ,TO_CHAR(xeh.invoice_indv_shipping_qty)                             invoice_indv_shipping_qty     --�i�`�[�v�j�o�א��ʁi�o���j
--            ,TO_CHAR(xeh.invoice_case_shipping_qty)                             invoice_case_shipping_qty     --�i�`�[�v�j�o�א��ʁi�P�[�X�j
--            ,TO_CHAR(xeh.invoice_ball_shipping_qty)                             invoice_ball_shipping_qty     --�i�`�[�v�j�o�א��ʁi�{�[���j
--            ,TO_CHAR(xeh.invoice_pallet_shipping_qty)                           invoice_pallet_shipping_qty   --�i�`�[�v�j�o�א��ʁi�p���b�g�j
--            ,TO_CHAR(xeh.invoice_sum_shipping_qty)                              invoice_sum_shipping_qty      --�i�`�[�v�j�o�א��ʁi���v�A�o���j
--            ,TO_CHAR(xeh.invoice_indv_stockout_qty)                             invoice_indv_stockout_qty     --�i�`�[�v�j���i���ʁi�o���j
--            ,TO_CHAR(xeh.invoice_case_stockout_qty)                             invoice_case_stockout_qty     --�i�`�[�v�j���i���ʁi�P�[�X�j
--            ,TO_CHAR(xeh.invoice_ball_stockout_qty)                             invoice_ball_stockout_qty     --�i�`�[�v�j���i���ʁi�{�[���j
--            ,TO_CHAR(xeh.invoice_sum_stockout_qty)                              invoice_sum_stockout_qty      --�i�`�[�v�j���i���ʁi���v�A�o���j
--            ,TO_CHAR(xeh.invoice_case_qty)                                      invoice_case_qty              --�i�`�[�v�j�P�[�X����
--            ,TO_CHAR(xeh.invoice_fold_container_qty)                            invoice_fold_container_qty    --�i�`�[�v�j�I���R���i�o���j����
--            ,TO_CHAR(xeh.invoice_order_cost_amt)                                invoice_order_cost_amt        --�i�`�[�v�j�������z�i�����j
--            ,TO_CHAR(xeh.invoice_shipping_cost_amt)                             invoice_shipping_cost_amt     --�i�`�[�v�j�������z�i�o�ׁj
--            ,TO_CHAR(xeh.invoice_stockout_cost_amt)                             invoice_stockout_cost_amt     --�i�`�[�v�j�������z�i���i�j
--            ,TO_CHAR(xeh.invoice_order_price_amt)                               invoice_order_price_amt       --�i�`�[�v�j�������z�i�����j
--            ,TO_CHAR(xeh.invoice_shipping_price_amt)                            invoice_shipping_price_amt    --�i�`�[�v�j�������z�i�o�ׁj
--            ,TO_CHAR(xeh.invoice_stockout_price_amt)                            invoice_stockout_price_amt    --�i�`�[�v�j�������z�i���i�j
--            ,TO_CHAR(xeh.total_indv_order_qty)                                  total_indv_order_qty          --�i�����v�j�������ʁi�o���j
--            ,TO_CHAR(xeh.total_case_order_qty)                                  total_case_order_qty          --�i�����v�j�������ʁi�P�[�X�j
--            ,TO_CHAR(xeh.total_ball_order_qty)                                  total_ball_order_qty          --�i�����v�j�������ʁi�{�[���j
--            ,TO_CHAR(xeh.total_sum_order_qty)                                   total_sum_order_qty           --�i�����v�j�������ʁi���v�A�o���j
--            ,TO_CHAR(xeh.total_indv_shipping_qty)                               total_indv_shipping_qty       --�i�����v�j�o�א��ʁi�o���j
--            ,TO_CHAR(xeh.total_case_shipping_qty)                               total_case_shipping_qty       --�i�����v�j�o�א��ʁi�P�[�X�j
--            ,TO_CHAR(xeh.total_ball_shipping_qty)                               total_ball_shipping_qty       --�i�����v�j�o�א��ʁi�{�[���j
--            ,TO_CHAR(xeh.total_pallet_shipping_qty)                             total_pallet_shipping_qty     --�i�����v�j�o�א��ʁi�p���b�g�j
--            ,TO_CHAR(xeh.total_sum_shipping_qty)                                total_sum_shipping_qty        --�i�����v�j�o�א��ʁi���v�A�o���j
--            ,TO_CHAR(xeh.total_indv_stockout_qty)                               total_indv_stockout_qty       --�i�����v�j���i���ʁi�o���j
--            ,TO_CHAR(xeh.total_case_stockout_qty)                               total_case_stockout_qty       --�i�����v�j���i���ʁi�P�[�X�j
--            ,TO_CHAR(xeh.total_ball_stockout_qty)                               total_ball_stockout_qty       --�i�����v�j���i���ʁi�{�[���j
--            ,TO_CHAR(xeh.total_sum_stockout_qty)                                total_sum_stockout_qty        --�i�����v�j���i���ʁi���v�A�o���j
--            ,TO_CHAR(xeh.total_case_qty)                                        total_case_qty                --�i�����v�j�P�[�X����
--            ,TO_CHAR(xeh.total_fold_container_qty)                              total_fold_container_qty      --�i�����v�j�I���R���i�o���j����
--            ,TO_CHAR(xeh.total_order_cost_amt)                                  total_order_cost_amt          --�i�����v�j�������z�i�����j
--            ,TO_CHAR(xeh.total_shipping_cost_amt)                               total_shipping_cost_amt       --�i�����v�j�������z�i�o�ׁj
--            ,TO_CHAR(xeh.total_stockout_cost_amt)                               total_stockout_cost_amt       --�i�����v�j�������z�i���i�j
--            ,TO_CHAR(xeh.total_order_price_amt)                                 total_order_price_amt         --�i�����v�j�������z�i�����j
--            ,TO_CHAR(xeh.total_shipping_price_amt)                              total_shipping_price_amt      --�i�����v�j�������z�i�o�ׁj
--            ,TO_CHAR(xeh.total_stockout_price_amt)                              total_stockout_price_amt      --�i�����v�j�������z�i���i�j
--            ,TO_CHAR(xeh.total_line_qty)                                        total_line_qty                --�g�[�^���s��
--            ,TO_CHAR(xeh.total_invoice_qty)                                     total_invoice_qty             --�g�[�^���`�[����
--            ,xeh.chain_peculiar_area_footer                                     chain_peculiar_area_footer    --�`�F�[���X�ŗL�G���A�i�t�b�^�[�j
--      FROM   xxcos_edi_headers                                                  xeh                           --EDI�w�b�_���e�[�u��
--            ,xxcos_edi_lines                                                    xel                           --EDI���׏��e�[�u��
--/* 2009/06/11 Ver1.10 Mod start */
----            ,oe_order_headers_all                                               ooha                          --�󒍃w�b�_���e�[�u��
----            ,oe_order_lines_all                                                 oola                          --�󒍖��׏��e�[�u��
--            ,(
--              --�󒍂����݂���f�[�^
--              SELECT  xeh.edi_header_info_id   edi_header_info_id  --EDI�w�b�_ID
--                     ,xel.edi_line_info_id     edi_line_info_id    --EDI����ID
--                     ,ooha.order_number        order_number        --�󒍔ԍ�
--                     ,ooha.request_date        request_date        --�[�i��
--                     ,xlvv.attribute8          bargain_class       --��ԓ����敪
--                     ,xlvv.attribute10         outbound_flag       --OUTBOUND��
--              FROM    xxcos_edi_headers        xeh         --EDI�w�b�_
--                     ,xxcos_edi_lines          xel         --EDI����
--                     ,oe_order_headers_all     ooha        --�󒍃w�b�_
--                     ,oe_transaction_types_tl  ottt_h      --�󒍃^�C�v(�w�b�_)
--                     ,oe_order_sources         oos         --�󒍃\�[�X
--                     ,oe_order_lines_all       oola        --�󒍖���
--                     ,oe_transaction_types_tl  ottt_l      --�󒍃^�C�v(����)
--                     ,xxcos_lookup_values_v    xlvv        --�N�C�b�N�R�[�h(����敪�}�X�^)
--              WHERE   xeh.order_forward_flag        = 'Y'                        --�󒍘A�g��
--              AND     xeh.edi_header_info_id        = xel.edi_header_info_id
--              AND     xeh.order_connection_number   = ooha.orig_sys_document_ref
--              AND     ooha.org_id                   = i_prf_rec.org_id           --MO:�c�ƒP��
--              AND     ooha.flow_status_code        != cv_cancel                  --�X�e�[�^�X(�L�����Z���ȊO)
--              AND     ooha.order_type_id            = ottt_h.transaction_type_id
--              AND     ottt_h.language               = userenv('LANG')
--              AND     ottt_h.source_lang            = userenv('LANG')
--              AND     ottt_h.description            = i_msg_rec.header_type      --�󒍃^�C�v(�w�b�_)
--              AND     ooha.order_source_id          = oos.order_source_id
--              AND     oos.description               = i_msg_rec.order_source     --�󒍃\�[�X
--              AND     oos.enabled_flag              = 'Y'
--              AND     ooha.header_id                = oola.header_id
--              AND     ooha.org_id                   = oola.org_id                --MO:�c�ƒP��
--              AND     oola.orig_sys_line_ref        = xel.order_connection_line_number
--              AND     oola.flow_status_code        != cv_cancel                  --�X�e�[�^�X(�L�����Z���ȊO)
--              AND     oola.line_type_id             = ottt_l.transaction_type_id
--              AND     ottt_l.language               = userenv('LANG')
--              AND     ottt_l.source_lang            = userenv('LANG')
--              AND     ottt_l.description            = i_msg_rec.line_type        --�󒍃^�C�v(����)
--              AND     xlvv.lookup_type(+)           = ct_qc_sale_class           --����敪
--              AND     xlvv.lookup_code(+)           = oola.attribute5
--              AND     i_other_rec.process_date
--                        BETWEEN NVL(xlvv.start_date_active,i_other_rec.process_date)
--                        AND     NVL(xlvv.end_date_active,i_other_rec.process_date)
--              UNION ALL
--              --�󒍂����݂��Ȃ��f�[�^
--              SELECT  xeh.edi_header_info_id   edi_header_info_id  --EDI�w�b�_ID
--                     ,xel.edi_line_info_id     edi_line_info_id    --EDI����ID
--                     ,TO_NUMBER( NULL )        order_number        --�󒍔ԍ�
--                     ,TO_DATE( NULL )          request_date        --�[�i��
--                     ,TO_CHAR( NULL )          bargain_class       --��ԓ����敪
--                     ,TO_CHAR( NULL )          outbound_flag       --OUTBOUND��
--              FROM    xxcos_edi_headers        xeh         --EDI�w�b�_
--                     ,xxcos_edi_lines          xel         --EDI����
--              WHERE   xeh.order_forward_flag        = 'N'                        --�󒍖��A�g
--              AND     xeh.edi_header_info_id        = xel.edi_header_info_id
--             )                                                                  ixe                           --�Ώۃf�[�^����
--/* 2009/06/11 Ver1.10 Mod End   */
--            ,xxcmm_cust_accounts                                                xca                           --�ڋq�}�X�^�A�h�I��
--            ,hz_cust_accounts                                                   hca                           --�ڋq�}�X�^
--            ,hz_parties                                                         hp                            --�p�[�e�B�}�X�^
--            ,ic_item_mst_b                                                      iimb                          --OPM�i�ڃ}�X�^
--            ,xxcmn_item_mst_b                                                   ximb                          --OPM�i�ڃ}�X�^�A�h�I��
--            ,mtl_system_items_b                                                 msib                          --DISC�i�ڃ}�X�^
--            ,xxcmm_system_items_b                                               xsib                          --DISC�i�ڃ}�X�^�A�h�I��
--            ,xxcos_head_prod_class_v                                            xhpc                          --�{�Џ��i�敪�r���[
--            ,xxcos_chain_store_security_v                                       xcss                          --�`�F�[���X�X�܃Z�L�����e�B�r���[
--/* 2009/06/11 Ver1.10 Del Start */
----            ,xxcos_lookup_values_v                                              xlvv                          --����敪�}�X�^
----            ,oe_transaction_types_tl                                            ottt_l                        --�󒍃^�C�v(����)
----            ,oe_transaction_types_tl                                            ottt_h                        --�󒍃^�C�v(�w�b�_)
----            ,oe_order_sources                                                   oos                           --�󒍃\�[�X
--/* 2009/06/11 Ver1.10 Del End   */
--            ,xxcos_lookup_values_v                                              xlvv2                         --�ŃR�[�h�}�X�^
--            ,ar_vat_tax_all_b                                                   avtab                         --�ŗ��}�X�^
----******************************************* 2009/04/02 1.8 T.Kitajima ADD START *************************************
--            ,(
--              SELECT hca.account_number                                                  account_number               --�ڋq�R�[�h
--                    ,hp.party_name                                                       base_name                    --�ڋq����
--                    ,hp.organization_name_phonetic                                       base_name_kana               --�ڋq����(�J�i)
--                    ,hl.state                                                            state                        --�s���{��
--                    ,hl.city                                                             city                         --�s�E��
--                    ,hl.address1                                                         address1                     --�Z���P
--                    ,hl.address2                                                         address2                     --�Z���Q
--                    ,hl.address_lines_phonetic                                           phone_number                 --�d�b�ԍ�
--                    ,xca.torihikisaki_code                                               customer_code                --�����R�[�h
--              FROM   hz_cust_accounts                                                    hca                          --�ڋq�}�X�^
--                    ,xxcmm_cust_accounts                                                 xca                          --�ڋq�}�X�^�A�h�I��
--                    ,hz_parties                                                          hp                           --�p�[�e�B�}�X�^
--                    ,hz_cust_acct_sites_all                                              hcas                         --�ڋq���ݒn
--                    ,hz_party_sites                                                      hps                          --�p�[�e�B�T�C�g�}�X�^
--                    ,hz_locations                                                        hl                           --���Ə��}�X�^
--              WHERE  hca.customer_class_code = cv_cust_class_base
--              AND    xca.customer_id         = hca.cust_account_id
--              AND    hp.party_id             = hca.party_id
--              AND    hps.party_id            = hca.party_id
--              AND    hl.location_id          = hps.location_id
--              AND    hcas.cust_account_id    = hca.cust_account_id
--              AND    hps.party_site_id       = hcas.party_site_id
--              AND    hcas.org_id             = g_prf_rec.org_id
--             )                                                                  cdm
----******************************************* 2009/04/02 1.8 T.Kitajima ADD  END  *************************************
--            
--      --EDI�w�b�_���e�[�u�����o����
--      WHERE  xeh.data_type_code = i_input_rec.data_type_code                                                  --�f�[�^��R�[�h
--      AND (
--             i_input_rec.info_div IS NULL                                                                     --���敪
--        OR   i_input_rec.info_div IS NOT NULL AND xeh.info_class = i_input_rec.info_div
--      )
----******************************************* 2009/04/01 1.7 T.Kitajima MOD START *************************************
----      AND    xeh.edi_chain_code = i_input_rec.chain_code                                                      --EDI�`�F�[���X�R�[�h
--      AND    xeh.edi_chain_code = i_input_rec.ssm_store_code                                                  --EDI�`�F�[���X�R�[�h
----******************************************* 2009/04/01 1.7 T.Kitajima MOD  END  *************************************
----******************************************* 2009/04/02 1.8 T.Kitajima ADD START *************************************
----      AND (
----             i_input_rec.store_code IS NOT NULL AND xeh.shop_code = i_input_rec.store_code                    --�X�܃R�[�h
----        AND  xeh.shop_code = xcss.chain_store_code
----        OR   i_input_rec.store_code IS NULL AND xeh.shop_code = xcss.chain_store_code
----      )
--      AND    xeh.shop_code      = NVL(i_input_rec.store_code, xeh.shop_code)                                  --�X�܃R�[�h
----******************************************* 2009/04/02 1.8 T.Kitajima ADD  END  *************************************
--      AND    NVL(TRUNC(xeh.shop_delivery_date)
--                ,NVL(TRUNC(xeh.center_delivery_date)
--                    ,NVL(TRUNC(xeh.order_date)
--                        ,TRUNC(xeh.data_creation_date_edi_data))))
--             BETWEEN TO_DATE(i_input_rec.shop_delivery_date_from, cv_date_fmt)
--             AND     TO_DATE(i_input_rec.shop_delivery_date_to, cv_date_fmt)
--      AND (
--             i_input_rec.edi_input_date IS NULL                                                               --EDI�捞��
--        OR   i_input_rec.edi_input_date IS NOT NULL
--        AND  TRUNC(xeh.data_creation_date_edi_data) = TO_DATE(i_input_rec.edi_input_date,cv_date_fmt)
--      )
--      --EDI���׏��e�[�u�����o����
--      AND    xel.edi_header_info_id = xeh.edi_header_info_id
--/* 2009/06/11 Ver1.10 Del Start */
----      --�󒍃^�C�v(�w�b�_)���o����
----      AND    ottt_h.language = userenv('LANG')
----      AND    ottt_h.source_lang = userenv('LANG')
----      AND    ottt_h.description = i_msg_rec.header_type
----      --�󒍃^�C�v(����)���o����
----      AND    ottt_l.language = userenv('LANG')
----      AND    ottt_l.source_lang = userenv('LANG')
----      AND    ottt_l.description = i_msg_rec.line_type
----      --�󒍃\�[�X���o����
----      AND    oos.description = i_msg_rec.order_source
----      AND    oos.enabled_flag = 'Y'
----      --�󒍃w�b�_�e�[�u�����o����
----      AND    ooha.orig_sys_document_ref = xeh.order_connection_number                                         --�O���V�X�e���󒍔ԍ� = �󒍊֘A�ԍ�
----      AND    ooha.flow_status_code != cv_cancel                                                               --�X�e�[�^�X
--/* 2009/06/11 Ver1.10 Del End   */
--      AND    xxcos_common2_pkg.get_deliv_slip_flag(                                                           --�[�i�����s�t���O�擾�֐�
--               i_input_rec.publish_flag_seq                                                                   --�[�i�����s�t���O����
----******************************************* 2009/04/01 1.7 T.Kitajima MOD START *************************************
----              ,DECODE(i_input_rec.report_code                                                                  --���̓p�����[�^.�`�F�[���X�R�[�h
--              ,DECODE(i_input_rec.chain_code                                                                  --���̓p�����[�^.�`�F�[���X�R�[�h
----******************************************* 2009/04/01 1.7 T.Kitajima MOD  END  *************************************
--                     ,i_prf_rec.cmn_rep_chain_code                                                            --���ʒ��[�l���p�`�F�[���X�R�[�h
--/* 2009/06/11 Ver1.10 Mod Start */
----                     ,ooha.global_attribute1                                                                  --���ʒ��[�l���p�[�i�����s�t���O�G���A
----                     ,ooha.global_attribute2                                                                  --�`�F�[���X�ŗL���[�l���p�[�i�����s�t���O�G���A
--                     ,xeh.deliv_slip_flag_area_cmn                                                            --���ʒ��[�l���p�[�i�����s�t���O�G���A
--                     ,xeh.deliv_slip_flag_area_chain                                                          --�`�F�[���X�ŗL���[�l���p�[�i�����s�t���O�G���A
--/* 2009/06/11 Ver1.10 Mod End */
--               )
--             ) = i_input_rec.publish_div                                                                      --���̓p�����[�^.�[�i�����s�t���O
--/* 2009/06/11 Ver1.10 Add Start */
--      --���o�Ώۏ���
--      AND    xeh.edi_header_info_id  = ixe.edi_header_info_id
--      AND    xel.edi_line_info_id    = ixe.edi_line_info_id
--/* 2009/06/11 Ver1.10 Add End   */
--/* 2009/06/11 Ver1.10 Del Start */
----      AND    ooha.order_type_id = ottt_h.transaction_type_id                                                  --�󒍃w�b�_�^�C�v
----      AND    ooha.order_source_id = oos.order_source_id
----      --�󒍖��׏��e�[�u�����o����
----      AND    oola.header_id = ooha.header_id                                                                  --�w�b�_ID
----      AND    oola.line_number = xel.line_no                                                                   --�sNo
----      AND    oola.flow_status_code != cv_cancel                                                               --�X�e�[�^�X
----      AND    oola.line_type_id = ottt_l.transaction_type_id                                                     --�󒍖��׃^�C�v
--/* 2009/06/11 Ver1.10 Del End   */
--      --�ڋq�}�X�^�A�h�I��(�X��)���o����
--      AND    xca.chain_store_code(+) = xeh.edi_chain_code                                                       --EDI�`�F�[���X�R�[�h
--      AND    xca.store_code(+) = xeh.shop_code                                                                --�X�܃R�[�h
--      --�ڋq�}�X�^(�X��)���o����
--      AND    hca.cust_account_id(+) = xca.customer_id                                                         --�ڋqID
--      AND   (hca.cust_account_id IS NOT NULL
--        AND  hca.customer_class_code IN (cv_cust_class_chain_store, cv_cust_class_uesama)
--        OR   hca.cust_account_id IS NULL
--      )                                                                                                       --�ڋq�敪
--      --�p�[�e�B�}�X�^(�X��)���o����
--      AND    hp.party_id(+) = hca.party_id                                                                    --�p�[�e�BID
--      --OPM�i�ڃ}�X�^���o����
--      AND    iimb.item_no(+) = xel.item_code                                                                  --�i�ڃR�[�h
--      --OPM�i�ڃ}�X�^�A�h�I�����o����
--      AND    ximb.item_id(+) = iimb.item_id                                                                   --�i��ID
--      AND    NVL(xeh.shop_delivery_date
--                ,NVL(xeh.center_delivery_date
--                    ,NVL(xeh.order_date
--                        ,xeh.data_creation_date_edi_data)))
--        BETWEEN NVL(ximb.start_date_active
--                   ,NVL(xeh.shop_delivery_date
--                       ,NVL(xeh.center_delivery_date
--                           ,NVL(xeh.order_date
--                               ,xeh.data_creation_date_edi_data))))
--        AND     NVL(ximb.end_date_active
--                    ,NVL(xeh.shop_delivery_date
--                       ,NVL(xeh.center_delivery_date
--                           ,NVL(xeh.order_date
--                               ,xeh.data_creation_date_edi_data))))
--      --DISC�i�ڃ}�X�^���o����
--      AND    msib.segment1(+) = xel.item_code                                                                 --�i�ڃR�[�h
--      AND    msib.organization_id(+) = i_other_rec.organization_id                                            --�݌ɑg�DID
--      --DISC�i�ڃA�h�I�����o����
--      AND    xsib.item_code(+) = msib.segment1                                                         --INV�i��ID
--      --�{�Џ��i�敪�r���[���o����
--      AND    xhpc.segment1(+) = iimb.item_no                                                                  --�i�ڃR�[�h
--      --�`�F�[���X�X�܃Z�L�����e�B�r���[���o����
----******************************************* 2009/04/02 1.8 T.Kitajima MOD START *************************************
----******************************************* 2009/04/01 1.7 T.Kitajima MOD START *************************************
----      AND    xcss.chain_code = i_input_rec.chain_code                                                         --�`�F�[���X�R�[�h
----      AND    xcss.chain_code = i_input_rec.ssm_store_code                                                     --���[�l���`�F�[���X�R�[�h
----******************************************* 2009/04/01 1.7 T.Kitajima MOD  END  *************************************
----      AND    xcss.user_id          = i_input_rec.user_id                                                   --���[�UID
--      AND    xcss.chain_code(+)       = xeh.edi_chain_code                                                    --�`�F�[���X�R�[�h
--      AND    xcss.chain_store_code(+) = xeh.shop_code                                                         --�X�R�[�h
--      AND    xcss.user_id(+)          = i_input_rec.user_id                                                   --���[�UID
----******************************************* 2009/04/02 1.8 T.Kitajima MOD  END  *************************************
--/* 2009/06/11 Ver1.10 Del Start */
----      --����敪�}�X�^���o����
----      AND    xlvv.lookup_type(+) = ct_qc_sale_class                                                           --�Q�ƃ^�C�v������敪
----      AND    xlvv.lookup_code(+) = oola.attribute5                                                            --�Q�ƃR�[�h������敪
----      AND    i_other_rec.process_date
----        BETWEEN NVL(xlvv.start_date_active,i_other_rec.process_date)
----        AND     NVL(xlvv.end_date_active,i_other_rec.process_date)
--/* 2009/06/11 Ver1.10 Del Start */
--      AND xlvv2.lookup_type(+) = 'XXCOS1_CONSUMPTION_TAX_CLASS'
--      AND xlvv2.attribute3(+) = xca.tax_div
--/* 2009/06/11 Ver1.10 Mod Start */
----      AND ooha.request_date
----        BETWEEN NVL(xlvv2.start_date_active,ooha.request_date)
----        AND     NVL(xlvv2.end_date_active,ooha.request_date)
--      AND TRUNC( xeh.shop_delivery_date )
--        BETWEEN NVL( xlvv2.start_date_active, TRUNC( xeh.shop_delivery_date ) )
--        AND     NVL( xlvv2.end_date_active, TRUNC( xeh.shop_delivery_date ) )
--/* 2009/06/11 Ver1.10 Mod End   */
--      AND avtab.tax_code(+) = xlvv2.attribute2
--      AND avtab.set_of_books_id(+) = i_prf_rec.set_of_books_id
---- 2009/02/16 T.Nakamura Ver.1.3 add start
--      AND avtab.org_id                   = i_prf_rec.org_id       --MO:�c�ƒP��
--      AND avtab.enabled_flag             = 'Y'                    --�g�p�\�t���O
--      AND i_other_rec.process_date
--        BETWEEN NVL( avtab.start_date ,i_other_rec.process_date )
--        AND     NVL( avtab.end_date   ,i_other_rec.process_date )
--/* 2009/06/11 Ver.1.10 Del Start */
----      AND ooha.org_id = i_prf_rec.org_id                          --MO:�c�ƒP��
----      AND oola.org_id = ooha.org_id                               --MO:�c�ƒP��
--/* 2009/06/11 Ver.1.10 Del Del   */
----******************************************* 2009/04/02 1.8 T.Kitajima ADD START *************************************
--      AND xca.delivery_base_code = cdm.account_number(+)
----******************************************* 2009/04/02 1.8 T.Kitajima ADD  END  *************************************
---- 2009/02/16 T.Nakamura Ver.1.3 add end
--/* 2009/06/11 Ver1.10 Mod Start */
----      ORDER BY xeh.invoice_number,xel.line_no
----      --���b�N
----      FOR UPDATE OF ooha.header_id NOWAIT
--      ORDER BY xeh.shop_code, xeh.invoice_number, xel.line_no
--      FOR UPDATE OF xeh.edi_header_info_id NOWAIT
--
    CURSOR cur_data_record(i_input_rec    g_input_rtype
                          ,i_prf_rec      g_prf_rtype
                          ,i_base_rec     g_base_rtype
                          ,i_chain_rec    g_chain_rtype
                          ,i_msg_rec      g_msg_rtype
                          ,i_other_rec    g_other_rtype
    )
    IS
      SELECT xeh_l.xeh_edi_header_info_id                                      header_id                     --�w�b�_ID(�X�V�L�[)
            ,ixe.bargain_class                                                 bargain_class                 --��ԓ����敪
            ,ixe.outbound_flag                                                 outbound_flag                 --OUTBOUND��
            ------------------------------------------------�w�b�_���------------------------------------------------
            ,xeh_l.xeh_medium_class                                            medium_class                  --�}�̋敪
            ,xeh_l.xeh_data_type_code                                          data_type_code                --�f�[�^��R�[�h
            ,xeh_l.xeh_file_no                                                 file_no                       --�t�@�C���m��
            ,xeh_l.xeh_info_class                                              info_class                    --���敪
            ,i_other_rec.proc_date                                             process_date                  --������
            ,i_other_rec.proc_time                                             process_time                  --��������
            ,xeh_l.cdm_account_number                                          base_code                     --���_�i����j�R�[�h
            ,xeh_l.cdm_base_name                                               base_name                     --���_���i�������j
            ,xeh_l.cdm_base_name_kana                                          base_name_alt                 --���_���i�J�i�j
            ,xeh_l.xeh_edi_chain_code                                          edi_chain_code                --�d�c�h�`�F�[���X�R�[�h
            ,i_chain_rec.chain_name                                            edi_chain_name                --�d�c�h�`�F�[���X���i�����j
            ,i_chain_rec.chain_name_kana                                       edi_chain_name_alt            --�d�c�h�`�F�[���X���i�J�i�j
            ,xeh_l.xeh_chain_code                                              chain_code                    --�`�F�[���X�R�[�h
            ,xeh_l.xeh_chain_name                                              chain_name                    --�`�F�[���X���i�����j
            ,xeh_l.xeh_chain_name_alt                                          chain_name_alt                --�`�F�[���X���i�J�i�j
            ,i_input_rec.report_code                                           report_code                   --���[�R�[�h
            ,i_input_rec.report_name                                           report_name                   --���[�\����
            ,xeh_l.hca_account_number                                          customer_code                 --�ڋq�R�[�h
            ,xeh_l.hp_party_name                                               customer_name                 --�ڋq���i�����j
            ,xeh_l.hp_organization_name_phonetic                               customer_name_alt             --�ڋq���i�J�i�j
            ,xeh_l.xeh_company_code                                            company_code                  --�ЃR�[�h
            ,xeh_l.xeh_company_name                                            company_name                  --�Ж��i�����j
            ,xeh_l.xeh_company_name_alt                                        company_name_alt              --�Ж��i�J�i�j
            ,xeh_l.xeh_shop_code                                               shop_code                     --�X�R�[�h
            ,NVL(xeh_l.xeh_shop_name,NVL(xeh_l.xca_cust_store_name
                                  ,i_msg_rec.customer_notfound))               shop_name                     --�X���i�����j
            ,NVL(xeh_l.xeh_shop_name_alt,xeh_l.hp_organization_name_phonetic)  shop_name_alt                 --�X���i�J�i�j
            ,NVL(xeh_l.xeh_delivery_center_code,xeh_l.xca_deli_center_code)    delivery_center_code          --�[���Z���^�[�R�[�h
            ,NVL(xeh_l.xeh_delivery_center_name,xeh_l.xca_deli_center_name)    delivery_center_name          --�[���Z���^�[���i�����j
            ,xeh_l.xeh_delivery_center_name_alt                                delivery_center_name_alt      --�[���Z���^�[���i�J�i�j
            ,TO_CHAR(xeh_l.xeh_order_date,cv_date_fmt)                         order_date                    --������
            ,TO_CHAR(xeh_l.xeh_center_delivery_date,cv_date_fmt)               center_delivery_date          --�Z���^�[�[�i��
            ,TO_CHAR(xeh_l.xeh_result_delivery_date,cv_date_fmt)               result_delivery_date          --���[�i��
            ,TO_CHAR(xeh_l.xeh_shop_delivery_date,cv_date_fmt)                 shop_delivery_date            --�X�ܔ[�i��
            ,TO_CHAR(xeh_l.xeh_data_creat_date_edi_d,cv_date_fmt)              data_creation_date_edi_data   --�f�[�^�쐬���i�d�c�h�f�[�^���j
            ,xeh_l.xeh_data_creation_time_edi_d                                data_creation_time_edi_data  --�f�[�^�쐬�����i�d�c�h�f�[�^���j
            ,xeh_l.xeh_invoice_class                                           invoice_class                 --�`�[�敪
            ,xeh_l.xeh_small_classification_code                               small_classification_code     --�����ރR�[�h
            ,xeh_l.xeh_small_classification_name                               small_classification_name     --�����ޖ�
            ,xeh_l.xeh_middle_classification_code                              middle_classification_code    --�����ރR�[�h
            ,xeh_l.xeh_middle_classification_name                              middle_classification_name    --�����ޖ�
            ,xeh_l.xeh_big_classification_code                                 big_classification_code       --�啪�ރR�[�h
            ,xeh_l.xeh_big_classification_name                                 big_classification_name       --�啪�ޖ�
            ,xeh_l.xeh_other_party_department_c                                other_party_department_code   --����敔��R�[�h
            ,xeh_l.xeh_other_party_order_number                                other_party_order_number      --����攭���ԍ�
            ,xeh_l.xeh_check_digit_class                                       check_digit_class             --�`�F�b�N�f�W�b�g�L���敪
            ,xeh_l.xeh_invoice_number                                          invoice_number                --�`�[�ԍ�
            ,xeh_l.xeh_check_digit                                             check_digit                   --�`�F�b�N�f�W�b�g
            ,TO_CHAR(xeh_l.xeh_close_date, cv_date_fmt)                        close_date                    --����
            ,ixe.order_number                                                  order_no_ebs                  --�󒍂m���i�d�a�r�j
            ,xeh_l.xeh_ar_sale_class                                           ar_sale_class                 --�����敪
            ,xeh_l.xeh_delivery_classe                                         delivery_classe               --�z���敪
            ,xeh_l.xeh_opportunity_no                                          opportunity_no                --�ւm��
            ,NVL(xeh_l.xeh_contact_to, xeh_l.cdm_phone_number)                       contact_to                    --�A����
            ,xeh_l.xeh_route_sales                                             route_sales                   --���[�g�Z�[���X
            ,xeh_l.xeh_corporate_code                                          corporate_code                --�@�l�R�[�h
            ,xeh_l.xeh_maker_name                                              maker_name                    --���[�J�[��
/* 2010/10/15 Ver1.18 Mod Start */
--            ,xeh_l.xeh_area_code                                               area_code                     --�n��R�[�h
--            ,NVL2(xeh_l.xeh_area_code,xeh_l.xca_edi_district_name,NULL)        area_name                     --�n�於�i�����j
--            ,NVL2(xeh_l.xeh_area_code,xeh_l.xca_edi_district_kana,NULL)        area_name_alt                 --�n�於�i�J�i�j
              ,NVL(xeh_l.xeh_area_code, xeh_l.xca_edi_district_code )                                        --�n��R�[�h
              ,NVL2(xeh_l.xeh_area_code, xeh_l.xeh_area_name, xeh_l.xca_edi_district_name)                   --�n�於�i�����j
              ,NVL2(xeh_l.xeh_area_code, xeh_l.xeh_area_name_alt, xeh_l.xca_edi_district_kana)               --�n�於�i�J�i�j
/* 2010/10/15 Ver1.18 Mod End   */
            ,NVL(xeh_l.xeh_vendor_code,xeh_l.xca_torihikisaki_code)            vendor_code                   --�����R�[�h
            ,xeh_l.cdm_vendor_name                                             vendor_name                   --����於�i�����j
            ,CASE
               WHEN xeh_l.xeh_vendor_name1_alt IS NULL
                AND xeh_l.xeh_vendor_name2_alt IS NULL THEN
                 i_prf_rec.company_name_kana
               ELSE
                 xeh_l.xeh_vendor_name1_alt
             END                                                               vendor_name1_alt              --����於�P�i�J�i�j
            ,CASE
               WHEN xeh_l.xeh_vendor_name1_alt IS NULL
                AND xeh_l.xeh_vendor_name2_alt IS NULL THEN
                 xeh_l.cdm_base_name_kana
               ELSE
                 xeh_l.xeh_vendor_name2_alt
             END                                                               vendor_name2_alt              --����於�Q�i�J�i�j
            ,xeh_l.cdm_phone_number                                                  vendor_tel                    --�����s�d�k
            ,NVL(xeh_l.xeh_vendor_charge, i_base_rec.manager_name_kana)        vendor_charge                 --�����S����
            ,xeh_l.cdm_state    ||
             xeh_l.cdm_city     ||
             xeh_l.cdm_address1 ||
             xeh_l.cdm_address2                                                      vendor_address                --�����Z���i�����j
            ,xeh_l.xeh_deliver_to_code_itouen                                  deliver_to_code_itouen        --�͂���R�[�h�i�ɓ����j
            ,xeh_l.xeh_deliver_to_code_chain                                   deliver_to_code_chain         --�͂���R�[�h�i�`�F�[���X�j
            ,xeh_l.xeh_deliver_to                                              deliver_to                    --�͂���i�����j
            ,xeh_l.xeh_deliver_to1_alt                                         deliver_to1_alt               --�͂���P�i�J�i�j
            ,xeh_l.xeh_deliver_to2_alt                                         deliver_to2_alt               --�͂���Q�i�J�i�j
            ,xeh_l.xeh_deliver_to_address                                      deliver_to_address            --�͂���Z���i�����j
            ,xeh_l.xeh_deliver_to_address_alt                                  deliver_to_address_alt        --�͂���Z���i�J�i�j
            ,xeh_l.xeh_deliver_to_tel                                          deliver_to_tel                --�͂���s�d�k
            ,xeh_l.xeh_balance_accounts_code                                   balance_accounts_code         --������R�[�h
            ,xeh_l.xeh_balance_accounts_comp_c                                 balance_accounts_company_code --������ЃR�[�h
            ,xeh_l.xeh_balance_accounts_shop_c                                 balance_accounts_shop_code    --������X�R�[�h
            ,xeh_l.xeh_balance_accounts_name                                   balance_accounts_name         --�����於�i�����j
            ,xeh_l.xeh_balance_accounts_name_alt                               balance_accounts_name_alt     --�����於�i�J�i�j
            ,xeh_l.xeh_balance_accounts_address                                balance_accounts_address      --������Z���i�����j
            ,xeh_l.xeh_balance_accounts_addr_alt                               balance_accounts_address_alt  --������Z���i�J�i�j
            ,xeh_l.xeh_balance_accounts_tel                                    balance_accounts_tel          --������s�d�k
            ,TO_CHAR(xeh_l.xeh_order_possible_date, cv_date_fmt)               order_possible_date           --�󒍉\��
            ,TO_CHAR(xeh_l.xeh_permission_possible_date, cv_date_fmt)          permission_possible_date      --���e�\��
            ,TO_CHAR(xeh_l.xeh_forward_month, cv_date_fmt)                     forward_month                 --����N����
            ,TO_CHAR(xeh_l.xeh_payment_settlement_date, cv_date_fmt)           payment_settlement_date       --�x�����ϓ�
            ,TO_CHAR(xeh_l.xeh_handbill_start_date_active, cv_date_fmt)        handbill_start_date_active    --�`���V�J�n��
            ,TO_CHAR(xeh_l.xeh_billing_due_date, cv_date_fmt)                  billing_due_date              --��������
            ,xeh_l.xeh_shipping_time                                           shipping_time                 --�o�׎���
            ,xeh_l.xeh_delivery_schedule_time                                  delivery_schedule_time        --�[�i�\�莞��
            ,xeh_l.xeh_order_time                                              order_time                    --��������
            ,TO_CHAR(xeh_l.xeh_general_date_item1, cv_date_fmt)                general_date_item1            --�ėp���t���ڂP
            ,TO_CHAR(xeh_l.xeh_general_date_item2, cv_date_fmt)                general_date_item2            --�ėp���t���ڂQ
            ,TO_CHAR(xeh_l.xeh_general_date_item3, cv_date_fmt)                general_date_item3            --�ėp���t���ڂR
            ,TO_CHAR(xeh_l.xeh_general_date_item4, cv_date_fmt)                general_date_item4            --�ėp���t���ڂS
            ,TO_CHAR(xeh_l.xeh_general_date_item5, cv_date_fmt)                general_date_item5            --�ėp���t���ڂT
            ,xeh_l.xeh_arrival_shipping_class                                  arrival_shipping_class        --���o�׋敪
            ,xeh_l.xeh_vendor_class                                            vendor_class                  --�����敪
            ,xeh_l.xeh_invoice_detailed_class                                  invoice_detailed_class        --�`�[����敪
            ,xeh_l.xeh_unit_price_use_class                                    unit_price_use_class          --�P���g�p�敪
            ,xeh_l.xeh_sub_distribution_center_c                               sub_distribution_center_code  --�T�u�����Z���^�[�R�[�h
            ,xeh_l.xeh_sub_distribution_center_n                               sub_distribution_center_name  --�T�u�����Z���^�[�R�[�h��
            ,xeh_l.xeh_center_delivery_method                                  center_delivery_method        --�Z���^�[�[�i���@
            ,xeh_l.xeh_center_use_class                                        center_use_class              --�Z���^�[���p�敪
            ,xeh_l.xeh_center_whse_class                                       center_whse_class             --�Z���^�[�q�ɋ敪
            ,xeh_l.xeh_center_area_class                                       center_area_class             --�Z���^�[�n��敪
            ,xeh_l.xeh_center_arrival_class                                    enter_arrival_class          --�Z���^�[���׋敪
            ,xeh_l.xeh_depot_class                                             depot_class                   --�f�|�敪
            ,xeh_l.xeh_tcdc_class                                              tcdc_class                    --�s�b�c�b�敪
            ,xeh_l.xeh_upc_flag                                                upc_flag                      --�t�o�b�t���O
            ,xeh_l.xeh_simultaneously_class                                    simultaneously_class          --��ċ敪
            ,xeh_l.xeh_business_id                                             business_id                   --�Ɩ��h�c
            ,xeh_l.xeh_whse_directly_class                                     whse_directly_class           --�q���敪
            ,xeh_l.xeh_premium_rebate_class                                    premium_rebate_class          --���ڎ��
            ,xeh_l.xeh_item_type                                               item_type                     --�i�i���ߋ敪
            ,xeh_l.xeh_cloth_house_food_class                                  cloth_house_food_class        --�߉ƐH�敪
            ,xeh_l.xeh_mix_class                                               mix_class                     --���݋敪
            ,xeh_l.xeh_stk_class                                               stk_class                     --�݌ɋ敪
            ,xeh_l.xeh_last_modify_site_class                                  last_modify_site_class        --�ŏI�C���ꏊ�敪
            ,xeh_l.xeh_report_class                                            report_class                  --���[�敪
            ,xeh_l.xeh_addition_plan_class                                     addition_plan_class           --�ǉ��E�v��敪
            ,xeh_l.xeh_registration_class                                      registration_class            --�o�^�敪
            ,xeh_l.xeh_specific_class                                          specific_class                --����敪
            ,xeh_l.xeh_dealings_class                                          dealings_class                --����敪
            ,xeh_l.xeh_order_class                                             order_class                   --�����敪
            ,xeh_l.xeh_sum_line_class                                          sum_line_class                --�W�v���׋敪
            ,xeh_l.xeh_shipping_guidance_class                                 shipping_guidance_class       --�o�׈ē��ȊO�敪
            ,xeh_l.xeh_shipping_class                                          shipping_class                --�o�׋敪
            ,xeh_l.xeh_product_code_use_class                                  product_code_use_class        --���i�R�[�h�g�p�敪
            ,xeh_l.xeh_cargo_item_class                                        cargo_item_class              --�ϑ��i�敪
            ,xeh_l.xeh_ta_class                                                ta_class                      --�s�^�`�敪
            ,xeh_l.xeh_plan_code                                               plan_code                     --���R�[�h
            ,xeh_l.xeh_category_code                                           category_code                 --�J�e�S���[�R�[�h
            ,xeh_l.xeh_category_class                                          category_class                --�J�e�S���[�敪
            ,xeh_l.xeh_carrier_means                                           carrier_means                 --�^����i
            ,xeh_l.xeh_counter_code                                            counter_code                  --����R�[�h
            ,xeh_l.xeh_move_sign                                               move_sign                     --�ړ��T�C��
            ,xeh_l.xeh_eos_handwriting_class                                   eos_handwriting_class         --�d�n�r�E�菑�敪
            ,xeh_l.xeh_delivery_to_section_code                                delivery_to_section_code      --�[�i��ۃR�[�h
            ,xeh_l.xeh_invoice_detailed                                        invoice_detailed              --�`�[����
            ,xeh_l.xeh_attach_qty                                              attach_qty                    --�Y�t��
            ,xeh_l.xeh_other_party_floor                                       other_party_floor             --�t���A
            ,xeh_l.xeh_text_no                                                 text_no                       --�s�d�w�s�m��
            ,xeh_l.xeh_in_store_code                                           in_store_code                 --�C���X�g�A�R�[�h
            ,xeh_l.xeh_tag_data                                                tag_data                      --�^�O
            ,xeh_l.xeh_competition_code                                        competition_code              --����
            ,xeh_l.xeh_billing_chair                                           billing_chair                 --��������
            ,xeh_l.xeh_chain_store_code                                        chain_store_code              --�`�F�[���X�g�A�[�R�[�h
            ,xeh_l.xeh_chain_store_short_name                                  chain_store_short_name        --�`�F�[���X�g�A�[�R�[�h��������
            ,xeh_l.xeh_direct_delivery_rcpt_fee                                direct_delivery_rcpt_fee      --���z���^���旿
            ,xeh_l.xeh_bill_info                                               bill_info                     --��`���
            ,xeh_l.xeh_description                                             description                   --�E�v
            ,xeh_l.xeh_interior_code                                           interior_code                 --�����R�[�h
            ,xeh_l.xeh_order_info_delivery_cate                                order_info_delivery_category  --�������@�[�i�J�e�S���[
            ,xeh_l.xeh_purchase_type                                           purchase_type                 --�d���`��
            ,xeh_l.xeh_delivery_to_name_alt                                    delivery_to_name_alt          --�[�i�ꏊ���i�J�i�j
            ,xeh_l.xeh_shop_opened_site                                        shop_opened_site              --�X�o�ꏊ
            ,xeh_l.xeh_counter_name                                            counter_name                  --���ꖼ
            ,xeh_l.xeh_extension_number                                        extension_number              --�����ԍ�
            ,xeh_l.xeh_charge_name                                             charge_name                   --�S���Җ�
            ,xeh_l.xeh_price_tag                                               price_tag                     --�l�D
            ,xeh_l.xeh_tax_type                                                tax_type                      --�Ŏ�
            ,xeh_l.xeh_consumption_tax_class                                   consumption_tax_class         --����ŋ敪
            ,xeh_l.xeh_brand_class                                             brand_class                   --�a�q
            ,xeh_l.xeh_id_code                                                 id_code                       --�h�c�R�[�h
            ,xeh_l.xeh_department_code                                         department_code               --�S�ݓX�R�[�h
            ,xeh_l.xeh_department_name                                         department_name               --�S�ݓX��
            ,xeh_l.xeh_item_type_number                                        item_type_number              --�i�ʔԍ�
            ,xeh_l.xeh_description_department                                  description_department        --�E�v�i�S�ݓX�j
            ,xeh_l.xeh_price_tag_method                                        price_tag_method              --�l�D���@
            ,xeh_l.xeh_reason_column                                           reason_column                 --���R��
            ,xeh_l.xeh_a_column_header                                         a_column_header               --�`���w�b�_
            ,xeh_l.xeh_d_column_header                                         d_column_header               --�c���w�b�_
            ,xeh_l.xeh_brand_code                                              brand_code                    --�u�����h�R�[�h
            ,xeh_l.xeh_line_code                                               line_code                     --���C���R�[�h
            ,xeh_l.xeh_class_code                                              class_code                    --�N���X�R�[�h
            ,xeh_l.xeh_a1_column                                               a1_column                     --�`�|�P��
            ,xeh_l.xeh_b1_column                                               b1_column                     --�a�|�P��
            ,xeh_l.xeh_c1_column                                               c1_column                     --�b�|�P��
            ,xeh_l.xeh_d1_column                                               d1_column                     --�c�|�P��
            ,xeh_l.xeh_e1_column                                               e1_column                     --�d�|�P��
            ,xeh_l.xeh_a2_column                                               a2_column                     --�`�|�Q��
            ,xeh_l.xeh_b2_column                                               b2_column                     --�a�|�Q��
            ,xeh_l.xeh_c2_column                                               c2_column                     --�b�|�Q��
            ,xeh_l.xeh_d2_column                                               d2_column                     --�c�|�Q��
            ,xeh_l.xeh_e2_column                                               e2_column                     --�d�|�Q��
            ,xeh_l.xeh_a3_column                                               a3_column                     --�`�|�R��
            ,xeh_l.xeh_b3_column                                               b3_column                     --�a�|�R��
            ,xeh_l.xeh_c3_column                                               c3_column                     --�b�|�R��
            ,xeh_l.xeh_d3_column                                               d3_column                     --�c�|�R��
            ,xeh_l.xeh_e3_column                                               e3_column                     --�d�|�R��
            ,xeh_l.xeh_f1_column                                               f1_column                     --�e�|�P��
            ,xeh_l.xeh_g1_column                                               g1_column                     --�f�|�P��
            ,xeh_l.xeh_h1_column                                               h1_column                     --�g�|�P��
            ,xeh_l.xeh_i1_column                                               i1_column                     --�h�|�P��
            ,xeh_l.xeh_j1_column                                               j1_column                     --�i�|�P��
            ,xeh_l.xeh_k1_column                                               k1_column                     --�j�|�P��
            ,xeh_l.xeh_l1_column                                               l1_column                     --�k�|�P��
            ,xeh_l.xeh_f2_column                                               f2_column                     --�e�|�Q��
            ,xeh_l.xeh_g2_column                                               g2_column                     --�f�|�Q��
            ,xeh_l.xeh_h2_column                                               h2_column                     --�g�|�Q��
            ,xeh_l.xeh_i2_column                                               i2_column                     --�h�|�Q��
            ,xeh_l.xeh_j2_column                                               j2_column                     --�i�|�Q��
            ,xeh_l.xeh_k2_column                                               k2_column                     --�j�|�Q��
            ,xeh_l.xeh_l2_column                                               l2_column                     --�k�|�Q��
            ,xeh_l.xeh_f3_column                                               f3_column                     --�e�|�R��
            ,xeh_l.xeh_g3_column                                               g3_column                     --�f�|�R��
            ,xeh_l.xeh_h3_column                                               h3_column                     --�g�|�R��
            ,xeh_l.xeh_i3_column                                               i3_column                     --�h�|�R��
            ,xeh_l.xeh_j3_column                                               j3_column                     --�i�|�R��
            ,xeh_l.xeh_k3_column                                               k3_column                     --�j�|�R��
            ,xeh_l.xeh_l3_column                                               l3_column                     --�k�|�R��
            ,xeh_l.xeh_chain_peculiar_area_header                              chain_peculiar_area_header   --�`�F�[���X�ŗL�G���A�i�w�b�_�[�j
            ,xeh_l.xeh_order_connection_number                                 order_connection_number       --�󒍊֘A�ԍ��i���j
-- 2011/10/06 A.Shirakawa Ver.1.19 ADD START
            ,xeh_l.xeh_bms_header_data                                         bms_header_data               --���ʂa�l�r�w�b�_�f�[�^
-- 2011/10/06 A.Shirakawa Ver.1.19 ADD END
            ------------------------------------------------���׏��------------------------------------------------
            ,TO_CHAR(xeh_l.xel_line_no)                                        line_no                       --�s�m��
            ,xeh_l.xel_stockout_class                                          stockout_class                --���i�敪
            ,xeh_l.xel_stockout_reason                                         stockout_reason               --���i���R
-- == 2010/04/20 V1.16 Modified START ===============================================================
--            ,xeh_l.xel_item_code                                               item_code                     --���i�R�[�h�i�ɓ����j
            ,ixe.item_code                                                     item_code                     -- ���i�R�[�h�i�ɓ����j
-- == 2010/04/20 V1.16 Modified END   ===============================================================
            ,xeh_l.xel_product_code1                                           product_code1                 --���i�R�[�h�P
            ,xeh_l.xel_product_code2                                           product_code2                 --���i�R�[�h�Q
            ,CASE
               WHEN xeh_l.xel_line_uom = i_prf_rec.case_uom_code THEN
                   xsib.case_jan_code
               ELSE
                 iimb.attribute21
             END                                                               jan_code                      --�i�`�m�R�[�h
            ,NVL(xeh_l.xel_itf_code, iimb.attribute22)                         itf_code                      --�h�s�e�R�[�h
            ,xeh_l.xel_extension_itf_code                                      extension_itf_code            --�����h�s�e�R�[�h
            ,xeh_l.xel_case_product_code                                       case_product_code             --�P�[�X���i�R�[�h
            ,xeh_l.xel_ball_product_code                                       ball_product_code             --�{�[�����i�R�[�h
            ,xeh_l.xel_product_code_item_type                                  product_code_item_type        --���i�R�[�h�i��
-- ************ 2009/08/12 N.Maeda 1.11 MOD START ***************** --
--            ,xhpc.item_div_h_code                                              prod_class                    --���i�敪
              ,( 
                SELECT
                  mcb.segment1
                FROM
                  mtl_system_items_b msib,
                  mtl_item_categories mic,
                  mtl_categories_b mcb
                WHERE
                    msib.organization_id = i_other_rec.organization_id
                AND msib.segment1 = iimb.item_no
                AND msib.organization_id = mic.organization_id
                AND msib.inventory_item_id = mic.inventory_item_id
                AND mic.category_set_id = i_other_rec.category_set_id
                AND mic.category_id = mcb.category_id
                AND ( mcb.disable_date IS NULL OR mcb.disable_date > i_other_rec.process_date )
/* 2009/09/15 Ver1.12 Mod Start */
--                AND   mcb.enabled_flag   = 'Y'      -- �J�e�S���L���t���O
                AND   mcb.enabled_flag   = cv_enabled_flag      -- �J�e�S���L���t���O
/* 2009/09/15 Ver1.12 Mod End   */
                AND   i_other_rec.process_date BETWEEN NVL(mcb.start_date_active, i_other_rec.process_date)
                                                 AND   NVL(mcb.end_date_active, i_other_rec.process_date)
/* 2009/09/15 Ver1.12 Mod Start */
--                AND   msib.enabled_flag  = 'Y'      -- �i�ڃ}�X�^�L���t���O
                AND   msib.enabled_flag  = cv_enabled_flag      -- �i�ڃ}�X�^�L���t���O
/* 2009/09/15 Ver1.12 Mod End   */
                AND   i_other_rec.process_date BETWEEN NVL(msib.start_date_active, i_other_rec.process_date)
                                                 AND  NVL(msib.end_date_active, i_other_rec.process_date)
             ) PROD_CLASS
-- ************ 2009/08/12 N.Maeda 1.11 MOD  END  ***************** --
            ,NVL(ximb.item_name,i_msg_rec.item_notfound)                       product_name                  --���i���i�����j
            ,xeh_l.xel_product_name1_alt                                       product_name1_alt             --���i���P�i�J�i�j
            ,xeh_l.xel_product_name2_alt                                       product_name2_alt             --���i���Q�i�J�i�j
            ,xeh_l.xel_item_standard1                                          item_standard1                --�K�i�P
            ,xeh_l.xel_item_standard2                                          item_standard2                --�K�i�Q
            ,TO_CHAR(xeh_l.xel_qty_in_case)                                    qty_in_case                   --����
            ,iimb.attribute11                                                  num_of_cases                  --�P�[�X����
            ,TO_CHAR(NVL(xeh_l.xel_num_of_ball,xsib.bowl_inc_num))             num_of_ball                   --�{�[������
            ,xeh_l.xel_item_color                                              item_color                    --�F
            ,xeh_l.xel_item_size                                               item_size                     --�T�C�Y
            ,TO_CHAR(xeh_l.xel_expiration_date,cv_date_fmt)                    expiration_date               --�ܖ�������
            ,TO_CHAR(xeh_l.xel_product_date,cv_date_fmt)                       product_date                  --������
            ,TO_CHAR(xeh_l.xel_order_uom_qty)                                  order_uom_qty                 --�����P�ʐ�
            ,TO_CHAR(xeh_l.xel_shipping_uom_qty)                               shipping_uom_qty              --�o�גP�ʐ�
            ,TO_CHAR(xeh_l.xel_packing_uom_qty)                                packing_uom_qty               --����P�ʐ�
            ,xeh_l.xel_deal_code                                               deal_code                     --����
            ,xeh_l.xel_deal_class                                              deal_class                    --�����敪
            ,xeh_l.xel_collation_code                                          collation_code                --�ƍ�
            ,xeh_l.xel_uom_code                                                uom_code                      --�P��
            ,xeh_l.xel_unit_price_class                                        unit_price_class              --�P���敪
            ,xeh_l.xel_parent_packing_number                                   parent_packing_number         --�e����ԍ�
            ,xeh_l.xel_packing_number                                          packing_number                --����ԍ�
            ,xeh_l.xel_product_group_code                                      product_group_code            --���i�Q�R�[�h
            ,xeh_l.xel_case_dismantle_flag                                     case_dismantle_flag           --�P�[�X��̕s�t���O
            ,xeh_l.xel_case_class                                              case_class                    --�P�[�X�敪
            ,TO_CHAR(xeh_l.xel_indv_order_qty)                                 indv_order_qty                --�������ʁi�o���j
            ,TO_CHAR(xeh_l.xel_case_order_qty)                                 case_order_qty                --�������ʁi�P�[�X�j
            ,TO_CHAR(xeh_l.xel_ball_order_qty)                                 ball_order_qty                --�������ʁi�{�[���j
            ,TO_CHAR(xeh_l.xel_sum_order_qty)                                  sum_order_qty                 --�������ʁi���v�A�o���j
            ,TO_CHAR(xeh_l.xel_indv_shipping_qty)                              indv_shipping_qty             --�o�א��ʁi�o���j
            ,TO_CHAR(xeh_l.xel_case_shipping_qty)                              case_shipping_qty             --�o�א��ʁi�P�[�X�j
            ,TO_CHAR(xeh_l.xel_ball_shipping_qty)                              ball_shipping_qty             --�o�א��ʁi�{�[���j
            ,TO_CHAR(xeh_l.xel_pallet_shipping_qty)                            pallet_shipping_qty           --�o�א��ʁi�p���b�g�j
            ,TO_CHAR(xeh_l.xel_sum_shipping_qty)                               sum_shipping_qty              --�o�א��ʁi���v�A�o���j
            ,TO_CHAR(xeh_l.xel_indv_stockout_qty)                              indv_stockout_qty             --���i���ʁi�o���j
            ,TO_CHAR(xeh_l.xel_case_stockout_qty)                              case_stockout_qty             --���i���ʁi�P�[�X�j
            ,TO_CHAR(xeh_l.xel_ball_stockout_qty)                              ball_stockout_qty             --���i���ʁi�{�[���j
            ,TO_CHAR(xeh_l.xel_sum_stockout_qty)                               sum_stockout_qty              --���i���ʁi���v�A�o���j
            ,TO_CHAR(xeh_l.xel_case_qty)                                       case_qty                      --�P�[�X����
            ,TO_CHAR(xeh_l.xel_fold_container_indv_qty)                        fold_container_indv_qty       --�I���R���i�o���j����
-- == 2010/04/20 V1.16 Modified START ===============================================================
--            ,TO_CHAR(xeh_l.xel_order_unit_price)                               order_unit_price              --���P���i�����j
            ,CASE WHEN  ixe.unit_selling_price  IS NULL
                            THEN  TO_CHAR(xeh_l.xel_order_unit_price)
                  WHEN  xeh_l.edi_unit_price    IS NOT NULL
                            THEN  TO_CHAR(xeh_l.xel_order_unit_price)
                            ELSE  TO_CHAR(ixe.unit_selling_price)
             END                                                               order_unit_price              -- ���P���i�����j
-- == 2010/04/20 V1.16 Modified END   ===============================================================
            ,TO_CHAR(xeh_l.xel_shipping_unit_price)                            shipping_unit_price           --���P���i�o�ׁj
            ,TO_CHAR(xeh_l.xel_order_cost_amt)                                 order_cost_amt                --�������z�i�����j
            ,TO_CHAR(xeh_l.xel_shipping_cost_amt)                              shipping_cost_amt             --�������z�i�o�ׁj
            ,TO_CHAR(xeh_l.xel_stockout_cost_amt)                              stockout_cost_amt             --�������z�i���i�j
            ,TO_CHAR(xeh_l.xel_selling_price)                                  selling_price                 --���P��
            ,TO_CHAR(xeh_l.xel_order_price_amt)                                order_price_amt               --�������z�i�����j
            ,TO_CHAR(xeh_l.xel_shipping_price_amt)                             shipping_price_amt            --�������z�i�o�ׁj
            ,TO_CHAR(xeh_l.xel_stockout_price_amt)                             stockout_price_amt            --�������z�i���i�j
            ,TO_CHAR(xeh_l.xel_a_column_department)                            a_column_department           --�`���i�S�ݓX�j
            ,TO_CHAR(xeh_l.xel_d_column_department)                            d_column_department           --�c���i�S�ݓX�j
            ,TO_CHAR(xeh_l.xel_standard_info_depth)                            standard_info_depth           --�K�i���E���s��
            ,TO_CHAR(xeh_l.xel_standard_info_height)                           standard_info_height          --�K�i���E����
            ,TO_CHAR(xeh_l.xel_standard_info_width)                            standard_info_width           --�K�i���E��
            ,TO_CHAR(xeh_l.xel_standard_info_weight)                           standard_info_weight          --�K�i���E�d��
            ,xeh_l.xel_general_succeeded_item1                                 general_succeeded_item1       --�ėp���p�����ڂP
            ,xeh_l.xel_general_succeeded_item2                                 general_succeeded_item2       --�ėp���p�����ڂQ
            ,xeh_l.xel_general_succeeded_item3                                 general_succeeded_item3       --�ėp���p�����ڂR
            ,xeh_l.xel_general_succeeded_item4                                 general_succeeded_item4       --�ėp���p�����ڂS
            ,xeh_l.xel_general_succeeded_item5                                 general_succeeded_item5       --�ėp���p�����ڂT
            ,xeh_l.xel_general_succeeded_item6                                 general_succeeded_item6       --�ėp���p�����ڂU
            ,xeh_l.xel_general_succeeded_item7                                 general_succeeded_item7       --�ėp���p�����ڂV
            ,xeh_l.xel_general_succeeded_item8                                 general_succeeded_item8       --�ėp���p�����ڂW
            ,xeh_l.xel_general_succeeded_item9                                 general_succeeded_item9       --�ėp���p�����ڂX
            ,xeh_l.xel_general_succeeded_item10                                general_succeeded_item10      --�ėp���p�����ڂP�O
            ,TO_CHAR(xeh_l.avtab_tax_rate)                                           general_add_item1             --�ėp�t�����ڂP(�ŗ�)
            ,SUBSTRB(xeh_l.cdm_phone_number, 1, 10)                                  general_add_item2             --�ėp�t�����ڂQ
            ,SUBSTRB(xeh_l.cdm_phone_number, 11, 10)                                 general_add_item3             --�ėp�t�����ڂR
            ,xeh_l.xel_general_add_item4                                       general_add_item4             --�ėp�t�����ڂS
            ,xeh_l.xel_general_add_item5                                       general_add_item5             --�ėp�t�����ڂT
            ,xeh_l.xel_general_add_item6                                       general_add_item6             --�ėp�t�����ڂU
            ,xeh_l.xel_general_add_item7                                       general_add_item7             --�ėp�t�����ڂV
            ,xeh_l.xel_general_add_item8                                       general_add_item8             --�ėp�t�����ڂW
            ,xeh_l.xel_general_add_item9                                       general_add_item9             --�ėp�t�����ڂX
            ,xeh_l.xel_general_add_item10                                      general_add_item10            --�ėp�t�����ڂP�O
            ,xeh_l.xel_chain_peculiar_area_line                                chain_peculiar_area_line      --�`�F�[���X�ŗL�G���A�i���ׁj
-- 2011/10/06 A.Shirakawa Ver.1.19 ADD START
            ,xeh_l.xel_bms_line_data                                           bms_line_data                 --���ʂa�l�r���׃f�[�^
-- 2011/10/06 A.Shirakawa Ver.1.19 ADD END
            ------------------------------------------------�t�b�^���-----------------------------------------------
            ,TO_CHAR(xeh_l.xeh_invoice_indv_order_qty)                         invoice_indv_order_qty        --�i�`�[�v�j�������ʁi�o���j
            ,TO_CHAR(xeh_l.xeh_invoice_case_order_qty)                         invoice_case_order_qty        --�i�`�[�v�j�������ʁi�P�[�X�j
            ,TO_CHAR(xeh_l.xeh_invoice_ball_order_qty)                         invoice_ball_order_qty        --�i�`�[�v�j�������ʁi�{�[���j
            ,TO_CHAR(xeh_l.xeh_invoice_sum_order_qty)                          invoice_sum_order_qty        --�i�`�[�v�j�������ʁi���v�A�o���j
            ,TO_CHAR(xeh_l.xeh_invoice_indv_shipping_qty)                      invoice_indv_shipping_qty     --�i�`�[�v�j�o�א��ʁi�o���j
            ,TO_CHAR(xeh_l.xeh_invoice_case_shipping_qty)                      invoice_case_shipping_qty     --�i�`�[�v�j�o�א��ʁi�P�[�X�j
            ,TO_CHAR(xeh_l.xeh_invoice_ball_shipping_qty)                      invoice_ball_shipping_qty     --�i�`�[�v�j�o�א��ʁi�{�[���j
            ,TO_CHAR(xeh_l.xeh_invoice_pallet_ship_qty)                        invoice_pallet_shipping_qty   --�i�`�[�v�j�o�א��ʁi�p���b�g�j
            ,TO_CHAR(xeh_l.xeh_invoice_sum_shipping_qty)                       invoice_sum_shipping_qty     --�i�`�[�v�j�o�א��ʁi���v�A�o���j
            ,TO_CHAR(xeh_l.xeh_invoice_indv_stockout_qty)                      invoice_indv_stockout_qty     --�i�`�[�v�j���i���ʁi�o���j
            ,TO_CHAR(xeh_l.xeh_invoice_case_stockout_qty)                      invoice_case_stockout_qty     --�i�`�[�v�j���i���ʁi�P�[�X�j
            ,TO_CHAR(xeh_l.xeh_invoice_ball_stockout_qty)                      invoice_ball_stockout_qty     --�i�`�[�v�j���i���ʁi�{�[���j
            ,TO_CHAR(xeh_l.xeh_invoice_sum_stockout_qty)                       invoice_sum_stockout_qty      --�i�`�[�v�j���i���ʁi���v�A�o���j
            ,TO_CHAR(xeh_l.xeh_invoice_case_qty)                               invoice_case_qty              --�i�`�[�v�j�P�[�X����
            ,TO_CHAR(xeh_l.xeh_invoice_fold_container_qty)                     invoice_fold_container_qty    --�i�`�[�v�j�I���R���i�o���j����
            ,TO_CHAR(xeh_l.xeh_invoice_order_cost_amt)                         invoice_order_cost_amt        --�i�`�[�v�j�������z�i�����j
            ,TO_CHAR(xeh_l.xeh_invoice_shipping_cost_amt)                      invoice_shipping_cost_amt     --�i�`�[�v�j�������z�i�o�ׁj
            ,TO_CHAR(xeh_l.xeh_invoice_stockout_cost_amt)                      invoice_stockout_cost_amt     --�i�`�[�v�j�������z�i���i�j
            ,TO_CHAR(xeh_l.xeh_invoice_order_price_amt)                        invoice_order_price_amt       --�i�`�[�v�j�������z�i�����j
            ,TO_CHAR(xeh_l.xeh_invoice_shipping_price_amt)                     invoice_shipping_price_amt    --�i�`�[�v�j�������z�i�o�ׁj
            ,TO_CHAR(xeh_l.xeh_invoice_stockout_price_amt)                     invoice_stockout_price_amt    --�i�`�[�v�j�������z�i���i�j
            ,TO_CHAR(xeh_l.xeh_total_indv_order_qty)                           total_indv_order_qty          --�i�����v�j�������ʁi�o���j
            ,TO_CHAR(xeh_l.xeh_total_case_order_qty)                           total_case_order_qty          --�i�����v�j�������ʁi�P�[�X�j
            ,TO_CHAR(xeh_l.xeh_total_ball_order_qty)                           total_ball_order_qty          --�i�����v�j�������ʁi�{�[���j
            ,TO_CHAR(xeh_l.xeh_total_sum_order_qty)                            total_sum_order_qty           --�i�����v�j�������ʁi���v�A�o���j
            ,TO_CHAR(xeh_l.xeh_total_indv_shipping_qty)                        total_indv_shipping_qty       --�i�����v�j�o�א��ʁi�o���j
            ,TO_CHAR(xeh_l.xeh_total_case_shipping_qty)                        total_case_shipping_qty       --�i�����v�j�o�א��ʁi�P�[�X�j
            ,TO_CHAR(xeh_l.xeh_total_ball_shipping_qty)                        total_ball_shipping_qty       --�i�����v�j�o�א��ʁi�{�[���j
            ,TO_CHAR(xeh_l.xeh_total_pallet_shipping_qty)                      total_pallet_shipping_qty     --�i�����v�j�o�א��ʁi�p���b�g�j
            ,TO_CHAR(xeh_l.xeh_total_sum_shipping_qty)                         total_sum_shipping_qty        --�i�����v�j�o�א��ʁi���v�A�o���j
            ,TO_CHAR(xeh_l.xeh_total_indv_stockout_qty)                        total_indv_stockout_qty       --�i�����v�j���i���ʁi�o���j
            ,TO_CHAR(xeh_l.xeh_total_case_stockout_qty)                        total_case_stockout_qty       --�i�����v�j���i���ʁi�P�[�X�j
            ,TO_CHAR(xeh_l.xeh_total_ball_stockout_qty)                        total_ball_stockout_qty       --�i�����v�j���i���ʁi�{�[���j
            ,TO_CHAR(xeh_l.xeh_total_sum_stockout_qty)                         total_sum_stockout_qty        --�i�����v�j���i���ʁi���v�A�o���j
            ,TO_CHAR(xeh_l.xeh_total_case_qty)                                 total_case_qty                --�i�����v�j�P�[�X����
            ,TO_CHAR(xeh_l.xeh_total_fold_container_qty)                       total_fold_container_qty      --�i�����v�j�I���R���i�o���j����
            ,TO_CHAR(xeh_l.xeh_total_order_cost_amt)                           total_order_cost_amt          --�i�����v�j�������z�i�����j
            ,TO_CHAR(xeh_l.xeh_total_shipping_cost_amt)                        total_shipping_cost_amt       --�i�����v�j�������z�i�o�ׁj
            ,TO_CHAR(xeh_l.xeh_total_stockout_cost_amt)                        total_stockout_cost_amt       --�i�����v�j�������z�i���i�j
            ,TO_CHAR(xeh_l.xeh_total_order_price_amt)                          total_order_price_amt         --�i�����v�j�������z�i�����j
            ,TO_CHAR(xeh_l.xeh_total_shipping_price_amt)                       total_shipping_price_amt      --�i�����v�j�������z�i�o�ׁj
            ,TO_CHAR(xeh_l.xeh_total_stockout_price_amt)                       total_stockout_price_amt      --�i�����v�j�������z�i���i�j
            ,TO_CHAR(xeh_l.xeh_total_line_qty)                                 total_line_qty                --�g�[�^���s��
            ,TO_CHAR(xeh_l.xeh_total_invoice_qty)                              total_invoice_qty             --�g�[�^���`�[����
            ,xeh_l.xeh_chain_peculiar_area_footer                              chain_peculiar_area_footer    --�`�F�[���X�ŗL�G���A�i�t�b�^�[�j
-- 2019/06/25 V1.22 N.Miyamoto ADD START
            ,xeh_l.xeh_conv_customer_code                                      conv_customer_code            --�ϊ���ڋq�R�[�h
-- 2019/06/25 V1.22 N.Miyamoto ADD END
--
      FROM  (
/* 2009/09/15 Ver1.12 Mod Start */
--             SELECT  '1'                                select_block
             SELECT cv_select_block_1                   select_block
/* 2009/09/15 Ver1.12 Mod End   */
                    -------------------- �w�b�_�f�[�^ -------------------------------------------------------------------------------
                    ,xeh.edi_header_info_id             xeh_edi_header_info_id     -- EDI�w�b�_���ID
                    ,xeh.medium_class                   xeh_medium_class           -- �}�̋敪
                    ,xeh.data_type_code                 xeh_data_type_code         -- �f�[�^��R�[�h
                    ,xeh.file_no                        xeh_file_no                -- �t�@�C���m��
                    ,xeh.info_class                     xeh_info_class             -- ���敪
                    ,xeh.process_date                   xeh_process_date           -- ������
                    ,xeh.process_time                   xeh_process_time           -- ��������
                    ,xeh.base_code                      xeh_base_code              -- ���_�i����j�R�[�h
                    ,xeh.base_name                      xeh_base_name              -- ���_���i�������j
                    ,xeh.base_name_alt                  xeh_base_name_alt          -- ���_���i�J�i�j
                    ,xeh.edi_chain_code                 xeh_edi_chain_code         -- �d�c�h�`�F�[���X�R�[�h
                    ,xeh.edi_chain_name                 xeh_edi_chain_name         -- �d�c�h�`�F�[���X���i�����j
                    ,xeh.edi_chain_name_alt             xeh_edi_chain_name_alt     -- �d�c�h�`�F�[���X���i�J�i�j
                    ,xeh.chain_code                     xeh_chain_code             -- �`�F�[���X�R�[�h
                    ,xeh.chain_name                     xeh_chain_name             -- �`�F�[���X���i�����j
                    ,xeh.chain_name_alt                 xeh_chain_name_alt         -- �`�F�[���X���i�J�i�j
                    ,xeh.report_code                    xeh_report_code            -- ���[�R�[�h
                    ,xeh.report_show_name               xeh_report_show_name       -- ���[�\����
                    ,xeh.customer_code                  xeh_customer_code          -- �ڋq�R�[�h
                    ,xeh.customer_name                  xeh_customer_name          -- �ڋq���i�����j
                    ,xeh.customer_name_alt              xeh_customer_name_alt      -- �ڋq���i�J�i�j
                    ,xeh.company_code                   xeh_company_code           -- �ЃR�[�h
                    ,xeh.company_name                   xeh_company_name           -- �Ж��i�����j
                    ,xeh.company_name_alt               xeh_company_name_alt       -- �Ж��i�J�i�j
                    ,xeh.shop_code                      xeh_shop_code              -- �X�R�[�h
                    ,xeh.shop_name                      xeh_shop_name              -- �X���i�����j
                    ,xeh.shop_name_alt                  xeh_shop_name_alt          -- �X���i�J�i�j
                    ,xeh.delivery_center_code           xeh_delivery_center_code   -- �[���Z���^�[�R�[�h
                    ,xeh.delivery_center_name           xeh_delivery_center_name   -- �[���Z���^�[���i�����j
                    ,xeh.delivery_center_name_alt       xeh_delivery_center_name_alt   -- �[���Z���^�[���i�J�i�j
                    ,xeh.order_date                     xeh_order_date             -- ������
                    ,xeh.center_delivery_date           xeh_center_delivery_date   -- �Z���^�[�[�i��
                    ,xeh.result_delivery_date           xeh_result_delivery_date   -- ���[�i��
                    ,xeh.shop_delivery_date             xeh_shop_delivery_date     -- �X�ܔ[�i��
                    ,xeh.data_creation_date_edi_data    xeh_data_creat_date_edi_d       -- �f�[�^�쐬���i�d�c�h�f�[�^���j
-- ************ 2010/03/10 T.Nakano 1.15 ADD START ***************** --
                    ,xeh.edi_received_date              xeh_edi_received_date           -- EDI��M��
-- ************ 2010/03/10 T.Nakano 1.15 ADD START ***************** --
                    ,xeh.data_creation_time_edi_data    xeh_data_creation_time_edi_d    -- �f�[�^�쐬�����i�d�c�h�f�[�^���j
                    ,xeh.invoice_class                  xeh_invoice_class               -- �`�[�敪
                    ,xeh.small_classification_code      xeh_small_classification_code   -- �����ރR�[�h
                    ,xeh.small_classification_name      xeh_small_classification_name   -- �����ޖ�
                    ,xeh.middle_classification_code     xeh_middle_classification_code  -- �����ރR�[�h
                    ,xeh.middle_classification_name     xeh_middle_classification_name  -- �����ޖ�
                    ,xeh.big_classification_code        xeh_big_classification_code     -- �啪�ރR�[�h
                    ,xeh.big_classification_name        xeh_big_classification_name     -- �啪�ޖ�
                    ,xeh.other_party_department_code    xeh_other_party_department_c -- ����敔��R�[�h
                    ,xeh.other_party_order_number       xeh_other_party_order_number    -- ����攭���ԍ�
                    ,xeh.check_digit_class              xeh_check_digit_class           -- �`�F�b�N�f�W�b�g�L���敪
                    ,xeh.invoice_number                 xeh_invoice_number              -- �`�[�ԍ�
                    ,xeh.check_digit                    xeh_check_digit                 -- �`�F�b�N�f�W�b�g
                    ,xeh.close_date                     xeh_close_date                  -- ����
                    ,xeh.order_no_ebs                   xeh_order_no_ebs                -- �󒍂m���i�d�a�r�j
                    ,xeh.ar_sale_class                  xeh_ar_sale_class               -- �����敪
                    ,xeh.delivery_classe                xeh_delivery_classe             -- �z���敪
                    ,xeh.opportunity_no                 xeh_opportunity_no              -- �ւm��
                    ,xeh.contact_to                     xeh_contact_to                  -- �A����
                    ,xeh.route_sales                    xeh_route_sales                 -- ���[�g�Z�[���X
                    ,xeh.corporate_code                 xeh_corporate_code              -- �@�l�R�[�h
                    ,xeh.maker_name                     xeh_maker_name                  -- ���[�J�[��
                    ,xeh.area_code                      xeh_area_code                   -- �n��R�[�h
                    ,xeh.area_name                      xeh_area_name                   -- �n�於�i�����j
                    ,xeh.area_name_alt                  xeh_area_name_alt               -- �n�於�i�J�i�j
                    ,xeh.vendor_code                    xeh_vendor_code                 -- �����R�[�h
                    ,xeh.vendor_name                    xeh_vendor_name                 -- ����於�i�����j
                    ,xeh.vendor_name1_alt               xeh_vendor_name1_alt            -- ����於�P�i�J�i�j
                    ,xeh.vendor_name2_alt               xeh_vendor_name2_alt            -- ����於�Q�i�J�i�j
                    ,xeh.vendor_tel                     xeh_vendor_tel                  -- �����s�d�k
                    ,xeh.vendor_charge                  xeh_vendor_charge               -- �����S����
                    ,xeh.vendor_address                 xeh_vendor_address              -- �����Z���i�����j
                    ,xeh.deliver_to_code_itouen         xeh_deliver_to_code_itouen      -- �͂���R�[�h�i�ɓ����j
                    ,xeh.deliver_to_code_chain          xeh_deliver_to_code_chain       -- �͂���R�[�h�i�`�F�[���X�j
                    ,xeh.deliver_to                     xeh_deliver_to                  -- �͂���i�����j
                    ,xeh.deliver_to1_alt                xeh_deliver_to1_alt             -- �͂���P�i�J�i�j
                    ,xeh.deliver_to2_alt                xeh_deliver_to2_alt             -- �͂���Q�i�J�i�j
                    ,xeh.deliver_to_address             xeh_deliver_to_address          -- �͂���Z���i�����j
                    ,xeh.deliver_to_address_alt         xeh_deliver_to_address_alt      -- �͂���Z���i�J�i�j
                    ,xeh.deliver_to_tel                 xeh_deliver_to_tel              -- �͂���s�d�k
                    ,xeh.balance_accounts_code          xeh_balance_accounts_code       -- ������R�[�h
                    ,xeh.balance_accounts_company_code  xeh_balance_accounts_comp_c     -- ������ЃR�[�h
                    ,xeh.balance_accounts_shop_code     xeh_balance_accounts_shop_c     -- ������X�R�[�h
                    ,xeh.balance_accounts_name          xeh_balance_accounts_name       -- �����於�i�����j
                    ,xeh.balance_accounts_name_alt      xeh_balance_accounts_name_alt   -- �����於�i�J�i�j
                    ,xeh.balance_accounts_address       xeh_balance_accounts_address    -- ������Z���i�����j
                    ,xeh.balance_accounts_address_alt   xeh_balance_accounts_addr_alt   -- ������Z���i�J�i�j
                    ,xeh.balance_accounts_tel           xeh_balance_accounts_tel        -- ������s�d�k
                    ,xeh.order_possible_date            xeh_order_possible_date         -- �󒍉\��
                    ,xeh.permission_possible_date       xeh_permission_possible_date    -- ���e�\��
                    ,xeh.forward_month                  xeh_forward_month               -- ����N����
                    ,xeh.payment_settlement_date        xeh_payment_settlement_date     -- �x�����ϓ�
                    ,xeh.handbill_start_date_active     xeh_handbill_start_date_active  -- �`���V�J�n��
                    ,xeh.billing_due_date               xeh_billing_due_date            -- ��������
                    ,xeh.shipping_time                  xeh_shipping_time               -- �o�׎���
                    ,xeh.delivery_schedule_time         xeh_delivery_schedule_time      -- �[�i�\�莞��
                    ,xeh.order_time                     xeh_order_time                  -- ��������
                    ,xeh.general_date_item1             xeh_general_date_item1          -- �ėp���t���ڂP
                    ,xeh.general_date_item2             xeh_general_date_item2          -- �ėp���t���ڂQ
                    ,xeh.general_date_item3             xeh_general_date_item3          -- �ėp���t���ڂR
                    ,xeh.general_date_item4             xeh_general_date_item4          -- �ėp���t���ڂS
                    ,xeh.general_date_item5             xeh_general_date_item5          -- �ėp���t���ڂT
                    ,xeh.arrival_shipping_class         xeh_arrival_shipping_class      -- ���o�׋敪
                    ,xeh.vendor_class                   xeh_vendor_class                -- �����敪
                    ,xeh.invoice_detailed_class         xeh_invoice_detailed_class      -- �`�[����敪
                    ,xeh.unit_price_use_class           xeh_unit_price_use_class        -- �P���g�p�敪
                    ,xeh.sub_distribution_center_code   xeh_sub_distribution_center_c     -- �T�u�����Z���^�[�R�[�h
                    ,xeh.sub_distribution_center_name   xeh_sub_distribution_center_n     -- �T�u�����Z���^�[�R�[�h��
                    ,xeh.center_delivery_method         xeh_center_delivery_method      -- �Z���^�[�[�i���@
                    ,xeh.center_use_class               xeh_center_use_class            -- �Z���^�[���p�敪
                    ,xeh.center_whse_class              xeh_center_whse_class           -- �Z���^�[�q�ɋ敪
                    ,xeh.center_area_class              xeh_center_area_class           -- �Z���^�[�n��敪
                    ,xeh.center_arrival_class           xeh_center_arrival_class        -- �Z���^�[���׋敪
                    ,xeh.depot_class                    xeh_depot_class                 -- �f�|�敪
                    ,xeh.tcdc_class                     xeh_tcdc_class                  -- �s�b�c�b�敪
                    ,xeh.upc_flag                       xeh_upc_flag                    -- �t�o�b�t���O
                    ,xeh.simultaneously_class           xeh_simultaneously_class        -- ��ċ敪
                    ,xeh.business_id                    xeh_business_id                 -- �Ɩ��h�c
                    ,xeh.whse_directly_class            xeh_whse_directly_class         -- �q���敪
                    ,xeh.premium_rebate_class           xeh_premium_rebate_class        -- �i�i���ߋ敪
                    ,xeh.item_type                      xeh_item_type                   -- ���ڎ��
                    ,xeh.cloth_house_food_class         xeh_cloth_house_food_class      -- �߉ƐH�敪
                    ,xeh.mix_class                      xeh_mix_class                   -- ���݋敪
                    ,xeh.stk_class                      xeh_stk_class                   -- �݌ɋ敪
                    ,xeh.last_modify_site_class         xeh_last_modify_site_class      -- �ŏI�C���ꏊ�敪
                    ,xeh.report_class                   xeh_report_class                -- ���[�敪
                    ,xeh.addition_plan_class            xeh_addition_plan_class         -- �ǉ��E�v��敪
                    ,xeh.registration_class             xeh_registration_class          -- �o�^�敪
                    ,xeh.specific_class                 xeh_specific_class              -- ����敪
                    ,xeh.dealings_class                 xeh_dealings_class              -- ����敪
                    ,xeh.order_class                    xeh_order_class                 -- �����敪
                    ,xeh.sum_line_class                 xeh_sum_line_class              -- �W�v���׋敪
                    ,xeh.shipping_guidance_class        xeh_shipping_guidance_class     -- �o�׈ē��ȊO�敪
                    ,xeh.shipping_class                 xeh_shipping_class              -- �o�׋敪
                    ,xeh.product_code_use_class         xeh_product_code_use_class      -- ���i�R�[�h�g�p�敪
                    ,xeh.cargo_item_class               xeh_cargo_item_class            -- �ϑ��i�敪
                    ,xeh.ta_class                       xeh_ta_class                    -- �s�^�`�敪
                    ,xeh.plan_code                      xeh_plan_code                   -- ���R�[�h
                    ,xeh.category_code                  xeh_category_code               -- �J�e�S���[�R�[�h
                    ,xeh.category_class                 xeh_category_class              -- �J�e�S���[�敪
                    ,xeh.carrier_means                  xeh_carrier_means               -- �^����i
                    ,xeh.counter_code                   xeh_counter_code                -- ����R�[�h
                    ,xeh.move_sign                      xeh_move_sign                   -- �ړ��T�C��
                    ,xeh.eos_handwriting_class          xeh_eos_handwriting_class       -- �d�n�r�E�菑�敪
                    ,xeh.delivery_to_section_code       xeh_delivery_to_section_code    -- �[�i��ۃR�[�h
                    ,xeh.invoice_detailed               xeh_invoice_detailed            -- �`�[����
                    ,xeh.attach_qty                     xeh_attach_qty                  -- �Y�t��
                    ,xeh.other_party_floor              xeh_other_party_floor           -- �t���A
                    ,xeh.text_no                        xeh_text_no                     -- �s�d�w�s�m��
                    ,xeh.in_store_code                  xeh_in_store_code               -- �C���X�g�A�R�[�h
                    ,xeh.tag_data                       xeh_tag_data                    -- �^�O
                    ,xeh.competition_code               xeh_competition_code            -- ����
                    ,xeh.billing_chair                  xeh_billing_chair               -- ��������
                    ,xeh.chain_store_code               xeh_chain_store_code            -- �`�F�[���X�g�A�[�R�[�h
                    ,xeh.chain_store_short_name         xeh_chain_store_short_name      -- �`�F�[���X�g�A�[�R�[�h��������
                    ,xeh.direct_delivery_rcpt_fee       xeh_direct_delivery_rcpt_fee    -- ���z���^���旿
                    ,xeh.bill_info                      xeh_bill_info                   -- ��`���
                    ,xeh.description                    xeh_description                 -- �E�v
                    ,xeh.interior_code                  xeh_interior_code               -- �����R�[�h
                    ,xeh.order_info_delivery_category   xeh_order_info_delivery_cate    -- �������@�[�i�J�e�S���[
                    ,xeh.purchase_type                  xeh_purchase_type               -- �d���`��
                    ,xeh.delivery_to_name_alt           xeh_delivery_to_name_alt        -- �[�i�ꏊ���i�J�i�j
                    ,xeh.shop_opened_site               xeh_shop_opened_site            -- �X�o�ꏊ
                    ,xeh.counter_name                   xeh_counter_name                -- ���ꖼ
                    ,xeh.extension_number               xeh_extension_number            -- �����ԍ�
                    ,xeh.charge_name                    xeh_charge_name                 -- �S���Җ�
                    ,xeh.price_tag                      xeh_price_tag                   -- �l�D
                    ,xeh.tax_type                       xeh_tax_type                    -- �Ŏ�
-- 2019/06/25 V1.22 N.Miyamoto MOD START
--                    ,xeh.consumption_tax_class          xeh_consumption_tax_class       -- ����ŋ敪
                    ,NVL(xeh.consumption_tax_class, xca.tax_div)
                                                        xeh_consumption_tax_class       -- ����ŋ敪
-- 2019/06/25 V1.22 N.Miyamoto MOD END
                    ,xeh.brand_class                    xeh_brand_class                 -- �a�q
                    ,xeh.id_code                        xeh_id_code                     -- �h�c�R�[�h
                    ,xeh.department_code                xeh_department_code             -- �S�ݓX�R�[�h
                    ,xeh.department_name                xeh_department_name             -- �S�ݓX��
                    ,xeh.item_type_number               xeh_item_type_number            -- �i�ʔԍ�
                    ,xeh.description_department         xeh_description_department      -- �E�v�i�S�ݓX�j
                    ,xeh.price_tag_method               xeh_price_tag_method            -- �l�D���@
                    ,xeh.reason_column                  xeh_reason_column               -- ���R��
                    ,xeh.a_column_header                xeh_a_column_header             -- �`���w�b�_
                    ,xeh.d_column_header                xeh_d_column_header             -- �c���w�b�_
                    ,xeh.brand_code                     xeh_brand_code                  -- �u�����h�R�[�h
                    ,xeh.line_code                      xeh_line_code                   -- ���C���R�[�h
                    ,xeh.class_code                     xeh_class_code                  -- �N���X�R�[�h
                    ,xeh.a1_column                      xeh_a1_column                   -- �`�|�P��
                    ,xeh.b1_column                      xeh_b1_column                   -- �a�|�P��
                    ,xeh.c1_column                      xeh_c1_column                   -- �b�|�P��
                    ,xeh.d1_column                      xeh_d1_column                   -- �c�|�P��
                    ,xeh.e1_column                      xeh_e1_column                   -- �d�|�P��
                    ,xeh.a2_column                      xeh_a2_column                   -- �`�|�Q��
                    ,xeh.b2_column                      xeh_b2_column                   -- �a�|�Q��
                    ,xeh.c2_column                      xeh_c2_column                   -- �b�|�Q��
                    ,xeh.d2_column                      xeh_d2_column                   -- �c�|�Q��
                    ,xeh.e2_column                      xeh_e2_column                   -- �d�|�Q��
                    ,xeh.a3_column                      xeh_a3_column                   -- �`�|�R��
                    ,xeh.b3_column                      xeh_b3_column                   -- �a�|�R��
                    ,xeh.c3_column                      xeh_c3_column                   -- �b�|�R��
                    ,xeh.d3_column                      xeh_d3_column                   -- �c�|�R��
                    ,xeh.e3_column                      xeh_e3_column                   -- �d�|�R��
                    ,xeh.f1_column                      xeh_f1_column                   -- �e�|�P��
                    ,xeh.g1_column                      xeh_g1_column                   -- �f�|�P��
                    ,xeh.h1_column                      xeh_h1_column                   -- �g�|�P��
                    ,xeh.i1_column                      xeh_i1_column                   -- �h�|�P��
                    ,xeh.j1_column                      xeh_j1_column                   -- �i�|�P��
                    ,xeh.k1_column                      xeh_k1_column                   -- �j�|�P��
                    ,xeh.l1_column                      xeh_l1_column                   -- �k�|�P��
                    ,xeh.f2_column                      xeh_f2_column                   -- �e�|�Q��
                    ,xeh.g2_column                      xeh_g2_column                   -- �f�|�Q��
                    ,xeh.h2_column                      xeh_h2_column                   -- �g�|�Q��
                    ,xeh.i2_column                      xeh_i2_column                   -- �h�|�Q��
                    ,xeh.j2_column                      xeh_j2_column                   -- �i�|�Q��
                    ,xeh.k2_column                      xeh_k2_column                   -- �j�|�Q��
                    ,xeh.l2_column                      xeh_l2_column                   -- �k�|�Q��
                    ,xeh.f3_column                      xeh_f3_column                   -- �e�|�R��
                    ,xeh.g3_column                      xeh_g3_column                   -- �f�|�R��
                    ,xeh.h3_column                      xeh_h3_column                   -- �g�|�R��
                    ,xeh.i3_column                      xeh_i3_column                   -- �h�|�R��
                    ,xeh.j3_column                      xeh_j3_column                   -- �i�|�R��
                    ,xeh.k3_column                      xeh_k3_column                   -- �j�|�R��
                    ,xeh.l3_column                      xeh_l3_column                   -- �k�|�R��
                    ,xeh.chain_peculiar_area_header     xeh_chain_peculiar_area_header  -- �`�F�[���X�ŗL�G���A�i�w�b�_�[�j
                    ,xeh.order_connection_number        xeh_order_connection_number     -- �󒍊֘A�ԍ�
                    ,xeh.invoice_indv_order_qty         xeh_invoice_indv_order_qty      -- �i�`�[�v�j�������ʁi�o���j
                    ,xeh.invoice_case_order_qty         xeh_invoice_case_order_qty      -- �i�`�[�v�j�������ʁi�P�[�X�j
                    ,xeh.invoice_ball_order_qty         xeh_invoice_ball_order_qty      -- �i�`�[�v�j�������ʁi�{�[���j
                    ,xeh.invoice_sum_order_qty          xeh_invoice_sum_order_qty       -- �i�`�[�v�j�������ʁi���v�A�o���j
                    ,xeh.invoice_indv_shipping_qty      xeh_invoice_indv_shipping_qty   -- �i�`�[�v�j�o�א��ʁi�o���j
                    ,xeh.invoice_case_shipping_qty      xeh_invoice_case_shipping_qty   -- �i�`�[�v�j�o�א��ʁi�P�[�X�j
                    ,xeh.invoice_ball_shipping_qty      xeh_invoice_ball_shipping_qty   -- �i�`�[�v�j�o�א��ʁi�{�[���j
                    ,xeh.invoice_pallet_shipping_qty    xeh_invoice_pallet_ship_qty     -- �i�`�[�v�j�o�א��ʁi�p���b�g�j
                    ,xeh.invoice_sum_shipping_qty       xeh_invoice_sum_shipping_qty    -- �i�`�[�v�j�o�א��ʁi���v�A�o���j
                    ,xeh.invoice_indv_stockout_qty      xeh_invoice_indv_stockout_qty   -- �i�`�[�v�j���i���ʁi�o���j
                    ,xeh.invoice_case_stockout_qty      xeh_invoice_case_stockout_qty   -- �i�`�[�v�j���i���ʁi�P�[�X�j
                    ,xeh.invoice_ball_stockout_qty      xeh_invoice_ball_stockout_qty   -- �i�`�[�v�j���i���ʁi�{�[���j
                    ,xeh.invoice_sum_stockout_qty       xeh_invoice_sum_stockout_qty    -- �i�`�[�v�j���i���ʁi���v�A�o���j
                    ,xeh.invoice_case_qty               xeh_invoice_case_qty            -- �i�`�[�v�j�P�[�X����
                    ,xeh.invoice_fold_container_qty     xeh_invoice_fold_container_qty  -- �i�`�[�v�j�I���R���i�o���j����
                    ,xeh.invoice_order_cost_amt         xeh_invoice_order_cost_amt      -- �i�`�[�v�j�������z�i�����j
                    ,xeh.invoice_shipping_cost_amt      xeh_invoice_shipping_cost_amt   -- �i�`�[�v�j�������z�i�o�ׁj
                    ,xeh.invoice_stockout_cost_amt      xeh_invoice_stockout_cost_amt   -- �i�`�[�v�j�������z�i���i�j
                    ,xeh.invoice_order_price_amt        xeh_invoice_order_price_amt     -- �i�`�[�v�j�������z�i�����j
                    ,xeh.invoice_shipping_price_amt     xeh_invoice_shipping_price_amt  -- �i�`�[�v�j�������z�i�o�ׁj
                    ,xeh.invoice_stockout_price_amt     xeh_invoice_stockout_price_amt  -- �i�`�[�v�j�������z�i���i�j
                    ,xeh.total_indv_order_qty           xeh_total_indv_order_qty        -- �i�����v�j�������ʁi�o���j
                    ,xeh.total_case_order_qty           xeh_total_case_order_qty        -- �i�����v�j�������ʁi�P�[�X�j
                    ,xeh.total_ball_order_qty           xeh_total_ball_order_qty        -- �i�����v�j�������ʁi�{�[���j
                    ,xeh.total_sum_order_qty            xeh_total_sum_order_qty         -- �i�����v�j�������ʁi���v�A�o���j
                    ,xeh.total_indv_shipping_qty        xeh_total_indv_shipping_qty     -- �i�����v�j�o�א��ʁi�o���j
                    ,xeh.total_case_shipping_qty        xeh_total_case_shipping_qty     -- �i�����v�j�o�א��ʁi�P�[�X�j
                    ,xeh.total_ball_shipping_qty        xeh_total_ball_shipping_qty     -- �i�����v�j�o�א��ʁi�{�[���j
                    ,xeh.total_pallet_shipping_qty      xeh_total_pallet_shipping_qty   -- �i�����v�j�o�א��ʁi�p���b�g�j
                    ,xeh.total_sum_shipping_qty         xeh_total_sum_shipping_qty      -- �i�����v�j�o�א��ʁi���v�A�o���j
                    ,xeh.total_indv_stockout_qty        xeh_total_indv_stockout_qty     -- �i�����v�j���i���ʁi�o���j
                    ,xeh.total_case_stockout_qty        xeh_total_case_stockout_qty     -- �i�����v�j���i���ʁi�P�[�X�j
                    ,xeh.total_ball_stockout_qty        xeh_total_ball_stockout_qty     -- �i�����v�j���i���ʁi�{�[���j
                    ,xeh.total_sum_stockout_qty         xeh_total_sum_stockout_qty      -- �i�����v�j���i���ʁi���v�A�o���j
                    ,xeh.total_case_qty                 xeh_total_case_qty              -- �i�����v�j�P�[�X����
                    ,xeh.total_fold_container_qty       xeh_total_fold_container_qty    -- �i�����v�j�I���R���i�o���j����
                    ,xeh.total_order_cost_amt           xeh_total_order_cost_amt        -- �i�����v�j�������z�i�����j
                    ,xeh.total_shipping_cost_amt        xeh_total_shipping_cost_amt     -- �i�����v�j�������z�i�o�ׁj
                    ,xeh.total_stockout_cost_amt        xeh_total_stockout_cost_amt     -- �i�����v�j�������z�i���i�j
                    ,xeh.total_order_price_amt          xeh_total_order_price_amt       -- �i�����v�j�������z�i�����j
                    ,xeh.total_shipping_price_amt       xeh_total_shipping_price_amt    -- �i�����v�j�������z�i�o�ׁj
                    ,xeh.total_stockout_price_amt       xeh_total_stockout_price_amt    -- �i�����v�j�������z�i���i�j
                    ,xeh.total_line_qty                 xeh_total_line_qty              -- �g�[�^���s��
                    ,xeh.total_invoice_qty              xeh_total_invoice_qty           -- �g�[�^���`�[����
                    ,xeh.chain_peculiar_area_footer     xeh_chain_peculiar_area_footer  -- �`�F�[���X�ŗL�G���A�i�t�b�^�[�j
                    ,xeh.conv_customer_code             xeh_conv_customer_code          -- �ϊ���ڋq�R�[�h
                    ,xeh.order_forward_flag             xeh_order_forward_flag          -- �󒍘A�g�σt���O
                    ,xeh.creation_class                 xeh_creation_class              -- �쐬���敪
                    ,xeh.edi_delivery_schedule_flag     xeh_edi_delivery_schedule_flag  -- EDI�[�i�\�著�M�σt���O
                    ,xeh.price_list_header_id           xeh_price_list_header_id        -- ���i�\�w�b�_ID
                    ,xeh.deliv_slip_flag_area_chain     xeh_deliv_slip_flag_area_chain  -- �[�i�����s�t���O�G���A�i�`�F�[���X�l���j
                    ,xeh.deliv_slip_flag_area_cmn       xeh_deliv_slip_flag_area_cmn    -- �[�i�����s�t���O�G���A�i���ʗl���j
-- 2011/10/06 A.Shirakawa Ver.1.19 ADD START
                    ,xeh.bms_header_data                xeh_bms_header_data             -- ���ʂa�l�r�w�b�_�f�[�^
-- 2011/10/06 A.Shirakawa Ver.1.19 ADD END
                    -------------------- ���׃f�[�^ -------------------------------------------------------------------------------
                    ,xel.edi_line_info_id               xel_edi_line_info_id            -- EDI���׏��ID
                    ,xel.edi_header_info_id             xel_edi_header_info_id          -- EDI�w�b�_���ID
                    ,xel.line_no                        xel_line_no                     -- �s�m��
                    ,xel.stockout_class                 xel_stockout_class              -- ���i�敪
                    ,xel.stockout_reason                xel_stockout_reason             -- ���i���R
                    ,xel.product_code_itouen            xel_product_code_itouen         -- ���i�R�[�h�i�ɓ����j
                    ,xel.product_code1                  xel_product_code1               -- ���i�R�[�h�P
                    ,xel.product_code2                  xel_product_code2               -- ���i�R�[�h�Q
                    ,xel.jan_code                       xel_jan_code                    -- �i�`�m�R�[�h
                    ,xel.itf_code                       xel_itf_code                    -- �h�s�e�R�[�h
                    ,xel.extension_itf_code             xel_extension_itf_code          -- �����h�s�e�R�[�h
                    ,xel.case_product_code              xel_case_product_code           -- �P�[�X���i�R�[�h
                    ,xel.ball_product_code              xel_ball_product_code           -- �{�[�����i�R�[�h
                    ,xel.product_code_item_type         xel_product_code_item_type      -- ���i�R�[�h�i��
                    ,xel.prod_class                     xel_prod_class                  -- ���i�敪
                    ,xel.product_name                   xel_product_name                -- ���i���i�����j
                    ,xel.product_name1_alt              xel_product_name1_alt           -- ���i���P�i�J�i�j
                    ,xel.product_name2_alt              xel_product_name2_alt           -- ���i���Q�i�J�i�j
                    ,xel.item_standard1                 xel_item_standard1              -- �K�i�P
                    ,xel.item_standard2                 xel_item_standard2              -- �K�i�Q
                    ,xel.qty_in_case                    xel_qty_in_case                 -- ����
                    ,xel.num_of_cases                   xel_num_of_cases                -- �P�[�X����
                    ,xel.num_of_ball                    xel_num_of_ball                 -- �{�[������
                    ,xel.item_color                     xel_item_color                  -- �F
                    ,xel.item_size                      xel_item_size                   -- �T�C�Y
                    ,xel.expiration_date                xel_expiration_date             -- �ܖ�������
                    ,xel.product_date                   xel_product_date                -- ������
                    ,xel.order_uom_qty                  xel_order_uom_qty               -- �����P�ʐ�
                    ,xel.shipping_uom_qty               xel_shipping_uom_qty            -- �o�גP�ʐ�
                    ,xel.packing_uom_qty                xel_packing_uom_qty             -- ����P�ʐ�
                    ,xel.deal_code                      xel_deal_code                   -- ����
                    ,xel.deal_class                     xel_deal_class                  -- �����敪
                    ,xel.collation_code                 xel_collation_code              -- �ƍ�
                    ,xel.uom_code                       xel_uom_code                    -- �P��
                    ,xel.unit_price_class               xel_unit_price_class            -- �P���敪
                    ,xel.parent_packing_number          xel_parent_packing_number       -- �e����ԍ�
                    ,xel.packing_number                 xel_packing_number              -- ����ԍ�
                    ,xel.product_group_code             xel_product_group_code          -- ���i�Q�R�[�h
                    ,xel.case_dismantle_flag            xel_case_dismantle_flag         -- �P�[�X��̕s�t���O
                    ,xel.case_class                     xel_case_class                  -- �P�[�X�敪
                    ,xel.indv_order_qty                 xel_indv_order_qty              -- �������ʁi�o���j
                    ,xel.case_order_qty                 xel_case_order_qty              -- �������ʁi�P�[�X�j
                    ,xel.ball_order_qty                 xel_ball_order_qty              -- �������ʁi�{�[���j
                    ,xel.sum_order_qty                  xel_sum_order_qty               -- �������ʁi���v�A�o���j
                    ,xel.indv_shipping_qty              xel_indv_shipping_qty           -- �o�א��ʁi�o���j
                    ,xel.case_shipping_qty              xel_case_shipping_qty           -- �o�א��ʁi�P�[�X�j
                    ,xel.ball_shipping_qty              xel_ball_shipping_qty           -- �o�א��ʁi�{�[���j
                    ,xel.pallet_shipping_qty            xel_pallet_shipping_qty         -- �o�א��ʁi�p���b�g�j
                    ,xel.sum_shipping_qty               xel_sum_shipping_qty            -- �o�א��ʁi���v�A�o���j
                    ,xel.indv_stockout_qty              xel_indv_stockout_qty           -- ���i���ʁi�o���j
                    ,xel.case_stockout_qty              xel_case_stockout_qty           -- ���i���ʁi�P�[�X�j
                    ,xel.ball_stockout_qty              xel_ball_stockout_qty           -- ���i���ʁi�{�[���j
                    ,xel.sum_stockout_qty               xel_sum_stockout_qty            -- ���i���ʁi���v�A�o���j
                    ,xel.case_qty                       xel_case_qty                    -- �P�[�X����
                    ,xel.fold_container_indv_qty        xel_fold_container_indv_qty     -- �I���R���i�o���j����
                    ,xel.order_unit_price               xel_order_unit_price            -- ���P���i�����j
                    ,xel.shipping_unit_price            xel_shipping_unit_price         -- ���P���i�o�ׁj
                    ,xel.order_cost_amt                 xel_order_cost_amt              -- �������z�i�����j
                    ,xel.shipping_cost_amt              xel_shipping_cost_amt           -- �������z�i�o�ׁj
                    ,xel.stockout_cost_amt              xel_stockout_cost_amt           -- �������z�i���i�j
                    ,xel.selling_price                  xel_selling_price               -- ���P��
                    ,xel.order_price_amt                xel_order_price_amt             -- �������z�i�����j
                    ,xel.shipping_price_amt             xel_shipping_price_amt          -- �������z�i�o�ׁj
                    ,xel.stockout_price_amt             xel_stockout_price_amt          -- �������z�i���i�j
                    ,xel.a_column_department            xel_a_column_department         -- �`���i�S�ݓX�j
                    ,xel.d_column_department            xel_d_column_department         -- �c���i�S�ݓX�j
                    ,xel.standard_info_depth            xel_standard_info_depth         -- �K�i���E���s��
                    ,xel.standard_info_height           xel_standard_info_height        -- �K�i���E����
                    ,xel.standard_info_width            xel_standard_info_width         -- �K�i���E��
                    ,xel.standard_info_weight           xel_standard_info_weight        -- �K�i���E�d��
                    ,xel.general_succeeded_item1        xel_general_succeeded_item1     -- �ėp���p�����ڂP
                    ,xel.general_succeeded_item2        xel_general_succeeded_item2     -- �ėp���p�����ڂQ
                    ,xel.general_succeeded_item3        xel_general_succeeded_item3     -- �ėp���p�����ڂR
                    ,xel.general_succeeded_item4        xel_general_succeeded_item4     -- �ėp���p�����ڂS
                    ,xel.general_succeeded_item5        xel_general_succeeded_item5     -- �ėp���p�����ڂT
                    ,xel.general_succeeded_item6        xel_general_succeeded_item6     -- �ėp���p�����ڂU
                    ,xel.general_succeeded_item7        xel_general_succeeded_item7     -- �ėp���p�����ڂV
                    ,xel.general_succeeded_item8        xel_general_succeeded_item8     -- �ėp���p�����ڂW
                    ,xel.general_succeeded_item9        xel_general_succeeded_item9     -- �ėp���p�����ڂX
                    ,xel.general_succeeded_item10       xel_general_succeeded_item10    -- �ėp���p�����ڂP�O
                    ,xel.general_add_item1              xel_general_add_item1           -- �ėp�t�����ڂP
                    ,xel.general_add_item2              xel_general_add_item2           -- �ėp�t�����ڂQ
                    ,xel.general_add_item3              xel_general_add_item3           -- �ėp�t�����ڂR
                    ,xel.general_add_item4              xel_general_add_item4           -- �ėp�t�����ڂS
                    ,xel.general_add_item5              xel_general_add_item5           -- �ėp�t�����ڂT
                    ,xel.general_add_item6              xel_general_add_item6           -- �ėp�t�����ڂU
                    ,xel.general_add_item7              xel_general_add_item7           -- �ėp�t�����ڂV
                    ,xel.general_add_item8              xel_general_add_item8           -- �ėp�t�����ڂW
                    ,xel.general_add_item9              xel_general_add_item9           -- �ėp�t�����ڂX
                    ,xel.general_add_item10             xel_general_add_item10          -- �ėp�t�����ڂP�O
                    ,xel.chain_peculiar_area_line       xel_chain_peculiar_area_line    -- �`�F�[���X�ŗL�G���A�i���ׁj
                    ,xel.item_code                      xel_item_code                   -- �i�ڃR�[�h
                    ,xel.line_uom                       xel_line_uom                    -- ���גP��
                    ,xel.hht_delivery_schedule_flag     xel_hht_delivery_schedule_flag  -- HHT�[�i�\��A�g�σt���O
                    ,xel.order_connection_line_number   xel_order_connect_line_num      -- �󒍊֘A���הԍ�
                    ,xel.taking_unit_price              xel_taking_unit_price           -- �捞�����P���i�����j
-- 2011/10/06 A.Shirakawa Ver.1.19 ADD START
                    ,xel.bms_line_data                  xel_bms_line_data               -- ���ʂa�l�r���׃f�[�^
-- 2011/10/06 A.Shirakawa Ver.1.19 ADD END
                    ----------------- �ڋq��� --------------------------------------------------------------
                    ,hca.account_number                 hca_account_number              -- �ڋq�R�[�h
                    ,hp.party_name                      hp_party_name                   -- �ڋq���i�����j
                    ,hp.organization_name_phonetic      hp_organization_name_phonetic   -- �X���i�J�i�j
                    ,xca.cust_store_name                xca_cust_store_name             -- �X���i�����j
                    ,xca.deli_center_code               xca_deli_center_code            -- �[���Z���^�[�R�[�h
                    ,xca.deli_center_name               xca_deli_center_name            -- �[���Z���^�[���i�����j
/* 2010/10/15 Ver1.18 Add Start */
                    ,xca.edi_district_code              xca_edi_district_code           -- �n��R�[�h
/* 2010/10/15 Ver1.18 Add End   */
                    ,xca.edi_district_name              xca_edi_district_name           -- �n�於�i�����j
                    ,xca.edi_district_kana              xca_edi_district_kana           -- �n�於�i�J�i�j
                    ,xca.torihikisaki_code              xca_torihikisaki_code           -- �����R�[�h
                    ,xca.tax_div                        xca_tax_div                     -- ����ŋ敪
                    ,xca.delivery_base_code             xca_delivery_base_code          --
-- 2019/06/25 V1.22 N.Miyamoto MOD START
--                    ,avtab.tax_rate                     avtab_tax_rate                  -- �ŗ�
                    ,DECODE( xlvv2.attribute4, cv_attribute_y                           -- �ڋq�ŋ敪����ې�(�ŃR�[�h�}�X�^.��ېŋ敪=Y)�̏ꍇ��
                           , avtab.tax_rate                                             -- �ŗ��}�X�^���擾
                           , xrtrv.tax_rate )           avtab_tax_rate                  -- ��ېňȊO�͕i�ڕʏ���ŗ����擾
-- 2019/06/25 V1.22 N.Miyamoto MOD END
                    ,cdm.account_number                 cdm_account_number
                    ,DECODE(cdm.account_number
                           ,NULL
                           ,g_msg_rec.customer_notfound
                           ,cdm.base_name)              cdm_base_name                   -- ���_���i�������j
                    ,cdm.base_name_kana                 cdm_base_name_kana
                    ,cdm.phone_number                   cdm_phone_number
                    ,cdm.state                          cdm_state
                    ,cdm.city                           cdm_city
                    ,cdm.address1                       cdm_address1
                    ,cdm.address2                       cdm_address2
                    ,DECODE(cdm.account_number
                           ,NULL, g_msg_rec.customer_notfound
-- ************************* 2010/01/06 N.Maeda MOD START **************** --
--                           ,i_prf_rec.company_name || cv_space || cdm.base_name
                           ,i_prf_rec.company_name || cv_space 
                           || REPLACE ( cdm.base_name , cv_space)
-- ************************* 2010/01/06 N.Maeda MOD  END  **************** --
                     )                                  cdm_vendor_name                 -- ����於
-- == 2010/04/20 V1.16 Added START ===============================================================
                   , xel.edi_unit_price                 edi_unit_price                  -- EDI���P���i�����j
-- == 2010/04/20 V1.16 Added END   ===============================================================
             FROM    xxcos_edi_headers                  xeh                             -- EDI�w�b�_���e�[�u��
                    ,xxcos_edi_lines                    xel                             -- EDI���׏��e�[�u��
                    ,xxcmm_cust_accounts                    xca                           --�ڋq�}�X�^�A�h�I��
                    ,hz_cust_accounts                       hca                           --�ڋq�}�X�^
                    ,hz_parties                             hp                            --�p�[�e�B�}�X�^
/* 2010/06/11 Ver1.17 Del Start */
--                    ,xxcos_chain_store_security_v           xcss                          --�`�F�[���X�X�܃Z�L�����e�B�r���[
/* 2010/06/11 Ver1.17 Del End */
                    ,xxcos_lookup_values_v                  xlvv2                         --�ŃR�[�h�}�X�^
                    ,ar_vat_tax_all_b                       avtab                         --�ŗ��}�X�^
-- 2019/06/25 V1.22 N.Miyamoto ADD START
                    ,xxcos_reduced_tax_rate_v               xrtrv                         --�i�ڕʏ���ŗ�view
-- 2019/06/25 V1.22 N.Miyamoto ADD END
                    ,(
                      SELECT hca.account_number                                                  account_number               --�ڋq�R�[�h
                            ,hp.party_name                                                       base_name                    --�ڋq����
                            ,hp.organization_name_phonetic                                       base_name_kana               --�ڋq����(�J�i)
                            ,hl.state                                                            state                        --�s���{��
                            ,hl.city                                                             city                         --�s�E��
                            ,hl.address1                                                         address1                     --�Z���P
                            ,hl.address2                                                         address2                     --�Z���Q
                            ,hl.address_lines_phonetic                                           phone_number                 --�d�b�ԍ�
                            ,xca.torihikisaki_code                                               customer_code                --�����R�[�h
                      FROM   hz_cust_accounts                                                    hca                          --�ڋq�}�X�^
                            ,xxcmm_cust_accounts                                                 xca                          --�ڋq�}�X�^�A�h�I��
                            ,hz_parties                                                          hp                           --�p�[�e�B�}�X�^
                            ,hz_cust_acct_sites_all                                              hcas                         --�ڋq���ݒn
                            ,hz_party_sites                                                      hps                          --�p�[�e�B�T�C�g�}�X�^
                            ,hz_locations                                                        hl                           --���Ə��}�X�^
                      WHERE  hca.customer_class_code = cv_cust_class_base
                      AND    xca.customer_id         = hca.cust_account_id
                      AND    hp.party_id             = hca.party_id
                      AND    hps.party_id            = hca.party_id
                      AND    hl.location_id          = hps.location_id
                      AND    hcas.cust_account_id    = hca.cust_account_id
                      AND    hps.party_site_id       = hcas.party_site_id
                      AND    hcas.org_id             = g_prf_rec.org_id
                     )                                                                  cdm
--
             WHERE  xel.edi_header_info_id = xeh.edi_header_info_id
             AND    xeh.edi_chain_code = i_input_rec.ssm_store_code                                                  --EDI�`�F�[���X�R�[�h
             AND    xeh.conv_customer_code IS NOT NULL
             --�ϊ���ڋq�R�[�h��NOT NULL�̕�(�ڋq�}�X�^�Ƀ}�X�^�f�[�^�����݂������)
             AND    xeh.shop_code      = NVL(i_input_rec.store_code,xeh.shop_code)                                                      --�X�܃R�[�h
             --�ڋq�}�X�^�A�h�I��(�X��)���o����
             AND    xca.chain_store_code = xeh.edi_chain_code --EDI�`�F�[���X�R�[�h
             AND    xca.store_code       = xeh.shop_code      --�X�܃R�[�h
             --�ڋq�}�X�^(�X��)���o����
             AND    hca.cust_account_id  = xca.customer_id                                                         --�ڋqID
             AND   (hca.cust_account_id IS NOT NULL
             AND  hca.customer_class_code IN (cv_cust_class_chain_store, cv_cust_class_uesama)
               OR   hca.cust_account_id IS NULL
                   )                                                                                                       --�ڋq�敪
             --�p�[�e�B�}�X�^(�X��)���o����
             AND    hp.party_id = hca.party_id                                                                    --�p�[�e�BID
-- Ver1.21 Add Start
             AND    hp.duns_number_c <> cv_cust_stop_div                                                          --���~���ٍψȊO
-- Ver1.21 Add End
/* 2010/06/11 Ver1.17 Mod Start */
--             --�`�F�[���X�X�܃Z�L�����e�B�r���[���o����
--             AND    xcss.chain_code       = xeh.edi_chain_code                                                    --�`�F�[���X�R�[�h
--             AND    xcss.chain_store_code = xeh.shop_code                                                         --�X�R�[�h
--             AND    xcss.user_id          = i_input_rec.user_id                                                   --���[�UID
             AND xca.delivery_base_code  = i_input_rec.base_code
/* 2010/06/11 Ver1.17 Del End   */
--
/* 2009/09/15 Ver1.12 Mod Start */
--             AND xlvv2.lookup_type = 'XXCOS1_CONSUMPTION_TAX_CLASS'                               --
             AND xlvv2.lookup_type = ct_qc_consumption_tax_class                               --
/* 2009/09/15 Ver1.12 Mod End   */
             AND xlvv2.attribute3  = xca.tax_div                                             --
             AND TRUNC( xeh.shop_delivery_date )                                               --
               BETWEEN NVL( xlvv2.start_date_active, TRUNC( xeh.shop_delivery_date ) )         --
               AND     NVL( xlvv2.end_date_active, TRUNC( xeh.shop_delivery_date ) )           --
             AND avtab.tax_code = xlvv2.attribute2
             AND avtab.set_of_books_id = i_prf_rec.set_of_books_id
             AND avtab.org_id                   = i_prf_rec.org_id       --MO:�c�ƒP��
/* 2009/09/15 Ver1.12 Mod Start */
--             AND avtab.enabled_flag             = 'Y'                    --�g�p�\�t���O
             AND avtab.enabled_flag             = cv_enabled_flag        --�g�p�\�t���O
/* 2009/09/15 Ver1.12 Mod End   */
/* 2009/09/08 Ver1.12 Del Start */
--             AND i_other_rec.process_date
--               BETWEEN NVL( avtab.start_date ,i_other_rec.process_date )
--               AND     NVL( avtab.end_date   ,i_other_rec.process_date )
/* 2009/09/08 Ver1.12 Del End   */
-- 2019/06/25 V1.22 N.Miyamoto ADD START
             AND xel.item_code = xrtrv.item_code(+)                                            -- EDI����.�i��=�i�ڕʏ���ŗ�.�i��
             AND TRUNC( xeh.shop_delivery_date )                                               -- EDI�w�b�_.�X�ܔ[�i��
               BETWEEN NVL( xrtrv.start_date, TRUNC( xeh.shop_delivery_date ) )                -- �i�ڕʏ���ŗ�V.�ŗ��L�[_�J�n��
                   AND NVL( xrtrv.end_date,   TRUNC( xeh.shop_delivery_date ) )                -- �i�ڕʏ���ŗ�V.�ŗ��L�[_�I����
             AND TRUNC( xeh.shop_delivery_date )                                               -- EDI�w�b�_.�X�ܔ[�i��
               BETWEEN NVL( xrtrv.start_date_histories, TRUNC( xeh.shop_delivery_date ) )      -- �i�ڕʏ���ŗ�V.����ŗ���_�J�n��
                   AND NVL( xrtrv.end_date_histories,   TRUNC( xeh.shop_delivery_date ) )      -- �i�ڕʏ���ŗ�V.����ŗ���_�I����
-- 2019/06/25 V1.22 N.Miyamoto ADD END
             --
             AND xca.delivery_base_code = cdm.account_number
-- ************ 2009/08/12 N.Maeda 1.11 ADD START ***************** --
             AND xeh.data_type_code = i_input_rec.data_type_code
-- ************ 2009/08/12 N.Maeda 1.11 ADD  END  ***************** --
--
             UNION ALL
--
             SELECT 
-- ************ 2009/08/12 N.Maeda 1.11 ADD START ***************** --
                    /*+
                      INDEX ( XEL XXCOS_EDI_LINES_N01 )
                      USE_NL ( OTTT_H )
                    */
-- ************ 2009/08/12 N.Maeda 1.11 ADD  END  ***************** --
/* 2009/09/15 Ver1.12 Mod Start */
--                    '2'                                 select_block
                     cv_select_block_2                  select_block
/* 2009/09/15 Ver1.12 Mod End   */
                    -------------------- �w�b�_�f�[�^ -------------------------------------------------------------------------------
                    ,xeh.edi_header_info_id              xeh_edi_header_info_id     -- EDI�w�b�_���ID
                    ,xeh.medium_class                   xeh_medium_class           -- �}�̋敪
                    ,xeh.data_type_code                 xeh_data_type_code         -- �f�[�^��R�[�h
                    ,xeh.file_no                        xeh_file_no                -- �t�@�C���m��
                    ,xeh.info_class                     xeh_info_class             -- ���敪
                    ,xeh.process_date                   xeh_process_date           -- ������
                    ,xeh.process_time                   xeh_process_time           -- ��������
                    ,xeh.base_code                      xeh_base_code              -- ���_�i����j�R�[�h
                    ,xeh.base_name                      xeh_base_name              -- ���_���i�������j
                    ,xeh.base_name_alt                  xeh_base_name_alt          -- ���_���i�J�i�j
                    ,xeh.edi_chain_code                 xeh_edi_chain_code         -- �d�c�h�`�F�[���X�R�[�h
                    ,xeh.edi_chain_name                 xeh_edi_chain_name         -- �d�c�h�`�F�[���X���i�����j
                    ,xeh.edi_chain_name_alt             xeh_edi_chain_name_alt     -- �d�c�h�`�F�[���X���i�J�i�j
                    ,xeh.chain_code                     xeh_chain_code             -- �`�F�[���X�R�[�h
                    ,xeh.chain_name                     xeh_chain_name             -- �`�F�[���X���i�����j
                    ,xeh.chain_name_alt                 xeh_chain_name_alt         -- �`�F�[���X���i�J�i�j
                    ,xeh.report_code                    xeh_report_code            -- ���[�R�[�h
                    ,xeh.report_show_name               xeh_report_show_name       -- ���[�\����
                    ,xeh.customer_code                  xeh_customer_code          -- �ڋq�R�[�h
                    ,xeh.customer_name                  xeh_customer_name          -- �ڋq���i�����j
                    ,xeh.customer_name_alt              xeh_customer_name_alt      -- �ڋq���i�J�i�j
                    ,xeh.company_code                   xeh_company_code           -- �ЃR�[�h
                    ,xeh.company_name                   xeh_company_name           -- �Ж��i�����j
                    ,xeh.company_name_alt               xeh_company_name_alt       -- �Ж��i�J�i�j
                    ,xeh.shop_code                      xeh_shop_code              -- �X�R�[�h
                    ,xeh.shop_name                      xeh_shop_name              -- �X���i�����j
                    ,xeh.shop_name_alt                  xeh_shop_name_alt          -- �X���i�J�i�j
                    ,xeh.delivery_center_code           xeh_delivery_center_code   -- �[���Z���^�[�R�[�h
                    ,xeh.delivery_center_name           xeh_delivery_center_name   -- �[���Z���^�[���i�����j
                    ,xeh.delivery_center_name_alt       xeh_delivery_center_name_alt   -- �[���Z���^�[���i�J�i�j
                    ,xeh.order_date                     xeh_order_date             -- ������
                    ,xeh.center_delivery_date           xeh_center_delivery_date   -- �Z���^�[�[�i��
                    ,xeh.result_delivery_date           xeh_result_delivery_date   -- ���[�i��
                    ,xeh.shop_delivery_date             xeh_shop_delivery_date     -- �X�ܔ[�i��
                    ,xeh.data_creation_date_edi_data    xeh_data_creat_date_edi_d    -- �f�[�^�쐬���i�d�c�h�f�[�^���j
-- ************ 2010/03/10 T.Nakano 1.15 ADD START ***************** --
                    ,xeh.edi_received_date              xeh_edi_received_date        -- EDI��M��
-- ************ 2010/03/10 T.Nakano 1.15 ADD START ***************** --
                    ,xeh.data_creation_time_edi_data    xeh_data_creation_time_edi_d -- �f�[�^�쐬�����i�d�c�h�f�[�^���j
                    ,xeh.invoice_class                  xeh_invoice_class            -- �`�[�敪
                    ,xeh.small_classification_code      xeh_small_classification_code   -- �����ރR�[�h
                    ,xeh.small_classification_name      xeh_small_classification_name   -- �����ޖ�
                    ,xeh.middle_classification_code     xeh_middle_classification_code  -- �����ރR�[�h
                    ,xeh.middle_classification_name     xeh_middle_classification_name  -- �����ޖ�
                    ,xeh.big_classification_code        xeh_big_classification_code     -- �啪�ރR�[�h
                    ,xeh.big_classification_name        xeh_big_classification_name     -- �啪�ޖ�
                    ,xeh.other_party_department_code    xeh_other_party_department_c    -- ����敔��R�[�h
                    ,xeh.other_party_order_number       xeh_other_party_order_number    -- ����攭���ԍ�
                    ,xeh.check_digit_class              xeh_check_digit_class           -- �`�F�b�N�f�W�b�g�L���敪
                    ,xeh.invoice_number                 xeh_invoice_number              -- �`�[�ԍ�
                    ,xeh.check_digit                    xeh_check_digit                 -- �`�F�b�N�f�W�b�g
                    ,xeh.close_date                     xeh_close_date                  -- ����
                    ,xeh.order_no_ebs                   xeh_order_no_ebs                -- �󒍂m���i�d�a�r�j
                    ,xeh.ar_sale_class                  xeh_ar_sale_class               -- �����敪
                    ,xeh.delivery_classe                xeh_delivery_classe             -- �z���敪
                    ,xeh.opportunity_no                 xeh_opportunity_no              -- �ւm��
                    ,xeh.contact_to                     xeh_contact_to                  -- �A����
                    ,xeh.route_sales                    xeh_route_sales                 -- ���[�g�Z�[���X
                    ,xeh.corporate_code                 xeh_corporate_code              -- �@�l�R�[�h
                    ,xeh.maker_name                     xeh_maker_name                  -- ���[�J�[��
                    ,xeh.area_code                      xeh_area_code                   -- �n��R�[�h
                    ,xeh.area_name                      xeh_area_name                   -- �n�於�i�����j
                    ,xeh.area_name_alt                  xeh_area_name_alt               -- �n�於�i�J�i�j
                    ,xeh.vendor_code                    xeh_vendor_code                 -- �����R�[�h
                    ,xeh.vendor_name                    xeh_vendor_name                 -- ����於�i�����j
                    ,xeh.vendor_name1_alt               xeh_vendor_name1_alt            -- ����於�P�i�J�i�j
                    ,xeh.vendor_name2_alt               xeh_vendor_name2_alt            -- ����於�Q�i�J�i�j
                    ,xeh.vendor_tel                     xeh_vendor_tel                  -- �����s�d�k
                    ,xeh.vendor_charge                  xeh_vendor_charge               -- �����S����
                    ,xeh.vendor_address                 xeh_vendor_address              -- �����Z���i�����j
                    ,xeh.deliver_to_code_itouen         xeh_deliver_to_code_itouen      -- �͂���R�[�h�i�ɓ����j
                    ,xeh.deliver_to_code_chain          xeh_deliver_to_code_chain       -- �͂���R�[�h�i�`�F�[���X�j
                    ,xeh.deliver_to                     xeh_deliver_to                  -- �͂���i�����j
                    ,xeh.deliver_to1_alt                xeh_deliver_to1_alt             -- �͂���P�i�J�i�j
                    ,xeh.deliver_to2_alt                xeh_deliver_to2_alt             -- �͂���Q�i�J�i�j
                    ,xeh.deliver_to_address             xeh_deliver_to_address          -- �͂���Z���i�����j
                    ,xeh.deliver_to_address_alt         xeh_deliver_to_address_alt      -- �͂���Z���i�J�i�j
                    ,xeh.deliver_to_tel                 xeh_deliver_to_tel              -- �͂���s�d�k
                    ,xeh.balance_accounts_code          xeh_balance_accounts_code       -- ������R�[�h
                    ,xeh.balance_accounts_company_code  xeh_balance_accounts_comp_c     -- ������ЃR�[�h
                    ,xeh.balance_accounts_shop_code     xeh_balance_accounts_shop_c     -- ������X�R�[�h
                    ,xeh.balance_accounts_name          xeh_balance_accounts_name       -- �����於�i�����j
                    ,xeh.balance_accounts_name_alt      xeh_balance_accounts_name_alt   -- �����於�i�J�i�j
                    ,xeh.balance_accounts_address       xeh_balance_accounts_address    -- ������Z���i�����j
                    ,xeh.balance_accounts_address_alt   xeh_balance_accounts_addr_alt   -- ������Z���i�J�i�j
                    ,xeh.balance_accounts_tel           xeh_balance_accounts_tel        -- ������s�d�k
                    ,xeh.order_possible_date            xeh_order_possible_date         -- �󒍉\��
                    ,xeh.permission_possible_date       xeh_permission_possible_date    -- ���e�\��
                    ,xeh.forward_month                  xeh_forward_month               -- ����N����
                    ,xeh.payment_settlement_date        xeh_payment_settlement_date     -- �x�����ϓ�
                    ,xeh.handbill_start_date_active     xeh_handbill_start_date_active  -- �`���V�J�n��
                    ,xeh.billing_due_date               xeh_billing_due_date            -- ��������
                    ,xeh.shipping_time                  xeh_shipping_time               -- �o�׎���
                    ,xeh.delivery_schedule_time         xeh_delivery_schedule_time      -- �[�i�\�莞��
                    ,xeh.order_time                     xeh_order_time                  -- ��������
                    ,xeh.general_date_item1             xeh_general_date_item1          -- �ėp���t���ڂP
                    ,xeh.general_date_item2             xeh_general_date_item2          -- �ėp���t���ڂQ
                    ,xeh.general_date_item3             xeh_general_date_item3          -- �ėp���t���ڂR
                    ,xeh.general_date_item4             xeh_general_date_item4          -- �ėp���t���ڂS
                    ,xeh.general_date_item5             xeh_general_date_item5          -- �ėp���t���ڂT
                    ,xeh.arrival_shipping_class         xeh_arrival_shipping_class      -- ���o�׋敪
                    ,xeh.vendor_class                   xeh_vendor_class                -- �����敪
                    ,xeh.invoice_detailed_class         xeh_invoice_detailed_class      -- �`�[����敪
                    ,xeh.unit_price_use_class           xeh_unit_price_use_class        -- �P���g�p�敪
                    ,xeh.sub_distribution_center_code   xeh_sub_distribution_center_c     -- �T�u�����Z���^�[�R�[�h
                    ,xeh.sub_distribution_center_name   xeh_sub_distribution_center_n     -- �T�u�����Z���^�[�R�[�h��
                    ,xeh.center_delivery_method         xeh_center_delivery_method      -- �Z���^�[�[�i���@
                    ,xeh.center_use_class               xeh_center_use_class            -- �Z���^�[���p�敪
                    ,xeh.center_whse_class              xeh_center_whse_class           -- �Z���^�[�q�ɋ敪
                    ,xeh.center_area_class              xeh_center_area_class           -- �Z���^�[�n��敪
                    ,xeh.center_arrival_class           xeh_center_arrival_class        -- �Z���^�[���׋敪
                    ,xeh.depot_class                    xeh_depot_class                 -- �f�|�敪
                    ,xeh.tcdc_class                     xeh_tcdc_class                  -- �s�b�c�b�敪
                    ,xeh.upc_flag                       xeh_upc_flag                    -- �t�o�b�t���O
                    ,xeh.simultaneously_class           xeh_simultaneously_class        -- ��ċ敪
                    ,xeh.business_id                    xeh_business_id                 -- �Ɩ��h�c
                    ,xeh.whse_directly_class            xeh_whse_directly_class         -- �q���敪
                    ,xeh.premium_rebate_class           xeh_premium_rebate_class        -- �i�i���ߋ敪
                    ,xeh.item_type                      xeh_item_type                   -- ���ڎ��
                    ,xeh.cloth_house_food_class         xeh_cloth_house_food_class      -- �߉ƐH�敪
                    ,xeh.mix_class                      xeh_mix_class                   -- ���݋敪
                    ,xeh.stk_class                      xeh_stk_class                   -- �݌ɋ敪
                    ,xeh.last_modify_site_class         xeh_last_modify_site_class      -- �ŏI�C���ꏊ�敪
                    ,xeh.report_class                   xeh_report_class                -- ���[�敪
                    ,xeh.addition_plan_class            xeh_addition_plan_class         -- �ǉ��E�v��敪
                    ,xeh.registration_class             xeh_registration_class          -- �o�^�敪
                    ,xeh.specific_class                 xeh_specific_class              -- ����敪
                    ,xeh.dealings_class                 xeh_dealings_class              -- ����敪
                    ,xeh.order_class                    xeh_order_class                 -- �����敪
                    ,xeh.sum_line_class                 xeh_sum_line_class              -- �W�v���׋敪
                    ,xeh.shipping_guidance_class        xeh_shipping_guidance_class     -- �o�׈ē��ȊO�敪
                    ,xeh.shipping_class                 xeh_shipping_class              -- �o�׋敪
                    ,xeh.product_code_use_class         xeh_product_code_use_class      -- ���i�R�[�h�g�p�敪
                    ,xeh.cargo_item_class               xeh_cargo_item_class            -- �ϑ��i�敪
                    ,xeh.ta_class                       xeh_ta_class                    -- �s�^�`�敪
                    ,xeh.plan_code                      xeh_plan_code                   -- ���R�[�h
                    ,xeh.category_code                  xeh_category_code               -- �J�e�S���[�R�[�h
                    ,xeh.category_class                 xeh_category_class              -- �J�e�S���[�敪
                    ,xeh.carrier_means                  xeh_carrier_means               -- �^����i
                    ,xeh.counter_code                   xeh_counter_code                -- ����R�[�h
                    ,xeh.move_sign                      xeh_move_sign                   -- �ړ��T�C��
                    ,xeh.eos_handwriting_class          xeh_eos_handwriting_class       -- �d�n�r�E�菑�敪
                    ,xeh.delivery_to_section_code       xeh_delivery_to_section_code    -- �[�i��ۃR�[�h
                    ,xeh.invoice_detailed               xeh_invoice_detailed            -- �`�[����
                    ,xeh.attach_qty                     xeh_attach_qty                  -- �Y�t��
                    ,xeh.other_party_floor              xeh_other_party_floor           -- �t���A
                    ,xeh.text_no                        xeh_text_no                     -- �s�d�w�s�m��
                    ,xeh.in_store_code                  xeh_in_store_code               -- �C���X�g�A�R�[�h
                    ,xeh.tag_data                       xeh_tag_data                    -- �^�O
                    ,xeh.competition_code               xeh_competition_code            -- ����
                    ,xeh.billing_chair                  xeh_billing_chair               -- ��������
                    ,xeh.chain_store_code               xeh_chain_store_code            -- �`�F�[���X�g�A�[�R�[�h
                    ,xeh.chain_store_short_name         xeh_chain_store_short_name      -- �`�F�[���X�g�A�[�R�[�h��������
                    ,xeh.direct_delivery_rcpt_fee       xeh_direct_delivery_rcpt_fee    -- ���z���^���旿
                    ,xeh.bill_info                      xeh_bill_info                   -- ��`���
                    ,xeh.description                    xeh_description                 -- �E�v
                    ,xeh.interior_code                  xeh_interior_code               -- �����R�[�h
                    ,xeh.order_info_delivery_category   xeh_order_info_delivery_cate    -- �������@�[�i�J�e�S���[
                    ,xeh.purchase_type                  xeh_purchase_type               -- �d���`��
                    ,xeh.delivery_to_name_alt           xeh_delivery_to_name_alt        -- �[�i�ꏊ���i�J�i�j
                    ,xeh.shop_opened_site               xeh_shop_opened_site            -- �X�o�ꏊ
                    ,xeh.counter_name                   xeh_counter_name                -- ���ꖼ
                    ,xeh.extension_number               xeh_extension_number            -- �����ԍ�
                    ,xeh.charge_name                    xeh_charge_name                 -- �S���Җ�
                    ,xeh.price_tag                      xeh_price_tag                   -- �l�D
                    ,xeh.tax_type                       xeh_tax_type                    -- �Ŏ�
                    ,xeh.consumption_tax_class          xeh_consumption_tax_class       -- ����ŋ敪
                    ,xeh.brand_class                    xeh_brand_class                 -- �a�q
                    ,xeh.id_code                        xeh_id_code                     -- �h�c�R�[�h
                    ,xeh.department_code                xeh_department_code             -- �S�ݓX�R�[�h
                    ,xeh.department_name                xeh_department_name             -- �S�ݓX��
                    ,xeh.item_type_number               xeh_item_type_number            -- �i�ʔԍ�
                    ,xeh.description_department         xeh_description_department      -- �E�v�i�S�ݓX�j
                    ,xeh.price_tag_method               xeh_price_tag_method            -- �l�D���@
                    ,xeh.reason_column                  xeh_reason_column               -- ���R��
                    ,xeh.a_column_header                xeh_a_column_header             -- �`���w�b�_
                    ,xeh.d_column_header                xeh_d_column_header             -- �c���w�b�_
                    ,xeh.brand_code                     xeh_brand_code                  -- �u�����h�R�[�h
                    ,xeh.line_code                      xeh_line_code                   -- ���C���R�[�h
                    ,xeh.class_code                     xeh_class_code                  -- �N���X�R�[�h
                    ,xeh.a1_column                      xeh_a1_column                   -- �`�|�P��
                    ,xeh.b1_column                      xeh_b1_column                   -- �a�|�P��
                    ,xeh.c1_column                      xeh_c1_column                   -- �b�|�P��
                    ,xeh.d1_column                      xeh_d1_column                   -- �c�|�P��
                    ,xeh.e1_column                      xeh_e1_column                   -- �d�|�P��
                    ,xeh.a2_column                      xeh_a2_column                   -- �`�|�Q��
                    ,xeh.b2_column                      xeh_b2_column                   -- �a�|�Q��
                    ,xeh.c2_column                      xeh_c2_column                   -- �b�|�Q��
                    ,xeh.d2_column                      xeh_d2_column                   -- �c�|�Q��
                    ,xeh.e2_column                      xeh_e2_column                   -- �d�|�Q��
                    ,xeh.a3_column                      xeh_a3_column                   -- �`�|�R��
                    ,xeh.b3_column                      xeh_b3_column                   -- �a�|�R��
                    ,xeh.c3_column                      xeh_c3_column                   -- �b�|�R��
                    ,xeh.d3_column                      xeh_d3_column                   -- �c�|�R��
                    ,xeh.e3_column                      xeh_e3_column                   -- �d�|�R��
                    ,xeh.f1_column                      xeh_f1_column                   -- �e�|�P��
                    ,xeh.g1_column                      xeh_g1_column                   -- �f�|�P��
                    ,xeh.h1_column                      xeh_h1_column                   -- �g�|�P��
                    ,xeh.i1_column                      xeh_i1_column                   -- �h�|�P��
                    ,xeh.j1_column                      xeh_j1_column                   -- �i�|�P��
                    ,xeh.k1_column                      xeh_k1_column                   -- �j�|�P��
                    ,xeh.l1_column                      xeh_l1_column                   -- �k�|�P��
                    ,xeh.f2_column                      xeh_f2_column                   -- �e�|�Q��
                    ,xeh.g2_column                      xeh_g2_column                   -- �f�|�Q��
                    ,xeh.h2_column                      xeh_h2_column                   -- �g�|�Q��
                    ,xeh.i2_column                      xeh_i2_column                   -- �h�|�Q��
                    ,xeh.j2_column                      xeh_j2_column                   -- �i�|�Q��
                    ,xeh.k2_column                      xeh_k2_column                   -- �j�|�Q��
                    ,xeh.l2_column                      xeh_l2_column                   -- �k�|�Q��
                    ,xeh.f3_column                      xeh_f3_column                   -- �e�|�R��
                    ,xeh.g3_column                      xeh_g3_column                   -- �f�|�R��
                    ,xeh.h3_column                      xeh_h3_column                   -- �g�|�R��
                    ,xeh.i3_column                      xeh_i3_column                   -- �h�|�R��
                    ,xeh.j3_column                      xeh_j3_column                   -- �i�|�R��
                    ,xeh.k3_column                      xeh_k3_column                   -- �j�|�R��
                    ,xeh.l3_column                      xeh_l3_column                   -- �k�|�R��
                    ,xeh.chain_peculiar_area_header     xeh_chain_peculiar_area_header  -- �`�F�[���X�ŗL�G���A�i�w�b�_�[�j
                    ,xeh.order_connection_number        xeh_order_connection_number     -- �󒍊֘A�ԍ�
                    ,xeh.invoice_indv_order_qty         xeh_invoice_indv_order_qty      -- �i�`�[�v�j�������ʁi�o���j
                    ,xeh.invoice_case_order_qty         xeh_invoice_case_order_qty      -- �i�`�[�v�j�������ʁi�P�[�X�j
                    ,xeh.invoice_ball_order_qty         xeh_invoice_ball_order_qty      -- �i�`�[�v�j�������ʁi�{�[���j
                    ,xeh.invoice_sum_order_qty          xeh_invoice_sum_order_qty       -- �i�`�[�v�j�������ʁi���v�A�o���j
                    ,xeh.invoice_indv_shipping_qty      xeh_invoice_indv_shipping_qty   -- �i�`�[�v�j�o�א��ʁi�o���j
                    ,xeh.invoice_case_shipping_qty      xeh_invoice_case_shipping_qty   -- �i�`�[�v�j�o�א��ʁi�P�[�X�j
                    ,xeh.invoice_ball_shipping_qty      xeh_invoice_ball_shipping_qty   -- �i�`�[�v�j�o�א��ʁi�{�[���j
                    ,xeh.invoice_pallet_shipping_qty    xeh_invoice_pallet_ship_qty     -- �i�`�[�v�j�o�א��ʁi�p���b�g�j
                    ,xeh.invoice_sum_shipping_qty       xeh_invoice_sum_shipping_qty    -- �i�`�[�v�j�o�א��ʁi���v�A�o���j
                    ,xeh.invoice_indv_stockout_qty      xeh_invoice_indv_stockout_qty   -- �i�`�[�v�j���i���ʁi�o���j
                    ,xeh.invoice_case_stockout_qty      xeh_invoice_case_stockout_qty   -- �i�`�[�v�j���i���ʁi�P�[�X�j
                    ,xeh.invoice_ball_stockout_qty      xeh_invoice_ball_stockout_qty   -- �i�`�[�v�j���i���ʁi�{�[���j
                    ,xeh.invoice_sum_stockout_qty       xeh_invoice_sum_stockout_qty    -- �i�`�[�v�j���i���ʁi���v�A�o���j
                    ,xeh.invoice_case_qty               xeh_invoice_case_qty            -- �i�`�[�v�j�P�[�X����
                    ,xeh.invoice_fold_container_qty     xeh_invoice_fold_container_qty  -- �i�`�[�v�j�I���R���i�o���j����
                    ,xeh.invoice_order_cost_amt         xeh_invoice_order_cost_amt      -- �i�`�[�v�j�������z�i�����j
                    ,xeh.invoice_shipping_cost_amt      xeh_invoice_shipping_cost_amt   -- �i�`�[�v�j�������z�i�o�ׁj
                    ,xeh.invoice_stockout_cost_amt      xeh_invoice_stockout_cost_amt   -- �i�`�[�v�j�������z�i���i�j
                    ,xeh.invoice_order_price_amt        xeh_invoice_order_price_amt     -- �i�`�[�v�j�������z�i�����j
                    ,xeh.invoice_shipping_price_amt     xeh_invoice_shipping_price_amt  -- �i�`�[�v�j�������z�i�o�ׁj
                    ,xeh.invoice_stockout_price_amt     xeh_invoice_stockout_price_amt  -- �i�`�[�v�j�������z�i���i�j
                    ,xeh.total_indv_order_qty           xeh_total_indv_order_qty        -- �i�����v�j�������ʁi�o���j
                    ,xeh.total_case_order_qty           xeh_total_case_order_qty        -- �i�����v�j�������ʁi�P�[�X�j
                    ,xeh.total_ball_order_qty           xeh_total_ball_order_qty        -- �i�����v�j�������ʁi�{�[���j
                    ,xeh.total_sum_order_qty            xeh_total_sum_order_qty         -- �i�����v�j�������ʁi���v�A�o���j
                    ,xeh.total_indv_shipping_qty        xeh_total_indv_shipping_qty     -- �i�����v�j�o�א��ʁi�o���j
                    ,xeh.total_case_shipping_qty        xeh_total_case_shipping_qty     -- �i�����v�j�o�א��ʁi�P�[�X�j
                    ,xeh.total_ball_shipping_qty        xeh_total_ball_shipping_qty     -- �i�����v�j�o�א��ʁi�{�[���j
                    ,xeh.total_pallet_shipping_qty      xeh_total_pallet_shipping_qty   -- �i�����v�j�o�א��ʁi�p���b�g�j
                    ,xeh.total_sum_shipping_qty         xeh_total_sum_shipping_qty      -- �i�����v�j�o�א��ʁi���v�A�o���j
                    ,xeh.total_indv_stockout_qty        xeh_total_indv_stockout_qty     -- �i�����v�j���i���ʁi�o���j
                    ,xeh.total_case_stockout_qty        xeh_total_case_stockout_qty     -- �i�����v�j���i���ʁi�P�[�X�j
                    ,xeh.total_ball_stockout_qty        xeh_total_ball_stockout_qty     -- �i�����v�j���i���ʁi�{�[���j
                    ,xeh.total_sum_stockout_qty         xeh_total_sum_stockout_qty      -- �i�����v�j���i���ʁi���v�A�o���j
                    ,xeh.total_case_qty                 xeh_total_case_qty              -- �i�����v�j�P�[�X����
                    ,xeh.total_fold_container_qty       xeh_total_fold_container_qty    -- �i�����v�j�I���R���i�o���j����
                    ,xeh.total_order_cost_amt           xeh_total_order_cost_amt        -- �i�����v�j�������z�i�����j
                    ,xeh.total_shipping_cost_amt        xeh_total_shipping_cost_amt     -- �i�����v�j�������z�i�o�ׁj
                    ,xeh.total_stockout_cost_amt        xeh_total_stockout_cost_amt     -- �i�����v�j�������z�i���i�j
                    ,xeh.total_order_price_amt          xeh_total_order_price_amt       -- �i�����v�j�������z�i�����j
                    ,xeh.total_shipping_price_amt       xeh_total_shipping_price_amt    -- �i�����v�j�������z�i�o�ׁj
                    ,xeh.total_stockout_price_amt       xeh_total_stockout_price_amt    -- �i�����v�j�������z�i���i�j
                    ,xeh.total_line_qty                 xeh_total_line_qty              -- �g�[�^���s��
                    ,xeh.total_invoice_qty              xeh_total_invoice_qty           -- �g�[�^���`�[����
                    ,xeh.chain_peculiar_area_footer     xeh_chain_peculiar_area_footer  -- �`�F�[���X�ŗL�G���A�i�t�b�^�[�j
                    ,xeh.conv_customer_code             xeh_conv_customer_code          -- �ϊ���ڋq�R�[�h
                    ,xeh.order_forward_flag             xeh_order_forward_flag          -- �󒍘A�g�σt���O
                    ,xeh.creation_class                 xeh_creation_class              -- �쐬���敪
                    ,xeh.edi_delivery_schedule_flag     xeh_edi_delivery_schedule_flag  -- EDI�[�i�\�著�M�σt���O
                    ,xeh.price_list_header_id           xeh_price_list_header_id        -- ���i�\�w�b�_ID
                    ,xeh.deliv_slip_flag_area_chain     xeh_deliv_slip_flag_area_chain  -- �[�i�����s�t���O�G���A�i�`�F�[���X�l���j
                    ,xeh.deliv_slip_flag_area_cmn       xeh_deliv_slip_flag_area_cmn    -- �[�i�����s�t���O�G���A�i���ʗl���j
-- 2011/10/06 A.Shirakawa Ver.1.19 ADD START
                    ,xeh.bms_header_data                xeh_bms_header_data             -- ���ʂa�l�r�w�b�_�f�[�^
-- 2011/10/06 A.Shirakawa Ver.1.19 ADD END
                    -------------------- ���׃f�[�^ -------------------------------------------------------------------------------
                    ,xel.edi_line_info_id               xel_edi_line_info_id            -- EDI���׏��ID
                    ,xel.edi_header_info_id             xel_edi_header_info_id          -- EDI�w�b�_���ID
                    ,xel.line_no                        xel_line_no                     -- �s�m��
                    ,xel.stockout_class                 xel_stockout_class              -- ���i�敪
                    ,xel.stockout_reason                xel_stockout_reason             -- ���i���R
                    ,xel.product_code_itouen            xel_product_code_itouen         -- ���i�R�[�h�i�ɓ����j
                    ,xel.product_code1                  xel_product_code1               -- ���i�R�[�h�P
                    ,xel.product_code2                  xel_product_code2               -- ���i�R�[�h�Q
                    ,xel.jan_code                       xel_jan_code                    -- �i�`�m�R�[�h
                    ,xel.itf_code                       xel_itf_code                    -- �h�s�e�R�[�h
                    ,xel.extension_itf_code             xel_extension_itf_code          -- �����h�s�e�R�[�h
                    ,xel.case_product_code              xel_case_product_code           -- �P�[�X���i�R�[�h
                    ,xel.ball_product_code              xel_ball_product_code           -- �{�[�����i�R�[�h
                    ,xel.product_code_item_type         xel_product_code_item_type      -- ���i�R�[�h�i��
                    ,xel.prod_class                     xel_prod_class                  -- ���i�敪
                    ,xel.product_name                   xel_product_name                -- ���i���i�����j
                    ,xel.product_name1_alt              xel_product_name1_alt           -- ���i���P�i�J�i�j
                    ,xel.product_name2_alt              xel_product_name2_alt           -- ���i���Q�i�J�i�j
                    ,xel.item_standard1                 xel_item_standard1              -- �K�i�P
                    ,xel.item_standard2                 xel_item_standard2              -- �K�i�Q
                    ,xel.qty_in_case                    xel_qty_in_case                 -- ����
                    ,xel.num_of_cases                   xel_num_of_cases                -- �P�[�X����
                    ,xel.num_of_ball                    xel_num_of_ball                 -- �{�[������
                    ,xel.item_color                     xel_item_color                  -- �F
                    ,xel.item_size                      xel_item_size                   -- �T�C�Y
                    ,xel.expiration_date                xel_expiration_date             -- �ܖ�������
                    ,xel.product_date                   xel_product_date                -- ������
                    ,xel.order_uom_qty                  xel_order_uom_qty               -- �����P�ʐ�
                    ,xel.shipping_uom_qty               xel_shipping_uom_qty            -- �o�גP�ʐ�
                    ,xel.packing_uom_qty                xel_packing_uom_qty             -- ����P�ʐ�
                    ,xel.deal_code                      xel_deal_code                   -- ����
                    ,xel.deal_class                     xel_deal_class                  -- �����敪
                    ,xel.collation_code                 xel_collation_code              -- �ƍ�
                    ,xel.uom_code                       xel_uom_code                    -- �P��
                    ,xel.unit_price_class               xel_unit_price_class            -- �P���敪
                    ,xel.parent_packing_number          xel_parent_packing_number       -- �e����ԍ�
                    ,xel.packing_number                 xel_packing_number              -- ����ԍ�
                    ,xel.product_group_code             xel_product_group_code          -- ���i�Q�R�[�h
                    ,xel.case_dismantle_flag            xel_case_dismantle_flag         -- �P�[�X��̕s�t���O
                    ,xel.case_class                     xel_case_class                  -- �P�[�X�敪
                    ,xel.indv_order_qty                 xel_indv_order_qty              -- �������ʁi�o���j
                    ,xel.case_order_qty                 xel_case_order_qty              -- �������ʁi�P�[�X�j
                    ,xel.ball_order_qty                 xel_ball_order_qty              -- �������ʁi�{�[���j
                    ,xel.sum_order_qty                  xel_sum_order_qty               -- �������ʁi���v�A�o���j
                    ,xel.indv_shipping_qty              xel_indv_shipping_qty           -- �o�א��ʁi�o���j
                    ,xel.case_shipping_qty              xel_case_shipping_qty           -- �o�א��ʁi�P�[�X�j
                    ,xel.ball_shipping_qty              xel_ball_shipping_qty           -- �o�א��ʁi�{�[���j
                    ,xel.pallet_shipping_qty            xel_pallet_shipping_qty         -- �o�א��ʁi�p���b�g�j
                    ,xel.sum_shipping_qty               xel_sum_shipping_qty            -- �o�א��ʁi���v�A�o���j
                    ,xel.indv_stockout_qty              xel_indv_stockout_qty           -- ���i���ʁi�o���j
                    ,xel.case_stockout_qty              xel_case_stockout_qty           -- ���i���ʁi�P�[�X�j
                    ,xel.ball_stockout_qty              xel_ball_stockout_qty           -- ���i���ʁi�{�[���j
                    ,xel.sum_stockout_qty               xel_sum_stockout_qty            -- ���i���ʁi���v�A�o���j
                    ,xel.case_qty                       xel_case_qty                    -- �P�[�X����
                    ,xel.fold_container_indv_qty        xel_fold_container_indv_qty     -- �I���R���i�o���j����
                    ,xel.order_unit_price               xel_order_unit_price            -- ���P���i�����j
                    ,xel.shipping_unit_price            xel_shipping_unit_price         -- ���P���i�o�ׁj
                    ,xel.order_cost_amt                 xel_order_cost_amt              -- �������z�i�����j
                    ,xel.shipping_cost_amt              xel_shipping_cost_amt           -- �������z�i�o�ׁj
                    ,xel.stockout_cost_amt              xel_stockout_cost_amt           -- �������z�i���i�j
                    ,xel.selling_price                  xel_selling_price               -- ���P��
                    ,xel.order_price_amt                xel_order_price_amt             -- �������z�i�����j
                    ,xel.shipping_price_amt             xel_shipping_price_amt          -- �������z�i�o�ׁj
                    ,xel.stockout_price_amt             xel_stockout_price_amt          -- �������z�i���i�j
                    ,xel.a_column_department            xel_a_column_department         -- �`���i�S�ݓX�j
                    ,xel.d_column_department            xel_d_column_department         -- �c���i�S�ݓX�j
                    ,xel.standard_info_depth            xel_standard_info_depth         -- �K�i���E���s��
                    ,xel.standard_info_height           xel_standard_info_height        -- �K�i���E����
                    ,xel.standard_info_width            xel_standard_info_width         -- �K�i���E��
                    ,xel.standard_info_weight           xel_standard_info_weight        -- �K�i���E�d��
                    ,xel.general_succeeded_item1        xel_general_succeeded_item1     -- �ėp���p�����ڂP
                    ,xel.general_succeeded_item2        xel_general_succeeded_item2     -- �ėp���p�����ڂQ
                    ,xel.general_succeeded_item3        xel_general_succeeded_item3     -- �ėp���p�����ڂR
                    ,xel.general_succeeded_item4        xel_general_succeeded_item4     -- �ėp���p�����ڂS
                    ,xel.general_succeeded_item5        xel_general_succeeded_item5     -- �ėp���p�����ڂT
                    ,xel.general_succeeded_item6        xel_general_succeeded_item6     -- �ėp���p�����ڂU
                    ,xel.general_succeeded_item7        xel_general_succeeded_item7     -- �ėp���p�����ڂV
                    ,xel.general_succeeded_item8        xel_general_succeeded_item8     -- �ėp���p�����ڂW
                    ,xel.general_succeeded_item9        xel_general_succeeded_item9     -- �ėp���p�����ڂX
                    ,xel.general_succeeded_item10       xel_general_succeeded_item10    -- �ėp���p�����ڂP�O
                    ,xel.general_add_item1              xel_general_add_item1           -- �ėp�t�����ڂP
                    ,xel.general_add_item2              xel_general_add_item2           -- �ėp�t�����ڂQ
                    ,xel.general_add_item3              xel_general_add_item3           -- �ėp�t�����ڂR
                    ,xel.general_add_item4              xel_general_add_item4           -- �ėp�t�����ڂS
                    ,xel.general_add_item5              xel_general_add_item5           -- �ėp�t�����ڂT
                    ,xel.general_add_item6              xel_general_add_item6           -- �ėp�t�����ڂU
                    ,xel.general_add_item7              xel_general_add_item7           -- �ėp�t�����ڂV
                    ,xel.general_add_item8              xel_general_add_item8           -- �ėp�t�����ڂW
                    ,xel.general_add_item9              xel_general_add_item9           -- �ėp�t�����ڂX
                    ,xel.general_add_item10             xel_general_add_item10          -- �ėp�t�����ڂP�O
                    ,xel.chain_peculiar_area_line       xel_chain_peculiar_area_line    -- �`�F�[���X�ŗL�G���A�i���ׁj
                    ,xel.item_code                      xel_item_code                   -- �i�ڃR�[�h
                    ,xel.line_uom                       xel_line_uom                    -- ���גP��
                    ,xel.hht_delivery_schedule_flag     xel_hht_delivery_schedule_flag  -- HHT�[�i�\��A�g�σt���O
                    ,xel.order_connection_line_number   xel_order_connect_line_num  -- �󒍊֘A���הԍ�
                    ,xel.taking_unit_price              xel_taking_unit_price           -- �捞�����P���i�����j
-- 2011/10/06 A.Shirakawa Ver.1.19 ADD START
                    ,xel.bms_line_data                  xel_bms_line_data               -- ���ʂa�l�r���׃f�[�^
-- 2011/10/06 A.Shirakawa Ver.1.19 ADD END
                    ----------------- �ڋq��� --------------------------------------------------------------
                    ,NULL                               hca_account_number              -- �ڋq�R�[�h
                    ,NULL                               hp_party_name                   -- �ڋq���i�����j
                    ,NULL                               hp_organization_name_phonetic   -- �X���i�J�i�j
                    ,NULL                               xca_cust_store_name             -- �X���i�����j
                    ,NULL                               xca_deli_center_code            -- �[���Z���^�[�R�[�h
                    ,NULL                               xca_deli_center_name            -- �[���Z���^�[���i�����j
/* 2010/10/15 Ver1.18 Add Start */
                    ,NULL                               xca_edi_district_code           -- �n��R�[�h
/* 2010/10/15 Ver1.18 Add End   */
                    ,NULL                               xca_edi_district_name           -- �n�於�i�����j
                    ,NULL                               xca_edi_district_kana           -- �n�於�i�J�i�j
                    ,NULL                               xca_torihikisaki_code           -- �����R�[�h
                    ,NULL                               xca_tax_div                     -- ����ŋ敪
                    ,NULL                               xca_delivery_base_code          --
                    ,NULL                               avtab_tax_rate                  -- �ŗ�
                    ,g_input_rec.base_code              cdm_account_number
                    ,g_input_rec.base_name              cdm_base_name
                    ,i_base_rec.base_name_kana          cdm_base_name_kana
                    ,NULL                               cdm_phone_number
                    ,NULL                               cdm_state
                    ,NULL                               cdm_city
                    ,NULL                               cdm_address1
                    ,NULL                               cdm_address2
                    ,NULL                               cdm_vendor_name                 -- ����於
-- == 2010/04/20 V1.16 Added START ===============================================================
                   , xel.edi_unit_price                 edi_unit_price                  -- EDI���P���i�����j
-- == 2010/04/20 V1.16 Added END   ===============================================================
             FROM  xxcos_edi_headers                    xeh --EDI�w�b�_���e�[�u��
                  ,xxcos_edi_lines                      xel --EDI���׏��e�[�u��
             WHERE  xel.edi_header_info_id = xeh.edi_header_info_id
             AND    xeh.edi_chain_code = i_input_rec.ssm_store_code                     -- EDI�`�F�[���X�R�[�h
             AND    xeh.conv_customer_code IS NULL
-- ************ 2009/08/12 N.Maeda 1.11 ADD START ***************** --
             AND xeh.data_type_code = i_input_rec.data_type_code
-- ************ 2009/08/12 N.Maeda 1.11 ADD  END  ***************** --
              --�X�܃R�[�h��NULL�̕�(�ڋq�}�X�^�Ƀ}�X�^�f�[�^�����݂��Ȃ�����)
              --AND IN�p�����[�^�̓X�܃R�[�h IS NULL
              ) xeh_l
                    ,(
                      --�󒍂����݂���f�[�^
                      SELECT 
-- ************ 2009/08/12 N.Maeda 1.11 ADD START ***************** --
                             /*+
                               INDEX ( XEL XXCOS_EDI_LINES_N01 )
                               USE_NL ( OOS OTTT_H )
                             */
-- ************ 2009/08/12 N.Maeda 1.11 ADD  END  ***************** --
                             xeh.edi_header_info_id   edi_header_info_id   --EDI�w�b�_ID
                             ,xel.edi_line_info_id     edi_line_info_id    --EDI����ID
                             ,ooha.order_number        order_number        --�󒍔ԍ�
                             ,ooha.request_date        request_date        --�[�i��
                             ,xlvv.attribute8          bargain_class       --��ԓ����敪
                             ,xlvv.attribute10         outbound_flag       --OUTBOUND��
-- == 2010/04/20 V1.16 Added START ===============================================================
                            , oola.unit_selling_price  unit_selling_price  -- �̔��P��
                            , msib.segment1            item_code           -- �i�ڃR�[�h
-- == 2010/04/20 V1.16 Added END   ===============================================================
                      FROM    xxcos_edi_headers        xeh         --EDI�w�b�_
                             ,xxcos_edi_lines          xel         --EDI����
                             ,oe_order_headers_all     ooha        --�󒍃w�b�_
                             ,oe_transaction_types_tl  ottt_h      --�󒍃^�C�v(�w�b�_)
                             ,oe_order_sources         oos         --�󒍃\�[�X
                             ,oe_order_lines_all       oola        --�󒍖���
                             ,oe_transaction_types_tl  ottt_l      --�󒍃^�C�v(����)
                             ,xxcos_lookup_values_v    xlvv        --�N�C�b�N�R�[�h(����敪�}�X�^)
-- == 2010/04/20 V1.16 Added START ===============================================================
                            , mtl_system_items_b       msib        -- �i�ڃ}�X�^
-- == 2010/04/20 V1.16 Added END   ===============================================================
/* 2009/09/15 Ver1.12 Mod Start */
--                      WHERE   xeh.order_forward_flag        = 'Y'                        --�󒍘A�g��
                      WHERE   xeh.order_forward_flag        = cv_order_forward_flag_y    --�󒍘A�g��
/* 2009/09/15 Ver1.12 Mod End   */
                      AND     xeh.edi_header_info_id        = xel.edi_header_info_id
                      AND     xeh.order_connection_number   = ooha.orig_sys_document_ref
                      AND     ooha.org_id                   = i_prf_rec.org_id           --MO:�c�ƒP��
                      AND     ooha.flow_status_code        != cv_cancel                  --�X�e�[�^�X(�L�����Z���ȊO)
                      AND     ooha.order_type_id            = ottt_h.transaction_type_id
/* 2009/09/08 Ver1.12 Mod Start */
--                      AND     ottt_h.language               = userenv('LANG')
--                      AND     ottt_h.source_lang            = userenv('LANG')
                      AND     ottt_h.language               = ct_user_lang
                      AND     ottt_h.source_lang            = ct_user_lang
/* 2009/09/08 Ver1.12 Mod End   */
                      AND     ottt_h.description            = i_msg_rec.header_type      --�󒍃^�C�v(�w�b�_)
                      AND     ooha.order_source_id          = oos.order_source_id
                      AND     oos.description               = i_msg_rec.order_source     --�󒍃\�[�X
/* 2009/09/15 Ver1.12 Mod Start */
--                      AND     oos.enabled_flag              = 'Y'
                      AND     oos.enabled_flag              = cv_enabled_flag
/* 2009/09/15 Ver1.12 Mod End   */
                      AND     ooha.header_id                = oola.header_id
                      AND     ooha.org_id                   = oola.org_id                --MO:�c�ƒP��
                      AND     oola.orig_sys_line_ref        = xel.order_connection_line_number
--  2018/03/07 V1.20 Deleted SART
--                      AND     oola.flow_status_code        != cv_cancel                  --�X�e�[�^�X(�L�����Z���ȊO)
--  2018/03/07 V1.20 Deleted END
                      AND     oola.line_type_id             = ottt_l.transaction_type_id
/* 2009/09/08 Ver1.12 Mod Start */
--                      AND     ottt_l.language               = userenv('LANG')
--                      AND     ottt_l.source_lang            = userenv('LANG')
                      AND     ottt_l.language               = ct_user_lang
                      AND     ottt_l.source_lang            = ct_user_lang
/* 2009/09/08 Ver1.12 Mod End   */
                      AND     ottt_l.description            = i_msg_rec.line_type        --�󒍃^�C�v(����)
                      AND     xlvv.lookup_type(+)           = ct_qc_sale_class           --����敪
                      AND     xlvv.lookup_code(+)           = oola.attribute5
                      AND     i_other_rec.process_date
                                BETWEEN NVL(xlvv.start_date_active,i_other_rec.process_date)
                                AND     NVL(xlvv.end_date_active,i_other_rec.process_date)
-- ************ 2009/08/12 N.Maeda 1.11 ADD START ***************** --
                      AND     xeh.data_type_code = i_input_rec.data_type_code
                      AND     xeh.edi_chain_code = i_input_rec.ssm_store_code
-- ************ 2009/08/12 N.Maeda 1.11 ADD  END  ***************** --
-- == 2010/04/20 V1.16 Added START ===============================================================
                      AND     oola.inventory_item_id        =   msib.inventory_item_id
                      AND     msib.organization_id          =   i_other_rec.organization_id
-- == 2010/04/20 V1.16 Added END   ===============================================================
                      UNION ALL
                      --�󒍂����݂��Ȃ��f�[�^
                      SELECT  xeh.edi_header_info_id   edi_header_info_id  --EDI�w�b�_ID
                             ,xel.edi_line_info_id     edi_line_info_id    --EDI����ID
                             ,TO_NUMBER( NULL )        order_number        --�󒍔ԍ�
                             ,TO_DATE( NULL )          request_date        --�[�i��
                             ,TO_CHAR( NULL )          bargain_class       --��ԓ����敪
                             ,TO_CHAR( NULL )          outbound_flag       --OUTBOUND��
-- == 2010/04/20 V1.16 Added START ===============================================================
                            , TO_NUMBER(NULL)          unit_selling_price  -- �̔��P��
                            , xel.item_code            item_code           -- �i�ڃR�[�h
-- == 2010/04/20 V1.16 Added END   ===============================================================
                      FROM   xxcos_edi_headers         xeh         --EDI�w�b�_
                             ,xxcos_edi_lines          xel         --EDI����
/* 2010/01/04 Ver1.13 Add Start */
--/* 2009/09/15 Ver1.12 Mod Start */
----                      WHERE   xeh.order_forward_flag        = 'N'                        --�󒍖��A�g
--                      WHERE   xeh.order_forward_flag        = cv_order_forward_flag_n    --�󒍖��A�g
--/* 2009/09/15 Ver1.12 Mod End   */
                      WHERE   xeh.order_forward_flag       IN ( cv_order_forward_flag_n
                                                              , cv_order_forward_flag_s )
/* 2010/01/04 Ver1.13 Add End   */
                      AND     xeh.edi_header_info_id        = xel.edi_header_info_id
-- ************ 2009/08/12 N.Maeda 1.11 ADD START ***************** --
                      AND     xeh.data_type_code = i_input_rec.data_type_code
                      AND     xeh.edi_chain_code = i_input_rec.ssm_store_code
-- ************ 2009/08/12 N.Maeda 1.11 ADD  END  ***************** --
                     )                                      ixe                           --�Ώۃf�[�^����
            ,ic_item_mst_b                                                      iimb                          --OPM�i�ڃ}�X�^
            ,xxcmn_item_mst_b                                                   ximb                          --OPM�i�ڃ}�X�^�A�h�I��
            ,mtl_system_items_b                                                 msib                          --DISC�i�ڃ}�X�^
            ,xxcmm_system_items_b                                               xsib                          --DISC�i�ڃ}�X�^�A�h�I��
-- ************ 2009/08/12 N.Maeda 1.11 DEL START ***************** --
--            ,xxcos_head_prod_class_v                                            xhpc                          --�{�Џ��i�敪�r���[
-- ************ 2009/08/12 N.Maeda 1.11 DEL  END  ***************** --
--
-- ************ 2009/08/12 N.Maeda 1.11 MOD START ***************** --
--      WHERE  xeh_l.xeh_data_type_code = i_input_rec.data_type_code                                            --�f�[�^��R�[�h
--      AND (
--                 i_input_rec.info_div IS NULL                                                                     --���敪
--            OR   i_input_rec.info_div IS NOT NULL AND xeh_l.xeh_info_class = i_input_rec.info_div
--          )
      WHERE (
                 i_input_rec.info_div IS NULL                                                                     --���敪
            OR   i_input_rec.info_div IS NOT NULL AND xeh_l.xeh_info_class = i_input_rec.info_div
            )
-- ************ 2009/08/12 N.Maeda 1.11 MOD  END  ***************** --
      AND    NVL(TRUNC(xeh_l.xeh_shop_delivery_date)
                ,NVL(TRUNC(xeh_l.xeh_center_delivery_date)
                    ,NVL(TRUNC(xeh_l.xeh_order_date)
                        ,TRUNC(xeh_l.xeh_data_creat_date_edi_d))))
             BETWEEN TO_DATE(i_input_rec.shop_delivery_date_from, cv_date_fmt)
             AND     TO_DATE(i_input_rec.shop_delivery_date_to, cv_date_fmt)
-- ************ 2010/03/10 T.Nakano 1.15 MOD START ***************** --
--      AND (
--             i_input_rec.edi_input_date IS NULL                                                               --EDI�捞��
--        OR   i_input_rec.edi_input_date IS NOT NULL
--        AND  TRUNC(xeh_l.xeh_data_creat_date_edi_d) = TO_DATE(i_input_rec.edi_input_date,cv_date_fmt)
--        )
      AND (
            (i_input_rec.edi_input_date IS NULL)                                                              --EDI�捞��
        OR  (i_input_rec.edi_input_date IS NOT NULL
          AND  TRUNC(xeh_l.xeh_edi_received_date) = TO_DATE(i_input_rec.edi_input_date,cv_date_fmt))
        )
-- ************ 2010/03/10 T.Nakano 1.15 MOD END ***************** --
      AND    xxcos_common2_pkg.get_deliv_slip_flag(                                                           --�[�i�����s�t���O�擾�֐�
               i_input_rec.publish_flag_seq                                                          --�[�i�����s�t���O����
              ,DECODE(i_input_rec.chain_code                                                         --���̓p�����[�^.�`�F�[���X�R�[�h
                     ,i_prf_rec.cmn_rep_chain_code                                                   --���ʒ��[�l���p�`�F�[���X�R�[�h
                     ,xeh_l.xeh_deliv_slip_flag_area_cmn                                             --���ʒ��[�l���p�[�i�����s�t���O�G���A
                     ,xeh_l.xeh_deliv_slip_flag_area_chain                                           --�`�F�[���X�ŗL���[�l���p�[�i�����s�t���O�G���A
               )
             ) = i_input_rec.publish_div                                                               --���̓p�����[�^.�[�i�����s�t���O
-- == 2010/04/20 V1.16 Modified START ===============================================================
      --OPM�i�ڃ}�X�^���o����
--      AND    iimb.item_no(+) = xeh_l.xel_item_code                                                     --�i�ڃR�[�h
      AND    iimb.item_no(+) = ixe.item_code                                                           --�i�ڃR�[�h
-- == 2010/04/20 V1.16 Modified END   ===============================================================
      --OPM�i�ڃ}�X�^�A�h�I�����o����
      AND    ximb.item_id(+) = iimb.item_id                                                            --�i��ID
      AND    NVL(xeh_l.xeh_shop_delivery_date
                ,NVL(xeh_l.xeh_center_delivery_date
                    ,NVL(xeh_l.xeh_order_date
                        ,xeh_l.xeh_data_creat_date_edi_d)))
        BETWEEN NVL(ximb.start_date_active
                   ,NVL(xeh_l.xeh_shop_delivery_date
                       ,NVL(xeh_l.xeh_center_delivery_date
                           ,NVL(xeh_l.xeh_order_date
                               ,xeh_l.xeh_data_creat_date_edi_d))))
        AND     NVL(ximb.end_date_active
                    ,NVL(xeh_l.xeh_shop_delivery_date
                       ,NVL(xeh_l.xeh_center_delivery_date
                           ,NVL(xeh_l.xeh_order_date
                               ,xeh_l.xeh_data_creat_date_edi_d))))
-- == 2010/04/20 V1.16 Modified START ===============================================================
      --DISC�i�ڃ}�X�^���o����
--      AND    msib.segment1(+) = xeh_l.xel_item_code                                                    --�i�ڃR�[�h
      AND    msib.segment1(+) = ixe.item_code                                                          --�i�ڃR�[�h
-- == 2010/04/20 V1.16 Modified END   ===============================================================
      AND    msib.organization_id(+) = i_other_rec.organization_id                                     --�݌ɑg�DID
      --DISC�i�ڃA�h�I�����o����
      AND    xsib.item_code(+) = msib.segment1                                                         --INV�i��ID
-- ************ 2009/08/12 N.Maeda 1.11 DEL START ***************** --
--      --�{�Џ��i�敪�r���[���o����
--      AND    xhpc.segment1(+) = iimb.item_no                                                           --�i�ڃR�[�h
-- ************ 2009/08/12 N.Maeda 1.11 DEL  END  ***************** --
      -- ���o�Ώۏ���      
      AND    xeh_l.xeh_edi_header_info_id  = ixe.edi_header_info_id
      AND    xeh_l.xel_edi_line_info_id    = ixe.edi_line_info_id
      --
      AND xeh_l.select_block       = DECODE( i_input_rec.store_code,
                                             NULL,xeh_l.select_block,
/* 2009/09/15 Ver1.12 Mod Start */
--                                             '1')
                                             cv_select_block_1)
/* 2009/09/15 Ver1.12 Mod End   */
      ORDER BY xeh_l.xeh_shop_code, xeh_l.xeh_invoice_number, xeh_l.xel_line_no
--****************************** 2009/06/18 1.11 N.Maeda MOD  END    ******************************--
/* 2009/06/11 Ver1.10 Mod End   */
      ;
--
    -- *** ���[�J���E���R�[�h ***
    l_base_rec                 g_base_rtype;                        --�[�i���_���
    l_chain_rec                g_chain_rtype;                       --EDI�`�F�[���X���
    l_other_rec                g_other_rtype;                       --���̑����
    l_data_tab                 xxcos_common2_pkg.g_layout_ttype;    --�o�̓f�[�^���
--
--
  BEGIN
    out_line(buff => cv_prg_name || ' start');
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    lb_error := FALSE;
-- 2009/02/19 T.Nakamura Ver.1.5 add start
    lv_errbuf_all := NULL;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
--
    --���b�Z�[�W������(�ʏ��)�擾
    g_msg_rec.header_type := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_header_type);
    --���b�Z�[�W������(�ʏ�o��)�擾
    g_msg_rec.line_type := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_line_type);
    --���b�Z�[�W������(�󒍃\�[�X)�擾
    g_msg_rec.order_source := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_order_source);
    --==============================================================
    --�����S���ҏ��擾
    --==============================================================
    BEGIN
      SELECT papf.last_name || papf.first_name                                  manager_name                  --�����S����
      INTO   l_base_rec.manager_name_kana
      FROM   per_all_people_f                                                   papf                          --�]�ƈ��}�X�^
            ,per_all_assignments_f                                              paaf                          --�]�ƈ������}�X�^
      WHERE  papf.person_id = paaf.person_id
      AND    xxccp_common_pkg2.get_process_date 
        BETWEEN papf.effective_start_date
        AND     NVL(papf.effective_end_date,xxccp_common_pkg2.get_process_date)
      AND    xxccp_common_pkg2.get_process_date
        BETWEEN paaf.effective_start_date
        AND     NVL(paaf.effective_end_date,xxccp_common_pkg2.get_process_date)
      AND   paaf.ass_attribute5 = g_input_rec.base_code
      AND   papf.attribute11 = g_prf_rec.base_manager_code
      AND ROWNUM = 1
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
      WHEN OTHERS THEN
        out_line(buff => cv_prg_name || ' ' || sqlerrm);
    END;
--
/* 2009/06/11 Ver1.10 Add End   */
    --==============================================================
    --�[�i���_���擾
    --==============================================================
    BEGIN
      SELECT hp.organization_name_phonetic                   base_name_kana  -- �ڋq����(�J�i)
      INTO   l_base_rec.base_name_kana
      FROM   hz_cust_accounts                                hca             -- �ڋq�}�X�^
            ,hz_parties                                      hp              -- �p�[�e�B�}�X�^
      --�ڋq�}�X�^���o����
      WHERE  hca.account_number = g_input_rec.base_code
      AND    hca.customer_class_code = cv_cust_class_base
      --�p�[�e�B�}�X�^���o����
      AND    hp.party_id = hca.party_id
      AND    ROWNUM = 1 --�G���[����̂��߈ꎞ�I�ɕt��
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        l_base_rec.base_name_kana := NULL;
    END;
/* 2009/06/11 Ver1.10 Add End   */
--******************************************* 2009/04/02 1.8 T.Kitajima DEL START *************************************
--    --==============================================================
--    --�[�i���_���擾
--    --==============================================================
--    BEGIN
--      SELECT hp.party_name                                                       base_name                    --�ڋq����
--            ,hp.organization_name_phonetic                                       base_name_kana               --�ڋq����(�J�i)
--            ,hl.state                                                            state                        --�s���{��
--            ,hl.city                                                             city                         --�s�E��
--            ,hl.address1                                                         address1                     --�Z���P
--            ,hl.address2                                                         address2                     --�Z���Q
--            ,hl.address_lines_phonetic                                           phone_number                 --�d�b�ԍ�
--            ,xca.torihikisaki_code                                               customer_code                --�����R�[�h
--      INTO   l_base_rec.base_name
--            ,l_base_rec.base_name_kana
--            ,l_base_rec.state
--            ,l_base_rec.city
--            ,l_base_rec.address1
--            ,l_base_rec.address2
--            ,l_base_rec.phone_number
--            ,l_base_rec.customer_code
--      FROM   hz_cust_accounts                                                    hca                          --�ڋq�}�X�^
--            ,xxcmm_cust_accounts                                                 xca                          --�ڋq�}�X�^�A�h�I��
--            ,hz_parties                                                          hp                           --�p�[�e�B�}�X�^
---- 2009/02/16 T.Nakamura Ver.1.3 add start
--            ,hz_cust_acct_sites_all                                              hcas                         --�ڋq���ݒn
---- 2009/02/16 T.Nakamura Ver.1.3 add end
--            ,hz_party_sites                                                      hps                          --�p�[�e�B�T�C�g�}�X�^
--            ,hz_locations                                                        hl                           --���Ə��}�X�^
--      --�ڋq�}�X�^���o����
--      WHERE  hca.account_number = g_input_rec.base_code
--      AND    hca.customer_class_code = cv_cust_class_base
--      --�ڋq�}�X�^�A�h�I�����o����
--      AND    xca.customer_id = hca.cust_account_id
--      --�p�[�e�B�}�X�^���o����
--      AND    hp.party_id = hca.party_id
--     --�p�[�e�B�T�C�g���o����
--      AND    hps.party_id = hca.party_id
--      --�ڋq���Ə��}�X�^���o����
--      AND    hl.location_id = hps.location_id
---- 2009/02/16 T.Nakamura Ver.1.3 add start
--      AND    hcas.cust_account_id = hca.cust_account_id
--      AND    hps.party_site_id = hcas.party_site_id
--      AND    hcas.org_id = g_prf_rec.org_id
---- 2009/02/16 T.Nakamura Ver.1.3 add end
--      and rownum = 1 --�G���[����̂��߈ꎞ�I�ɕt��
--      ;
--      l_base_rec.notfound_flag := cv_found;
--    EXCEPTION
--      WHEN NO_DATA_FOUND THEN
--        l_base_rec.base_name := g_msg_rec.customer_notfound;
--        l_base_rec.notfound_flag := cv_notfound;
--    END;
--******************************************* 2009/04/02 1.8 T.Kitajima DEL  END  *************************************
--
    --==============================================================
    --EDI�`�F�[���X���擾
    --==============================================================
    BEGIN
      SELECT hp.party_name                                                      chain_name                    --�`�F�[���X����
            ,hp.organization_name_phonetic                                      chain_name_kana               --�`�F�[���X����(�J�i)
      INTO   l_chain_rec.chain_name           
            ,l_chain_rec.chain_name_kana      
      FROM   xxcmm_cust_accounts                                                xca                           --�ڋq�}�X�^�A�h�I��
            ,hz_cust_accounts                                                   hca                           --�ڋq�}�X�^
            ,hz_parties                                                         hp                            --�p�[�e�B�}�X�^
--******************************************* 2009/04/01 1.7 T.Kitajima MOD START *************************************
--      WHERE  xca.edi_chain_code = g_input_rec.chain_code
      WHERE  xca.edi_chain_code = g_input_rec.ssm_store_code
--******************************************* 2009/04/01 1.7 T.Kitajima MOD  END  *************************************
      AND    hca.cust_account_id = xca.customer_id
      AND    hca.customer_class_code = cv_cust_class_chain
      AND    hp.party_id = hca.party_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        l_chain_rec.chain_name := g_msg_rec.customer_notfound;
    END;
--
    --==============================================================
    --�O���[�o���ϐ��̐ݒ�
    --==============================================================
    g_base_rec := l_base_rec;
    g_chain_rec := l_chain_rec;
--
    --==============================================================
    --�f�[�^���R�[�h���擾
    --==============================================================
    OPEN cur_data_record(
           g_input_rec
          ,g_prf_rec
          ,g_base_rec
          ,g_chain_rec
          ,g_msg_rec
          ,g_other_rec
         );
    <<data_record_loop>>
    LOOP
      FETCH cur_data_record INTO
        lt_header_id                                                                                          --�w�b�_ID
       ,lt_bargain_class                                                                                      --��ԓ����敪
       ,lt_outbound_flag                                                                                      --OUTBOUND��
            ------------------------------------------------�w�b�_���------------------------------------------------
       ,l_data_tab('MEDIUM_CLASS')                                                                            --�}�̋敪
       ,l_data_tab('DATA_TYPE_CODE')                                                                          --�f�[�^��R�[�h
       ,l_data_tab('FILE_NO')                                                                                 --�t�@�C���m��
       ,l_data_tab('INFO_CLASS')                                                                              --���敪
       ,l_data_tab('PROCESS_DATE')                                                                            --������
       ,l_data_tab('PROCESS_TIME')                                                                            --��������
       ,l_data_tab('BASE_CODE')                                                                               --���_�i����j�R�[�h
       ,l_data_tab('BASE_NAME')                                                                               --���_���i�������j
       ,l_data_tab('BASE_NAME_ALT')                                                                           --���_���i�J�i�j
       ,l_data_tab('EDI_CHAIN_CODE')                                                                          --�d�c�h�`�F�[���X�R�[�h
       ,l_data_tab('EDI_CHAIN_NAME')                                                                          --�d�c�h�`�F�[���X���i�����j
       ,l_data_tab('EDI_CHAIN_NAME_ALT')                                                                      --�d�c�h�`�F�[���X���i�J�i�j
       ,l_data_tab('CHAIN_CODE')                                                                              --�`�F�[���X�R�[�h
       ,l_data_tab('CHAIN_NAME')                                                                              --�`�F�[���X���i�����j
       ,l_data_tab('CHAIN_NAME_ALT')                                                                          --�`�F�[���X���i�J�i�j
       ,l_data_tab('REPORT_CODE')                                                                             --���[�R�[�h
       ,l_data_tab('REPORT_SHOW_NAME')                                                                        --���[�\����
       ,l_data_tab('CUSTOMER_CODE')                                                                           --�ڋq�R�[�h
       ,l_data_tab('CUSTOMER_NAME')                                                                           --�ڋq���i�����j
       ,l_data_tab('CUSTOMER_NAME_ALT')                                                                       --�ڋq���i�J�i�j
       ,l_data_tab('COMPANY_CODE')                                                                            --�ЃR�[�h
       ,l_data_tab('COMPANY_NAME')                                                                            --�Ж��i�����j
       ,l_data_tab('COMPANY_NAME_ALT')                                                                        --�Ж��i�J�i�j
       ,l_data_tab('SHOP_CODE')                                                                               --�X�R�[�h
       ,l_data_tab('SHOP_NAME')                                                                               --�X���i�����j
       ,l_data_tab('SHOP_NAME_ALT')                                                                           --�X���i�J�i�j
       ,l_data_tab('DELIVERY_CENTER_CODE')                                                                    --�[���Z���^�[�R�[�h
       ,l_data_tab('DELIVERY_CENTER_NAME')                                                                    --�[���Z���^�[���i�����j
       ,l_data_tab('DELIVERY_CENTER_NAME_ALT')                                                                --�[���Z���^�[���i�J�i�j
       ,l_data_tab('ORDER_DATE')                                                                              --������
       ,l_data_tab('CENTER_DELIVERY_DATE')                                                                    --�Z���^�[�[�i��
       ,l_data_tab('RESULT_DELIVERY_DATE')                                                                    --���[�i��
       ,l_data_tab('SHOP_DELIVERY_DATE')                                                                      --�X�ܔ[�i��
       ,l_data_tab('DATA_CREATION_DATE_EDI_DATA')                                                             --�f�[�^�쐬���i�d�c�h�f�[�^���j
       ,l_data_tab('DATA_CREATION_TIME_EDI_DATA')                                                             --�f�[�^�쐬�����i�d�c�h�f�[�^���j
       ,l_data_tab('INVOICE_CLASS')                                                                           --�`�[�敪
       ,l_data_tab('SMALL_CLASSIFICATION_CODE')                                                               --�����ރR�[�h
       ,l_data_tab('SMALL_CLASSIFICATION_NAME')                                                               --�����ޖ�
       ,l_data_tab('MIDDLE_CLASSIFICATION_CODE')                                                              --�����ރR�[�h
       ,l_data_tab('MIDDLE_CLASSIFICATION_NAME')                                                              --�����ޖ�
       ,l_data_tab('BIG_CLASSIFICATION_CODE')                                                                 --�啪�ރR�[�h
       ,l_data_tab('BIG_CLASSIFICATION_NAME')                                                                 --�啪�ޖ�
       ,l_data_tab('OTHER_PARTY_DEPARTMENT_CODE')                                                             --����敔��R�[�h
       ,l_data_tab('OTHER_PARTY_ORDER_NUMBER')                                                                --����攭���ԍ�
       ,l_data_tab('CHECK_DIGIT_CLASS')                                                                       --�`�F�b�N�f�W�b�g�L���敪
       ,l_data_tab('INVOICE_NUMBER')                                                                          --�`�[�ԍ�
       ,l_data_tab('CHECK_DIGIT')                                                                             --�`�F�b�N�f�W�b�g
       ,l_data_tab('CLOSE_DATE')                                                                              --����
       ,l_data_tab('ORDER_NO_EBS')                                                                            --�󒍂m���i�d�a�r�j
       ,l_data_tab('AR_SALE_CLASS')                                                                           --�����敪
       ,l_data_tab('DELIVERY_CLASSE')                                                                         --�z���敪
       ,l_data_tab('OPPORTUNITY_NO')                                                                          --�ւm��
       ,l_data_tab('CONTACT_TO')                                                                              --�A����
       ,l_data_tab('ROUTE_SALES')                                                                             --���[�g�Z�[���X
       ,l_data_tab('CORPORATE_CODE')                                                                          --�@�l�R�[�h
       ,l_data_tab('MAKER_NAME')                                                                              --���[�J�[��
       ,l_data_tab('AREA_CODE')                                                                               --�n��R�[�h
       ,l_data_tab('AREA_NAME')                                                                               --�n�於�i�����j
       ,l_data_tab('AREA_NAME_ALT')                                                                           --�n�於�i�J�i�j
       ,l_data_tab('VENDOR_CODE')                                                                             --�����R�[�h
       ,l_data_tab('VENDOR_NAME')                                                                             --����於�i�����j
       ,l_data_tab('VENDOR_NAME1_ALT')                                                                        --����於�P�i�J�i�j
       ,l_data_tab('VENDOR_NAME2_ALT')                                                                        --����於�Q�i�J�i�j
       ,l_data_tab('VENDOR_TEL')                                                                              --�����s�d�k
       ,l_data_tab('VENDOR_CHARGE')                                                                           --�����S����
       ,l_data_tab('VENDOR_ADDRESS')                                                                          --�����Z���i�����j
       ,l_data_tab('DELIVER_TO_CODE_ITOUEN')                                                                  --�͂���R�[�h�i�ɓ����j
       ,l_data_tab('DELIVER_TO_CODE_CHAIN')                                                                   --�͂���R�[�h�i�`�F�[���X�j
       ,l_data_tab('DELIVER_TO')                                                                              --�͂���i�����j
       ,l_data_tab('DELIVER_TO1_ALT')                                                                         --�͂���P�i�J�i�j
       ,l_data_tab('DELIVER_TO2_ALT')                                                                         --�͂���Q�i�J�i�j
       ,l_data_tab('DELIVER_TO_ADDRESS')                                                                      --�͂���Z���i�����j
       ,l_data_tab('DELIVER_TO_ADDRESS_ALT')                                                                  --�͂���Z���i�J�i�j
       ,l_data_tab('DELIVER_TO_TEL')                                                                          --�͂���s�d�k
       ,l_data_tab('BALANCE_ACCOUNTS_CODE')                                                                   --������R�[�h
       ,l_data_tab('BALANCE_ACCOUNTS_COMPANY_CODE')                                                           --������ЃR�[�h
       ,l_data_tab('BALANCE_ACCOUNTS_SHOP_CODE')                                                              --������X�R�[�h
       ,l_data_tab('BALANCE_ACCOUNTS_NAME')                                                                   --�����於�i�����j
       ,l_data_tab('BALANCE_ACCOUNTS_NAME_ALT')                                                               --�����於�i�J�i�j
       ,l_data_tab('BALANCE_ACCOUNTS_ADDRESS')                                                                --������Z���i�����j
       ,l_data_tab('BALANCE_ACCOUNTS_ADDRESS_ALT')                                                            --������Z���i�J�i�j
       ,l_data_tab('BALANCE_ACCOUNTS_TEL')                                                                    --������s�d�k
       ,l_data_tab('ORDER_POSSIBLE_DATE')                                                                     --�󒍉\��
       ,l_data_tab('PERMISSION_POSSIBLE_DATE')                                                                --���e�\��
       ,l_data_tab('FORWARD_MONTH')                                                                           --����N����
       ,l_data_tab('PAYMENT_SETTLEMENT_DATE')                                                                 --�x�����ϓ�
       ,l_data_tab('HANDBILL_START_DATE_ACTIVE')                                                              --�`���V�J�n��
       ,l_data_tab('BILLING_DUE_DATE')                                                                        --��������
       ,l_data_tab('SHIPPING_TIME')                                                                           --�o�׎���
       ,l_data_tab('DELIVERY_SCHEDULE_TIME')                                                                  --�[�i�\�莞��
       ,l_data_tab('ORDER_TIME')                                                                              --��������
       ,l_data_tab('GENERAL_DATE_ITEM1')                                                                      --�ėp���t���ڂP
       ,l_data_tab('GENERAL_DATE_ITEM2')                                                                      --�ėp���t���ڂQ
       ,l_data_tab('GENERAL_DATE_ITEM3')                                                                      --�ėp���t���ڂR
       ,l_data_tab('GENERAL_DATE_ITEM4')                                                                      --�ėp���t���ڂS
       ,l_data_tab('GENERAL_DATE_ITEM5')                                                                      --�ėp���t���ڂT
       ,l_data_tab('ARRIVAL_SHIPPING_CLASS')                                                                  --���o�׋敪
       ,l_data_tab('VENDOR_CLASS')                                                                            --�����敪
       ,l_data_tab('INVOICE_DETAILED_CLASS')                                                                  --�`�[����敪
       ,l_data_tab('UNIT_PRICE_USE_CLASS')                                                                    --�P���g�p�敪
       ,l_data_tab('SUB_DISTRIBUTION_CENTER_CODE')                                                            --�T�u�����Z���^�[�R�[�h
       ,l_data_tab('SUB_DISTRIBUTION_CENTER_NAME')                                                            --�T�u�����Z���^�[�R�[�h��
       ,l_data_tab('CENTER_DELIVERY_METHOD')                                                                  --�Z���^�[�[�i���@
       ,l_data_tab('CENTER_USE_CLASS')                                                                        --�Z���^�[���p�敪
       ,l_data_tab('CENTER_WHSE_CLASS')                                                                       --�Z���^�[�q�ɋ敪
       ,l_data_tab('CENTER_AREA_CLASS')                                                                       --�Z���^�[�n��敪
       ,l_data_tab('CENTER_ARRIVAL_CLASS')                                                                    --�Z���^�[���׋敪
       ,l_data_tab('DEPOT_CLASS')                                                                             --�f�|�敪
       ,l_data_tab('TCDC_CLASS')                                                                              --�s�b�c�b�敪
       ,l_data_tab('UPC_FLAG')                                                                                --�t�o�b�t���O
       ,l_data_tab('SIMULTANEOUSLY_CLASS')                                                                    --��ċ敪
       ,l_data_tab('BUSINESS_ID')                                                                             --�Ɩ��h�c
       ,l_data_tab('WHSE_DIRECTLY_CLASS')                                                                     --�q���敪
       ,l_data_tab('PREMIUM_REBATE_CLASS')                                                                    --���ڎ��
       ,l_data_tab('ITEM_TYPE')                                                                               --�i�i���ߋ敪
       ,l_data_tab('CLOTH_HOUSE_FOOD_CLASS')                                                                  --�߉ƐH�敪
       ,l_data_tab('MIX_CLASS')                                                                               --���݋敪
       ,l_data_tab('STK_CLASS')                                                                               --�݌ɋ敪
       ,l_data_tab('LAST_MODIFY_SITE_CLASS')                                                                  --�ŏI�C���ꏊ�敪
       ,l_data_tab('REPORT_CLASS')                                                                            --���[�敪
       ,l_data_tab('ADDITION_PLAN_CLASS')                                                                     --�ǉ��E�v��敪
       ,l_data_tab('REGISTRATION_CLASS')                                                                      --�o�^�敪
       ,l_data_tab('SPECIFIC_CLASS')                                                                          --����敪
       ,l_data_tab('DEALINGS_CLASS')                                                                          --����敪
       ,l_data_tab('ORDER_CLASS')                                                                             --�����敪
       ,l_data_tab('SUM_LINE_CLASS')                                                                          --�W�v���׋敪
       ,l_data_tab('SHIPPING_GUIDANCE_CLASS')                                                                 --�o�׈ē��ȊO�敪
       ,l_data_tab('SHIPPING_CLASS')                                                                          --�o�׋敪
       ,l_data_tab('PRODUCT_CODE_USE_CLASS')                                                                  --���i�R�[�h�g�p�敪
       ,l_data_tab('CARGO_ITEM_CLASS')                                                                        --�ϑ��i�敪
       ,l_data_tab('TA_CLASS')                                                                                --�s�^�`�敪
       ,l_data_tab('PLAN_CODE')                                                                               --���R�[�h
       ,l_data_tab('CATEGORY_CODE')                                                                           --�J�e�S���[�R�[�h
       ,l_data_tab('CATEGORY_CLASS')                                                                          --�J�e�S���[�敪
       ,l_data_tab('CARRIER_MEANS')                                                                           --�^����i
       ,l_data_tab('COUNTER_CODE')                                                                            --����R�[�h
       ,l_data_tab('MOVE_SIGN')                                                                               --�ړ��T�C��
       ,l_data_tab('EOS_HANDWRITING_CLASS')                                                                   --�d�n�r�E�菑�敪
       ,l_data_tab('DELIVERY_TO_SECTION_CODE')                                                                --�[�i��ۃR�[�h
       ,l_data_tab('INVOICE_DETAILED')                                                                        --�`�[����
       ,l_data_tab('ATTACH_QTY')                                                                              --�Y�t��
       ,l_data_tab('OTHER_PARTY_FLOOR')                                                                       --�t���A
       ,l_data_tab('TEXT_NO')                                                                                 --�s�d�w�s�m��
       ,l_data_tab('IN_STORE_CODE')                                                                           --�C���X�g�A�R�[�h
       ,l_data_tab('TAG_DATA')                                                                                --�^�O
       ,l_data_tab('COMPETITION_CODE')                                                                        --����
       ,l_data_tab('BILLING_CHAIR')                                                                           --��������
       ,l_data_tab('CHAIN_STORE_CODE')                                                                        --�`�F�[���X�g�A�[�R�[�h
       ,l_data_tab('CHAIN_STORE_SHORT_NAME')                                                                  --�`�F�[���X�g�A�[�R�[�h��������
       ,l_data_tab('DIRECT_DELIVERY_RCPT_FEE')                                                                --���z���^���旿
       ,l_data_tab('BILL_INFO')                                                                               --��`���
       ,l_data_tab('DESCRIPTION')                                                                             --�E�v
       ,l_data_tab('INTERIOR_CODE')                                                                           --�����R�[�h
       ,l_data_tab('ORDER_INFO_DELIVERY_CATEGORY')                                                            --�������@�[�i�J�e�S���[
       ,l_data_tab('PURCHASE_TYPE')                                                                           --�d���`��
       ,l_data_tab('DELIVERY_TO_NAME_ALT')                                                                    --�[�i�ꏊ���i�J�i�j
       ,l_data_tab('SHOP_OPENED_SITE')                                                                        --�X�o�ꏊ
       ,l_data_tab('COUNTER_NAME')                                                                            --���ꖼ
       ,l_data_tab('EXTENSION_NUMBER')                                                                        --�����ԍ�
       ,l_data_tab('CHARGE_NAME')                                                                             --�S���Җ�
       ,l_data_tab('PRICE_TAG')                                                                               --�l�D
       ,l_data_tab('TAX_TYPE')                                                                                --�Ŏ�
       ,l_data_tab('CONSUMPTION_TAX_CLASS')                                                                   --����ŋ敪
       ,l_data_tab('BRAND_CLASS')                                                                             --�a�q
       ,l_data_tab('ID_CODE')                                                                                 --�h�c�R�[�h
       ,l_data_tab('DEPARTMENT_CODE')                                                                         --�S�ݓX�R�[�h
       ,l_data_tab('DEPARTMENT_NAME')                                                                         --�S�ݓX��
       ,l_data_tab('ITEM_TYPE_NUMBER')                                                                        --�i�ʔԍ�
       ,l_data_tab('DESCRIPTION_DEPARTMENT')                                                                  --�E�v�i�S�ݓX�j
       ,l_data_tab('PRICE_TAG_METHOD')                                                                        --�l�D���@
       ,l_data_tab('REASON_COLUMN')                                                                           --���R��
       ,l_data_tab('A_COLUMN_HEADER')                                                                         --�`���w�b�_
       ,l_data_tab('D_COLUMN_HEADER')                                                                         --�c���w�b�_
       ,l_data_tab('BRAND_CODE')                                                                              --�u�����h�R�[�h
       ,l_data_tab('LINE_CODE')                                                                               --���C���R�[�h
       ,l_data_tab('CLASS_CODE')                                                                              --�N���X�R�[�h
       ,l_data_tab('A1_COLUMN')                                                                               --�`�|�P��
       ,l_data_tab('B1_COLUMN')                                                                               --�a�|�P��
       ,l_data_tab('C1_COLUMN')                                                                               --�b�|�P��
       ,l_data_tab('D1_COLUMN')                                                                               --�c�|�P��
       ,l_data_tab('E1_COLUMN')                                                                               --�d�|�P��
       ,l_data_tab('A2_COLUMN')                                                                               --�`�|�Q��
       ,l_data_tab('B2_COLUMN')                                                                               --�a�|�Q��
       ,l_data_tab('C2_COLUMN')                                                                               --�b�|�Q��
       ,l_data_tab('D2_COLUMN')                                                                               --�c�|�Q��
       ,l_data_tab('E2_COLUMN')                                                                               --�d�|�Q��
       ,l_data_tab('A3_COLUMN')                                                                               --�`�|�R��
       ,l_data_tab('B3_COLUMN')                                                                               --�a�|�R��
       ,l_data_tab('C3_COLUMN')                                                                               --�b�|�R��
       ,l_data_tab('D3_COLUMN')                                                                               --�c�|�R��
       ,l_data_tab('E3_COLUMN')                                                                               --�d�|�R��
       ,l_data_tab('F1_COLUMN')                                                                               --�e�|�P��
       ,l_data_tab('G1_COLUMN')                                                                               --�f�|�P��
       ,l_data_tab('H1_COLUMN')                                                                               --�g�|�P��
       ,l_data_tab('I1_COLUMN')                                                                               --�h�|�P��
       ,l_data_tab('J1_COLUMN')                                                                               --�i�|�P��
       ,l_data_tab('K1_COLUMN')                                                                               --�j�|�P��
       ,l_data_tab('L1_COLUMN')                                                                               --�k�|�P��
       ,l_data_tab('F2_COLUMN')                                                                               --�e�|�Q��
       ,l_data_tab('G2_COLUMN')                                                                               --�f�|�Q��
       ,l_data_tab('H2_COLUMN')                                                                               --�g�|�Q��
       ,l_data_tab('I2_COLUMN')                                                                               --�h�|�Q��
       ,l_data_tab('J2_COLUMN')                                                                               --�i�|�Q��
       ,l_data_tab('K2_COLUMN')                                                                               --�j�|�Q��
       ,l_data_tab('L2_COLUMN')                                                                               --�k�|�Q��
       ,l_data_tab('F3_COLUMN')                                                                               --�e�|�R��
       ,l_data_tab('G3_COLUMN')                                                                               --�f�|�R��
       ,l_data_tab('H3_COLUMN')                                                                               --�g�|�R��
       ,l_data_tab('I3_COLUMN')                                                                               --�h�|�R��
       ,l_data_tab('J3_COLUMN')                                                                               --�i�|�R��
       ,l_data_tab('K3_COLUMN')                                                                               --�j�|�R��
       ,l_data_tab('L3_COLUMN')                                                                               --�k�|�R��
       ,l_data_tab('CHAIN_PECULIAR_AREA_HEADER')                                                              --�`�F�[���X�ŗL�G���A�i�w�b�_�[�j
       ,l_data_tab('ORDER_CONNECTION_NUMBER')                                                                 --�󒍊֘A�ԍ��i���j
-- 2011/10/06 A.Shirakawa Ver.1.19 ADD START
       ,l_data_tab('BMS_HEADER_DATA')                                                                         --���ʂa�l�r�w�b�_�f�[�^
-- 2011/10/06 A.Shirakawa Ver.1.19 ADD END
            ------------------------------------------------���׏��------------------------------------------------
       ,l_data_tab('LINE_NO')                                                                                 --�s�m��
       ,l_data_tab('STOCKOUT_CLASS')                                                                          --���i�敪
       ,l_data_tab('STOCKOUT_REASON')                                                                         --���i���R
       ,l_data_tab('PRODUCT_CODE_ITOUEN')                                                                     --���i�R�[�h�i�ɓ����j
       ,l_data_tab('PRODUCT_CODE1')                                                                           --���i�R�[�h�P
       ,l_data_tab('PRODUCT_CODE2')                                                                           --���i�R�[�h�Q
       ,l_data_tab('JAN_CODE')                                                                                --�i�`�m�R�[�h
       ,l_data_tab('ITF_CODE')                                                                                --�h�s�e�R�[�h
       ,l_data_tab('EXTENSION_ITF_CODE')                                                                      --�����h�s�e�R�[�h
       ,l_data_tab('CASE_PRODUCT_CODE')                                                                       --�P�[�X���i�R�[�h
       ,l_data_tab('BALL_PRODUCT_CODE')                                                                       --�{�[�����i�R�[�h
       ,l_data_tab('PRODUCT_CODE_ITEM_TYPE')                                                                  --���i�R�[�h�i��
       ,l_data_tab('PROD_CLASS')                                                                              --���i�敪
       ,l_data_tab('PRODUCT_NAME')                                                                            --���i���i�����j
       ,l_data_tab('PRODUCT_NAME1_ALT')                                                                       --���i���P�i�J�i�j
       ,l_data_tab('PRODUCT_NAME2_ALT')                                                                       --���i���Q�i�J�i�j
       ,l_data_tab('ITEM_STANDARD1')                                                                          --�K�i�P
       ,l_data_tab('ITEM_STANDARD2')                                                                          --�K�i�Q
       ,l_data_tab('QTY_IN_CASE')                                                                             --����
       ,l_data_tab('NUM_OF_CASES')                                                                            --�P�[�X����
       ,l_data_tab('NUM_OF_BALL')                                                                           --�{�[������
       ,l_data_tab('ITEM_COLOR')                                                                              --�F
       ,l_data_tab('ITEM_SIZE')                                                                               --�T�C�Y
       ,l_data_tab('EXPIRATION_DATE')                                                                         --�ܖ�������
       ,l_data_tab('PRODUCT_DATE')                                                                            --������
       ,l_data_tab('ORDER_UOM_QTY')                                                                           --�����P�ʐ�
       ,l_data_tab('SHIPPING_UOM_QTY')                                                                        --�o�גP�ʐ�
       ,l_data_tab('PACKING_UOM_QTY')                                                                         --����P�ʐ�
       ,l_data_tab('DEAL_CODE')                                                                               --����
       ,l_data_tab('DEAL_CLASS')                                                                              --�����敪
       ,l_data_tab('COLLATION_CODE')                                                                          --�ƍ�
       ,l_data_tab('UOM_CODE')                                                                                --�P��
       ,l_data_tab('UNIT_PRICE_CLASS')                                                                        --�P���敪
       ,l_data_tab('PARENT_PACKING_NUMBER')                                                                   --�e����ԍ�
       ,l_data_tab('PACKING_NUMBER')                                                                          --����ԍ�
       ,l_data_tab('PRODUCT_GROUP_CODE')                                                                      --���i�Q�R�[�h
       ,l_data_tab('CASE_DISMANTLE_FLAG')                                                                     --�P�[�X��̕s�t���O
       ,l_data_tab('CASE_CLASS')                                                                              --�P�[�X�敪
       ,l_data_tab('INDV_ORDER_QTY')                                                                          --�������ʁi�o���j
       ,l_data_tab('CASE_ORDER_QTY')                                                                          --�������ʁi�P�[�X�j
       ,l_data_tab('BALL_ORDER_QTY')                                                                          --�������ʁi�{�[���j
       ,l_data_tab('SUM_ORDER_QTY')                                                                           --�������ʁi���v�A�o���j
       ,l_data_tab('INDV_SHIPPING_QTY')                                                                       --�o�א��ʁi�o���j
       ,l_data_tab('CASE_SHIPPING_QTY')                                                                       --�o�א��ʁi�P�[�X�j
       ,l_data_tab('BALL_SHIPPING_QTY')                                                                       --�o�א��ʁi�{�[���j
       ,l_data_tab('PALLET_SHIPPING_QTY')                                                                     --�o�א��ʁi�p���b�g�j
       ,l_data_tab('SUM_SHIPPING_QTY')                                                                        --�o�א��ʁi���v�A�o���j
       ,l_data_tab('INDV_STOCKOUT_QTY')                                                                       --���i���ʁi�o���j
       ,l_data_tab('CASE_STOCKOUT_QTY')                                                                       --���i���ʁi�P�[�X�j
       ,l_data_tab('BALL_STOCKOUT_QTY')                                                                       --���i���ʁi�{�[���j
       ,l_data_tab('SUM_STOCKOUT_QTY')                                                                        --���i���ʁi���v�A�o���j
       ,l_data_tab('CASE_QTY')                                                                                --�P�[�X����
       ,l_data_tab('FOLD_CONTAINER_INDV_QTY')                                                                 --�I���R���i�o���j����
       ,l_data_tab('ORDER_UNIT_PRICE')                                                                        --���P���i�����j
       ,l_data_tab('SHIPPING_UNIT_PRICE')                                                                     --���P���i�o�ׁj
       ,l_data_tab('ORDER_COST_AMT')                                                                          --�������z�i�����j
       ,l_data_tab('SHIPPING_COST_AMT')                                                                       --�������z�i�o�ׁj
       ,l_data_tab('STOCKOUT_COST_AMT')                                                                       --�������z�i���i�j
       ,l_data_tab('SELLING_PRICE')                                                                           --���P��
       ,l_data_tab('ORDER_PRICE_AMT')                                                                         --�������z�i�����j
       ,l_data_tab('SHIPPING_PRICE_AMT')                                                                      --�������z�i�o�ׁj
       ,l_data_tab('STOCKOUT_PRICE_AMT')                                                                      --�������z�i���i�j
       ,l_data_tab('A_COLUMN_DEPARTMENT')                                                                     --�`���i�S�ݓX�j
       ,l_data_tab('D_COLUMN_DEPARTMENT')                                                                     --�c���i�S�ݓX�j
       ,l_data_tab('STANDARD_INFO_DEPTH')                                                                     --�K�i���E���s��
       ,l_data_tab('STANDARD_INFO_HEIGHT')                                                                    --�K�i���E����
       ,l_data_tab('STANDARD_INFO_WIDTH')                                                                     --�K�i���E��
       ,l_data_tab('STANDARD_INFO_WEIGHT')                                                                    --�K�i���E�d��
       ,l_data_tab('GENERAL_SUCCEEDED_ITEM1')                                                                 --�ėp���p�����ڂP
       ,l_data_tab('GENERAL_SUCCEEDED_ITEM2')                                                                 --�ėp���p�����ڂQ
       ,l_data_tab('GENERAL_SUCCEEDED_ITEM3')                                                                 --�ėp���p�����ڂR
       ,l_data_tab('GENERAL_SUCCEEDED_ITEM4')                                                                 --�ėp���p�����ڂS
       ,l_data_tab('GENERAL_SUCCEEDED_ITEM5')                                                                 --�ėp���p�����ڂT
       ,l_data_tab('GENERAL_SUCCEEDED_ITEM6')                                                                 --�ėp���p�����ڂU
       ,l_data_tab('GENERAL_SUCCEEDED_ITEM7')                                                                 --�ėp���p�����ڂV
       ,l_data_tab('GENERAL_SUCCEEDED_ITEM8')                                                                 --�ėp���p�����ڂW
       ,l_data_tab('GENERAL_SUCCEEDED_ITEM9')                                                                 --�ėp���p�����ڂX
       ,l_data_tab('GENERAL_SUCCEEDED_ITEM10')                                                                --�ėp���p�����ڂP�O
       ,l_data_tab('GENERAL_ADD_ITEM1')                                                                       --�ėp�t�����ڂP
       ,l_data_tab('GENERAL_ADD_ITEM2')                                                                       --�ėp�t�����ڂQ
       ,l_data_tab('GENERAL_ADD_ITEM3')                                                                       --�ėp�t�����ڂR
       ,l_data_tab('GENERAL_ADD_ITEM4')                                                                       --�ėp�t�����ڂS
       ,l_data_tab('GENERAL_ADD_ITEM5')                                                                       --�ėp�t�����ڂT
       ,l_data_tab('GENERAL_ADD_ITEM6')                                                                       --�ėp�t�����ڂU
       ,l_data_tab('GENERAL_ADD_ITEM7')                                                                       --�ėp�t�����ڂV
       ,l_data_tab('GENERAL_ADD_ITEM8')                                                                       --�ėp�t�����ڂW
       ,l_data_tab('GENERAL_ADD_ITEM9')                                                                       --�ėp�t�����ڂX
       ,l_data_tab('GENERAL_ADD_ITEM10')                                                                      --�ėp�t�����ڂP�O
       ,l_data_tab('CHAIN_PECULIAR_AREA_LINE')                                                                --�`�F�[���X�ŗL�G���A�i���ׁj
-- 2011/10/06 A.Shirakawa Ver.1.19 ADD START
       ,l_data_tab('BMS_LINE_DATA')                                                                           --���ʂa�l�r���׃f�[�^
-- 2011/10/06 A.Shirakawa Ver.1.19 ADD END
            ------------------------------------------------�t�b�^���------------------------------------------------
       ,l_data_tab('INVOICE_INDV_ORDER_QTY')                                                                  --�i�`�[�v�j�������ʁi�o���j
       ,l_data_tab('INVOICE_CASE_ORDER_QTY')                                                                  --�i�`�[�v�j�������ʁi�P�[�X�j
       ,l_data_tab('INVOICE_BALL_ORDER_QTY')                                                                  --�i�`�[�v�j�������ʁi�{�[���j
       ,l_data_tab('INVOICE_SUM_ORDER_QTY')                                                                   --�i�`�[�v�j�������ʁi���v�A�o���j
       ,l_data_tab('INVOICE_INDV_SHIPPING_QTY')                                                               --�i�`�[�v�j�o�א��ʁi�o���j
       ,l_data_tab('INVOICE_CASE_SHIPPING_QTY')                                                               --�i�`�[�v�j�o�א��ʁi�P�[�X�j
       ,l_data_tab('INVOICE_BALL_SHIPPING_QTY')                                                               --�i�`�[�v�j�o�א��ʁi�{�[���j
       ,l_data_tab('INVOICE_PALLET_SHIPPING_QTY')                                                             --�i�`�[�v�j�o�א��ʁi�p���b�g�j
       ,l_data_tab('INVOICE_SUM_SHIPPING_QTY')                                                                --�i�`�[�v�j�o�א��ʁi���v�A�o���j
       ,l_data_tab('INVOICE_INDV_STOCKOUT_QTY')                                                               --�i�`�[�v�j���i���ʁi�o���j
       ,l_data_tab('INVOICE_CASE_STOCKOUT_QTY')                                                               --�i�`�[�v�j���i���ʁi�P�[�X�j
       ,l_data_tab('INVOICE_BALL_STOCKOUT_QTY')                                                               --�i�`�[�v�j���i���ʁi�{�[���j
       ,l_data_tab('INVOICE_SUM_STOCKOUT_QTY')                                                                --�i�`�[�v�j���i���ʁi���v�A�o���j
       ,l_data_tab('INVOICE_CASE_QTY')                                                                        --�i�`�[�v�j�P�[�X����
       ,l_data_tab('INVOICE_FOLD_CONTAINER_QTY')                                                              --�i�`�[�v�j�I���R���i�o���j����
       ,l_data_tab('INVOICE_ORDER_COST_AMT')                                                                  --�i�`�[�v�j�������z�i�����j
       ,l_data_tab('INVOICE_SHIPPING_COST_AMT')                                                               --�i�`�[�v�j�������z�i�o�ׁj
       ,l_data_tab('INVOICE_STOCKOUT_COST_AMT')                                                               --�i�`�[�v�j�������z�i���i�j
       ,l_data_tab('INVOICE_ORDER_PRICE_AMT')                                                                 --�i�`�[�v�j�������z�i�����j
       ,l_data_tab('INVOICE_SHIPPING_PRICE_AMT')                                                              --�i�`�[�v�j�������z�i�o�ׁj
       ,l_data_tab('INVOICE_STOCKOUT_PRICE_AMT')                                                              --�i�`�[�v�j�������z�i���i�j
       ,l_data_tab('TOTAL_INDV_ORDER_QTY')                                                                    --�i�����v�j�������ʁi�o���j
       ,l_data_tab('TOTAL_CASE_ORDER_QTY')                                                                    --�i�����v�j�������ʁi�P�[�X�j
       ,l_data_tab('TOTAL_BALL_ORDER_QTY')                                                                    --�i�����v�j�������ʁi�{�[���j
       ,l_data_tab('TOTAL_SUM_ORDER_QTY')                                                                     --�i�����v�j�������ʁi���v�A�o���j
       ,l_data_tab('TOTAL_INDV_SHIPPING_QTY')                                                                 --�i�����v�j�o�א��ʁi�o���j
       ,l_data_tab('TOTAL_CASE_SHIPPING_QTY')                                                                 --�i�����v�j�o�א��ʁi�P�[�X�j
       ,l_data_tab('TOTAL_BALL_SHIPPING_QTY')                                                                 --�i�����v�j�o�א��ʁi�{�[���j
       ,l_data_tab('TOTAL_PALLET_SHIPPING_QTY')                                                               --�i�����v�j�o�א��ʁi�p���b�g�j
       ,l_data_tab('TOTAL_SUM_SHIPPING_QTY')                                                                  --�i�����v�j�o�א��ʁi���v�A�o���j
       ,l_data_tab('TOTAL_INDV_STOCKOUT_QTY')                                                                 --�i�����v�j���i���ʁi�o���j
       ,l_data_tab('TOTAL_CASE_STOCKOUT_QTY')                                                                 --�i�����v�j���i���ʁi�P�[�X�j
       ,l_data_tab('TOTAL_BALL_STOCKOUT_QTY')                                                                 --�i�����v�j���i���ʁi�{�[���j
       ,l_data_tab('TOTAL_SUM_STOCKOUT_QTY')                                                                  --�i�����v�j���i���ʁi���v�A�o���j
       ,l_data_tab('TOTAL_CASE_QTY')                                                                          --�i�����v�j�P�[�X����
       ,l_data_tab('TOTAL_FOLD_CONTAINER_QTY')                                                                --�i�����v�j�I���R���i�o���j����
       ,l_data_tab('TOTAL_ORDER_COST_AMT')                                                                    --�i�����v�j�������z�i�����j
       ,l_data_tab('TOTAL_SHIPPING_COST_AMT')                                                                 --�i�����v�j�������z�i�o�ׁj
       ,l_data_tab('TOTAL_STOCKOUT_COST_AMT')                                                                 --�i�����v�j�������z�i���i�j
       ,l_data_tab('TOTAL_ORDER_PRICE_AMT')                                                                   --�i�����v�j�������z�i�����j
       ,l_data_tab('TOTAL_SHIPPING_PRICE_AMT')                                                                --�i�����v�j�������z�i�o�ׁj
       ,l_data_tab('TOTAL_STOCKOUT_PRICE_AMT')                                                                --�i�����v�j�������z�i���i�j
       ,l_data_tab('TOTAL_LINE_QTY')                                                                          --�g�[�^���s��
       ,l_data_tab('TOTAL_INVOICE_QTY')                                                                       --�g�[�^���`�[����
       ,l_data_tab('CHAIN_PECULIAR_AREA_FOOTER')                                                              --�`�F�[���X�ŗL�G���A�i�t�b�^�[�j
-- 2019/06/25 V1.22 N.Miyamoto ADD START
       ,lt_conv_customer_code                                                                                 --�ϊ���ڋq�R�[�h
-- 2019/06/25 V1.22 N.Miyamoto ADD END
      ;
      EXIT WHEN cur_data_record%NOTFOUND;
-- 2019/06/25 V1.22 N.Miyamoto ADD START
      --����Ŋz���Z�o����
      --�ŗ��ɒl�������Ă���(�ϊ���ڋq�ɒl������)�ꍇ�ɏ���Ŋz���v�Z���A�ėp�t�����ڂP�O�ɃZ�b�g����B
      IF ( l_data_tab('GENERAL_ADD_ITEM1') IS NOT NULL ) THEN
        ln_order_cost_amt     := TO_NUMBER(l_data_tab('ORDER_COST_AMT'));           --�������z(����)
        ln_tax_rate           := TO_NUMBER(l_data_tab('GENERAL_ADD_ITEM1')) / 100;  --����ŗ�
--
        IF ( NVL(ln_order_cost_amt, 0) = 0 ) THEN      -- �������z(����)��NULL�A�܂���0�̏ꍇ
          ln_general_add_item10 := ln_order_cost_amt;  -- NULL�܂���0��ݒ肷��
        ELSE
          -- �ڋq�}�X�^�̏���ŋ敪������(�P������)�̏ꍇ
          IF ( l_data_tab('CONSUMPTION_TAX_CLASS') = cv_ins_bid_tax ) THEN
            --�Ŋz�̓��o
            ln_general_add_item10 := ln_order_cost_amt - ln_order_cost_amt / ( 1 + ln_tax_rate );
          -- ����ŋ敪������(�P������)�ȊO�̏ꍇ
          ELSE
            --�Ŋz�̓��o
            ln_general_add_item10 := ln_order_cost_amt * ln_tax_rate;
          END IF;
        END IF;
        --�[�����o��������
        IF ( ln_general_add_item10  <>  TRUNC(ln_general_add_item10) ) THEN
          -- �ŋ��|�[�������擾
          BEGIN
            SELECT  xchv.bill_tax_round_rule    bill_tax_round_rule             -- �ŋ��|�[������
              INTO  lt_bill_tax_round_rule
              FROM  xxcos_cust_hierarchy_v      xchv                            -- �ڋq�K�w�r���[
             WHERE  xchv.ship_account_number  =  lt_conv_customer_code          -- �ڋq�K�w�r���[.�o�א�ڋq�R�[�h���J�[�\���Ŏ擾�����ϊ���ڋq�R�[�h
            ;
          EXCEPTION
            --�[�������̎擾�Ɏ��s�����ꍇ�͐Ōv�Z�����Ȃ�
            WHEN NO_DATA_FOUND THEN
              ln_general_add_item10 := NULL;
            WHEN OTHERS THEN
              RAISE global_api_expt;
          END;
          --������ڋq�̒[�������Ɋ�Â��Ē[�������v�Z���s�Ȃ�
          IF ( lt_bill_tax_round_rule  =  cv_tkn_down ) THEN        -- �؎̂�
               --���I�_�ȉ��̏���(�؎̂�)
               ln_general_add_item10   := TRUNC(ln_general_add_item10);
          ELSIF ( lt_bill_tax_round_rule  =  cv_tkn_up ) THEN       -- �؏グ
            --�����_�ȉ��̏���(�؏グ)
            IF ( SIGN( ln_general_add_item10 )  <>  -1 )  THEN
              ln_general_add_item10 := TRUNC( ln_general_add_item10 ) + 1;
            ELSE
              ln_general_add_item10 := TRUNC( ln_general_add_item10 ) - 1;
            END IF;
          ELSIF ( lt_bill_tax_round_rule = cv_tkn_nearest ) THEN    -- �l�̌ܓ�
            ln_general_add_item10 := ROUND( ln_general_add_item10 );
          END IF;
        END IF;
        --�v�Z���ʂ𕶎��^��CAST���ăe�[�u���ϐ��ɃZ�b�g
        l_data_tab('GENERAL_ADD_ITEM10') := TO_CHAR(ln_general_add_item10);
      END IF;
-- 2019/06/25 V1.22 N.Miyamoto ADD END
--
--****************************** 2009/06/18 1.11 N.Maeda MOD START   ******************************--
      --===========================
      --�Ώۃf�[�^���b�N�擾
      --===========================
      SELECT  'Y'
      INTO    lv_data
      FROM    xxcos_edi_headers xeh
      WHERE   xeh.edi_header_info_id = lt_header_id
      FOR UPDATE OF xeh.edi_header_info_id NOWAIT;
--****************************** 2009/06/18 1.11 N.Maeda MOD  END    ******************************--
      --==============================================================
      --����敪���݃`�F�b�N
      --==============================================================
/* 2009/06/11 Ver1.10 Mod Start */
--      IF (lt_last_invoice_number = l_data_tab('INVOICE_NUMBER')) AND cur_data_record%ROWCOUNT > 1 THEN
      IF ( lt_last_header_id = lt_header_id ) AND cur_data_record%ROWCOUNT > 1 THEN
/* 2009/06/11 Ver1.10 Mod End   */
        --�O��`�[�ԍ�������`�[�ԍ��ŁA����`�[���ō��݃`�F�b�N�G���[�������Ȃ��ꍇ
        IF (lt_last_bargain_class != lt_bargain_class AND lb_mix_error_order = FALSE) THEN
          --�O���ԓ����敪�������ԓ����敪�̏ꍇ
          lb_error := TRUE;
          lb_mix_error_order := TRUE;
          lv_errmsg := xxccp_common_pkg.get_msg(
                         cv_apl_name
                        ,ct_msg_sale_class_mixed
/* 2009/06/11 Ver1.10 Add Start */
                        ,cv_tkn_chain_code
                        ,l_data_tab('CHAIN_CODE')
                        ,cv_tkn_store_code
                        ,l_data_tab('SHOP_CODE')
/* 2009/06/11 Ver1.10 Add End   */
                        ,cv_tkn_order_no
                        ,l_data_tab('INVOICE_NUMBER')
                       );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
-- 2009/02/19 T.Nakamura Ver.1.5 add start
          lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
        END IF;
      ELSE
/* 2009/06/11 Ver1.10 Mod Start */
--        --�O��`�[�ԍ�������`�[�ԍ��̏ꍇ
--        lt_last_invoice_number := l_data_tab('INVOICE_NUMBER');
        --�O��EDI�w�b�_���ID������EDI�w�b�_���ID�̏ꍇ
        lt_last_header_id := lt_header_id;
/* 2009/06/11 Ver1.10 Mod Start */
        lt_last_bargain_class := lt_bargain_class;
        lb_mix_error_order := FALSE;
        lb_out_flag_error_order := FALSE;
      END IF;
--
      --==============================================================
      --����敪OUTBOUND�ۃt���O�`�F�b�N
      --==============================================================
      IF (lt_outbound_flag = 'N' AND lb_out_flag_error_order = FALSE) THEN
        lb_error := TRUE;
        lb_out_flag_error_order := TRUE;
        lv_errmsg := xxccp_common_pkg.get_msg(
                       cv_apl_name
                      ,ct_msg_sale_class_err
                      ,cv_tkn_order_no
                      ,l_data_tab('INVOICE_NUMBER')
                     );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
-- 2009/02/19 T.Nakamura Ver.1.5 add start
        lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
      END IF;
--
      --==============================================================
      --CSV�w�b�_���R�[�h�쐬����
      --==============================================================
      IF (cur_data_record%ROWCOUNT = 1) THEN
        proc_out_csv_header(
          lv_errbuf
         ,lv_retcode
         ,lv_errmsg
        );
      END IF;
--
      IF (lv_retcode = cv_status_error) THEN
-- 2009/02/20 T.Nakamura Ver.1.6 mod start
--        RAISE global_process_expt;
        RAISE global_api_expt;
-- 2009/02/20 T.Nakamura Ver.1.6 mod end
      END IF;
--
      --==============================================================
      --�f�[�^���R�[�h�쐬����
      --==============================================================
      proc_out_data_record(
        lt_header_id
       ,l_data_tab
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg
      );
--
      IF (lv_retcode = cv_status_error) THEN
-- 2009/02/20 T.Nakamura Ver.1.6 mod start
--        RAISE global_process_expt;
        RAISE global_api_expt;
-- 2009/02/20 T.Nakamura Ver.1.6 mod end
      END IF;
--
    END LOOP data_record_loop;
    --==============================================================
    --�t�b�^���R�[�h�쐬����
    --==============================================================
    proc_out_footer_record(
      lv_errbuf
     ,lv_retcode
     ,lv_errmsg
    );
--
    IF (lv_retcode = cv_status_error) THEN
-- 2009/02/20 T.Nakamura Ver.1.6 mod start
--      RAISE global_process_expt;
      RAISE global_api_expt;
-- 2009/02/20 T.Nakamura Ver.1.6 mod end
    END IF;
--
    IF (lb_error) THEN
      RAISE sale_class_expt;
    END IF;
--
    --�Ώۃf�[�^������
    IF (gn_target_cnt = 0) THEN
      ov_retcode := cv_status_warn;
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_apl_name
                    ,iv_name         => ct_msg_nodata
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
-- 2009/02/19 T.Nakamura Ver.1.5 add start
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
-- 2009/02/19 T.Nakamura Ver.1.5 add end
    END IF;
    CLOSE cur_data_record;
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
--
    -- *** ���b�N�G���[�n���h�� ***
    WHEN resource_busy_expt THEN
/* 2009/06/11 Ver1.10 Mod Start */
--      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_oe_header);
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_edi_header);
/* 2009/06/11 Ver1.10 Mod End   */
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_resource_busy_err
                    ,cv_tkn_table
                    ,lt_tkn
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** ����敪�G���[�n���h�� ***
    WHEN sale_class_expt THEN
      ov_errmsg  := NULL;
-- 2009/02/19 T.Nakamura Ver.1.5 mod start
--      ov_errbuf  := NULL;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf_all,1,5000);
-- 2009/02/19 T.Nakamura Ver.1.5 mod end
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_get_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
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
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
--
  BEGIN
    out_line(buff => cv_prg_name || ' start');
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
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --==============================================================
    --��������
    --==============================================================
    proc_init(
      lv_errbuf
     ,lv_retcode
     ,lv_errmsg
    );
    IF (lv_retcode != cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    --�w�b�_���R�[�h�쐬����
    --==============================================================
    proc_out_header_record(
      lv_errbuf
     ,lv_retcode
     ,lv_errmsg
    );
    IF (lv_retcode != cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    --�f�[�^���R�[�h�擾����
    --==============================================================
    proc_get_data(
      lv_errbuf
     ,lv_retcode
     ,lv_errmsg
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    ov_retcode := lv_retcode;
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
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
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_file_name                 IN     VARCHAR2,  --  7.�t�@�C����
    iv_chain_code                IN     VARCHAR2,  --  2.�`�F�[���X�R�[�h
    iv_report_code               IN     VARCHAR2,  -- 11.���[�R�[�h
    in_user_id                   IN     NUMBER,    --  1.���[�UID
    iv_chain_name                IN     VARCHAR2,  --  3.�`�F�[���X��
    iv_store_code                IN     VARCHAR2,  --  4.�X�܃R�[�h
    iv_base_code                 IN     VARCHAR2,  --  5.���_�R�[�h
    iv_base_name                 IN     VARCHAR2,  --  6.���_��
    iv_data_type_code            IN     VARCHAR2,  --  8.���[��ʃR�[�h(�f�[�^��R�[�h)
    iv_ebs_business_series_code  IN     VARCHAR2,  --  9.�Ɩ��n��R�[�h
    iv_info_div                  IN     VARCHAR2,  -- 10.���敪
    iv_report_name               IN     VARCHAR2,  -- 12.���[�l��
    iv_shop_delivery_date_from   IN     VARCHAR2,  -- 13.�X�ܔ[�i��(FROM�j'YYYYMMDD'
    iv_shop_delivery_date_to     IN     VARCHAR2,  -- 14.�X�ܔ[�i���iTO�j 'YYYYMMDD'
    iv_edi_input_date            IN     VARCHAR2,  -- 15.EDI�捞��        'YYYYMMDD'
    iv_publish_div               IN     VARCHAR2,  -- 16.�[�i�����s�敪
    in_publish_flag_seq          IN     NUMBER,    -- 17.�[�i�����s�t���O����
--******************************************* 2009/04/01 1.7 T.Kitajima ADD START *************************************
    iv_ssm_store_code            IN     VARCHAR2   -- 18.���[�l���`�F�[���X�R�[�h
--******************************************* 2009/04/01 1.7 T.Kitajima ADD  END  *************************************
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
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F�o��
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F���O(���[�̂�)
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
    --
    l_input_rec g_input_rtype;
  BEGIN
    out_line(buff => cv_prg_name || ' start');
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log_header_out
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
    -- ���̓p�����[�^�̃Z�b�g
    -- ===============================================
    l_input_rec.user_id                  := in_user_id;
    l_input_rec.chain_code               := iv_chain_code;
    l_input_rec.chain_name               := iv_chain_name;
    l_input_rec.store_code               := iv_store_code;
    l_input_rec.base_code                := iv_base_code;
    l_input_rec.base_name                := iv_base_name;
    l_input_rec.file_name                := iv_file_name;
    l_input_rec.data_type_code           := iv_data_type_code;
    l_input_rec.ebs_business_series_code := iv_ebs_business_series_code;
    l_input_rec.info_div                 := iv_info_div;
    l_input_rec.report_code              := iv_report_code;
    l_input_rec.report_name              := iv_report_name;
    l_input_rec.shop_delivery_date_from  := iv_shop_delivery_date_from;
    l_input_rec.shop_delivery_date_to    := iv_shop_delivery_date_to;
    l_input_rec.edi_input_date           := iv_edi_input_date;
    l_input_rec.publish_div              := iv_publish_div;
    l_input_rec.publish_flag_seq         := in_publish_flag_seq;
--******************************************* 2009/04/01 1.7 T.Kitajima ADD START *************************************
    l_input_rec.ssm_store_code           := iv_ssm_store_code;
--******************************************* 2009/04/01 1.7 T.Kitajima ADD  END  *************************************
--
    g_input_rec := l_input_rec;
--
    -- ===============================================
    -- ���������̌Ăяo��
    -- ===============================================
    init(
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- ===============================================
    -- �I������
    -- ===============================================
    --�G���[�o��
--
--******************************************* 2009/06/18 1.11 N.Maeda ADD START *************************************
    IF (lv_retcode = cv_status_error) THEN
      gn_error_cnt := 1;
    END IF;
--******************************************* 2009/06/18 1.11 N.Maeda ADD  END  *************************************
--
    IF (lv_retcode != cv_status_normal) THEN
-- 2009/02/19 T.Nakamura Ver.1.5 mod start
--      FND_FILE.PUT_LINE(
--         which  => FND_FILE.OUTPUT
--        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
--      );
      IF ( lv_errmsg IS NOT NULL ) THEN
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
        );
      END IF;
-- 2009/02/19 T.Nakamura Ver.1.5 mod end
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
-- 2009/02/12 T.Nakamura Ver.1.1 mod start
--    END IF;
--    --��s�}��
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => ''
--    );
      --��s�}��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
    END IF;
-- 2009/02/12 T.Nakamura Ver.1.1 mod end
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
    IF (lv_retcode = cv_status_normal) THEN
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
    ELSE
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_success_rec_msg
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR(0)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
    END IF;
    --
    --�G���[�����o��
    IF (lv_retcode = cv_status_error) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_error_rec_msg
                      ,iv_token_name1  => cv_cnt_token
--******************************************* 2009/06/18 1.11 N.Maeda MOD START *************************************
                      ,iv_token_value1 => TO_CHAR(gn_error_cnt)
--                      ,iv_token_value1 => TO_CHAR(gn_target_cnt)
--******************************************* 2009/06/18 1.11 N.Maeda MOD  END  *************************************
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
    ELSE
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_error_rec_msg
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR(0)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
    END IF;
    --
    --��s�}��
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
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCOS014A02C;
/
